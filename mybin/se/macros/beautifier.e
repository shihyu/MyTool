////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46084 $
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
#import "guiopen.e"
#import "adaptiveformatting.e"
#import "bookmark.e"
#import "c.e"
#import "config.e"
#import "csbeaut.e"
#import "context.e"
#import "debug.e"
#import "hotspots.e"
#import "listbox.e"
#import "markfilt.e"
#import "mprompt.e"
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

#define BEAUTIFIER_XML_TAG_ROOT        "profiles"
#define BEAUTIFIER_XML_TAG_PROFILE     "profile"

// All languages supported by the new beautifier.
_str ALL_BEAUT_LANGUAGES[] = {'c', 'm', 'java', 'cs'};

/**
 * Saves a profile configuration that was loaded with 
 * beautifier_load_profile.   
 *  
 * @param options Option array from beautifier_load_profile
 * 
 * @return int 0 on success, error code on error.
 */
extern int beautifier_save_profile(_str (&options)[]);

extern _str beautifier_load_profile(_str profile_name, _str lang_id, int& status)[];

/**
 * Beautifies the current buffer in editor control 'wid'
 * 
 * 
 * @param wid 
 * @param locations Array of offsets in the source that will be 
 *                  mapped to new locations in the beautified
 *                  source.
 * 
 * @return int 0 on success, error code on error.
 */
extern int beautify_buffer(int wid, long (&locations)[], int beaut_flags);


/**
 * Beautifies the source between source_offset and end_offset. 
 * This processes the _entire_ buffer, (even though only the 
 * selection is modified); for effenciency, use the
 * beautify_snippet() or new_beautify_selection(). 
 *  
 * @param wid 
 * @param locations Array of offsets in the source that will be 
 *                  mapped to new locations in the beautified
 *                  source.
 * @param start_offset 
 * @param end_offset 
 * 
 * @return int 0 on success, or an error code on error.
 */
extern int beautify_buffer_selection(int wid, long (&locations)[], long& start_offset, long& end_offset, int initial_indent, int beaut_flags);

/**
 * Returns an array of the profiles for the given language id.
 */
extern _str beautifier_profiles_for(_str langId)[]; 

/**
 * Creates a new profile named 'new_profile_name' by cloning the 
 * profile named 'src_profile_name'. 
 *  
 * Will overwrite an existing profile named 'new_profile_name' 
 * without comment.  Will fail if you try to create a profile 
 * that has the same name as one of the system profiles that we 
 * ship with. 
 * 
 * @param lang_id 
 * @param new_profile_name 
 * @param src_profile_name 
 * 
 * @return int 0 on success, or an error code on failure. 
 */
extern int beautifier_create_profile(_str lang_id, _str new_profile_name, _str src_profile_name);

/**
 * Deletes the profile named 'profile_name' for the language 
 * 'lang_id'. 
 *  
 * @param lang_id 
 * @param profile_name 
 * 
 * @return int 0 on success, or an error code on failure.
 */
extern int beautifier_delete_profile(_str lang_id, _str profile_name);


/**
 * Returns true if the given profile is a system profile. 
 * System profiles can not be deleted, and you can not create a 
 * profile that has the same name as a system profile. 
 * 
 * @param lang_id 
 * @param profile_name 
 * 
 * @return int nonzero if the given profile is a system profile.
 */
extern int beautifier_is_system_profile(_str lang_id, _str profile_name);

#define USER_BEAUTIFIER_PROFILES_FILE    'vusr_beautifier.xml'

// Combo box option values.
const CBV_NO = "No Spaces";
const CBV_B  = "Space Before";
const CBV_A  = "Space After";
const CBV_BA = "Space Before & After";
const CBV_Y  = "Yes";
const CBV_N  = "No";
const CBV_NSB = "No Space Before";
const CBV_NSA = "No Space After";
const CBV_AL_PARENS = "Align on Parens";
const CBV_AL_CONT = "Continuation Indent";
const CBV_AL_AUTO = "Auto";
const CBV_IN_TABS = "Tabs";
const CBV_IN_SPACES = "Spaces";
const CBV_SAMELINE = "Same Line";
const CBV_NEXTLINE = "Next Line";
const CBV_NEXTLINE_IN = "Next Line Indented";
const CBV_ALLEXP = "All Expressions";
const CBV_CMPLX_EXP = "Complex Expressions";
const CBV_NONE = "None";

const DISABLE = 0x8000;

// Extra beautifier flag we use internally to this module.
#define BEAUT_FLAG_EXACT_CONTEXT 0x8000                     // Don't try to be clever with leading context.  Be sure.

// Unique values for the different combo box entries we support.
const COMBO_NO = 0;
const COMBO_B = 1;
const COMBO_A = 2;
const COMBO_BA = 3;
const COMBO_Y = 4;
const COMBO_N = 5;
const COMBO_NSB = 6;
const COMBO_NSA = 7;
const COMBO_AL_PARENS = 8;
const COMBO_AL_CONT = 9;
const COMBO_AL_AUTO = 10;
const COMBO_IN_TABS = 11;
const COMBO_IN_SPACES = 12;
const COMBO_NEXTLINE = 13;
const COMBO_NEXTLINE_IN = 14;
const COMBO_SAMELINE = 15;
const COMBO_ALLEXP = 16;
const COMBO_CMPLX_EXP = 17;
const COMBO_NONE = 18;
const COMBO_AL_SEL_COLON=19;
const COMBO_AL_SEL_NAME=20;
const COMBO_FORCE_PARENS=21;
const COMBO_FORCE_PARENS_IF_COMPLEX=22;
const COMBO_REMOVE_PARENS=23;
const COMBO_MULTILINE_NO=24;

const LEFT_JUSTIFICATION=0;
const RIGHT_JUSTIFICATION=1;

// Map from language id to option array.
static typeless gLanguageOptionsCache:[];
static int gProfileEditForm;
static boolean gInhibitSyncing;

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

// If zero, ignore any updates to tab or other settngs from
// upgrade_all_current_profiles().  There are times that this 
// will get called from language emulations where we don't want to 
// persist the settings to the beautifier profiles.
static int gPersistUpdateChanges = 0;

definit()
{
   gLanguageOptionsCache._makeempty();
   gProfileEditForm = 0;
   gInhibitSyncing = false;
   def_beautifier_debug = 0;
   gAllowBeautifyCopy = 1;
   gPersistUpdateChanges = 0;
}


// Trailing comments radio button values.
static enum TrailingComment { TC_ABS_COL = 0, TC_ORIG_ABS_COL, TC_ORIG_REL_INDENT};

// Workspace we use while we're editing a profile to 
// hold the settings for the preview screens.
static _str gCurrentSettings[];

// Backup config of the editor control settings, for dialogs that allow you
// to beautify the current buffer.
static _str gEditorControlOriginalSettings[];

static enum CPPSettingIndex {
   // Start of options that are required by BraceBasedLanguage.
   CPPB_ST_NL_EMPTY = COMMON_OPTION_END,
   CPPB_SP_CATCH_PADPAREN,
   CPPB_SP_SWITCH_LPAREN,
   CPPB_SP_ARRAYEXPR_LBRACKET,
   CPPB_SP_ARRAYDECL_LBRACKET,
   CPPB_ST_FUNDECL_NAMELINE,
   CPPB_ST_ONELINE_DOWHILE,
   CPPB_SP_OP_BITWISE,
   CPPB_ST_ONELINE_CATCH,
   CPPB_SP_FOR_LPAREN,
   CPPB_SP_FUNCALL_VOIDPAREN,
   CPPB_SP_SWITCH_PADPAREN,
   CPPB_SP_FUN_PADPAREN,
   CPPB_SP_IF_RPAREN,
   CPPB_SP_OP_BITAND,
   CPPB_SP_OP_ASSIGNMENT,
   CPPB_SP_FOR_COMMA,
   CPPB_SP_FUNCALL_COMMA,
   CPPB_SP_ARRAYEXPR_RBRACKET,
   CPPB_SP_OP_MULT,
   CPPB_SP_ARRAYDECL_RBRACKET,
   CPPB_SP_FOR_LBRACE,
   CPPB_ST_ONELINE_THEN,
   CPPB_SP_CATCH_LPAREN,
   CPPB_SP_MEMBER_DOT,
   CPPB_SP_FOR_RPAREN,
   CPPB_SP_WHILE_RPAREN,
   CPPB_SP_RET_PAREXPR,
   CPPB_SP_THROW_PAREXPR,
   CPPB_ST_ONELINE_STATEMENT,
   CPPB_ST_ONELINE_ELSIF,
   CPPB_SP_OP_UNARY,
   CPPB_SP_OP_BINARY,
   CPPB_SP_OP_COMPARISON,
   CPPB_SP_CATCH_RPAREN,
   CPPB_SP_FUN_LPAREN,
   CPPB_SP_FUN_VOIDPAREN,
   CPPB_SP_WHILE_LBRACE,
   CPPB_SP_SWITCH_LBRACE,
   CPPB_SP_OP_LOGICAL,
   CPPB_SP_FOR_SEMICOLON,
   CPPB_ST_NL_FN,
   CPPB_SP_FUNCALL_RPAREN,
   CPPB_SP_FUNCALL_LPAREN,
   CPPB_SP_FUN_COMMA,
   CPPB_ST_LEAVE_DECLMULT,
   CPPB_SP_CATCH_LBRACE,
   CPPB_SP_FUN_LBRACE,
   CPPB_SP_IF_LBRACE,
   CPPB_SP_FOR_PADPAREN,
   CPPB_SP_SWITCH_RPAREN,
   CPPB_SP_OP_PREFIX,
   CPPB_SP_FUNCALL_PADPAREN,
   CPPB_SP_WHILE_PADPAREN,
   CPPB_SP_WHILE_LPAREN,
   CPPB_SP_FUN_RPAREN,
   CPPB_ST_LEAVE_STMTMULT,
   CPPB_SP_ARRAYEXPR_PADBRACKET,
   CPPB_SP_ARRAYDECL_PADBRACKET,
   CPPB_ST_ONELINE_ELSE,
   CPPB_ST_NL_CASE,
   CPPB_SP_OP_POSTFIX,
   CPPB_SP_IF_LPAREN,
   CPPB_SP_IF_PADPAREN,
   CPPB_INDENT_FIRST_LEVEL,
   CPPB_INDENT_GOTO,
   CPPB_ALIGN_ON_EQUALS,
   CPPB_EXP_PAREN_ALIGN,
   CPPB_BRACE_LOC_IF,
   CPPB_BRACE_LOC_FOR,
   CPPB_BRACE_LOC_WHILE,
   CPPB_BRACE_LOC_SWITCH,
   CPPB_BRACE_LOC_DO,
   CPPB_BRACE_LOC_TRY,
   CPPB_BRACE_LOC_CATCH,
   CPPB_BRACE_LOC_FUN,
   CPPB_COMMENT_INDENT,
   CPPB_COMMENT_COL1_INDENT,
   CPPB_ALLOW_ONE_LINE_BLOCK,
   CPPB_ST_NEWLINE_BEFORE_ELSE,
   CPPB_TRAILING_COMMENT_ALIGN,
   CPPB_TRAILING_COMMENT_VALUE,
   CPPB_INDENT_FROM_BRACE,
   CPPB_LABEL_INDENT,
   CPPB_SP_RETURN_PADPAREN,
   CPPB_SP_RETURN_RPAREN,
   CPPB_SP_THROW_PADPAREN,
   CPPB_SP_THROW_RPAREN,
   CPPB_SP_EXPR_LPAREN,
   CPPB_SP_EXPR_PADPAREN,
   CPPB_SP_EXPR_RPAREN,
   CPPB_SP_STMT_SEMICOLON,
   CPPB_SP_TRY_LBRACE,
   CPPB_BRACE_FOLLOWS_CASE,
   CPPB_NL_INDENT_LONE_ELSE,
   CPPB_RW_FORCE_THROW_PARENS,
   CPPB_RW_FORCE_RETURN_PARENS,
   CPPB_FORCE_PARAM_VOID,
   CPPB_SP_CAST_LPAREN,
   CPPB_SP_CAST_PADPAREN,
   CPPB_SP_CAST_RPAREN,
   CPPB_BLANK_BEFORE_CASE,
   CPPB_BLANK_BEFORE_FIRST_CASE,
   CPPB_BL_START_BLOCK_IF,
   CPPB_BL_END_BLOCK_IF,
   CPPB_BL_START_BLOCK_FOR,
   CPPB_BL_END_BLOCK_FOR,
   CPPB_BL_START_BLOCK_WHILE,
   CPPB_BL_END_BLOCK_WHILE,
   CPPB_BL_START_BLOCK_DO,
   CPPB_BL_END_BLOCK_DO,
   CPPB_BL_END_BLOCK_SWITCH,
   CPPB_BL_START_BLOCK_TRY,
   CPPB_BL_START_BLOCK_CATCH,
   CPPB_BL_END_BLOCK_CATCH,
   CPPB_BL_START_BLOCK_METHOD,
   CPPB_BL_BEFORE_LOCALS,
   CPPB_BL_AFTER_LOCALS,
   CPPB_VARALIGN_JUSTIFICATION,
   CPPB_BRACELOC_MULTILINE_COND,
   CPPB_SP_STMT_BEFORE_SEMI,

   LAST_BRACE_BASED_LANGUAGE = CPPB_SP_STMT_BEFORE_SEMI,
   // End of options for BraceBasedLanguage.

   // Options for ClassDeclaration
   CPPB_ST_NL_CLASS,
   CPPB_ALLOW_CLASS_ONE_LINE_BLOCK,
   CPPB_SP_CLASS_LBRACE,
   CPPB_SP_CLASS_COMMA,
   CPPB_SP_CLASS_COLON,
   CPPB_BRACE_LOC_CLASS,
   CPPB_INDENT_CLASS_BODY,
   CPPB_BL_BEFORE_FIRST_DECL,
   CPPB_BL_BETWEEN_METHODS,
   CPPB_BL_BETWEEN_FIELDS,
   CPPB_BL_BETWEEN_MEMBER_CLASSES,
   CPPB_BL_BETWEEN_DIFFERENT_DECLS,
   CPPB_BL_BETWEEN_CLASSES,
   CPPB_BL_BETWEEN_FN_PROTOTYPES,
   CPPB_BL_BETWEEN_COMMENTED_FIELDS,
   CPPB_INSTVARALIGN_JUSTIFICATION,
   LAST_CLASSDECL_SETTING = CPPB_INSTVARALIGN_JUSTIFICATION,

   // BeautGenericsHandler settings
   CPPB_SP_TMPLPARM_LT,
   CPPB_SP_TMPLDECL_PAD,
   CPPB_SP_TMPLDECL_COMMA,
   CPPB_SP_TMPLDECL_EQUALS,
   CPPB_SP_TMPLDECL_LT,
   CPPB_SP_TMPLPARM_PAD,
   CPPB_SP_TMPLPARM_COMMA,

   // CommentBeautifierSettings
   C_JD_FORMAT_HTML,
   C_JD_FORMAT_PRE,
   C_JD_INDENT_PARAM_DESC,
   C_JD_INDENT_PAST_PARAM_NAME,
   C_JD_FORCE_DELIM_NL,
   C_JD_BLANK_LINES_BEFORE_TAGS,
   C_JD_RM_BLANK_LINES,
   C_JD_BETWEEN_DIFF_TAGS,
   C_JD_BETWEEN_SAME_TAGS,
   C_DOX_FORMAT_PRE,
   C_DOX_INDENT_PARAM_DESC,
   C_DOX_INDENT_PAST_PARAM_NAME,
   C_DOX_FORCE_DELIM_NL,
   C_DOX_AFTER_BRIEF,
   C_DOX_RM_BLANK_LINES,
   C_DOX_BETWEEN_DIFF_TAGS,
   C_DOX_BETWEEN_SAME_TAGS,
   C_XDOC_FORMAT_PRE,
   C_XDOC_BETWEEN_DIFF_TAGS,
   C_XDOC_BETWEEN_SAME_TAGS,
   C_XDOC_RM_BLANK_LINES,
   C_XDOC_NL_AFTER_OPENTAG,
   C_XDOC_NL_BEFORE_CLOSETAG,

   CPPB_SP_INIT_COMMA,
   CPPB_SP_MEMBER_DOTSTAR,
   CPPB_SP_MPTR_CCS,
   CPPB_SP_DELETE_PADBRACKET,
   CPPB_SP_CPPCAST_PAD,
   CPPB_SP_REF_ARP,
   CPPB_SP_MEMBER_ARROWSTAR,
   CPPB_SP_CTLSTMT_RPAREN,
   CPPB_SP_CTLSTMT_PADPAREN,
   CPPB_ST_NEWLINE_AFTER_EXTERN,
   CPPB_SP_SWITCH_DEFCOLON,
   CPPB_SP_STRUCT_COMMA,
   CPPB_SP_PTR_IS,
   CPPB_SP_FUN_EQUALS,
   CPPB_SP_DELETE_RBRACKET,
   CPPB_SP_REF_AV,
   CPPB_SP_NEW_LPAREN,
   CPPB_SP_STRUCT_COLON,
   CPPB_SP_PTR_SRP,
   CPPB_SP_FUNCALL_OPERATOR,
   CPPB_ST_ONELINE_ACCESS,
   CPPB_SP_CPPCAST_GT,
   CPPB_SP_FUN_COMMAINIT,
   CPPB_SP_INIT_LBRACE,
   CPPB_SP_FUN_OPERATOR,
   CPPB_SP_PTR_SS,
   CPPB_SP_TMPLCALL_PAD,
   CPPB_SP_ENUM_LBRACE,
   CPPB_SP_PTR_SV,
   CPPB_SP_UNION_LBRACE,
   CPPB_SP_NEW_RPAREN,
   CPPB_SP_NEW_PADPAREN,
   CPPB_SP_ENUM_COMMA,
   CPPB_SP_ENUM_EQUALS,
   CPPB_SP_CPPCAST_LT,
   CPPB_SP_SWITCH_COLON,
   CPPB_SP_ENUM_COLON,
   CPPB_SP_PTR_SLP,
   CPPB_SP_PTR_SA,
   CPPB_SP_REF_IA,
   CPPB_SP_TMPLCALL_COMMA,
   CPPB_SP_TMPLCALL_LT,
   CPPB_SP_PTR_SI,
   CPPB_SP_CTLSTMT_LPAREN,
   CPPB_SP_FUN_COLON,
   CPPB_SP_DELETE_LBRACKET,
   CPPB_SP_PP_EATSPACE,
   CPPB_SP_OP_DEREFERENCE,
   CPPB_SP_STRUCT_LBRACE,
   CPPB_SP_MEMBER_ARROW,
   CPPB_SP_FPTR_SI,
   CPPB_SP_REF_ALP,
   CPPB_SP_CTLSTMT_LBRACE,
   CPPB_SP_INIT_RBRACE,
   CPPB_SP_OP_ADDRESSOF,
   CPPB_PREVIEW_INDENT,
   CPPB_SOME_LABEL,
   CPPB_INDENT_TAB_CUSTOM,
   CPPB_INDENT_EXTERN,
   CPPB_INDENT_NAMESPACE,
   CPPB_ORIG_INDENT,
   CPPB_INDENT_PREPROCESSING,
   CPPB_INDENT_IN_BLOCK,
   CPPB_INDENT_GUARD,
   CPPB_INDENT_PP_COL1,
   CPPB_BRACE_LOC_ASM,
   CPPB_BRACE_LOC_NAMESPACE,
   CPPB_BRACE_LOC_ENUM,
   CPPB_RESPACE_OTHER,
   CPPB_SPACING_TREE_FRAME,
   CPPB_STYLE_FRAME,
   CPPB_PARENS_RETURN,
   CPPB_PARENS_THROW,
   CPPB_FUNDECL_VOID,
   CPPB_FUN_ASSOC_WITH_RET_TYPE,
   CPPB_SP_FPTR_PADPAREN,
   CPPB_SP_FPTR_LPAREN,
   CPPB_SP_FPTR_RPAREN,
   CPPB_CONT_INDENT_RETURNTYPE,
   CPPB_SP_TY_STAR_PROTOTYPE,
   CPPB_SP_TY_AMP_PROTOTYPE,
   CPPB_SP_DISASSOC_RET_TYPE_REF,
   CPPB_SP_NAMESPACE_LBRACE,
   CPPB_PP_INDENT_WITH_CODE,
   CPPB_PP_PIN_HASH,
   CPPB_BL_BEFORE_ACCESS,
   CPPB_BL_AFTER_ACCESS,
   CPPB_BRACE_LOC_STRUCT,
   CPPB_BRACE_LOC_UNION,
   CPPB_SP_PAD_LAMBDABRACE,
   CPPB_SP_LAMBDACAPTURE_LBRACKET,
   CPPB_SP_LAMBDACAPTURE_RBRACKET,
   CPPB_SP_LAMBDACAPTURE_PAD,
   END_OF_CPPSETTINGS,

   // Equivalences to the common settings
   CPPB_INDENT_SYNTAX = CBI_SYNTAX_INDENT,
   CPPB_INDENT_TAB = CBI_TAB_INDENT,
   CPPB_INDENT_POLICY = CBI_INDENT_POLICY,
   CPPB_INDENT_MEMBER_ACCESS = CBI_MEMBER_ACCESS_INDENT,
   CPPB_ACCESS_SPEC_INDENT = CBI_MEMBER_ACCESS_INDENT_WIDTH,
   CPPB_MEMBER_ACCESS_RELATIVE_INDENT = CBI_MEMBER_ACCESS_RELATIVE_INDENT,
   CPPB_INDENT_CASE = CBI_INDENT_CASE,
   CPPB_CASE_INDENT_WIDTH = CBI_CASE_INDENT_WIDTH,
   CPPB_CONTINUATION_WIDTH = CBI_CONTINUATION_WIDTH,
   CPPB_FUNCALL_PARAM_ALIGN = CBI_FUNCALL_PARAM_ALIGN,
   CPPB_ST_NL_FILE = CBI_NL_AT_END_OF_FILE,
   CPPB_ORIGINAL_TAB = CBI_ORIGINAL_TAB,
   CPPB_INDENT_USE_TAB = CBI_INDENT_USE_ORIGINAL_TAB,
   CPPB_RM_TRAILING_WS = CBI_RM_TRAILING_WS,
   CPPB_RM_DUP_WS = CBI_RM_DUP_WS
};

enum JavaSettingIndex {
   JAVA_SP_TMPLDECL_LT = LAST_CLASSDECL_SETTING+1,
   JAVA_SP_TMPLDECL_PAD,   
   JAVA_SP_TMPLDECL_COMMA, 
   JAVA_SP_TMPLDECL_EQUALS,
   JAVA_SP_TMPLPARM_LT,    
   JAVA_SP_TMPLPARM_PAD,   
   JAVA_SP_TMPLPARM_COMMA,

   // CommentBeautifierSettings
   JAVA_JD_FORMAT_HTML,
   JAVA_JD_FORMAT_PRE,
   JAVA_JD_INDENT_PARAM_DESC,
   JAVA_JD_INDENT_PAST_PARAM_NAME,
   JAVA_JD_FORCE_DELIM_NL,
   JAVA_JD_BLANK_LINES_BEFORE_TAGS,
   JAVA_JD_RM_BLANK_LINES,
   JAVA_JD_BETWEEN_DIFF_TAGS,
   JAVA_JD_BETWEEN_SAME_TAGS,
   JAVA_DOX_FORMAT_PRE,
   JAVA_DOX_INDENT_PARAM_DESC,
   JAVA_DOX_INDENT_PAST_PARAM_NAME,
   JAVA_DOX_FORCE_DELIM_NL,
   JAVA_DOX_AFTER_BRIEF,
   JAVA_DOX_RM_BLANK_LINES,
   JAVA_DOX_BETWEEN_DIFF_TAGS,
   JAVA_DOX_BETWEEN_SAME_TAGS,
   JAVA_XDOC_FORMAT_PRE,
   JAVA_XDOC_BETWEEN_DIFF_TAGS,
   JAVA_XDOC_BETWEEN_SAME_TAGS,
   JAVA_XDOC_RM_BLANK_LINES,
   JAVA_XDOC_NL_AFTER_OPENTAG,
   JAVA_XDOC_NL_BEFORE_CLOSETAG,

   JAVA_SP_FOREACH_COLON,
   JAVA_ANNOT_NEWLINE,
   JAVA_SP_ANNOT_LPAREN,
   JAVA_SP_ANNOT_PADPAREN,
   JAVA_SP_ANNOT_RPAREN,
   JAVA_SP_ANNOT_COMMA,
   JAVA_ANNOT_NEWLINE_PACKAGE,
   JAVA_ANNOT_NEWLINE_FIELD,
   JAVA_ANNOT_NEWLINE_METHOD,
   JAVA_ANNOT_NEWLINE_PARAMETER,
   JAVA_ANNOT_NEWLINE_LOCAL,
   JAVA_ANNOT_TYPE_BRACELOC,
   JAVA_SP_ANNOT_TYPE_BRACE,
   JAVA_SP_ENUM_LBRACE,
   JAVA_SP_ENUM_COMMA,
   JAVA_SP_ENUM_CONSTBODY_LBRACE,
   JAVA_ENUM_BRACELOC,
   JAVA_ENUM_CONSTBODY_BRACELOC,
   JAVA_SP_ENUM_INIT_LPAREN,
   JAVA_SP_ENUM_INIT_RPAREN,
   JAVA_SP_ENUM_INIT_PADDING,
   JAVA_SP_ENUM_EQ,
   JAVA_ANON_CLASS_BRACELOC,
   JAVA_SP_ANON_CLASS_LBRACE,
   JAVA_IND_ENUM_BODY,
   JAVA_IND_ENUM_CONST_BODY,
   JAVA_IND_BREAK_STMT,
   JAVA_IND_ANNOT_TYPE_BODY,
   JAVA_SP_ARRAY_INIT_COMMA,
   JAVA_SP_ARRAY_INIT_PAD, 
   JAVA_NL_ARRAY_INIT_INNER_PAD,
   JAVA_NL_ARRAY_INIT_OUTER_PAD,
   JAVA_NL_ARRAY_INIT_BEFORE_OUTER_LBRACE,
   JAVA_NL_ARRAY_INIT_BEFORE_INNER_LBRACE,
   JAVA_BL_BEFORE_PACKAGE,
   JAVA_BL_AFTER_PACKAGE,
   JAVA_BL_LEAVE_BETWEEN_IMPORTS,
   JAVA_BL_AFTER_IMPORTS,
   JAVA_SP_BEFORE_TRY_LPAREN,
   JAVA_SP_AFTER_TRY_RPAREN,
   JAVA_SP_PADPAREN_TRY,
   JAVA_BL_BEFORE_SYNC,
   JAVA_BL_AFTER_SYNC,
   JAVA_SP_SYNC_LPAREN,
   JAVA_SP_SYNC_PAD,
   JAVA_SP_SYNC_RPAREN,
   JAVA_SP_EXCEPTION_CHOICE,
};

enum OBJCSettingIndex {
   OBJC_METH_DECL_ALIGN = END_OF_CPPSETTINGS,
   OBJC_METH_CALL_ALIGN,
   OBJC_CATEGORY_PADPAREN,
   OBJC_CATEGORY_LPAREN,
   OBJC_CATEGORY_RPAREN,
   OBJC_SP_DECL_SELECTOR_COLON,
   OBJC_SP_CALL_SELECTOR_COLON,
   OBJC_PROTOCOL_PADPAREN,
   OBJC_PROTOCOL_LPAREN,
   OBJC_PROTOCOL_RPAREN,
   OBJC_PROTOCOL_COMMA,
   OBJC_METH_CALL_BRACKET_ALIGN,
   OBJC_METH_CALL_SELALIGN_FORCE,
   OBJC_PROP_PADPAREN,
   OBJC_PROP_LPAREN,
   OBJC_PROP_RPAREN,
   OBJC_PROP_COMMA,
   OBJC_SYNTH_COMMA,
   OBJC_SYNTH_EQ,
   OBJC_DYNAMIC_COMMA,
   OBJC_METH_RETURN_LPAREN,
   OBJC_METH_RETURN_PADPAREN,
   OBJC_METH_RETURN_RPAREN,
   OBJC_METH_PARAM_LPAREN,
   OBJC_METH_PARAM_PADPAREN,
   OBJC_METH_PARAM_RPAREN,
   OBJC_BLOCK_INITIAL_INDENT,
   OBJC_FINALLY_LBRACE,
   OBJC_SYNCHRONIZED_LPAREN,
   OBJC_SYNCHRONIZED_PADPAREN,
   OBJC_SYNCHRONIZED_RPAREN,
   OBJC_SYNCHRONIZED_LBRACE,
   OBJC_PROP_EQ,

   // We need aliases for the doc comment settings, even though we share the
   // setting indices with C++.
   M_JD_FORMAT_HTML             =    C_JD_FORMAT_HTML,            
   M_JD_FORMAT_PRE              =    C_JD_FORMAT_PRE,             
   M_JD_INDENT_PARAM_DESC       =    C_JD_INDENT_PARAM_DESC,      
   M_JD_INDENT_PAST_PARAM_NAME  =    C_JD_INDENT_PAST_PARAM_NAME, 
   M_JD_FORCE_DELIM_NL          =    C_JD_FORCE_DELIM_NL,         
   M_JD_BLANK_LINES_BEFORE_TAGS =    C_JD_BLANK_LINES_BEFORE_TAGS,
   M_JD_RM_BLANK_LINES          =    C_JD_RM_BLANK_LINES,         
   M_JD_BETWEEN_DIFF_TAGS       =    C_JD_BETWEEN_DIFF_TAGS,      
   M_JD_BETWEEN_SAME_TAGS       =    C_JD_BETWEEN_SAME_TAGS,
   M_DOX_FORMAT_PRE             =    C_DOX_FORMAT_PRE,
   M_DOX_INDENT_PARAM_DESC      =    C_DOX_INDENT_PARAM_DESC,
   M_DOX_INDENT_PAST_PARAM_NAME =    C_DOX_INDENT_PAST_PARAM_NAME,
   M_DOX_FORCE_DELIM_NL         =    C_DOX_FORCE_DELIM_NL,
   M_DOX_AFTER_BRIEF            =    C_DOX_AFTER_BRIEF,
   M_DOX_RM_BLANK_LINES         =    C_DOX_RM_BLANK_LINES,
   M_DOX_BETWEEN_DIFF_TAGS      =    C_DOX_BETWEEN_DIFF_TAGS,
   M_DOX_BETWEEN_SAME_TAGS      =    C_DOX_BETWEEN_SAME_TAGS
};

static _str yn_choices[] = {
   CBV_Y, CBV_N
};

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
 */
static void save_stream_markers(SavedStreamMarkers& state, long (&markers)[], long start_offset, long end_offset) {
   TextChangeNotify.enableTextChange(false); // disable text change callbacks
   if (end_offset <= start_offset) {
      return;
   }

   state.surround_index = save_surround_state_to(markers);
   EventUI.beautifySave(state.callbacks, state.callback_index, markers, start_offset, end_offset);
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
   restore_surround_state_from(state.surround_index, markers);
   EventUI.beautifyRestore(state.callbacks, state.callback_index, markers);
}

boolean beautifier_profile_editor_active()
{
   return gProfileEditForm != 0;
}

static _str get_language_wildcards(_str lang)
{
   _str ext;
   _str rest = get_file_extensions_sorted(lang);
   _str extlist = '';

   do {
      parse rest with ext rest;
      extlist = extlist :+ '*.'ext';';
   } while (rest != '');

   // .h files are used by a few languages.
   if (lang == 'c'
       || lang == 'm') {
      extlist = extlist :+ '*.h;';
   }

   return substr(extlist, 1, extlist._length()-1);
}


static int find_any_enclosing_form(int start)
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

const BEAUT_EX_KEY_PREFIX = "__example_";


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
   if (pos('[.]+', file, 1, 'U') > 0) {
      if (def_beautifier_debug > 1) 
         say("normalize("file") => "file);
      return file;
   }

   _str langext = '.'langId;

   switch (langId) {
   case "c":
      langext = ".cpp";
      break;
   }

   if (def_beautifier_debug > 1) 
      say("normalize("file") => "(file :+ langext));

   return file :+ langext;
}

static void set_user_example_file(int form, _str examp_name, _str examp_file)
{
   _SetDialogInfoHt(BEAUT_EX_KEY_PREFIX :+ examp_name, examp_file, form);
}

static void update_preview(int preview_wid, _str file, _str langId = 'c')
{
   long markers[];
   _str cfg[];
   formWid := find_any_enclosing_form(preview_wid);

   if (!formWid) {
      return;
   }

   if (preview_wid.p_buf_size <= 2) {
      _str ue = get_user_example_file(formWid, file);

      if (ue == '') {
         _str root = get_env("VSROOT");
         ue = root"sysconfig/formatter/"langId"/examples/"(normalize_example_file(file, langId));
      }
      // Inhibit this, so we don't double-beautify.
      gAllowBeautifyCopy = 0;
      preview_wid.get(ue);
      gAllowBeautifyCopy = 1;
   }

   oldf := p_window_id;
   p_window_id = preview_wid;
   _SetEditorLanguage(langId);
   p_window_id = oldf;

   // Always update the tab stops, otherwise, it can look silly when switching
   // when switching the tab and space settings.
   preview_wid.p_tabs = "+"((int)gCurrentSettings[CPPB_INDENT_TAB]);
   preview_wid.p_ShowSpecialChars |= SHOWSPECIALCHARS_TABS;
   preview_wid.p_BeautifierCfg = gCurrentSettings;
   beautify_buffer(preview_wid, markers, BEAUT_FLAG_NONE);
   // Cursor at top.
   oldf = p_window_id;
   p_window_id = preview_wid;
   top_of_buffer();
   p_window_id = oldf;

   refresh();   
}

static void populatecb(int ctl, int defval, _str (&items)[]) 
{
   int i;

   for (i = 0; i < items._length(); i++) {
      ctl.p_cb_list_box._lbadd_item(items[i]);
   }

   ctl.p_cb_text_box.p_text = items[defval];
}

const STYLE_MASK = BES_BEGIN_END_STYLE_1|BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3;

// Translates from our encoded brace location values to the 
// format recognized by LanguageSettings
int beautifier_xlat_brace_loc(_str sbloc)
{
   switch ((int)sbloc) {
   case COMBO_NEXTLINE:
      return BES_BEGIN_END_STYLE_2;

   case COMBO_NEXTLINE_IN:
      return BES_BEGIN_END_STYLE_3;

   default:
      return BES_BEGIN_END_STYLE_1;

   }
}

static int xlat_yn(_str s)
{
   int c = (int)s & ~DISABLE;

   return (int)(c == COMBO_Y);
}

static int xlat_pointer_style(_str (&options)[])
{
   if (options[CBI_LANG_ID] != 'c') 
      return 0;

   int sb = (int)options[CPPB_SP_PTR_IS] & ~DISABLE;
   int sa = (int)options[CPPB_SP_PTR_SV] & ~DISABLE;

   if (sa == COMBO_Y) {
      if (sb == COMBO_Y) {
         return BES_SPACE_SURROUNDS_POINTER;
      } else {
         return BES_SPACE_AFTER_POINTER;
      }
   } else {
      if (sb == COMBO_Y) {
         return 0;
      } else {
         return 0; // Default, since this doesn't translate.
      }
   }
}

static void options_changed_handler(_str (&options)[], _str langId)
{
   if (LanguageSettings.getBeautifierProfileName(langId) == options[CBI_PROFILE_NAME]) {
      // The current profile was updated, so update any open buffers for that language.
      _str update:[];

      update:[SYNTAX_INDENT_UPDATE_KEY] = options[CPPB_INDENT_SYNTAX];
      update:[INDENT_CASE_FROM_SWITCH_UPDATE_KEY] = options[CPPB_INDENT_CASE];
      update:[BEGIN_END_STYLE_UPDATE_KEY] = beautifier_xlat_brace_loc(options[CPPB_BRACE_LOC_IF]);
      update:[PAD_PARENS_UPDATE_KEY] = xlat_yn(options[CPPB_SP_IF_PADPAREN]);
      update:[NO_SPACE_BEFORE_PAREN_UPDATE_KEY] = !xlat_yn(options[CPPB_SP_IF_LPAREN]);
      update:[POINTER_STYLE_UPDATE_KEY] = xlat_pointer_style(options);
      update:[TABS_UPDATE_KEY] = "+"(_str)((int)options[CBI_TAB_INDENT]);
      update:[INDENT_WITH_TABS_UPDATE_KEY] = ((int)options[CBI_INDENT_POLICY] == COMBO_IN_TABS) ? 1 : 0;

      _update_buffers_from_table(langId, update);

      // Keep language settings in sync.  We already hook into LanguageSettings to
      // overlay our settings, we just need to save out to the defs as well.
      LanguageSettings.clearLanguageOptionsCache();
      LanguageSettings.getAllLanguageOptions(langId, auto langOptions);
      LanguageSettings.setAllLanguageOptions(langId, langOptions);
   }

}


/**
 * Returns true if the language is supported by the new 
 * beautifier. 
 *  
 * @param langid 
 * 
 * @return boolean 
 */
boolean new_beautifier_supported_language(_str langid)
{
   return langid == 'c' || langid == 'm' || langid == 'java' || langid == 'cs';
}

_command void beautify_with_profile(_str profile='None Specified') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   long markers[]; 

   if (!new_beautifier_supported_language(p_LangId)) {
      return;
   }

   pcy := p_cursor_y;
   pcx := p_scroll_left_edge;

   tmpProfile := beautifier_load_profile(profile, p_LangId, auto status);
   if (status) {
      _message_box("Could not load profile named '"profile"' for "p_LangId", error="status);
      return;
   }

   boolean has_selection = select_active() == MARK_SEARCH;
   int beginLine, endLine;
   long startoff = 0, endoff = 0;

   if (has_selection) {
      // Ignore adaptive formatting for a full file beautify.
      update_profile_from_aff(tmpProfile);
   }
   p_BeautifierCfg = tmpProfile;

   // Save cursor position, so beautifier can remap it to the same location
   // in the beautified source.
   cline_len := _text_colc();
   if (p_col > cline_len) {
      // We don't like markers that are in virtual columns.
      _end_line();
   }
   markers[0] = _QROffset();

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
   _SaveBookmarksInFile(auto bmSaves, beginLine, endLine);
   _SaveBreakpointsInFile(auto bpSaves, beginLine, endLine);
   _SaveAnnotationsInFile(auto annoSaves);

   int rc;

   if (has_selection) {
      rc = beautify_snippet(startoff, endoff, markers, &tmpProfile);
   } else {
      rc = beautify_buffer(p_window_id, markers, BEAUT_FLAG_NONE);
   }

   if (rc < 0) {
      message(get_message(rc));
   } else {
      // restore bookmarks, breakpoints, and annotation locations
      _RestoreBookmarksInFile(bmSaves);
      _RestoreBreakpointsInFile(bpSaves);
      _RestoreAnnotationsInFile(annoSaves);

      if (markers._length() > 0) {
         // Restore to the remapped position in the source file.
         _GoToROffset(markers[0]);
         set_scroll_pos(pcx, pcy);
      }
   }
}


_command void beautify_current_buffer() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   beautify_with_profile(LanguageSettings.getBeautifierProfileName(p_LangId));
}

/**
 * 
 * @param langid 
 * 
 * @return _str (&)[] of beautifier options for langid. 
 */
typeless get_options_for_language(_str langid)
{
   _str options[];

   options = gLanguageOptionsCache:[langid];
   if (options == null) {
      int status = 0;
      prof := beautifier_load_profile(LanguageSettings.getBeautifierProfileName(langid), langid, status);
      if (status == 0) {
         gLanguageOptionsCache:[langid] = prof;
         options = gLanguageOptionsCache:[langid];

         // Make the defaults explicit, so array lookups in slickc don't fail for unspecified values.
         defp := beautifier_load_profile('Default', langid, status);
         if (status == 0) {
            int i;
            
            for (i = 0; i < defp._length(); i++) {
               if (options[i] == null) {
                  options[i] = defp[i];
               }
            }
            gLanguageOptionsCache:[langid] = options;
         }
      } else {
         // We don't want to repeatedly retry on error, so revert to defaults for this language.
         gLanguageOptionsCache:[langid] = beautifier_load_profile("Default", langid, status);
         options = gLanguageOptionsCache:[langid];
      }
   }
   return options;
}

static void invalidate_options_cache(_str langid)
{
   gLanguageOptionsCache:[langid] = null;
}

static int xlat_pad_parens(_str opt) {
   int c = (int)opt & ~DISABLE;

   if ( c == COMBO_Y ) {
      return BES_PAD_PARENS;
   }
   return 0;
}

static int xlat_space_before_paren(_str opt) {
   int c = (int)opt & ~DISABLE;

   if ( c == COMBO_Y ) {
      return 0;
   }
   return BES_NO_SPACE_BEFORE_PAREN;
}

// Updates language options for all of the beautifiers that share the brace based config indices
// with the C++ beautifier.
static void update_cppb_language_options(typeless (&options)[], _str (&beaut_options)[])
{
   options[LOI_INDENT_FIRST_LEVEL] = (int)beaut_options[CPPB_INDENT_FIRST_LEVEL];
   options[LOI_BEGIN_END_STYLE] = beautifier_xlat_brace_loc((int)beaut_options[CPPB_BRACE_LOC_IF]);
   options[LOI_PAD_PARENS] = xlat_pad_parens(beaut_options[CPPB_SP_IF_PADPAREN]);
   options[LOI_NO_SPACE_BEFORE_PAREN] = xlat_space_before_paren(beaut_options[CPPB_SP_IF_LPAREN]);
   options[LOI_CUDDLE_ELSE] = xlat_yn(beaut_options[CPPB_ST_NEWLINE_BEFORE_ELSE]);
}

static void update_common_language_options(typeless (&options)[], _str (&beaut_options)[])
{
   // These settings are accurate enough for most uses. For code that needs 
   // more specific per-statement-type information, or configuration options beyond 
   // what's supplied by the existing buffer properties, see the beaut_*
   // functions.
   options[LOI_SYNTAX_INDENT] = (int)beaut_options[CPPB_INDENT_SYNTAX];
   options[LOI_INDENT_CASE_FROM_SWITCH] = (int)beaut_options[CPPB_INDENT_CASE];
   options[LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS] = (int)beaut_options[CPPB_FUNCALL_PARAM_ALIGN] == COMBO_AL_CONT;
   options[LOI_POINTER_STYLE] = xlat_pointer_style(beaut_options);
}

void _c_update_brace_settings(int bes, _str lang, _str (&opts)[]) {
   _str bstyle;

   switch (bes) {
   case BES_BEGIN_END_STYLE_1:
      bstyle = (_str)COMBO_SAMELINE;
      break;

   case BES_BEGIN_END_STYLE_2:
      bstyle = (_str)COMBO_NEXTLINE;
      break;

   case BES_BEGIN_END_STYLE_3:
      bstyle = (_str)COMBO_NEXTLINE_IN;
      break;

   default:
      return;
   }

   opts[CPPB_BRACE_LOC_IF] = bstyle;
   opts[CPPB_BRACE_LOC_FOR] = bstyle;
   opts[CPPB_BRACE_LOC_WHILE] = bstyle;
   opts[CPPB_BRACE_LOC_SWITCH] = bstyle;
   opts[CPPB_BRACE_LOC_DO] = bstyle;
   opts[CPPB_BRACE_LOC_TRY] = bstyle;
   opts[CPPB_BRACE_LOC_CATCH] = bstyle;
   opts[CPPB_BRACE_LOC_ASM] = bstyle;
   opts[CPPB_BRACE_LOC_NAMESPACE] = bstyle;
   opts[CPPB_BRACE_LOC_CLASS] = bstyle;
   opts[CPPB_BRACE_LOC_ENUM] = bstyle;
   opts[CPPB_BRACE_LOC_FUN] = bstyle;
}

void _m_update_brace_settings(int bes, _str lang, _str (&opts)[]) {
   _c_update_brace_settings(bes, lang,opts);
}

void _c_update_misc_settings(_str lang, _str (&opts)[]) {
   if (LanguageSettings.getCuddleElse(lang)) {
      opts[CPPB_ST_NEWLINE_BEFORE_ELSE] = (_str)COMBO_N; 
   } else {
      opts[CPPB_ST_NEWLINE_BEFORE_ELSE] = (_str)COMBO_Y;
   }
}


void _m_update_misc_settings(_str lang, _str (&opts)[]) {
   _c_update_misc_settings(lang,opts);
}

static _str normalize_tabs(_str tab_setting) {
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


void all_lang_update_all_current_profiles(boolean update_indent_settings,
                                         boolean update_brace_settings,
                                         boolean update_misc_settings) {
   // Always update for the all_languages form.
   gPersistUpdateChanges = 1;
   update_all_current_profiles(update_indent_settings, 
                               update_brace_settings,
                               update_misc_settings);
   gPersistUpdateChanges = 0;
}

/**
 * Updates indent, brace and any miscellaneous settings from the 
 * quick start and All Languages setting pages for all of the 
 * current profiles for all languages supported by the 
 * beautifier.  Also called by main.e:_firstInit() when building 
 * a new state file. 
 *  
 * @param update_indent_settings 
 * @param update_brace_settings 
 * @param update_misc_settings 
 */
void update_all_current_profiles(boolean update_indent_settings,
                                 boolean update_brace_settings,
                                 boolean update_misc_settings) {
   int i, status;

   if (!gPersistUpdateChanges) {
      return;
   }

   gInhibitSyncing = true;
   LanguageSettings.clearLanguageOptionsCache();
   for (i = 0; i < ALL_BEAUT_LANGUAGES._length(); i++) {
      lang := ALL_BEAUT_LANGUAGES[i];
      prof := LanguageSettings.getBeautifierProfileName(lang);

      if (prof == '') {
         continue;
      }

      if (beautifier_is_system_profile(lang, prof)) {
         // Make a copy so we can modify it.
         all_profiles := beautifier_profiles_for(lang);
         boolean looking = true;
         _str suffix = '';

         while (looking) {
            canidate := 'My 'prof :+ suffix;
            if (profile_conflicts_with_existing(canidate, lang)) {
               if (suffix == '') {
                  suffix = '1';
               } else {
                  suffix = (_str)((int)suffix + 1);
               }
            } else {
               looking = false;
               status = beautifier_create_profile(lang, canidate, prof);
               prof = canidate;
            }
         }
         if (status == 0) {
            LanguageSettings.setBeautifierProfileName(lang, prof);
         } else {
            continue;
         }
      }

      opts := beautifier_load_profile(prof, lang, status);
      if (status != 0) {
         continue;
      }

      if (update_indent_settings) {
         opts[CBI_SYNTAX_INDENT] = (_str)LanguageSettings.getSyntaxIndent(lang);
         opts[CBI_TAB_INDENT] = normalize_tabs(LanguageSettings.getTabs(lang));
         if (LanguageSettings.getIndentWithTabs(lang)) {
            opts[CBI_INDENT_POLICY] = (_str)COMBO_IN_TABS;
         } else {
            opts[CBI_INDENT_POLICY] = (_str)COMBO_IN_SPACES;
         }
      }

      // Hook these too, as they might vary by language
      if (update_brace_settings) {
         ubs := find_index('_'lang'_update_brace_settings', PROC_TYPE);
         if (ubs != 0) {
            call_index(LanguageSettings.getBeginEndStyle(lang), lang, opts, ubs);
         }
      }

      if (update_misc_settings) {
         ums := find_index('_'lang'_update_misc_settings', PROC_TYPE);
         if (ums != 0) {
            call_index(lang, opts, ums);
         }
      }
      opts[CBI_PROFILE_NAME] = prof;
      opts[CBI_LANG_ID] = lang;
      beautifier_save_profile(opts);
      invalidate_options_cache(lang);
      options_changed_handler(opts, lang);
   }
   gInhibitSyncing = false;
   LanguageSettings.clearLanguageOptionsCache();
}

/** 
 * For handling the case where a state file is being rebuilt 
 * from a user's vunxdefs.e/vusrdefs.e 
 */
void beautifier_upgrade_from_settings() {
   // Reset to default profile if the user profile they had before doesn't exist.
   foreach (auto lang in ALL_BEAUT_LANGUAGES) {
      curprof := LanguageSettings.getBeautifierProfileName(lang, 'Default');
      if (!profile_conflicts_with_existing(curprof, lang)) {
         LanguageSettings.setBeautifierProfileName(lang, 'Default');
      }
   }
   gPersistUpdateChanges = 1;
   update_all_current_profiles(true, true, true);
   gPersistUpdateChanges = 0;
}


void _c_and_m_upgrade_existing_settings(_str lang, _str prof) {
   opts := beautifier_load_profile(prof, lang, auto status);

   if (status == 0) {
      boolean changed = false;

      // Give reasonable defaults for new separate struct and union
      // brace styles.  Previously controlled by class brace style.
      if (opts[CPPB_BRACE_LOC_UNION] == null) {
         opts[CPPB_BRACE_LOC_UNION] = opts[CPPB_BRACE_LOC_CLASS];
         changed = true;
      }
      if (opts[CPPB_BRACE_LOC_STRUCT] == null) {
         opts[CPPB_BRACE_LOC_STRUCT] = opts[CPPB_BRACE_LOC_CLASS];
         changed = true;
      }

      if (changed) {
         beautifier_save_profile(opts);
      }
   }
}

/**
* Fixes up default settings for a clean install that is not 
* upgrading from an existing config directory.  Called from 
* main.e 
*/
void beautifier_initial_setup()
{
#if __UNIX__
   // Default tabs are 8 on *nix, 4 on windows.
   int i, status;

   gInhibitSyncing = true;
   for (i = 0; i < ALL_BEAUT_LANGUAGES._length(); i++) {
      lang := ALL_BEAUT_LANGUAGES[i];

      // If this has already been done, bail out.
      if (profile_conflicts_with_existing("My Default", lang)) {
         break;
      }
      opts := beautifier_load_profile("Default", lang, status);

      if (status != 0) {
         continue;
      }

      status = beautifier_create_profile(lang, "My Default", "Default");
      if (status != 0) {
         continue;
      }

      opts[CBI_TAB_INDENT] = "8";
      opts[CBI_PROFILE_NAME] = "My Default";
      opts[CBI_LANG_ID] = lang;
      status = beautifier_save_profile(opts);

      if (status != 0) {
         continue;
      }
      LanguageSettings.setBeautifierProfileName(lang, "My Default");
      invalidate_options_cache(lang);
   }
   gInhibitSyncing = false;

#endif
}

void _c_upgrade_existing_settings(_str lang, _str prof) {
   _c_and_m_upgrade_existing_settings(lang, prof);
}

/**
 * For handling version to version updates of beautifier 
 * options.  Mainly useful when trying to set good defaults 
 * for a new setting using the original settings a a base. 
 */
void beautifier_upgrade_existing_settings() {
   foreach (auto lang in ALL_BEAUT_LANGUAGES) {
      ind := find_index('_'lang'_upgrade_existing_settings', PROC_TYPE);
      if (ind == 0) {
         continue;
      }

      foreach (auto prof in beautifier_profiles_for(lang)) {
         if (beautifier_is_system_profile(lang, prof)) {
            continue;
         }
         call_index(lang, prof, ind);
      }
   }
}

/**
 * Hook that allows us to keep the LanguageSettings in sync with 
 * the beautifier settings. 
 */
void _c_language_options_sync(typeless (&options)[])
{
   if (!gInhibitSyncing) {
        _str bo[] = get_options_for_language('c');

        if (bo != null && bo._length() > 0) {
           update_cppb_language_options(options, bo);
           update_common_language_options(options, bo);
        }
   }
}


void _m_language_options_sync(typeless (&options)[])
{
   if (!gInhibitSyncing) {
        _str bo[] = get_options_for_language('m');

        if (bo != null && bo._length() > 0) {
           update_cppb_language_options(options, bo);
           update_common_language_options(options, bo);
        }
   }
}

void _java_language_options_sync(typeless (&options)[])
{
   if (!gInhibitSyncing) {
        _str bo[] = get_options_for_language('java');

        if (bo != null && bo._length() > 0) {
           update_cppb_language_options(options, bo);
           update_common_language_options(options, bo);
        }
   }
}

void _cs_language_options_sync(typeless (&options)[])
{
   if (!gInhibitSyncing) {
        _str bo[] = get_options_for_language('cs');

        if (bo != null && bo._length() > 0) {
           //TODO: cs equivalent of update_cppb_language_options, once BraceBasedLanguage settings are in place.
           update_common_language_options(options, bo);
        }
   }
}

static void _common_language_def_sync(VS_LANGUAGE_SETUP_OPTIONS& setup, _str lang) {
   _str bo[] = get_options_for_language(lang);

   if (bo != null && bo._length() > 0) {
      // It possible for the tab setting to be in an unnormalized format
      // when we're called indirectly by _firstinit via some emulations.
      setup.tabs = normalize_tabs(bo[CBI_TAB_INDENT]);
      setup.indent_with_tabs = (int)bo[CBI_INDENT_POLICY] == COMBO_IN_TABS;
   }
}

void _c_language_definition_sync(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   if (!gInhibitSyncing) {
        _common_language_def_sync(setup, 'c');
   }
}


void _m_language_definition_sync(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   if (!gInhibitSyncing) {
        _common_language_def_sync(setup, 'm');
   }
}

void _java_language_definition_sync(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   if (!gInhibitSyncing) {
        _common_language_def_sync(setup, 'java');
   }
}

void _cs_language_definition_sync(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   if (!gInhibitSyncing) {
        _common_language_def_sync(setup, 'cs');
   }
}


static int _lang_cfg_index(_str lang, _str& fnkey, int& status)
{
   int index = _const_value(fnkey, status);

   lang = upcase(lang);
   if (status != 0) {
      // Try with extension pasted to beginning.
      orig := fnkey;

      fnkey = lang'_'fnkey;
      index = _const_value(fnkey, status);

      if (status != 0) {
         // Special case for language that shares config with c++.
         if (lang == "JAVA" || lang == "M" || lang == 'C') {
            fnkey = 'CPPB_'orig;
            index = _const_value(fnkey, status);
         }
      }
   }
   return index;
}

static int _cfg_index(_str& fnkey, int& status) 
{
   return _lang_cfg_index(gCurrentSettings[CBI_LANG_ID], fnkey, status);
}

_str beautifier_load_or_save_3state(_str fnkey, _str value = null, int &checkState = null)
{
   _str rv;

   int index = _cfg_index(fnkey, auto j);

   if (value == null) {
      rv = _intern_beautifier_load_or_save(fnkey);
      checkState = (int)(((int)rv & DISABLE) == 0);
      if (!_is_numeric_field(fnkey)) {
         rv = _config_val_to_ui(fnkey, index, (int)rv & ~DISABLE);
      } else {
         rv = (int)rv & ~DISABLE;
      }
   } else {
      rv = value;
      if (!_is_numeric_field(fnkey)) {
         value = (_str)_ui_to_config_val(fnkey, index, value);
      }
      if (!checkState) {
         value = (_str)((int)value | DISABLE);
      }
      _intern_beautifier_load_or_save(fnkey, value);
   }

// if (value == null) {
//    say("3sFETCH "fnkey"="rv);
// } else {
//    say("3sSET "fnkey"="value);
// }

   return rv;
}

static int gTrueBooleans:[] = {
   'CPPB_INDENT_CASE' => 1,
   'CPPB_INDENT_MEMBER_ACCESS' => 1,
   'CPPB_MEMBER_ACCESS_RELATIVE_INDENT' => 1,
   'CPPB_INDENT_GOTO' => 1,
   'CPPB_INDENT_EXTERN' => 1,
   'CPPB_INDENT_NAMESPACE' => 1,
   'CPPB_INDENT_FIRST_LEVEL' => 1,
   'CPPB_ALIGN_ON_EQUALS' => 1,
   'CPPB_INDENT_PREPROCESSING' => 1,
   'CPPB_INDENT_IN_BLOCK' => 1,
   'CPPB_INDENT_GUARD' => 1,
   'OBJC_METH_CALL_SELALIGN_FORCE' => 1,
   'CPPB_INDENT_USE_TAB' => 1,
   'CPPB_BRACE_FOLLOWS_CASE' => 1,
   'CPPB_PP_INDENT_WITH_CODE' => 1,
   'CPPB_PP_PIN_HASH' => 1,
   'CBI_INDENT_USE_ORIGINAL_TAB' => 1,
   'CPPB_INDENT_USE_TAB' => 1,
   'CBI_RM_TRAILING_WS' => 1,
   'CPPB_RM_TRAILING_WS' => 1,
   'CBI_RM_DUP_WS' => 1,
   'CPPB_RM_DUP_WS' => 1,
   'CBI_NL_AT_END_OF_FILE' => 1,
   'CPPB_ST_NL_FILE' => 1,
   'JAVA_IND_CLASS_BODY' => 1,
   'CPPB_INDENT_CLASS_BODY' => 1,
   'JAVA_IND_ENUM_BODY' => 1,
   'JAVA_IND_ENUM_CONST_BODY' => 1,
   'JAVA_IND_ANNOT_TYPE_BODY' => 1,
   'JAVA_SP_ARRAY_INIT_PAD' => 1,
   'JAVA_NL_ARRAY_INIT_INNER_PAD' => 1,
   'JAVA_NL_ARRAY_INIT_OUTER_PAD' => 1,
   'JAVA_NL_ARRAY_INIT_BEFORE_OUTER_LBRACE' => 1,
   'JAVA_NL_ARRAY_INIT_BEFORE_INNER_LBRACE' => 1,

   'CS_INDENT_CASE' => 1,
   'CS_INDENT_MEMBER_ACCESS' => 1,
   'CS_MEMBER_ACCESS_RELATIVE_INDENT' => 1,
   'CS_INDENT_GOTO' => 1,
   'CS_INDENT_EXTERN' => 1,
   'CS_INDENT_NAMESPACE' => 1,
   'CS_INDENT_FIRST_LEVEL' => 1,
   'CS_ALIGN_ON_EQUALS' => 1,
   'CS_INDENT_IN_BLOCK' => 1,
   'CS_INDENT_GUARD' => 1,
   'CS_INDENT_USE_TAB' => 1,
   'CS_BRACE_FOLLOWS_CASE' => 1,
   'CS_INDENT_USE_TAB' => 1,
   'CS_RM_TRAILING_WS' => 1,
   'CS_RM_DUP_WS' => 1,
   'CS_ST_NL_FILE' => 1,
   'CS_INDENT_CLASS_BODY' => 1,
   'CS_RM_TRAILING_WS' => 1,
   'CS_RM_DUP_WS' => 1,
   'CS_ST_NL_FILE' => 1,
   'CS_INDENT_USE_TAB' => 1,
   'CS_PP_INDENT' => 1, 
   'CS_PP_INDENT_BLOCK' => 1,
   'CS_PP_INDENT_HEADER_GUARD' => 1,
   'CS_PP_OLD_STYLE_INDENT' => 1,
   'CS_PP_CODE_INDENT' => 1,
};

static int gNumericFields:[] = {
   'CPPB_BLANK_BEFORE_CASE' => 1,
   'CPPB_BLANK_BEFORE_FIRST_CASE' => 1,
   'CPPB_BL_BEFORE_FIRST_DECL' => 1,
   'CPPB_BL_BETWEEN_METHODS' => 1,
   'CPPB_BL_BETWEEN_FIELDS' => 1,
   'CPPB_BL_BETWEEN_MEMBER_CLASSES' => 1,
   'CPPB_BL_BETWEEN_DIFFERENT_DECLS' => 1,
   'CPPB_BL_BETWEEN_CLASSES' => 1,
   'CPPB_BL_START_BLOCK_IF' => 1,
   'CPPB_BL_END_BLOCK_IF' => 1,
   'CPPB_BL_START_BLOCK_FOR' => 1,
   'CPPB_BL_END_BLOCK_FOR' => 1,
   'CPPB_BL_START_BLOCK_WHILE' => 1,
   'CPPB_BL_END_BLOCK_WHILE' => 1,
   'CPPB_BL_START_BLOCK_DO' => 1,
   'CPPB_BL_END_BLOCK_DO' => 1,
   'CPPB_BL_END_BLOCK_SWITCH' => 1,
   'CPPB_BL_START_BLOCK_TRY' => 1,
   'CPPB_BL_START_BLOCK_CATCH' => 1,
   'CPPB_BL_START_BLOCK_METHOD' => 1,
   'CPPB_BL_END_BLOCK_CATCH' => 1,
   'CPPB_BL_BEFORE_LOCALS' => 1,
   'CPPB_BL_AFTER_LOCALS' => 1,
   'CPPB_BL_BETWEEN_FN_PROTOTYPES' => 1,
   'CPPB_BL_BEFORE_ACCESS' => 1,
   'CPPB_BL_AFTER_ACCESS' => 1,
   'JAVA_BL_BEFORE_PACKAGE' => 1,
   'JAVA_BL_AFTER_PACKAGE' => 1,
   'JAVA_BL_LEAVE_BETWEEN_IMPORTS' => 1,
   'JAVA_BL_AFTER_IMPORTS' => 1,
   'CPPB_INDENT_SYNTAX' => 1,
   'CPPB_LABEL_INDENT' => 1,
   'CPPB_BL_BETWEEN_COMMENTED_FIELDS' => 1,
   'JAVA_BL_BEFORE_SYNC' => 1,
   'JAVA_BL_AFTER_SYNC' => 1,
   'C_JD_BLANK_LINES_BEFORE_TAGS' => 1,
   'C_JD_BETWEEN_DIFF_TAGS' => 1,
   'C_JD_BETWEEN_SAME_TAGS' => 1,
   'JAVA_JD_BLANK_LINES_BEFORE_TAGS' => 1,
   'JAVA_JD_BETWEEN_DIFF_TAGS' => 1,
   'JAVA_JD_BETWEEN_SAME_TAGS' => 1,
   'M_JD_BLANK_LINES_BEFORE_TAGS' => 1,
   'M_JD_BETWEEN_DIFF_TAGS' => 1,
   'M_JD_BETWEEN_SAME_TAGS' => 1,
   'C_DOX_BETWEEN_DIFF_TAGS' => 1,
   'C_DOX_BETWEEN_SAME_TAGS' => 1,
   'C_DOX_AFTER_BRIEF' => 1,
   'JAVA_DOX_BETWEEN_DIFF_TAGS' => 1,
   'JAVA_DOX_BETWEEN_SAME_TAGS' => 1,
   'JAVA_DOX_AFTER_BRIEF' => 1,
   'MC_DOX_BETWEEN_DIFF_TAGS' => 1,
   'MC_DOX_BETWEEN_SAME_TAGS' => 1,
   'MC_DOX_AFTER_BRIEF' => 1,
   'C_DOX_BETWEEN_DIFF_TAGS' => 1,
   'C_DOX_BETWEEN_SAME_TAGS' => 1,
   'M_DOX_BETWEEN_DIFF_TAGS' => 1,
   'M_DOX_BETWEEN_SAME_TAGS' => 1,
   'JAVA_DOX_BETWEEN_DIFF_TAGS' => 1,
   'JAVA_DOX_BETWEEN_SAME_TAGS' => 1,
   'CS_BL_BEFORE_FIRST_DECL' => 1,
   'CS_BL_BETWEEN_METHODS' => 1,
   'CS_BL_BETWEEN_FIELDS' => 1,    
   'CS_BL_BETWEEN_COMMENTED_FIELDS' => 1,
   'CS_BL_BETWEEN_MEMBER_CLASSES' => 1,
   'CS_BL_BETWEEN_DIFFERENT_DECLS' => 1,
   'CS_BL_BETWEEN_CLASSES' => 1,
   'CS_BL_BETWEEN_FN_PROTOTYPES' => 1,
   'CS_JD_BLANK_LINES_BEFORE_TAGS' => 1,
   'CS_JD_BETWEEN_DIFF_TAGS' => 1,
   'CS_JD_BETWEEN_SAME_TAGS' => 1,
   'CS_DOX_BETWEEN_DIFF_TAGS' => 1,
   'CS_DOX_BETWEEN_SAME_TAGS' => 1,
   'CS_DOX_AFTER_BRIEF' => 1,
   'CS_BL_START_BLOCK_LOCK'   => 1,
   'CS_BL_END_BLOCK_LOCK'     => 1,
   'CS_BL_START_BLOCK_USING'  => 1,
   'CS_BL_END_BLOCK_USING'    => 1,
   'CS_VARALIGN_JUSTIFICATION' => 1,
   'JAVA_VARALIGN_JUSTIFICATION' => 1,
   'CPPB_VARALIGN_JUSTIFICATION' => 1,
   'CPPB_BRACELOC_MULTILINE_COND' => 1,
   'CS_BRACELOC_MULTILINE_COND' => 1,
   'CS_INSTVARALIGN_JUSTIFICATION' => 1,
   'CPPB_INSTVARALIGN_JUSTIFICATION' => 1
};

static boolean _is_boolean_field(_str fnkey) {
   if (gTrueBooleans._indexin(fnkey)) {
      return true;
   }
   return false;
}

static boolean _is_numeric_field(_str fnkey) {
   boolean rv = false;

   if (gNumericFields._indexin(fnkey)) {
      rv = true;
   } else if (!gTrueBooleans._indexin(fnkey)) {
      // Approximation that holds for now.
      int index = _const_value(fnkey, auto cstat);
      rv = ((cstat==0 && index < COMMON_OPTION_END) || index == CPPB_ORIGINAL_TAB);
   }
   return rv;
}

const BEAUT_CFG_TREE = "beaut_config_tree";
const BEAUT_DISPLAY_TIMER = "beaut_display_timer";
const BEAUT_LANGUAGE_ID = "beaut_lang_id";
const BEAUT_ALLOW_PREVIEWS = "beaut_allow_previews";
const BEAUT_LAST_INDEX = "beaut_last_index";
const BEAUT_ASSOC_EDITCTL = "beaut_assoc_editctl";
const BEAUT_PROFILE_CHANGED = "beaut_profile_changed";

// Sentinels for BEAUT_LAST_INDEX
const DO_NOT_RELOAD_PREVIEW = -2;
const RELOAD_PREVIEW = -1;

// Function we use to load/save options to the optionsxml configtree we use
// for our settings.
static _str _intern_beautifier_load_or_save(_str fnkey, _str value = null)
{
   int idx = _cfg_index(fnkey, auto status);
   if (status != 0) {
      return "";
   }

   if (value != null) {
      gCurrentSettings[idx] = value;
      return value;
   } else {
      if (idx < gCurrentSettings._length() && gCurrentSettings[idx] != null) {
         _str v = gCurrentSettings[idx];
         return v;
      } else {
         // This can occur when config options have been added since a 
         // previous release, and the user profiles don't have a setting
         // specified.  The beautifier defaults to the setting in the "Default"
         // system profile, we need to do that too.
         form := find_enclosing_form(p_window_id, '_beaut_options');
         if (form) {
            _str *lang = _GetDialogInfoHtPtr(BEAUT_LANGUAGE_ID, form);

            if (lang != null) {
               _str df[] = beautifier_load_profile('Default', *lang, auto ldstat);
               if (ldstat == 0 && idx < df._length()) {
                  // Don't leave holes in the array, or we'll have to do this all over again.
                  int i;
                  for (i = gCurrentSettings._length(); i < df._length(); i++) {
                     gCurrentSettings[i] = df[i];
                  }
                  return df[idx];
               }
            }
         }
         return (_str)DISABLE;
      }
   }
}


_str beautifier_load_or_save(_str fnkey, _str value = null) {
   _str rv;
   int index = _cfg_index(fnkey, auto j);

   // Some wrapping code to translate between optionsxml and
   // beautifier representations.  _intern_beautifier_load_or_save
   // does the heavy lifting.
   if (_is_numeric_field(fnkey)) {
      rv = _intern_beautifier_load_or_save(fnkey,value);
   } else {
      if (value != null) {
         value = _ui_to_config_val(fnkey, index, value);
      }
      rv = _config_val_to_ui(fnkey, index, (int)_intern_beautifier_load_or_save(fnkey,value));
   }

// if (value == null) {
//    say("FETCH "fnkey"="rv);
// } else {
//    say("SET "fnkey"="value);
// }

   return rv;
}

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
void ctl_cat_tree.on_create(_str langId)
{
   ec := get_current_editor_control(p_active_form);

   if (ec <= 0) {
      _ctl_beautify_button.p_visible = false;
      _SetDialogInfoHt(BEAUT_ASSOC_EDITCTL, 0);
   } else {
      _ctl_beautify_button.p_message = "Beautifies the editor buffer with the current settings.";
      gEditorControlOriginalSettings = ec.p_BeautifierCfg;
      if (gEditorControlOriginalSettings._length() == 0) {
         // Not loaded yet, help it along.
         gEditorControlOriginalSettings = get_options_for_language(ec.p_LangId);
      }
      _SetDialogInfoHt(BEAUT_ASSOC_EDITCTL, ec);
   }

   se.options.OptionsConfigTree t;
   t.init(ctl_cat_tree, _control ctl_value_frame, _control ctl_help_frame, getBeautifierOptionsFile(langId)); 
   _SetDialogInfoHt(BEAUT_ALLOW_PREVIEWS, 1);
   _SetDialogInfoHt(BEAUT_LANGUAGE_ID, langId);
   _SetDialogInfoHt(BEAUT_CFG_TREE, t);
   _SetDialogInfoHt(BEAUT_DISPLAY_TIMER, -1);
   _SetDialogInfoHt(OPTIONS_CHANGE_CALLBACK_KEY, find_index('_beaut_property_change_cb', PROC_TYPE));
   _SetDialogInfoHt(BEAUT_LAST_INDEX, RELOAD_PREVIEW);

   p_active_form.p_caption = gCurrentSettings[CBI_PROFILE_NAME]"/"LanguageSettings.getModeName(langId);
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
   schedule_deferred_update(250, p_active_form);
}

static _str getBeautifierOptionsFile(_str langId)
{
   return get_env("VSROOT")'sysconfig'FILESEP'formatter'FILESEP :+ langId :+ FILESEP'options.xml';
}

static _update_space_before_paren(boolean space_before_paren, _str (&options)[])
{
   // Will need to be hooked later for different languages.
   val := space_before_paren ? COMBO_Y : COMBO_N;

   options[CPPB_SP_IF_LPAREN] = val;
   options[CPPB_SP_SWITCH_LPAREN] = val;
   options[CPPB_SP_FOR_LPAREN] = val;
   options[CPPB_SP_CATCH_LPAREN] = val;
   options[CPPB_SP_WHILE_LPAREN] = val;
}

static void _update_pad_parens(boolean pad_parens, _str (&options)[])
{
   val := pad_parens ? COMBO_Y : COMBO_N;

   options[CPPB_SP_IF_PADPAREN] = val;
   options[CPPB_SP_SWITCH_PADPAREN] = val;
   options[CPPB_SP_FOR_PADPAREN] = val;
   options[CPPB_SP_CATCH_PADPAREN]  = val;
   options[CPPB_SP_WHILE_PADPAREN] = val;
}

static void update_profile_from_aff(_str (&options)[]) {
   if (!LanguageSettings.getUseAdaptiveFormatting(p_LangId)) {
      if (def_beautifier_debug > 1) 
         say("update_profile_from_aff: aff disabled");
      return;
   }

   // Force recalculation of adaptive formatting settings.
   p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);

   if (def_beautifier_debug > 1) 
      say("update_profile_from_aff: incoming_flags="p_adaptive_formatting_flags);

   int changedFlags = 0;

   updateAdaptiveFormattingSettings(AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS|AFF_INDENT_CASE|AFF_BEGIN_END_STYLE|AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN, false,
                                    &changedFlags);

   if (def_beautifier_debug > 1) 
      say("update_profile_from_aff: outgoing_flags="changedFlags);

   if (changedFlags & AFF_NO_SPACE_BEFORE_PAREN) {
      _update_space_before_paren(!p_no_space_before_paren, options);
      if (def_beautifier_debug > 1) say("update_profile_from_aff: no_space_before_paren => "p_no_space_before_paren);
   }

   if (changedFlags & AFF_PAD_PARENS) {
      _update_pad_parens(p_pad_parens, options);
      if (def_beautifier_debug > 1) say("update_profile_from_aff: pad_parens => "p_pad_parens);
   }

   if (changedFlags&AFF_INDENT_WITH_TABS) {
      if (p_indent_with_tabs) {
         options[CBI_INDENT_POLICY] = COMBO_IN_TABS;
      } else {
         options[CBI_INDENT_POLICY] = COMBO_IN_SPACES;
      }
      if (def_beautifier_debug > 1) say("update_profile_from_aff: indent_policy => "options[CBI_INDENT_POLICY]);
   }

   if (changedFlags&AFF_SYNTAX_INDENT) {
      options[CBI_SYNTAX_INDENT] = p_SyntaxIndent;
      options[CBI_CASE_INDENT_WIDTH] = p_SyntaxIndent;
      if (def_beautifier_debug > 1) say("update_profile_from_aff: syntax_indent => "options[CBI_SYNTAX_INDENT]);
   }

   if (changedFlags&AFF_TABS) {
      options[CBI_TAB_INDENT] = normalize_tabs(p_tabs);
      if (def_beautifier_debug > 1) say("update_profile_from_aff: tabs => "options[CBI_TAB_INDENT]);
   }

   if (changedFlags&AFF_INDENT_CASE) {
      if (p_indent_case_from_switch) {
         options[CPPB_INDENT_CASE] = '1';
      } else {
         options[CPPB_INDENT_CASE] = '0';
      }
      if (def_beautifier_debug > 1) say("update_profile_from_aff: indent_case => "options[CBI_INDENT_CASE]);
   }

   if (def_beautifier_aff_bracestyle != 0 && changedFlags&AFF_BEGIN_END_STYLE) {
      ubs := find_index('_'p_LangId'_update_brace_settings', PROC_TYPE);
      if (ubs != 0) {
         call_index(p_begin_end_style, p_LangId, options, ubs);
         if (def_beautifier_debug>1) 
            say("update_profile_from_aff: brace_style => "p_begin_end_style);
      }
   }
}

void _ctl_beautify_button.lbutton_up()
{
   int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

   if (last_sel_index) {
      *last_sel_index = DO_NOT_RELOAD_PREVIEW;
   }
   schedule_deferred_update(150, p_active_form);

   ec := get_current_editor_control(p_active_form);

   if (ec > 0) {
      long markers[];

      owid := p_window_id;
      p_window_id = ec;
      markers[0] = _QROffset();
      ec.p_BeautifierCfg = gCurrentSettings;
      ec.p_tabs = '+'gCurrentSettings[CBI_TAB_INDENT];
      beautify_buffer(ec, markers, BEAUT_FLAG_NONE);
      _GoToROffset(markers[0]);
      refresh();
      p_window_id = owid;
   }
}

void _ctl_reset_button.lbutton_up()
{
   se.options.OptionsTree* ot = p_active_form._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot) 
      return;

   int idx = p_active_form.ctl_cat_tree._TreeCurIndex();

   _str ex = ot->getCurrentSystemHelp();

   if (ex != '') {
      int* last_sel_index = p_active_form._GetDialogInfoHtPtr(BEAUT_LAST_INDEX);

      if (last_sel_index) {
         *last_sel_index = RELOAD_PREVIEW;
      }

      set_user_example_file(p_active_form, ex, '');
      ctl_formatted_edit.delete_all();
      schedule_deferred_update(150, p_active_form);
   }
}

void _ctl_open_button.lbutton_up()
{
   se.options.OptionsTree* ot = p_active_form._GetDialogInfoHtPtr(BEAUT_CFG_TREE);

   if (!ot) 
      return;

   int idx = p_active_form.ctl_cat_tree._TreeCurIndex();
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
      schedule_deferred_update(100, p_active_form);
   }
}

const MIN_TREE_WIDTH = 1440;

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

      ctl_value_frame.p_x = ctl_cat_tree.p_x + ctl_cat_tree.p_width + DEFAULT_DIALOG_BORDER;
      ctl_value_frame.p_width = minWidth;

      if (ctl_value_frame.p_child) {
         ctl_value_frame.p_child.p_width = ctl_value_frame.p_width - (2 * ctl_value_frame.p_child.p_x);
      }
   }
}

// Only call this for combo boxes and booleans, not numeric fields.
static int _ui_to_config_val(_str fnkey, int index, _str val) {
   if (val == 'True' || val == 'y') {
      if (_is_boolean_field(fnkey)) {
         return 1;
      } else {
         return COMBO_Y;
      }
   } else if (val == 'False' || val == 'n') {
      if (_is_boolean_field(fnkey)) {
         return 0;
      } else {
         return COMBO_N;
      }
   } else {
      return (int)val;
   }
}

// Only call this for combo boxes and booleans, not numeric fields.
static _str _config_val_to_ui(_str fnkey, int index, int val) {
   if (_is_boolean_field(fnkey)) {
      if (val) {
         return 'y';
      } else {
         return 'n';
      }
   }

   if (val == COMBO_Y) {
      return 'y';
   } else if (val == COMBO_N) {
      return 'n';
   } else {
      return (_str)val;
   }
}

void _beaut_property_change_cb(Property *p)
{
   // Update gSetttings with the changed value, and then
   // force the preview to update.
   if (p->isCheckable()) {
      int checkState = p->getCheckState();
      beautifier_load_or_save_3state(p->getFunctionKey(), 
                                     p->getActualValue(), 
                                     checkState);
   } else {
      beautifier_load_or_save(p->getFunctionKey(),
                              p->getActualValue());
   }

   // The active form is very likely a form embedded in our form.
   form := find_enclosing_form(p_active_form, '_beaut_options');
   if (form) {
      int* last_sel_index = _GetDialogInfoHtPtr(BEAUT_LAST_INDEX, form);

      if (last_sel_index) {
         *last_sel_index = RELOAD_PREVIEW;
      }
      schedule_deferred_update(150,form);
   }
}

/**
 * Schedules a preview window update for later.
 * @param when How long to wait before doing the update.  If -1, 
 *             then the function just kills any exising timer
 *             without registering a new one.
 * @param form 
 */
static void schedule_deferred_update(int when, int form, _str fnName = 'showBeautOptionsPanel')
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
   schedule_deferred_update(-1, form);

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
   ec := _GetDialogInfoHt(BEAUT_ASSOC_EDITCTL, p_active_form);

   if (ec > 0 && gEditorControlOriginalSettings._length() > 0) {
      ec.p_BeautifierCfg = gEditorControlOriginalSettings;
      ec.p_tabs = '+'gEditorControlOriginalSettings[CBI_TAB_INDENT];
   }
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
         schedule_deferred_update(150, p_active_form);
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

   int idx = formWid.ctl_cat_tree._TreeCurIndex();

   if (idx >= 0
       && (!last_sel_index
           || *last_sel_index != idx)) {
		int open_button = formWid._find_control('_ctl_open_button');
		int reset_button = formWid._find_control('_ctl_reset_button');
      int formatted = formWid._find_control('ctl_formatted_edit');

      ot->goToTreeNode(idx);
      example := ot->getCurrentSystemHelp(); 
      if (example && example != "Bogus") {

         if (*last_sel_index != DO_NOT_RELOAD_PREVIEW) {
            formatted.delete_all();
         }
         update_preview(formatted, example, (_str)formWid._GetDialogInfoHt(BEAUT_LANGUAGE_ID));
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

static boolean profile_conflicts_with_existing(_str prof_name, _str langid)
{
   profiles := beautifier_profiles_for(langid);

   for (i := 0; i < profiles._length(); i++) {
      if (profiles[i] == prof_name) {
         return true;
      }
   }
   return false;
}

/**
 * Brings up the profile editor for the given profile name. 
 * Updates profile_name if the user had to save to a different 
 * profile name. 
 * 
 * @param profile_name 
 * @param language_id 
 * @param change_default_on_save_as - If the user changes a 
 *                                  system profile and saves the
 *                                  modified profile under
 *                                  another name, controls
 *                                  whether we change the
 *                                  default profile to this new
 *                                  profile immediately or not.
 * @return int 0 on success, or an error code on failure.
 */
int _beautifier_edit_profile(_str& profile_name='', _str language_id='', boolean change_default_on_save_as = false, boolean *cancelled = null)
{
   if (cancelled) {
      *cancelled = false;
   }

   if (!new_beautifier_supported_language(language_id)) {
      //gui_beautify();
      return 0;
   }

   int status = 0;
   gCurrentSettings = beautifier_load_profile(profile_name, language_id, status);


   if (status != 0) {
      return status;
   }

   _str result=show('-xy -modal _beaut_options', language_id);
   if (result==IDCANCEL || result == '') {
      if (cancelled) {
         *cancelled = true;
      }
      return 0;
   }

   origProfileName := profile_name;
   conflictRename := false;
   while (conflictRename
          ||beautifier_is_system_profile(language_id, profile_name)) {
      int mbrc;

      if (conflictRename) {
         conflictRename = false;
         mbrc = textBoxDialog("Save Profile As", 0, 0, "", "", "", 
                               "Pick a different profile name to save this as:"profile_name);
      } else {
         mbrc = textBoxDialog("Save Profile As", 0, 0, "", "", "", 
                               "Pick a new profile name to save this as:My "profile_name);
      }

      if (mbrc == COMMAND_CANCELLED_RC) {
         if (_message_box("Discard your changes?", "Cancel Edit", MB_YESNO) == IDYES) {
            return 1;
         }
      } else {
         profile_name = _param1;
         if (beautifier_is_system_profile(language_id, profile_name)) {
            continue;
         }
      }

      if (profile_conflicts_with_existing(profile_name, language_id)) {
         mbrc = _message_box("A profile named '"profile_name"' already exists.  Overwrite it?", "Confirm Overwrite", MB_YESNO);
         if (mbrc == IDYES) {
            break;
         }
         conflictRename = true;
      }
   }

   gCurrentSettings[CBI_PROFILE_NAME] = profile_name;
   status = beautifier_save_profile(gCurrentSettings);

   if (status != 0) {
      return status;
   }

   if (origProfileName != profile_name
       && change_default_on_save_as) {
      LanguageSettings.setBeautifierProfileName(p_LangId, profile_name);
   }

   invalidate_options_cache(language_id);
   options_changed_handler(gCurrentSettings, language_id);
   return 0;
}



_command int beautifier_edit_current_profile()  name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_EDITORCTL)
{
   _str prof = LanguageSettings.getBeautifierProfileName(p_LangId);
   return _beautifier_edit_profile(prof, p_LangId, true);
}

_OnUpdate_beautifier_edit_current_profile(CMDUI cmdui,int target_wid,_str command)
{
 if ( !target_wid || !target_wid._isEditorCtl() ) {
    return(MF_GRAYED);
 }

 if (new_beautifier_supported_language(target_wid.p_LangId)) {
    return MF_ENABLED;
 } else {
    return MF_GRAYED;
 }
}


/**
 * Beautifies the code between the two source offsets.
 *  
 * @param start 
 * @param end 
 * 
 * @return int 
 */
int new_beautify_range(long start, long endo, long (&markers)[], boolean save_cursor = false, boolean restore_cursor_right = false, 
                       boolean beaut_leading_context = false, int beaut_flags = BEAUT_FLAG_NONE, void (*tweak_profile)(_str (&)[]) = null)
{
   save_pos(auto sp1);
   pcy := p_cursor_y;
   pcx := p_scroll_left_edge;
   cursor_idx := markers._length();
   if (save_cursor) {
      cline_len := _text_colc();
      if (p_col > cline_len) {
         // We don't like markers that are in virtual columns.
         _end_line();
      }
      markers[markers._length()] = _QROffset();
   }

   _GoToROffset(start);
   startLine := p_line;

   _GoToROffset(endo);
   endLine := p_line;


   // save bookmark, breakpoint, and annotation information
   _SaveBookmarksInFile(auto bmSaves, startLine, endLine);
   _SaveBreakpointsInFile(auto bpSaves, startLine, endLine);
   _SaveAnnotationsInFile(auto annoSaves);

   _str opts[] = get_options_for_language(p_LangId);

   update_profile_from_aff(opts);

   if (tweak_profile != null) {
      (*tweak_profile)(opts);
   }
   p_BeautifierCfg = opts;

   int rc = beautify_snippet(start, endo, markers, &opts, beaut_leading_context, beaut_flags);
   restore_pos(sp1);
   set_scroll_pos(pcx, pcy);
   if (rc < 0) {
      return rc;
   } else {
      // restore bookmarks, breakpoints, and annotation locations
      _RestoreBookmarksInFile(bmSaves);
      _RestoreBreakpointsInFile(bpSaves);
      _RestoreAnnotationsInFile(annoSaves);
      if (save_cursor) {
         _GoToROffset(markers[cursor_idx]);
         set_scroll_pos(pcx, pcy);
         if (restore_cursor_right) {
            next_char();
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

static int getSmartTabColumn()
{
   int smartpaste_index=0;
   _get_smarttab(p_LangId,smartpaste_index);
   if (!smartpaste_index) return(0);
   
   // check if we are in a comment
   if (_smart_in_comment(false)) {
      return 0;
   }

   save_pos(auto p);
   typeless orig_markid=_duplicate_selection('');
   typeless markid=_alloc_selection();_select_line(markid);
   _show_selection(markid);
   // We want the smart-indent answer, even if they don't have it enabled.
   old_style := p_indent_style;
   p_indent_style = INDENT_SMART;
   typeless enter_col=call_index(true, // char type clipboard so we try harder
                        2,    // first col not 1 so we try harder
                        1,    // Noflines==1
                        true, // allow the enter_col = 1
                        smartpaste_index
                        );
   p_indent_style = old_style;

   _show_selection(orig_markid);_free_selection(markid);
   restore_pos(p);

   return enter_col;
}

// Helper for going to the beginning of a statement that takes
// care of the corner cases for comments and preprocessing.
static void _ctx_goto_statement_beginning() {
   first_non_blank();
   int pp_max;
   _str ch;

   for (pp_max=30; p_line > 1; pp_max--) {
      get_line(auto line);
      if (line == '') {
         if (search('[^ \t\r\n]', '-R@<') == 0) {
            first_non_blank();
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
         first_non_blank();
      } else if (_clex_find(0, 'G') == CFG_COMMENT) {
         _clex_find_start();
         if (def_beautifier_debug > 1)
            say("_ctx_goto_statement_beginning: to start of comment @ "_QROffset());
         return;
      } else {
         first_non_blank();
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
const MAX_FUN_LINES = 5;

void _c_snippet_find_leading_context(long selstart, long selend) {
   if (def_beautifier_usetaginfo && p_LangId != 'java' && p_LangId != 'cs') {
      int i;
      _GoToROffset(selstart);
      start_line := p_line;


      _UpdateContext(true,true,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
      tag_lock_context(false);

      for (i = 0; i<2; i++) {
         first_non_blank();
         stmt := tag_current_statement();
         if (stmt > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_type, stmt, auto stype);
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, stmt, auto stline);
            if (stype == 'func' && (start_line-stline) > MAX_FUN_LINES) {
               // This can happen for incomplete statements, which you can get when
               // brace auto-close and syntax expansion are off.
               prev_char();
               _clex_skip_blanks('-');
               _ctx_goto_statement_beginning();
               if (def_beautifier_debug > 1) 
                  say("_c_snippet_find_leading_context: rejected, heuristic start @"_QROffset());
            } else {
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, stmt, auto ststart);
               _GoToROffset(ststart);
               if (def_beautifier_debug > 1) 
                  say("_c_snippet_find_leading_context: tag statement start @"_QROffset());

               if (stype == 'proto' || stype == 'func') {
                  // If we're in a class, it is possible to misinterpret a constructor decl
                  // as a function call, without enough leading context to distinguish the two.
                  tag_get_detail2(VS_TAGDETAIL_class_id, stmt, auto klass);
                  if (klass > 0) {
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
      long sw_off = 0;
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

   boolean had_to_unwind = deepest != 0;
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
         // if we can to help out ctx_goto_statement_begining for
         // things like multiline for statements.
         find_matching_paren(true);
         if (def_beautifier_debug > 1) say("_c_snippet_find_leading_context: control paren to "_QROffset());
      } else if (mch == ':') {
         // Maybe a case statement in a switch.
         first_non_blank();
         cword := cur_word(auto whatever);
         if (cword == 'default' || cword == 'case') {
            long found_offset = 0;
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

void _java_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
}

void _cs_snippet_find_leading_context(long selstart, long selend) {
   _c_snippet_find_leading_context(selstart, selend);
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
const SNIPPET_SURROUND = 0x1;       // dynamic surround state was saved and restored -
                                    //   will need to be redisplayed.

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
int beautify_snippet(long offset_orig_begin, long offset_orig_end, long (&markers)[], _str (*bconfig)[] = null, boolean beaut_leading_context = false, 
                     int beaut_flags = BEAUT_FLAG_NONE) {

   // Ensure user markers are in the selection.
   foreach (auto m  in markers) {
      offset_orig_end = max(m, offset_orig_end);
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

   if (surround_get_extent(auto sur_start, auto sur_end)
       && _ranges_overlap(offset_user_begin, offset_user_end, sur_start, sur_end)) {
      // If we overlap an active dynamic surround, expand to include all of it,
      // otherwise, we'll mangle it.
      offset_user_begin = min(offset_user_begin, sur_start);
      offset_user_end = max(offset_user_end, sur_end);
      if (def_beautifier_debug > 1) say("beautify_snippet: surround expand("offset_user_begin","offset_user_end")");
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
         say("beautify_snippet: expanded end for comment: "offset_user_begin", "offset_user_end);
   }


   // expand like it was a line selection again.
   _GoToROffset(offset_user_begin);
   p_col = 1;
   offset_user_begin = _QROffset();
   _GoToROffset(offset_user_end);
   _end_line();
   offset_user_end = _QROffset();

   num_user_markers := markers._length();
   save_stream_markers(auto smstate, markers, offset_user_begin, offset_user_end);
   extent_markers := markers._length();

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

   init_indent := max(0, getSmartTabColumn() - 1);
   if (def_beautifier_debug > 1) 
      say("initial indent="init_indent);

   // Create temp view with content from extended content selection to the end
   // of the user's selection.
   int status, tview, orig_wid;
   sel1 := make_line_selection(offset_ctx_begin, offset_user_end);
   if (sel1 >= 0) {
      orig_wid = _create_temp_view(tview);
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
   int  delim_offset = markers._length(); 

   markers[delim_offset]     = udelim_start;   // So we can get feedback on the new position 
   markers[delim_offset + 1] = udelim_end;

   if (bconfig != null) {
      p_window_id.p_BeautifierCfg = *bconfig;
   } else {
      p_window_id.p_BeautifierCfg = orig_wid.p_BeautifierCfg;
   }

   if (def_beautifier_debug > 1) {
      say("beautify_snippet: udelim_start="udelim_start", udelim_end="udelim_end);
      _dump_var(markers, "remapped input markers");
   }
   status = beautify_buffer_selection(p_window_id, markers, udelim_start, udelim_end, init_indent, beaut_flags | BEAUT_FLAG_SNIPPET);
   if (status < 0) {
      message(get_message(status));
      _delete_temp_view(tview);
      return status;
   }

   if (def_beautifier_debug > 1) {
      _dump_var(markers, 'raw markers out');
   }

   // Since we don't do trailing context, the end should always be
   // the end of the temp buffer. But we want to trim off trailing
   // whitespace and newlines for uniform handling when we paste
   // this back into the source buffer.
   bottom();
   if ( 0 == search('[~ \t\r\n]', 'rh@-')) {
      next_char();
      // But don't eat any trailing whitespace the beautifier left.
      while (get_text() == ' ') {
         next_char();
      }
   }
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
   if (offset_user_begin >= p_RBufSize) {
      // Expansion at the end of the file.  Don't go into
      // virtual space by trying to seek there.
      bottom();
      _insert_text(p_newline);
   } else {
      _GoToROffset(offset_user_begin);
      left(); _insert_text(p_newline);  // we don't want nosplit-line, it can screw up offsets if it adjusts previous line.
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
   long start = _QROffset();

   end_select();
   long endo = _QROffset();
   long markers[];
   return new_beautify_range(start, endo, markers);
}

const OPTIONS_PREVIEW = "main";
static get_options_preview_file(_str langid)
{
   if (langid == 'c') {
      return OPTIONS_PREVIEW'.cpp';
   } else if (langid == 'm') {
      return OPTIONS_PREVIEW'.m';
   } else if (langid == 'java') {
      return OPTIONS_PREVIEW'.java';
   } else if (langid == 'cs') {
      return OPTIONS_PREVIEW'.cs';
   }
}

/**
 * Dialog that's embedded in 
 * Tools->Options->Languages->Blah->Formatting 
 */
defeventtab _new_beautifier_config;

static void repopulate_profile_list(_str cur_profile, _str lang)
{
   profiles := beautifier_profiles_for(lang);

   if (cur_profile == '') {
      cur_profile = profiles[0];
   }

   _ctl_profile_selection.p_cb_list_box._lbclear();
   for (i := 0; i < profiles._length(); i++) {
      _ctl_profile_selection.p_cb_list_box._lbadd_item(profiles[i]);
   }
   _ctl_profile_selection.p_cb_text_box.p_text = cur_profile;
}

static void update_button_state(_str langid, _str profile)
{
   estate := true;

   if (beautifier_is_system_profile(langid, profile)) {
      estate = false;
   }
   _ctl_delete_profile.p_enabled = estate;
}

static void update_options_preview(int wid, _str file, _str lang, _str profilename)
{
   gCurrentSettings = beautifier_load_profile(profilename, lang, auto status);

   if (status == 0) {
      update_preview(wid, file, lang);
   }
}

void _bc_update_preview_cb(int form)
{
   // update_options_preview() doesn't work exactly right if 
   // called from _new_beautifier_config_init_for_options, so
   // we call this from a timer in that case.
   schedule_deferred_update(-1, form);
   int selector = form._find_control('_ctl_profile_selection');

   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID, form);
   cur_prof := selector.p_cb_text_box.p_text;
   _str ext = '';

   if (langid == 'c') {
      ext = 'cpp';
   } else if (langid == 'm') {
      ext = 'm';
   } else if (langid == 'java') {
      ext = 'java';
   } else if (langid == 'cs') {
      ext = 'cs';
   }

   update_options_preview(form._find_control('_ctl_preview'), get_options_preview_file(langid), langid, cur_prof);
}

void _new_beautifier_config_restore_state(_str options) {
    schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _new_beautifier_config_init_for_options(_str langid)
{
   // do a little fancy work to make sure the buttons look nice -
   // they are autosized and may need to be adjusted
   padding := ctllabel1.p_x;
   _ctl_edit_profile.p_x = _ctl_profile_selection.p_x + _ctl_profile_selection.p_width + padding;
   _ctl_create_profile.p_x = _ctl_edit_profile.p_x + _ctl_edit_profile.p_width + padding;
   _ctl_delete_profile.p_x = _ctl_create_profile.p_x + _ctl_create_profile.p_width + padding;

   _ctl_loadfile_button.p_x = _ctl_preview.p_x + _ctl_preview.p_width - _ctl_loadfile_button.p_width;
   _ctl_reset_button.p_x = _ctl_loadfile_button.p_x - padding - _ctl_reset_button.p_width;
// _ctl_beautify_button.p_x = _ctl_reset_button.p_x - padding - _ctl_beautify_button.p_width;

   cur_prof := LanguageSettings.getBeautifierProfileName(langid);
   repopulate_profile_list(cur_prof, langid);
   _ctl_profile_selection.p_cb_text_box.p_text = cur_prof;
   update_button_state(langid, cur_prof);
   _SetDialogInfoHt(BEAUT_LANGUAGE_ID, langid);
   _SetDialogInfoHt(BEAUT_DISPLAY_TIMER, -1);
   _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);

   schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _new_beautifier_config_cancel()
{
   // Cancel the timer, in case the user was remarkably quick.
   schedule_deferred_update(-1, p_active_form);
}

boolean _new_beautifier_config_apply()
{
   // Cancel the timer, in case the user was remarkably quick.
   schedule_deferred_update(-1, p_active_form);

   lang := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   prof := _ctl_profile_selection.p_cb_text_box.p_text;

   opt := beautifier_load_profile(prof, lang, auto status);
   if (status == 0) {
      LanguageSettings.setBeautifierProfileName(lang, prof);
      invalidate_options_cache(lang);
      options_changed_handler(opt, lang);
      _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 0);
   }
   return true;
}

boolean _new_beautifier_config_is_modified()
{
   lang := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   changed := _GetDialogInfoHt(BEAUT_PROFILE_CHANGED);

   return (changed || LanguageSettings.getBeautifierProfileName(lang) != _ctl_profile_selection.p_cb_text_box.p_text);
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

   // if this is a user profile, we'll need the file, too
   if (!beautifier_is_system_profile(langID, args)) {

      // see if we need to copy a user profile file
      userProfiles := _ConfigPath() :+ USER_BEAUTIFIER_PROFILES_FILE;
      if (file_exists(userProfiles)) {
         targetFile := file :+ USER_BEAUTIFIER_PROFILES_FILE;

         // see if this file already exists - that means we've already
         // exported a profile (and this one with it) - so do nothing!
         if (!file_exists(targetFile)) {
            // the system lexer file is our base
            if (copy_file(userProfiles, targetFile)) error = 'Error copying beautifier profiles file, 'userProfiles'.';
         }
         file = USER_BEAUTIFIER_PROFILES_FILE;
      }
   } // else system profile

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
      do {
         // get the profile for this language
         importXmlHandle := _xmlcfg_open(file, auto status);
         if (importXmlHandle < 0) {
            error = 'Error opening beautifier profile file 'file'.';
            break;
         }

         // get the profile for this language - the name should be the args
         searchString := "//"BEAUTIFIER_XML_TAG_PROFILE'[@name="'args'"][@lang="'langID'"]';
         profileIndex := _xmlcfg_find_simple(importXmlHandle, searchString);
         if (profileIndex < 0) {
            error = 'Error finding beautifier profile named 'args' in 'file'.';
            break;
         }

         // now open our existing beautifier file
         userProfiles := _ConfigPath() :+ USER_BEAUTIFIER_PROFILES_FILE;
         userProfilesXmlHandle := -1;
         if (file_exists(userProfiles)) {
            userProfilesXmlHandle = _xmlcfg_open(userProfiles, status);
         } else {
            userProfilesXmlHandle = _xmlcfg_create(userProfiles, VSENCODING_UTF8);
         }

         // see if we already have a profile with this name for this language
         existingProfileIndex := _xmlcfg_find_simple(userProfilesXmlHandle, searchString);
         if (existingProfileIndex > 0) {
            // delete it so we can overwrite it
            _xmlcfg_delete(userProfilesXmlHandle, existingProfileIndex);
         }

         // now copy in our new profile
         profilesNode := _xmlcfg_find_simple(userProfilesXmlHandle, "'/"BEAUTIFIER_XML_TAG_ROOT);
         if (profilesNode < 0) {
            profilesNode = _xmlcfg_add(userProfilesXmlHandle, 0, BEAUTIFIER_XML_TAG_ROOT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         }
         _xmlcfg_copy(userProfilesXmlHandle, profilesNode, importXmlHandle, profileIndex, VSXMLCFG_COPY_AS_CHILD);

         // now set the lexer name for the language
         _xmlcfg_save(userProfilesXmlHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
         _xmlcfg_close(userProfilesXmlHandle);
         _xmlcfg_close(importXmlHandle);

         opt := beautifier_load_profile(args, langID, status);
         if (status == 0) {
            LanguageSettings.setBeautifierProfileName(langID, args);
            invalidate_options_cache(langID);
            options_changed_handler(opt, langID);
         }

      } while (false);
   } else {
      // no file, that means we need to set a system profile
      // first, make sure it exists on this system
      if (beautifier_is_system_profile(langID, args)) {
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

   heightDiff := p_height - (_ctl_preview_frame.p_y + _ctl_preview_frame.p_height + padding);
   widthDiff := p_width - (_ctl_preview_frame.p_x + _ctl_preview_frame.p_width + padding);

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
   schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
}

void _ctl_loadfile_button.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   wildcards := 'Source Files ('get_language_wildcards(langid)'), All Files (*.*)';


   _str res = _OpenDialog("-modal", "Open Preview File", "Source Files", wildcards, OFN_FILEMUSTEXIST|OFN_READONLY|OFN_NOCHANGEDIR|OFN_EDIT);

   if (res != "") {
      _ctl_preview.delete_all();
      _ctl_preview.get(res);
      schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
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
   orig_prof := cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;

   boolean cancelled = false;

   _beautifier_edit_profile(cur_prof, langid, false, &cancelled);
   if (!cancelled) {
      if (orig_prof != cur_prof) {
         // They saved it under a different name than we started with.
         repopulate_profile_list(cur_prof, langid);
         _ctl_profile_selection.p_cb_text_box.p_text = cur_prof;
         update_button_state(langid, cur_prof);
      }   
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
      invalidate_options_cache(langid);
      _SetDialogInfoHt(BEAUT_PROFILE_CHANGED, 1);
   }
}

void _ctl_delete_profile.lbutton_up()
{
   langid := _GetDialogInfoHt(BEAUT_LANGUAGE_ID);
   cur_prof := _ctl_profile_selection.p_cb_text_box.p_text;

   mbrc := _message_box("Are you sure you want to delete the profile '"cur_prof"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
   if (mbrc == IDYES) {
      beautifier_delete_profile(langid, cur_prof);
      repopulate_profile_list('', langid);
      cur_prof = _ctl_profile_selection.p_cb_text_box.p_text;
      update_button_state(langid, cur_prof);
      update_options_preview(_control _ctl_preview, get_options_preview_file(langid), langid, cur_prof);
   }
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
         prof = _param1; 

         if (beautifier_is_system_profile(langid, prof)) {
            mbrc = _message_box("Can not overwrite system profiles.", "Invalid Name");
            needToPrompt = true;
            continue;
         }

         if (profile_conflicts_with_existing(prof, langid)) {
            mbrc = _message_box("A profile named '"prof"' already exists.  Overwrite it?", "Confirm Overwrite", MB_YESNO);
            if (mbrc != IDYES) {
               needToPrompt = true;
            }
         }
      }
   }

   brc := beautifier_create_profile(langid, prof, cur_prof);
   if (brc == 0) {
      repopulate_profile_list(prof, langid);
      update_button_state(langid, prof);
      schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
   } else {
      _message_box("Failure creating new profile. (rc="brc")");
   }
}

_command void new_beautifier_options() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (new_beautifier_supported_language(p_LangId)) {
      // cheap.
      setupext('-formatting');
   } else {
      _message_box('"'LanguageSettings.getModeName(p_LangId)'" does not have a beautifier.');
   }
}




/** 
 * @param lang Language id
 * 
 * @return int Amount to indent member access specifiers by, or 
 *         0 for no indent.
 */
int beaut_member_access_indent(_str lang)
{
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      if (opts[CBI_MEMBER_ACCESS_INDENT] == '1') {
         return (int)opts[CBI_MEMBER_ACCESS_INDENT_WIDTH];
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


static int gKeywordToConfigKey:[] = {
   'if' => CPPB_BRACE_LOC_IF,
   'else' => CPPB_BRACE_LOC_IF,
   'else if' => CPPB_BRACE_LOC_IF,
   'switch' => CPPB_BRACE_LOC_SWITCH,
   'while' => CPPB_BRACE_LOC_WHILE,
   'for' => CPPB_BRACE_LOC_FOR,
   'do' => CPPB_BRACE_LOC_DO,
   'try' => CPPB_BRACE_LOC_TRY,
   'catch' => CPPB_BRACE_LOC_CATCH,
   'asm' => CPPB_BRACE_LOC_ASM,
   '_asm' => CPPB_BRACE_LOC_ASM,
   '__asm' => CPPB_BRACE_LOC_ASM,
   'namespace' => CPPB_BRACE_LOC_NAMESPACE,
   'class' => CPPB_BRACE_LOC_CLASS,
   'struct' => CPPB_BRACE_LOC_CLASS,
   'union' => CPPB_BRACE_LOC_CLASS,
   'enum'  => CPPB_BRACE_LOC_ENUM,
   '@interface' => CPPB_BRACE_LOC_CLASS,  //TODO: does this get its own brace loc?
};

int beaut_style_for_keyword(_str lang, _str kw, boolean& found)
{
   if (new_beautifier_supported_language(lang)) {
      typeless beautCfg = get_options_for_language(lang);

      if (beautCfg != null) {
         update_profile_from_aff(beautCfg);
         int* idx = gKeywordToConfigKey._indexin(kw);
         if (idx
             && *idx >= 0
             && *idx < beautCfg._length()) {
            return beautifier_xlat_brace_loc(beautCfg[*idx]);
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


static long _calc_selection_to_offset(long from_offset, int num_sel_lines, long &sel_start, long& sel_end) {
   save_pos(auto p1);
   _GoToROffset(from_offset);

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
      say("_calc_selection_to_offset: from="from_offset", to="to_offset);

   _GoToROffset(from_offset);
   to_offset = _expand_forward_context(to_offset);
   restore_pos(p1);
   return to_offset;
}

void beautify_moved_selection(_str sel_type, long sel_src, long from_offset, int num_sel_lines) {
   if (!beautify_paste_expansion(p_LangId) || !gAllowBeautifyCopy) 
      return;

   if (!_macro('S')) {
      _undo('S');
   }

   // Cursor is positioned at the end of the selection when we're called.
   end_of_sel_actual := _QROffset();

   to_offset := _calc_selection_to_offset(from_offset, num_sel_lines, auto destsel_start, auto destsel_end);

   // We want to have the beautifier track whatever line of the selection
   // our caller left the cursor on, but preserve the column number.
   savecol := p_col;
   long markers[];

   // Map destination selection area to beautified version.
   markers[0] = destsel_start;
   markers[1] = destsel_end;
   markers[2] = end_of_sel_actual;

   new_beautify_range(min(from_offset, sel_src, to_offset), 
                      max(to_offset, sel_src, from_offset), markers, true, false, true);

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
boolean beaut_indent_members_from_access_spec(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      return opts[CBI_MEMBER_ACCESS_RELATIVE_INDENT] == '1';
   } else {
      return true;
   }
}

/**
 * @param lang 
 * 
 * @return int Amount to indent the case statement by.
 */
int beaut_case_indent(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      update_profile_from_aff(opts);
      if (opts[CBI_INDENT_CASE] == '1') {
         return (int)opts[CBI_CASE_INDENT_WIDTH];
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
int beaut_funcall_param_alignment(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      return (int)opts[CBI_FUNCALL_PARAM_ALIGN];
   } else {
      if (LanguageSettings.getUseContinuationIndentOnFunctionParameters(lang,false)) {
         return COMBO_AL_CONT;
      } else {
         return COMBO_AL_AUTO;
      }
   }
}

int beaut_continuation_indent(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      return (int)opts[CBI_CONTINUATION_WIDTH];
   } else {
      return p_SyntaxIndent;
   }
}

int beaut_initial_anonfn_indent(_str lang) {
   if (lang == 'm') {
      opts := get_options_for_language(lang);
      return (int)opts[OBJC_BLOCK_INITIAL_INDENT];
   } else {
      return p_SyntaxIndent;
   }
}

int beaut_method_decl_continuation_indent(_str lang) {
   if (lang == 'm') {
      opts := get_options_for_language(lang);
      if ((int)opts[OBJC_METH_CALL_BRACKET_ALIGN] == COMBO_AL_CONT) {
         return (int)opts[CBI_CONTINUATION_WIDTH];
      } else {
         return 0;
      }
   } else {
      return 0;
   }
}

int beaut_should_indent_namespace(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      if (lang != 'cs') {
         opts := get_options_for_language(lang);
         return (int)opts[CPPB_INDENT_NAMESPACE];
      } else {
         //TODO: make separate setting for C#, or unify so this branch can go away.
         return 1;
      }
   } else {
      return 1;
   }
}
int beaut_should_indent_extern(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      return (int)opts[CPPB_INDENT_EXTERN];
   } else {
      return 1;
   }
}

int beaut_brace_indents_with_case(_str lang) {
   if (new_beautifier_supported_language(lang)) {
      opts := get_options_for_language(lang);
      if (opts._length() > CPPB_BRACE_FOLLOWS_CASE) {
         return (int)opts[CPPB_BRACE_FOLLOWS_CASE];
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
boolean beautify_on_edit(_str lang) {
   return (new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_ON_EDIT) != 0);
}

/**
 * Returns true if we should beautify syntax expansions.
 */
boolean beautify_syntax_expansion(_str lang) {
   return (new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_SYNTAX) != 0);
}


/**
 * Returns true if we should beautify syntax expansions.
 */
boolean beautify_alias_expansion(_str lang) {
   return (new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_ALIAS) != 0);
}

/**
 * Returns true if we should beautify syntax expansions.
 */
boolean beautify_paste_expansion(_str lang) {
   return (new_beautifier_supported_language(lang) && (LanguageSettings.getBeautifierExpansions(lang) & BEAUT_EXPAND_PASTE) != 0);
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
      _copy_or_move('', 'M', 1, 1);

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

boolean beautifier_should_delay_brace_decision(_str lang)
{
   if (!new_beautifier_supported_language(lang)) {
      return false;
   }

   int status;
   n := 'ALLOW_CLASS_ONE_LINE_BLOCK';

   int index = _lang_cfg_index(lang, n, status);

   //TODO: take both one line options into account.
   if (status == 0) {
      opts := get_options_for_language(lang);
      return opts[index] == COMBO_Y;
   }
   return false;
}

// helper for align variables, makes sure the variable aligment settings are enabled
// when trying to align the variables.
static void _enable_aligment_settings(_str (&opts)[]) 
{
   int status;
   n := 'VARALIGN_JUSTIFICATION';

   int index = _lang_cfg_index(opts[CBI_LANG_ID], n, status);

   if (status == 0) {
      opts[index] = (_str)((int)opts[index] & ~DISABLE);
   }

   n = 'INSTVARALIGN_JUSTIFICATION';
   index = _lang_cfg_index(opts[CBI_LANG_ID], n, status);
   if (status == 0) {
      opts[index] = (_str)((int)opts[index] & ~DISABLE);
   }
}

_command void align_variables() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION)
{
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
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (!new_beautifier_supported_language(target_wid.p_LangId)) {
      return (MF_GRAYED);
   }

   return(MF_ENABLED);
}
