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
#include "autocomplete.sh"
#include "se/lang/api/LanguageSettings.sh"
#import "main.e"
#import "stdcmds.e"
//#import "stdprocs.e"
#import "tags.e"
#import "cfg.e"
#endregion

_str _encode_vsenvvars(_str paths, bool isFilename, bool allowDotDot=true);
bool _is_syntax_indent_supported(_str langId,bool return_true_if_uses_syntax_indent_property=true);

namespace se.lang.api;

/**
 * This class is used to save and retrieve the language definition and language 
 * options. You can use the _LangGetProperty and 
 * _LangSetProeprty functions instead. 
 * 
 */
class LanguageSettings {
   /**
    * Determines if a language with the given langId is defined in the application.
    * 
    * @param langId              langId to look for
    * 
    * @return bool               true if the given langId is mapped to a defined 
    *                            language.
    */
   public static bool isLanguageDefined(_str langId)
   {
      return _LangIsDefined(langId);
   }

   /** 
    * Get the list of all language IDs currently defined in the application. 
    *  
    * @param allLangIds          (output) Array of language IDs 
    */
   public static void getAllLanguageIds(_str (&allLangIds)[])
   {
      allLangIds._makeempty();
      _GetAllLangIds(allLangIds);
   }
   /** 
    * Determines if option specified applies to this language 
    * 
    * @param langID    Language id (i.e "c" for C++).
    * @param option    An LOI_XXX option.
    * 
    * @return   Returns true if option applys
    */
   public static bool doesOptionApplyToLanguage(_str langID, _str option)
   {
      _str value=_LangGetProperty(langID,option,null);
      return !value._isempty();
   }
   public static int getAllLanguageOptions(_str langID, VS_LANGUAGE_OPTIONS &langOptions)
   {
      _GetDefaultLanguageOptions(langID, langOptions);

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

      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT, defaultValue);
   }

   /** 
    * Sets the auto-brace placement for the given languages. 
    * 
    * @param langID 
    * @param value AUTOBRACE_PLACE_* constant
    */
   public static void setAutoBracePlacement(_str langID, int value) {
      _LangSetProperty(langID,VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT, value);
   }

   /** 
    * Returns the name of the beautifier profile associated with 
    * langID, if any. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value. 
    * 
    * @return                    Profile name. 
    *                            
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getBeautifierProfileName(_str langID)
   {
      return _LangGetBeautifierDefault(langID);
   }
   /**
    * Returns true if the tab key should cycle through the possible 
    * indents when it's struck on an empty line.  This setting only 
    * makes sense for languages where the indent defines the block 
    * structure.  (Python) 
    * 
    * @param langID - Language id
    * @param defaultValue - Default value to use if the setting 
    *                     does not exist.
    * 
    * @return bool True if the setting is enabled.
    */
   public static bool getTabCyclesIndents(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_TAB_CYCLES_INDENT, defaultValue);
   }

   /**
    * Setting that controls whether the tab key should cycle
    * through the possible indents when it's struck on an empty 
    * line.  This setting only makes sense for languages where the 
    * indent defines the block structure.  (Python) 
    * 
    * @param langID - Language id
    * @param value - True to enable the setting.
    */
   public static void setTabCyclesIndents(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_TAB_CYCLES_INDENT, value);
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
      _LangSetProperty(langID, VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE, value);
   }

   /** 
    * Returns a set of BEAUT_EXPAND_* flags for the given language,
    * if any. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    Profile name. 
    *                            
    *  
    * @categories LanguageSettings_API 
    */
   public static int getBeautifierExpansions(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_BEAUTIFIER_EXPANSION_FLAGS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_BEAUTIFIER_EXPANSION_FLAGS, value);
   }

   public static void setAllLanguageOptions(_str langID, VS_LANGUAGE_OPTIONS &langOptions)
   {
      _SetDefaultLanguageOptions(langID, langOptions);
   }
   
   /**
    * Retrieves a VS_LANGUAGE_SETUP_OPTIONS struct populated with options for 
    * the given language. 
    * 
    * @param langID           language of interest
    * @param setup            struct to populate
    * 
    * @return                 Returns 0 if successful.
    *  
    * @categories LanguageSettings_API 
    */
   public static int getLanguageDefinitionOptions(_str langID, VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      VS_LANGUAGE_OPTIONS options;
      status := _GetDefaultLanguageOptions(langID, options);
      if (!status) {

         // now populate the struct
         setup.mode_name = _LangOptionsGetProperty(options,VSLANGPROPNAME_MODE_NAME);
         setup.tabs = _LangOptionsGetProperty(options,VSLANGPROPNAME_TABS);
         setup.margins = _LangOptionsGetProperty(options,VSLANGPROPNAME_MARGINS);
         setup.keytab_name = _LangOptionsGetProperty(options,VSLANGPROPNAME_EVENTTAB_NAME);
         setup.word_wrap_style = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_WORD_WRAP_FLAGS,STRIP_SPACES_WWS);
         setup.indent_with_tabs = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_INDENT_WITH_TABS,0)!=0;
         setup.show_tabs = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,DEFAULT_SPECIAL_CHARS);
         setup.hex_mode = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_HEX_MODE,0);
         setup.indent_style = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);
         setup.word_chars = _LangOptionsGetProperty(options,VSLANGPROPNAME_WORD_CHARS);
         setup.lexer_name = _LangOptionsGetProperty(options,VSLANGPROPNAME_LEXER_NAME);
         setup.color_flags = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_COLOR_FLAGS,CLINE_COLOR_FLAG);
         setup.line_numbers_flags = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_LINE_NUMBERS_FLAGS,0);
         setup.line_numbers_len = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_LINE_NUMBERS_LEN,0);
         setup.TruncateLength = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_TRUNCATE_LENGTH,0);
         setup.bounds = _LangOptionsGetProperty(options,VSLANGPROPNAME_BOUNDS);
         setup.caps = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_AUTO_CAPS,0);
         setup.SoftWrap = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_SOFT_WRAP,0)!=0;
         setup.SoftWrapOnWord = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,1)!=0;
         setup.AutoLeftMargin = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_AUTO_LEFT_MARGIN,0)!=0;
         setup.FixedWidthRightMargin = _LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,0);
      }
   
      
      return status;
   }
   
   /**
    * Sets the options contained in a VS_LANGUAGE_SETUP_OPTIONS struct for the 
    * given language.
    * 
    * @param langID           language of interest
    * @param setup            struct to populate 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLanguageDefinitionOptions(_str langID, VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      // get the current options
      VS_LANGUAGE_OPTIONS options;
      _GetDefaultLanguageOptions(langID, options);

      // replace with our data
      if (setup.mode_name != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_MODE_NAME,setup.mode_name);
      if (setup.tabs != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_TABS,setup.tabs);
      if (setup.keytab_name != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_EVENTTAB_NAME,setup.keytab_name);
      if (setup.word_wrap_style != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_WORD_WRAP_FLAGS,setup.word_wrap_style);
      if (setup.indent_with_tabs != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_INDENT_WITH_TABS,setup.indent_with_tabs);
      if (setup.show_tabs != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,setup.show_tabs);
      if (setup.hex_mode != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_HEX_MODE,setup.hex_mode);
      if (setup.indent_style != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_INDENT_STYLE,setup.indent_style);
      if (setup.word_chars != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_WORD_CHARS,setup.word_chars);
      if (setup.lexer_name != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_LEXER_NAME,setup.lexer_name);
      if (setup.color_flags != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_COLOR_FLAGS,setup.color_flags);
      if (setup.line_numbers_flags != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_LINE_NUMBERS_FLAGS,setup.line_numbers_flags);
      if (setup.line_numbers_len != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_LINE_NUMBERS_LEN,setup.line_numbers_len);
      if (setup.TruncateLength != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_TRUNCATE_LENGTH,setup.TruncateLength);
      if (setup.caps != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_AUTO_CAPS,setup.caps);
      if (setup.SoftWrap != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_SOFT_WRAP,setup.SoftWrap);
      if (setup.SoftWrapOnWord != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,setup.SoftWrapOnWord);
      if (setup.AutoLeftMargin != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_AUTO_LEFT_MARGIN,setup.AutoLeftMargin);
      if (setup.FixedWidthRightMargin != null) _LangOptionsSetProperty(options,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,setup.FixedWidthRightMargin);

      if (setup.margins != null) {
         parse setup.margins with auto lm auto rm auto npm;

         if (isinteger(lm) && isinteger(rm) && isinteger(npm)) {
            _LangOptionsSetProperty(options,VSLANGPROPNAME_MARGINS,lm' 'rm' 'npm);
         }
      }

      if (setup.bounds != null) {
         parse setup.bounds with auto bs auto be;
         if (isinteger(bs) && isinteger(be)) {
            _LangOptionsSetProperty(options,VSLANGPROPNAME_BOUNDS, bs' 'be);
         }
      }

      // set the new stuff
      _SetDefaultLanguageOptions(langID, options);
   }
   
   /**
    * Builds a language setup string given a 
    * VS_LANGUAGE_SETUP_OPTIONS object containing language options. 
    *  
    * <p>This function is here mainly for backward 
    * compatibility. It's better to use other functions for setting
    * language options.
    * 
    * @param setup   language options
    * 
    * @return        language setup string 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getLanguageSetupStringFromSetupOptions(VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      return buildLangDefinitionString(setup);
   }

   /**
    * Builds the language setup string from an array of language settings.
    * 
    * @return           setup string
    */
   private static _str buildLangDefinitionString(VS_LANGUAGE_SETUP_OPTIONS &setup)
   {
      info := MODE_NAME_SHORT_KEY'='setup.mode_name','TABS_SHORT_KEY'=' setup.tabs :+
         ','MARGINS_SHORT_KEY'=' setup.margins','KEY_TABLE_SHORT_KEY'=' setup.keytab_name','WORD_WRAP_SHORT_KEY'='setup.word_wrap_style :+
         ','INDENT_WITH_TABS_SHORT_KEY'='setup.indent_with_tabs','SHOW_TABS_SHORT_KEY'='setup.show_tabs :+
         ','INDENT_STYLE_SHORT_KEY'='setup.indent_style','WORD_CHARS_SHORT_KEY'='setup.word_chars :+
         ','LEXER_NAME_SHORT_KEY'='setup.lexer_name','COLOR_FLAGS_SHORT_KEY'='setup.color_flags :+
         ','LINE_NUMBERS_LEN_SHORT_KEY'='setup.line_numbers_len','TRUNCATE_LENGTH_SHORT_KEY'='setup.TruncateLength :+
         ','BOUNDS_SHORT_KEY'='setup.bounds','CAPS_SHORT_KEY'='setup.caps','SOFT_WRAP_SHORT_KEY'='setup.SoftWrap :+
         ','SOFT_WRAP_ON_WORD_SHORT_KEY'='setup.SoftWrapOnWord','HEX_MODE_SHORT_KEY'='setup.hex_mode :+ 
         ','LINE_NUMBERS_FLAGS_SHORT_KEY'='setup.line_numbers_flags:+
         ','AUTO_LEFT_MARGIN_SHORT_KEY'='setup.AutoLeftMargin:+
         ','FIXED_WIDTH_RIGHT_MARGIN_SHORT_KEY'='setup.FixedWidthRightMargin:+
         ',';

      return info;
   }
   
   /**
    * Returns true if syntax expansions, alias expansions and the 
    * like should run the beautifier on the expanded code. 
    * 
    * @return bool
    */
   public static bool shouldBeautifyExpansions(_str langId)
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
   private static bool isOptionInParseMap(_str langID, int option) {
      return doesOptionApplyToLanguage(langID,option);
   }

   /**
    * Set the given language option item for this language.
    * 
    * @param langID           language of interest
    * @param propertyName     option we want to set (one of the 
    *                         LanguageOptionItems enum)
    * @param value            new value of option 
    */
   private static void setLanguageOptionItem(_str langID, _str propertyName, typeless value)
   {
      if (!doesOptionApplyToLanguage(langID, propertyName)) return;
      _LangSetProperty(langID,propertyName,value);
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
      return _LangGetProperty(langID,VSLANGPROPNAME_MODE_NAME);
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
   public static _str getTabs(_str langID, _str defaultValue = "+8")
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_TABS,defaultValue);
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
   public static _str getMargins(_str langID, _str defaultValue = "1 254 1")
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_MARGINS,defaultValue);
   }
   /**
    * Retrieves the auto left margin for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto left margin for 
    *                         language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getAutoLeftMargin(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_AUTO_LEFT_MARGIN,defaultValue);
   }

   /**
    * Retrieves the fixed width right margin for 
    * the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 fixed width right margin for language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getFixedWidthRightMargin(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,defaultValue);
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
      return _LangGetProperty(langID,VSLANGPROPNAME_EVENTTAB_NAME);
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
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_WORD_WRAP_FLAGS,defaultValue);
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
   public static bool getIndentWithTabs(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_INDENT_WITH_TABS,defaultValue);
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
   public static int getShowTabs(_str langID, int defaultValue = DEFAULT_SPECIAL_CHARS)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,defaultValue);
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
   public static int getIndentStyle(_str langID, int defaultValue = INDENT_AUTO)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_INDENT_STYLE,defaultValue);
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
      word_chars:=_LangGetProperty(langID,VSLANGPROPNAME_WORD_CHARS,null);
      if (word_chars._isempty()) {
         if (_LanguageInheritsFrom("xml", langID)) {
            return "\\p{isXMLNameChar}?!";
         } else {
            return "A-Za-z0-9_$";
         }
      }
      return word_chars;
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
      return _LangGetProperty(langID,VSLANGPROPNAME_LEXER_NAME);
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
   public static int getColorFlags(_str langID, int defaultValue = CLINE_COLOR_FLAG)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_COLOR_FLAGS,defaultValue);
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
   public static int getLineNumbersLength(_str langID, int defaultValue = _default_option(VSOPTION_LINE_NUMBERS_LEN))
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_LINE_NUMBERS_LEN,defaultValue);
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
   public static int getTruncateLength(_str langID, int defaultValue = 0) {
         return _LangGetPropertyInt32(langID,VSLANGPROPNAME_TRUNCATE_LENGTH,defaultValue);
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
   public static _str getBounds(_str langID, _str defaultValue = '')
   {
      bounds:=_LangGetProperty(langID, VSLANGPROPNAME_BOUNDS,defaultValue);
      parse bounds with auto bounds_start auto bounds_end;
      if (!isinteger(bounds_start) || !isinteger(bounds_end)) {
         return '0 0';
      }
      return bounds;
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
   public static int getCaps(_str langID, int defaultValue = CM_CAPS_OFF)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_AUTO_CAPS,defaultValue);
   }

   /**
    * Retrieves the spell check while typing setting for the given
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 Spell check while typing setting for
    *                         language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getSpellCheckWhileTyping(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING,defaultValue);
   }
   /**
    * Retrieves the spell check while typing elements setting for 
    * the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 Spell check while typing elements 
    *                         setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getSpellCheckWhileTypingElements(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS,defaultValue);
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
   public static bool getSoftWrap(_str langID, bool defaultValue = def_SoftWrap)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_SOFT_WRAP,defaultValue);
   }
   /**
    * Retrieves the show minimap setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 show minimap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getShowMinimap(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_SHOW_MINIMAP,defaultValue);
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
   public static bool getSoftWrapOnWord(_str langID, bool defaultValue = def_SoftWrapOnWord)
   {
      return _LangGetPropertyBool(langID,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,defaultValue);
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
   public static int getHexMode(_str langID, int defaultValue = HM_HEX_OFF)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_HEX_MODE,defaultValue);
   }
   /**
    * Retrieves the hex mode number of columns
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
   public static int getHexNofCols(_str langID, int defaultValue = 4)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_HEX_NOFCOLS,defaultValue);
   }
   /**
    * Retrieves the hex mode number of bytes per column
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
   public static int getHexBytesPerCol(_str langID, int defaultValue = 4)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_HEX_BYTES_PER_COL,defaultValue);
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
   public static int getLineNumbersFlags(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,VSLANGPROPNAME_LINE_NUMBERS_FLAGS,defaultValue);
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
   public static bool getSyntaxExpansion(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,LOI_SYNTAX_EXPANSION,defaultValue);
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
   public static int getSyntaxIndent(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_SYNTAX_INDENT,defaultValue);
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
   public static int getMinimumAbbreviation(_str langID, int defaultValue = 1)
   {
      return _LangGetPropertyInt32(langID,LOI_MIN_ABBREVIATION,defaultValue);
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
   public static bool getIndentCaseFromSwitch(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,LOI_INDENT_CASE_FROM_SWITCH,defaultValue);
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
   public static bool getBeginEndComments(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_BEGIN_END_COMMENTS, defaultValue);
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
   public static int getKeywordCase(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_KEYWORD_CASE,defaultValue);
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
   public static int getIndentFirstLevel(_str langID, int defaultValue = 1)
   {
      return _LangGetPropertyInt32(langID, LOI_INDENT_FIRST_LEVEL, defaultValue);
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
   public static bool getMultilineIfExpansion(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_MULTILINE_IF_EXPANSION, defaultValue);
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
   public static int getMainStyle(_str langID, int defaultValue = 1)
   {
      return _LangGetPropertyInt32(langID, LOI_MAIN_STYLE, defaultValue);
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
   public static int getUseContinuationIndentOnFunctionParameters(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID, LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS, defaultValue);
   }
   /**
    * Retrieves the continuation indent for specific functions
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 continuation indent for specific 
    *                         functions:
    *  
    * <p>fun-name1 use-contuation1 fun-name2 use-contuation2 etc. 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getUseContinuationIndentOnFunctionParametersList(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS_LIST, defaultValue);
   }

   /**
    * Retrieves the indent alignment on function parameters setting
    * for the given language.  This setting is currently just used 
    * for Python, and uses the same option storage as the "Use 
    * continuation indent on function parameters" option for other 
    * languages, with additional options. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 function parameter alignment setting
    *                         for language
    *                         0 - Align on parens
    *                         1 - continuation indent
    *                         2 - auto 
    *  
    * @categories LanguageSettings_API 
    */
   public static int getFunctionParameterAlignment(_str langID, int defaultValue = null)
   {
      // different name, same option
      return getUseContinuationIndentOnFunctionParameters(langID, defaultValue);
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
   public static int getBeginEndStyle(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_BEGIN_END_STYLE,defaultValue);
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
   public static bool getPadParens(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,LOI_PAD_PARENS,defaultValue);
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
   public static bool getNoSpaceBeforeParen(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,LOI_NO_SPACE_BEFORE_PAREN,defaultValue);
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
   public static int getPointerStyle(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_POINTER_STYLE,defaultValue);
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
   public static bool getFunctionBeginOnNewLine(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID,LOI_FUNCTION_BEGIN_ON_NEW_LINE,defaultValue);
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
   public static bool getInsertBeginEndImmediately(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, LOI_INSERT_BEGIN_END_IMMEDIATELY, defaultValue);
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
   public static bool getInsertBlankLineBetweenBeginEnd(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END, defaultValue);
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
   public static bool getQuickBrace(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, LOI_QUICK_BRACE, defaultValue);
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
   public static bool getCuddleElse(_str langID, bool defaultValue = true)
   {
      return !_LangGetPropertyBool(langID, LOI_CUDDLE_ELSE, defaultValue);
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
   public static int getTagCase(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_TAG_CASE,defaultValue);
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
   public static int getAttributeCase(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_ATTRIBUTE_CASE,defaultValue);
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
   public static int getValueCase(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_WORD_VALUE_CASE,defaultValue);
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
   public static int getHexValueCase(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID,LOI_HEX_VALUE_CASE,defaultValue);
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
   public static bool getLowercaseFilenamesWhenInsertingLinks(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, defaultValue);
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
   public static bool getQuoteNumberValues(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, LOI_QUOTE_NUMBER_VALUES, defaultValue);
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
   public static bool getQuoteWordValues(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, LOI_QUOTE_WORD_VALUES, defaultValue);
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
   public static bool getUseColorNames(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_USE_COLOR_NAMES, defaultValue);
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
   public static bool getUseDivTagsForAlignment(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_USE_DIV_TAGS_FOR_ALIGNMENT, defaultValue);
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
   public static bool getUsePathsForFileEntries(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_USE_PATHS_FOR_FILE_ENTRIES, defaultValue);
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
   public static bool getAutoValidateOnOpen(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_AUTO_VALIDATE_ON_OPEN, defaultValue);
   }
   /**
    * Retrieves the auto XML well-formedness on open setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param defaultValue     (optional) the value to return if no value is 
    *                         saved for this setting in the given language.  If
    *                         this is not specified, then the application's
    *                         default value for this language setting is
    *                         returned
    * 
    * @return                 auto check XML well-formedness on open setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getAutoWellFormedNessOnOpen(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_AUTO_WELLFORMEDNESS_ON_OPEN, defaultValue);
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
   public static bool getAutoCorrelateStartEndTags(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_AUTO_CORRELATE_START_END_TAGS, defaultValue);
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
   public static bool getAutoSymbolTranslation(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_AUTO_SYMBOL_TRANSLATION, defaultValue);
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
   public static bool getInsertRightAngleBracket(_str langID, bool defaultValue = false)
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
   public static bool getAutoInsertLabel(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_AUTO_INSERT_LABEL, defaultValue);
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
   public static int getRubyStyle(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID, LOI_RUBY_STYLE, defaultValue);
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
   public static bool getDelphiExpansions(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, LOI_DELPHI_EXPANSIONS, defaultValue);
   }
   
   /**
    * Retrieves the language options, with the possibility of 
    * creating a new language if one with the given langID does not 
    * exist. 
    * 
    * @param langID 
    * @param options 
    * @param createNewLang 
    */
   private static void getOrCreateLanguageOptions(_str langID, VS_LANGUAGE_OPTIONS &options, bool createNewLang)
   {
      if (_GetDefaultLanguageOptions(langID, options)) {
         if (createNewLang) {
            _LangInitOptions(options,true,langID);
            _SetDefaultLanguageOptions(langID,options);
         }
      }
   }

   /**
    * Set the mode name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new mode name for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setModeName(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_MODE_NAME,value);
   }

   /**
    * Set the tabs for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new tabs for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTabs(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_TABS,value);
   }

   /**
    * Set the margins for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new margins for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMargins(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_MARGINS,value);
   }

   /**
    * Set the auto left margin for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoLeftMargin(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_AUTO_LEFT_MARGIN,value);
   }

   /**
    * Set the fixed width right margin for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setFixedWidthRightMargin(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,value);
   }

   /**
    * Set the key table name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new key table name for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setKeyTableName(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_EVENTTAB_NAME,value);
   }

   /**
    * Set the word wrap style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new word wrap style for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setWordWrapStyle(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_WORD_WRAP_FLAGS,value);
   }

   /**
    * Set the indent with tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent with tabs setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentWithTabs(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_INDENT_WITH_TABS,value);
   }

   /**
    * Set the show tabs setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new show tabs setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setShowTabs(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,value);
   }

   /**
    * Set the indent style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent style for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentStyle(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_INDENT_STYLE,value);
   }

   /**
    * Set the word characters for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new word characters for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setWordChars(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_WORD_CHARS,value);
   }

   /**
    * Set the lexer name for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new lexer name for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLexerName(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_LEXER_NAME,value);
   }

   /**
    * Set the color flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new color flags for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setColorFlags(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_COLOR_FLAGS,value);
   }

   /**
    * Set the line numbers length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new line numbers length for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLineNumbersLength(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_LINE_NUMBERS_LEN,value);
   }

   /**
    * Set the truncate length for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new truncate length for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTruncateLength(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_TRUNCATE_LENGTH,value);
   }

   /**
    * Set the bounds for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new bounds for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBounds(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_BOUNDS,value);
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
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCaps(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_AUTO_CAPS,value);
   }

   /**
    * Set the spell check while typing setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new spell check while typing
    *                         setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSpellCheckWhileTyping(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING,value);
   }

   /**
    * Set the spell check while typing setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new spell check while typing
    *                         setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSpellCheckWhileTypingElements(_str langID, _str value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS,value);
   }

   /**
    * Set the soft wrap setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSoftWrap(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_SOFT_WRAP,value);
   }

   /**
    * Set the show minimap setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new show minimap setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setShowMinimap(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_SHOW_MINIMAP,value);
   }

   /**
    * Set the soft wrap on word setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new soft wrap on word setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSoftWrapOnWord(_str langID, bool value)
   {
      _LangSetProperty(langID,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,value);
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
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexMode(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_HEX_MODE,value);
   }
   /**
    * Set the hex mode number of columns for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new hex mode number of columns for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexNofCols(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_HEX_NOFCOLS,value);
   }

   /**
    * Set the hex mode number of bytes per column for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new hex mode number of bytes per column for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexBytesPerCol(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_HEX_BYTES_PER_COL,value);
   }

   /**
    * Set the line numbers flags for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new line numbers flags for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLineNumbersFlags(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,VSLANGPROPNAME_LINE_NUMBERS_FLAGS,value);
   }

   /**
    * Sets the syntax expansion setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new syntax expansion setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSyntaxExpansion(_str langID, bool value)
   {
      _LangSetProperty(langID,LOI_SYNTAX_EXPANSION,value);
   }

   /**
    * Sets the syntax indent for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new syntax indent for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSyntaxIndent(_str langID, int value)
   {
      if (!_is_syntax_indent_supported(langID)) {
         return;
      }
      _LangSetPropertyInt32(langID,LOI_SYNTAX_INDENT,value);
   }

   /**
    * Sets the minimum abbreviation setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new minimum abbreviation setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMinimumAbbreviation(_str langID, int value)
   {
      _LangSetPropertyInt32(langID,LOI_MIN_ABBREVIATION,value);
   }

   /**
    * Sets the indent case from switch setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent case from switch setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentCaseFromSwitch(_str langID, bool value)
   {
      _LangSetProperty(langID,LOI_INDENT_CASE_FROM_SWITCH,value);
   }

   /**
    * Sets the begin/end comments setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new begin/end comments setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeginEndComments(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_BEGIN_END_COMMENTS, value);
   }

   /**
    * Sets the keyword case for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new keyword case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setKeywordCase(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_KEYWORD_CASE, value);
   }

   /**
    * Sets the indent first level setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new indent first level setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setIndentFirstLevel(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_INDENT_FIRST_LEVEL, value);
   }

   /**
    * Sets the multiline IF expansion setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new multiline IF expansion setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMultilineIfExpansion(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_MULTILINE_IF_EXPANSION, value);
   }

   /**
    * Sets the MAIN style setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new MAIN style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setMainStyle(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_MAIN_STYLE, value);
   }

   /**
    * Sets the continuation indent on function parameters setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new continuation indent on function parameters setting 
    *                         for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseContinuationIndentOnFunctionParameters(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS, value);
   }
   /**
    * Sets the continuation indent for specific function names 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value 
    *      fun-name1 use-contuation1 fun-name2 use-contuation2 etc.
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseContinuationIndentOnFunctionParametersList(_str langID, _str value)
   {
      setLanguageOptionItem(langID, VSLANGPROPNAME_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS_LIST, value);
   }

   /**
    * Sets the indent alignment on function parameters setting
    * for the given language.  This setting is currently just used 
    * for Python, and uses the same option storage as the "Use 
    * continuation indent on function parameters" option for other 
    * languages, with additional options. 
    * 
    * @param langID           language ID (see {@link p_LangId}) 
    * @param value            function parameter alignment setting
    *                         for language
    *                         0 - Align on parens
    *                         1 - continuation indent
    *                         2 - auto 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setFunctionParameterAlignment(_str langID, int value)
   {
      setUseContinuationIndentOnFunctionParameters(langID, value);
   }

   /**
    * Sets the begin/end style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new begin/end style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setBeginEndStyle(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_BEGIN_END_STYLE, value);
   }
   /**
    * Sets the pad parentheses setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new pad parentheses setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setPadParens(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_PAD_PARENS, value);
   }
   /**
    * Sets the no space before parenthesis setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new no space before parenthesis setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setNoSpaceBeforeParen(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_NO_SPACE_BEFORE_PAREN, value);
   }
   /**
    * Sets the pointer style for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new pointer style setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setPointerStyle(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_POINTER_STYLE, value);
   }

   /**
    * Sets the function brace on new line setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new function brace on new line setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setFunctionBeginOnNewLine(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_FUNCTION_BEGIN_ON_NEW_LINE, value);
   }

   /**
    * Sets the insert braces immediately setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert braces immediately setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setInsertBeginEndImmediately(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_INSERT_BEGIN_END_IMMEDIATELY, 
                            value ? 1 : 0);
   }

   /**
    * Sets the insert blank line between braces setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert blank line between braces setting for 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setInsertBlankLineBetweenBeginEnd(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END, 
                            value ? 1 : 0);
   }

   /**
    * Sets the quick brace setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quick brace setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuickBrace(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_QUICK_BRACE, value);
   }

   /**
    * Sets the cuddle else setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new cuddle else setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setCuddleElse(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_CUDDLE_ELSE, value ? 0 : 1);
   }

   /**
    * Sets the tag case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new tag case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTagCase(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_TAG_CASE, value);
   }

   /**
    * Sets the attribute case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new attribute case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAttributeCase(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_ATTRIBUTE_CASE, value);
   }

   /**
    * Sets the single word value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new single word value case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setValueCase(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_WORD_VALUE_CASE, value);
   }

   /**
    * Sets the hex value case setting for the given language.
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new hex value case setting for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setHexValueCase(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_HEX_VALUE_CASE, value);
   }

   /**
    * Sets the lowercase filename when inserting links setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new lowercase filename when inserting links setting 
    *                         for language
    *  
    * @categories LanguageSettings_API 
    */
   public static void setLowercaseFilenamesWhenInsertingLinks(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, value);
   }

   /**
    * Sets the quotes for numeric values setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quotes for numeric values setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuoteNumberValues(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_QUOTE_NUMBER_VALUES, value);
   }
   // Use setQuoteNumberValues instead. This function
   // is needed for imported from SlickEdit <v21
   public static void setQuotesForNumericValues(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_QUOTE_NUMBER_VALUES, value);
   }

   /**
    * Sets the quotes for single word values setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new quotes for single word values setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setQuoteWordValues(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_QUOTE_WORD_VALUES, value);
   }
   // Use setQuoteWordValues instead. This function
   // is needed for imported from SlickEdit <v21
   public static void setQuotesForSingleWordValues(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_QUOTE_WORD_VALUES, value);
   }

   /**
    * Sets the use color names setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use color names setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseColorNames(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_USE_COLOR_NAMES, value);
   }

   /**
    * Sets the use div tags for alignment setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use div tags for alignment setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUseDivTagsForAlignment(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_USE_DIV_TAGS_FOR_ALIGNMENT, value);
   }

   /**
    * Sets the use paths for file entries setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new use paths for file entries setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setUsePathsForFileEntries(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_USE_PATHS_FOR_FILE_ENTRIES, value);
   }

   /**
    * Sets the auto validate on open setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto validate on open setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoValidateOnOpen(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_AUTO_VALIDATE_ON_OPEN, value);
   }
   /**
    * Sets the auto XML well-formedness check on open setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto wellformedness on open setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoWellFormedNessOnOpen(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_AUTO_WELLFORMEDNESS_ON_OPEN, value);
   }

   /**
    * Sets the auto correlate start/end tags setting for the given 
    * language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto correlate start/end tags setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCorrelateStartEndTags(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_AUTO_CORRELATE_START_END_TAGS, value);
   }

   /**
    * Sets the auto symbol translation setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto symbol translation setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoSymbolTranslation(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_AUTO_SYMBOL_TRANSLATION, value);
   }

   /**
    * Sets the insert right angle bracket setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new insert right angle bracket setting for language 
    *  
    * @categories LanguageSettings_API 
    * @deprecated 
    */
   public static void setInsertRightAngleBracket(_str langID, bool value)
   {
   }

   /**
    * Sets the auto-insert label setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new auto-insert label setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoInsertLabel(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_AUTO_INSERT_LABEL, value);
   }

   /**
    * Sets the ruby style setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new ruby style setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setRubyStyle(_str langID, int value)
   {
      setLanguageOptionItem(langID, LOI_RUBY_STYLE, value);
   }

   /**
    * Sets the delphi expansion setting for the given language. 
    * 
    * @param langID           language ID (see {@link p_LangId})
    * @param value            new delphi expansion setting for language 
    *  
    * @categories LanguageSettings_API 
    */
   public static void setDelphiExpansions(_str langID, bool value)
   {
      setLanguageOptionItem(langID, LOI_DELPHI_EXPANSIONS,
         value ? 1 : 0);
      
   }
   
   #region Language-Specific Def-Vars


   /**
    * Gets the list of languages which a symbol defined in the 
    * current language can be referened in. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value. 
    * 
    * @return                    begin/end pairs value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getReferencedInLanguageIDs(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_REFERENCED_IN_LANGIDS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_REFERENCED_IN_LANGIDS, value);
   }

   /**
    * Gets the Begin/End pairs for this language.  This value is available on the 
    * GUI on the General form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    begin/end pairs value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getBeginEndPairs(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID,VSLANGPROPNAME_BEGIN_END_PAIRS,defaultValue);
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
      _LangSetProperty(langID,VSLANGPROPNAME_BEGIN_END_PAIRS,value);
   }

   /**
    * Gets the smart tab value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    smart tab value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSmartTab(_str langID, int defaultValue = 2)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_SMART_TAB, defaultValue);
   }

   /**
    * Gets the tab style value for this language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    smart tab value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getTabStyle(_str langID, int defaultValue = VSTABSTYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_TAB_STYLE, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_SMART_TAB, value);
   }

   /**
    * Sets the tab style value for this language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setTabStyle(_str langID, int value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_TAB_STYLE, value);
   }

   /**
    * Gets the smartpaste value for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    smartpaste value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getSmartPaste(_str langID, bool defaultValue = true)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_SMART_PASTE, defaultValue);
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
   public static void setSmartPaste(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_SMART_PASTE, value);
   }

   /**
    * Gets the code margin setting for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    code margins string 
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getCodeMargins(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_CODE_MARGINS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_CODE_MARGINS, value);
   }

   /**
    * Gets the diff columns setting for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    diff columns string, consisting of
    *                            on/off' 'startColumn' 'endcolumn.
    *                            For example, a setting of '1 1 70'
    *                            would mean diff columns are one,
    *                            with a start of 1 and end of 70
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getDiffColumns(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID, VSLANGPROPNAME_DIFF_COLUMNS, defaultValue);
   }

   /**
    * Sets the diff margins for this language.  
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               diff columns string, consisting of 
    *                            on/off' 'startColumn' 'endcolumn.
    *                            For example, a setting of '1 1 70'
    *                            would mean diff columns are one,
    *                            with a start of 1 and end of 70
    *  
    * @categories LanguageSettings_API 
    */
   public static void setDiffColumns(_str langID, _str value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_DIFF_COLUMNS, value);
   }

   /**
    * Gets the adaptive formatting flags for this language.  This value is 
    * controlled on the GUI on the Adaptive Formatting form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    adaptive formatting flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAdaptiveFormattingFlags(_str langID, int defaultValue = 0)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS, value);
   }

   /**
    * Gets the adaptive formatting value for this language, which controls whether 
    * adaptive formatting is turned on. This value is controlled on the GUI on the
    * Adaptive Formatting form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    adaptive formatting value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getUseAdaptiveFormatting(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING, defaultValue);
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
   public static void setUseAdaptiveFormatting(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING, value);
   }

   /**
    * Gets the inheritance value for this language, which defines if a language 
    * inherits callbacks from another language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    *  
    * @return                    inheritance value for this language (language 
    *                            whose callbacks this language inherits from)
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getLangInheritsFrom(_str langID, _str defaultValue = '')
   {
      return _LangGetProperty(langID,VSLANGPROPNAME_INHERITS_FROM,defaultValue);
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
      _LangSetProperty(langID,VSLANGPROPNAME_INHERITS_FROM,value);
   }

   /**
    * Gets the numbering style for this language.  This value is available on the 
    * Formattiong options form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    numbering style value for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getNumberingStyle(_str langID, int defaultValue = 2)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_NUMBERING_STYLE, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_NUMBERING_STYLE, value);
   }

   /**
    * Gets the surround options for this language.  This value is available on the 
    * GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    surround options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSurroundOptions(_str langID, int defaultValue = 65535)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_SURROUND_FLAGS, defaultValue);  
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
      _LangSetProperty(langID, VSLANGPROPNAME_SURROUND_FLAGS, value);
   }

   /**
    * Gets the codehelp flags for this language.  The options for this value are 
    * available on the GUI on the Context Tagging form for each applicable 
    * language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    codehelp flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static VSCodeHelpFlags getCodehelpFlags(_str langID, VSCodeHelpFlags defaultValue = VSCODEHELPFLAG_DEFAULT_FLAGS)
   {
      flags := (VSCodeHelpFlags) _LangGetPropertyInt64(langID, VSLANGPROPNAME_CODE_HELP_FLAGS, defaultValue);
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
   public static void setCodehelpFlags(_str langID, VSCodeHelpFlags value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_CODE_HELP_FLAGS, value);
   }

   /**
    * Gets the autocomplete options for this language, which are a bitset of 
    * AUTO_COMPLETE_. This value controls the options which are available on the
    * AutoComplete form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    autocomplete options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static AutoCompleteFlags getAutoCompleteOptions(_str langID, AutoCompleteFlags defaultValue=AUTO_COMPLETE_DEFAULT)
   {
      return (AutoCompleteFlags) _LangGetPropertyInt64(langID, VSLANGPROPNAME_AUTO_COMPLETE_FLAGS, defaultValue);
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
   public static void setAutoCompleteOptions(_str langID, AutoCompleteFlags value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_AUTO_COMPLETE_FLAGS, value);
   }

   /**
    * Gets the minimum length required for autocomplete to be triggered for this 
    * language. This value is available on the AutoComplete form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    minimum autocomplete length for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoCompleteMinimumLength(_str langID, int defaultValue = 1)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_AUTO_COMPLETE_MIN, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_AUTO_COMPLETE_MIN, value);
   }

   /**
    * Gets the symbol coloring options for this language.  This value is controlled
    * by options which are available on the View form for each applicable language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    symbol coloring options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSymbolColoringOptions(_str langID, int defaultValue = 41)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_SYMBOL_COLORING_FLAGS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_SYMBOL_COLORING_FLAGS, value);
   }


   /**
    * Determines whether backspace at the beginning of the line unindents the line
    * for this language. This value is available on the Indent form for each 
    * applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    backspace options for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getBackspaceUnindents(_str langID)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_BACKSPACE_UNINDENTS,false);
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
   public static void setBackspaceUnindents(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_BACKSPACE_UNINDENTS, value);
   }


   /**
    * Gets the name of the menu used for right-click context menus when there is a
    * selection for this language. This value is available on the General form for
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    menu info for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getMenuIfSelection(_str langID, _str defaultValue = '_ext_menu_default_sel')
   {
      return _LangGetProperty(langID,VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION,defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION, value);
   }

   /**
    * Gets the name of the menu used for right-click context menus when there is 
    * no selection for this language. This value is available on the General form 
    * for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    menu info for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static _str getMenuIfNoSelection(_str langID, _str defaultValue = '_ext_menu_default')
   {
      return _LangGetProperty(langID,VSLANGPROPNAME_CONTEXT_MENU,defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_CONTEXT_MENU, value);
   }

   /**
    * Retrieves a file option.  These options are stored in language-specific 
    * properties as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param langPropName        Language property name 
    *                            VSLANGPROPNAME_*
    * @param flag                string to look for to determine whether this 
    *                            option is on or off
    * 
    * @return                    1 for +flag, 0 for -flag, -1 for flag not found
    */
   private static int getFileOption(_str langID, _str langPropName, _str flag)
   {
      fileOptions := _LangGetProperty(langID, langPropName,'');
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
    * properties as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param langPropName        Language property name 
    *                            VSLANGPROPNAME_*
    * @param flag                string to which determines whether this option 
    *                            is on or off
    * @param value               how we want to set the flag in the
    *                            option string:  1 for +flag, 0 for
    *                            -flag, -1 for flag not found
    */
   private static void setFileOption(_str langID, _str langPropName, _str flag, int value)
   {
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
      fileOptions := _LangGetProperty(langID, langPropName, '');
      if (fileOptions != '') {
         // remove the existing setting for this flag
         fileOptions = stranslate(fileOptions, '', '[ ]*[+-]'flag, 'R');
      } 

      // add in the new option
      fileOptions = strip(fileOptions :+ newOption);

      // finally, set the new option
      _LangSetProperty(langID, langPropName, strip(fileOptions));
   }

   /**
    * Retrieves a file option.  These options are stored in language-specific 
    * properties as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param langPropName        Language property name 
    *                            VSLANGPROPNAME_*
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
   private static _str getFileSelectOption(_str langID, _str langPropName, _str flag, _str defaultValue,
                                           bool checkPlusMinus = false, bool tryGlobal = true)
   {
      value := '';

      // figure out what we're searching for
      ss := '[+|-]'flag'(:c):0,1( |$)';

      fileOptions := _LangGetProperty(langID, langPropName,'');
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
    * properties as strings that must be parsed. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param langPropName        Language property name 
    *                            VSLANGPROPNAME_*
    * @param flag                string to look for to determine the 
    *                            value of this option
    * @param value               string to insert into these options to 
    *                            specify a value
    */
   private static void setFileSelectOption(_str langID, _str langPropName, _str flag, _str value, _str defaultValue = '')
   {
      // get the existing option and modify it
      fileOptions := _LangGetProperty(langID, langPropName,'');

      // figure out what we're looking for
      ss := '[+|-]'flag'(:c):0,1( |$)';
      col := pos(ss, fileOptions, 1, 'R');

      // did we find it?
      if (col) {
         // yup, we gotta build a new string, so get what's before and after the option
         before := mid := after := "";
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
               fileOptions :+= ' ' :+ value :+ flag;
            } else {
               // or maybe it's another letter
               fileOptions :+= " +" :+ flag :+ value;
            }
         }
      }

      // finally, set the new option
      _LangSetProperty(langID, langPropName, strip(fileOptions));
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
   public static bool getLoadAsBinary(_str langID)
   {
      return (getFileOption(langID, VSLANGPROPNAME_LOAD_FILE_OPTIONS, 'LB') > 0);
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
   public static void setLoadAsBinary(_str langID, bool value)
   {
      setFileOption(langID, VSLANGPROPNAME_LOAD_FILE_OPTIONS, 'LB', (value == false) ? -1 : 1);
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
      return getFileOption(langID, VSLANGPROPNAME_LOAD_FILE_OPTIONS, 'E');
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
      setFileOption(langID, VSLANGPROPNAME_LOAD_FILE_OPTIONS, 'E', value);
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
   public static bool getSaveAsBinary(_str langID)
   {
      return (getFileOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'B') > 0);
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
   public static void setSaveAsBinary(_str langID, bool value)
   {
      setFileOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'B', (value == false) ? -1 : 1);
   }

   /**
    * Gets whether tabs are expanded to spaces when files in this language are
    * saved. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    *  
    * @return     ETO_OFF - do not expand tabs to spaces 
    *             ETO_EXPAND_ALL - expand all tabs
    *             ETO_EXPAND_MODIFIED - expand tabs to spaces only
    *             on modified or inserted lines
    *  
    * @categories LanguageSettings_API 
    */
   public static int getSaveExpandTabsToSpaces(_str langID)
   {
      value := 0;
      strValue := getFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'E', '', true, false);
      switch (strValue) {
      case '-':
         value = ETO_OFF;
         break;
      case '+':
         value = ETO_EXPAND_ALL;
         break;
      case 'M':
         value = ETO_EXPAND_MODIFIED;
         break;
      default:
         value = -1;
         break;
      }

      return value;
   }

   /**
    * Sets whether tabs are expanded to spaces when files in this language are
    * saved. This value is available on the File Options form for 
    * each applicable language. 
    * 
    * @param langID        language ID (see {@link p_LangId}) 
    * @param int value     ETO_OFF - do not expand tabs to spaces 
    *                      ETO_EXPAND_ALL - expand all tabs
    *                      ETO_EXPAND_MODIFIED - expand tabs to
    *                      spaces only on modified or inserted
    *                      lines
    *  
    * @categories LanguageSettings_API 
    */
   public static void setSaveExpandTabsToSpaces(_str langID, int value)
   {
      strValue := '';
      switch (value) {
      case ETO_OFF:
         strValue = '-';
         break;
      case ETO_EXPAND_ALL:
         strValue = '+';
         break;
      case ETO_EXPAND_MODIFIED:
         strValue = 'M';
         break;
      default:
         strValue = '';
         break;
      }

      setFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'E', strValue);
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
      strValue := getFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'S', '', true, false);
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

      setFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'S', strValue);
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
      return getFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'F', 'A');
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
      setFileSelectOption(langID, VSLANGPROPNAME_SAVE_FILE_OPTIONS, 'F', value, 'A');
   }

   /**
    * Gets whether we insert real indent for this language. This value is 
    * available on the GUI on the Indent form for each applicable language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    * 
    * @return                    whether we insert real indent for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getInsertRealIndent(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_REAL_INDENT, defaultValue);
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
   public static void setInsertRealIndent(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_REAL_INDENT, value);
   }

   /**
    * Retrieves whether or not we want to auto-case keywords for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    *  
    * @return                    whether to auto-case keywords in this language
    *  
    * @categories LanguageSettings_API 
    */
   public static bool getAutoCaseKeywords(_str langID, bool defaultValue = false)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_AUTO_CASE_KEYWORDS, defaultValue);
   }

   /**
    * Sets whether or not we want to auto-case keywords for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoCaseKeywords(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_AUTO_CASE_KEYWORDS, value);
   }

   /**
    * Retrieves the comment editing flags for this language.
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    *  
    * @return                    comment editing flags for this language
    *  
    * @categories LanguageSettings_API 
    */
   public static int getCommentEditingFlags(_str langID, int defaultValue = -3857)
   {
      return _LangGetPropertyInt32(langID, VSLANGPROPNAME_COMMENT_EDITING_FLAGS, defaultValue);
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
      _LangSetProperty(langID, VSLANGPROPNAME_COMMENT_EDITING_FLAGS, value);
   }

   /**
    * Gets the list of all tag files for this language, including inactive tag files. 
    * Each path is separated by PATHSEP.  May need to use _replace_envvars to get the full paths. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * 
    * @return                    list of tag files for this language, separated 
    *                            by PATHSEP
    */
   public static _str getTagFileListAll(_str langID)
   {
      return _plugin_get_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST_ALL,langID);
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
   public static void setTagFileListAll(_str langID, _str value, bool append = false)
   {
      // make sure we encode this guy
      orig_value := value;
      value = _encode_vsenvvars(value, true, false);

      if (append) {
         tagFiles := getTagFileListAll(langID);
         tagFiles = strip(tagFiles, 'B', PATHSEP);

         // make sure the new path isn't already in there
         if (pos(value, PATHSEP :+ tagFiles :+ PATHSEP)) return;
         if (pos(orig_value, PATHSEP :+ tagFiles :+ PATHSEP)) return;

         if (tagFiles != '') tagFiles :+= PATHSEP;
         value = tagFiles :+ value;
      }

      if (length(value) > 0) {
         _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST_ALL,VSCFGPROFILE_TAG_FILE_LIST_VERSION,langID,value);
      } else {
         _plugin_delete_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST_ALL,langID);
      }

      // This function does not call the tag file callbacks, becuase it deals
      // with inactive tag files, so a change here does not change anything
      // with respect to context tagging
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
      return _plugin_get_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST,langID);
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
   public static void setTagFileList(_str langID, _str value, bool append = false)
   {
      // make sure we encode this guy
      orig_value := value;
      value = _encode_vsenvvars(value, true, false);

      if (append) {
         tagFiles := getTagFileList(langID);
         tagFiles = strip(tagFiles, 'B', PATHSEP);

         // make sure the new path isn't already in there
         if (pos(value, PATHSEP :+ tagFiles :+ PATHSEP)) return;
         if (pos(orig_value, PATHSEP :+ tagFiles :+ PATHSEP)) return;

         if (tagFiles != '') tagFiles :+= PATHSEP;
         value = tagFiles :+ value;
      }

      if (length(value) > 0) {
         _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST,VSCFGPROFILE_TAG_FILE_LIST_VERSION,langID,value);
      } else {
         _plugin_delete_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST,langID);
      }

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
      handle:=_plugin_get_profile(VSCFGPACKAGE_MISC, VSCFGPROFILE_TAG_FILE_LIST);
      if (handle<0) return;
      profile_node:=_xmlcfg_get_first_child_element(handle);
      property_node:=_xmlcfg_get_first_child_element(handle,profile_node);
      while (property_node>=0) {
         langId:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
         value:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
         if (value!='') {
            table:[langId] = value;
         }
         property_node=_xmlcfg_get_next_sibling_element(handle,property_node);
      }
   }

   /**
    * Retrieves a hashtable of tag file lists, keyed by language.  Use this to 
    * go through all the language-specific tag file lists. 
    * 
    * @param table               table to be populated with values
    */
   public static void getTagFileListAllTable(_str (&table):[])
   {
      // first get the old-style tag file list
      getTagFileListTable(table);

      // then for languages that have the new setting, 
      // replace it with the all tag files setting
      handle:=_plugin_get_profile(VSCFGPACKAGE_MISC, VSCFGPROFILE_TAG_FILE_LIST_ALL);
      if (handle >= 0) {
         profile_node:=_xmlcfg_get_first_child_element(handle);
         property_node:=_xmlcfg_get_first_child_element(handle,profile_node);
         while (property_node>=0) {
            langId:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
            value:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
            if (value!="") {
               table:[langId] = value;
            }
            property_node=_xmlcfg_get_next_sibling_element(handle,property_node);
         }
      }
   }

   /**
    * 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    *  
    * @return                    
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoBracket(_str langID)
   {
      return(_LangGetPropertyInt32(langID, VSLANGPROPNAME_AUTO_BRACKET_FLAGS,0));
   }

   /**
    * Helper function to determine if specific feature is enabled.
    * 
    * @param langID 
    * @param flags 
    * 
    * @return bool
    */
   public static bool getAutoBracketEnabled(_str langID, int flags)
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
      _LangSetProperty(langID, VSLANGPROPNAME_AUTO_BRACKET_FLAGS, value);
   }

   /**
    * 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.
    *  
    * @return                    
    *  
    * @categories LanguageSettings_API 
    */
   public static int getAutoSurround(_str langID)
   {
      return(_LangGetPropertyInt32(langID, VSLANGPROPNAME_AUTO_SURROUND_FLAGS,0));
   }

   /**
    * 
    * 
    * @param langID              language ID (see {@link p_LangId}) 
    * @param value               new value
    *  
    * @categories LanguageSettings_API 
    */
   public static void setAutoSurround(_str langID, int value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_AUTO_SURROUND_FLAGS, value);
   }

   /**
    * Helper function to determine if specific feature is enabled.
    * 
    * @param langID 
    * @param flags 
    * 
    * @return bool
    */
   public static bool getAutoSurroundEnabled(_str langID, int flags)
   {
      sflags := LanguageSettings.getAutoSurround(langID);
      return ((sflags & AUTO_BRACKET_ENABLE) && (sflags & flags)); 
   }
   
   /**
    * Retrieves whether language-specific aliases should be automatically 
    * expanded on space for this language. 
    * 
    * @param langID              language ID (see {@link p_LangId})
    * 
    * @return bool               whether to expand language-specific aliases on 
    *                            space
    */
   public static bool getExpandAliasOnSpace(_str langID)
   {
      return _LangGetPropertyBool(langID, VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE,false);
   }

   /**
    * Sets whether language-specific aliases should be automatically 
    * expanded on space for this language.
    * 
    * @param langID              language ID (see {@link p_LangId})
    * @param value               whether to expand language-specific 
    *                            aliases on space
    */
   public static void setExpandAliasOnSpace(_str langID, bool value)
   {
      _LangSetProperty(langID, VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE, value);
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
      return _LangGetPropertyInt32(langId, VSLANGPROPNAME_AUTO_COMPLETE_POUND_INCLUDE,defaultValue);
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
      _LangSetProperty(langId, VSLANGPROPNAME_AUTO_COMPLETE_POUND_INCLUDE, value);
   }

   /**
    * Gets setting specifying how Auto-Complete looks for subword pattern matches.
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param defaultValue        value to use if no value is set
    * 
    * @return int 
    */
   public static AutoCompleteSubwordPattern getAutoCompleteSubwordPatternOption(_str langId, AutoCompleteSubwordPattern defaultValue=AUTO_COMPLETE_SUBWORD_MATCH_STSK_SUBWORD)
   {
      return (AutoCompleteSubwordPattern) _LangGetPropertyInt32(langId, VSLANGPROPNAME_AUTO_COMPLETE_SUBWORDS, defaultValue);
   }

   /**
    * Specify how Auto-Complete looks for subword pattern matches.
    * 
    * @param langId              language ID (see {@link p_LangId})
    * @param value               new value
    */
   public static void setAutoCompleteSubwordPatternOption(_str langId, AutoCompleteSubwordPattern value)
   {
      _LangSetProperty(langId, VSLANGPROPNAME_AUTO_COMPLETE_SUBWORDS, value);
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
      return 0;
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
   }

   /**
    * Retrieves the flags specifying the selective display options
    * for this language.
    *
    * @param langId              language ID (see {@link p_LangId})
    *
    * @return int                surround-with alias version
    */
   public static int getSelectiveDisplayFlags(_str langId)
   {
      return _LangGetPropertyInt32(langId, VSLANGPROPNAME_SELECTIVE_DISPLAY_FLAGS,0);
   }

   /**
    * Sets the flags specifying the selective display options for
    * this language.
    *
    * @param langId              language ID (see {@link p_LangId})
    * @param value               surround-with alias version
    */
   public static void setSelectiveDisplayFlags(_str langId, int value)
   {
      _LangSetProperty(langId, VSLANGPROPNAME_SELECTIVE_DISPLAY_FLAGS, value);
   }

   #endregion Language-Specific Def-Vars

   #region Defaults
   
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
      case LOI_INDENT_FIRST_LEVEL:
      case LOI_MULTILINE_IF_EXPANSION:
      case LOI_MAIN_STYLE:
      case LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS:
      case LOI_NO_SPACE_BEFORE_PAREN:
      case LOI_INSERT_BEGIN_END_IMMEDIATELY:
      case LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END:
      case LOI_DELPHI_EXPANSIONS:
      case LOI_QUOTE_NUMBER_VALUES:
      case LOI_QUOTE_WORD_VALUES:
      case LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS:
      case LOI_USE_COLOR_NAMES:
      case LOI_USE_DIV_TAGS_FOR_ALIGNMENT:
      case LOI_USE_PATHS_FOR_FILE_ENTRIES:
      case LOI_AUTO_INSERT_LABEL:
      case LOI_AUTO_VALIDATE_ON_OPEN:
      case LOI_AUTO_WELLFORMEDNESS_ON_OPEN:
      case LOI_RUBY_STYLE:
         useDefault = !isinteger(value);
         appDefault = 0;
         break;
      case LOI_BEGIN_END_COMMENTS:
      case LOI_AUTO_CORRELATE_START_END_TAGS:
      case LOI_AUTO_SYMBOL_TRANSLATION:
      case LOI_COBOL_SYNTAX:
         useDefault = !isinteger(value);
         appDefault = 1;
         break;
      case LOI_QUICK_BRACE:
         useDefault = !isinteger(value);
         appDefault = 1;
         break;
      case LOI_CUDDLE_ELSE:
         useDefault = !isinteger(value);
         appDefault = 1;
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
