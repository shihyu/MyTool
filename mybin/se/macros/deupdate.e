////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50212 $
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
#import "color.e"
#import "combobox.e"
#import "complete.e"
#import "dlgeditv.e"
#import "dlgman.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "math.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

//
// Add support for a new property requires modifying the
// following functions.
//
//      _deupdate_edit_in_place_types,_defill_cblist,_deupdate_property,
//      _set_property, _get_property, _demerge_props
//
// Not all these functions will need to modified.  Some
// LIST constants that they use may need to be modified.
//
_form _dlge_form;
                     //_display_wid is the wid of a selected control or 0 if
                     // no controls selected
int _deform_wid=0;   //  Window id of properties form.
int _decombo_wid;    // Window id of combo box
int _delist_wid;     // Window id of list box
_str _depname;       // Current/last property name
int _deNofselected;  // Number of selected controls
boolean _deignore_ctllist_on_change;
_control combo;

#pragma option(deprecateconst,off)
const OBJECT_KIND_LIST=\
         '_form='OI_FORM' ':+
         '_text_box='OI_TEXT_BOX' ':+
         '_check_box='OI_CHECK_BOX' ':+
         '_command_button='OI_COMMAND_BUTTON' ':+
         '_radio_button='OI_RADIO_BUTTON' ':+
         '_frame='OI_FRAME' ':+
         '_label='OI_LABEL' ':+
         '_list_box='OI_LIST_BOX' ':+
         '_editor='OI_EDITOR' ':+
         '_vscroll_bar='OI_VSCROLL_BAR' ':+
         '_hscroll_bar='OI_HSCROLL_BAR' ':+
         '_combo_box='OI_COMBO_BOX' ':+
         '_picture_box='OI_PICTURE_BOX' ':+
         '_image='OI_IMAGE' ':+
         '_gauge='OI_GAUGE' ':+
         '_spin='OI_SPIN' ':+
         '_sstab='OI_SSTAB' ':+
         '_minihtml='OI_MINIHTML' ':+
         '_tree_view='OI_TREE_VIEW' ':+
         '_switch='OI_SWITCH' ':+
         '_textbrowser='OI_TEXTBROWSER' ';
//  Color properties are in hex or decimal. combo box
//  displays picture "...".  Can edit combo text box.
const COLOR_PROPS=' backcolor forecolor ActiveColor';
//  Boolean properties.  Show True or False.
//  Can not edit in text box.
const BOOLEAN_PROPS= ' ActiveEnabled AlwaysColorCurrent auto_size cancel CaptionClick case_sensitive':+
               ' checkable CheckListBox clip_controls ColorEntireLine default DisplayTopOfFile DropDownList enabled':+
               ' EditInPlace font_bold font_italic font_underline interpret_html ListCompletions max_button min_button':+
               ' NeverColorCurrent PictureOnly':+
               ' ReadOnly Password stretch tab_stop tool_window ':+
               ' visible word_wrap';
//  Can edit combo text.
const INCINT_PROPS='font_size  Gridlines LineStyle value';
const INT_PROPS='ActiveTab ActiveOrder delay FirstActiveTab font_size height increment large_change LevelIndent max min Nofstates small_change tab_index SpaceY ':+
          'value width PaddingX PaddingY';
const MIN_VALUES='font_size=1 height=4 Nofstates=1 tab_index=0 ':+
          'width=4 x=0 y=0';
const MAX_VALUES='';
// Properties selectable from combo list.
const CBLIST_PROPS=' alignment border_style command completion font_name':+
                   ' Gridlines LineStyle ListCompletions max_click mouse_pointer':+
                   ' multi_select Orientation scroll_bars style ':+
                   ' UseFileInfoOverlays ';
const TRUEFALSE_LIST='FALSE=':+false:+' TRUE=':+true;
const AL_LIST='AL_LEFT='AL_LEFT' ':+
          'AL_RIGHT='AL_RIGHT' ':+
          'AL_CENTER='AL_CENTER' ':+
          'AL_VCENTER='AL_VCENTER' ':+
          'AL_VCENTERRIGHT='AL_VCENTERRIGHT' ':+
          'AL_CENTERBOTH='AL_CENTERBOTH' ':+
          'AL_BOTTOM='AL_BOTTOM' ':+
          'AL_BOTTOMRIGHT='AL_BOTTOMRIGHT' ':+
          'AL_BOTTOMCENTER='AL_BOTTOMCENTER;
const AL_CHECK_LIST='AL_LEFT='AL_LEFT' ':+
          'AL_RIGHT='AL_RIGHT;
const SB_LIST='SB_NONE='SB_NONE' ':+
        'SB_HORIZONTAL='SB_HORIZONTAL' ':+
        'SB_VERTICAL='SB_VERTICAL' ':+
        'SB_BOTH='SB_BOTH;
const BDS_FORM_LIST='BDS_NONE='BDS_NONE' ':+
           'BDS_FIXED_SINGLE='BDS_FIXED_SINGLE' ':+
           'BDS_SIZABLE='BDS_SIZABLE' ':+
           'BDS_DIALOG_BOX='BDS_DIALOG_BOX;
const BDS_LIST='BDS_NONE='BDS_NONE' ':+
           'BDS_FIXED_SINGLE='BDS_FIXED_SINGLE;
// List for label
const BDS_LIST2='BDS_NONE='BDS_NONE' ':+
         'BDS_FIXED_SINGLE='BDS_FIXED_SINGLE' ':+
         'BDS_SUNKEN='BDS_SUNKEN;
const BDS_LIST3='BDS_NONE='BDS_NONE' ':+
         'BDS_FIXED_SINGLE='BDS_FIXED_SINGLE' ':+
         'BDS_SUNKEN='BDS_SUNKEN' ':+
         'BDS_SUNKEN_LESS='BDS_SUNKEN_LESS;
const TREE_GRIDLINE_LIST='TREE_GRID_NONE='TREE_GRID_NONE' ':+
         'TREE_GRID_HORZ='TREE_GRID_HORZ' ':+
         'TREE_GRID_VERT='TREE_GRID_VERT' ':+
         'TREE_GRID_BOTH='TREE_GRID_BOTH' ':+
         'TREE_GRID_ALTERNATE_ROW_COLORS='(TREE_GRID_NONE|TREE_GRID_ALTERNATE_ROW_COLORS)' ':+
         'TREE_GRID_HORZ|TREE_GRID_ALTERNATE_ROW_COLORS='(TREE_GRID_HORZ|TREE_GRID_ALTERNATE_ROW_COLORS)' ':+
         'TREE_GRID_VERT|TREE_GRID_ALTERNATE_ROW_COLORS='(TREE_GRID_VERT|TREE_GRID_ALTERNATE_ROW_COLORS)' ':+
         'TREE_GRID_BOTH|TREE_GRID_ALTERNATE_ROW_COLORS='(TREE_GRID_BOTH|TREE_GRID_ALTERNATE_ROW_COLORS);
const TREE_FILE_INFO_OVERLAY_LIST='FILE_OVERLAYS_NONE='FILE_OVERLAYS_NONE' ':+
         'FILE_OVERLAYS_NODE='FILE_OVERLAYS_NODE;
#if 0
const VS_LIST='VS_NONE='VS_NONE' ':+
              'VS_INTEGER='VS_INTEGER;
#endif
const MC_LIST='MC_SINGLE='MC_SINGLE' ':+
        'MC_DOUBLE='MC_DOUBLE' ':+
        'MC_TRIPLE='MC_TRIPLE;
const MP_LIST='MP_DEFAULT='MP_DEFAULT' ':+
          'MP_ARROW='MP_ARROW' ':+
          'MP_CROSS='MP_CROSS' ':+
          'MP_IBEAM='MP_IBEAM' ':+
          'MP_ICON='MP_ICON' ':+
          'MP_SIZE='MP_SIZE' ':+
          'MP_SIZENESW='MP_SIZENESW' ':+
          'MP_SIZENS='MP_SIZENS' ':+
          'MP_SIZENWSE='MP_SIZENWSE' ':+
          'MP_SIZEWE='MP_SIZEWE' ':+
          'MP_UP_ARROW='MP_UP_ARROW' ':+
          'MP_HOUR_GLASS='MP_HOUR_GLASS' ':+
          'MP_SIZEHORZ='MP_SIZEHORZ' ':+
          'MP_SIZEVERT='MP_SIZEVERT' ':+  
          'MP_SPLITVERT='MP_SPLITVERT' ':+
          'MP_SPLITHORZ='MP_SPLITHORZ' ':+
          'MP_LEFTARROW_DROP_TOP='MP_LEFTARROW_DROP_TOP' ':+
          'MP_LEFTARROW_DROP_BOTTOM='MP_LEFTARROW_DROP_BOTTOM' ':+
          'MP_LEFTARROW_DROP_RIGHT='MP_LEFTARROW_DROP_RIGHT' ':+
          'MP_LEFTARROW_DROP_LEFT='MP_LEFTARROW_DROP_LEFT' ':+
          'MP_LEFTARROW='MP_LEFTARROW' ':+
          'MP_RIGHTARROW='MP_RIGHTARROW' ':+
          'MP_MOVETEXT='MP_MOVETEXT' ' :+
          'MP_HAND='MP_HAND' ':+
          'MP_LISTBOXBUTTONSIZE='MP_LISTBOXBUTTONSIZE' ':+
          'MP_NODROP='MP_NODROP' ':+
          'MP_ALLOWCOPY='MP_ALLOWCOPY' ':+
          'MP_ALLOWDROP='MP_ALLOWDROP;

const MS_LIST='MS_NONE='MS_NONE' ':+
          'MS_SIMPLE_LIST='MS_SIMPLE_LIST' ':+
          'MS_EXTENDED='MS_EXTENDED;
const MS_LIST_TREEVIEW='MS_NONE='MS_NONE' ':+
          'MS_SIMPLE_LIST='MS_SIMPLE_LIST;
const CP_LIST='NONE_ARG=. ':+
        'FILE_ARG='FILE_ARG' ':+
        'FILENEW_ARG='FILENEW_ARG' ':+
        'FILENOQUOTES_ARG='FILENOQUOTES_ARG' ':+
        'SEMICOLON_FILES_ARG='SEMICOLON_FILES_ARG' ':+
        'DIR_ARG='DIR_ARG' ':+
        'DIRNEW_ARG='DIRNEW_ARG' ':+
        'DIRNOQUOTES_ARG='DIRNOQUOTES_ARG' ':+
        'MULTI_FILE_ARG='MULTI_FILE_ARG' ':+
        'BUFFER_ARG='BUFFER_ARG' ':+
        'COMMAND_ARG='COMMAND_ARG' ':+
        'PICTURE_ARG='PICTURE_ARG' ':+
        'FORM_ARG='FORM_ARG' ':+
        'MODULE_ARG='MODULE_ARG' ':+
        'MACRO_ARG='MACRO_ARG' ':+
        'MACROTAG_ARG='MACROTAG_ARG' ':+
        'VAR_ARG='VAR_ARG' ':+
        'ENV_ARG='ENV_ARG' ':+
        'MENU_ARG='MENU_ARG' ':+
        /* 'HELP_ARG='HELP_ARG' ':+ */
        'TAG_ARG='TAG_ARG' ';

const COMPLETION_LIST='picture='PICTURE_ARG' ':+
                'command='COMMAND_ARG' ':+
                'help='HELP_ARG' ':+
                'ActiveHelp='HELP_ARG;

const PSCH_LIST='PSCH_AUTO2STATE='PSCH_AUTO2STATE' ':+
          'PSCH_AUTO3STATEA='PSCH_AUTO3STATEA' ':+
          'PSCH_AUTO3STATEB='PSCH_AUTO3STATEB;
const PSCBO_LIST='PSCBO_EDIT='PSCBO_EDIT' ':+
           'PSCBO_LIST_ALWAYS='PSCBO_LIST_ALWAYS' ':+
           'PSCBO_NOEDIT='PSCBO_NOEDIT;
const PSGA_LIST='PSGA_HORZ_WITH_PERCENT='PSGA_HORZ_WITH_PERCENT' ':+
          'PSGA_VERT_WITH_PERCENT='PSGA_VERT_WITH_PERCENT' ':+
          'PSGA_HORIZONTAL='PSGA_HORIZONTAL' ':+
          'PSGA_VERTICAL='PSGA_VERTICAL' ':+
          'PSGA_HORZ_ACTIVITY='PSGA_HORZ_ACTIVITY' ':+
          'PSGA_VERT_ACTIVITY='PSGA_VERT_ACTIVITY;
const PSPIC_LIST='PSPIC_DEFAULT='PSPIC_DEFAULT' ':+
           'PSPIC_PUSH_BUTTON='PSPIC_PUSH_BUTTON' ':+
           'PSPIC_SPLIT_PUSH_BUTTON='PSPIC_SPLIT_PUSH_BUTTON' ':+
           'PSPIC_AUTO_BUTTON='PSPIC_AUTO_BUTTON' ':+
           'PSPIC_AUTO_CHECK='PSPIC_AUTO_CHECK' ':+
           'PSPIC_FILL_GRADIENT_HORIZONTAL='PSPIC_FILL_GRADIENT_HORIZONTAL' ':+
           'PSPIC_FILL_GRADIENT_VERTICAL='PSPIC_FILL_GRADIENT_VERTICAL;
const PSIMG_LIST='PSPIC_DEFAULT='PSPIC_DEFAULT' ':+
           //'PSPIC_DEFAULT_TRANSPARENT='PSPIC_DEFAULT_TRANSPARENT' ':+  /* Obsolete. If you want transparency, then create a transparent image. */
           'PSPIC_BUTTON='PSPIC_BUTTON' ':+
           'PSPIC_SPLIT_BUTTON='PSPIC_SPLIT_BUTTON' ':+
           'PSPIC_AUTO_BUTTON='PSPIC_AUTO_BUTTON' ':+
           'PSPIC_AUTO_CHECK='PSPIC_AUTO_CHECK' ':+
           'PSPIC_SIZEVERT='PSPIC_SIZEVERT' ':+
           'PSPIC_SIZEHORZ='PSPIC_SIZEHORZ' ':+
           'PSPIC_GRABBARVERT='PSPIC_GRABBARVERT' ':+
           'PSPIC_GRABBARHORZ='PSPIC_GRABBARHORZ' ':+
           'PSPIC_TOOLBAR_DIVIDER_VERT='PSPIC_TOOLBAR_DIVIDER_VERT' ':+
           'PSPIC_TOOLBAR_DIVIDER_HORZ='PSPIC_TOOLBAR_DIVIDER_HORZ' ':+
           'PSPIC_FLAT_BUTTON='PSPIC_FLAT_BUTTON' ':+
           'PSPIC_FLAT_MONO_BUTTON='PSPIC_FLAT_MONO_BUTTON' ':+
           'PSPIC_HIGHLIGHTED_BUTTON='PSPIC_HIGHLIGHTED_BUTTON' ':+
           'PSPIC_SPLIT_HIGHLIGHTED_BUTTON='PSPIC_SPLIT_HIGHLIGHTED_BUTTON;

const PSPIC_ORIENTATION_LIST='PSPIC_OHORIZONTAL='PSPIC_OHORIZONTAL' ':+
           'PSPIC_OVERTICAL='PSPIC_OVERTICAL;

const SSTAB_ORIENTATION_LIST='SSTAB_OTOP='SSTAB_OTOP' ':+
           'SSTAB_OBOTTOM='SSTAB_OBOTTOM' ':+
           'SSTAB_OLEFT='SSTAB_OLEFT' ':+
           'SSTAB_ORIGHT='SSTAB_ORIGHT;


const TREE_LINE_LIST='TREE_NO_LINES='TREE_NO_LINES' ':+
    'TREE_DOTTED_LINES='TREE_DOTTED_LINES' ':+
    'TREE_SOLID_LINES='TREE_SOLID_LINES' ';


static _str count=1;

_control _objectkind;
void _deupdate()
{
   /* messageNwait('_deform_wid='_deform_wid' _display_wid='_display_wid) */
   // IF properties form not displayed, do nothing.
   if (!_deform_wid) {
      return;
   }
   if (!_display_wid) {
      _delist_wid.p_enabled=0;
      //_decombo_wid.p_enabled=0;
      _declear_props();
      _deform_wid.p_caption=nls('Properties');
      _deform_wid._objectkind.p_caption='';
      return;
   }
   _deignore_ctllist_on_change=1;
   _deform_wid._objectkind.p_caption=eq_value2name(_display_wid.p_object,OBJECT_KIND_LIST);
   //_desave_combovalue()
   _str old_depname=_depname;
   _declear_props();
   _depname=old_depname;
   _delist_wid.p_enabled=1;
   //_decombo_wid.p_enabled=1;
   int orig_wid=p_window_id;
   p_window_id=_delist_wid;
   if (_deNofselected>1) {
      _demerge_props();
   } else {
      switch (_display_wid.p_object) {
      case OI_FORM:
         _deform_props();
         break;
      case OI_TEXT_BOX:
         _detext_props();
         break;
      case OI_COMMAND_BUTTON:
         _decommand_props();
         break;
      case OI_CHECK_BOX:
         _decheck_props();
         break;
      case OI_RADIO_BUTTON:
         _deradio_props();
         break;
      case OI_FRAME:
         _deframe_props();
         break;
      case OI_LABEL:
         _delabel_props();
         break;
      case OI_LIST_BOX:
         _delist_props();
         break;
      case OI_EDITOR:
         _deeditor_props();
         break;
      case OI_COMBO_BOX:
         _decombo_props();
         break;
      case OI_IMAGE:
         _deimage_props();
         break;
      case OI_PICTURE_BOX:
         _depicture_props();
         break;
      case OI_HSCROLL_BAR:
         _descroll_props();
         break;
      case OI_VSCROLL_BAR:
         _descroll_props();
         break;
      case OI_GAUGE:
         _degauge_props();
         break;
      case OI_SPIN:
         _despin_props();
         break;
      case OI_SSTAB:
         _desstab_props();
         break;
      case OI_TREE_VIEW:
         _detree_props();
         break;
      case OI_MINIHTML:
         _deminihtml_props();
         break;
      case OI_SWITCH:
         _deswitch_props();
         break;
      case OI_TEXTBROWSER:
         _detextbrowser_props();
         break;
      }
   }
   //_post_paint();
   p_window_id=orig_wid;
   _deupdate_caption();
   int index=-1;
   if (_depname!='') {
      index=_delist_wid._TreeSearch(TREE_ROOT_INDEX,_depname"\t",'P');
   }
   if (index<0) {
      //_delist_wid._TreeTop();
      index=_delist_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }
   if (index<0) {
   } else {
      _delist_wid._TreeSetCurIndex(index);
      // Adjust the column widths so that everything can be seen
      // just look at the first column - otherwise if we have a
      // long value, then the property names can't be seen and aren't very useful
      _delist_wid._TreeAdjustColumnWidths(0);
   }
   _deignore_ctllist_on_change=0;
   //_deupdate_combo();
   //message 'display object='_display_wid.p_object;delay(200)
}
static void _declear_props()
{
   _delist_wid._TreeDelete(TREE_ROOT_INDEX,'C');
}
_str _format_color(int color)
{
   if (color<0) {
      color=(pow(2,32))+color;
   }
   _str result=dec2hex(color);
   _str rest='';
   parse result with '0x' rest;
   return('0x'substr('',1,8-length(rest),'0'):+rest);
}
const CHECK_BOX_PROPS=' alignment auto_size backcolor caption enabled eventtab eventtab2 font_bold':+
               ' font_italic font_name font_size forecolor height help':+
               ' mouse_pointer tab_stop value visible width x y ';

static _str _quote_tm(_str s, boolean isTitleBar=false)
{
   // get the constants for registered trademark symbols
   tmName := isTitleBar? "VSREGISTEREDTM_TITLEBAR" : "VSREGISTEREDTM";
   tmChar := isTitleBar?  VSREGISTEREDTM_TITLEBAR  :  VSREGISTEREDTM;

   // translate them to % sequences to get rid of special characters
   s = stranslate(s, "%":+tmName:+"%", tmChar);

   // now quote the string
   s = _quote(s);

   // get the quote character used
   quoteChar := substr(s,1,1);

   // now replace the % sequence with quotes correctly
   s = stranslate(s, quoteChar:+tmName:+quoteChar, "%":+tmName:+"%");

   // trim trailing empty string if there is one
   if (length(s) > 10 && 
       substr(s, length(s)-1, 2) == quoteChar:+quoteChar && 
       substr(s, length(s)-2, 1) != "\\") {
      s = substr(s, 1, length(s)-2);
   }

   // return final result
   return s;
}

static void _decheck_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"alignment\t"eq_value2name(_display_wid.p_alignment,AL_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSCH_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
static safe_insert_line(_str property,_str value,boolean isTitleBar=false)
{
   // Macro compiler has 1k limit on string constants
   // here we let the compiler truncate the string
   if (length(property)+length(value)+12>=1000) {
      int i=length(value) intdiv 2;
      // It is ok to bisect a dbcs character here.
      _str half=substr(value,1,i);
      _str half2=substr(value,i+1);
      insert_line(property:+_quote(half)':+');
      insert_line(substr('',1,length(property)):+_quote(half2)';');
      return('');
   }
   insert_line(property:+_quote_tm(value,isTitleBar)';');
}
static void insert_prop(int indent, _str prop_name,_str value)
{
   insert_line(substr('',1,indent):+prop_name:+"=":+value:+";");
}
void _insert_check_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_alignment",eq_value2name(_display_wid.p_alignment,AL_LIST));
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_style",eq_value2name(_display_wid.p_style,PSCH_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   RADIO_BUTTON_PROPS=' alignment auto_size backcolor caption enabled eventtab eventtab2 font_bold':+
               ' font_italic font_name font_size font_underline':+
               ' forecolor height help mouse_pointer tab_stop value visible':+
               ' width x y ';
static void _deradio_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"alignment\t"eq_value2name(_display_wid.p_alignment,AL_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_radio_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_alignment",eq_value2name(_display_wid.p_alignment,AL_LIST));
   //_TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   FORM_PROPS=' backcolor border_style caption CaptionClick enabled eventtab eventtab2':+
              ' forecolor height help max_button min_button mouse_pointer picture tool_window visible':+
              ' width x y ';
static void _deform_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_FORM_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"CaptionClick\t"_bool2TRUEFALSE(_display_wid.p_CaptionClick),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"clip_controls\t"_bool2TRUEFALSE(_display_wid.p_clip_controls),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max_button\t"_bool2TRUEFALSE(_display_wid.p_max_button),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"min_button\t"_bool2TRUEFALSE(_display_wid.p_min_button),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"min_button\t"_bool2TRUEFALSE(_display_wid.p_min_button))
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"picture\t"name_name(_display_wid.p_picture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tool_window\t"_bool2TRUEFALSE(_display_wid.p_tool_window),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
static insert_etabs(int _display_wid,int indent,_str form_name)
{
   _str etname=translate(name_name(_display_wid.p_eventtab),'_','-');
   if (_display_wid.p_eventtab &&
       !name_eq(form_name'.'_display_wid.p_name,etname)) {
      insert_prop(indent,"p_eventtab",etname);
   }
   if (_display_wid.p_eventtab2) {
      insert_prop(indent,"p_eventtab2",translate(name_name(_display_wid.p_eventtab2),'_','-'));
   }
}
void _insert_form_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_FORM_LIST));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption,true);
   if (_display_wid.p_CaptionClick) {
      insert_prop(indent,"p_CaptionClick",_bool2truefalse(_display_wid.p_CaptionClick));
   }
   //insert_prop(indent,"p_clip_controls",_bool2truefalse(_display_wid.p_clip_controls));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled))
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_max_button) insert_prop(indent,"p_max_button",_bool2truefalse(_display_wid.p_max_button));
   if(_display_wid.p_min_button) insert_prop(indent,"p_min_button",_bool2truefalse(_display_wid.p_min_button));
   //if(_display_wid.p_min_button) insert_prop(indent,"p_min_button",_bool2truefalse(_display_wid.p_min_button))
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   if( _display_wid.p_picture!=0 ) {
      insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)));
   }
   if (_display_wid.p_tool_window) insert_prop(indent,"p_tool_window",_bool2truefalse(_display_wid.p_tool_window))
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   TEXT_BOX_PROPS=' auto_size backcolor border_style completion':+
                  ' enabled eventtab eventtab2 font_bold':+
                  ' font_italic font_name font_size font_underline forecolor':+
                  ' height help ListCompletions mouse_pointer ReadOnly':+
                  ' Password tab_stop text visible width x y ';
static void _detext_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"completion\t"cp_value2name(_display_wid.p_completion),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ListCompletions\t"_bool2TRUEFALSE(_display_wid.p_ListCompletions),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ReadOnly\t"_bool2TRUEFALSE(_display_wid.p_ReadOnly),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Password\t"_bool2TRUEFALSE(_display_wid.p_Password),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"text\t"_display_wid.p_text,TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX," validate_style\t"eq_value2name(_display_wid.p_validate_style,VS_LIST))
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_text_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   insert_prop(indent,"p_completion",cp_value2name(_display_wid.p_completion));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(!_display_wid.p_ListCompletions) insert_prop(indent,"p_ListCompletions",_bool2truefalse(_display_wid.p_ListCompletions));
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   if (_display_wid.p_ReadOnly) {
      insert_prop(indent,"p_ReadOnly",_bool2truefalse(_display_wid.p_ReadOnly));
   }
   if (_display_wid.p_Password) {
      insert_prop(indent,"p_Password",_bool2truefalse(_display_wid.p_Password));
   }
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (_display_wid.p_text:!='') insert_prop(indent,"p_text",_quote_tm(_display_wid.p_text))
   //insert_line(substr('',1,indent)"p_validate_style="eq_value2name(_display_wid.p_validate_style,VS_LIST))
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   COMMAND_BUTTON_PROPS=' auto_size cancel caption command default enabled eventtab eventtab2 font_bold':+
              ' font_italic font_name font_size font_underline':+
              ' height help mouse_pointer tab_stop visible width x y ';

static void _decommand_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   //insert_line(" backcolor\t"_format_color(_display_wid.p_backcolor))
   _TreeAddItem(TREE_ROOT_INDEX,"cancel\t"_bool2TRUEFALSE(_display_wid.p_cancel),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"command\t"_display_wid.p_command,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"default\t"_bool2TRUEFALSE(_display_wid.p_default),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_command_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   //insert_line(substr('',1,indent)"p_backcolor="_format_color(_display_wid.p_backcolor))
   insert_prop(indent,"p_cancel",_bool2truefalse(_display_wid.p_cancel));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   if (_display_wid.p_command!="") {
      safe_insert_line(substr('',1,indent)"p_command=",_display_wid.p_command);
   }
   insert_prop(indent,"p_default",_bool2truefalse(_display_wid.p_default));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   FRAME_PROPS=' backcolor caption checkable enabled eventtab eventtab2 font_bold font_italic font_name':+
               ' font_size font_underline forecolor height help mouse_pointer':+
               ' visible width x y ';
static void _deframe_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"checkable\t"_bool2TRUEFALSE(_display_wid.p_checkable),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"clip_controls\t"_bool2TRUEFALSE(_display_wid.p_clip_controls),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_frame_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   //insert_prop(indent,"p_clip_controls",_bool2truefalse(_display_wid.p_clip_controls));
   if(_display_wid.p_checkable) insert_prop(indent,"p_checkable",_bool2truefalse(_display_wid.p_checkable));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   if (_display_wid.p_tab_stop) insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if(!_display_wid.p_value) insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   LABEL_PROPS=' alignment auto_size backcolor border_style caption':+
               ' enabled eventtab eventtab2 font_bold font_italic font_name font_size':+
               ' font_underline forecolor height help mouse_pointer':+
               ' interpret_html visible width word_wrap x y ';
static void _delabel_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"alignment\t"eq_value2name(_display_wid.p_alignment,AL_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST2),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"interpret_html\t"_bool2TRUEFALSE(_display_wid.p_interpret_html),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"word_wrap\t"_bool2TRUEFALSE(_display_wid.p_word_wrap),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_label_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_alignment",eq_value2name(_display_wid.p_alignment,AL_LIST));
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST2));
   safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_interpret_html!=MP_DEFAULT) insert_prop(indent,"p_interpret_html",_bool2truefalse(_display_wid.p_interpret_html));
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_word_wrap",_bool2truefalse(_display_wid.p_word_wrap));
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
      TREE_VIEW_PROPS=' AlwaysColorCurrent backcolor border_style CheckListBox':+
                 ' ColorEntireLine delay enabled':+
                 ' eventtab eventtab2 EditInPlace font_bold':+
                 ' font_italic font_name font_size font_underline forecolor':+
                 ' Gridlines height help LevelIndent mouse_pointer':+
                 ' multi_select NeverColorCurrent scroll_bars SpaceY ':+
                 ' tab_stop UseFileInfoOverlays visible width x y ';
static void _detree_props()
{
   //_TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size))
   //_TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor))
   _TreeAddItem(TREE_ROOT_INDEX,"after_pic_indent_x\t"_display_wid.p_after_pic_indent_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"AlwaysColorCurrent\t"_bool2TRUEFALSE(_display_wid.p_AlwaysColorCurrent),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"CheckListBox\t"_bool2TRUEFALSE(_display_wid.p_CheckListBox),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"clip_controls\t"_bool2TRUEFALSE(_display_wid.p_clip_controls),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"CollapsePicture\t"name_name(_display_wid.p_CollapsePicture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ColorEntireLine\t"_bool2TRUEFALSE(_display_wid.p_ColorEntireLine),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"delay\t"_display_wid.p_delay,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"EditInPlace\t"_bool2TRUEFALSE(_display_wid.p_EditInPlace),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"ExpandPicture\t"name_name(_display_wid.p_ExpandPicture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Gridlines\t"eq_value2name(_display_wid.p_Gridlines,TREE_GRIDLINE_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor))
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"LeafPicture\t"name_name(_display_wid.p_LeafPicture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"LevelIndent\t"_display_wid.p_LevelIndent,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"LineStyle\t"eq_value2name(_display_wid.p_LineStyle,TREE_LINE_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"multi_select\t"eq_value2name(_display_wid.p_multi_select,MS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"NeverColorCurrent\t"_bool2TRUEFALSE(_display_wid.p_NeverColorCurrent),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"scroll_bars\t"eq_value2name(_display_wid.p_scroll_bars,SB_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"ShowRoot\t"_bool2TRUEFALSE(_display_wid.p_ShowRoot),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"SpaceY\t"_display_wid.p_SpaceY,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"UseFileInfoOverlays\t"eq_value2name(_display_wid.p_UseFileInfoOverlays,TREE_FILE_INFO_OVERLAY_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_tree_props(int _display_wid,int indent,_str form_name)
{
   //insert_line(substr('',1,indent)"p_auto_size="_bool2TRUEFALSE(_display_wid.p_auto_size))
   insert_prop(indent,"p_after_pic_indent_x",_display_wid.p_after_pic_indent_x);
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   //insert_prop(indent,"p_clip_controls",_bool2truefalse(_display_wid.p_clip_controls));
   insert_prop(indent,"p_CheckListBox",_bool2truefalse(_display_wid.p_CheckListBox));
   //insert_prop(indent,"p_CollapsePicture",_quote(name_name(_display_wid.p_CollapsePicture)));
   insert_prop(indent,"p_ColorEntireLine",_bool2truefalse(_display_wid.p_ColorEntireLine));
   insert_prop(indent,"p_EditInPlace",_bool2truefalse(_display_wid.p_EditInPlace));
   insert_prop(indent,"p_delay",_display_wid.p_delay);
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   //insert_prop(indent,"p_ExpandPicture",_quote(name_name(_display_wid.p_ExpandPicture)));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_Gridlines",eq_value2name(_display_wid.p_Gridlines,TREE_GRIDLINE_LIST));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   //insert_prop(indent,"p_LeafPicture",_quote(name_name(_display_wid.p_LeafPicture)));
   insert_prop(indent,"p_LevelIndent",_display_wid.p_LevelIndent);
   insert_prop(indent,"p_LineStyle",eq_value2name(_display_wid.p_LineStyle,TREE_LINE_LIST));
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   insert_prop(indent,"p_multi_select",eq_value2name(_display_wid.p_multi_select,MS_LIST));
   insert_prop(indent,"p_NeverColorCurrent",_bool2truefalse(_display_wid.p_NeverColorCurrent));
#if 0
   if (_display_wid.p_picture) {
      insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)))
      insert_prop(indent,"p_pic_space_y",_display_wid.p_pic_space_y)
      insert_prop(indent,"p_pic_point_scale",_display_wid.p_pic_point_scale)
   }
#endif
   insert_prop(indent,"p_ShowRoot",_bool2truefalse(_display_wid.p_ShowRoot));
   insert_prop(indent,"p_AlwaysColorCurrent",_bool2truefalse(_display_wid.p_AlwaysColorCurrent));
   insert_prop(indent,"p_SpaceY",_display_wid.p_SpaceY);
   insert_prop(indent,"p_scroll_bars",eq_value2name(_display_wid.p_scroll_bars,SB_LIST));
   insert_prop(indent,"p_UseFileInfoOverlays",eq_value2name(_display_wid.p_UseFileInfoOverlays,TREE_FILE_INFO_OVERLAY_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
      MINIHTML_PROPS=' backcolor border_style enabled':+
                 ' eventtab eventtab2':+
                 ' ':+
                 ' height help mouse_pointer PaddingX PaddingY':+
                 ' tab_stop text visible width word_wrap x y ';
static void _deminihtml_props()
{
   //_TreeAddItem(TREE_ROOT_INDEX," auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size))
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor))
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"PaddingX\t"_display_wid.p_PaddingX,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"PaddingY\t"_display_wid.p_PaddingY,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"text\t"_display_wid.p_text,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"word_wrap\t"_bool2TRUEFALSE(_display_wid.p_word_wrap),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_minihtml_props(int _display_wid,int indent,_str form_name)
{
   //insert_line(substr('',1,indent)"p_auto_size="_bool2TRUEFALSE(_display_wid.p_auto_size))
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if( _display_wid.p_mouse_pointer != MP_DEFAULT && _display_wid.p_mouse_pointer != MP_CUSTOM ) {
      insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   }
   insert_prop(indent,"p_PaddingX",_display_wid.p_PaddingX);
   insert_prop(indent,"p_PaddingY",_display_wid.p_PaddingY);
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (_display_wid.p_text:!='') insert_prop(indent,"p_text",_quote_tm(_display_wid.p_text));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_word_wrap",_bool2truefalse(_display_wid.p_word_wrap));
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}

const SWITCH_PROPS=' enabled eventtab eventtab2 font_bold':+
               ' font_italic font_name font_size font_underline height help':+
               ' mouse_pointer tab_stop value visible width x y ';

static void _deswitch_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}

void _insert_switch_props(int _display_wid, int indent, _str form_name)
{
   if( !_display_wid.p_enabled ) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if( _display_wid.p_font_bold ) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if( _display_wid.p_font_italic ) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if( _display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME ) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if( _display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE ) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if( _display_wid.p_font_underline ) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if( _display_wid.p_help != '' ) safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if( _display_wid.p_mouse_pointer != MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if( !_display_wid.p_visible ) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}

const TEXTBROWSER_PROPS=' backcolor border_style enabled':+
                        ' eventtab eventtab2':+
                        ' height help mouse_pointer':+
                        ' tab_stop visible width x y ';

static void _detextbrowser_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
// _TreeAddItem(TREE_ROOT_INDEX,"text\t"_display_wid.p_text,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}

void _insert_textbrowser_props(int _display_wid, int indent, _str form_name)
{
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if( _display_wid.p_mouse_pointer != MP_DEFAULT && _display_wid.p_mouse_pointer != MP_CUSTOM ) {
      insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   }
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
// if (_display_wid.p_text:!='') insert_prop(indent,"p_text",_quote_tm(_display_wid.p_text));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}

const
   LIST_BOX_PROPS=' border_style enabled eventtab eventtab2 font_bold':+
              ' font_italic font_name font_size font_underline':+
              ' height help mouse_pointer multi_select scroll_bars tab_stop visible':+
              ' width x y ';
static void _delist_props()
{
   //_TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"multi_select\t"eq_value2name(_display_wid.p_multi_select,MS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"scroll_bars\t"eq_value2name(_display_wid.p_scroll_bars,SB_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_list_props(int _display_wid,int indent,_str form_name)
{
   //insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   //insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   //insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_multi_select",eq_value2name(_display_wid.p_multi_select,MS_LIST));
   if (_display_wid.p_picture) {
      insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)));
      insert_prop(indent,"p_pic_space_y",_display_wid.p_pic_space_y);
      insert_prop(indent,"p_pic_point_scale",_display_wid.p_pic_point_scale);
   }
   insert_prop(indent,"p_scroll_bars",eq_value2name(_display_wid.p_scroll_bars,SB_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}


const
   EDITOR_PROPS=' border_style DisplayTopOfFile enabled eventtab eventtab2 font_bold':+
              ' font_italic font_name font_size font_underline forecolor':+
              ' height help mouse_pointer scroll_bars tab_stop visible':+
              ' width x y ';
static void _deeditor_props()
{
   //_TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"DisplayTopOfFile\t"_bool2TRUEFALSE(_display_wid.p_DisplayTopOfFile),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"scroll_bars\t"eq_value2name(_display_wid.p_scroll_bars,SB_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_editor_props(int _display_wid,int indent,_str form_name)
{
   //insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   //insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST));
   if(_display_wid.p_DisplayTopOfFile) insert_prop(indent,"p_DisplayTopOfFile",_bool2truefalse(_display_wid.p_DisplayTopOfFile));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   if (_display_wid.p_picture) {
      insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)));
      insert_prop(indent,"p_pic_space_y",_display_wid.p_pic_space_y);
      insert_prop(indent,"p_pic_point_scale",_display_wid.p_pic_point_scale);
   }
   insert_prop(indent,"p_scroll_bars",eq_value2name(_display_wid.p_scroll_bars,SB_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   COMBO_BOX_PROPS=' backcolor completion enabled eventtab eventtab2 font_bold font_italic font_name':+
             ' font_size font_underline forecolor height help mouse_pointer':+
             ' tab_stop text visible width x y ';
static void _decombo_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"case_sensitive\t"_bool2TRUEFALSE(_display_wid.p_case_sensitive),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"completion\t"cp_value2name(_display_wid.p_completion),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ListCompletions\t"_bool2TRUEFALSE(_display_wid.p_ListCompletions),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSCBO_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"text\t"_display_wid.p_text,TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"validate_style\t"eq_value2name(_display_wid.p_validate_style,VS_LIST))
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_combo_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_case_sensitive",_bool2truefalse(_display_wid.p_case_sensitive));
   insert_prop(indent,"p_completion",cp_value2name(_display_wid.p_completion));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   if(!_display_wid.p_ListCompletions) insert_prop(indent,"p_ListCompletions",_bool2truefalse(_display_wid.p_ListCompletions));
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_style",eq_value2name(_display_wid.p_style,PSCBO_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (_display_wid.p_text:!='') insert_prop(indent,"p_text",_quote_tm(_display_wid.p_text))
   //insert_line(substr('',1,indent)"p_validate_style="eq_value2name(_display_wid.p_validate_style,VS_LIST))
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
#define IMAGE_BUTTON 1
const
   IMAGE_PROPS=' auto_size backcolor border_style caption command enabled eventtab eventtab2':+
#if IMAGE_BUTTON
               ' font_bold font_italic font_name font_size font_underline forecolor ':+
               ' height max_click message mouse_pointer Nofstates Orientation picture stretch':+
               ' tab_stop value visible':+
#else
               ' height max_click message mouse_pointer Nofstates Orientation picture stretch':+
               ' tab_stop value visible':+
#endif
               ' width x y ';
static void _deimage_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST3),TREE_ADD_AS_CHILD,0,0,-1);
#if IMAGE_BUTTON
   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);
#endif
   _TreeAddItem(TREE_ROOT_INDEX,"command\t"_display_wid.p_command,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
#if IMAGE_BUTTON
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
#endif
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max_click\t"eq_value2name(_display_wid.p_max_click,MC_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"message\t"_display_wid.p_message,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Nofstates\t"_display_wid.p_Nofstates,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Orientation\t"eq_value2name(_display_wid.p_Orientation,PSPIC_ORIENTATION_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"picture\t"name_name(_display_wid.p_picture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"stretch\t"_bool2TRUEFALSE(_display_wid.p_stretch),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSIMG_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_image_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST3));
#if IMAGE_BUTTON
   if (_display_wid.p_caption!="") {
      safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   }
#endif
   if (_display_wid.p_command!='') insert_prop(indent,"p_command",_quote(_display_wid.p_command));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
#if IMAGE_BUTTON
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
#endif
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   insert_prop(indent,"p_max_click",eq_value2name(_display_wid.p_max_click,MC_LIST));
   if (_display_wid.p_message!='') insert_prop(indent,"p_message",_quote_tm(_display_wid.p_message));
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   insert_prop(indent,"p_Nofstates",_display_wid.p_Nofstates);
   if( _display_wid.p_Orientation!=PSPIC_OHORIZONTAL ) {
      insert_prop(indent,"p_Orientation",eq_value2name(_display_wid.p_Orientation,PSPIC_ORIENTATION_LIST));
   }
   insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)));
   insert_prop(indent,"p_stretch",_bool2truefalse(_display_wid.p_stretch));
   insert_prop(indent,"p_style",eq_value2name(_display_wid.p_style,PSIMG_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   PICTURE_BOX_PROPS=' auto_size backcolor border_style caption command':+
            ' font_bold font_italic font_name font_size font_underline forecolor':+
            ' enabled eventtab eventtab2':+
            ' height help max_click message mouse_pointer Nofstates picture':+
            ' stretch tab_stop value visible width x y ';
static void _depicture_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"border_style\t"eq_value2name(_display_wid.p_border_style,BDS_LIST3),TREE_ADD_AS_CHILD,0,0,-1);

   _TreeAddItem(TREE_ROOT_INDEX,"caption\t"_display_wid.p_caption,TREE_ADD_AS_CHILD,0,0,-1);

   //_TreeAddItem(TREE_ROOT_INDEX,"clip_controls\t"_bool2TRUEFALSE(_display_wid.p_clip_controls),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"command\t"_display_wid.p_command,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);

   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);

   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max_click\t"eq_value2name(_display_wid.p_max_click,MC_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"message\t"_display_wid.p_message,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Nofstates\t"_display_wid.p_Nofstates,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"picture\t"name_name(_display_wid.p_picture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"stretch\t"_bool2TRUEFALSE(_display_wid.p_stretch),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSPIC_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_picture_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   insert_prop(indent,"p_border_style",eq_value2name(_display_wid.p_border_style,BDS_LIST3));
   if( _display_wid.p_caption != '' ) {
      safe_insert_line(substr('',1,indent)"p_caption=",_display_wid.p_caption);
   }
   //insert_prop(indent,"p_clip_controls",_bool2truefalse(_display_wid.p_clip_controls));
   if( _display_wid.p_command != '' ) {
      insert_prop(indent,"p_command",_quote(_display_wid.p_command));
   }
   if( !_display_wid.p_enabled ) {
      insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   }

   if( _display_wid.p_font_bold ) {
      insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   }
   if( _display_wid.p_font_italic ) {
      insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   }
   if( _display_wid.p_font_name != VSDEFAULT_DIALOG_FONT_NAME ) {
      insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   }
   if( _display_wid.p_font_size != VSDEFAULT_DIALOG_FONT_SIZE ) {
      insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   }
   if( _display_wid.p_font_underline ) {
      insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   }
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));

   insert_prop(indent,"p_height",_display_wid.p_height);
   if( _display_wid.p_help != '' ) {
      safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   }
   insert_prop(indent,"p_max_click",eq_value2name(_display_wid.p_max_click,MC_LIST));
   if( _display_wid.p_message != '' ) {
      insert_prop(indent,"p_message",_quote_tm(_display_wid.p_message));
   }
   if( _display_wid.p_mouse_pointer != MP_DEFAULT ) {
      insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   }
   insert_prop(indent,"p_Nofstates",_display_wid.p_Nofstates);
   insert_prop(indent,"p_picture",_quote(name_name(_display_wid.p_picture)));
   insert_prop(indent,"p_stretch",_bool2truefalse(_display_wid.p_stretch));
   insert_prop(indent,"p_style",eq_value2name(_display_wid.p_style,PSPIC_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if( !_display_wid.p_visible ) {
      insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible));
   }
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   SCROLL_BAR_PROPS=' auto_size enabled eventtab eventtab2 height help large_change max min':+
                    ' mouse_pointer small_change tab_stop value visible width x y ';
static void _descroll_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"large_change\t"_display_wid.p_large_change,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max\t"_display_wid.p_max,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"min\t"_display_wid.p_min,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"small_change\t"_display_wid.p_small_change,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_scroll_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled))
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   insert_prop(indent,"p_large_change",_display_wid.p_large_change);
   insert_prop(indent,"p_max",_display_wid.p_max);
   insert_prop(indent,"p_min",_display_wid.p_min);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_small_change",_display_wid.p_small_change);
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   GAUGE_PROPS=' enabled eventtab eventtab2 height help max min mouse_pointer':+
               ' tab_stop value visible width x y ';
static void _degauge_props()
{
   //_TreeAddItem(TREE_ROOT_INDEX," auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size))
   //_TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max\t"_display_wid.p_max,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"min\t"_display_wid.p_min,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSGA_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"value\t"_display_wid.p_value,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_gauge_props(int _display_wid,int indent,_str form_name)
{
   //insert_line(substr('',1,indent)"p_auto_size="_bool2TRUEFALSE(_display_wid.p_auto_size))
   //insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled))
   //insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   insert_prop(indent,"p_max",_display_wid.p_max);
   insert_prop(indent,"p_min",_display_wid.p_min);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   insert_prop(indent,"p_style",eq_value2name(_display_wid.p_style,PSGA_LIST));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   insert_prop(indent,"p_value",_display_wid.p_value);
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
   SPIN_PROPS=' auto_size enabled eventtab eventtab2 height help increment':+
              ' max min mouse_pointer visible width x y ';
static void _despin_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"auto_size\t"_bool2TRUEFALSE(_display_wid.p_auto_size),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"delay\t"_display_wid.p_delay,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"help\t"_display_wid.p_help,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"increment\t"_display_wid.p_increment,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"max\t"_display_wid.p_max,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"min\t"_display_wid.p_min,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"style\t"eq_value2name(_display_wid.p_style,PSSP_LIST))
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop))
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_spin_props(int _display_wid,int indent,_str form_name)
{
   insert_prop(indent,"p_auto_size",_bool2truefalse(_display_wid.p_auto_size));
   //insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   //insert_prop(indent,"p_delay",_display_wid.p_delay);
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled))
   //insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if (_display_wid.p_help!='') safe_insert_line(substr('',1,indent)"p_help=",_display_wid.p_help);
   insert_prop(indent,"p_increment",_display_wid.p_increment);
   insert_prop(indent,"p_max",_display_wid.p_max);
   insert_prop(indent,"p_min",_display_wid.p_min);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST))
   //insert_line(substr('',1,indent)"p_style="eq_value2name(_display_wid.p_style,PSSP_LIST))
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   //insert_line(substr('',1,indent)"p_tab_stop="_bool2TRUEFALSE(_display_wid.p_tab_stop))
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
const
      SSTAB_PROPS=' ActiveCaption ActiveColor ActiveEnabled ActiveHelp ActiveOrder ActivePicture ActiveTab ActiveToolTip backcolor':+
                 ' DropDownList enabled eventtab eventtab2 FirstActiveTab font_bold':+
                 ' font_italic font_name font_size font_underline forecolor':+
                 ' height mouse_pointer NofTabs Orientation PaddingX PaddingY PictureOnly':+
                 ' tab_stop visible width x y ';
static void _desstab_props()
{
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveCaption\t"_display_wid.p_ActiveCaption,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveColor\t"_format_color(_display_wid.p_ActiveColor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveEnabled\t"_bool2TRUEFALSE(_display_wid.p_ActiveEnabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveHelp\t"_display_wid.p_ActiveHelp,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveOrder\t"_display_wid.p_ActiveOrder,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActivePicture\t"name_name(_display_wid.p_ActivePicture),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveTab\t"_display_wid.p_ActiveTab,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"ActiveToolTip\t"_display_wid.p_ActiveToolTip,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"backcolor\t"_format_color(_display_wid.p_backcolor),TREE_ADD_AS_CHILD,0,0,-1);
   //_TreeAddItem(TREE_ROOT_INDEX,"clip_controls\t"_bool2TRUEFALSE(_display_wid.p_clip_controls),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"DropDownList\t"_bool2TRUEFALSE(_display_wid.p_DropDownList),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"enabled\t"_bool2TRUEFALSE(_display_wid.p_enabled),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab\t"translate(name_name(_display_wid.p_eventtab),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"eventtab2\t"translate(name_name(_display_wid.p_eventtab2),'_','-'),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"FirstActiveTab\t"_display_wid.p_FirstActiveTab,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_bold\t"_bool2TRUEFALSE(_display_wid.p_font_bold),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_italic\t"_bool2TRUEFALSE(_display_wid.p_font_italic),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_name\t"_display_wid.p_font_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_size\t"_display_wid.p_font_size,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"font_underline\t"_bool2TRUEFALSE(_display_wid.p_font_underline),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"forecolor\t"_format_color(_display_wid.p_forecolor),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"height\t"_display_wid.p_height,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"mouse_pointer\t"eq_value2name(_display_wid.p_mouse_pointer,MP_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"name\t"_display_wid.p_name,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"NofTabs\t"_display_wid.p_NofTabs,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"Orientation\t"eq_value2name(_display_wid.p_Orientation,SSTAB_ORIENTATION_LIST),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"PictureOnly\t"_bool2TRUEFALSE(_display_wid.p_PictureOnly),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_index\t"_display_wid.p_tab_index,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"tab_stop\t"_bool2TRUEFALSE(_display_wid.p_tab_stop),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"visible\t"_bool2TRUEFALSE(_display_wid.p_visible),TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"width\t"_display_wid.p_width,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"x\t"_display_wid.p_x,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(TREE_ROOT_INDEX,"y\t"_display_wid.p_y,TREE_ADD_AS_CHILD,0,0,-1);
   _deupdate_edit_in_place_types();
}
void _insert_sstab_props(int _display_wid, int indent, _str form_name)
{
   insert_prop(indent,"p_FirstActiveTab",_display_wid.p_FirstActiveTab);
   insert_prop(indent,"p_backcolor",_format_color(_display_wid.p_backcolor));
   //insert_prop(indent,"p_clip_controls",_bool2truefalse(_display_wid.p_clip_controls));
   insert_prop(indent,"p_DropDownList",_bool2truefalse(_display_wid.p_DropDownList));
   if(!_display_wid.p_enabled) insert_prop(indent,"p_enabled",_bool2truefalse(_display_wid.p_enabled));
   if(_display_wid.p_font_bold) insert_prop(indent,"p_font_bold",_bool2truefalse(_display_wid.p_font_bold));
   if(_display_wid.p_font_italic) insert_prop(indent,"p_font_italic",_bool2truefalse(_display_wid.p_font_italic));
   if(_display_wid.p_font_name!=VSDEFAULT_DIALOG_FONT_NAME) insert_prop(indent,"p_font_name",_quote(_display_wid.p_font_name));
   if(_display_wid.p_font_size!=VSDEFAULT_DIALOG_FONT_SIZE) insert_prop(indent,"p_font_size",_display_wid.p_font_size);
   if(_display_wid.p_font_underline) insert_prop(indent,"p_font_underline",_bool2truefalse(_display_wid.p_font_underline));
   insert_prop(indent,"p_forecolor",_format_color(_display_wid.p_forecolor));
   insert_prop(indent,"p_height",_display_wid.p_height);
   if(_display_wid.p_mouse_pointer!=MP_DEFAULT) insert_prop(indent,"p_mouse_pointer",eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   insert_prop(indent,"p_NofTabs",_display_wid.p_NofTabs);
   insert_prop(indent,"p_Orientation",eq_value2name(_display_wid.p_Orientation,SSTAB_ORIENTATION_LIST));
   insert_prop(indent,"p_PictureOnly",_bool2truefalse(_display_wid.p_PictureOnly));
   insert_prop(indent,"p_tab_index",_display_wid.p_tab_index);
   insert_prop(indent,"p_tab_stop",_bool2truefalse(_display_wid.p_tab_stop));
   if (!_display_wid.p_visible) insert_prop(indent,"p_visible",_bool2truefalse(_display_wid.p_visible))
   insert_prop(indent,"p_width",_display_wid.p_width);
   insert_prop(indent,"p_x",_display_wid.p_x);
   insert_prop(indent,"p_y",_display_wid.p_y);
   insert_etabs(_display_wid,indent,form_name);
}
void _insert_sstab_container_props(int _display_wid, int indent, _str form_name)
{
   safe_insert_line(substr('',1,indent)"p_ActiveCaption=",_display_wid.p_ActiveCaption);
   insert_prop(indent,"p_ActiveEnabled",_bool2truefalse(_display_wid.p_ActiveEnabled));
   if (_display_wid.p_ActiveHelp!='') safe_insert_line(substr('',1,indent)"p_ActiveHelp=",_display_wid.p_ActiveHelp);
   insert_prop(indent,"p_ActiveOrder",_display_wid.p_ActiveOrder);
   if (_display_wid.p_ActivePicture) {
      insert_prop(indent,"p_ActivePicture",_quote(name_name(_display_wid.p_ActivePicture)));
   }
   if (_display_wid.p_ActiveColor) {
      insert_prop(indent,"p_ActiveColor",_format_color(_display_wid.p_ActiveColor));
   }
   safe_insert_line(substr('',1,indent)"p_ActiveToolTip=",_display_wid.p_ActiveToolTip);
   //insert_etabs(_display_wid,indent,form_name);
}
defeventtab _decolor_form;
otherColor.on_create(typeless color='')
{
   if (substr(color,1,2)=="0x") {
      p_user=hex2dec(color);
   } else {
      p_user=0;
   }
   image.p_border_style = BDS_SUNKEN;
   image.p_next.p_border_style = BDS_SUNKEN_LESS;
}
void otherColor.lbutton_up()
{
   int color = show_color_picker((int)p_user);
   if (color != COMMAND_CANCELLED_RC) {
      p_active_form._delete_window(color);
   }
}
void inheritColor.lbutton_up()
{
   p_active_form._delete_window(0x80000005);
}
image.lbutton_down()
{
   p_active_form._delete_window(p_backcolor);
}

static _str _ignore_combo_change=0;
_str _deget_ignore_combo_change()
{
   return(_ignore_combo_change);
}
static _str _bool2truefalse(boolean value)
{
   return(value? 'true':'false');
}
static _str _bool2TRUEFALSE(boolean value)
{
   return(value? 'TRUE':'FALSE');
}
static boolean _truefalse2bool(_str value)
{
   return (lowcase(value)=='true' || value=='1');
}
static void cblist_props_fillin_combo(_str _depname,int index,int wid) {
   _str list;

   switch (_depname) {
   case 'alignment':
      if (_display_wid.p_object==OI_CHECK_BOX) {
         list=AL_CHECK_LIST;
      } else {
         list=AL_LIST;
      }
      break;
   case 'border_style':
      if (_display_wid.p_object==OI_FORM) {
         list=BDS_FORM_LIST;
      } else if (_display_wid.p_object==OI_LABEL) {
         list=BDS_LIST2;
      } else if (_display_wid.p_object==OI_PICTURE_BOX) {
         list=BDS_LIST3;
      } else if (_display_wid.p_object==OI_IMAGE) {
         list=BDS_LIST3;
      } else {
         list=BDS_LIST;
      }
      break;
   case 'completion':
      list=CP_LIST;
      break;
   //case 'GrabbarLocation':
   //   list=SSTAB_GRABBARLOCATION_LIST;
   //   break;
   case 'Gridlines':
      list=TREE_GRIDLINE_LIST;
      break;
   case 'font_name':
      mou_hour_glass(1);
      wid._insert_font_list();
      mou_hour_glass(0);
      break;
   case 'max_click':
      list=MC_LIST;
      break;
   case 'mouse_pointer':
      list=MP_LIST;
      break;
   case 'Orientation':
      if( _display_wid.p_object==OI_SSTAB ) {
         list=SSTAB_ORIENTATION_LIST;
      } else {
         // OI_IMAGE
         list=PSPIC_ORIENTATION_LIST;
      }
      break;
   case 'LineStyle':
      list=TREE_LINE_LIST;
      break;
   case 'multi_select':
      switch(_display_wid.p_object){
      case OI_TREE_VIEW:
         list=MS_LIST_TREEVIEW;
         break;
      default:
         list=MS_LIST;
         break;
      }
      break;
   //case 'MultiRow':
   //   list=SSTAB_MULTIROW_LIST;
   //   break;
   case 'style':
      switch(_display_wid.p_object){
      case OI_CHECK_BOX:
         list=PSCH_LIST;
         break;
      case OI_COMBO_BOX:
         list=PSCBO_LIST;
         break;
      case OI_GAUGE:
         list=PSGA_LIST;
         break;
      case OI_PICTURE_BOX:
         list=PSPIC_LIST;
         break;
      case OI_IMAGE:
         list=PSIMG_LIST;
         break;
      }
      break;
   case 'scroll_bars':
      list=SB_LIST;
      break;
   case 'UseFileInfoOverlays':
      list=TREE_FILE_INFO_OVERLAY_LIST;
      break;
#if 0
   case 'validate_style':
      list=VS_LIST;
      break;
#endif
   }
   //p_window_id=_decombo_wid.p_cb_list_box;
   _str value;
   for (;;) {
      _str word='';
      parse list with word'='value list;
      if (word=='') break;
      wid._lbadd_item(word);
   }
   wid._lbsort();
   if (_depname=='font_name') {
      wid._lbremove_duplicates();
   }
}
void _deupdate_edit_in_place(int index,boolean setNodeEditStyle,int wid=0) {
   parse _TreeGetCaption(index) with auto depname "\t" auto value;
   boolean isCombo=false;
   // By default we use the No edit combo box
   comboBoxOption:= TREE_EDIT_COMBOBOX;

   // Since this is a sample, we'll just look for one type
   if ( depname=="font_name" || depname=='command' || depname=='font_size') comboBoxOption=TREE_EDIT_EDITABLE_COMBOBOX;

   if (pos(' 'depname' ',' 'BOOLEAN_PROPS' ',1,'i')) {
      isCombo=true;
      if (!setNodeEditStyle) {
         wid._lbadd_item('FALSE');wid._lbadd_item('TRUE');
      }
   /* } else if(pos(' 'depname' ',' 'INT_PROPS' ',1,'i')){ */
   } else if(lowcase(depname)=='font_size' && !_isscalable_font(_display_wid.p_font_name,'s')) {
      isCombo=1;
      if (!setNodeEditStyle) {
         mou_hour_glass(1);
         wid._insert_font_list('s',_display_wid.p_font_name);
         mou_hour_glass(0);
         wid._lbsort('-n');
      }
   } else if(pos(' 'depname' ',' 'CBLIST_PROPS' ',1,'i')){
      isCombo=1;
      if (!setNodeEditStyle) {
         cblist_props_fillin_combo(depname,index,wid);
      }
   } else if(pos(' 'lowcase(depname)' ',' activecolor forecolor backcolor ')){
      if (setNodeEditStyle) {
         _TreeSetNodeEditStyle(index,1,TREE_EDIT_TEXTBOX|TREE_EDIT_BUTTON);
      }
      //isCombo=1;
   } else if(pos(' 'lowcase(depname)' ',' activepicture collapsepicture expandpicture picture leafpicture ')){
      if (setNodeEditStyle) {
         _TreeSetNodeEditStyle(index,1,TREE_EDIT_TEXTBOX|TREE_EDIT_BUTTON);
      } else {
         wid.p_text=value;
         wid.p_ReadOnly=true;
      }
   }

   if (setNodeEditStyle) {
      if (isCombo) {
         _TreeSetNodeEditStyle(index,1,comboBoxOption);
      }
   }
}
void _deupdate_edit_in_place_types() {
   int index=_delist_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) return;
   for (;;) {
      _delist_wid._deupdate_edit_in_place(index,true);
      index=_TreeGetNextSiblingIndex(index);
      if (index<0) break;
   }

}
int _deupdate_property(int index,_str new_value,_str option='')
{
   typeless status='';
   _str value='';
   parse _TreeGetCaption(index) with _depname value;
   //say('_depname='_depname' value='value);
   //_str new_value=_decombo_wid.p_text;
   //say('update new='new_value' old='value' dep='_depname);
   if (_deNofselected<=1 && value==new_value && option=='') return(0);
   _str list='';
   /* if (pos(' '_depname' ',' 'BOOLEAN_PROPS' ',1,'i')) { */
      /* list=TRUEFALSE_LIST */
   if(pos(' '_depname' ',' 'INT_PROPS' ',1,'i')){
      if (!isinteger(new_value)) {
         //_deupdate_combo();
         popup_message(nls('Invalid property value'));
         return(-1);
      }
      _str min_value=eq_name2value(_depname,MIN_VALUES);
      if (min_value!='' && new_value<min_value) {
         //_deupdate_combo();
         popup_message(nls('Invalid property value'));
         return(-1);
      }
      _str max_value=eq_name2value(_depname,MAX_VALUES);
      if (max_value!='' && new_value>max_value) {
         //_deupdate_combo();
         popup_message(nls('Invalid property value'));
         return(-1);
      }
      return _deset_property(_display_wid,_depname,new_value);
   } else if (lowcase(_depname)=='command' || lowcase(_depname)=='help' || lowcase(_depname)=='activehelp'){
   } else if(pos(' '_depname' ',' 'CBLIST_PROPS' ',1,'i') ||
             pos(' '_depname' ',' 'BOOLEAN_PROPS' ',1,'i')){
#if 0
      if (!_decombo_wid.p_cb_list_box.p_Noflines) {
         _decombo_wid._defill_cblist();
      }
      status=_decombo_wid._cbi_search('','$');
      if (status) {  // String not found?
         //_deupdate_combo();
         _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
         return(-1);
      }
      _decombo_wid.p_cb_list_box._lbselect_line();
      new_value=_decombo_wid.p_cb_list_box._lbget_text();
#endif
   }
   status=_deset_property(_display_wid,_depname,new_value);
   //if (status) _deupdate_combo();
   if (lowcase(_depname)=='name'){
      _deupdate_caption();
   }
   if (status) {
      return -1;
   }
   return(0);
}
#if 0
_str _deupdate_property(_str option='')
{
   typeless status='';
   _str value='';
   parse _delist_wid._lbget_text() with _depname value;
   _str new_value=_decombo_wid.p_text;
   if (value==new_value && option=='') return('');
   _str list='';
   /* if (pos(' '_depname' ',' 'BOOLEAN_PROPS' ',1,'i')) { */
      /* list=TRUEFALSE_LIST */
   if(pos(' '_depname' ',' 'INT_PROPS' ',1,'i')){
      if (!isinteger(new_value)) {
         _deupdate_combo();
         _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
         return('');
      }
      _str min_value=eq_name2value(_depname,MIN_VALUES);
      if (min_value!='' && new_value<min_value) {
         _deupdate_combo();
         //popup_message(nls('Invalid property value'))
         _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
         return('');
      }
      _str max_value=eq_name2value(_depname,MAX_VALUES);
      if (max_value!='' && new_value>max_value) {
         _deupdate_combo();
         _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
         return('');
      }
      _deset_property(_display_wid,_depname,new_value);
      return('');
   } else if (lowcase(_depname)=='command' || lowcase(_depname)=='help' || lowcase(_depname)=='activehelp'){
   } else if(pos(' '_depname' ',' 'CBLIST_PROPS' ',1,'i') ||
             pos(' '_depname' ',' 'BOOLEAN_PROPS' ',1,'i')){

      if (!_decombo_wid.p_cb_list_box.p_Noflines) {
         _decombo_wid._defill_cblist();
      }
      status=_decombo_wid._cbi_search('','$');
      if (status) {  // String not found?
         _deupdate_combo();
         _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
         return('');
      }
      _decombo_wid.p_cb_list_box._lbselect_line();
      new_value=_decombo_wid.p_cb_list_box._lbget_text();
   }
   status=_deset_property(_display_wid,_depname,new_value);
   if (status) {
      _deupdate_combo();
   }
   if (lowcase(_depname)=='name'){
      _deupdate_caption();
   }
   return('');
}
#endif
static _deupdate_caption()
{
   _str title='';
   if (_display_wid.p_object==OI_FORM) {
      title=_display_wid.p_name' Properties';
   } else {
      title=_get_form(_display_wid).p_name'.':+
                            _display_wid.p_name' Properties';
   }
   _deform_wid.p_caption=translate(title,'_','-');
}
static int _deset_property(int _display_wid, _str pname, typeless value)
{
   typeless status=_set_property(_display_wid,pname,value);
   if (status==1) {
      //_deupdate_combo();
      _post_call(find_index('popup_message',COMMAND_TYPE),nls('Invalid property value'));
   } else if (status==2){
      //_deupdate_combo();
      _post_call(find_index('popup_message',COMMAND_TYPE),nls('You already have a control with this name'));
   } else if (status==3){
      //_deupdate_combo();
      _post_call(find_index('popup_message',COMMAND_TYPE),nls('You already have a form with this name'));
   } else if (status==4){
      //_deupdate_combo();
      _post_call(find_index('popup_message',COMMAND_TYPE),nls('Event table not found'));
   } else if (status<0){
      //_deupdate_combo();
      _post_call(find_index('popup_message',COMMAND_TYPE),nls('Unable to set property %s to %s',pname,value)'.  'get_message(status));
   } else {
      //_delist_wid._lbset_item(pname:+\t:+value);
   }
   //_delist_wid._lbselect_line();
   if (!status && _deNofselected>1) {
      _for_each_control(_get_form(_display_wid),
                     '_deset_selprop','',pname,value);
   }
   if (status) {
      return -1;
   }
   return(0);
}
_str _deset_selprop(int wid, _str pname, typeless value)
{
   if (wid.p_selected && wid!=_display_wid) {
      _set_property(wid,pname,value);
   }
   return(0);
}

static _str _set_property(int _display_wid, _str _depname, var value)
{
   int wid=0;
   int index=0;
   int status=0;
   _suspend();
   if ( rc ) {
      if (isinteger(rc) && rc<0 ) {
         return(1);
      }
      if ( rc==10 ) {  /* No error? */
         return(0);
      }
      return(rc);
   }
   int orig_wid=p_window_id;
   p_window_id=_display_wid;
   typeless new_value=value;
   switch (_depname) {
   case "ActiveCaption":
      p_ActiveCaption=new_value;
      break;
   case "ActiveEnabled":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_ActiveEnabled=new_value;
      break;
   case "ActiveHelp":
      p_ActiveHelp=new_value;
      break;
   case "ActiveOrder":
      p_ActiveOrder=new_value;
      _deupdate();
      break;
   case "ActiveColor":
      new_value=hex2dec(new_value);
      if (new_value!='') {
         p_ActiveColor=new_value;
         value=_format_color(new_value);
         _deupdate();
      } else {
         status=1;
      }
      break;
   case "ActivePicture":
      if (new_value=='') {
         p_ActivePicture=0;
      } else {
         /* Replace or load a picture. */
         index=_update_picture(-1,new_value);
         if (index<0) {
            status=index;
         } else {
            p_ActivePicture=index;
            // Set the picture property again to the same value
            // just incase other windows are displaying this
            // picture, the editor will refresh them.
            p_ActivePicture=index;
         }
         value=_strip_filename(value,'P');
      }
      break;
   case "ActiveTab":
      p_ActiveTab=new_value;
      _deupdate();
      break;
   case "ActiveToolTip":
      p_ActiveToolTip=new_value;
      break;
   case "after_pic_indent_x":
      p_after_pic_indent_x=new_value;
      _deupdate();
      break;
   case "alignment":
      typeless old_value=new_value;
      _str list='';
      if (!isinteger(new_value)) {
         if (_display_wid.p_object==OI_CHECK_BOX) {
            list=AL_CHECK_LIST;
         } else {
            list=AL_LIST;
         }
         new_value=eq_name2value(new_value,list);
      }
      p_alignment=new_value;
      break;
   case "auto_size":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_auto_size=new_value;
      break;
   case "backcolor":
      new_value=hex2dec(new_value);
      if (new_value!='') {
         p_backcolor=new_value;
         value=_format_color(new_value);
      } else {
         status=1;
      }
      break;
   case 'border_style':
      if (!isinteger(new_value)) {
         if (_display_wid.p_object==OI_FORM) {
            list=BDS_FORM_LIST;
         } else if (_display_wid.p_object==OI_LABEL) {
            list=BDS_LIST2;
         } else if (_display_wid.p_object==OI_PICTURE_BOX) {
            list=BDS_LIST3;
         } else if (_display_wid.p_object==OI_IMAGE) {
            list=BDS_LIST3;
         } else {
            list=BDS_LIST;
         }
         new_value=eq_name2value(new_value,list);
      }
      p_border_style=new_value;
      break;
   case "cancel":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_cancel=new_value;
      break;
   case "caption":
      p_caption=new_value;
      break;
   case "case_sensitive":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_case_sensitive=new_value;
      break;
   case "CaptionClick":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_CaptionClick=new_value;
      break;
   case "checkable":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_checkable=new_value;
      break;
   case "CheckListBox":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_CheckListBox=new_value;
      break;
   case "clip_controls":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_clip_controls=new_value;
      break;
   case "CollapsePicture":
      if (new_value=='') {
         p_CollapsePicture=0;
      } else {
         /* Replace or load a picture. */
         index=_update_picture(-1,new_value);
         if (index<0) {
            status=index;
         } else {
            p_CollapsePicture=index;
            // Set the picture property again to the same value
            // just incase other windows are displaying this
            // picture, the editor will refresh them.
            p_CollapsePicture=index;
         }
         value=_strip_filename(value,'P');
      }
      break;
   case "command":
      p_command=new_value;
      break;
   case "completion":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,CP_LIST);
      }
      if (new_value=='.') new_value='';
      p_completion=new_value;
      break;
   case "ListCompletions":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_ListCompletions=new_value;
      break;
   case "default":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_default=new_value;
      break;
   case "delay":
      p_delay=new_value;
      break;
   case "DisplayTopOfFile":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_DisplayTopOfFile=new_value;
      break;
   case "DropDownList":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_DropDownList=new_value;
      break;
   case "EditInPlace":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_EditInPlace=new_value;
      break;
   case "eventtab":
      if (new_value=='') {
         new_value=0;
      } else {
         new_value=find_index(new_value,EVENTTAB_TYPE);
         if (!new_value) {
            status=4;
            break;
         }
      }
      p_eventtab=new_value;
      break;
   case "eventtab2":
      if (new_value=='') {
         new_value=0;
      } else {
         new_value=find_index(new_value,EVENTTAB_TYPE);
         if (!new_value) {
            status=4;
            break;
         }
      }
      p_eventtab2=new_value;
      break;
   case "enabled":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_enabled=new_value;
      break;
   case "ExpandPicture":
      if (new_value=='') {
         p_ExpandPicture=0;
      } else {
         /* Replace or load a picture. */
         index=_update_picture(-1,new_value);
         if (index<0) {
            status=index;
         } else {
            p_ExpandPicture=index;
            // Set the picture property again to the same value
            // just incase other windows are displaying this
            // picture, the editor will refresh them.
            p_ExpandPicture=index;
         }
         value=_strip_filename(value,'P');
      }
      break;
   case "FirstActiveTab":
      p_FirstActiveTab=new_value;
      _deupdate();
      break;
   case "font_bold":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_font_bold=new_value;
      break;
   case "font_italic":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_font_italic=new_value;
      break;
   case "font_name":
      p_font_name=new_value;
      break;
   case "font_size":
      p_font_size=new_value;
      break;
   case "font_underline":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_font_underline=new_value;
      break;
   case "forecolor":
      new_value=hex2dec(new_value);
      if (new_value!='') {
         p_forecolor=new_value;
         value=_format_color(new_value);
      } else {
         status=1;
      }
      break;
   case "Gridlines":
      p_Gridlines=eq_name2value(new_value,TREE_GRIDLINE_LIST);
      break;
   case "height":
      p_height=new_value;
      break;
   case "help":
      p_help=new_value;
      break;
   case "increment":
      p_increment=new_value;
      break;
   case "large_change":
      p_large_change=new_value;
      break;
   case "LeafPicture":
      if (new_value=='') {
         p_LeafPicture=0;
      } else {
         /* Replace or load a picture. */
         index=_update_picture(-1,new_value);
         if (index<0) {
            status=index;
         } else {
            p_LeafPicture=index;
            // Set the picture property again to the same value
            // just incase other windows are displaying this
            // picture, the editor will refresh them.
            p_LeafPicture=index;
         }
         value=_strip_filename(value,'P');
      }
      break;
   case "LevelIndent":
      p_LevelIndent=new_value;
      break;
   case "LineStyle":
      p_LineStyle=eq_name2value(new_value,TREE_LINE_LIST);
      break;
   case "max":
      p_max=new_value;
      break;
   case "max_button":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_max_button=new_value;
      break;
   case "min_button":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_min_button=new_value;
      break;
   case "min":
      p_min=new_value;
      break;
   case "max_click":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,MC_LIST);
      }
      p_max_click=new_value;
      break;
   case "message":
      p_message=new_value;
      break;
   case "mouse_pointer":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,MP_LIST);
      }
      p_mouse_pointer=new_value;
      break;
   case "multi_select":
      if (!isinteger(new_value)) {
         switch(p_object){
         case OI_TREE_VIEW:
            list=MS_LIST_TREEVIEW;
            break;
         default:
            list=MS_LIST;
            break;
         }
         new_value=eq_name2value(new_value,list);
      }
      p_multi_select=new_value;
      break;
   case "name":
      if (!(new_value=='' && p_object!=OI_FORM) && !isid_valid(new_value)) {
         status=1;
         break;
      }
      if (!name_eq(p_name,new_value)) {
         if (p_object==OI_FORM) {
            index=find_index(new_value,oi2type(OI_FORM));
            if (index && index!=p_template){
               status=3;
               break;
            }
         } else {
            wid=_find_control(new_value);
            if (new_value!='' && wid) {
               status=2;
               break;
            }
         }
      }
      p_name=new_value;
      break;
   case "Nofstates":
      p_Nofstates=new_value;
      break;
   case "NofTabs":
      p_NofTabs=new_value;
      _deupdate();
      break;
   case "Orientation":
      if( p_object==OI_SSTAB ) {
         p_Orientation=eq_name2value(new_value,SSTAB_ORIENTATION_LIST);
      } else if( p_object==OI_IMAGE ) {
         p_Orientation=eq_name2value(new_value,PSPIC_ORIENTATION_LIST);
      }
      break;
   case "PaddingX":
      p_PaddingX=new_value;
      break;
   case "PaddingY":
      p_PaddingY=new_value;
      break;
   case "picture":
      if (new_value=='') {
         p_picture=0;
      } else {
         /* Replace or load a picture. */
         index=_update_picture(-1,new_value);
         if (index<0) {
            status=index;
         } else {
            p_picture=index;
            // Set the picture property again to the same value
            // just incase other windows are displaying this
            // picture, the editor will refresh them.
            p_picture=index;
         }
         value=_strip_filename(value,'P');
      }
      break;
   case "PictureOnly":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_PictureOnly=new_value;
      break;
   case "ReadOnly":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_ReadOnly=new_value;
      break;
   case "Password":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_Password=new_value;
      break;
   case "scroll_bars":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,SB_LIST);
      }
      p_scroll_bars=new_value;
      break;
   case "ShowRoot":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_ShowRoot=new_value;
      break;
   case "AlwaysColorCurrent":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_AlwaysColorCurrent=new_value;
      break;
   case "NeverColorCurrent":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_NeverColorCurrent=new_value;
      break;
   case "ColorEntireLine":
      new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      p_ColorEntireLine=new_value;
      break;
   case "interpret_html":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_interpret_html=new_value;
      break;
   case "SpaceY":
      p_SpaceY=new_value;
      break;
   case "small_change":
      p_small_change=new_value;
      break;
   case "stretch":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_stretch=new_value;
      break;
   case "style":
      if (!isinteger(new_value)) {
         list='';
         switch (p_object) {
         case OI_CHECK_BOX:
            list=PSCH_LIST;
            break;
         case OI_COMBO_BOX:
            list=PSCBO_LIST;
            break;
         case OI_GAUGE:
            list=PSGA_LIST;
            break;
         case OI_PICTURE_BOX:
            list=PSPIC_LIST;
            break;
         case OI_IMAGE:
            list=PSIMG_LIST;
            break;
         }
         if (list=='') break;
         old_value=new_value;
         new_value=eq_name2value(new_value,list);
         if (new_value=='') {
            status=1;
            break;
         }
      }
      p_style=new_value;
      break;
   case "tab_index":
      _set_tab_index(new_value);
      break;
   case "tab_stop":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_tab_stop=new_value;
      break;
   case "text":
      if (p_object==OI_MINIHTML) {
         p_text=new_value;
      } else {
         boolean orig_ReadOnly;
         if (p_object==OI_TEXT_BOX) {
            orig_ReadOnly=p_ReadOnly;
            p_ReadOnly=0;
         }
         p_text=new_value;
         if (p_object==OI_TEXT_BOX) {
            p_ReadOnly=orig_ReadOnly;
         }
      }
      break;
   case "UseFileInfoOverlays":
      new_value=eq_name2value(new_value,TREE_FILE_INFO_OVERLAY_LIST);
      p_UseFileInfoOverlays=new_value;
      break;
#if 0
   case "validate_style":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,VS_LIST);
      }
      p_validate_style=new_value;
      break;
#endif
   case "value":
      if (isinteger(new_value)) {
         //max_value=value;
         if (p_object==OI_CHECK_BOX) {
            int max_value=0;
            if (p_style==PSCH_AUTO2STATE) {
               max_value=1;
            } else {
               max_value=2;
            }
            if (value>max_value) {
               value=max_value;
            }
         }
         p_value=value;
      } else {
         status=2;
      }
      break;
   case "tool_window":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_tool_window=new_value;
      break;
   case "visible":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_visible=new_value;
      break;
   case "width":
      p_width=new_value;
      break;
   case "word_wrap":
      if (!isinteger(new_value)) {
         new_value=eq_name2value(new_value,TRUEFALSE_LIST);
      }
      p_word_wrap=new_value;
      break;
   case "x":
      p_x=new_value;
      break;
   case "y":
      p_y=new_value;
      break;
   }
   p_window_id=orig_wid;
   if (status) {
      rc=status;_resume();
   }
   rc=10;_resume();

   //We never hit this
   return(0);
}
#if 0
_delist_dclick()
{
   _str value='';
   typeless status;
   int min_value=0;
   int max_value=0;
   parse _delist_wid._lbget_text() with _depname value;
   if (lowcase(_depname)=='value' &&
       (_display_wid.p_object==OI_CHECK_BOX|| _display_wid.p_object==OI_RADIO_BUTTON)) {
       max_value=0;
       if (_display_wid.p_style==PSCH_AUTO2STATE||_display_wid.p_object==OI_RADIO_BUTTON) {
          max_value=1;
       } else {
          max_value=2;
       }
       ++value;
       if (value>max_value) {
          value=0;
       }
       _ignore_combo_change=1;
       _decombo_wid.p_text=value;
       _ignore_combo_change=0;
       _deset_property(_display_wid,_depname,value);
       return('');
   } else if (_decombo_wid.p_cb_picture.p_picture==_pic_cbdots){
      _decombo_wid.p_cb_active=_decombo_wid.p_cb_picture;
      _decombo_wid.call_event(_decombo_wid,LBUTTON_DOWN);

   } else if (lowcase(_depname)=='command' || lowcase(_depname)=='help' || lowcase(_depname)=='activehelp'){
      // The list for a command is too long to go to the next item. */
   } else if((lowcase(_depname)=='font_size' && !_isscalable_font(_display_wid.p_font_name,'s')) ||
              pos(' '_depname' ',' 'CBLIST_PROPS' ',1,'i') ||
             pos(' '_depname' ',' 'BOOLEAN_PROPS' ',1,'i')){

      if (!_decombo_wid.p_cb_list_box.p_Noflines) {
         _decombo_wid._defill_cblist();
      }
      _str before=_decombo_wid.p_text;
      status=_decombo_wid._cbi_search();
      if (!status) {  // String found?
         status=_decombo_wid.p_cb_list_box.down();
         if (status) {  // Bottom of file?
            _decombo_wid.p_cb_list_box.top();
         }
         value=_decombo_wid.p_cb_list_box._lbget_text();
         _ignore_combo_change=1;
         _decombo_wid.p_text=value;
         _ignore_combo_change=0;
         _deset_property(_display_wid,_depname,value);
         return('');
      }
   } else if(pos(' '_depname' ',' 'INCINT_PROPS' ',1,'i')){
      if (!isinteger(value)) {
         popup_message(nls('Invalid property value'));
         return('');
      }
      min_value=eq_name2value(_depname,MIN_VALUES);
      max_value=eq_name2value(_depname,MAX_VALUES);
      ++value;
      if (max_value!='' && value>max_value) {
         if (min_value!='') {
            value=min_value;
            _ignore_combo_change=1;
            _decombo_wid.p_text=value;
            _ignore_combo_change=0;
            _deset_property(_display_wid,_depname,value);
            return('');
         }
         --value;
      } else {
         _ignore_combo_change=1;
         _decombo_wid.p_text=value;
         _ignore_combo_change=0;
         _deset_property(_display_wid,_depname,value);
         return('');
      }
   }
   p_window_id=_decombo_wid.p_cb_text_box;
   _decombo_wid.p_cb_text_box._set_sel(1,length(_decombo_wid.p_cb_text_box.p_text)+1);_set_focus();
   return('');
}
#endif
static _deget_object_props(int object)
{
   _str props='';
   switch (object) {
   case OI_FORM:
      props=FORM_PROPS;
      break;
   case OI_TEXT_BOX:
      props=TEXT_BOX_PROPS;
      break;
   case OI_COMMAND_BUTTON:
      props=COMMAND_BUTTON_PROPS;
      break;
   case OI_CHECK_BOX:
      props=CHECK_BOX_PROPS;
      break;
   case OI_RADIO_BUTTON:
      props=RADIO_BUTTON_PROPS;
      break;
   case OI_FRAME:
      props=FRAME_PROPS;
      break;
   case OI_LABEL:
      props=LABEL_PROPS;
      break;
   case OI_LIST_BOX:
      props=LIST_BOX_PROPS;
      break;
   case OI_EDITOR:
      props=EDITOR_PROPS;
      break;
   case OI_SSTAB:
      props=SSTAB_PROPS;
      break;
   case OI_TREE_VIEW:
      props=TREE_VIEW_PROPS;
      break;
   case OI_MINIHTML:
      props=MINIHTML_PROPS;
      break;
   case OI_COMBO_BOX:
      props=COMBO_BOX_PROPS;
      break;
   case OI_IMAGE:
      props=IMAGE_PROPS;
      break;
   case OI_PICTURE_BOX:
      props=PICTURE_BOX_PROPS;
      break;
   case OI_HSCROLL_BAR:
   case OI_VSCROLL_BAR:
      props=SCROLL_BAR_PROPS;
      break;
   case OI_GAUGE:
      props=GAUGE_PROPS;
      break;
   case OI_SPIN:
      props=SPIN_PROPS;
      break;
   case OI_SWITCH:
      props=SWITCH_PROPS;
      break;
   }
   return(props);
}
static _demerge_props()
{
   // Create list of objects that are different  OI_??? */
   _str objects='';
   int child=_display_wid;
   int hit_label=0;
   for (;;) {
      if (child.p_selected) {
         if (!pos(' 'child.p_object' ',' 'objects' ')) {
            objects=objects' ':+child.p_object;
            if (child.p_object==OI_LABEL) {
               hit_label=1;
            }
         }
      }
      child=child.p_next;
      if (child==_display_wid) break;
   }
   typeless object='';
   parse objects with object objects;
   _str props=_deget_object_props(object);
   _str property='';
   // IF there is only one type of object AND this
   // object has a style property
   int insert_style=0;
   if (objects=='' && pos(' 'object' ',
       ' 'OI_CHECK_BOX' 'OI_COMBO_BOX' 'OI_GAUGE' 'OI_PICTURE_BOX' 'OI_IMAGE' ')) {
       insert_style=1;
   }
   //IF there is more than one type of object AND
   int remove_border_property=0;
   if (objects!='' && hit_label) {
      remove_border_property=1;
   }
   for (;;) {
      parse objects with object objects;
      if (object=='') break;
      _str props2=_deget_object_props(object);
      _str new_props='';
      for (;;) {
         parse props with property props;
         if (property=='') break;
         if (pos(' 'property' ',' 'props2' ')) {
            new_props=new_props' 'property;
         }
      }
      props=new_props;
   }
   for (;;) {
      parse props with property props;
      if (insert_style && 'style'<property) {
         _TreeAddItem(TREE_ROOT_INDEX,"style\t"_get_property(_display_wid,"style"),TREE_ADD_AS_CHILD,0,0,-1);
         insert_style=0;
      }
      if (property=='') break;
      if (!remove_border_property || property!='border_style') {
         //say('prop='property' r='_get_property(_display_wid,property));
         _TreeAddItem(TREE_ROOT_INDEX,property"\t"_get_property(_display_wid,property),TREE_ADD_AS_CHILD,0,0,-1);
      }
   }
   _deupdate_edit_in_place_types();
}
static _str _get_property(int _display_wid, _str property)
{
   _str list='';
   switch (property) {
   case "ActiveCaption":
      return(_display_wid.p_ActiveCaption);
   case "ActiveEnabled":
      return(_bool2TRUEFALSE(_display_wid.p_ActiveEnabled));
   case "ActiveHelp":
      return(_display_wid.p_ActiveHelp);
   case "ActiveOrder":
      return(_display_wid.p_ActiveOrder);
   case "ActiveColor":
      return(_format_color(_display_wid.p_ActiveColor));
   case "ActivePicture":
      return(name_name(_display_wid.p_ActivePicture));
   case "ActiveTab":
      return(_display_wid.p_ActiveTab);
   case "ActiveToolTip":
      return(_display_wid.p_ActiveToolTip);
   case "after_pic_indent_x":
      return(_display_wid.p_after_pic_indent_x);
   case "alignment":
      return(eq_value2name(_display_wid.p_alignment,AL_LIST));
   case "auto_size":
      return(_bool2TRUEFALSE(_display_wid.p_auto_size));
   case "backcolor":
      return(_format_color(_display_wid.p_backcolor));
   case "border_style":
      //say('_display_wid.p_border_style='_display_wid.p_border_style' r='eq_value2name(_display_wid.p_border_style,BDS_LIST));
      if (_display_wid.p_object==OI_LABEL) {
         return(eq_value2name(_display_wid.p_border_style,BDS_LIST2));
      } else if (_display_wid.p_object==OI_PICTURE_BOX) {
         return(eq_value2name(_display_wid.p_border_style,BDS_LIST3));
      } else if (_display_wid.p_object==OI_IMAGE) {
         return(eq_value2name(_display_wid.p_border_style,BDS_LIST3));
      } else {
         return(eq_value2name(_display_wid.p_border_style,BDS_LIST));
      }
   case "cancel":
      return(_bool2TRUEFALSE(_display_wid.p_cancel));
   case "caption":
      return(_display_wid.p_caption);
   case "case_sensitive":
      return(_bool2TRUEFALSE(_display_wid.p_case_sensitive));
   case "CaptionClick":
      return(_bool2TRUEFALSE(_display_wid.p_CaptionClick));
   case "CheckListBox":
      return(_display_wid.p_CheckListBox);
   case "clip_controls":
      return(_bool2TRUEFALSE(_display_wid.p_clip_controls));
   case "CollapsePicture":
      return(_display_wid.p_CollapsePicture);
   case "default":
      return(_bool2TRUEFALSE(_display_wid.p_default));
   case "delay":
      return(_display_wid.p_delay);
   case "DisplayTopOfFile":
      return(_bool2TRUEFALSE(_display_wid.p_DisplayTopOfFile));
   case "DropDownList":
      return(_bool2TRUEFALSE(_display_wid.p_DropDownList));
   case "enabled":
      return(_bool2TRUEFALSE(_display_wid.p_enabled));
   case "eventtab":
      return(translate(name_name(_display_wid.p_eventtab),'_','-'));
   case "eventtab2":
      return(translate(name_name(_display_wid.p_eventtab2),'_','-'));
   case "ExpandPicture":
      return(_display_wid.p_ExpandPicture);
   case "FirstActiveTab":
      return(_display_wid.p_FirstActiveTab);
   case "font_bold":
      return(_bool2TRUEFALSE(_display_wid.p_font_bold));
   case "font_italic":
      return(_bool2TRUEFALSE(_display_wid.p_font_italic));
   case "font_name":
      return(_display_wid.p_font_name);
   case "font_size":
      return(_display_wid.p_font_size);
   case "font_underline":
      return(_bool2TRUEFALSE(_display_wid.p_font_underline));
   case "forecolor":
      return(_format_color(_display_wid.p_forecolor));
   case "height":
      return(_display_wid.p_height);
   case "increment":
      return(_display_wid.p_increment);
   case "large_change":
      return(_display_wid.p_large_change);
   case "LeafPicture":
      return(_display_wid.p_LeafPicture);
   case "LevelIndent":
      return(_display_wid.p_LevelIndent);
   case "max":
      return(_display_wid.p_max);
   case "max_button":
      return(_bool2TRUEFALSE(_display_wid.p_max_button));
   case "min_button":
      return(_bool2TRUEFALSE(_display_wid.p_min_button));
   case "min":
      return(_display_wid.p_min);
   case "max_click":
      return(eq_value2name(_display_wid.p_max_click,MC_LIST));
   case "mouse_pointer":
      return(eq_value2name(_display_wid.p_mouse_pointer,MP_LIST));
   case "multi_select":
      return(eq_value2name(_display_wid.p_multi_select,MS_LIST));
   /* case "name":  Don't need this for dialog editor */
   case "Nofstates":
      return(_display_wid.p_Nofstates);
   case "NofTabs":
      return(_display_wid.p_NofTabs);
   case "Orientation":
      if( _display_wid.p_object==OI_SSTAB ) {
         return(eq_value2name(_display_wid.p_Orientation,SSTAB_ORIENTATION_LIST));
      } else {
         // OI_IMAGE
         return(eq_value2name(_display_wid.p_Orientation,PSPIC_ORIENTATION_LIST));
      }
   case "PaddingX":
      return(_display_wid.p_PaddingX);
   case "PaddingY":
      return(_display_wid.p_PaddingY);
   case "picture":
      return(name_name(_display_wid.p_picture));
   case "PictureOnly":
      return(_bool2TRUEFALSE(_display_wid.p_PictureOnly));
   case "ReadOnly":
      return(_bool2TRUEFALSE(_display_wid.p_ReadOnly));
   case "Password":
      return(_bool2TRUEFALSE(_display_wid.p_Password));
   case "scroll_bars":
      return(eq_value2name(_display_wid.p_scroll_bars,SB_LIST));
   case "ShowRoot":
         return(_display_wid.p_ShowRoot);
   case "AlwaysColorCurrent":
         return(_display_wid.p_AlwaysColorCurrent);
   case "NeverColorCurrent":
         return(_display_wid.p_NeverColorCurrent);
   case "ColorEntireLine":
         return(_display_wid.p_ColorEntireLine);
   case "small_change":
      return(_display_wid.p_small_change);
   case "SpaceY":
      return(_display_wid.p_SpaceY);
   case "stretch":
      return(_bool2TRUEFALSE(_display_wid.p_stretch));
   case "style":
      switch (_display_wid.p_object) {
      case OI_CHECK_BOX:
         list=PSCH_LIST;
         break;
      case OI_COMBO_BOX:
         list=PSCBO_LIST;
         break;
      case OI_GAUGE:
         list=PSGA_LIST;
         break;
      case OI_PICTURE_BOX:
         list=PSPIC_LIST;
         break;
      case OI_IMAGE:
         list=PSIMG_LIST;
         break;
      }
      return(eq_value2name(_display_wid.p_style,list));
   /* case "tab_index": Don't need this for dialog editor */
   case "tab_stop":
      return(_bool2TRUEFALSE(_display_wid.p_tab_stop));
   case "text":
      return(_display_wid.p_text);
   case "value":
      return(_display_wid.p_value);
   case "tool_window":
      return(_bool2TRUEFALSE(_display_wid.p_visible));
   case "visible":
      return(_bool2TRUEFALSE(_display_wid.p_visible));
   case "width":
      return(_display_wid.p_width);
   case "x":
      return(_display_wid.p_x);
   case "y":
      return(_display_wid.p_y);
   }
   return('');
}
static _str cp_value2name(_str cp_value)
{
   if (cp_value=='') {
      return('NONE_ARG');
   }
   _str name=eq_value2name(cp_value,CP_LIST);
   return(name);
}

void _insert_menu_source(int index, int indent, int add_indent, _str form_name)
{
   form_name=translate(form_name,'_','-');
   if (!(index & 0xffff0000)) {
      index=index << 16;
   }
   boolean first_time=!(index & 0xffff);
   if (first_time) {
      insert_line(substr('',1,indent):+'_menu 'index.p_name' {');
   } else {
      /* p_caption, p_help, p_message, p_categories */
      insert_menu_strings(substr('',1,indent):+'submenu ',index.p_caption,index.p_help,index.p_message,index.p_categories);
   }
   int child=index.p_child;
   if (child) {
      int first_child=child;
      for (;;) {
         if (child.p_object==OI_MENU) {
            _insert_menu_source(child,indent+add_indent,add_indent,form_name);
         } else {
            insert_menu_strings(substr('',1,indent+add_indent),
                                child.p_caption,
                                child.p_command,
                                child.p_categories,
                                child.p_help,
                                child.p_message
                                );
         }
         child=child.p_next;
         if (child==first_child) break;
      }
   }
   //if (first_time) {
      insert_line(substr('',1,indent)'}');
   //} else {
   //   insert_line(substr('',1,indent)'endsubmenu');
   //}
}
static void insert_menu_strings(_str result,...)
{
   _str brace_str = pos("submenu",result)? " {":";";
   int i;
   for (i=2;i<=arg();++i) {
      _str special_chars="\b\f\n\r\t";
      _str string=arg(i);
      if(verify(string,special_chars,'M')) {
         string=_quote_tm(string);
      } else if(!pos('"',string) && !pos('\',string)){
         string='"'string'"';
      }  else {
         string=_quote_tm(string);
      }
      if (i==2) {
         result=result:+string;
      } else {
         result=result','string;
      }
   }
   if (result!='') {
      insert_line(result:+brace_str);
   }
}

static void _de_sortselected(int first_child, int (&wid_list)[], _str sort_by_prop = '')
{
   wid_list._makeempty();
   int child=first_child;
   for (;;) {
      if (child.p_selected) {
         wid_list[wid_list._length()] = child;
      }
      child=child.p_next;
      if (child==first_child) break;
   }
   if (sort_by_prop != '') {
      int i, j;
      int len = wid_list._length();
      for (i = 1; i < len; i++) {
         int wid = wid_list[i];
         typeless value = _get_property(wid_list[i], sort_by_prop);
         for (j = i - 1; (j >= 0) && (_get_property(wid_list[j], sort_by_prop) > value); j--) {
            wid_list[j+1] = wid_list[j];   
         }
         wid_list[j+1] = wid;
      }
   }
}
static void _de_align_controls(_str options)
{
   int x, y, ax, ay, wid, i;
   int selected[];
   _de_sortselected(_display_wid, selected);
   switch (lowcase(options)) {
   // alignment
   case "l":   // left
      {   x = _display_wid.p_x;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "x", x);
         }
      }
      break;
   case "t":   // top
      {
         y = _display_wid.p_y;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "y", y);
         }
      }
      break;
   case "r":   // right
      {
         x = _display_wid.p_x + _display_wid.p_width;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            if (wid == _display_wid) continue;
            ax = x - wid.p_width;
            _set_property(wid, "x", ax);
         }
      }
      break;
   case "b":   // bottom
      {
         y = _display_wid.p_y + _display_wid.p_height;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            if (wid == _display_wid) continue;
            ay = y - wid.p_height;
            _set_property(wid, "y", ay);
         }
      }
      break;
   case "c":   // center
      {
         x = _display_wid.p_x + (_display_wid.p_width >> 1);
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            if (wid == _display_wid) continue;
            ax = x - (wid.p_width >> 1);
            _set_property(wid, "x", ax);
         }
      }
      break;
   case "m":   // mid
      {
         y = _display_wid.p_y + (_display_wid.p_height >> 1);
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            if (wid == _display_wid) continue;
            ay = y - (wid.p_height >> 1);
            _set_property(wid, "y", ay);
         }
      }
      break;
   }
}

static void _de_size_controls(_str options)
{
   int x, y, w, h, wid, i;
   int selected[];
   _de_sortselected(_display_wid, selected);
   switch (lowcase(options)) {
   case "=":   // equal width, height
      {   w = _display_wid.p_width;
          h = _display_wid.p_height;
          for (i = 0; i < selected._length(); ++i) {
             wid = selected[i];
             _set_property(wid, "width", w);
             _set_property(wid, "height", h);
          }
      }
      break;
   case "w":   // equal width
      {   
         w = _display_wid.p_width;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "width", w);
         }
      }
      break;
   case "h":   // equal height
      {   
         h = _display_wid.p_height;
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "height", h);
         }
      }
      break;
   case "ex":  // expand (left-1, top-1, right+1, bottom+1)
      {
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            x = wid.p_x - _twips_per_pixel_x();
            w = wid.p_width + _twips_per_pixel_x() * 2;
            y = wid.p_y - _twips_per_pixel_y();
            h = wid.p_height + _twips_per_pixel_y() * 2;
            _set_property(wid, "x", x);
            _set_property(wid, "y", y);
            _set_property(wid, "width", w);
            _set_property(wid, "height", h);
         }
      }
      break;
   case "co":  // contract (left+1, top+1, right-1, bottom-1)
      {
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            x = wid.p_x + _twips_per_pixel_x();
            w = wid.p_width - _twips_per_pixel_x() * 2;
            y = wid.p_y + _twips_per_pixel_y();
            h = wid.p_height - _twips_per_pixel_y() * 2;
            _set_property(wid, "x", x);
            _set_property(wid, "y", y);
            _set_property(wid, "width", w);
            _set_property(wid, "height", h);
         }
      }
      break;
   case "sq": // square (w = h)
      {
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            w = wid.p_width;
            _set_property(wid, "height", w);
         }
      }
      break;
   case "sw":  // shrinkwrap
      {
         for (i = 0; i < selected._length(); ++i) {
            wid = selected[i];
            if (wid.p_child == 0) continue;
            _get_child_extents(wid, w, h, false);
            _set_property(wid, "width", w);
            _set_property(wid, "height", h);
         }
      }
      break;
   }
}

static void _de_space_controls(_str options)
{
   int x, y, w, h, len, wid, i;
   int selected[];
   boolean vert_space = (pos('v', lowcase(options)) != 0);
   boolean inc_space = (pos('+', lowcase(options)) != 0);
   boolean dec_space = (pos('-', lowcase(options)) != 0);
   boolean no_spacing = (pos('0', lowcase(options)) != 0);

   if (!vert_space) {
       _de_sortselected(_display_wid, selected, "x");
   } else {
       _de_sortselected(_display_wid, selected, "y");
   }

   if (no_spacing) {
      if (vert_space) {
         y = selected[0].p_y + selected[0].p_height;
         for (i = 1; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "y", y);
            y = y + wid.p_height;
         }
      } else {
         x = selected[0].p_x + selected[0].p_width;
         for (i = 1; i < selected._length(); ++i) {
            wid = selected[i];
            _set_property(wid, "x", x);
            x = x + wid.p_width;
         }
      }
      return;
   }

   // these are sorted
   len = selected._length();
   w = selected[len-1].p_x - selected[0].p_x;
   h = selected[len-1].p_y - selected[0].p_y;

   if (vert_space) {
       w = 0;
       h = h /(len-1);
       if (inc_space) {
         h += _twips_per_pixel_y();
      } else if (dec_space) {
         h -= _twips_per_pixel_y();
      }
   } else {
      w = w/(len-1);
      h = 0;
      if (inc_space) {
         w += _twips_per_pixel_x();
      } else if (dec_space) {
         w -= _twips_per_pixel_x();
      }
   }

   if (w > 0) {
      x = selected[0].p_x + w;
      for (i = 1; i < selected._length(); ++i) {
         wid = selected[i];
         _set_property(wid, "x", x);
         x = x + w;
      }
   }

   if (h > 0) {
      y = selected[0].p_y + h;
      for (i = 1; i < selected._length(); ++i) {
         wid = selected[i];
         _set_property(wid, "y", y);
         y = y + h;
      }
   }
}

static void _de_center_controls(_str options)
{
   int x1, x2, y1, y2;
   int off_x, off_y, wid, i;
   int selected[];
   int wid_parent = _display_wid.p_parent;
   _de_sortselected(_display_wid, selected);
   x1 = _display_wid.p_x;
   x2 = _display_wid.p_x + _display_wid.p_width;
   y1 = _display_wid.p_y;
   y2 = _display_wid.p_y + _display_wid.p_height;
   for (i = 0; i < selected._length(); ++i) {
      wid = selected[i];
      x1 = (wid.p_x < x1) ? wid.p_x : x1;
      x2 = (wid.p_x + wid.p_width > x2) ? wid.p_x + wid.p_width : x2;
      y1 = (wid.p_y < y1) ? wid.p_y : y1;
      y2 = (wid.p_y + wid.p_height > y2) ? wid.p_y + wid.p_height : y2;
   }
   int parent_w = _dx2lx(_display_wid.p_active_form.p_xyscale_mode, wid_parent.p_client_width);
   int parent_h = _dy2ly(_display_wid.p_active_form.p_xyscale_mode, wid_parent.p_client_height);
   switch (lowcase(options)) {
   case "h":   // center horizontal
      {
         off_x = x1 - ((parent_w - (x2 - x1)) >> 1);
         off_y = 0;
      }
      break;
   case "v":   // center vertical
      {
         off_x = 0;
         off_y = y1 - ((parent_h - (y2 - y1)) >> 1);
      }
      break;
   case "b":   // center horizontal, vertical
      {
         off_x = x1 - ((parent_w - (x2 - x1)) >> 1);
         off_y = y1 - ((parent_h - (y2 - y1)) >> 1);
      }
      break;
   }
   for (i = 0; i < selected._length(); ++i) {
      wid = selected[i];
      int x = wid.p_x - off_x;
      int y = wid.p_y - off_y;
      _set_property(wid, "x", x);
      _set_property(wid, "y", y);
   }
}

static void _de_snap_controls()
{
   int x, y, wid, i;
   int selected[];
   int w = _grid_width();
   int h = _grid_height();
   _de_sortselected(_display_wid, selected);
   for (i = 0; i < selected._length(); ++i) {
      wid = selected[i];
      x = (wid.p_x / w) * w;
      y = (wid.p_y / h) * h;
      _set_property(wid, "x", x);
      _set_property(wid, "y", y);
   }

}

int _OnUpdate_vdlgedit_move(CMDUI cmdui, int target_wid, _str command)
{
   if (!p_active_form.p_edit || !_display_wid || (_display_wid == p_active_form)) return (MF_GRAYED);
   _str cmd, action, option;
   parse command with cmd action option;
   switch (lowcase(action)) {
   case "sz":
      if (option == "w" || option == "h" || option == "=") {
         if (_deNofselected <= 1) { 
            return (MF_GRAYED);
         }
      }
      return (MF_ENABLED);
   case "c":
   case "sn":
      return (MF_ENABLED);
   default:
      if (_deNofselected<=1) {
         return (MF_GRAYED);
      }
      break;
   }
   return (MF_ENABLED);
}

_command void vdlgedit_move(_str cmdline = '')
{
   _str action, option;
   parse cmdline with action option;
   if (!p_active_form.p_edit || !_display_wid) return; 
   switch (action) {
   case "al":
      _de_align_controls(option);
      break;
   case "sz":
      _de_size_controls(option);
      break;
   case "sp":
      _de_space_controls(option);
      break;
   case "c":
      _de_center_controls(option);
      break;
    case "sn":
      _de_snap_controls();
      break;
   default:
      break;
   }
   _deupdate();
}
