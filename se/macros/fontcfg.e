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
#include "license.sh"
#import "ccode.e"
#import "files.e"
#import "font.e"
#import "listbox.e"
#import "main.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbprops.e"
#import "treeview.e"
#import "wfont.e"
#import "cfg.e"
#endregion

struct FONTCFGINFO {
   _str name;
   _str nameid;
   _str value;
   _str desc;
};

static FONTCFGINFO gfontcfglist[]={
   {"Command Line",'cmdline',CFG_CMDLINE, 'The SlickEdit command line is displayed at the bottom of the application window and is accessed by pressing ESC for most emulatios.'},
   {"Status Line",'status',CFG_STATUS, 'Status messages are displayed at the bottom of the application window.'},
   {"SBCS/DBCS Source Windows",'sbcs_dbcs_source_window', CFG_SBCS_DBCS_SOURCE_WINDOW, 'Editor windows that are displaying non-Unicode content (Windows: plain text).'},
   {"SBCS/DBCS Minimap Windows",'sbcs_dbcs_minimap_window', CFG_SBCS_DBCS_MINIMAP_WINDOW, 'Minimap windows that are displaying non-Unicode content (Windows: plain text).'},
   {"Hex Source Windows",'hex_source_window', CFG_HEX_SOURCE_WINDOW, 'Editor windows that are being viewed in Hex mode (View > Hex).'},
   {"Unicode Source Windows",'unicode_source_window', CFG_UNICODE_SOURCE_WINDOW, 'Editor windows that are displaying Unicode content (for example, XML).'},
   {"Unicode Minimap Windows",'unicode_minimap_window', CFG_UNICODE_MINIMAP_WINDOW, 'Minimap windows that are displaying Unicode content (for example, XML).'},
   {"File Manager Windows",'file_manager_window',CFG_FILE_MANAGER_WINDOW, 'Controls the display of the SlickEdit File Manager (File > File Manager).'},
   {"Diff Editor SBCS/DBCS Source Windows",'diff_editor_window', CFG_DIFF_EDITOR_WINDOW, 'The editor windows used by DIFFzilla (Tools > File Difference) that are displaying non-Unicode content.'},
   {"Diff Editor Unicode Source Windows",'unicode_diff_editor_window', CFG_UNICODE_DIFF_EDITOR_WINDOW, 'The editor windows used by DIFFzilla (Tools > File Difference) that are displaying Unicode content.'},
   {"Parameter Information",'function_help', CFG_FUNCTION_HELP, 'Controls the fonts used to display pop-ups with information about symbols and parameters.'},
   {"Parameter Information Fixed",'function_help_fixed',CFG_FUNCTION_HELP_FIXED, 'Used when SlickEdit needs to display a fixed-width font for parameter info, such as when displaying example code.'},
   {"Selection List",'selection_list',"sellist", 'The font used for selection lists, like the document language list (Document > Select Mode).'},
#if 1 /* __UNIX__ */
   {"Menu",'menu',CFG_MENU, 'Includes the main menu, as well as context menus.'},
#endif
   {"Dialog",'dialog', CFG_DIALOG, 'Controls the font used in SlickEdit dialogs and tool windows.'},
   {"HTML Proportional",'minihtml_proportional', CFG_MINIHTML_PROPORTIONAL, 'The default font used by HTML controls for proportional fonts. In particular, this affects the Version Control History dialog, the About SlickEdit dialog, and the Cool Features dialog.'},
   {"HTML Fixed",'minihtml_fixed', CFG_MINIHTML_FIXED, 'The default font used by HTML controls for fixed-space fonts.'},
   {"Document Tabs",'document_tabs', CFG_DOCUMENT_TABS, 'The tabs used to easily switch between open documents.'},
};

static int CHANGING_ELEMENT_LIST(...) {
   if (arg()) _italic.p_user=arg(1);
   return _italic.p_user;
}

// These are also defined in font.e
static int FONTCFG_CHANGING_NAME_LIST(...) {
   if (arg()) _sample_frame.p_user=arg(1);
   return _sample_frame.p_user;
}

static int FONTCFG_CHANGING_SIZE_LIST(...) {
   if (arg()) _font_size_list.p_user=arg(1);
   return _font_size_list.p_user;
}
static _str CURRENT_FONT_ELEMENT(...) {
   if (arg()) _bold.p_user=arg(1);
   return _bold.p_user;
}

struct FONTCFGSETTINGS {
   _str id;   // This is a string because of 'sellist'
   _str nameid;
   _str orig_info;
   _str info;
};

static FONTCFGSETTINGS gfontsettings:[];

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
      if (endsWith(line, ')')) {
         parse line with line " (";
      }
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


#region Options Dialog Helper Functions

defeventtab _font_config_form;

void _font_config_form_init_for_options()
{
   if (!_UTF8()) {
      ctlEnableBoldAndItalic.p_visible = false;
   }

   if (!ctlEnableBoldAndItalic.p_visible) {
      yDiff := ctlAntiAliasing.p_y - ctlEnableBoldAndItalic.p_y;
      ctlAntiAliasing.p_y -= yDiff;
      _sample_frame.p_y -= yDiff;
   }
}

bool _font_config_form_is_modified()
{
   do {
      // save in case user made changes
      saveCurrentFontSettings(true);

      changed := false;
      foreach (auto id => auto fInfo in gfontsettings) {
         if (fInfo.orig_info != fInfo.info) {
            changed = true;
            break;
         }
      }
      if (changed) break;

      if (_UTF8()) {
         if ( ctlEnableBoldAndItalic.p_value != (_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0) ) break;
      }

      if ( ctlAntiAliasing.p_value != (_default_option(VSOPTION_NO_ANTIALIAS)?0:1) ) break;

      return false;

   } while (false);

   return true;
}

bool _font_config_form_apply()
{
   saveCurrentFontSettings();

   already_prompted := false;
   already_prompted_status := 0;
   // Now do all the macro recording
   typeless i;
   _macro('m',_macro('s'));
   for( i._makeempty();; ) {
      gfontsettings._nextel(i);
      if( i._isempty() ) break;
      if (gfontsettings:[i].orig_info != gfontsettings:[i].info) {
         typeless font_name,font_size,font_flags,charset;
         parse gfontsettings:[i].info with font_name','font_size','font_flags','charset',';
         if( gfontsettings:[i].id=='sellist' ) {
            _macro_call('_setFont',font_name,font_size,font_flags);
            //_macro_append("def_qt_sellist_font="_quote(gfontsettings:[i].info)";");
         } else {
            _macro_append("_default_font("gfontsettings:[i].id","_quote(gfontsettings:[i].info)");");
         }
      }
   }
   for( i._makeempty();; ) {
      gfontsettings._nextel(i);
      if( i._isempty() ) break;

      typeless font_id=gfontsettings:[i].id;
      _str nameid=gfontsettings:[i].nameid;
      typeless result=gfontsettings:[i].info;
      orig_result := gfontsettings:[i].orig_info;

      if( result==orig_result ) continue;

      typeless font_name,font_size,font_flags,charset;
      typeless ofont_name,ofont_size,ofont_flags,ocharset;
      parse result with font_name','font_size','font_flags','charset',';
      parse orig_result with ofont_name','ofont_size','ofont_flags','ocharset',';
      if( font_name==ofont_name && font_size==ofont_size && font_flags==ofont_flags && charset==ocharset) continue;
      gfontsettings:[i].orig_info=result;

      _set_font_profile_property(font_id,font_name,font_size,font_flags,charset);
      if (font_id=='sellist') {
         _setSelectionListFont(result);
         continue;
      }
      isEditorFontChange := font_id==CFG_SBCS_DBCS_SOURCE_WINDOW || font_id==CFG_HEX_SOURCE_WINDOW || font_id==CFG_UNICODE_SOURCE_WINDOW || font_id==CFG_FILE_MANAGER_WINDOW;
      isMinimapFontchange:= font_id==CFG_SBCS_DBCS_MINIMAP_WINDOW  || font_id==CFG_UNICODE_MINIMAP_WINDOW;
      if (isEditorFontChange || isMinimapFontchange) {
         _macro('m',_macro('s'));   //Had to add this to get it to work consistently
         _macro_call('setall_wfonts',font_name, font_size, font_flags,charset,font_id);
         setall_wfonts(font_name, font_size, font_flags,charset,font_id);
         continue;
      }
      _default_font(font_id,result);

      gfontsettings:[i].orig_info = gfontsettings:[i].info;
      switch (font_id) {
      case CFG_MDICHILDICON:
      //case CFG_MDICHILDTITLE:
         if( result==orig_result ) continue;
         _message_box(get_message(VSRC_FC_CHILD_WINDOWS_NOT_UPDATED));
         break;
      case CFG_DIALOG:
         if (index_callable(find_index("tbReloadBitmaps", COMMAND_TYPE|PROC_TYPE))) {
            if (def_toolbar_pic_auto) tbReloadBitmaps("auto","",reloadSVGFromDisk:false);
         }
         if (index_callable(find_index("tbReloadTreeBitmaps", COMMAND_TYPE|PROC_TYPE))) {
            if (def_toolbar_tree_pic_auto) tbReloadTreeBitmaps("auto","",reloadSVGFromDisk:false);
         }
         if (index_callable(find_index("tbReloadTabBitmaps", COMMAND_TYPE|PROC_TYPE))) {
            if (def_toolbar_tab_pic_auto) tbReloadTabBitmaps("auto","",reloadSVGFromDisk:false);
         }
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART_DIALOG_FONT));
         continue;
      }

   }

   if (_UTF8() && ctlEnableBoldAndItalic.p_enabled) {
      if (ctlEnableBoldAndItalic.p_value!=(_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0)) {
         _default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS,ctlEnableBoldAndItalic.p_value);
      }
   }

   if ( ctlAntiAliasing.p_value != (_default_option(VSOPTION_NO_ANTIALIAS)?0:1) ) {
      _default_option(VSOPTION_NO_ANTIALIAS, (ctlAntiAliasing.p_value ? 0 : 1));
   }

   return true;
}

_str _font_config_form_build_export_summary(PropertySheetItem (&table)[])
{
   settings := '';
   typeless i;
   nationalizeElementNames();
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=gfontcfglist._nextel(i);
      if (i._isempty()) break;

      typeless id = fontcfginfo.value;
      info := '';

      if (id == CFG_UNICODE_SOURCE_WINDOW && !_UTF8()) continue;
      if (!allow_element(id)) continue;
      if (id == CFG_STATUS && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_STATUS_FONT) == 0)) continue;
      if (id == CFG_CMDLINE && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT) == 0)) continue;
      if (id == CFG_DOCUMENT_TABS && ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT) == 0)) continue;
      if ((id == CFG_FUNCTION_HELP || id == CFG_FUNCTION_HELP_FIXED) && !_haveContextTagging()) continue;

      if( id=='sellist' ) {
         info= _getSelectionListFont();
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

   nationalizeElementNames();
   // first go through and make a table of all the names and IDs
   typeless namesIds:[];
   typeless i;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=gfontcfglist._nextel(i);
      if (i._isempty()) break;

      namesIds:[fontcfginfo.name] = fontcfginfo.value;
   }

   // get a table of our available fonts
   _str fontTable:[];
   getTableOfFonts(fontTable);
   
   PropertySheetItem psi;
   foreach (psi in table) {
      // the caption is the value...
      set_def_unicode_font_too := false;
      if ( psi.Caption=='Diff Editor Source Windows') {
         psi.Caption='Diff Editor SBCS/DBCS Source Windows';
         set_def_unicode_font_too=true;
      }
      if (namesIds._indexin(psi.Caption)) {
         id := namesIds:[psi.Caption];
         
         // now compile the info into something we can use!
         typeless font_name, font_size, charset, rest;
         if (substr(psi.Value,1,7)==' size ') {
            font_name='';
            parse psi.Value with 'size' font_size','rest;
         } else {
            parse psi.Value with font_name 'size' font_size','rest;
         }
         
         // make sure this font exists on this machine
         font_name = lowcase(strip(font_name));

         // this font is not font on this machine,
         // maybe the font name ends with [Adobe], and this platform
         // has that, but without the [Adobe] part (Helvetica, Courier)
         if (font_name!='' && !fontTable._indexin(font_name)) {
            parse font_name with auto simplified_font_name '[' .;
            simplified_font_name = strip(simplified_font_name);
            if (fontTable._indexin(simplified_font_name)) {
               font_name = simplified_font_name;
            }
         }

         // the font is still not found, maybe it's this is a default
         // option that we can exchange for the platform-non-specific default.
         if (font_name!='' && !fontTable._indexin(font_name)) {

            // if importing options that were exported on another platform,
            // the default fonts may not be available, so try to substitute
            // it for the default font type.
            _str prop_font_names[];
            prop_font_names :+= "lucida grande";
            prop_font_names :+= "dejavu sans";
            prop_font_names :+= "lucida";
            prop_font_names :+= "arial";
            prop_font_names :+= "bitstream vera sans";
            prop_font_names :+= "helvetica";
            prop_font_names :+= "helvetica [adobe]";
            prop_font_names :+= "calibri";
            prop_font_names :+= "times new roman";
            if (_array_find_item(prop_font_names, font_name) >= 0) {
               error :+= 'Warning: replacing font configuration for element 'psi.Caption' - missing font "'font_name'" with 'VSDEFAULT_DIALOG_FONT_NAME'.'OPTIONS_ERROR_DELIMITER;
               font_name = lowcase(VSDEFAULT_DIALOG_FONT_NAME);
            }
            // try the same logic for fixed fonts
            _str fixed_font_names[];
            fixed_font_names :+= "consolas";
            fixed_font_names :+= "menlo";
            fixed_font_names :+= "andale mono";
            fixed_font_names :+= "monaco";
            fixed_font_names :+= "dejavu sans mono";
            fixed_font_names :+= "bitstream vera sans mono";
            fixed_font_names :+= "courier";
            fixed_font_names :+= "courier [adobe]";
            fixed_font_names :+= "courier new";
            if (_array_find_item(fixed_font_names, font_name) >= 0) {
               error :+= 'Warning: replacing font configuration for element 'psi.Caption' - missing font "'font_name'" with 'VSDEFAULT_FIXED_FONT_NAME'.'OPTIONS_ERROR_DELIMITER;
               font_name = lowcase(VSDEFAULT_FIXED_FONT_NAME);
            }
         }

         // try it now.
         if (font_name=='' || fontTable._indexin(font_name)) {
            if (font_name!='') {
               // the key is all lowercase, but the value is the actual name
               font_name = fontTable:[font_name];
            }
   
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
            _setFont(id,font_name,font_size,font_style);
            if ( set_def_unicode_font_too ) {
               _setFont(CFG_UNICODE_DIFF_EDITOR_WINDOW,font_name,font_size,font_style);
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

   return error;
}

void _convert_default_fonts_to_profile() {
   for (i:=0;i<gfontcfglist._length();++i) {
      _str nameid=gfontcfglist[i].nameid;
      typeless cfg=gfontcfglist[i].value;
      if (isinteger(cfg)) {
         if (allow_element(cfg)) {
            typeless font_name,font_size,font_flags,charset;
            parse _default_font(cfg) with font_name','font_size','font_flags','charset',';
            _set_font_profile_property(cfg,font_name,font_size,font_flags,charset);
         }
      } else if(cfg=='sellist') {
         index:=find_index('def_qt_sellist_font',VAR_TYPE);
         if (index>0) {
            _setSelectionListFont(name_info(index));
         }
      }
   }
}

void _set_font_profile_property(typeless id, _str font_name, _str font_size, int font_style, int charset) {
   nameid:=elementIdToNameId(id);
   if (nameid!='' && 
       (font_name!='' || (id==CFG_SBCS_DBCS_MINIMAP_WINDOW || id==CFG_UNICODE_MINIMAP_WINDOW)) &&
        isinteger(font_size) && isinteger(font_style)) {
      handle:=_xmlcfg_create('',VSENCODING_UTF8);
      property_node:=_xmlcfg_add_property(handle,0,nameid);
      attrs_node:=property_node;
      _xmlcfg_set_attribute(handle,attrs_node,'font_name',font_name);
      _xmlcfg_set_attribute(handle,attrs_node,'sizex10',((int)font_size)*10);
      _xmlcfg_set_attribute(handle,attrs_node,'flags',"0x":+_dec2hex(font_style));
      _plugin_set_property_xml(VSCFGPACKAGE_MISC,VSCFGPROFILE_FONTS,VSCFGPROFILE_FONTS_VERSION,nameid,handle);
      _xmlcfg_close(handle);
   }
}

void _setFont(typeless id, _str font_name, _str font_size, int font_style, int charset=0)
{
   info := font_name','font_size','font_style','charset',';

   editorFont := id == CFG_SBCS_DBCS_SOURCE_WINDOW ||
      id == CFG_HEX_SOURCE_WINDOW ||
      id == CFG_UNICODE_SOURCE_WINDOW ||
      id == CFG_FILE_MANAGER_WINDOW ||
      id==CFG_SBCS_DBCS_MINIMAP_WINDOW  || id==CFG_UNICODE_MINIMAP_WINDOW;
   _set_font_profile_property(id,font_name,font_size,font_style,charset);
   if (editorFont) {
      _macro('m',_macro('s'));   //Had to add this to get it to work consistently
      _macro_call('setall_wfonts', font_name, font_size, font_style, charset, id);
      setall_wfonts(font_name, font_size, font_style, charset, id);
   } else if (id=='sellist') {
      _setSelectionListFont(info);
   } else {
      if (_default_font(id) != info) {
         _default_font(id, info);
      }
   }
}

static void nationalizeElementNames()
{
#if 0
   typeless i=0;
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_COMMAND_LINE);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_STATUS_LINE);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_SBCS_DBCS_SOURCE_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_HEX_SOURCE_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_UNICODE_SOURCE_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_FILE_MANAGER_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_DIFF_EDITOR_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_UNICODE_DIFF_EDITOR_WINDOWS);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_PARAMETER_INFO);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_PARAMETER_INFO_FIXED);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_SELECTION_LIST);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_MENU);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_DIALOG);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_MINIHTML_PROPORTIONAL);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_MINIHTML_FIXED);
   gfontcfglist[i++].name=get_message(VSRC_FCF_ELEMENTS_DOCUMENT_TABS);
#endif
}

//definit()
//{
//   _dump_var(gfontcfglist, "_ctl_element_tree.on_create H"__LINE__": gfontcfglist");
//}

_ctl_element_tree.on_create()
{
   _macro('m',_macro('s'));

   // From the user feed back we are getting, a number of users want bold and italic for XML files.
   // This will give them that as long as the choose a fixed Unicode font.
   ctlEnableBoldAndItalic.p_value= (_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS)?1:0);
   ctlAntiAliasing.p_value = (_default_option(VSOPTION_NO_ANTIALIAS)?0:1);

   // The following nationalizes the content of the Elements combo box.
   // Look up the language-specific strings.
   nationalizeElementNames();

   // Disallow ON_CHANGE events to _ctl_element_list
   CHANGING_ELEMENT_LIST(0);
   // arg(1) and arg(2) are passed to the on_create() event of _font_form._font_name_list
   FillInElementTree();

   // select the default value
   typeless defaultId=arg(3);
   if (defaultId == '') {
      // check the current file encoding
      enc := _GetDefaultEncoding();
      if (!_no_child_windows()) {
         enc = _mdi.p_child.p_encoding;
      }

      if (enc >= VSENCODING_UTF8 && enc <= VSENCODING_UTF32BE_WITH_SIGNATURE) {
         defaultId = CFG_UNICODE_SOURCE_WINDOW;
      } else {
         defaultId = CFG_SBCS_DBCS_SOURCE_WINDOW;
      }
   }
   defaultId = elementIdToName(defaultId);
   index := _ctl_element_tree._TreeSearch(TREE_ROOT_INDEX, defaultId);
   if (index > 0) {
      _ctl_element_tree._TreeSetCurIndex(index);
   } else {
      _ctl_element_tree._TreeTop();
   }

   // Save all the original element settings
   typeless i=0;
   for (i._makeempty();;) {
      FONTCFGINFO fontcfginfo;
      fontcfginfo=gfontcfglist._nextel(i);
      if (i._isempty()) break;
      _str name=fontcfginfo.name;
      typeless id=fontcfginfo.value;
      //id=ghashtab:[name];
      gfontsettings:[name].id=id;
      gfontsettings:[name].nameid=fontcfginfo.nameid;
      if( id=='sellist' ) {
         _str info= _getSelectionListFont();
         _str font_name, font_size, font_style, charset;
         parse info with font_name ',' font_size ',' font_style ',' charset',';
         if (charset=='') {
            charset=VSCHARSET_DEFAULT;
            info=font_name ',' font_size ',' font_style ',' charset',';
         }
         gfontsettings:[name].info=info;
      } else {
         gfontsettings:[name].info=_default_font(id);
      }

      gfontsettings:[name].orig_info = gfontsettings:[name].info;
   }

   // Re-allow ON_CHANGE events to _ctl_element_list
   CHANGING_ELEMENT_LIST(1);

   // make sure something is selected
   index = _ctl_element_tree._TreeCurIndex();
   _ctl_element_tree.call_event(CHANGE_SELECTED, index, _ctl_element_tree,ON_CHANGE,"W");
   parse _font_name_list._lbget_text() with auto from_list_font_name " (";
   if (ctlfixedfonts.p_value==1 &&
       _font_name_list.p_text!="" &&
       _font_name_list.p_text!=from_list_font_name) {
      ctlfixedfonts.p_value=0;
      ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);
   }
   _font_name_list._set_focus();
}

static FillInElementTree()
{
   FONTCFGINFO fontcfginfo;
   foreach (fontcfginfo in gfontcfglist) {
      name := fontcfginfo.name;
      typeless value = fontcfginfo.value;
      if (allow_element(value)) {
         if (value==CFG_STATUS) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_STATUS_FONT)) {
               _ctl_element_tree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            }
         } else if (value==CFG_CMDLINE) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT)) {
               _ctl_element_tree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            }
         } else if (value==CFG_DOCUMENT_TABS) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT)) {
               _ctl_element_tree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            }
         } else {
            _ctl_element_tree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
         }
      }
   }
}

void _ctl_element_tree.on_change(int reason, int index)
{
   if (reason == CHANGE_SELECTED) {
      if (index <= 0 || !CHANGING_ELEMENT_LIST()) return;

      // did the old one just get selected again?
      newFontElement := _TreeGetCaption(index);
      if (newFontElement == CURRENT_FONT_ELEMENT()) return;

      // save any changes made to the current item
      if (saveCurrentFontSettings()) {
         // failed, select the old one again
         CHANGING_ELEMENT_LIST(1);
         oldIndex := _ctl_element_tree._TreeSearch(TREE_ROOT_INDEX, CURRENT_FONT_ELEMENT());
         if (index > 0) {
            _ctl_element_tree._TreeSetCurIndex(oldIndex);
         }
         CHANGING_ELEMENT_LIST(0);
         return;
      }

      // update the current font name
      CURRENT_FONT_ELEMENT(newFontElement);

      // show the font and size
      showFontForElement(CURRENT_FONT_ELEMENT());

      // update options help
      ctl_element_desc.p_caption = elementIdToDesc(gfontsettings:[CURRENT_FONT_ELEMENT()].id);
   }
}

static int saveCurrentFontSettings(bool quiet=false)
{
   // retrieve from our var, in case it has been changed in the tree
   fontName := CURRENT_FONT_ELEMENT();
   //say('save fontName='fontName);
   if (fontName != '') {
      result := _font_get_result(quiet);
      //say('save result='result);
      if (result == '') return 1;

      gfontsettings:[fontName].info = result;
   }

   return 0;
}

void _font_config_form.on_resize()
{
   pad := _ctl_element_tree.p_x;

   widthDiff := p_width - (ctlframe1.p_x_extent + pad);
   heightDiff := p_height - (ctlAntiAliasing.p_y_extent + pad);

   if (widthDiff) {
      // put half of this space into the element list and half into the font list
      widthDiff = widthDiff intdiv 2;
      _ctl_element_tree.p_width += widthDiff;
      ctl_element_desc.p_width = _ctl_element_tree.p_width;
      ctlframe1.p_x += widthDiff;
      ctlframe1.p_width += widthDiff;

      _font_name_list.p_width += widthDiff;
      _size_label.p_x += widthDiff;
      _font_size_list.p_x += widthDiff;
      _style_frame.p_x += widthDiff;
      _sample_frame.p_width += widthDiff;
      picture1.p_width += widthDiff;
      _sample_text.p_width += widthDiff;

      // align with the left of the font list
      // do it this way b/c of variations in font size
      ctlfixedfonts.p_x = _font_name_list.p_x_extent - ctlfixedfonts.p_width;
   }

   if (heightDiff) {
      _ctl_element_tree.p_height += heightDiff;
      ctlframe1.p_height += heightDiff;
      _font_name_list.p_height += heightDiff;
      _sample_frame.p_y += heightDiff;

      ctlEnableBoldAndItalic.p_y += heightDiff;
      ctlAntiAliasing.p_y += heightDiff;
      ctl_element_desc.p_y += heightDiff;
   }
}

_control _font_name_list;
_control _font_size_list;

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

_ctl_ok.lbutton_up()
{
   if (_font_config_form_apply()) {
      p_active_form._delete_window(0);
   } else {
      return('');
   }
}

static void showFontForElement(_str element)
{
   // we may need to show or disable fixed fonts, depending on our element
   disable_fixedfonts := 0;
   show_fixedfonts := 0;

   // get the font info, based on the element name
   font_options := "";
   _str font_id=gfontsettings:[element].id;
   _str font=gfontsettings:[element].info;

   // show fixed fonts?
   if( font_id==CFG_SBCS_DBCS_SOURCE_WINDOW || 
       font_id==CFG_SBCS_DBCS_MINIMAP_WINDOW || 
       font_id==CFG_HEX_SOURCE_WINDOW || 
       font_id==CFG_UNICODE_SOURCE_WINDOW || 
       font_id==CFG_UNICODE_MINIMAP_WINDOW || 
       font_id==CFG_FILE_MANAGER_WINDOW || 
       font_id==CFG_DIFF_EDITOR_WINDOW || 
       font_id==CFG_UNICODE_DIFF_EDITOR_WINDOW || 
       font_id==CFG_FUNCTION_HELP_FIXED ||
       font_id==CFG_MINIHTML_FIXED) {
      show_fixedfonts=1;
   }

   // Disable fixed fonts option?
   if( disable_fixedfonts ) {
      ctlfixedfonts.p_enabled=false;
      ctlEnableBoldAndItalic.p_enabled = false;
   }

   // Show only fixed fonts?
   if( show_fixedfonts ) {
      font_options :+= 'f';
      ctlfixedfonts.p_value=1;
      ctlEnableBoldAndItalic.p_enabled = true;
   } else {
      ctlfixedfonts.p_value=0;
      ctlEnableBoldAndItalic.p_enabled = false;
   }

   typeless font_name,font_size,font_style,charset;
   parse font with font_name ',' font_size ',' font_style ',' charset',';

   // Disallow ON_CHANGE events on _font_name_list and _font_size_list
   FONTCFG_CHANGING_NAME_LIST(0);
   FONTCFG_CHANGING_SIZE_LIST(0);

   if (font_id==CFG_SBCS_DBCS_MINIMAP_WINDOW || font_id==CFG_UNICODE_MINIMAP_WINDOW) {
      ctlfixedfonts.p_user=1;
      FONTCFGINFO cfg;
      foreach (auto i => cfg in gfontcfglist) {
         if (font_id==CFG_SBCS_DBCS_MINIMAP_WINDOW && cfg.value==CFG_SBCS_DBCS_SOURCE_WINDOW) {
            break;
         } else if (font_id==CFG_UNICODE_MINIMAP_WINDOW && cfg.value==CFG_UNICODE_SOURCE_WINDOW) {
            break;
         }
      }
      if (i<gfontcfglist._length()) {
         typeless font_name2;
         parse gfontsettings:[gfontcfglist[i].name].info with font_name2 ',';
         /*if (font_name=='') {
            font_name=font_name2;
         } */
         //typeless temp_font_size=font_size;
         //_xlat_font(font_name2,temp_font_size);
         _sample_text.p_user=font_name2;
      } else {
         _sample_text.p_user='';
      }
      _style_frame.p_enabled=false;
      _sample_text.p_font_scalable=true;
   } else {
      ctlfixedfonts.p_user='';
      _sample_text.p_user='';
      _sample_text.p_font_scalable=false;
      _style_frame.p_enabled=true;

   }
   // Set the font in _font_name_list.p_text
   _font_name_list.p_text=font_name;

   // Set the size in _font_size_list.p_text
   _font_size_list.p_text=font_size;
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
   if (_font_name_list._lbfind_and_select_item(font_name) < 0) {
      if (!_font_name_list._lbsearch(font_name)) {
         _font_name_list._lbselect_line();
      } else {
         // Dialog might have auto-restored but this font may not be a fixed font.
         // Must turn that off.
         if (ctlfixedfonts.p_value==1 && font_name!='') {
            ctlfixedfonts.p_value=0;
            ctlfixedfonts.call_event(ctlfixedfonts,LBUTTON_UP);
            if (_font_name_list._lbfind_and_select_item(font_name) < 0) {
               if (!_font_name_list._lbsearch(font_name)) {
                  _font_name_list._lbselect_line();
               }
            }
         }
      }
   }

   FONTCFG_CHANGING_NAME_LIST(1);
   FONTCFG_CHANGING_SIZE_LIST(1);

   /* Call the ON_CHANGE event for _font_name_list so the list of sizes
    * and sample text are updated.
    */
   _font_name_list.call_event(CHANGE_OTHER,_font_name_list,ON_CHANGE,'W');
   _font_size_list.p_text=font_size;

   charsetName := _CharSet2Name(charset);

   parse _font_name_list._lbget_text() with auto from_list_font_name " (";

   // some fonts only have a few sizes available - if the size setting is not
   // in the list, this makes the options look modified when nothing has
   // actually changed
   parse font_name with font_name " (";
   if (fontHasLimitedSizes(font_name)) {
      // see if the value has changed just by being loaded into the form
      if (_font_size_list.p_text != font_size) {
         // Don't modify config here. User didn't set anything.         //_setFont(font_id, font_name, _font_size_list.p_text, font_style);
         gfontsettings:[element].info = gfontsettings:[element].orig_info = font_name','_font_size_list.p_text','font_style','charset',';
      }
   }
}

/**
 * Some fonts have only one size available.
 */
bool fontHasLimitedSizes(_str fontName)
{
   switch (fontName) {
      case VSDEFAULT_MENU_FONT_NAME:
      case VSDEFAULT_MDICHILD_FONT_NAME:
         return true;
         break;
      case VSOEM_FIXED_FONT_NAME:
      case VSANSI_VAR_FONT_NAME:
      case VSANSI_FIXED_FONT_NAME:
      case VSDEFAULT_UNICODE_FONT_NAME:
      case VSDEFAULT_FIXED_FONT_NAME:
      case VSDEFAULT_DIALOG_FONT_NAME:
      case VSDEFAULT_COMMAND_LINE_FONT_NAME:
         return _isUnix();
   }

   return false;
}

void setall_wfonts(_str font_name, _str font_size,int font_flags,int charset=VSCHARSET_DEFAULT,int font_id=CFG_SBCS_DBCS_SOURCE_WINDOW)
{
   _change_all_wfonts(font_name,font_size,font_flags,charset,font_id);
}
static bool allow_element(int value) {
   if (value==CFG_MDICHILDTITLE || value==CFG_MENU) {
      return (_isUnix() && !_isMac()) && !_OEM();
   }

   if ((value == CFG_FUNCTION_HELP || value == CFG_FUNCTION_HELP_FIXED) && !_haveContextTagging()) return false;

   return true;
}

static _str elementIdToName(_str id)
{
   FONTCFGINFO cfg;
   foreach (cfg in gfontcfglist) {
      if (id == cfg.value) {
         return cfg.name;
      }
   }

   return '';
}

static _str elementIdToNameId(_str id)
{
   FONTCFGINFO cfg;
   foreach (cfg in gfontcfglist) {
      if (id == cfg.value) {
         return cfg.nameid;
      }
   }

   return '';
}

static _str elementIdToDesc(_str id)
{
   FONTCFGINFO cfg;
   foreach (cfg in gfontcfglist) {
      if (id == cfg.value) {
         return cfg.desc;
      }
   }

   return '';
}
