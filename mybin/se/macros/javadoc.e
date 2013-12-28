////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49775 $
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
#include "color.sh"
#include "diff.sh"
#include "minihtml.sh"
#include "treeview.sh"
#import "c.e"
#import "cbrowser.e"
#import "clipbd.e"
#import "codehelp.e"
#import "context.e"
#import "diff.e"
#import "dlgman.e"
#import "htmltool.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "picture.e"
#import "pushtag.e"
#import "recmacro.e"
#import "reflow.e"
#import "sellist.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "xmldoc.e"
#import "se/tags/TaggingGuard.e"
#endregion

//#define REMOVECODE 0
//#pragma option(autodeclvars,off)

/**
 * Returns the string representation of a specific subarray of the
 * <code>char</code> array argument.
 * <p>
 * The <code>offset</code> argument is the index of the first
 * character of the subarray. The <code>count</code> argument
 * specifies the length of the subarray. The contents of the subarray
 * are copied; subsequent modification of the character array does not
 * affect the newly created string.
 *
 * @param   data
 * @param   offset   the initial offset into the value of the
 * <code>String</code>.
 * @param   count    the length of the value of the <code>String</code>.
 * more text
 * @return  a newly allocated string representing the sequence of
 * characters contained in the subarray of the character array
 * argument.
 * @exception NullPointerException if <code>data</code> is
 *          <code>null</code>.
 * @exception IndexOutOfBoundsException if <code>offset</code> is
 * negative, or <code>count</code> is negative, or
 * <code>offset+count</code> is larger than
 * <code>data.length</code>.
 * @see     java.lang.StringBuffer#append(long)
 * @see     java.lang.StringBuffer#append(java.lang.Object)
 * @see     java.lang.StringBuffer#append(java.lang.String)
 * @since   JDK1.0
 * @author  Lee Boynton
 * @author  Arthur van Hoff
 * @version 1.112, 09/23/98
 */


static int _testdoc1(int data[], int offset, int count)
{
   return 0;
}

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

/**
 * Controls whether or not the JavaDoc editor will preserve
 * comments for obsolete or misnamed parameters.
 *
 * @categories Configuration_Variables
 */
boolean def_javadoc_keep_obsolete=false;

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
#define USE_EXCEPTION_TAG ctlpreview.p_user
   _control ctltree1;

defeventtab _javadoc_form;
void ctloptions.lbutton_up()
{
   show('-modal _javadoc_format_form');
}
struct JDSEEUSERDATA {
   int NofHiddenLinesBefore;
   int NofHiddenLinesAfter;
   int NofHiddenBytes;
};
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
   int restore_linenum=0;
   int i=0;
   for (i=1;;++i) {
      if (text:=='') break;
      _str line="";
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
   typeless junk="";
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

   int oldwid=0;
   boolean oldmodify=0;
   int origline=wid.p_line;
   wid.get_line(line);
   boolean onlast=OnLastLine();
   int isimaginary=wid._lineflags()&NOSAVE_LF;
   if (isimaginary && !DialogIsDiff()) {
      return;
   }
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
      wid.delete_line();
      if (isimaginary) p_modify=oldmodify;
      break;
   case 'delete-selection':
      wid.delete_selection();break;
   default:
      wid._begin_select();
      oldwid=p_window_id;p_window_id=wid;
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
               int first_col=0;
               int last_col=0;
               typeless junk="";
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
void ctlsee1.'<'()
{
}
void ctlsee1.'<'()
{
   jdmaybe_delete_selection();
   _str line="";
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
   jdmaybe_delete_selection();
   _str line="";
   get_line(line);
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      keyin('#');
      return;
   }
   auto_codehelp_key();
}
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
//void _javadoc_form.A_A-A_Z()
void _javadoc_form.A_K,A_X,A_O,A_T,A_N,A_P,A_A,A_X,A_M,A_U,A_I()
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
   jdMaybeSave(true);
   p_active_form._delete_window();
}

static _str jdSSTab[][]={
   {"0"},
   {"ctldescriptionlabel1"},
   {"ctldescriptionlabel2"},
   {"ctldescriptionlabel3","ctlsincelabel3","ctlexamplelabel3","ctlexamplenotelabel3"},
};
static int jdPercentageHashtab:[]={
   "ctldescription1"=> 50,
   "ctldeprecated1"=>22,
   "ctlsee1"=>28,

   "ctldescription2"=> 50,
   "ctldeprecated2"=>22,
   "ctlsee2"=>28,

   "ctldescription3"=> 50,
   "ctlparam3"=> 25,
   "ctlreturn3"=> 25,

   "ctldeprecated3"=>30,
   "ctlsee3"=>35,
   "ctlexception3"=> 35,

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
static void jdCopyEditorCtlData(int form_wid,_str prefix,_str ctlname,int flag,boolean &addBlankBeforeNext,_str atTagSpace="",boolean atTagSpaceFirstLineOnly=true)
{
   int wid=form_wid._find_control(ctlname:+form_wid.CURJAVATYPE);
   if (wid && wid.p_visible) {
      if (!wid.p_Noflines) {
         return;
      }
      _str line="";
      wid.get_line(line);
      if (ctlname=='ctlexample' && wid.p_Noflines==1 && line=='') {
         return;
      }
      int status=0;
      typeless p;
      wid.save_pos(p);
      wid.top();
      boolean isdescription=(ctlname=='ctldescription');
      if (isdescription) {
         status=wid.search('^[ \t]*\@','@rh');
      }
      wid.bottom();
      while (wid.p_Noflines>1) {
         wid.get_line(line);
         if (line!="") break;
         wid._delete_line();
      }
      boolean doBeautify=false;
      _str indent="";

      if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (
          (ctlname=='ctlreturn' &&

             (def_javadoc_format_flags & VSJAVADOCFLAG_ALIGN_RETURN)) ||
          (ctlname=='ctldeprecated' &&

             (def_javadoc_format_flags & VSJAVADOCFLAG_ALIGN_DEPRECATED))
          )

         ) {
         wid.top();
         status=wid.search( '<pre|<xmp' ,'rh@i');
         if (status) {
            doBeautify=true;
            indent=substr('',1,length(atTagSpace));
         }
      }
      wid.top();wid.up();
      for (;;) {
         if (wid.down()) break;
         if (wid._lineflags() & HIDDEN_LF) {
            continue;
         }
         wid.get_line(line);
         if (ctlname!='ctlsee' || line!='') {
            if (addBlankBeforeNext) {
               insert_line(prefix);
               addBlankBeforeNext=false;
            }
            if (doBeautify && length(atTagSpace)==0) {
               insert_line(prefix:+atTagSpace:+indent:+strip(line));
            } else {
               insert_line(prefix:+atTagSpace:+line);
            }
         }
         if (atTagSpaceFirstLineOnly) {
            atTagSpace='';
         }
      }
      wid.restore_pos(p);
      if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_javadoc_format_flags & flag)
          ) {
         for (;;) {
            get_line(line);
            line=substr(line,length(prefix));
            if (line!="") {
               break;
            }
            if(!_delete_line()) {
               if (up()) break;
            }
         }
         if (status) {
            addBlankBeforeNext=true;
         }
      }
   }
}
static void jdCopyComboCtlData(int form_wid,_str prefix,_str ctlname,int flag,boolean &addBlankBeforeNext,_str tag,_str tagPrefix="@")
{

   _str hashindex_tag=tag;
   if (tag=='exception' && !form_wid.USE_EXCEPTION_TAG) {
      tag='throws';
   }
   
   _str list="";
   _str line="";
   _str argName="";
   _str rest="";

   int wid=form_wid._find_control(ctlname:+form_wid.CURJAVATYPE);
   if (wid) {
      _str hashtab:[][]=form_wid.HASHTAB;
      // If there are parameters
      int count=hashtab:[hashindex_tag]._length();
      if (!def_javadoc_keep_obsolete && 
          hashindex_tag=='param' && hashtab._indexin('@paramcount')) {
         count=(int)hashtab:['@paramcount'][0];
      }
      int i=0;
      int LongestLen= -1;
      int minLen,maxLen;
      int flag2;
      if (hashindex_tag=='param') {
         flag2=VSJAVADOCFLAG_ALIGN_PARAMETERS;
         minLen=def_javadoc_parammin;
         maxLen=def_javadoc_parammax;
      } else {
         flag2=VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
         minLen=def_javadoc_exceptionmin;
         maxLen=def_javadoc_exceptionmax;
      }
      if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
          (def_javadoc_format_flags & flag2)
          ) {
         LongestLen=minLen;
         // Determine the longest parameter name.
         for (i=0;i<count;++i) {
            list=hashtab:[hashindex_tag][i];
            parse list with line "\n" list;
            parse line with argName rest;
            if (hashindex_tag!='param' || !def_javadoc_keep_obsolete ||
                i<hashtab:['@paramcount'][0] ||
                rest!='' || list!='') {
               if (length(argName)>LongestLen) {
                  if (length(argName)<=maxLen) {
                     LongestLen=length(argName);
                  }
               }
            }
         }
         if (LongestLen<minLen) {
            LongestLen=minLen;
         }
      }

      for (i=0;i<count;++i) {
         list=hashtab:[hashindex_tag][i];
         parse list with line "\n" list;
         parse line with argName rest;
         if (hashindex_tag!='param' || !def_javadoc_keep_obsolete ||
             i<hashtab:['@paramcount'][0] ||
             rest!='' || list!='') {
            _str indent="";
            boolean doBeautify=false;
            if (addBlankBeforeNext) {
               insert_line(prefix);
               addBlankBeforeNext=false;
            }
            if (LongestLen>=0 && !pos('<pre',rest:+list,1,'i') &&
                !pos('<xmp',rest:+list,1,'i')
                ) {
               if (length(argName)<=LongestLen) {
                  argName=substr(argName,1,LongestLen);
               }
               if (length(argName)>maxLen) {
                  insert_line(prefix:+tagPrefix:+tag:+strip(' 'argName,'T'));
                  indent=substr('',1,length(tagPrefix:+tag)+LongestLen+2);
                  if (rest!='') {
                     insert_line(prefix:+indent:+strip(rest));
                  }
               } else {
                  indent=substr('',1,1+length(tagPrefix:+tag' ')+length(argName));
                  insert_line(prefix:+tagPrefix:+tag:+strip(' 'argName:+' 'strip(rest),'T'));
               }
               doBeautify=true;
            } else {
               doBeautify=false;
               insert_line(prefix:+tagPrefix:+tag' 'argName:+' 'rest);
            }
            for (;;) {
               if (list:=='') {
                  break;
               }
               parse list with line "\n" list;
               if (addBlankBeforeNext) {
                  insert_line(prefix);
                  addBlankBeforeNext=false;
               }
               if (doBeautify) {
                  insert_line(prefix:+indent:+strip(line));
               } else {
                  insert_line(prefix:+indent:+line);
               }
            }
         }
         if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) &&
             ((def_javadoc_format_flags & flag) ||
              (i+1==count && hashindex_tag=="param" &&
               (def_javadoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM)))
             ) {
            for (;;) {
               get_line(line);
               line=substr(line,length(prefix));
               if (line!="") {
                  break;
               }
               int status=_delete_line();
               if (!status) up();
            }
            addBlankBeforeNext=true;
         }
      }
   }
}
/**
 * Insert comment lines into current editor control object.
 * 
 * @param form_wid      Window id of javadoc form
 * @param start_col     Lines are indent up to start_col specified
 * @param comment_flags bitset of VSCODEHELP_COMMENTFLAG_*
 * @param doxygen_comment_start  start characters for Doxygen comments.
 */
static void jdInsertCommentLines(int form_wid,
                                 int start_col,
                                 int comment_flags=0,
                                 _str doxygen_comment_start="",
                                 _str tagPrefix="@")
{

   // save parameter changes
   int wid=form_wid._find_control('ctlparamcombo'form_wid.CURJAVATYPE);
   if (wid) {
      wid.jdShowParam();
   }

   // save parameter changes
   wid=form_wid._find_control('ctlexceptioncombo'form_wid.CURJAVATYPE);
   if (wid) {
      wid.jdShowParam('exception');
   }

   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end);

   if (comment_flags & VSCODEHELP_COMMENTFLAG_DOXYGEN) {
      if (doxygen_comment_start == "//!") {
         mlcomment_start = "";
         mlcomment_end   = "";
         slcomment_start = doxygen_comment_start;
      } else if (doxygen_comment_start == "/*!") {
         mlcomment_start = doxygen_comment_start;
         slcomment_start=' *';
      }
   } else {
      mlcomment_start = "/**";
   }

   if (mlcomment_start!='') {
      insert_line(indent_string(start_col-1):+mlcomment_start);
      slcomment_start='';
      if (pos('*',mlcomment_start)) {
         slcomment_start=' *';
      }
   }

   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';
   boolean addBlankBeforeNext=false;
   jdCopyEditorCtlData(form_wid,prefix,'ctldescription',
                       VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION,addBlankBeforeNext,
                       "",true
                       );

   wid=form_wid._find_control('ctlauthor'form_wid.CURJAVATYPE);
   if (wid && wid.p_text!='') {
      _str author_list=wid.p_text;
      for (;;) {
         _str author="";
         parse author_list with author ',' author_list;
         if (author=='') break;
         if (addBlankBeforeNext) {
            insert_line(prefix);
            addBlankBeforeNext=false;
         }
         insert_line(prefix:+tagPrefix'author 'strip(author));
      }
   }
   wid=form_wid._find_control('ctlversion'form_wid.CURJAVATYPE);
   if (wid && wid.p_text!='') {
      insert_line(prefix:+tagPrefix'version 'strip(wid.p_text));
   }
   jdCopyComboCtlData(form_wid,prefix,'ctlparamcombo',VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS,addBlankBeforeNext,'param',tagPrefix);
   jdCopyEditorCtlData(form_wid,prefix,'ctlreturn',VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN,addBlankBeforeNext,tagPrefix:+'return ');
   jdCopyEditorCtlData(form_wid,prefix,'ctlexample',VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE,addBlankBeforeNext,tagPrefix:+'example ');

   jdCopyComboCtlData(form_wid,prefix,'ctlexceptioncombo',0,addBlankBeforeNext,'exception');

   jdCopyEditorCtlData(form_wid,prefix,'ctlsee',0,addBlankBeforeNext,tagPrefix:+'see ',false);

   wid=form_wid._find_control('ctlsince'form_wid.CURJAVATYPE);
   if (wid && wid.p_text!='') {
      insert_line(prefix:+tagPrefix:+'since 'strip(wid.p_text));
   }
   wid=form_wid._find_control('ctldeprecated'form_wid.CURJAVATYPE);
   if (wid) {
      // IF Deprecated check box is on
      if (wid.p_prev.p_value) {
         jdCopyEditorCtlData(form_wid,prefix,'ctldeprecated',0,addBlankBeforeNext,tagPrefix:+'deprecated ');
      }
   }
   _str line="";
   get_line(line);
   if (line=='*') {
      _delete_line();up();
   }
   if (mlcomment_end != "") {
      insert_line(indent_string(start_col):+mlcomment_end);
   }
}

static void jdMaybeSave(boolean forceSave=false)
{
   if (jdModified() || forceSave) {
      static int recursion;

      if (recursion) return;
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

      int comment_flags=0;
      _str orig_comment="";
      _str return_type="";
      _str line_prefix="";
      _str doxygen_comment_start="";
      int blanks:[][];
      _str tagPrefix="@";
      int status=_GetCurrentCommentInfo(comment_flags,orig_comment,return_type,line_prefix,blanks,doxygen_comment_start);
      if (status != 0) {
         comment_flags=0;
      } else if (comment_flags & VSCODEHELP_COMMENTFLAG_DOXYGEN) {
         if (pos("\\param " ,orig_comment)) tagPrefix="\\";
         if (pos("\\return ",orig_comment)) tagPrefix="\\";
      }

      int first_line, last_line;
      if (_do_default_get_tag_header_comments(first_line, last_line)) {
         first_line = start_line_no;
         last_line  = first_line-1;
      }

      // delete the original comment lines
      int num_lines = last_line-first_line+1;
      if (num_lines > 0) {
         p_line=first_line;
         int i;
         for (i=0; i<num_lines; i++) {
            _delete_line();
         }
      } else {
         first_line=start_line_no;
      }
      p_line=first_line-1;

      jdInsertCommentLines(form_wid,start_col,comment_flags,doxygen_comment_start,tagPrefix);

      _restore_pos2(p);
      activate_window(orig_view_id);

      _str buf_name=editorctl_wid.p_buf_name;
      if (buf_name!='') {
         _str caption="";
         parse p_active_form.p_caption with caption ':';
         p_active_form.p_caption=caption': 'buf_name;
      }

      _javadoc_refresh_proctree(false);
      CURTREEINDEX=ctltree1._TreeCurIndex();
      //say('a1 CURT='CURTREEINDEX' cap='ctltree1._TreeGetCaption(CURTREEINDEX));
      --recursion;
   }
}
void _javadoc_refresh_proctree(boolean curItemMayChange=true)
{
   tag_lock_context(true);
   int form_wid=p_active_form;
   int editorctl_wid=_form_parent();
   editorctl_wid._UpdateContext(true);
   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,'','T');
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_javadoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);
   tag_unlock_context();
   ctltree1._TreeSizeColumnToContents(0);
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
         child._lbclear();
         child.p_text="";
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
               child2._lbclear();
               child2.p_text="";
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
   ctlexceptioncombo3.p_user="";
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
   ctltagcaption.p_x = ctloptions.p_x + ctloptions.p_width + ctltree1.p_y; // options button is auto-sized, plus ctltree1.p_y for padding

   ctltree1.p_height=ctlok.p_y-ctltree1.p_y-100;
   ctltree1.p_width=ctlimage1.p_x-ctltree1.p_x;

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

void jdParseParam(_str &string,_str &argName,_str &text,boolean doBeautify=false,_str tag='')
{
   parse string with argName text;
   parse argName with argName '[ \n]','r';
   if (doBeautify &&
       def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY) {
      int flag2;
      if (tag=='param') {
         flag2=VSJAVADOCFLAG_ALIGN_PARAMETERS;
      } else {
         flag2=VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
      }
      if ( (def_javadoc_format_flags & flag2) &&
           !pos('<pre',text,1,'i') &&
           !pos('<xmp',text,1,'i')
         ) {
         typeless result='';
         for (;;) {
            if (text:=='') {
               break;
            }
            _str line="";
            parse text with line "\n" text;
            if (result=="") {
               result=strip(line);
            } else {
               result=result:+"\n":+strip(line);
            }
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
      jdParseParam(hashtab:[tag][i],argName,text);
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
      jdParseParam(hashtab:[tag][j],param_name,text);
      text=wid.get_text(wid.p_buf_size,0);
      if (wid.p_newline=="\r\n") {
         text=stranslate(text,"","\r");
      } else if (wid.p_newline=="\r") {
         text=stranslate(text,"\n","\r");
      }
      if (text:==wid.p_newline || text=="\n") {
         text='';
      }
      _str linetemp="";
      parse text with linetemp "\n";
      hashtab:[tag][j]=param_name' 'text;
      if (length(text)) {
         widcombo=_find_control('ctl'tag'combo'CURJAVATYPE);
         typeless p;
         widcombo.save_pos(p);
         widcombo._lbtop();
         if (!widcombo._lbfind_and_select_item(param_name' (empty)')) {
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
      jdParseParam(hashtab:[tag][j],param_name,text,true,tag);
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
         jdMaybeSave();
      }
   }
   p_active_form._delete_window();
}
void ctlexceptioncombo3.on_change(int reason)
{
   jdShowParam('exception');
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
#if 1
   int form_wid=p_active_form;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=form_wid._form_parent().p_UTF8;
   _SetEditorLanguage(form_wid._form_parent().p_LangId);
   jdInsertCommentLines(form_wid,1);
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

   show('-xy -modal _javadoc_preview_form',orig_comment);

   activate_window(orig_view_id);
   return;
#else
   _str line="";
   int wid=_find_control('ctldescription'CURJAVATYPE);
   if (wid.p_Noflines==1 && wid.p_buf_size<=4) {
      wid.get_line(line);
      if (line=='') {
         // force output of a comment
         MODIFIED=1;
      }
   }
   jdMaybeSave();
   MODIFIED=0;

   // Line number and type(class,proc|func, other)
   VS_TAG_BROWSE_INFO cm;
   int editorctl_wid=_form_parent();
   int tree_wid=ctltree1;
   int orig_wid=p_window_id;

   int orig_view_id;
   get_window_id(orig_view_id);
   p_window_id=editorctl_wid;

   _UpdateContext(true);
   typeless orig_values="";
   int embedded_status=_EmbeddedStart(orig_values,'');

   _str proc_name,path;
   int start_line_no;
   int javatype;
   tree_wid._ProcTreeTagInfo2(editorctl_wid,cm,proc_name,path,start_line_no);
   save_pos(auto p);
   p_RLine=start_line_no;
   //say('start_line_no='start_line_no);
   //say('proc_name='proc_name);
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
   int start_seekpos=0;
   int scope_line_no=0;
   int scope_seekpos=0;
   int end_line_no=0;
   int end_seekpos=0;
   _str class_name="";
   int tag_flags=0;
   _str signature="";
   _str return_type="";
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);
   _GoToROffset(start_seekpos);

   int comment_flags=0;
   // hash table of original comments for incremental updates
   _str orig_comment='';
   int first_line, last_line;
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      p_RLine=start_line_no;
      _GoToROffset(start_seekpos);
      _do_default_get_tag_comments(comment_flags,type_name, orig_comment, 1000, false);
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   restore_pos(p);
   activate_window(orig_view_id);
   _make_html_comments(orig_comment,comment_flags,'');


   show('-xy -modal _javadoc_preview_form',orig_comment);

   activate_window(orig_view_id);

   int param_wid=0;
   typeless param_p=0;
   _str param_text="";
   int paramcombo_wid=_find_control('ctlparamcombo'CURJAVATYPE);
   if (paramcombo_wid) {
      param_text=paramcombo_wid.p_text;
      param_wid=_find_control('ctlparam'CURJAVATYPE);
      param_wid.save_pos(param_p);
   }

   int exception_wid=0;
   typeless exception_p=0;
   _str exception_text="";
   int exceptioncombo_wid=_find_control('ctlexceptioncombo'CURJAVATYPE);
   if (exceptioncombo_wid) {
      exception_text=exceptioncombo_wid.p_text;
      exception_wid=_find_control('ctlexception'CURJAVATYPE);
      exception_wid.save_pos(exception_p);
   }

   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   if (paramcombo_wid) {
      paramcombo_wid.p_text=param_text;
      param_wid.restore_pos(param_p);
   }
   if (exceptioncombo_wid) {
      exceptioncombo_wid.p_text=exception_text;
      exception_wid.restore_pos(exception_p);
   }
#endif
}
void ctltree1.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
      jdMaybeSave();
      if (TIMER_ID=='') {
         TIMER_ID=_set_timer(40,TimerCallback,p_active_form);
      }

      if (index==TREE_ROOT_INDEX) return;
      CURTREEINDEX=index;
      //say('a3 CURTREEINDEX='CURTREEINDEX);
      _str caption=_TreeGetCaption(CURTREEINDEX);
      _str before="";
      _str after="";
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

      typeless orig_values="";
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
      int start_seekpos=0;
      int scope_line_no=0;
      int scope_seekpos=0;
      int end_line_no=0;
      int end_seekpos=0;
      _str class_name="";
      int tag_flags=0;
      _str signature="";
      _str return_type="";
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

      int comment_flags=0;
      int count=0;
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
      _str description="";
      if (comment_flags & VSCODEHELP_COMMENTFLAG_JAVADOC) {
         _parseJavadocComment(orig_comment, description,hashtab,tagList,false);
      } else {
         init_modified=1;
         description=orig_comment;
      }
      typeless i,j;
      hashtab._nextel(i);
      /*
        ORDER


         deprecated,param,return,throws,since

         others

         Author

         see
      */
      _str param_name="";
      _str argName="";
      _str text="";
      _str list="";

      typeless status=0;
      _str tag="";
      _str line="";
      int wid=_find_control('ctldescription'CURJAVATYPE);
      if (wid) {
         tag="description";
         if (description!="") {
            wid.p_undo_steps=0;
            wid._delete_line();
            wid._insert_text(description);
            while (wid.p_Noflines>1) {
               wid.get_line(line);
               if (line!="") break;
               wid._delete_line();
            }
            wid.p_modify=0;wid.top();
            wid.p_undo_steps=32000;
         }
      }
      wid=_find_control('ctldeprecated'CURJAVATYPE);
      if (wid) {
         tag="deprecated";
         if (hashtab._indexin(tag)) {
            wid.p_undo_steps=0;
            wid._delete_line();
            wid._insert_text(hashtab:[tag][0]);
            while (wid.p_Noflines>1) {
               wid.get_line(line);
               if (line!="") break;
               wid._delete_line();
            }

            if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)
                 && (def_javadoc_format_flags & VSJAVADOCFLAG_ALIGN_DEPRECATED)
                ) {
               wid.top();
               status=wid.search( '<pre|<xmp' ,'rh@i');
               if (status) {
                  wid.up();
                  for(;;) {
                     if (wid.down()) break;
                     wid.get_line(line);
                     wid.replace_line(strip(line));
                  }
               }

            }

            wid.p_modify=0;wid.top();
            wid.p_undo_steps=32000;
            wid.p_prev.p_value=1;
            wid.p_visible=true;

            hashtab._deleteel(tag);
         } else {
            wid.p_prev.p_value=0;
            wid.p_visible=false;
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
               while (wid.p_Noflines>1) {
                  wid.get_line(line);
                  if (line!="") break;
                  wid._delete_line();
               }

               if ((def_javadoc_format_flags & VSJAVADOCFLAG_BEAUTIFY)
                    && (def_javadoc_format_flags & VSJAVADOCFLAG_ALIGN_RETURN)
                   ) {
                  wid.top();
                  status=wid.search( '<pre|<xmp' ,'rh@i');
                  if (status) {
                     wid.up();
                     for(;;) {
                        if (wid.down()) break;
                        wid.get_line(line);
                        wid.replace_line(strip(line));
                     }
                  }

               }

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

      wid=_find_control('ctlparamcombo'CURJAVATYPE);
      if (wid) {
         tag="param";
         // If there are parameters
         boolean hitList[];
         _str new_list[];
         count=0;
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
         }
         for (i=0;i<count;++i) hitList[i]=false;
         _str empty_msg=' (empty)';

         for (i=1; i<=tag_get_num_of_locals(); i++) {
            // only process params that belong to this function, not outer functions
            int local_seekpos=0;
            _str param_type="";
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
            tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
            if (param_type=='param' && local_seekpos>=start_seekpos) {
               tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
               j=jdFindParam('param',param_name,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
               if (j>=0) {
                  jdParseParam(hashtab:[tag][j],argName,text);
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
               jdParseParam(hashtab:[tag][i],argName,text);
               new_list[new_list._length()]=hashtab:[tag][i];
               wid._lbadd_item(argName' (obsolete)');
               if (!def_javadoc_keep_obsolete) {
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

      USE_EXCEPTION_TAG=1;
      wid=_find_control('ctlexceptioncombo'CURJAVATYPE);
      if (wid) {
         USE_EXCEPTION_TAG=1;
         tag="exception";
         boolean hitList[];
         count=0;
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
         } else if (hashtab._indexin('throws')) {
            hashtab:[tag]=hashtab:['throws'];
            hashtab._deleteel('throws');
            count=hashtab:[tag]._length();
            USE_EXCEPTION_TAG=0;
         }
         for (i=0;i<count;++i) hitList[i]=false;
         _str empty_msg=' (empty)';

         if (cm.exceptions!='') {
            list=cm.exceptions;
            _str exception="";
            for (;;) {
               parse list with exception ',' list;
               if (exception=='') break;
               j=jdFindParam('exception',exception,hashtab,editorctl_wid.p_EmbeddedCaseSensitive);
               if (j>=0) {
                  jdParseParam(hashtab:[tag][j],argName,text);
                  hitList[j]=true;
                  if (text=='') {
                     // comment not given for this exception
                     wid._lbadd_item(exception:+empty_msg);
                  } else {
                     wid._lbadd_item(exception);
                  }
               } else {
                  // exception in throws clause but not in the javadoc comment.
                  // add it to hashtab
                  wid._lbadd_item(exception:+empty_msg);
                  hashtab:[tag][hashtab:[tag]._length()]=exception;
               }
            }
         }
         for (i=0; i < count; ++i) {
            if (!hitList[i]) {
               jdParseParam(hashtab:[tag][i],argName,text);
               // We don't append an ' (obsolete)' text to the unchecked exceptions 
               // like we used to.  See #1-3DGMS.
               wid._lbadd_item(argName);
            }
         }

         int widparam=_find_control('ctlexception'CURJAVATYPE);
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

      wid=_find_control('ctlsince'CURJAVATYPE);
      if (wid) {
         tag="since";
         if (hashtab._indexin(tag)) {
            parse hashtab:[tag][0] with line "\n" ;
            wid.p_text=line;
            hashtab._deleteel(tag);
         }
      }
      wid=_find_control('ctlversion'CURJAVATYPE);
      if (wid) {
         tag="version";
         if (hashtab._indexin(tag)) {
            parse hashtab:[tag][0] with line "\n" ;
            wid.p_text=line;
            hashtab._deleteel(tag);
         }
      }
      wid=_find_control('ctlauthor'CURJAVATYPE);
      if (wid) {
         tag="author";
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
            _str authors="";
            for (i=0;i<count;++i) {
               parse hashtab:[tag][i] with line "\n" ;
               if (i==0) {
                  authors=strip(line);
               } else {
                  authors=authors:+", ":+strip(line);
               }
            }
            wid.p_text=authors;
            hashtab._deleteel(tag);
         }
      }
      wid=_find_control('ctlsee'CURJAVATYPE);
      if (wid) {
         tag="see";
         _str see_msg="";
         if (hashtab._indexin(tag)) {
            count=hashtab:[tag]._length();
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
            wid.p_undo_steps=0;
            wid._delete_line();
            wid._insert_text(hashtab:[tag][0]);
            while (wid.p_Noflines>1) {
               wid.get_line(line);
               if (line!="") break;
               wid._delete_line();
            }
            wid.p_modify=0;wid.top();
            wid.p_undo_steps=32000;
            hashtab._deleteel(tag);
         }
         wid.p_visible=true;
         wid.p_prev.p_visible=true;
      }
      wid=_find_control('ctldescription'CURJAVATYPE);
      if (wid) {
         wid.bottom();
         // add user defined tags
         boolean first_time=true;

         for (j=0;j<tagList._length();++j) {
            tag=tagList[j];
            if (hashtab._indexin(tag) && 
                !(tag=='param' && _find_control('ctlparamcombo'CURJAVATYPE)) &&
                !(tag=='exception' && _find_control('ctlexceptioncombo'CURJAVATYPE)) &&
                substr(tag,1,1)!='@') {
               count=hashtab:[tag]._length();
               if (first_time && (def_javadoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION)) {
                  wid.insert_line('');
               }
               //if (count) wid.insert_line('');
               for (i=0;i<count;++i) {
                  wid._insert_text("\n@"tag' 'hashtab:[tag][i]);
                  while (wid.p_Noflines>1) {
                     wid.get_line(line);
                     if (line!="") break;
                     wid._delete_line();
                     wid._end_line();
                  }
               }
               first_time=false;
               hashtab._deleteel(tag);
            }
         }

         /*for (tag._makeempty();;) {
            hashtab._nextel(tag);
            if (tag._isempty()) break;
            if (hashtab._indexin(tag) && tag!='param' && tag!='exception' && substr(tag,1,1)!='@') {
               count=hashtab:[tag]._length();
               if (first_time && (def_javadoc_format_flags & VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION)) {
                  wid.insert_line('');
               }
               //if (count) wid.insert_line('');
               for (i=0;i<count;++i) {
                  wid._insert_text("\n@"tag' 'hashtab:[tag][i]);
                  while (wid.p_Noflines>1) {
                     wid.get_line(line);
                     if (line!="") break;
                     wid._delete_line();
                     wid._end_line();
                  }
               }
            }
            first_time=false;
         } */
         wid.p_modify=0;wid.top();
      }

#if 0
      tag="serial";
      _str member_msg="";
      _str ddstyle="";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+"<DT><B>Serial:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            member_msg=member_msg:+"<dd>":+hashtab:[tag][i];
         }
         hashtab._deleteel(tag);
      }
      tag="serialfield";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+"<DT><B>SerialField:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            _str fieldName="";
            _str fieldType="";
            parse hashtab:[tag][i] with fieldName fieldType text;
            member_msg=member_msg:+"<dd"ddstyle">":+fieldName' 'fieldType:+" - ":+text;
         }
         hashtab._deleteel(tag);
      }
      tag="serialdata";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+"<DT><B>SerialData:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            member_msg=member_msg:+"<dd"ddstyle">":+hashtab:[tag][i];
         }
         hashtab._deleteel(tag);
      }
#endif
      HASHTAB=hashtab;

      int pic_wid=0;
      MaybeShowDeprecated();
      wid=_find_control('ctlexceptioncombo'CURJAVATYPE);
      if (wid) {
         pic_wid=_find_control('ctlsizeexc'CURJAVATYPE);
         if (wid.p_Noflines) {
            pic_wid.p_visible=true;
            _find_control('ctlexception'CURJAVATYPE).p_visible=true;
         } else {
            pic_wid.p_visible=false;
            _find_control('ctlexception'CURJAVATYPE).p_visible=false;
            //ctlexceptionlabel3
         }
      }
      //MODIFIED=init_modified;
      MODIFIED=0;
      jdShowModified();

      p_active_form.jdResizeControls();
      pic_wid=_find_control('ctlpicture'CURJAVATYPE);
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

   int flags=def_javadoc_filter_flags;
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   int x=0, y=0;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

static void MaybeShowDeprecated()
{
   int wid=_find_control('ctldeprecatedcheck'CURJAVATYPE);
   //wid.p_value=1;
   if (wid) {
      if (wid.p_value) {
         //_find_control('ctldeprecatedframe'CURJAVATYPE).p_visible=0;
         _find_control('ctldeprecated'CURJAVATYPE).p_visible=1;
      } else {
         _find_control('ctldeprecated'CURJAVATYPE).p_visible=0;
         //_find_control('ctldeprecatedframe'CURJAVATYPE).p_visible=1;
      }
   }
}
void ctldeprecatedcheck1.lbutton_up()
{
   MODIFIED=1;
   MaybeShowDeprecated();
   p_active_form.jdResizeControls();
   if (p_value) {
      p_next._set_focus();
   }
}
void _javadoc_form.on_resize(boolean doMove=false)
{
   if (doMove) return;
   jdResizeControls();
}

static int _setEditorControlMode(int wid)
{
   if (wid.p_object!=OI_EDITOR) {
      return(0);
   }
   wid._SetEditorLanguage('html');
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
   int editorctl_wid=_form_parent();
   /*
   Determine the Java type to start with


   */
   _for_each_control(p_active_form,_setEditorControlMode,'H');
   ctlsee1._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee2._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee3._SetEditorLanguage(_form_parent().p_LangId);
   ctlsee1.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee2.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlsee3.p_window_flags |=VSWFLAG_NOLCREADWRITE;
   ctlexception3._SetEditorLanguage('html');
   ctlexample3._SetEditorLanguage('html');

   _str buf_name=editorctl_wid.p_buf_name;
   if (buf_name!='') {
      p_active_form.p_caption=p_active_form.p_caption': 'buf_name;
   }
   editorctl_wid._UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   cb_prepare_expand(p_active_form,ctltree1,TREE_ROOT_INDEX);
   ctltree1._TreeBeginUpdate(TREE_ROOT_INDEX,'','T');
   tag_tree_insert_context(ctltree1,TREE_ROOT_INDEX,
                           def_javadoc_filter_flags,
                           1,1,0,0);
   ctltree1._TreeEndUpdate(TREE_ROOT_INDEX);
   ctltree1._TreeSizeColumnToContents(0);

   typeless p;
   editorctl_wid.save_pos(p);
   editorctl_wid.p_col=1;
   editorctl_wid._clex_skip_blanks();
   int EditorLN=editorctl_wid.p_RLine;
   int context_id = tag_nearest_context(EditorLN,def_javadoc_filter_flags);
   int nearIndex= -1;
   int line_num=0;
   editorctl_wid.restore_pos(p);
   if (context_id>0) {
      tag_get_detail2(VS_TAGDETAIL_context_line, context_id, line_num);
      nearIndex=ctltree1._TreeSearch(TREE_ROOT_INDEX,'','T',line_num);
   }
   if (nearIndex <= 0) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_javadoc_filter_flags= -1;
      _javadoc_refresh_proctree();
      if (ctltree1._TreeCurIndex()<=0 || CURJAVATYPE=="") {
         nearIndex= ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (nearIndex<0) {
            //p_active_form._delete_window();
            jdHideAll();
            ctltagcaption.p_caption="No symbol selected, check filtering options.";
            return;
         }
         ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
      }
      return;
   }
   if (ctltree1._TreeCurIndex()!=nearIndex) {
      ctltree1._TreeSetCurIndex(nearIndex);
   } else {
      ctltree1.call_event(CHANGE_SELECTED,nearIndex,ctltree1,ON_CHANGE,'W');
   }

}
void _javadoc_form.on_load()
{
   int wid=_find_control('ctldescription'CURJAVATYPE);
   if (wid) {
      wid._set_focus();
   }
}
void ctlok.on_destroy()
{
   if (TIMER_ID!='') {
      _kill_timer(TIMER_ID);
   }
}

int _OnUpdate_edit_doc_comment(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || !target_wid._isEditorCtl() || target_wid.p_readonly_mode) {
      return(MF_GRAYED);
   }

   int enabled=_OnUpdate_javadoc_comment(cmdui,target_wid,command);
   _str key_name="";
   _str caption="";
   int mf_flags=0;
   if (cmdui.menu_handle) {
      _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,mf_flags,'p',caption);
      parse caption with \t key_name;

      int comment_flags=0;
      _str orig_comment="";
      _str return_type="";
      _str line_prefix="";
      _str doxygen_comment_start="";
      int blanks:[][];
      int status=target_wid._GetCurrentCommentInfo(comment_flags,orig_comment,return_type,line_prefix,blanks,
         doxygen_comment_start);
      if (comment_flags==0) {
         if (line_prefix=="" && doxygen_comment_start=="" && _is_xmldoc_preferred()) {
            comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
         }
      } else if (line_prefix == "///" && _is_xmldoc_supported()) {
         comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
      }
      if (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC) {
         _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,mf_flags,'p',"Edit XML Comment\t"key_name);
         return(enabled);
      }
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,mf_flags,'p',"Edit Javadoc Comment\t"key_name);
   }
   return(enabled);
}

// Detects comment editor from comments
_command void edit_doc_comment() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   int comment_flags=0;
   _str orig_comment="";
   _str return_type="";
   _str line_prefix="";
   _str doxygen_comment_start="";
   int blanks:[][];
   int status=_GetCurrentCommentInfo(comment_flags,orig_comment,return_type,line_prefix,blanks,doxygen_comment_start);
   if (comment_flags==0) {
      if (line_prefix=="" && doxygen_comment_start=="" && _is_xmldoc_preferred()) {
         comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
      }
   } else if (line_prefix == "///" && _is_xmldoc_supported()) {
      comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
   }
   if (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC) {
      xmldoc_editor();
      return;
   }
   javadoc_editor();
}

int _OnUpdate_javadoc_editor(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_javadoc_comment(cmdui,target_wid,command);
}

_command void javadoc_editor(_str deprecate='') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (p_active_form.p_name == '_javadoc_form' || p_active_form.p_name=='_xmldoc_form') {
      return;
   }
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if (get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || !javadocSupported) {
      _message_box('JavaDoc comment not supported for this file type');
      return;
   }
   show('-xy -modal _javadoc_form');
}

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
defeventtab _javadoc_preview_form;
void _javadoc_preview_form.on_create(_str htmltext,boolean isxmldoc=false)
{
   if (isxmldoc) {
      p_active_form.p_caption="XMLDOC Preview";
   }
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

defeventtab _javadoc_format_form;
void ctlok.on_create()
{
   ctlbeautify.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BEAUTIFY;
   ctlparammin.p_text=def_javadoc_parammin;
   ctlparammax.p_text=def_javadoc_parammax;
   ctlexceptionmin.p_text=def_javadoc_exceptionmin;
   ctlexceptionmax.p_text=def_javadoc_exceptionmax;
   ctlparamalign.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_ALIGN_PARAMETERS;
   ctlexceptionalign.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
   ctlreturnalign.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_ALIGN_RETURN;
   ctldeprecatedalign.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_ALIGN_DEPRECATED;
   ctlparamblank.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   ctlparamgroupblank.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   ctlreturnblank.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   ctlexampleblank.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   ctldescriptionblank.p_value=def_javadoc_format_flags&VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;

   ctlbeautify.call_event(ctlbeautify,LBUTTON_UP,'W');
   ctlparamalign.call_event(ctlparamalign,LBUTTON_UP,'W');
   ctlexceptionalign.call_event(ctlexceptionalign,LBUTTON_UP,'W');
}
static int _disableAll(int wid)
{
   wid.p_enabled=ctlbeautify.p_value!=0;
   return(0);
}
void ctlparamalign.lbutton_up()
{
   p_next.p_enabled=p_next.p_next.p_enabled=p_value!=0;
   int wid=p_next.p_next.p_next;
   wid.p_next.p_enabled=wid.p_next.p_next.p_enabled=p_value!=0;
}

void ctlok.lbutton_up()
{
   int old_def_javadoc_parammin=def_javadoc_parammin;
   int old_def_javadoc_parammax=def_javadoc_parammax;
   int old_def_javadoc_exceptionmin=def_javadoc_exceptionmin;
   int old_def_javadoc_exceptionmax=def_javadoc_exceptionmax;
   int old_def_javadoc_format_flags=def_javadoc_format_flags;

   _macro('m',_macro('s'));
   if(!isinteger(ctlparammin.p_text)) {
      ctlparammin._text_box_error("Invalid integer");
      return;
   }
   if(!isinteger(ctlparammax.p_text)) {
      ctlparammax._text_box_error("Invalid integer");
      return;
   }
   if (ctlparammin.p_text>ctlparammax.p_text) {
      ctlparammin._text_box_error("Minimum must be less or equal to maximum");
      return;
   }
   if(!isinteger(ctlexceptionmin.p_text)) {
      ctlexceptionmin._text_box_error("Invalid integer");
      return;
   }
   if(!isinteger(ctlexceptionmax.p_text)) {
      ctlexceptionmax._text_box_error("Invalid integer");
      return;
   }
   if (ctlexceptionmin.p_text>ctlexceptionmax.p_text) {
      ctlexceptionmin._text_box_error("Minimum must be less or equal to maximum");
      return;
   }
   if(ctlbeautify.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BEAUTIFY;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BEAUTIFY;
   }
   def_javadoc_parammin=(int)ctlparammin.p_text;
   def_javadoc_parammax=(int)ctlparammax.p_text;
   def_javadoc_exceptionmin=(int)ctlexceptionmin.p_text;
   def_javadoc_exceptionmax=(int)ctlexceptionmax.p_text;

   if(ctlparamalign.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_ALIGN_PARAMETERS;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_ALIGN_PARAMETERS;
   }
   if(ctlexceptionalign.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_ALIGN_EXCEPTIONS;
   }
   if(ctlreturnalign.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_ALIGN_RETURN;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_ALIGN_RETURN;
   }
   if(ctldeprecatedalign.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_ALIGN_DEPRECATED;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_ALIGN_DEPRECATED;
   }
   if(ctlparamblank.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS;
   }
   if(ctlparamgroupblank.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM;
   }
   if(ctlreturnblank.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN;
   }
   if(ctlexampleblank.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE;
   }
   if(ctldescriptionblank.p_value) {
      def_javadoc_format_flags|=VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;
   } else {
      def_javadoc_format_flags&= ~VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION;
   }

   if(old_def_javadoc_parammin!=def_javadoc_parammin) {
      _macro_append("def_javadoc_parammin="def_javadoc_parammin";");
   }
   if(old_def_javadoc_parammax!=def_javadoc_parammax) {
      _macro_append("def_javadoc_parammax="def_javadoc_parammax";");
   }
   if(old_def_javadoc_exceptionmin!=def_javadoc_exceptionmin) {
      _macro_append("def_javadoc_exceptionmin="def_javadoc_exceptionmin";");
   }
   if(old_def_javadoc_exceptionmax!=def_javadoc_exceptionmax) {
      _macro_append("def_javadoc_exceptionmax="def_javadoc_exceptionmax";");
   }
   if(old_def_javadoc_format_flags!=def_javadoc_format_flags) {
      _macro_append("def_javadoc_format_flags="def_javadoc_format_flags";");
   }

   p_active_form._delete_window();
}

/**
 * Reflows the current Javadoc style comment using reflow
 * paragraph.
 */
_command void javadoc_reflow() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   // make sure this is a javaDoc comment
   int start_col = _inJavadoc();
   if (!start_col) {
      message('Not in a Javadoc comment.');
      return;
   }

   // find the beginning and end of the comment
   int first_line,last_line,orig_line=p_line;

   _str orig_line_data='';
   get_line(orig_line_data);
   boolean started_at_top_of_comment=orig_line_data=='/**';
   boolean started_at_bottom_of_comment=orig_line_data=='*/';

   _clex_find_start(); first_line = p_line;
   _clex_find_end();   last_line  = p_line;

   // now tune the first line, looking for a paragraph break
   //p_line = first_line;
   p_line = orig_line;
   while (p_line >= first_line) {
      get_line(auto temp_first_line);
      parse temp_first_line with "*" temp_first_line;
      temp_first_line = lowcase(strip(temp_first_line));
      if (temp_first_line=='' || temp_first_line=='*') {
         first_line=p_line+1;
         break;
      }
      if (pos('^<(p|/p|/pre|/ul|/ol|/dl|li|dt|dd|/blockquote)[ >]',temp_first_line,1,'r') || substr(temp_first_line,1,1)=='@') {
         first_line=p_line;
         break;
      }
      up();
   }

   // now tune the last line, looking for a paragraph break
   //p_line = first_line;
   _str line="";
   p_line = orig_line;
   while (p_line <= last_line) {
      get_line(line);
      parse line with "*" line;
      line = lowcase(strip(line));
      if (line=='' || line=='/' || line=='*/') {
         last_line=p_line-1;
         break;
      }
      if (pos('^<(p|/p|pre|ul|ol|dl|li|dt|dd|blockquote)[ >]',line,1,'r') || substr(line,1,1)=='@') {
         last_line=p_line;
         break;
      }
      down();
   }

   // Delete the leading '*'
   p_line=first_line;
   while (p_line <= last_line) {
      p_col = start_col;
      if (get_text()=='*') {
         delete_char();
      }
      down();
   }

   // insert fake blank lines to keep format paragraph in check
   p_line = last_line;
   insert_line('');
   p_line = first_line-1;
   insert_line('');
   p_line = orig_line+1;

   // Want to be sure that we are touching the text when we call reflow_fundamental
   // In border cases, setting p_line to orig_line will not work, so we need these
   // tweaks
   if ( started_at_top_of_comment ) {
      down();
   }else if (started_at_bottom_of_comment) {
      up();
   }

   // adjust the margins for the start column
   _str orig_margins=p_margins;
   typeless leftmargin="";
   typeless rightmargin="";
   _str rest="";
   parse p_margins with leftmargin rightmargin rest;
   p_margins=leftmargin' '(rightmargin-start_col-1)' 'rest;

   // now reflow the paragraph and find out how many lines
   // were added or removed.
   int orig_num_lines=p_Noflines;
   reflow_fundamental();
   int delta_lines=p_Noflines - orig_num_lines;
   last_line += delta_lines;
   p_margins=orig_margins;

   // delete the first blank line
   p_line = first_line;
   get_line(line);
   if (line=='') {
      _delete_line();
   }

   // now put the *'s back in
   while (p_line <= last_line) {
      get_line(line);
      replace_line(indent_string(start_col-1)'* ':+strip(line));
      down();
   }

   // finally, delete the last blank line
   get_line(line);
   if (line=='') {
      _delete_line();
   }
   p_line=orig_line;
}
