////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc. 
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
// Language support module for Coffeescript
// 
#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "context.e"
#import "cutil.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

static const COFFEESCRIPT_LANGUAGE_ID= 'coffeescript';

defeventtab coffeescript_keys;
//def '('=vera_paren;
//def '.'=auto_codehelp_key;
def ' '= ext_space;
def 'ENTER'=coffeescript_enter;
//def '{'= vera_beginbrace;
//def '}'= vera_endbrace;
def tab= smarttab;

_command coffeescript_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(COFFEESCRIPT_LANGUAGE_ID);
}

//static SYNTAX_EXPANSION_INFO coffeescript_space_words:[] = {
//   'do'             => { "do { ... } while ( ... )" },
//   'foreach'        => { "foreach ( in ) { ... }" },
   //'if'             => { "if ... ..." },
//   'trap'           => { "trap { ... }" },
//   'finally'        => { "finally { ... }" },
//   'switch'         => { "switch ( ... ) { ... }" },
//   'while'          => { "while ( ... ) { ... }" }
//};

//static int powershell_insert_braces(int syntax_indent,int be_style,int width)
//{
//   int up_count = 0;
//   if ( be_style == BES_BEGIN_END_STYLE_3 ) {
//      width=width+syntax_indent;
//   }
//   up_count=1;
//   if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
//      up_count=up_count+1;
//      insert_line(indent_string(width)'{');
//   }
//   if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
//      up_count=up_count+1;
//      if (be_style == BES_BEGIN_END_STYLE_3) {
//         insert_line(indent_string(width));
//      } else {
//         insert_line(indent_string(width+syntax_indent));
//      }
//   }
//   insert_line(indent_string(width)'}');
//   set_surround_mode_end_line();
//   return up_count;
//}

//static _str coffeescript_expand_space()
//{
//   int status=0;
//
//   // grab the line we're looking at
//   _str line='';
//   get_line(line);
//   line=strip(line,'T');
//   _str orig_word=lowcase(strip(line));
//
//   // if we are not at the end of the line, then forget it
//   if ( p_col!=text_col(_rawText(line))+1 ) {
//      return(1);
//   }
//
//   _str aliasfilename='';
//   _str word=min_abbrev2(orig_word,coffeescript_space_words,'',aliasfilename);
//
//   // can we expand an alias?
//   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
//      // if the function returned 0, that means it handled the space bar
//      // however, we need to return whether the expansion was successful
//      return expandResult;
//   }
//
//   // we can't do anything with an empty word
//   if ( word=='') return(1);
//
//   // see if we need to update our adaptive formatting info for this file
////   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
//
//   syntax_indent := p_SyntaxIndent;
////   _str maybespace = (p_no_space_before_paren) ? '' : ' ';
////   _str parens = (p_pad_parens) ? '(  )':'()';
////   int paren_offset = (p_pad_parens) ? 2 : 1;
////   int paren_width = length(parens);
////
////   be_style := p_begin_end_style;
////   _str be0 = (be_style & (BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3)) ? '' : ' {';
////   int be_width = length(be0);
////
////   set_surround_mode_start_line();
////   line=substr(line,1,length(line)-length(orig_word)):+word;
////   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
////
////   doNotify := true;
////   if ( word=='foreach' ) {
////      _str foreach_parens = (p_pad_parens) ? '(  in  )':'( in )';
////      replace_line(line :+ maybespace :+ foreach_parens :+ be0);
////      up(powershell_insert_braces(syntax_indent,be_style,width));
////      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
////      if ( ! _insert_state() ) { _insert_toggle(); }
////   } else if (word=='if' || word=='while' || word=='switch') {
////      replace_line(line :+ maybespace :+ parens :+ be0);
////      up(powershell_insert_braces(syntax_indent,be_style,width));
////      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
////      if ( ! _insert_state() ) { _insert_toggle(); }
////   } else if (word=='trap' || word=='finally' || word=='do') {
////      replace_line(line :+ be0);
////      int up_count = powershell_insert_braces(syntax_indent,be_style,width);
////      if (word == 'do') {
////         end_line();
////         if (be_style == BES_BEGIN_END_STYLE_3) {
////            insert_line(indent_string(width));
////            _insert_text('while' :+ maybespace :+ parens);
////         } else {
////            _insert_text(' while' :+ maybespace :+ parens);
////         }
////      }
////      up(up_count);
////      insert_line(indent_string(width+syntax_indent));
////      if ( ! _insert_state() ) { _insert_toggle(); }
////   } else {
////      status = 1;
////      doNotify = false;
////   }
////
////   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
////      // notify user that we did something unexpected
////      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
////   }
////
//   return status;
//}

//int _coffeescript_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
//{
//   return AutoCompleteGetSyntaxSpaceWords(words, coffeescript_space_words, prefix, min_abbrev);
//}

int coffeescript_proc_search(_str &proc_name,bool find_first)
{
   _str re_map:[];
   re_map:["ARGS"] = "?#";
   return _generic_regex_proc_search('^( |\t)@<<<NAME>>>(\:|( |\t)@=)( |\t)@((\(<<<ARGS>>>\))|)( |\t)@\->', proc_name, find_first!=0, "func", re_map);
}

//_command coffeescript_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
//{
//   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
//        _in_comment() ||
//        coffeescript_expand_space() ) {
//      if ( command_state() ) {
//         call_root_key(' ');
//      } else {
//         keyin(' ');
//      }
//   } else if (_argument=='') {
//      _undo('S');
//   }
//
//}

_command void coffeescript_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_coffeescript_expand_enter, true);
}
bool _coffeescript_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

/*
 * Do syntax indentation on the ENTER key.
 * Returns non-zero number if pass through to enter key required
 */
typeless _coffeescript_expand_enter()
{
   orig_col := p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line' || 
       (enter_cmd:=='maybe-split-insert-line' && !_insert_state())
       ) {
      _end_line();
   }
   int col=coffeescript_getIndentCol();
   if (col<=0) {
      col=orig_col;
   }

   indent_on_enter(0,col);
   return 0;
}

/*
  Determine what we are inside of

  Search backwards for  {[(: ,  blocks,   begin-line-first-non-blank (comment or string )

  a= {
       'a': [1,
          2,
          3]
       'this is a test': (1,
                          2,
                          3)
     }
  if (
       (<enter here>
         a,
        b
       ) +
       (c,
        d)
       
     ) :
       print




*/

static const COFFEESCRIPT_DEBUG_INDENT=      0;
static const COFFEESCRIPT_BLOCK_WORDS=       ' catch class else finally for if switch try unless when while ';
static const COFFEESCRIPT_POSSIBLE_POSTFIX=  ' if unless while ';
static const COFFEESCRIPT_PAREN_CHARS=       "{}[]()";
static const COFFEESCRIPT_INDENT_SYMBOLS=    ' -> = : => ';
static int coffeescript_getIndentCol()
{
   if (COFFEESCRIPT_DEBUG_INDENT) say('GETTING INDENT COLUMN');

   // see if adaptive formatting needs to figure anything out
   updateAdaptiveFormattingSettings(AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS);

   // save where we were
   save_pos(auto p);
   orig_linenum := p_line;
   orig_col := p_col;

   // see if we need a continuation indent here
   contIndent := coffeescript_thisLineNeedsContinuing();

   // look for one of our block words or for parens
   words_re := translate(strip(COFFEESCRIPT_BLOCK_WORDS),'|',' ');
   //words_re := '(^|[ \t])'translate(strip(COFFEESCRIPT_BLOCK_WORDS),'|',' ')'($|[ \t])';
   symbols_re := translate(strip(_escape_re_chars(COFFEESCRIPT_INDENT_SYMBOLS)),'|',' ');
   // open or close parens, a symbol at the end of the line, one of our magic words, or a regular non-blank line
   regex := '['_escape_re_chars(COFFEESCRIPT_PAREN_CHARS)']|('symbols_re')$|'words_re'|^[ \t]*[^ \t]';
   // reverse search, slickedit regex, search hidden lines, no error message
   status := search(regex,'-Rh@');

   // first non-blank col
   begin_line_col := 0;
   // and line
   begin_line_line := 0;

   // great big for loop!
   for (;;) {
      // if our search failed to find what we were looking for
      if (status) {
         // go back to where we were
         restore_pos(p);
         if (begin_line_col) {
            return(begin_line_col);
         }
         // find the first non-blank, indent to that
         status=search('[^ \t]','hr@');

         // we're just lost now 
         if (status) return(p_col);

         result_col := p_col;
         restore_pos(p);
         return(result_col);
      }
      if (COFFEESCRIPT_DEBUG_INDENT) say('   search brought us to p_line = 'p_line', p_col = 'p_col);

      // figure out what kind of symbol we're standing on
      int cfg=_clex_find(0,'g');

      // grab the text of our match
      //_str match=strip(get_match_text());
      match := get_match_text();
      matchLen := length(match);

      isSymbolMatch := (pos(match,COFFEESCRIPT_PAREN_CHARS) != 0) || (pos(' 'match' ',COFFEESCRIPT_INDENT_SYMBOLS) != 0);

      // grab the characters on the left and the right of our match
      _str chLeft = get_text(1,match_length('S') - 1);
      _str chRight = get_text(1,match_length('S') + match_length(''));

      // grab the rest of the line, too
      get_line(auto line);
      firstPartOfLine := substr(line, 1, p_col - 1);
      restOfLine := substr(line, p_col + matchLen);
      
//    if (COFFEESCRIPT_DEBUG_INDENT) say('      match = 'match', chLeft = 'chLeft', chRight = 'chRight', restOfLine = 'restOfLine);
      if (COFFEESCRIPT_DEBUG_INDENT) say('      match = 'match', firstPartOfLine = 'firstPartOfLine', restOfLine = 'restOfLine);

      // IF we have not found the beginning of the line
      // AND this is a non-symbol match
      if (!begin_line_col && !isSymbolMatch) {

         // if this is not a continued line, then save it
         if (!coffeescript_isLineContinuedFromPrevious()) {

            // save where we found the first non-blank
            save_pos(auto p2);
            _first_non_blank();
            begin_line_col=p_col;
            begin_line_line=p_line;
            restore_pos(p2);
            if (COFFEESCRIPT_DEBUG_INDENT) say('      saving begin line = 'begin_line_line' and col = 'begin_line_col);
         }
      }

      // if we landed in a comment or a string, try again
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         status=repeat_search();
         continue;
      }

      // did we find a paren?  a symbol match?
      // parens can be used for blocks, or they can be omitted.  it's confusing
      if (isSymbolMatch) {

         if (COFFEESCRIPT_DEBUG_INDENT) say('      symbol match');
         /*
          * Paren char cases
            + have text after brace but before <cursor>
               ** Use column of text

            +  Dont' have text,
               Use first_non_blank()+syntax_indent
          */

         // did we find a closing block?
         switch (match) {
         case '}':
         case ']':
         case ')':
            if (COFFEESCRIPT_DEBUG_INDENT) say('         closing paren/brace match');

            // see if we can find the matching opening paren
            int match_status=_find_matching_paren(MAXINT,true);
            if (match_status) {
               // match the indent of whatever was going on before the paren block
               status=search('[^ \t]','hr@');
               if (status) return(p_col); // We are lost
               result_col := p_col;
               restore_pos(p);
               return(result_col);
            }
            // no matching paren?  just try our search again
            status=repeat_search();
            continue;
         }

         // it must have been an opening paren or a symbol
         // save our search parameters, we're about to do a different one
         result_col := 0;
         save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
         save_pos(auto p2);

         // Search for a non-blank character after the symbol
         for (i := 0; i < matchLen; i++) right();

         auto search_status=search('[^ \t]','hr@');
         if (!search_status) {
            // found one
            if (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col)) {
               // as long as it comes before our original position, then save it
               if (COFFEESCRIPT_DEBUG_INDENT) say('         found a blank after the symbol(p_line = 'p_line', p_col = 'p_col);
               result_col=p_col;
            }
         }
         // restore our old search params and position
         restore_search(s1,s2,s3,s4,s5);
         restore_pos(p2);

         // we are skipping continuation indent right now.  Just indent like regular
         if (result_col) {
            // we got a result, so send it back
            if (COFFEESCRIPT_DEBUG_INDENT) say('         result col is 'result_col);
            restore_pos(p);
            return(result_col);
         } else {
            // no result, so we'll just add the indent to what we did find
            _first_non_blank();
            result_col=p_col+p_SyntaxIndent;
            if (COFFEESCRIPT_DEBUG_INDENT) say('         no line after symbol, adding to first blank = 'p_col', which gives us 'result_col);
            restore_pos(p);
            return(result_col);
         }
      }

      // sometimes we find something that is merely a long word with a keyword inside it
      if (!pos(' 'match' ',COFFEESCRIPT_BLOCK_WORDS) || ext_isIdChar(chLeft) || ext_isIdChar(chRight)) {
         // not what we want, try again
         if (COFFEESCRIPT_DEBUG_INDENT) say('         not a block word, continuing');
         status = repeat_search();
         continue;
      }

//    // the match is just a regular old line
//    if (!pos(' 'match' ',COFFEESCRIPT_BLOCK_WORDS)) {
//       first_non_blank();
//
//       // now, just add the syntax indent to the current col and we are good to go
//       int result_col=p_col;
//       restore_pos(p);
//
//       if (COFFEESCRIPT_DEBUG_INDENT) say('   found the previous line level, using result_col = 'result_col);
//       return result_col;
//    }

      // if this is a continued line, then it's not really that helpful
      if (coffeescript_isLineContinuedFromPrevious()) {
         if (COFFEESCRIPT_DEBUG_INDENT) say('         this line is a continuation, continuing search');
         status=repeat_search();
         continue;
      }

      continuationIndent := contIndent ? p_SyntaxIndent : 0;

      // the only matches we have left are word matches
      if (begin_line_col && p_line < begin_line_line) {
         if (COFFEESCRIPT_DEBUG_INDENT) say('         returning begin_line_col, found on line 'begin_line_line);
         restore_pos(p);
         return begin_line_col + continuationIndent;
      }

      // however, some of these block cases may be one-liners - check for the when
      if (match == 'if' || match == 'when') {
         // look for a then
         if (pos('then', restOfLine)) {
            // this is a one-line statement, so we can't calculate 
            // the indent based on it, try again
            if (COFFEESCRIPT_DEBUG_INDENT) say('         one line if or when statement, continuing search');
            status=repeat_search();
            continue;
         }
      }

      // sometimes if is used postfix, which means it's a one line statement, no indent
      if (pos(' 'match' ', COFFEESCRIPT_POSSIBLE_POSTFIX)) {
         // if the match is at the beginning of the line
         // or is preceded directly by an = (which makes the loop an expression)
         strippedFirstPart := strip(firstPartOfLine);
         if (strippedFirstPart != '' &&
             !endsWith(strippedFirstPart, '=') && 
             !(match == 'if' && endsWith(strippedFirstPart, 'else'))) {
            if (COFFEESCRIPT_DEBUG_INDENT) say('   'match' not first or preceeded by =');
            status=repeat_search();
            continue;
         }
      }

      // also, else needs to be at the end of the line - if it's followed by something, then it's a one liner
      // else if handed in if case
      if (match == 'else' && restOfLine != '') {
         status=repeat_search();
         continue;
      }


      // jump to the first nonblank of this line
      _first_non_blank();

      // now, just add the syntax indent to the current col and we are good to go
      int result_col = p_col + p_SyntaxIndent;
      restore_pos(p);
      return(result_col);
   }

}


//static bool coffeescript_lineEndsWithBackslash(int truncate_linenum=-1,int truncate_col=-1)
//{
//   linecont := false;
//   _str line;
//   if (p_line==truncate_linenum) {
//      int ilen=_text_colc(0,'L');
//      if (truncate_col-1<ilen) {
//         line=_expand_tabsc(1,truncate_col-1,'S');
//         _message_box('line='line);
//      } else {
//         get_line(line);
//      }
//   } else {
//      get_line(line);
//   }
//
//   // check the last char
//   if (last_char(line)=='\') {
//      _end_line();
//      left();
//      // Backslash at the end of a comment line is not a line continuation
//      linecont=_clex_find(0,'g')!=CFG_COMMENT;
//   }
//   return(linecont);
//}

static bool coffeescript_thisLineNeedsContinuing()
{
   linecont := false;

   // save where we were
   save_pos(auto p);

   // grab the line
   get_line(auto line);
   line = strip(line);

   // first, check for a backslash - not used very often in CoffeeScript, but it's allowed
   if (_last_char(line) == '\') {
      _end_line();
      left();

      // Backslash at the end of a comment line is not a line continuation
      linecont = _clex_find(0,'g') != CFG_COMMENT;
   } else {
      // if the line ends with OR or AND, then we must be in the middle of an complex boolean
      linecont = endsWith(line, ' (and|or)', false, 'R');
      //say('LINECONT IS 'linecont);
      //say('line is 'line);
   }


   // go back to where we were
   restore_pos(p);

   // return what we found
   return linecont;
}

static bool coffeescript_isLineContinuedFromPrevious() 
{
   // save where we were
   save_pos(auto p);

   // go up to the previous line
   int status=up();

   linecont := coffeescript_thisLineNeedsContinuing();

   // go back to where we were
   restore_pos(p);

   // return what we found
   return linecont;
}

static int coffeescript_findContinuationIndent()
{
   return p_SyntaxIndent;
}

///**
// * Build tag file for PowerShell
// *
// * @param tfindex   Tag file index
// */
//int _powershell_MaybeBuildTagFile(int &tfindex)
//{
//   _str ext=POWERSHELL_EXTENSION;
//   _str basename=POWERSHELL_LANGUAGE_ID;
//
//   // maybe we can recycle tag file(s)
//   _str tagfilename='';
//   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
//      return(0);
//   }
//   tag_close_db(tagfilename);
//
//   // Build tags from powershell.tagdoc or builtins.ps1
//   int status=0;
//   _str extra_file=ext_builtins_path(ext,'powershell');
//   if(extra_file!='') {
//         status=shell('maketags -n "PowerShell Libraries" -o ' :+
//                      _maybe_quote_filename(tagfilename)' ' :+
//                      _maybe_quote_filename(extra_file));
//   }
//   LanguageSettings.setTagFileList(POWERSHELL_LANGUAGE_ID, tagfilename, true);
//
//   return(status);
//}

/**
 * Handle <b>SmartPaste&reg;</b> in Coffeescript. 
 * <p> 
 * In Coffeescript mode, only a line selection can be 
 * SmartPaste'd, and the line selection must be such that the 
 * first selected line always has the least amount of 
 * indentation. 
 *
 * @param char_cbtype pasting character selection?
 * @param first_col first column where pasting
 * @return destination column position based on current context, 
 *         or 0 on failure.  When 0 is returned, the calling
 *         function performs a normal paste.
 */
int coffeescript_smartpaste(bool char_cbtype, int first_col,int Noflines,bool allow_col_1=false)
{
   //_begin_select();up();
   //_end_line();
   //save_pos(auto p4);
   //// Look for first piece of code not in a comment
   //typeless status=_clex_skip_blanks('m');
   //if (status) {
   //   restore_pos(p4);
   //} else {
   //   auto word=cur_word(auto junk_col);
   //   int col=0;
   //   if (word=='elif') {
   //      col=find_block_start_col('if');
   //   } else if (word=='else') {
   //      col=find_block_start_col('while|for|if|try');
   //   } else if ((word=='except') || word=='finally') {
   //      col=find_block_start_col('try');
   //   }
   //   restore_pos(p4);
   //   if (col) {
   //      return(col);
   //   }
   //}
   _begin_select();up();
   _end_line();
   return coffeescript_getIndentCol();
}
