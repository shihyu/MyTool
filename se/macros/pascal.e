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
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "cbrowser.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "markfilt.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for pascal syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                       value to avoid abbreviation expansion.
       2             Keyword case. Values may be 0,1, or 2 which correspond
                       to lower case, upper case, and capitalized.  Default
                       is 0.
       3             Begin/end style.  Begin/end style may be 0 or 1 (nonzero)
                       as show below. Default is 0.

                      Style 0
                          if expr then begin
                             statemens...
                          end;

                      Style 1
                          if expr then
                          begin
                             statements...
                          end;

                     Add 4 to the value if you want begin/end pairs inserted
                     during expansion.  (defaults to on).  Add 8 to the value
                     if you want Delphi syntax expansions.

       4             End commenting.  Defaults to 1.  0 is off, 1 is on.  Comments
                       ends with the keyword they are ending.  ex: end; { for }
       5             Indent constant from CASE.  Default is 1.  Specify
                       1 if you want constant statements indented from the
                       CASE statement.
*/

//Delphi Constants
static const D_ENTER_WORDS=  (" automated begin case class dispinterface except exports":+\
                        " else finalization finally for initialization interface":+\
                        " private protected public published record":+\
                        " repeat var then try type uses const while with on ");
/* Space words must be in sorted order */
static const D_EXPAND_WORDS= " begin else implementation interface label overlay property writeln ";
static const D_DECL_WORDS= " const exports finalization initialization label type uses var ";

//Regular pascal constants
static const PAS_ENTER_WORDS= (" begin case else for record repeat var then type const while with ");
/* Space words must be in sorted order */
static const PAS_EXPAND_WORDS= " begin else label overlay writeln ";
static const PAS_DECL_WORDS= " const label type var ";

static const PASCAL_COMMON_END_OF_STATEMENT_RE= "begin|end|case|while|repeat|if|then|else|of|until|do|for|to|downto|with|raise|try|except|finally|label|goto";
static const PASCAL_NOT_FUNCTION_WORDS= " begin end case while repeat if then else of until do for downto with raise try except finally label goto when ";

static SYNTAX_EXPANSION_INFO d_space_words:[] = {
   "automated"      => { "automated" },
   "begin"          => { "begin" },
   "case"           => { "case ... of" },
   "class"          => { "class" },
   "const"          => { "const" },
   "constructor=block"=> { "constructor ... begin ... end;" },
   "constructor"    => { "constructor" },
   "destructor=block"=> { "destructor ... begin ... end;" },
   "destructor"     => { "destructor" },
   "dispinterface"  => { "dispinterface" },
   "else"           => { "else" },
   "exports"        => { "exports" },
   "finalization"   => { "finalization" },
   "for"            => { "for ... := ... to ... do ..." },
   "function-block" => { "function ... begin ... end;" },
   "function"       => { "function" },
   "goto"           => { "goto" },
   "implementation" => { "implementation" },
   "inherited"      => { "inherited" },
   "if"             => { "if ... then" },
   "initialization" => { "initialization" },
   "interface"      => { "interface" },
   "label"          => { "label" },
   "library"        => { "library ... begin ... end." },
   "on"             => { "on ... do ..." },
   "overlay"        => { "overlay" },
   "private"        => { "private" },
   "procedure-block"=> { "procedure ... begin ... end;" },
   "procedure"      => { "procedure" },
   "program"        => { "program ... begin ... end." },
   "property"       => { "property" },
   "protected"      => { "protected" },
   "public"         => { "public" },
   "published"      => { "published" },
   "raise"          => { "raise" },
   "record"         => { "record" },
   "repeat"         => { "repeat ... until ... ;" },
   "try_except"     => { "try ... except ... end;" },
   "try_finally"    => { "try ... finally ... end;" },
   "type"           => { "type" },
   "unit"           => { "unit ... interface ... implementation ... end." },
   "uses"           => { "uses" },
   "var"            => { "var" },
   "while"          => { "while ... do ..." },
   "with"           => { "with ... do ..." },
   "writeln"        => { "writeln('" },
};

static SYNTAX_EXPANSION_INFO pas_space_words:[] = {
   "begin"          => { "begin" },
   "case"           => { "case ... of" },
   "const"          => { "const" },
   "else"           => { "else" },
   "for"            => { "for ... := ... to ... do ..." },
   "function-block" => { "function ... begin ... end;" },
   "function"       => { "function" },
   "if"             => { "if ... then ..." },
   "goto"           => { "goto" },
   "label"          => { "label" },
   "overlay"        => { "overlay" },
   "procedure-block"=> { "procedure ... begin ... end;" },
   "procedure"      => { "procedure" },
   "program"        => { "program ... begin ... end." },
   "record"         => { "record" },
   "repeat"         => { "repeat ... until ... ;" },
   "type"           => { "type" },
   "var"            => { "var" },
   "while"          => { "while ... do ..." },
   "with"           => { "with ... do ..." },
   "writeln"        => { "writeln('" },
};

static _str gtkinfo;
static _str gtk;

defeventtab pascal_keys;
def ' '= pascal_space;
def 'ENTER'= pascal_enter;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;


/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _pas_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

/**
 * Activates PASCAL file editing mode.  The ENTER and SPACE BAR 
 * bindings are changed as well as the tab and margin settings.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void pascal_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   /* The SELECT_EDIT_MODE procedure can find the file extension setup */
   /* data by passing it the 'pas' extension. */
   _SetEditorLanguage("pas");
}

/**
 * New binding of ENTER key when in PASCAL mode.  Handles syntax 
 * expansion and indenting for files with PAS extension.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void pascal_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_pas_expand_enter);
}
bool _pas_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _pas_supports_insert_begin_end_immediately() {
   return true;
}
/**
 * New binding of SPACE key when in PASCAL mode.  Handles syntax 
 * expansion and indenting for files with PAS extension.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void pascal_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
        _in_comment() ||
        pas_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=="") {
      _undo('S');
   }
}

int pascal_get_info(var Noflines,var cur_line,var first_word,var last_word,
                    var rest,var non_blank_col,var semi,var prev_semi,
                    bool in_smart_paste=false)
{
   typeless old_pos;
   save_pos(old_pos);
   line := "";
   stuff := "";
   before_brace := "";
   first_word="";last_word="";non_blank_col=p_col;
   b := false;
   orig_col := p_col;
   int i,j;
   for (j=0; ; ++j) {
      get_line(cur_line);
      if (in_smart_paste) {
         _begin_line();
         i=verify(cur_line,' '\t);
         if ( i ) p_col=text_col(cur_line,i,'I');
         b = cur_line!="" && _clex_find(0,'g')!=CFG_COMMENT;
      } else {
         //b = cur_line!="";
         _begin_line();
         i=verify(cur_line,' '\t);
         if ( i ) p_col=text_col(cur_line,i,'I');
         b = cur_line!="" && _clex_find(0,'g')!=CFG_COMMENT;

      }
      if (b) {
#if 0
         parse cur_line with line "(*"; /* Strip comment on current line. */
         parse line with line "{"; /* Strip comment on current line. */
         parse line with line "//"; /* Strip comment on current line. */
         parse line with before_brace "begin",'i' +0 last_word;
#endif
#if 1
         line=cur_line;
         search('begin|$','w@rh');
         last_word='';
         before_brace='';
         //say('ml='match_length());
         if (match_length() && _clex_find(0,'g')==CFG_KEYWORD) {
            before_brace=substr(cur_line,1,_text_colc(p_col,'P'));
            last_word='begin';
            //say('last_word='last_word);
         } else {
            _end_line();
            search('then|do|of|end|record|^','-w@rh');
            //say('h2 ml='match_length());
            if (match_length() && _clex_find(0,'g')==CFG_KEYWORD) {
               //before_brace=substr(cur_line,1,_text_colc(p_col,'P'));
               last_word= get_text(match_length(''), match_length('S'));
               //say('h2 last_word='last_word);
            }
         }
#endif
#if 0
         last_word=strip(last_word);

         //if lastword is "" then need to find the last word other than begin
         if (last_word=="") {
            parse line with stuff "( then| do| of| end| record)",'ri' +0 last_word;  //the spaces make sure that it isn't part of another word
            if (strieq(last_word,"end;")) {  //throw out the semi b/c we just want the end for the last word
               last_word=_word_case("end",false,first_word);
            }
         }

#endif
         parse strip(line,'L') with first_word '[(:; \t]','r' +0 rest;

         if (strieq(last_word,"begin")) {
            save_pos(auto p2);
            p_col=text_col(before_brace);
            _clex_skip_blanks('-');  //searches backwards, skipping blanks and comments till it finds another lexeme
            non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
            restore_pos(p2);
         } else {
            non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
         }
         Noflines=j;
         break;
      }
      if ( up() ) {
         restore_pos(old_pos);
         return(1);
      }
      if (j>=100) {
         restore_pos(old_pos);
         return(1);
      }
   }
   if (in_smart_paste) {
      if (!j) p_col=orig_col;
   }
   semi=pas_stat_has_semi(j? true:false);
   prev_semi=pas_prev_stat_has_semi();
   restore_pos(old_pos);
   return(0);
}

/* Returns non-zero number if pass through to enter key required */
bool _pas_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indentcase := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;
   
   end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   typeless enter_words;
   typeless expand_words;
   typeless decl_words;
   delphi := false;

   if (LanguageSettings.getDelphiExpansions(p_LangId)) {
      enter_words=D_ENTER_WORDS;
      expand_words=D_EXPAND_WORDS;
      decl_words=D_DECL_WORDS;
      delphi=true;
   } else {
      enter_words=PAS_ENTER_WORDS;
      expand_words=PAS_EXPAND_WORDS;
      decl_words=PAS_DECL_WORDS;
      delphi=false;
   }

   Noflines := 0;
   non_blank_col := 0;
   cur_line := "";
   first_word := "";
   last_word := "";
   rest := "";
   semi := "";
   prev_semi := "";
   int status=pascal_get_info(Noflines,cur_line,first_word,last_word,rest,
                              non_blank_col,semi,prev_semi);
   lfirst_word := lowcase(first_word);
   _str llast_word=lowcase(last_word);  //so I don't need to test for different capitals
   _str line=cur_line;

   if (status) return(true);

   //Delphi class statement
   mycol := 0;
   myword := "";
   typeless junk=0;
   typeless p=0;
   typeless p2=0;
   thisline := "";
   myline := "";
   get_line(myline);
   if (pos(':a*[ \t]*=[ \t]*{class|dispinterface|interface}(|[ \t]*\([ \t]*:a#[ \t]*\))',line,1,'ri')) {
      _str class_str = _word_case(substr(line,pos('S0'),pos('0')),false,first_word);
      before := substr(line,1,pos('S0')-1);
      after := substr(line,pos('S0')+pos('0'));
      if (delphi && !pos(';',after) && !pos(' of',after)) {
         replace_line(before:+class_str:+after);
         _save_pos2(p);
         _first_non_blank();
         mycol=text_col(line,p_col,'p');
         if (end_comment) {
            insert_line(indent_string(mycol-1):+_word_case("end; { "class_str" }",false,first_word));
         } else {
            insert_line(indent_string(mycol-1):+_word_case("end;",false,first_word));
         }
         _restore_pos2(p);

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
      indent_on_enter(syntax_indent);
      return(false);
   }
   if (llast_word=="end" && myline!="") {     //line up next line with the block col
      _save_pos2(p);
      mycol=p_col;
      _end_line();
      if (mycol >= p_col) {  //make sure the cursor is at the end of the line, else fall through
         _restore_pos2(p);
         _save_pos2(p2);
         do {
            if (p_col==1) {
               up();_end_line();
            } else {
               --p_col; //move left to get into the end
            }
         } while (_clex_find(0,'g')!=CFG_KEYWORD  ); //this is so it will work with end comments
         do {
            status=_find_matching_paren(def_pmatch_max_diff_ksize);
            myword=lowcase(cur_word(junk));
            if (myword=="begin") { //if it's not begin, it must be a case
               get_line(thisline);
               if (lastpos('[~:]*\:[ \t]*(begin)' ,thisline,1,'ri')) {
                  mycol=verify(thisline,' '\t);
               } else mycol=pas_find_block_col();
               myword=lowcase(cur_word(junk));
            } else mycol=p_col;
         } while (myword=="end" && !status);  //in case they are indenting the elses in style 1

         _restore_pos2(p2);
         insert_line("");
         p_col=mycol;
         return(false);
      }
      _restore_pos2(p);

   }

   col := 0;
   col2 := 0;
   num := 0;
   newcol := 0;
   split_pos := 0;
   next_line := "";
   keyword := "";
   function_name := "";
   before := "";
   typeless stuff="";
   status=0;
   _str expanded_line = expand_tabs(line);
   _str raw_expanded_line = _rawText(expanded_line);
   if ( expand && ! Noflines &&
        !(_rawSubstr(raw_expanded_line,p_col)!=""  && /*_expand_tabsc(p_col)!="" && */
          (_will_split_insert_line()
          )
         )
      ) {
      if (lfirst_word=="for" && name_on_key(ENTER):=="nosplit-insert-line" ) {
         if ( name_on_key(ENTER):!="nosplit-insert-line" ) {
            if ( (be_style == BES_BEGIN_END_STYLE_2) || semi ) {
               return(true);
            }
            indent_on_enter(syntax_indent);
            return(false);
         }
         /* tab to fields of pascal for statement */
         line=expand_tabs(line);
         parse lowcase(line) with before ":=";
         if ( length(before)+1>=p_col ) {
            p_col=length(before)+4;
         } else {
            parse lowcase(line) with before "to";
            if ( length(before)>=p_col ) {
               p_col=length(before)+4;
            } else {
               indent_on_enter(syntax_indent);
            }
         }
      } else if (expand && pos(" "lfirst_word" "," library program procedure function constructor destructor ")) {
         /* If next line is begin key word, comment begin/end with function name */
         save_pos(p);
         get_line(thisline);
         parse thisline with "(library|program|procedure|function|constructor|destructor)",'ir' junk;
         if (junk!="") {
            num=1;
            if (lfirst_word=="program" || lfirst_word=="library") {
               num++;    //the extra is so that there is a space between the begin of the program and any function headers.
            }
            down(num);
            get_line(next_line);
            if ( strieq(next_line,"begin") && p_col>text_col(line) ) {
               if (end_comment) {   //if end commenting is on, comment with the function name
                  up(num);
                  parse line with keyword function_name '([\:\(;])|$','r';
                  down(num);
                  function_name=strip(function_name);
                  replace_line(next_line" { "function_name" }");
                  down();
                  get_line(line);
                  if ( strieq(line,"end;") || strieq(line,"end.") ) {
                     replace_line(line" { "function_name" }");
                  }
                  // notify user that we did something unexpected
                  notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
               }
            }
            restore_pos(p);
            indent_on_enter(0);
         } else {
            replace_line(_word_case(lfirst_word,false,first_word)); //move it over and capitalize
            indent_on_enter(syntax_indent);
         }
      } else if (llast_word=="begin") {
         get_line(myline);
         parse line with stuff 'begin','i';
         replace_line(stuff:+_word_case("begin",false,first_word));

         // is there already an end?  if not, insert one
         _save_pos2(p);
         status=_find_matching_paren(def_pmatch_max_diff_ksize, true);
         _restore_pos2(p);

         surround := false;
         if (status) {
            pas_insert_end(be_style,end_comment,1);
            // notify user that we did something unexpected
            notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
            surround = true;
            status = 0;
         }

         // either way, do indent
         indent_on_enter(syntax_indent);

         if (surround) {
            do_surround_mode_keys();
         }
      } else if (lfirst_word=="case") {
         if (!indentcase) {
            indent_on_enter(0);
         } else {
            status=1;
         }
      } else if (pos(" "lfirst_word" "," automated private protected public published ") && lfirst_word==lowcase(strip(line))) {
         save_pos(p);
         int indent_col = _text_colc()-length(lfirst_word);//pos(lfirst_word, line, 1, 'i');
         status=search(':v[ \t]*=[ \t]*class?*$','@rhi-');
         if (status) {
            restore_pos(p);
            status=search('class?*$','@rhwi-');
         }
         if (!status) {
            indent_col = _text_colc(p_col)-match_length("");
         }
         restore_pos(p);
         replace_line(indent_string(indent_col):+_word_case(lfirst_word,false,first_word));
         insert_line(indent_string(indent_col+syntax_indent));
      } else if ( expand && (lfirst_word=="unit") ) {  //Delphi
         get_line(thisline);
         parse thisline with 'unit','i' junk;
         if (junk!="") {
            if ( p_col>text_col(line)) {
               save_pos(p);
               if (end_comment) {   //if end commenting is on, comment with the function name
                  parse line with keyword function_name '([\:\(;])|$','r';
                  down(10);
                  function_name=strip(function_name);
                  get_line(line);
                  if ( strieq(line,"end.") ) {
                     replace_line(line" { "function_name" }");
                  }
                  restore_pos(p);

                  // notify user that we did something unexpected
                  notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
               }
               if (_find_keyword("interface")!="") {
                  down();
                  get_line(line);
                  if (line=="") {
                     down();
                     get_line(line);
                     if (line=="") {
                        down();
                        get_line(line);
                        up();
                        if (line=="") {
                           _begin_line();
                        } else {
                           up();
                           insert_line("");
                        }
                     } else {
                        up(2);
                        insert_line("");
                        status=1;
                     }
                  } else {
                     up();
                     insert_line("");
                     status=1;
                  }
               } else {
                  status=1;
               }
            } else {
               status=1;
#if 0
               col=p_col;        //the col stuff is so that it won't indent if it's at the beginning of the line
               _end_line();
               col2=p_col;
               p_col=col;
               if (col2!=col) {
                  call_root_key(ENTER);
               } else indent_on_enter(syntax_indent);
#endif
            }
         } else {
            replace_line(_word_case("unit",false,first_word)); //move it over and capitalize
            indent_on_enter(syntax_indent);
         }
      } else if (llast_word=="record") {
         //say("pascal_expand_enter: record");
         get_line(thisline);
         parse thisline with before "record",'i';
         replace_line(before:+_word_case("record",false,first_word));
         _save_pos2(p);
         _first_non_blank();
         mycol=p_col-1;
         if (end_comment) {
            insert_line(indent_string(mycol):+_word_case("end; {",false,first_word):+" ":+_word_case("record }",false,first_word));
         } else {
            insert_line(indent_string(mycol):+_word_case("end;",false,first_word));
         }
         _restore_pos2(p);

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
         indent_on_enter(syntax_indent);

      } else if (llast_word=="class" || llast_word=="interface" || llast_word=="dispinterface") { //Delphi
         //say("pascal_expand_enter: class");
         get_line(thisline);
         if (llast_word=="class") {
            parse thisline with before "class",'i';
         } else if (llast_word=="interface") {
            parse thisline with before "interface",'i';
         } else if (llast_word=="dispinterface") {
            parse thisline with before "dispinterface",'i';
         }
         replace_line(before:+_word_case(llast_word,false,first_word));
         _save_pos2(p);
         _first_non_blank();
         mycol=p_col-1;
         if (end_comment) {
            insert_line(indent_string(mycol):+_word_case("end; { ",false,first_word):+_word_case(llast_word,false,first_word)" }");
         } else {
            insert_line(indent_string(mycol):+_word_case("end;",false,first_word));
         }
         _restore_pos2(p);

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
         indent_on_enter(syntax_indent);

      } else if (pos(" "lfirst_word" ",decl_words,1,'i')) {  //was llast word
         _save_pos2(p);
         get_line(thisline);
         col=p_col;        //the col stuff is so that it won't indent if it's at the beginning of the line
         _end_line();
         col2=p_col;
         p_col=col;
         if (col2 > col) {
            call_root_key(ENTER);
         } else {
            _restore_pos2(p);
            replace_line(_word_case(lfirst_word,false,first_word));
            split_pos = pos(lfirst_word,thisline)+length(lfirst_word)+1;
            insert_line(indent_string(syntax_indent):+substr(thisline,split_pos));
            p_col=1+syntax_indent; //two indents
         }


      } else if (pos(" "lfirst_word" ",enter_words,1,'i')) {
         mycol=p_col;
         _end_line();
         newcol=p_col;
         p_col=mycol; //move it back
         if (mycol < newcol) {
            indent_on_enter(0);
         } else indent_on_enter(syntax_indent);
      } else {
         status=1;
      }
   } else {
      status=1;
   }
   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      col=pas_indent_col(non_blank_col);
      indent_on_enter(0,col);
   }
   return(status != 0);

}

int pas_indent_col(int non_blank_col, bool pasting_open_block = false)
{
   typeless status=0;
   Noflines := 0;
   typeless cur_line=0;
   first_word := "";
   last_word := "";
   rest := "";
   typeless semi=0;
   typeless prev_semi=0;
   int nbc = non_blank_col;

   status = pascal_get_info(Noflines, cur_line, first_word, last_word, rest,
                                non_blank_col, semi, prev_semi, false);

   if (status) {
      return nbc;
   }
   lfirst_word := lowcase(first_word);
   llast_word := lowcase(last_word);
   
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      return(non_blank_col);
   }
   is_structure := pos(" "lfirst_word" "," if repeat while case for ");
   parse cur_line with cur_line '\(\*|\{|//','r';
   cur_line=strip(cur_line,'T');
   if (_last_char(cur_line)==":" && substr(cur_line,1,1)=="") {
      is_structure=1;
   }
   past_non_blank := p_col>non_blank_col || name_on_key(ENTER)=="nosplit-insert-line";
   //messageNwait('is_struct='is_structure' semi='semi' psemi='prev_semi' firstw='first_word' lastw='last_word)

#if 1
   save_pos(auto p);
   line := "";
   up(Noflines);get_line(line);
   // Check for statement like this
   //
   //   if ( func(a,b,
   //          c,(d),(e) )) return;
   //
   //  look for last paren which matches to paren on different line.
   //
   i := j := 0;
   if (Noflines) {
      i=length(line);
   } else {
      i=text_col(line,p_col,'p')-1;
   }

   color := 0;
   word := "";
   myword := "";
   mycol := 0;
   col := 0;
   typeless junk=0;
   typeless pline=point();
   for (;;) {
      if (i<=0) break;
      j=lastpos(")",line,i);
      if (!j) break;
      p_col=text_col(line,j,'I');
      color=_clex_find(0,'g');
      if (color==CFG_COMMENT || color==CFG_STRING) {
         i=j-1;
         continue;
      }
      status=_find_matching_paren(def_pmatch_max_diff_ksize);
      if (status) break;
      if (pline!=point()) {
         //messageNwait('special case');
         _first_non_blank();
         non_blank_col=p_col;
         get_line(line);
         parse line with word . ;
         word=lowcase(word);  //for pascal keywords
         is_structure=pos(" "word" "," if repeat while case for ");
         //restore_pos(p);
         //return(col);
      }
      i=j-1;
   }
   if (llast_word=="end") {     //this will find the block col that the end belongs to
      _end_line();
      status=0;
      do {
         if (p_col==1) {
            status=1;
            break;
         }
         left();
      } while (_clex_find(0,'g')!=CFG_KEYWORD );  //this is safe since we know there is an end on the line
      if (!status) {
         do {
            status=_find_matching_paren(def_pmatch_max_diff_ksize);
            myword=lowcase(cur_word(junk));
            if (myword=="begin") { //if it's not begin, it must be a case
               mycol=pas_find_block_col();
               myword=lowcase(cur_word(junk));
            } else mycol=p_col;
         } while (myword=="end" && !status);  //in case they are indenting the elses in style 1
         restore_pos(p);
         return(mycol);
      }
   }
   restore_pos(p);
#endif
   if (
      ((llast_word=="begin"||  llast_word=="then") && past_non_blank) ||
      (is_structure && ! semi && past_non_blank && !pasting_open_block) ||
      pos('else$',strip(cur_line),1,'r') || (lfirst_word=="else" && !semi) ||
      (is_structure && llast_word=="begin" && past_non_blank) ) {
      return(non_blank_col+syntax_indent);
      /* Look for spaces, end brace, spaces, comment */
   } else if ( (semi && ! prev_semi)) {
      // OK we are a little lazy here. If the dangling statement is not indented
      // correctly, then neither will this statement.
      //
      //     if (
      //             )
      //             i=1;
      //         <end up here> and should be aligned with if
      //
      col=non_blank_col-syntax_indent;
      if ( col<=0 ) {
         col=1;
      }
      if ( col==1 ) {
         return(non_blank_col);
      }
      return(col);
   }
   return(non_blank_col);

}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
bool pas_is_start_block()
{
   save_pos(auto p);
   _first_non_blank();
   col := 0;
   _str word = cur_word(col);
   p_col=col;
   word = lowcase(word);
   restore_pos(p);

   return strieq(word, "begin");
}

static typeless pas_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indentcase := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;
   end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);

   typeless space_words;
   typeless enter_words;
   typeless expand_words;
   typeless decl_words;
   delphi := false;

   if (LanguageSettings.getDelphiExpansions(p_LangId)) {
      space_words=d_space_words;
      enter_words=D_ENTER_WORDS;
      expand_words=D_EXPAND_WORDS;
      decl_words=D_DECL_WORDS;
      delphi=true;
      //say("pas_expand_space: delphi");
   } else {
      space_words=pas_space_words;
      enter_words=PAS_ENTER_WORDS;
      expand_words=PAS_EXPAND_WORDS;
      decl_words=PAS_DECL_WORDS;
      delphi=false;
      //say("pas_expand_space: pascal");
   }

   /* Put first word of line in lower case into word variable. */
   get_line(auto orig_line);
   line := strip(orig_line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 || (p_col==1 && line=='')) {
      return(1);
   }

   Noflines := 0;
   non_blank_col := 0;
   cur_line := "";
   first_word := "";
   last_word := "";
   rest := "";
   semi := "";
   prev_semi := "";
   int status=pascal_get_info(Noflines,cur_line,first_word,last_word,rest,
                          non_blank_col,semi,prev_semi);

   lfirst_word := lowcase(first_word);
   _str llast_word=lowcase(last_word);  //so I don't need to test for different capitals

   //say("pas_expand_space: lfirst_word="lfirst_word" llast_word="llast_word);

   aliasfilename := "";
   _str word=min_abbrev2(orig_word,space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   //say("pas_expand_space: word="word);
   name := "";
   second_word := "";
   lfirst := "";
   lsecond := "";
   myline := "";
   typeless p=0;
   mycol := 0;
   if_special_case := 0;
   indent_value := 0;

   // since we check stuff on the end of the line, we have to keep 
   // two flags for notification
   specialCaseNotify := false;
   doNotify := true;
   if ( word=="") {
      //say("pas_expand_space: word=="" line=|"line"|");
      if (pos(':a*[ \t]*=[ \t]*{class|interface|dispinterface}[ \t]*(|\([ \t\*:a*[ \t]*\))',line,1,'ri') /*&& pos('keyin-match-paren',name)*/ && delphi) {
         _str class_str = _word_case(substr(line,pos('S0'),pos('0')),false,first_word);
         before := substr(line,1,pos('S0')-1);
         after := substr(line,pos('S0')+pos('0'));
         //say("class_str="class_str" before="before " after="after);
         if (delphi && !pos(";",after) && !pos(" of",after)) {
            replace_line(before:+class_str:+after);
            _save_pos2(p);
            _first_non_blank();
            mycol=text_col(line,p_col,'p');
            if (end_comment) {
               insert_line(indent_string(mycol-1):+_word_case("end; { ",false,first_word):+class_str" }");
            } else {
               insert_line(indent_string(mycol-1):+_word_case("end;",false,first_word));
            }
            _restore_pos2(p);

            specialCaseNotify = true;
         }
      } else {
         // Check for end
         parse orig_line with first_word second_word rest;
         lfirst=lowcase(first_word);
         lsecond=lowcase(second_word);
         //messageNwait('first: 'lfirst' second: 'lsecond' rest: 'rest);
         if (lfirst=="end" && lsecond!="" && rest=="" && lsecond:==substr("els",1,length(lsecond))) {
            keyin(substr("else ",length(lsecond)+1));
            get_line(myline);
            replace_line(_word_case(myline,false,first_word));  //the line only has an end and an if, so this is ok

            // we did something here
            notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

            return(0);
         }
         // Check for else if or end else if
         if (lfirst=="else" && orig_word==substr("else if",1,length(orig_word))) {
            word="else if";
            if_special_case=1;
            if (second_word=='i') {
               indent_value=1;
            }
         } else if (lsecond=="else" && rest!="" && orig_word==substr("end else if",1,length(orig_word))) {
            word="end else if";
            if_special_case=1;
            if (rest=='i') {   //correct spacing if the 'if' is expanded
               indent_value=1;
            }
         }
      }
   }

   // get surround mode ready to rock
   expanded := false;
   set_surround_mode_start_line();

   //line up the end depending on what style.
   typeless stuff="";
   if (llast_word=="begin") {
      get_line(myline);
      parse line with stuff 'begin','i';
      replace_line(stuff:+_word_case("begin",false,first_word));
      pas_insert_end(be_style,end_comment,1);

      specialCaseNotify = true;
      expanded=true;
   }

   thisline := "";
   before := "";
   if (llast_word=="record") {
      //say("pas_expand_space: record");
      get_line(thisline);
      parse thisline with before 'record','i';
      replace_line(before:+_word_case("record",false,first_word));
      _save_pos2(p);
      _first_non_blank();
      mycol=p_col-1;
      if (end_comment) {
         insert_line(indent_string(mycol):+_word_case("end; {",false,first_word):+" ":+_word_case("record }",false,first_word));
      } else {
         insert_line(indent_string(mycol):+_word_case("end;",false,first_word));
      }

      _restore_pos2(p);
      specialCaseNotify = true;
      expanded = true;
   }

   //Dan changed for new alias expansion 11:16pm 4/18/1996
   /* Is the cursor not at the end of the line or the first word */
   /* not one of the SPACE BAR expansion key words. */
   if (word=="" && !if_special_case && !expanded) {

      if (specialCaseNotify) {
         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
      return(1);
   }

   /* Insert the appropriate template based on the key word. */
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   temp_col := 0;
   num := 0;
   typeless code=0;

   //messageNwait('if special='if_special_case);
   if ( word=="if" || if_special_case==1 ) {
      replace_line(_word_case(line,false,first_word):+_word_case("  then",false,first_word));
      _save_pos2(p);
      if (be_style == BES_BEGIN_END_STYLE_2) {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)_word_case("begin",false,first_word));
            pas_insert_end(be_style,end_comment, 0);
            _restore_pos2(p);
         }
         //p_col=width+4;
         p_col+=1;
         if (if_special_case/*and first word isn't end*/) {
            p_col+=indent_value;
         }
         //messageNwait('if, style 1');
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            replace_line(_word_case(line,false,first_word):+_word_case("  then",false,first_word):+" ":+_word_case("begin",false,first_word));
            _end_line(); //cursor needs to be at the end of line for insert_end to work
            pas_insert_end(be_style,end_comment, 0);
            _restore_pos2(p);
         }
         p_col+=1;
         if (if_special_case) {
            p_col+=indent_value;
         }
         //messageNwait('if, style 0');
         if ( ! _insert_state() ) {
            _insert_toggle();
         }

      }
   } else if ( word=="for" ) {
      replace_line(_word_case(_word_case(line):+" :=  "_word_case("to")"  "_word_case("do"),false,first_word));
      _save_pos2(p);
      if (be_style == BES_BEGIN_END_STYLE_2) {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)_word_case("begin",false,first_word));
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
         }
         p_col=width+5;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            replace_line(_word_case(line,false,first_word):+" :=  ":+_word_case("to",false,first_word):+"  ":+_word_case("do",false,first_word):+" ":+_word_case("begin",false,first_word));
            _end_line(); //cursor needs to be at the end of line for insert_end to work
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
            p_col+=1;
         } else p_col+=1;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      }
   } else if ( word=="with" ) {
      replace_line(_word_case(_word_case(line):+"  "_word_case("do"),false,first_word));
      _save_pos2(p);
      if (be_style == BES_BEGIN_END_STYLE_2) {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)_word_case("begin",false,first_word));
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
         }
         p_col=width+6;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            replace_line(_word_case(line,false,first_word):+"  ":+_word_case("do",false,first_word):+" ":+_word_case("begin",false,first_word));
            _end_line(); //cursor needs to be at the end of line for insert_end to work
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
            p_col+=1;
         } else p_col+=1;

         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      }
   } else if (word=="while") {

      replace_line(_word_case(line"  do",false,first_word));
      _save_pos2(p);
      if (be_style == BES_BEGIN_END_STYLE_2) {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)_word_case("begin",false,first_word));
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
         }
         p_col=width+7;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            replace_line(_word_case(line"  do",false,first_word):+" ":+_word_case("begin",false,first_word));
            _end_line(); //cursor needs to be at the end of line for insert_end to work
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
            p_col=width+7;
         } else p_col=width+7;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      }
   } else if ( word=="case" ) {
      replace_line(_word_case(line"  of",false,first_word));
      p_col=width+6;
      if ( ! _insert_state() ) {
         _insert_toggle();
      }
   } else if ( word=="repeat" ) {
      replace_line(_word_case(line,false,first_word));
      insert_line(indent_string(width)_word_case("until  ;",false,first_word));
      up();nosplit_insert_line();
      set_surround_mode_end_line(p_line+1);
      p_col += syntax_indent;
   } else if (word=="inherited" || word=="goto" || word=="raise") {
      newLine := _word_case(line,false,first_word)" ";
      replace_line(newLine);
      _end_line();
      list_symbols();

      doNotify = (newLine != line);
   } else if (pos(" "word" "," automated private protected public published ")) {
      save_pos(p);
      int indent_col = _text_colc()-length(lfirst_word);//pos(lfirst_word, line, 1, 'i');
      status=search(':v[ \t]*=[ \t]*class?*$','@rhi-');
      if (status) {
         restore_pos(p);
         status=search('class?*$','@rhwi-');
      }
      if (!status) {
         indent_col = _text_colc(p_col)-match_length("");
      }
      restore_pos(p);
      replace_line(indent_string(indent_col):+_word_case(word,false,first_word));
      insert_line(indent_string(indent_col+syntax_indent));
   } else if (word=="with") {
      replace_line(_word_case(line,false,first_word):+"  ":+_word_case("do",false,first_word));
      _save_pos2(p);
      if (be_style == BES_BEGIN_END_STYLE_2) {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)_word_case("begin",false,first_word));
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
         }
         p_col=width+7;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            replace_line(_word_case(line,false,first_word):+"  ":+_word_case("do",false,first_word):+" ":+_word_case("begin",false,first_word));
            _end_line(); //cursor needs to be at the end of line for insert_end to work
            pas_insert_end(be_style,end_comment,1);
            _restore_pos2(p);
            p_col=width+7;
         } else p_col=width+7;
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
      }
   } else if (pos(" "word" "," library program procedure function constructor destructor procedure-block function-block constructor-block destructor-block ")) {
      save_pos(p);
      _first_non_blank();
      mycol=p_col;
      restore_pos(p);

      // Just incase we are in a class definition, require
      // user to type entire word.
      if (orig_word=="procedure" || orig_word=="function" ||
          orig_word=="constructor" || orig_word=="destructor" ||
          (mycol!=1 && !pos("-block",word))) {
         get_line(thisline);
         parse thisline with before '(procedure|function)','ri';
         newLine := indent_string(mycol-1):+_word_case(word,false,first_word);
         replace_line(newLine);
         _end_line();
         p_col++;

         doNotify = (newLine != thisline);
      } else {
         parse word with word "-block";
         temp_col=p_col;
         code=down();
         get_line(myline);
         if (1 /*!pos('begin',myline,1,'I')*/) {
            if (!code) { //down was successfull
               up();
            }
            p_col=temp_col;
            num=2;
            if (word=="program" || word=="library") {
               insert_line(" "); //this is so the keys function and procedure will expand (begin not on next line)
               num++;
            }
            insert_line(indent_string(width):+_word_case("begin",false,first_word));   //don't care if its in the wrong place, will fix below
            col:=_pas_last_prog_col()-1;  //begin has to be there so it will match up
            up(num-1);                    //need to use strange order so that the begin is there for last_prog_col
            if (col==0) {
               replace_line(_word_case(word,false,first_word));
            } else {
               replace_line(indent_string(col)_word_case(word,false,first_word));
            }
            down(num-1);
            //_end_line;
            replace_line(indent_string(col)_word_case("begin",false,first_word));   //fix where the begin is
            if ( word == "program" || word=="library") {
               insert_line(_word_case("end.",false,first_word));
            } else {
               insert_line(indent_string(col):+_word_case("end;",false,first_word));
            }
            up(num);_end_line();right();
         } else {
            if (!code) up();
            keyin(" ");
            doNotify = false;
         }
      }

   } else if ( word=="writeln" ) {
      replace_line(indent_string(width)"writeln('");
      _end_line();
   } else if (word=="on") {   //Delphi
      replace_line(_word_case(line,false,first_word):+"  ":+_word_case("do",false,first_word));
      p_col=width+4;
   } else if (word=="try_except") {  //Delphi
      parse line with before "try_except",'i' rest;
      line=before:+"try":+rest;
      replace_line(_word_case(line,false,first_word));
      _save_pos2(p);
      insert_line(indent_string(width):+_word_case("except",false,first_word));
      if (end_comment) {
         insert_line(indent_string(width)_word_case("end; {",false,first_word):+" ":+_word_case("try }",false,first_word));
      } else {
         insert_line(indent_string(width)_word_case("end;",false,first_word));
      }
      _restore_pos2(p);
      p_col=width+5;
      set_surround_mode_end_line(p_line+1,2);
   } else if (word=="try_finally") {  //Delphi
      parse line with before "try_finally",'i' rest;
      line=before:+"try":+rest;
      replace_line(_word_case(line,false,first_word));
      _save_pos2(p);
      insert_line(indent_string(width):+_word_case("finally",false,first_word));
      if (end_comment) {
         insert_line(indent_string(width)_word_case("end; {",false,first_word):+" ":+_word_case("try }",false,first_word));
      } else {
         insert_line(indent_string(width)_word_case("end;",false,first_word));
      }
      _restore_pos2(p);
      p_col=width+5;
      set_surround_mode_end_line(p_line+1,2);
   } else if ( word=="unit" ) {  //Delphi
      replace_line(_word_case(word,false,first_word));  //this always starts it in col 1
      _end_line();
      _save_pos2(p);
      insert_line("");
      insert_line(_word_case("interface",false,first_word));
      insert_line("");
      insert_line("");
      insert_line("");
      insert_line(_word_case("implementation",false,first_word));
      insert_line("");
      insert_line("");
      insert_line("");
      insert_line(_word_case("end.",false,first_word));
      _restore_pos2(p);
      p_col+=1;
   } else if ( pos(" "word" ",decl_words) ) {
      newLine := _word_case(word,false,first_word)" ";
      replace_line(newLine);
      insert_line("");
      p_col=1+syntax_indent; //two indents

      doNotify = (newLine != orig_line);
   } else if ( pos(" "word" ",expand_words) ) {
      newLine := indent_string(width)_word_case(word,false,first_word)" ";
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != orig_line);
   } else {
      _insert_text(" ");
      doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(0);
}

int _pas_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   typeless space_words;
   if (LanguageSettings.getDelphiExpansions(p_LangId)) {
      space_words=d_space_words;
   } else {
      space_words=pas_space_words;
   }
   return AutoCompleteGetSyntaxSpaceWords(words, space_words, prefix, min_abbrev);
}

/**
 * Callback used by dynamic surround to do 
 * language specific indentation and un-indentation.
 * 
 * @param direction '+' for indent, '-' for unindent
 */
void _pas_indent_surround(_str direction)
{
   // get the begin / end style setting
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   doSecondIndent := (p_begin_end_style == BES_BEGIN_END_STYLE_2);

   // check if we are in a try/except/end or try/finally/end
   // instead of a statement with conventional begin end
   if (doSecondIndent) {
      save_pos(auto p);
      if (direction=="+") {
         down();
      } else {
         up(2);
      }
      _str line, first_word;
      get_line(line);
      parse line with first_word .;
      if (lowcase(first_word)=="except" || lowcase(first_word)=="finally") {
         doSecondIndent=false;
      }
      restore_pos(p);
   }

   if (direction=="+") {
      _indent_line(false);
      if (doSecondIndent) {
         indent_line();
      }
   } else {
      unindent_line();
      if (doSecondIndent) {
         unindent_line();
      }
   }
}

static typeless pas_prev_stat_has_semi()
{
   col := 0;
   line := "";
   myword := "";
   typeless p=0;
   typeless junk=0;
   typeless status=1;
   up();
   if ( ! rc ) {
      col=p_col;_end_line();get_line(line);
      parse line with line '\(\*|\{','r';
      line=strip(line,'T');
      //want this to be last word of line == do, then
      save_pos(p);
      _clex_skip_blanks('-');
      if (_clex_find(0,'g')==CFG_KEYWORD) {
         myword=lowcase(cur_word(junk));
      } else myword=""; //just to make sure

      restore_pos(p);
      if (myword=="then" || myword=="do") {
         status=0;  //if it was a do or a then, the first word must be a while, if or for
      } else {
         status=_last_char(line)!=")" && ! pos('((end)|)else$',line,1,'r');
      }
      down();
      p_col=col;
   }
   return(status);
}
static typeless pas_stat_has_semi(bool argument_one=false)
{
   line := "";
   get_line(line);
   parse line with line "(*";
   parse line with line '\(\*|\{','r';
   line=strip(line,'T');
   return(_last_char(line):==';' &&
          !(( _will_split_insert_line()
            ) && (p_col<=text_col(line) && argument_one)
           )
         );

}


int _pas_last_case_col()
{
   if (p_lexer_name=="") {
      return(0);
   }
   word := "";
   save_pos(auto p);
   // Find case at same brace level
   // search for begin brace,end brace, and case not in comment or string
   typeless status=search('begin|end|case','@rhi-');
   level := 0;
   color := 0;
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      word=get_match_text();
      color=_clex_find(0,'g');
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (lowcase(word)) {
         case "end":
            --level;
            break;
         case "begin":
            ++level;
            break;
         default:
            //messageNwait("_pas_last_case_col: word="word" level="level);
            if (color==CFG_KEYWORD && level== 0) {
               result := p_col;
               restore_pos(p);
               return(result);
            } else ++level;     //must be a case
         }
      }
      status=repeat_search();
   }
}

int _pas_last_prog_col()
{
   if (p_lexer_name=="") {
      return(0);
   }
   save_pos(auto p);
   status := search('program|library|unit','@rhi-');
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      if (color==CFG_KEYWORD) {
         _first_non_blank();
         result := p_col;
         restore_pos(p);
         return(result);
      } else status=repeat_search();
   }


}
int _pas_last_func_col()
{
   if (p_lexer_name=="") {
      return(0);
   }
   save_pos(auto p);
   // Find function header at same brace level
   // search for begin, end and function/program headers
   status := search('program|library|function|procedure|begin|end|unit','@rhi-');   //unit is for delphi.

   level := 1;    //because there are no begins before the var etc. headings
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (lowcase(word)) {
         case "end":
            --level;
            break;
         case "begin":
            ++level;
            break;
         default:
            if (color==CFG_KEYWORD && level== 1) {
               result := p_col;
               restore_pos(p);
               return(result);
            }
         }
      }
      //messageNwait('word:'word' level:'level);
      status=repeat_search();
   }
}

/**
 * Handles the 'n' key - tries to prepare for syntax expansion of the BEGIN 
 * keyword. 
 * 
 * @return typeless 
 *  
 * @deprecated   We now handle expansion in pascal_expand_enter and 
 *               pascal_expand_space
 */
_command pascal_n() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_LASTKEY)
{
   //this function traps the n key so pascal_enter and space can be
   //smarter.
   keyin(event2name(last_event()));
   if (command_state()) {
   } else {
      typeless junk=0;
      _str word=cur_identifier(junk);
      if (upcase(word)=="BEGIN") {
         left(); //so c_lex_find will work
         if (_clex_find(0,'g')==CFG_KEYWORD) {  //probably redundant
            right();
            return("");
         }
         right();
      }
      last_index(0,'C');
   }
}

/**
 * Handles the 'd' key - tries to prepare for syntax expansion of the RECORD 
 * keyword. 
 * 
 * @return typeless 
 *  
 * @deprecated   We now handle expansion in pascal_expand_enter and 
 *               pascal_expand_space
 */
_command pascal_d() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_LASTKEY)
{
   //this function traps the d key so pascal_enter and space can be
   //smarter.
   keyin(event2name(last_event()));
   if (command_state()) {
   } else {
      typeless junk=0;
      _str word=cur_identifier(junk);
      if (upcase(word)=="RECORD") {
         left(); //so c_lex_find will work
         if (_clex_find(0,'g')==CFG_KEYWORD) {  //probably redundant
            right();
            return("");
         }
         right();
      }
      last_index(0,'C');
   }
}

/**
 * Handles the 'y' key - tries to prepare for syntax expansion of the TRY 
 * keyword. 
 * 
 * @return typeless 
 *  
 * @deprecated   We now handle expansion in pascal_expand_enter and 
 *               pascal_expand_space
 */
_command pascal_y() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_LASTKEY)
{
   //this function traps the y key so pascal_enter and space can be
   //smarter.
   keyin(event2name(last_event()));
   if (command_state()) {
   } else {
      typeless junk=0;
      _str word=cur_identifier(junk);
      if (upcase(word)=="TRY") {
         left(); //so c_lex_find will work
         if (_clex_find(0,'g')==CFG_KEYWORD) {  //probably redundant
            right();
            return("");
         }
         right();
      }
      last_index(0,'C');
   }
}

int pas_endbrace_col(int be_style)
{
   if (p_lexer_name=="") {
      return(0);
   }
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   begin_brace_col := p_col;
   // Check if the first char before open brace is close paren
   int col= pas_find_block_col();
   if (!col) {
      restore_pos(p);
      return(0);
   }
   if (be_style == BES_BEGIN_END_STYLE_2) {
      restore_pos(p);
      return(begin_brace_col);
   }
   restore_pos(p);
   return(col);
}

int pas_find_try_col()
{
   if (p_lexer_name=="") {
      return(0);
   }
   save_pos(auto p);
   // Find case at same brace level
   // search for begin brace,end brace, and case not in comment or string
   status := search('begin|end|case|try','@rhi-');

   level := 1;
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (lowcase(word)) {
         case "end":
            --level;
            break;
         case "begin":
         case "case":
            ++level;
            break;
         default:
            if (color==CFG_KEYWORD && level== 1) {
               result := p_col;
               restore_pos(p);
               return(result);
            } else ++level;     //must be a try
         }
      }
      status=repeat_search();
   }
}
static int pas_find_block_col()
{
   temp_col := p_col;
   --p_col;
   if (_clex_skip_blanks('-')) return(0);
   //messageNwait('waiting');
   if (_clex_find(0,'g')!=CFG_KEYWORD) {
      //_message_box("pas_find_block_col: temp_col="temp_col);
      //messageNwait('returning 0 b/c its not a keyword');
      return(temp_col);
   }
   col := 0;
   word := lowcase(cur_word(col));

   //messageNwait('lets see what the word is: 'word);
   if (word=="do" || word=="else" || word=="then" || word=="of") {
      _first_non_blank();
      return(p_col);
      //return(p_col-length(word)+1);
   }
   return(p_col);
}

static int pas_insert_end(int be_style,int end_comment,_str semi)
{
   typeless p;
   _save_pos2(p);
   p_col -= 5;
   //messageNwait('waiting1');
   line := "";
   typeless p2=0;
   style1col := p_col;
   int col=pas_find_block_col()-1;
   //messageNwait('col:'col);
   typeless junk=0;
   _str myword=cur_word(junk);
   if (be_style == BES_BEGIN_END_STYLE_2) {
      _restore_pos2(p);
      _save_pos2(p2);
      if (lowcase(myword)=="if" || lowcase(myword)=="else" || lowcase(myword)=="end") {
         insert_line(indent_string(style1col-1):+_word_case("end",false,myword));
      } else {
         insert_line(indent_string(style1col-1):+_word_case("end;",false,myword));
      }
      if (end_comment && lowcase(myword)!="if" && lowcase(myword)!="end" && lowcase(myword)!="else") {
         get_line(line);
         if (lowcase(myword)=="begin") {
            replace_line(line);
         } else {
            replace_line(line:+" { "_word_case(myword,false,myword)" }");
         }
      }
      set_surround_mode_end_line();
      _restore_pos2(p2);
      p_col+=1;
      return(0);
   }
   _restore_pos2(p);
   _save_pos2(p2);
   if (lowcase(myword)=="if" || lowcase(myword)=="else" || lowcase(myword)=="end") {
      insert_line(indent_string(col):+_word_case("end",false,myword));
   } else {
      insert_line(indent_string(col):+_word_case("end;",false,myword));
   }
   if (end_comment && lowcase(myword)!="if" && lowcase(myword)!="end" && lowcase(myword)!="else") {
      get_line(line);
      if (lowcase(myword)=="begin") {
         replace_line(line);
      } else {
         replace_line(line:+" { "_word_case(myword,false,myword)" }");
      }
   }
   set_surround_mode_end_line();
   _restore_pos2(p2);
   p_col+=1;
   return(0);
}
/*
   Returns string keyword found
*/
static _str _find_keyword(_str re_words)
{
   save_pos(auto p);
   status := search("{"re_words"}","@rh");
   for (;;) {
      if (status) {
         restore_pos(p);
         return("");
      }
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_KEYWORD) {
         word := get_match_text(0);
         return(word);
      }
      status=repeat_search();
   }
}

static int pas_before_dot(_str &prefixexp,_str &lastid)
{
   count := 0;
   status := 0;
   nest_level := 0;

outer_loop:
   for (;;) {
      //say("pas_before_dot: gtkinfo="gtkinfo);
      switch (gtk) {
      case ".":  // watch out for .. (range specifier)
         prefixexp=substr(prefixexp,1,length(prefixexp)-1);
         return(2);
      case "^":
         prefixexp="^":+prefixexp;
         gtk=pas_prev_sym();
         break;
      case "]":
         prefixexp="[]":+prefixexp;
         right();
         status=find_matching_paren(true);
         if (status) {
            return(1);
         }
         left();
         gtk=pas_prev_sym();
         if (gtk!="]") {
            if (gtk!=TK_ID) {
               if (gtk==")") {
                  continue;
               }
               return(1);
            }
            prefixexp=gtkinfo:+prefixexp;
            gtk=pas_prev_sym();
            return(2);  // continue
         }
         break;
      case ")":
         nest_level=0;
         for (count=0;;++count) {
            if (count>200) {
               return(1);
            }
            if (gtk:=="") {
               return(1);
            }
            if (gtk=="]") {
               prefixexp="[]":+prefixexp;
               right();
               status=find_matching_paren(true);
               if (status) {
                  return(1);
               }
               left();
            } else {
               if (gtk==TK_ID) {
                  prefixexp=gtkinfo" ":+prefixexp;
               } else {
                  prefixexp=gtkinfo:+prefixexp;
               }
            }
            if (gtk=="(") {
               --nest_level;
               if (nest_level<=0) {
                  gtk=pas_prev_sym();
                  if (gtk!=TK_ID) {

                     if (gtk=="]") {
                        continue outer_loop;
                     }
                     if (gtk==")") {
                        continue;
                     }
                     return(0);
                  }
                  prefixexp=gtkinfo:+prefixexp;
                  gtk=pas_prev_sym();
                  return(2);// Tell call to continue processing
               }
            } else if (gtk==")") {
               ++nest_level;
            }
            gtk=pas_prev_sym();
         }
         break;
      default:
         return(1);
      }
   }
   return(1);
}
static int pas_before_id(_str &prefixexp,_str &lastid,int &info_flags)
{
   typeless status=0;
   for (;;) {
      //say("pas_before_id: gtk="gtk);
      switch (gtk) {
      case "'":
         if (_LanguageInheritsFrom("ada") || _LanguageInheritsFrom("vhd")) {
            right();
            return ada_before_squote(prefixexp,lastid,info_flags);
         }
         return(0);
      case "^":
      case ".":
         if (get_text(1)==".") {
            if (prefixexp!="") {
               return(0);
            }
            return(1);
         }
         prefixexp=gtkinfo:+prefixexp;
         gtk=pas_prev_sym();
         while (gtk=="^") {
            prefixexp=gtkinfo:+prefixexp;
            gtk=pas_prev_sym();
         }
         if (gtk==TK_ID) {
            prefixexp=gtkinfo:+prefixexp;
            gtk=pas_prev_sym();
         } else {
            status=pas_before_dot(prefixexp,lastid);
            if (status!=2) {
               return(status);
            }
         }
         break;
      case TK_ID:
         if (gtkinfo=="goto") {
            info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
         }
         if (gtkinfo=="raise") {
            info_flags |= VSAUTOCODEINFO_IN_THROW_STATEMENT;
         }
         if (gtkinfo=="inherited") {
            prefixexp="inherited "prefixexp;
            gtk=pas_prev_sym();
         }
         return(0);
      case ',':
      case '(':
         if (_LanguageInheritsFrom("ada") || _LanguageInheritsFrom("vhd")) {
            return ada_record_initializer_case(prefixexp,lastid,info_flags);
         }
         return(0);
      default:
         return(0);
      }
   }
}
static int ada_record_initializer_case(_str &prefixexp,_str &lastid,int &info_flags)
{
   save_pos(auto p);
   orig_prefixexp  := prefixexp;
   orig_lastid     := lastid;
   orig_info_flags := info_flags;
   num_iterations  := 0;

   while (++num_iterations < 200) {
      if (_CheckTimeout()) {
         break;
      }
      if (gtk != ',' && gtk != '(') {
         break;
      }
      if (gtk == '(') {
         gtk=pas_prev_sym();
         if (gtk == ':=' || gtk == '=') {
            gtk = pas_prev_sym();
            if (gtk=="]") {
               prefixexp="[]":+prefixexp;
               right();
               status := find_matching_paren(true);
               if (status) break;
               right();
               gtk = pas_prev_sym();
            }
            if (gtk==TK_ID) {
               identifier := gtkinfo;
               prefixexp = gtkinfo:+prefixexp:+'.';
               gtk=pas_prev_sym();
               status := pas_before_id(prefixexp,lastid,info_flags);
               if (status) {
                  prefixexp=identifier;
               }
               return(0);
            }
         }
         break;
      }
      if (gtk == ',') {
         gtk=pas_prev_sym();
         nesting := 0;
         while (gtk == TK_ID || 
                gtk == TK_NUMBER || 
                gtk == TK_STRING || 
                gtk == '='   || gtk == '=='  ||
                gtk == '<'   || gtk == '<='  ||
                gtk == '>='  || gtk == '>='  ||
                gtk == '=>'  || gtk == '<>'  ||
                gtk == '!='  || gtk == '^'   ||
                gtk == '!'   || gtk == '%'   ||
                gtk == '*'   || gtk == '/'   ||
                gtk == '['   || gtk == ']'   ||
                gtk == '-'   || gtk == '+'   ||
                gtk == '.'   || gtk == '^.'  ||
                gtk == '||'  || gtk == '&&'  ||
                gtk == ".."  || gtk == '#'   ||
                gtk == 'and' || gtk == 'or'  || 
                gtk == 'xor' || gtk == 'not' ||
                gtk == 'div' || gtk == 'mod' ||
                gtk == 'shl' || gtk == 'shr' ||
                gtk == 'is'  || gtk == 'as'  ||
                gtkinfo == 'and' || gtkinfo == 'or'  || 
                gtkinfo == 'xor' || gtkinfo == 'not' ||
                gtkinfo == 'div' || gtkinfo == 'mod' ||
                gtkinfo == 'shl' || gtkinfo == 'shr' ||
                gtkinfo == 'is'  || gtkinfo == 'as'  ||
                gtk == '(' || gtk == ')' ) {
            if (gtk == ')') {
               ++nesting;
            } else if (gtk == '(') {
               --nesting;
               if (nesting < 0) break;
            }
            if (++num_iterations > 200) break;
            if (num_iterations % 25 == 0 && _CheckTimeout()) {
               break;
            }
            gtk=pas_prev_sym();
         }
      }
   }

   // error case, just pretend we didn't look
   prefixexp  = orig_prefixexp;
   lastid     = orig_lastid;
   info_flags = orig_info_flags;
   restore_pos(p);
   return 0;
}
static int ada_before_squote(_str &prefixexp,_str &lastid,int &info_flags)
{
   if (get_text(1) == "'" &&
       get_text(1,(int)point('s')-2)!="'" &&
       get_text(1,(int)point('s')+2)!="'") {
      // this quote is not part of a character constant
      gtk=pas_prev_sym();
      if (gtk=="'") {
         gtk=pas_prev_sym();
         if (gtk==TK_ID && !pos(" "gtkinfo" ",PASCAL_NOT_FUNCTION_WORDS,1,'i')) {
            _str identifier = gtkinfo;
            prefixexp=gtkinfo:+"'":+prefixexp;
            gtk=pas_prev_sym();
            if (gtk!="'" || length(identifier)>1) {
               int status=pas_before_id(prefixexp,lastid,info_flags);
               //say("ada_before_squote: status="status);
               if (status) {
                  prefixexp=identifier:+"'";
               }
               return(0);
            }
         }
      }
   }
   return(1);
}

/////////////////////////////////////////////////////////////////////////////////////
// Is the given ID the name of a built-in pascal, modula, Ada, or VHDL type?
//
static int _pas_is_builtin_type(_str id)
{
   switch (lowcase(id)) {
   case "integer":
   case "double":
   case "currency":
   case "string":
   case "boolean":
   case "date":
   case "real":
   case "single":
   case "extended":
   case "comp":
   case "cardinal":
   case "shortint":
   case "smallint":
   case "longint":
   case "byte":
   case "word":
   case "ansichar":
   case "widechar":
   case "char":
   case "bytebool":
   case "wordbool":
   case "longbool":
   case "bool":
   case "ansistring":
   case "shortstring":
   case "widestring":
      return(1);
   default:
      return(0);
   }
}
/////////////////////////////////////////////////////////////////////////////////////
// Context Tagging&reg; related function for Pascal, Modula, Ada, VHDL, etc.
//
static int _pas_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                                  _str symbol, _str search_class_name,
                                  _str file_name, _str return_type,
                                  VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_pas_parse_return_type("symbol","search_class_name","return_type","file_name")");
   }

   // filter out mutual recursion
   _str input_args="get;"symbol";"search_class_name";"file_name";"return_type";"p_buf_name";"tag_return_type_string(rt);
   int status = _CodeHelpCheckVisited(input_args, "_pas_get_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   found_seperator := false;
   allow_local_class := true;
   _str orig_return_type = return_type;
   found_type := "";
   package_name := "";
   new_package_name := "";
   renamed_to := "";
   parenexp := "";
   ch := "";
   n := p := 0;
   num_args := 0;
   rt.return_type = "";

   while (return_type != "") {
      p = pos('^ @{\[|\]|[.^/]|:v|[@]:i[a-z]}', return_type, 1, 'r');
      if (p <= 0) {
         break;
      }
      p = pos('S0');
      n = pos('0');
      ch = substr(return_type, p, n);
      return_type = substr(return_type, p+n);
      if (_chdebug) {
         isay(depth, "_pas_parse_return_type: ch="ch" return_type="return_type" package_name="package_name);
      }
      switch (ch) {
      case "packed":
      case "in":
      case "out":
      case "inout":
      case "buffer":
         continue;
      case "record":
      case "dispinterface":
      case "interface":
         visited:[input_args]=rt;
         return(0);
      case "class":
         if (!pos("of ",return_type)) {
            visited:[input_args]=rt;
            return(0);
         }
         parse return_type with "of " return_type;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         break;
      case "procedure":
      case "destructor":
         visited:[input_args]=rt;
         return 0;
      case "constructor":
      case "function":
         parse return_type with . "(" . ")" . ":" return_type;
         break;
      case "array":
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         rt.pointer_count++;
         if (pos("[",return_type)==1) {
            return_type=substr(return_type,2);
            if (!match_brackets(return_type, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            return_type=strip(return_type,'L');
            if (pos("of ",return_type)==1) {
               return_type=substr(return_type, 4);
            }
         } else if (pos("(",return_type)==1) {
            // Ada style array
            return_type=substr(return_type,2);
            array_paren_exp := "";
            if (!match_parens(return_type, array_paren_exp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            return_type=strip(return_type,'L');
            if (pos("of ",return_type)==1) {
               return_type=substr(return_type, 4);
            }
         }
         break;
      case ".":
      case "/":
            if (pos("/",package_name)) {
               new_package_name = stranslate(package_name,".","/");
               int package_index = tag_check_for_package(new_package_name, tag_files, true, false, renamed_to, visited, depth+1);
               if (package_index > 0) {
                  if (renamed_to != "") {
                     VS_TAG_RETURN_TYPE package_rt;
                     tag_return_type_init(package_rt);
                     inner_name := outer_name := "";
                     tag_split_class_name(package_name, inner_name, outer_name);
                     if (_pas_parse_return_type(errorArgs, tag_files, inner_name, outer_name, file_name, renamed_to, package_rt, visited, depth+1)==0) {
                        rt = package_rt;
                        new_package_name = rt.return_type;
                     }
                  }
                  package_name = new_package_name :+ "/";
               }
            } else if (package_name != "" && tag_check_for_package(package_name, tag_files, true, false, renamed_to, visited, depth+1) > 0) {
               if (renamed_to != "") {
                  VS_TAG_RETURN_TYPE package_rt;
                  tag_return_type_init(package_rt);
                  inner_name := outer_name := "";
                  tag_split_class_name(package_name, inner_name, outer_name);
                  if (_pas_parse_return_type(errorArgs, tag_files, inner_name, outer_name, file_name, renamed_to, package_rt, visited, depth+1)==0) {
                     rt = package_rt;
                     package_name = rt.return_type;
                  }
               }
               package_name :+= "/";
            } else {
               package_name :+= ".";
            }
         break;
      case "^":
         //if (found_type != "") {
            rt.pointer_count++;
         //}
         //say("PARSE *, pointer_count="pointer_count);
         break;
      case "[":
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         rt.pointer_count++;
         //say("PARSE[], pointer_count="pointer_count);
         break;
      case "]":
         break;
      case "(":
         if (!match_parens(return_type, parenexp, num_args)) {
            // this is not good
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         break;
      case ")":
         break;
      case "access":
         if (_LanguageInheritsFrom("ada") || _LanguageInheritsFrom("vhd")) {
            continue;
         }
         // fall through to ID case
      default:
         // this must be an identifier
         // try simple macro substitution
         //say("XXXXXXXXXXXXXXXXXXX, return_type="return_type);
         //if (_MatchSymbolAsDefine(ch, ch)) {
         if (package_name != "") {
            package_name :+= ch;
            found_type=package_name;
         } else if (found_type != "" && allow_local_class && found_seperator) {
            if (tag_check_for_package(found_type,tag_files,true,false, null, visited, depth+1) > 0) {
               found_type :+= VS_TAGSEPARATOR_package :+ ch;
            } else {
               found_type :+= VS_TAGSEPARATOR_class :+ ch;
            }
            found_seperator = false;
         } else {
            found_type = ch;
            if (tag_check_for_package(found_type,tag_files,true,false, null, visited, depth+1) > 0) {
               package_name = ch;
            }
         }
      }
   }

   //say("search_class="search_class_name" found_type="found_type);
   _str qualified_name = found_type;
   if (pos("/", package_name)) {
      found_type = package_name;
   }

   if (allow_local_class && !pos(VS_TAGSEPARATOR_package, found_type)) {
      //say("JJJJJJ found_type="found_type" return_type="return_type" search_class="search_class_name);
      _str inner_name, outer_name;
      tag_split_class_name(found_type, inner_name, outer_name);
      //say("found_type="found_type" inner_name="inner_name" outer_name="outer_name);
      qualified_name="";
      if (length(outer_name) < length(search_class_name)) {
         //say("inner_name="inner_name" search_class="search_class_name);
         outer_name = tag_join_class_name(inner_name, search_class_name, tag_files, false, true, false, visited, depth+1);
         //say("outer_name="outer_name);
         qualified_name = outer_name;
         if (outer_name :== "" && search_class_name :!= "" && found_type :!= inner_name) {
            outer_name = found_type;
         }
      }
      if (qualified_name=="") {
         //say("JJJJJJJ inner_name="inner_name" outer_name="outer_name);
         tag_qualify_symbol_name(qualified_name,inner_name,outer_name,file_name,tag_files,false, visited, depth+1);
         //say("JJJJJJJ qualify="qualified_name" symbol="symbol" class="search_class_name);
      }
      if (qualified_name=="") {
         qualified_name = found_type;
      }
   }

   // try to handle typedefs
   //say("check for typedef, qualified_name="qualified_name" found_type="found_type);
   qualified_inner := "";
   qualified_outer := "";
   tag_split_class_name(qualified_name, qualified_inner, qualified_outer);
   if (tag_check_for_typedef(qualified_inner, tag_files, false, qualified_outer, visited, depth+1)) {
      //say(qualified_name" is a typedef");
      VS_TAG_RETURN_TYPE typedef_rt = rt;
      status = _pas_get_return_type_of(errorArgs, tag_files, 
                                       qualified_inner, qualified_outer,
                                       0, SE_TAG_FILTER_TYPEDEF, false,
                                       typedef_rt, visited, depth+1);
      if (status) {
         return status;
      }
      qualified_name   = typedef_rt.return_type;
      rt.pointer_count = typedef_rt.pointer_count;
      rt.return_flags  = typedef_rt.return_flags;
      //say("qualify = "qualified_name" found_type="found_type" pointers="pointer_count);
   }

   if (qualified_name == "" &&
       (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
      qualified_name = found_type;
   }
   if (qualified_name == "") {
      if (_pas_is_builtin_type(found_type)) {
         errorArgs[1] = symbol;
         errorArgs[2] = orig_return_type;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         rt.return_type = found_type;
         return VSCODEHELPRC_BUILTIN_TYPE;
      }
   }

   rt.return_type = qualified_name;
   if (_chdebug) {
      isay(depth,"_pas_parse_return_type returns "rt.return_type" pointer_count="rt.pointer_count);
   }
   if (rt.return_type == "") {
      errorArgs[1] = found_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   visited:[input_args]=rt;
   return 0;
}
static int _pas_get_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                   _str symbol, _str search_class_name,
                                   int min_args, SETagFilterFlags filter_flags,
                                   bool maybe_class_name,
                                   VS_TAG_RETURN_TYPE &rt,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_pas_get_return_type_of("symbol","search_class_name")");
   }

   // filter out mutual recursion
   _str input_args="get;"symbol";"search_class_name";"min_args";"filter_flags";"maybe_class_name";"p_buf_name";"tag_return_type_string(rt);
   int status = _CodeHelpCheckVisited(input_args, "_pas_get_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // initialize pas_return_flags
   rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                         VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                         VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                         VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                         VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY|
                         VSCODEHELP_RETURN_TYPE_ARRAY|
                         VSCODEHELP_RETURN_TYPE_HASHTABLE
                        );

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get the current class from the context
   context_id := tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                         auto cur_tag_type,auto cur_type_id,
                                         auto cur_class_name,auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);

   // special case keyword 'self'
   if (strieq(symbol,"self")) {
      if (search_class_name :== "" && context_id > 0 &&
          !(cur_tag_flags & SE_TAG_FLAG_STATIC)) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         rt.return_type = cur_class_name;
         rt.pointer_count = 0;
         //say("_pas_get_return_type_of: self match_type="match_type);
         visited:[input_args]=rt;
         return 0;
      } else if (search_class_name != "") {
         rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                              VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                              VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                              VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                              VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY|
                              VSCODEHELP_RETURN_TYPE_ARRAY|
                              VSCODEHELP_RETURN_TYPE_HASHTABLE
                             );
         rt.return_type = search_class_name;
         rt.pointer_count = 0;
         visited:[input_args]=rt;
         return 0;
      }
   }

   // special case keyword 'this'
   //say("_pas_get_return_type_of: symbol="symbol);
   cur_return_type := "";
   if (search_class_name=="" && strieq(symbol,"result") && cur_tag_type:=="func") {
      tag_get_detail2(VS_TAGDETAIL_context_return, context_id, cur_return_type);
      if (_chdebug) {
         isay(depth, "_pas_get_return_type_of: cur_return_type="cur_return_type);
      }

      status = _pas_parse_return_type(errorArgs, tag_files,
                                      "result", cur_class_name,
                                      p_buf_name, cur_return_type,
                                      rt, visited, depth+1);
      if (status==0) visited:[input_args]=rt;
      return status;
   }

   int num_matches = _pas_match_return_type_of(errorArgs,tag_files,
                                               symbol,search_class_name,
                                               filter_flags,
                                               rt.return_flags,
                                               visited, depth+1);
   // check for error condition
   if (num_matches < 0) {
      return num_matches;
   }

   // resolve the type of the matches
   rt.taginfo = "";
   int orig_return_flags = rt.return_flags;
   status = _pas_get_type_of_matches(errorArgs, tag_files, symbol,
                                     search_class_name, cur_class_name,
                                     min_args, maybe_class_name,
                                     rt, visited, depth+1);
   if (status==0) {
      if (orig_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
      }
      visited:[input_args]=rt;
   }
   return status;
}
static int _pas_match_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                   _str symbol, _str search_class_name,
                                   SETagFilterFlags filter_flags,int pas_return_flags,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_pas_match_return_type_of("symbol","search_class_name")");
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // Attempt to qualify symbols to their appropriate package for Java
   junk := "";
   if (search_class_name=="") {
      tag_qualify_symbol_name(search_class_name,symbol,search_class_name,p_buf_name,tag_files,false, visited, depth+1);
      tag_split_class_name(search_class_name, junk, search_class_name);
   }
   if (_chdebug) {
      isay(depth, "_pas_match_return_type_of: before previous_id="symbol" match_class="search_class_name);
   }

   // try to find match for 'symbol' within context, watch for
   // C++ global designator (leading ::)
   i := num_matches := 0;
   tag_clear_matches();
   if (pas_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      if (_chdebug) {
         isay(depth, "_pas_match_return_type_of: matching globals");
      }
      tag_list_context_globals(0, 0, symbol, true, tag_files, SE_TAG_FILTER_ANYTHING,
                               SE_TAG_CONTEXT_ONLY_NON_STATIC,
                               num_matches, def_tag_max_function_help_protos, 
                               true, false, visited, depth+1);
   } else {
      if (_chdebug) {
         isay(depth, "_pas_match_return_type_of: matching class symbols, search_class="search_class_name" symbol="symbol" filter_flags="filter_flags);
      }
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, tag_files, "",
                                  num_matches, def_tag_max_function_help_protos,
                                  filter_flags, SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_ONLY_CONTEXT,
                                  true, false, visited, depth+1);
      if (search_class_name!="" && num_matches==0) {
         tag_list_symbols_in_context(symbol, search_class_name, 0, 0, tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     filter_flags, SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_ONLY_CONTEXT|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PACKAGE,
                                     true, false, visited, depth+1);
      }

      if (search_class_name=="" && num_matches==0) {
         tag_list_symbols_in_context(symbol, "System", 0, 0, tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     filter_flags, SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_NO_GLOBALS,
                                     true, false, visited, depth+1);
      }
      // check for package names
      if (num_matches == 0 && (filter_flags && SE_TAG_FILTER_PACKAGE) &&
          search_class_name != "" && tag_check_for_package(search_class_name"."symbol,tag_files,true,p_LangCaseSensitive, null, visited, depth+1)) {
         tag_list_symbols_in_context(search_class_name"."symbol, "", 0, 0, tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     filter_flags, SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_NO_GLOBALS,
                                     true, false, visited, depth+1);
      }
   }

   // return the number of matches
   //say("num_matches="num_matches);
   return num_matches;
}
static int _pas_get_type_of_matches(_str (&errorArgs)[], typeless tag_files,
                                    _str symbol, _str search_class_name,
                                    _str cur_class_name, int min_args,
                                    bool maybe_class_name,
                                    VS_TAG_RETURN_TYPE &rt,
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_matches("symbol","search_class_name")");
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   // filter out matches based on number of arguments
   _str matchlist[];
   tag_init_tag_browse_info(auto proc_cm);

   num_matches := tag_get_num_of_matches();
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_matches: num_matches="num_matches);
   }
   for (i:=1; i<=num_matches; i++) {
      tag_get_match_browse_info(i, proc_cm);
      if (_chdebug) {
         tag_browse_info_dump(proc_cm, "_pas_get_type_of_matches: XXX", depth);
      }
      // check that number of argument matches.
      if (min_args > 0 && tag_tree_type_is_func(proc_cm.type_name)) {
         num_args := 0;
         def_args := 0;
         arg_pos := 0;
         ff := 1;
         for (;;) {
            _str parm = cb_next_arg(proc_cm.arguments, arg_pos, ff);
            if (parm == "") {
               break;
            }
            if (pos("=", parm)) {
               def_args++;
            }
            num_args++;
            ff=0;
         }
         // this prototype doesn't take enough arguments?
         if (num_args < min_args) {
            continue;
         }
         // this prototype requires too many arguments?
         if (num_args - def_args > min_args) {
            continue;
         }
      }
      if ((proc_cm.flags & SE_TAG_FLAG_OPERATOR) && proc_cm.class_name :!= search_class_name) {
         continue;
      }
      if (_chdebug) {
         tag_browse_info_dump(proc_cm, "_pas_get_type_of_matches: WHERE", depth);
      }
      if (rt.taginfo == "") {
         rt.taginfo = tag_compose_tag_browse_info(proc_cm);
         //say("MATCH TAG="match_tag);
      }
      if (tag_tree_type_is_package(proc_cm.type_name) || tag_tree_type_is_class(proc_cm.type_name) || proc_cm.type_name=="enum") {
         if (proc_cm.return_type != null && proc_cm.return_type != "") {
            VS_TAG_RETURN_TYPE package_rt;
            tag_return_type_init(package_rt);
            status := _pas_parse_return_type(errorArgs, tag_files, proc_cm.member_name, proc_cm.class_name, proc_cm.file_name, proc_cm.return_type, package_rt, visited, depth+1);
            if (!status) {
               proc_cm.return_type = package_rt.return_type;
            }
         } else if (proc_cm.class_name != "") {
            proc_cm.return_type = tag_join_class_name(proc_cm.member_name, proc_cm.class_name, tag_files, true, false, false, visited, depth+1); 
         } else {
            proc_cm.return_type = proc_cm.member_name;
         }
      }
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_matches: return_type="proc_cm.return_type);
      }
      if (proc_cm.return_type != "") {
         matchlist[matchlist._length()] = proc_cm.member_name "\t" proc_cm.class_name "\t" proc_cm.type_name "\t" proc_cm.file_name "\t" proc_cm.return_type;
      }
   }

   // for each match in list, (have to do it this way because
   // _pas_parse_return_type()) uses the context match set.
   typeless status=0;
   rt.return_type = "";
   match_pointer_count := 0;
   for (i=0; i<matchlist._length(); i++) {

      parse matchlist[i] with proc_cm.member_name "\t" proc_cm.class_name "\t" proc_cm.type_name "\t" proc_cm.file_name "\t" proc_cm.return_type;
      if (_chdebug) {
         tag_browse_info_dump(proc_cm, "_pas_get_type_of_matches: HERE", depth);
      }

      VS_TAG_RETURN_TYPE found_rt;
      tag_return_type_init(found_rt);
      if (tag_tree_type_is_package(proc_cm.type_name)) {
         status = 0;
         errorArgs._makeempty();
         found_rt.return_type = proc_cm.return_type;
         rt.taginfo = tag_compose_tag_browse_info(proc_cm);
      } else {
         status = _pas_parse_return_type(errorArgs, tag_files, 
                                         proc_cm.member_name, 
                                         (proc_cm.class_name != "")? proc_cm.class_name : cur_class_name,
                                         proc_cm.file_name, proc_cm.return_type,
                                         found_rt, visited, depth+1);
      }
      if (status) {
         if (i < matchlist._length()) {
            continue;
         }
         return status;
      }
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_matches: **found_type="found_rt.return_type" match_type="rt.return_type" pointers="found_rt.pointer_count" flags="found_rt.return_flags);
      }
      if (found_rt.return_type != "") {

         if (rt.return_type == "") {
            rt.return_type = found_rt.return_type;
            //_message_box("new match type="match_type);
            rt.return_flags = found_rt.return_flags;
            rt.pointer_count += found_rt.pointer_count;
            rt.taginfo = found_rt.taginfo;
            if (_chdebug) {
               isay(depth, "_pas_get_type_of_matches: RETURN, pointer_count="rt.pointer_count" found_pointer_count="found_rt.pointer_count" found_type="found_rt.return_type);
            }
            match_pointer_count = found_rt.pointer_count;
         } else {
            // different opinions on static_only or const_only, chose more general
            if (!(rt.return_flags & found_rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
            if (!(rt.return_flags & found_rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (!(rt.return_flags & found_rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
            }
            rt.return_flags |= (found_rt.return_flags | VSCODEHELP_RETURN_TYPE_ARRAY);
            if (rt.return_type :!= found_rt.return_type || match_pointer_count != found_rt.pointer_count) {
               // different return type, this is not good.
               if (_chdebug) {
                  isay(depth, "_pas_get_type_of_matches: MATCH_TYPE="rt.return_type" FOUND_TYPE="found_rt.return_type);
               }
               errorArgs[1] = symbol;
               return VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
            }
         }
      }
   }

   //_message_box("OUT OF LOOP");
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_matches: maybe class name, num_matches="num_matches);
   }
   // Java syntax like Class.blah... or C++ style iostream::blah
   typeless junk="";
   if (maybe_class_name && num_matches==0) {
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_matches: 111 searching for class name, symbol="symbol" class="search_class_name);
      }
      SETagFilterFlags filter_flags  = SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_UNION;
      SETagContextFlags context_flags = (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
      context_flags |= SE_TAG_CONTEXT_ALLOW_ANONYMOUS;
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, tag_files, "",
                                  num_matches, def_tag_max_function_help_protos,
                                  filter_flags, context_flags,
                                  true, false, visited, depth+1);

      //say("found "num_matches" matches");
      if (num_matches > 0) {
         tag_get_match_browse_info(1, auto xInfo);
         //say("X tag="x_tag_name" class="x_class_name" type="x_type_name);
         rt.return_type = symbol;
         if (search_class_name == "" || search_class_name == cur_class_name) {
            _str outer_class_name = cur_class_name;
            local_matches := 0;
            while (outer_class_name != "") {
               tag_list_symbols_in_context(rt.return_type, cur_class_name, 0, 0, tag_files, "",
                                           local_matches, def_tag_max_function_help_protos,
                                           filter_flags, context_flags, 
                                           true, false, visited, depth+1);

               //say("222 match_type="match_type" cur_class_name="cur_class_name" num_matches="local_matches);
               if (local_matches > 0) {
                  tag_get_match_browse_info(1, auto relInfo);
                  rt.return_type = tag_join_class_name(rt.return_type, relInfo.class_name, tag_files, false, true, false, visited, depth+1);
                  //say("type_name="rel_type_name" MATCH_TYPE="match_type);
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                  break;
               }
               tag_split_class_name(outer_class_name, junk, outer_class_name);
            }
         } else if (search_class_name != "") {
            rt.return_type = tag_join_class_name(rt.return_type, search_class_name, tag_files, false, true, false, visited, depth+1);
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         }
      }
   }

   // no matches?
   if (num_matches == 0) {
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_matches: no symbols found");
      }
      errorArgs[1] = symbol;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // current method is from same class, then we have private access
   if (rt.return_type :== cur_class_name) {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
   }
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_matches() returns "rt.return_type" pointers="rt.pointer_count);
   }
   return 0;
}
// pull prefix off of prefixexp until matching bracket, paren, or lt/gt
// returns true if match was found, false otherwise
static _str _pas_get_expr_token(_str &prefixexp)
{
   // get next token from expression, \x27 is single quote character (for Ada)
   int p = pos('^ @{[*/+-=<>#().^@]|\x27|[<>][>=]|:v|\[|\]}', prefixexp, 1, 'r');
   if (!p) {
      return "";
   }
   p = pos('S0');
   n := pos('0');
   ch := substr(prefixexp, p, n);
   prefixexp = substr(prefixexp, p+n);
   return ch;
}
static int _pas_get_type_of_part(_str (&errorArgs)[], typeless tag_files,
                                 _str &previous_id, _str ch,
                                 _str &prefixexp, _str &full_prefixexp,
                                 struct VS_TAG_RETURN_TYPE &rt, 
                                 VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_part("previous_id","ch","prefixexp","full_prefixexp","rt.return_type")");
   }
   _str current_id = previous_id;

   // number of arguments in paren or brackets group
   num_args := 0;
   status := 0;
   var_filters := 0;
   typeless junk="";
   cast_type := "";
   parents := "";
   tag_dbs := "";
   orig_db := "";
   p1 := t1 := "";
   outer_class := "";

   // process token
   switch (lowcase(ch)) {
   case ".":     // member access operator
      if (previous_id != "") {
         status = _pas_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT|SE_TAG_FILTER_TYPEDEF|SE_TAG_FILTER_ENUM, true,
                                          rt, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_pas_get_type_of_part: match_class="rt.return_type" pointer_count="rt.pointer_count" status="status);
         }
         if (status) {
            return status;
         }
         previous_id = "";
      }
      //say("pointer_count="pointer_count);
      if (rt.pointer_count < 0) {
         errorArgs[1] = full_prefixexp;
         return (VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      } else if (rt.pointer_count > 0) {
         errorArgs[1] = ".";
         errorArgs[2] = current_id;
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) {
            return (VSCODEHELPRC_DOT_FOR_ARRAY);
         } else {
            return (VSCODEHELPRC_DOT_FOR_POINTER);
         }
      }
      if (rt.pointer_count != 0) {
      }
      break;

   case "^":
      if (previous_id != "") {
         status = _pas_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT, true,
                                          rt, visited, depth+1);
         //say("match_class="match_class" pointer_count="pointer_count" status="status);
         if (status) {
            return status;
         }
         previous_id = "";
      }
      //reference_count--;
      rt.pointer_count--;
      if (rt.pointer_count < 0) {
         errorArgs[1] = "^";
         errorArgs[2] = substr(full_prefixexp,1,length(full_prefixexp)-length(prefixexp)-1);
         return (VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER);
      }
      break;
   case "'":
      ch = _pas_get_expr_token(prefixexp);
      if (_LanguageInheritsFrom("ada")) {
         switch (lowcase(ch)) {
         case "access":
         case "base":
         case "unchecked_access":
            // returns access type
            return(0);
         case "class":
            // returns class-wide type (not static)
            return(0);
         case "address":
            // returns address type
            rt.pointer_count++;
            return(0);
         case "adjacent":
         case "ceiling":
         case "compose":
         case "copy_sign":
         case "exponent":
         case "floor":
         case "fraction":
         case "input":
         case "leading_part":
         case "machine":
         case "max":
         case "min":
         case "model":
         case "pred":
         case "remainder":
         case "round":
         case "rounding":
         case "scaling":
         case "succ":
         case "truncation":
         case "unbiased_rounding":
            // takes arguments and returns same type
            if (substr(prefixexp,1,1)=="(") {
               ch = _pas_get_expr_token(prefixexp);
               if (ch=="(" && !match_parens(prefixexp, cast_type, num_args)) {
                  // this is not good
                  errorArgs[1] = full_prefixexp;
                  return VSCODEHELPRC_PARENTHESIS_MISMATCH;
               }
            }
            return(0);
         case "identity":
         case "output":
         case "read":
         case "write":
         case "range":
         case "val":
         case "value":
         case "wide_value":
            // procedure type or other unknown type
            rt.return_type = "";
            return(VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
         case "caller":
            // task identifier
            rt.return_type = "Task_Identification/Task_ID";
            return(0);
         case "storage_pool":
            // storage pool (base type)
            rt.return_type = "System.Storage_Pools/Root_Storage_Pool";
            return(0);
         case "tag":
            // class tag
            rt.return_type = "Ada.Tags/Tag";
            return(0);
         default:
            // everything else returns a builtin type
            errorArgs[1] = ch;
            errorArgs[2] = "";
            rt.return_type = "";
            return(VSCODEHELPRC_BUILTIN_TYPE);
         }
      } else if (_LanguageInheritsFrom("vhd")) {
         switch (lowcase(ch)) {
         // integers
         case "left":
         case "right":
         case "low":
         case "high":
         case "pos":
         case "length":
            rt.return_type="";
            return(0);
         // generic values
         case "val":
         case "leftof":
         case "rightof":
         case "pred":
         case "succ":
            rt.return_type="";
            return(0);
         case "range":
         case "reverse_range":
            rt.return_type="";
            return(0);
         default:
            // everything else returns a builtin type
            errorArgs[1] = ch;
            errorArgs[2] = "";
            rt.return_type = "";
            return(VSCODEHELPRC_BUILTIN_TYPE);
         }
      }
      break;
   case "@":
      //reference_count++;
      rt.pointer_count++;
      break;

   case "[":     // array subscript introduction
      if (!match_brackets(prefixexp, num_args)) {
         // this is not good
         //say("return from [");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (previous_id != "") {
         current_id = previous_id;
         status = _pas_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT, false,
                                          rt, visited, depth+1);
         if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
            // array operator, but not an array
         }
         if (status) {
            return status;
         }
         previous_id = "";
         rt.pointer_count--;
      }
      break;
   case "]":     // array subscript close
      // what do I do here?
      break;

   case "(":     // function call, cast, or expression grouping
      if (!match_parens(prefixexp, cast_type, num_args)) {
         // this is not good
         //say("return from (");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_PARENTHESIS_MISMATCH;
      }
      if (previous_id != "") {
         // might be a cast to a built-in type
         if (_pas_is_builtin_type(previous_id)) {
            rt.return_type = previous_id;
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
            errorArgs[1]=cast_type;
            errorArgs[2]=previous_id;
            return VSCODEHELPRC_BUILTIN_TYPE;
         }
         if (_chdebug) {
            isay(depth, "_pas_get_type_of_part: GOT HERE 3, previous_id="previous_id" match_class="rt.return_type" num_args="num_args);
         }
         // this was a function call or new style function pointer
         VS_TAG_RETURN_TYPE match_rt = rt;
         match_rt.return_type = "";
         status = _pas_get_return_type_of(errorArgs,tag_files,previous_id,
                                          rt.return_type, num_args,
                                          SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT, false,
                                          match_rt, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_pas_get_type_of_part: status="status" pointer_count="rt.pointer_count" match_tag="rt.taginfo);
            isay(depth, "_pas_get_type_of_part: match_class="match_rt.return_type);
         }
         if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND) {
            return status;
         }
         // did we find a variable of a function or function pointer?
         is_function := false;
         if (match_rt.taginfo != "") {
            if (_chdebug) {
               isay(depth, "_pas_get_type_of_part: match_rt.taginfo="match_rt.taginfo);
            }
            tag_get_info_from_return_type(match_rt, auto match_cm);
            if (tag_tree_type_is_func(match_cm.type_name)) {
               is_function=true;
            } else if (match_rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) {
               // Ada uses parens for array subscripts
               --match_rt.pointer_count;
               match_rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
            } else if (pos("(",match_cm.return_type)) {
               is_function=true;
            }
         }
         //say("3 new_match_class="new_match_class);
         // could not find match class, maybe this is a function-style cast?
         if (match_rt.return_type == "") {
            num_matches := 0;
            tag_list_symbols_in_context(previous_id, rt.return_type, 0, 0, tag_files, "",
                                        num_matches, def_tag_max_find_context_tags,
                                        SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_TYPEDEF,
                                        SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL,
                                        true, false, visited, depth+1, rt.template_args);

            if (num_matches > 0) {
               if (_chdebug) {
                  isay(depth, "_pas_get_type_of_part: "previous_id" is a struct or typedef");
               }
               status = _pas_parse_return_type(errorArgs, tag_files, "", "", p_buf_name,
                                               previous_id,
                                               rt, visited, depth+1);
               //status = _pas_parse_return_type(errorArgs, tag_files,
               //                                previous_id, match_class, p_buf_name,
               //                                previous_id,
               //                                match_class, pointer_count,
               //                                pas_return_flags, dummy_tag);
            } else if (rt.return_type != "") {
               rt.pointer_count = 0;
            }
            //say("4 match_class="match_class" status="status" pointer_count="pointer_count);
            //if (match_class != "") {
            //   pointer_count = 0;
            //}
         } else {
            //say("GOT HERE 5");
            rt = match_rt;

         }

         // this may have been an array index expression
         if (!is_function && rt.pointer_count > 0 && (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
            rt.pointer_count -= num_args;
            if (rt.pointer_count < 0) rt.pointer_count = 0;
            if (rt.pointer_count == 0) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
            }
         }

         //say("GOT HERE 10");
         previous_id = "";
      } else {
         //say("cast_type="cast_type" prefixexp="prefixexp);
         // must be an expression, go recursive
         //say("think it's an expression, cast_type="cast_type);
         status = _pas_get_type_of_prefix(errorArgs, cast_type, rt, visited, depth+1);
         if (status) {
            return status;
         }
         if (_chdebug) {
            isay(depth, "_pas_get_type_of_part: EXPR: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
         }
      }
      break;

   case ")":
      // what do I do here?
      errorArgs[1] = full_prefixexp;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;

   case "inherited":
      status = _pas_get_return_type_of(errorArgs, tag_files, "self", "", 0,
                                       SE_TAG_FILTER_ANY_DATA, false,
                                       rt, visited, depth+1);
      if (status) {
         return status;
      }
      parent_types := "";
      parents = cb_get_normalized_inheritance(rt.return_type, 
                                              tag_dbs, tag_files, 
                                              true, "", "",
                                              parent_types, false,
                                              visited, depth+1);
      //say("_pas_get_type_of_part: inherited match_class="parents);
      parse parents with rt.return_type ";" parents;
      // add each of them to the list also
      orig_db = tag_current_db();
      while (parents != "") {
         parse parents with p1 ";" parents;
         parse tag_dbs with t1 ";" tag_dbs;
         status = tag_read_db(t1);
         if (status < 0) {
            continue;
         }
         // add transitively inherited class members
         parse p1 with p1 "<" .;
         tag_split_class_name(p1, rt.return_type, outer_class);
         status = tag_find_tag(rt.return_type, "class", outer_class);
         tag_reset_find_tag();
         if (!status) {
            rt.return_type = p1;
            break;
         }
         status = tag_find_tag(rt.return_type, "interface", outer_class);
         tag_reset_find_tag();
         if (!status) {
            rt.return_type = p1;
            break;
         }
      }
      previous_id = "";
      break;

   case "self":
   case "result":
      status = _pas_get_return_type_of(errorArgs, tag_files, ch, "", 0,
                                       SE_TAG_FILTER_ANY_DATA, false, 
                                       rt, visited, depth+1);
      if (status) {
         return status;
      }
      previous_id = "";
      rt.pointer_count = 0;
      break;

   // binary operators returning the type of their LHS
   case "*":
   case "/":
   case "+":
   case "-":
   case "div":
   case "mod":
   case "shl":
   case "shr":
   case "as":
      if (depth <= 0) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (previous_id != "") {
         rt.taginfo = "";
         status = _pas_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT, true,
                                          rt, visited, depth+1);
         if (status) {
            return status;
         }
         previous_id = "";
      }
      break;

   // operators producing a boolean result
   case "=":
   case "<":
   case ">":
   case "<=":
   case ">=":
   case "<>":
   case "#":
   case "not":
   case "and":
   case "or":
   case "xor":
   case "in":
   case "is":
      rt.return_type = "boolean";
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
      errorArgs[1]=ch;
      errorArgs[2]="boolean";
      return (VSCODEHELPRC_BUILTIN_TYPE);

   // In VHDL, 'work' is the default user library namespace
   case "work":
      if (lowcase(ch)=="work" && _LanguageInheritsFrom("vhd") && rt.return_type=="") {
         break;
      }
      // fall through

   default:
      // this must be an identifier (or drop-through case)
      rt.taginfo = "";
      previous_id = ch;
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_part: previous_id="previous_id);
      }
      var_filters = SE_TAG_FILTER_MEMBER_VARIABLE|SE_TAG_FILTER_PROPERTY;
      if (rt.return_type == "") {
         var_filters |= SE_TAG_FILTER_LOCAL_VARIABLE|SE_TAG_FILTER_GLOBAL_VARIABLE;
      }
      break;
   }

   // successful so far, cool.
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_part: success");
   }
   return 0;
}

int _pas_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                            struct VS_TAG_RETURN_TYPE &rt, 
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_pas_get_type_of_prefix("prefixexp")");
   }

   // initiialize return values
   rt.return_type   = "";
   rt.pointer_count = 0;
   rt.return_flags  = 0;

   // loop variables
   typeless tag_files       = tags_filenamea(p_LangId);
   _str     full_prefixexp  = prefixexp;
   previous_id := "";
   //int      reference_count = 0;
   status := 0;

   // process the prefix expression, token by token, delegate
   // most of processing to recursive func _pas_get_type_of_part
   while (prefixexp != "") {

      // get next token from expression
      _str ch = _pas_get_expr_token(prefixexp);
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_prefix: get prefixexp = "prefixexp" ch="ch);
      }
      if (ch == "") {
         // don't recognize something we saw
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }

      // process this part of the prefix expression
      status = _pas_get_type_of_part(errorArgs, tag_files,
                                     previous_id, ch, prefixexp, full_prefixexp,
                                     rt, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_prefix: match_class="rt.return_type);
      }
      if (status) {
         return status;
      }
   }

   if (previous_id != "") {
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_prefix: before previous_id="previous_id" match_class="rt.return_type);
      }
      var_filters := SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_CONSTANT;

      status = _pas_get_return_type_of(errorArgs, tag_files, previous_id,
                                       rt.return_type, 0, var_filters, true,
                                       rt, visited, depth+1);
      if (status) {
         return status;
      }
      previous_id = "";
      if (_chdebug) {
         isay(depth, "_pas_get_type_of_prefix: after previous_id="previous_id" match_class="rt.return_type" match_tag="rt.taginfo);
      }
   }
   //pointer_count += reference_count;

   if (_chdebug) {
      isay(depth, "_pas_get_type_of_prefix: returns "rt.return_type);
   }
   return 0;
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
int _pas_get_expression_info(bool PossibleOperator,VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_idexp_info_init(idexp_info);
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int cfg;
   if (PossibleOperator) {
      left();cfg=_clex_find(0,'g');right();
   } else {
      cfg=_clex_find(0,'g');
   }
   if (_in_comment() || cfg==CFG_STRING) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   idexp_info.errorArgs._makeempty();
   idexp_info.otherinfo="";
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   word_chars := _clex_identifier_chars();
   save_pos(auto orig_pos);
   if (PossibleOperator) {
      left();
      ch := get_text();
      switch (ch) {
      //case '^':
      //case '@':
      //   left();
      //   break;
      case "'":
         if (_LanguageInheritsFrom("ada") || _LanguageInheritsFrom("vhd")) {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s');
            idexp_info.prefixexp="";
            int status=ada_before_squote(idexp_info.prefixexp,idexp_info.lastid,idexp_info.info_flags);
            restore_pos(orig_pos);
            return(status);
         }
         restore_pos(orig_pos);
         return(1);
      case ".":
         orig_col := p_col;
         if (ch==".") {
            // Screen out floating point.  1.0
            if (isdigit(get_text(1,(int)point('s')-1))) {
               // Check if identifier before . is a number
               save_pos(auto p2);
               left();
               search('[~'word_chars']\c|^\c','-rh@');
               if (isdigit(get_text())) {
                  restore_pos(orig_pos);
                  return(1);
               }
               restore_pos(p2);

            }
            right();
         }
         // get the id after the dot
         // IF we are on a id character
         if (pos('['word_chars']',get_text(),1,'r')) {
            start_col := p_col;
            _str start_offset=point('s');
            //search('[~'p_word_chars']|$','r@');
            _TruncSearchLine('[~'word_chars']|$','r');
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=(int)start_offset;
         } else {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
         }
         p_col=orig_col;
         break;
      case "(":
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         _clex_skip_blanks('-');
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            restore_pos(orig_pos);
            //say("ID returns 5");
            return(1);
         }
         int end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         if (pos(" "idexp_info.lastid" ",PASCAL_NOT_FUNCTION_WORDS)) {
            restore_pos(orig_pos);
            return(1);
         }
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      default:
         restore_pos(orig_pos);
         return(1);
      }
   } else {
      //say("_pas_get_expression_info: not an id char");
      // IF we are not on an id character.
      ch := get_text();
      done := 0;
      if (pos('[~'word_chars']',ch,1,'r')) {
         //say("_pas_get_expression_info: 1");
         left();
         ch=get_text();
         if (ch==".") {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            done=1;
         }
      }
      if (!done) {
         //say("_pas_get_expression_info: 2");
         // IF we are not on an id character.
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            //say("_pas_get_expression_info: 3");
            restore_pos(orig_pos);
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');

            gtk=pas_prev_sym();
            if (gtk==TK_ID) {
               idexp_info.prefixexp=lowcase(gtkinfo)" ";
               switch (lowcase(gtkinfo)) {
               case "inherited":
                  break;
               case "goto":
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_GOTO_STATEMENT;
                  break;
               case "raise":
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_THROW_STATEMENT;
                  break;
               default:
                  idexp_info.prefixexp="";
                  break;
               }
            }
            restore_pos(orig_pos);
            return(0);
         }
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col := p_col;
         // Check if this is a function call
         //search('[~ \t]|$','r@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=="(") {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         p_col=end_col;

         //say("_pas_get_expression_info: 4");
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
      }
   }
   //say("_pas_get_expression_info: got here");
   idexp_info.prefixexp="";
   gtk=pas_prev_sym();
   int status=pas_before_id(idexp_info.prefixexp,idexp_info.lastid,idexp_info.info_flags);
   restore_pos(orig_pos);
   return(status);
}

static _str pas_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   status := 0;
   ch := get_text();
   if (ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(pas_next_sym());
   }
   start_col := 0;
   start_line := 0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=="." && get_text()==".") {
      right();
      gtk=gtkinfo="..";
      return(gtk);
   }
   if (ch=="<" && get_text()==">") {
      right();
      gtk=gtkinfo="<>";
      return(gtk);
   }
   if (ch=="=" && get_text()==">") {
      right();
      gtk=gtkinfo="=>";
      return(gtk);
   }
   if (ch==":" && get_text()=="=") {
      right();
      gtk=gtkinfo=":=";
      return(gtk);
   }
   if (ch=="<" && get_text()=="=") {
      right();
      gtk=gtkinfo="<=";
      return(gtk);
   }
   if (ch==">" && get_text()=="=") {
      right();
      gtk=gtkinfo=">=";
      return(gtk);
   }
   if (ch=="=" && get_text()=="=") {
      right();
      gtk=gtkinfo="==";
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str pas_prev_sym()
{
   status := 0;
   ch := get_text();
   if (ch=="\n" || ch=="\r" || ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(pas_prev_sym());
   }
   end_col := 0;
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      end_col=p_col+1;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col==1) break;
            left();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               right();
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      } else {
         search('[~'word_chars']\c|^\c','@rh-');
         gtk=TK_ID;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if (p_col==1) {
      up();_end_line();
      if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   if (ch=="." && get_text()==".") {
      right();
      gtk=gtkinfo="..";
      return(gtk);
   }
   if (ch==">") {
      switch (get_text()) {
      case '=':
      case '<':
         gtk=gtkinfo=get_text():+"=";
         left();
         return(gtk);
      }
   }
   if (ch=='=') {
      switch (get_text()) {
      case ':':
      case '=':
      case '<':
      case '>':
         gtk=gtkinfo=get_text():+"=";
         left();
         return(gtk);
      }
   }
   gtk=gtkinfo=ch;
   return(gtk);
}

int _pas_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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
      isay(depth, "_pas_find_context_tags("prefixexp","lastid")");
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

   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_line_no);
      tag_get_detail2(VS_TAGDETAIL_context_return, context_id, cur_return_type);
   }

   // get the list of tag files for this search
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // check what language we are really working with
   isADA  := _LanguageInheritsFrom("ada");
   isVHDL := _LanguageInheritsFrom("vhd");
   isPascal := _LanguageInheritsFrom("pas");

   // narrow down results to only functions if the symbol is followed by a paren
   if (isPascal && !isADA && !isVHDL && (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // Ada attribute operator, list all attributes
   if ((isADA || isVHDL) && _last_char(prefixexp):=="'") {
      // list ada attributes from builtins.ada or vhdl.tagdoc
      tag_list_in_class(lastid,"Predefined_Attributes",
                        0, 0, tag_files,
                        num_matches,def_tag_max_find_context_tags,
                        filter_flags, context_flags,
                        exact_match,case_sensitive,
                        null,null,visited,depth+1);
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // no prefix expression, update globals and members from current context
   if (prefixexp == "") {

      // insert locals and 'this' if there is class context
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         in_function_context := false;
         if (tag_tree_type_is_func(cur_type_name)) {
            in_function_context=true;
            this_class_name := _MatchThisOrSelf(visited, depth+1);
            if (this_class_name != "" && !isVHDL) {
               this_class_name = stranslate(this_class_name, ".", "/");
               this_class_name = stranslate(this_class_name, ".", ":");
               if (lastid=="" || pos(lastid, import_name,1,case_sensitive? "":"i")==1) {
                  tag_tree_insert_tag(0, 0, 0, 1, 0, 
                                      "self", "var", 
                                      p_buf_name, cur_line_no, 
                                      "", 0, this_class_name);
                  num_matches++;
               }
            }
            if (cur_type_name :== "func" && isPascal) {
               if (lastid=="" || pos(lastid, import_name,1,case_sensitive? "":"i")==1) {
                  tag_tree_insert_tag(0, 0, 0, 1, 0, 
                                      "result", "var", 
                                      p_buf_name, cur_line_no, 
                                      "", 0, cur_return_type);
                  num_matches++;
               }
            }
         }
         // now add in other local variables
         tag_list_class_locals( 0, 0, tag_files, 
                                lastid, "", 
                                filter_flags, context_flags,
                                num_matches, max_matches, 
                                exact_match, case_sensitive, 
                                null, visited, depth+1);
      }

      // update the members in the current context
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
         tag_list_symbols_in_context( lastid, cur_context,
                                      0, 0, tag_files, p_buf_name, 
                                      num_matches, max_matches, 
                                      filter_flags, context_flags, 
                                      exact_match, case_sensitive, 
                                      visited, depth+1);
      }

      // update the list of globals in the current buffer
      if ((context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
          !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, null,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
      }

      // update the imports in the current context
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
          !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {

         n := tag_get_num_of_context();
         for (i:=1; i<=n; i++) {
            if (_CheckTimeout()) break;
            if (num_matches > max_matches) break;
            tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
            if (type_name:=="import") {
               tag_get_detail2(VS_TAGDETAIL_context_name,i,import_name);
               tag_get_detail2(VS_TAGDETAIL_context_return,i,aliased_to);
               if (aliased_to!="" && tag_check_for_package(aliased_to,tag_files,true,false, null, visited, depth+1)) {
                  import_name = aliased_to;
               }
               int package_index = tag_check_for_package(import_name, tag_files, true, false, null, visited, depth+1);
               // translate case-sensitivity
               if (package_index==1) {
                  tag_get_detail(VS_TAGDETAIL_return, aliased_to);
               } else if (package_index > 1) {
                  tag_get_detail2(VS_TAGDETAIL_context_return, package_index-1, aliased_to);
               } else {
                  aliased_to="";
               }
               if (aliased_to!="" && tag_check_for_package(aliased_to,tag_files,true,false, null, visited, depth+1)) {
                  import_name = aliased_to;
               }
               //say("import="import_name'=');
               tag_list_class_tags(0, 0, tag_files,
                                   lastid, import_name,
                                   filter_flags, context_flags,
                                   num_matches, max_matches,
                                   exact_match, case_sensitive, 
                                   visited, depth+1);
            }
         }

         // update the system builtins in the current context
         if (isADA || isVHDL) {
            // Standard is always imported
            tag_list_in_class(lastid,"Standard",
                              0, 0, tag_files,
                              num_matches, max_matches,
                              filter_flags, 
                              context_flags|SE_TAG_CONTEXT_ACCESS_PUBLIC,
                              exact_match, case_sensitive,
                              null, null, visited, depth+1);
         } else if (isPascal) {
            // System is always imported
            tag_list_in_class(lastid,"System",
                              0, 0, tag_files,
                              num_matches, max_matches,
                              filter_flags, 
                              context_flags|SE_TAG_CONTEXT_ACCESS_PUBLIC,
                              exact_match, case_sensitive,
                              null, null, visited, depth+1);
         }
      }

      // update the list of packages visible
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
          !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {

         if (isPascal) {
            // System is always imported
            if (lastid=="" || pos(lastid, "System", 1,case_sensitive? "":"i")==1) {
               tag_tree_insert_tag(0, 0, 0, 1, 0, "System", "package", "", 0, "", 0, "");
               num_matches++;
            }
         }
         if (isADA || isVHDL) {
            // Standard is always imported
            if (lastid=="" || pos(lastid, "Standard", 1,case_sensitive? "":"i")==1) {
               tag_tree_insert_tag(0, 0, 0, 1, 0, "Standard", "package", "", 0, "", 0, "");
               num_matches++;
            }
         }

         // list other available classes matching prefix

         if (!exact_match && lastid == "") {
            tag_list_globals_of_type(0, 0, tag_files,
                                     SE_TAG_TYPE_PACKAGE, 0, 0,
                                     num_matches, max_matches,
                                     visited, depth+1);
         } else {
            tag_list_context_packages(0, 0, 
                                      lastid, tag_files,
                                      num_matches, max_matches,
                                      exact_match, case_sensitive,
                                      visited, depth+1);
         }

         // list explicitely imported packages and current package
         n := tag_get_num_of_context();
         for (i:=1; i<=n; i++) {
            if (_CheckTimeout()) break;
            if (num_matches > max_matches) break;
            tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
            tag_get_detail2(VS_TAGDETAIL_context_type, i, import_name);
            if (tag_tree_type_is_package(type_name)) {
               if (lastid=="" || pos(lastid, import_name,1,case_sensitive? "":"i")==1) {
                  tag_insert_match_fast(VS_TAGMATCH_context, i);
                  num_matches++;
               }
            } else if (type_name :== "import") {
               if (lastid=="" || pos(lastid, import_name,1,case_sensitive? "":"i")==1) {
                  tag_insert_match_fast(VS_TAGMATCH_context, i);
                  num_matches++;
               }
            }
         }
      }

      // all done
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // maybe prefix expression is a package name or prefix of package name
   word_chars := _clex_identifier_chars();
   if (pos("^[."word_chars"]@$", prefixexp, 1, 'r')) {
      _CodeHelpListPackages(0, 0,
                            p_window_id, tag_files,
                            prefixexp, lastid,
                            num_matches, max_matches,
                            exact_match, case_sensitive,
                            visited, depth+1);
   }

   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   tag_push_matches();
   status = _pas_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1);
   tag_pop_matches();
   if (_chdebug) {
      isay(depth, "_pas_find_context_tags: match_class="rt.return_type" status="status);
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
      }
   }

   // Return 0 indicating success if anything was found
   if (_chdebug) {
      tag_dump_matches("_pas_find_context_tags: FINAL", depth+1);
   }
   errorArgs[1] = (lastid!="")? lastid : prefixexp;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/*
INPUT
   info.class_name
   info.member_name
   info.type_name;
   info.flags;
   info.return_type;
   info.arguments
   info.exceptions
*/
_str _pas_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   tag_flags  := info.flags;
   tag_name   := info.member_name;
   class_name := info.class_name;
   type_name  := info.type_name;
   in_class_def := (flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   verbose      := (flags&VSCODEHELPDCLFLAG_VERBOSE);
   show_class   := (flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   show_access  := (flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   arguments := (info.arguments!="")? "("info.arguments")":"";
   result := "";
   proto := "";
   kw := "";

   //say("_pas_get_decl: type_name="type_name);
   switch (type_name) {
   case "proc":         // procedure or command
   case "proto":        // function prototype
   case "constr":       // class constructor
   case "destr":        // class destructor
   case "func":         // function
   case "procproto":    // Prototype for procedure
   case "subfunc":      // Nested function or cobol paragraph
   case "subproc":      // Nested procedure or cobol paragraph

      before_tag := "";
      if (show_access && in_class_def) {
         c_access_flags := (tag_flags & SE_TAG_FLAG_ACCESS);
         before_tag=access_indent_string;
         switch (c_access_flags) {
         case SE_TAG_FLAG_PUBLIC:
         case SE_TAG_FLAG_PACKAGE:
            strappend(before_tag,_word_case("PUBLIC"):+"\n":+access_indent_string);
            break;
         case SE_TAG_FLAG_PROTECTED:
            strappend(before_tag,_word_case("PROTECTED"):+"\n":+access_indent_string);
            break;
         case SE_TAG_FLAG_PRIVATE:
            strappend(before_tag,_word_case("PRIVATE"):+"\n":+access_indent_string);
            break;
         }
      }

      if (verbose && in_class_def && (tag_flags & SE_TAG_FLAG_STATIC)) {
         strappend(before_tag,_word_case("CLASS"):+" ");
      }
      if (verbose) {
         if (type_name=="constr" || (tag_flags & SE_TAG_FLAG_CONSTRUCTOR)) {
            strappend(before_tag, _word_case("CONSTRUCTOR"):+" ");
         } else if (type_name=="destr" || (tag_flags & SE_TAG_FLAG_DESTRUCTOR)) {
            strappend(before_tag, _word_case("DESTRUCTOR"):+" ");
         } else if (pos("proc",type_name)) {
            strappend(before_tag, _word_case("PROCEDURE"):+" ");
         } else {
            strappend(before_tag, _word_case("FUNCTION"):+" ");
         }
      }

      // prepend qualified class name for C++
      if ((tag_flags & SE_TAG_FLAG_OPERATOR) && verbose) {
         tag_name = _word_case("OPERATOR"):+" ":+tag_name;
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,".",":");
         class_name = stranslate(class_name,".","/");
         tag_name   = class_name"."tag_name;
      }

      _str return_type=info.return_type;
      after_sig := "";
      if (return_type!="" && verbose) {
         if (lang=="vhd") {
            strappend(after_sig," return "return_type);
         } else {
            strappend(after_sig,": "return_type);
         }
      }
      if (verbose) {
         if (tag_flags & SE_TAG_FLAG_VIRTUAL) {
            strappend(after_sig,"; ":+_word_case("VIRTUAL"));
         }
         if (tag_flags & SE_TAG_FLAG_ABSTRACT) {
            strappend(after_sig,"; ":+_word_case("ABSTRACT"));
         }
         if (tag_flags & SE_TAG_FLAG_EXTERN) {
            strappend(after_sig,"; ":+_word_case("EXTERN"));
         }
      }

      // finally, insert the line
      result=before_tag:+tag_name:+"("info.arguments")":+after_sig;
      return(result);

   case "define":       // preprocessor macro definition
      if (verbose) {
         return(decl_indent_string"#define ":+tag_name:+arguments:+" "info.return_type);
      }
      return(decl_indent_string:+tag_name:+arguments);

   case "typedef":      // type definition
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,".",":");
         class_name = stranslate(class_name,".","/");
         tag_name   = class_name"."tag_name;
      }
      if (verbose) {
         return(decl_indent_string:+_word_case("TYPE"):+" "tag_name" = "info.return_type:+arguments);
      }
      return(decl_indent_string:+tag_name);

   case "gvar":         // global variable declaration
   case "var":          // member of a class / struct / package
   case "lvar":         // local variable declaration
   case "prop":         // property
   case "param":        // function or procedure parameter
   case "group":        // Container variable
      if (info.flags&SE_TAG_FLAG_CONST) {
         kw = (lang=="ada" || lang=="vhd")? "constant":"const";
      } else {
         kw = (lang=="vhd")? "variable":"var";
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,".",":");
         class_name = stranslate(class_name,".","/");
         tag_name   = class_name"."tag_name;
      }
      if (verbose) {
         return(decl_indent_string:+_word_case(kw):+" "tag_name": "info.return_type);
      }
      return(decl_indent_string:+tag_name);

   case "struct":       // structure definition
   case "enum":         // enumerated type
   case "class":        // class definition
   case "union":        // structure / union definition
   case "interface":    // interface, eg, for Java
   case "package":      // package / module / namespace
   case "prog":         // pascal program
   case "lib":          // pascal library
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,".",":");
         class_name = stranslate(class_name,".","/");
         tag_name   = class_name"."tag_name;
      }
      arguments = (info.arguments!="")? "<"info.arguments">" : "";
      switch (type_name) {
      case "struct":       type_name="RECORD";    break;
      case "enum":         type_name="ENUM";      break;
      case "class":        type_name="CLASS";     break;
      case "union":        type_name="VARIANT";   break;
      case "interface":    type_name=(lang=="mod")? "INTERFACE MODULE":"INTERFACE"; break;
      case "package":      type_name=(lang=="mod")? "MODULE":"UNIT";
                           if (lang=="ada") type_name = "PACKAGE";
                           break;
      case "prog":         type_name=(lang=="mod")? "IMPLEMENTATION MODULE":"PROGRAM";   break;
      case "lib":          type_name=(lang=="mod")? "MODULE":"LIBRARY";   break;
      case "task":         type_name="TASK";      break;
      }
      if (verbose) {
         return(decl_indent_string:+_word_case(type_name)" "tag_name:+arguments);
      }
      return(decl_indent_string:+tag_name:+arguments);

   case "label":        // label
      if (verbose) {
         return(decl_indent_string:+_word_case("LABEL"):+" "tag_name":");
      }
      return(decl_indent_string:+tag_name);

   case "import":       // package import or using
      if (verbose) {
         return(decl_indent_string:+_word_case("USES"):+" "tag_name);
      }
      return(decl_indent_string:+tag_name);

   case "friend":       // C++ friend relationship
      if (verbose) {
         return(decl_indent_string:+"friend "tag_name:+arguments);
      }
      return(decl_indent_string:+tag_name:+arguments);
   case "include":      // C++ include or Ada with (dependency)
      if (verbose) {
         return(decl_indent_string:+"#include "tag_name);
      }
      return(decl_indent_string:+tag_name);

   case "const":        // pascal constant
      proto=decl_indent_string;
      if (verbose) {
         proto :+= _word_case("CONSTANT"):+" ";
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name= stranslate(class_name,".",":");
         class_name= stranslate(class_name,".","/");
         strappend(proto,class_name:+".");
      }
      strappend(proto,info.member_name);
      if (info.return_type!="" && verbose) {
         if (pos("=",info.return_type)) {
            strappend(proto,": "info.return_type);
         } else {
            strappend(proto," = "info.return_type);
         }
      }
      return(proto);

   case "enumc":        // enumeration value
      proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!="") {
         class_name= stranslate(class_name,".",":");
         class_name= stranslate(class_name,".","/");
         strappend(proto,class_name:+".");
      }
      strappend(proto,info.member_name);
      if (info.return_type!="" && verbose) {
         strappend(proto," = "info.return_type);
      }
      return(proto);

   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "file":         // COBOL file descriptor
   case "cursor":       // Database result set cursor
      if (verbose) {
         return(decl_indent_string:+_word_case(type_name)" "tag_name);
      }
      return(decl_indent_string:+tag_name);

   default:
      proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!="") {
         class_name= stranslate(class_name,".",":");
         class_name= stranslate(class_name,".","/");
         strappend(proto,class_name:+".");
      }
      strappend(proto,info.member_name);
      if (info.return_type!="" && verbose) {
         strappend(proto,": "info.return_type" ");
      }
      return(proto);
   }
}
_str _ada_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return _pas_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
_str _mod_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return _pas_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
_str _m3_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   return _pas_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}
/*
   PARAMETERS
      OperatorTyped     When true, user has just typed last character of operator.
                        Example
                             p.<Cursor Here>
                        This should be false if cursorInsideArgumentList
                        is true.
      cursorInsideArgumentList
                        When true, user requested function help when
                        the cursor was inside an argument list.

                        Example
                          MessageBox(...,<Cursor Here>...)

                        Here we give help on MessageBox
      FunctionNameOffset  OUTPUT. Offset to start of function name.

      ArgumentStartOffset OUTPUT. Offset to start of first argument

  RETURN CODES
      0    Successful
      VSCODEHELPRC_CONTEXT_NOT_VALID
      VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
      VSCODEHELPRC_NO_HELP_FOR_FUNCTION
*/
int _pas_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   if (_chdebug) {
      isay(depth, "_pas_fcthelp_get_start");
   }
   errorArgs._makeempty();
   flags=0;
   typeless p=0;
   typeless junk=0;
   typeless p1,p2,p3,p4;
   typeless orig_pos;
   save_pos(orig_pos);
   ch := "";
   word := "";
   lastid := "";
   _str orig_seek = point('s');
   orig_col := p_col;
   orig_line := p_line;
   first_less_than_seek := 0;
   int status=search('[;()]','-rh@xcs');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset= -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) {
         break;
      }
      ch=get_text();
      //say("PCH="ch);
      if (ch=='(') {
         save_pos(p);
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         ch=get_text();
         word=cur_word(junk);
         restore_pos(p);
         if (pos('['word_chars']',ch,1,'r')) {
            if (pos(" "word" ",PASCAL_NOT_FUNCTION_WORDS)) {
               if (OperatorTyped && ArgumentStartOffset== -1) {
                  if (_chdebug) {
                     isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
                  }
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               break;
            }
            ArgumentStartOffset=(int)point('s')+1;
         } else {
            /*
               OperatorTyped==true
                   Avoid give help when have
                   myproc(....4+( <CursorHere>

            */
            if (OperatorTyped && ArgumentStartOffset== -1 &&
                ch!=")" &&   // (*pfn)(a,b,c)  OR  f(x)(a,b,c)
                ch!="]"      // calltab[a](a,b,c)
               ){
               if (_chdebug) {
                  isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
               }
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (ch==")" || ch=="]") {
               ArgumentStartOffset=(int)point('s')+1;
            }
         }
      } else if (ch==")") {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(orig_pos);
            if (_chdebug) {
               isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
            }
            return(VSCODEHELPRC_PARENTHESIS_MISMATCH);
         }
         save_pos(p);
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         word=cur_word(junk);
         if (pos(" "word" "," to downto if while except case until ")) {
            break;
         }
         restore_pos(p);
      } else  {
         break;
      }
      status=repeat_search();
   }
   if (ArgumentStartOffset>=0) {
      goto_point(ArgumentStartOffset);
   }

   ArgumentStartOffset=(int)point('s');
   left();
   left();
   search('[~ \t]|^','-rh@');
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      ch=get_text();
      if (ch==")" || ch=="]") {
         FunctionNameOffset=ArgumentStartOffset-1;
         if (_chdebug) {
            isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
         }
         return(0);
      } else {
         if (_chdebug) {
            isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      int end_col=p_col+1;
      search('[~'word_chars']\c|^\c','-rh@');
      lastid=_expand_tabsc(p_col,end_col-p_col);
      FunctionNameOffset=(int)point('s');
   }
   if (pos(" "lastid" ",PASCAL_NOT_FUNCTION_WORDS)) {
      if (_chdebug) {
         isay(depth, "_pas_fcthelp_get_start: H"__LINE__);
      }
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   return(0);
}

/*
   PARAMETERS
      FunctionHelp_list    (Input/Ouput)
                           Structure is initially empty.
                              FunctionHelp_list._isempty()==true
                           You may set argument lengths to 0.
                           See VSAUTOCODE_ARG_INFO structure in slick.sh.
      FunctionHelp_list_changed   (Output) Indicates whether the data in
                                  FunctionHelp_list has been changed.
                                  Also indicates whether current
                                  parameter being edited has changed.
      FunctionHelp_cursor_x  (Output) Indicates the cursor x
                             position in pixels relative to the
                             edit window where to display the
                             argument help.

      FunctionNameStartOffset,ArgumentEndOffset
                              (INPUT) The text between these two
                              end points needs to be parsed
                              to determine the new argument
                              help.
   RETURN
     Returns 0 if we want to continue with function argument
     help.  Otherwise a non-zero value is returned and a
     message is usually displayed.

   REMARKS
     If there is no help for the first function, a non-zero value
     is returned and message is usually displayed.

     If the end of the statement is found, a non-zero value is
     returned.  This happens when a user to the closing brace
     to the outer most function caller or does some weird
     paste of statements.

     If there is no help for a function and it is not the first
     function, FunctionHelp_list is filled in with a message
         FunctionHelp_list._makeempty();
         FunctionHelp_list[0].proctype=message;
         FunctionHelp_list[0].argstart[0]=1;
         FunctionHelp_list[0].arglength[0]=0;

  RETURN CODES
     1   Not a valid context
     (not implemented yet)
     10   Context expression too complex
     11   No help found for current function
     12   Unable to evaluate context expression
*/
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;
int _pas_fcthelp_get(_str (&errorArgs)[],
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
   //say("_pas_fcthelp_get");
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   //common='[,;()[]|'PASCAL_COMMON_END_OF_STATEMENT_RE;
   common := '[,;()[]|'PASCAL_COMMON_END_OF_STATEMENT_RE;
   _str cursor_offset=point('s');
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   goto_point(FunctionNameStartOffset);
   // enum, struct class
   status := search(common,'rh@xcs');
   preprocessing_top := 0;
   int preprocessing_ParamNum_stack[];
   int preprocessing_offset_stack[];
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   stack_top := 0;
   ParamNum_stack[stack_top]=0;
   nesting := 0;
   for (;;) {
      if (status) {
         break;
      }
      ch := get_text();
      //say('ch='ch);
      //say('cursor_offset='cursor_offset' p='point('s'));
      if (cursor_offset<=point('s')) {
         break;
      }
      if (ch==",") {
         ++ParamNum_stack[stack_top];
      } else if (ch==")") {
         --stack_top;
         if (stack_top<=0) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
      } else if (ch=="(") {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');
      } else if (ch=="[") {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(p);
            return(VSCODEHELPRC_BRACKETS_MISMATCH);
         }
      } else if (ch==";") {
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      //if (ch=='#' || ch=='{' || (pos('[~'p_word_chars']',get_text(1,match_length('s')-1),1,'r') &&
      //                           pos('[~'p_word_chars']',get_text(1,match_length('s')+match_length()),1,'r'))
      //    ) {
      //   // IF this could be enum, struct, or class
      //   if (stack_top>1 && (ch=='e' || ch=='s' || ch=='c')) {
      //      word=cur_word(junk);
      //      if (word=='enum' || word=='struct' || word=='class') {
      //         status=repeat_search();
      //         continue;
      //      }
      //   }
      //   restore_pos(p);
      //   return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      //}
      status=repeat_search();
   }
   typeless tag_files = tags_filenamea(p_LangId);
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]+1);
      status=_pas_get_expression_info(true,idexp_info);
      errorArgs[1] = idexp_info.lastid;

      if (_chdebug) {
         tag_idexp_info_dump(idexp_info, "_pas_fcthelp_get", depth);
         isay(depth, "_pas_fcthelp_get: status="status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         set_scroll_pos(orig_left_edge,p_col);

         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
            gLastContext_FunctionName :== idexp_info.lastid &&
            gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
            prev_otherinfo :== idexp_info.otherinfo &&
            prev_info_flags == idexp_info.info_flags &&
            prev_ParamNum   == ParamNum) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }

         // find matching symbols
         //say('lastid='lastid' prefixexp='prefixexp' ParamNum='ParamNum' otherinfo='otherinfo);
         globals_only := false;
         attributes_only := false;
         _str match_list[];
         match_symbol := idexp_info.lastid;
         match_flags := SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_CONSTANT|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_PACKAGE;

         // find symbols matching the given class
         VS_TAG_RETURN_TYPE rt;
         tag_return_type_init(rt);
         num_matches := 0;
         tag_clear_matches();
         status = _pas_get_type_of_prefix(errorArgs, idexp_info.prefixexp, rt, visited, depth+1);
         //say("_pas_get_type_of_prefix returns "match_class" status="status" match_tag="match_tag);
         if (_last_char(idexp_info.prefixexp)=="'") {
            attributes_only=true;
         } else if (status && (status!=VSCODEHELPRC_BUILTIN_TYPE || idexp_info.lastid!="")) {
            restore_pos(p);
            return status;
         }
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
            globals_only = true;
         }
         tag_clear_matches();
         // try to find 'lastid' as a member of the 'match_class'
         // within the current context
         if (attributes_only) {
            tag_list_in_class(idexp_info.lastid,"Predefined_Attributes",0,0,tag_files,
                              num_matches,def_tag_max_function_help_protos,
                              SE_TAG_FILTER_ANYTHING,SE_TAG_CONTEXT_ANYTHING,
                              true,false,null,null,visited,depth+1);
         } else if (idexp_info.lastid != "") {
            SETagContextFlags context_flags = globals_only? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
            tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, "",
                                        num_matches, def_tag_max_function_help_protos,
                                        match_flags, context_flags, 
                                        true, false, 
                                        visited, depth+1, rt.template_args);
            // try 'system' module
            if (num_matches==0) {
               tag_list_symbols_in_context(match_symbol, "System", 0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, 0,
                                           true, false, visited, depth+1);
            }
         } else {
            idexp_info.lastid = match_symbol;
         }

         //say("_pas_fcthelp_get: num_matches="tag_get_num_of_matches());

         // process variables whose type is a typedef, insert the typedef
         match_class := "";
         for (i:=1; i<=num_matches; i++) {
            tag_get_detail2(VS_TAGDETAIL_match_return, i, auto return_type);
            tag_get_detail2(VS_TAGDETAIL_match_type, i, auto type_name);
            tag_get_detail2(VS_TAGDETAIL_match_class, i, match_class);
            if (pos("var",type_name) && (tag_check_for_typedef(return_type, tag_files, false, match_class, visited, depth+1) || _LanguageInheritsFrom("verilog"))) {
               if (pos('[:]:v$',return_type,1,'r')) {
                  return_type = substr(return_type, pos('S')+1);
               }
               if (pos("procedure",return_type)==1) {
                  return_type = "";
               }
               if (_LanguageInheritsFrom("verilog")) {
                  match_class="";
               }
               SETagContextFlags context_flags = globals_only? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
               tag_list_symbols_in_context(return_type, match_class, 
                                           0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           SE_TAG_FILTER_TYPEDEF|SE_TAG_FILTER_PACKAGE,
                                           context_flags,
                                           true, false, visited, depth+1);
            }
         }

         // remove duplicates from the list of matches
         int unique_indexes[];
         _str duplicate_indexes[];
         removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         num_unique := unique_indexes._length();
         for (i=0; i<num_unique; i++) {
            j := unique_indexes[i];
            tag_get_match_browse_info(j, auto cm);
            // kick out matches that are not good
            if (num_unique > 1) {
               if (_file_eq(cm.file_name,p_buf_name) && cm.line_no:==p_line) {
                  continue;
               }
               if (tag_tree_type_is_class(cm.type_name) && cm.type_name!="task") {
                  continue;
               }
               if (cm.arguments=="" && (cm.flags & SE_TAG_FLAG_EXTERN)) {
                  continue;
               }
               if (pos("var", cm.type_name) && !pos('function|procedure',cm.return_type,1,'ri')) {
                  continue;
               }
            }
            if (cm.arguments=="" && (cm.flags & SE_TAG_FLAG_TEMPLATE)) {
               tag_get_detail2(VS_TAGDETAIL_match_template_args, j, cm.arguments);
            }
            if (cm.arguments=="" && (cm.flags & SE_TAG_FLAG_CONSTRUCTOR)) {
               tag_get_detail2(VS_TAGDETAIL_arguments, j, cm.arguments);
            }
            proc_name := cm.member_name;
            if (cm.class_name != "") {
               proc_name = cm.class_name "." proc_name;
            }
            //match_list[match_list._length()] = proc_name "\t" signature "\t" return_type;
            //say("match_list[i] = "match_list[match_list._length()-1]);
            match_list[match_list._length()] = proc_name "\t" cm.type_name "\t" cm.arguments "\t" cm.return_type"\t"j"\t"duplicate_indexes[i];
         }

         // sort and get rid of any duplicate entries (is this necessary?)
         match_list._sort();
         _aremove_duplicates(match_list, false);

         // translate functions into struct needed by function help
         have_matching_params := false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            for (i=0; i<match_list._length(); i++) {
               k := FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               parse match_list[i] with auto match_tag_name "\t" auto match_type_name "\t" auto signature "\t" auto return_type "\t" auto imatch "\t" auto duplist;
               //say("tag="match_tag_name" sig="signature" ret="return_type);
               if (pos('[:]:v$',return_type,1,'r')) {
                  return_type = substr(return_type, pos('S')+1);
               }
               if (pos("procedure",return_type)==1) {
                  return_type = "";
               }

               tag_get_match_browse_info((int)imatch, auto cm);
               prototype := match_tag_name"("signature")";
               if (return_type != "") {
                  prototype = prototype ": " return_type;
               }
               tag_autocode_arg_info_from_browse_info(FunctionHelp_list[k], cm, prototype, rt);
               base_length := length(match_tag_name) + 1;
               FunctionHelp_list[k].argstart[0]=length(return_type)+1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;

               foreach (auto z in duplist) {
                  if (z == imatch) continue;
                  tag_get_match_browse_info((int)z, cm);
                  tag_autocode_arg_info_add_browse_info_to_tag_list(FunctionHelp_list[k], cm, rt);
               }

               // parse signature and map out argument ranges
               j          := 0;
               arg_pos    := 0;
               comma_pos  := 0;
               before_pos := 0;
               argument := cb_next_arg(signature, arg_pos, 1);
               while (argument != "") {
                  //say("argument="argument);
                  do {
                     j = FunctionHelp_list[k].argstart._length();
                     FunctionHelp_list[k].argstart[j]=base_length+arg_pos+before_pos;
                     FunctionHelp_list[k].arglength[j]=length(argument);
                     if (j == ParamNum) {
                        // parse out the return type of the current parameter
                        pslang := p_LangId;
                        psindex := _FindLanguageCallbackIndex("%s_proc_search",pslang);
                        int temp_view_id;
                        int orig_view_id=_create_temp_view(temp_view_id);
                        _insert_text(argument";");
                        top();
                        pvarname := "";
                        if (psindex) {
                           status=call_index(pvarname,1,pslang,psindex);
                        } else {
                           _SetEditorLanguage(pslang, false);
                           status = _VirtualProcSearch(pvarname);
                        }
                        if (!status) {
                           tag_decompose_tag_browse_info(pvarname,auto param_cm);
                           FunctionHelp_list[k].ParamType=param_cm.return_type;
                           FunctionHelp_list[k].ParamName=param_cm.member_name;
                        }
                        _delete_temp_view(temp_view_id);
                        p_window_id = orig_view_id;
                     }

                     comma_pos = pos(",",argument);
                     if (comma_pos > 0) {
                        argument = substr(argument, comma_pos+1);
                        before_pos += comma_pos;
                     }
                  } while (comma_pos > 0);

                  argument = cb_next_arg(signature, arg_pos, 0);
                  comma_pos=0;
               }
               if (ParamNum != 1 && j < ParamNum) {
                  if (have_matching_params) {
                     FunctionHelp_list._deleteel(k);
                  }
               } else {
                  if (!have_matching_params) {
                     VSAUTOCODE_ARG_INFO func_arg_info = FunctionHelp_list[k];
                     FunctionHelp_list._makeempty();
                     FunctionHelp_list[0] = func_arg_info;
                  }
                  have_matching_params = true;
               }
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=true;
               }
               prev_prefixexp  = idexp_info.prefixexp;
               prev_otherinfo  = idexp_info.otherinfo;
               prev_info_flags = idexp_info.info_flags;
               prev_ParamNum   = ParamNum;
               if (!p_IsTempEditor) {
                  FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
               }
               break;
            }
         }
      }
   }
   if (idexp_info.lastid!=gLastContext_FunctionName || gLastContext_FunctionOffset!=idexp_info.lastidstart_offset) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName=idexp_info.lastid;
      gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}

int _pas_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   std_libs := "";
   ext := "pas";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"pascal") && !forceRebuild) {
      return(0);
   }

   if (_isWindows()) {
      // The user does not have an extension specific tag file for Slick-C
      dcc_binary := "";
      _str dirList[];
      getDelphiSrcPath(dirList);
      if (dirList._length()) {
         dcc_binary = dirList[0];
      } else {
         dcc_binary = "";
      }
      source_path := "";
      path := "";
      if (dcc_binary!="") {
         path = dcc_binary;
         source_path=file_match(_maybe_quote_filename(path:+"Source"), 1);
         if (source_path!="") {
            path :+= "Source":+FILESEP;
         }
         std_libs=_maybe_quote_filename(path:+"*.pas");
         //say("_pas_MaybeBuildTagFile: path="path" std_libs="std_libs);
      }
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"Delphi/Pascal Libraries",
                           true,std_libs,ext_builtins_path(ext,"pascal"), withRefs, useThread);
}

// Desc:  Get the specified key from Delphi 1 INI file.
// Retn:  value, or "" for key not found.
static _str getDelphi1Key( _str k1, _str k2 )
{
   // Get path to INI file:
   _str foundPath, windir, inifile;
   int file_exists;
   foundPath = "";
   windir = _get_windows_directory();
   inifile = windir:+"DELPHI.INI";
   file_exists = (int)(file_match("-p "inifile,1) != "");
   if ( !file_exists ) {
      return("");
   }

   // Scan INI file for [Visual-SlickEdit]:
   _str line;
   key := "";
   v1 := "";
   int foundClause;
   k1 = upcase(k1);
   k2 = upcase(k2);
   foundClause = 0;
   temp_view := 0;
   ori_view := 0;
   _open_temp_view( inifile, temp_view, ori_view );
   top();
   for (;;) {
      get_line( line );
      line = strip( line );
      if ( foundClause ) {
         parse line with key "=" v1;
         key = upcase(key);
         if ( key == k2 ) {
            foundPath = v1;
            break;
         }
      } else if ( pos( k1, upcase(line) ) ) {
         foundClause = 1;
      }
      if ( down() ) break;
   }
   _delete_temp_view( temp_view );
   return( foundPath );
}

// Desc:  Look up the Delphi 1.0 exe path from DELPHI.INI.
// Retn: path, "" for not found
static _str getDelphi1ExePath()
{
   // Get path from INI file:
   _str foundPath;
   foundPath = "";
   foundPath = getDelphi1Key( "[Library]", "ComponentLibrary" );
   if ( foundPath == "" ) {
      foundPath = getDelphi1Key( "[Experts]", "ExptDemo" );
   }
   _str dir;
   dir = _strip_filename(foundPath, 'N');
   _maybe_strip_filesep(dir);
   dir=_strip_filename(dir,"N");
   return(dir);
}

static _str getDelphiBasePath(_str path, _str valueName)
{
   _str exefile;
   int status;
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE, path, valueName, exefile);
   if (status) return("");
   _str dir;
   dir = _strip_filename(exefile, 'N');
   _maybe_strip_filesep(dir);
   dir=_strip_filename(dir,"N");
   return(dir);
}

// Look up the registry for the paths to the Delphi executables.
// The path to the newest version of Delphi is dirList[0].
static void getDelphiSrcPath(_str (&dirList)[])
{
   int count, status;
   dirList._makeempty();
   _str dir;
   count = 0;
   dir = getDelphiBasePath("SOFTWARE\\Borland\\Delphi\\4.0", "Delphi 4");
   if (dir != "") {
      dirList[count] = dir;
      count++;
   }
   dir = getDelphiBasePath("SOFTWARE\\Borland\\Delphi\\3.0", "Delphi 3");
   if (dir != "") {
      dirList[count] = dir;
      count++;
   }
   dir = getDelphiBasePath("SOFTWARE\\Borland\\Delphi\\2.0", "Delphi 2.0");
   if (dir != "") {
      dirList[count] = dir;
      count++;
   }
   dir = getDelphi1ExePath();
   if (dir != "") {
      dirList[count] = dir;
      count++;
   }
}


#region Options Dialog Helper Functions

/*Pascal Options Form*/
defeventtab _pas_extform;

void _pas_extform_init_for_options(_str langID)
{
   label2._use_source_window_font();
   label3._use_source_window_font();

   _language_form_init_for_options(langID, _pas_extform_get_value, 
                                   _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(langID);
}

_str _pas_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case "_comment":
      value = (int)LanguageSettings.getBeginEndComments(langId);
      break;
   case "_delphi_expand":
      value = (int)LanguageSettings.getDelphiExpansions(langId, true);
      break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}

bool _pas_extform_apply()
{
   _language_form_apply(_pas_extform_apply_control);

   return true;
}

_str _pas_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := "";

   switch (controlName) {
   case "_comment":
      LanguageSettings.setBeginEndComments(langId, ((int)value != 0));
      break;
   case "_delphi_expand":
      LanguageSettings.setDelphiExpansions(langId, ((int)value != 0));
      break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return updateString;
}

#endregion Options Dialog Helper Functions

void _pas_extform.on_destroy()
{
   _language_form_on_destroy();
}

/*End Pascal Options Form*/
