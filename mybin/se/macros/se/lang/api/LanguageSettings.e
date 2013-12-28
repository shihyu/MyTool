////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49791 $
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
#include "se/lang/api/LanguageSettings.sh"
#import "autocomplete.e"
#import "adaptiveformatting.e"
#import "box.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/color/SymbolColorAnalyzer.e"
#endregion

#define LANGUAGE_OPTIONS_KEY "LanguageOptions"

namespace se.lang.api;

/**
 * This class is used to save and retrieve the language definition and language 
 * options.  These used to be accessed by changing def-language-<lang> and 
 * def-options-<lang> directly.  Now all items can be accessed through static 
 * getter and setter methods in this class. 
 * 
 */
class LanguageSettings {
   
   /***********************************************************
    * 0. LOI_SYNTAX_INDENT                                    *
    * 1. LOI_SYNTAX_EXPANSION                                 *
    * 2. LOI_MIN_ABBREVIATION                                 *
    * 3. LOI_KEYWORD_CASE                                     *
    * 4. begin/end style                                      *
    * 5. LOI_INDENT_FIRST_LEVEL                               *  
    * 6. LOI_MAIN_STYLE                                       *
    * 7. LOI_INDENT_CASE_FROM_SWITCH                          *
    * 8. LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS   *
    **********************************************************/ 
   static int s_defaultLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_KEYWORD_CASE, BRACE_STYLE, LOI_INDENT_FIRST_LEVEL, LOI_MAIN_STYLE, LOI_INDENT_CASE_FROM_SWITCH,
      LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS };

      /*******************************************************
       * 0. LOI_SYNTAX_INDENT                                *
       * 1. LOI_SYNTAX_EXPANSION                             *
       * 2. LOI_TAG_CASE                                     *
       * 3. LOI_ATTRIBUTE_CASE                               *
       * 4. LOI_WORD_VALUE_CASE                              *
       * 5. LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS     *
       * 6. LOI_QUOTES_FOR_NUMERIC_VALUES                    *
       * 7. LOI_QUOTES_FOR_SINGLE_WORD_VALUES                *
       * 8. LOI_USE_COLOR_NAMES                              *
       * 9.  LOI_USE_DIV_TAGS_FOR_ALIGNMENT                  *
       * 10. LOI_USE_PATHS_FOR_FILE_ENTRIES                  *
       * 11. LOI_HEX_VALUE_CASE                              *
       * 12. LOI_AUTO_SYMBOL_TRANSLATION                     *
       * 13. LOI_INSERT_RIGHT_ANGLE_BRACKET                  *
       * 14. temps[0]                                        *
       ******************************************************/
   static int s_htmlLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_TAG_CASE, LOI_ATTRIBUTE_CASE,
      LOI_WORD_VALUE_CASE, LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, LOI_QUOTES_FOR_NUMERIC_VALUES, 
      LOI_QUOTES_FOR_SINGLE_WORD_VALUES, LOI_USE_COLOR_NAMES, LOI_USE_DIV_TAGS_FOR_ALIGNMENT, LOI_USE_PATHS_FOR_FILE_ENTRIES,
      LOI_HEX_VALUE_CASE, LOI_AUTO_SYMBOL_TRANSLATION, LOI_INSERT_RIGHT_ANGLE_BRACKET };                                   

      /*******************************************************
       * 0. LOI_SYNTAX_INDENT                                *
       * 1. LOI_SYNTAX_EXPANSION                             *
       * 2. LOI_TAG_CASE                                     *
       * 3. LOI_ATTRIBUTE_CASE                               *
       * 4. LOI_WORD_VALUE_CASE                              *  
       * 5. temps[0]                                         *
       * 6. LOI_QUOTES_FOR_NUMERIC_VALUES                    *                        
       * 7. LOI_QUOTES_FOR_SINGLE_WORD_VALUES                *                                
       * 8. temps[1]                                         *
       * 9.  temps[2]                                        *
       * 10. temps[3]                                        *
       * 11. LOI_HEX_VALUE_CASE                              *
       * 12. LOI_AUTO_VALIDATE_ON_OPEN                       *
       * 13. LOI_AUTO_CORRELATE_START_END_TAGS               *
       * 14. LOI_AUTO_SYMBOL_TRANSLATION                     *
       ******************************************************/ 
   static int s_xmlLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_TAG_CASE, LOI_ATTRIBUTE_CASE,
      LOI_WORD_VALUE_CASE, SPACE_HOLDER, LOI_QUOTES_FOR_NUMERIC_VALUES, LOI_QUOTES_FOR_SINGLE_WORD_VALUES, 
      SPACE_HOLDER, SPACE_HOLDER, SPACE_HOLDER, LOI_HEX_VALUE_CASE, LOI_AUTO_VALIDATE_ON_OPEN, 
      LOI_AUTO_CORRELATE_START_END_TAGS, LOI_AUTO_SYMBOL_TRANSLATION };                                   

      /*******************************************************
       * 0. LOI_SYNTAX_INDENT                                *
       * 1. LOI_SYNTAX_EXPANSION                             *
       * 2. LOI_MIN_ABBREVIATION                             *
       * 3. LOI_KEYWORD_CASE                                 *
       * 4. begin/end style                                  *
       * 5. LOI_BEGIN_END_COMMENTS                           *  
       * 6. LOI_INDENT_CASE_FROM_SWITCH                      *                        
       ******************************************************/ 
   static int s_pasLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_KEYWORD_CASE, BRACE_STYLE, LOI_BEGIN_END_COMMENTS, LOI_INDENT_CASE_FROM_SWITCH };

      /***********************************************************
       * 0. LOI_SYNTAX_INDENT                                    *
       * 1. LOI_SYNTAX_EXPANSION                                 *
       * 2. LOI_MIN_ABBREVIATION                                 *
       * 3. LOI_KEYWORD_CASE                                     *
       * 4. temps[0]                                             *  
       * 5. temps[1]                                             *
       * 6. LOI_MULTILINE_IF_EXPANSION                           *
       * 7. temps[2]                                             *
       **********************************************************/ 
   static int s_forLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_KEYWORD_CASE, SPACE_HOLDER, SPACE_HOLDER, LOI_MULTILINE_IF_EXPANSION };

      /***********************************************************
       * 0. LOI_SYNTAX_INDENT                                    *
       * 1. LOI_SYNTAX_EXPANSION                                 *
       * 2. LOI_MIN_ABBREVIATION                                 *
       * 3. LOI_KEYWORD_CASE                                     *
       * 4. temps[0]                                             *  
       * 5. LOI_COBOL_SYNTAX                                     *
       **********************************************************/ 
   static int s_cobLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_KEYWORD_CASE, SPACE_HOLDER, LOI_COBOL_SYNTAX };

      /*******************************************************
       * 0. LOI_SYNTAX_INDENT                                *
       * 1. LOI_SYNTAX_EXPANSION                             *
       * 2. LOI_MIN_ABBREVIATION                             *
       * 3. LOI_KEYWORD_CASE                                 *
       * 4. begin/end style                                  *
       * 5. LOI_AUTO_INSERT_LABEL                            *                        
       ******************************************************/ 
   static int s_vhdLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_KEYWORD_CASE, BRACE_STYLE, LOI_AUTO_INSERT_LABEL };

      /***********************************************************
       * 0. LOI_SYNTAX_INDENT                                    *
       * 1. LOI_SYNTAX_EXPANSION                                 *
       * 2. LOI_MIN_ABBREVIATION                                 *
       * 3. LOI_RUBY_STYLE                                       *
       * 4. begin/end style                                      *
       * 5. LOI_INDENT_FIRST_LEVEL                               *
       * 6. LOI_MAIN_STYLE                                       *
       * 7. LOI_INDENT_CASE_FROM_SWITCH                          *
       * 8. LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS   *
       **********************************************************/ 
   static int s_rubyLangDefinition[] = { LOI_SYNTAX_INDENT, LOI_SYNTAX_EXPANSION, LOI_MIN_ABBREVIATION,                              
      LOI_RUBY_STYLE, BRACE_STYLE, LOI_INDENT_FIRST_LEVEL, LOI_MAIN_STYLE, LOI_INDENT_CASE_FROM_SWITCH,
      LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS };                               

   /**
    * Clear the language options cache
    */
   static void clearLanguageOptionsCache()
   {
      _SetDialogInfoHt(LANGUAGE_OPTIONS_KEY, null, _mdi);
   }

   /**
    * Determines if a language with the given langId is defined in the application.
    * 
    * @param langId              langId to look for
    * 
    * @return boolean            true if the given langId is mapped to a defined 
    *                            language.
    */
   public static boolean isLanguageDefined(_str langId)
   {
      index := find_index('def-language-'langId, MISC_TYPE);
      return (index > 0);
   }

   /** 
    * Get the list of all language IDs currently defined in the application. 
    *  
    * @param allLangIds          (output) Array of language IDs 
    */
   public static void getAllLanguageIds(_str (&allLangIds)[])
   {
      langId := "";
      allLangIds._makeempty();
      index := name_match('def-language-',1, MISC_TYPE);
      while (index > 0) {
        langId = substr(name_name(index),14);
        allLangIds[allLangIds._length()] = langId;
        index=name_match('def-language-',0, MISC_TYPE);
      }
   }

   public static boolean doesOptionApplyToLanguage(_str langID, int option)
   {
      // first, make sure this language even has a def-options value
      if (find_index('def-options-'langID, MISC_TYPE) <= 0) return false;

      return isOptionInParseMap(langID, option);
   }

   public static int getAllLanguageOptions(_str langID, VS_LANGUAGE_OPTIONS &langOptions)
   {
      VS_LANGUAGE_SETUP_OPTIONS setup;
      getLanguageDefinitionOptions(langID, setup);
      
      langOptions.szModeName = setup.mode_name;
      langOptions.ColorFlags = setup.color_flags;
      langOptions.szLexerName = setup.lexer_name;

      langOptions.DisplayLineNumbers = (setup.line_numbers_flags & LNF_ON) != 0;
      langOptions.LineNumbersLen = setup.line_numbers_len;
      langOptions.LineNumbersFlags = setup.line_numbers_flags;
      langOptions.szTabs=setup.tabs;
      
      // parse out the margins
      typeless leftMargin = '', rightMargin = '', newParaMargin = '';
      parse setup.margins with leftMargin rightMargin newParaMargin;
      if (newParaMargin == '') newParaMargin = leftMargin;
      if (!isinteger(leftMargin) || !isinteger(rightMargin) || !isinteger(newParaMargin)) {
         leftMargin = 1;
         rightMargin = 254;
         newParaMargin = 1;
      }
      langOptions.LeftMargin = leftMargin;
      langOptions.RightMargin = rightMargin;
      langOptions.NewParagraphMargin = newParaMargin;

      langOptions.WordWrapStyle = setup.word_wrap_style;
      langOptions.IndentWithTabs = setup.indent_with_tabs;
      langOptions.IndentStyle = setup.indent_style;
      langOptions.szWordChars = setup.word_chars;
      langOptions.szEventTableName = setup.keytab_name;
      langOptions.TruncateLength = setup.TruncateLength;

      // parse the bounds info
      typeless boundsStart = '', boundsEnd='';
      parse setup.bounds with boundsStart boundsEnd .;
      if (!isinteger(boundsStart) || !isinteger(boundsEnd) || boundsStart <= 0)  {
         boundsStart = 0;
         boundsEnd = 0;
      }
      langOptions.BoundsStart = boundsStart;
      langOptions.BoundsEnd = boundsEnd;

      langOptions.AutoCaps = setup.caps;
      langOptions.SoftWrap = setup.SoftWrap;
      langOptions.SoftWrapOnWord = setup.SoftWrapOnWord;
      langOptions.ShowTabs = setup.show_tabs;
      langOptions.HexMode = setup.hex_mode;
      
      typeless options[], temps[];
      int parseMap[];
      getLanguageOptionsParseMap(langID, parseMap);
      getLanguageOptions(langID, parseMap, options, temps);
      
      checkAllLanguageOptionDefaults(langID, options);
            
      langOptions.SyntaxExpansion = options[LOI_SYNTAX_EXPANSION];
      langOptions.SyntaxIndent = options[LOI_SYNTAX_INDENT];
      langOptions.minAbbrev = options[LOI_MIN_ABBREVIATION];
      langOptions.IndentCaseFromSwitch = options[LOI_INDENT_CASE_FROM_SWITCH];
      langOptions.KeywordCasing = options[LOI_KEYWORD_CASE];

      langOptions.BeginEndStyle = options[LOI_BEGIN_END_STYLE];
      langOptions.PadParens = options[LOI_PAD_PARENS];
      langOptions.NoSpaceBeforeParen = options[LOI_NO_SPACE_BEFORE_PAREN];
      langOptions.PointerStyle = options[LOI_POINTER_STYLE];
      langOptions.FunctionBraceOnNewLine = options[LOI_FUNCTION_BEGIN_ON_NEW_LINE];
      
      langOptions.TagCasing = options[LOI_TAG_CASE];
      langOptions.AttributeCasing = options[LOI_ATTRIBUTE_CASE];
      langOptions.ValueCasing = options[LOI_WORD_VALUE_CASE];
      langOptions.HexValueCasing = options[LOI_HEX_VALUE_CASE];

      langOptions.szBeginEndPairs = getBeginEndPairs(langID);
      langOptions.szAliasFilename = getAliasFilename(langID);
      langOptions.szInheritsFrom = getLangInheritsFrom(langID);

      return(0);
   }
   
   /**
    * Returns the autobrace placement settings, AUTOBRACE_PLACE_* 
    * for languages that support it.  This controls the placement 
    * of braces when the user types a brace.  It does not effect 
    * brace placement for syntax expansions. 
    *  
    * @param langID 
    * @param defaultValue 
    * 
    * @return int One of the AUTOBRACE_PLACE_* constants.
    */
   public static int getAutoBracePlacement(_str langID, int defaultValue = AUTOBRACE_PLACE_NEXTLINE) {
      return getLanguageDefVar(langID, ONE_LINE_AUTOBRACES_DEF_VAR_KEY, defaultValue);
   }

   /** 
    * Sets the auto-brace placement for the given languages. 
    * 
    * @param langID 
    * @param value AUTOBRACE_PLACE_* constant
    */
   public static void setAutoBracePlacement(_str langID, int value) {
      setLanguageDefVar(langID,ONE_LINE_AUTOBRACES_DEF_VAR_KEY, value);
   }

   /** 
    * Returns the name of the beautifier profile associated with 
    * langID, if any. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    Profile name. 
    *                            
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getBeautifierProfileName(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, BEAUTIFIER_PROFILE_DEF_VAR_KEY, defaultValue);
   }

   /** 
    * Sets the beautifier profile name associated with langID. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeautifierProfileName(_str langID, _str value)
   {
      setLanguageDefVar(langID, BEAUTIFIER_PROFILE_DEF_VAR_KEY, value);
   }

   /** 
    * Returns a set of BEAUT_EXPAND_* flags for the given language,
    * if any. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    Profile name. 
    *                            
    *  
    * @categories LanguageSettings_API 
    */
   public static int getBeautifierExpansions(_str langID, int defaultValue = 0)
   {
      return getLanguageDefVar(langID, BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY, defaultValue);
   }

   /** 
    * Sets the BEAUT_EXPAND_* flags for langID. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeautifierExpansions(_str langID, int value)
   {
      setLanguageDefVar(langID, BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY, value);
   }

   public static void setAllLanguageOptions(_str langID, VS_LANGUAGE_OPTIONS &langOptions)
   {
      // changing language options, so clear cache
      clearLanguageOptionsCache();

      // now set up the new language options struct
      VS_LANGUAGE_SETUP_OPTIONS setup;
      setup.mode_name = langOptions.szModeName;
      setup.color_flags = langOptions.ColorFlags;
      setup.lexer_name = langOptions.szLexerName;
      setup.line_numbers_len = langOptions.LineNumbersLen;
      setup.line_numbers_flags = langOptions.LineNumbersFlags;
      setup.tabs = langOptions.szTabs;
      setup.word_wrap_style = langOptions.WordWrapStyle;
      setup.indent_with_tabs = langOptions.IndentWithTabs;
      setup.indent_style = langOptions.IndentStyle;
      setup.word_chars = langOptions.szWordChars;
      setup.keytab_name = langOptions.szEventTableName;
      setup.TruncateLength = langOptions.TruncateLength;
      setup.caps = langOptions.AutoCaps;
      setup.SoftWrap = langOptions.SoftWrap;
      setup.SoftWrapOnWord = langOptions.SoftWrapOnWord;
      setup.show_tabs = langOptions.ShowTabs;
      setup.hex_mode = langOptions.HexMode;

      setup.margins = strip(langOptions.LeftMargin' 'langOptions.RightMargin' 'langOptions.NewParagraphMargin);
      setup.bounds = strip(langOptions.BoundsStart' 'langOptions.BoundsEnd);
      setLanguageDefinitionOptions(langID, setup);   
            
      typeless options[], temps[];
      int parseMap[];
      getLanguageOptionsParseMap(langID, parseMap);
      optionsIndex := getLanguageOptions(langID, parseMap, options, temps);
            
      if (langOptions.SyntaxExpansion != null) options[LOI_SYNTAX_EXPANSION] = langOptions.SyntaxExpansion;
      if (langOptions.SyntaxIndent != null) options[LOI_SYNTAX_INDENT] = langOptions.SyntaxIndent;
      if (langOptions.minAbbrev != null) options[LOI_MIN_ABBREVIATION] = langOptions.minAbbrev;
      if (langOptions.IndentCaseFromSwitch != null) options[LOI_INDENT_CASE_FROM_SWITCH] = langOptions.IndentCaseFromSwitch;
      if (langOptions.KeywordCasing != null) options[LOI_KEYWORD_CASE] = langOptions.KeywordCasing;

      if (langOptions.BeginEndStyle != null) options[LOI_BEGIN_END_STYLE] = langOptions.BeginEndStyle;
      if (langOptions.PadParens != null) options[LOI_PAD_PARENS] = langOptions.PadParens;
      if (langOptions.NoSpaceBeforeParen != null) options[LOI_NO_SPACE_BEFORE_PAREN] = langOptions.NoSpaceBeforeParen;
      if (langOptions.PointerStyle != null) options[LOI_POINTER_STYLE] = langOptions.PointerStyle;
      if (langOptions.FunctionBraceOnNewLine != null) options[LOI_FUNCTION_BEGIN_ON_NEW_LINE] = langOptions.FunctionBraceOnNewLine;
      
      if (langOptions.TagCasing != null) options[LOI_TAG_CASE] = langOptions.TagCasing;
      if (langOptions.AttributeCasing != null) options[LOI_ATTRIBUTE_CASE] = langOptions.AttributeCasing;
      if (langOptions.ValueCasing != null) options[LOI_WORD_VALUE_CASE] = langOptions.ValueCasing;
      if (langOptions.HexValueCasing != null) options[LOI_HEX_VALUE_CASE] = langOptions.HexValueCasing;

      setLanguageOptions(optionsIndex, langID, parseMap, options, temps);

      if (langOptions.szBeginEndPairs != null) setBeginEndPairs(langID, langOptions.szBeginEndPairs);
      if (langOptions.szAliasFilename != null) setAliasFilename(langID, langOptions.szAliasFilename);
      if (langOptions.szInheritsFrom != null) setLangInheritsFrom(langID, langOptions.szInheritsFrom);

   }
   
   /**
    * Retrieves a VS_LANGUAGE_SETUP_OPTIONS struct populated with options for 
    * the given language. 
    * 
    * @param langID           language of interest
    * @param setup            struct to populate
    * 
    * @return                 the index of def-language-<langID> 
    *  
    * @categories LanguageSettings_API 
    */
   public static int getLanguageDefinitionOptions(_str langID, VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      // fill our array with all the info
      typeless langInfo[];
      setupIndex := getLangDefinition(langID, langInfo);

      if (setupIndex) {
         // check for defaults
         checkAllLanguageDefinitionDefaults(langID, langInfo);
         
         // now populate the struct
         setup.mode_name = langInfo[LDI_MODE_NAME];
         setup.tabs = langInfo[LDI_TABS];
         setup.margins = langInfo[LDI_MARGINS];
         setup.keytab_name = langInfo[LDI_KEY_TABLE];
         setup.word_wrap_style = langInfo[LDI_WORD_WRAP];
         setup.indent_with_tabs = langInfo[LDI_INDENT_WITH_TABS];
         setup.show_tabs = langInfo[LDI_SHOW_TABS];
         setup.hex_mode = langInfo[LDI_HEX_MODE];
         setup.indent_style = langInfo[LDI_INDENT_STYLE];
         setup.word_chars = getWordChars(langID);
         setup.lexer_name = langInfo[LDI_LEXER_NAME];
         setup.color_flags = langInfo[LDI_COLOR_FLAGS];
         setup.line_numbers_flags = langInfo[LDI_LINE_NUMBERS_FLAGS];
         setup.line_numbers_len = langInfo[LDI_LINE_NUMBERS_LENGTH];
         setup.TruncateLength = langInfo[LDI_TRUNCATE_LENGTH];
         setup.bounds = langInfo[LDI_BOUNDS];
         setup.caps = langInfo[LDI_CAPS];
         setup.SoftWrap = langInfo[LDI_SOFT_WRAP];
         setup.SoftWrapOnWord = langInfo[LDI_SOFT_WRAP_ON_WORD];
      }
   
      
      // Allow beautifier to optionally sync its settings into the array.
      hook := find_index('_'langID'_language_definition_sync', PROC_TYPE);
      if (hook) {
         call_index(setup, hook);
      }
         
      return setupIndex;
   }
   
   /**
    * Sets the options contained in a VS_LANGUAGE_SETUP_OPTIONS struct for the 
    * given language.  Internally, these values are contained in 
    * def-language-<langID>. 
    * 
    * @param langID           language of interest
    * @param setup            struct to populate 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLanguageDefinitionOptions(_str langID, VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      // fill our array with all the info
      typeless langInfo[];
      setupIndex := getLangDefinition(langID, langInfo);
      
      // handle word chars separately
      setWordChars(langID, setup.word_chars);
      setup.word_chars = WORD_CHARS_NOT_APPLICABLE;

      // now populate the array with struct info
      languageSetupToArray(setup, langInfo);
      
      setLangDefinition(setupIndex, langInfo);
   }
   
   /**
    * Builds a language setup string (such as contained in def-langugage-<langID>) 
    * given a VS_LANGUAGE_SETUP_OPTIONS object containing language options.
    * 
    * @param setup   language options
    * 
    * @return        def-language string 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getLanguageSetupStringFromSetupOptions(VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      typeless langInfo[];

      // now populate the array with struct info
      languageSetupToArray(setup, langInfo);

      return buildLangDefinitionString(langInfo);
   }

   /**
    * Transfers the language data contained in a VS_LANGUAGE_SETUP_OPTIONS object 
    * into an array indexed by the items in the LanguageDefinitionItems enum.  If 
    * any of the items in the struct are null, then these are not transferred over.
    * 
    * @param setup            language options
    * @param langInfo         array to receive info 
    *  
    * @categories LanguageSettings_API 
    */
   private static void languageSetupToArray(VS_LANGUAGE_SETUP_OPTIONS &setup, typeless (&langInfo)[])
   {
      if (setup.mode_name != null) langInfo[LDI_MODE_NAME] = setup.mode_name;
      if (setup.tabs != null) langInfo[LDI_TABS] = setup.tabs;
      if (setup.margins != null) langInfo[LDI_MARGINS] = setup.margins;
      if (setup.keytab_name != null) langInfo[LDI_KEY_TABLE] = setup.keytab_name;
      if (setup.word_wrap_style != null) langInfo[LDI_WORD_WRAP] = setup.word_wrap_style;
      if (setup.indent_with_tabs != null) langInfo[LDI_INDENT_WITH_TABS] = setup.indent_with_tabs;
      if (setup.show_tabs != null) langInfo[LDI_SHOW_TABS] = setup.show_tabs;
      if (setup.hex_mode != null) langInfo[LDI_HEX_MODE] = setup.hex_mode;
      if (setup.indent_style != null) langInfo[LDI_INDENT_STYLE] = setup.indent_style;
      if (setup.word_chars != null) langInfo[LDI_WORD_CHARS] = setup.word_chars;
      if (setup.lexer_name != null) langInfo[LDI_LEXER_NAME] = setup.lexer_name;
      if (setup.color_flags != null) langInfo[LDI_COLOR_FLAGS] = setup.color_flags;
      if (setup.line_numbers_flags != null) langInfo[LDI_LINE_NUMBERS_FLAGS] = setup.line_numbers_flags;
      if (setup.line_numbers_len != null) langInfo[LDI_LINE_NUMBERS_LENGTH] = setup.line_numbers_len;
      if (setup.TruncateLength != null) langInfo[LDI_TRUNCATE_LENGTH] = setup.TruncateLength;
      if (setup.bounds != null) langInfo[LDI_BOUNDS] = setup.bounds;
      if (setup.caps != null) langInfo[LDI_CAPS] = setup.caps;
      if (setup.SoftWrap != null) langInfo[LDI_SOFT_WRAP] = setup.SoftWrap;
      if (setup.SoftWrapOnWord != null) langInfo[LDI_SOFT_WRAP_ON_WORD] = setup.SoftWrapOnWord;
   }

   /**
    * Retrieves a specific language setting.  Use the LanguageSettingsIndices 
    * enum to specify the item wanted.
    * 
    * @param langID     language 
    * @param item       item desired (LanguageSettingsIndices enum)
    * 
    * @return           the requested value or an empty string if the index is 
    *                   invalid
    */
   private static typeless getLangDefinitionItem(_str langID, int item, typeless defaultValue)
   {
      typeless langInfo[];
      typeless value = null;
      if (getLangDefinition(langID, langInfo) > 0) {
         value = langInfo[item];
      }
         
      maybeUseLanguageDefinitionItemDefault(langID, item, value, defaultValue);
      
      return value;
   }
   
   /**
    * Parses the Language definition to get all the settings included within.
    * 
    * @param langID           language
    * @param langInfo         array to fill with settings
    * 
    * @return                 index of def-language-langID
    */
   private static int getLangDefinition(_str langID, typeless (&langInfo)[])
   {
      _str info;
      setupIndex := find_index('def-language-'langID, MISC_TYPE);
      if (setupIndex) {
         info = name_info(setupIndex);
         parseLangDefinitionString(info, langInfo);
      }
   
      return setupIndex;   
   }
   
   /**
    * Parses the language definition string so that the values are stored in an 
    * array, where each item corresponds to the appropriate index as defined by the 
    * LDI enum. 
    * 
    * @param info          string to be parsed
    * @param langInfo      array to be filled with values
    */
   private static void parseLangDefinitionString(_str info, typeless (&langInfo)[])
   {
      parse info with MODE_NAME_SHORT_KEY'=' langInfo[LDI_MODE_NAME] ',' TABS_SHORT_KEY'=' langInfo[LDI_TABS] ','\
         MARGINS_SHORT_KEY'=' langInfo[LDI_MARGINS] ',' KEY_TABLE_SHORT_KEY'=' langInfo[LDI_KEY_TABLE] ',' WORD_WRAP_SHORT_KEY'='langInfo[LDI_WORD_WRAP] ','\
         INDENT_WITH_TABS_SHORT_KEY'='langInfo[LDI_INDENT_WITH_TABS] ',' SHOW_TABS_SHORT_KEY'='langInfo[LDI_SHOW_TABS] ','\
         INDENT_STYLE_SHORT_KEY'='langInfo[LDI_INDENT_STYLE] ',' WORD_CHARS_SHORT_KEY'='langInfo[LDI_WORD_CHARS]','\
         LEXER_NAME_SHORT_KEY'='langInfo[LDI_LEXER_NAME]',' COLOR_FLAGS_SHORT_KEY'='langInfo[LDI_COLOR_FLAGS]','\
         LINE_NUMBERS_LEN_SHORT_KEY'='langInfo[LDI_LINE_NUMBERS_LENGTH]',' TRUNCATE_LENGTH_SHORT_KEY'='langInfo[LDI_TRUNCATE_LENGTH]','\
         BOUNDS_SHORT_KEY'='langInfo[LDI_BOUNDS]',' CAPS_SHORT_KEY'='langInfo[LDI_CAPS]',' SOFT_WRAP_SHORT_KEY'='langInfo[LDI_SOFT_WRAP]','\
         SOFT_WRAP_ON_WORD_SHORT_KEY'='langInfo[LDI_SOFT_WRAP_ON_WORD]',' HEX_MODE_SHORT_KEY'='langInfo[LDI_HEX_MODE]','\
         LINE_NUMBERS_FLAGS_SHORT_KEY'='langInfo[LDI_LINE_NUMBERS_FLAGS]',';
   }

   /**
    * Set a specific language setting.  Use the LanguageSettingsIndices 
    * enum to specify the item to be set.
    * 
    * @param langID     language 
    * @param item       item desired (LanguageSettingsIndices enum) 
    * @param value      item's new value 
    * @param createNewLang       whether to create the setting for 
    *                            this language if it does not
    *                            already exist
    */
   private static void setLangDefinitionItem(_str langID, int item, typeless value, boolean createNewLang = false)
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      typeless langInfo[];
      setupIndex := getLangDefinition(langID, langInfo);

      // does this language currently exist?
      if (setupIndex <= 0) {
         // we might want to create it
         if (createNewLang) {
            info := _GetDefaultLanguageSetupInfo(langID);
            setupIndex = insert_name('def-language-'langID, MISC_TYPE, info);
            _config_modify_flags(CFGMODIFY_DEFDATA);

            parseLangDefinitionString(info, langInfo);
         } else {
            return;
         }
      }

      // no need to do all this if the value is the same anyway!
      if (setupIndex <= 0 || (langInfo[item] != null && langInfo[item] :== value)) return;

      langInfo[item] = value;
      setLangDefinition(setupIndex, langInfo);
   }

   /**
    * Builds the language setup string from an array of language settings.
    * 
    * @return           setup string
    */
   private static _str buildLangDefinitionString(typeless (&langInfo)[])
   {
      info := MODE_NAME_SHORT_KEY'='langInfo[LDI_MODE_NAME]','TABS_SHORT_KEY'=' langInfo[LDI_TABS] :+
         ','MARGINS_SHORT_KEY'=' langInfo[LDI_MARGINS]','KEY_TABLE_SHORT_KEY'=' langInfo[LDI_KEY_TABLE]','WORD_WRAP_SHORT_KEY'='langInfo[LDI_WORD_WRAP] :+
         ','INDENT_WITH_TABS_SHORT_KEY'='langInfo[LDI_INDENT_WITH_TABS]','SHOW_TABS_SHORT_KEY'='langInfo[LDI_SHOW_TABS] :+
         ','INDENT_STYLE_SHORT_KEY'='langInfo[LDI_INDENT_STYLE]','WORD_CHARS_SHORT_KEY'='langInfo[LDI_WORD_CHARS] :+
         ','LEXER_NAME_SHORT_KEY'='langInfo[LDI_LEXER_NAME]','COLOR_FLAGS_SHORT_KEY'='langInfo[LDI_COLOR_FLAGS] :+
         ','LINE_NUMBERS_LEN_SHORT_KEY'='langInfo[LDI_LINE_NUMBERS_LENGTH]','TRUNCATE_LENGTH_SHORT_KEY'='langInfo[LDI_TRUNCATE_LENGTH] :+
         ','BOUNDS_SHORT_KEY'='langInfo[LDI_BOUNDS]','CAPS_SHORT_KEY'='langInfo[LDI_CAPS]','SOFT_WRAP_SHORT_KEY'='langInfo[LDI_SOFT_WRAP] :+
         ','SOFT_WRAP_ON_WORD_SHORT_KEY'='langInfo[LDI_SOFT_WRAP_ON_WORD]','HEX_MODE_SHORT_KEY'='langInfo[LDI_HEX_MODE] :+ 
         ','LINE_NUMBERS_FLAGS_SHORT_KEY'='langInfo[LDI_LINE_NUMBERS_FLAGS]',';

      return info;
   }

   /**
    * Sets the language definition (def-language-<langID>) values.
    * 
    * @param setupIndex          index in names table where def-language-<langID> 
    *                            is located
    * @param langInfo            array containing our values, with values 
    *                            corresponding to the appropriate LDI enum value
    */
   private static void setLangDefinition(int setupIndex, typeless (&langInfo)[])
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      info := strip(buildLangDefinitionString(langInfo));
      set_name_info(setupIndex, info);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   
   /**
    * Returns true if syntax expansions, alias expansions and the 
    * like should run the beautifier on the expanded code. 
    * 
    * @return boolean 
    */
   public static boolean shouldBeautifyExpansions(_str langId)
   {
      //TODO: Promote this to a real option. 
      return langId == 'c' || langId == 'm';
   }

   /**
    * Determines if a particular option (noted by the corresponding value in 
    * LanguageOptionItems enum) is available for a particular language. 
    * 
    * @param langID           language to check
    * @param option           LanguageOptionItems enum value corresponding to the 
    *                         option we are interested in
    * 
    * @return                 true if the given option is included in this 
    *                         language's set of options, false otherwise
    */
   private static boolean isOptionInParseMap(_str langID, int option)
   {
      int parseMap[];
      getLanguageOptionsParseMap(langID, parseMap);

      if (isBeginEndStyleItem(option)) option = BRACE_STYLE;

      foreach (auto parseOption in parseMap) {
         if (parseOption == option) return true;
      }

      return false;
   }

   /**
    * Retrieves the parse map for the given language.  The parse map defines how to 
    * parse out the options found at def-options-<langID>. 
    * 
    * @param langID                 language of interest
    * @param langDefinition         parse map
    */
   private static void getLanguageOptionsParseMap(_str langID, int (&langDefinition)[])
   {
      if (_LanguageInheritsFrom('html', langID) || _LanguageInheritsFrom('xml', langID) ) {

         if (_LanguageInheritsFrom('html',langID) && !_LanguageInheritsFrom('tld',langID)) {
            langDefinition = s_htmlLangDefinition;
         } else langDefinition = s_xmlLangDefinition;
      } else {  
         if (_LanguageInheritsFrom('pas', langID)) langDefinition = s_pasLangDefinition;
         else if (_LanguageInheritsFrom('for', langID)) langDefinition = s_forLangDefinition;
         else if (_LanguageInheritsFrom('cob', langID)) langDefinition = s_cobLangDefinition;
         else if (_LanguageInheritsFrom('vhd', langID)) langDefinition = s_vhdLangDefinition;
         else if (_LanguageInheritsFrom('ruby', langID)) langDefinition = s_rubyLangDefinition;
         else langDefinition = s_defaultLangDefinition;
      }
   }

   /**
    * Retrieves a specific option stored in the def-options-<langID> value.  These 
    * options are enumerated in the LanguageOptionItems enum. 
    * 
    * @param langID              language of interest
    * @param item                option we want (one of LanguageOptionItems enum)
    * @param defaultValue        the default value of this option if one is not 
    *                            stored for this language
    * 
    * @return                    option value
    */
   private static typeless getLanguageOptionItem(_str langID, int item, typeless defaultValue)
   {
      typeless options[];
      typeless temps[];
      int parseMap[];
      getLanguageOptionsParseMap(langID, parseMap);

      typeless value = null;
      if (getLanguageOptions(langID, parseMap, options, temps) > 0) {
         value = options[item];
      }
   
      maybeUseLanguageOptionItemDefault(langID, item, value, defaultValue);

      return value;
   }

   /**
    * Retrieves the values stored in def-options-<langID> by parsing them out of 
    * that string and placing them into an array which is indexed by the 
    * LanguageOptionItems enum. 
    * 
    * @param langID           language of interest   
    * @param parseMap         parse map for this language
    * @param options          array to be filled with options
    * @param temps            temporary placeholders found within the info string
    * 
    * @return                 index of def-options-<langID>
    */
   private static int getLanguageOptions(_str langID, int (&parseMap)[], typeless (&options)[], typeless (&temps)[])
   {
      optionsIndex := find_index('def-options-'langID, MISC_TYPE);
      info := '';
      info = name_info(optionsIndex);

      index := 0;
      typeless item;
      while (info != '') {

         if (parseMap._length() <= index) {
            // this should pick up anything left in the info, we will save it
            temps[temps._length()] = info;
            info = '';
         } else {
            // parse out the next item
            parse info with item info;
   
            // see what it is and what to do with it
            switch (parseMap[index]) {
            case SPACE_HOLDER:
               temps[temps._length()] = item;
               break;
            case BRACE_STYLE:
               getBeginEndStyleItems(item, options);
               break;
            default:
               options[parseMap[index]] = item;
               break;
            }
            index++;
         }
      }
            
      // Allow beautifier to optionally sync its settings into the array.
      hook := find_index('_'langID'_language_options_sync', PROC_TYPE);
      if (hook) {
         call_index(options, hook);
      }

      return optionsIndex;
   }

   /**
    * Set the given language option item for this language.
    * 
    * @param langID           language of interest
    * @param item             option we want to set (one of the LanguageOptionItems 
    *                         enum)
    * @param value            new value of option 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    */
   private static void setLanguageOptionItem(_str langID, int item, typeless value, boolean createNew = false)
   {
      if (!isOptionInParseMap(langID, item)) return;

      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      typeless options[];
      typeless temps[];
      int parseMap[];
      getLanguageOptionsParseMap(langID, parseMap);
      optionsIndex := getLanguageOptions(langID, parseMap, options, temps);

      if (optionsIndex <= 0) {
         if (createNew || _IsInstalledLanguage(langID)) {
            // not all of our installed languages come with a def-options value, so add it now
            info := langID == 'fundamental' ? '' : DEFAULT_SYNTAX_INFO;
            insert_name('def-options-'langID, MISC_TYPE, info);

            // now try again
            optionsIndex = getLanguageOptions(langID, parseMap, options, temps);
         } else {
            return;
         }
      }

      // no need to do all this if the value is the same anyway!
      if (options[item] != null && options[item] :== value) return;

      options[item] = value;
      setLanguageOptions(optionsIndex, langID, parseMap, options, temps);
   }

   /**
    * Sets all the language options for the given language.
    * 
    * @param optionsIndex           index in names table for def-options-<langID>
    * @param langID                 language of interest
    * @param parseMap               parse map containing info on how to parse 
    *                               def-language-<langID> for this language
    */
   private static void setLanguageOptions(int optionsIndex, _str langID, int (&parseMap)[], typeless(&options), typeless(&temps))
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      info := '';

      index := 0;
      tempIndex := 0;
      typeless item;
      // we need to rebuild the string to set it up
      while (index < parseMap._length()) {
   
         item = '';
         switch (parseMap[index]) {
         case SPACE_HOLDER:
            if (tempIndex < temps._length()) {
               item = temps[tempIndex];
               tempIndex++;
            }
            break;
         case BRACE_STYLE:
            item = buildBeginEndStyle(options);
            break;
         default:
            item = options[parseMap[index]];
            maybeUseLanguageOptionItemDefault(langID, parseMap[index], item);
            break;
         }

         info :+= ' 'item;
         index++;
      }

      set_name_info(optionsIndex, strip(info));
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }

   /**
    * Determines whether the given flag (from the LanguageOptionItems enum) is 
    * one that is included in the brace style when it is saved. 
    *  
    * @param item       the item to check
    * 
    * @return           true if it's a brace style item, false otherwise
    */
   private static boolean isBeginEndStyleItem(int item)
   {
      return (item >= BEGIN_END_STYLE_FIRST && item <= BEGIN_END_STYLE_LAST);
   }

   /**
    * Compiles the begin/end style items by ORing them all together into one value. 
    * This only applies to items which return true for isBraceStyleItem(). 
    *  
    * @param options    the array of begin/end style options 
    *  
    * @return           the new begin/end style item 
    */
   private static int buildBeginEndStyle(typeless (&options)[])
   {
      braceStyle := 0;
      int i;
      for (i = BEGIN_END_STYLE_FIRST; i <= BEGIN_END_STYLE_LAST; i++) {
         if (isinteger(options[i])) braceStyle |= options[i];
      }

      return braceStyle;
   }

   /**
    * Retrieves the language option items that are ORed into the brace style 
    * when stored.  Saves them in an options array by their corresponding index 
    * (based on the LanguageOptionItems enum). 
    * 
    * @param braceStyle    the brace style value retrieved for the language 
    * @param options       the options array to store the values
    */
   private static void getBeginEndStyleItems(int braceStyle, typeless (&options)[])
   {
      if (!isinteger(braceStyle)) {
         // set them all equal to '' so that their individual default values will kick in
         options[LOI_BEGIN_END_STYLE] = options[LOI_PAD_PARENS] = options[LOI_NO_SPACE_BEFORE_PAREN] = 
            options[LOI_POINTER_STYLE] = options[LOI_FUNCTION_BEGIN_ON_NEW_LINE] = 
            options[LOI_INSERT_BEGIN_END_IMMEDIATELY] = options[LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END] = 
            options[LOI_QUICK_BRACE] = options[LOI_CUDDLE_ELSE] = '';
      } else {
   
         // begin/end style
         options[LOI_BEGIN_END_STYLE] = (braceStyle & (BES_BEGIN_END_STYLE_1 | BES_BEGIN_END_STYLE_2 | BES_BEGIN_END_STYLE_3));
   
         // pad parens
         options[LOI_PAD_PARENS] = (braceStyle & BES_PAD_PARENS);
   
         // space before paren
         options[LOI_NO_SPACE_BEFORE_PAREN] = (braceStyle & BES_NO_SPACE_BEFORE_PAREN);
   
         // pointer style
         options[LOI_POINTER_STYLE] = (braceStyle & (BES_SPACE_AFTER_POINTER | BES_SPACE_SURROUNDS_POINTER));
   
         // function brace on new line
         options[LOI_FUNCTION_BEGIN_ON_NEW_LINE] = (braceStyle & BES_FUNCTION_BEGIN_ON_NEW_LINE);
   
         // insert braces immediately
         options[LOI_INSERT_BEGIN_END_IMMEDIATELY] = (braceStyle & BES_INSERT_BEGIN_END_IMMEDIATELY);
   
         // insert blank line between braces
         options[LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END] = (braceStyle & BES_INSERT_BLANK_LINE_BETWEEN_BEGIN_END);
   
         // quick brace
         options[LOI_QUICK_BRACE] = (braceStyle & BES_NO_QUICK_BRACE_UNBRACE);
   
         // cuddle else
         options[LOI_CUDDLE_ELSE] = (braceStyle & BES_ELSE_ON_LINE_AFTER_BRACE);

         // delphi expansions - only used by pascal
         options[LOI_DELPHI_EXPANSIONS] = (braceStyle & BES_DELPHI_EXPANSIONS);
      }
   }

   /**
    * Retrieves the mode name for the given language. 
    *  
    * @param langID           language ID (see {@link p_LangId}) 
    * 
    * @return                 mode name for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getModeName(_str langID)
   {
      return getLangDefinitionItem(langID, LDI_MODE_NAME, '');
   }

   /**
    * Retrieves the tabs for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 tabs for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getTabs(_str langID, _str defaultValue = null)
   {
      tabs := getLangDefinitionItem(langID, LDI_TABS, defaultValue);

      return tabs;
   }

   /**
    * Retrieves the margins for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 margins for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getMargins(_str langID, _str defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_MARGINS, defaultValue);
   }

   /**
    * Retrieves the key table name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 key table name for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getKeyTableName(_str langID)
   {
      return getLangDefinitionItem(langID, LDI_KEY_TABLE, '');
   }

   /**
    * Retrieves the word wrap style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 word wrap style for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getWordWrapStyle(_str langID, int defaultValue = STRIP_SPACES_WWS | WORD_WRAP_WWS)
   {
      return getLangDefinitionItem(langID, LDI_WORD_WRAP, defaultValue);
   }

   /**
    * Retrieves the indent with tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 indent with tabs setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getIndentWithTabs(_str langID, boolean defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_INDENT_WITH_TABS, defaultValue);
   }

   /**
    * Retrieves the show tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 show tabs setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getShowTabs(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_SHOW_TABS, defaultValue);
   }

   /**
    * Retrieves the indent style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 indent style for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getIndentStyle(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_INDENT_STYLE, defaultValue);
   }

   /**
    * Retrieves the word characters for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * 
    * @return                 word characters for language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getWordChars(_str langID)
   {
      // in SE 2010, we moved word chars from def-language-<langID> to 
      // def-word-chars-<langID>, so that we could use commas
      wordChars := getLanguageDefVar(langID, WORD_CHARS_OPTIONS_DEF_VAR_KEY, '');
                          
      // see if maybe we just haven't retrieved the value out of the old way yet
      if (wordChars == '') {
         wordChars = getLangDefinitionItem(langID, LDI_WORD_CHARS, null);
         if (wordChars != null && wordChars != WORD_CHARS_NOT_APPLICABLE) {
            setWordChars(langID, wordChars);
            setLangDefinitionItem(langID, LDI_WORD_CHARS, WORD_CHARS_NOT_APPLICABLE);
         } else {
            // we have already retrieved it, so just get the default, i guess
            wordChars = getLanguageDefVar(langID, WORD_CHARS_OPTIONS_DEF_VAR_KEY, null);
         }
      } 

      return wordChars;
   }

   /**
    * Retrieves the lexer name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 lexer name for language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getLexerName(_str langID)
   {
      return getLangDefinitionItem(langID, LDI_LEXER_NAME, null);
   }

   /**
    * Retrieves the color flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    *  
    * @return                 color flags for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getColorFlags(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_COLOR_FLAGS, defaultValue);
   }

   /**
    * Retrieves the line numbers length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 line numbers length for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getLineNumbersLength(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_LINE_NUMBERS_LENGTH, defaultValue);
   }

   /**
    * Retrieves the truncate length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 truncate length for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getTruncateLength(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_TRUNCATE_LENGTH, defaultValue);
   }

   /**
    * Retrieves the bounds for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 bounds for language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getBounds(_str langID, _str defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_BOUNDS, defaultValue);
   }

   /**
    * Retrieves the caps for the given language.  The possible values are as 
    * follows: 
    * <ul> 
    * <li>CM_CAPS_OFF - does not change the caps </li>
    * <li>CM_CAPS_ON - converts keywords to upper case </li>
    * <li>CM_CAPS_AUTO - uses _GetCaps to determine if there are any lowerase 
    * letters in the file.  If so, turns caps off.  If not, caps is turned on. 
    * </li> 
    * </ul>
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 caps for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getCaps(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_CAPS, defaultValue);
   }

   /**
    * Retrieves the soft wrap setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 soft wrap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getSoftWrap(_str langID, boolean defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_SOFT_WRAP, defaultValue);
   }

   /**
    * Retrieves the soft wrap on word setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 soft wrap on word setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getSoftWrapOnWord(_str langID, boolean defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_SOFT_WRAP_ON_WORD, defaultValue);
   }

   /**
    * Retrieves the hex mode for the given language.  Possible values: 
    *  
    * <ul> 
    * <li>HM_HEX_OFF - hex mode off </li>
    * <li>HM_HEX_ON - hex mode on </li>
    * <li>HM_HEX_LINE - hex mode on using line hex
    * </li> 
    * </ul>
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 hex mode for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getHexMode(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_HEX_MODE, defaultValue);
   }

   /**
    * Retrieves the line numbers flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 line numbers flags for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getLineNumbersFlags(_str langID, int defaultValue = null)
   {
      return getLangDefinitionItem(langID, LDI_LINE_NUMBERS_FLAGS, defaultValue);
   }

   /**
    * Retrieves the syntax expansion setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 syntax expansion setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getSyntaxExpansion(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_SYNTAX_EXPANSION, defaultValue);
   }

   /**
    * Retrieves the syntax indent for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 syntax indent for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSyntaxIndent(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_SYNTAX_INDENT, defaultValue);
   }

   /**
    * Retrieves the minimum abbreviation setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 minimum abbreviation setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getMinimumAbbreviation(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_MIN_ABBREVIATION, defaultValue);
   }

   /**
    * Retrieves the indent case from switch setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    *  
    * @return                 indent case from switch setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getIndentCaseFromSwitch(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_INDENT_CASE_FROM_SWITCH, defaultValue);
   }

   /**
    * Retrieves the begin/end comments setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 begin/end comments setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getBeginEndComments(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_BEGIN_END_COMMENTS, defaultValue);
   }

   /**
    * Retrieves the keyword case for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 keyword case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getKeywordCase(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_KEYWORD_CASE, defaultValue);
   }

   /**
    * Retrieves the indent first level setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 indent first level setting setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getIndentFirstLevel(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_INDENT_FIRST_LEVEL, defaultValue);
   }

   /**
    * Retrieves the multiline IF expansion setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 multiline IF expansion setting setting for 
    *                         language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getMultilineIfExpansion(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_MULTILINE_IF_EXPANSION, defaultValue);
   }

   /**
    * Retrieves the MAIN style setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 MAIN style setting setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static int getMainStyle(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_MAIN_STYLE, defaultValue);
   }

   /**
    * Retrieves the continuation indent on function parameters setting for the 
    * given language. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 continuation indent on function parameters 
    *                         setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getUseContinuationIndentOnFunctionParameters(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS, defaultValue);
   }

   /**
    * Retrieves the begin/end style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 begin/end style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getBeginEndStyle(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_BEGIN_END_STYLE, defaultValue);
   }

   /**
    * Retrieves the pad parentheses setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 pad parentheses setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getPadParens(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_PAD_PARENS, defaultValue);
   }

   /**
    * Retrieves the no space before parenthesis setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 no space before parenthesis setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getNoSpaceBeforeParen(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_NO_SPACE_BEFORE_PAREN, defaultValue);
   }

   /**
    * Retrieves the pointer style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 pointer style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getPointerStyle(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_POINTER_STYLE, defaultValue);
   }

   /**
    * Retrieves the function brace on new line setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 function brace on new line setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getFunctionBeginOnNewLine(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_FUNCTION_BEGIN_ON_NEW_LINE, defaultValue);
   }

   /**
    * Retrieves the insert braces immediately setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 insert braces immediately setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getInsertBeginEndImmediately(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_INSERT_BEGIN_END_IMMEDIATELY, defaultValue);
   }

   /**
    * Retrieves the insert blank line between braces setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 insert blank line between braces setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getInsertBlankLineBetweenBeginEnd(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END, defaultValue);
   }

   /**
    * Retrieves the quick brace setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 quick brace setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getQuickBrace(_str langID, boolean defaultValue = null)
   {
      return !getLanguageOptionItem(langID, LOI_QUICK_BRACE, defaultValue);
   }

   /**
    * Retrieves the cuddle else setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 cuddle else setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getCuddleElse(_str langID, boolean defaultValue = null)
   {
      return !getLanguageOptionItem(langID, LOI_CUDDLE_ELSE, defaultValue);
   }

   /**
    * Retrieves the tag case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 tag case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getTagCase(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_TAG_CASE, defaultValue);
   }

   /**
    * Retrieves the attribute case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 attribute case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAttributeCase(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_ATTRIBUTE_CASE, defaultValue);
   }

   /**
    * Retrieves the single word value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 single word value case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getValueCase(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_WORD_VALUE_CASE, defaultValue);
   }

   /**
    * Retrieves the hex value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 hex value case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getHexValueCase(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_HEX_VALUE_CASE, defaultValue);
   }

   /**
    * Retrieves the lowercase filenames when inserting links setting for the 
    * given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 lowercase filenames when inserting links setting 
    *                         for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getLowercaseFilenamesWhenInsertingLinks(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, defaultValue);
   }

   /**
    * Retrieves the quotes for numeric values setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 quotes for numeric values setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getQuotesForNumericValues(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_QUOTES_FOR_NUMERIC_VALUES, defaultValue);
   }

   /**
    * Retrieves the quotes for single word values setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 quotes for single word values setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getQuotesForSingleWordValues(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_QUOTES_FOR_SINGLE_WORD_VALUES, defaultValue);
   }

   /**
    * Retrieves the use color names setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 use color names setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getUseColorNames(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_USE_COLOR_NAMES, defaultValue);
   }

   /**
    * Retrieves the use div tags for alignment setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 use div tags for alignment setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getUseDivTagsForAlignment(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_USE_DIV_TAGS_FOR_ALIGNMENT, defaultValue);
   }

   /**
    * Retrieves the use paths for file entries setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 use paths for file entries setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getUsePathsForFileEntries(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_USE_PATHS_FOR_FILE_ENTRIES, defaultValue);
   }

   /**
    * Retrieves the auto validate on open setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto validate on open setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getAutoValidateOnOpen(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_AUTO_VALIDATE_ON_OPEN, defaultValue);
   }

   /**
    * Retrieves the auto correlate start/end tags setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto correlate start/end tags setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getAutoCorrelateStartEndTags(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_AUTO_CORRELATE_START_END_TAGS, defaultValue);
   }

   /**
    * Retrieves the auto symbol translation setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto symbol translation setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getAutoSymbolTranslation(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_AUTO_SYMBOL_TRANSLATION, defaultValue);
   }

   /**
    * Retrieves the insert right angle bracket setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 insert right angle bracket setting for language 
    *  
    * @categories LanguageSettings_API 
    * @deprecated 
    */
   public static boolean getInsertRightAngleBracket(_str langID, boolean defaultValue = null)
   {
      return false;
   }

   /**
    * Retrieves the auto-insert label setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto-insert label setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getAutoInsertLabel(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_AUTO_INSERT_LABEL, defaultValue);
   }

   /**
    * Retrieves the ruby style setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 ruby style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getRubyStyle(_str langID, int defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_RUBY_STYLE, defaultValue);
   }

   /**
    * Retrieves the delphi expansions setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 delphi expansions setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getDelphiExpansions(_str langID, boolean defaultValue = null)
   {
      return getLanguageOptionItem(langID, LOI_DELPHI_EXPANSIONS, defaultValue);
   }
   
   /**
    * Set the mode name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new mode name for language
    * @param createNewLang    whether to create language if it does 
    *                         not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setModeName(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_MODE_NAME, value, createNewLang);
   }

   /**
    * Set the tabs for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new tabs for language 
    * @param createNewLang    whether to create language if it does 
    *                         not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTabs(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_TABS, value, createNewLang);
   }

   /**
    * Set the margins for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new margins for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMargins(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_MARGINS, value, createNewLang);
   }

   /**
    * Set the key table name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new key table name for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setKeyTableName(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_KEY_TABLE, value, createNewLang);
   }

   /**
    * Set the word wrap style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new word wrap style for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setWordWrapStyle(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_WORD_WRAP, value, createNewLang);
   }

   /**
    * Set the indent with tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent with tabs setting for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentWithTabs(_str langID, boolean value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_INDENT_WITH_TABS, value, createNewLang);
   }

   /**
    * Set the show tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new show tabs setting for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setShowTabs(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_SHOW_TABS, value, createNewLang);
   }

   /**
    * Set the indent style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent style for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentStyle(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_INDENT_STYLE, value, createNewLang);
   }

   /**
    * Set the word characters for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new word characters for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setWordChars(_str langID, _str value, boolean createNewLang = false)
   {
      setLanguageDefVar(langID, WORD_CHARS_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Set the lexer name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new lexer name for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLexerName(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_LEXER_NAME, value, createNewLang);
      
      // set color flags accordingly
      colorFlags := getColorFlags(langID);
      
      if (value != '') colorFlags |= LANGUAGE_COLOR_FLAG;
      else colorFlags &=~ LANGUAGE_COLOR_FLAG;
            
      setColorFlags(langID, colorFlags);
   }

   /**
    * Set the color flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new color flags for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setColorFlags(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_COLOR_FLAGS, value, createNewLang);
   }

   /**
    * Set the line numbers length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new line numbers length for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLineNumbersLength(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_LINE_NUMBERS_LENGTH, value, createNewLang);
   }

   /**
    * Set the truncate length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new truncate length for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTruncateLength(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_TRUNCATE_LENGTH, value, createNewLang);
   }

   /**
    * Set the bounds for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new bounds for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBounds(_str langID, _str value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_BOUNDS, value, createNewLang);
   }

   /**
    * Set the caps for the given language. The possible values are as 
    * follows: 
    * <ul> 
    * <li>CM_CAPS_OFF - does not change the caps </li>
    * <li>CM_CAPS_ON - converts keywords to upper case </li>
    * <li>CM_CAPS_AUTO - uses _GetCaps to determine if there are any lowerase 
    * letters in the file.  If so, turns caps off.  If not, caps is turned on. 
    * </li> 
    * </ul>
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new caps for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCaps(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_CAPS, value, createNewLang);
   }

   /**
    * Set the soft wrap setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap setting for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSoftWrap(_str langID, boolean value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_SOFT_WRAP, value, createNewLang);
   }

   /**
    * Set the soft wrap on word setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap on word setting for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSoftWrapOnWord(_str langID, boolean value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_SOFT_WRAP_ON_WORD, value, createNewLang);
   }

   /**
    * Set the hex mode for the given language.  Possible values: 
    *  
    * <ul> 
    * <li>HM_HEX_OFF - hex mode off </li>
    * <li>HM_HEX_ON - hex mode on </li>
    * <li>HM_HEX_LINE - hex mode on using line hex
    * </li> 
    * </ul>
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new hex mode for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexMode(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_HEX_MODE, value, createNewLang);
   }

   /**
    * Set the line numbers flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new line numbers flags for language
    * @param createNewLang    whether to create the language if it 
    *                         does not already exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLineNumbersFlags(_str langID, int value, boolean createNewLang = false)
   {
      setLangDefinitionItem(langID, LDI_LINE_NUMBERS_FLAGS, value, createNewLang);
   }

   /**
    * Sets the syntax expansion setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new syntax expansion setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSyntaxExpansion(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_SYNTAX_EXPANSION, value, createNew);
   }

   /**
    * Sets the syntax indent for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new syntax indent for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSyntaxIndent(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_SYNTAX_INDENT, value, createNew);
   }

   /**
    * Sets the minimum abbreviation setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new minimum abbreviation setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMinimumAbbreviation(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_MIN_ABBREVIATION, value, createNew);
   }

   /**
    * Sets the indent case from switch setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent case from switch setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentCaseFromSwitch(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_INDENT_CASE_FROM_SWITCH, value, createNew);
   }

   /**
    * Sets the begin/end comments setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new begin/end comments setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeginEndComments(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_BEGIN_END_COMMENTS, value, createNew);
   }

   /**
    * Sets the keyword case for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new keyword case setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setKeywordCase(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_KEYWORD_CASE, value, createNew);
   }

   /**
    * Sets the indent first level setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent first level setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentFirstLevel(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_INDENT_FIRST_LEVEL, value, createNew);
   }

   /**
    * Sets the multiline IF expansion setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new multiline IF expansion setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMultilineIfExpansion(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_MULTILINE_IF_EXPANSION, value, createNew);
   }

   /**
    * Sets the MAIN style setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new MAIN style setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMainStyle(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_MAIN_STYLE, value, createNew);
   }

   /**
    * Sets the continuation indent on function parameters setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new continuation indent on function parameters setting 
    *                         for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseContinuationIndentOnFunctionParameters(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS, value, createNew);
   }

   /**
    * Sets the begin/end style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new begin/end style setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeginEndStyle(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_BEGIN_END_STYLE, value, createNew);
   }
   /**
    * Sets the pad parentheses setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new pad parentheses setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setPadParens(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_PAD_PARENS, 
                            value ? VS_C_OPTIONS_INSERT_PADDING_BETWEEN_PARENS : 0, createNew);
   }
   /**
    * Sets the no space before parenthesis setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new no space before parenthesis setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setNoSpaceBeforeParen(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_NO_SPACE_BEFORE_PAREN, 
                            value ? VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN : 0, createNew);
   }
   /**
    * Sets the pointer style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new pointer style setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setPointerStyle(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_POINTER_STYLE, value, createNew);
   }

   /**
    * Sets the function brace on new line setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new function brace on new line setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setFunctionBeginOnNewLine(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_FUNCTION_BEGIN_ON_NEW_LINE, 
                            value ? BES_FUNCTION_BEGIN_ON_NEW_LINE : 0, createNew);
   }

   /**
    * Sets the insert braces immediately setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert braces immediately setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setInsertBeginEndImmediately(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_INSERT_BEGIN_END_IMMEDIATELY, 
                            value ? BES_INSERT_BEGIN_END_IMMEDIATELY : 0, createNew);
   }

   /**
    * Sets the insert blank line between braces setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert blank line between braces setting for 
    *                         language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setInsertBlankLineBetweenBeginEnd(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END, 
                            value ? BES_INSERT_BLANK_LINE_BETWEEN_BEGIN_END : 0, createNew);
   }

   /**
    * Sets the quick brace setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quick brace setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuickBrace(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_QUICK_BRACE, 
                            value ? 0 : BES_NO_QUICK_BRACE_UNBRACE, createNew);
   }

   /**
    * Sets the cuddle else setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new cuddle else setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCuddleElse(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_CUDDLE_ELSE, 
                            value ? 0 : BES_ELSE_ON_LINE_AFTER_BRACE, createNew);
   }

   /**
    * Sets the tag case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new tag case setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTagCase(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_TAG_CASE, value, createNew);
   }

   /**
    * Sets the attribute case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new attribute case setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAttributeCase(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_ATTRIBUTE_CASE, value, createNew);
   }

   /**
    * Sets the single word value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new single word value case setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setValueCase(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_WORD_VALUE_CASE, value, createNew);
   }

   /**
    * Sets the hex value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new hex value case setting for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexValueCase(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_HEX_VALUE_CASE, value, createNew);
   }

   /**
    * Sets the lowercase filename when inserting links setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new lowercase filename when inserting links setting 
    *                         for language
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLowercaseFilenamesWhenInsertingLinks(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, value, createNew);
   }

   /**
    * Sets the quotes for numeric values setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quotes for numeric values setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuotesForNumericValues(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_QUOTES_FOR_NUMERIC_VALUES, value, createNew);
   }

   /**
    * Sets the quotes for single word values setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quotes for single word values setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuotesForSingleWordValues(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_QUOTES_FOR_SINGLE_WORD_VALUES, value, createNew);
   }

   /**
    * Sets the use color names setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use color names setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseColorNames(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_USE_COLOR_NAMES, value, createNew);
   }

   /**
    * Sets the use div tags for alignment setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use div tags for alignment setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseDivTagsForAlignment(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_USE_DIV_TAGS_FOR_ALIGNMENT, value, createNew);
   }

   /**
    * Sets the use paths for file entries setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use paths for file entries setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUsePathsForFileEntries(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_USE_PATHS_FOR_FILE_ENTRIES, value, createNew);
   }

   /**
    * Sets the auto validate on open setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto validate on open setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoValidateOnOpen(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_AUTO_VALIDATE_ON_OPEN, value, createNew);
   }

   /**
    * Sets the auto correlate start/end tags setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto correlate start/end tags setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCorrelateStartEndTags(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_AUTO_CORRELATE_START_END_TAGS, value, createNew);
   }

   /**
    * Sets the auto symbol translation setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto symbol translation setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoSymbolTranslation(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_AUTO_SYMBOL_TRANSLATION, value, createNew);
   }

   /**
    * Sets the insert right angle bracket setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert right angle bracket setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    * @deprecated 
    */
   public static void setInsertRightAngleBracket(_str langID, boolean value, boolean createNew = false)
   {
   }

   /**
    * Sets the auto-insert label setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto-insert label setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoInsertLabel(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_AUTO_INSERT_LABEL, value, createNew);
   }

   /**
    * Sets the ruby style setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new ruby style setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setRubyStyle(_str langID, int value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_RUBY_STYLE, value, createNew);
   }

   /**
    * Sets the delphi expansion setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new delphi expansion setting for language 
    * @param createNew        whether to create a new entry for 
    *                         this language if it does not exist
    *  
    * @categories LanguageSettings_API 
    */
   public static void setDelphiExpansions(_str langID, boolean value, boolean createNew = false)
   {
      setLanguageOptionItem(langID, LOI_DELPHI_EXPANSIONS,
         value ? BES_DELPHI_EXPANSIONS : 0, createNew);
      
   }
   
   #region Language-Specific Def-Vars

   /**
    * Retrieves the default value for the given def-var.  If the def-var is not in 
    * the names table for a language, then this value is used.  Likewise, when 
    * setting a language-specific def-var to this value, we'll often just delete 
    * the name instead. 
    * 
    * @param defVarKey           def-var key
    * 
    * @return                    default value of def-var
    */
   private static typeless getDefaultDefVarValue(_str defVarKey, _str langID)
   {
      typeless defaultValue;

      switch (defVarKey) {
      case ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY:
         defaultValue = def_adaptive_formatting_flags;
         break;
      case ALIAS_FILENAME_DEF_VAR_KEY:
      case BEGIN_END_PAIRS_DEF_VAR_KEY:
      case INHERIT_DEF_VAR_KEY:
      case LOAD_FILE_OPTIONS_DEF_VAR_KEY:
      case MENU_OPTIONS_DEF_VAR_KEY:
      case SAVE_FILE_OPTIONS_DEF_VAR_KEY:
      case TAG_FILE_LIST_DEF_VAR_KEY:
      default:
         defaultValue = '';
         break;
      case ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY:
      case SMART_PASTE_DEF_VAR_KEY:
         defaultValue = true;
         break;
      case AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY:
         defaultValue = def_auto_complete_minimum_length;
         break;
      case AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY:
         defaultValue = def_auto_complete_options;
         break;
      case CODEHELP_FLAGS_DEF_VAR_KEY:
         extra_codehelp_flag := VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE;
         if (_FindLanguageCallbackIndex("_%s_analyze_return_type", langID) &&
             _FindLanguageCallbackIndex("_%s_get_expression_pos", langID)) {
            extra_codehelp_flag = VSCODEHELPFLAG_AUTO_LIST_VALUES;
         }
         defaultValue = def_codehelp_flags | extra_codehelp_flag;
         break;
      case COMMENT_EDITING_FLAGS_DEF_VAR_KEY:
         defaultValue = VS_COMMENT_EDITING_FLAG_DEFAULT;
         if (!def_auto_javadoc_comment) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_COMMENT;
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT;
         }
         if (!def_auto_javadoc) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK;
         }
         if (!def_auto_xmldoc_comment) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT;
         }
         if (!def_extend_linecomment) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS;
         }
         if (!def_auto_linecomment) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS;
         }
         if (!def_join_comments) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS;
         }
         if (!def_auto_string) {
            defaultValue &= ~VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS;
         }
         break;
      case COMMENT_WRAP_OPTIONS_DEF_VAR_KEY:
         defaultValue = CW_commentWrapDefaultsStr;
         break;
      case DOC_COMMENT_FLAGS_DEF_VAR_KEY:
         defaultValue = def_default_doc_comment_flags;
         break;
      case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
         defaultValue = AC_POUND_INCLUDE_NONE;
         break;
      case INDENT_OPTIONS_DEF_VAR_KEY:
         defaultValue = VS_INDENT_FLAG_DEFAULT;
         if (_LanguageInheritsFrom('py', langID)) {
            defaultValue |= VS_INDENT_FLAG_BACKSPACE_UNINDENT;
         }
         break;
      case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
         if (_LanguageInheritsFrom('plsql', langID) || _LanguageInheritsFrom('pl1', langID)) {
            defaultValue = 1;
         } else {
            defaultValue = 0;
         }
         break;
      case NUMBERING_STYLE_DEF_VAR_KEY:
         defaultValue = 0;
         break;
      case REAL_INDENT_DEF_VAR_KEY:
         defaultValue = (def_enter_indent != 0);
         break;
      case SMART_TAB_DEF_VAR_KEY:
         defaultValue = def_smarttab;
         break;
      case SURROUND_OPTIONS_DEF_VAR_KEY:
         defaultValue = def_surround_mode_options;
         break;
      case SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY:
         defaultValue = SYMBOL_COLOR_BOLD_DEFINITIONS |
                        SYMBOL_COLOR_SHOW_NO_ERRORS   |
                        SYMBOL_COLOR_DISABLED;
         break;
      case USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY:
         defaultValue = def_adaptive_formatting_on;
         break;
      case WORD_CHARS_OPTIONS_DEF_VAR_KEY:
         if (_LanguageInheritsFrom('xml', langID)) {
            defaultValue = '\p{isXMLNameChar}?!';
         } else {
            defaultValue = 'A-Za-z0-9_$';
         }
         break;
      case XML_WRAP_OPTIONS_DEF_VAR_KEY:
         if (langID == 'docbook') {
            defaultValue = XW_xmlWrapDefaultsStrDocbook;
         } else {
            defaultValue = XW_xmlWrapDefaultsStr;
         }
         break;
      case AUTOBRACKET_VAR_KEY:
         {
            switch (langID) {
            case 'fundamental':
            case 'binary':
            case 'process':
               defaultValue = AUTO_BRACKET_DEFAULT_OFF;
               break;
            case 'vbs':
               // disable single quote for vbscript
               defaultValue = AUTO_BRACKET_DEFAULT_OFF & ~AUTO_BRACKET_SINGLE_QUOTE;
               break;
            case 'c':
            case 'ansic':
               defaultValue = AUTO_BRACKET_DEFAULT_C_STYLE;
               break;
            case 'html':
            case 'cfml':
            case 'xml':
               defaultValue = AUTO_BRACKET_DEFAULT_HTML_STYLE;
               break;
            case 'd':
            case 'lua':
            case 'phpscript':
            case 'pl':
            case 'as':
            case 'awk':
            case 'ch':
            case 'cs':
            case 'e':
            case 'java':
            case 'js':
            case 'jsl':
            case 'm':
            case 'py':
            case 'powershell':
               defaultValue = AUTO_BRACKET_DEFAULT_ON;
               break;
            default:
               defaultValue = AUTO_BRACKET_DEFAULT;
               break;
            }
         }
         break;
      case UPDATE_VERSION_DEF_VAR_KEY:
         defaultValue = '0';
         break;
      case CODE_MARGINS_DEF_VAR_KEY:
         if (_LanguageInheritsFrom('pl1', langID)) {
            defaultValue = '2 72';
         } else {
            defaultValue = '';
         }
      case SURROUND_WITH_VERSION_DEF_VAR_KEY:
         // see if we can find the old def-var that we used before this was lang-specific
         index := find_index('def-surround-version', MISC_TYPE);
         if (!index) {
            // it was never created, so just use 0
            defaultValue = 0;
         } else {
            // has been updated at least once before, find out what version
            value := name_info(index);
            if (isnumber(value)) {
               defaultValue = (int)value;
            } else {
               // no idea what happened here
               defaultValue = 0;
            }
         }
         break;
      }

      return defaultValue;
   }

   /**
    * Retrieves the name of the id-specific def-var for the given 
    * id and def-var key. 
    * 
    * @param id                  language ID (see {@link 
    *                            p_LangId})
    * @param defVarKey           def-var key
    * 
    * @return                    name of def-var in names table
    */
   private static _str getDefVarName(_str id, _str defVarKey)
   {
      switch (defVarKey) {
      case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
      case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
         // why is this one different?  one of life's great mysteries
         return('def-'id'-'defVarKey);
         break;
      default:
         // yup, it really is that simple
         return('def-'defVarKey'-'id);
         break;
      }

   }

   /**
    * Retrieves a language-specific def-var.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param defaultValue        default value to be used in case the def-var is 
    *                            not present.  
    * 
    * @return                    language-specific def-var value
    */
   private static typeless getLanguageDefVar(_str langID, _str defVarKey, _str defaultValue = null)
   {
      defVarName := getDefVarName(langID, defVarKey);
      typeless result = getDefVar(defVarName, defaultValue);
      if (result._isempty()) {
         return getDefaultDefVarValue(defVarKey, langID);
      }
      return result;
   }

   /**
    * Sets the value of a language-specific def-var.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param value               new value 
    */
   private static int setLanguageDefVar(_str langID, _str defVarKey, typeless value)
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      defVarName := getDefVarName(langID, defVarKey);
      defaultValue := getDefaultDefVarValue(defVarKey, langID);

      return setDefVar(defVarName, value, defaultValue);
   }

   /**
    * Gets the list of languages which a symbol defined in the 
    * current language can be referened in. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    begin/end pairs value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getReferencedInLanguageIDs(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, REFERENCED_IN_LANGUAGES_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the list of languages which a symbol defined in the 
    * current language can be referened in. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setReferencedInLanguageIDs(_str langID, _str value)
   {
      setLanguageDefVar(langID, REFERENCED_IN_LANGUAGES_DEF_VAR_KEY, value);
   }

   /**
    * Gets the Begin/End pairs for this language.  This value is available on the 
    * GUI on the General form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    begin/end pairs value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getBeginEndPairs(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, BEGIN_END_PAIRS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the Begin/End pairs for this language.  This value is available on the 
    * GUI on the General form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeginEndPairs(_str langID, _str value)
   {
      setLanguageDefVar(langID, BEGIN_END_PAIRS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the smart tab value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    smart tab value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSmartTab(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, SMART_TAB_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the smart tab value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSmartTab(_str langID, int value)
   {
      setLanguageDefVar(langID, SMART_TAB_DEF_VAR_KEY, value);
   }

   /**
    * Gets the smartpaste value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    smartpaste value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getSmartPaste(_str langID, boolean defaultValue = null)
   {
      return getLanguageDefVar(langID, SMART_PASTE_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the smartpaste value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSmartPaste(_str langID, boolean value)
   {
      setLanguageDefVar(langID, SMART_PASTE_DEF_VAR_KEY, value);
   }

   /**
    * Gets the alias filename value for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    alias filename value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getAliasFilename(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, ALIAS_FILENAME_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the alias filename value for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAliasFilename(_str langID, _str value)
   {
      setLanguageDefVar(langID, ALIAS_FILENAME_DEF_VAR_KEY, value);
   }

   /**
    * Gets the code margin setting for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    code margins string 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getCodeMargins(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, CODE_MARGINS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the code margins for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCodeMargins(_str langID, _str value)
   {
      setLanguageDefVar(langID, CODE_MARGINS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the adaptive formatting flags for this language.  This value is 
    * controlled on the GUI on the Adaptive Formatting form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    adaptive formatting flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAdaptiveFormattingFlags(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the adaptive formatting flags for this language.  This value is 
    * available on the GUI on the Adaptive Formatting form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAdaptiveFormattingFlags(_str langID, int value)
   {
      setLanguageDefVar(langID, ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the adaptive formatting value for this language, which controls whether 
    * adaptive formatting is turned on. This value is controlled on the GUI on the
    * Adaptive Formatting form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    adaptive formatting value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getUseAdaptiveFormatting(_str langID, boolean defaultValue = null)
   {
      return getLanguageDefVar(langID, USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the adaptive formatting value for this language, which controls whether 
    * adaptive formatting is turned on. This value is available on the GUI on the 
    * Adaptive Formatting form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseAdaptiveFormatting(_str langID, boolean value)
   {
      setLanguageDefVar(langID, USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY, value);
   }

   /**
    * Gets the inheritance value for this language, which defines if a language 
    * inherits callbacks from another language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    inheritance value for this language (language 
    *                            whose callbacks this language inherits from)
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getLangInheritsFrom(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, INHERIT_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the inheritance value for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLangInheritsFrom(_str langID, _str value)
   {
      setLanguageDefVar(langID, INHERIT_DEF_VAR_KEY, value);
   }

   /**
    * Gets the numbering style for this language.  This value is available on the 
    * Formattiong options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    numbering style value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getNumberingStyle(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, NUMBERING_STYLE_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the numbering style for this language.  This value is available on the 
    * Formatting options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setNumberingStyle(_str langID, int value)
   {
      setLanguageDefVar(langID, NUMBERING_STYLE_DEF_VAR_KEY, value);
   }

   /**
    * Gets the surround options for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    surround options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSurroundOptions(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, SURROUND_OPTIONS_DEF_VAR_KEY, defaultValue);  
   }

   /**
    * Sets the surround options for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSurroundOptions(_str langID, int value)
   {
      setLanguageDefVar(langID, SURROUND_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the codehelp flags for this language.  The options for this value are 
    * available on the GUI on the Context Tagging form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    codehelp flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getCodehelpFlags(_str langID, int defaultValue = null)
   {
      flags := getLanguageDefVar(langID, CODEHELP_FLAGS_DEF_VAR_KEY, defaultValue);
      if (_jaws_mode()) {
         flags &= ~(VSCODEHELPFLAG_AUTO_FUNCTION_HELP | VSCODEHELPFLAG_AUTO_LIST_MEMBERS | 
                    VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION | VSCODEHELPFLAG_AUTO_LIST_PARAMS | 
                    VSCODEHELPFLAG_AUTO_LIST_VALUES);
      }

      return flags;
   }

   /**
    * Sets the codehelp flags for this language.  The options for this value are 
    * available on the GUI on the Context Tagging form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCodehelpFlags(_str langID, int value)
   {
      setLanguageDefVar(langID, CODEHELP_FLAGS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the autocomplete options for this language, which are a bitset of 
    * AUTO_COMPLETE_. This value controls the options which are available on the
    * AutoComplete form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    autocomplete options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoCompleteOptions(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the autocomplete options for this language.  This value controls the 
    * options which are available on the AutoComplete form for each applicable
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCompleteOptions(_str langID, int value)
   {
      setLanguageDefVar(langID, AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the minimum length required for autocomplete to be triggered for this 
    * language. This value is available on the AutoComplete form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    minimum autocomplete length for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoCompleteMinimumLength(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the minimum length required for autocomplete to be triggered for this 
    * language.  This value is available on the AutoComplete form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCompleteMinimumLength(_str langID, int value)
   {
      setLanguageDefVar(langID, AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY, value);
   }

   /**
    * Gets the symbol coloring options for this language.  This value is controlled
    * by options which are available on the View form for each applicable language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    symbol coloring options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSymbolColoringOptions(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the symbol coloring options for this language.  This value is controlled
    * by options which are available on the View form for each applicable language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSymbolColoringOptions(_str langID, int value)
   {
      setLanguageDefVar(langID, SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the doc comment flags for this language.  This value is controlled by 
    * the options available on the Comments form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    doc comment flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getDocCommentFlags(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, DOC_COMMENT_FLAGS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the doc comment flags for this language.  This value is controlled by 
    * the options available on the Comments form for each applicable language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setDocCommentFlags(_str langID, _str value)
   {
      setLanguageDefVar(langID, DOC_COMMENT_FLAGS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the comment wrap options for this language.  This value is controlled by
    * the options available on the Comments form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    comment wrap options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getCommentWrapOptions(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, COMMENT_WRAP_OPTIONS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the comment wrap options for this language.  This value is controlled by
    * the options available on the Comments form for each applicable language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCommentWrapOptions(_str langID, _str value)
   {
      setLanguageDefVar(langID, COMMENT_WRAP_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Determines whether backspace at the beginning of the line unindents the line
    * for this language. This value is available on the Indent form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    backspace options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getBackspaceUnindents(_str langID, boolean defaultValue = null)
   {
      intDefault := null;
      if (defaultValue != null) {
         if (defaultValue) {
            intDefault = VS_INDENT_FLAG_BACKSPACE_UNINDENT;
         } else intDefault = 0;
      } 

      indentFlags := getLanguageDefVar(langID, INDENT_OPTIONS_DEF_VAR_KEY, intDefault);
      return ((indentFlags & VS_INDENT_FLAG_BACKSPACE_UNINDENT) != 0);
   }

   /**
    * Sets  whether backspace at the beginning of the line unindents the line
    * for this language.  This value is available on the Indent form for
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBackspaceUnindents(_str langID, boolean value)
   {
      indentFlags := getLanguageDefVar(langID, INDENT_OPTIONS_DEF_VAR_KEY, null);
      if (value) {
         indentFlags |= VS_INDENT_FLAG_BACKSPACE_UNINDENT;
      } else {
         indentFlags &= ~VS_INDENT_FLAG_BACKSPACE_UNINDENT;
      }

      setLanguageDefVar(langID, INDENT_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the xml wrap options for this language.  This value is available on 
    * the GUI on the Formatting form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    xml wrap options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getXMLWrapOptions(_str langID, _str defaultValue = null)
   {
      return getLanguageDefVar(langID, XML_WRAP_OPTIONS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the xml wrap flags for this language.  This value is 
    * available on the GUI on the Formatting form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setXMLWrapOptions(_str langID, _str value)
   {
      setLanguageDefVar(langID, XML_WRAP_OPTIONS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the name of the menu used for right-click context menus when there is a
    * selection for this language. This value is available on the General form for
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    menu info for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getMenuIfSelection(_str langID, _str defaultValue = null)
   {
      menuInfo := getLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, '');
      parse menuInfo with . ',' auto selMenu;

      if (selMenu == '') selMenu = '_ext_menu_default_sel';

      return selMenu;
   }

   /**
    * Sets the the name of the menu used for right-click context menus when there is a
    * selection.  This value is available on the General form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMenuIfSelection(_str langID, _str value)
   {
      if (value == '_ext_menu_default_sel') value = '';

      menuInfo := getLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, '');
      parse menuInfo with auto first ',' .;
      menuInfo = first','value;

      setLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, menuInfo);
   }

   /**
    * Gets the name of the menu used for right-click context menus when there is 
    * no selection for this language. This value is available on the General form 
    * for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    menu info for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getMenuIfNoSelection(_str langID, _str defaultValue = null)
   {
      menuInfo := getLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, '');
      parse menuInfo with auto noSelMenu ',' .;

      if (noSelMenu == '') noSelMenu = '_ext_menu_default';
                             
      return noSelMenu;
   }

   /**
    * Sets the the name of the menu used for right-click context menus when there is 
    * no selection.  This value is available on the General form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMenuIfNoSelection(_str langID, _str value)
   {
      if (value == '_ext_menu_default') value = '';

      menuInfo := getLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, '');
      parse menuInfo with . ',' auto rest;
      menuInfo = value','rest;

      setLanguageDefVar(langID, MENU_OPTIONS_DEF_VAR_KEY, menuInfo);
   }

   /**
    * Retrieves a file option.  These options are stored in language-specific 
    * def-vars as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param flag                string to look for to determine whether this 
    *                            option is on or off
    * 
    * @return                    1 for +flag, 0 for -flag, -1 for flag not found
    */
   private static int getFileOption(_str langID, _str defVarKey, _str flag)
   {
      fileOptions := getLanguageDefVar(langID, defVarKey);
      if (fileOptions != '') {
         col := pos('[+-]' :+ flag, fileOptions, 1, 'r');
         if (col > 0) {
            if (substr(fileOptions, col, 1) == '+') {
               return 1;
            }
            return 0;
         }
      }

      return -1;
   }

   /**
    * Sets a file option.  These options are stored in language-specific 
    * def-vars as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param flag                string to which determines whether this option 
    *                            is on or off
    * @param value               how we want to set the flag in the def-var:  1
    *                            for +flag, 0 for -flag, -1 for flag not found
    */
   private static void setFileOption(_str langID, _str defVarKey, _str flag, int value)
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      // if the value is anything besides a 1 or 0, then we just blank out the option
      newOption := '';
      switch (value) {
      case 0:
         // set this to FALSE
         newOption = ' -'flag;
         break;
      case 1:
         // set this to TRUE
         newOption = ' +'flag;
         break;
      }

      // get the existing option and modify it
      fileOptions := getLanguageDefVar(langID, defVarKey);
      if (fileOptions != '') {
         // remove the existing setting for this flag
         fileOptions = stranslate(fileOptions, '', '[ ]*[+-]'flag, 'R');
      } 

      // add in the new option
      fileOptions = strip(fileOptions :+ newOption);

      // finally, set the new option
      setLanguageDefVar(langID, defVarKey, strip(fileOptions));
   }

   /**
    * Retrieves a file option.  These options are stored in language-specific 
    * def-vars as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param flag                string to look for to determine the value of 
    *                            this option
    * @param checkPlusMinus      whether to use the +/- as the
    *                            option value if no suffix is found
    * @param tryGlobal           whether to check the global option
    *                            if not language setting if found
    * 
    * @return                    the string value found after the flag for 
    *                            this option
    */
   private static _str getFileSelectOption(_str langID, _str defVarKey, _str flag, _str defaultValue,
                                           boolean checkPlusMinus = false, boolean tryGlobal = true)
   {
      value := '';

      // figure out what we're searching for
      ss := '[+|-]'flag'(:c):0,1( |$)';

      fileOptions := getLanguageDefVar(langID, defVarKey);
      if (fileOptions != '') {

         // did we find it?
         col := pos(ss, fileOptions, 1, 'R');
         if (col) {
            // then whip it out!
            suffix := substr(fileOptions, col + length(flag) + 1, 1);
            if (suffix != '') {
               value = suffix;
            } else if (checkPlusMinus) {
               value = substr(fileOptions, col, 1);
            }
         } 
      }

      // if we found nothing in the language specific options, then try getting
      // something from the global options
      if (value == '' && tryGlobal) {
         fileOptions = def_save_options;
         col := pos(ss, fileOptions, 1, 'R');
         if (col) {
            suffix := substr(fileOptions, col + length(flag) + 1, 1);
            if (suffix != '') {
               value = suffix;
            } else if (checkPlusMinus) {
               value = substr(fileOptions, col, 1);
            }
         }
      }

      if (value == '') {
         value = defaultValue;
      }

      return value;
   }

   /**
    * Sets a file option.  These options are stored in language-specific 
    * def-vars as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defVarKey           key to the def-var
    * @param flag                string to look for to determine the 
    *                            value of this option
    * @param value               string to insert into these options to 
    *                            specify a value
    */
   private static void setFileSelectOption(_str langID, _str defVarKey, _str flag, _str value, _str defaultValue = '')
   {
      // changed a language option, so clear cache
      clearLanguageOptionsCache();

      // get the existing option and modify it
      fileOptions := getLanguageDefVar(langID, defVarKey);

      // figure out what we're looking for
      ss := '[+|-]'flag'(:c):0,1( |$)';
      col := pos(ss, fileOptions, 1, 'R');

      // did we find it?
      if (col) {
         // yup, we gotta build a new string, so get what's before and after the option
         _str before = '', mid = '', after = '';
         before = substr(fileOptions, 1, col - 1);

         nextSpace := pos(' ', fileOptions, col);
         if (nextSpace) {
            after = substr(fileOptions, nextSpace);   // find the next space
         }

         // for the default, we just remove the thing
         if (value != defaultValue) {
            // maybe the plus or minus is the value
            if (value == '+' || value == '-') {
               mid = value :+ flag;
            } else {
               // or maybe it's another letter
               mid = "+" :+ flag :+ value;
            }
            fileOptions = before :+ mid :+ after;
         } else {
            fileOptions = strip(before)' 'strip(after);
         }
      } else {
         // if it's not in there, that means it's off - to turn it on, just add to the existing string
         // for default choice, we just leave it blank
         if (value != defaultValue) {
            if (value == '+' || value == '-') {
               fileOptions = fileOptions :+ ' ' :+ value :+ flag;
            } else {
               // or maybe it's another letter
               fileOptions = fileOptions :+ " +" :+ flag :+ value;
            }
         }
      }

      // finally, set the new option
      setLanguageDefVar(langID, defVarKey, strip(fileOptions));
   }

   /**
    * Gets whether files in this language are loaded as binary.  This value is 
    * available on the File Options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    whether files are loaded as binary 
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getLoadAsBinary(_str langID)
   {
      return (getFileOption(langID, LOAD_FILE_OPTIONS_DEF_VAR_KEY, 'LB') > 0);
   }

   /**
    * Sets whether files in this language are loaded as binary.  This value is 
    * available on the File Options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLoadAsBinary(_str langID, boolean value)
   {
      setFileOption(langID, LOAD_FILE_OPTIONS_DEF_VAR_KEY, 'LB', (value == false) ? -1 : 1);
   }

   /**
    * Gets whether tabs are expanded to spaces when files in this language are
    * loaded. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    whether tabs are expanded to spaces during 
    *                            file loading
    *  
    * @categories LanguageSettings_API 
    */
   public static int getLoadExpandTabsToSpaces(_str langID)
   {
      return getFileOption(langID, LOAD_FILE_OPTIONS_DEF_VAR_KEY, 'E');
   }

   /**
    * Sets whether tabs are expanded to spaces when files in this language are
    * loaded. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLoadExpandTabsToSpaces(_str langID, int value)
   {
      setFileOption(langID, LOAD_FILE_OPTIONS_DEF_VAR_KEY, 'E', value);
   }

   /**
    * Gets whether files in this language are saved as binary.  This 
    * value is available on the File Options form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    whether files are saved as binary 
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getSaveAsBinary(_str langID)
   {
      return (getFileOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'B') > 0);
   }

   /**
    * Sets whether files in this language are saved as binary.  This 
    * value is available on the File Options form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSaveAsBinary(_str langID, boolean value)
   {
      setFileOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'B', (value == false) ? -1 : 1);
   }

   /**
    * Gets whether tabs are expanded to spaces when files in this language are
    * saved. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    whether tabs are expanded to spaces during 
    *                            file save
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSaveExpandTabsToSpaces(_str langID)
   {
      return getFileOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'E');
   }

   /**
    * Sets whether tabs are expanded to spaces when files in this language are
    * saved. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSaveExpandTabsToSpaces(_str langID, int value)
   {
      setFileOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'E', value);
   }

   /**
    * Gets whether files in this language are have their trailing spaces 
    * stripped when saved. This value is available on the File Options form 
    * for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    whether trailing spaces are stripped on 
    *                            save
    *                            values:<pre>
    *                            STSO_OFF - do not strip spaces
    *                            STSO_STRIP_ALL - strip all trailing spaces
    *                            STSO_STRIP_MODIFIED - strip
    *                            spaces only from modified or
    *                            inserted lines</pre>
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSaveStripTrailingSpaces(_str langID)
   {
      value := 0;
      strValue := getFileSelectOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'S', '', true, false);
      switch (strValue) {
      case '-':
         value = STSO_OFF;
         break;
      case '+':
         value = STSO_STRIP_ALL;
         break;
      case 'M':
         value = STSO_STRIP_MODIFIED;
         break;
      default:
         value = -1;
         break;
      }

      return value;
   }

   /**
    * Sets whether files in this language are have their trailing spaces 
    * stripped when saved. This value is available on the File Options form 
    * for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *                            values:<pre>
    *                            STSO_OFF - do not strip spaces
    *                            STSO_STRIP_ALL - strip all trailing spaces
    *                            STSO_STRIP_MODIFIED - strip
    *                            spaces only from modified or
    *                            inserted lines</pre>
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSaveStripTrailingSpaces(_str langID, int value)
   {
      strValue := '';
      switch (value) {
      case STSO_OFF:
         strValue = '-';
         break;
      case STSO_STRIP_ALL:
         strValue = '+';
         break;
      case STSO_STRIP_MODIFIED:
         strValue = 'M';
         break;
      default:
         strValue = '';
         break;
      }

      setFileSelectOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'S', strValue);
   }

   /**
    * Gets the format used to translate EOL characters when files in this 
    * language are saved. This value is available on the File 
    * Options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return                    how EOL characters are translated when a 
    *                            file is saved
    *                            values:<pre>
    *                            A - Automatic
    *                            D - DOS
    *                            M - Mac
    *                            U - Unix</pre>
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getSaveEOLFormat(_str langID)
   {
      return getFileSelectOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'F', 'A');
   }

   /**
    * Sets the format used to translate EOL characters when files in this 
    * language are saved.  This value is available on the 
    * File Options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSaveEOLFormat(_str langID, _str value)
   {
      setFileSelectOption(langID, SAVE_FILE_OPTIONS_DEF_VAR_KEY, 'F', value, 'A');
   }

   /**
    * Gets whether we insert real indent for this language. This value is 
    * available on the GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    whether we insert real indent for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getInsertRealIndent(_str langID, boolean defaultValue = null)
   {
      return getLanguageDefVar(langID, REAL_INDENT_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets whether we insert real indent for this language. 
    * This value is available on the GUI on the Indent form 
    * for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setInsertRealIndent(_str langID, boolean value)
   {
      setLanguageDefVar(langID, REAL_INDENT_DEF_VAR_KEY, value);
   }

   /**
    * Retrieves whether or not we want to auto-case keywords for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *  
    * @return                    whether to auto-case keywords in this language
    *  
    * @categories LanguageSettings_API 
    */
   public static boolean getAutoCaseKeywords(_str langID, boolean defaultValue = null)
   {
      return getLanguageDefVar(langID, AUTO_CASE_KEYWORDS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets whether or not we want to auto-case keywords for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCaseKeywords(_str langID, boolean value)
   {
      setLanguageDefVar(langID, AUTO_CASE_KEYWORDS_DEF_VAR_KEY, value);
   }

   /**
    * Retrieves the comment editing flags for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *  
    * @return                    comment editing flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getCommentEditingFlags(_str langID, int defaultValue = null)
   {
      return getLanguageDefVar(langID, COMMENT_EDITING_FLAGS_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the comment editing flags for this language. 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCommentEditingFlags(_str langID, int value)
   {
      setLanguageDefVar(langID, COMMENT_EDITING_FLAGS_DEF_VAR_KEY, value);
   }

   /**
    * Gets the list of tag files for this language.  Each path is separated by 
    * PATHSEP.  May need to use _replace_envvars to get the full paths. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * 
    * @return                    list of tag files for this language, separated 
    *                            by PATHSEP
    */
   public static _str getTagFileList(_str langID)
   {
      return getLanguageDefVar(langID, TAG_FILE_LIST_DEF_VAR_KEY);
   }

   /**
    * Sets the list of tag files for this language.  Each path is separated by 
    * PATHSEP.  Before saving the value, environment variable are encoded.
    * 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               list of tag files to set, delimited by PATHSEP
    * @param append              true to append the files to the existing value, 
    *                            false to replace the existing value
    */
   public static void setTagFileList(_str langID, _str value, boolean append = false)
   {
      if (append) {
         tagFiles := getTagFileList(langID);

         // make sure the new path isn't already in there
         if (pos(value, PATHSEP :+ tagFiles :+ PATHSEP)) return;

         if (tagFiles != '') tagFiles :+= PATHSEP;
         value = tagFiles :+ value;
      }

      // make sure we encode this guy
      value = _encode_vsenvvars(value, true, false);

      setLanguageDefVar(langID, TAG_FILE_LIST_DEF_VAR_KEY, value);

      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }

   /**
    * Retrieves a hashtable of tag file lists, keyed by language.  Use this to 
    * go through all the language-specific tag file lists. 
    * 
    * @param table               table to be populated with values
    */
   public static void getTagFileListTable(_str (&table):[])
   {
      defVarName := getDefVarName('', TAG_FILE_LIST_DEF_VAR_KEY);
      index := name_match(defVarName, 1, MISC_TYPE);
      while (index) {
         parse name_name(index) with '-' . '-' auto langId;
         table:[langId] = name_info(index);

         index = name_match(defVarName, 0, MISC_TYPE);
      }
   }

   /**
    * 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *  
    * @return                    
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoBracket(_str langID)
   {
      return(getLanguageDefVar(langID, AUTOBRACKET_VAR_KEY));
   }

   /**
    * Helper function to determine if specific feature is enabled.
    * 
    * @param langID 
    * @param flags 
    * 
    * @return boolean 
    */
   public static boolean getAutoBracketEnabled(_str langID, int flags)
   {
      defAB := LanguageSettings.getAutoBracket(langID);
      return ((defAB & AUTO_BRACKET_ENABLE) && (defAB & flags)); 
   }

   /**
    * 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoBracket(_str langID, int value)
   {
      setLanguageDefVar(langID, AUTOBRACKET_VAR_KEY, value);
   }
   
   /**
    * Retrieves whether language-specific aliases should be automatically 
    * expanded on space for this language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * 
    * @return boolean            whether to expand language-specific aliases on 
    *                            space
    */
   public static boolean getExpandAliasOnSpace(_str langID)
   {
      return getLanguageDefVar(langID, ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY);
   }

   /**
    * Sets whether language-specific aliases should be automatically 
    * expanded on space for this language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               whether to expand language-specific 
    *                            aliases on space
    */
   public static void setExpandAliasOnSpace(_str langID, boolean value)
   {
      setLanguageDefVar(langID, ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY, value);
   }

   /**
    * Gets the update version of this language.  The update version specifies the 
    * last version that we updated the language's default settings.  This is used 
    * when we update default settings for a language and want to know which 
    * languages to update. 
    * 
    * @param langId              language ID (see {@link p_LangId}) 
    *  
    * @returned                  last version this language was updated
    */
   public static _str getUpdateVersion(_str langId)
   {
      return getLanguageDefVar(langId, UPDATE_VERSION_DEF_VAR_KEY);
   }

   /**
    * Sets the update version of this language.  The update version specifies the 
    * last version that we updated the language's default settings.  This is used 
    * when we update default settings for a language and want to know which 
    * languages to update. 
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param value               last version this language was updated 
    */
   public static void setUpdateVersion(_str langId, _str value)
   {
      setLanguageDefVar(langId, UPDATE_VERSION_DEF_VAR_KEY, value);
   }

   /**
    * Gets whether Auto-Complete acts on #include for languages 
    * which have that particularly structure.  To do no 
    * auto-complete, the value is set to AC_POUND_INCLUDE_NONE. To 
    * show a list of quoted filenames after the user types 
    * #include, followed by a space, this value is set to 
    * AC_POUND_INCLUDE_QUOTED_ON_SPACE.  To show a list of 
    * filenames after the user types " or < (after 
    * #include<space>), this value is set to 
    * AC_POUND_INCLUDE_ON_QUOTELT. 
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param defaultValue        value to use if no value is set
    * 
    * @return int 
    */
   public static int getAutoCompletePoundIncludeOption(_str langId, int defaultValue = null)
   {
      return getLanguageDefVar(langId, AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY);
   }

   /**
    * Sets whether Auto-Complete acts on #include for languages 
    * which have that particularly structure.  To do no 
    * auto-complete, the value is set to AC_POUND_INCLUDE_NONE. To 
    * show a list of quoted filenames after the user types 
    * #include, followed by a space, this value is set to 
    * AC_POUND_INCLUDE_QUOTED_ON_SPACE.  To show a list of 
    * filenames after the user types " or < (after 
    * #include<space>), this value is set to 
    * AC_POUND_INCLUDE_ON_QUOTELT. 
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param value               new value
    */
   public static void setAutoCompletePoundIncludeOption(_str langId, int value)
   {
      setLanguageDefVar(langId, AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY, value);
   }

   /**
    * Retrieves the current version of the surround-with alias 
    * definitions for this language.   
    * 
    * @param langId              language ID (see {@link p_LangId})
    * 
    * @return int                surround-with alias version
    */
   public static int getSurroundWithVersion(_str langId)
   {
      return getLanguageDefVar(langId, SURROUND_WITH_VERSION_DEF_VAR_KEY);
   }

   /**
    * Sets the current version of the surround-with alias 
    * definitions for this language. 
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param value               surround-with alias version
    */
   public static void setSurroundWithVersion(_str langId, int value)
   {
      setLanguageDefVar(langId, SURROUND_WITH_VERSION_DEF_VAR_KEY, value);
   }

   #endregion Language-Specific Def-Vars

   #region Defaults
   
   /**
    * Checks all the information retrieved from the Language Definition to see 
    * if any items need to be populated with defaults.  This function does not 
    * allow any user defaults.  See maybeUseLanguageDefinitionItemDefault.
    * 
    * @param langID              language of interest
    * @param langInfo            array of Language Definition items
    */
   private static void checkAllLanguageDefinitionDefaults(_str langID, typeless (&langInfo)[])
   {
      for (i := 0; i <= LDI_LAST; i++) {
         maybeUseLanguageDefinitionItemDefault(langID, i, langInfo[i]);
      }
   }
   
   /**
    * Checks an item to see if it is a valid value for the given option.  If 
    * not, fills in a default.  A user-supplied default can be used.  If no 
    * user-supplied default is given, then the application default is used. 
    * 
    * @param langID              language of interest
    * @param item                item that we are checking (one of 
    *                            LanguageDefinitionItems)
    * @param value               value to check for validity and possibly 
    *                            replace with a default
    * @param userDefault         (optional) the default the user wishes to use 
    *                            in case the stored value is not valid
    */
   private static void maybeUseLanguageDefinitionItemDefault(_str langID, int item, typeless &value, typeless userDefault = null)
   {
      if (value == null) value = '';

      typeless appDefault; 
      useDefault := false;
      
      switch (item) {
      case LDI_MODE_NAME:
         break;
      case LDI_TABS:
         useDefault = (value == '');
         appDefault = '+8';
         break;
      case LDI_MARGINS:
         useDefault = (value == '');
         appDefault = '1 254 1';
         break;
      case LDI_KEY_TABLE:
         break;
      case LDI_WORD_WRAP:
         useDefault = !isinteger(value);
         appDefault = STRIP_SPACES_WWS | WORD_WRAP_WWS;
         break;
      case LDI_INDENT_WITH_TABS:
         useDefault = !isinteger(value);
         appDefault = 0;
         break;
      case LDI_SHOW_TABS:
         useDefault = !isinteger(value);
         appDefault = DEFAULT_SPECIAL_CHARS;
         break;
      case LDI_INDENT_STYLE:
         useDefault = !isinteger(value) || value > INDENT_SMART || value < INDENT_NONE || (value >= INDENT_SMART && langID == 'fundamental');
         if (langID == 'fundamental') {
            appDefault = INDENT_AUTO;
         } else {
            appDefault = INDENT_SMART;
         }
         break;
      case LDI_WORD_CHARS:
         useDefault = (value == '');
         if (_LanguageInheritsFrom('xml', langID)) appDefault = '\p{isXMLNameChar}?!';
         else appDefault = 'A-Za-z0-9_$';
         break;
      case LDI_LEXER_NAME:
         useDefault = (value == '');

         // special case for un-initialized Unix assembly lexer name
         if (_LanguageInheritsFrom('unixasm', langID)) {
            appDefault = 'Unix Assembler 'eq_name2value(substr(machine(), 1, 2), UNIX_ASM_LEXER_LIST);
         } else appDefault = '';
         break;
      case LDI_COLOR_FLAGS:
         useDefault = !isinteger(value);
         lexerName := getLexerName(langID);
         if (lexerName!='') appDefault = LANGUAGE_COLOR_FLAG;
         else appDefault = CLINE_COLOR_FLAG;
         break;
      case LDI_LINE_NUMBERS_LENGTH:
         useDefault = (!isinteger(value) || !value);
         appDefault = _default_option(VSOPTION_LINE_NUMBERS_LEN);

         if (!useDefault && value < 0) value = abs(value);
         break;
      case LDI_TRUNCATE_LENGTH:
         useDefault = !isinteger(value);
         appDefault = 0;
         break;
      case LDI_BOUNDS:
         useDefault = (value == '');
         appDefault = '';
         break;
      case LDI_CAPS:
         useDefault = !isinteger(value);
         appDefault = CM_CAPS_OFF;
         break;
      case LDI_SOFT_WRAP:
         useDefault = (!isinteger(value) || value == 2);
         appDefault = def_SoftWrap;
         break;
      case LDI_SOFT_WRAP_ON_WORD:
         useDefault = (!isinteger(value) || value == 2);
         appDefault = def_SoftWrapOnWord;
         break;
      case LDI_HEX_MODE:
         useDefault = !isinteger(value);
         appDefault = HM_HEX_OFF;
         break;
      case LDI_LINE_NUMBERS_FLAGS:
         useDefault = !isinteger(value);

         lineNumbersLen := getLineNumbersLength(langID, 0);
         if (lineNumbersLen) appDefault = LNF_ON | LNF_AUTOMATIC;
         else appDefault = 0;
         break;
      default:
         appDefault = 0;
      }
      
      if (useDefault) {
         if (userDefault != null) {
            value = userDefault;
         } else value = appDefault;
      }
   }
   
   /**
    * Checks all the information retrieved from the Language Options to see 
    * if any items need to be populated with defaults.  This function does not 
    * allow any user defaults.  See maybeUseLanguageOptionItemDefault. 
    * 
    * @param langID              language of interest
    * @param langInfo            array of Language Option items
    */
   private static void checkAllLanguageOptionDefaults(_str langID, typeless (&langInfo)[])
   {
      for (i := 0; i <= LOI_LAST; i++) {
         maybeUseLanguageOptionItemDefault(langID, i, langInfo[i]);
      }
   }
   
   /**
    * Checks an item to see if it is a valid value for the given option.  If 
    * not, fills in a default.  A user-supplied default can be used.  If no 
    * user-supplied default is given, then the application default is used. 
    * 
    * @param langID              language of interest
    * @param item                item that we are checking (one of 
    *                            LanguageOptionItems)
    * @param value               value to check for validity and possibly 
    *                            replace with a default
    * @param userDefault         (optional) the default the user wishes to use 
    *                            in case the stored value is not valid
    */
   private static void maybeUseLanguageOptionItemDefault(_str langID, int item, typeless &value, typeless userDefault = null)
   {
      if (value == null) value = '';

      typeless appDefault; 
      useDefault := false;
      
      switch (item) {
      case LOI_SYNTAX_INDENT:
         if (langID == 'fundamental') {
            useDefault = true;
            appDefault = 0;
         } else {
            useDefault = !isinteger(value);
            appDefault = 0;
         }
         break;
      case LOI_SYNTAX_EXPANSION:
      case LOI_INDENT_FIRST_LEVEL:
      case LOI_MULTILINE_IF_EXPANSION:
      case LOI_MAIN_STYLE:
      case LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS:
      case LOI_INDENT_CASE_FROM_SWITCH:
      case LOI_KEYWORD_CASE:
      case LOI_BEGIN_END_STYLE:
      case LOI_PAD_PARENS:
      case LOI_NO_SPACE_BEFORE_PAREN:
      case LOI_POINTER_STYLE:
      case LOI_FUNCTION_BEGIN_ON_NEW_LINE:
      case LOI_INSERT_BEGIN_END_IMMEDIATELY:
      case LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END:
      case LOI_DELPHI_EXPANSIONS:
      case LOI_TAG_CASE:
      case LOI_ATTRIBUTE_CASE:
      case LOI_WORD_VALUE_CASE:
      case LOI_HEX_VALUE_CASE:
      case LOI_QUOTES_FOR_NUMERIC_VALUES:
      case LOI_QUOTES_FOR_SINGLE_WORD_VALUES:
      case LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS:
      case LOI_USE_COLOR_NAMES:
      case LOI_USE_DIV_TAGS_FOR_ALIGNMENT:
      case LOI_USE_PATHS_FOR_FILE_ENTRIES:
      case LOI_AUTO_INSERT_LABEL:
      case LOI_RUBY_STYLE:
         useDefault = !isinteger(value);
         appDefault = 0;
         break;
      case LOI_MIN_ABBREVIATION:
      case LOI_BEGIN_END_COMMENTS:
      case LOI_AUTO_VALIDATE_ON_OPEN:
      case LOI_AUTO_CORRELATE_START_END_TAGS:
      case LOI_AUTO_SYMBOL_TRANSLATION:
      case LOI_COBOL_SYNTAX:
         useDefault = !isinteger(value);
         appDefault = 1;
         break;
      case LOI_QUICK_BRACE:
         useDefault = !isinteger(value);
         appDefault = BES_NO_QUICK_BRACE_UNBRACE;
         break;
      case LOI_CUDDLE_ELSE:
         useDefault = !isinteger(value);
         appDefault = BES_ELSE_ON_LINE_AFTER_BRACE;
         break;
      default:
         // we really don't know what's going on now
         useDefault = false;
         appDefault = 0;
         break;
      }
      
      if (useDefault) {
         if (userDefault != null) {
            value = userDefault;
         } else value = appDefault;
      }
   }
   
   #endregion Defaults
};
