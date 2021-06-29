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
#include "tagsdb.sh"
#include "vsevents.sh"
#include "minihtml.sh"
#include "color.sh"
#include "diff.sh"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/OvertypeMarker.e"
#import "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "bind.e"
#import "box.e"
#import "c.e"
#import "cbrowser.e"
#import "ccode.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cua.e"
#import "cutil.e"
#import "diffedit.e"
#import "dir.e"
#import "dlgman.e"
#import "docbook.e"
#import "files.e"
#import "help.e"
#import "html.e"
#import "main.e"
#import "javaopts.e"
#import "jrefactor.e"
#import "listproc.e"
#import "markfilt.e"
#import "math.e"
#import "menu.e"
#import "mouse.e"
#import "notifications.e"
#import "picture.e"
#import "pushtag.e"
#import "recmacro.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "tagform.e"
#import "taggui.e"
#import "util.e"
#import "vc.e"
#import "vi.e"
#import "xmldoc.e"
#import "backtag.e"
#endregion

using se.lang.api.LanguageSettings;

static bool gSCIMConfigured;

/**
 * Maximum number of parameters to display for parameter
 * information.  Any number of parameters over this threshold
 * will be elided.
 *
 * @default 8
 * @categories Configuration_Variables
 */
int def_codehelp_max_params=8;

/**
 * Maximum number of lines to retrieve for comment help
 * when retrieving comments for parameter information or
 * list members.
 *
 * @default 500
 * @categories Configuration_Variables
 */
int def_codehelp_max_comments=500;

bool def_codehelp_html_comments = true;


const CODEHELP_DOXYGEN_PREFIX= "/*!";
const CODEHELP_DOXYGEN_PREFIX1= "//!";
const CODEHELP_DOXYGEN_PREFIX2= "///";
const CODEHELP_JAVADOC_PREFIX= "/**";
const CODEHELP_JAVADOC_END_PREFIX= "*/";

static const CODEHELP_FORCE_CASE_SENSITIVE=     2;
static const CODEHELP_PREFER_CASE_SENSITIVE=    1;
static const CODEHELP_CASE_INSENSITIVE=         0;

/*
  Scroll height needs to be at least
    pad_y+
    font_height+
    pad_y+
    horizontal scroll bar height
    all times 2
  Using 10 has big problems
*/
static SCROLL_BAR_HEIGHT(int screen_height) {
    return max((screen_height*_twips_per_pixel_y()) intdiv 10,1900);
}

   struct HYPERTEXTSTACK{
      int HyperTextTop;    // -1 indicates empty.
                                   // Otherwise HyperTextStack[HyperTextTop] is top entry
      int HyperTextMaxTop; // Maximum value of HyperTextTop since comment help popped up
      struct {
         typeless htmlCtlScrollInfo;
         int TagIndex;
         VSAUTOCODE_ARG_INFO TagList[];
      }s[];
   };

   static int geditorctl_wid;
   static int geditorctl_buf_id;

   static int gFunctionHelp_form_wid;
   static bool gFunctionHelp_MouseOver;
   struct FUNCTIONHELP_MOUSEOVER_INFO {
      int wid;
      int x,y,width,height;  // Rectangle for mouse
      int buf_id;    // Original buffer id
      int LineNum;   // Original line number
      int col;       // Original column
      _str ScrollInfo;  // Original scroll info;
      typeless OrigPos;
      _str streamMarkerMessage;
   };
   FUNCTIONHELP_MOUSEOVER_INFO gFunctionHelp_MouseOverInfo;
   static bool gFunctionHelp_OperatorTyped;
   static bool gFunctionHelp_FirstCall;
   static bool gFunctionHelp_InsertedParam;
   static _str gFunctionHelp_HelpWord;
   static int gFunctionHelpTagIndex;

   static bool gFunctionHelp_OnFunctionName;
   static int gFunctionHelp_ArgumentNameOffset;
   static int gFunctionHelp_FunctionNameOffset;
   static int gFunctionHelp_FunctionLineOffset;
   static _str gFunctionHelp_starttext;
   static int gFunctionHelp_flags;

   static int gFunctionHelp_UpdateLineNumber;
   static int gFunctionHelp_UpdateLineCol;
   static VSAUTOCODE_ARG_INFO gFunctionHelp_list[];
   static VS_TAG_BROWSE_INFO  gFunctionHelp_selected_symbol;
   //static int gFunctionHelp_ParamNum;
   static int gFunctionHelp_cursor_y;
   static int gFunctionHelp_cursor_x;

   struct LINECOMMENTCHARS {
      _str commentChars[];
   };

   struct BLOCKCOMMENTCHARS {
      _str startChars[];
      _str endChars[];
      bool nesting[];
   };

   static LINECOMMENTCHARS g_lineCommentChars:[] = null;
   static BLOCKCOMMENTCHARS g_blockCommentChars:[] = null;


static int LISTHELPTREEWID(...) {
   if (arg()) ctlminihtml2.p_user=arg(1);
   return ctlminihtml2.p_user;
}

static HYPERTEXTSTACK HYPERTEXTSTACKDATA(...) {
   if (arg()) ctlminihtml1.p_user=arg(1);
   return ctlminihtml1.p_user;
}
defeventtab codehelp_key_overrides;
def ESC=codehelp_key;
def PGUP=codehelp_key;
def PGDN=codehelp_key;
def DOWN=codehelp_key;
def C_K=codehelp_key;
def UP=codehelp_key;
def C_I=codehelp_key;
def C_G=codehelp_key;
def ENTER=codehelp_key;
def C_C=codehelp_key;
def C_A=codehelp_key;
def C_U=codehelp_key;
def TAB=codehelp_key;
def "A-."=codehelp_key;
def "A-,"=codehelp_key;
def "A-INS"=codehelp_key;
def "M-."=codehelp_key;
def "M-,"=codehelp_key;
def "M-INS"=codehelp_key;
def "C-DOWN"=codehelp_key;
def "C-UP"=codehelp_key;
def "C- "=codehelp_key;
def "C-PGDN"=codehelp_key;
def "C-PGUP"=codehelp_key;
def "S-PGDN"=codehelp_key;
def "S-PGUP"=codehelp_key;

// Might want to add a new def_codehelp_flags called
// VSCODEHELPFLAG_ENABLE_EXTRA_SHIFT_KEYS
def "S-HOME"=codehelp_key;
def "S-END"=codehelp_key;
def "S-UP"=codehelp_key;
def "S-DOWN"=codehelp_key;

//def \0-\127=;
def " "-\127=codehelp_key;
//def "="=codehelp_key;
bool gpending_switchbuf;
static _str gpending_switchbuf_buf_name;

definit()
{
   if (arg(1)!='L') {
      /* Editor initialization case. */
      ginFunctionHelp=false;
      gFunctionHelp_pending=false;
      gFunctionHelp_selected_symbol = null;

      g_lineCommentChars = null;
      g_blockCommentChars = null;
      geditorctl_wid=0;
      geditorctl_buf_id=0;
   }
   gpending_switchbuf=false;
}

void _before_write_state_codehelp()
{
   g_lineCommentChars = null;
   g_blockCommentChars = null;
}

void _lexer_updated_codehelp(_str lexername = "")
{
   // clear cached comment data
   if (g_lineCommentChars._indexin(lexername)) {
      g_lineCommentChars._deleteel(lexername);
   }
   if (g_blockCommentChars._indexin(lexername)) {
      g_blockCommentChars._deleteel(lexername);
   }
}

/**
 * In html when the keyword combination <% is detected add a line
 * to complete the block with %> on it. This completes a embedded java
 * block.
 */
void auto_complete_script_block(_str last_key, _str current_key)
{
   if(last_key=="<") {
      // DJB 02/15/2006 -- never insert %> on a new line,
      // since the user might be typing <%= expr %>
      //
      // check to see if there is existing text on the line
      //_str textAfterCursor=_expand_tabsc(p_col,-1,'S');
      //if (textAfterCursor!="") {
         _insert_text("%>");
         _GoToROffset(_QROffset()-2);
      //} else {
      //   insert_line("%>");
      //   _GoToROffset(_QROffset()-3);
      //}
   }
}

/**
 * Command normally bound to keystrokes that should initiate
 * auto-function help or auto-syntax help.  For example in
 * C or Pascal, this is bound to the open parenthesis.
 *
 * Does not invoke function help if on command line or in a
 * comment or string, or if auto function help is turned off.
 *
 * @see _do_function_help()
 */
_command void auto_functionhelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if (command_state() || _MultiCursor()) {
      call_root_key(l_event);
      return;
   }
   if (l_event=="<" && _inDocComment()) {
      auto_codehelp_key();
      return;
   }

   if (_LanguageInheritsFrom("java") && def_jrefactor_auto_import) {
      refactor_add_import(true);
   } else if (_LanguageInheritsFrom("cs") && def_csharp_refactor_auto_import) {
      refactor_add_import(true);
   }
   //say("auto_functionhelp_key()");
   _macro_delete_line();
   _macro_call("AutoBracketKeyin",l_event);
   AutoBracketKeyin(l_event);
   if (_haveContextTagging() && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP)) {
      left();
      int cfg=_clex_find(0,'g');
      right();

      // do not do auto-function help for operator <<
      if (get_text(2,_nrseek()-2) == "<<") {
         return;
      }

      // convert #include "<" to #include <> and force list members
      langId := p_LangId;
      VS_TAG_IDEXP_INFO idexp_info;
      if (!_Embeddedget_expression_info(false, langId, idexp_info)) {
         if ((idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
             (idexp_info.prefixexp == "#include" || 
              idexp_info.prefixexp == "#require" || 
              idexp_info.prefixexp == "#import")) {
            get_line(auto line);
            line = stranslate(line,"","[ \t]",'r');
            if ((LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) != AC_POUND_INCLUDE_NONE) &&
                (get_text(2,_nrseek()-1)=="<\"" || get_text(2,_nrseek()-2)=="\"<") &&
                (_last_char(line) == '"') && 
                (!pos("<",line,11))) {
               if (get_text(2,_nrseek()-2)=="\"<") left();
               left();
               _delete_text(2);
               _insert_text("<");
               orig_col := p_col;
               p_col += length(line) - 11;
               if (idexp_info.prefixexp == "#import") right();
               _delete_text(1);
               _insert_text(">");
               p_col = orig_col;
               if (get_text(2,_nrseek()-1) == "<>") {
                  _do_list_members(OperatorTyped:true, DisplayImmediate:true);
               }
               return;
            }
         }
      }

      if (cfg!=CFG_STRING) {

         // check if the line starts with a #include statement
         if (LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_ON_QUOTELT && 
             !_Embeddedget_expression_info(false, langId, idexp_info)) {
            if ((idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
                (idexp_info.prefixexp == "#include" || 
                 idexp_info.prefixexp == "#require" || 
                 idexp_info.prefixexp == "#import")) {
               if (get_text_safe() != ">") {
                  _insert_text(">");
                  left();
               }
               _do_list_members(OperatorTyped:true, DisplayImmediate:true);
               return;
            }
         }

         // try return type based value matching if supported and option is on
         tryReturnTypeMatching := (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_VALUES)? true:false;
         if (!_FindLanguageCallbackIndex("vs%s_get_expression_pos") &&
             !_FindLanguageCallbackIndex("_%s_get_expression_pos")) {
            tryReturnTypeMatching = false;
         }

         // this is the fun part
         _do_function_help(OperatorTyped:true,
                           DisplayImmediate:false,
                           cursorInsideArgumentList:false,
                           tryReturnTypeMatching);
      }
   }
}
static _str get_arg_info_type_name(VSAUTOCODE_ARG_INFO &fn)
{
   // do not do auto-list-parameters for #define's
   if (fn.tagList._length() > 0) {
      if ( fn.tagList[0].browse_info != null ) {
         return fn.tagList[0].browse_info.type_name;
      }
      tag_decompose_tag_browse_info(fn.tagList[0].taginfo, auto cm);
      return cm.type_name;
   }
   return "";
}

/**
 * Command normally bound to keystrokes that should initiate
 * auto-list-members.  For example, in C and C++, this could be
 * ".", ":", or ">" (last char of "->").
 *
 * Does not invoke function help if on command line or in a
 * comment or string, or if auto function help is turned off.
 *
 * @see _do_list_members()
 * @categories Tagging_Functions
 */
_command void auto_codehelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   //say("auto_codehelp_key()");
   if (command_state() || _MultiCursor() || _macro('KR') /*Vim kbd macro running? */) {
      call_root_key(last_event());
      return;
   }
   _str akey=key2ascii(last_event());
   if (length(akey)!=1) {
      return;
   }
   _str key=akey;
   _str last_key=get_text(1,(int)_QROffset()-1);

   if(_EmbeddedLanguageKey(key)) return;

   if(key==">" && _inDocumentationComment() && LanguageSettings.getSyntaxExpansion('html')) {
      maybe_insert_html_close_tag();
      return;
   }
   if(key=="]" && _LanguageInheritsFrom("bbc") && LanguageSettings.getSyntaxExpansion('bbc')) {
      maybe_insert_html_close_tag();
      return;
   }
   _macro_delete_line();
   _macro_call("keyin",akey);

   // maybe do auto-import for Java
   l_event := akey;
   if (def_jrefactor_auto_import && _LanguageInheritsFrom("java") && (key=="." || key==">" || key=="=")) {
      refactor_add_import(true);
   } else if (def_csharp_refactor_auto_import && _LanguageInheritsFrom("cs") && (key=="." || key==">" || key=="=")) {
      refactor_add_import(true);
   }

   keyin(l_event);
   /*
     Fix for performance problem when typing '<' or '/' in a
     large XML file.
   */
   if (p_buf_size>=def_update_context_max_ksize*1024) {
      return;
   }


   // maybe automatically translate "." to "->" for C/C++ and Slick-C
   langId := p_LangId;
   if (def_c_auto_dot_to_dash_gt && key == "." && (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("e"))) {
      c_auto_dot_to_dashgt();
   }

   if(key=="%" && p_LangId=="html") {
      auto_complete_script_block(last_key, key);
   }

   if (_haveContextTagging() && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      // maybe have to update function help first
      if (ginFunctionHelp) {
         still_in_function_help(MAXINT);
      }
      // obtain the expected parameter type if in codehelp
      expected_name := "";
      expected_type := "";
      arglist_type := "";
      if (ginFunctionHelp && !gFunctionHelp_pending &&
          (geditorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) ) {
         i := gFunctionHelpTagIndex;
         n := gFunctionHelp_list._length();
         if (i>=0 && i<n) {
            expected_name=gFunctionHelp_list[i].ParamName;
            expected_type=gFunctionHelp_list[i].ParamType;
            arglist_type=get_arg_info_type_name(gFunctionHelp_list[i]);
            if (arglist_type == "define") expected_type = "";
         }
      }
      if (expected_type == "" || arglist_type!="define") {
         _do_list_members(OperatorTyped:true,
                          DisplayImmediate:false,
                          syntaxExpansionWords:null,
                          expected_type,
                          rt:null,
                          expected_name);
      }
   }
}
/**
 * Attempt to use Context Tagging&reg; to complete the word under the
 * cursor.  If the word can not be completed, or tagging isn't
 * supported, then try expanding aliases.
 *
 * @see expand_alias
 *
 * @categories Tagging_Functions
 */
_command void codehelp_complete() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
#if 0
   if (machine()=="LINUX") {
      if (!gSCIMConfigured && last_event():==name2event("c- ") && _SCIMRunning()) {
         gSCIMConfigured=true;
         int result=_message_box("Do you want Ctrl+Space to perform completion?\n\nIf you choose \"Yes\" (recommended), you can display the SCIM input method editor by pressing Ctrl+Alt+Space instead of Ctrl+Space. If you choose \"No\", Ctrl+Space will display the SCIM input method editor and you will not have any alternate key binding for performing symbol/alias completion.\n\nTo configure this later, go to Tools>Options>Redefine Common Keys and set the \"Use Ctrl+Space for input method editor\" check box.","Configure Ctrl+Space",MB_YESNO);
         if (result==IDYES) {
            _default_option(VSOPTION_USE_CTRL_SPACE_FOR_IME,0);
         } else {
            _default_option(VSOPTION_USE_CTRL_SPACE_FOR_IME,1);
         }
         return;
      }
   }
#endif

   // check if this is our first try or second try at this
   index := last_index('','C');
   prev := prev_index('','C');
   isFirstAttempt := !AutoCompleteCommandRepeated();

   //say("codehelp_complete()");
   if (!command_state()) {
      _str errorArgs[];errorArgs._makeempty();
      typeless orig_values;
      int status=_EmbeddedStart(orig_values);
      if (!_istagging_supported() &&
          // I bet we won't need this for long..
          !_LanguageInheritsFrom("xml") && !_LanguageInheritsFrom("dtd")
          ) {
         if (status==1) {
            _EmbeddedEnd(orig_values);
         }
         _expand_alias();
         last_index(index,'C');
         prev_index(prev,'C');
         return;
      }
      left();
      cfg := _clex_find(0,'g');
      right();
      if (!_in_comment() && (cfg!=CFG_STRING ||
                             _LanguageInheritsFrom("cob") || _LanguageInheritsFrom("html") ||
                             _LanguageInheritsFrom("dtd") || _LanguageInheritsFrom("xml")
                            )) {
         //If an exact alias match, expand the alias rather than symbol completion.
         if (!_expand_alias("","",alias_filename(true,false))) {
            last_index(index,'C');
            prev_index(prev,'C');
            return;
         }
         _do_complete(isFirstAttempt);
      } else {
         _expand_alias();
      }
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
   } else {
      _expand_alias();
   }

   last_index(index,'C');
   prev_index(prev,'C');
}

/** 
 * If the word under the cursor is an alias, expand it. 
 * Otherwise, attempt to use Auto-Complete the word under the cursor. 
 *
 * @see expand_alias 
 * @see autocomplete( 
 *
 * @categories Tagging_Functions
 */
_command void codehelp_autocomplete() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   index := last_index('','C');
   prev := prev_index('','C');

   //say("codehelp_complete()");
   if (!command_state()) {
      _str errorArgs[];errorArgs._makeempty();
      typeless orig_values;
      int status=_EmbeddedStart(orig_values);
      if (!_istagging_supported() &&
          // I bet we won't need this for long..
          !_LanguageInheritsFrom("xml") && !_LanguageInheritsFrom("dtd")
          ) {
         if (status==1) {
            _EmbeddedEnd(orig_values);
         }
         _expand_alias();
         last_index(index,'C');
         prev_index(prev,'C');
         return;
      }
      left();
      int cfg=_clex_find(0,'g');
      right();
      if (!_in_comment() && (cfg!=CFG_STRING ||
                             _LanguageInheritsFrom("cob") || _LanguageInheritsFrom("html") ||
                             _LanguageInheritsFrom("dtd") || _LanguageInheritsFrom("xml")
                            )) {
         //If an exact alias match, expand the alias rather than symbol completion.
         if (!_expand_alias("","",alias_filename(true,false))) {
            last_index(index,'C');
            prev_index(prev,'C');
            return;
         }
         autocomplete();
      } else {
         _expand_alias();
      }
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
   } else {
      _expand_alias();
   }

   last_index(index,'C');
   prev_index(prev,'C');
}

/*
      Cursor must be at first character of start of
      line comment.

    parameters
       first_line

*/
static int get_line_comment_range(int &first_line,int &last_line)
{
   required_indent_col := p_col;
   typeless orig_pos;
   save_pos(orig_pos);
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      // Caller screwed up.
      restore_pos(orig_pos);
      return(1);
   }
   first_line=p_line;
   // Find end of comment
   int status=_clex_skip_blanks("h");
   if (status) {
      bottom();
   }
   last_line=p_line-1;
   // Now only include lines which have the correct indent
   p_line=first_line+1;
   int Noflines=last_line-first_line+1;
   for (;--Noflines>0;) {
      _first_non_blank('h');
      if (p_col<required_indent_col) {
         last_line=p_line-1;
         break;
      }
      down();
   }
   restore_pos(orig_pos);
   return(0);
}
static void get_line_comment(VSCodeHelpCommentFlags &comment_flags,
                             _str tag_type,
                             _str &comments,
                             int &first_line,
                             int &last_line,
                             int line_limit)
{
   comment_flags=0;
   comments="";
   first_line = last_line = p_line;
   typeless orig_pos;
   save_pos(orig_pos);
   _end_line();
   typeless end_seek=_nrseek();
   left();
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      restore_pos(orig_pos);
      return;
   }
   linenum := p_line;
   int status=_clex_find(COMMENT_CLEXFLAG,"n-");
   if (status || linenum!=p_line) {
      restore_pos(orig_pos);
      return;
   }
   ++p_col;
   if(get_line_comment_range(first_line,last_line)) {
      restore_pos(orig_pos);
      return;
   }
   line_prefix := "";
   int blanks:[][];
   doxygen_comment_start := "";
   _parse_multiline_comments(p_col,first_line,last_line,comment_flags,tag_type,comments,line_limit,
                             line_prefix,blanks,doxygen_comment_start);
   restore_pos(orig_pos);
}
/**
 * Parse multiline comments, starting from the 'first_line' and parsing
 * up until the 'last_line'.
 *
 * @param line_comment_indent_col  Indent column for line comments
 * @param first_line     First line to start parsing at
 * @param last_line      Last line to parse to
 * @param comment_flags  (reference) bitset of VSCODEHELP_COMMENTFLAG_*
 * @param tag_type       tag type name (see SE_TAG_TYPE_*)
 * @param comments       (reference) set to line-by-line comments
 * @param line_limit     maximum number of lines to parse
 * @param line_prefix    (reference) comment line prefix
 * @param blanks         (reference) blank lines after comment tags
 */
void _parse_multiline_comments(
   int line_comment_indent_col,
   int first_line,int last_line,
   VSCodeHelpCommentFlags &comment_flags,
   _str tag_type,
   _str &comments,
   int line_limit,
   _str &line_prefix,
   int (&blanks):[][],
   _str &doxygen_comment_start)
{
   blanks._makeempty();
   comment_flags=0;

   Noflines := last_line-first_line+1;
   if (Noflines>line_limit) Noflines=line_limit;
   p_line=first_line;

   _str comment_lines[];
   line := _expand_tabsc(line_comment_indent_col);
   for (i:=0;i<Noflines;++i) {
      cur_line_flags := _lineflags();
      if (cur_line_flags & NOSAVE_LF) {
         down();
         continue;
      }
      line=_expand_tabsc(line_comment_indent_col);
      comment_lines :+= line;
      down();
   }

   status := tag_tree_parse_multiline_comment(comment_lines, 
                                              line_comment_indent_col, 
                                              first_line, 
                                              last_line, 
                                              line_limit, 
                                              comment_flags, 
                                              comments, 
                                              line_prefix, 
                                              doxygen_comment_start, 
                                              blanks, 
                                              p_LangId, 
                                              _extra_word_chars:+p_word_chars,
                                              _dbcs());

   if (_chdebug) {
      say("_parse_multiline_comments: FLAGS="comment_flags);
      say("_parse_multiline_comments: PREFIX="line_prefix);
      say("_parse_multiline_comments: DOXYGEN="doxygen_comment_start);
      _dump_var(blanks, "_parse_multiline_comments: blanks");
      split(comments, "\n", auto comment_array);
      for (i=0; i < comment_array._length(); i++) {
         say("_make_html_comments: line["i"]="comment_array[i]);
      }
      _dump_var(blanks, "_parse_multiline_comments: blanks");
   }
}

/**
 * Dynamically add links to attribute/value help.
 * <P>
 * The current object must be an editor control or the current buffer.
 *
 * @param comments  (reference) Comments passed in by caller
 */
static void _html_tagdoc_extra(_str &comments)
{
   // We only insert extra attribute/value help for our own builtin
   // "html.tagdoc" source.
   filename := _strip_filename(p_buf_name,'P');
   if (!_file_eq(filename,"html.tagdoc") && !_file_eq(filename,"cfml.tagdoc") &&
       !_file_eq(filename,"xml.tagdoc") && !_file_eq(filename,"xsd.tagdoc")) return;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Verify there is a context
   _UpdateContext(true);
   context_id := tag_current_context();
   if( context_id<=0 ) return;

   name := "";
   class_name := "";
   type_name := "";
   tag_get_detail2(VS_TAGDETAIL_context_name,context_id,name);
   tag_get_detail2(VS_TAGDETAIL_context_class,context_id,class_name);
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);

   type_name=lowcase(type_name);
   // 'tag'   = HTML tag (e.g. BODY, IMG, etc.)
   // 'group' = HTML tag attribute (e.g. align, etc.)
   if (type_name!="tag" && type_name!="group") return;
   // We only want the current context, so the tag file list is null
   _str tag_files[]=null;
   num_matches := 0;
   filter_flags := SE_TAG_FILTER_NULL;
   context_flags := SE_TAG_CONTEXT_ANYTHING;
   if (type_name=="group") {
      name=class_name":"name;
      filter_flags=SE_TAG_FILTER_ANYTHING;
      context_flags=SE_TAG_CONTEXT_ACCESS_PRIVATE|SE_TAG_CONTEXT_ONLY_THIS_CLASS;
   } else {
      filter_flags=SE_TAG_FILTER_MEMBER_VARIABLE;
      context_flags=SE_TAG_CONTEXT_ONLY_INCLASS;
   }
   tag_push_matches();
   // Clear matches or else get old matches mixed in with current matches
   tag_clear_matches();
   struct VS_TAG_RETURN_TYPE visited:[];
   tag_list_in_class("",name,0,0,
                     tag_files,num_matches,def_tag_max_find_context_tags,
                     filter_flags,
                     context_flags,
                     false,p_EmbeddedCaseSensitive,
                     null, null, visited, 1);
   // We want a sorted list of attribute/value links
   _str attrval_list[];
   for (i:=1;i<=num_matches;++i) {
      // Concatenate them this way so sorting sorts on attr_tag_name
      tag_get_match_browse_info(i, auto info);
      attrval_list[attrval_list._length()]=info.member_name","info.class_name;
   }
   tag_pop_matches();
   // Sort the list
   attrval_list._sort((p_EmbeddedCaseSensitive)?"":"i");
   links := "";
   for (i=0;i<attrval_list._length();++i) {
      parse attrval_list[i] with auto attrval_name "," auto attrval_class_name;
      link := "{@link ";
      link :+= attrval_class_name;
      link :+= "#"attrval_name" "attrval_name"}";
      links :+= link", ";
   }
   // Insert the attribute/value help before the first example (@example).
   if (links!="") {
      links=strip(links);
      links=strip(links,"T",",");
      i=pos('(^|\n)\@example',comments,1,'r');
      if (!i) {
         // Put attributes at end of comment
         i=length(comments)+1;
      }
      if (name=="group") {
         links="@values "links;
      } else {
         links="@attributes "links;
      }
      comments=substr(comments,1,i-1):+
                      "\n"links"\n":+
                      substr(comments,i);
   }

   return;
}
/**
 * Extension-non-specific callback for getting the comments
 * associated with the tag starting at the cursor position.
 * Distinguishes line comments from multi-line header comments.
 * 
 * @param comment_flags    (output) JavaDoc or HTML comment?
 * @param tag_type         tag type, corresponding to SE_TAG_TYPE_*
 * @param comments         (output) collected comments
 * @param line_limit       maximum number of lines to collect
 * @param line_comments    get line comments or ignore them (false)
 * @param line_prefix      (output) comment line prefix
 * @param blanks           (output) blank lines after comment tags
 * @param doxygen_comment_start
 */
void _do_default_get_tag_comments(VSCodeHelpCommentFlags &comment_flags,
                                  _str tag_type,_str &comments,
                                  int line_limit=500,
                                  bool line_comments=true,
                                  _str &line_prefix="",
                                  int (&blanks):[][]=null,
                                  _str &doxygen_comment_start=""
                                  )
{
   comment_flags=0;
   //say("_do_default_get_tag_comments("tag_type")");
   typeless orig_pos;
   save_pos(orig_pos);
   comments="";
   first_line := 0;
   last_line := 0;
   VSCodeHelpCommentFlags line_comment_flags=0;
   if (line_comments) {
      get_line_comment(line_comment_flags,tag_type,comments,first_line,last_line,line_limit);
   }
   comment_flags=line_comment_flags;
   //say("_do_default_get_tag_comments: line="comments);

   // we found line comments to the right of this symbol
   if (comments != "" && last_line > first_line && !tag_tree_type_is_func(tag_type)) {
      return;
   }

   start_col := 1;
   int status=_do_default_get_tag_header_comments(first_line,last_line);
   if (_chdebug) {
      say("_do_default_get_tag_comments H"__LINE__": status="status" first_line="first_line" last_line="last_line);
   }
   if (!status) {
      header_comments := "";
      _parse_multiline_comments(1,first_line,last_line,
                                comment_flags,tag_type,header_comments,
                                line_limit,line_prefix,blanks,
                                doxygen_comment_start);
      if (_chdebug) {
         say("_do_default_get_tag_comments H"__LINE__": first_line="first_line);
         say("_do_default_get_tag_comments H"__LINE__": last_line="last_line);
         say("_do_default_get_tag_comments H"__LINE__": header_comments="header_comments);
         say("_do_default_get_tag_comments H"__LINE__": line_prefix="line_prefix);
         say("_do_default_get_tag_comments H"__LINE__": doxygen_comment_start="doxygen_comment_start);
         say("_do_default_get_tag_comments H"__LINE__": comment_flags="comment_flags);
      }
      if ((comment_flags & (VSCODEHELP_COMMENTFLAG_HTML|VSCODEHELP_COMMENTFLAG_JAVADOC|VSCODEHELP_COMMENTFLAG_DOXYGEN))) {
         if (!(line_comment_flags&VSCODEHELP_COMMENTFLAG_HTML)) {
            comments=header_comments;
         } else {
            if (length(comments)) strappend(comments,"<hr>");
            strappend(comments,header_comments);
         }
      } else {
         if (!(line_comment_flags&VSCODEHELP_COMMENTFLAG_HTML)) {
            if (length(comments)) strappend(comments,"\n");
            strappend(comments,header_comments);
         }
         if (!(comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC)) {
            comment_flags=line_comment_flags;
         }
      }
   }

   // check if there is an extension specific callback for additional comments
   if (comment_flags == 0) {
      index := _FindLanguageCallbackIndex("_%s_get_tag_additional_comments");
      if (index) {
         restore_pos(orig_pos);
         status = call_index(first_line,last_line,start_col,index);
         if (!status) {
            line_comment_flags = comment_flags;
            add_comments := "";
            _parse_multiline_comments(start_col,first_line,last_line,
                                      comment_flags,tag_type,add_comments,
                                      line_limit,line_prefix,blanks,
                                      doxygen_comment_start);
            if ((comment_flags & VSCODEHELP_COMMENTFLAG_HTML)) {
               if (length(comments)) strappend(comments,"<hr>");
               strappend(comments,add_comments);
            } else {
               if (length(comments)) strappend(comments,"\n");
               strappend(comments,add_comments);
            }
         }
      }
   }

   restore_pos(orig_pos);

   // Dynamically add links to attribute/value help
   _html_tagdoc_extra(comments);
}
/**
 * On entry, cursor is on line,column of tag symbol.
 * Finds the starting line and ending line for the tag's comments.
 *
 * @param first_line   (output) set to first line of comment
 * @param last_line    (output) set to last line of comment
 * @param start_line   (optional, output) set to first line above current symbol (skips over annotations) 
 *
 * @return 0 if header comment found and first_line,last_line
 *         set.  Otherwise, 1 is returned.
 */
int _do_default_get_tag_header_comments(int &first_line, int &last_line, int &start_line=1)
{
   // check if there is an extension specific callback.
   start_line = first_line = last_line = p_line;
   index := _FindLanguageCallbackIndex("_%s_get_tag_header_comments");
   if (index) {
      status := call_index(first_line,last_line,start_line,index);
      if (!status) {
         return(0);
      }
   }
   return _do_default_get_tag_header_comments_above(first_line, last_line, start_line);
}

/** 
 * On entry, cursor is on line,column of tag symbol.
 * Finds the starting line and ending line for the tag's comments 
 * (above the current line) 
 *
 * @param first_line   (output) set to first line of comment
 * @param last_line    (output) set to last line of comment 
 * @param start_line   (optional, output) set to first line above current symbol (skips over annotations) 
 *
 * @return 0 if header comment found and first_line,last_line set. 
 *         Otherwise, 1 is returned.
 */
int _do_default_get_tag_header_comments_above(int &first_line, int &last_line, int &start_line=1)
{
   // skip blank lines before tag
   line := "";
   save_pos(auto orig_pos);
   orig_line := p_line;
   for (;;) {
      up();
      if (p_line==0) {
         restore_pos(orig_pos);
         return(1);
      }
      get_line(line);
      if (line!="") {
         break;
      }
   }
   // skip past leading spaces
   _first_non_blank('h');
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      found_comment:=false;
      // Skip annotation lines before the function header. The comment is
      // before the annotation lines.
      annotation_lead_char := '';
      annotation_tail_char := '';
      if (p_LangId=='java' || _LanguageInheritsFrom('kotlin') || p_LangId == 'scala') {
         annotation_lead_char = '@';
      } else if (_LanguageInheritsFrom('cs')) {
         annotation_lead_char = '[';
         annotation_tail_char = ']';
      } else if (p_LangId=='c') {
         annotation_lead_char = '[[';
         annotation_tail_char = ']';
      }
      if (annotation_lead_char != '') {
         for (;;) {
            _first_non_blank('h');
            cfg := _clex_find(0,'g');
            if (cfg != CFG_COMMENT) {
               if (cfg == CFG_WINDOW_TEXT || cfg == CFG_PUNCTUATION || cfg == CFG_OPERATOR) {
                  if (get_text(length(annotation_lead_char)) == annotation_lead_char) {
                     _last_non_blank('h');
                     if (annotation_tail_char == '' || get_text(1) == annotation_tail_char) {
                        save_pos(orig_pos);
                        orig_line = p_line;
                        up();
                        continue;
                     }
                  }
               }
               first_line = orig_line;
               start_line = orig_line;
               restore_pos(orig_pos);
               return(1);
            } else {
               found_comment=true;
               break;
            }
         }
      }
      if (!found_comment) {
         restore_pos(orig_pos);
         first_line = orig_line;
         start_line = orig_line;
         return(1);
      }
   }

   // Search for beginning of comments, stopping if at first non-comment line
   save_pos(auto end_of_comment);
   for (;;) {
      _last_non_blank('h');
      if (_clex_find(0,'g')!=CFG_COMMENT) {
         down();
         _begin_line();
         break;
      }
      _begin_line();
      _first_non_blank();
      if (_clex_find(0,'g')!=CFG_COMMENT) {
         down();
         _begin_line();
         break;
      }
      up();
      if (p_line<=1) {
         break;
      }
   }
   save_pos(auto non_comment_line);
   non_comment_line_number := p_line;

   // start over again, this time using a more simple search.
   restore_pos(end_of_comment);
   status := _clex_skip_blanks("h-");
   if (status) {
      top();
      _begin_line();
      _clex_find(COMMENT_CLEXFLAG,"O");
   } else {
      _end_line();  // Skip to end of line so we don't find comment after non-blank text.
      _clex_find(COMMENT_CLEXFLAG,"O");
   }
   first_line=p_line;

   // if the first technique stopped earlier, use that as the first line
   if (non_comment_line_number > first_line) {
      first_line = non_comment_line_number;
      restore_pos(non_comment_line);
      _end_line();  // Skip to end of line so we don't find comment after non-blank text.
      _clex_find(COMMENT_CLEXFLAG,"O");
      if (p_line >= orig_line) {
         // Bound the search forward - we don't want to find a comment
         // inside of the function we're getting the header comment for.
         restore_pos(non_comment_line);
         _begin_line();
      }
   }

   // Find end of comment
   status=_clex_skip_blanks("h");
   if (status) {
      bottom();
      _clex_find(COMMENT_CLEXFLAG,"-O");
      last_line=p_line;
   } else {
      last_line=p_line-1;
   }

   // If there is a javadoc comment,  Only return those lines
   p_line=last_line;
   typeless markid=_alloc_selection();
   _select_line(markid);
   p_line=first_line;_begin_line();
   _select_line(markid);
   typeless orig_markid=_duplicate_selection("");
   _show_selection(markid);
   _end_select(markid);
   status=search('^[ \t]*'_escape_re_chars(CODEHELP_JAVADOC_PREFIX)'([~*]|$)','-mrh@');
   if (!status) {
      first_line=p_line;
      status=search('^[ \t]*'_escape_re_chars(CODEHELP_JAVADOC_END_PREFIX)'([~*]|$)','mrh@');
      if (!status) {
         last_line=p_line;
      }
   }
   _show_selection(orig_markid);
   _free_selection(markid);
   slcomment_start := "";
   mlcomment_start := "";
   mlcomment_end := "";
   javadocSupported := false;
   if (!get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) && javadocSupported) {
      // Don't add del prefix
      p_line=last_line;down();
      for (;;) {
         up();
         get_line(line);
         if (p_line==0 ||
             substr(line,1,length(C_DEL_TAG_PREFIX))==C_DEL_TAG_PREFIX ||
             p_line<first_line
             ) {
            down();
            break;
         }
      }
      first_line=p_line;
      if (first_line>last_line) {
         restore_pos(orig_pos);
         return(1);
      }
   }

   restore_pos(orig_pos);
   return(0);
}

/** 
 * On entry, cursor is on line,column of tag symbol.
 * Finds the starting line and ending line for the tag's comments 
 * (below the current line) 
 *
 * @param first_line   (output) set to first line of comment
 * @param last_line    (output) set to last line of comment
 *
 * @return 0 if header comment found and first_line,last_line
 *         set.  Otherwise, 1 is returned.
 */
int _do_default_get_tag_header_comments_below(int &first_line,int &last_line)
{
   // skip blank lines after tag
   count := 1;
   save_pos(auto orig_pos);
   loop {
      if (down()) {
         restore_pos(orig_pos);
         return(1);
      }
      get_line(auto line);
      if (line!="" && count>10) {
         restore_pos(orig_pos);
         return(1);
      }
      _first_non_blank('h');
      if (_clex_find(0,'g')==CFG_COMMENT) {
         first_line=last_line=p_RLine;
         break;
      }
      ++count;
   }

   loop {
      if (down()) break;
      get_line(auto line);
      if (line == "") break;
      _first_non_blank('h');
      if (_clex_find(0,'g')!=CFG_COMMENT) {
         break;
      }
      last_line=p_RLine;
   }

   // that's all, restore position and return success
   restore_pos(orig_pos);
   return(0);
}

/**
 * Attempt to start function help window.  If function help is already active,
 * update the window, otherwise, call the _[ext]_fcthelp_get_start hook function
 * to get the start of the current function, then _[ext]_fcthelp_get to get/update
 * the function help information.
 *
 * @param OperatorTyped             Was an operator typed for auto-function help?
 * @param DisplayImmediate          Display the window immediately, or start timer?
 * @param cursorInsideArgumentList  Is the cursor inside an argument list?
 * @param tryReturnTypeMatching     Try to do list-members for matching return types
 *                                  if function help fails?
 *
 * @see _do_default_fcthelp_get_start
 * @see _do_default_fcthelp_get
 * @see _update_function_help
 */
void _do_function_help(bool OperatorTyped,
                       bool DisplayImmediate,
                       bool cursorInsideArgumentList=false,
                       bool tryReturnTypeMatching=false,
                       bool doMouseOverFunctionName=false,
                       int MouseOverCursorX=0,
                       int MouseOverPixelWidth=0,
                       int MouseOverLineNum=0,
                       int MouseOverCol=0,
                       typeless MouseOverPos=null,
                       _str streamMarkerMessage=null)
{
   if (!_haveContextTagging()) {
      return;
   }

   // IF we are in a recorded macro, just forget it
   if (_macro('r')) {
      // Too slow to display GUI
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      return;
   }
   //say("_do_function_help: ");
   if (ginFunctionHelp) {
      if (!gFunctionHelp_MouseOver && !doMouseOverFunctionName) {
         still_in_code_help();
      }
   }
   if (ginFunctionHelp) {
      if (gFunctionHelp_MouseOver && !doMouseOverFunctionName) {
         TerminateFunctionHelp(inOnDestroy:false);
      } else {
         return;
      }
   }
   typeless orig_pos;
   save_pos(orig_pos);
   _str errorArgs[];errorArgs._makeempty();
   FunctionNameOffset := 0;
   ArgumentStartOffset := 0;
   flags := 0;

   // is this embedded code?
   status := _Embeddedfcthelp_get_start(errorArgs,
                                        OperatorTyped,
                                        cursorInsideArgumentList,
                                        FunctionNameOffset,
                                        ArgumentStartOffset,
                                        flags, depth:1);

   // if not in an argument list, try again by moving after function name
   cursorIsOnFunctionName := !cursorInsideArgumentList;
   if (status == VSCODEHELPRC_NOT_IN_ARGUMENT_LIST && cursorInsideArgumentList) {
      restore_pos(orig_pos);
      function_name := cur_identifier(auto function_name_start_pos);
      if (function_name != "") {
         p_col = function_name_start_pos + length(function_name);
         if (get_text() :== ' ') right();
         right();
         status = _Embeddedfcthelp_get_start(errorArgs,
                                             OperatorTyped,
                                             cursorInsideArgumentList:false,
                                             FunctionNameOffset,
                                             ArgumentStartOffset,
                                             flags, depth:1);
         if (status == 0) {
            cursorIsOnFunctionName = true;
         }
         restore_pos(orig_pos);
      }
   }

   // maybe try return type matching for assignment statement
   if (status) {
      if (tryReturnTypeMatching) {
         restore_pos(orig_pos);
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         _do_list_members(OperatorTyped,
                          DisplayImmediate,
                          syntaxExpansionWords:null,
                          expected_type:null,
                          rt,
                          expected_name:null,
                          prefixMatch:false,
                          selectMatchingItem:false,
                          doListParameters:true, 
                          depth:1);
         return;
      }
      if (status && !OperatorTyped && !doMouseOverFunctionName) {
         msg := _CodeHelpRC(status,errorArgs);
         if (msg!="") {
            //_message_box(msg);
            message(msg);
         }
      }
      restore_pos(orig_pos);
      return;
   }

   // output some debugging stuff
   if (_chdebug) {
      say("_do_function_help: fnoffset="FunctionNameOffset" argstartofs="ArgumentStartOffset);
   }

   if (OperatorTyped) {
      flags |= VSAUTOCODEINFO_OPERATOR_TYPED;
   }
   goto_point(FunctionNameOffset);
   gFunctionHelp_OperatorTyped=OperatorTyped;
   gFunctionHelp_FirstCall=true;
   gFunctionHelp_InsertedParam=false;
   gFunctionHelp_ArgumentNameOffset=ArgumentStartOffset;
   gFunctionHelp_FunctionNameOffset=FunctionNameOffset;
   gFunctionHelp_FunctionLineOffset=(int)point();
   gFunctionHelp_starttext=get_text(ArgumentStartOffset-gFunctionHelp_FunctionLineOffset,gFunctionHelp_FunctionLineOffset);
   gFunctionHelp_flags=flags;
   gFunctionHelpTagIndex=MAXINT;
   restore_pos(orig_pos);
   gFunctionHelp_MouseOver=doMouseOverFunctionName;
   gFunctionHelp_OnFunctionName=cursorIsOnFunctionName;
   if (gFunctionHelp_MouseOver) {
      gFunctionHelp_MouseOverInfo.wid=p_window_id;
      gFunctionHelp_MouseOverInfo.x=0;gFunctionHelp_MouseOverInfo.y=0;
      //_lxy2dxy(SM_TWIP,x,y);
      //say("p_parent="p_parent);
      //say("_mdi="_mdi);
      _map_xy(p_window_id,0,gFunctionHelp_MouseOverInfo.x,gFunctionHelp_MouseOverInfo.y);
      gFunctionHelp_MouseOverInfo.x+=MouseOverCursorX;
      gFunctionHelp_MouseOverInfo.y+=p_cursor_y;
      gFunctionHelp_MouseOverInfo.width=MouseOverPixelWidth;
      gFunctionHelp_MouseOverInfo.height=p_font_height;
      //say("got here x="x" y="y);
      gFunctionHelp_MouseOverInfo.buf_id=p_buf_id;
      gFunctionHelp_MouseOverInfo.LineNum=MouseOverLineNum;
      gFunctionHelp_MouseOverInfo.col=MouseOverCol;
      gFunctionHelp_MouseOverInfo.ScrollInfo=_scroll_page();
      gFunctionHelp_MouseOverInfo.streamMarkerMessage = streamMarkerMessage;

      save_pos(gFunctionHelp_MouseOverInfo.OrigPos);
   }

   geditorctl_wid=p_window_id;
   geditorctl_buf_id=p_buf_id;
   p_ModifyFlags&=~MODIFYFLAG_FCTHELP_UPDATED;

   gFunctionHelp_list._makeempty();
   //DisplayImmediate=true;

   gFunctionHelp_form_wid=0;
   ginFunctionHelp=true;
   if (!DisplayImmediate && (def_codehelp_idle || gFunctionHelp_MouseOver)) {
      gFunctionHelp_pending=true;
   } else {
      _UpdateContext(AlwaysUpdate:true);
      _update_function_help(tryReturnTypeMatching && !cursorIsOnFunctionName);
      gFunctionHelp_InsertedParam=false;
      if (gFunctionHelp_OperatorTyped && ginFunctionHelp && !gFunctionHelp_pending && !cursorIsOnFunctionName) {
         insert_space   := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN);
         insert_keyword := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS);
         if (p_col > 1 && insert_space) {
            left();
            if (get_text()!="(") insert_space=false;
            right();
         }
         gFunctionHelp_InsertedParam=maybe_insert_current_param(do_select:true, check_if_defined:true, insert_space, insert_keyword);
      }
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          !gFunctionHelp_MouseOver && 
          tryReturnTypeMatching && !cursorIsOnFunctionName &&
          (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS)) {
         maybe_list_arguments(DisplayImmediate);
         if (gFunctionHelp_InsertedParam) {
            maybe_uninsert_current_param();
         }
      }
   }
}

/**
 * Is the function parameter help dialog up?
 *
 * @return <code>true</code> if the function help dialog is active,
 *         <code>false</code> otherwise
 */
bool ParameterHelpActive()
{
   if (!ginFunctionHelp) return false;
   if (!_iswindow_valid(gFunctionHelp_form_wid)) return false;
   return true;
}

/**
 * @return Return the window ID for the functino parameter help 
 *         window.  Return 0 if function help is not active.
 */
int ParameterHelpFormWid()
{
   if (!ginFunctionHelp) return 0;
   if (!_iswindow_valid(gFunctionHelp_form_wid)) return 0;
   return gFunctionHelp_form_wid;
}

void ParameterHelpSetSelectedSymbol(struct VS_TAG_BROWSE_INFO cm)
{
   gFunctionHelp_selected_symbol = cm;
}

void TerminateFunctionHelp(bool inOnDestroy, bool alsoTerminateAutoComplete=true)
{
   if (ginFunctionHelp) {
      if (_iswindow_valid(gFunctionHelp_form_wid)) {
         if (gFunctionHelp_InsertedParam && 
             _iswindow_valid(geditorctl_wid) &&
             geditorctl_wid.select_active() &&
             (geditorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
            _macro_call("maybe_delete_selection");
            geditorctl_wid.maybe_delete_selection();
            gFunctionHelp_InsertedParam=false;
         }
         if (!inOnDestroy) {
            gFunctionHelp_form_wid._delete_window();
         }
      }
      gFunctionHelp_form_wid=0;
      ginFunctionHelp=false;
      // Shouldn't need to reinitialize gFunctionHelp_MouseOver, but since
      // the ALM bug (immediately going away) was hard to reproduce let's make
      // sure we reset it.
      gFunctionHelp_MouseOver=false;
      gFunctionHelp_OnFunctionName=false;
      gFunctionHelp_selected_symbol=null;
      gFunctionHelp_ArgumentNameOffset=0;
      gFunctionHelp_FunctionNameOffset=0;
      gFunctionHelp_FunctionLineOffset=0;
      if (_iswindow_valid(geditorctl_wid) &&
          geditorctl_wid._isEditorCtl()) {
         geditorctl_wid._RemoveEventtab(defeventtab codehelp_key_overrides);
         geditorctl_wid=0;
      }
   }
   if (alsoTerminateAutoComplete) {
      AutoCompleteTerminate();
   }
}

/**
 * General purpose function for modifying the event tab
 * to the current control.  This is used by codehelp to
 * change the event tab for the editor when list-members
 * or function help is visible.
 *
 * @param add_eventtab_index  index of event tab from name table
 */
void _AddEventtab(int add_eventtab_index)
{
   count := 0;
   int etab_index=p_eventtab;
   found := false;
   for (;count<20;++count) {
      if (!etab_index) {
         break;
      }
      if (etab_index==add_eventtab_index) {
         found=true;
         break;
      }
      etab_index=eventtab_inherit(etab_index);
   }
   if (!found) {
      etab_index=p_eventtab;
      p_eventtab=add_eventtab_index;
      eventtab_inherit(add_eventtab_index,etab_index);
   }
   //say("add "name_name(p_eventtab));
}
/**
 * General purpose function for replacing the original event tab
 * to the current control.  This is used by codehelp to change
 * the event tab for the editor when list-members or function help
 * is visible.
 *
 * @param add_eventtab_index  index of event tab from name table
 */
void _RemoveEventtab(int add_eventtab_index)
{
   count := 0;
   prev_eventtab_index := 0;
   int etab_index=p_eventtab;
   found := false;
   for (;count<20;++count) {
      if (!etab_index) {
         break;
      }
      if (etab_index==add_eventtab_index) {
         found=true;
         break;
      }
      prev_eventtab_index=etab_index;
      etab_index=eventtab_inherit(etab_index);
   }
   if (!found) {
      return;
   }
   if (prev_eventtab_index) {
      eventtab_inherit(prev_eventtab_index,eventtab_inherit(add_eventtab_index));
   } else {
      p_eventtab=eventtab_inherit(add_eventtab_index);
   }
   eventtab_inherit(add_eventtab_index,0);
   //say("remove "name_name(p_eventtab));
}

/**
 * Returns the current word under the cursor, as seen by
 * function help in order to find related topic in online help.
 *
 * @param allHelpWorkDone  finished?
 *
 * @return current help topic, as seen by function help
 */
_str _CodeHelpCurWord(bool &allHelpWorkDone)
{
   //say("_CodeHelpCurWord: ");
   allHelpWorkDone=false;
   if (!ginFunctionHelp || gFunctionHelp_FirstCall) {
      return("");
   }
   return(gFunctionHelp_HelpWord);
}
/**
 * @return
 * Returns the tag information for the first tag currently displayed
 * by function help.  [ignoring hypertext links]
 */
_str _FunctionHelpTagInfo()
{
   if (!ginFunctionHelp || gFunctionHelp_FirstCall) {
      return("");
   }
   i := gFunctionHelpTagIndex;
   n := gFunctionHelp_list._length();
   if (i<0 || i>=n) {
      return("");
   }
   if (gFunctionHelp_list[i].tagList._length() <= 0) {
      return("");
   }
   tagInfo := gFunctionHelp_list[i].tagList[0].taginfo;
   if (length(tagInfo) > 0) return tagInfo;
   if (gFunctionHelp_list[i].tagList[0].browse_info != null) {
      return tag_compose_tag_browse_info(gFunctionHelp_list[i].tagList[0].browse_info);
   }
   return "";
}
/**
 * Update the function help window.  Calls _[ext]_fcthelp_get
 * to get the function help and current parameter number, etc,
 * and displays form with the current parameter bolded.
 *
 * @param tryReturnTypeMatching   If function help fails, try to
 *                                to list members using return type
 *                                matching.
 */
void _update_function_help(bool tryReturnTypeMatching=false)
{
   if (!_haveContextTagging()) {
      return;
   }

   doNotify := !gFunctionHelp_MouseOver && !gFunctionHelp_form_wid;

   if ((p_ModifyFlags & MODIFYFLAG_FCTHELP_UPDATED) &&
       gFunctionHelp_UpdateLineNumber==p_line &&
       gFunctionHelp_UpdateLineCol==p_col
       ) {
      return;
   }
   
   VSAUTOCODE_ARG_INFO curTag_arg_info;
   curTag_arg_info_set := false;
   if (gFunctionHelpTagIndex<gFunctionHelp_list._length()) {
      curTag_arg_info=gFunctionHelp_list[gFunctionHelpTagIndex];
      curTag_arg_info_set=true;
   }
   /*
       (clark) I wrapped _Embeddedfcthelp_get with save_pos/restore_pos because we hit a case when in
       Line Hex mode (should happend in regular mode too) where typing '(' causes the screen to
       scroll.  This totally screws up "Show info for mouse under cursor".
   */
   sc.lang.ScopedTimeoutGuard timeout;
   if (gFunctionHelp_OperatorTyped) {
      _SetTimeout(def_tag_max_list_matches_time);
   }

   VS_TAG_RETURN_TYPE visited:[];
   _str errorArgs[];errorArgs._makeempty();
   save_pos(auto p);
   FunctionHelp_list_changed := false;
   if (gFunctionHelp_OnFunctionName && 
       point('s') >= gFunctionHelp_FunctionNameOffset &&
       point('s') <= gFunctionHelp_ArgumentNameOffset) {
      goto_point(gFunctionHelp_ArgumentNameOffset);
   }
   status := _Embeddedfcthelp_get(errorArgs,
                                  gFunctionHelp_list,
                                  FunctionHelp_list_changed,
                                  gFunctionHelp_cursor_x,
                                  gFunctionHelp_HelpWord,
                                  gFunctionHelp_FunctionNameOffset,
                                  gFunctionHelp_flags,
                                  symbol_info:null, 
                                  visited, depth:1);
   restore_pos(p);
   if (status) {
      if (gFunctionHelp_OperatorTyped && _CheckTimeout()) {
         status = VSCODEHELPRC_FUNCTION_HELP_TIMEOUT;
      }
      if (tryReturnTypeMatching &&
          !gFunctionHelp_OperatorTyped && gFunctionHelp_FirstCall) {
         TerminateFunctionHelp(inOnDestroy:false);
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         _do_list_members(OperatorTyped:false,
                          DisplayImmediate:true,
                          syntaxExpansionWords:null,
                          expected_type:null,
                          rt,
                          expected_name:null,
                          prefixMatch:false,
                          selectMatchingItem:false,
                          doListParameters:true,
                          isFirstAttempt:true, 
                          visited, depth:1);
      }
      if (!gFunctionHelp_OperatorTyped && !gFunctionHelp_MouseOver  &&
          (gFunctionHelp_FirstCall|| status!=VSCODEHELPRC_NOT_IN_ARGUMENT_LIST)) {
         msg := _CodeHelpRC(status,errorArgs);
         if (msg!="") {
            message(msg);
         }
      }

      if (ginFunctionHelp && 
          !gFunctionHelp_pending && 
          gFunctionHelp_OperatorTyped &&
          !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN) &&
          get_text(1, (int)point('s')-1) == ")" && 
          get_text(1, (int)point('s')-2) != " " &&
          _clex_find(0,'g') !- CFG_STRING &&
          _clex_find(0,'g') !- CFG_COMMENT) {

         // we are in auto-function help, and they may have jumped out using TAB OR ENTER
         // before we were able to patch in the padding space before the close paren
         if (last_event(null,true) == ENTER || last_event(null, true) == TAB) {
            _macro_call("left");
            _macro_call("_insert_text"," ");
            _macro_call("right");
            left();
            _insert_text(" ");
            right();
         }
      }

      TerminateFunctionHelp(inOnDestroy:false);
      return;
   }
   gFunctionHelp_FirstCall=false;
   if (!gFunctionHelp_form_wid) {
      gFunctionHelp_form_wid=geditorctl_wid.show("-hidden -nocenter -new _function_help_form", geditorctl_wid, 0);
      FunctionHelp_list_changed=true;
   }
   p_ModifyFlags|=MODIFYFLAG_FCTHELP_UPDATED;
   gFunctionHelp_UpdateLineNumber=p_line;
   gFunctionHelp_UpdateLineCol=p_col;

   if (!FunctionHelp_list_changed &&
       gFunctionHelp_cursor_y >= geditorctl_wid.p_cursor_y &&
       gFunctionHelp_form_wid.p_visible ) {
      return;
   }
   if (gFunctionHelpTagIndex>=gFunctionHelp_list._length()) {
      gFunctionHelpTagIndex=0;

      // select the overload which was most recently inserted using auto-complete
      if (gFunctionHelp_selected_symbol != null) {
         for (i:=gFunctionHelp_list._length()-1; i>=0; --i) {
            for (j:=0; j<gFunctionHelp_list[i].tagList._length(); j++) {
               if ( !_file_eq(gFunctionHelp_selected_symbol.file_name, gFunctionHelp_list[i].tagList[j].filename) ||
                    gFunctionHelp_selected_symbol.line_no != gFunctionHelp_list[i].tagList[j].linenum ) {
                  continue;
               }
               cm := gFunctionHelp_list[i].tagList[j].browse_info;
               if (cm == null) {
                  tag_decompose_tag_browse_info(gFunctionHelp_list[i].tagList[j].taginfo, cm);
               }
               if ( gFunctionHelp_selected_symbol.member_name != cm.member_name ||
                    gFunctionHelp_selected_symbol.class_name  != cm.class_name ) {
                  continue;
               }
               gFunctionHelpTagIndex = i;
               break;
            }
            if (gFunctionHelpTagIndex > 0) break;
         }
      }

   } else {

      if (curTag_arg_info_set) {
         if (gFunctionHelpTagIndex<gFunctionHelp_list._length() &&
             curTag_arg_info.prototype==gFunctionHelp_list[gFunctionHelpTagIndex].prototype
             ) {
            curTag_arg_info_set=true;
         } else {
            curTag_arg_info_set=false;
            int i;
            for (i=0;i<gFunctionHelp_list._length();++i) {
               if (curTag_arg_info.prototype==gFunctionHelp_list[i].prototype) {
                  gFunctionHelpTagIndex=i;
                  curTag_arg_info_set=true;
                  break;
               }
            }
         }
      }
      if (!curTag_arg_info_set) {
         gFunctionHelpTagIndex=0;
      }
   }
   //say(!FunctionHelp_list_changed" "(ParamNum==gFunctionHelp_ParamNum)" "(gFunctionHelp_cursor_y>=geditorctl_wid.p_cursor_y)" "gFunctionHelp_form_wid.p_visible);
   new_cursor_y := geditorctl_wid.p_cursor_y;
   if (!FunctionHelp_list_changed /*&& ParamNum!=gFunctionHelp_ParamNum */&&
       gFunctionHelp_cursor_y>=geditorctl_wid.p_cursor_y) {
      new_cursor_y=gFunctionHelp_cursor_y;
   }
   //gFunctionHelp_ParamNum=ParamNum;
   //say(FunctionHelp_list_changed" pn="ParamNum" "gFunctionHelp_ParamNum" y="gFunctionHelp_cursor_y" "geditorctl_wid.p_cursor_y);
   geditorctl_wid._AddEventtab(defeventtab codehelp_key_overrides);
   gFunctionHelp_cursor_y=new_cursor_y;

   // make sure that function help is displayed
   ShowCommentHelp(true, false, gFunctionHelp_form_wid, geditorctl_wid, do_not_move_form:false, visited);

   // display feature notification that function help was displayed
   if (doNotify) {
      notifyUserOfFeatureUse(NF_AUTO_DISPLAY_PARAM_INFO);

      // if there are overloads, create the message for what hitting 
      // function_argument_help again will do
      if (gFunctionHelp_list._length() > 1) {
         fcthelp_key := _where_is("function_argument_help");
         if (fcthelp_key != "") fcthelp_key :+= " or"
         fcthelp_msg := "Press "fcthelp_key" Ctrl+PgDn to cycle to next function overload.";
         message(fcthelp_msg);
      }
   }
}

static void nextFunctionHelpPage(int inc,bool doFunctionHelp=true)
{
   VSAUTOCODE_ARG_INFO (*plist)[];
   _nocheck _control ctlminihtml2;
   form_wid := gFunctionHelp_form_wid;
   if (!_iswindow_valid(form_wid)) {
      return;
   }
   _str key;
   if (inc==4) {
      key=RIGHT;
   } else if (inc==-4) {
      key=LEFT;
   } else if (inc==3) {
      key=UP;
   } else if (inc==-3) {
      key=DOWN;
   } else if (inc==2) {
      key=HOME;
   } else if (inc==-2) {
      key=END;
   } else if (inc>0) {
      key=PGDN;
   } else if (inc<0) {
      key=PGUP;
   } else {
      key=TAB;
   }
   int wid=form_wid.ctlminihtml2;
   if (wid) {
      wid.call_event(wid,key,'W');
   }
}
// returns 0 if there were not overloaded tags to cycle through
// otherwise, return 'inc' on success.
static int nextFunctionHelp(int inc, bool doFunctionHelp=true, int form_wid=0)
{
   if (!_haveContextTagging()) {
      return 0;
   }

   // find the function help form window, unless one was passed in.
   VSAUTOCODE_ARG_INFO (*plist)[];
   _nocheck _control ctlminihtml1;
   if (doFunctionHelp) {
      form_wid=gFunctionHelp_form_wid;
   }
   if (!_iswindow_valid(form_wid)) {
      return 0;
   }

   // find the index of the current item selected
   TagIndex := 0;
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA();
   if (stack.HyperTextTop>=0) {
      TagIndex=stack.s[stack.HyperTextTop].TagIndex;
      plist= &stack.s[stack.HyperTextTop].TagList;
   } else {
      if (doFunctionHelp) {
         plist= &gFunctionHelp_list;
         form_wid=gFunctionHelp_form_wid;
         TagIndex=gFunctionHelpTagIndex;
      }
   }

   // determine if we will need to restart list-members or list-parameters
   restart_list_members    := false;
   restart_list_parameters := false;
   if (doFunctionHelp) {
      last_event_was_alt_dot   := (last_event() == name2event("A-.") || last_event() == name2event("C- "));
      last_event_was_alt_comma := (last_event() == name2event("A-,") || last_event() == name2event("A-M-,") || last_event() == name2event("M-,"));
      restart_list_members    = last_event_was_alt_dot || last_event_was_alt_comma || AutoCompleteActive();
      restart_list_parameters = last_event_was_alt_comma || AutoCompleteDoRestartListParameters();
   }

   // adjust index to advance to next prototype to display
   orig_TagIndex := TagIndex;
   TagIndex += inc;
   if (TagIndex<0 && plist->_length() > 0) {
      TagIndex=plist->_length()-1;
   } else if (TagIndex>=plist->_length()) {
      TagIndex=0;
   }

   // update the comment help if this is a different form.
   if (TagIndex!=orig_TagIndex) {
      if (stack.HyperTextTop>=0) {
         stack.s[stack.HyperTextTop].TagIndex=TagIndex;
         form_wid.HYPERTEXTSTACKDATA(stack);
      } else {
         gFunctionHelpTagIndex=TagIndex;
      }
      orig_height := form_wid.p_height;
      ShowCommentHelp(doFunctionHelp, false, form_wid, geditorctl_wid, true);
      if (_iswindow_valid(form_wid) && form_wid.p_height != orig_height) {
         restart_list_members = true;
         restart_list_parameters = AutoCompleteDoRestartListParameters();
      }
   }

   // restart list members and/or list compatibible values if necessary
   if (restart_list_members) {
      // obtain the expected parameter type
      int i=gFunctionHelpTagIndex;
      n := gFunctionHelp_list._length();
      if (i>=0 && i<n) {
         arglist_type := get_arg_info_type_name(gFunctionHelp_list[i]);
         _str expected_type=null;
         _str expected_name=null;
         if (restart_list_parameters) {
            expected_type=gFunctionHelp_list[i].ParamType;
            expected_name=gFunctionHelp_list[i].ParamName;
         }

         if (expected_type == null || expected_type == "" || arglist_type != "define") {
            AutoCompleteTerminate();
            geditorctl_wid._do_list_members(OperatorTyped:false,
                                            DisplayImmediate:true,
                                            syntaxExpansionWords:null,
                                            expected_type,
                                            rt:null,
                                            expected_name,
                                            prefixMatch:false,
                                            selectMatchingItem:true,
                                            doListParameters:true);

         }
      }
   }

   // that's all folks
   return (TagIndex!=orig_TagIndex)? inc:0;
}

// jump to the tag currently displayed by function argument help
// or by list-members comment help.
//
static int gotoFunctionTag(bool doFunctionHelp, int form_wid, int editorctl_wid)
{
   // find the index of the current item selected
   _nocheck _control ctlminihtml1;
   TagIndex := 0;
   VSAUTOCODE_ARG_INFO (*plist)[] = null;
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA();
   if (stack.HyperTextTop>=0) {
      TagIndex =stack.s[stack.HyperTextTop].TagIndex;
      plist = &stack.s[stack.HyperTextTop].TagList;
   } else {
      if (doFunctionHelp) {
         plist = &gFunctionHelp_list;
         form_wid = gFunctionHelp_form_wid;
         TagIndex = gFunctionHelpTagIndex;
      }
   }
   if (plist == null) {
      return STRING_NOT_FOUND_RC;
   }
   if (TagIndex < 0 || TagIndex >= plist->_length()) {
      return STRING_NOT_FOUND_RC;
   }

   // a get a pointer to the selected item
   VSAUTOCODE_ARG_INFO *pinfo = &plist->[TagIndex];
   if (pinfo->tagList._length() > 0) {

      // make sure we have a timeout set
      _SetTimeout(def_tag_max_list_members_time);
      tag_push_matches();

      // search for matches to each symbol overload
      tag_init_tag_browse_info(auto cm);
      
      // get the basic information about the symbol(s)
      have_tag_browse_info := false;
      foreach (auto tag_info in pinfo->tagList) {
         filename := tag_info.filename;
         linenum := tag_info.linenum;
         cm = tag_info.browse_info;
         if (cm == null) {
            taginfo := tag_info.taginfo;
            tag_decompose_tag_browse_info(taginfo, cm); 
         } else if (length(cm.member_name) > 0 && length(cm.file_name) > 0) {
            have_tag_browse_info = true;//!have_multiple_signatures;
         }
         if (length(cm.file_name) <= 0) {
            cm.file_name = filename;
         }
         if ( cm.line_no <= 0 ) {
            if ( linenum != null ) cm.line_no = linenum;
         }
         tag_insert_match_info(cm);
      }

      // compute a slightly flexible set of filters to search for
      filter_flags := tag_type_to_filter(cm.type_name,0);
      if (tag_tree_type_is_func(cm.type_name)) filter_flags |= SE_TAG_FILTER_ANY_PROCEDURE;
      if (tag_tree_type_is_data(cm.type_name)) filter_flags |= SE_TAG_FILTER_ANY_DATA;

      // now search for the matching symbol
      num_matches := 0;
      if (!have_tag_browse_info) {
         tag_files := tags_filenamea(editorctl_wid.p_LangId);
         editorctl_wid.tag_list_symbols_in_context(cm.member_name, cm.class_name, 
                                                   0, 0, 
                                                   tag_files, "",
                                                   num_matches, 
                                                   def_tag_max_function_help_protos,
                                                   filter_flags, 
                                                   SE_TAG_CONTEXT_ANYTHING,
                                                   true, true);
      }

      // remove any matches that do not match the original argument list
      // or that are not functions in the first place
      if (tag_tree_type_is_func(cm.type_name)) {
         VS_TAG_BROWSE_INFO matches[];
         for (j:=tag_get_num_of_matches(); j>0; --j) {
            tag_get_match_info(j, auto cmj);
            if (!tag_tree_type_is_func(cmj.type_name) ||
                tag_tree_compare_args(cm.arguments, cmj.arguments, true) == 0) {
               matches :+= cmj;
            }
         }
         tag_clear_matches();
         foreach (cm in matches) {
            tag_insert_match_info(cm);
         }
         num_matches = tag_get_num_of_matches();
      }

      // shut down code help
      TerminateFunctionHelp(inOnDestroy:false);
      _SetTimeout(0);

      // get the basic information about the symbol
      // remove duplicate symbols from the match set
      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false,
                                          filterDuplicateGlobalVars:false,
                                          filterDuplicateClasses:false,
                                          filterAllImports:true,
                                          filterDuplicateDefinitions:false,
                                          filterAllTagMatchesInContext:false);

      // symbol information for tag we will go to
      tag_init_tag_browse_info(cm);
      push_tag_reset_matches();

      // check if there is a preferred definition or declaration to jump to
      match_id := tag_check_for_preferred_symbol(_GetCodehelpFlags());
      if (match_id > 0) {
         // record the matches the user chose from
         tag_get_match_info(match_id, cm);
         push_tag_add_match(cm);
         for (i:=1; i<=tag_get_num_of_matches(); ++i) {
            if (i==match_id) continue;
            tag_get_match_info(i,auto im);
            push_tag_add_match(im);
         }
      } else {
         // present list of matches and go to the selected match
         status := tag_select_symbol_match(cm,true,_GetCodehelpFlags());
         if (status < 0) {
            tag_pop_matches();
            return status;
         }
      }

      // push a bookmark before navigating
      if (!(editorctl_wid.p_buf_flags & VSBUFFLAG_HIDDEN) && !beginsWith(editorctl_wid.p_buf_name,".process")) {
         editorctl_wid.push_bookmark();
      }

      // now go to the selected tag
      status := editorctl_wid.tag_edit_symbol(cm);
      tag_pop_matches();

      // set up push-tag circle items
      push_tag_reset_item();
      push_tag_index := find_index("push-tag",COMMAND_TYPE);
      if (push_tag_index > 0) {
         prev_index(push_tag_index, "C");
         last_index(push_tag_index, "C");
      }

      // that's all folks
      TerminateMouseOverHelp();
      return status;
   }

   // we did not have any symbol information
   return STRING_NOT_FOUND_RC;
}

static void _ElideParameterList(VSAUTOCODE_ARG_INFO &plist, int max_params)
{
   // calcualte the first parameter position shown
   static int first_param;
   int i,n=plist.arglength._length();
   if (max_params<=0) max_params=1;
   int num_added = (max_params*3 intdiv 4);
   if (plist.ParamNum < first_param) {
      first_param=plist.ParamNum-num_added;
   } else if (plist.ParamNum >= first_param+max_params) {
      if (!num_added) num_added=1;
      first_param=plist.ParamNum-max_params+num_added;
   }
   if (first_param<1) {
      first_param=1;
   } else if (first_param+max_params > n) {
      first_param=n-max_params;
   }

   // elide the parameters before the current param
   chars_elided := 0;
   if (first_param>1) {
      int start_pos = plist.argstart[1];
      int end_pos = plist.argstart[first_param-1]+plist.arglength[first_param-1];
      if (first_param < n) {
         end_pos = plist.argstart[first_param];
      }
      chars_elided = end_pos-start_pos-3;
      plist.prototype=substr(plist.prototype,1,start_pos-1) :+ "..." :+
                      substr(plist.prototype,end_pos);
      for (i=1; i<first_param; ++i) {
         plist.arglength[i]=3;
         plist.argstart[i]=start_pos;
      }
   }

   // adjust the start positions of the parameters within sliding window
   int last_param=first_param+max_params;
   if (chars_elided>0) {
      for (i=first_param; i<n; ++i) {
         plist.argstart[i] -= chars_elided;
         if (last_param<n && plist.argstart[i]+plist.arglength[i] > plist.argstart[last_param]) {
            plist.arglength[i] = plist.argstart[last_param] - plist.argstart[i];
         }
      }
   }

   // elide the other parameters
   if (n > first_param+max_params) {
      //plist.argstart[first_param+max_params] -= chars_elided;
      int end_pos = plist.argstart[first_param+max_params];
      plist.prototype = substr(plist.prototype,1,end_pos-1)"...";
      for (i=first_param+max_params; i<n; ++i) {
         plist.argstart[i]=end_pos;
         plist.arglength[i]=3;
      }
   }
}

int tag_find_class_parents(_str tag_files[], 
                           _str search_file_name,
                           _str class_name, 
                           bool case_sensitive,
                           int &num_matches,
                           int max_matches,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, 
                           int depth=0)
{
   // get the fully qualified parents of this class
   if (_chdebug) {
      isay(depth, "tag_find_class_parents H"__LINE__": class_name="class_name);
   }
   orig_tag_file := tag_current_db();
   parents := cb_get_normalized_inheritance(class_name, auto tag_dbs, tag_files, 
                                            check_context:true, "", search_file_name, "", 
                                            includeTemplateParameters:true, visited, depth+1);
   tag_clear_matches();

   // add each of them to the list also
   while (parents != "") {
      parse parents with auto cur_parent_class ";" parents;
      parse tag_dbs with auto cur_tag_file     ";" tag_dbs;

      // make the right tag file active, if we have one
      if (cur_tag_file != "") {
         status := tag_read_db(cur_tag_file);
         if (status < 0) {
            say("tag_find_class_parents H"__LINE__": tag file status="status);
            continue;
         }
      }

      // add transitively inherited class members
      tag_flags := (pos('<', cur_parent_class) > 0)? SE_TAG_FLAG_TEMPLATE : SE_TAG_FLAG_NULL;
      parse cur_parent_class with cur_parent_class "<" auto template_arguments ">";
      tag_split_class_name(cur_parent_class, auto class_name_only, auto outer_class_name);

      // now try to find the parent class
      if (_chdebug) {
         isay(depth, "tag_find_class_parents H"__LINE__": cur_parent_class="cur_parent_class);
      }
      if (outer_class_name != "") {
         tag_list_in_class(class_name_only, outer_class_name, 
                           0, 0, tag_files, 
                           num_matches, 1000,//max_matches, 
                           SE_TAG_FILTER_ANY_STRUCT,
                           SE_TAG_CONTEXT_ACCESS_PROTECTED|SE_TAG_CONTEXT_ALLOW_PROTECTED,
                           exact_match:true, case_sensitive, 
                           null, null, visited, depth+1);
      } else {
         tag_list_context_globals(tree_wid:0, tree_index:0, 
                                  class_name_only, 
                                  check_context: true,
                                  tag_files, 
                                  SE_TAG_FILTER_ANY_STRUCT,
                                  SE_TAG_CONTEXT_ACCESS_PROTECTED|SE_TAG_CONTEXT_ALLOW_PROTECTED,
                                  num_matches, max_matches,  
                                  exact_match:true, case_sensitive, 
                                  visited, depth+1);
      }
      if (_chdebug) {
         isay(depth, "tag_find_class_parents H"__LINE__": num_matches="num_matches);
      }
   }

   // return to the original tag file and return, successful
   tag_read_db(orig_tag_file);
   return 0;
}

int tag_find_function_parents(_str tag_files[], 
                              _str search_file_name,
                              _str lastid,
                              _str class_name, 
                              bool case_sensitive,
                              int &num_matches,
                              int max_matches,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, 
                              int depth=0)
{
   // get the fully qualified parents of this class
   if (_chdebug) {
      isay(depth, "tag_find_function_parents H"__LINE__": class_name="class_name);
   }
   orig_tag_file := tag_current_db();
   parents := cb_get_normalized_inheritance(class_name, auto tag_dbs, tag_files, 
                                            check_context:true, "", search_file_name, "", 
                                            includeTemplateParameters:true, visited, depth+1);
   tag_clear_matches();

   // add each of them to the list also
   while (parents != "") {
      parse parents with auto cur_parent_class ";" parents;
      parse tag_dbs with auto cur_tag_file     ";" tag_dbs;

      // make the right tag file active, if we have one
      if (cur_tag_file != "") {
         status := tag_read_db(cur_tag_file);
         if (status < 0) {
            continue;
         }
      }

      // add transitively inherited class members
      tag_flags := (pos('<', cur_parent_class) > 0)? SE_TAG_FLAG_TEMPLATE : SE_TAG_FLAG_NULL;
      parse cur_parent_class with cur_parent_class "<" auto template_arguments ">";

      // go get those constructors
      if (_chdebug) {
         isay(depth, "tag_find_function_parents H"__LINE__": cur_parent_class="cur_parent_class);
      }
      tag_list_in_class(lastid, cur_parent_class,
                        0, 0, tag_files, 
                        num_matches, max_matches, 
                        SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_PROPERTY,
                        SE_TAG_CONTEXT_ACCESS_PROTECTED|SE_TAG_CONTEXT_ALLOW_PROTECTED, 
                        /*exact_match*/true, case_sensitive, 
                        null, null, visited, depth+1);
      if (_chdebug) {
         isay(depth, "tag_find_function_parents H"__LINE__": num_matches="num_matches);
      }
   }

   // return to the original tag file and return, successful
   tag_read_db(orig_tag_file);
   return 0;
}

bool GetCommentInfoInherited(VS_TAG_BROWSE_INFO &cm, 
                             VSCodeHelpCommentFlags &comment_flags, 
                             _str &comment_info, 
                             VS_TAG_RETURN_TYPE (&visited):[]=null, 
                             int depth=0)
{
   // gone too far?
   if (depth > 32) {
      return false;
   }

   if (tag_tree_type_is_class(cm.type_name)) {

      // classes with parent classes
      if (cm.class_parents == null || cm.class_parents == "") {
         return false;
      }

      tag_files := tags_filenamea(cm.language);
      case_sensitive := (_isEditorCtl()? p_LangCaseSensitive : true);
      num_matches := 0;

      if (cm.qualified_name == "") {
         cm.qualified_name = tag_join_class_name(cm.member_name, cm.class_name, tag_files, case_sensitive, allow_anonymous:false, only_opaque:false, visited, depth+1);
      }

      tag_push_matches();
      tag_find_class_parents(tag_files, cm.file_name, cm.qualified_name, case_sensitive, num_matches, 10, visited, depth+1);

   } else if (tag_tree_type_is_func(cm.type_name) || cm.type_name == "prop" || (cm.flags & SE_TAG_FLAG_VIRTUAL)) {

      // if we didn't find anything, find and look up parent classes
      tag_files := tags_filenamea(cm.language);
      case_sensitive := (_isEditorCtl()? p_EmbeddedCaseSensitive : true);
      num_matches := 0;

      tag_push_matches();
      tag_find_function_parents(tag_files, cm.file_name, cm.member_name, cm.class_name, case_sensitive, num_matches, 10, visited, depth+1);

   } else {
      // not the sort of tag that can inherit anything
      return false;
   }

   // check if we found any matching inherited symbols
   num_matches := tag_get_num_of_matches();
   if (num_matches <= 0) {
      tag_pop_matches();
      return false;
   }

   // try to get inherited comment info from the tags we found
   all_comment_info := "";
   for (i:=1; i<=num_matches; ++i) {
      tag_get_match_browse_info(i, auto parent);
      parent_comment_info := "";
      parent_comment_flags := comment_flags;
      if (GetCommentInfoForSymbol(parent, parent_comment_flags, parent_comment_info, visited, depth+1)) {
         doc_comment_flags := (VSCODEHELP_COMMENTFLAG_JAVADOC|VSCODEHELP_COMMENTFLAG_XMLDOC|VSCODEHELP_COMMENTFLAG_DOXYGEN);
         if (!(comment_flags & doc_comment_flags) && (parent_comment_flags & doc_comment_flags)) {
            comment_flags = parent_comment_flags;
         }
         if (parent_comment_flags == comment_flags) {
            if (all_comment_info != "") {
               all_comment_info :+= "\n\n";
            }
            all_comment_info :+= parent_comment_info;
         }
      }
   }
   tag_pop_matches();

   // no comments found?
   if (all_comment_info == "") {
      return false;
   }

   inherit_pos := pos("{@inheritdoc}", comment_info,  1, 'i');
   if (inherit_pos <= 0) {
      inherit_pos = pos("<inheritdoc/>", comment_info,  1, 'i');
   }
   if (inherit_pos > 0) {
      inherit_len := pos('');
      comment_info = substr(comment_info, 1, inherit_pos-1) :+
                     all_comment_info :+
                     substr(comment_info, inherit_pos+inherit_len);
      return true;
   }

   comment_info = all_comment_info;
   return true;
}


/**
 * Verify that the documentation comment attached to this symbol can be used. 
 * If not, return 'false' to indicate that we need to extract the comment 
 * from the source code. 
 * 
 * @param cm               symbol information
 * @param comment_flags    (output) bitset of VSCODEHELP_COMMENTFLAG_*
 * @param comment_info     (output) comment text to process
 * 
 * @return 'true' if we can use the comment we have from tagging.
 */
bool GetCommentInfoForSymbol(VS_TAG_BROWSE_INFO &cm, 
                             VSCodeHelpCommentFlags &comment_flags, 
                             _str &comment_info, 
                             VS_TAG_RETURN_TYPE (&visited):[]=null, 
                             int depth=0)
{
   if (_chdebug) {
      tag_browse_info_dump(cm, "GetCommentInfoForSymbol: ", depth);
   }

   // filter out mutual recursion
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   current_cm := tag_compose_tag_browse_info(cm);
   current_buf := (_isEditorCtl()? p_buf_name : "");
   input_args := "GetCommentInfoForSymbol;":+current_cm:+";":+current_buf;
   if (visited._indexin(input_args)) {
      rt = visited:[input_args];
      if (!rt.istemplate) {
         return false;
      }
      comment_info = rt.taginfo;
      comment_flags = (VSCodeHelpCommentFlags) rt.line_number;
      return true;
   } else {
      // indicates we've been here, and found nothing
      visited:[input_args] = rt;
   }

   if (cm._length() >= 27 && cm.doc_comments != null) {
      switch (cm.doc_type) {
      case SE_TAG_DOCUMENTATION_JAVADOC:
         comment_flags = VSCODEHELP_COMMENTFLAG_JAVADOC;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_XMLDOC:
         comment_flags = VSCODEHELP_COMMENTFLAG_XMLDOC;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_DOXYGEN:
         comment_flags = VSCODEHELP_COMMENTFLAG_DOXYGEN;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_RAW_JAVADOC:
         comment_flags = VSCODEHELP_COMMENTFLAG_JAVADOC|VSCODEHELP_COMMENTFLAG_RAW;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_RAW_XMLDOC:
         comment_flags = VSCODEHELP_COMMENTFLAG_XMLDOC|VSCODEHELP_COMMENTFLAG_RAW;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_RAW_DOXYGEN:
         comment_flags = VSCODEHELP_COMMENTFLAG_DOXYGEN|VSCODEHELP_COMMENTFLAG_RAW;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_PLAIN_TEXT:
         comment_flags = VSCODEHELP_COMMENTFLAG_TEXT;
         comment_info = cm.doc_comments;
         break;
      case SE_TAG_DOCUMENTATION_FIXED_FONT_TEXT:
         comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
         comment_info = "<pre>" :+ cm.doc_comments :+ "</pre>";
         break;
      case SE_TAG_DOCUMENTATION_HTML:
         comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
         comment_info = cm.doc_comments;
         break;
      default:
         // handle negative case, this symbol just might not have any comments
         if (cm.flags & SE_TAG_FLAG_NO_COMMENT) {
            comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
            comment_info = "<p><i>No comments found</i></p>";
            found := GetCommentInfoInherited(cm, comment_flags, comment_info, visited, depth+1);
            if (found) {
               rt.isvariadic = true;
               rt.taginfo = comment_info;
               rt.line_number = comment_flags;
               visited:[input_args] = rt;
               return true;
            }
         }
         //say("GetCommentInfoForSymbol H"__LINE__": INVALID COMMENT TYPE, cm.doc_type="cm.doc_type);
         return false;
      }

      // if no file, this comment is the best comment we will ever find
      if (cm.file_name != null && cm.file_name != "" && file_exists(cm.file_name)) {
         // there is a newer version of this file, so we should extract comments
         if (cm._length() >= 28 && cm.tagged_date < _file_date(cm.file_name, 'B')) {
            //say("GetCommentInfoForSymbol H"__LINE__": FILE DATE IS OUT OF DATE");
            return false;
         }
         if (_chdebug) {
            isay(depth, "GetCommentInfoForSymbol H"__LINE__": USING COMMENT FROM TAG FILE");
         }
      }

      // check if we can inherit comments
      if (comment_info == "" || 
          pos("{@inheritdoc}", comment_info,  1, 'i') > 0 ||
          pos("<inheritdoc/>", comment_info,  1, 'i') > 0) {
         found := GetCommentInfoInherited(cm, comment_flags, comment_info, visited, depth+1);
         if (found) {
            rt.isvariadic = true;
            rt.taginfo = comment_info;
            rt.line_number = comment_flags;
            visited:[input_args] = rt;
            return true;
         }
      }
      rt.isvariadic = true;
      rt.taginfo = comment_info;
      rt.line_number = comment_flags;
      visited:[input_args] = rt;
      return true;
   }

   // no doc_comments here at all
   //isay(depth, "GetCommentInfoForSymbol H"__LINE__": NO DOC COMMENTS AT ALL");
   return false;

}

void ShowCommentHelp(bool doFunctionHelp=true, 
                     bool prefer_left_placement=false,
                     int form_wid=0, int editorctl_wid=0,
                     bool do_not_move_form=false,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, 
                     int depth=0)
{
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": IN");
   }
   TagIndex := 0;
   VSAUTOCODE_ARG_INFO (*plist)[] = null;
   _nocheck _control ctlminihtml1;
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA();
   if (stack.HyperTextTop>=0) {
      TagIndex=stack.s[stack.HyperTextTop].TagIndex;
      plist= &stack.s[stack.HyperTextTop].TagList;
   } else {
      if (doFunctionHelp) {
         plist= &gFunctionHelp_list;
         form_wid=gFunctionHelp_form_wid;
         TagIndex=gFunctionHelpTagIndex;
      }
   }
   if (plist == null) {
      if (_chdebug) {
         say("ShowCommentHelp H"__LINE__": NOTHING TO DISPLAY");
      }
      return;
   }

   // get the image based on the dialog font height
   _xlat_default_font(CFG_FUNCTION_HELP, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
   imageSize := getImageSizeForFontHeight(fontHeight);

   // and construct the prototype information in HTML
   text := margin_text := "";
   if (plist->_length()>1) {
      margin_text="<a href=\"<<f\" lbuttondown><img src=vslick://_f_arrow_lt.svg@"imageSize"></a> ":+
                  (TagIndex+1):+" of ":+plist->_length():+" ":+
                  "<a href=\">>f\" lbuttondown><img src=vslick://_f_arrow_gt.svg@"imageSize"></a> ";
   }
   if (stack.HyperTextTop>0) {
      if (stack.HyperTextMaxTop>stack.HyperTextTop) {
         margin_text="<a href=\"<<back\" lbuttondown>Back</a> <a href=\"<<forward\" lbuttondown>Forward</a>&nbsp;":+margin_text;
      } else {
         margin_text="<a href=\"<<back\" lbuttondown>Back</a> ":+margin_text;
      }
   } else if (stack.HyperTextTop==0 && stack.HyperTextMaxTop>stack.HyperTextTop) {
      margin_text="<a href=\"<<forward\" lbuttondown>Forward</a>&nbsp;":+margin_text;
   }
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": margin_text="margin_text);
   }
   // add push tag bmp (checks later to see if there is a filename to go to)
   pushtag_text := "<a href=\"<<pushtag\" lbuttondown><img src=vslick://_f_arrow_into.svg@"imageSize"></a>&nbsp;";
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": pushtag_text="pushtag_text);
   }

   // Standard and Community edition can't do this
   if (!_haveContextTagging()) {
      pushtag_text = "";
      margin_text = "";
   }

   // Encode bold and italic args
   i := TagIndex;
   if (i<0 || i>=plist->_length()) {
      return;
   }
   jcount := plist->[i].argstart._length();
   ParamNum := plist->[i].ParamNum;
   if (ParamNum>=jcount && jcount > 0 &&
       substr(plist->[i].prototype,
              plist->[i].argstart[jcount-1],
              plist->[i].arglength[jcount-1])=="...") {
      ParamNum=jcount-1;
   }
   if (jcount >= (def_codehelp_max_params*3 intdiv 2)) {
      _ElideParameterList(plist->[i],def_codehelp_max_params);
   }
   prototype := "";
   hr_prototype := plist->[i].prototype;
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": hr_prototype="hr_prototype);
   }
   while (hr_prototype != "") {
      parse hr_prototype with auto part "<hr>" hr_prototype;
      escape_prototype := true;
      if (pos("<b>", part) > 0 && pos("</b>", part) > 0) escape_prototype = false;
      else if (pos("<u>", part) > 0 && pos("</u>", part) > 0) escape_prototype = false;
      else if (pos("<a ", part) > 0 && pos("</a>", part) > 0) escape_prototype = false;
      else if (pos("<em>", part) > 0 && pos("</em>", part) > 0) escape_prototype = false;
      else if (pos("<code>", part) > 0 && pos("</code>", part) > 0) escape_prototype = false;
      else if (pos("<h1>", part) > 0 && pos("</h1>", part) > 0) escape_prototype = false;
      else if (pos("<h2>", part) > 0 && pos("</h2>", part) > 0) escape_prototype = false;
      else if (pos("<h3>", part) > 0 && pos("</h3>", part) > 0) escape_prototype = false;
      else if (pos("<h4>", part) > 0 && pos("</h4>", part) > 0) escape_prototype = false;
      if (escape_prototype) {
         part = stranslate(part,"\4","<br>");
         part = stranslate(part,"\5","<hr>");
         part = translate(part,"\1\2\3","<&>");
      }
      _maybe_append(prototype, "<hr>");
      prototype :+= part;
   }
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": prototype="prototype);
   }

   if (ParamNum<0 || ParamNum>=jcount || gFunctionHelp_MouseOver) {
      text :+= prototype:+"\n";
   } else {
      html_color := cfg_color_to_html_color(CFG_NAVHINT);
      start := plist->[i].argstart[ParamNum];
      len   := plist->[i].arglength[ParamNum];
      text :+= substr(prototype,1,start-1);
      text :+= "<b><font color=\"#"html_color"\">";
      text :+= substr(prototype,start,len);
      text :+= "</font></b>";
      text :+= substr(prototype,start+len);
      text :+= "\n</pre>";
   }
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": text="text);
   }

   have_filename := false;
   if (plist->[i].tagList._length() > 0) {
      if (plist->[i].tagList[0].filename != null && length(plist->[i].tagList[0].filename) > 0) {
         have_filename = true;
      } else if (plist->[i].tagList[0].browse_info != null && length(plist->[i].tagList[0].browse_info.file_name) > 0) {
         have_filename = true;
      }
   }
   if (have_filename) {
      margin_text :+= pushtag_text;
   }
   
   text=stranslate(text,"<hr>","\5");
   text=stranslate(text,"<br>","\4");
   text=stranslate(text,"&gt;","\3");
   text=stranslate(text,"&amp;","\2");
   text=stranslate(text,"&lt;","\1");
   doMouseOver := doFunctionHelp && gFunctionHelp_MouseOver;
   //text='<pre><font size=+0>
   //_message_box("text="text);
   _nocheck _control picture1;
   html_comments   := "";
   VS_TAG_BROWSE_INFO first_cm;
   tag_browse_info_init(first_cm);
   cur_param_name  := "";
   if ((doFunctionHelp && !doMouseOver && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS)) ||
       (!doFunctionHelp && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS)) ||
       (doMouseOver && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS))) {

      VSAUTOCODE_ARG_INFO *pinfo;
      pinfo=&plist->[TagIndex];
      if (TagIndex<plist->_length() && pinfo->tagList!=null) {
         //_message_box(" h1 len="pinfo->tagList._length());
         retrieved_data := false;
         if (pinfo->tagList._length()>0) {
            first_cm.file_name = pinfo->tagList[0].filename;
            first_cm.line_no   = pinfo->tagList[0].linenum;
            if (pinfo->tagList[0].browse_info != null) {
               first_cm = pinfo->tagList[0].browse_info;
            } else if (pinfo->tagList[0].taginfo != null) {
               parse pinfo->tagList[0].taginfo with first_cm.member_name "(";
            }
         }
         have_slickc_value := false;
         for (i=0;i<pinfo->tagList._length();++i) {
            //_message_box("i="i" h1 len="pinfo->tagList._length());
            // If we have not fetched the comments yet
            if (_haveContextTagging()) {
               cm := pinfo->tagList[i].browse_info;
               if (cm != null && GetCommentInfoForSymbol(cm, pinfo->tagList[i].comment_flags, pinfo->tagList[i].comments, visited, depth+1)) {
                  // No need for extracting comment from source, we already have it.
               } else if (pinfo->tagList[i].comments==null) {
                  retrieved_data=true;
                  if (cm == null) {
                     tag_decompose_tag_browse_info(pinfo->tagList[i].taginfo, cm);
                  }
                  tag_database := null;
                  if (pinfo->tagList[i].browse_info != null) {
                     tag_database = pinfo->tagList[i].browse_info.tag_database;
                  }
                  editorctl_wid._ExtractTagComments2(pinfo->tagList[i].comment_flags,
                                                     pinfo->tagList[i].comments,
                                                     2000,
                                                     cm.member_name,
                                                     pinfo->tagList[i].filename,
                                                     pinfo->tagList[i].linenum,
                                                     cm.class_name,
                                                     cm.type_name,
                                                     tag_database,
                                                     visited, depth+1);
                  //pinfo->tagList[i].comments="test comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\n";pinfo->tagList[i].comment_flags=0;
               }
            }
            comments := pinfo->tagList[i].comments;
            comment_flags := pinfo->tagList[i].comment_flags;
            comments_are_unique := true;
            for (j:=0; j<i;++j) {
               if (pinfo->tagList[j].comments==comments) {
                  comments_are_unique=false;
                  break;
               }
            }
            if (comments!="" && comments_are_unique) {
               if (html_comments!="") {
                  strappend(html_comments,"<hr>");
               }
               if (!(comment_flags & VSCODEHELP_COMMENTFLAG_HTML)) {
                  _make_html_comments(comments,
                                      pinfo->tagList[i].comment_flags,
                                      "" /*return_type*/,
                                      pinfo->ParamName,
                                      editorctl_wid.p_LangId=="e" || editorctl_wid.p_LangId=="c",
                                      editorctl_wid.p_LangId);
               }
               cur_param_name=pinfo->ParamName;
               strappend(html_comments,comments);
            }
            if (!have_slickc_value && editorctl_wid._LanguageInheritsFrom("e") && _haveDebugging()) {
               var_index := find_index(first_cm.member_name, VAR_TYPE|GVAR_TYPE);
               if (var_index) {
                  typeless v=_get_var(var_index);
                  if (v._varformat()==VF_EMPTY) v="(null)";
                  if (VF_IS_INT(v) || v._varformat()==VF_LSTR) {
                     if (!isinteger(v)) v = _quote(v);
                     html_comments :+= "<B>Value:&nbsp;&nbsp;<code>":+v:+"</code></b>";
                     have_slickc_value = true;
                  }
               }
            }
         }
         if (retrieved_data) {
            if (stack.HyperTextTop>0) {
               form_wid.HYPERTEXTSTACKDATA(stack);
            }
         }
      }
   }
   vx := vy := vwidth := vheight := 0;
   text_x := editorctl_wid.p_cursor_x;
   text_y := editorctl_wid.p_cursor_y;
   _map_xy(editorctl_wid,0,text_x,text_y);
   _GetVisibleScreenFromPoint(text_x,text_y,vx,vy,vwidth,vheight);
   if (doFunctionHelp) {
      avail_width := vwidth*_twips_per_pixel_x();
      if (avail_width > 18000) {
         // lots of space, don't occupy more the 2/3 of screen
         avail_width=(avail_width*2 intdiv 3);
      } else if (avail_width > 12000) {
         // not tons of space, but don't use more than 12000 twips
         avail_width=12000;
      }
      if (gFunctionHelp_MouseOverInfo != null &&
          gFunctionHelp_MouseOverInfo.streamMarkerMessage != null &&
          gFunctionHelp_MouseOverInfo.streamMarkerMessage != "") {
         markerText := gFunctionHelp_MouseOverInfo.streamMarkerMessage;
         _escape_html_chars(markerText);
         if (html_comments != "") {
            markerText :+= "<hr>";
         }
         html_comments = markerText:+html_comments;
      }
      gFunctionHelp_form_wid._DisplayFunctionHelp(
         margin_text,
         8,  // 8 points
         text,
         html_comments,
         ",;",
         (_twips_per_pixel_x()*4),
         (_twips_per_pixel_y()*2),
         avail_width,
         _default_font(CFG_FUNCTION_HELP),
         _default_font(CFG_FUNCTION_HELP_FIXED),
         0x80000020,0x80000021,
         SCROLL_BAR_HEIGHT(vheight),
         F_BOLD);
      _PositionNoFocusForm(editorctl_wid,
                           gFunctionHelp_form_wid,
                           gFunctionHelp_cursor_x,
                           gFunctionHelp_cursor_y,
                           editorctl_wid.p_font_height,0);
      if (cur_param_name != "") {
         _nocheck _control ctlminihtml2;
         gFunctionHelp_form_wid.ctlminihtml2._minihtml_FindAName(cur_param_name,VSMHFINDANAMEFLAG_CENTER_SCROLL);
      }
      gFunctionHelp_form_wid._ShowWindow(SW_SHOWNOACTIVATE);
      gFunctionHelp_form_wid.refresh('w');
      _reset_idle();
      return;
   } else {
      // find the output tagwin and update it
      cb_refresh_output_tab(first_cm, true);
   }

   //def_codehelp_html_comments
   //member_msg=stranslate(member_msg,"&&","&");

   // show the member (function) help dialog

   _nocheck _control ctlminihtml2;
   vx *= _twips_per_pixel_x();
   screen_w := vwidth*_twips_per_pixel_x();
   screen_h := vheight*_twips_per_pixel_y();
   char_h := 0;
   first_visible := 0;
   current_line := 0;
   have_list_form := false;
   list_x := 0;
   list_h := 0;
   list_w := 0;
   delta_h := 0;
   tree_wid := form_wid.LISTHELPTREEWID();
   if (tree_wid != null && tree_wid > 0 && _iswindow_valid(tree_wid)) {
      char_h = tree_wid.p_line_height;
      first_visible = tree_wid._TreeScroll();
      current_line  = tree_wid._TreeCurLineNumber();
      delta_h = _twips_per_pixel_y() * char_h * (current_line - first_visible);
      list_form_wid := tree_wid.p_active_form;
      if (_iswindow_valid(list_form_wid) && list_form_wid.p_visible) {
         list_h = list_form_wid.p_height;
         list_w = list_form_wid.p_width;
         list_x = list_form_wid.p_x;
         have_list_form=true;
      }
   }

   // if there is no tree control, then pivot at cursor position.
   if (!have_list_form) {
      list_x = _dx2lx(SM_TWIP, text_x);
      list_h = _dy2ly(SM_TWIP, editorctl_wid.p_height);
   }

   // once the form moves to the left because there is more
   // space there, then leave it there, don't hop back and forth
   if (!prefer_left_placement && 
       form_wid.p_x_extent <= list_x &&
       list_x-vx > vx+screen_w-list_x-list_w) {
      prefer_left_placement = true;
   }
   
   x := list_x + list_w;
   y := 0;
   height := 0;
   int avail_width=(screen_w intdiv 1);
   width := avail_width;
   // IF this window does not fit on the right of the list
   if (x+width > vx+screen_w || prefer_left_placement) {
      // IF there is more space on the left;
      if (list_x-vx > screen_w-(x-vx)) {
         x = x-width-list_w;
         if (x<vx) x=vx;
         avail_width=list_x-vx;
      } else {
         avail_width=screen_w-(x-vx);
      }
   }
                       
   if (avail_width<300) avail_width=300;
   if (avail_width > 18000) {
      // lots of space, don't occupy more the 2/3 of screen
      avail_width=(avail_width*2 intdiv 3);
   } else if (avail_width > 12000) {
      // not tons of space, but don't use more than 12000 twips
      avail_width=12000;
   }

   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": margin_text="margin_text);
      say("ShowCommentHelp H"__LINE__": text="text);
      say("ShowCommentHelp H"__LINE__": html_comments="html_comments);
   }

   /*
       This code is not finished yet.
       We need to pass a tag if multiple tags are found.
   */
   form_wid._DisplayFunctionHelp(
      margin_text,
      8,  // 8 points
      text,
      html_comments,
      ",;",
      (_twips_per_pixel_x()*4),
      (_twips_per_pixel_y()*2),
      avail_width,
      _default_font(CFG_FUNCTION_HELP),
      _default_font(CFG_FUNCTION_HELP_FIXED),
      0x80000020,0x80000021,
      list_h,
      -1);

   junk_x:=0;
   form_wid._get_window(junk_x,y,width,height);
   //y = form_wid.p_y + delta_h;
   //if (list_h > 0 && delta_h+height > list_h) {
   //   y = y-delta_h+(list_h-height);
   //}
   x= list_x + list_w;
   // IF this window fits to the right
   if (x+width > vx+screen_w || prefer_left_placement) {
      // IF there is more space on the left;
      if(list_x-vx> screen_w-(x-vx) ||
         (prefer_left_placement && list_x > list_w)) {
         x = x-width-list_w;
         if (x<vx) x=vx;
      }
   }
   // IF this window doesn't fit vertically on the screen
   if (y+height > vy+screen_h) {
      y = (vy+screen_h-height);
   }
   if (cur_param_name != "") {
      _nocheck _control ctlminihtml2;
      form_wid.ctlminihtml2._minihtml_FindAName(cur_param_name,VSMHFINDANAMEFLAG_CENTER_SCROLL);
   }

   if (do_not_move_form) {
      x = form_wid.p_x;
      y = form_wid.p_y;
   }

   form_wid._move_window(x,y,width,height);
   form_wid._ShowWindow(SW_SHOWNOACTIVATE);
   form_wid.refresh("w");
   _reset_idle();
   if (_chdebug) {
      say("ShowCommentHelp H"__LINE__": OUT");
   }
}

/**
 * Decide whether or not, based on current context, the list
 * symbols menu item should be enabled or disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_list_symbols(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveContextTagging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!_istagging_supported()) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows list-symbols to report that
      // when tagging is not supported.
      return(MF_GRAYED|MF_ENABLED);
   }
   return(MF_ENABLED);
}
int _OnUpdate_codehelp_trace_list_symbols(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_list_symbols(cmdui,target_wid,command);
}

/**
 * List the symbols visible in the current context in the list members
 * window.  This command is normally bound to Alt+Dot
 *
 * @see _do_list_members
 *
 * @categories Tagging_Functions
 */
_command void list_symbols() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   if (_executed_from_key_or_cmdline(name_name(last_index('','C')))) {
      if (_macro('KI')) _macro('KD');
   }
   //say("list_symbols: ");
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }

   index := last_index('','C');
   prev := prev_index('','C');
   _macro_delete_line();
   _do_list_members(OperatorTyped:false,
                    DisplayImmediate:true,
                    syntaxExpansionWords:null,
                    expected_type:null,
                    rt:null,
                    expected_name:null,
                    prefixMatch:false,
                    selectMatchingItem:true,
                    isFirstAttempt: !AutoCompleteCommandRepeated()
                    );

   last_index(index,'C');
   prev_index(prev,'C');
}

static bool gIDExprFailed = false;
static long gnew_total_time = 0;
static long gold_total_time = 0;

_command void codehelp_trace_expression_info(_str operatorTyped="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   orig_chdebug := _chdebug;
   _chdebug = 2;
   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   VS_TAG_RETURN_TYPE visited:[];
   _Embeddedget_expression_info(operatorTyped==1, lang, idexp_info, visited);
   if (operatorTyped == "v") tag_idexp_info_dump(idexp_info, "TRACE");
   _chdebug = orig_chdebug;
   gnew_total_time = 0;
   gold_total_time = 0;
}
int _OnUpdate_codehelp_trace_expression_info(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_list_symbols(cmdui,target_wid,command);
}

_command void codehelp_test_expression_info(_str startAtCursor="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   status := 0;
   orig_chdebug := _chdebug;
   _chdebug = 1;
   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   VS_TAG_RETURN_TYPE visited:[];
   gIDExprFailed = false;
   save_pos(auto p);
   if (startAtCursor!=1) {
      bottom();
      _end_line();
   }
   fileSize := _QROffset();

   // Show progress dialog
   progressFormID := show_cancel_form("Testing get_expression_info callback", p_buf_name, true, true);

   while (_QROffset() > 0) {
      tag_idexp_info_init(idexp_info);
      visited._makeempty();
      status = _Embeddedget_expression_info(true, lang, idexp_info, visited);
      if (gIDExprFailed && startAtCursor==1) {
         say("codehelp_test_expression_info: OPERATOR FAIL AT OFFSET="_QROffset());
         break;
      }
      if (status == 0 && !p_ReadOnly) {
         save_pos(auto before_trunc);
         delete_end_line();
         status = _Embeddedget_expression_info(true, lang, idexp_info, visited);
         undo();
         restore_pos(before_trunc);
         if (gIDExprFailed && startAtCursor==1) {
            say("codehelp_test_expression_info: TRUNC FAIL AT OFFSET="_QROffset());
            break;
         }
      }

      tag_idexp_info_init(idexp_info);
      visited._makeempty();
      status = _Embeddedget_expression_info(false, lang, idexp_info, visited);
      if (gIDExprFailed && startAtCursor==1) {
         say("codehelp_test_expression_info: LIST MEMBERS FAIL AT OFFSET="_QROffset());
         break;
      }
      if (status == 0 && 
          idexp_info.lastid._length() > 0 &&
          isid_valid(idexp_info.lastid) &&
          idexp_info.lastidstart_offset < _QROffset() - 2 &&
          idexp_info.lastidstart_offset + idexp_info.lastid._length() >= _QROffset()) {
         _GoToROffset(idexp_info.lastidstart_offset);
      } else if (status == 0 && 
                 idexp_info.lastidstart_offset == _QROffset() &&
                 idexp_info.lastid._length() == 0 &&
                 idexp_info.prefixexp._length() == 0 &&
                 idexp_info.otherinfo._length() == 0) {
         // Skip backwards over groups of spaces
         search("[^ \t]", "@rh-");
         if (p_col > 1) {
            left();
         } else {
            up();
            _end_line();
         }
      } else {
         if (p_col > 1) {
            left();
         } else {
            up();
            _end_line();
         }
      }

      // if there is a progress form, update it
      if ((_QROffset() % 32) == 0 && progressFormID) {
         cancel_form_progress(progressFormID, (int)(fileSize-_QROffset()), (int)fileSize);
         if(cancel_form_cancelled()) break;
      }
   }
   if (!gIDExprFailed) {
      say("_Embeddedget_expression_info: SUCCESS FOR ENTIRE FILE");
      restore_pos(p);
   }
   if (startAtCursor!=1) {
      restore_pos(p);
   }
   _chdebug = orig_chdebug;
   say("_Embeddedget_expression_info: new_total="gnew_total_time" old_total="gold_total_time);
   gnew_total_time = 0;
   gold_total_time = 0;

   // kill progress form
   if(progressFormID) {
      close_cancel_form(progressFormID);
   }
}
int _OnUpdate_codehelp_test_expression_info(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_list_symbols(cmdui,target_wid,command);
}

_command void codehelp_trace_list_symbols() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   say("codehelp_trace_list_symbols: ===============================");
   orig_chdebug := _chdebug;
   _chdebug = 1;
   list_symbols();
   _chdebug = orig_chdebug;
   say("============================================================");
}
_command void codehelp_trace_complete() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   say("codehelp_trace_complete: ===================================");
   orig_chdebug := _chdebug;
   _chdebug = 1;
   codehelp_complete();
   _chdebug = orig_chdebug;
   say("============================================================");
}

_command void codehelp_trace_key() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   say("codehelp_trace_key: ===================================");
   orig_chdebug := _chdebug;

   // prompt for a key to profile the command bound to
   typeless keytab_used,k;
   _str keyname;
   if (prompt_for_key(nls('Find proc bound to key:')' ',keytab_used,k,keyname,'','','',1)) {
      return;
   }

   // profile running that key
   _chdebug = 1;
   call_event(keytab_used, k, 'e');
   _chdebug = orig_chdebug;
   say("============================================================");
}

/**
 * Is a callback (hook function) available for the current language,
 * accounting for embedded languages, such as JavaScript within HTML.
 *
 * @param proc_name procedure name to search for, not extension
 *                  should already be added
 *
 * @return 1 if callback is available, result is equivelent to
 *         an embedded start.  0 if the callback is not available.
 *
 * @see _EmbeddedStart
 * @see _EmbeddedEnd
 */
int _EmbeddedCallbackAvailable(_str proc_name)
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   /*
   Returns 2 to indicate that there is embedded language
   code, but in comment/in string like default processing
   should be performed.
    For now don't allow auto function help in string embedded language.
   */
   if (embedded_status==2) {
      return(0);
   }
   index := _FindLanguageCallbackIndex(proc_name,p_LangId);
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   //gFunctionHelp_fcthelp_get=find_index("_"p_LangId"_fcthelp_get",PROC_TYPE);
   if (!index) {
      return(0);
   }
   return(1);
}
/**
 * Decide whether or not, based on current context, the parameter
 * information menu item should be enabled or disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_function_argument_help(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveContextTagging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   //status=(index_callable(find_index("_"p_LangId"_fcthelp_get_start",PROC_TYPE)) );
   int status=_EmbeddedCallbackAvailable("_%s_fcthelp_get_start");
   if (!status) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows function-argument-help to
      // report when it is not supported.
      return(MF_GRAYED|MF_ENABLED);
   }
   return(MF_ENABLED);
}
int _OnUpdate_codehelp_trace_function_argument_help(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_function_argument_help(cmdui,target_wid,command);
}
/**
 * Display function help window showing prototype for current function
 * being called, highlighting the current parameter.
 * This command is normally bound to Alt+Comma
 *
 * @see _do_function_help
 */
_command void function_argument_help() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Parameter help");
      return;
   }
   if (_executed_from_key_or_cmdline(name_name(last_index('','C')))) {
      if (_macro('KI')) _macro('KD');
   }
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   _do_function_help(OperatorTyped:false,
                     DisplayImmediate:true,
                     cursorInsideArgumentList:true,
                     tryReturnTypeMatching:true);
}
_command void codehelp_trace_function_argument_help() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Parameter help");
      return;
   }
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   orig_chdebug := _chdebug;
   _chdebug = 1;
   _do_function_help(OperatorTyped:false,
                     DisplayImmediate:true,
                     cursorInsideArgumentList:true,
                     tryReturnTypeMatching:true);
   _chdebug = orig_chdebug;
}

_str _getJavadocTag()
{
   line := "";
   get_line(line);
   before := after := tag := "";
   if (pos(CODEHELP_DOXYGEN_PREFIX1, line) > 0) {
      parse line with before "//!" after .;
   } else {
      parse line with before "*" after .;
   }
   before_ch := _first_char(before);
   if (before_ch == '@' || before_ch == '\') {
      tag=substr(before,2);
      return(tag);
   }
   after=strip(after);
   after_ch := _first_char(after);
   if (before=="" && (after_ch == '@' || after_ch == '\')) {
      tag=substr(after,2);
      return(tag);
   }
   return("");
}
/**
 * @return True if we are currently in the scope of a Javadoc @see tag.
 */
bool _inJavadocSeeTag(_str &tag="")
{
   tag = _getJavadocTag();
   if (tag != "see" && tag != "throw") {
      return false;
   }
   if (!_inJavadoc() && !_inDoxygenComment()) {
      tag = "";
      return false;
   }

   save_pos(auto p);
   _begin_line();
   _TruncSearchLine("[\\@](see|throw)", "r");
   see_col := p_col;
   restore_pos(p);
   if (p_col < see_col) {
      tag = "";
      return false;
   }

   return true;
}
bool _inJavadocSwitchToHTML()
{
   tag := "";
   if (!_inJavadoc() && !_inDoxygenComment()) {
      return(false);
   }
   tag=_getJavadocTag();
   index := find_index("_javadoc_"tag"_find_context_tags",PROC_TYPE);
   if (index) {
      return(false);
   }
   return(tag!="see");

   //get_line(line);tag="";
   //parse line with first second .;
   //return ((first=="*" && second=="@see") || first=="@see");
}

/** 
 * Generic function to test if we are in a documentation comment.
 *
 * @param fastCheck If true, only search 1000 lines above the current line
 *                  for the start of the comment.
 * @param style     (optional) If not specified, check if any documentation 
 *                  comment style, otherwise, just check for the one given
 *                  <ul>
 *                  <li>CODEHELP_DOXYGEN_PREFIX  = "/&ast;!"
 *                  <li>CODEHELP_DOXYGEN_PREFIX1 = "//!"
 *                  <li>CODEHELP_DOXYGEN_PREFIX2 = "///"
 *                  <li>CODEHELP_JAVADOC_PREFIX  = "/&ast;&ast;"
 *                  </ul>
 *
 * @return non-zero value if in doc comment. 
 *         The non-zero value is the column position where leading comment
 *         characters should align for the comment.
 */
int _inDocumentationComment(bool fastCheck = false, _str style="")
{
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }

   // create a selection of the surrounding 2000 lines
   save_pos(auto p);
   orig_mark_id:=0;
   mark_id := 0;
   fastCheckOption := "";
   if (fastCheck && p_RLine > def_codehelp_max_comments) {
      orig_mark_id = _duplicate_selection("");
      mark_id = _alloc_selection();
      if (mark_id<0) return mark_id;

      fastCheckOption = "m";
      p_RLine = p_RLine - def_codehelp_max_comments;
      _select_line(mark_id);
      restore_pos(p);
      _select_line(mark_id);
      _end_select(mark_id,true);
      _show_selection(mark_id);
      restore_pos(p);
   }

   // search for the beginning of the comment, only with selection for fast option
   int status=_clex_find(COMMENT_CLEXFLAG,"n-"fastCheckOption);
   if (status) {
      top();
   }

   _clex_find(COMMENT_CLEXFLAG);
   col := p_col;
   get_line(auto text);
   text=substr(text,text_col(text,col,'P'),4);
   text=stranslate(text,"","\n");
   text=stranslate(text,"","\r");
   if (style != "" && text==style) {
      col+=1;
   } else if ((style == "") && 
              ((text == CODEHELP_DOXYGEN_PREFIX ) || 
               (text == CODEHELP_DOXYGEN_PREFIX1) ||  
               (text == CODEHELP_DOXYGEN_PREFIX2) ||  
               (text == CODEHELP_JAVADOC_PREFIX ) )) {
      col+=1;
   } else {
      col=0;
   }
   if (fastCheckOption!="") {
      _show_selection(orig_mark_id);
      _free_selection(mark_id);
   }
   restore_pos(p);
   return(col);
}

/** 
 * Is the cursor in a JavaDoc documentation comment? 
 *
 * @param fastCheck If true, only search 1000 lines above the current line
 *                  for the start of the comment.
 *
 * @return non-zero value if in Javadoc comment. 
 *         The non-zero value is the column position where star '*'
 *         characters should align for the comment.
 */
int _inJavadoc(bool fastCheck = false)
{
   return _inDocumentationComment(false, CODEHELP_JAVADOC_PREFIX);
}
/** 
 * Is the cursor in an XMLDoc documentation comment? 
 *
 * @param fastCheck If true, only search 1000 lines above the current line
 *                  for the start of the comment.
 *
 * @return non-zero value if in XMLdoc comment. 
 *         The non-zero value is the column position where star '///'
 *         characters should align for the comment.
 */
int _inXMLDoc(bool fastCheck = false)
{
   return _inDocumentationComment(false, CODEHELP_DOXYGEN_PREFIX2);
}
/** 
 * Is the cursor in a Doxygen style documentation comment? 
 *
 * @param fastCheck If true, only search 1000 lines above the current line
 *                  for the start of the comment.
 *
 * @return non-zero value if in a Doxygen comment. 
 *         The non-zero value is the column position where star '*'
 *         or '//!' characters should align for the comment.
 */
int _inDoxygenComment(bool fastCheck = false)
{
   col := _inDocumentationComment(false, CODEHELP_DOXYGEN_PREFIX);
   if (col > 0) return col;
   return _inDocumentationComment(false, CODEHELP_DOXYGEN_PREFIX1);
}

/**
 * @return non-zero value if in the middle of an aligned
 * multi-line line comment.  Note, this function also
 * considers a single line containing an empty line
 * comment as a multi-line comment.
 * The non-zero value is the column position where
 * the line comment delimiter characters align for the comment.
 * @example
 * slash '//' characters align for the line comment in a C-style line ,comment.
 */
int _inExtendableLineComment(_str &delims="", bool skipAllDelimsTest = false)
{
   // we must be in a comment
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }

   // try extension specific callback
   index := _FindLanguageCallbackIndex("_%s_inExtendableLineComment");
   if( index>0 ) {
      return ( call_index(index) );
   }

   // get line comment delimeters for this language
   _str commentChars[];
   if (_getLineCommentChars(commentChars) != 0) {
      return(0);
   }

   // try each delimeter
   int i;
   for (i=0; i<commentChars._length(); ++i) {
      int comment_col = _inExtendableLineCommentWithDelimeters(commentChars[i], skipAllDelimsTest);
      if (comment_col > 0) {
         delims = commentChars[i];
         return comment_col;
      }
   }

   // didn't match any of the comment delimeters
   return 0;
}

/**
 * Retrieve the line comment delimeters for this language
 * using the color coding settings.
 */
int _getLineCommentChars(_str (&commentChars)[], _str lexer_name="")
{
   // initialize the array
   commentChars._makeempty();

   // can we grab the lexer name?
   if (lexer_name == "" && _isEditorCtl()) {
      lexer_name = p_lexer_name;
   }

   // Do we even have a lexer for this mode?
   if (lexer_name == "") {
      return STRING_NOT_FOUND_RC;
   }
   if (g_lineCommentChars._indexin(lexer_name)) {
      commentChars = g_lineCommentChars:[lexer_name].commentChars;
   } else {
      if (strieq(lexer_name,'C Shell') || strieq(lexer_name,'Bourne shell')) {
         commentChars[0]='#';
      } else {
         COMMENT_TYPE comments[];
         GetComments(comments,'L',lexer_name);
         for (i:=0;i<comments._length();++i) {
            commentChars[i]=comments[i].delim1;
         }
      }

      LINECOMMENTCHARS lcc;
      lcc.commentChars = commentChars;
      g_lineCommentChars:[lexer_name] = lcc;
   }

   if (!commentChars._length()) {
      return 1;
   }
   return(0);
}

/**
 * Retrieve the line comment delimeters for this language
 * using the color coding settings.
 */
int _getBlockCommentChars(_str (&startChars)[], _str (&endChars)[],  bool (&nesting)[], _str lexer_name="")
{

   // initialize the array
   startChars._makeempty();
   endChars._makeempty();
   nesting._makeempty();

   // can we grab the lexer name?
   if (lexer_name == "" && _isEditorCtl()) {
      lexer_name = p_lexer_name;
   }

   // Do we even have a lexer for this mode?
   if (lexer_name == "") {
      return STRING_NOT_FOUND_RC;
   }
   if (g_blockCommentChars._indexin(lexer_name)) {
      startChars = g_blockCommentChars:[lexer_name].startChars;
      endChars = g_blockCommentChars:[lexer_name].endChars;
      nesting = g_blockCommentChars:[lexer_name].nesting;
   } else {
      COMMENT_TYPE comments[];
      GetComments(comments,'M',lexer_name);
      for (i:=0;i<comments._length();++i) {
         startChars[i]=comments[i].delim1;
         endChars[i]=comments[i].delim2;
         nesting[i]=comments[i].nesting?true:false;
      }
      BLOCKCOMMENTCHARS bcc;
      bcc.startChars = startChars;
      bcc.endChars = endChars;
      bcc.nesting = nesting;
      g_blockCommentChars:[lexer_name] = bcc;
   }
   if (!startChars._length()) {
      return 1;
   }
   return(0);
}

/**
 * Assuming the cursor is in a line comment, jump to the
 * first character of beginning of the line comment.
 */
int _beginLineComment()
{
   // not in a comment, the do nothing
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return STRING_NOT_FOUND_RC;
   }

   // search for something before the comment
   orig_line := p_line;
   int status=_clex_find(COMMENT_CLEXFLAG,'n-');
   if (status) {
      _begin_line();
   }

   // find the start of the comment
   if (p_line != orig_line) {
      // backed up over another comment?
      p_line = orig_line;
      p_col = 1;
   } else {
      _clex_find(COMMENT_CLEXFLAG);
   }

   // success
   return 0;
}

static int _inExtendableLineCommentWithDelimeters(_str commentChars="//", bool skipAllDelimsTest = false)
{
   // we must be in a comment
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }

   // check if we are at the end of the line
   save_pos(auto p);
   orig_col := p_col;
   at_end := (at_end_of_line());

   // find the start of the comment
   _beginLineComment();

   // line comment starts with comment start chars
   commentLength := length(commentChars);
   int col = (get_text(commentLength)==commentChars)? p_col:0;

   // check for case-sensitive match
   if (!col && !p_EmbeddedCaseSensitive) {
      col = (lowcase(get_text(commentLength))==lowcase(commentChars))? p_col:0;
      commentChars = get_text(commentLength);
   }

   // not at end of line, so restore position and we are done
   if (!at_end) {
      restore_pos(p);
      return(col);
   }

   // first, check if the previous line has a line comment
   prev_line_has_comment := true;
   restore_pos(p);
   if (up()) prev_line_has_comment=false;
   if (_clex_find(0,'g')!=CFG_COMMENT) prev_line_has_comment=false;
   _beginLineComment();
   if (get_text(commentLength)!=commentChars || col!=p_col) prev_line_has_comment=false;

   // now check if the next line has a line comment
   next_line_has_comment := true;
   restore_pos(p);
   if (down()) next_line_has_comment=false;
   if (_clex_find(0,'g')!=CFG_COMMENT) next_line_has_comment=false;
   _beginLineComment();
   if (get_text(commentLength)!=commentChars || col!=p_col) next_line_has_comment=false;

   // check if the current line is all delimters (e.g. slashes for C-style comments)
   restore_pos(p);
   p_col=col;
   all_delims := skipAllDelimsTest || (orig_col > p_col && pos('^['commentChars']*[ \t]*$',get_text(orig_col-p_col),1,'r')==1);

   // line comment is stand-alone and not empty
   if (!prev_line_has_comment && !next_line_has_comment && !all_delims) {
      col = 0;
   }

   // extending a line comment, check options?
   if (prev_line_has_comment && !next_line_has_comment &&
       !_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS)) {
      col = 0;
   }

   // ok, this passes as an extendable line comment
   restore_pos(p);
   return(col);
}

/**
 * This function is called from functions that handle the ENTER key.
 * It checks if the current cursor location is within a line comment
 * and will split or extend the line comment if appropriate.
 *
 * @author_inExtendableLineComment()
 */
bool _maybeSplitLineComment()
{
   // not the editor control?
   if (!_isEditorCtl()) {
      return false;
   }

   // read only?
   if (_QReadOnly()) {
      return false;
   }

   // is the comment split or extend comment option on?
   if (at_end_of_line()) {
      if (!_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS)) {
         return false;
      }
   } else {
      if (!_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS)) {
         return false;
      }
   }

   // are we in a line comment?
   if (!_in_comment(false)) {
      return false;
   }

   // are we in an extendable line comment?
   commentChars := "";
   orig_col := p_col;
   int line_col = _inExtendableLineComment(commentChars);
   if (!line_col) {
      return false;
   }

   // is split insert line active?
   if (!_will_split_insert_line() && !(at_end_of_line() && _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS))) {
      return false;
   }

   // get the line comment character
   save_pos(auto p);
   p_col=line_col;
   _str comment_ch = get_text(commentChars._length());
   padding := "";
   get_line_raw(auto line);
   int afterDelimRaw = text_col(line, p_col + commentChars._length(), 'P');
   contentCol := pos("[~ \\t]", line, afterDelimRaw, 'R');
   if (contentCol) {
      padding = substr(line, afterDelimRaw, contentCol - afterDelimRaw);
   }
   restore_pos(p);

   // already have comment character?
   if (line_col == orig_col) {
      return false;
   }

   // ok, now we patch in the comment
   indent_on_enter(0,line_col);
   if (get_text(commentChars._length())!=comment_ch) {
      keyin(commentChars :+ padding);
   }

   // we have successfully split the line comment
   return true;
}

/**
 * @return non-zero value if in the middle of a string
 *         The non-zero value is the column position where
 *         the string's starting delimiter is.
 *
 * @param delim string delimiter.
 */
int _inString(_str &delim,bool allow_raw_strings=true)
{
   // we must be in a string
   if (_clex_find(0,'g')!=CFG_STRING) {
      delim="";
      return(0);
   }

   // check if we are at the end of the line
   save_pos(auto p);

   // search for something before the string
   int status=_clex_find(STRING_CLEXFLAG,'n-');
   if (status) {
      top();
   }

   // find the start of the comment
   _clex_find(STRING_CLEXFLAG);
   col := p_col;
   if (!allow_raw_strings) {
      if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('kotlin')) {
         if (get_text(3)=='"""') {
            restore_pos(p);
            return 0;
         }
      }
      if (_LanguageInheritsFrom('cs')) {
         if (p_col>=2) {
            left();
            if (get_text(2)=='@"') {
               restore_pos(p);
               return 0;
            }
            right();
         }
      }
   }
   delim = get_text();
   if (delim != '"' && delim != "'") {
      restore_pos(p);
      return 0;
   }
   if (!allow_raw_strings && p_LangId=='c' && p_col>1) {
      left();
      temp:=get_text();
      if (temp=='R') {
         delim="R";
         restore_pos(p);
         return 0;
      }
   }

   // restore position and we are done
   restore_pos(p);
   return(col);
}

/*
    This code which attempts to autodetect a XMLDOC versus a Javadoc comment only works if your
    cursor is inside the definition.
    For example:
         /// <summary> xml comment </summary>
         int field1;   <cursor here!!! does not work>
         /**
          * javadoc comment
          */
         int field2;
    I think this needs to interate through the context to get the nearest match.
*/
int _GetCurrentCommentInfo(VSCodeHelpCommentFlags &comment_flags,
                           _str &orig_comment,
                           _str &return_type, 
                           _str &line_prefix, 
                           int (&blanks):[][],
                           _str &doxygen_comment_start)
{
   comment_flags=0;
   orig_comment="";
   save_pos(auto p);
   _clex_skip_blanks();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   context_id := tag_current_context();
   if (context_id <= 0) {
      restore_pos(p);
      return(1);
   }
   // get the information about the current function
   tag_get_context_browse_info(context_id, auto cm);
   return_type = cm.return_type;

   _GoToROffset(cm.seekpos);
   if (tag_tree_type_is_func(cm.type_name)) {
      _UpdateLocals(true);
   }

   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   int first_line, last_line;
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      p_RLine=cm.line_no;
      _GoToROffset(cm.seekpos);
      // We temporarily change the buffer name just in case the Javadoc Editor
      // is the one getting the comments.
      _str old_buf_name=p_buf_name;
      p_buf_name="";
      _do_default_get_tag_comments(comment_flags, cm.type_name, orig_comment, 
                                   def_codehelp_max_comments*10, false,
                                   line_prefix, blanks, doxygen_comment_start);
      p_buf_name=old_buf_name;
   } else {
      //init_modified=1;
      first_line = cm.line_no;
      last_line  = first_line-1;
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   restore_pos(p);
   return(0);
}
/**
 * Attempt to find the expected type for an identifier with
 * (or without) prefix expression from the current context.
 * This makes it possible, for example, the list compatible
 * variables for the right-hand-side of an assignment statement.
 *
 * @param errorArgs              array of error message arguments
 * @param prefixexpstart_offset  prefix expression start offset
 * @param rt                     (reference) expected return type
 *
 * @return 0 on success, expected type must contain the fully
 *                       qualified type name.
 */
static int find_expected_type_from_expression(_str (&errorArgs)[],
                                              int prefixexpstart_offset,
                                              VS_TAG_RETURN_TYPE &rt,
                                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   //say("find_expected_type_from_expression: IN");
   // drop into embedded mode to find expression start
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   //say("find_expected_type_from_expression: passed embedded");
   // find the function to find the expression context
   ep_index := _FindLanguageCallbackIndex("_%s_get_expression_pos");
   if (!ep_index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         say("find_expected_type_from_expression H"__LINE__": ");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("find_expected_type_from_expression: have expression_ops callback");
   // find the function to analyze return types, we need this
   ar_index := _FindLanguageCallbackIndex("_%s_analyze_return_type");
   if (!ar_index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         say("find_expected_type_from_expression H"__LINE__": ");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("find_expected_type_from_expression: have analyze return type");
   // we'll need this information later
   typeless tag_files=tags_filenamea(p_LangId);
   case_sensitive := p_EmbeddedCaseSensitive;

   // save the current buffer position for restore
   typeless orig_pos;
   save_pos(orig_pos);

   //say("find_expected_type_from_expression: prefixpos="prefixexpstart_offset);
   // get the position of a comparible identifier in the
   // current expression that we can use to determine the expected
   // return type
   _GoToROffset(prefixexpstart_offset);
   lhs_start_offset := 0;
   expression_op := "";
   reference_count := 0;
   status := call_index(lhs_start_offset,expression_op,reference_count,depth+1,ep_index);
   //say("find_expected_type_from_expression: status="status);
   if (embedded_status==1) {
      restore_pos(orig_pos);
      _EmbeddedEnd(orig_values);
      embedded_status=0;
   }
   if (status) {
      restore_pos(orig_pos);
      return(status);
   }
   //say("find_expected_type_from_expression: op="expression_op" pos="lhs_start_offset);
   case_sensitive=case_sensitive;

   // evaluate the ID expression at the calculated position
   _GoToROffset(lhs_start_offset);
   _str ext;

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   status = _Embeddedget_expression_info(false,ext,idexp_info,visited,depth+1);

   //say("find_expected_type_from_expression: lastid="idexp_info.lastid" prefixexp="idexp_info.prefixexp" status="status);
   if (status) {
      restore_pos(orig_pos);
      return(status);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // analyze the return type of the identifier to compare to
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   status = _Embeddedfind_context_tags(errorArgs,idexp_info.prefixexp,
                                       idexp_info.lastid,idexp_info.lastidstart_offset,
                                       idexp_info.info_flags,idexp_info.otherinfo,
                                       false,def_tag_max_function_help_protos,
                                       true,case_sensitive,
                                       SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_PROCEDURE,
                                       SE_TAG_CONTEXT_ALLOW_LOCALS,
                                       visited, depth+1);
   //say("find_expected_type_from_expression: find status="status" num_matches="tag_get_num_of_matches());
   if (status < 0) {
      restore_pos(orig_pos);
      return(status);
   }

   // analyze the return type of each and every match
   VS_TAG_RETURN_TYPE found_rt;
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; ++i) {
      // get the details about this tag
      tag_get_match_browse_info(i, auto cm);

      // compute it's return type
      tag_return_type_init(found_rt);
      status = _Embeddedanalyze_return_type(ar_index, errorArgs, tag_files, cm, cm.return_type, found_rt, visited);
      //say("find_expected_type_from_expression: ar status="status" return_type="return_type" found_rt="found_rt.return_type);
      if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         continue;
      }

      // does the return type match the last found return type?
      if (rt==null || rt.return_type=="") {
         rt=found_rt;
      } else if (!tag_return_type_equal(rt,found_rt,case_sensitive)) {
         errorArgs[1]=cm.member_name;
         status = VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
         break;
      }
   }

   // adjust the return type pointer count
   if (reference_count>0 && rt.pointer_count<reference_count) {
      errorArgs[1]=idexp_info.lastid;
      status = VSCODEHELPRC_SUBSCRIPT_BUT_NOT_ARRAY_TYPE;
   } else {
      rt.pointer_count-=reference_count;
   }

   // the best laid plans of mice and men...
   if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
      restore_pos(orig_pos);
      return(status);
   }

   // success!, it's unbelievable!, success!!!
   //say("find_expected_type_from_expression: SUCCESS!!!!!!!!!!!!!!!!!!!!!!");
   restore_pos(orig_pos);
   return(0);
}

/**
 * List the symbols visible in the current context in the
 * list members window.  Calls the extension specific hook
 * function _[lang]_get_expression_info to get the basic information about
 * the current context, then hands the information off to
 * auto complete to call _[lang]_find_context_tags and
 * populate the list symbols tree.
 *
 * @param OperatorTyped
 * @param DisplayImmediate
 * @param syntaxExpansionWords
 * @param expected_type
 * @param rt
 *
 * @see list_symbols
 *
 * @categories Tagging_Functions
 */
void _do_list_members(bool OperatorTyped,
                      bool DisplayImmediate,
                      _str (&syntaxExpansionWords)[]=null,
                      _str expected_type=null,
                      VS_TAG_RETURN_TYPE &rt=null,
                      _str expected_name=null,
                      bool prefixMatch=false,
                      bool selectMatchingItem=false,
                      bool doListParameters=false,
                      bool isFirstAttempt=true,
                      VS_TAG_RETURN_TYPE (&visited):[]=null,
                      int depth=0)
                      
{
   // No context tagging means no auto-list members
   if ((OperatorTyped || doListParameters) && !_haveContextTagging()) {
      return;
   }

   // IF we are in a recorded macro, just forget it
   if (_macro('r')) {
      // Too slow to display GUI
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      return;
   }
   
   if (_chdebug > 0) {
      isay(depth, "_do_list_members: operator="OperatorTyped", expected_ty="(expected_type ? expected_type : "<null>")", expected_name="(expected_name ? expected_name : "<null>"));
   }
   
   //say("do_list_members("OperatorTyped","DisplayImmediate);
   orig_col := p_col;
   left();
   p_col=orig_col;
   //bool inJavadocSeeTag=_inJavadocSeeTag();

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   lang := p_LangId;
   status := 0;
   // set up info flags to be seen by get_expression_info
   if (expected_type!=null && expected_type!="") {
      //say("_do_list_members: expected_type="expected_type);
      idexp_info.info_flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
   }
   // parse out the context expression for the current language

   status=_Embeddedget_expression_info(OperatorTyped, lang, idexp_info, visited);
   if (status && OperatorTyped && rt!=null) {
      status=_Embeddedget_expression_info(false, lang, idexp_info, visited);
   }

   // override expression info if overloaded operator syntax
   if (OperatorTyped && status < 0 && (idexp_info.info_flags & VSAUTOCODEINFO_CPP_OPERATOR )) {
      tag_idexp_info_init(idexp_info);
      idexp_info.lastid="";
      idexp_info.prefixexp="";
      idexp_info.lastidstart_col=p_col;
      idexp_info.lastidstart_offset=(int)_QROffset();
      idexp_info.prefixexpstart_offset=(int)_QROffset();
      idexp_info.info_flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
      status=0;
   }

   if (status) {
      if (!OperatorTyped && expected_type==null) {
         msg := _CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!="") {
            //_message_box(msg);
            message(msg);
         }
      }
      return;
   }
   // if we were not given an expected type, try to find one
   if (idexp_info.prefixexpstart_offset>0 && expected_type==null && rt!=null) {
      tag_return_type_init(rt);
      status=find_expected_type_from_expression(idexp_info.errorArgs,idexp_info.prefixexpstart_offset,rt);
      if (status) {
         msg := _CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!="" && !OperatorTyped) {
            message(msg);
         }
         return;
      } else {
         expected_type = rt.return_type;
      }
   }
   if (OperatorTyped) {
      idexp_info.info_flags |= VSAUTOCODEINFO_OPERATOR_TYPED;
   }
   if (expected_type!=null) {
      idexp_info.info_flags |= VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
   } else {
      rt = null;
   }
   if (_chdebug) {
      tag_idexp_info_dump(idexp_info,"_do_list_members");
   }

   // if auto-complete is already active, then just update the info.
   if (AutoCompleteActive() && AutoCompleteRunCommand()) {
      return;
   }

   // turn things over the auto-complete to handle the display of list-symbols
   retryCount := 0;
   orig_wid := p_window_id;
   _str errorArgs[];
   do {
      status = AutoCompleteUpdateInfo(alwaysUpdate:true,
                                      forceUpdate:DisplayImmediate,
                                      doInsertLongest:false,
                                      OperatorTyped,
                                      prefixMatch,
                                      idexp_info,
                                      expected_type,
                                      rt,
                                      expected_name,
                                      selectMatchingItem,
                                      doListParameters,
                                      isFirstAttempt,
                                      errorArgs
                                      );
      if (status < 0) {
         msg := _CodeHelpRC(status, errorArgs);
         if (msg != "" && !OperatorTyped) {
            if (_haveContextTagging() && 
                length(idexp_info.lastid) > 1 && 
                !(_GetCodehelpFlags(lang) & VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES) &&
                isFirstAttempt && (_GetCodehelpFlags(lang) & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY)) {
               complete_key := _where_is("codehelp_complete");
               if (complete_key != "") {
                  complete_msg := "   - Press "complete_key" again to force pattern matching.";
                  msg :+= complete_msg;
               }
            }
            message(msg);
         }
         if (DisplayImmediate && retryCount==0) {
            if (_MaybeRetryTaggingWhenFinished()) {
               if (_iswindow_valid(orig_wid)) {
                  activate_window(orig_wid);
                  retryCount++;
                  continue;
               }
            }
         }
      }
   } while (false);
}

/**
 * Replace the word with completed or partially completed word
 * for each active cursor (if multiple cursors are active) 
 *  
 * @param lastid                 original word under cursor
 * @param lastid_len             length of original word
 * @param longest_prefix         longest prefix match found
 * @param longest_case_prefix    longest case-sensitive prefix match found
 * @param num_matches            number of matches found
 */
static void do_complete_replace_word(_str lastid, int lastid_len,
                                     _str &longest_prefix,
                                     _str longest_case_prefix,
                                     int num_matches,
                                     int depth=1)
{
   if (_chdebug) {
      isay(depth, "do_complete_replace_word: lastid="lastid" lastid_len="lastid_len);
      isay(depth, "do_complete_replace_word: longest_prefix="longest_prefix);
      isay(depth, "do_complete_replace_word: longest_case_prefix="longest_case_prefix);
   }
   target_wid := p_window_id;
   already_looping := _MultiCursorAlreadyLooping();
   multicursor     := !already_looping && _MultiCursor();

   for (ff:=true;;ff=false) {
      if (multicursor) {
         if (!_MultiCursorNext(ff)) {
            break;
         }
      }

      // replace the word with completed or partially completed word
      if (length(longest_prefix)+1 >= lastid_len && longest_prefix:!=lastid) {
         p_col = p_col-lastid_len;
         orig_col := p_col;
         word_col := 0;
         word := cur_identifier(word_col,VSCURWORD_FROM_CURSOR);
         if (_chdebug) {
            isay(depth, "do_complete_replace_word: word="word" word_col="word_col" line="p_line" col="p_col);
         }
         if (word_col <= orig_col &&  word_col + _rawLength(word) >= orig_col) {
            p_col = word_col;
            if (_GetCodehelpFlags() & VSCODEHELPFLAG_REPLACE_IDENTIFIER) {
               if (_chdebug) {
                  isay(depth, "do_complete_replace_word H"__LINE__": delete whole identifier, word="word);
               }
               _delete_text(_rawLength(word));
            } else {
               if (_chdebug) {
                  isay(depth, "do_complete_replace_word: delete lastid, lastid="lastid);
               }
               _delete_text(_rawLength(lastid));
            }
         }
         if (length(longest_case_prefix) > length(longest_prefix) && length(longest_case_prefix) >= lastid_len) {
            longest_prefix = longest_case_prefix;
         }
         if (_chdebug) {
            isay(depth, "do_complete_replace_word: insert longest prefix="longest_prefix);
         }
         _insert_text(longest_prefix);
      //} else if (num_matches <= 1 || length(longest_prefix) == lastid_len) {
      //   if (!expand_alias("","",alias_filename(true,false))) return;
      }

      if (!multicursor) {
         if (!already_looping) _MultiCursorLoopDone();
         break;
      }
      if (target_wid!=p_window_id) {
         _MultiCursorLoopDone();
         break;
      }
   }

   activate_window(target_wid);
}

/**
 * Attempt to complete the tag prefix under the cursor with the
 * longest matching tag.  If there are multiple matches, bring
 * up the list symbols dialog to help to user select one.
 */
void _do_complete(bool isFirstAttempt=true)
{
   //say("_do_complete()");

   // check the current context, don't try it within string or comment
   cfg := _clex_find(0,'g');
   if (_in_comment() || (cfg==CFG_STRING && _LanguageInheritsFrom("cob"))) {
      save_pos(auto p);
      left();cfg=_clex_find(0,'g');
      if (_in_comment() || cfg==CFG_STRING) {
         if (_expand_alias()) {
            message("Tag completion not supported in string or comment");
         }
         restore_pos(p);
         return;
      }
      restore_pos(p);
   }

   // do we have a list-tags or proc-search function?
   lang := p_LangId;
   if (!_istagging_supported(lang)
       && !_LanguageInheritsFrom("xml") && !_LanguageInheritsFrom("dtd")   // I bet we won't need this for long..
       ) {
      _expand_alias();
      return;
   }

   // do we have tag files set up for this extension?
   MaybeBuildTagFile(lang);

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   // match the tag at the current position
   lastid := "";
   tag_clear_matches();
   _str errorArgs[];
   VS_TAG_RETURN_TYPE visited:[];

   // using Context Tagging(R) to find matches
   sc.lang.ScopedTimeoutGuard timeout(def_auto_complete_timeout_forced);
   caseSensitive := (_GetCodehelpFlags(lang) & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE)? true:false;
   num_matches := context_match_tags(errorArgs,
                                     lastid,
                                     find_parents:false,
                                     def_tag_max_find_context_tags,
                                     exact_match:false, caseSensitive,
                                     visited, depth:0, 
                                     SE_TAG_FILTER_ANYTHING, 
                                     SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL);

   // force list symbols if it appears that the list was truncated
   timedOut := _CheckTimeout();
   if (num_matches >= def_tag_max_find_context_tags || timedOut) {
      if (_chdebug > 0) {
         say("_do_complete: timed_out, going to list_symbols");
      }
      timeout.restore();
      _macro_delete_line();
      _do_list_members(OperatorTyped:false,
                       DisplayImmediate:true,
                       prefixMatch:true,
                       selectMatchingItem:true,
                       doListParameters:false,
                       isFirstAttempt,
                       visited);
      return;
   }

   if (_chdebug) {
      say("_do_complete: ctx_match_tags -> num_matches="num_matches);
   }

   // ran out of time and did not find anything
   if (timedOut && num_matches <= 0) {
      timeout.restore();
      status := VSCODEHELPRC_NO_SYMBOLS_FOUND;
      if (num_matches < 0) status = num_matches;
      if (errorArgs._length()==0) errorArgs[1]=lastid;
      msg := _CodeHelpRC(status, errorArgs);
      if (_expand_alias() && msg!="") {
         message(msg);
      }
      return;
   }

   // look for exact matches in the match set
   lastid_len := length(lastid);
   longest_prefix := "";
   longest_case_prefix := "";
   longest_prefix_case_is_same := true;
   longest_caption := "";
   if (num_matches > 0) {
      tag_find_longest_prefix_match(lastid, 
                                    longest_prefix, 
                                    longest_case_prefix, 
                                    longest_caption, 
                                    longest_prefix_case_is_same);
      if (_chdebug) {
         say("_do_complete H"__LINE__": lastid="lastid);
         say("_do_complete H"__LINE__": longest_prefix="longest_prefix);
         say("_do_complete H"__LINE__": longest_case_prefix="longest_case_prefix);
         say("_do_complete H"__LINE__": case_is_same="longest_prefix_case_is_same);
      }
   }

   // if there were no matches, look for pattern matching matchestransposed character matches
   complete_subword_option := AutoCompleteGetSubwordPatternOption(p_LangId);
   if (!timedOut && 
       num_matches <= 0 && 
       lastid_len > 1 &&
       _haveContextTagging() && 
       complete_subword_option != AUTO_COMPLETE_SUBWORD_MATCH_NONE && 
       !(_GetCodehelpFlags(lang) & VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES)) {

      save_pos(auto p);
      longest_prefix = "";
      longest_prefix_case_is_same = true;
      pattern_flags := AutoCompleteGetSubwordPatternFlags(p_LangId);
      codehelpFlags := _GetCodehelpFlags(p_LangId);
      if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_WORKSPACE_ONLY) {
         pattern_flags |= SE_TAG_CONTEXT_ONLY_WORKSPACE;
         if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_AUTO_UPDATED) {
            pattern_flags |= SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED;
         }
         if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_COMPILER) {
            pattern_flags |= SE_TAG_CONTEXT_INCLUDE_COMPILER;
         }
         if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_RELAX_ORDER) {
            pattern_flags |= SE_TAG_CONTEXT_MATCH_RELAX_ORDER;
         }
      }
      if (isFirstAttempt && (_GetCodehelpFlags(lang) & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY)) {
         pattern_flags |= SE_TAG_CONTEXT_ONLY_CONTEXT|SE_TAG_CONTEXT_ALLOW_LOCALS;
      }

      num_pattern_matches := context_match_tags(errorArgs,
                                                lastid,
                                                find_parents:false,
                                                def_tag_max_find_context_tags,
                                                exact_match:false, 
                                                caseSensitive,
                                                visited, 0,
                                                SE_TAG_FILTER_ANYTHING,
                                                SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_MATCH_FIRST_CHAR|pattern_flags);

      timedOut = _CheckTimeout();
      if (!timedOut && num_pattern_matches <= 0) {
         all_pattern_matches := context_match_tags(errorArgs,
                                                   lastid,
                                                   find_parents:false,
                                                   def_tag_max_find_context_tags,
                                                   exact_match:false, 
                                                   caseSensitive,
                                                   visited, 0,
                                                   SE_TAG_FILTER_ANYTHING,
                                                   SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL|pattern_flags);
         timedOut = _CheckTimeout();
         if (all_pattern_matches > 0) {
            num_pattern_matches = all_pattern_matches;
         }
      }

      if (!timedOut && num_pattern_matches < def_tag_max_find_context_tags) {
         if (_chdebug) {
            say("_do_complete: ctx_match_tags[PATTERN] -> num_matches="num_pattern_matches);
         }
         // look for matches with transposed characters
         restore_pos(p);

         // look for matches with transposed characters
         num_patterns_found := tag_find_longest_pattern_match(lastid, 
                                                              caseSensitive, 
                                                              pattern_flags, 
                                                              longest_prefix, 
                                                              longest_caption, 
                                                              longest_prefix_case_is_same);
         num_matches = num_pattern_matches;
         if (num_patterns_found > 0) {
            // we do not want to replace lastid with a prefix that does not match the pattern
            num_matches = num_patterns_found;
            if (!tag_matches_symbol_name_pattern(lastid, longest_prefix, exact_match:false, caseSensitive, pattern_flags)) {
               longest_prefix = "";
               if (_chdebug) {
                  say("_do_complete H"__LINE__": voiding out longest prefix because it does not match pattern");
               }
            }
            if (_chdebug) {
               say("_do_complete H"__LINE__": lastid="lastid);
               say("_do_complete H"__LINE__": longest_prefix="longest_prefix);
               say("_do_complete H"__LINE__": case_is_same="longest_prefix_case_is_same);
               say("_do_complete H"__LINE__": num_patterns_found="num_patterns_found);
            }
         }
      }
   }

   // if there were no matches, look for transposed character matches
   if (!timedOut && 
       num_matches <= 0 && 
       length(longest_prefix) < lastid_len && 
       lastid_len > 2 &&
       !(_GetCodehelpFlags(lang) & VSCODEHELPFLAG_COMPLETION_NO_FUZZY_MATCHES)) {
      for (i:=lastid_len-1; i>0; i--) {
         orig_col := p_col;
         save_pos(auto p);
         visited = null;
         word_col := 1;
         word := cur_identifier(word_col,VSCURWORD_BEFORE_CURSOR);
         if (word != "") {
            p_col = word_col+i;
            word = "";
         }
         num_fuzzy_matches := context_match_tags(errorArgs,
                                                 word,false,
                                                 def_tag_max_find_context_tags,
                                                 false, caseSensitive,
                                                 visited, 0,
                                                 SE_TAG_FILTER_ANYTHING,
                                                 SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL);
         if (_chdebug) {
            say("_do_complete: ctx_match_tags[FUZZY i="i"] -> num_matches="num_fuzzy_matches);
         }
         restore_pos(p);
         if (_CheckTimeout()) {
            if (_chdebug) {
               say("_do_complete: ctx_match_tags[FUZZY i="i"] TIMEOUT");
            }
            break;
         }
         if (num_fuzzy_matches >= def_tag_max_find_context_tags) {
            if (_chdebug) {
               say("_do_complete: ctx_match_tags[FUZZY i="i"] TOO MANY SYMBOL MATCHES");
            }
            break;
         }

         // look for matches with transposed characters
         num_fuzzy_found := tag_find_longest_fuzzy_match(lastid, 
                                                         caseSensitive, 
                                                         i, 
                                                         longest_prefix, 
                                                         longest_caption, 
                                                         longest_prefix_case_is_same);
         if (num_fuzzy_found > 0) {
            num_matches = num_fuzzy_found;
            if (_chdebug) {
               say("_do_complete H"__LINE__": lastid="lastid);
               say("_do_complete H"__LINE__": longest_prefix="longest_prefix);
               say("_do_complete H"__LINE__": case_is_same="longest_prefix_case_is_same);
               say("_do_complete H"__LINE__": num_fuzzy_found="num_fuzzy_found);
            }
            break;
         }
      }
   }

   // no matches
   if (num_matches <= 0) {
      status := VSCODEHELPRC_NO_SYMBOLS_FOUND;
      if (num_matches < 0) status = num_matches;
      errorArgs[0]=errorArgs[1]=lastid;
      msg := _CodeHelpRC(status, errorArgs);
      if (_expand_alias() && msg!="") {
         // show them that they can hit Ctrl+Space again
         if (lastid_len > 1 && _haveContextTagging() && 
             complete_subword_option != AUTO_COMPLETE_SUBWORD_MATCH_NONE && 
             !(_GetCodehelpFlags(lang) & VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES) &&
             isFirstAttempt && (_GetCodehelpFlags(lang) & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY)) {
            complete_key := _where_is("codehelp_complete");
            if (complete_key != "") {
               complete_msg := "   - Press "complete_key" again to force pattern matching.";
               msg :+= complete_msg;
            }
         }
         message(msg);
      }
      return;
   }

   // if they are banging on Ctrl+Space to complete something and erase the 
   // remaining identifier to the right of the cursor, try to use the remaining id
   if (lastid == longest_prefix && lastid==longest_caption && longest_prefix_case_is_same) {
      tagname := cur_identifier(auto col);
      if (length(tagname) > length(lastid) && beginsWith(tagname, lastid)) {
         if (isFirstAttempt) {
            complete_key := _where_is("codehelp_complete");
            if (complete_key != "") {
               complete_msg := "Identifier to the left of the cursor is already complete.  Press "complete_key" again to force '":+tagname:+"' to be replaced with '":+longest_prefix:+"'";
               message(complete_msg);
            }
         } else {
            lastid = tagname;
            lastid_len = length(longest_prefix);
            if (_chdebug) {
               say("_do_complete H"__LINE__": forcing entire identifer (":+tagname:+") to be replaced");
            }
         }
      }
   }

   // replace the word with completed or partially completed word
   if (length(longest_prefix)+1 >= lastid_len && longest_prefix != lastid && longest_prefix_case_is_same) {
      do_complete_replace_word(lastid, lastid_len, longest_prefix, longest_case_prefix, num_matches);
   } else if (num_matches <= 1 || length(longest_prefix) == lastid_len) {
      if (!_expand_alias("","",alias_filename(true,false))) return;
   }

   // force list symbols if the result is not an exact tag match
   if ((num_matches > 1 && length(longest_caption) > length(longest_prefix)) ||
       (num_matches >= 1 && longest_prefix == "")) {
      _macro_delete_line();
      _do_list_members(OperatorTyped:false,
                       DisplayImmediate:true,
                       syntaxExpansionWords:null,
                       expected_type:null,
                       auto rt,
                       expected_name:null,
                       prefixMatch:true,
                       selectMatchingItem:true,
                       doListParameters:false,
                       isFirstAttempt,
                       visited);
   }
}

void _update_list_width(int initial_width=0)
{
   // get the size of the visible screen
   int vx, vy, vwidth, vheight;
   _GetVisibleScreen(vx,vy,vwidth,vheight);

   // adjust width of form to accomodate longer captions
   int form_width   = _dx2lx(p_xyscale_mode, vwidth);
   int border_width = 360/*scrollbar*/ + 360/*bitmap*/ + p_LevelIndent;
   max_width := 0;
   if (initial_width > border_width) {
      max_width = initial_width - border_width;
   }

   // go through each category and each list of items underneath
   cat_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (cat_index > 0) {
      // get the width of the caption
      int caption_width = _text_width(_TreeGetCaption(cat_index));
      if (caption_width > max_width) {
         max_width = caption_width;
      }

      // go through the items underneath
      tag_index := _TreeGetFirstChildIndex(cat_index);
      while (tag_index > 0) {
         // check the width of this caption
         caption_width = _text_width(_TreeGetCaption(tag_index));
         if (caption_width > max_width) {
            max_width = caption_width;
         }
         // next please
         tag_index = _TreeGetNextSiblingIndex(tag_index);
      }

      // next category please
      cat_index = _TreeGetNextSiblingIndex(cat_index);
   }

   // clip form if it is too wide
   if (max_width+border_width > form_width) {
      max_width = form_width - border_width;
   }

   // adjust the with of the tree and the form
   p_width = max_width+border_width;
   _nocheck _control ctlsizebar;
   p_active_form.ctlsizebar.p_width=p_width;
   p_active_form.p_width=p_active_form._left_width()*2+p_width;
}

int _update_list_height(int initial_height=0, bool snap=true, bool countLines=false)
{
   // get the size of the visible screen
   int vx, vy, vwidth, vheight;
   _GetVisibleScreen(vx,vy,vwidth,vheight);

   // adjust width of form to accomodate longer captions
   int form_height = _dy2ly(p_xyscale_mode, vheight);

   // count the number of lines in the tree
   line_count := 0;
   if (countLines) {
      show_children := bm1 := bm2 := line_number := tree_flags := 0;
      cat_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (cat_index > 0) {
         // go through the items underneath
         tag_index := _TreeGetFirstChildIndex(cat_index);
         while (tag_index > 0) {
            _TreeGetInfo(tag_index, show_children, bm1, bm2, tree_flags, line_number, TREENODE_HIDDEN);
            if (!(tree_flags & TREENODE_HIDDEN)) {
               line_count++;
            }
            tag_index = _TreeGetNextSiblingIndex(tag_index);
         }

         // next category please
         _TreeGetInfo(cat_index, show_children, bm1, bm2, tree_flags, line_number, TREENODE_HIDDEN);
         if (!(tree_flags & TREENODE_HIDDEN)) {
            line_count++;
         }
         cat_index = _TreeGetNextSiblingIndex(cat_index);
      }
   }

   // get the original form height, and last sizing state
   int y = initial_height;
   if (y==0 || countLines) {
      _str h=_moncfg_retrieve_value(p_active_form.p_name:+".p_height");
      if (isinteger(h)) y=(int)h;
   }

   // compute the new size
   int delta_h = _twips_per_pixel_y() * p_line_height;
   if (line_count>=1 && y > delta_h*line_count) {
      if (line_count < 4) line_count = 4;
      y = delta_h*line_count;
   } else if (y < delta_h*4) {
      y = delta_h*4;
   } else if (y > (vheight*_twips_per_pixel_y()*3) intdiv 4) {
      y = (vheight*_twips_per_pixel_y()*3) intdiv 4;
   }
   if (snap) {
      y=((y+delta_h intdiv 2) intdiv delta_h) * delta_h + _top_height()*2;
   }

   // update the tree and form height
   p_height = y;
   _nocheck _control ctlsizebar;
   p_active_form.ctlsizebar.p_y = p_height;
   p_active_form.p_height = p_active_form.ctlsizebar.p_y + p_active_form.ctlsizebar.p_height;
   return y;
}

/*
   PARAMETERS
      editorctl_wid     Coordinates text_x and text_y are relative to this window
      form_wid          The form to move.
      text_x,text_y     Prefered position of form in pixels relative to editorctl_wid
      text_height       Height of form in pixels
*/
static void _PositionNoFocusForm(int editorctl_wid,int form_wid,
                                 int text_x,int text_y,int text_height,
                                 int FunctionHelp_form_wid,
                                 bool prefer_positioning_above=false)
{
   int x=text_x;
   int y=text_y+text_height;
   _map_xy(editorctl_wid,0,x,y);
   if (FunctionHelp_form_wid) {
      fx := 0;
      int fy=FunctionHelp_form_wid.p_y;
      fy=_ly2dy(SM_TWIP,fy);
      if (y<=fy) {
         y=fy+_ly2dy(SM_TWIP,FunctionHelp_form_wid.p_height);
      }
   }

   int vx, vy, vwidth, vheight;
   //editorctl_wid._GetVisibleScreen(vx,vy,vwidth,vheight);
   _GetVisibleScreenFromPoint(x,y,vx,vy,vwidth,vheight);
   if (x<vx) x=vx;  // Don't display text off the screen
   int height=_ly2dy(form_wid.p_xyscale_mode,form_wid.p_height);
   if ((y+height>=vy+vheight && text_y>=height) ||
       (prefer_positioning_above && y-height>=vy) ||
       (y+height>=vy+vheight && text_y<height && (text_y-height > (vy+vheight)-(y+height)))) {
      // Display this dialog above
      x=text_x;
      y=text_y-height;
      _map_xy(editorctl_wid,0,x,y);

      if (FunctionHelp_form_wid) {
         int ty=y+_ly2dy(SM_TWIP,form_wid.p_height);
         fx := 0;
         int fy=FunctionHelp_form_wid.p_y;
         fy=_ly2dy(SM_TWIP,fy);
         if (ty>fy) {
            y-=ty-fy;
            //y=fy+_ly2dy(SM_TWIP,FunctionHelp_form_wid.p_height);
         }
      }
   }
   int width=_lx2dx(form_wid.p_xyscale_mode,form_wid.p_width);
   if (x+width>=vx+vwidth) {
      x=vx+vwidth-width;
   }
   _dxy2lxy(form_wid.p_xyscale_mode,x,y);

   junk := 0;
   form_wid._get_window(junk,junk,width,height);
   form_wid._move_window(x,y,width,height);
}

/**
 * Timer callback for updating function parameter help
 */
void _CodeHelp(bool AlwaysUpdate=false)
{
   if (gpending_switchbuf) {
      gpending_switchbuf=false;
      buf_name:=gpending_switchbuf_buf_name;
      if (_isUnix()) {
          // If this buffer name has a valid path
          if (substr(buf_name,1,1)=="/") {
             _str path;
             if (_get_filetype_dir_parts(buf_name,path,auto ft_file)) {
             } else {
                path = _strip_filename(buf_name,'N');
             }
             // We don't want buffer order changed when if build window
             // buffer is activate so here we change the load options before
             // calling cd().
             old_load_options := def_load_options;
             def_load_options=stranslate(lowcase(def_load_options)," ","+bp");
             cwd := getcwd();
             _maybe_append_filesep(cwd);
             _maybe_append_filesep(path);
             if (!_file_eq(path,cwd)) {
                cd("-a "_maybe_quote_filename(path),"q");
             }
             def_load_options=old_load_options;
          }
      } else {
         // If this buffer name has a valid path
         if ((substr(buf_name,2,1)==":" && substr(buf_name,3,1)=='\') ||
             (substr(buf_name,1,2)=='\\' && pos('\',buf_name,4)!=0)) {
            _str path;
            if (_get_filetype_dir_parts(buf_name,path,auto ft_file)) {
            } else {
               path = _strip_filename(buf_name,'N');
            }
            // We don't want buffer order changed when if build window
            // buffer is activate so here we change the load options before
            // calling cd().
            old_load_options := def_load_options;
            def_load_options=stranslate(lowcase(def_load_options)," ","+bp");
            cwd := getcwd();
            _maybe_append_filesep(cwd);
            _maybe_append_filesep(path);
            if (!_file_eq(path,cwd)) {
               cd("-a "_maybe_quote_filename(path),"q");
            }
            def_load_options=old_load_options;
         }
      }
   }
   if (!_haveContextTagging()) {
      return;
   }
   if (!ginFunctionHelp) return;
   // check if the tag database is busy and we can't get a lock.
   dbName := _GetWorkspaceTagsFilename();
   if (tag_trylock_db(dbName)) {
      _SetTimeout(def_tag_max_list_members_time);
      still_in_code_help();
      _SetTimeout(0);
      tag_unlock_db(dbName);
   }
}

/**
 * Callback for updating list members when we switch buffers.
 */
void _switchbuf_code_help(_str old_buf_name, _str flag)
{
   if (def_switchbuf_cd && !p_IsTempEditor &&  p_window_id!=VSWID_HIDDEN) {
      if (_isEditorCtl(false)) {
         gpending_switchbuf=true;
         gpending_switchbuf_buf_name=p_buf_name;
      }
   }
   // on got focus
   if (flag=='W') {
      if (geditorctl_wid==p_window_id) {
         return;
      }
   }
   TerminateFunctionHelp(inOnDestroy:false, alsoTerminateAutoComplete:false);
}

static bool still_in_function_help(long idle)
{
   if (!_haveContextTagging()) {
      return false;
   }

   if (gFunctionHelp_MouseOver) {
      mou_get_xy(auto mx,auto my);
      in_rect := mx>=gFunctionHelp_MouseOverInfo.x && mx<gFunctionHelp_MouseOverInfo.x+gFunctionHelp_MouseOverInfo.width &&
                 my>=gFunctionHelp_MouseOverInfo.y && my<gFunctionHelp_MouseOverInfo.y+gFunctionHelp_MouseOverInfo.height;
      form_wid := _GetMouWindow();
      if (form_wid && _iswindow_valid(form_wid)) {
         form_wid=form_wid.p_active_form;
         if (form_wid==gFunctionHelp_form_wid) {
            return(false);
         }
      }

      wid   := gFunctionHelp_MouseOverInfo.wid;
      other := !_iswindow_valid(wid) ||
               !_AppActive() ||
               gFunctionHelp_MouseOverInfo.buf_id!=wid.p_buf_id ||
               gFunctionHelp_MouseOverInfo.LineNum!=wid.p_line ||
               gFunctionHelp_MouseOverInfo.col!=wid.p_col ||
               gFunctionHelp_MouseOverInfo.ScrollInfo!=wid._scroll_page();

      // pretend the mouse is in the function help dialog if they followed a link
      if (ginFunctionHelp && _iswindow_valid(gFunctionHelp_form_wid)) {
         HYPERTEXTSTACK stack = gFunctionHelp_form_wid.HYPERTEXTSTACKDATA();
         if (!in_rect && stack.HyperTextTop > 0) in_rect=true;
      }

      if (!in_rect || other) {
         TerminateFunctionHelp(inOnDestroy:false, alsoTerminateAutoComplete:false);
         return(true);
      }
      if (!gFunctionHelp_pending) {
         return(false);
      }
   } else if (gFunctionHelp_OnFunctionName) {
      if (point('s') < gFunctionHelp_FunctionNameOffset ||
          get_text(length(gFunctionHelp_starttext),gFunctionHelp_FunctionLineOffset) != gFunctionHelp_starttext) {
         TerminateFunctionHelp(inOnDestroy:false);
         return(true);
      }
   } else {
      if (point('s') < gFunctionHelp_FunctionLineOffset+length(gFunctionHelp_starttext) ||
          get_text(length(gFunctionHelp_starttext),gFunctionHelp_FunctionLineOffset) != gFunctionHelp_starttext) {
         TerminateFunctionHelp(inOnDestroy:false);
         return(true);
      }
   }

   if (gFunctionHelp_pending) {
      b := idle>=def_codehelp_idle;

      if (gFunctionHelp_MouseOver) {
         b=idle>=_default_option(VSOPTION_TOOLTIPDELAY)*100;
      }

      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      if (b && tag_trylock_db(dbName)) {
         if (gFunctionHelp_MouseOver) {
            typeless p;
            gFunctionHelp_MouseOverInfo.wid.save_pos(p);
            gFunctionHelp_MouseOverInfo.wid.restore_pos(gFunctionHelp_MouseOverInfo.OrigPos);
            _update_function_help();
            gFunctionHelp_MouseOverInfo.wid.restore_pos(p);
         } else {
            _update_function_help();
         }
         gFunctionHelp_pending=false;
         gFunctionHelp_InsertedParam=false;
         if (gFunctionHelp_OperatorTyped && ginFunctionHelp) {
            insert_space   := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN);
            insert_keyword := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS);
            gFunctionHelp_InsertedParam=maybe_insert_current_param(do_select:true, check_if_defined:true, insert_space, insert_keyword);
         }
         if (ginFunctionHelp && !gFunctionHelp_MouseOver &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS)) {
            maybe_list_arguments(true);
            if (gFunctionHelp_InsertedParam) {
               maybe_uninsert_current_param();
            }
         }
         tag_unlock_db(dbName);
      }
   } else {
      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      if (idle>=def_codehelp_key_idle && tag_trylock_db(dbName)) {
         _update_function_help();
         tag_unlock_db(dbName);
      } else {
         // Check if the cursor is under the the function help window
         text_x := 0;
         text_y := p_cursor_y+p_font_height-1;
         _map_xy(p_window_id,0,text_x,text_y);
         _dxy2lxy(SM_TWIP,text_x,text_y);
         if ( gFunctionHelp_form_wid ) {
            int y=gFunctionHelp_form_wid.p_y;
            if (text_y>y && text_y<y+gFunctionHelp_form_wid.p_height) {
               //gFunctionHelp_form_wid.p_visible=false;
            }
         }
      }
   }
   return(false);
}

static void still_in_code_help(bool ignoreIdle=false)
{
   orig_wid := p_window_id;
   focus_wid := _get_focus();

   if (ginFunctionHelp && gFunctionHelp_MouseOver) {
      if (!_iswindow_valid(gFunctionHelp_MouseOverInfo.wid)) {
         TerminateFunctionHelp(inOnDestroy:false, alsoTerminateAutoComplete:false);
         return;
      }
      focus_wid=gFunctionHelp_MouseOverInfo.wid;
   }

   if (!focus_wid) {
      TerminateFunctionHelp(inOnDestroy:false);
      if (_iswindow_valid(orig_wid)) p_window_id=orig_wid;
      return;
   }

   p_window_id=focus_wid;

   // IF this dialog was closed (close_window maybe) OR
   //    focus is not on editor control object OR
   //    object changed
   //    buffer id changed
   if ( !p_HasBuffer ||
        geditorctl_wid!=p_window_id ||
        geditorctl_wid.p_buf_id != geditorctl_buf_id ) {
      TerminateFunctionHelp(inOnDestroy:false);
      if (_iswindow_valid(orig_wid)) p_window_id=orig_wid;
      return;
   }
   idle := _idle_time_elapsed();
   if (ignoreIdle) idle += (def_codehelp_idle + def_memberhelp_idle);
   if (ginFunctionHelp && still_in_function_help(idle)) {
      if (_iswindow_valid(orig_wid)) p_window_id=orig_wid;
      return;
   }

   if (_iswindow_valid(orig_wid)) {
      p_window_id=orig_wid;
   }
}
/**
 * Is the list members dialog up?
 *
 * @param itemIsSelected   If list members is active, also check
 *                         if and selected in the list, return
 *                         false if nothing is selected.
 *
 * @return <code>true</code> if the list members dialog is active,
 *         <code>false</code> otherwise
 *  
 * @deprecated Use {@link AutoCompleteActive}
 */
bool CodeHelpActive(bool itemIsSelected=false)
{
   return false;
}

void XW_TerminateCodeHelp() 
{
   p_window_id.TerminateFunctionHelp(inOnDestroy:false);
}

void TerminateMouseOverHelp()
{
   p_window_id._KillMouseOverBBWin();
   if (gFunctionHelp_MouseOver) {
      p_window_id.TerminateFunctionHelp(inOnDestroy:false);
   }
}

void RefreshListHelp()
{
   p_window_id.AutoCompleteUpdateInfo(alwaysUpdate:false);
}

static int maybe_list_arguments(bool DisplayImmediate)
{
   // check the current context, don't try it within string or comment
   int cfg=_clex_find(0,'g');
   if (_in_comment()) {
      save_pos(auto p);
      left();cfg=_clex_find(0,'g');
      if (_in_comment()) {
         restore_pos(p);
         return(0);
      }
      restore_pos(p);
   }

   // check if we are in the scope of a function or statement
   if (!_in_function_scope() || _in_string() || !_haveContextTagging()) {
      return(0);
   }

   // first check if we have a find-arguments function
   // find-arguments is responsible for parameter type matching
   // and for listing javadoc paraminfo supplied arguments
   // find the function to match return types
   ar_index := _FindLanguageCallbackIndex("_%s_analyze_return_type");
   if (!ar_index) {
      return(0);
   }
   // obtain the expected parameter type
   i := gFunctionHelpTagIndex;
   n := gFunctionHelp_list._length();
   if (i>=0 && i<n) {
      expected_name := gFunctionHelp_list[i].ParamName;
      expected_type := gFunctionHelp_list[i].ParamType;
      arglist_type := get_arg_info_type_name(gFunctionHelp_list[i]);
      if (expected_type!="" && arglist_type!="define") {
         _do_list_members(OperatorTyped:false,
                          DisplayImmediate,
                          syntaxExpansionWords:null,
                          expected_type,
                          rt:null,
                          expected_name,
                          prefixMatch:false,
                          selectMatchingItem: DisplayImmediate,
                          doListParameters:true);
      }
      return(1);
   }
   return(0);
}

static bool maybe_insert_current_param(bool do_select=false,
                                       bool check_if_defined=true,
                                       bool insert_space=false,
                                       bool insert_keyword=false)
{
   if (!_haveContextTagging()) {
      return false;
   }
   // do not do selection if we are not configured to overtype it
   if (do_select && def_persistent_select!='D') {
      return(false);
   }
   // do not do anything if we already have a selection
   if (do_select && select_active()) {
      return(false);
   }

   // do not insert parameters inside strings or comments
   cfg := _clex_find(0,'g');
   if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
      return false;
   }
   numArgs := 0;
   param_keyword := "";
   i := gFunctionHelpTagIndex;
   n := gFunctionHelp_list._length();
   if (i>=0 && i<n) {
      param_name := gFunctionHelp_list[i].ParamName;
      param_keyword = gFunctionHelp_list[i].ParamKeyword;
      numArgs = gFunctionHelp_list[i].arglength._length()-1;
      if (param_name!="" && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
         VS_TAG_IDEXP_INFO idexp_info;
         tag_idexp_info_init(idexp_info);

         struct VS_TAG_RETURN_TYPE visited:[];
         status := _Embeddedget_expression_info(false, auto ext, idexp_info, visited);

         if (!status && idexp_info.lastid!=param_name &&
             (!do_default_is_builtin_type(param_name)) &&
             (idexp_info.prefixexp=="" || (_LanguageInheritsFrom("cob") && lowcase(idexp_info.prefixexp)=="using")) &&
             (p_col==idexp_info.lastidstart_col+_rawLength(idexp_info.lastid)) &&
             (idexp_info.lastid=="" || pos(idexp_info.lastid,param_name,1,(p_EmbeddedCaseSensitive? "":"i"))==1)) {
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
            tag_push_matches();

            // If this is a template class, only look for arguments that are local parameters
            filter_flags  :=  SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_DEFINE|SE_TAG_FILTER_ENUM;
            context_flags := SE_TAG_CONTEXT_ALLOW_LOCALS;
            arglist_type  := get_arg_info_type_name(gFunctionHelp_list[i]);
            if (tag_tree_type_is_class(arglist_type)) {
               filter_flags   =  SE_TAG_FILTER_ANY_DATA;
               context_flags |= SE_TAG_CONTEXT_ONLY_LOCALS;
            }

            if (check_if_defined) {
               status=_Embeddedfind_context_tags(idexp_info.errorArgs,"",param_name,
                                                 idexp_info.lastidstart_offset,idexp_info.info_flags,idexp_info.otherinfo,
                                                 false,def_tag_max_list_matches_symbols,
                                                 true,p_EmbeddedCaseSensitive,
                                                 filter_flags, context_flags,
                                                 visited, 0);
               // verify that at least one of the matches is the same language mode
               if (status >= 0 && tag_get_num_of_matches() > 0) {
                  have_lang_match := false;
                  num_matches := tag_get_num_of_matches();
                  for (j:=1; j<=num_matches; j++) {
                     tag_get_detail2(VS_TAGDETAIL_match_language_id, j, auto match_lang);
                     if (match_lang == p_LangId) {
                        have_lang_match = true;
                        break;
                     }
                  }
                  if (!have_lang_match) {
                     tag_clear_matches();
                  }
               }
            }
            if (status >= 0 && tag_get_num_of_matches() > 0) {
               p_col=idexp_info.lastidstart_col;
               _macro('m',_macro('s'));
               count := _rawLength(idexp_info.lastid);
               if (count) {
                  _delete_text(count);
                  _macro_call("_delete_text",count);
               }
               if (insert_space) {
                  _macro_call("_insert_text"," ");
                  _insert_text(" ");
               }
               if (insert_keyword && length(param_keyword) > 0) {
                  _macro_call("_insert_text", param_keyword:+" ");
                  _insert_text(param_keyword:+" ");
               }
               _macro_call("_insert_text",param_name);
               start_col := p_col;
               _insert_text(param_name);
               end_col := p_col;
               if (do_select) {
                  _macro_call("_select_char","","C");
                  p_col = start_col;
                  _select_char('','C');
                  p_col = end_col;
                  _select_char('','C');
               }
               // let the user know what happened
               notifyUserOfFeatureUse(NF_INSERT_MATCHING_PARAMETERS);
               tag_pop_matches();
               return(true);
            }

            // clean up temporary match set
            tag_pop_matches();
         }
      }
   }
   if (insert_space && numArgs>=1) {
      _macro('m',_macro('s'));
      _macro_call("_insert_text"," ");
      _insert_text(" ");
   }
   if (insert_keyword && length(param_keyword) > 0) {
      _macro_call("_insert_text", param_keyword:+" ");
      _insert_text(param_keyword:+" ");
   }
   return(false);
}

// defeat auto-insert parameter if parameter help is active and
// the parameter inserted is not even a prefix match.
static void maybe_uninsert_current_param(bool terminateList=false)
{
   if (!ginFunctionHelp || gFunctionHelp_pending || !select_active() ||
       !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) ||
       !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
      return;
   }
   if (terminateList) {
      _macro_call("maybe_delete_selection");
      maybe_delete_selection();
      gFunctionHelp_InsertedParam=false;
      return;
   }
}

void maybe_dokey(_str key)
{
   if (_QReadOnly()) {
      kt_index := last_index('','k');
      int command_index=eventtab_index(_default_keys,p_mode_eventtab,event2index(key));
      typeless arg2="";
      parse name_info(command_index) with "," arg2 ",";
      if ( arg2=="" ) {
         arg2=0;
      }
      int iscommand=(name_type(command_index) & COMMAND_TYPE);
      if (iscommand && ! ((arg2&VSARG2_EDITORCTL) &&
                          (arg2&VSARG2_READ_ONLY)
                         )

         ) {
         return;
      }

   }
   last_event(key);
   call_key(key);
}

// NOTE: If 'key' is bound to a macro that closes the current
// window and leaves focus in another window, especially one
// that is not an editor control, and the window ID found in
// geditorctl_wid is recycled, we may add the event tab back
// to the wrong window.
static DoDefaultKey(_str key,bool doTerminate=true)
{
   last_index(prev_index('','C'),'C');
   //orig_eventtab=p_eventtab;
   //p_eventtab=0;
   _RemoveEventtab(defeventtab codehelp_key_overrides);
   if (doTerminate) {
      maybe_dokey(key);
      if (ginFunctionHelp && _iswindow_valid(geditorctl_wid)) {
         _AddEventtab(defeventtab codehelp_key_overrides);
      }
   } else {
      maybe_dokey(key);
      if (ginFunctionHelp && _iswindow_valid(geditorctl_wid)) {
         //p_eventtab=orig_eventtab;
         _AddEventtab(defeventtab codehelp_key_overrides);
      }
   }
}

void codehelp_keyin(_str key)
{
   // workaround for codehelp_key_overrides eventtable for callback enabled keys
   if (OvertypeListenerKeyin(key)) return;
   AutoBracketKeyin(key);
}

bool codehelp_at_start_of_parameter()
{
   // check if we are at the start of an argument
   save_pos(auto p);
   left();
   skip_status := _clex_skip_blanks('-h');
   if (!skip_status && pos(get_text(), "(,[<=")) {
      restore_pos(p);
      return true;
   }
   restore_pos(p);
   return false;
}

bool codehelp_at_end_of_comment(_str lastid_prefix="")
{
   // check if the characters ahead of the cursor are part of a comment
   save_pos(auto p);
   for (i:=0; i<=length(lastid_prefix); i++) left();
   if (p_col <= 1) {
      restore_pos(p);
      return false;
   }
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   search("[^ \t\v\r\n]", '-r');
   in_comment := (_clex_find(0, 'g') == COMMENT_CLEXFLAG);
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return in_comment;
}

/**
 * Process keyboard event occuring while function help or code
 * help is active.  Maps UP/DOWN to scrolling up/down the list, etc.
 */
void codehelp_key()
{
   //say("codehelp_key: last="event2name(last_event()));
   _macro_delete_line();
   _macro('m',_macro('s'));
   _nocheck _control ctltree;
   doTerminate := false;
   key := last_event();
   unique := false;
   index := 0;
   status := 0;

   // do not allow file to be modified if it is read-only
   if (_QReadOnly()) {
      if ((length(key)==1 && _asc(_maybe_e2a(key))>=27) || (key==name2event("C- "))) {
         orig_wid := p_window_id;
         int orig_actapp=def_actapp;
         def_actapp=0;
         status = _readonly_error(0,false);
         def_actapp=orig_actapp;
         if (status) return;
         if (_QReadOnly()) return;
         if (!_iswindow_valid(orig_wid)) return;
         p_window_id = orig_wid;
      }
   }

   //say("codehelp_key: key="key"=");
   if (length(key)==1 && _asc(_maybe_e2a(key))>=27 &&
       (key!=" " || (_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE))
      ) {
      still_in_code_help();
      int cfg = _clex_find(0,'g');
      if (ginFunctionHelp && !gFunctionHelp_pending &&
          gFunctionHelp_InsertedParam && key:==")" &&
          get_text(1, (int)point('s')-1) != " " &&
          get_text(1, (int)point('s')-1) != "(" &&
          (cfg!=CFG_STRING && cfg!=CFG_COMMENT) &&
          !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
         // function help is active, but they type ')' in function help
         // still insert the padding space before the paren
         _macro_call("_insert_text"," ");
         _insert_text(" ");
      } else if (ginFunctionHelp && !gFunctionHelp_pending &&
                 gFunctionHelp_OperatorTyped && key:==")" &&
                 get_text(1, (int)point('s')-1) != " " &&
                 get_text(1, (int)point('s')-1) != "(" &&
                 (cfg!=CFG_STRING && cfg!=CFG_COMMENT) &&
                 !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
         // function help is active, but they type ')' in function help
         // still insert the padding space before the paren
         _macro_call("_insert_text"," ");
         _insert_text(" ");
      }

      if (!doTerminate || key:!=" " || !(_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE)) {

         if (gFunctionHelp_InsertedParam &&
             ginFunctionHelp && !gFunctionHelp_pending) {
            if (pos(key,"`\'\"~!")) {
               maybe_uninsert_current_param(true);
            } else if (pos('[,|)>]',key,1,'r') || (key==" " && _LanguageInheritsFrom("cob"))) {
               _macro_call("maybe_deselect");
               maybe_deselect();    // deselect the auto-inserted param
            }
         }
         DoDefaultKey(key,doTerminate);

         gFunctionHelp_InsertedParam=false;
         if (ginFunctionHelp && !gFunctionHelp_pending) {
            // get next parameter for argument completion
            if (key=="|" && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
               _update_function_help();
               gFunctionHelp_InsertedParam=maybe_insert_current_param(do_select:true, check_if_defined:true);
            } else if (key==",") {
               _update_function_help();
               insert_space   := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA);
               insert_keyword := !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS);
               gFunctionHelp_InsertedParam=maybe_insert_current_param(do_select:true, check_if_defined:true, insert_space, insert_keyword);
            } else if (key==" " && _LanguageInheritsFrom("cob") &&
                       (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
               _update_function_help();
               gFunctionHelp_InsertedParam=maybe_insert_current_param(do_select:true, check_if_defined:true, insert_space:false);
            }
         }

         // display auto-list-members for parameter information
         if (ginFunctionHelp && !gFunctionHelp_pending && _haveContextTagging() &&
            (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
            ((key=="," || key=="|") || 
             (key=="=" && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_VALUES)) ||
             (key==" " && _LanguageInheritsFrom("cob")) ||
             ((key==" " || key==ENTER) && codehelp_at_start_of_parameter() && AutoCompleteDoRestartListParameters()))) {
            _update_function_help();
            maybe_list_arguments(false);
            if (gFunctionHelp_InsertedParam) {
               maybe_uninsert_current_param();
            }
         }
      }
      return;
   }
   function_help_wid := 0;
   switch (key) {
   case C_I:
   case UP:
      still_in_code_help();
      DoDefaultKey(key);
      return;
   case C_K:
   case DOWN:
      still_in_code_help();
      DoDefaultKey(key);
      return;
   case PGUP:
      still_in_code_help();
      DoDefaultKey(key);
      return;
   case PGDN:
      still_in_code_help();
      DoDefaultKey(key);
      return;

   case TAB:
   case ENTER:
      still_in_code_help();
      {
         had_auto_param := false;
         if (ginFunctionHelp && !gFunctionHelp_pending && gFunctionHelp_InsertedParam) {
            had_auto_param = select_active()!=0;
            _macro_call("maybe_deselect");
            maybe_deselect();    // deselect the auto-inserted param
            gFunctionHelp_InsertedParam=false;
            _update_function_help();
            return;
         }
         DoDefaultKey(key,doTerminate);
         // were we in list help?
         was_in_list_help := AutoCompleteDoRestartListParameters();
         // maybe insert matching parameter name
         if (had_auto_param && gFunctionHelp_OperatorTyped &&
             ginFunctionHelp && !gFunctionHelp_pending &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
            _update_function_help();
            if (ginFunctionHelp && !gFunctionHelp_pending) {
               maybe_insert_current_param(do_select:true);
            }
         }
         // display auto-list-members for parameter information
         if (ginFunctionHelp && !gFunctionHelp_pending && was_in_list_help && codehelp_at_start_of_parameter()) {
            _update_function_help();
            maybe_list_arguments(false);
         }
         return;
      }
      if (ginFunctionHelp && !gFunctionHelp_pending && select_active() &&
          (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
          (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION) &&
          gFunctionHelp_InsertedParam) {
         _macro_call("maybe_deselect");
         maybe_deselect();  // deselect the auto-inserted param
      }
      DoDefaultKey(key,true);
      return;

   case C_G:
      if (!iscancel(key)) {
         DoDefaultKey(key,false /* don't terminate */);
         return;
      }
      TerminateFunctionHelp(inOnDestroy:false);
      return;
   case ESC:
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call("maybe_delete_selection");
         maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
         return;
      }
      TerminateFunctionHelp(inOnDestroy:false);
      maybeCommandMode();
      return;

   case name2event("A-."):
   case name2event("M-."):
   case name2event("A-M-."):
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call("maybe_delete_selection");
         maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
      }
      still_in_code_help();
      DoDefaultKey(key);
      return;
   case name2event("C-DOWN"):
      still_in_code_help();
      //say("got here C-DOWN");
      DoDefaultKey(key);
      return;
   case name2event("C-UP"):
      still_in_code_help();
      //say("got here C-UP");
      DoDefaultKey(key);
      return;

   case name2event(" "):
      if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_COMPLETION)) {
         still_in_code_help(true);
         if (ginFunctionHelp && !gFunctionHelp_pending && select_active() &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION) &&
             gFunctionHelp_InsertedParam) {
            _macro_call("maybe_deselect");
            maybe_deselect();  // deselect the auto-inserted param
         }
         DoDefaultKey(key);
         return;
      }
      // drop through as if they typed control-space
   case name2event("C- "):
      still_in_code_help();
      //say("got here C-SPACE or SPACE");
      if (key==name2event("C- ") && ginFunctionHelp && !gFunctionHelp_pending) {
         _update_function_help();
         if (ginFunctionHelp && !gFunctionHelp_pending && maybe_insert_current_param()) {
            return;
         }
      }
      DoDefaultKey(key);
      return;

   case name2event("A-INS"):
   case name2event("M-INS"):
      still_in_code_help();
      //say("got here A-INS, ");
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         _update_function_help();
         if (ginFunctionHelp && !gFunctionHelp_pending && maybe_insert_current_param(do_select:false, check_if_defined:false)) {
            return;
         }
      }
      DoDefaultKey(key);
      return;
   case name2event("A-,"):
   case name2event("M-,"):
   case name2event("A-M-,"):
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call("maybe_delete_selection");
         maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
      }
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending && !gFunctionHelp_MouseOver) {
         nextFunctionHelp(1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("c-pgdn"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelp(1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("c-pgup"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelp(-1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-pgdn"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-pgup"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(-1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-home"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(2);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-end"):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(-2);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-up"):
      still_in_code_help();
      function_help_wid = ParameterHelpReposition(aboveCurrentLine:true);
      if (function_help_wid) {
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event("s-down"):
      still_in_code_help();
      function_help_wid = ParameterHelpReposition(aboveCurrentLine:false);
      if (function_help_wid) {
         return;
      }
      DoDefaultKey(key);
      return;
   case C_C:
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending && _iswindow_valid(gFunctionHelp_form_wid)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gFunctionHelp_form_wid;
         if (form_wid.ctlminihtml1._minihtml_isTextSelected()) {
             form_wid.ctlminihtml1._minihtml_command("copy");
             form_wid.ctlminihtml1._minihtml_command("deselect");
            return;
         } else if (form_wid.ctlminihtml2._minihtml_isTextSelected()) {
                    form_wid.ctlminihtml2._minihtml_command("copy");
                    form_wid.ctlminihtml2._minihtml_command("deselect");
            return;
         } else {
            DoDefaultKey(key,false);
            return;
         }
      }
      DoDefaultKey(key);
      return;
   case C_A:
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending && _iswindow_valid(gFunctionHelp_form_wid)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gFunctionHelp_form_wid;
         if (!form_wid.ctlminihtml1._minihtml_isTextSelected() &&
             !form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml2._minihtml_command("deselect");
            form_wid.ctlminihtml1._minihtml_command("selectall");
            return;
         } else if (!form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml2._minihtml_command("selectall");
            return;
         } else {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml2._minihtml_command("deselect");
         }
      }
      DoDefaultKey(key);
      return;
   case C_U:
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending && _iswindow_valid(gFunctionHelp_form_wid)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gFunctionHelp_form_wid;
         if (form_wid.ctlminihtml1._minihtml_isTextSelected() ||
             form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml2._minihtml_command("deselect");
            return;
         }
      }
      DoDefaultKey(key);
      return;

   default:
      DoDefaultKey(key);
      return;
   }
}

/**
 * Reposition the Parameter help form above the current line
 */
int ParameterHelpReposition(bool aboveCurrentLine)
{
   if (ginFunctionHelp && !gFunctionHelp_pending) {
      still_in_code_help();
      _PositionNoFocusForm(geditorctl_wid,
                           gFunctionHelp_form_wid,
                           gFunctionHelp_cursor_x,
                           gFunctionHelp_cursor_y,
                           geditorctl_wid.p_font_height,
                           0, aboveCurrentLine);
      return gFunctionHelp_form_wid;
   }
   return 0;
}

//    tag_type     -- 
//    class_name   -- 
//    temp_view_id -- 
//    orig_view_id -- 
//    tag_name     -- 
//    file_name    -- 
//    line_no      -- 
//    type_name    -- 
//    class_name   -- 
//

/**
 * Find the given tag to extract the comments surrounding.
 * Searches the current context to locate the tag nearest to
 * the given line.
 * 
 * @param tag_type         (reference) contains type name of tag found
 * @param class_name       (reference) name of class tag is found in
 * @param temp_view_id     (output) on success, contains temp_view_id containing file
 * @param orig_view_id     (output) on success, contains original view ID
 * @param tag_name         name of tag to search for
 * @param file_name        name of file that the tag is located in
 * @param line_no          the 'start' line for the tag
 * @param tag_database     (optional) tag database where this symbol is coming from 
 *
 * @return Returns 0 on success.  Non-zero otherwise. 
 *         On success, 'temp_view_id' holds the view ID for the file
 *         the comment came from, and 'orig_view_id' is the original view ID.
 */
static int _LocateTagForExtractingComment(_str &tag_type,
                                          _str &class_name,
                                          int &temp_view_id, 
                                          int &orig_view_id,
                                          _str tag_name, 
                                          _str file_name, 
                                          int line_no,
                                          _str tag_database=null)
{
   switch (_FileQType(file_name)) {
   case VSFILETYPE_URL_FILE:
      // URL access can be very slow, so don't try to get the comments
      return(1);
   }

   // is this a binary file?
   if (_QBinaryLoadTagsSupported(file_name)) {
      //message nls("Can not locate source code for %s.",file_name);
      return(1);
   }

   // try finding the item in locals or context, for current buffer
   found_class_name := "";
   status := 0;
   tag_linenum := -1;
   tag_seekpos := -1;
   tag_closest_linenum := MAXINT;
   tag_closest_col := 1;
   tag_closest_i := -1;
   tag_flags := 0;
   case_sensitive := p_EmbeddedCaseSensitive;
   temp_view_id=0;
   if (_isEditorCtl() && _file_eq(p_buf_name, file_name)) {
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // update the current context and locals
      _UpdateContext(true);
      _UpdateLocals(true);

      // try to find the tag among the locals
      i := tag_find_local_iterator(tag_name, true, case_sensitive);
      tag_closest_i= -1;
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, tag_linenum);
         if (abs(tag_linenum-line_no) < abs(tag_closest_linenum-line_no)) {
            tag_closest_linenum= tag_linenum;
            tag_closest_i=i;
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, tag_seekpos);
            tag_get_detail2(VS_TAGDETAIL_local_type, i, tag_type);
            tag_get_detail2(VS_TAGDETAIL_local_class, i, found_class_name);
            if (i > 1) {
               for (prev_i := i-1; prev_i > 0; prev_i--) {
                  tag_get_detail2(VS_TAGDETAIL_local_type, prev_i, auto prev_type);
                  if (!tag_tree_type_is_annotation(prev_type)) break;
                  tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, prev_i, tag_seekpos);
               }
            }
            if (tag_closest_linenum==line_no) break;
         }
         i = tag_next_local_iterator(tag_name, i, true, case_sensitive);
      }
      // not found? try the current context
      if (tag_closest_linenum!=line_no) {
         i = tag_find_context_iterator(tag_name, true, case_sensitive);
         tag_closest_i=-1;
         while (i > 0) {
            //say("_LocateTagForExtractingComment: context="i);
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, tag_linenum);
            if (abs(tag_linenum-line_no) < abs(tag_closest_linenum-line_no)) {
               tag_closest_linenum= tag_linenum;
               tag_closest_i=i;
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, tag_closest_i, tag_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_type, tag_closest_i, tag_type);
               tag_get_detail2(VS_TAGDETAIL_context_class, tag_closest_i, found_class_name);
               if (tag_closest_i > 1) {
                  for (prev_i := i-1; prev_i > 0; prev_i--) {
                     tag_get_detail2(VS_TAGDETAIL_context_type, prev_i, auto prev_type);
                     if (!tag_tree_type_is_annotation(prev_type)) break;
                     tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, prev_i, tag_seekpos);
                  }
               }
               if (tag_closest_linenum==line_no) break;
            }
            i = tag_next_context_iterator(tag_name, i, true, case_sensitive);
         }
      }
      // found in locals or context
      if (tag_seekpos >= 0) {
         already_loaded := false;
         status=_open_temp_view(file_name,temp_view_id,orig_view_id,"",already_loaded,false,true);
         if (status) {
            return status;
         }
         p_RLine= tag_linenum;
         _GoToROffset(tag_seekpos);
         //say("_LocateTagForExtractingComment: p_line="p_line" seek="_nrseek());
         return 0;
      }
      // could not find tag
      return 1;
   }

   // do not open URLs for extracting comments, too slow
   protocol := "";
   if (_isUrl(file_name, protocol) && protocol != "plugin") {
      return 1;
   }

   // check the tag file passed in to see if the file is up-to-date.
   // if it is, then just use the line number they gave us
   file_date := _file_date(file_name, 'B');
   tag_file_up_to_date    := false;
   found_file_in_tag_file := false;
   _str tag_files[];
   if (tag_database != null && tag_database != "") {
     tag_files[0] = tag_database;
     status = tag_read_db(tag_database);
     if (status >= 0) {
        tagged_date := "";
        status = tag_get_date(file_name, tagged_date);
        if (status == 0) {
           found_file_in_tag_file = true;
           if (tagged_date == file_date) {
              tag_file_up_to_date = true;
           }
        }
     }
   }

   // check all tag files to see if this file is up to date
   // if it is, then just use the line number they gave us
   if (!found_file_in_tag_file) {
      tag_files = tags_filenamea();
      i := 0;
      tag_filename := next_tag_filea(tag_files, i, false, true);
      while (tag_filename != "") {
         tagged_date := "";
         status=tag_get_date(file_name, tagged_date);
         if (status == 0) {
            found_file_in_tag_file = true;
            tag_database = tag_filename;
            if (tagged_date == file_date) {
               tag_file_up_to_date=true;
               break;
            }
         }
         tag_filename = next_tag_filea(tag_files, i, false, true);
      }
   }

   // check that the file is not oversized for opening to extract comments 
   file_size := _file_size(file_name);
   if (file_size > def_update_context_max_ksize*1024*32) {
      //say("_LocateTagForExtractingComment H"__LINE__": FILE IS WAY TOO BIG");
      return 1;
   }
   if (!tag_file_up_to_date && file_size > def_update_context_max_ksize*1024) {
      //say("_LocateTagForExtractingComment H"__LINE__": FILE IS TOO BIG");
      return 1;
   }

   // try to create a temp view for the file
   already_loaded := false;
   status=_open_temp_view(file_name,temp_view_id,orig_view_id,"",already_loaded,false,true);
   if (status) {
      return status;
   }

   if (tag_file_up_to_date) {
      p_RLine=line_no;
      _begin_line();
      _first_non_blank();
      //say("_LocateTagForExtractingComment H"__LINE__": TAG FILE UP TO DATE");
      return(0);
   }

   // no tagging support for this file, then give up
   if (! _istagging_supported(p_LangId) ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      temp_view_id=0;
      //say("_LocateTagForExtractingComment H"__LINE__": NO TAGGING SUPPORT");
      return(1);
   }

   // the proc-search based code is faster if we have one
   PSindex := _FindLanguageCallbackIndex("%s-proc-search");
   if (PSindex) {
      // set up proc name to search for
      _str find_proc_name = tag_name;
      // First try searching from designated line number
      p_line=line_no; begin_line();
      _str orig_proc_name = find_proc_name;
      top();
      ff := 1;
      for (;;) {
         find_proc_name = orig_proc_name;
         status=call_index(find_proc_name,ff,p_LangId,PSindex);
         //say("_ExtractTagComments: "find_proc_name" status="status" buf="p_buf_name);
         //say("p_line="p_line" line_no="line_no);
         if (status) {
            break;
         }
         if (p_line==line_no) {
            tag_decompose_tag_browse_info(find_proc_name, auto cm);
            tag_name = cm.member_name;
            class_name = cm.class_name;
            return 0;
         }
         ff=0;
      }

      // didn't find the tag, give up unless we have list-tags
      LTindex := _FindLanguageCallbackIndex("vs%s_list_tags");
      if (!LTindex) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         temp_view_id=0;
         return status;  // non-zero
      }
      // giving up on proc-search, try context
      status=0;
   }

   // save the current context and then
   // parse the items in the temporary view
   orig_context_file := "";
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // set up proc name to search for
   i := tag_find_context_iterator(tag_name, true, case_sensitive);
   tag_closest_i=-1;
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, tag_linenum);
      if (abs(tag_linenum-line_no) < abs(tag_closest_linenum-line_no)) {
         tag_closest_linenum= tag_linenum;
         tag_closest_i=i;
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, tag_closest_i, tag_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_type, tag_closest_i, tag_type);
         tag_get_detail2(VS_TAGDETAIL_context_class, tag_closest_i, class_name);
         if (i > 1) {
            for (prev_i := i-1; prev_i > 0; prev_i--) {
               tag_get_detail2(VS_TAGDETAIL_context_type, prev_i, auto prev_type);
               if (!tag_tree_type_is_annotation(prev_type)) break;
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, prev_i, tag_seekpos);
            }
         }
         if (tag_closest_linenum==line_no) break;
      }
      i = tag_next_context_iterator(tag_name, i, true, case_sensitive);
   }
   if (tag_closest_i>=0) {
      // found the tag
      p_RLine= tag_closest_linenum;
      _GoToROffset(tag_seekpos);
   } else {
      // didn't find the tag
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      temp_view_id=0;
      status=1;
   }

   // restore the context and locals
   // _UpdateContext shouldn't do anything
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();
   if (_isEditorCtl()) {
      _UpdateContext(true);
      _UpdateLocals(true);
   }
   return status;  // non-zero
}

/**
 * Extract source comments from the header file for the given tag,
 * located in the given file and line number.
 *
 * @param header_list  (output) array of strings for each line of comment
 * @param line_limit   maximum number of lines of comment to retrieve
 * @param tag_name     name of tag to search for
 * @param file_name    name of file that the tag is located in
 * @param line_no      the 'start' line for the tag
 * @param type_name    tag type (SE_TAG_TYPE_*) to search for
 * @param class_name   class name to search for
 * @param indent_col   amount to indent each line of comment
 *
 * @return 0 on success, nonzero on error
 *         Results are returned in 'header_list', expect it may be empty.
 */
int _ExtractTagComments(_str (&header_list)[], int line_limit,
                        _str tag_name, _str file_name, int line_no,
                        _str type_name="", _str class_name="", int indent_col=0)
{
   //say("_ExtractTagComments: 1");
   header_list._makeempty();

   // try to find the tag
   tag_type := "";
   temp_view_id := orig_view_id := 0;
   status := _LocateTagForExtractingComment(tag_type, class_name,
                                            temp_view_id, orig_view_id,
                                            tag_name, file_name, line_no);
   // didn't find the tag, out of here
   if (status) {
      return status;
   }

   // get the tag header comments
   status=_do_default_get_tag_header_comments(auto first_line,auto last_line);
   if (_chdebug) {
      say("_ExtractTagComments H"__LINE__": status="status" first_line="first_line" last_Line="last_line);
   }
   if (status) {
      if (temp_view_id != 0) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
      return status;
   }

   // maybe check line limit
   if (line_limit>0 && last_line-first_line>line_limit) {
      last_line = first_line+line_limit;
   }

   // collect the lines of the header comment, into header_list
   p_line=first_line;
   first_non_blank_col := 0;
   while (p_line<=last_line) {
      _first_non_blank('h');
      if (!first_non_blank_col) {
         first_non_blank_col=p_col;
      } else {
         if (p_col<first_non_blank_col) {
            first_non_blank_col=p_col;
         }
      }
      line := _expand_tabsc(first_non_blank_col,-1,'S');
      line=indent_string(indent_col):+strip(line,'T');
      header_list :+= line;
      if (down()) {
         break;
      }
   }

   // success!!!
   if (temp_view_id != 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   return 0;
}

/**
 * Extract source comments from the header file for the given tag,
 * located in the given file and line number.
 *
 * @param comment_flags  (output) JavaDoc or HTML comments?
 * @param member_msg     (output) array of strings for each line of comment
 * @param line_limit     maximum number of comment lines to retrieve
 * @param tag_name       name of tag to search for
 * @param file_name      name of file that the tag is located in
 * @param line_no        the 'start' line for the tag 
 * @param tag_database   (optional) tag database where this symbol is coming from 
 *
 * @return 0 on success, nonzero on error
 *         Results are returned in 'header_list', expect it may be empty.
 */
int _ExtractTagComments2(VSCodeHelpCommentFlags &comment_flags,
                         _str &member_msg, 
                         int line_limit,
                         _str tag_name, 
                         _str file_name, 
                         int line_no,
                         _str class_name="",
                         _str tag_type="",
                         _str tag_database=null,
                         VS_TAG_RETURN_TYPE (&visited):[] = null,
                         int depth=0)
{
   //say("_ExtractTagComments2: 1");
   // try to find the tag
   comment_flags=0;
   member_msg="";

   if (p_LangId == "docbook") {
      return _docbook_ExtractTagComments2(member_msg, tag_name, file_name, line_no);
   }

   temp_view_id := orig_view_id := 0;
   status := _LocateTagForExtractingComment(tag_type, class_name,
                                            temp_view_id, orig_view_id,
                                            tag_name, 
                                            file_name, line_no,
                                            tag_database);
   if (_chdebug) {
      say("_ExtractTagComments2 H"__LINE__": status="status" line_no="line_no);
   }

   // didn't find the tag
   if (!status) {
      // get the tag header comments
      line_prefix := "";
      int blanks:[][];
      doxygen_comment_start := "";
      _do_default_get_tag_comments(comment_flags,tag_type,member_msg,line_limit,true,line_prefix,blanks,doxygen_comment_start);
      if (_chdebug) {
         say("_ExtractTagComments2 H"__LINE__": comment_flags="comment_flags);
         say("_ExtractTagComments2 H"__LINE__": tag_type="tag_type);
         say("_ExtractTagComments2 H"__LINE__": member_msg="member_msg);
         say("_ExtractTagComments2 H"__LINE__": line_limit="line_limit);
         say("_ExtractTagComments2 H"__LINE__": line_prefix="line_prefix);
         say("_ExtractTagComments2 H"__LINE__": doxygen_comment_start="doxygen_comment_start);
      }
      if (temp_view_id != 0) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         temp_view_id=0;
      }
   }

   // if we didn't find anything, find and look up parent classes
   if (member_msg=="" && file_name!="" && depth < 100) {
      tag_files := tags_filenamea(p_LangId);
      if ( tag_database != null && tag_database != "" ) {
         tag_files :+= tag_database;
      }
      i := num_matches := 0;
      tag_push_matches();
      tag_list_in_class(tag_name,class_name,0,0,
                        tag_files,num_matches,def_tag_max_find_context_tags,
                        tag_type_to_filter(tag_type,0),
                        SE_TAG_CONTEXT_ONLY_PARENTS,
                        true,p_EmbeddedCaseSensitive,
                        null, null, visited, 1);
      for (i=1; i<=num_matches; ++i) {
         tag_get_match_browse_info(i, auto parent);
         if (parent.member_name == tag_name && parent.class_name == class_name) {
            continue;
         }
         status=_ExtractTagComments2(comment_flags, member_msg, line_limit,
                                     parent.member_name, 
                                     parent.file_name, 
                                     parent.line_no,
                                     parent.class_name,
                                     parent.type_name,
                                     parent.tag_database,
                                     visited, depth+1);
         if (!status && member_msg!="") {
            break;
         }

      }
      tag_pop_matches();
   }

   return 0;
}
/**
 * Escape HTML characters in the given string.
 *
 * @param text     (reference) string, set to string with HTML chars
 *                 replaced by special characters
 */
void _escape_html_chars(_str &text)
{
   text=translate(text,"\1\2\3","<&>");
   text=stranslate(text,"&gt;","\3");
   text=stranslate(text,"&amp;","\2");
   text=stranslate(text,"&lt;","\1");
}

/*
   Doxygen comments are a super set of javadoc comments.  Unfortunately,
   interpreting javadoc comments as doxygen comments can wreck the javadoc
   comments.  For this reason, we take a conservative approach.  By default,
   "/ **" are interpreted as javadoc comments.  Turn this option on, if you
   want "/ **" comments interpreted as doxygen comments.

   "/ *!" comments are always interpreted as doxygen comments.

*/
bool def_doxygen_all = false;
/**
 * Parse the components out of a standard Javadoc comment.
 *
 * @param member_msg     comment to parse
 * @param description    set to description of javadoc comment
 * @param hashtab        hash table of javadoc tags -> messages
 * @param tagList        list of tags found in message 
 *  
 * @deprecated Use tag_tree_parse_javadoc_comment() instead 
 */
void _parseJavadocComment(_str &member_msg,
                          _str &description,
                          _str (&hashtab):[][],
                          _str (&tagList)[],
                          bool TranslateThrowsToException=true,
                          bool isDoxygen=false, 
                          _str &tagStyle="@", 
                          bool skipBrief=true)
{
   tag_tree_parse_javadoc_comment(member_msg, description, tagStyle, hashtab, tagList, TranslateThrowsToException, isDoxygen, skipBrief);
}

/* This translation is only need for Doxygen but it seems reasonable
   to do this for javadoc comments too.
*/

/**
 * Create a HTML comment from the comment extracted from source code.
 * If the comment is Javadoc, format it appropriately.
 *
 * @param member_msg     comment to parse
 * @param comment_flags  bitset of VSCODEHELP_COMMENTFLAG_*
 * @param return_type    expected return type for tag/variable
 * @param param_name     name of current parameter of function
 * @param make_categories_links make links for SlickEdit @categories links
 * @param lang_id        (optional) current function's language mode
 */
void _make_html_comments(_str &member_msg,VSCodeHelpCommentFlags comment_flags,_str return_type,_str param_name="",bool make_categories_links=false,_str lang_id="")
{
   // check if there is an extension specific callback.
   extra_comment_text := "";
   comment_text := member_msg;
   index := _FindLanguageCallbackIndex("_%s_process_comments", lang_id);
   if (index) {
      status := call_index(member_msg, comment_flags, comment_text, index);
      if (status < 0) {
         // error code < 0 indicates that we do not use our results
      } else if (status > 0) {
         // result > 0 means to append the generated text to the comment
         extra_comment_text = member_msg;
      } else {
         // zero means we need to use the comment text just the way it is.
         return;
      }
   }

   tag_tree_make_html_comment(member_msg, comment_flags, comment_text, param_name, return_type, lang_id, make_categories_links, def_doxygen_all);
   if (extra_comment_text != "") {
      member_msg :+= "\n";
      member_msg :+= extra_comment_text;
   }

   // get the image based on the function parameter info font height
   if (pos("vslick://_f_arrow_right.svg", member_msg)) {
      _xlat_default_font(CFG_FUNCTION_HELP, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
      imageSize := getImageSizeForFontHeight(fontHeight);
      if (imageSize != 12) {
         member_msg = stranslate(member_msg, "vslick://_f_arrow_right.svg@":+imageSize, "vslick://_f_arrow_right.svg@12");
      }
   }

   if (_chdebug) {
      split(member_msg, "\n", auto comment_array);
      for (i:=0; i < comment_array._length(); i++) {
         say("_make_html_comments: < html["i"]="comment_array[i]);
      }
   }
}
/**
 * Format the given tag for display as the variable definition part
 * in list-members or function help.  This function is also used
 * for generating code (override method, add class member, etc.).
 * The current object must be an editor control.
 * <P>
 * If there isn't an extension specific _[lang]_get_decl hook
 * function, this function will call {@link _c_get_decl()}.
 *
 * @param lang           Current language ID {@see p_LangId}
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with.
 *
 * @return string holding formatted declaration.
 */
_str extension_get_decl(_str lang, VS_TAG_BROWSE_INFO &info,int flags=0,
                        _str decl_indent_string="",
                        _str access_indent_string="")
{
   index := _FindLanguageCallbackIndex("_%s_get_decl",lang);
   if (index) {
      return call_index(lang,info,flags,decl_indent_string,access_indent_string,index);
   }
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

// comment <B> bold comment</B> <I>italic</I> <U> underline</U>
// comment <B> bold comment <I>italic</I> <U> underline</U></B>

/**
 * Sets up bold/italic/underline text fonts for the HTML viewer control.
 *
 * @param width              required width
 * @param height             required height
 * @param Noflines           (reference) Number of lines added
 * @param parent_wid         parent window ID
 * @param msg                message with optional line breaks and the
 *                           following font style encodings
 *                           <PRE>
 *                             \1b      Bold
 *                             \1i      Italic
 *                             \1u      Underline
 *                             \1e      End all styles
 *                           </PRE>
 * @param sepchars           One or more characters after which line breaks
 *                           are allowed.  Space may be specified in this list.
 * @param start_x            X position (p_x)
 * @param start_y            Y position (p_y)
 * @param max_width          Maximimum width of label text in twips.
 * @param font_string        Font to be used for label text
 * @param fg                 RGB foreground color
 * @param bg                 RGB background colors
 * @param wrap_indent
 * @param max_font_flags     Usually 0 is specified to indicate that
 *                           some font flags are used by that consistent
 *                           word wrap is not necessary.
 *                           -1 indicates that no font flags are used.
 *                           One or more of the flags below indicate
 *                           <PRE>
 *                                F_BOLD
 *                                F_ITALIC
 *                                F_UNDERLINE
 *                           </PRE>
 *                           the largest possible font case.  Then variations
 *                           in the font will give the same word wrap
 *                           results.
 */
void _CreateBoldItalicLabels(int &width,int &height,int &Noflines,
                             int parent_wid,_str msg,_str sepchars,
                             int start_x,int start_y,
                             int max_width,_str font_string,
                             int fg,int bg,int wrap_indent,int max_font_flags
                            )
{
   if (max_font_flags== -1) {
      max_font_flags=0;
   }
   font_name := "";
   typeless font_size=0;
   parse font_string with font_name","font_size",";
   prefix := "";
   word_wrap := false;
   if (pos(" ",sepchars)) {
      word_wrap=true;
      sepchars=stranslate(sepchars,""," ");
   }
   sepchars=stranslate(sepchars,"","\n");
   if (max_font_flags) {
      prefix :+= _chr(1)'<_MAXFONTFLAGS flags='max_font_flags'>';
   }
   if (sepchars!="") {
      prefix :+= _chr(1)'<_sepchars sepchars="'sepchars'">';
   }
   if (wrap_indent) {
      prefix :+= _chr(1)'<_hangingindent width='wrap_indent't>';
   }
   if (prefix!="") {
      msg=prefix:+msg;
   }
   //say("start_y="start_y);
   int label_wid=_create_window(OI_LABEL,parent_wid,"",start_x,start_y,0,0,CW_CHILD,BDS_NONE);
   label_wid.p_MouseActivate=MA_NOACTIVATE;
   if (font_name!="") {
      label_wid.p_font_name=font_name;
   }
   if (isinteger(font_size)) {
      label_wid.p_font_size=font_size;
   }
   //label_wid.p_width=max_width;
   //label_wid.p_height=400;
   if (word_wrap) {
      label_wid.p_width=max_width;
      label_wid.p_word_wrap=true;
   }
   if (max_font_flags) {
      label_wid.p_width=max_width;
      if (sepchars:!="") {
         label_wid.p_word_wrap=true;
      }
   }
   //label_wid._font_flags2props(font_flags);
   label_wid.p_caption=msg;
   //messageNwait("label_wid.p_caption="label_wid.p_caption);
   label_wid.p_forecolor=fg;
   label_wid.p_backcolor=bg;
   label_wid.p_auto_size=true;

   if (max_font_flags) {
      width=start_x+label_wid.p_width;
      //say("width="_lx2dx(SM_TWIP,width));
      label_wid.p_auto_size=false;
      label_wid.p_width=max_width;
   } else {
      if (label_wid.p_width>max_width) {
         label_wid.p_auto_size=false;
         label_wid.p_width=max_width;
         if (sepchars:!="") {
            label_wid.p_word_wrap=true;
         }
         label_wid.p_auto_size=true;
      }
      width=start_x+label_wid.p_width;
   }

   height=start_y+label_wid.p_height;
   Noflines=label_wid.p_height intdiv label_wid._text_height();
}

/**
 * Set up the fonts for the HTML control in the codehelp window.
 *
 * @param font_string        Requested proportional font string (encoded)
 * @param font_string_fixed  Requested fixed font string (encoded)
 * @param font_name          set to name of font found
 * @param font_size          set to size of font found
 */
void _codehelp_set_minihtml_fonts(_str font_string,_str font_string_fixed,_str &font_name="",typeless &font_size="")
{
   typeless flags;
   typeless charset;
   parse font_string with font_name","font_size","flags","charset;
   if (!isinteger(charset)) charset=-1;
   font_name_fixed := "";
   typeless font_size_fixed;
   typeless flags_fixed;
   typeless charset_fixed;
   parse font_string_fixed with font_name_fixed","font_size_fixed","flags_fixed","charset_fixed;
   if (!isinteger(charset_fixed)) charset_fixed=-1;
   if (font_name=="") font_name=VSDEFAULT_DIALOG_FONT_NAME;
   if (lowcase(font_name)==lowcase(VSDEFAULT_DIALOG_FONT_NAME) && _dbcs()) {
      font_name=\130\108\130\114\32\130\111\131\83\131\86\131\98\131\78;
      font_size=9;
   }
   if (!isinteger(font_size)) font_size=8;
   if (font_name!="") {
      _minihtml_SetProportionalFont(font_name,charset);
   }
   if (isinteger(font_size)) {
      _minihtml_SetProportionalFontSize(-1,font_size*10);
   }
   if (font_name_fixed!="") {
      _minihtml_SetFixedFont(font_name_fixed,charset_fixed);
   }
   if (isinteger(font_size_fixed)) {
      _minihtml_SetFixedFontSize(-1,font_size_fixed*10);
   }
}
/**
 * This function operates on a picture1 of the _function_help_form
 *
 * @param margin_text        margin text?
 * @param more_margin        margin ratio?
 * @param msg                message with optional line breaks and the
 *                           following font style encodings
 *                           <PRE>
 *                             \1b      Bold
 *                             \1i      Italic
 *                             \1u      Underline
 *                             \1e      End all styles
 *                           </PRE>
 * @param sepchars           One or more characters after which line breaks
 *                           are allowed.  Space may be specified in this list.
 * @param start_x            X position (p_x)
 * @param start_y            Y position (p_y)
 * @param max_width          Maximimum width of label text in twips.
 * @param max_height         Maximum height of label text in twips.
 * @param font_string        Font to be used for label text
 * @param font_string_fixed  Font to be used for fixed with label text
 * @param fg                 RGB foreground color
 * @param bg                 RGB background colors
 * @param max_font_flags     Usually 0 is specified to indicate that
 *                           some font flags are used by that consistent
 *                           word wrap is not necessary.
 *                           -1 indicates that no font flags are used.
 *                           One or more of the flags below indicate
 *                           <PRE>
 *                                F_BOLD
 *                                F_ITALIC
 *                                F_UNDERLINE
 *                           </PRE>
 *                           the largest possible font case.  Then variations
 *                           in the font will give the same word wrap
 *                           results.
 */
void _InitBoldItalic(_str margin_text,
                     double more_margin,  // Must do floating point math!!
                     _str msg,
                     _str sepchars,
                     int start_x,int start_y,
                     int max_width,
                     int max_height,
                     _str font_string,
                     _str font_string_fixed,
                     int fg,int bg,int max_font_flags
                     )
{
   if (max_font_flags== -1) {
      max_font_flags=0;
   }
   font_name := "";
   typeless font_size=0;
   _codehelp_set_minihtml_fonts(font_string,font_string_fixed,
                                font_name,font_size);

   prefix := "";
   /*if (pos(" ",sepchars)) {
      word_wrap=true;
      sepchars=stranslate(sepchars,""," ");
   } */
   sepchars=stranslate(sepchars,"","\n");
   if (max_font_flags) {
      prefix :+= "<_MAXFONTFLAGS flags="max_font_flags">";
   }
   if (sepchars!="") {
      prefix :+= '<_sepchars sepchars="'sepchars'">';
   }
   if (sepchars!="") {
      more_margin1 := 0.0; // Must do floating point math!!
      if (margin_text!="") {
         //margin_text="<img src=vslick://_f_arrow_lt.svg><img src=vslick://_f_arrow_gt.svg>";more_margin=0;
         //margin_text="WWWWiiiiiiiii";more_margin=0;
         p_PaddingX=0;
         p_PaddingY=0;
         //say("font_name="font_name);
         //p_text="<pre style=font-family:"font_name";font-size:">"margin_text;
         p_text='<pre style="font-family:'font_name';font-size:'font_size'pt">'margin_text"</pre>";
         //p_text=margin_text;
         p_width=max_width;
         _minihtml_ShrinkToFit();
         //p_active_form.p_visible=p_parent.p_visible=true;_message_box("got here");
         //say(_lx2dx(SM_TWIP,p_width));
         // 72 points per inch
         //say("n="p_font_name" size="p_font_size);
         //say("930/tx="930/_twips_per_pixel_x());
         double indent=_lx2dx(SM_TWIP,p_width);
         //p_font_name=VSDEFAULT_DIALOG_FONT_NAME;
         //indent=_lx2dx(SM_TWIP,_text_width(margin_text));
         //say("indent="indent" "_lx2dx(SM_TWIP,_text_width(margin_text)));
         //indent=9*2+_lx2dx(SM_TWIP,_text_width(" 1 of 2  "));more_margin=0;//say("h2 indent="indent);
         // Must do floating point math!!
         more_margin1= (indent*72) / _pixels_per_inch_x();
      }
      msg='<pre style="text-indent:-'(more_margin+more_margin1)'pt;margin-left:'(more_margin+more_margin1)'pt;margin-top:0;margin-bottom:0;font-family:'font_name';font-size:'font_size'pt">'prefix:+margin_text:+msg;
      //msg='<pre style="text-indent:-'(more_margin+more_margin1)'pt;margin-left:'(more_margin+more_margin1)'pt;margin-top:0;margin-bottom:0;">'prefix:+margin_text:+msg;
      //msg='<pre>'prefix:+margin_text:+msg;
   } else {
      if (prefix!="") {
         msg=prefix:+msg;
      }
   }
   wid := p_window_id;
   p_word_wrap=false;
   //say("start_y="start_y);
   p_MouseActivate=MA_NOACTIVATE;
   p_width=max_width;
   p_height=max_height;
   p_PaddingX=start_x;
   p_PaddingY=start_y;
   //say("start_y="start_y" max_height="max_height" font="p_font_name" s="p_font_size);

   p_backcolor=bg;
   //messageNwait("h1");p_active_form.p_visible=true;p_visible=true;
   p_text=msg;
   //say(msg);
   //fsay(msg);
   //messageNwait("h2");
   //say("wh h1 "p_width" "p_height" m="max_width" "max_height);

   _minihtml_ShrinkToFit();
   //say("wh h2 "p_width" "p_height);
}
//#if 0
defeventtab _function_help_form;
void ctlminihtml1.on_create(int editorctl_wid=0, int tree_wid=0)
{
   geditorctl_wid = editorctl_wid;
   p_active_form.p_MouseActivate=MA_NOACTIVATE;
   HYPERTEXTSTACK stack;
   stack.HyperTextTop= -1;stack.HyperTextMaxTop=stack.HyperTextTop;
   HYPERTEXTSTACKDATA(stack);
   ctlsizebar.p_user=_moncfg_retrieve_value(p_active_form.p_name:+".ctlsizebar.p_user");
   LISTHELPTREEWID(tree_wid);
}

/**
 * Find symbols which match the given hypertext reference.
 * This is used for traversing comments in the preview tool
 * window and list members and autocomplete windows.
 * The current object should be the editor control positioned
 * in the context to match tags at.  The results are inserted
 * into the current symbol match set.
 *
 * @param hrefText      link text to match
 * @param filename      current file name to find line relative to
 * @param linenum       current line number within file
 * @param curclassname  current class / package context
 *
 * @return number of matches >= 0 on success, <0 on error
 */
int tag_match_href_text(_str hrefText,
                        _str filename="", int linenum=0,
                        _str curclassname="")
{
   //say("tag_match_href_text H"__LINE__": IN, hrefText="hrefText);
   // verify that this is a symbol link
   if (substr(hrefText,1,1) != JAVADOCHREFINDICATOR) {
      //say("tag_match_href_text H"__LINE__": NO INDICATOR");
      return STRING_NOT_FOUND_RC;
   }

   //say("tag_match_href_text H"__LINE__": filename="filename);
   //say("tag_match_href_text H"__LINE__": line="linenum);

   // open a temp view if the expected file does not match the current file
   status := 0;
   orig_context_file := "";
   temp_view_id := orig_view_id := 0;
   save_pos(auto p);
   if (filename != "") {
      tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_push_context();
      if (!_file_eq(filename, p_buf_name)) {
         status=_open_temp_view(filename,temp_view_id,orig_view_id);
      }
      if (!status && linenum != 0) {
         p_RLine=linenum;
         _begin_line();
      }
   } else {
      filename=p_buf_name;
      linenum=p_RLine;
   }

   // get current mode / file extension
   lang := p_LangId;
   if (lang=="xmldoc") lang="cs";

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);

   // grab up the critical information about current context
   context_id := tag_get_current_context(auto cur_proc_name,auto cur_tag_flags,
                                         auto cur_type_name,auto cur_type_id,
                                         auto cur_class_name,auto cur_class_only,
                                         auto cur_package_name);
   if (context_id > 0) {
      if (tag_tree_type_is_class(cur_type_name)) {
         cur_class_name = tag_join_class_name(cur_proc_name, cur_class_name, null, true);
      }
      curclassname=cur_class_name;
   }
   //say("tag_match_href_text H"__LINE__": curclassname="curclassname);

   // clean up the temp view and restore the current context information
   if (temp_view_id > 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
      _UpdateContextAndTokens(true);
   }

   // Look up tags associated with this Href, result is in match set
   //
   // Known Limitations for C#
   //
   //    A.B     could find method B() of class A instead for class A.B
   //
   class_name := "";
   method := "";
   arguments := "";
   data_member_only := false;
   if (pos("#",hrefText)) {
      parse substr(hrefText,2) with class_name"#"method"("arguments")";
   } else {
      // For Java , if there is a paren, it may ONLY mean that its a constuctor.  For now, we treat this
      // the same as C# where we look for a method first.
      arguments="";
      parse substr(hrefText,2) with class_name"("arguments")";
      method="";
      last_dot := lastpos(".",class_name);
      last_cc  := lastpos("::",class_name);
      if (last_dot > 0) {
         method=substr(class_name,last_dot+1);
         class_name=substr(class_name,1,last_dot-1);
      } else if (last_cc > 0) {
         method=substr(class_name,last_cc+2);
         class_name=substr(class_name,1,last_cc-1);
      } else {
         method=class_name;
         class_name="";
      }
      if (!pos('(', hrefText) && _LanguageInheritsFrom("cs",lang)){
         // class name or data member case
         // Try data member first
         data_member_only=true;
      }
   }

   //say("tag_match_href_text H"__LINE__": class_name="class_name);
   //say("tag_match_href_text H"__LINE__": method="method);
   //say("tag_match_href_text H"__LINE__": arguments="arguments);

   embedded_status := _EmbeddedStart(auto orig_values);
   lang=p_LangId;
   if (lang=="xmldoc") lang="cs";
   status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
   if (data_member_only) {
      hit_one := false;
      n := tag_get_num_of_matches();
      for (i:=0; i<n; ++i) {
         tag_get_match_info(i+1, auto cm);
         cm.language=lang;
         if (!(cm.flags & SE_TAG_FLAG_CONST_DESTR)) {
            hit_one=true;
            break;
         }
      }
      if (!hit_one) {
         status=1;
      }
   }
   if (status) {
      if (!pos("#",hrefText)) {
         if (pos("(",hrefText) ) {
            // This could be a constructor.
            parse substr(hrefText,2) with class_name"(" .;
            status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
         } else if(_LanguageInheritsFrom("cs",lang)){
            // Already tried data member.  Now try class.
            parse substr(hrefText,2) with class_name"(" .;
            method="";
            status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
         }
      }
   }

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   restore_pos(p);
   if (status) {
      return STRING_NOT_FOUND_RC;
   }

   // return number of matches found
   return tag_get_num_of_matches();
}

/**
 * Jump to the specified web page or SlickEdit help page.
 * This is used for traversing comments in the preview tool
 * window and list members and autocomplete windows.
 *
 * @param webpage    hypertext link or web page to jump to
 */
void tag_goto_url(_str webpage)
{
   i := pos("://",webpage);
   word := "";
   rest := "";
   if (i) {
      word=substr(webpage,1,i-1);
      rest=substr(webpage,i+3);
   }
   type := "";
   if (substr(webpage,1,9)=="helppath:") {
      webpage=_getSlickEditInstallPath():+"help":+FILESEP:+"misc":+FILESEP:+substr(webpage,10);
      type="f";
   } else if (substr(webpage,1,5)=="help:") {
      help(substr(webpage,6));
      return;
      /*_str url=h_match_pick_url(substr(i,6));
      if (url=="") {
         _message_box(nls("%s not found in help index",substr(i,6));
         return;
      }
      webpage=url;
      type="f";*/
   } else if (lowcase(word)=="file" ) {
      webpage=rest;
      type="f";
   } else if (word=="" &&
              (substr(webpage,2,1)==":" || substr(webpage,2,1)=="|")  &&
              (substr(webpage,3,1)=='\" || substr(webpage,3,1)=="/') &&
               substr(webpage,4,1)!='\" && substr(webpage,4,1)!="/'
              ) {
      type="f";
   } else if (word=="" &&
              (substr(webpage,1,1)=='\" || substr(webpage,1,1)=="/') &&
               substr(webpage,2,1)!='\" && substr(webpage,2,1)!="/'
              ) {
      type="f";
   } else {
      type="p";
   }
   if (type=="f") {
      webpage=translate(webpage,":","|");
      if(FILESEP=='\') {
         webpage=translate(webpage,'\','/');
      }
   }
   goto_url(webpage);
}

/*
    http:// ...
    ftp:// ...
    gopher://
    wais://
    <word>:// <rest>
    file:// ...  This is a file
    help:// SlickEdit on-line help item
    #name   in current doc

    filename#name

    category\x.html
*/
void ctlminihtml1.on_change(int reason,_str hrefText)
{
   //say("ctlminihtml1.on_change H"__LINE__": HERE, reason="reason" text="hrefText);
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      //say("ctlminihtml1.on_change H"__LINE__": HTML LINK");
      HYPERTEXTSTACK stack;
      stack=HYPERTEXTSTACKDATA();
      doFunctionHelp := p_active_form==gFunctionHelp_form_wid;
      if (hrefText=="<<back") {
         if(stack.HyperTextTop>=0) {
            ctlminihtml2._minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         --stack.HyperTextTop;
         HYPERTEXTSTACKDATA(stack);
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid, true);
         ctlminihtml2._minihtml_SetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         return;
      } else if(hrefText=="<<forward") {
         if(stack.HyperTextTop>=0) {
            ctlminihtml2._minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         ++stack.HyperTextTop;
         HYPERTEXTSTACKDATA(stack);
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid, true);
         ctlminihtml2._minihtml_SetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         return;
      }

      if (hrefText=="<<f") {
         nextFunctionHelp(-1, doFunctionHelp, p_active_form);
         return;
      } else if (hrefText==">>f") {
         nextFunctionHelp(1, doFunctionHelp, p_active_form);
         return;
      } else if (hrefText=="<<pushtag") {
         gotoFunctionTag(doFunctionHelp, p_active_form, geditorctl_wid);
         return;
      } else if (substr(hrefText,1,16)=="<<push_clipboard") {
         hrefText = strip(substr(hrefText,17));
         push_clipboard(hrefText);
         message("Copied '"hrefText"' to clipboard");
         return;
      } else if (substr(hrefText,1,7)=="help://") {
         help(substr(hrefText,8));
         return;
      } else if (substr(hrefText,1,7)=="slickc:") {
         parse hrefText with "slickc:" auto commandName auto argValue;
         index := find_index(commandName, COMMAND_TYPE);
         if (index_callable(index)) {
            call_index(argValue, index);
            return;
         }
         return;
      } else if (substr(hrefText,1,2)=="<<") {
         parse hrefText with "<<" auto commandName auto argValue;
         index := find_index(commandName, COMMAND_TYPE);
         if (index_callable(index)) {
            call_index(argValue, index);
            return;
         }
      }

      // Is this a web site or other hypertext link (not a code link)?
      if (substr(hrefText,1,1)!=JAVADOCHREFINDICATOR) {
         tag_goto_url(hrefText);
         return;
      }

      if (substr(hrefText,1,2)==JAVADOCHREFINDICATOR:+JAVADOCHREFINDICATOR) {
         if (stack.HyperTextTop<0) {
            ++stack.HyperTextTop;
            stack.HyperTextMaxTop=stack.HyperTextTop;
            if (doFunctionHelp) {
               stack.s[stack.HyperTextTop].TagIndex=gFunctionHelpTagIndex;
               stack.s[stack.HyperTextTop].TagList=gFunctionHelp_list;
            } else {
            }
         }
         if(stack.HyperTextTop>=0) {
            _minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         ++stack.HyperTextTop;
         stack.HyperTextMaxTop=stack.HyperTextTop;
         stack.s[stack.HyperTextTop].TagIndex=gFunctionHelpTagIndex;
         stack.s[stack.HyperTextTop].TagList=gFunctionHelp_list;
         HYPERTEXTSTACKDATA(stack);
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid, true);
         ctlminihtml2._minihtml_FindAName(substr(hrefText,3),VSMHFINDANAMEFLAG_CENTER_SCROLL);
         return;
      }

      stack=HYPERTEXTSTACKDATA();
      VSAUTOCODE_ARG_INFO (*plist)[];
      TagIndex := 0;
      //say("top="stack.HyperTextTop);
      if (stack.HyperTextTop>=0) {
         TagIndex=stack.s[stack.HyperTextTop].TagIndex;
         plist=&stack.s[stack.HyperTextTop].TagList;
      } else {
         // Determine source and line of this comment
         if (doFunctionHelp) {
            TagIndex=gFunctionHelpTagIndex;
            plist=&gFunctionHelp_list;
         } else {
            /* This case never happens since stack is built
               when list members comment is displayed */
            return;
         }
      }

      filename := "";
      linenum := 0;
      curclassname := "";
      if (TagIndex<plist->_length() && (*plist)[TagIndex].tagList!=null) {
         if ((*plist)[TagIndex].tagList._length()<1) {
            return;
         }
         // Use the first comment for this tag.  Don't worry if there are
         // multiple definitions of the exact same tag.
         filename=(*plist)[TagIndex].tagList[0].filename;
         linenum=(*plist)[TagIndex].tagList[0].linenum;
         cm := (*plist)[TagIndex].tagList[0].browse_info;
         if (cm == null && (*plist)[TagIndex].tagList[0].taginfo != null) {
            curclassname=(*plist)[TagIndex].tagList[0].taginfo;
            tag_decompose_tag_browse_info(curclassname, cm);
         }
         if (cm != null) {
            curclassname = cm.class_name;
         }
      }


      //say("ctlminihtml1.on_change H"__LINE__": filename="filename);
      //say("ctlminihtml1.on_change H"__LINE__": linenum="linenum);
      //say("ctlminihtml1.on_change H"__LINE__": curclassname="curclassname);

      // Look up tags associated with this Href, result is in match set
      if (substr(hrefText,1,1)==JAVADOCHREFINDICATOR) {
         //say("ctlminihtml1.on_change H"__LINE__": JAVADOCHREFINDICATOR");

         VSAUTOCODE_ARG_INFO list[];
         status := geditorctl_wid.tag_match_href_text(hrefText, filename, linenum, curclassname);
         if (status < 0) {
            // populate the symbol information with a fake symbol that just says it wasn't found.
            // this is better than popping up an annoying message box
            tag_browse_info_init(auto cm);
            parse substr(hrefText, 2) with cm.member_name '(' cm.arguments ')' .;
            dot_pos := lastpos(cm.member_name, '#');
            if (dot_pos <= 0) dot_pos = lastpos(cm.member_name, '.');
            if (dot_pos <= 0) dot_pos = lastpos(cm.member_name, ':');
            if (dot_pos <= 0) dot_pos = lastpos(cm.member_name, '/');
            cm.class_name = substr(cm.member_name, 1, dot_pos);
            cm.member_name = substr(cm.member_name, dot_pos+1);
            prototype := geditorctl_wid.extension_get_decl(geditorctl_wid.p_LangId,cm,VSCODEHELPDCLFLAG_SHOW_CLASS|VSCODEHELPDCLFLAG_VERBOSE);
            tag_autocode_arg_info_from_browse_info(list[0], cm, prototype);
            list[0].ParamNum=-1;
            list[0].tagList[0].comments = nls('Could not find help for "%s"',substr(hrefText,2));

         } else {
            // remove duplicates or tags from binary sources
            tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false, 
                                                filterDuplicateGlobalVars:false, 
                                                filterDuplicateClasses:true, 
                                                filterAllImports:true,
                                                filterBinaryLoadedTags:true);

            // for each match, put it into the array
            n:=tag_get_num_of_matches();
            //say("ctlminihtml1.on_change: n="n);
            for (i:=0; i<n; ++i) {

            //say("ctlminihtml1.on_change: i="i);
               tag_get_match_info(i+1, auto cm);
               cm.language=geditorctl_wid.p_LangId;

               prototype := geditorctl_wid.extension_get_decl(geditorctl_wid.p_LangId,cm,VSCODEHELPDCLFLAG_SHOW_CLASS|VSCODEHELPDCLFLAG_VERBOSE);
               tag_autocode_arg_info_from_browse_info(list[i], cm, prototype);
               list[i].ParamNum=-1;
            }
         }

         if (stack.HyperTextTop<0) {
            ++stack.HyperTextTop;
            stack.HyperTextMaxTop=stack.HyperTextTop;
            if (doFunctionHelp) {
               stack.s[stack.HyperTextTop].TagIndex=gFunctionHelpTagIndex;
               stack.s[stack.HyperTextTop].TagList=gFunctionHelp_list;
            }
         }
         if(stack.HyperTextTop>=0) {
            _minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         ++stack.HyperTextTop;
         stack.HyperTextMaxTop=stack.HyperTextTop;
         stack.s[stack.HyperTextTop].TagIndex=0;
         stack.s[stack.HyperTextTop].TagList=list;
         HYPERTEXTSTACKDATA(stack);
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid, true);
      }
   }
}

void vscroll1.on_change()
{
   p_prev.p_y = -((p_value-1)*(p_prev.p_height intdiv p_max));
}
void vscroll1.on_scroll()
{
   p_prev.p_y = -((p_value-1)*(p_prev.p_height intdiv p_max));
}
#if 0
void picture1.on_create()
{
   //msg="int myclass::myproc(\1uint p1\1e,\1b\1iint \1\blong\1u long long p2\1e,\1iint p3\1e)\n";
   msg="int this is a test this is a sfsdfsfd thi sdfs";
   //msg=msg:+msg;
   //msg=msg:+msg;
  _DisplayFunctionHelp(msg," ",
                       //(_twips_per_pixel_x()*4),(_twips_per_pixel_y()*2),
                       0,0,
                       _dx2lx(SM_TWIP,200),p_font_name','p_font_size,
                     0x80000020,0x80000021,5000,0,F_BOLD);
}
#endif

// resize the form
static int _adjust_function_help_form_height(int y)
{
   int vx, vy, vwidth, vheight;
   geditorctl_wid._GetScreen(vx,vy,vwidth,vheight);
   int delta_h = _twips_per_pixel_y();
   if (y < ctlminihtml1.p_height+ctlsizebar.p_height+delta_h*4) {
      y = ctlminihtml1.p_height+ctlsizebar.p_height+delta_h*4;
   } else if (y > (vheight*_twips_per_pixel_y()*4) intdiv 5) {
      y = (vheight*_twips_per_pixel_y()*4) intdiv 5;
   }
   return y;
}
void ctlsizebar.lbutton_down()
{
   mou_mode(1);
   mou_release();
   mou_capture();
   selected_wid := p_window_id;

   // kill auto-complete if they are resizing function help
   isFunctionHelpForm := false;
   if (ginFunctionHelp && !gFunctionHelp_pending && 
       p_active_form==gFunctionHelp_form_wid) {
      isFunctionHelpForm = true;
      if (AutoCompleteActive()) {
         AutoCompleteTerminate();
         p_window_id = selected_wid;
      }
   }
   
   orig_minihtml_height := ctlminihtml2.p_height;

   // loop until we get the mouse-up event
   int orig_y=p_active_form.p_height;
   y := 0;
   for (;;) {
      _str event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         y=_adjust_function_help_form_height(p_active_form.mou_last_y('M'));
         p_active_form.p_height=y+ctlsizebar.p_height;
         ctlminihtml2.p_height+=(y-ctlpicture1.p_height);
         ctlpicture1.p_height=y;
         ctlsizebar.p_y=ctlpicture1.p_height;
         continue;
      case LBUTTON_UP:
         y=_adjust_function_help_form_height(p_active_form.mou_last_y('M'));
         p_active_form.p_height=y+ctlsizebar.p_height;
         ctlminihtml2.p_height+=(y-ctlpicture1.p_height);
         ctlpicture1.p_height=y;
         ctlsizebar.p_y=ctlpicture1.p_height;

         if (ctlminihtml2.p_height<orig_minihtml_height) {
            ctlminihtml2.p_text=ctlminihtml2.p_text; // hack, forces redraw of scrollbar
         }
         if (isFunctionHelpForm) {
            ctlsizebar.p_user=ctlminihtml2.p_height;
            _moncfg_append_retrieve(0, ctlsizebar.p_user, "_function_help_form.ctlsizebar.p_user");
         }
         mou_mode(0);
         mou_release();
         p_window_id=selected_wid;
         return;
      }
   }
}

/**
 * This function operates on a picture1 of the _function_help_form
 *
 * @param margin_text        margin text?
 * @param more_margin        margin ratio?
 * @param msg                message with optional line breaks and the
 *                           following font style encodings
 *                           <PRE>
 *                             \1b      Bold
 *                             \1i      Italic
 *                             \1u      Underline
 *                             \1e      End all styles
 *                           </PRE>
 * @param comments
 * @param sepchars           One or more characters after which line breaks
 *                           are allowed.  Space may be specified in this list.
 * @param pad_x              Amount in twips to pad left/right.
 * @param pad_y              Amount in twips to pad top/bottom.
 * @param max_width          Maximimum width of label text in twips.
 * @param font_string        Font to be used for label text
 * @param font_string_fixed  Font to be used for fixed with label text
 * @param fg                 RGB foreground color
 * @param bg                 RGB background colors
 * @param scroll_bar_height  If the label is taller than this, a scroll bar is used.
 * @param max_font_flags     Usually 0 is specified to indicate that
 *                           some font flags are used by that consistent
 *                           word wrap is not necessary.
 *                           -1 indicates that no font flags are used.
 *                           One or more of the flags below indicate
 *                           <PRE>
 *                                F_BOLD
 *                                F_ITALIC
 *                                F_UNDERLINE
 *                           </PRE>
 *                           the largest possible font case.  Then variations
 *                           in the font will give the same word wrap
 *                           results.
 */
static void _DisplayFunctionHelp(_str margin_text,
                                 double more_margin,
                                 _str msg,
                                 _str comments,_str sepchars,
                                 int pad_x,int pad_y,
                                 int max_width,
                                 _str font_string,
                                 _str font_string_fixed,
                                 int fg,int bg,
                                 int scroll_bar_height,
                                 int max_font_flags)
{
   ctlpicture1.p_x=0;
   ctlpicture1.p_y=0;
   ctlpicture1.p_visible=false;
   ctlpicture1.p_backcolor=0;
   fw := _dx2lx(SM_TWIP,ctlpicture1._frame_width());
   fh := _dy2ly(SM_TWIP,ctlpicture1._frame_width());
   ctlminihtml1.p_x=fw;ctlminihtml1.p_y=fh;
   if (msg=="") {
      ctlminihtml1.p_width=0;
      ctlminihtml1.p_height=0;
      ctlminihtml1.p_visible=false;
   } else {
      ctlminihtml1._InitBoldItalic(
         margin_text,
         more_margin,
         msg,sepchars,pad_x,pad_y,
         max_width,scroll_bar_height intdiv 2,
         font_string,
         font_string_fixed,
         p_forecolor,p_backcolor,max_font_flags
            );
      ctlminihtml1.p_visible=true;
   }
   /*maxheight1=(scroll_bar_height intdiv 2)-2*_twips_per_pixel_y();
   if (ctlminihtml1.p_height>maxheight1) {
      ctlminihtml1.p_height=maxheight1;
   } */
   if (comments!="") {
      scroll_bar_height-=ctlminihtml1.p_height;
      if (p_window_id==gFunctionHelp_form_wid &&
          isinteger(ctlsizebar.p_user) && 
          ctlsizebar.p_user>scroll_bar_height) {
         scroll_bar_height=ctlsizebar.p_user;
      }
      if (ctlminihtml1.p_height) {
         scroll_bar_height-=_twips_per_pixel_y()*2;
      }
      ctlminihtml2.p_MouseActivate=MA_NOACTIVATE;
      ctlminihtml2._InitBoldItalic("",0,
         comments,"",pad_x,pad_y,
         max_width,scroll_bar_height,
         font_string,
         font_string_fixed,
         p_forecolor,p_backcolor,0
       );
      // loop through a few divisors until we can resize the HTML text
      // into a reasonable proportion.  This is done this way to prevent
      // a long comment to be formatted as one big long line just because
      // someone's monitor is large enough to allow it.
      min_recommended_width := 320 * _twips_per_pixel_x();
      for (d := 2; d <= 5; d++) {
         if ((max_width intdiv d) <= min_recommended_width) {
            break;
         }
         if (ctlminihtml2.p_width <= min_recommended_width) {
            break;
         }
         if (ctlminihtml2.p_width <= ctlminihtml1.p_width) {
            break;
         }
         if (ctlminihtml2.p_width <= ctlminihtml2.p_height*2) {
            break;
         }
         prev_minihtml2_width := ctlminihtml2.p_width;;
         ctlminihtml2._InitBoldItalic("",0,
            comments,"",pad_x,pad_y,
            min(max_width, max(max_width intdiv d, ctlminihtml1.p_width)),
            scroll_bar_height,
            font_string,
            font_string_fixed,
            p_forecolor,p_backcolor,0
          );
         if (ctlminihtml2.p_width == prev_minihtml2_width) {
            break;
         }
      }
      if (msg=="") {
         ctlminihtml2.p_y=ctlminihtml1.p_height+fh;
      } else {
         ctlminihtml2.p_y=ctlminihtml1.p_height+fh+_twips_per_pixel_y();
      }
      ctlminihtml2.p_x=fw;
      if (ctlminihtml2.p_width>ctlminihtml1.p_width) {
         ctlminihtml1.p_width=ctlminihtml2.p_width;
      } else {
         ctlminihtml2.p_width=ctlminihtml1.p_width;
      }
      ctlpicture1.p_height=ctlminihtml2.p_y_extent+fh;
      ctlminihtml2.p_visible=true;
   } else {
      ctlsizebar.p_visible=false;
      ctlminihtml2.p_visible=false;
      ctlpicture1.p_height=ctlminihtml1.p_height+fh*2;
   }

   ctlpicture1.p_width=ctlminihtml1.p_width+fw*2;
   ctlsizebar.p_y=ctlpicture1.p_y_extent;
   ctlsizebar.p_width=ctlpicture1.p_width;
   ctlsizebar.p_x=ctlpicture1.p_x;
   ctlpicture1.p_visible=true;
   ctlminihtml1.p_MouseActivate=MA_NOACTIVATE;
   //messageNwait("max_x="max_x" max_width="max_width);
   int form_height=ctlpicture1.p_height+p_active_form._top_height()+p_active_form._bottom_height();
   if (comments!="" && p_window_id==gFunctionHelp_form_wid) {
      form_height+=ctlsizebar.p_height;
   } else if (ctlsizebar.p_visible) {
      form_height+=ctlsizebar.p_height;
   }
   p_active_form.p_height=form_height;
   p_active_form.p_width=ctlpicture1.p_width+p_active_form._left_width()*2;
   //say(".p_x="ctlminihtml1.p_x);
}

/**
 * Generic function for calling a (up-to) three argument function in an
 * embedded context.
 *
 * @param pfn            pointer to function to call
 * @param arg1           first argument for function call
 * @param arg2           second argument for function call
 * @param arg3           third argument for function call
 *
 * @return nothing
 */
void _EmbeddedCall(typeless pfn,typeless &arg1="",typeless &arg2="",typeless &arg3="")
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   (*pfn)(arg1,arg2,arg3);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }

}
/**
 * @return Returns the indentation amount for the current mode.
 */
int _get_enter_indent()
{
   orig_modify := p_modify;
   orig_line := p_line;
   _end_line();
   _str orig_def_keys=def_keys;
   def_keys="";
   last_event(ENTER);
   _argument=1;  // Don't want new undo step
   call_index(eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER)));
   _argument="";
   def_keys=orig_def_keys;
   indent_col := p_col;
   _delete_line();
   p_modify=orig_modify;
   if (p_line!=orig_line) up();
   return(indent_col-1);
}

/**
  Get the preferred line comment and multiple-line comment delimiters.
  Note that the best implementation of this function would get the
  information from the color coding, however for the moment, this
  function simply hard-codes the results for supported languages.

  @param ext              file extension, from extension setup
  @param slcomment_start  line comment start, eg. // for C++
  @param mlcomment_start  multiple line comment start
  @param mlcomment_end    multiple line comment end
*/
int get_comment_delims(_str &slcomment_start,
                       _str &mlcomment_start, 
                       _str &mlcomment_end,
                       bool &supportJavadoc=false)
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(1);
   }
   status := 0;
   index := _FindLanguageCallbackIndex("_%s_get_comment_delimits");
   if (index) {
      status = call_index(slcomment_start,mlcomment_start,mlcomment_end,index);
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      return(status);
   }
   status=0;
   supportJavadoc=false;
   // get the multi-line comment start string
   switch (p_LangId) {
   case "pas":
   case "mod":
      mlcomment_start = "(*";
      mlcomment_end   = "*)";
      slcomment_start = "";
      break;
   case "ada":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = "--";
      break;
   case "pl":
   case "bourneshell":
   case "csh":
   case "tcl":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = "#";
      break;
   case "bas":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = "'";
      break;
   case "f":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = "!";
      break;
   case "s":
   case "asm":
   case "masm":
   case "unixasm":
   case "asm390":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = ";";
      break;
   case "cob":
   case "cob74":
   case "cob2000":
      mlcomment_start = "";
      mlcomment_end   = "";
      slcomment_start = "      *";
      break;
   case "awk":
      mlcomment_start = "/*";
      mlcomment_end   = "*/";
      slcomment_start = "#";
      break;
   case "rul":
   case "c":
   case "js":
   //case "phpscript":
   case "idl":
   case "java":
   case "scala":
   case "groovy":
   case "jsl":
   case "cs":
   case "e":
   case "tagdoc":
   case "as":
   case "vera":
   case "verilog":
   case "systemverilog":
   case "m":
   case "googlego":
      supportJavadoc=true;
      mlcomment_start = "/*";
      mlcomment_end   = "*/";
      slcomment_start = "//";
      break;
   case "phpscript":
      mlcomment_start = "/*";
      mlcomment_end   = "*/";
      slcomment_start = "//";
      break;
   case "xml":
   case "html":
   case "cfml":
   case "docbook":
   case "dtd":
   case "xsd":
      mlcomment_start = "<!--";
      mlcomment_end   = "-->";
      slcomment_start = "";
      break;
   default:
      status=1;
      break;
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   return(status);
}

/**
  Create a javadoc-style comment for the current function

  @return 0 on success, <0 on error
*/
static int _javadoc_comment()
{
   return _document_comment(DocCommentTrigger1);
}


/**
 * Decide whether or not, based on current context, the javadoc
 * comment menu item should be enabled or disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_javadoc_comment(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() || target_wid.p_readonly_mode) {
      return(MF_GRAYED);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
   save_pos(auto p);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   context_id := tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   restore_pos(p);
   if (context_id <= 0) {
      return(MF_GRAYED);
   }
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   javadocSupported := false;
   if (get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || !javadocSupported) {
      return(MF_GRAYED);
   }
   status := _EmbeddedCallbackAvailable("_%s_generate_function");
   if (status) {
      return(MF_ENABLED);
   }
   status = _EmbeddedCallbackAvailable("_%s_fcthelp_get_start");
   if (status) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}


/**
 * Generate a javadoc-style comment for the current tag.  Will attempt
 * to convert the current comment to javadoc.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void javadoc_comment() name_info(","VSARG2_REQUIRES_EDITORCTL)
{
   _EmbeddedCall(_javadoc_comment);
}

bool is_javadoc_supported()
{
   if (!_haveContextTagging()) return false;
   _str junk1, junk2, junk3;
   javadoc_enabled := false;
   if(get_comment_delims(junk1, junk2, junk3, javadoc_enabled)) {
      javadoc_enabled=false;
   }
   return javadoc_enabled;
}

/**
 * Create error code for code help functions
 *
 * @param status     VSCODEHELPRC_*
 * @param errorArgs  list of arguments for error message
 *
 * @return text of error message
 */
_str _CodeHelpRC(int status, _str (&errorArgs)[])
{
   if (status >= 0) {
      if (errorArgs[0]._varformat() == VF_LSTR) {
         return nls(errorArgs[0], errorArgs);
      }
      return "";
   }
   if (errorArgs._length() > 0 && errorArgs[0]==null) errorArgs[0]="";
   switch (errorArgs._length()) {
   case 0:
      return get_message(status,"","");
   case 1:
      return get_message(status,errorArgs[0],"");
   case 2:
      return get_message(status,errorArgs[0],errorArgs[1]);
   case 3:
      return get_message(status,errorArgs[0],errorArgs[1],errorArgs[2]);
   case 4:
      return get_message(status,errorArgs[0],errorArgs[1],errorArgs[2],errorArgs[3]);
   default:
      return get_message(status,errorArgs[0],errorArgs[1],errorArgs[2],errorArgs[3],errorArgs[4]);
   }
}
/**
 * @return Return the current language type, checking to see if we
 * are in embedded code first.
 *
 * @see _do_list_members()
 * @categories Tagging_Functions
 * @deprecated Use {@link _GetEmbeddedLangId()}
 */
_str _EmbeddedExtension()
{
   return _GetEmbeddedLangId();
}
/**
 * @return Return the current language type, checking to see if we
 *         are in embedded code first.
 *
 * @see _do_list_members()
 * @categories Tagging_Functions
 */
_str _GetEmbeddedLangId()
{
   lang := p_LangId;
   typeless orig_values;
   int embedded=_EmbeddedStart(orig_values);
   if (embedded==2) {
      return(lang);
   }
   lang=p_LangId;
   if (embedded==1) {
      _EmbeddedEnd(orig_values);
   }
   return(lang);
}
static int _Embeddedfcthelp_get_start(_str (&errorArgs)[],
                                      bool OperatorTyped,
                                      bool cursorInsideArgumentList,
                                      int &FunctionNameOffset,
                                      int &ArgumentStartOffset,
                                      int &flags,
                                      int depth=0)
{
   lang := p_LangId;
   MaybeBuildTagFile(lang);
   if (_inJavadocSwitchToHTML()) {
      lang="html";
      MaybeBuildTagFile(lang);
   }
   errorArgs._makeempty();
   _UpdateContextAndTokens(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   /*
   Returns 2 to indicate that there is embedded language
   code, but in comment/in string like default processing
   should be performed.
   */
   if (embedded_status==2) {
      return(1);
   }
   if (embedded_status==1) {
      lang = p_LangId;
      MaybeBuildTagFile(lang);
   }
   index := _FindLanguageCallbackIndex("_%s_fcthelp_get_start",lang);
   //gFunctionHelp_fcthelp_get=find_index("_"p_LangId"_fcthelp_get",PROC_TYPE);
   if (!index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      //_message_box("Auto function help not supported for this language");
      return(1);
   }
   //status=call_index(false,prefixexp,lastid,lastidstart_col,info_flags,get_expression_info_index);
   int status=call_index(errorArgs,OperatorTyped,cursorInsideArgumentList,
                     FunctionNameOffset,ArgumentStartOffset,flags,
                     index);
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   return(status);
}
static int _Embeddedfcthelp_get(
                      _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   errorArgs._makeempty();
   _UpdateContextAndTokens(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   /*
   Returns 2 to indicate that there is embedded language
   code, but in comment/in string like default processing
   should be performed.
   */
   if (embedded_status==2) {
      return(1);
   }
   lang := p_LangId;
   if (_inJavadocSwitchToHTML()) lang="html";
   index := _FindLanguageCallbackIndex("_%s_fcthelp_get",lang);
   if (!index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      //_message_box("Auto function help not supported for this language");
      return(1);
   }
   //status=call_index(false,prefixexp,lastid,lastidstart_col,info_flags,get_expression_info_index);
   tag_lock_context(false);
   tag_lock_matches(true);
   int status=call_index(errorArgs,
                         FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth,
                         index);
   tag_unlock_context();
   tag_unlock_matches();
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   return(status);
}
/**
 * Is the expression under the cursor a valid ID expression,
 * as determined by the extension-specific get_expression_info hook function.
 * Works in embedded contexts.  Requires that 'lastid' is not empty.
 *
 * @return true if _[ext]_get_expression_info returns 0 (success)
 */
bool is_valid_idexp(_str &lastid)
{
   ext := "";

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   struct VS_TAG_RETURN_TYPE visited:[];
   int status=_Embeddedget_expression_info(false, ext, idexp_info, visited);
   lastid = idexp_info.lastid;

   return (status != 0 || lastid=="")? false:true;
}

int _doc_comment_get_expression_info(bool PossibleOperator, 
                                     VS_TAG_IDEXP_INFO &idexp_info, 
                                     VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                     int depth=0)
{
   if (_chdebug) {
      isay(depth, "_doc_comment_get_expression_info: possible_op="PossibleOperator" @"_QROffset()" ["p_line","p_col"]");
   }

   idexp_info.errorArgs._makeempty();
   orig_info_flags := idexp_info.info_flags;
   idexp_info.info_flags = VSAUTOCODEINFO_DO_LIST_MEMBERS;

   cfg := 0;
   if (PossibleOperator && p_col > 1) {
      left();cfg=_clex_find(0,'g');right();
   } else {
      cfg=_clex_find(0,'g');
   }

   typeless orig_pos;
   save_pos(orig_pos);

   // Handle the case where we have an identifier immediately
   // abutted with a comment and we are at the end of the identifier
   // For example:   /*comment*/i/*comment*/
   if (p_col>1 && cfg==CFG_COMMENT) {
      left();cfg=_clex_find(0,'g');right();
   }

   if (_chdebug > 9) {
      isay(depth, "_doc_comment_get_expression_info: lexed="cfg);
   }

   if (cfg != CFG_COMMENT) {
      restore_pos(orig_pos);
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   word_chars := _clex_identifier_chars();
   word_chars = stranslate(word_chars, '', '@');
   if (PossibleOperator) {
      left();
      ch := get_text_safe();
      switch (ch) {
      case "@":
      case "\\":
      case "#":
         // get the id after the dot
         // IF we are on a id character
         right();
         if (pos('['word_chars']',get_text_safe(),1,'r')) {
            start_col:=p_col;
            start_offset:= (int)point('s');
            _TruncSearchLine('[~'word_chars']|$','r');
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
         } else {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
         }
         idexp_info.prefixexp=ch;
         restore_pos(orig_pos);
         idexp_info.prefixexpstart_offset=(int)point('s');
         idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         return(0);
      case "=":
      case "/":
      case "<":
      case "&":
         restore_pos(orig_pos);
         status := _html_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
         if (status == 0) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         }
         restore_pos(orig_pos);
         return status;
      default:
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }

   // IF we are on an id character, find the end of the ID
   ch := get_text_safe();
   end_col := p_col;
   if (_clex_is_identifier_char(ch)) {
      _TruncSearchLine('[~'word_chars']|$','r');
      end_col = p_col;
   }

   left();
   ch = get_text_safe();
   start_col := p_col;
   start_offset:=(int)point('s');
   if (_clex_is_identifier_char(ch)) {
      search('[~'word_chars']\c|^\c','-rh@');
      start_col = p_col;
      start_offset = (int)point('s');
      left();
   }
   idexp_info.lastid="";
   if (end_col > start_col) {
      idexp_info.lastid=_expand_tabsc(start_col,end_col-start_col);
   }
   idexp_info.lastidstart_col=start_col;
   idexp_info.lastidstart_offset=start_offset;
   orig_idexp_info := idexp_info;

   // now check what we have before the identifier
   ch = get_text_safe();
   switch (ch) {
   case "@":
   case "\\":
      idexp_info.prefixexp=ch;
      idexp_info.prefixexpstart_offset=(int)point('s');
      idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      restore_pos(orig_pos);
      return(0);
   case "<":
   case "/":
   case "=":
   case "&":
      restore_pos(orig_pos);
      status := _html_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
      if (status == 0) {
         idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      } else if (orig_idexp_info.lastid != "") {
         idexp_info = orig_idexp_info;
         idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         status = 0;
      }
      restore_pos(orig_pos);
      return status;
   case " ":
   case "\t":
   case "#":
      while (p_col > 1 && (ch == " " || ch == "\t")) {
         left();
         ch = get_text_safe();
      }
      if (_clex_is_identifier_char(ch)) {
         end_prefixexp_col := p_col;
         search('[~'word_chars']\c|^\c','-rh@');
         left();
         ch = get_text_safe();
         switch (ch) {
         case "@":
         case "\\":
            idexp_info.prefixexpstart_offset = (int)point('s');
            idexp_info.prefixexp = get_text_safe(end_prefixexp_col-p_col+1);
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
            restore_pos(orig_pos);
            return(0);
         }
      }

      restore_pos(orig_pos);
      tag := "";
      if (_inJavadocSeeTag(tag)) {
         restore_pos(orig_pos);
         index := _FindLanguageCallbackIndex("_%s_get_expression_info");
         if (index > 0 && index_callable(index)) {
            tag_idexp_info_init(idexp_info);
            status = call_index(PossibleOperator, idexp_info, visited, depth+1, index);
            restore_pos(orig_pos);
            return status;
         }
      }

      restore_pos(orig_pos);
      status = _html_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
      if (status == 0) {
         idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      } else if (orig_idexp_info.lastid != "") {
         idexp_info = orig_idexp_info;
         idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         status = 0;
      }
      restore_pos(orig_pos);
      return status;
   default:
      restore_pos(orig_pos);
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   restore_pos(orig_pos);
   return(VSCODEHELPRC_CONTEXT_NOT_VALID);
}

/**
 * Get the information about the word under the cursor by calling
 * the language-specific _[lang_id]_get_expression_info hook function. 
 * Also works in embedded contexts.
 *
 * @param PossibleOperator    could this be an operator just typed?
 * @param lang                current langauge ID
 * @param idexp_info          information about the expression 
 * @param visited             hash table of prior symbol analysis results 
 * @param depth               recursive depth for logging
 *
 * @return 0 on success, <0 on error, errorArgs has error arguments.
 * @since 11.0 
 * @categories Tagging_Functions
 */
int _Embeddedget_expression_info(bool PossibleOperator, _str &lang,
                                 VS_TAG_IDEXP_INFO &idexp_info,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   _str errorArgs[];
   tag_idexp_info_init(idexp_info);
   if (_chdebug) {
      isay(depth, "_Embeddedget_expression_info: file="_strip_filename(p_buf_name,'p')", line="p_RLine" col="p_col);
   }
   
   // Returns 2 to indicate that there is embedded language code, 
   // but in comment/in string like default processing should be performed.
   embedded_status := _EmbeddedStart(auto orig_values);
   if (embedded_status==2) {
      if (_chdebug) {
         isay(depth, "_Embeddedget_expression_info: embedded_status==2");
      }
      return(1);
   }
   // check if tagging is supported in this context
   if (!_istagging_supported(p_LangId) && upcase(substr(p_lexer_name,1,3))!="XML") {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         isay(depth, "_Embeddedget_expression_info: no tagging support");
      }
      return(1);
   }

   status := 0;
   lang = p_LangId;
   if (idexp_info.info_flags & VSAUTOCODEINFO_DO_ACTION_MASK) {
      MaybeBuildTagFile(lang);
      if (_inDocComment()) {
         status = _doc_comment_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
         if (status == 0) {
            if (_chdebug) {
               isay(depth, "_Embeddedget_expression_info: doc comment succeeded");
            }
            return status;
         }
      }
   }

   if (!_haveContextTagging()) {
      // for SlickEdit Standard edition, just try default version
      status = _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_Embeddedget_expression_info: (no context tagging: using _do_default_get_expression_info)");
         isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset()" status="status);
         get_line(auto line);
         isay(depth, "   LINE="line);
         tag_idexp_info_dump(idexp_info, "   DEFAULT IDEXP_INFO: ", depth);
         gIDExprFailed = true;
         isay(depth, "_Embeddedget_expression_info: ==================================");
      }

   } else if (_chdebug) {

      // check for the latest fast version of callback (in DLL, using token list)
      fast_get_index := _FindLanguageCallbackIndex("vs%s_get_expression_info",lang);
      get_index := 0;
      if (fast_get_index == 0 || _chdebug) {
         get_index = _FindLanguageCallbackIndex("_%s_get_expression_info",lang);
      }
      // xml can use HTML callback if it doesn't have one of it's own
      if (!get_index && upcase(substr(p_lexer_name,1,3))=="XML") {
         get_index=find_index("_html_get_expression_info",PROC_TYPE);
         fast_get_index = 0;
      }
      // if the file is too big for building a token list quickly, drop back to
      // slower get_expression_info() callback that searches editor buffer
      // rather than using token list.
      if (!_CheckUpdateContextSizeLimits(VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens, true)) {
         fast_get_index = 0;
      }
      if (fast_get_index != 0 && get_index != 0) {
         _UpdateContextAndTokens(true);
         _UpdateLocals(true);

         orig_time := (long)_time('b');
         VS_TAG_IDEXP_INFO new_idexp_info;
         tag_idexp_info_init(new_idexp_info);
         new_status := call_index(PossibleOperator, 
                                  _QROffset(), 
                                  new_idexp_info,
                                  errorArgs, 
                                  fast_get_index);
         new_time := (long)_time('b');
         gnew_total_time += (new_time - orig_time);

         // Call new version
         orig_time = (long)_time('b');
         status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
         new_time = (long)_time('b');
         gold_total_time += (new_time - orig_time);

         if (new_status == 0 && status == 0) {
            if (idexp_info.prefixexp=="") {
               idexp_info.prefixexpstart_offset=new_idexp_info.prefixexpstart_offset;
            }
            if (stranslate(new_idexp_info.prefixexp, "", " ") != stranslate(idexp_info.prefixexp, "", " ") ||
                new_idexp_info.lastid                != idexp_info.lastid                ||
                new_idexp_info.lastidstart_col       != idexp_info.lastidstart_col       ||
                new_idexp_info.lastidstart_offset    != idexp_info.lastidstart_offset    ||
                new_idexp_info.prefixexpstart_offset != idexp_info.prefixexpstart_offset ||
                new_idexp_info.otherinfo             != idexp_info.otherinfo             ||
                new_idexp_info.info_flags            != idexp_info.info_flags
               ) {
               get_line(auto line);
               isay(depth, "_Embeddedget_expression_info: ==================================");
               isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset());
               isay(depth, "   LINE="line);
               tag_idexp_info_dump(new_idexp_info, "   NEW: ", depth);
               tag_idexp_info_dump(idexp_info,     "   OLD: ", depth);
               gIDExprFailed = true;
               isay(depth, "_Embeddedget_expression_info: ==================================");
            } else if (_chdebug > 1) {
               isay(depth, "_Embeddedget_expression_info: ==================================");
               isay(depth, "ID EXPRESSION INFO MATCHES at "_QROffset());
               tag_idexp_info_dump(new_idexp_info, "   IDEXP_INFO: ", depth);
               isay(depth, "_Embeddedget_expression_info: ==================================");
            }
         } else if (new_status == 0 && status < 0) {
            if (_chdebug > 1) {
               isay(depth, "_Embeddedget_expression_info: ==================================");
               isay(depth, "   ID EXPRESSION INFO WORKS WHERE OLD VERSION FAILS at "_QROffset());
               if (_clex_find(0,'g')==CFG_COMMENT) {
                  isay(depth, "   COMMENT CASE ");
               }
               if (new_idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS) {
                  isay(depth, "   PREPROCESSING CASE ");
               }
               tag_idexp_info_dump(new_idexp_info, "   IDEXP_INFO: ", depth);
               isay(depth, "_Embeddedget_expression_info: ==================================");
               idexp_info = new_idexp_info;
               status = new_status;
            }
         } else if (new_status < 0 && status < 0) {
            if (_chdebug > 1) {
               isay(depth, "   ID EXPRESSION INFO FAIL MATCHES at "_QROffset());
            }
         } else {
            isay(depth, "_Embeddedget_expression_info: ==================================");
            get_line(auto line);
            isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset());
            isay(depth, "   LINE="line);
            isay(depth, "   NEW status="new_status);
            isay(depth, "   OLD status="status);
            if (new_status == 0) tag_idexp_info_dump(new_idexp_info, "   NEW: ", depth);
            if (status == 0)     tag_idexp_info_dump(idexp_info,     "   OLD: ", depth);
            gIDExprFailed = true;
            isay(depth, "_Embeddedget_expression_info: ==================================");
         }

      } else if(get_index != 0) {
         // Call new version
         status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
         isay(depth, "_Embeddedget_expression_info: (using "name_name(get_index)")");
         isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset()" status="status);
         get_line(auto line);
         isay(depth, "   LINE="line);
         tag_idexp_info_dump(idexp_info, "   IDEXP_INFO: ", depth);
         gIDExprFailed = true;
         isay(depth, "_Embeddedget_expression_info: ==================================");

      } else {
         // Could not find new version, try old.
         get_index = _FindLanguageCallbackIndex("_%s_get_idexp",lang);
         if (get_index != 0) {
            // Call old version
            status=call_index(idexp_info.errorArgs, PossibleOperator, 
                              idexp_info.prefixexp, idexp_info.lastid,
                              idexp_info.lastidstart_col, idexp_info.lastidstart_offset,
                              idexp_info.info_flags, idexp_info.otherinfo, 
                              idexp_info.prefixexpstart_offset, get_index);
            isay(depth, "_Embeddedget_expression_info: (using "name_name(get_index)")");
            isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset()" status="status);
            get_line(auto line);
            isay(depth, "   LINE="line);
            tag_idexp_info_dump(idexp_info, "   IDEXP_INFO: ", depth);
            gIDExprFailed = true;
            isay(depth, "_Embeddedget_expression_info: ==================================");
         } else {
            // Try default version
            status=_do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
            isay(depth, "_Embeddedget_expression_info: (using _do_default_get_expression_info)");
            isay(depth, "   p_line="p_line" p_col="p_col" offset="_QROffset()" status="status);
            get_line(auto line);
            isay(depth, "   LINE="line);
            tag_idexp_info_dump(idexp_info, "   IDEXP_INFO: ", depth);
            gIDExprFailed = true;
            isay(depth, "_Embeddedget_expression_info: ==================================");
         }
      }

   } else {

      do {
         // Try the faster version written in C code
         fast_get_index := _FindLanguageCallbackIndex("vs%s_get_expression_info",lang);

         // if the file is too big for building a token list quickly, drop back to
         // slower get_expression_info() callback that searches editor buffer
         // rather than using token list.
         if (!_CheckUpdateContextSizeLimits(VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens, true)) {
            fast_get_index = 0;
         }

         // Call the fast version
         if (fast_get_index != 0 && index_callable(fast_get_index)) {
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
            status = call_index(PossibleOperator, _QROffset(), idexp_info, errorArgs, fast_get_index);
            //say("_Embeddedget_expression_info: status="status" file="p_buf_name" line="p_line" col="p_col);
            if (!(p_embedded!=0 && status < 0)) break;
            tag_idexp_info_init(idexp_info);
            status = 0; 
         }

         // Look for a macro version
         get_index := _FindLanguageCallbackIndex("_%s_get_expression_info",lang);
         if (!get_index && upcase(substr(p_lexer_name,1,3))=="XML") {
            get_index=find_index("_html_get_expression_info",PROC_TYPE);
         }
         if (get_index != 0 && index_callable(get_index)) {
            status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
            break;
         }

         // Try the old, old macro version of this function
         get_index = _FindLanguageCallbackIndex("_%s_get_idexp",lang);
         if (get_index != 0 && index_callable(get_index)) {
            // Call old version
            status = call_index(idexp_info.errorArgs,
                                PossibleOperator,
                                idexp_info.prefixexp,
                                idexp_info.lastid,
                                idexp_info.lastidstart_col,
                                idexp_info.lastidstart_offset,
                                idexp_info.info_flags,
                                idexp_info.otherinfo,
                                idexp_info.prefixexpstart_offset,
                                get_index);
            break;
         } 

         // Try default version
         status = _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);

      } while (false);
   }
//   say("   p_LangId="p_LangId);
//   say("   _Embeddedget_expression_info: PossibleOperator="PossibleOperator);
//   tag_idexp_info_dump(idexp_info,"_Embeddedget_expression_info");
//   say("   _Embeddedget_expression_info: get_expression_info_index="get_expression_info_index);
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   if (_chdebug) {
      isay(depth, "_Embeddedget_expression_info: status="status" prefixexp="idexp_info.prefixexp" lastid="idexp_info.lastid" col="idexp_info.lastidstart_col);
   }
   return(status);
}

/**
 * Get the information about the word under the cursor by calling
 * the extension-specific _[ext]_get_expression_info hook function.  Works in
 * embedded contexts.
 *
 * @param ext                      set the [embedded] extension
 * @param errorArgs                error message arguments
 * @param PossibleOperator         could this be an operator just typed?
 * @param prefixexp                what is the prefix expression
 * @param prefixexpstart_offset    start offset of prefix expresssion
 * @param lastid                   last id looked up
 * @param lastidstart_col          start column of last id
 * @param lastidstart_offset       start offset of last id
 * @param info_flags               VSCODEHELPINFO_*
 * @param otherinfo                extension-specific supplementary information.
 *
 * @return 0 on success, <0 on error, errorArgs has error arguments.
 * @deprecated use _Embedded_get_expression_info instead
 */
int _Embeddedget_idexp(_str &ext,
                       _str (&errorArgs)[],
                       bool PossibleOperator,
                       _str &prefixexp,
                       int &prefixexpstart_offset,
                       _str &lastid,
                       int &lastidstart_col,
                       int &lastidstart_offset,
                       int &info_flags,
                       typeless &otherinfo,
                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   int status = _Embeddedget_expression_info(PossibleOperator,ext,idexp_info,visited,depth+1);
   errorArgs               = idexp_info.errorArgs;
   prefixexp               = idexp_info.prefixexp;
   prefixexpstart_offset   = idexp_info.prefixexpstart_offset;
   lastid                  = idexp_info.lastid;
   lastidstart_col         = idexp_info.lastidstart_col;
   lastidstart_offset      = idexp_info.lastidstart_offset;
   info_flags              = idexp_info.info_flags;
   otherinfo               = idexp_info.otherinfo;

   return status;
}

int _Embeddedanalyze_return_type(int ar_index,_str (&errorArgs)[],
                                 typeless tag_files,
                                 struct VS_TAG_BROWSE_INFO cm,
                                 _str expected_type,
                                 struct VS_TAG_RETURN_TYPE &rt,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // select the embedded mode
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(1);
   }
   // analyze the expected return type
   int status = call_index(errorArgs,tag_files,
                           cm.member_name, cm.class_name, cm.type_name,
                           cm.flags, cm.file_name, expected_type,
                           rt,visited, ar_index);
   //say("_Embeddedanalyze_return_type: status="status);
   // drop out of embedded mode
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   // double check the status and return type
   if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
      return(status);
   }
   if (rt.return_type=="") {
      errorArgs[1] = expected_type;
      return(VSCODEHELPRC_RETURN_TYPE_NOT_FOUND);
   }
   return(0);
}
/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param ar_index       index of function for analyzing return types
 * @param rt_index       return type matching function
 * @param fm_index       index of function to find members of enum
 * @param tag_files      array of tag files
 * @param param_name     name of function parameter being matched
 * @param lastid_prefix  word prefix to search for 
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param num_matches    number of candidates looked at
 * @param max_matches    maximum number of candidates to look at
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 * @param visited        visitation cache 
 * @param depth          recursive search depth counter
 *
 * @return number of items inserted
 */
static int _list_matching_constants(struct VS_TAG_RETURN_TYPE &rt_expected,
                                    int ar_index,int rt_index, int fm_index,
                                    typeless tag_files,
                                    _str param_name, _str param_default,
                                    _str lastid_prefix, int tree_wid, int tree_index,
                                    int num_matches, int max_matches,
                                    bool exact_match, bool case_sensitive,
                                    struct VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // find the insert constants callback
   cs_index := _FindLanguageCallbackIndex("_%s_insert_constants_of_type");
   if (!cs_index) {
      return(0);
   }
   int count=call_index(rt_expected,
                        tree_wid,tree_index,
                        lastid_prefix,
                        exact_match,case_sensitive,
                        param_name, param_default,
                        visited, depth+1,
                        cs_index);

   // special case for enumerated types
   inner_name := outer_name := "";
   tag_split_class_name(rt_expected.return_type,inner_name,outer_name);
   if (fm_index && tag_check_for_enum(inner_name,outer_name,tag_files,p_EmbeddedCaseSensitive,visited,depth+1)) {

      // find the members of the enumerated type
      tag_push_matches();
      prefixexp := "";
      call_index(rt_expected,
                 outer_name,"enum",0,"",0,prefixexp,
                 tag_files,SE_TAG_FILTER_ENUM,
                 visited, depth+1,
                 fm_index);

      // copy the current match set and then clear it
      VS_TAG_BROWSE_INFO matches[];
      tag_get_all_matches(matches);
      tag_clear_matches();
      tag_pop_matches();

      // and insert them into the tree (the types will match)
      count += _list_matching_arguments(matches, 
                                        rt_expected,
                                        ar_index,rt_index,
                                        param_name, "", lastid_prefix,
                                        tag_files,
                                        tree_wid, tree_index,
                                        num_matches,max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth+1);
   }
   // return total number of items inserted
   return(count);
}
static int _analyze_return_type(struct VS_TAG_RETURN_TYPE &rt_candidate,
                                int ar_index,_str prefixexp,typeless tag_files,
                                _str tag_name,_str class_name,_str type_name,
                                SETagFlags tag_flags,_str file_name,_str return_type,
                                struct VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // check if this has been tried before
   status := 0;
   key := "#;"/*prefixexp";"*/class_name";"type_name";"tag_flags";"file_name";"return_type;
   //say("_analyze_return_type: key="key);
   if (!visited._indexin(key)) {
      // analyze the candidate tag's return type
      _str errorArgs[];errorArgs._makeempty();
      tag_return_type_init(rt_candidate);
      status = call_index(errorArgs,tag_files,
                          tag_name,class_name,type_name,tag_flags,file_name,
                          return_type,rt_candidate,visited,depth+1,
                          ar_index);
      // return type analysis failed
      if ((status && status!=VSCODEHELPRC_BUILTIN_TYPE)) {
         tag_return_type_init(rt_candidate);
         visited:[key]=null;
      } else {
         visited:[key]=rt_candidate;
      }
      //say("_list_matching_arguments: tag="tag_name" time="(int)_time('b')-orig_time);
      //say("_analyze_return_type: COMPUTE key="key);
   } else if (visited:[key]==null) {
      //say("_analyze_return_type: SHORTCUT failure");
      tag_return_type_init(rt_candidate);
      return(VSCODEHELPRC_RETURN_TYPE_NOT_FOUND);
   } else {
      //say("_analyze_return_type: SHORTCUT success");
      //say("_analyze_return_type: shortcut, key="key);
      rt_candidate=visited:[key];
   }
   return(status);
}
/**
 * Insert the items from the current match set that match the expected
 * return type, according to language-specific type-matching rules.
 *  
 * @param matches        array of symbol matches to try 
 * @param rt_expected    expected return type
 * @param ar_index       name table index for function to analyze return type
 * @param rt_index       name table index for function to insert matching return types
 * @param prefixexp      prefix to insert before anything we match
 * @param lastid         word prefix to search for 
 * @param tag_files      array of tag file paths
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param num_matches    number of candidates checked
 * @param max_matches    maximum number of matches to try
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 * @param visited        hash table of cached results
 *
 * @return number of matches inserted
 */
static int _list_matching_arguments(struct VS_TAG_BROWSE_INFO (&matches)[],
                                    struct VS_TAG_RETURN_TYPE &rt_expected,
                                    int ar_index, int rt_index,
                                    _str param_name, _str prefixexp,_str lastid,
                                    typeless tag_files,
                                    int tree_wid, int tree_index,
                                    int &num_matches, int max_matches,
                                    bool exact_match, bool case_sensitive,
                                    struct VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_list_matching_arguments: IN");
   }
   //int orig_time=(int)_time('b');
   // filter flags for searching
   filter_flags := SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ENUM|SE_TAG_FILTER_DEFINE;

   // for each match, first match the return types
   match_count := 0;
   n := matches._length();
   for (i:=0; i<n; ++i) {

      // past stopping point
      if (++num_matches > max_matches) {
         return(match_count);
      }

      // if something is going on, get out of here
      if (_CheckTimeout()) {
         return(match_count);
      }
      if ( i%32 == 0 ) {
         if( _IsKeyPending() ) {
            return(match_count);
         }
      }

      VS_TAG_BROWSE_INFO cm = matches[i];
      if (cm == null) continue;

      if (_chdebug) {
         isay(depth, "_list_matching_arguments: match["i"].name="cm.member_name" type="cm.return_type);
      }

      // make sure that this is a prefix match for the current symbol
      if (!_CodeHelpDoesIdMatch(lastid, cm.member_name, exact_match, case_sensitive)) {
         continue;
      }

      // make sure that it is the right type of symbol also
      if (tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,cm.type_name,(int)cm.flags) &&
          !(cm.flags & SE_TAG_FLAG_OPERATOR) &&
          !(cm.flags & SE_TAG_FLAG_CONST_DESTR)) {

         // check if this has been tried before
         //int orig_time=(int)_time('b');
         tag_push_matches();
         struct VS_TAG_RETURN_TYPE rt_candidate;
         tag_return_type_init(rt_candidate);
         status := _analyze_return_type(rt_candidate,ar_index,
                                        prefixexp,tag_files,
                                        cm.member_name,cm.class_name,cm.type_name,
                                        cm.flags,cm.file_name,cm.return_type,
                                        visited, depth+1);
         tag_pop_matches();
         if (_chdebug) {
            isay(depth, "_list_matching_arguments: status="status" evaluted_type="rt_candidate.return_type);
         }

         // success, now match return types for this tag
         if (rt_candidate.return_type!="") {
            match_count+=call_index(rt_expected,rt_candidate,
                                    cm.member_name,cm.type_name,cm.flags,cm.file_name,cm.line_no,
                                    prefixexp,tag_files,tree_wid,tree_index,visited,depth+1,
                                    rt_index);
         }
         // if matching members of a prefix expression, stop after first match
         if (match_count>0 && tree_wid==0 && tree_index>0) {
            break;
         }
      }
   }
   //say("_list_matching_arguments: time="(int)_time('b')-orig_time);
   return(match_count);
}
static int _list_matching_members(struct VS_TAG_BROWSE_INFO (&matches)[],
                                  struct VS_TAG_RETURN_TYPE &rt_expected,
                                  int ar_index, int rt_index, int fm_index,
                                  _str prefixexp, _str lastid_prefix,
                                  typeless tag_files,
                                  bool matchAnyObject,
                                  int &num_matches, int max_matches,
                                  bool exact_match, bool case_sensitive,
                                  struct VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // filter flags for searching
   //say("_list_matching_members: here, prefix="prefixexp"=");
   filter_flags := SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_STRUCT;

   // for each match, first match the return types
   match_count := 0;
   n := matches._length();
   for (i:=0; i<n; ++i) {

      // past stopping point
      if (++num_matches > max_matches) {
         return(match_count);
      }

      // if something is going on, get out of here
      if( _IsKeyPending() ) {
         return(match_count);
      }
      if (_CheckTimeout()) {
         return(match_count);
      }

      VS_TAG_BROWSE_INFO cm = matches[i];
      if (cm == null) continue;
      if (tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,cm.type_name,(int)cm.flags) &&
          !(cm.flags & SE_TAG_FLAG_OPERATOR)) {

         tag_push_matches();
         struct VS_TAG_RETURN_TYPE rt_candidate;
         int status=_analyze_return_type(rt_candidate,ar_index,
                                         prefixexp,tag_files,
                                         cm.member_name,cm.class_name,cm.type_name,
                                         cm.flags,cm.file_name,cm.return_type,
                                         visited, depth+1);
         tag_pop_matches();

         // success, now match return types for this tag
         if (!status && rt_candidate.return_type!="" && rt_candidate.taginfo!="") {
            rtc_type := tag_get_tag_type_of_return_type(rt_candidate);
            if (tag_tree_type_is_class(rtc_type)) {
               count := 1;
               orig_prefixexp := prefixexp;
               if ( !matchAnyObject ) {
                  tag_push_matches();
                  call_index(rt_candidate,
                             cm.member_name,cm.type_name,cm.flags,cm.file_name,cm.line_no,
                             prefixexp,tag_files,filter_flags,visited,depth+1,
                             fm_index);

                  // copy the current match set and then clear it
                  VS_TAG_BROWSE_INFO rt_matches[];
                  tag_get_all_matches(rt_matches);
                  tag_clear_matches();
                  tag_pop_matches();

                  count = _list_matching_arguments(rt_matches,
                                                   rt_expected,
                                                   ar_index,rt_index,
                                                   "", prefixexp, lastid_prefix,
                                                   tag_files,
                                                   0,0,//tree_wid,tree_index,
                                                   num_matches, max_matches,
                                                   exact_match, case_sensitive,
                                                   visited, depth+1);
                  //say("_list_matching_members: tag_name="tag_name" count="count);
               } else {
                  prefixexp = cm.member_name;
                  cm.type_name = rtc_type;
               }

               match_count+=count;
               if (count>0 && prefixexp!="") {
                  if (cm.type_name=="proto" && (cm.flags & SE_TAG_FLAG_MAYBE_VAR)) cm.type_name="var";
                  tag_tree_insert_tag(0,0,0,-1,TREE_ADD_AS_CHILD,prefixexp,cm.type_name,cm.file_name,cm.line_no,"",(int)cm.flags,"",cm.file_name":"cm.line_no);
               }
               prefixexp=orig_prefixexp;
            }
         }
      }
   }
   return(match_count);
}

int _Embeddedinsert_auto_params(_str (&errorArgs)[],
                                int editorctl_wid,
                                int tree_wid,
                                _str prefixexp,
                                _str lastid,
                                _str lastid_prefix,
                                int lastidstart_offset,
                                _str expected_type,
                                VS_TAG_RETURN_TYPE &rt,
                                _str expected_name,
                                int info_flags,typeless otherinfo,
                                VS_TAG_RETURN_TYPE (&visited):[], 
                                int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_Embeddedinsert_auto_params("prefixexp","lastid","lastid_prefix","otherinfo","expected_type")");
   }
   // check for embedded mode
   embedded_status := editorctl_wid._EmbeddedStart(auto orig_values);

   // find the functions to analyze and match return types
   ar_index := editorctl_wid._FindLanguageCallbackIndex("_%s_analyze_return_type");
   if (!ar_index) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: H"__LINE__": no _lang_analyze_return_type");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }
   rt_index := editorctl_wid._FindLanguageCallbackIndex("_%s_match_return_type");
   if (!rt_index) {
      rt_index = find_index("_do_default_match_return_type",PROC_TYPE);
   }
   if (!index_callable(rt_index)) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: H"__LINE__": no _lang_match_return_type");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }
   fm_index := editorctl_wid._FindLanguageCallbackIndex("_%s_find_members_of");
   if (fm_index && !index_callable(fm_index)) {  // fm_index is optional
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: H"__LINE__": no _lang_find_members_of");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   // not supported in C++ constructor initializer lists (yet)
   if (info_flags & VSAUTOCODEINFO_IN_INITIALIZER_LIST) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: H"__LINE__": initializer list");
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("_Embeddedinsert_auto_params: past find_index");
   sc.lang.ScopedTimeoutGuard timeout(def_tag_max_list_matches_time);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   editorctl_wid._UpdateContextAndTokens(true);
   editorctl_wid._UpdateLocals(true);

   typeless tag_files=editorctl_wid.tags_filenamea(editorctl_wid.p_LangId);
   status := 0;
   if (expected_type!="" && (rt==null || rt.return_type==null || rt.return_type != expected_type)) {
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: expected type="expected_type);
      }
      // get the function, class, and file location for the current function call
      tag_init_tag_browse_info(auto func_cm);
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         int i=gFunctionHelpTagIndex;
         n := gFunctionHelp_list._length();
         if (i>=0 && i<n) {
            func_cm = gFunctionHelp_list[i].tagList[0].browse_info;
            if (func_cm == null) {
               func_info := gFunctionHelp_list[i].tagList[0].taginfo;
               tag_decompose_tag_browse_info(func_info, func_cm);
               func_cm.file_name = gFunctionHelp_list[i].tagList[0].filename;
            }
         }
         if (func_cm.member_name=="") {
            if (embedded_status==1) {
               editorctl_wid._EmbeddedEnd(orig_values);
            }
            return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
         }
      }

      //isay(depth, "_Embeddedinsert_auto_params: analyze");
      // analyze the given return type
      VS_TAG_RETURN_TYPE dummy_rt;
      tag_return_type_init(dummy_rt);
      rt=dummy_rt;
      status=editorctl_wid._Embeddedanalyze_return_type(ar_index,
                                                        errorArgs,
                                                        tag_files,
                                                        func_cm,
                                                        expected_type,
                                                        rt,
                                                        visited);
      if (_chdebug) {
         isay(depth, "_Embeddedinsert_auto_params: expected="rt.return_type" pointers="rt.pointer_count);
      }
      if (info_flags & VSAUTOCODEINFO_HAS_REF_OPERATOR) {
         //isay(depth, "_Embeddedinsert_auto_params: REF OPERATOR, otherinfo="otherinfo"=");
         if (otherinfo == "*") {
            ++rt.pointer_count;
         } else if (otherinfo == "&") {
            --rt.pointer_count;
         }
      }
   }
   if (_chdebug) {
      isay(depth, "_Embeddedinsert_auto_params: match_type="rt.return_type" expected_type="expected_type" status="status);
   }
   if (_CheckTimeout()) status = TAGGING_TIMEOUT_RC;
   if (status) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      return(status);
   }

   // number of candidates looked at
   num_candidates := 0;

   // update the list of variables
   vars_count :=0;

   // first insert language-specific builtin constants
   if (prefixexp=="") {

      // calculate the default initializer for this parameter
      eq_pos  := lastpos('=', expected_type);
      init_to := (eq_pos > 0)? substr(expected_type, eq_pos+1) : null;
      if (eq_pos > 0 && pos(')', init_to) && !pos('(', init_to)) {
         init_to = null;
      }

      vars_count+=editorctl_wid._list_matching_constants(rt,
                                                         ar_index,
                                                         rt_index,
                                                         fm_index,
                                                         tag_files,
                                                         expected_name,
                                                         init_to,
                                                         lastid_prefix,
                                                         tree_wid, 0,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited, depth+1);
   }

   // find all tags visible in the current context
   tag_push_matches();
   errorArgs._makeempty();
   status = editorctl_wid._Embeddedfind_context_tags(errorArgs,
                                                     prefixexp,
                                                     lastid_prefix,
                                                     lastidstart_offset,
                                                     info_flags,
                                                     otherinfo,
                                                     false,
                                                     def_tag_max_list_matches_symbols,
                                                     false,
                                                     editorctl_wid.p_EmbeddedCaseSensitive,
                                                     SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_DEFINE|SE_TAG_FILTER_ENUM,
                                                     SE_TAG_CONTEXT_ONLY_CONTEXT|SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                     visited, depth+1);

   // copy the current match set and then clear it
   VS_TAG_BROWSE_INFO matches[];
   tag_get_all_matches(matches);
   tag_clear_matches();
   tag_pop_matches();

   if (_chdebug) {
      isay(depth, "_Embeddedinsert_auto_params: find context tags, status="status" num_matches="matches._length());
   }
   if (status >= 0) {
      // for each match, first match the return types
      vars_count+=editorctl_wid._list_matching_arguments(matches,
                                                         rt,
                                                         ar_index,rt_index,
                                                         expected_name, prefixexp, lastid_prefix,
                                                         tag_files,
                                                         tree_wid, 0,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited, depth+1);
   }
   if (status >= 0) {
      vars_count += editorctl_wid._list_matching_members(matches, rt,
                                                         ar_index,rt_index,fm_index,
                                                         prefixexp, lastid_prefix,
                                                         tag_files, 
                                                         true,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited, depth+1);
   }

#if 0
   // NOTE:
   //
   // THIS FEATURE IS DISABLED IN 11.0.
   //
   // It was never really useful and always was a big performance hit.
   // It is really sufficient to only list variables which match the
   // return type exactly.
   //
   // set up for updating the tree
   int exprs_count=0,exprs_root=TREE_ROOT_INDEX;
   static _str exprs_prefix;
   if (tree_wid==0 || tree_wid._CodeHelpBeginUpdate(VSCODEHELP_TITLE_exprs,
                                                    ""/*lastid_prefix*/,
                                                    exprs_prefix,
                                                    exprs_root,
                                                    exprs_count)) {

      // find all tags visible in the current context
      errorArgs._makeempty();
      tag_push_matches();
      status = editorctl_wid._Embeddedfind_context_tags(
                                    errorArgs,prefixexp,""/*lastid_prefix*/,lastidstart_offset,
                                    info_flags,otherinfo,false,
                                    def_tag_max_list_matches_symbols,
                                    false,editorctl_wid.p_EmbeddedCaseSensitive,
                                    SE_TAG_FILTER_ANYTHING-SE_TAG_FILTER_ANY_DATA-SE_TAG_FILTER_DEFINE-SE_TAG_FILTER_ENUM,
                                    SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_CONTEXT,
                                    visited);

      // copy the current match set and then clear it
      VS_TAG_BROWSE_INFO matches[];
      tag_get_all_matches(matches);
      tag_clear_matches();
      tag_pop_matches();

      //isay(depth, "_Embeddedinsert_auto_params: num="num_candidates" count="tag_get_num_of_matches());
      if (!status) {

         // for each match, first match the return types
         exprs_count=editorctl_wid._list_matching_arguments(matches, rt,
                                                            ar_index,rt_index,
                                                            prefixexp,tag_files,
                                                            tree_wid,exprs_root,
                                                            num_candidates,
                                                            def_tag_max_list_matches_symbols,
                                                            visited);
      }

      // find all tags visible in the current context
      if (fm_index) {
         errorArgs._makeempty();
         tag_push_matches();
         status = editorctl_wid._Embeddedfind_context_tags(
                                       errorArgs,prefixexp,""/*lastid_prefix*/,lastidstart_offset,
                                       info_flags,otherinfo,false,
                                       def_tag_max_list_matches_symbols,
                                       false,editorctl_wid.p_EmbeddedCaseSensitive,
                                       SE_TAG_FILTER_ANY_DATA,
                                       SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS|SE_TAG_CONTEXT_NO_GLOBALS,
                                       visited);

         // copy the current match set and then clear it
         tag_get_all_matches(matches);
         tag_clear_matches();
         tag_pop_matches();

         if (!status) {
            // now find the matching items
            exprs_count+=editorctl_wid._list_matching_members(matches, rt,
                                                              ar_index,rt_index,fm_index,
                                                              prefixexp,tag_files,
                                                              tree_wid,exprs_root,
                                                              num_candidates,
                                                              def_tag_max_list_matches_symbols,
                                                              visited);
            //isay(depth, "_Embeddedinsert_auto_params: matches="tag_get_num_of_matches());
         }
      }

      if (tree_wid != 0) {
         tree_wid._CodeHelpEndUpdate(exprs_root,exprs_prefix,exprs_count,
                                     def_tag_max_list_matches_symbols,true);
      }
   }
#endif

   // that's all folks
   if (embedded_status==1) {
      editorctl_wid._EmbeddedEnd(orig_values);
   }
   return (/*exprs_count+*/vars_count==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

static void maybeCommandMode()
{
   if (def_keys == "vi-keys" && def_vim_esc_codehelp) {
      vi_escape();
   }
}
