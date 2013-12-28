////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50485 $
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
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
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
#import "util.e"
#import "vc.e"
#import "vi.e"
#import "xmldoc.e"
#import "backtag.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/OvertypeMarker.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

   static boolean gSCIMConfigured;
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
   boolean def_codehelp_html_comments=true;

#if __OS390__ || __TESTS390__
   int def_codehelp_key_idle=1000;
   int def_memberhelp_idle=2000;
   int def_update_tagging_idle=2500;
   int def_update_tagging_extra_idle=500;
#elif __UNIX__
   int def_codehelp_key_idle=200;
   int def_memberhelp_idle=400;
   int def_update_tagging_idle=1000;
   int def_update_tagging_extra_idle=500;
#else
   int def_codehelp_key_idle=50;
   int def_memberhelp_idle=50;
   int def_update_tagging_idle=500;
   int def_update_tagging_extra_idle=250;
#endif

int def_background_tagging_timeout=250;
int def_background_tagging_idle=500;
int def_background_tagging_threads=2;
int def_background_reader_threads=1;
int def_background_database_threads=1;
int def_background_tagging_maximum_jobs=500;
boolean def_background_tagging_minimize_write_locking=true;

#define CODEHELP_DOXYGEN_PREFIX '/*!'
#define CODEHELP_DOXYGEN_PREFIX1 '//!'
#define CODEHELP_DOXYGEN_PREFIX2 '///'
#define CODEHELP_JAVADOC_PREFIX '/**'
#define CODEHELP_JAVADOC_END_PREFIX '*/'

#define CODEHELP_FORCE_CASE_SENSITIVE     2
#define CODEHELP_PREFER_CASE_SENSITIVE    1
#define CODEHELP_CASE_INSENSITIVE         0

/*
  Scroll height needs to be at least
    pad_y+
    font_height+
    pad_y+
    horizontal scroll bar height
    all times 2
  Using 10 has big problems
*/
#define SCROLL_BAR_HEIGHT(screen_height)  max((screen_height*_twips_per_pixel_y()) intdiv 10,1900)

#define LISTHELPTREEWID    ctlminihtml2.p_user
#define HYPERTEXTSTACKDATA ctlminihtml1.p_user
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
   static boolean gFunctionHelp_MouseOver;
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
   static boolean gFunctionHelp_OperatorTyped;
   static boolean gFunctionHelp_FirstCall;
   static boolean gFunctionHelp_InsertedParam;
   static _str gFunctionHelp_HelpWord;
   static int gFunctionHelpTagIndex;

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
      boolean nesting[];
   };

   static LINECOMMENTCHARS g_lineCommentChars:[] = null;
   static BLOCKCOMMENTCHARS g_blockCommentChars:[] = null;


defeventtab codehelp_keys;
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
def TAB=codehelp_key;
def 'A-.'=codehelp_key;
def 'A-,'=codehelp_key;
def 'A-INS'=codehelp_key;
def 'M-.'=codehelp_key;
def 'M-,'=codehelp_key;
def 'M-INS'=codehelp_key;
def 'C-DOWN'=codehelp_key;
def 'C-UP'=codehelp_key;
def 'C- '=codehelp_key;
def 'C-PGDN'=codehelp_key;
def 'C-PGUP'=codehelp_key;
def 'S-PGDN'=codehelp_key;
def 'S-PGUP'=codehelp_key;

// Might want to add a new def_codehelp_flags called
// VSCODEHELPFLAG_ENABLE_EXTRA_SHIFT_KEYS
def 'S-HOME'=codehelp_key;
def 'S-END'=codehelp_key;
def 'S-UP'=codehelp_key;
def 'S-DOWN'=codehelp_key;

//def \0-\127=;
def ' '-\127=codehelp_key;
//def '='=codehelp_key;

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
}

void _before_write_state_codehelp()
{
   g_lineCommentChars = null;
   g_blockCommentChars = null;
}

void _lexer_updated_codehelp(_str lexername = '')
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
   if(last_key=='<') {
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
_command void auto_functionhelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if (!command_state() && l_event=='<' && _inDocComment()) {
      auto_codehelp_key();
      return;
   }
   if(!command_state() && _LanguageInheritsFrom("java") && def_jrefactor_auto_import==1) {
      jrefactor_add_import(true);
   }
   //say("auto_functionhelp_key()");
   _macro_delete_line();
   _macro_call('AutoBracketKeyin',l_event);
   AutoBracketKeyin(l_event);
   if (!command_state()) {
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
         left();
         int cfg=_clex_find(0,'g');
         right();
         if (cfg!=CFG_STRING) {

            // check if the line starts with a #include statement
            langId := p_LangId;
            VS_TAG_IDEXP_INFO idexp_info;
            if (LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_ON_QUOTELT && 
                !_Embeddedget_expression_info(false, langId, idexp_info)) {
               if ((idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
                   (idexp_info.prefixexp == '#include' || 
                    idexp_info.prefixexp == '#require' || 
                    idexp_info.prefixexp == '#import')) {
                  if (get_text_safe() != ">") {
                     _insert_text(">");
                     left();
                  }
                  _do_list_members(true, true);
                  return;
               }
            }

            // try return type based value matching if supported and option is on
            boolean tryReturnTypeMatching=(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_VALUES)? true:false;
            if (!_FindLanguageCallbackIndex("vs%s_get_expression_pos") &&
                !_FindLanguageCallbackIndex("_%s_get_expression_pos")) {
               tryReturnTypeMatching = false;
            }

            // this is the fun part
            _do_function_help(true,false,false,tryReturnTypeMatching);
         } else {
            // convert #include "<" to #include <> and force list members
            get_line(auto line);
            if (LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) != AC_POUND_INCLUDE_NONE && 
                line == "#include \"<\"") {
               left();
               left();
               _delete_text(3);
               _insert_text('<>');
               left();
               _do_list_members(true, true);
            }
         }
      }
   }
}
static _str get_arg_info_type_name(VSAUTOCODE_ARG_INFO &fn)
{
   // do not do auto-list-parameters for #define's
   if (fn.tagList._length() > 0) {
      tag_tree_decompose_tag(fn.tagList[0].taginfo,
                             auto tag_name="",
                             auto class_name="",
                             auto arglist_type="",
                             auto tag_flags=0,
                             auto arguments="");
      return arglist_type;
   }
   return '';
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
_command void auto_codehelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   //say("auto_codehelp_key()");
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if (length(last_event())!=1) {
      return;
   }
   _str key=last_event();
   _str last_key=get_text(1,(int)_QROffset()-1);

   if(_EmbeddedLanguageKey(key)) return;

   if(key=='>' && _inJavadoc()) {
      maybe_insert_html_close_tag();
      return;
   }
   if(key==']' && _LanguageInheritsFrom('bbc')) {
      maybe_insert_html_close_tag();
      return;
   }

   _macro_delete_line();
   _macro_call('keyin',last_event());

   _str l_event = last_event();
   if(def_jrefactor_auto_import==1 && _LanguageInheritsFrom('java') && (key=='.' || key=='>' || key=='=')) {
      jrefactor_add_import(true);
   }

   keyin(l_event);

   if(key=='%' && p_LangId=="html") {
      auto_complete_script_block(last_key, key);
   }

   if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
      // maybe have to update function help first
      if (ginFunctionHelp) {
         still_in_function_help(MAXINT);
      }
      // obtain the expected parameter type if in codehelp
      _str expected_name='';
      _str expected_type='';
      _str arglist_type='';
      if (ginFunctionHelp && !gFunctionHelp_pending &&
          (geditorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) ) {
         int i=gFunctionHelpTagIndex;
         int n=gFunctionHelp_list._length();
         if (i>=0 && i<n) {
            expected_name=gFunctionHelp_list[i].ParamName;
            expected_type=gFunctionHelp_list[i].ParamType;
            arglist_type=get_arg_info_type_name(gFunctionHelp_list[i]);
         }
      }
      if (expected_type == '' || arglist_type!='define') {
         _do_list_members(true,false,null,expected_type,null,expected_name);
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
   if (machine()=='LINUX') {
      if (!gSCIMConfigured && last_event():==name2event('c- ') && _SCIMRunning()) {
         gSCIMConfigured=true;
         int result=_message_box("Do you want Ctrl+Space to perform completion?\n\nIf you choose \"Yes\" (recommended), you can display the SCIM input method editor by pressing Ctrl+Alt+Space instead of Ctrl+Space. If you choose \"No\", Ctrl+Space will display the SCIM input method editor and you will not have any alternate key binding for performing symbol/alias completion.\n\nTo configure this later, go to Tools>Options>Redefine Common Keys and set the \"Use Ctrl+Space for input method editor\" check box.",'Configure Ctrl+Space',MB_YESNO);
         if (result==IDYES) {
            _default_option(VSOPTION_USE_CTRL_SPACE_FOR_IME,0);
         } else {
            _default_option(VSOPTION_USE_CTRL_SPACE_FOR_IME,1);
         }
         return;
      }
   }
#endif

   //say("codehelp_complete()");
   if (!command_state()) {
      _str errorArgs[];errorArgs._makeempty();
      typeless orig_values;
      int status=_EmbeddedStart(orig_values);
      if (!_istagging_supported() &&
          // I bet we won't need this for long..
          !_LanguageInheritsFrom('xml') && !_LanguageInheritsFrom('dtd')
          ) {
         if (status==1) {
            _EmbeddedEnd(orig_values);
         }
         expand_alias();
         return;
      }
      left();
      int cfg=_clex_find(0,'g');
      right();
      if (!_in_comment() && (cfg!=CFG_STRING ||
                             _LanguageInheritsFrom('cob') || _LanguageInheritsFrom('html') ||
                             _LanguageInheritsFrom('dtd') || _LanguageInheritsFrom('xml')
                            )) {
         //If an exact alias match, expand the alias rather than symbol completion.
         if (!expand_alias("","",alias_filename(true,false))) return;
         _do_complete();
      } else {
         expand_alias();
      }
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
   } else {
      expand_alias();
   }
}

/*
      Cursor must be at first character of start of
      line comment.

    parameters
       first_line

*/
static int get_line_comment_range(int &first_line,int &last_line)
{
   int required_indent_col=p_col;
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
      first_non_blank('h');
      if (p_col<required_indent_col) {
         last_line=p_line-1;
         break;
      }
      down();
   }
   restore_pos(orig_pos);
   return(0);
}
static void get_line_comment(int &comment_flags,_str tag_type,_str &comments,int line_limit)
{
   comment_flags=0;
   comments="";
   typeless orig_pos;
   save_pos(orig_pos);
   _end_line();
   typeless end_seek=_nrseek();
   left();
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      restore_pos(orig_pos);
      return;
   }
   int linenum=p_line;
   int status=_clex_find(COMMENT_CLEXFLAG,"n-");
   if (status || linenum!=p_line) {
      restore_pos(orig_pos);
      return;
   }
   ++p_col;
   int first_line=0, last_line=0;
   if(get_line_comment_range(first_line,last_line)) {
      restore_pos(orig_pos);
      return;
   }
   _str line_prefix = '';
   int blanks:[][];
   _str doxygen_comment_start='';
   _parse_multiline_comments(p_col,first_line,last_line,comment_flags,tag_type,comments,line_limit,
      line_prefix,blanks,doxygen_comment_start);
   restore_pos(orig_pos);
#if 0
   //say("get_line_comment: ");
   comments="";
   save_pos(orig_pos);
   _end_line();
   end_seek=_nrseek();
   left();
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      restore_pos(orig_pos);
      return;
   }
   linenum=p_line;
   status=_clex_skip_blanks("h-");
   if (status || linenum!=p_line) {
      restore_pos(orig_pos);
      return;
   }
   comments=strip(get_text(end_seek-(int)point('s')-1,(int)point('s')+1));
   if (pos('['p_word_chars']',substr(comments,1,1),1,'r')) {
      parse comments with . comments;
      restore_pos(orig_pos);
      return;
   }
   lang = p_LangId;
   orig_view_id=_create_temp_view(temp_view_id);
   _SetEditorLanguage(lang);
   insert_line(comments);
   insert_line("");
   // IF this is an unterminated multi-line comment
   if (_clex_find(0,'g')==CFG_COMMENT) {
      j=pos('[ 'p_word_chars']',comments,1,'r');
      if (!j) {
         comments="";
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         restore_pos(orig_pos);
         return;
      }
      comments=strip(substr(comments,j));
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      restore_pos(orig_pos);
      return;
   }
   j=pos('[ 'p_word_chars']',comments,1,'r');
   if (!j) {
      comments="";
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      restore_pos(orig_pos);
      return;
   }
   comments=strip(substr(comments,j));
   j=lastpos('[ 'p_word_chars'.]',comments,MAXINT,'r');
   if (!j) {
      comments="";
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      restore_pos(orig_pos);
      return;
   }
   comments=strip(substr(comments,1,j));
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   restore_pos(orig_pos);
#endif
}
/**
 * Parse multiline comments, starting from the 'first_line' and parsing
 * up until the 'last_line'.
 *
 * @param line_comment_indent_col  Indent column for line comments
 * @param first_line     First line to start parsing at
 * @param last_line      Last line to parse to
 * @param comment_flags  (reference) bitset of VSCODEHELP_COMMENTFLAG_*
 * @param tag_type       tag type name (see VS_TAGTYPE_*)
 * @param comments       (reference) set to line-by-line comments
 * @param line_limit     maximum number of lines to parse
 * @param line_prefix    (reference) comment line prefix
 * @param blanks         (reference) blank lines after comment tags
 */
void _parse_multiline_comments(
   int line_comment_indent_col,
   int first_line,int last_line,
   int &comment_flags,
   _str tag_type,
   _str &comments,
   int line_limit,
   _str &line_prefix,
   int (&blanks):[][],
   _str &doxygen_comment_start)
{
   blanks._makeempty();
   comment_flags=0;
   int Noflines=last_line-first_line+1;
   if (Noflines>line_limit) Noflines=line_limit;
   _str list[];
   _str prefix='',revprefix='';
   p_line=first_line;
   int min_non_blank_col=100;
   int first_non_blank_col=0;
   _str line=_expand_tabsc(line_comment_indent_col);
   boolean hit_doxygen_prefix_already=false;
   int i;
   _str last_javadoc_tag='';
   boolean allow_xmldoc_comment=true;
   boolean same_tag=false;
   for (i=0;i<Noflines;++i) {
      int cur_line_flags=_lineflags();
      if (cur_line_flags&NOSAVE_LF) {
         down();continue;
      }
      line=_expand_tabsc(line_comment_indent_col);
      //say('h0 line='line);
      _str start='', rest='';
      parse line with start rest;
      boolean start_of_javadoc=false;
      if (substr(strip(line,'L'),1,3)=='///' && allow_xmldoc_comment) {
         rest=strip(substr(strip(line,'L'),4));
         _str first_non_blank_ch=substr(rest,1,1);
         // Another way to do this is to disable xmldoc if first_non_blank_ch
         // is not an alpha or numberic character.
         if (rest!='' && 
             first_non_blank_ch!='/' &&  // Not /////////
             first_non_blank_ch!='*' &&  // Not ///**********************
             first_non_blank_ch!='!'  // Not ///!!!!!!!!!!!!!!!!!!!!
             ) {
            if (first_non_blank_ch=='<') {
               comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
            }
            allow_xmldoc_comment=false;
         }
      }
      if ( (substr(strip(line,'L'),1,3)==CODEHELP_JAVADOC_PREFIX ||      // /** JavaDoc
            substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX ||      // /*! Doxygen
            substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX1 ||     // //! Doxygen
            (substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX2 
             && !(comment_flags&VSCODEHELP_COMMENTFLAG_XMLDOC))
             ) &&     // /// Doxygen
           substr(strip(line,'L'),4,1) != '*' &&                           // not /*******
           substr(strip(line,'L'),4,1) != '!' &&                           // not /*!!!!!!
           !hit_doxygen_prefix_already) {                                   // for //! or /// block 
         comment_flags|=VSCODEHELP_COMMENTFLAG_HTML|VSCODEHELP_COMMENTFLAG_JAVADOC;
         if (substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX || 
             substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX1 ||
             (substr(strip(line,'L'),1,3)==CODEHELP_DOXYGEN_PREFIX2 
              && !(comment_flags&VSCODEHELP_COMMENTFLAG_XMLDOC))
              ) {
            comment_flags|=VSCODEHELP_COMMENTFLAG_DOXYGEN;
            doxygen_comment_start = substr(strip(line,'L'),1,3);
            hit_doxygen_prefix_already=true;
         }
         list._makeempty();
         prefix='';revprefix='';
         min_non_blank_col=100;
         first_non_blank_col=0;
#if 0
         //Handle javadoc case below by looking ahead at next line
         /**
           * This is a factory
           * The returned object
           */
#endif
         if (i+1<Noflines && !down()) {
            _str line2;
            line2=_expand_tabsc(1);
            if (substr(strip(line2),1,1)=='*') {
               first_non_blank_col=pos('[^ ]',line2,1,'r');
            }
            up();
         }
         start_of_javadoc=true;
      /*} else if(substr(strip(line,'L'),1,3)=='///' && substr(strip(line,'L'),4,1)!='/' && allow_xmldoc_comment) {
         rest=substr(strip(line,'L'),4);
         if (substr(strip(rest),1,1)=='<' || rest=='') {
            comment_flags|=VSCODEHELP_COMMENTFLAG_XMLDOC;
         }*/
      } else if( substr(strip(line,'L'),1,1)=='#' && _LanguageInheritsFrom("pl") ) {
         rest=substr(strip(line,'L'),2);
         // DJB (10-27-2005)
         // Don't let a blank line alone trigger HTML comments
         if (substr(strip(rest),1,1)=='<' /*|| rest==''*/) {
            comment_flags|=VSCODEHELP_COMMENTFLAG_HTML|VSCODEHELP_COMMENTFLAG_JAVADOC;
         }
      }
      prefix='';
      int j=0;
      if (!first_non_blank_col) {
         first_non_blank_col=pos('[^ ]',line,1,'r');
         if (!first_non_blank_col) {
            down();
            continue;
         }
         //  Handle the following comment
         /* text on first line
            aligned under text.  No stuff before text */
         if (substr(line,first_non_blank_col,2)=='/*' && substr(line,first_non_blank_col+2,1)==' ') {
            if (i+1<Noflines && !down()) {
               _str line2;
               line2=_expand_tabsc(1);
               if (substr(line2,first_non_blank_col,2)=='') {
                  prefix='/*';
                  line=substr(line,1,first_non_blank_col-1):+'  ':+substr(line,first_non_blank_col+2);
               }
               up();
            }
         }
      } else {
         j=pos('[^ ]',line,1,'r');
         if (j && j<first_non_blank_col) {
            if (!start_of_javadoc) {
               first_non_blank_col=j;
            }
         }
      }
      j=first_non_blank_col;
      word_chars := _extra_word_chars:+p_word_chars;
      if (substr(line,j,1):==' ' && substr(line,j+1,1):!=' ' &&
         !pos('[<'word_chars']',substr(line,j+1,1),1,'r')) {
         ++j;
      }
      if (_LanguageInheritsFrom('pl') && substr(line,j,1)=='#') {
         j=pos('[~ \t]',line,j+1,'r');
      } else {
         // if we are on the comment prefix, ignore trailing spaces
         if (line_prefix == '') {
            line = strip(line, 't');
         }
         j=pos('[ <'word_chars']',line,j,'r');
      }
      if (!j && _dbcs()) {
         // This may be a dbcs comment
         int l,len=length(line);
         boolean found_lead_byte=false;
         // Scan the string for a dbcs lead byte
         for (l=1;l<=len;++l) {
            if (_dbcsIsLeadByte(substr(line,l,1)) ) {
               found_lead_byte=true;
               break;
            }
         }
         if ( found_lead_byte ) {
            // If we found a dbcs lead byte, start the comment from here
            j=l;
         }
      }
      if (!j) {
         // if we have found the prefix, and this line is only the prefix
         if (line_prefix != '' && strip(line) == line_prefix) {
            // why is this here?
//          if (list._length() > 1) {
               // the tag we are working on is the nth javadoc tag of the same type
               int n = blanks:[last_javadoc_tag]._length();
               // if we haven't found a javadoc tag yet, we still want to mark this blank
               // in the table b/c it could be a blank after the description
               if (last_javadoc_tag == '') {
                  if (isinteger(blanks:[last_javadoc_tag][0])) {
                     blanks:[last_javadoc_tag][0]++;
                  } else {
                     blanks:[last_javadoc_tag][0]=1;
                  }
               } else if (n > 0 && isinteger(blanks:[last_javadoc_tag][n-1])) {
                  blanks:[last_javadoc_tag][n-1]++;
               }
//          }
         }
         if (list._length()) {
            list[list._length()]="";
         }
         down();
         if (line_prefix == '') {
            if (isinteger(blanks:["leading"][0])) {
               blanks:["leading"][0]++;
            } else {
               blanks:["leading"][0] = 1;
            }
         }
         continue;
      }
      if (prefix=='') {
         prefix=strip(substr(line,1,j-1));
      }

      /* Support no space between * and @
         Support no space between * and \
         Support no space between ** and @
         Support no space between ** and \

         More support for poorly written javadoc and doxygen
      */
      if((prefix == '*@') || (prefix == '*\')) {
         prefix = '*';
         j = 3;
      } else if ((prefix == '**@') || (prefix == '**\')) {
         prefix = '*';
         j = 3;
      }
      if (line_prefix == '') {
         line_prefix = prefix;
      }
      if (prefix!='' && revprefix=='') {
         revprefix = prefix;
         /*
            Need to manually translated these prefixes
         */
         if (prefix==CODEHELP_JAVADOC_PREFIX || prefix==CODEHELP_DOXYGEN_PREFIX) {
            revprefix='*/';
         } else {
            if (length(revprefix)==2) {
               revprefix=substr(prefix,2,1):+substr(prefix,1,1);
            }
            revprefix=stranslate(revprefix,'}','{');
            revprefix=stranslate(revprefix,')','(');
            revprefix=stranslate(revprefix,']','[');
         }
      }
      //say('j='j);
      //say('h1 subline='substr(line,1,4));
      line=strip(substr(line,j),'T');
      //say('h2 line='line);
      /*
         Removed if so that javadoc and doxygen comments that start and end on
         the same line don't leave the trailing "* /".
         / **  comment * /
         / *!  comment * /
      */
      //if (!(comment_flags&(VSCODEHELP_COMMENTFLAG_JAVADOC))) {
         if (revprefix!="" && length(line)>length(revprefix) &&
             substr(line,length(line)-length(revprefix)+1):==revprefix) {
            line=strip(substr(line,1,length(line)-length(revprefix)),'T');
         } else if (prefix!="" && length(line)>length(prefix) &&
             substr(line,length(line)-length(prefix)+1):==prefix) {
            line=strip(substr(line,1,length(line)-length(prefix)),'T');
         }
      //}
      // Look for repeat of a character like -
      if (length(line)>3 && line:==substr('',1,length(line),substr(line,1,1))) {
         line='';
      }
      if (line!="" || list._length()) {
         list[list._length()]=line;
         int x=pos('(^|\n)[ \t]*[\\@]{[a-zA-Z0-9\-_]#}',line,1,'r');
         // if there is a javadoc tag
         if (x) {
            int s,n;
            // start of @word match
            s=pos('S0')-x+1;
            // length of @word match
            n=pos('0');
            _str cur_tag=substr(line, s,n);
            // remember if this is not the first javadoc tag we've encountered...
            // AND it is the same as the last one we encountered
            if (last_javadoc_tag != '' || cur_tag == last_javadoc_tag) {
               same_tag=true;
            } else {
               // this assumes that all the similar tags would be after one another,
               // which might not be the case
               same_tag=false;
            }
            // no matter what, set the counter for this particular instance of this
            // javadoc tag type to 0
            blanks:[cur_tag][blanks:[cur_tag]._length()]=0;
            last_javadoc_tag=cur_tag;
         } else if (strip(line) == "") {
            // if there is any whitespace in the line it won't hit the normal
            // blank line code...so take care of this here
            int n = blanks:[last_javadoc_tag]._length();
            if (last_javadoc_tag == '') {
               if (isinteger(blanks:[last_javadoc_tag][0])) {
                  blanks:[last_javadoc_tag][0]++;
               } else {
                  blanks:[last_javadoc_tag][0]=1;
               }
            } else if (n > 0 && isinteger(blanks:[last_javadoc_tag][n-1])) {
               blanks:[last_javadoc_tag][n-1]++;
            }
         }
      }
      int non_blank_col=pos('[~ ]',line,1,'r');
      if (non_blank_col && non_blank_col<min_non_blank_col) {
         min_non_blank_col=non_blank_col;
      }
      down();
   }
   while (list._length() && list[list._length()-1]=="") {
      list._deleteel(list._length()-1);
   }
   for (i=0;i<list._length();++i) {
      strappend(comments,substr(list[i],min_non_blank_col):+"\n");
   }
   // extra-check for xmldocs that may not contain /// or /**
   // e.g. the *.xml in windows/Microsoft.Net/Framework/vVersionNumber
   if( p_LangId == 'xmldoc' ) {
      comment_flags |= VSCODEHELP_COMMENTFLAG_XMLDOC;
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
   _str filename=_strip_filename(p_buf_name,'P');
   if (!file_eq(filename,'html.tagdoc') && !file_eq(filename,'cfml.tagdoc') &&
       !file_eq(filename,'xml.tagdoc') && !file_eq(filename,'xsd.tagdoc')) return;

   // Verify there is a context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id=tag_current_context();
   if( context_id<=0 ) return;

   _str name='';
   _str class_name='';
   _str type_name='';
   tag_get_detail2(VS_TAGDETAIL_context_name,context_id,name);
   tag_get_detail2(VS_TAGDETAIL_context_class,context_id,class_name);
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);

   type_name=lowcase(type_name);
   // 'tag'   = HTML tag (e.g. BODY, IMG, etc.)
   // 'group' = HTML tag attribute (e.g. align, etc.)
   if (type_name!='tag' && type_name!='group') return;
   // We only want the current context, so the tag file list is null
   _str tag_files[]=null;
   int num_matches=0;
   int filter_flags=0;
   int context_flags=0;
   if (type_name=='group') {
      name=class_name':'name;
      filter_flags=VS_TAGFILTER_ANYTHING;
      context_flags=VS_TAGCONTEXT_ACCESS_private|VS_TAGCONTEXT_ONLY_this_class;
   } else {
      filter_flags=VS_TAGFILTER_VAR;
      context_flags=VS_TAGCONTEXT_ONLY_inclass;
   }
   tag_push_matches();
   // Clear matches or else get old matches mixed in with current matches
   tag_clear_matches();
   struct VS_TAG_RETURN_TYPE visited:[];
   tag_list_in_class('',name,0,0,
                     tag_files,num_matches,def_tag_max_find_context_tags,
                     filter_flags,
                     context_flags,
                     false,p_EmbeddedCaseSensitive,
                     null, null, visited);
   // We want a sorted list of attribute/value links
   _str attrval_name='';
   _str attrval_type='';
   _str attrval_file_name='';
   _str attrval_class_name='';
   _str attrval_signature='';
   _str attrval_return_type='';
   int attrval_line_no=0;
   int attrval_tag_flags=0;
   _str attrval_list[];
   attrval_list._makeempty();
   int i;
   for (i=1;i<=num_matches;++i) {
      _str dtf;
      tag_get_match(i,dtf,attrval_name,attrval_type,attrval_file_name,attrval_line_no,
                    attrval_class_name,attrval_tag_flags,attrval_signature,attrval_return_type);
      // Concatenate them this way so sorting sorts on attr_tag_name
      attrval_list[attrval_list._length()]=attrval_name','attrval_class_name;
   }
   tag_pop_matches();
   // Sort the list
   attrval_list._sort((p_EmbeddedCaseSensitive)?'':'i');
   _str links="";
   for (i=0;i<attrval_list._length();++i) {
      parse attrval_list[i] with attrval_name ',' attrval_class_name;
      _str link='{@link ';
      link=link:+attrval_class_name;
      link=link'#'attrval_name' 'attrval_name'}';
      links=links:+link', ';
   }
   // Insert the attribute/value help before the first example (@example).
   if (links!="") {
      links=strip(links);
      links=strip(links,'T',',');
      i=pos('(^|\n)\@example',comments,1,'r');
      if (!i) {
         // Put attributes at end of comment
         i=length(comments)+1;
      }
      if (name=='group') {
         links='@values 'links;
      } else {
         links='@attributes 'links;
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
 * @param tag_type         tag type, corresponding to VS_TAGTYPE_*
 * @param comments         (output) collected comments
 * @param line_limit       maximum number of lines to collect
 * @param line_comments    get line comments or ignore them (false)
 * @param line_prefix      (output) comment line prefix
 * @param blanks           (output) blank lines after comment
 *                         tags
 */
void _do_default_get_tag_comments(int &comment_flags,
                                  _str tag_type,_str &comments,
                                  int line_limit=500,
                                  boolean line_comments=true,
                                  _str &line_prefix='',
                                  int (&blanks):[][]=null,
                                  _str &doxygen_comment_start=''
                                  )
{
   comment_flags=0;
   //say("_do_default_get_tag_comments("tag_type")");
   typeless orig_pos;
   save_pos(orig_pos);
   comments='';
   int line_comment_flags=0;
   if (line_comments) {
      get_line_comment(line_comment_flags,tag_type,comments,line_limit);
   }
   //say("_do_default_get_tag_comments: line="comments);
#if 0
   /*
      We can add this code back in if problems arise.
   */
   if (comments!="") {
      if (_LanguageInheritsFrom('pl') && !tag_tree_type_is_func(tag_type)) {
         comment_flags=line_comment_flags;
         return;
      }
   }
#endif
   int first_line=0, last_line=0;
   int status=_do_default_get_tag_header_comments(first_line,last_line);
   if (status) {
      comment_flags=line_comment_flags;
      return;
   }
   if (length(comments)) {
      _str comments2='';
      _parse_multiline_comments(1,first_line,last_line,comment_flags,tag_type,comments2,line_limit,line_prefix,blanks,
         doxygen_comment_start);
      if ((comment_flags & VSCODEHELP_COMMENTFLAG_HTML)) {
         if (!(line_comment_flags&VSCODEHELP_COMMENTFLAG_HTML)) {
            comments=comments2;
         } else {
            strappend(comments,"<hr>");
            strappend(comments,comments2);
         }
      } else {
         if (!(line_comment_flags&VSCODEHELP_COMMENTFLAG_HTML)) {
            /*if (!pos("\n",comments)) */strappend(comments,"\n");
            strappend(comments,comments2);
         }
         comment_flags=line_comment_flags;
      }
   } else {
      _parse_multiline_comments(1,first_line,last_line,comment_flags,tag_type,comments,line_limit,line_prefix,blanks,
         doxygen_comment_start);
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
 *
 * @return 0 if header comment found and first_line,last_line
 *         set.  Otherwise, 1 is returned.
 */
int _do_default_get_tag_header_comments(int &first_line,int &last_line)
{
   // check if there is an extension specific callback.
   index := _FindLanguageCallbackIndex('_%s_get_tag_header_comments');
   if (index) {
      status := call_index(first_line,last_line,index);
      if (!status) {
         return(0);
      }
   }
   // skip blank lines before tag
   _str line='';
   typeless orig_pos;
   save_pos(orig_pos);
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
   first_non_blank('h');
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      restore_pos(orig_pos);
      return(1);
   }
   // Search for beginning of comments
   status := _clex_skip_blanks("h-");
   if (status) {
      top();
   } else {
      _end_line();  // Skip to end of line so we don't find comment after non-blank text.
      _clex_find(COMMENT_CLEXFLAG,"O");
   }
   first_line=p_line;
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
   typeless orig_markid=_duplicate_selection('');
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
   _str slcomment_start='';
   _str mlcomment_start='';
   _str mlcomment_end='';
   boolean javadocSupported=false;
   if(!get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) && javadocSupported) {
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
void _do_function_help(boolean OperatorTyped,
                       boolean DisplayImmediate,
                       boolean cursorInsideArgumentList=false,
                       boolean tryReturnTypeMatching=false,
                       boolean doMouseOverFunctionName=false,
                       int MouseOverCursorX=0,
                       int MouseOverPixelWidth=0,
                       int MouseOverLineNum=0,
                       int MouseOverCol=0,
                       typeless MouseOverPos=null,
                       _str streamMarkerMessage=null)
{
   // IF we are in a recorded macro, just forget it
   if (_macro('r')) {
      // Too slow to display GUI
      return;
   }
   //say("_do_function_help: ");
   if (ginFunctionHelp) {
      if (!gFunctionHelp_MouseOver) {
         still_in_code_help();
      }
   }
   if (ginFunctionHelp) {
      if (gFunctionHelp_MouseOver!=doMouseOverFunctionName) {
         TerminateFunctionHelp(false);
      } else {
         return;
      }
   }
   typeless orig_pos;
   save_pos(orig_pos);
   _str errorArgs[];errorArgs._makeempty();
   int FunctionNameOffset=0;
   int ArgumentStartOffset=0;
   int flags=0;

   // is this embedded code?
   int status=_Embeddedfcthelp_get_start(
      errorArgs,
      OperatorTyped,
      cursorInsideArgumentList,
      FunctionNameOffset,
      ArgumentStartOffset,
      flags
      );
   if (status) {
      if (tryReturnTypeMatching) {
         restore_pos(orig_pos);
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         _do_list_members(OperatorTyped,DisplayImmediate,null,null,rt,null,false,false,true);
         return;
      }
      if (status && !OperatorTyped && !doMouseOverFunctionName) {
         _str msg=_CodeHelpRC(status,errorArgs);
         if (msg!='') {
            //_message_box(msg);
            message(msg);
         }
      }
      restore_pos(orig_pos);
      return;
   }

   // output some debugging stuff
   if (_chdebug) {
      say('_do_function_help: fnoffset='FunctionNameOffset' argstartofs='ArgumentStartOffset);
   }

   if (OperatorTyped) {
      flags |= VSAUTOCODEINFO_OPERATOR_TYPED;
   }
   goto_point(FunctionNameOffset);
   gFunctionHelp_OperatorTyped=OperatorTyped;
   gFunctionHelp_FirstCall=true;
   gFunctionHelp_InsertedParam=false;
   gFunctionHelp_FunctionNameOffset=FunctionNameOffset;
   gFunctionHelp_FunctionLineOffset=(int)point();
   gFunctionHelp_starttext=get_text(ArgumentStartOffset-gFunctionHelp_FunctionLineOffset,gFunctionHelp_FunctionLineOffset);
   gFunctionHelp_flags=flags;
   gFunctionHelpTagIndex=MAXINT;
   restore_pos(orig_pos);
   gFunctionHelp_MouseOver=doMouseOverFunctionName;
   if(gFunctionHelp_MouseOver) {
      gFunctionHelp_MouseOverInfo.wid=p_window_id;
      gFunctionHelp_MouseOverInfo.x=0;gFunctionHelp_MouseOverInfo.y=0;
      //_lxy2dxy(SM_TWIP,x,y);
      //say('p_parent='p_parent);
      //say('_mdi='_mdi);
      _map_xy(p_window_id,0,gFunctionHelp_MouseOverInfo.x,gFunctionHelp_MouseOverInfo.y);
      gFunctionHelp_MouseOverInfo.x+=MouseOverCursorX;
      gFunctionHelp_MouseOverInfo.y+=p_cursor_y;
      gFunctionHelp_MouseOverInfo.width=MouseOverPixelWidth;
      gFunctionHelp_MouseOverInfo.height=p_font_height;
      //say('got here x='x' y='y);
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
      _update_function_help(tryReturnTypeMatching);
      gFunctionHelp_InsertedParam=false;
      if (gFunctionHelp_OperatorTyped && ginFunctionHelp && !gFunctionHelp_pending) {
         boolean insert_space=(!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN))? true:false;
         if (p_col > 1 && insert_space) {
            left();
            if (get_text()!='(') insert_space=false;
            right();
         }
         gFunctionHelp_InsertedParam=maybe_insert_current_param(true,true,insert_space);
      }
      if (ginFunctionHelp && !gFunctionHelp_pending && !gFunctionHelp_MouseOver &&
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
boolean ParameterHelpActive()
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

static void TerminateFunctionHelp(boolean inOnDestroy)
{
   if (!ginFunctionHelp) return;
   if (_iswindow_valid(gFunctionHelp_form_wid)) {
      if (gFunctionHelp_InsertedParam && 
          _iswindow_valid(geditorctl_wid) &&
          geditorctl_wid.select_active() &&
          (geditorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
         _macro_call('maybe_delete_selection');
         geditorctl_wid.maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
      }
      if (!inOnDestroy) {
         gFunctionHelp_form_wid._delete_window();
      }
   }
   gFunctionHelp_form_wid=0;
   ginFunctionHelp=0;
   // Shouldn't need to reinitialize gFunctionHelp_MouseOver, but since
   // the ALM bug (immediately going away) was hard to reproduce let's make
   // sure we reset it.
   gFunctionHelp_MouseOver=0;
   gFunctionHelp_selected_symbol = null;
   if (_iswindow_valid(geditorctl_wid) &&
       geditorctl_wid._isEditorCtl()) {
      geditorctl_wid._RemoveEventtab(defeventtab codehelp_keys);
      geditorctl_wid=0;
   }
   AutoCompleteTerminate();
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
   int count=0;
   int etab_index=p_eventtab;
   boolean found=false;
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
   //say('add 'name_name(p_eventtab));
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
   int count=0;
   int prev_eventtab_index=0;
   int etab_index=p_eventtab;
   boolean found=false;
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
   //say('remove 'name_name(p_eventtab));
}

/**
 * Returns the current word under the cursor, as seen by
 * function help in order to find related topic in online help.
 *
 * @param allHelpWorkDone  finished?
 *
 * @return current help topic, as seen by function help
 */
_str _CodeHelpCurWord(boolean &allHelpWorkDone)
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
   int i=gFunctionHelpTagIndex;
   int n=gFunctionHelp_list._length();
   if (i<0 || i>=n) {
      return("");
   }
   return gFunctionHelp_list[i].tagList[0].taginfo;
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
void _update_function_help(boolean tryReturnTypeMatching=false)
{
   doNotify := !gFunctionHelp_MouseOver && !gFunctionHelp_form_wid;

   if ((p_ModifyFlags & MODIFYFLAG_FCTHELP_UPDATED) &&
       gFunctionHelp_UpdateLineNumber==p_line &&
       gFunctionHelp_UpdateLineCol==p_col
       ) {
      return;
   }
   
   VSAUTOCODE_ARG_INFO curTag_arg_info;
   boolean curTag_arg_info_set=false;
   if (gFunctionHelpTagIndex<gFunctionHelp_list._length()) {
      curTag_arg_info=gFunctionHelp_list[gFunctionHelpTagIndex];
      curTag_arg_info_set=true;
   }
   /*
       (clark) I wrapped _Embeddedfcthelp_get with save_pos/restore_pos because we hit a case when in
       Line Hex mode (should happend in regular mode too) where typing '(' causes the screen to
       scroll.  This totally screws up "Show info for mouse under cursor".
   */
   if (gFunctionHelp_OperatorTyped) {
      _SetTimeout(def_tag_max_list_matches_time);
   }

   _str errorArgs[];errorArgs._makeempty();
   save_pos(auto p);
   boolean FunctionHelp_list_changed=false;
   int status=_Embeddedfcthelp_get(errorArgs,
                     gFunctionHelp_list,
                     FunctionHelp_list_changed,
                     gFunctionHelp_cursor_x,
                     gFunctionHelp_HelpWord,
                     gFunctionHelp_FunctionNameOffset,
                     gFunctionHelp_flags
                     );
   restore_pos(p);
   if (status) {
      if (gFunctionHelp_OperatorTyped && _CheckTimeout()) {
         status = VSCODEHELPRC_FUNCTION_HELP_TIMEOUT;
      }
      if (tryReturnTypeMatching &&
          !gFunctionHelp_OperatorTyped && gFunctionHelp_FirstCall) {
         TerminateFunctionHelp(0);
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         _do_list_members(false,true,null,null,rt,null,false,false,true);
      }
      if (!gFunctionHelp_OperatorTyped && !gFunctionHelp_MouseOver  &&
          (gFunctionHelp_FirstCall|| status!=VSCODEHELPRC_NOT_IN_ARGUMENT_LIST)) {
         _str msg=_CodeHelpRC(status,errorArgs);
         if (msg!='') {
            message(msg);
         }
      }
      TerminateFunctionHelp(0);
      return;
   }
   gFunctionHelp_FirstCall=false;
   if (!gFunctionHelp_form_wid) {
      gFunctionHelp_form_wid=geditorctl_wid.show('-hidden -nocenter -new _function_help_form', geditorctl_wid, 0);
      FunctionHelp_list_changed=1;
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
               if ( !file_eq(gFunctionHelp_selected_symbol.file_name, gFunctionHelp_list[i].tagList[j].filename) ||
                    gFunctionHelp_selected_symbol.line_no != gFunctionHelp_list[i].tagList[j].linenum ) {
                  continue;
               }
               tag_tree_decompose_tag(gFunctionHelp_list[i].tagList[j].taginfo, auto tag_name, auto class_name, auto type_name, auto tag_flags);
               if ( gFunctionHelp_selected_symbol.member_name != tag_name ||
                    gFunctionHelp_selected_symbol.class_name  != class_name ) {
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
   //say(!FunctionHelp_list_changed' '(ParamNum==gFunctionHelp_ParamNum)' '(gFunctionHelp_cursor_y>=geditorctl_wid.p_cursor_y)' 'gFunctionHelp_form_wid.p_visible);
   int new_cursor_y=geditorctl_wid.p_cursor_y;
   if (!FunctionHelp_list_changed /*&& ParamNum!=gFunctionHelp_ParamNum */&&
       gFunctionHelp_cursor_y>=geditorctl_wid.p_cursor_y) {
      new_cursor_y=gFunctionHelp_cursor_y;
   }
   //gFunctionHelp_ParamNum=ParamNum;
   //say(FunctionHelp_list_changed' pn='ParamNum' 'gFunctionHelp_ParamNum' y='gFunctionHelp_cursor_y' 'geditorctl_wid.p_cursor_y);
   geditorctl_wid._AddEventtab(defeventtab codehelp_keys);
   gFunctionHelp_cursor_y=new_cursor_y;

   // make sure that function help is displayed
   ShowCommentHelp(true, false, gFunctionHelp_form_wid, geditorctl_wid);

   // display feature notification that function help was displayed
   if (doNotify) {
      notifyUserOfFeatureUse(NF_AUTO_DISPLAY_PARAM_INFO);
   }
}

static void nextFunctionHelpPage(int inc,boolean doFunctionHelp=true)
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
static int nextFunctionHelp(int inc, boolean doFunctionHelp=true, int form_wid=0)
{
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
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA;
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
      last_event_was_alt_comma := (last_event() == name2event('A-,') || last_event() == name2event('A-M-,') || last_event() == name2event('M-,'));
      restart_list_members    = last_event_was_alt_comma;
      restart_list_parameters = last_event_was_alt_comma;
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
         form_wid.HYPERTEXTSTACKDATA=stack;
      } else {
         gFunctionHelpTagIndex=TagIndex;
      }
      ShowCommentHelp(doFunctionHelp, false, form_wid, geditorctl_wid);
   }

   // restart list members and/or list compatibible values if necessary
   if (restart_list_members) {
      // obtain the expected parameter type
      int i=gFunctionHelpTagIndex;
      int n=gFunctionHelp_list._length();
      if (i>=0 && i<n) {
         _str arglist_type=get_arg_info_type_name(gFunctionHelp_list[i]);
         _str expected_type=null;
         _str expected_name=null;
         if (restart_list_parameters) {
            expected_type=gFunctionHelp_list[i].ParamType;
            expected_name=gFunctionHelp_list[i].ParamName;
         }
         if (expected_type == null || expected_type == '' || arglist_type != 'define') {
            geditorctl_wid._do_list_members(false,true,null,expected_type,null,expected_name,false,false,true);
         }
      }
   }

   // that's all folks
   return (TagIndex!=orig_TagIndex)? inc:0;
}

// jump to the tag currently displayed by function argument help
// or by list-members comment help.
//
static int gotoFunctionTag(boolean doFunctionHelp, int form_wid, int editorctl_wid)
{
   // find the index of the current item selected
   _nocheck _control ctlminihtml1;
   TagIndex := 0;
   VSAUTOCODE_ARG_INFO (*plist)[] = null;
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA;
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
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      
      // get the basic information about the symbol
      _str filename = pinfo->tagList[TagIndex].filename;
      int linenum = pinfo->tagList[TagIndex].linenum;
      _str taginfo = pinfo->tagList[TagIndex].taginfo;
      tag_tree_decompose_tag_info(taginfo, cm); 
      cm.file_name = filename;
      cm.line_no = linenum;
      tag_insert_match_info(cm);

      // compute a slightly flexible set of filters to search for
      int filter_flags = tag_type_to_filter(cm.type_name,0);
      if (tag_tree_type_is_func(cm.type_name)) filter_flags |= VS_TAGFILTER_ANYPROC;
      if (tag_tree_type_is_data(cm.type_name)) filter_flags |= VS_TAGFILTER_ANYDATA;

      // now search for the matching symbol
      int num_matches=0;
      typeless tag_files = tags_filenamea(editorctl_wid.p_LangId);
      editorctl_wid.tag_list_symbols_in_context(cm.member_name, cm.class_name, 
                                                0, 0, 
                                                tag_files, '',
                                                num_matches, 
                                                def_tag_max_function_help_protos,
                                                filter_flags, 
                                                VS_TAGCONTEXT_ANYTHING,
                                                true, true);

      // remove any matches that do not match the original argument list
      // or that are not functions in the first place
      if (tag_tree_type_is_func(cm.type_name)) {
         VS_TAG_BROWSE_INFO matches[];
         for (j:=tag_get_num_of_matches(); j>0; --j) {
            VS_TAG_BROWSE_INFO cmj;
            tag_browse_info_init(cmj);
            tag_get_match_info(j, cmj);
            if (tag_tree_type_is_func(cmj.type_name) &&
                tag_tree_compare_args(cm.arguments, cmj.arguments, true) == 0) {
               matches[matches._length()] = cmj;
            }
         }
         tag_clear_matches();
         for (j=0; j<matches._length(); j++) {
            tag_insert_match_info(matches[j]);
         }
         num_matches = tag_get_num_of_matches();
      }

      // shut down code help
      TerminateFunctionHelp(0);
      _SetTimeout(0);

      // get the basic information about the symbol
      // remove duplicate symbols from the match set
      tag_remove_duplicate_symbol_matches(false,false,false,true,false,false);

      // symbol information for tag we will go to
      tag_browse_info_init(cm);
      push_tag_reset_matches();

      // check if there is a preferred definition or declaration to jump to
      int match_id = tag_check_for_preferred_symbol(_GetCodehelpFlags());
      if (match_id > 0) {
         // record the matches the user chose from
         tag_get_match_info(match_id, cm);
         push_tag_add_match(cm);
         for (i:=1; i<=tag_get_num_of_matches(); ++i) {
            if (i==match_id) continue;
            VS_TAG_BROWSE_INFO im;
            tag_get_match_info(i,im);
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

      // now go to the selected tag
      status := tag_edit_symbol(cm);
      tag_pop_matches();

      // set up push-tag circle items
      push_tag_reset_item();
      push_tag_index := find_index("push-tag",COMMAND_TYPE);
      if (push_tag_index > 0) {
         prev_index(push_tag_index, "C");
         last_index(push_tag_index, "C");
      }

      // that's all folks
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
   int chars_elided=0;
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

void ShowCommentHelp(boolean doFunctionHelp=true, 
                     boolean prefer_left_placement=false,
                     int form_wid=0, int editorctl_wid=0 )
{
   TagIndex := 0;
   VSAUTOCODE_ARG_INFO (*plist)[] = null;
   _nocheck _control ctlminihtml1;
   HYPERTEXTSTACK stack = form_wid.HYPERTEXTSTACKDATA;
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
      return;
   }

   _str text="";
   //parse _default_font(CFG_FUNCTION_HELP) with fontname',';
   _str margin_text="";
   if (plist->_length()>1) {
      margin_text="<a href=\"<<f\" lbuttondown><img src=vslick://_arrowlt.ico></a> "(TagIndex+1)" of "plist->_length()" <a href=\">>f\" lbuttondown><img src=vslick://_arrowgt.ico></a> ";
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
   // add push tag bmp
   margin_text = margin_text:+"<a href=\"<<pushtag\" lbuttondown><img src=vslick://_push_tag.ico></a>&nbsp;";
   // Encode bold and italic args
   int i;
   //for (i=0;i<plist->_length();++i) {
      i=TagIndex;
      if(i<0 || i>=plist->_length()) {
         return;
      }
      int jcount=plist->[i].argstart._length();
      int ParamNum=plist->[i].ParamNum;
      if (ParamNum>=jcount && jcount > 0 &&
          substr(plist->[i].prototype,
                 plist->[i].argstart[jcount-1],
                 plist->[i].arglength[jcount-1])=='...') {
         ParamNum=jcount-1;
      }
      if (jcount >= (def_codehelp_max_params*3 intdiv 2)) {
         _ElideParameterList(plist->[i],def_codehelp_max_params);
      }
      _str prototype=translate(plist->[i].prototype,"\1\2\3",'<&>');
      if (ParamNum<0 || ParamNum>=jcount) {
         text=text:+prototype:+"\n";
      } else {
         int start=plist->[i].argstart[ParamNum];
         int len=plist->[i].arglength[ParamNum];
         text=text:+substr(prototype,1,start-1):+
            "<b>":+substr(prototype,start,len):+"</b>":+substr(prototype,start+len):+"\n</pre>";
      }
   //}
   text=stranslate(text,'&gt;',"\3");
   text=stranslate(text,'&amp;',"\2");
   text=stranslate(text,'&lt;',"\1");
   doMouseOver := doFunctionHelp && gFunctionHelp_MouseOver;
   //text='<pre><font size=+0>
   //_message_box('text='text);
   _nocheck _control picture1;
   _str html_comments="";
   _str first_file_name='';
   int  first_line_no  = 0;
   _str first_tag_name ='';
   _str cur_param_name ='';
   if ((doFunctionHelp && !doMouseOver && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS)) ||
       (!doFunctionHelp && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS)) ||
       (doMouseOver && (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS))) {

      VSAUTOCODE_ARG_INFO *pinfo;
      pinfo=&plist->[TagIndex];
      if (TagIndex<plist->_length() &&
          pinfo->tagList!=null) {
         //_message_box(' h1 len='pinfo->tagList._length());
         boolean retrieved_data=false;
         if (pinfo->tagList._length()>0) {
            first_file_name=pinfo->tagList[0].filename;
            first_line_no  =pinfo->tagList[0].linenum;
            if (pinfo->tagList[0].taginfo != null) {
               parse pinfo->tagList[0].taginfo with first_tag_name '(';
            }
         }
         for (i=0;i<pinfo->tagList._length();++i) {
            //_message_box('i='i' h1 len='pinfo->tagList._length());
            // If we have not fetched the comments yet
            if (pinfo->tagList[i].comments==null) {
               retrieved_data=true;
               _str tag_name='';
               _str class_name='';
               _str type_name='';
               int tag_flags=0;
               tag_tree_decompose_tag(pinfo->tagList[i].taginfo, tag_name, class_name, type_name, tag_flags);
               /*say('f='pinfo->tagList[i].filename);
               say('l='pinfo->tagList[i].linenum);*/
               editorctl_wid._ExtractTagComments2(pinfo->tagList[i].comment_flags,
                                                  pinfo->tagList[i].comments,
                                                  2000,
                                                  tag_name,
                                                  pinfo->tagList[i].filename,
                                                  pinfo->tagList[i].linenum);
               /*say('c='pinfo->tagList[i].comments);*/
               //pinfo->tagList[i].comments="test comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\ntest comment text\n";pinfo->tagList[i].comment_flags=0;
            }
            _str comments=pinfo->tagList[i].comments;
            boolean comments_are_unique=true;
            int j;
            for (j=0; j<i;++j) {
               if (pinfo->tagList[j].comments==comments) {
                  comments_are_unique=false;
                  break;
               }
            }
            if (comments!="" && comments_are_unique) {
               if (html_comments!="") {
                  strappend(html_comments,"<hr>");
               }
               _make_html_comments(comments,
                                   pinfo->tagList[i].comment_flags,
                                   "" /*return_type*/,
                                   pinfo->ParamName);
               cur_param_name=pinfo->ParamName;
               strappend(html_comments,comments);
            }
            if (editorctl_wid._LanguageInheritsFrom('e')) {
               int var_index=find_index(first_tag_name,VAR_TYPE|GVAR_TYPE);
               if (var_index) {
                  _str ddstyle=' style="margin-left:13pt"';
                  typeless v=_get_var(var_index);
                  if (v._varformat()==VF_EMPTY) v="(null)";
                  if (VF_IS_INT(v) || v._varformat()==VF_LSTR) {
                     html_comments=html_comments:+"<DT><B>Value:</B> <b><code>"v"</code></b><DD"ddstyle">";
                  }
               }
            }
         }
         if (retrieved_data) {
            if (stack.HyperTextTop>0) {
               form_wid.HYPERTEXTSTACKDATA=stack;
            }
         }
      }
   }
   int vx=0, vy=0, vwidth=0, vheight=0;
   int text_x = editorctl_wid.p_cursor_x;
   int text_y = editorctl_wid.p_cursor_y;
   _map_xy(editorctl_wid,0,text_x,text_y);
   _GetVisibleScreenFromPoint(text_x,text_y,vx,vy,vwidth,vheight);
   if (doFunctionHelp) {
      int avail_width = vwidth*_twips_per_pixel_x();
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
            markerText = markerText:+"<hr>";
         }
         html_comments = markerText:+html_comments;
      }
      gFunctionHelp_form_wid._DisplayFunctionHelp(
         margin_text,
         8,  // 8 points
         text,
         html_comments,
         ',;',
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
      if (cur_param_name!='') {
         _nocheck _control ctlminihtml2;
         gFunctionHelp_form_wid.ctlminihtml2._minihtml_FindAName(cur_param_name,VSMHFINDANAMEFLAG_CENTER_SCROLL);
      }
      gFunctionHelp_form_wid._ShowWindow(SW_SHOWNOACTIVATE);
      gFunctionHelp_form_wid.refresh('w');
      _reset_idle();
      return;
   } else {
      // find the output tagwin and update it
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      cm.file_name   = first_file_name;
      cm.line_no     = first_line_no;
      cm.member_name = first_tag_name;
      cb_refresh_output_tab(cm, true);
   }

   //def_codehelp_html_comments
   //member_msg=stranslate(member_msg,'&&','&');

   // show the member (function) help dialog

   _nocheck _control ctlminihtml2;
   vx=vx*_twips_per_pixel_x();
   int screen_w = vwidth*_twips_per_pixel_x();
   int screen_h = vheight*_twips_per_pixel_y();
   int char_h = 0;
   int first_visible = 0;
   int current_line = 0;
   int list_x = 0;
   int list_h = 0;
   int list_w = 0;
   int delta_h = 0;
   int tree_wid = form_wid.LISTHELPTREEWID;
   if (tree_wid > 0 && _iswindow_valid(tree_wid)) {
      char_h = tree_wid.p_line_height;
      first_visible = tree_wid._TreeScroll();
      current_line  = tree_wid._TreeCurLineNumber();
      delta_h = _twips_per_pixel_y() * char_h * (current_line - first_visible);
      list_form_wid := tree_wid.p_active_form;
      if (_iswindow_valid(list_form_wid) && list_form_wid.p_visible) {
         list_h = list_form_wid.p_height;
         list_w = list_form_wid.p_width;
         list_x = list_form_wid.p_x;
      }
   }

   // if there is no tree control, then pivot at cursor position.
   if (list_x <= 0) list_x = _dx2lx(SM_TWIP, text_x);
   if (list_h <= 0) list_h = _dy2ly(SM_TWIP, editorctl_wid.p_height);

   // once the form moves to the left because there is more
   // space there, then leave it there, don't hop back and forth
   if (!prefer_left_placement && 
       form_wid.p_x+form_wid.p_width <= list_x &&
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

   /*
       This code is not finished yet.
       We need to pass a tag if multiple tags are found.
   */
   form_wid._DisplayFunctionHelp(
      margin_text,
      8,  // 8 points
      text,
      html_comments,
      ',;',
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
   if (cur_param_name!='') {
      _nocheck _control ctlminihtml2;
      form_wid.ctlminihtml2._minihtml_FindAName(cur_param_name,VSMHFINDANAMEFLAG_CENTER_SCROLL);
   }
   form_wid._move_window(x,y,width,height);
   form_wid._ShowWindow(SW_SHOWNOACTIVATE);
   form_wid.refresh('w');
   _reset_idle();
}

/**
 * Is the given tag in the given class on the kill list?
 * Kill list is used only when an operator is typed.
 * Current object needs to be editor control.
 *
 * @param tag_name    name of tag to look for
 * @param class_name  class name that tag is in
 * @param flags       bitset of VSAUTOCODEINFO_*
 *
 * @return 1 if this tag is on the kill list and operator typed.
 *
 * @see _do_default_fcthelp_get
 * @see _do_function_help
 */
int _check_killfcts(_str tag_name, _str class_name, int flags)
{
   // check if the symbol was on the kill list for this extension
   if (flags & VSAUTOCODEINFO_OPERATOR_TYPED) {
      //say("check kill list, symbol="match_symbol" class="match_class);
      _str search_class  = (class_name=='')? '' : class_name:+VS_TAGSEPARATOR_class;
      _str search_string = PATHSEP:+search_class:+tag_name:+PATHSEP;
      int Kindex=find_index('def-killfcts-'p_LangId,MISC_TYPE);
      if (Kindex && pos(search_string, PATHSEP:+name_info(Kindex):+PATHSEP)) {
         // skip this one, it is on the kill list
         return 1;
      }
   }
   return 0;
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
_command void list_symbols() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   //say("list_symbols: ");
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   _macro_delete_line();
   _do_list_members(false,true,null,null,null,null,false,true);
}

static boolean gIDExprFailed = false;
static long gnew_total_time = 0;
static long gold_total_time = 0;

_command void codehelp_trace_expression_info(_str operatorTyped="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   orig_chdebug := _chdebug;
   _chdebug = 1;
   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   VS_TAG_RETURN_TYPE visited:[];
   _Embeddedget_expression_info(operatorTyped==1, lang, idexp_info, visited);
   _chdebug = orig_chdebug;
   gnew_total_time = 0;
   gold_total_time = 0;
}

_command void codehelp_test_expression_info(_str startAtCursor="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
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
   //gFunctionHelp_fcthelp_get=find_index('_'p_LangId'_fcthelp_get',PROC_TYPE);
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
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   //status=(index_callable(find_index('_'p_LangId'_fcthelp_get_start',PROC_TYPE)) );
   int status=_EmbeddedCallbackAvailable('_%s_fcthelp_get_start');
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
_command void function_argument_help() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   _do_function_help(false,true,true,true);
}
_command void codehelp_trace_function_argument_help() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   orig_chdebug := _chdebug;
   _chdebug = 1;
   _do_function_help(false,true,true,true);
   _chdebug = orig_chdebug;
}

_str _getJavadocTag()
{
   _str line='';
   get_line(line);
   _str before='', after='', tag='';
   parse line with before '*' after .;
   if (substr(before,1,1)=='@') {
      tag=substr(before,2);
      return(tag);
   }
   after=strip(after);
   if (before=='' && substr(after,1,1)=='@') {
      tag=substr(after,2);
      return(tag);
   }
   return('');
}
/**
 * @return True if we are currently in the scope of a Javadoc @see tag.
 */
boolean _inJavadocSeeTag(_str &tag='')
{
   tag=_getJavadocTag();
   if (tag != "see" && tag != "throw") {
      return false;
   }
   if (!_inJavadoc()) {
      tag = "";
      return false;
   }

   save_pos(auto p);
   _begin_line();
   _TruncSearchLine("\\@see|\\@throw", "r");
   see_col := p_col;
   restore_pos(p);
   if (p_col < see_col) {
      tag = "";
      return false;
   }

   return true;
}
boolean _inJavadocSwitchToHTML()
{
   _str tag='';
   if (!_inJavadoc()) {
      return(false);
   }
   tag=_getJavadocTag();
   int index=find_index('_javadoc_'tag'_find_context_tags',PROC_TYPE);
   if (index) {
      return(false);
   }
   return(tag!='see');

   //get_line(line);tag='';
   //parse line with first second .;
   //return ((first=='*' && second=='@see') || first=='@see');
}

/**
 *
 * @param fastCheck If true, only search 1000 lines above the current line
 *                  for the start of the comment.
 *
 * @return int non-zero value if in Javadoc comment.  The non-zero value
 *             isthe column position where star '*' characters should align
 *             for the comment.
 */
int _inJavadoc(boolean fastCheck = false)
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
      orig_mark_id = _duplicate_selection('');
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
   int status=_clex_find(COMMENT_CLEXFLAG,'n-'fastCheckOption);
   if (status) {
      top();
   }

   _clex_find(COMMENT_CLEXFLAG);
   int col=p_col;
   get_line(auto text);
   text=substr(text,text_col(text,col,'P'),4);
   text=stranslate(text,"","\n");
   text=stranslate(text,"","\r");
   if (text==CODEHELP_JAVADOC_PREFIX) {
      col+=1;
   } else {
      col=0;
   }
   if (fastCheck) {
      _show_selection(orig_mark_id);
      _free_selection(mark_id);
   }
   restore_pos(p);
   return(col);
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
int _inExtendableLineComment(_str &delims='', boolean skipAllDelimsTest = false)
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
int _getLineCommentChars(_str (&commentChars)[], _str lexer_name='')
{
   // initialize the array
   commentChars._makeempty();

   // can we grab the lexer name?
   if (lexer_name == '' && _isEditorCtl()) {
      lexer_name = p_lexer_name;
   }

   // Do we even have a lexer for this mode?
   if (lexer_name == '') {
      return STRING_NOT_FOUND_RC;
   }

   if (g_lineCommentChars._indexin(lexer_name)) {
      commentChars = g_lineCommentChars:[lexer_name].commentChars;
   } else {

      // look up the lexer definition for the current mode
      int orig_wid=p_window_id;
      int temp_view_id=0;
      _str filename=_FindLexerFile(lexer_name,true,orig_wid,temp_view_id);
      if (filename == '') {
         return FILE_NOT_FOUND_RC;
      }
   #if 0
      // open the lexer definition
      if (_ini_get_section(filename,lexer_name,temp_view_id)) {
         return(1);
      }
   #endif

      // create a temporary view and search for the keywords
      int orig_view_id=p_window_id;
      p_window_id=temp_view_id;
      top();up();
      while (!search('^linecomment @=','@rih>')) {
         _str line; get_line(line);
         _end_line();
         parse line with 'linecomment' '=' line;

         // parse line comment delimeter and options
         _str cur='';
         _str col='';
         _str options='';
         cur = parse_file(line, false);
         parse line with col options;
         cur = strip(cur);
         if (cur == '') {
            continue;
         }
         if (isnumber(first_char(cur))) {
            continue;
         }

         // found one, add it to the list
         commentChars[commentChars._length()] = strip(cur);
      }

      // restore the original view
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      p_window_id=orig_wid;

      // we didn't find anything - ah, crap!
      if (!commentChars._length()) return 1;

      // save
      LINECOMMENTCHARS lcc;
      lcc.commentChars = commentChars;
      g_lineCommentChars:[lexer_name] = lcc;
   }
   return(0);
}

/**
 * Retrieve the line comment delimeters for this language
 * using the color coding settings.
 */
int _getBlockCommentChars(_str (&startChars)[], _str (&endChars)[],  boolean (&nesting)[], _str lexer_name='')
{
   // initialize the array
   startChars._makeempty();
   endChars._makeempty();

   // can we grab the lexer name?
   if (lexer_name == '' && _isEditorCtl()) {
      lexer_name = p_lexer_name;
   }

   // Do we even have a lexer for this mode?
   if (lexer_name == '') {
      return STRING_NOT_FOUND_RC;
   }

   if (g_blockCommentChars._indexin(lexer_name)) {
      startChars = g_blockCommentChars:[lexer_name].startChars;
      endChars = g_blockCommentChars:[lexer_name].endChars;
      nesting = g_blockCommentChars:[lexer_name].nesting;
   } else {
      int orig_wid=p_window_id;
      int temp_view_id=0;

      // look up the lexer definition for the current mode
      _str filename=_FindLexerFile(lexer_name,true, orig_wid, temp_view_id);
      if (filename == '') {
         return FILE_NOT_FOUND_RC;
      }

   #if 0
      // open the lexer definition
      int orig_wid=p_window_id;
      int temp_view_id=0;
      if (_ini_get_section(filename,lexer_name,temp_view_id)) {
         return(1);
      }
   #endif

      // create a temporary view and search for the keywords
      int orig_view_id=p_window_id;
      p_window_id=temp_view_id;
      top();up();
      while (!search('^mlcomment @=','@rih>')) {
         _str line; get_line(line);
         _end_line();
         parse line with 'mlcomment' '=' line;

         // parse line comment delimeter and options
         _str curS='';
         _str curE='';
         _str col='';
         _str options='';
         //parse line with curS curE col options;
         parse line with curS curE options;
         curS = strip(curS);
         curE = strip(curE);
         if (curS == '' || curE == '') {
            continue;
         }
         if (isnumber(first_char(curS)) || isnumber(first_char(curE))) {
            continue;
         }
         // found one, add it to the list
         startChars[startChars._length()] = curS;
         endChars[endChars._length()] = curE;

         //Check if nesting is set
         if (pos('nesting', options)) {
            nesting[nesting._length()] = true;
         } else {
            nesting[nesting._length()] = false;
         }
      }

      // restore the original view
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      p_window_id=orig_wid;

      BLOCKCOMMENTCHARS bcc;
      bcc.startChars = startChars;
      bcc.endChars = endChars;
      bcc.nesting = nesting;
      g_blockCommentChars:[lexer_name] = bcc;
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
   int orig_line = p_line;
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

static int _inExtendableLineCommentWithDelimeters(_str commentChars='//', boolean skipAllDelimsTest = false)
{
   // we must be in a comment
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(0);
   }

   // check if we are at the end of the line
   save_pos(auto p);
   int orig_col = p_col;
   boolean at_end = (at_end_of_line());

   // find the start of the comment
   _beginLineComment();

   // line comment starts with comment start chars
   int commentLength=length(commentChars);
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
   boolean prev_line_has_comment=true;
   restore_pos(p);
   if (up()) prev_line_has_comment=false;
   if (_clex_find(0,'g')!=CFG_COMMENT) prev_line_has_comment=false;
   _beginLineComment();
   if (get_text(commentLength)!=commentChars || col!=p_col) prev_line_has_comment=false;

   // now check if the next line has a line comment
   boolean next_line_has_comment=true;
   restore_pos(p);
   if (down()) next_line_has_comment=false;
   if (_clex_find(0,'g')!=CFG_COMMENT) next_line_has_comment=false;
   _beginLineComment();
   if (get_text(commentLength)!=commentChars || col!=p_col) next_line_has_comment=false;

   // check if the current line is all delimters (e.g. slashes for C-style comments)
   restore_pos(p);
   p_col=col;
   boolean all_delims= skipAllDelimsTest || (orig_col > p_col && pos('^['commentChars']*[ \t]*$',get_text(orig_col-p_col),1,'r')==1);

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
boolean _maybeSplitLineComment()
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
   _str commentChars='';
   int orig_col = p_col;
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
   _str padding = '';
   get_line_raw(auto line);
   int afterDelimRaw = text_col(line, p_col + commentChars._length(), 'P');
   int contentCol = pos("[~ \\t]", line, afterDelimRaw, 'R');
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
int _inString(_str &delim)
{
   // we must be in a string
   if (_clex_find(0,'g')!=CFG_STRING) {
      delim='';
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
   int col = p_col;
   delim = get_text();
   if (delim != '"' && delim != "'") {
      restore_pos(p);
      return 0;
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
int _GetCurrentCommentInfo(int &comment_flags,_str &orig_comment,_str &return_type, _str &line_prefix, int (&blanks):[][],
                           _str &doxygen_comment_start)
{
   _UpdateContext(true);
   comment_flags=0;
   orig_comment='';
   save_pos(auto p);
   _clex_skip_blanks();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if (context_id <= 0) {
      restore_pos(p);
      return(1);
   }
   // get the information about the current function
   _str tag_name = '';
   _str type_name = '';
   _str file_name = '';
   int start_line_no = 0;
   int start_seekpos = 0;
   int scope_line_no = 0;
   int scope_seekpos = 0;
   int end_line_no = 0;
   int end_seekpos = 0;
   _str class_name = '';
   int tag_flags = 0;
   _str signature = '';
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);
   //say('n='tag_name);
   //say('sig='signature' len='length(signature));

   _GoToROffset(start_seekpos);
   if (tag_tree_type_is_func(/*cm.*/type_name)) {
      _UpdateLocals(true);
   }

   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   int first_line, last_line;
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      p_RLine=start_line_no;
      _GoToROffset(start_seekpos);
      // We temporarily change the buffer name just in case the Javadoc Editor
      // is the one getting the comments.
      _str old_buf_name=p_buf_name;
      p_buf_name="";
      _do_default_get_tag_comments(comment_flags,type_name, orig_comment, def_codehelp_max_comments*10, false,
         line_prefix,blanks,doxygen_comment_start);
      p_buf_name=old_buf_name;
   } else {
      //init_modified=1;
      first_line = start_line_no;
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
   //say("find_expected_type_from_expression: IN");
   // drop into embedded mode to find expression start
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   //say("find_expected_type_from_expression: passed embedded");
   // find the function to find the expression context
   ep_index := _FindLanguageCallbackIndex('_%s_get_expression_pos');
   if (!ep_index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("find_expected_type_from_expression: have expression_ops callback");
   // find the function to analyze return types, we need this
   ar_index := _FindLanguageCallbackIndex('_%s_analyze_return_type');
   if (!ar_index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("find_expected_type_from_expression: have analyze return type");
   // we'll need this information later
   typeless tag_files=tags_filenamea(p_LangId);
   boolean case_sensitive=p_EmbeddedCaseSensitive;

   // save the current buffer position for restore
   typeless orig_pos;
   save_pos(orig_pos);

   //say("find_expected_type_from_expression: prefixpos="prefixexpstart_offset);
   // get the position of a comparible identifier in the
   // current expression that we can use to determine the expected
   // return type
   _GoToROffset(prefixexpstart_offset);
   int lhs_start_offset=0;
   _str expression_op='';
   int reference_count=0;
   int status=call_index(lhs_start_offset,expression_op,reference_count,ep_index);
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
   status = _Embeddedget_expression_info(false,ext,idexp_info,visited,depth);

   //say("find_expected_type_from_expression: lastid="idexp_info.lastid" prefixexp="idexp_info.prefixexp" status="status);
   if (status) {
      restore_pos(orig_pos);
      return(status);
   }

   // analyze the return type of the identifier to compare to
   _UpdateContext(true);
   _UpdateLocals(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   status = _Embeddedfind_context_tags(errorArgs,idexp_info.prefixexp,
                                       idexp_info.lastid,idexp_info.lastidstart_offset,
                                       idexp_info.info_flags,idexp_info.otherinfo,
                                       false,def_tag_max_function_help_protos,
                                       true,case_sensitive,
                                       VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYPROC,
                                       VS_TAGCONTEXT_ALLOW_locals,
                                       visited, depth);
   //say("find_expected_type_from_expression: find status="status" num_matches="tag_get_num_of_matches());
   if (status < 0) {
      restore_pos(orig_pos);
      return(status);
   }

   // analyze the return type of each and every match
   VS_TAG_RETURN_TYPE found_rt;
   _str tag_name,class_name,type_name,file_name,return_type,tag_file,signature;
   int tag_flags=0,line_no=0;
   int i,n=tag_get_num_of_matches();
   for (i=1; i<=n; ++i) {
      // get the details about this tag
      tag_get_match(i,tag_file,tag_name,type_name,file_name,line_no,
                    class_name,tag_flags,signature,return_type);

      // compute it's return type
      tag_return_type_init(found_rt);
      status = _Embeddedanalyze_return_type(ar_index,errorArgs,tag_files,
                                            tag_name,class_name,type_name,
                                            tag_flags,file_name,return_type,
                                            found_rt, visited);
      //say("find_expected_type_from_expression: ar status="status" return_type="return_type" found_rt="found_rt.return_type);
      if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         continue;
      }

      // does the return type match the last found return type?
      if (rt==null || rt.return_type=='') {
         rt=found_rt;
      } else if (!tag_return_type_equal(rt,found_rt,case_sensitive)) {
         errorArgs[1]=tag_name;
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
void _do_list_members(boolean OperatorTyped,
                      boolean DisplayImmediate,
                      _str (&syntaxExpansionWords)[]=null,
                      _str expected_type=null,
                      VS_TAG_RETURN_TYPE &rt=null,
                      _str expected_name=null,
                      boolean prefixMatch=false,
                      boolean selectMatchingItem=false,
                      boolean doListParameters=false)
{
   // IF we are in a recorded macro, just forget it
   if (_macro('r')) {
      // Too slow to display GUI
      return;
   }
   
   if (_chdebug > 0) {
      say("_do_list_members: operator="OperatorTyped", expected_ty="(expected_type ? expected_type : "<null>")", expected_name="(expected_name ? expected_name : "<null>"));
   }
   
   //say("do_list_members("OperatorTyped","DisplayImmediate);
   int orig_col=p_col;
   left();
   p_col=orig_col;
   //boolean inJavadocSeeTag=_inJavadocSeeTag();
   struct VS_TAG_RETURN_TYPE visited:[];

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   _str lang=p_LangId;
   int status=0;
   // set up info flags to be seen by get_expression_info
   if (expected_type!=null && expected_type!='') {
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
      idexp_info.lastid='';
      idexp_info.prefixexp='';
      idexp_info.lastidstart_col=p_col;
      idexp_info.lastidstart_offset=(int)_QROffset();
      idexp_info.prefixexpstart_offset=(int)_QROffset();
      idexp_info.info_flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
      status=0;
   }

   if (status) {
      if (!OperatorTyped && expected_type==null) {
         _str msg=_CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!='') {
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
         _str msg=_CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!='' && !OperatorTyped) {
            //_message_box(msg);
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
   _str errorArgs[];
   status = AutoCompleteUpdateInfo(true,
                                   DisplayImmediate,   /* force update */
                                   false,              /* insert longest match */
                                   OperatorTyped,
                                   prefixMatch,
                                   idexp_info,
                                   expected_type,
                                   rt,
                                   expected_name,
                                   selectMatchingItem,
                                   doListParameters,
                                   errorArgs
                                   );
   if (status < 0) {
      msg := _CodeHelpRC(status, errorArgs);
      if (msg != '' && !OperatorTyped) {
         message(msg);
      }
   }
}

/**
 * Attempt to complete the tag prefix under the cursor with the
 * longest matching tag.  If there are multiple matches, bring
 * up the list symbols dialog to help to user select one.
 */
void _do_complete()
{
   //say("_do_complete()");

   // check the current context, don't try it within string or comment
   int cfg=_clex_find(0,'g');
   if (_in_comment() || (cfg==CFG_STRING && _LanguageInheritsFrom('cob'))) {
      save_pos(auto p);
      left();cfg=_clex_find(0,'g');
      if (_in_comment() || cfg==CFG_STRING) {
         if (expand_alias()) {
            message('Tag completion not supported in string or comment');
         }
         restore_pos(p);
         return;
      }
      restore_pos(p);
   }

   // do we have a list-tags or proc-search function?
   _str lang = p_LangId;
   if (!_istagging_supported(lang)
       && !_LanguageInheritsFrom('xml') && !_LanguageInheritsFrom('dtd')   // I bet we won't need this for long..
       ) {
      expand_alias();
      return;
   }

   // do we have tag files set up for this extension?
   MaybeBuildTagFile(lang);
   _UpdateContext(true);
   _UpdateLocals(true);

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // match the tag at the current position
   _str lastid = '';
   tag_clear_matches();
   _str errorArgs[]; errorArgs._makeempty();

   // using Context Tagging(R) to find matches
   _SetTimeout(def_auto_complete_timeout_forced);
   caseSensitive := (_GetCodehelpFlags(lang) & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE)? true:false;
   int i, num_matches = context_match_tags(errorArgs,lastid,false,def_tag_max_find_context_tags,false,caseSensitive);
   timedOut := _CheckTimeout();
   _SetTimeout(0);

   if (_chdebug > 0) {
      say("_do_complete: ctx_match_tags -> num_matches="num_matches);
   }

   if (num_matches <= 0) {
      status := VSCODEHELPRC_NO_SYMBOLS_FOUND;
      if (num_matches < 0) status = num_matches;
      if (errorArgs._length()==0) errorArgs[1]=lastid;
      _str msg=_CodeHelpRC(status, errorArgs);
      if (expand_alias() && msg!='') {
         message(msg);
      }
      return;
   }

   // force list symbols if it appears that the list was truncated
   if (num_matches >= def_tag_max_find_context_tags || timedOut) {
      if (_chdebug > 0) {
         say("_do_complete: timed_out, going to list_symbols");
      }
      _macro_delete_line();
      _do_list_members(false,true,null,null,null,null,true,true);
      return;
   }

   // look for exact matches in the match set
   int lastid_len=length(lastid);
   _str longest_prefix = '';
   _str longest_case_prefix = '';
   _str longest_caption = '';
   if (num_matches > 0) {
      tag_get_detail2(VS_TAGDETAIL_match_name, 1, longest_caption);
      parse longest_caption with longest_caption '<';
      longest_prefix = longest_caption;
   }
   for (i=1; i<=num_matches; i++) {
      _str tag_name='';
      tag_get_detail2(VS_TAGDETAIL_match_name, i, tag_name);
      parse tag_name with tag_name '<';
      while (longest_prefix != '' && pos(longest_prefix, tag_name, 1, 'i')!=1) {
         longest_prefix = substr(longest_prefix, 1, length(longest_prefix)-1);
      }
      if (lastid!='' && pos(lastid, tag_name, 1, 'e')==1) {
         longest_case_prefix = substr(tag_name, 1, length(longest_prefix));
      }
      if (length(tag_name) > length(longest_caption)) {
         longest_caption = tag_name;
      }
   }
   longest_prefix=strip(longest_prefix,'t');

   // replace the word with completed or partially completed word
   if (length(longest_prefix) >= length(lastid) && longest_prefix:!=lastid) {
      p_col=p_col-lastid_len;
      int orig_col = p_col;
      int word_col = 0;
      _str word=cur_identifier(word_col,VSCURWORD_FROM_CURSOR);
      //say("word="word" p_col="p_col" lastid="lastid);
      if (word_col <= orig_col &&  word_col + _rawLength(word) >= orig_col) {
         p_col = word_col;
         if (_GetCodehelpFlags() & VSCODEHELPFLAG_REPLACE_IDENTIFIER) {
            _delete_text(_rawLength(word));
         } else {
            _delete_text(_rawLength(lastid));
         }
      }
      if (length(longest_case_prefix) >= length(lastid)) {
         longest_prefix = longest_case_prefix;
      }
      _insert_text(longest_prefix);
   } else if (num_matches <= 1 || length(longest_prefix) == length(lastid)) {
      if (!expand_alias("","",alias_filename(true,false))) return;
   }

   // force list symbols if the result is not an exact tag match
   if ((num_matches > 1 && length(longest_caption) > length(longest_prefix)) ||
       (num_matches >= 1 && longest_prefix == '')) {
      _macro_delete_line();
      _do_list_members(false,true,null,null,null,null,true,true);
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
   int max_width = 0;
   if (initial_width > border_width) {
      max_width = initial_width - border_width;
   }

   // go through each category and each list of items underneath
   int cat_index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (cat_index > 0) {
      // get the width of the caption
      int caption_width = _text_width(_TreeGetCaption(cat_index));
      if (caption_width > max_width) {
         max_width = caption_width;
      }

      // go through the items underneath
      int tag_index = _TreeGetFirstChildIndex(cat_index);
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

int _update_list_height(int initial_height=0, boolean snap=true, boolean countLines=false)
{
   // get the size of the visible screen
   int vx, vy, vwidth, vheight;
   _GetVisibleScreen(vx,vy,vwidth,vheight);

   // adjust width of form to accomodate longer captions
   int form_height = _dy2ly(p_xyscale_mode, vheight);

   // count the number of lines in the tree
   int line_count = 0;
   if (countLines) {
      int show_children, bm1, bm2, line_number, tree_flags=0;
      int cat_index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (cat_index > 0) {
         // go through the items underneath
         int tag_index = _TreeGetFirstChildIndex(cat_index);
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
      _str h=_retrieve_value(p_active_form.p_name:+".p_height");
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
                                 boolean prefer_positioning_above=false)
{
   int x=text_x;
   int y=text_y+text_height;
   _map_xy(editorctl_wid,0,x,y);
   if (FunctionHelp_form_wid) {
      int fx=0;
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
         int fx=0;
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

   int junk=0;
   form_wid._get_window(junk,junk,width,height);
   form_wid._move_window(x,y,width,height);
}

/**
 * Timer callback for updating function parameter help
 */
void _CodeHelp()
{
   //say("_CodeHelp: ");
   if (!ginFunctionHelp) return;
   // check if the tag database is busy and we can't get a lock.
   dbName := _GetWorkspaceTagsFilename();
   if (tag_trylock_db(dbName)) {
      still_in_code_help();
      tag_unlock_db(dbName);
   }
}

/**
 * Callback for updating list members when we switch buffers.
 */
void _switchbuf_code_help()
{
   if (def_switchbuf_cd) {
#if __UNIX__
       // If this buffer name has a valid path
       if (substr(p_buf_name,1,1)=='/') {
          _str path=_strip_filename(p_buf_name,'N');
          // We don't want buffer order changed when if build window
          // buffer is activate so here we change the load options before
          // calling cd().
          typeless old_load_options=def_load_options;
          def_load_options=stranslate(lowcase(def_load_options),' ','+bp');
          _str cwd=getcwd();
          if (last_char(cwd)!=FILESEP) cwd=cwd:+FILESEP;
          if (last_char(path)!=FILESEP) path=path:+FILESEP;
          if (!file_eq(path,cwd)) {
             cd('-a 'maybe_quote_filename(path),'q');
          }
          def_load_options=old_load_options;
       }
#else
       // If this buffer name has a valid path
       if ((substr(p_buf_name,2,1)==':' && substr(p_buf_name,3,1)=='\') ||
           (substr(p_buf_name,1,2)=='\\' && pos('\',p_buf_name,4)!=0)) {
          _str path=_strip_filename(p_buf_name,'N');
          // We don't want buffer order changed when if build window
          // buffer is activate so here we change the load options before
          // calling cd().
          typeless old_load_options=def_load_options;
          def_load_options=stranslate(lowcase(def_load_options),' ','+bp');
          _str cwd=getcwd();
          if (last_char(cwd)!=FILESEP) cwd=cwd:+FILESEP;
          if (last_char(path)!=FILESEP) path=path:+FILESEP;
          if (!file_eq(path,cwd)) {
             cd('-a 'maybe_quote_filename(path),'q');
          }
          def_load_options=old_load_options;
       }
#endif

   }
   // on got focus
   if (arg(2)=='W') {
      if (geditorctl_wid==p_window_id) {
         return;
      }
   }
   TerminateFunctionHelp(0);
}

static boolean still_in_function_help(long idle)
{
   if (gFunctionHelp_MouseOver) {
      int mx, my;
      mou_get_xy(mx,my);
      boolean in_rect=mx>=gFunctionHelp_MouseOverInfo.x && mx<gFunctionHelp_MouseOverInfo.x+gFunctionHelp_MouseOverInfo.width &&
             my>=gFunctionHelp_MouseOverInfo.y && my<gFunctionHelp_MouseOverInfo.y+gFunctionHelp_MouseOverInfo.height;
      int form_wid=_GetMouWindow();
      if (form_wid && _iswindow_valid(form_wid)) {
         form_wid=form_wid.p_active_form;
         if (form_wid==gFunctionHelp_form_wid) {
            return(false);
         }
      }

      int wid=gFunctionHelp_MouseOverInfo.wid;
      boolean other=!_iswindow_valid(wid) ||
          !_AppActive() ||
         gFunctionHelp_MouseOverInfo.buf_id!=wid.p_buf_id ||
          gFunctionHelp_MouseOverInfo.LineNum!=wid.p_line ||
         gFunctionHelp_MouseOverInfo.col!=wid.p_col ||
         gFunctionHelp_MouseOverInfo.ScrollInfo!=wid._scroll_page() /*|| (gBBWid && !_iswindow_valid(gBBWid))*/
        ;

      if (!in_rect || other) {
         TerminateFunctionHelp(0);
         return(true);
      }
      if (!gFunctionHelp_pending) {
         return(false);
      }
   } else {
      if (point('s')<gFunctionHelp_FunctionLineOffset+length(gFunctionHelp_starttext) ||
          get_text(length(gFunctionHelp_starttext),gFunctionHelp_FunctionLineOffset)!=gFunctionHelp_starttext
          ) {
         TerminateFunctionHelp(0);
         return(true);
      }
   }

   if (gFunctionHelp_pending) {
      boolean bool=idle>=def_codehelp_idle;

      if (gFunctionHelp_MouseOver) {
         bool=idle>=_default_option(VSOPTION_TOOLTIPDELAY)*100;
      }

      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      if (bool && tag_trylock_db(dbName)) {
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
            boolean insert_space=(!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN))? true:false;
            gFunctionHelp_InsertedParam=maybe_insert_current_param(true, true, insert_space);
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
         int text_x=0;
         int text_y=p_cursor_y+p_font_height-1;
         _map_xy(p_window_id,0,text_x,text_y);
         _dxy2lxy(SM_TWIP,text_x,text_y);
         int x=0;
         if ( gFunctionHelp_form_wid ) {
            int y=gFunctionHelp_form_wid.p_y;
            if (text_y>y && text_y<y+gFunctionHelp_form_wid.p_height) {
               //gFunctionHelp_form_wid.p_visible=0;
            }
         }
      }
   }
   return(false);
}

static void still_in_code_help(boolean ignoreIdle=false)
{
   int orig_wid=p_window_id;
   int focus_wid=_get_focus();

   if (ginFunctionHelp && gFunctionHelp_MouseOver) {
      if (!_iswindow_valid(gFunctionHelp_MouseOverInfo.wid)) {
         TerminateFunctionHelp(0);
         return;
      }
      focus_wid=gFunctionHelp_MouseOverInfo.wid;
   }

   if (!focus_wid) {
      TerminateFunctionHelp(0);
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
      TerminateFunctionHelp(0);
      if (_iswindow_valid(orig_wid)) p_window_id=orig_wid;
      return;
   }
   long idle=_idle_time_elapsed();
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
boolean CodeHelpActive(boolean itemIsSelected=false)
{
   return false;
}

void XW_TerminateCodeHelp() 
{
   TerminateFunctionHelp(0);
}

void TerminateMouseOverHelp()
{
   _KillMouseOverBBWin();
   if (gFunctionHelp_MouseOver) {
      TerminateFunctionHelp(false);
   }
}

void RefreshListHelp()
{
   AutoCompleteUpdateInfo(false);
}

static int maybe_list_arguments(boolean DisplayImmediate)
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
   if (!_in_function_scope() || _in_string()) {
      return(0);
   }

   // first check if we have a find-arguments function
   // find-arguments is responsible for parameter type matching
   // and for listing javadoc paraminfo supplied arguments
   // find the function to match return types
   ar_index := _FindLanguageCallbackIndex('_%s_analyze_return_type');
   if (!ar_index) {
      return(0);
   }
   // obtain the expected parameter type
   int i=gFunctionHelpTagIndex;
   int n=gFunctionHelp_list._length();
   if (i>=0 && i<n) {
      _str expected_name=gFunctionHelp_list[i].ParamName;
      _str expected_type=gFunctionHelp_list[i].ParamType;
      _str arglist_type=get_arg_info_type_name(gFunctionHelp_list[i]);
      if (expected_type!='' && arglist_type!='define') {
         _do_list_members(false,DisplayImmediate,null,expected_type,null,expected_name,false,DisplayImmediate,true);
      }
      return(1);
   }
   return(0);
}

static boolean maybe_insert_current_param(boolean do_select=false,
                                          boolean check_if_defined=true,
                                          boolean insert_space=false)
{
   // do not do selection if we are not configured to overtype it
   if (do_select && def_persistent_select!='D') {
      return(false);
   }
   // do not insert parameters inside strings or comments
   int cfg = _clex_find(0,'g');
   if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
      return false;
   }
   int numArgs=0;
   int i=gFunctionHelpTagIndex;
   int n=gFunctionHelp_list._length();
   if (i>=0 && i<n) {
      _str param_name=gFunctionHelp_list[i].ParamName;
      numArgs = gFunctionHelp_list[i].arglength._length()-1;
      if (param_name!='' && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
         _str ext;

         VS_TAG_IDEXP_INFO idexp_info;
         tag_idexp_info_init(idexp_info);

         struct VS_TAG_RETURN_TYPE visited:[];
         int status=_Embeddedget_expression_info(false, ext, idexp_info, visited);

         if (!status && idexp_info.lastid!=param_name && !_LanguageInheritsFrom('cs') &&
             (idexp_info.prefixexp=='' || (_LanguageInheritsFrom('cob') && lowcase(idexp_info.prefixexp)=="using")) &&
             (p_col==idexp_info.lastidstart_col+_rawLength(idexp_info.lastid)) &&
             (idexp_info.lastid=='' || pos(idexp_info.lastid,param_name,1,(p_EmbeddedCaseSensitive? '':'i'))==1)) {
            _UpdateContext(true);
            _UpdateLocals(true);

            if (check_if_defined) {
               status=_Embeddedfind_context_tags(idexp_info.errorArgs,'',param_name,
                                                 idexp_info.lastidstart_offset,idexp_info.info_flags,idexp_info.otherinfo,
                                                 false,def_tag_max_list_matches_symbols,
                                                 true,p_EmbeddedCaseSensitive,
                                                 VS_TAGFILTER_ANYDATA|VS_TAGFILTER_DEFINE|VS_TAGFILTER_ENUM,
                                                 VS_TAGCONTEXT_ALLOW_locals,
                                                 visited, 0);
            }
            if (status >= 0 && tag_get_num_of_matches() > 0) {
               int orig_col=p_col;
               p_col=idexp_info.lastidstart_col;
               _macro('m',_macro('s'));
               int count=_rawLength(idexp_info.lastid);
               if (count) {
                  _delete_text(count);
                  _macro_call('_delete_text',count);
               }
               if (insert_space) {
                  _macro_call('_insert_text',' ');
                  _insert_text(' ');
               }
               if (do_select) {
                  _macro_call('_select_char','','C');
                  _select_char('','C');
               }
               _macro_call('_insert_text',param_name);
               _insert_text(param_name);

               // let the user know what happened
               notifyUserOfFeatureUse(NF_INSERT_MATCHING_PARAMETERS);
               return(true);
            }
         }
      }
   }
   if (insert_space && numArgs>=1) {
      _macro('m',_macro('s'));
      _macro_call('_insert_text',' ');
      _insert_text(' ');
   }
   return(false);
}

// defeat auto-insert parameter if parameter help is active and
// the parameter inserted is not even a prefix match.
static void maybe_uninsert_current_param(boolean terminateList=false)
{
   if (!ginFunctionHelp || gFunctionHelp_pending || !select_active() ||
       !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) ||
       !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
      return;
   }
   if (terminateList) {
      _macro_call('maybe_delete_selection');
      maybe_delete_selection();
      gFunctionHelp_InsertedParam=false;
      return;
   }
}

void maybe_dokey(_str key)
{
   if (_QReadOnly()) {
      int kt_index=last_index('','k');
      int command_index=eventtab_index(_default_keys,p_mode_eventtab,event2index(key));
      typeless arg2='';
      parse name_info(command_index) with ',' arg2 ',';
      if ( arg2=='' ) {
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
static DoDefaultKey(_str key,boolean doTerminate=true)
{
   last_index(prev_index('','C'),'C');
   //orig_eventtab=p_eventtab;
   //p_eventtab=0;
   _RemoveEventtab(defeventtab codehelp_keys);
   if (doTerminate) {
      maybe_dokey(key);
      if (ginFunctionHelp && _iswindow_valid(geditorctl_wid)) {
         _AddEventtab(defeventtab codehelp_keys);
      }
   } else {
      maybe_dokey(key);
      if (ginFunctionHelp && _iswindow_valid(geditorctl_wid)) {
         //p_eventtab=orig_eventtab;
         _AddEventtab(defeventtab codehelp_keys);
      }
   }
}

void codehelp_keyin(_str key)
{
   // workaround for codehelp_keys eventtable for callback enabled keys
   if (OvertypeListenerKeyin(key)) return;
   AutoBracketKeyin(key);
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
   boolean doTerminate=false;
   _str key=last_event();
   boolean unique=false;
   int index=0;
   int status=0;

   // do not allow file to be modified if it is read-only
   if (_QReadOnly()) {
      if ((length(key)==1 && _asc(_maybe_e2a(key))>=27) || (key==name2event('C- '))) {
         int orig_wid = p_window_id;
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
       (key!=' ' || (_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE))
      ) {
      still_in_code_help();
      int cfg = _clex_find(0,'g');
      if (ginFunctionHelp && !gFunctionHelp_pending &&
          gFunctionHelp_InsertedParam && key:==')' &&
          get_text(1, (int)point('s')-1) != ' ' &&
          get_text(1, (int)point('s')-1) != '(' &&
          (cfg!=CFG_STRING && cfg!=CFG_COMMENT) &&
          !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
         // function help is active, but they type ')' in function help
         // still insert the padding space before the paren
         _macro_call('_insert_text',' ');
         _insert_text(' ');
      } else if (ginFunctionHelp && !gFunctionHelp_pending &&
                 gFunctionHelp_OperatorTyped && key:==')' &&
                 get_text(1, (int)point('s')-1) != ' ' &&
                 get_text(1, (int)point('s')-1) != '(' &&
                 (cfg!=CFG_STRING && cfg!=CFG_COMMENT) &&
                 !(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
         // function help is active, but they type ')' in function help
         // still insert the padding space before the paren
         _macro_call('_insert_text',' ');
         _insert_text(' ');
      }

      if (!doTerminate || key:!=' ' || !(_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE)) {

         if (gFunctionHelp_InsertedParam &&
             ginFunctionHelp && !gFunctionHelp_pending) {
            if (pos(key,"`\'\"~!")) {
               maybe_uninsert_current_param(true);
            } else if (pos('[,|)>]',key,1,'r') || (key==' ' && _LanguageInheritsFrom('cob'))) {
               _macro_call('maybe_deselect');
               maybe_deselect();    // deselect the auto-inserted param
            }
         }
         DoDefaultKey(key,doTerminate);

         gFunctionHelp_InsertedParam=false;
         if (ginFunctionHelp && !gFunctionHelp_pending) {
            // get next parameter for argument completion
            if (key=='|' && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
               _update_function_help();
               gFunctionHelp_InsertedParam=maybe_insert_current_param(true,true);
            } else if (key==',') {
               _update_function_help();
               boolean insert_space=(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA)? false:true;
               gFunctionHelp_InsertedParam=maybe_insert_current_param(true,true,insert_space);
            } else if (key==' ' && _LanguageInheritsFrom('cob') &&
                       (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
               _update_function_help();
               gFunctionHelp_InsertedParam=maybe_insert_current_param(true,true,false);
            }
         }
         // display auto-list-members for parameter information
         if (ginFunctionHelp && !gFunctionHelp_pending &&
            (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
            (key==',' || key=='|' || (key==' ' && _LanguageInheritsFrom('cob')))) {
            _update_function_help();
            maybe_list_arguments(false);
            if (gFunctionHelp_InsertedParam) {
               maybe_uninsert_current_param();
            }
         }
      }
      return;
   }
   int function_help_wid=0;
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
         boolean had_auto_param=false;
         if (ginFunctionHelp && !gFunctionHelp_pending && gFunctionHelp_InsertedParam) {
            had_auto_param = select_active();
            _macro_call('maybe_deselect');
            maybe_deselect();    // deselect the auto-inserted param
            gFunctionHelp_InsertedParam=false;
            _update_function_help();
            return;
         }
         DoDefaultKey(key,doTerminate);
         // were we in list help?
         boolean was_in_list_help = false;
         // maybe insert matching parameter name
         if (had_auto_param && gFunctionHelp_OperatorTyped &&
             ginFunctionHelp && !gFunctionHelp_pending &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION)) {
            _update_function_help();
            if (ginFunctionHelp && !gFunctionHelp_pending) {
               maybe_insert_current_param(true);
            }
         }
         // display auto-list-members for parameter information
         if (ginFunctionHelp && !gFunctionHelp_pending &&
             gFunctionHelp_OperatorTyped && was_in_list_help) {
            _update_function_help();
            maybe_list_arguments(false);
         }
         return;
      }
      if (ginFunctionHelp && !gFunctionHelp_pending && select_active() &&
          (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
          (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION) &&
          gFunctionHelp_InsertedParam) {
         _macro_call('maybe_deselect');
         maybe_deselect();  // deselect the auto-inserted param
      }
      DoDefaultKey(key,true);
      return;

   case C_G:
      if (!iscancel(key)) {
         DoDefaultKey(key,false /* don't terminate */);
         return;
      }
      TerminateFunctionHelp(0);
      return;
   case ESC:
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call('maybe_delete_selection');
         maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
         return;
      }
      TerminateFunctionHelp(0);
      maybeCommandMode();
      return;

   case name2event('A-.'):
   case name2event('M-.'):
   case name2event('A-M-.'):
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call('maybe_delete_selection');
         maybe_delete_selection();
         gFunctionHelp_InsertedParam=false;
      }
      still_in_code_help();
      DoDefaultKey(key);
      return;
   case name2event('C-DOWN'):
      still_in_code_help();
      //say("got here C-DOWN");
      DoDefaultKey(key);
      return;
   case name2event('C-UP'):
      still_in_code_help();
      //say("got here C-UP");
      DoDefaultKey(key);
      return;

   case name2event(' '):
      if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_COMPLETION)) {
         still_in_code_help(true);
         if (ginFunctionHelp && !gFunctionHelp_pending && select_active() &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_PARAMS) &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION) &&
             gFunctionHelp_InsertedParam) {
            _macro_call('maybe_deselect');
            maybe_deselect();  // deselect the auto-inserted param
         }
         DoDefaultKey(key);
         return;
      }
      // drop through as if they typed control-space
   case name2event('C- '):
      still_in_code_help();
      //say("got here C-SPACE or SPACE");
      if (key==name2event('C- ') && ginFunctionHelp && !gFunctionHelp_pending) {
         _update_function_help();
         if (ginFunctionHelp && !gFunctionHelp_pending && maybe_insert_current_param()) {
            return;
         }
      }
      DoDefaultKey(key);
      return;

   case name2event('A-INS'):
   case name2event('M-INS'):
      still_in_code_help();
      //say("got here A-INS, ");
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         _update_function_help();
         if (ginFunctionHelp && !gFunctionHelp_pending && maybe_insert_current_param(false,false)) {
            return;
         }
      }
      DoDefaultKey(key);
      return;
   case name2event('A-,'):
   case name2event('M-,'):
   case name2event('A-M-,'):
      if (ginFunctionHelp && !gFunctionHelp_pending && 
          gFunctionHelp_InsertedParam && select_active()) {
         _macro_call('maybe_delete_selection');
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
   case name2event('c-pgdn'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelp(1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('c-pgup'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelp(-1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-pgdn'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-pgup'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(-1);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-home'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(2);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-end'):
      still_in_code_help();
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         nextFunctionHelpPage(-2);
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-up'):
      still_in_code_help();
      function_help_wid = ParameterHelpReposition(true);
      if (function_help_wid) {
         return;
      }
      DoDefaultKey(key);
      return;
   case name2event('s-down'):
      still_in_code_help();
      function_help_wid = ParameterHelpReposition(false);
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
             form_wid.ctlminihtml1._minihtml_command('copy');
             form_wid.ctlminihtml1._minihtml_command('deselect');
            return;
         } else if (form_wid.ctlminihtml2._minihtml_isTextSelected()) {
                    form_wid.ctlminihtml2._minihtml_command('copy');
                    form_wid.ctlminihtml2._minihtml_command('deselect');
            return;
         } else {
            DoDefaultKey(key,false);
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
int ParameterHelpReposition(boolean aboveCurrentLine)
{
   still_in_code_help();
   if (ginFunctionHelp && !gFunctionHelp_pending) {
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

// Find the given tag to extract the comments surrounding.
// Searches the current context to locate the tag nearest to
// the given line.
//    tag_type     -- (reference) contains type name of tag found
//    class_name   -- (reference) name of class tag is found in
//    temp_view_id -- on success, contains temp_view_id containing file
//    orig_view_id -- on success, contains original view ID
//    tag_name     -- name of tag to search for
//    file_name    -- name of file that the tag is located in
//    line_no      -- the 'start' line for the tag
//    type_name    -- tag type (VS_TAGTYPE_*) to search for
//    class_name   -- class name to search for
// On success, 'temp_view_id' holds the view ID for the file
// the comment came from, and 'orig_view_id' is the original view ID.
//
static int _LocateTagForExtractingComment(_str &tag_type, _str &class_name,
                                          int &temp_view_id, int &orig_view_id,
                                          _str tag_name, _str file_name, int line_no)
{
   switch (_FileQType(file_name)) {
   case VSFILETYPE_URL_FILE:
      // URL access can be very slow, so don't try to get the comments
      return(1);
   }
   // is this a binary file?
   if (_QBinaryLoadTagsSupported(file_name)) {
      //message nls('Can not locate source code for %s.',file_name);
      return(1);
   }

   // try finding the item in locals or context, for current buffer
   _str found_class_name='';
   int status;
   int tag_linenum = -1;
   int tag_seekpos = -1;
   int tag_closest_linenum=MAXINT;
   int tag_closest_col= 1;
   int tag_closest_i = -1;
   case_sensitive := p_EmbeddedCaseSensitive;
   temp_view_id=0;
   if (_isEditorCtl() && file_eq(p_buf_name, file_name)) {
      // update the current context and locals
      _UpdateContext(true);
      _UpdateLocals(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // try to find the tag among the locals
      int i = tag_find_local_iterator(tag_name, true, case_sensitive);
      tag_closest_i= -1;
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, tag_linenum);
         if (abs(tag_linenum-line_no) < abs(tag_closest_linenum-line_no)) {
            tag_closest_linenum= tag_linenum;
            tag_closest_i=i;
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, tag_seekpos);
            tag_get_detail2(VS_TAGDETAIL_local_type, i, tag_type);
            tag_get_detail2(VS_TAGDETAIL_local_class, i, found_class_name);
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
               if (tag_closest_linenum==line_no) break;
            }
            i = tag_next_context_iterator(tag_name, i, true, case_sensitive);
         }
      }
      // found in locals or context
      if (tag_seekpos > 0) {
         boolean already_loaded=false;
         status=_open_temp_view(file_name,temp_view_id,orig_view_id,'',already_loaded,false,true);
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

   // try to create a temp view for the file
   boolean already_loaded=false;
   status=_open_temp_view(file_name,temp_view_id,orig_view_id,'',already_loaded,false,true);
   if (status) {
      return status;
   }

   // no tagging support for this file, then give up
   if (! _istagging_supported(p_LangId) ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return(1);
   }

   // check all tag files to see if this file is up to date
   // if it is, then just use the line number they gave us
   boolean tag_file_up_to_date=true;
   typeless tag_files=tags_filenamea();
   int i=0;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != '') {
      _str tagged_date='';
      status=tag_get_date(p_buf_name,tagged_date);
      if (status==0 && tagged_date!=p_file_date) {
         tag_file_up_to_date=false;
         break;
      }
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }
   if (tag_file_up_to_date) {
      p_RLine=line_no;
      return(0);
   }

   // the proc-search based code is faster if we have one
   PSindex := _FindLanguageCallbackIndex('%s-proc-search');
   if (PSindex) {
      // set up proc name to search for
      _str find_proc_name = tag_name;
      // First try searching from designated line number
      p_line=line_no; begin_line();
      _str orig_proc_name = find_proc_name;
      top();
      int ff=1;
      for (;;) {
         find_proc_name = orig_proc_name;
         status=call_index(find_proc_name,ff,p_LangId,PSindex);
         //say("_ExtractTagComments: "find_proc_name" status="status" buf="p_buf_name);
         //say('p_line='p_line' line_no='line_no);
         if (status) {
            break;
         }
         if (p_line==line_no) {
            _str type_name='';
            int tag_flags=0;
            tag_tree_decompose_tag(find_proc_name, tag_name, class_name, type_name, tag_flags);
            return 0;
         }
         ff=0;
      }

      // didn't find the tag, give up unless we have list-tags
      LTindex := _FindLanguageCallbackIndex('vs%s_list_tags');
      if (!LTindex) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         return status;  // non-zero
      }
      // giving up on proc-search, try context
      status=0;
   }

   // save the current context and then
   // parse the items in the temporary view
   _str orig_context_file='';
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // set up proc name to search for
   i = tag_find_context_iterator(tag_name, true, case_sensitive);
   tag_closest_i=-1;
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, tag_linenum);
      if (abs(tag_linenum-line_no) < abs(tag_closest_linenum-line_no)) {
         tag_closest_linenum= tag_linenum;
         tag_closest_i=i;
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, tag_closest_i, tag_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_type, tag_closest_i, tag_type);
         tag_get_detail2(VS_TAGDETAIL_context_class, tag_closest_i, class_name);
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
 * @param type_name    tag type (VS_TAGTYPE_*) to search for
 * @param class_name   class name to search for
 * @param indent_col   amount to indent each line of comment
 *
 * @return 0 on success, nonzero on error
 *         Results are returned in 'header_list', expect it may be empty.
 */
int _ExtractTagComments(_str (&header_list)[], int line_limit,
                        _str tag_name, _str file_name, int line_no,
                        _str type_name='', _str class_name='', int indent_col=0)
{
   //say("_ExtractTagComments: 1");
   header_list._makeempty();

   // try to find the tag
   _str tag_type='';
   int temp_view_id=0, orig_view_id=0;
   int status = _LocateTagForExtractingComment(tag_type, class_name,
                                               temp_view_id, orig_view_id,
                                               tag_name, file_name, line_no);
   // didn't find the tag, out of here
   if (status) {
      return status;
   }

   // get the tag header comments
   int first_line, last_line;
   status=_do_default_get_tag_header_comments(first_line,last_line);
   if (status) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return status;
   }

   // maybe check line limit
   if (line_limit>0 && last_line-first_line>line_limit) {
      last_line = first_line+line_limit;
   }

   // collect the lines of the header comment, into header_list
   p_line=first_line;
   int first_non_blank_col=0;
   while (p_line<=last_line) {
      first_non_blank('h');
      if (!first_non_blank_col) {
         first_non_blank_col=p_col;
      } else {
         if (p_col<first_non_blank_col) {
            first_non_blank_col=p_col;
         }
      }
      _str line=_expand_tabsc(first_non_blank_col,-1,'S');
      line=indent_string(indent_col):+strip(line,'T');
      header_list[header_list._length()]=line;
      if (down()) {
         break;
      }
   }

   // success!!!
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
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
 *
 * @return 0 on success, nonzero on error
 *         Results are returned in 'header_list', expect it may be empty.
 */
int _ExtractTagComments2(int &comment_flags,
                         _str &member_msg, int line_limit,
                         _str tag_name, _str file_name, int line_no
                         )
{
   //say("_ExtractTagComments2: 1");
   // try to find the tag
   _str tag_type='',class_name='';
   member_msg='';comment_flags=0;
   int temp_view_id=0, orig_view_id=0;

   if (p_LangId == 'docbook') {
      return _docbook_ExtractTagComments2(member_msg, tag_name, file_name, line_no);
   }

   int status = _LocateTagForExtractingComment(tag_type, class_name,
                                               temp_view_id, orig_view_id,
                                               tag_name, file_name, line_no);
   // didn't find the tag
   if (status) {
      return status;
   }

   // get the tag header comments
   _str line_prefix='';
   int blanks:[][];
   _str doxygen_comment_start='';
   _do_default_get_tag_comments(comment_flags,tag_type,member_msg,line_limit,true,line_prefix,blanks,doxygen_comment_start);
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   // if we didn't find anything, find and look up parent classes
   if (member_msg=='' && file_name!='') {
      typeless tag_files = tags_filenamea(p_LangId);
      int i,num_matches=0;
      tag_push_matches();
      struct VS_TAG_RETURN_TYPE visited:[];
      tag_list_in_class(tag_name,class_name,0,0,
                        tag_files,num_matches,def_tag_max_find_context_tags,
                        tag_type_to_filter(tag_type,0),
                        VS_TAGCONTEXT_ONLY_parents,
                        true,p_EmbeddedCaseSensitive,
                        null, null, visited);
      for (i=1; i<=num_matches; ++i) {
         _str dtf;
         _str parent_tag_name='';
         _str parent_type_name='';
         _str parent_file_name='';
         _str parent_class_name='';
         _str parent_signature='';
         _str parent_return='';
         int parent_line_no=0;
         int parent_tag_flags=0;
         tag_get_match(i,dtf,parent_tag_name,parent_type_name,parent_file_name,parent_line_no,
                       parent_class_name,parent_tag_flags,parent_signature,parent_return);
         status=_ExtractTagComments2(comment_flags,member_msg,line_limit,
                                     parent_tag_name,parent_file_name,parent_line_no);
         if (!status && member_msg!='') {
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
   text=stranslate(text,'&gt;',"\3");
   text=stranslate(text,'&amp;',"\2");
   text=stranslate(text,'&lt;',"\1");
}
static _str see_info2html(_str text)
{
   text=strip(text,'T',"\n");
   if (substr(text,1,1)=='"') {
      text=strip(text,'B','"');
   } else if (substr(text,1,1)=='<') { // URL
   } else if (substr(text,1,7)=='http://' || substr(text,1,4)=='www.') { // URL
      text='<a href="'text'">'text'</a>';
   } else if (substr(text,1,5)=='help:') {
      text='<a href="'text'">'substr(text,6)'</a>';
   } else { // package.class#member(int a,int b) label
      int j=lastpos(')',text);
      int open=lastpos('(',text);
      int k=pos(' ',text);
      _str label='';
      _str packageClassMember='';
      if (j && !(k && k<open)) {
         label=substr(text,j+2);
         packageClassMember=strip(substr(text,1,j));
      } else if (k) {
         label=substr(text,k+1);
         packageClassMember=strip(substr(text,1,k-1));
      } else {
         label="";
         packageClassMember=text;
      }
      // If we don't have label
      if (label=="") {
         label=packageClassMember;
         if (substr(label,1,1)=='#') {
            label=substr(label,2);
         } else {
            int i=pos('#',label);
            if (i) {
               label=substr(label,1,i-1):+'.':+substr(label,i+1);
            }
         }
      }
      text='<a href="'JAVADOCHREFINDICATOR:+packageClassMember'">'strip(label)'</a>';
   }
   return(text);
}
/*
   Doxygen comments are a super set of javadoc comments.  Unfortunately,
   interpreting javadoc comments as doxygen comments can reck the javadoc
   comments.  For this reason, we take a conservative approach.  By default,
   "/ **" are interpreted as javadoc comments.  Turn this option on, if you
   want "/ **" comments interpreted as doxygen comments.

   "/ *!" comments are always interpreted as doxygen comments.

*/
boolean def_doxygen_all = false;
/**
 * Parse the components out of a standard Javadoc comment.
 *
 * @param member_msg     comment to parse
 * @param description    set to description of javadoc comment
 * @param hashtab        hash table of javadoc tags -> messages
 * @param tagList        list of tags found in message
 */
void _parseJavadocComment(_str &member_msg,
                          _str &description,
                          _str (&hashtab):[][],
                          _str (&tagList)[],
                          boolean TranslateThrowsToException=true,
                          boolean isDoxygen=false, 
                          _str &tagStyle='@', 
                          boolean skipBrief=true)
{
   hashtab._makeempty();
   tagList._makeempty();
   boolean use_doxygen=isDoxygen;
   boolean set_tagstyle=false;

   if (use_doxygen) {
      // @Ding Zhaojie: support Doxygen tags
      member_msg=doxygen_filter(member_msg);
   }

   description=member_msg;
   int i;


   int brief_pos, iat, islash;
   brief_pos = 0;
#if 0
   if (use_doxygen) {
      // try to determine what delimiter is used for tags
      islash=pos('(^|\n)[ \t]*[\\]{[a-zA-Z0-9\-_]#}',member_msg,1,'r');
      iat=pos('(^|\n)[ \t]*[@]{[a-zA-Z0-9\-_]#}',member_msg,1,'r');
      if (islash == 0 || (iat < islash && iat != 0)) {
         use_doxygen = false;
      }
   }
#endif
   if (use_doxygen) {
      // maybe skip \brief if it is the first tag
      if (skipBrief) {
         brief_pos=pos('(^|\n)[ \t]*[\\@]{brief}',member_msg,1,'r');
         if (brief_pos) {
            brief_pos += pos('');
         }
      }
      if (brief_pos) {
         i=pos('(^|\n)[ \t]*[\\@]{[a-zA-Z0-9\-_]#}',member_msg,brief_pos,'r');
      } else {
         i=pos('(^|\n)[ \t]*[\\@]{[a-zA-Z0-9\-_]#}',member_msg,1,'r');
      }
   } else {
      i=pos('(^|\n)[ \t]*[\\@]{[a-zA-Z0-9\-_]#}',member_msg,1,'r');
   }
   // IF there is a javadoc tag
   if (i) {
      int s,n;
      s=pos('S0')-i+1;  // Start of @word match
      n=pos('0');   // length of @word match

      _str javadoc_comments= substr(member_msg,i);
      // Seems reasonable to do this for javadoc too.
      if (skipBrief) {
         description=doxygen_convert_two_newlines_to_paragraph(member_msg,brief_pos+1,i-brief_pos-1);
      } else {
         description=substr(member_msg,1,i-1);
      }
      //say('javadoc_comments='javadoc_comments);
      //say('description='description);
      i=1;

      for(;i;) {
         if (!set_tagstyle) {
            tagStyle=substr(javadoc_comments, s-1,1);
            set_tagstyle=true;
         }
         _str tag=substr(javadoc_comments, s,n);
         if (tag=='throws' && TranslateThrowsToException) {
            tag='exception';
         }
         int j;
         j=pos('(^|\n)[ \t]*[\\@]{[a-zA-Z0-9\-_]#}',javadoc_comments,s+n,'r');
         if (!j) {
            j=length(javadoc_comments)+1;
            i=0;
         } else {
            i=j;

         }
         _str text=strip(substr(javadoc_comments,s+n,j-(s+n)),'L');
         //say('tag='tag);
         //say('text='text);
         hashtab:[tag][hashtab:[tag]._length()]=text;
         tagList[tagList._length()]=tag;

         s=pos('S0');  // Start of @word match
         n=pos('0');   // length of @word match
      }
   } else if (brief_pos) {
      i=1;
      // Seems reasonable to do this for javadoc too.
      description=doxygen_convert_two_newlines_to_paragraph(member_msg,brief_pos+1,i-brief_pos-1);
   }
}
/* This translation is only need for Doxygen but it seems reasonable
   to do this for javadoc comments too.
*/
static _str doxygen_convert_two_newlines_to_paragraph(_str string,int start, int len)
{
   _str temp=substr(string,start,len);
   temp=stranslate(temp, "<p>\n", "\n\n", '');
   return temp;
}

/**
 * Process some doxygen tags.
 *
 * @author Ding Zhaojie (2008-6-18)
 *
 * @param[in] doc
 *
 * @return _str
 */
static _str doxygen_filter(_str doc)
{
#define DOXY_WORD   '{[!-.0-\?A-\~]#}'
#define DOXY_SPACE  '[ \t\n]#'

    _str res = doc;

    /*
        Removing leading <.
    */
    if (!pos(">", res)) {
       res = stranslate(res, '', '^<', 'R');
    }

    /*
        Add a <br> tag if two paragraphs are separated by a blank line.
        The second paragraph must not start with a tag.
    */
    res = stranslate(res,
                     '#0<br>\n<br>\n#1',
                     '{([~> \t][ \t]@)}\n([ \t]@\n)#{~([\@\\]([A-Za-z]:2,))}', 'R');

    // @code @endcode
    res = stranslate(res, '<pre>', '[\@\\]code', 'R');
    res = stranslate(res, '</pre>', '[\@\\]endcode', 'R');

    /*

       {@link abc#def}
       Translate doxygen style XXX#YYY links to links that can navigate.
       Doxygen also supports myclass.mymember and myclass::mymember without
       using a pound.  We could add that but there would need to be an option
       for it.

       Whatch for:
          @see #abc
          {@link abc#abc}

       Might need to support identifiers for more languages here.
       With generic identifier characters, can support navigating to different
       languages.  This supports Java and C++ identifiers.
    */
    _str atsee_re='(^|\n|[~\@\\])\@see[ \t]{#0}?*($|\n)';
    _str javadoc_link_re='\{\@link{#0}?*\}';
    _str signature_re='\(?*\)';
    _str doxygen_link_re1='(^|\n|[ \t])\#{#0[A-Za-z_$][A-Za-z0-9_$]@('signature_re'|)}';
    _str doxygen_link_re2='{#0([A-Za-z_$]([A-Za-z0-9_$.:]@[A-Za-z0-9_$:]|))\#([A-Za-z_$][A-Za-z0-9_$]@)('signature_re'|)}';
                  // Could try to exclude "#include" etc. but I don't think we need to.
                  // '{^|\n|[~\@\\]}\#~(include|define|if|else|endif){([A-Za-z_$][A-Za-z0-9_$]@)}', 'R');
    _str re='('atsee_re')|('javadoc_link_re')|('doxygen_link_re1')|('doxygen_link_re2')';

    int i=1;
    for (;;) {
       int j=pos(re,res,i,'r');
       if (!j) {
          break;
       }
       //say('len='pos('0'));
       //say('start='pos('S0'));
       //say('j='j);
       //say('j='substr(res,j));
       _str word=get_match_substr(res,0);
       if (word=='') {
          i=j+pos('');
          if (substr(res,i-1,1)=="\n") {
             /* Since '^' does not work after beginning of string, must do this.
                Handle
                   @see x
                   @see y
             */
             --i;
          }
          continue;
       }
       _str temp;
       if (j==1) {
          temp=substr(res,1,j-1):+'{@link 'word'}';
       } else {
          _str ch=substr(res,j,1);
          // Need to keep space,tab, or newline
          if (ch:==' ' || ch:=="\t" || ch:=="\n") {
             temp=substr(res,1,j):+'{@link 'word'}';
          } else {
             temp=substr(res,1,j-1):+'{@link 'word'}';
          }
       }
       i=length(temp);
       res=temp:+substr(res,j+pos(''));
    }

    /*
       Replace escaped characters with character.

       \@ --> @
       \% --> %

       @@ --> @
       @% --> %
    */
    res = stranslate(res, '#0', '[\@\\]{\#|\@|\&|\%|\<|\>|\~|\\}', 'R');

    // @a (arg)
    res = stranslate(res,
                     '<font color=darkred><i>#0</i></font>',
                     '[\@\\]a':+DOXY_SPACE:+DOXY_WORD, 'R');
    // @b (bold)
    res = stranslate(res,
                     '<b>#0</b>', '[\@\\]b':+DOXY_SPACE:+DOXY_WORD, 'R');
    // @c @p (monospace)
    res = stranslate(res,
                     '<font color=mediumblue><code>#0</code></font>',
                     '[\@\\](c|p)':+DOXY_SPACE:+DOXY_WORD, 'R');
    // @e @em (italic)
    res = stranslate(res,
                     '<i>#0</i>', '[\@\\]em:0,1':+DOXY_SPACE:+DOXY_WORD, 'R');

    /*
       Remove bogus format tags.  Since doxygen does this, we might as well
       do this too.
    */
    res = stranslate(res, '#0', '[\@\\](a|b|c|p|e|em){'DOXY_SPACE'}', 'R');

    // @n (newline)
    res=stranslate(res,'<br>','[\@\\]n( |\n|$)', 'R');
    return (res);
}
/**
 * Create a HTML comment from the comment extracted from source code.
 * If the comment is Javadoc, format it appropriately.
 *
 * @param member_msg     comment to parse
 * @param comment_flags  bitset of VSCODEHELP_COMMENTFLAG_*
 * @param return_type    expected return type for tag/variable
 * @param param_name     name of current parameter of function
 */
void _make_html_comments(_str &member_msg,int comment_flags,_str return_type,_str param_name='',boolean make_categories_links=false)
{
   // Special case VSAPI keyword
   _str temp=return_type;
   _str last_word=parse_last_file(temp);
   _str description='';
   typeless i;
   int count=0;
   if (last_word=='VSAPI' && temp!='') {
      return_type=temp;
   }
   if (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC) {
      member_msg=_xmldoc_xlat_to_html(member_msg,return_type,param_name);
      return;
   }
   if (!(comment_flags & VSCODEHELP_COMMENTFLAG_HTML)) {
      if (member_msg!="") {
         member_msg='<pre style=margin-top:0;margin-bottom:0><xmp style="margin-top:0;margin-bottom:0">'member_msg'</xmp></pre>';
      }
   }
   if (comment_flags & VSCODEHELP_COMMENTFLAG_JAVADOC) {


   /*


Author
         can have multiples,  if multiples join with comma delim.
deprecated
         Start DD tag with "Deprecated. " in bold.
         can only have one.  Is displayed in italics.
         deprecated should be displayed first.
exception class-name description
         section name "Throws:"
         a - is added between the class-name and the description.
         multiples are displayed in separate paragraphs with DD
         tag.
@param   argName description
         section name Parameters:
         a - is  added between the argName and the description.
         argName is displayed inside code tags.
         multiples are displayed in separate paragraphs with DD
         tag.
@return  section name "Returns:" can only have one.

@see "quoted-text"
@see <a href="URL#value">label</a>
@see  package.class#member  label

{@link  name  label}  Syntax same as @see tag

@since
         section name Since:
         Can only have one.
@serial
@serialData
@serialField  field-name  field-type  field-description

@example example usage
         <pre>
           code
         </pre>

   */
      _str hashtab:[][];
      _str tagList[];
      boolean isDoxygen=(comment_flags& VSCODEHELP_COMMENTFLAG_DOXYGEN)!=0;
      _parseJavadocComment(member_msg, description,hashtab,tagList,true,isDoxygen || def_doxygen_all);
      hashtab._nextel(i);
      /*
        ORDER


         deprecated,param,return,exception,since

         others

         Author

         see
      */
      member_msg='<DL>';
      member_msg='';
      // We use a slightly different ddstyle than
      // Javadoc because indenting on comment contuations
      _str ddstyle=' style="margin-left:13pt"';
      _str ddstyle_param=' style="margin-left:26pt;text-indent:-13pt"';
      _str pstyle=' style="margin-top:0pt;margin-bottom:0pt;" class="JavadocHeading"';
      _str blockstyle=' style="margin-top:0pt;margin-bottom:0pt;"';
      _str hanging_indent='-13pt';
      _str hanging_indent2='-26pt';
      _str startdescriptiontags='<P style="margin-top:0pt;margin-bottom:0pt;" class="JavadocDescription">';
      _str startheadertags='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="text-indent:'hanging_indent';margin-top:0pt;">';
      _str startheadertags4='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="text-indent:'hanging_indent2';margin-top:0pt;">';
      _str startheadertags2='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="margin-top:0pt;margin-left:'hanging_indent';">';
      _str startheadertags3='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="margin-top:0pt;margin-left:'hanging_indent';">';

      //startheadertags='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="text-indent:-13pt;margin-top:0pt;">';
      //startheadertags2='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="margin-top:0pt;">';
      //startheadertags3='<blockquote style="margin-top:0pt;margin-bottom:0pt;"><p style="margin-top:0pt;">';
      _str endheadertags='</blockquote>';
      _str tag="deprecated";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+"<P"pstyle"><B>Deprecated.</B>&nbsp;<I>":+hashtab:[tag][0]:+"</i>":+'<br>':+'<br>';
         hashtab._deleteel(tag);
      }
      _str dtstart='<P'pstyle'>';
      member_msg=member_msg:+startdescriptiontags:+description;
      tag="param";
      _str argName='';
      _str text='';
      _str argNameOnly='';
      _str inOut='';
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>Parameters:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            parse hashtab:[tag][i] with inOut argName text;
            if (inOut=="[in]" || inOut=="[out]" || inOut=="[in,out]") {
            } else {
               // MAR Not found, so undo
               text=argName:+" ":+text;
               argName=inOut;
               inOut='';
            }
            parse argName with argName '[ \n]','r';
            parse argName with argNameOnly '(' .;
            _str argAnchor;
            if (inOut=='') {
               argAnchor='<A NAME="'argNameOnly'">'argName'</A>';
            } else {
               // Put [in/out] in italics
               argAnchor='<A NAME="'argNameOnly'">'argName'<i>'inOut'</i></A>';
            }
            //say('argName='argName' inOut='inOut' text='text' argNameOnly='argNameOnly);
            if (param_name!='' && argNameOnly==param_name) {
               //_str arrowPtr="<img src=vslick://_execpt.ico>&nbsp;";
               _str arrowPtr="<img src=vslick://_arrowc.ico>&nbsp;";
               _str ddstyle_param2=' style="margin-left:26pt;text-indent:-26pt"';
               member_msg=member_msg:+startheadertags4:+arrowPtr:+"<code><b>":+argAnchor"</b></code> - ":+text:+endheadertags;
            } else {
               member_msg=member_msg:+startheadertags"<code>":+argAnchor:+"</code> - ":+text:+endheadertags;
            }
         }
         hashtab._deleteel(tag);
      }
      tag="return";
      if (hashtab._indexin(tag)) {
         if (return_type!='') {
            member_msg=member_msg:+dtstart"<B>Returns:</B> <B><code>"return_type"</code></b>"startheadertags2:+hashtab:[tag][0]:+endheadertags;
         } else {
            member_msg=member_msg:+dtstart"<B>Returns:</B>"startheadertags2:+hashtab:[tag][0]:+endheadertags;
         }
         hashtab._deleteel(tag);
      }
      tag="exception";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>Throws:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            parse hashtab:[tag][i] with argName text;
            parse argName with argName '[ \n]','r';
            member_msg=member_msg:+startheadertags:+'<code>'argName'<code>':+" - ":+text:+endheadertags;
         }
         hashtab._deleteel(tag);
      }
      tag="since";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>Since:</B>"startheadertags2:+hashtab:[tag][0]:+endheadertags;
         hashtab._deleteel(tag);
      }
      tag="serial";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>Serial:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            member_msg=member_msg:+startheadertags3:+hashtab:[tag][i]:+endheadertags;
         }
         hashtab._deleteel(tag);
      }
      tag="serialfield";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>SerialField:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            _str fieldName='';
            _str fieldType='';
            parse hashtab:[tag][i] with fieldName fieldType text;
            member_msg=member_msg:+startheadertags2:+fieldName' 'fieldType:+" - ":+text:+endheadertags;
         }
         hashtab._deleteel(tag);
      }
      tag="serialdata";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>SerialData:</B>";
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            member_msg=member_msg:+startheadertags2:+hashtab:[tag][i]:+endheadertags;
         }
         hashtab._deleteel(tag);
      }
      tag="author";
      if (hashtab._indexin(tag)) {
         member_msg=member_msg:+dtstart"<B>Author:</B>":+startheadertags2;
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            if (i==0) {
               member_msg=member_msg:+hashtab:[tag][i];
            } else {
               member_msg=member_msg:+", ":+hashtab:[tag][i];
            }
         }
         member_msg=member_msg:+endheadertags;
         hashtab._deleteel(tag);
      }
      tag="see";
      _str see_msg="";
      if (hashtab._indexin(tag)) {
         see_msg=see_msg:+dtstart"<B>See Also:</B>":+startheadertags2;
         count=hashtab:[tag]._length();
         for (i=0;i<count;++i) {
            text=strip(hashtab:[tag][i]);
            text=see_info2html(text);
            if (text!="") {
               if (i==0) {
                  see_msg=see_msg:+text;
               } else {
                  see_msg=see_msg:+', 'text;
               }
            }
         }
         see_msg=see_msg:+endheadertags;
         hashtab._deleteel(tag);
      }
      _str category_msg="";
      if (make_categories_links) {
         tag="categories";
         if (hashtab._indexin(tag)) {
            _str all_categories=hashtab:[tag][0];
            _str categories_array[];
            _str cur_category;
            count=0;
            while (all_categories:!='') {
               parse all_categories with cur_category ',' all_categories;
               categories_array[count]=strip(cur_category);
               ++count;
            }

            if (count>1) {
               category_msg=dtstart"<B>Categories:</B>":+startheadertags2;
            } else {
               category_msg=dtstart"<B>Category:</B>":+startheadertags2;
            }
            for (i=0;i<count;++i) {
               _str category=categories_array[i];
               category=stranslate(category,"",'[\r\n]','r');
               category='<a href="':+category:+'.html">':+stranslate(category,' ','_'):+'</a>';
               if (i==0) {
                  category_msg=category_msg:+category;
               } else {
                  category_msg=category_msg:+", ":+category;
               }
            }
            category_msg=category_msg:+endheadertags;
            hashtab._deleteel(tag);
         }
      }
      int j;
      for (j=0;j<tagList._length();++j) {
         tag=tagList[j];
         if (hashtab._indexin(tag)) {
            member_msg=member_msg:+dtstart"<B>"upcase(substr(tag,1,1)):+substr(tag,2)":</B>";
            count=hashtab:[tag]._length();
            for (i=0;i<count;++i) {
               member_msg=member_msg:+startheadertags2:+hashtab:[tag][i]:+endheadertags;
            }
            hashtab._deleteel(tag);
         }
      }
      /*for (tag._makeempty();;) {
          hashtab._nextel(tag);
          if (tag._isempty()) break;
          if (hashtab._indexin(tag)) {
             member_msg=member_msg:+"<DT><B>"upcase(substr(tag,1,1)):+substr(tag,2)":</B>";
             count=hashtab:[tag]._length();
             for (i=0;i<count;++i) {
                member_msg=member_msg:+"<dd"ddstyle">":+hashtab:[tag][i];
             }
          }
      } */
      member_msg=member_msg:+category_msg:+see_msg;
      for(j=1,i=1;i<200;++i) {
         j=pos('\{\@{(link|code|literal|linkplain)}[ \t\n]+{?*}\}',member_msg,j,'r');
         if (!j) {
            break;
         } 
         _str ident=substr(member_msg, pos('S0'), pos('0'));
         int match_len=pos('');
         _str body=substr(member_msg,pos('S1'),pos('1'));
         // link and linkplain should actually use different fonts
         if (ident == 'link' || ident == 'linkplain') {
            text=see_info2html(body);
         } else if (ident == 'code') {
            text='<code>':+body:+'</code>';
         } else if (ident == 'literal') {
            text='<pre>':+body:+'</pre>';
         }
         member_msg=substr(member_msg,1,j-1):+text:+substr(member_msg,j+match_len);
         j=j+length(text);
      }
   } else {
      // disabled, becuase the prototype has the return type and value now
#if 0
      if (return_type!='') {
         //strappend(member_msg,nls("Returns \1b%s1\1e",return_type));
         strappend(member_msg,nls("Returns <b>%s1</b>",return_type));
      }
#endif
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
   index := _FindLanguageCallbackIndex('_%s_get_decl',lang);
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
#define DEBUG_CAPTION "LPCTSTR lpszCaption = NULL,"
   if (max_font_flags== -1) {
      max_font_flags=0;
   }
   _str font_name='';
   typeless font_size=0;
   parse font_string with font_name','font_size',';
   _str prefix="";
   boolean word_wrap=false;
   if (pos(' ',sepchars)) {
      word_wrap=true;
      sepchars=stranslate(sepchars,'',' ');
   }
   sepchars=stranslate(sepchars,'',"\n");
   if (max_font_flags) {
      prefix=prefix:+_chr(1)'<_MAXFONTFLAGS flags='max_font_flags'>';
   }
   if (sepchars!="") {
      prefix=prefix:+_chr(1)'<_sepchars sepchars="'sepchars'">';
   }
   if (wrap_indent) {
      prefix=prefix:+_chr(1)'<_hangingindent width='wrap_indent't>';
   }
   if (prefix!="") {
      msg=prefix:+msg;
   }
   //say('start_y='start_y);
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
      if (sepchars:!='') {
         label_wid.p_word_wrap=true;
      }
   }
   //label_wid._font_flags2props(font_flags);
   label_wid.p_caption=msg;
   //messageNwait('label_wid.p_caption='label_wid.p_caption);
   label_wid.p_forecolor=fg;
   label_wid.p_backcolor=bg;
   label_wid.p_auto_size=true;

   if (max_font_flags) {
      width=start_x+label_wid.p_width;
      //say('width='_lx2dx(SM_TWIP,width));
      label_wid.p_auto_size=false;
      label_wid.p_width=max_width;
   } else {
      if (label_wid.p_width>max_width) {
         label_wid.p_auto_size=false;
         label_wid.p_width=max_width;
         if (sepchars:!='') {
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
   parse font_string with font_name','font_size','flags','charset;
   if (!isinteger(charset)) charset=-1;
   _str font_name_fixed='';
   typeless font_size_fixed;
   typeless flags_fixed;
   typeless charset_fixed;
   parse font_string_fixed with font_name_fixed','font_size_fixed','flags_fixed','charset_fixed;
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
      _minihtml_SetProportionalFontSize(3,font_size*10);
   }
   if (font_name_fixed!="") {
      _minihtml_SetFixedFont(font_name_fixed,charset_fixed);
   }
   if (isinteger(font_size_fixed)) {
      _minihtml_SetFixedFontSize(3,font_size_fixed*10);
      _minihtml_SetFixedFontSize(2,font_size_fixed*10);
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
   _str font_name='';
   typeless font_size=0;
   _codehelp_set_minihtml_fonts(font_string,font_string_fixed,
                                font_name,font_size);

   _str prefix="";
   /*if (pos(' ',sepchars)) {
      word_wrap=true;
      sepchars=stranslate(sepchars,'',' ');
   } */
   sepchars=stranslate(sepchars,'',"\n");
   if (max_font_flags) {
      prefix=prefix:+'<_MAXFONTFLAGS flags='max_font_flags'>';
   }
   if (sepchars!="") {
      prefix=prefix:+'<_sepchars sepchars="'sepchars'">';
   }
   if (sepchars!="") {
      double more_margin1=0; // Must do floating point math!!
      if (margin_text!="") {
         //margin_text="<img src=vslick://_arrowlt.ico><img src=vslick://_arrowgt.ico>";more_margin=0;
         //margin_text="WWWWiiiiiiiii";more_margin=0;
         p_PaddingX=0;
         p_PaddingY=0;
         //say('font_name='font_name);
         //p_text="<pre style=font-family:"font_name";font-size:">"margin_text;
         p_text='<pre style="font-family:'font_name';font-size:'font_size'pt">'margin_text"</pre>";
         //p_text=margin_text;
         p_width=max_width;
         _minihtml_ShrinkToFit();
         //p_active_form.p_visible=p_parent.p_visible=1;_message_box('got here');
         //say(_lx2dx(SM_TWIP,p_width));
         // 72 points per inch
         //say('n='p_font_name' size='p_font_size);
         //say('930/tx='930/_twips_per_pixel_x());
         double indent=_lx2dx(SM_TWIP,p_width);
         //p_font_name=VSDEFAULT_DIALOG_FONT_NAME;
         //indent=_lx2dx(SM_TWIP,_text_width(margin_text));
         //say('indent='indent' '_lx2dx(SM_TWIP,_text_width(margin_text)));
         //indent=9*2+_lx2dx(SM_TWIP,_text_width(" 1 of 2  "));more_margin=0;//say('h2 indent='indent);
         // Must do floating point math!!
         more_margin1= (indent*72)/_pixels_per_inch_x();
      }
      msg='<pre style="text-indent:-'(more_margin+more_margin1)'pt;margin-left:'(more_margin+more_margin1)'pt;margin-top:0;margin-bottom:0;font-family:'font_name';font-size:'font_size'pt">'prefix:+margin_text:+msg;
      //msg='<pre style="text-indent:-'(more_margin+more_margin1)'pt;margin-left:'(more_margin+more_margin1)'pt;margin-top:0;margin-bottom:0;">'prefix:+margin_text:+msg;
      //msg='<pre>'prefix:+margin_text:+msg;
   } else {
      if (prefix!="") {
         msg=prefix:+msg;
      }
   }
   int wid=p_window_id;
   p_word_wrap=false;
   //say('start_y='start_y);
   p_MouseActivate=MA_NOACTIVATE;
   p_width=max_width;
   p_height=max_height;
   p_PaddingX=start_x;
   p_PaddingY=start_y;
   //say('start_y='start_y' max_height='max_height' font='p_font_name' s='p_font_size);

   p_backcolor=bg;
   //messageNwait('h1');p_active_form.p_visible=1;p_visible=1;
   p_text=msg;
   //say(msg);
   //fsay(msg);
   //messageNwait('h2');
   //say('wh h1 'p_width' 'p_height' m='max_width' 'max_height);

   _minihtml_ShrinkToFit();
   //say('wh h2 'p_width' 'p_height);
}
//#if 0
defeventtab _function_help_form;
void ctlminihtml1.on_create(int editorctl_wid=0, int tree_wid=0)
{
   geditorctl_wid = editorctl_wid;
   p_active_form.p_MouseActivate=MA_NOACTIVATE;
   HYPERTEXTSTACK stack;
   stack.HyperTextTop= -1;stack.HyperTextMaxTop=stack.HyperTextTop;
   HYPERTEXTSTACKDATA=stack;
   ctlsizebar.p_user=_retrieve_value("_function_help_form.ctlsizebar.p_user");
   LISTHELPTREEWID = tree_wid;
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
                        _str filename='', int linenum=0,
                        _str curclassname='')
{
   // verify that this is a symbol link
   if (substr(hrefText,1,1) != JAVADOCHREFINDICATOR) {
      return STRING_NOT_FOUND_RC;
   }

   // open a temp view if the expected file does not match the current file
   int status=0;
   _str orig_context_file='';
   int temp_view_id=0, orig_view_id=0;
   if (filename!='' && !file_eq(filename,p_buf_name)) {
      tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_push_context();
      status=_open_temp_view(filename,temp_view_id,orig_view_id);
      if (!status) {
         p_RLine=linenum;
         _begin_line();
      }
   } else {
      filename=p_buf_name;
      linenum=p_RLine;
   }

   // get current mode / file extension
   _str lang=p_LangId;
   if (lang=='xmldoc') lang='cs';

   // grab up the critical information about current context
   _str cur_proc_name = '';
   _str cur_type_name = '';
   _str cur_class_name = '';
   _str cur_class_only = '';
   _str cur_package_name = '';
   int cur_tag_flags = 0;
   int cur_type_id = 0;
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   int context_id = tag_get_current_context(cur_proc_name,cur_tag_flags,
                                            cur_type_name,cur_type_id,
                                            cur_class_name,cur_class_only,
                                            cur_package_name);
   if (context_id > 0) {
      curclassname=cur_class_name;
   }

   // clean up the temp view and restore the current context information
   if (temp_view_id > 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
      _UpdateContext(true);
   }

   // Look up tags associated with this Href, result is in match set
   //
   // Known Limitations for C#
   //
   //    A.B     could find method B() of class A instead for class A.B
   //
   _str class_name='';
   _str method='';
   _str arguments='';
   _str rest='';
   boolean data_member_only=false;
   if (pos('#',hrefText)) {
      parse substr(hrefText,2) with class_name'#'method'('arguments')';
   } else {
      // For Java , if there is a paren, it may ONLY mean that its a constuctor.  For now, we treat this
      // the same as C# where we look for a method first.
      arguments='';
      parse substr(hrefText,2) with class_name'('rest;
      method='';
      int last_dot=lastpos('.',class_name);
      if (rest!='') {
         if (last_dot) {
            method=substr(class_name,last_dot+1);
            class_name=substr(class_name,1,last_dot-1);
            parse rest with arguments ')';
         } else {
            method=class_name;
            class_name='';
            parse rest with arguments ')';
         }
      } else if(_LanguageInheritsFrom('cs',lang)){
         data_member_only=true;
         // class name or data member case
         // Try data member first
          if(last_dot) {
             method=substr(class_name,last_dot+1);
             class_name=substr(class_name,1,last_dot-1);
          } else {
             method=class_name;
             class_name='';
          }

      }
   }

   typeless orig_values;
   int embedded_status = _EmbeddedStart(orig_values);
   lang=p_LangId;
   if (lang=='xmldoc') lang='cs';
   status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
   if (data_member_only) {
      int n=tag_get_num_of_matches();
      boolean hit_one=false;
      int i;
      for (i=0; i<n; ++i) {

         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i+1, cm);
         cm.language=lang;
         if (!(cm.flags & VS_TAGFLAG_const_destr)) {
            hit_one=true;
            break;
         }
      }
      if (!hit_one) {
         status=1;
      }
   }
   if (status) {
      if (!pos('#',hrefText)) {
         if (pos('(',hrefText) ) {
            // This could be a constructor.
            parse substr(hrefText,2) with class_name'('rest;
            status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
         } else if(_LanguageInheritsFrom('cs',lang)){
            // Already tried data member.  Now try class.
            parse substr(hrefText,2) with class_name'('rest;
            method='';
            status = _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,p_EmbeddedCaseSensitive);
         }
      }
   }

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
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
   int i=pos('://',webpage);
   _str word='';
   _str rest='';
   if (i) {
      word=substr(webpage,1,i-1);
      rest=substr(webpage,i+3);
   }
   _str type='';
   if (substr(webpage,1,9)=='helppath:') {
      webpage=get_env('VSROOT'):+'help':+FILESEP:+"misc":+FILESEP:+substr(webpage,10);
      type='f';
   } else if (substr(webpage,1,5)=='help:') {
      help(substr(webpage,6));
      return;
      /*_str url=h_match_pick_url(substr(i,6));
      if (url=='') {
         _message_box(nls('%s not found in help index',substr(i,6));
         return;
      }
      webpage=url;
      type='f';*/
   } else if (lowcase(word)=='file' ) {
      webpage=rest;
      type='f';
   } else if (word=='' &&
              (substr(webpage,2,1)==':' || substr(webpage,2,1)=='|')  &&
              (substr(webpage,3,1)=='\' || substr(webpage,3,1)=='/') &&
               substr(webpage,4,1)!='\' && substr(webpage,4,1)!='/'
              ) {
      type='f';
   } else if (word=='' &&
              (substr(webpage,1,1)=='\' || substr(webpage,1,1)=='/') &&
               substr(webpage,2,1)!='\' && substr(webpage,2,1)!='/'
              ) {
      type='f';
   } else {
      type='p';
   }
   if (type=='f') {
      webpage=translate(webpage,':','|');
   #if FILESEP=='\'
      webpage=translate(webpage,'\','/');
   #endif
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
    #name   in current doc

    filename#name

    category\x.html
*/
void ctlminihtml1.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      HYPERTEXTSTACK stack;
      stack=HYPERTEXTSTACKDATA;
      boolean doFunctionHelp=p_active_form==gFunctionHelp_form_wid;
      if (hrefText=='<<back') {
         if(stack.HyperTextTop>=0) {
            ctlminihtml2._minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         --stack.HyperTextTop;
         HYPERTEXTSTACKDATA=stack;
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid);
         ctlminihtml2._minihtml_SetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         return;
      } else if(hrefText=='<<forward') {
         if(stack.HyperTextTop>=0) {
            ctlminihtml2._minihtml_GetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         }
         ++stack.HyperTextTop;
         HYPERTEXTSTACKDATA=stack;
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid);
         ctlminihtml2._minihtml_SetScrollInfo(stack.s[stack.HyperTextTop].htmlCtlScrollInfo);
         return;
      }

      if (hrefText=='<<f') {
         nextFunctionHelp(-1, doFunctionHelp, p_active_form);
         return;
      } else if (hrefText=='>>f') {
         nextFunctionHelp(1, doFunctionHelp, p_active_form);
         return;
      } else if (hrefText=='<<pushtag') {
         gotoFunctionTag(doFunctionHelp, p_active_form, geditorctl_wid);
         return;
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
         HYPERTEXTSTACKDATA=stack;
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid);
         ctlminihtml2._minihtml_FindAName(substr(hrefText,3),VSMHFINDANAMEFLAG_CENTER_SCROLL);
        return;
      }

      stack=HYPERTEXTSTACKDATA;
      VSAUTOCODE_ARG_INFO (*plist)[];
      int TagIndex=0;
      //say('top='stack.HyperTextTop);
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

      _str filename='';
      int linenum=0;
      _str curclassname='';
      if (TagIndex<plist->_length() &&
          (*plist)[TagIndex].tagList!=null) {
         if ((*plist)[TagIndex].tagList._length()<1) {
            return;
         }
         // Use the first comment for this tag.  Don't worry if there are
         // multiple definitions of the exact same tag.
         filename=(*plist)[TagIndex].tagList[0].filename;
         linenum=(*plist)[TagIndex].tagList[0].linenum;
         curclassname=(*plist)[TagIndex].tagList[0].taginfo;
         _str dt;int df;
         tag_tree_decompose_tag(curclassname,dt,curclassname,dt,df);
      }

      // Look up tags associated with this Href, result is in match set
      if (substr(hrefText,1,1)==JAVADOCHREFINDICATOR) {

         int status = geditorctl_wid.tag_match_href_text(hrefText, filename, linenum, curclassname);
         if (status < 0) {
            _message_box(nls('Could not find help for "%s"',substr(hrefText,2)));
            return;
         }

         // for each match, put it into the array
         VSAUTOCODE_ARG_INFO list[]; list._makeempty();
         int i,n=tag_get_num_of_matches();
         //say("ctlminihtml1.on_change: n="n);
         for (i=0; i<n; ++i) {

            //say("ctlminihtml1.on_change: i="i);
            VS_TAG_BROWSE_INFO cm;
            tag_get_match_info(i+1, cm);
            cm.language=geditorctl_wid.p_LangId;

            _str prototype=geditorctl_wid.extension_get_decl(geditorctl_wid.p_LangId,cm,VSCODEHELPDCLFLAG_SHOW_CLASS);
            list[i].prototype=prototype;
            list[i].arglength._makeempty();
            list[i].argstart._makeempty();
            list[i].ParamNum=-1;
            list[i].ParamType="";
            list[i].ParamName="";
            list[i].tagList._makeempty();
            list[i].tagList[0].filename=cm.file_name;
            list[i].tagList[0].linenum=cm.line_no;
            list[i].tagList[0].taginfo=tag_tree_compose_tag(cm.member_name,cm.class_name,cm.type_name,cm.flags,cm.arguments,cm.return_type);
            list[i].tagList[0].comments=null;
            list[i].tagList[0].comment_flags=0;
         }

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
         stack.s[stack.HyperTextTop].TagIndex=0;
         stack.s[stack.HyperTextTop].TagList=list;
         HYPERTEXTSTACKDATA=stack;
         ShowCommentHelp(doFunctionHelp, false, p_active_form, geditorctl_wid);
      }
   }
}

void vscroll1.on_change()
{
   p_prev.p_y=- ((p_value-1)*(p_prev.p_height/p_max));
}
void vscroll1.on_scroll()
{
   p_prev.p_y=- ((p_value-1)*(p_prev.p_height/p_max));
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
   int selected_wid=p_window_id;

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
   int y=0;
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
            _append_retrieve(0, ctlsizebar.p_user, "_function_help_form.ctlsizebar.p_user");
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
   ctlpicture1.p_visible=0;
   ctlpicture1.p_backcolor=0;
   int fw = _dx2lx(SM_TWIP,ctlpicture1._frame_width());
   int fh = _dy2ly(SM_TWIP,ctlpicture1._frame_width());
   ctlminihtml1.p_x=fw;ctlminihtml1.p_y=fh;
   if (msg=="") {
      ctlminihtml1.p_width=0;
      ctlminihtml1.p_height=0;
      ctlminihtml1.p_visible=0;
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
      ctlminihtml1.p_visible=1;
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
      ctlpicture1.p_height=ctlminihtml2.p_y+ctlminihtml2.p_height+fh;
      ctlminihtml2.p_visible=1;
   } else {
      ctlsizebar.p_visible=0;
      ctlminihtml2.p_visible=0;
      ctlpicture1.p_height=ctlminihtml1.p_height+fh*2;
   }

   ctlpicture1.p_width=ctlminihtml1.p_width+fw*2;
   ctlsizebar.p_y=ctlpicture1.p_y+ctlpicture1.p_height;
   ctlsizebar.p_width=ctlpicture1.p_width;
   ctlsizebar.p_x=ctlpicture1.p_x;
   ctlpicture1.p_visible=1;
   ctlminihtml1.p_MouseActivate=MA_NOACTIVATE;
   //messageNwait('max_x='max_x' max_width='max_width);
   int form_height=ctlpicture1.p_height+p_active_form._top_height()+p_active_form._bottom_height();
   if (comments!='' && p_window_id==gFunctionHelp_form_wid) {
      form_height+=ctlsizebar.p_height;
   } else if (ctlsizebar.p_visible) {
      form_height+=ctlsizebar.p_height;
   }
   p_active_form.p_height=form_height;
   p_active_form.p_width=ctlpicture1.p_width+p_active_form._left_width()*2;
   //say('.p_x='ctlminihtml1.p_x);
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
void _EmbeddedCall(typeless pfn,typeless &arg1='',typeless &arg2='',typeless &arg3='')
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
   boolean orig_modify=p_modify;
   int orig_line=p_line;
   _end_line();
   _str orig_def_keys=def_keys;
   def_keys='';
   last_event(ENTER);
   _argument=1;  // Don't want new undo step
   call_index(eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER)));
   _argument='';
   def_keys=orig_def_keys;
   int indent_col=p_col;
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
                        _str &mlcomment_start, _str &mlcomment_end,boolean &supportJavadoc=false)
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(1);
   }
   status := 0;
   index := _FindLanguageCallbackIndex('_%s_get_comment_delimits');
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
   case 'pas':
   case 'mod':
      mlcomment_start = '(*';
      mlcomment_end   = '*)';
      slcomment_start = '';
      break;
   case 'ada':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = '--';
      break;
   case 'pl':
   case 'bourneshell':
   case 'csh':
   case 'tcl':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = '#';
      break;
   case 'bas':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = "'";
      break;
   case 'f':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = '!';
      break;
   case 's':
   case 'asm':
   case 'masm':
   case 'unixasm':
   case 'asm390':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = ';';
      break;
   case 'cob':
   case 'cob74':
   case 'cob2000':
      mlcomment_start = '';
      mlcomment_end   = '';
      slcomment_start = '      *';
      break;
   case 'awk':
      mlcomment_start = '/*';
      mlcomment_end   = '*/';
      slcomment_start = '#';
      break;
   case 'rul':
   case 'c':
   case 'js':
   //case 'phpscript':
   case 'idl':
   case 'java':
   case 'jsl':
   case 'cs':
   case 'e':
   case 'tagdoc':
   case 'as':
   case 'vera':
   case 'verilog':
   case 'systemverilog':
   case 'm':
      supportJavadoc=true;
      mlcomment_start = '/*';
      mlcomment_end   = '*/';
      slcomment_start = '//';
      break;
   case 'phpscript':
      mlcomment_start = '/*';
      mlcomment_end   = '*/';
      slcomment_start = '//';
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
#if 0
   boolean mergeExistingComment = false;
   _UpdateContext(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values,'');
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || !javadocSupported) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      _message_box('JavaDoc comment not supported for this file type');
      return(1);
   }
   save_pos(auto p);
   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   if (context_id <= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      _message_box('no current tag');
      return context_id;
   }

   // get the information about the current function
   _str tag_name = '';
   _str type_name = '';
   _str file_name = '';
   _str class_name = '';
   _str signature = '';
   _str return_type = '';
   int start_line_no = 0;
   int start_seekpos = 0;
   int scope_line_no = 0;
   int scope_seekpos = 0;
   int end_line_no = 0;
   int end_seekpos = 0;
   int tag_flags = 0;
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);

   // get the start column of the tag, align new comment here
   int i=0;
   _str local_param_names[];
   local_param_names._makeempty();
   if (tag_tree_type_is_func(type_name)) {
      _GoToROffset((scope_seekpos<end_seekpos)? scope_seekpos:start_seekpos);
      _UpdateLocals(true);

      for (i=1; i<=tag_get_num_of_locals(); i++) {
         _str param_name='';
         _str param_type='';
         int local_seekpos=0;
         tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
         tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
         if (param_type=='param' && local_seekpos>=start_seekpos) {
            tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
            local_param_names[local_param_names._length()] = param_name;
         }
      }
   }
   _GoToROffset(start_seekpos);
   int start_col = p_col;

   // hash table of original comments for incremental updates
   int comment_flags=0;
   _str orig_comment='';
   int first_line, last_line;
   if (!_do_default_get_tag_header_comments(first_line, last_line) && mergeExistingComment) {
      p_RLine=start_line_no;
      _GoToROffset(start_seekpos);
      _do_default_get_tag_comments(comment_flags,type_name, orig_comment, def_codehelp_max_comments*10, false);
   } else {
      //first_line = start_line_no;
      //last_line  = first_line-1;
      first_line = last_line = start_line_no-1;
   }

   // delete the original comment lines
   int num_lines = last_line-first_line+1;
   if (num_lines > 0) {
      p_line=first_line;
      for (i=0; i<num_lines; i++) {
         _delete_line();
      }
   } else {
      first_line=start_line_no;
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   // insert the comment start string and juggle slcomment if needed
   if (first_line>1) {
      p_line=first_line-1;
   } else {
      top();up();
   }
   if (mlcomment_start!='') {
      insert_line(indent_string(start_col-1):+mlcomment_start'*');
      slcomment_start='';
      if (pos('*',mlcomment_start)) {
         slcomment_start=' *';
      }
   }
   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';

   //DOB 03-19-06 Do not insert '*' if option not checked
   if (!_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK)) {
      prefix = translate(prefix, ' ', '*');
   }
   //DOB end of change

   // parse the parts out of the original comment
   _str orig_parts:[];
   orig_parts._makeempty();
   int first_param_pos=0;
   _str cmt = orig_comment;
   _str part_key = '';
   while (cmt!='') {
      _str one_line='';
      parse cmt with one_line "\n" cmt;
      if (substr(strip(one_line),1,1)=='@') {
         _str kw='';
         _str id='';
         parse one_line with "@" kw id .;
         if (lowcase(kw)=='param') {
            part_key='@param'id;
            orig_parts:[part_key] = one_line;
            if (!first_param_pos) {
               save_pos(first_param_pos);
            }
         } else if (lowcase(kw)=='return') {
            part_key='@return';
            orig_parts:[part_key] = one_line;
         } else {
            part_key='';
         }
      }
      // either append to the current key or re-insert line
      if (part_key!='') {
         if (substr(strip(one_line),1,1)!='@') {
            orig_parts:[part_key] = orig_parts:[part_key]"\n"one_line;
         }
      } else {
         insert_line(prefix:+one_line);
      }
   }

   // insert the original parts of the comment (description)
   typeless cursor_pos=null;
   if (orig_comment=='') {
      insert_line(prefix);
      save_pos(cursor_pos);
   }
   if (!first_param_pos) {
      save_pos(first_param_pos);
   }
   if (mlcomment_start!='') {
      insert_line(indent_string(start_col):+mlcomment_end);
   }

   // insert the parameter descriptions, recycle old ones
   if (first_param_pos>1) {
      restore_pos(first_param_pos);
   }
   // insert a blank line before the javadoc tags, if necessary
   _str last_inserted='';
   get_line(last_inserted);
   if (last_inserted!='' && last_inserted!='*') {
      insert_line(prefix);
   }

   for (i=0; i<local_param_names._length(); i++) {
      _str param_name=local_param_names[i];
      if (orig_parts._indexin('@param'param_name)) {
         cmt = orig_parts:['@param'param_name];
         orig_parts._deleteel('@param'param_name);
         while (cmt!='') {
            _str one_line='';
            parse cmt with one_line "\n" cmt;
            insert_line(prefix:+one_line);
         }
      } else {
         insert_line(prefix'@param 'param_name);
      }
   }

   boolean hit_param=false;
   typeless j;
   for (j._makeempty();;) {
       orig_parts._nextel(j);
       if (j._isempty()) break;
       if (substr(j,1,6)=='@param') {
          if (!hit_param) {
             insert_line(prefix'---start old parameters---');
             hit_param=1;
          }
          cmt = orig_parts:[j];
          while (cmt!='') {
             _str one_line='';
             parse cmt with one_line "\n" cmt;
             insert_line(prefix:+one_line);
          }
       }
   }
   if (hit_param) {
      insert_line(prefix'---end old parameters---');
   }

   // insert the return type description, recycle old one if present
   _str current_line='';
   if (orig_parts._indexin('@return') && orig_parts:['@return']!='') {
      get_line(current_line);
      if (current_line != '') {
         insert_line(prefix);
      }
      cmt = orig_parts:['@return'];
      while (cmt!='') {
         _str one_line='';
         parse cmt with one_line "\n" cmt;
         insert_line(prefix:+one_line);
      }
   } else if (return_type!='' && return_type!='void' && tag_tree_type_is_func(type_name)) {
      get_line(current_line);
      if (current_line != '') {
         insert_line(prefix);
      }
      insert_line(prefix'@return 'return_type);
   }
   if (cursor_pos!=null) {
      restore_pos(cursor_pos);
   }

   // restore the search and current position
   return(0);
#endif
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

   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   save_pos(auto p);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
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
   boolean javadocSupported=false;
   if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || !javadocSupported) {
      return(MF_GRAYED);
   }
   //status=(index_callable(find_index('_'p_LangId'_fcthelp_get_start',PROC_TYPE)) );
   int status=_EmbeddedCallbackAvailable('_%s_generate_function');
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
_command void javadoc_comment() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _EmbeddedCall(_javadoc_comment);
}

boolean is_javadoc_supported()
{
   _str junk1, junk2, junk3;
   boolean javadoc_enabled=false;
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
      return '';
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
   _str lang=p_LangId;
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
static int _Embeddedfcthelp_get_start(
                         _str (&errorArgs)[],
                         boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   _str lang = p_LangId;
   MaybeBuildTagFile(lang);
   if (_inJavadocSwitchToHTML()) {
      lang='html';
      MaybeBuildTagFile(lang);
   }
   errorArgs._makeempty();
   _UpdateContext(true);
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
   index := _FindLanguageCallbackIndex('_%s_fcthelp_get_start',lang);
   //gFunctionHelp_fcthelp_get=find_index('_'p_LangId'_fcthelp_get',PROC_TYPE);
   if (!index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      //_message_box('Auto function help not supported for this language');
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
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   errorArgs._makeempty();
   _UpdateContext(true);
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
   _str lang = p_LangId;
   if (_inJavadocSwitchToHTML()) lang='html';
   index := _FindLanguageCallbackIndex('_%s_fcthelp_get',lang);
   if (!index) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      //_message_box('Auto function help not supported for this language');
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
boolean is_valid_idexp(_str &lastid)
{
   _str ext='';

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   struct VS_TAG_RETURN_TYPE visited:[];
   int status=_Embeddedget_expression_info(false, ext, idexp_info, visited);
   lastid = idexp_info.lastid;

   return (status != 0 || lastid=='')? false:true;
}

int _doc_comment_get_expression_info(boolean PossibleOperator, 
                                     VS_TAG_IDEXP_INFO &idexp_info, 
                                     VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                     int depth=0)
{
   if (_chdebug) {
      //isay(depth, "_doc_comment_get_expression_info: possible_op="PossibleOperator" @"_QROffset()" ["p_line","p_col"]");
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
         status := _html_get_expression_info(PossibleOperator, idexp_info, visited, depth);
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
      status := _html_get_expression_info(PossibleOperator, idexp_info, visited, depth);
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
      status = _html_get_expression_info(PossibleOperator, idexp_info, visited, depth);
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
 * the extension-specific _[ext]_get_expression_info hook function.  Works in
 * embedded contexts.
 *
 * @param PossibleOperator         could this be an operator just typed?
 * @param ext                      set the [embedded] extension
 * @param idexp_info               information about the expression
 *
 * @return 0 on success, <0 on error, errorArgs has error arguments.
 * @since 11.0
 */
int _Embeddedget_expression_info(boolean PossibleOperator, _str &lang,
                                 VS_TAG_IDEXP_INFO &idexp_info,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_idexp_info_init(idexp_info);
   //_UpdateContext(true);
   /*
   Returns 2 to indicate that there is embedded language
   code, but in comment/in string like default processing
   should be performed.
   */
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(1);
   }
   if (!_istagging_supported(p_LangId) && upcase(substr(p_lexer_name,1,3))!='XML') {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      return(1);
   }

   status := 0;
   lang = p_LangId;
   if (idexp_info.info_flags & VSAUTOCODEINFO_DO_ACTION_MASK) {
      MaybeBuildTagFile(lang);
      if (_inDocComment()) {
         status = _doc_comment_get_expression_info(PossibleOperator, idexp_info, visited, depth);
         if (status == 0) {
            return status;
         }
      }
   }

   if (_chdebug) {

      fast_get_index := _FindLanguageCallbackIndex('vs%s_get_expression_info',lang);
      get_index := 0;
      if (fast_get_index == 0 || _chdebug) {
         get_index = _FindLanguageCallbackIndex('_%s_get_expression_info',lang);
      }
      if (!get_index && upcase(substr(p_lexer_name,1,3))=='XML') {
         get_index=find_index('_html_get_expression_info',PROC_TYPE);
         fast_get_index = 0;
      }

      if (fast_get_index != 0 && get_index != 0) {
         _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);

         orig_time := (long)_time('b');
         VS_TAG_IDEXP_INFO new_idexp_info;
         tag_idexp_info_init(new_idexp_info);
         new_status := call_index(PossibleOperator, 
                                  _QROffset(), 
                                  new_idexp_info, 
                                  fast_get_index);
         new_time := (long)_time('b');
         gnew_total_time += (new_time - orig_time);

         //_dump_var(new_idexp_info);

         // Call new version
         orig_time = (long)_time('b');
         status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
         new_time = (long)_time('b');
         gold_total_time += (new_time - orig_time);

         if (_chdebug) {
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
                  say("_Embeddedget_expression_info: ==================================");
                  say("   p_line="p_line" p_col="p_col" offset="_QROffset());
                  say("   LINE="line);
                  _dump_var(new_idexp_info, "   NEW: ");
                  _dump_var(idexp_info,     "   OLD: ");
                  gIDExprFailed = true;
                  say("_Embeddedget_expression_info: ==================================");
               } else {
                  //say("   ID EXPRESSION INFO MATCHES at "_QROffset());
               }
            } else if (new_status == 0 && status < 0 && 
                       ((_clex_find(0,'g')==CFG_COMMENT) ||
                        (new_idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)
                        )) {
               //say("   ID EXPRESSION INFO WORKS WHERE OLD VERSION FAILS at "_QROffset());
            } else if (new_status < 0 && status < 0) {
               //say("   ID EXPRESSION INFO FAIL MATCHES at "_QROffset());
            } else {
               say("_Embeddedget_expression_info: ==================================");
               get_line(auto line);
               say("   p_line="p_line" p_col="p_col" offset="_QROffset());
               say("   LINE="line);
               say("   NEW status="new_status);
               say("   OLD status="status);
               if (new_status == 0) _dump_var(new_idexp_info, "   NEW: ");
               if (status == 0)     _dump_var(idexp_info, "   OLD: ");
               gIDExprFailed = true;
               say("_Embeddedget_expression_info: ==================================");
            }
         }

      } else if(get_index != 0) {
         // Call new version
         status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
      } else {
         // Could not find new version, try old.
         get_index = _FindLanguageCallbackIndex('_%s_get_idexp',lang);

         if(get_index != 0) {
            // Call old version
            status=call_index(idexp_info.errorArgs, PossibleOperator, idexp_info.prefixexp, idexp_info.lastid,
                     idexp_info.lastidstart_col, idexp_info.lastidstart_offset,
                     idexp_info.info_flags, idexp_info.otherinfo, idexp_info.prefixexpstart_offset, get_index);
         } else {
            // Try default version
            status=_do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
         }
         return(status);
      }

   } else {

      do {
         // Try the faster version written in C code
         get_index := _FindLanguageCallbackIndex('vs%s_get_expression_info',lang);
         if (get_index != 0 && index_callable(get_index)) {
            _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
            status = call_index(PossibleOperator, _QROffset(), idexp_info, get_index);
            break;
         }

         // Look for a macro version
         get_index = _FindLanguageCallbackIndex('_%s_get_expression_info',lang);
         if (!get_index && upcase(substr(p_lexer_name,1,3))=='XML') {
            get_index=find_index('_html_get_expression_info',PROC_TYPE);
         }
         if (get_index != 0 && index_callable(get_index)) {
            status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
            break;
         }

         // Try the old, old macro version of this function
         get_index = _FindLanguageCallbackIndex('_%s_get_idexp',lang);
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
         status = _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);

      } while (false);
   }
//   say("   p_LangId="p_LangId);
//   say("   _Embeddedget_expression_info: PossibleOperator="PossibleOperator);
//   tag_idexp_info_dump(idexp_info,"_Embeddedget_expression_info");
//   say("   _Embeddedget_expression_info: get_expression_info_index="get_expression_info_index);
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
//   say("_Embeddedget_expression_info: status="status" prefixexp="prefixexp" start="get_index);
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
                       boolean PossibleOperator,
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
   int status = _Embeddedget_expression_info(PossibleOperator,ext,idexp_info,visited,depth);
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

static int _Embeddedanalyze_return_type(int ar_index,_str (&errorArgs)[],typeless tag_files,
                                        _str func_name, _str func_class,
                                        _str func_type, int func_flags, _str func_file,
                                        _str expected_type,struct VS_TAG_RETURN_TYPE &rt,
                                        VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   // select the embedded mode
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==2) {
      return(1);
   }
   // analyze the expected return type
   int status = call_index(errorArgs,tag_files,
                           func_name,func_class,func_type,
                           func_flags,func_file,expected_type,
                           rt,visited,ar_index);
   //say("_Embeddedanalyze_return_type: status="status);
   // drop out of embedded mode
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   // double check the status and return type
   if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
      return(status);
   }
   if (rt.return_type=='') {
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
 *
 * @return number of items inserted
 */
static int _list_matching_constants(struct VS_TAG_RETURN_TYPE &rt_expected,
                                    int ar_index,int rt_index, int fm_index,
                                    typeless tag_files,_str param_name,
                                    _str lastid_prefix, int tree_wid, int tree_index,
                                    int num_matches, int max_matches,
                                    boolean exact_match, boolean case_sensitive,
                                    struct VS_TAG_RETURN_TYPE (&visited):[])
{
   // blow out of here if return flags indicate that this is a reference
   if (rt_expected != null && rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_REF) {

      // special case for Slick-C pass by reference paramters
      // this should have been a callback, but this was quicker & simpler
      if (_LanguageInheritsFrom('e') && param_name != null && param_name != '') {
         // this does not need a synchronization guard since the call to
         // tag_find_local_iterator() stands alone.
         _UpdateLocals(true);
         if (tag_find_local_iterator(param_name, true, true) <= 0) {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"auto ":+param_name,"param","",0,"",0,rt_expected.return_type);
            return 1;
         }
      }

      return(0);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // find the insert constants callback
   cs_index := _FindLanguageCallbackIndex('_%s_insert_constants_of_type');
   if (!cs_index) {
      return(0);
   }
   int count=call_index(rt_expected,tree_wid,tree_index,
                        lastid_prefix,exact_match,case_sensitive,
                        cs_index);

   // special case for enumerated types
   _str inner_name='',outer_name='';
   tag_split_class_name(rt_expected.return_type,inner_name,outer_name);
   if (fm_index && tag_check_for_enum(inner_name,outer_name,tag_files,p_EmbeddedCaseSensitive)) {

      // find the members of the enumerated type
      tag_push_matches();
      _str prefixexp='';
      call_index(rt_expected,
                 outer_name,"enum",0,"",0,prefixexp,
                 tag_files,VS_TAGFILTER_ENUM,
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
                                        "", lastid_prefix,
                                        tag_files,
                                        tree_wid, tree_index,
                                        num_matches,max_matches,
                                        exact_match, case_sensitive,
                                        visited);
   }
   // return total number of items inserted
   return(count);
}
static int _analyze_return_type(struct VS_TAG_RETURN_TYPE &rt_candidate,
                                int ar_index,_str prefixexp,typeless tag_files,
                                _str tag_name,_str class_name,_str type_name,
                                int tag_flags,_str file_name,_str return_type,
                                struct VS_TAG_RETURN_TYPE (&visited):[])
{
   // check if this has been tried before
   int status=0;
   _str key='#;'/*prefixexp";"*/class_name';'type_name';'tag_flags';'file_name';'return_type;
   //say("_analyze_return_type: key="key);
   if (!visited._indexin(key)) {
      // analyze the candidate tag's return type
      _str errorArgs[];errorArgs._makeempty();
      tag_return_type_init(rt_candidate);
      status = call_index(errorArgs,tag_files,
                          tag_name,class_name,type_name,tag_flags,file_name,
                          return_type,rt_candidate,visited,
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
                                    _str prefixexp,_str lastid,
                                    typeless tag_files,
                                    int tree_wid, int tree_index,
                                    int &num_matches, int max_matches,
                                    boolean exact_match, boolean case_sensitive,
                                    struct VS_TAG_RETURN_TYPE (&visited):[])
{
   //say("_list_matching_arguments: ENTER");
   //int orig_time=(int)_time('b');
   // filter flags for searching
   filter_flags := VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ENUM|VS_TAGFILTER_DEFINE;

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

      // make sure that this is a prefix match for the current symbol
      if (!_CodeHelpDoesIdMatch(lastid, cm.member_name, exact_match, case_sensitive)) {
         continue;
      }

      // make sure that it is the right type of symbol also
      if (tag_filter_type(0,filter_flags,cm.type_name,cm.flags) &&
          !(cm.flags & VS_TAGFLAG_operator) &&
          !(cm.flags & VS_TAGFLAG_const_destr)) {

         // check if this has been tried before
         //int orig_time=(int)_time('b');
         tag_push_matches();
         struct VS_TAG_RETURN_TYPE rt_candidate;
         tag_return_type_init(rt_candidate);
         status := _analyze_return_type(rt_candidate,ar_index,
                                        prefixexp,tag_files,
                                        cm.member_name,cm.class_name,cm.type_name,
                                        cm.flags,cm.file_name,cm.return_type,
                                        visited);
         tag_pop_matches();

         // success, now match return types for this tag
         if (rt_candidate.return_type!='') {
            match_count+=call_index(rt_expected,rt_candidate,
                                    cm.member_name,cm.type_name,cm.flags,cm.file_name,cm.line_no,
                                    prefixexp,tag_files,tree_wid,tree_index,
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
                                  int tree_wid, int tree_index,
                                  int &num_matches, int max_matches,
                                  boolean exact_match, boolean case_sensitive,
                                  struct VS_TAG_RETURN_TYPE (&visited):[],
                                  boolean matchAnyObject=false)
{
   // filter flags for searching
   //say("_list_matching_members: here, prefix="prefixexp"=");
   filter_flags := VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYSTRUCT;

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
      if (tag_filter_type(0,filter_flags,cm.type_name,cm.flags) &&
          !(cm.flags & VS_TAGFLAG_operator)) {

         tag_push_matches();
         struct VS_TAG_RETURN_TYPE rt_candidate;
         int status=_analyze_return_type(rt_candidate,ar_index,
                                         prefixexp,tag_files,
                                         cm.member_name,cm.class_name,cm.type_name,
                                         cm.flags,cm.file_name,cm.return_type,
                                         visited);
         tag_pop_matches();

         // success, now match return types for this tag
         if (!status && rt_candidate.return_type!="" && rt_candidate.taginfo!="") {
            tag_tree_decompose_tag(rt_candidate.taginfo, auto rtc_name, auto rtc_class, auto rtc_type,  auto rtc_flags);
            if (tag_tree_type_is_class(rtc_type)) {
               count := 1;
               orig_prefixexp := prefixexp;
               if ( !matchAnyObject ) {
                  tag_push_matches();
                  call_index(rt_candidate,
                             cm.member_name,cm.type_name,cm.flags,cm.file_name,cm.line_no,
                             prefixexp,tag_files,filter_flags,visited,
                             fm_index);

                  // copy the current match set and then clear it
                  VS_TAG_BROWSE_INFO rt_matches[];
                  tag_get_all_matches(rt_matches);
                  tag_clear_matches();
                  tag_pop_matches();

                  count = _list_matching_arguments(rt_matches,
                                                   rt_expected,
                                                   ar_index,rt_index,
                                                   prefixexp, lastid_prefix,
                                                   tag_files,
                                                   0,0,//tree_wid,tree_index,
                                                   num_matches, max_matches,
                                                   exact_match, case_sensitive,
                                                   visited);
                  //say("_list_matching_members: tag_name="tag_name" count="count);
               } else {
                  prefixexp = cm.member_name;
                  cm.type_name = rtc_type;
               }

               match_count+=count;
               if (count>0 && prefixexp!='') {
                  if (cm.type_name=='proto' && (cm.flags & VS_TAGFLAG_maybe_var)) cm.type_name='var';
                  tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,prefixexp,cm.type_name,cm.file_name,cm.line_no,"",cm.flags,"",cm.file_name":"cm.line_no);
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
   //say("_Embeddedinsert_auto_params("prefixexp","lastid","lastid_prefix","otherinfo","expected_type")");
   // check for embedded mode
   typeless orig_values;
   int embedded_status=editorctl_wid._EmbeddedStart(orig_values);

   // find the functions to analyze and match return types
   ar_index := editorctl_wid._FindLanguageCallbackIndex('_%s_analyze_return_type');
   if (!ar_index) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }
   rt_index := editorctl_wid._FindLanguageCallbackIndex('_%s_match_return_type');
   if (!rt_index) {
      rt_index = find_index('_do_default_match_return_type',PROC_TYPE);
   }
   if (!index_callable(rt_index)) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }
   fm_index := editorctl_wid._FindLanguageCallbackIndex('_%s_find_members_of');
   if (fm_index && !index_callable(fm_index)) {  // fm_index is optional
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   // not supported in C++ constructor initializer lists (yet)
   if (info_flags & VSAUTOCODEINFO_IN_INITIALIZER_LIST) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      return(VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED);
   }

   //say("_Embeddedinsert_auto_params: past find_index");
   // analyze the expected return type
   _SetTimeout(def_tag_max_list_matches_time);
   editorctl_wid._UpdateContext(true);
   editorctl_wid._UpdateLocals(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   typeless tag_files=editorctl_wid.tags_filenamea(editorctl_wid.p_LangId);
   int status = 0;
   if (expected_type!='' && (rt==null || rt.return_type==null || rt.return_type != expected_type)) {
      //say("_Embeddedinsert_auto_params: expected type="expected_type);
      // get the function, class, and file location for the current function call
      _str func_name='';
      _str func_class='';
      _str func_file='';
      _str func_type='';
      int func_flags=0;
      if (ginFunctionHelp && !gFunctionHelp_pending) {
         int i=gFunctionHelpTagIndex;
         int n=gFunctionHelp_list._length();
         if (i>=0 && i<n) {
            _str func_info=gFunctionHelp_list[i].tagList[0].taginfo;
            tag_tree_decompose_tag(func_info,func_name,func_class,func_type,func_flags);
            func_file=gFunctionHelp_list[i].tagList[0].filename;
         }
         if (func_name=='') {
            if (embedded_status==1) {
               editorctl_wid._EmbeddedEnd(orig_values);
            }
            _SetTimeout(0);
            return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
         }
      }

      //say("_Embeddedinsert_auto_params: analyze");
      // analyze the given return type
      VS_TAG_RETURN_TYPE dummy_rt;
      tag_return_type_init(dummy_rt);
      rt=dummy_rt;
      status=editorctl_wid._Embeddedanalyze_return_type(ar_index,
                                                        errorArgs,
                                                        tag_files,
                                                        func_name,
                                                        func_class,
                                                        func_type,
                                                        func_flags,
                                                        func_file,
                                                        expected_type,
                                                        rt,
                                                        visited);
      //say("_Embeddedinsert_auto_params: expected="rt.return_type" pointers="rt.pointer_count);
      if (info_flags & VSAUTOCODEINFO_HAS_REF_OPERATOR) {
         //say("_Embeddedinsert_auto_params: REF OPERATOR, otherinfo="otherinfo"=");
         if (otherinfo == '*') {
            ++rt.pointer_count;
         } else if (otherinfo == '&') {
            --rt.pointer_count;
         }
      }
   }
   //say("_Embeddedinsert_auto_params: match_type="rt.return_type" expected_type="expected_type" status="status);
   if (_CheckTimeout()) status = TAGGING_TIMEOUT_RC;
   if (status) {
      if (embedded_status==1) {
         editorctl_wid._EmbeddedEnd(orig_values);
      }
      _SetTimeout(0);
      return(status);
   }

   // number of candidates looked at
   num_candidates := 0;

   // update the list of variables
   vars_count :=0;

   // first insert language-specific builtin constants
   if (prefixexp=='') {
      vars_count+=editorctl_wid._list_matching_constants(rt,
                                                         ar_index,
                                                         rt_index,
                                                         fm_index,
                                                         tag_files,
                                                         expected_name,
                                                         lastid_prefix,
                                                         tree_wid, 0,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited);
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
                                                     VS_TAGFILTER_ANYDATA|VS_TAGFILTER_DEFINE|VS_TAGFILTER_ENUM,
                                                     VS_TAGCONTEXT_ONLY_context|VS_TAGCONTEXT_ALLOW_locals,
                                                     visited);

   // copy the current match set and then clear it
   VS_TAG_BROWSE_INFO matches[];
   tag_get_all_matches(matches);
   tag_clear_matches();
   tag_pop_matches();

   //say("_Embeddedinsert_auto_params: find context tags, status="status);
   if (status >= 0) {
      // for each match, first match the return types
      vars_count+=editorctl_wid._list_matching_arguments(matches,
                                                         rt,
                                                         ar_index,rt_index,
                                                         prefixexp, lastid_prefix,
                                                         tag_files,
                                                         tree_wid, 0,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited);
   }
   if (status >= 0) {
      vars_count += editorctl_wid._list_matching_members(matches, rt,
                                                         ar_index,rt_index,fm_index,
                                                         prefixexp, lastid_prefix,
                                                         tag_files, 
                                                         tree_wid, 0,
                                                         num_candidates,
                                                         def_tag_max_list_matches_symbols,
                                                         false,
                                                         editorctl_wid.p_EmbeddedCaseSensitive,
                                                         visited, true);
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
                                                    ''/*lastid_prefix*/,
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
                                    VS_TAGFILTER_ANYTHING-VS_TAGFILTER_ANYDATA-VS_TAGFILTER_DEFINE-VS_TAGFILTER_ENUM,
                                    VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_context,
                                    visited);

      // copy the current match set and then clear it
      VS_TAG_BROWSE_INFO matches[];
      tag_get_all_matches(matches);
      tag_clear_matches();
      tag_pop_matches();

      //say("_Embeddedinsert_auto_params: num="num_candidates" count="tag_get_num_of_matches());
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
                                       VS_TAGFILTER_ANYDATA,
                                       VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_inclass|VS_TAGCONTEXT_NO_globals,
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
            //say("_Embeddedinsert_auto_params: matches="tag_get_num_of_matches());
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
   if (def_keys == 'vi-keys' && def_vim_esc_codehelp) {
      vi_escape();
   }
}
