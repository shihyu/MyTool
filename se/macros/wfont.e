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
#import "stdcmds.e"
#import "stdprocs.e"
#import "fontcfg.e"
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
 */ 
void _okay.on_create(_str show_font_options="",_str _font_string="")
{
   createFontForm(show_font_options, _font_string);
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
   bool update_minimap_font=false;
   bool update_editor_font=false;
   int minimap_cfg= MAXINT;
   update_minimap_font= cfg==CFG_SBCS_DBCS_MINIMAP_WINDOW || cfg==CFG_UNICODE_MINIMAP_WINDOW;
   update_editor_font= !update_minimap_font;
   _str minimap_font_name='';
   _str minimap_font_size=0;
   int minimap_font_flags=0;
   if (cfg==CFG_SBCS_DBCS_SOURCE_WINDOW) {
      minimap_cfg=CFG_SBCS_DBCS_MINIMAP_WINDOW;
      update_minimap_font=true;
      parse _default_font(CFG_SBCS_DBCS_MINIMAP_WINDOW) with minimap_font_name','minimap_font_size',';//font_flags','charset',';
   } else if (cfg==CFG_UNICODE_SOURCE_WINDOW) {
      minimap_cfg=CFG_UNICODE_MINIMAP_WINDOW;
      update_minimap_font=true;
      parse _default_font(CFG_UNICODE_MINIMAP_WINDOW) with minimap_font_name','minimap_font_size',';//font_flags','charset',';
   }

   int last=_last_window_id();
   int i;
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(false)){
         int thiscfg=MAXINT;
         if (update_minimap_font && i.p_IsMinimap) {
            if (i._isEditorCtl(false)) {
               if (i.p_hex_mode) {
               //} else if (i.p_LangId=='fileman') {
               } else if (i.p_UTF8) {
                  thiscfg=CFG_UNICODE_MINIMAP_WINDOW;
               } else {
                  thiscfg=CFG_SBCS_DBCS_MINIMAP_WINDOW;
               }
            }
         }
         if (update_editor_font && !i.p_IsMinimap) {
            thiscfg=CFG_SBCS_DBCS_SOURCE_WINDOW;
            if (i._isEditorCtl(false)) {
               if (i.p_hex_mode) {
                  thiscfg=CFG_HEX_SOURCE_WINDOW;
               } else if (i.p_LangId=='fileman') {
                  thiscfg=CFG_FILE_MANAGER_WINDOW;
               } else if (i.p_UTF8) {
                  thiscfg=CFG_UNICODE_SOURCE_WINDOW;
               }
            }
         }
         if (thiscfg==cfg) {
            i.p_redraw=false;
            i.p_font_name      = font_name;
            i.p_font_size      = font_size;
            i.p_font_bold      = (font_flags & F_BOLD)!=0;
            i.p_font_italic    = (font_flags & F_ITALIC)!=0;
            i.p_font_underline = (font_flags & F_UNDERLINE)!=0;
            i.p_font_strike_thru = (font_flags & F_STRIKE_THRU)!=0;
            i.p_font_charset=charset;
            i.p_redraw=true;
         }
         if (thiscfg==minimap_cfg && minimap_cfg!=MAXINT) {
            i.p_redraw=false;
            i.p_font_name      = minimap_font_name;
            i.p_font_size      = minimap_font_size;
            /*i.p_font_bold      = (font_flags & F_BOLD)!=0;
            i.p_font_italic    = (font_flags & F_ITALIC)!=0;
            i.p_font_underline = (font_flags & F_UNDERLINE)!=0;
            i.p_font_strike_thru = (font_flags & F_STRIKE_THRU)!=0;
            i.p_font_charset=charset;*/
            i.p_redraw=true;
         }
      }
   }
   new_default :=  font_name','font_size','font_flags','charset;
   _default_font(cfg, new_default);
   _set_font_profile_property(cfg,font_name,font_size,font_flags,charset);
}


_okay.lbutton_up()
{
   update_sample_text();
   _str font_info = _font_get_result();
   if (font_info == '') {
      return('');
   }

   font_name := "";
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
      wid.p_redraw=false;
      wid.p_font_name        = font_name;
      wid.p_font_size        = font_size;
      wid.p_font_bold        = font_flags & F_BOLD;
      wid.p_font_italic      = font_flags & F_ITALIC;
      wid.p_font_underline   = font_flags & F_UNDERLINE;
      wid.p_font_strike_thru = font_flags & F_STRIKE_THRU;
      wid.p_font_charset=charset;
      wid.p_redraw=true;
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
 * @categories Forms, Edit_Window_Methods, Editor_Control_Methods
 */ 
_command void wfont() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   typeless param2 = _font_props2flags();
   show('-modal _wfont_form',
        'f',
        _font_param(p_font_name,p_font_size,param2,p_font_charset)
       );

}

static int _OnUpdate_wfont_zoom_in_or_out(CMDUI cmdui,int target_wid,_str command,int plusminus_one)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   int font_size=(int)target_wid.p_font_size;
   if (plusminus_one>0) {
      font_size+=1;
   } else {
      font_size-=1;
   }
   if ( font_size<=0 || font_size>128 )  {
      return(MF_GRAYED);
   }

   return(MF_ENABLED);
}
int _OnUpdate_wfont_zoom_in(CMDUI cmdui,int target_wid,_str command) {
   return _OnUpdate_wfont_zoom_in_or_out(cmdui,target_wid,command,1);
}
int _OnUpdate_wfont_zoom_out(CMDUI cmdui,int target_wid,_str command) {
   return _OnUpdate_wfont_zoom_in_or_out(cmdui,target_wid,command,-1);
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
 *  
 * @see wfont_zoom_in 
 * @see wfont_zoom_out 
 * @see wfont_unzoom
 */
_command void wfont_zoom(_str size="+1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   static bool last_attempt_failed;
   if (!isnumber(size)) {
      if (!last_attempt_failed) {
         _message_box("Font size must be an integer");
      }
      last_attempt_failed=true;
      return;
   }
   
   _str font_name=p_font_name;
   int font_size= (int)p_font_size*10;
   _xlat_font(font_name,font_size);
   //if (font_name!=p_font_name) {
   font_size=font_size intdiv 10;
   //}
   int new_size = font_size;
   if (substr(size,1,1)=='-' || substr(size,1,1)=='+') {
      new_size = font_size + (int)size;
   } else {
      new_size = (int) size;
   }
   if (new_size <= 0 || new_size > 128) {
      /*
      A user complained about this message.
      if (!last_attempt_failed) {
         _message_box("Font size is out of range");
      } */
      last_attempt_failed=true;
      return;
   }
   last_attempt_failed=false;
   if (font_size != new_size) {
      p_font_name=font_name;
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
 * @see wfont_unzoom
 * @see wfont_zoom_out
 */
_command void wfont_zoom_in(_str size="1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL|VSARG2_MARK)
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
 * @see wfont_unzoom
 * @see wfont_zoom_in
 */
_command void wfont_zoom_out(_str size="1") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL|VSARG2_MARK)
{
   wfont_zoom("-":+size);
}

static int _get_unzoom_font_size() {
   cfg_font := _isdiff_editor_window(p_window_id)?
                  (p_UTF8? CFG_UNICODE_DIFF_EDITOR_WINDOW : CFG_DIFF_EDITOR_WINDOW) :
                  (p_UTF8? CFG_UNICODE_SOURCE_WINDOW : CFG_SBCS_DBCS_SOURCE_WINDOW);
   if (p_IsMinimap) {
      cfg_font=(p_UTF8? CFG_UNICODE_MINIMAP_WINDOW : CFG_SBCS_DBCS_MINIMAP_WINDOW);
   }
   font_info := _default_font(cfg_font);
   parse font_info with . ',' auto font_size ',' .;
   if (isinteger(font_size)) {
      return (int)font_size;
   }
   return 10;
}
int _OnUpdate_wfont_unzoom(CMDUI cmdui,int target_wid,_str command) {
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   int font_size=(int)target_wid.p_font_size;
   unzoom_font_size:=target_wid._get_unzoom_font_size();
   if (font_size==unzoom_font_size) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Reset the font size to the default font size for this editor window.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @see wfont_zoom
 * @see wfont_zoom_in
 * @see wfont_zoom_out
 */
_command void wfont_unzoom() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   font_size:=_get_unzoom_font_size();
   wfont_zoom(font_size);
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
