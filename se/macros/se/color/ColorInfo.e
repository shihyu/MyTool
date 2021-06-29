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
#require "se/color/IColorCollection.e"
#import "recmacro.e"
#import "stdprocs.e"
#endregion

/**
 * These constants are used for message and status colors to indicate 
 * that we should use the default system color. 
 */
const VSDEFAULT_FOREGROUND_COLOR=0x80000008;
const VSDEFAULT_BACKGROUND_COLOR=0x80000005;


/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * This class is used to keep track of color information and 
 * implement color inheritance. 
 */
class ColorInfo {

   /**
    * Name of color to inherit from.  This is a color allocated and 
    * managed using the ColorManager class. 
    */
   _str m_parentName;

   /**
    * Foreground color.  Specify -1 to inherit color from the parent color.
    */
   int m_foreground;
   /**
    * Background color.  Specify -1 to inherit color from the parent color.
    */
   int m_background;
    /**
    * Font flags to add to this color specification. 
    * <ul> 
    * <li>F_BOLD -- bold font
    * <li>F_ITALIC -- italic font
    * <li>F_STRIKE_THRU -- strike through font
    * <li>F_UNDERLINE -- underline text
    * <li>F_INHERIT_FG_COLOR -- inherit foreground color from parent color 
    * <li>F_INHERIT_BG_COLOR -- inherit background color from parent color 
    * <li>F_INHERIT_STYLE -- inherit font style from parent color 
    * </ul>
    */
   int m_fontFlags;

   /**
    * Construct a color information object. 
    *  
    * @param fg            Foreground color ( -1 to inherit fg color )
    * @param bg            Background color ( -1 to inherit fg color )
    * @param fontFlags     Additional font flags
    * @param parentName    Name of parent color
    */
   ColorInfo(int fg=-1, int bg=-1, int fontFlags=0, _str parent=null) {
      m_parentName = parent;
      m_foreground = fg;
      m_background = bg;
      m_fontFlags  = fontFlags;
   }

   /**
    * @return Return the actual (calculated) foreground color for this
    *         color specification.
    *  
    * This will be the foreground color set in this object, provided 
    * it is not -1, which indicates that we should inherit the color 
    * from the parent object.  Otherwise, it is the parent color. 
    * If the parent color is not set, or is invalid, this will return 
    * the foreground color for CFG_WINDOW_TEXT. 
    */
   int getForegroundColor(IColorCollection *cc=null, int depth=0) {
      // first check if foreground color is inherited
      if ((m_fontFlags & F_INHERIT_FG_COLOR) && cc != null && depth<32) {
         if (m_parentName != null && isinteger(m_parentName)) {
            ColorInfo parentColor;
            parentColor.getColor((int)m_parentName);
            if (parentColor != null) {
               return parentColor.m_foreground;
            }
         }
         color := cc->getColorByName(m_parentName);
         if (color != null) {
            return color->getForegroundColor(cc,depth+1);
         }
      }
      // return actual foreground color
      return m_foreground;
   }

   /**
    * @return Return the actual (calculated) foreground color for this
    *         color specification.
    *  
    * This will be the foreground color set in this object, provided 
    * it is not -1, which indicates that we should inherit the color 
    * from the parent object.  Otherwise, it is the parent color.  If 
    * the parent color is not set, or is invalid, this will return the 
    * foreground color for CFG_WINDOW_TEXT. 
    */
   int getBackgroundColor(IColorCollection *cc=null, int depth=0) {
      // first check if background color is inherited
      if ((m_fontFlags & F_INHERIT_BG_COLOR) && cc != null && depth<32) {
         if (m_parentName != null && isinteger(m_parentName)) {
            ColorInfo parentColor;
            parentColor.getColor((int)m_parentName);
            if (parentColor != null) {
               return parentColor.m_background;
            }
         }
         color := cc->getColorByName(m_parentName);
         if (color != null) {
            return color->getBackgroundColor(cc,depth+1);
         }
      }
      // return actual background color
      return m_background;
   }

   /**
    * @return Return the actual (calculated) font flags for this color
    *         specification.
    *  
    * If this color inherits from a parent color, the font flags will 
    * be the font flags set in the parent color.
    */
   int getFontFlags(IColorCollection *cc=null, int depth=0) {
      if (!(m_fontFlags & F_INHERIT_STYLE)) {
         return m_fontFlags;
      }
      font_flags := (m_fontFlags & (F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_INHERIT_STYLE));
      if (cc != null && m_parentName!=null && depth<32) {
         if (isinteger(m_parentName)) {
            parse _default_color((int)m_parentName) with . . auto ff;
            parent_font_flags := (int) ff;
            parent_font_flags &= (F_BOLD|F_ITALIC|F_UNDERLINE|F_STRIKE_THRU);
            return parent_font_flags | font_flags;
         }
         color := cc->getColorByName(m_parentName);
         if (color != null) {
            parent_font_flags := color->getFontFlags(cc,depth+1);
            parent_font_flags &= (F_BOLD|F_ITALIC|F_UNDERLINE|F_STRIKE_THRU);
            return parent_font_flags | font_flags;
         }
      }
      return m_fontFlags;
   }

   /**
    * @return Allocate a system color ID for this color specification. 
    *  
    * @see _AllocColor 
    * @see _FreeColor 
    */
   int getColorId(IColorCollection *cc=null, int depth=0) {
      fg := getForegroundColor(cc, depth+1);
      bg := getBackgroundColor(cc, depth+1);
      ff := getFontFlags(cc, depth+1);
      ff &= ~(F_INHERIT_STYLE|F_INHERIT_FG_COLOR);
      orig_wid := _create_temp_view(auto temp_wid);
      colorId := _AllocColor(fg,bg,ff);
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
      return colorId;
   }

   /**
    *  
    * Get the color information for the given color ID
    * 
    * @param colorId    color index, either a default color, embedded color, 
    *                   or something allocated by {@link _AllocColor()}. 
    */
   void getColor(int colorId) {
      parse _default_color(colorId) with auto fg auto bg auto fontFlags;
      if (fg == "2147483656") fg = (int)VSDEFAULT_FOREGROUND_COLOR;
      if (bg == "2147483656") bg = (int)VSDEFAULT_FOREGROUND_COLOR;
      if (fg == "2147483653") fg = (int)VSDEFAULT_BACKGROUND_COLOR;
      if (bg == "2147483653") bg = (int)VSDEFAULT_BACKGROUND_COLOR;
      m_foreground = (int) fg;
      m_background = (int) bg;
      m_fontFlags  = (int) fontFlags;
      m_parentName = null;
   }

   /**
    * Update the color information for this color specification. 
    * @see _default_color 
    */
   void setColor(int colorId, IColorCollection *cc=null) {
      fg := getForegroundColor(cc);
      bg := getBackgroundColor(cc);
      ff := getFontFlags(cc);
      _default_color(colorId, fg, bg, ff);
   }

   /**
    * Swap foreground and background colors.
    */
   void invertColor(IColorCollection *cc=null) {
      fg := getForegroundColor(cc);
      bg := getBackgroundColor(cc);
      m_foreground = bg;
      m_background = fg;
      m_fontFlags &= ~(F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR);
   }

   /** 
    * @return 
    * Return 'true' if this colorInfo object matches the color set 
    * for the given colorId. 
    */
   bool matchesColor(int colorId, IColorCollection *cc=null) {
      ColorInfo colorInfo;
      colorInfo.getColor(colorId);
      if (colorInfo == this) {
         return true;
      }
      if (colorInfo.getForegroundColor(cc) == getForegroundColor(cc) &&
          colorInfo.getBackgroundColor(cc) == getBackgroundColor(cc) &&
          colorInfo.getFontFlags(cc) == getFontFlags(cc)) {
         return true;
      }
      return false;
   }

   /**
    * @return
    * Convert font flags to a string representation for writing to 
    * the XML configuration file.  This way the information in the 
    * configuration file is symbolic and readable. 
    *  
    * @param font_flags    Font flags to convert. 
    */
   static _str fontFlagsToString(int font_flags) {
      s := "";
      if ( font_flags & F_BOLD)              s :+= "F_BOLD|";
      if ( font_flags & F_ITALIC )           s :+= "F_ITALIC|";
      if ( font_flags & F_STRIKE_THRU )      s :+= "F_STRIKE_THRU|";
      if ( font_flags & F_UNDERLINE )        s :+= "F_UNDERLINE|";
      if ( font_flags & F_PRINTER )          s :+= "F_PRINTER|";
      if ( font_flags & F_INHERIT_STYLE )    s :+= "F_INHERIT_STYLE|";
      if ( font_flags & F_INHERIT_BG_COLOR ) s :+= "F_INHERIT_BG_COLOR|";
      if ( font_flags & F_INHERIT_FG_COLOR ) s :+= "F_INHERIT_FG_COLOR|";
      _maybe_strip(s, '|');
      return s;
   }

   /** 
    * @return 
    * Parse a list of font flags and return their integer value. 
    *  
    * @param s    string containing font flags from XML config file. 
    */
   static int parseFontFlags(_str s) {
      font_flags := 0;
      split(s, "|", auto flag_names);
      foreach (auto flag in flag_names) {
         switch (flag) {
         case "F_BOLD":               font_flags |= F_BOLD; break;           
         case "F_ITALIC":             font_flags |= F_ITALIC; break;    
         case "F_STRIKE_THRU":        font_flags |= F_STRIKE_THRU; break;  
         case "F_UNDERLINE":          font_flags |= F_UNDERLINE; break;
         case "F_PRINTER":            font_flags |= F_PRINTER; break;
         case "F_INHERIT_STYLE":      font_flags |= F_INHERIT_STYLE; break; 
         case "F_INHERIT_BG_COLOR":   font_flags |= F_INHERIT_BG_COLOR; break;
         case "F_INHERIT_FG_COLOR":   font_flags |= F_INHERIT_FG_COLOR; break;
         }
      }
      return font_flags;
   }

   /**
    * Insert the macro code required to set this color for the user's color scheme.
    * @param cfgName    name of CFG_* constant to set 
    */
   void insertMacroCode(_str cfgName, bool macroRecording) {
      fontFlagsString := fontFlagsToString(m_fontFlags);
      if (fontFlagsString == "") fontFlagsString=0;
      if (macroRecording) {
         _macro_append('_default_color('cfgName',0x'_dec2hex(m_foreground)',0x'_dec2hex(m_background)','fontFlagsString');');
      } else {
         insert_line('  _default_color('cfgName',0x'_dec2hex(m_foreground)',0x'_dec2hex(m_background)','fontFlagsString');');
      }
   }

};
