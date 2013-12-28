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
#require "sc/lang/IEquals.e"
#require "se/tags/SymbolInfo.e"
#require "se/color/ColorInfo.e"
#require "se/color/SymbolColorRule.e"
#require "se/color/IColorCollection.e"
#import "dlgman.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;


const VS_TAGTYPE_UNKNOWN=256;

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
      m_compatibleSchemes[m_compatibleSchemes._length()] = name;
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
   boolean isCompatibleWithColorScheme(_str name) {
      if (m_compatibleSchemes==null) return true;
      if (name == "") return true;
      foreach (auto schemeName in m_compatibleSchemes) {
         if (schemeName == name) {
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
    * @param tag_flags        tag attributes, bitset of VS_TAGFLAG_* 
    * @param rulesByType      rule index by symbol type and flags 
    * 
    * @return a pointer to an array of integer indexes into the rule 
    *         index table.
    */
   INTARRAY *getRuleSubsetByType(_str tag_type_name, int tag_flags, 
                                 int (&rulesByType)[][][] ) {

      // look up the type ID corresponding to this type name
      tag_type_id := tag_get_type_id(tag_type_name);
      if (tag_type_name == "UNKNOWN") tag_type_id = VS_TAGTYPE_UNKNOWN;
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
               if (type_id < 0 && typeName=="UNKNOWN") {
                  type_id = VS_TAGTYPE_UNKNOWN;
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
      tag_flags &= 0xf;
      if (tag_type_id < rulesByType._length() &&
          tag_flags < rulesByType[tag_type_id]._length()) {
         return &(rulesByType[tag_type_id][tag_flags]);
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
    * This function is no longer used, the default rule bases 
    * are stored in the symbol coloring configuration files. 
    */
   void initDefaultRuleBase() {

      // construct a rule base
      m_name = "All symbols - Light background";

      // construct array of "compatible" color scheme names
      split("Crispy;Eggshell;Grayscale;Harvest;Pumpkin;Wintergreen",";",m_compatibleSchemes); 

      // local variable
      // 
		// <Rule
		// 	name="Local variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="lvar"
		// 	attributesOn=""
		// 	attributesOff="static"
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0xA000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo localVarColor(_rgb(0x00,0xA0,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule localVar("Local variable", localVarColor, 
                               "lvar", 0, VS_TAGFLAG_static);
      addRule(localVar);
       
      // static local variable
      // 
		// <Rule
		// 	name="Static local variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="lvar"
		// 	attributesOn="static"
		// 	attributesOff=""
		// 	parentColor="Local variable"
		// 	fg="0x60A000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo staticLocalVarColor(_rgb(0x00,0xA0,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, localVar.m_ruleName);
      SymbolColorRule staticLocalVar("Static local variable", staticLocalVarColor, 
                                     "lvar", VS_TAGFLAG_static, 0);
      addRule(staticLocalVar);
       
      // parameter
      // 
		// <Rule
		// 	name="Parameter"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="param"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="Local variable"
		// 	fg="0xA060"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo parameterColor(_rgb(0x60,0xA0,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, localVar.m_ruleName);
      SymbolColorRule parameter("Parameter", parameterColor, 
                                "param", 0, 0); 
      addRule(parameter);
       
      // public member variable
      // 
		// <Rule
		// 	name="Public member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="inclass|public"
		// 	attributesOff="static|protected|private|package"
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x8000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo memberVarColor(_rgb(0x00,0x80,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule memberVar("Public member variable", memberVarColor, 
                                "var,group",
                                VS_TAGFLAG_uniq_public|VS_TAGFLAG_public|VS_TAGFLAG_inclass, 
                                VS_TAGFLAG_static|VS_TAGFLAG_private|VS_TAGFLAG_protected/*|VS_TAGFLAG_package*/|VS_TAGFLAG_uniq_package);
      addRule(memberVar);

      // package scope member variable
		// <Rule
		// 	name="Package member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="package"
		// 	attributesOff="static|protected|private|public"
		// 	parentColor="Public member variable"
		// 	fg="0x8040"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo packageMemberVarColor(_rgb(0x40,0x80,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, memberVar.m_ruleName);
      SymbolColorRule packageMemberVar("Package member variable", packageMemberVarColor, 
                                       "var,group", 
                                       VS_TAGFLAG_uniq_package/*|VS_TAGFLAG_package*/, 
                                       VS_TAGFLAG_static|VS_TAGFLAG_public|VS_TAGFLAG_uniq_public|VS_TAGFLAG_protected|VS_TAGFLAG_private);
      addRule(packageMemberVar);

      // protected member variable
      // 
		// <Rule
		// 	name="Protected member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="protected"
		// 	attributesOff="static|private|public|package"
		// 	parentColor="Package member variable"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo protectedMemberVarColor(_rgb(0x40,0x80,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_ITALIC, packageMemberVar.m_ruleName);
      SymbolColorRule protectedMemberVar("Protected member variable", protectedMemberVarColor, 
                                         "var,group",
                                         VS_TAGFLAG_protected, 
                                         VS_TAGFLAG_static|VS_TAGFLAG_private|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(protectedMemberVar);
      
      // private member variable
      // 
		// <Rule
		// 	name="Private member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="private"
		// 	attributesOff="static|protected|public|package"
		// 	parentColor="Protected member variable"
		// 	fg="0xA040"
		// 	fontFlags="F_ITALIC|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo privateMemberVarColor(_rgb(0x40,0xA0,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE|F_ITALIC, protectedMemberVar.m_ruleName);
      SymbolColorRule privateMemberVar("Private member variable", privateMemberVarColor, 
                                       "var,group", 
                                       VS_TAGFLAG_private, 
                                       VS_TAGFLAG_static|VS_TAGFLAG_protected|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(privateMemberVar);
       
       
      // public static member variable, like member var, but more blue tint (static)
      // 
		// <Rule
		// 	name="Public static member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="static|inclass|public"
		// 	attributesOff="protected|private|package"
		// 	parentColor="Public member variable"
		// 	fg="0x608000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticMemberVarColor(_rgb(0x00,0x80,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, memberVar.m_ruleName);
      SymbolColorRule staticMemberVar("Public static member variable", staticMemberVarColor, 
                                      "var,group", 
                                      VS_TAGFLAG_uniq_public|VS_TAGFLAG_public|VS_TAGFLAG_inclass|VS_TAGFLAG_static, 
                                      VS_TAGFLAG_private|VS_TAGFLAG_protected/*|VS_TAGFLAG_package*/|VS_TAGFLAG_uniq_package);
      addRule(staticMemberVar);
       
      // package scope static member variable
      // 
		// <Rule
		// 	name="Package static member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="static|package"
		// 	attributesOff="protected|private|public"
		// 	parentColor="Public static member variable"
		// 	fg="0x408040"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo packageStaticMemberVarColor(_rgb(0x40,0x80,0x40), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, staticMemberVar.m_ruleName);
      SymbolColorRule packageStaticMemberVar("Package static member variable",
                                             packageStaticMemberVarColor, 
                                             "var,group", 
                                             VS_TAGFLAG_static|VS_TAGFLAG_uniq_package/*|VS_TAGFLAG_package*/, 
                                             VS_TAGFLAG_public|VS_TAGFLAG_uniq_public|VS_TAGFLAG_protected|VS_TAGFLAG_private);
      addRule(packageStaticMemberVar);
       
      // protected static member variable
      // 
		// <Rule
		// 	name="Protected static member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="static|protected"
		// 	attributesOff="private|public|package"
		// 	parentColor="Package static member variable"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo protectedStaticMemberVarColor(_rgb(0x40,0x80,0x40), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_ITALIC, packageStaticMemberVar.m_ruleName);
      SymbolColorRule protectedStaticMemberVar("Protected static member variable", 
                                               protectedStaticMemberVarColor, 
                                               "var,group", 
                                               VS_TAGFLAG_static|VS_TAGFLAG_protected, 
                                               VS_TAGFLAG_private|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(protectedStaticMemberVar);
       
      // private static member variable
      // 
		// <Rule
		// 	name="Private static member variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="var,group"
		// 	attributesOn="static|private"
		// 	attributesOff="protected|public|package"
		// 	parentColor="Protected static member variable"
		// 	fg="0x60A040"
		// 	fontFlags="F_ITALIC|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo privateStaticMemberVarColor(_rgb(0x40,0xA0,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, protectedStaticMemberVar.m_ruleName);
      SymbolColorRule privateStaticMemberVar("Private static member variable", 
                                             privateStaticMemberVarColor, 
                                             "var,group", 
                                             VS_TAGFLAG_static|VS_TAGFLAG_private, 
                                             VS_TAGFLAG_protected|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(privateStaticMemberVar);
       
      // global variable
      // 
		// <Rule
		// 	name="Global variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="gvar"
		// 	attributesOn=""
		// 	attributesOff="static"
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x6000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo globalVarColor(_rgb(0x00,0x60,0x0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule globalVar("Global variable", globalVarColor, 
                               "gvar", 
                               0, VS_TAGFLAG_static);
      addRule(globalVar);
      
      // static global variable, with blue tint (static)
      // 
		// <Rule
		// 	name="Static global variable"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="gvar"
		// 	attributesOn="static"
		// 	attributesOff=""
		// 	parentColor="Global variable"
		// 	fg="0x606000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticGlobalVarColor(_rgb(0x00,0x60,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, globalVar.m_ruleName);
      SymbolColorRule staticGlobalVar("Static global variable", staticGlobalVarColor, 
                                      "gvar", 
                                      VS_TAGFLAG_static, 0);
      addRule(staticGlobalVar);
       
      // global function
      // 
		// <Rule
		// 	name="Global function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="subproc,proc,func,subfunc,procproto,proto"
		// 	attributesOn=""
		// 	attributesOff="static|inclass"
		// 	parentColor="*CFG_FUNCTION*"
		// 	fg="0x600060"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo globalFunctionColor(_rgb(0x60,0x00,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_FUNCTION); 
      SymbolColorRule globalFunction("Global function", globalFunctionColor,
                                     "proc,proto,func,procproto,subfunc,subproc",
                                     0, VS_TAGFLAG_static|VS_TAGFLAG_inclass);
      addRule(globalFunction);

      // static global function, with blue tint (static)
      // 
		// <Rule
		// 	name="Static global function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="subproc,proc,func,subfunc,procproto,proto"
		// 	attributesOn="static"
		// 	attributesOff="inclass"
		// 	parentColor="Global function"
		// 	fg="0xA00060"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticGlobalFunctionColor(_rgb(0x60,0x00,0xA0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, globalFunction.m_ruleName); 
      SymbolColorRule staticGlobalFunction("Static global function", 
                                           staticGlobalFunctionColor,
                                           "proc,proto,func,procproto,subfunc,subproc",
                                           VS_TAGFLAG_static, VS_TAGFLAG_inclass);
      addRule(staticGlobalFunction);

      // class constructor
      // 
		// <Rule
		// 	name="Class constructor"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="constr,proc,func,destr,procproto,proto"
		// 	attributesOn="constructor"
		// 	attributesOff="destructor"
		// 	parentColor="Global function"
		// 	fg="0x800000"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo constructorFunctionColor(_rgb(0,0,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, globalFunction.m_ruleName); 
      SymbolColorRule constructorFunction("Class constructor", constructorFunctionColor,
                                          "proc,proto,func,procproto,constr,destr",
                                          VS_TAGFLAG_constructor, 0);
      addRule(constructorFunction);

      // class destructor
      // 
		// <Rule
		// 	name="Class destructor"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="constr,proc,func,destr,procproto,proto"
		// 	attributesOn="destructor"
		// 	attributesOff="constructor"
		// 	parentColor="Class constructor"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo destructorFunctionColor(_rgb(0,0,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, constructorFunction.m_ruleName); 
      SymbolColorRule destructorFunction("Class destructor", destructorFunctionColor,
                                          "proc,proto,func,procproto,constr,destr",
                                          VS_TAGFLAG_destructor, 0);
      addRule(destructorFunction);
       
      // public member function
      // 
		// <Rule
		// 	name="Public member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="inclass|public"
		// 	attributesOff="static|protected|private|operator|constructor|destructor|package"
		// 	parentColor="Global function"
		// 	fg="0x800080"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo memberFunctionColor(_rgb(0x80,0x00,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, globalFunction.m_ruleName); 
      SymbolColorRule memberFunction("Public member function", 
                                     memberFunctionColor,
                                     "proc,proto,func,procproto,subfunc,subproc",
                                      VS_TAGFLAG_uniq_public|VS_TAGFLAG_public|VS_TAGFLAG_inclass, 
                                     VS_TAGFLAG_static|VS_TAGFLAG_private|VS_TAGFLAG_protected|VS_TAGFLAG_const_destr|VS_TAGFLAG_operator/*|VS_TAGFLAG_package*/|VS_TAGFLAG_uniq_package);
      addRule(memberFunction);
      
      // package scope member function
      // 
		// <Rule
		// 	name="Package member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="inclass|package"
		// 	attributesOff="static|protected|private|public"
		// 	parentColor="Public member function"
		// 	fg="0x8000A0"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo packageMemberFunctionColor(_rgb(0xA0,0x00,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, memberFunction.m_ruleName); 
      SymbolColorRule packageMemberFunction("Package member function", 
                                            packageMemberFunctionColor,
                                            "proc,proto,func,procproto,subfunc,subproc",
                                            VS_TAGFLAG_inclass|VS_TAGFLAG_uniq_package/*|VS_TAGFLAG_package*/, 
                                            VS_TAGFLAG_static|VS_TAGFLAG_public|VS_TAGFLAG_uniq_public|VS_TAGFLAG_protected|VS_TAGFLAG_private);
      addRule(packageMemberFunction);

      // protected member function, add italic
      // 
		// <Rule
		// 	name="Protected member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,subfunc,procproto,proto"
		// 	attributesOn="protected|inclass"
		// 	attributesOff="static|private|public|package"
		// 	parentColor="Package member function"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo protectedMemberFunctionColor(_rgb(0xA0,0x00,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_ITALIC, packageMemberFunction.m_ruleName); 
      SymbolColorRule protectedMemberFunction("Protected member function", 
                                              protectedMemberFunctionColor,
                                              "proc,proto,func,procproto,subfunc",
                                              VS_TAGFLAG_inclass|VS_TAGFLAG_protected, 
                                              VS_TAGFLAG_static|VS_TAGFLAG_private|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(protectedMemberFunction);
       
      // private member function
      // 
		// <Rule
		// 	name="Private member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="private|inclass"
		// 	attributesOff="static|protected|public|package"
		// 	parentColor="Protected member function"
		// 	fg="0xA000E0"
		// 	fontFlags="F_ITALIC|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo privateMemberFunctionColor(_rgb(0xE0,0x00,0xA0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE|F_ITALIC, protectedMemberFunction.m_ruleName); 
      SymbolColorRule privateMemberFunction("Private member function", 
                                            privateMemberFunctionColor,
                                            "proc,proto,func,procproto,subfunc,subproc",
                                            VS_TAGFLAG_inclass|VS_TAGFLAG_private, 
                                            VS_TAGFLAG_static|VS_TAGFLAG_protected|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(privateMemberFunction);

      // static public member function, add blue (static)
      // 
		// <Rule
		// 	name="Public static member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="static|inclass|public"
		// 	attributesOff="protected|private|package"
		// 	parentColor="Public member function"
		// 	fg="0xC00080"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticMemberFunctionColor(_rgb(0x80,0x00,0xC0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, memberFunction.m_ruleName); 
      SymbolColorRule staticMemberFunction("Public static member function",
                                           staticMemberFunctionColor,
                                           "proc,proto,func,procproto,subfunc,subproc",
                                           VS_TAGFLAG_uniq_public|VS_TAGFLAG_public|VS_TAGFLAG_static|VS_TAGFLAG_inclass, 
                                           VS_TAGFLAG_private|VS_TAGFLAG_protected/*|VS_TAGFLAG_package*/|VS_TAGFLAG_uniq_package);
      addRule(staticMemberFunction);
       
      // static package scope member function
      // 
		// <Rule
		// 	name="Package static member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="static|inclass|package"
		// 	attributesOff="protected|private|public"
		// 	parentColor="Public static member function"
		// 	fg="0xC000A0"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticPackageMemberFunctionColor(_rgb(0xA0,0x00,0xC0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, staticMemberFunction.m_ruleName); 
      SymbolColorRule staticPackageMemberFunction("Package static member function",
                                                  staticPackageMemberFunctionColor,
                                                  "proc,proto,func,procproto,subfunc,subproc",
                                                  VS_TAGFLAG_static|VS_TAGFLAG_inclass|VS_TAGFLAG_uniq_package/*|VS_TAGFLAG_package*/, 
                                                  VS_TAGFLAG_public|VS_TAGFLAG_uniq_public|VS_TAGFLAG_protected|VS_TAGFLAG_private);
      addRule(staticPackageMemberFunction);

      // static protected member function, add italic
      // 
		// <Rule
		// 	name="Protected static member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="static|protected|inclass"
		// 	attributesOff="private|public|package"
		// 	parentColor="Package static member function"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo staticProtectedMemberFunctionColor(_rgb(0xA0,0x00,0xC0), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_ITALIC, staticPackageMemberFunction.m_ruleName); 
      SymbolColorRule staticProtectedMemberFunction("Protected static member function",
                                                    staticProtectedMemberFunctionColor,
                                                    "proc,proto,func,procproto,subfunc,subproc",
                                                    VS_TAGFLAG_static|VS_TAGFLAG_inclass|VS_TAGFLAG_protected, 
                                                    VS_TAGFLAG_private|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(staticProtectedMemberFunction);
       
      // static private member function
      // 
		// <Rule
		// 	name="Private static member function"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="proc,func,procproto,proto,subfunc,subproc"
		// 	attributesOn="static|private|inclass"
		// 	attributesOff="protected|public|package"
		// 	parentColor="Protected static member function"
		// 	fg="0xE000C0"
		// 	fontFlags="F_BOLD|F_ITALIC|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo staticPrivateMemberFunctionColor(_rgb(0xC0,0x00,0xE0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, staticProtectedMemberFunction.m_ruleName); 
      SymbolColorRule staticPrivateMemberFunction("Private static member function",
                                                  staticPrivateMemberFunctionColor,
                                                  "proc,proto,func,procproto,subfunc,subproc",
                                                  VS_TAGFLAG_static|VS_TAGFLAG_inclass|VS_TAGFLAG_private, 
                                                  VS_TAGFLAG_protected|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(staticPrivateMemberFunction);


      // public property
      // 
		// <Rule
		// 	name="Public class property"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="prop"
		// 	attributesOn="inclass|public"
		// 	attributesOff="protected|private|package"
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x808000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo propertyColor(_rgb(0x80,0x80,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule publicProperty("Public class property", propertyColor,
                                     "prop",
                                     VS_TAGFLAG_uniq_public|VS_TAGFLAG_public|VS_TAGFLAG_inclass, 
                                     VS_TAGFLAG_private|VS_TAGFLAG_protected/*|VS_TAGFLAG_package*/|VS_TAGFLAG_uniq_package);
      addRule(publicProperty);
       
      // package scope property
      // 
		// <Rule
		// 	name="Package class property"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="prop"
		// 	attributesOn="package"
		// 	attributesOff="protected|private|public"
		// 	parentColor="Public class property"
		// 	fg="0x808040"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo packagePropertyColor(_rgb(0x40,0x80,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, publicProperty.m_ruleName);
      SymbolColorRule packageProperty("Package class property",
                                      packagePropertyColor,
                                      "prop",
                                      VS_TAGFLAG_uniq_package/*|VS_TAGFLAG_package*/, 
                                      VS_TAGFLAG_public|VS_TAGFLAG_uniq_public|VS_TAGFLAG_protected|VS_TAGFLAG_private);
      addRule(packageProperty);
       
      // protected property, add italic
      // 
		// <Rule
		// 	name="Protected class property"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="prop"
		// 	attributesOn="protected"
		// 	attributesOff="private|public|package"
		// 	parentColor="Package class property"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo protectedPropertyColor(_rgb(0x40,0x80,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_ITALIC, packageProperty.m_ruleName);
      SymbolColorRule protectedProperty("Protected class property",
                                        protectedPropertyColor,
                                        "prop",
                                        VS_TAGFLAG_protected, 
                                        VS_TAGFLAG_private|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(protectedProperty);
       
      // private property
      // 
		// <Rule
		// 	name="Private class property"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="prop"
		// 	attributesOn="private"
		// 	attributesOff="protected|public|package"
		// 	parentColor="Protected class property"
		// 	fg="0x808060"
		// 	fontFlags="F_ITALIC|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo privatePropertyColor(_rgb(0x60,0x80,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE|F_ITALIC, protectedProperty.m_ruleName);
      SymbolColorRule privateProperty("Private class property",
                                      privatePropertyColor,
                                      "prop",
                                      VS_TAGFLAG_private, 
                                      VS_TAGFLAG_protected|VS_TAGFLAG_uniq_public|VS_TAGFLAG_uniq_package);
      addRule(privateProperty);
       
      // class name, matching constructor color
      // 
		// <Rule
		// 	name="Class"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="class"
		// 	attributesOn=""
		// 	attributesOff="abstract|template"
		// 	parentColor="Class constructor"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo classColor(_rgb(0x00,0x00,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_INHERIT_STYLE, constructorFunction.m_ruleName);
      SymbolColorRule className("Class", 
                                classColor,
                                "class",
                                0, VS_TAGFLAG_template|VS_TAGFLAG_abstract);
      addRule(className);
      
      // template class name
      // 
		// <Rule
		// 	name="Template class"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="class"
		// 	attributesOn="template"
		// 	attributesOff=""
		// 	parentColor="Class"
		// 	fg="0x800040"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo templateClassColor(_rgb(0x40,0x00,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, className.m_ruleName);
      SymbolColorRule templateClassName("Template class",
                                        templateClassColor,
                                        "class",
                                        VS_TAGFLAG_template, 0);
      addRule(templateClassName);
       
      // abstract class name
      // 
		// <Rule
		// 	name="Abstract class"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="class"
		// 	attributesOn="abstract"
		// 	attributesOff=""
		// 	parentColor="Class"
		// 	fg="0xC00000"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo abstractClassColor(_rgb(0x00,0x00,0xC0), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, className.m_ruleName);
      SymbolColorRule abstractClassName("Abstract class",
                                        abstractClassColor,
                                        "class",
                                        VS_TAGFLAG_abstract, 0);
      addRule(abstractClassName);
       
      // interface name
      // 
		// <Rule
		// 	name="Interface class"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="interface"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="Class"
		// 	fg="0xFF0000"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo interfaceColor(_rgb(0x00,0x00,0xFF), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, className.m_ruleName);
      SymbolColorRule interfaceName("Interface class",
                                    interfaceColor,
                                    "interface",
                                    0, 0);
      addRule(interfaceName);
       
      // struct name
      // 
		// <Rule
		// 	name="Struct"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="struct"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="Class"
		// 	fg="0x808000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo structColor(_rgb(0x00,0x80,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, className.m_ruleName);
      SymbolColorRule structName("Struct",
                                 structColor,
                                 "struct",
                                 0, 0);
      addRule(structName);
       
      // union name
      // 
		// <Rule
		// 	name="Union or variant type"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="union"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="Class"
		// 	fg="0xA0A0"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo unionColor(_rgb(0xA0,0xA0,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, className.m_ruleName);
      SymbolColorRule unionName("Union or variant type",
                                unionColor,
                                "union",
                                0, 0);
      addRule(unionName);
       
      // typedef name
      // 
		// <Rule
		// 	name="Type definition or alias"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="typedef"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x404080"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo typedefColor(_rgb(0x80,0x40,0x40), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule typedefName("Type definition or alias",
                                  typedefColor,
                                  "typedef",
                                  0, 0);
      addRule(typedefName);
       
      // #define name, use system color for preprocessing
      // 
		// <Rule
		// 	name="Preprocessor macro"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="define"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_PPKEYWORD*"
		// 	fontFlags="F_BOLD|F_INHERIT_STYLE|F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR">
		// </Rule>
      // 
      ColorInfo defineColor(-1, -1, F_INHERIT_FG_COLOR|F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_PPKEYWORD);
      SymbolColorRule defineName("Preprocessor macro",
                                  defineColor,
                                  "define",
                                  0, 0);
      addRule(defineName);
       
      // namespace/package
      // 
		// <Rule
		// 	name="Package or namespace"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="package,prog,lib"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x2080"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo packageColor(_rgb(0x80,0x20,0x00), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule packageName("Package or Namespace",
                                  packageColor,
                                  "package,prog,lib",
                                  0, 0);
      addRule(packageName);
      
      // constant, gray color
      // 
		// <Rule
		// 	name="Symbolic constant"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="const"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x606060"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      // 
      ColorInfo constantColor(_rgb(0x60,0x60,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule constantName("Symbolic constant",
                                  constantColor,
                                  "const",
                                  0, 0);
      addRule(constantName);
       
      // enumerated type
      // 
		// <Rule
		// 	name="Enumerated type or constant"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="enumc,enum"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x808000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo enumColor(_rgb(0x00,0x80,0x80), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule enumName("Enumerated type or constant",
                               enumColor,
                               "enum,enumc",
                               0, 0);
      addRule(enumName);
       
      // label, really dark blue
      // 
		// <Rule
		// 	name="Statement label"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="label"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0x600000"
		// 	fontFlags="F_INHERIT_STYLE|F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo labelColor(_rgb(0x00,0x00,0x60), -1, F_INHERIT_BG_COLOR|F_INHERIT_STYLE, CFG_WINDOW_TEXT);
      SymbolColorRule labelName("Statement label",
                               labelColor,
                               "label",
                               0, 0);
      addRule(labelName);

      // catch-all for any symbol which is context tagging can not find
      // 
		// <Rule
		// 	name="Symbol not found"
		// 	regexType=""
		// 	classRE=""
		// 	nameRE=""
		// 	kinds="UNKNOWN"
		// 	attributesOn=""
		// 	attributesOff=""
		// 	parentColor="*CFG_WINDOW_TEXT*"
		// 	fg="0xFF"
		// 	fontFlags="F_INHERIT_BG_COLOR">
		// </Rule>
      //
      ColorInfo unknownColor(_rgb(0xFF,0x00,0x00), -1, F_INHERIT_BG_COLOR, CFG_WINDOW_TEXT);
      SymbolColorRule unknownName("Symbol not found",
                                  unknownColor,
                                  "UNKNOWN",
                                  0, 0);
      addRule(unknownName);
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
   boolean equals(sc.lang.IEquals &rhs) {
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

};


