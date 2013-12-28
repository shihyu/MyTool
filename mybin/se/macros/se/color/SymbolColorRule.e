////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include "tagsdb.sh"
#require "se/color/ColorInfo.e"
#require "se/tags/SymbolInfo.e"
#import "math.e"
#endregion

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

using se.tags.SymbolInfo;

/**
 * The SymbolColorRule class is used to describe one symbol coloring
 * rule.  A set of rules are used to map a symbol to a color to use
 * for symbol coloring.
 */
class SymbolColorRule {

   /**
    * Rule name for display in the user interface, and to
    * uniquely identify this rule.
    */
   _str m_ruleName;

   /**
    * Hash table of symbol tag type names.
    */
   boolean m_tagTypeList:[];

   /**
    * Tag attribute flags filter.  ALL flags set in this filter
    * must be SET in a symbol for this rule to pass.
    */
   int m_attributeFlagsOn;
   /**
    * Tag attribute flags filter.  ALL flags set in this filter
    * must be UNSET in a symbol for this rule to pass.
    */
   int m_attributeFlagsOff;

   /**
    * Regular expression to match the symbol name against. 
    * This filter is ignored if it is set to null or the empty string.
    */
   _str m_nameRegex;

   /**
    * Regular expression to match the symbol's class name against.
    * This filter is ignored if it is set to null or the empty string.
    */
   _str m_classRegex;

   /**
    * Regular expression syntax used by name and class regular 
    * expressions.  This will allow the user to select their 
    * preferred regular expression syntax instead of being forced 
    * to use the SlickEdit regular expression syntax. 
    * <ul> 
    * <li>'I' -- Ignore case (maybe be combined with r,u,b,l, or & 
    * <li>'R' -- SlickEdit Regular Expressions syntax
    * <li>'U' -- Unix regular expression syntax syntax
    * <li>'B' -- Brief regular expression syntax
    * <li>'L' -- Perl regular expression syntax
    * <li>'&' -- Wildcard expression
    * </ul>
    */
   _str m_regexOptions;

   /**
    * Color information to use for symbols which match this rule.
    */
   ColorInfo m_colorInfo;

   /**
    * Construct a symbol coloring rule. 
    *  
    * @param name             Symbol coloring rule name 
    * @param colorInfo        color information for this rule 
    * @param tag_type_list    list of tag types, separated by commas 
    * @param attrib_flags_on  tag attribute flags that must be set 
    * @param attrib_flags_off tag attribute flags that must be off 
    * @param name_re          regular expression to match symbol name against
    * @param class_re         regular expression to match symbol class scope name 
    * @param re_options       type of regular expression to use 
    *                         for name_re and class_re 
    */
   SymbolColorRule(_str name="", 
                   ColorInfo colorInfo = null,
                   _str tag_type_list = "",
                   int attrib_flags_on=0,
                   int attrib_flags_off=0,
                   _str name_re=null, _str class_re=null,
                   _str re_options="") {
      m_ruleName = name;
      m_attributeFlagsOn = attrib_flags_on;
      m_attributeFlagsOff = attrib_flags_off;
      m_nameRegex = name_re;
      m_classRegex = class_re;
      m_regexOptions = re_options;
      m_colorInfo = colorInfo;
      m_tagTypeList = null;
      setTagTypes(tag_type_list);
   }

   /**
    * Set the color information for this rule. 
    * The foreground or background color may be "-1", indicating 
    * that we should inherit the color from the parent rule. 
    * The font flags may also be used to indicate the color 
    * is inherited. 
    *  
    * @param fg         foreground color (See {@link _rgb()}); 
    * @param bg         background color (See {@link _rgb()}); 
    * @param fontFlags  font flags, bitset of F_BOLD, F_ITALIC, etc. 
    * @param parent     name of parent color to use 
    */
   void setColorInfo(int fg, int bg, int fontFlags, _str parent=null) {
      ColorInfo ci(fg,bg,fontFlags,parent);
      m_colorInfo = ci;
   }

   /**
    * Change the list of tag types used by this symbol coloring rule. 
    *  
    * @param tag_type_list   Comma-separated list of tag type names 
    */
   void setTagTypes(_str tag_type_list) {
      m_tagTypeList = null;
      if (tag_type_list == null) return;
      while (tag_type_list != "") {
         parse tag_type_list with auto type_name ',' tag_type_list;
         m_tagTypeList:[type_name] = true;
      }
   }
   /**
    * Change the list of tag types used by this symbol coloring rule. 
    *  
    * @param tag_type_list   Array of tag type names 
    */
   void setTagTypeArray(_str tag_type_list[]) {
      m_tagTypeList = null;
      foreach (auto type_name in tag_type_list) {
         m_tagTypeList:[type_name] = true;
      }
   }

   /** 
    * @return 
    * Return the list of tag types used by this symbol coloring rule, 
    * as an array of strings. 
    */
   STRARRAY getTagTypes() {
      _str tag_type_list[];
      foreach (auto type_name => . in m_tagTypeList) {
         tag_type_list[tag_type_list._length()] = type_name;
      }
      return tag_type_list;
   }

   /**
    * Does this rule have the given symbol type?
    */
   boolean hasTagType(_str &type_name) {
      return m_tagTypeList._indexin(type_name);
   }

   /**
    * Test this rule against a symbol.
    */
   boolean testSymbol(SymbolInfo &sym) {

      // first check the symbol type
      if (!hasTagType(sym.m_tagType)) {
         return false;
      }

      // special case for public and package scope flags
      tagFlags := sym.m_tagFlags;
      if ((tagFlags & VS_TAGFLAG_access) == VS_TAGFLAG_public) {
         tagFlags |= VS_TAGFLAG_uniq_public;
      }
      if ((tagFlags & VS_TAGFLAG_access) == VS_TAGFLAG_package) {
         tagFlags |= VS_TAGFLAG_uniq_package;
         tagFlags &= ~VS_TAGFLAG_protected;
         tagFlags &= ~VS_TAGFLAG_private;
      }

      // now check the symbol tag flags
      if ((tagFlags & m_attributeFlagsOn) != m_attributeFlagsOn) {
         return false;
      }
      if ((tagFlags & m_attributeFlagsOff) != 0) {
         return false;
      }

      // now test regular expression against symbol name
      if (m_nameRegex != null && m_nameRegex != "") {
         if (pos(m_nameRegex, sym.m_name, 1, m_regexOptions) <= 0) {
            return false;
         }
      }

      // now test regular expression against symbol class
      if (m_classRegex != null && m_classRegex != "") {
         if (pos(m_classRegex, sym.m_className, 1, m_regexOptions) <= 0) {
            return false;
         }
      }

      // Houston, we have a symbol rule match, initiate liftoff.
      return true;
   }

};
