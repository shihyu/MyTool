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
#require "se/color/SymbolColorRule.e"
#require "se/color/SymbolColorRuleBase.e"
#import "stdprocs.e"
#endregion

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * The SymbolColorRuleBaseCache class is used to cache the active 
 * symbol coloring rule bases being used for different buffers 
 * or windows, as well as indexing information about those rule 
 * bases, such as allocated color IDs and rule lookup tables. 
 * <p> 
 * The class is designed to be a transient class instance, 
 * not something to ever be saved to the state file.  It's class 
 * instance should be saved using _SetDialogInfo() for _mdi.
 */
class SymbolColorRuleIndex {

   /**
    * Rule base that symbol coloring needs to be performed against.
    */
   SymbolColorRuleBase m_scheme;

   /**
    * This index partitions the rules by tag type, creating rule 
    * subsets for each tag type ID based on the tag type filtering 
    * flags specified in the rule.  It also indexes rules based on 
    * the presence or absense of the public, private, protected, and 
    * package scope flags, as well as static and abstract flags. 
    * This optimization lets us apply rules more quickly since we only 
    * need to test the rule subset, not all rules. 
    * <p> 
    * This field is paired with 'm_rulesByTypeForRuleBase' which 
    * points to the rule base instance (typically 
    * 'def_symbol_color_scheme') which the lookup table applies to. 
    */
   int m_rulesByType[][][];

   /**
    * This hash table is used to map symbol color rule names to color IDs. 
    */
   int m_colorIdHash:[];

   /**
    * How many SymbolColorAnalyzer's have pointers to this rule index? 
    */
   private int m_referenceCount;


   /**
    * Construct a symbol color rule base index.
    */
   private SymbolColorRuleIndex(SymbolColorRuleBase ruleBase=null) {
      m_scheme = ruleBase;
      m_rulesByType = null;
      m_colorIdHash = null;
      m_referenceCount = 0;
   }

   /**
    * Clean up resources used by this class instance.
    */
   ~SymbolColorRuleIndex() {
      m_scheme = null;
      m_rulesByType = null;
      freeAllocatedColorIds();
      m_colorIdHash = null;
      m_referenceCount = 0;
   }

   /**
    * Release all symbol colors previously allocated for this analyzer. 
    */
   void freeAllocatedColorIds() {
      orig_wid := _create_temp_view(auto temp_wid=0);
      foreach (auto colorName => auto colorId in m_colorIdHash) {
         _FreeColor(colorId);
      }
      m_colorIdHash = null;
      _delete_temp_view(temp_wid);
      if (_iswindow_valid(orig_wid)) {
         activate_window(orig_wid);
      }
   }

   /**
    * Get the color ID for the rule with the given name 
    */
   int getColorId(SymbolColorRule &rule) {
      colorName := rule.m_ruleName;
      if (m_colorIdHash != null && m_colorIdHash._indexin(colorName)) {
         return m_colorIdHash:[colorName];
      }
      if (m_scheme==null) return CFG_WINDOW_TEXT;
      if (rule.m_colorInfo==null) return CFG_WINDOW_TEXT;
      colorId := rule.m_colorInfo.getColorId(&m_scheme);
      m_colorIdHash:[colorName] = colorId;
      return colorId;  
   }

   /**
    * Get the color ID for the rule with the given name 
    * with the given accent added to font 
    */
   int getStyledColorId(SymbolColorRule &rule, int fontFlag) {
      if (m_scheme==null) return CFG_WINDOW_TEXT;
      if (rule.m_colorInfo == null) return CFG_WINDOW_TEXT;

      origFontFlags := rule.m_colorInfo.getFontFlags(&m_scheme);
      if ((origFontFlags & fontFlag) == fontFlag) {
         return getColorId(rule);
      }
      colorName := rule.m_ruleName"("fontFlag")";
      if (m_colorIdHash != null && m_colorIdHash._indexin(colorName)) {
         return m_colorIdHash:[colorName];
      }
      origFontFlags &= ~(F_UNDERLINE|F_ITALIC|F_STRIKE_THRU|F_BOLD|F_INHERIT_STYLE);
      ColorInfo tmpColorInfo = rule.m_colorInfo;
      tmpColorInfo.m_fontFlags = origFontFlags|fontFlag;
      colorId := tmpColorInfo.getColorId(&m_scheme);
      m_colorIdHash:[colorName] = colorId;
      return colorId;  
   }

   /**
    * Allocate a symbol coloring rule index.  This is only used by the 
    * SymbolColorAnalyzer.  This is the ONLY way to allocate a symbol 
    * color rule index.  Because the rule index deals with resource handles 
    * (color ids), this should be used with great care. 
    * 
    * @param scheme     color scheme to associate with this index 
    * 
    * @return Returns a pointer to the instance of the rule index allocated. 
    *         This pointer MUST be deleted using freeRuleIndex, since it
    *         is a reference counted resource. 
    */
   static SymbolColorRuleIndex *allocateRuleIndex(SymbolColorRuleBase &scheme) {

      // get a pointer to the array of rule indexes
      SymbolColorRuleIndex (*ruleList)[] = null;
      ruleList = _GetDialogInfoHtPtr("SymbolColorRuleIndex", _mdi);
      if (ruleList == null) {
         SymbolColorRuleIndex tmpRuleList[] = null;
         _SetDialogInfoHt("SymbolColorRuleIndex", tmpRuleList, _mdi);
         ruleList = _GetDialogInfoHtPtr("SymbolColorRuleIndex", _mdi);
      }

      // first, look for a match
      i := 0;
      numSchemes := ruleList->_length();
      for (i=0; i<numSchemes; ++i) {
         if (ruleList->[i] == null) continue;
         if (ruleList->[i].m_scheme == scheme) {
            ruleList->[i].m_referenceCount++;
            return &ruleList->[i];
         }
      }

      // next, look for an open slot
      for (i=0; i<numSchemes; ++i) {
         if (ruleList->[i] == null) {
            SymbolColorRuleIndex ruleIndex(scheme);
            ruleIndex.m_referenceCount=1;
            ruleList->[i] = ruleIndex;
            return &(ruleList->[i]);
         }
      }

      // no match, add one to the end of the list
      SymbolColorRuleIndex ruleIndex(scheme);
      ruleIndex.m_referenceCount=1;
      ruleList->[numSchemes] = ruleIndex;
      return &(ruleList->[numSchemes]);
   }

   /** 
    * Use this method to free a symbol color rule index resource allocated 
    * using {@link allocateRuleIndex()}, above.  This method is ONLY used by 
    * the SymbolColorAnalyzer. 
    * 
    * @param pRuleIndex    pointer to rule index to release.
    */
   static void freeRuleIndex(SymbolColorRuleIndex *pRuleIndex) {

      // get a pointer to the rule list
      SymbolColorRuleBase (*ruleList)[] = null;
      ruleList = _GetDialogInfoHtPtr("SymbolColorRuleIndex", _mdi);

      // no rule list, then nothing to delete
      if (ruleList == null) return;

      // find the rule index to free
      numSchemes := ruleList->_length();
      for (i:=0; i<numSchemes; ++i) {
         if (ruleList->[i] == null) continue;
         if ( (typeless*) &(ruleList->[i]) == pRuleIndex) {
            pRuleIndex->m_referenceCount--;
            if ( pRuleIndex->m_referenceCount <= 0 ) {
               ruleList->[i] = null;
               return;
            }
         }
      }

      // did not find that rule index, don't know why and don't care
   }

};

