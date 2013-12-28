////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44145 $
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
#include "listbox.sh"
#import "dlgman.e"
#import "listbox.e"
#import "main.e"
#import "stdprocs.e"
#endregion

typeless gmycopy;

/* These are just for testing purposes */
static typeless temparray[]={
   'This is a string',
   {0,1,2,3},
   {'a'=>'aa','b'=>'bb','c'=>'cc','d'=>{'a'=>'aa','b'=>'bb','c'=>'cc'}}
   };
//typeless temphash:[];

typeless temphash:[]={
      'xx'=>'this is a string',
      'yy'=>{0,1,2,3},
      'zz'=>{'a'=>'aa','b'=>'bb','c'=>'cc','d'=>{'a'=>'aa','b'=>'bb','c'=>'cc','d'=>{0,1,2,3}}}
   };

#define VAREDITSV_SAFE_EXIT 0x1

int def_sv_flags=0;

#define VAREDITSV_ELEMENT 1
#define VAREDITSV_ARRAY 2
#define VAREDITSV_HASHTAB 3
#define VAREDITSV_NOTINIT 4

/*
   _ctlsv_ok.p_user      Name of variable.

   _ctlsv_list.p_user    Pointer to variable.

   p_active_form.p_user  Pointer to copy.

   _ctlsv_value.p_user   Used as semaphore. If non-zero, don't set value text
                         box when there is on_change event for the list box.

   _ctlsv_cancel.p_user  Used as modify flag.

   _ctlsv_insert.p_user  Keeps track of the col width used for the list box.
                         I know this doesn't make any sense, but I'm the list
                         box p_user is taken already, and I just don't feel
                         like switching it.
*/

defeventtab _var_editor_form;
void _var_editor_form.on_load()
{
   _ctlsv_list._set_focus();
}

static void maybe_change_colwidth(typeless str)
{
   int width=_text_width(strip_value(str));
   if (width+100>_ctlsv_insert.p_user) {//Dan added +100 "fudge" 11:02pm 1/30/1996
      // 257 =  left margin + 9*twips_per_pixel + indent(50)
      _ctlsv_insert.p_user=width+257;
      _col_width(0,_ctlsv_insert.p_user);
   }
}

static void mylbadd_item(_str str, typeless indent="", typeless pic="")
{
   _lbadd_item(str,indent,pic);
   maybe_change_colwidth(str);
}

static void mylbset_item(_str str, typeless indent="", typeless pic="")
{
   _lbset_item(str,indent,pic);
   maybe_change_colwidth(str);
}

void _ctlsv_list.on_create(/*_str var_name,typeless *var_p*/)
{
   if (arg()<2) {
      _message_box(nls("_var_editor_form:More arguments required."));
      p_active_form._delete_window();
      return;
   }
   if (!arg(2)) {
      _message_box(nls("Null pointer"));
      return;
   }
   _ctlsv_ok.p_user=arg(1);            //Name of variable
   _ctlsv_list.p_user=arg(2);    //Pointer to variable
   gmycopy=*(arg(2));            //copy of value of variable
   p_active_form.p_user=&gmycopy;//pointer to copy
   p_active_form.p_caption='Variable Editor - '_ctlsv_ok.p_user;
   _ctlsv_insert.p_user=2000;//Width of first column in list box.
   svinit_list(p_active_form.p_user);
   _ctlsv_value.p_enabled=0;
   _ctlsv_value.p_user=0;//Used as semaphore.  See comment as top.
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
   _ctlsv_cancel.p_user=0;
}

void _ctlsv_value.on_change()
{
   if (_ctlsv_value.p_user) return;
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _ctlsv_cancel.p_user=1;
   _lbdeselect_all();
   typeless *ptr=get_ptr_from_sublist(p_active_form.p_user,strip_value(_lbget_text()));
   int format=ptr->_varformat();
   if (format==VF_INT||format==VF_LSTR||format==VF_WID||format==VF_INT64) *ptr=_ctlsv_value.p_text;
   _str line="";
   int indent=0, pic=0;
   _lbget_item(line,indent,pic);
   line=substr(line,1,pos("\t",line)-1);
   mylbset_item(line"\t"_ctlsv_value.p_text,indent,pic);
   _lbselect_line();
   p_window_id=wid;
}

_ctlsv_ok.lbutton_up()
{
   typeless pmycopy=p_active_form.p_user;
   typeless porigvar=_ctlsv_list.p_user;
   *porigvar=*pmycopy;//Set original variable to the value of the copy
   if (arg()==0) {
      p_active_form._delete_window(0);
   }
}

_ctlsv_cancel.lbutton_up()
{
   if (def_sv_flags&VAREDITSV_SAFE_EXIT) {
      if (_ctlsv_cancel.p_user) {
         typeless result=_message_box(nls("Variable has been modified.\n\nExit anyway?"),
                             '',
                             MB_YESNO|MB_ICONQUESTION);
         if (result!=IDYES) {
            return('');
         }
         p_active_form._delete_window(0);
      }else{
         p_active_form._delete_window(0);
      }
   }else{
      p_active_form._delete_window(0);
   }
}

/*This would have fit int the svinit_list function, but I just took it out to
save a little space*/
static void svinit_list_font()
{
   typeless font_name="", font_size="", font_flags="";
   parse (_dbcs()?def_qt_jsellist_font:def_qt_sellist_font) with font_name',' font_size','font_flags . ;
   if (font_name!='') p_font_name=font_name;
   if (font_size!='') p_font_size=font_size;
   if (!isinteger(font_flags)) font_flags=0;
   p_font_bold=font_flags&F_BOLD;
   p_font_italic=font_flags&F_ITALIC;
   p_font_strike_thru=font_flags&F_STRIKE_THRU;
   p_font_underline=font_flags&F_UNDERLINE;
}

void _ctlsv_update.lbutton_up()
{
   _ctlsv_ok.call_event('1',_ctlsv_ok,LBUTTON_UP,'');
}

void _ctlsv_refresh.lbutton_up()
{
   p_window_id=_ctlsv_list;
   _lbclear();
   expand_var2(_ctlsv_list.p_user,'');
   gmycopy=*(_ctlsv_list.p_user);
   p_active_form.p_user=&gmycopy;
}

/*
1) Dumps the unexpanded version of the variable into the list.
2) Sets the font in the listX box up the same as a _sellist_form
I used a separate function from the one that expands a variable because this one
uses _varnextel, and it just works a little different.
*/
static void svinit_list(typeless *var_p)
{
   svinit_list_font();
   typeless i;
   i._makeempty();
   p_picture=_pic_lbplus;
   //Dan took this out to see if it made a difference 10:37pm 1/30/1996
#if 0
   _str ch="";
   int root_format=var_p->_varformat();
   switch (root_format) {
   case VF_HASHTAB:
      ch=':';
      break;
   case VF_ARRAY:
      ch='';
      break;
   }
#endif
   expand_var2(p_active_form.p_user,'');
   _lbtop();
   _lbselect_line();
}

/* (topptr) is a pointer to the array/hashtab itself.  (cur_line_list) is a
   subscript list.  Returns a pointer to the variable represented by
   (cur_line_list).  (isptr) is set to 1 if the return value is a pointer.
   If the return value is pointer to a pointer, it will be dereferenced (once) */
static typeless *get_ptr_from_sublist(typeless topptr,
                                      typeless cur_line_list,
                                      .../*,var isptr*/)
{
   arg(3)=0;
   typeless tline=cur_line_list;
   typeless ptr=topptr;
   typeless sub="";
   typeless last="";
   for (;;) {
      parse tline with '[' sub ']' tline;
      if (sub=='') break;
      while (ptr->_varformat()==VF_PTR) {
         //Probably insane
         arg(3)=1;
         last=ptr;
         ptr=*ptr;
      }
      ptr=&ptr->_el(sub);
      while (ptr->_varformat()==VF_PTR) {
         //Probably insane
         arg(3)=1;
         ptr=*ptr;
      }
   }
   return(ptr);
}

static _str strip_value(_str line)
{
   int p=pos("\t",line);
   if (p) {
      return(substr(line,1,p-1));
   }
   return(line);
}

static _str strip_subscripts(_str line)
{
   int p=pos("\t",line);
   if (p) {
      return(substr(line,p+1));
   }
   //return line;
   return('');
}

/* This is the "meat" of expand_var.  Its actually called directly once, from
svinit_list  Fills in the list box */
static void expand_var2(typeless *ptr, typeless subscriptlist)
{
   typeless i;
   i._makeempty();
   _str ch='';
   _str new_prefix_ch="";
   int format=0;
   typeless tptr="";
   {//Dan added to fix problem with colons 10:39pm 1/30/1996
      new_prefix_ch='';
      format=ptr->_varformat();
      if (format==VF_HASHTAB && !p_Noflines) {
         new_prefix_ch=':';
      }
   }
   for (;;) {
      format=ptr->_varformat();
      switch (format) {
      case VF_PTR:
         tptr=&(*ptr)->_nextel(i);
         break;
      case VF_ARRAY:
      case VF_HASHTAB:
      case VF_OBJECT:
         tptr=& ptr->_nextel(i);
         break;
      }
      if (i._varformat()==VF_EMPTY) break;
      _str subscript_i = '['i']';
      if (format==VF_OBJECT) {
         //subscript_i = '.'ptr->_fieldname(i);
      }
      format=tptr->_varformat();
      switch (format) {
      case VF_ARRAY:
         mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i,50,_pic_lbplus);
         break;
      case VF_HASHTAB:
         ch=(substr(subscriptlist,1,1)!=':')?':':'';
         mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i':',50,_pic_lbplus);
         break;
      case VF_OBJECT:
         mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i,50,_pic_lbplus);
         break;
      case VF_EMPTY:
         /*I will still put in the \t, just in case there are any lazy portions
           of the macro that assume it's just there*/
         mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i"\t",50);
         break;
      case VF_LSTR:
      case VF_INT:
      case VF_WID:
      case VF_INT64:
         format=ptr->_varformat();
         switch (format) {
         case VF_ARRAY:
            ch='';break;
         case VF_HASHTAB:
            //ch=':';
            break;
         }
         mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i"\t"(*tptr),50);
         break;
      case VF_PTR:
         typeless dref_ptr=*(*tptr);
         format=dref_ptr._varformat();
         switch (format) {
         case VF_ARRAY:
         case VF_HASHTAB:
            mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i,50,_pic_lbplus);
            break;
         case VF_INT:
         case VF_WID:
         case VF_INT64:
         case VF_LSTR:
            mylbadd_item(new_prefix_ch:+subscriptlist:+subscript_i"\t"(dref_ptr),50);
            break;
         }
         break;
      }
   }
}

/* Expands a variable using its (subscriptlist)*/
static void expand_var(typeless subscriptlist)
{
   typeless p;
   _ctlsv_list.save_pos(p);
   typeless *ptr=get_ptr_from_sublist(p_active_form.p_user,subscriptlist);
   expand_var2(ptr,subscriptlist);
   _ctlsv_list.restore_pos(p);
}

//returns the nth subscript in the list
static int get_sub_from_list(typeless list,int n)
{
   typeless sub="";
   int count=0;
   for (;;) {
      parse list with '[' sub ']' list;
      if (sub=='') break;
      ++count;
      if (count==n) return sub;
   }
   return(count);
}

//replaces the (n)th sub in the current line of the list with (newsub)
static _str change_sub_in_list(int n,typeless newsub)
{
   typeless p=0;
   _str str='';
   _str list="";
   _str ch="";
   typeless sub="";
   int indent=0, pic=0;
   _ctlsv_list._lbget_item(list,indent,pic);
   int i;
   for (i=1;i<n;++i) {
      parse list with ch '[' sub ']' list;
      str=str:+(ch'['sub']');
   }
   if (substr(list,1,1)==':') {//I don't think that this can ever be true
      str=str':';list=substr(list,2);
   }
   //At this point, '[' shoud be the first character in list.
   p=pos(']',list,2);
   str=str'['newsub']':+(substr(list,p+1));
   mylbset_item(str,indent,pic);
   return(str);
}

//Returns the number of subscripts in the list
static int num_subs(typeless sublist)
{
   typeless sub="";
   int count=0;
   for (;;) {
      parse sublist with '[' sub ']' sublist;
      if (sub=='') break;
      ++count;
   }
   return(count);
}

// returns 1 if (sublist2) is a child of sublist1
static int subscripts_child(typeless sublist1, typeless sublist2)
{
   sublist2=strip_value(sublist2);
   //If sublist1==sublist2, then we return 0 becuase we are on original line
   if (sublist1==sublist2) return 0;
   //If there are fewer subs in sublist1 than in sublist2, we can delete it
   if (num_subs(sublist1)<num_subs(sublist2)) return 1;
   typeless list1=sublist1;
   typeless list2=sublist2;
   typeless cursub1="";
   typeless cursub2="";
   //Compare sub to sub to see if they match
   for (;;) {
      parse list1 with '[' cursub1 ']' list1;
      if (cursub1=='') break;
      parse list2 with '[' cursub2 ']' list2;
      if (cursub2=='') break;
      if (cursub1!=cursub2) return 0;
   }
   return(1);
}

/* Collapses the variable at the current line */
static void collapse_var()
{
   typeless p;
   _ctlsv_list.save_pos(p);
   int oldwid=p_window_id;p_window_id=_ctlsv_list;
   _str subscriptlist="";
   int indent=0, pic=0;
   _lbget_item(subscriptlist,indent,pic);
   if (pic!=_pic_lbplus) return;/*This is backwards because the enter event
                                  changed it already.*/
   _lbdown();//Move down from line to be collapsed
   for (;;) {
      _str cursubscript="";
      _lbget_item(cursubscript,indent,pic);
      if (subscripts_child(subscriptlist,cursubscript)) {
         _lbdelete_item();
      }else break;
   }
   _ctlsv_list.restore_pos(p);
   p_window_id=oldwid;
}

/*When the user presses enter or double clicks, check to see if there is a
bitmap on the line.  If there is, expand or collapse accordingly.*/
_ctlsv_list.lbutton_double_click,ENTER()
{
   _lbdeselect_line();
   _str text="";
   int indent=0, pic=0;
   _lbget_item(text,indent,pic);
   if (pic==_pic_lbplus) {
      mylbset_item(text,indent,_pic_lbminus);
      expand_var(text);
   }else if (pic==_pic_lbminus) {
      mylbset_item(text,indent,_pic_lbplus);
      collapse_var();
   }
   _lbselect_line();
}

/* Fills in the value textbox, and sets its enabled property properly.  Also
   makes not initalized message visible if necessary.*/
void _ctlsv_list.on_change(int reason)
{
   switch (reason) {
   case CHANGE_SELECTED:
   case CHANGE_CLINE:
      typeless isptr='';
      _str text="";
      typeless sublist="";
      typeless pic=0;
      _lbget_item(text,sublist,pic);
      typeless value=strip_subscripts(text);
      sublist=strip_value(text);
      typeless *ptr=get_ptr_from_sublist(p_active_form.p_user,sublist,isptr);
      _ctlsv_value_label.p_enabled=_ctlsv_value.p_enabled=(pic=='');
      if (pic!='') {
         _ctlsv_ptr_deref_message.p_visible=isptr;
         _ctlsv_notinit_message.p_visible=0;
         _ctlsv_value.p_user=1;
         _ctlsv_value.p_text='';
         _ctlsv_value.p_user=0;
      }else{
         _ctlsv_value.p_user=1;
         _ctlsv_value.p_text=value;
         _ctlsv_value.p_user=0;
      }
      switch (ptr->_varformat()) {
      case VF_EMPTY:
         _ctlsv_notinit_message.p_visible=1;
         _ctlsv_value.p_enabled=_ctlsv_value_label.p_enabled=0;
         _ctlsv_ptr_deref_message.p_visible=0;
         break;
      default:
         if (ptr->_varformat()==VF_ARRAY||ptr->_varformat()==VF_HASHTAB||ptr->_varformat()==VF_OBJECT) {
            _ctlsv_value.p_enabled=_ctlsv_value_label.p_enabled=0;
         }else{
            _ctlsv_value.p_enabled=_ctlsv_value_label.p_enabled=1;
         }
         _ctlsv_notinit_message.p_visible=0;
         _ctlsv_ptr_deref_message.p_visible=isptr;
         break;
      }
      break;
   }
}

void _ctlsv_collapse_all.lbutton_up()
{
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _lbdeselect_all();
   _str orig_line_text=_lbget_text();
   _lbtop();_lbup();
   _str text="";
   int indent=0, pic=0;
   while (!_lbdown()) {
      _lbget_item(text,indent,pic);
      if (pic==_pic_lbminus) {
         call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, LBUTTON_DOUBLE_CLICK,'E');
      }
   }
   typeless status=_lbsearch(orig_line_text);
   /*If the original line is no longer there(because it was collapsed, do a
   a more sophisticated search to try to position current line at the last
   parent */
   if (status) {
      _str sublist=strip_value(orig_line_text);
      boolean found=0;
      for (;;) {
         _lbtop();_lbup();
         status=_lbsearch(sublist);
         if (!status) {
            found=1;
            break;
         }
         int lp=lastpos("[",sublist);
         if (lp) sublist=substr(sublist,1,lp-1);
         if (sublist=='') break;
      }
      if (!found) {
         _lbtop();
      }
   }
   _lbselect_line();
   _ctlsv_list._set_focus();
   p_window_id=wid;
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
}

void _ctlsv_expand_cur.lbutton_up()
{
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _str text="";
   int indent=0, pic=0;
   _lbget_item(text,indent,pic);
   if (pic!=_pic_lbplus) return;
   save_pos(auto p);
   _lbdown();
   _str orig_line=_lbget_text();
   _lbup();_lbup();
   while (!_lbdown()) {
      _lbget_item(text,indent,pic);
      if (text==orig_line) break;
      if (pic==_pic_lbplus) {
         call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, LBUTTON_DOUBLE_CLICK,'E');
      }
   }
   restore_pos(p);
   _lbselect_line();
   _ctlsv_list._set_focus();
   p_window_id=wid;
}

void _ctlsv_expand_all.lbutton_up()
{
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _lbdeselect_all();
   _str orig_line_text=_lbget_text();
   _lbtop();_lbup();
   _str text="";
   int indent=0, pic=0;
   while (!_lbdown()) {
      _lbget_item(text,indent,pic);
      if (pic==_pic_lbplus) {
         call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, LBUTTON_DOUBLE_CLICK,'E');
      }
   }
   _lbtop();
   _lbsearch(orig_line_text);
   _lbselect_line();
   _ctlsv_list._set_focus();
   p_window_id=wid;
}

// Basically just strips off the last element and returns the string
static _str element_prefix(typeless subscriptlist)
{
   _str prefix="";
   int lp=lastpos('[',subscriptlist);
   if (lp>1) {
      prefix=substr(subscriptlist,1,lp-1);
   }else{
      prefix='';
   }
   return(prefix);
}

/* Shift the appropriate subscript of the necessary elements(after a delete).
   The deleted element is already removed from the list, and (subscriptlist)
   is its subscript list.*/
static void shift_elements_down(typeless subscriptlist)
{
   _str prefix=element_prefix(subscriptlist);
   typeless subtochange=num_subs(prefix)+1;
   for (;;) {
      typeless extralist=strip_value(_lbget_text());
      typeless curprefix=element_prefix(extralist);
      if (curprefix!=prefix) break;
      typeless cursubscriptlist=strip_value(_lbget_text());
      typeless oldsub=get_sub_from_list(cursubscriptlist,subtochange);
      typeless newline=change_sub_in_list(subtochange,oldsub-1);
      typeless newsublist=strip_value(newline);
      typeless oldptr=get_ptr_from_sublist(p_active_form.p_user,cursubscriptlist);
      typeless newptr=get_ptr_from_sublist(p_active_form.p_user,newsublist);
      if (_lbdown()) break;
   }
}

//void _var_editor_form.DEL()
void _ctlsv_list.DEL()
{
   _ctlsv_delete.call_event(_ctlsv_delete,LBUTTON_UP);
}

void _ctlsv_delete.lbutton_up()
{
   _ctlsv_cancel.p_user=1;
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _lbdeselect_all();
   _str text="";
   int indent=0, pic=0;
   _lbget_item(text,indent,pic);
   typeless subscriptlist=strip_value(text);
   _set_focus();
   typeless old_position;
   save_pos(old_position); //Dan added to keep position right 11:08pm 1/30/1996
   boolean shift=!_lbdelete_item();//Delete the line that we're on
   if (shift) _lbup();
   while (!_lbdown()) {    //Delete all the children
      typeless cursubscriptlist=strip_value(_lbget_text());
      if (subscripts_child(subscriptlist,cursubscriptlist)) {
         _lbdelete_item();
         _lbup();
      }else {
         break;
      }
   }
   typeless *ptr=get_parent_ptr_from_sublist(p_active_form.p_user,subscriptlist);
   boolean isarray=(ptr->_varformat()==VF_ARRAY);
   if (isarray&&shift) {
      ptr->_deleteel(get_last_sub(subscriptlist));
      shift_elements_down(subscriptlist);
   }else{
      ptr=get_ptr_from_sublist(p_active_form.p_user,subscriptlist);
      ptr->_makeempty();
   }
   restore_pos(old_position);//Dan added to keep position right 11:08pm 1/30/1996
   _lbselect_line();
   p_window_id=wid;
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
}

static void smush(typeless *ptr)
{
   //This does not work for my current test case 11:32pm 1/30/1996
   typeless i;
   i._makeempty();
   for (;;) {
      int last=(i._varformat()==VF_EMPTY)?-1:i;
      typeless temp=&ptr->_nextel(i);
      if (i._varformat()==VF_EMPTY) break;
      if (ptr->_varformat()==VF_ARRAY) {
         if (last+1!=i) {
            int start=last+1;
            int total=i-last-1;
            ptr->_deleteel(start);
            ptr->_deleteel(start,total);
            i=start;
         }
      }
      if (temp->_varformat()==VF_ARRAY) {
         smush(temp);
      }
   }
}

void _ctlsv_compact.lbutton_up()
{
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _lbdeselect_all();
   smush(p_active_form.p_user);
   _lbclear();
   expand_var2(p_active_form.p_user,'');
   _lbtop();
   _lbselect_line();
   _ctlsv_cancel.p_user=1;
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
   p_window_id=wid;
}

static typeless *get_parent_ptr_from_sublist(typeless topptr,
                                             typeless orig_line_list,
                                             ...)
{
/*If we insert at a normal line, or a line that is an unexpanded
  structure, the parent of the new line is the parent of the line that
  is already there.  If we insert on a line that is an expanded
  structure, that line is the parent.
*/
   save_pos(auto p);
   _str text="";
   int indent=0, pic=0;
   _lbget_item(text,indent,pic);
   if (text=='') {
      arg(3)=1;
      return(p_active_form.p_user);
   }
   if (pic==_pic_lbminus) {
      arg(3)=p_line;
      restore_pos(p);
      typeless *rv=get_ptr_from_sublist(p_active_form.p_user,orig_line_list,arg(4));
      return(rv);
   }
   typeless num=num_subs(orig_line_list);
   //If there is only one subscript, parent has to pointer to var itself
   if (num==1) {
      arg(3)=0;
      restore_pos(p);
      typeless *rv=p_active_form.p_user;
      arg(4)=rv->_varformat()==VF_PTR;
      return(rv);
   }
   while (!_lbup()) {
      typeless cursublist=strip_value(_lbget_text());
      typeless curnum=num_subs(cursublist);
      if (curnum<num) {
         arg(3)=p_line;
         restore_pos(p);
         typeless *rv=get_ptr_from_sublist(p_active_form.p_user,cursublist,arg(4));
         return(rv);
      }
   }
   typeless junk;
   return(&junk);
}

int _isnot_valid_subscript(typeless subscript, int format)
{
   switch (format) {
   case VF_ARRAY:
      if (!isinteger(subscript)||subscript<0) {
         _message_box(nls("Arrays must be subscripted by positive integers."));
         return(1);
      }
   }
   return(0);
}

//Returns the last subscript in sublist
static _str get_last_sub(typeless sublist)
{
   int lp=lastpos('[',sublist);
   if (lp) {
      sublist=substr(sublist,lp+1);
      lp=pos(']',sublist);
      _str sub=substr(sublist,1,lp-1);
      return(sub);
   }
   return('');
}

static void add_el_or_structure(typeless parent_sublist,
                                int child_format,
                                typeless new_subscript)
{
   _str new_sublist="";
   switch (child_format) {
   case VAREDITSV_ELEMENT:
      new_sublist=parent_sublist'['new_subscript"]\t";
      mylbadd_item(new_sublist,50);
      break;
   case VAREDITSV_HASHTAB:
   case VAREDITSV_ARRAY:
      new_sublist=parent_sublist'['new_subscript']';
      mylbadd_item(new_sublist,50,_pic_lbplus);
      break;
   }
}

void _var_editor_form.on_resize()
{
   int wid=p_window_id;
   int border_width=p_active_form.p_width-_dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   int border_height=p_active_form.p_height-_dy2ly(p_xyscale_mode,p_active_form.p_client_height);
   if (p_active_form.p_width<_ctlsv_format.p_x+_ctlsv_format.p_width+border_width+_ctlsv_ok.p_x) {
      //p_active_form.p_width=_ctlsv_format.p_x+_ctlsv_format.p_width+border_width+_ctlsv_ok.p_x;
   }

   _ctlsv_ok.p_visible=_ctlsv_expand_all.p_visible=_ctlsv_collapse_all.p_visible=_ctlsv_update.p_visible=_ctlsv_refresh.p_visible=_ctlsv_compact.p_visible=0;

   _ctlsv_list.p_width=p_active_form.p_width-(_ctlsv_list.p_x+(border_width*2));
   int button_buffer=_ctlsv_insert.p_y-(_ctlsv_ok.p_y+_ctlsv_ok.p_height);
   _ctlsv_insert.p_y=p_active_form.p_height-_ctlsv_insert.p_height-border_height-button_buffer;
   _ctlsv_expand_all.p_y=_ctlsv_collapse_all.p_y=_ctlsv_update.p_y=_ctlsv_refresh.p_y=_ctlsv_compact.p_y=_ctlsv_insert.p_y;
   _ctlsv_ok.p_y=_ctlsv_insert.p_y-_ctlsv_insert.p_height-button_buffer;
   _ctlsv_cancel.p_y=_ctlsv_help.p_y=_ctlsv_expand_cur.p_y=_ctlsv_delete.p_y=_ctlsv_format.p_y=_ctlsv_ok.p_y;
   _ctlsv_ptr_deref_message.p_y=_ctlsv_ok.p_y-_ctlsv_ptr_deref_message.p_height;
   _ctlsv_notinit_message.p_y=_ctlsv_ptr_deref_message.p_y-_ctlsv_notinit_message.p_height;
   _ctlsv_value_label.p_y=_ctlsv_ptr_deref_message.p_y-_ctlsv_value_label.p_height-300;
   _ctlsv_value.p_y=_ctlsv_value_label.p_y;
   _ctlsv_list.p_height=_ctlsv_value.p_y-_ctlsv_list.p_y-100;

   _ctlsv_ok.p_visible=_ctlsv_expand_all.p_visible=_ctlsv_collapse_all.p_visible=_ctlsv_update.p_visible=_ctlsv_refresh.p_visible=_ctlsv_compact.p_visible=1;
#if 1
   if (_ctlsv_list.p_width>_ctlsv_insert.p_user) {
      _ctlsv_list._col_width(0,_ctlsv_insert.p_user/*width*/);
   }else{
      _ctlsv_list._col_width(0,_ctlsv_list.p_width-800/*width*/);
   }
#endif
   int width=_ctlsv_list._col_width(0);
   _ctlsv_list._col_width(-1,0);
   p_window_id=wid;
}

void _var_editor_form.INS()
{
   _ctlsv_insert.call_event(_ctlsv_insert,LBUTTON_UP);
}

void _ctlsv_insert.lbutton_up()
{
   typeless result=show('-modal _setvar_insert_form');
   if (result=='') return;
   _ctlsv_cancel.p_user=1;
   typeless temp=0;
   typeless child_format=result;
   switch (child_format) {
   case VAREDITSV_ARRAY:
      temp[0]._makeempty();
      break;
   case VAREDITSV_HASHTAB:
      temp:['0']._makeempty();
      break;
   case VAREDITSV_ELEMENT:
      temp='';
      break;
   }
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _lbdeselect_all();
   typeless orig_sublist=strip_value(_lbget_text());
   typeless parent_linenumber='';//Will be set in get_parent_ptr_from_sublist
   typeless isptr='';
   typeless *pparent=get_parent_ptr_from_sublist(p_active_form,orig_sublist,parent_linenumber,isptr);
   int parent_format=pparent->_varformat();
   result=show('-modal _textbox_form',
               '',
               0,//flags
               3000,//textbox width
               '',//helpitem
               '',//Buttons and captions
               '',//retrieve name
               '-e _isnot_valid_subscript:'parent_format' &Subscript:'
               );
   if (result=='') return;
   typeless new_subscript=_param1;
   typeless orig_prefix=element_prefix(orig_sublist);
   p_line=parent_linenumber;
   typeless parent_sublist="";
   if (p_line) {
      parent_sublist=strip_value(_lbget_text());//shouldn't need to strip
   }else{
      parent_sublist='';
   }
   typeless parent_last_sub=0;
   typeless cur_sublist="";
   typeless cur_sub_list="";
   typeless cur_sub_prefix="";
   typeless cur_last_sub="";
   typeless cur_sub="";
   typeless cur_value="";
   typeless new_sublist="";
   typeless new_numsubs="";
   typeless top_line=0;
   typeless last_sub="";
   typeless pnum="";
   typeless num="";
   boolean doinsert=1;
   _str ch="";
   _str text="";
   int indent=0, curpic=0, pic=0;
   switch (parent_format) {
   case VF_ARRAY:
      parent_last_sub=get_last_sub(parent_sublist);
      while (!_lbdown()) {
         cur_sublist=strip_value(_lbget_text());
         cur_last_sub=get_last_sub(cur_sublist);
         if (!subscripts_child(parent_sublist,cur_sublist)) {
            _lbup();
            break;
         }
         if (cur_last_sub>new_subscript) {
            new_numsubs=num_subs(cur_sublist)+1;
            while (!_lbup()) {
               cur_sublist=strip_value(_lbget_text());
               cur_last_sub=get_last_sub(cur_sublist);
               if (num_subs(cur_sublist)<new_numsubs) break;
               if (cur_last_sub<new_subscript) break;
            }
            break;
         }
         top_line=p_line+1;
         if (cur_last_sub==new_subscript) {
            _lbup();
            add_el_or_structure(parent_sublist,child_format,new_subscript);
            last_sub=new_subscript;
            pnum=num_subs(parent_sublist);
            top_line=p_line;
            while (!_lbdown()) {
               _lbget_item(text,indent,curpic);
               cur_sub_list=strip_value(text);
               //If number of subscripts goes down, out of children
               num=num_subs(cur_sub_list);
               if (num_subs(cur_sub_list)<pnum+1) {
                  break;
               }
            }
            doinsert=0;
            if (p_line!=p_Noflines) {
               _lbup();
            }
            while (p_line>top_line) {
               _lbget_item(text,indent,pic);
               cur_sub_list=strip_value(text);
               cur_value=strip_subscripts(text);
               cur_sub_prefix=element_prefix(cur_sub_list);
               ch=substr(cur_sub_list,length(cur_sub_list));
               if (ch!=':') ch='';
               cur_sub=get_last_sub(cur_sub_list);
               pparent->_el(cur_sub+1)=pparent->_el(cur_sub);
               if (pic=='') {
                  mylbset_item(cur_sub_prefix'['cur_sub+1']'ch"\t"cur_value,indent,pic);
               }else{
                  mylbset_item(cur_sub_prefix'['cur_sub+1']'ch,indent,pic);
               }
               _lbup();
            }
            cur_sub_list=strip_value(_lbget_text());
            cur_sub=get_last_sub(cur_sub_list);
            pparent->_el(cur_sub)=temp;
            break;
         }
      }
      if (doinsert) {
         add_el_or_structure(parent_sublist,child_format,new_subscript);
         pparent->_el(new_subscript)=temp;
      }
      break;
   case VF_HASHTAB:
      if (pparent->_el(new_subscript)._varformat()!=VF_EMPTY) {
         _message_box(nls("A subscript %s already exists.",new_subscript));
         return;
      }
       switch (child_format) {
      case VAREDITSV_ELEMENT:
         new_sublist=parent_sublist'['new_subscript"]\t";
         mylbadd_item(new_sublist,50);
         break;
      case VAREDITSV_HASHTAB:
      case VAREDITSV_ARRAY:
         new_sublist=parent_sublist'['new_subscript']';
         mylbadd_item(new_sublist,50,_pic_lbplus);
         break;
      }
      //add_el_or_structure(parent_sublist,child_format,new_subscript);
      pparent->_el(new_subscript)=temp;
      break;
   }
   _lbselect_line();
   if (child_format==VAREDITSV_ELEMENT) {//Dan added to fix focus after insert 11:19pm 1/30/1996
      _ctlsv_value._set_focus();
   }else{
      _set_focus();
   }
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
   p_window_id=wid;
}

static void convert_format(var dest, typeless *ptr)
{
   typeless i;
   i._makeempty();
   typeless tempptr='';
   int count=-1;
   for (;;) {
      ++count;
      tempptr=&ptr->_nextel(i);
      if (i._varformat()==VF_EMPTY) break;
      if (dest._varformat()==VF_ARRAY) {
         /*I was trying to preseve the subscript if it was an integer, and it
           didn't work, but I haven't completely given up hope*/
#if 0
         typeless sub=isinteger(i)?i:count;
         while (dest._indexin(count)) {
            ++count;
/*Trying to avoid collision problems

               consider this scenario:
               a:[a]
               a:[0]
               a:[b]
               if you use a count for non int elements, and use the sub when
               it happens to be an integer, you could have collisions.
*/
         }
#else
         dest._el(count)=*tempptr;
#endif
      }else{
         dest._el(i)=*tempptr;
      }
   }
}

void _ctlsv_format.lbutton_up()
{
   int wid=p_window_id;p_window_id=_ctlsv_list;
   _str text="";
   int indent=0, pic=0;
   _lbget_item(text,indent,pic);
   typeless subscriptlist=strip_value(text);
   if (last_char(subscriptlist)==':') {
      subscriptlist=substr(subscriptlist,1,length(subscriptlist)-1);
   }
   typeless *ptr=get_ptr_from_sublist(p_active_form.p_user,subscriptlist);
   int format=ptr->_varformat();
   typeless result=show('-modal _setvar_insert_form','','',1,format);
   if (result=='') {
      p_window_id=wid;
      return;
   }
   typeless dest;
   _ctlsv_cancel.p_user=1;
   int orig_format=ptr->_varformat();
   _lbdeselect_all();
   switch (result) {
   case VAREDITSV_NOTINIT:
      if (orig_format!=VF_EMPTY) {
         mylbset_item(subscriptlist,50);
         ptr->_makeempty();
      }
      break;
   case VAREDITSV_HASHTAB:
      if (orig_format!=VF_HASHTAB) {
         dest:['0']._makeempty();
         if (orig_format==VF_ARRAY) {
            convert_format(dest,ptr);
         }
         *ptr=dest;
         mylbset_item(subscriptlist':',50,_pic_lbplus);
      }
      break;
   case VAREDITSV_ARRAY:
      if (orig_format!=VF_ARRAY) {
         dest[0]._makeempty();
         if (orig_format==VF_HASHTAB) {
            convert_format(dest,ptr);
         }
         *ptr=dest;
         mylbset_item(subscriptlist,50,_pic_lbplus);
      }
      break;
   case VAREDITSV_ELEMENT:
      if (orig_format!=VF_INT && orig_format!=VF_LSTR && orig_format!=VF_WID && orig_format!=VF_INT64) {
         *ptr='';
      }
      mylbset_item(subscriptlist"\t",50);
      break;
   }
   if (pic!='') {
      save_pos(auto p);
      while (!_lbdown()) {    //Delete all the children
         typeless cursubscriptlist=strip_value(_lbget_text());
         if (subscripts_child(subscriptlist,cursubscriptlist)) {
            _lbdelete_item();
            _lbup();
         }else break;
      }
      restore_pos(p);
   }
   _lbselect_line();
   _ctlsv_list.call_event(CHANGE_SELECTED, defeventtab _var_editor_form._ctlsv_list, ON_CHANGE,'E');
   p_window_id=wid;
}

defeventtab _setvar_insert_form;

_ctlsvi_ok.on_create()
{
   typeless subscriptlist=arg(1);
   typeless varname=arg(2);
   typeless no_notinit=arg(3)=='';
   if (no_notinit) {
      _ctlsvi_ok.p_y=_ctlsvi_ok.p_next.p_y=_ctlsvi_ok.p_next.p_next.p_y=_ctl_notinit.p_y+200;//Move all 3 buttons-help and cancel
      //p_active_form.p_height=p_active_form.p_height-_ctlsvi_ok.p_height;
      _ctl_notinit.p_visible=0;
   }
   p_active_form.p_height=_ctlsvi_ok.p_y+_ctlsvi_ok.p_height+200+p_active_form._top_height()+p_active_form._bottom_height();
   if (arg(4)!='') {
      switch (arg(4)) {
      case VF_EMPTY:
         _ctl_notinit.p_value=1;
         break;
      case VF_INT:
      case VF_WID:
      case VF_INT64:
      case VF_LSTR:
         _element.p_value=1;
         break;
      case VF_HASHTAB:
         _hashtab.p_value=1;
         break;
      case VF_ARRAY:
         _array.p_value=1;
         break;
      }
   }else{
      _element.p_value=1;
   }
   if (no_notinit) {
      p_active_form.p_caption='Select Type to Insert';
   }else{
      p_active_form.p_caption='Select New Type';
   }
}

_ctlsvi_ok.lbutton_up()
{
   typeless retval=0;
   if (_array.p_value) {
      retval=VAREDITSV_ARRAY;
   }
   if (_hashtab.p_value) {
      retval=VAREDITSV_HASHTAB;
   }
   if (_element.p_value) {
      retval=VAREDITSV_ELEMENT;
   }
   if (_ctl_notinit.p_value) {
      retval=VAREDITSV_NOTINIT;
   }
   p_active_form._delete_window(retval);
}
void debugvar(typeless &t,_str VariableName='debug')
{
   show('-modal _var_editor_form',VariableName,&t);
}
