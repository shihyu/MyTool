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
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "clipbd.e"
#import "codehelp.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "main.e"
#import "markfilt.e"
#import "notifications.e"
#import "optionsxml.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  This PL/1 support module provides the following
  features:
    * SmartPaste(R)
    * Syntax expansion
    * Syntax indenting
    * Simple tagging on procedures
    * Selective display on procedures

  To install this macro, use the Load module
  dialog box ("Macro", "Load Module...").

  Built-in aliases

    BEGIN
    END;
    IF THEN DO;
    END;
    SELECT
    END;
    DO
    END;
    ELSE
    WHEN (expr) DO
    END;
    OTHERWISE;
*/
/*
Some language notes


PROCEDURES

mymain: PROC[EDURE] OPTIONS(MAIN);
end [mymain];

myproc: PROC[EDURE] (param1,param2) [RETURNS(type-description])];
 [DECLARE|DCL] local   <type-description>;
 [DECLARE|DCL] [number] param2 <type-description>;
 [DECLARE|DCL] [number] param1 <type-description>;

BLOCKS
   do until (expression);
   end;
   do i=1 to 10, while (expression), util (expression);
   end;
   do while ( expression);
   end;
   SELECT (expression);
   WHEN ()
   OTHERWISE   <-- or OTHER
   END;

   on endfile(xxx) begin
   end;

   begin/end styles
     0
         if expression then do;
         end else do;
         end;

     1   if expression then
             do;
             end;
         else
             do;
             end;
         end;


   ON ENDFILE(fh) begin
                  end;
   DCL 1 name


*/

static const PL1_LANGUAGE_ID=  "pl1";

/** 
 * These are used by _maybe_case_word and _maybe_case_backspace. 
 */
static int gWordEndOffset=-1;
static _str gWord;

static _str gtkinfo;
static _str gtk;

static _str pl1_next_sym(bool getword=false)
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   typeless status=0;
   ch := get_text();
   if (ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(pl1_next_sym());
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
   if (getword) {
      start_col=p_col;
      //search('[ \t]|$','r@');
      _TruncSearchLine('[ \t]|$','r');
      gtk=gtkinfo=ch;
      gtk=TK_ID;  // This really picks up a word and not and id
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
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
   if (ch=="-" && get_text()==">") {
      right();
      gtk=gtkinfo="->";
      return(gtk);

   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str pl1_prev_sym_same_line()
{
   //messageNwait('h0 gtk='gtk);
   /*if (gtk!='(' && gtk!='::') {
      return(pl1_prev_sym());
   } */
   orig_linenum := p_line;
   _str result=pl1_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      //messageNwait('h2');
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}
static _str pl1_prev_sym(bool getword=false)
{
   typeless status=0;
   ch := get_text();
   if (ch=="\n" || ch=="\r" || ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(pl1_prev_sym());
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
   if (getword) {
      end_col=p_col;
      search('[ \t]|^','-rh@');
      gtk=TK_ID;  // This really picks up a word and not and id
      if (match_length()) {
         right();
      }
      gtkinfo=_expand_tabsc(p_col,end_col-p_col+1);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if (p_col==1) {
      up();_end_line();
      /*if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      } */
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   if (ch==">" && get_text()=="-") {
      left();
      gtk=gtkinfo="->";
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);
}
defeventtab pl1_keys;
def  ' '= pl1_space;
def  'ENTER'= pl1_enter;
def 'a'-'z','A'-'Z','0'-'9','@','_','$','#'= pl1_maybe_case_word;
def 'BACKSPACE'= pl1_maybe_case_backspace;
def ';'=pl1_semi;
def '('=auto_functionhelp_key;

_command pl1_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PL1_LANGUAGE_ID);
}
_command void pl1_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_pl1_expand_enter);
}
bool _pl1_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _pl1_supports_insert_begin_end_immediately() {
   return true;
}
_command void pl1_semi() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin(';');
      return;
   }
   // check if the word at the cursor is end
   save_pos(auto p);
   pl1_prev_sym_same_line();
   _str tkinfo1=gtkinfo;
   pl1_prev_sym_same_line();
   _str tkinfo2=gtkinfo;
   pl1_prev_sym_same_line();
   restore_pos(p);
   int cfg=_clex_find(0,'g');
   get_line(auto line);
   if (cfg==CFG_COMMENT || cfg==CFG_STRING ) {
      keyin(';');
      return;
   }
   if (lowcase(line)!="end" && !(lowcase(tkinfo2)=="end"&& gtkinfo=="")) {
      /*
         Add END; to terminate SELECT or DO

            SELECT;
            END;
            DO;
            END;

      */
      keyin(';');
      if (lowcase(tkinfo1)=="select" || lowcase(tkinfo1)=="do") {
         updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
         if ((p_begin_end_style == BES_BEGIN_END_STYLE_3) && lowcase(tkinfo1)=="do") {
            prev_full_word();
         } else {
            _first_non_blank();
         }
         insert_line(indent_string(p_col-1)_word_case("end;",false,tkinfo1));
         up();_end_line();
         return;
      }
      return;
   }
   typeless orig_pos;
   save_pos(orig_pos);
   up();_end_line();
   block_info := "";
   int col=_pl1_find_block_col(block_info,false,(p_begin_end_style != BES_BEGIN_END_STYLE_3));
   block_info=lowcase(block_info);
   if (block_info!="do" && block_info!="begin") {
      _first_non_blank();
      col=p_col;
   }
   restore_pos(orig_pos);
   if (col) {
      replace_line(indent_string(col-1)strip(line)";");_end_line();
   } else {
      keyin(";");
   }
}

_command void pl1_auto_codehelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   auto_codehelp_key();
}

_command pl1_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
        pl1_expand_space()
        ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
         typeless orig_pos;
         save_pos(orig_pos);
         left();left();
         int cfg=_clex_find(0,'g');
         if (cfg==CFG_KEYWORD && LanguageSettings.getAutoCaseKeywords(p_LangId)) {
            word_pcol := 0;
            _str cw=cur_word(word_pcol);
            p_col=_text_colc(word_pcol,'I');
            _delete_text(length(cw));
            _insert_text(_word_case(cw));
         }
         restore_pos(orig_pos);
      }
   } else if (_argument=="") {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO pl1_space_words:[] = {
   "begin"     => { "BEGIN ... END;" },
   "do"        => { "DO ... END;" },
   "if"        => { "IF ... THEN DO; ... END;" },
   "else"      => { "ELSE" },
   "select"    => { "SELECT ... END;" },
   "when"      => { "WHEN ( ... ) DO; ... END;" },
   "otherwise" => { "OTHERWISE DO; ... END;" },
};


/*
    Returns true if nothing is done
*/
bool _pl1_expand_enter()
{
   save_pos(auto p);
   orig_linenum := p_line;
   orig_col := p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=="nosplit-insert-line") {
      _end_line();
   }
   int begin_col=pl1_begin_stat_col(false /* No RestorePos */,
                              false /* Don't skip first begin statement marker */,
                              false /* Don't return first non-blank */,
                              true  /* Return 0 if no code before cursor. */,
                              false,
                              true
                              );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(true);
   }
   restore_pos(p);
   int col=pl1_indent_col(0);
   indent_on_enter(0,col);
   return(false);
}
static void maybe_insert_doend(int syntax_indent,int be_style,int width,_str word,_str begin_word,int adjust_col=0,bool putCursorInsideDoBlock=false)
{
   int col=width+length(word)+2+adjust_col;
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN);
   if (p_no_space_before_paren) --col;
   if ( be_style == BES_BEGIN_END_STYLE_2 ) {
      width += syntax_indent;
   }
   if ( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
      up_count := 1;
      more_indent := 0;
      if ((be_style == BES_BEGIN_END_STYLE_3) &&
          lowcase(substr(begin_word,1,2))=="do") {
         more_indent=syntax_indent;
      }

      if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
         up_count++;
         insert_line(indent_string(width+more_indent):+begin_word);
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) || putCursorInsideDoBlock) {
         up_count++;
         insert_line(indent_string(width+syntax_indent));
      }
      if (be_style == BES_BEGIN_END_STYLE_3) {
         insert_line(indent_string(width+syntax_indent):+_word_case("end;",false,begin_word));
      } else {
         insert_line(indent_string(width):+_word_case("end;",false,begin_word));
      }
      set_surround_mode_end_line();
      if (putCursorInsideDoBlock) {
         up();col=p_col=width+syntax_indent+1;
      } else {
         up(up_count);
      }
   }
   p_col=col;
   if ( ! _insert_state() ) _insert_toggle();
}
/*
    Returns true if nothing is done.
*/
static _str pl1_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;

   typeless status=0;
   get_line(auto orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   _str sample=orig_word;
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   if_special_case := false;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,pl1_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=="") {
      // Check for ELSE IF or END; ELSE IF
      first_word := second_word := rest := "";
      parse orig_line with first_word second_word rest;
      first_word=lowcase(first_word);
      second_word=lowcase(second_word);
      if (first_word=="else" && lowcase(orig_word)==substr("else if",1,length(orig_word))) {
         word="else if";
         if_special_case=true;
      } else if (second_word=="else" && rest!="" && lowcase(orig_word)==substr("end; else if",1,length(orig_word))) {
         word="end; else if";
         if_special_case=true;
      } else if (first_word=="end;else" && second_word!="" && lowcase(orig_word)==substr("end;else if",1,length(orig_word))) {
         word="end;else if";
         if_special_case=true;
      } else {
         return(1);
      }
   }

   line=substr(line,1,length(line)-length(orig_word)):+_word_case(word,false,sample);
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);
   maybespace := " ";
   e1 := " do;";
   insertBeginEnd := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   // IF do/end goes on separate line
   if (be_style == BES_BEGIN_END_STYLE_2 || !(insertBeginEnd) || be_style == BES_BEGIN_END_STYLE_3) {
      e1="";
   }
   set_surround_mode_start_line();

   doNotify := true;
   if ( word=="if" || if_special_case) {
      if (be_style == BES_BEGIN_END_STYLE_3) {
         replace_line(line:+maybespace);
         maybe_insert_doend(syntax_indent,be_style,width,word,_word_case("then do;",false,sample));

         doNotify = ((line != orig_line) || LanguageSettings.getInsertBeginEndImmediately(p_LangId));
      } else {
         replace_line(line:+maybespace:+_word_case(" then":+e1,false,sample));
         maybe_insert_doend(syntax_indent,be_style,width,word,_word_case("do;",false,sample));
      }
   } else if (word=="when") {
      replace_line(line:+maybespace:+_word_case("()":+e1,false,sample));
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case("do;",false,sample),1);
   } else if (word=="other" || word=="otherwise") {
      newLine := line:+maybespace:+strip(_word_case(e1,false,sample));
      replace_line(newLine);
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case("do;",false,sample),0,true);

      doNotify = (newLine != orig_line || LanguageSettings.getInsertBeginEndImmediately(p_LangId));
   } else if (word=="do" || word=="select") {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case("end;",false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=="begin") {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case("end;",false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=="else") {
      newLine := _word_case(line,false,sample);
      replace_line(newLine);
      _end_line();++p_col;

      doNotify = (newLine != orig_line);
   } else {
      status=1;
      doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
}

int _pl1_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, pl1_space_words, prefix, min_abbrev);
}
_str _pl1_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

/**
 * Callback used by dynamic surround to do 
 * language specific indentation and un-indentation.
 * 
 * @param direction '+' for indent, '-' for unindent
 */
void _pl1_indent_surround(_str direction)
{
   // get the begin / end style setting
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   doSecondIndent := (p_begin_end_style == BES_BEGIN_END_STYLE_2)? true:false;

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

/*

PROCEDURES

  mymain: PROC[EDURE] OPTIONS(MAIN);
  end [mymain];

  myproc: PROC[EDURE] (param1,param2) [RETURNS(type-description])];
   [DECLARE|DCL] local   <type-description>;
   [DECLARE|DCL] [number] param2 <type-description>;
   [DECLARE|DCL] [number] param1 <type-description>;
  end [myproc];


*/
_str get_pl1_include_path()
{
   return def_pl1_include_path;
}

int pl1_proc_search(_str &proc_name,int find_first)
{
   // this is used for multi-item variable declarations
   //    dcl (a,b,c) <type-description>
   // we insert the first var found, and then hold onto the list
   // and insert each subsequent item on subsequent calls
   static _str var_list;

   // this is used to track variable nesting.  It keeps track of
   // the context ID's of all the parent variables, which are updated
   // as we move down the file.
   static int level_ids[];

   // this is used to keep track of variables and constants we have
   // already tagged.
   static bool have_vars:[];

   // initialize all the static locals on find_first
   if ( find_first ) {
      var_list = "";
      level_ids._makeempty();
      have_vars._makeempty();
   }

   // this is the regex search status
   status := 0;

   // if this is our first search, build the search expression first
   if ( find_first ) {
      // get the identifier regex
      word_re := _clex_identifier_re();

      // this regex is used for variable initializers 
      init_re := '(init[ \t]*\(?*\)[ \t]*|)';

      // this regex is used for comments optionally followed by new line
      comm_re := '([ \t]*\/\*?*\*\/[ \t]*|[ \t]*)(:i|'word_re'|)(\n|\r|\n\r|)[ \t]*';

      // this regex is for a multi-line function argument list.
      // it is also used for multi-variable declarations
      // THIS HAS EXPRESSION HAS CATASTROPHIC RESULTS
      // args_re := '\(\om[ \t]*{#4(%include 'word_re'|'word_re')[ \t]*'init_re''comm_re'[ \t]*(,[ \t]*'comm_re'(%include 'word_re';|'word_re')[ \t]*'init_re''comm_re')*}\)';
      // SIMPLIFIED (LESS CORRECT) VERSION - NO MULTILINE
      args_re := '\([ \t]*{#4([a-zA-Z@#$][a-zA-Z@#$0-9_]@)[ \t]*(\/\*?*\*\/[ \t]*|)(,[ \t]*(\/\*?*\*\/[ \t]*|)([a-zA-Z@#$][a-zA-Z@#$0-9_]@)[ \t]*)*}\)';

      // this regex is used for function return types
      retn_re := '('comm_re'{#5returns}[ \t(]'word_re')';

      // this part of the regex looks for procedure and entry points
      proc_re := '({#0([%]|)'word_re'}[ \t]*\:[ \t]*{#1(PROC|ENTRY|PROCEDURE)}([ \t]*'args_re'|)([ \t]*'retn_re'|))';

      // this regex is used to check for 'ext' and 'entry' on declarations,
      // which mark a declaration as a prototype.
      prot_re := '{#9([ \t]+(EXT[ \t]*|)ENTRY|)}';

      // this regex is used to identify variable declrations, defines and includes
      decl_re := '({#2(DCL|%DCL|DECLARE|%INCLUDE|[ \t](,[ \t]*|)[0-9]([0-9]|))}[ \t]+({#6[1-9]}[ \t]+|)(SYSLIB\({#3'word_re'}\)|{#3'word_re'}|'args_re')'prot_re')';

      // this regex is used to identify constant declarations
      cnst_re := "(([%]|){#7"word_re"}[ \\t]*{#8=}[ \\t]*[~\\n\\r;]*[ \\t]*;)";

      // this is the whole thing put together into one big regex
      re := '^([~a-zA-Z$]|)[ \t]*('proc_re'|'decl_re'|'cnst_re')';

      // now we search for a line that matches
      status=search(re,'hri@xcs');

   } else if (var_list != "") {

      // We need to finish parsing out a list of variables we started
      // parsing earlier.  Take one off the list and return the result.
      name := "";
      parse var_list with name "," var_list;
      if (name != "") {
         have_vars:[name] = true;
         tag_init_tag_browse_info(auto cm,name,"",SE_TAG_TYPE_VAR);
         name=tag_compose_tag_browse_info(cm);
         if (proc_name:=="") {
            proc_name=name;
            return(0);
         }
         if (proc_name==name) {
            return(0);
         }
      }

   } else {

      // we are continuing a search.  Check if the last search was a
      // procedure or function definition, and if, so, search ahead to the
      // end of the function or the beginning of the next function.
      get_line(auto line);
      if (pos('[:][ \t]*(proc|entry|procedure)[ \t;()]',line,1,'ri')) {
         save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
         _end_line();

         // identifier regex
         word_re := _clex_identifier_re();

         // can't do this because PL/I has nested functions
         status = STRING_NOT_FOUND_RC;
         /*
         // First, look specifically for the end with the name of the function.
         if (pos('{'word_re'}[:][ \t]*(proc|entry|procedure)[ \t;()]',line,1,'ri')) {
            save_pos(auto orig_end_pos);
            end_name := get_match_substr(line,0); 
            endn_re  := '((end|%end)[ \t]+'_escape_re_chars(end_name)')[ \t;]';
            status = search(endn_re,'hri@xcs');
            if (!status) {
               // if we found it, move to the end of the previous line
               up(); _end_line();
            }
         }
         */

         // if we didn't find the specific function end, do a more flexible search
         if (status) {
            // end function regex
            endp_re := '(end[ \t]+)|(%end[ \t;]+)';
            // regex for next function definition
            proc_re := '('word_re'[ \t]*\:[ \t]*(PROC|ENTRY|PROCEDURE))';
            // regex for next include statement
            incl_re := '(%INCLUDE 'word_re')';
            // now put them all together
            re := '^([~a-zA-Z$]|)[ \t]*('endp_re'|'proc_re'|'incl_re')';
   
            // now search
            status = search(re,'hri@xcs');
            if (!status) {
               // if we found it, move to the end of the previous line
               up(); _end_line();
            }
         }

         // now restore back to the original search expression
         restore_search(s1,s2,s3,s4,s5);
      }

      // search for another declaration
      status=repeat_search();
   }

   // update the end seek locations of all the outer variables
   // in our outer variable stack.
   if (proc_name == "") {
      for (i:=0; i<level_ids._length(); i++) {
         if (level_ids[i] != null && level_ids[i] > 0) {
            save_pos(auto p);
            if (status) bottom();
            _end_line();
            tag_end_context(level_ids[i], p_RLine, (int)_QROffset());
            restore_pos(p);
         }
      }
   }

   for (;;) {

      // the search failed, so just return STRING_NOT_FOUND
      if ( status ) {
         break;
      }

      // extract the name and type information from the search expression
      args := "";
      name := get_match_text(0);
      type := get_match_text(2);
      tag_flags := SE_TAG_FLAG_NULL;
      if (type=="") type = get_match_text(1);
      if (type=="") type = get_match_text(8);
      type = strip(stranslate(type, "", ","));

      // extract the variable level from the search expression.
      // if there is none, treat it as 0
      level := "";
      if (isnumber(type)) {
         level = type;
      } else if (strieq(type, "declare") || strieq(type, "dcl")) {
         level = get_match_text(6);
         if (level == "") level=0;
      } else {
         level = 0;
      }

      // now clip off all the stacked search levels to match our level
      // the end seek positions have already been updated
      while (level_ids._length() > (int)level) {
         last_i := level_ids._length()-1;
         level_ids[last_i] = 0;
         level_ids._deleteel(last_i);
      }

      // check for variable declarations
      if (strieq(type, "declare") || strieq(type, "dcl") || isnumber(type)) {

         // get the real variable name, or the list of variable names
         // if there is a list of var names, take the first one, and
         // stuff the rest into the static list
         name=get_match_text(3);
         if (name == "") {
            word_re := _clex_identifier_re();
            var_list = get_match_text(4);
            comm_re := '\/\*?*\*\/[ \t]*(:i|'word_re'|)';
            init_re := 'init[ \t]*\(?*\)';
            var_list = stranslate(var_list, "",  init_re, 'r');
            var_list = stranslate(var_list, "",  comm_re, 'r');
            var_list = stranslate(var_list, "", '[ \t\r\n]+', 'r');
            parse var_list with name ',' var_list; 
         }

         // mark this variable as tagged
         have_vars:[name] = true;

         // figure out if this is a variable or a prototype
         type = "var";
         tag_flags = SE_TAG_FLAG_INCLASS;
         prototype := get_match_text(9);
         if (pos("ext", prototype, 1, 'i')) {
            tag_flags |= SE_TAG_FLAG_EXTERN;
         }
         if (pos("entry", prototype, 1, 'i')) {
            type = "proto";
         }

         // it may be a group type, if the next match is at a variable
         // at a higher nesting level.
         if (level > 0) {
            save_pos(auto p);
            if (!repeat_search()) {
               next_type := get_match_text(2);
               next_type = strip(stranslate(next_type, "", ","));
               if (isnumber(next_type) && (int)next_type > (int)level) {
                  type = "group";
               }
            }
            restore_pos(p);
         }

         // and update the variable levels
         level_ids[0] = 0;
         level_ids[(int)level] = tag_get_num_of_context()+1;

      } else if (strieq(type, "%dcl")) {

         // treat %dcl like a #define in C
         name=get_match_text(3);
         type = "define";
         have_vars:[name] = true;

      } else if (strieq(type, "%include")) {

         // treat this like a #include in C
         // Note that we do not recursively parse includes, of course
         name=get_match_text(3);
         type="include";

      } else if (strieq(type, "=")) {

         // check for a constant declaration.
         // this could also be a variable assignment
         name=get_match_text(7);
         type="const";
         if (have_vars._indexin(name)) {
            status = repeat_search();
            continue;
         }

         // mark this variable as seen and put together the result
         have_vars:[name] = true;

      } else {

         // otherwise, we have a procedure definition
         // get the argument list and clean out comments and whitespace
         args = get_match_text(4);
         if (args != "") {
            word_re := _clex_identifier_re();
            comm_re := '\/\*?*\*\/[ \t]*(:i|'word_re'|)';
            init_re := 'init[ \t]*\(?*\)';
            args = stranslate(args, "",  init_re, 'r');
            args = stranslate(args, "",  comm_re, 'r');
            args = stranslate(args, "", '[ \t\r\n]+', 'r');
         }

         // check if it has a return type, then it is a function.
         retn := get_match_text(5);
         type = (retn != "")? "func":"proc";
      }

      // put together the tag information string
      tag_init_tag_browse_info(auto cm, name, "", type, tag_flags, "", 0, 0, args);
      name = tag_compose_tag_browse_info(cm);

      // finally, if they gave no proc_name, just return the next item
      if (proc_name:=="") {
         proc_name=name;
         return(0);
      }

      // otherwise if they are searching for a specific function,
      // only return if we found it.  Note, this logic is deprecated
      // and no longer used. 
      tag_init_tag_browse_info(cm, name, "", type);
      name = tag_compose_tag_browse_info(cm);
      if (proc_name==name) {
         return(0);
      }

      // next please
      status=repeat_search();
   }

   // If we get here, then we have failed to find a match.
   // reset all the static locals and return non-zero status
   var_list = "";
   level_ids._makeempty();
   have_vars._makeempty();
   return(status);
}


///////////////////////////////////////////////////////////////////////////////
// This function is called to search for local variables within the current
// function.  While it takes a lot of parameters (mirroring the list_tags
// callback functions), the only two that matter are the start seek position
// and the end_seekposition.
// 
// This function will ALWAYS be called from within a view containing
// the file being parsed, so we do not have to worry about opening a
// temporary view, or any of the <code>ltf_flags</code> (list tags flags).
// 
/*void pl1_list_locals(int unused_output_view_id, _str unused_filename_p, 
                     _str embedded_ext, int ltf_flags, 
                     int unused_tree_wid, int unused_bitmap_index,
                     int cur_start_seekpos, int end_seekpos)
{
   // save our location and last search parameters
   typeless p;
   save_pos(p);
   typeless s1,s2,s3,s4,s5;
   save_search(s1,s2,s3,s4,s5);

   // move to the start position for the search
   _GoToROffset(cur_start_seekpos);
   status := search(';', '@hXcs');
   if (status) return;
   down(); _begin_line();
   bool found_locals:[];

   // Now we loop until we either find nothing more, or we hit the
   // end of the function.
   ff := 1;
   for (;;) {

      // search for make or local statements
      proc_name := "";
      status = pl1_proc_search(proc_name, ff);
      ff = 0;

      // stop if not found or past end marker
      if (status) break;
      if (_QROffset() > end_seekpos) break;

      // get the line and parse out the variable namec
      tag_name := "";
      class_name := "";
      type_name := "";
      tag_flags := 0;
      args := "";
      tag_tree_decompose_tag(proc_name, tag_name, class_name, type_name, tag_flags, args);
      if (tag_name == "") break;

      // have we already seen this declared?
      if (found_locals._indexin(tag_name)) continue;
      if (tag_find_context_iterator(tag_name, true, false) > 0) continue;
      if (type_name == 'var') type_name = 'lvar';
      if (args != "") args = VS_TAGSEPARATOR_args:+args;

      // find it's start seek position
      start_offset := (int)_QROffset();
      save_pos(auto begin_p);
      _end_line();
      end_offset := (int)_QROffset();
      restore_pos(begin_p);

      // finally, insert the tag
      found_locals:[tag_name]=true;
      tag_insert_local2(tag_name, type_name, p_buf_name,
                        p_RLine, start_offset,
                        p_RLine, start_offset,
                        p_RLine, end_offset,
                        class_name, tag_flags, args);
   }

   // restore state and we are done
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
}*/

#if 0
/*
    This functions make show_procs smarter by showing user
    all parameters and attributes of the function definition
    but not the code.
*/
void pl1_find_lastprocparam()
{
   save_pos(auto p);
   typeless startpos=_nrseek();
   int status=search(";","@hxcs");
   if (status) {
      restore_pos(p);
      return;
   }
   orig_col := p_col;
   first_non_blank();
   if (p_col==orig_col) {
      up();_end_line();
   }
}
#endif

/*


  Block constructs

   do until (expression);
   end;
   do i=1 to 10, while (expression), util (expression);
   end;
   do while ( expression);
   end;
   select (expression);
   end;

   on endfile(xxx) begin
   end;

   begin/end styles
     0
         if expression then do;
         end else do;
         end;

     1   if expression then
             do;
             end;
         else
             do;
             end;
         end;


   ON ENDFILE(fh) BEGIN
                  END;

*/
int _pl1_find_block_col(_str &block_info/* currently just block word */,bool restoreCursor,bool returnFirstNonBlank)
{
   typeless orig_pos;
   save_pos(orig_pos);
   int nesting;
   nesting=1;
   status := search('select|begin|do|end|procedure|proc|entry','h@-wirxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      word := lowcase(get_match_text());
      //messageNwait(word);
      switch (word) {
      case "begin":
      case "do":
      case "proc":
      case "entry":
      case "procedure":
      case "select":
         --nesting;
         break;
      case "end":
         ++nesting;
         break;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         junk := 0;
         block_info=cur_word(junk);
         if (returnFirstNonBlank) {
            _first_non_blank();
         }
         col := p_col;
         if (restoreCursor) {
            restore_pos(orig_pos);
         }
         return(col);
      }
      status=repeat_search();
   }
}
/*

   Return beginning of statement column.  0 if not found.

*/
static int pl1_begin_stat_col(bool RestorePos,bool SkipFirstHit,bool ReturnFirstNonBlank,
                              bool FailIfNoPrecedingText=false,
                              bool AlreadyRecursed=false,
                              bool FailWithMinus1_IfNoTextAfterCursor=false,
                              //bool leave_cursor_at_start_of_word=false
                              )
{

   orig_linenum := p_line;
   orig_col := p_col;
   //FailIfNoPrecedingText=(arg(4)!="");
   //AlreadyRecursed=(arg(5)!="");
   //FailWithMinus1_IfNoTextAfterCursor=(arg(6)!="");
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   save_pos(auto p);
   int status=search('[;]|do|then|else|begin|when','h-RI@xcs');
   //status=search('[;]|do|begin|when','h-RI@xcs');
   junk := 0;
   word := "";
   nesting := 0;
   hit_top := false;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         word=lowcase(get_match_text());
         if (word!=";" && word!=lowcase(cur_word(junk))) {
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         /*switch (get_text()) {
         case '(':
            FailIfNoPrecedingText=false;
            if (nesting>0) {
               --nesting;
            }
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         case ')':
            FailIfNoPrecedingText=false;
            ++nesting;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         */
         if (SkipFirstHit || nesting) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         // Special case most words which can be considered to start a statement.
         // If this causes problems in the future, we will have to add a
         // parameter to this function to specify whether this check should
         // be made.
         if (word!="do" && word!="begin" && word!="when") {
            p_col+=match_length();
         }
      }
      status=_clex_skip_blanks();
      if (status) {
         restore_pos(p);
         /*
             Would could have an open brace followed by blanks and eof.
         */
         if (!hit_top) {
            if (!FailWithMinus1_IfNoTextAfterCursor) {
               return(p_col);
            }
            return(-1);
         }
         return(0);
      }
      /*
          We could have the following:

            class name:public name2 {

          recurse to look for "case" keyword

      */
      if (ReturnFirstNonBlank) {
         _first_non_blank();
      }
      col := p_col;
      if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>orig_col)) {
         return(0);
      }
      if (RestorePos) {
         restore_pos(p);
      }
      return(col);
   }
}
static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   //_message_box("This case not handled yet");
   // SmartPaste(R) should set the non_blank_col
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      restore_pos(p);
      return(non_blank_col);
   }
   restore_pos(p);
   col := 0;
   int begin_stat_col=pl1_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker */,
                                   true  /* return first non-blank */
                                   );

   if (begin_stat_col && (p_line<orig_linenum ||
                          (p_line==orig_linenum && p_col<=orig_col)
                         )
      ) {
#if 0
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p2);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      ch := get_text();
      if (ch:==")") {
         restore_pos(p);
         return(begin_stat_col);
      }
      restore_pos(p2);
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      col=p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ch!=',') {
         restore_pos(p);
         return(col);
      }
      int nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
#endif
      col=p_col;
      restore_pos(p);
      return(col+syntax_indent);
   }
   restore_pos(p);
   line := "";
   get_line(line);
   line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   _first_non_blank();
   col=p_col;
   restore_pos(p);
   return(col);
}
static int HandlePartialStatement(int statdelim_linenum,
                                  int sameline_indent,
                                  int nextline_indent,
                                  int orig_linenum,int orig_col)
{
   orig_ch := get_text();
   typeless orig_pos;
   save_pos(orig_pos);
   //linenum=p_line;col=p_col;

   int begin_stat_col=pl1_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker. */,
                                   false /* Don't return first non-blank */,
                                   false,
                                   false,
                                   true   // Fail if no text after cursor
                                   );
   word := "";
   word_chars := _clex_identifier_chars();
   if (begin_stat_col>0 && pos('['word_chars']',get_text(),1,'r')) {
      junk := 0;
      word=cur_word(junk);
      p_col+=length(word);
   }
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=pl1_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */
                                      );
      if (p_line==statdelim_linenum) {
         return(begin_stat_col+sameline_indent);
      }
      col := p_col;
      return(col+nextline_indent);
#if 0
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      ch := get_text();
      if (ch:==")") {
         return(begin_stat_col);
      }
      restore_pos(p);
      /*
         IF semicolon is on same line as extra characters

         Example
            {b=<ENTER>
      */
      if (p_line==statdelim_linenum) {
         return(begin_stat_col+sameline_indent);
      }
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      col=p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ch!=',') {
         return(col);
      }
      return(col+nextline_indent);
#endif
   }
   return(0);
}

/*
    Cursor should be on a semicolon or at the place where the semicolon
    would go when this routine is called.
*/
static bool _SemicolonTerminatesProc(int &col)
{
   save_pos(auto p);
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   int begin_stat_col=pl1_begin_stat_col(false /* RestorePos */,
                              false /* skip first begin statement marker */,
                              true/* return first non-blank */
                              );
   if (!begin_stat_col) {
      restore_pos(p);
      return(false);
   }
   get_line(auto line);
   label_name := rest := "";
   parse line with label_name":" rest;
   if (label_name=="" || pos('[ \t]',label_name,1,'r')) {
      restore_pos(p);
      return(false);
   }
   b4 := "";
   parse rest with b4 '(proc|procedure|entry)[ \t;]','ri' +0 rest;
   if (b4!="") {
      restore_pos(p);
      return(false);
   }
   if (rest=="") {
      // This line is just a label
      restore_pos(p);
      return(false);
   }
   restore_pos(p);
   col=begin_stat_col;
   return(true);
}
static bool _SemicolonTerminatesBlock(int &col,_str &blockinfo,bool &semi_follows)
{
   blockinfo="";semi_follows=false;
   if (_SemicolonTerminatesProc(col)) {
      return(true);
   }
   save_pos(auto p);
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   int begin_stat_col=pl1_begin_stat_col(false /* RestorePos */,
                              false /* skip first begin statement marker */,
                              false/* return first non-blank */
                              );
   if (!begin_stat_col) {
      restore_pos(p);
      return(false);
   }
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   junk := 0;
   word := lowcase(cur_word(junk));
   if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
      save_pos(auto p2);
      p_col+=length(word);
      _clex_skip_blanks();
      semi_follows=get_text()==";";
      restore_pos(p2);
   }
   //ch_after_word=get_text(1,_nrseek()+length(word));
   blockinfo=word;
   if (word=="do"|| word=="begin" || (word=="select" && p_indent_case_from_switch)) {
      orig_col := p_col;
      _first_non_blank();
      if ((p_begin_end_style == BES_BEGIN_END_STYLE_3) &&
          ((word=="do"&& semi_follows) || word=="begin")) {
         if (p_col<orig_col) {
            p_col+=p_SyntaxIndent;

         } else {
            p_col=orig_col;
         }
      }
      col=p_col;
      restore_pos(p);
      return(true);
   }
   restore_pos(p);
   return(false);
}
/*
   This code is just here incase we get fancy
*/
int pl1_indent_col(int non_blank_col, bool pasting_open_block = false)
{
   orig_col := p_col;
   orig_linenum := p_line;
   save_pos(auto p);
   typeless UseContOnParameters=LanguageSettings.getUseContinuationIndentOnFunctionParameters(p_LangId);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   // IF user does not want syntax indenting
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=="nosplit-insert-line") {
      _end_line();
   }

   col := 0;
   nesting := 0;
   OpenParenCol := 0;
   begin_stat_col := 0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   typeless junk=0;
   typeless status=search('[;()]|dcl|declare|then|else|do|begin','h-RI@xcs');
   for (;;) {
      if (status) {
         if (nesting<0) {
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      ch := get_text();
      switch (ch) {
      case "(":
         if (!nesting && !OpenParenCol) {
            save_pos(auto p3);
#if 1
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanks();


            if (!(UseContOnParameters==FPAS_CONTINUATION_INDENT) &&
                !status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<orig_col)
                           )) {
               col=p_col-1;
            } else {
               /*
                  case: Use continuation indent instead of lining up on
                  open paren.

                  aButton.addActionListener(<Enter here. No args follow>
                      a,
                      b,
               */
               restore_pos(p3);
               goto_point(_nrseek()-1);
               //if (_clex_skip_blanks('-')) return(0);
               //word=cur_word(junk);
               pl1_prev_sym();
               if (gtk==TK_ID && !pos(" "gtkinfo" "," with for if switch while ")) {
                  restore_pos(p3);
                  _first_non_blank();
                  col=p_col+p_SyntaxIndent-1;
               }
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#else
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanks();
            if (!status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<=orig_col)
                           )) {
               col=p_col-1;
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#endif
            OpenParenCol=col;
            restore_pos(p3);
         }
         --nesting;
         status=repeat_search();
         continue;
      case ")":
         ++nesting;
         status=repeat_search();
         continue;
      default:
         if (nesting<0) {
            //messageNwait("nesting case");
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
      }
      if (nesting ) {
         status=repeat_search();
         continue;
      }
      word := get_match_text();
      if (word!=";" && word!=cur_word(junk)) {
         status=repeat_search();
         continue;
      }
      word=lowcase(word);

      //messageNwait("c_indent_col2: ch="ch);
      switch (word) {
      case ";":
         //messageNwait("case ;");
         save_pos(auto p2);
         save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

         statdelim_linenum := p_line;
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         right();
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);

         left();
         pl1_prev_sym();
         info := lowcase(gtkinfo);
         if (info=="end") {
            /*
               We may need to un indent for this
               IF expr THEN
                   DO;
                   END;<enter>
               ELSE
                   DO;
                   END;<enter>
               IF expr THEN
                   DO;
                   END;
               ELSE IF expr THEN
                   DO;
                   END;<enter>
               ON ENDFILE(file)
                  begin
                  end;<enter>

            */
            block_info := "";
            col=_pl1_find_block_col(block_info,false,false);
            if (col) {
               block_info=lowcase(block_info);
               if (block_info=="do" ) {
                  if(p_col==1) {
                     up();_end_line();
                  } else {
                     left();
                  }
                  // Check if the previous symbol is a semicolon
                  pl1_prev_sym();
                  if (lowcase(gtkinfo)!=";") {
                     find_if := false;
                     if (lowcase(gtkinfo)=="else") {
                        find_if=true;
                        pl1_prev_sym();
                        if (gtkinfo==";") pl1_prev_sym();
                        pl1_prev_sym();
                        if (lowcase(gtkinfo)=="end") {
                           _pl1_find_block_col(block_info,false,false);
                        }
                     } else if (lowcase(gtkinfo)=="then") {
                        find_if=true;
                     } else if(gtkinfo==")") {
                        /*
                            WHEN  (i<j)
                                DO;
                                END;
                        */
                        begin_stat_col=pl1_begin_stat_col(
                           false, // RestorePos
                           false, // skip first begin statement marker */
                           false  // return first non-blank
                           );
                        if (begin_stat_col ) {
                           word=lowcase(cur_word(junk));
                           if (word=="when") {
                              restore_pos(p);
                              return(begin_stat_col);
                           }
                        }
                     } else if (lowcase(gtkinfo)=="otherwise" || lowcase(gtkinfo)=="other") {
                        /*
                            OTHERWISE
                                DO;
                                END;
                        */
                        _clex_skip_blanks();
                        col=p_col;
                        restore_pos(p);
                        return(col);

                     }
                     if (find_if) {
                        status=search('IF','h-@rwixcs');
                        if (!status) {
                           _first_non_blank();
                           col=p_col;
                           restore_pos(p);
                           return(col);
                        }
                     }

                  }
               } else if (block_info=="begin") {
                  begin_stat_col=pl1_begin_stat_col(false /* RestorePos */,
                                             true /* skip first begin statement marker */,
                                             true /* return first non-blank */
                                             );
                  if (begin_stat_col) {
                     restore_pos(p);
                     return(begin_stat_col);
                  }
               }
            }
            // This is the simple case where do/begin/end is not part
            // of a larger block construct.
         } else {
            restore_pos(p2);
            blockinfo := "";
            semi_follows := false;
            if (_SemicolonTerminatesBlock(col,blockinfo,semi_follows)) {
               if ((p_begin_end_style == BES_BEGIN_END_STYLE_3) &&
                   ((blockinfo=="do"&& semi_follows) || blockinfo=="begin")
                  ){
                  restore_pos(p);
                  return(col);

               }
               restore_pos(p);
               return(col+syntax_indent);
            }
         }
         restore_search(s1,s2,s3,s4,s5);
         if (info=="begin" || info=="do") {
            restore_pos(p2);
            status=repeat_search();
            continue;
         }
         restore_pos(p2);

         begin_stat_col=pl1_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */
                                    );
         restore_pos(p);
         return(begin_stat_col);
      case "then":

         statdelim_linenum=p_line;
         save_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         //p_col+=length(word);
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);

         left();   // Don't worry about then in column 1.
         _clex_skip_blanks('-');
         status=search('IF','h-@rwixcs');
         if (status) {
            _first_non_blank();
            col=p_col+syntax_indent;
            restore_pos(p);
            return(col);
         }
         /*  IF expression THEN

         */
         _first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);

      case "do":
      case "begin":

         statdelim_linenum=p_line;
         save_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         p_col+=length(word);
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         _first_non_blank();
         col=p_col;
         restore_pos(p2);
         if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
         } else {
            col += syntax_indent;
         }
         restore_pos(p);
         return(col);

      case "else":
         statdelim_linenum=p_line;
         save_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         //p_col+=length(word);
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);

         _first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);
      case "dcl":
      case "declare":
         col=p_col;
         save_pos(p2);
         restore_pos(p);
         save_search(s1,s2,s3,s4,s5);
         _clex_skip_blanks('-');
         isContinuation := get_text()!=",";
         status=search('^[ \t]*\c{:i|DCL|DECLARE}','@hri-xcs');
         for (;;) {
            if (status) {
               // This is strange
               restore_pos(p);
               return(col);
            }
            word=lowcase(cur_word(junk));
            if (isinteger(word) || word=="dcl" || word=="declare") {
               break;
            }
            repeat_search();
         }
         col=p_col;
         if (isinteger(word)) {
            restore_pos(p);
            return((isContinuation)?col+syntax_indent:col);
         }
         restore_pos(p);
         return(col+syntax_indent);
      default:
         _message_box("unknown word="word);
      }
      status=repeat_search();
   }

}
int pl1_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   comment_col := "";
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   first_line := "";
   get_line(first_line);
   int i=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!="" && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   int status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!="") || (!status && comment_col!="" && p_col!=comment_col)) {
      return(0);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   typeless junk=0;
   typeless enter_col=0;
   word := lowcase(cur_word(junk));
   ignore_column1 := false;
   if (!status && (word=="end")) {
      save_pos(auto p2);
      up();_end_line();
      block_info := "";
      enter_col=_pl1_find_block_col(block_info,false,(p_begin_end_style != BES_BEGIN_END_STYLE_3));
      block_info=lowcase(block_info);
      if (block_info!="do" && block_info!="begin") {
         _first_non_blank();
         enter_col=p_col;
      }
      restore_pos(p2);
      if (!enter_col) {
         enter_col="";
      }
      _begin_select();get_line(first_line);up();
   /*} else if (!status && (word=='else')) {
      // Align else with if
      //messageNwait('it was an else');
      save_pos(p2);
      up();_end_line();
      enter_col=_pl1_find_block_col(block_info,true,true);
      restore_pos(p2);
      if (enter_col && lowcase(block_info)!='if') {
         enter_col+=syntax_indent;
      }
      if (!enter_col) {
         enter_col="";
      }
      _begin_select;get_line first_line;up();*/
   } else {
      ignore_column1=!allow_col_1;
      _begin_select();get_line(first_line);up();
      _end_line();
      enter_col=pl1_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && ignore_column1) || enter_col=="" ||
      (substr(first_line,1,1)!="" && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static _str pl1_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      pl1_enter_col2(enter_col) ) {
      return("");
   }
   return(enter_col);
}


static bool pl1_enter_col2(int &enter_col)
{
   enter_col=pl1_indent_col(0);
   return(false);
}

//Returns 0 if the letter wasn't upcased, otherwise 1
_command void pl1_maybe_case_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_word(LanguageSettings.getAutoCaseKeywords(PL1_LANGUAGE_ID),gWord,gWordEndOffset);
}

_command void pl1_maybe_case_backspace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_backspace(LanguageSettings.getAutoCaseKeywords(PL1_LANGUAGE_ID),gWord,gWordEndOffset);
}


int _pl1_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags,
                               depth));
}
int _pl1_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}


int _pl1_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,
                               lastidstart_offset,
                               info_flags,
                               otherinfo,
                               find_parents,
                               max_matches,
                               exact_match,
                               case_sensitive,
                               filter_flags,
                               context_flags,
                               visited, depth,
                               prefix_rt);
}

int _pl1_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator,idexp_info,visited,depth);
//   say('_pl1_get_expression_info');
//   if (_in_comment()) {
//      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
//   }
////   say("_pl1_get_expression_info(): operator="PossibleOperator);
//   tag_idexp_info_init(idexp_info);
//   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
//   save_pos(auto orig_pos);
//   word_chars := _clex_identifier_chars();
////   say('_pl1_get_expression_info: word_chars='word_chars);
//   if (PossibleOperator) {
//      left();
//      _str ch=get_text();
////      say("_pl1_get_expression_info(): ch="ch'=');
//      switch (ch) {
//      case '.':
////       orig_col=p_col;
//         // foo.bar, foo is not a constructor or destructor, even if name matches
//         idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
//         // Watch out for parse <exp> with a . b .
////       if (slickc && get_text_safe(1,(int)point('s')-1)=="") {
////          restore_pos(orig_pos);
////          return(VSCODEHELPRC_CONTEXT_NOT_VALID);
////       }
//         // Screen out floating point.  1.0
//         if (isdigit(get_text_safe(1,(int)point('s')-1))) {
//            // Check if identifier before . is a number
//            save_pos(auto p2);
//            left();
//            search('[~'word_chars']\c|^\c','-rh@');
//            if (isdigit(get_text_safe())) {
//               restore_pos(orig_pos);
//               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
//            }
//            restore_pos(p2);
//         }
//         get_line(auto line);
//         if (pos('^[ \t]*\#[ \t]*include',line,1,'r')) {
//            // Screen out -->  #include <iostream.h>
//            restore_pos(orig_pos);
//            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
//         }
//         right();
//         // get the id after the dot
//         // IF we are on a id character
//         if (pos('['word_chars']',get_text_safe(),1,'r')) {
//            int start_col=p_col;
//            typeless start_offset=point('s');
//            //search('[~'p_word_chars']|$','r@');
//            _TruncSearchLine('[~'word_chars']|$','r');
//            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
////            say('idexp_info.lastid='idexp_info.lastid);
//            idexp_info.lastidstart_col=start_col;
////            say('idexp_info.lastidstart_col='idexp_info.lastidstart_col);
//            idexp_info.lastidstart_offset=start_offset;
////            say('idexp_info.lastidstart_offset='idexp_info.lastidstart_offset);
//         } else {
//            idexp_info.lastid="";
////            say('idexp_info.lastid='idexp_info.lastid);
//            idexp_info.lastidstart_col=p_col;
////            say('idexp_info.lastidstart_col='idexp_info.lastidstart_col);
//            idexp_info.lastidstart_offset=(int)point('s');
////            say('idexp_info.lastidstart_offset='idexp_info.lastidstart_offset);
//         }
//         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
////       p_col=orig_col;
//         restore_pos(orig_pos);
//         break;
////    case '(':
////       idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
////       left();
////       _clex_skip_blanks('-');
////       if (pos('[~'word_chars']',get_text(),1,'r')) {
////          restore_pos(orig_pos);
////          return(1);
////       }
////       end_col=p_col+1;
////       search('[~'word_chars']\c|^\c','-rh@');
////       idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
////       idexp_info.lastidstart_col=p_col;
////       idexp_info.lastidstart_offset=(int)point('s');
////       cob_maybe_ignore_paren(idexp_info);
////       if (idexp_info.lastid!="" && pos(' 'idexp_info.lastid' ',COBOL_SYNTAX_WORDS,1,'i')) {
////          restore_pos(orig_pos);
////          return(1);
////       }
////       if(p_col==1) {
////          up();_end_line();
////       } else {
////          left();
////       }
////       break;
////    case ':':
////       if (get_text(1,(int)point('s')-1)!=':') {
////          restore_pos(orig_pos);
////          return(1);
////       }
////       int orig_col=p_col;
////       right();
////       // get the id after the ::
////       // IF we are on a id character
////       if (pos('['word_chars']',get_text(),1,'r')) {
////          int start_col=p_col;
////          int start_offset=(int)point('s');
////          //search('[~'p_word_chars']|$','r@');
////          _TruncSearchLine('[~'word_chars']|$','r');
////          idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
////          idexp_info.lastidstart_col=start_col;
////          idexp_info.lastidstart_offset=start_offset;
////       } else {
////          idexp_info.lastid="";
////          idexp_info.lastidstart_col=p_col;
////          idexp_info.lastidstart_offset=(int)point('s');
////       }
////       p_col=orig_col;
////       break;
//      default:
//         restore_pos(orig_pos);
//         return(1);
//      }
//   }
//   return 0;
}

int _pl1_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return 0;
}

defeventtab _pl1_extform;

label2.on_create()
{
   label2._use_source_window_font();
   label3._use_source_window_font();
   ctllabel1._use_source_window_font();
}
