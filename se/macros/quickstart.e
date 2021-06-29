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
#include "refactor.sh"
#import "alllanguages.e"
#import "beautifier.e"
#import "cjava.e"
#import "clipbd.e"
#import "color.e"
#import "complete.e"
#import "coolfeatures.e"
#import "font.e"
#import "fontcfg.e"
#import "html.e"
#import "listbox.e"
#import "main.e"
#import "math.e"
#import "optionsxml.e"
#import "packs.e"
#import "projconv.e"
#import "refactor.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/color/ColorScheme.e"
#require "se/color/DefaultColorsConfig.e"
#endregion

using se.lang.api.LanguageSettings;
using se.color.DefaultColorsConfig;
using se.color.ColorScheme;

/**
 * Launches the Quick Start dialog.
 */
_command void quick_start() name_info(',')
{
   // see if the options dialog is already open - if so, close it right quick
   wid := getOptionsForm(OP_CONFIG, false);
   if (wid > 0) {
      p_window_id = wid;
   
      // in this case, we have to close this options dialog by cancelling first - hopefully this won't come up often
      cancelBtn := _find_control('_ctl_cancel');
      cancelBtn.call_event(false, cancelBtn, LBUTTON_UP, 'W');
   }

   // do not allow the splash screen to remain on top of quick-start
   _SplashScreenHide();

   show('-modal -mdi _options_tree_form', OP_QUICK_START);
}

/**
 * New Project Wizard.  Helps users pick correct project type when creating a 
 * new project. 
 */
defeventtab _new_project_wizard_form;

static PROJECTPACKS PROJECT_PACKS(...):[] {
   if (arg()) _ctl_tool_chain_combo.p_user=arg(1);
   return _ctl_tool_chain_combo.p_user;
}

void _ctl_go.on_create()
{
   getProjectPacks();

   // populate the languages combo
   _ctl_lang_combo._lbadd_item('C/C++');
   _ctl_lang_combo._lbadd_item('Java');
   _ctl_lang_combo._lbadd_item('C#');
   _ctl_lang_combo._lbadd_item('Visual Basic');
   _ctl_lang_combo._lbadd_item('Other');
   addPacksToCombo(_ctl_lang_combo.p_window_id, 'C\+\+|Java|Microsoft|Generic', true);

   // make the visual studio label invisible at first
   showVisualStudioLabel(false);

   _ctl_launch_proj_wizard.p_value = (int)def_launch_new_project_wizard;

   resetCombos();

   // disable the go button so they can't continue without filling out all the info
   _ctl_go.p_enabled = false;
}

/**
 * Resets the combo boxes on the New Project Wizard to their initial state.  
 */
static void resetCombos()
{
   // the tool chain and project type combos are empty and disabled
   _ctl_tool_chain_combo.p_enabled = false;
   _ctl_proj_type_combo.p_enabled = false;

   _ctl_tool_chain_combo._lbclear();
   _ctl_proj_type_combo._lbclear();

   _ctl_tool_chain_combo.p_text = 'Select tool chain';
   _ctl_proj_type_combo.p_text = 'Select project type';
}

/**
 * Shows the label that tells the user how to use a Visual Studio solution in 
 * SlickEdit.  If we get here, then the user must have indicated that they want 
 * Visual Studio. 
 * 
 * @param show             true to show the label, false to hide it and return 
 *                         the form to the other display
 */
static void showVisualStudioLabel(bool show)
{
   if (show) {
      if (!_ctl_vis_studio_label.p_visible) {
         _ctl_vis_studio_label.p_visible = true;
         _ctl_go.p_y += _ctl_vis_studio_label.p_height;
         _ctl_cancel.p_y += _ctl_vis_studio_label.p_height;
         _ctl_launch_proj_wizard.p_y += _ctl_vis_studio_label.p_height;
         p_active_form.p_height += _ctl_vis_studio_label.p_height;

         _ctl_go.p_caption = 'Open Visual Studio Solution';
         _ctl_go.p_width = 3000;
         _ctl_go.p_x = 1980;
      }
   } else if (_ctl_vis_studio_label.p_visible) {
      _ctl_vis_studio_label.p_visible = false;
      _ctl_go.p_y -= _ctl_vis_studio_label.p_height;
      _ctl_cancel.p_y -= _ctl_vis_studio_label.p_height;
      _ctl_launch_proj_wizard.p_y -= _ctl_vis_studio_label.p_height;
      p_active_form.p_height -= _ctl_vis_studio_label.p_height;

      _ctl_go.p_caption = 'Go';
      _ctl_go.p_width = 1260;
      _ctl_go.p_x = 3720;
   }
}

void _ctl_lang_combo.on_change(int reason)
{
   // use their selection to do stuff
   selectedLang := _ctl_lang_combo.p_text;

   resetCombos();

   switch (selectedLang) {
   case 'C#':
   case 'F#':
   case 'J#':
   case 'Visual Basic':
      // just show them more info and allow them to open a project
      _ctl_go.p_enabled = true;

      showVisualStudioLabel(true);
      break;
   case 'C/C++':

      _ctl_tool_chain_combo._lbadd_item('Microsoft Visual Studio');
      addPacksToCombo(_ctl_tool_chain_combo.p_window_id, 'C\+\+');
      _ctl_tool_chain_combo.p_enabled = true;

      _ctl_go.p_enabled = false;
      showVisualStudioLabel(false);
      break;
   case 'Java':
      _ctl_tool_chain_combo.p_text = 'Java JDK';

      addPacksToCombo(_ctl_proj_type_combo.p_window_id, 'Java');
      _ctl_proj_type_combo.p_enabled = true;

      _ctl_go.p_enabled = false;
      showVisualStudioLabel(false);
      break;
   default:
      _ctl_go.p_enabled = true;

      showVisualStudioLabel(false);
      break;
   }

}

static void addPacksToCombo(int comboWid, _str searchString, bool addNonMatches = false)
{
   callbackIndex := find_index("_oem_new_project_group_callback", PROC_TYPE);

   PROJECTPACKS packs:[] = PROJECT_PACKS();
   foreach (auto packName => . in packs) {

      // First check to see if an OEM has a callback to group these together
      // _oem_new_project_group_callback has to return 1 true if it
      // processed the package name, 0 if this function should process
      // it.
      status := 0;
      if (callbackIndex) status = call_index(packName, callbackIndex);

      match := (pos(searchString, packName, 1, 'IR') != 0);
      if ((match && !addNonMatches) || (!match && addNonMatches)) {
         comboWid._lbadd_item(packName);
      }
   }

   comboWid._lbsort();

}

static void getProjectPacks()
{
   userTemplates :=  _ProjectOpenUserTemplates();
   sysTemplates := _ProjectOpenTemplates();

   PROJECTPACKS p:[];
   p._makeempty();

   GetAllProjectPacks(p, userTemplates, sysTemplates, false);

   PROJECT_PACKS(p);

   _xmlcfg_close(userTemplates);
   _xmlcfg_close(sysTemplates);
}

void _ctl_tool_chain_combo.on_change(int reason)
{
   selectedLang := _ctl_lang_combo.p_text;
   selectedToolChain := _ctl_tool_chain_combo.p_text;
   if (selectedLang == 'C/C++' && selectedToolChain == 'Microsoft Visual Studio') {
      showVisualStudioLabel(true);
   } else showVisualStudioLabel(false);

   _ctl_go.p_enabled = true;
}

void _ctl_proj_type_combo.on_change(int reason)
{
   _ctl_go.p_enabled = true;
}

void _ctl_go.lbutton_up()
{
   def_launch_new_project_wizard = (_ctl_launch_proj_wizard.p_value != 0);

   // see if we are trying to open a visual studio project
   if (_ctl_vis_studio_label.p_visible) {

      wid := p_active_form;
      if (!workspace_open_visualstudio()) {
         // IDIGNORE tells the new project form that we opened a visual studio solution
         wid._delete_window(IDIGNORE);
      }
   } else {
      // save what we did
      if (_ctl_tool_chain_combo.p_enabled) _param1 = _ctl_tool_chain_combo.p_text;
      else if (_ctl_proj_type_combo.p_enabled) _param1 = _ctl_proj_type_combo.p_text;
      else _param1 = _ctl_lang_combo.p_text;

      p_active_form._delete_window(IDOK);
   }

}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);
}

defeventtab _quick_start_colors_form;

static DefaultColorsConfig COLOR_SCHEMES(...) {
   if (arg()) _ctl_color_scheme_list.p_user=arg(1);
   return _ctl_color_scheme_list.p_user;
}
static _str ORIG_COLOR_SCHEME(...) {
   if (arg()) ctl_code_sample.p_user=arg(1);
   return ctl_code_sample.p_user;
}
static bool IN_LIST_ON_CREATE(...) {
   if (arg()) ctl_system_theme.p_user=arg(1);
   return ctl_system_theme.p_user;
}

void _quick_start_colors_form_save_settings()
{
   ORIG_COLOR_SCHEME(ColorScheme.removeProfilePrefix(_ctl_color_scheme_list._lbget_text()));
}

bool _quick_start_colors_form_is_modified()
{
   // Did the app theme change?
   if (_GetDialogInfoHt('orig_app_theme') != _app_theme_auto() ) { 
      return true;
   }

   // did the selected scheme change?
   return (ORIG_COLOR_SCHEME() != ColorScheme.removeProfilePrefix(_ctl_color_scheme_list._lbget_text())); 
}

bool _quick_start_colors_form_validate()
{
   if ( (ORIG_COLOR_SCHEME() == ColorScheme.removeProfilePrefix(_ctl_color_scheme_list._lbget_text())) && 
        _GetDialogInfoHt('orig_app_theme') != _app_theme_auto()  &&
        (ctl_dark_theme.p_value==1 || (ctl_automatic_theme.p_value==1 && strieq(_GetAppThemeForOS(),'Dark')) )) {
      color := _ctl_color_scheme_list._lbget_text();
      if ( substr(color,1,6)=="Light:" ) {
         result := _message_box(nls("You have selected a Dark Application Theme and a Light Color Profile for the editor window\n\nWould you like to select a Dark Color Profile?"),"",MB_YESNO);
         if ( result==IDYES ) {
            _ctl_color_scheme_list._lbtop();
            _ctl_color_scheme_list._lbsearch("Dark: Slate");
            _ctl_color_scheme_list._lbselect_line();
            _ctl_color_scheme_list.call_event(CHANGE_SELECTED,_ctl_color_scheme_list,ON_CHANGE,'W');
            return false;
         }
      }
   }
   return true;
}
bool _quick_start_colors_form_apply()
{
   // we only return true - if there is no callback, then the options
   // will think that the call was unsuccessful
   return true;
}

void _quick_start_colors_form_cancel()
{
   // Reset to original theme
   _app_theme_auto(_GetDialogInfoHt('orig_app_theme'));

   // reset stuff to the original schemes
   applyColorScheme(ORIG_COLOR_SCHEME(), true);
}

void _quick_start_colors_form_restore_state()
{
   // this is really only for quick start
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(se.options.OptionsTree.PURPOSE, form);
   if (purpose == OP_QUICK_START) {
      currentScheme := ColorScheme.getDefaultProfile();
      if (currentScheme != ORIG_COLOR_SCHEME() && currentScheme != ColorScheme.removeProfilePrefix(_ctl_color_scheme_list._lbget_text())) {
         // they've gone and changed things!
         _ctl_color_scheme_list._lbfind_and_select_item(ColorScheme.addProfilePrefix(currentScheme));
         ORIG_COLOR_SCHEME(currentScheme);
      }
  
   }
}

_ctl_color_scheme_list.on_create()
{
   IN_LIST_ON_CREATE(true);
   _str app_theme = _app_theme_auto();
   if (!_isMac()) {
      ctl_automatic_theme.p_visible=false;
      app_theme = _default_option(VSOPTIONZ_APP_THEME);
   }
   _SetDialogInfoHt('orig_app_theme', app_theme);
   switch ( app_theme ) {
   case 'Dark':
      ctl_dark_theme.p_value = 1;
      break;
   case CONFIG_AUTOMATIC:
      ctl_automatic_theme.p_value = 1;
      break;
   default:
      ctl_system_theme.p_value = 1;
   }

   // fill the color schemes in
   COLOR_SCHEMES(null);
   fillInColorSchemes();
   call_event(CHANGE_OTHER, _ctl_color_scheme_list.p_window_id, ON_CHANGE, "W");
   _ctl_customize_colors_link.p_mouse_pointer = MP_HAND;

   ctl_mode_name._lbaddModeNames();
   ctl_mode_name._lbsort();

   ctl_mode_name.p_text = _LangGetModeName(_Ext2LangId("c"));
   ctl_code_sample.setup_preview_code("cpp"); 
   IN_LIST_ON_CREATE(false);
}

void _quick_start_colors_form.on_resize()
{
   padding := ctl_sample_frame.p_x;

   // calculate the horizontal and vertical adjustments
   adjust_x := p_width  - (ctl_sample_frame.p_x_extent  + padding);
   adjust_y := p_height - (ctl_sample_frame.p_y_extent + padding);
   
   // adjust heights of sample code
   ctl_sample_frame.p_height += adjust_y;
   ctl_code_sample.p_height += adjust_y;

   // adjust width of app theme, sample code
   ctl_app_theme_frame.p_width += adjust_x;
   ctl_sample_frame.p_width += adjust_x;
   ctl_code_sample.p_width += adjust_x;
}

void ctl_system_theme.lbutton_up()
{
   if (IN_LIST_ON_CREATE()) {
      return;
   }
   if ( ctl_system_theme.p_value ) {
      _app_theme_auto('');
   } else if ( ctl_dark_theme.p_value ) {
      _app_theme_auto('Dark');
   } else if ( ctl_automatic_theme.p_value ) {
      _app_theme_auto(CONFIG_AUTOMATIC);
   }
}

/** 
 * Change the mode name for the sample code. 
 */
void ctl_mode_name.on_change(int reason)
{
   switch (reason) {
   case CHANGE_CLINE:
   case CHANGE_CLINE_NOTVIS:
   case CHANGE_SELECTED:
      p_next._SetEditorLanguage(_Modename2LangId(p_text));
      p_next._GenerateSampleColorCode();
      break;
   }
}

void fillInColorSchemes()
{
   se.color.DefaultColorsConfig dcc;
   dcc.loadFromDefaultColors();
   COLOR_SCHEMES(null);

   // get list of schemes
   _ctl_color_scheme_list._lbaddColorSchemeNames(dcc);

   currentScheme:=ColorScheme.getDefaultProfile();
   
   if (_ctl_color_scheme_list._lbfind_and_select_item(ColorScheme.addProfilePrefix(currentScheme))) {
      _ctl_color_scheme_list._lbfind_and_select_item(ColorScheme.addProfilePrefix('Default'));
   }

   COLOR_SCHEMES(dcc);
}

void _ctl_customize_colors_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('Colors', 'N');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

   // we need to refresh this stuff in case they changed anything
   _quick_start_colors_form_restore_state();
}

void _ctl_color_scheme_list.on_change(int reason)
{
   // grab the scheme name
   schemeName := ColorScheme.removeProfilePrefix(_ctl_color_scheme_list._lbget_text());
   applyColorScheme(schemeName);
}

static void applyColorScheme(_str schemeName, bool applySymbolColors = true)
{
   DefaultColorsConfig dcc;
   dcc = COLOR_SCHEMES();
   if (dcc == null) return;
   scm:=dcc.loadProfile(schemeName);

   scm->applyColorScheme();

   if (applySymbolColors && scm->m_symbolColoringSchemeName != null) {
      if (scm->m_symbolColoringSchemeName != "" && scm->m_symbolColoringSchemeName != CONFIG_AUTOMATIC) {
         scm->applySymbolColorScheme();
      } else {
         localScheme := *scm;
         localScheme.m_symbolColoringSchemeName = "";
         localScheme.applySymbolColorScheme();
      }
   }
}

defeventtab _quick_start_fonts_form;

static _str ORIG_FONT_NAME_UNICODE(...) {
   if (arg()) _ctl_font_name_list_unicode.p_user=arg(1);
   return _ctl_font_name_list_unicode.p_user;
}
static _str ORIG_FONT_SIZE_UNICODE(...) {
   if (arg()) _ctl_font_size_list_unicode.p_user=arg(1);
   return _ctl_font_size_list_unicode.p_user;
}
static _str ORIG_FONT_NAME_NON_UNICODE(...) {
   if (arg()) _ctl_font_name_list_non_unicode.p_user=arg(1);
   return _ctl_font_name_list_non_unicode.p_user;
}
static _str ORIG_FONT_SIZE_NON_UNICODE(...) {
   if (arg()) _ctl_font_size_list_non_unicode.p_user=arg(1);
   return _ctl_font_size_list_non_unicode.p_user;
}

bool _quick_start_fonts_form_is_modified()
{
   return (_ctl_font_name_list_unicode.get_font_name_from_list() != ORIG_FONT_NAME_UNICODE() ||
           _ctl_font_size_list_unicode.p_text != ORIG_FONT_SIZE_UNICODE() ||
           _ctl_font_name_list_non_unicode.get_font_name_from_list() != ORIG_FONT_NAME_NON_UNICODE() ||
           _ctl_font_size_list_non_unicode.p_text != ORIG_FONT_SIZE_NON_UNICODE() ||
           ctlminimap.p_value!=2);
}

bool _quick_start_fonts_form_apply()
{
   typeless font, fontSize, fontFlags, charSet;
   fontInfo := _default_font(CFG_UNICODE_SOURCE_WINDOW);
   parse fontInfo with font','fontSize','fontFlags','charSet',';
   font = _ctl_font_name_list_unicode.get_font_name_from_list();
   fontSize = _ctl_font_size_list_unicode.p_text;
   setall_wfonts(font, fontSize, fontFlags, charSet, CFG_UNICODE_SOURCE_WINDOW);

   fontInfo = _default_font(CFG_SBCS_DBCS_SOURCE_WINDOW);
   parse fontInfo with font','fontSize','fontFlags','charSet',';
   font = _ctl_font_name_list_non_unicode.get_font_name_from_list();
   fontSize = _ctl_font_size_list_non_unicode.p_text;
   setall_wfonts(font, fontSize, fontFlags, charSet, CFG_SBCS_DBCS_SOURCE_WINDOW);
   if (ctlminimap.p_value!=2) {
      setOptionForAllLanguages('ShowMinimap', ctlminimap.p_value);
      AllLanguagesSetting settings:[];
      AllLanguagesSetting als;
      als.Value = ctlminimap.p_value;
      als.Exclusions='';
      settings:[SHOW_MINIMAP_UPDATE_KEY] = als;
      _update_buffers_for_all_languages(settings);
   }

   return true;
}

void _quick_start_fonts_form_restore_state()
{
   // this is really only for quick start
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(se.options.OptionsTree.PURPOSE, form);
   if (purpose == OP_QUICK_START) {
      // get the values again
      _str font, fontSize;
      fontInfo := _default_font(CFG_UNICODE_SOURCE_WINDOW);
      parse fontInfo with font','fontSize',' .;

      if (ORIG_FONT_NAME_UNICODE() != font) {
         // load up the new font and size, because they've changed things
         _ctl_font_size_list_unicode._cbset_text(fontSize);
         fillInFonts(_ctl_font_name_list_unicode.p_window_id, font);

         ORIG_FONT_NAME_UNICODE(font);
         ORIG_FONT_SIZE_UNICODE(fontSize);
      } else if (ORIG_FONT_SIZE_UNICODE() != fontSize) {
         // just load up the size
         _ctl_font_size_list_unicode._cbset_text(fontSize);
         ORIG_FONT_SIZE_UNICODE(fontSize);
      }


      fontInfo = _default_font(CFG_SBCS_DBCS_SOURCE_WINDOW);
      parse fontInfo with font','fontSize',' .;

      if (ORIG_FONT_NAME_NON_UNICODE() != font) {
         // load up the new font and size, because they've changed things
         _ctl_font_size_list_non_unicode._cbset_text(fontSize);
         fillInFonts(_ctl_font_name_list_non_unicode.p_window_id, font);

         ORIG_FONT_NAME_NON_UNICODE(font);
         ORIG_FONT_SIZE_NON_UNICODE(fontSize);
      } else if (ORIG_FONT_SIZE_NON_UNICODE() != fontSize) {
         _ctl_font_size_list_non_unicode._cbset_text(fontSize);
         ORIG_FONT_SIZE_NON_UNICODE(fontSize);
      }
   }
}

static void setup_preview_code(_str ext="cpp")
{
   top(); up();
   p_buf_name = ".":+ext;
   _SetEditorLanguage(_Ext2LangId(ext));
   _GenerateSampleColorCode();
   p_undo_steps=0;
}

void _ctl_font_name_list_non_unicode.on_create()
{

   bool show_minimap;
   show_minimap= _LangGetPropertyInt32(ALL_LANGUAGES_ID,VSLANGPROPNAME_SHOW_MINIMAP,0)!=0;
   // set up mode names for sample code preview
   ctl_non_unicode_mode_name._lbaddModeNames();
   ctl_non_unicode_mode_name._lbsort();
   ctl_non_unicode_mode_name._lbfind_and_select_item(_LangGetModeName('c'));
   show_minimap= _LangGetPropertyInt32("c",VSLANGPROPNAME_SHOW_MINIMAP,0)!=0;
   if (show_minimap) {
      _ctl_preview_non_unicode.p_window_flags|=VSWFLAG_SHOW_MINIMAP;
   }

   ctl_unicode_mode_name._lbaddModeNames();
   ctl_unicode_mode_name._lbsort();
   ctl_unicode_mode_name._lbfind_and_select_item(_LangGetModeName("html"));
   if (show_minimap) {
      _ctl_preview_unicode.p_window_flags|=VSWFLAG_SHOW_MINIMAP;
   }

   // put the preview text into the editors
   _ctl_preview_non_unicode.setup_preview_code("cpp");
   _ctl_preview_unicode.setup_preview_code("html");
 
   // fill in the fonts and sizes...
   _str font, fontSize;
   fontInfo := _default_font(CFG_UNICODE_SOURCE_WINDOW);
   parse fontInfo with font','fontSize',' .;

   ORIG_FONT_NAME_UNICODE(font);
   ORIG_FONT_SIZE_UNICODE(fontSize);

   fillInFonts(_ctl_font_name_list_unicode.p_window_id, font);
   _ctl_font_size_list_unicode._cbset_text(fontSize);

   fontInfo = _default_font(CFG_SBCS_DBCS_SOURCE_WINDOW);
   parse fontInfo with font','fontSize',' .;

   ORIG_FONT_NAME_NON_UNICODE(font);
   ORIG_FONT_SIZE_NON_UNICODE(fontSize);

   fillInFonts(_ctl_font_name_list_non_unicode.p_window_id, font);
   _ctl_font_size_list_non_unicode._cbset_text(fontSize);
   
   // set the mouse overs for the link
   _ctl_customize_fonts_link.p_mouse_pointer = MP_HAND;
}

void _quick_start_fonts_form.on_resize()
{
   // calculate the horizontal and vertical adjustments
   adjust_x := p_width - (ctl_unicode_frame.p_x_extent  + ctl_unicode_frame.p_x);
   adjust_y := p_height - (ctl_unicode_frame.p_y_extent + _ctl_customize_fonts_link.p_y);

   // adjust frames first
   adjust_y = adjust_y intdiv 2;
   ctl_non_unicode_frame.p_height += adjust_y;
   ctl_unicode_frame.p_height += adjust_y;
   ctl_unicode_frame.p_y += adjust_y;
   ctl_non_unicode_frame.p_width += adjust_x;
   ctl_unicode_frame.p_width += adjust_x;

   // adjust heights of sample code, etc
   _ctl_preview_non_unicode.p_height += adjust_y;
   _ctl_preview_unicode.p_height += adjust_y;

   _ctl_font_name_list_unicode.p_height += adjust_y;
   ctllabel2.p_y += adjust_y;
   _ctl_font_size_list_unicode.p_y += adjust_y;

   _ctl_font_name_list_non_unicode.p_height += adjust_y;
   ctllabel4.p_y += adjust_y;
   _ctl_font_size_list_non_unicode.p_y += adjust_y;

   // adjust width of sample code
   _ctl_preview_non_unicode.p_width += adjust_x;
   _ctl_preview_unicode.p_width += adjust_x;
   _ctl_customize_fonts_link.p_x += adjust_x;
}

void ctlminimap.lbutton_up() {
   bool show_minimap;
   show_minimap= _LangGetPropertyInt32(ALL_LANGUAGES_ID,VSLANGPROPNAME_SHOW_MINIMAP,0)!=0;
   if (p_value==1) {
      show_minimap=true;
   }  else if (p_value==0) {
      show_minimap=false;
   }
   if (show_minimap) {
      _ctl_preview_unicode.p_window_flags|=VSWFLAG_SHOW_MINIMAP;
      _ctl_preview_non_unicode.p_window_flags|=VSWFLAG_SHOW_MINIMAP;
   }  else {
      _ctl_preview_unicode.p_window_flags&=~VSWFLAG_SHOW_MINIMAP;
      _ctl_preview_non_unicode.p_window_flags&=~VSWFLAG_SHOW_MINIMAP;
   }

}


static void fillInFonts(int fontNameList, _str fontName)
{
   fontNameList.p_redraw = false;
   fontNameList.p_picture = 0;

   first_time := !fontNameList.p_Noflines;
   fontNameList._lbclear();

   orig_wid := p_window_id;
   p_window_id = fontNameList.p_window_id;
   fontNameList._insert_font_list('S'); //Put names of fonts in list box

   if (fontName == '') {
      fontNameList._lbsort('i');
      fontNameList.p_line = 1;
      fontName = fontNameList._lbget_text();
      fontNameList.p_text = fontName;
   } else {
      fontNameList._lbsort('i');
   }
   
   fontNameList._lbremove_duplicates('i');
   old_line := fontNameList.p_line;
   
   top();
   up();
   for (;;) {
      if(down()) break;
      name := _lbget_text();
      
      if (_isUnix()) {
         _lbset_item(name);
      } else {
         ft := _font_type(name);
         picture := 0;
         if (ft & TRUETYPE_FONTTYPE) picture = _pic_tt;
         else if(ft & DEVICE_FONTTYPE) picture = _pic_printer;

         _lbset_item(name, 60, picture);
      }
   }
   
   p_after_pic_indent_x = 80;
   p_line = old_line;

   if (_isUnix()) {
      p_picture = 0;
   } else {
      p_picture = _pic_tt;
   }

   fontNameList.p_redraw=true;
   p_window_id=orig_wid;

   if (first_time) fontNameList.p_auto_size = true;

   fontNameList.p_line = 1;
   if (strieq(fontName, "Courier")) {
      // if it's not in the list, use Courier New
      if (fontNameList._lbfind_item(fontName) <= 0) {
         fontName = "Courier New";
      }
   }

   // Select the font name in the combo box text box in the list box.
   if (fontNameList._lbfind_and_select_item(fontName) < 0) {
      // try again with prefix match
      if (!fontNameList._lbsearch(fontName)) {
         fontNameList._lbselect_line();
         fontNameList.p_text = fontNameList._lbget_seltext();
      }
   }
   
   p_window_id = orig_wid;
}


void _ctl_customize_fonts_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('Fonts', 'N');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

   // we need to refresh this stuff in case they changed anything
   _quick_start_fonts_form_restore_state();
}

void _ctl_font_size_list_unicode.on_change(int reason)
{
   height := _ctl_preview_unicode.p_height;
   fontSizeChanged(_ctl_font_name_list_unicode, _ctl_font_size_list_unicode, _ctl_preview_unicode);
   _ctl_preview_unicode.p_height = height;
}

void _ctl_font_name_list_unicode.on_change(int reason)
{
   height := _ctl_preview_unicode.p_height;
   fontNameChanged(_ctl_font_name_list_unicode, _ctl_font_size_list_unicode, _ctl_preview_unicode);
   _ctl_preview_unicode.p_height = height;
}

void _ctl_font_size_list_non_unicode.on_change(int reason)
{
   height := _ctl_preview_non_unicode.p_height;
   fontSizeChanged(_ctl_font_name_list_non_unicode, _ctl_font_size_list_non_unicode, _ctl_preview_non_unicode);
   _ctl_preview_non_unicode.p_height = height;
}

void _ctl_font_name_list_non_unicode.on_change(int reason)
{
   height := _ctl_preview_non_unicode.p_height;
   fontNameChanged(_ctl_font_name_list_non_unicode, _ctl_font_size_list_non_unicode, _ctl_preview_non_unicode);
   _ctl_preview_non_unicode.p_height = height;
}

static void fontNameChanged(int fontNameList, int fontSizeList, int preview)
{
   
   // update the preview
   font_name := fontNameList.get_font_name_from_list();
   preview.p_font_name = font_name;

   updateSizes(fontSizeList, font_name);
   
   if (isinteger(fontSizeList.p_text)) {
      preview.p_font_size = fontSizeList.p_text;
   }

   
   linenum := fontSizeList.p_line;
   fontSizeList.top();
   fontSizeList.p_line = linenum;
}

static void updateSizes(int fontSizeList, _str fontName) 
{
   old_size := fontSizeList.p_text;
   _str list = FONT_SIZE_LIST;
   fontSizeList._lbclear();

   //special_case_terminal := (lowcase(font_name)=='terminal' && !__UNIX__);
   if (_isscalable_font(fontName, 'S')) {
       for (;;) {
          ls := "";
          parse list with ls list;
          if (ls == '') {
             break;
          }
          fontSizeList._lbadd_item(ls);
       }

       fontSizeList.p_line = 1;
       fontSizeList._lbsort('-n');
   }else{
       old_wid := p_window_id;
       p_window_id = fontSizeList;
       _insert_font_list('S', fontName);
       _lbsort('-n');
       top();
       _lbdeselect_line();
       _lbremove_duplicates('n');
       p_window_id = old_wid;
   }

   old_wid := p_window_id;
   p_window_id=fontSizeList;
   if(_lbfind_and_select_item(old_size) < 0){
      p_line = 1;
   }
   p_window_id = old_wid;

}

static void fontSizeChanged(int fontNameList, int fontSizeList, int preview)
{
   if (_isscalable_font(fontNameList.get_font_name_from_list(), 'S')) {
      if (isinteger(fontSizeList.p_text)) {
         preview.p_font_size = fontSizeList.p_text;
      }
   } else {
      new_size := fontSizeList.p_text;
      preview.p_font_size = new_size;
   }
}

defeventtab _quick_start_coding_form;

bool _quick_start_coding_form_is_modified()
{
   return (_ctl_line_numbers.p_value != 2 || _ctl_syntax_expansion.p_value != 2 || 
           _ctl_indent_check.p_value || _ctl_brace_check.p_value );
}

void _quick_start_coding_form_apply()
{
   _str excludedLangIDs[];
   AllLanguagesSetting als;
   AllLanguagesSetting settings:[];

   setBraces := (_ctl_brace_check.p_value != 0);
   setIndent := (_ctl_indent_check.p_value != 0);

   // set syntax expansion for everything
   if (_ctl_syntax_expansion.p_value != 2) {
      // determine if this setting is protected for any language
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('Indent > Syntax Expansion', excludedLangIDs);
      exclusions := join(excludedLangIDs, ',');
      setOptionForAllLanguages('SyntaxExpansion', (_ctl_syntax_expansion.p_value != 0), exclusions);
   }
   
   // set brace style for everything (it doesn't apply to everything, 
   // but the LanguageSettings API will take care of that)
   if (setBraces) {
      braceStyle := 0;
      switch (_ctl_brace_style.p_text) {
      case CBV_SAMELINE:
         braceStyle = BES_BEGIN_END_STYLE_1;
         break;
      case CBV_NEXTLINE:
         braceStyle = BES_BEGIN_END_STYLE_2;
         break;
      case CBV_NEXTLINE_IN:
         braceStyle = BES_BEGIN_END_STYLE_3;
         break;
      }
//    if (_style0.p_value) {
//       braceStyle = BES_BEGIN_END_STYLE_1;
//    } else if (_style1.p_value) {
//       braceStyle = BES_BEGIN_END_STYLE_2;
//    } else {
//       braceStyle = BES_BEGIN_END_STYLE_3;
//    }
      // determine if this setting is protected for any language
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('Begin/End Style', excludedLangIDs);
      getExcludedLanguages('isLangExcludedFromAllLangsBraceStyle', excludedLangIDs);
      exclusions := join(excludedLangIDs, ',');
      setOptionForAllLanguages('BeginEndStyle', braceStyle, exclusions);

      // add something for updating buffers
      als.Value = braceStyle;
      als.Exclusions = exclusions;
      settings:[BEGIN_END_STYLE_UPDATE_KEY] = als;
   }
   
   if (setIndent) {

      // set indent with tabs or spaces
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('Indent > Indent with Tabs', excludedLangIDs);
      getExcludedLanguages('isLangExcludedFromAllLangsIndentWithTabs', excludedLangIDs);
      exclusions := join(excludedLangIDs, ',');
      indentWithTabs := (_ctl_indent_tabs.p_value != 0);
      setOptionForAllLanguages('IndentWithTabs', indentWithTabs,exclusions);

      // add something for updating buffers
      als.Value = (int)(_ctl_indent_tabs.p_value != 0);
      als.Exclusions = exclusions;
      settings:[INDENT_WITH_TABS_UPDATE_KEY] = als;
      
      // set the indent amount
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('Indent > Syntax Indent', excludedLangIDs);
      getExcludedLanguages('isLangExcludedFromAllLangsSyntaxIndent', excludedLangIDs);
      exclusions = "fundamental," :+ join(excludedLangIDs, ',');
      setOptionForAllLanguages('SyntaxIndent', _indent_amount.p_text,exclusions);
      
      // add something for updating buffers
      als.Value = _indent_amount.p_text;
      als.Exclusions = exclusions;
      settings:[SYNTAX_INDENT_UPDATE_KEY] = als;

      // set the tabs now
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('Indent > Tabs', excludedLangIDs);
      getExcludedLanguages('isLangExcludedFromAllLangsTabs', excludedLangIDs);
      exclusions = join(excludedLangIDs, ',');
      setOptionForAllLanguages('Tabs', _tab_size.p_text,exclusions);

      // add something for updating buffers
      als.Value = _tab_size.p_text;
      als.Exclusions = exclusions;
      settings:[TABS_UPDATE_KEY] = als;
   }

   // set line numbers for all languages
   if (_ctl_line_numbers.p_value != 2) {
      // determine if this setting is protected for any language
      excludedLangIDs._makeempty();
      getLanguagesWithOptionProtected('View > Line numbers on', excludedLangIDs);
      exclusions := 'cob,mak,' :+ join(excludedLangIDs, ',');
      if (_ctl_line_numbers.p_value) {
         setOptionForAllLanguages('LineNumbersFlags', LNF_ON | LNF_AUTOMATIC, exclusions);
      } else {
         setOptionForAllLanguages('LineNumbersFlags', LNF_AUTOMATIC, exclusions);
      }

      // add something for updating buffers
      als.Value = _ctl_line_numbers.p_value ? (LNF_ON | LNF_AUTOMATIC) : LNF_AUTOMATIC;
      als.Exclusions = exclusions;
      settings:[LINE_NUMBERS_FLAGS_UPDATE_KEY] = als;
   }
   
   if (settings._length()) {
      _update_buffers_for_all_languages(settings);
   }

}

void _quick_start_coding_form.on_resize()
{
   // a little padding
   padding := _ctl_divider1.p_x;
   widthDiff := p_width - (_ctl_divider1.p_width + 2 * padding);

   if (widthDiff) {

      // dividers
      _ctl_divider1.p_width += widthDiff;
      _ctl_divider2.p_width = _ctl_divider3.p_width = _ctl_divider1.p_width;

      // indent frame changes
      _ctl_indent_label.p_width += widthDiff;
      _ctl_customize_indent_link.p_x += widthDiff;

      // brace style frame changes
      _ctl_brace_label.p_width += widthDiff;
      _ctl_customize_brace_style_link.p_x += widthDiff;

      // syntax expansion frame changes
      _ctl_expansion_label.p_width += widthDiff;
      _ctl_customize_syntax_expansion_link.p_x += widthDiff;

      // line numbers
      _ctl_customize_line_numbers_link.p_x += widthDiff;
   }
}

void _ctl_indent_tabs.on_create()
{
   // syntax expansion & line numbers - set to gray
   _ctl_syntax_expansion.p_value = 2;
   _ctl_line_numbers.p_value = 2;
   
   // brace style
   _ctl_brace_style._lbadd_item(CBV_SAMELINE);
   _ctl_brace_style._lbadd_item(CBV_NEXTLINE);
   _ctl_brace_style._lbadd_item(CBV_NEXTLINE_IN);
   _brace_style_example._use_source_window_font();
   braceStyle := getMostCommonLanguageSettingForAllLanguages('BeginEndStyle');
   switch(braceStyle) {
   case BES_BEGIN_END_STYLE_1:
      _ctl_brace_style._lbfind_and_select_item(CBV_SAMELINE);
      break;
   case BES_BEGIN_END_STYLE_2:
      _ctl_brace_style._lbfind_and_select_item(CBV_NEXTLINE);
      break;
   case BES_BEGIN_END_STYLE_3:
      _ctl_brace_style._lbfind_and_select_item(CBV_NEXTLINE_IN);
      break;
   }
   
   // set indent with tabs or spaces
   indentWithTabs := getMostCommonLanguageSettingForAllLanguages('IndentWithTabs');
   if (indentWithTabs) _ctl_indent_tabs.p_value = 1;
   else _ctl_indent_spaces.p_value = 1;
   
   // set the indent amount
   _indent_amount.p_text = getMostCommonLanguageSettingForAllLanguages('SyntaxIndent');

   // set the tabs now
   _tab_size.p_text = getMostCommonLanguageSettingForAllLanguages('Tabs');

   _ctl_customize_indent_link.p_mouse_pointer = MP_HAND;
   _ctl_customize_brace_style_link.p_mouse_pointer = MP_HAND;
   _ctl_customize_syntax_expansion_link.p_mouse_pointer = MP_HAND;

   // make sure these line up nicely
   rightAlign := _ctl_indent_label.p_x_extent;
   _ctl_customize_indent_link.p_x = rightAlign - _ctl_customize_indent_link.p_width;
   _ctl_customize_brace_style_link.p_x = rightAlign - _ctl_customize_brace_style_link.p_width;
   _ctl_customize_syntax_expansion_link.p_x = rightAlign - _ctl_customize_syntax_expansion_link.p_width;
   _ctl_customize_line_numbers_link.p_x = rightAlign - _ctl_customize_line_numbers_link.p_width;

   call_event(_ctl_indent_check.p_window_id, LBUTTON_UP);
   call_event(_ctl_brace_check.p_window_id, LBUTTON_UP);

   // line numbers...
   _ctl_customize_line_numbers_link.p_mouse_pointer = MP_HAND;
}

void _ctl_indent_check.lbutton_up()
{
   _ctl_indent_spaces.p_enabled = _ctl_indent_tabs.p_enabled = _indent_amount.p_enabled =
      _tab_size.p_enabled = (_ctl_indent_check.p_value != 0);
}

void _ctl_brace_check.lbutton_up()
{
// _style0.p_enabled = _style1.p_enabled = _style2.p_enabled = (_ctl_brace_check.p_value != 0);
   _ctl_brace_style.p_enabled = _brace_style_example.p_enabled = (_ctl_brace_check.p_value != 0);
}

void _ctl_customize_indent_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('formatting', 'S');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

}

void _ctl_customize_brace_style_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('brace', 'S');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

}

void _ctl_customize_syntax_expansion_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('syntax expansion', 'S');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

}

void _ctl_customize_line_numbers_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('line numbers', 'S');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

}

void getExcludedLanguages(_str exclusionFunction, _str (&langs)[])
{
   // find the function to determine exclusion
   funIndex := find_index(exclusionFunction, PROC_TYPE);
   if (!funIndex) return;

   // go through all the languages
   _str alllangs[];
   LanguageSettings.getAllLanguageIds(alllangs);
   for (i := 0; i < alllangs._length(); i++) {
     langID := alllangs[i];

     // is it excluded?
     if (call_index(langID, funIndex)) {
        langs[langs._length()] = langID;
     }
   }
}

void setOptionForAllLanguages(_str setting, typeless value, _str exceptions = '')
{
   typeless exception_value_changed:[];
   getIndex := find_index('se.lang.api.LanguageSettings.get'setting, PROC_TYPE);
   _str orig_exception=exceptions;
   for (;;) {
      if (exceptions=='') {
         break;
      }
      parse exceptions with auto langID ',' exceptions;
      if (langID=='') {
         continue;
      }
      cur_value:=call_index(langID,getIndex);
      if (cur_value!=value) {
         exception_value_changed:[langID]=cur_value;
      }
   }
   exceptions=orig_exception;

   setIndex := find_index('se.lang.api.LanguageSettings.set'setting, PROC_TYPE);
   // find the function to set this setting
   call_index(ALL_LANGUAGES_ID, value, setIndex);
   
   // go through all the languages
   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i := 0; i < langs._length(); i++) {
      langID := langs[i];

     // check for exceptions
     if (!pos(','langID',', ','exceptions',')) {
        call_index(langID, value, setIndex);
     } else if (exception_value_changed._indexin(langID)) {
        call_index(langID, exception_value_changed:[langID], setIndex);
     }
   }
}

typeless getMostCommonLanguageSettingForAllLanguages(_str setting, _str exceptions = '')
{
   // find the function to get this setting
   getIndex := find_index('se.lang.api.LanguageSettings.get'setting, PROC_TYPE);
   return getMostCommonValueForAllLanguages(getIndex, exceptions);
}

typeless getMostCommonValueForAllLanguages(int getIndex, _str exceptions)
{
   // we need a tally!
   typeless tally:[];
   
   // go through all the languages
   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i := 0; i < langs._length(); i++) {
      langID := langs[i];

     retVal := call_index(langID, getIndex);
     if (tally._indexin(retVal)) {
        tally:[retVal]++;
     } else {
        tally:[retVal] = 1;
     }
   }
   
   // now go through the tallies and find the most common response
   highestCount := 0;
   highestValue := '';
   typeless value, count;
   foreach (value => count in tally) {
      if (count > highestCount) {
         highestCount = count;
         highestValue = value;
      }
   }
   
   return highestValue;
}

defeventtab _quick_start_setup_project_form;

bool _quick_start_setup_project_form_is_modified()
{
   return false;
}

void _ctl_start_project_wizard.on_create()
{
   // modify text for standard
   if (!_haveBuild()) {
      _ctl_info_html.p_text='Workspaces and projects provide a way to organize your work and allow you to more quickly access your files. If you choose not to set up a project at this time, you can access the New Project Dialog from <b>Project > New</b>.</p>';
   }

   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_ShrinkToFit();
}

void _ctl_start_project_wizard.lbutton_up()
{
   bool nextEnabled, prevEnabled;
   
   wid := p_active_form;
   wid.disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   project_new_maybe_wizard();  

   wid.disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

}

void _quick_start_setup_project_form.on_resize()
{
   // current dimensions
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);

   _ctl_info_html.p_width = width - (2 * _ctl_info_html.p_x);

   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_UseDialogFont();
   _ctl_info_html._minihtml_ShrinkToFit();

   _ctl_start_project_wizard.p_x = (width - _ctl_start_project_wizard.p_width) intdiv 2;
}

defeventtab _quick_start_welcome_form;

bool _quick_start_welcome_form_is_modified()
{
   return false;
}

void _ctl_welcome_label.on_create()
{
   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_UseDialogFont();
   _ctl_info_html._minihtml_ShrinkToFit();

   if (isEclipsePlugin()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_eclipse.ico@128");
      _ctl_info_html.p_text=stranslate(_ctl_info_html.p_text,"Window > SlickEdit Preferences","Tools > Options");
   } else if (_isStandardEdition()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_standard.ico@128");
   } else if (_isCommunityEdition()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_community.ico@128");
   } else {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_profile.ico@128");
   }
}

void _quick_start_welcome_form.on_resize()
{
   // current dimensions
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);

   _ctl_welcome_label.p_x_extent = width ;
   _ctl_info_html.p_x_extent = width ;

   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_ShrinkToFit();
}

defeventtab _quick_start_more_information_form;

bool _quick_start_more_information_form_is_modified()
{
   return false;
}

void _ctl_top_info_html.on_create()
{
   _ctl_top_info_html.p_height *= 2;
   _ctl_export_info_html.p_height *= 2;
   _ctl_other_info_html.p_height *= 2;

   _ctl_top_info_html._minihtml_UseDialogFont();
   _ctl_export_info_html._minihtml_UseDialogFont();
   _ctl_other_info_html._minihtml_UseDialogFont();

   _ctl_top_info_html._minihtml_ShrinkToFit();
   _ctl_export_info_html._minihtml_ShrinkToFit();
   _ctl_other_info_html._minihtml_ShrinkToFit();

   if (isEclipsePlugin()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_eclipse.ico@128");
      _ctl_export_info_html.p_text=stranslate(_ctl_export_info_html.p_text,"Window > SlickEdit Preferences","Tools > Options");
      _ctl_export_info_html.p_text=stranslate(_ctl_export_info_html.p_text,"Preferences","Options");
      _ctl_export_info_html.p_text=stranslate(_ctl_export_info_html.p_text,"preferences","options");
      _ctl_other_info_html.p_text=stranslate(_ctl_other_info_html.p_text,"SlickEdit Cool Features","Cool Features");
   } else if (_isStandardEdition()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_standard.ico@128");
   } else if (_isCommunityEdition()) {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_community.ico@128");
   } else {
      ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_profile.ico@128");
   }
}

void _ctl_top_info_html.on_change(int reason, _str href="")
{
   if ( reason==CHANGE_CLICKED_ON_HTML_LINK ) {
      goto_url(href);
   }
}

void _quick_start_more_information_form.on_resize()
{
   // current dimensions
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);

   // see what changed...
   padding := _ctl_export_frame.p_x;
   widthDiff := width - (_ctl_export_frame.p_width + 2 * padding);

   if (widthDiff) {
   
      _ctl_export_frame.p_width += widthDiff;
      _ctl_other_frame.p_width += widthDiff;
   
      _ctl_top_info_html.p_width = (_ctl_export_frame.p_x_extent) - _ctl_top_info_html.p_x;
      htmlWidth := _ctl_export_frame.p_width - (2 * padding);
      _ctl_export_info_html.p_width = htmlWidth;
      _ctl_other_info_html.p_width = htmlWidth;
   
      _ctl_export.p_x += (widthDiff intdiv 2);
      _ctl_cool_features.p_x += (widthDiff intdiv 2);
      _ctl_release_notes.p_x += (widthDiff intdiv 2);

      _ctl_top_info_html.p_height *=2;
      _ctl_export_info_html.p_height *=2;
      _ctl_other_info_html.p_height *=2;

      _ctl_top_info_html._minihtml_ShrinkToFit();
      _ctl_export_info_html._minihtml_ShrinkToFit();
      _ctl_other_info_html._minihtml_ShrinkToFit();
   }
}

_ctl_export.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_export.p_caption="Export Preferences...";
        _ctl_export.p_width=1800;
    }
}

void _ctl_export.lbutton_up()
{
   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   p_active_form.export_options('-a');

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);
}

void _ctl_cool_features.lbutton_up()
{
   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   cool_features();

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);
}

void _ctl_release_notes.lbutton_up()
{
   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   vsversion('R', true);

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);
}
