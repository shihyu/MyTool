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
#import "adaptiveformatting.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "mouse.e"
#import "notifications.e"
#import "pascal.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "se/tags/TaggingGuard.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  To install this package, perform the following steps.

    -  Load this macro module with LOAD command.  The ST.EXE
       compiler will automatically get invoked if necessary.
    -  Save the configuration. {CONFIG,Save configuration...}

  Options for FORTRAN syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 0.
       3             reserved.
       4             reserved
       5             Multi-line if expansion.  Defaults to 0.

*/

/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _for_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}
static const FOR_LANGUAGE_ID= "for";

/**
 * If enabled, Fortran syntax expansion will work properly
 * with Fortran 90 with free form indentation.  Otherwise,
 * the indentation will always be forced to at least column 7,
 * in order to leave room for line numbers.
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_fortran_free_form_indent=1;
/**
 * If enabled, Fortran syntax expansion will create multiple cursors 
 * when expanding declartions where the name is expected both at the 
 * beginning and end of the declaration.  This way you only need to type 
 * type the name once. 
 *  
 * @example 
 * <pre> 
 *    subroutine CURSOR_HERE
 *    end subroutine CURSOR_HERE
 * </pre>
 */
bool def_fortran_multicursor_expansion=false;

defeventtab fortran_keys;
def ' '= fortran_space;
def 'ENTER'= fortran_enter;
def "("= auto_functionhelp_key;
def "%"= auto_codehelp_key;
def ":"= auto_codehelp_key;

_command fortran_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(FOR_LANGUAGE_ID);
}
_command void fortran_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_fortran_expand_enter);
}
bool _for_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
_command fortran_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      fortran_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}

static const FOR_ENTER_WORDS= " associate block critical do if else elseif forall select where ";
static const FOR_ENTER_WORDS2= "";
static const FOR_EXPAND_WORDS= " allocatable continue else inquire pointer return ";

static const FOR_MODULE_WORDS="(MODULE(:b(FUNCTION|SUBROUTINE|PROCEDURE)|))";
static const FOR_SELECT_WORDS="(SELECT(:b(TYPE|CASE)|))";
static const FOR_BEGIN_WORDS= "ASSOCIATE|BLOCK|CRITICAL|DO|FILE|FORALL|FUNCTION|IF|INTERFACE|PROCEDURE|PROGRAM|SUBMODULE|SUBROUTINE|TYPE|WHERE|"FOR_MODULE_WORDS'|'FOR_SELECT_WORDS;
static const FOR_MIDDLE_WORDS="CONTAINS|ELSEIF|THEN|(ELSE(:bIF|))";
static const FOR_END_WORDS=   "(CONTINUE|END(:b|)("FOR_BEGIN_WORDS"|))";

static SYNTAX_EXPANSION_INFO fortran_space_words:[] = {
   "allocatable" => { "allocatable" },
   "associate"   => { "associate ( ... ) ... end associate" },
   "block"       => { "block ... end block" },
   "block data"  => { "block data ... end block data" },
   "case"        => { "case ( ... ) " },
   "close"       => { "close" },
   "continue"    => { "continue" },
   "critical"    => { "critical ... end critical " },
   "else"        => { "else" },
   "elseif"      => { "elseif ( ... ) then" },
   "else if"     => { "else if ( ... ) then" },
   "format"      => { "format( ... )" },
   "function"    => { "function ... end function " },
   "if"          => { "if ( ... ) then" },
   "do"          => { "do ... end do" },
   "do while"    => { "do while ( ... ) ... end do" },
   "forall"      => { "forall ( ... ) ... end forall" },
   "inquire"     => { "inquire( ... )" },
   "integer"     => { "integer" },
   "interface"   => { "interface ... end interface" },
   "module"      => { "module ... end module" },
   "module subroutine" => { "module subroutine ... end subroutine" },
   "module function"   => { "module function ... end function" },
   "module procedure"  => { "module procedure ... end procedure" },
   "open"        => { "open( ... )" },
   "pointer"     => { "pointer" },
   "program"     => { "program ... end program " },
   "read"        => { "read( ... )" },
   "return"      => { "return" },
   "select"      => { "select ... end select" },
   "select case" => { "select case ( ... ) ... end select" },
   "select type" => { "select type ( ... ) ... end select" },
   "submodule"   => { "submodule ... end submodule" },
   "subroutine"  => { "subroutine ... end subroutine " },
   "type"        => { "type ... end type" },
   "where"       => { "where ( ... ) ... end where" },
   "write"       => { "write( ... )" },
};

/* Returns non-zero number if fall through to enter key required */
bool _fortran_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   line := "";
   get_line(line);
   int i=verify(line,"0123456789")  /* Skip the linenumbers */;
   if ( ! i ) {
      i=7;
   }
   orig_first_word := "";
   rest := "";
   maybe_rest := "";
   parse substr(line,i) with orig_first_word rest;
   if (pos(':',orig_first_word)) {
      // This is a label, see if we can do better
      parse rest with next_word maybe_rest;
      if (next_word!="") {
         orig_first_word=next_word;
         rest=maybe_rest;
      }
   }

   // In case we have "if( expr ) then", parse off parens
   int p=pos('\(|\)',orig_first_word,1,'r');
   if (p && p>1) {
      orig_first_word=substr(orig_first_word,1,p-1);
   }
   old_col := 0;
   new_col := 0;
   first_word := lowcase(orig_first_word);
   if ( (pos(' 'first_word' ',FOR_ENTER_WORDS) || pos(' 'first_word' ',FOR_ENTER_WORDS2)) &&
        !(first_word == "if" && !pos("then",line,1,'i')) &&
        !(first_word == "elseif" && !pos("then",line,1,'i')) &&
        !(first_word == "else" && pos(" if",line,1,'i') && !pos("then",line,1,'i'))) {
      old_col=p_col;
      p_col=verify(line,' ','',i);
      tab();
      new_col=p_col;p_col=old_col;
      indent_on_enter(syntax_indent);
   } else {
      if ( first_word!="" ) {
         new_col=verify(line,' ','',i);
      } else {
         if (!def_fortran_free_form_indent) {
            if ( i<7 ) {
               i=7;
            }
         }
         new_col=i;
      }
      call_root_key(ENTER);
   }
   next_line := "";
   get_line(next_line);
   if ( p_col<new_col ) {
      int diff=new_col-p_col;
      if ( next_line!="" ) {
         replace_line(substr("",1,diff):+next_line);
      }
      p_col += diff;
   }
   return(false);

}
static _str fortran_expand_space()
{
   multi_line_if := LanguageSettings.getMultilineIfExpansion(p_LangId);
   
   typeless status=0;
   get_line(auto origLine);
   line := strip(origLine,'T');
   typeless i=verify(line,"0123456789")  /* Skip the linenumbers */;
   if ( ! i ) {
      return(1);
   }
   sample := strip(substr(line,i));
   orig_word := lowcase(strip(substr(line,i)));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   aliasfilename := "";
   word := min_abbrev2(orig_word,fortran_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=="" ) return(1);
   /* Grab line number with blanks. */
   linenum_space := substr(line,1,verify(line,' '\t,'',i)-1);
   leading_space := indent_string(length(expand_tabs(linenum_space)));
   doNotify := true;
   end_statement_keyword := "";
   if ( word=="if" ) {
      if ( multi_line_if ) {
         set_surround_mode_start_line();
         replace_line(linenum_space:+_word_case("if ()",false,sample):+" ":+_word_case("then",false,sample));
         insert_line(leading_space:+_word_case("endif",false,sample));
         set_surround_mode_end_line();
         up();_end_line();p_col=p_col-6;
         doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      } else {
         replace_line(linenum_space:+_word_case("if () ",false,sample));
         _end_line();p_col=p_col-2;
      }
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="case" ) {
      replace_line(linenum_space:+_word_case("case () ",false,sample));
      _end_line();p_col=p_col-2;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="elseif" || word == "else if" ) {
      replace_line(linenum_space:+_word_case(word,false,sample):+" () ":+_word_case("then",false,sample));
      _end_line();p_col=p_col-6;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="block" || word=="do" || word=="select" || word=="critical" ) {
      set_surround_mode_start_line();
      replace_line(linenum_space:+_word_case(word,false,sample):+" ");
      insert_line(leading_space:+_word_case("end ":+word,false,sample));
      set_surround_mode_end_line();
      up();_end_line();
      doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="do while" ) {
      set_surround_mode_start_line();
      replace_line(linenum_space:+_word_case("do while ()",false,sample):+" ");
      insert_line(leading_space:+_word_case("end do",false,sample));
      set_surround_mode_end_line();
      up();_end_line();p_col=p_col-2;
      doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="associate" || word=="forall" || word == "where" ) {
      set_surround_mode_start_line();
      replace_line(linenum_space:+_word_case(word,false,sample):+" () ");
      insert_line(leading_space:+_word_case("end",false,sample):+" ":+_word_case(word,false,sample));
      set_surround_mode_end_line();
      up();_end_line();p_col=p_col-2;
      doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="select case" || word=="select type") {
      set_surround_mode_start_line();
      replace_line(linenum_space:+_word_case(word,false,sample):+" () ");
      insert_line(leading_space:+_word_case("end select",false,sample));
      set_surround_mode_end_line();
      up();_end_line();p_col=p_col-2;
      doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=="program" ) {
      replace_line(linenum_space:+_word_case("program ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="function" ) {
      replace_line(linenum_space:+_word_case("function ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="type" ) {
      replace_line(linenum_space:+_word_case("type ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="module" ) {
      replace_line(linenum_space:+_word_case("module ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="interface" ) {
      replace_line(linenum_space:+_word_case("interface ",false,sample));
      insert_line(leading_space:+_word_case("end",false,sample):+" ":+_word_case("interface",false,sample):+" ");
      up();_end_line();
   } else if ( word=="submodule" ) {
      replace_line(linenum_space:+_word_case("submodule ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="subroutine" ) {
      replace_line(linenum_space:+_word_case("subroutine ",false,sample));
      end_statement_keyword = word;
   } else if ( word=="module subroutine" ) {
      replace_line(linenum_space:+_word_case("module subroutine ",false,sample));
      end_statement_keyword = "subroutine";
   } else if ( word=="module function" ) {
      replace_line(linenum_space:+_word_case("module function ",false,sample));
      end_statement_keyword = "function";
   } else if ( word=="module procedure" ) {
      replace_line(linenum_space:+_word_case("module procedure ",false,sample));
      end_statement_keyword = "procedure";
   } else if ( word=="block data" ) {
      replace_line(linenum_space:+_word_case("block data ",false,sample));
      end_statement_keyword = word;
   // -- I/O statements -- add parentheses after keyword -- (MHP 12/1/99)
   } else if ( word=="open" ) {
      replace_line(linenum_space:+_word_case("open()",false,sample));
      _end_line();left();
   } else if ( word=="close" ) {
      replace_line(linenum_space:+_word_case("close()",false,sample));
      _end_line();left();
   } else if ( word=="inquire" ) {
      replace_line(linenum_space:+_word_case("inquire()",false,sample));
      _end_line();left();
   } else if ( word=="format" ) {
      replace_line(linenum_space:+_word_case("format()",false,sample));
      _end_line();left();
   } else if ( word=="read" ) {
      replace_line(linenum_space:+_word_case("read()",false,sample));
      _end_line();left();
   } else if ( word=="write" ) {
      replace_line(linenum_space:+_word_case("write()",false,sample));
      _end_line();left();
   } else if ( pos(" "word" ",FOR_EXPAND_WORDS) ) {
      newLine := linenum_space:+_word_case(word" ",false,sample);
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != origLine);
   } else {
      status=1;
      doNotify = false;
   }

   if (end_statement_keyword != "") {
      insert_line(leading_space:+_word_case("end",false,sample):+" ":+_word_case(end_statement_keyword,false,sample):+" ");
      if (!_MultiCursor() && def_fortran_multicursor_expansion) {
         add_multiple_cursors();
         up();_end_line();
         add_multiple_cursors();
      }
      else {
         up();_end_line();
      }
   }

   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;

}

int _for_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, fortran_space_words, prefix, min_abbrev);
}

static _str strip_comment(_str line)
{
   if ( pos(substr(line,1,1),"Cc*") ) {
      return("");
   }
   i := pos('!',line);
   if ( text_col(line,i,'I')!=6 ) {
      parse line with line "!";  /* LP77 extension */
   }
   return(line);

}
static const LINE_PREFIX_RE= '^([0-9 \t][ \t]*(:d)*|)[ \t]*';
static const NAME_RE= '{[A-Za-z][ A-Za-z0-9$_]*[A-Za-z0-9$_]}';
//#define PROC_RE (LINE_PREFIX_RE'[~!]*(subroutine|function|program|module) *\c'NAME_RE' *(\(|$|!|    )')
//Changed this b/c a user started his subroutines in col 1.  Also, added module for the same user.
static const PROC_RE= (LINE_PREFIX_RE'[~!]*(subroutine|function|program|submodule|module) *\c'NAME_RE' *(\(|$|!|    )');

int for_proc_search(_str &proc_name,int find_first)
{
   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "subroutine|function|program|module";
   }

   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["subroutine"] = "proc";
      kw_map:["function"]   = "func";
      kw_map:["program"]    = "prog";
      kw_map:["module"]     = "package";
      kw_map:["submodule"]  = "class";
   }

   return _generic_regex_proc_search('<<<TYPE>>>:b<<<NAME>>>', proc_name, find_first!=0, "", re_map, kw_map);
}

/*
  if then
  endif
  $if
  $endif
  do 10
10  continue
  do while
  end do
*/
/* Code for Layhey fortran support */
#if 0 //__PCDOS__
_str
   _error_search
   ,_error_parse
   ,_error_re
   ,_error_re2

void for_parse_error(var filename,var line,var col,var err_msg)
{
   col=7;
   get_line orig_line;
   parse_error(filename,line,junk,line_text);
   /* Check if error message is before 'File xyz.for, line    N:' */
   up();
   if ( ! rc ) {
      get_line prev_line;
      down();
      parse prev_line with '(FATAL|WARNING) -','ri' err_msg;
      if ( err_msg!='' ) {
         col=7;
         return;
      }
   }
   search '^(([ \t]*\^)|((WARNING|FATAL) - @{?@}$))','rih';
   get_line col_line;
   if ( last_char(col_line)=='^' ) {
      new_col=pos('^',col_line)-pos(':d\:',orig_line,1,'r')-2
      if ( ! rc && new_col>0 ) {
         col=new_col;
      }
      search '(WARNING|FATAL) - @{?@}$','@rih';
   }
   if ( rc ) {
      err_msg='';
   } else {
      err_msg=get_match_text(0);
   }
   /* messageNwait('filename='filename' line='line' col='col' err_msg='err_msg) */

}
void for_init_error()
{
   _error_parse= find_index(FOR_LANGUAGE_ID'-parse-error',PROC_TYPE);
   _error_re='^(?*,|) *File {:p}, *line *{:i}{}(\:|.) @{?@}$';
   _error_re2='';
}
#endif

_command void for_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   //int index=_edit_window().p_index;
   //p_index=0;
   call_root_key(TAB);
   //_edit_window().p_index=index;

}
_command void for_backtab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   //int index=_edit_window().p_index;
   //p_index=0;
   call_root_key(S_TAB);
   //_edit_window().p_index=index;
}


/** 
 * Build tag file for Fortran bultins. 
 *  
 * @param tfindex       [output] set to tag file index for fortran tag file 
 * @param withRefs      Build tag file including references 
 * @param useThread     Build tag file on a background thread 
 * @param forceRebuild  Force the langauge specific tag file to be rebuilt from scratch 
 */  
int _for_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   lang := "for";
   base := "fortran";
   tagfilename := "";
   if (!forceRebuild && ext_MaybeRecycleTagFile(tfindex,tagfilename,lang,base)) {
      return(0);
   }
   // Now build and save the tag file
   return ext_BuildTagFile(tfindex, 
                           tagfilename, 
                           lang, 
                           "Fortran Builtins",
                           recursive:false, 
                           "", 
                           ext_builtins_path(lang,base), 
                           withRefs, useThread);
}

int _for_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return _pas_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth);
}
int _for_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     bool &FunctionHelp_list_changed,
                     int &FunctionHelp_cursor_x,
                     _str &FunctionHelp_HelpWord,
                     int FunctionNameStartOffset,
                     int flags,
                     VS_TAG_BROWSE_INFO symbol_info=null,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _pas_fcthelp_get(errorArgs,
                           FunctionHelp_list,
                           FunctionHelp_list_changed,
                           FunctionHelp_cursor_x,
                           FunctionHelp_HelpWord,
                           FunctionNameStartOffset,
                           flags, symbol_info,
                           visited, depth);
}

int _for_get_expression_info(bool PossibleOperator, 
                             VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "_for_get_expression_info: PossibleOperator="PossibleOperator);
   }

   // get the identifier under the cursor
   status := _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);
   if (_chdebug) {
      tag_idexp_info_dump(idexp_info, "_for_get_expression_info", depth+1);
      isay(depth+1, "_for_get_expression_info: status="status);
   }
   if (status) {
      return status;
   }

   // get the prefix expression
   save_pos(auto orig_pos);
   _GoToROffset(idexp_info.lastidstart_offset);

   loop {
      // get the character to the left of the cursor
      if (p_col <= 1) break;
      left();
      _clex_skip_blanks('-');
      ch := get_text();
      if (_chdebug) {
         isay(depth, "_for_get_expression_info: ch="ch"=");
      }

      // % is the member access operator in Fortran, dig it.
      if (ch != '%' && ch != ':') break;

      // now get the identifier to the left of the % operator
      left();
      _clex_skip_blanks('-');
      prefix_id := cur_identifier(auto start_col);
      if (prefix_id == "") break;
      if (_chdebug) {
         isay(depth, "_for_get_expression_info: prefix_id="prefix_id"=");
      }

      // and prepend it to the prefix expression
      p_col = start_col;
      idexp_info.prefixexp = prefix_id :+ ch :+ idexp_info.prefixexp;
      idexp_info.prefixexpstart_offset = (int)_QROffset();
   }

   restore_pos(orig_pos);
   return(0);
}

/**
 * Utility function for searching the current context and tag files
 * for symbols matching the given symbol and search class, filtering
 * based on the filter_flags and toy_return_flags.  The number of
 * matches is returned and can be obtained using TAGSDB function
 * tag_get_match_browse_info(...).
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param filter_flags        bitset of VS_TAGFILTER_*, allows us to search only
 *                            certain items in the database (e.g. functions only)
 * @param rt                  return type information
 *
 * @return 0 on success,
 *         < 0 on other error (normal slickedit RC)
 */
static int _for_get_return_type_of(_str (&errorArgs)[], 
                                    typeless tag_files,
                                    _str symbol, 
                                    _str search_class_name,
                                    _str search_file, 
                                    bool maybe_class_name,
                                    SETagFilterFlags filter_flags, 
                                    SETagContextFlags context_flags,
                                    struct VS_TAG_RETURN_TYPE &rt,
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0) 
{
   if (_chdebug) {
      isay(depth, "_for_get_return_type_of("symbol","search_class_name")");
   }

   num_matches := 0;
   max_matches := def_tag_max_function_help_protos;

   if (_isEditorCtl()) {
      _UpdateContext(AlwaysUpdate:true);
      _UpdateLocals(AlwaysUpdate:true);
   }
   tag_push_matches();
   status := tag_list_symbols_in_context(symbol, search_class_name,
                                         0, 0, tag_files, search_file,
                                         num_matches, max_matches,
                                         filter_flags, context_flags,
                                         exact_match:true, 
                                         case_sensitive:p_LangCaseSensitive, 
                                         visited, depth+1, 
                                         rt.template_args);
   if ((status < 0 || num_matches <= 0) && rt.return_type == "") {
      status = tag_list_symbols_in_context(symbol, "",
                                           0, 0, tag_files, search_file,
                                           num_matches, max_matches,
                                           filter_flags, context_flags,
                                           exact_match:true, 
                                           case_sensitive:p_LangCaseSensitive, 
                                           visited, depth+1, 
                                           rt.template_args);
   }
   if (status < 0) {
      tag_pop_matches();
      return status;
   }

   tag_get_all_matches(auto matches);
   tag_pop_matches();
   if (_chdebug) {
      isay(depth, "_for_get_return_type_of: num_matches="matches._length());
   }

   result := 0;
   foreach (auto cm in matches) {
      if (cm.return_type == null || cm.return_type == "") {
         if (tag_tree_type_is_package(cm.type_name)) {
            rt.return_type = cm.qualified_name;
            return 0;
         }
         if (tag_tree_type_is_class(cm.type_name) || cm.type_name == "typedef") {
            rt.return_type = cm.qualified_name;
            return 0;
         }
         continue;
      }
      if (_chdebug) {
         tag_browse_info_dump(cm, "_for_get_return_type_of", depth+1);
      }
      status = _for_parse_return_type(errorArgs, 
                                      tag_files, 
                                      symbol, 
                                      search_class_name,
                                      cm.file_name, 
                                      cm.return_type, 
                                      rt, visited, depth+1);
      if (status < 0) {
         result = status;
         continue;
      }

      return status;
   }

   return result;
}

/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param tag_files           List of tag files to use
 * @param prefixexp           Prefix expression
 * @param rt                  (reference) return type structure
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               (optional) depth of recursion
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param symbol              name of symbol corresponding to current context 
 * @param search_class_name   class name of current context 
 *
 * @return 0 on success, non-zero on error
 */
static int _for_get_type_of_prefix_recursive(_str (&errorArgs)[], 
                                             _str (&tag_files)[],
                                             _str prefixexp, 
                                             _str search_class_name,
                                             struct VS_TAG_RETURN_TYPE &rt,
                                             struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   tag_return_type_init(rt);
   if (prefixexp == null) {
      return 0;
   }
   if (_chdebug) {
      isay(depth, "_for_get_type_of_prefix_recursive(prefixexp: "prefixexp", search_class_name: "search_class_name")");
   }

   while (prefixexp != "") {
      if (pos('%', prefixexp)) {
         // TYPE member access
         parse prefixexp with auto var_id '%' prefixexp;
         status := _for_get_return_type_of(errorArgs, 
                                           tag_files, 
                                           var_id, 
                                           ((rt.return_type != "")? rt.return_type : search_class_name), 
                                           rt.filename, 
                                           maybe_class_name:false, 
                                           SE_TAG_FILTER_ANY_DATA, 
                                           SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_PARENTS, 
                                           rt, 
                                           visited, depth+1);
         if (status < 0) {
            return status;
         }
      } else if (pos(':', prefixexp)) {
         // MODULE:SUBMODULE type name access
         parse prefixexp with auto var_id '!' prefixexp;
         status := _for_get_return_type_of(errorArgs, 
                                           tag_files, 
                                           var_id, 
                                           ((rt.return_type != "")? rt.return_type : search_class_name), 
                                           rt.filename, 
                                           maybe_class_name:true,
                                           SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_PACKAGE, 
                                           SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_FIND_PARENTS,
                                           rt, 
                                           visited, depth+1);
         if (status < 0) {
            return status;
         }
      } else {
         // lost in the wilderness
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }

   }

   return 0;
}

/**
 * Evaluate the type of a Fortran prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param prefixexp           Prefix expression
 * @param rt                  (reference) return type structure
 * @param depth               (optional) depth of recursion 
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param search_class_name   current package/class scope 
 *
 * @return 0 on success, non-zero on error
 */
int _for_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                            struct VS_TAG_RETURN_TYPE &rt, 
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                            CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL, 
                            _str search_class_name="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   lang := _isEditorCtl()? p_LangId : "";
   tag_files := tags_filenamea(lang);
   tag_push_matches();
   if (_chdebug) {
      isay(depth, "_for_get_type_of_prefix("prefixexp")");
   }
   status := _for_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, search_class_name, rt, visited, depth);
   tag_pop_matches();
   return status;
}

int _for_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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
      isay(depth, "_for_find_context_tags("prefixexp","lastid")");
   }
   errorArgs._makeempty();
   tag_clear_matches();

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         _CodeHelpListLabels(0, 0, lastid, "",
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth+1);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // declare local variables to be used later
   cur_return_type := "";
   proc_name := type_name := import_name := aliased_to := "";
   cur_line_no := 0;
   num_matches := status := 0;

   // get the current class and current package from the context
   context_id := tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                         auto cur_type_name,auto cur_type_id,
                                         auto cur_context, auto cur_class_name,
                                         auto cur_package_name,
                                         visited, depth+1);
   // work around for broken cur_context parameter
   if (cur_context != "" && pos(cur_context, cur_class_name) == 1 && length(cur_class_name) > length(cur_context)) {
      cur_context = cur_class_name;
   }
   if (_chdebug) {
      isay(depth, "_for_find_context_tags H"__LINE__": cur_context="cur_context);
   }

   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_line_no);
      tag_get_detail2(VS_TAGDETAIL_context_return, context_id, cur_return_type);
   }

   // get the list of tag files for this search
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // no prefix expression, update globals and members from current context
   if (prefixexp == "") {

      return _do_default_find_context_tags(errorArgs, 
                                           prefixexp, 
                                           lastid, lastidstart_offset, 
                                           info_flags, otherinfo, 
                                           find_parents, 
                                           max_matches, 
                                           exact_match, case_sensitive, 
                                           filter_flags, context_flags, 
                                           visited, depth);

      // all done
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   tag_return_type_init(auto rt);
   tag_push_matches();
   status = _for_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1, search_class_name:cur_context);
   tag_pop_matches();
   if (_chdebug) {
      isay(depth, "_for_find_context_tags: match_class="rt.return_type" status="status);
   }
   if (status && num_matches==0) {
      return status;
   }

   if (!status) {
      prefix_rt = rt;
      if (pos(cur_package_name"/",rt.return_type)) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
      }
      if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_LOCALS;
      }
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
         context_flags |= SE_TAG_CONTEXT_ACCESS_PRIVATE;
      }
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
         context_flags |= SE_TAG_CONTEXT_ONLY_CONSTRUCTORS;
         tag_list_in_class(lastid, rt.return_type,
                           0, 0, tag_files,
                           num_matches, max_matches,
                           filter_flags, context_flags,
                           exact_match, case_sensitive, 
                           rt.template_args, null, visited, depth+1 );
         context_flags &= ~SE_TAG_CONTEXT_ONLY_CONSTRUCTORS;
         context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
      }
      if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
         context_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      }
      if (prefixexp != "" && rt.return_type != "") {
         context_flags |= SE_TAG_CONTEXT_NO_GLOBALS;
      }
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_LOCALS;
      }
      context_flags |= SE_TAG_CONTEXT_ALLOW_FORWARD;

      if (num_matches == 0) {
         tag_list_symbols_in_context(lastid, rt.return_type, 
                                     0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags,
                                     exact_match, case_sensitive, 
                                     visited, depth+1, 
                                     rt.template_args);

         if (tag_get_num_of_matches() == 0) {
            tag_qualify_symbol_name(auto qualified_name, rt.return_type, cur_context, rt.filename, tag_files, case_sensitive:false, visited, depth+1);
            if (_chdebug) {
               isay(depth, "_for_find_context_tags: qualified_name="qualified_name);
            }
            if (qualified_name != "" && qualified_name != rt.return_type) {
               if (_chdebug) {
                  isay(depth, "_for_find_context_tags: qualified_name="qualified_name);
               }
               rt.return_type = qualified_name;
               prefix_rt = rt;
               tag_list_symbols_in_context(lastid, rt.return_type, 
                                           0, 0, tag_files, "",
                                           num_matches, max_matches,
                                           filter_flags,
                                           context_flags,
                                           exact_match, case_sensitive, 
                                           visited, depth+1, 
                                           rt.template_args);
            }
         }
      }
   }

   // Return 0 indicating success if anything was found
   if (_chdebug) {
      tag_dump_matches("_for_find_context_tags: FINAL", depth+1);
   }
   errorArgs[1] = (lastid!="")? lastid : prefixexp;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

static int _for_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                                  _str symbol, _str search_class_name,
                                  _str file_name, _str return_type,
                                  VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_for_parse_return_type("symbol","search_class_name","return_type","file_name")");
   }

   // filter out mutual recursion
   input_args := "get;"symbol";"search_class_name";"file_name";"return_type";"p_buf_name";"tag_return_type_string(rt);
   status := _CodeHelpCheckVisited(input_args, "_for_get_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   orig_return_type := return_type;
   rt.return_type = "";

   while (return_type != "") {
      p := pos('^ @{\[|\]|\(|\)|\%|\*|\:|:v|:i}', return_type, 1, 'r');
      if (p <= 0) {
         break;
      }
      p   = pos('S0');
      n  := pos('0');
      ch := substr(return_type, p, n);
      return_type = strip(substr(return_type, p+n));
      if (_chdebug) {
         isay(depth+1, "_for_parse_return_type: ch="ch" return_type="return_type);
      }
      switch (upcase(ch)) {
      case "CLASS":
         parse return_type with "(" return_type ")";
         break;
      case "TYPE":
         parse return_type with "(" return_type ")";
         break;
      case "ABSTRACT":
      case "PUBLIC":
      case "PRIVATE":
      case "PROTECTED":
      case "ALLOCATABLE":
      case "ASYNCHRONOUS":
      case "CONTIGUOUS":
      case "EXTERNAL":
      case "INTRINSIC":
      case "PARAMETER":
      case "SAVE":
      case "TARGET":
      case "VALUE":
         // ignore type attributes
         break;
      case "BIND":
      case "EXTENDS":
         // ignore type attributes
         parse return_type with "(" . ")" return_type;
         break;
      case "INTENT":
         parse return_type with "(" auto intent ")" return_type;
         switch (upcase(strip(intent))) {
         case "IN":
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_IN;
            break;
         case "OUT":
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_OUT;
            break;
         case "INOUT":
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }
         break;
      case "CODIMENSION":
         parse return_type with "(" . ")" return_type;
         parse return_type with "[" . "]" return_type;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         break;
      case "DIMENSION":
         parse return_type with "(" . ")" return_type;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         break;
      case "INTEGER":
      case "REAL":
      case "COMPLEX":
      case "CHARACTER":
      case "LOGICAL":
         rt.return_type = ch;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         break;
      case "DOUBLE":
         rt.return_type = ch;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         if (pos("PRECISION", return_type, 1, 'i') == 1) {
            rt.return_type = ch :+ " " :+ substr(return_type, 1, 9);
         }
         break;
      case "KIND":
         // ignore KIND=...
         return_type = "";
         break;
      case "LEN":
         // ignore KIND=...
         return_type = "";
         break;
      case "POINTER":
         parse return_type with "(" . ")" return_type;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_POINTER;
         rt.pointer_count = 1;
         break;
      case "VOLATILE":
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         break;
      case "*":
         if (pos(":i", return_type, 1, 'ir') == 1) {
            p  = pos('S0');
            n  = pos('0');
            ch = substr(return_type, p, n);
            return_type = strip(substr(return_type, p+n));
         }
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         break;
      default:
         if (isnumber(ch)) {
            // do not know why there is a number here
         } else {
            // try to find this symbol as a return type
            tag_return_type_init(auto ch_rt);
            ch_status := _for_get_return_type_of(errorArgs, tag_files, 
                                                 ch, search_class_name, 
                                                 rt.filename, maybe_class_name:true, 
                                                 SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_PACKAGE, 
                                                 SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_FIND_PARENTS, 
                                                 ch_rt, 
                                                 visited, depth+1);
            rt.return_type = ch;
            if (ch_status == 0 && ch_rt.return_type != 0) {
               rt.return_type = ch_rt.return_type;
            } else {
               qualify_status := tag_qualify_symbol_name(auto qualified_name, ch, search_class_name, rt.filename, tag_files, case_sensitive:false, visited, depth+1);
               if (!qualify_status && qualified_name != "") {
                  rt.return_type = qualified_name;
               }
            }

         }
         break;
      }

      // could have a comma separator between attributes
      if (_first_char(return_type) == ',') {
         return_type = strip(substr(return_type, 2));
      }
   }

   if (_chdebug) {
      isay(depth,"_for_parse_return_type returns: return_type="rt.return_type" pointer_count="rt.pointer_count);
   }
   if (rt.return_type == "") {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   visited:[input_args]=rt;
   return 0;
}


/**
 * Callback for determining if the current line is the first line
 * of a block statement.
 * <p>
 *
 * @param first_line
 * @param last_line
 * @param num_first_lines
 * @param num_last_lines
 *
 * @return bool
 */

bool _for_find_surround_lines(int &first_line, int &last_line,
                              int &num_first_lines, int &num_last_lines,
                              bool &indent_change,
                              bool ignoreContinuedStatements=false)
{
   indent_change = true;
   first_line = p_RLine;
   _first_non_blank();
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return false;
   }
   status := 0;
   start_col := 0;
   word := cur_identifier(start_col);
   switch (upcase(word)) {
   case "ASSOCIATE":
   case "BLOCK":
   case "CRITICAL":
   case "DO":
   case "IF":
   case "FORALL":
   case "SELECT":
   case "WHERE":
      break;
   default:
      return false;
   }
        
   first_line = p_RLine;
   num_first_lines = 1;
   status = _for_match_next_word(word);
   if (status) {
      return false;
   }
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return false;
   }
   word = cur_identifier(start_col);
   switch (upcase(word)) {
   case "END":
   case "ENDASSOCIATE":
   case "ENDBLOCK":
   case "ENDCRITICAL":
   case "ENDDO":
   case "ENDIF":
   case "ENDFORALL":
   case "ENDSELECT":
   case "ENDWHERE":
      p_col += length(word);
      break;
   }
   num_last_lines=1;
   last_line = p_RLine;

   // make sure that it is at the end of the line
   p_col++;
   _clex_skip_blanks('h');
   if (p_RLine==last_line && !at_end_of_line()) {
      return false;
   }
   // success
   return true;
}

static bool _for_pbrace(_str ch)
{
   return (ch == '(' || ch == ')' || ch == '{' || ch == '}' || ch == '[' || ch == ']');
}

/**
 * Fortran Begin/End statements (reverse search)
 *
 * <pre> 
 *   program .. end program
 *   module ... end module
 *   interface ... end subroutine
 *   function ... end function
 *   subroutine ... end subroutine
 *   if ... end if
 *   do while ... end do
 *   do ... continue
 *   forall ... end forall
 * </pre>
 */
static int _for_match_prev_word(_str word)
{
   // figure out what keyword we are trying to find a match for
   save_pos(auto p);
   start_word := "";
   if (length(word) > 3 && upcase(substr(word,1,3)) == "END") {
      start_word = substr(word,4);
   } else if (upcase(word) == "CONTINUE") {
      start_word = "DO";
   } else {
      start_word = word;
   }

   // set up stack to keep track of nesting levels
   stack_top := 0;
   _str tk_stack[];
   tk_stack[stack_top] = upcase(start_word);

   // back up a notch and then search, if we don't know the start word
   // we are searching for, then look for any start word
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   status := search('[{}()\[\]]|\b('FOR_END_WORDS'|'FOR_BEGIN_WORDS')\b', "-iwrh@XSC");;
   while (!status && stack_top < 100) {

      // skip {} [] ()
      ch := get_text();
      if (_for_pbrace(ch)) { 
         if (_pmdebug) {
            isay(stack_top, "_for_match_next_word: PUNCTUATION, ch="ch" p_line="p_RLine" p_col="p_col);
         }
         if (ch == '}' || ch == ')' || ch == ']') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, quiet:true, depth:stack_top+1);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(1);
            }
         } else {
            if (_pmdebug) {
               isay(stack_top, "_for_match_next_word: NO MATCH FOR STRAY OPEN PUNCTUATION, ch="ch" p_line="p_RLine" p_col="p_col);
            }
            //restore_pos(p);
            //return(1);
         }

      } else {

         // get the word that was matched
         word = get_match_text();
         tktop := tk_stack[stack_top];
         tk := upcase(word);
         tk = stranslate(tk, "", ":b", 'r');

         if (_pmdebug) {
            isay(stack_top, "_for_match_prev_word: word="word);
         }
         // check for MODULE <keyword>
         if (length(tk) > 6 && substr(tk, 1, 6) == "MODULE") {
            tk = substr(tk, 7);
         } else if (length(tk) > 6 && substr(tk, 1, 6) == "SELECT") {
            tk = "SELECT";
         }
         if (_pmdebug) {
            isay(stack_top, "_for_match_prev_word: tk="tk" tktop="tktop);
         }

         // check for MODULE <keyword>
         if (p_col > 2 && (tk == "FUNCTION" || tk == "PROCEDURE" || tk == "SUBROUTINE")) {
            save_pos(auto fun_pos);
            p_col -= 2;
            prev_word := cur_identifier(auto module_col);
            if (upcase(prev_word) == "MODULE") {
               p_col = module_col;
               word = prev_word:+' ':+word;
            } else {
               restore_pos(fun_pos);
            }
         }

         // check for SELECT <keyword>
         if (p_col > 2 && (tk == "TYPE" || tk == "CASE")) {
            save_pos(auto type_pos);
            p_col -= 2;
            prev_word := cur_identifier(auto select_col);
            if (upcase(prev_word) == "SELECT") {
               p_col = select_col;
               word = prev_word:+' ':+word;
               tk = upcase(prev_word);
            } else {
               restore_pos(type_pos);
            }
         }

         // check for ELSE IF
         if (p_col > 2 && tk == "IF") {
            save_pos(auto if_pos);
            p_col -= 2;
            prev_word := cur_identifier(auto else_col);
            if (upcase(prev_word) == "ELSE") {
               p_col = else_col;
               word = prev_word:+' ':+word;
               tk = "ELSEIF";
            } else {
               restore_pos(if_pos);
            }
         }

         if (tk == "END") {
            // unmatched bare END keyword, just ignore it going backwards

         } else if (substr(tk,1,3) == "END") {
            // END <keyword> pushes stack
            tkstart := substr(tk,4);
            tk_stack[++stack_top] = upcase(tkstart);

         } else if (tk == "CONTINUE") {
            // CONTINUE <keyword> wants to pair with "DO"
            tk_stack[++stack_top] = "DO";

         } else if (tk == "TYPE") {
            // special case because TYPE(xxx) can be used in variable declarations
            save_pos(auto type_pos);
            p_col += 4;
            ch = get_text();
            while (ch :== " " || ch :== "\t") {
               p_col++;
               ch = get_text();
            }
            next_word := cur_identifier(auto after_type_pos);
            restore_pos(type_pos);
            if (upcase(next_word) != "IS" && (ch==":" || ch=="," || _clex_is_identifier_char(ch))) {
               // maybe we found a word match for TYPE
               if (tk == tktop) {
                  --stack_top;
                  if (stack_top < 0) {
                     return 0;
                  }
               }
            }

         } else if (tk == "IF") {
            // ignore "IF" without "THEN"
            get_line(auto line);
            if_pos   := pos("IF",   line, 1, 'i');
            then_pos := pos("THEN", line, max(1,if_pos), 'i');
            if (then_pos > if_pos && tk == tktop) {
               --stack_top;
               if (stack_top < 0) {
                  return 0;
               }
            } else {
               if (_pmdebug) {
                  isay(stack_top, "_for_match_prev_word: IF CASE, CONTINUE ANYWAY");
               }
            }

         } else if (tk == tktop) {
            // found a match for the keyword on top of stack
            --stack_top;
            if (stack_top < 0) {
               return 0;
            }

         } else if (length(word) > 6 && upcase(substr(word, 1, 6)) == "MODULE") {
            // we can have a prototype for a MODULE PROCEDURE with no
            // matching END PROCEDURE, so just skip this stray

         } else if (tktop == "END") {
            // allow a lone "END" to match anything when going backwards
            --stack_top;
            if (stack_top < 0) {
               return 0;
            }

         } else if (tk == "FUNCTION" || tk == "PROCEDURE" || tk == "SUBROUTINE") {
            // we can have a prototype for a PROCEDURE with no
            // matching END PROCEDURE, so just skip this stray

         } else if (tk == "ELSEIF" || tk == "ELSE" || tk == "THEN" || tk == "CONTAINS") {
            // we do not stop at "middle" keywords when going backwards.

         } else {
            if (_pmdebug) {
               isay(stack_top, "_for_match_prev_word: STRAY KEYWORD, FULL STOP");
            }
            // start keyword does not match stack, error out
            restore_pos(p);
            return(1);
         }
      }
      
      // find another
      if (_pmdebug) {
         isay(stack_top, "_for_match_prev_word: BEFORE REPEAT SEARCH, line="p_RLine" col="p_col);
      }
      status = repeat_search();
      if (_pmdebug) {
         isay(stack_top, "_for_match_prev_word: REPEAT SEARCH, status="status);
      }
   }

   // no match found
   restore_pos(p);
   return(1);
}

/**
 * Fortran Begin/End statements (forward search)
 *
 * <pre> 
 *   program .. end program
 *   module ... contains ... end module
 *   interface ... contains  ... end subroutine
 *   function ... end function
 *   subroutine ... end subroutine
 *   if ... then ... [ elseif ... then ... ] [ else ... ] end if
 *   do while ... end do
 *   do ... continue
 *   forall ... end forall
 * </pre>
 */
static int _for_match_next_word(_str word)
{
   // keep a stack of what items we are matching against
   _str tk_stack[];
   stack_top := 0;
   tk_stack[stack_top] = upcase(word);

   // search for the next match
   save_pos(auto p);
   status := search('[{}()\[\]]|\b('FOR_BEGIN_WORDS'|'FOR_MIDDLE_WORDS'|'FOR_END_WORDS')\b', "irh@XSC");
   while (!status && stack_top < 100) {

      // skip {} [] ()
      ch := get_text();
      if (_for_pbrace(ch)) {
         if (ch == '{' || ch == '(' || ch == '[') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, quiet:true, depth:stack_top+1);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);   // error'd
               return(1);
            }
         } else {
            if (_pmdebug) {
               isay(stack_top, "_for_match_next_word: NO MATCH FOR STRAY CLOSE PUNCTUATION, ch="ch" p_line="p_RLine" p_col="p_col);
            }
            restore_pos(p);   // error'd
            return(1);
         }

      } else {
         // get the word that was found
         word = get_match_text();
         tktop := tk_stack[stack_top];
         tk := upcase(word);
         tk = stranslate(tk, "", ":b", 'r');
         if (length(tk) > 6 && substr(tk, 1, 6) == "MODULE") {
            tk = substr(tk, 7);
         } else if (length(tk) > 6 && substr(tk, 1, 6) == "SELECT") {
            tk = "SELECT";
         }
         if (_pmdebug) {
            isay(stack_top, "_for_match_next_word: tk="tk" tktop="tktop);
         }

         if (tk == "TYPE") {
            // special case because TYPE(xxx) can be used in variable declarations
            save_pos(auto type_pos);
            p_col += 4;
            ch = get_text();
            while (ch :== " " || ch :== "\t") {
               p_col++;
               ch = get_text();
            }
            next_word := cur_identifier(auto after_type_pos);
            if (upcase(next_word) != "IS" && (ch==":" || ch=="," || _clex_is_identifier_char(ch))) {
               tk_stack[++stack_top] = tk;
            }
            restore_pos(type_pos);

         } else if (tk == "IF") {
            // ignore "IF" without "THEN"
            get_line(auto line);
            if (_pmdebug) {
               isay(stack_top, "_for_match_next_word: IF CASE, line="line);
            }
            if_pos   := pos("IF",   line, 1, 'i');
            then_pos := pos("THEN", line, max(1,if_pos), 'i');
            if (then_pos > if_pos) {
               tk_stack[++stack_top] = tk;
            } else {
               if (_pmdebug) {
                  isay(stack_top, "_for_match_next_word: IF CASE, CONTINUE ANYWAY");
               }
            }

         } else if (pos("^("FOR_BEGIN_WORDS")$", upcase(tk), 1, 'ir') > 0) {
            p_col += (length(word)-1);
            tk_stack[++stack_top] = tk;

         } else if (tk == "END") {
            --stack_top;
            if (stack_top < 0) {
               return 0;
            }

         } else if (tk == "CONTINUE") {
            if (tktop == "DO") {
               --stack_top;
               if (stack_top < 0) {
                  return 0;
               }
            }

         } else if (pos("^("FOR_END_WORDS")$", tk, 1, 'ir') > 0) {
            p_col += length(word);
            tkend := substr(tk,4);
            if (upcase(tkend) == tktop) {
               --stack_top;
               if (stack_top < 0) {
                  return 0;
               }
            } else if (tktop == "CONTAINS" && (tkend == "INTERFACE" || tkend == "MODULE" || tkend == "SUBMODULE" || tkend == "PROGRAM" || tkend == "TYPE") && stack_top <= 0) {
               return 0;
            } else if ((tktop == "ELSEIF" || tktop == "ELSE" || tktop == "THEN") && tkend == "IF" && stack_top <= 0) {
               return 0;
            } else {
               // see if our match is higher up the stack,
               // maybe we have something with a missing 'END"
               for (i:=stack_top-1; i>=0; --i) {
                  tktop = tk_stack[i];
                  if (upcase(tkend) == tktop) {
                     stack_top = (i-1);
                     if (stack_top < 0) {
                        return 0;
                     }
                  } else if (tktop == "CONTAINS" && (tkend == "INTERFACE" || tkend == "MODULE" || tkend == "SUBMODULE" || tkend == "PROGRAM" || tkend == "TYPE")) {
                     stack_top = (i-1);
                     if (stack_top < 0) {
                        return 0;
                     }
                  } else if ((tktop == "ELSEIF" || tktop == "ELSE" || tktop == "THEN") && tkend == "IF") {
                     stack_top = (i-1);
                     if (stack_top < 0) {
                        return 0;
                     }
                  }
               }
            }

         } else if (tk == "CONTAINS") {
            switch (tktop) {
            case "PROGRAM":
            case "MODULE":
            case "SUBMODULE":
            case "INTERFACE":
            case "TYPE":
               if (stack_top <= 0) {
                  return 0;
               }
            }

         } else if (tk == "THEN" || tk == "ELSEIF" || tk == "ELSE") {
            p_col += (length(word)-1);
            switch (tktop) {
            case "IF":
            case "ELSEIF":
            case "ELSE":
            case "THEN":
               if (stack_top <= 0) {
                  return 0;
               }
            }

         } else {
            // no match found
            if (_pmdebug) {
               isay(stack_top, "_for_match_next_word: STRAY KEYWORD, FULL STOP");
            }
            restore_pos(p);
            return(1);
         }
      }

      // find another
      if (_pmdebug) {
         isay(stack_top, "_for_match_next_word: BEFORE REPEAT SEARCH, line="p_RLine" col="p_col);
      }
      status = repeat_search();
      if (_pmdebug) {
         isay(stack_top, "_for_match_next_word: REPEAT SEARCH, status="status);
      }
   }

   // no match found
   restore_pos(p);
   return(1);
}

/**
 * Fortran block matching callback
 *
 * @param quiet   just return status, no messages 
 *  
 * @return 0 on success, nonzero if no match
 */
int _for_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   save_pos(auto p);

   // if the word under the cursor is not a block match word, 
   // scan forward on this line until we find one
   ch := get_text();
   if (_clex_is_identifier_char(ch)) {
      word := cur_identifier(auto start_col);
      while (word != "" && !pos("^("FOR_BEGIN_WORDS'|'FOR_MIDDLE_WORDS'|'FOR_END_WORDS")$", word, 1, 'ir')) {
         p_col = start_col+length(word);
         ch = get_text();
         while (ch :== " " || ch :== "\t") {
            p_col++;
            ch = get_text();
         }
         if (!_clex_is_identifier_char(ch)) {
            restore_pos(p);
            break;
         }
         word = cur_identifier(start_col);
         if (word == "") {
            restore_pos(p);
            break;
         }
      }
   }

   cfg := _clex_find(0, 'g');
   if (cfg != CFG_KEYWORD && p_col > 0) {
      left(); 
      cfg = _clex_find(0, 'g');
   }
   if (cfg == CFG_KEYWORD) {
      word := cur_identifier(auto start_col);
      end_col := start_col+length(word);

      // maybe the cursor is on the first part of an "END KEYWORD" sequence
      if (upcase(word) == "END") {
         p_col = end_col+2;
         next_word := cur_identifier(auto end_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: END CASE, WORD AFTER="next_word);
         }
         if (next_word != "" && pos('^('FOR_BEGIN_WORDS')$', next_word, 1, 'ir')) {
            word = "END":+upcase(next_word);
            end_col = end_start_col+length(next_word);
         }
      }
      // maybe the cursor is on the second part of an "END KEYWORD" sequence
      if (start_col > 2 && pos("^("FOR_BEGIN_WORDS")$", word, 1, 'ir') > 0) {
         p_col = start_col-2;
         prev_word := cur_identifier(auto prev_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: BEGIN CASE, WORD BEFORE="word);
         }
         if (upcase(prev_word) == "END") {
            word = "END":+upcase(word);
            start_col = prev_start_col;
         }
      }

      // maybe the cursor is on the "ELSE" preceeding an "IF"
      if (upcase(word) == "ELSE") {
         p_col = end_col+2;
         next_word := cur_identifier(auto else_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: ELSE CASE, WORD AFTER="next_word);
         }
         if (upcase(next_word) == "IF") {
            word = "ELSEIF";
            end_col = else_start_col+length(next_word);
         }
      }
      // maybe the cursor is on the "IF" following an "ELSE"
      if (start_col > 2 && upcase(word) == "IF") {
         p_col = start_col-2;
         prev_word := cur_identifier(auto prev_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: IF CASE, WORD BEFORE="word);
         }
         if (upcase(prev_word) == "ELSE") {
            word = "ELSEIF";
            start_col = prev_start_col;
         }
      }

      // maybe the cursor is on the first part of an "MODULE KEYWORD" sequence
      if (upcase(word) == "MODULE") {
         p_col = end_col+2;
         next_word := cur_identifier(auto end_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: MODULE CASE, WORD AFTER="next_word);
         }
         if (next_word != "" && pos('^('FOR_BEGIN_WORDS')$', next_word, 1, 'ir')) {
            word = upcase(next_word);
            end_col = end_start_col+length(next_word);
         }
      }
      // maybe the cursor is on the second part of an "END KEYWORD" sequence
      if (start_col > 2 && pos("^("FOR_BEGIN_WORDS")$", word, 1, 'ir') > 0) {
         p_col = start_col-2;
         prev_word := cur_identifier(auto prev_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: END CASE, WORD BEFORE="prev_word);
         }
         if (upcase(prev_word) == "MODULE") {
            start_col = prev_start_col;
         }
      }

      // maybe the cursor is on the first part of an "SELECT TYPE" sequence
      if (upcase(word) == "SELECT") {
         p_col = end_col+2;
         next_word := cur_identifier(auto end_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: SELECT CASE, WORD AFTER="next_word);
         }
         if (upcase(next_word) == "TYPE" || upcase(next_word) == "CASE") {
            end_col = end_start_col+length(next_word);
         }
      }
      // maybe the cursor is on the second part of an "END KEYWORD" sequence
      if (start_col > 2 && (upcase(word) == "TYPE" || upcase(word) == "CASE")) {
         p_col = start_col-2;
         prev_word := cur_identifier(auto prev_start_col);
         if (_pmdebug) {
            say("_for_find_matching_word: END CASE, WORD BEFORE="prev_word);
         }
         if (upcase(prev_word) == "SELECT") {
            word = upcase(prev_word);
            start_col = prev_start_col;
         }
      }

      if (_pmdebug) {
         say("_for_find_matching_word H"__LINE__": =======================================");
         say("_for_find_matching_word H"__LINE__": word="word);
      }

      restore_pos(p);
      if (pos("^("FOR_BEGIN_WORDS"|"FOR_MIDDLE_WORDS")$", upcase(word), 1, 'ir') > 0) {
         p_col = end_col;
         if (!_for_match_next_word(word)) {
            return 0;
         }
      }
      if (pos("^("FOR_END_WORDS")$", word, 1, 'ir') > 0) {
         p_col = start_col;
         if (!_for_match_prev_word(word)) {
            return 0;
         }
      }
   }

   restore_pos(p);
   return(1);
}

