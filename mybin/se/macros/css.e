////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49339 $
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
#import "adaptiveformatting.e"
#require "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "codehelp.e"
#import "context.e"
#import "cutil.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

#define CSS_LANG_ID    'css'
#define CSS_MODE_NAME  'CSS'
#define CSS_LEXERNAME  'CSS'
#define CSS_WORDCHARS  'A-Za-z0-9_'

defload()
{
   _str setup_info='MN='CSS_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='CSS_LANG_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='CSS_WORDCHARS',LN='CSS_LEXERNAME',CF=1,LNL=0,TL=0,BNDS=,CAPS=0,SW=0,SOW=0,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 0 3 0';
   _str be_info='';
   _CreateLanguage(CSS_LANG_ID, CSS_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("css", CSS_LANG_ID);

   LanguageSettings.setAutoBracket(CSS_LANG_ID, AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT);
}

_command void css_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(CSS_LANG_ID);
}

/**
 * @see ext_MaybeBuildTagFile
 */
int _css_MaybeBuildTagFile(int &tfindex)
{
   int status = ext_MaybeBuildTagFile(tfindex,'css','css','CSS Tags');
   return(status);
}

defeventtab css_keys;
def 'ENTER'=css_enter;
def 'TAB'=smarttab;
def ' '=css_space;
def '}'=css_endbrace;
def '{'=css_begin;

static int _css_indent_col(int syntax_indent)
{
   int col = 0;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   int status = search('[{};]', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      _str ch = get_text();
      switch (ch) {
      case '{':
         first_non_blank();
         col = p_col + syntax_indent;
         restore_pos(p);
         return(col);
      case '}':
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         status = _find_matching_paren(def_pmatch_max_diff, true);
         restore_search(s1, s2, s3, s4, s5);
         if (status) {
            restore_pos(p);
            return(0);
         }
         first_non_blank();
         col = p_col;
         restore_pos(p);
         return(col);
      case ';':
         restore_pos(p);
         return(0);
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

static boolean _css_split_brace_block(int syntax_indent)
{
   if (p_col > _text_colc(0,'E')) {
      return(false);
   }
   save_pos(auto p);
   search('[~ \t]|$','@rh');
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_COMMENT && cfg != CFG_STRING) {
      ch := get_text();
      if (ch == '}') {
         right();
         col := _css_indent_col(syntax_indent);
         restore_pos(p);
         if (col) {
            indent_on_enter(0, col);
            get_line(auto line);
            replace_line(indent_string(col-1):+strip(line));
            return(true);
         }
      }
   }
   restore_pos(p);
   return(false);
}

boolean _css_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   boolean line_splits = _will_split_insert_line();
   if (line_splits && _css_split_brace_block(syntax_indent)) {
      return(false);
   }
   if (name_on_key(ENTER):=='nosplit-insert-line') {
      _end_line();
   }
   int col = _css_indent_col(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void css_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_css_expand_enter);
}

static int _css_endbrace_col(int be_style)
{
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff, true);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   first_non_blank();
   int col = p_col;
   if (be_style == BES_BEGIN_END_STYLE_3) {
      col+=p_SyntaxIndent;
   }
   restore_pos(p);
   return(col);
}

_command void css_endbrace() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('}');
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      _str line="";
      get_line(line);
      if (line=='}') {
         int col=_css_endbrace_col(LanguageSettings.getBeginEndStyle(p_LangId));
         if (col) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

_command void css_begin() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      call_root_key('{');
      return;
   }
   int cfg = 0;
   if (p_col > 1) {
      left(); cfg = _clex_find(0, 'g'); right();
   }
   if (cfg == CFG_STRING || _in_comment()) {
      call_root_key('{');
      return;
   }

   keyin('{');
   save_pos(auto p);
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);
   if (expand && !find_matching_paren(true)) {
      expand = 0;
   }
   if (expand) {
      be_style := LanguageSettings.getBeginEndStyle(p_LangId);
      first_non_blank();
      col := p_col + ((be_style == BES_BEGIN_END_STYLE_3) ? p_SyntaxIndent : 0);
      if (col) {
         insert_line(indent_string(col - 1)'}');
         up();
      }
   }
   restore_pos(p);
}

int _css_delete_char(_str force_wrap='')
{
   cfg := _clex_find(0, 'g');
   if (cfg == CFG_STRING || cfg == CFG_COMMENT) {
      return STRING_NOT_FOUND_RC;
   }

   if (get_text() == '{') {
      // check if this is an empty brace block
      save_pos(auto p);
      right();
      status := search('[~ \t\r\n]','@hr');
      empty_braces := (!status && get_text() == '}');
      restore_pos(p);

      if (empty_braces) {
         // check if this brace has a matching brace somewhere
         orig_line := p_line;
         status = find_matching_paren(true);
         if (status) return status;

         sameLineCase := (orig_line==p_line);
         if (!sameLineCase) {
            first_non_blank();
         } 
         _delete_char();

         restore_pos(p);
         get_line(auto line);
         if (sameLineCase) {
            _delete_char();
            while (get_text():==" " || get_text():=="\t") {
               _delete_char();
            }

         } else if (line == '{') {
            _delete_line();
            first_non_blank();

         } else {
            _delete_char();
         }
         return 0;
      }
   }
   return STRING_NOT_FOUND_RC;
}

int _css_rubout_char(_str force_wrap='')
{
   if (p_col <= 1) {
      return STRING_NOT_FOUND_RC;
   }
   save_pos(auto p);
   left();
   status := _css_delete_char(force_wrap);
   if (status) restore_pos(p);
   return status;
}

int css_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

static void css_space_codehelp()
{
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      return;
   }

   // save the cursor position
   save_pos(auto p);
   orig_col := p_col;
   first_non_blank();
   if (p_col >= orig_col) {
      // in leading whitespace
      restore_pos(p);
      return;
   }

   restore_pos(p);
   left();
   if (_clex_skip_blanks('-')) {
      restore_pos(p);
      return;
   }

   cfg := _clex_find(0, 'g');
   if (cfg == CFG_COMMENT || cfg == CFG_STRING || cfg == CFG_KEYWORD) {
      restore_pos(p);
      return;
   }

   ch := get_text_safe();
   restore_pos(p);
   if (ch == ':') {
      _do_list_members(false, true);
   }
}

_command void css_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(' ');
      return;
   }
   keyin(' ');
   css_space_codehelp();
}

static int css_before_id(VS_TAG_IDEXP_INFO &idexp_info)
{
   status := 0;
   save_pos(auto p);
   ch := get_text();
   if (ch == ';' || ch == '}') {
      if (p_col == 1) {
         up(); _end_line();
      } else {
         left();
      }
   }

   paren_count := 0;
   bracket_count := 0;
   status = search('[@{};()\[\]]','-@rhxcs');
   if (!status) {
      done := false;
      while (!done) {
         ch = get_text();
         switch (ch) {
         case '}':
            status = 2;
            done = true;
            break;

         case '@':
         case '{':
         case ';':
            done = true;
            break;

         case ')':
            --paren_count;
            break;

         case '(':
            ++paren_count;
            if (paren_count > 0) {
               done = true;
            }
            break;

         case ']':
            --bracket_count;
            break;

         case '[':
            ++bracket_count;
            if (bracket_count > 0) {
               done = true;
            }
            break;
         }

         if (done) {
            break;
         }

         status = repeat_search();
         if (status) {
            break;
         }
      }

      if (bracket_count || paren_count) {
         status = 2;
      }

      if (!status) {
         right(); _clex_skip_blanks();
         offset := (int)point('s');
         if (offset < idexp_info.lastidstart_offset) {
            word_chars := _clex_identifier_chars();
            ch = get_text();
            if (pos('[~'word_chars']', ch, 1, 'r')) {
               status = 2;

            } else {
               prefix_offset := offset;
               prefix_col := p_col;
               search('[~'word_chars']|$','rh@');
               prefixexp := _expand_tabsc(prefix_col, p_col - prefix_col);

               _clex_skip_blanks(); ch = get_text();
               offset = (int)point('s');
               if (offset < idexp_info.lastidstart_offset) {
                  if (ch == ':') {
                     idexp_info.prefixexp = prefixexp;
                     idexp_info.prefixexpstart_offset = prefix_offset;
                  }
               }
            }
         }
      }

      restore_pos(p);
   }
   return status;
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _css_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   boolean done = false;
   int status = 0;
   idexp_info.info_flags = VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);

   } else {
      // check color coding to see that we are not in a comment
      int cfg = _clex_find(0,'g');
      if (cfg == CFG_COMMENT || cfg == CFG_STRING || cfg == CFG_NUMBER) {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         int first_col = 1;
         if (p_col > 1) {
            first_col = 0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            idexp_info.lastid = "";
            idexp_info.lastidstart_col = p_col-first_col;
            idexp_info.lastidstart_offset = (int)point('s');
            done = 1;
         }
      } 

      if (!done) {
         int old_TruncateLength = p_TruncateLength; p_TruncateLength = 0;
         _TruncSearchLine('[~'word_chars']|$','r');
         int end_col = p_col;
         _TruncSearchLine('[~ \t]|$','r');
         p_col = end_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid = _expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col = p_col;
         idexp_info.lastidstart_offset = (int)point('s');
         p_TruncateLength = old_TruncateLength;

         if (p_col > 1) {
            left();
            switch (get_text()) {
            case '@':
            case '#':
            case '.':
            case '(':
            case '[':
               status = 2;
               break;
            }
         }
      }

      if (!status) {
         status = css_before_id(idexp_info);
      }

      if (status) {
         idexp_info.info_flags = 0;
         idexp_info.lastid = "";
      }
   }

   restore_pos(orig_pos);
   return(status);
}

/**
 * Find a list of tags matching the given identifier after
 * evaluating the prefix expression.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_
 * @param prefixexp          prefix of expression (from _[ext]_get_expression_info
 * @param lastid             last identifier in expression
 * @param lastidstart_offset seek position of last identifier
 * @param info_flags         bitset of VS_CODEHELPFLAG_*
 * @param otherinfo          used in some cases for extra information
 *                           tied to info_flags
 * @param find_parents       for a virtual class function, list all
 *                           overloads of this function
 * @param max_matches        maximum number of matches to locate
 * @param exact_match        if true, do an exact match, otherwise
 *                           perform a prefix match on lastid
 * @param case_sensitive     if true, do case sensitive name comparisons
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return
 *   The number of matches found or <0 on error (one of VSCODEHELPRC_*,
 *   errorArgs must be set).
 */
int _css_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           boolean find_parents,int max_matches,
                           boolean exact_match,boolean case_sensitive,
                           int filter_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      say("_css_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   }
   errorArgs._makeempty();
   lang := p_LangId;

   int num_matches = 0;
   typeless tag_files = tags_filenamea("css");
   if (!tag_files._length()) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }
   if (lastid != '' && prefixexp == '') {
      tag_list_context_globals(0, 0, lastid,
                               false, tag_files,
                               VS_TAGFILTER_MISCELLANEOUS,
                               VS_TAGCONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);

   } else {
      tag_list_in_class(lastid, prefixexp,
                        0, 0, tag_files,
                        num_matches, max_matches,
                        VS_TAGFILTER_ENUM, VS_TAGCONTEXT_ONLY_inclass,
                        exact_match, case_sensitive,
                        null, null, visited, depth);
   }

   if (_chdebug) {
      isay(depth,"_css_find_context_tags: num_matches="num_matches);
      int i,n = tag_get_num_of_matches();
      for (i=1; i<=n; ++i) {
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i, cm);
         tag_browse_info_dump(cm, "_css_find_context_tags", 1);
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * Format the given tag for display. Delegates to _c_get_decl
 * for tag types that are not tags. 
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
 *
 * @see _c_get_decl
 */
_str _css_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   _str tag_name=info.member_name;
   // say("_css_get_decl: type_name="info.type_name);
   switch (info.type_name) {
   case 'tag':
      return decl_indent_string:+tag_name;

   default:
      break;
   }
   // delegate to C version for anything not CSS specific
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

