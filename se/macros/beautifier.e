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
#include "slick.sh"
#import "adaptiveformatting.e"
#import "c.e"
#import "cfg.e"
#import "cformat.e"
#import "clipbd.e"
#import "codehelp.e"
#import "guicd.e"
#import "config.e"
#import "context.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "hformat.e"
#import "hotspots.e"
#import "java.e"
#import "listbox.e"
#import "markfilt.e"
#import "main.e"
#import "xmldoc.e"
#import "menu.e"
#import "mouse.e"
#import "mprompt.e"
#import "picture.e"
#import "pmatch.e"
#import "put.e"
#import "sellist.e"
#import "setupext.e"
#import "smartp.e"
#import "stdcmds.e"
#import "surround.e"
#import "stdprocs.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "xml.e"
#import "xmlwrapgui.e"
#import "sellist2.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/options/OptionsConfigTree.e"
#require "se/options/Property.e"
#require "se/ui/IKeyEventCallback.e"
#require "se/ui/EventUI.e"
#require "se/ui/TextChange.e"


using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;
using se.options.Property;
using se.ui.EventUI;
using se.ui.TextChangeNotify;

const BEAUTIFIER_DEFAULT_PROFILE =          "Default";
const BEAUT_DEFAULT_TAG_NAME= "(default tag)";

//#define VSCFGP_BEAUTIFIER_MAX_LINE_LEN "max_line_len"
//#define VSCFGP_BEAUTIFIER_MAX_LINE_LEN "max_line_len"

// All languages supported by the new beautifier.
_str ALL_BEAUT_LANGUAGES[] = {'c', 'm', 'java', 'scala', 'cs', 'js', 'xml', 'xhtml', 'phpscript', 'html', 'docbook', 'bas', 'vbs', 'cfml', 'vpj', 'xsd', 'ant',
                              'android', 'tld', 'py', 'systemverilog','verilog', 'groovy', 'json'};



extern int _beautifier_save_profile(int ibeautifier, _str escapedProfilePackage, _str profileName);

extern int _beautifier_set_properties(int ibeautifier,_str escapedProfilePackage,_str profileName,bool clear=true);

extern int _beautifier_delete_property(int ibeautifier,_str name,bool matchPrefix=false);

extern _str _beautifier_get_property(int ibeautifier,_str name, _str defaultValue='', bool &apply=null);

extern void _beautifier_set_property(int ibeautifier,_str name,_str value,bool apply=null);

extern void _beautifier_list_properties(int ibeautifier,XmlCfgPropertyInfo (&array)[], _str matchNamePrefix='',_str matchNameSearchOptions=null,_str matchValue=null,_str matchValueSearchOptions=null);

extern void _beautifier_destroy(int ibeautifier);

extern int _beautifier_create(_str langId);

extern int _beautifier_reformat_buffer(int ibeautifier, int wid, long (&locations)[], long (&cursor_indices)[], int beaut_flags);

extern int _beautifier_reformat_selection(int ibeautifier, int wid, long (&locations)[],
                                   long (&cursor_indices)[],
                                   long start_offset, long end_offset, int initial_indent,
                                   int beaut_flags);


static const USER_BEAUTIFIER_PROFILES_FILE=    'vusr_beautifier.xml';

// Combo box option values.
//const CBV_NO = "No Spaces";
//const CBV_B  = "Space Before";
//const CBV_A  = "Space After";
//const CBV_BA = "Space Before & After";
//const CBV_Y  = "Yes";
//const CBV_N  = "No";
//const CBV_NSB = "No Space Before";
//const CBV_NSA = "No Space After";
const CBV_AL_PARENS = "Align on Parens";
const CBV_AL_CONT = "Continuation Indent";
const CBV_AL_AUTO = "Auto";

//const CBV_IN_TABS = "Tabs";
//const CBV_IN_SPACES = "Spaces";

const CBV_SAMELINE = "Same Line";
const CBV_NEXTLINE = "Next Line";
const CBV_NEXTLINE_IN = "Next Line Indented";

//const CBV_ALLEXP = "All Expressions";
//const CBV_CMPLX_EXP = "Complex Expressions";
//const CBV_NONE = "None";

// Extra beautifier flag we use internally to this module.
static const BEAUT_FLAG_EXACT_CONTEXT= 0x8000;                     // Don't try to be clever with leading context.  Be sure.

// Buffer name we use for cacheing configuration conversions.
static const SETUP_BUFFER = 'setup_buffer';                        

// Unique values for the different combo box entries we support.
//const COMBO_Y = 1;
//const COMBO_N = 0;
//const COMBO_NSB = 6;
//const COMBO_NSA = 7;

//const COMBO_IN_SPACES = 0;
//const COMBO_IN_TABS = 1;

//const COMBO_ALLEXP = 16;
//const COMBO_CMPLX_EXP = 17;
//const COMBO_NONE = 18;
//const COMBO_AL_SEL_COLON=19;
//const COMBO_AL_SEL_NAME=20;

//const COMBO_MULTILINE_NO=24;


_metadata const COMBO_NO = 0; // no spaces
_metadata const COMBO_B = 1;  // space before
_metadata const COMBO_A = 2;  // space after
_metadata const COMBO_BA = 3; // space before & after

_metadata const COMBO_AL_PARENS = FPAS_ALIGN_ON_PARENS;
_metadata const COMBO_AL_CONT = FPAS_CONTINUATION_INDENT;
_metadata const COMBO_AL_AUTO = FPAS_AUTO;


_metadata const COMBO_REMOVE_PARENS=0;
_metadata const COMBO_FORCE_PARENS=1;
_metadata const COMBO_FORCE_PARENS_IF_COMPLEX=2;

_metadata const COMBO_SAMELINE = 0;
_metadata const COMBO_NEXTLINE = 1;
_metadata const COMBO_NEXTLINE_IN = 2;
_metadata const COMBO_BL_USE_STATEMENT_SETTING = 10;



_metadata const LEFT_JUSTIFICATION=0;
_metadata const RIGHT_JUSTIFICATION=1;

// Map from language id to option array.
static int gLanguageOptionsCache:[];
static int gProfileEditForm;

/**
 * If nonzero, will use information from statement tagging when
 * making decisions about how much leading context a
 * selection/snippet will need for the beautifier to evaluate it
 * correctly.
 */
int def_beautifier_usetaginfo = 1;

/**
 * If ==0, the beautifier will ignore the brace style discovered
 * by adaptive formatting.
 *
 * if !=0, the beautifier will take the brace style discovered
 * by adaptive formatting, and apply it to all of the beautifier
 * brace styles, effectively homogenizing them.
 *
 */
int def_beautifier_aff_bracestyle = 1;

// Sometimes we want to quash the beautify-on-copy behavior
// when we're updating preview windows.
static int gAllowBeautifyCopy = 1;

static _str gLangId = '';

definit()
{
   gLanguageOptionsCache._makeempty();
   gProfileEditForm = 0;
   def_beautifier_debug = 0;
   gAllowBeautifyCopy = 1;
   gLangId = '';
}


// Trailing comments radio button values.
_metadata enum TrailingComment { TC_ABS_COL = 0, TC_ORIG_ABS_COL, TC_ORIG_REL_INDENT};

// _gibeautifier holds beautifier settings while we're editing profile
int _gibeautifier;

const VSCFGP_BEAUTIFIER_SYNTAX_INDENT= "syntax_indent";
const VSCFGP_BEAUTIFIER_TAB_SIZE= "tab_size";
const VSCFGP_BEAUTIFIER_INDENT_WITH_TABS= "indent_with_tabs";
const VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS= "indent_member_access";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_MEMBER_ACCESS= "indent_width_member_access";
const VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS_RELATIVE= "indent_member_access_relative";
const VSCFGP_BEAUTIFIER_INDENT_CASE= "indent_case";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_CASE= "indent_width_case";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION= "indent_width_continuation";
const VSCFGP_BEAUTIFIER_LISTALIGN_FUN_CALL_PARAMS= "listalign_fun_call_params";
const VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AT_EOF= "require_new_line_at_eof";
const VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE= "original_tab_size";
const VSCFGP_BEAUTIFIER_RM_TRAILING_SPACES= "rm_trailing_spaces";
const VSCFGP_BEAUTIFIER_RM_DUP_SPACES= "rm_dup_spaces";
const VSCFGP_BEAUTIFIER_MAX_LINE_LEN= "max_line_len";
const VSCFGP_BEAUTIFIER_PP_INDENT= "pp_indent";
const VSCFGP_BEAUTIFIER_PP_INDENT_IN_CODE_BLOCK= "pp_indent_in_code_block";
const VSCFGP_BEAUTIFIER_PP_INDENT_IN_HEADER_GUARD= "pp_indent_in_header_guard";
const VSCFGP_BEAUTIFIER_PP_KEEP_POUND_IN_COL1= "pp_keep_pound_in_col1";
const VSCFGP_BEAUTIFIER_PP_INDENT_WITH_CODE= "pp_indent_with_code";
const VSCFGP_BEAUTIFIER_ALIGN_TRINARY_BRANCHES= "align_trinary_branches";
const VSCFGP_BEAUTIFIER_NL_EMPTY_BLOCK= "nl_empty_block";
const VSCFGP_BEAUTIFIER_SPPAD_CATCH_PARENS= "sppad_catch_parens";
const VSCFGP_BEAUTIFIER_SP_SWITCH_BEFORE_LPAREN= "sp_switch_before_lparen";
const VSCFGP_BEAUTIFIER_SP_ARRAY_EXPR_BEFORE_LBRACKET= "sp_array_expr_before_lbracket";
const VSCFGP_BEAUTIFIER_SP_ARRAY_DECL_BEFORE_LBRACKET= "sp_array_decl_before_lbracket";
const VSCFGP_BEAUTIFIER_ONELINE_DOWHILE= "oneline_dowhile";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_BITWISE= "spstyle_op_bitwise";
const VSCFGP_BEAUTIFIER_ONELINE_CATCH= "oneline_catch";
const VSCFGP_BEAUTIFIER_SP_FOR_BEFORE_LPAREN= "sp_for_before_lparen";
const VSCFGP_BEAUTIFIER_SP_FUN_CALL_EMPTY_PARENS= "sp_fun_call_empty_parens";
const VSCFGP_BEAUTIFIER_SPPAD_SWITCH_PARENS= "sppad_switch_parens";
const VSCFGP_BEAUTIFIER_SPPAD_FUN_PARENS= "sppad_fun_parens";
const VSCFGP_BEAUTIFIER_SP_IF_AFTER_RPAREN= "sp_if_after_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_ASSIGNMENT= "spstyle_op_assignment";
const VSCFGP_BEAUTIFIER_SPSTYLE_FOR_COMMA= "spstyle_for_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_FUN_CALL_COMMA= "spstyle_fun_call_comma";
const VSCFGP_BEAUTIFIER_SP_ARRAY_EXPR_AFTER_RBRACKET= "sp_array_expr_after_rbracket";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_MULT= "spstyle_op_mult";
const VSCFGP_BEAUTIFIER_SP_ARRAY_DECL_AFTER_RBRACKET= "sp_array_decl_after_rbracket";
const VSCFGP_BEAUTIFIER_SPSTYLE_FOR_LBRACE= "spstyle_for_lbrace";
const VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_THEN= "oneline_unblocked_then";
const VSCFGP_BEAUTIFIER_SP_CATCH_BEFORE_LPAREN= "sp_catch_before_lparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_MEMBER_DOT= "spstyle_member_dot";
const VSCFGP_BEAUTIFIER_SP_FOR_AFTER_RPAREN= "sp_for_after_rparen";
const VSCFGP_BEAUTIFIER_SP_WHILE_AFTER_RPAREN= "sp_while_after_rparen";
const VSCFGP_BEAUTIFIER_SP_RETURN_BEFORE_LPAREN= "sp_return_before_lparen";
const VSCFGP_BEAUTIFIER_SP_THROW_BEFORE_LPAREN= "sp_throw_before_lparen";
const VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_STATEMENT= "oneline_unblocked_statement";
const VSCFGP_BEAUTIFIER_ONELINE_ELSEIF= "oneline_elseif";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_UNARY= "spstyle_op_unary";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_BINARY= "spstyle_op_binary";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_COMPARISON= "spstyle_op_comparison";
const VSCFGP_BEAUTIFIER_SP_CATCH_AFTER_RPAREN= "sp_catch_after_rparen";
const VSCFGP_BEAUTIFIER_SP_FUN_BEFORE_LPAREN= "sp_fun_before_lparen";
const VSCFGP_BEAUTIFIER_SP_FUN_EMPTY_PARENS= "sp_fun_empty_parens";
const VSCFGP_BEAUTIFIER_SPSTYLE_WHILE_LBRACE= "spstyle_while_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_SWITCH_LBRACE= "spstyle_switch_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_LOGICAL= "spstyle_op_logical";
const VSCFGP_BEAUTIFIER_SPSTYLE_FOR_SEMICOLON= "spstyle_for_semicolon";
const VSCFGP_BEAUTIFIER_NL_EMPTY_FUN_BODY= "nl_empty_fun_body";
const VSCFGP_BEAUTIFIER_SP_FUN_CALL_AFTER_RPAREN= "sp_fun_call_after_rparen";
const VSCFGP_BEAUTIFIER_SP_FUN_CALL_BEFORE_LPAREN= "sp_fun_call_before_lparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_FUN_COMMA= "spstyle_fun_comma";
const VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_DECL= "leave_multiple_decl";
const VSCFGP_BEAUTIFIER_SPSTYLE_CATCH_LBRACE= "spstyle_catch_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_FUN_LBRACE= "spstyle_fun_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_IF_LBRACE= "spstyle_if_lbrace";
const VSCFGP_BEAUTIFIER_SPPAD_FOR_PARENS= "sppad_for_parens";
const VSCFGP_BEAUTIFIER_SP_SWITCH_AFTER_RPAREN= "sp_switch_after_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_PREFIX= "spstyle_op_prefix";
const VSCFGP_BEAUTIFIER_SPPAD_FUN_CALL_PARENS= "sppad_fun_call_parens";
const VSCFGP_BEAUTIFIER_SPPAD_WHILE_PARENS= "sppad_while_parens";
const VSCFGP_BEAUTIFIER_SP_WHILE_BEFORE_LPAREN= "sp_while_before_lparen";
const VSCFGP_BEAUTIFIER_SP_FUN_AFTER_RPAREN= "sp_fun_after_rparen";
const VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_STMT= "leave_multiple_stmt";
const VSCFGP_BEAUTIFIER_SPPAD_ARRAY_EXPR_BRACKETS= "sppad_array_expr_brackets";
const VSCFGP_BEAUTIFIER_SPPAD_ARRAY_DECL_BRACKETS= "sppad_array_decl_brackets";
const VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_ELSE= "oneline_unblocked_else";
const VSCFGP_BEAUTIFIER_NL_AFTER_CASE= "nl_after_case";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_POSTFIX= "spstyle_op_postfix";
const VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN= "sp_if_before_lparen";
const VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS= "sppad_if_parens";
const VSCFGP_BEAUTIFIER_INDENT_FIRST_LEVEL= "indent_first_level";
const VSCFGP_BEAUTIFIER_INDENT_LABEL= "indent_label";
const VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP= "align_on_assignment_op";
const VSCFGP_BEAUTIFIER_LISTALIGN2_EXPR_PARENS= "listalign2_expr_parens";
const VSCFGP_BEAUTIFIER_BRACELOC_IF= "braceloc_if";
const VSCFGP_BEAUTIFIER_BRACELOC_FOR= "braceloc_for";
const VSCFGP_BEAUTIFIER_BRACELOC_WHILE= "braceloc_while";
const VSCFGP_BEAUTIFIER_BRACELOC_SWITCH= "braceloc_switch";
const VSCFGP_BEAUTIFIER_BRACELOC_DO= "braceloc_do";
const VSCFGP_BEAUTIFIER_BRACELOC_TRY= "braceloc_try";
const VSCFGP_BEAUTIFIER_BRACELOC_CASE= "braceloc_case";
const VSCFGP_BEAUTIFIER_BRACELOC_CATCH= "braceloc_catch";
const VSCFGP_BEAUTIFIER_BRACELOC_FUN= "braceloc_fun";
const VSCFGP_BEAUTIFIER_INDENT_COMMENTS= "indent_comments";
const VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS= "indent_col1_comments";
const VSCFGP_BEAUTIFIER_LEAVE_ONE_LINE_CODE_BLOCKS= "leave_one_line_code_blocks";
const VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE= "nl_before_else";
const VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE= "trailing_comment_style";
const VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL= "trailing_comment_col";
const VSCFGP_BEAUTIFIER_INDENT_FROM_BRACE= "indent_from_brace";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_LABEL= "indent_width_label";
const VSCFGP_BEAUTIFIER_SPPAD_RETURN_PARENS= "sppad_return_parens";
const VSCFGP_BEAUTIFIER_SP_RETURN_AFTER_RPAREN= "sp_return_after_rparen";
const VSCFGP_BEAUTIFIER_SPPAD_THROW_PARENS= "sppad_throw_parens";
const VSCFGP_BEAUTIFIER_SP_THROW_AFTER_RPAREN= "sp_throw_after_rparen";
const VSCFGP_BEAUTIFIER_SP_EXPR_BEFORE_LPAREN= "sp_expr_before_lparen";
const VSCFGP_BEAUTIFIER_SPPAD_EXPR_PARENS= "sppad_expr_parens";
const VSCFGP_BEAUTIFIER_SP_EXPR_AFTER_RPAREN= "sp_expr_after_rparen";
const VSCFGP_BEAUTIFIER_SP_STMT_AFTER_SEMICOLON= "sp_stmt_after_semicolon";
const VSCFGP_BEAUTIFIER_SPSTYLE_TRY_LBRACE= "spstyle_try_lbrace";
const VSCFGP_BEAUTIFIER_ALIGN_LBRACE_WITH_CASE= "align_lbrace_with_case";
const VSCFGP_BEAUTIFIER_INDENT_IF_OF_ELSE_IF= "indent_if_of_else_if";
const VSCFGP_BEAUTIFIER_RA_THROW_PARENS= "ra_throw_parens";
const VSCFGP_BEAUTIFIER_RAI_RETURN_PARENS= "rai_return_parens";
const VSCFGP_BEAUTIFIER_RA_FUN_VOID_IN_EMPTY_PARAM_LIST= "ra_fun_void_in_empty_param_list";
const VSCFGP_BEAUTIFIER_SP_CAST_BEFORE_LPAREN= "sp_cast_before_lparen";
const VSCFGP_BEAUTIFIER_SPPAD_CAST_PARENS= "sppad_cast_parens";
const VSCFGP_BEAUTIFIER_SP_CAST_AFTER_RPAREN= "sp_cast_after_rparen";
const VSCFGP_BEAUTIFIER_BL_BEFORE_CASE= "bl_before_case";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_SWITCH= "bl_after_start_block_switch";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_IF= "bl_after_start_block_if";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_IF= "bl_after_end_block_if";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_FOR= "bl_after_start_block_for";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_FOR= "bl_after_end_block_for";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_WHILE= "bl_after_start_block_while";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_WHILE= "bl_after_end_block_while";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_DO= "bl_after_start_block_do";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_DO= "bl_after_end_block_do";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_SWITCH= "bl_after_end_block_switch";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_TRY= "bl_after_start_block_try";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_CATCH= "bl_after_start_block_catch";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_CATCH= "bl_after_end_block_catch";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_FUN= "bl_after_start_block_fun";
const VSCFGP_BEAUTIFIER_BL_BEFORE_LOCALS= "bl_before_locals";
const VSCFGP_BEAUTIFIER_BL_AFTER_LOCALS= "bl_after_locals";
const VSCFGP_BEAUTIFIER_JUSTIFY_VAR_DECLS= "justify_var_decls";
const VSCFGP_BEAUTIFIER_BRACELOC_MULTILINE_COND= "braceloc_multiline_cond";
const VSCFGP_BEAUTIFIER_SP_STMT_BEFORE_SEMICOLON= "sp_stmt_before_semicolon";
const VSCFGP_BEAUTIFIER_SPSTYLE_ENUM_LBRACE= "spstyle_enum_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_ENUM_CONST_COMMA= "spstyle_enum_const_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_FUN_COLON= "spstyle_fun_colon";
const VSCFGP_BEAUTIFIER_NL_EMPTY_CLASS_BODY= "nl_empty_class_body";
const VSCFGP_BEAUTIFIER_LEAVE_CLASS_ONE_LINE_BLOCK= "leave_class_one_line_block";
const VSCFGP_BEAUTIFIER_SPSTYLE_CLASS_LBRACE= "spstyle_class_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_CLASS_COMMA= "spstyle_class_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_CLASS_COLON= "spstyle_class_colon";
const VSCFGP_BEAUTIFIER_BRACELOC_CLASS= "braceloc_class";
const VSCFGP_BEAUTIFIER_INDENT_CLASS_BODY= "indent_class_body";
const VSCFGP_BEAUTIFIER_BL_BEFORE_FIRST_DECL= "bl_before_first_decl";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_FUNS= "bl_between_funs";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_MEMBER_VAR_DECLS= "bl_between_member_var_decls";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_COMMENTED_MEMBER_VAR_DECLS= "bl_between_commented_member_var_decls";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_MEMBER_CLASSES= "bl_between_member_classes";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_DIFFERENT_DECLS= "bl_between_different_decls";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_CLASSES= "bl_between_classes";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_FUN_PROTOTYPES= "bl_between_fun_prototypes";
const VSCFGP_BEAUTIFIER_JUSTIFY_MEMBER_VAR_DECLS= "justify_member_var_decls";
const VSCFGP_BEAUTIFIER_SP_TMPL_DECL_BEFORE_LT= "sp_tmpl_decl_before_lt";
const VSCFGP_BEAUTIFIER_SPPAD_TMPL_DECL_ANGLE_BRACKETS= "sppad_tmpl_decl_angle_brackets";
const VSCFGP_BEAUTIFIER_SPSTYLE_TMPL_DECL_COMMA= "spstyle_tmpl_decl_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_TMPL_DECL_EQ= "spstyle_tmpl_decl_eq";
const VSCFGP_BEAUTIFIER_SP_TMPL_PARM_BEFORE_LT= "sp_tmpl_parm_before_lt";
const VSCFGP_BEAUTIFIER_SPPAD_TMPL_PARM_ANGLE_BRACKETS= "sppad_tmpl_parm_angle_brackets";
const VSCFGP_BEAUTIFIER_SPSTYLE_TMPLPARM_COMMA= "spstyle_tmplparm_comma";
const VSCFGP_BEAUTIFIER_JD_FORMAT_HTML= "jd_format_html";
const VSCFGP_BEAUTIFIER_JD_FORMAT_PRE= "jd_format_pre";
const VSCFGP_BEAUTIFIER_JD_INDENT_PARAM_DESC= "jd_indent_param_desc";
const VSCFGP_BEAUTIFIER_JD_INDENT_PAST_PARAM_NAME= "jd_indent_past_param_name";
const VSCFGP_BEAUTIFIER_JD_NL_AT_START_AND_END= "jd_nl_at_start_and_end";
const VSCFGP_BEAUTIFIER_JD_BL_BEFORE_TAGS= "jd_bl_before_tags";
const VSCFGP_BEAUTIFIER_JD_RM_BLANK_LINES= "jd_rm_blank_lines";
const VSCFGP_BEAUTIFIER_JD_BL_BETWEEN_DIFFERENT_TAGS= "jd_bl_between_different_tags";
const VSCFGP_BEAUTIFIER_JD_BL_BETWEEN_SAME_TAGS= "jd_bl_between_same_tags";
const VSCFGP_BEAUTIFIER_DOX_FORMAT_PRE= "dox_format_pre";
const VSCFGP_BEAUTIFIER_DOX_INDENT_PARAM_DESC= "dox_indent_param_desc";
const VSCFGP_BEAUTIFIER_DOX_INDENT_PAST_PARAM_NAME= "dox_indent_past_param_name";
const VSCFGP_BEAUTIFIER_DOX_NL_AT_START_AND_END= "dox_nl_at_start_and_end";
const VSCFGP_BEAUTIFIER_DOX_BL_AFTER_BRIEF= "dox_bl_after_brief";
const VSCFGP_BEAUTIFIER_DOX_RM_BLANK_LINES= "dox_rm_blank_lines";
const VSCFGP_BEAUTIFIER_DOX_BL_BETWEEN_DIFFERENT_TAGS= "dox_bl_between_different_tags";
const VSCFGP_BEAUTIFIER_DOX_BL_BETWEEN_SAME_TAGS= "dox_bl_between_same_tags";
const VSCFGP_BEAUTIFIER_XDOC_FORMAT_PRE= "xdoc_format_pre";
const VSCFGP_BEAUTIFIER_XDOC_BL_BETWEEN_DIFFERENT_TAGS= "xdoc_bl_between_different_tags";
const VSCFGP_BEAUTIFIER_XDOC_BL_BETWEEN_SAME_TAGS= "xdoc_bl_between_same_tags";
const VSCFGP_BEAUTIFIER_XDOC_RM_BLANK_LINES= "xdoc_rm_blank_lines";
const VSCFGP_BEAUTIFIER_XDOC_NL_AFTER_OPEN_TAG= "xdoc_nl_after_open_tag";
const VSCFGP_BEAUTIFIER_XDOC_NL_BEFORE_CLOSE_TAG= "xdoc_nl_before_close_tag";
const VSCFGP_BEAUTIFIER_SPSTYLE_INIT_COMMA= "spstyle_init_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_DOTSTAR= "spstyle_op_dotstar";
const VSCFGP_BEAUTIFIER_SP_MPTR_BETWEEN_COLONCOLON_AND_STAR= "sp_mptr_between_coloncolon_and_star";
const VSCFGP_BEAUTIFIER_SPPAD_ARRAY_DEL_BRACKETS= "sppad_array_del_brackets";
const VSCFGP_BEAUTIFIER_SPPAD_CPPCAST_ANGLE_BRACKETS= "sppad_cppcast_angle_brackets";
const VSCFGP_BEAUTIFIER_SP_REF_BETWEEN_AMP_AND_RPAREN= "sp_ref_between_amp_and_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_DASHGTSTAR= "spstyle_op_dashgtstar";
const VSCFGP_BEAUTIFIER_NL_AFTER_EXTERN= "nl_after_extern";
const VSCFGP_BEAUTIFIER_SPSTYLE_STRUCT_COMMA= "spstyle_struct_comma";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_TYPE_AND_STAR= "sp_ptr_between_type_and_star";
const VSCFGP_BEAUTIFIER_SPSTYLE_FUN_EQ= "spstyle_fun_eq";
const VSCFGP_BEAUTIFIER_SP_ARRAY_DEL_RBRACKET= "sp_array_del_rbracket";
const VSCFGP_BEAUTIFIER_SP_REF_BETWEEN_AMP_AND_ID= "sp_ref_between_amp_and_id";
const VSCFGP_BEAUTIFIER_SP_NEW_BEFORE_LPAREN= "sp_new_before_lparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_STRUCT_COLON= "spstyle_struct_colon";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_RPAREN= "sp_ptr_between_star_and_rparen";
const VSCFGP_BEAUTIFIER_SP_FUN_CALL_AFTER_OPERATOR= "sp_fun_call_after_operator";
const VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AFTER_MEMBER_ACCESS= "require_new_line_after_member_access";
const VSCFGP_BEAUTIFIER_SP_CPPCAST_AFTER_GT= "sp_cppcast_after_gt";
const VSCFGP_BEAUTIFIER_SPSTYLE_CONSTR_INIT_LIST_COMMA= "spstyle_constr_init_list_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_INIT_LIST_COMMA= "spstyle_init_list_comma";
const VSCFGP_BEAUTIFIER_SP_FUN_AFTER_OPERATOR= "sp_fun_after_operator";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_STAR= "sp_ptr_between_star_and_star";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_ID= "sp_ptr_between_star_and_id";
const VSCFGP_BEAUTIFIER_SPSTYLE_UNION_BEFORE_LBRACE= "spstyle_union_before_lbrace";
const VSCFGP_BEAUTIFIER_SP_NEW_AFTER_RPAREN= "sp_new_after_rparen";
const VSCFGP_BEAUTIFIER_SPPAD_NEW_PARENS= "sppad_new_parens";
const VSCFGP_BEAUTIFIER_SPSTYLE_ENUM_CONST_EQ= "spstyle_enum_const_eq";
const VSCFGP_BEAUTIFIER_SP_CPPCAST_BEFORE_LT= "sp_cppcast_before_lt";
const VSCFGP_BEAUTIFIER_SPSTYLE_ENUM_COLON= "spstyle_enum_colon";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_LPAREN= "sp_ptr_between_star_and_lparen";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_AMP= "sp_ptr_between_star_and_amp";
const VSCFGP_BEAUTIFIER_SP_REF_BETWEEN_TYPE_AND_AMP= "sp_ref_between_type_and_amp";
const VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_QUALIFIER= "sp_ptr_between_star_and_qualifier";
const VSCFGP_BEAUTIFIER_SP_ARRAY_DEL_BEFORE_LBRACKET= "sp_array_del_before_lbracket";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_DEREFERENCE= "spstyle_op_dereference";
const VSCFGP_BEAUTIFIER_SPSTYLE_STRUCT_LBRACE= "spstyle_struct_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_DASHGT= "spstyle_op_dashgt";
const VSCFGP_BEAUTIFIER_SP_FPTR_BETWEEN_STAR_AND_ID= "sp_fptr_between_star_and_id";
const VSCFGP_BEAUTIFIER_SP_REF_BETWEEN_AMP_AND_LPAREN= "sp_ref_between_amp_and_lparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_INIT_RBRACE= "spstyle_init_rbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_OP_ADDRESSOF= "spstyle_op_addressof";
const VSCFGP_BEAUTIFIER_INDENT_EXTERN_BODY= "indent_extern_body";
const VSCFGP_BEAUTIFIER_INDENT_NAMESPACE_BODY= "indent_namespace_body";
const VSCFGP_BEAUTIFIER_INDENT_FUNCALL_LAMBDA = "indent_funcall_lambda";
const VSCFGP_BEAUTIFIER_BRACELOC_ASM= "braceloc_asm";
const VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE= "braceloc_namespace";
const VSCFGP_BEAUTIFIER_BRACELOC_ENUM= "braceloc_enum";
const VSCFGP_BEAUTIFIER_SP_PTR_RETURN_TYPE_BETWEEN_TYPE_AND_STAR= "sp_ptr_return_type_between_type_and_star";
const VSCFGP_BEAUTIFIER_SPPAD_FPTR_PARENS= "sppad_fptr_parens";
const VSCFGP_BEAUTIFIER_SP_FPTR_BEFORE_LPAREN= "sp_fptr_before_lparen";
const VSCFGP_BEAUTIFIER_SP_FPTR_AFTER_RPAREN= "sp_fptr_after_rparen";
const VSCFGP_BEAUTIFIER_INDENT_ON_RETURN_TYPE_CONTINUATION= "indent_on_return_type_continuation";
const VSCFGP_BEAUTIFIER_SP_PTR_CAST_PROTO_BETWEEN_TYPE_AND_STAR= "sp_ptr_cast_proto_between_type_and_star";
const VSCFGP_BEAUTIFIER_SP_REF_CAST_PROTO_BETWEEN_TYPE_AND_AMP= "sp_ref_cast_proto_between_type_and_amp";
const VSCFGP_BEAUTIFIER_SP_REF_RETURN_TYPE_BETWEEN_TYPE_AND_AMP= "sp_ref_return_type_between_type_and_amp";
const VSCFGP_BEAUTIFIER_SPSTYLE_NAMESPACE_LBRACE= "spstyle_namespace_lbrace";
const VSCFGP_BEAUTIFIER_BL_BEFORE_MEMBER_ACCESS= "bl_before_member_access";
const VSCFGP_BEAUTIFIER_BL_AFTER_MEMBER_ACCESS= "bl_after_member_access";
const VSCFGP_BEAUTIFIER_BRACELOC_STRUCT= "braceloc_struct";
const VSCFGP_BEAUTIFIER_BRACELOC_UNION= "braceloc_union";
const VSCFGP_BEAUTIFIER_SPPAD_LAMBDA_BRACES= "sppad_lambda_braces";
const VSCFGP_BEAUTIFIER_SP_LAMBDA_BEFORE_LBRACKET= "sp_lambda_before_lbracket";
const VSCFGP_BEAUTIFIER_SP_LAMBDA_AFTER_RBRACKET= "sp_lambda_after_rbracket";
const VSCFGP_BEAUTIFIER_SPPAD_LAMBDA_BRACKETS= "sppad_lambda_brackets";
const VSCFGP_BEAUTIFIER_RM_RETURN_TYPE_NEW_LINES= "rm_return_type_new_lines";
const VSCFGP_BEAUTIFIER_OBJC_ALIGN_METH_DECL_ON_COLON= "objc_align_meth_decl_on_colon";
const VSCFGP_BEAUTIFIER_OBJC_ALIGN_METH_CALL_ON_COLON= "objc_align_meth_call_on_colon";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_CATEGORY_PARENS= "objc_sppad_category_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_CATEGORY_BEFORE_LPAREN= "objc_sp_category_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SP_CATEGORY_BEFORE_RPAREN= "objc_sp_category_before_rparen";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_DECL_SELECTOR_COLON= "objc_spstyle_decl_selector_colon";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_CALL_SELECTOR_COLON= "objc_spstyle_call_selector_colon";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_PROTOCOL_PARENS= "objc_sppad_protocol_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_PROTOCOL_BEFORE_LPAREN= "objc_sp_protocol_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SP_PROTOCOL_BEFORE_RPAREN= "objc_sp_protocol_before_rparen";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_PROTOCOL_COMMA= "objc_spstyle_protocol_comma";
const VSCFGP_BEAUTIFIER_OBJC_LISTALIGN2_METH_CALL_BRACKETS= "objc_listalign2_meth_call_brackets";
const VSCFGP_BEAUTIFIER_OBJC_ALIGN_METH_CALL_SELECTORS_RIGHT= "objc_align_meth_call_selectors_right";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_PROPERTY_PARENS= "objc_sppad_property_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_PROPERTY_BEFORE_LPAREN= "objc_sp_property_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SP_PROPERTY_AFTER_RPAREN= "objc_sp_property_after_rparen";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_PROPERTY_COMMA= "objc_spstyle_property_comma";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_SYNTHESIZE_COMMA= "objc_spstyle_synthesize_comma";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_SYNTHESIZE_EQ= "objc_spstyle_synthesize_eq";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_DYNAMIC_COMMA= "objc_spstyle_dynamic_comma";
const VSCFGP_BEAUTIFIER_OBJC_SP_METH_RETURN_TYPE_BEFORE_LPAREN= "objc_sp_meth_return_type_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_METH_RETURN_TYPE_PARENS= "objc_sppad_meth_return_type_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_METH_RETURN_TYPE_AFTER_RPAREN= "objc_sp_meth_return_type_after_rparen";
const VSCFGP_BEAUTIFIER_OBJC_SP_METH_PARAM_BEFORE_LPAREN= "objc_sp_meth_param_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_METH_PARAM_PARENS= "objc_sppad_meth_param_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_METH_PARAM_AFTER_RPAREN= "objc_sp_meth_param_after_rparen";
const VSCFGP_BEAUTIFIER_OBJC_INDENT_WIDTH_LAMBDA_BODY= "objc_indent_width_lambda_body";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_FINALLY_LBRACE= "objc_spstyle_finally_lbrace";
const VSCFGP_BEAUTIFIER_OBJC_SP_SYNCHRONIZED_BEFORE_LPAREN= "objc_sp_synchronized_before_lparen";
const VSCFGP_BEAUTIFIER_OBJC_SPPAD_SYNCHRONIZED_PARENS= "objc_sppad_synchronized_parens";
const VSCFGP_BEAUTIFIER_OBJC_SP_SYNCHRONIZED_AFTER_RPAREN= "objc_sp_synchronized_after_rparen";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_SYNCHRONIZED_LBRACE= "objc_spstyle_synchronized_lbrace";
const VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_PROPERTY_EQ= "objc_spstyle_property_eq";
const VSCFGP_BEAUTIFIER_SPSTYLE_FOREACH_COLON= "spstyle_foreach_colon";
const VSCFGP_BEAUTIFIER_NL_AFTER_TYPE_ANNOT= "nl_after_type_annot";
const VSCFGP_BEAUTIFIER_SP_ANNOT_BEFORE_LPAREN= "sp_annot_before_lparen";
const VSCFGP_BEAUTIFIER_SP_PAD_ANNOT_PARENS= "sp_pad_annot_parens";
const VSCFGP_BEAUTIFIER_SP_ANNOT_AFTER_RPAREN= "sp_annot_after_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_ANNOT_COMMA= "spstyle_annot_comma";
const VSCFGP_BEAUTIFIER_NL_AFTER_PACKAGE_ANNOT= "nl_after_package_annot";
const VSCFGP_BEAUTIFIER_NL_AFTER_VAR_ANNOT= "nl_after_var_annot";
const VSCFGP_BEAUTIFIER_NL_AFTER_METH_ANNOT= "nl_after_meth_annot";
const VSCFGP_BEAUTIFIER_NL_AFTER_PARAM_ANNOT= "nl_after_param_annot";
const VSCFGP_BEAUTIFIER_NL_AFTER_LOCAL_VAR_DECL_ANNOT= "nl_after_local_var_decl_annot";
const VSCFGP_BEAUTIFIER_BRACELOC_TYPE_ANNOT= "braceloc_type_annot";
const VSCFGP_BEAUTIFIER_SPSTYLE_TYPE_ANNOT_LBRACE= "spstyle_type_annot_lbrace";
const VSCFGP_BEAUTIFIER_SPSTYLE_ENUM_CONST_BODY_LBRACE= "spstyle_enum_const_body_lbrace";
const VSCFGP_BEAUTIFIER_BRACELOC_ENUM_CONST_BODY= "braceloc_enum_const_body";
const VSCFGP_BEAUTIFIER_SP_ENUM_CONST_BEFORE_LPAREN= "sp_enum_const_before_lparen";
const VSCFGP_BEAUTIFIER_SP_ENUM_CONST_AFTER_RPAREN= "sp_enum_const_after_rparen";
const VSCFGP_BEAUTIFIER_SPPAD_ENUM_CONST_PARENS= "sppad_enum_const_parens";
const VSCFGP_BEAUTIFIER_BRACELOC_ANON_CLASS= "braceloc_anon_class";
const VSCFGP_BEAUTIFIER_SPSTYLE_ANON_CLASS_LBRACE= "spstyle_anon_class_lbrace";
const VSCFGP_BEAUTIFIER_INDENT_ENUM_BODY= "indent_enum_body";
const VSCFGP_BEAUTIFIER_INDENT_ENUM_CONST_BODY= "indent_enum_const_body";
const VSCFGP_BEAUTIFIER_INDENT_ANNOT_TYPE_BODY= "indent_annot_type_body";
const VSCFGP_BEAUTIFIER_SPSTYLE_ARRAY_INIT_COMMA= "spstyle_array_init_comma";
const VSCFGP_BEAUTIFIER_SPPAD_ARRAY_INIT_BRACES= "sppad_array_init_braces";
const VSCFGP_BEAUTIFIER_NLPAD_ARRAY_INIT_INNER_BRACES= "nlpad_array_init_inner_braces";
const VSCFGP_BEAUTIFIER_NLPAD_ARRAY_INIT_OUTER_BRACES= "nlpad_array_init_outer_braces";
const VSCFGP_BEAUTIFIER_NL_ARRAY_INIT_BEFORE_OUTER_LBRACE= "nl_array_init_before_outer_lbrace";
const VSCFGP_BEAUTIFIER_NL_ARRAY_INIT_BEFORE_INNER_LBRACE= "nl_array_init_before_inner_lbrace";
const VSCFGP_BEAUTIFIER_BL_BEFORE_PACKAGE= "bl_before_package";
const VSCFGP_BEAUTIFIER_BL_AFTER_PACKAGE= "bl_after_package";
const VSCFGP_BEAUTIFIER_BL_BETWEEN_DIFFERENT_IMPORTS= "bl_between_different_imports";
const VSCFGP_BEAUTIFIER_BL_AFTER_IMPORTS= "bl_after_imports";
const VSCFGP_BEAUTIFIER_SP_TRY_BEFORE_LPAREN= "sp_try_before_lparen";
const VSCFGP_BEAUTIFIER_SP_TRY_AFTER_RPAREN= "sp_try_after_rparen";
const VSCFGP_BEAUTIFIER_SPPAD_TRY_PARENS= "sppad_try_parens";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_SYNCHRONIZED= "bl_after_start_block_synchronized";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_SYNCHRONIZED= "bl_after_end_block_synchronized";
const VSCFGP_BEAUTIFIER_SP_SYNCHRONIZED_BEFORE_LPAREN= "sp_synchronized_before_lparen";
const VSCFGP_BEAUTIFIER_SPPAD_SYNCHRONIZED_PARENS= "sppad_synchronized_parens";
const VSCFGP_BEAUTIFIER_SP_SYNCHRONIZED_AFTER_RPAREN= "sp_synchronized_after_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_CATCH_VBAR= "spstyle_catch_vbar";
const VSCFGP_BEAUTIFIER_NL_BEFORE_WHERE= "nl_before_where";
const VSCFGP_BEAUTIFIER_NL_AFTER_WHERE_COMMA= "nl_after_where_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_WHERE_COMMA= "spstyle_where_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_WHERE_COLON= "spstyle_where_colon";
const VSCFGP_BEAUTIFIER_BRACELOC_USING= "braceloc_using";
const VSCFGP_BEAUTIFIER_SP_USING_BEFORE_LPAREN= "sp_using_before_lparen";
const VSCFGP_BEAUTIFIER_SPPAD_USING_PARENS= "sppad_using_parens";
const VSCFGP_BEAUTIFIER_SP_USING_AFTER_RPAREN= "sp_using_after_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_USING_COMMA= "spstyle_using_comma";
const VSCFGP_BEAUTIFIER_BRACELOC_PROPERTY= "braceloc_property";
const VSCFGP_BEAUTIFIER_BRACELOC_OUTER_PROPERTY= "braceloc_outer_property";
const VSCFGP_BEAUTIFIER_SP_LOCK_BEFORE_LPAREN= "sp_lock_before_lparen";
const VSCFGP_BEAUTIFIER_SP_LOCK_AFTER_RPAREN= "sp_lock_after_rparen";
const VSCFGP_BEAUTIFIER_SPPAD_LOCK_PARENS= "sppad_lock_parens";
const VSCFGP_BEAUTIFIER_BRACELOC_LOCK= "braceloc_lock";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_LOCK= "bl_after_start_block_lock";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_LOCK= "bl_after_end_block_lock";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_BLOCK_USING= "bl_after_start_block_using";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_BLOCK_USING= "bl_after_end_block_using";
const VSCFGP_BEAUTIFIER_INDENT_FUN_RELATIVE_TO_KEYWORD= "indent_fun_relative_to_keyword";
const VSCFGP_BEAUTIFIER_SPSTYLE_DICTIONARY_COLON= "spstyle_dictionary_colon";
//#define VSCFGP_BEAUTIFIER_BRACELOC_FORK "braceloc_fork"
const VSCFGP_BEAUTIFIER_JUSTIFY_VAR_DECL_NAME= "justify_var_decl_name";
const VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AFTER_VAR_DECL_COMMA= "require_new_line_after_var_decl_comma";
const VSCFGP_BEAUTIFIER_ALIGN_ASSIGNMENTS= "align_assignments";
const VSCFGP_BEAUTIFIER_ALIGN_MODULE_INSTANTIATIONS= "align_module_instantiations";
const VSCFGP_BEAUTIFIER_ALIGN_MODULE_PARAMETERS= "align_module_parameters";
const VSCFGP_BEAUTIFIER_BRACELOC_ANON_FN= "braceloc_anon_fn";

// Python/VB properties
const VSCFGP_BEAUTIFIER_LABEL_INDENT_STYLE= "label_indent_style";
//#define VSCFGP_BEAUTIFIER_CHANGE_KEYWORDS_TO_MIXED_CASE "change_keywords_to_mixed_case"
const VSCFGP_BEAUTIFIER_NORMALIZE_ENDS=  "normalize_ends";
const VSCFGP_BEAUTIFIER_ADD_THENS=  "add_thens";
const VSCFGP_BEAUTIFIER_CONVERT_VARIANT_TO_OBJECT= "convert_variant_to_object";
const VSCFGP_BEAUTIFIER_RESPACE_OTHER= "respace_other";

/////////////////////////////////////////////////////// 
// HTML/XML properties 
const VSCFGP_BEAUTIFIER_PARENT_TAG= "parent_tag";
const VSCFGP_BEAUTIFIER_END_TAG= "end_tag";
const VSCFGP_BEAUTIFIER_END_TAG_REQUIRED= "end_tag_required";
const VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS= "valid_child_tags";
const VSCFGP_BEAUTIFIER_CONTENT_STYLE= "content_style";
const VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS= "preserve_child_tags";
const VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS_INDENT= "preserve_child_tags_indent";
const VSCFGP_BEAUTIFIER_PRESERVE_TEXT_INDENT= "preserve_text_indent";
const VSCFGP_BEAUTIFIER_WRAP_REMOVE_BLANK_LINES= "wrap_remove_blank_lines";
const VSCFGP_BEAUTIFIER_WRAP_NEVER_JOIN_LINES= "wrap_never_join_lines";
const VSCFGP_BEAUTIFIER_WRAP_RESPACE= "wrap_respace";
const VSCFGP_BEAUTIFIER_INDENT_TAGS= "indent_tags";
const VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG= "bl_before_start_tag";
const VSCFGP_BEAUTIFIER_ISMIN_BEFORE_START_TAG= "ismin_before_start_tag";
const VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG= "bl_after_end_tag";
const VSCFGP_BEAUTIFIER_ISMIN_AFTER_END_TAG= "ismin_after_end_tag";
const VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG= "bl_after_start_tag";
const VSCFGP_BEAUTIFIER_ISMIN_AFTER_START_TAG= "ismin_after_start_tag";
const VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG= "bl_before_end_tag";
const VSCFGP_BEAUTIFIER_ISMIN_BEFORE_END_TAG= "ismin_before_end_tag";
const VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_TRAILING_INDENT= "preserve_start_tag_trailing_indent";
const VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT= "preserve_start_tag_indent";
const VSCFGP_BEAUTIFIER_PRESERVE_END_TAG_TRAILING_INDENT= "preserve_end_tag_trailing_indent";
const VSCFGP_BEAUTIFIER_PRESERVE_END_TAG_INDENT= "preserve_end_tag_indent";
const VSCFGP_BEAUTIFIER_PRESERVE_END_TAG_INDENT_FOR_COLUMN1= "preserve_end_tag_indent_for_column1";
const VSCFGP_BEAUTIFIER_TAG_ATTR_STYLE= "tag_attr_style";
const VSCFGP_BEAUTIFIER_CLOSE_ATTR_LIST_ON_SEPARATE_LINE= "close_attr_list_on_separate_line";
const VSCFGP_BEAUTIFIER_SP_AFTER_LAST_ATTR= "sp_after_last_attr";
const VSCFGP_BEAUTIFIER_ESCAPE_NEW_LINES_IN_ATTR_VALUE= "escape_new_lines_in_attr_value";
const VSCFGP_BEAUTIFIER_SPPAD_ATTR_EQ= "sppad_attr_eq";

const VSCFGP_BEAUTIFIER_INDENT_CODE_FROM_TAG= "indent_code_from_tag";
const VSCFGP_BEAUTIFIER_MOD_TAG_INDENT= "mod_tag_indent";
const VSCFGP_BEAUTIFIER_ML_CLOSING_TAG= "ml_closing_tag";
const VSCFGP_BEAUTIFIER_ML_CLOSING_BLOCK= "ml_closing_block";
const VSCFGP_BEAUTIFIER_DEFAULT_EMBEDDED_LANG= "default_embedded_lang";
const VSCFGP_BEAUTIFIER_WC_ATTR_NAME= "wc_attr_name";
const VSCFGP_BEAUTIFIER_WC_TAG_NAME= "wc_tag_name";
const VSCFGP_BEAUTIFIER_WC_ATTR_WORD_VALUE= "wc_attr_word_value";
const VSCFGP_BEAUTIFIER_WC_ATTR_HEX_VALUE= "wc_attr_hex_value";
const VSCFGP_BEAUTIFIER_QUOTE_ALL_VALUES= "quote_all_values";
const VSCFGP_BEAUTIFIER_WRAP_REMOVE_BLANK_LINES= "wrap_remove_blank_lines";
const VSCFGP_BEAUTIFIER_WRAP_NEVER_JOIN_LINES= "wrap_never_join_lines";
const VSCFGP_BEAUTIFIER_TAG_ATTR_STYLE= "tag_attr_style";
const VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE= "quote_attr_word_value";
const VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE= "quote_attr_number_value";
const VSCFGP_BEAUTIFIER_CLOSE_ATTR_LIST_ON_SEPARATE_LINE= "close_attr_list_on_separate_line";
const VSCFGP_BEAUTIFIER_SP_AFTER_LAST_ATTR= "sp_after_last_attr";
const VSCFGP_BEAUTIFIER_ESCAPE_NEW_LINES_IN_ATTR_VALUE= "escape_new_lines_in_attr_value";
const VSCFGP_BEAUTIFIER_SPPAD_ATTR_EQ= "sppad_attr_eq";

// slick-c properties
const VSCFGP_BEAUTIFIER_RM_BLANK_LINES= "rm_blank_lines";
const VSCFGP_BEAUTIFIER_APPLY_BRACELOC_TO_FUNCTIONS= "apply_braceloc_to_functions";
const VSCFGP_BEAUTIFIER_SP_BEFORE_LBRACE= "sp_before_lbrace";
const VSCFGP_BEAUTIFIER_PP_RM_SPACES_AFTER_POUND= "pp_rm_spaces_after_pound";
const VSCFGP_BEAUTIFIER_LISTALIGN2_PARENS= "listalign2_parens";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_BRACES= "indent_width_braces";
const VSCFGP_BEAUTIFIER_DECL_COMMENT_COL=   "decl_comment_col";
const VSCFGP_BEAUTIFIER_REQUIRE_PARENS_ON_RETURN= "require_parens_on_return";

// Ada properties
const VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FOR_USE= "bl_between_adjacent_for_use";
const VSCFGP_BEAUTIFIER_BL_BEFORE_FOR_USE= "bl_before_for_use";
const VSCFGP_BEAUTIFIER_BL_AFTER_FOR_USE= "bl_after_for_use";

const VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUNS= "bl_between_adjacent_funs";
const VSCFGP_BEAUTIFIER_BL_BEFORE_FUNS= "bl_before_funs";
const VSCFGP_BEAUTIFIER_BL_AFTER_FUNS= "bl_after_funs";

const VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUN_PROTOTYPES= "bl_between_adjacent_fun_prototypes";
const VSCFGP_BEAUTIFIER_BL_BEFORE_FUN_PROTOTYPES= "bl_before_fun_prototypes";
const VSCFGP_BEAUTIFIER_BL_AFTER_FUN_PROTOTYPES= "bl_after_fun_prototypes";

const VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_TYPE_DECLS= "bl_between_adjacent_type_decls";
const VSCFGP_BEAUTIFIER_BL_BEFORE_TYPE_DECLS= "bl_before_type_decls";
const VSCFGP_BEAUTIFIER_BL_AFTER_TYPE_DECLS= "bl_after_type_decls";

const VSCFGP_BEAUTIFIER_BL_BEFORE_END= "bl_before_end";
const VSCFGP_BEAUTIFIER_BL_AFTER_BEGIN= "bl_after_begin";

const VSCFGP_BEAUTIFIER_BL_BEFORE_END_IF= "bl_before_end_if";
const VSCFGP_BEAUTIFIER_BL_AFTER_IF= "bl_after_if";

const VSCFGP_BEAUTIFIER_BL_BEFORE_END_LOOP= "bl_before_end_loop";
const VSCFGP_BEAUTIFIER_BL_AFTER_LOOP= "bl_after_loop";

//??? doesn't seem to work.
const VSCFGP_BEAUTIFIER_BL_BEFORE_RETURN= "bl_before_return";
const VSCFGP_BEAUTIFIER_BL_AFTER_RETURN= "bl_after_return";

//??? before option doesn't seem to work. Remove both.
const VSCFGP_BEAUTIFIER_BL_BEFORE_NESTED_LIST_ITEM= "bl_before_nested_list_item";
const VSCFGP_BEAUTIFIER_BL_AFTER_NESTED_LIST_ITEM= "bl_after_nested_list_item";

//??? Code doesn't seem to use this option. It sets the options but
// beautifier doesn't access it.
const VSCFGP_BEAUTIFIER_BL_BEFORE_SUBUNIT_HEADER= "bl_before_subunit_header";
const VSCFGP_BEAUTIFIER_BL_AFTER_SUBUNIT_HEADER= "bl_after_subunit_header";

// Only works if force type declaration comments to next line is set
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_COMMENT_AFTER_TYPE_DECL= "indent_width_comment_after_type_decl";


//???This option doesn't work and beautifier doesn't even attempt to use it.
const VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AFTER_LOGICAL_OPERATOR_IN_IF=  "require_new_line_after_after_logical_operator_in_if";

const VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION=  "indent_width_if_expr_continuation";
// ??? doesn't work well.
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION_MULTIPLE_LOGICAL_OPS= "indent_width_if_expr_continuation_multiple_logical_ops";

const VSCFGP_BEAUTIFIER_LEAVE_TYPE_DECL_TRAILING_COMMENT=  "leave_type_decl_trailing_comment";
const VSCFGP_BEAUTIFIER_INDENT_WIDTH_TRAILING_COMMENT= "indent_width_trailing_comment";
const VSCFGP_BEAUTIFIER_ALIGN_ADJACENT_COMMENTS=  "align_adjacent_comments";

//??? not used
const VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_ENUM=  "leave_multiple_enum";

const VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_FUN_DECL_PARAMS=  "leave_multiple_fun_decl_params";

const VSCFGP_BEAUTIFIER_WRAP_OPERATORS_BEGIN_NEXT_LINE=  "wrap_operators_begin_next_line";
const VSCFGP_BEAUTIFIER_SPSTYLE_COMMA=  "spstyle_comma";
const VSCFGP_BEAUTIFIER_SPSTYLE_LPAREN=  "spstyle_lparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_RPAREN=  "spstyle_rparen";
const VSCFGP_BEAUTIFIER_SPSTYLE_SEMICOLON= "spstyle_semicolon";
const VSCFGP_BEAUTIFIER_WC_KEYWORD=   "wc_keyword";
const VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE3=  "trailing_comment_style3";

const VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_COLON= "align_fun_params_on_colon";
// ?? somewhat broken when align_fun_param_names_on_colon is 1
const VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_IN_OUT= "align_fun_params_on_in_out";


/**
 * Used by the beautifier to save and restore stream markers
 * when beautifying a selection.
 */
struct SavedStreamMarkers {
   int surround_index;

   // save/restore key event callback markers
   se.ui.IKeyEventCallback* callbacks[];
   int callback_index[];
};


/**
 * Saves enough information on the markers between start_offset
 * and end_offset that we can recreate them once that snippet
 * has been beautified.
 *
 * @param state Storage to save the stream markers to.
 * @param markers marker offset array, that will be passed into
 *                one of the beautify functions.  We store
 *                stream marker offsets into this array so the
 *                beautifer can update their positions.
 * @param start_offset Start of area to save markers for.
 * @param end_offset End of area to save markers for.
 * @return Index of the first surround markers.  This returns an
 *         index even if there were no surround markers saved.
 */
static int save_stream_markers(SavedStreamMarkers& state, long (&markers)[], long (&cursorMarkerIndices)[], long start_offset, long end_offset, 
                               bool includeSurround) {
   TextChangeNotify.enableTextChange(false); // disable text change callbacks
   if (end_offset <= start_offset) {
      return markers._length();
   }

   EventUI.beautifySave(state.callbacks, state.callback_index, markers, cursorMarkerIndices, start_offset, end_offset);
   rv := markers._length();

   if (includeSurround) {
      state.surround_index = save_surround_state_to(markers);
   } else {
      state.surround_index = -1;
   }

   return rv;
}

/**
 * Restores stream markers from a previous call to
 * save_stream_markers(), probably after the code has been
 * beautified.
 *
 * It only restores stream markers used by select subsystems.
 * Currently hotspots...
 *
 * @param state
 * @param markers
 */
static void restore_stream_markers(SavedStreamMarkers& state, long (&markers)[]) {
   _updateTextChange();
   TextChangeNotify.enableTextChange(true);
   EventUI.beautifyRestore(state.callbacks, state.callback_index, markers);
   restore_surround_state_from(state.surround_index, markers);
}

bool beautifier_profile_editor_active()
{
   return gProfileEditForm != 0;
}

static _str get_language_wildcards(_str lang)
{
   _str ext;
   _str rest = get_file_extensions_sorted(lang);
   extlist := "";

   do {
      parse rest with ext rest;
      extlist :+= '*.'ext';';
   } while (rest != '');

   // .h files are used by a few languages.
   if (lang == 'c'
       || lang == 'm') {
      extlist :+= '*.h;';
   }

   return substr(extlist, 1, extlist._length()-1);
}


int find_any_enclosing_form(int start)
{
   int wid = start;
   while (wid && wid.p_object != OI_FORM) {
      wid = wid.p_parent;
   }
   return wid;
}


static int get_current_editor_control(int wid) {
   form := find_any_enclosing_form(wid);

   if (form <= 0) {
      return 0;
   }

   mc := form.p_parent;
   if (mc > 0
       && mc.p_object == OI_EDITOR) {
      return mc;
   } else {
      return 0;
   }
}

static const BEAUT_EX_KEY_PREFIX = "__example_";


static _str get_user_example_file(int form, _str examp_name)
{
   // For first cut, just ephemerally storing this in the
   // dialog properties.
   _str uex = _GetDialogInfoHt(BEAUT_EX_KEY_PREFIX :+ examp_name, form);

   if (uex == null
       || uex._length() == 0) {
      return '';
   }
   return uex;
}

// Examples in commonOptions.xml don't have file extensions, because
// they are shared for multiple languages.  This function accounts for this
// case and makes sure the correct extension is added to extensionless example
// files.
static _str normalize_example_file(_str file, _str langId)
{
   if (pos('[.]', file, 1, 'L') > 0) {
      if (def_beautifier_debug > 1)
         say("normalize("file") => "file);
      return file;
   }

   langext :=  '.'langId;

   switch (langId) {
   case "c":
      langext = ".cpp";
      break;
   case 'systemverilog':
      langext='.sv';
   case 'verilog':
      langext='.v';
   case 'groovy':
      langext='.groovy';
   }

   if (def_beautifier_debug > 1)
      say("normalize("file") => "(file :+ langext));

   return file :+ langext;
}

static void set_user_example_file(int form, _str examp_name, _str examp_file)
{
   _SetDialogInfoHt(BEAUT_EX_KEY_PREFIX :+ examp_name, examp_file, form);
}

void beautifier_update_preview(int preview_wid, _str file, _str langId = 'c',int ibeautifier= -1)
{
   long markers[];
   long cindices[];
   _str cfg[];
   formWid := find_any_enclosing_form(preview_wid);

   if (!formWid) {
      return;
   }

   if (preview_wid.p_buf_size <= 2) {
      _str ue = get_user_example_file(formWid, file);

      if (ue == '') {
         ue = _getSysconfigMaybeFixPath("formatter":+FILESEP:+langId:+FILESEP:+"examples":+FILESEP:+normalize_example_file(file, langId), false);
      }
      // Inhibit this, so we don't double-beautify.
      gAllowBeautifyCopy = 0;
      preview_wid.p_line=0;
      preview_wid.get(ue);
      gAllowBeautifyCopy = 1;
   }

   oldf := p_window_id;
   p_window_id = preview_wid;
   _SetEditorLanguage(langId);
   p_window_id = oldf;
   if (ibeautifier<0) {
      ibeautifier=_gibeautifier;
   }

   tab_size:= _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);
   // Always update the tab stops, otherwise, it can look silly when switching
   // when switching the tab and space settings.
   if (tab_size!='') {
      preview_wid.p_tabs = "+"tab_size;
   } else {
      tab_size=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);
      if (tab_size!='') {
         tab_size='4';
      }
      preview_wid.p_tabs = "+"tab_size;
   }
   preview_wid.p_ShowSpecialChars |= SHOWSPECIALCHARS_TABS;
   if (!new_beautifier_supported_language(preview_wid.p_LangId)) {
      // Probably Slick-C or ActionScript or Ada
      preview_wid.c_format(0,0,ibeautifier,true);
   } else {
      _beautifier_reformat_buffer(ibeautifier,preview_wid, markers, cindices, BEAUT_FLAG_NONE);
   }
   // Cursor at top.
   oldf = p_window_id;
   p_window_id = preview_wid;
   p_line = 1;
   p_col = 1;
   p_window_id = oldf;

   refresh();
}


static const STYLE_MASK = BES_BEGIN_END_STYLE_1|BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3;

// Translates from our encoded brace location values to the
// format recognized by LanguageSettings
static int beautifier_xlat_brace_loc(_str sbloc)
{
   if (isinteger(sbloc)) {
      switch ((int)sbloc) {
      case COMBO_NEXTLINE:
         return BES_BEGIN_END_STYLE_2;

      case COMBO_NEXTLINE_IN:
         return BES_BEGIN_END_STYLE_3;

      default:
         return BES_BEGIN_END_STYLE_1;

      }
   } else {
      // Just give out a default rather than falling over.
      return BES_BEGIN_END_STYLE_1;
   }
}

static int xlat_yn(_str s)
{
   return s!=0?1:0;
}

void _beautifier_profile_changed(_str prof_name,_str langId,int ibeautifier= -1) {
   _str update:[];
   doDestroy := false;
   if (ibeautifier<0) {
      ibeautifier=_beautifier_create(langId);
      doDestroy=true;
   }
   if (langId=='' || prof_name=='' || _plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(langId),prof_name)) {
      if (langId!='' && prof_name!='') {
         _beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),prof_name);
      }
      if (langId=='' || prof_name=='' || 
          (langId!='' && 
            (prof_name:==LanguageSettings.getBeautifierProfileName(langId) || _default_option(VSOPTION_EDITORCONFIG_FLAGS))
          )
         ) {
         // The current profile was updated, so update any open buffers for that language.

         update:[VSLANGPROPNAME_TABS] = '';
         update:[VSLANGPROPNAME_INDENT_WITH_TABS] = '';
         update:[LOI_SYNTAX_INDENT] = '';


         update:[LOI_TAG_CASE] = '';
         update:[LOI_ATTRIBUTE_CASE] = '';
         update:[LOI_WORD_VALUE_CASE] = '';
         update:[LOI_HEX_VALUE_CASE] = '';


         update:[LOI_QUOTE_WORD_VALUES] = '';
         update:[LOI_QUOTE_NUMBER_VALUES] = '';

         update:[LOI_KEYWORD_CASE] = '';

         update:[LOI_BEGIN_END_STYLE] = '';
         update:[LOI_PAD_PARENS] = '';
         update:[LOI_NO_SPACE_BEFORE_PAREN] = '';

         update:[LOI_INDENT_CASE_FROM_SWITCH] = '';

         update:[LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS] = '';

         update:[LOI_FUNCTION_BEGIN_ON_NEW_LINE] = '';

         update:[LOI_CUDDLE_ELSE] = '';

         update:[LOI_POINTER_STYLE] = '';

         _LangClearCache(langId);
         _update_buffer_from_new_setting(update,langId);
      }
   }
   if (doDestroy) {
      _beautifier_destroy(ibeautifier);
   }

}
/*
   We don't know if the beautifier profiles changes. Just assume
   they did and sync up the buffers. 

   The bad thing with doing
   this is that if a buffer has custom Tabs or indent_with_tabs
   settings, they will be blown away.
*/
void _cbafter_import_beautifier_profiles_changed() {
   _beautifier_cache_clear('');
   _beautifier_profile_changed('','');
}


static bool LangDict:[];

/**
 * Returns true if the language has a new beautifier
 * profile, regardless of whether the new beautifier
 * is supported in the current edition.
 */
bool has_beautifier_profiles(_str langId)
{
    if (LangDict._length() == 0) {
       foreach (auto lang in ALL_BEAUT_LANGUAGES) {
          LangDict:[lang] = true;
       }
    }

    return (LangDict._indexin(langId));
}

/**
 * Returns true if the language is supported by the new
 * beautifier.
 *
 * @param langid
 *
 * @return bool
 */
bool new_beautifier_supported_language(_str langid)
{
   return _haveBeautifiers() && has_beautifier_profiles(langid);
}

/**
 * Returns true if the given language supports the standard
 * options.xml configuration, managed by the common beautifier
 * code.
 */
bool new_beautifier_has_standard_config(_str langid)
{
   return (has_beautifier_profiles(langid) &&
           !_LanguageInheritsFrom('xml', langid) &&
           !_LanguageInheritsFrom('html', langid) &&
           langid != 'vbs' && langid != 'py' && langid != 'bas');
}

/**
 * Returns true if the given language supports the standard
 * options.xml configuration, managed by the common beautifier
 * code.
 */
bool _beautifier_gui_uses_options_xml(_str langId)
{

   return  file_exists(getBeautifierOptionsFile(langId));
}

_command void beautify_with_profile(_str profile=BEAUTIFIER_DEFAULT_PROFILE) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   long markers[];
   long cindices[];

   if (!new_beautifier_supported_language(p_LangId)) {
      ibeautifier:=_beautifier_create(p_LangId);
      status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(p_LangId),profile);
      if (status) {
         _beautifier_destroy(ibeautifier);
         _message_box("Could not load profile named '"profile"' for "p_LangId", error="status);
         return;
      }
      
      _beautifier_destroy(ibeautifier);
      return;
   }

   pcy := p_cursor_y;
   pcx := p_scroll_left_edge;
   ibeautifier:=_beautifier_create(p_LangId);
   status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(p_LangId),profile);
   if (status) {
      _beautifier_destroy(ibeautifier);
      _message_box("Could not load profile named '"profile"' for "p_LangId", error="status);
      return;
   }

   has_selection := (select_active() == MARK_SEARCH);
   int beginLine, endLine;
   long startoff = 0, endoff = 0;

   if (has_selection) {
      // Ignore adaptive formatting for a full file beautify.
      update_profile_from_aff(ibeautifier);
   }

   // Save cursor position, so beautifier can remap it to the same location
   // in the beautified source.
   cline_len := _text_colc();
   if (p_col > cline_len) {
      // We don't like markers that are in virtual columns.
      _end_line();
   }
   markers[0] = _QROffset();
   cindices[0] = 0;

   if (has_selection) {
      _begin_select();
      startoff = _QROffset();
      beginLine = p_line;

      _end_select();
      endoff = _QROffset();
      endLine = p_line;
   } else {
      beginLine = 1;
      bottom();
      endLine = p_line;
   }

   // save bookmark, breakpoint, and annotation information
   _SaveMarkersInFile(auto markerSaves, beginLine, endLine);

   rc := 0;
   if (has_selection) {
      rc = beautify_snippet(startoff, endoff, markers, ibeautifier);
   } else {
      rc = _beautifier_reformat_buffer(ibeautifier,p_window_id, markers, cindices, BEAUT_FLAG_NONE);
   }
   _beautifier_destroy(ibeautifier);

   if (rc < 0) {
      message(get_message(rc));
   } else {
      // restore bookmarks, breakpoints, and annotation locations
      _RestoreMmrkersInFile(markerSaves);

      if (markers._length() > 0) {
         // Restore to the remapped position in the source file.
         _GoToROffset(markers[0]);
         set_scroll_pos(pcx, pcy);
      }
   }
}


_command void beautify_current_buffer() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   beautify_with_profile(_beautifier_get_buffer_profile(p_LangId,p_buf_name));
}


/**
 *
 * @param langid
 *
 * @return _str (&)[] of beautifier options for langid.
 */
int _beautifier_cache_get(_str langId,_str buf_name)
{
   append := "";
   if (buf_name!='' && _default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      append="\t":+_default_option(VSOPTION_EDITORCONFIG_FLAGS):+"\t":+buf_name;
   } else {
      append = buf_name;
   }

   key := langId:+append;
   int *pibeautifier = gLanguageOptionsCache._indexin(key);
   if (pibeautifier) {
      return *pibeautifier;
   }
   int ibeautifier = _beautifier_create(langId);
   _str profileName=_beautifier_get_buffer_profile(langId,buf_name);
   status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
   if (status == 0) {
      // Make the defaults explicit, so array lookups in slickc don't fail for unspecified values.
      // Done in C++ code now.
   } else {
      // We don't want to repeatedly retry on error, so revert to defaults for this language.
      _beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),"Default");
   }
   gLanguageOptionsCache:[key] = ibeautifier;
   return ibeautifier;
}

bool _html_event_cancels_surround(_str event)
{
   // Strict on ending the surround once typing starts, to avoid
   // getting into a situation where an event being handed in
   // do_surround_keys would initiate another recursive surround.
   return vsIsKeyEvent(event2index(event));
}

bool _xhtml_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _cfml_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _vpj_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _xsd_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _android_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _tld_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

bool _ant_event_cancels_surround(_str event)
{
   return _html_event_cancels_surround(event);
}

void _html_invalidate_options_cache(_str langid)
{
   call_list('_hformatSaveScheme_',langid,LanguageSettings.getBeautifierProfileName(langid));
}

void _cfml_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _vpj_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _xsd_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _android_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _tld_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _ant_invalidate_options_cache(_str langId)
{
   _html_invalidate_options_cache(langId);
}

void _docbook_invalidate_options_cache(_str langid)
{
   _html_invalidate_options_cache(langid);
}

void _xml_invalidate_options_cache(_str langid)
{
   _html_invalidate_options_cache(langid);
}

void _xhtml_invalidate_options_cache(_str langid)
{
   _html_invalidate_options_cache(langid);
}
static void _beautifier_cache_clear1(_str langId) {
   int *pibeautifier = gLanguageOptionsCache._indexin(langId);
   if (pibeautifier) {
      _beautifier_destroy(*pibeautifier);
      gLanguageOptionsCache._deleteel(langId);
   }
   idx := find_index('_'langId'_invalidate_options_cache', PROC_TYPE);
   if (idx > 0) {
      call_index(langId, idx);
   }
}

void _beautifier_cache_clear(_str langId)
{
   // There could be buffer specific overrides. For simplicity, just clear all items in cache.
   foreach (auto key => auto value in gLanguageOptionsCache) {
      _beautifier_cache_clear1(key);
   }

#if 0
   if (langId=='') {
      foreach (auto key => auto value in gLanguageOptionsCache) {
         _beautifier_cache_clear1(key);
      }
      return;
   }
   _beautifier_cache_clear1(langId);
#endif
}

static _str convert_brace_style(int bes)
{
   switch (bes) {
   case BES_BEGIN_END_STYLE_1:
      return (_str)COMBO_SAMELINE;

   case BES_BEGIN_END_STYLE_2:
      return (_str)COMBO_NEXTLINE;

   case BES_BEGIN_END_STYLE_3:
      return (_str)COMBO_NEXTLINE_IN;

   default:
      return (_str)COMBO_SAMELINE;
   }
}

void _c_update_brace_settings(int bes, _str lang, int ibeautifier) {
   _str bstyle = convert_brace_style(bes);


   /*opts[BRACE_LOC_IF] = bstyle;
   opts[BRACE_LOC_FOR] = bstyle;
   opts[BRACE_LOC_WHILE] = bstyle;
   opts[BRACE_LOC_SWITCH] = bstyle;
   opts[BRACE_LOC_DO] = bstyle;
   opts[BRACE_LOC_TRY] = bstyle;
   opts[BRACE_LOC_CATCH] = bstyle;
   opts[CPPB_BRACE_LOC_ASM] = bstyle;
   opts[CPPB_BRACE_LOC_NAMESPACE] = bstyle;
   opts[BRACE_LOC_CLASS] = bstyle;
   opts[CPPB_BRACE_LOC_ENUM] = bstyle;
   opts[BRACE_LOC_FUN] = bstyle;
   opts[CPPB_BRACE_LOC_STRUCT] = bstyle;
   opts[CPPB_BRACE_LOC_UNION] = bstyle;*/

   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FOR,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_WHILE,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_SWITCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_DO,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TRY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CATCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ASM,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FUN,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_STRUCT,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_UNION,bstyle);
}

void _js_update_brace_settings(int bes, _str lang, int ibeautifier) {
   _c_update_brace_settings(bes, lang, ibeautifier);
}


void _m_update_brace_settings(int bes, _str lang, int ibeautifier) {
   _c_update_brace_settings(bes, lang,ibeautifier);
}

void _java_update_brace_settings(int bes, _str lang, int ibeautifier) {
   bstyle := convert_brace_style(bes);

   /*opts[BRACE_LOC_IF] = bstyle;
   opts[BRACE_LOC_FOR] = bstyle;
   opts[BRACE_LOC_WHILE] = bstyle;
   opts[BRACE_LOC_SWITCH] = bstyle;
   opts[BRACE_LOC_DO] = bstyle;
   opts[BRACE_LOC_TRY] = bstyle;
   opts[BRACE_LOC_CATCH] = bstyle;
   opts[BRACE_LOC_CLASS] = bstyle;
   opts[BRACE_LOC_FUN] = bstyle;
   opts[JAVA_ANNOT_TYPE_BRACELOC] = bstyle;
   opts[JAVA_ENUM_BRACELOC] = bstyle;
   opts[JAVA_ANON_CLASS_BRACELOC] = bstyle; */


   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ANON_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CATCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_DO,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM_CONST_BODY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FOR,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FUN,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_SWITCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TRY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TYPE_ANNOT,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_WHILE,bstyle);

   //_beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ASM,bstyle);
   //_beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE,bstyle);
   //_beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM,bstyle);
   //_beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_STRUCT,bstyle);
   //_beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_UNION,bstyle);
}

void _groovy_update_brace_settings(int bes, _str lang, int ibeautifier) {
   bstyle := convert_brace_style(bes);
   _java_update_brace_settings(bes,lang,ibeautifier);
   _beautifier_set_property(ibeautifier, VSCFGP_BEAUTIFIER_BRACELOC_ANON_FN, bstyle);
}

void _cs_update_brace_settings(int bes, _str lang, int ibeautifier) {
   bstyle := convert_brace_style(bes);

   /*opts[BRACE_LOC_IF] = bstyle;
   opts[BRACE_LOC_FOR] = bstyle;
   opts[BRACE_LOC_WHILE] = bstyle;
   opts[BRACE_LOC_SWITCH] = bstyle;
   opts[BRACE_LOC_DO] = bstyle;
   opts[BRACE_LOC_TRY] = bstyle;
   opts[BRACE_LOC_CATCH] = bstyle;
   opts[BRACE_LOC_CLASS] = bstyle;
   opts[BRACE_LOC_FUN] = bstyle;
   opts[CS_BRACELOC_ANONMETH] = bstyle;
   opts[CS_BRACELOC_ENUM] = bstyle;
   opts[CS_BRACELOC_LOCK] = bstyle;
   opts[CS_BRACELOC_NAMESPACE] = bstyle;
   opts[CS_BRACELOC_OUTER_PROPERTY] = bstyle;
   opts[CS_BRACELOC_PROPERTY] = bstyle;
   opts[CS_BRACELOC_USING] = bstyle;*/


   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ANON_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CATCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_DO,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FOR,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FUN,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_LOCK,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_OUTER_PROPERTY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_PROPERTY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_SWITCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TRY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_USING,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_WHILE,bstyle);

}

void _phpscript_update_brace_settings(int bes, _str lang, int ibeautifier) {
   bstyle := convert_brace_style(bes);

   /*opts[BRACE_LOC_IF] = bstyle;
   opts[BRACE_LOC_FOR] = bstyle;
   opts[BRACE_LOC_WHILE] = bstyle;
   opts[BRACE_LOC_SWITCH] = bstyle;
   opts[BRACE_LOC_DO] = bstyle;
   opts[BRACE_LOC_TRY] = bstyle;
   opts[BRACE_LOC_CATCH] = bstyle;
   opts[BRACE_LOC_CLASS] = bstyle;
   opts[BRACE_LOC_FUN] = bstyle;
   opts[CS_BRACELOC_ANONMETH] = bstyle;*/


   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ANON_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CATCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CLASS,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_DO,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FOR,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FUN,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_LOCK,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_OUTER_PROPERTY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_PROPERTY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_SWITCH,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TRY,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_USING,bstyle);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_WHILE,bstyle);
}

void _c_update_misc_settings(_str lang, int ibeautifier) {
   if (LanguageSettings.getCuddleElse(lang)) {
      //opts[ST_NEWLINE_BEFORE_ELSE] = (_str)COMBO_N;
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE, 0);

   } else {
      //opts[ST_NEWLINE_BEFORE_ELSE] = (_str)COMBO_Y;
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE, 1);
   }
}


void _m_update_misc_settings(_str lang, int ibeautifier) {
   _c_update_misc_settings(lang,ibeautifier);
}

void _phpscript_update_misc_settings(_str lang, int ibeautifier) {
   _c_update_misc_settings(lang,ibeautifier);
}

_str normalize_tabs(_str tab_setting) {
   _str n1, n2;
   parse tab_setting with n1 n2 .;

   if (isinteger(n1) && isinteger(n2)) {
      i1 := (int)n1;
      i2 := (int)n2;

      if (i2 > i1) {
         return '+' :+ (_str)(i2 - i1);
      }
      // For forms like: 4 +3
      // Even if we're wrong, it beats just returning
      // something of the form "N1 N2" that's just going
      // to make stages later on toss a stack.
      return '+' :+ (_str)(i2);
   }
   if (length(tab_setting) > 0
       && substr(tab_setting, 1, 1) == '+') {
      return tab_setting;
   } else {
      return '+'tab_setting;
   }
}



static int _lang_cfg_index(_str& fnkey, int& status)
{
   int index = _const_value(fnkey, status);

   //say("WHUT: "fnkey", "status);
   if (status != 0) {
      say("CNF: "fnkey);
   }
   return index;
}

static int _cfg_index(_str& fnkey, int& status)
{
   return _lang_cfg_index(fnkey, status);
}

// Function we use to load/save options to the optionsxml configtree we use
// for our settings.
static const BEAUTTYPE_NOTSET= -1;
static const BEAUTTYPE_NONE= 0;
static const BEAUTTYPE_INT=   1;
static const BEAUTTYPE_SPSTYLE= 2;
static const BEAUTTYPE_LISTALIGN= 3;
static const BEAUTTYPE_BRACELOC= 4;
static const BEAUTTYPE_TRAILING_COMMENT_STYLE= 5;
static const BEAUTTYPE_BOOL= 6;
static const BEAUTTYPE_RAI=  7;
static const BEAUTTYPE_JUSTIFY=  8;
static const BEAUTTYPE_WORDCASE= 9;
static const BEAUTTYPE_QUOTESTYLE= 10;
static const BEAUTTYPE_STRING=  11;
static const BEAUTTYPE_CONTENTSTYLE=  12;

/*
 List property names where the type can be determined from the property name.

*/
static int gbeauttype_map:[]={
   VSCFGP_BEAUTIFIER_SYNTAX_INDENT=>BEAUTTYPE_INT,
   VSCFGP_BEAUTIFIER_TAB_SIZE=>BEAUTTYPE_INT,
   VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE=>BEAUTTYPE_INT,
   VSCFGP_BEAUTIFIER_DEFAULT_EMBEDDED_LANG=>BEAUTTYPE_STRING,
   VSCFGP_BEAUTIFIER_QUOTE_ALL_VALUES=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_WC_TAG_NAME=>BEAUTTYPE_STRING,
   //VSCFGP_BEAUTIFIER_QUOTESTYLE_ATTR_NUMBER_VALUE=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_ESCAPE_NEW_LINES_IN_ATTR_VALUE=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_LABEL_INDENT_STYLE=>BEAUTTYPE_STRING,
   //VSCFGP_BEAUTIFIER_CHANGE_KEYWORDS_TO_MIXED_CASE=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_NORMALIZE_ENDS=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_ADD_THENS=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_CONVERT_VARIANT_TO_OBJECT=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_RESPACE_OTHER=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL=>BEAUTTYPE_INT,
   VSCFGP_BEAUTIFIER_END_TAG=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_END_TAG_REQUIRED=>BEAUTTYPE_BOOL,
   VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS=>BEAUTTYPE_STRING,
   VSCFGP_BEAUTIFIER_CONTENT_STYLE=>BEAUTTYPE_CONTENTSTYLE, // Wrap,TreatAsContent,Preserve
   'apply_braceloc_to_functions'=>BEAUTTYPE_BOOL,  // used by old beautifier for Slick-C and Action Script
};

static int get_beatufier_property_type(_str name) {
   temp_name:=name;
   if (substr(name,1,5)=='objc_') {
      temp_name=substr(name,6);
   } else if (substr(name,1,3)=='jd_') {
      temp_name=substr(name,4);
   } else if (substr(name,1,4)=='dox_') {
      temp_name=substr(name,5);
   } else if (substr(name,1,5)=='xdoc_') {
      temp_name=substr(name,6);
   }
   beauttype:=BEAUTTYPE_NOTSET;
   ptype:=gbeauttype_map._indexin(name);
   if (ptype) {
      return *ptype;
   }

   if (temp_name==VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE || temp_name==VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE3) {
      return BEAUTTYPE_TRAILING_COMMENT_STYLE;
   } 
   if (
       substr(temp_name,1,3)=='nl_'
       || substr(temp_name,1,6)=='nlpad_'
       || substr(temp_name,1,3)=='rm_'
       || substr(temp_name,1,3)=='sp_' 
       || substr(temp_name,1,6)=='sppad_'
       || substr(temp_name,1,3)=='pp_'
       || substr(temp_name,1,6)=='leave_'
       || substr(temp_name,1,6)=='align_'
       || substr(temp_name,1,8)=='oneline_'
       || substr(temp_name,1,7)=='format_'
       || substr(temp_name,1,8)=='require_'
       || substr(temp_name,1,3)=='ml_'
       || substr(temp_name,1,4)=='mod_'
       || substr(temp_name,1,5)=='wrap_'
       || substr(temp_name,1,6)=='ismin_'
       || substr(temp_name,1,9)=='preserve_'
       || substr(temp_name,1,6)=='quote_'
       ) {
      return BEAUTTYPE_BOOL;
   } 
   if (
       substr(temp_name,1,3)=='wc_'
       ) {
      return BEAUTTYPE_WORDCASE;
   } 
   if (temp_name == VSCFGP_BEAUTIFIER_RA_FUN_VOID_IN_EMPTY_PARAM_LIST) {
      return BEAUTTYPE_BOOL;
   }
   if (
       substr(temp_name,1,3)=='ra_'
       || substr(temp_name,1,4)=='rai_' 
       ) {
      return BEAUTTYPE_RAI;
   } 
   if (
       substr(temp_name,1,8)=='spstyle_'
       ) {
      return BEAUTTYPE_SPSTYLE;
   } 
   if (
       substr(temp_name,1,9)=='braceloc_'
       ) {
      return BEAUTTYPE_NONE;
   }
   if (
       substr(temp_name,1,8)=='justify_'
       ) {
      return BEAUTTYPE_JUSTIFY;
   } 
   if (        
       substr(temp_name,1,13)=='indent_width_'
       || substr(temp_name,1,3)=='bl_'
       || substr(temp_name,1,4)=='max_'
       ) {
      return BEAUTTYPE_INT;
   } 
   if (
       substr(temp_name,1,7)=='indent_'
       ) {
      return BEAUTTYPE_BOOL;
   } 
   if (
       substr(temp_name,1,11)=='listalign2_'
       || substr(temp_name,1,10)=='listalign_'
       ) {
      return BEAUTTYPE_LISTALIGN;
   }
   return BEAUTTYPE_INT;
}


_str beautifier_load_or_save_3state(_str fnkey, _str value = null, int &checkState = null,bool hasCheckbox=true)
{
   type:=get_beatufier_property_type(fnkey);
   // BEAUTTYPE_CONTENTSTYLE not handled yet
   if (value==null) {
      value=_beautifier_get_property(_gibeautifier,fnkey,null,auto apply);
      //say('n='fnkey' v='value' t='type' BEAUTTYPE_BOOL='BEAUTTYPE_BOOL);
      if (value==null) {
         say(nls("property '%s' not found",fnkey));
         value='';
      }
      if (hasCheckbox) {
         checkState=(apply)?1:0;
      }
      if (type==BEAUTTYPE_STRING) {
         return value;
      }
      if (type==BEAUTTYPE_INT || type==BEAUTTYPE_SPSTYLE || type==BEAUTTYPE_LISTALIGN 
          || type==BEAUTTYPE_BRACELOC || type==BEAUTTYPE_TRAILING_COMMENT_STYLE || type==BEAUTTYPE_RAI || 
          type==BEAUTTYPE_JUSTIFY || type==BEAUTTYPE_WORDCASE || type==BEAUTTYPE_QUOTESTYLE) {
         if (!isinteger(value)) value=0;
         return value;
      }
      if (type==BEAUTTYPE_BOOL) {
         if (value==0) {
            return 'N';
         }
         return 'Y';
      }
      return value;
   }
   tvalue:=value;
   if (type==BEAUTTYPE_BOOL) {
      tvalue=(strieq(value,'false') || strieq(value,'n'))?0:1;
   }
   if (hasCheckbox) {
      _beautifier_set_property(_gibeautifier,fnkey,tvalue,checkState?true:false);
   } else {
      _beautifier_set_property(_gibeautifier,fnkey,tvalue);
   }
   return value;
}

_str beautifier_load_or_save(_str fnkey, _str value = null) {
   return beautifier_load_or_save_3state(fnkey,value,0,false);
}


static const BEAUT_CFG_TREE = "beaut_config_tree";
const BEAUT_DISPLAY_TIMER = "beaut_display_timer";
static const BEAUT_LANGUAGE_ID = "beaut_lang_id";
static const BEAUT_ALLOW_PREVIEWS = "beaut_allow_previews";
static const BEAUT_LAST_INDEX = "beaut_last_index";
//const BEAUT_ASSOC_EDITCTL = "beaut_assoc_editctl";
static const BEAUT_PROFILE_CHANGED = "beaut_profile_changed";

// Sentinels for BEAUT_LAST_INDEX
static const DO_NOT_RELOAD_PREVIEW = -2;
static const RELOAD_PREVIEW = -1;


static int find_enclosing_form(int start, _str name)
{
   int wid = start;
   while (wid && wid.p_name != name) {
      wid = wid.p_parent;
   }
   return wid;
}

void beautifier_profile_editor_goto(_str node_caption)
{
   if (!gProfileEditForm) {
      return;
   }

   se.options.OptionsTree* ot = gProfileEditForm._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot) {
      return;
   }

   ot->showNode(node_caption);
}

// If you change the form name, be sure to search and replace on the form name
// to catch some references we make in strings.
defeventtab _beaut_options;
void ctl_cat_tree.on_create(_str profileName,_str langId)
{
   gLangId = langId;
   ec := get_current_editor_control(p_active_form);

   if (ec <= 0 || ec._QReadOnly()) {
      _ctl_beautify_button.p_visible = false;
      //_SetDialogInfoHt(BEAUT_ASSOC_EDITCTL, 0);
      //gEditorControlOriginalTabSettings='';
   } else {
      _ctl_beautify_button.p_message = "Beautifies the editor buffer with the current settings.";
      //_SetDialogInfoHt(BEAUT_ASSOC_EDITCTL, ec);
      //gEditorControlOriginalTabSettings = ec.p_tabs;
   }

   se.options.OptionsConfigTree t;

   _SetDialogInfoHt(BEAUT_ALLOW_PREVIEWS, 1);
   _SetDialogInfoHt(BEAUT_LANGUAGE_ID, langId);
   _SetDialogInfoHt(BEAUT_DISPLAY_TIMER, -1);
   _SetDialogInfoHt(OPTIONS_CHANGE_CALLBACK_KEY, find_index('_beaut_property_change_cb', PROC_TYPE));
   _SetDialogInfoHt(BEAUT_LAST_INDEX, RELOAD_PREVIEW);
   t.init(ctl_cat_tree, _control ctl_value_frame, _control ctl_help_frame, getBeautifierOptionsFile(langId));
   _SetDialogInfoHt(BEAUT_CFG_TREE, t);

   p_active_form.p_caption = profileName"/"LanguageSettings.getModeName(langId);
   ctl_search.p_text = '';

   se.options.OptionsTree* ot = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   p_active_form.resize_beaut_options_for_panel();
   gProfileEditForm = p_active_form;

   caption := ctl_cat_tree._retrieve_value();
   if (caption) {
      ot->showNode(caption, true);
   } else {
      ot->goToTreeNode(ctl_cat_tree._TreeGetFirstChildIndex(0));
   }

   // Make sure last_sel_index is not set to a value that will prevent the
   // deferred update from doing anything.  Otherwise the user gets a
   // unbeautified preview.
   int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

   if (last_sel_index) {
      *last_sel_index = -1;
   }
   beautifier_schedule_deferred_update(250, p_active_form);
}

static _str getBeautifierOptionsFile(_str langId)
{
   return _getSysconfigMaybeFixPath("formatter":+FILESEP:+langId:+FILESEP:+"options.xml", false);
}

static void _update_space_before_paren(bool space_before_paren, int ibeautifier)
{
   // Will need to be hooked later for different languages.
   val := space_before_paren ? 1 : 0;

   //options[SP_IF_LPAREN] = val;
   //options[SP_SWITCH_LPAREN] = val;
   //options[SP_FOR_LPAREN] = val;
   //options[SP_CATCH_LPAREN] = val;
   //options[SP_WHILE_LPAREN] = val;
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_SWITCH_BEFORE_LPAREN,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_FOR_BEFORE_LPAREN,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_CATCH_BEFORE_LPAREN,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_WHILE_BEFORE_LPAREN,val);
}

static void _update_pad_parens(bool pad_parens, int ibeautifier)
{
   val := pad_parens ? 1 : 0;

   //options[SP_IF_PADPAREN] = val;
   //options[SP_SWITCH_PADPAREN] = val;
   //options[SP_FOR_PADPAREN] = val;
   //options[SP_CATCH_PADPAREN]  = val;
   //options[SP_WHILE_PADPAREN] = val;
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_SWITCH_PARENS,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_FOR_PARENS,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_CATCH_PARENS,val);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_WHILE_PARENS,val);
}

// Returns true if profile settings were updated from the .editorconfig
static bool update_profile_from_editorconfig(int ibeautifier) 
{
   changed := false;

   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      EDITOR_CONFIG_PROPERITIES ecprops;
      _EditorConfigGetProperties(p_buf_name,ecprops,p_LangId,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
      _str setting;

      if (def_beautifier_debug > 1) {
         say('update_profile_from_editorconfig:');
      }

      if (ecprops.m_property_set_flags & ECPROPSETFLAG_INDENT_WITH_TABS) {
         setting = ecprops.m_indent_with_tabs ? '1' : '0';

         _beautifier_set_property(ibeautifier, VSCFGP_BEAUTIFIER_INDENT_WITH_TABS, setting);
         changed = true;
         if (def_beautifier_debug > 1) say('   indent_with_tabs='setting);
      }

      if (ecprops.m_property_set_flags & ECPROPSETFLAG_SYNTAX_INDENT) {
         setting = ecprops.m_syntax_indent;

         _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT,setting);

         if (_beautifier_has_property(ibeautifier, VSCFGP_BEAUTIFIER_INDENT_WIDTH_CASE)) {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CASE,setting);
         }
         changed = true;
         if (def_beautifier_debug > 1) say("   syntax_indent="setting);
      }

      if (ecprops.m_property_set_flags & ECPROPSETFLAG_TAB_SIZE) {
         setting = '+'ecprops.m_tab_size;
         _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE,setting);
         changed = true;
         if (def_beautifier_debug > 1) say('   tab_size='setting);
      }

      if (ecprops.m_property_set_flags & ECPROPSETFLAG_STRIP_TRAILING_SPACES &&
          _beautifier_has_property(ibeautifier, VSCFGP_BEAUTIFIER_RM_TRAILING_SPACES)) {
         setting = ecprops.m_strip_trailing_spaces ? '1' : '0';
         _beautifier_set_property(ibeautifier, VSCFGP_BEAUTIFIER_RM_TRAILING_SPACES, setting);
         changed = true;
         if (def_beautifier_debug > 1) say('   strip_trailing_spaces='setting);
      }
   }

   return changed;
}

// If the user has set the per-document tab setting, and it's
// a valid tab setting for the beautifier, use it.
static void update_tabs_from_document_setting(int ibeautifier, int afChangedFlags = 0)
{
   VS_LANGUAGE_OPTIONS opts;
   _GetDefaultLanguageOptions(p_LangId, opts);

   if (!(afChangedFlags & AFF_TABS)) {
      deftabs := _LangOptionsGetProperty(opts, VSLANGPROPNAME_TABS);
      if (deftabs != '' && deftabs != p_tabs) {
         nt := normalize_tabs(p_tabs);
         if (nt != '') {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE, nt);
            if (def_beautifier_debug > 1) {
               say('update_tabs_from_document_setting: using per-document tab of "'nt'" instead of "'deftabs'"');
            }
         }
      }
   }

   if (!(afChangedFlags & AFF_INDENT_WITH_TABS)) {
      defiwt := _LangOptionsGetPropertyInt32(opts, VSLANGPROPNAME_INDENT_WITH_TABS) != 0;
      if (defiwt != p_indent_with_tabs) {
         if (p_indent_with_tabs) {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,1);
         } else {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,0);
         }
         if (def_beautifier_debug > 1) {
            say('update_tabs_from_document_setting: using per-document indent-with-tabs of 'p_indent_with_tabs' instead of 'defiwt'.');
         }
      }
   }
}

static void update_profile_from_aff(int ibeautifier) {
   if (!update_profile_from_editorconfig(ibeautifier)) {
      if (!LanguageSettings.getUseAdaptiveFormatting(p_LangId)) {
         if (def_beautifier_debug > 1)
            say("update_profile_from_aff: aff disabled");
         update_tabs_from_document_setting(ibeautifier);
         return;
      }

      // Force recalculation of adaptive formatting settings.
      p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);

      if (def_beautifier_debug > 1)
         say("update_profile_from_aff: incoming_flags="p_adaptive_formatting_flags);

      changedFlags := 0;

      updateAdaptiveFormattingSettings(AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS|AFF_INDENT_CASE|AFF_BEGIN_END_STYLE|AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN, false,
                                       &changedFlags);

      if (def_beautifier_debug > 1)
         say("update_profile_from_aff: outgoing_flags="changedFlags);

      if (changedFlags & AFF_NO_SPACE_BEFORE_PAREN) {
         _update_space_before_paren(!p_no_space_before_paren, ibeautifier);
         if (def_beautifier_debug > 1) say("update_profile_from_aff: no_space_before_paren => "p_no_space_before_paren);
      }

      if (changedFlags & AFF_PAD_PARENS) {
         _update_pad_parens(p_pad_parens, ibeautifier);
         if (def_beautifier_debug > 1) say("update_profile_from_aff: pad_parens => "p_pad_parens);
      }

      if (changedFlags&AFF_INDENT_WITH_TABS) {
         if (p_indent_with_tabs) {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,1);
            //options[CO_INDENT_POLICY] = COMBO_IN_TABS;
         } else {
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,0);
            //options[CO_INDENT_POLICY] = COMBO_IN_SPACES;
         }
         if (def_beautifier_debug > 1) say("update_profile_from_aff: indent_with_tabs => "_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS));
      }

      if (changedFlags&AFF_SYNTAX_INDENT) {
         //options[CO_SYNTAX_INDENT] = p_SyntaxIndent;
         //options[CO_CASE_INDENT_WIDTH] = p_SyntaxIndent;
         _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT,p_SyntaxIndent);
         _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CASE,p_SyntaxIndent);
         if (def_beautifier_debug > 1) say("update_profile_from_aff: syntax_indent => "_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT));
      }

      if (changedFlags&AFF_TABS) {
         _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE,normalize_tabs(p_tabs));
         if (def_beautifier_debug > 1) say("update_profile_from_aff: tabs => "_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE));
      }

      if (changedFlags&AFF_INDENT_CASE) {
         if (p_indent_case_from_switch) {
           // options[CO_INDENT_CASE] = '1';
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE,1);
         } else {
            //options[CO_INDENT_CASE] = '0';
            _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE,0);
         }
         if (def_beautifier_debug > 1) say("update_profile_from_aff: indent_case => "_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE));
      }

      if (def_beautifier_aff_bracestyle != 0 && changedFlags&AFF_BEGIN_END_STYLE) {
         ubs := find_index('_'p_LangId'_update_brace_settings', PROC_TYPE);
         if (ubs != 0) {
            call_index(p_begin_end_style, p_LangId, ibeautifier, ubs);
            if (def_beautifier_debug>1)
               say("update_profile_from_aff: brace_style => "p_begin_end_style);
         }
      }

      // We can use the per-document setting if AF hasn't overridden it.
      update_tabs_from_document_setting(ibeautifier, changedFlags);
   }
}

void _ctl_beautify_button.lbutton_up()
{
   int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

   beautifier_schedule_deferred_update(-1, p_active_form);

   if (last_sel_index) {
      *last_sel_index = DO_NOT_RELOAD_PREVIEW;
   }

   ec := get_current_editor_control(p_active_form);

   if (ec > 0) {
      long markers[];
      long cindices[];

      owid := p_window_id;
      p_window_id = ec;
      markers[0] = _QROffset();
      cindices[0] = 0;
      ec.p_tabs = '+'_beautifier_get_property(_gibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);

      if (!new_beautifier_supported_language(ec.p_LangId)) {
         ec.c_format(0,0,_gibeautifier,true);
      } else {
         _beautifier_reformat_buffer(_gibeautifier,ec, markers, cindices, BEAUT_FLAG_NONE);
         _GoToROffset(markers[0]);
      }
      refresh();
      p_window_id = owid;
   }
}

void _ctl_reset_button.lbutton_up()
{
   se.options.OptionsTree* ot = p_active_form._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot)
      return;

   idx := p_active_form.ctl_cat_tree._TreeCurIndex();

   _str ex = ot->getCurrentSystemHelp();

   if (ex != '') {
      int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

      if (last_sel_index) {
         *last_sel_index = RELOAD_PREVIEW;
      }

      set_user_example_file(p_active_form, ex, '');
      ctl_formatted_edit.delete_all();
      beautifier_schedule_deferred_update(150, p_active_form);
   }
}

void _ctl_open_button.lbutton_up()
{
   se.options.OptionsTree* ot = p_active_form._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot)
      return;

   idx := p_active_form.ctl_cat_tree._TreeCurIndex();
   _str ex = ot->getCurrentSystemHelp();

   if (ex == '') {
      return;
   }

   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   wildcards := 'Source Files ('get_language_wildcards(langid)'), All Files (*.*)';


   _str res = _OpenDialog("-modal", "Open Preview File", "Source Files", wildcards, OFN_FILEMUSTEXIST|OFN_READONLY|OFN_NOCHANGEDIR|OFN_EDIT);

   if (res != "") {
      int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

      if (last_sel_index) {
         *last_sel_index = RELOAD_PREVIEW;
      }

      ctl_formatted_edit.delete_all();
      set_user_example_file(p_active_form, ex, res);
      beautifier_schedule_deferred_update(100, p_active_form);
   }
}

static const MIN_TREE_WIDTH = 1440;

void resize_beaut_options_for_panel()
{
   // first, get the minimum size required by this panel
   int minWidth, minHeight;
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);
   if (!optionsTree) return;
   optionsTree->getMinimumFrameDimensions(minHeight, minWidth);

   // does the panel already have enough room?
   if (ctl_value_frame.p_width < minWidth) {
      width := p_width;
      left_controls_width := width - (minWidth + 3 * DEFAULT_DIALOG_BORDER);

      // need a minimum for the tree
      if (left_controls_width < MIN_TREE_WIDTH) {
         left_controls_width = MIN_TREE_WIDTH;
         minWidth = width - (left_controls_width + 3 * DEFAULT_DIALOG_BORDER);
      }

      ctl_formatted_edit.p_width = ctl_cat_tree.p_width = left_controls_width;

      ctl_value_frame.p_x = ctl_cat_tree.p_x_extent + DEFAULT_DIALOG_BORDER;
      ctl_value_frame.p_width = minWidth;

      if (ctl_value_frame.p_child) {
         ctl_value_frame.p_child.p_width = ctl_value_frame.p_width - (2 * ctl_value_frame.p_child.p_x);
      }
   }
}

void _beaut_property_change_cb(Property *p)
{
   // Update gSetttings with the changed value, and then
   // force the preview to update.
   if (p->isCheckable()) {
      int checkState = p->getCheckState();

      idx := find_index('_'gLangId'_load_or_save_3state', PROC_TYPE);
      if (idx > 0) {
         call_index(p->getFunctionKey(),
                    p->getActualValue(),
                    checkState, idx);
      } else {
         beautifier_load_or_save_3state(p->getFunctionKey(),
                                        p->getActualValue(),
                                        checkState);
      }
   } else {
      idx := find_index('_'gLangId'_load_or_save', PROC_TYPE);
      if (idx > 0) {
         call_index(p->getFunctionKey(),
                    p->getActualValue(), idx);
      } else {
         beautifier_load_or_save(p->getFunctionKey(),
                                 p->getActualValue());
      }
   }

   // The active form is very likely a form embedded in our form.
   form := find_enclosing_form(p_active_form, '_beaut_options');
   if (form) {
      int* last_sel_index = _GetDialogInfoHtPtr(BEAUT_LAST_INDEX, form);

      if (last_sel_index) {
         *last_sel_index = RELOAD_PREVIEW;
      }
      beautifier_schedule_deferred_update(150,form);
   }
}

/**
 * Schedules a preview window update for later.
 * @param when How long to wait before doing the update.  If -1,
 *             then the function just kills any exising timer
 *             without registering a new one.
 * @param form
 */
void beautifier_schedule_deferred_update(int when, int form, _str fnName = 'showBeautOptionsPanel')
{
   int* timer = _GetDialogInfoHtPtr(BEAUT_DISPLAY_TIMER, form);

   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   if (when != -1) {
      *timer = _set_timer(when, find_index(fnName, PROC_TYPE), form);
   }
}

static void shutting_down_dialog(int form)
{
   // Kill outstanding timer
   beautifier_schedule_deferred_update(-1, form);

   _SetDialogInfoHt(BEAUT_ALLOW_PREVIEWS, 0);
   gProfileEditForm = 0;
}

static void _save_options_loc(int tree_wid, se.options.OptionsConfigTree* optionsTree) {
   if (optionsTree) {
      _append_retrieve(0, optionsTree->getTreeNodePath(tree_wid._TreeCurIndex()),
                       '_beaut_options.'tree_wid.p_name);
   }
}

void _ctl_ok.lbutton_up()
{
   se.options.OptionsConfigTree* optionsTree = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   _save_options_loc(ctl_cat_tree, optionsTree);
   shutting_down_dialog(p_active_form);
   optionsTree->apply();
   p_active_form._delete_window(IDOK);
}

void _ctl_cancel.lbutton_up()
{
   se.options.OptionsConfigTree* optionsTree = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   _save_options_loc(ctl_cat_tree, optionsTree);

   /*
   ec := _GetDialogInfoHt(BEAUT_ASSOC_EDITCTL, p_active_form);

   if (ec > 0 && gEditorControlOriginalTabSettings!='') {
      ec.p_tabs =gEditorControlOriginalTabSettings;
   } */
   shutting_down_dialog(p_active_form);
   p_active_form._delete_window(IDCANCEL);
}

void _beaut_options.on_destroy()
{
   int *t = _GetDialogInfoHtPtr(BEAUT_DISPLAY_TIMER);
   if (_timer_is_valid(*t)) {
      _kill_timer(*t);
      *t = -1;
   }
}

void ctl_cat_tree.on_change(int reason, int treeIndex = 0)
{
   se.options.OptionsConfigTree* optionsTree = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);
   int should_show = _GetDialogInfoHt(BEAUT_ALLOW_PREVIEWS);

   // Probably means we're in the process of closing down.
   if (should_show == 0) {
      return;
   }

   switch (reason) {
   case CHANGE_EXPANDED:
      if (!ctl_cat_tree._TreeDoesItemHaveChildren(treeIndex)) {
         optionsTree -> expandTreeNode(treeIndex);
      }
      break;
   case CHANGE_SELECTED:
      if (optionsTree->isOptionsChangeDelayed()) {
         beautifier_schedule_deferred_update(150, p_active_form);
      } else {
         optionsTree->resetOptionsChangeDelay();
         showBeautOptionsPanel(p_active_form);
      }
      break;
   }
}

void ctl_search.on_change()
{
   se.options.OptionsConfigTree* ot = _GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot)
      return;

   if (ctl_search.p_text == '') {
      ot->clearSearch();
      ot->showAll();
   } else {
      ot->searchOptions(ctl_search.p_text);
   }
}

void showBeautOptionsPanel(int formWid)
{
   int* timer = formWid._GetDialogInfoHtPtr(BEAUT_DISPLAY_TIMER);
   int* last_sel_index = formWid._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   se.options.OptionsTree* ot = formWid._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot)
      return;

   idx := formWid.ctl_cat_tree._TreeCurIndex();

   if (idx >= 0
       && (!last_sel_index
           || *last_sel_index != idx)) {
      open_button := formWid._find_control('_ctl_open_button');
      reset_button := formWid._find_control('_ctl_reset_button');
      formatted := formWid._find_control('ctl_formatted_edit');

      ot->goToTreeNode(idx);
      example := ot->getCurrentSystemHelp();
      if (example && example != "Bogus") {

         if (*last_sel_index != DO_NOT_RELOAD_PREVIEW) {
            formatted.delete_all();
         }
         beautifier_update_preview(formatted, example, (_str)formWid._GetDialogInfoHt(BEAUT_LANGUAGE_ID));
         open_button.p_enabled = true;
         reset_button.p_enabled = true;
      } else {
         open_button.p_enabled = false;
         reset_button.p_enabled = false;
         formatted.delete_all();
         formatted.refresh();
      }

      formWid.resize_beaut_options_for_panel();
      *last_sel_index = idx;
   }
}

/**
 * Brings up the profile editor for the given profile name.
 * Updates profile_name if the user had to save to a different
 * profile name.
 *
 * @param profile_name
 * @param langId
 * @return int 0 on success, or an error code on failure.
 */
int _beautifier_edit_profile(_str& profile_name, _str langId, bool *cancelled = null)
{

   if (cancelled) {
      *cancelled = false;
   }

   if (!_beautifier_gui_uses_options_xml(langId)) {
      //gui_beautify();
      return 0;
   }

   _gibeautifier=_beautifier_create(langId);
   ibeautifier:=_gibeautifier;
   status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profile_name);
   if (status != 0) {
      _beautifier_destroy(ibeautifier);
      return status;
   }

   _str result=show('-xy -modal _beaut_options', profile_name, langId);
   if (result==IDCANCEL || result == '') {
      _beautifier_destroy(ibeautifier);
      if (cancelled) {
         *cancelled = true;
      }
      return 0;
   }
   // Allow built-in profiles to be modified. Now that it's easy to store user modified changes to
   // built-in profiles which can be reset, it makes more sense.
   status=_beautifier_save_profile(_gibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profile_name);

   if (status != 0) {
      _beautifier_destroy(ibeautifier);
      return status;
   }
   _beautifier_cache_clear(langId);
   _beautifier_profile_changed(profile_name,langId,ibeautifier);
   _beautifier_destroy(ibeautifier);
   return 0;
}

bool _beautifier_is_supported(_str langId) {
   profileName:=_LangGetProperty(langId,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
   return (profileName!='');
}

/**
 * Displays beautifier options and optionionally allows
 * beautifying of file.<p>
 * 
 * @param lang        Optional override for languaged id to be 
 *                    used instead of current buffer p_LangId.
 * @param profileName Optionally specifies a different profile 
 *                    than the default profile for the
 *                    language.
 * 
 * @return a status value.  Return value=2 means there was an error beautifying and calling function should
 *         get the error message with vscf_iserror().
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command int beautifier_edit_current_profile,gui_beautify(_str lang = '',_str profileName='') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY) 
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   curbuf_matches_lang := false;
   if (lang == '') {
      lang = p_LangId;
      curbuf_matches_lang=true;
   } else if (_isEditorCtl(false) && p_LangId==lang) {
      curbuf_matches_lang=true;
   }
   if (profileName=='') {
      profileName=_beautifier_get_buffer_profile(lang,p_buf_name);
      if (profileName=='') {
         profileName=BEAUTIFIER_DEFAULT_PROFILE;
      }
   }
   orig_lang := "";
   if(curbuf_matches_lang && !_beautifier_is_supported(lang)) {
      lang=show('-modal _beautify_extension_form');
      if ( lang=='' ) {
         // User cancelled
         return(COMMAND_CANCELLED_RC);
      }
      orig_lang=p_LangId;
      p_LangId=lang;
   }
   if (!_beautifier_is_supported(lang)) {
      _message_box("No beautifier support for "_LangGetProperty(lang,VSLANGPROPNAME_MODE_NAME));
      return(1);
   }
   if (curbuf_matches_lang) {
      _ExitScroll();
   }
   int status;
   int lastModified;
   if (curbuf_matches_lang) {
      lastModified=p_LastModified;
   }
   if (_beautifier_gui_uses_options_xml(lang)) {
      status=_beautifier_edit_profile(profileName, lang);
   } else {
      idx := find_index('_'lang'_edit_current_profile', PROC_TYPE);
      if (index_callable(idx)) {
         call_index(p_window_id, lang, profileName, idx);
         status=0;
      } else {
         if (_LanguageInheritsFrom('html', lang) || _LanguageInheritsFrom('xml', lang) ) {
            lang_engine:='html';
            index:=find_index("_"lang_engine"_beautify_form",oi2type(OI_FORM));
            if ( !index ) {
               _message_box("Can't find form: ":+"_"lang_engine"_beautify_form");
               return(1);
            }
            caption:=_LangGetModeName(lang);
            show("-modal "index,lang_engine,lang,"",caption,profileName);
            _beautifier_cache_clear(lang);
            _beautifier_profile_changed(profileName,lang);
         }
         // We're lost
         status=0;
      }
   }
   if ( curbuf_matches_lang && lastModified!=p_LastModified ) adaptive_format_reset_buffers();
   if (orig_lang!='') {
      p_LangId=orig_lang;
   }
   return status;
}

_str _beautifier_get_buffer_profile(_str lang,_str buf_name,bool &using_override=false) {
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      EDITOR_CONFIG_PROPERITIES ecprops;
      _EditorConfigGetProperties(buf_name,ecprops,lang,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
      if (ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) {
         if (_plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(lang),ecprops.m_beautifier_default_profile)) {
            using_override=true;
            return ecprops.m_beautifier_default_profile;
         }
      }
   }
   using_override=false;
   return _LangGetBeautifierDefault(lang);
}

int _OnUpdate_beautifier_edit_current_profile(CMDUI cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   idname:=target_wid._ConcurProcessName();
   if (idname!=null) {
      return(MF_GRAYED);
   }
   // Allow chosing a beautifier for fundamental mode. Could be large XML file.
   // We could just always enable this and allow the user to choose a beautifier.
   lang := target_wid.p_LangId;
   if (lang=='fundamental' || _beautifier_gui_uses_options_xml(target_wid.p_LangId) || new_beautifier_supported_language(target_wid.p_LangId)) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}


// Helper function that prevents us from doing beautifies on 
// snippets we think we don't have enough information to do well
// with.  Assumes the range is for the current buffer.
bool should_beautify_range(long lowo, long higho, int beaut_flags)
{
   should := true;

   if ((beaut_flags & BEAUT_FLAG_COMPLETION) != 0) {
      if (p_LangId == 'c') {
         save_pos(auto psave);
         _GoToROffset(lowo);
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         rc := search('case', '@WCK');
         loc := _QROffset();
         restore_search(s1, s2, s3, s4, s5);
         restore_pos(psave);
         should = rc != 0 || loc > higho || loc < lowo;
      }
   }

   return should;
}

/**
 * Beautifies the code between the two source offsets.
 *
 * @param start
 * @param end
 *
 * @return int
 */
int new_beautify_range(long start, long endo, long (&markers)[], bool save_cursor = false, bool restore_cursor_right = false,
                       bool beaut_leading_context = false, int beaut_flags = BEAUT_FLAG_NONE, void (*tweak_profile)(int ibeautifier) = null)
{
   save_pos(auto sp1);
   pcy := p_cursor_y;
   pcx := p_scroll_left_edge;
   cursor_idx := markers._length();
   num_multiple_cursors := 0;
   if (save_cursor) {
      cline_len := _text_colc();
      if (p_col > cline_len) {
         // We don't like markers that are in virtual columns.
         _end_line();
      }
      markers :+= _QROffset();
   }

   _GoToROffset(start);
   startLine := p_line;

   _GoToROffset(endo);
   endLine := p_line;


   // save bookmark, breakpoint, and annotation information
   _SaveMarkersInFile(auto markerSaves, startLine, endLine);

   ibeautifier := _beautifier_cache_get(p_LangId,p_buf_name);

   update_profile_from_aff(ibeautifier);

   if (tweak_profile != null) {
      (*tweak_profile)(ibeautifier);
   }
   //p_BeautifierCfg = opts;

   int rc = beautify_snippet(start, endo, markers, ibeautifier, beaut_leading_context, beaut_flags);
   restore_pos(sp1);
   set_scroll_pos(pcx, pcy);
   if (rc < 0) {
      return rc;
   } else {
      // restore bookmarks, breakpoints, and annotation locations
      _RestoreMmrkersInFile(markerSaves);

      if (save_cursor) {
         _GoToROffset(markers[cursor_idx]);
         set_scroll_pos(pcx, pcy);
         if (restore_cursor_right) {
            next_char();
         }
         if (num_multiple_cursors > 0) {
            for (i:=0; i<num_multiple_cursors; i++) {
               _GoToROffset(markers[cursor_idx+i]);
               add_multiple_cursors();
            }
         }
         if (rc & SNIPPET_SURROUND) {
            do_surround_mode_keys(false);
         }
      }
   }
   return 0;
}

static int make_line_selection(long start_off, long end_off) {
   rv := _alloc_selection();

   if (rv >= 0) {
      _GoToROffset(start_off);
      _select_line(rv);
      _GoToROffset(end_off);
      _select_line(rv);
   } else {
      message(get_message(rv));
   }
   return rv;
}


static int make_char_selection(long start_off, long end_off) {
   rv := _alloc_selection();

   if (rv >= 0) {
      _GoToROffset(start_off);
      _select_char(rv);
      _GoToROffset(end_off);
      _select_char(rv);
   } else {
      message(get_message(rv));
   }
   return rv;
}

// Helper for going to the beginning of a statement that takes
// care of the corner cases for comments and preprocessing.
static void _ctx_goto_statement_beginning() {
   _first_non_blank();
   int pp_max;
   _str ch;

   for (pp_max=30; p_line > 1; pp_max--) {
      get_line(auto line);
      if (line == '') {
         if (search('[^ \t\r\n]', '-R@<') == 0) {
            _first_non_blank();
            if (def_beautifier_debug > 1)
               say("_ctx_goto_statement_beginning: skip blank line to "_QROffset());
         } else {
            // At the top of the file?
            if (def_beautifier_debug > 1) {
               say("_ctx_goto_statement_beginning: only whitespace above us");
            }
            break;
         }
      } else if (_in_c_preprocessing()) {
         if (def_beautifier_debug > 1)
            say("_ctx_goto_statement_beginning: skip pp "_QROffset());
         up();
         _first_non_blank();
      } else if (_clex_find(0, 'G') == CFG_COMMENT) {
         _clex_find_start();
         if (def_beautifier_debug > 1)
            say("_ctx_goto_statement_beginning: to start of comment @ "_QROffset());
         return;
      } else {
         _first_non_blank();

         if ((get_text(4) == 'case' || get_text(7) == 'default') &&
             _clex_find(0, 'G') == CFG_KEYWORD) {
            if (search('switch[ \t]*\(', '-U@<') != 0) {
               up();
            }
            if (def_beautifier_debug > 1)
               say('_ctx_goto_statement_beginning: scan for switch to '_QROffset());
            continue;
         }
         ch = get_text();

         if (ch == '{') {
            prev_char();
            _clex_skip_blanks('-');
         } else if (ch == '}') {
            if (def_beautifier_debug > 1)
               say("_ctx_goto_statement_beginning: rbrace @ "_QROffset());
            _find_matching_paren(MAXINT, true);
         } else {
            c_begin_stat_col(false, false, false);
            _begin_line();

            if (def_beautifier_debug > 1)
               say("_ctx_goto_statement_beginning: done @ "_QROffset());
            return;
         }
      }
   }

   if (def_beautifier_debug > 1)
      say("_ctx_goto_statement_beginning: stopped @ "_QROffset());
   _begin_line();
}

// Maxium number of lines we'll accept when using the function start as leading context.
static const MAX_FUN_LINES = 5;

static bool lang_use_taginfo(_str langId) {

   //return langId != 'scala' && langId != 'java' && langId != 'cs' && langId != 'phpscript' &&
   //       langId != 'systemverilog' && langId != 'verilog' && langId != 'json';
   switch (langId) {
   case 'scala':
   case 'java':
   case 'cs':
   case 'phpscript':
   case 'systemverilog':
   case 'verilog':
   case 'json':
      return false;
   default:
      break;
   }

   // If the average time spent getting statement tagging for this buffer is
   // fast enough, then use that tagging information, otherwise, avoid it.
   //
   return !_UpdateStatementsIsSlow();
}

void _c_snippet_find_leading_context(long selstart, long selend) {
   if (def_beautifier_usetaginfo && lang_use_taginfo(p_LangId) ) {
      int i;
      _GoToROffset(selstart);
      start_line := p_line;


      tag_lock_context(false);
      _UpdateStatements(true);

      for (i = 0; i<2; i++) {
         _first_non_blank();
         stmt := tag_current_statement();
         if (stmt > 0) {
            tag_get_detail2(VS_TAGDETAIL_statement_type, stmt, auto stype);
            tag_get_detail2(VS_TAGDETAIL_statement_start_linenum, stmt, auto stline);
            if (stype == 'func' && (start_line-stline) > MAX_FUN_LINES) {
               // This can happen for incomplete statements, which you can get when
               // brace auto-close and syntax expansion are off.
               prev_char();
               _clex_skip_blanks('-');
               _ctx_goto_statement_beginning();
               if (def_beautifier_debug > 1)
                  say("_c_snippet_find_leading_context: rejected, heuristic start @"_QROffset());
            } else if (stype == 'pp') {
               tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, stmt, auto ststart);
               if (def_beautifier_debug > 1)
                  say("_c_snippet_find_leading_context: rejected, preprocessing @"ststart);
               break;
            } else if (stype == 'assign' && (p_LangId == 'c' || p_LangId == 'm')) {
               // Does this look like we're in a struct initializer?
               tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, stmt, auto ststart);
               _GoToROffset(ststart);
               initAssign := get_text() == '.';  // .field = bleh syntax.
               if (!initAssign) {
                  _end_line();
                  if (p_col > 1) {
                     _clex_skip_blanks('-');
                     c := get_text();
                     initAssign = c == ',' || c == '}';
                     _GoToROffset(ststart);
                  }
               }
               if (initAssign && search('{', 'lmh@XCS-') == 0) {
                  p_col = 1;
                  if (def_beautifier_debug > 1) {
                     say('_c_snippet_find_leading_context: expand to initializer start @'_QROffset());
                  }
                  break;
               }
            } else {
               tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, stmt, auto ststart);
               _GoToROffset(ststart);
               if (def_beautifier_debug > 1)
                  say("_c_snippet_find_leading_context: tag statement start @"_QROffset());

               if (stype == 'proto' || stype == 'func') {
                  // If we're in a class, it is possible to misinterpret a constructor decl
                  // as a function call, without enough leading context to distinguish the two.
                  tag_get_detail2(VS_TAGDETAIL_statement_class, stmt, auto klass);
                  if (klass != "") {
                     // class offsets may be off, so just do a search.
                     if (search('class|struct|union|enum', 'rmh@XCS-') == 0
                         && def_beautifier_debug > 1) {
                        say("_c_snippet_find_leading_context: expand for class @"_QROffset());
                     }
                  }
               }
               break;
            }
         }
      }
      tag_unlock_context();

      // Include the entire line.
      _begin_line();
      if (_QROffset() < selstart) {
         selstart = _QROffset();
      }
   }

   // Don't have goto labels as the leading context, their
   // indent is a little too disconnected from the surrounding
   // syntax to be reliable.
   _GoToROffset(selstart);
   get_line_raw(auto rline);
   rline = strip(rline);
   if (pos('^[0-9a-zA-Z_]+\:$', rline, 1, 'R')) {
      // To get an accurate position for a goto label, we need
      // to include the enclosing left brace.
      search('\{', 'r-h@XCS');
      _ctx_goto_statement_beginning();
      selstart = _QROffset();
      if (def_beautifier_debug > 1)
         say("_c_snippet_find_leading_context: skipped label to:"selstart);
   }

   // Use a selection to limit our searching.
   _deselect();
   _GoToROffset(selstart);
   _select_line();
   _GoToROffset(selend);
   _select_line('', 'P');
   _GoToROffset(selstart);

   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);


   if (def_beautifier_debug > 1) say("_c_snippet_find_leading_context: ("selstart", "selend")");

   // Are we in the middle of a case statement or class decl?
   crv := search('case[ \t]|default\:|public\:|private\:|protected\:|slots\:', 'rmh@XCS');
   if (0 == crv) {
      sw_off := 0L;
      cw := cur_word(auto jkl);
      _str outer_kw;
      if (cw == 'default' || cw == 'case') {
         outer_kw = 'switch';
      } else {
         outer_kw = 'class|struct';
      }

      if (_c_last_enclosing_control_stmt(outer_kw, auto kw, &sw_off) > 0) {
         if (sw_off < selstart) {
            // Move the goalpost back only if 'switch' isn't already selected
            // We extend the selection so the searches limited to the selection
            // work correctly below.
            selstart = sw_off;
            _deselect();
            _GoToROffset(sw_off);
            _select_line();
            _GoToROffset(selend);
            _select_line('', 'P');
            if (def_beautifier_debug > 1) say("_c_snippet_find_leading_context: expand for "outer_kw" to "selstart);
         }
      }
   } else if (def_beautifier_usetaginfo) {
   }

   // amount of net nesting in the selection effects how much context
   // we want to grab for accuracy.
   _GoToROffset(selstart);
   nesting := 0;
   deepest := 0;
   crv = search('\{|\}', 'rmh@XCS');
   while (crv == 0) {
      switch (get_text()) {
      case '{':
         nesting--;
         break;

      case '}':
         nesting++;
         break;
      }
      if (nesting > deepest) {
         deepest = nesting;
      }
      crv = repeat_search('rmh@XCS');
   }

   had_to_unwind := (deepest != 0);
   if (deepest == 0) {
      // Nothing special required.
      _GoToROffset(selstart);
   } else {
      // Wind up N braces
      _GoToROffset(selstart);
      prev_char();  // In case start of selstart is { or }

      crv = search('\{|\}', 'rh@-XCS');
      while (crv == 0 && deepest > 0) {
         if (get_text() == '}') {
            deepest++;
         } else {
            deepest--;
         }
         if (deepest > 0) {
            crv = repeat_search('rh@-XCS');
         }
      }
      if (def_beautifier_debug > 1) say("_c_snippet_find_leading_context: unwind braces to "_QROffset());
   }

   if (get_text_safe() == '{') {
      // we want c_begin_stat_col to deal with any statement
      // that introduces the block, not just return the position
      // of the first statement after the brace.
      prev_char(); _clex_skip_blanks('-');

      mch := get_text_safe();

      if (mch == ')') {
         // Some sort of control statement.  Skip to lparen
         // if we can to help out ctx_goto_statement_beginning for
         // things like multiline for statements.
         find_matching_paren(true);
         if (def_beautifier_debug > 1) say("_c_snippet_find_leading_context: control paren to "_QROffset());
      } else if (mch == ':') {
         // Maybe a case statement in a switch.
         _first_non_blank();
         cword := cur_word(auto whatever);
         if (cword == 'default' || cword == 'case') {
            found_offset := 0L;
            if (_c_last_enclosing_control_stmt('switch', auto kw, &found_offset) > 0) {
               _GoToROffset(found_offset);
               if (def_beautifier_debug > 1)
                  say("_c_snippet_find_leading_context: expand to switch for braced case: "found_offset);
            }
         }
      }
   }

   if (had_to_unwind && p_col > 1) {
      // Corner case check for nested if statements
      scol := p_col;
      p_col = 1;
      if (pos('\{|\}', get_text(scol - 1), 1, 'r')) {
         // We unwound, but there are still possibly unmatched braces.
         // Rather than doing a bunch of repeated searchs, just take
         // a big bite.
         if (def_beautifier_usetaginfo) {
            tag_lock_context(false);
            tag_update_context();
            cur_ctx := tag_current_context();
            if (cur_ctx > 0) {
               if (def_beautifier_debug > 1)
                  say("_c_snippet_find_leading_context: skip to containing context");
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, cur_ctx, auto seekpos);
               _GoToROffset(seekpos);
            }
            tag_unlock_context();
         } else {
            // Simplistic search for a function beginning.
            search('^[^ \t\n\r]', 'rmh@XCS-');
         }
      }
   }
   _ctx_goto_statement_beginning();
   restore_search(s1, s2, s3, s4, s5);
   _deselect();
}


void _m_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _scala_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _java_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _js_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _cs_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _phpscript_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _html_snippet_find_leading_context(long selstart, long selend)
{
   _GoToROffset(0);
}

void _xml_snippet_find_leading_context(long selstart, long selend)
{
   _GoToROffset(0);
}

void _xhtml_snippet_find_leading_context(long selstart, long selend)
{
   _GoToROffset(0);
}

void _cfml_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

void _vpj_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

void _xsd_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

void _android_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

void _tld_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

void _ant_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

/**
 * Looks backwards from the current cursor position for a good
 * starting point for the beautifier, and leaves the cursor
 * there.
 *
 * Selection is line based, so it needs to find a good starting
 * point at the beginning of the line at the moment.
 */
static void snippet_find_leading_context(long selstart, long selend) {
   index := find_index('_'p_LangId'_snippet_find_leading_context', PROC_TYPE);
   if (index) {
      call_index(selstart, selend, index);
   }
}


/**
 *  Flags that can be returned by beautify snippet.
 */
static const SNIPPET_SURROUND = 0x1;       // dynamic surround state was saved and restored -
                                    //   will need to be redisplayed.

static long scanLeftPastPreprocessing()
{
   here := _QROffset();
   rc := search('^[ \t]*#', '-<U@');

   if (rc == 0) {
      _begin_line();
      return _QROffset();
   }

   return here;
}

/**
 * @param offset_orig_begin Starting offset
 * @param offset_orig_end End offset
 * @param markers Array of offsets to get feedback on
 *                post-beautified positions from.
 * @param bconfig If supplied, applies this beautifier config
 *                when beautifying. (for using something other
 *                than the default profile for a language).
 *
 * @param save_selection
 * @param select_pivot
 *
 * @return int
 */
int beautify_snippet(long offset_orig_begin, long offset_orig_end, long (&markers)[], int ibeautifier, bool beaut_leading_context = false,
                     int beaut_flags = BEAUT_FLAG_NONE) {

   _str orig_buf_name=p_buf_name;
   // Ensure user markers are in the selection.
   foreach (auto m  in markers) {
      offset_orig_end = max(m, offset_orig_end);
      offset_orig_begin = min(m, offset_orig_begin);
   }

   // Get boundaries of user selection as if it were a line selection.
   _GoToROffset(offset_orig_begin);
   p_col = 1;
   offset_user_begin := _QROffset();

   _GoToROffset(offset_orig_end);
   _end_line();

   // Pull up over any trailing newlines.
   search('[^ \t\n\r]', 'rh@-');
   offset_user_end := _QROffset();

   if (offset_user_end <= offset_user_begin) {
      return 0;
   }

   if (def_beautifier_debug > 1) say("beautify_snippet: extent("offset_orig_begin","offset_orig_end"), user("offset_user_begin", "offset_user_end")");

   include_surround := false;
   if (surround_get_extent(auto sur_start, auto sur_end)) {
      // Do an early check to see if the surround state is valid.  A surround
      // setup for an `if` at the end of a function will cause us to include the entire
      // function in the leading source. If the source doesn't completely match 
      // the profile settings, then this can cause indents that look wrong in the
      // context of the neighboring statements, even though they're correct if the 
      // function was completely beautified.
      include_surround = calculate_surround_extent(auto dsl, auto ddel, auto dll, auto dsp);
      if (def_beautifier_debug > 1 ) say('beautify_snippet: include surround='include_surround);
      if (include_surround && _ranges_overlap(offset_user_begin, offset_user_end, sur_start, sur_end)) {
         // If we overlap an active dynamic surround, expand to include all of it,
         // otherwise, we'll mangle it.
         offset_user_begin = min(offset_user_begin, sur_start);
         offset_user_end = max(offset_user_end, sur_end);
         if (def_beautifier_debug > 1) say("beautify_snippet: surround expand("offset_user_begin","offset_user_end")");
      }
   }

   _GoToROffset(offset_user_end);
   cfg := _clex_find(0, 'G');
   if (cfg == CFG_COMMENT) {
      // Don't beautify half of a comment, the lexer won't be impressed.
      _clex_find_end();
      right();
      offset_user_end = max(offset_user_end, _QROffset());
      left();
      _clex_find_start();
      left();
      offset_user_begin = min(offset_user_begin, _QROffset());
      if (def_beautifier_debug > 1)
         say("beautify_snippet: expanded end for "cfg": "offset_user_begin", "offset_user_end);
   }

   _GoToROffset(offset_user_begin);
   if (_in_c_preprocessing()) {
      offset_user_begin = scanLeftPastPreprocessing();
      if (def_beautifier_debug > 1)
         say('beautify_snippet: move user_begin to left of preprocessing to 'offset_user_begin);
   }


   // expand like it was a line selection again.
   _GoToROffset(offset_user_begin);
   p_col = 1;
   offset_user_begin = _QROffset();
   _GoToROffset(offset_user_end);
   _end_line();
   offset_user_end = _QROffset();

   long cursor_indices[];  // Array of indices into markers, with an index for each marker that's a cursor.
   num_user_markers := markers._length();
   after_hotspots_index := save_stream_markers(auto smstate, markers, cursor_indices, offset_user_begin, offset_user_end, include_surround);
   extent_markers := markers._length();
   if (def_beautifier_debug > 1) say('beautify_snippet: num_user_markers='num_user_markers', after_hotspots_index='after_hotspots_index);

   // Extend selection upwards for extra context.
   _GoToROffset(offset_user_begin);
   if (beaut_flags & BEAUT_FLAG_EXACT_CONTEXT) {
      _GoToROffset(0);
      if (def_beautifier_debug > 1) say("BEAUT_FLAG_EXACT_CONTEXT");
   } else {
      snippet_find_leading_context(offset_user_begin, offset_user_end);
   }
   p_col = 1;
   offset_ctx_begin := _QROffset();

   if (def_beautifier_debug > 1) say("beautify_snippet: leading_context="offset_ctx_begin);
   if (offset_ctx_begin > offset_user_begin) {
      // The statement begin code got lost.  We may be in some hopeless syntax,
      // so pull back to the selection, and make a wish.
      offset_ctx_begin = offset_user_begin;
      _GoToROffset(offset_ctx_begin);
   }

   if (beaut_leading_context) {
      offset_user_begin = offset_ctx_begin;
   }

   if (extent_markers > num_user_markers) {
      // Expand our extent to cover the range of any stream markers
      // that got saved.
      int i;
      for (i = 0; i < extent_markers; i++) {
         offset_ctx_begin  = min(offset_ctx_begin, markers[i]);
         offset_user_end   = max(offset_user_end, markers[i]);
      }
      _GoToROffset(offset_ctx_begin);
      snippet_find_leading_context(offset_ctx_begin, offset_user_end);
      offset_ctx_begin = _QROffset();

      if (def_beautifier_debug > 1) {
         say("leading context adjusted for stream markers, offset_ctx_begin="offset_ctx_begin",  offset_user_end="offset_user_end);
      }
   }

   // Never creep the context forward past where the user selection start.
   if (offset_ctx_begin > offset_user_begin) {
      offset_ctx_begin = offset_user_begin;
   }

   // Smart tab is not the right choice for languages where
   // leading indent is significant.  (Python is the prime
   // example - smart paste can only figure out where
   // the cursor should be to continue the last block in the
   // source, not where/if to end the block)
   init_indent := 0;
   indent_fn := find_index('_'p_LangId'_get_initial_indent', PROC_TYPE);

   if (indent_fn > 0) {
      init_indent = call_index(indent_fn);
   } else {
      init_indent = get_smart_tab_column();
      if (init_indent <= 0) {
         // This language likely doesn't have smart tab.  The best we can do is
         // to hope the initial indent is already ok.
         if (def_beautifier_debug > 1) say(p_LangId' has no smarttab, guessing indent.');
         init_indent = _first_non_blank_col(p_SyntaxIndent) - 1;
      } else {
         init_indent -= 1; // Col to indent level.
      }
   }

   if (def_beautifier_debug > 1)
      say("initial indent="init_indent);

   // Create temp view with content from extended content selection to the end
   // of the user's selection.
   int status, tview, orig_wid;
   sel1 := make_line_selection(offset_ctx_begin, offset_user_end);
   if (sel1 >= 0) {
      orig_wid = _create_temp_view(tview, '');
      p_buf_name=orig_buf_name;
      _SetEditorLanguage(orig_wid.p_LangId);
      p_UTF8 = orig_wid.p_UTF8;
      p_encoding=orig_wid.p_encoding;
      p_newline = orig_wid.p_newline;
      p_indent_with_tabs = orig_wid.p_indent_with_tabs;
      status = _copy_to_cursor(sel1);
      _free_selection(sel1);

      if (status < 0) {
         _delete_temp_view(tview);
         return status;
      }
   } else {
      return sel1;
   }

   if (def_beautifier_debug > 1) {
      say("beautify_snippet: num_user_markers="num_user_markers);
      _dump_var(markers, 'before');
   }

   if (def_beautifier_debug > 1) say("beautify_snippet: bufsize="p_RBufSize);
   // Map caller's and savestate markers to what we're actually beautifying.
   int i;
   long out_of_range[];
   for (i = 0; i < extent_markers; i++) {
      markers[i] = markers[i] - offset_ctx_begin;
      if (markers[i] < 0) {
         out_of_range[i] = markers[i];
         if (def_beautifier_debug > 1) say("beautify_snippet: marker "i" before effective range: "markers[i]);
         markers[i] = 0;
      } else if (markers[i] >= p_RBufSize) {
         out_of_range[i] = 1 + (markers[i] - p_RBufSize);
         if (def_beautifier_debug > 1) say("beautify_snippet: marker "i" after effective range: "out_of_range[i]);
      } else {
         out_of_range[i] = 0;
      }
   }

   // delimit the users original selection, and then beautify it.
   long udelim_start = offset_user_begin - offset_ctx_begin;

   bottom();
   long udelim_end   = length(p_newline) + _QROffset();            // No trailing context, so this is always valid.
   delim_offset := markers._length();

   markers[delim_offset]     = udelim_start;   // So we can get feedback on the new position
   markers[delim_offset + 1] = udelim_end;

   //p_window_id.p_BeautifierCfg = bconfig;

   if (def_beautifier_debug > 1) {
      say("beautify_snippet: udelim_start="udelim_start", udelim_end="udelim_end);
      _dump_var(markers, "remapped input markers");
   }

   // Mark the user supplied markers to be 
   // treated as cursor markers.  (ie, markers that trailing whitespace should
   // be allowed for if the marker is on the end of a line)
   for (i = 0; i < num_user_markers; i++) {
      cursor_indices[cursor_indices._length()] = i;
   }
   status = _beautifier_reformat_selection(ibeautifier,p_window_id, markers, cursor_indices, udelim_start, udelim_end, init_indent, beaut_flags | BEAUT_FLAG_SNIPPET);
   if (status < 0) {
      message(get_message(status));
      _delete_temp_view(tview);
      return status;
   }

   if (def_beautifier_debug > 1) {
      _dump_var(markers, 'raw markers out');
   }


   long max_marker_pos = -1;

   for (i = 0; i < extent_markers; i++) {
      if (markers[i] > max_marker_pos) {
         max_marker_pos = markers[i];
      }
   }
   if (def_beautifier_debug > 1 ) say('max_marker_pos='max_marker_pos);

   // Since we don't do trailing context, the end should always be
   // the end of the temp buffer. But we want to trim off trailing
   // whitespace and newlines for uniform handling when we paste
   // this back into the source buffer.
   bottom();
   s_end_line := p_line;
   if ( 0 == search('[~ \t\r\n]', 'rh@-')) {
      next_char();
      // But don't eat any trailing whitespace the beautifier left.
      while (get_text() == ' ') {
         next_char();
      }

      if (_QROffset() < max_marker_pos) {
         if (def_beautifier_debug > 1) say('moving from '_QROffset()' to marker max: 'max_marker_pos);
         _GoToROffset(max_marker_pos);
      }
      if (def_beautifier_debug > 1) say("beautify_snippet: snippet trim nl to "_QROffset()", lines="p_line", "s_end_line);
   }
   num_trailing_lines := s_end_line - p_line;
   markers[delim_offset + 1] = _QROffset();

   // If we trimmed any markers, move them back.  But just
   // the user's markers, not the saved state ones.
   adjusted_rhs := markers[delim_offset+1] + offset_ctx_begin;
   if (def_beautifier_debug > 1) say("beautify_snippet: adjusted_end="adjusted_rhs);

   // And map back to document offsets.
   for (i = 0; i < extent_markers; i++) {
      if (out_of_range[i] < 0) {
         markers[i] = offset_ctx_begin + out_of_range[i];
      } else if (out_of_range[i] > 0) {
         markers[i] = adjusted_rhs + out_of_range[i] - 1;
      } else {
         markers[i] = markers[i] + offset_ctx_begin;
      }
   }

   for (i = 0; i < num_user_markers; i++) {
      if (markers[i] > adjusted_rhs) {
         markers[i] = adjusted_rhs;
      }
   }

   _GoToROffset(markers[delim_offset]);
   p_col = 1;
   markers[delim_offset] = _QROffset();
   beaut_select := make_char_selection(markers[delim_offset], markers[delim_offset + 1]);
   if (beaut_select < 0) {
      _delete_temp_view(tview);
      return beaut_select;
   }

   // Remove user selection text.
   activate_window(orig_wid);
   sel2 := make_line_selection(offset_user_begin, offset_user_end);
   if (sel2 >= 0) {
      status = _delete_selection(sel2);
      _free_selection(sel2);
      if (status < 0) {
         _free_selection(beaut_select);
         _delete_temp_view(tview);
         return status;
      }
   }

   // put in a newline for the last line of the beautified selection.
   // And add back any trailing newlines the beautifier left in there.
   // we use _insert_text instead of nosplit-line; latter can screw up offsets if it adjusts previous line.
   int idx;
   if (offset_user_begin >= p_RBufSize) {
      // Expansion at the end of the file.  Don't go into
      // virtual space by trying to seek there.
      bottom();
      for (idx = 0; idx < max(1, num_trailing_lines); idx++) {
         _insert_text(p_newline);
      }
   } else {
      _GoToROffset(offset_user_begin);
      left();
      for (idx = 0; idx < max(1, num_trailing_lines); idx++) {
         _insert_text(p_newline);
      }
   }

   // Insert the beautified text.
   _GoToROffset(offset_user_begin);
   status = _copy_to_cursor(beaut_select);
   _free_selection(beaut_select);
   _delete_temp_view(tview);

   restore_stream_markers(smstate, markers);

   if (status >= 0) {
      if (smstate.surround_index >= 0) {
         status |= SNIPPET_SURROUND;
      }
   }

   return status;
}

//void _nextprev_hotspot_beautifier(long from_offset, long to_offset) {
//   if (from_offset < to_offset
//       && beautify_on_edit(p_LangId)) {
//      long markers[];
//
//      new_beautify_range(from_offset, to_offset, markers, true);
//   }
//}

_command int new_beautify_selection() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   begin_select();
   start := _QROffset();

   end_select();
   endo := _QROffset();
   long markers[];
   return new_beautify_range(start, endo, markers);
}

_command int beautify_function() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
  if (!_haveContextTagging()) {
     return 0;
  }

  if (!new_beautifier_supported_language(p_LangId)) {
     message('No beautifier for 'p_LangId);
     return 0;
  }
  se.tags.TaggingGuard sentry;
  sentry.lockContext(false);
  _UpdateContext(true,false,VS_UPDATEFLAG_context);
  
  ctx := tag_current_context();
  if (ctx > 0) {
     if (0 == tag_get_context_browse_info(ctx, auto cm)) {
        if (cm.type_name == 'func') {
           long markers[];
           return new_beautify_range(cm.name_seekpos, cm.end_seekpos, markers, true);
        } else {
           message('Not in function?');
        }
     }
  }

  return 0;
}

static const OPTIONS_PREVIEW = "main";
static get_options_preview_file(_str langid)
{
   if (langid == 'c') {
      langid = 'cpp';
   } else if (langid == 'systemverilog') {
      langid='sv';
   } else if (langid == 'verilog') {
      langid='v';
   }
   return OPTIONS_PREVIEW'.'langid;
}

/**
 * Dialog that's embedded in
 * Tools->Options->Languages->Blah->Formatting
 */
defeventtab _new_beautifier_config;

void _ctl_symbol_trans_edit.lbutton_up()
{
   lang := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   autoSymbolTransEditor(lang);
}

static void repopulate_profile_list(_str cur_profile, _str lang)
{
   _beautifier_list_profiles(lang,auto profiles);

   if (cur_profile == '') {
      cur_profile = profiles[0];
   }

   _ctl_profile_selection.p_cb_list_box._lbclear();
   for (i := 0; i < profiles._length(); i++) {
      _ctl_profile_selection.p_cb_list_box._lbadd_item(profiles[i]);
   }
   _ctl_profile_selection.p_cb_text_box.p_text = cur_profile;
}

static void update_button_state(_str langId, _str profileName)
{
   estate := true;

   if (_plugin_has_builtin_profile(vsCfgPackage_for_LangBeautifierProfiles(langId),profileName)) {
      estate = false;
   }
   _ctl_delete_profile.p_enabled = estate;
   _ctl_reset_profile.p_enabled = _plugin_is_modified_builtin_profile(vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
}

static void update_options_preview(int wid, _str file, _str langId, _str profileName)
{
   ibeautifier:=_beautifier_create(langId);
   status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);

   if (status == 0) {
      beautifier_update_preview(wid, file, langId, ibeautifier);
   }
   _beautifier_destroy(ibeautifier);
}

void _bc_update_preview_cb(int form)
{
   beautifier_schedule_deferred_update(-1, form);
   selector := form._find_control('_ctl_profile_selection');

   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID, form);
   cur_prof := selector.p_cb_text_box.p_text;

   update_options_preview(form._find_control('_ctl_preview'), get_options_preview_file(langid), langid, cur_prof);
}

void _new_beautifier_config_restore_state(_str options) {
    beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _new_beautifier_config_init_for_options(_str langid)
{
   // do a little fancy work to make sure the buttons look nice -
   // they are autosized and may need to be adjusted
   padding := ctllabel1.p_x;
   _ctl_edit_profile.p_x = _ctl_profile_selection.p_x_extent + padding;
   _ctl_create_profile.p_x = _ctl_edit_profile.p_x_extent + padding;
   _ctl_delete_profile.p_x = _ctl_create_profile.p_x_extent + padding;
   _ctl_reset_profile.p_x = _ctl_delete_profile.p_x_extent + padding;

   _ctl_loadfile_button.p_x = _ctl_preview.p_x_extent - _ctl_loadfile_button.p_width;
   _ctl_reset_button.p_x = _ctl_loadfile_button.p_x - padding - _ctl_reset_button.p_width;
// _ctl_beautify_button.p_x = _ctl_reset_button.p_x - padding - _ctl_beautify_button.p_width;

   hasSymTrans := (_LanguageInheritsFrom('html', langid) || _LanguageInheritsFrom('xml', langid));
   hasAutoValidate := _LanguageInheritsFrom('xml', langid);

   _ctl_symbol_trans.p_visible = hasSymTrans;
   _ctl_symbol_trans_edit.p_visible = hasSymTrans;
   _ctl_auto_validate.p_visible = hasAutoValidate;

   if (hasSymTrans) {
      _ctl_symbol_trans.p_value = (int)LanguageSettings.getAutoSymbolTranslation(langid);
   }

   if (hasAutoValidate) {
      if (!_haveXMLValidation()) {
         _ctl_auto_validate.p_visible=false;
      }
      _ctl_auto_validate.p_value = (int)LanguageSettings.getAutoValidateOnOpen(langid, false);
   }

   cur_prof := LanguageSettings.getBeautifierProfileName(langid);
   repopulate_profile_list(cur_prof, langid);
   _ctl_profile_selection.p_cb_text_box.p_text = cur_prof;
   update_button_state(langid, cur_prof);
   _SetDialogInfoHt(BEAUT_LANGUAGE_ID, langid);
   _SetDialogInfoHt(BEAUT_DISPLAY_TIMER, -1);
   _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);

   beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _new_beautifier_config_cancel()
{
   // Cancel the timer, in case the user was remarkably quick.
   beautifier_schedule_deferred_update(-1, p_active_form);
   _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);
}

bool _new_beautifier_config_apply()
{
   // Cancel the timer, in case the user was remarkably quick.
   beautifier_schedule_deferred_update(-1, p_active_form);
   lang := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   prof := _ctl_profile_selection.p_cb_text_box.p_text;

   LanguageSettings.setBeautifierProfileName(lang, prof);
   _beautifier_cache_clear(lang);
   _beautifier_profile_changed(prof, lang);
   _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);
   if (_ctl_symbol_trans.p_visible) {
      LanguageSettings.setAutoSymbolTranslation(lang, _ctl_symbol_trans.p_value != 0);
   }

   if (_ctl_auto_validate.p_visible) {
      LanguageSettings.setAutoValidateOnOpen(lang, _ctl_auto_validate.p_value != 0);
   }

   return true;
}

bool _new_beautifier_config_is_modified()
{
   lang := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   changed := _GetDialogInfoHt(BEAUT_PROFILE_CHANGED) ||
      (_ctl_symbol_trans.p_visible && _ctl_symbol_trans.p_value != (int)LanguageSettings.getAutoSymbolTranslation(lang)) ||
      (_ctl_auto_validate.p_visible && _ctl_auto_validate.p_value != (int)LanguageSettings.getAutoValidateOnOpen(lang));

   return (changed || LanguageSettings.getBeautifierProfileName(lang) != _ctl_profile_selection.p_cb_text_box.p_text);
}

_str beautifier_user_config_file()
{
   return _ConfigPath() :+ USER_BEAUTIFIER_PROFILES_FILE;
}

_str beautifier_system_config_file(_str langid)
{
   return _getSysconfigPath():+'formatter/'langid'/profiles/slickedit-beautifier-profile.xml';
}

_str beautifier_config_for_profile(_str profname, _str langid)
{
   if (_beautifier_is_system_profile(langid, profname)) {
      return beautifier_system_config_file(langid);
   }

   return beautifier_user_config_file();
}

_str _new_beautifier_config_export_settings(_str &file, _str &args, _str langID)
{
   error := '';

   // just set the args to be the profile name for this langauge
   args = LanguageSettings.getBeautifierProfileName(langID);
   if (args == null) {
      // if it doesn't exist, we just ignore it
      args = '';
      return '';;
   }

   //_plugin_export_profile(file,vsCfgPackage_for_LangBeautifierProfiles(langID),args,langID);
   error=_plugin_export_profiles(file,vsCfgPackage_for_LangBeautifierProfiles(langID),null,false);

   return error;
}

_str _new_beautifier_config_import_settings(_str &file, _str &args, _str langID)
{
   error := '';

   if (args == '') {
      // we can't do anything here
      return error;
   }

   if (file != '') {
      error=_plugin_import_profiles(file,vsCfgPackage_for_LangBeautifierProfiles(langID),2);
      //error = importUserProfile(file, args, langID);
      if (_plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(langID),args)) {
         // it does, so set it as this profile for this language
         LanguageSettings.setBeautifierProfileName(langID, args);
      }
   } else {
      // no file,  first, make sure this profile exists
      if (_plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(langID),args)) {
         // it does, so set it as this profile for this language
         LanguageSettings.setBeautifierProfileName(langID, args);
      }
   }

   return error;
}

_str _new_beautifier_config_get_static_search_tags(_str langId)
{
   // these are things we don't want in the search tags
   symbols := '['_escape_re_chars("@+,|:#.<>=*&/\\{}[]\"'-", 'R')']';
   list := '';

   // get the file
   file := getBeautifierOptionsFile(langId);
   if (file == '' || !file_exists(file)) return '';

   // open it up
   handle := _xmlcfg_open(file, auto status);
   if (handle > 0) {

      // search for all the Captions
      _str captions[];
      searchStr := "//@Caption";
      _xmlcfg_find_simple_array(handle, searchStr, captions, TREE_ROOT_INDEX, VSXMLCFG_FIND_VALUES);

      // combine the captions into one long list
      for (i := 0; i < captions._length(); i++) {
         // lowercase, please
         cap := lowcase(captions[i]);

         // replace any symbols with spaces
         cap = stranslate(cap, ' ', symbols, 'r');

         list :+= cap' ';
      }

      // close down the xml
      _xmlcfg_close(handle);
   }

   // and we are done
   return strip(list);
}

void _new_beautifier_config.on_resize()
{
   padding := _ctl_preview_frame.p_x;

   heightDiff := p_height - (_ctl_preview_frame.p_y_extent + padding);
   widthDiff := p_width - (_ctl_preview_frame.p_x_extent + padding);

   _ctl_preview_frame.p_width += widthDiff;
   _ctl_preview.p_width += widthDiff;

   _ctl_reset_button.p_x += widthDiff;
   _ctl_loadfile_button.p_x += widthDiff;

   _ctl_preview_frame.p_height += heightDiff;
   _ctl_preview.p_height += heightDiff;

   _ctl_reset_button.p_y += heightDiff;
   _ctl_loadfile_button.p_y += heightDiff;
}

//void _ctl_beautify_button.lbutton_up()
//{
//   schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
//}

void _ctl_reset_button.lbutton_up()
{
   _ctl_preview.delete_all();
   beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _ctl_loadfile_button.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   wildcards := 'Source Files ('get_language_wildcards(langid)'), All Files (*.*)';


   _str res = _OpenDialog("-modal", "Open Preview File", "Source Files", wildcards, OFN_FILEMUSTEXIST|OFN_READONLY|OFN_NOCHANGEDIR|OFN_EDIT);

   if (res != "") {
      _ctl_preview.delete_all();
      _ctl_preview.get(res);
      beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
   }
}

void _ctl_profile_selection.on_change(int reason)
{
   if (reason == CHANGE_CLINE || reason == CHANGE_SELECTED) {
      langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
      cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;
      update_button_state(langid, cur_prof);
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
      _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 1);
   }
}

void _ctl_edit_profile.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;


   beautifier_edit_current_profile(langid,cur_prof);
   update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
#if 0
   cancelled := false;

   idx := find_index('_'langid'_edit_current_profile', PROC_TYPE);
   if (new_beautifier_has_standard_config(langid) || idx==0 /*py or vbs */) {
      _beautifier_edit_profile(cur_prof, langid, &cancelled);
      if (!cancelled) {
         _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 1);
      }
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
   } else {
      // Brings up gui editor for xml/html family of languages.
      //_gibeautifier[CO_PROFILE_NAME] = cur_prof;
      if (idx > 0) {
         _ctl_preview.p_ReadOnly = true;
         call_index(_ctl_preview, langid, cur_prof, idx);
         _ctl_preview.p_ReadOnly = false;
         _beautifier_cache_clear(langid);
         _beautifier_profile_changed(cur_prof,langid);
         update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid,
                                _ctl_profile_selection.p_cb_text_box.p_text);
      }
   }
#endif
   update_button_state(langid, cur_prof);
}

void _ctl_delete_profile.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;
   mbrc:=IDYES;

   if (!_beautifier_is_system_profile(langid,cur_prof)) {
      mbrc = _message_box("Are you sure you want to delete the profile '"cur_prof"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
   }

   if (mbrc == IDYES) {
      _plugin_delete_profile(vsCfgPackage_for_LangBeautifierProfiles(langid),cur_prof);
      repopulate_profile_list('', langid);
      cur_prof = _ctl_profile_selection.p_cb_text_box.p_text;
      update_button_state(langid, cur_prof);
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
   }
}
void _ctl_reset_profile.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;
   mbrc:=IDYES;

   mbrc = _message_box("Are you sure you want to reset changes to the built-in profile '"cur_prof"'?  This action can not be undone.", "Confirm Profile Reset", MB_YESNO | MB_ICONEXCLAMATION);

   if (mbrc == IDYES) {
      _plugin_delete_profile(vsCfgPackage_for_LangBeautifierProfiles(langid),cur_prof);
      repopulate_profile_list(cur_prof, langid);
      update_button_state(langid, cur_prof);
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
   }
}

int _beautifier_create_profile(_str langId,_str profileName,_str fromProfileName=BEAUTIFIER_DEFAULT_PROFILE) {
    ibeautifier:=_beautifier_create(langId);
    if (fromProfileName=='') {
       fromProfileName=BEAUTIFIER_DEFAULT_PROFILE;
    }
    status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),fromProfileName);
    if (status) {
       status=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),BEAUTIFIER_DEFAULT_PROFILE);
    }
    status=_beautifier_save_profile(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
    _beautifier_destroy(ibeautifier);
    return status;
}
void _beautifier_list_profiles(_str langId,_str (&profileNames)[]) {
   _plugin_list_profiles(vsCfgPackage_for_LangBeautifierProfiles(langId),profileNames);
}

bool _beautifier_is_system_profile(_str langId,_str profileName) {
   return _plugin_has_builtin_profile(vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
}

void _ctl_create_profile.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;

   needToPrompt := true;
   _str prof;

   while (needToPrompt) {
      needToPrompt = false;
      mbrc := textBoxDialog("Copy Profile: "cur_prof, 0, 0, "", "", "", "Enter a new profile name:");

      if (mbrc == COMMAND_CANCELLED_RC) {
         return;
      } else {
         prof = strip(_param1);
         if (_plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(langid),prof)) {
            mbrc = _message_box("A profile named '"prof"' already exists.  Overwrite it?", "Confirm Overwrite", MB_YESNO);
            if (mbrc != IDYES) {
               needToPrompt = true;
            }
         }
      }
   }
   brc := _beautifier_create_profile(langid, prof, cur_prof);
   if (brc == 0) {
      repopulate_profile_list(prof, langid);
      update_button_state(langid, prof);
      beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
   } else {
      _message_box("Failure creating new profile. (rc="brc")");
   }
}

void _new_beautifier_options(_str lang='') {
   if (lang == '') {
      lang = p_LangId;
   }

   supports_profiles  := _plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(lang),BEAUTIFIER_DEFAULT_PROFILE);
   if (supports_profiles) {
      // cheap.
      setupext('-formatting 'lang);
   } else {
      _message_box('"'LanguageSettings.getModeName(lang)'" does not have a beautifier.');
   }
}




/**
 * @param lang Language id
 *
 * @return int Amount to indent member access specifiers by, or
 *         0 for no indent.
 */
int beaut_member_access_indent()
{
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      if (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS) == '1') {
         return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_MEMBER_ACCESS);
      } else {
         return 0;
      }
   } else {
      if (def_indent_member_access_specifier) {
         return p_SyntaxIndent;
      } else {
         return 0;
      }
   }
}


static _str gKeywordToConfigKey:[] = {
   'if' => VSCFGP_BEAUTIFIER_BRACELOC_IF,
   'else' => VSCFGP_BEAUTIFIER_BRACELOC_IF,
   'else if' => VSCFGP_BEAUTIFIER_BRACELOC_IF,
   'case' => VSCFGP_BEAUTIFIER_BRACELOC_CASE,
   'switch' => VSCFGP_BEAUTIFIER_BRACELOC_SWITCH,
   'while' => VSCFGP_BEAUTIFIER_BRACELOC_WHILE,
   'for' => VSCFGP_BEAUTIFIER_BRACELOC_FOR,
   'do' => VSCFGP_BEAUTIFIER_BRACELOC_DO,
   'try' => VSCFGP_BEAUTIFIER_BRACELOC_TRY,
   'catch' => VSCFGP_BEAUTIFIER_BRACELOC_CATCH,
   'finally' => VSCFGP_BEAUTIFIER_BRACELOC_CATCH,
   'asm' => VSCFGP_BEAUTIFIER_BRACELOC_ASM,
   '_asm' => VSCFGP_BEAUTIFIER_BRACELOC_ASM,
   '__asm' => VSCFGP_BEAUTIFIER_BRACELOC_ASM,
   'namespace' => VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE,
   'class' => VSCFGP_BEAUTIFIER_BRACELOC_CLASS,
   'struct' => VSCFGP_BEAUTIFIER_BRACELOC_CLASS,
   'union' => VSCFGP_BEAUTIFIER_BRACELOC_CLASS,
   'enum'  => VSCFGP_BEAUTIFIER_BRACELOC_ENUM,
   '@interface' => VSCFGP_BEAUTIFIER_BRACELOC_CLASS,  //TODO: does this get its own brace loc?
};

int beaut_style_for_keyword(_str rawKw, bool& found)
{
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);

      if (ibeautifier>=0) {
         update_profile_from_aff(ibeautifier);
         _str* idx = gKeywordToConfigKey._indexin(rawKw);

         if (!idx) {
            // Completion for some languages has more than just
            // the keyword.
            kw := strip(translate(rawKw, '      ', '{}() \t'));
            idx = gKeywordToConfigKey._indexin(kw);
         }

         if (idx) {
             /*
             This have been changed to use the same property names.

             if (lang == 'cs') {
                // C# has a couple of settings that should have been shared, but are separate.
                if (*idx == VSCFGP_BEAUTIFIER_BRACELOC_ENUM) {
                   return beautifier_xlat_brace_loc(beautCfg[CS_BRACELOC_ENUM]);
                } else if (*idx == CPPB_BRACE_LOC_NAMESPACE) {
                   return beautifier_xlat_brace_loc(beautCfg[CS_BRACELOC_NAMESPACE]);
                }
             } else if (lang == 'java' && *idx == CPPB_BRACE_LOC_ENUM) {
                return beautifier_xlat_brace_loc(beautCfg[JAVA_ENUM_BRACELOC]);
             }
            */
            return beautifier_xlat_brace_loc(_beautifier_get_property(ibeautifier,*idx));
         }
      }
   }
   return p_begin_end_style;
}



static long _expand_forward_context(long to_offset) {
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   // beautify_snippet will take care of leading context that comes
   // from beautifying this range, but does not push farther forward
   // in the file.
   status := search('\{', 'R@XCS');
   if (status == 0 && _QROffset()<to_offset) {
      if (find_matching_paren(true) == 0) {
         _end_line();
         to_offset = max(_QROffset(), to_offset);
         if (def_beautifier_debug > 1)
            say("_expand_forward_context: lbrace extended to="to_offset);
      }
   }

   restore_search(s1, s2, s3, s4, s5);
   return to_offset;
}


static long _calc_selection_to_offset(long dest_offset, int num_sel_lines, long &sel_start, long& sel_end) {
   save_pos(auto p1);
   _GoToROffset(dest_offset);

   // Calculate sel_start so we're on something other than whitespace, if possible.
   search('[^ \t]', 'rh@');
   sel_start = _QROffset();

   p_line += max(0, num_sel_lines-1);
   _end_line();
   to_offset := _QROffset();

   // We also want the end of selection to be in a non-whitespace token,
   //  if possible.
   search('[^ \t', 'rh@-');
   sel_end = _QROffset();

   if (def_beautifier_debug > 1)
      say("_calc_selection_to_offset: orig="dest_offset", to="to_offset);

   _GoToROffset(dest_offset);
   to_offset = _expand_forward_context(to_offset);
   restore_pos(p1);
   return to_offset;
}

/**
 * Given offsets from a dragged selection, beautifies an
 * appropriate range of code for the selection.
 *
 * @param sel_type
 * @param sel_src Offset of the selection before it was dragged.
 * @param dest_offset Offset somewhere in the first line of
 *                  there the selection was dragged.
 * @param num_sel_lines Number of lines in the selection.
 */
void beautify_moved_selection(_str sel_type, long sel_src, long dest_offset, int num_sel_lines) {
   if (def_beautifier_debug > 1)
      say('beautify_moved_selection(sel_type='sel_type' sel_src='sel_src' dest_offset='dest_offset' num_sel_lines='num_sel_lines' )');

   if (!beautify_paste_expansion(p_LangId) || !gAllowBeautifyCopy)
      return;

   if (!_macro('S')) {
      _undo('S');
   }

   // Cursor is positioned at the end of the selection when we're called.
   end_of_sel_actual := _QROffset();

   to_offset := _calc_selection_to_offset(dest_offset, num_sel_lines, auto destsel_start, auto destsel_end);

   // We want to have the beautifier track whatever line of the selection
   // our caller left the cursor on, but preserve the column number.
   savecol := p_col;
   long markers[];

   // Map destination selection area to beautified version.
   markers[0] = destsel_start;
   markers[1] = destsel_end;
   markers[2] = end_of_sel_actual;

   new_beautify_range(min(dest_offset, sel_src, to_offset),
                      max(to_offset, sel_src, dest_offset), markers, true, false, true);

   if (sel_type == 'LINE') {
      // Always select the copied text when it's being dragged/moved through the document.
      save_pos(auto p1);
      _deselect();
      _GoToROffset(markers[0]);
      _select_line();
      _GoToROffset(markers[1]);
      _select_line('', 'EP');
      _show_selection();
      restore_pos(p1);
   } else if (sel_type == 'CHAR') {
      save_pos(auto p1);
      _deselect();
      _GoToROffset(markers[0]);
      _select_char();
      _GoToROffset(markers[2]);
      _select_char('', 'EP');
      _show_selection();
      restore_pos(p1);
   }

   p_col = savecol;
}


/**
 * Called with the cursor at the end of the selection,
 * expands the area to be beautified out as necessary to include
 * areas exposed braces being moved.
 *
 *
 *
 * @param num_sel_lines
 */
void beautify_pasted_code(_str sel_type, long from_offset, int num_sel_lines) {
   if (!beautify_paste_expansion(p_LangId) || !gAllowBeautifyCopy)
      return;

   save_pos(auto end_of_dest_sel);
   to_offset := _calc_selection_to_offset(from_offset, num_sel_lines, auto destsel_start,
                                          auto destsel_end);

   restore_pos(end_of_dest_sel);
   if (!_macro('S')) {
      _undo('S');
   }

   // For line selectiosn, we want to have the beautifier track whatever line of the selection
   // our caller left the cursor on, but preserve the column number.
   savecol := p_col;
   long markers[];

   new_beautify_range(from_offset, to_offset, markers, true, false, false);

   if (sel_type == 'LINE') {
      p_col = savecol;
   }
}


/**
 * Returns true if the default beautifier configuration for
 * 'lang' indents class members relative to the indent for the
 * member access specifiers.
 *
 * @param lang Language id.
 */
bool beaut_indent_members_from_access_spec() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      return _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS_RELATIVE) == '1';
   } else {
      return true;
   }
}

/**
 * @param lang
 *
 * @return int Amount to indent the case statement by.
 */
int beaut_case_indent() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      update_profile_from_aff(ibeautifier);
      if (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE) == '1') {
         return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CASE);
      } else {
         return 0;
      }
   } else {
      if (p_indent_case_from_switch) {
         return p_SyntaxIndent;
      } else {
         return 0;
      }
   }
}

/**
 *
 * @param lang
 *
 * @return int COMBO_AL_AUTO|COMBO_AL_CONT|COMBO_AL_PARENS
 */
int beaut_funcall_param_alignment() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      value:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_LISTALIGN_FUN_CALL_PARAMS);
      if (!isinteger(value)) {
         say('VSCFGP_BEAUTIFIER_FUNCALL_PARAM_ALIGN not valid');
         return COMBO_AL_AUTO;
      }
      return (int)value;
   } else {
      if (LanguageSettings.getUseContinuationIndentOnFunctionParameters(lang,0)) {
         return COMBO_AL_CONT;
      } else {
         return COMBO_AL_AUTO;
      }
   }
}

int beaut_expr_paren_alignment() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      value:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_LISTALIGN2_EXPR_PARENS);
      if (!isinteger(value)) {
         say('VSCFGP_BEAUTIFIER_LISTALIGN2_EXPR_PARENS not valid');
         return COMBO_AL_AUTO;
      }
      return (int)value;
   } else {
      if (LanguageSettings.getUseContinuationIndentOnFunctionParameters(lang,0)) {
         return COMBO_AL_CONT;
      } else {
         return COMBO_AL_AUTO;
      }
   }
}

int beaut_continuation_indent() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION);
   } else {
      return p_SyntaxIndent;
   }
}

int beaut_oneline_unblocked_statement() {
   lang := p_LangId;
   if (!has_beautifier_profiles(lang)) return 0;
   ibeautifier := _beautifier_cache_get(lang,p_buf_name);
   return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_STATEMENT);
}

int beaut_oneline_unblocked_then() {
   lang := p_LangId;
   if (!has_beautifier_profiles(lang)) return 0;
   ibeautifier := _beautifier_cache_get(lang,p_buf_name);
   return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_ELSE);
}

int beaut_oneline_unblocked_else() {
   lang := p_LangId;
   if (!has_beautifier_profiles(lang)) return 0;
   ibeautifier := _beautifier_cache_get(lang,p_buf_name);
   return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ONELINE_UNBLOCKED_THEN);
}

int beaut_initial_anonfn_indent() {
   lang := p_LangId;
   if (lang == 'm' || lang == 'js') {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_OBJC_INDENT_WIDTH_LAMBDA_BODY /*VSCFGP_BEAUTIFIER_BLOCK_INITIAL_INDENT*/);
   } else {
      return p_SyntaxIndent;
   }
}

int beaut_method_decl_continuation_indent() {
   lang := p_LangId;
   if (lang == 'm') {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      if ((int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_OBJC_LISTALIGN2_METH_CALL_BRACKETS) == COMBO_AL_CONT) {
         return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION);
      } else {
         return 0;
      }
   } else {
      return 0;
   }
}

int beaut_should_indent_namespace() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      if (lang == 'phpscript') {
         // Workaround for v21 only, this is fixed in later versions by including
         // this setting in the default profile.
         return 1;
      } else {
         ibeautifier := _beautifier_cache_get(lang,p_buf_name);
         return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_NAMESPACE_BODY);
      } 
   } else {
      return 1;
   }
}

// Returns non-zero if anonymous function code should be indented relative to
// the column that the introducing keyword is in.
int beaut_anon_fn_indent_relative() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang) && lang == 'js') {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_FUN_RELATIVE_TO_KEYWORD);
   } else {
      return 0;
   }
}

int beaut_should_indent_extern() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang) &&
       (lang == 'c' || lang == 'm')) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      return (int)_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_EXTERN_BODY);
   } else {
      return 1;
   }
}

// For C++/Obj-C, if there's a leading colon for a constructor initializer, 
// should give it a continuation indent, or leave it at the same level as the 
// constructor function decl?
bool beaut_should_indent_leading_cons_colon()
{
   rv := false;

   if (p_LangId == 'c' || p_LangId == 'm') {
      ibeautifier := _beautifier_cache_get(p_LangId,p_buf_name);
      rv = _beautifier_get_property(ibeautifier, "indent_leading_cons_colon") != 0;
   }

   return rv;
}

int beaut_brace_indents_with_case() {
   lang := p_LangId;
   if (has_beautifier_profiles(lang)) {
      ibeautifier := _beautifier_cache_get(lang,p_buf_name);
      val:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ALIGN_LBRACE_WITH_CASE);
      if (isinteger(val)) {
         return (int)val;
      } else {
         return 0;
      }
   } else {
      return 0;
   }
}


/**
 * Returns true if we should beautify code as the user types.
 */
bool beautify_on_edit(_str lang=null) {
   if (lang==null) {
      if (_ConcurProcessName()!=null) {
         return false;
      }
      lang=p_LangId;
   }
   supported := (_LanguageInheritsFrom('xml', lang) || _LanguageInheritsFrom('html', lang) || _haveBeautifiers()) &&
                 // Since users can turn on beautify while typeing for "All languages" (I did),
                 // It needs to be turned off for Groovy and Scala which don't support it. There needs
                 // to be a supports_beautify_while_typing property.
                 !_LanguageInheritsFrom('groovy', lang) && !_LanguageInheritsFrom('scala', lang);

   return (supported && has_beautifier_profiles(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_ON_EDIT) != 0);
}

/**
 * Returns true if we should beautify syntax expansions.
 */
bool beautify_syntax_expansion(_str lang) {
   return (_haveBeautifiers() && new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_SYNTAX) != 0);
}


/**
 * Returns true if we should beautify syntax expansions.
 */
bool beautify_alias_expansion(_str lang) {
   // For XML/HTML, we associate alias expansion flag with beautify on typing.
   if (_LanguageInheritsFrom('xml', lang) || _LanguageInheritsFrom('html', lang)) {
      return beautify_on_edit(lang);
   }

   return (_haveBeautifiers() && new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_ALIAS) != 0);
}

/**
 * Returns true if we should beautify syntax expansions.
 */
bool beautify_paste_expansion(_str lang) {
   return (_haveBeautifiers() && new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_PASTE) != 0);
}


static int gDragBlockMarkerType = -1;

static int get_drag_mode_block_marker_type()
{
   if (gDragBlockMarkerType < 0) {
      gDragBlockMarkerType = _MarkerTypeAlloc();
   }
   _MarkerTypeSetFlags(gDragBlockMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE|VSMARKERTYPEFLAG_DRAW_BOX);
   return gDragBlockMarkerType;
}

_command void pk_drag() name_info(',')
{
   int highlight_marker;

   _begin_select();
   _get_selinfo(auto s1, auto s2, auto s3, '', auto s4, auto s5, auto s6, auto num_lines);
   initial_line := p_line;
   current_line := p_line;

   highlight_marker = _LineMarkerAdd(p_window_id,
                                     initial_line, false, num_lines,
                                     0, get_drag_mode_block_marker_type(),
                                     ''
                                     );

   typeless fg, bg;
   parse _default_color(CFG_BLOCK_MATCHING) with fg bg . ;
   _LineMarkerSetStyleColor(highlight_marker,fg);

   saved_line_insert := def_line_insert;

   for (;;) {
      ev := get_event();
      if (ev == ESC) {
         // Cancel, put everything back.
         if (current_line < initial_line
             || current_line >= (initial_line+num_lines)) {
            undo();
            undo();
         }
         break;
      } else if (ev == ENTER || ev == TAB) {
         // leave it where it is.
         break;
      }

      if (current_line < initial_line
          || current_line >= (initial_line+num_lines)) {
         undo();
         undo();
      }

      _deselect();
      p_line = initial_line;
      _select_line();
      p_line += num_lines-1;
      _select_line('', 'P');
      _show_selection('');

      switch (name_on_key(ev)) {
      case 'cursor-up':
         if (current_line > 1) {
            current_line--;
         }
         if (current_line >= initial_line
             && current_line < (initial_line+num_lines)) {
            current_line = initial_line;
         }
         break;

      case 'cursor-down':
         if (current_line == initial_line) {
            current_line += num_lines;
         } else {
            current_line++;
         }
         break;

      }

      if (current_line < initial_line) {
         def_line_insert = 'B';
      } else {
         def_line_insert = 'A';
      }

      _LineMarkerRemove(highlight_marker);
      p_line = current_line;
      _copy_or_move('', 'M', true, true);

      hl_line := current_line;
      if (current_line > initial_line) {
         hl_line -= num_lines-1;
      }
      highlight_marker = _LineMarkerAdd(p_window_id,
                                        hl_line, false, num_lines,
                                        0, get_drag_mode_block_marker_type(),
                                        ''
                                        );
      _LineMarkerSetStyleColor(highlight_marker,fg);
   }
   _LineMarkerRemove(highlight_marker);
   def_line_insert = saved_line_insert;
}

_str beautifier_mode_for_extension(_str file_ext)
{
   return ExtensionSettings.getLangRefersTo(file_ext);
}

bool beautifier_should_delay_brace_decision()
{
   lang := p_LangId;
   if (!new_beautifier_supported_language(lang)) {
      return false;
   }

   ibeautifier := _beautifier_cache_get(lang,p_buf_name);
   return _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_LEAVE_CLASS_ONE_LINE_BLOCK)!=0;
}

// helper for align variables, makes sure the variable aligment settings are enabled
// when trying to align the variables.
static void _enable_aligment_settings(int ibeautifier)
{
   val:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_JUSTIFY_VAR_DECLS);
   if (isinteger(val)) {
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_JUSTIFY_VAR_DECLS,(_str)((int)val));
   }
   val=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_JUSTIFY_MEMBER_VAR_DECLS);
   if (isinteger(val)) {
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_JUSTIFY_MEMBER_VAR_DECLS,(_str)((int)val));
   }
}

_command void align_variables() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return;
   }

   long markers[];

   if (!new_beautifier_supported_language(p_LangId)) {
      message('align_variables: Language not supported');
      return;
   }

   _begin_select();
   starto := _QROffset();

   _end_select();
   endo   := _QROffset();

   // BEUAT_FLAT_EXACT_CONTEXT forces the beautifier to eat a lot of the file, but
   // we absolutely have to know if the vars selected are class vars, or locals
   // to be able to do this correctly.
   new_beautify_range(starto, endo, markers, false, false, false, BEAUT_FLAG_SNIPPET|BEAUT_FLAG_EXACT_CONTEXT, _enable_aligment_settings);
}


_OnUpdate_align_variables(CMDUI cmdui,int target_wid,_str command)
{
   if (!_haveBeautifiers()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
      }
      return MF_DELETED|MF_REQUIRES_PRO;
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (!new_beautifier_supported_language(target_wid.p_LangId)) {
      return (MF_GRAYED);
   }

   return(MF_ENABLED);
}

/**
 * Beautifier supports "beautify while typing".
 */
bool beautifier_supports_typing(_str langId)
{
   return new_beautifier_supported_language(langId) && langId != 'scala' && langId != 'vbs' && langId != 'groovy' && langId != 'bas' && langId != 'json';
}

_command void toggle_beautify_on_edit() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   exp := LanguageSettings.getBeautifierExpansions(p_LangId);

   if (exp & BEAUT_EXPAND_ON_EDIT) {
      LanguageSettings.setBeautifierExpansions(p_LangId, exp & ~BEAUT_EXPAND_ON_EDIT);
   } else {
      LanguageSettings.setBeautifierExpansions(p_LangId, exp | BEAUT_EXPAND_ON_EDIT);
   }
}

bool markup_formatting_supported(_str langId)
{
   return _LanguageInheritsFrom('xml', langId) || _LanguageInheritsFrom('html', langId) || _haveBeautifiers();
}

int _OnUpdate_toggle_beautify_on_edit(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   if (!markup_formatting_supported(p_LangId)) {
      return (MF_GRAYED|MF_UNCHECKED);
   }
   if(target_wid._ConcurProcessName()!=null) { 
      return (MF_GRAYED|MF_UNCHECKED);
   }

   lang := p_LangId;
   if (!new_beautifier_supported_language(lang) || !beautifier_supports_typing(lang)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   if (beautify_on_edit(lang)) {
      return(MF_CHECKED|MF_ENABLED);
   } else {
      return(MF_UNCHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_GRAYED);
}

static _str bs_list[] = { CBV_SAMELINE, CBV_NEXTLINE, CBV_NEXTLINE_IN };
static _str fp_list[] = { CBV_AL_AUTO, CBV_AL_CONT, CBV_AL_PARENS };

defeventtab _language_settings_standard;
void _ctl_quick_brace.on_create()
{
   populatecb(_control _ctl_brace_style, 0, bs_list);
   populatecb(_control _ctl_func_param_align_combo, 0, fp_list);
}


void _ctl_brace_style.on_change(int reason)
{
   clike_update_brace_ex(_ctl_brace_style, _control _brace_style_example);
}

static void update_indent_access()
{
   access_indented := _ctl_indent_access.p_value != 0;
   _ctl_indent_from_access.p_enabled = access_indented;

   if (!access_indented) {
      _ctl_indent_from_access.p_value = 0;
   }
}

void _ctl_indent_access.lbutton_up()
{
   update_indent_access();
}

// Standard profile handling for settings that require
// per-language differences, or translation between the
// dialog values and profile values.
//
static int isetting(int ibeautifier,_str propName)
{
   return _beautifier_get_property(ibeautifier,propName)?1:0;
}

static _str st_get_brace_style(int ibeautifier)
{
   bs := isetting(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF);

   switch (bs) {
   case COMBO_NEXTLINE:
      return CBV_NEXTLINE;
   case COMBO_NEXTLINE_IN:
      return CBV_NEXTLINE_IN;
   case COMBO_SAMELINE:
   default:
      return CBV_SAMELINE;
   }
}

static void st_set_brace_style(int ibeautifier,_str bs)
{
   _str pval;

   if (bs == CBV_NEXTLINE) {
      pval = (_str)COMBO_NEXTLINE;
   } else if (bs == CBV_NEXTLINE_IN) {
      pval = (_str)COMBO_NEXTLINE_IN;
   } else {
      pval = (_str)COMBO_SAMELINE;
   }

   // There's no reason why we can't set all of these, even
   // for languages that don't support them.
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CATCH, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CASE, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_CLASS, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_DO, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FOR, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_FUN, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_SWITCH, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_TRY, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_WHILE, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ASM, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_ENUM, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_NAMESPACE, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_STRUCT, pval);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_UNION, pval);
}

static _str st_get_fun_param_align(int ibeautifier)
{
   fpa := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_LISTALIGN_FUN_CALL_PARAMS);
   switch (fpa) {
   case COMBO_AL_PARENS:
      return CBV_AL_PARENS;
   case COMBO_AL_CONT:
      return CBV_AL_CONT;
   case COMBO_AL_AUTO:
   default:
      return CBV_AL_AUTO;
   }
}

static void st_set_fun_param_align(int ibeautifier,_str fpa) {
   _str val;

   if (fpa == CBV_AL_CONT) {
      val = (_str)COMBO_AL_CONT;
   } else if (fpa == CBV_AL_PARENS) {
      val = (_str)COMBO_AL_PARENS;
   } else {
      val = (_str)COMBO_AL_AUTO;
   }

   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_LISTALIGN_FUN_CALL_PARAMS,val);
}

static int st_get_use_tabs(int ibeautifier)
{
   return isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS);
}

static void st_set_use_tabs(int ibeautifier,int ut)
{
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,(ut!=0)?1:0);
}

static int st_get_padparens(int ibeautifier)
{
   return isetting(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS);
}

static void st_set_space_prop(int ibeautifier,_str key,_str val,_str langId='') {
   if (langId!="as" && langId!="e" || key!="sp_if_before_lparen") {
      _beautifier_get_property(ibeautifier,key, val, auto apply);
      _beautifier_set_property(ibeautifier,key, val, apply);
      return;
   }
   _beautifier_set_property(ibeautifier,key, val);
}

static void st_set_padparens(int ibeautifier,int flag)
{
   val := flag ? (_str)1 : (_str)0;

   // Set all of the control statement padparen settings.
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_LOCK_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_USING_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_TRY_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_SYNCHRONIZED_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_CATCH_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_FOR_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_RETURN_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_SWITCH_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_THROW_PARENS, val);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_WHILE_PARENS, val);
}

static int st_get_space_before_paren(int ibeautifier)
{
   return isetting(ibeautifier,VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN);
}

static void st_set_space_before_paren(int ibeautifier,int flag,_str langId) {
   val := flag ? (_str)1 : (_str)0;

   // Set all of the control statement lparen settings.
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_LOCK_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_USING_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_TRY_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_SYNCHRONIZED_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_CATCH_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_FOR_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_SWITCH_BEFORE_LPAREN, val,langId);
   st_set_space_prop(ibeautifier,VSCFGP_BEAUTIFIER_SP_WHILE_BEFORE_LPAREN, val,langId);
}

static void _beautifier_set_wc_property_in_beautifier_profile(int ibeautifier,_str key,_str value,_str langId,_str profileName) {
   epackage:=vsCfgPackage_for_LangBeautifierProfiles(langId);
   if (!_plugin_has_property(epackage, BEAUTIFIER_DEFAULT_PROFILE, key)) {
       return;
   }
   if (value<0) {
       // Turn off apply but keep value;
       cmvalue := _plugin_get_property(epackage, profileName, key, value,false,1 /* Want built-in property value, not user value */); 
       apply := false;
       _beautifier_set_property(ibeautifier, key, cmvalue, apply);
       return;
   }
   apply := true;
   _beautifier_set_property(ibeautifier, key, value, apply);
   return;
   
}
// Options dialog integration.
//

void _language_settings_standard_init_for_options(_str langId)
{
   ibeautifier := _beautifier_cache_get(langId, SETUP_BUFFER);
   _set_language_form_lang_id(langId);

   //gCurrentLanguage = langId;

   // Visibility for per-language options.
   if (langId == 'c' || langId == 'm') {
      _ctl_indent_namespace.p_visible = true;
      _ctl_indent_extern.p_visible = true;
      _ctl_indent_access.p_visible = true;
      _ctl_indent_from_access.p_visible = true;
   } else if (langId == 'vbs' || langId == 'bas' || langId=='ada') {
       // Away with the brace style, and bring in the keyword case
       // frame.
       frame1.p_visible = false;
       kwd_case_frame.p_visible = true;
       kwd_case_frame.p_height = frame1.p_height;
       kwd_case_frame.p_x = frame1.p_x;
       kwd_case_frame.p_y = frame1.p_y;
       _ctl_func_param_align_combo.p_visible = false;
       _ctl_func_param_lbl.p_visible = false;
       _ctl_quick_brace.p_visible = false;
       _ctl_else_sameline.p_visible = false;
       _ctl_indent_first_level.p_visible = false;
       _ctl_indent_case.p_visible = false;
       _ctl_space_before_paren.p_visible = false;
       _ctl_pad_parens.p_visible = false;
       _indent_case_ad_form_link.p_visible = false;
       _no_space_ad_form_link.p_visible = false;
       _pad_parens_ad_form_link.p_visible = false;
   } else if (langId == 'systemverilog' || langId == 'verilog') {
      topy := _ctl_func_param_align_combo.p_y;
      ht := _ctl_indent_case.p_y - _ctl_indent_first_level.p_y;

      _ctl_space_before_paren.p_y = topy;
      _ctl_pad_parens.p_y = topy + ht;

      _ctl_space_before_paren.p_visible = false;
      _ctl_pad_parens.p_visible = false;

      _ctl_func_param_align_combo.p_visible = false;
      _ctl_func_param_lbl.p_visible = false;
      _ctl_quick_brace.p_visible = false;
      _ctl_else_sameline.p_visible = false;
      _ctl_indent_first_level.p_visible = false;
      _ctl_indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;
   } else if (langId == 'py') {
      frame1.p_visible = false;
      _ctl_func_param_align_combo.p_visible = false;
      _ctl_func_param_lbl.p_visible = false;
      _ctl_quick_brace.p_visible = false;
      _ctl_else_sameline.p_visible = false;
      _ctl_indent_first_level.p_visible = false;
      _ctl_indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;
      _ctl_func_param_align_combo.p_visible=false;
      _ctl_pad_parens.p_visible=false;
      _pad_parens_ad_form_link.p_visible = false;
      _ctl_space_before_paren.p_visible=false;
      _no_space_ad_form_link.p_visible = false;
   }

   if (frame1.p_visible) {
       _ctl_brace_style.p_cb_text_box.p_text = st_get_brace_style(ibeautifier);
       clike_update_brace_ex(_ctl_brace_style, _brace_style_example);
   }
   if (_ctl_func_param_align_combo.p_visible) {
       _ctl_func_param_align_combo.p_cb_text_box.p_text = st_get_fun_param_align(ibeautifier);
   }
   _ctl_use_tabs.p_value = st_get_use_tabs(ibeautifier);
   _ctl_indent.p_text = _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT);
   _ctl_tab_size.p_text = _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);
   if (_ctl_quick_brace.p_visible) {
       _ctl_quick_brace.p_value = (int)LanguageSettings.getQuickBrace(langId);
   }
   if (_ctl_else_sameline.p_visible) {
       _ctl_else_sameline.p_value = (int)(!xlat_yn(_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE)));
   }
   if (_ctl_indent_first_level.p_visible) {
       _ctl_indent_first_level.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_FIRST_LEVEL);
   }

   if (_ctl_indent_case.p_visible) {
       _ctl_indent_case.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE);
   }

   if (_ctl_space_before_paren.p_visible) {
       _ctl_space_before_paren.p_value = st_get_space_before_paren(ibeautifier);
   }

   if (_ctl_pad_parens.p_visible) {
       _ctl_pad_parens.p_value = st_get_padparens(ibeautifier);
   }

   if (_ctl_indent_namespace.p_visible)
      _ctl_indent_namespace.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_NAMESPACE_BODY);

   if (_ctl_indent_extern.p_visible) {
      _ctl_indent_extern.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_EXTERN_BODY);
   }

   if (_ctl_indent_access.p_visible) {
      _ctl_indent_access.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS);
   }

   if (_ctl_indent_from_access.p_visible) {
      _ctl_indent_from_access.p_value = isetting(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS_RELATIVE);
   }

   /*
      This is only visible for VB
   */
   if (kwd_case_frame.p_visible) {
      _str wc;
      bool apply;
      wc=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_WC_KEYWORD,WORDCASE_PRESERVE,apply);
      if (!apply) {
         wc=WORDCASE_PRESERVE;
      }

      switch (wc) {
      case WORDCASE_PRESERVE:
         _none.p_value = 1;
         break;
      case WORDCASE_LOWER:
         _lower.p_value = 1;
         break;
      case WORDCASE_UPPER:
         _upper.p_value = 1;
         break;
      case WORDCASE_CAPITALIZE:
         _capitalize.p_value = 1;
         break;
      }
   }

   setAdaptiveLinks(langId);
   update_indent_access();
   _brace_style_example._use_source_window_font();
}

void _language_settings_standard_restore_state(_str options)
{
   langId:=_get_language_form_lang_id();
   setAdaptiveLinks(langId/*gCurrentLanguage*/);
}

void _language_settings_standard_apply()
{
   langId:=_get_language_form_lang_id();
   ibeautifier := _beautifier_cache_get(langId, SETUP_BUFFER);

   if (frame1.p_visible) {
       st_set_brace_style(ibeautifier,_ctl_brace_style.p_cb_text_box.p_text);
   }

   if (_ctl_func_param_align_combo.p_visible) {
       st_set_fun_param_align(ibeautifier,_ctl_func_param_align_combo.p_cb_text_box.p_text);
   }
   st_set_use_tabs(ibeautifier,_ctl_use_tabs.p_value);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT,_ctl_indent.p_text);
   _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE, normalize_tabs(_ctl_tab_size.p_text));
   if (_ctl_quick_brace.p_visible) {
       LanguageSettings.setQuickBrace(langId, _ctl_quick_brace.p_value != 0);
   }
   if (_ctl_else_sameline.p_visible) {
       _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE, (_ctl_else_sameline.p_value) ? 0 : 1);
   }
   if (_ctl_indent_first_level.p_visible) {
       _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_FIRST_LEVEL,(_str)_ctl_indent_first_level.p_value);
   }

   if (_ctl_indent_case.p_visible) {
       _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE,(_str)_ctl_indent_case.p_value);
   }
   if (_ctl_space_before_paren.p_visible) {
       st_set_space_before_paren(ibeautifier,_ctl_space_before_paren.p_value,langId);
   }

   if (_ctl_pad_parens.p_visible) {
       st_set_padparens(ibeautifier,_ctl_pad_parens.p_value);
   }

   if (_ctl_indent_namespace.p_visible)
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_NAMESPACE_BODY,(_str)_ctl_indent_namespace.p_value);

   if (_ctl_indent_extern.p_visible) {
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_EXTERN_BODY,(_str)_ctl_indent_extern.p_value);
   }

   if (_ctl_indent_access.p_visible) {
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS /*CO_MEMBER_ACCESS_INDENT*/,(_str)_ctl_indent_access.p_value);
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_MEMBER_ACCESS /*CO_MEMBER_ACCESS_INDENT_WIDTH*/, _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT));
   }

   if (_ctl_indent_from_access.p_visible) {
      _beautifier_set_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS_RELATIVE/* CO_MEMBER_ACCESS_RELATIVE_INDENT*/,(_str)_ctl_indent_from_access.p_value);
   }

   if (kwd_case_frame.p_visible) {
      apply:=true;
      _str val= WORDCASE_LOWER;

      if (_lower.p_value) {
          val = WORDCASE_LOWER;
      } else if (_upper.p_value) {
          val = WORDCASE_UPPER;
      } else if (_capitalize.p_value) {
          val = WORDCASE_CAPITALIZE;
      } else if (_none.p_value) {
          //val = _beautifier_get_property(ibeautifier, VSCFGP_BEAUTIFIER_WC_KEYWORD);
          //apply=false;
         val= WORDCASE_PRESERVE;
      }
      _beautifier_set_wc_property_in_beautifier_profile(ibeautifier, VSCFGP_BEAUTIFIER_WC_KEYWORD,val,langId,BEAUTIFIER_DEFAULT_PROFILE);
      //_beautifier_set_property(ibeautifier, VSCFGP_BEAUTIFIER_WC_KEYWORD, (_str)val,apply);
   }

   _beautifier_save_profile(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),BEAUTIFIER_DEFAULT_PROFILE);
   _beautifier_cache_clear(langId);
   _beautifier_profile_changed(BEAUTIFIER_DEFAULT_PROFILE,langId,ibeautifier);
}

bool _language_settings_standard_validate(int action)
{
   if (action == OPTIONS_APPLYING) {
      if (!isinteger(_ctl_indent.p_text)) {
         _ctl_indent._text_box_error("Syntax Indent must be a number.");
         return false;
      }

      iv := (int)_ctl_indent.p_text;
      if (iv < 0) {
         _ctl_indent._text_box_error("Syntax indent must be >= 0");
         return false;
      }

      tv := _ctl_tab_size.p_text;
      rv := pos('^[ \t]*\+?([0-9]+)[ \t]*$', tv, 1, 'U');
      if (rv > 0) {
         nums := substr(tv,pos('S1'),pos('1'));
         num := (int)nums;
         if (num < 1 || num > 500) {
            _ctl_tab_size._text_box_error("Tab must be >= 1 and <= 500");
            return false;
         }
      } else {
         _ctl_tab_size._text_box_error("Only uniform tab stops in the format '+WIDTH' is supported");
         return false;
      }
   }
   return true;
}

_str _language_settings_standard_export_settings(_str &file, _str &args, _str langID)
{
   return _plugin_export_profile(file,vsCfgPackage_for_LangBeautifierProfiles(langID),BEAUTIFIER_DEFAULT_PROFILE,langID);
}

_str _language_settings_standard_import_settings(_str &file, _str &args, _str langID)
{
   error := '';

   if (args == '') {
      // we can't do anything here
      return error;
   }

   return importUserProfile(file, args, langID);
}

static _str importUserProfile(_str srcFile, _str profile, _str langID)
{
   error := '';
   do {
      srcFile=strip(srcFile,'B','"');
      if (endsWith(srcFile,VSCFGFILEEXT_CFGXML,false,_fpos_case)) {
         _plugin_import_profile(srcFile,vsCfgPackage_for_LangBeautifierProfiles(langID),profile,langID);
      } else {
         _convert_new_beautifier_profiles(srcFile,langID,profile);
      }

      LanguageSettings.setBeautifierProfileName(langID, profile);

   } while (false);

   return error;
}

bool  _beautifier_has_property(int ibeautifier,_str name) {
   value:=_beautifier_get_property(ibeautifier,name,null);
   return (value!=null);
}


void _beautifier_list_tags(int ibeautifier,_str (&tagNames)[]) {
   tagNames._makeempty();
   XmlCfgPropertyInfo array[];
   _beautifier_list_properties(ibeautifier,array,'^[^'VSXMLCFG_PROPERTY_SEPARATOR']+'VSXMLCFG_PROPERTY_SEPARATOR'$',"r");
   for (i:=0;i<array._length();++i) {
      _str name=array[i].name;
      tagNames[tagNames._length()]= substr(name,1,length(name)-1);
   }
}
void _beautifier_delete_tag(int ibeautifier,_str tagname ) {
   _beautifier_delete_property(ibeautifier,tagname:+VSXMLCFG_PROPERTY_SEPARATOR,true);
}
void _beautifier_set_tag_property(int ibeautifier,_str tagname,_str propName,_str value,bool apply=null ) {
   _beautifier_set_property(ibeautifier,tagname:+VSXMLCFG_PROPERTY_SEPARATOR:+propName,value,apply);
}
void _beautifier_delete_tag_property(int ibeautifier,_str tagname,_str propName ) {
   _beautifier_delete_property(ibeautifier,tagname:+VSXMLCFG_PROPERTY_SEPARATOR:+propName);
}
_str  _beautifier_get_tag_property(int ibeautifier,_str tagname,_str propName,_str defaultValue='',bool &apply=null) {
   return _beautifier_get_property(ibeautifier,tagname:+VSXMLCFG_PROPERTY_SEPARATOR:+propName,defaultValue,apply);
}
bool  _beautifier_tag_exists(int ibeautifier,_str tagname) {
   value:=_beautifier_get_property(ibeautifier,tagname:+VSXMLCFG_PROPERTY_SEPARATOR,null,null);
   return (value!=null);
}
_str _beautifier_get_tag_standalone(int ibeautifier,_str tagname) {
   nlb := _beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,'',auto nlb_apply);
   nla := _beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,'',auto nla_apply);
   lbw := _beautifier_get_tag_lb_within(ibeautifier,tagname,auto lb_within_apply);

   saVal := '0';

   if ((nlb_apply && nlb != '0') || (nla_apply && nla != '0') || (lb_within_apply && lbw != '0')) {
      saVal = '1';
   }
   return saVal;
}
_str _beautifier_resolve_tag(int ibeautifier,_str tag) {
   // If this tag is not defined
   if (!_beautifier_tag_exists(ibeautifier,tag)) {
      tag=BEAUT_DEFAULT_TAG_NAME;
   } else {
      parent_tag:=_beautifier_get_tag_property(ibeautifier,tag,VSCFGP_BEAUTIFIER_PARENT_TAG);
      if (parent_tag!='') tag=parent_tag;
   }
   return tag;
}

bool _beautifier_get_tag_lb_within(int ibeautifier,_str tagname,bool &apply=null) {
   new_line_after_start_tag:=_beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG, '', auto new_line_after_start_tag_apply);
   if (!isinteger(new_line_after_start_tag)) new_line_after_start_tag=0;
   new_line_before_end_tag:=_beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG, '', auto new_line_before_end_tag_apply);
   if (!isinteger(new_line_before_end_tag)) new_line_before_end_tag=0;

   if (!new_line_after_start_tag_apply || !new_line_before_end_tag_apply) {
      apply=false;
      return false;
   } else {
      apply=true;
   }
   return (new_line_after_start_tag || new_line_before_end_tag)?true:false;
}
_form _beautifier_overrides_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption="Beautifier Profile Overrides";
   p_forecolor=0x80000008;
   p_height=6450;
   p_width=6915;
   p_x=30270;
   p_y=18480;
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption="Path:";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=1;
      p_width=390;
      p_word_wrap=false;
      p_x=225;
      p_y=2445;
   }
   _combo_box ctlpath {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=300;
      p_style=PSCBO_EDIT;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=6300;
      p_x=195;
      p_y=2715;
      p_eventtab2=_ul2_combobx;
   }
   _image ctlchoosepath {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=300;
      p_max_click=MC_SINGLE;
      p_Nofstates=2;
      p_picture="bbbrowse.svg";
      p_stretch=false;
      p_style=PSPIC_BUTTON;
      p_tab_index=3;
      p_tab_stop=false;
      p_value=0;
      p_width=300;
      p_x=6555;
      p_y=2700;
   }
   _tree_view ctltree1 {
      p_after_pic_indent_x=50;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_CheckListBox=false;
      p_ColorEntireLine=false;
      p_EditInPlace=false;
      p_delay=0;
      p_forecolor=0x80000008;
      p_Gridlines=TREE_GRID_NONE;
      p_height=2580;
      p_LevelIndent=300;
      p_LineStyle=TREE_DOTTED_LINES;
      p_multi_select=MS_NONE;
      p_NeverColorCurrent=false;
      p_ShowRoot=false;
      p_AlwaysColorCurrent=false;
      p_SpaceY=50;
      p_scroll_bars=SB_VERTICAL;
      p_UseFileInfoOverlays=FILE_OVERLAYS_NONE;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=5265;
      p_x=210;
      p_y=3330;
      p_eventtab2=_ul2_tree;
   }
   _minihtml ctlminihtml1 {
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_height=1770;
      p_PaddingX=60;
      p_PaddingY=30;
      p_tab_index=5;
      p_tab_stop=true;
      p_text="This dialog creates a .seeditorconfig.xml file in the path specified. <p>Files at or beneath the .seeditorconfig.xml path get the specified beautifier profile overrides. <p>Usually the .seeditorconfigfile.xml is stored at the root path of a source tree to effect all the files in that source tree.";
      p_width=6645;
      p_word_wrap=true;
      p_x=135;
      p_y=135;
      p_eventtab2=_ul2_minihtm;
   }
   _command_button ctladd {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Add...";
      p_default=false;
      p_height=345;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1125;
      p_x=5640;
      p_y=3450;
   }
   _command_button ctledit {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Edit...";
      p_default=false;
      p_height=345;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=1125;
      p_x=5640;
      p_y=3930;
   }
   _command_button ctldelete {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Delete";
      p_default=false;
      p_height=345;
      p_tab_index=8;
      p_tab_stop=true;
      p_width=1125;
      p_x=5640;
      p_y=4410;
   }
   _command_button ctlsave {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Save";
      p_default=false;
      p_height=345;
      p_tab_index=9;
      p_tab_stop=true;
      p_width=1125;
      p_x=225;
      p_y=5985;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Cancel";
      p_default=false;
      p_height=345;
      p_tab_index=10;
      p_tab_stop=true;
      p_width=1125;
      p_x=1530;
      p_y=5985;
   }
   _label ctllabel2 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption=".seeditorconfig.xml profile overrides:";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=11;
      p_width=2655;
      p_word_wrap=false;
      p_x=240;
      p_y=3060;
   }
}

defeventtab _beautifier_overrides_form;
static void puser_set_modified() {
    ctlpath.p_enabled=false;
    ctlchoosepath.p_enabled=false;
    PUSER_MODIFIED(1);
}
static typeless PUSER_MODIFIED(...) { 
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user; 
}
static typeless PUSER_IGNORE_CHANGE(...) { 
   if (arg()) ctlsave.p_user=arg(1);
   return ctlsave.p_user; 
}
static typeless PUSER_TIMER_HANDLE(...) { 
   if (arg()) ctlminihtml1.p_user=arg(1);
   return ctlminihtml1.p_user; 
}
static typeless PUSER_EDITOR_WID(...) { 
   if (arg()) ctlcancel.p_user=arg(1);
   return ctlcancel.p_user; 
}
static typeless PUSER_EXTRAS(...) { 
   if (arg()) ctladd.p_user=arg(1);
   return ctladd.p_user; 
}
static void override_enable_buttons() {
    index:=ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
    if(index<=0) {
        ctledit.p_enabled=ctldelete.p_enabled=false;
        return;
    }
    ctledit.p_enabled=ctldelete.p_enabled=true;
    if (ctltree1._TreeCurIndex()<=0) {
        ctltree1._TreeSetCurIndex(index);
    }
}
void ctlsave.on_create() {
    PUSER_EXTRAS(null);
    PUSER_TIMER_HANDLE(-1);
    PUSER_IGNORE_CHANGE(1);
    col0Width := 1500;
    col1Width := 0;

    ctltree1._TreeSetColButtonInfo(0,col0Width,0 /*TREE_BUTTON_PUSHBUTTON*//*|TREE_BUTTON_SORT*/,0,"Language");
    ctltree1._TreeSetColButtonInfo(1,col1Width,0 /*TREE_BUTTON_PUSHBUTTON*//*|TREE_BUTTON_SORT*/,0,"Beautifier Profile");

    ctlminihtml1._minihtml_UseDialogFont();
    int wid=_form_parent();
    if (!wid || !wid._isEditorCtl()) {
        wid=0;

    } else {
        EDITOR_CONFIG_PROPERITIES ecprops;
        _EditorConfigGetProperties(wid.p_buf_name,ecprops,wid.p_LangId,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
        if (ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) {
            int i;
            len := ecprops.m_option_files._length();
            for (i=len-1;i>=0;--i) {
                name := _strip_filename(ecprops.m_option_files[i],'P');
                if (_file_eq(name,'.seeditorconfig.xml')) {
                    break;
                }
            }
            if (i>=0) {
                ctlpath.p_text=_strip_filename(ecprops.m_option_files[i],'N');
            }
        }
    }
    PUSER_EDITOR_WID(wid);
    PUSER_MODIFIED(0);
    if (_workspace_filename!='') {
        ctlpath._lbadd_item('<Workspace Path>');
        //ctlpath.p_text=_strip_filename(_workspace_filename,'N');
    } 
    if (_project_name!='') {
        ctlpath._lbadd_item('<Project Path>');
        //ctlpath.p_text=_strip_filename(_workspace_filename,'N');
    }
    if (wid) {
        ctlpath._lbadd_item('<Current Buffer Path>');
    }
    PUSER_IGNORE_CHANGE(0);

    ctlpath.call_event(ctlpath,ON_CHANGE,'W');
    sizeBrowseButtonToTextBox(ctlpath.p_window_id, ctlchoosepath.p_window_id, 0, p_active_form.p_width - ctlpath.p_x);
}
void ctlsave.on_destroy() {
    if (PUSER_TIMER_HANDLE()>=0) {
        _kill_timer(PUSER_TIMER_HANDLE());
        PUSER_TIMER_HANDLE(-1);
    }
}
void ctlsave.lbutton_up() {
    _str extras[]=PUSER_EXTRAS();
    filename := absolute(ctlpath.p_text);
    _maybe_append_filesep(filename);
    filename :+= '.seeditorconfig.xml';
    handle:=_xmlcfg_open(filename,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
    if (handle>=0) {
        typeless array;
        _xmlcfg_find_simple_array(handle,"options/*[contains(@n,'^language.','r')]",array);
        foreach (auto i=>auto node in array) {
            _xmlcfg_delete(handle,node);
        }
    } else {
        handle=_xmlcfg_create(filename,VSENCODING_UTF8);
    }
    options_node:=_xmlcfg_set_path(handle,"/options");


    node:=ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
    while (node>=0) {
        parse ctltree1._TreeGetCaption(node) with auto mode_name "\t" auto profile;
        profile_node:=_xmlcfg_add(handle,options_node,'language',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
        _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME,'language.'_Modename2LangId(mode_name));
        property_node:=_xmlcfg_add(handle,profile_node,'beautifier_default_profile',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
        _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE,profile);
        node=ctltree1._TreeGetNextSiblingIndex(node);
    }
    foreach (auto i=>auto value in PUSER_EXTRAS()) {
        parse value with auto langId "\t" auto profile;
        profile_node:=_xmlcfg_add(handle,options_node,'language',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
        _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME,'language.'langId);
        property_node:=_xmlcfg_add(handle,profile_node,'beautifier_default_profile',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
        _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE,profile);
    }
    status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,filename);
    _xmlcfg_close(handle);
    if (status) {
        _message_box(nls("Unable to save '%s'. ",filename):+get_message(status));
        return;
    }
    _EditorConfigClearCache();
    _beautifier_cache_clear('');
    _beautifier_profile_changed('','');
    p_active_form._delete_window(1);
}
void ctlchoosepath.lbutton_up() {
    init_dir := absolute(p_prev.p_text);
    _maybe_append_filesep(init_dir);
    result := _ChooseDirDialog('',init_dir);
    if( result=='' ) return;
    result=strip(result,'B','"');;
    p_prev.p_text=result;
    p_prev._set_sel(1,length(result)+1);
}
static void override_update_file(typeless form_wid) {
    if (!_iswindow_valid(form_wid)) {
        return;
    }
    orig_wid:=p_window_id;
    p_window_id=form_wid;
    _kill_timer(PUSER_TIMER_HANDLE());PUSER_TIMER_HANDLE(-1);
    filename := absolute(ctlpath.p_text);
    _maybe_append_filesep(filename);
    filename :+= '.seeditorconfig.xml';
    handle:=_xmlcfg_open(filename,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
    ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
    PUSER_EXTRAS(null);
    if (handle>=0) {
        typeless array[];
        _xmlcfg_find_simple_array(handle,"options/*[contains(@n,'^language.','r')]",array);
        _str extras[];
         foreach (auto i=>auto profile_node in array) {
             _str n=_xmlcfg_get_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME);
             langId := _plugin_get_profile_name(n);
             if (langId!='') {
                 node:=_xmlcfg_find_child_with_name(handle,profile_node,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
                 if (node<0) {
                     node=_xmlcfg_find_property(handle,profile_node,VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE);
                 }
                 if (node>=0) {
                     _str profile=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
                     if (profile!='') {
                         if (_LangIsDefined(langId)) {
                             ctltree1._TreeAddItem(TREE_ROOT_INDEX,_LangGetModeName(langId)"\t"profile,TREE_ADD_AS_CHILD,0,0,-1);
                         } else {
                             extras[extras._length()]=langId"\t"profile;
                         }
                     }
                 }
             }
         }
         PUSER_EXTRAS(extras);
        _xmlcfg_close(handle);
    }
    p_window_id=orig_wid;
}

void ctlpath.on_change() {
    if(PUSER_IGNORE_CHANGE()) {
        return;
    }
    if (PUSER_TIMER_HANDLE()>=0) {
        return;
    }

    PUSER_IGNORE_CHANGE(1);
    if (strieq(p_text,'<Workspace Path>') && _workspace_filename!='') {
        p_text=_strip_filename(_workspace_filename,'N');
    } else if (strieq(p_text,'<Project Path>') && _project_name!='') {
        p_text=_strip_filename(_project_name,'N');
    } else if (strieq(p_text,'<Current Buffer Path>') && PUSER_EDITOR_WID()!=0) {
        p_text=_strip_filename(PUSER_EDITOR_WID().p_buf_name,'N');
    }
    PUSER_IGNORE_CHANGE(0);

    PUSER_TIMER_HANDLE(_set_timer(500,override_update_file,p_active_form));
}

void ctladd.lbutton_up() {
    result:=show('-modal _override_setting_form');
    if (result=='') {
        return;
    }
    puser_set_modified();
    ctltree1._TreeAddItem(TREE_ROOT_INDEX,_param1"\t"_param2,TREE_ADD_AS_CHILD,0,0,-1);
    override_enable_buttons();
}

void ctledit.lbutton_up() {
    index:=ctltree1._TreeCurIndex();
    if (index<=0) {
        return;
    }
    parse ctltree1._TreeGetCaption(index) with auto mode_name "\t" auto profile;

    result:=show('-modal _override_setting_form',mode_name,profile);
    if (result=='') {
        return;
    }
    puser_set_modified();
    ctltree1._TreeSetCaption(index,_param1"\t"_param2);
}
void ctldelete.lbutton_up() {
    index:=ctltree1._TreeCurIndex();
    if (index<=0) {
        return;
    }
    puser_set_modified();
    ctltree1._TreeDelete(index);
    override_enable_buttons();
}
void ctlcancel.lbutton_up() {
    if (PUSER_MODIFIED()) {
        result:=_message_box('Throw away changes?','',MB_YESNOCANCEL);
        if (result!=IDYES) {
           return;
        }
    }
    p_active_form._delete_window('');
}

_form _override_setting_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption="Override Setting";
   p_forecolor=0x80000008;
   p_height=6660;
   p_width=5685;
   p_x=29895;
   p_y=19020;
   _label ctlmodelabel {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption="Language mode:";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=1;
      p_width=1200;
      p_word_wrap=false;
      p_x=135;
      p_y=135;
   }
   _list_box ctlmode {
      p_border_style=BDS_FIXED_SINGLE;
      p_height=2700;
      p_multi_select=MS_NONE;
      p_scroll_bars=SB_VERTICAL;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=5460;
      p_x=120;
      p_y=405;
      p_eventtab2=_ul2_listbox;
   }
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption="Beautifier Profile";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=3;
      p_width=1185;
      p_word_wrap=false;
      p_x=150;
      p_y=3210;
   }
   _list_box ctlprofile {
      p_border_style=BDS_FIXED_SINGLE;
      p_height=2700;
      p_multi_select=MS_NONE;
      p_scroll_bars=SB_VERTICAL;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=5400;
      p_x=135;
      p_y=3450;
      p_eventtab2=_ul2_listbox;
   }
   _command_button ctlok {
      p_auto_size=false;
      p_cancel=false;
      p_caption="OK";
      p_default=false;
      p_height=345;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=1125;
      p_x=120;
      p_y=6240;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Cancel";
      p_default=false;
      p_height=345;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1125;
      p_x=1620;
      p_y=6240;
   }
}
defeventtab _override_setting_form;
static typeless PUSER_IGNORE_CHANGE2(...) { 
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user; 
}

void ctlok.on_create(_str modeName='',_str profile='') {
    PUSER_IGNORE_CHANGE2(1);
    _str langs[];
    LanguageSettings.getAllLanguageIds(langs);
    foreach (auto i=>auto langId in langs) {
        if (_beautifier_is_supported(langId)) {
            ctlmode._lbadd_item(_LangGetModeName(langId));
        }
    }
    ctlmode._lbtop();
    ctlmode._lbselect_line();
    if (modeName!='') {
        status:=ctlmode._lbsearch('^'_escape_re_chars(modeName)'$','@ri');
        if (!status) {
            ctlmode._lbselect_line();
        }
    }

    PUSER_IGNORE_CHANGE2(0);
    ctlmode.call_event(ctlmode,ON_CHANGE,'W');
    if (profile!='') {
        status:=ctlprofile._lbsearch('^'_escape_re_chars(profile)'$','@ri');
        if (!status) {
            ctlprofile._lbselect_line();
        }
    }
}

void ctlok.lbutton_up() {
    _param1=ctlmode._lbget_text();
    _param2=ctlprofile._lbget_text();
    p_active_form._delete_window(1);
}

void ctlmode.on_change() {
    ctlmode._lbselect_line();

    _str mode_name=ctlmode._lbget_text();
    _str langId=_Modename2LangId(mode_name);
    _str profileNames[];
    _plugin_list_profiles(vsCfgPackage_for_LangBeautifierProfiles(langId),profileNames);
    ctlprofile._lbclear();
    foreach (auto i=>auto value in profileNames) {
        ctlprofile._lbadd_item(value);
    }
    ctlprofile._lbtop();
    ctlprofile._lbselect_line();
}


int _OnUpdate_beautifier_edit_seeditorconfig(CMDUI cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   if (!_haveBeautifiers()) {
       return(MF_GRAYED);
   }
   return MF_ENABLED;
}
_command void beautifier_edit_seeditorconfig() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)  {
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return;
   }
   _mdi.p_child.show('_beautifier_overrides_form');
}
