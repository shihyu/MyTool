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
#pragma option(metadata,"LanguageSettings.e")
#include "slick.sh"


// these are the many items which can be ORed into the brace styles item
_metadata enum_flags BeginEndStyles {
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

//#define LOI_LAST                    LOI_RUBY_STYLE
//#define LDI_LAST                    LDI_LINE_NUMBERS_FLAGS

const WORD_CHARS_NOT_APPLICABLE=   'N/A';

// language setting keys - used to parse options strings - this seems like a lot of confusing keys, I know.
// Short keys are used to parse out options from def-language-<langId>.
// Both short keys and p_keys were used to update buffers when a setting is changed, pre-v15.
// In v15, we added the update_keys so that when you call update_buffers, you always know which one to use.  
// Not all fields have both p keys and short keys, but they do all have update keys.
// If you use one of the other keys, we will helpfully correct it to the update key.
// Is it overkill?  Maybe, but someone will thank me someday.
const MODE_NAME_P_KEY                                 = VSLANGPROPNAME_MODE_NAME;
const MODE_NAME_SHORT_KEY                             = 'MN';
const MODE_NAME_UPDATE_KEY                            = VSLANGPROPNAME_MODE_NAME;

const TABS_P_KEY                                      = VSLANGPROPNAME_TABS;
const TABS_SHORT_KEY                                  = 'TABS';
const TABS_UPDATE_KEY                                 = VSLANGPROPNAME_TABS;

const MARGINS_P_KEY                                   = VSLANGPROPNAME_MARGINS;
const MARGINS_SHORT_KEY                               = 'MA';
const MARGINS_UPDATE_KEY                              = VSLANGPROPNAME_MARGINS;

const KEY_TABLE_P_KEY                                 = VSLANGPROPNAME_EVENTTAB_NAME;
const KEY_TABLE_SHORT_KEY                             = 'KEYTAB';
const KEY_TABLE_UPDATE_KEY                            = VSLANGPROPNAME_EVENTTAB_NAME;

const WORD_WRAP_P_KEY                                 = VSLANGPROPNAME_WORD_WRAP_FLAGS;
const WORD_WRAP_SHORT_KEY                             = 'WW';
const WORD_WRAP_UPDATE_KEY                            = VSLANGPROPNAME_WORD_WRAP_FLAGS;

const INDENT_WITH_TABS_P_KEY                          = VSLANGPROPNAME_INDENT_WITH_TABS;
const INDENT_WITH_TABS_SHORT_KEY                      = 'IWT';
const INDENT_WITH_TABS_UPDATE_KEY                     = VSLANGPROPNAME_INDENT_WITH_TABS;

const SHOW_TABS_P_KEY                                 = VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS;
const SHOW_TABS_SHORT_KEY                             = 'ST';
const SHOW_TABS_UPDATE_KEY                            = VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS;

const INDENT_STYLE_P_KEY                              = VSLANGPROPNAME_INDENT_STYLE;
const INDENT_STYLE_SHORT_KEY                          = 'IN';
const INDENT_STYLE_UPDATE_KEY                         = VSLANGPROPNAME_INDENT_STYLE;

const WORD_CHARS_P_KEY                                = VSLANGPROPNAME_WORD_CHARS;
const WORD_CHARS_SHORT_KEY                            = 'WC';
const WORD_CHARS_UPDATE_KEY                           = VSLANGPROPNAME_WORD_CHARS;

const LEXER_NAME_P_KEY                                = VSLANGPROPNAME_LEXER_NAME;
const LEXER_NAME_SHORT_KEY                            = 'LN';
const LEXER_NAME_UPDATE_KEY                           = VSLANGPROPNAME_LEXER_NAME;

const COLOR_FLAGS_P_KEY                               = VSLANGPROPNAME_COLOR_FLAGS;
const COLOR_FLAGS_SHORT_KEY                           = 'CF';
const COLOR_FLAGS_UPDATE_KEY                          = VSLANGPROPNAME_COLOR_FLAGS;

const LINE_NUMBERS_LEN_P_KEY                          = VSLANGPROPNAME_LINE_NUMBERS_LEN;
const LINE_NUMBERS_LEN_SHORT_KEY                      = 'LNL';
const LINE_NUMBERS_LEN_UPDATE_KEY                     = VSLANGPROPNAME_LINE_NUMBERS_LEN;

const TRUNCATE_LENGTH_P_KEY                           = VSLANGPROPNAME_TRUNCATE_LENGTH;
const TRUNCATE_LENGTH_SHORT_KEY                       = 'TL';
const TRUNCATE_LENGTH_UPDATE_KEY                      = VSLANGPROPNAME_TRUNCATE_LENGTH;

const BOUNDS_SHORT_KEY                                = 'BNDS';
const BOUNDS_UPDATE_KEY                               = VSLANGPROPNAME_BOUNDS;

const DIFFCOL_SHORT_KEY                               = 'DIFFCOL';
const DIFFCOL_UPDATE_KEY                              = VSLANGPROPNAME_DIFF_COLUMNS;

const CAPS_SHORT_KEY                                  = 'CAPS';
const CAPS_UPDATE_KEY                                 = VSLANGPROPNAME_AUTO_CAPS;

const SHOW_MINIMAP_P_KEY                              = VSLANGPROPNAME_SHOW_MINIMAP;
const SHOW_MINIMAP_SHORT_KEY                          = 'SM';
const SHOW_MINIMAP_UPDATE_KEY                         = VSLANGPROPNAME_SHOW_MINIMAP;

const SOFT_WRAP_P_KEY                                 = VSLANGPROPNAME_SOFT_WRAP;
const SOFT_WRAP_SHORT_KEY                             = 'SW';
const SOFT_WRAP_UPDATE_KEY                            = VSLANGPROPNAME_SOFT_WRAP;

const SOFT_WRAP_ON_WORD_P_KEY                         = VSLANGPROPNAME_SOFT_WRAP_ON_WORD;
const SOFT_WRAP_ON_WORD_SHORT_KEY                     = 'SOW';
const SOFT_WRAP_ON_WORD_UPDATE_KEY                    = VSLANGPROPNAME_SOFT_WRAP_ON_WORD;

const HEX_MODE_P_KEY                                  = VSLANGPROPNAME_HEX_MODE;
const HEX_MODE_SHORT_KEY                              = 'HX';
const HEX_MODE_UPDATE_KEY                             = VSLANGPROPNAME_HEX_MODE;

const HEX_NOFCOLS_P_KEY                               = VSLANGPROPNAME_HEX_NOFCOLS;
const HEX_NOFCOLS_SHORT_KEY                           = 'HNC';
const HEX_NOFCOLS_UPDATE_KEY                          = VSLANGPROPNAME_HEX_NOFCOLS;

const HEX_BYTES_PER_COL_P_KEY                         = VSLANGPROPNAME_HEX_BYTES_PER_COL;
const HEX_BYTES_PER_COL_SHORT_KEY                     = 'HBC';
const HEX_BYTES_PER_COL_UPDATE_KEY                    = VSLANGPROPNAME_HEX_BYTES_PER_COL;

const LINE_NUMBERS_FLAGS_SHORT_KEY                    = 'LNF';
const LINE_NUMBERS_FLAGS_UPDATE_KEY                   = VSLANGPROPNAME_LINE_NUMBERS_FLAGS;

const BEGIN_END_STYLE_P_KEY                           = LOI_BEGIN_END_STYLE;
const BEGIN_END_STYLE_UPDATE_KEY                      = LOI_BEGIN_END_STYLE;

const NO_SPACE_BEFORE_PAREN_P_KEY                     = LOI_NO_SPACE_BEFORE_PAREN;
const NO_SPACE_BEFORE_PAREN_UPDATE_KEY                = LOI_NO_SPACE_BEFORE_PAREN;

const INDENT_CASE_FROM_SWITCH_P_KEY                   = LOI_INDENT_CASE_FROM_SWITCH;
const INDENT_CASE_FROM_SWITCH_UPDATE_KEY              = LOI_INDENT_CASE_FROM_SWITCH;

const PAD_PARENS_P_KEY                                = LOI_PAD_PARENS;
const PAD_PARENS_UPDATE_KEY                           = LOI_PAD_PARENS;

const POINTER_STYLE_P_KEY                             = LOI_POINTER_STYLE;
const POINTER_STYLE_UPDATE_KEY                        = LOI_POINTER_STYLE;

const FUNCTION_BRACE_ON_NEW_LINE_P_KEY                = LOI_FUNCTION_BEGIN_ON_NEW_LINE;
const FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY           = LOI_FUNCTION_BEGIN_ON_NEW_LINE;

const KEYWORD_CASING_P_KEY                            = LOI_KEYWORD_CASE;
const KEYWORD_CASING_UPDATE_KEY                       = LOI_KEYWORD_CASE;

const TAG_CASING_P_KEY                                = LOI_TAG_CASE;
const TAG_CASING_UPDATE_KEY                           = LOI_TAG_CASE;

const ATTRIBUTE_CASING_P_KEY                          = LOI_ATTRIBUTE_CASE;
const ATTRIBUTE_CASING_UPDATE_KEY                     = LOI_ATTRIBUTE_CASE;

const VALUE_CASING_P_KEY                              = LOI_WORD_VALUE_CASE;
const VALUE_CASING_UPDATE_KEY                         = LOI_WORD_VALUE_CASE;

const HEX_VALUE_CASING_P_KEY                          = LOI_HEX_VALUE_CASE;
const HEX_VALUE_CASING_UPDATE_KEY                     = LOI_HEX_VALUE_CASE;

const ADAPTIVE_FORMATTING_FLAGS_P_KEY                 = VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS;
const ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY            = VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS;

const SHOW_SPECIAL_CHARS_P_KEY                        = VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS;
const SHOW_SPECIAL_CHARS_UPDATE_KEY                   = VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS;

const SYNTAX_INDENT_P_KEY                             = LOI_SYNTAX_INDENT;
const SYNTAX_INDENT_UPDATE_KEY                        = LOI_SYNTAX_INDENT;

// there is no p_cuddle else, we just need this for all langauges to update beautifier settings
const CUDDLE_ELSE_UPDATE_KEY                          = LOI_CUDDLE_ELSE;

const AUTO_LEFT_MARGIN_P_KEY                          = VSLANGPROPNAME_AUTO_LEFT_MARGIN;
const AUTO_LEFT_MARGIN_SHORT_KEY                      = 'ALM';
const AUTO_LEFT_MARGIN_UPDATE_KEY                     = VSLANGPROPNAME_AUTO_LEFT_MARGIN;

const FIXED_WIDTH_RIGHT_MARGIN_P_KEY                  = VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN;
const FIXED_WIDTH_RIGHT_MARGIN_SHORT_KEY              = 'ALM';
const FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY             = VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN;

