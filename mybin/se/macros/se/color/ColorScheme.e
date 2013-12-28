////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50269 $
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
#require "sc/lang/IEquals.e"
#require "se/color/ColorInfo.e"
#require "se/color/IColorCollection.e"
#import "se/color/SymbolColorConfig.e"
#import "se/color/SymbolColorAnalyzer.e"
#import "dlgman.e"
#import "ini.e"
#import "main.e"
#import "math.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#require "se/ui/NavMarker.e"
#endregion

/**
 * Version number for the current color settings. This 
 * allows us to detect when a user has an older color 
 * scheme and update it with new color settings as needed.
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_color_scheme_version = 0;

/**
 * This is the current color scheme version number.
 */
enum {
   // default, virgin SlickEdit configuration
   COLOR_SCHEME_VERSION_DEFAULT = 0,

   // any migrated color scheme from user's vusrdefs.e (probably incomplete) 
   COLOR_SCHEME_VERSION_PREHISTORIC,

   // Epoch colors added from previous releases 
   COLOR_SCHEME_VERSION_SPECIAL_CHARS = 10,     // colors added in 10.0
   COLOR_SCHEME_VERSION_BLOCK_MATCHING = 11,    // colors added in 12.0
   COLOR_SCHEME_VERSION_FILE_TABS = 13,         // added in 13.0.2
   COLOR_SCHEME_VERSION_EMBEDDED_CHANGES = 14,  // added in 14.0.0
   COLOR_SCHEME_VERSION_COMMENT_COLORS,
   COLOR_SCHEME_VERSION_INACTIVE_COLORS,
   COLOR_SCHEME_VERSION_INHERIT_COLORS,
   COLOR_SCHEME_VERSION_INACTIVE_COMMENT,
   COLOR_SCHEME_VERSION_MODIFIED_ITEM,
   COLOR_SCHEME_VERSION_NAVHINT,
   COLOR_SCHEME_VERSION_XML_CHARACTER_REF,
   COLOR_SCHEME_VERSION_MARKDOWN,

   // keep up with the latest color scheme version number
   COLOR_SCHEME_VERSION_LAST_PLUS_ONE,
   COLOR_SCHEME_VERSION_CURRENT = (COLOR_SCHEME_VERSION_LAST_PLUS_ONE-1),
};

/**
 * Update the user's color scheme if it is out of date.
 */
void _UpgradeColorScheme()
{
   if (def_color_scheme_version != COLOR_SCHEME_VERSION_DEFAULT &&
       def_color_scheme_version < COLOR_SCHEME_VERSION_CURRENT) {
      se.color.ColorScheme scm;
      scm.loadCurrentColorScheme();
      scm.updateColorScheme(def_color_scheme_version);
      scm.applyColorScheme();
   }

   // remove the (modified) if it's there
   parse def_color_scheme with auto schemeName ' (modified)';
   if (schemeName != '') def_color_scheme = schemeName;
}


/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information
 * within SlickEdit.
 */
namespace se.color;

using namespace se.ui.AutoBracketMarker;
/**
 * The ColorScheme class is used to describe one SlickEdit syntax
 * coloring scheme, including embedded colors.
 */
class ColorScheme : IColorCollection, sc.lang.IEquals {

   /**
    * This is a name for this scheme, for display in the GUI.
    */
   _str m_name;

   /**
    * This is the entire set of colors, indexed by the CFG_* 
    * color constants. 
    */
   private ColorInfo m_colors[];

   /**
    * This is the set of colors for embedded code, also indexed by 
    * the CFG_* color constants.  Note that although we store 
    * complete color information for each embedded color, as of 
    * SlickEdit 2009, we only use the embedded background color. 
    */
   private ColorInfo m_embedded[];

   /**
    * This is the recommended symbol coloring scheme to use with
    * this syntax coloring scheme.
    */
   _str m_symbolColoringSchemeName;

   /**
    * Construct a symbol color rule base.
    */
   ColorScheme(_str name = "") {
      m_name = name;
      m_colors = null;
      m_embedded = null;
      m_symbolColoringSchemeName = null;
   }

   /**
    * Modify a color in this color scheme.
    *
    * @param cfg        color index (CFG_*)
    *                   use negative numbers for embedded
    * @param color      color information
    *
    * @return 0 on success, <0 on error.
    */
   void setColor(int cfg, ColorInfo &color) {
      if (cfg < 0) {
         m_embedded[-cfg] = color;
      } else {
         m_colors[cfg] = color;
      }
   }

   /**
    * Modify a color in the embedded portion of this color scheme.
    *
    * @param cfg        color index (CFG_*)
    *                   use negative numbers for embedded
    * @param color      color information
    *
    * @return 0 on success, <0 on error.
    */
   void setEmbeddedColor(int cfg, ColorInfo &color) {
      m_embedded[cfg] = color;
   }

   /**
    * @return Return the total number of colors in this scheme.
    */
   int getNumColors() {
      return m_colors._length() + m_embedded._length();
   }

   /**
    * Return a pointer to the color information for the given item.
    *
    * @param cfg        color index (CFG_*)
    *                   use negative numbers for embedded
    *
    * @return ColorInfo* on success, null if no such color
    */
   ColorInfo *getColor(int cfg) {
      if (cfg < 0 && -cfg < m_embedded._length()) {
         return &m_embedded[-cfg];
      }
      if (cfg > 0 && cfg < m_colors._length()) {
         return &m_colors[cfg];
      }
      return null;
   }

   /**
    * Return a pointer to the color information for the given item 
    * in the embedded portion of the color scheme. 
    *
    * @param cfg        color index (CFG_*)
    *                   use negative numbers for embedded
    *
    * @return ColorInfo* on success, null if no such color
    */
   ColorInfo *getEmbeddedColor(int cfg) {
      if (cfg < m_embedded._length()) {
         return &m_embedded[cfg];
      }
      return null;
   }

   /**
    * Is the given color ID a significant embedded color?
    */
   static boolean isEmbeddedColor(int cfg) {
      switch (cfg) {
      case CFG_CLINE:
      case CFG_CURSOR:
      case CFG_SELECTION:
      case CFG_SELECTED_CLINE:
      case CFG_WINDOW_TEXT:
      case CFG_ERROR:
      case CFG_MODIFIED_LINE:
      case CFG_INSERTED_LINE:
      case CFG_KEYWORD:
      case CFG_LINENUM:
      case CFG_NUMBER:
      case CFG_STRING:
      case CFG_COMMENT:
      case CFG_PPKEYWORD:
      case CFG_PUNCTUATION:
      case CFG_LIBRARY_SYMBOL:
      case CFG_OPERATOR:
      case CFG_USER_DEFINED:
      case CFG_NOSAVE_LINE:
      case CFG_FUNCTION:
      case CFG_FILENAME:
      case CFG_HILIGHT:
      case CFG_ATTRIBUTE:
      case CFG_UNKNOWNXMLELEMENT:
      case CFG_XHTMLELEMENTINXSL:
      case CFG_SPECIALCHARS:
      case CFG_BLOCK_MATCHING:
      case CFG_INC_SEARCH_CURRENT:
      case CFG_INC_SEARCH_MATCH:
      case CFG_HEX_MODE_COLOR:
      case CFG_SYMBOL_HIGHLIGHT:
      case CFG_LINE_COMMENT:
      case CFG_DOCUMENTATION:
      case CFG_DOC_KEYWORD:
      case CFG_DOC_PUNCTUATION:
      case CFG_DOC_ATTRIBUTE:
      case CFG_DOC_ATTR_VALUE:
      case CFG_IDENTIFIER:
      case CFG_FLOATING_NUMBER:
      case CFG_HEX_NUMBER:
      case CFG_SINGLEQUOTED_STRING:
      case CFG_BACKQUOTED_STRING:
      case CFG_UNTERMINATED_STRING:
      case CFG_INACTIVE_CODE:
      case CFG_INACTIVE_KEYWORD:
      case CFG_INACTIVE_COMMENT:
      case CFG_IMAGINARY_SPACE:
      case CFG_XML_CHARACTER_REF:
      case CFG_MARKDOWN_HEADER:
      case CFG_MARKDOWN_CODE:
      case CFG_MARKDOWN_BLOCKQUOTE:
      case CFG_MARKDOWN_LINK:
         return true;
      default:
         return false;
      }
   }

   /**
    * @return
    * Return the message code for the given color's name.
    * 
    * @param cfg  color ID 
    */
   int getColorNameRC(int cfg)
   {
      switch (cfg) {
      case CFG_SELECTION:                  return VSRC_CFG_SELECTION;
      case CFG_WINDOW_TEXT:                return VSRC_CFG_WINDOW_TEXT;
      case CFG_CLINE:                      return VSRC_CFG_CURRENT_LINE;
      case CFG_SELECTED_CLINE:             return VSRC_CFG_SELECTED_CURRENT_LINE;
      case CFG_MESSAGE:                    return VSRC_CFG_MESSAGE;
      case CFG_STATUS:                     return VSRC_CFG_STATUS;
      case CFG_CURSOR:                     return VSRC_CFG_CURSOR;
      case CFG_ERROR:                      return VSRC_CFG_ERROR;
      case CFG_MODIFIED_LINE:              return VSRC_CFG_MODIFIED_LINE;
      case CFG_INSERTED_LINE:              return VSRC_CFG_INSERTED_LINE;
      case CFG_KEYWORD:                    return VSRC_CFG_KEYWORD;
      case CFG_LINENUM:                    return VSRC_CFG_LINE_NUMBER;
      case CFG_NUMBER:                     return VSRC_CFG_NUMBER;
      case CFG_STRING:                     return VSRC_CFG_STRING;
      case CFG_COMMENT:                    return VSRC_CFG_COMMENT;
      case CFG_PPKEYWORD:                  return VSRC_CFG_PREPROCESSOR;
      case CFG_PUNCTUATION:                return VSRC_CFG_PUNCTUATION;
      case CFG_LIBRARY_SYMBOL:             return VSRC_CFG_LIBRARY_SYMBOL;
      case CFG_OPERATOR:                   return VSRC_CFG_OPERATOR;
      case CFG_USER_DEFINED:               return VSRC_CFG_USER_DEFINED_SYMBOL;
      case CFG_NOSAVE_LINE:                return VSRC_CFG_NOSAVE_LINE;
      case CFG_FUNCTION:                   return VSRC_CFG_FUNCTION;
      case CFG_LINEPREFIXAREA:             return VSRC_CFG_LINE_PREFIX_AREA;
      case CFG_FILENAME:                   return VSRC_CFG_FILENAME;
      case CFG_HILIGHT:                    return VSRC_CFG_HIGHLIGHT;
      case CFG_ATTRIBUTE:                  return VSRC_CFG_ATTRIBUTE;
      case CFG_UNKNOWNXMLELEMENT:          return VSRC_CFG_UNKNOWN_XML_ELEMENT;
      case CFG_XHTMLELEMENTINXSL:          return VSRC_CFG_XHTML_ELEMENT_IN_XSL;
      //case CFG_ACTIVECAPTION:              return VSRC_CFG_ACTIVE_TOOL_WINDOW_CAPTION;
      //case CFG_INACTIVECAPTION:            return VSRC_CFG_INACTIVE_TOOL_WINDOW_CAPTION;
      case CFG_SPECIALCHARS:               return VSRC_CFG_SPECIALCHARS;
      case CFG_CURRENT_LINE_BOX:           return VSRC_CFG_CURRENT_LINE_BOX;
      case CFG_VERTICAL_COL_LINE:          return VSRC_CFG_VERTICAL_COL_LINE;
      case CFG_MARGINS_COL_LINE:           return VSRC_CFG_MARGINS_COL_LINE;
      case CFG_TRUNCATION_COL_LINE:        return VSRC_CFG_TRUNCATION_COL_LINE;
      case CFG_PREFIX_AREA_LINE:           return VSRC_CFG_PREFIX_AREA_LINE;
      case CFG_BLOCK_MATCHING:             return VSRC_CFG_BLOCK_MATCHING;
      case CFG_INC_SEARCH_CURRENT:         return VSRC_CFG_INC_SEARCH_CURRENT;
      case CFG_INC_SEARCH_MATCH:           return VSRC_CFG_INC_SEARCH_MATCH;
      case CFG_HEX_MODE_COLOR:             return VSRC_CFG_HEX_MODE_COLOR;
      case CFG_SYMBOL_HIGHLIGHT:           return VSRC_CFG_SYMBOL_HIGHLIGHT;
      //case CFG_MODIFIED_FILE_TAB:          return VSRC_CFG_MODIFIED_FILE_TAB;
      case CFG_LINE_COMMENT:               return VSRC_CFG_LINE_COMMENT;
      case CFG_DOCUMENTATION:              return VSRC_CFG_DOCUMENTATION_COMMENT;
      case CFG_DOC_KEYWORD:                return VSRC_CFG_DOCUMENTATION_KEYWORD;
      case CFG_DOC_PUNCTUATION:            return VSRC_CFG_DOCUMENTATION_PUNCTUATION;
      case CFG_DOC_ATTRIBUTE:              return VSRC_CFG_DOCUMENTATION_ATTRIBUTE;
      case CFG_DOC_ATTR_VALUE:             return VSRC_CFG_DOCUMENTATION_ATTR_VALUE;
      case CFG_IDENTIFIER:                 return VSRC_CFG_IDENTIFIER;
      case CFG_FLOATING_NUMBER:            return VSRC_CFG_FLOATING_NUMBER;
      case CFG_HEX_NUMBER:                 return VSRC_CFG_HEX_NUMBER;
      case CFG_SINGLEQUOTED_STRING:        return VSRC_CFG_SINGLE_QUOTED_STRING;
      case CFG_BACKQUOTED_STRING:          return VSRC_CFG_BACKQUOTED_STRING;
      case CFG_UNTERMINATED_STRING:        return VSRC_CFG_UNTERMINATED_STRING;
      case CFG_INACTIVE_CODE:              return VSRC_CFG_INACTIVE_CODE;
      case CFG_INACTIVE_KEYWORD:           return VSRC_CFG_INACTIVE_KEYWORD;
      case CFG_INACTIVE_COMMENT:           return VSRC_CFG_INACTIVE_COMMENT;
      case CFG_IMAGINARY_SPACE:            return VSRC_CFG_IMAGINARY_SPACE;
      case CFG_MODIFIED_ITEM:              return VSRC_CFG_MODIFIED_ITEM;
      case CFG_NAVHINT:                    return VSRC_CFG_NAVHINT;
      case CFG_XML_CHARACTER_REF:          return VSRC_CFG_XML_CHARACTER_REF;
      case CFG_SEARCH_RESULT_TRUNCATED:    return VSRC_CFG_SEARCH_RESULT_TRUNCATED;
      case CFG_MARKDOWN_HEADER:            return VSRC_CFG_MARKDOWN_HEADER;
      case CFG_MARKDOWN_CODE:              return VSRC_CFG_MARKDOWN_CODE;
      case CFG_MARKDOWN_BLOCKQUOTE:        return VSRC_CFG_MARKDOWN_BLOCKQUOTE;
      case CFG_MARKDOWN_LINK:              return VSRC_CFG_MARKDOWN_LINK;
      case CFG_DOCUMENT_TAB_ACTIVE:        return VSRC_CFG_DOCUMENT_TAB_ACTIVE;
      case CFG_DOCUMENT_TAB_MODIFIED:      return VSRC_CFG_DOCUMENT_TAB_MODIFIED;
      case CFG_DOCUMENT_TAB_SELECTED:      return VSRC_CFG_DOCUMENT_TAB_SELECTED;
      case CFG_DOCUMENT_TAB_UNSELECTED:    return VSRC_CFG_DOCUMENT_TAB_UNSELECTED;
      default:
         return 0;
      }
   }

   /**
    * @return
    * Return the message code for the given color's name.
    * 
    * @param cfg  color ID 
    */
   int getColorDescriptionRC(int cfg)
   {
      switch (cfg) {
      case CFG_SELECTION:                    return VSRC_CFG_SELECTION_DESCRIPTION;
      case CFG_WINDOW_TEXT:                  return VSRC_CFG_WINDOW_TEXT_DESCRIPTION;
      case CFG_CLINE:                        return VSRC_CFG_CURRENT_LINE_DESCRIPTION;
      case CFG_SELECTED_CLINE:               return VSRC_CFG_SELECTED_CURRENT_LINE_DESCRIPTION;
      case CFG_MESSAGE:                      return VSRC_CFG_MESSAGE_DESCRIPTION;
      case CFG_STATUS:                       return VSRC_CFG_STATUS_DESCRIPTION;
      case CFG_CURSOR:                       return VSRC_CFG_CURSOR_DESCRIPTION;
      case CFG_ERROR:                        return VSRC_CFG_ERROR_DESCRIPTION;
      case CFG_MODIFIED_LINE:                return VSRC_CFG_MODIFIED_LINE_DESCRIPTION;
      case CFG_INSERTED_LINE:                return VSRC_CFG_INSERTED_LINE_DESCRIPTION;
      case CFG_KEYWORD:                      return VSRC_CFG_KEYWORD_DESCRIPTION;
      case CFG_LINENUM:                      return VSRC_CFG_LINE_NUMBER_DESCRIPTION;
      case CFG_NUMBER:                       return VSRC_CFG_NUMBER_DESCRIPTION;
      case CFG_STRING:                       return VSRC_CFG_STRING_DESCRIPTION;
      case CFG_COMMENT:                      return VSRC_CFG_COMMENT_DESCRIPTION;
      case CFG_PPKEYWORD:                    return VSRC_CFG_PREPROCESSOR_DESCRIPTION;
      case CFG_PUNCTUATION:                  return VSRC_CFG_PUNCTUATION_DESCRIPTION;
      case CFG_LIBRARY_SYMBOL:               return VSRC_CFG_LIBRARY_SYMBOL_DESCRIPTION;
      case CFG_OPERATOR:                     return VSRC_CFG_OPERATOR_DESCRIPTION;
      case CFG_USER_DEFINED:                 return VSRC_CFG_USER_DEFINED_SYMBOL_DESCRIPTION;
      case CFG_NOSAVE_LINE:                  return VSRC_CFG_NOSAVE_LINE_DESCRIPTION;
      case CFG_FUNCTION:                     return VSRC_CFG_FUNCTION_DESCRIPTION;
      case CFG_LINEPREFIXAREA:               return VSRC_CFG_LINE_PREFIX_AREA_DESCRIPTION;
      case CFG_FILENAME:                     return VSRC_CFG_FILENAME_DESCRIPTION;
      case CFG_HILIGHT:                      return VSRC_CFG_HIGHLIGHT_DESCRIPTION;
      case CFG_ATTRIBUTE:                    return VSRC_CFG_ATTRIBUTE_DESCRIPTION;
      case CFG_UNKNOWNXMLELEMENT:            return VSRC_CFG_UNKNOWN_XML_ELEMENT_DESCRIPTION;
      case CFG_XHTMLELEMENTINXSL:            return VSRC_CFG_XHTML_ELEMENT_IN_XSL_DESCRIPTION;
      //case CFG_ACTIVECAPTION:                return VSRC_CFG_ACTIVE_TOOL_WINDOW_CAPTION_DESCRIPTION;
      //case CFG_INACTIVECAPTION:              return VSRC_CFG_INACTIVE_TOOL_WINDOW_CAPTION_DESCRIPTION;
      case CFG_SPECIALCHARS:                 return VSRC_CFG_SPECIALCHARS_DESCRIPTION;
      case CFG_CURRENT_LINE_BOX:             return VSRC_CFG_CURRENT_LINE_BOX_DESCRIPTION;
      case CFG_VERTICAL_COL_LINE:            return VSRC_CFG_VERTICAL_COL_LINE_DESCRIPTION;
      case CFG_MARGINS_COL_LINE:             return VSRC_CFG_MARGINS_COL_LINE_DESCRIPTION;
      case CFG_TRUNCATION_COL_LINE:          return VSRC_CFG_TRUNCATION_COL_LINE_DESCRIPTION;
      case CFG_PREFIX_AREA_LINE:             return VSRC_CFG_PREFIX_AREA_LINE_DESCRIPTION;
      case CFG_BLOCK_MATCHING:               return VSRC_CFG_BLOCK_MATCHING_DESCRIPTION;
      case CFG_INC_SEARCH_CURRENT:           return VSRC_CFG_INC_SEARCH_CURRENT_DESCRIPTION;
      case CFG_INC_SEARCH_MATCH:             return VSRC_CFG_INC_SEARCH_MATCH_DESCRIPTION;
      case CFG_HEX_MODE_COLOR:               return VSRC_CFG_HEX_MODE_COLOR_DESCRIPTION;
      case CFG_SYMBOL_HIGHLIGHT:             return VSRC_CFG_SYMBOL_HIGHLIGHT_DESCRIPTION;
      //case CFG_MODIFIED_FILE_TAB:            return VSRC_CFG_MODIFIED_FILE_TAB_DESCRIPTION;
      case CFG_LINE_COMMENT:                 return VSRC_CFG_LINE_COMMENT_DESCRIPTION;
      case CFG_DOCUMENTATION:                return VSRC_CFG_DOC_COMMENT_DESCRIPTION;
      case CFG_DOC_KEYWORD:                  return VSRC_CFG_DOCUMENTATION_KEYWORD_DESCRIPTION;
      case CFG_DOC_PUNCTUATION:              return VSRC_CFG_DOCUMENTATION_PUNCTUATION_DESCRIPTION;
      case CFG_DOC_ATTRIBUTE:                return VSRC_CFG_DOCUMENTATION_ATTRIBUTE_DESCRIPTION;
      case CFG_DOC_ATTR_VALUE:               return VSRC_CFG_DOCUMENTATION_ATTR_VALUE_DESCRIPTION;
      case CFG_IDENTIFIER:                   return VSRC_CFG_IDENTIFIER_DESCRIPTION;
      case CFG_FLOATING_NUMBER:              return VSRC_CFG_FLOATING_NUMBER_DESCRIPTION;
      case CFG_HEX_NUMBER:                   return VSRC_CFG_HEX_NUMBER_DESCRIPTION;
      case CFG_SINGLEQUOTED_STRING:          return VSRC_CFG_SINGLE_QUOTED_STRING_DESCRIPTION;
      case CFG_BACKQUOTED_STRING:            return VSRC_CFG_BACKQUOTED_STRING_DESCRIPTION;
      case CFG_UNTERMINATED_STRING:          return VSRC_CFG_UNTERMINATED_STRING_DESCRIPTION;
      case CFG_INACTIVE_CODE:                return VSRC_CFG_INACTIVE_CODE_DESCRIPTION;
      case CFG_INACTIVE_KEYWORD:             return VSRC_CFG_INACTIVE_KEYWORD_DESCRIPTION;
      case CFG_INACTIVE_COMMENT:             return VSRC_CFG_INACTIVE_COMMENT_DESCRIPTION;
      case CFG_IMAGINARY_SPACE:              return VSRC_CFG_IMAGINARY_SPACE_DESCRIPTION;
      case CFG_MODIFIED_ITEM:                return VSRC_CFG_MODIFIED_ITEM_DESCRIPTION;
      case CFG_NAVHINT:                      return VSRC_CFG_NAVHINT_DESCRIPTION;
      case CFG_XML_CHARACTER_REF:            return VSRC_CFG_XML_CHARACTER_REF;
      case CFG_SEARCH_RESULT_TRUNCATED:      return VSRC_CFG_SEARCH_RESULT_TRUNCATED_DESCRIPTION;
      case CFG_MARKDOWN_HEADER:              return VSRC_CFG_MARKDOWN_HEADER_DESCRIPTION;
      case CFG_MARKDOWN_CODE:                return VSRC_CFG_MARKDOWN_CODE_DESCRIPTION;
      case CFG_MARKDOWN_BLOCKQUOTE:          return VSRC_CFG_MARKDOWN_BLOCKQUOTE_DESCRIPTION;
      case CFG_MARKDOWN_LINK:                return VSRC_CFG_MARKDOWN_LINK_DESCRIPTION;
      case CFG_DOCUMENT_TAB_ACTIVE:          return VSRC_CFG_DOCUMENT_TAB_ACTIVE_DESCRIPTION;
      case CFG_DOCUMENT_TAB_MODIFIED:        return VSRC_CFG_DOCUMENT_TAB_MODIFIED_DESCRIPTION;
      case CFG_DOCUMENT_TAB_SELECTED:        return VSRC_CFG_DOCUMENT_TAB_SELECTED_DESCRIPTION;
      case CFG_DOCUMENT_TAB_UNSELECTED:      return VSRC_CFG_DOCUMENT_TAB_UNSELECTED_DESCRIPTION;
      default:
         return 0;
      }
   }

   /**
    * Get the color index for the given display color name.
    */
   int getColorIndexByName(_str colorName) {
      int colorNameRC[];
      for (cfg:=1; cfg<=CFG_LAST_DEFAULT_COLOR; cfg++) {
         colorNameRC[cfg] = getColorNameRC(cfg);
      }
      foreach (cfg => auto colorRC in colorNameRC) {
         if (colorRC!=0 && get_message(colorRC) == colorName) {
            return cfg;
         }
      }
      return STRING_NOT_FOUND_RC;
   }

   /**
    * @return Return the display name for the given color index. 
    *         Return null if we do not have a display name for
    *         this color.
    */
   _str getColorName(int cfg) {
      if (cfg < 0) {
         cfg = -cfg;
      }

      if (cfg < 0 || cfg > CFG_LAST_DEFAULT_COLOR) {
         return null;
      }
      colorNameRC := getColorNameRC(cfg);
      if (colorNameRC == 0) return null;
      return get_message(colorNameRC);
   }

   /**
    * @return Return the description of the given color.
    *         Return null if we do not have a
    *         description for this color.
    */
   _str getColorDescription(int cfg) {
      if (cfg < 0) {
         cfg = -cfg;
      }

      if (cfg < 0 || cfg > CFG_LAST_DEFAULT_COLOR) {
         return null;
      }
      colorDescRC := getColorDescriptionRC(cfg);
      if (colorDescRC == 0) return null;
      return get_message(colorDescRC);
   }

   /**
    * @return Return the color category for the given color item.
    */
   _str getColorCategoryName(int colorId, int &priority) {

      if (colorId < 0) colorId = -colorId;
       categoryRC := 0;
       switch (colorId) {
       case CFG_WINDOW_TEXT:
       case CFG_KEYWORD:
       case CFG_PPKEYWORD:
       case CFG_SYMBOL1:
       case CFG_SYMBOL2:
       case CFG_SYMBOL3:
       case CFG_SYMBOL4:
       case CFG_FUNCTION:
       case CFG_SPECIALCHARS:
       case CFG_IDENTIFIER:
           categoryRC = VSRC_COLOR_CATEGORY_EDITOR_TEXT;
           priority = 0;
           break;
       case CFG_SELECTION:
       case CFG_CLINE:
       case CFG_SELECTED_CLINE:
       case CFG_CURSOR:
           categoryRC = VSRC_COLOR_CATEGORY_EDITOR_CURSOR;
           priority = 10;
           break;
       case CFG_COMMENT:
       case CFG_LINE_COMMENT:
       case CFG_DOCUMENTATION:
       case CFG_DOC_KEYWORD:
       case CFG_DOC_PUNCTUATION:
       case CFG_DOC_ATTRIBUTE:
       case CFG_DOC_ATTR_VALUE:
       case CFG_INACTIVE_CODE:
       case CFG_INACTIVE_KEYWORD:
       case CFG_INACTIVE_COMMENT:
           categoryRC = VSRC_COLOR_CATEGORY_COMMENTS;
           priority = 20;
           break;
       case CFG_STRING:
       case CFG_SINGLEQUOTED_STRING:
       case CFG_BACKQUOTED_STRING:
       case CFG_UNTERMINATED_STRING:
           categoryRC = VSRC_COLOR_CATEGORY_STRINGS;
           priority = 30;
           break;
       case CFG_LINENUM:
       case CFG_NUMBER:
       case CFG_FLOATING_NUMBER:
       case CFG_HEX_NUMBER:
          categoryRC = VSRC_COLOR_CATEGORY_NUMBERS;
          priority = 40;
          break;
       case CFG_ATTRIBUTE:
       case CFG_UNKNOWNXMLELEMENT:
       case CFG_XHTMLELEMENTINXSL:
       case CFG_XML_CHARACTER_REF:
           categoryRC = VSRC_COLOR_CATEGORY_XML;
           priority = 50;
           break;
       case CFG_MARKDOWN_HEADER:    
       case CFG_MARKDOWN_CODE:      
       case CFG_MARKDOWN_BLOCKQUOTE:
       case CFG_MARKDOWN_LINK:      
           categoryRC = VSRC_COLOR_CATEGORY_MARKDOWN;
           priority = 60;
           break;
       case CFG_MODIFIED_LINE:
       case CFG_INSERTED_LINE:
       case CFG_IMAGINARY_LINE:
       case CFG_IMAGINARY_SPACE:
           categoryRC = VSRC_COLOR_CATEGORY_DIFF;
           priority = 70;
           break;
       case CFG_FILENAME:
       case CFG_HILIGHT:
       case CFG_INC_SEARCH_CURRENT:
       case CFG_INC_SEARCH_MATCH:
       case CFG_HEX_MODE_COLOR:
       case CFG_SYMBOL_HIGHLIGHT:
       case CFG_BLOCK_MATCHING:
       case CFG_ERROR:
       case CFG_SEARCH_RESULT_TRUNCATED:
           categoryRC = VSRC_COLOR_CATEGORY_HIGHLIGHTS;
           priority = 80;
           break;
       case CFG_LINEPREFIXAREA:
       case CFG_CURRENT_LINE_BOX:
       case CFG_VERTICAL_COL_LINE:
       case CFG_MARGINS_COL_LINE:
       case CFG_TRUNCATION_COL_LINE:
       case CFG_PREFIX_AREA_LINE:
           categoryRC = VSRC_COLOR_CATEGORY_EDITOR_COLUMNS;
           priority = 90;
           break;
       case CFG_MESSAGE:
       case CFG_STATUS:
       case CFG_CMDLINE:
       //case CFG_MODIFIED_FILE_TAB:
       case CFG_MODIFIED_ITEM:
       case CFG_FUNCTION_HELP:
       case CFG_FUNCTION_HELP_FIXED:
       case CFG_NAVHINT:
       case CFG_DOCUMENT_TAB_ACTIVE:
       case CFG_DOCUMENT_TAB_MODIFIED:
       case CFG_DOCUMENT_TAB_SELECTED:
       case CFG_DOCUMENT_TAB_UNSELECTED:
           categoryRC = VSRC_COLOR_CATEGORY_MISC;
           priority = 100;
           break;
       default:
           categoryRC = VSRC_COLOR_CATEGORY_MISC;
           priority = 999;
           break;
       }

       return get_message(categoryRC);
   }

   /**
    * Load a default color scheme.
    */
   void loadDefaultColorScheme() {
      m_name = "Default";
      m_colors = null;
      m_embedded = null;

      // editor window syntax element colors
      ColorInfo textColor(0x0, 0xFFFFFF, 0);
      m_colors[CFG_WINDOW_TEXT] = textColor;
      textColor.m_background = 0xD0D0D0;
      m_embedded[CFG_WINDOW_TEXT] = textColor;

      ColorInfo identifierColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR, true);
      m_colors[CFG_IDENTIFIER] = textColor; 
      textColor.m_background = 0xD0D0D0;
      m_embedded[CFG_IDENTIFIER] = textColor;

      ColorInfo commentColor(0x8000, 0xFFFFFF, F_ITALIC|F_INHERIT_BG_COLOR);
      m_colors[CFG_COMMENT] = commentColor;
      commentColor.m_background = 0xD0D0D0;
      m_embedded[CFG_COMMENT] = commentColor;

      ColorInfo lineCommentColor(0x608000, 0xFFFFFF, F_ITALIC|F_INHERIT_BG_COLOR);
      m_colors[CFG_LINE_COMMENT] = lineCommentColor;
      lineCommentColor.m_background = 0xD0D0D0;
      m_embedded[CFG_LINE_COMMENT] = lineCommentColor;

      ColorInfo docCommentColor(0x008060, 0xFFFFFF, F_ITALIC|F_INHERIT_BG_COLOR);
      m_colors[CFG_DOCUMENTATION] = docCommentColor;
      docCommentColor.m_background = 0xD0D0D0;
      m_embedded[CFG_DOCUMENTATION] = docCommentColor;

      ColorInfo docKeywordColor(0x800080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_DOC_KEYWORD] = docKeywordColor;
      docKeywordColor.m_background = 0xD0D0D0;
      m_embedded[CFG_DOC_KEYWORD] = docKeywordColor;

      ColorInfo docPunctuationColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_DOC_PUNCTUATION] = docPunctuationColor;
      docPunctuationColor.m_background = 0xD0D0D0;
      m_embedded[CFG_DOC_PUNCTUATION] = docPunctuationColor;

      ColorInfo docAttributeColor(0x800080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_DOC_ATTRIBUTE] = docAttributeColor;
      docAttributeColor.m_background = 0xD0D0D0;
      m_embedded[CFG_DOC_ATTRIBUTE] = docAttributeColor;

      ColorInfo docStringColor(0x808000, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_DOC_ATTR_VALUE] = docStringColor;
      docStringColor.m_background = 0xD0D0D0;
      m_embedded[CFG_DOC_ATTR_VALUE] = docStringColor;

      ColorInfo inactiveCodeColor(0x808080, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_INACTIVE_CODE] = inactiveCodeColor;
      inactiveCodeColor.m_foreground = 0xD0D0D0;
      m_embedded[CFG_INACTIVE_CODE] = inactiveCodeColor;

      ColorInfo inactiveKeywordColor(0x808080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_INACTIVE_KEYWORD] = inactiveKeywordColor;
      inactiveKeywordColor.m_foreground = 0xD0D0D0;
      m_embedded[CFG_INACTIVE_KEYWORD] = inactiveKeywordColor;

      ColorInfo inactiveCommentColor(0x808080, 0xFFFFFF, F_ITALIC|F_INHERIT_BG_COLOR);
      m_colors[CFG_INACTIVE_COMMENT] = inactiveCommentColor;
      inactiveCommentColor.m_foreground = 0xD0D0D0;
      m_embedded[CFG_INACTIVE_COMMENT] = inactiveCommentColor;

      ColorInfo keywordColor(0x800080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_KEYWORD] = keywordColor;
      keywordColor.m_background = 0xD0D0D0;
      m_embedded[CFG_KEYWORD] = keywordColor;

      ColorInfo linenumColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_LINENUM] = linenumColor;
      linenumColor.m_background = 0xD0D0D0;
      m_embedded[CFG_LINENUM] = linenumColor;

      ColorInfo numberColor(0x808000, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_NUMBER] = numberColor;
      m_colors[CFG_HEX_NUMBER] = numberColor;
      m_colors[CFG_FLOATING_NUMBER] = numberColor;
      numberColor.m_background = 0xD0D0D0;
      m_embedded[CFG_NUMBER] = numberColor;
      m_embedded[CFG_HEX_NUMBER] = numberColor;
      m_embedded[CFG_FLOATING_NUMBER] = numberColor;

      ColorInfo ppColor(0x8080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_PPKEYWORD] = ppColor;
      ppColor.m_background = 0xD0D0D0;
      m_embedded[CFG_PPKEYWORD] = ppColor;

      ColorInfo stringColor(0x808000, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_STRING] = stringColor;
      m_colors[CFG_SINGLEQUOTED_STRING] = stringColor;
      m_colors[CFG_BACKQUOTED_STRING] = stringColor;
      m_colors[CFG_UNTERMINATED_STRING] = stringColor;
      stringColor.m_background = 0xD0D0D0;
      m_embedded[CFG_STRING] = stringColor;
      m_embedded[CFG_SINGLEQUOTED_STRING] = stringColor;
      m_embedded[CFG_BACKQUOTED_STRING] = stringColor;
      m_embedded[CFG_UNTERMINATED_STRING] = stringColor;

      ColorInfo punctuationColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_PUNCTUATION] = punctuationColor;
      punctuationColor.m_background = 0xD0D0D0;
      m_embedded[CFG_PUNCTUATION] = punctuationColor;

      ColorInfo libraryColor(0x0, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_LIBRARY_SYMBOL] = libraryColor;
      libraryColor.m_background = 0xD0D0D0;
      m_embedded[CFG_LIBRARY_SYMBOL] = libraryColor;

      ColorInfo operatorColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_OPERATOR] = operatorColor;
      operatorColor.m_background = 0xD0D0D0;
      m_embedded[CFG_OPERATOR] = operatorColor;

      ColorInfo userDefinedColor(0x0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_USER_DEFINED] = userDefinedColor;
      userDefinedColor.m_background = 0xD0D0D0;
      m_embedded[CFG_USER_DEFINED] = userDefinedColor;

      ColorInfo functionColor(0x0, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_FUNCTION] = functionColor;
      functionColor.m_background = 0xD0D0D0;
      m_embedded[CFG_FUNCTION] = functionColor;

      // special characters
      ColorInfo specialCharsColor(0xC0C0C0, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_SPECIALCHARS] = specialCharsColor;
      specialCharsColor.m_background = 0xD0D0D0;
      m_embedded[CFG_SPECIALCHARS] = specialCharsColor;

      ColorInfo hexColor(0x80, 0xF0F0F0, F_BOLD);
      m_colors[CFG_HEX_MODE_COLOR] = hexColor;
      m_embedded[CFG_HEX_MODE_COLOR] = hexColor;

      // XML and HTML tags and attributes
      ColorInfo attributeColor(0x800080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_ATTRIBUTE] = attributeColor;
      attributeColor.m_background = 0xD0D0D0;
      m_embedded[CFG_ATTRIBUTE] = attributeColor;

      ColorInfo unknownXMLElementColor(0x0080FF, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_UNKNOWNXMLELEMENT] = unknownXMLElementColor;
      unknownXMLElementColor.m_background = 0xD0D0D0;
      m_embedded[CFG_UNKNOWNXMLELEMENT] = unknownXMLElementColor;

      ColorInfo XHTMLElementInXSLColor(0x8080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_XHTMLELEMENTINXSL] = XHTMLElementInXSLColor;
      XHTMLElementInXSLColor.m_background = 0xD0D0D0;
      m_embedded[CFG_XHTMLELEMENTINXSL] = XHTMLElementInXSLColor;

      // current line and selection colors
      ColorInfo cursorColor(0xC0C0C0, 0x0, 0);
      m_colors[CFG_CURSOR] = cursorColor;
      m_embedded[CFG_CURSOR] = cursorColor;

      ColorInfo currentLineColor(0xFF0000, 0xFFFFFF, 0);
      m_colors[CFG_CLINE] = currentLineColor;
      currentLineColor.m_background = 0xD0D0D0;
      m_embedded[CFG_CLINE] = currentLineColor;

      ColorInfo insertedLineColor(0xFFFFFF, 0x80, 0);
      m_colors[CFG_INSERTED_LINE] = insertedLineColor;
      m_embedded[CFG_INSERTED_LINE] = insertedLineColor;

      ColorInfo errorColor(0xFFFFFF, 0xFF, 0);
      m_colors[CFG_ERROR] = errorColor;
      m_embedded[CFG_ERROR] = errorColor;

      ColorInfo modifiedLineColor(0xFFFFFF, 0xFF, 0);
      m_colors[CFG_MODIFIED_LINE] = modifiedLineColor;
      m_embedded[CFG_MODIFIED_LINE] = modifiedLineColor;

      ColorInfo noSaveLineColor(0xFFFFFF, 0x80, 0);
      m_colors[CFG_NOSAVE_LINE] = noSaveLineColor;
      m_embedded[CFG_NOSAVE_LINE] = noSaveLineColor;

      ColorInfo imaginarySpaceColor(0xFFFFFF, 0x8000, 0);
      m_colors[CFG_IMAGINARY_SPACE] = imaginarySpaceColor;
      m_embedded[CFG_IMAGINARY_SPACE] = imaginarySpaceColor;

      ColorInfo selectedCurrentLineColor(0xFF0000, 0xC0C0C0, 0);
      m_colors[CFG_SELECTED_CLINE] = selectedCurrentLineColor;
      selectedCurrentLineColor.m_background = 0xFFD0D0;
      m_embedded[CFG_SELECTED_CLINE] = selectedCurrentLineColor;

      ColorInfo selectionColor(0xFF0000, 0xFFFFFF, 0);
      m_colors[CFG_SELECTION] = selectionColor;
      selectionColor.m_background = 0xFFD0D0;
      m_embedded[CFG_SELECTION] = selectionColor;

      // filenames on MDI icons
      ColorInfo filenameColor(0x8000000, 0xC0C0C0, 0);
      m_colors[CFG_FILENAME] = filenameColor;
      m_embedded[CFG_FILENAME] = filenameColor;

      ColorInfo highlightColor(0xFFFFFF, 0xFF0000, 0);
      m_colors[CFG_HILIGHT] = highlightColor;
      m_embedded[CFG_HILIGHT] = highlightColor;

      ColorInfo blockMatchingColor(0xFFFFFF, 0xFF0000, 0);
      m_colors[CFG_BLOCK_MATCHING] = blockMatchingColor;
      m_embedded[CFG_BLOCK_MATCHING] = blockMatchingColor;

      ColorInfo incrementalSearchCurrentColor(0x0, 0x0ffff80, F_INHERIT_STYLE);
      m_colors[CFG_INC_SEARCH_CURRENT] = incrementalSearchCurrentColor;
      m_embedded[CFG_INC_SEARCH_CURRENT] = incrementalSearchCurrentColor;

      ColorInfo incrementalSearchMatchColor(0x0, 0x080ffff, F_INHERIT_STYLE);
      m_colors[CFG_INC_SEARCH_MATCH] = incrementalSearchMatchColor;
      m_embedded[CFG_INC_SEARCH_MATCH] = incrementalSearchMatchColor;

      ColorInfo symbolHighlightColor(0x0, 0x080ffff, 0);
      m_colors[CFG_SYMBOL_HIGHLIGHT] = symbolHighlightColor;
      m_embedded[CFG_SYMBOL_HIGHLIGHT] = symbolHighlightColor;

      // message bar and status bar
      ColorInfo messageColor((int)VSDEFAULT_FOREGROUND_COLOR,
                             (int)VSDEFAULT_BACKGROUND_COLOR, 0);
      m_colors[CFG_MESSAGE] = messageColor;
      m_embedded[CFG_MESSAGE] = messageColor;

      ColorInfo statusColor((int)VSDEFAULT_FOREGROUND_COLOR,
                            (int)VSDEFAULT_BACKGROUND_COLOR, 0);
      m_colors[CFG_STATUS] = messageColor;
      m_embedded[CFG_STATUS] = messageColor;

      // current line box, vertical lines, prefix area
      ColorInfo currentLineBoxColor(0xFF8080, 0xFF8080, 0);
      m_colors[CFG_CURRENT_LINE_BOX] = currentLineBoxColor;
      m_embedded[CFG_CURRENT_LINE_BOX] = currentLineBoxColor;

      ColorInfo gutterColor(0x800080, 0xFFF0F0, 0);
      m_colors[CFG_LINEPREFIXAREA] = gutterColor;
      m_embedded[CFG_LINEPREFIXAREA] = gutterColor;

      ColorInfo gutterLineColor(0x808080, 0x808080, 0);
      m_colors[CFG_PREFIX_AREA_LINE] = gutterLineColor;
      m_embedded[CFG_PREFIX_AREA_LINE] = gutterLineColor;

      ColorInfo verticalColumnLineColor(0x8080FF, 0x8080FF, 0);
      m_colors[CFG_VERTICAL_COL_LINE] = verticalColumnLineColor;
      m_embedded[CFG_VERTICAL_COL_LINE] = verticalColumnLineColor;

      ColorInfo marginColumnsLineColor(0x808080, 0x808080, 0);
      m_colors[CFG_MARGINS_COL_LINE] = marginColumnsLineColor;
      m_embedded[CFG_MARGINS_COL_LINE] = marginColumnsLineColor;

      ColorInfo truncationColumnLineColor(0x0000FF, 0x0000FF, 0);
      m_colors[CFG_TRUNCATION_COL_LINE] = truncationColumnLineColor;
      m_embedded[CFG_TRUNCATION_COL_LINE] = truncationColumnLineColor;

       // modified item in a debugger window
      ColorInfo modifiedItemColor(0xFF, 0xFFFFFF, 0);
      m_colors[CFG_MODIFIED_ITEM] = modifiedItemColor;
      m_embedded[CFG_MODIFIED_ITEM] = modifiedItemColor;

      ColorInfo navHintColor(0x0, 0xFF8000, 0);
      m_colors[CFG_NAVHINT] = navHintColor;
      m_embedded[CFG_NAVHINT] = navHintColor;

      ColorInfo xmlCharColor(0x808000, 0xFFFFFF, F_INHERIT_BG_COLOR);
      m_colors[CFG_XML_CHARACTER_REF] = numberColor;
      numberColor.m_background = 0xD0D0D0;
      m_embedded[CFG_XML_CHARACTER_REF] = numberColor;

      ColorInfo searchTruncColor(0xC0C0C0, 0xFFFFFF, 0);
      m_colors[CFG_SEARCH_RESULT_TRUNCATED] = searchTruncColor;
      searchTruncColor.m_background = 0xD0D0D0;
      m_embedded[CFG_SEARCH_RESULT_TRUNCATED] = searchTruncColor;

      ColorInfo markdownHeader(0x800080, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_MARKDOWN_HEADER] = markdownHeader;
      markdownHeader.m_background = 0xD0D0D0;
      m_embedded[CFG_MARKDOWN_HEADER] = markdownHeader;

      ColorInfo markdownCode(0x808000, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_MARKDOWN_CODE] = markdownCode;
      markdownCode.m_background = 0xD0D0D0;
      m_embedded[CFG_MARKDOWN_CODE] = markdownCode;

      ColorInfo markdownBlockQuote(0x40C0, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_MARKDOWN_BLOCKQUOTE] = markdownBlockQuote;
      markdownBlockQuote.m_background = 0xD0D0D0;
      m_embedded[CFG_MARKDOWN_BLOCKQUOTE] = markdownBlockQuote;

      ColorInfo markdownLink(0x800000, 0xFFFFFF, F_BOLD|F_INHERIT_BG_COLOR);
      m_colors[CFG_MARKDOWN_LINK] = markdownLink;
      markdownLink.m_background = 0xD0D0D0;
      m_embedded[CFG_MARKDOWN_LINK] = markdownLink;

      // message bar, status bar, document tabs
      ColorInfo documentTabActiveColor((int)VSDEFAULT_FOREGROUND_COLOR,
                                       (int)VSDEFAULT_BACKGROUND_COLOR, 0);
      m_colors[CFG_DOCUMENT_TAB_ACTIVE] = documentTabActiveColor;
      m_embedded[CFG_DOCUMENT_TAB_ACTIVE] = documentTabActiveColor;

      ColorInfo documentTabModifiedColor(0xff, 0xffffff, 0);
      m_colors[CFG_DOCUMENT_TAB_MODIFIED] = documentTabModifiedColor;
      m_embedded[CFG_DOCUMENT_TAB_MODIFIED] = documentTabModifiedColor;

      ColorInfo documentTabSelectedColor((int)VSDEFAULT_FOREGROUND_COLOR,
                                         (int)VSDEFAULT_BACKGROUND_COLOR, 0);
      m_colors[CFG_DOCUMENT_TAB_SELECTED] = documentTabSelectedColor;
      m_embedded[CFG_DOCUMENT_TAB_SELECTED] = documentTabSelectedColor;

      ColorInfo documentTabUnselectedColor((int)VSDEFAULT_FOREGROUND_COLOR,
                                           (int)VSDEFAULT_BACKGROUND_COLOR, 0);
      m_colors[CFG_DOCUMENT_TAB_UNSELECTED] = documentTabUnselectedColor;
      m_embedded[CFG_DOCUMENT_TAB_UNSELECTED] = documentTabUnselectedColor;
   }

   /**
    * Load the user's current color scheme.
    */
   void loadCurrentColorScheme() {
      m_name = def_color_scheme;
      m_colors = null;
      m_embedded = null;
      for (cfg:=1; cfg<=CFG_LAST_DEFAULT_COLOR; cfg++) {
         // make sure this is a valid / interesting color
         if (getColorNameRC(cfg) == 0) {
            m_colors[cfg] = null;
            m_embedded[cfg] = null;
            continue;
         }
         // get standard colors
         ColorInfo c;
         c.getColor(cfg);
         m_colors[cfg] = c;
         // also get embedded colors
         if (!isEmbeddedColor(cfg)) {
            m_embedded[cfg] = null;
            continue;
         }
         ColorInfo e;
         e.getColor(-cfg);
         e.m_fontFlags = c.m_fontFlags;
         m_embedded[cfg] = e;
      }
      m_symbolColoringSchemeName = null;
      if (def_symbol_color_scheme != null) {
         m_symbolColoringSchemeName = def_symbol_color_scheme.m_name;
      }
   }

   /**
    * Return the path to the file containing the user-defined color schemes.
    */
   static _str getUserColorSchemeFile() {
      userini := _ConfigPath();
      _maybe_append_filesep(userini);
      userini :+= VSCFGFILE_USER_COLORSCHEMES;
      return userini;
   }

   /**
    * Return the path to the file containing the user-defined color schemes.
    */
   static _str getSystemColorSchemeFile() {
      sysini  := get_env("VSROOT"):+VSCFGFILE_COLORSCHEMES;
      return sysini;
   }

   /**
    * Apply this color scheme as the current color scheme.
    */
   void applyColorScheme() {
      for (i:=1; i <= CFG_LAST_DEFAULT_COLOR; i++) {
         if (i >= m_colors._length()) break;
         if (m_colors[i] == null) continue;
         if (getColorConstantName(i) == null) continue;
         m_colors[i].setColor(i, &this);
         if (i == CFG_NAVHINT) {
            int fgcolor = m_colors[i].getForegroundColor();
            NavMarker.updateMarkerColor(fgcolor);
         }
      }
      for (i=1; i <= CFG_LAST_DEFAULT_COLOR; i++) {
         if (i >= m_embedded._length()) break;
         if (m_embedded[i] == null) continue;
         if (!isEmbeddedColor(i)) continue;
         embeddedColor := m_embedded[i];
         embeddedColor.m_foreground = m_colors[i].getForegroundColor();
         embeddedColor.m_background = getEmbeddedBackgroundColor(i);
         embeddedColor.m_fontFlags &= ~F_INHERIT_BG_COLOR;
         embeddedColor.setColor(-i, &this);
      }
      if (m_name != "") {
         def_color_scheme_version = COLOR_SCHEME_VERSION_CURRENT;
         def_color_scheme = m_name;
        _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }

   /**
    * Apply the associated symbol coloring scheme for this color scheme.
    */
   void applySymbolColorScheme() {
      if (m_symbolColoringSchemeName != def_symbol_color_scheme.m_name) {
         se.color.SymbolColorConfig scc;
         scc.loadEmptyScheme();
         scc.loadSystemSchemes();
         scc.loadUserSchemes();
         rb := scc.getScheme(m_symbolColoringSchemeName);
         if (rb != null) {
            def_symbol_color_scheme = *rb;
         }
      }

      SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme);
   }

   /**
    * Insert the Slick-C code required for recording their color changes.
    */
   void insertMacroCode(boolean macroRecording) {
      // make sure we are recording
      if (macroRecording) {
         _macro('m',_macro('s'));
      }

      // first add the macro code for normal colors
      for (i:=1; i<= CFG_LAST_DEFAULT_COLOR; i++) {
         if (i >= m_colors._length()) break;
         if (m_colors[i] == null) continue;
         cfgName := getColorConstantName(i);
         if (cfgName == null) continue;
         m_colors[i].insertMacroCode(cfgName, macroRecording);
      }

      // now add the code for select embedded colors
      for (i=1; i<= CFG_LAST_DEFAULT_COLOR; i++) {
         if (i >= m_embedded._length()) break;
         if (m_embedded[i] == null) continue;
         if (!isEmbeddedColor(i)) continue;
         cfgName := getColorConstantName(i);
         if (cfgName == null) continue;
         embeddedColor := m_embedded[i];
         embeddedColor.m_background = getEmbeddedBackgroundColor(i);
         embeddedColor.insertMacroCode("-":+cfgName, macroRecording);
      }

      if (m_name != "") {
         if (macroRecording) {
            _macro_append("def_color_scheme = "_dquote(m_name)";");
         } else {
            insert_line("  def_color_scheme = "_dquote(m_name)";");
         }
      }
   }

   /**
    * Load the given color scheme from the INI file.
    *
    * @param fileName       File to load color scheme from
    * @param schemeName     Name of color scheme to find and load
    *
    * @return 0 on success, <0 on error.
    */
   private int loadScheme(_str fileName,  _str schemeName) {

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
       boolean visitedColors[] = null;

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
             colorSchemeVersion = (int) value;
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
             c->m_background = hex2dec(value);
             break;
          case "fg":
             c->m_foreground = hex2dec(value);
             break;
          case "ff":
             c->m_fontFlags = hex2dec(value);
             break;
          case "em":
             ColorInfo *ec = &m_embedded[colorId];
             ec->m_foreground = c->m_foreground;
             ec->m_fontFlags = c->m_fontFlags;
             ec->m_background = hex2dec(value);
             break;
          }
       }

       defaultText := m_colors[CFG_WINDOW_TEXT];
       defaultEmbedded := m_embedded[CFG_WINDOW_TEXT];
       // null out colors that are not part of this scheme
       for (i := 1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
          if (getColorNameRC(i) == 0) {
             m_colors[i] = null;
             m_embedded[i] = null;
             continue;
          }
          if (!isEmbeddedColor(i)) {
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

       // that's all folks
       return 0;
   }

   /**
    * Load the given named color scheme from the user's settings
    */
   int loadUserColorScheme(_str schemeName) {
      fileName := getUserColorSchemeFile();
      if (fileName == null || fileName == "" || !file_exists(fileName)) {
         return FILE_NOT_FOUND_RC;
      }
      return loadScheme(fileName, schemeName);
   }

   /**
    * Load the given system color scheme from the standard configuration.
    */
   int loadSystemColorScheme(_str schemeName) {
      fileName := getSystemColorSchemeFile();
      if (fileName == null || fileName == "" || !file_exists(fileName)) {
         return FILE_NOT_FOUND_RC;
      }
      return loadScheme(fileName, schemeName);
   }

   /**
    * Load the given system color scheme either from the user's settings
    * or from the system colors schemes, whereever it's found first.
    */
   int loadColorScheme(_str schemeName) {
      if (loadUserColorScheme(schemeName) == 0) {
         return 0;
      }
      return loadSystemColorScheme(schemeName);
   }

   /**
    * Should the given color inherit background color from window text 
    * by default? 
    */
   boolean shouldInheritBG(int cfg) {
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
      case CFG_UNKNOWNXMLELEMENT:
      case CFG_XHTMLELEMENTINXSL:
      case CFG_SYMBOL_HIGHLIGHT:
      case CFG_ATTRIBUTE:
      case CFG_UNKNOWNXMLELEMENT:
      case CFG_XHTMLELEMENTINXSL:
      case CFG_BLOCK_MATCHING:
      case CFG_LINE_COMMENT:
      case CFG_DOCUMENTATION:
      case CFG_DOC_PUNCTUATION:
      case CFG_DOC_ATTRIBUTE:
      case CFG_DOC_ATTR_VALUE:
      case CFG_IDENTIFIER:
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
         return true;
      default:
         return false;
      }

   }

   static private int adjustEmbeddedBackgroundColor(int rgb) {

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
         if (getColorNameRC(i) == 0) continue;
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
            if (!isEmbeddedColor(i)) continue;
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
            if (getColorNameRC(i) == 0) continue;
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
         if (getColorNameRC(i) == 0) continue;
         if (!isEmbeddedColor(i)) continue;
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
   }

   /** 
    * @return 
    * Return the color constant name for the given color 
    * Return null if this is not a color that we work 
    * with in the Color settings dialog. 
    * 
    * @param cfg     color id 
    */
   _str getColorConstantName(int cfg) {
      switch (cfg) {
      case CFG_SELECTION:                 return "CFG_SELECTION";          
      case CFG_WINDOW_TEXT:               return "CFG_WINDOW_TEXT";        
      case CFG_CLINE:                     return "CFG_CLINE";              
      case CFG_SELECTED_CLINE:            return "CFG_SELECTED_CLINE";     
      case CFG_MESSAGE:                   return "CFG_MESSAGE";            
      case CFG_STATUS:                    return "CFG_STATUS";             
      case CFG_CMDLINE:                   return "CFG_CMDLINE";            
      case CFG_CURSOR:                    return "CFG_CURSOR";             
      case CFG_ERROR:                     return "CFG_ERROR";      
      case CFG_MODIFIED_LINE:             return "CFG_MODIFIED_LINE";      
      case CFG_INSERTED_LINE:             return "CFG_INSERTED_LINE";      
      //case CFG_FUNCTION_HELP:             return "CFG_FUNCTION_HELP";      
      //case CFG_FUNCTION_HELP_FIXED      : return "CFG_FUNCTION_HELP_FIXED";
      case CFG_KEYWORD:                   return "CFG_KEYWORD";            
      case CFG_LINENUM:                   return "CFG_LINENUM";            
      case CFG_NUMBER:                    return "CFG_NUMBER";             
      case CFG_STRING:                    return "CFG_STRING";             
      case CFG_COMMENT:                   return "CFG_COMMENT";            
      case CFG_PPKEYWORD:                 return "CFG_PPKEYWORD";          
      case CFG_PUNCTUATION:               return "CFG_PUNCTUATION";        
      case CFG_LIBRARY_SYMBOL:            return "CFG_LIBRARY_SYMBOL";     
      case CFG_OPERATOR:                  return "CFG_OPERATOR";           
      case CFG_USER_DEFINED:              return "CFG_USER_DEFINED";       
      case CFG_IMAGINARY_LINE:            return "CFG_IMAGINARY_LINE";     
      case CFG_NOSAVE_LINE:               return "CFG_NOSAVE_LINE";        
      case CFG_FUNCTION:                  return "CFG_FUNCTION";           
      case CFG_LINEPREFIXAREA:            return "CFG_LINEPREFIXAREA";     
      case CFG_FILENAME:                  return "CFG_FILENAME";           
      case CFG_HILIGHT:                   return "CFG_HILIGHT";            
      case CFG_ATTRIBUTE:                 return "CFG_ATTRIBUTE";          
      case CFG_UNKNOWNXMLELEMENT:         return "CFG_UNKNOWNXMLELEMENT";  
      case CFG_XHTMLELEMENTINXSL:         return "CFG_XHTMLELEMENTINXSL";  
      //case CFG_ACTIVECAPTION:             return "CFG_ACTIVECAPTION";      
      //case CFG_INACTIVECAPTION:           return "CFG_INACTIVECAPTION";    
      case CFG_SPECIALCHARS:              return "CFG_SPECIALCHARS";       
      case CFG_CURRENT_LINE_BOX:          return "CFG_CURRENT_LINE_BOX";   
      case CFG_VERTICAL_COL_LINE:         return "CFG_VERTICAL_COL_LINE";  
      case CFG_MARGINS_COL_LINE:          return "CFG_MARGINS_COL_LINE";   
      case CFG_TRUNCATION_COL_LINE:       return "CFG_TRUNCATION_COL_LINE";
      case CFG_PREFIX_AREA_LINE:          return "CFG_PREFIX_AREA_LINE";   
      case CFG_BLOCK_MATCHING:            return "CFG_BLOCK_MATCHING";     
      case CFG_INC_SEARCH_CURRENT:        return "CFG_INC_SEARCH_CURRENT"; 
      case CFG_INC_SEARCH_MATCH:          return "CFG_INC_SEARCH_MATCH";   
      case CFG_HEX_MODE_COLOR:            return "CFG_HEX_MODE_COLOR";     
      case CFG_SYMBOL_HIGHLIGHT:          return "CFG_SYMBOL_HIGHLIGHT";   
      //case CFG_MODIFIED_FILE_TAB:         return "CFG_MODIFIED_FILE_TAB";
      case CFG_LINE_COMMENT:              return "CFG_LINE_COMMENT";
      case CFG_DOCUMENTATION:             return "CFG_DOCUMENTATION";
      case CFG_DOC_KEYWORD:               return "CFG_DOC_KEYWORD";
      case CFG_DOC_PUNCTUATION:           return "CFG_DOC_PUNCTUATION";
      case CFG_DOC_ATTRIBUTE:             return "CFG_DOC_ATTRIBUTE";
      case CFG_DOC_ATTR_VALUE:            return "CFG_DOC_ATTR_VALUE";
      case CFG_IDENTIFIER:                return "CFG_IDENTIFIER";
      case CFG_FLOATING_NUMBER:           return "CFG_FLOATING_NUMBER";
      case CFG_HEX_NUMBER:                return "CFG_HEX_NUMBER";
      case CFG_SINGLEQUOTED_STRING:       return "CFG_SINGLEQUOTED_STRING";
      case CFG_BACKQUOTED_STRING:         return "CFG_BACKQUOTED_STRING";
      case CFG_UNTERMINATED_STRING:       return "CFG_UNTERMINATED_STRING";
      case CFG_INACTIVE_CODE:             return "CFG_INACTIVE_CODE";
      case CFG_INACTIVE_KEYWORD:          return "CFG_INACTIVE_KEYWORD";
      case CFG_INACTIVE_COMMENT:          return "CFG_INACTIVE_COMMENT";
      case CFG_IMAGINARY_SPACE:           return "CFG_IMAGINARY_SPACE";     
      case CFG_MODIFIED_ITEM:             return "CFG_MODIFIED_ITEM";
      case CFG_NAVHINT:                   return "CFG_NAVHINT";
      case CFG_XML_CHARACTER_REF:         return "CFG_XML_CHARACTER_REF";
      case CFG_SEARCH_RESULT_TRUNCATED:   return "CFG_SEARCH_RESULT_TRUNCATED";
      case CFG_MARKDOWN_HEADER:           return "CFG_MARKDOWN_HEADER";
      case CFG_MARKDOWN_CODE:             return "CFG_MARKDOWN_CODE";
      case CFG_MARKDOWN_BLOCKQUOTE:       return "CFG_MARKDOWN_BLOCKQUOTE";
      case CFG_MARKDOWN_LINK:             return "CFG_MARKDOWN_LINK";
      case CFG_DOCUMENT_TAB_ACTIVE:       return "CFG_DOCUMENT_TAB_ACTIVE";
      case CFG_DOCUMENT_TAB_MODIFIED:     return "CFG_DOCUMENT_TAB_MODIFIED";
      case CFG_DOCUMENT_TAB_SELECTED:     return "CFG_DOCUMENT_TAB_SELECTED";
      case CFG_DOCUMENT_TAB_UNSELECTED:   return "CFG_DOCUMENT_TAB_UNSELECTED";
      default: 
         return null;  
      }
   }

   /** 
    * @return 
    * Return the embedded background color for this color item. 
    * If the color is inherited, return the color for embedded 
    * window text. 
    * 
    * @param cfg  Color id 
    */
   int getEmbeddedBackgroundColor(int cfg) {
      color := getColor(cfg);
      if (color->m_fontFlags & F_INHERIT_BG_COLOR) {
         color = getEmbeddedColor(CFG_WINDOW_TEXT);
         if (color == null) return 0x0;
      } else {
         color = getEmbeddedColor(cfg);
         if (color == null) return 0x0;
      }
      return color->m_background;
   }

   /**
    * Save the current scheme to the user color schemes configuration file.
    *
    * @return 0 on success, <0 on error
    */
   int saveColorScheme() {
      int orig_view_id = _create_temp_view(auto temp_view_id=0);
      insert_line("VERSION="COLOR_SCHEME_VERSION_CURRENT);
      if (m_symbolColoringSchemeName != null && m_symbolColoringSchemeName != "") {
         insert_line("ASSOCIATED_SYMBOL_SCHEME="m_symbolColoringSchemeName);
      }

      for ( cfg:=1; cfg<=CFG_LAST_DEFAULT_COLOR; ++cfg) {
         if (cfg >= m_colors._length()) continue;
         if (m_colors[cfg] == null) continue;

         cfgName := getColorConstantName(cfg);
         if (cfgName == null) continue;

         insert_line(cfgName:+"fg=":+dec2hex(0x0000000FFFFFFFF & m_colors[cfg].getForegroundColor(&this)));
         insert_line(cfgName:+"bg=":+dec2hex(0x0000000FFFFFFFF & m_colors[cfg].getBackgroundColor(&this)));
         insert_line(cfgName:+"ff=":+dec2hex(m_colors[cfg].getFontFlags(&this)));

         if (cfg < m_embedded._length() && isEmbeddedColor(cfg) && m_embedded[cfg] != null) {
            insert_line(cfgName:+"em=":+dec2hex(0x0000000FFFFFFFF & getEmbeddedBackgroundColor(cfg)));
         }
      }

      fileName := getUserColorSchemeFile();
      status := _ini_put_section(fileName, m_name, temp_view_id);
      activate_window(orig_view_id);
      return status;
   }

   /**
    * Delete the given color scheme from the user color schemes 
    * configuration file.
    */
   int deleteColorScheme(_str schemeName) {
      fileName := getUserColorSchemeFile();
      if (fileName == "" || !file_exists(fileName)) return FILE_NOT_FOUND_RC;
      return _ini_delete_section(fileName, schemeName);
   }

   /**
    * @return
    * Return the list of system color scheme names
    */
   static STRARRAY getSystemSchemeNames() {
      fileName := getSystemColorSchemeFile();
      if (fileName == null || fileName == "" || !file_exists(fileName)) {
         return null;
      }
      _ini_get_sections_list(fileName, auto schemeNames);
      return schemeNames;
   }

   /**
    * @return
    * Return the list of user defined color scheme names
    */
   static STRARRAY getUserSchemeNames() {
      fileName := getUserColorSchemeFile();
      if (fileName == null || fileName == "" || !file_exists(fileName)) {
          return null;
      }
      _ini_get_sections_list(fileName, auto schemeNames);
      return schemeNames;
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
      if (first_char(colorName)=='-') {
         isEmbedded = true;
         colorName = substr(colorName, 2);
      }
      cfg := getColorIndexByName(colorName);
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


   ////////////////////////////////////////////////////////////////////////
   // interface IEquals
   ////////////////////////////////////////////////////////////////////////

   /**
    * Compare this object with another (presumably) instance of
    * a symbol color rule base.
    *
    * @param rhs  object on the right hand side of comparison
    *
    * @return 'true' if this equals 'rhs', false otherwise
    */
   boolean equals(sc.lang.IEquals &rhs) {
      if (rhs == null) {
//       say("equals:  rhs null");
         return (this == null);
      }
      if (!(rhs instanceof se.color.ColorScheme)) {
//       say("equals:  rhs not a ColorScheme");
         return false;
      }
      ColorScheme *pRHS = &((ColorScheme)rhs);
      if (pRHS->m_name != m_name) {
//       say("equals:  names are different");
         return false;
      }
      for (i:=1; i<=CFG_LAST_DEFAULT_COLOR; i++) {
         if (!getColorName(i)) continue;
         c1 := getColor(i);
         c2 := pRHS->getColor(i);
         if (c1==null && c2==null) {
         } else if (c1 == null || c2==null) {
//          say("equals: MISSING COLOR, i="i" color="getColorName(i));
            return false;
         } else if (*c1 == null && *c2 == null) {
         } else if (*c1 != null && *c2 != null) {
            if (*c1 != *c2) {
//             say("equals: HERE1, i="i" color="getColorName(i));
               return false;
            }
         }
         if (isEmbeddedColor(i)) {
            c1 = getEmbeddedColor(i);
            c2 = pRHS->getEmbeddedColor(i);
            if (c1==null && c2==null) {
            } else if (c1 == null || c2==null) {
//             say("equals: MISSING EMBEDDED COLOR, i="i" color="getColorName(i));
            } else if (*c1 == null && *c2 == null) {
            } else if (*c1 != null && *c2 != null) {
               if (*c1 != *c2) {
//                say("equals: EMBEDDED HERE1, i="i" color="getColorName(i));
//                _dump_var(*c1);
//                _dump_var(*c2);
                  return false;
               }
            }
         }
      }
      if (pRHS->m_symbolColoringSchemeName != m_symbolColoringSchemeName) {
//       say("equals:  different coloring scheme names");
         return false;
      }
//    say("equals:  EQUAL AFTER ALL!");
      return true;
   }

};


