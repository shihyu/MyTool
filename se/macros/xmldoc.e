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
#include "xml.sh"
#include "color.sh"
#include "minihtml.sh"
#import "c.e"
#import "cbrowser.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "dlgman.e"
#import "help.e"
#import "javadoc.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "picture.e"
#import "pushtag.e"
#import "recmacro.e"
#import "sellist.e"
#import "sellist2.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "xml.e"
#import "se/tags/TaggingGuard.e"
#endregion

//#define REMOVECODE 0
//#pragma option(autodeclvars,off)

int def_xmldoc_format_flags=VSJAVADOCFLAG_BEAUTIFY|VSJAVADOCFLAG_ALIGN_PARAMETERS|VSJAVADOCFLAG_ALIGN_EXCEPTIONS|VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION|VSJAVADOCFLAG_ALIGN_RETURN|VSJAVADOCFLAG_ALIGN_DEPRECATED|VSJAVADOCFLAG_DEFAULT_ON;

static bool in_cua_select;

static void xdcmd_maybe_deselect_command(typeless pfn);
static void xdcmd_rubout();
static void xdcmd_linewrap_rubout();
static void xdcmd_delete_char();
static void xdcmd_linewrap_delete_char();
static void xdcmd_cua_select();

static void xdcmd_cut_line();
static void xdcmd_join_line();
static void xdcmd_delete_line();
static void xdcmd_cut_end_line();
static void xdcmd_erase_end_line();

static int _setEditorControlMode(int wid);

static typeless XMLDocCommands:[]={
   "rubout"                    =>xdcmd_rubout,
   "linewrap-rubout"           =>xdcmd_linewrap_rubout,
   "delete-char"               =>xdcmd_delete_char,
   "vi-forward-delete-char"    =>xdcmd_delete_char,
   "linewrap-delete-char"      =>xdcmd_linewrap_delete_char,
   "brief-delete"              =>xdcmd_linewrap_delete_char,

   "cut-line"                  =>xdcmd_cut_line,
   "join-line"                 =>xdcmd_join_line,
   "cut"                       =>xdcmd_cut_line,
   "delete-line"               =>xdcmd_delete_line,
   "cut-end-line"              =>xdcmd_cut_end_line,
   "erase-end-line"            =>xdcmd_erase_end_line,

   "codehelp-complete"         =>codehelp_complete,
   "list-symbols"              =>list_symbols,
   "function-argument-help"    =>function_argument_help,
   "split-insert-line"         =>split_insert_line,
   "maybe-split-insert-line"   =>split_insert_line,
   "nosplit-insert-line"       =>split_insert_line,
   "nosplit-insert-line-above" =>split_insert_line,
   "paste"                     =>paste,
   "brief-paste"               =>paste,

   "undo"                      =>undo,
   "undo-cursor"               =>undo_cursor,
   "cua-select"                =>xdcmd_cua_select,
   "deselect"                  =>deselect,
   "copy-to-clipboard"         =>copy_to_clipboard,

   "bottom-of-buffer"          =>{xdcmd_maybe_deselect_command,bottom_of_buffer},

   "top-of-buffer"             =>{xdcmd_maybe_deselect_command,top_of_buffer},

   "page-up"                   =>{xdcmd_maybe_deselect_command,page_up},

   "vi-page-up"                =>{xdcmd_maybe_deselect_command,page_up},

   "page-down"                 =>{xdcmd_maybe_deselect_command,page_down},

   "vi-page-down"              =>{xdcmd_maybe_deselect_command,page_down},


   "cursor-left"               =>{xdcmd_maybe_deselect_command,cursor_left},
   "vi-cursor-left"            =>{xdcmd_maybe_deselect_command,cursor_left},

   "cursor-right"              =>{xdcmd_maybe_deselect_command,cursor_right},
   "vi-cursor-right"           =>{xdcmd_maybe_deselect_command,cursor_right},

   "cursor-up"                 =>{xdcmd_maybe_deselect_command,cursor_up},
   "vi-prev-line"              =>{xdcmd_maybe_deselect_command,cursor_up},

   "cursor-down"               =>{xdcmd_maybe_deselect_command,cursor_down},
   "vi-next-line"              =>{xdcmd_maybe_deselect_command,cursor_down},

   "begin-line"                =>{xdcmd_maybe_deselect_command,begin_line},

   "begin-line-text-toggle"    =>{xdcmd_maybe_deselect_command,begin_line_text_toggle},

   "brief-home"                =>{xdcmd_maybe_deselect_command,begin_line},

   "vi-begin-line"             =>{xdcmd_maybe_deselect_command,begin_line},

   "vi-begin-line-insert-mode" =>{xdcmd_maybe_deselect_command,begin_line},

   "brief-end"                 =>{xdcmd_maybe_deselect_command,end_line},
   "end-line"                  =>end_line,
   "end-line-text-toggle"      =>{xdcmd_maybe_deselect_command,end_line_text_toggle},
   "end-line-ignore-trailing-blanks"=>{xdcmd_maybe_deselect_command,end_line_ignore_trailing_blanks},
   "vi-end-line"               =>{xdcmd_maybe_deselect_command,end_line},
   "vi-end-line-append-mode"   =>{xdcmd_maybe_deselect_command,end_line},
   "mou-click"                 =>mou_click,
   "mou-extend-selection"      =>mou_extend_selection,
   "mou-select-line"           =>mou_select_line,

   "select-line"               =>select_line,
   "brief-select-line"         =>select_line,
   "select-char"               =>select_char,
   "brief-select-char"         =>select_char,
};

bool def_xmldoc_keep_obsolete=false;

static const XDMIN_EDITORCTL_HEIGHT=  600;
/**
 * Amount in twips to indent in the Y direction after a label control
 */
static const XDY_AFTER_LABEL=   28;
/**
 * Amount in twips to indent in the Y direction after controls that do not have
 * a specific indent
 */
static const XDY_AFTER_OTHER=   100;
static const XDX_BETWEEN_TEXT_BOX=  200;

static const XMLDOCTYPE_CLASS=    1;
static const XMLDOCTYPE_DATA=     2;
static const XMLDOCTYPE_METHOD=   3;
static const XMLDOCTYPE_LAST=     3;

_control ctlcancel;

static int CURXMLDOCTYPE(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}
static int MODIFIED(...) {
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user;
}
static typeless TIMER_ID(...) {
   if (arg()) ctltagcaption.p_user=arg(1);
   return ctltagcaption.p_user;
}
static _str HASHTAB(...):[][] {
   if (arg()) ctlcancel.p_user=arg(1);
   return ctlcancel.p_user;
}
static int CURTREEINDEX(...) {
   if (arg()) p_active_form.p_user=arg(1);
   return p_active_form.p_user;
}
static bool ALLOW_SAVE(...) {
   if (arg()) ctlpicture1.p_user=arg(1);
   return ctlpicture1.p_user;
}
static int XML_HANDLE(...) {
   if (arg()) ctldescription1.p_user=arg(1);
   return ctldescription1.p_user;
}
   _control ctltree1;
   _control ctldescription1;

defeventtab _xmldoc_form;
void ctloptions.lbutton_up()
{
   show("-modal _xmldoc_format_form");
}
static void xdSetupSeeContextTagging()
{
   if (p_user!="") {
      return;
   }
   p_user=1;
   //say('initializing data');
   orig_modify := p_modify;
   orig_linenum := p_line;
   orig_col := p_col;
   top();
   text := get_text(p_buf_size);
   /*if (length(text)<length(p_newline) ||
       substr() {
   } */

   markid := _alloc_selection();
   editorctl_wid := _form_parent();
   editorctl_wid.save_pos(auto p);
   editorctl_wid.top();
   editorctl_wid._select_line(markid);
   editorctl_wid.bottom();
   editorctl_wid._select_line(markid);
   undo_steps := p_undo_steps;
   p_undo_steps=0;
   _lbclear();
   _copy_to_cursor(markid);
   editorctl_wid.restore_pos(p);

   _free_selection(markid);
   top();up();
   _lineflags(HIDDEN_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
   for (;;) {
      if ( down()) break;
      _lineflags(HIDDEN_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
   }

   orig_wid := p_window_id;
   orig_view_id := 0;
   get_window_id(orig_view_id);
   p_window_id=editorctl_wid;
   _UpdateContext(true);
   proc_name := path := "";
   start_line_no := -1;
   orig_wid.ctltree1._ProcTreeTagInfo2(editorctl_wid,auto cm,proc_name,path,start_line_no,orig_wid.CURTREEINDEX());
   activate_window(orig_view_id);

   p_RLine=start_line_no;
   p_col=1;
   up();
   line := "";
   restore_linenum := 0;
   for (i:=1;;++i) {
      if (text:=="") break;
      parse text with line '\r\n|\r|\n','r' text;
      insert_line(line);
      _lineflags(0,HIDDEN_LF);
      if (i==orig_linenum) {
         restore_linenum=i;
      }
   }
   p_col=orig_col;
   if (restore_linenum) {
      p_line=restore_linenum;
   }
   p_undo_steps=undo_steps;
   p_modify=orig_modify;

}
void ctlsee1.on_got_focus()
{
   xdSetupSeeContextTagging();
}


static void xdEditControlEventHandler()
{
   lastevent := last_event();
   eventname := event2name(lastevent);
   //messageNwait("_EditControlEventHandler: eventname="eventname" _select_type()="_select_type());
   if (eventname=="F1" || eventname=="A-F4" || eventname=="ESC" || eventname=="TAB" || eventname=="S-TAB") {
      call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
      return;
      //help('Diff Dialog box');
   }
   if (eventname=="MOUSE-MOVE") {
      return;
   }
   /*if (eventname=='RBUTTON-DOWN ') {
      edit_window_rbutton_up();
      return;
   } */
   status := 0;
   if (substr(eventname,1,2)=="A-" && isalpha(substr(eventname,3,1))) {
      letter := "";
      parse event2name(last_event()) with "A-" letter;
      status=_dmDoLetter(letter);
      if (!status) return;
   }
   key_index  := event2index(lastevent);
   name_index := eventtab_index(_default_keys,p_mode_eventtab,key_index);
   command_name := name_name(name_index);

   //This is to handle C-X combinations
   if (name_type(name_index)==EVENTTAB_TYPE) {
      eventtab_index2 := name_index;
      event2 := get_event('k');
      key_index=event2index(event2);
      name_index=eventtab_index(_default_keys,eventtab_index2,key_index);
      command_name=name_name(name_index);
   }
   typeless junk=0;
   if (XMLDocCommands._indexin(command_name)) {
      old_dragdrop := def_dragdrop;
      def_dragdrop=false;
      switch (XMLDocCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         (*XMLDocCommands:[command_name])();
         break;
      case VF_ARRAY:
         junk=(*XMLDocCommands:[command_name][0])(XMLDocCommands:[command_name][1]);
         break;
      }
      def_dragdrop=old_dragdrop;
   } else {
      if (command_name!="") {
         if (pos('\-space$',command_name,1,'r')) {
            keyin(" ");
         }else if (pos('\-enter$',command_name,1,'r')) {
            split_insert_line();
         }else if (pos('\maybe-case-backspace$',command_name,1,'r')) {
            xdcmd_linewrap_rubout();
         }else if (pos('\-backspace$',command_name,1,'r')) {
            xdcmd_linewrap_rubout();
         }
      }
   }

   p_scroll_left_edge=-1;

}
//void ctlsee1.\0-\33,\129-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
void ctlsee1."range-first-nonchar-key"-"all-range-last-nonchar-key"," ", "range-first-mouse-event"-"all-range-last-mouse-event",ON_SELECT()
{
   xdEditControlEventHandler();
}
static void xdDoCharKey()
{
   key := last_event();
   index := eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(key));
   cmdname := name_name(index);
   if (pos("auto-codehelp-key",cmdname) || 
       pos("auto-functionhelp-key",cmdname)
       ) {
      call_index(find_index(cmdname,name_type(index)));
      return;
   }
   keyin(key);
}
#if 0
static void xd_multi_delete(_str cmdline="")
{
   line := "";
   if ((cmdline==""||p_word_wrap_style&WORD_WRAP_WWS) && OnImaginaryLine()) {
      get_line(line);
      //if (p_col==length(line)) return;
      if (p_col>=length(expand_tabs(line))) return;
   }
   if (p_col > _line_length()) {
      if (!down()) {
         if (OnImaginaryLine()) {
            if (cmdline=="" ||
                cmdline=='linewrap-delete-char'||
                cmdline=='delete-char') {
               DiffMessageBox('Cannot split Imaginary line');
               up();
               return;
            }
         }
         up();
      }
   }

   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   orig_numlines := p_Noflines;
   wid._undo('S');
   otherwid._undo('S');

   origline := wid.p_line;
   wid.get_line(line);
   onlast := OnLastLine();
   isimaginary := (wid._lineflags() & NOSAVE_LF) != 0;
   if (isimaginary && !DialogIsDiff()) {
      return;
   }
   oldmodify := false;
   switch (cmdline) {
   case 'cut':
      wid.cut();break;
   case 'linewrap-delete-char':
      wid.linewrap_delete_char();break;
   case 'delete-char':
      wid.linewrap_delete_char();break;
   case 'cut-line':
      oldmodify=wid.p_modify;
      wid.cut_line();
      if (isimaginary) wid.p_modify=oldmodify;
      break;
   case 'delete-line':
      oldmodify=p_modify;
      wid._delete_line();
      if (isimaginary) p_modify=oldmodify;
      break;
   case 'delete-selection':
      wid.delete_selection();break;
   default:
      wid._begin_select();
      oldwid := p_window_id;p_window_id=wid;
      _delete_selection();
      p_window_id=oldwid;
      wid.keyin(last_event());
      break;
   }
   if (wid.p_Noflines<orig_numlines) {
      cur_num_lines := wid.p_Noflines;
      otherwid.p_line=origline;
      if (!wid.OnLastLine()) {
         otherwid.p_line=wid.p_line;
      }
      for (i:=1;i<=orig_numlines-cur_num_lines;++i) {
         old_col := p_col;
         if (!otherwid.OnImaginaryLine()) {
            if (!onlast) {
               up();
            }
            //InsertImaginaryLine();
            DiffInsertImaginaryBufferLine();
            if (!onlast) {
               down();
            }
            otherwid.set_line_inserted();
            otherwid.down();
            AddUndoNothing(otherwid);
         }else{
            AddUndoNothing(wid);
            wid=p_window_id;
            p_window_id=otherwid;
            oldmodify=p_modify;
            isimaginary=_lineflags()&NOSAVE_LF;
            _delete_line();
            if (isimaginary) {
               p_modify=oldmodify;
            }
            p_window_id=wid;
         }
         p_col=old_col;
      }
      otherwid.p_line=wid.p_line;
   }
   if (_lineflags()&MODIFY_LF) {
      otherwid._lineflags(MODIFY_LF,MODIFY_LF);
   }
   AddUndoNothing(otherwid);

   otherwid.set_scroll_pos(otherwid.p_left_edge,wid.p_cursor_y);
   p_active_form.p_user=1;
}
#endif

static int xdmaybe_delete_selection()
{
   if (!command_state() && select_active()) {
      if ( _select_type("","U")=="P" && _select_type("","S")=="E" ) {
         return(0);
      }
      if ( def_persistent_select=="D"  && !_QReadOnly() ) {
         _begin_select();
         if (_select_type()=="LINE") {
            p_col=1;_delete_selection();
            if (_lineflags() & HIDDEN_LF) {
               up();
               insert_line("");
               _lineflags(0,HIDDEN_LF);
            }
         } else if (_select_type()=="CHAR") {
            _end_select();
            _end_line();
            down();
            if (_lineflags()& HIDDEN_LF) {
               first_col := last_col := junk := 0;
               _get_selinfo(first_col,last_col,junk);
               if(p_col<last_col+_select_type("","i")) {
                  up();insert_line("");
               }
            }
            _begin_select();
            _delete_selection();
         } else {
            _delete_selection();
         }
         return(1);
      }
   }
   return(0);
}
void ctlsee1.\33-"range-last-char-key"()
{
   xdmaybe_delete_selection();
   xdDoCharKey();
}
#if 0
void ctlsee1.'<'()
{
}
void ctlsee1.'<'()
{
   line := "";
   xdmaybe_delete_selection();
   get_line(line);
   if (line!="") {
      keyin('<');
      return;
   }
   _SetEditorLanguage('html');
   _insert_text('<'case_html_tag('a')' 'case_html_tag('href',true)'=""></'case_html_tag('a')'>');
   _SetEditorLanguage(_form_parent().p_LangId);
   p_col-=6;
}
void ctlsee1.'#'()
{
   xdmaybe_delete_selection();
   get_line(auto line);
   cfg := _clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      keyin('#');
      return;
   }
   auto_codehelp_key();
}
#endif
void ctlparam3."TAB"()
{
   wid := _find_control("ctlparamcombo"CURXMLDOCTYPE());
   if (wid && wid.p_line<wid.p_Noflines) {
      wid._lbdown();
      wid.p_text=wid._lbget_text();
   } else {
      call_event(defeventtab _ainh_dlg_manager,TAB,'E');
   }
}
void ctlparam3."S-TAB"()
{
   wid := _find_control("ctlparamcombo"CURXMLDOCTYPE());
   if (wid && wid.p_line>1) {
      wid._lbup();
      wid.p_text=wid._lbget_text();
   } else {
      call_event(defeventtab _ainh_dlg_manager,S_TAB,'E');
   }
}
//void _xmldoc_form.A_A-A_Z()
void _xmldoc_form.A_K,A_X,A_O,A_T,A_N,A_P,A_A,A_X,A_M,A_U,A_I()
{
   lastevent := last_event();
   eventname := event2name(lastevent);
   if (substr(eventname,1,2)=="A-" && isalpha(substr(eventname,3,1))) {
      letter := "";
      parse event2name(last_event()) with "A-" letter;
      status := _dmDoLetter(letter);
      if (!status) return;
   }
}
void ctlok.lbutton_up()
{
   status := xdMaybeSave(true);
   if (status) {
      return;
   }
   p_active_form._delete_window();
}

static _str xdSSTab[][]={
   {"0"},
   {"ctldescriptionlabel1","ctlseealsolabel1","ctlexamplelabel1"},
   {"ctldescriptionlabel2","ctlseealsolabel1","ctlexamplelabel1"},
   {"ctldescriptionlabel3","ctlseealsolabel3","ctlexamplelabel3","ctlremarkslabel3"},
};
static int xdPercentageHashtab:[]={
   "ctldescription1"=> 100,

   "ctlsee1"=>100,

   "ctldescription2"=> 100,

   "ctldescription3"=> 50,
   "ctlparam3"=> 25,
   "ctlreturn3"=> 25,

   "ctlsee3"=>100,

   "ctlexample3"=>100,

   "ctlremarks3"=>100
};
static void xdHideAll()
{
   for (i:=1;i<=XMLDOCTYPE_LAST;++i) {
      wid := _find_control("ctlpicture"i);
      if (wid) wid.p_visible=false;
   }
   ctlpreview.p_enabled=false;
}
static int xdPictureFirstChild()
{
   wid := _find_control("ctlpicture"CURXMLDOCTYPE());
   if (wid && wid.p_object==OI_SSTAB) {
      return(_find_control(xdSSTab[CURXMLDOCTYPE()][wid.p_ActiveTab]));
   }
   return(wid.p_child);
}
static void xdCheckForModifiedEditorCtl()
{
   firstchild := child := xdPictureFirstChild();
   for (;;) {
      if (child.p_object==OI_EDITOR) {
         if (child.p_modify) {
            MODIFIED(1);
            return;
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
}
/*
  The data is modified if any editor control is modified or
  a text box, or check box is modified.
*/
static bool xdModified()
{
   if (CURXMLDOCTYPE()=="") return(false);
   if (MODIFIED()) {
      return(true);
   }
   xdCheckForModifiedEditorCtl();
   if (MODIFIED()) {
      return(true);
   }
   return(false);
}
static void xdCopySeeLines(int form_wid,_str indent,_str ctlname)
{
   handle := form_wid.XML_HANDLE();
   wid := form_wid._find_control(ctlname:+form_wid.CURXMLDOCTYPE());
   if (wid && wid.p_visible) {
      typeless array[];
      _xmlcfg_find_simple_array(handle,"/document/seealso",array);
      for (i:=0;i<array._length();++i) {
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
      if (!wid.p_Noflines) {
         return;
      }
      wid.get_line(auto line);
      if (wid.p_Noflines==1 && line=="") {
         return;
      }
      dest_node_index := _xmlcfg_find_simple(handle,"/document/example");
      if (dest_node_index<0) {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/returns");
         if (dest_node_index<0) {
            _xmlcfg_find_simple_array(handle,"/document/param",array);
            if (array._isempty()) {
               _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
            }
            if (array._length()) {
               dest_node_index=(int)array[array._length()-1];
            }
            if (dest_node_index<0) {
               dest_node_index=_xmldoc_find_description_node(handle);
            }
         }
      }
      next_index := _xmlcfg_get_next_sibling(handle,dest_node_index,-1);
      if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
         dest_node_index=next_index;
      }
      wid.top();wid.up();
      for (;;) {
         if (wid.down()) break;
         if (wid._lineflags() & HIDDEN_LF) {
            continue;
         }
         wid.get_line(line);
         if (line!="") {
            dest_node_index=_xmlcfg_add(handle,dest_node_index,"seealso",VSXMLCFG_NODE_ELEMENT_START,0);
            _xmlcfg_set_attribute(handle,dest_node_index,"cref",line,0);
            dest_node_index=_xmldoc_add_linebreak(handle,dest_node_index);
         }
      }
   }
}
static void xdCopyEditorCtlData(int form_wid,_str indent,_str ctlname,bool &hit_error,_str &error_info)
{
   handle := form_wid.XML_HANDLE();
   wid := form_wid._find_control(ctlname:+form_wid.CURXMLDOCTYPE());
   if (wid && wid.p_visible) {
      wid.get_line(auto line);
      if ((!wid.p_Noflines || (wid.p_Noflines==1 && line=="")) && ctlname!="ctldescription" && ctlname!="ctlreturn") {
         index := -1;
         switch (ctlname) {
         case "ctlexample":
            index=_xmlcfg_find_simple(handle,"/document/example");
            break;
         }
         if (index>=0) {
            _xmldoc_remove_eol(handle,index);
            _xmlcfg_delete(handle,index);
         }
         return;
      }
      wid.save_pos(auto p);
      wid.top();
      status := 1;
      isdescription := (ctlname=="ctldescription");
      //if (isdescription) {
      //   status=wid.search('^[ \t]*\@','@r');
      //}

      doBeautify := false;
      prefix := "";

      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (ctlname!="ctlsee")
         ) {
         wid.top();
         status=wid.search( "<code>" ,"rh@");
         if (status) {
            doBeautify=true;
            prefix=indent;   //substr("",1,length(atTagSpace));
         }
      }
      temp_view_id := 0;
      orig_view_id := _create_temp_view(temp_view_id);
      wid.top();wid.up();
      first_loop := true;
      for (;;) {
         if (wid.down()) break;
         if (wid._lineflags() & HIDDEN_LF) {
            continue;
         }
         wid.get_line(line);
         if (ctlname!="ctlsee" || line!="") {
            if (doBeautify && !first_loop && line!="") {
               insert_line(prefix:+line);
            } else {
               insert_line(line);
            }
         }
         first_loop=false;
      }

      //temp_handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      wid.restore_pos(p);
      top();_insert_text("<document>");
      bottom();_insert_text("</document>");
      temp_handle := _xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      if (temp_handle<0) {
         hit_error=true;
         error_info=ctlname;
         return;
      }
      tag := "";
      dest_node_index := 0;
      if (ctlname=="ctldescription") {
         dest_node_index=_xmldoc_find_description_node(handle);
         tag="summary";
      } else if (ctlname=="ctlreturn") {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/returns");
         tag="returns";
      } else if (ctlname=="ctlexample") {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/example");
         tag="example";
      } else   if (ctlname=="ctlremarks") {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/remarks");
         tag="remarks";
      }
      //say(ctlname);_showxml(handle);
      if (dest_node_index>=0) {
         _xmlcfg_delete(handle,dest_node_index,true);
         next_index := _xmlcfg_get_next_sibling(handle,dest_node_index,~VSXMLCFG_NODE_ATTRIBUTE);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            line=_xmlcfg_get_value(handle,next_index);
            line=stranslate(line,"","\r");
            first := second := rest := "";
            parse line with first "\n" second "\n";
            if (first=="" && second=="" && pos("\n?*\n",line,1,"r")) {
               parse line with first "\n" rest;
               _xmlcfg_set_value(handle,next_index,rest);
            }
         }
      } else {
         dest_node_index=_xmlcfg_find_simple(handle,"/document");
         next_index := _xmlcfg_get_first_child(handle,dest_node_index,-1);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            dest_node_index=_xmlcfg_add(handle,next_index,tag,VSXMLCFG_NODE_ELEMENT_START,0);
            //dest_node_index=_xmlcfg_add(handle,dest_node_index,"",VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
         } else {
            if (ctlname=="ctldescription") {
               dest_node_index=_xmlcfg_add(handle,next_index,tag,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_BEFORE);
            } else if (ctlname=="ctlremarks") {
               // add after summary
               desc_index :=_xmldoc_find_description_node(handle);
               if (desc_index > 0) {
                  dest_node_index=_xmlcfg_add(handle,desc_index,tag,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AFTER);
               } else {
                  dest_node_index=_xmlcfg_add(handle,next_index,tag,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_BEFORE);
               }
            } else {
               // Add <returns> after last parameter if one exists
               temp_index := 0;
               after_index := dest_node_index;
               flags := VSXMLCFG_ADD_AS_CHILD;
               if (ctlname=="ctlexample") {
                  after_index=-1;
                  temp_index=_xmlcfg_find_simple(handle,"/document/returns");
                  if (temp_index>=0) {
                     flags=0;after_index=temp_index;
                  }
               }
               if (ctlname=="ctlreturn" || (ctlname=="ctlexample" && after_index<0) ) {
                  _str array[];
                  _xmlcfg_find_simple_array(handle,"/document/param",array);
                  if (array._isempty()) {
                     _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
                  }
                  if (array._length()) {
                     flags=0;
                     after_index=(int)array[array._length()-1];
                  } else {
                     temp_index = _xmlcfg_find_simple(handle,"/document/remarks");
                     if (temp_index<0) {
                        temp_index=_xmldoc_find_description_node(handle);
                     }
                     if (temp_index>=0) {
                        flags=0;after_index=temp_index;
                     } else {
                        after_index= dest_node_index;
                        flags=VSXMLCFG_ADD_AS_CHILD;
                     }
                  }
               }
               
               temp_index=_xmlcfg_add(handle,after_index,"\n",VSXMLCFG_NODE_PCDATA,flags);
               dest_node_index=_xmlcfg_add(handle,(!flags)?temp_index:after_index,tag,VSXMLCFG_NODE_ELEMENT_START,flags);
            }
         }
      }
      //say('h2 'ctlname);_showxml(handle);
      //_showxml(temp_handle);
      _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,"/document"),VSXMLCFG_COPY_CHILDREN);
      //_showxml(handle);
      //say('h3 'ctlname);_showxml(handle);

      _xmlcfg_close(temp_handle);
   } else {
      index := -1;
      switch (ctlname) {
      case "ctlreturn":
         index=_xmlcfg_find_simple(handle,"/document/returns");
         break;
      }
      if (index>=0) {
         _xmldoc_remove_eol(handle,index);
         _xmlcfg_delete(handle,index);
      }
   }
}
/**
 * Insert comment lines into current editor control
 * object.
 *
 * @param form_wid Window id of javadoc form
 * @param start_col Lines are indent up to start_col specified
 */
static int xdInsertCommentLines(int form_wid,int start_col,int first_line,int last_line,int start_line_no)
{
   handle := form_wid.XML_HANDLE();
   // save parameter changes
   wid := form_wid._find_control("ctlparamcombo"form_wid.CURXMLDOCTYPE());
   if (wid) {
      wid.xdShowParam();
   }

   slcomment_start := "///";
   mlcomment_start := "///";
   mlcomment_end := "///";

   i := 0;
   count := 0;
   dest_node_index := 0;
   next_index := 0;
   newline_index := 0;
   typeless array[];
   tag := "";
   line := "";
   argName := "";
   list := "";
   temp_handle := 0;
   status := 0;
   hit_error := false;
   error_info := "";

   indent := substr("",1,p_SyntaxIndent);   //substr("",1,length(atTagSpace));
   xdCopyEditorCtlData(form_wid,indent,"ctldescription",hit_error,error_info);
   xdCopyEditorCtlData(form_wid,indent,"ctlremarks",hit_error,error_info);
   wid=form_wid._find_control("ctlparamcombo":+form_wid.CURXMLDOCTYPE());
   if (wid) {
      _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_blank_line(handle,array[i]);
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
      _xmlcfg_find_simple_array(handle,"/document/param",array);
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_blank_line(handle,array[i]);
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
      _str hashtab:[][]=form_wid.HASHTAB();
      temp_view_id := 0;
      orig_view_id := _create_temp_view(temp_view_id);
      count=(int)hashtab:["@paramcount"][0];
      tag="param";
      param_node_index := -1;
      for (i=0;i<count;++i) {
         list=hashtab:[tag][i];
         templatePrefix := "";
         if (substr(list,1,2) == "<>") {
            templatePrefix = substr(list, 1, 2);
            list = substr(list, 3);
         }
         parse list with argName list;
         list=stranslate(list,"","\r");
         if (_last_char(list)=="\n" && length(list)>2 && substr(list,length(list)-1,1)!="\n") {
            list=substr(list,1,length(list)-1);
         }
         if (tag!="param" || !def_xmldoc_keep_obsolete ||
             i<hashtab:["@paramcount"][0] ||
             /*rest!="" || */list!="") {
            doBeautify := false;
            if (!pos("<code>",/*rest:+*/list,1)) {
               doBeautify=true;
            } else {
               doBeautify=false;
            }
            first_loop := true;
            for (;;) {
               if (list:=="") {
                  break;
               }
               //parse list with line "\n" list;
               x := pos("\n",list,1);
               if (x) {
                  line=substr(list,1,x);
                  list=substr(list,x+1);
               } else {
                  line=list;
                  list="";
               }
               if (doBeautify && !first_loop && strip(line)!="\n") {
                  _insert_text(indent:+line);
               } else {
                  _insert_text(line);
               }
               first_loop=false;
            }
         }
         top();_insert_text("<document>");bottom();_insert_text("</document>");
         temp_handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
         if (temp_handle<0) {
            hit_error=true;
            error_info="ctlparam "i;
            break;
         }

         if (param_node_index<0) {
            do_insert_child := true;
            dest_node_index = _xmlcfg_find_simple(handle,"/document/remarks");
            if (dest_node_index<0) {
               dest_node_index=_xmldoc_find_description_node(handle);
            }
            next_index=_xmlcfg_get_next_sibling(handle,dest_node_index,-1);
            if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
               dest_node_index=next_index;
            }
            if (templatePrefix == "") {
               dest_node_index=_xmlcfg_add(handle,dest_node_index,"param",VSXMLCFG_NODE_ELEMENT_START,0);
            } else {
               dest_node_index=_xmlcfg_add(handle,dest_node_index,"typeparam",VSXMLCFG_NODE_ELEMENT_START,0);
            }
            _xmlcfg_set_attribute(handle,dest_node_index,"name",argName);
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            //dest_node_index=_xmlcfg_add(handle,dest_node_index,"",VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
            //_showxml(handle);
            _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,"/document"),VSXMLCFG_COPY_CHILDREN);
            //_showxml(handle);
            param_node_index=newline_index;
         } else {
            if (templatePrefix == "") {
               dest_node_index=_xmlcfg_add(handle,param_node_index,"param",VSXMLCFG_NODE_ELEMENT_START,0);
            } else {
               dest_node_index=_xmlcfg_add(handle,param_node_index,"typeparam",VSXMLCFG_NODE_ELEMENT_START,0);
            }
            _xmlcfg_set_attribute(handle,dest_node_index,"name",argName);
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            //_showxml(handle);
            _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,"/document"),VSXMLCFG_COPY_CHILDREN);
            //_showxml(handle);
            param_node_index=newline_index;
         }
         _xmlcfg_close(temp_handle);
         delete_all();
      }
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   }
   //xdCopyComboCtlData(form_wid,prefix,'ctlparamcombo',VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS,'param');

   ctlname := "";
   xdCopyEditorCtlData(form_wid,indent,"ctlreturn",hit_error,error_info);
   xdCopyEditorCtlData(form_wid,indent,"ctlexample",hit_error,error_info);
   xdCopySeeLines(form_wid,indent,"ctlsee");
   if (hit_error) {
      _message_box("XML not valid.  Please correct and save again.");
      typeless linenum;
      parse error_info with ctlname linenum;
      tab_wid := form_wid._find_control("ctlpicture":+form_wid.CURXMLDOCTYPE());
      focus_wid := form_wid._find_control(ctlname:+form_wid.CURXMLDOCTYPE());
      if (ctlname=="ctlparam") {
         //wid=form_wid._find_control('ctlparamcombo':+form_wid.CURXMLDOCTYPE);
         tab_wid.p_ActiveTab=0;
         combo_wid := form_wid._find_control("ctlparamcombo":+form_wid.CURXMLDOCTYPE());
         combo_wid.p_line=linenum+1;
         combo_wid.p_text=combo_wid._lbget_text();
      } else if (ctlname=="ctldescription") {
         tab_wid.p_ActiveTab=0;
      } else if (ctlname=="ctlreturn") {
         tab_wid.p_ActiveTab=0;
      } else if (ctlname=="ctlexample") {
         tab_wid.p_ActiveTab=2;
      } else if (ctlname=="ctlremarks") {
         tab_wid.p_ActiveTab=3;
      }
      focus_wid._set_focus();
      return(1);
   }
   if (first_line>=0) {
      // delete the original comment lines
      num_lines := last_line-first_line+1;
      if (num_lines > 0) {
         p_line=first_line;
         for (i=0; i<num_lines; i++) {
            _delete_line();
         }
      } else {
         first_line=start_line_no;
      }
      p_line=first_line-1;
   }

   /*
       Add blank lines
   */
#if 1
   index := 0;
   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION)) {
      index=_xmldoc_find_description_node(handle);
      if (index>=0) {
         _xmldoc_add_blank_line_after(handle,index);
      }
   }

   index=_xmlcfg_find_simple(handle,"/document/returns");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);

      }
   }
   index=_xmlcfg_find_simple(handle,"/document/example");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);
      }
   }
   index=_xmlcfg_find_simple(handle,"/document/remarks");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);
      }
   }

   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & (VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS|VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM))
      ) {
      _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
      if (array._length()) {
         if (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS) {
            for (i=0;i<array._length();++i) {
               _xmldoc_add_blank_line_after(handle,array[i]);
            }
         } else {
            // only insert extra blank here if there are no non-type parameters
            _xmlcfg_find_simple_array(handle,"/document/param",array);
            if (array._isempty()) {
               _xmldoc_add_blank_line_after(handle,array[array._length()-1]);
            }
         }
      }
   }

   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & (VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS|VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM))
      ) {
      _xmlcfg_find_simple_array(handle,"/document/param",array);
      if (array._length()) {
         if (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS) {
            for (i=0;i<array._length();++i) {
               _xmldoc_add_blank_line_after(handle,array[i]);
            }
         } else {
            _xmldoc_add_blank_line_after(handle,array[array._length()-1]);
         }
      }
   }
#endif

   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(0,handle,0,VSXMLCFG_SAVE_PRESERVE_PCDATA);
   len := length("<document>");
   top();_delete_text(len);bottom();p_col-=len+1;_delete_text(len+1);
   if (_line_length()==0) {
      _delete_line();
   }
   top();
   prefix := indent_string(start_col-1):+slcomment_start:+" ";
   search('^'substr("",1,p_SyntaxIndent),'rh@',prefix);
   temp_buf_id := p_buf_id;
   activate_window(orig_view_id);
   _buf_transfer(temp_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   return(0);
}

static int xdMaybeSave(bool forceSave=false)
{

   doSave := xdModified() || forceSave;
   if (doSave && !ALLOW_SAVE()) {
      _message_box("Can't save.  Correct original XML documentation first.");
      return(1);
   }
   if (doSave) {

      static int recursion;

      if (recursion) return(1);
      ++recursion;
      //say('a0 CURT='CURTREEINDEX()' cap='ctltree1._TreeGetCaption(CURTREEINDEX()));

      form_wid := p_active_form;
      editorctl_wid := _form_parent();
      orig_wid := p_window_id;

      orig_view_id := 0;
      get_window_id(orig_view_id);
      p_window_id=editorctl_wid;

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      proc_name := path := "";
      start_line_no := -1;
      orig_wid.ctltree1._ProcTreeTagInfo2(editorctl_wid,auto cm,proc_name,path,start_line_no,orig_wid.CURTREEINDEX());

      _save_pos2(auto p);
      p_RLine=start_line_no;

      _GoToROffset(cm.seekpos);
      start_col := p_col;


      first_line := last_line := 0;
      if (_do_default_get_tag_header_comments(first_line, last_line, start_line_no)) {
         first_line = start_line_no;
         last_line  = first_line-1;
      }
      status := xdInsertCommentLines(form_wid,start_col,first_line,last_line,start_line_no);

      _restore_pos2(p);
      activate_window(orig_view_id);

      if (!status) {
         buf_name := editorctl_wid.p_buf_name;
         if (buf_name!="") {
            caption := "";
            parse p_active_form.p_caption with caption ":";
            p_active_form.p_caption=caption": "buf_name;
         }

         _xmldoc_refresh_proctree(false);
         CURTREEINDEX(ctltree1._TreeCurIndex());
      }
      //say('a1 CURT='CURTREEINDEX()' cap='ctltree1._TreeGetCaption(CURTREEINDEX()));
      --recursion;
      return(status);
   }
   return(0);
}
void _xmldoc_refresh_proctree(bool curItemMayChange=true)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);
   sentry.lockMatches(true);

   form_wid := p_active_form;
   editorctl_wid := _form_parent();
   editorctl_wid._UpdateContext(true);
   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,"","T");
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_xmldoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);
   ctltree1._TreeSizeColumnToContents(0);
   if (curItemMayChange) {
      nearIndex := ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (nearIndex<0) {
         xdHideAll();
         ctltagcaption.p_caption="No symbol selected, check filtering options.";
         //p_active_form._delete_window();
         return;
      }
      ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
   }

}
static void xdClearControls(int activeTab=0)
{
   firstchild := child := 0;
   wid := _find_control("ctlpicture"CURXMLDOCTYPE());
   if (wid && wid.p_object==OI_SSTAB) {
      firstchild=child=_find_control(xdSSTab[CURXMLDOCTYPE()][activeTab]);
   } else {
      firstchild=child=xdPictureFirstChild();
   }
   for (;;) {
      undo_steps := 0;
      switch (child.p_object) {
      case OI_EDITOR:
         undo_steps=child.p_undo_steps;child.p_undo_steps=0;
         child._lbclear();
         child.p_user="";
         child.p_undo_steps=undo_steps;
         child.insert_line("");
         child.p_modify=false;
         child.p_MouseActivate=MA_ACTIVATE;
         break;
      case OI_CHECK_BOX:
         child.p_value=0;
         break;
      case OI_COMBO_BOX:
         child.p_text="";
         child._lbclear();
         break;
      case OI_TEXT_BOX:
         child.p_text="";
         break;
      }
      if (child.p_child) {
         firstchild2 := child2 := child.p_child;
         for (;;) {
            switch (child2.p_object) {
            case OI_EDITOR:
               undo_steps=child2.p_undo_steps;child2.p_undo_steps=0;
               child2._lbclear();
               child2.p_user="";
               child2.p_undo_steps=undo_steps;
               child2.insert_line("");
               child2.p_modify=false;
               child2.p_MouseActivate=MA_ACTIVATE;
               break;
            case OI_CHECK_BOX:
               child2.p_value=0;
               break;
            case OI_COMBO_BOX:
               child2.p_text="";
               child2._lbclear();
               break;
            case OI_TEXT_BOX:
               child2.p_text="";
               break;
            }
            child2=child2.p_next;
            if (child2==firstchild2) break;
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
}
static void xdShowType(int xmldoctype)
{
   ctlparamcombo3.p_user="";
   //ctlexceptioncombo3.p_user="";
   if (CURXMLDOCTYPE()!=xmldoctype) {
      xdHideAll();
      CURXMLDOCTYPE(xmldoctype);
   }
   wid := _find_control("ctlpicture"CURXMLDOCTYPE());
   if (wid && wid.p_object==OI_SSTAB) {
      xdClearControls(0);
      xdClearControls(1);
   } else {
      xdClearControls(0);
   }
   ctlpreview.p_enabled=true;
}
static void xdResizeChildren(int activeTab=0)
{
   paddingX := _dx2lx(SM_TWIP,_lx2dx(SM_TWIP,100));
   paddingY := ctltree1.p_y;
   y := 0;
   wid := _find_control("ctlpicture"CURXMLDOCTYPE());
   // Determine the minimum hieght required
   NofSizeableControls := 0;
   UseMorePercent := 0;
   nextPaddingY := 0;
   firstchild := child := 0;
   if (wid && wid.p_object==OI_SSTAB) {
      if (activeTab >= wid.p_NofTabs) return;
      firstchild=child=_find_control(xdSSTab[CURXMLDOCTYPE()][activeTab]);
   } else {
      firstchild=child=xdPictureFirstChild();
   }
   for (y=paddingY;;) {
      y+=nextPaddingY;
      if (child.p_visible==0) {
         y-=nextPaddingY;
         if (xdPercentageHashtab._indexin(child.p_name)) {
            UseMorePercent+=xdPercentageHashtab:[child.p_name];
         }
      } else {
         switch (child.p_object) {
         case OI_CHECK_BOX:
            if (!child.p_value) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
               break;
            }
         case OI_LABEL:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_LABEL));
            break;
         case OI_EDITOR:
            if (xdPercentageHashtab._indexin(child.p_name)) {
               NofSizeableControls+=1;
               y+=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDMIN_EDITORCTL_HEIGHT));
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
               break;
            }
         default:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
   if (wid && wid.p_object==OI_SSTAB) {
      y+=paddingY;
   }
   extra_height := ctlok.p_y-y;
   pic_width := _dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlimage1.p_x-ctlimage1.p_width;
   if (wid && !activeTab) {
      wid.p_x=ctlimage1.p_x_extent;
      wid.p_y=0;
      wid.p_width=pic_width;
      wid.p_y_extent = ctltree1.p_y_extent;
   }
   if (wid && wid.p_object==OI_SSTAB) {
      firstchild=child=_find_control(xdSSTab[CURXMLDOCTYPE()][activeTab]);

      pic_width-=(wid.p_width-wid.p_child.p_width);
      extra_height-=(wid.p_height-wid.p_child.p_height);
   } else {
      firstchild=child=xdPictureFirstChild();
   }
   if (extra_height<0) extra_height=0;
   extra_height_remaining := extra_height;
   //say('*******************************************************');
   //say('extra_height='extra_height);
   nextPaddingY=0;
   for (y=paddingY;;) {
      y+=nextPaddingY;
      if (child.p_visible==0) {
         y-=nextPaddingY;
      } else {
         height := 0;
         if (xdPercentageHashtab._indexin(child.p_name)) {
            percent := 0;
            if (UseMorePercent && NofSizeableControls) {
               percent=UseMorePercent/NofSizeableControls;
            }
            extra := ((percent+xdPercentageHashtab:[child.p_name])*extra_height) intdiv 100;
            height=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDMIN_EDITORCTL_HEIGHT))+extra;
            extra_height_remaining-=extra;
         } else {
            height=child.p_height;
         }
         child._move_window(paddingX,y,pic_width-paddingX*2,height);
         //say('y='y' t='ctltree1.p_y);
         if (child.p_object==OI_PICTURE_BOX){
            sizename := substr(child.p_name,1,10);
            if (sizename=="ctlsizepic") {
               // version and serial
               child2 := child.p_child.p_next;
               text_box_width := ((child.p_width-XDX_BETWEEN_TEXT_BOX) intdiv 2);

               // move version text box
               child2._move_window(child2.p_x,child2.p_y,text_box_width,child2.p_height);
               child2=child2.p_next;
               // move serial label
               child2._move_window(text_box_width+XDX_BETWEEN_TEXT_BOX,child2.p_y,child2.p_width,child2.p_height);
               child2=child2.p_next;
               // move serial text box
               child2._move_window(text_box_width+XDX_BETWEEN_TEXT_BOX,child2.p_y,text_box_width,child2.p_height);
            } else if (sizename=="ctlsizeexc" || sizename=="ctlsizepar") {
               label_wid := child.p_child;
               combo_wid := label_wid.p_next;
               combo_wid.p_x=label_wid.p_x_extent+100;
               width := child.p_width-combo_wid.p_x-label_wid.p_x;
               if (width<0) width=1000;
               combo_wid.p_width=width;
            }
         }
         switch (child.p_object) {
         case OI_CHECK_BOX:
            if (!child.p_value) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
               break;
            }
         case OI_LABEL:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_LABEL));
            break;
         case OI_EDITOR:
            if (xdPercentageHashtab._indexin(child.p_name)) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
               break;
            }
         default:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,XDY_AFTER_OTHER));
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
}
static void xdResizeControls()
{
   ctltagcaption.p_visible=ctlok.p_visible=ctlcancel.p_visible=false;

   ctlok.p_y= _dy2ly(SM_TWIP,p_client_height)-ctlok.p_height-100;
   ctlcancel.p_y=ctlpreview.p_y=ctloptions.p_y=ctlok.p_y;
   ctltagcaption.p_y=ctlok.p_y+(ctlok.p_height-ctltagcaption.p_height) intdiv 2;
   ctltagcaption.p_x = ctloptions.p_x_extent + ctlok.p_x;

   ctltree1.p_y_extent = ctlok.p_y-100;
   ctltree1.p_x_extent = ctlimage1.p_x;

   //ctlimage1.p_x=ctltree1.p_x_extent;
   ctlimage1.p_y=0;
   ctlimage1.p_height=ctltree1.p_y_extent;

   ctlok.p_visible=ctlcancel.p_visible=true;
   ctltagcaption.p_visible=true;

   wid := _find_control("ctlpicture"CURXMLDOCTYPE());
   if (wid) {
      wid.p_visible=false;

      if (wid.p_object==OI_SSTAB) {
         xdResizeChildren(0);
         xdResizeChildren(1);
         xdResizeChildren(2);
         xdResizeChildren(3);
      } else {
         xdResizeChildren();
      }

      wid.p_visible=true;
      //_for_each_control(p_active_form,_setEditorControlMode,'H');
   }
}


// Get the information about the tag currently selected
// in the proc tree.
//
static int _ProcTreeTagInfo2(int editorctl_wid,
                             struct VS_TAG_BROWSE_INFO &cm,
                             _str &proc_name, _str &path, int &LineNumber,
                             int tree_index=-1)
{
   // find the tag name, file and line number
   if (tree_index<0) {
      tree_index= _TreeCurIndex();
   }
   LineNumber=_TreeGetUserInfo(tree_index);

   path=editorctl_wid.p_buf_name;
   cm.language=editorctl_wid.p_LangId;
   cm.file_name=editorctl_wid.p_buf_name;

   caption := _TreeGetCaption(tree_index);
   tag_tree_decompose_caption(caption,proc_name);

   // get the remainder of the information
   status := (int)_GetContextTagInfo(cm, "", proc_name, path, LineNumber);
   cm.language=editorctl_wid.p_LangId;
   cm.file_name=editorctl_wid.p_buf_name;
   return (status);
}

static void xdParseEditText(_str &string,_str &text,bool doBeautify=false)
{
   text=string;
   if (doBeautify &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)) {
      if (!pos("<code>",text,1) ) {
         result := "";
         for (;;) {
            if (text:=="") {
               break;
            }
            line := "";
            i := pos("\n",text,1);
            if (i) {
               line=substr(text,1,i);
               text=substr(text,i+1);
            } else {
               line=text;
               text="";
            }
            //parse text with line "\n" +0 text;
            result :+= strip(line);
         }
         text=result;

      }
   }
}
static void xmldocParseParam(_str string,_str &argName,_str &text,_str &templatePrefix,bool doBeautify=false,_str tag="")
{
   templatePrefix = "";
   if (substr(string,1,2) == "<>") {
      templatePrefix = substr(string, 1, 2);
      string = substr(string, 3);
   }
   parse string with argName text;
   parse argName with argName '[ \n]','r';
   if (doBeautify &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)) {
      flag2 := 0;
      if (tag=="param" || tag=="typeparam") {
         flag2=VSJAVADOCFLAG_ALIGN_PARAMETERS;
      } else {
         flag2=VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
      }
      if ( (def_xmldoc_format_flags & flag2) && !pos("<code>",text,1) ) {
         result := "";
         for (;;) {
            if (text:=="") {
               break;
            }
            line := "";
            i := pos("\n",text,1);
            if (i) {
               line=substr(text,1,i);
               text=substr(text,i+1);
            } else {
               line=text;
               text="";
            }
            //parse text with line "\n" text;
            result :+= line;
         }
         text=result;

      }
   }
}
static int xdFindParam(_str tag,_str param_name,_str (&hashtab):[][],bool case_sensitive)
{
   count := hashtab:[tag]._length();
   for (i:=0;i<count;++i) {
      xmldocParseParam(hashtab:[tag][i],auto argName,auto text, auto templatePrefix);
      if (case_sensitive) {
         if (argName==param_name) {
            return(i);
         }
      } else {
         if (strieq(argName,param_name)) {
            return(i);
         }
      }
   }
   return(-1);
}
static void xdShowParam(_str tag="param")
{
   if (p_text=="") return;
   editorctl_wid := _form_parent();
   widcombo := _find_control("ctl"tag"combo"CURXMLDOCTYPE());
   wid := _find_control("ctl"tag:+CURXMLDOCTYPE());
   modify := wid.p_modify;
   _str hashtab:[][];
   hashtab=HASHTAB();
   param_name := text := "";
   templatePrefix := "";
   if (modify && isinteger(widcombo.p_user) && widcombo.p_user>=0) {
      j := widcombo.p_user;
      xmldocParseParam(hashtab:[tag][j],param_name,text,templatePrefix);
      text=wid.get_text(wid.p_buf_size,0);
      if (wid.p_newline=="\r\n") {
         text=stranslate(text,"","\r");
      } else if (wid.p_newline=="\r") {
         text=stranslate(text,"\n","\r");
      }
      if (text:==wid.p_newline || text=="\n") {
         text="";
      }
      //parse text with linetemp "\n";
      hashtab:[tag][j]=templatePrefix:+param_name" "text;
      if (length(text)) {
         widcombo=_find_control("ctl"tag"combo"CURXMLDOCTYPE());
         widcombo.save_pos(auto p);
         widcombo._lbtop();
         status := widcombo._lbfind_and_select_item(param_name" (empty)");
         if (!status) {
            widcombo._lbset_item(param_name);
         }
         widcombo.restore_pos(p);
      }
      HASHTAB(hashtab);
   }
   parse p_text with param_name" (";
   undo_steps := wid.p_undo_steps;wid.p_undo_steps=0;
   wid._lbclear();
   wid.p_undo_steps=undo_steps;
   j := xdFindParam(tag,param_name,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
   if (j>=0) {
      xmldocParseParam(hashtab:[tag][j],param_name,text,templatePrefix,true,tag);
      wid._insert_text(text);
      wid.p_modify=modify;wid.top();
   }
   widcombo.p_user=j;
}
void ctlcancel.lbutton_up()
{
   if (xdModified()) {
      result := prompt_for_save("Save changes?");
      if (result==IDCANCEL) {
         return;
      }
      if (result==IDYES) {
         status := xdMaybeSave();
         if (status) {
            return;
         }
      }
   }
   p_active_form._delete_window();
}
void ctlauthor1.on_change()
{
   MODIFIED(1);
}
void ctlparamcombo3.on_change(int reason)
{
   xdShowParam();
}
static void xdShowModified()
{
   if (MODIFIED()) {
      if (TIMER_ID()!="") {
         _kill_timer(TIMER_ID());
         TIMER_ID("");
      }
      p_active_form.p_caption=p_active_form.p_caption:+" *";
   }
}
static void TimerCallback(int form_wid)
{
   if (form_wid.xdModified()) {
      form_wid.MODIFIED(1);
      form_wid.xdShowModified();
   }
}
void ctlpreview.lbutton_up()
{
   form_wid := p_active_form;
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   p_UTF8=form_wid._form_parent().p_UTF8;
   _SetEditorLanguage(form_wid._form_parent().p_LangId);
   status := xdInsertCommentLines(form_wid,1,-1,0,0);
   if (status) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }
   bottom();
   insert_line("int foo;");
   VSCodeHelpCommentFlags comment_flags=0;
   orig_comment := "";
   first_line := last_line := 0;
   line_prefix := "";
   int blanks:[][];
   doxygen_comment_start := "";
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      _parse_multiline_comments(1,first_line,last_line,comment_flags,"",orig_comment,2000,line_prefix,blanks,doxygen_comment_start);
   }
   _make_html_comments(orig_comment,comment_flags,"","",false,p_LangId);

   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   show("-xy -modal _xmldoc_preview_form",orig_comment,true);

   activate_window(orig_view_id);
   return;
}
static bool in_on_change = false;
void ctltree1.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
      if (in_on_change) {
         return;
      }
      in_on_change=true;
      //say('CURTREEINDEX()='CURTREEINDEX()' cur='_TreeCurIndex());
      cti := CURTREEINDEX();
      if(xdMaybeSave() && cti!=null && cti!="" && isinteger(cti)) {
         _TreeSetCurIndex(cti);
         in_on_change=false;
         return;
      }
      in_on_change=false;
      if (TIMER_ID()=="") {
         TIMER_ID(_set_timer(40,TimerCallback,p_active_form));
      }

      if (index==TREE_ROOT_INDEX) return;
      CURTREEINDEX(index);
      //say('a3 CURTREEINDEX()='CURTREEINDEX());
      caption := _TreeGetCaption(CURTREEINDEX());
      parse caption with auto before "\t" auto after;
      if (after!="") {
         ctltagcaption.p_caption=stranslate(after,"&&","&");
      } else {
         ctltagcaption.p_caption=stranslate(caption,"&&","&");
      }
      // Line number and type(class,proc|func, other)
      tag_init_tag_browse_info(auto cm);
      editorctl_wid := _form_parent();
      buf_name := editorctl_wid.p_buf_name;
      if (buf_name != "") {
         parse p_active_form.p_caption with caption ":";
         p_active_form.p_caption=caption": "buf_name;
      }
      orig_wid := p_window_id;

      get_window_id(auto orig_view_id);
      p_window_id=editorctl_wid;

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      embedded_status := _EmbeddedStart(auto orig_values);

      start_line_no:=0;
      xmldoctype:=0;
      orig_wid._ProcTreeTagInfo2(editorctl_wid,cm,auto proc_name,auto path,start_line_no,index);
      if (tag_tree_type_is_func(cm.type_name)) {
         xmldoctype=XMLDOCTYPE_METHOD;
      } else if (tag_tree_type_is_class(cm.type_name)) {
         xmldoctype=XMLDOCTYPE_CLASS;
         //} else if (tag_tree_type_is_package(cm.type_name)) {
      } else {
         xmldoctype=XMLDOCTYPE_DATA;
      }
      orig_wid.xdShowType(xmldoctype);
      init_modified := 0;

      save_pos(auto p);
      p_RLine=start_line_no;
      _GoToROffset(cm.seekpos);
      //p_col=1;_clex_skip_blanks();

      // try to locate the current context, maybe skip over
      // comments to start of next tag
      context_id := tag_current_context();
      if (context_id <= 0) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         restore_pos(p);
         _message_box("no current tag");
         return;
      }

      // get the information about the current function
      tag_get_context_browse_info(context_id, auto context_cm);
      //say('n='tag_name);
      //say('sig='signature' len='length(signature));

      _GoToROffset(cm.seekpos);
      if (tag_tree_type_is_func(cm.type_name) || tag_tree_type_is_class(cm.type_name)) {
         _UpdateLocals(true);
      }
      newline := p_newline;
      VSCodeHelpCommentFlags comment_flags=0;
      // hash table of original comments for incremental updates
      orig_comment := "";
      first_line := last_line := 0;
      if (!_do_default_get_tag_header_comments(first_line, last_line)) {
         p_RLine=cm.line_no;
         _GoToROffset(cm.seekpos);
         // We temporarily change the buffer name just in case the XMLDoc Editor
         // is the one getting the comments.
         old_buf_name := p_buf_name;
         p_buf_name="";
         line_prefix := "";
         int blanks:[][];
         doxygen_comment_start := "";
         _do_default_get_tag_comments(comment_flags, context_cm.type_name, orig_comment, 1000, false, line_prefix, blanks, 
            doxygen_comment_start);
         p_buf_name=old_buf_name;
      } else {
         init_modified=1;
         first_line = cm.line_no;
         last_line  = first_line-1;
      }
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      activate_window(orig_view_id);


      _str hashtab:[][];
      _str tagList[];

      if (!(comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC)) {
         orig_comment=stranslate(orig_comment,"&lt;","<");  // Translate < to &lt;
         orig_comment=stranslate(orig_comment,"&gt;",">");  // Translate < to &gt;
         orig_comment=stranslate(orig_comment,"","\r");
         if (_last_char(orig_comment)=="\n" && length(orig_comment)>2 && substr(orig_comment,length(orig_comment)-1,1)!="\n") {
            orig_comment=substr(orig_comment,1,length(orig_comment)-1);
         }
         orig_comment="<summary>":+orig_comment:+"</summary>":+"\n";
         init_modified=1;
      }
      description := "";
      allowSave := false;

      if (XML_HANDLE()) {
         _xmlcfg_close(XML_HANDLE());
         XML_HANDLE("");
      }
      handle := _parseXMLDocComment(orig_comment, description, hashtab, tagList, allowSave, true);
      XML_HANDLE(handle);
      ALLOW_SAVE(allowSave);

      typeless i;
      hashtab._nextel(i);
      /*
        ORDER


         deprecated,param,return,throws,since

         others

         Author

         see
      */
      tag := "";
      wid := _find_control("ctldescription"CURXMLDOCTYPE());
      if (wid) {
         tag="description";
         if (description!="") {
            wid.p_undo_steps=0;
            wid._delete_line();
            wid._insert_text(description);
            /*wid.top();
            status=wid.search( '<code>' ,'r@');
            if (status) {
               wid.up();
               for(;;) {
                  if (wid.down()) break;
                  wid.get_line(line);
                  wid.replace_line(strip(line));
               }
            } */
            wid.p_modify=false;wid.top();
            wid.p_undo_steps=32000;
         }
      }
      wid=_find_control("ctlreturn"CURXMLDOCTYPE());
      if (wid) {
         tag="return";
         // If there is a return value
         if (cm.return_type!=""  && cm.return_type!="void" && cm.return_type!="void VSAPI") {
            if (hashtab._indexin(tag)) {
               wid.p_undo_steps=0;
               wid._delete_line();
               wid._insert_text(hashtab:[tag][0]);
#if 0
               if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)
                    && (def_xmldoc_format_flags & VSJAVADOCFLAG_ALIGN_RETURN)
                   ) {
                  wid.top();
                  status := wid.search( '<code>' ,'rh@');
                  if (status) {
                     wid.up();
                     for(;;) {
                        if (wid.down()) break;
                        line := "";
                        wid.get_line(line);
                        wid.replace_line(strip(line));
                     }
                  }
               }
#endif
               wid.p_modify=false;wid.top();
               wid.p_undo_steps=32000;
               hashtab._deleteel(tag);

            } else {
               // Add @return tag
               init_modified=1;
            }
            wid.p_visible=true;
            wid.p_prev.p_visible=true;
         } else {
            if (hashtab._indexin(tag)) {
               // Remove obsolete @return tag
               init_modified=1;
               hashtab._deleteel(tag);
            }
            wid.p_visible=false;
            wid.p_prev.p_visible=false;
         }
      }

      text := "";
      argName := "";
      templatePrefix := "";
      wid=_find_control("ctlparamcombo"CURXMLDOCTYPE());
      if (wid) {
         tag="param";
         // If there are parameters
         bool hitList[];
         _str new_list[];
         count := 0;
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
         }
         for (i=0;i<count;++i) hitList[i]=false;
         empty_msg := " (empty)";

         for (i=1; i<=tag_get_num_of_locals(); i++) {
            // only process params that belong to this function, not outer functions
            local_seekpos := 0;
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
            param_type := "";
            param_flags := SE_TAG_FLAG_NULL;
            tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
            tag_get_detail2(VS_TAGDETAIL_local_flags,i,param_flags);
            templatePrefix = (param_flags & SE_TAG_FLAG_TEMPLATE)? "<>" : "";
            if (param_type=="param" && local_seekpos>=cm.seekpos) {
               param_name := "";
               tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
               j := xdFindParam("param",param_name,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
               if (j>=0) {
                  xmldocParseParam(hashtab:[tag][j],argName,text,templatePrefix);
                  if (new_list._length()!=j) {
                     init_modified=1;
                  }
                  new_list :+= hashtab:[tag][j];
                  hitList[j]=true;
                  if (text=="") {
                     wid._lbadd_item(param_name:+empty_msg);
                  } else {
                     wid._lbadd_item(param_name);
                  }
               } else {
                  init_modified=1;
                  wid._lbadd_item(param_name:+empty_msg);
                  new_list :+= templatePrefix:+param_name;
               }
            }
         }
         hashtab:["@paramcount"][0]=new_list._length();
         for (i=0;i<count;++i) {
            if (!hitList[i]) {
               xmldocParseParam(hashtab:[tag][i],argName,text,templatePrefix);
               new_list :+= hashtab:[tag][i];
               wid._lbadd_item(argName" (obsolete)");
               if (!def_xmldoc_keep_obsolete) {
                  init_modified=1;
               } else if(text=="") {
                  init_modified=1;
               }
            }
         }
         hashtab:[tag]=new_list;
      }

      widparam := _find_control("ctlparam"CURXMLDOCTYPE());
      if (widparam) {
         if (wid && wid.p_Noflines) {
            HASHTAB(hashtab);
            wid._lbtop();
            wid.p_text=wid._lbget_text();
            //wid.xdShowParam();
            widparam.p_visible=true;
            widparam.p_prev.p_visible=true;
         } else {
            widparam.p_visible=false;
            widparam.p_prev.p_visible=false;
         }
      }

      line := "";
      wid=_find_control("ctlsee"CURXMLDOCTYPE());
      if (wid) {
         tag="see";
         see_msg := "";
         if (hashtab._indexin(tag)) {
            count := hashtab:[tag]._length();
            if (count) {
               wid._lbclear();
            }
            for (i=0;i<count;++i) {
               parse hashtab:[tag][i] with line "\n" ;
               wid.insert_line(line);
            }
            wid.p_modify=false;wid.top();
            hashtab._deleteel(tag);
         }
      }
      wid=_find_control("ctlexample"CURXMLDOCTYPE());
      if (wid) {
         tag="example";
         wid.delete_all();
         wid.insert_line("");
         wid.p_modify=false;
         // If there is example code
         if (hashtab._indexin(tag)) {
            xdParseEditText(hashtab:[tag][0],text,true);
            wid.p_undo_steps=0;
            wid._insert_text(text);
#if 0
            wid.top();
            status := wid.search( '<code>' ,'rh@');
            if (status) {
               wid.up();
               for(;;) {
                  if (wid.down()) break;
                  wid.get_line(line);
                  wid.replace_line(strip(line));
               }
            }
#endif
            wid.p_modify=false;wid.top();
            wid.p_undo_steps=32000;
            hashtab._deleteel(tag);
         }
         wid.p_visible=true;
         wid.p_prev.p_visible=true;
      }

      wid=_find_control("ctlremarks"CURXMLDOCTYPE());
      if (wid) {
         tag="remarks";
         wid.delete_all();
         wid.insert_line("");
         wid.p_modify=false;
         // If there is example code
         if (hashtab._indexin(tag)) {
            xdParseEditText(hashtab:[tag][0],text,true);
            wid.p_undo_steps=0;
            wid._insert_text(text);
            wid.p_modify=false;wid.top();
            wid.p_undo_steps=32000;
            hashtab._deleteel(tag);
         }
         wid.p_visible=true;
         wid.p_prev.p_visible=true;
      }
      HASHTAB(hashtab);

      //MODIFIED(init_modified);
      MODIFIED(0);
      xdShowModified();

      p_active_form.xdResizeControls();
      pic_wid := _find_control("ctlpicture"CURXMLDOCTYPE());
      if (pic_wid) pic_wid.p_visible=true;

   }
}
void ctlimage1.lbutton_down()
{
   _ul2_image_sizebar_handler(ctlok.p_width, ctlpicture3.p_x_extent-ctloptions.p_x);
}
void ctltree1.rbutton_up()
{
   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   flags := def_xmldoc_filter_flags;
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void _xmldoc_form.on_resize(bool doMove=false)
{
   if (doMove) return;
   xdResizeControls();
}

static int _setEditorControlMode(int wid)
{
   if (wid.p_object!=OI_EDITOR) {
      return(0);
   }
   wid.p_buf_name=".xmldoc";
   wid._SetEditorLanguage("xmldoc");
// wid.apply_dtd_changes();
   editorctl_wid := wid._form_parent();
   wid.p_SoftWrap=editorctl_wid.p_SoftWrap;
   wid.p_SoftWrapOnWord=editorctl_wid.p_SoftWrapOnWord;
   wid.p_encoding=editorctl_wid.p_encoding;
   return(0);
}
static int _checkEditorControlModify(int wid)
{
   if (wid.p_object!=OI_EDITOR) {
      return(0);
   }
   if (wid.p_modify) {
      return(1);
   }
   return((int)wid.p_modify);
}
void ctlok.on_create()
{
   XML_HANDLE("");
   CURTREEINDEX("");
   editorctl_wid := _form_parent();
   _setEditorControlMode(ctldescription1.p_window_id);
   _setEditorControlMode(ctldescription2.p_window_id);
   _setEditorControlMode(ctldescription3.p_window_id);
   _setEditorControlMode(ctlexample1.p_window_id);
   _setEditorControlMode(ctlexample2.p_window_id);
   _setEditorControlMode(ctlexample3.p_window_id);
   _setEditorControlMode(ctlparam3.p_window_id);
   _setEditorControlMode(ctlreturn3.p_window_id);
   _setEditorControlMode(ctlremarks3.p_window_id);

   ctlsee1._SetEditorLanguage(editorctl_wid.p_LangId);
   ctlsee2._SetEditorLanguage(editorctl_wid.p_LangId);
   ctlsee3._SetEditorLanguage(editorctl_wid.p_LangId);
   ctlsee1.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee2.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee3.p_window_flags |=VSWFLAG_NOLCREADWRITE;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);
   sentry.lockMatches(true);

   buf_name := editorctl_wid.p_buf_name;
   if (buf_name!="") {
      p_active_form.p_caption=p_active_form.p_caption": "buf_name;
   }
   editorctl_wid._UpdateContext(true);
   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,"","T");
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_xmldoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);
   ctltree1._TreeSizeColumnToContents(0);

   editorctl_wid.save_pos(auto p);
   editorctl_wid.p_col=1;
   editorctl_wid._clex_skip_blanks();
   EditorLN := editorctl_wid.p_RLine;

   current_id := editorctl_wid.tag_current_context();
   nearest_id := editorctl_wid.tag_nearest_context(EditorLN, def_xmldoc_filter_flags, true);
   if (nearest_id > 0 && current_id != nearest_id && editorctl_wid._in_comment()) {
      current_id = nearest_id;
   }

   nearIndex := -1;
   line_num := 0;
   editorctl_wid.restore_pos(p);
   if (current_id>0) {
      tag_get_detail2(VS_TAGDETAIL_context_line, current_id, line_num);
      nearIndex=ctltree1._TreeSearch(TREE_ROOT_INDEX,"","T",line_num);
   }
   if (nearIndex <= 0) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_xmldoc_filter_flags = SE_TAG_FILTER_ANYTHING;
      _xmldoc_refresh_proctree();
      if (ctltree1._TreeCurIndex()<=0 || CURXMLDOCTYPE()=="") {
         nearIndex= ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (nearIndex<0) {
            //p_active_form._delete_window();
            xdHideAll();
            ctltagcaption.p_caption="No symbol selected, check filtering options.";
            tag_unlock_context();
            return;
         }
         ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
      }
      tag_unlock_context();
      return;
   }
   if (ctltree1._TreeCurIndex()!=nearIndex) {
      ctltree1._TreeSetCurIndex(nearIndex);
   } else {
      ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
   }

   // we are done updating the current context
   tag_unlock_context();
}
void _xmldoc_form.on_load()
{
   wid := _find_control("ctldescription"CURXMLDOCTYPE());
   if (wid) {
      wid._set_focus();
   }
}
void ctlok.on_destroy()
{
   if (XML_HANDLE()) {
      _xmlcfg_close(XML_HANDLE());XML_HANDLE("");
   }
   if (TIMER_ID()!="") {
      _kill_timer(TIMER_ID());
   }
}

bool _bas_is_xmldoc_supported()
{
   return true;
}

bool def_c_xmldoc=false;
bool _c_is_xmldoc_supported()
{
   return true;
}
bool _c_is_xmldoc_preferred()
{
   // (clark) Don't want xmldoc_editor command to generate C# style XMLDoc comments in C++ files.
   // For now, don't support xmldoc comment wrapping for C++ and C. At least we support
   // XmlDoc color coding and context tagging XmlDoc comment display for C++ and C.
   // 
   // A better way to do this is pretty complicated and possibly slow because must call analyze
   // the comment that is already present to see if it is an XmlDoc comment 
   // (like _parse_multiline_comments() does). Also, if no comment is present, generate a 
   // XMLDoc comment (or use a def var).
   //
   return def_c_xmldoc;
}

bool _cs_is_xmldoc_supported()
{
   return true;
}

bool _jsl_is_xmldoc_supported()
{
   return true;
}

/** 
 * Check to see if xmldoc comments are supported for <B>lang</B>
 * 
 * @param lang Language to check
 * 
 * @return bool true if xmldoc comments are supported for <B>lang</B>
 */
bool _is_xmldoc_supported(_str lang=null)
{
   if (!_haveContextTagging()) return false;
   if ( lang==null ) lang = p_LangId;
   index := _FindLanguageCallbackIndex("-%s-is-xmldoc-supported",lang);
   if ( index && index_callable(index) ) {
      return call_index(index);
   }
   return false;
}

/** 
 * Check to see if xmldoc comments are the preferred documentation 
 * comment format for <B>lang</B>
 * 
 * @param lang Language to check
 * 
 * @return bool true if xmldoc comments are preferred for <B>lang</B>
 */
bool _is_xmldoc_preferred(_str lang=null)
{
   if ( lang==null ) lang = p_LangId;
   if (!_is_xmldoc_supported) return false;
   index := _FindLanguageCallbackIndex("-%s-is-xmldoc-preferred",lang);
   if ( index && index_callable(index) ) {
      return call_index(index);
   }
   return false;
}

/**
 * Decide whether or not, based on current context, the javadoc
 * comment menu item should be enabled or disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_xmldoc_comment(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || !target_wid._isEditorCtl() || target_wid.p_readonly_mode) {
      return(MF_GRAYED);
   }

   if (!_is_xmldoc_supported(target_wid.p_LangId)) {
      return(MF_GRAYED);
   }

   save_pos(auto p);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   context_id := tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   restore_pos(p);
   if (context_id <= 0) {
      return(MF_GRAYED);
   }
   // get the multi-line comment start string
   slcomment_start := "";
   mlcomment_start := "";
   mlcomment_end   := "";
   xmldocSupported := false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,xmldocSupported) /*|| !xmldocSupported*/) {
      return(MF_GRAYED);
   }

   status := _EmbeddedCallbackAvailable("_%s_generate_function");
   if (status) {
      return(MF_ENABLED);
   }
   status = _EmbeddedCallbackAvailable("_%_fcthelp_get_start");
   if (status) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}



/**
 * Create an xmlDoc-style comment for the current function
 * 
 * @return 0 on success, <0 on error
 */
static int _xmldoc_comment(_str slcomment_start_seq = "///")
{
   // get the multi-line comment start string
   slcomment_start := "";
   mlcomment_start := "";
   mlcomment_end   := "";
   xmldocSupported := false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,xmldocSupported)/* || !xmldocSupported */) {
      _message_box("XML documentation comment not supported for this file type");
      return(1);
   }

   return _document_comment(slcomment_start_seq);
}

/**
 * Generate a xmldoc-style comment for the current tag.  Will attempt
 * to convert the current comment to xmldoc.
 * <p>
 * This function is supported for C# and C++ only;
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void xmldoc_comment(_str slcomment_start = "///") name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( !_is_xmldoc_supported() ) {
      _message_box("XML documentation comment not supported for this file type");
      return;
   }
   _EmbeddedCall(_xmldoc_comment, slcomment_start);
}

int _OnUpdate_xmldoc_editor(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveContextTagging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   return(_OnUpdate_xmldoc_comment(cmdui,target_wid,command));
}

_command void xmldoc_editor(_str deprecate="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "XMLDOC Editor");
      return;
   }
   if (p_active_form.p_name == "_javadoc_form" || p_active_form.p_name=="_xmldoc_form") {
      return;
   }
   // get the multi-line comment start string
   slcomment_start := "";
   mlcomment_start := "";
   mlcomment_end   := "";
   xmldocSupported := false;
   if (get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,xmldocSupported) || slcomment_start!="//") {
      _message_box("XMLDOC comment not supported for this file type");
      return;
   }
   show("-xy -modal _xmldoc_form");
}

/**
 * On entry, cursor is on line, column of tag symbol.  Finds the starting line
 * and ending line for the tag's comments.
 *
 * @param first_line  (output) set to first line of comment
 * @param last_line   (output) set to last line of comment
 *
 * @return 0 if header comment found and first_line,last_line
 *          set.  Otherwise, 1 is returned.
 */
int _xmldoc_get_tag_header_comments(int &first_line,int &last_line) {

   // Comments start at the beginning of the <summary> line and continue through
   // the </member> tag

   //say('start _xmldoc_get_tag_header_comments');

   save_pos(auto p);  // save original start position
   status := search("<summary>","h@xcs");
   if (status) {
      restore_pos(p);
      return(1);
   }

   //say('found <summary>');

   first_line=p_line;  // <summary> found, save current line

   // find the next </member> tag
   status=search("</member>","h@xcs");
   if (status) {
      restore_pos(p);
      return(1);
   }

   //say('found </member>');

   last_line=p_line-1;  // don't include the end member tag
   //say('found cmnt firstln: 'first_line'  lastln: 'last_line);

   restore_pos(p);
   return(0);
}  // _xmldoc_get_tag_header_comments

static void xdcmd_maybe_deselect_command(typeless pfn)
{
   if (!in_cua_select) {
      if (select_active()) {
         if ( _select_type("",'U')!='P') {
            _deselect();
         }
      }
   }
   (*pfn)();
}
static void xdcmd_rubout()
{
   if(xdmaybe_delete_selection()) return;
   _rubout();
}
static void xdcmd_linewrap_rubout()
{
   if(xdmaybe_delete_selection()) return;
   if (p_col!=1) {
      _rubout();
      return;
   }
   save_pos(auto p);
   up();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   down();
   linewrap_rubout();
}
static void xdcmd_delete_char()
{
   if(xdmaybe_delete_selection()) return;
   _delete_char();
}
static void xdcmd_linewrap_delete_char()
{
   if(xdmaybe_delete_selection()) return;
   if (p_col<=_text_colc()) {
      _delete_char();
      return;
   }
   save_pos(auto p);
   down();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   up();
   linewrap_delete_char();
}
static void xdcmd_cua_select()
{
   in_cua_select=true;
   cua_select();
   in_cua_select=false;
}

static void xdcmd_cut_line()
{
   xdmaybe_delete_selection();
   cut_line();
   if (_lineflags()& HIDDEN_LF) {
      up();insert_line("");
      _lineflags(0,HIDDEN_LF);
   }
}
static void xdcmd_delete_line()
{
   xdmaybe_delete_selection();
   _delete_line();
   if (_lineflags()& HIDDEN_LF) {
      up();insert_line("");
      _lineflags(0,HIDDEN_LF);
   }
}
static void xdcmd_join_line()
{
   save_pos(auto p);
   down();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   join_line();
}
static void xdcmd_cut_end_line()
{
   if(xdmaybe_delete_selection()) return;
   if (p_col<=_text_colc()) {
      cut_end_line();
      return;
   }
   save_pos(auto p);
   down();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   up();
   cut_end_line();
}
static void xdcmd_erase_end_line()
{
   if(xdmaybe_delete_selection()) return;
   if (p_col<=_text_colc()) {
      erase_end_line();
      return;
   }
   save_pos(auto p);
   down();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   up();
   erase_end_line();
}
/**
 * Parse the components out of a standard XMLDoc comment.
 *
 * @param member_msg     comment to parse
 * @param description    set to description of javadoc comment
 * @param hashtab        hash table of javadoc tags -> messages
 * @param tagList        list of tags found in message
 */
int _parseXMLDocComment(_str &member_msg,_str &description,_str (&hashtab):[][],_str (&tagList)[], bool &allowSave, bool allowInvalidXML)
{
   hashtab._makeempty();
   tagList._makeempty();

   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   _insert_text("<document>");_insert_text(member_msg);
   get_line(auto line);
   if(line=="") _delete_line();
   bottom();_insert_text("\n</document>");_delete_text(-2);
   allow_save := true;
   status := 0;
   handle := _xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (handle<0) {
      if (!allowInvalidXML) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return handle;
      }
      delete_all();
      insert_line("<document>");
      insert_line("<summary>XML not valid.  Correct the XML comment and try again.</summary>");
      insert_line("</document>");
      handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      allow_save=false;
   }
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   //XML_HANDLE(handle);
   allowSave=allow_save;

   description=member_msg;
   /*
       Look for description tag
         summary, remarks, value, or exception
   */
   node_index := _xmldoc_find_description_node(handle);
   description=_xmldoc_get_xml_as_text(handle,node_index);


   typeless array[];
   _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
   tag := "typeparam";
   for (i:=0;i<array._length();++i) {
      //say('name='_xmlcfg_get_attribute(handle,array[i],'name'));
      //say('text='_xmldoc_get_xml_as_text(handle,array[i]));
      hashtab:["param"] :+= "<>" :+ _xmlcfg_get_attribute(handle,array[i],"name")" "_xmldoc_get_xml_as_text(handle,array[i]);
      tagList :+= tag;
   }
   array._makeempty();
   _xmlcfg_find_simple_array(handle,"/document/param",array);
   tag = "param";
   for (i=0;i<array._length();++i) {
      //say('name='_xmlcfg_get_attribute(handle,array[i],'name'));
      //say('text='_xmldoc_get_xml_as_text(handle,array[i]));
      hashtab:[tag] :+= _xmlcfg_get_attribute(handle,array[i],"name")" "_xmldoc_get_xml_as_text(handle,array[i]);
      tagList :+= tag;
   }
   node_index=_xmlcfg_find_simple(handle,"/document/returns");
   if (node_index>=0) {
      tag="return";
      hashtab:[tag] :+= _xmldoc_get_xml_as_text(handle,node_index);
      tagList :+= tag;
   }
   _xmlcfg_find_simple_array(handle,"/document/seealso",array);
   tag="see";
   for (i=0;i<array._length();++i) {
      cref := _xmlcfg_get_attribute(handle,array[i],"cref");
      if (cref!="") {
         hashtab:[tag] :+= cref;
         tagList :+= tag;
      }
   }
   node_index=_xmlcfg_find_simple(handle,"/document/example");
   if (node_index>=0) {
      tag="example";
      hashtab:[tag] :+= _xmldoc_get_xml_as_text(handle,node_index);
      tagList :+= tag;
   }
   node_index=_xmlcfg_find_simple(handle,"/document/remarks");
   if (node_index>=0) {
      tag="remarks";
      hashtab:[tag] :+= _xmldoc_get_xml_as_text(handle,node_index);
      tagList :+= tag;
   }
   return handle;
}
defeventtab _xmldoc_preview_form;
void _xmldoc_preview_form.on_create(_str htmltext)
{
   ctlminihtml1.p_text=htmltext;

   ctlminihtml1._codehelp_set_minihtml_fonts(
      _default_font(CFG_FUNCTION_HELP),
      _default_font(CFG_FUNCTION_HELP_FIXED));
}
void _xmldoc_preview_form.on_resize(bool doMove)
{
   if (doMove) return;
   ctlminihtml1._move_window(0,0,_dx2lx(SM_TWIP,p_client_width),_dy2ly(SM_TWIP,p_client_height));
}
void _xmldoc_preview_form.esc()
{
   p_active_form.call_event(defeventtab _ainh_dlg_manager,A_F4,'e');
}

defeventtab _xmldoc_format_form;
void ctlok.on_create()
{
   //ctlbeautify.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BEAUTIFY;
   ctlparamblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   ctlparamgroupblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   ctlreturnblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   ctlexampleblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   ctldescriptionblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;
   ctlremarksblank.p_value=def_xmldoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS;
}
void ctlok.lbutton_up()
{
   old_def_xmldoc_format_flags := def_xmldoc_format_flags;

   _macro('m',_macro('s'));
   if(ctlparamblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   }
   if(ctlparamgroupblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   }
   if(ctlreturnblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   }
   if(ctlexampleblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   }
   if(ctldescriptionblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;
   }
   if(ctlremarksblank.p_value) {
      def_xmldoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS;
   } else {
      def_xmldoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS;
   }
   if(old_def_xmldoc_format_flags!=def_xmldoc_format_flags) {
      _macro_append("def_xmldoc_format_flags="def_xmldoc_format_flags";");
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);

   p_active_form._delete_window();
}
/**
 * Look for description tag summary, remarks, value, or exception
 *
 * @param handle Handle to xmlcfg tree
 *
 * @return Returns xmlcfg tree node handle.
 */
static int _xmldoc_find_description_node(int handle)
{

   node_index := _xmlcfg_find_simple(handle,"/document/summary");
   if (node_index<0) {
      node_index=_xmlcfg_find_simple(handle,"/document/value");
      if (node_index<0) {
         node_index=_xmlcfg_find_simple(handle,"/document/exception");
      }
   }
   return(node_index);
}
_str _xmldoc_get_xml_as_text(int handle,int node_index)
{
   if (node_index<0) {
      return("");
   }
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   status := _xmlcfg_save_to_buffer(p_window_id,handle,0 /* Preserce PCDATA white space */,VSXMLCFG_SAVE_PRESERVE_PCDATA,node_index);
   top();

   line := "";
   status=search( "<code>" ,"rh@");
   if (status) {
      min_col := 0;
      // Skip the first line.
      // Find the non-blank line with the least number of spaces
      for (;;) {
         if (down()) {
            break;
         }
         get_line(line);
         if (line!="") {
            _first_non_blank();
            if (p_col<min_col || !min_col) {
               min_col=p_col;
            }
         }
      }
      if (min_col) {
         // Remove leading blanks from all but first line
         top();
         for (;;) {
            if (down()) {
               break;
            }
            get_line(line);
            if (line!="") {
               replace_line(_expand_tabsc(min_col,-1,"S"));
            }
         }
      }
   }
   top();
   description := get_text(p_buf_size);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   return(description);
}
void _showxml(int handle,
              int node_index=TREE_ROOT_INDEX,
              int flags=VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,
              int IndentAmount=3)
{
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(0,handle,IndentAmount,flags,node_index);
   xml_mode();
   _showbuf(p_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
}
static void _xmldoc_add_blank_line_after(int handle,int node_index)
{
   next_index := _xmlcfg_get_next_sibling(handle,node_index,~VSXMLCFG_NODE_ATTRIBUTE);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      line := _xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      first := second := "";
      parse line with first "\n" second "\n";
      if (first=="" && second=="" && pos("?*\n?*\n",line,1,"r")) {
         return;
      }
      if (first=="" && second=="") {
         if (_xmlcfg_get_next_sibling(handle,next_index,~VSXMLCFG_NODE_ATTRIBUTE)<0) {
            return;
         }
      }
      if (first=="" && second=="") {
         _xmlcfg_set_value(handle,next_index,"\n\n");
         return;
      }
   }
   if (next_index<0) {
      return;
   }
   newline_index := _xmlcfg_add(handle,node_index,"",VSXMLCFG_NODE_PCDATA,0);
   _xmlcfg_set_value(handle,newline_index,"\n");
}
static int _xmldoc_add_linebreak(int handle,int node_index)
{
   next_index := _xmlcfg_get_next_sibling(handle,node_index,~VSXMLCFG_NODE_ATTRIBUTE);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      line := _xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      first := second := "";
      parse line with first "\n" second "\n";
      if (first=="" && pos("?*\n",line,1,"r")) {
         return(next_index);
      }
      _xmlcfg_set_value(handle,next_index,"\n":+line);
      return(next_index);
   }
   newline_index := _xmlcfg_add(handle,node_index,"",VSXMLCFG_NODE_PCDATA,0);
   _xmlcfg_set_value(handle,newline_index,"\n");
   return(newline_index);
}

/**
 * Translate the given XMLDoc formatted comment to HTML for display using 
 * function argument help or list members comment help or the Preview tool window. 
 * 
 * @param comment_text    XMLDoc comment text with comment delimeters removed
 * @param return_type     Return type of function being with this comment
 * @param param_name      Name of current parameter (for function-argument help)
 * 
 * @return 
 * Returns formatted HTML for this comment. 
 *  
 * @deprecated Use tag_tree_make_html_comment() instead. 
 */
_str _xmldoc_xlat_to_html(_str comment_text,_str return_type,_str param_name="")
{
   tag_tree_make_html_comment(auto html_text, VSCODEHELP_COMMENTFLAG_XMLDOC, comment_text, param_name, return_type, p_LangId, false, false);
   return html_text;
}
void _xmldoc_remove_blank_line(int handle,int index)
{
   next_index := _xmlcfg_get_next_sibling(handle,index,-1);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      line := _xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      first := second := rest := "";
      parse line with first "\n" second "\n";
      if (first=="" && second=="" && pos("\n?*\n",line,1,"r")) {
         parse line with first "\n" rest;
         _xmlcfg_set_value(handle,next_index,rest);
      }
   }
}
void _xmldoc_remove_eol(int handle,int index)
{
   next_index := _xmlcfg_get_next_sibling(handle,index,-1);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      line := _xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      first := second := rest := "";
      parse line with first "\n" second "\n";
      if (first=="" && pos("\n",line,1,"r")) {
         parse line with first "\n" rest;
         _xmlcfg_set_value(handle,next_index,rest);
      }
   }
}

// updates parameter list and add/removes return
void _xmldoc_update_doc_comment(_str orig_comment, _str (&signature):[][], int start_col, int first_line, int last_line)
{
   status := 0;
   _str hashtab:[][];
   _str tagList[];
   description := "";
   allowSave := false;
   handle := _parseXMLDocComment(orig_comment, description, hashtab, tagList, allowSave, false);
   if (handle < 0) {
      status = _message_box("XML not valid.  Delete existing comment and continue?", "", MB_YESNO|MB_ICONEXCLAMATION);
      if (status == IDNO) {
         return;
      }

      temp_view_id := 0;
      orig_view_id := _create_temp_view(temp_view_id);
      delete_all();
      insert_line("<document><summary>");
      insert_line("");
      insert_line("</summary>");
      insert_line("</document>");
      handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      if (handle < 0) {
         return;
      }
   }

   slcomment_start := "///";
   mlcomment_start := "///";
   mlcomment_end := "///";

   i := 0;
   count := 0;
   dest_node_index := 0;
   next_index := 0;
   newline_index := 0;
   index := 0;
   typeless array[];
   tag := "";
   line := "";
   argName := "";
   list := "";
   temp_handle := 0;
   
   hit_error := false;
   error_info := "";

   dest_encoding := p_encoding;
   temp_handle =_xmlcfg_create("",dest_encoding);
   if (temp_handle < 0) {
      _xmlcfg_close(handle);
      return;
   }
   status = _xmlcfg_copy(temp_handle, 0, handle, 0, VSXMLCFG_COPY_CHILDREN);

   // update type parameter list
   type_param_node_index := -1;
   _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
   if (array._length() > 0) {
      type_param_node_index = _xmlcfg_get_prev_sibling(handle, array[0], -1);
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_blank_line(handle,array[i]);
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
   }

   // update parameter list
   param_node_index := -1;
   _xmlcfg_find_simple_array(handle,"/document/param",array);
   if (array._length() > 0) {
      param_node_index = _xmlcfg_get_prev_sibling(handle, array[0], -1);
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_blank_line(handle,array[i]);
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
   }

   dest_node_index=_xmlcfg_find_simple(handle,"/document");
   if (signature._indexin("typeparam")) {
      int copy_param[];
      count = signature:["typeparam"]._length();
      _xmlcfg_find_simple_array(temp_handle,"/document/typeparam",array);

      // find matching params in old comment
      for (i = 0; i < count; ++i) {
         argName = signature:["typeparam"][i];
         copy_param[i] = -1;  // initialize

         for (k := 0; k < array._length(); ++k) {
            if ((array[k] > 0) && strieq(_xmlcfg_get_attribute(temp_handle,array[k],"name"), argName)) {
               copy_param[i] = array[k];
               array[k] = -1;
            }
         }
      }

      // re-use old parameters if available
      for (i = 0; i < array._length() && i < count; ++i) {
         if ((copy_param[i] < 0) && (array[i] > -1)) {
            copy_param[i] = array[i];
         }
      }

      for (i = 0; i < count; ++i) {
         if (type_param_node_index < 0) {
            dest_node_index=_xmlcfg_add(handle,dest_node_index,"typeparam",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         } else {
            dest_node_index=_xmlcfg_add(handle,type_param_node_index,"typeparam",VSXMLCFG_NODE_ELEMENT_START,0);
         }

         if (dest_node_index >= 0) {
            argName = signature:["typeparam"][i];
            _xmlcfg_set_attribute(handle,dest_node_index,"name",argName);
            index = copy_param[i];
            if (index > 0) {
               if (_xmlcfg_get_first_child(temp_handle, index,~VSXMLCFG_NODE_ATTRIBUTE) > 0) {
                  status = _xmlcfg_copy(handle,dest_node_index,temp_handle,index,VSXMLCFG_COPY_CHILDREN);
               }  
            }
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            type_param_node_index=newline_index;
         }
      }
   }

   dest_node_index=_xmlcfg_find_simple(handle,"/document");
   if (signature._indexin("param")) {
      int copy_param[];
      count = signature:["param"]._length();
      _xmlcfg_find_simple_array(temp_handle,"/document/param",array);

      // find matching params in old comment
      for (i = 0; i < count; ++i) {
         argName = signature:["param"][i];
         copy_param[i] = -1;  // initialize

         for (k := 0; k < array._length(); ++k) {
            if ((array[k] > 0) && strieq(_xmlcfg_get_attribute(temp_handle,array[k],"name"), argName)) {
               copy_param[i] = array[k];
               array[k] = -1;
            }
         }
      }

      // re-use old parameters if available
      for (i = 0; i < array._length() && i < count; ++i) {
         if ((copy_param[i] < 0) && (array[i] > -1)) {
            copy_param[i] = array[i];
         }
      }

      for (i = 0; i < count; ++i) {
         if (param_node_index < 0) {
            dest_node_index=_xmlcfg_add(handle,dest_node_index,"param",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         } else {
            dest_node_index=_xmlcfg_add(handle,param_node_index,"param",VSXMLCFG_NODE_ELEMENT_START,0);
         }

         if (dest_node_index >= 0) {
            argName = signature:["param"][i];
            _xmlcfg_set_attribute(handle,dest_node_index,"name",argName);
            index = copy_param[i];
            if (index > 0) {
               if (_xmlcfg_get_first_child(temp_handle, index,~VSXMLCFG_NODE_ATTRIBUTE) > 0) {
                  status = _xmlcfg_copy(handle,dest_node_index,temp_handle,index,VSXMLCFG_COPY_CHILDREN);
               }  
            }
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            param_node_index=newline_index;
         }
      }
   }

   // check returns
   dest_node_index = _xmlcfg_find_simple(handle, "/document/returns");
   if (dest_node_index < 0) {
      // add?
      if (signature._indexin("return")) {
         return_type :=  signature:["return"][0];
         if (return_type!="" && return_type!="void" && return_type!="void VSAPI") {
            dest_node_index=_xmlcfg_find_simple(handle,"/document");

            temp_index  := 0;
            after_index := dest_node_index;
            flags := VSXMLCFG_ADD_AS_CHILD;
            _xmlcfg_find_simple_array(handle,"/document/param",array);
            if (array._isempty()) {
               _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
            }
            if (array._length()) {
               flags = 0;
               after_index = (int)array[array._length()-1];
            } else {
               temp_index = _xmlcfg_find_simple(handle,"/document/remarks");
               if (temp_index < 0) {
                  temp_index = _xmldoc_find_description_node(handle);
               }
               if (temp_index >= 0) {
                  flags = 0; after_index = temp_index;
               } else {
                  after_index = dest_node_index;
                  flags = VSXMLCFG_ADD_AS_CHILD;
               }
            }
            temp_index = _xmlcfg_add(handle,after_index,"\n",VSXMLCFG_NODE_PCDATA,flags);
            dest_node_index = _xmlcfg_add(handle,(!flags)?temp_index:after_index,"returns",VSXMLCFG_NODE_ELEMENT_START,flags);
         }
      }
   } else {
      // remove?
      return_type := "";
      if (signature._indexin("return")) {
         return_type = signature:["return"][0];
      }
      if (return_type=="" || return_type=="void" || return_type=="void VSAPI") {
         _xmldoc_remove_blank_line(handle, dest_node_index);
         _xmldoc_remove_eol(handle, dest_node_index);
         _xmlcfg_delete(handle, dest_node_index);
      }
   }
   _xmlcfg_close(temp_handle);

   // run beautify options
   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION)) {
      index=_xmldoc_find_description_node(handle);
      if (index>=0) {
         _xmldoc_add_blank_line_after(handle,index);
      }
   }

   index=_xmlcfg_find_simple(handle,"/document/returns");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);

      }
   }
   index=_xmlcfg_find_simple(handle,"/document/example");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);
      }
   }
   index=_xmlcfg_find_simple(handle,"/document/remarks");
   if (index>=0) {
      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS)) {
         _xmldoc_add_blank_line_after(handle,index);
      } else {
         _xmldoc_remove_blank_line(handle,index);
      }
   }
   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & (VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS|VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM))
      ) {
      _xmlcfg_find_simple_array(handle,"/document/typeparam",array);
      if (array._length()) {
         if (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS) {
            for (i=0;i<array._length();++i) {
               _xmldoc_add_blank_line_after(handle,array[i]);
            }
         } else {
            // only insert extra blank here if there are no non-type parameters 
            _xmlcfg_find_simple_array(handle,"/document/param",array);
            if (array._isempty()) {
               _xmldoc_add_blank_line_after(handle,array[array._length()-1]);
            }
         }
      }
   }
   if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
       (def_xmldoc_format_flags & (VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS|VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM))
      ) {
      _xmlcfg_find_simple_array(handle,"/document/param",array);
      if (array._length()) {
         if (def_xmldoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS) {
            for (i=0;i<array._length();++i) {
               _xmldoc_add_blank_line_after(handle,array[i]);
            }
         } else {
            _xmldoc_add_blank_line_after(handle,array[array._length()-1]);
         }
      }
   }

   // nuke the original comment lines (if there were any)
   num_lines := last_line-first_line+1;
   if (num_lines > 0 && !(orig_comment == "")) {
      p_line=first_line;
      for (i=0; i<num_lines; i++) {
         _delete_line();
      }
   }
   // put us where we need to be
   p_line = first_line - 1;

   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(0,handle,0,VSXMLCFG_SAVE_PRESERVE_PCDATA);
   len := length("<document>");
   top();_delete_text(len);bottom();p_col-=len+1;_delete_text(len+1);
   if (_line_length()==0) {
      _delete_line();
   }
   top();
   prefix := indent_string(start_col-1):+slcomment_start:+" ";
   search("^"substr("",1,p_SyntaxIndent),"rh@",prefix);
   temp_buf_id := p_buf_id;
   activate_window(orig_view_id);
   _buf_transfer(temp_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   _xmlcfg_close(handle);
}

