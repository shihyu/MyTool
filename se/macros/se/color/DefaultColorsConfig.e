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
#require "se/color/ColorInfo.e"
#require "se/color/ColorScheme.e"
#import "se/color/SymbolColorAnalyzer.e"
#import "se/color/SymbolColorConfig.e"
#import "se/options/OptionsConfigTree.e"
#import "box.e"
#import "c.e"
#import "clipbd.e"
#import "color.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "cfg.e"
#endregion

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * The DefaultColorsConfig class is used to manage the data necessary 
 * for customizing the basic color scheme configuration.  It works closely 
 * with the Colors options dialog. 
 */
class DefaultColorsConfig {

   /**
    * This is the symbol color profile (rule base) which is 
    * currently being edited in the Symbol Coloring options dialog.
    */
   private ColorScheme m_currentProfile;
   /**
    * This is the symbol color profile (rule base) which is 
    * currently being edited in the Symbol Coloring options dialog.
    */
   private ColorScheme m_origProfile;

   /**
    * Has the current symbol coloring profile stored in 
    * m_currentProfile changed or has the currently selected 
    * profile changed. Call profileChanged() to check if just the
    * profile settings changed. 
    */
   private bool m_modified = false;

   /**
    * Temporarily ignore what might appear to be symbol coloring modifications. 
    */
   private bool m_ignoreModifications = false;

   /**
    * This table is used to assign color ID's to each of the the colors 
    * currently being edited in the color form.
    */
   private int m_colorIds[];

   DefaultColorsConfig() {
      m_modified=false;
      m_ignoreModifications=false;
      m_colorIds._makeempty();
   }

   ColorScheme* loadProfile(_str profileName,int optionLevel=0) {
      m_currentProfile.loadProfile(profileName,optionLevel);
      m_origProfile=m_currentProfile;
      m_colorIds._makeempty();
      return &m_currentProfile;
   }
   void resetToOriginal() {
      m_currentProfile=m_origProfile;
      m_colorIds._makeempty();
   }
   /** 
    * @return 
    * Return a pointer to the current color scheme being edited. 
    * This function can not return 'null'. 
    */
   ColorScheme *getCurrentProfile() {
      return &m_currentProfile;
   }

   static bool hasBuiltinProfile(_str profileName) {
      return _plugin_has_builtin_profile(VSCFGPACKAGE_COLOR_PROFILES,profileName);
   }

   /**
    * @return 
    * Return 'true' if the scheme with the given name was added as a system scheme, 
    * but has been modified from its original form by the user. 
    *  
    * @param name    symbol color scheme name 
    */
   bool isModifiedBuiltinProfile() {
      if (!_plugin_has_builtin_profile(VSCFGPACKAGE_COLOR_PROFILES,m_currentProfile.m_name)) {
         return false;
      }
      
      ColorScheme builtin_profile;
      builtin_profile.loadProfile(m_currentProfile.m_name,1);
      return m_currentProfile!=builtin_profile;
   }

   /**
    * @return 
    * Has the current color scheme changed since we started editing it? 
    */
   bool isModified() {
      return m_modified;
   }
   bool profileChanged() {
      return m_currentProfile!=m_origProfile;
   }
   /**
    * Mark the current color scheme as modified or not modified.  This 
    * function will also relay the modification information to the main 
    * options dialog so that it knows that the Colors options panel has
    * unsaved modifications to save. 
    *  
    * @param onoff   'true' for a modification, 'false' if we are resetting modify 
    */
   void setModified(bool onoff=true) {
      if (m_ignoreModifications) return;
      m_modified = onoff;
   }

   /**
    * Temporarily ignore any modfications being made to the color scheme. 
    * This should be used when loading color schemes, to prevent callbacks 
    * that are populating the form from triggering modify callbacks when 
    * on_change() events are generated. 
    *  
    * @param onoff   'true' to ignore modifications, false otherwise. 
    *  
    * @return Returns the original state of ignoring modifications (true/false). 
    */
   void setIgnoreChanges(bool onoff) {
      m_ignoreModifications = onoff;
   }
   /**
    * @return 
    * Return 'true' if we are ignoring modifications temporilary. 
    */
   bool ignoreChanges() {
      return m_ignoreModifications;
   }

   /**
    * Set the color settings displayed in the Colors options dialog to the 
    * options currently in use. 
    */
   ColorScheme *loadFromDefaultColors() {
      m_currentProfile.loadCurrentColorScheme();
      m_origProfile=m_currentProfile;
      return &m_currentProfile;
   }
   /** 
    * @return 
    * Return a color ID, possibly allocated for the given color in 
    * the current scheme.  If a color is allocated, it will be free'd 
    * by this same class. 
    * 
    * @param cfg     CFG_* color constant 
    */
   int getColorIdForCurrentProfile(int cfg) {
      // no scheme, revert to plain text color
      if (m_currentProfile == null) {
         return CFG_WINDOW_TEXT;
      }
      // no such color, revert to plain text color
      ColorInfo *colorInfo = m_currentProfile.getColor(cfg);
      if (colorInfo == null) {
         return CFG_WINDOW_TEXT;
      }
      // no difference from default color, then use default
      if (colorInfo->matchesColor(cfg, &m_currentProfile)) {
         return cfg;
      }
      // allocate a color ID if we need one
      if (m_colorIds._length() <= cfg || m_colorIds[cfg]==null || m_colorIds[cfg] == 0) {
         m_colorIds[cfg] = colorInfo->getColorId(&m_currentProfile);
         return m_colorIds[cfg]; 
      }
      // color hasn't changed since allocated?
      if (!colorInfo->matchesColor(m_colorIds[cfg], &m_currentProfile)) {
         colorInfo->setColor(m_colorIds[cfg], &m_currentProfile);
      }
      // return the allocated color ID
      return m_colorIds[cfg];
   }

};


///////////////////////////////////////////////////////////////////////////
// Switch to the global namespace
//
namespace default;

using se.color.SymbolColorAnalyzer;
using se.color.ColorScheme;
using se.color.DefaultColorsConfig;

/** 
 *  
 */
definit() 
{
}

///////////////////////////////////////////////////////////////////////////
// The following code is used to implement the Colors options dialog.
///////////////////////////////////////////////////////////////////////////

defeventtab _color_form;

/**
 * Get the DefaultColorsConfig class instance, which is stored in 
 * the p_user of the schemes control. 
 * 
 * @return se.color.DefaultColorsConfig* 
 */
static se.color.DefaultColorsConfig *getDefaultColorsConfig()
{
   if (ctl_scheme.p_user instanceof se.color.DefaultColorsConfig) {
      return &ctl_scheme.p_user;
   }
   return null;
}

/**
 * Gets the scheme name that was in place when the user opened the dialog OR the 
 * most recently applied on. 
 * 
 * @return scheme name
 */
static _str getOriginalColorSchemeName()
{
   return ctl_scheme_label.p_user;
}

/**
 * Get the ColorScheme class instance being edited. 
 * It is obtained though the master DefaultColorsConfig object. 
 * 
 * @return se.color.ColorScheme* 
 */
static se.color.ColorScheme *getColorScheme()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return null;
   return dcc->getCurrentProfile();
}

/**
 * Get the current ColorInfo being edited.  It is obtained by looking 
 * at the color name currently selected in the Colors options dialog.
 * 
 * @return se.color.ColorInfo* 
 */
static se.color.ColorInfo *getColorInfo()
{
   scm := getColorScheme();
   if (scm == null) return null;

   index := ctl_rules._TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return null;

   colorId := getColorId();
   if (colorId != null && colorId != "") {
      return scm->getColor(colorId);
   }
   return null;
}

/**
 * Get the current ColorInfo being edited.  It is obtained by looking 
 * at the color name currently selected in the Colors options dialog.
 * 
 * @return se.color.ColorInfo* 
 */
static se.color.ColorInfo *getEmbeddedColorInfo()
{
   scm := getColorScheme();
   if (scm == null) return null;

   colorId := getColorId();
   if (colorId > 0) {
      return scm->getEmbeddedColor(colorId);
   }
   return null;
}

/** 
 * @return 
 * Return the color ID for the current color being edited.  It is obtained by 
 * looking at the color name currently selected in the Colors options dialog. 
 */
static int getColorId()
{
   index := ctl_rules._TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return 0;
   if (ctl_rules._TreeGetDepth(index) <= 1) return 0;
   return ctl_rules._TreeGetUserInfo(index);
}

/**
 * Load all the colors into the tree control pushing them into categories
 */
static void loadAllColorsInTree(se.color.ColorScheme *scm)
{
   // load all the individual colors
   if (scm == null) return;
   ctl_rules._TreeBeginUpdate(TREE_ROOT_INDEX);
   ctl_rules._TreeDelete(TREE_ROOT_INDEX,'c');
   for ( cfg:=1; cfg<=CFG_LAST_DEFAULT_COLOR; cfg++) {
      // for v17, we removed this option
      if (cfg == CFG_STATUS) continue;

      // remove items that don't apply to Standard edition
      if (!_haveBuild() && cfg==CFG_ERROR) continue;
      if (!_haveContextTagging() && cfg==CFG_SYMBOL_HIGHLIGHT) continue;
      if (!_haveDebugging() && cfg==CFG_MODIFIED_ITEM) continue;

      if (scm->getColor(cfg) == null) continue;
      colorName := scm->getColorName(cfg);
      categoryPriority := 0;
      categoryName := scm->getColorCategoryName(cfg,categoryPriority);
      if (colorName == null || categoryName == null) continue;
      categoryNode := ctl_rules._TreeSearch(TREE_ROOT_INDEX, categoryName);
      if (categoryNode <= 0) {
         categoryNode = ctl_rules._TreeAddItem(TREE_ROOT_INDEX, categoryName,
                                               TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED, 
                                               TREENODE_BOLD, categoryPriority);
      }
      if (colorName=="") continue;
      treeIndex := ctl_rules._TreeAddItem(categoryNode, colorName,
                                          TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, cfg);
   }
   ctl_rules._TreeEndUpdate(TREE_ROOT_INDEX);

   // sort items under each category
   ctl_rules._TreeSortUserInfo(TREE_ROOT_INDEX,'N');
   treeIndex := ctl_rules._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (treeIndex > 0) {
      ctl_rules._TreeSortCaption(treeIndex);
      treeIndex = ctl_rules._TreeGetNextSiblingIndex(treeIndex);
   }
   
}

static void loadScheme() 
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := dcc->getCurrentProfile();

   origIgnore := dcc->ignoreChanges();
   dcc->setIgnoreChanges(true);

   // set up the list of compatible color schemes
   ctl_symbol_scheme._lbaddSymbolColoringSchemeNames();
   if (scm != null &&
       scm->m_symbolColoringSchemeName != null && 
       scm->m_symbolColoringSchemeName != "") {
      ctl_symbol_scheme._lbfind_and_select_item(scm->m_symbolColoringSchemeName);
   } else {
      ctl_symbol_scheme.p_text = "(None)";
   }

   // load all the individual colors
   loadAllColorsInTree(scm);

   dcc->setIgnoreChanges(origIgnore);
   dcc->setModified(false);
}

/**
 * Refresh all the information about the currently selected color
 * in the list of color names and descriptions.
 */
static void updateCurrentColor()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (dcc->ignoreChanges()) return;

   color := getColorInfo();
   index := ctl_rules._TreeCurIndex();
   ctl_rules.p_redraw=true;

   scm := dcc->getCurrentProfile();
   if (scm == null) return;
   dcc->setModified(true);
   //schemeName := strip(ctl_scheme.p_text);

   ctl_code_sample.updateSampleCode();
}

/**
 * Update the color coding for the language specific sample code. 
 */
static void updateSampleCode()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (dcc->ignoreChanges()) return;
   scm := dcc->getCurrentProfile();
   if (scm == null) return;

   int colorIds[];
   for (cfg := 0; cfg <= CFG_LAST_DEFAULT_COLOR; cfg++) {
      colorIds[cfg] = 0;
   }

   se.color.ColorInfo *windowText = scm->getColor(CFG_WINDOW_TEXT);
   if (windowText != null) {
      se.color.ColorInfo curWindowText;
      curWindowText.getColor(CFG_WINDOW_TEXT);
      /*
         We either need to do this every profile or never do this. Go 
         ahead and do this for every color profile.
      */
      //if (curWindowText.getBackgroundColor() != windowText->getBackgroundColor()) {
         // TBF:  we don't really want to do this, but until we can have colors
         // per editor control, this is our only workaround.
         scm->applyColorScheme();
         scm->applySymbolColorScheme();
      //}
   }

   save_pos(auto p);
   bottom(); _end_line();

   loop {
      cfg = _clex_find(0, 'D');
      endSeekpos := _QROffset();
      while (p_col > 1 ) {
         left();
         if (_clex_find(0, 'D') != cfg) {
            right();
            break;
         }
      }
      startSeekpos := _QROffset();
      
      if (cfg > 0) {
         colorId := colorIds[cfg];
         if (colorId == null || colorId == 0) {
            colorId = colorIds[cfg] = dcc->getColorIdForCurrentProfile(cfg); 
         }
          
         if (startSeekpos < endSeekpos) {
            _SetTextColor(colorId, (int)(endSeekpos-startSeekpos+1));
         } else {
            _GoToROffset(endSeekpos);
            _SetTextColor(colorId, 1);
         }
      }

      if (p_col == 1) {
         if (p_RLine <= 1 || up()) break;
         _end_line();
      } else {   
         left();
      }
   }
}

/**
 * Change the text in the color selection box depending on whether
 * it is currently enabled or not.  Display slashes when it is
 * disabled, and a message saying to click here when it is enabled.
 */
static void enableColorControl()
{
   inherit := false;
   inherit_checkbox := p_prev;
   while (inherit_checkbox != p_window_id) {
      if (inherit_checkbox.p_object == OI_CHECK_BOX) {
         inherit = (inherit_checkbox.p_visible && inherit_checkbox.p_enabled && inherit_checkbox.p_value != 0);
         break;
      }
      inherit_checkbox = inherit_checkbox.p_prev;
   }

   orig_width := p_width;
   p_forecolor = 0x606060;
   if (inherit) {
      p_caption = "/////////////////////////////";
   } else {
      p_caption = "Click to change color...";
   }
   p_width = orig_width; 
}

/**
 * Load the given color into the Colors dialog. 
 *  
 * @param cfg      color ID 
 * @param color    color specification
 */
static void loadColor(int cfg)
{
   // get the symbol color configuration manager object
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (cfg == 0) {
      enableColorSettings(0);
      return;
   }

   // if they gave us a null color, disable everything, otherwise enable form
   ctl_color_note.p_enabled = true;
   enableColorSettings(cfg);

   // set up the color description
   scm := getColorScheme();
   if (scm == null) return;
   ctl_color_note.p_caption = scm->getColorDescription(cfg);

   // disable all on_change callbacks
   origIgnore := dcc->ignoreChanges();
   dcc->setIgnoreChanges(true);

   // fill in the color information
   color := scm->getColor(cfg);
   if (ctl_system_default.p_enabled) {
      ctl_system_default.p_value = ((color->m_foreground < 0 || color->m_foreground == VSDEFAULT_FOREGROUND_COLOR) && 
                                    (color->m_background < 0 || color->m_background == VSDEFAULT_BACKGROUND_COLOR))? 1:0;
   }

   if (ctl_system_default.p_enabled && ctl_system_default.p_value) {
      _system_default_color_state(true);
   } else {
      ctl_foreground_color.p_backcolor = color->getForegroundColor(scm);
      ctl_background_color.p_backcolor = color->getBackgroundColor(scm);
      ctl_embedded_color.p_backcolor = scm->getEmbeddedBackgroundColor(cfg);
   }

   ctl_background_inherit.p_value = (color->getFontFlags(scm) & F_INHERIT_BG_COLOR)? 1:0;
   ctl_foreground_color.enableColorControl();
   ctl_background_color.enableColorControl();
   ctl_embedded_color.enableColorControl();

   // fill in the font information
   ctl_italic.p_value = (color->getFontFlags(scm) & F_ITALIC)? 1:0;  
   ctl_bold.p_value = (color->getFontFlags(scm) & F_BOLD)? 1:0;  
   ctl_underline.p_value = (color->getFontFlags(scm) & F_UNDERLINE)? 1:0;  
   ctl_strikeout.p_value = (color->getFontFlags(scm) & F_STRIKE_THRU)? 1:0;  
   //ctl_normal.p_value = (color->getFontFlags(scm) & (F_ITALIC|F_BOLD|F_UNDERLINE))? 0:1;
   
   // fill in the sample color display
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;  
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_embedded_sample.p_forecolor = ctl_foreground_color.p_backcolor;  
   ctl_embedded_sample.p_backcolor = ctl_embedded_color.p_backcolor;
   ctl_sample.p_font_bold      = (color->getFontFlags(scm) & F_BOLD) != 0;
   ctl_sample.p_font_italic    = (color->getFontFlags(scm) & F_ITALIC) != 0;
   ctl_sample.p_font_underline = (color->getFontFlags(scm) & F_UNDERLINE) != 0;
   ctl_sample.p_font_strike_thru = (color->getFontFlags(scm) & F_STRIKE_THRU) != 0;
   ctl_embedded_sample.p_font_bold      = ctl_sample.p_font_bold;            
   ctl_embedded_sample.p_font_italic    = ctl_sample.p_font_italic;    
   ctl_embedded_sample.p_font_underline = ctl_sample.p_font_underline;
   ctl_embedded_sample.p_font_strike_thru = ctl_sample.p_font_strike_thru;

   // done, back to business as usual 
   dcc->setIgnoreChanges(origIgnore);
}

/**
 * Load the color scheme names into a combo box 
 *  
 * @param dcc  Color configuration manager object 
 */
void _lbaddColorSchemeNames(se.color.DefaultColorsConfig &dcc)
{
   p_picture = _pic_lbvs;
   p_pic_space_y = 60;
   p_pic_point_scale = 8;
   _str schemeNames[];
   ColorScheme.listProfiles(schemeNames,true);
   name := "";
   _lbclear();
   if (_isMac()) {
      _lbadd_item(CONFIG_AUTOMATIC,60,_pic_lbvs);
   }

   foreach (name in schemeNames) {
      if (DefaultColorsConfig.hasBuiltinProfile(ColorScheme.removeProfilePrefix(name))) {
         _lbadd_item(name,60,_pic_lbvs);
      } else {
         _lbadd_item(name,60,"");
      }
   }
}

/**
 * Initialize the Colors options dialog.
 */
void ctl_code_sample.on_create()
{
   // The symbol color configuration dialog manager object goes
   // in the p_user of 'ctl_scheme'
   ctl_scheme.p_user = null;
   se.color.DefaultColorsConfig dcc;

   // load default schemes and the current symbol coloring scheme
   dcc.loadFromDefaultColors();
   
   // load all the scheme names into the combo box, putting
   // user defined schemes at the top of the list.
   ctl_scheme._lbaddColorSchemeNames(dcc);

   // determine the current scheme, mark it as modified if necessary
   currentSchemeName := ColorScheme.getDefaultProfile();

   ctl_scheme.p_text = ColorScheme.addProfilePrefix(currentSchemeName);
   scm := dcc.loadFromDefaultColors();
   associated_symbol_profile := _plugin_get_property(VSCFGPACKAGE_COLOR_PROFILES,ColorScheme.realProfileName(currentSchemeName),'associated_symbol_profile');

   // symbol coloring relies on context tagging, so if it's gone, no symbol coloring
   if (_haveContextTagging()) {
      // set up the list of compatible color schemes
      ctl_symbol_scheme._lbaddSymbolColoringSchemeNames(ColorScheme.realProfileName(currentSchemeName));
      if (associated_symbol_profile != "") {
         ctl_symbol_scheme.p_text = associated_symbol_profile;
      } else {
         ctl_symbol_scheme.p_text = "(None)";
      }
   } else {
      // just hide everything
      ctl_assoc_label.p_visible = ctl_symbol_scheme.p_visible = ctl_symbol_coloring.p_visible = false;

      // move these down so it doesn't look goofy
      pad := ctl_reset_scheme.p_x - (ctl_save_scheme_as.p_x_extent);
      ctl_save_scheme_as.p_y = ctl_delete_scheme.p_y = ctl_rename_scheme.p_y = ctl_reset_scheme.p_y = ctl_reset_colors.p_y;
      ctl_save_scheme_as.p_x = ctl_scheme_label.p_x;
      ctl_reset_scheme.p_x = ctl_save_scheme_as.p_x_extent + pad;
      ctl_delete_scheme.p_x = ctl_reset_scheme.p_x_extent + pad;
      ctl_rename_scheme.p_x = ctl_delete_scheme.p_x_extent + pad;
      ctl_reset_colors.p_x = ctl_rename_scheme.p_x_extent + pad;

      ctl_scheme.p_width = (ctl_reset_scheme.p_x_extent) - ctl_scheme.p_x;
   }
   
   // load all the individual color names
   loadAllColorsInTree(scm);

   // the small sample text needs to use the editor control font
   ctl_mode_name._lbaddModeNames();
   ctl_mode_name._lbsort();
   ctl_sample._use_edit_font();
   ctl_embedded_sample._use_edit_font();

   mode_name:= _retrieve_value("_color_form.ctl_mode_name");
   if (mode_name!='') {
      if(ctl_mode_name._lbfind_and_select_item(mode_name)) {
         mode_name='';
      }
   }
   if (mode_name=='') mode_name=_LangGetModeName("c");
   ctl_mode_name._lbfind_and_select_item(mode_name);
   ctl_code_sample._SetEditorLanguage(_Modename2LangId(mode_name));
   ctl_code_sample._GenerateSampleColorCode();
   ctl_code_sample.p_undo_steps=0;

   ctl_code_sample.p_window_flags|=OVERRIDE_CURLINE_COLOR_WFLAG;  // Disable curline color
   // finally, load the current symbol coloring scheme into the form 
   ctl_scheme.p_user = dcc;
   loadScheme();
   ctl_code_sample.updateSampleCode();
   ctl_rules._TreeRefresh();

   // select the color under the cursor if we have an MDI editor window
   if (!_no_child_windows()) {
      cfg := _mdi.p_child._clex_find(0, 'D');
      selectColor(cfg);
   } else {
      selectColor(CFG_WINDOW_TEXT);
   }

   updateButtons();
}

/**
 * Cleanup
 */
void _color_form.on_destroy()
{
   _append_retrieve(0, ctl_mode_name.p_text,
                    "_color_form.ctl_mode_name");
   // destroy the config object
   p_user = null;
}

/**
 * Handle form resizing.  Stretches out the color list
 * vertically.  Stretches out kinds and attributes horizontally. 
 * Other items remain in the same relative positions. 
 */
void _color_form.on_resize()
{
   // total size
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(ctl_save_scheme_as.p_width*5, ctl_sample.p_height*9);
   }

   // calculate the horizontal and vertical adjustments
   padding := _dx2lx(SM_TWIP,_lx2dx(SM_TWIP,ctl_rules.p_x));
   adjust_x:=width-_dx2lx(SM_TWIP,_lx2dx(SM_TWIP,ctl_scheme_divider.p_x_extent))-padding;
   //adjust_x:= width-orig_width;
   if (adjust_x<0 && -adjust_x>ctl_rules.p_width) {
      adjust_x=-ctl_rules.p_width;
   }
   if (adjust_x<0 && -adjust_x>ctl_symbol_scheme.p_width) {
      adjust_x=-ctl_symbol_scheme.p_width;
   }

   // adjust the scheme buttons
   if (ctl_symbol_scheme.p_visible) {
      ctl_rename_scheme.p_x += adjust_x;
      ctl_delete_scheme.p_x += adjust_x;
      ctl_reset_scheme.p_x += adjust_x;
      ctl_save_scheme_as.p_x += adjust_x;
      ctl_reset_colors.p_x += adjust_x;
      ctl_scheme.p_width += adjust_x;
   }
   ctl_symbol_scheme.p_width += adjust_x;
   ctl_symbol_coloring.p_x += adjust_x;
   ctl_scheme_divider.p_width += adjust_x;

   // adjust the color and font attribute groups
   ctl_rules.p_width += adjust_x;
   temp:=(height- ctl_rules.p_y);
   if (temp<0) temp=200;
   ctl_rules.p_height = temp;
   ctl_color_note.p_x += adjust_x;
   ctl_system_default.p_x += adjust_x;
   ctl_foreground_frame.p_x += adjust_x;
   ctl_background_frame.p_x += adjust_x;
   ctl_font_frame.p_x += adjust_x;
   ctl_sample.p_x += adjust_x;
   ctl_embedded_sample.p_x += adjust_x;

   // adjust the sample code area
   ctl_sample_frame.p_x += adjust_x;
   temp=(height- ctl_sample_frame.p_y);
   if (temp<0) temp=200;
   ctl_sample_frame.p_height = temp;
   ctl_code_sample.p_y_extent = ctl_sample_frame.p_height - DEFAULT_DIALOG_BORDER;
}

/**
 * Callback for handling the [OK] or [Apply] buttons on the
 * master configuration dialog when the symbol coloring
 * properties are modified and need to be recalculated.
 */
void _color_form_apply()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := dcc->getCurrentProfile();
   if (scm == null) return;

   scm->saveProfile();

   scm->applyColorScheme();
   scm->applySymbolColorScheme();
   scm->insertMacroCode(true);
   _config_modify_flags(CFGMODIFY_DEFVAR);
   dcc->setModified(false);
}

/**
 * Callback for handling the [Cancel] button on the master configuration dialog 
 * when the symbol coloring properties are modified and need to be recalculated. 
 * Since we cache the scheme being edited in the symbol coloring configuration 
 * object, there is nothing to do here unless the user changed which scheme was 
 * being used. 
 */
void _color_form_cancel()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   // Reset the currently edited profile settings
   dcc->resetToOriginal();
   scm:=dcc->getCurrentProfile();
   scm->applyColorScheme();
   scm->applySymbolColorScheme();

   /*
      Restore the color profile to the original if it changed
      since the last apply.
   */
   origProfile := getOriginalColorSchemeName();
   if (origProfile != ColorScheme.removeProfilePrefix(ctl_scheme.p_text) && 
       _plugin_has_profile(VSCFGPACKAGE_COLOR_PROFILES,origProfile)
       ) {
      dcc->loadProfile(origProfile);
      scm=dcc->getCurrentProfile();
      scm->applyColorScheme();
      scm->applySymbolColorScheme();
   }
}

/**
 * Initialize the symbol coloring configuration dialog for the 
 * master configuration dialog.  There is nothing to do here 
 * becuase it is all handled in the on_create(). 
 *  
 * @param scheme_name   symbol coloring scheme name 
 */
void _color_form_init_for_options(_str scheme_name_or_color = "")
{
   if (scheme_name_or_color != '') {
      if (isinteger(scheme_name_or_color)) {
         selectColor((int)scheme_name_or_color);
      } 
   }
}

/**
 * Initialize the settings of the form so that we can figure out when it's been 
 * modified. 
 */
void _color_form_save_settings()
{
   // save the current scheme name
   ctl_scheme_label.p_user = ColorScheme.removeProfilePrefix(ctl_scheme.p_text);
}

/**
 * Callback to check if the color settings have been modified since it was first
 * loaded into the dialog. 
 *  
 * @return 'true' if the coloring had been modified.
 */
bool _color_form_is_modified()
{
   // see if we are using the same scheme
   dcc := getDefaultColorsConfig();
   if (dcc == null) return false;
   scm:=dcc->getCurrentProfile();
   if (dcc->isModified() || (dcc->isModifiedBuiltinProfile() && !_plugin_has_user_profile(VSCFGPACKAGE_COLOR_PROFILES,scm->m_name)) ||
       scm->m_name!=def_color_scheme) return true;

   return false;
}
#if 0
/**
 * Callback to restore the symbol coloring options back to their 
 * original state for the given scheme name. 
 *  
 * @param scheme_name_or_color   symbol coloring scheme name to reset, or the 
 *                               color id corresponding to the color we wish to
 *                               select
 */
void _color_form_restore_state(_str scheme_name_or_color)
{
   if (isinteger(scheme_name_or_color)) {
      selectColor((int)scheme_name_or_color);
   } else {
   
      dcc := getDefaultColorsConfig();
      if (dcc == null) return;
   
      scm := dcc->getScheme(scheme_name_or_color);
      if (scm == null) return;
   
      dcc->setCurrentScheme(*scm);
      dcc->setModified(false);
      ctl_scheme.p_text = scm->m_name;
   }
}
#endif

/**
 * Enable or disable the symbol coloring form controls for editing 
 * the current color. 
 *  
 * @param onoff   'true' to enable, 'false' to disable 
 */
static void enableColorSettings(int cfg)
{
   switch (cfg) {
   case 0:
      ctl_color_note.p_enabled = false;
      ctl_system_default.p_enabled = false;
      ctl_system_default.p_visible = false;
      ctl_foreground_frame.p_visible = true;
      ctl_foreground_frame.p_enabled = false;
      ctl_foreground_color.p_enabled = false;
      ctl_foreground_color.p_backcolor = 0x808080;
      ctl_background_frame.p_visible = true;
      ctl_background_frame.p_enabled = false;
      ctl_background_inherit.p_visible = true;
      ctl_background_inherit.p_enabled = false;
      ctl_background_inherit.p_value = 0;
      ctl_background_color.p_enabled = false;
      ctl_background_color.p_backcolor = 0x808080;
      ctl_embedded_label.p_enabled = false;
      ctl_embedded_color.p_enabled = false;
      ctl_embedded_label.p_visible = true;
      ctl_embedded_color.p_visible = true;
      ctl_embedded_color.p_backcolor = 0x808080;
      ctl_font_frame.p_visible = true;
      ctl_font_frame.p_enabled = false;
      //ctl_normal.p_enabled = false;
      ctl_bold.p_enabled = false;
      ctl_underline.p_enabled = false;
      ctl_strikeout.p_enabled = false;
      ctl_italic.p_enabled = false;
      ctl_sample.p_visible = true;
      ctl_sample.p_enabled = false;
      ctl_sample.p_forecolor = 0x0;
      ctl_sample.p_backcolor = 0x808080;
      ctl_embedded_sample.p_visible = true;
      ctl_embedded_sample.p_enabled = false;
      ctl_embedded_sample.p_forecolor = 0x0;
      ctl_embedded_sample.p_backcolor = 0x808080;
      break;

   case CFG_CURRENT_LINE_BOX:
   case CFG_VERTICAL_COL_LINE:
   case CFG_MARGINS_COL_LINE:
   case CFG_TRUNCATION_COL_LINE:
   case CFG_PREFIX_AREA_LINE:
   case CFG_SELECTIVE_DISPLAY_LINE:
   case CFG_MODIFIED_ITEM:
   case CFG_NAVHINT:
   case CFG_DOCUMENT_TAB_MODIFIED:
   case CFG_MINIMAP_DIVIDER:
      ctl_color_note.p_enabled = true;
      ctl_system_default.p_enabled = false;
      ctl_system_default.p_visible = false;
      ctl_foreground_frame.p_visible = true;
      ctl_foreground_frame.p_enabled = true;
      ctl_foreground_color.p_enabled = true;
      ctl_background_frame.p_visible = false;
      ctl_background_frame.p_enabled = false;
      ctl_font_frame.p_enabled = false;
      ctl_font_frame.p_visible = false;
      ctl_sample.p_visible = false;
      ctl_embedded_sample.p_visible = false;
      break;

   case CFG_STATUS:
   case CFG_CMDLINE:
   case CFG_MESSAGE:
   case CFG_DOCUMENT_TAB_ACTIVE:
   case CFG_DOCUMENT_TAB_SELECTED:
   case CFG_DOCUMENT_TAB_UNSELECTED:
      ctl_color_note.p_enabled = true;
      ctl_system_default.p_enabled = true;
      ctl_system_default.p_visible = true;
      ctl_foreground_frame.p_visible = true;
      ctl_foreground_frame.p_enabled = true;
      ctl_foreground_color.p_enabled = true;
      ctl_background_frame.p_visible = true;
      ctl_background_frame.p_enabled = true;
      ctl_background_inherit.p_enabled = false;
      ctl_background_inherit.p_visible = false;
      ctl_background_color.p_enabled = true;
      ctl_embedded_label.p_enabled = false;
      ctl_embedded_color.p_enabled = false;
      ctl_embedded_label.p_visible = false;
      ctl_embedded_color.p_visible = false;
      ctl_font_frame.p_enabled = false;
      ctl_font_frame.p_visible = false;
      //ctl_normal.p_enabled = true;
      ctl_bold.p_enabled = true;
      ctl_underline.p_enabled = true;
      ctl_strikeout.p_enabled = true;
      ctl_italic.p_enabled = true;
      ctl_sample.p_visible = true;
      ctl_sample.p_enabled = true;
      ctl_embedded_sample.p_visible = false;
      ctl_embedded_sample.p_enabled = false;
      break;

   case CFG_SELECTED_CLINE:
   case CFG_SELECTION:
   case CFG_CLINE:
   case CFG_CURSOR:
      ctl_color_note.p_enabled = true;
      ctl_system_default.p_enabled = false;
      ctl_system_default.p_visible = false;
      ctl_foreground_frame.p_visible = true;
      ctl_foreground_frame.p_enabled = true;
      ctl_foreground_color.p_enabled = true;
      ctl_background_frame.p_visible = true;
      ctl_background_frame.p_enabled = true;
      ctl_background_inherit.p_visible = true;
      ctl_background_inherit.p_enabled = true;
      ctl_background_color.p_enabled = true;
      ctl_embedded_label.p_enabled = true;
      ctl_embedded_color.p_enabled = true;
      ctl_embedded_label.p_visible = true;
      ctl_embedded_color.p_visible = true;
      ctl_font_frame.p_enabled = false;
      ctl_font_frame.p_visible = true;
      //ctl_normal.p_enabled = false;
      ctl_bold.p_enabled = false;
      ctl_underline.p_enabled = false;
      ctl_strikeout.p_enabled = false;
      ctl_italic.p_enabled = false;
      ctl_bold.p_value = ctl_italic.p_value=ctl_underline.p_value=ctl_strikeout.p_value=0;
      ctl_sample.p_visible = true;
      ctl_sample.p_enabled = true;
      ctl_embedded_sample.p_visible = !(cfg == CFG_LINEPREFIXAREA);
      ctl_embedded_sample.p_enabled = !(cfg == CFG_LINEPREFIXAREA);
      break;

   default:
      ctl_color_note.p_enabled = true;
      ctl_system_default.p_enabled = false;
      ctl_system_default.p_visible = false;
      ctl_foreground_frame.p_visible = true;
      ctl_foreground_frame.p_enabled = true;
      ctl_foreground_color.p_enabled = true;
      ctl_background_frame.p_visible = true;
      ctl_background_frame.p_enabled = true;
      ctl_background_inherit.p_visible = true;
      ctl_background_inherit.p_enabled = (cfg != CFG_WINDOW_TEXT);
      ctl_background_color.p_enabled = true;
      ctl_embedded_label.p_enabled = !(cfg == CFG_LINEPREFIXAREA);
      ctl_embedded_color.p_enabled = !(cfg == CFG_LINEPREFIXAREA);
      ctl_embedded_label.p_visible = !(cfg == CFG_LINEPREFIXAREA);
      ctl_embedded_color.p_visible = !(cfg == CFG_LINEPREFIXAREA);
      ctl_font_frame.p_enabled = true;
      ctl_font_frame.p_visible = true;
      //ctl_normal.p_enabled = true;
      ctl_bold.p_enabled = true;
      ctl_underline.p_enabled = true;
      ctl_strikeout.p_enabled = true;
      ctl_italic.p_enabled = true;
      ctl_sample.p_visible = true;
      ctl_sample.p_enabled = true;
      ctl_embedded_sample.p_visible = !(cfg == CFG_LINEPREFIXAREA);
      ctl_embedded_sample.p_enabled = !(cfg == CFG_LINEPREFIXAREA);
      break;
   }
}

/**
 * Handle actions that occur in the color list, such as when the 
 * user selects a different node. 
 *  
 * @param reason     type of event 
 * @param index      current tree index
 */
void ctl_rules.on_change(int reason,int index)
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (dcc->ignoreChanges()) {
      return;
   }

   switch (reason) {
   case CHANGE_CLINE:
   case CHANGE_CLINE_NOTVIS:
   case CHANGE_SELECTED:
      loadColor(getColorId());
      break;
   }

}

/** 
 * Change the mode name for the sample code. 
 */
void ctl_mode_name.on_change(int reason)
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (dcc->ignoreChanges()) {
      return;
   }

   switch (reason) {
   case CHANGE_CLINE_NOTVIS:
   case CHANGE_CLINE:
   case CHANGE_SELECTED:
      ctl_code_sample._SetEditorLanguage(_Modename2LangId(p_text));
      ctl_code_sample._GenerateSampleColorCode();
      break;
   }
}

/**
 * Prompt the user for a color scheme name, this is done both for saving the
 * current scheme and renaming the scheme. 
 *  
 * @param dcc              color configuration manager object
 * @param origSchemeName   original scheme name (being renamed or saved) 
 * @param allowSameName    allow them to use the same name (to save a user scheme) 
 * 
 * @return '' if they cancelled, otherwise returns the new scheme name 
 */
static _str getColorSchemeName(_str origSchemeName)
{
   // prompt the user for a new scheme name
   loop {
      status := textBoxDialog("Enter Profile Name", 0, 0, 
                              "New Color Profile dialog", 
                              "", "", " Profile name:":+origSchemeName);
      if (status < 0) {
         break;
      }
      newSchemeName := _param1;
      if (newSchemeName == "") {
         break;
      }

      // verify that the new name does not duplicate an existing name
      if (!_plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,newSchemeName)) {
         return newSchemeName;
      }


      _message_box("There is already a profile named \""newSchemeName".\"");
      continue;
   }

   // command cancelled due to error
   return "";
}

/**
 * Handle switching schemes.  If the current scheme is modified from it's 
 * saved settings, prompt the user before switching schemes. 
 *  
 * @param reason  event type
 */
void ctl_scheme.on_change(int reason)
{
   if (reason == CHANGE_CLINE || reason == CHANGE_CLINE_NOTVIS) {

      dcc := getDefaultColorsConfig();
      if (dcc == null) return;
      if (dcc->ignoreChanges()) return;
      scm := getColorScheme();
      if (scm==null) return;
     
      // prompt about saving the former scheme
      if (dcc->profileChanged()) {
         buttons := "&Save Changes,&Discard Changes,Cancel:_cancel\t-html The current profile has been modified.  Would you like to save your changes?";
   
         status := textBoxDialog('SlickEdit Options',
                                 0,
                                 0,
                                 'Modified Color Profile',
                                 buttons);
         if (status == 1) {            // Save - the first button
            scm->saveProfile();
            dcc->setModified(false);
         } else if (status == 2) {     // Discard Changes - the second button
            //loadScheme(scm->m_name);
         } else {                      // Cancel our cancellation
            ctl_scheme.p_text = ColorScheme.addProfilePrefix(scm->m_name);
            return;
         }
      }

      // warn them if the selected scheme is not compatible with the
      // current color scheme
      schemeName := ColorScheme.removeProfilePrefix(strip(ctl_scheme.p_text));
      cfg := getColorId();
      dcc->loadProfile(schemeName);
      loadScheme();
      ctl_code_sample.updateSampleCode();
      selectColor(cfg);
      dcc->setModified(true);
      ctl_rules._TreeRefresh();

      updateButtons();
   }
}

/**
 * Select the given color.
 */
void selectColor(int colorId)
{
   if (colorId == 0) return;
   index := ctl_rules._TreeSearch(TREE_ROOT_INDEX, "", "T", colorId);
   if (index > 0) {
      ctl_rules._TreeTop();
      ctl_rules._TreeSetCurIndex(index);
      ctl_rules._TreeRefresh();
   }
}

/**
 * Reset the current scheme to the default.  Only has any effect on system 
 * schemes that have been modified. 
 */
void ctl_reset_scheme.lbutton_up()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := getColorScheme();

   // make sure this scheme can be reset - it must be a system scheme that has 
   // been modified
   name := scm->m_name;
   if (dcc->isModifiedBuiltinProfile()) {
      dcc->loadProfile(scm->m_name,1/* Load the built-in profile */);
      cfg := getColorId();
      loadScheme();
      ctl_code_sample.updateSampleCode();
      selectColor(cfg);
      ctl_rules._TreeRefresh();

      ctl_reset_scheme.p_enabled = false;

      dcc->setModified();
   }  
}
static void updateButtons()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := dcc->getCurrentProfile();

   ctl_delete_scheme.p_enabled = ctl_rename_scheme.p_enabled = !DefaultColorsConfig.hasBuiltinProfile(scm->m_name);
   ctl_reset_scheme.p_enabled = dcc->isModifiedBuiltinProfile();
}

/**
 * Delete the current scheme.  Do not allow them to delete system schemes.
 */
void ctl_delete_scheme.lbutton_up()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := getColorScheme();
   if (scm==null) return;

   if (DefaultColorsConfig.hasBuiltinProfile(scm->m_name)) {
      //_message_box(get_message(VSRC_CFG_CANNOT_REMOVE_SYSTEM_SCHEMES));
      return;
   }
   mbrc := _message_box("Are you sure you want to delete the profile '"scm->m_name"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
   if (mbrc!=IDYES) {
      return;
   }
   _plugin_delete_profile(VSCFGPACKAGE_COLOR_PROFILES,scm->m_name);

   // disable all on_change callbacks
   origIgnore := dcc->ignoreChanges();
   dcc->setIgnoreChanges(true);

   dcc->setModified();

   ctl_scheme._lbdelete_item();
   ctl_scheme._lbdown();
   currentSchemeName:=ColorScheme.removeProfilePrefix(ctl_scheme._lbget_text());
   ctl_scheme.p_text = ColorScheme.addProfilePrefix(currentSchemeName);
   cfg := getColorId();
   dcc->setIgnoreChanges(origIgnore);

   dcc->loadProfile(currentSchemeName);
   loadScheme();
   ctl_code_sample.updateSampleCode();
   selectColor(cfg);
   ctl_rules._TreeRefresh();

   updateButtons();
   // set modified again, to note that the current selection has changed
   dcc->setModified(true);

}

/**
 * Save the current scheme under a new name as a user-defined scheme.
 */
void ctl_save_scheme_as.lbutton_up()
{
   if (save_changes_first()) {
      return;
   }
   copyCurentProfile();
   updateButtons();
}

static void copyCurentProfile()
{
   // get the configuration object
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := getColorScheme();
   if (scm == null) return;

   // prompt the user for a new scheme name
   origSchemeName := scm->m_name;
   newSchemeName := getColorSchemeName(origSchemeName);
   if (newSchemeName == "") return;

   scm->m_name = newSchemeName;
   scm->saveProfile();
   if (newSchemeName != origSchemeName) {
      ctl_scheme._lbbottom();
      ctl_scheme._lbadd_item(ColorScheme.addProfilePrefix(newSchemeName),60,"");
      ctl_scheme._lbsort('i');
      dcc->setIgnoreChanges(true);
      ctl_scheme.p_text = ColorScheme.addProfilePrefix(newSchemeName);
      dcc->setIgnoreChanges(false);
      loadScheme();
   }

   dcc->setModified(false);
}

static bool save_changes_first() {
   dcc := getDefaultColorsConfig();
   if (dcc == null) return false;
   
   if (dcc->profileChanged()) {
      buttons := "&Save Changes,&Discard Changes,Cancel:_cancel\t-html The current profile has been modified.  Would you like to save your changes?";

      status := textBoxDialog('SlickEdit Options',
                              0,
                              0,
                              'Modified Color Profile',
                              buttons);
      if (status == 1) {            // Save - the first button
         scm := dcc->getCurrentProfile();
         scm->saveProfile();
         dcc->setModified(false);
      } else if (status == 2) {     // Discard Changes - the second button
         //loadScheme(rb->m_name);
      } else {                      // Cancel our cancellation
         return true;
      }
   }
   return false;
}

/**
 * Rename the current scheme.  Do not allow them to rename system 
 * default schemes. 
 */
void ctl_rename_scheme.lbutton_up()
{
   // get the configuration object
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := dcc->getCurrentProfile();

   // only allow them to rename user schemes
   origSchemeName := scm->m_name;
   if (DefaultColorsConfig.hasBuiltinProfile(scm->m_name)) {
      // This button is supposed to be disabled.
      //_message_box(get_message(VSRC_CFG_CANNOT_FIND_USER_SCHEME, origSchemeName));
      return;
   }
   if (save_changes_first()) {
      return;
   }

   // prompt the user for a new scheme name
   newSchemeName  := getColorSchemeName(origSchemeName);
   if (newSchemeName == "") return;

   scm->m_name = newSchemeName; 
   scm->saveProfile();
   _plugin_delete_profile(VSCFGPACKAGE_COLOR_PROFILES,origSchemeName);
   ctl_scheme._lbset_item(ColorScheme.addProfilePrefix(newSchemeName));
   ctl_scheme._lbsort('i');
   origIgnore := dcc->ignoreChanges();
   dcc->setIgnoreChanges(true);
   ctl_scheme.p_text = ColorScheme.addProfilePrefix(newSchemeName);
   dcc->setIgnoreChanges(origIgnore);

   // set modified again, to note that the current selection has changed
   dcc->setModified(true);
   updateButtons();
}

/**
 * Reset the color scheme back to what it was before we started.
 */
void ctl_reset_colors.lbutton_up()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := getColorScheme();
   if (scm == null) return;

   scm->loadCurrentColorScheme();
   ctl_scheme.p_text = ColorScheme.addProfilePrefix(scm->m_name);
   cfg := getColorId();
   loadScheme();
   loadColor(getColorId());
   selectColor(cfg);
   dcc->setModified(false);
}

/**
 * Display the Symbol Coloring dialog.
 */
void ctl_symbol_coloring.lbutton_up()
{
   config("Symbol Coloring");
}

/**
 * Turn on/off use of the system default coloring.
 */
static void _system_default_color_state(bool useSystemDefault)
{
   ctl_foreground_frame.p_enabled = !useSystemDefault;
   ctl_foreground_color.p_enabled = !useSystemDefault;
   ctl_background_frame.p_enabled = !useSystemDefault;
   ctl_background_inherit.p_enabled = !useSystemDefault;
   ctl_background_color.p_enabled = !useSystemDefault;
   ctl_embedded_label.p_enabled = !useSystemDefault;
   ctl_embedded_color.p_enabled = !useSystemDefault;
   
   color := getColorInfo();
   if (color == null) return;
   if (useSystemDefault) {
      color->m_foreground = VSDEFAULT_FOREGROUND_COLOR;
      color->m_background = VSDEFAULT_BACKGROUND_COLOR;
      color->m_fontFlags = 0;
   } else {
      color->m_foreground = 0x0;
      color->m_background = 0xFFFFFF;
      color->m_fontFlags = 0;
   }

   ctl_foreground_color.p_backcolor = color->getForegroundColor();
   ctl_background_color.p_backcolor = color->getBackgroundColor();
   ctl_embedded_color.p_backcolor = color->getBackgroundColor();
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_embedded_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_embedded_sample.p_backcolor = ctl_embedded_color.p_backcolor;
   updateCurrentColor();
}

void ctl_system_default.lbutton_up()
{
   if (!p_enabled) return;
   _system_default_color_state((p_value != 0));
}

/**
 * Handle changes in font settings.  This event handler is also used by
 * by the Inherit Font, Bold, Italic, and Underline radio buttons
 */
void ctl_bold.lbutton_up()
{
   // get our current scheme and color info
   scm := getColorScheme();
   color := getColorInfo();
   if (color == null) return;

   // figure out which font attribute changed
   font_flag := 0;
#if 0
   // Don't support bold with italic with underline for now
   if (ctl_bold.p_value && ctl_italic.p_value && ctl_underline.p_value) {
      switch (p_name) {
      case "ctl_bold":  
         ctl_bold.p_value=0;
         break;
      case "ctl_italic": 
         ctl_underline.p_value=0;
         break;
      case "ctl_underline":
         ctl_italic.p_value=0;
         break;
      case "ctl_strikeout":
         ctl_strikeout.p_value=0;
         break;
      }
   }
#endif

   // first, cut out all the flags
   color->m_fontFlags &= ~(F_BOLD|F_ITALIC|F_UNDERLINE|F_STRIKE_THRU);

   // now add back in the one we selected
   if (ctl_bold.p_value) {
      color->m_fontFlags |= F_BOLD;
   } 
   if (ctl_italic.p_value) {
      color->m_fontFlags |= F_ITALIC;
   }
   if (ctl_underline.p_value) {
      color->m_fontFlags |= F_UNDERLINE;
   }
   if (ctl_strikeout.p_value) {
      color->m_fontFlags |= F_STRIKE_THRU;
   }

   embeddedColor := getEmbeddedColorInfo();
   if (embeddedColor != null) {
      embeddedColor->m_fontFlags = color->m_fontFlags;
   }

   ctl_sample.p_font_strike_thru = (ctl_strikeout.p_value != 0);
   ctl_sample.p_font_underline = (ctl_underline.p_value != 0);
   ctl_sample.p_font_italic = (ctl_italic.p_value != 0);
   ctl_sample.p_font_bold = (ctl_bold.p_value != 0);
   ctl_embedded_sample.p_font_bold      = ctl_sample.p_font_bold;            
   ctl_embedded_sample.p_font_italic    = ctl_sample.p_font_italic;    
   ctl_embedded_sample.p_font_underline = ctl_sample.p_font_underline;
   ctl_embedded_sample.p_font_strike_thru = ctl_sample.p_font_strike_thru;
   updateCurrentColor();
   dcc := getDefaultColorsConfig();
   if (dcc==null) return;
   // set modified again, to note that the current selection has changed
   dcc->setModified(true);
   updateButtons();
}

/**
 * Handle changes in foreground or background color inheritance.
 */
void ctl_background_inherit.lbutton_up()
{
   ctl_foreground_color.enableColorControl();
   ctl_background_color.enableColorControl();
   ctl_embedded_color.enableColorControl();

   color := getColorInfo();
   if (color == null) return;

   if (p_name == "ctl_background_inherit") {
      if (p_value) {
         color->m_fontFlags |= F_INHERIT_BG_COLOR;
      } else {
         color->m_fontFlags &= ~F_INHERIT_BG_COLOR;
      }
      embeddedColor := getEmbeddedColorInfo();
      if (embeddedColor != null) {
         if (p_value) {
            embeddedColor->m_fontFlags |= F_INHERIT_BG_COLOR;
         } else {
            embeddedColor->m_fontFlags &= ~F_INHERIT_BG_COLOR;
         }
      }
   } else {
      if (p_value) {
         color->m_fontFlags |= F_INHERIT_FG_COLOR;
      } else {
         color->m_fontFlags &= ~F_INHERIT_FG_COLOR;
      }
   }

   scm := getColorScheme();
   cfg := getColorId();
   ctl_foreground_color.p_backcolor = color->getForegroundColor(scm);
   ctl_background_color.p_backcolor = color->getBackgroundColor(scm);
   ctl_embedded_color.p_backcolor = scm->getEmbeddedBackgroundColor(cfg);
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_embedded_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_embedded_sample.p_backcolor = ctl_embedded_color.p_backcolor;
   updateCurrentColor();
   dcc := getDefaultColorsConfig();
   if (dcc==null) return;
   // set modified again, to note that the current selection has changed
   dcc->setModified(true);
   updateButtons();
}

/**
 * Handle changes in the foreground or background color setting. 
 */
void ctl_foreground_color.lbutton_up()
{
   inherit_checkbox := p_prev;
   while (inherit_checkbox != p_window_id) {
      if (inherit_checkbox.p_object == OI_CHECK_BOX) {
         if (inherit_checkbox.p_value != 0) return;
      }
      inherit_checkbox = inherit_checkbox.p_prev;
   }

   // make sure this is a proper color
   origColor := p_backcolor;
   if ((int)origColor < 0 || (origColor & 0x80000000) ||
       (int)origColor == VSDEFAULT_FOREGROUND_COLOR || 
       (int)origColor == VSDEFAULT_BACKGROUND_COLOR) {
      origColor = 0x0;
   }
   color := show_color_picker(origColor);
   if (color == COMMAND_CANCELLED_RC) return;
   if (color == origColor) return;

   p_backcolor = color;

   colorInfo := getColorInfo();
   if (colorInfo == null) return;

   scm := getColorScheme();
   if (p_window_id == ctl_foreground_color) {
      colorInfo->m_foreground = color;
      if (!ctl_background_frame.p_visible) {
         colorInfo->m_background = color;
      }
   } else if (p_window_id == ctl_background_color) {
      colorInfo->m_background = color;
   } else if (p_window_id == ctl_embedded_color) {
      embeddedInfo := getEmbeddedColorInfo();
      if (embeddedInfo != null) {
         embeddedInfo->m_background = color;
      }
   }

   cfg := getColorId();
   ctl_foreground_color.p_backcolor = colorInfo->getForegroundColor(scm);
   ctl_background_color.p_backcolor = colorInfo->getBackgroundColor(scm);
   ctl_embedded_color.p_backcolor = scm->getEmbeddedBackgroundColor(cfg);
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_embedded_sample.p_forecolor = ctl_foreground_color.p_backcolor;
   ctl_embedded_sample.p_backcolor = ctl_embedded_color.p_backcolor;

   updateCurrentColor();
   dcc := getDefaultColorsConfig();
   if (dcc==null) return;
   // set modified again, to note that the current selection has changed
   dcc->setModified(true);
   updateButtons();
}

void ctl_symbol_scheme.on_change(int reason)
{
   if (reason != CHANGE_OTHER) {
      scm := getColorScheme();
      if (scm==null) return;
      if (scm->m_symbolColoringSchemeName != p_text) {
         dcc := getDefaultColorsConfig();
         if (dcc==null) return;
         dcc->setModified(true);
         if (dcc->ignoreChanges()) return;
         scm->m_symbolColoringSchemeName = p_text;
      }
   }
}

/**
 * Look up the language specific code sample from the code sample database. 
 * 
 * @param configFile    name of code samples XML config file 
 * @param modeName      language mode name to find sample for
 * 
 * @return contents of code sample (PCDATA) 
 */
static _str getSampleCode( _str modeName)
{
   langid:=_Modename2LangId(modeName);
   if (langid=='') {
      return null;
   }
   int handle=_plugin_get_property_xml(VSCFGPACKAGE_MISC,VSCFGPROFILE_COLOR_CODING_SAMPLES,langid);
   if (handle<0) {
      return null;
   }
   text:=_xmlcfg_get_text(handle,_xmlcfg_get_document_element(handle));
   _xmlcfg_close(handle);
   if (text=='') {
      return null;
   }
   return text;
}

/**
 * Generate sample code for the selected mode name 
 * and insert it into the sample code editor control. 
 */
void _GenerateSampleColorCode() 
{
   _lbclear();
   top(); 
   _begin_line();

   text := getSampleCode(p_mode_name);
   if (text != null) {
      text = strip(text, "L", " \t");
      while (_first_char(text) == "\n" || _first_char(text) == "\r") {
         text = substr(text, 2);
      }
      _insert_text(text);
   } else {
      insert_line("This code is generated.");
      _lineflags(NOSAVE_LF);
      if ( !getCommentSettings(p_LangId,auto commentSettings,"B") ) {
         insert_line(" This is a block comment.");
         select_line();
         box();
         _deselect();
         bottom();
         _end_line();
      }
      insert_line("if");
      call_event(p_window_id, " ");
      keyin(" cond == true ");
      _end_line();
      nosplit_insert_line();
      keyin("y = 123456789;");
      indent_line();

      bottom();
      if ( !getCommentSettings(p_LangId,commentSettings,"L") ) {
         insert_line(" This is a line comment.");
         comment();
      }
      insert_line("if");
      call_event(p_window_id, " ");
      keyin(" cond == false ");
      _end_line();
      nosplit_insert_line();
      keyin("x = \"This is a string\";");
      indent_line();
   }
   top(); up(); _begin_line();
   // reset line flags
   while (!down()) {
      _lineflags(0,MODIFY_LF|INSERTED_LINE_LF);
   }
   top(); up(); _begin_line();
   // add Inserted Line, Modified Line to sample
   if (!down()) {
      if (!down()) _lineflags(INSERTED_LINE_LF,INSERTED_LINE_LF);
      if (!down()) _lineflags(MODIFY_LF,MODIFY_LF);
   }
   top(); _begin_line();
}

_str _color_form_export_settings(_str &path, _str &currentScheme)
{

   error := '';
   _plugin_export_profiles(path,VSCFGPACKAGE_COLOR_PROFILES);
   // save our current scheme
   currentScheme = def_color_scheme;
   return error;
}
_str _color_form_import_settings(_str file, _str currentScheme)
{
   error := '';

   if (file!='') {
      if (endsWith(file,VSCFGFILEEXT_CFGXML,false,_fpos_case)) {
         error=_plugin_import_profiles(file,VSCFGPACKAGE_COLOR_PROFILES,2);
      } else {
         _convert_uscheme_ini(file);
      }
   }
   if (_plugin_has_profile(VSCFGPACKAGE_COLOR_PROFILES,currentScheme)) {
      se.color.ColorScheme rb;
      
      def_color_scheme = currentScheme;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      rb.loadProfile(def_color_scheme);
      rb.applyColorScheme();
   }
   return error;

}
