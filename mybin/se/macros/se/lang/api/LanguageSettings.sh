////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#ifndef LANGUAGE_SETTINGS_SH
#define LANGUAGE_SETTINGS_SH

// these are the items that are in def-language-<lang>
enum LanguageDefinitionItems {
   LDI_MODE_NAME,
   LDI_TABS,
   LDI_MARGINS,
   LDI_KEY_TABLE,
   LDI_WORD_WRAP,
   LDI_INDENT_WITH_TABS,
   LDI_SHOW_TABS,
   LDI_INDENT_STYLE,
   LDI_WORD_CHARS,
   LDI_LEXER_NAME,
   LDI_COLOR_FLAGS,
   LDI_LINE_NUMBERS_LENGTH,
   LDI_TRUNCATE_LENGTH,
   LDI_BOUNDS,
   LDI_CAPS,
   LDI_SOFT_WRAP,
   LDI_SOFT_WRAP_ON_WORD,
   LDI_HEX_MODE,
   LDI_LINE_NUMBERS_FLAGS,
};

// these items are in def-options-<lang>
enum LanguageOptionItems {
   LOI_SYNTAX_INDENT,
   LOI_SYNTAX_EXPANSION,
   LOI_MIN_ABBREVIATION,
   LOI_INDENT_CASE_FROM_SWITCH,
   LOI_KEYWORD_CASE,
   LOI_BEGIN_END_COMMENTS,
   LOI_INDENT_FIRST_LEVEL,
   LOI_MULTILINE_IF_EXPANSION,
   LOI_MAIN_STYLE,
   LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS,
   LOI_BEGIN_END_STYLE,
   LOI_PAD_PARENS,
   LOI_NO_SPACE_BEFORE_PAREN,
   LOI_POINTER_STYLE,
   LOI_FUNCTION_BEGIN_ON_NEW_LINE,
   LOI_INSERT_BEGIN_END_IMMEDIATELY,
   LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END,
   LOI_QUICK_BRACE,
   LOI_CUDDLE_ELSE,
   LOI_DELPHI_EXPANSIONS,              // pascal
   LOI_TAG_CASE,
   LOI_ATTRIBUTE_CASE,
   LOI_WORD_VALUE_CASE,
   LOI_HEX_VALUE_CASE,
   LOI_QUOTES_FOR_NUMERIC_VALUES,
   LOI_QUOTES_FOR_SINGLE_WORD_VALUES,
   LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS,
   LOI_USE_COLOR_NAMES,
   LOI_USE_DIV_TAGS_FOR_ALIGNMENT,
   LOI_USE_PATHS_FOR_FILE_ENTRIES,
   LOI_AUTO_VALIDATE_ON_OPEN,
   LOI_AUTO_CORRELATE_START_END_TAGS,
   LOI_AUTO_SYMBOL_TRANSLATION,
   LOI_INSERT_RIGHT_ANGLE_BRACKET,     // deprecated
   LOI_COBOL_SYNTAX,                   // cobol only
   LOI_AUTO_INSERT_LABEL,              // vhdl only
   LOI_RUBY_STYLE,                     // ruby only
};

// these are the many items which can be ORed into the brace styles item
enum_flags BeginEndStyles {
   BES_BEGIN_END_STYLE_1                     =   0x0,
   BES_SPACE_BEFORE_POINTER                  =   0x0, 
   BES_BEGIN_END_STYLE_2                     =   0x1,
   BES_BEGIN_END_STYLE_3                     =   0x2,
   BES_INSERT_BEGIN_END_IMMEDIATELY          =   0x4,
   BES_INSERT_BLANK_LINE_BETWEEN_BEGIN_END   =   0x8,
   BES_NO_SPACE_BEFORE_PAREN                 =  0x10,
   BES_FUNCTION_BEGIN_ON_NEW_LINE            =  0x20,
   BES_SPACE_AFTER_POINTER                   =  0x40,
   BES_SPACE_SURROUNDS_POINTER               =  0x80,
   BES_PAD_PARENS                            = 0x100,
   BES_NO_QUICK_BRACE_UNBRACE                = 0x200,
   BES_ELSE_ON_LINE_AFTER_BRACE              = 0x400,
   BES_DELPHI_EXPANSIONS                     = 0x800,
};

enum CMainStyle {
   CMS_KR,
   CMS_ANSI_CPP,
   CMS_NONE,
};

enum CapsMode {
   CM_CAPS_OFF,         // caps off
   CM_CAPS_ON,          // caps on
   CM_CAPS_AUTO,        // use _GetCaps() to determine whether on/off
};

enum HexMode {
   HM_HEX_OFF,          // hex mode off
   HM_HEX_ON,           // hex mode on
   HM_HEX_LINE,         // line hex mode
};

#define BEGIN_END_STYLE_FIRST       LOI_BEGIN_END_STYLE
#define BEGIN_END_STYLE_LAST        LOI_DELPHI_EXPANSIONS

#define LOI_LAST                    LOI_RUBY_STYLE
#define LDI_LAST                    LDI_LINE_NUMBERS_FLAGS

#define DEFAULT_SYNTAX_INFO  '4 1 1 0 0 3 0'

#define SPACE_HOLDER -1
#define BRACE_STYLE  -2

#define WORD_CHARS_NOT_APPLICABLE   'N/A'

// these are the things that are held in language-specific def-vars
#define ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY         'adaptive-flags'
#define ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY             'alias-expand'
#define ALIAS_FILENAME_DEF_VAR_KEY                    'alias'
#define AUTOBRACKET_VAR_KEY                           'autobracket'
#define AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY           'autocompletemin'
#define AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY              'autocomplete'
#define AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY        'expand-include'
#define AUTO_CASE_KEYWORDS_DEF_VAR_KEY                'autocase'
#define BEGIN_END_PAIRS_DEF_VAR_KEY                   'begin-end'
#define REFERENCED_IN_LANGUAGES_DEF_VAR_KEY           'referenced-in'
#define CODEHELP_FLAGS_DEF_VAR_KEY                    'codehelp'
#define COMMENT_EDITING_FLAGS_DEF_VAR_KEY             'commentediting'
#define COMMENT_WRAP_OPTIONS_DEF_VAR_KEY              'comment-wrap'
#define DOC_COMMENT_FLAGS_DEF_VAR_KEY                 'doccomment'
#define INDENT_OPTIONS_DEF_VAR_KEY                    'indent'
#define INHERIT_DEF_VAR_KEY                           'inherit'
#define LOAD_FILE_OPTIONS_DEF_VAR_KEY                 'load'
#define MENU_OPTIONS_DEF_VAR_KEY                      'menu'
#define NUMBERING_STYLE_DEF_VAR_KEY                   'numbering'
#define REAL_INDENT_DEF_VAR_KEY                       'real-indent'
#define SAVE_FILE_OPTIONS_DEF_VAR_KEY                 'save'
#define SMART_PASTE_DEF_VAR_KEY                       'smartpaste'
#define SMART_TAB_DEF_VAR_KEY                         'smarttab'
#define SURROUND_OPTIONS_DEF_VAR_KEY                  'surround'
#define SURROUND_WITH_VERSION_DEF_VAR_KEY             'surround-with-version'
#define SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY           'symbolcoloring'
#define TAG_FILE_LIST_DEF_VAR_KEY                     'tagfiles'
#define UPDATE_VERSION_DEF_VAR_KEY                    'update-version'
#define USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY           'adaptive-formatting'
#define WORD_CHARS_OPTIONS_DEF_VAR_KEY                'word-chars'
#define XML_WRAP_OPTIONS_DEF_VAR_KEY                  'xml-wrap'
#define BEAUTIFIER_PROFILE_DEF_VAR_KEY                'beautifier-profile'
#define BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY             'beautifier-expansions'
#define ONE_LINE_AUTOBRACES_DEF_VAR_KEY               'one-line-brackets'
#define CODE_MARGINS_DEF_VAR_KEY                      'code-margins'

// language setting keys - used to parse options strings - this seems like a lot of confusing keys, I know.
// Short keys are used to parse out options from def-language-<langId>.
// Both short keys and p_keys were used to update buffers when a setting is changed, pre-v15.
// In v15, we added the update_keys so that when you call update_buffers, you always know which one to use.  
// Not all fields have both p keys and short keys, but they do all have update keys.
// If you use one of the other keys, we will helpfully correct it to the update key.
// Is it overkill?  Maybe, but someone will thank me someday.
#define MODE_NAME_P_KEY                               'P_MODE_NAME'
#define MODE_NAME_SHORT_KEY                           'MN'
#define MODE_NAME_UPDATE_KEY                          MODE_NAME_P_KEY

#define TABS_P_KEY                                    'P_TABS'
#define TABS_SHORT_KEY                                'TABS'
#define TABS_UPDATE_KEY                               TABS_P_KEY

#define MARGINS_P_KEY                                 'P_MARGINS'
#define MARGINS_SHORT_KEY                             'MA'
#define MARGINS_UPDATE_KEY                            MARGINS_P_KEY

#define KEY_TABLE_P_KEY                               'P_MODE_EVENTTAB'
#define KEY_TABLE_SHORT_KEY                           'KEYTAB'
#define KEY_TABLE_UPDATE_KEY                          KEY_TABLE_P_KEY

#define WORD_WRAP_P_KEY                               'P_WORD_WRAP_STYLE'
#define WORD_WRAP_SHORT_KEY                           'WW'
#define WORD_WRAP_UPDATE_KEY                          WORD_WRAP_P_KEY

#define INDENT_WITH_TABS_P_KEY                        'P_INDENT_WITH_TABS'
#define INDENT_WITH_TABS_SHORT_KEY                    'IWT'
#define INDENT_WITH_TABS_UPDATE_KEY                   INDENT_WITH_TABS_P_KEY

#define SHOW_TABS_P_KEY                               'P_SHOW_TABS'
#define SHOW_TABS_SHORT_KEY                           'ST'
#define SHOW_TABS_UPDATE_KEY                          SHOW_TABS_P_KEY

#define INDENT_STYLE_P_KEY                            'P_INDENT_STYLE'
#define INDENT_STYLE_SHORT_KEY                        'IN'
#define INDENT_STYLE_UPDATE_KEY                        INDENT_STYLE_P_KEY

#define WORD_CHARS_P_KEY                              'P_WORD_CHARS'
#define WORD_CHARS_SHORT_KEY                          'WC'
#define WORD_CHARS_UPDATE_KEY                         WORD_CHARS_P_KEY

#define LEXER_NAME_P_KEY                              'P_LEXER_NAME'
#define LEXER_NAME_SHORT_KEY                          'LN'
#define LEXER_NAME_UPDATE_KEY                         LEXER_NAME_P_KEY

#define COLOR_FLAGS_P_KEY                             'P_COLOR_FLAGS'
#define COLOR_FLAGS_SHORT_KEY                         'CF'
#define COLOR_FLAGS_UPDATE_KEY                        COLOR_FLAGS_P_KEY

#define LINE_NUMBERS_LEN_P_KEY                        'P_LINE_NUMBERS_LEN'
#define LINE_NUMBERS_LEN_SHORT_KEY                    'LNL'
#define LINE_NUMBERS_LEN_UPDATE_KEY                   LINE_NUMBERS_LEN_P_KEY

#define TRUNCATE_LENGTH_P_KEY                         'P_TRUNCATELENGTH'
#define TRUNCATE_LENGTH_SHORT_KEY                     'TL'
#define TRUNCATE_LENGTH_UPDATE_KEY                    TRUNCATE_LENGTH_P_KEY

#define BOUNDS_SHORT_KEY                              'BNDS'
#define BOUNDS_UPDATE_KEY                             BOUNDS_SHORT_KEY

#define CAPS_SHORT_KEY                                'CAPS'
#define CAPS_UPDATE_KEY                               CAPS_SHORT_KEY

#define SOFT_WRAP_P_KEY                               'P_SOFTWRAP'
#define SOFT_WRAP_SHORT_KEY                           'SW'
#define SOFT_WRAP_UPDATE_KEY                          SOFT_WRAP_P_KEY

#define SOFT_WRAP_ON_WORD_P_KEY                       'P_SOFTWRAPONWORD'
#define SOFT_WRAP_ON_WORD_SHORT_KEY                   'SOW'
#define SOFT_WRAP_ON_WORD_UPDATE_KEY                  SOFT_WRAP_ON_WORD_P_KEY

#define HEX_MODE_P_KEY                                'P_HEXMODE'
#define HEX_MODE_SHORT_KEY                            'HX'
#define HEX_MODE_UPDATE_KEY                           HEX_MODE_P_KEY

#define LINE_NUMBERS_FLAGS_SHORT_KEY                  'LNF'
#define LINE_NUMBERS_FLAGS_UPDATE_KEY                 LINE_NUMBERS_FLAGS_SHORT_KEY

#define BEGIN_END_STYLE_P_KEY                         'P_BEGIN_END_STYLE'
#define BEGIN_END_STYLE_UPDATE_KEY                    BEGIN_END_STYLE_P_KEY

#define NO_SPACE_BEFORE_PAREN_P_KEY                   'P_NO_SPACE_BEFORE_PAREN'
#define NO_SPACE_BEFORE_PAREN_UPDATE_KEY              NO_SPACE_BEFORE_PAREN_P_KEY

#define INDENT_CASE_FROM_SWITCH_P_KEY                 'P_INDENT_CASE_FROM_SWITCH'
#define INDENT_CASE_FROM_SWITCH_UPDATE_KEY            INDENT_CASE_FROM_SWITCH_P_KEY

#define PAD_PARENS_P_KEY                              'P_PAD_PARENS'
#define PAD_PARENS_UPDATE_KEY                         PAD_PARENS_P_KEY

#define POINTER_STYLE_P_KEY                           'P_POINTER_STYLE'
#define POINTER_STYLE_UPDATE_KEY                      POINTER_STYLE_P_KEY

#define FUNCTION_BRACE_ON_NEW_LINE_P_KEY              'P_FUNCTION_BRACE_ON_NEW_LINE'
#define FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY         FUNCTION_BRACE_ON_NEW_LINE_P_KEY

#define KEYWORD_CASING_P_KEY                          'P_KEYWORD_CASING'
#define KEYWORD_CASING_UPDATE_KEY                     KEYWORD_CASING_P_KEY

#define TAG_CASING_P_KEY                              'P_TAG_CASING'
#define TAG_CASING_UPDATE_KEY                         TAG_CASING_P_KEY

#define ATTRIBUTE_CASING_P_KEY                        'P_ATTRIBUTE_CASING'
#define ATTRIBUTE_CASING_UPDATE_KEY                   ATTRIBUTE_CASING_P_KEY

#define VALUE_CASING_P_KEY                            'P_VALUE_CASING'
#define VALUE_CASING_UPDATE_KEY                       VALUE_CASING_P_KEY

#define HEX_VALUE_CASING_P_KEY                        'P_HEX_VALUE_CASING'
#define HEX_VALUE_CASING_UPDATE_KEY                   HEX_VALUE_CASING_P_KEY

#define ADAPTIVE_FORMATTING_FLAGS_P_KEY               'P_ADAPTIVE_FORMATTING_FLAGS'
#define ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY          ADAPTIVE_FORMATTING_FLAGS_P_KEY

#define SHOW_SPECIAL_CHARS_P_KEY                      'P_SHOWSPECIALCHARS'
#define SHOW_SPECIAL_CHARS_UPDATE_KEY                 SHOW_SPECIAL_CHARS_P_KEY

#define SYNTAX_INDENT_P_KEY                           'P_SYNTAXINDENT'
#define SYNTAX_INDENT_UPDATE_KEY                      SYNTAX_INDENT_P_KEY

// there is no p_cuddle else, we just need this for all langauges to update beautifier settings
#define CUDDLE_ELSE_UPDATE_KEY                        'P_CUDDLE_ELSE'

#endif
