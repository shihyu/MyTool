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
#import "cfg.e"
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

   /** Need an order list here so that we can more easily write
      out this list in the same order it was read in. That
     way user doesn't get extra items in their profile. 
    */ 
   _str m_tagTypeList[];

   /**
    * Tag attribute flags filter.  ALL flags set in this filter
    * must be SET in a symbol for this rule to pass.
    */
   SETagFlags m_attributeFlagsOn;
   /**
    * Tag attribute flags filter.  ALL flags set in this filter
    * must be UNSET in a symbol for this rule to pass.
    */
   SETagFlags m_attributeFlagsOff;

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
    * <li>'L' -- Perl regular expression syntax
    * <li>'~' -- Vim regular expression syntax
    * <li>'U' -- Perl regular expression syntax syntax. Support for Unix syntax regular expressions has been dropped.
    * <li>'B' -- Perl regular expression syntax. Support for Brief syntax regular expressions has been dropped.
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
                   SETagFlags attrib_flags_on=SE_TAG_FLAG_NULL,
                   SETagFlags attrib_flags_off=SE_TAG_FLAG_NULL,
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
         m_tagTypeList[m_tagTypeList._length()] = type_name;
      }
   }
   /**
    * Change the list of tag types used by this symbol coloring rule. 
    *  
    * @param tag_type_list   Array of tag type names 
    */
   void setTagTypeArray(_str (&tag_type_list)[],_str profileName) {
      /* 
         To avoid the tag type list changing even though the user made no changes,
         feature this list from the "built-in" profile if there is one. If there
         isn't a built-in profile, no need to do anything special.
      */ 
      property_handle:=_plugin_get_property_xml(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,profileName,'kinds',null,1);
      if (property_handle<0) {
         // There's no built-in profile so just write this. 
         // Could get original value from the non-built-in profile to reduce diff changes but don't
         // bother for now.
         m_tagTypeList=tag_type_list;
         return;
      }
      attrs_node:=_xmlcfg_get_first_child_element(property_handle);

      SymbolColorRule temp_rule;
      temp_rule.setTagTypes(_xmlcfg_get_attribute(property_handle, attrs_node, "kinds"));

      orig_NofItems:=temp_rule.m_tagTypeList._length();
      // Want to maintain this list in the same order if possible.
      int hash:[];
      for (i:=0;i<orig_NofItems;++i) {
         hash:[temp_rule.m_tagTypeList[i]]=i;
      }
      for (i=0;i<tag_type_list._length();++i) {
         int *pi=hash._indexin(tag_type_list[i]);
         if (pi) {
            *pi= -1;
         } else {
            temp_rule.m_tagTypeList[m_tagTypeList._length()]=tag_type_list[i];
         }
      }
      NofDeleted := 0;
      for (i=orig_NofItems-1;i>=0;--i) {
         int *pi=hash._indexin(temp_rule.m_tagTypeList[i]);
         if (*pi>=0) {
            temp_rule.m_tagTypeList._deleteel(i);
         }
      }
      m_tagTypeList = temp_rule.m_tagTypeList;
   }

   /** 
    * @return 
    * Return the list of tag types used by this symbol coloring rule, 
    * as an array of strings. 
    */
   STRARRAY getTagTypes() {
      return m_tagTypeList;
   }

   /**
    * Does this rule have the given symbol type?
    */
   bool hasTagType(_str &type_name) {
      for (i:=0;i<m_tagTypeList._length();++i) {
         if (m_tagTypeList[i]==type_name) {
            return true;
         }
      }
      return false;
   }

   /**
    * Test this rule against a symbol.
    */
   bool testSymbol(SymbolInfo &sym) {

      // first check the symbol type
      if (!hasTagType(sym.m_tagType)) {
         return false;
      }

      // special case for public and package scope flags
      tagFlags := sym.m_tagFlags;
      tagFlags &= ~SE_TAG_FLAG_UNIQ_PUBLIC;
      tagFlags &= ~SE_TAG_FLAG_UNIQ_PACKAGE;
      if (sym.m_className != "") {
         tagFlags |= SE_TAG_FLAG_INCLASS;
         if ((tagFlags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PUBLIC) {
            tagFlags |= SE_TAG_FLAG_UNIQ_PUBLIC;
         }
      }
      if ((tagFlags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PACKAGE) {
         tagFlags |= SE_TAG_FLAG_UNIQ_PACKAGE;
         tagFlags &= ~SE_TAG_FLAG_PROTECTED;
         tagFlags &= ~SE_TAG_FLAG_PRIVATE;
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
