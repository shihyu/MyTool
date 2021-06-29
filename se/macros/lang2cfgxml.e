/*
TODO 
   * _lang_doc_comments_enabled(). Better to check if there's a profile that isn't empty

   * need _lang_symboltrans_aliases_enabled(). Modify options.xml to export these.

   * How to know when property is supported and whether to allow a property to be set.

     COMMENT_WRAP_OPTIONS_DEF_VAR_KEY   commentwrap_isSupportedLanguage
 
*/


/*
TODO 

   * Work on create new language. make sure copy settings works and
     can set the properties.

   * _lang_doc_comments_enabled(). Better to check if there's a profile that isn't empty

   * need _lang_symboltrans_aliases_enabled(). Modify options.xml to export these.

   * How to know when property is supported and whether to allow a property to be set.

     COMMENT_WRAP_OPTIONS_DEF_VAR_KEY   commentwrap_isSupportedLanguage
 
*/

#pragma option(pedantic,on)
#include "slick.sh"
#import "stdprocs.e"
#import "cfg.e"
#import "autocomplete.e"
#import "box.e"
#import "se/color/SymbolColorAnalyzer.e"
#if __VERSION__>=21
#import "main.e"
#endif
#import "commentformat.e"
#import "setupext.e"
#import "listproc.e"
//#import "xmlwrap.e"
#import "optionsxml.e"
#import "codehelp.e"
#import "se/color/SymbolColorAnalyzer.e"


static const SPACE_HOLDER= -1;
static const BRACE_STYLE=  -2;

static const NEW_LOI_SYNTAX_INDENT='syntax_indent';
static const NEW_LOI_SYNTAX_EXPANSION='syntax_expansion';
static const NEW_LOI_MIN_ABBREVIATION='minimum_abbreviation';
static const NEW_LOI_INDENT_CASE_FROM_SWITCH='indent_case';
static const NEW_LOI_KEYWORD_CASE='wc_keyword';
static const NEW_LOI_BEGIN_END_COMMENTS='begin_end_comments';
static const NEW_LOI_INDENT_FIRST_LEVEL='indent_first_level';
static const NEW_LOI_MULTILINE_IF_EXPANSION='multi_line_if_expansion';
static const NEW_LOI_MAIN_STYLE='main_style';
static const NEW_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS='listalign_fun_call_params';
static const NEW_LOI_BEGIN_END_STYLE='begin_end_style';
static const NEW_LOI_PAD_PARENS='sppad_parens';
static const NEW_LOI_NO_SPACE_BEFORE_PAREN='no_space_before_paren';
static const NEW_LOI_POINTER_STYLE='pointer_style';
static const NEW_LOI_FUNCTION_BEGIN_ON_NEW_LINE='function_begin_on_new_line';
static const NEW_LOI_INSERT_BEGIN_END_IMMEDIATELY='insert_begin_end_immediately';
static const NEW_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END='insert_blank_line_between_begin_end';
static const NEW_LOI_QUICK_BRACE='quick_brace';
static const NEW_LOI_CUDDLE_ELSE='nl_before_else';
static const NEW_LOI_DELPHI_EXPANSIONS='delphi_expansions';              // pascal
static const NEW_LOI_TAG_CASE='wc_tag_name';
static const NEW_LOI_ATTRIBUTE_CASE='wc_attr_name';
static const NEW_LOI_WORD_VALUE_CASE='wc_attr_word_value';
static const NEW_LOI_HEX_VALUE_CASE='wc_attr_hex_value';
static const NEW_LOI_QUOTE_NUMBER_VALUES='quote_attr_number_value';
static const NEW_LOI_QUOTE_WORD_VALUES='quote_attr_word_value';
static const NEW_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS='lowercase_filenames_when_inserting_links';
static const NEW_LOI_USE_COLOR_NAMES='use_color_names';
static const NEW_LOI_USE_DIV_TAGS_FOR_ALIGNMENT='use_div_tags_for_alignment';
static const NEW_LOI_USE_PATHS_FOR_FILE_ENTRIES='use_paths_for_file_entries';
static const NEW_LOI_AUTO_VALIDATE_ON_OPEN='auto_validate_on_open';
static const NEW_LOI_AUTO_CORRELATE_START_END_TAGS='auto_correlate_start_end_tags';
static const NEW_LOI_AUTO_SYMBOL_TRANSLATION='auto_symbol_translation';
static const NEW_LOI_INSERT_RIGHT_ANGLE_BRACKET='insert_right_angle_bracket';     // deprecated
static const NEW_LOI_COBOL_SYNTAX='cobol_syntax';                   // cobol only
static const NEW_LOI_AUTO_INSERT_LABEL='auto_insert_label';              // vhdl only
static const NEW_LOI_RUBY_STYLE='ruby_style';                     // ruby only



static const ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY=         'adaptive-flags';
static const ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY=             'alias-expand';
static const AUTOBRACKET_VAR_KEY=                           'autobracket';
static const AUTOSURROUND_VAR_KEY=                          'autosurround';
static const AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY=           'autocompletemin';
static const AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY=              'autocomplete';
static const AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY=        'expand-include';
static const AUTO_CASE_KEYWORDS_DEF_VAR_KEY=                'autocase';
static const REFERENCED_IN_LANGUAGES_DEF_VAR_KEY=           'referenced-in';
static const CODEHELP_FLAGS_DEF_VAR_KEY=                    'codehelp';
static const COMMENT_EDITING_FLAGS_DEF_VAR_KEY=             'commentediting';
static const COMMENT_WRAP_OPTIONS_DEF_VAR_KEY=              'comment-wrap';
static const DOC_COMMENT_FLAGS_DEF_VAR_KEY=                 'doccomment';
static const INDENT_OPTIONS_DEF_VAR_KEY=                    'indent';
static const LOAD_FILE_OPTIONS_DEF_VAR_KEY=                 'load';
static const MENU_OPTIONS_DEF_VAR_KEY=                      'menu';
static const NUMBERING_STYLE_DEF_VAR_KEY=                   'numbering';
static const REAL_INDENT_DEF_VAR_KEY=                       'real-indent';
static const SAVE_FILE_OPTIONS_DEF_VAR_KEY=                 'save';
static const SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY=         'selective-display';
static const SMART_PASTE_DEF_VAR_KEY=                       'smartpaste';
static const SMART_TAB_DEF_VAR_KEY=                         'smarttab';
static const SURROUND_OPTIONS_DEF_VAR_KEY=                  'surround';
static const SURROUND_WITH_VERSION_DEF_VAR_KEY=             'surround-with-version';
static const SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY=           'symbolcoloring';
static const TAG_FILE_LIST_DEF_VAR_KEY=                     'tagfiles';
static const UPDATE_VERSION_DEF_VAR_KEY=                    'update-version';
static const USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY=           'adaptive-formatting';
static const XML_WRAP_OPTIONS_DEF_VAR_KEY=                  'xml-wrap';
static const BEAUTIFIER_PROFILE_DEF_VAR_KEY=                'beautifier-profile';
static const BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY=             'beautifier-expansions';
static const LANGUAGE_TAB_CYCLES_INDENTS=                   'tab-cycles-indents';
static const ONE_LINE_AUTOBRACES_DEF_VAR_KEY=               'one-line-brackets';
static const CODE_MARGINS_DEF_VAR_KEY=                      'code-margins';
static const DIFF_COLUMNS_DEF_VAR_KEY=                      'diff-columns';


enum OldLanguageOptionItems {
   OLD_LOI_SYNTAX_INDENT,
   OLD_LOI_SYNTAX_EXPANSION,
   OLD_LOI_MIN_ABBREVIATION,
   OLD_LOI_INDENT_CASE_FROM_SWITCH,
   OLD_LOI_KEYWORD_CASE,
   OLD_LOI_BEGIN_END_COMMENTS,
   OLD_LOI_INDENT_FIRST_LEVEL,
   OLD_LOI_MULTILINE_IF_EXPANSION,
   OLD_LOI_MAIN_STYLE,
   OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS,
   OLD_LOI_BEGIN_END_STYLE,
   OLD_LOI_PAD_PARENS,
   OLD_LOI_NO_SPACE_BEFORE_PAREN,
   OLD_LOI_POINTER_STYLE,
   OLD_LOI_FUNCTION_BEGIN_ON_NEW_LINE,
   OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY,
   OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END,
   OLD_LOI_QUICK_BRACE,
   OLD_LOI_CUDDLE_ELSE,
   OLD_LOI_DELPHI_EXPANSIONS,              // pascal
   OLD_LOI_TAG_CASE,
   OLD_LOI_ATTRIBUTE_CASE,
   OLD_LOI_WORD_VALUE_CASE,
   OLD_LOI_HEX_VALUE_CASE,
   OLD_LOI_QUOTE_NUMBER_VALUES,
   OLD_LOI_QUOTE_WORD_VALUES,
   OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS,
   OLD_LOI_USE_COLOR_NAMES,
   OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT,
   OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES,
   OLD_LOI_AUTO_VALIDATE_ON_OPEN,
   OLD_LOI_AUTO_CORRELATE_START_END_TAGS,
   OLD_LOI_AUTO_SYMBOL_TRANSLATION,
   OLD_LOI_INSERT_RIGHT_ANGLE_BRACKET,     // deprecated
   OLD_LOI_COBOL_SYNTAX,                   // cobol only
   OLD_LOI_AUTO_INSERT_LABEL,              // vhdl only
   OLD_LOI_RUBY_STYLE,                     // ruby only

};
static const OLD_BEGIN_END_STYLE_FIRST=       OLD_LOI_BEGIN_END_STYLE;
static const OLD_BEGIN_END_STYLE_LAST=        OLD_LOI_DELPHI_EXPANSIONS;
   /***********************************************************
    * 0. OLD_LOI_SYNTAX_INDENT                                    *
    * 1. OLD_LOI_SYNTAX_EXPANSION                                 *
    * 2. OLD_LOI_MIN_ABBREVIATION                                 *
    * 3. OLD_LOI_KEYWORD_CASE                                     *
    * 4. begin/end style                                      *
    * 5. OLD_LOI_INDENT_FIRST_LEVEL                               *  
    * 6. OLD_LOI_MAIN_STYLE                                       *
    * 7. OLD_LOI_INDENT_CASE_FROM_SWITCH                          *
    * 8. OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS   *
    **********************************************************/ 
   static int s_defaultLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_KEYWORD_CASE, BRACE_STYLE, OLD_LOI_INDENT_FIRST_LEVEL, OLD_LOI_MAIN_STYLE, OLD_LOI_INDENT_CASE_FROM_SWITCH,
      OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS };

      /*******************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                *
       * 1. OLD_LOI_SYNTAX_EXPANSION                             *
       * 2. OLD_LOI_TAG_CASE                                     *
       * 3. OLD_LOI_ATTRIBUTE_CASE                               *
       * 4. OLD_LOI_WORD_VALUE_CASE                              *
       * 5. OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS     *
       * 6. OLD_LOI_QUOTE_NUMBER_VALUES                    *
       * 7. OLD_LOI_QUOTE_WORD_VALUES                *
       * 8. OLD_LOI_USE_COLOR_NAMES                              *
       * 9.  OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT                  *
       * 10. OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES                  *
       * 11. OLD_LOI_HEX_VALUE_CASE                              *
       * 12. OLD_LOI_AUTO_SYMBOL_TRANSLATION                     *
       * 13. OLD_LOI_INSERT_RIGHT_ANGLE_BRACKET                  *
       * 14. temps[0]                                        *
       ******************************************************/
   static int s_htmlLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_TAG_CASE, OLD_LOI_ATTRIBUTE_CASE,
      OLD_LOI_WORD_VALUE_CASE, OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS, OLD_LOI_QUOTE_NUMBER_VALUES, 
      OLD_LOI_QUOTE_WORD_VALUES, OLD_LOI_USE_COLOR_NAMES, OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT, OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES,
      OLD_LOI_HEX_VALUE_CASE, OLD_LOI_AUTO_SYMBOL_TRANSLATION, OLD_LOI_INSERT_RIGHT_ANGLE_BRACKET };                                   

      /*******************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                *
       * 1. OLD_LOI_SYNTAX_EXPANSION                             *
       * 2. OLD_LOI_TAG_CASE                                     *
       * 3. OLD_LOI_ATTRIBUTE_CASE                               *
       * 4. OLD_LOI_WORD_VALUE_CASE                              *  
       * 5. temps[0]                                         *
       * 6. OLD_LOI_QUOTE_NUMBER_VALUES                    *                        
       * 7. OLD_LOI_QUOTE_WORD_VALUES                *                                
       * 8. temps[1]                                         *
       * 9.  temps[2]                                        *
       * 10. temps[3]                                        *
       * 11. OLD_LOI_HEX_VALUE_CASE                              *
       * 12. OLD_LOI_AUTO_VALIDATE_ON_OPEN                       *
       * 13. OLD_LOI_AUTO_CORRELATE_START_END_TAGS               *
       * 14. OLD_LOI_AUTO_SYMBOL_TRANSLATION                     *
       ******************************************************/ 
   static int s_xmlLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_TAG_CASE, OLD_LOI_ATTRIBUTE_CASE,
      OLD_LOI_WORD_VALUE_CASE, SPACE_HOLDER, OLD_LOI_QUOTE_NUMBER_VALUES, OLD_LOI_QUOTE_WORD_VALUES, 
      SPACE_HOLDER, SPACE_HOLDER, SPACE_HOLDER, OLD_LOI_HEX_VALUE_CASE, OLD_LOI_AUTO_VALIDATE_ON_OPEN, 
      OLD_LOI_AUTO_CORRELATE_START_END_TAGS, OLD_LOI_AUTO_SYMBOL_TRANSLATION };                                   

      /*******************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                *
       * 1. OLD_LOI_SYNTAX_EXPANSION                             *
       * 2. OLD_LOI_MIN_ABBREVIATION                             *
       * 3. OLD_LOI_KEYWORD_CASE                                 *
       * 4. begin/end style                                  *
       * 5. OLD_LOI_BEGIN_END_COMMENTS                           *  
       * 6. OLD_LOI_INDENT_CASE_FROM_SWITCH                      *                        
       ******************************************************/ 
   static int s_pasLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_KEYWORD_CASE, BRACE_STYLE, OLD_LOI_BEGIN_END_COMMENTS, OLD_LOI_INDENT_CASE_FROM_SWITCH };

      /***********************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                    *
       * 1. OLD_LOI_SYNTAX_EXPANSION                                 *
       * 2. OLD_LOI_MIN_ABBREVIATION                                 *
       * 3. OLD_LOI_KEYWORD_CASE                                     *
       * 4. temps[0]                                             *  
       * 5. temps[1]                                             *
       * 6. OLD_LOI_MULTILINE_IF_EXPANSION                           *
       * 7. temps[2]                                             *
       **********************************************************/ 
   static int s_forLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_KEYWORD_CASE, SPACE_HOLDER, SPACE_HOLDER, OLD_LOI_MULTILINE_IF_EXPANSION };

      /***********************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                    *
       * 1. OLD_LOI_SYNTAX_EXPANSION                                 *
       * 2. OLD_LOI_MIN_ABBREVIATION                                 *
       * 3. OLD_LOI_KEYWORD_CASE                                     *
       * 4. temps[0]                                             *  
       * 5. OLD_LOI_COBOL_SYNTAX                                     *
       **********************************************************/ 
   static int s_cobLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_KEYWORD_CASE, SPACE_HOLDER, OLD_LOI_COBOL_SYNTAX };

      /*******************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                *
       * 1. OLD_LOI_SYNTAX_EXPANSION                             *
       * 2. OLD_LOI_MIN_ABBREVIATION                             *
       * 3. OLD_LOI_KEYWORD_CASE                                 *
       * 4. begin/end style                                  *
       * 5. OLD_LOI_AUTO_INSERT_LABEL                            *                        
       ******************************************************/ 
   static int s_vhdLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_KEYWORD_CASE, BRACE_STYLE, OLD_LOI_AUTO_INSERT_LABEL };

      /***********************************************************
       * 0. OLD_LOI_SYNTAX_INDENT                                    *
       * 1. OLD_LOI_SYNTAX_EXPANSION                                 *
       * 2. OLD_LOI_MIN_ABBREVIATION                                 *
       * 3. OLD_LOI_RUBY_STYLE                                       *
       * 4. begin/end style                                      *
       * 5. OLD_LOI_INDENT_FIRST_LEVEL                               *
       * 6. OLD_LOI_MAIN_STYLE                                       *
       * 7. OLD_LOI_INDENT_CASE_FROM_SWITCH                          *
       * 8. OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS   *
       **********************************************************/ 
   static int s_rubyLangDefinition[] = { OLD_LOI_SYNTAX_INDENT, OLD_LOI_SYNTAX_EXPANSION, OLD_LOI_MIN_ABBREVIATION,                              
      OLD_LOI_RUBY_STYLE, BRACE_STYLE, OLD_LOI_INDENT_FIRST_LEVEL, OLD_LOI_MAIN_STYLE, OLD_LOI_INDENT_CASE_FROM_SWITCH,
      OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS };                               

static bool doesOptionApplyToLanguage(_str langID, int option) {
   // first, make sure this language even has a def-options value
   if (find_index('def-options-'langID, MISC_TYPE) <= 0) return false;

   return isOptionInParseMap(langID, option);
}
static bool isBeginEndStyleItem(int item) {
   return (item >= OLD_BEGIN_END_STYLE_FIRST && item <= OLD_BEGIN_END_STYLE_LAST);
}
static bool isOptionInParseMap(_str langID, int option) {
   int parseMap[];
   getLanguageOptionsParseMap(langID, parseMap);

   if (isBeginEndStyleItem(option)) option = BRACE_STYLE;

   foreach (auto parseOption in parseMap) {
      if (parseOption == option) return true;
   }

   return false;
}
static void getLanguageOptionsParseMap(_str langID, int (&langDefinition)[]) {
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
static void getBeginEndStyleItems(int braceStyle, typeless (&options)[])
{
   if (!isinteger(braceStyle)) {
      // set them all equal to '' so that their individual default values will kick in
      options[OLD_LOI_BEGIN_END_STYLE] = options[OLD_LOI_PAD_PARENS] = options[OLD_LOI_NO_SPACE_BEFORE_PAREN] = 
         options[OLD_LOI_POINTER_STYLE] = options[OLD_LOI_FUNCTION_BEGIN_ON_NEW_LINE] = 
         options[OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY] = options[OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END] = 
         options[OLD_LOI_QUICK_BRACE] = options[OLD_LOI_CUDDLE_ELSE] = '';
   } else {

      // begin/end style
      options[OLD_LOI_BEGIN_END_STYLE] = (braceStyle & (BES_BEGIN_END_STYLE_1 | BES_BEGIN_END_STYLE_2 | BES_BEGIN_END_STYLE_3));

      // pad parens
      options[OLD_LOI_PAD_PARENS] = (braceStyle & BES_PAD_PARENS);

      // space before paren
      options[OLD_LOI_NO_SPACE_BEFORE_PAREN] = (braceStyle & BES_NO_SPACE_BEFORE_PAREN);

      // pointer style
      options[OLD_LOI_POINTER_STYLE] = (braceStyle & (BES_SPACE_AFTER_POINTER | BES_SPACE_SURROUNDS_POINTER));

      // function brace on new line
      options[OLD_LOI_FUNCTION_BEGIN_ON_NEW_LINE] = (braceStyle & BES_FUNCTION_BEGIN_ON_NEW_LINE);

      // insert braces immediately
      options[OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY] = (braceStyle & BES_INSERT_BEGIN_END_IMMEDIATELY);

      // insert blank line between braces
      options[OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END] = (braceStyle & BES_INSERT_BLANK_LINE_BETWEEN_BEGIN_END);

      // quick brace
      options[OLD_LOI_QUICK_BRACE] = (braceStyle & BES_NO_QUICK_BRACE_UNBRACE);

      // cuddle else
      options[OLD_LOI_CUDDLE_ELSE] = (braceStyle & BES_ELSE_ON_LINE_AFTER_BRACE);

      // delphi expansions - only used by pascal
      options[OLD_LOI_DELPHI_EXPANSIONS] = (braceStyle & BES_DELPHI_EXPANSIONS);
   }
}
static int getLanguageOptions(_str langID, int (&parseMap)[], typeless (&options)[], typeless (&temps)[])
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

   return optionsIndex;
}
static void maybeUseLanguageOptionItemDefault(_str langID, int item, typeless &value, typeless userDefault = null)
{
   if (value == null) value = '';

   typeless appDefault; 
   useDefault := false;
   
   switch (item) {
   case OLD_LOI_INDENT_FIRST_LEVEL:
   case OLD_LOI_MULTILINE_IF_EXPANSION:
   case OLD_LOI_MAIN_STYLE:
   case OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS:
   case OLD_LOI_NO_SPACE_BEFORE_PAREN:
   case OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY:
   case OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END:
   case OLD_LOI_DELPHI_EXPANSIONS:
   case OLD_LOI_QUOTE_NUMBER_VALUES:
   case OLD_LOI_QUOTE_WORD_VALUES:
   case OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS:
   case OLD_LOI_USE_COLOR_NAMES:
   case OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT:
   case OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES:
   case OLD_LOI_AUTO_INSERT_LABEL:
   case OLD_LOI_AUTO_VALIDATE_ON_OPEN:
   case OLD_LOI_RUBY_STYLE:
      useDefault = !isinteger(value);
      appDefault = 0;
      break;
   case OLD_LOI_BEGIN_END_COMMENTS:
   case OLD_LOI_AUTO_CORRELATE_START_END_TAGS:
   case OLD_LOI_AUTO_SYMBOL_TRANSLATION:
   case OLD_LOI_COBOL_SYNTAX:
      useDefault = !isinteger(value);
      appDefault = 1;
      break;
   case OLD_LOI_QUICK_BRACE:
      useDefault = !isinteger(value);
      appDefault = BES_NO_QUICK_BRACE_UNBRACE;
      break;
   case OLD_LOI_CUDDLE_ELSE:
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
static typeless getLanguageOptionItem(_str langID, int item, typeless defaultValue) {
   typeless options[];
   typeless temps[];
   int parseMap[];
   getLanguageOptionsParseMap(langID, parseMap);

   value := null;
   if (getLanguageOptions(langID, parseMap, options, temps) > 0) {
      value = options[item];
   }

   maybeUseLanguageOptionItemDefault(langID, item, value, defaultValue);

   return value;
}

static _str getDefVar(_str defVar, typeless defaultValue = null)
{
   // find our guy in the names table
   index := find_index(defVar, MISC_TYPE);

   if (index) {
      // it's there, so just return it
      return name_info(index);
   } else {
      // it is not there, so return a default value
      return defaultValue;
   }
}
static _str getDefVarName(_str id, _str defVarKey) {
   switch (defVarKey) {
   case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
   case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
   case 'include':
      // why is this one different?  one of life's great mysteries
      return('def-'id'-'defVarKey);
      break;
   default:
      // yup, it really is that simple
      return('def-'defVarKey'-'id);
      break;
   }

}
static _str getDefaultDefVarValue(_str defVarKey, _str langID)
{
   typeless defaultValue;

   switch (defVarKey) {
   case ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY:
      defaultValue = def_adaptive_formatting_flags;
      break;
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

      // do not insert parens for cobol
      if (langID == 'cob' || langID == 'cob74' || langID == 'cob2000') {
         defaultValue &= ~VSCODEHELPFLAG_INSERT_OPEN_PAREN;
      }
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
      defaultValue = '0 1 0 1 1 64 0 0 80 0 80 0 80 0 0 1';
      break;
   //case DOC_COMMENT_FLAGS_DEF_VAR_KEY:
   //   defaultValue = def_default_doc_comment_flags;
   //   break;
   case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
      defaultValue = AC_POUND_INCLUDE_NONE;
      break;
   case INDENT_OPTIONS_DEF_VAR_KEY:
      defaultValue = false;
      if (_LanguageInheritsFrom('py', langID)) {
         defaultValue = true;
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
      {
         index:=find_index('def_smarttab',VAR_TYPE);
         if (!index) {
            defaultValue=2;
         } else {
            defaultValue = _get_var(index);
            if (!isinteger(defaultValue)) {
               defaultValue=2;
            }
         }
      }
      break;
   case SURROUND_OPTIONS_DEF_VAR_KEY:
      {
         index:=find_index('def_surround_mode_options',VAR_TYPE);
         if (!index) {
            defaultValue=0xFFFF;
         } else {
            defaultValue = _get_var(index);
            if (!isinteger(defaultValue)) {
               defaultValue=0xFFFF;
            }
         }
      }
      break;
   case SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY:
      defaultValue = SYMBOL_COLOR_BOLD_DEFINITIONS |
                     SYMBOL_COLOR_SHOW_NO_ERRORS   |
                     SYMBOL_COLOR_DISABLED;
      break;
   case USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY:
      defaultValue = def_adaptive_formatting_on;
      break;
   /*case XML_WRAP_OPTIONS_DEF_VAR_KEY:
      if (langID == 'docbook') {
         defaultValue = '1 1 'XW_NODEFAULTSCHEME;
      } else {
         defaultValue = '0 0 'XW_NODEFAULTSCHEME;;
      }
      break;*/

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
            defaultValue = AUTO_BRACKET_DEFAULT & ~AUTO_BRACKET_SINGLE_QUOTE;
            break;
         case 'c':
         case 'ansic':
            defaultValue = AUTO_BRACKET_DEFAULT_C_STYLE;
            break;
         case 'html':
         case 'cfml':
         case 'xml':
         case 'markdown':
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

   case AUTOSURROUND_VAR_KEY:
      {
         switch (langID) {
         case 'vbs':
            // disable single quote for vbscript
            defaultValue = AUTO_BRACKET_DEFAULT & ~AUTO_BRACKET_SINGLE_QUOTE;
            break;
         case 'c':
         case 'ansic':
            defaultValue = AUTO_BRACKET_DEFAULT_C_STYLE;
            break;
         case 'html':
         case 'cfml':
         case 'xml':
         case 'markdown':
            defaultValue = AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT_HTML_STYLE;
            break;
         default:
            defaultValue = AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT;
            break;
         }
      }
      break;


   case DIFF_COLUMNS_DEF_VAR_KEY:
   case SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY:
   case UPDATE_VERSION_DEF_VAR_KEY:
      defaultValue = '0';
      break;
   case CODE_MARGINS_DEF_VAR_KEY:
      if (_LanguageInheritsFrom('pl1', langID)) {
         defaultValue = '2 72';
      } else {
         defaultValue = '';
      }
      break;
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
static _str getLanguageDefVar(_str langID, _str defVarKey,bool fetchDefaultValue=false/*, _str defaultValue = null*/) {
   defVarName := getDefVarName(langID, defVarKey);
   typeless result = getDefVar(defVarName, null);
   if (result._isempty()) {
      if (fetchDefaultValue) {
         return getDefaultDefVarValue(defVarKey, langID);
      }
      //say('default defVarKey='defVarKey);
      return result;
      //return getDefaultDefVarValue(defVarKey, langID);
   }
   return result;
}
static void convert_int_xmlcfg_property(_str langId,_str defVarKey,_str (&properties):[],_str propName,bool fetchDefaultValue=true) {
   value:=getLanguageDefVar(langId, defVarKey,fetchDefaultValue);
   if (isinteger(value)) {
      properties:[propName] = value;
   }
}
static _str getDefaultWordChars(_str pszLangId)
{
   if (_LanguageInheritsFrom("xml", pszLangId)) {
      return "\\p{isXMLNameChar}?!";
   } else {
      return "A-Za-z0-9_$";
   }
}

static void convert_str_xmlcfg_property(_str langId,_str defVarKey,_str (&properties):[],_str propName,bool warn_if_not_set=false) {
   if (langId=='pl1' && propName==VSLANGPROPNAME_CODE_MARGINS) {
      value:='2 72';
      properties:[propName] = value;
      return;
   }
   value:=getLanguageDefVar(langId, defVarKey,true);
   if (propName=='tag_file_list') {
      if (value!=null && value!='') {
         _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST,VSCFGPROFILE_TAG_FILE_LIST_VERSION,langId,value);
      }
      return;
   }
   if (value!=null && value!='' && propName==VSLANGPROPNAME_REFERENCED_IN_LANGIDS) {
      if (!_LangIsDefined('s')) {
         parse ' 'value' ' with auto before ' s 'auto after;
         value=strip(before)' 'strip(after);
      }
      if (!_LangIsDefined('asm')) {
         parse ' 'value' ' with auto before ' asm 'auto after;
         value=strip(before)' 'strip(after);
      }
      value=strip(value);
   }
   if (value!=null && value!='') {
      properties:[propName] = value;
   } else {
      value='';
      switch (propName) {
      case VSLANGPROPNAME_WORD_CHARS:
         value=getDefaultWordChars(langId);
         break;
         //say('WARNING word_chars are blank for 'langId);
         //return;
      case VSLANGPROPNAME_TABS:
         value="+4";
         break;
         //say('WARNING tabs are blank for 'langId);
         //return;
      case VSLANGPROPNAME_MARGINS:
         value="1 74 1";
         break;
         //say('WARNING margins are blank for 'langId);
         //return;
      case VSLANGPROPNAME_BOUNDS:
         value="0 0";
         break;
         //say('WARNING bounds is blank for 'langId);
         //return;
      }
      //say('default: 'propName' lang='langId' not set');
      properties:[propName] = value;
      //say('warning 'defVarKey' lang='langId' not set');
   }
}
static bool has_beautifier_profiles(_str langId) {
   return pos(langId, " c m java cs js xml xhtml phpscript html docbook vbs cfml vpj xsd ant android py systemverilog verilog ")!=0;
}
#if __VERSION__<21
enum_flags CWFLAGS {
   CWFLAG_ENABLE_COMMENT_WRAP=0x1,
   CWFLAG_ENABLE_DOC_COMMENT_WRAP=0x2,
   CWFLAG_ENABLE_BLOCK_COMMENT_WRAP=0x4,
   CWFLAG_ENABLE_LINE_COMMENT_WRAP=0x8,
   CWFLAG_PRESERVE_WIDTH_ON_EXISTING_COMMENT=0x10,
   CWFLAG_CONTINUE_BULLET_LIST_ON_ENTER=0x20,
   CWFLAG_JAVADOC_HANGING_INDENT_ON_BLOCK_TAG=0x40,
   CWFLAG_ENABLE_FIXED_WIDTH_MAX_RIGHT_COLUMN=0x80,
   CWFLAG_ENABLE_AUTOMATIC_WIDTH_MAX_RIGHT_COLUMN=0x100,
   CWFLAG_DEFAULTS=CWFLAG_ENABLE_COMMENT_WRAP|CWFLAG_ENABLE_DOC_COMMENT_WRAP|CWFLAG_JAVADOC_HANGING_INDENT_ON_BLOCK_TAG
};
enum CWSTYLE {
   CWSTYLE_FIXED_WIDTH=0,
   CWSTYLE_AUTOMATIC_WIDTH=1,
   CWSTYLE_FIXED_RIGHT_MARGIN=2,
};
#endif
static void maybe_convert_comment_wrap_options(_str langId,_str (&properties):[]) {
/* 
 
  _GetCommentWrapFlags, _SetCommentWrapFlags
  getCommentWrapOptions, setCommentWrapOptions
 
   cw_flags
         enable_comment_wrap=1      (enable_commentwrap)
         enable_doc_comment_wrap=1     (enable_javadoc)
         enable_block_comment_wrap==0  (enable_block)
         enable_line_comment_wrap=0 (enable_lineblock)
         preserve_width_on_existing_comments=0   (use_auto_override)
         continue_bullet_list_on_enter=0 (match_prev_para)
         javadoc_hanging_indent_on_block_tag_comments=1   (javadoc_auto_indent)
         enable_fixed_width_max_right_column=0   (max_right)
         enable_automatic_width_max_right_column=0  (max_right_dyn)
   cw_style=0   //comment_width_style= 0 -fixed_width 1- automatic_width 2-fixed_right_margin
 
   cw_line_comment_min=2
   cw_fixed_width_size=64
   cw_fixed_width_max_right_column=80
   cw_fixed_right_column=80
   cw_automatic_width_max_right_column=80
 
*/
   if (!commentwrap_isSupportedLanguage(langId)) {
      return;
   }
   //_GetCommentWrapFlags2(lang);
   _str CommentWrapSettings = getLanguageDefVar(langId, COMMENT_WRAP_OPTIONS_DEF_VAR_KEY,true);
   parse CommentWrapSettings with auto enable_block auto enable_javadoc auto preserve_width_on_existing_comments auto javadoc_auto_indent auto use_fixed_width auto fixed_width_size auto use_first_para auto use_fixed_margins auto fixed_right_column auto use_fixed_width_max_right_column auto fixed_width_max_right_column auto use_automatic_width_max_right_column auto automatic_width_max_right_column auto continue_bullet_list_on_enter auto enable_lineblock auto enable_commentwrap auto line_comment_min .;
   int cw_flags=CWFLAG_DEFAULTS;
   if (isinteger(enable_commentwrap)) {
      if ((int)enable_commentwrap) {
         cw_flags|=CWFLAG_ENABLE_COMMENT_WRAP;
      } else {
         cw_flags&=~CWFLAG_ENABLE_COMMENT_WRAP;
      }
   }
   if (isinteger(enable_javadoc)) {
      if ((int)enable_javadoc) {
         cw_flags|=CWFLAG_ENABLE_DOC_COMMENT_WRAP;
      } else {
         cw_flags&=~CWFLAG_ENABLE_DOC_COMMENT_WRAP;
      }
   }
   if (isinteger(enable_block)) {
      if ((int)enable_block) {
         cw_flags|=CWFLAG_ENABLE_BLOCK_COMMENT_WRAP;
      } else {
         cw_flags&=~CWFLAG_ENABLE_BLOCK_COMMENT_WRAP;
      }
   }
   if (isinteger(enable_lineblock)) {
      if ((int)enable_lineblock) {
         cw_flags|=CWFLAG_ENABLE_LINE_COMMENT_WRAP;
      } else {
         cw_flags&=~CWFLAG_ENABLE_LINE_COMMENT_WRAP;
      }
   }
   if (isinteger(preserve_width_on_existing_comments)) {
      if ((int)preserve_width_on_existing_comments) {
         cw_flags|=CWFLAG_PRESERVE_WIDTH_ON_EXISTING_COMMENT;
      } else {
         cw_flags&=~CWFLAG_PRESERVE_WIDTH_ON_EXISTING_COMMENT;
      }
   }
   if (isinteger(continue_bullet_list_on_enter)) {
      if ((int)continue_bullet_list_on_enter) {
         cw_flags|=CWFLAG_CONTINUE_BULLET_LIST_ON_ENTER;
      } else {
         cw_flags&=~CWFLAG_CONTINUE_BULLET_LIST_ON_ENTER;
      }
   }
   if (isinteger(javadoc_auto_indent)) {
      if ((int)javadoc_auto_indent) {
         cw_flags|=CWFLAG_JAVADOC_HANGING_INDENT_ON_BLOCK_TAG;
      } else {
         cw_flags&=~CWFLAG_JAVADOC_HANGING_INDENT_ON_BLOCK_TAG;
      }
   }
   if (use_fixed_width_max_right_column!=0 && isinteger(fixed_width_max_right_column)) {
      if ((int)fixed_width_max_right_column) {
         cw_flags|=CWFLAG_ENABLE_FIXED_WIDTH_MAX_RIGHT_COLUMN;
      } else {
         cw_flags&=~CWFLAG_ENABLE_FIXED_WIDTH_MAX_RIGHT_COLUMN;
      }
   }
   if (use_automatic_width_max_right_column!=0 && isinteger(automatic_width_max_right_column)) {
      if ((int)automatic_width_max_right_column) {
         cw_flags|=CWFLAG_ENABLE_AUTOMATIC_WIDTH_MAX_RIGHT_COLUMN;
      } else {
         cw_flags&=~CWFLAG_ENABLE_AUTOMATIC_WIDTH_MAX_RIGHT_COLUMN;
      }
   }
   
   if (!isinteger(line_comment_min)) line_comment_min=2;
   if (!isinteger(fixed_width_size)) fixed_width_size=64;
   if (!isinteger(fixed_width_max_right_column)) fixed_width_max_right_column=80;
   if (!isinteger(fixed_right_column)) fixed_right_column=80;
   if (!isinteger(automatic_width_max_right_column)) automatic_width_max_right_column=80;
   int cw_style;
   if (isinteger(use_fixed_width) && use_fixed_width!=0) {
      cw_style= CWSTYLE_FIXED_WIDTH;
   } else if (isinteger(use_first_para) && use_first_para!=0) {
      cw_style=CWSTYLE_AUTOMATIC_WIDTH;
   } else if (isinteger(use_fixed_margins) && use_fixed_margins!=0) {
      cw_style=CWSTYLE_FIXED_RIGHT_MARGIN;
   }
   //_GetCommentWrapFlags,_SetCommentWrapFlags
   properties:[VSLANGPROPNAME_CW_FLAGS]=cw_flags;
   properties:[VSLANGPROPNAME_CW_STYLE]=cw_style;
   properties:[VSLANGPROPNAME_CW_LINE_COMMENT_MIN]=line_comment_min;
   properties:[VSLANGPROPNAME_CW_FIXED_WIDTH_SIZE]=fixed_width_size;
   properties:[VSLANGPROPNAME_CW_FIXED_WIDTH_MAX_RIGHT_COLUMN]=fixed_width_max_right_column;
   properties:[VSLANGPROPNAME_CW_FIXED_RIGHT_COLUMN]=fixed_right_column;
   properties:[VSLANGPROPNAME_CW_AUTOMATIC_WIDTH_MAX_RIGHT_COLUMN]=automatic_width_max_right_column;
}
static void maybe_convert_doc_comments(_str langId,_str (&properties):[]) {
   return;
#if 0
   if (!_lang_doc_comments_enabled_v20(langId)) {
      return;
   }
   /* 
    
      doc_comment_flags -- Not used any more.
    
      Need to generate doc aliases
        language.<langId>.doc_aliases

      if convert2cfgxml has already been run, old_getCWaliasFile returns ''
   */ 
   alias_filename:=old_getCWaliasFile(langId);
   if (alias_filename=='') {
      // NOTE: if convert2cfgxml has already been run, old_getCWaliasFile returns ''
      return;
   }
   _convert_alias_file_to_v21_profile(alias_filename,vsCfgPackage_for_Lang(langId),VSCFGPROFILE_DOC_ALIASES);
#endif
}
static void convert_comment_settings(_str langId,_str (&properties):[]) {
   /* 
      comment_editing_flags
    
      comment_tlc..
      comment_first_line_is_top
      comment_last_line_is_top
      line_comment_left
      line_comment_right
      line_comment_style= 0-LEFT_MARGIN or 1-LEVEL_OF_INDENT or 2-START_AT_COLUMN
      line_comment_start_col
      
   */ 
   //BlockCommentSettings settings:[];
   //BlockCommentSettings commentSettings;
   //_str lang = CW_p_LangId;
   //if (getCommentSettings( lang, settings, 'b')) {
}
/*static void maybe_convert_xml_wrap_options(_str langId,_str (&properties):[]) {
   if (!XW_isSupportedLanguage(langId)) {
      return;
   }
   _str xmlWrapSettings = getLanguageDefVar(langId, XML_WRAP_OPTIONS_DEF_VAR_KEY,true);
   parse xmlWrapSettings with auto enable_CW auto enable_TL auto xw_profile .;
   if (!isinteger(enable_CW)) enable_CW = '0';
   if (!isinteger(enable_TL)) enable_TL = '0';
   if (xw_profile == "") xw_profile = XW_NODEFAULTSCHEME;

   xw_flags := 0;
   if (enable_CW!=0) xw_flags|=XWFLAG_ENABLE_CONTENT_WRAP;
   if (enable_TL!=0) xw_flags|=XWFLAG_ENABLE_TAG_LAYOUT;
   properties:[VSLANGPROPNAME_XW_FLAGS]=xw_flags;
   if (xw_profile==XW_NODEFAULTSCHEME) {
      xw_profile='';
   }
   properties:[VSLANGPROPNAME_XW_PROFILE]=xw_profile;
   //_GetXMLWrapFlags, _SetXMLWrapFlags

} */


#if __VERSION__>=21
static bool _beautifier_is_supported(_str langId) {
   profileName:=_LangGetProperty(langId,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
   return (profileName!='');
}
#endif
static void convertLangToXml(_str langId,int index=0) {
   if (index<=0) {
      index=find_index('def-language-'langId,MISC_TYPE);
      if (index<0) {
         return;
      }
   }
   _str info=name_info(index);
   if (info=='') {
      return;
   }
   if (substr(info,1,1)=='@' || !pos('=',info)) {
      // Not sure what's going on here. just delete it.
      return;
   }
   //say('info='info);
   //return;
#if 0
   // def-setup-s,vsm,fundamental,qth
   index=name_match('def-language-',1,MISC_TYPE);
   while (index>0) {
      say('n='name_name(index)' 'name_info(index));

      index=name_match('def-language-',0,MISC_TYPE);
   }
#endif
   _str properties:[];
   // set some defaults in case we don't have settings for everything
   properties:[VSLANGPROPNAME_AUTO_CAPS]=0;
   properties:[VSLANGPROPNAME_AUTO_LEFT_MARGIN]=0;
   properties:[VSLANGPROPNAME_BEGIN_END_PAIRS]='';
   properties:[VSLANGPROPNAME_BOUNDS]='0 0';
   properties:[VSLANGPROPNAME_COLOR_FLAGS]=CLINE_COLOR_FLAG;
   properties:[VSLANGPROPNAME_EVENTTAB_NAME]='';
   properties:[VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN]=0;
   properties:[VSLANGPROPNAME_HEX_MODE]=0;
   if (langId=='fundamental') {
      properties:[VSLANGPROPNAME_INDENT_STYLE]=INDENT_AUTO;
   } else {
      properties:[VSLANGPROPNAME_INDENT_STYLE]=INDENT_SMART;
   }
   properties:[VSLANGPROPNAME_INDENT_WITH_TABS]= 0;
   properties:[VSLANGPROPNAME_LEXER_NAME]= '';
   properties:[VSLANGPROPNAME_LINE_NUMBERS_FLAGS]= 0;
   properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]= 1;
   properties:[VSLANGPROPNAME_MARGINS]='1 74 1';
   properties:[VSLANGPROPNAME_MODE_NAME]='';
   properties:[VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS]=8;
   properties:[VSLANGPROPNAME_SOFT_WRAP]=0;
   properties:[VSLANGPROPNAME_SOFT_WRAP_ON_WORD]=1;
   properties:[VSLANGPROPNAME_TABS]='+8';
   properties:[VSLANGPROPNAME_TRUNCATE_LENGTH]=0;
   properties:[VSLANGPROPNAME_CONTEXT_MENU]="_ext_menu_default";
   properties:[VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION]="_ext_menu_default_sel";
   properties:[VSLANGPROPNAME_INHERITS_FROM]="";
   /*
      Need to set up different configs for unixasm ("s") 
#define UNIX_ASM_LEXER_LIST "SP=SPARC RS=PPC PP=PPC MA=INTEL LI=Intel IN=INTEL SC=INTEL FR=INTEL UN=INTEL SG=MIPS DE=MIPS MI=MIPS AL=ALPHA NT=Intel WI=Intel HP=HP"    
    
   win=Intel 
   mac=Intel
   Linux=Inntel 
    
   INTELSOLARIS=Intel 
   SPARC=SPARC 
   RS6000=PPC 
   HP9000=HP 
   */
   int tempInt;
   lnfSet := false;
   lnlSet := false;
   cfSet := false;
   while (info!='') {
      // get the next piece
      _str item;
      _str val;
      parse info with item ',' info;
      parse item with item'='val;

      switch (item) {
      case 'ALM':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_AUTO_LEFT_MARGIN] = val;
         }
         break;
      case 'BNDS':
         // bnds - bounds
         _str bs, be;
         parse val with bs be;
         if (isinteger(bs) && isinteger(be)) {
            properties:[VSLANGPROPNAME_BOUNDS] = bs' 'be;
         }
         break;
      case 'CAPS':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_AUTO_CAPS] = val;
         }
         break;
      case 'CF':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_COLOR_FLAGS] = val;
            cfSet = true;
         }
         break;
      case 'FWRM':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN] = val;
         }
         break;
      case 'HX':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_HEX_MODE] = val;
         }
         break;
      case 'IWT':
         if (isinteger(val)) {
#if __VERSION__<21
            if (langId=='fundamental') {
               // No point in have this setting be different between Windows and Unix
               // indent with tabs is more modern for text files and Unix needs
               // this on for editing system config files.
               val=1;
            }
#endif
            properties:[VSLANGPROPNAME_INDENT_WITH_TABS] = val;
         }
         break;
      case 'IN':
         if (isinteger(val) &&
                val >= 0 && val <= 2 &&
                !(val == 2 && langId == "fundamental")) {
            properties:[VSLANGPROPNAME_INDENT_STYLE] = val;
            break;
         }
         break;
      case 'KEYTAB':
         properties:[VSLANGPROPNAME_EVENTTAB_NAME] = val;
         break;
      case 'LN':
         if (val!='') {
            // Try to correct the case of this lexer
#if __VERSION__>=21
            val=_plugin_get_profile_name_case(VSCFGPACKAGE_COLORCODING_PROFILES,val);
#endif
            properties:[VSLANGPROPNAME_LEXER_NAME] = val;
         }
         break;
      case 'LNL':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN] = val;
            lnlSet = true;
         }
         break;
      case 'LNF':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_LINE_NUMBERS_FLAGS] = val;
            lnfSet = true;
         }
         break;
      case 'MN':
         properties:[VSLANGPROPNAME_MODE_NAME] = val;
         break;
      case 'MA':
         _str lm, rm, np;

         parse val with lm rm np;
         if (np=='') np = lm;

         if (isinteger(lm) && isinteger(rm) && isinteger(np)) {
            properties:[VSLANGPROPNAME_MARGINS] = val;
         }
         break;
      case 'ST':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS] = val;
         }
         break;
      case 'SW':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_SOFT_WRAP] = val;
         }
         break;
      case 'SOW':
#if __VERSION__>=21
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_SOFT_WRAP_ON_WORD] = val;
         }
#endif
         break;
      case 'TABS':
#if __VERSION__<21
         if (pos(' 'langId' ',' ada antlr awk bas cics d gl lex mod model204 plsql powershell prg pro rexx seq sqlserver ttcn3 vbs yacc ')) {
            val='+4';  //Since the tabs settings were messed up for this. Fix it in our defaults generator.
         }
         if (val!='') {
            properties:[VSLANGPROPNAME_TABS] = val;
         }
#else
         properties:[VSLANGPROPNAME_TABS] = val;
#endif
         break;
      case 'TL':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_TRUNCATE_LENGTH] = val;
         }
         break;
      case 'WW':
         if (isinteger(val)) {
            properties:[VSLANGPROPNAME_WORD_WRAP_FLAGS] = val;
         }
         break;
      }
   }

   // the default for line numbers flags is a little complicated
   if (!lnfSet) {
      if (lnlSet && isinteger(properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]) && properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]) {
         properties:[VSLANGPROPNAME_LINE_NUMBERS_FLAGS] = 3;
      } else {
         properties:[VSLANGPROPNAME_LINE_NUMBERS_FLAGS] = 0;
      }
   }
   if (lnlSet && isinteger(properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]) && properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]<=0) {
      properties:[VSLANGPROPNAME_LINE_NUMBERS_LEN]=1;
   }
   /*if (lnlSet && ((int)properties:[VSLANGPROPNAME_LINE_NUMBERS_FLAGS]&1)) {
      properties:['display_line_numbers'] = 1;
   } */
   if (!cfSet) {
      if(properties._indexin(VSLANGPROPNAME_LEXER_NAME)) {
         properties:[VSLANGPROPNAME_COLOR_FLAGS] = LANGUAGE_COLOR_FLAG;
      } else {
         properties:[VSLANGPROPNAME_COLOR_FLAGS] = CLINE_COLOR_FLAG;
      }
   }
   _str value;

   //Alias have been converted to profiles where this crazy update mechanism isn't needed any more.
   //convert_int_xmlcfg_property(langId,SURROUND_WITH_VERSION_DEF_VAR_KEY,properties,VSLANGPROPNAME_SURROUND_WITH_VERSION,false);

   smartpaste_index:=_FindLanguageCallbackIndex('%s_smartpaste',langId);
   // IF SmartPaste is supported for this language.
   if (smartpaste_index) {
      convert_int_xmlcfg_property(langId,SMART_PASTE_DEF_VAR_KEY,properties,VSLANGPROPNAME_SMART_PASTE);
   }
   /*
     TODO:  Not sure about auto_brace_placement
   */
   convert_int_xmlcfg_property(langId,ONE_LINE_AUTOBRACES_DEF_VAR_KEY,properties,VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT);
   if (has_beautifier_profiles(langId)) {
      convert_str_xmlcfg_property(langId,BEAUTIFIER_PROFILE_DEF_VAR_KEY,properties,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
   } else if (langId=='e' /* Slick-C */|| langId=='as' /*ActionScript */ || langId=='ada') {
      if (langId!='ada') {
         properties:[VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT] = 1;
      }
      properties:[VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE] = 'Default';
   } else if (langId=='cs' || langId=='java' || langId=='js' || langId=='phpscript' ) {
      properties:[VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT] = 1;
   }
   if (properties._indexin(VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE) && properties:[VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE]=='') {
      properties._deleteel(VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
   }
   convert_int_xmlcfg_property(langId,LANGUAGE_TAB_CYCLES_INDENTS,properties,VSLANGPROPNAME_TAB_CYCLES_INDENT);
   convert_int_xmlcfg_property(langId,BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_BEAUTIFIER_EXPANSION_FLAGS);
   convert_str_xmlcfg_property(langId,'word-chars',properties,VSLANGPROPNAME_WORD_CHARS,true);

   if(doesOptionApplyToLanguage(langId,OLD_LOI_SYNTAX_INDENT)) {
      value=getLanguageOptionItem(langId,OLD_LOI_SYNTAX_INDENT,null);
#if __VERSION__<21
      if (pos(' 'langId' ',' ada antlr awk bas cics gl lex mod model204 pl plsql powershell prg pro rexx seq sqlserver ttcn3 vbs yacc ')) {
         value='4';
      }
#endif
      if (!isinteger(value)) value=4;
      properties:[NEW_LOI_SYNTAX_INDENT] = value;
   }

   if(doesOptionApplyToLanguage(langId,OLD_LOI_SYNTAX_EXPANSION)) {
      value=getLanguageOptionItem(langId,OLD_LOI_SYNTAX_EXPANSION,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_SYNTAX_EXPANSION] = value;
   }

   /*if (pos(' 'langId' ',' masm npasm ')) {
       properties._deleteel(NEW_LOI_SYNTAX_INDENT);
   } */


   if(doesOptionApplyToLanguage(langId,OLD_LOI_MIN_ABBREVIATION)) {
      value=getLanguageOptionItem(langId,OLD_LOI_MIN_ABBREVIATION,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_MIN_ABBREVIATION] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_INDENT_CASE_FROM_SWITCH)) {
      value=getLanguageOptionItem(langId,OLD_LOI_INDENT_CASE_FROM_SWITCH,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_INDENT_CASE_FROM_SWITCH] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_KEYWORD_CASE) &&
      !pos(' 'langId' ',' cfscript phpscript idl tagdoc bat ini conf make imakefile fundamental binary process fileman c m applescript cs pas e java jsl bbc tex bibtex pdf postscript puppet dtd bourneshell csh vlx vsm db2 ansisql jcl grep diffpatch m4 rc def as ansic antlr lex yacc masm unixasm npasm awk ch d pl properties py rul tcl vbs verilog lua css powershell js qml erlang haskell fsharp markdown coffeescript googlego ttcn3 cg cghlsl matlab scala cmake swift ')) {
      // Languages which support this feature: gl ada asm390 cics cob cob74 cob2000 for model204 bas pl1 plsql prg sas sqlserver vhd pro seq rexx
      // missing GUI: mod model204 pro seq
      value=getLanguageOptionItem(langId,OLD_LOI_KEYWORD_CASE,null);
      if (!isinteger(value)) value= -1;
      properties:[NEW_LOI_KEYWORD_CASE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_BEGIN_END_COMMENTS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_BEGIN_END_COMMENTS,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_BEGIN_END_COMMENTS] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_INDENT_FIRST_LEVEL)) {
      value=getLanguageOptionItem(langId,OLD_LOI_INDENT_FIRST_LEVEL,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_INDENT_FIRST_LEVEL] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_MULTILINE_IF_EXPANSION)) {
      value=getLanguageOptionItem(langId,OLD_LOI_MULTILINE_IF_EXPANSION,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_MULTILINE_IF_EXPANSION] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_MAIN_STYLE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_MAIN_STYLE,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_MAIN_STYLE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_BEGIN_END_STYLE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_BEGIN_END_STYLE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_BEGIN_END_STYLE] = value;
   }
#if __VERSION__<21
   if (langId=='d') {
      properties:[NEW_LOI_BEGIN_END_STYLE] = 0;
   }
#endif
   if(doesOptionApplyToLanguage(langId,OLD_LOI_PAD_PARENS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_PAD_PARENS,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_PAD_PARENS] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_NO_SPACE_BEFORE_PAREN)) {
      value=getLanguageOptionItem(langId,OLD_LOI_NO_SPACE_BEFORE_PAREN,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_NO_SPACE_BEFORE_PAREN] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_POINTER_STYLE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_POINTER_STYLE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_POINTER_STYLE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_FUNCTION_BEGIN_ON_NEW_LINE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_FUNCTION_BEGIN_ON_NEW_LINE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_FUNCTION_BEGIN_ON_NEW_LINE] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY)) {
      value=getLanguageOptionItem(langId,OLD_LOI_INSERT_BEGIN_END_IMMEDIATELY,null);
      if (!isinteger(value)) value=4;
      properties:[NEW_LOI_INSERT_BEGIN_END_IMMEDIATELY] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END)) {
      value=getLanguageOptionItem(langId,OLD_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_QUICK_BRACE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_QUICK_BRACE,null);
      if (!isinteger(value)) value=0;
      value=!value;
      properties:[NEW_LOI_QUICK_BRACE] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_CUDDLE_ELSE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_CUDDLE_ELSE,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_CUDDLE_ELSE] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_DELPHI_EXPANSIONS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_DELPHI_EXPANSIONS,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_DELPHI_EXPANSIONS] = value?1:0;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_TAG_CASE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_TAG_CASE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_TAG_CASE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_ATTRIBUTE_CASE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_ATTRIBUTE_CASE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_ATTRIBUTE_CASE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_WORD_VALUE_CASE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_WORD_VALUE_CASE,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_WORD_VALUE_CASE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_HEX_VALUE_CASE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_HEX_VALUE_CASE,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_HEX_VALUE_CASE] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_QUOTE_NUMBER_VALUES)) {
      value=getLanguageOptionItem(langId,OLD_LOI_QUOTE_NUMBER_VALUES,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_QUOTE_NUMBER_VALUES] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_QUOTE_WORD_VALUES)) {
      value=getLanguageOptionItem(langId,OLD_LOI_QUOTE_WORD_VALUES,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_QUOTE_WORD_VALUES] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_USE_COLOR_NAMES)) {
      value=getLanguageOptionItem(langId,OLD_LOI_USE_COLOR_NAMES,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_USE_COLOR_NAMES] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT)) {
      value=getLanguageOptionItem(langId,OLD_LOI_USE_DIV_TAGS_FOR_ALIGNMENT,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_USE_DIV_TAGS_FOR_ALIGNMENT] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES)) {
      value=getLanguageOptionItem(langId,OLD_LOI_USE_PATHS_FOR_FILE_ENTRIES,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_USE_PATHS_FOR_FILE_ENTRIES] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_AUTO_VALIDATE_ON_OPEN)) {
      value=getLanguageOptionItem(langId,OLD_LOI_AUTO_VALIDATE_ON_OPEN,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_AUTO_VALIDATE_ON_OPEN] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_AUTO_CORRELATE_START_END_TAGS)) {
      value=getLanguageOptionItem(langId,OLD_LOI_AUTO_CORRELATE_START_END_TAGS,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_AUTO_CORRELATE_START_END_TAGS] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_AUTO_SYMBOL_TRANSLATION)) {
      value=getLanguageOptionItem(langId,OLD_LOI_AUTO_SYMBOL_TRANSLATION,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_AUTO_SYMBOL_TRANSLATION] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_INSERT_RIGHT_ANGLE_BRACKET)) {
      value=getLanguageOptionItem(langId,OLD_LOI_INSERT_RIGHT_ANGLE_BRACKET,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_INSERT_RIGHT_ANGLE_BRACKET] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_COBOL_SYNTAX)) {
      value=getLanguageOptionItem(langId,OLD_LOI_COBOL_SYNTAX,null);
      if (!isinteger(value)) value=1;
      properties:[NEW_LOI_COBOL_SYNTAX] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_AUTO_INSERT_LABEL)) {
      value=getLanguageOptionItem(langId,OLD_LOI_AUTO_INSERT_LABEL,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_AUTO_INSERT_LABEL] = value;
   }
   if(doesOptionApplyToLanguage(langId,OLD_LOI_RUBY_STYLE)) {
      value=getLanguageOptionItem(langId,OLD_LOI_RUBY_STYLE,null);
      if (!isinteger(value)) value=0;
      properties:[NEW_LOI_RUBY_STYLE] = value;
   }
   convert_str_xmlcfg_property(langId,REFERENCED_IN_LANGUAGES_DEF_VAR_KEY,properties,VSLANGPROPNAME_REFERENCED_IN_LANGIDS);
   convert_str_xmlcfg_property(langId,"begin-end",properties,VSLANGPROPNAME_BEGIN_END_PAIRS);
   
   smarttab_index := _FindLanguageCallbackIndex('%s_smartpaste',langId);
   if (smarttab_index && index_callable(smarttab_index)) {
      convert_int_xmlcfg_property(langId,SMART_TAB_DEF_VAR_KEY,properties,VSLANGPROPNAME_SMART_TAB);  //def_smarttab
   }
   //convert_str_xmlcfg_property(langId,"alias",properties,VSLANGPROPNAME_ALIAS_FILENAME);
   convert_str_xmlcfg_property(langId,CODE_MARGINS_DEF_VAR_KEY,properties,VSLANGPROPNAME_CODE_MARGINS);
   convert_str_xmlcfg_property(langId,DIFF_COLUMNS_DEF_VAR_KEY,properties,VSLANGPROPNAME_DIFF_COLUMNS);
   convert_int_xmlcfg_property(langId,ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY,properties,VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS);
   convert_int_xmlcfg_property(langId,USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY,properties,VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING); 
   convert_str_xmlcfg_property(langId,'inherit',properties,VSLANGPROPNAME_INHERITS_FROM);
   convert_int_xmlcfg_property(langId,NUMBERING_STYLE_DEF_VAR_KEY,properties,VSLANGPROPNAME_NUMBERING_STYLE); 
   convert_int_xmlcfg_property(langId,SURROUND_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_SURROUND_FLAGS); 
   convert_int_xmlcfg_property(langId,CODEHELP_FLAGS_DEF_VAR_KEY,properties,VSLANGPROPNAME_CODE_HELP_FLAGS); 
   convert_int_xmlcfg_property(langId,AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_AUTO_COMPLETE_FLAGS); 
   convert_int_xmlcfg_property(langId,AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY,properties,VSLANGPROPNAME_AUTO_COMPLETE_MIN); 
   convert_int_xmlcfg_property(langId,SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_SYMBOL_COLORING_FLAGS); 
   maybe_convert_doc_comments(langId,properties);
   maybe_convert_comment_wrap_options(langId,properties);
   //VS_INDENT_FLAG_BACKSPACE_UNINDENT, IndentFlags
   convert_int_xmlcfg_property(langId,INDENT_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_BACKSPACE_UNINDENTS,langId!='fundamental'); 

   //maybe_convert_xml_wrap_options(langId,properties);

   value = getLanguageDefVar(langId, MENU_OPTIONS_DEF_VAR_KEY);
   if (value==null) {
      value='';
   }
   parse value with auto menu_name ',' auto menu_name_if_sel;
   if (menu_name!='') {
      properties:[VSLANGPROPNAME_CONTEXT_MENU] = menu_name;
   } else {
      menu_name='_ext_menu_default';
   }
   if (menu_name_if_sel!='') {
      properties:[VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION] = menu_name_if_sel;
   } else {
      menu_name='_ext_menu_default_sel';
   }
   convert_str_xmlcfg_property(langId,LOAD_FILE_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_LOAD_FILE_OPTIONS); 
   convert_str_xmlcfg_property(langId,SAVE_FILE_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_SAVE_FILE_OPTIONS); 
   convert_int_xmlcfg_property(langId,REAL_INDENT_DEF_VAR_KEY,properties,VSLANGPROPNAME_REAL_INDENT); 
   convert_int_xmlcfg_property(langId,AUTO_CASE_KEYWORDS_DEF_VAR_KEY,properties,VSLANGPROPNAME_AUTO_CASE_KEYWORDS); 

   /* String editing, comment editing, doc comment.
      Since String editing is allowed if certain color coding is defined,
      go ahead and always write this property.
   */ 
   convert_int_xmlcfg_property(langId,COMMENT_EDITING_FLAGS_DEF_VAR_KEY,properties,VSLANGPROPNAME_COMMENT_EDITING_FLAGS); 
   
   if (_istagging_supported(langId)) {
      convert_str_xmlcfg_property(langId,TAG_FILE_LIST_DEF_VAR_KEY,properties,'tag_file_list'); 
   }
   convert_int_xmlcfg_property(langId,AUTOBRACKET_VAR_KEY,properties,VSLANGPROPNAME_AUTO_BRACKET_FLAGS); 
   convert_int_xmlcfg_property(langId,AUTOSURROUND_VAR_KEY,properties,VSLANGPROPNAME_AUTO_SURROUND_FLAGS); 
   convert_int_xmlcfg_property(langId,ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY,properties,VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE); 
   convert_int_xmlcfg_property(langId,AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY,properties,VSLANGPROPNAME_AUTO_COMPLETE_POUND_INCLUDE); 
   convert_int_xmlcfg_property(langId,SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY,properties,VSLANGPROPNAME_SELECTIVE_DISPLAY_FLAGS); 
   convert_int_xmlcfg_property(langId,'include',properties,VSLANGPROPNAME_INCLUDE_RE); 


   // For backward compatibility, must forst binary mode hex_mode value to HM_HEX_ON
   if (langId=='binary') {
      properties:['hex_mode']=HM_HEX_ON;
   } else {
   }

/* 
 
    The languages below have indent set to AUTO and not SMART
    and p_SyntaxIndent is 0
       p_SyntaxIndent=0,p_IndentStyle==INDENT_AUTO 
       fundamental,fundamental
       process,process
       fileman,fileman
       bbc,bbc
       tex,tex
       bibtex,bittex
       pdf,pdf
       postscript,postscript
       puppet,puppet
       grep,grep
       diffpatch,diffpatch
       m4,m4
       rc,rc
       def,def
 
    The languages below have indent set to AUTO and not SMART
       ,p_IndentStyle==INDENT_AUTO 
       ,binary
       ,cfml
       ,tld
       ,vlx
       ,vsm
       ,masm
       ,unixasm
       ,npasm
 
 begin_end_style support: ansic antlr applescript as awk c cfscript cg cghsl ch cobol cob74 cob2000 cs css d e googlego idl java js jsl lex m pas phpscript
                          pl pl1 powershell qml ruby seq swift systemverilog tagdoc tcl ttcn3 vera verilog vhd yacc
     c-keys
 No begin_end_style support: ada android ansisql ant asm390 bas bat bbc bibtex binary bourneshell cfml csh cics cmake coffeescript
                             conf db2 def diffpatch docbook dtd erlang fileman for fsharp fundamental gl grep haskell html imakefile
                             ini jcl lua m4 mak markdown masm matlab modula model204 npasm pdf plsql postscript prg pro process
                             properties puppet py rc rexx rul sas scala sqlserver tex tld unixasm vbscript vlx vpj vsm xhtml xml xmldoc xsd
     xml-keys,html-keys,ext-keys,default-keys,''
 
 fix LUA if? insert end??
 fix veralog,systemverilog:  Need separate begin end style for "If statment"
 
 ansic
 antlr
 awk
 c
 ch
 d
 javascript
 msqbas
 ruby
 swift
 java
 pl,
 
 
syntax_indent 
syntax_expansion 
expand_alias_on_space 
 
min_abbreviation 
wc_keyword
   mak     keyword_case (not used) auto_case_keywords (not used)
   mod     keyword_case (not used) auto_case_keywords (not used)
 
   (could fix gui) model204  uses keyword_case    auto_case_keywords (not used)
   (could fix gui) *pro   uses keyword_case,   nothing on GUI - doesn't use auto_case_keywords (uses def_pro_autocase instead).
   (could fix gui)*seq   uses keyword_case - nothing on GUI - doesn't use auto_case_keywords (uses def_seq_autocase instead).
 
   systemverilog  keyword_case (not used) auto_case_keywords (not used)
   vera   keyword_case (not used) auto_case_keywords (not used)

auto_case_keywords
beautifier_default_profile 
 
begin_end_style
code_margins??
comment_wrap_options
delphi_expansions 
 
else_on_line_after_brace
function_begin_on_new_line
indent_case_from_switch
indent_first_level
 
 
keyword_case 
attribute_case 
word_value_case 
hex_word_value_case 
tag_case 
 
insert_begin_end_immediately
insert_blank_line_between_begin_end 
 
main_style
no_space_before_paren
numbering_style
pad_parens
pointer_style
quick_brace
symbol_coloring_options
tag_file_list
xml_wrap_options


indent_case_from_switch 
getBeginEndComments?? ? 
keyword_case 
indent_first_level 
multi_line_if_expansion 
main_style ==>CMainStyle
use_continuation_indent_on_function_parameters
function_parameter_alignment 
begin_end_style => BeginEndStyles 
    LANGUAGES_WITH_PROFILES[] = {'c', 'm', 'java', 'cs', 'js', 'xml', 'xhtml', 'phpscript', 'html', 'docbook', 'vbs', 'cfml', 'vpj', 'xsd', 'ant',
                              'android', 'py', 'systemverilog','verilog'};
    remove some for c, m, java, cs, js, phpscript, py, android, systemverilog, verilog, vbs
   xml,xhtml,html,docbook, cfml, vpj, xsd,ant,
 
   insert_begin_end_immediately  --> 0|1
   insert_blank_line_between_begin_end  --> 0|1
   quick_brace_unbrace  --> 0|1   defaults to 1
   (if)begin_end_style--> 0|1|2
   (if)space_before_paren  --> 0|1   defaults to 1
   function_begin_on_new_line --> 0|1
   pointer_style= 0|1|2  (space_after_pointer| space_surrounds_pointer)
   (if)pad_parens --> 0|1
   else_on_line_after_brace  --> 0|1
   delphi_expansions  --> 0 | 1
*/
   if (langId=='tld') {
      properties:[VSLANGPROPNAME_EVENTTAB_NAME]='xml-keys';
      properties:[VSLANGPROPNAME_INHERITS_FROM]='xml';
   }
#if 0
   // We could change these languages to use ext-keys so expand alias on space is supported.
   if (//(!properties.indexin(VSLANGPROPNAME_EVENTTAB_NAME) ||  translate(properties:[VSLANGPROPNAME_EVENTTAB_NAME],'-','_')=='default-keys') &&
      pos(' 'langId' ',' bibtex fundamental masm npasm pdf postscript properties puppet tex unixasm ')) {
      properties:[VSLANGPROPNAME_EVENTTAB_NAME]='ext-keys';
   }
#endif
   eventtab_name := "";
#if __VERSION__>=21
   eventtab_name=translate(_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME),'-','_');
#endif
   if (properties._indexin(VSLANGPROPNAME_EVENTTAB_NAME)) {
      eventtab_name=translate(properties:[VSLANGPROPNAME_EVENTTAB_NAME],'-','_');
      if (eventtab_name=='default-keys') {
         eventtab_name='';
      }
      // Normalize event table with dashes. 
      // Doing this so can be lazy when doing multi-file find for event table.
      properties:[VSLANGPROPNAME_EVENTTAB_NAME]=eventtab_name;
   }
   if (langId=='masm' || langId=='unixasm' || langId=='npasm' || langId=='properties') {
      if (properties._indexin(VSLANGPROPNAME_EVENTTAB_NAME) && properties:[VSLANGPROPNAME_EVENTTAB_NAME]=='') {
         properties._deleteel(VSLANGPROPNAME_EVENTTAB_NAME);
      }
   }
   if (pos(' 'langId' ',//' bibtex fundamental masm npasm pdf postscript properties puppet tex unixasm ':+
                        ' fileman grep process ':+  // These modes have custom eventtables that don't support syntax expansion
                        ' asm390 cg cghlsl cics css fsharp haskell jcl markdown ':+  // These modes have custom eventtables that don't support syntax expansion
                        ' binary '                  // These shouldn't support syntax expansion
           )  || 
           eventtab_name==''
           || eventtab_name=='ext-keys' 
            //|| eventtab_name=='html-keys' 
            || eventtab_name=='xml-keys' 
            || eventtab_name=='default-keys' ||

       //_LanguageInheritsFrom('html') ||
       _LanguageInheritsFrom('xml')
       ) {
      properties._deleteel(NEW_LOI_SYNTAX_EXPANSION);
   }

   braces_supported := false;
   {
      _str list[];
      get_language_inheritance_list(langId, list);
      for (i := 0; i < list._length(); i++) {
         if (pos(' 'list[i]' ', ' ansic cs c d jsl java m pas awk ch pl tcl as cfscript js phpscript pl1 vera vhd e idl systemverilog vera ') > 0) {
            braces_supported = true;
            break;
         }
      }
   }
   // Remove support for insert_begin_end_immediately for some languages
   // antlr uses c-keys? 
   // lex uses c-keys?
   // idl uses c-keys but doesn't have weird expansions
   // powershell should support the insert braces immediatley option but doesn't
   if (!braces_supported 
       && eventtab_name!='c-keys' && eventtab_name!='java-keys' && 
       ! _LanguageInheritsFrom('c', langId) && ! _LanguageInheritsFrom('java', langId)) {
      properties._deleteel(NEW_LOI_INSERT_BEGIN_END_IMMEDIATELY);
      properties._deleteel(NEW_LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END);
      //properties._deleteel(NEW_LOI_SYNTAX_EXPANSION);
   }


   // Remove support for expand alias on space for some languages
   if (pos(' 'langId' ',//' bibtex fundamental masm npasm pdf postscript properties puppet tex unixasm ':+
                        ' fileman grep process ':+  // These modes have custom eventtables that don't support expand alias on space
                        ' cg cghlsl cics css fsharp haskell jcl markdown ':+  // These modes have custom eventtables that don't support expand alias on space
                        ' binary '                  // These shouldn't support expand alias on space
           )  
           ||  eventtab_name==''
           //|| eventtab_name=='html-keys' 
           || eventtab_name=='xml-keys' 
           || eventtab_name=='default-keys' 
            
       ) {
      properties._deleteel(VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE);
   }
   // Need to make sure expand_alias_on_space and syntax_expansion are set
   // so embedded languages can support these.
   if (_LanguageInheritsFrom('html') || langId=='html' || langId=='cfml') {
      if (!properties._indexin(VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE)) {
         properties:[VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE]=1;
      }
      if (!properties._indexin(NEW_LOI_SYNTAX_INDENT)) {
         properties:[NEW_LOI_SYNTAX_INDENT] = 1;
      }
   }

   // Remove support for syntax_indent for some languages
   if (pos(' 'langId' ',//' bibtex fundamental masm npasm pdf postscript properties puppet tex unixasm ':+
                        ' fileman grep process ':+  // These modes have custom eventtables that don't support syntax indent
                        ' bbc bibtex def diffpatch fundamental m4 pdf postscript puppet rc tex ':+  // Syntax indent was disabled in v20 for these
                       //' asm390 cg cghlsl cics css fsharp haskell jcl markdown ':+  // These modes have custom eventtables that don't support syntax indent
                        ' binary '                  // These shouldn't support syntax indent
           ) 
           //|| eventtab_name==''
           //|| eventtab_name=='html-keys' 
           //|| eventtab_name=='xml-keys' 
           //|| eventtab_name=='default-keys' 
            
       ) {
      properties._deleteel(NEW_LOI_SYNTAX_INDENT);
   }
   // Remove support for keyword_case for some languages
   if (pos(' 'langId' ', ' mak mod systemverilog vera ' )) {
      properties._deleteel(NEW_LOI_KEYWORD_CASE);
   }
   // Remove support for auto_case_keywords for some languages
   if (pos(' 'langId' ', ' mak mod model204 systemverilog vera ' )) {
      properties._deleteel(VSLANGPROPNAME_AUTO_CASE_KEYWORDS);
   }

   if (!properties._indexin(NEW_LOI_SYNTAX_EXPANSION) && !properties._indexin(VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE) ) {
      properties._deleteel(NEW_LOI_MIN_ABBREVIATION);
   }
   // Remove support for begin_end_style for some languages
   if (!pos(' 'langId' ', ' ansic antlr applescript as awk c cfscript cg cghsl ch cobol cob74 cob2000 cs css d e googlego idl java js jsl lex m pas phpscript ':+
                          ' pl p`l1 powershell qml ruby seq swift systemverilog tagdoc tcl ttcn3 vera verilog vhd yacc '
             ) && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       ) {
      properties._deleteel(NEW_LOI_BEGIN_END_STYLE);
   }
   // Remove support for code_margins for some languages
   if (langId=='pl1' || _LanguageInheritsFrom('pl1', langId)) {
      properties._deleteel(VSLANGPROPNAME_CODE_MARGINS);
   }
   if (langId=='pas' || _LanguageInheritsFrom('pas', langId)) {
      properties._deleteel(NEW_LOI_DELPHI_EXPANSIONS);
   }
   if (!pos(' 'langId' ', ' as c e java googlego rul vera ') && eventtab_name!='c-keys' && !_LanguageInheritsFrom('c', langId) && !_LanguageInheritsFrom('vera', langId)
       && !_LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_CUDDLE_ELSE);
   }
   // This is a bit of a guess. We may need to tweak this.
   if (!pos(' 'langId' ', ' as c e java googlego rul vera ') && eventtab_name!='c-keys' && !_LanguageInheritsFrom('c', langId) && !_LanguageInheritsFrom('vera', langId)
       && !_LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_FUNCTION_BEGIN_ON_NEW_LINE);
   }
   // Remove support for indent_case_from_switch for some languages
   if (!pos(' 'langId' ', ' ansic antlr applescript as awk c cfscript cg cghsl ch cs css d e gl googlego idl java js jsl lex m pas phpscript ':+
                          ' pl pl1 powershell qml ruby swift systemverilog tagdoc tcl vera verilog vhd yacc '
             ) 
       && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       && eventtab_name!='java-keys' && ! _LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_INDENT_CASE_FROM_SWITCH);
   }
                            
   // Remove support for indent_first_level for some languages
   if (!pos(' 'langId' ', ' ansic antlr applescript as awk c cfscript ch cs d e googlego idl java js jsl lex m phpscript ':+
                          ' pl qml ruby swift tagdoc tcl ttcn3 vera verilog yacc '
             ) && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       ) {
      properties._deleteel(NEW_LOI_INDENT_FIRST_LEVEL);
   }

   // Remove support for keyword_case for some languages
   if (!pos(' 'langId' ', ' ada asm390 bas cics cob cob2000 cob74 for gl model204 pas pl1 plsql plsql prg pro rexx sabl sas sqlserver vbscript vhdl ')) {
       properties._deleteel(NEW_LOI_KEYWORD_CASE);
   }
   // Remove support for attribute_case for some languages
   if (eventtab_name!='html-keys' && eventtab_name!='xml-keys' 
       && !_LanguageInheritsFrom('html', langId) && !_LanguageInheritsFrom('xml', langId)
       ) {
       properties._deleteel(NEW_LOI_ATTRIBUTE_CASE);
       properties._deleteel(NEW_LOI_WORD_VALUE_CASE);
       properties._deleteel(NEW_LOI_HEX_VALUE_CASE);
       properties._deleteel(NEW_LOI_TAG_CASE);
   }
   // Remove support for main_style for some languages
   if (!_LanguageInheritsFrom('ansic', langId) && ! _LanguageInheritsFrom('c', langId) && !_LanguageInheritsFrom('d', langId)) {
      properties._deleteel(NEW_LOI_MAIN_STYLE);
   }

   // Remove support for no_space_before_paren for some languages
   if (!pos(' 'langId' ', ' ansic antlr applescript as awk c cfscript ch cs d e googlego idl java js jsl lex m phpscript ':+
                          ' pl pl1 powershell qml ruby sabl swift tagdoc tcl ttcn3 vera yacc '
             ) 
       && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       && eventtab_name!='java-keys' && ! _LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_NO_SPACE_BEFORE_PAREN);
   }
   // Remove support for pad_parens for some languages
   if (!pos(' 'langId' ', ' ansic antlr applescript as awk c cfscript ch cs d e googlego idl java js jsl lex m phpscript ':+
                          ' pl pl1 powershell qml ruby sabl swift tagdoc tcl ttcn3 vera yacc '
             ) 
       && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       && eventtab_name!='java-keys' && ! _LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_PAD_PARENS);
   }
   // Remove support for pad_parens for some languages
   // Can cfscript support quick brace?
   // idl probably shouldn't use c-keys
   // lex,yacc probably shouldn't use c-keys
   // tagdoc not included 
   if (!pos(' 'langId' ', ' ansic as awk c cs d e googlego idl java js jsl lex m phpscript ':+
                          ' pl qml ruby swift tcl ttcn3 vera yacc '
             ) 

       && (eventtab_name!='c-keys' && !pos(' 'langId' ',' cfscript idl lex tagdoc ttcn3 yacc ')) && ! _LanguageInheritsFrom('c', langId)
       && eventtab_name!='java-keys' && ! _LanguageInheritsFrom('java', langId)
       ) {
      properties._deleteel(NEW_LOI_QUICK_BRACE);
   }

   // Remove support for symbol_coloring_options for some languages
   if (!_QSymbolColoringSupported(langId)) {
      properties._deleteel(NEW_LOI_QUICK_BRACE);
   }


   if (!pos(' 'langId' ', ' ansic c cs d vera m ') 
       && eventtab_name!='c-keys' && ! _LanguageInheritsFrom('c', langId)
       ) {
      properties._deleteel(NEW_LOI_POINTER_STYLE);
   }

   // Remove support for numbering_style for some languages
   if (!pos(' 'langId' ', ' cob cob74 cob2000 ') 
       && ! _LanguageInheritsFrom('cob', langId)
       && ! _LanguageInheritsFrom('cob74', langId)
       && ! _LanguageInheritsFrom('cob2000', langId)
       ) {
      properties._deleteel(VSLANGPROPNAME_NUMBERING_STYLE);
   }
#if __VERSION__>=21
   if (_beautifier_is_supported(langId)) {
      properties._deleteel(LOI_HEX_VALUE_CASE);
      properties._deleteel(LOI_ATTRIBUTE_CASE);
      properties._deleteel(LOI_WORD_VALUE_CASE);
      properties._deleteel(LOI_TAG_CASE);
      properties._deleteel(LOI_KEYWORD_CASE);
      // listalign_fun_call_params seems to be set to 0 in the old configs. We definitely want "auto" (2) for this.
      properties._deleteel(LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS);

      /*
          syntax_indent was 3 for VBScript and Ada in old configs. Want updated value.
      */
      if (langId=='vbs' || langId=='ada') {
         properties._deleteel(LOI_SYNTAX_INDENT);
      }
      // Was +3, want +4
      if (langId=='ada') {
         properties._deleteel(VSLANGPROPNAME_TABS);
      }
   }
#endif



   _str array[];
   foreach (auto key=>value in properties) {
      array[array._length()]=key:+_chr(1):+value;
   }
   array._sort();
   int i;
#if 0
   for (i=0;i<array._length();++i) {
      parse array[i] with key (_chr(1)) value;
      if (key=='keyword_case') {
         if (value) {
            //say('langId='langId' v='value);
         }
      }
   }
#else
   //say('lang='langId);
   for (i=0;i<array._length();++i) {
      parse array[i] with key (_chr(1)) value;
#if __VERSION__>=21
      _LangSetProperty(langId,key,value);
#else
      _plugin_set_property(VSCFGPACKAGE_LANGUAGE,langId,VSCFGPROFILE_LANGUAGE_VERSION,key,value);
#endif
   }
#endif
}

#if __VERSION__>=21
static void delete_old_misc_data(_str langId) {
   int index;
   _str name;
   index = find_index('def-options-'langId, MISC_TYPE);
   if (index) delete_name(index);
   name = getDefVarName(langId, ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTOBRACKET_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTOSURROUND_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, AUTO_CASE_KEYWORDS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, REFERENCED_IN_LANGUAGES_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, CODEHELP_FLAGS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, COMMENT_EDITING_FLAGS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, COMMENT_WRAP_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, DOC_COMMENT_FLAGS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, INDENT_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, LOAD_FILE_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, MENU_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, NUMBERING_STYLE_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, REAL_INDENT_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SAVE_FILE_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SMART_PASTE_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SMART_TAB_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SURROUND_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SURROUND_WITH_VERSION_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, TAG_FILE_LIST_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   // Take care of this later.
   //name = getDefVarName(langId, UPDATE_VERSION_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, XML_WRAP_OPTIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, BEAUTIFIER_PROFILE_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, LANGUAGE_TAB_CYCLES_INDENTS);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, ONE_LINE_AUTOBRACES_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, CODE_MARGINS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, DIFF_COLUMNS_DEF_VAR_KEY);index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, 'word-chars');index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, 'begin-end');index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, 'alias');index=find_index(name,MISC_TYPE);if (index) delete_name(index);
   name = getDefVarName(langId, 'inherit');index=find_index(name,MISC_TYPE);if (index) delete_name(index);
}
static void convert_int_xmlcfg_property_all(_str defVarKey,_str propName) {
   switch (defVarKey) {
   case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
   case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
   case VSLANGPROPNAME_CODE_MARGINS:
      return;
   }
   int array[];
   index:=name_match('def-'defVarKey'-',1,MISC_TYPE);
   while (index) {
      array[array._length()]=index;

      //convertLangToXml(langId,index);
      index=name_match('def-language-',0,MISC_TYPE);
   }
   for (i:=0;i<array._length();++i) {
      index=array[i];
      parse name_name(index) with ('def-'defVarKey'-') auto langId;
      value:=getLanguageDefVar(langId, defVarKey,false);
      if(_LangIsDefined(langId)) {
         // Remove support for expand alias on space for some languages
         eventtab_name:=_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME);
         if (propName=='VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE' &&
             pos(' 'langId' ',//' bibtex fundamental masm npasm pdf postscript properties puppet tex unixasm ':+
                              ' fileman grep process ':+  // These modes have custom eventtables that don't support expand alias on space
                              ' cg cghlsl cics css fsharp haskell jcl markdown ':+  // These modes have custom eventtables that don't support expand alias on space
                              ' binary '                  // These shouldn't support expand alias on space
                 )  
                 ||  eventtab_name==''
                 || eventtab_name=='html-keys' 
                 || eventtab_name=='xml-keys' 
                 || eventtab_name=='default-keys' 

             ) {
            delete_name(index);
            continue;
         }
         if (isinteger(value)) {
            _LangSetProperty(langId,propName,value);
         }
      }
      delete_name(index);

   }
}
static void convert_str_xmlcfg_property_all(_str defVarKey,_str propName) {
   switch (defVarKey) {
   case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
   case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
   case VSLANGPROPNAME_CODE_MARGINS:
      return;
   }
   int array[];
   index:=name_match('def-'defVarKey'-',1,MISC_TYPE);
   while (index) {
      array[array._length()]=index;

      //convertLangToXml(langId,index);
      index=name_match('def-language-',0,MISC_TYPE);
   }
   for (i:=0;i<array._length();++i) {
      index=array[i];
      parse name_name(index) with ('def-'defVarKey'-') auto langId;
      if(_LangIsDefined(langId)) {

         value:=getLanguageDefVar(langId, defVarKey,false);
         if (value!=null && value!='') {
            if (propName=='tag_file_list') {
               _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_TAG_FILE_LIST,VSCFGPROFILE_TAG_FILE_LIST_VERSION,langId,value);
            } else {
               _LangSetProperty(langId,propName,value);
            }
         } else {
            value='';
            switch (propName) {
            case VSLANGPROPNAME_WORD_CHARS:
               //value=getDefaultWordChars(langId);
               break;
            //case VSLANGPROPNAME_TABS:
            //   //value="+4";
            //   break;
            //case VSLANGPROPNAME_MARGINS:
            //   //value="1 74 1";
            //   break;
            //case VSLANGPROPNAME_BOUNDS:
            //   value="0 0";
            //  break;
            }
         }
      }
      delete_name(index);

   }

}
static void convert_old_misc_data() {
   convert_int_xmlcfg_property_all(SMART_PASTE_DEF_VAR_KEY,VSLANGPROPNAME_SMART_PASTE);
   convert_int_xmlcfg_property_all(ONE_LINE_AUTOBRACES_DEF_VAR_KEY,VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT);
   convert_str_xmlcfg_property_all(BEAUTIFIER_PROFILE_DEF_VAR_KEY,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
   convert_int_xmlcfg_property_all(LANGUAGE_TAB_CYCLES_INDENTS,VSLANGPROPNAME_TAB_CYCLES_INDENT);
   convert_int_xmlcfg_property_all(BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY,VSLANGPROPNAME_BEAUTIFIER_EXPANSION_FLAGS);
   convert_str_xmlcfg_property_all('word-chars',VSLANGPROPNAME_WORD_CHARS);
   convert_str_xmlcfg_property_all(REFERENCED_IN_LANGUAGES_DEF_VAR_KEY,VSLANGPROPNAME_REFERENCED_IN_LANGIDS);
   convert_str_xmlcfg_property_all("begin-end",VSLANGPROPNAME_BEGIN_END_PAIRS);
   convert_int_xmlcfg_property_all(SMART_TAB_DEF_VAR_KEY,VSLANGPROPNAME_SMART_TAB);  //def_smarttab
   //convert_str_xmlcfg_property_all(CODE_MARGINS_DEF_VAR_KEY,VSLANGPROPNAME_CODE_MARGINS);
   convert_str_xmlcfg_property_all(DIFF_COLUMNS_DEF_VAR_KEY,VSLANGPROPNAME_DIFF_COLUMNS);
   convert_int_xmlcfg_property_all(ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY,VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS);
   convert_int_xmlcfg_property_all(USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY,VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING); 
   convert_str_xmlcfg_property_all('inherit',VSLANGPROPNAME_INHERITS_FROM);
   //convert_int_xmlcfg_property_all(NUMBERING_STYLE_DEF_VAR_KEY,VSLANGPROPNAME_NUMBERING_STYLE); 
   convert_int_xmlcfg_property_all(SURROUND_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_SURROUND_FLAGS); 
   convert_int_xmlcfg_property_all(CODEHELP_FLAGS_DEF_VAR_KEY,VSLANGPROPNAME_CODE_HELP_FLAGS); 
   convert_int_xmlcfg_property_all(AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_AUTO_COMPLETE_FLAGS); 
   convert_int_xmlcfg_property_all(AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY,VSLANGPROPNAME_AUTO_COMPLETE_MIN); 
   convert_int_xmlcfg_property_all(SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_SYMBOL_COLORING_FLAGS); 
   //convert_int_xmlcfg_property_all(INDENT_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_BACKSPACE_UNINDENTS,langId=='py'); 
   convert_str_xmlcfg_property_all(LOAD_FILE_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_LOAD_FILE_OPTIONS); 
   convert_str_xmlcfg_property_all(SAVE_FILE_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_SAVE_FILE_OPTIONS); 
   convert_int_xmlcfg_property_all(REAL_INDENT_DEF_VAR_KEY,VSLANGPROPNAME_REAL_INDENT); 
   //convert_int_xmlcfg_property_all(AUTO_CASE_KEYWORDS_DEF_VAR_KEY,VSLANGPROPNAME_AUTO_CASE_KEYWORDS); 
   convert_int_xmlcfg_property_all(COMMENT_EDITING_FLAGS_DEF_VAR_KEY,VSLANGPROPNAME_COMMENT_EDITING_FLAGS); 
   convert_str_xmlcfg_property_all(TAG_FILE_LIST_DEF_VAR_KEY,'tag_file_list'); 
   convert_int_xmlcfg_property_all(AUTOBRACKET_VAR_KEY,VSLANGPROPNAME_AUTO_BRACKET_FLAGS); 
   convert_int_xmlcfg_property_all(AUTOSURROUND_VAR_KEY,VSLANGPROPNAME_AUTO_SURROUND_FLAGS); 
   convert_int_xmlcfg_property_all(ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY,VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE); 
   convert_int_xmlcfg_property_all(AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY,VSLANGPROPNAME_AUTO_COMPLETE_POUND_INCLUDE); 
   convert_int_xmlcfg_property_all(SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY,VSLANGPROPNAME_SELECTIVE_DISPLAY_FLAGS); 
   convert_int_xmlcfg_property_all('include',VSLANGPROPNAME_INCLUDE_RE); 
}
#endif
static void convert_names_table_lang_data_to_cfgxml() {
#if __VERSION__>=21
   /** 
    * "def-setup-[ext]" is no longer used for extension setup in SE 2008. 
    * Instead we use "def-lang-for-ext-[ext]" and "def-language-[lang]". 
    * The purpose of this code is to migrate those settings appropriately. 
    */
   names := "";
   index := name_match('def-setup-',1,MISC_TYPE);
   while (index > 0) {
      names :+= ("\t" :+ name_name(index) :+ "\n");
      name := substr(name_name(index),11);
      info := name_info(index);
      delete_name(index);
      //say('name='name' info='info);
      if (substr(info,1,1)=='@') {
         //say('name='name' refersto='substr(info, 2));
         _ExtensionSetRefersTo(name, substr(info, 2));
         //ExtensionSettings.setLangRefersTo(name, substr(info, 2));
      } else {
         index = find_index('def-language-'name);
         if (!index) {
            insert_name('def-language-'name,MISC_TYPE,info);
         } else {
            set_name_info(index, info);
         }

         if (name!='fundamental') {
            _ExtensionSetRefersTo(name, name);
         }
         //ExtensionSettings.setLangRefersTo(name, name);
      }
      // next please
      index = name_match('def-setup-',1,MISC_TYPE);
   }
#if 0
   if (moduleLoaded != "" && names != '') {
      _message_box(nls("The module '%s'\n":+
                       "defines the following variables which are no longer used:\n":+
                       "\n":+
                       "%s\n":+
                       "def-setup-[ext]* has been replaced with def-language-[langid] and\n":+
                       "file extensions are mapped to languages using def-lang-for-ext-[ext]\n":+
                       "\n":+
                       "The settings have been automatically migrated, but we recommend\n":+
                       "revising your code to create the correct settings using\n":+
                       "_CreateLanguage() and _CreateExtension().",
                       moduleLoaded,names));
   }
#endif

   // change storage of word chars in SE 2010 - sg
   // get language specific primary extensions
   wordChars := '';
   typeless start, rest;
   index = name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     langID := substr(name_name(index),14);

     info := name_info(index);
     parse info with start 'WC='wordChars',' rest;

     if (wordChars != '' && wordChars != 'N/A') {
        _LangSetProperty(langID, VSLANGPROPNAME_WORD_CHARS,wordChars);
        //LanguageSettings.setWordChars(langID, wordChars);
        info = start'WC=N/A,'rest;
        set_name_info(index, info);
     }

     index=name_match('def-language-',0,MISC_TYPE);
   }
#else
   int index;
#endif
   int array[];
   index=name_match('def-language-',1,MISC_TYPE);
   while (index) {
      array[array._length()]=index;

      //convertLangToXml(langId,index);
      index=name_match('def-language-',0,MISC_TYPE);
   }
   for (i:=0;i<array._length();++i) {
      index=array[i];
      parse name_name(index) with 'def-language-' auto langId;
      convertLangToXml(langId,index);
#if __VERSION__>=21
      delete_name(index);
      delete_old_misc_data(langId);
#endif
   }
}

#if 1
defmain()
{
   convert_names_table_lang_data_to_cfgxml();
#if __VERSION__>=21
   _convert_names_table_ext_data_to_cfgxml();
   convert_old_misc_data();
#endif
   return 0;
}

#else
// Create or appned to system profiles for all defined languages
defmain()
{
   //handle:=_xmlcfg_open('F:\f\se64\vslick2000\lang.system.cfg.xml',auto status);
   handle:=_xmlcfg_open('F:\f\se64\vslick2000\slickedit\temp\20.0.1\user.cfg.xml',auto status);
   if (handle<0) {
      say('bad xml');
      return 0;
   }
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/options/profile",array);
   for (i:=0;i<array._length();++i) {
      profile_node:=array[i];
      int system_handle;
      profile_name:=_xmlcfg_get_attribute(handle,profile_node,'n');
      parse profile_name with '.' auto langId;
      _str output_filename=_getSlickEditInstallPath():+'plugins/com_slickedit.base/language/'langId'/language.':+langId:+'.cfg.xml';
      //_str output_filename=VSCFGPLUGIN_BASE:+'language/':+langId:+'/':+'language.':+langId:+'.cfg.xml';
      system_handle=_xmlcfg_open(output_filename,status);
      if (system_handle>=0) {
         say('h1 output_filename='output_filename);
         system_profile_node:=_xmlcfg_find_simple(system_handle,"/options/profile");
         if (system_profile_node<=0) {
            say("could not find existing profile node for langId="langId);
            _message_box('h1 stop');
            stop();
            return 0;
         }
         _xmlcfg_copy(system_handle,system_profile_node,handle,profile_node,VSXMLCFG_COPY_CHILDREN);
         _xmlcfg_save(system_handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      } else {
         say('h2 output_filename='output_filename);
         status=_make_path(output_filename,true);
         if (status) {
            say('output_filename='output_filename);
            say('error creating path='status);
            _message_box('stop');
            stop();
         }
         system_handle=_xmlcfg_create(output_filename,VSENCODING_UTF8);
         system_profile_node:=_xmlcfg_set_path(system_handle,"/options/profile");
         _xmlcfg_set_attribute(system_handle,system_profile_node,'n','language.':+langId);
         _xmlcfg_set_attribute(system_handle,system_profile_node,'version',1);
         _xmlcfg_copy(system_handle,system_profile_node,handle,profile_node,VSXMLCFG_COPY_CHILDREN);
         _xmlcfg_save(system_handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      }
   }
   _xmlcfg_close(handle);
}
#endif
