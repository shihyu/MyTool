////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50341 $
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
#import "context.e"
#import "cutil.e"
#import "dlgman.e"
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

static boolean in_cua_select;

static void jdcmd_maybe_deselect_command(typeless pfn);
static void jdcmd_rubout();
static void jdcmd_linewrap_rubout();
static void jdcmd_delete_char();
static void jdcmd_linewrap_delete_char();
static void jdcmd_cua_select();

static void jdcmd_cut_line();
static void jdcmd_join_line();
static void jdcmd_delete_line();
static void jdcmd_cut_end_line();
static void jdcmd_erase_end_line();

static int _setEditorControlMode(int wid);

static typeless JavadocCommands:[]={
   "rubout"                    =>jdcmd_rubout,
   "linewrap-rubout"           =>jdcmd_linewrap_rubout,
   "delete-char"               =>jdcmd_delete_char,
   "vi-forward-delete-char"    =>jdcmd_delete_char,
   "linewrap-delete-char"      =>jdcmd_linewrap_delete_char,
   "brief-delete"              =>jdcmd_linewrap_delete_char,

   "cut-line"                  =>jdcmd_cut_line,
   "join-line"                 =>jdcmd_join_line,
   "cut"                       =>jdcmd_cut_line,
   "delete-line"               =>jdcmd_delete_line,
   "cut-end-line"              =>jdcmd_cut_end_line,
   "erase-end-line"            =>jdcmd_erase_end_line,

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
   "cua-select"                =>jdcmd_cua_select,
   "deselect"                  =>deselect,
   "copy-to-clipboard"         =>copy_to_clipboard,

   "bottom-of-buffer"          =>{jdcmd_maybe_deselect_command,bottom_of_buffer},

   "top-of-buffer"             =>{jdcmd_maybe_deselect_command,top_of_buffer},

   "page-up"                   =>{jdcmd_maybe_deselect_command,page_up},

   "vi-page-up"                =>{jdcmd_maybe_deselect_command,page_up},

   "page-down"                 =>{jdcmd_maybe_deselect_command,page_down},

   "vi-page-down"              =>{jdcmd_maybe_deselect_command,page_down},


   "cursor-left"               =>{jdcmd_maybe_deselect_command,cursor_left},
   "vi-cursor-left"            =>{jdcmd_maybe_deselect_command,cursor_left},

   "cursor-right"              =>{jdcmd_maybe_deselect_command,cursor_right},
   "vi-cursor-right"           =>{jdcmd_maybe_deselect_command,cursor_right},

   "cursor-up"                 =>{jdcmd_maybe_deselect_command,cursor_up},
   "vi-prev-line"              =>{jdcmd_maybe_deselect_command,cursor_up},

   "cursor-down"               =>{jdcmd_maybe_deselect_command,cursor_down},
   "vi-next-line"              =>{jdcmd_maybe_deselect_command,cursor_down},

   "begin-line"                =>{jdcmd_maybe_deselect_command,begin_line},

   "begin-line-text-toggle"    =>{jdcmd_maybe_deselect_command,begin_line_text_toggle},

   "brief-home"                =>{jdcmd_maybe_deselect_command,begin_line},

   "vi-begin-line"             =>{jdcmd_maybe_deselect_command,begin_line},

   "vi-begin-line-insert-mode" =>{jdcmd_maybe_deselect_command,begin_line},

   "brief-end"                 =>{jdcmd_maybe_deselect_command,end_line},
   "end-line"                  =>end_line,
   "vi-end-line"               =>{jdcmd_maybe_deselect_command,end_line},
   "vi-end-line-append-mode"   =>{jdcmd_maybe_deselect_command,end_line},
   "mou-click"                 =>mou_click,
   "mou-extend-selection"      =>mou_extend_selection,
   "mou-select-line"           =>mou_select_line,

   "select-line"               =>select_line,
   "brief-select-line"         =>select_line,
   "select-char"               =>select_char,
   "brief-select-char"         =>select_char,
};

boolean def_xmldoc_keep_obsolete=false;

#define JDMIN_EDITORCTL_HEIGHT  600
/**
 * Amount in twips to indent in the Y direction after a label control
 */
#define JDY_AFTER_LABEL   28
/**
 * Amount in twips to indent in the Y direction after controls that do not have
 * a specific indent
 */
#define JDY_AFTER_OTHER   100
#define JDX_BETWEEN_TEXT_BOX  200

#define JAVATYPE_CLASS    1
#define JAVATYPE_DATA     2
#define JAVATYPE_METHOD   3
#define JAVATYPE_LAST     3

_control ctlcancel;

#define CURJAVATYPE ctlok.p_user
#define MODIFIED ctltree1.p_user
#define TIMER_ID ctltagcaption.p_user
#define HASHTAB ctlcancel.p_user
#define CURTREEINDEX p_active_form.p_user
#define ALLOW_SAVE   ctlpicture1.p_user
#define XML_HANDLE   ctldescription1.p_user
   _control ctltree1;
   _control ctldescription1;

defeventtab _xmldoc_form;
void ctloptions.lbutton_up()
{
   show('-modal _xmldoc_format_form');
}
static void jdSetupSeeContextTagging()
{
   if (p_user!="") {
      return;
   }
   p_user=1;
   //say('initializing data');
   boolean orig_modify=p_modify;
   int orig_linenum=p_line;
   int orig_col=p_col;
   top();
   _str text=get_text(p_buf_size);
   /*if (length(text)<length(p_newline) ||
       substr() {
   } */

   typeless markid=_alloc_selection();
   int editorctl_wid=_form_parent();
   typeless p;
   editorctl_wid.save_pos(p);
   editorctl_wid.top();
   editorctl_wid._select_line(markid);
   editorctl_wid.bottom();
   editorctl_wid._select_line(markid);
   int undo_steps=p_undo_steps;p_undo_steps=0;
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

   int orig_wid=p_window_id;
   int orig_view_id;
   get_window_id(orig_view_id);
   p_window_id=editorctl_wid;
   _UpdateContext(true);
   VS_TAG_BROWSE_INFO cm;
   _str proc_name,path;
   int start_line_no=-1;
   int javatype;
   orig_wid.ctltree1._ProcTreeTagInfo2(editorctl_wid,cm,proc_name,path,start_line_no,orig_wid.CURTREEINDEX);
   activate_window(orig_view_id);

   p_RLine=start_line_no;
   p_col=1;
   up();
   _str line="";
   int restore_linenum=0;
   int i;
   for (i=1;;++i) {
      if (text:=='') break;
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
   jdSetupSeeContextTagging();
}


static void jdEditControlEventHandler()
{
   _str lastevent=last_event();
   _str eventname=event2name(lastevent);
   //messageNwait("_EditControlEventHandler: eventname="eventname" _select_type()="_select_type());
   if (eventname=='F1' || eventname=='A-F4' || eventname=='ESC' || eventname=='TAB' || eventname=='S-TAB') {
      call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
      return;
      //help('Diff Dialog box');
   }
   if (eventname=='MOUSE-MOVE') {
      return;
   }
   /*if (eventname=='RBUTTON-DOWN ') {
      edit_window_rbutton_up();
      return;
   } */
   typeless status=0;
   if (substr(eventname,1,2)=='A-' && isalpha(substr(eventname,3,1))) {
      _str letter="";
      parse event2name(last_event()) with 'A-' letter;
      status=_dmDoLetter(letter);
      if (!status) return;
   }
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,p_mode_eventtab,key_index);
   _str command_name=name_name(name_index);

   //This is to handle C-X combinations
   if (name_type(name_index)==EVENTTAB_TYPE) {
      int eventtab_index2=name_index;
      _str event2=get_event('k');
      key_index=event2index(event2);
      name_index=eventtab_index(_default_keys,eventtab_index2,key_index);
      command_name=name_name(name_index);
   }
   typeless junk=0;
   if (JavadocCommands._indexin(command_name)) {
      boolean old_dragdrop=def_dragdrop;
      def_dragdrop=false;
      switch (JavadocCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         (*JavadocCommands:[command_name])();
         break;
      case VF_ARRAY:
         junk=(*JavadocCommands:[command_name][0])(JavadocCommands:[command_name][1]);
         break;
      }
      def_dragdrop=old_dragdrop;
   } else {
      if (command_name!='') {
         if (pos('\-space$',command_name,1,'r')) {
            keyin(' ');
         }else if (pos('\-enter$',command_name,1,'r')) {
            split_insert_line();
         }else if (pos('\maybe-case-backspace$',command_name,1,'r')) {
            jdcmd_linewrap_rubout();
         }else if (pos('\-backspace$',command_name,1,'r')) {
            jdcmd_linewrap_rubout();
         }
      }
   }

   p_scroll_left_edge=-1;

}
//void ctlsee1.\0-\33,\129-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
void ctlsee1.'range-first-nonchar-key'-'all-range-last-nonchar-key',' ', 'range-first-mouse-event'-'all-range-last-mouse-event',ON_SELECT()
{
   jdEditControlEventHandler();
}
static void jdDoCharKey()
{
   _str key=last_event();
   int index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(key));
   _str cmdname=name_name(index);
   if (pos('auto-codehelp-key',cmdname) || 
       pos('auto-functionhelp-key',cmdname)
       ) {
      call_index(find_index(cmdname,name_type(index)));
      return;
   }
   keyin(key);
}
#if 0
static void jd_multi_delete(_str cmdline="")
{
   _str line="";
   if ((cmdline==''||p_word_wrap_style&WORD_WRAP_WWS) && OnImaginaryLine()) {
      get_line(line);
      //if (p_col==length(line)) return;
      if (p_col>=length(expand_tabs(line))) return;
   }
   if (p_col > _line_length()) {
      if (!down()) {
         if (OnImaginaryLine()) {
            if (cmdline=='' ||
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

   int wid=0;
   int otherwid=p_window_id.GetOtherWid(wid);
   int orig_numlines=p_Noflines;
   wid._undo('S');
   otherwid._undo('S');

   int origline=wid.p_line;
   wid.get_line(line);
   boolean onlast=OnLastLine();
   int isimaginary=wid._lineflags()&NOSAVE_LF;
   if (isimaginary && !DialogIsDiff()) {
      return;
   }
   boolean oldmodify=false;
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
      int oldwid=p_window_id;p_window_id=wid;
      _delete_selection();
      p_window_id=oldwid;
      wid.keyin(last_event());
      break;
   }
   if (wid.p_Noflines<orig_numlines) {
      int cur_num_lines=wid.p_Noflines;
      otherwid.p_line=origline;
      if (!wid.OnLastLine()) {
         otherwid.p_line=wid.p_line;
      }
      int i;
      for (i=1;i<=orig_numlines-cur_num_lines;++i) {
         int old_col=p_col;
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

static int jdmaybe_delete_selection()
{
   if (!command_state() && select_active()) {
      if ( _select_type('','U')=='P' && _select_type('','S')=='E' ) {
         return(0);
      }
      if ( def_persistent_select=='D'  && !_QReadOnly() ) {
         _begin_select();
         if (_select_type()=='LINE') {
            p_col=1;_delete_selection();
            if (_lineflags() & HIDDEN_LF) {
               up();
               insert_line('');
               _lineflags(0,HIDDEN_LF);
            }
         } else if (_select_type()=='CHAR') {
            _end_select();
            _end_line();
            down();
            if (_lineflags()& HIDDEN_LF) {
               int first_col=0, last_col=0, junk=0;
               _get_selinfo(first_col,last_col,junk);
               if(p_col<last_col+_select_type('','i')) {
                  up();insert_line('');
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
void ctlsee1.\33-'range-last-char-key'()
{
   jdmaybe_delete_selection();
   jdDoCharKey();
}
#if 0
void ctlsee1.'<'()
{
}
void ctlsee1.'<'()
{
   _str line="";
   jdmaybe_delete_selection();
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
   _str line="";
   jdmaybe_delete_selection();
   get_line(line);
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      keyin('#');
      return;
   }
   auto_codehelp_key();
}
#endif
void ctlparam3.'TAB'()
{
   int wid=_find_control('ctlparamcombo'CURJAVATYPE);
   if (wid.p_line<wid.p_Noflines) {
      wid._lbdown();
      wid.p_text=wid._lbget_text();
   } else {
      call_event(defeventtab _ainh_dlg_manager,TAB,'E');
   }
}
void ctlparam3.'S-TAB'()
{
   int wid=_find_control('ctlparamcombo'CURJAVATYPE);
   if (wid.p_line>1) {
      wid._lbup();
      wid.p_text=wid._lbget_text();
   } else {
      call_event(defeventtab _ainh_dlg_manager,S_TAB,'E');
   }
}
//void _xmldoc_form.A_A-A_Z()
void _xmldoc_form.A_K,A_X,A_O,A_T,A_N,A_P,A_A,A_X,A_M,A_U,A_I()
{
   _str lastevent=last_event();
   _str eventname=event2name(lastevent);
   if (substr(eventname,1,2)=='A-' && isalpha(substr(eventname,3,1))) {
      _str letter="";
      parse event2name(last_event()) with 'A-' letter;
      int status=_dmDoLetter(letter);
      if (!status) return;
   }
}
void ctlok.lbutton_up()
{
   int status=jdMaybeSave(true);
   if (status) {
      return;
   }
   p_active_form._delete_window();
}

static _str jdSSTab[][]={
   {"0"},
   {"ctldescriptionlabel1","ctlseealsolabel1","ctlexamplelabel1"},
   {"ctldescriptionlabel2","ctlseealsolabel1","ctlexamplelabel1"},
   {"ctldescriptionlabel3","ctlseealsolabel3","ctlexamplelabel3"},
};
static int jdPercentageHashtab:[]={
   "ctldescription1"=> 100,

   "ctlsee1"=>100,

   "ctldescription2"=> 100,

   "ctldescription3"=> 50,
   "ctlparam3"=> 25,
   "ctlreturn3"=> 25,

   "ctlsee3"=>100,

   "ctlexample3"=>100
};
static void jdHideAll()
{
   int i,wid;
   for (i=1;i<=JAVATYPE_LAST;++i) {
      wid=_find_control('ctlpicture'i);
      wid.p_visible=false;
   }
   ctlpreview.p_enabled=false;
}
static int jdPictureFirstChild()
{
   int wid=_find_control('ctlpicture'CURJAVATYPE);
   if (wid.p_object==OI_SSTAB) {
      return(_find_control(jdSSTab[CURJAVATYPE][wid.p_ActiveTab]));
   }
   return(wid.p_child);
}
static void jdCheckForModifiedEditorCtl()
{
   int child,firstchild;
   firstchild=child=jdPictureFirstChild();
   for (;;) {
      if (child.p_object==OI_EDITOR) {
         if (child.p_modify) {
            MODIFIED=1;
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
static boolean jdModified()
{
   if (CURJAVATYPE=='') return(0);
   if (MODIFIED) {
      return(1);
   }
   jdCheckForModifiedEditorCtl();
   if (MODIFIED) {
      return(1);
   }
   return(false);
}
static void jdCopySeeLines(int form_wid,_str indent,_str ctlname)
{
   typeless handle=form_wid.XML_HANDLE;
   int wid=form_wid._find_control(ctlname:+form_wid.CURJAVATYPE);
   if (wid && wid.p_visible) {
      typeless array[];
      _xmlcfg_find_simple_array(handle,'/document/seealso',array);
      int i;
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
      if (!wid.p_Noflines) {
         return;
      }
      _str line;
      wid.get_line(line);
      if (wid.p_Noflines==1 && line=='') {
         return;
      }
      int dest_node_index=_xmlcfg_find_simple(handle,"/document/example");
      if (dest_node_index<0) {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/returns");
         if (dest_node_index<0) {
            _xmlcfg_find_simple_array(handle,"/document/param",array);
            if (array._length()) {
               dest_node_index=(int)array[array._length()-1];
            }
            if (dest_node_index<0) {
               dest_node_index=_xmldoc_find_description_node(handle);
            }
         }
      }
      int next_index=_xmlcfg_get_next_sibling(handle,dest_node_index,-1);
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
         if (line!='') {
            dest_node_index=_xmlcfg_add(handle,dest_node_index,'seealso',VSXMLCFG_NODE_ELEMENT_START,0);
            _xmlcfg_set_attribute(handle,dest_node_index,'cref',line,0);
            dest_node_index=_xmldoc_add_linebreak(handle,dest_node_index);
         }
      }
   }
}
static void jdCopyEditorCtlData(int form_wid,_str indent,_str ctlname,boolean &hit_error,_str &error_info)
{
   typeless handle=form_wid.XML_HANDLE;
   int wid=form_wid._find_control(ctlname:+form_wid.CURJAVATYPE);
   if (wid && wid.p_visible) {
      _str line;
      wid.get_line(line);
      if ((!wid.p_Noflines || (wid.p_Noflines==1 && line=="")) && ctlname!='ctldescription' && ctlname!='ctlreturn') {
         int index= -1;
         switch (ctlname) {
         case 'ctlexample':
            index=_xmlcfg_find_simple(handle,'/document/example');
            break;
         }
         if (index>=0) {
            _xmldoc_remove_eol(handle,index);
            _xmlcfg_delete(handle,index);
         }
         return;
      }
      typeless p;
      wid.save_pos(p);
      wid.top();
      int status=1;
      boolean isdescription=(ctlname=='ctldescription');
      //if (isdescription) {
      //   status=wid.search('^[ \t]*\@','@r');
      //}

      boolean doBeautify=false;
      _str prefix='';

      if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (ctlname!='ctlsee')
         ) {
         wid.top();
         status=wid.search( '<code>' ,'rh@');
         if (status) {
            doBeautify=true;
            prefix=indent;   //substr('',1,length(atTagSpace));
         }
      }
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      wid.top();wid.up();
      boolean first_loop=true;
      for (;;) {
         if (wid.down()) break;
         if (wid._lineflags() & HIDDEN_LF) {
            continue;
         }
         wid.get_line(line);
         if (ctlname!='ctlsee' || line!='') {
            if (doBeautify && !first_loop && line!='') {
               insert_line(prefix:+line);
            } else {
               insert_line(line);
            }
         }
         first_loop=false;
      }

      //temp_handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      wid.restore_pos(p);
      top();_insert_text('<document>');
      bottom();_insert_text('</document>');
      typeless temp_handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      if (temp_handle<0) {
         hit_error=true;
         error_info=ctlname;
         return;
      }
      _str tag="";
      int dest_node_index=0;
      if (ctlname=='ctldescription') {
         dest_node_index=_xmldoc_find_description_node(handle);
         tag='summary';
      } else if (ctlname=='ctlreturn') {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/returns");
         tag='returns';
      } else if (ctlname=='ctlexample') {
         dest_node_index=_xmlcfg_find_simple(handle,"/document/example");
         tag='example';
      }
      //say(ctlname);_showxml(handle);
      if (dest_node_index>=0) {
         _xmlcfg_delete(handle,dest_node_index,true);
         int next_index=_xmlcfg_get_next_sibling(handle,dest_node_index,~VSXMLCFG_NODE_ATTRIBUTE);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            line=_xmlcfg_get_value(handle,next_index);
            line=stranslate(line,"","\r");
            _str first="", second="", rest="";
            parse line with first "\n" second "\n";
            if (first=="" && second=="" && pos("\n?*\n",line,1,"r")) {
               parse line with first "\n" rest;
               _xmlcfg_set_value(handle,next_index,rest);
            }
         }
      } else {
         dest_node_index=_xmlcfg_find_simple(handle,'/document');
         int next_index=_xmlcfg_get_first_child(handle,dest_node_index,-1);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            dest_node_index=_xmlcfg_add(handle,next_index,tag,VSXMLCFG_NODE_ELEMENT_START,0);
            //dest_node_index=_xmlcfg_add(handle,dest_node_index,'',VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
         } else {
            if (ctlname=='ctldescription') {
               dest_node_index=_xmlcfg_add(handle,next_index,tag,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_BEFORE);
            } else {
               // Add <returns> after last parameter if one exists
               int temp_index=0;
               int after_index=dest_node_index;
               int flags=VSXMLCFG_ADD_AS_CHILD;
               if (ctlname=='ctlexample') {
                  after_index=-1;
                  temp_index=_xmlcfg_find_simple(handle,'/document/returns');
                  if (temp_index>=0) {
                     flags=0;after_index=temp_index;
                  }
               }
               if (ctlname=='ctlreturn' || (ctlname=='ctlexample' && after_index<0) ) {
                  _str array[];
                  _xmlcfg_find_simple_array(handle,'/document/param',array);
                  if (array._length()) {
                     flags=0;
                     after_index=(int)array[array._length()-1];
                  } else {
                     temp_index=_xmldoc_find_description_node(handle);
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
      _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,'/document'),VSXMLCFG_COPY_CHILDREN);
      //_showxml(handle);
      //say('h3 'ctlname);_showxml(handle);

      _xmlcfg_close(temp_handle);
   } else {
      int index= -1;
      switch (ctlname) {
      case 'ctlreturn':
         index=_xmlcfg_find_simple(handle,'/document/returns');
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
static int jdInsertCommentLines(int form_wid,int start_col,int first_line,int last_line,int start_line_no)
{
   typeless handle=form_wid.XML_HANDLE;
   // save parameter changes
   int wid=form_wid._find_control('ctlparamcombo'form_wid.CURJAVATYPE);
   if (wid) {
      wid.jdShowParam();
   }

   _str slcomment_start='///';
   _str mlcomment_start='///';
   _str mlcomment_end='///';

   typeless i=0;
   int count=0;
   int dest_node_index=0;
   int next_index=0;
   int newline_index=0;
   typeless array[];
   _str tag="";
   _str line="";
   _str argName="";
   typeless list="";
   typeless temp_handle=0;
   typeless status=0;
   boolean hit_error=false;
   _str error_info='';

   _str indent=substr('',1,p_SyntaxIndent);   //substr('',1,length(atTagSpace));
   jdCopyEditorCtlData(form_wid,indent,'ctldescription',hit_error,error_info);
   wid=form_wid._find_control('ctlparamcombo':+form_wid.CURJAVATYPE);
   if (wid) {
      _xmlcfg_find_simple_array(handle,'/document/param',array);
      for (i=0;i<array._length();++i) {
         _xmldoc_remove_blank_line(handle,array[i]);
         _xmldoc_remove_eol(handle,array[i]);
         _xmlcfg_delete(handle,array[i]);
      }
      _str hashtab:[][]=form_wid.HASHTAB;
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      count=(int)hashtab:['@paramcount'][0];
      tag='param';
      int param_node_index=-1;
      for (i=0;i<count;++i) {
         list=hashtab:[tag][i];
         //parse list with line "\n" list;
         //parse line with argName rest;
         parse list with argName list;
         list=stranslate(list,'',"\r");
         if (last_char(list)=="\n" && length(list)>2 && substr(list,length(list)-1,1)!="\n") {
            list=substr(list,1,length(list)-1);
         }
         if (tag!='param' || !def_xmldoc_keep_obsolete ||
             i<hashtab:['@paramcount'][0] ||
             /*rest!='' || */list!='') {
            boolean doBeautify=false;
            if (!pos('<code>',/*rest:+*/list,1)) {
               doBeautify=true;
            } else {
               doBeautify=false;
            }
            boolean first_loop=true;
            for (;;) {
               if (list:=='') {
                  break;
               }
               //parse list with line "\n" list;
               int x=pos("\n",list,1);
               if (x) {
                  line=substr(list,1,x);
                  list=substr(list,x+1);
               } else {
                  line=list;
                  list='';
               }
               if (doBeautify && !first_loop && strip(line)!="\n") {
                  _insert_text(indent:+line);
               } else {
                  _insert_text(line);
               }
               first_loop=false;
            }
         }
         top();_insert_text('<document>');bottom();_insert_text('</document>');
         temp_handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
         if (temp_handle<0) {
            hit_error=true;
            error_info='ctlparam 'i;
            break;
         }

         if (param_node_index<0) {
            boolean do_insert_child=true;
            dest_node_index=_xmldoc_find_description_node(handle);
            next_index=_xmlcfg_get_next_sibling(handle,dest_node_index,-1);
            if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
               dest_node_index=next_index;
            }
            dest_node_index=_xmlcfg_add(handle,dest_node_index,'param',VSXMLCFG_NODE_ELEMENT_START,0);
            _xmlcfg_set_attribute(handle,dest_node_index,'name',argName);
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            //dest_node_index=_xmlcfg_add(handle,dest_node_index,'',VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
            //_showxml(handle);
            _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,'/document'),VSXMLCFG_COPY_CHILDREN);
            //_showxml(handle);
            param_node_index=newline_index;
         } else {
            dest_node_index=_xmlcfg_add(handle,param_node_index,'param',VSXMLCFG_NODE_ELEMENT_START,0);
            _xmlcfg_set_attribute(handle,dest_node_index,'name',argName);
            newline_index=_xmldoc_add_linebreak(handle,dest_node_index);
            //_showxml(handle);
            _xmlcfg_copy(handle,dest_node_index,temp_handle,_xmlcfg_find_simple(temp_handle,'/document'),VSXMLCFG_COPY_CHILDREN);
            //_showxml(handle);
            param_node_index=newline_index;
         }
         _xmlcfg_close(temp_handle);
         delete_all();
      }
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   }
   //jdCopyComboCtlData(form_wid,prefix,'ctlparamcombo',VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS,'param');

   _str ctlname='';
   jdCopyEditorCtlData(form_wid,indent,'ctlreturn',hit_error,error_info);
   jdCopyEditorCtlData(form_wid,indent,'ctlexample',hit_error,error_info);
   jdCopySeeLines(form_wid,indent,'ctlsee');
   if (hit_error) {
      _message_box('XML not valid.  Please correct and save again.');
      parse error_info with ctlname i;
      int tab_wid=form_wid._find_control('ctlpicture':+form_wid.CURJAVATYPE);
      int focus_wid=form_wid._find_control(ctlname:+form_wid.CURJAVATYPE);
      if (ctlname=='ctlparam') {
         //wid=form_wid._find_control('ctlparamcombo':+form_wid.CURJAVATYPE);
         tab_wid.p_ActiveTab=0;
         int combo_wid=form_wid._find_control('ctlparamcombo':+form_wid.CURJAVATYPE);
         combo_wid.p_line=i+1;
         combo_wid.p_text=combo_wid._lbget_text();
      } else if (ctlname=='ctldescription') {
         tab_wid.p_ActiveTab=0;
      } else if (ctlname=='ctlreturn') {
         tab_wid.p_ActiveTab=0;
      } else if (ctlname=='ctlexample') {
         tab_wid.p_ActiveTab=2;
      }
      focus_wid._set_focus();
      return(1);
   }
   if (first_line>=0) {
      // delete the original comment lines
      int num_lines = last_line-first_line+1;
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
   int index=0;
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

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(0,handle,0,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   int len=length('<document>');
   top();_delete_text(len);bottom();p_col-=len+1;_delete_text(len+1);
   if (_line_length()==0) {
      _delete_line();
   }
   top();
   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';
   search('^'substr('',1,p_SyntaxIndent),'rh@',prefix);
   int temp_buf_id=p_buf_id;
   activate_window(orig_view_id);
   _buf_transfer(temp_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   return(0);
}

static int jdMaybeSave(boolean forceSave=false)
{

   boolean doSave=jdModified() || forceSave;
   if (doSave && !ALLOW_SAVE) {
      _message_box("Can't save.  Correct original XML documentation first.");
      return(1);
   }
   if (doSave) {

      static int recursion;

      if (recursion) return(1);
      ++recursion;
      //say('a0 CURT='CURTREEINDEX' cap='ctltree1._TreeGetCaption(CURTREEINDEX));

      int form_wid=p_active_form;
      int editorctl_wid=_form_parent();
      int orig_wid=p_window_id;

      int orig_view_id;
      get_window_id(orig_view_id);
      p_window_id=editorctl_wid;

      _UpdateContext(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      VS_TAG_BROWSE_INFO cm;
      _str proc_name,path;
      int start_line_no=-1;
      int javatype;
      orig_wid.ctltree1._ProcTreeTagInfo2(editorctl_wid,cm,proc_name,path,start_line_no,orig_wid.CURTREEINDEX);


      typeless p;
      _save_pos2(p);

      p_RLine=start_line_no;

      _GoToROffset(cm.seekpos);
      int start_col = p_col;


      int first_line, last_line;
      if (_do_default_get_tag_header_comments(first_line, last_line)) {
         first_line = start_line_no;
         last_line  = first_line-1;
      }
      int status=jdInsertCommentLines(form_wid,start_col,first_line,last_line,start_line_no);

      _restore_pos2(p);
      activate_window(orig_view_id);

      if (!status) {
         _str buf_name=editorctl_wid.p_buf_name;
         if (buf_name!='') {
            _str caption="";
            parse p_active_form.p_caption with caption ':';
            p_active_form.p_caption=caption': 'buf_name;
         }

         _xmldoc_refresh_proctree(false);
         CURTREEINDEX=ctltree1._TreeCurIndex();
      }
      //say('a1 CURT='CURTREEINDEX' cap='ctltree1._TreeGetCaption(CURTREEINDEX));
      --recursion;
      return(status);
   }
   return(0);
}
void _xmldoc_refresh_proctree(boolean curItemMayChange=true)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);
   sentry.lockMatches(true);

   int form_wid=p_active_form;
   int editorctl_wid=_form_parent();
   editorctl_wid._UpdateContext(true);
   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,'','T');
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_xmldoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);
   if (curItemMayChange) {
      int nearIndex= ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (nearIndex<0) {
         jdHideAll();
         ctltagcaption.p_caption="No symbol selected, check filtering options.";
         //p_active_form._delete_window();
         return;
      }
      ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
   }

}
static void jdClearControls(int activeTab=0)
{
   int firstchild,child;
   int wid=_find_control('ctlpicture'CURJAVATYPE);
   if (wid.p_object==OI_SSTAB) {
      firstchild=child=_find_control(jdSSTab[CURJAVATYPE][activeTab]);
   } else {
      firstchild=child=jdPictureFirstChild();
   }
   for (;;) {
      int undo_steps=0;
      switch (child.p_object) {
      case OI_EDITOR:
         undo_steps=child.p_undo_steps;child.p_undo_steps=0;
         child._lbclear();
         child.p_user="";
         child.p_undo_steps=undo_steps;
         child.insert_line("");
         child.p_modify=0;
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
         int firstchild2,child2;
         firstchild2=child2=child.p_child;
         for (;;) {
            switch (child2.p_object) {
            case OI_EDITOR:
               undo_steps=child2.p_undo_steps;child2.p_undo_steps=0;
               child2._lbclear();
               child2.p_user="";
               child2.p_undo_steps=undo_steps;
               child2.insert_line("");
               child2.p_modify=0;
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
static void jdShowType(int javatype)
{
   ctlparamcombo3.p_user="";
   //ctlexceptioncombo3.p_user="";
   if (CURJAVATYPE!=javatype) {
      jdHideAll();
      CURJAVATYPE=javatype;
   }
   int wid=_find_control('ctlpicture'CURJAVATYPE);
   if (wid.p_object==OI_SSTAB) {
      jdClearControls(0);
      jdClearControls(1);
   } else {
      jdClearControls(0);
   }
   ctlpreview.p_enabled=true;
}
static void jdResizeChildren(int activeTab=0)
{
   int paddingX=_dx2lx(SM_TWIP,_lx2dx(SM_TWIP,100));
   int paddingY=ctltree1.p_y;
   int y=0;
   int wid=_find_control('ctlpicture'CURJAVATYPE);
   // Determine the minimum hieght required
   int NofSizeableControls=0;
   int UseMorePercent=0;
   int nextPaddingY=0;
   int firstchild,child;
   if (wid.p_object==OI_SSTAB) {
      firstchild=child=_find_control(jdSSTab[CURJAVATYPE][activeTab]);
   } else {
      firstchild=child=jdPictureFirstChild();
   }
   for (y=paddingY;;) {
      y+=nextPaddingY;
      if (child.p_visible==0) {
         y-=nextPaddingY;
         if (jdPercentageHashtab._indexin(child.p_name)) {
            UseMorePercent+=jdPercentageHashtab:[child.p_name];
         }
      } else {
         switch (child.p_object) {
         case OI_CHECK_BOX:
            if (!child.p_value) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
               break;
            }
         case OI_LABEL:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_LABEL));
            break;
         case OI_EDITOR:
            if (jdPercentageHashtab._indexin(child.p_name)) {
               NofSizeableControls+=1;
               y+=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDMIN_EDITORCTL_HEIGHT));
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
               break;
            }
         default:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
   if (wid.p_object==OI_SSTAB) {
      y+=paddingY;
   }
   int extra_height=ctlok.p_y-y;
   int pic_width= _dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlimage1.p_x-ctlimage1.p_width;
   if (!activeTab) {
      wid.p_x=ctlimage1.p_x+ctlimage1.p_width;
      wid.p_y=0;
      wid.p_width=pic_width;
      wid.p_height=ctltree1.p_height+ctltree1.p_y-wid.p_y;
   }
   if (wid.p_object==OI_SSTAB) {
      firstchild=child=_find_control(jdSSTab[CURJAVATYPE][activeTab]);

      pic_width-=(wid.p_width-wid.p_child.p_width);
      extra_height-=(wid.p_height-wid.p_child.p_height);
   } else {
      firstchild=child=jdPictureFirstChild();
   }
   if (extra_height<0) extra_height=0;
   int extra_height_remaining=extra_height;
   //say('*******************************************************');
   //say('extra_height='extra_height);
   nextPaddingY=0;
   int last_sizeable_wid=0;
   for (y=paddingY;;) {
      y+=nextPaddingY;
      if (child.p_visible==0) {
         y-=nextPaddingY;
      } else {
         int height;
         if (jdPercentageHashtab._indexin(child.p_name)) {
            int percent=0;
            if (UseMorePercent && NofSizeableControls) {
               percent=UseMorePercent/NofSizeableControls;
            }
            int extra=((percent+jdPercentageHashtab:[child.p_name])*extra_height) intdiv 100;
            height=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDMIN_EDITORCTL_HEIGHT))+extra;
            extra_height_remaining-=extra;
            last_sizeable_wid=wid;
         } else {
            height=child.p_height;
         }
         child._move_window(paddingX,y,pic_width-paddingX*2,height);
         //say('y='y' t='ctltree1.p_y);
         if (child.p_object==OI_PICTURE_BOX){
            _str sizename=substr(child.p_name,1,10);
            if (sizename=='ctlsizepic') {
               // version and serial
               int child2=child.p_child.p_next;
               int text_box_width=((child.p_width-JDX_BETWEEN_TEXT_BOX) intdiv 2);

               // move version text box
               child2._move_window(child2.p_x,child2.p_y,text_box_width,child2.p_height);
               child2=child2.p_next;
               // move serial label
               child2._move_window(text_box_width+JDX_BETWEEN_TEXT_BOX,child2.p_y,child2.p_width,child2.p_height);
               child2=child2.p_next;
               // move serial text box
               child2._move_window(text_box_width+JDX_BETWEEN_TEXT_BOX,child2.p_y,text_box_width,child2.p_height);
            } else if (sizename=='ctlsizeexc' || sizename=='ctlsizepar') {
               int label_wid=child.p_child;
               int combo_wid=label_wid.p_next;
               combo_wid.p_x=label_wid.p_x+label_wid.p_width+100;
               int width=child.p_width-combo_wid.p_x-label_wid.p_x;
               if (width<0) width=1000;
               combo_wid.p_width=width;
            }
         }
         switch (child.p_object) {
         case OI_CHECK_BOX:
            if (!child.p_value) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
               break;
            }
         case OI_LABEL:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_LABEL));
            break;
         case OI_EDITOR:
            if (jdPercentageHashtab._indexin(child.p_name)) {
               y+=child.p_height;
               nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
               break;
            }
         default:
            y+=child.p_height;
            nextPaddingY=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP,JDY_AFTER_OTHER));
         }
      }
      child=child.p_next;
      if (child==firstchild) break;
   }
}
static void jdResizeControls()
{
   ctltagcaption.p_visible=ctlok.p_visible=ctlcancel.p_visible=false;

   ctlok.p_y= _dy2ly(SM_TWIP,p_client_height)-ctlok.p_height-100;
   ctlcancel.p_y=ctlpreview.p_y=ctloptions.p_y=ctlok.p_y;
   ctltagcaption.p_y=ctlok.p_y+(ctlok.p_height-ctltagcaption.p_height) intdiv 2;

   ctltree1.p_height=ctlok.p_y-ctltree1.p_y-100;
   ctltree1.p_width=ctlimage1.p_x-ctltree1.p_x;

   //ctlimage1.p_x=ctltree1.p_x+ctltree1.p_width;
   ctlimage1.p_y=0;
   ctlimage1.p_height=ctltree1.p_height+ctltree1.p_y;

   ctlok.p_visible=ctlcancel.p_visible=true;
   ctltagcaption.p_visible=true;

   int wid=_find_control('ctlpicture'CURJAVATYPE);
   if (wid) {
      wid.p_visible=false;

      if (wid.p_object==OI_SSTAB) {
         jdResizeChildren(0);
         jdResizeChildren(1);
         jdResizeChildren(2);
      } else {
         jdResizeChildren();
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

   _str caption = _TreeGetCaption(tree_index);
   tag_tree_decompose_caption(caption,proc_name);

   // get the remainder of the information
   int status = (int)_GetContextTagInfo(cm, '', proc_name, path, LineNumber);
   cm.language=editorctl_wid.p_LangId;
   cm.file_name=editorctl_wid.p_buf_name;
   return (status);
}

static void jdParseEditText(_str &string,_str &text,boolean doBeautify=false)
{
   text=string;
   if (doBeautify &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)) {
      if (!pos('<code>',text,1) ) {
         _str result='';
         for (;;) {
            if (text:=='') {
               break;
            }
            _str line="";
            int i=pos("\n",text,1);
            if (i) {
               line=substr(text,1,i);
               text=substr(text,i+1);
            } else {
               line=text;
               text='';
            }
            //parse text with line "\n" +0 text;
            result=result:+strip(line);
         }
         text=result;

      }
   }
}
static void xmldocParseParam(_str &string,_str &argName,_str &text,boolean doBeautify=false,_str tag='')
{
   parse string with argName text;
   parse argName with argName '[ \n]','r';
   if (doBeautify &&
       (def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)) {
      int flag2;
      if (tag=='param') {
         flag2=VSJAVADOCFLAG_ALIGN_PARAMETERS;
      } else {
         flag2=VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
      }
      if ( (def_xmldoc_format_flags & flag2) && !pos('<code>',text,1) ) {
         _str result='';
         for (;;) {
            if (text:=='') {
               break;
            }
            _str line="";
            int i=pos("\n",text,1);
            if (i) {
               line=substr(text,1,i);
               text=substr(text,i+1);
            } else {
               line=text;
               text='';
            }
            //parse text with line "\n" text;
            result=result:+line;
         }
         text=result;

      }
   }
}
static int jdFindParam(_str tag,_str param_name,_str (&hashtab):[][],boolean case_sensitive)
{
   int count=hashtab:[tag]._length();
   int i;
   _str argName,text;
   for (i=0;i<count;++i) {
      xmldocParseParam(hashtab:[tag][i],argName,text);
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
static void jdShowParam(_str tag='param')
{
   if (p_text=="") return;
   int editorctl_wid=_form_parent();
   int widcombo=_find_control('ctl'tag'combo'CURJAVATYPE);
   int wid=_find_control('ctl'tag:+CURJAVATYPE);
   boolean modify=wid.p_modify;
   _str hashtab:[][];
   hashtab=HASHTAB;
   _str param_name,text;
   if (modify && isinteger(widcombo.p_user) && widcombo.p_user>=0) {
      int j=widcombo.p_user;
      xmldocParseParam(hashtab:[tag][j],param_name,text);
      text=wid.get_text(wid.p_buf_size,0);
      if (wid.p_newline=="\r\n") {
         text=stranslate(text,"","\r");
      } else if (wid.p_newline=="\r") {
         text=stranslate(text,"\n","\r");
      }
      if (text:==wid.p_newline || text=="\n") {
         text='';
      }
      //parse text with linetemp "\n";
      hashtab:[tag][j]=param_name' 'text;
      if (length(text)) {
         widcombo=_find_control('ctl'tag'combo'CURJAVATYPE);
         typeless p;
         widcombo.save_pos(p);
         widcombo._lbtop();
         typeless status=widcombo._lbfind_and_select_item(param_name' (empty)');
         if (!status) {
            widcombo._lbset_item(param_name);
         }
         widcombo.restore_pos(p);
      }
      HASHTAB=hashtab;
   }
   parse p_text with param_name' (';
   int undo_steps=wid.p_undo_steps;wid.p_undo_steps=0;
   wid._lbclear();
   wid.p_undo_steps=undo_steps;
   int j=jdFindParam(tag,param_name,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
   if (j>=0) {
      xmldocParseParam(hashtab:[tag][j],param_name,text,true,tag);
      wid._insert_text(text);
      wid.p_modify=modify;wid.top();
   }
   widcombo.p_user=j;
}
void ctlcancel.lbutton_up()
{
   if (jdModified()) {
      int result=prompt_for_save("Save changes?");
      if (result==IDCANCEL) {
         return;
      }
      if (result==IDYES) {
         int status=jdMaybeSave();
         if (status) {
            return;
         }
      }
   }
   p_active_form._delete_window();
}
void ctlauthor1.on_change()
{
   MODIFIED=1;
}
void ctlparamcombo3.on_change(int reason)
{
   jdShowParam();
}
static void jdShowModified()
{
   if (MODIFIED) {
      if (TIMER_ID!='') {
         _kill_timer(TIMER_ID);
         TIMER_ID='';
      }
      p_active_form.p_caption=p_active_form.p_caption:+' *';
   }
}
static void TimerCallback(int form_wid)
{
   if (form_wid.jdModified()) {
      form_wid.MODIFIED=1;
      form_wid.jdShowModified();
   }
}
void ctlpreview.lbutton_up()
{
   int form_wid=p_active_form;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=form_wid._form_parent().p_UTF8;
   _SetEditorLanguage(form_wid._form_parent().p_LangId);
   int status=jdInsertCommentLines(form_wid,1,-1,0,0);
   if (status) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }
   bottom();
   insert_line('int foo;');
   int comment_flags=0;
   _str orig_comment='';
   int first_line, last_line;
   _str line_prefix='';
   int blanks:[][];
   _str doxygen_comment_start='';
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      _parse_multiline_comments(1,first_line,last_line,comment_flags,'',orig_comment,2000,line_prefix,blanks,doxygen_comment_start);
   }
   _make_html_comments(orig_comment,comment_flags,'');

   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   show('-xy -modal _javadoc_preview_form',orig_comment,true);

   activate_window(orig_view_id);
   return;
}
static boolean in_change;
void ctltree1.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
      if (in_change) {
         return;
      }
      in_change=true;
      //say('CURTREEINDEX='CURTREEINDEX' cur='_TreeCurIndex());
      if(jdMaybeSave() && CURTREEINDEX!='') {
         _TreeSetCurIndex(CURTREEINDEX);
         in_change=false;
         return;
      }
      in_change=false;
      if (TIMER_ID=='') {
         TIMER_ID=_set_timer(40,TimerCallback,p_active_form);
      }

      if (index==TREE_ROOT_INDEX) return;
      CURTREEINDEX=index;
      //say('a3 CURTREEINDEX='CURTREEINDEX);
      _str caption=_TreeGetCaption(CURTREEINDEX);
      _str before="", after="";
      parse caption with before "\t" after;
      if (after!="") {
         ctltagcaption.p_caption=stranslate(after,"&&","&");
      } else {
         ctltagcaption.p_caption=stranslate(caption,"&&","&");
      }
      // Line number and type(class,proc|func, other)
      VS_TAG_BROWSE_INFO cm;
      int editorctl_wid=_form_parent();
      _str buf_name=editorctl_wid.p_buf_name;
      if (buf_name!='') {
         parse p_active_form.p_caption with caption ':';
         p_active_form.p_caption=caption': 'buf_name;
      }
      int orig_wid=p_window_id;

      int orig_view_id;
      get_window_id(orig_view_id);
      p_window_id=editorctl_wid;

      _UpdateContext(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      typeless orig_values;
      int embedded_status=_EmbeddedStart(orig_values);

      _str proc_name,path;
      int start_line_no;
      int javatype;
      orig_wid._ProcTreeTagInfo2(editorctl_wid,cm,proc_name,path,start_line_no);
      if (tag_tree_type_is_func(cm.type_name)) {
         javatype=JAVATYPE_METHOD;
      } else if (tag_tree_type_is_class(cm.type_name)) {
         javatype=JAVATYPE_CLASS;
         //} else if (tag_tree_type_is_package(cm.type_name)) {
      } else {
         javatype=JAVATYPE_DATA;
      }
      orig_wid.jdShowType(javatype);
      int init_modified=0;

      save_pos(auto p);
      p_RLine=start_line_no;
      _GoToROffset(cm.seekpos);
      //p_col=1;_clex_skip_blanks();

      // try to locate the current context, maybe skip over
      // comments to start of next tag
      int context_id = tag_current_context();
      if (context_id <= 0) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         restore_pos(p);
         _message_box('no current tag');
         return;
      }

      // get the information about the current function
      _str tag_name="";
      _str type_name="";
      _str file_name="";
      _str class_name="";
      _str signature="";
      _str return_type="";
      int tag_flags=0;
      int start_seekpos=0;
      int scope_line_no=0;
      int scope_seekpos=0;
      int end_line_no=0;
      int end_seekpos=0;
      tag_get_context(context_id, tag_name, type_name, file_name,
                      start_line_no, start_seekpos, scope_line_no,
                      scope_seekpos, end_line_no, end_seekpos,
                      class_name, tag_flags, signature, return_type);
      //say('n='tag_name);
      //say('sig='signature' len='length(signature));

      _GoToROffset(start_seekpos);
      if (tag_tree_type_is_func(cm.type_name)) {
         _UpdateLocals(true);
      }
      _str newline=p_newline;
      int comment_flags=0;
      // hash table of original comments for incremental updates
      _str orig_comment='';
      int first_line, last_line;
      if (!_do_default_get_tag_header_comments(first_line, last_line)) {
         p_RLine=start_line_no;
         _GoToROffset(start_seekpos);
         // We temporarily change the buffer name just in case the Javadoc Editor
         // is the one getting the comments.
         _str old_buf_name=p_buf_name;
         p_buf_name="";
         _str line_prefix='';
         int blanks:[][];
         _str doxygen_comment_start='';
         _do_default_get_tag_comments(comment_flags,type_name, orig_comment, 1000, false, line_prefix, blanks, 
            doxygen_comment_start);
         p_buf_name=old_buf_name;
      } else {
         init_modified=1;
         first_line = start_line_no;
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
         orig_comment=stranslate(orig_comment,'&lt;','<');  // Translate < to &lt;
         orig_comment=stranslate(orig_comment,'&gt;','>');  // Translate < to &gt;
         orig_comment=stranslate(orig_comment,'',"\r");
         if (last_char(orig_comment)=="\n" && length(orig_comment)>2 && substr(orig_comment,length(orig_comment)-1,1)!="\n") {
            orig_comment=substr(orig_comment,1,length(orig_comment)-1);
         }
         orig_comment='<summary>':+orig_comment:+'</summary>':+"\n";
         init_modified=1;
      }
      _str description="";
      _parseXMLDocComment(orig_comment, description,hashtab,tagList);

      typeless i;
      hashtab._nextel(i);
      /*
        ORDER


         deprecated,param,return,throws,since

         others

         Author

         see
      */
      _str tag="";
      int wid=_find_control('ctldescription'CURJAVATYPE);
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
            wid.p_modify=0;wid.top();
            wid.p_undo_steps=32000;
         }
      }
      wid=_find_control('ctlreturn'CURJAVATYPE);
      if (wid) {
         tag="return";
         // If there is a return value
         if (cm.return_type!=""  && cm.return_type!='void' && cm.return_type!='void VSAPI') {
            if (hashtab._indexin(tag)) {
               wid.p_undo_steps=0;
               wid._delete_line();
               wid._insert_text(hashtab:[tag][0]);
#if 0
               if ((def_xmldoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)
                    && (def_xmldoc_format_flags & VSJAVADOCFLAG_ALIGN_RETURN)
                   ) {
                  wid.top();
                  int status=wid.search( '<code>' ,'rh@');
                  if (status) {
                     wid.up();
                     for(;;) {
                        if (wid.down()) break;
                        _str line="";
                        wid.get_line(line);
                        wid.replace_line(strip(line));
                     }
                  }
               }
#endif
               wid.p_modify=0;wid.top();
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

      _str text="";
      _str argName="";
      wid=_find_control('ctlparamcombo'CURJAVATYPE);
      if (wid) {
         tag="param";
         // If there are parameters
         boolean hitList[];
         _str new_list[];
         int count=0;
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
         }
         for (i=0;i<count;++i) hitList[i]=false;
         _str empty_msg=' (empty)';

         for (i=1; i<=tag_get_num_of_locals(); i++) {
            // only process params that belong to this function, not outer functions
            int local_seekpos=0;
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
            _str param_type="";
            tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
            if (param_type=='param' && local_seekpos>=start_seekpos) {
               _str param_name="";
               tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
               int j=jdFindParam('param',param_name,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
               if (j>=0) {
                  xmldocParseParam(hashtab:[tag][j],argName,text);
                  if (new_list._length()!=j) {
                     init_modified=1;
                  }
                  new_list[new_list._length()]=hashtab:[tag][j];
                  hitList[j]=true;
                  if (text=='') {
                     wid._lbadd_item(param_name:+empty_msg);
                  } else {
                     wid._lbadd_item(param_name);
                  }
               } else {
                  init_modified=1;
                  wid._lbadd_item(param_name:+empty_msg);
                  new_list[new_list._length()]=param_name;
               }
            }
         }
         hashtab:['@paramcount'][0]=new_list._length();
         for (i=0;i<count;++i) {
            if (!hitList[i]) {
               xmldocParseParam(hashtab:[tag][i],argName,text);
               new_list[new_list._length()]=hashtab:[tag][i];
               wid._lbadd_item(argName' (obsolete)');
               if (!def_xmldoc_keep_obsolete) {
                  init_modified=1;
               } else if(text=="") {
                  init_modified=1;
               }
            }
         }
         hashtab:[tag]=new_list;

         int widparam=_find_control('ctlparam'CURJAVATYPE);
         if (wid.p_Noflines) {
            HASHTAB=hashtab;
            wid._lbtop();
            wid.p_text=wid._lbget_text();
            //wid.jdShowParam();
            widparam.p_visible=true;
            widparam.p_prev.p_visible=true;
         } else {
            widparam.p_visible=false;
            widparam.p_prev.p_visible=false;
         }
      }

      _str line="";
      wid=_find_control('ctlsee'CURJAVATYPE);
      if (wid) {
         tag="see";
         _str see_msg="";
         if (hashtab._indexin(tag)) {
            int count=hashtab:[tag]._length();
            if (count) {
               wid._lbclear();
            }
            for (i=0;i<count;++i) {
               parse hashtab:[tag][i] with line "\n" ;
               wid.insert_line(line);
            }
            wid.p_modify=0;wid.top();
            hashtab._deleteel(tag);
         }
      }
      wid=_find_control('ctlexample'CURJAVATYPE);
      if (wid) {
         tag="example";
         wid.delete_all();
         wid.insert_line('');
         wid.p_modify=0;
         // If there is example code
         if (hashtab._indexin(tag)) {
            jdParseEditText(hashtab:[tag][0],text,true);
            wid.p_undo_steps=0;
            wid._insert_text(text);
#if 0
            wid.top();
            int status=wid.search( '<code>' ,'rh@');
            if (status) {
               wid.up();
               for(;;) {
                  if (wid.down()) break;
                  wid.get_line(line);
                  wid.replace_line(strip(line));
               }
            }
#endif
            wid.p_modify=0;wid.top();
            wid.p_undo_steps=32000;
            hashtab._deleteel(tag);
         }
         wid.p_visible=true;
         wid.p_prev.p_visible=true;
      }
      HASHTAB=hashtab;

      //MODIFIED=init_modified;
      MODIFIED=0;
      jdShowModified();

      p_active_form.jdResizeControls();
      int pic_wid=_find_control('ctlpicture'CURJAVATYPE);
      pic_wid.p_visible=true;

   }
}
void ctlimage1.lbutton_down()
{
   _ul2_image_sizebar_handler(ctlok.p_width, ctlpicture3.p_x+ctlpicture3.p_width-ctloptions.p_x);
}
void ctltree1.rbutton_up()
{
   // Get handle to menu:
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   int flags=def_xmldoc_filter_flags;
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void _xmldoc_form.on_resize(boolean doMove=false)
{
   if (doMove) return;
   jdResizeControls();
}

static int _setEditorControlMode(int wid)
{
   if (wid.p_object!=OI_EDITOR) {
      return(0);
   }
   wid.p_buf_name=".xmldoc";
   wid._SetEditorLanguage('xmldoc');
// wid.apply_dtd_changes();
   int editorctl_wid=wid._form_parent();
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
   XML_HANDLE='';
   CURTREEINDEX='';
   int editorctl_wid=_form_parent();
   _setEditorControlMode(ctldescription1.p_window_id);
   _setEditorControlMode(ctldescription2.p_window_id);
   _setEditorControlMode(ctldescription3.p_window_id);
   _setEditorControlMode(ctlexample1.p_window_id);
   _setEditorControlMode(ctlexample2.p_window_id);
   _setEditorControlMode(ctlexample3.p_window_id);
   _setEditorControlMode(ctlparam3.p_window_id);
   _setEditorControlMode(ctlreturn3.p_window_id);

   ctlsee1._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee2._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee3._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee1.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee2.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee3.p_window_flags |=VSWFLAG_NOLCREADWRITE;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);
   sentry.lockMatches(true);

   _str buf_name=editorctl_wid.p_buf_name;
   if (buf_name!='') {
      p_active_form.p_caption=p_active_form.p_caption': 'buf_name;
   }
   editorctl_wid._UpdateContext(true);
   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,'','T');
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_xmldoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);

   typeless p;
   editorctl_wid.save_pos(p);
   editorctl_wid.p_col=1;
   editorctl_wid._clex_skip_blanks();
   int EditorLN=editorctl_wid.p_RLine;
   int context_id = tag_nearest_context(EditorLN,def_xmldoc_filter_flags);
   int nearIndex= -1;
   int line_num=0;
   editorctl_wid.restore_pos(p);
   if (context_id>0) {
      tag_get_detail2(VS_TAGDETAIL_context_line, context_id, line_num);
      nearIndex=ctltree1._TreeSearch(TREE_ROOT_INDEX,'','T',line_num);
   }
   if (nearIndex <= 0) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_xmldoc_filter_flags= -1;
      _xmldoc_refresh_proctree();
      if (ctltree1._TreeCurIndex()<=0 || CURJAVATYPE=="") {
         nearIndex= ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (nearIndex<0) {
            //p_active_form._delete_window();
            jdHideAll();
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
   int wid=_find_control('ctldescription'CURJAVATYPE);
   if (wid) {
      wid._set_focus();
   }
}
void ctlok.on_destroy()
{
   if (XML_HANDLE) {
      _xmlcfg_close(XML_HANDLE);XML_HANDLE='';
   }
   if (TIMER_ID!='') {
      _kill_timer(TIMER_ID);
   }
}

boolean _bas_is_xmldoc_supported()
{
   return true;
}

boolean def_c_xmldoc=false;
boolean _c_is_xmldoc_supported()
{
   return def_c_xmldoc;
}
boolean _c_is_xmldoc_preferred()
{
   // (clark) Don't want javadoc_editor command to generate C# style XMLDoc comments in C++ files.
   // For now, don't support xmldoc comment wrapping for C++ and C. At least we support
   // XmlDoc color coding and context tagging XmlDoc comment display for C++ and C.
   // 
   // A better way to do this is pretty complicated and possibly slow because must call analyze
   // the comment that is already present to see if it is an XmlDoc comment 
   // (like _parse_multiline_comments() does). Also, if no comment is present, generate a 
   // javadoc comment (or use a def var).
   //
   return def_c_xmldoc;
}

boolean _cs_is_xmldoc_supported()
{
   return true;
}

boolean _jsl_is_xmldoc_supported()
{
   return true;
}

/** 
 * Check to see if xmldoc comments are supported for <B>lang</B>
 * 
 * @param lang Language to check
 * 
 * @return boolean true if xmldoc comments are supported for 
 *         <B>lang</B>
 */
boolean _is_xmldoc_supported(_str lang=null)
{
   if ( lang==null ) lang = p_LangId;
   index := _FindLanguageCallbackIndex('-%s-is-xmldoc-supported',lang);
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
 * @return boolean true if xmldoc comments are preferred for <B>lang</B>
 */
boolean _is_xmldoc_preferred(_str lang=null)
{
   if ( lang==null ) lang = p_LangId;
   if (!_is_xmldoc_supported) return false;
   index := _FindLanguageCallbackIndex('-%s-is-xmldoc-preferred',lang);
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

   _UpdateContext(true);
   save_pos(auto p);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   restore_pos(p);
   if (context_id <= 0) {
      return(MF_GRAYED);
   }
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) /*|| !javadocSupported*/) {
      return(MF_GRAYED);
   }
   //status=(index_callable(find_index('_'p_LangId'_fcthelp_get_start',PROC_TYPE)) );
   int status=_EmbeddedCallbackAvailable('_%s_generate_function');
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
static int _xmldoc_comment(_str slcomment_start_seq = '///')
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported)/* || !javadocSupported */) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      _message_box('XML documentation comment not supported for this file type');
      return(1);
   }
   mlcomment_start='///';
   mlcomment_end='///';
   save_pos(auto p);
   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   if (context_id <= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      _message_box('no current tag');
      return context_id;
   }

   // get the information about the current function
   _str tag_name="";
   _str type_name="";
   _str file_name="";
   _str class_name="";
   _str signature="";
   _str return_type="";
   int tag_flags=0;
   int start_line_no=0;
   int start_seekpos=0;
   int scope_line_no=0;
   int scope_seekpos=0;
   int end_line_no=0;
   int end_seekpos=0;
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);

   // get the start column of the tag, align new comment here
   if (tag_tree_type_is_func(type_name)) {
      _GoToROffset((scope_seekpos<end_seekpos)? scope_seekpos:start_seekpos);
      _UpdateLocals(true);
   }
   _GoToROffset(start_seekpos);
   int start_col = p_col;

   int comment_flags=0;
   // hash table of original comments for incremental updates
   _str orig_comment='';
   int first_line, last_line;
  if (!_do_default_get_tag_header_comments(first_line, last_line)) {
     //Removed code to merge in the contents of existing comments,
     first_line = last_line;
  } else {
     first_line = start_line_no;
     last_line  = first_line-1;
  }

  // delete the original comment lines
   typeless i=0;
   int num_lines = last_line-first_line+1;
   if (num_lines > 0) {
      p_line=first_line;
      for (i=0; i<num_lines; i++) {
         _delete_line();
      }
   } else {
      first_line=start_line_no;
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }

   // insert the comment start string and juggle slcomment if needed
   if (first_line>1) {
      p_line=first_line-1;
   } else {
      top();up();
   }
   slcomment_start = slcomment_start_seq;
   /*if (mlcomment_start!='') {
      insert_line(indent_string(start_col-1):+'///');
      slcomment_start='';
      if (pos('*',mlcomment_start)) {
         slcomment_start=' *';
      }
   } */
   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);

   _insert_text('<document>');insert_line('');
   if (orig_comment!='' && (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC)) {
      _insert_text(orig_comment);
   } else {
      _insert_text('<summary>');_insert_text(p_newline);
      orig_comment=stranslate(orig_comment,'&lt;','<');  // Translate < to &lt;
      orig_comment=stranslate(orig_comment,'&gt;','>');  // Translate < to &gt;
      _insert_text(orig_comment);
      if (!pos("[\n\r]:b$",orig_comment,1,'r')) {
         _insert_text(p_newline);
      }
      _insert_text('</summary>');_insert_text(p_newline);
   }
   _insert_text('</document>');
   typeless status=0;
   typeless handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (handle<0) {
      _message_box('XML not valid.  Correct the XML and try again.');
      return(1);
   }
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);

   /*
      Place the parameters and return after <summary>/<value>/<remarks>

   */
   //Find the handle to the first parameter
   int first_param_handle=_xmlcfg_find_simple(handle,"param");
   if (first_param_handle<0) {
      first_param_handle=_xmlcfg_find_simple(handle,"return");
   }
   int node_index=0;
   int next_index=0;
   boolean do_insert_child=true;
   if (first_param_handle>=0) {
      node_index=_xmlcfg_get_prev_sibling(handle,first_param_handle);
      if (node_index>=0) {
         do_insert_child=false;
      } else {
         node_index=_xmlcfg_get_parent(handle,first_param_handle);
      }
   } else {
      node_index=_xmldoc_find_description_node(handle);
      if (node_index<0) {
         node_index=_xmlcfg_find_simple(handle,"/document");
      } else {
         do_insert_child=false;
      }
      if (do_insert_child) {
         next_index=_xmlcfg_get_first_child(handle,node_index,-1);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            node_index=next_index;
            do_insert_child=false;
         }
      } else {
         next_index=_xmlcfg_get_next_sibling(handle,node_index,-1);
         if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
            node_index=next_index;
         }
      }
   }


   // insert the original parts of the comment (description)
   typeless cursor_pos=null;

   // insert the parameter descriptions, recycle old ones
   // insert a blank line before the javadoc tags, if necessary
   get_line(auto last_inserted);
   boolean valid_param:[];
   for (i=1; i<=tag_get_num_of_locals(); i++) {
      _str param_name='';
      _str param_type='';
      int local_seekpos=0;
      tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
      tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
      if (param_type=='param' && local_seekpos>=start_seekpos) {
         tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
         int param_index=_xmlcfg_find_simple(handle,"//param[@name='"param_name"']");
         valid_param:[param_name]=true;
         // IF this parameter is not present
         if (param_index<0) {
            node_index=_xmlcfg_add(handle,node_index,'param',VSXMLCFG_NODE_ELEMENT_START,(do_insert_child)?VSXMLCFG_ADD_AS_CHILD:0);
            _xmlcfg_add_attribute(handle,node_index,'name',param_name);
            node_index=_xmlcfg_add(handle,node_index,'',VSXMLCFG_NODE_PCDATA,0);
            _xmlcfg_set_value(handle,node_index,p_newline);
         } else {
            // Really should move (copy then delete) the parameter tag to make sure the order is correct
            node_index=_xmlcfg_copy(handle,node_index,handle,param_index,(do_insert_child)?VSXMLCFG_COPY_AS_CHILD:0);
            next_index=_xmlcfg_get_next_sibling(handle,param_index,-1);
            _xmlcfg_delete(handle,param_index);

            if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
               // Move the PCDATA
               node_index=_xmlcfg_copy(handle,node_index,handle,next_index,0);
               _xmlcfg_delete(handle,next_index);
            }

            //node_index=param_index;
         }
         do_insert_child=false;
      }
   }

   typeless array[];
   _xmlcfg_find_simple_array(handle,'param[@name]',array);

   boolean hit_param=false;
   for (i._makeempty();;) {
       array._nextel(i);
       if (i._isempty()) break;
       if (!valid_param._indexin(_xmlcfg_get_value(handle,array[i]))) {
          // Could move this parameter to the end and put start/end old parameters around them
          _xmlcfg_delete(handle,array[i]);
       }
   }

   // insert the return type description, recycle old one if present
   int return_index=_xmlcfg_find_simple(handle,'/document/returns');
   if (return_index>=0) {
      if (!(return_type!='' && return_type!='void')) {
         _xmlcfg_delete(handle,return_index);
      }
   } else if (return_type!='' && return_type!='void' && tag_tree_type_is_func(type_name)) {
      node_index=_xmlcfg_add(handle,node_index,'returns',VSXMLCFG_NODE_ELEMENT_START,(do_insert_child)?VSXMLCFG_ADD_AS_CHILD:0);
      do_insert_child=false;
      int pcdata_index=_xmlcfg_add(handle,node_index,'',VSXMLCFG_NODE_PCDATA,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_value(handle,pcdata_index,return_type);
      node_index=_xmlcfg_add(handle,node_index,'',VSXMLCFG_NODE_PCDATA,0);
      _xmlcfg_set_value(handle,node_index,p_newline);
   }

   orig_view_id=_create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(p_window_id,handle,0 /* Preserve PCDATA white space */,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   _xmlcfg_close(handle);
   top();_delete_line();bottom();_delete_line();_delete_line();
   top();
   search('^'substr('',1,p_SyntaxIndent),'rh@',prefix);
   int temp_buf_id=p_buf_id;
   activate_window(orig_view_id);
   _buf_transfer(temp_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   // restore the search and current position
   return(0);
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
_command void xmldoc_comment(typeless slcomment_start = '///') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( !_is_xmldoc_supported() ) {
      _message_box('XML documentation comment not supported for this file type');
      return;
   }
   _EmbeddedCall(_xmldoc_comment, slcomment_start);
}

int _OnUpdate_xmldoc_editor(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_xmldoc_comment(cmdui,target_wid,command));
}

_command void xmldoc_editor(_str deprecate='') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (p_active_form.p_name == '_javadoc_form' || p_active_form.p_name=='_xmldoc_form') {
      return;
   }
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if (get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || slcomment_start!='//') {
      _message_box('XMLDOC comment not supported for this file type');
      return;
   }
   show('-xy -modal _xmldoc_form');
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
   typeless status=search('<summary>','h@xcs');
   if (status) {
      restore_pos(p);
      return(1);
   }

   //say('found <summary>');

   first_line=p_line;  // <summary> found, save current line

   // find the next </member> tag
   status=search('</member>','h@xcs');
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

static void jdcmd_maybe_deselect_command(typeless pfn)
{
   if (!in_cua_select) {
      if (select_active()) {
         if ( _select_type('','U')!='P') {
            _deselect();
         }
      }
   }
   (*pfn)();
}
static void jdcmd_rubout()
{
   if(jdmaybe_delete_selection()) return;
   _rubout();
}
static void jdcmd_linewrap_rubout()
{
   if(jdmaybe_delete_selection()) return;
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
static void jdcmd_delete_char()
{
   if(jdmaybe_delete_selection()) return;
   _delete_char();
}
static void jdcmd_linewrap_delete_char()
{
   if(jdmaybe_delete_selection()) return;
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
static void jdcmd_cua_select()
{
   in_cua_select=1;
   cua_select();
   in_cua_select=0;
}

static void jdcmd_cut_line()
{
   jdmaybe_delete_selection();
   cut_line();
   if (_lineflags()& HIDDEN_LF) {
      up();insert_line('');
      _lineflags(0,HIDDEN_LF);
   }
}
static void jdcmd_delete_line()
{
   jdmaybe_delete_selection();
   _delete_line();
   if (_lineflags()& HIDDEN_LF) {
      up();insert_line('');
      _lineflags(0,HIDDEN_LF);
   }
}
static void jdcmd_join_line()
{
   save_pos(auto p);
   down();
   if (_lineflags()& HIDDEN_LF) {
      restore_pos(p);
      return;
   }
   join_line();
}
static void jdcmd_cut_end_line()
{
   if(jdmaybe_delete_selection()) return;
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
static void jdcmd_erase_end_line()
{
   if(jdmaybe_delete_selection()) return;
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
void _parseXMLDocComment(_str &member_msg,_str &description,_str (&hashtab):[][],_str (&tagList)[])
{
   if (XML_HANDLE) {
      _xmlcfg_close(XML_HANDLE);
      XML_HANDLE='';
   }
   hashtab._makeempty();
   tagList._makeempty();

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _insert_text('<document>');_insert_text(member_msg);
   get_line(auto line);
   if(line=='') _delete_line();
   bottom();_insert_text("\n</document>");_delete_text(-2);
   boolean allow_save=1;
   typeless status=0;
   typeless handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (handle<0) {
      delete_all();
      insert_line('<document>');
      insert_line('<summary>XML not valid.  Correct the XML comment and try again.</summary>');
      insert_line('</document>');
      handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
      allow_save=0;
   }
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   XML_HANDLE=handle;

   ALLOW_SAVE=allow_save;

   description=member_msg;
   /*
       Look for description tag
         summary, remarks, value, or exception
   */
   int node_index=_xmldoc_find_description_node(handle);
   description=_xmldoc_get_xml_as_text(handle,node_index);

   typeless array[];
   _xmlcfg_find_simple_array(handle,'/document/param',array);
   _str tag='param';
   int i;
   for (i=0;i<array._length();++i) {
      //say('name='_xmlcfg_get_attribute(handle,array[i],'name'));
      //say('text='_xmldoc_get_xml_as_text(handle,array[i]));
      hashtab:[tag][hashtab:[tag]._length()]=_xmlcfg_get_attribute(handle,array[i],'name')" "_xmldoc_get_xml_as_text(handle,array[i]);
      tagList[tagList._length()]=tag;
   }
   node_index=_xmlcfg_find_simple(handle,'/document/returns');
   if (node_index>=0) {
      tag='return';
      hashtab:[tag][hashtab:[tag]._length()]=_xmldoc_get_xml_as_text(handle,node_index);
      tagList[tagList._length()]=tag;
   }
   _xmlcfg_find_simple_array(handle,'/document/seealso',array);
   tag='see';
   for (i=0;i<array._length();++i) {
      _str cref=_xmlcfg_get_attribute(handle,array[i],'cref');
      if (cref!='') {
         hashtab:[tag][hashtab:[tag]._length()]=cref;
         tagList[tagList._length()]=tag;
      }
   }
   node_index=_xmlcfg_find_simple(handle,'/document/example');
   if (node_index>=0) {
      tag='example';
      hashtab:[tag][hashtab:[tag]._length()]=_xmldoc_get_xml_as_text(handle,node_index);
      tagList[tagList._length()]=tag;
   }
}
defeventtab _xmldoc_preview_form;
void _javadoc_preview_form.on_create(_str htmltext)
{
   ctlminihtml1.p_text=htmltext;

   ctlminihtml1._codehelp_set_minihtml_fonts(
      _default_font(CFG_FUNCTION_HELP),
      _default_font(CFG_FUNCTION_HELP_FIXED));
}
void _javadoc_preview_form.on_resize(boolean doMove)
{
   if (doMove) return;
   ctlminihtml1._move_window(0,0,_dx2lx(SM_TWIP,p_client_width),_dy2ly(SM_TWIP,p_client_height));
}
void _javadoc_preview_form.esc()
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
}
void ctlok.lbutton_up()
{
   int old_def_xmldoc_format_flags=def_xmldoc_format_flags;

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

   if(old_def_xmldoc_format_flags!=def_xmldoc_format_flags) {
      _macro_append("def_xmldoc_format_flags="def_xmldoc_format_flags";");
   }

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

   int node_index=_xmlcfg_find_simple(handle,"/document/summary");
   if (node_index<0) {
      node_index=_xmlcfg_find_simple(handle,"/document/remarks");
      if (node_index<0) {
         node_index=_xmlcfg_find_simple(handle,"/document/value");
         if (node_index<0) {
            node_index=_xmlcfg_find_simple(handle,"/document/exception");
         }
      }
   }
   return(node_index);
}
_str _xmldoc_get_xml_as_text(int handle,int node_index)
{
   if (node_index<0) {
      return('');
   }
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   int status=_xmlcfg_save_to_buffer(p_window_id,handle,0 /* Preserce PCDATA white space */,VSXMLCFG_SAVE_ALL_ON_ONE_LINE,node_index);
   top();

   _str line="";
   status=search( '<code>' ,'rh@');
   if (status) {
      int min_col=0;
      // Skip the first line.
      // Find the non-blank line with the least number of spaces
      for (;;) {
         if (down()) {
            break;
         }
         get_line(line);
         if (line!='') {
            first_non_blank();
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
            if (line!='') {
               replace_line(_expand_tabsc(min_col,-1,"S"));
            }
         }
      }
   }
   top();
   _str description=get_text(p_buf_size);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   return(description);
}
void _showxml(int handle,int node_index=TREE_ROOT_INDEX,int flags=VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,
              int IndentAmount=3)
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _xmlcfg_save_to_buffer(0,handle,IndentAmount,flags,node_index);
   xml_mode();
   _showbuf(p_buf_id);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
}
static void _xmldoc_add_blank_line_after(int handle,int node_index)
{
   int next_index=_xmlcfg_get_next_sibling(handle,node_index,~VSXMLCFG_NODE_ATTRIBUTE);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      _str line=_xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      _str first="", second="";
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
   int newline_index=_xmlcfg_add(handle,node_index,'',VSXMLCFG_NODE_PCDATA,0);
   _xmlcfg_set_value(handle,newline_index,"\n");
}
static int _xmldoc_add_linebreak(int handle,int node_index)
{
   int next_index=_xmlcfg_get_next_sibling(handle,node_index,~VSXMLCFG_NODE_ATTRIBUTE);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      _str line=_xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      _str first="", second="";
      parse line with first "\n" second "\n";
      if (first=="" && pos("?*\n",line,1,"r")) {
         return(next_index);
      }
      _xmlcfg_set_value(handle,next_index,"\n":+line);
      return(next_index);
   }
   int newline_index=_xmlcfg_add(handle,node_index,'',VSXMLCFG_NODE_PCDATA,0);
   _xmlcfg_set_value(handle,newline_index,"\n");
   return(newline_index);
}
static void _xmldoc_xlat_to_html3(int handle,int node_index,_str &result,_str start_term_tag,_str end_term_tag)
{
   //_message_box('recurse 'result' n='_xmlcfg_get_name(handle,node_index));
   _str text="";
   int child=_xmlcfg_get_first_child(handle,node_index,~VSXMLCFG_NODE_ATTRIBUTE);
   while (child>=0) {
      switch (_xmlcfg_get_type(handle,child)) {
      case VSXMLCFG_NODE_ELEMENT_START:
      case VSXMLCFG_NODE_ELEMENT_START_END:
         _str name=_xmlcfg_get_name(handle,child);
         _str begin_tags='';
         _str end_tags='';
         _str start_term_tag2=start_term_tag;
         _str end_term_tag2=end_term_tag;
         switch (name) {
         case 'c':
            begin_tags='<code>';
            end_tags='</code>';
            break;
         case 'code':
            begin_tags='<pre><code>';
            end_tags='</code></pre>';
            break;
         case 'see':
            _str cref=_xmlcfg_get_attribute(handle,child,"cref");
            if (cref!='') {
               text=see_info2html(cref);
               if (text!="") {
                  result=result:+text;
               }
            }
            break;
         case 'list':
            // Find the first item
            //item_index=_xmlcfg_find_simple(handle,'item/term',child);
            if(_xmlcfg_find_simple(handle,'item/term',child)>=0) {
               begin_tags='<dl>';
               end_tags='</dl><p>';
               start_term_tag2='<DD>';
               end_term_tag2='</DD>';
            } else {
               _str type=_xmlcfg_get_attribute(handle,child,'type');
               if (type=='bullet') {
                  begin_tags='<ul>';
                  end_tags='</ul><p>';
               } else {
                  begin_tags='<ol>';
                  end_tags='</ol><p>';
               }
               start_term_tag2='<LI>';
               end_term_tag2='';
            }
            break;
         case 'description':
            begin_tags=start_term_tag;
            end_tags=end_term_tag;
            break;
         case 'term':
            begin_tags='<dt>';
            end_tags='</dt>';
            break;
         case 'para':
            begin_tags='<p>';
            break;
         case 'paramref':
            cref=_xmlcfg_get_attribute(handle,child,'name');
            if (name!='') {
               text='<a href="'JAVADOCHREFINDICATOR:+JAVADOCHREFINDICATOR:+cref'">'strip(cref)'</a>';
               if (text!="") {
                  result=result:+text;
               }
            }
            break;
         }
         if (name!='listheader') {
            result=result:+begin_tags;
            _xmldoc_xlat_to_html3(handle,child,result,start_term_tag2,end_term_tag2);
            /*if (name=='list') {
               _message_box(result);
            } */
            result=result:+end_tags;
         }
         break;
      case VSXMLCFG_NODE_PCDATA:
         text=_xmlcfg_get_value(handle,child);
         if (text!=null) result=result:+text;
         break;
      }
      child=_xmlcfg_get_next_sibling(handle,child,~VSXMLCFG_NODE_ATTRIBUTE);
   }
}
static _str _xmldoc_xlat_to_html2(int handle,int node_index)
{
   _str result;
   result='';
   _xmldoc_xlat_to_html3(handle,node_index,result,'<dd>','</dd>');
   return(result);
}
static _str see_info2html(_str text)
{
   text=strip(text,'T',"\n");
   if (substr(text,1,1)=='"') {
      text=strip(text,'B','"');
   } else if (substr(text,1,1)=='<') { // URL
   } else if (substr(text,1,7)=='http://' || substr(text,1,4)=='www.') { // URL
      text='<a href="'text'">'text'</a>';
   } else { // package.class#member(int a,int b) label
      _str label='';
      _str packageClassMember='';
      int j=lastpos(')',text);
      int k=pos(' ',text);
      if (j) {
         label=substr(text,j+2);
         packageClassMember=strip(substr(text,1,j));
      } else if (k) {
         label=substr(text,k+1);
         packageClassMember=strip(substr(text,1,k-1));
      } else {
         label="";
         packageClassMember=text;
      }
      // If we don't have label
      if (label=="") {
         label=packageClassMember;
         if (substr(label,1,1)=='#') {
            label=substr(label,2);
         } else {
            int i=pos('#',label);
            if (i) {
               label=substr(label,1,i-1):+'.':+substr(label,i+1);
            }
         }
      }
      text='<a href="'JAVADOCHREFINDICATOR:+packageClassMember'">'strip(label)'</a>';
   }
   return(text);
}
_str _xmldoc_xlat_to_html(_str comment_text,_str return_type,_str param_name='')
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _insert_text('<document>');_insert_text(comment_text);_insert_text('</document>');
   typeless status=0;
   typeless handle=_xmlcfg_open_from_buffer(0,status,VSXMLCFG_OPEN_ADD_PCDATA);
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   if (handle<0) {
      comment_text='<pre style=margin-top:0;margin-bottom:0><xmp style="margin-top:0;margin-bottom:0">'comment_text'</xmp></pre>';
      return(comment_text);
   }
   _str member_msg='<DL>';
   // We use a slightly different ddstyle than
   // Javadoc because indenting on comment contuations
   _str ddstyle=' style="margin-left:13pt"';
   _str ddstyle_param=' style="margin-left:26pt;text-indent:-13pt"';

   typeless array[];
   _str text="";
   int i=0, count=0;

   boolean params_done=false;
   int node_index=_xmlcfg_get_first_child(handle,_xmlcfg_find_simple(handle,'/document'));
   for (;node_index>=0;) {
      _str tag=_xmlcfg_get_name(handle,node_index);
      if (tag=='param') {
         if (!params_done) {
            params_done=true;
            // Do all the parameters now
            member_msg=member_msg:+"<DT><B>Parameters:</B>";
            _xmlcfg_find_simple_array(handle,'/document/param',array);
            count=array._length();
            for (i=0;i<count;++i) {
               text=_xmldoc_xlat_to_html2(handle,array[i]);
               _str argName=_xmlcfg_get_attribute(handle,array[i],'name');
               if (argName!=null) {
                  _str argNameOnly='';
                  parse argName with argNameOnly '(' .;  // Not sure when this happens?
                  _str argAnchor='<A NAME="'argNameOnly'">'argName'</A>';
                  //_message_box('argName='argName' text='text);
                  if (param_name!='' && argNameOnly==param_name) {
                     //_str arrowPtr="<img src=vslick://_execpt.ico>&nbsp;";
                     _str arrowPtr="<img src=vslick://_arrowc.ico>&nbsp;";
                     _str ddstyle_param2=' style="margin-left:26pt;text-indent:-26pt"';
                     member_msg=member_msg:+"<dd"ddstyle_param2">":+arrowPtr:+"<code><b>":+argAnchor"</b></code> - ":+text;
                  } else {
                     member_msg=member_msg:+"<dd"ddstyle_param"><code>":+argAnchor:+"</code> - ":+text;
                  }
               }
            }
         }
      } else if (tag=='seealso') {
      /*} else if (tag=='summary' || tag=='remarks' || tag=='value' || tag=='exception') {
         member_msg=member_msg:+"<DT>"_xmldoc_xlat_to_html2(handle,node_index);*/
      } else if (tag=='exception') {
         _str crefName = _xmlcfg_get_attribute(handle,node_index,'cref');
         if (crefName != '') {
            crefName='<a href="'JAVADOCHREFINDICATOR:+crefName'">'strip(crefName)'</a>';
         }
         member_msg=member_msg:+"<DT><B>"upcase(substr(tag,1,1)):+substr(tag,2)":</b> "crefName;
         member_msg=member_msg:+"<dd"ddstyle">":+_xmldoc_xlat_to_html2(handle,node_index);
      } else {
         member_msg=member_msg:+"<DT><B>"upcase(substr(tag,1,1)):+substr(tag,2)":</B>";
         member_msg=member_msg:+"<dd"ddstyle">":+_xmldoc_xlat_to_html2(handle,node_index);
      }
      node_index=_xmlcfg_get_next_sibling(handle,node_index);
   }
   _xmlcfg_find_simple_array(handle,'/document/seealso',array);
   if (array._length()) {
      member_msg=member_msg:+"<DT><B>See Also:</B>";
      member_msg=member_msg:+"<dd"ddstyle">";
      count=array._length();
      for (i=0;i<count;++i) {
         _str cref=_xmlcfg_get_attribute(handle,array[i],"cref");
         if (cref!='') {
            text=cref;
            text=see_info2html(text);
            if (text!="") {
               if (i==0) {
                  member_msg=member_msg:+text;
               } else {
                  member_msg=member_msg:+', 'text;
               }
            }
         }
      }
   }

   member_msg=member_msg:+"</DL>";
   //_message_box(member_msg);
   return(member_msg);
}
void _xmldoc_remove_blank_line(int handle,int index)
{
   int next_index=_xmlcfg_get_next_sibling(handle,index,-1);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      _str line=_xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      _str first="", second="", rest="";
      parse line with first "\n" second "\n";
      if (first=="" && second=="" && pos("\n?*\n",line,1,"r")) {
         parse line with first "\n" rest;
         _xmlcfg_set_value(handle,next_index,rest);
      }
   }
}
void _xmldoc_remove_eol(int handle,int index)
{
   int next_index=_xmlcfg_get_next_sibling(handle,index,-1);
   if (next_index>=0 && _xmlcfg_get_type(handle,next_index)==VSXMLCFG_NODE_PCDATA) {
      _str line=_xmlcfg_get_value(handle,next_index);
      line=stranslate(line,"","\r");
      _str first="", second="", rest="";
      parse line with first "\n" second "\n";
      if (first=="" && pos("\n",line,1,"r")) {
         parse line with first "\n" rest;
         _xmlcfg_set_value(handle,next_index,rest);
      }
   }
}
