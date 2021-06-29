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
#import "complete.e"
#import "fontcfg.e"
#import "listbox.e"
#import "stdprocs.e"
#endregion

_control _bold;
_control _italic;
_control _strikethrough;
_control _underline;
_control _font_name_list;
_control _font_size_list;
_control _ok;
_control _cancel;
_control _sample_text;



const FONT_SIZE_LIST= '8 9 10 11 12 14 16 18 20 22 24 26 28 36 48 72';
const MINIMAP_FONT_SIZE_LIST= '1 2 3 4 5 6 7 8';
/*List of font sizes for scalable fonts*/


//#define CHANGING_SCRIPT_LIST  ctlScript.p_cb_list_box.p_user
static int FONT_CHANGING_NAME_LIST(...) {
   if (arg()) _sample_frame.p_user=arg(1);
   return _sample_frame.p_user;
}
static int FONT_CHANGING_SIZE_LIST(...) {
   if (arg()) _font_size_list.p_user=arg(1);
   return _font_size_list.p_user;
}

/*

   _font_name_list.p_user    Contains _insert_font_list options.
                             Not necessarily the original options.

*/

/**
 * Displays the <b>Font dialog box</b>.  The 'P' option specifies that 
 * printer fonts be listed.  <i>font</i> specifies the initial font displayed in 
 * this dialog box.
 * <p>
 * <i>Syntax</i>  _str show('-modal _font_form', <i>options</i> , 
 * <i>font</i>)
 * 
 * @param   options  a string of zero or more of the following option letters:
 * <DL compact style="margin-left:20pt;">
 *    <DT>F <DD>Display fixed fonts only.
 *    <DT>P <DD>Display printer fonts.  If not specified, screen fonts are displayed.
 * </DL>
 * 
 * @param   font  a string in the format: <i>font_name</i>, <i>font_size</i>, <i>font_flags </i>[,]
 * @param   font_size   a font point size.
 * @param   font_flags  is a combination of the following flags defined in 
 * "slick.sh":
 * <DL>
 *    <DT>F_BOLD
 *    <DT>F_ITALIC
 *    <DT>F_STRIKE_THRU
 *    <DT>F_UNDERLINE
 * </DL>
 * 
 * @return  Returns '' if the user cancels the dialog box.  Otherwise, a 
 * string in the same format as the <i>font</i> argument parameter is returned.
 * @example
 * <pre>
 *    font='Courier,10,0';
 *     // You can use the _font_param function to build the above string like this
 *     //     font=_font_param("Courier", 10, 0);
 *    result = show('-modal _font_form',
 *                  'F',      // Display fixed fonts only
 *                   font
 *                 );
 *    if (result == '') {
 *       return(COMMAND_CANCELLED_RC);
 *    }
 *    parse result with font_name','font_size','font_flags','
 * </pre>
 * @see _choose_font
 * @see _font_param
 * 
 * @appliesTo  All_Window_Objects
 * 
 * @categories Forms
 */
defeventtab _font_form;

_str get_font_name_from_list(bool useList=false)
{
   font_name := (useList || p_text=='')? _lbget_text() : p_text;
   if (endsWith(font_name, ")")) {
      parse font_name with font_name " (";
   }
   return font_name;
}

ctlfixedfonts.lbutton_up()
{
   _str options=_font_name_list.p_user;
   before := "";
   after := "";
   parse options with before 'f' after;
   options=before:+after;
   if (p_value) {
      options :+= 'f';
   }
   _font_name_list.p_user=options;
   font_name := _font_name_list.get_font_name_from_list();
   wid := _find_control("ctlEnableBoldAndItalic");
   if (wid > 0 && wid.p_visible) wid.p_enabled = (p_value != 0);
   FillInFontNameList(font_name,ctlfixedfonts.p_user!='');
}

void update_sample_text()
{
   _sample_text.p_redraw=false;
   _sample_text.p_font_name = _font_name_list.get_font_name_from_list(true);
   if (isinteger(_font_size_list.p_text)) {
      _sample_text.p_font_size = _font_size_list.p_text;
   }
   _sample_text.p_font_bold = _bold.p_value!=0;
   _sample_text.p_font_italic = _italic.p_value!=0;
   _sample_text.p_font_strike_thru = _strikethrough.p_value!=0;
   _sample_text.p_font_underline = _underline.p_value!=0;

   //_sample_text.p_font_charset=_CharSetName2Id(ctlScript.p_text);
   int charset=_sample_text.p_font_charset;
   if (charset==VSCHARSET_DEFAULT) {
      charset=_GetFontCharSet(_sample_text.p_font_name,_sample_text.p_font_size,_font_name_list.p_user);
   }

   _sample_text.p_caption=_CharSet2SampleText(charset);
   _sample_text.p_redraw=false;
}

/* Function to find item in list, select it, and put it in text box.*/
static typeless prepare_cb_and_list(_str item, bool setting_size)
{
   p_line = 1;
   if( _lbfind_and_select_item(item) < 0) {
      // try again with prefix match
      if (!_lbsearch(item)) {
         _lbselect_line();
         return(0);
      }
      // item was never found
      if (setting_size) {
         p_text=item;
         return('');
      }
      p_line = 1;
      if (item == ''){
         p_text = _lbget_text();
      } else {
         p_text = item;
      }
      _lbselect_line();
      return('');
   }
   return(0);
}

static void put_in_sizes(_str font_name)
{

   /*Handle Font Size List*/
   list := FONT_SIZE_LIST;
   _font_size_list._lbclear();
   old_size := _font_size_list.p_text;

   //special_case_terminal := (lowcase(font_name)=='terminal' && !__UNIX__);
   // Fonts for Minimap window are always scalable.
   if (_sample_text.p_user!='') {
      foreach (auto ls in MINIMAP_FONT_SIZE_LIST) {
         _font_size_list._lbadd_item(ls);
         _font_size_list.p_line = 1;
         _font_size_list._lbsort('-n');
      }
   } else if ( _isscalable_font(font_name, _font_name_list.p_user)) {
       foreach (auto ls in FONT_SIZE_LIST) {
          _font_size_list._lbadd_item(ls);
          _font_size_list.p_line = 1;
          _font_size_list._lbsort('-n');
       }
   }else{
       old_wid := p_window_id;
       p_window_id = _font_size_list;
       _insert_font_list(_font_name_list.p_user, font_name);
       _lbsort('-n');
       top();
       _lbdeselect_line();
       _lbremove_duplicates('n');
       p_window_id = old_wid;
   }

   old_wid := p_window_id;
   p_window_id=_font_size_list;
   if(_lbfind_and_select_item(old_size) < 0) {
      p_line = 1;
      if (fontHasLimitedSizes(font_name)) {
         p_text = _lbget_text();
      }
   }
   p_window_id = old_wid;
   /* Handle Font Size List*/
}
int _CharSetName2Id(_str name)
{
   if (name == get_message(VSRC_CHARSET_WESTERN))
      return(VSCHARSET_ANSI);
   if (name ==  get_message(VSRC_CHARSET_DEFAULT))
      return(VSCHARSET_DEFAULT);
   if (name ==  get_message(VSRC_CHARSET_SYMBOL))
      return(VSCHARSET_SYMBOL);
   if (name ==  get_message(VSRC_CHARSET_SHIFTJIS))
      return(VSCHARSET_SHIFTJIS);
   if (name ==  get_message(VSRC_CHARSET_HANGEUL))
      return(VSCHARSET_HANGEUL);
   if (name ==  get_message(VSRC_CHARSET_GB2312))
      return(VSCHARSET_GB2312);
   if (name ==  get_message(VSRC_CHARSET_CHINESEBIG5))
      return(VSCHARSET_CHINESEBIG5);
   if (name ==  get_message(VSRC_CHARSET_OEMDOS))
      return(VSCHARSET_OEM);
   if (name ==  get_message(VSRC_CHARSET_JOHAB))
      return(VSCHARSET_JOHAB);
   if (name ==  get_message(VSRC_CHARSET_HEBREW))
      return(VSCHARSET_HEBREW);
   if (name ==  get_message(VSRC_CHARSET_ARABIC))
      return(VSCHARSET_ARABIC);
   if (name ==  get_message(VSRC_CHARSET_GREEK))
      return(VSCHARSET_GREEK);
   if (name ==  get_message(VSRC_CHARSET_TURKISH))
      return(VSCHARSET_TURKISH);
   if (name ==  get_message(VSRC_CHARSET_THAI))
      return(VSCHARSET_THAI);
   if (name ==  get_message(VSRC_CHARSET_CENTRALEUROPEAN))
      return(VSCHARSET_EASTEUROPE);
   if (name ==  get_message(VSRC_CHARSET_CYRILLIC))
      return(VSCHARSET_RUSSIAN);
   if (name ==  get_message(VSRC_CHARSET_MAC))
      return(VSCHARSET_MAC);
   if (name ==  get_message(VSRC_CHARSET_BALTIC))
      return(VSCHARSET_BALTIC);
   if (name ==  get_message(VSRC_CHARSET_VIETNAMESE))
      return(VSCHARSET_VIETNAMESE);

   // otherwise return the default font
   return(VSCHARSET_DEFAULT);

}
_str _CharSet2Name(int charset)
{
   switch (charset) {
   case VSCHARSET_ANSI:
      return(get_message(VSRC_CHARSET_WESTERN));
   case VSCHARSET_DEFAULT:
      return(get_message(VSRC_CHARSET_DEFAULT));
   case VSCHARSET_SYMBOL:
      return(get_message(VSRC_CHARSET_SYMBOL));
   case VSCHARSET_SHIFTJIS:
      return(get_message(VSRC_CHARSET_SHIFTJIS));
   case VSCHARSET_HANGEUL:
      return(get_message(VSRC_CHARSET_HANGEUL));
   case VSCHARSET_GB2312:
      return(get_message(VSRC_CHARSET_GB2312));
   case VSCHARSET_CHINESEBIG5:
      return(get_message(VSRC_CHARSET_CHINESEBIG5));
   case VSCHARSET_OEM:
      return(get_message(VSRC_CHARSET_OEMDOS));
   case VSCHARSET_JOHAB:
      return(get_message(VSRC_CHARSET_JOHAB));
   case VSCHARSET_HEBREW:
      return(get_message(VSRC_CHARSET_HEBREW));
   case VSCHARSET_ARABIC:
      return(get_message(VSRC_CHARSET_ARABIC));
   case VSCHARSET_GREEK:
      return(get_message(VSRC_CHARSET_GREEK));
   case VSCHARSET_TURKISH:
      return(get_message(VSRC_CHARSET_TURKISH));
   case VSCHARSET_THAI:
      return(get_message(VSRC_CHARSET_THAI));
   case VSCHARSET_EASTEUROPE:
      return(get_message(VSRC_CHARSET_CENTRALEUROPEAN));
   case VSCHARSET_RUSSIAN:
      return(get_message(VSRC_CHARSET_CYRILLIC));
   case VSCHARSET_MAC:
      return(get_message(VSRC_CHARSET_MAC));
   case VSCHARSET_BALTIC:
      return(get_message(VSRC_CHARSET_BALTIC));
   case VSCHARSET_VIETNAMESE:
      return(get_message(VSRC_CHARSET_VIETNAMESE));
   default:
      return(charset);
   }
}
static _str _CharSet2SampleText(int charset)
{
   if (_UTF8()) {
      switch (charset) {
      case VSCHARSET_SHIFTJIS:
         return("\x{0041}\x{0061}\x{3042}\x{3041}\x{30a2}\x{30a1}\x{4e9c}\x{5b87}");
      case VSCHARSET_GREEK:
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{0041}\x{03b1}\x{0042}\x{03b2}");
      case VSCHARSET_TURKISH:
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{011e}\x{011f}\x{015e}\x{015f}");
      case VSCHARSET_EASTEUROPE:
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{00c1}\x{00e1}\x{00d4}\x{00f4}");
      case VSCHARSET_RUSSIAN:  // Cyrillic
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{0411}\x{0431}\x{0424}\x{0444}");
      case VSCHARSET_SYMBOL:
         return("Symbol");
      case VSCHARSET_ARABIC:
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{0639}\x{0645}\x{0646}\x{062e}\x{0631}\x{0648}\x{0643}\x{0645}");
      case VSCHARSET_HEBREW:
         return("\x{0041}\x{0061}\x{0042}\x{0062}\x{05e0}\x{05e1}\x{05e9}\x{05ea}");
      case VSCHARSET_HANGEUL:
      case VSCHARSET_GB2312:
      case VSCHARSET_CHINESEBIG5:
      case VSCHARSET_OEM:
      case VSCHARSET_JOHAB:
      case VSCHARSET_THAI:

      case VSCHARSET_MAC:    // Uses default
      case VSCHARSET_BALTIC: // Uses default
      case VSCHARSET_ANSI:   // Western. Uses default
      case VSCHARSET_DEFAULT:
      }
      return("-> Line before <-\nAa_Bb_Cc = (l1 + O0);\n-> Line after <-");
   }
   switch (charset) {
   case VSCHARSET_SHIFTJIS:
      return("Aa"\130\160\130\159\131"A"\131"@"\136\159\137"F");
   case VSCHARSET_GREEK:
      return("AaBbA"\225"B"\226);
   case VSCHARSET_TURKISH:
      return("AaBb"\208\240\222\254);
   case VSCHARSET_EASTEUROPE:
      return("AaBb"\193\225\212\244);
   case VSCHARSET_RUSSIAN:  // Cyrillic
      return("AaBb"\193\225\212\244);
   case VSCHARSET_SYMBOL:
      return("Symbol");
   case VSCHARSET_ARABIC:
      return("AaBb"\218\227\228\206\209\230\223\227);
   case VSCHARSET_HEBREW:
      return("AaBb"\240\241\249\250);
   case VSCHARSET_HANGEUL:
   case VSCHARSET_GB2312:
   case VSCHARSET_CHINESEBIG5:
   case VSCHARSET_OEM:
   case VSCHARSET_JOHAB:
   case VSCHARSET_THAI:

   case VSCHARSET_MAC:    // Uses default
   case VSCHARSET_BALTIC: // Uses default
   case VSCHARSET_ANSI:   // Western. Uses default
   case VSCHARSET_DEFAULT:
   }
   return("-> Line before <-\nAa_Bb_Cc = (l1 + O0);\n-> Line after <-");
}
static void put_in_charsets(_str font_name)
{
   // Qt fonts have no character set
   return;
}


_ok.on_create(_str show_font_options="",_str _font_string="")
{
   createFontForm(show_font_options, _font_string);
}

void createFontForm(_str show_font_options="",_str _font_string="")
{
   //messageNwait("_font_name_list.on_create: h1");
   font_name := "";
   typeless size=0;
   typeless font_flags=0;
   typeless charset=0;

   //changing_name_list =  changing_size_list = 0;
   if(_font_string != ''){
      parse _font_string with font_name ',' size ',' font_flags ',' charset ',' .;
   }else{
      font_name = '';
      size = 10;
      font_flags = 0;
      charset=VSCHARSET_DEFAULT;
   }
   if (charset=="") {
      charset=VSCHARSET_DEFAULT;
   }
   if(size == ''){
      size = 10;
   }
   if (font_flags == '') {
      font_flags = 0;
   }
   if (pos('d',show_font_options,1,'i')) {
      ctlfixedfonts.p_enabled=false;
      _str before,after;
      parse show_font_options with before 'i' after;
      show_font_options=before:+after;
   }
   if (pos('f',show_font_options,1,'i') ) {
      ctlfixedfonts.p_value=1;
   }

   _font_name_list.p_user=show_font_options;

   FONT_CHANGING_NAME_LIST(0);
   FONT_CHANGING_SIZE_LIST(0);
   //CHANGING_SCRIPT_LIST=0;


   if (pos('p',_font_name_list.p_user,1,'i')) {
      _sample_text.p_font_printer=true;
   } else {
      _sample_text.p_font_printer=false;
   }

   //_param1 is the font name with no quotes    - Defaults to courier
   //size is the font size                      - Defaults to 10
   //font_flags is truth(bold)                  - Defaults to 0 (no)

   FillInFontNameList(font_name,false);


   _font_name_list.prepare_cb_and_list(font_name,false);
   put_in_sizes(font_name);
   _font_size_list.prepare_cb_and_list(size,true);
   put_in_charsets(font_name);

   int isbold = font_flags & F_BOLD;
   int isitalic = font_flags & F_ITALIC;
   int isstrikethrough = font_flags & F_STRIKE_THRU;
   int isunderline = font_flags & F_UNDERLINE;

   _bold.p_value = isbold;
   _italic.p_value = isitalic;
   _underline.p_value = isunderline;
   _strikethrough.p_value = isstrikethrough;

   if (isbold) _sample_text.p_font_bold=true;
   if (isitalic) _sample_text.p_font_italic=true;
   if (isunderline) _sample_text.p_font_underline=true;
   if(isstrikethrough) _sample_text.p_font_strike_thru = true;

   //Change font name so that frame matches _font_name_list.p_text
   _sample_text.p_font_name = _font_name_list.get_font_name_from_list(true);
   _sample_text.p_font_size = size;
   _sample_text.p_font_charset=charset;
   if (charset==VSCHARSET_DEFAULT) {
      charset=_GetFontCharSet(_sample_text.p_font_name,_sample_text.p_font_size,_font_name_list.p_user);
   }
   _sample_text.p_caption=_CharSet2SampleText(charset);
   //ctlScript.p_text=_CharSet2Name(_sample_text.p_font_charset);
   FONT_CHANGING_NAME_LIST(1);
   FONT_CHANGING_SIZE_LIST(1);//Allow events to combo boxes
   //CHANGING_SCRIPT_LIST=1;
   //changing_name_list = changing_size_list = 1;//Allow events to combo boxes
   /* messageNwait('_font_name_list.p_cb_list_box.p='_font_name_list.p_cb_list_box.p_pic_point_scale) */
   _macro('m',_macro('s'));

   if (ctlfixedfonts.p_value==1 &&
       _font_name_list.p_text!="" &&
       _font_name_list.p_text!=_font_name_list._lbget_text()) {
      ctlfixedfonts.p_value=0;
      ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);
   }
}

static void FillInFontNameList(_str &font_name,bool addBlankFontName)
{
   //say('FillInFontNameList: font_name='font_name);
   _font_name_list.p_redraw=false;
   _font_name_list.p_picture=0;
   first_time := !_font_name_list.p_Noflines;
   _font_name_list._lbclear();
   /*Handle Font Name List*/
   p_window_id=_font_name_list;
   _font_name_list._insert_font_list(_font_name_list.p_user); //Put names of fonts in list box

   //messageNwait("FillInFontNameList: _font_name_list="_font_name_list" _font_name_list.p_user="_font_name_list.p_user" N="_font_name_list.p_cb_list_box.p_Noflines);
   //messageNwait('_font_name_list.p_user='_font_name_list.p_user);
   // For Xft we need to sort fonts case insensitive.
   if (font_name == '' && !addBlankFontName) {
      _font_name_list._lbsort('i');
      _font_name_list.p_line = 1;
      font_name = _font_name_list.get_font_name_from_list();
      _font_name_list.p_text = font_name;
   } else {
      //Sort the list box
      _font_name_list._lbsort('i');
   }
   _font_name_list._lbremove_duplicates('i');
   old_line := _font_name_list.p_line;
   orig_wid := p_window_id;
   p_window_id=_font_name_list;

   // 7/20/2011 - rb
   // p_picture is really just a boolean that tells the combobox to insert
   // lines with pictures. It is required to be set before massaging the
   // list with pictures or else the first item will not have a picture.
   // In time we may refactor this code and deprecate this particular use
   // of p_picture.
   if (_isWindows()) {
      p_picture = _pic_tt;
   }

   top();up();
   if (addBlankFontName) {
      picture := 0;
      _lbadd_item('');
   }
   for (;;) {
      if(down()) break;
      _str name = _lbget_text();
      if (_isUnix()) {
         picture := 0;
         _lbset_item(name);
      } else {
         picture := 0;
         int ft=_font_type(name,_font_name_list.p_user);
         if (ft & TRUETYPE_FONTTYPE) {
            picture = _pic_tt;
         }else if(ft & DEVICE_FONTTYPE){
            picture = _pic_printer;
         } else {
            picture=0;
         }
         _lbset_item(name, 60, picture);
      }
   }
   p_after_pic_indent_x=80;
   p_line = old_line;
   //messageNwait('h1 p_auto_size='_font_name_list.p_auto_size);
   //_font_name_list.p_auto_size=0;
   if (_isUnix()) {
      p_picture = 0;
   } else {
      p_picture = _pic_tt;
   }
   _font_name_list.p_redraw=true;
   p_window_id=orig_wid;
   /*End Handle Font Name List*/
   if (first_time) {
      _font_name_list.p_auto_size=true;
   }

   // special case for Courier - many computers
   // do not include Courier as a print font anymore
   // and so we switch it to Courier New to avoid
   // getting an invalid font error
   // 1-1R5GL
   // 5.23.07
   // sg
   _font_name_list.p_line = 1;
   if (strieq(font_name, "Courier")) {
      if(_font_name_list._lbfind_item(font_name) < 0) {
         font_name = "Courier New";
      }
   }

   /*_font_name_list.p_line = 1;
   say('font_name='font_name' addblank='addBlankFontName);
   if(_font_name_list._lbfind_item(font_name) < 0) {
      say('NOT FOUND');
   }
   _font_name_list.p_line = 1;*/
   // Select the font name in the combo box text box in
   // the list box.
   _font_name_list.prepare_cb_and_list(font_name,false);
}

void _font_name_list.on_change(int reason)
{
   if (FONT_CHANGING_NAME_LIST()) {
      font_name := get_font_name_from_list();
      lbtext := get_font_name_from_list(true);
      // Times New Roman (HTML Proportional setting) doesn't exist in font list.
      // Want to keep users setting for a font name that doesn't exist
      /*if (lowcase(font_name)!=lowcase(lbtext)) {
         return;
      } */
      _lbselect_line();
      if (font_name=='') {
         font_name=_sample_text.p_user;
      }
      /*if (font_name!='' && _sample_text.p_user!='') {
         typeless temp_font_size=10;
         _xlat_font(font_name,temp_font_size);
      } */
      _sample_text.p_font_name = font_name;
      _sample_text.p_font_bold = _bold.p_value!=0;
      _sample_text.p_font_italic = _italic.p_value!=0;
      _sample_text.p_font_underline = _underline.p_value!=0;
      _sample_text.p_font_strike_thru = _strikethrough.p_value!=0;
      put_in_sizes(font_name);
      put_in_charsets(font_name);
      if (isinteger(_font_size_list.p_text)) {
         _sample_text.p_font_size = _font_size_list.p_text;
      }
      int charset=_sample_text.p_font_charset;
      if (charset!=_sample_text.p_font_charset) {
         _sample_text.p_font_charset=charset;
      }
      _sample_text.p_caption=_CharSet2SampleText(charset);
      linenum := _font_size_list.p_line;
      _font_size_list.top();
      _font_size_list.p_line=linenum;
   }
}

bigint _font_size_valid(_str font_size)
{
   if (isinteger(font_size)) return(1);
   typeless width,height;
   parse font_size with width 'x','i' height;
   if (!isinteger(width) || !isinteger(height)) {
      return(0);
   }
   return(1);
}
_font_size_list.on_lost_focus()
{
   if (_font_size_valid(p_text)) {
      _sample_text.p_font_size = p_text;
      /*
         For now, assume this character set is available in this size

         if (_GetFontCharSet(_sample_text.p_font_name,_sample_text.p_font_size,_font_name_list.p_user)==VSCHARSET_SHIFTJIS) {
            _sample_text.p_caption=JAPANESE_SAMPLE_TEXT;
         } else {
            _sample_text.p_caption="AaBbYyZz";
         }
      */
   } else {
      _beep();
   }
}

_font_size_list.on_change(int reason)
{
   if (!FONT_CHANGING_SIZE_LIST()) {
      return('');
   }

   lbtext := _lbget_text();
   if (lbtext:!=p_text){
      font_name := _font_name_list.get_font_name_from_list();
      if(_sample_text.p_user!='' || _isscalable_font(font_name,_font_name_list.p_user)) {
         if (isinteger(p_text)) {
            _sample_text.p_font_size=p_text;
            /*if (_GetFontCharSet(_sample_text.p_font_name,_sample_text.p_font_size,_font_name_list.p_user)==VSCHARSET_SHIFTJIS) {
               _sample_text.p_caption=JAPANESE_SAMPLE_TEXT;
            } else {
               _sample_text.p_caption="AaBbYyZz";
            } */
         }
      }
      return('');
   }
   _lbselect_line();
   new_size := _lbget_text();
   _sample_text.p_font_size = new_size;
   /*if (_GetFontCharSet(_sample_text.p_font_name,_sample_text.p_font_size,_font_name_list.p_user)==VSCHARSET_SHIFTJIS) {
      _sample_text.p_caption=JAPANESE_SAMPLE_TEXT;
   } else {
      _sample_text.p_caption="AaBbYyZz";
   } */
}


_italic.lbutton_up()
{
     _sample_text.p_font_italic = p_value!=0;
}

_underline.lbutton_up()
{
    _sample_text.p_font_underline = p_value!=0;
}

_bold.lbutton_up()
{
   _sample_text.p_font_bold = p_value!=0;
}

_strikethrough.lbutton_up()
{
    _sample_text.p_font_strike_thru = p_value!=0;
}


_ok.lbutton_up()
{
   typeless result = _font_get_result();
   if (result=='') {
      return('');
   }
   _macro('m',_macro('s'));
   p_active_form._delete_window(result);
}

_str _font_get_result(bool quiet=false)
{
   flags := 0;
   font_name := _font_name_list.get_font_name_from_list();
   //say('_font_get_result: font_name='font_name);
   font_size := _font_size_list.p_text;
   if (!isinteger(font_size)) {
      typeless width,height;
      parse font_size with width 'x','i' height;
      if (!isinteger(width) || !isinteger(height)) {
         p_window_id=_font_size_list;
         if (!quiet) _message_box(get_message(VSRC_FC_INVALID_FONT_SIZE));
         _set_sel(1,length(p_text)+1);_set_focus();
         return('');
      }
      if (lowcase(font_name)!='terminal') {
         p_window_id=_font_size_list;
         if (!quiet) _message_box(get_message(VSRC_FC_TERMINAL_FONT_SIZE));
         _set_sel(1,length(p_text)+1);_set_focus();
         return('');
      }
   } else if (font_size > 400) {
      p_window_id=_font_size_list;
      if (!quiet) _message_box(get_message(VSRC_FC_INVALID_FONT_SIZE));
      _set_sel(1,length(p_text)+1);_set_focus();
      return('');
   }
   if (_font_name_list._lbfind_item(font_name) < 0) {
      if (!_font_name_list._lbsearch(font_name)) {
         _font_name_list._lbselect_line();
      } else {
         // Allow user to choose a font that doesn't exist.
         //p_window_id=_font_name_list;
         //if (!quiet) _message_box(get_message(VSRC_FC_INVALID_FONT_NAME));
         //_set_sel(1,length(p_text)+1);_set_focus();
         //return('');
      }
   }
   if (_sample_text.p_font_bold == 1) {
      flags |= 0x01;
   }
   if (_sample_text.p_font_italic == 1) {
      flags |= 0x02;
   }
   if (_sample_text.p_font_strike_thru == 1) {
      flags |= 0x04;
   }
   if (_sample_text.p_font_underline == 1) {
      flags |= 0x08;
   }
   //say('font_name='font_name' '_sample_text.p_font_name);
   //IF the font name is optional, use '' for the font
   if (font_name=='' && ctlfixedfonts.p_user!='') {
      return(font_name','_font_size_list.p_text','flags','_sample_text.p_font_charset',');
   }
   return(_sample_text.p_font_name','_font_size_list.p_text','flags','_sample_text.p_font_charset',');
}

