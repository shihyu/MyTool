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
#import "se/lang/api/LanguageSettings.e"
#import "se/ui/AutoBracketMarker.e"
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
#import "cfg.e"
#endregion

using se.lang.api.LanguageSettings;
using se.ui.AutoBracketMarker;

static const CSS_LANG_ID=    "css";

_command void css_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(CSS_LANG_ID);
}

_command void less_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('less');
}

/**
 * @see ext_MaybeBuildTagFile
 */
int _css_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   int status = ext_MaybeBuildTagFile(tfindex,"css","css","CSS Tags", "", false, withRefs, useThread, forceRebuild);
   return(status);
}

int _less_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   int status = ext_MaybeBuildTagFile(tfindex,"less","css","Less Tags", "", false, withRefs, useThread, forceRebuild);
   return(status);
}

static int _css_indent_col(int syntax_indent)
{
   col := 0;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   int status = search('[{};]', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      ch := get_text();
      switch (ch) {
      case '{':
         _first_non_blank();
         col = p_col + syntax_indent;
         restore_pos(p);
         return(col);
      case '}':
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
         restore_search(s1, s2, s3, s4, s5);
         if (status) {
            restore_pos(p);
            return(0);
         }
         _first_non_blank();
         col = p_col;
         restore_pos(p);
         return(col);
      case ";":
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

static bool _css_split_brace_block(int syntax_indent)
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

bool _css_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   line_splits := _will_split_insert_line();
   if (line_splits && _css_split_brace_block(syntax_indent)) {
      return(false);
   }
   if (name_on_key(ENTER):=="nosplit-insert-line") {
      _end_line();
   }
   int col = _css_indent_col(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void css_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_css_expand_enter);
}
bool _css_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _less_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

static int _css_endbrace_col(int be_style)
{
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff_ksize, true);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   _first_non_blank();
   col := p_col;
   if (be_style == BES_BEGIN_END_STYLE_3) {
      col+=p_SyntaxIndent;
   }
   restore_pos(p);
   return(col);
}

_command void css_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin("}");
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=="") {
      line := "";
      get_line(line);
      if (line=="}") {
         int col=_css_endbrace_col(LanguageSettings.getBeginEndStyle(p_LangId));
         if (col) {
            replace_line(indent_string(col-1):+"}");
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

_command void css_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      call_root_key("{");
      return;
   }
   cfg := 0;
   prev_ch := "";
   if (p_col > 1) {
      left(); prev_ch=get_text(); cfg = _clex_find(0, 'g'); right();
   }
   if (cfg == CFG_STRING || _in_comment() || prev_ch=='@') {
      call_root_key("{");
      return;
   }

   keyin("{");
   save_pos(auto p);
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);
   if (expand && !find_matching_paren(true)) {
      expand = false;
   }
   if (expand) {
      be_style := LanguageSettings.getBeginEndStyle(p_LangId);
      _first_non_blank();
      col := p_col + ((be_style == BES_BEGIN_END_STYLE_3) ? p_SyntaxIndent : 0);
      if (col) {
         insert_line(indent_string(col - 1)"}");
         up();
      }
   }
   restore_pos(p);
}

int _css_delete_char(_str force_wrap="")
{
   cfg := _clex_find(0, 'g');
   if (cfg == CFG_STRING || cfg == CFG_COMMENT) {
      return STRING_NOT_FOUND_RC;
   }

   if (get_text() == "{") {
      // check if this is an empty brace block
      save_pos(auto p);
      right();
      status := search('[~ \t\r\n]','@hr');
      empty_braces := (!status && get_text() == "}");
      restore_pos(p);

      if (empty_braces) {
         // check if this brace has a matching brace somewhere
         orig_line := p_line;
         status = find_matching_paren(true);
         if (status) return status;

         sameLineCase := (orig_line==p_line);
         if (!sameLineCase) {
            _first_non_blank();
         } 
         _delete_char();

         restore_pos(p);
         get_line(auto line);
         if (sameLineCase) {
            _delete_char();
            while (get_text():==" " || get_text():=="\t") {
               _delete_char();
            }

         } else if (line == "{") {
            _delete_line();
            _first_non_blank();

         } else {
            _delete_char();
         }
         return 0;
      }
   }
   return STRING_NOT_FOUND_RC;
}

int _css_rubout_char(_str force_wrap="")
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

int css_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

int less_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

static void css_space_codehelp()
{
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      return;
   }

   // save the cursor position
   save_pos(auto p);
   orig_col := p_col;
   _first_non_blank();
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
   if (ch == ":" && _haveContextTagging()) {
      _do_list_members(OperatorTyped:false, DisplayImmediate:true);
   }
}

_command void css_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 || _in_comment() ||
        ext_expand_space()) {
      call_root_key(" ");
      return;
   }
   keyin(" ");
   css_space_codehelp();
}
static int gexpr_info_cfg;
static _str gexpr_info_clip_prefix;
/*
   Return 0 if want to list properties
   return 1 if want to list lib keywords
   return 2 if want to list elements

*/
static int css_before_id(VS_TAG_IDEXP_INFO &idexp_info)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (p_line==0) {
      return 0;
   }
   /*idexp_info.prefixexp = 'background-color';
   idexp_info.prefixexpstart_offset = 5;
   return 0;*/
   //int modify_flags=p_ModifyFlags;
   save_pos(auto p);
   orig_lastModified := p_LastModified;
   orig_modifyflags  := p_ModifyFlags;
   orig_modify       := p_modify;
   orig_line_modify := _lineflags();
   _CallbackBufSuspendAll(p_buf_id,1);
   orig_undo_steps := _SuspendUndo(p_window_id);
   get_line(auto line);
   p_col=idexp_info.lastidstart_col;
   _str text;
   int cfg;
   col:=p_col;

   text=" all ";
   _insert_text(text);
   p_col=col+1;
   cfg=_clex_find(0,'d');
   replace_line(line);
   p_ModifyFlags    = orig_modifyflags;
   p_LastModified   = orig_lastModified;
   if (isEclipsePlugin()) {
      _eclipse_set_dirty(p_window_id, orig_modify);
   }
   _lineflags(orig_line_modify,MODIFY_LF);
   if (cfg:==CFG_CSS_PROPERTY) {
      gexpr_info_cfg=cfg;
      restore_pos(p);//p_ModifyFlags=modify_flags;
      _CallbackBufSuspendAll(p_buf_id,0);
      _ResumeUndo(p_window_id,orig_undo_steps);
      return 0;
   }
   p_col=col;
   text=" red ";
   _insert_text(text);
   p_col=col+1;
   cfg=_clex_find(0,"d");
   replace_line(line);
   p_ModifyFlags    = orig_modifyflags;
   p_LastModified   = orig_lastModified;
   if (isEclipsePlugin()) {
      _eclipse_set_dirty(p_window_id, orig_modify);
   }
   _lineflags(orig_line_modify,MODIFY_LF);

   if (cfg:==CFG_LIBRARY_SYMBOL) {
      // Need to determine property so can fetch class members
      gexpr_info_cfg=cfg;
      status:=search(':','@-hxcs');
      if (status) {
         restore_pos(p);//p_ModifyFlags=modify_flags;
         _CallbackBufSuspendAll(p_buf_id,0);
         _ResumeUndo(p_window_id,orig_undo_steps);
         return 1;
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks('-');

      if (!status) {
         word_chars := _clex_identifier_chars();
         ch := get_text();
         if (pos('[~'word_chars']', ch, 1, 'r')) {
            restore_pos(p);//p_ModifyFlags=modify_flags;
            _CallbackBufSuspendAll(p_buf_id,0);
            _ResumeUndo(p_window_id,orig_undo_steps);
            return 1;
         } 
         last_char_col := p_col;
         search('[~'word_chars']|^','-rh@');
         if (match_length()) {
            right();
         }
         prefixexp := _expand_tabsc(p_col, last_char_col - p_col+1);
         idexp_info.prefixexp = prefixexp;
         idexp_info.prefixexpstart_offset = p_col;
      }
      restore_pos(p);//p_ModifyFlags=modify_flags;
      _CallbackBufSuspendAll(p_buf_id,0);
      _ResumeUndo(p_window_id,orig_undo_steps);
      return 0;
   }
   gexpr_info_clip_prefix="";
   p_col=col;
   if (col>1) {
      left();
      ch:=get_text(1);
      if (ch==":") {
         gexpr_info_clip_prefix=ch;
         if (col>2) {
            left();
            ch=get_text(1);
            if (ch==":") {
               gexpr_info_clip_prefix="::";
            }
            right();
         }
      } else if (ch=="@") {
         gexpr_info_clip_prefix=ch;
      }
      idexp_info.lastid=gexpr_info_clip_prefix:+idexp_info.lastid;
      idexp_info.lastidstart_col-=length(gexpr_info_clip_prefix);
      right();
   }
   text=" p ";
   _insert_text(text);
   p_col=col+1;
   cfg=_clex_find(0,'d');
   replace_line(line);
   p_ModifyFlags    = orig_modifyflags;
   p_LastModified   = orig_lastModified;
   if (isEclipsePlugin()) {
      _eclipse_set_dirty(p_window_id, orig_modify);
   }
   _lineflags(orig_line_modify,MODIFY_LF);
   if (cfg:==CFG_CSS_ELEMENT) {
      gexpr_info_cfg=cfg;
      restore_pos(p);//p_ModifyFlags=modify_flags;
      _CallbackBufSuspendAll(p_buf_id,0);
      _ResumeUndo(p_window_id,orig_undo_steps);
      return 0;
   }
   restore_pos(p);//p_ModifyFlags=modify_flags;
   _CallbackBufSuspendAll(p_buf_id,0);
   _ResumeUndo(p_window_id,orig_undo_steps);
   return 1;
}
int _less_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0) {

   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   done := false;
   status := 0;
   idexp_info.info_flags = VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   } else {
      // check color coding to see that we are not in a comment
      int cfg = _clex_find(0,'g');
      if (cfg == CFG_COMMENT /*|| cfg == CFG_STRING || cfg == CFG_NUMBER */) {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      // IF we are not on an id character.
      /*if (pos('[~'word_chars']',get_text(),1,'r')) {
         first_col := 1;
         if (p_col > 1) {
            first_col = 0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            idexp_info.lastid = "";
            idexp_info.lastidstart_col = p_col-first_col;
            idexp_info.lastidstart_offset = (int)point('s');
            done = true;
         }
      } */
      if (!done) {
         int old_TruncateLength = p_TruncateLength; p_TruncateLength = 0;
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col := p_col;
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
            if (cfg==CFG_NUMBER && get_text()!='#') {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            switch (get_text()) {
            case "(":
               //pre_ch_is_open_paren=true;
               break;
            case '@':
            case '#':
            case '.':
               if (cfg==CFG_STRING) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               // List Less variables or selectors
               idexp_info.prefixexp=get_text();
               restore_pos(orig_pos);
               return 0;
            case "{":
               if (p_col>1) {
                  left();
                  if (get_text()=='@') {
                     idexp_info.prefixexp=get_text();
                     restore_pos(orig_pos);
                     return 0;
                  }
               }
            }
         }
         if (cfg==CFG_NUMBER) {
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
      }
   }

   restore_pos(orig_pos);
   return _css_get_expression_info(PossibleOperator,idexp_info,visited,depth+1);
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
int _css_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   done := false;
   status := 0;
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
         first_col := 1;
         if (p_col > 1) {
            first_col = 0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            idexp_info.lastid = "";
            idexp_info.lastidstart_col = p_col-first_col;
            idexp_info.lastidstart_offset = (int)point('s');
            done = true;
         }
      } 
      pre_ch_is_open_paren := false;

      if (!done) {
         int old_TruncateLength = p_TruncateLength; p_TruncateLength = 0;
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col := p_col;
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
            case "(":
               pre_ch_is_open_paren=true;
               break;
            //case '@':
            case "#":
            case ".":
            case "[":
               status = 2;
               break;
            }
         }
      }

      if (!status) {
         status = css_before_id(idexp_info);
         if (pre_ch_is_open_paren && gexpr_info_cfg!=CFG_CSS_PROPERTY) {
            status=2;
         }
      }

      if (status) {
         idexp_info.info_flags = 0;
         idexp_info.lastid = "";
      }
   }

   restore_pos(orig_pos);
   return(status);
}


static void _css_insert_context_tag_item(_str cur, _str lastid,
                                         _str clip_prefix,
                                         int start_or_end, 
                                         int &num_matches, int max_matches,
                                         bool exact_match=false,
                                         bool case_sensitive=false,
                                         _str tag_file="",
                                         SETagType tag_type=SE_TAG_TYPE_TAG,
                                         VS_TAG_BROWSE_INFO *pargs=null
                                         )
{
//   say("_html_insert_context_tag_item");
   tag_init_tag_browse_info(auto cm);
   if (pargs!=null) {
      cm = *pargs;
   }

   if (clip_prefix!="") {
      if (substr(cur,1,length(clip_prefix)):!=clip_prefix) {
         return;
      }

   } else {
      ch:=substr(cur,1,1);
      if (ch=="@" || ch==":") {
         return;
      }
   }
   tag_get_type(tag_type,auto type_name);

   cm.tag_database = tag_file;
   cm.member_name = cur;
   cm.type_name = type_name;
   tag_insert_match_browse_info(cm);
   ++num_matches;
}

int _CSSListKeywords(_str keyword_class, 
                             _str keyword_name,
                             _str lastid,
                             _str clip_prefix, 
                             int start_or_end, 
                             int &num_matches,
                             int max_matches,
                             bool exact_match,
                             bool case_sensitive)
{
   //say("_CSSListKeywords("lastid","lastid_prefix","p_mode_name","keyword_class","keyword_name")");
   // look up the lexer definition for the current mode
   _str lexer_name=p_EmbeddedLexerName;
   if (lexer_name=="") {
      lexer_name=p_lexer_name;
   }
   handle:=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexer_name);
   if (handle<0) {
      return 0;
   }
   /*
     k,csk,
     mlckeywords
     keywordattrs   keyword_name!=""
     atttrvalues    keyword_name!=""
   
   */
   profile_node:=_xmlcfg_set_path(handle,"/profile");
   _str re;
   if (keyword_class=="mlckeywords") {
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'$';
   } else if (keyword_class=="keywordattrs") {
      // Match tag name
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+_escape_re_chars(keyword_name):+VSXMLCFG_PROPERTY_SEPARATOR:+'$';
   } else if (keyword_class=="attrvalues") {
      //list value for attribute, don't care what tag
      re='^'VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+'[^'VSXMLCFG_PROPERTY_SEPARATOR']*':+VSXMLCFG_PROPERTY_SEPARATOR:+_escape_re_chars(keyword_name)'$';
   } else {
      re='^'keyword_class:+VSXMLCFG_PROPERTY_SEPARATOR;
   }
   int array[];
   _xmlcfg_list_properties(array,handle,profile_node,re,'ir');

   // adjust lastid and lastid_prefix for clipping prefix
   if (clip_prefix!="") {
      lastid=clip_prefix:+clip_prefix;
   }
   // create a temporary view and search for the keywords
   for (i:=0;i<array._length();++i) {
      int node=array[i];
      line := "";
      parse _xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME) with auto section (VSXMLCFG_PROPERTY_SEPARATOR) auto cur;
      doAdd := _clex_is_simple_keyword(handle,node);
      if (doAdd) {
         _css_insert_context_tag_item(cur,
                                      lastid,
                                      clip_prefix, start_or_end,
                                      num_matches, max_matches,
                                      exact_match, case_sensitive);
      }
      continue;
   }
   _xmlcfg_close(handle);
   return(0);
}
int _less_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            bool find_parents,int max_matches,
                            bool exact_match,bool case_sensitive,
                            SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                            SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                            VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
   tag_return_type_init(prefix_rt);
   if (!tag_files._length()) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }
   if (prefixexp == '@') {
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               SE_TAG_FILTER_GLOBAL_VARIABLE, //SE_TAG_FILTER_MISCELLANEOUS,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   } else if (prefixexp=='#' || prefixexp=='.') {
      tag_list_context_globals(0, 0, prefixexp:+lastid,
                               true, tag_files,
                               // find LABEL or SE_TAG_TYPE_CONTAINER
                               SE_TAG_FILTER_ANY_SYMBOL, //SE_TAG_FILTER_MISCELLANEOUS, //SE_TAG_FILTER_ANYTHING,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }
   return _css_find_context_tags(errorArgs,
                                 prefixexp,
                                 lastid,lastidstart_offset,
                                 info_flags,otherinfo,
                                 find_parents,max_matches,
                                 exact_match,case_sensitive,
                                 filter_flags,context_flags,
                                 visited,depth+1,
                                 prefix_rt);
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
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_css_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   }
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   lang := p_LangId;

   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
   if (!tag_files._length()) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }
   //prefixexp='all';
   //lastid='un';
   //say('lastid='lastid' p='prefixexp'>');
   if (gexpr_info_cfg==CFG_CSS_PROPERTY) {
      tag_list_context_globals(0, 0, lastid,
                               false, tag_files,
                               SE_TAG_FILTER_MISCELLANEOUS,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      for (i:=tag_get_num_of_matches(); i>0; --i) {
         tag_get_match_info(i, auto cm);
         //say('sym='cm.member_name' type='cm.type_name);
         if (cm.type_name!="tag") {
            tag_remove_match(i);
         }
      }
   } else if (gexpr_info_cfg==CFG_CSS_ELEMENT) {
      _CSSListKeywords((gexpr_info_clip_prefix:=="" || gexpr_info_clip_prefix:=="@")?"css_element":"css_class","",
                        lastid,gexpr_info_clip_prefix,0,
                        num_matches,max_matches,
                        exact_match,case_sensitive);
   } else if (prefixexp != "") {
      if (_chdebug) {
         isay(depth, "_css_find_context_tags: list in class");
      }
      tag_list_in_class(lastid, prefixexp,
                        0, 0, tag_files,
                        num_matches, max_matches,
                        SE_TAG_FILTER_ANYTHING /*SE_TAG_FILTER_ENUM|SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE*/, 
                        SE_TAG_CONTEXT_ANYTHING /*SE_TAG_CONTEXT_ONLY_INCLASS*/,
                        exact_match, case_sensitive,
                        null, null, visited, depth+1);
   } else if (lastid != "" && prefixexp == "") {
      tag_list_context_globals(0, 0, lastid,
                               false, tag_files,
                               SE_TAG_FILTER_MISCELLANEOUS,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);

   } else {
      tag_list_context_globals(0, 0, lastid,
                               false, tag_files,
                               SE_TAG_FILTER_MISCELLANEOUS,
                               SE_TAG_CONTEXT_ANYTHING,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}
_str _less_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="") {
   return _css_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
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
   case "tag":
      return decl_indent_string:+tag_name;

   default:
      break;
   }
   // delegate to C version for anything not CSS specific
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}


_command void css_colon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state() || p_col<=1) {
      call_root_key(":");
      return;
   }
   save_pos(auto p);
   left();
   search('^|[^ \t]','@r-h');
   if (match_length()) {
      VS_TAG_IDEXP_INFO idexp_info;
      status:=_css_get_expression_info(false,idexp_info);
      if (!status && gexpr_info_cfg==CFG_CSS_PROPERTY) {
         restore_pos(p);
         open_offset:=_QROffset();
         _insert_text(":");
         save_pos(p);
         close_offset:=_QROffset();
         _insert_text(";");
         AutoBracketMarker.createMarker(";", open_offset, 1, close_offset, 1);
         restore_pos(p);
         return;
      }
   }
   restore_pos(p);
   keyin(":");
}


#if 0
_command void css_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      call_root_key('{');
      return;
   }
   cfg := 0;
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
#endif
