////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49944 $
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
#include "diff.sh"
#import "files.e"
#import "font.e"
#import "listbox.e"
#import "main.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "wfont.e"
#require "se/options/DialogExporter.e"
#endregion

struct FONTCFGINFO {
   _str name;
   _str value;
};
static FONTCFGINFO glist[]={
   {"Command Line",CFG_CMDLINE},
   {"Status Line",CFG_STATUS},
   {"SBCS/DBCS Source Windows",CFG_SBCS_DBCS_SOURCE_WINDOW},
   {"Hex Source Windows",CFG_HEX_SOURCE_WINDOW},
   {"Unicode Source Windows",CFG_UNICODE_SOURCE_WINDOW},
   {"File Manager Windows",CFG_FILE_MANAGER_WINDOW},
   {"Diff Editor Source Windows",CFG_DIFF_EDITOR_WINDOW},
   {"Parameter Info",CFG_FUNCTION_HELP},
   {"Parameter Info Fixed",CFG_FUNCTION_HELP_FIXED},
   {"Selection List","sellist"},
#if 1 /* __UNIX__ */
   {"Menu",CFG_MENU},
#endif
   {"Dialog",CFG_DIALOG},
   {"HTML Proportional",CFG_MINIHTML_PROPORTIONAL},
   {"HTML Fixed",CFG_MINIHTML_FIXED},
   {"Document Tabs",CFG_DOCUMENT_TABS},
#if 0 /* __UNIX__ */
   {"MDI Child Icon",CFG_MDICHILDICON},
   {"MDI Child Title",CFG_MDICHILDTITLE},
#endif
};

#define CHANGING_ELEMENT_LIST _ctl_element_list.p_user

// These are also defined in font.e
//#define CHANGING_SCRIPT_LIST  ctlScript.p_cb_list_box.p_user
#define CHANGING_NAME_LIST    _sample_frame.p_user
#define CHANGING_SIZE_LIST    _font_size_list.p_user

typedef struct {
   _str id;   // This is a string because of 'sellist'
   _str info;
} settings_t;

static settings_t _settings:[];
static settings_t _orig_settings:[];

/**
 * Retrieves a hash table filled with all the font names 
 * availabe on this machine.  The key and value are both the 
 * font name.  However, the key is lowercase, while the value 
 * uses the casing that is used in the actual font name. 
 * 
 * @param table 
 */
static void getTableOfFonts(_str (&table):[])
{
   // open up a temp view so we can put the font names in there
   tempView := 0;
   origView := _create_temp_view(tempView);

   // put the font names into the temp view
   _insert_font_list('');

   // read the fonts
   line := '';
   top();
   while (true) {
      // add the next one to our list
      get_line(line);
      line = strip(line);
      if (line != '') {
         table:[lowcase(line)] = line;
      }

      // next, please
      if (down()) break;
   }

   // get rid of the temp view
   p_window_id = origView;
   _delete_temp_view(tempView);
}

_control _font_name_list;
_control _font_size_list;

defeventtab _font_config_form;

void _font_config_form.on_resize()
{
   // do not let this function call itself recursively
   static boolean in_resize;
   if (in_resize) return;
   in_resize = true;

   // total size
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   padding := _sample_frame.p_x;
   embeddedInOptions := !_ctl_ok.p_visible;     // this changes a few things...

   // verify that the adjustments meet minimum guidelines - we don't worry about this 
   // when we are embedded in the options because that dialog takes care of it for us
   if (!embeddedInOptions && !_minimum_width()) {
      // have we set the min size yet?  if not, min width will be 0
      min_width := ctlEnableBoldAndItalic.p_width+2*padding;
      min_height := (padding+_style_frame.p_height) + (_sample_frame.p_y+_sample_frame.p_height - ctlfixedfonts.p_y);
      _set_minimum_size(min_width, min_height);
   }

   // calculate the horizontal and vertical adjustments
   adjust_x := (width - _sample_frame.p_width - 2 * padding);
   adjust_y := 0;
   if (embeddedInOptions) {
      adjust_y = (height - _sample_frame.p_height - _sample_frame.p_y - padding);
   } else {
      adjust_y = (height - _ctl_ok.p_height - _ctl_ok.p_y - padding);
   }

   // adjust along horizontal dimensions
   _ctl_element_list.p_width += adjust_x;
   _font_name_list.p_width += adjust_x;
   _font_size_list.p_x += adjust_x;
   _size_label.p_x += adjust_x;
   _style_frame.p_x += adjust_x;
   //ctlScriptLabel.p_x += adjust_x;
   //ctlScript.p_x += adjust_x;
   _sample_frame.p_width += adjust_x;
   picture1.p_width += adjust_x;
   _sample_text.p_width += adjust_x;

   // adjust along vertical dimensions
   _font_size_list.p_height += adjust_y;
   _font_name_list.p_height = _font_size_list.p_height;
   //ctlScriptLabel.p_y += adjust_y;
   //ctlScript.p_y += adjust_y;
   ctlfixedfonts.p_y += adjust_y;
   ctlEnableBoldAndItalic.p_y += adjust_y;
   ctlAntiAliasing.p_y += adjust_y;
   _sample_frame.p_y += adjust_y;
   _ctl_ok.p_y += adjust_y;
   _ctl_cancel.p_y += adjust_y;
   _ctl_help.p_y += adjust_y;
   in_resize = false;
}

defeventtab _font_config_form._font_name_list _inherit _font_form._font_name_list;
_font_name_list.on_create(_str show_font_options="",_str _font_string="") {
   //_message_box('do nothing fontopt='show_font_options' s='_font_string);
}

#region Options Dialog Helper Functions

void _font_config_form_init_for_options()
{
   _ctl_ok.p_visible = false;
   _ctl_help.p_visible = false;
   _ctl_cancel.p_visible = false;

   if (!_UTF8()) {
      ctlEnableBoldAndItalic.p_visible = false;
   }

   if (!ctlEnableBoldAndItalic.p_visible) {
      yDiff := ctlAntiAliasing.p_y - ctlEnableBoldAndItalic.p_y;
      ctlAntiAliasing.p_y -= yDiff;
      _sample_frame.p_y -= yDiff;
   }
}

void _font_config_form_save_settings(_str (&settings):[])
{
   settings:["_ctl_element_list.p_text"] = _ctl_element_list.p_text;
   settings:["_font_name_list.p_text"] = _font_name_list.p_text;
   settings:["_font_size_list.p_text"] = _font_size_list.p_text;
   settings:["_bold.p_value"] = _bold.p_value;
   settings:["_italic.p_value"] = _italic.p_value;
   settings:["_strikethrough.p_value"] = _strikethrough.p_value;
   settings:["_underline.p_value"] = _underline.p_value;
   //settings:["ctlScript.p_text"] = ctlScript.p_text;
}

boolean _font_config_form_is_modified(_str settings:[])
{
   do {
      if (settings:["_ctl_element_list.p_text"] != _ctl_element_list.p_text) break;
      if (settings:["_font_name_list.p_text"] != _font_name_list.p_text) break;
      if (settings:["_font_size_list.p_text"] != _font_size_list.p_text) break;
      if (settings:["_bold.p_value"] != _bold.p_value) break;
      if (settings:["_italic.p_value"] != _italic.p_value) break;
      if (settings:["_strikethrough.p_value"] != _strikethrough.p_value) break;
      if (settings:["_underline.p_value"] != _underline.p_value) break;
      //if (settings:["ctlScript.p_text"] != ctlScript.p_text) break;

      if (_UTF8()) {
         if ( ctlEnableBoldAndItalic.p_value != (_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0) ) break;
      }

      if ( ctlAntiAliasing.p_value != (_default_option(VSOPTION_NO_ANTIALIAS)?0:1) ) break;
      return false;

   } while (false);

   return true;
}

boolean _font_config_form_apply()
{
   /* If they only set a single font, then the ON_GOT_FOCUS event
    * on _ctl_element_list would not have occurred, so save the
    * current settings for the current element.
    */
   typeless result=0;
   _str name=_ctl_element_list.p_text;
   if( name!='' ) {
      name=strip(name);
      result=_font_get_result();
      if( result=='' ) return false;
      _settings:[name].info=result;
   }

   boolean already_prompted=false;
   int already_prompted_status=0;
   // Now do all the macro recording
   typeless i;
   _macro('m',_macro('s'));
   for( i._makeempty();; ) {
      _settings._nextel(i);
      if( i._isempty() ) break;
      if( _settings:[i].id=='sellist' ) {
         if( _dbcs() ) {
            _macro_append("def_qt_jsellist_font="_quote(_settings:[i].info)";");
         } else {
            _macro_append("def_qt_sellist_font="_quote(_settings:[i].info)";");
         }
      } else if( _settings:[i].id==CFG_DIALOG ) {
         _macro_call('_ConfigEnvVar','VSLICKDIALOGFONT',_settings:[i].info);
      } else {
         _macro_append("_default_font("_settings:[i].id","_quote(_settings:[i].info)");");
      }
   }
   for( i._makeempty();; ) {
      _settings._nextel(i);
      if( i._isempty() ) break;

      typeless font_id=_settings:[i].id;
      result=_settings:[i].info;
      typeless orig_result=_orig_settings:[i].info;

      if (font_id==CFG_DIALOG) {
         if( result==orig_result ) continue;
         _ConfigEnvVar('VSLICKDIALOGFONT',result);
      }
      switch (font_id) {
      case CFG_MDICHILDICON:
      //case CFG_MDICHILDTITLE:
         if( result==orig_result ) continue;
         _message_box(get_message(VSRC_FC_CHILD_WINDOWS_NOT_UPDATED));
         break;
      case CFG_DIALOG:
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART));
         continue;
      }

      typeless font_name,font_size,font_flags,charset;
      typeless ofont_name,ofont_size,ofont_flags,ocharset;
      parse result with font_name','font_size','font_flags','charset',';
      parse orig_result with ofont_name','ofont_size','ofont_flags','ocharset',';
      if( font_name==ofont_name && font_size==ofont_size && font_flags==ofont_flags && charset==ocharset) continue;

      if (font_id=='sellist') {
         if (_dbcs()) {
            def_qt_jsellist_font=result;
         } else {
            def_qt_sellist_font=result;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
         continue;
      }

      typeless status=0;
      boolean isEditorFontChange=font_id==CFG_SBCS_DBCS_SOURCE_WINDOW || font_id==CFG_HEX_SOURCE_WINDOW || font_id==CFG_UNICODE_SOURCE_WINDOW || font_id==CFG_FILE_MANAGER_WINDOW;
      if (isEditorFontChange) {
         status=IDYES;
      }
      _config_modify_flags(CFGMODIFY_OPTION);
      if (isEditorFontChange && (status == IDNO)) {
         _default_font(font_id, font_name','font_size','font_flags','charset);
         int wid=_mdi.p_child;
         p_redraw=0;
         wid.p_font_name=font_name;//I've added these changes to immediately update the current window
         wid.p_font_size=font_size;
         wid.p_font_bold      = font_flags & F_BOLD;
         wid.p_font_italic    = font_flags & F_ITALIC;
         wid.p_font_underline = font_flags & F_UNDERLINE;
         wid.p_font_strike_thru = font_flags & F_STRIKE_THRU;
         wid.p_font_charset=charset;
         p_redraw=1;
         continue;
      }
      if (isEditorFontChange && (status == IDYES)) {
         _macro('m',_macro('s'));   //Had to add this to get it to work consistently
         _macro_call('setall_wfonts',font_name, font_size, font_flags,charset,font_id);
         setall_wfonts(font_name, font_size, font_flags,charset,font_id);
         continue;
      }
      _default_font(font_id,result);
   }

   if (_UTF8() && ctlEnableBoldAndItalic.p_enabled) {
      if (ctlEnableBoldAndItalic.p_value!=(_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0)) {
         _default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS,ctlEnableBoldAndItalic.p_value);
         _config_modify_flags(CFGMODIFY_OPTION);
      }
   }

   if ( ctlAntiAliasing.p_value != (_default_option(VSOPTION_NO_ANTIALIAS)?0:1) ) {
      _default_option(VSOPTION_NO_ANTIALIAS, (ctlAntiAliasing.p_value ? 0 : 1));
      _config_modify_flags(CFGMODIFY_OPTION);
   }

   _orig_settings = _settings;

   return true;
}

_str _font_config_form_build_export_summary(PropertySheetItem (&table)[])
{
   settings := '';
   typeless i;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=glist._nextel(i);
      if (i._isempty()) break;

      typeless id = fontcfginfo.value;
      info := '';

      if (id == CFG_UNICODE_SOURCE_WINDOW && !_UTF8()) continue;
      if (!allow_element(id)) continue;
      if (id == CFG_STATUS && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_STATUS_FONT) == 0)) continue;
      if (id == CFG_CMDLINE && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT) == 0)) continue;
      if (id == CFG_DOCUMENT_TABS && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT) == 0)) continue;

      if( id=='sellist' ) {
         info= (_dbcs()?def_qt_jsellist_font:def_qt_sellist_font);
         _str font_name, font_size, font_style, charset;
         parse info with font_name ',' font_size ',' font_style ',' charset',';
         if (charset=='') {
            charset=VSCHARSET_DEFAULT;
            info=font_name ',' font_size ',' font_style ',' charset',';
         }
      } else {
         info=_default_font(id);
      }

      typeless font_name, font_size, font_style, charset;
      parse info with font_name ',' font_size ',' font_style ',' charset',';
      info = font_name' size 'font_size;
      if (charset != '') {
         info :+= ', '_CharSet2Name(charset)' Script';
      }
      
      if (isinteger(font_style)) {
         if (font_style & F_BOLD) {
            info :+= ', Bold';
         }
         if (font_style & F_ITALIC) {
            info :+= ', Italic';
         }
         if (font_style & F_UNDERLINE) {
            info :+= ', Underline';
         }
         if (font_style & F_STRIKE_THRU) {
            info :+= ', Strikethrough';
         }
      }
      
      PropertySheetItem psi;
      psi.Caption = fontcfginfo.name;
      psi.Value = info;
      psi.ChangeEvents = (id == CFG_DIALOG) ? OCEF_DIALOG_FONT_RESTART : 0;
      
      table[table._length()] = psi;
   }

   PropertySheetItem psi;
   psi.Caption = 'Use fixed spacing for bold and italic fixed Unicode fonts';
   psi.Value = _default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS) ? 'True' : 'False';
   psi.ChangeEvents = 0;

   table[table._length()] = psi;

   psi.Caption = 'Use anti-aliasing';
   psi.Value = _default_option(VSOPTION_NO_ANTIALIAS) ? 'False' : 'True';
   psi.ChangeEvents = 0;

   table[table._length()] = psi;

   return '';
}

_str _font_config_form_import_summary(PropertySheetItem (&table)[])
{
   error := '';

   // first go through and make a table of all the names and IDs
   typeless namesIds:[];
   typeless i;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=glist._nextel(i);
      if (i._isempty()) break;

      namesIds:[fontcfginfo.name] = fontcfginfo.value;
   }

   // get a table of our available fonts
   _str fontTable:[];
   getTableOfFonts(fontTable);
   
   PropertySheetItem psi;
   foreach (psi in table) {
      // the caption is the value...
      if (namesIds._indexin(psi.Caption)) {
         id := namesIds:[psi.Caption];
         
         // now compile the info into something we can use!
         typeless font_name, font_size, charset, rest;
         parse psi.Value with font_name 'size' font_size','rest;
         
         // make sure this font exists on this machine
         font_name = lowcase(strip(font_name));
         if (fontTable._indexin(font_name)) {
            // the key is all lowercase, but the value is the actual name
            font_name = fontTable:[font_name];
   
            parse rest with charset 'Script' rest;
            if (charset != '') {
               charset = _CharSetName2Id(charset);
            }
   
            font_style := 0;
            if (pos('Bold', rest)) {
               font_style |= F_BOLD;
            }
            if (pos('Italic', rest)) {
               font_style |= F_ITALIC;
            }
            if (pos('Underline', rest)) {
               font_style |= F_UNDERLINE;
            }
            if (pos('Strikethrough', rest)) {
               font_style |= F_STRIKE_THRU;
            }
   
            font_size = strip(font_size);
            info := font_name','font_size','font_style','charset',';
   
            editorFont := id == CFG_SBCS_DBCS_SOURCE_WINDOW || 
               id == CFG_HEX_SOURCE_WINDOW || 
               id == CFG_UNICODE_SOURCE_WINDOW || 
               id == CFG_FILE_MANAGER_WINDOW;
            if (editorFont) {
               _macro('m',_macro('s'));   //Had to add this to get it to work consistently
               _macro_call('setall_wfonts', font_name, font_size, font_style, charset, id);
               setall_wfonts(font_name, font_size, font_style, charset, id);
            } else if (id=='sellist') {
               if (_dbcs()) {
                  def_qt_jsellist_font = info;
               } else {
                  def_qt_sellist_font = info;
               }
            } else {
               if (_default_font(id) == info) continue;
               
               if (id == CFG_DIALOG) {
                  _ConfigEnvVar('VSLICKDIALOGFONT', info);
               }
   
               _default_font(id, info);
            }
         } else {
            // this font does not exist here - sorry!
            error :+= 'Error setting font configuration for element 'psi.Caption' - 'font_name' does not exist on this machine.'OPTIONS_ERROR_DELIMITER;
         }
      } else {
         switch (psi.Caption) {
         case 'Use anti-aliasing':
            _default_option(VSOPTION_NO_ANTIALIAS, (psi.Value == 'True') ? 0 : 1);
            break;
         case 'Use fixed spacing for bold and italic fixed Unicode fonts':
            _default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS, (psi.Value == 'True') ? 1 : 0);
            break;
         default:
            error :+= 'Error setting font configuration for element 'psi.Caption'.'OPTIONS_ERROR_DELIMITER;
            break;
         }
      }
   }

   _config_modify_flags(CFGMODIFY_OPTION);
   return error;
}

#endregion Options Dialog Helper Functions

_ctl_element_list.on_create()
{
   _macro('m',_macro('s'));

   // From the user feed back we are getting, a number of users want bold and italic for XML files.
   // This will give them that as long as the choose a fixed Unicode font.
   ctlEnableBoldAndItalic.p_value= (_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0);
   ctlAntiAliasing.p_value = (_default_option(VSOPTION_NO_ANTIALIAS)?0:1);

   // The following nationalizes the content of the Elements combo box.
   // Look up the language-specific strings.
   typeless i=0;
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_COMMAND_LINE);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_STATUS_LINE);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_SBCS_DBCS_SOURCE_WINDOWS);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_HEX_SOURCE_WINDOWS);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_UNICODE_SOURCE_WINDOWS);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_FILE_MANAGER_WINDOWS);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_DIFF_EDITOR_WINDOWS);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_PARAMETER_INFO);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_PARAMETER_INFO_FIXED);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_SELECTION_LIST);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_MENU);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_DIALOG);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_MINIHTML_PROPORTIONAL);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_MINIHTML_FIXED);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_DOCUMENT_TABS);
#if 0  /* __UNIX__ */
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_MDI_CHILD_ICON);
   glist[i++].name=get_message(VSRC_FCF_ELEMENTS_MDI_CHILD_TITLE);
#endif

   // Disallow ON_CHANGE events to _ctl_element_list
   CHANGING_ELEMENT_LIST=0;
   // arg(1) and arg(2) are passed to the on_create() event of _font_form._font_name_list
   FillInElementList();

   typeless default_element_id=arg(3);
   if( default_element_id=='' ) {
      _ctl_element_list._retrieve_value();
      _str element_name=p_text;
      if( element_name=='' ) {
         default_element_id=CFG_SBCS_DBCS_SOURCE_WINDOW;
      } else {
         default_element_id= element_name;
      }
   }
   SetElementListDefault(default_element_id);


   // Save all the original element settings

   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=glist._nextel(i);
      if (i._isempty()) break;
      _str name=fontcfginfo.name;
      typeless id=fontcfginfo.value;
      //id=ghashtab:[name];
      _settings:[name].id=id;
      if( id=='sellist' ) {
         _str info= (_dbcs()?def_qt_jsellist_font:def_qt_sellist_font);
         _str font_name, font_size, font_style, charset;
         parse info with font_name ',' font_size ',' font_style ',' charset',';
         if (charset=='') {
            charset=VSCHARSET_DEFAULT;
            info=font_name ',' font_size ',' font_style ',' charset',';
         }
         _settings:[name].info=info;
      } else {
         _settings:[name].info=_default_font(id);
      }
   }
   //say('xx info='_settings:['Selection List'].info);
   _orig_settings=_settings;

   // Re-allow ON_CHANGE events to _ctl_element_list
   CHANGING_ELEMENT_LIST=1;

   // This is already being done in on_load()
   //call_event(CHANGE_OTHER,_ctl_element_list,ON_CHANGE);

}

_ctl_element_list.on_destroy()
{
   // Save the last element we were working on
   _append_retrieve(_ctl_element_list,_ctl_element_list.p_text);

   // Empty the _settings hash table so it doesn't get stored in the state file.
   _settings._makeempty();
}

void _font_config_form.on_load()
{
   // Do this after the on_create()'s because the list will be filled in now
   CHANGING_ELEMENT_LIST=1;
   _ctl_element_list.call_event(CHANGE_OTHER,_ctl_element_list,ON_CHANGE,"W");
   if (ctlfixedfonts.p_value==1 &&
       _font_name_list.p_text!="" &&
       _font_name_list.p_text!=_font_name_list._lbget_text()) {
      ctlfixedfonts.p_value=0;
      ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);
   }
   _font_name_list._set_focus();
}

// Bad font name
static void _fn_bad_setting(_str msg)
{
   int fontCfgForm = _find_formobj('_font_config_form', 'n');
   int fnList = fontCfgForm._font_name_list;
   fnList._set_sel(1,length(fnList.p_text)+1);
   fnList._set_focus();
   _post_call(find_index('popup_message',COMMAND_TYPE),msg);
   return;
}

// Bad font size
static void _fs_bad_setting(_str msg)
{
   int fontCfgForm = _find_formobj('_font_config_form', 'n');
   int fsList = fontCfgForm._font_size_list;
   fsList._set_sel(1,length(fsList.p_text)+1);
   fsList._set_focus();
   _post_call(find_index('popup_message',COMMAND_TYPE),msg);
   return;
}

_ctl_element_list.on_got_focus()
{
   _str name=strip(_ctl_element_list.p_text);

   #if 1
   // Wholesaled from _font_get_result() in font.e
   int flags = 0;
   typeless result=0;

   _str font_name=_font_name_list.p_text;
   typeless font_size=_font_size_list.p_text;
   if (!isinteger(font_size)) {
      typeless width, height;
      parse font_size with width 'x','i' height;
      if (!isinteger(width) || !isinteger(height)) {
         _post_call(_fs_bad_setting, get_message(VSRC_FC_INVALID_FONT_SIZE));
         result='';
      }
      if (lowcase(font_name)!='terminal') {
         _post_call(_fs_bad_setting,get_message(VSRC_FC_TERMINAL_FONT_SIZE));
         result='';
      }
   } else if (font_size > 400) {
      _post_call(_fs_bad_setting,get_message(VSRC_FC_INVALID_FONT_SIZE));
      result='';
   }
   if(_font_name_list._lbfind_item(font_name) < 0){
      p_window_id=_font_name_list;
      _post_call(_fn_bad_setting,get_message(VSRC_FC_INVALID_FONT_NAME));
      result='';
   }else{
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
      result=_sample_text.p_font_name','_font_size_list.p_text','flags','_sample_text.p_font_charset',';
   }
   #else
   result=_font_get_result(1);
   #endif

   if( result!='' ) {
      _settings:[name].info=result;   /* Save this so we don't lose
                                       * the settings when user picks
                                       * another element.
                                       */
   }
}

_ctl_ok.lbutton_up()
{
   if (_font_config_form_apply()) {
      p_active_form._delete_window(0);
   } else {
      return('');
   }
}

void _ctl_element_list.on_change(int reason=CHANGE_OTHER)
{
   if( CHANGING_ELEMENT_LIST ) {
      int disable_fixedfonts=0;
      int show_fixedfonts=0;
      _str font_options='';
      _str font_id=_settings:[p_text].id;
      _str font=_settings:[p_text].info;
      if( font_id==CFG_SBCS_DBCS_SOURCE_WINDOW || 
          font_id==CFG_HEX_SOURCE_WINDOW || 
          font_id==CFG_UNICODE_SOURCE_WINDOW || 
          font_id==CFG_FILE_MANAGER_WINDOW || 
          font_id==CFG_DIFF_EDITOR_WINDOW || 
          font_id==CFG_MINIHTML_FIXED) {
         show_fixedfonts=1;
      }
      // Disable fixed fonts option?
      if( disable_fixedfonts ) {
         ctlfixedfonts.p_enabled=0;
         ctlEnableBoldAndItalic.p_enabled = false;
      }

      // Show only fixed fonts?
      if( show_fixedfonts ) {
         font_options=font_options'f';
         ctlfixedfonts.p_value=1;
         ctlEnableBoldAndItalic.p_enabled = true;
      } else {
         ctlfixedfonts.p_value=0;
         ctlEnableBoldAndItalic.p_enabled = false;
      }

      typeless font_name,font_size,font_style,charset;
      parse font with font_name ',' font_size ',' font_style ',' charset',';

      // Disallow ON_CHANGE events on _font_name_list and _font_size_list
      CHANGING_NAME_LIST=CHANGING_SIZE_LIST=0;
      //CHANGING_SCRIPT_LIST=0;

      // Set the font in _font_name_list.p_text
      _font_name_list.p_text=font_name;

      // Set the size in _font_size_list.p_text
      _font_size_list.p_text=font_size;
      //ctlScript.p_text=_CharSet2Name(charset);
      _sample_text.p_font_charset=charset;

      // Set the style
      _bold.p_value=0;
      _italic.p_value=0;
      _strikethrough.p_value=0;
      _underline.p_value=0;
      if( isinteger(font_style) ) {
         if( font_style&F_BOLD ) {
            _bold.p_value=1;
         }
         if( font_style&F_ITALIC ) {
            _italic.p_value=1;
         }
         if( font_style&F_STRIKE_THRU ) {
            _strikethrough.p_value=1;
         }
         if( font_style&F_UNDERLINE ) {
            _underline.p_value=1;
         }
      }

      /* Call this no matter what because it causes the font list
       * to be refreshed.
       */
      _font_name_list.p_user=font_options;
      ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);

      // Select font_name in the list box
      _font_name_list._lbfind_and_select_item(font_name);

      CHANGING_NAME_LIST=CHANGING_SIZE_LIST=1;

      /* Call the ON_CHANGE event for _font_name_list so the list of sizes
       * and sample text are updated.
       */
      _font_name_list.call_event(CHANGE_OTHER,_font_name_list,ON_CHANGE,'W');

      _str charsetName=_CharSet2Name(charset);

      // Select the font name in the text box of _font_name_list
      p_window_id=_font_name_list;

      if (ctlfixedfonts.p_value==1 &&
          _font_name_list.p_text!="" &&
          _font_name_list.p_text!=_font_name_list._lbget_text()) {
         ctlfixedfonts.p_value=0;
         ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);
      }
   }
}

void setall_wfonts(_str font_name, _str font_size,int font_flags,int charset=VSCHARSET_DEFAULT,int font_id=CFG_SBCS_DBCS_SOURCE_WINDOW)
{
   _change_all_wfonts(font_name,font_size,font_flags,charset,font_id);
}
static boolean allow_element(int value) {
   if (value==CFG_MDICHILDTITLE || value==CFG_MENU) {
      return (__UNIX__ && !__MACOSX__) && !_OEM();
   }
   return true;
}

static FillInElementList()
{
   typeless i;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=glist._nextel(i);
      if (i._isempty()) break;
      _str name=fontcfginfo.name;
      typeless value=fontcfginfo.value;
      if( allow_element(value) ) {
         if (value==CFG_STATUS) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_STATUS_FONT)) {
               _ctl_element_list._lbadd_item(name);
            }
         } else if (value==CFG_CMDLINE) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT)) {
               _ctl_element_list._lbadd_item(name);
            }
         } else if (value==CFG_DOCUMENT_TABS) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT)) {
               _ctl_element_list._lbadd_item(name);
            }
         } else {
            _ctl_element_list._lbadd_item(name);
         }
      }
   }

}
static SetElementListDefault(_str default_element_id)
{
   if( default_element_id==null || default_element_id=='' ) {
      default_element_id=CFG_SBCS_DBCS_SOURCE_WINDOW;
   }
   _str default_name='';
   _str default_element='';
   typeless i;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=glist._nextel(i);
      if (i._isempty()) break;
      _str name=fontcfginfo.name;
      typeless value=fontcfginfo.value;
      if (value==CFG_SBCS_DBCS_SOURCE_WINDOW) {
         default_name=name;
      }
      if (value==default_element_id || default_element_id==name) {
         default_element=name;
      }
   }

   if (default_element=='') {
      default_element=default_name;
   }
   _ctl_element_list.p_text=default_element;
}


