////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47307 $
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
#import "clipbd.e"
#import "font.e"
#import "main.e"
#import "recmacro.e"
#import "sellist.e"
#import "stdprocs.e"
#endregion

_control _okay
_control _just_window
_control _sample_text
_control _font_name_list

defeventtab _wfont_form;
/**
 * Displays <b>Font dialog box</b> which allows you to change the font 
 * for the current MDI edit window or all MDI edit windows.
 * 
 * @param options is a string of zero or more of the following option 
 * letters:
 * 
 * <dl>
 * <dt>F</dt><dd>Display fixed pitch fonts only.</dd>
 * <dt>S</dt><dd>(Default) Display screen fonts.</dd>
 * <dt>P</dt><dd>Display printer fonts.</dd>
 * </dl>
 * 
 * <p>Printer and screen fonts can not be displayed at the same time.</p>
 *    
 * @param font specifies the font that should be used to initialize the 
 * dialog box.  It is a string in the format:<br>  
 * 
 * <i>font_name,font_size, font_flags</i>
 * 
 * @param font_size is the point size of the font.  <i>font_flags</i> is 
 * zero or constants ORed together.  The font flag constants are defined 
 * in "slick.sh" and have the prefix "F_" (ex. F_BOLD).
 * 
 * @example void show('_wfont_form', <i>options</i> , <i>font</i>)
 * 
 * @see _choose_font
 * @see wfont
 * 
 * @categories Forms
 * 
 */ 
void _okay.on_create()
{
}

static void generate_change_all_macro(_str font_name,_str font_size,int font_flags,int charset=VSCHARSET_DEFAULT,int cfg=CFG_SBCS_DBCS_SOURCE_WINDOW)
{
   _macro('m',_macro('s'));
   _macro_call("_change_all_wfonts",font_name,font_size,font_flags,charset,cfg);
}

static void generate_change_current_macro(_str font_name, _str font_size, int font_flags,int charset=VSCHARSET_DEFAULT)
{
   charset=arg(4);
   int fs = font_flags & F_STRIKE_THRU;
   int fu = font_flags & F_UNDERLINE;
   int fi = font_flags & F_ITALIC;
   int fb = font_flags & F_BOLD;
   _macro('m',_macro('s'));
   _macro_append("p_font_name       ="_quote(font_name)";");
   _macro_append("p_font_size       ="font_size";");
   _macro_append("p_font_bold       ="fb";");
   _macro_append("p_font_italic     ="fi";");
   _macro_append("p_font_underline  ="fu";");
   _macro_append("p_font_strike_thru="fs";");
   _macro_append("p_font_charset="charset";");
}

/**
 * Changes the font of all MDI edit windows.  <i>font_size</i> is a point size.
 * <i>font_flags</i> is a combination of the following flag constants defined in "slick.sh":
 * <pre>
 * F_BOLD
 * F_ITALIC
 * F_STRIKE_THRU
 * F_UNDERLINE
 * </pre>
 * 
 * @param font_name
 * @param font_size
 * @param font_flags
 * @param charset
 * @param cfg
 * 
 * @categories Window_Functions
 */
void _change_all_wfonts(_str font_name, _str font_size, int font_flags,int charset=VSCHARSET_DEFAULT,int cfg=CFG_SBCS_DBCS_SOURCE_WINDOW)
{
   if (!isinteger(charset)) {
      charset=VSCHARSET_DEFAULT;
   }

   int last=_last_window_id();
   int i;
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(false)){
         typeless thiscfg=CFG_SBCS_DBCS_SOURCE_WINDOW;
         if (i._isEditorCtl(false)) {
            if (i.p_hex_mode) {
               thiscfg=CFG_HEX_SOURCE_WINDOW;
            } else if (i.p_LangId=='fileman') {
               thiscfg=CFG_FILE_MANAGER_WINDOW;
            } else if (i.p_UTF8) {
               thiscfg=CFG_UNICODE_SOURCE_WINDOW;
            }
         }
         if (thiscfg==cfg) {
            i.p_redraw=0;
            i.p_font_name      = font_name;
            i.p_font_size      = font_size;
            i.p_font_bold      = (font_flags & F_BOLD)!=0;
            i.p_font_italic    = (font_flags & F_ITALIC)!=0;
            i.p_font_underline = (font_flags & F_UNDERLINE)!=0;
            i.p_font_strike_thru = (font_flags & F_STRIKE_THRU)!=0;
            i.p_font_charset=charset;
            i.p_redraw=1;
         }
      }
   }
   _str new_default = font_name','font_size','font_flags','charset;
   _default_font(cfg, new_default);
   _config_modify_flags(CFGMODIFY_OPTION);
}


_okay.lbutton_up()
{
   update_sample_text();
   _str font_info = _font_get_result();
   if (font_info == '') {
      return('');
   }

   _str font_name='';
   typeless font_size=0;
   typeless font_flags=0;
   typeless charset='';
   parse font_info with font_name ',' font_size ',' font_flags ','charset ',' ;
   if (!isinteger(charset)) {
      charset=VSCHARSET_DEFAULT;
   }

   int wid=_form_parent(); //_mdi.p_child;
   if (_just_window.p_value) {
      p_active_form._delete_window(1);
      wid.p_redraw=0;
      wid.p_font_name        = font_name;
      wid.p_font_size        = font_size;
      wid.p_font_bold        = font_flags & F_BOLD;
      wid.p_font_italic      = font_flags & F_ITALIC;
      wid.p_font_underline   = font_flags & F_UNDERLINE;
      wid.p_font_strike_thru = font_flags & F_STRIKE_THRU;
      wid.p_font_charset=charset;
      wid.p_redraw=1;
      generate_change_current_macro(font_name, font_size, font_flags,charset);
   }else{
      p_active_form._delete_window(1);
      typeless cfg=CFG_SBCS_DBCS_SOURCE_WINDOW;
      if (wid && wid._isEditorCtl(false)) {
         if (wid.p_hex_mode) {
            cfg=CFG_HEX_SOURCE_WINDOW;
         } else if (wid.p_LangId=='fileman') {
            cfg=CFG_FILE_MANAGER_WINDOW;
         } else if (wid.p_UTF8) {
            cfg=CFG_UNICODE_SOURCE_WINDOW;
         }
      }
      _change_all_wfonts(font_name, font_size, font_flags,charset,cfg);
      generate_change_all_macro(font_name, font_size, font_flags,charset,cfg);
   }
}

/**
 * Displays <b>Window Font dialog box</b> which allows you to 
 * change the font for the current MDI edit window or all MDI edit 
 * windows.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void wfont() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   typeless param2 = _font_props2flags();
   show('-modal _wfont_form',
        'f',
        _font_param(p_font_name,p_font_size,param2,p_font_charset)
       );

}

/**
 * Modify the font size for the current editor window.
 * 
 * @param size  font size change amount<ul>
 *    <li><b> +n </b> -- increase font size by 'n' pixels
 *    <li><b> -n </b> -- decrease font size by 'n' pixels
 *    <li><b> n </b> -- set font size to 'n'
 *    </ul>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void wfont_zoom(_str size="+1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   if (!isnumber(size)) {
      _message_box("Font size must be an integer");
      return;
   }
   int new_size = (int) p_font_size;
   if (substr(size,1,1)=='-' || substr(size,1,1)=='+') {
      new_size = (int)p_font_size + (int)size;
   } else {
      new_size = (int) size;
   }
   if (new_size <= 0 || new_size > 128) {
      _message_box("Font size is out of range");
      return;
   }
   if (p_font_size != new_size) {
      p_font_size = new_size;
   }
}
/**
 * Increase the font size for the current editor window.
 * 
 * @param size   (default=1) amount to increment font size
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @see wfont_zoom
 */
_command void wfont_zoom_in(_str size="1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   wfont_zoom("+":+size);
}
/**
 * Decrease the font size for the current editor window.
 * 
 * @param size   (default=1) amount to decrement font size
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @see wfont_zoom
 */
_command void wfont_zoom_out(_str size="1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   wfont_zoom("-":+size);
}

#if 0
_command reset_wfonts()
{
   last=_last_window_id();
   for (i=1;i<=last;++i) {
      if ((_iswindow_valid(i)) && (i.p_mdi_child) && (i.p_HasBuffer < 0)){
         i.p_font_name        = 'Courier'
         i.p_font_size        = 10;
         i.p_font_bold        = 0;
         i.p_font_italic      = 0;
         i.p_font_underline   = 0;
         i.p_font_strike_thru = 0;
      }
   }
}
#endif
