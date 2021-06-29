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
// 
// Language support module for PowerShell
// TSFKA (the shell formerly known as) Microsoft Command Shell, Monad shell
// 
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "hotspots.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

static const POWERSHELL_LANGUAGE_ID= "powershell";
static const POWERSHELL_PROC_ID_RE= '(#[ [a-zA-Z0-9_$\-\x{80}-\x{FFFF}] + [\x{85}\x{A0}\x{1680}\x{2000}-\x{200A}\x{2018}-\x{201E}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}] ])#';

_command void powershell_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON) {
   ps1_mode();
}
_command void ps1_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(POWERSHELL_LANGUAGE_ID);
}

static const EXPAND_WORDS= (' static hidden class ');
static SYNTAX_EXPANSION_INFO powershell_space_words:[] = {
   "class"          => { "class" },
   "default"        => { "default { ... }" },
   "do"             => { "do { ... } while ( ... )" },
   "for"            => { "for ( ... ) { ... }" },
   "foreach"        => { "foreach ( in ) { ... }" },
   //"hidden"          => { "hidden" },
   "if"             => { "if ( ... ) { ... }" },
   "trap"           => { "trap { ... }" },
   "finally"        => { "finally { ... }" },
   "static"         => { "static" },
   "switch"         => { "switch ( ... ) { ... }" },
   "try"            => { "try { ... } catch [ ... ] { ... }" },
   "while"          => { "while ( ... ) { ... }" }
};

static _str powershell_expand_space()
{
   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   noSpaceBeforeParen := p_no_space_before_paren;
   expansion_end := 0L;
   status := 0;
   orig_line := "";
   get_line(orig_line);
   line:=strip(orig_line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,powershell_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=="") return(1);

   clear_hotspots();
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   
   syntax_indent := p_SyntaxIndent;
   _str openparen='(';
   _str closeparen=')';
   _str maybespace = (p_no_space_before_paren) ? "" : " ";
   _str parenspace=(p_pad_parens)? ' ':'';
   _str parens = (p_pad_parens) ? "(  )":"()";
   bracespace := ' ';
   int paren_offset = (p_pad_parens) ? 2 : 1;
   paren_width := length(parens);
   
   be_style := p_begin_end_style;
   _str be0 = (be_style & (BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3)) ? "" : " {";
   be_width := length(be0);
   style2 := be_style == BES_BEGIN_END_STYLE_2;
   style3 := be_style == BES_BEGIN_END_STYLE_3;

   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   e1 := " {";
   if (word=='do' || word=='try' || word=='finally' || word=='}finally' || word=='} finally' || word=='default' || 
       word=='trap' || 
       word=='if' || word=='else' || word=='elseif') {
      // Braces are either required or this construct only works well when braces are inserted immediately
      insertBraceImmediately=true;
   }
   if (! ((word=='do' || word=='try' || word=='finally' || word=='}finally' || word=='} finally' || word=='default' || word=='') && !style2 && !style3) ) {
      if ( style2 || style3 || !insertBraceImmediately ) {
         e1='';
      } else if (word=='}else' || word=='}finally') {
         e1='{';
      }
   } else if (last_event()=='{') {
      e1='{';
      bracespace='';
   }

   doNotify := true;
   if ( word=="foreach" ) {
      _str foreach_parens = (p_pad_parens) ? "(  in  )":"( in )";
      replace_line(line :+ maybespace :+ foreach_parens :+ e1);
      _begin_line();search(')','@h');
      if (p_pad_parens) left();
      add_hotspot();
      if (!insertBraceImmediately) {
         _end_line();
         add_hotspot();
      }
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word),openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=="for" ) {
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately, width, word, false, openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if (word=="if" || word=="while" || word=="switch") { 
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      //replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word),openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='try' ) {
      surround_end_line := 0;
      num_end_lines := 2;
      if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) ++num_end_lines;
      if (style2 || style3) ++num_end_lines;
      replace_line(line:+e1);
      if (!style3) {
         if (style2) {
            insert_line(indent_string(width)'{');
         }
         cuddleElse := LanguageSettings.getCuddleElse(p_LangId);
         if (!cuddleElse) {
            insert_line(indent_string(width)'}');
            surround_end_line=p_line+1;
            insert_line(indent_string(width)'catch':+maybespace'['parenspace:+parenspace']'e1);
            ++num_end_lines;
         } else {
            insert_line(indent_string(width)'}'bracespace'catch':+maybespace'['parenspace:+parenspace']'e1);
            surround_end_line=p_line+1;
         }
         _end_line();
         p_col -= (length(e1)+1);
         add_hotspot();
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
         up(1);
         if (!cuddleElse){
            up(1);
         }
      } else if (style3) {
         insert_line(indent_string(width+syntax_indent)'{');
         insert_line(indent_string(width+syntax_indent)'}');
         surround_end_line=p_line+1;
         insert_line(indent_string(width)'catch':+maybespace'('parenspace:+parenspace')'e1);
         _end_line();
         p_col -= (length(e1)+1+length(parenspace));
         add_hotspot();
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
         up(2);
         ++num_end_lines;
      }
      nosplit_insert_line();
      p_col=width+syntax_indent+1;
      add_hotspot();
      set_surround_mode_end_line(surround_end_line, num_end_lines);
   } else if ( word=='do' ) {
      insertBraceImmediately=true;  // do doesn't work well when not inserting braces immediately
      // Always insert braces for do loop unless braces are on separate
      // line from do and while statements
      num_end_lines := 1;
      replace_line(line:+e1);
      if ( ! style3 ) {
         if (style2 ) {
            insert_line(indent_string(width)'{');
         }
         insert_line(indent_string(width)'}'bracespace'while':+maybespace'('parenspace:+parenspace');');
         _end_line();
         expansion_end = _QROffset();
         p_col -= 2;

         updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
         if (p_pad_parens) p_col--;
         add_hotspot();
         up();
      } else if ( style3 ) {
         if (insertBraceImmediately) {
            num_end_lines=2;
            insert_line(indent_string(width+syntax_indent)'{');
            insert_line(indent_string(width+syntax_indent)'}');
            insert_line(indent_string(width)'while':+maybespace'('parenspace:+parenspace');');
            _end_line();
            expansion_end = _QROffset();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(2);
            //syntax_indent=0;
         } else {
            insert_line(indent_string(width)'while'maybespace:+'('parenspace:+parenspace');');
            _end_line();
            expansion_end = _QROffset();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(1);
            //syntax_indent=0
         }
      }
      nosplit_insert_line();
      set_surround_mode_end_line(p_line+1, num_end_lines);
      p_col=width+syntax_indent+1;
      add_hotspot();
   } else if (word=="trap" || word=="finally" || word=='default') { 
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
      _end_line();
   } else if ( pos(' 'word' ',EXPAND_WORDS)) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else {
      status = 1;
      doNotify = false;
   }
   show_hotspots();
   
   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

int _powershell_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, powershell_space_words, prefix, min_abbrev);
}

int powershell_proc_search(_str &proc_name,bool find_first)
{
   // ^:b*{#0(function|filter|alias|cmdlet)}:b{#0([a-z0-9\-]#)}
   // or for existing
   // ^:b*{#0(function|filter|alias|cmdlet)}:b{#1(proc-name)}
   searchOptions := "@riXc";
   procSearchName :=  POWERSHELL_PROC_ID_RE;
   rePart1 := '^[ \t]*{#0(function|filter|alias|cmdlet)}:b{#1(';
   rePart2 := ")}";

   if ( proc_name != "" ) {
      procSearchName = _escape_re_chars(proc_name);
   }

   search_key :=  rePart1 :+ procSearchName :+ rePart2;
   status := 0;
   //_str search_key='^[\[]'proc_name'[\]]';
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
      // Pick out the name of this function, filter, or alias
      // from the tagged expression #1
      groupStart := match_length('S1');
      groupLen := match_length('1');
      tempFoundProc := get_text(groupLen, groupStart);
      tag_flags := SE_TAG_FLAG_NULL;

      // Don't confuse the scope with the function/filter name.
      scopeDelim := pos(":", tempFoundProc);
      if (scopeDelim > 0 && tempFoundProc._length() > scopeDelim) {
         scope := substr(tempFoundProc, 1, scopeDelim-1);
         tempFoundProc = substr(tempFoundProc, scopeDelim+1);
         if (strieq(scope, "private")) {
            tag_flags |= SE_TAG_FLAG_PRIVATE;
         } else if (strieq(scope, "script")) {
            tag_flags |= SE_TAG_FLAG_PACKAGE;
         }      
      }

      groupStart = match_length('S0');
      groupLen = match_length('0');
      procType := get_text(groupLen, groupStart);

      type_name := "";
      arguments := "";
      if(strieq("function", procType))
      {
         type_name = "proc";
         // TODO: Search down from within the enclosing brace
         // for the param keyword, and add the arguments spec
      }
      else if (strieq("filter", procType))
      {
         type_name = "proc";
      }
      else if (strieq("alias", procType))
      {
         type_name = "typedef";
      }
      else if (strieq("cmdlet", procType))
      {
         type_name = "class";
         // TODO: When PowerShell v2 cmdlet syntax is finalized, add
         // support for the child param, begin, process, and end blocks
         // when present
      }

      tag_init_tag_browse_info(auto cm, tempFoundProc, "", type_name, tag_flags, "", 0, 0, arguments);
      proc_name = tag_compose_tag_browse_info(cm);
   }
   return(status);
}

_command powershell_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      powershell_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=="") {
      _undo('S');
   }

}

_command void powershell_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}
bool _powershell_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _powershell_supports_insert_begin_end_immediately() {
   return true;
}

/**
 * Build tag file for PowerShell
 *
 * @param tfindex   Tag file index
 */
int _powershell_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, POWERSHELL_LANGUAGE_ID, POWERSHELL_LANGUAGE_ID,
                                "PowerShell Libraries",
                                "", false, withRefs, useThread, forceRebuild);
}
/*
 
# line ending with `
# line ending with ! , | + - * / % 
# -band -bor -bxor -bnot -eq -ne -ge -le -lt -gt -like -notlike -contains -in -notin -and -or -not -xor -replace -split -join -as -is -f
*/
bool _powershell_treat_this_newline_like_a_semicolon(bool adjust_col_if_semicolon=false) {
   save_pos(auto p);
   if (p_col>1) {
      left();
      if (get_text():=='`') {
         restore_pos(p);
         return false;
      }
      right();
   }
   cfg:=_clex_find(0,'g');
   start_line:=p_line;
   _clex_skip_blanksNpp('-');
   if (p_line!=start_line) {
      restore_pos(p);
      return false;
   }
   ch:=get_text();
   if (ch:==';') {
      if (adjust_col_if_semicolon) {
         return true;
      }
      restore_pos(p);
      return false;
   }
   // Continuation operator at end of line?
   if (pos(ch,'=!,|+-*/%{}')) {
      //messageNwait('continuation operator='ch);
      restore_pos(p);
      return false;
   } else if (isalpha(ch)) {
      word:=cur_identifier(auto start_col);
      // Continuation operator word at end of line?
      if (substr(word,1,1)=='-' && 
          pos(word,'-band -bor -bxor -bnot -eq -ne -ge -le -lt -gt -like -notlike -contains -in -notin -and -or -not -xor -replace -split -join -as -is -f')
          ) {
         //messageNwait('continuation word='word);
         restore_pos(p);
         return false;
      }
   }
   restore_pos(p);
   return true;
}
bool _powershell_is_smarttab_supported() {
   return true;
}

