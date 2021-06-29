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
#require "se/color/IColorCollection.e"
#require "se/color/SymbolColorRule.e"
#import "se/tags/SymbolInfo.e"
#import "se/color/ColorInfo.e"
#import "se/color/ColorScheme.e"
#import "dlgman.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "cfg.e"
#endregion

/** 
 * Active symbol coloring profile.
 * Modified by GUI.
 *
 * @categories Configuration_Variables
 */
_str def_symbol_color_profile='';

static _str gSCProfileList[]={
   "All symbols - Light background",
   "All symbols - Dark background",
   "All symbols - Default",
   "All symbols - Silver",
   "All symbols - Iceberge",
};

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * Represents all color schemes with dark backgrounds:
 */
const SYMBOL_COLOR_COMPATIBLE_DARK  = "(Dark Backgrounds)";
/**
 * Represents all color schemes with dark backgrounds:
 */
const SYMBOL_COLOR_COMPATIBLE_LIGHT = "(Light Backgrounds)";
/**
 * String to display if a symbol color scheme is considered 
 * compatible with all color schemes.
 */
const SYMBOL_COLOR_COMPATIBLE_ALL = "All color profiles";


/**
 * The SymbolColorRule class is used to describe one symbol coloring
 * rule.  A set of rules are used to map a symbol to a color to use
 * for symbol coloring.
 */
class SymbolColorRuleBase : IColorCollection, sc.lang.IEquals {

   /**
    * This is a name for this rule base, for display in the GUI.
    */
   _str m_name;

   /**
    * This is a list of base color schemes which this symbol 
    * color rule base is compatible with. 
    */
   _str m_compatibleSchemes[];

   /**
    * This is the entire rule list, a linear, ordered list of
    * symbol color rules.
    */
   SymbolColorRule m_ruleList[];


   /**
    * Construct a symbol color rule base.
    */
   SymbolColorRuleBase(_str name = "") {
      m_name = name;
      m_compatibleSchemes = null;
      m_ruleList = null;
   }

   /**
    * Add a rule to this symbol color rule base.  It is recommended to 
    * first check that the rule name is unique (using {@link 
    * getRuleByName}) before adding it to the rule base. 
    *  
    * @param ruleInfo   symbol coloring rule information to add 
    * @param index      index in list to add the rule at.
    * 
    * @return 0 on success, <0 on error. 
    */
   int addRule(SymbolColorRule &ruleInfo, int index=-1) {
      if (index < 0 || index >= m_ruleList._length()) {
         index = m_ruleList._length();
         m_ruleList[index] = ruleInfo;
      } else {
         m_ruleList._insertel(ruleInfo, index);
      }
      return 0;
   }

   /**
    * Remove a rule from this symbol color rule base. 
    *  
    * @param index   index of rule to remove. 
    * 
    * @return 0 on success, <0 on error. 
    */
   int removeRule(int index) {
      if (index < 0 || index > m_ruleList._length()) {
         return STRING_NOT_FOUND_RC;
      }
      m_ruleList._deleteel(index);
      return 0;
   }

   /**
    * Remove the unique rule with the given name from the rule base. 
    *  
    * @param ruleName   name of rule to remove 
    * 
    * @return 0 on success, <0 on error. 
    */
   int removeRuleByName(_str ruleName) {
      // iterate though each of the rules, delete the first
      // rule that matches the given name
      for ( i := 0; i < m_ruleList._length(); i++ ) {
         if (m_ruleList[i].m_ruleName == ruleName) {
            m_ruleList._deleteel(i);
            return 0;
         }
      }
      // error: no such rule exists
      return STRING_NOT_FOUND_RC;
   }

   /**
    * @return Return the number of rules in the rule base.
    */
   int getNumRules() {
      return m_ruleList._length();
   }

   /**
    * Return a pointer to the rule in the rule database at the given 
    * index location. 
    *  
    * @param index   index of rule to return  
    * 
    * @return SymbolColorRule* on success, null if no such rule
    */
   SymbolColorRule *getRule(int index) {
      if (index < 0 || index > m_ruleList._length()) {
         return null;
      }
      return &m_ruleList[index];
   }

   /**
    * Return a pointer to the symbol coloring rule in the rule 
    * database with the given unique name. 
    *  
    * @param ruleName   rule name to look for
    * 
    * @return SymbolColorRule* on success, null if no such rule
    */
   SymbolColorRule *getRuleByName(_str ruleName) {
      // iterate though each of the rules, return the first
      // rule that matches the given name
      for ( i := 0; i < m_ruleList._length(); i++ ) {
         if (m_ruleList[i].m_ruleName == ruleName) {
            return &m_ruleList[i];
         }
      }
      // error: no such rule exists
      return null;
   }

   /**
    * @return Return the index of the given rule (by name). 
    *         Return <0 if not found. 
    */
   int getRuleIndex(_str ruleName) {
      // iterate though each of the rules, return the first
      // rule that matches the given name
      for ( i := 0; i < m_ruleList._length(); i++ ) {
         if (m_ruleList[i].m_ruleName == ruleName) {
            return i;
         }
      }
      // error: no such rule exists
      return -1;
   }

   /** 
    * Swap the position of two rules in the rule database. 
    * 
    * @param ruleName1  name of first rule to swap
    * @param ruleName2  name of second rule to swap
    * 
    * @return 0 on success, <0 on error.
    */
   int swapRules(_str ruleName1, _str ruleName2) {

      // find each rule in the rule list
      index1 := index2 := -1;
      for ( i := 0; i < m_ruleList._length(); i++ ) {
         if (index1 < 0 && m_ruleList[i].m_ruleName == ruleName1) {
            index1 = i;
         } else if (index2 < 0 && m_ruleList[i].m_ruleName == ruleName2) {
            index2 = i;
         }
      }

      // check that both rules exist
      if ( index1 < 0 || index2 < 0 ) {
         return STRING_NOT_FOUND_RC;
      }

      // swap the location of the rules in the rule table
      tempRule := m_ruleList[index1];
      m_ruleList[index1] = m_ruleList[index2];
      m_ruleList[index2] = tempRule;
      // that's all
      return 0;
   }

   /**
    * Add a color scheme name as a compatible color scheme for this 
    * symbol coloring scheme.  This allows us to know if a certain 
    * symbol coloring scheme is compatible with the current color 
    * scheme. 
    *  
    * @param name    color scheme name 
    */
   void addCompatibleColorScheme(_str name) {
      if (m_compatibleSchemes!=null && isCompatibleWithColorScheme(name)) return;
      m_compatibleSchemes :+= name;
   }
   /**
    * Replace the entire array of compatible color schemes. 
    * Use 'null' to remove all compatible color scheme names. 
    *  
    * @param names   array of color scheme names
    */
   void setCompatibleColorSchemes(_str names[]) {
      m_compatibleSchemes = names;
   }

   /**
    * Remove a color scheme from the list of compatible color schemes. 
    *  
    * @param name    color scheme name 
    */
   void removeCompatibleColorScheme(_str name) {
      numSchemes := m_compatibleSchemes._length();
      for (i := numSchemes-1; i>=0; --i) {
         if (m_compatibleSchemes[i] == name) {
            m_compatibleSchemes._deleteel(i);
         }
      }
   }

   /** 
    * @return 
    * Return 'true' if this symbol color scheme is compatible with the 
    * given master color scheme? 
    *  
    * @param name    color scheme name 
    */
   bool isCompatibleWithColorScheme(_str name) {
      if (m_compatibleSchemes==null) return true;
      if (name == "") return true;
      foreach (auto schemeName in m_compatibleSchemes) {
         if (schemeName == SYMBOL_COLOR_COMPATIBLE_DARK && ColorScheme.isDarkColorProfile(name)) {
            return true;
         } else if (schemeName == SYMBOL_COLOR_COMPATIBLE_LIGHT && !ColorScheme.isDarkColorProfile(name)) {
            return true;
         } else if (schemeName == name) {
            return true;
         }
      }
      return false;
   }

   /** 
    * @return 
    * Return an comma separated list of compatible color schemes.
    */
   _str getCompatibleColorSchemes() {
      if (m_compatibleSchemes == null) return "";
      return join(m_compatibleSchemes, ", ");
   }

   /**
    * Get the subset of rules that might pass for a symbol with the 
    * given tag name and tag flags subset. 
    * <p> 
    * Currently this only discriminates based on "static, abstract, 
    * public, package, private, and protected" tag flags. 
    * <p> 
    * This index partitions the rules by tag type, creating rule 
    * subsets for each tag type ID based on the tag type filtering 
    * flags specified in the rule.  It also indexes rules based on 
    * the presence or absense of the public, private, protected, and 
    * package scope flags, as well as static and abstract flags. 
    * This optimization lets us apply rules more quickly since we only 
    * need to test the rule subset, not all rules. 
    *  
    * @param tag_type_name    tag type, see {@link tag_get_type_id} 
    * @param tag_flags        tag attributes, bitset of SE_TAG_FLAG_* 
    * @param rulesByType      rule index by symbol type and flags 
    * 
    * @return a pointer to an array of integer indexes into the rule 
    *         index table.
    */
   INTARRAY *getRuleSubsetByType(_str tag_type_name, 
                                 SETagFlags tag_flags, 
                                 int (&rulesByType)[][][] ) {

      // look up the type ID corresponding to this type name
      tag_type_id := tag_get_type_id(tag_type_name);
      if (tag_type_name == "UNKNOWN") tag_type_id = SE_TAG_TYPE_UNKNOWN;
      if (tag_type_id < 0) {
         return null;
      }

      // build the rules by type index if it is not already there
      // do not pay attention to access flags for attributes off
      // because of overlapping package, private, and protected flags.
      if (rulesByType == null) {
         foreach (auto i => auto ruleInfo in m_ruleList) {
            attrs_on  := (ruleInfo.m_attributeFlagsOn  & 0xf);
            attrs_off := (ruleInfo.m_attributeFlagsOff & 0x3);
            foreach (auto typeName in ruleInfo.getTagTypes()) {
               type_id := tag_get_type_id(typeName);
               if (type_id <= 0 && typeName=="UNKNOWN") {
                  type_id = SE_TAG_TYPE_UNKNOWN;
               }
               for (flags := 0; flags <= 0xf; ++flags) {
                  // now check most popular symbol tag flags for exact match
                  if ((attrs_on & flags) != attrs_on) {
                     continue;
                  }
                  if ((attrs_off & flags) != 0) {
                     continue;
                  }
                  // ok, add this to the sparse index
                  n := rulesByType[type_id][flags]._length();
                  rulesByType[type_id][flags][n] = i;
               }
            }
         }
      }

      // finally, return the rules subset for this type
      // note that this could still return null (no rules)
      tag_flags &= (SE_TAG_FLAG_ACCESS|SE_TAG_FLAG_STATIC|SE_TAG_FLAG_VIRTUAL);
      if (tag_type_id < rulesByType._length() &&
          tag_flags < rulesByType[tag_type_id]._length()) {
         return &(rulesByType[tag_type_id][(int)tag_flags]);
      }

      // no rules for this type ID, better luck next time
      return null;
   }

   /** 
    * Find the first symbol coloring rule matching the given symbol. 
    * The rules are matched in the order in which they are found in 
    * the list.  The first match wins. 
    * 
    * @param sym           symbol information
    * @param rulesByType   rule index by symbol type and flags 
    * 
    * @return SymbolColorRuleSubset* - a pointer to an array of 
    *         pointers to SymbolColorRules.  This will return null if
    *         there is no matching rule to apply.
    */
   SymbolColorRule *matchRules(se.tags.SymbolInfo &sym, int (&rulesByType)[][][]) {

      INTARRAY *ruleList = getRuleSubsetByType(sym.m_tagType, sym.m_tagFlags, rulesByType);
      if (ruleList == null) {
         return null;
      }
      foreach (auto i in *ruleList) {
         if (m_ruleList[i] != null && m_ruleList[i].testSymbol(sym)) {
            return &m_ruleList[i];
         }
      }
      return null;
   }

   /**
    * Return the symbol color associated with the rule which matched 
    * for this symbol. 
    *  
    * @param sym           symbol information
    * @param rulesByType   rule index by symbol type and flags 
    * 
    * @return ColorInfo* - a pointer to the color information 
    *         associated with the first rule that matched for the
    *         given symbol.
    */
   ColorInfo *matchColor(se.tags.SymbolInfo &sym, int (&rulesByType)[][][]) {
      SymbolColorRule *ruleInfoP = matchRules(sym, rulesByType);
      if (ruleInfoP) {
         return &ruleInfoP->m_colorInfo;
      }
      return null;
   }

   /**
    * When a rule is renamed, we need to adjust the parent rule 
    * names for other rules that inherit color information from them. 
    *  
    * @param origRuleName  old rule name 
    * @param newRuleName   new rule name
    */
   void renameRuleParents(_str origRuleName, _str newRuleName) {
      if (origRuleName=="") return;
      foreach (auto i => auto ruleInfo in m_ruleList) {
         if (m_ruleList[i].m_colorInfo != null &&
             m_ruleList[i].m_colorInfo.m_parentName == origRuleName) {
            m_ruleList[i].m_colorInfo.m_parentName = newRuleName;
         }
      }
   }

   /**
    * Create the default symbol color rule base.
    *  
    * This function chooses either "All Symbols - Dark background" 
    * or "All Symbols - Light background" depending if the current 
    * window color scheme is light or dark. 
    */
   void initDefaultRuleBase() {
      window_color_scheme := ColorScheme.realProfileName(def_color_scheme);
      symbol_color_profile_name := "";
      if (ColorScheme.isDarkColorProfile(window_color_scheme)) {
         symbol_color_profile_name = "All symbols - Dark background";
      } else {
         symbol_color_profile_name = "All symbols - Light background";
      }
      loadProfile(symbol_color_profile_name);
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
   class ColorInfo *getColorByName(_str name) {
      if (name == null) return null;
      rule := getRuleByName(name);
      if (rule == null) return null;
      return &(rule->m_colorInfo);
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
   bool equals(sc.lang.IEquals &rhs) {
      if (rhs == null) {
         return (this == null);
      }
      if (!(rhs instanceof se.color.SymbolColorRuleBase)) {
         return false;
      }
      SymbolColorRuleBase *pRHSRuleBase = &((SymbolColorRuleBase)rhs);
      if (pRHSRuleBase->m_name != m_name) {
         return false;
      }
      if (pRHSRuleBase->m_ruleList != m_ruleList) {
         return false;
      }
      if (pRHSRuleBase->m_compatibleSchemes != m_compatibleSchemes) {
         return false;
      }
      return true;
   }
   /** 
    * @return 
    * Return the name of the default symbol color profile to use 
    * when the User does not have one set, or has it set to "Automatic" 
    */
   static _str getDefaultSymbolColorProfile(_str symbol_color_profile_name="") {

      if (symbol_color_profile_name == "") {
         symbol_color_profile_name = def_symbol_color_profile;
      }

      // check if the current symbol color profile is valid
      if (symbol_color_profile_name != "" && symbol_color_profile_name != CONFIG_AUTOMATIC) {
         if (_plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,symbol_color_profile_name)) {
            return symbol_color_profile_name;
         }
      }

      // find the symbol coloring profiles compatible with the current color scheme
      window_color_scheme := ColorScheme.realProfileName(def_color_scheme);
      listProfiles(auto profileNames, window_color_scheme);

      profile_name := "";
      bool hash_profile:[];
      foreach (profile_name in profileNames) {
         hash_profile:[lowcase(profile_name)] = true;
      }

      // select a preferred symbol coloring profile name
      compatibleSchemeName := "";

      // see if the current window color scheme has an associated symbol colroing scheme
      profile_name = _plugin_get_property(VSCFGPACKAGE_COLOR_PROFILES,window_color_scheme,'associated_symbol_profile');
      if (profile_name != "" &&
          _plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,profile_name) &&
          hash_profile._indexin(lowcase(profile_name))) {
         compatibleSchemeName = profile_name;
      }

      // look through the global list of preferred symbol coloring profiles
      if (compatibleSchemeName != "") {
         foreach (profile_name in gSCProfileList) {
            if (!_plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,profile_name)) continue;
            if (!hash_profile._indexin(lowcase(profile_name))) continue;
            if (pos(window_color_scheme, profile_name, 1, 'i')) {
               compatibleSchemeName = profile_name;
               break;
            }
         }
      }

      // just try to take the first 
      if (compatibleSchemeName == "" && profileNames._length() > 0) {
         compatibleSchemeName = profileNames[0];
      }

      // special case for light background or dark background
      if (compatibleSchemeName == se.color.SYMBOL_COLOR_COMPATIBLE_DARK) {
         compatibleSchemeName = "All symbols - Dark background";
      } else if (compatibleSchemeName == se.color.SYMBOL_COLOR_COMPATIBLE_LIGHT) {
         compatibleSchemeName = "All symbols - Light background";
      }

      // didn't find one, try selecting a color by looking
      // at the background used for the window color scheme.
      if (compatibleSchemeName == "") {
         if (ColorScheme.isDarkColorProfile(window_color_scheme)) {
            compatibleSchemeName = "All symbols - Dark background";
         } else if (!ColorScheme.isDarkColorProfile(window_color_scheme)) {
            compatibleSchemeName = "All symbols - Light background";
         }
      }

      // make sure we came up with a good scheme
      if (_plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,compatibleSchemeName) && 
          hash_profile._indexin(lowcase(compatibleSchemeName))) {
         return compatibleSchemeName;
      }

      // should never get here
      return "All symbols - Light background";
   }

   static bool profileCompatibleWith(_str profileName,_str colorProfileName) {
      if (colorProfileName=='' || colorProfileName==null) {
         return true;
      }
      colorProfileName = ColorScheme.realProfileName(colorProfileName);
      __compatible_with:=_plugin_get_property(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,profileName,'__compatible_with');
      if (__compatible_with==null || __compatible_with=='') {
         return true;
      }
      compatibleProfiles:=split2array(__compatible_with, ";");
      foreach (auto name in compatibleProfiles) {
         if (name == SYMBOL_COLOR_COMPATIBLE_DARK && ColorScheme.isDarkColorProfile(colorProfileName)) {
            return true;
         } else if (name == SYMBOL_COLOR_COMPATIBLE_LIGHT && !ColorScheme.isDarkColorProfile(colorProfileName)) {
            return true;
         } else if (name == colorProfileName) {
            return true;
         }
      }
      return false;
   }

   public static void listProfiles(_str (&profileNames)[],_str colorSchemeName='') { 
      profileNames._makeempty();
      _plugin_list_profiles(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,auto allProfileNames);
      foreach (auto name in allProfileNames) {
         if (_plugin_has_builtin_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,name)) continue;
         if (profileCompatibleWith(name,colorSchemeName)) {
            profileNames :+= name;
         }
      }
      foreach (name in allProfileNames) {
         if (!_plugin_has_builtin_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,name)) continue;
         if (profileCompatibleWith(name,colorSchemeName)) {
            profileNames :+= name;
         }
      }
      // The Symbol color dialog combo box needs this sorted or
      // the user may not be able to select items that have a prefix match.
      profileNames._sort('i');
   }

   /**
    * @return
    * Convert symbol tag attribute flags to a string representation for 
    * writing to the XML configuration file.  This way the information in 
    * the configuration file is symbolic and readable. 
    *  
    * @param tag_flags    Tag attribute flags to convert. 
    */
   static _str tagFlagsToString(SETagFlags tag_flags) {
      s := "";
      if (tag_flags & SE_TAG_FLAG_OVERRIDE     ) s :+= "override|";
      if (tag_flags & SE_TAG_FLAG_VIRTUAL      ) s :+= "virtual|";
      if (tag_flags & SE_TAG_FLAG_STATIC       ) s :+= "static|";
      if (tag_flags & SE_TAG_FLAG_PROTECTED    ) s :+= "protected|";
      if (tag_flags & SE_TAG_FLAG_PRIVATE      ) s :+= "private|";
      if (tag_flags & SE_TAG_FLAG_CONST        ) s :+= "const|";
      if (tag_flags & SE_TAG_FLAG_CONSTEXPR    ) s :+= "constexpr|";
      if (tag_flags & SE_TAG_FLAG_CONSTEVAL    ) s :+= "consteval|";
      if (tag_flags & SE_TAG_FLAG_CONSTINIT    ) s :+= "constinit|";
      if (tag_flags & SE_TAG_FLAG_EXPORT       ) s :+= "export|";
      if (tag_flags & SE_TAG_FLAG_FINAL        ) s :+= "final|";
      if (tag_flags & SE_TAG_FLAG_ABSTRACT     ) s :+= "abstract|";
      if (tag_flags & SE_TAG_FLAG_INLINE       ) s :+= "inline|";
      if (tag_flags & SE_TAG_FLAG_OPERATOR     ) s :+= "operator|";
      if (tag_flags & SE_TAG_FLAG_CONSTRUCTOR  ) s :+= "constructor|";
      if (tag_flags & SE_TAG_FLAG_VOLATILE     ) s :+= "volatile|";
      if (tag_flags & SE_TAG_FLAG_TEMPLATE     ) s :+= "template|";
      if (tag_flags & SE_TAG_FLAG_INCLASS      ) s :+= "inclass|";
      if (tag_flags & SE_TAG_FLAG_DESTRUCTOR   ) s :+= "destructor|";
      if (tag_flags & SE_TAG_FLAG_SYNCHRONIZED ) s :+= "synchronized|";
      if (tag_flags & SE_TAG_FLAG_TRANSIENT    ) s :+= "transient|";
      if (tag_flags & SE_TAG_FLAG_NATIVE       ) s :+= "native|";
      if (tag_flags & SE_TAG_FLAG_MACRO        ) s :+= "macro|";
      if (tag_flags & SE_TAG_FLAG_EXTERN       ) s :+= "extern|";
      if (tag_flags & SE_TAG_FLAG_MAYBE_VAR    ) s :+= "maybe_var|";
      if (tag_flags & SE_TAG_FLAG_ANONYMOUS    ) s :+= "anonymous|";
      if (tag_flags & SE_TAG_FLAG_MUTABLE      ) s :+= "mutable|";
      if (tag_flags & SE_TAG_FLAG_EXTERN_MACRO ) s :+= "extern_macro|";
      if (tag_flags & SE_TAG_FLAG_LINKAGE      ) s :+= "linkage|";
      if (tag_flags & SE_TAG_FLAG_PARTIAL      ) s :+= "partial|";
      if (tag_flags & SE_TAG_FLAG_IGNORE       ) s :+= "ignore|";
      if (tag_flags & SE_TAG_FLAG_FORWARD      ) s :+= "forward|";
      if (tag_flags & SE_TAG_FLAG_OPAQUE       ) s :+= "opaque|";
      if (tag_flags & SE_TAG_FLAG_UNIQ_PUBLIC  ) s :+= "public|";
      if (tag_flags & SE_TAG_FLAG_UNIQ_PACKAGE ) s :+= "package|";
      //if (tag_flags & SE_TAG_FLAG_OUTLINE_ONLY ) s :+= "outline_only|";
      //if (tag_flags & SE_TAG_FLAG_OUTLINE_HIDE ) s :+= "outline_hide|";
      if (tag_flags & SE_TAG_FLAG_OVERRIDE     ) s :+= "override|";
      if (tag_flags & SE_TAG_FLAG_SHADOW       ) s :+= "shadow|";
      //if (tag_flags & SE_TAG_FLAG_NO_PROPAGATE ) s :+= "no_propagate|";
      if (tag_flags & SE_TAG_FLAG_INTERNAL     ) s :+= "internal|";
      if (tag_flags & SE_TAG_FLAG_INFERRED     ) s :+= "inferred|";
      if (tag_flags & SE_TAG_FLAG_NO_COMMENT   ) s :+= "no_comment|";
      _maybe_strip(s, '|');
      return s;
   }
   /** 
    * @return 
    * Parse a list of tag attribute flags and return their integer value. 
    *  
    * @param s    string containing tag attribute flags from XML config file. 
    */
   static SETagFlags parseTagFlags(_str s) {
      tag_flags := SE_TAG_FLAG_NULL;
      split(s, "|", auto flag_names);
      foreach (auto flag in flag_names) {
         switch (flag) {
         case "virtual":      tag_flags |= SE_TAG_FLAG_VIRTUAL; break;      
         case "static":       tag_flags |= SE_TAG_FLAG_STATIC; break;       
         case "public":       tag_flags |= SE_TAG_FLAG_UNIQ_PUBLIC; break;       
         case "protected":    tag_flags |= SE_TAG_FLAG_PROTECTED; break;    
         case "private":      tag_flags |= SE_TAG_FLAG_PRIVATE; break;      
         case "package":      tag_flags |= SE_TAG_FLAG_UNIQ_PACKAGE; break;      
         case "const":        tag_flags |= SE_TAG_FLAG_CONST; break;        
         case "constexpr":    tag_flags |= SE_TAG_FLAG_CONSTEXPR; break;        
         case "consteval":    tag_flags |= SE_TAG_FLAG_CONSTEVAL; break;        
         case "constinit":    tag_flags |= SE_TAG_FLAG_CONSTINIT; break;        
         case "export":       tag_flags |= SE_TAG_FLAG_EXPORT; break;        
         case "final":        tag_flags |= SE_TAG_FLAG_FINAL; break;        
         case "abstract":     tag_flags |= SE_TAG_FLAG_ABSTRACT; break;     
         case "inline":       tag_flags |= SE_TAG_FLAG_INLINE; break;       
         case "operator":     tag_flags |= SE_TAG_FLAG_OPERATOR; break;     
         case "constructor":  tag_flags |= SE_TAG_FLAG_CONSTRUCTOR; break;  
         case "const_destr":  tag_flags |= SE_TAG_FLAG_CONST_DESTR; break;  
         case "volatile":     tag_flags |= SE_TAG_FLAG_VOLATILE; break;     
         case "template":     tag_flags |= SE_TAG_FLAG_TEMPLATE; break;     
         case "inclass":      tag_flags |= SE_TAG_FLAG_INCLASS; break;      
         case "destructor":   tag_flags |= SE_TAG_FLAG_DESTRUCTOR; break;   
         case "synchronized": tag_flags |= SE_TAG_FLAG_SYNCHRONIZED; break; 
         case "transient":    tag_flags |= SE_TAG_FLAG_TRANSIENT; break;    
         case "native":       tag_flags |= SE_TAG_FLAG_NATIVE; break;       
         case "macro":        tag_flags |= SE_TAG_FLAG_MACRO; break;        
         case "extern":       tag_flags |= SE_TAG_FLAG_EXTERN; break;       
         case "maybe_var":    tag_flags |= SE_TAG_FLAG_MAYBE_VAR; break;    
         case "anonymous":    tag_flags |= SE_TAG_FLAG_ANONYMOUS; break;    
         case "mutable":      tag_flags |= SE_TAG_FLAG_MUTABLE; break;      
         case "extern_macro": tag_flags |= SE_TAG_FLAG_EXTERN_MACRO; break; 
         case "linkage":      tag_flags |= SE_TAG_FLAG_LINKAGE; break;      
         case "partial":      tag_flags |= SE_TAG_FLAG_PARTIAL; break;      
         case "ignore":       tag_flags |= SE_TAG_FLAG_IGNORE; break;       
         case "forward":      tag_flags |= SE_TAG_FLAG_FORWARD; break;      
         case "opaque":       tag_flags |= SE_TAG_FLAG_OPAQUE; break;       
         case "implicit":     tag_flags |= SE_TAG_FLAG_IMPLICIT; break;       
         case "override":     tag_flags |= SE_TAG_FLAG_OVERRIDE; break;      
         case "shadow":       tag_flags |= SE_TAG_FLAG_SHADOW; break;      
         case "internal":     tag_flags |= SE_TAG_FLAG_INTERNAL; break;      
         case "inferred":     tag_flags |= SE_TAG_FLAG_INFERRED; break;      
         case "no_comment":   tag_flags |= SE_TAG_FLAG_NO_COMMENT; break;      
         }
      }
      return tag_flags;
   }

   /**
    * @return
    * Convert a standard color index to a string for storage in the 
    * XML symbol coloring configuration file.  This way the information 
    * in the configuration file is symbolic and readable. 
    *  
    * @param color   color index (CFG_*)
    */
   static _str colorIndexToString(_str color) {
      switch (color) {
      case CFG_WINDOW_TEXT:          return "*CFG_WINDOW_TEXT*";         
      case CFG_KEYWORD:              return "*CFG_KEYWORD*";             
      case CFG_PPKEYWORD:            return "*CFG_PPKEYWORD*";           
      case CFG_LIBRARY_SYMBOL:       return "*CFG_LIBRARY_SYMBOL*";      
      case CFG_USER_DEFINED:         return "*CFG_USER_DEFINED*";        
      case CFG_FUNCTION:             return "*CFG_FUNCTION*";            
      case CFG_HILIGHT:              return "*CFG_HILIGHT*";             
      case CFG_SYMBOL_HIGHLIGHT:     return "*CFG_SYMBOL_HIGHLIGHT*";    
      case CFG_REF_HIGHLIGHT_0:      return "*CFG_REF_HIGHLIGHT_0*";    
      case CFG_REF_HIGHLIGHT_1:      return "*CFG_REF_HIGHLIGHT_1*";    
      case CFG_REF_HIGHLIGHT_2:      return "*CFG_REF_HIGHLIGHT_2*";    
      case CFG_REF_HIGHLIGHT_3:      return "*CFG_REF_HIGHLIGHT_3*";    
      case CFG_REF_HIGHLIGHT_4:      return "*CFG_REF_HIGHLIGHT_4*";    
      case CFG_REF_HIGHLIGHT_5:      return "*CFG_REF_HIGHLIGHT_5*";    
      case CFG_REF_HIGHLIGHT_6:      return "*CFG_REF_HIGHLIGHT_6*";    
      case CFG_REF_HIGHLIGHT_7:      return "*CFG_REF_HIGHLIGHT_7*";    
      default: return color;   
      }
   }
   /**
    * @return 
    * Return the color index corresponding to the given symbol color 
    * string from the XML configuration file.  Will return the same string 
    * that was passed in if it doesn't match any of the standard colors. 
    *  
    * @param s    Color name string 
    */
   static _str parseColorName(_str s) {
      switch (s) {
      case "":
      case "*CFG_WINDOW_TEXT*":          return CFG_WINDOW_TEXT;         
      case "*CFG_KEYWORD*":              return CFG_KEYWORD;             
      case "*CFG_PPKEYWORD*":            return CFG_PPKEYWORD;           
      case "*CFG_LIBRARY_SYMBOL*":       return CFG_LIBRARY_SYMBOL;      
      case "*CFG_USER_DEFINED*":         return CFG_USER_DEFINED;        
      case "*CFG_FUNCTION*":             return CFG_FUNCTION;            
      case "*CFG_HILIGHT*":              return CFG_HILIGHT;             
      case "*CFG_SYMBOL_HIGHLIGHT*":     return CFG_SYMBOL_HIGHLIGHT;    
      case "*CFG_REF_HIGHLIGHT_0*":      return CFG_REF_HIGHLIGHT_0;    
      case "*CFG_REF_HIGHLIGHT_1*":      return CFG_REF_HIGHLIGHT_1;    
      case "*CFG_REF_HIGHLIGHT_2*":      return CFG_REF_HIGHLIGHT_2;    
      case "*CFG_REF_HIGHLIGHT_3*":      return CFG_REF_HIGHLIGHT_3;    
      case "*CFG_REF_HIGHLIGHT_4*":      return CFG_REF_HIGHLIGHT_4;    
      case "*CFG_REF_HIGHLIGHT_5*":      return CFG_REF_HIGHLIGHT_5;    
      case "*CFG_REF_HIGHLIGHT_6*":      return CFG_REF_HIGHLIGHT_6;    
      case "*CFG_REF_HIGHLIGHT_7*":      return CFG_REF_HIGHLIGHT_7;    
      default:
         return s;
      }
   }

   private SymbolColorRule  loadOneRule(int handle, int property_node,_str ruleName,int (&hash_position):[]) {
      se.color.ColorInfo c;
      se.color.SymbolColorRule rule;
      rule.m_colorInfo = c;

      rule.m_ruleName            = ruleName;
      attrs_node:=property_node;
      position:= _xmlcfg_get_attribute(handle, attrs_node, "position");
      if (isinteger(position)) {
         hash_position:[ruleName]=position;
      }
      rule.m_regexOptions        = _xmlcfg_get_attribute(handle, attrs_node, "regex_type");
      rule.m_classRegex          = _xmlcfg_get_attribute(handle, attrs_node, "class_re");
      rule.m_nameRegex           = _xmlcfg_get_attribute(handle, attrs_node, "name_re");
      rule.setTagTypes(_xmlcfg_get_attribute(handle, attrs_node, "kinds"));
      rule.m_attributeFlagsOn    = parseTagFlags(_xmlcfg_get_attribute(handle, attrs_node, "attributes_on"));
      rule.m_attributeFlagsOff   = parseTagFlags(_xmlcfg_get_attribute(handle, attrs_node, "attributes_off"));

      isValid := true;
      se.color.ColorInfo color;
      color.m_parentName = parseColorName(_xmlcfg_get_attribute(handle, attrs_node, "parent_color"));
      fg := _hex2dec(_xmlcfg_get_attribute(handle, attrs_node, "fg"), 16, isValid);
      if (!isValid) fg=0x000000;
      color.m_foreground = fg;
      bg := _hex2dec(_xmlcfg_get_attribute(handle, attrs_node, "bg"), 16, isValid);
      if (!isValid) bg=0xffffff;
      color.m_background = bg;
      color.m_fontFlags  = se.color.ColorInfo.parseFontFlags(_xmlcfg_get_attribute(handle, attrs_node, "font_flags"));
      rule.m_colorInfo = color;

      return rule;
   }
   int loadProfile(_str profileName,int optionLevel=0,int (&hash_position):[]=null) {
      hash_position._makeempty();
      m_name = profileName;
      if (profileName == "" || profileName == CONFIG_AUTOMATIC) {
         profileName = getDefaultSymbolColorProfile(profileName);
      }

      m_compatibleSchemes._makeempty();
      m_ruleList._makeempty();

      handle:=_plugin_get_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,profileName,optionLevel);
      if (handle<0) {
         return handle;
      }

      //compatibleSchemes := _xmlcfg_get_attribute(xmlcfgHandle,  schemeNode, "compatibleWith");
      //if (compatibleSchemes == null) compatibleSchemes="";
      //setCompatibleColorSchemes(split2array(compatibleSchemes, ";"));
      profile_node:=_xmlcfg_set_path(handle,"/profile");
      // Sort the nodes by position. 
      // Don't worry that the __compatibility_with node doesn't have an attrs with a position. It's position will be
      // assumed to be 0 so it will likely be at the top but it really doesn't matter where it is.

      _xmlcfg_sort_on_attribute(handle,profile_node,"position",'n');
      property_node:=_xmlcfg_get_first_child(handle,profile_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      while (property_node>=0) {
         if (_xmlcfg_get_name(handle,property_node)!=VSXMLCFG_PROPERTY) {
            property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
            continue;
         }
         _str ruleName=_xmlcfg_get_attribute(handle,property_node, VSXMLCFG_PROPERTY_NAME);
         if (substr(ruleName,1,2)=='__') {
            if (ruleName=='__compatible_with') {
               compatibleSchemes := _xmlcfg_get_attribute(handle,  property_node, VSXMLCFG_PROPERTY_VALUE);
               if (compatibleSchemes == null) compatibleSchemes="";
               setCompatibleColorSchemes(split2array(compatibleSchemes, ";"));
            }
         } else {
            rule:=loadOneRule(handle,property_node,ruleName,hash_position);
            if (rule != null) {
               addRule(rule);
            }
         }
         property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
      return 0;
   }
   private static void addRuleToXml(int handle,int profile_node,se.color.SymbolColorRule &rule,int &last_position,int (&hash_position):[]) {
      _plugin_next_position(rule.m_ruleName,last_position,hash_position);

      property_node:=_xmlcfg_add_property(handle,profile_node,rule.m_ruleName);
      attrs_node:=property_node;

      _xmlcfg_set_attribute(handle,attrs_node,'position',last_position);

      if (rule.m_regexOptions != null) {
         _xmlcfg_set_attribute(handle,attrs_node,'regex_type',rule.m_regexOptions);
      }
      if (rule.m_classRegex != null) {
         _xmlcfg_set_attribute(handle,attrs_node,'class_re',rule.m_classRegex);
      }
      if (rule.m_nameRegex != null) {
         _xmlcfg_set_attribute(handle,attrs_node,'name_re',rule.m_nameRegex);
      }
      tagTypeArray:=rule.getTagTypes();
      _xmlcfg_set_attribute(handle,attrs_node,'kinds',join(tagTypeArray, ","));
      _xmlcfg_set_attribute(handle,attrs_node,'attributes_on',tagFlagsToString(rule.m_attributeFlagsOn));
      _xmlcfg_set_attribute(handle,attrs_node,'attributes_off',tagFlagsToString(rule.m_attributeFlagsOff));
      if (rule.m_colorInfo.m_parentName != null) {
          _xmlcfg_set_attribute(handle, attrs_node, 'parent_color', colorIndexToString(rule.m_colorInfo.m_parentName));
      }
      if (rule.m_colorInfo.m_foreground >= 0) {
         _xmlcfg_set_attribute(handle,attrs_node,'fg',"0x":+_dec2hex(rule.m_colorInfo.m_foreground));
      }
      if (rule.m_colorInfo.m_background >= 0) {
         _xmlcfg_set_attribute(handle,attrs_node,'bg',"0x":+_dec2hex(rule.m_colorInfo.m_background));
      }
      _xmlcfg_set_attribute(handle,attrs_node,'font_flags',se.color.ColorInfo.fontFlagsToString(rule.m_colorInfo.m_fontFlags));

   }

   void saveProfile() {
      se.color.SymbolColorRuleBase tem_rb;
      profileName := m_name;
      if (profileName == CONFIG_AUTOMATIC) {
         profileName = getDefaultSymbolColorProfile(profileName);
      }

      tem_rb.loadProfile(profileName,1,auto hash_position);

      handle := _xmlcfg_create_profile(auto profile_node,
                                       VSCFGPACKAGE_SYMBOLCOLORING_PROFILES,
                                       profileName,
                                       VSCFGPROFILE_SYMBOLCOLORING_VERSION);
      _xmlcfg_add_property(handle, profile_node, "__compatible_with", join(m_compatibleSchemes, ";"));


      last_position := 0;

      foreach (auto i in getNumRules()) {
         se.color.SymbolColorRule *rule = getRule(i-1);
         if (rule != null) {
            addRuleToXml(handle, profile_node, *rule,last_position,hash_position); 
         }
      }

      _plugin_set_profile(handle);
      _xmlcfg_close(handle);
   }

};


