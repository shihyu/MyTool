#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "plugin.sh"
#import "se/color/ColorInfo.e"
#import "se/color/IColorCollection.e"
#import "se/color/ColorScheme.e"
#import "se/color/SymbolColorRuleBase.e"
#import "se/ui/NavMarker.e"
#import "cfg.e"
#import "dlgman.e"
#import "ini.e"
#import "stdprocs.e"
#endregion

namespace se.color;

using se.color.ColorScheme;

class OldColorScheme : IColorCollection /*, sc.lang.IEquals*/ {

   /**
    * This is a name for this scheme, for display in the GUI.
    */
   _str m_name;

   /**
    * This is the entire set of colors, indexed by the CFG_* 
    * color constants. 
    */
   ColorInfo m_colors[];

   /**
    * This is the set of colors for embedded code, also indexed by 
    * the CFG_* color constants.  Note that although we store 
    * complete color information for each embedded color, as of 
    * SlickEdit 2009, we only use the embedded background color. 
    */
   ColorInfo m_embedded[];

   /**
    * This is the recommended symbol coloring scheme to use with
    * this syntax coloring scheme.
    */
   _str m_symbolColoringSchemeName;

   OldColorScheme(_str name = "") {
      m_name = name;
      m_colors = null;
      m_embedded = null;
      m_symbolColoringSchemeName = null;
   }

   static bool shouldInheritBG(int cfg) {
      switch (cfg) {
      case CFG_COMMENT:
      case CFG_FUNCTION:
      case CFG_KEYWORD:
      case CFG_LIBRARY_SYMBOL:
      case CFG_LINENUM:
      case CFG_NUMBER:
      case CFG_OPERATOR:
      case CFG_PPKEYWORD:
      case CFG_PUNCTUATION:
      case CFG_SPECIALCHARS:
      case CFG_STRING:
      case CFG_USER_DEFINED:
      case CFG_ATTRIBUTE:
      case CFG_UNKNOWN_ATTRIBUTE:
      //case CFG_UNKNOWNXMLELEMENT:
      case CFG_XHTMLELEMENTINXSL:
      case CFG_SYMBOL_HIGHLIGHT:
      case CFG_BLOCK_MATCHING:
      case CFG_LINE_COMMENT:
      case CFG_DOCUMENTATION:
      case CFG_DOC_PUNCTUATION:
      case CFG_DOC_ATTRIBUTE:
      case CFG_DOC_ATTR_VALUE:
      case CFG_IDENTIFIER:
      case CFG_IDENTIFIER2:
      case CFG_FLOATING_NUMBER:
      case CFG_HEX_NUMBER:
      case CFG_SINGLEQUOTED_STRING:
      case CFG_BACKQUOTED_STRING:
      case CFG_INACTIVE_CODE:
      case CFG_INACTIVE_KEYWORD:
      case CFG_INACTIVE_COMMENT:
      case CFG_XML_CHARACTER_REF:
      case CFG_MARKDOWN_HEADER:
      case CFG_MARKDOWN_CODE:
      case CFG_MARKDOWN_BLOCKQUOTE:
      case CFG_MARKDOWN_LINK:
      case CFG_MARKDOWN_LINK2:
      case CFG_MARKDOWN_BULLET:
      case CFG_MARKDOWN_EMPHASIS:
      case CFG_MARKDOWN_EMPHASIS2:
      case CFG_MARKDOWN_EMPHASIS3:
      case CFG_MARKDOWN_EMPHASIS4:
      case CFG_CSS_ELEMENT:
      case CFG_CSS_CLASS:
      case CFG_CSS_PROPERTY:
      case CFG_CSS_SELECTOR:
      case CFG_YAML_TEXT_COLON:
      case CFG_YAML_TEXT:
      case CFG_YAML_TAG:
      case CFG_YAML_DIRECTIVE:
      case CFG_YAML_ANCHOR_DEF:
      case CFG_YAML_ANCHOR_REF:
      case CFG_YAML_PUNCTUATION:
      case CFG_YAML_OPERATOR:
         return true;
      default:
         return false;
      }

   }
   static int adjustEmbeddedBackgroundColor(int rgb) {

      r := (rgb & 0xFF);
      rgb = rgb intdiv 256;
      g := (rgb & 0xFF);
      rgb = rgb intdiv 256;
      b := (rgb & 0xFF);
      
      if (r+g+b < 255) {
         // dark scheme, go lighter (charcoal)
         r += 48; if (r > 255) r = 255;
         g += 48; if (g > 255) g = 255;
         b += 48; if (b > 255) b = 255;
      } else {
         // light scheme, go darker (gray)
         r -= 48; if (r < 0) r = 0;
         g -= 48; if (g < 0) g = 0;
         b -= 48; if (b < 0) b = 0;
      }
      return _rgb(r,g,b);
   }

   /**
    * Fill in missing values for the embedded color scheme.
    */
   void updateColorScheme(int old_version) {

      // use window text color for any missing colors
      i:=0;
      windowText := m_colors[CFG_WINDOW_TEXT];
      for (i=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
         if (ColorScheme.getColorNameRC(i) == 0) continue;
         if (i >= m_colors._length() || m_colors[i] == null) {
            m_colors[i] = windowText;
         }
      }

      // Colors that changes after SlickEdit release 10.0
      if (old_version < COLOR_SCHEME_VERSION_SPECIAL_CHARS) {
         if (m_colors[CFG_SPECIALCHARS] == windowText) { 
            // light gray
            m_colors[CFG_SPECIALCHARS].m_foreground = _rgb(0xC0,0xC0,0xC0);
         }
         if (m_colors[CFG_CURRENT_LINE_BOX] == windowText) {
            // bright blue
            m_colors[CFG_CURRENT_LINE_BOX].m_foreground = _rgb(0x80,0x80,0xFF);
         }
         if (m_colors[CFG_VERTICAL_COL_LINE] == windowText) {
            // light red
            m_colors[CFG_VERTICAL_COL_LINE].m_foreground = _rgb(0xFF,0x80,0x80);
         }
         if (m_colors[CFG_MARGINS_COL_LINE] == windowText) {
            // medium gray
            m_colors[CFG_MARGINS_COL_LINE].m_foreground = _rgb(0x80,0x80,0x80);
         }
         if (m_colors[CFG_PREFIX_AREA_LINE] == windowText) {
            // light gray
            m_colors[CFG_PREFIX_AREA_LINE].m_foreground = _rgb(0xC0,0xC0,0xC0);
         }
      }

      // Colors that changes after SlickEdit release 11.0
      if (old_version < COLOR_SCHEME_VERSION_BLOCK_MATCHING) {
         if (m_colors[CFG_BLOCK_MATCHING] == windowText) {
            // blue and bold
            m_colors[CFG_BLOCK_MATCHING].m_foreground = _rgb(0x00,0x00,0xFF);
            m_colors[CFG_BLOCK_MATCHING].m_fontFlags = F_BOLD;
         }
         if (m_colors[CFG_INC_SEARCH_CURRENT] == windowText) {
            // black on cyan
            m_colors[CFG_INC_SEARCH_CURRENT].m_foreground = _rgb(0x00,0x00,0x00);
            m_colors[CFG_INC_SEARCH_CURRENT].m_background = _rgb(0x80,0xFF,0xFF);
            m_embedded[CFG_INC_SEARCH_CURRENT].m_foreground = _rgb(0x00,0x00,0x00);
            m_embedded[CFG_INC_SEARCH_CURRENT].m_background = _rgb(0x50,0xD0,0xD0);
         }
         if (m_colors[CFG_INC_SEARCH_MATCH] == windowText) {
            // black on yellow
            m_colors[CFG_INC_SEARCH_MATCH].m_foreground = _rgb(0x00,0x00,0x00);
            m_colors[CFG_INC_SEARCH_MATCH].m_background = _rgb(0xFF,0xFF,0x80);
            m_embedded[CFG_INC_SEARCH_MATCH].m_foreground = _rgb(0x00,0x00,0x00);
            m_embedded[CFG_INC_SEARCH_MATCH].m_background = _rgb(0xD0,0xD0,0x50);
         }
         if (m_colors[CFG_HEX_MODE_COLOR] == windowText) {
            // light gray
            m_colors[CFG_HEX_MODE_COLOR].m_foreground = _rgb(0x80,0x00,0x00);
            m_colors[CFG_INC_SEARCH_MATCH].m_background = _rgb(0xF0,0xF0,0xF0);
            m_embedded[CFG_HEX_MODE_COLOR].m_foreground = _rgb(0x00,0x00,0x00);
            m_embedded[CFG_HEX_MODE_COLOR].m_background = _rgb(0xD0,0xD0,0xD0);
         }
         if (m_colors[CFG_SYMBOL_HIGHLIGHT] == windowText) {
            // bright blue
            m_colors[CFG_SYMBOL_HIGHLIGHT].m_foreground = _rgb(0x00,0x00,0xFF);
         }
      }

      // No new colors in SlickEdit 2007
      //  
      // Colors that changed for SlickEdit 2008
      if (old_version < COLOR_SCHEME_VERSION_FILE_TABS) {
         if (m_colors[CFG_MODIFIED_FILE_TAB] == windowText) {
            m_colors[CFG_MODIFIED_FILE_TAB].m_foreground = _rgb(0xFF,0x00,0x00);
            m_colors[CFG_MODIFIED_FILE_TAB].m_background = _rgb(0xFF,0xFF,0xFF);
         }
      }

      // calculate the embedded window text color
      embeddedText := m_embedded[CFG_WINDOW_TEXT];
      if (embeddedText == null || old_version < COLOR_SCHEME_VERSION_EMBEDDED_CHANGES) {
         embeddedText = windowText;
         rgb := embeddedText.getBackgroundColor();
         embeddedText.m_background = adjustEmbeddedBackgroundColor(rgb);
         m_embedded[CFG_WINDOW_TEXT] = embeddedText;
      }

      // Colors added for SlickEdit 2009
      if (old_version < COLOR_SCHEME_VERSION_EMBEDDED_CHANGES) {

         // tint non-embedded scheme's background color for missing
         // embedded colors.
         mismatchDetected := false;
         for (i=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
            if (!ColorScheme.isEmbeddedColor(i)) continue;
            if (i >= m_embedded._length() && m_colors[i] != null) {
               m_embedded[i] = m_colors[i];
               m_embedded[i].m_background = adjustEmbeddedBackgroundColor(m_colors[i].getBackgroundColor(&this));
               mismatchDetected = true;
               continue;
            }
            if (m_embedded[i] == null) continue;
            if (m_embedded[i].m_fontFlags != m_colors[i].m_fontFlags) {
               m_embedded[i].m_fontFlags = m_colors[i].m_fontFlags;
               mismatchDetected = true;
            }
            if (m_embedded[i].m_foreground != m_colors[i].m_foreground) {
               m_embedded[i].m_foreground = m_colors[i].m_foreground;
               mismatchDetected = true;
            }
         }
   
         // check if any of the colors use inheritance, assume that if none of
         // them do, then this is an old-style color scheme and add the default
         // inheritance parameters for colors whose backgrounds match window text.
         numInheriting := 0;
         for (i=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
            if (ColorScheme.getColorNameRC(i) == 0) continue;
            if (m_colors[i].m_fontFlags & F_INHERIT_BG_COLOR) {
               numInheriting++;
            }
         }
         if (numInheriting == 0) {
            for (i=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
               if (shouldInheritBG(i)) {
                  if (m_colors[i].m_background == m_colors[CFG_WINDOW_TEXT].m_background) {
                     m_colors[i].m_fontFlags |= F_INHERIT_BG_COLOR;
                     m_embedded[i].m_fontFlags = m_colors[i].m_fontFlags;
                  }
               }
            }
         }
      }

      // Colors that changed for SlickEdit 2009, 14.0.2 patch
      if (old_version < COLOR_SCHEME_VERSION_MODIFIED_ITEM) {
         if (m_colors[CFG_MODIFIED_ITEM] == windowText) {
            m_colors[CFG_MODIFIED_ITEM].m_foreground = _rgb(0xFF,0x00,0x00);
            m_colors[CFG_MODIFIED_ITEM].m_background = _rgb(0xFF,0xFF,0xFF);
         }
      }


      // Colors add SlickEdit 2010
      if (old_version < COLOR_SCHEME_VERSION_NAVHINT) {
         //Set default color to orange
         m_colors[CFG_NAVHINT].m_foreground = _rgb(0xFF,0x80,0x00);
      }

      // double check that they have all the embedded colors
      // this should have happened above, but maybe something went badly.
      for (i=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
         if (ColorScheme.getColorNameRC(i) == 0) continue;
         if (!ColorScheme.isEmbeddedColor(i)) continue;
         if (i >= m_embedded._length() || m_embedded[i] == null) {
            if (i < m_colors._length() && m_colors[i] != null) {
               m_embedded[i] = m_colors[i];
            } else {
               m_embedded[i] = embeddedText;
            }
            m_embedded[i].m_fontFlags |= F_INHERIT_BG_COLOR;
         }
      }

      // just set line documentation colors to same color as regular comments
      if (old_version < COLOR_SCHEME_VERSION_COMMENT_COLORS) {
         m_colors[CFG_LINE_COMMENT]  = m_colors[CFG_COMMENT];
         m_colors[CFG_DOCUMENTATION] = m_colors[CFG_COMMENT];
         m_colors[CFG_DOC_KEYWORD] = m_colors[CFG_COMMENT];
         m_colors[CFG_DOC_KEYWORD].m_fontFlags |= F_BOLD;
         m_colors[CFG_DOC_KEYWORD].m_fontFlags &= ~(F_ITALIC|F_UNDERLINE);
         m_colors[CFG_DOC_PUNCTUATION] = m_colors[CFG_DOC_KEYWORD];
         m_colors[CFG_DOC_ATTRIBUTE] = m_colors[CFG_DOC_KEYWORD];
         m_colors[CFG_DOC_ATTR_VALUE] = m_colors[CFG_DOC_KEYWORD];
         m_colors[CFG_DOC_ATTR_VALUE].m_fontFlags &= ~(F_BOLD);
         m_colors[CFG_IDENTIFIER] = m_colors[CFG_WINDOW_TEXT];
         m_colors[CFG_IDENTIFIER].m_fontFlags |= F_INHERIT_BG_COLOR;
         m_colors[CFG_IDENTIFIER2] = m_colors[CFG_WINDOW_TEXT];
         m_colors[CFG_IDENTIFIER2].m_fontFlags |= F_INHERIT_BG_COLOR;
         m_colors[CFG_FLOATING_NUMBER] = m_colors[CFG_NUMBER];
         m_colors[CFG_HEX_NUMBER] = m_colors[CFG_NUMBER];
         m_colors[CFG_SINGLEQUOTED_STRING] = m_colors[CFG_STRING];
         m_colors[CFG_BACKQUOTED_STRING] = m_colors[CFG_STRING];
         m_colors[CFG_UNTERMINATED_STRING] = m_colors[CFG_STRING];

         m_embedded[CFG_LINE_COMMENT] = m_embedded[CFG_COMMENT];
         m_embedded[CFG_DOCUMENTATION] = m_embedded[CFG_COMMENT];
         m_embedded[CFG_DOC_KEYWORD] = m_embedded[CFG_COMMENT];
         m_embedded[CFG_DOC_KEYWORD].m_fontFlags |= F_BOLD;
         m_embedded[CFG_DOC_KEYWORD].m_fontFlags &= ~(F_ITALIC|F_UNDERLINE);
         m_embedded[CFG_DOC_PUNCTUATION] = m_embedded[CFG_DOC_KEYWORD];
         m_embedded[CFG_DOC_ATTRIBUTE] = m_embedded[CFG_DOC_KEYWORD];
         m_embedded[CFG_DOC_ATTR_VALUE] = m_embedded[CFG_DOC_KEYWORD];
         m_embedded[CFG_DOC_ATTR_VALUE].m_fontFlags &= ~(F_BOLD);
         m_embedded[CFG_IDENTIFIER] = m_embedded[CFG_WINDOW_TEXT];
         m_embedded[CFG_IDENTIFIER].m_fontFlags |= F_INHERIT_BG_COLOR;
         m_embedded[CFG_IDENTIFIER2] = m_embedded[CFG_WINDOW_TEXT];
         m_embedded[CFG_IDENTIFIER2].m_fontFlags |= F_INHERIT_BG_COLOR;
         m_embedded[CFG_FLOATING_NUMBER] = m_embedded[CFG_NUMBER];
         m_embedded[CFG_HEX_NUMBER] = m_embedded[CFG_NUMBER];
         m_embedded[CFG_SINGLEQUOTED_STRING] = m_embedded[CFG_STRING];
         m_embedded[CFG_BACKQUOTED_STRING] = m_embedded[CFG_STRING];
         m_embedded[CFG_UNTERMINATED_STRING] = m_embedded[CFG_STRING];
      }

      if (old_version < COLOR_SCHEME_VERSION_INACTIVE_COLORS) {
         m_colors[CFG_INACTIVE_CODE] = m_colors[CFG_WINDOW_TEXT];
         m_colors[CFG_INACTIVE_CODE].m_fontFlags = F_INHERIT_BG_COLOR;
         m_colors[CFG_INACTIVE_CODE].m_foreground = 0x808080;
         m_colors[CFG_INACTIVE_KEYWORD] = m_colors[CFG_INACTIVE_CODE];
         m_colors[CFG_INACTIVE_KEYWORD].m_fontFlags = F_BOLD|F_INHERIT_BG_COLOR;
         m_colors[CFG_IMAGINARY_SPACE] = m_colors[CFG_IMAGINARY_LINE];

         m_embedded[CFG_INACTIVE_CODE] = m_embedded[CFG_WINDOW_TEXT];
         m_embedded[CFG_INACTIVE_CODE].m_fontFlags = F_INHERIT_BG_COLOR;
         m_embedded[CFG_INACTIVE_CODE].m_foreground = 0x808080;
         m_embedded[CFG_INACTIVE_KEYWORD] = m_embedded[CFG_INACTIVE_CODE];
         m_embedded[CFG_INACTIVE_KEYWORD].m_fontFlags = F_BOLD|F_INHERIT_BG_COLOR;
         m_embedded[CFG_IMAGINARY_SPACE] = m_embedded[CFG_IMAGINARY_LINE];
      }

      if (old_version < COLOR_SCHEME_VERSION_INACTIVE_COMMENT) {
         m_colors[CFG_INACTIVE_COMMENT] = m_colors[CFG_INACTIVE_CODE];
         m_colors[CFG_INACTIVE_COMMENT].m_fontFlags = F_ITALIC|F_INHERIT_BG_COLOR;
         m_embedded[CFG_INACTIVE_COMMENT] = m_embedded[CFG_INACTIVE_CODE];
         m_embedded[CFG_INACTIVE_COMMENT].m_fontFlags = F_ITALIC|F_INHERIT_BG_COLOR;
      }

      if (old_version < COLOR_SCHEME_VERSION_XML_CHARACTER_REF) {
         m_colors[CFG_XML_CHARACTER_REF] = m_colors[CFG_HEX_NUMBER];
         m_embedded[CFG_XML_CHARACTER_REF] = m_embedded[CFG_HEX_NUMBER];
      }

      if (old_version < COLOR_SCHEME_VERSION_SELECTIVE_DISPLAY) {
         m_colors[CFG_SELECTIVE_DISPLAY_LINE].m_foreground = _rgb(0xB0,0xC0,0xB0);
         m_colors[CFG_SELECTIVE_DISPLAY_LINE].m_foreground = _rgb(0xB0,0xC0,0xB0);
         m_embedded[CFG_SELECTIVE_DISPLAY_LINE].m_foreground = _rgb(0xB0,0xC0,0xB0);
         m_embedded[CFG_SELECTIVE_DISPLAY_LINE].m_foreground = _rgb(0xB0,0xC0,0xB0);
      }
   }
   void fix_some_colors() {
      if (strieq(m_name,'Default')) {
         // Fetch built-in value
         handle:=_plugin_get_property_xml(VSCFGPACKAGE_COLOR_PROFILES,m_name,'xml_character_ref',null,1);
         if (handle>=0) {
            property_node:=_xmlcfg_get_first_child_element(handle);
            if (property_node>=0) {
               attrs_node:=property_node;
               if (attrs_node>=0) {
                  typeless fg,bg,flags;
                  bg=_xmlcfg_get_attribute(handle,attrs_node,'bg');
                  fg=_xmlcfg_get_attribute(handle,attrs_node,'fg');
                  flags=_xmlcfg_get_attribute(handle,attrs_node,'flags');
                  if (bg!='' && fg!='' && flags!='') {
                     bg=_hex2dec(bg);
                     fg=_hex2dec(fg);
                     flags=_hex2dec(flags);
                     m_colors[CFG_XML_CHARACTER_REF].m_foreground=fg;
                     m_colors[CFG_XML_CHARACTER_REF].m_background=bg;
                     m_colors[CFG_XML_CHARACTER_REF].m_fontFlags=flags;
                  }
               }
               _xmlcfg_close(handle);
            }
         }
         handle=_plugin_get_property_xml(VSCFGPACKAGE_COLOR_PROFILES,m_name,'error',null,1);
         if (handle>=0) {
            property_node:=_xmlcfg_get_first_child_element(handle);
            if (property_node>=0) {
               attrs_node:=property_node;
               if (attrs_node>=0) {
                  typeless embg,flags;
                  flags=_xmlcfg_get_attribute(handle,attrs_node,'flags');
                  embg=_xmlcfg_get_attribute(handle,attrs_node,'embg');
                  if (embg!='' && flags!='') {
                     flags=_hex2dec(flags);
                     m_colors[CFG_ERROR].m_fontFlags=flags;
                     embg=_hex2dec(embg);
                     //m_embedded[CFG_ERROR].m_foreground=embg;
                     m_embedded[CFG_ERROR].m_background=embg;
                     //m_embedded[CFG_ERROR].m_fontFlags=flags;
                  }
               }
               _xmlcfg_close(handle);
            }
         }
      }
   }
   /**
    * Load the user's current color scheme.
    */
   void loadCurrentColorScheme() {
      m_name = ColorScheme.getDefaultProfile();
      m_colors = null;
      m_embedded = null;
      for (cfg:=1; cfg<=CFG_LAST_DEFAULT_COLOR; cfg++) {
         // make sure this is a valid / interesting color
         if (ColorScheme.getColorNameRC(cfg) == 0) {
            m_colors[cfg] = null;
            m_embedded[cfg] = null;
            continue;
         }
         // get standard colors
         ColorInfo c;
         c.getColor(cfg);
         m_colors[cfg] = c;
         // also get embedded colors
         if (!ColorScheme.isEmbeddedColor(cfg)) {
            m_embedded[cfg] = null;
            continue;
         }
         ColorInfo e;
         e.getColor(-cfg);
         e.m_fontFlags = c.m_fontFlags;
         m_embedded[cfg] = e;
      }
      m_symbolColoringSchemeName = null;
      if (def_symbol_color_profile != "" && def_symbol_color_profile != CONFIG_AUTOMATIC) {
         m_symbolColoringSchemeName = def_symbol_color_profile;
      } else {
         associated_symbol_profile := _plugin_get_property(VSCFGPACKAGE_COLOR_PROFILES,m_name,'associated_symbol_profile');
         if (associated_symbol_profile!='') {
            m_symbolColoringSchemeName=associated_symbol_profile;
         }
      }
      fix_some_colors();
   }

   /**
    * Load the given color scheme from the INI file.
    *
    * @param fileName       File to load color scheme from
    * @param schemeName     Name of color scheme to find and load
    *
    * @return 0 on success, <0 on error.
    */
   int loadScheme(_str fileName,  _str schemeName) {

       // load the color scheme information
       status := _ini_get_section_array(fileName, schemeName, auto colors);
       if (status) {
          return status;
       }

       // initialize the entire color list
       m_colors = null;
       m_embedded = null;
       m_name = schemeName;

       // watch for the scheme version
       colorSchemeVersion := COLOR_SCHEME_VERSION_PREHISTORIC;
       bool visitedColors[] = null;

       // parse out the colors for this scheme
       foreach (auto colorInfo in colors) {
          parse colorInfo with auto key'='auto value;

          // handle special case for associated color scheme
          if (key == "ASSOCIATED_SYMBOL_SCHEME") {
             m_symbolColoringSchemeName = value;
             continue;
          }

          // handle special case for color scheme version
          if (key == "VERSION" && isinteger(value)) {
             colorSchemeVersion = (ColorSchemeVersion) value;
             continue;
          }

          // extract the color id and the fg/bg/flag
          constantName := substr(key, 1, length(key) - 2);
          colorId := _const_value(constantName);
          if (!isinteger(colorId) || colorId <= 0 || colorId > CFG_LAST_DEFAULT_COLOR) {
             continue;
          }

          ColorInfo *c = &m_colors[colorId];
          colorAttribute := substr(key, length(key) - 1);
          switch (colorAttribute) {
          case "bg":
             c->m_background = _hex2dec(value);
             break;
          case "fg":
             c->m_foreground = _hex2dec(value);
             break;
          case "ff":
             c->m_fontFlags = _hex2dec(value);
             break;
          case "em":
             ColorInfo *ec = &m_embedded[colorId];
             ec->m_foreground = c->m_foreground;
             ec->m_fontFlags = c->m_fontFlags;
             ec->m_background = _hex2dec(value);
             break;
          }
       }

       defaultText := m_colors[CFG_WINDOW_TEXT];
       defaultEmbedded := m_embedded[CFG_WINDOW_TEXT];
       // null out colors that are not part of this scheme
       for (i := 1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
          if (ColorScheme.getColorNameRC(i) == 0) {
             m_colors[i] = null;
             m_embedded[i] = null;
             continue;
          }
          if (!ColorScheme.isEmbeddedColor(i)) {
             m_embedded[i] = null;
          }
          if (m_colors[i] == null) {
             m_colors[i] = defaultText;
             // reminder for devs
             //say('WARNING: loadScheme['schemeName']: m_colors['i':'getColorName(i)']=null (NOT defined in default scheme: 'fileName')');
          }
          if (m_embedded[i] == null) {
             m_embedded[i] = defaultEmbedded;
          }
          // make sure there are no colors with foreground or font inheritance
          if (m_colors[i] != null)   m_colors[i].m_fontFlags   &= ~(F_INHERIT_FG_COLOR|F_INHERIT_STYLE);
          if (m_embedded[i] != null) m_embedded[i].m_fontFlags &= ~(F_INHERIT_FG_COLOR|F_INHERIT_STYLE);
       }

       // if the color scheme is out of date, update it
       if (colorSchemeVersion < COLOR_SCHEME_VERSION_CURRENT) {
          updateColorScheme(colorSchemeVersion);
       }
       fix_some_colors();

       // that's all folks
       return 0;
   }
   ////////////////////////////////////////////////////////////////////////
   // interface IColorCollection
   ////////////////////////////////////////////////////////////////////////
   /**
    * @return
    * Return a pointer to the color information object associated with
    * the given color name.  Color names do not have to be universally
    * unique, only unique within this collection.
    * <p>
    * Return null if there is no such color or if this collection does
    * not index colors by name.
    *
    * @param name    color name
    */
   ColorInfo *getColorByName(_str colorName) {
      if (colorName == null || colorName=="") {
         return &m_colors[CFG_WINDOW_TEXT];
      }
      isEmbedded := false;
      if (_first_char(colorName)=='-') {
         isEmbedded = true;
         colorName = substr(colorName, 2);
      }
      cfg := ColorScheme.getColorIndexByName(colorName);
      if (isEmbedded) {
         if (cfg < 0 || cfg >= m_embedded._length()) {
            return null;
         }
         return &m_embedded[cfg];
      } else {
         if (cfg < 0 || cfg >= m_colors._length()) {
            return null;
         }
         return &m_colors[cfg];
      }
   }

};

static void convert_old_vsscheme_ini(_str filename) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   OldColorScheme oldProfile;
   ColorScheme profile;
   top();up();
   status=search('^\[','@r');
   while (!status) {
      get_line(auto line);
      parse line with '[' auto profileName ']';
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      oldProfile.loadScheme(filename,profileName);
      profile.initAllMembers(
         oldProfile.m_name,
         oldProfile.m_colors,
         oldProfile.m_embedded,
         oldProfile.m_symbolColoringSchemeName);
      profile.saveProfile();
      restore_search(s1,s2,s3,s4,s5);
      status=repeat_search();
   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;


}

defmain()
{
   args:=arg(1);
   filename:=parse_file(args,true);
   if (filename=='""') {
      OldColorScheme oldProfile;
      ColorScheme profile;
      oldProfile.loadCurrentColorScheme();
      profile.initAllMembers(
         oldProfile.m_name,
         oldProfile.m_colors,
         oldProfile.m_embedded,
         oldProfile.m_symbolColoringSchemeName);
      profile.saveProfile();
      return 0;
      
   } else if (filename=='') {
      filename=p_buf_name;
   } else {
      filename=strip(filename,'B','"');
   }
   convert_old_vsscheme_ini(filename);

}
