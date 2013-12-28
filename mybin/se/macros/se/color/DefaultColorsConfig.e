////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50230 $
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
#endregion

/**
 * This is the name of the file used to store language specific 
 * code samples displayed in the color coding dialog. 
 */
const CODE_SAMPLES_FILE = "CodeSamples.xml";


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
    * This is a hash table of color schemes.  There are system schemes, 
    * and user schemes, both stored in this same table.  Schemes must 
    * be uniquely named. 
    */
   private ColorScheme m_schemes:[];

   /**
    * This hash table keeps track of the original versions of system schemes as 
    * they are read from the installed INI file. 
    */
   private ColorScheme m_systemSchemes:[];

   /**
    * This is the color scheme which is currently being edited 
    * in the Colors options dialog.
    */
   private ColorScheme m_currentScheme;

   /**
    * Has the current color scheme changed? 
    */
   private boolean m_modified = false;

   /**
    * Temporarily ignore what might appear to be color modifications. 
    */
   private boolean m_ignoreModifications = false;

   /**
    * This table is used to assign color ID's to each of the the colors 
    * currently being edited in the color form.
    */
   private int m_colorIds[];

   ///**
   // * Destructor, clean up resources.
   // */
   //~DefaultColorsConfig() {
   //   temp_wid := 0;
   //   orig_wid := _create_temp_view(temp_wid);
   //   foreach (auto colorId in m_colorIds) {
   //      if (colorId != null && colorId != 0 && colorId > CFG_LAST_DEFAULT_COLOR) {
   //         //_FreeColor(colorId);
   //      }
   //   }
   //   _delete_temp_view(temp_wid);
   //   m_colorIds = null;
   //   m_userScheme = null;
   //   m_schemes = null;
   //}

   /** 
    * @return 
    * Return the total number of system and and user-defined
    * color schemes loaded. 
    */
   int getNumSchemes() {
      return m_schemes._length();
   }

   /** 
    * @return 
    * Return a pointer to the current color scheme being edited. 
    * This function can not return 'null'. 
    */
   ColorScheme *getCurrentScheme() {
      return &m_currentScheme;
   }

   /**
    * Replace the current color scheme with the given scheme.
    *
    * @param scm      new color scheme
    */
   void setCurrentScheme(ColorScheme &scheme) {
      m_currentScheme = scheme;
   }

   /**
    * Return the names of all the system and user color schemes currently 
    * loaded into the configuration GUI. 
    *  
    * @return An array of strings containing scheme names. 
    */
   STRARRAY getSchemeNames() {
      STRARRAY a;
      foreach (auto name => . in m_schemes) {
         a[a._length()] = name;
      }
      return a;
   }

   /**
    * @return 
    * Return a pointer to the system or user scheme with the given name. 
    * 
    * @param name    symbol color color base name
    */
   ColorScheme *getScheme(_str name) {
      if (name == null) return null;
      if (m_schemes._indexin(name)) {
         return &m_schemes:[name];
      }
      return null;
   }

   /**
    * Add the given scheme to the list of color schemes. 
    *  
    * @param scm            symbol color scheme
    * @param isUserScheme  false for system defined default schemes
    * 
    * @return Return a pointer to the copy of the scheme added to the list. 
    */
   ColorScheme *addScheme(ColorScheme &scm, boolean isUserScheme) {

      if (isUserScheme) {
         // for user schemes, just shove them in the hash table without a care
         m_schemes:[scm.m_name] = scm;
      } else {
         // add these to the system table
         m_systemSchemes:[scm.m_name] = scm;
         // make sure they are not already in the big table - we don't want to 
         // override the user version of this scheme
         if (!m_schemes._indexin(scm.m_name)) {
            m_schemes:[scm.m_name] = scm;
         } 
      } 

      return &m_schemes:[scm.m_name];
   }

   /**
    * Delete the scheme with the given name from the list of schemes. 
    *  
    * @param name    symbol color scheme name 
    */
   void deleteScheme(_str name) {
      if (m_schemes._indexin(name)) {
         m_schemes._deleteel(name);
      }
   }

   /**
    * Resets a modified system scheme back to the original configuration as 
    * specificed in the installed INI file. 
    * 
    * @param name    name of scheme to reset to default
    */
   void resetScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         scm := m_systemSchemes:[name];
         m_schemes:[name] = scm;

         setCurrentScheme(scm);
      }
   }

   /**
    * @return 
    * Return 'true' if the scheme with the given name was added as a 
    * user defined symbol color scheme (color base), as apposed to being 
    * a system defined default scheme. 
    *  
    * @param name    symbol color scheme name 
    */
   boolean isUserScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         return false;
      }
      return true;
   }

   /**
    * @return 
    * Return 'true' if the scheme with the given name was added as a system scheme, 
    * but has been modified from its original form by the user. 
    *  
    * @param name    symbol color scheme name 
    */
   boolean isModifiedSystemScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         orig_scm := &m_systemSchemes:[name];
         curr_scm := &m_schemes:[name];
         return (orig_scm == null || curr_scm == null || *orig_scm != *curr_scm);
      }

      return false;
   }

   /**
    * @return 
    * Has the current color scheme changed since we started editing it? 
    */
   boolean isModified() {
      return m_modified;
   }
   /**
    * Mark the current color scheme as modified or not modified.  This 
    * function will also relay the modification information to the main 
    * options dialog so that it knows that the Colors options panel has
    * unsaved modifications to save. 
    *  
    * @param onoff   'true' for a modification, 'false' if we are resetting modify 
    */
   void setModified(boolean onoff=true) {
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
   void ignoreChanges(boolean onoff=true) {
      m_ignoreModifications = onoff;
   }
   /**
    * @return 
    * Return 'true' if we are ignoring modifications temporilary. 
    */
   boolean isIgnoringChanges() {
      return m_ignoreModifications;
   }

   /**
    * @return 
    * Return the full path to the user color schemes configuration file. 
    * This file is stored in the user's configuration directory. 
    *  
    * @param mustExist  Return "" if the file does not exist. 
    */
   _str getUserDefaultColorsConfigFile(boolean mustExist=true) {
      filename := ColorScheme.getUserColorSchemeFile();
      if (mustExist && !file_exists(filename)) {
         filename = "";
      }
      return filename;
   }

   /**
    * @return 
    * Return the full path to the system default color schemes configuration 
    * file. This file is stored under the installation directory.
    *  
    * @param mustExist  Return "" if the file does not exist. 
    */
   _str getSystemDefaultColorsConfigFile(boolean mustExist=true) {

      filename := ColorScheme.getSystemColorSchemeFile();
      if (mustExist && !file_exists(filename)) {
         filename = "";
      }
      return filename;
   }

   /**
    * Set the color settings displayed in the Colors options dialog to the 
    * options currently in use. 
    */
   void loadCurrentScheme() {
      ColorScheme scm;
      scm.loadCurrentColorScheme();
      m_currentScheme = scm;

      // always load the current scheme as a user scheme, even though it may 
      // have originated as a system scheme
      addScheme(scm, true);         
   }

   /**
    * Load the system color schemes into the Colors options dialog. 
    * The schemes are loaded from [slickedit]/vsscheme.ini.
    * 
    * @return 0 on success, <0 on error
    */
   int loadSystemSchemes() {
      fileName := ColorScheme.getSystemColorSchemeFile();
      status := _open_temp_view(fileName, auto temp_wid=0, auto orig_wid=0);
      if (status < 0) return status;
      schemeNames := ColorScheme.getSystemSchemeNames();
      foreach (auto schemeName in schemeNames) {
         ColorScheme scm;
         scm.loadSystemColorScheme(schemeName);
         addScheme(scm, false);
      }
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
      return 0;
   }
   /**
    * Load the user defined color schemes into the Colors options dialog. 
    * The schemes are loaded from [config]/SymbolColoring.xml. 
    * 
    * @return 0 on success, <0 on error
    */
   int loadUserSchemes() {
      fileName := ColorScheme.getUserColorSchemeFile();
      status := _open_temp_view(fileName, auto temp_wid=0, auto orig_wid=0);
      if (status < 0) return status;
      schemeNames := ColorScheme.getUserSchemeNames();
      foreach (auto schemeName in schemeNames) {
         ColorScheme scm;
         scm.loadUserColorScheme(schemeName);
         addScheme(scm, true);
      }
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
      return 0;
   }

   /** 
    * @return 
    * Return a color ID, possibly allocated for the given color in 
    * the current scheme.  If a color is allocated, it will be free'd 
    * by this same class. 
    * 
    * @param cfg     CFG_* color constant 
    */
   int getColorIdForCurrentScheme(int cfg) {
      // no scheme, revert to plain text color
      if (m_currentScheme == null) {
         return CFG_WINDOW_TEXT;
      }
      // no such color, revert to plain text color
      ColorInfo *colorInfo = m_currentScheme.getColor(cfg);
      if (colorInfo == null) {
         return CFG_WINDOW_TEXT;
      }
      // no difference from default color, then use default
      if (colorInfo->matchesColor(cfg, &m_currentScheme)) {
         return cfg;
      }
      // allocate a color ID if we need one
      if (m_colorIds._length() <= cfg || m_colorIds[cfg]==null || m_colorIds[cfg] == 0) {
         m_colorIds[cfg] = colorInfo->getColorId(&m_currentScheme);
         return m_colorIds[cfg]; 
      }
      // color hasn't changed since allocated?
      if (!colorInfo->matchesColor(m_colorIds[cfg], &m_currentScheme)) {
         colorInfo->setColor(m_colorIds[cfg], &m_currentScheme);
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
   return dcc->getCurrentScheme();
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

/**
 * Load all the information about the color scheme with the given name into the 
 * Colors options dialog.  Generally speaking, this function fills in the tree
 * control containing the list of colors. 
 *  
 * @param name    color scheme name 
 */
static void loadScheme(_str name, boolean loadCurrentScheme=false) 
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;

   // find the selected color base by name
   scm := dcc->getCurrentScheme();
   if (!loadCurrentScheme || scm == null || scm->m_name != name) {
      scm = dcc->getScheme(name);
      if (scm == null) return;
      dcc->setCurrentScheme(*scm);
   }

   origIgnore := dcc->isIgnoringChanges();
   dcc->ignoreChanges(true);

   // load compatible symbol coloring schemes
   se.color.SymbolColorConfig scc;
   scc.loadEmptyScheme();
   scc.loadSystemSchemes();
   scc.loadUserSchemes();

   // set up the list of compatible color schemes
   ctl_symbol_scheme._lbaddSymbolColoringSchemeNames(scc, name);
   if (scm != null &&
       scm->m_symbolColoringSchemeName != null && 
       scm->m_symbolColoringSchemeName != "") {
      ctl_symbol_scheme._lbfind_and_select_item(scm->m_symbolColoringSchemeName);
   } else {
      ctl_symbol_scheme.p_text = "(None)";
   }

   // load all the individual colors
   loadAllColorsInTree(scm);

   // save the scheme
   dcc->setCurrentScheme(*scm);
   dcc->ignoreChanges(origIgnore);
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
   if (dcc->isIgnoringChanges()) return;

   color := getColorInfo();
   index := ctl_rules._TreeCurIndex();
   ctl_rules.p_redraw=true;

   scm := getColorScheme();
   if (scm == null) return;
   dcc->setModified(true);
   schemeName := strip(ctl_scheme.p_text);
   orig_scm := dcc->getScheme(schemeName);

   ctl_code_sample.updateSampleCode();
}

/**
 * Update the color coding for the language specific sample code. 
 */
static void updateSampleCode()
{
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   if (dcc->isIgnoringChanges()) return;
   scm := dcc->getCurrentScheme();
   if (scm == null) return;

   int colorIds[];
   for (cfg := 0; cfg <= CFG_LAST_DEFAULT_COLOR; cfg++) {
      colorIds[cfg] = 0;
   }

   se.color.ColorInfo *windowText = scm->getColor(CFG_WINDOW_TEXT);
   if (windowText != null) {
      se.color.ColorInfo curWindowText;
      curWindowText.getColor(CFG_WINDOW_TEXT);
      if (curWindowText.getBackgroundColor() != windowText->getBackgroundColor()) {
         // TBF:  we don't really want to do this, but until we can have colors
         // per editor control, this is our only workaround.
         scm->applyColorScheme();
         scm->applySymbolColorScheme();
      }
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
            colorId = colorIds[cfg] = dcc->getColorIdForCurrentScheme(cfg); 
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
   origIgnore := dcc->isIgnoringChanges();
   dcc->ignoreChanges(true);

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
   ctl_normal.p_value = (color->getFontFlags(scm) & (F_ITALIC|F_BOLD|F_UNDERLINE))? 0:1;
   
   // fill in the sample color display
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;  
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_embedded_sample.p_forecolor = ctl_foreground_color.p_backcolor;  
   ctl_embedded_sample.p_backcolor = ctl_embedded_color.p_backcolor;
   ctl_sample.p_font_bold      = (color->getFontFlags(scm) & F_BOLD) != 0;
   ctl_sample.p_font_italic    = (color->getFontFlags(scm) & F_ITALIC) != 0;
   ctl_sample.p_font_underline = (color->getFontFlags(scm) & F_UNDERLINE) != 0;
   ctl_embedded_sample.p_font_bold      = ctl_sample.p_font_bold;            
   ctl_embedded_sample.p_font_italic    = ctl_sample.p_font_italic;    
   ctl_embedded_sample.p_font_underline = ctl_sample.p_font_underline;

   // done, back to business as usual 
   dcc->ignoreChanges(origIgnore);
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
   // load all the scheme names into the combo box, putting
   // user defined schemes at the top of the list.
   schemeNames := dcc.getSchemeNames();
   name := "";
   _lbclear();

   foreach (name in schemeNames) {
      if (!dcc.isUserScheme(name)) continue;
      scm := dcc.getScheme(name);
      if (scm != null) {
         _lbadd_item(name,60,"");
      }
   }
   foreach (name in schemeNames) {
      if (dcc.isUserScheme(name)) continue;
      scm := dcc.getScheme(name);
      if (scm != null) {
         _lbadd_item(name,60,_pic_lbvs);
      }
   }

}

/**
 * Initialize the Colors options dialog.
 */
void _color_form.on_create()
{
   // The symbol color configuration dialog manager object goes
   // in the p_user of 'ctl_scheme'
   ctl_scheme.p_user = null;
   se.color.DefaultColorsConfig dcc;

   // load default schemes and the current symbol coloring scheme
   dcc.loadSystemSchemes();
   dcc.loadUserSchemes();
   dcc.loadCurrentScheme();
   
   // load all the scheme names into the combo box, putting
   // user defined schemes at the top of the list.
   ctl_scheme._lbaddColorSchemeNames(dcc);

   // determine the current scheme, mark it as modified if necessary
   currentSchemeName := def_color_scheme;
   ctl_scheme.p_text = currentSchemeName;
   scm := dcc.getCurrentScheme();
   orig_scm := dcc.getScheme(currentSchemeName);

   // enable and disable buttons based on whether this scheme is 
   // a user/system scheme
   ctl_delete_scheme.p_enabled = ctl_rename_scheme.p_enabled = dcc.isUserScheme(currentSchemeName);
   ctl_reset_scheme.p_enabled = dcc.isModifiedSystemScheme(currentSchemeName);

   // load compatible symbol coloring schemes
   se.color.SymbolColorConfig scc;
   scc.loadSystemSchemes();
   scc.loadUserSchemes();

   // set up the list of compatible color schemes
   ctl_symbol_scheme._lbaddSymbolColoringSchemeNames(scc, def_color_scheme);
   if (orig_scm != null && 
       orig_scm->m_symbolColoringSchemeName != null && 
       orig_scm->m_symbolColoringSchemeName != "") {
      ctl_symbol_scheme.p_text = orig_scm->m_symbolColoringSchemeName; 
   } else {
      ctl_symbol_scheme.p_text = "(None)";
   }
   
   // load all the individual color names
   loadAllColorsInTree(scm);

   // the small sample text needs to use the editor control font
   ctl_mode_name._lbaddModeNames();
   ctl_mode_name._lbsort();
   ctl_mode_name._lbfind_and_select_item(_LangId2Modename("c"));
   ctl_sample._use_edit_font();
   ctl_embedded_sample._use_edit_font();
   ctl_code_sample.top(); ctl_code_sample.up();
   ctl_code_sample.p_buf_name = ".cpp";
   ctl_code_sample._SetEditorLanguage(_Ext2LangId("cpp"));
   ctl_code_sample._GenerateSampleColorCode();

   ctl_code_sample.p_undo_steps=0;

   // finally, load the current symbol coloring scheme into the form 
   ctl_scheme.p_user = dcc;
   loadScheme(currentSchemeName,true);
   ctl_code_sample.updateSampleCode();
   ctl_rules._TreeRefresh();

   // select the color under the cursor if we have an MDI editor window
   if (!_no_child_windows()) {
      cfg := _mdi.p_child._clex_find(0, 'D');
      selectColor(cfg);
   } else {
      selectColor(CFG_WINDOW_TEXT);
   }
}

/**
 * Cleanup
 */
void _color_form.on_destroy()
{
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
      _set_minimum_size(ctl_save_scheme_as.p_width*6, ctl_sample.p_height*9);
   }

   // calculate the horizontal and vertical adjustments
   padding := ctl_rules.p_x;
   adjust_x := (width - ctl_rename_scheme.p_width - padding) - ctl_rename_scheme.p_x;
   adjust_y := (height - ctl_sample_frame.p_height - padding) - ctl_sample_frame.p_y;

   // adjust the scheme buttons
   ctl_rename_scheme.p_x += adjust_x; 
   ctl_delete_scheme.p_x += adjust_x;
   ctl_reset_scheme.p_x += adjust_x;
   ctl_save_scheme_as.p_x += adjust_x;
   ctl_scheme.p_width += adjust_x;
   ctl_symbol_scheme.p_width += adjust_x;
   ctl_symbol_coloring.p_x += adjust_x;
   ctl_reset_colors.p_x += adjust_x;
   ctl_scheme_divider.p_width += adjust_x;

   // adjust the color and font attribute groups
   ctl_rules.p_width += adjust_x;
   ctl_rules.p_height += adjust_y;
   ctl_color_note.p_x += adjust_x;
   ctl_system_default.p_x += adjust_x;
   ctl_foreground_frame.p_x += adjust_x;
   ctl_background_frame.p_x += adjust_x;
   ctl_font_frame.p_x += adjust_x;
   ctl_sample.p_x += adjust_x;
   ctl_embedded_sample.p_x += adjust_x;

   // adjust the sample code area
   ctl_sample_frame.p_x += adjust_x;
   ctl_sample_frame.p_height += adjust_y;
   ctl_code_sample.p_height = ctl_sample_frame.p_height - ctl_code_sample.p_y - 150;
}

/**
 * Callback for handling the [OK] or [Apply] buttons on the
 * master configuration dialog when the symbol coloring
 * properties are modified and need to be recalculated.
 */
void _color_form_apply()
{
   scm := getColorScheme();
   if (scm == null) return;
   scm->applyColorScheme();
   scm->applySymbolColorScheme();
   scm->insertMacroCode(true);
   _config_modify_flags(CFGMODIFY_DEFVAR);

   saveCurrentScheme(def_color_scheme);
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
   // see if the user was using a different scheme before and go back to that
   origScheme := getOriginalColorSchemeName();
   if (origScheme != ctl_scheme.p_text) {
      loadScheme(origScheme);

      scm := getColorScheme();
      if (scm == null) return;
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
   ctl_scheme_label.p_user = ctl_scheme.p_text;
}

/**
 * Callback to check if the color settings have been modified since it was first
 * loaded into the dialog. 
 *  
 * @return 'true' if the coloring had been modified.
 */
boolean _color_form_is_modified()
{
   // see if we are using the same scheme
   dcc := getDefaultColorsConfig();
   if (dcc == null) return false;
   if (dcc->isModified()) return true;

   return false;
}

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
      ctl_normal.p_enabled = false;
      ctl_bold.p_enabled = false;
      ctl_underline.p_enabled = false;
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
   case CFG_MODIFIED_ITEM:
   case CFG_NAVHINT:
   case CFG_DOCUMENT_TAB_MODIFIED:
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
      ctl_normal.p_enabled = true;
      ctl_bold.p_enabled = true;
      ctl_underline.p_enabled = true;
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
      ctl_normal.p_enabled = false;
      ctl_bold.p_enabled = false;
      ctl_underline.p_enabled = false;
      ctl_italic.p_enabled = false;
      ctl_normal.p_value = 1;
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
      ctl_normal.p_enabled = true;
      ctl_bold.p_enabled = true;
      ctl_underline.p_enabled = true;
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
   if (dcc->isIgnoringChanges()) {
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
   if (dcc->isIgnoringChanges()) {
      return;
   }

   switch (reason) {
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
static _str getColorSchemeName(se.color.DefaultColorsConfig &dcc, 
                               _str origSchemeName, boolean allowSameName=false)
{
   // prompt the user for a new scheme name
   loop {
      status := textBoxDialog("Enter Scheme Name", 0, 0, 
                              "New Color Scheme dialog", 
                              "", "", " Scheme name:":+origSchemeName);
      if (status < 0) {
         break;
      }
      newSchemeName := _param1;
      if (newSchemeName == "") {
         break;
      }

      // verify that the new name does not duplicate an existing name
      if (dcc.getScheme(newSchemeName) == null) {
         return newSchemeName;
      }

      // allow them to save a scheme with the same name as before
      if (newSchemeName == origSchemeName && allowSameName) {
         return newSchemeName;
      }

      _message_box("There is already a scheme named \""newSchemeName".\"");
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
      if (dcc->isIgnoringChanges()) return;
      scm := getColorScheme();
      if (scm==null) return;
     
      // prompt about saving the former scheme
      orig_scm := dcc->getScheme(scm->m_name);
      if (orig_scm == null || *orig_scm != *scm) {
         buttons := "&Save Changes,&Discard Changes,Cancel:_cancel\t-html The current scheme has been modified.  Would you like to save your changes?";
   
         status := textBoxDialog('SlickEdit Options',
                                 0,
                                 0,
                                 'Modified Color Scheme',
                                 buttons);
         if (status == 1) {            // Save - the first button
            saveCurrentScheme(scm->m_name);
         } else if (status == 2) {     // Discard Changes - the second button
            loadScheme(scm->m_name);
         } else {                      // Cancel our cancellation
            ctl_scheme.p_text = scm->m_name;
            return;
         }
      }

      // warn them if the selected scheme is not compatible with the
      // current color scheme
      schemeName := strip(ctl_scheme.p_text);
      scm = dcc->getScheme(schemeName);

      cfg := getColorId();
      loadScheme(schemeName);
      ctl_code_sample.updateSampleCode();
      selectColor(cfg);
      dcc->setModified(true);
      ctl_rules._TreeRefresh();

      // enable and disable buttons based on whether this scheme is 
      // a user/system scheme
      ctl_delete_scheme.p_enabled = ctl_rename_scheme.p_enabled = dcc -> isUserScheme(schemeName);
      ctl_reset_scheme.p_enabled = dcc -> isModifiedSystemScheme(schemeName);
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
   if (scm==null) return;

   // make sure this scheme can be reset - it must be a system scheme that has 
   // been modified
   name := scm->m_name;
   if (dcc->isModifiedSystemScheme(name)) {

      dcc->resetScheme(name);
      scm->deleteColorScheme(name);

      cfg := getColorId();
      loadScheme(name);
      ctl_code_sample.updateSampleCode();
      selectColor(cfg);
      ctl_rules._TreeRefresh();

      ctl_reset_scheme.p_enabled = false;

      dcc->setModified();
   }  
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

   if (!dcc->isUserScheme(scm->m_name)) {
      _message_box(get_message(VSRC_CFG_CANNOT_REMOVE_SYSTEM_SCHEMES));
      return;
   }

   dcc->setModified();
   scm->deleteColorScheme(scm->m_name);
   dcc->deleteScheme(scm->m_name);

   ctl_scheme._lbdelete_item();
   ctl_scheme._lbdown();
   ctl_scheme.p_text = ctl_scheme._lbget_text();
   cfg := getColorId();
   loadScheme(ctl_scheme._lbget_text());
   ctl_code_sample.updateSampleCode();
   selectColor(cfg);
   ctl_rules._TreeRefresh();
}

/**
 * Save the current scheme under a new name as a user-defined scheme.
 */
void ctl_save_scheme_as.lbutton_up()
{
   saveCurrentScheme();
}

static void saveCurrentScheme(_str newSchemeName = "")
{
   // get the configuration object
   dcc := getDefaultColorsConfig();
   if (dcc == null) return;
   scm := getColorScheme();
   if (scm == null) return;

   // prompt the user for a new scheme name
   origSchemeName := scm->m_name;
   if (newSchemeName == "") {
      newSchemeName  = getColorSchemeName(*dcc, origSchemeName, dcc->isUserScheme(origSchemeName));
   }
   if (newSchemeName == "") return;

   scm->m_name = newSchemeName;
   if (newSchemeName != origSchemeName) {
      dcc->addScheme(*scm, true); 
      ctl_scheme._lbbottom();
      ctl_scheme._lbadd_item(newSchemeName,60,"");
      ctl_scheme.p_text = newSchemeName;
   } else {
      saved_scm := dcc->getScheme(origSchemeName);
      *saved_scm = *scm;
   }
   scm->saveColorScheme();

   dcc->setModified(false);
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
   scm := getColorScheme();
   if (scm == null) return;

   // only allow them to rename user schemes
   origSchemeName := scm->m_name;
   if (!dcc->isUserScheme(origSchemeName)) {
      _message_box(get_message(VSRC_CFG_CANNOT_FIND_USER_SCHEME, origSchemeName));
      return;
   }

   // prompt the user for a new scheme name
   newSchemeName  := getColorSchemeName(*dcc, origSchemeName);
   if (newSchemeName == "") return;

   scm->m_name = newSchemeName; 
   dcc->addScheme(*scm, true);
   dcc->deleteScheme(origSchemeName);
   ctl_scheme._lbset_item(newSchemeName);
   ctl_scheme.p_text = newSchemeName;
   scm->deleteColorScheme(origSchemeName);
   scm->saveColorScheme();
   dcc->setModified(true);
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
   ctl_scheme.p_text = scm->m_name;
   cfg := getColorId();
   loadScheme(scm->m_name, true);
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
static void _system_default_color_state(boolean useSystemDefault)
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
void ctl_normal.lbutton_up()
{
   // get our current scheme and color info
   scm := getColorScheme();
   color := getColorInfo();
   if (color == null) return;

   // figure out which font attribute changed
   font_flag := 0;
   switch (p_name) {
   case "ctl_normal":       font_flag = 0x0; break;
   case "ctl_bold":         font_flag = F_BOLD; break;
   case "ctl_italic":       font_flag = F_ITALIC; break; 
   case "ctl_underline":    font_flag = F_UNDERLINE; break;
   }

   // first, cut out all the flags
   color->m_fontFlags &= ~(F_BOLD|F_ITALIC|F_UNDERLINE);

   // now add back in the one we selected
   color->m_fontFlags |= font_flag;

   embeddedColor := getEmbeddedColorInfo();
   if (embeddedColor != null) {
      embeddedColor->m_fontFlags = color->m_fontFlags;
   }

   ctl_sample.p_font_underline = (ctl_underline.p_value != 0);
   ctl_sample.p_font_italic = (ctl_italic.p_value != 0);
   ctl_sample.p_font_bold = (ctl_bold.p_value != 0);
   ctl_embedded_sample.p_font_bold      = ctl_sample.p_font_bold;            
   ctl_embedded_sample.p_font_italic    = ctl_sample.p_font_italic;    
   ctl_embedded_sample.p_font_underline = ctl_sample.p_font_underline;
   updateCurrentColor();
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
         if (dcc->isIgnoringChanges()) return;
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
static _str getSampleCode(_str configFile, _str modeName)
{
   if (!file_exists(configFile)) {
      return null;
   }

   handle := _xmlcfg_open(configFile, auto status=0, VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) {
      return null;
   }

   // Look first for exact match.
   int node = _xmlcfg_find_simple(handle, "/CodeSamples/Sample[@Language='":+modeName:+"']");
   if (node < 0) {
      // Look for a "prefix match", because p_mode_name (modeName parameter) may have been truncated to 20 chars.
      // For example "Windows Resource File" is reported from p_mode_name as "Windows Resource Fil"
      node = _xmlcfg_find_simple(handle, "/CodeSamples/Sample[contains(@Language, '":+modeName:+".+', 'U')]");
      if(node < 0) {
         _xmlcfg_close(handle);
         return null;
      }
   }

   cdata := _xmlcfg_get_first_child(handle, node);
   if (cdata < 0) {
      _xmlcfg_close(handle);
      return null;
   }

   text := _xmlcfg_get_value(handle,  cdata);
   _xmlcfg_close(handle);
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

   codeSamplesPath := _ConfigPath();
   _maybe_append_filesep(codeSamplesPath);
   codeSamplesPath :+= CODE_SAMPLES_FILE;
   text := getSampleCode(codeSamplesPath, p_mode_name);
   if (text == null) {
      codeSamplesPath = get_env("VSROOT");
      _maybe_append_filesep(codeSamplesPath);
      codeSamplesPath :+= "sysconfig";
      codeSamplesPath :+= FILESEP;
      codeSamplesPath :+= "color";
      codeSamplesPath :+= FILESEP;
      codeSamplesPath :+= CODE_SAMPLES_FILE;
      text = getSampleCode(codeSamplesPath, p_mode_name);
   }
   if (text != null) {
      text = strip(text, "L", " \t");
      while (first_char(text) == "\n" || first_char(text) == "\r") {
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
   top(); 
   _begin_line();
}

_str _color_form_export_settings(_str &file, _str &schemeName)
{
   error := '';

   // now we combine the user file....
   userSchemes := ColorScheme.getUserColorSchemeFile();
   if (userSchemes != '' && file_exists(userSchemes)) {
      if (copy_file(userSchemes, file :+ VSCFGFILE_USER_COLORSCHEMES)) error = 'Error exporting user color schemes.';
      else file = VSCFGFILE_USER_COLORSCHEMES;
   }

   schemeName = def_color_scheme;

   return error;
}
_str _color_form_import_settings(_str filename, _str schemeName)
{
   error := '';

   userSchemes := ColorScheme.getUserColorSchemeFile();
   sysSchemes  := ColorScheme.getSystemColorSchemeFile();
   if (filename != '') {
      if (!file_exists(userSchemes)) {
         if (copy_file(filename, userSchemes)) error = 'Error copying color schemes.'OPTIONS_ERROR_DELIMITER;
      } else {
         if (_ini_combine_files(userSchemes, filename)) error = 'Error copying color schemes.'OPTIONS_ERROR_DELIMITER;
      }
   }

   // check for the default
   iniSchemeName := schemeName;
   if (iniSchemeName == '(init)') iniSchemeName = 'Default';

   // now we have to rip those schemes out of the INI and apply them...right away!
   if (applyINIScheme(iniSchemeName)) {
      def_color_scheme = schemeName;
   } else {
      error :+= 'Error applying new color scheme,' schemeName'.'OPTIONS_ERROR_DELIMITER;
   }

   return error;
}
static boolean applyINIScheme(_str schemeName)
{
   se.color.ColorScheme scheme;
   status := scheme.loadColorScheme(schemeName);
   if (status < 0) {
      return false;
   }

   scheme.applyColorScheme();
   return true;
}

