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
#include "color.sh"
#include "markers.sh"
#import "se/lang/api/LanguageSettings.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "c.e"
#import "color.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "seldisp.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * Charactors to use for parentheses pair matching.
 * <p>
 * By default, this only supports parentheses,
 * square brackets, and curly braces.  
 * <p>
 * To support &lt; and &gt; for template argument lists,
 * simply append &lt;&gt; to this variable.  Note that this can
 * be easily confused with uses of &lt; and &gt; in comparison
 * expressions.
 *
 * @default "()[]{}"
 * @categories Configuration_Variables
 * @see find_matching_paren
 * @see keyin_match_paren
 */
_str def_pmatch_chars='()[]{}';

/**
 * Set this to true to enable debug output for find-matching-paren. 
 * Currently, this is only supported for Fortran.
 */
bool _pmdebug = false;

/**   
 * Inserts one of the end parenthesis ], }, or ) and then temporarily
 * places the cursor on the matching begin parenthesis for a short period of
 * time.
 *
 * @see find_matching_paren
 * @see show_matching_paren
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 *
 */
_command keyin_match_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin(last_event());
   if ( command_state() ) {
      return(1);
   }
/*
   Multiple cursors/selections does not support block/column 
   selections so we can't temporarily show a block/column selection.
*/
#if !MULTI_CURSOR_SUPPORTS_BLOCK_MARK
   if (_MultiCursor()) {
      return(1);
   }
#else
   if (!_MultiCursorActiveLoopIteration()) {
      return(1);
   }
#endif
   if (!_macro('r')) {
      _UpdateShowMatchingParen(true);
   }
   if (def_pmatch_style2=='') return(1);
   if (p_lexer_name!='' && _clex_find(0,'g')==CFG_STRING) {
      return(1);
   }

   int p=pos(last_event(),def_pmatch_chars);
   if ( ! p ) {
      return(1);
   }
   typeless status=0;
   p_col--;
   if ( def_pmatch_style2 ) {
      typeless old_mark=_duplicate_selection('');
      typeless mark=_alloc_selection();
      if ( mark<0 ) {
         return(mark);
      }
      _show_selection(mark);
      typeless position;
      save_pos(position);
      /*paren_pair=substr('()[]{}',p-1,2)*/
      status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'','-','',substr(def_pmatch_chars,p-1,1),false,true,true);
      if ( ! status ) {
         _select_block(mark);
         restore_pos(position);
         /* .col=.col+1 */
         _select_block(mark);
         p_col++;
         if (!_macro('r')) {
            refresh();
            delay(20,'k');
         }
      } else {
         p_col++;
      }
      _show_selection(old_mark);
      _free_selection(mark);
   } else {
      paren_pair := substr(def_pmatch_chars,p-1,2);
      status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'','-','',substr(def_pmatch_chars,p-1,1));
      if ( ! status ) {
         if (!_macro('r')) {
            refresh();
            delay(50,'k');
         }
         match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'','','',substr(def_pmatch_chars,p,1));
      }
      p_col++;
   }
   return(0);
#if 0
   keyin(last_event());
   p=pos(last_event(),def_pmatch_chars);
   if ( ! p ) {
      return(1);
   }
   p_col--;
   paren_pair := substr(def_pmatch_chars,p-1,2);
   status=match_paren('','-','',substr(def_pmatch_chars,p-1,1));
   if ( ! status ) {
      refresh();
      delay(50,'k');
      match_paren('','','',substr(def_pmatch_chars,p,1));
   }
   p_col++;
#endif
}
int _find_matching_paren(int pmatch_max_diff_ksize=MAXINT,bool quiet=false,int pmatch_max_level=MAXINT,bool alwaysUpdate=true,bool matchAllParens=false, int initialNestLevel=0, int depth=1)
{
   if (pmatch_max_diff_ksize!=MAXINT && p_buf_size>def_pmatch_max_ksize*1024) {
      return 1;
   }
   if (pmatch_max_diff_ksize!=MAXINT && pmatch_max_level==MAXINT) {
      pmatch_max_level=def_pmatch_max_level;
   }
   depth += initialNestLevel;
   if (_pmdebug) {
      isay(depth, "_find_matching_paren(pmatch_max_diff_ksize:"pmatch_max_diff_ksize" ,quiet:"quiet", pmatch_max_level:"pmatch_max_level", alwaysUpdate:"alwaysUpdate", matchAllParens:"matchAllParens", initialNestLevel:"initialNestLevel", depth:"depth);
   }

   // IF cursor is past end of line AND line is not blank
   ch := "";
   save_pos(auto orig_pos);
   if ( p_col>_text_colc() && _text_colc()) {
      ch=_expand_tabsc(_text_colc(),1);
      if ( pos(ch,def_pmatch_chars) ) {
         p_col=_text_colc();
      }
   }
   // first check the character right at the cursor
   ch = get_text();
   p := pos(ch,def_pmatch_chars);
   if (!p) {
      // a little forgiving, check the character before the cursor
      if (p_col>1) {
         left();  // this does move the cursor one to the left even if the match fails,
                  // however it should show more clearly what we were trying to match
         ch = get_text();
         p=pos(ch,def_pmatch_chars);
         if (!p) {
            // still nothing, put the cursor back
            right();
         }
      }
   }
   if (_pmdebug) {
      isay(depth, "_find_matching_paren: ch="ch"= def_pmatch_chars="def_pmatch_chars" p="p);
   }

   // special case for Bulletin Board Code Tags
   if (_LanguageInheritsFrom('bbc') && (ch=='[' || ch==']')) {
      p=0;
   }

   lang := "";
   line := "";
   word := "";
   word_chars := "";
   old_col := 0;
   status := 0;
   typeless ignore_case=0;

   if (p % 2) {   /* begin paren? */
      if (_pmdebug) {
         isay(depth, "_find_matching_paren: BEGIN PAREN ch="ch);
      }
      status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','','',substr(def_pmatch_chars,p+1,1),quiet,alwaysUpdate,matchAllParens, initialNestLevel, depth+1);

   } else {

      if ( ! p ) {
         lang=p_LangId;
         pi := _FindLanguageCallbackIndex('%s-smatch',lang);
         if ( pi ) {
            if (_pmdebug) {
               isay(depth, "_find_matching_paren@"__LINE__": using language specific callback function: "name_name(pi));
            }
            return(call_index(lang,pi));
         }
         /* Try to match begin/end language pair */
         old_col=p_col;
         old_hex_field:=p_hex_field;
         old_hex_nibble:=p_hex_nibble;
         save_search(auto searchstring,auto options,auto word_re);
         // for not special case languages with preprocessing
         switch (lang) {
         case 'c':
         case 'java':
         case 'cs':
         case 'e':
         case 'd':
            //word_chars=PMATCH_CHARS;
            word_chars=p_word_chars:+'#';
            break;
         default:
            word_chars=p_word_chars;
         }
//#define PMATCH_CHARS 'a-zA-Z0-9_$#'
         //word_chars=PMATCH_CHARS;
         pi = _FindLanguageCallbackIndex('_%s_find_matching_word', lang);
         if (pi) {
            if (_pmdebug) {
               isay(depth, "_find_matching_paren@"__LINE__": using language specific callback function: "name_name(pi));
            }
            pirc := call_index(quiet,pmatch_max_diff_ksize,pmatch_max_level,pi);
            if (!pirc) {
               //Match was found in the _ext_find_matching_word
               return(pirc);
            }
            return(1);
         }

         beginEndPairs := LanguageSettings.getBeginEndPairs(lang);
         // Microsoft Visual Test uses a `$if
         if (pos("'",beginEndPairs)) {
            word_chars :+= "'";
         }
         search('['word_chars']:1,300|^','@rhe-');       /* Find the word. */ /* rev2a */
         word=get_match_text();
         restore_search(searchstring,options,word_re);
         if ( _file_eq(lang,'cmd') && p_LangId == 'e' ) {
            lang=substr(_macro_ext,2);
         }
         parse beginEndPairs with beginEndPairs ';' ignore_case;
         if (upcase(ignore_case) != 'I') ignore_case = '';
         beginEndPairs=' 'beginEndPairs' ';
         if (_pmdebug) {
            isay(depth, "_find_matching_paren H"__LINE__": beginEndPairs="beginEndPairs);
            isay(depth, "_find_matching_paren H"__LINE__": word_chars="word_chars);
            isay(depth, "_find_matching_paren H"__LINE__": ignore_case="ignore_case);
            isay(depth, "_find_matching_paren H"__LINE__": word="word);
         }
         i := pos('('word')',beginEndPairs,1,ignore_case);
         if ( ! i ) {
            p_col=old_col;
            p_hex_field=old_hex_field;
            p_hex_nibble=old_hex_nibble;

            // Support for matching in any extension:
            if (!quiet) {
               message(nls('Not on begin/end or paren pair'));
            }
            return(1);
         }

         start_col := lastpos(' ',beginEndPairs,i,ignore_case);
         match_re := substr(beginEndPairs,start_col+1,pos(' ',beginEndPairs,i)-start_col-1);
         if ( ignore_case!='' ) {
            parse upcase(match_re) with (upcase(word)) '|' word;
         } else {
            parse match_re with (word) '|' word;
         }
         direction := "";
         if ( word =='' ) {
            direction='-'ignore_case'w=['word_chars']';
         } else {
            direction=ignore_case'w=['word_chars']';
         }
         return match_paren(pmatch_max_diff_ksize,pmatch_max_level,match_re,direction,ignore_case,"",quiet,alwaysUpdate,matchAllParens, initialNestLevel,depth+1);

      } else {
         // try the language specific find-matching paren from the original
         // cursor position before falling back to generic case
         // This helps with cases like this:
         //
         //    if (true) { return 1; }if(false) { return 0; }
         //                           ^ cursor here
         //
         //    <p> (something)</p>
         //                   ^ cursor here
         //
         pi := _FindLanguageCallbackIndex('_%s_find_matching_word', lang);
         if (pi) {
            if (_pmdebug) {
               isay(depth, "_find_matching_paren@"__LINE__": using language specific callback function: "name_name(pi));
            }
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            save_pos(auto before_find_matching_word);
            restore_pos(orig_pos);
            orig_offset := _QROffset();
            pirc := call_index(p!=0,pmatch_max_diff_ksize,pmatch_max_level,pi);
            if (!pirc && _QROffset() != orig_offset) {
               //Match was found in the _ext_find_matching_word
               return(pirc);
            }
            restore_pos(before_find_matching_word);
            restore_search(s1,s2,s3,s4,s5);
         }
      }
      status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','-','',substr(def_pmatch_chars,p-1,1),quiet,alwaysUpdate,matchAllParens, initialNestLevel,depth+1);
   }
   if (status) {
      restore_pos(orig_pos);
      return(status);
   }
   /*
      Refreshing the scroll position when in hidden lines will change
      the line number.  
   */
   if (_lineflags() & HIDDEN_LF) return(0);
   col := p_col;
   _begin_line();_refresh_scroll();p_col=col;
   return(0);
}

/**
 * Finds the parenthesis that matches the parenthesis the cursor is on.
 * The supported parenthesis pairs are [], {}, and ().  This command also
 * matches begin/end structures for the languages C, C++, Pascal, REXX, AWK,
 * Assembly, Modula-2, Clipper, and Slick-C&reg;.  To add begin/end structure
 * matching for another language see <b>Extension Options dialog box</b>.
 *  
 * @param quiet            quiet mode, no message even if paren match fails 
 * @param matchAllParens   use slower paren matching that searches for and 
 *                         checks all parenthesis pairs in the search, which
 *                         is slower but more strict 
 *  
 * @return  Returns 0 if match found.  Common return codes are
 * TOO_MANY_SELECTIONS_RC and STRING_NOT_FOUND_RC.
 *
 * @see keyin_match_paren
 * @see def_pmatch_chars 
 * @see def_pmatch_style 
 * @see def_pmatch_style2 
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int find_matching_paren(bool quiet=false, bool matchAllParens=false) name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(_find_matching_paren(MAXINT,quiet,MAXINT,true,matchAllParens));
}

/**
 * Perform {@link find_matching_paren} with debug messages enabled.
 */
_command int trace_find_matching_paren(bool quiet=false, bool matchAllParens=false) name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   orig_pmdebug := _pmdebug;
   _pmdebug = true;
   say("trace_find_matching_paren: =========================================");
   result := _find_matching_paren(MAXINT, quiet, MAXINT, alwaysUpdate:true, matchAllParens);
   _pmdebug = orig_pmdebug;
   say("trace_find_matching_paren: result="result"===================================");
   return result;
}


static bool paren_color_matches(int color1, int color2)
{
   if ((color1 == CFG_PUNCTUATION || color1 == CFG_OPERATOR || color1 == CFG_WINDOW_TEXT) &&
       (color2 == CFG_PUNCTUATION || color2 == CFG_OPERATOR || color2 == CFG_WINDOW_TEXT)) {
      return true;
   }
   return (color1 == color2);
}

static int match_paren(int pmatch_max_diff_ksize,
                       int pmatch_max_level,
                       _str pattern,
                       _str direction,
                       _str ignore_case="",
                       _str matchchar="",
                       bool quiet=false,
                       bool alwaysUpdate=true,
                       bool matchAllParens=false, 
                       int initialNestLevel = 0,
                       int depth=1)
{
   color := 0;
   if (p_lexer_name!='') {
      color=_clex_find(0,'g');
   }

   /* Assume that cursor is on ) or ] or } */
   /* Find matching begin paren */
   mark := _alloc_selection();
   if ( mark<0 ) {
      if (!quiet) {
         message(get_message(mark));
      }
      return(mark);
   }
   _select_char(mark);

   nest_level := initialNestLevel;
   orig_char  := get_text();
   new_level  := "";
   pattern_re := "";
   before := after := "";
   bc := ec := "";
   save_search(auto searchstring,auto options,auto word_re);

   if ( pattern!='' ) {
      pattern_re=translate(pattern,'|',',');
      parse pattern with before '|' after;
      if ( substr(direction,1,1):=='-' ) {
         new_level=translate(after,'|',',');
      } else {
         new_level=translate(before,'|',',');
      }
      pattern_re=stranslate(pattern_re,'\#','#');
      pattern_re=stranslate(pattern_re,'\@','@');
      // Microsoft Visual Test uses a $
      pattern_re=stranslate(pattern_re,'\$','$');

      //Allow a space between the # and other item.
      pattern_re=stranslate(pattern_re,'(\#|\#:b)','\#');

      // If the pattern contains a space, allow multiples
      pattern_re = stranslate(pattern_re,'(:b)',' ');

      bc='(';
      ec=')';
   } else {

      /* only match paren pair. */
      temp := def_pmatch_chars;
      i := pos(matchchar,temp);
      if ( !i ) {
         new_level=orig_char;
      } else if ( i%2 ) {
         new_level=substr(temp,i+1,1);
      } else {
         new_level=substr(temp,i-1,1);
      }
      pattern_re='[\'matchchar'\'new_level']';
      /* Match all parens, special case searching for < and >, example: if ((a<b) && (c>d)) {} */
      if ( (matchAllParens || def_pmatch_style || pos(matchchar,"<>")) && pos(matchchar,"()[]{}<>")) { 
         pattern_re = "[";
         if (pos("()", temp)) new_level :+= ((direction!='-')? "(" : ")" );
         if (pos("[]", temp)) new_level :+= ((direction!='-')? "[" : "]");
         if (pos("{}", temp)) new_level :+= ((direction!='-')? "{" : "}" );
         if (pos("()", temp)) pattern_re :+= "()";
         if (pos("[]", temp)) pattern_re :+= "\\[\\]";
         if (pos("{}", temp)) pattern_re :+= "{}";
         if (pos(matchchar,"<>")) {
            new_level :+= ((direction!='-')? "<" : ">" );
            pattern_re :+= "<>";
         }
         pattern_re :+= "]";
      }
      bc='';ec='';
   }

   if (_pmdebug) {
      isay(nest_level+depth, "match_paren: pattern_re="pattern_re);
   }

   // use color coding search to more quickly skip over instances 
   // in strings and comments
   excludes := "";
   switch (color) {
   case CFG_STRING:
   case CFG_COMMENT:
      break;
   default:
      if (p_lexer_name != 'PL/I') {
         excludes = "Xcs"; 
      }
   }

   orig_embeddedLexerName := p_EmbeddedLexerName;
   typeless seekStart = point();
   status := search(pattern_re,'@rhe'direction:+excludes);
   for (;;) {
      if ( status ) {
         break;
      }

      // check if we landed in embedded code and skip over it unless we
      // started in embedded code also
      if (p_EmbeddedLexerName != orig_embeddedLexerName) {
         if (orig_embeddedLexerName == "") {
            if (direction == "") {
               status = _clex_find(0,'S');
               if (status < 0) continue;
            }
            status=repeat_search();
            continue;
         }
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // workaround for matching pl/i begin/end pairs regardless of whether they
      // are identified as preprocessor keywords or not
      if (color!=0 && !paren_color_matches(color,_clex_find(0,'g')) && 
          (p_lexer_name != 'PL/I' || (color != CFG_COMMENT && _clex_find(0,'g') == CFG_COMMENT))) {
         status=repeat_search();
         continue;
      }

      // get the character found
      ch := get_match_text();
      if (_pmdebug) {
         isay(nest_level+depth, "match_paren: ch="ch"= line="p_RLine" col="p_col);
      }

      // special case for ->, >>, or >=
      if ( ch=='>') {
         switch ( get_text_left() ) {
         case '-':
         case '>':
         case '=':
            status=repeat_search();
            continue;
         }
         switch ( get_text_right() ) {
         case '>':
         case '=':
            status=repeat_search();
            continue;
         }
      }
      // special case for <<, <=
      if ( ch=='<') {
         switch ( get_text_left() ) {
         case '>':
         case '=':
            status=repeat_search();
            continue;
         }
         switch ( get_text_right() ) {
         case '>':
         case '=':
            status=repeat_search();
            continue;
         }
      }

      match_text := bc:+ch:+ec;

      // collapse multiple spaces to a single space
      match_text = stranslate(match_text,' ',':b','r');

      // account for the space after the #
      match_text = stranslate(match_text,'#','# ');

      if ( pos(match_text,new_level,1,ignore_case) ) { /* new level ? */
         if (_pmdebug) {
            isay(nest_level+depth, "match_paren: NEW LEVEL, match_text="match_text);
         }
         nest_level++;
         if (nest_level > pmatch_max_level) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
         // check if we hit our timeout
         if (!alwaysUpdate && _CheckTimeout()) {
            status = CMRC_TIMEOUT;
            break;
         }
      } else {
         if (_pmdebug) {
            isay(nest_level+depth, "match_paren: CLOSE LEVEL, match_text="match_text);
         }
         nest_level--;
         if ( nest_level <= 0 ) break;
      }
      // Only enforce matching limit for (), {}, and []:
      // We want to support #if/#endif matching entire file.
      if ( bc == '' ) {
         typeless start="";
         parse point() with start .;
         if ( abs(start - seekStart) > (pmatch_max_diff_ksize*1024) ) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
      }
      status=repeat_search();
   }

   // verify that we landed on the character we expected
   if (!status && matchchar!='' && get_text()!=matchchar) {
      status = STRING_NOT_FOUND_RC;
   }
   if ( status ) {
      /* restore original cursor position */
      _begin_select(mark);
      if (!quiet && !_macro('r')) {
         message(nls('Match not found'));
      }
   }
   if (!quiet && !status && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
   _free_selection(mark);
   restore_search(searchstring,options,word_re);
   return(status);
}

/**
 * Amount of time to wait before finding the matching paren
 * or block under the cursor and highlighting it.
 *
 * @default 200 ms
 * @categories Configuration_Variables
 * 
 * @see def_highlight_matching_parens
 * @see _UpdateShowMatchingParen()
 */
int def_match_paren_idle=200;
/** 
 * Give up on finding matching parens after this amount of time. 
 *
 * @default 1000 ms
 * @categories Configuration_Variables
 * 
 * @see def_highlight_matching_parens
 * @see _UpdateShowMatchingParen()
 */
int def_match_paren_timeout=1000;
/**
 * Highlight matching parentheses, braces, brackets,
 * and begin/end pairs under the cursor.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_highlight_matching_parens=true;

/**
 * If parentheses highlighting is enabled, this setting
 * determines whether or not to highlight the item
 * under the cursor.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_highlight_paren_under_cursor=true;

static int gBlockMatchingPicType=-1;
static int gBlockMatchingNumPics=0;
static int gBlockMatchingEmbedded=-1;
static int gBlockMatchingCurrentLine=-1;
static int gBlockMatchingCurrentLineEmbedded=-1;
definit()
{
   _pmdebug = false;
   gBlockMatchingPicType=-1;
   gBlockMatchingNumPics=0;
   gBlockMatchingEmbedded=-1;
   gBlockMatchingCurrentLine=-1;
   gBlockMatchingCurrentLineEmbedded=-1;
}

/**
 * @return Return the length of the item under the cursor after
 * doing find_matching_paren()
 */
static int get_matching_paren_length()
{
   // HTML or XML?
   isTag := (get_text()=='<' && (_LanguageInheritsFrom('xml') || _LanguageInheritsFrom('html') || _LanguageInheritsFrom('dtd')));
   if (get_text()=='[' && _LanguageInheritsFrom('bbc')) isTag=true;

   // C++ preprocessing, like #if?
   save_pos(auto p2);
   if (get_text()=='#' || isTag) {
      right();
   }

   // Objective-C @class/@interface/@implementation/@protocol .. @end
   in_objc_keyword := false;
   if (_LanguageInheritsFrom('m') && get_text() == '@' && _clex_find(0, 'g') == CFG_KEYWORD) {
      in_objc_keyword = true;
      right();
   }

   // try cur_word to get word length and start col
   start_col := 0;
   word := cur_word(start_col);
   start_col = _text_colc(start_col,"I");
   restore_pos(p2);

   // special case for "end if" or other sequences
   // found in Cobol, Ada, SQL, and Basic
   if (!isTag && !_LanguageInheritsFrom('lua') && lowcase(word) == "end") {
      p_col += 4;
      if (_clex_find(0, 'g')==CFG_KEYWORD) {
         keyword_col := 0;
         keyword := cur_word(keyword_col);
         word :+= ' 'keyword;
      }
      restore_pos(p2);
   }

   // calculate the length of the match item
   len := 1;
   if (word != "") {
      if (start_col==p_col) {
         len=length(word);
      } else if (get_text()=='#' || isTag) {
         len=start_col+length(word)-p_col;
      } else if (in_objc_keyword) {
         len=start_col+length(word)-p_col;
      }
   }

   // check for '>' ending tag (']' for bbc)
   if (isTag && len > 1 &&
       (!_LanguageInheritsFrom('bbc') && _last_char(get_text(len+1))=='>') ||
       ( _LanguageInheritsFrom('bbc') && _last_char(get_text(len+1))==']')) {
      ++len;
   }

   // that's all folks
   return len;
}

/**
 * Update the set of highlighted parentheses, braces,
 * brackets, or begin/end pairs under the cursor.
 * 
 * @param alwaysUpdate  Update immediately, or only if idle
 * 
 * @see def_highlight_matching_parens
 * @see def_match_paren_idle
 * @categories Miscellaneous_Functions
 */
void _UpdateShowMatchingParen(bool alwaysUpdate=false)
{
   // no child windows?
   if (_no_child_windows()) {
      return;
   }
   // option disabled?
   if (!def_highlight_matching_parens) {
      _RemoveMatchingParenMarkers();
      return;
   }

   // switch to MDI editor control
   orig_wid := p_window_id;
   p_window_id = _mdi.p_child;

   // this is where the cursor was last time
   static long last_seekpos;
   static int last_bufid;
   if (last_seekpos == _QROffset() && last_bufid==p_buf_id) {
      p_window_id = orig_wid;
      return;
   }
   // idle time not reached?
   if (!alwaysUpdate && (_idle_time_elapsed() < def_match_paren_idle)) {
      // this is where the cursor was last time
      if (gBlockMatchingNumPics > 0) {
         if (last_seekpos != _QROffset() || last_bufid!=p_buf_id) {
            gBlockMatchingNumPics=0;
            _StreamMarkerRemoveAllType(gBlockMatchingPicType);
            refresh();
         }
      }
      p_window_id = orig_wid;
      return;
   }
   // save position and search information
   _str orig_line=point();
   orig_offset := _QROffset();
   /*
      Scrolling and doing things which restore scroll position
      like save_pos()/restore_pos() can be very slow with long
      softwrapped lines. 

      Here we temporarily turn off soft wrap and use 
      _save_pos2()/_restore_pos2() to quickly restore
      the scroll position.
   */
   _save_pos2(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   orig_SoftWrap:=p_SoftWrap;p_SoftWrap=false;

   // out with the old, in with the new_color
   if (gBlockMatchingPicType <= 0) {
      gBlockMatchingPicType = _MarkerTypeAlloc();
   } else {
      _StreamMarkerRemoveAllType(gBlockMatchingPicType);
      gBlockMatchingNumPics=0;
   }

   // workaround in order to support block matching color in embedded code.
   if (gBlockMatchingEmbedded <= 0 || 
       _default_color(gBlockMatchingEmbedded) != _default_color(-CFG_BLOCK_MATCHING)) {
      typeless fg, bg, ff;
      parse _default_color(-CFG_BLOCK_MATCHING) with fg bg ff;
      if (ff & F_INHERIT_BG_COLOR) {
         ff &= ~F_INHERIT_BG_COLOR;
         parse _default_color(-CFG_WINDOW_TEXT) with . bg .;
      }
      if (gBlockMatchingEmbedded<=0) {
         gBlockMatchingEmbedded = _AllocColor();
      }
      typeless old_fg, old_bg, old_ff;
      parse _default_color(gBlockMatchingEmbedded) with old_fg old_bg old_ff;
      if (old_fg!=fg || old_bg!=bg || old_ff!=ff) {
         _default_color(gBlockMatchingEmbedded,fg,bg,ff);
      }
   }

   // workaround in order to support block matching color with current line color
   if (p_color_flags & CLINE_COLOR_FLAG) {
      if (gBlockMatchingCurrentLine <= 0) {
         gBlockMatchingCurrentLine = _AllocColor();
      }
      typeless fg, bg, ff;
      parse _default_color(CFG_BLOCK_MATCHING) with fg bg ff;
      if (ff & F_INHERIT_BG_COLOR) {
         ff &= ~F_INHERIT_BG_COLOR;
         parse _default_color(CFG_CLINE) with . bg .;
      }
      typeless old_fg, old_bg, old_ff;
      parse _default_color(gBlockMatchingCurrentLine) with old_fg old_bg old_ff;

      if (old_fg!=fg || old_bg!=bg || old_ff!=ff) {
         _default_color(gBlockMatchingCurrentLine,fg,bg,ff);
      }
      
      if (gBlockMatchingCurrentLineEmbedded <= 0) {
         gBlockMatchingCurrentLineEmbedded = _AllocColor();
      }
      parse _default_color(-CFG_BLOCK_MATCHING) with fg bg ff;
      if (ff & F_INHERIT_BG_COLOR) {
         parse _default_color(-CFG_CLINE) with . bg .;
         ff &= ~F_INHERIT_BG_COLOR;
      }

      parse _default_color(gBlockMatchingCurrentLineEmbedded) with old_fg old_bg old_ff;
      if (old_fg!=fg || old_bg!=bg || old_ff!=ff) {
         _default_color(gBlockMatchingCurrentLineEmbedded,fg,bg,ff);
      }
   }

   // set a time limit
   sc.lang.ScopedTimeoutGuard timeout;
   if (!alwaysUpdate) {
      _SetTimeout(def_match_paren_timeout);
   }

   // find the matching paren(s) from this position
   count := 0;
   bool been_there:[];
   for (;;) {
      // in a comment?
      if (_in_comment()) {
         break;
      }
      // attempt to find matching paren
      int status = _find_matching_paren(def_pmatch_max_diff_ksize, true, def_pmatch_max_level, alwaysUpdate);
      if (status || been_there._indexin(_QROffset())) {
         break;
      }
      // get the size of the match
      offset := _QROffset();
      len := get_matching_paren_length();
      if (def_highlight_paren_under_cursor || 
          (point() != orig_line) || orig_offset < offset || orig_offset > offset+len) {
         // add markers to do the highlighting
         int marker = _StreamMarkerAdd(p_window_id, offset, len, true, 0, gBlockMatchingPicType, null);
         if (p_EmbeddedLexerName != '') {
            if ((p_color_flags & CLINE_COLOR_FLAG) && point()==orig_line) {
               _StreamMarkerSetTextColor(marker, gBlockMatchingCurrentLineEmbedded);
            } else {
               _StreamMarkerSetTextColor(marker, gBlockMatchingEmbedded);
            }
         } else {
            if ((p_color_flags & CLINE_COLOR_FLAG) && point()==orig_line) {
               _StreamMarkerSetTextColor(marker, gBlockMatchingCurrentLine);
            } else {
               _StreamMarkerSetTextColor(marker, CFG_BLOCK_MATCHING);
            }
         }
      }
      // remember that we've been here before
      been_there:[offset]=true;
      count++;
      // check if we hit our timeout
      if (!alwaysUpdate && _CheckTimeout()) {
         break;
      }
   }

   // only found one item?
   if (count <= 1) {
      _StreamMarkerRemoveAllType(gBlockMatchingPicType);
      gBlockMatchingNumPics=0;
   } else {
      gBlockMatchingNumPics=count;
   }
   p_SoftWrap=orig_SoftWrap;
   // restore file position and window ID
   restore_search(s1,s2,s3,s4,s5);
   _restore_pos2(p);

   // save our most recent buffer position and buffer ID
   last_seekpos=_QROffset();
   last_bufid=p_buf_id;

   // refresh the MDI child window, force process events to repaint
   refresh();

   // restore the original window ID
   p_window_id = orig_wid;
}

/**
 *  Remove highlighting for matching parentheses.
 */
void _RemoveMatchingParenMarkers()
{
   if (gBlockMatchingPicType) {
      _StreamMarkerRemoveAllType(gBlockMatchingPicType);
      gBlockMatchingNumPics=0;
   }
}

int _c_find_matching_word(bool quiet,
                          int pmatch_max_diff_ksize=MAXINT,
                          int pmatch_max_level=MAXINT)
{
   save_pos(auto p);
   status := 0;
   start_col := 0;
   line := "";
   _str word;
   /*
      Since cur_identifier does not have an AT_END_USE_NEXT 
      option, move the cursor to the next word so that
      calling cur_identifier is like _cur_word().
   */
   doRestore := false;
   for (;;) {
      // stop if we are at the end of the line
      if (at_end_of_line()) break;
      // check for space or # (C/C++ preprocessing)
      ch := get_text();
      if (ch:=='#' || ch:==' ' || ch:=="\t") {
         right();
         doRestore=true;
         continue;
      }
      break;
   }
   word=cur_identifier(start_col);
   start_col=_text_colc(start_col,"P");
   if (doRestore) restore_pos(p);
   int orig_line;
   get_line_raw(orig_line);
   if (word!='' && start_col>1) {
      line=strip(substr(orig_line,1,start_col-1));
   }
   if (word!='' && start_col>1 && _last_char(line):=='#') {
      word='#':+word;
   }

   // check if we are at the start or end of a /* comment
   if ( _clex_find(0,'g')==CFG_COMMENT ) {
      onStar := (get_text()=='*');
      if ( get_text()=='/' ) right();
      if ( get_text()=='*' ) {
         _GoToROffset(_QROffset()-2);
         if ( _clex_find(0,'g')!=CFG_COMMENT ) {
            restore_pos(p);
            _clex_find(COMMENT_CLEXFLAG,'n');
            _clex_find(COMMENT_CLEXFLAG,'-o');
            if ( get_text()=='/' ) {
               if ( onStar ) left();
               return 1;
            }
         }
      }
      restore_pos(p);
      if ( get_text()=='/' ) left();
      if ( get_text()=='*' ) {
         _GoToROffset(_QROffset()+2);
         if ( _clex_find(0,'g')!=CFG_COMMENT ) {
            restore_pos(p);
            _clex_find(COMMENT_CLEXFLAG,'-n');
            _clex_find(COMMENT_CLEXFLAG,'o');
            if ( get_text()=='/' ) {
               if ( onStar ) right();
               return 1;
            }
         }
      }
      restore_pos(p);
   }

   // check if we are on a statement keyword
   if ( _clex_find(0,'g')==CFG_KEYWORD ) {

      // jump to the end of the keyword and skip spaces
      p_col=start_col+length(word);
      _clex_skip_blanks();

      switch ( word ) {
      case 'else':
         if ( _clex_find(0,'g')!=CFG_KEYWORD || get_text(2) != 'if' ) {
            return 0;
         } else {
            p_col+=2;
            _clex_skip_blanks();
         }
         // drop through to if case
      case 'if':
      case 'while':
      case 'catch':
      case 'switch':
      case 'for':
      case 'using':
         // 'using' is only in C#
         if ( word=='using' && !_LanguageInheritsFrom('cs') ) {
            restore_pos(p);
            return 1;
         }
         // skip parenthesized expression
         if ( get_text() == '(' && !match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','+','',')',true) ) {
            right();
            _clex_skip_blanks();
            if ( get_text() == '{' ) {
               right();
            }
            return 0;
         }
         break;

      case 'finally':
      case 'try':
      case 'do':
      case 'return':
      case 'throw':
      case 'goto':
      case 'loop':
      case 'yield':
      case 'co_await':
      case 'co_return':
      case 'co_yield':
         return 0;
      }

      restore_pos(p);
   }

   // try to handle simple template argument cases
   long start_offset=0, end_offset=0;
   word_chars := _clex_identifier_chars();
   if ( (get_text() == '<' || get_text_left() == '<') && 
        !_LanguageInheritsFrom('e') && 
        !_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG,'T') ) {

      // is < to the left of the cursor?
      typeless lt_pos;
      save_pos(lt_pos);
      if ( get_text() != '<' ) {
         // no fuzzy match if the actual char under the cursor is a paren 
         if (pos(get_text(), def_pmatch_chars) ) {
            restore_pos(p);
            return 1;
         }
         left();
         save_pos(lt_pos);
      }

      // make sure this isn't operator << or <=
      right();
      start_offset = _QROffset();
      if ( get_text()=='<' || get_text()=='=' ) {
         restore_pos(p);
         return 1;
      }
      // make sure that the template arguments are preceded by an identifier
      restore_pos(lt_pos);
      left();
      _clex_skip_blanks('-');
      junk := 0;
      if ( !pos('['word_chars']', get_text(), 1, 'r') ) {
         restore_pos(p);
         return 1;
      }
      // ok, now try to find the matching template punctuator
      restore_pos(lt_pos);
      if ( !match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','+','','>',true) == 0 ) {
         restore_pos(p);
         return 1;
      }
      // test what was inside of < > pair for sanity
      // if there are braces or semicolons, then this < was 
      // probably part of a conditional expression
      end_offset = _QROffset();
      if ( pos('([{};]|\&\&|\|\|)',get_text((int)(end_offset-start_offset-1),(int)start_offset),1,'r') ) {
         restore_pos(p);
         return 1;
      }
      // we have what we believe to be a template argument match
      return 0;
   }
   if ( (get_text() == '>' || get_text_left()=='>') && 
        !_LanguageInheritsFrom('e') && 
        !_clex_find(COMMENT_CLEXFLAG|STRING_CLEXFLAG,'T') ) {

      // is > to the left of the cursor?
      typeless gt_pos;
      save_pos(gt_pos);
      if ( get_text() != '>' ) {
         // no fuzzy match if the actual char under the cursor is a paren 
         if (pos(get_text(), def_pmatch_chars) ) {
            restore_pos(p);
            return 1;
         }
         left();
         save_pos(gt_pos);
      }

      // make sure this isn't ->, :>, or >>
      left();
      end_offset = _QROffset();
      if ( get_text()=='-' || get_text()==':' || get_text()=='>' ) {
         restore_pos(p);
         return 1;
      }
      // make sure this isn't >> or >=
      restore_pos(gt_pos);
      right();
      if ( get_text()=='>' || get_text()=='=' ) {
         restore_pos(p);
         return 1;
      }
      // ok, now try to find the matching template punctuator
      restore_pos(gt_pos);
      if ( match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','-','','<',true)!=0 ) {
         restore_pos(p);
         return 1;
      }
      // make sure that the template arguments are preceded by an identifier
      typeless match_p;
      save_pos(match_p);
      left();
      _clex_skip_blanks('-');
      if ( !pos('['word_chars']', get_text(), 1, 'r') ) {
         restore_pos(p);
         return 1;
      }
      // test what was inside of < > pair for sanity
      // if there are braces or semicolons, then this < was 
      // probably part of a conditional expression
      restore_pos(match_p);
      start_offset = _QROffset();
      if ( pos('([{};]|\&\&|\|\|)',get_text((int)(end_offset-start_offset-1),(int)start_offset),1,'r') ) {
         restore_pos(p);
         return 1;
      }
      // we have a match
      return 0;
   }

   typeless clex_tag=0;
   if (substr(word,1,1):=='#' && langHasPPConditions(p_LangId)) {
      clex_tag=_clex_find(0,'g');
      if (((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
         //There is a #... inside of a comment or string.
         restore_pos(p);
         if (!quiet) {
            message(nls('Not on begin/end or paren pair'));
         }
         return(1);
      }
      //If it is a preprocessor statement
      conditionals := " #if #ifdef #ifndef #elif #else ";  //Not including endif
      if (pos(' 'word' ',conditionals,1)) {
         status=next_condition(quiet);
      } else {
         status=0;
         if (pos(' 'word' ',' #define #undef #include ',1)) {
            restore_pos(p);
            if (!quiet) {
               message(nls('Not on begin/end or paren pair'));
            }
            return(1);
         }
         int i=pos(word,expand_tabs(stranslate(orig_line,'#','# ',p_rawpos)),1);
         p_col=i;
         if( word:=='#region' || word:=='#endregion' ) {
            _str direction= (word:=='#region')?('+'):('-');
            status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'(#region)|(#endregion)',direction,'','',true);
         } else if (word:=="#pragma") {
            save_pos(auto after_pragma);
            p_col=start_col+length(word);
            _clex_skip_blanks();
            next_word := cur_identifier(auto next_start_col);
            restore_pos(after_pragma);
            direction := (next_word:=='region')?('+'):('-');
            status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'(#pragma region)|(#pragma endregion)',direction,'','',true);
         } else {
            if (word:=='#endif') {
               //This includes #endif
               status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','-','','',true);
            }
            if (status) {
               status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
            }
         }
      }
      if (!status) {
         //begin_line();
         //message('Match found');
      }
   } else if (substr(word,1,1):=='@') {
      clex_tag=_clex_find(0,'g');
      if (((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
         //There is an @... inside of a comment or string.
         restore_pos(p);
         if (!quiet) {
            message(nls('Not on begin/end or paren pair'));
         }
         return(1);
      } 
      status=0;
      //If it is a preprocessor statement
      obj_c := " @class @interface @implementation @protocol @end ";
      if (pos(word,obj_c,1)) {
         _str direction=(word:=='@end')?('-'):('+');
         status = match_paren(pmatch_max_diff_ksize,pmatch_max_level,'(@class),(@interface),(@implementation),(@protocol)|(@end)',direction,'','',true);
      }
   } else {
      restore_pos(p);
      status=1;
      if (!quiet) {
         message(nls('Not on begin/end or paren pair'));
      }
   }
   return(status);
}
int _java_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _e_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}
int _cs_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return(_c_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}

static const CONDITION_EXTENSION_LIST= ' d cs e c m ansic java asm masm s unixasm ';
static const CONDITION_EXCLUSION_LIST= ' ch jsl ';

/**
 * Determines if we handle preprocessing conditionals for the given langauge.
 * 
 * @param langId 
 * 
 * @return bool
 */
bool langHasPPConditions(_str langId)
{
   // first check if this language is in our list
   if (pos(' 'langId' ', CONDITION_EXTENSION_LIST)) {
      return true;
   }

   // see if this language is in our exclusion list - we need this list because some 
   // languages inherit from languages in our list, but we still do not include them
   if (pos(' 'langId' ', CONDITION_EXCLUSION_LIST)) {
      return false;
   }

   // does this language inherit from something we are not including?
   _str langs[];
   split(CONDITION_EXCLUSION_LIST, ' ', langs);
   for (i := 0; i < langs._length(); i++) {
      if (_LanguageInheritsFrom(langs[i], langId)) return false;
   }

   // finally, check if our language inherits from one of our included languages
   split(CONDITION_EXTENSION_LIST, ' ', langs);
   for (i = 0; i < langs._length(); i++) {
      if (_LanguageInheritsFrom(langs[i], langId)) return true;
   }

   return false;
}

int _OnUpdate_next_condition(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!langHasPPConditions(p_LangId)) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

/*
 *Function Name:next_condition
 *
 *Parameters: none
 *
 *Description: This goes to the next preprocessing statement #if...#elif...#else..#endif
 *             This takes into account nesting when going to next/prev conditions.
 *
 *Returns: Returns 0 if the line is found.  Otherwise 1.
 *
 */
_command int next_condition(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if (command_state()) {
      return(1);
   }
   beginning_line := 0;
   typeless status=0;
   save_pos(auto p);
   if (!langHasPPConditions(p_LangId)) {
      beginning_line=p_line;
      status=find_matching_paren(true);
      if (p_line<beginning_line) {
         restore_pos(p);
      }
      if (quiet!=1) {
         clear_message();
      }
      return(status);
   }

   new_line := -1;
   current_line := p_line;
   save_pos(auto p2);
   word := "";
   line := "";
   junk := 0;
   
   _first_non_blank();

   //First try the fast/easy way:
   new_line=find_next_condition('+');
   if (new_line<0) {
      //If that fails, we need to do the "hard" work:

      //This takes the place of having to change p_word_chars
      word=cur_word(junk);
      get_line_raw(line);
      if (word!='' && junk>1) {
         line=strip(substr(line,1,junk-1));
      }
      if (_last_char(line):=='#') {
         word='#':+word;
      }

      switch (word) {
      case '#if':
      case '#ifdef':
      case '#ifndef':
         new_line=find_condition('elif', word, '+');
         if (new_line<0) {
            //didn't find the elif, try something else
            new_line=find_condition('else', word, '+');
         }
         if (new_line<0) {
            //look for a matching endif
            new_line=find_condition('endif', word, '+');
         }
         if (new_line<0) {
            //Last ditch effort to find something.
            status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
            if (status) {
               restore_pos(p2);
               if (quiet!=1) {
                  message('No enclosing preprocesser directives found.');
               }
               return(status);
            }
            new_line=p_line;
            p_line=current_line;
         }
         break;
      case '#else':
         new_line=find_condition('endif', word, '+');
         break;
      case '#elif':
      case '#endif':
      default:
         new_line=find_condition('endif', word, '+');
         if (new_line<0) {
            new_line=find_condition('elif', word, '+');
         }
         if (new_line<0) {
            new_line=find_condition('else', word, '+');
         }
         if (new_line<0) {
            new_line=find_next_condition('+');
         }
         break;
      }
   }
   restore_pos(p2);
   if (new_line>0) {
      p_line=new_line;
   } else {
      restore_pos(p);
      if (quiet!=1) {
         message('No enclosing conditional statement found.');
      }
      return(1);
   }
   _first_non_blank();
   //begin_line();
   //message('Matching conditional statement found.');
   return(0);
}

int _OnUpdate_prev_condition(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_next_condition(cmdui,target_wid,command));
}
/*
 *Function Name:prev_condition
 *
 *Parameters: none
 *
 *Description: This goes to the prev preprocessing statement #if...#elif...#else..#endif
 *
 *Returns: Returns 0 if the line is found.  Otherwise 1.
 *
 */
_command int prev_condition(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if (command_state()) {
      return(1);
   }

   beginning_line := 0;
   typeless status=0;
   save_pos(auto p);
   if (!langHasPPConditions(p_LangId)) {
      beginning_line=p_line;
      status=find_matching_paren(true);
      if (p_line>beginning_line) {
         restore_pos(p);
      }
      if (quiet!=1) {
         clear_message();
      }
      return(status);
   }

   new_line := -1;
   current_line := p_line;
   junk := 0;
   save_pos(auto p2);
   _first_non_blank();
   word := "";
   line := "";

   //First try the easy/fast way:
   new_line=find_next_condition('-');
   if (new_line<0) {
      //If that fails, we need to do the "hard" work:

      word=cur_word(junk);

      //This takes the place of having to change p_word_chars
      get_line_raw(line);
      if (word!='' && junk>1) {
         line=strip(substr(line,1,junk-1));
      }
      if (_last_char(line):=='#') {
         word='#':+word;
      }

      switch (word) {
      case '#elif':
      case '#else':
         new_line=find_condition('elif', word, '-');
         if (new_line<0) {
            new_line=find_condition('if', word, '-');
         }
         break;
      case '#endif':
         new_line=find_condition('else', word, '-');
         if (new_line<0) {
            new_line=find_condition('elif', word, '-');
         }
         if (new_line<0) {
            status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
            if (status) {
               restore_pos(p2);
               if (quiet!=1) {
                  message('No enclosing preprocesser directives found.');
               }
               return(status);
            }
            new_line=p_line;
            p_line=current_line;
         }
         break;
      case '#if':
      default:
         new_line=find_condition('if', word, '-');
         if (new_line<0) {
            new_line=find_condition('elif', word, '-');
         }
         if (new_line<0) {
            new_line=find_condition('else', word, '-');
         }
         if (new_line<0) {
            new_line=find_next_condition('-');
         }
         break;
      }
   }

   restore_pos(p2);
   if (new_line>0) {
      p_line=new_line;
   } else {
      restore_pos(p);
      if (quiet!=1) {
         message('No enclosing conditional statement found.');
      }
      return(1);
   }
   _first_non_blank();
   //begin_line();
   //message('Matching conditional statement found.');
   return(0);
}

/*
 *Function Name:find_condition
 *
 *Parameters: String condition what we're looking for
 *            String direction where we're headed
 *
 *Description: locates the next/prev ocurrance of the condition (if exists)
 *
 *Returns: a line number if it is found.  Otherwise -1
 *
 */

static int find_condition(_str condition, _str word, _str direction='+')
{
   //say('find_condition condition='condition' word='word' direction='direction);
   prepend_string := '^[ \t]*\#[ \t]*';
   condition_line := -1;

   current_line := p_line;

   lang := p_LangId;

   utf8 := p_UTF8;
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=utf8;  // Use the same utf8 mode of the source file
   _SetEditorLanguage(lang);
   activate_window(orig_view_id);

   start_line := p_line;
   ifword := (word:=='#if')||(word:=='#ifdef')||(word:=='#ifndef');
   if ((ifword && direction:=='-') || (word:=='#endif' && direction:=='+')) {
      //This case is handled in find_next_condition();
      return(condition_line);
   }

   line := "";
   i := 0;
   last_line := 0;
   typeless clex_tag=0;
   typeless status=0;
   if (ifword || word:=='#endif') {
      //This is easy:
      _first_non_blank(); p_col++;
      status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
      if (status) {
         clear_message();
         activate_window(orig_view_id);
         _delete_temp_view(temp_view_id);
         p_line=current_line;
         return(condition_line);
      }
      last_line=p_line;
      insert_code_block(start_line, last_line, orig_view_id, temp_view_id);
   } else {
      //We have to work to get the #if...#endif block
      //This starts on the next line, which is OK.
      while (!down()) {
         get_line(line);
         i=pos(prepend_string'if',line,1,'r');  //Look for #if on the line
         _first_non_blank();  //p_col=i;
         clex_tag=_clex_find(0,'g');
         if (i && !((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
            //we need to skip over this #if...#endif section.
            status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
            if (status) {
               //This is a bad code section
               clear_message();
               activate_window(orig_view_id);
               _delete_temp_view(temp_view_id);
               p_line=current_line;
               return(condition_line);
            }
         } else {
            i=pos(prepend_string'endif',line,1,'r');
            _first_non_blank();  //p_col=i;
            clex_tag=_clex_find(0,'g');
            if (i && !((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
               //This is what we are looking for.
               last_line=p_line;
               status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
               if (status) {
                  clear_message();
                  activate_window(orig_view_id);
                  _delete_temp_view(temp_view_id);
                  p_line=current_line;
                  return(condition_line);
               }
               start_line=p_line;
               //messageNwait('about to insert_code start_line='start_line' last_line='last_line' current_line='current_line);
               insert_code_block(start_line, last_line, orig_view_id, temp_view_id);
               break;
            }
         }
      }
   }
   /*
     At this point, we have the #if...#endif block in temp_view_id
     The vars at this point are:

         current_line -- The line in the actual file that has the code section
         start_line   -- The line with the #if
         last_line     -- The line with the #endif

            start line is always before or equal to current line
            last_line is always after current_line.
            i.e. current_line can be the same value as start_line, but never smaller.

         condition_line-- Still -1 (default)
         temp_view_id -- Temp view with the #if...#endif block
         orig_view_id -- The original view id

         condition    -- What I'm looking for
         word         -- The word that the editor was on when this was called
                         (not used further in this function).
         direction    -- The direction I'm searching in.

      New variable:

         padded       -- The number of lines that get compressed (array).
         msg          -- Text flag
         count        -- Number of embedded blocks
   */


   int padded[];
   //padded._makeempty();
   padded=null;

   //Get rid of the lines that I don't need:
   msg := "This is a SlickEdit marker.  --  ";
   count := -1;

   int difference = current_line-start_line;
   if (difference<0) {
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
      p_line=current_line;
      return(condition_line);
   }

   if (p_window_id!=temp_view_id) {
      activate_window(temp_view_id);
   }
   //This will compress any nested #if...#endif blocks...
   pos1 := 0;
   pos2 := 0;
   p_line=1;
   while (!down()) {
      get_line(line);
      i=pos(prepend_string'if',line,1,'r');
      if (i) {
         _first_non_blank();  //p_col=i;
         clex_tag=_clex_find(0,'g');
         if (!((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
            pos1=p_line;
            _first_non_blank();
            status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
            clear_message();
            pos2=p_line;
            for (p_line=pos2;p_line>=pos1;p_line--) {
               _delete_line();
            }
            count++;
            padded[count]=pos2-pos1;
            insert_line(msg:+count);
         }
      }
   }
   //Now we just have the code that we are working with.

#if 0
   if (p_window_id!=temp_view_id) {
      activate_window(temp_view_id);
   }
   _str filename=_temp_path():+'find_':+condition;
   p_buf_name=filename;
   _save_file('+o');
#endif

   typeless p=0;
   typeless a,b,c,d;
   typeless index=0;
   if (count>=0) {
      //This is really to set the correct line.
      save_pos(p);
      p_line=difference;
      save_search(a,b,c,d);
      status=search(msg,'-@h');
      restore_search(a,b,c,d);
      if (!status) {
         get_line(line);
         parse line with . '--' index;
         x := 0;
         for (x=0;x<=index;x++) {
            difference-=padded[count];
         }
      }
      restore_pos(p);
   }
   if (difference<0) {
      difference=current_line-start_line;
   }
   if (direction:=='+') {
      p_line=difference+1;
   } else {
      p_line=difference;
   }

   //Find what I'm looking for.
   save_search(a,b,c,d);
   status=search(prepend_string:+condition,'rh@XCS':+direction);
   restore_search(a,b,c,d);

   //messageNwait('status='status' direction='direction' p_line='p_line);
   if (status) {
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
      p_line=current_line;
      return(condition_line);
   }
   //Otherwise, this is the line.
   unadjusted_line := p_line;  //We add padded[] to this, and get the real line #
   if (count>=0) {
      save_search(a,b,c,d);
      status=search(msg,'-<@h');
      restore_search(a,b,c,d);
      if (!status) {
         get_line(line);
         parse line with . '--' index;
         for (i=index;i>=0;i--) {
            unadjusted_line+=padded[i];
         }
      }
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   condition_line=unadjusted_line+start_line-1;
   p_line=current_line;
   //say('find_condition condition_line='condition_line);
   return(condition_line);
}

//This inserts the partial contents of orig_view_id into temp_view_id
static void insert_code_block(var start_line, var last_line, int orig_view_id, int temp_view_id)
{
   if (start_line>last_line) {
      int temp=start_line;
      start_line=last_line;
      last_line=temp;
   }
   //messageNwait(nls('insert_code_block start_line=%s, last_line=%s, orig_view_id=%d, temp_view_id=%s',start_line, last_line, orig_view_id, temp_view_id));
   p_line=start_line;
   while (p_line<=last_line) {
      line := "";
      get_line(line);
      activate_window(temp_view_id);
      bottom();
      insert_line(line);
      activate_window(orig_view_id);
      if (down()) {
         break;
      }
   }
   p_line=start_line;
}

/*
 *Function Name:find_next_condition
 *
 *Parameters: String direction where we're headed
 *
 *Description: locates the next/prev ocurrance of any condition (if exists)
 *
 *Returns: a line number if it is found.  Otherwise -1
 *
 */

static int find_next_condition(_str direction='+')
{
   save_pos(auto p2);
   condition_line := -1;
   if (!_in_c_preprocessing_specific()) {
      restore_pos(p2);
      return(condition_line);
   }
   prepend_string := '^[ \t]*\#[ \t]*';
   search_string := prepend_string:+'(elif|else|endif|if)';  //Matches ifdef/ifndef too
   typeless status=0;
   save_search(auto a,auto b,auto c,auto d);
   if (direction:=='+') {
      search(':b|\n','r@h');  //we need to be at the end of the word or line.
      status=search(search_string,'+rh<@XCS');
   } else {
      up(); _end_line();
      status=search(search_string,'-rh<@XCS');
   }
   //Can't call restore_search() yet b/c it may throw repeat_search() off later.
   if (status) {
      restore_search(a,b,c,d);
      restore_pos(p2);
      return(condition_line);
   }
   typeless e,f,g,h;
   clex_tag := 0;
   i := 0;
   line := "";
   while (!status) {
      get_line(line);
      if (direction:=='+') {
         i=pos(prepend_string:+'if',line,1,'r');
         if (i) {
            _first_non_blank();
            clex_tag=_clex_find(0,'g');
            if (!((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
               //There is a save/restore_search in match_paren, but it still throws this off.
               save_search(e,f,g,h);
               status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','+','','',true);
               restore_search(e,f,g,h);
               if (status) {
                  restore_search(a,b,c,d);
                  restore_pos(p2);
                  return(condition_line);
               }
            }
         } else {
            break;
         }
      } else {
         //direction == '-'
         i=pos(prepend_string:+'endif',line,1,'r');
         if (i) {
            _first_non_blank();
            clex_tag=_clex_find(0,'g');
            if (!((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
               save_search(e,f,g,h);
               status=match_paren(def_pmatch_max_diff_ksize,def_pmatch_max_level,'(#ifdef),(#ifndef),(#if)|(#endif)','-','','',true);
               restore_search(e,f,g,h);
               if (status) {
                  restore_search(a,b,c,d);
                  restore_pos(p2);
                  return(condition_line);
               }
            }
            //Don't want to match the #if of the skipped block
            up(); _end_line();
         } else {
            break;
         }
      }
      status=repeat_search();
   }
   restore_search(a,b,c,d);
   if (status) {
      restore_pos(p2);
      return(condition_line);
   }
   condition_line=p_line;
   restore_pos(p2);
   return(condition_line);
}

//More tailored version of _in_c_preprocessing()
static bool _in_c_preprocessing_specific()
{
   prepend_string := '^[ \t]*\#[ \t]*';
   exclude_words := prepend_string:+'(define|undef|include)';  //This is a regex string format: (xxx|yyy)
   save_pos(auto p);
   line := "";
   get_line(line);line=strip(line,'L');
   clex_tag := 0;
   i := pos(prepend_string:+'endif',line,1,'r');
   if (i) {
      _first_non_blank();  //p_col=i;
      clex_tag=_clex_find(0,'g');
      if (!((clex_tag==CFG_COMMENT) || (clex_tag==CFG_STRING))) {
         restore_pos(p);
         return(true);
      }
   }

   search_string := "";
   for (;;) {
      get_line(line);line=strip(line,'L');
      if (substr(line,1,1)=="#" && !pos(exclude_words,line,1,'r')) {
         if (pos(prepend_string:+'endif',line,1,'r')) {
            down();
            search_string=prepend_string:+'(elif|else|endif|if)';
            save_search(auto a,auto b,auto c,auto d);
            status := search(search_string,'rh@');
            restore_search(a,b,c,d);
            if (status) {
               restore_pos(p);
               return(false);
            }
            get_line(line);
            // DJB 11-23-2005
            // This check is invalid because the #endif ... #if could be parts
            // two #if blocks nested within an outer #if block.
            // 
            // if (pos(prepend_string:+'if',line,1,'r')) {
            //    //In this case, we hit a #endif...#if section, i.e. we're not in a block.
            //    restore_pos(p);
            //    return(false);
            // }
            //In this case, we hit a #endif...#something else, i.e. we're in a block.
            restore_pos(p);
            return(true);
         }
         restore_pos(p);
         return(true);
      }
      up();
      if (_on_line0()) {
         restore_pos(p);
         return(false);
      }
   }
}

_command int select_paren_block() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(show_matching_paren('y',false));
}

/**   
 * Searches for the closest open parenthesis [, {, or ( that is at or 
 * before the cursor location and then temporarily places the cursor on 
 * the matching end parenthesis for a short period of time. 
 *
 * @see find_matching_paren
 * @see keyin_match_paren
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 *
 */
_command int show_matching_paren(_str select_block='',bool search_backward=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int pmatch_max_diff_ksize=MAXINT;
   int pmatch_max_level=MAXINT;
   quiet := false;
   int status;
   typeless orig_pos;
   save_pos(orig_pos);
   ch := get_text();
   p := pos(ch,def_pmatch_chars);
   // IF we are NOT sitting on a paren/brace character
   if (!p) {
      // Search backward for open or close paren
      int orig_color=_clex_find(0,'g');
      status=1;
      if (search_backward) {
         status=search('['_escape_re_chars(def_pmatch_chars)']','-rh@xcs');
      }
      if (status) {
         status=search('['_escape_re_chars(def_pmatch_chars)']','rh@xcs');
         if (status) {
            message(nls('Not on begin/end or paren pair'));
            return(status);
         }
      }
      ch=get_text();
      p=pos(ch,def_pmatch_chars);
#if 0
      if (!status) {
         color_options := "xcs";
         // This is not a perfect algorithm because we could have gone
         // out and back into string/comment color.
         int new_color=_clex_find(0,'g');
         if (orig_color==CFG_STRING && new_color==orig_color) {
            color_options='cs';
         } else if (orig_color==CFG_STRING && new_color==orig_color) {
            color_options='cc';
         }

      }
#endif
   }
   typeless new_pos=0;
   typeless start_pos;
   save_pos(start_pos);
   if ( p%2 ) {   /* begin paren? */
      status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','','',substr(def_pmatch_chars,p+1,1),quiet,true,false);
   } else {
      status=match_paren(pmatch_max_diff_ksize,pmatch_max_level,'','-','',substr(def_pmatch_chars,p-1,1),quiet,true,false);
   }
   if (!status) {
      if (select_block!='') {
         /* On begin paren? */
         if (p%2) {
            save_pos(new_pos);
            // go back to the begin paren
            restore_pos(start_pos);
         } else {
            new_pos=start_pos;
         }
         mark := "";
         _deselect(mark);
         _select_char(mark,translate(def_select_style,'I','N'));
         restore_pos(new_pos);
         _select_char(mark,translate(def_select_style,'I','N'));
         _cua_select=1;
      } else {
         typeless old_mark=_duplicate_selection('');
         int temp_mark=_alloc_selection();
         if ( temp_mark<0 ) {
            return(temp_mark);
         }
         _show_selection(temp_mark);
         _select_block(temp_mark);
         refresh();
         delay(100,'k');

         _show_selection(old_mark);
         _free_selection(temp_mark);
      }
   }
   if (select_block=='' || status) {
      restore_pos(orig_pos);
   }
   return(status);
}
