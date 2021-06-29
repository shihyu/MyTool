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
#import "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "autobracket.e"
#import "c.e"
#import "pmatch.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#endregion
using se.lang.api.LanguageSettings;

defeventtab json_keys;
def 'ENTER' = json_enter;
def  '{'= json_begin;
def  '}'= json_endbrace;
def  ']' = json_endbracket;
def 'TAB' = smarttab;
def ' ' = json_space;

struct DelimiterInfo {
   int col;
   long seekPos;
   bool endsLine;
   _str leadingChar;
   int firstNonblank;
   bool isObjectValue;
};

static SYNTAX_EXPANSION_INFO json_space_words:[];

_command void json_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(' ');
   }

   if (doExpandSpace(p_LangId)) {
      orig_word := cur_word(auto startCol);
      if (orig_word != '') {
         word:=min_abbrev2(orig_word, json_space_words, "",
                          auto aliasfilename, true, false);
         if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
            // if the function returned 0, that means it handled the space bar
            // however, we need to return whether the expansion was successful
            return;
         }
      }
   }
   keyin(' ');
}

// Returns the column of the enclosing object or array, or 0
// if there is none.
static void containing_literal_col(DelimiterInfo &di)
{
   rv := 0;
   save_pos(auto pp);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   nesting := 1;
   scanning := true;
   while (scanning) {
      status := search('[[\]{}]', '-<L@');
      if (status != 0) {
         break;
      }
      ch := get_text();
      switch (ch) {
      case '{':
      case '[':
         nesting--;
         if (nesting <= 0) {
            scanning=false;
            rv = p_col;
            di.leadingChar = ch;
            di.seekPos = _QROffset();
         }
         break;

      case ']':
      case '}':
         nesting++;
         break;
      }

      if (prev_char() != 0) {
         break;
      }
   }

   if (rv != 0) {
      save_pos(auto bpos);
      bline := p_line;
      next_char(); 
      moved := next_char() == 0;

      if (moved) {
         end_line();
         status := _clex_skip_blanks('-');
         di.endsLine = (status == 0 && p_col == rv);
      } else {
         di.endsLine = true;
      }
      restore_pos(bpos);
      
      save_pos(bpos);
      if (prev_char() == 0) {
         _clex_skip_blanks('-');
         di.isObjectValue = get_text() == ':';
         restore_pos(bpos);
      } else {
         di.isObjectValue = false;
      }
   }

   _first_non_blank();
   di.firstNonblank = p_col;
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(pp);

   if (rv != 0) {
   }
   di.col =rv;
}

// Called with cursor to the right of the ':', tries to seek backwards
// to the beinning of the key.  
static void reverse_find_key(long from)
{
   _GoToROffset(from);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   search('"[ \t]*:', '-L@');
   if (prev_char() == 0) {
      _clex_find_start();
   }
   //say('reverse_find_key from 'from' to '_QROffset());
   restore_search(s1, s2, s3, s4, s5);
}

static void get_edit_context(DelimiterInfo& inner, DelimiterInfo& outer)
{
   save_pos(auto pp);
   containing_literal_col(inner);
   if (inner.col > 0) {
      _GoToROffset(inner.seekPos);
      if (prev_char() == 0) {
         containing_literal_col(outer);
      } else {
         outer.col = 0;
      }
   } else {
      outer.col = 0;
   }
// if (inner.col == 0) {
//    say('edit_context: top level');
// } else {
//    say('edit_context INNER col='inner.col', leadingChar='inner.leadingChar', firstNonblankCol='inner.firstNonblank', braceEndsLine='inner.endsLine', leadingCharSeekPos='inner.seekPos', isObjVal='inner.isObjectValue);
//    if (outer.col != 0) {
//       say('edit_context OUTER col='outer.col', leadingChar='outer.leadingChar', firstNonblankCol='outer.firstNonblank', braceEndsLine='outer.endsLine', leadingCharSeekPos='outer.seekPos', isObjVal='outer.isObjectValue);
//    }
// }
   restore_pos(pp);
}


static int calc_nextline_indent()
{
   rv := 0;
   save_pos(auto pp);

   //TODO: string special case

   ch := get_text();
   if (ch == ']' || ch == '}') {
      prev_char();
   }

   get_edit_context(auto di, auto outer);
   if (di.col == 0) {
      restore_pos(pp);
      return 0;
   }
   if (outer.col == 0) {
      if (di.endsLine) {
         rv = di.col + p_SyntaxIndent - 1;
      } else {
         rv = di.firstNonblank;
      }
   } else if (di.endsLine) {
      if (di.isObjectValue) {
         reverse_find_key(di.seekPos);
         rv = p_col - 1;
         rv = di.firstNonblank + p_SyntaxIndent - 1;
      } else {
         rv = di.col + p_SyntaxIndent - 1;
      }
   } else {
      // !di.endsLine
      rv = di.col;
   }

   restore_pos(pp);
   return rv;
}

_command void json_enter(_str synthetic='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   line_splits := _will_split_insert_line();
   long rb_pos;

   if (synthetic == ''
       && _will_split_insert_line() 
       && should_expand_cuddling_braces('json') 
       && inside_cuddled_braces(rb_pos)) {
      save_pos(auto pp);
      _GoToROffset(rb_pos);
      delete_char();
      indent_on_enter(p_SyntaxIndent, calc_nextline_indent()+1);
      json_endbrace();
      restore_pos(pp);
      indent_on_enter(p_SyntaxIndent, calc_nextline_indent()+1);
   } else {
      indent_on_enter(p_SyntaxIndent, calc_nextline_indent()+1);
   }
}

bool _json_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

int json_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   _begin_select();
   up();
   end_line();
   //tODO
   return calc_nextline_indent()+1;
}


//TODO: auto-close for '['

static void reindent_closing_delim(_str startDelim, _str endDelim)
{
   if (line_is_blank()) {
      int ind;

      get_edit_context(auto inner, auto outer);
      if (inner.col == 0 || inner.leadingChar != startDelim) {
         keyin(endDelim);
         return;
      } else if (outer.col == 0) {
         ind = inner.col - 1;
      } else if (inner.isObjectValue) {
         if (inner.endsLine) {
            save_pos(auto pp);
            reverse_find_key(inner.seekPos);
            ind = p_col - 1;
            restore_pos(pp);
         } else {
            ind = inner.col - 1;
         }
      } else {
         ind = inner.col - 1;
      }
      replace_line(indent_string(ind):+endDelim);
      end_line();
   } else {
      keyin(endDelim);
   }
}

_command void json_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   reindent_closing_delim('{', '}');
}


_command void json_endbracket() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   reindent_closing_delim('[', ']');
}

void _json_snippet_find_leading_context(long selstart, long selend) {
   _GoToROffset(selstart);
   get_edit_context(auto inner, auto outer);
   _GoToROffset(inner.seekPos);
}

static int json_expand_begin()
{
   rv := -1;

   if (line_is_blank()) {
      replace_line(indent_string(calc_nextline_indent()));
      end_line();
   } 

   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);
   insertBlankLine := LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId);

   if (expand) {
      int placement = get_autobrace_placement(p_LangId);

      rv = 0;
      lbo := _QROffset();
      keyin('{');
      if (placement == AUTOBRACE_PLACE_SAMELINE) {
         rbo := _QROffset();
         keyin('}');
         AutoBracketForBraces(p_LangId, lbo, rbo);
         _GoToROffset(rbo);
      } else {
         cur := _QROffset();
         json_enter('n');
         json_endbrace();
         _GoToROffset(cur);
         if (placement == AUTOBRACE_PLACE_AFTERBLANK) {
            json_enter('n');
         }
      }
   }

   return 0;
}

_command void json_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   //TODO: should not be doing this.
   // Need: autoclose
   cfg := 0;
   if (p_col>1) {
      left();cfg=_clex_find(0,'g');right();
   }

   if ( cfg==CFG_STRING || json_expand_begin()) {
      call_root_key('{');
   }

}

