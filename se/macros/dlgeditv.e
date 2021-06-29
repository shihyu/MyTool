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
#include "treeview.sh"
#import "cua.e"
#import "complete.e"
#import "deupdate.e"
#import "dlgman.e"
#import "event.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "mouse.e"
#import "options.e"
#import "picture.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vlstobjs.e"
#import "markfilt.e"
#import "treeview.e"
#require "sc/controls/RubberBand.e"
#import "math.e"
#endregion

/* Names dialog editor tool bar bitmap files with .bmp extension. */
static const DE_ARROW= 'bbpointer';//'_sarrow';
static const DE_LABEL= 'bblabel';//'_labelb';
static const DE_TEXT_BOX= 'bbtextbox';//'_textbox';
static const DE_EDIT_WINDOW= 'bbtext';//'_editwin';
static const DE_FRAME= 'bbframe';//'_frameb';
static const DE_COMMAND_BUTTON= 'bbbutton'; //'_cmdbtn';
static const DE_RADIO_BUTTON= 'bbradio_button';//'_radbtn';
static const DE_CHECK_BOX= 'bbcheckbox';//'_checkbx';
static const DE_COMBO_BOX= 'bbcombobox';//'_combobx';
static const DE_LIST_BOX= 'bblistbox';//_listbox';
static const DE_VSCROLL_BAR= 'bbvert_scrollbar';//'_vscroll';
static const DE_HSCROLL_BAR= 'bbhorz_scrollbar';//_hscroll';
static const DE_DRIVE_LIST= 'bbhard_drive';//'_drvlist';
static const DE_FILE_LIST= 'bblist_buffers';//'_fillist';
static const DE_DIRECTORY_LIST= 'bbopen';//_dirlist';
static const DE_PICTURE_BOX= 'bbbox';//'_picture';
static const DE_NONE= '.';
static const DE_IMAGE= 'bbhtml_image';//'_imageb';
static const DE_GAUGE= 'bbprogress_bar';//'_gaugeb';
static const DE_SPIN= 'bbspin';//_spinb';
static const DE_TREE_VIEW= 'bbtree';//'_tree';
static const DE_SSTAB= 'bbtabs';//'_sstabb';
static const DE_SSTAB_CONTAINER= '_sstabb_container';
static const DE_MINIHTML= 'bbhtml_text';//'_minihtm';
static const DE_SWITCH= 'bbswitch';//'_switchb';

static const DEBITMAP_LIST= (
    DE_ARROW'='0' ':+
    DE_MINIHTML'='OI_MINIHTML' ':+
    DE_LABEL'='OI_LABEL' ':+
    DE_SPIN'='OI_SPIN' ':+
    DE_TEXT_BOX'='OI_TEXT_BOX' ':+
    DE_EDIT_WINDOW'='OI_EDITOR' ':+
    DE_FRAME'='OI_FRAME' ':+
    DE_COMMAND_BUTTON'='OI_COMMAND_BUTTON' ':+
    DE_RADIO_BUTTON'='OI_RADIO_BUTTON' ':+
    DE_CHECK_BOX'='OI_CHECK_BOX' ':+
    DE_COMBO_BOX'='OI_COMBO_BOX' ':+
    DE_LIST_BOX'='OI_LIST_BOX' ':+
    DE_VSCROLL_BAR'='OI_VSCROLL_BAR' ':+
    DE_HSCROLL_BAR'='OI_HSCROLL_BAR' ':+
    DE_DRIVE_LIST'='OI_COMBO_BOX' ':+
    DE_FILE_LIST'='OI_LIST_BOX' ':+
    DE_DIRECTORY_LIST'='OI_TREE_VIEW' ':+
    DE_PICTURE_BOX'='OI_PICTURE_BOX' ':+
    DE_GAUGE'='OI_GAUGE' ':+
    DE_IMAGE'='OI_IMAGE' ':+
    DE_SSTAB'='OI_SSTAB' ':+
    DE_TREE_VIEW'='OI_TREE_VIEW' ':+
    DE_SWITCH'='OI_SWITCH);

static const DEBITMAP_2_UL2_LIST= (
    //DE_ARROW'='. ':+
    DE_MINIHTML'=_ul2_minihtm ':+
    //DE_LABEL'=. ':+
    //DE_SPIN'='. ':+
    DE_TEXT_BOX'=_ul2_textbox ':+
    DE_EDIT_WINDOW'=_ul2_editwin ':+
    //DE_FRAME'=. ':+
    //DE_COMMAND_BUTTON'=. ':+
    //DE_RADIO_BUTTON'=. ':+
    //DE_CHECK_BOX'=. ':+
    DE_COMBO_BOX'=_ul2_combobx ':+
    DE_LIST_BOX'=_ul2_listbox ':+
    //DE_VSCROLL_BAR'=. ':+
    //DE_HSCROLL_BAR'=. ':+
    DE_DRIVE_LIST'=_ul2_drvlist ':+
    DE_FILE_LIST'=_ul2_fillist ':+
    DE_DIRECTORY_LIST'=_ul2_dirlist ':+
    DE_PICTURE_BOX'=_ul2_picture ':+
    //DE_GAUGE'=. ':+
    DE_IMAGE'=_ul2_imageb ':+
    DE_SSTAB'=_ul2_sstabb ':+
    DE_TREE_VIEW'=_ul2_tree '
    //:+ DE_SWITCH'=. '
    );


_form _dlge_form;
int _deform_wid=0;      //  Window id of properties form.
//int _decombo_wid=0;     // Window id of combo box
int _delist_wid=0;      // Window id of list box
_str _deobject_name='';
int _deNofselected=0;   // Number of selected
                        // controls
_str _depname='';       // Current/last property name
//_combo_box combo;


// Pre-alpha versions of the dialog editor changed the
// mouse shape when you moved controls.  We found this
// annoying when moving small controls.  So we have preprocessed
// this code out.
#define DLGEDITV_CHANGE_MOUSE_ON_MOVE 0

static _str _ignore_gotlost_focus=0;
static _str debug_count=0;

static _str _open_form_callback(int reason,var result,_str key);

definit()
{
   if (arg(1)!='L') {
      _deform_wid=0;
      _display_wid=0;
   }
   //already_editing_dlge_props=0
   //_set_selected2_index=find_index('-set-selected2',PROC_TYPE)
}

//
//  Event processing for dialog editor properties form
//  Don't need anything new.  Need it to define form.

/** 
 *    Displays dialog editor Properties dialog box.
 * @categories Forms
 */

defeventtab _dlge_form;
_dlge_form.'F2',"C-S", "A-W"()
{
   if (_display_wid) {
      _display_wid.p_active_form.save_form();
   }

}
_dlge_form.'F12'()
{
   if (_display_wid) {
      _display_wid._set_focus();
   }

}
_dlge_form.'F1'()
{
   if (_display_wid) {
      help('p_'_depname);
      return('');
   }
   help('dialog editor');
}
static const SMALLEST_LIST_WIDTH= 2500;
static const SMALLEST_COL1_WIDTH= 1000;
static const LARGEST_COL1_WIDTH= 1500;
static const SMALLEST_COL2_WIDTH= 1000;
static const RIGHT_PADDING= 100;
static const BOTTOM_PADDING= 50;
static const PAD_AFTER_BITMAPS= 100;

//
//  Event processing for dialog editor list box
//
ctllist.on_create()
{

   // Set up columns

   // This is the left colun with the property name
   // We do not want it to be editable
   _TreeSetColButtonInfo(0,1000,TREE_BUTTON_PUSHBUTTON/*|TREE_BUTTON_SORT*/,-1,"Property");

   // This the right colun with the property's value.
   // Use the editable flag here - the tree control will figure out whether to 
   // use a text box, or a combo box
   _TreeSetColButtonInfo(1,1000,TREE_BUTTON_PUSHBUTTON,-1,"Value");
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);

   int bitmap_padx = bbpointer.p_x;
   int bitmap_pady = bbpointer.p_y;
   int dlge_bwidth = bbpointer.p_width+bitmap_padx;
   int dlge_bheight= bbpointer.p_height+bitmap_pady;
   //_dxy2lxy(SM_TWIP,dlge_bwidth,dlge_bheight);
   int combo_x=dlge_bwidth*2+PAD_AFTER_BITMAPS;
   //combo.p_x=combo_x;
   _objectkind.p_x=p_x=combo_x;
   p_y = _objectkind.p_y_extent+_objectkind.p_y;
   _str list=DEBITMAP_LIST;
   i := 0;
   for (i=0;;++i) {
      lbitmap := "";
      rbitmap := "";
      parse list with lbitmap'='. rbitmap'='. list ;
      if (lbitmap=='') break;
      _find_control(lbitmap).p_y=i*dlge_bheight+bitmap_pady;
      if (rbitmap=='') break;
      if (rbitmap=='.') {
         continue;
      }
      r_wid := _find_control(rbitmap);
      r_wid.p_x=dlge_bwidth+bitmap_padx;
      r_wid.p_y=i*dlge_bheight+bitmap_pady;
   }

}
#if 0
ctllist.lbutton_double_click()
{
   _delist_dclick();
   get_event('B');
}
#endif
/** 
 * The CHANGE_SELECTED part of this is what gives us the 
 * "property sheet" feel.  If you remove the call to 
 * _TreeEditNode(), users will have to double click to edit a 
 * node 
 *  
 * @param reason One of the CHANGE_* constants
 * @param index index that was changed.  NOTE - this can be -1, 
 *              so be sure to check before running tree
 *              operations on it.
 * @param col Column for the change - only apples to 
 *            CHANGE_EDIT_* reasons
 * @param value value that user has set for this item - only 
 *              apples to CHANGE_EDIT_* reasons
 * 
 * @return int 
 */
int ctllist.on_change(int reason,int index,int col=-1,_str value="",int wid=0)
{
   if(_deignore_ctllist_on_change==1) return(0);

   switch ( reason ) {
   case CHANGE_EDIT_CLOSE:
      //say('on_change CHANGE_EDIT_CLOSE');
      return _deupdate_property(index,value);
   case CHANGE_EDIT_PROPERTY:
      // When we get CHANGE_EDIT_PROPERTY, if we return TREE_EDIT_COLUMN_BIT, 
      // the tree will automatically put the node into edit mode for the
      // column that we OR in. In this case, we always want to edit column
      // 1 (the leftmost column is column 0), so we return TREE_EDIT_COLUMN_BIT|1
      if (_deNofselected>1) {
         return 0;
      }
      return TREE_EDIT_COLUMN_BIT|1;
   case CHANGE_EDIT_OPEN_COMPLETE:
      {
         // CHANGE_EDIT_OPEN_COMPLETE is where we can do things like add items
         // to a combo box, or set the p_completion property for a text box.
         // the 'value' parameter that comes in only gives us the value for the
         // column being edited, so here we take the index and get the value 
         // of the whole caption so we can see what is in column 0, and work
         // based on taht
         _deupdate_edit_in_place(index,false,wid);
      }
      break;
   case CHANGE_NODE_BUTTON_PRESS:
      {
         // The "..." button to the right of the text/combo box was pressed

         // This has to be a modal dialog
         cap := _TreeGetCaption(index);
         parse cap with auto name "\t" .;

         if (pos('picture',name,1,'i') ) {
            typeless result=_OpenDialog('-modal ',
                                        'Open picture', 
                                        (_isUnix()? "*.xpm;":"") :+ "*.bmp;*.ico;*.svg",
                                        (_isUnix()?" Images (*.xpm;*.bmp;*.ico;*.svg),Pixmaps (*.xpm)":"Images (*.bmp;*.ico;*.svg)") :+ ",Bitmaps (*.bmp),Icons (*.ico),Scalable Vector Graphics(*.svg),All Files ("ALLFILES_RE")",
                 OFN_FILEMUSTEXIST,
                 'svg',      // Default extensions
                 '',         // Initial filename
                 '',         // Initial directory
                 'bmp'       // Retrieve name
                 );
            if (result=='') {
               return(COMMAND_CANCELLED_RC);
            }
            result=strip(result,'B','"');
            if (result!='') {
               int pic_index=_update_picture(-1,result);
               if (pic_index<0) {
                  result='';
               } else {
                  temp:=path_search(name_name(pic_index),"VSLICKBITMAPS",'R');
                  if (temp!='') {
                     result=name_name(pic_index);
                  }
                  //result=_strip_filename(result,'P');
               }
            }
            wid.p_ReadOnly=false;
            wid.p_text=result;
            wid.p_ReadOnly=true;
            //combo.p_text=result;
            //_deupdate_property();
            //combo.p_text=strip_filename(result,'P');
            _deupdate_property(index,result);
            _TreeSetCaption(index,name"\t"result);
         } else if (pos('color',name,1,'i') ) {
            form_wid := p_active_form;
            old_wid := p_window_id;
            // Open existing .bmp file
            _str result=show('-modal _decolor_form',wid.p_text);
            p_window_id=old_wid;
            if (result=='') {
               return(COMMAND_CANCELLED_RC);
            }
            if (result==0x80000005) {
               if (lowcase(name)!='backcolor') {
                  result=0x80000008;
               }
            }
            /*result=dec2hex(result);
            if (result=='') {
               return COMMAND_CANCELLED_RC;
            } */
            result=_format_color((int)result);
            wid.p_text=result;
            //_deupdate_property();
            _deupdate_property(index,result);
            _TreeSetCaption(index,name"\t"result);
            //_deupdate_property(index,result);
         }
      }
      break;
   case CHANGE_SELECTED:
      if (index<0 || _deNofselected>1) {
         //_delist_wid._TreeDelete(TREE_ROOT_INDEX,'C');
         return 0;
      }
      if ( index>=0 ) {
         // _depname is a global variable. when clicking on different edited control
         // want to default to selecting the same property name.
         parse _TreeGetCaption(index) with _depname "\t";
      }
   }
   return 0;
}
_dlge_form.on_resize(bool move)
{
   if (!move) {
      int new_width= p_client_width*_twips_per_pixel_x()-RIGHT_PADDING-_delist_wid.p_x;
      if (new_width<SMALLEST_LIST_WIDTH) {
         new_width=SMALLEST_LIST_WIDTH;
      }
      int new_height= p_client_height*_twips_per_pixel_y()-BOTTOM_PADDING-_delist_wid.p_y;
      if (new_height<1) {
         new_height=1;
      }
      int col1_width=SMALLEST_COL1_WIDTH;
      int col2_width=SMALLEST_COL2_WIDTH;
      if (new_width-SMALLEST_COL2_WIDTH>SMALLEST_COL1_WIDTH) {
         int extra=(new_width -(col1_width+col2_width)) intdiv 2;
         if (col1_width+extra>LARGEST_COL1_WIDTH) {
            col1_width=LARGEST_COL1_WIDTH;
         } else {
            col1_width += extra;
         }
         col2_width=new_width-col1_width;
      }
      _delist_wid._col_width(0,col1_width);
      _delist_wid._col_width(1,col2_width);
      x := y := width := height := 0;
      _delist_wid._get_window(x,y,width,height);
      _delist_wid._move_window(x,y,new_width,new_height);
      //_decombo_wid.p_width=new_width;
   }
}
_dlge_form.on_create()
{
   _deignore_ctllist_on_change=false;
   _deform_wid=p_window_id;
   _delist_wid=_control ctllist;
   //_decombo_wid=_control combo;

   _delist_wid.p_enabled=false;
   //_decombo_wid.p_enabled=false;

   if(_display_wid) _deupdate();
   _deselect_tool(DE_ARROW);
   //call_event(0,p_window_id,ON_RESIZE,'');
}
_dlge_form.on_destroy()
{
   _deform_wid=0;
}
_dlge_form.on_close,a_f4()
{
   //_deselect_tool(DE_ARROW)
   _get_form(p_window_id)._delete_window();
}
void _deselect_tool(_str tool)
{
   ico_tool := tool;
   svg_tool := tool;
   if (_get_extension(tool) == "") {
      svg_tool :+= ".svg";
      ico_tool :+= ".ico";
   } else {
      svg_tool = _strip_filename(tool,'e'):+".svg";
      ico_tool = _strip_filename(tool,'e'):+".ico";
   }

   if (!_deform_wid) return;
   int first_wid=_deform_wid.p_child;
   int wid=first_wid;
   for (;;) {
      if (wid.p_object==OI_IMAGE ||wid.p_object==OI_PICTURE_BOX) {
         if (_file_eq(ico_tool,name_name(wid.p_picture)) ||
             _file_eq(svg_tool,name_name(wid.p_picture))) {
            if (!wid.p_value) {
               wid.p_value=1;
            }
            _deobject_name=_file_case(_strip_filename(tool,'e'));
         } else {
            if (wid.p_value) {
               wid.p_value=0;
            }
         }
      }
      wid=wid.p_next;
      if (first_wid==wid) break;
   }
   //messageNwait('t3 _deobject_name='_deobject_name)
   tool_noext := _strip_filename(tool,'E');
   if (_file_eq(tool_noext,DE_ARROW)) {
      _decreate_mode(0);
   } else {
      _decreate_mode(1);
   }
}
//
//  Event processing for dialog editor tool bar buttons.
//
_arrow.lbutton_down()
{
#if 0
   mou_mode(1)
   mou_capture
   done=0;
   i=1
   for (;;++i) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         mx=mou_last_x()
         my=mou_last_y()
         _get_window x,y,width,height
         width=width/_twips_per_pixel_x()
         height=height/_twips_per_pixel_y()
         message 'i='i'mx='mx' my='my' width='width' height='height
         if (mx>=0 && my>=0 && mx<width && my<height) {
            if (!p_value) {
               p_value=1;
            }
         } else {
            if (p_value) {
               p_value=0;
            }
         }
         break;
      case LBUTTON_UP:
      case ESC:
         done=1;
      }
      if (done) break;
   }
   mou_mode(0);
   mou_release
   return('')
#endif
   /* If the button is down just return. */
   if (p_value) {
      //p_style=PSPIC_DEFAULT;
      //return '';
   }
   /* Make sure all other buttons are up. */
   first_wid := p_window_id;
   int wid=first_wid;
   for (;;) {
      wid=wid.p_next;
      if (wid==first_wid) break;
      if ((wid.p_object==OI_IMAGE ||wid.p_object==OI_PICTURE_BOX) /*&& wid.p_value*/) {
         wid.p_value=0;
         if (wid.p_nofstates==1) {
            wid.p_style=PSPIC_HIGHLIGHTED_BUTTON;
            wid.p_border_style=BDS_NONE;
         }
      }
   }
   p_value=1;
   if (p_nofstates==1) {
      p_style=PSPIC_DEFAULT;
      p_border_style=BDS_FIXED_SINGLE;
   }
   _deselect_tool(name_name(p_picture));
   p_window_id=first_wid;
}
void _arrow.lbutton_double_click()
{
   get_event('B');  // Reset button count
   if (!_display_wid) return;
   // Some times the lbutton_down event gets lost.  I think is because of
   // get_event()
   if (_strip_filename(name_name(p_picture),'e')!=_deobject_name) {
      p_value=0;
      call_event(1,p_window_id,LBUTTON_DOWN,'');
   }
   if (_file_eq(_strip_filename(name_name(p_picture),'E'),DE_ARROW)) {
      return;
   }
   int selected_wid=_display_wid;
   int Nofselected=_deNofselected;
   form_wid := _get_form(_display_wid);
   _reset_selected();
   if (Nofselected==1 &&
       (selected_wid.p_object==OI_FRAME || selected_wid.p_object==OI_PICTURE_BOX ||
         selected_wid.p_object==OI_SSTAB)
       ) {
      p_window_id=selected_wid;
      if (p_window_id.p_object==OI_SSTAB) {
         p_window_id = p_window_id._getActiveWindow();
      }
   } else {
      p_window_id=form_wid;
   }
   _create_control(p_window_id,_deobject_name,0);
   p_selected=true;
   _dedisplay(p_window_id,1);
   _deselect_tool(DE_ARROW);
}

#if 0
combo.on_drop_down(int reason)
{
   if (!_decombo_wid.p_cb_picture.p_picture==_pic_cbarrow) return('');
   switch (reason) {
   case DROP_UP:
      if (p_cb_list_box._lbisline_selected()) {
         _deupdate_property();
          p_cb_text_box._set_sel(length(p_cb_text_box.p_text)+1);
      }
      p_window_id=_delist_wid;
      break;
   case DROP_DOWN:
      if (!p_cb_list_box.p_Noflines) {
         _defill_cblist();
      }
      p_cb_text_box._set_sel(1,length(p_cb_text_box.p_text)+1);
      break;
   case DROP_INIT:
      if (!p_cb_list_box.p_Noflines) {
         _defill_cblist();
      }
      break;
   }
}
lcombo.lbutton_down()
{
   if (_decombo_wid.p_cb_picture.p_picture==_pic_cbarrow){
      call_event(defeventtab _ul2_combobx,LBUTTON_DOWN,'e');
      return('');
   }
   if (p_cb_active==p_cb_picture) {
      switch (lowcase(_depname)) {
      case 'activepicture':
      case 'picture':
      case 'collapsepicture':
      case 'expandpicture':
      case 'leafpicture':
         if (!p_cb_picture._push_button()) {
            return('');
         }
         // Open existing .bmp file
         reinit := "-reinit";
         typeless result=_OpenDialog('-modal ' :+ (_isUnix()? '-hideondel':''),
                                     'Open picture', 
                                     (_isUnix()? "*.xpm;":"") :+ "*.bmp;*.ico;*.svg",
                                     (_isUnix()?" Images (*.xpm;*.bmp;*.ico;*.svg),Pixmaps (*.xpm)":"Images (*.bmp;*.ico;*.svg)") :+ ",Bitmaps (*.bmp),Icons (*.ico),Scalable Vector Graphics(*.svg),All Files ("ALLFILES_RE")",
              OFN_FILEMUSTEXIST,
              'bmp',      // Default extensions
              '',         // Initial filename
              '',         // Initial directory
              'bmp'       // Retrieve name
              );
         if (result!='') {
            result=strip(result,'B','"');
            combo.p_text=result;
            _deupdate_property();
            combo.p_text=strip_filename(result,'P');
         }
         return('');
      case 'activecolor':
      case 'backcolor':
      case 'forecolor':
         if (!p_cb_picture._push_button()) {
            return('');
         }
         form_wid := p_active_form;
         old_wid := p_window_id;
         // Open existing .bmp file
         result=show('_decolor_form -hidden',combo.p_text);
         if (result<0) return('');
         int diff=form_wid.p_height-(form_wid.p_client_height*_twips_per_pixel_y());
         result.p_y=diff+form_wid.p_y+form_wid.combo.p_y+form_wid.combo.p_height;
         result.p_visible=true;
         result=_modal_wait(result);
         p_window_id=old_wid;
         if (result!='') {
            if (result==0x80000005) {
               if (lowcase(_depname)!='backcolor') {
                  result=0x80000008;
               }
            }
            combo.p_text=_format_color(result);
            _deupdate_property();
         }
         return('');
      }
   }
   call_event(defeventtab  _ul2_combobx,LBUTTON_DOWN,'E');
}
#endif

#if 0
static bool isDlgEditComboTextBoxMultilinePasteAllowed(int wid)
{
   // We have to check both _decombo_wid and _decombo_wid.p_cb_text_box since the active
   // window is different depending on how you paste (e.g. Ctrl+V, right-click+Paste).
   if( _deform_wid > 0 && (wid == _decombo_wid || wid == _decombo_wid.p_cb_text_box) ) {
      if( _display_wid > 0 ) {
         if( _depname == "text" ) {
            if( _display_wid.p_object == OI_MINIHTML ) {
               return true;
            }
         }
      }
   }
   return false;
}

/**
 * Callback used by paste command to condense a multiline pasted
 * clipboard into a single line suitable for the dialog editor's
 * text field. This is useful when, for example, pasting
 * multiple lines of html text into the text property of a
 * minihtml control.
 *
 * @param targetWid Window id of textbox we are pasting to.
 * @param firstLineNumber First line of the pasted text to
 *                        processed in the current window.
 * @param lastLineNumber  Last line of the pasted text to
 *                        processed in the current window.
 *
 * @return true if we processed the text, otherwise false.
 */
bool _ProcessCommandPaste_DlgEditComboPasteMultiline(int targetWid, int firstLineNumber, int lastLineNumber)
{
   if( !isDlgEditComboTextBoxMultilinePasteAllowed(targetWid) ) {
      return false;
   }
   if( firstLineNumber == lastLineNumber ) {
      // Only interested in multiline pastes
      return false;
   }
   p_line=firstLineNumber;
   int Noflines = lastLineNumber - firstLineNumber + 1;
   line := "";
   while( Noflines > 1 ) {
      get_line(line);
      replace_line(strip(line,'t'):+_chr(10));
      if( 0 != _join_line() ) {
         // Return true since we have already altered the pasted text.
         // Paste will end up deleting any extra lines before setting
         // the textbox text.
         return true;
      }
      Noflines--;
   }
   return true;
}
#endif

static void _dedisplay(int wid, _str Nofselected='')
{
   if (_display_wid==wid && Nofselected==_deNofselected &&
      _deNofselected==1) return;
   if (Nofselected=='') {
      _deNofselected=(wid)?1:0;
   } else {
      _deNofselected=(int)Nofselected;
   }
   _display_wid=wid;
   _deupdate();
}
void _on_edit_form()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_DIALOG_EDITING)) {
      return;
   }
   //index=find_index(p_name,oi2type(OI_FORM))
   //if (!index || p_name=='') {
   int index= p_template;
   if (!index) {
      int result=_message_box(nls("Form has no template.  Can't edit this form\n\nPress OK button to close window."),'',
                          MB_OKCANCEL
                         );
      if (result==IDOK && !p_IsClippedChild){
         p_active_form._delete_window();
      }
      return;
   }
   if (!p_DockingArea && !p_IsClippedChild) {
      if (p_modal) {
         // Delete all modal form windows. */
         _delete_modal_windows();
      } else if (p_window_id!=_deform_wid) {
         p_init_style&=~(IS_REINIT|IS_HIDEONDEL);
         _delete_window();
      }
   }
   open_form(translate(name_name(index),'_','-'));
}
void _on_show_properties()
{
   show_properties(1);
}
#if 0
_str _on_update_and_load()
{
   form_wid=_get_form(p_window_id);
   status=form_wid._update_template()
   if (status<0) {
      _message_box(nls("Failed to update form '%s'.\n"get_message(status)))
      return('')
   }
   status=load_all();
   return(status)
}
#endif
static _str _load_form()
{
   form_wid := p_active_form;
   int status=form_wid._update_template();
   if (!status) {
      status=INSUFFICIENT_MEMORY_RC;
      _message_box(nls("Failed to update form '%s'.",form_wid.p_name)"\n\n"get_message(status));
      return(status);
   }
   if (form_wid.p_object_modify) {
      _set_object_modify(status);
   }
   form_wid.p_object_modify=false;
   return(0);
}
void _on_load_form()
{
   _load_form();
   // Now for a visual effect.  Blink the handles on/off
   _deblink_selected();
}
void _on_run()
{
   run_selected();
}
static void _run_selected2(_str form_wid='')
{
   if (form_wid=='') {
      return;
   }
   // If form not currently being edited.
   if (!isinteger(form_wid)) {
      show('-app 'form_wid);
      return;
   }
   show('-app 'form_wid.p_name);
}
/**
 * Saves the form selected in the dialog editor.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories Form_Functions
 * 
 */ 
_command save_form() name_info(FORM_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (p_mdi_child) {
      if (!_display_wid) {
         _message_box(nls('No form is selected'));
         return(1);
      }
      return(_display_wid.save_form());
   }
   form_wid := _get_form(p_window_id);
   int status=form_wid._update_template();
   if (!status) {
      status=INSUFFICIENT_MEMORY_RC;
      _message_box(nls("Failed to update form '%s'.",form_wid.p_name)"\n\n"get_message(status));
      return(status);
   }
   if (form_wid.p_object_modify) {
      _set_object_modify(status);
   }
   status=save_config(1);
   if ( !status) {  /* write-state successful */
      form_wid.p_object_modify=false;
   }
   return(status);
}
/** 
 * Loads all Slick-C&reg; source files (.e) currently opened.  If the 
 * <i>eventtab_name</i> argument is given and not '', only source files which 
 * define an event table of the specified name are loaded.
 * 
 * @see unload
 * @see load
 * @see gui_load
 * @see gui_unload
 * @see _load
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command load_all(_str eventtab_name="") name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (_no_child_windows()) {
      return(0);
   }
   orig_view_id := 0;
   get_window_id(orig_view_id);
   p_window_id=_mdi._edit_window();
   _safe_hidden_window();
   int first_buf_id=p_buf_id;
   status := 0;
   for (;;) {
     _next_buffer('HR');    /* Must include hidden buffers, because */
                            /* active buffer could be a hidden buffer */
     int buf_id=p_buf_id;
     _str extension=_get_extension(p_buf_name);
     if ( ! (p_buf_flags & VSBUFFLAG_HIDDEN) &&
          (_file_eq('.'extension,_macro_ext) ||_file_eq(extension,'cmd'))) {
        if (eventtab_name!='') {
           save_pos(auto p);
           top();
           search('^[ \t]*defeventtab[ \t]#'strip(eventtab_name)'([~a-zA-Z0-9_$]|$)','@ri');
           if (!rc) {
              status=load();
           } else {
              status=0;
           }
           if (!status) {
              restore_pos(p);
           }
        } else {
           status=load();
        }
        if ( status ) {
           break;
        }
     }
     if ( buf_id== first_buf_id ) {
       break;
     }
   }
   if (status) {
      int error_buf_id=p_buf_id;
      if (def_one_file!='') {
         p_buf_id=first_buf_id;
      }
      edit('+bi 'error_buf_id);
      return(status);
   }
   activate_window(orig_view_id);
   return(0);
}
void _on_save_form()
{
   save_form();
}

_str _list_tab_index2(int wid)
{
   if (wid.p_tab_index<=0) {
      return(0);
   }
   bottom();
   while (p_Noflines<wid.p_tab_index) {
      insert_line('');
   }
   p_line=wid.p_tab_index;
   line := "";
   get_line(line);
   replace_line(line' 'wid);
   return(0);
}
static int _list_tab_index(int &orig_view_id)
{
   wid := p_window_id;
   temp_view_id := 0;
   orig_view_id=_create_temp_view(temp_view_id);
   if (!wid.p_parent) {
      activate_window(orig_view_id);
      return(temp_view_id);
   }
   int child=wid;
   int first_child=child;
   for (;;) {
      _list_tab_index2(child);
      child=child.p_next;
      if (child==first_child) {
         break;
      }
   }
   //_for_each_control(_get_form(wid),'_list_tab_index2')
   activate_window(orig_view_id);
   return(temp_view_id);
}
_str _set_tab_index(int index)
{
   if (index<=0) {
      p_tab_index=0;
      return(0);
   }
   typeless wid=p_window_id;
   // Place windows in line number which corresponds
   // to p_tab_index
   orig_view_id := 0;
   temp_view_id := _list_tab_index(orig_view_id);
   activate_window(temp_view_id);
   top();
   line := "";
   int status=search('(^| )'wid'( |$)','@r');
   if (! status) {
      get_line(line);line=substr(line,1,p_col-1):+substr(line,p_col+match_length());
      replace_line(line);
   }
   if (index>p_Noflines) {
      bottom();
      while (index-1>p_Noflines) {
         insert_line('');
      }
      insert_line(wid);
   } else {
      p_line=index;
      get_line(line);
      replace_line(line' 'wid);
   }
   leading_blank_lines := 1;
   top();
   for (;;){
      get_line(line);
      if (line=='') {
         if (!leading_blank_lines) {
            status=_delete_line();
            if (!status) {
               continue;
            }
         }
      } else {
         leading_blank_lines=0;
         for (;;) {
            parse line with wid line;
            if (line=='') {
               /* messageNwait('setting wid='wid' to 'p_line) */
               wid.p_tab_index=p_line;
               break;
            }
            insert_line(wid);
            up();
         }
      }
      if (down()) break;
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(0);
}
static _str _selected_list;
static int _set_selected2(int wid, bool val)
{
   if (wid.p_selected) {
      wid.p_selected=val;
      _selected_list :+= ' 'wid;
   }
   return(0);
}
static _reset_selected(_str wid='')
{
   if (!_display_wid) return('');
   int child=_display_wid;
   _selected_list='';
   for (;;) {
      // If child is selected and window id is different
      if (child.p_selected && child!=wid) {
         if (length(_selected_list)<MAX_LINE-5) {
            _selected_list :+= ' 'child;
         }
         child.p_selected=false;
      }
      child=child.p_next;
      if (child==_display_wid) break;
   }
}
void _set_selected(bool val)
{
   _selected_list='';
   _for_each_control(_get_form(p_window_id),_set_selected2,'',val);
}
static void _restore_selected()
{
   typeless wid='';
   for (;;) {
      parse _selected_list with wid _selected_list;
      if (wid=='') break;
      wid.p_selected=true;
   }
}
   _control _sellist;
   _control _sellistcombo;


/** 
 * Inserts Slick-C&reg; source code for the dialog box template or menu 
 * template into the current buffer.  If <i>object_name</i> is not given, a 
 * dialog box is displayed which allows you to enter a form or menu name or 
 * select from a list of existing objects.  If the current buffer has a 
 * selection that is not locked, it is replaced unless the current selection 
 * style does not perform a paste replace (See <b>Select Styles Tab</b>).
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command insert_object(_str result="") name_info(OBJECT_ARG','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (result=='') {
      orig_wid := p_window_id;
      result=_list_matches2(
                     'Insert Form/Menu Source',   // title
                     SL_MATCHCASE|SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_DEFAULTCALLBACK,  // flags
                     '',       // buttons
                     'Insert Form Source dialog box',   // help_item
                     '',       // font
                     _open_form_callback, //callback
                     'insert_object',       // retrieve_name
                     OBJECT_ARG,            // completion
                     0,                     // min list width
                     ''                     // fast complete
                     );
      p_window_id=orig_wid;
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
   }
   index := find_index(result,OBJECT_TYPE);
   if (!index) {
      popup_message(nls('Could not find template object "%s".  Make sure object is saved first.',result,'','Error'));
      return(1);
   }
   int status=maybe_delete_selection();
   if(status){
      if (status==4) {
         _delete_line();
      } else {
         up();
      }
   }
   status=list_objects(result);
   if(status){
      _message_box(nls("Error")"\n\n"get_message(status));
   }
   return(status);
}

static _str _open_form_callback(int reason,var result,_str key)
{
   _nocheck _control _sellistcombo,_sellist;

   if (reason==SL_ONDEFAULT) {  // Enter key
      form_caption := lowcase(p_active_form.p_caption);
      form_name := p_active_form.p_name;
      result=_sellist._lbget_seltext();
      if (result=='') {
         result=_sellistcombo.p_text;
      }
      if (form_caption!='open form') {
         if (result=='') {
            if (form_name=='insert_object') {
               p_window_id=_sellistcombo;
               return('');
            }
            // Return invalid identifier character
            result='*';
            return(1);
         }
         status := _sellist._lbsearch(result,'E');
         if (status) {
            _message_box(nls('%s does not exist',result));
            p_window_id=_sellistcombo;
            _set_sel(1,length(p_text)+1);_set_focus();
            return('');
         }
         return(1);
      }
      // Make sure that character
      if (!isid_valid(result)) {
         _message_box(nls('Invalid identifier'));
         return('');
      }
      result='-new 'result;
      return(1);
   }
   return('');
}

/**
 * Opens one or more dialog boxes (forms) specified for editing with the 
 * dialog editor.  If a form is already opened for editing, it is brought to the 
 * foreground and given focus.  The <b>-new</b> option specifies that a new form 
 * with the given name be created if it does not already exist.  If no arguments 
 * are given or <i>cmdline</i> is "", a selection list of existing forms is 
 * displayed.
 * 
 * @param cmdline is a string in the following format:  [-new]
 * <i>form1</i> [<i>form2 </i>[<i>form3 ...</i>]]
 * 
 * @return Returns 0 if there are no errors.
 * 
 * @categories Form_Functions
 * 
 */
_command open_form(_str cmdline="") name_info(FORM_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   names := "";
   if (cmdline=="") {
      _str result=_list_matches2(
                     'Open Form',   // title
                     SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_DEFAULTCALLBACK|SL_MATCHCASE, // flags
                     '',       // buttons
                     'Open Form dialog',   // help_item
                     '',       // font
                     _open_form_callback, //callback
                     'open_form',       // retrieve_name
                     FORM_ARG); // completion
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      names=strip(result);
   } else {
      names=strip(cmdline);
   }
   screen_x := 0;
   screen_y := 0;
   screen_width := 0;
   screen_height := 0;
   status := 0;
   typeless result_wid='';
   first_time := true;
   new_form_if_not_found := false;
   reset_modify := false;
   for (;;) {
      name := "";
      parse names with name names ;
      if (name=='') {
         status=0;
         break;
      }
      if (lowcase(name)=='-new') {
         new_form_if_not_found=true;
         continue;
      }
      reset_modify=false;
      int wid=_find_formobj(name,'E');
      if (!wid) {
         int index=find_index(name,oi2type(OI_FORM));
         wid=0;
         if (!index){
            if (!new_form_if_not_found) {
               popup_message(nls('Form "%s" not found',name));
               status=STRING_NOT_FOUND_RC;
               break;
            }

            width := 6000;
            height := 6000;
            _mdi._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
            int x=((screen_width)*_twips_per_pixel_x()-width) intdiv 2;
            int y=((screen_height)*_twips_per_pixel_y()-height) intdiv 2;
            x+=screen_x*_twips_per_pixel_x();
            y+=screen_y*_twips_per_pixel_y();
            wid=_create_window(OI_FORM,_desktop,"",
                                x,y,width,height,
                                CW_PARENT|CW_EDIT,
                                BDS_DIALOG_BOX);
            if (wid<0) {
               popup_message(nls('Unable to create form')'.  'get_message(wid));
               status=wid;
               break;
            }
            wid.p_name=name;
            wid.p_caption=wid.p_name;
            reset_modify=true;
         }
         if (!wid) {
            // message 'index='index' wid='eventtab_window(index)
            wid=_isloaded(index,'E');
            if (!wid){
               wid=_load_template(index,_desktop,'EH') /* Edit|Hidden */;
               if (wid<0) {
                  popup_message(nls('Unable to open form %s',name)'.  'get_message(wid));
                  status=wid;
                  break;
               }
               reset_modify=true;
            }
            if (wid) {
               wid.p_init_style=0;
               wid._restore_form_xy();
            }
         }
      } else {
         wid.p_visible=true;
      }
      if (first_time) {
         if (_display_wid) {
            _reset_selected();
         }
         show_properties(1);
      }
      result_wid=wid;
      p_window_id=wid;
      //refresh();
      if (reset_modify) {
         wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
         if (wid.p_x>=(screen_x+screen_width)*_twips_per_pixel_x()-720 ||
             wid.p_x_extent-720<screen_x*_twips_per_pixel_x() ||
             wid.p_y>=(screen_y+screen_height)*_twips_per_pixel_y()-720 ||
             wid.p_y_extent-720<screen_y*_twips_per_pixel_y()
             ) {
             wid._center_window(_desktop);
         }
         wid.p_visible=true;
         wid.p_object_modify=false;
      }
      first_time=false;
   }
   //temp=_defind_selected();messageNwait('cursel='temp);
   if (result_wid!='') {
      if (_display_wid) {
         _reset_selected();
      }
      _dedisplay(result_wid,1);
      result_wid.p_selected=true;
      _set_focus();
   }
   return(status);
}

/**
 * Creates an empty dialog box form for editing with the dialog editor.
 * 
 * @param form_name  name of new form to create
 * 
 * @return Returns 0 if new form successfully created.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Form_Functions
 */
_command new_form(_str form_name="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   show_properties(1);

   width := 6000;
   height := 6000;
   screen_x := 0;
   screen_y := 0;
   screen_width := 0;
   screen_height := 0;
   _mdi._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int x=((screen_width)*_twips_per_pixel_x()-width) intdiv 2;
   int y=((screen_height)*_twips_per_pixel_y()-height) intdiv 2;
   x+=screen_x*_twips_per_pixel_x();
   y+=screen_y*_twips_per_pixel_y();
   int wid=_create_window(OI_FORM,_desktop,"",
                       x,y,width,height,
                       CW_PARENT|CW_EDIT,
                       BDS_DIALOG_BOX);
   if (wid<0) {
      popup_message(nls('Unable to create form')'.  'get_message(wid));
      return(wid);
   }
   if (form_name != '') {
      wid.p_name = form_name;
   } else {
      wid._unique_name();
   }
   wid.p_caption=wid.p_name;
   object_modify := wid.p_object_modify;
   wid.p_selected=true;
   //wid.p_visible=true;p_window_id=wid.p_window_id
   /* _fill_list_boxes() */
   wid.p_object_modify=false;
   if (_display_wid) {
      _reset_selected();
   }
   _dedisplay(wid,1);
   return(0);
}
/**
 * @return Returns Windows <i>form_name</i> translated to the appropriated 
 * dialog box for the current operating System.  If there is no translation 
 * for the form <i>form_name</i>, <i>form_name</i> is returned.
 * 
 * @categories Miscellaneous_Functions
 * @Deprecated Send the appropriate flag to _OpenDialog instead.
 */ 
_str _stdform(_str name)
{
   if (_isUnix()) {
      name=translate(name,'_','-');
      switch (lowcase(name)) {
      case '_open_form':
         return('_unixopen_form');
      case '_edit_form':
         return('_unixedit_form');
      }
      return(name);
   } else {
      if (!_DataSetSupport()) {
         return(name);
      }
      name=translate(name,'_','-');
      switch (lowcase(name)) {
      case '_open_form':
         return('_unixopen_form');
      case '_edit_form':
         return('_unixedit_form');
      }
      return(name);
   }
}

void _CenterIfFormNotVisible(int amon_wid=0,int parent=_app)
{
   if (!amon_wid) amon_wid=p_window_id;
   int screen_x,screen_y,screen_width,screen_height;
   amon_wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int tpx=_twips_per_pixel_x();
   int tpy=_twips_per_pixel_y();
   ppx := 720;
   ppy := 720;
   if (p_scale_mode==SM_PIXEL) {
      tpx=1;tpy=1;
      ppx=_lx2dx(SM_TWIP,ppx);
      ppy=_ly2dy(SM_TWIP,ppy);
   }
   if (p_x>=(screen_x+screen_width)*tpx-ppx ||
       p_x+p_width<screen_x*tpx+ppx ||
       p_y>=(screen_y+screen_height)*tpy-ppy ||
       p_y+p_height<screen_y*tpy+ppy
       ) {
      if (parent==VSWID_HIDDEN || parent.p_mdi_child || parent==_cmdline) {
         parent=_mdi;
      }
      _center_window(parent.p_active_form);
   }
}
/**
 * Displays a dialog box or menu you specify.
 * 
 * @return If the -modal option is given, the return value given to 
 * <b>_delete_window</b> is returned.  '' is returned if the dialog box is 
 * edited or destroyed during an <b>on_create</b> event.  
 * 
 * <p>If the -modal option is not given, the <b>int</b> form window id is 
 * returned if successful.  Otherwise, a negative error code is returned.</p>
 * 
 * @param cmdline is a string in the format: [<i>option</i>] <i>object_name</i>
 * 
 * @param option may be one of following:
 * 
 * <dl>
 * <dt>-mdi</dt><dd>Keep the form on top of the MDI Window.</dd>
 * 
 * <dt>-app</dt><dd>Keep the form on top of the SlickEdit 
 * Application Window.  This allows the MDI 
 * Window to be displayed on top of the form.</dd>
 * 
 * <dt>-desktop</dt><dd>Use the desktop as the form's parent. 
 * This allows the MDI Window to be displayed on top of the form.</dd> 
 * 
 * <dt>-xy</dt><dd>Restore the previous x, y position, width, 
 * and height of the dialog box.  If the old position can not be
 * found, the dialog box is centered.  When the dialog box is 
 * closed, the x, y position is automatically saved (the dialog 
 * manager calls <b>_save_form_xy</b>).</dd> 
 * 
 * <dt>-wh</dt><dd>Restore the previous width and height of the
 * dialog box.  This option is implied when you use 
 * the <tt>-xy</tt> option.</dd>
 * 
 * <dt>-span</dt><dd>When restoring the width and height of the 
 * dialog box, allow the dialog to span across the adjacent 
 * monitor to the right or below the originating monitor./dd> 
 * 
 * <dt>-hidden</dt><dd>Do not make the form visible.</dd>
 * 
 * <dt>-modal</dt><dd>Run the form modally.  All other forms are 
 * disabled.  Control returns to the caller when 
 * the form window is deleted with 
 * <b>_delete_window</b>.</dd>
 * 
 * <dt>-nocenter</dt><dd>Do not center the form.</dd>
 * 
 * <dt>-new</dt><dd>Normally when a form is already displayed, 
 * the existing form is given focus.  This option 
 * allows for multiple instances of a form to be 
 * displayed.</dd>
 * 
 * <dt>-reinit</dt><dd><b>UNIX only</b>. Ignored by other 
 * platforms.  Causes <b>_delete_window</b> 
 * function to make the form invisible instead of 
 * deleting the form.  The destroy events are 
 * dispatched even though no windows are 
 * actually destroyed.  Next time show is called 
 * for the same dialog box, the invisible dialog 
 * box is made visible, some properties are 
 * reinitialized, and the create events are sent.  
 * Be careful when using this option.  Not all 
 * dialog boxes can use this option without 
 * minor modifications.  The form_parent() 
 * function will not work because the next time 
 * the form is used, the parent is not changed to 
 * the new parent specified.</dd>
 * 
 * <dt>-hideondel</dt><dd><b>UNIX only</b>.  Same as -reinit option 
 * except no properties are reinitialized when the 
 * invisible dialog box is shown again.</dd>
 * </dl>
 * 
 * @param object_name specifies a form or menu resource.  If it is an integer, 
 * it must be a valid index into the names table of a form or menu.  
 * Otherwise, it should be the name of an existing form or menu that can 
 * be found in the names table.
 * 
 * <p>Currently, all <i>cmdline</i> arguments except <i>object_name</i> 
 * are ignored if <i>object_name</i> corresponds to a menu.</p>
 * 
 * <p>When a dialog box and all its objects are created, each object receives 
 * an <b>on_create</b> event.  The <b>on_create</b> event receives the 
 * <i>arg1, arg2...argN</i> arguments given to this function.  After the 
 * <b>on_create</b> events are sent, the form receives an 
 * <b>on_load</b> event.  You CAN NOT set the initial focus in an 
 * <b>on_create</b> event.  Use the <b>on_load</b> event to set the 
 * initial focus to a control other than the control with lowest tab index 
 * (<b>p_tab_index</b>) that is enabled and visible.</p>
 * 
 * @example
 * <pre>
 * // This example requires that you create a form called form1 
 * // with a command button and load this file.
 * #include "slick.sh"
 * _command mytest()
 * { 
 *     show('-modal form1', 
 *          'param1 to on_create',
 *          'param2 to on_create');
 * }
 * 
 * defeventtab form1;
 * command1.on_create(_str arg1="", _str arg2="")
 * {
 *     // Could get the arguments with the arg built-in
 *     //arg1=arg(1);
 *     //arg2=arg(2);
 *     messageNwait('arg1='arg1' arg2='arg2);
 * }
 * </pre>
 * 
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *     index=find_index('form1',oi2type(OI_FORM));
 *     if (!index) {
 *          messageNwait("form1 not found");
 *          return(1);
 *     }
 *     form_wid=show('-hidden -nocenter form1', 
 *                   'param1 to on_create', 
 *                   'param2 to on_create');
 *     if (form_wid<0) {
 *          return(1);
 *     }
 *     // Place the form at the top left corner of the 
 * display.
 *     form_wid.p_x=form_wid.p_y=0;
 *     // Make the form visible
 *     form_wid.p_visible=true;
 * }
 * </pre>
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Form_Functions, Menu_Functions
 * 
 */ 
_command typeless show(_str cmdline="", ...) name_info(OBJECT_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   orig_wid := p_window_id;
   _str arg1=prompt(cmdline,nls('Show form'));
   name := strip(arg1);
   options := "";
   name=strip_options(name,options);
   if (name=='') {
      popup_message(nls('Must specify name'));
      return(-1);
   }
   index := 0;
   if (isinteger(name)) {
      index=(int)name;
   } else {
      index=find_index(name,OBJECT_TYPE);
      if (!index) {
         popup_message(nls('Could not find form "%s"',name));
         //return(STRING_NOT_FOUND_RC)
         return(0);
      }
   }

   menu_handle := 0;
   width := 0;
   height := 0;
   screen_x := 0;
   screen_y := 0;
   screen_width := 0;
   screen_height := 0;
   x := y := 0;
   flags := 0;
   wid := 0;

   if (type2oi(name_type(index))==OI_MENU) {
      menu_handle=_menu_load(index,'P');
      _mdi._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
      x=screen_width intdiv 2;
      y=screen_height intdiv 2;
      x+=screen_x;y+=screen_y;
      call_list('_on_popup2_',translate(name_name(index),'_','-'),menu_handle);
      if (_isEditorCtl()) {
         call_list('_on_popup_',translate(name_name(index),'_','-'),menu_handle);
      }
      flags=VPM_CENTERALIGN|VPM_LEFTBUTTON;
      //messageNwait('h1');
      _menu_show(menu_handle,flags,x,y);
      _menu_destroy(menu_handle);
      return(0);
   }

   typeless result='';
   modal := 0;
   new_instance := 0;
   do_center := true;
   do_xy := false;
   do_wh := false;
   do_span := false;
   hidden := 'H';
   parent := p_window_id;
   keep_hidden := 0;
   showmodal := 0;
   set_focus := 1;
   hideondel := 0;
   // Determine active monitor from form of current window.
   amon := false;  
   int amon_wid=_mdi;
   option := "";
   load_template_as_child_form := "";

   for (;;) {
      parse options with option options ;
      if (option=='') break;
      uoption := upcase(option);
      switch (uoption) {
      case '-MODAL':
         modal=1;
         break;
      case '-MDI':
         parent=_mdi;
         break;
      case '-APP':
         parent=_app;
         amon=true;
         break;
      case '-CHILD':
         load_template_as_child_form='P';
         break;
      case '-DESKTOP':
         parent=_desktop;
         amon=true;
         break;
      case '-NEW':
         new_instance=1;
         break;
      case '-NOCENTER':
         do_center=false;
         do_xy=false;
         break;
      case '-XY':
         do_center=false;
         do_wh=false;
         do_xy=true;  // xy option does wh option when possible
         break;
      case '-SPAN':
         do_span=true;  // allow width/height to span to next monitor
         break;
      case '-WH':
         //do_center=false;
         do_xy=false;
         do_wh=true;
         break;
      case '-REINIT':
         if (_isUnix()) {
            //hideondel=IS_REINIT; not supported
         }
         break;
      case '-HIDEONDEL':
         if (_isUnix()) {
            //hideondel=IS_HIDEONDEL; not supported
         }
         break;
      case '-HIDDEN':
         keep_hidden=1;
         break;
      case '-SHOWMODAL':
         showmodal=1;
         break;
      case '-NOHIDDEN':
         hidden='';
#if 0
      default:
         if (substr(uoption,1,7)=='-PARENT') {
            parse uoption with ':' parent ;
            if (parent=='') {
               parent=orig_wid;
               if (parent.p_mdi_child || parent==_cmdline) {
                  parent=_mdi;
               }
            }
         }
#endif
      }
   }
   if (parent=='') {
      parent=_app;
   }
   if (!new_instance) {
      wid=_isloaded(index,'N');
      if (wid && wid.p_name==index.p_name){
         if (!hideondel && !wid.p_visible) {
            hideondel=wid.p_init_style&(IS_REINIT|IS_HIDEONDEL);
         }
         if (hideondel && !wid.p_visible) {
            hidden :+= 'W':+((hideondel==IS_REINIT)?'R':'');
            index=wid;
         } else {
            wid.p_enabled=true;
            wid.p_visible=true;
            wid._set_foreground_window();
            return((modal)?'':wid);
         }
      }
   } else if (hideondel) {
      wid=_isloaded(index,'N');
      if (wid && !wid.p_visible) {
         hidden :+= 'W':+((hideondel==IS_REINIT)?'R':'');
         index=wid;
      }
   }
   /* Switch parent to mdi frame if hideondel option given and */
   /* parent to be mdi child */
   if (hideondel && parent.p_mdi_child) {
      parent=_mdi;
   }
   if (parent==VSWID_HIDDEN) {
      parent=_mdi;
   }
   if (_isUnix()) {
      mou_hour_glass(true);
   }
   /*
     Qt does not support a modeless dialog which comes up
     after a modal dialog but is not parented to the modal
     dialog. Here we fudge the parent to be the modal dialog.
   */    
   if (index.p_border_style!=BDS_NONE) {
      int modal_wid=_ModalDialog();
      if (modal_wid && parent.p_active_form!=modal_wid) {
         parent=modal_wid;
      }
   }
   wid=_load_template(index,parent,load_template_as_child_form:+hidden'A',2); /* Hidden */
   if (_isUnix()) {
      mou_hour_glass(false);
   }
   if (wid<0) {
      popup_message(nls('Unable to open form %s',name)'.  'get_message(wid));
      return((modal)?'':wid);
   }
   // If window was deleted during on_create or on_load event.
   if (!_iswindow_valid(wid)) {
      if (modal) {
         result=_modal_wait(0);
         /* Restore the original window if it is valid.  It seems to be OK to do this
            when a form is edited and the result==''.  push_tag needs the window id
            restored even when escape is pressed.
         */
         if (_iswindow_valid(orig_wid)) {
            p_window_id=orig_wid;
         }
         return(result);
      }
      return(COMMAND_CANCELLED_RC);
      //return((modal)?'':COMMAND_CANCELLED_RC);
   }
   wid.p_init_style&= (IS_SAVE_XY|IS_REINIT|IS_HIDEONDEL);
   if (do_xy) {
      int status=wid._restore_form_xy(false,null,do_span);
      if (status) {
         do_center=true;
      }
      wid.p_init_style|=IS_SAVE_XY;
   } else if (do_wh) {
      wid._restore_form_xy(true,null,do_span);
      wid.p_init_style|=IS_SAVE_XY;
   }
   wid.p_init_style|=hideondel;
   /* If center form OR can't see the 1/2 inch of form */
   if (do_xy) {
      // Make sure the window is visible on any monitor
      wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   } else if (amon) {
      amon_wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   } else if (wid.p_parent) {
      // Make sure the window is visible on the parent windows monitor
      wid.p_parent._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   } else {
      // Make sure the window is visible on any monitor
      wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   }
   if (do_span) {
      _ScreenInfo screenInfo;
      wid._GetScreenInfo(screen_x+screen_width, screen_y+(screen_height intdiv 2), screenInfo);
      if (screenInfo.x == screen_x+screen_width) {
         screen_width += screenInfo.width;
      }
      wid._GetScreenInfo(screen_y+screen_height, screen_x+(screen_width intdiv 2), screenInfo);
      if (screenInfo.y == screen_y+screen_height) {
         screen_height += screenInfo.height;
      }
   }
   int tpx=_twips_per_pixel_x();
   int tpy=_twips_per_pixel_y();
   ppx := 720;
   ppy := 720;
   if (wid.p_scale_mode==SM_PIXEL) {
      tpx=1;tpy=1;
      ppx=_lx2dx(SM_TWIP,ppx);
      ppy=_ly2dy(SM_TWIP,ppy);
   }
   if (load_template_as_child_form=='' && 
       (do_center || wid.p_x>=(screen_x+screen_width)*tpx-ppx ||
        wid.p_x_extent<screen_x*tpx+ppx ||
        wid.p_y>=(screen_y+screen_height)*tpy-ppy ||
        wid.p_y_extent<screen_y*tpy-ppy
        )
       ) {
       if (parent==VSWID_HIDDEN /*|| parent.p_mdi_child || parent==_cmdline*/) {
          parent=_mdi;
       }
       if (parent.p_mdi_child) {
          wid._center_window(parent);
       } else {
          wid._center_window(parent.p_active_form);
       }
   }
   if (load_template_as_child_form=='' && wid.p_object!=OI_MENU) {
      wid._get_window(x,y,width,height);
      if( wid.p_border_style==BDS_SIZABLE) {
         _lxy2dxy(wid.p_xyscale_mode,width,height);
         if (width>screen_width) width=screen_width;
         if (height>screen_height) height=screen_height;
         _dxy2lxy(wid.p_xyscale_mode,width,height);
      }
      wid._move_window(x,y,width,height);
   }

   if (!wid.p_enabled) wid.p_enabled=true;
   if (showmodal || modal) {
      wid.p_ShowModal=true;
   }
   if (!keep_hidden) {
      wid.p_visible=true;
      focus := _get_focus();
      if (def_focus_select && focus && (focus.p_object==OI_TEXT_BOX || focus.p_object==OI_COMBO_BOX) && focus.p_auto_select) {
         focus._set_sel(1,length(focus.p_text)+1);
      }
   }
   result=wid;
   if (modal) {
      _str old_mark;
      mark_status := 1;
      if (_isWindows()) {
         if (isEclipsePlugin() && _isEditorCtl() && select_active()) {
            mark_status=save_selection(old_mark);
         }
      }
      result=_modal_wait(wid);
      if (_isWindows()) {
         if (isEclipsePlugin() && mark_status == 0) {
            restore_selection(old_mark);
         }
      }
      /* Restore the original window if it is valid.  It seems to be OK to do this
         when a form is edited and the result==''.  push_tag needs the window id
         restored even when escape is pressed.
      */
      if (_iswindow_valid(orig_wid)) {
         p_window_id=orig_wid;
      }
   }
   return(result);
}
static int _delete_undo_windows2(int wid)
{
   if (!wid.p_undo_visible) {
      wid._delete_window();
      return(0);
   }
   if (wid.p_child && wid.p_object!=OI_COMBO_BOX ){
      int first_child=wid.p_child;
      int child=first_child;
      int Nofchildren;
      for (Nofchildren=1;;++Nofchildren) {
         child=child.p_next;
         if (child==first_child) break;
      }
      child=first_child=wid.p_child;
      int i;
      for (i=1;i<=Nofchildren;++i) {
         int next=child.p_next;
         int status=_delete_undo_windows2(child);
         if (status) {
            return(status);
         }
         child=next;
      }
   }
   return(0);
}
void _delete_undo_windows()
{
   orig_wid := p_window_id;
   _delete_undo_windows2(p_active_form);
   p_window_id=orig_wid;
}
_str _set_undo_visible2(int wid, bool val)
{
   if (wid.p_selected) {
      if (val && _get_form(wid)._find_control(wid.p_name)) {
         wid._unique_name();
      }
      wid.p_undo_visible=val;
      if (val && wid.p_tab_index) {
         wid._unique_tab_index();
      }
      return(0);
   }
   return(0);
}
void _set_undo_visible(bool val)
{
   _for_each_control(_get_form(p_window_id),
                     '_set_undo_visible2','H',val);
}
_str _check_undo_visible2(int wid)
{
   if (!wid.p_undo_visible) {
      return(1);
   }
   return(0);
}
static _str _check_undo_visible()
{
   typeless status=_for_each_control(_get_form(p_window_id),
                     '_check_undo_visible2',
                     'H');
   return(status);
}




defeventtab _ainh_dlg_edit;

static int _deinc_selprop(int wid,_str pname,int add)
{
   if (wid.p_selected) {
      switch (pname) {
      case 'x':
         wid.p_x += add;
         break;
      case 'y':
         wid.p_y += add;
         break;
      case 'sx':
         if (_display_wid.p_width>_twips_per_pixel_x()*8) {
            wid.p_width += add;
         }
         break;
      case 'sy':
         if (_display_wid.p_height>_twips_per_pixel_y()*8) {
            wid.p_height += add;
         }
         break;
      }
   }
   return(0);
}
static void MoveControl(_str option, int add)
{
   // We used to attempt to accumulate repeats and perform the
   // operation in one fell swoop, but that does not work any more
   // because: 1) test_event is no longer used; 2) machines are
   // so fast that you would have to call delay(,'k') in order
   // to accumulate anything in the input queue. We will leave
   // count=1 here in case we want to pass in a count at some
   // point.
   count := 1;
   add= add*count;
   if (_deNofselected<=1) {
      _deinc_selprop(_display_wid,option,add);
   } else {
      _for_each_control(_display_wid.p_active_form,
                        _deinc_selprop,'',option,add);
   }
   _deupdate();
}
_ainh_dlg_edit.s_right()
{
   MoveControl('sx',_twips_per_pixel_x());
}
_ainh_dlg_edit.s_left()
{
   MoveControl('sx',-_twips_per_pixel_x());
}
_ainh_dlg_edit.s_up()
{
   MoveControl('sy',-_twips_per_pixel_y());
}
_ainh_dlg_edit.s_down()
{
   MoveControl('sy',_twips_per_pixel_y());
}
_ainh_dlg_edit.right()
{
   MoveControl('x',_twips_per_pixel_x());
}
_ainh_dlg_edit.left()
{
   MoveControl('x',-_twips_per_pixel_x());
}
_ainh_dlg_edit.up()
{
   MoveControl('y',-_twips_per_pixel_y());
}
_ainh_dlg_edit.down()
{
   MoveControl('y',_twips_per_pixel_y());
}
_ainh_dlg_edit.c_right()
{
   MoveControl('sx',-_twips_per_pixel_x());
   MoveControl('x',_twips_per_pixel_x());
}
_ainh_dlg_edit.c_left()
{
   MoveControl('sx',_twips_per_pixel_x());
   MoveControl('x',-_twips_per_pixel_x());
}
_ainh_dlg_edit.c_up()
{
   MoveControl('sy',_twips_per_pixel_y());
   MoveControl('y',-_twips_per_pixel_y());
}
_ainh_dlg_edit.c_down()
{
   MoveControl('sy',-_twips_per_pixel_y());
   MoveControl('y',_twips_per_pixel_y());
}
_ainh_dlg_edit.on_destroy2()
{
   if (p_window_id==p_active_form) {
      _save_form_xy();
   }
}
void _ainh_dlg_edit.rbutton_up()
{
   if (!p_selected){
      handle_i := 0;
      Nofselected := 0;
      selected_wid := 0;
      _move_selected('I',handle_i,Nofselected,selected_wid,0);
      //messageNwait('Nofselected='Nofselected);
      if (Nofselected && !(p_selected && Nofselected==1)){
         //messageNwait('reset');
         _reset_selected();
         Nofselected=0;
      }
      _dedisplay(p_window_id,1);
      p_selected=true;
   }
   p_window_id=p_active_form;
   last_event(RBUTTON_DOWN);
   mou_show_menu('_dlgedit_menu','R');
}
_command void vdlgedit_save() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!p_active_form.p_edit) return;
   save_form();
}
_command void vdlgedit_load(_str option='') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!p_active_form.p_edit) return;
   if (upcase(option)=='R') {
      _on_run();
      return;
   }
   _load_form();
   // Now for a visual effect.  Blink the handles on/off
   _deblink_selected();
}
_ainh_dlg_edit."s- ","c-s- "()
{
   _on_run();
}
_ainh_dlg_edit."c_l"()
{
   _load_form();
   // Now for a visual effect.  Blink the handles on/off
   _deblink_selected();
}
_ainh_dlg_edit.c_s,f2,a_w()
{
   save_form();
}
_ainh_dlg_edit.c_c,"m_c",a_v,pad_plus,c_ins()
{
   int status=_get_form(p_window_id)._copy_objects_to_clipboard();
   if (status) {
      popup_message(get_message(status));
   }
   // Now for a visual effect.  Blink the handles on/off
   _deblink_selected();
   return(status);
}


/**
 * Temporarily blinks the selection handles on all controls selected on the 
 * form including the form.  This function is used to help indicate to the 
 * user that a dialog editor operation completed.  This function should only 
 * be called to operate on forms that are being edited. (<b>p_edit</b> 
 * property non-zero).
 * 
 * @appliesTo  Form
 * @categories Miscellaneous_Functions
 */
void _deblink_selected()
{
   _reset_selected();
   _ignore_gotlost_focus=1;
   cancel := false;
   process_events(cancel);
   delay(10);
   //_get_form(p_window_id).refresh();
   _ignore_gotlost_focus=0;
   _restore_selected();
}
_ainh_dlg_edit.c_a()
{
   orig_wid := p_window_id;
   typeless wid=_defind_selected();
   if (!wid) {
      wid=p_window_id;
   }
   if (wid.p_object!=OI_FORM) {
      wid=wid.p_parent;
   }
   // IF there are no children
   if (!wid.p_child) {
      return('');
   }
   _reset_selected();
   int first_child=wid.p_child;
   int child=first_child;
   for (;;) {
      child.p_selected=true;
      child=child.p_next;
      if (child==first_child) break;
   }
   Nofselected := 0;
   _decount_selected(child,Nofselected);
   _dedisplay(first_child,Nofselected);
   return(0);
}
_ainh_dlg_edit.c_v,"m_v",c_y,ins,"s-ins"()
{
   if(!_clipboard_format(VSCF_VSCONTROLS,true) ){
      popup_message(nls('This type of clipboard may not be pasted'));
      return(1);
   }
   if (_display_wid && _display_wid.p_active_form==p_active_form) {
      p_window_id=_display_wid;
   }
   if (!p_undo_visible) {
      //_message_box('got here p_name='p_name);
      return('');
   }
   _delete_undo_windows();
   _deactivate_selected();
   if(p_object==OI_SSTAB) {
      p_window_id=_getActiveWindow();
   }
   _reset_selected();
   int status=_copy_from_clipboard();
   if (status) {
      popup_message(get_message(status));
      return status;
   }
   typeless wid=_get_form(p_window_id);
   wid=_defind_selected();
   if (wid) {
      p_window_id=wid;
      Nofselected := 0;
      _decount_selected(p_window_id,Nofselected);
      _dedisplay(p_window_id,Nofselected);
   }
   return(status);
}
_ainh_dlg_edit.c_x,"m_x",a_k,pad_minus,"s-del"()
{
   if (_get_form(p_window_id).p_selected) {
      popup_message("Sorry, cut form to clipboard not supported");
      return('');
   }
   int status=_get_form(p_window_id)._copy_objects_to_clipboard();
   if (status) {
      popup_message(get_message(status));
      return(status);
   }
   desafe_delete();
   return(0);
}
//static _str _got_focus=0
//static _str _lost_focus=0
void _ainh_dlg_edit.on_got_focus()
{
   if (_ignore_gotlost_focus) {
      return;
   }
   if (_display_wid==p_window_id) {
      // message 'same p_name='p_name;delay(300);clear_message
      return;
   }

   new_form := _get_form(p_window_id);
   int old_form=new_form;
   if (_display_wid) {
      old_form=_get_form(_display_wid);
   }
   if (new_form!=old_form) {
      _reset_selected(p_window_id);
      p_selected=true;
      _dedisplay(p_window_id,1);
      return;
   }
   // make sure something in this form is selected
   typeless wid=_defind_selected();
   if (!wid) {
      p_selected=true;
      _dedisplay(p_window_id,1);
      return;
   }
}
_ainh_dlg_edit.backspace,del()
{
   form_wid := _get_form(p_window_id);
   if (form_wid.p_selected) {
      int result=_message_box(nls("Delete form '%s'.  Are you sure? ",form_wid.p_name),'',MB_ICONQUESTION|MB_YESNOCANCEL);
      if (result==IDYES) {
         if (form_wid.p_template) {
            int status= form_wid.p_template;
            _set_object_modify(status);
            _config_modify_flags(CFGMODIFY_DELRESOURCE);
            delete_name(form_wid.p_template);
         }
         form_wid._delete_window();
         _dedisplay(0);
         _deselect_tool(DE_ARROW);
      }
      return('');
   }
   desafe_delete();
   // Under OS/2, an invisible window can have focus.
   _display_wid._set_focus();
}
static desafe_delete()
{
   _get_form(p_window_id).p_object_modify=true;
   typeless wid=_defind_selected();
   // For tab control, delete only the active tab unless it is the last
   // tab in the control.
   if (wid && wid.p_object==OI_SSTAB) {
      //say( "Deleting OI_SSTAB wid="wid" activeTab="wid.p_ActiveTab" NofTabs="wid.p_NofTabs );
      if ( wid.p_NofTabs >= 1 ) {
         int tabwindow;
         tabwindow = wid._getActiveWindow();
         int result = IDYES;
         if (tabwindow.p_child) {
            result=_message_box("You are about to delete the active tab which contains children controls.\nYou will not be able to undo this action.\n\nContinue to delete tab?",'',MB_ICONQUESTION|MB_YESNO);
         }
         if ( wid.p_NofTabs > 1 ) {
            if (result==IDYES) {
               wid._deleteActive();
               _deupdate();
            }
            return("");
         }
         if (result==IDNO) return("");
      }
   }
   int parent_wid=(wid)?wid.p_parent:0;
   if (parent_wid && parent_wid.p_object==OI_SSTAB_CONTAINER) {
      parent_wid = parent_wid.p_parent;
   }
   _delete_undo_windows();
   _set_undo_visible(false);
   if (parent_wid) {
      p_window_id=parent_wid;
      p_selected=true;
      _dedisplay(p_window_id,1);
      _deselect_tool(DE_ARROW);
   }
}
_ainh_dlg_edit.c_z,a_backspace()
{
   /* IF nothing to undo */
   if (!_check_undo_visible()) {
      return('');
   }
   _reset_selected();
   _set_undo_visible(true);
   typeless wid=_defind_selected();
   if (wid) {
      p_window_id=wid;
      Nofselected := 0;
      _decount_selected(p_window_id,Nofselected);
      _dedisplay(p_window_id,Nofselected);
   }
}
_ainh_dlg_edit.tab()
{
   _deactivate_selected();
   _reset_selected();
   _denext_control();
   p_selected=true;
   _dedisplay(p_window_id,1);
   _set_focus();
}
_ainh_dlg_edit.s_tab()
{
   _deactivate_selected();
   _reset_selected();
   _deprev_control(/*'P'*/);
   p_selected=true;
   _dedisplay(p_window_id,1);
}
//returns the property sheet id if the only things left are the psheet and 1 form
static void _propsheet_info(int &prop_wid, int &Nofedited_forms)
{
   int last=_last_window_id();
   Nofedited_forms=0;prop_wid=0;
   i := 0;
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) ) {
         if (i.p_object==OI_FORM && i.p_edit) {
            ++Nofedited_forms;
         }else if (i.p_name=='_dlge_form') {
            prop_wid=i;
         }
      }
   }
}

_ainh_dlg_edit.A_F4,on_close()
{
   p_window_id=p_active_form;
   if (p_object_modify) {
      int result=_message_box(nls("Save changes to form '%s'?",p_name),'',MB_ICONQUESTION|MB_YESNOCANCEL);
      if (result==IDYES) {
         int status=p_active_form._update_template();
         if (!status) {
            status=INSUFFICIENT_MEMORY_RC;
            _message_box(nls("Failed to update form '%s'.",p_active_form.p_name)"\n\n"get_message(status));
            return(status);
         }
         _set_object_modify(status);
         status=save_config(1);
         if (status) {
            return('');
         }
         p_object_modify=false;
         form_wid := p_active_form;
      } else if (result==IDCANCEL){
         return('');
      }
   }
   ps_wid := 0;
   Nofedited_forms := 0;
   _propsheet_info(ps_wid,Nofedited_forms);
   // Should check whether we need to save here.
   //say('close 'p_active_form.p_name);
   p_active_form._delete_window();
   _dedisplay(0);
   _deselect_tool(DE_ARROW);
   if (Nofedited_forms<=1 && ps_wid) {//Delete property sheet if necessary
      ps_wid._delete_window();
   }
}
_ainh_dlg_edit.on_resize()
{
   if (p_object==OI_FORM && p_selected) {
      _deupdate();
   }
}
_ainh_dlg_edit."c-lbutton-down","s-lbutton-down","s-lbutton-double-click","s-lbutton-triple-click"()
{
   handle_i := 0;
   Nofselected := 0;
   selected_wid := 0;
   _move_selected('I',handle_i,Nofselected,selected_wid);
   if (Nofselected && selected_wid.p_parent!=p_parent) {
      _reset_selected();
      Nofselected=0;
   }
   p_selected=!p_selected;
   if (!Nofselected && !p_selected) {
      _dedisplay(0);
      return('');
   }
   if (p_selected) {
      _dedisplay((Nofselected>=1)?_display_wid:p_window_id,
                  Nofselected+1);
   } else {
      if (Nofselected-1<=0) {
         _dedisplay(0);
         return('');
      }
      typeless wid=_display_wid;
      if (p_window_id==_display_wid) {
         wid=_defind_selected();
      }
      _dedisplay(wid,Nofselected-1);
   }
}

_ainh_dlg_edit.lbutton_double_click()
{
   if( p_object == OI_SSTAB ) {
      return('');
   }
    if( _deNofselected && _deNofselected != 1 ){
       _reset_selected();
    }
    p_selected = true;
   _dedisplay(p_window_id,1);
   _select_event();
}

/*
   Case analysis.

   Move Selected handles cases 1 and 2a.

      1.  Mouse is in handle and only one control is selected.
          handle_i is set to non-zero value.  selected_wid
          is set to handle of window selected.  Use _draw_rect to
          size the control.

      2.  Mouse is on control.

          handle_i is set to zero.

        2a. Mouse is on form and !_decreate_mode()

            Turn off selected.  If controls are inside rectangle,
            select them.  Otherwise, select form.

            handle_i is set to zero.  Call _draw_rect to draw
            dotted selection rectangle.

        2b. Mouse is on (form or frame) and _decreate_mode()

            Turn off selected.   If user escapes, select form or
            frame.  Otherwise select new object created.

            handle_i is set to zero.  Call _draw_rect to draw thick
            resize frame.

        2c. Not case 2a or 2b

            If no controls selected, turn of selected and select this
            control.

            Subseqent calls to _move_selected, will move the selected
            control(s).

*/
_ainh_dlg_edit.lbutton_down()
{
   handle_i := 0;
   Nofselected := 0;
   color := 0;
   color=_rgb(0x80,0x80,0x80)  /* Gray */;
   selected_wid := 0;
   _move_selected('I',handle_i,Nofselected,selected_wid,color);
   //message 'handle_i='handle_i' Nofselected='Nofselected' selected_wid='selected_wid' name='selected_wid.p_name
   /* if (p_cb ) p_window_id=p_cb; */
#if 0
   if (p_object!=OI_FORM && Nofselected!=1) {
      p_selected=!p_selected
      _get_form(p_window_id).refresh
   }
#endif
   /* If current control is part of a combo box, activate the combo box */
   /* window. */

   typeless status=0;
   _ignore_gotlost_focus=1;
   if (handle_i) {
      if (_decreate_mode()) {
         _deselect_tool(DE_ARROW);
      }
      status=_size_control(handle_i,selected_wid);
      _deupdate();
      _ignore_gotlost_focus=0;
      return(status);
   }

   form_wid := _get_form(p_window_id);
   rect_style := "";
   if(p_object==OI_FORM && !_decreate_mode()){
      /* User is selecting rectangle of controls or selecting form. */
      select_controls();
      _ignore_gotlost_focus=0;
      return(0);
   } else if((p_object==OI_FORM || p_object==OI_FRAME ||
              p_object==OI_SSTAB ||
      p_object==OI_PICTURE_BOX) && _decreate_mode()){
      if (Nofselected && !(p_selected && Nofselected==1)){
         _reset_selected();
      }
      _decreate_control(Nofselected);
      if (_decreate_mode()) {
         _deselect_tool(DE_ARROW);
      }
      /* _dedisplay(p_window_id) */
      _ignore_gotlost_focus=0;
      return(0);
   }
   if (_decreate_mode()) {
      _deselect_tool(DE_ARROW);
   }
   sstabClickProcessed := false;
   int mx, my;
   mou_get_xy(mx,my);
   if( p_object == OI_SSTAB && _xyHitTest(mx,my) >= 0 ) {
      // User pressed a tab
      sstabClickProcessed = true;
   }
   do_dedisplay := 0;
   if (!p_selected){
      if (Nofselected && !(p_selected && Nofselected==1)){
         _reset_selected();
         Nofselected=0;
         _move_selected('I',handle_i,Nofselected,selected_wid,color);
      }
      do_dedisplay=p_window_id;
   }
   // Capture mouse here to avoid, extra set focus
   // caused by "_get_form(p_window_id).refresh".
   // Don't think it matters because if control is
   // already selected, nothing happens.
   mou_capture();
   if (Nofselected<=1) {
      p_selected=false;
      _get_form(p_window_id).refresh('w');
   }
   /* Control(s) are being moved */
   orig_wid := p_window_id;
   p_window_id=p_parent;
   form_modify := _get_form(p_window_id).p_object_modify;
   parent_modify := p_object_modify;
   old_mouse := "";
   event := "";
   done := false;
   int mou_x=mou_last_x();
   int mou_y=mou_last_y();
   int old_x=orig_wid.p_x;
   int old_y=orig_wid.p_y;
   p_window_id=orig_wid.p_parent;
   if (sstabClickProcessed) {
      _deupdate();
   } else {
      if (_isDragDrop(mou_last_x(),mou_last_y())) {
         mou_mode(1);
         for (;;) {
            event=get_event();
            switch (event) {
            case MOUSE_MOVE:
               if (old_mouse!='' || abs(mou_x-mou_last_x())>1 || abs(mou_y-mou_last_y())>1){
                  if (old_mouse=='') {
                     /* Limit the range of movement of the mouse. */
                     mou_limit(0,0,p_client_width,p_client_height);
                     old_mouse=p_mouse_pointer;
                  }
      #if DLGEDITV_CHANGE_MOUSE_ON_MOVE
                  if (p_mouse_pointer!=5) {
                     p_mouse_pointer=5;
                     mou_set_pointer(p_mouse_pointer)
                  }
      #endif
                  _move_selected();
               }
               break;
            case LBUTTON_UP:
            case ESC:
               done=true;
            }
            if (done) break;
         }
         mou_mode(0);
         mou_limit(0,0,0,0);
      }
   }

#if DLGEDITV_CHANGE_MOUSE_ON_MOVE
   if (old_mouse!='') {
      p_mouse_pointer=old_mouse
   }
#endif
   mou_release();
   if (orig_wid.p_x==old_x && orig_wid.p_y==old_y && !form_modify) {
      _get_form(p_window_id).p_object_modify=false;
      /* messageNwait('got here') */
   } else {
      /* messageNwait('old_x='old_x' old_y='old_y' new_x='orig_wid.p_x' new_y='orig_wid.p_y) */
   }
   p_window_id=orig_wid;
   if (!p_selected) {
      p_selected=true;
   }
   _ignore_gotlost_focus=0;
   /* _check_modify() */
   if (do_dedisplay) {
      // This is sort of a hack.  This test_event causes
      // The X windows version to check for lbutton_double_click
      // now.  Testting for it after the call to do_dedisplay._dedisplay
      // takes up too much time so loose double click.
      //
      // !!This test_event call has been removed because it looks like we
      // have improved the performance enough that we do not need this call.
      //   test_event('r');
      do_dedisplay._dedisplay(p_window_id,1);
   }
   return(0);
}
_str _size_control(int handle_i,int selected_wid)
{
   child_modify := selected_wid.p_object_modify;
   orig_wid := p_window_id;
   /* Limit the range of movement of the mouse to form or frame. */
   p_window_id=selected_wid.p_parent;


   color := 0;
   color=_rgb(0x80,0x80,0x80)  /* Gray */;
   color=_rgb(0xff,0xff,0xff);
   //color=_rgb(0xf8,0xf8,0xf8);
   /*color=_rgb(0xC5,0xC5,0xC5);
   color=_rgb(0x33,0x33,0x33);
   color=_rgb(0xC0,0xC0,0xC0); */
   //color=_rgb(0x55,0x55,0x55);

   mou_mode(1);
   mou_capture();
   int morig_x=mou_last_x('M');
   int morig_y=mou_last_y('M');
   done := false;
   orig_x := 0;
   orig_y := 0;
   orig_width := 0;
   orig_height := 0;
   selected_wid._get_window(orig_x,orig_y,orig_width,orig_height);
   int x1=orig_x;
   int y1=orig_y;
   int x2=x1+orig_width;
   int y2=y1+orig_height;
   int orig_x1=x1;
   int orig_y1=y1;
   int orig_x2=x2;
   int orig_y2=y2;
   new_x1 := 0;
   new_y1 := 0;
   new_x2 := 0;
   new_y2 := 0;
   //grid_x=60;grid_y=60;
   int smallest_width=_HANDLE_WIDTH*2;
   int smallest_height=_HANDLE_HEIGHT*2;
   _lxy2lxy(SM_TWIP,p_scale_mode,smallest_width,smallest_height);
   mou_limit(0,0,p_client_width,p_client_height);
   event := "";
   for (;;) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         new_x1=x1;new_y1=y1;new_x2=x2;new_y2=y2;
         switch (handle_i) {
         case 1:
            new_x1=orig_x1+mou_last_x('M')-morig_x;
            new_y1=orig_y1+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x1,new_y1,orig_x1,orig_y1);
            break;
         case 2:
            new_y1=orig_y1+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x1,new_y1,orig_x1,orig_y1);
            break;
         case 3:
            new_x2=orig_x2+mou_last_x('M')-morig_x;
            new_y1=orig_y1+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x2,new_y1,orig_x2,orig_y1);
            break;
         case 4:
            new_x2=orig_x2+mou_last_x('M')-morig_x;
            _grid_roundxy(new_x2,new_y2,orig_x2,orig_y2);
            break;
         case 5:
            new_x2=orig_x2+mou_last_x('M')-morig_x;
            new_y2=orig_y2+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x2,new_y2,orig_x2,orig_y2);
            break;
         case 6:
            new_y2=orig_y2+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x2,new_y2,orig_x2,orig_y2);
            break;
         case 7:
            new_x1=orig_x1+mou_last_x('M')-morig_x;
            new_y2=orig_y2+mou_last_y('M')-morig_y;
            _grid_roundxy(new_x1,new_y2,orig_x1,orig_y2);
            break;
         case 8:
            new_x1=orig_x1+mou_last_x('M')-morig_x;
            _grid_roundxy(new_x1,new_y1,orig_x1,orig_y1);
            break;
         }
         if (new_x2-new_x1<smallest_width) {
            new_x1=x1;new_x2=x2;
         }
         if (new_y2-new_y1<smallest_height) {
            new_y1=y1;new_y2=y2;
         }
         x1=new_x1;y1=new_y1;x2=new_x2;y2=new_y2;
         selected_wid._move_window(x1,y1,x2-x1,y2-y1);
         break;
      case LBUTTON_UP:
      case ESC:
         done=true;
      }
      if( done) break;
   }
   mou_limit(0,0,0,0);
   mou_mode(0);
   mou_release();
   new_x := 0;
   new_y := 0;
   new_width := 0;
   new_height := 0;
   selected_wid._get_window(new_x,new_y,new_width,new_height);
   if (event==ESC || (new_x==orig_x && new_y==orig_y &&
        new_width==orig_width && new_height==orig_height)) {
      selected_wid._move_window(orig_x,orig_y,orig_width,orig_height);
      selected_wid.p_object_modify=child_modify;
      //message 'parent_modify='parent_modify' child_modify='child_modify
      //message 'modify='_get_form(p_window_id).p_object_modify
   } else {
      selected_wid.p_object_modify=true;
   }
   p_window_id=orig_wid;
   return(0);
}


#if 0
_str _fill_list_boxes2(wid)
{
   if (wid.p_object==OI_LIST_BOX) {
      for (i=1;i<=20;++i) {
         wid.insert_line(">i="i)
      }
      wid.top()
   } else if (wid.p_object==OI_COMBO_BOX) {
      wid=wid.p_cb_list_box
      for (i=1;i<=20;++i) {
         wid.insert_line(" i="i)
      }
      wid.top()
   }
   return(0)
}
static _str _fill_list_boxes()
{
   _for_each_control(_get_form(p_window_id),'_fill_list_boxes2','')
}
#endif
#if 0
_str _check_modify2(wid)
{
   if (wid.p_object_modify) {
      messageNwait('modify on name='wid.p_name)
   }
   return(0)
}
_str _check_modify()
{
   _for_each_control(_get_form(p_window_id),'_check_modify2','')
}
#endif
int _round(int x, int r)
{
   return(((x+(r>>1)) intdiv r)*r);
}
static void _grid_roundxy(int &x, int &y, int orig_x, int orig_y)
{
   _lxy2lxy(p_scale_mode,SM_TWIP,x,y);
   _lxy2lxy(p_scale_mode,SM_TWIP,orig_x,orig_y);
   x=_grid_round(x,orig_x,_grid_width());
   y=_grid_round(y,orig_y,_grid_height());
   _lxy2lxy(SM_TWIP,p_scale_mode,x,y);
}
static int _grid_round(int x, int orig_x, int r)
{
   if (r<=1) return(x);
   int rx=((x+(r>>1)) intdiv r)*r;
   diff_x := 0;
   if (rx<orig_x && rx+r>orig_x) {
      diff_x=(orig_x-rx)>>1;
      if (x+diff_x>=orig_x) {
         rx=orig_x;
      }
   } else if (rx>orig_x && rx-r<orig_x){
      diff_x=(rx-orig_x)>>1;
      if (x-diff_x<orig_x) {
         rx=orig_x;
      }
   }
   return(rx);
}

static _str _decreate_control(int Nofselected)
{
   // Translate SSTAB control into the active tab window:
   if (p_window_id.p_object==OI_SSTAB) {
      p_window_id = p_window_id._getActiveWindow();
   }
   orig_wid := p_window_id;
   //typeless draw_setup;
   //_save_draw_setup(draw_setup);


   //p_fill_style=PSFS_TRANSPARENT;
   //p_draw_width=2;p_draw_style=PSDS_SOLID;p_draw_mode=PSDM_XORPEN;
   //int color=0;
   //color=_rgb(0x80,0x80,0x80)  /* Gray */;

   /* Limit the range of movement of the mouse to form or frame. */
   mou_mode(1);
   mou_capture();
   int orig_x=mou_last_x('M');
   int orig_y=mou_last_y('M');
   _lxy2lxy(p_scale_mode,SM_TWIP,orig_x,orig_y);
   orig_x=_round(orig_x,_grid_width());
   orig_y=_round(orig_y,_grid_height());
   _lxy2lxy(SM_TWIP,p_scale_mode,orig_x,orig_y);
   int x=orig_x;
   int y=orig_y;
   done := false;
   int min_width=_HANDLE_WIDTH*2;
   int min_height=_HANDLE_HEIGHT*2;
   _reset_selected();
   int new_wid=_create_control(0,_deobject_name,0,orig_x,orig_y,min_width,min_height);
   new_wid.p_object_modify=true;
   p_window_id=orig_wid;
   event := "";
   mou_limit(0,0,p_client_width,p_client_height);
   for (;;) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         int new_x=mou_last_x('M');
         int new_y=mou_last_y('M');
         _lxy2lxy(p_scale_mode,SM_TWIP,new_x,new_y);
         new_x=_round(new_x,_grid_width());
         new_y=_round(new_y,_grid_height());
         _lxy2lxy(SM_TWIP,p_scale_mode,new_x,new_y);
         if (new_x==x && new_y==y) {
            continue;
         }
         x=new_x;y=new_y;

         int start_x=orig_x;
         int start_y=orig_y;
         int width=x-orig_x;
         int height=y-orig_y;
         if (width<0) {
            start_x=x;width= -width;
         }
         if (height<0) {
            start_y=y;height= -height;
         }
         if (width<min_width) width=min_width;
         if (height<min_height) height=min_height;
         new_wid._move_window(start_x,start_y,width,height);

         break;
      case LBUTTON_UP:
      case ESC:
         done=true;
      }
      if( done) break;
   }
   mou_mode(0);
   mou_release();
   mou_limit(0,0,0,0);
   p_window_id=new_wid;
   p_selected=true;
   _dedisplay(p_window_id,1);
   //orig_wid._restore_draw_setup(draw_setup);
   return(0);
}
static _str select_controls()
{
   old_object_modify := p_object_modify;
   /* Limit the range of movement of the mouse to form or frame. */
   mou_mode(1);
   mou_capture();

   int orig_x=mou_last_x('M');
   int orig_y=mou_last_y('M');
   int x=orig_x;
   int y=orig_y;
   rectangle_drawn := false;
   int mou_x=mou_last_x();
   int mou_y=mou_last_y();
   done := false;
   event := "";
   mou_limit(0,0,p_client_width,p_client_height);
   orig_wid:=p_window_id;
   sc.controls.RubberBand rubberBand;
   p_window_id=orig_wid;
   for (;;) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         if (rectangle_drawn || abs(mou_x-mou_last_x())>3 || abs(mou_y-mou_last_y())>3){
            int new_x=mou_last_x('M');
            int new_y=mou_last_y('M');
            int px1,py1,px2,py2;
            px1=orig_x;py1=orig_y;
            px2=new_x;py2=new_y;
            // Need pixels for the desktop
            _lxy2dxy(SM_TWIP,px1,py1);
            _lxy2dxy(SM_TWIP,px2,py2);
            //_lxy2dxy(SM_TWIP,tab_x,tab_y);
            //_lxy2dxy(SM_TWIP,tab_w,tab_h);
            // Map to desktop coordinates
            _map_xy(p_window_id,0,px1,py1,SM_PIXEL);
            _map_xy(p_window_id,0,px2,py2,SM_PIXEL);
            //_map_xy(relativeToWid.p_xyparent,0,tab_x,tab_y,SM_PIXEL);
            //_map_xy(relativeToWid.p_xyparent,0,tab_w,tab_h,SM_PIXEL);
            rectangle_drawn=true;
            if (px2<px1) {
               temp:=px1;
               px1=px2;px2=temp;
            }
            if (py2<py1) {
               temp:=py1;
               py1=py2;py2=temp;
            }
            rubberBand.setWindow(px1,py1,px2-px1,py2-py1);
            if( !rubberBand.isVisible() ) {
               rubberBand.setVisible(true);
            }
            p_window_id=orig_wid;
            //_draw_rect(orig_x,orig_y,new_x,new_y,color,0,'E');
            x=new_x;y=new_y;
         }
         break;
      case LBUTTON_UP:
      case ESC:
         done=true;
      }
      if( done) break;
   }
   mou_limit(0,0,0,0);
   mou_mode(0);
   mou_release();
   if (rectangle_drawn) {
      rubberBand.destroy();
      p_window_id=orig_wid;
      //_draw_rect(orig_x,orig_y,x,y,color,0,'E');
   }
   p_object_modify=old_object_modify;
   if (rectangle_drawn) {
      /* Erase the rectangle. */
      Nofselected := 0;
      _select_controls_in(orig_x,orig_y,x,y,Nofselected);
      _reset_selected();
      if (Nofselected) {
         p_window_id=(typeless)_select_controls_in(orig_x,orig_y,x,y,Nofselected,'S');
      } else {
         p_selected=true;
         Nofselected=1;
      }
      _dedisplay(p_window_id,Nofselected);
   } else {
      _reset_selected(p_window_id);
      p_selected=true;
      _dedisplay(p_window_id,1);
   }
   return(0);
}
static bool _rects_intersect(int wx1, int wy1, int wx2, int wy2,
                                int x1,  int y1,  int x2,  int y2)
{
   return(!(x2<wx1 || x1>wx2 || y2<wy1 || y1>wy2));
}
static _str _select_controls_in(int x1, int y1,
                                int x2, int y2, 
                                var Nofselected,
                                _str option="")
{
   temp := 0;
   if (x1>x2) {
      temp=x1;x1=x2;x2=temp;
   }
   if (y1>y2) {
      temp=y1;y1=y2;y2=temp;
   }
   typeless selected_wid='';
   Nofselected=0;
   int first_wid=p_child;
   int wid=first_wid;
   if (!wid) return(selected_wid);
   for (;;) {
      wx1 := 0;
      wy1 := 0;
      width := 0;
      height := 0;
      wid._get_window(wx1,wy1,width,height);
      int wx2=wx1+width;
      int wy2=wy1+height;
      if (wid.p_undo_visible && _rects_intersect(wx1,wy1,wx2,wy2,x1,y1,x2,y2)) {
         ++Nofselected;
         selected_wid=wid;
         if (option=='S') {
            wid.p_selected=true;
         }
      }
      wid=wid.p_next;
      if (wid==first_wid) break;
   }
   return(selected_wid);
}
static int _create_control(int parent_wid,
                            _str object_name, int flags,
                            int x=0, int y=0, 
                            int width=0, int height=0)
{
   /* IF window rectangle given. */
   if (p_edit) {
      _delete_undo_windows();
   }
   typeless object=eq_name2value(object_name,DEBITMAP_LIST);
   form_wid := 0;
   if (width>0 && height>0) {
      if (!parent_wid) {
         parent_wid=p_window_id;
      }
   } else {
      if (parent_wid) {
         form_wid=parent_wid;
      } else {
         form_wid=_get_form(p_window_id);
      }
      parent_wid=form_wid;
      switch (object) {
      case OI_COMMAND_BUTTON:
         width=1125;height=345;
         break;
      case OI_CHECK_BOX:
      case OI_RADIO_BUTTON:
         width=1400;height=262;
         break;
      case OI_LIST_BOX:
         width=2000;height=1400;
         break;
      case OI_EDITOR:
         width=2000;height=1400;
         break;
      case OI_TEXT_BOX:
      case OI_FRAME:
      case OI_LABEL:
      case OI_COMBO_BOX:
      case OI_PICTURE_BOX:
      case OI_IMAGE:
      case OI_SPIN:
      case OI_GAUGE:
         width=1400;height=700;
         break;
      case OI_HSCROLL_BAR:
         width=1400;height=300;
         break;
      case OI_VSCROLL_BAR:
         width=300;height=1400;
         break;
      case OI_TREE_VIEW:
         width=2000;height=1400;
         break;
      case OI_MINIHTML:
         width=2000;height=1400;
         break;
      case OI_SSTAB:
         width=2200;height=1500;
         break;
      case OI_SWITCH:
         // Does not really matter since OI_SWITCH is always autosized
         width = 1500;
         height = 300;
         break;
      }
      int cwidth=parent_wid.p_client_width;
      int cheight=parent_wid.p_client_height;
      _dxy2lxy(SM_TWIP,cwidth,cheight);
      x=(cwidth-width) intdiv 2;
      y=(cheight-height) intdiv 2;
      x=_round(x,_grid_width());
      y=_round(y,_grid_height());

      _lxy2lxy(SM_TWIP,parent_wid.p_scale_mode,x,y);
      _lxy2lxy(SM_TWIP,parent_wid.p_scale_mode,width,height);
   }
   int wid=_create_window(object,parent_wid,"",x,y,width,height,CW_CHILD|CW_EDIT|flags/*|CW_HIDDEN*/);
   // Create the first tab for the control:
   if (wid && object==OI_SSTAB) {
      int cwid=_create_window(OI_SSTAB_CONTAINER,wid,"",100,100,100,100,
               CW_CHILD);
      _deactivate_selected();
      _reset_selected();
      parent_wid.p_selected = false;
      p_window_id = wid;
      // OI_SSTAB_CONTAINER is always created hidden, so set p_ActiveTab to
      // force it visible.
      p_ActiveTab = p_NofTabs - 1;
      p_ActiveCaption = "NewTab";
      p_ActiveEnabled=true;
      p_selected=true;
   }
   //wid.p_visible=true;
   if (wid) {
      wid._deinit_object(object_name);
   }
   return(wid);
}
void _deinit_object(_str object_name)
{
   index := 0;
   _unique_tab_index();
   _unique_name();
   if (p_edit) {
      // Might want to make this case sensitive in the future.
      switch (lowcase(object_name)) {
      case DE_EDIT_WINDOW:
         p_scroll_bars=SB_BOTH;
         break;
      case DE_TEXT_BOX:
      case DE_COMBO_BOX:
         p_text=p_name;
         break;
      case DE_COMMAND_BUTTON:
      case DE_RADIO_BUTTON:
      case DE_CHECK_BOX:
      case DE_FRAME:
      case DE_LABEL:
         p_caption=p_name;
         break;
      case DE_SSTAB:
         p_tab_stop = true;
         p_Orientation = SSTAB_OTOP;
         //p_PaddingX = 4;
         //p_PaddingY = 4;
         break;
      case DE_TREE_VIEW:
         p_SpaceY=50;
         p_LevelIndent=50;
         p_LineStyle=TREE_SOLID_LINES;
         p_after_pic_indent_x=50;
         break;
      case DE_SWITCH:
         p_value = 1;
         break;
      }
      typeless object=eq_name2value(object_name,DEBITMAP_LIST);
      _str ul2_etab_name=eq_name2value(object_name,DEBITMAP_2_UL2_LIST);
      index=0;
      if (ul2_etab_name!='') {
         index=find_index(ul2_etab_name,EVENTTAB_TYPE);
      }
      p_eventtab2=index;
      if (index) {
         call_event(p_window_id,ON_CREATE2,'');
      }
      //message 'index='index' object_name='object_name
   }
   if (p_object==OI_FORM) {
      index=find_index(p_name,EVENTTAB_TYPE);
   } else {
      index=find_index(_get_form(p_window_id).p_name'.'p_name,EVENTTAB_TYPE);
   }
   p_eventtab=index;
}
static int _defind_selected2(int wid)
{
   if (wid.p_selected) {
      return(wid);
   }
   return(0);
}
/*
    Returns window id of first window with p_selected!=0.  If
    no windows are selected, zero is returned.
*/
static _str _defind_selected()
{
   wid := _for_each_control(_get_form(p_window_id),_defind_selected2);
   return(wid);
}
static void _deactivate_selected()
{
   if (p_selected) return;
   typeless wid=_defind_selected();
   if (wid) {
      p_window_id=wid;
   }
   return;
}
static _decount_selected(int first_child, int &Nofselected)
{
   Nofselected=0;
   int child=first_child;
   for (;;) {
      if (child.p_selected) {
         ++Nofselected;
      }
      child=child.p_next;
      if (child==first_child) break;
   }
}
/**
 * Displays the dialog editor properties form.  If  the dialog editor 
 * properties form is already displayed, it is brought to the front of the 
 * window Z-order and given input focus.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void show_properties(_str showSelected='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return;
   }
   if (showSelected=='') {
      show_selected(1);
   }
   typeless wid=show('-app _dlge_form -xy');
   //refresh();
}
int _OnUpdate_show_selected(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveProMacros()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!_display_wid) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Brings the selected form being edited with the dialog editor to the 
 * front of the window Z-order and gives it the input focus.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void show_selected(_str showProperties='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return;
   }
   if (_display_wid) {
      if (showProperties=='') {
         show_properties(1);
      }
      p_window_id=_display_wid;
      _set_focus(); //refresh();
   }
}
static _str _source_form_name()
{
   if (!p_HasBuffer || (p_window_flags & HIDE_WINDOW_OVERLAP) ||
        !_file_eq('.'_get_extension(p_buf_name),_macro_ext)) {
      return('');
   }
   save_pos(auto p);
   top();
   int status=search('^[ \t]*defeventtab[ \t]#{[a-zA-Z_$][a-zA-Z0-9_$]@}([~a-zA-Z0-9_$]|$)','@ri');
   restore_pos(p);
   if (!status) {
      _str word=get_text(match_length('0'),match_length('s0'));
      int index=find_index(word,oi2type(OI_FORM));
      if (index) {
         return(word);
      }
   }
   return('');

}
_str def_auto_load=1;

static void qrebind_shift_space()
{
   if (_no_child_windows()) {
      _message_box(nls("No form is selected."));
      return;
   }
   int result=_message_box(nls("No form Selected.\n\nYou have pressed Shift-Space Bar.\n\nThis key binding is intended for macro development.\n\nWould you like to rebind it to insert a space now?"),
                       '',
                       MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result==IDYES) {
      int sspace_index=event2index(name2event('S- '));
      command_index := find_index('keyin-space',COMMAND_TYPE);
      if (!command_index) {
         _message_box(nls("Could not rebind key."));
         return;
      }
      set_eventtab_index(_default_keys,sspace_index,command_index);
      _config_modify_flags(CFGMODIFY_KEYS);
   }
}
int _OnUpdate_run_selected(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveProMacros()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!_display_wid) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Runs the form that is selected in the dialog editor.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command run_selected() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   form_name := "";
   status := 0;
   if (!_display_wid) {
      form_name=_source_form_name();
      if (form_name=='') {
         //_message_box(nls('No form is selected'))
         qrebind_shift_space();
         return(1);
      }
      if (def_auto_load) {
         // Only load macros with "defeventtab form_name????
         status=load_all(form_name);
         if (status) {
            return(status);
         }
      }
      _post_call(_run_selected2,form_name);
      return(0);
   }
   int form_wid=_display_wid.p_active_form;
   if (def_auto_load) {
      // Only load macros with "defeventtab form_name????
      status=load_all(form_wid.p_name);
      if (status) {
         return(status);
      }
   }
   // If (edited form modified or new form that was not saved) AND
   // failed loading form.
   if((form_wid.p_object_modify || !(form_wid.p_template)) &&
      _display_wid._load_form()) {
      return(1);
   }
   _post_call(_run_selected2,form_wid);
   return(0);
}

/**
 * Displays and optionally sets the grid width and height used by the dialog 
 * editor.  This affects the distance displayed between the dots displayed on a 
 * form that is being edited.  The <b>Grid dialog box</b> is displayed which 
 * prompts you for the width and height.  The <i>width</i> and <i>height</i> 
 * parameters are in twips (1440 twips are one inch on the display).
 * 
 * @see grid
 * @see _grid_height
 * @see _grid_width
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command gui_grid() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Form editing");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int was_recording=_macro();
   _macro_delete_line();
   typeless result = show('-modal _grid_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',was_recording);
   _str argmnt = _grid_width()' '_grid_height();
   _macro_call('grid', argmnt);
}

defeventtab _grid_form;

_ok.on_create()
{
   _grwidth.p_text = _grid_width();
   _grheight.p_text = _grid_height();
}

_ok.lbutton_up()
{
   grid(_grwidth.p_text' '_grheight.p_text);
   p_active_form._delete_window(1);
}

/** 
 * Displays or sets the grid width and height used by the dialog editor.  
 * This effects the distance displayed between the dots displayed on a form that 
 * is being edited.  If no parameters are given, the current grid width and 
 * height are displayed on the command line.  The <i>width</i> and <i>height</i> 
 * parameters are in twips (1440 twips are one inch on the display).  
 * 
 * @param cmdline is a string in the format: <i>width</i> <i>height</i>
 * 
 * @see gui_grid
 * @see _grid_width
 * @see _grid_height
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command void grid(_str cmdline='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (cmdline=='') {
      message('Grid width='_grid_width()' Grid height='_grid_height());
   }
   _str arg1=prompt(cmdline,'',_grid_width()' '_grid_height());
   if (arg1=='') {
      return;
   }
   typeless width='';
   typeless height='';
   parse arg1 with width height ;
   _grid_width(width);
   if (height!='') {
      _grid_height(height);
   }
}

