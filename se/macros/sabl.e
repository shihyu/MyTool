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
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "pmatch.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*

   docs on EXIT wrong
   Can two statements be on the same line
   Can a statement follow the THEN
   keyword on the same line.
   are / * comments support?
   Preprocessing?
   Header files?

   Test let and plcwrite function help


  This SABL support module provides the following
  features:
    * SmartPaste(R)
    * Syntax expansion
    * Syntax indenting

  To install this macro, use the Load module
  dialog box ("Macro", "Load Module...").

  Built-in aliases

   IF THEN

   BEGIN
   END

   ELSE

  Other block constructs
   FOR i=a TO b STEP z
   NEXT i
*/

static const VSAUTOCODEINFO_SABL_IS_PROC=   VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS;
static const VSAUTOCODEINFO_SABL_IS_FUNC=   0x1000000;
static const VSAUTOCODEINFO_SABL_IS_LABEL=  0x2000000;
/*
   This is turned on if there is only one
   possible match.
*/
static const VSAUTOCODEINFO_SABL_EXACT_MATCH= 0x4000000;
static const VSAUTOCODEINFO_SABL_LASTID_FOLLOWED_BY_SPACE=  0x8000000;

static const SEQ_LANGUAGE_ID=    "seq";

static int gWordEndOffset=-1;
static _str gWord;

static const BESTYLE_FLAG=    1;

static _str gtkinfo;
static _str gtk;

_str _pro_next_arg(_str params,int &arg_pos,int find_first,_str ArgSep_re="");

static _str seq_next_sym(bool getword=false)
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
   if (ch=="" || (ch==";" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(seq_next_sym());
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
      search('[ \t]|$','rh@');
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
      search('[~'word_chars']|$','@rh');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=='-' && get_text()=='>') {
      right();
      gtk=gtkinfo="->";
      return(gtk);

   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str seq_next_sym_same_line()
{
   orig_linenum := p_line;
   _str result=seq_next_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum) {
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}
static _str seq_prev_sym_same_line()
{
   //messageNwait('h0 gtk='gtk);
   /*if (gtk!='(' && gtk!='::') {
      return(seq_prev_sym());
   } */
   orig_linenum := p_line;
   _str result=seq_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      //messageNwait('h2');
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}

static _str seq_prev_sym(bool getword=false)
{
   typeless status=0;
   ch := get_text();
   if (ch=="\n" || ch=="\r" || ch=="" || (ch==";" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(seq_prev_sym());
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
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   gtk=gtkinfo=ch;
   return(gtk);
}
defeventtab seq_keys;
def ' '=seq_space;
def  'ENTER'= seq_enter;
def '='=seq_equal;
def '('=auto_functionhelp_key;
def  'a'-'z','A'-'Z','0'-'9','%','$','_'= seq_maybe_case_word;
def  'BACKSPACE'= seq_maybe_case_backspace;

_command seq_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(SEQ_LANGUAGE_ID);
}
_command void seq_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_seq_expand_enter);
}
bool _seq_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
_command void seq_equal() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin('=');
      return;
   }
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING ) {
      keyin('=');
      return;
   }
   get_line(auto line);
   first_word := varname := rest := "";
   parse line with first_word varname rest;
   if (lowcase(first_word)!="for" || rest!="" ||varname=="") {
      keyin("=");
      return;
   }
   keyin("=");
   _first_non_blank();
   col := p_col;
   insert_line(indent_string(col-1)_word_case("next ")varname);
   up();_end_line();
}

_command seq_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
        seq_expand_space()
        ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
         typeless orig_pos;
         save_pos(orig_pos);
         left();left();
         int cfg=_clex_find(0,'g');
         autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);
         if (cfg==CFG_KEYWORD && autoCase) {
            word_pcol := 0;
            _str cw=cur_word(word_pcol);
            p_col=_text_colc(word_pcol,'I');
            _delete_text(length(cw));
            _insert_text(_word_case(cw));
            restore_pos(orig_pos);
         }
         restore_pos(orig_pos);
         VS_TAG_IDEXP_INFO idexp_info;
         tag_idexp_info_init(idexp_info);
         struct VS_TAG_RETURN_TYPE visited:[];
         typeless status=_seq_get_expression_info(false,idexp_info,visited);
         if (!status && (idexp_info.info_flags & VSAUTOCODEINFO_SABL_IS_LABEL)) {
            list_symbols();
         } else {
            restore_pos(orig_pos);
            left();_delete_text(1);
            auto_functionhelp_key();
         }
      }
   } else if (_argument=="") {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO seq_space_words:[] = {
   "begin"      => { "BEGIN ... END" },
   "if"         => { "IF ... THEN ..." },
   "else"       => { "ELSE" },
   "#define"    => { "#define" },
   "#if"        => { "#if" },
   "#ifdef"     => { "#ifdef" },
   "#elif"      => { "#elif" },
   "#undef"     => { "#undef" },
   "#else"      => { "#else" },
   "#endif"     => { "#endif" },
   "#include"   => { "#include" },
};


static const SEQ_EXPAND_WORDS= " #define #elif #else #endif #error #if #ifdef #ifndef #include #pragma #undef ";

/*
    Returns true if nothing is done
*/
bool _seq_expand_enter()
{
   int col=_seq_indent_col(0);
   indent_on_enter(0,col);
   return(false);
}
static void maybe_insert_doend(int syntax_indent,int be_style,int width,_str word,_str begin_word,int adjust_col=0,bool putCursorInsideDoBlock=false)
{
   int col=width+length(word)+2+adjust_col;
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN);
   if (p_no_space_before_paren) --col;
   if ( be_style == BESTYLE_FLAG ) {
      width += syntax_indent;
   }
   if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
      up_count := 1;
      if ( be_style & BESTYLE_FLAG ) {
         up_count++;
         insert_line(indent_string(width):+begin_word);
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) || putCursorInsideDoBlock) {
         up_count++;
         insert_line(indent_string(width+syntax_indent));
      }
      insert_line(indent_string(width):+_word_case("end;",false,begin_word));
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
static _str seq_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;

   typeless status=0;
   get_line(auto orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   if_special_case := false;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,seq_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   first_word := second_word := rest := "";
   if ( word=="") {
      // Check for ELSE IF or END; ELSE IF
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

   line=substr(line,1,length(line)-length(orig_word)):+_word_case(word);
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,"i")-1;
   orig_word=word;
   word=lowcase(word);

   doNotify := true;
   if ( word=="if" || if_special_case) {
      set_surround_mode_start_line();
      replace_line(line:+_word_case("  then",false,orig_word));
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case("begin",false,orig_word));
   } else if (word=="begin") {
      set_surround_mode_start_line();
      replace_line(_word_case(line,false,orig_word));
      insert_line(indent_string(width)_word_case("end",false,orig_word));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=="else") {
      replace_line(_word_case(line,false,orig_word));
      _end_line();++p_col;
      doNotify = (line != orig_line);
   } else if ( pos(" "word" ",SEQ_EXPAND_WORDS) ) {
      newLine := indent_string(width)word" ";
      replace_line(newLine);
      _end_line();
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
int _seq_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, seq_space_words, prefix, min_abbrev);
}
/*
  Block constructs

   FOR i=a TO b STEP z
   NEXT i
   BEGIN
   END

*/
int _seq_find_block_col(_str &block_info/* currently just block word */,bool restoreCursor,bool returnFirstNonBlank)
{
   typeless orig_pos;
   save_pos(orig_pos);
   int nesting;
   nesting=1;
   word := "";
   typeless status=search("begin|for|next",'h@-wirxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      word=lowcase(get_match_text());
      //messageNwait(word);
      switch (word) {
      case "begin":
      case "if":
      case "for":
         --nesting;
         break;
      case "end":
      case "next":
         ++nesting;
         break;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         typeless junk=0;
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
static int seq_prev_stat_col(_str &blockinfo,bool RestorePos)
{

   orig_linenum := p_line;
   orig_col := p_col;
   //FailIfNoPrecedingText=(arg(4)!="");
   //AlreadyRecursed=(arg(5)!="");
   //FailWithMinus1_IfNoTextAfterCursor=(arg(6)!="");
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   line := "";
   typeless status=0;
   save_pos(auto p);
   for (;;) {
      status=_clex_skip_blanks('-');
      if (status) {
         return(0);
      }
      get_line(line);
      _first_non_blank();
      typeless start_stat_pos;
      save_pos(start_stat_pos);
      typeless junk=0;
      blockinfo=cur_word(junk);
      col := p_col;
      seq_next_sym_same_line();
      blockinfo=gtkinfo;
      seq_next_sym_same_line();
      if (gtk=="") {
         if (RestorePos) {
            restore_pos(p);
            return(col);
         }
         restore_pos(start_stat_pos);
         return(col);
      }
      // We found a label;
      if (gtk==":") {
         save_pos(start_stat_pos);
         seq_next_sym_same_line();
         blockinfo=gtkinfo;
         if (gtk=="") {
            restore_pos(start_stat_pos);
            up();_end_line();
            continue;
         }
         restore_pos(start_stat_pos);
         search('[~ \t]','rh@');

         blockinfo=cur_word(junk);
         col=p_col;
         if (RestorePos) {
            restore_pos(p);
            return(col);
         }
         return(col);
      }
      if (RestorePos) {
         restore_pos(p);
         return(col);
      }
      restore_pos(start_stat_pos);
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
   typeless blockinfo="";
   int begin_stat_col=seq_prev_stat_col(blockinfo,true);
   if (begin_stat_col) {
      restore_pos(p);
      return(begin_stat_col);
   }
   line := "";
   get_line(line);line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   _first_non_blank();
   col := p_col;
   restore_pos(p);
   return(col);
}

/*
   This code is just here incase we get fancy
*/
int _seq_indent_col(int non_blank_col)
{
   orig_col := p_col;
   orig_linenum := p_line;
   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
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
   typeless blockinfo="";
   int begin_stat_col=seq_prev_stat_col(blockinfo,false);
   if (!begin_stat_col) {
      restore_pos(p);
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   blockinfo=lowcase(blockinfo);
   if (blockinfo=="begin") {
      restore_pos(p);
      return(begin_stat_col);
   }
   typeless status=0;
   linenum := 0;
   if (blockinfo=="if") {
      // Look for then on same line.
      search('then|$','rh@wxcs');
      if (match_length()) {
         p_col+=5;
         linenum=p_line;
         status=_clex_skip_blanks();
         if (status || p_line!=linenum) {
            restore_pos(p);
            return(begin_stat_col+syntax_indent);
         }
         restore_pos(p);
         return(begin_stat_col);
      } else {
         restore_pos(p);
         return(begin_stat_col+syntax_indent);
      }
   }
   if (blockinfo=="else") {
      // Look for then on same line.
      p_col+=5;
      linenum=p_line;
      status=_clex_skip_blanks();
      if (status || p_line!=linenum) {
         restore_pos(p);
         return(begin_stat_col+syntax_indent);
      }
      restore_pos(p);
      return(begin_stat_col);
   }
   if (blockinfo=="for") {
      restore_pos(p);
      return(begin_stat_col+syntax_indent);
   }
   if (blockinfo=="end") {
      /*
         We may need to un indent for this
         IF expr THEN
             BEGIN
             END<enter>
         ELSE
             BEGIN
             END<enter>

      */
      if(p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      typeless block_info="";
      int col=_seq_find_block_col(block_info,false,false);
      if (col) {
         block_info=lowcase(block_info);
         if (block_info=="begin" ) {
            if(p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            // Check if the previous symbol is a else or then
            seq_prev_sym();
            find_if := false;
            if (lowcase(gtkinfo)=="else") {
               find_if=true;
               seq_prev_sym();
               if (gtkinfo==";") seq_prev_sym();
               seq_prev_sym();
               if (lowcase(gtkinfo)=="end") {
                  _seq_find_block_col(block_info,false,false);
               }
            } else if (lowcase(gtkinfo)=="then") {
               find_if=true;
            }
            if (find_if) {
               status=search("IF",'h-@rwixcs');
               if (!status) {

                  _first_non_blank();
                  col=p_col;
                  restore_pos(p);
                  return(col);
               }
            }
         }
      }
   } else {
      up();_end_line();
      // Check if we are in a dangling if or else clause
      int begin_stat_col2=seq_prev_stat_col(blockinfo,false);
      if (blockinfo=="else" || blockinfo=="if") {
         restore_pos(p);
         return(begin_stat_col2);
      }
   }
   restore_pos(p);
   return(begin_stat_col);

}
int seq_smartpaste(bool char_cbtype,int first_col)
{
   typeless comment_col="";
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
   typeless status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!="") || (!status && comment_col!="" && p_col!=comment_col)) {
      return(0);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   typeless junk=0;
   typeless enter_col=0;
   word := lowcase(cur_word(junk));
   ignore_column1 := false;
   if (!status && (word=="next" || word=="end")) {
      save_pos(auto p2);
      up();_end_line();
      typeless block_info="";
      enter_col=_seq_find_block_col(block_info,true,true);
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
      enter_col=_seq_find_block_col(block_info,true,true);
      restore_pos(p2);
      if (enter_col && lowcase(block_info)!='if') {
         enter_col+=syntax_indent;
      }
      if (!enter_col) {
         enter_col='';
      }
      _begin_select;get_line first_line;up();*/
   } else {
      //ignore_column1=true;
      _begin_select();get_line(first_line);up();
      _end_line();
      enter_col=seq_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && ignore_column1) || enter_col=="" /*||
      (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))*/) {
      return(0);
   }
   return(enter_col);
}

static _str seq_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      seq_enter_col2(enter_col) ) {
      return("");
   }
   return(enter_col);
}


static bool seq_enter_col2(int &enter_col)
{
   enter_col=_seq_indent_col(0);
   return(false);
}

//Returns 0 if the letter wasn't upcased, otherwise 1
_command void seq_maybe_case_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _lang_maybe_case_word(gWord,gWordEndOffset);
}

_command void seq_maybe_case_backspace() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _lang_maybe_case_backspace(gWord,gWordEndOffset);
}


defeventtab _seq_extform;

void _lower.lbutton_up()
{
   ctlautocase.p_enabled=ctlnone.p_value==0;
}
void _upper.lbutton_up()
{
   ctlautocase.p_enabled=ctlnone.p_value==0;
}
void _capitalize.lbutton_up()
{
   ctlautocase.p_enabled=ctlnone.p_value==0;
}
void ctlnone.lbutton_up()
{
   ctlautocase.p_enabled=ctlnone.p_value==0;
}
_ok.on_create()
{
   ext := "";
   parse p_active_form.p_name with "_" ext "_extform";
   
   scase := LanguageSettings.getKeywordCase(ext);
   switch (scase) {
   case -1:ctlnone.p_value = 1;break;
   case 0:_lower.p_value = 1;break;
   case 1:_upper.p_value = 1;break;
   case 2:_capitalize.p_value = 1;break;
   }
   autoCase := LanguageSettings.getAutoCaseKeywords(ext);
   ctlautocase.p_value=(int)autoCase;
}
_ok.lbutton_up()
{
   lang := "";
   parse p_active_form.p_name with "_" lang "_extform";

   kw_case := 0;
   if (_lower.p_value) {//THESE CONTROLS
      kw_case= 0;
   }else if(_upper.p_value) {
      kw_case= 1;
   } else if (_capitalize.p_value) {
      kw_case= 2;
   }else{
      kw_case= -1;
   }

   LanguageSettings.setKeywordCase(lang, kw_case);
   
   LanguageSettings.setAutoCaseKeywords(lang,ctlautocase.p_value!=0);

   p_active_form._delete_window(0);
}

int _seq_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "seq", "sabl", 
                                "SABL Libraries",
                                "", false, withRefs, useThread, forceRebuild);
}

static int _seq_get_proc_offset2(int &FunctionNameOffset,bool StartFromCursor)
{
   if (StartFromCursor) {
      search("then|else|^",'rh@-wxcs');
      if (match_length()) {
         p_col+=5;
         if (p_col>_text_colc()) {
            FunctionNameOffset=_nrseek();
            return(0);
         }
         search('[~ \t]|$','rh@');
         FunctionNameOffset=_nrseek();
         return(0);
      }
   }
   line := "";
   get_line(line);
   _first_non_blank();
   typeless start_stat_pos;
   save_pos(start_stat_pos);
   FunctionNameOffset=_nrseek();
   seq_next_sym_same_line();
   typeless blockinfo=gtkinfo;
   seq_next_sym_same_line();
   if (gtk=="") {
      _nrseek(FunctionNameOffset);
      return(0);
   }
   // We found a label;
   if (gtk==":") {
      save_pos(start_stat_pos);
      seq_next_sym_same_line();
      if (gtk=="") {
         return(1);
      }
      restore_pos(start_stat_pos);
      search('[~ \t]','rh@');

      FunctionNameOffset=_nrseek();
      return(0);
   }
   _nrseek(FunctionNameOffset);
   return(0);
}
static int _seq_get_proc_offset(_str &tagNamePrefix,int &FunctionNameOffset,bool &doPrefixMatch,bool StartFromCursor=false,bool AllowAssignmentStatement=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   save_pos(auto p);
   typeless offset=_nrseek();
   if(_seq_get_proc_offset2(FunctionNameOffset,StartFromCursor)){
      restore_pos(p);
      return(1);
   }
   allBlanks := (offset <= FunctionNameOffset || get_text(offset-FunctionNameOffset)=="");
   
   // See if we have a tag by this name
   tagfilename := absolute(_tagfiles_path():+"seq":+TAG_FILE_EXT);
   int status=tag_read_db(tagfilename);
   if (status < 0) {
      restore_pos(p);
      return(status);
   }
   // Find the longest prefix match
   tagNamePrefix="";
   doPrefixMatch=true;
   tag_init_tag_browse_info(auto cm);
   new_tag_name := "";
outer:
   for (;;) {
      seq_next_sym_same_line();
      if (gtkinfo=="") {
         break;
      }
      if (tagNamePrefix=="") {
         new_tag_name=gtkinfo;
      } else {
         new_tag_name=tagNamePrefix" "gtkinfo;
      }
      status=tag_find_prefix(new_tag_name);
      for (;;) {
         if (status) {
            //doPrefixMatch=false;
            tag_reset_find_tag();
            break outer;
         }
         tag_get_tag_browse_info(cm);
         if (cm.type_name=="proc" && substr(cm.member_name,length(new_tag_name)+1,1):==" ") {
            break;
         }
         status=tag_next_prefix(new_tag_name);
      }
      tag_reset_find_tag();
      tagNamePrefix=new_tag_name;
   }
   if (tagNamePrefix=="") {
      restore_pos(p);
      tag_close_db(null,true);
      if (AllowAssignmentStatement) {
         if(allBlanks) {
            restore_pos(p);FunctionNameOffset=_nrseek();
         }
         //_nrseek(FunctionNameOffset);
         tagNamePrefix=new_tag_name;
         return(0);
      }
      return(1);
   }
   _nrseek(FunctionNameOffset);
   // Check for space or tab following name
   if (get_text(1,FunctionNameOffset+length(tagNamePrefix))=="") {
      //doPrefixMatch=false;
   }
   tag_close_db(null,true);
   return(0);
}

/*
   PARAMETERS
      OperatorTyped     When true, user has just typed comma or
                        open paren.

                        Example
                           myfun(<Cursor Here>
                             OR
                           myproc ,

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
int _seq_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   errorArgs._makeempty();
   flags=0;
   //if (cursorInsideArgumentList || OperatorTyped)
   typeless orig_pos;
   save_pos(orig_pos);
   orig_col := p_col;
   orig_line := p_line;
   search_string := "[()]|^";
   typeless status=search(search_string,'-rh@');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }

   word := "";
   typeless p=0;
   typeless junk=0;
   typeless p1,p2,p3,p4;
   ch := "";
   cfg := 0;
   ArgumentStartOffset= -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) break;
      if (!match_length()) {
         break;
      }
      cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      ch=get_text();
      //say("CCH="ch);
      if (ch=="(") {
         save_pos(p);
         if(p_col==1){up();_end_line();} else {left();}
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         ch=get_text();
         word=cur_word(junk);
         restore_pos(p);
         if (pos("["word_chars"]",ch,1,'r')) {
            /*if (pos(' 'word' ',C_NOT_FUNCTION_WORDS)) {
               if (OperatorTyped && ArgumentStartOffset== -1) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               break;
            }
            */

            ArgumentStartOffset=(int)point('s')+1;
         } else {
            /*
               OperatorTyped==true
                   Avoid giving help when have
                   myproc(....4+( <CursorHere>

            */
            if (OperatorTyped && ArgumentStartOffset== -1 ){
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
         }
      } else if (ch==')') {
         status=_find_matching_paren(MAXINT,true);
         if (status) {
            restore_pos(orig_pos);
            return(1);
         }
         save_pos(p);
         if(p_col==1){up();_end_line();} else {left();}
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         word=cur_word(junk);
         /*if (pos(' 'word' ',' if while catch switch ')) {
            break;
         }
         */
         restore_pos(p);
      } else  {
         break;
      }
      status=repeat_search();
   }
   tagNamePrefix := "";
   doPrefixMatch := false;
   if (ArgumentStartOffset<0) {
      restore_pos(orig_pos);
      if(_seq_get_proc_offset(tagNamePrefix,FunctionNameOffset,doPrefixMatch,true)) {
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      ArgumentStartOffset=FunctionNameOffset;
      return(0);
   } else {
      if(!_seq_get_proc_offset(tagNamePrefix,FunctionNameOffset,doPrefixMatch)) {
         ArgumentStartOffset=FunctionNameOffset;
         return(0);
      }
   }
   goto_point(ArgumentStartOffset);

   // Cursor is after , or (
   left();  // cursor to , or (
   left();  // cursor to before , or (
   search('[~ \t]|^','-rh@');  // Search for last char of ID
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   int end_col=p_col+1;
   search('[~'word_chars']\c|^\c','-rh@');
   _str lastid=_expand_tabsc(p_col,end_col-p_col);
   FunctionNameOffset=(int)point('s');
   /*if (pos(' 'lastid' ',C_NOT_FUNCTION_WORDS)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   */
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
int _seq_fcthelp_get(_str (&errorArgs)[],
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
   //say("_seq_fcthelp_get");
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
   _str cursor_offset=point('s');
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   goto_point(FunctionNameStartOffset);
   // enum, struct class
   //found_function_pointer:=false;
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   stack_top := 0;
   ParamNum_stack[stack_top]=0;
   nesting := 0;
   bool doPrefixMatch;
   int procNameOffset;
   _str procNamePrefix;
   int proc_lastidstart_col;
   if (_seq_get_proc_offset(procNamePrefix,procNameOffset,doPrefixMatch,true) ||
       procNameOffset<FunctionNameStartOffset) {
      procNamePrefix="";
      procNameOffset= -1;
   } else {
      ++stack_top;
      ParamNum_stack[stack_top]=1;
      offset_stack[stack_top]=(int)point('s');
      proc_lastidstart_col=p_col;
   }
   search_string := "[,()[]|goto|gosub|count|$";
   status := search(search_string,'irh@');
   linenum := p_line;
   for (;;) {
      if (status) {
         break;
      }
      if (cursor_offset<=point('s') || linenum!=p_line) {
         break;
      }
      if (!match_length()) {
         p_col=_text_colc(_line_length(true),'I')+1;
         if (cursor_offset<=point('s')) {
            break;
         }
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      _str cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      ch := get_text();
      //say('ch='ch' seek='_nrseek());
      if (ch=="[" ) {
         status=_find_matching_paren(MAXINT,true);
         ++p_col;
         status=search(search_string,'irh@');
         continue;
      } else if (ch==",") {
         ++ParamNum_stack[stack_top];
         status=repeat_search();
         continue;
      } else if (ch==")") {
         --stack_top;
         if (stack_top<=0 /*&& (!found_function_pointer && stack_top<0)*/) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         //found_function_pointer = false;
         status=repeat_search();
         continue;
      } else if (ch=="(") {
         if (procNameOffset>=0) {
            // Determine if this is a new function
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            save_pos(auto p2);
            left();
            seq_prev_sym_same_line();
            if (gtkinfo:!="") {
               if (p_col>_text_colc()) {
                  down();p_col=1;
               } else {
                  right();
               }
            }
            int offset=_nrseek();
            restore_pos(p2);
            restore_search(s1,s2,s3,s4,s5);
            if (offset<=procNameOffset || gtkinfo=="count") {
               status=_find_matching_paren(MAXINT,true);
               ++p_col;
               status=search(search_string,'irh@');
               continue;
            }
         }

         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');
         /*if (get_text(2)=='(*') {
            found_function_pointer = true;
         } */
         status=repeat_search();
         continue;
      } else {
         int junk;
         word := lowcase(cur_word(junk));
         if (word=="goto" && stack_top==1 && procNameOffset>=0 &&
             !pos("goto",procNamePrefix,1,'ri')) {
            ++ParamNum_stack[stack_top];
         } else if (word=="gosub" && stack_top==1 && procNameOffset>=0 &&
             !pos("gosub",procNamePrefix,1,'ri')) {
            ++ParamNum_stack[stack_top];
         } else if (word=="count" && stack_top==1 && procNameOffset>=0) {
            ++ParamNum_stack[stack_top];
         }

      }
      status=repeat_search();
   }
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]+1);
      // If we need to find a proc
      if (offset_stack[stack_top]==procNameOffset) {
         idexp_info.prefixexp="";
         idexp_info.lastid=procNamePrefix;
         idexp_info.lastidstart_offset=procNameOffset;
         idexp_info.lastidstart_col=proc_lastidstart_col;
         idexp_info.otherinfo="";
         idexp_info.info_flags=VSAUTOCODEINFO_SABL_IS_PROC;
         if (!doPrefixMatch) {
            idexp_info.info_flags|=VSAUTOCODEINFO_SABL_EXACT_MATCH;
         }
         status=0;
      } else {
         status=_seq_get_expression_info(true,idexp_info,visited,depth+1);
      }
      idexp_info.errorArgs[1] = idexp_info.lastid;

      if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_seq_fcthelp_get", depth);
         isay(depth, "_seq_fcthelp_get: status="status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         if (ParamNum<=0) ParamNum=1;
         set_scroll_pos(orig_left_edge,p_col);
         // check if anything has changed

         if (prev_prefixexp :== idexp_info.prefixexp &&
            gLastContext_FunctionName :== idexp_info.lastid &&
            gLastContext_FunctionOffset :== idexp_info.lastidstart_offset &&
            prev_otherinfo :== idexp_info.otherinfo &&
            prev_info_flags == idexp_info.info_flags &&
            prev_ParamNum   == ParamNum) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }
         // lastid is name of function or proc
         // (info_flags & VSAUTOCODEINFO_SABL_IS_FUNC) indicates function
         // (info_flags & VSAUTOCODEINFO_SABL_IS_PROC) indicates procedure

         bool isproc;
         _str match_list[];
         match_list._makeempty();
         if (offset_stack[stack_top]==procNameOffset) {
            isproc=true;
            if (doPrefixMatch) {
               status=tag_find_prefix(procNamePrefix);
            } else {
               status=tag_find_equal(procNamePrefix);
            }
            count := 0;
            for (;;) {
               if (status) {
                  break;
               }
               tag_get_tag_browse_info(auto tag_cm);
               if (tag_cm.type_name=="proc") {
                  ++count;
                  tag_cm.return_type = "";
                  taginfo := tag_compose_tag_browse_info(tag_cm);
                  match_list[match_list._length()] = tag_cm.member_name"\t"tag_cm.type_name"\t"tag_cm.arguments"\t"tag_cm.file_name"\t"tag_cm.line_no"\t"taginfo;
               }
               if (doPrefixMatch) {
                  status=tag_next_prefix(procNamePrefix);
               } else {
                  status=tag_next_equal();
               }
            }
            tag_reset_find_tag();

         } else {
            isproc=false;
            tag_clear_matches();
            num_matches := 0;

            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
            typeless tag_files = tags_filenamea(p_LangId);
            tag_list_symbols_in_context(idexp_info.lastid, "", 
                                        0, 0, tag_files, "",
                                        num_matches, def_tag_max_function_help_protos,
                                        SE_TAG_FILTER_ANY_PROCEDURE, 
                                        SE_TAG_CONTEXT_ALLOW_LOCALS,
                                        true, p_EmbeddedCaseSensitive, 
                                        visited, depth+1);

            for (i:=1; i<=num_matches; ++i) {
               tag_get_match_browse_info(i, auto match_cm);
               match_cm.member_name = idexp_info.lastid;
               if (match_cm.type_name:!="func") {
                  continue;
               }
               //match_list[match_list._length()] = proc_name "\t" signature "\t" ;
               taginfo := tag_compose_tag_browse_info(match_cm);
               match_list[match_list._length()] = match_cm.member_name"\t"match_cm.type_name"\t"match_cm.arguments"\t"match_cm.file_name"\t"match_cm.line_no"\t"taginfo;
            }
         }

         //_message_box('Nofmatches='match_list._length());

         // get rid of any duplicate entries
         match_list._sort();
         _aremove_duplicates(match_list, true);

         // translate functions into struct needed by function help
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = idexp_info.lastid;
            ArgSep_re := "";

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            int i,k;
            for (i=0; i<match_list._length(); i++) {
               k = FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               tag_autocode_arg_info_init(FunctionHelp_list[k]);

               parse match_list[i] with auto match_tag_name "\t" auto match_type_name "\t" auto signature "\t" auto match_file_name "\t" auto match_line_no "\t" auto match_taginfo;
               if (isproc) {
                  FunctionHelp_list[k].prototype= match_tag_name" "signature;
               } else {
                  FunctionHelp_list[k].prototype= match_tag_name"("signature")";
               }

               if (isproc) {
                  switch (lowcase(match_tag_name)) {
                  case "on":
                  case "on countdown":
                     ArgSep_re="gosub|goto";
                     break;
                  case "waituntil":
                     ArgSep_re="count";
                     break;
                  }
               }
               base_length := length(match_tag_name)+1;
               FunctionHelp_list[k].argstart[0]=0;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum= -1;
               FunctionHelp_list[k].tagList[0].comment_flags=0;
               FunctionHelp_list[k].tagList[0].comments=null;
               FunctionHelp_list[k].tagList[0].filename=match_file_name;
               FunctionHelp_list[k].tagList[0].linenum=(int)match_line_no;
               FunctionHelp_list[k].tagList[0].taginfo=match_taginfo;

               //++base_length;
               // parse signature and map out argument ranges
               arg_pos := 0;
               ArgumentPosition := 0;
               _str argument = _pro_next_arg(signature, arg_pos, 1,ArgSep_re);
               while (argument != "") {
                  //say("argument="argument);
                  int j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  if (pos('[''"]',argument,1,'r')) {
                     // Positional argument
                     ++ArgumentPosition;
                     if (ArgumentPosition==ParamNum) {
                        FunctionHelp_list[k].ParamNum=j;
                     }
                  } else {
                     if (pos("...",argument)) {
                        if (ParamNum>ArgumentPosition) {
                           FunctionHelp_list[k].ParamNum=j;
                        }
                     } else {
                        // Positional argument
                        ++ArgumentPosition;
                        //say('ArgPos='ArgumentPosition' ParamNum='ParamNum);
                        if (ArgumentPosition==ParamNum) {
                           FunctionHelp_list[k].ParamNum=j;
                        }
                     }
                  }
                  argument = _pro_next_arg(signature, arg_pos, 0,ArgSep_re);
               }
               //say('[k].ParamNum='FunctionHelp_list[k].ParamNum);
               /*if (ParamNum>=FunctionHelp_list[k].argstart._length() &&
                   pos('...',last_argument) && !pos('[''"]',last_argument,1,'r')) {
                  FunctionHelp_list[k].ParamNum= VSAUTOCODEARGFLAG_VAR_ARGS;
               } */
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               //if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=true;
               //}
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

static bool seq_need_label(int seekpos)
{
   save_pos(auto p);
   _nrseek(seekpos);
   seq_prev_sym_same_line();
   gtkinfo=lowcase(gtkinfo);
   if (gtkinfo=="goto" || gtkinfo=="gosub") {
      restore_pos(p);
      return(true);
   }
   restore_pos(p);
   lastid := "";
   lastidstart_offset := 0;
   doPrefixMatch := false;
   if (_seq_get_proc_offset(lastid,lastidstart_offset,doPrefixMatch)) {
      restore_pos(p);
      return(false);
   }
   if(lowcase(lastid)!="on") {
      restore_pos(p);
      return(false);
   }
   restore_pos(p);
   _begin_line();
   orig_line := p_line;
   typeless status=search('(goto|gosub)\c','irh@ck');
   if (status || p_line!=orig_line) {
      restore_pos(p);
      return(false);
   }
   if (seekpos>_nrseek()) {
      restore_pos(p);
      return(true);
   }
   restore_pos(p);

   return(false);
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
int _seq_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
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
   idexp_info.prefixexp="";
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      left();
      ch := get_text();
      switch (ch) {
      case " ":
         if (seq_need_label(_nrseek()-1)) {
            idexp_info.info_flags=VSAUTOCODEINFO_SABL_LASTID_FOLLOWED_BY_SPACE|VSAUTOCODEINFO_SABL_IS_LABEL|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            idexp_info.lastidstart_col=p_col;
            restore_pos(orig_pos);
            return(0);
         }
         bool doPrefixMatch;
         if (_seq_get_proc_offset(idexp_info.lastid,idexp_info.lastidstart_offset,doPrefixMatch,true)) {
            restore_pos(orig_pos);
            return(1);
         }
         if (_nrseek()>idexp_info.lastidstart_offset+length(idexp_info.lastid)+1) {
            restore_pos(orig_pos);
            return(1);
         }
         idexp_info.info_flags=VSAUTOCODEINFO_SABL_LASTID_FOLLOWED_BY_SPACE|VSAUTOCODEINFO_SABL_IS_PROC|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         idexp_info.lastidstart_col=p_col;
         restore_pos(orig_pos);
         return(0);
      case "(":
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         search('[~ \t]|^','-rh@');
         // maybe there was a function pointer expression
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
         /*if (pos(' 'lastid' ',C_NOT_FUNCTION_WORDS)) {
            restore_pos(orig_pos);
            return(1);
         }
         */
         break;
      default:
         restore_pos(orig_pos);
         return(1);
      }
   } else {
      int orig_seek=_nrseek();
      bool doPrefixMatch;
      if (_seq_get_proc_offset(idexp_info.lastid,idexp_info.lastidstart_offset,doPrefixMatch,true,true)) {
         restore_pos(orig_pos);
         get_line(auto line);
         if (line=="") {
            idexp_info.lastid="";
            idexp_info.lastidstart_offset=_nrseek();
            idexp_info.lastidstart_col=p_col;
            idexp_info.info_flags=VSAUTOCODEINFO_SABL_IS_PROC|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            return(0);
         }
         //return(1);
      } else {
         if (orig_seek<=idexp_info.lastidstart_offset+length(idexp_info.lastid) || idexp_info.lastid=="") {
            idexp_info.info_flags=VSAUTOCODEINFO_SABL_LASTID_FOLLOWED_BY_SPACE|VSAUTOCODEINFO_SABL_IS_PROC|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            if (length(idexp_info.lastid)) {
               _nrseek(idexp_info.lastidstart_offset);
            }
            idexp_info.lastidstart_col=p_col;
            restore_pos(orig_pos);
            return(0);
         }
      }
      restore_pos(orig_pos);
      // IF we are not on an id character.
      ch := get_text();
      done := 0;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         left();
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            if (get_text()=="(") {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            }
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            done=1;
         }
      }
      if(!done) {
         search('[~'word_chars']|$','rh@');
         end_col := p_col;
         // Check if this is a function call
         search('[~ \t]|$','rh@');
         if (get_text()=="(") {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
      }
   }
   if (seq_need_label(idexp_info.lastidstart_offset-1)) {
      idexp_info.info_flags=VSAUTOCODEINFO_SABL_LASTID_FOLLOWED_BY_SPACE|VSAUTOCODEINFO_SABL_IS_LABEL|VSAUTOCODEINFO_DO_FUNCTION_HELP;
      idexp_info.lastidstart_col=p_col;
      restore_pos(orig_pos);
      return(0);
   }
   idexp_info.info_flags|=VSAUTOCODEINFO_SABL_IS_FUNC;
   restore_pos(orig_pos);
   return(0);
}

static void _seq_insert_text(_str caption,_str category_caption)
{
   if (category_caption==get_message(VSRC_CODEHELP_TITLE_DEFINES)) {
      _insert_text(caption);
      return;
   }
   _autocase_insert_text(caption,false);
}

int _seq_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   // id followed by paren, then limit search to functions
   tag_type := SE_TAG_TYPE_FUNCTION;
   // tag_type is SE_TAG_TYPE_FUNCTION, we really
   // want vars,defines, and functions
   if (info_flags & VSAUTOCODEINFO_SABL_IS_PROC) {
      tag_type=SE_TAG_TYPE_PROC;
      // tag_type is SE_TAG_TYPE_PROC, we really
      // want procs,and vars
   } else if (info_flags & VSAUTOCODEINFO_SABL_IS_LABEL) {
      tag_type=SE_TAG_TYPE_LABEL;
   }

   // get the tag file list
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   if (context_flags & SE_TAG_CONTEXT_NO_GLOBALS) {
      errorArgs[1] = lastid;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   if (tag_type==SE_TAG_TYPE_LABEL) {
      tag_list_globals_of_type( 0, 0, 
                                tag_files,
                                tag_type,
                                0, 0,
                                num_matches, max_matches,
                                visited, depth+1 );
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   if (tag_type==SE_TAG_TYPE_PROC) {
      tag_list_globals_of_type( 0, 0,
                                tag_files,
                                SE_TAG_TYPE_PROC,
                                0,0,
                                num_matches, max_matches,
                                visited, depth+1 );
      tag_list_globals_of_type( 0, 0,
                                tag_files,
                                SE_TAG_TYPE_VAR,
                                0,0,
                                num_matches, max_matches,
                                visited, depth+1 );
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   tag_list_globals_of_type( 0, 0,
                             tag_files,
                             SE_TAG_TYPE_FUNCTION,
                             0, 0,
                             num_matches, max_matches,
                             visited, depth+1 );

   tag_list_globals_of_type( 0, 0,
                             tag_files,
                             SE_TAG_TYPE_VAR,
                             0,0,
                             num_matches, max_matches,
                             visited, depth+1 );

   tag_list_globals_of_type( 0, 0,
                             tag_files,
                             SE_TAG_TYPE_DEFINE,
                             0, 0,
                             num_matches, max_matches,
                             visited, depth+1 );

   errorArgs[1] = lastid;
   return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
}

static bool ghashtab:[];
int seq_proc_search(var proc_name, int find_first)
{
   typeless status=0;
   name := "";
   type := "";
   if ( find_first ) {
      ghashtab._makeempty();
      word_chars := _clex_identifier_chars();
      if (proc_name!="") {
         parse proc_name with name "(" type ")";
         if (type=="define") {
            name='\#[ \t]*define[ \t]+{#0['word_chars']#}';
         } else if (type=="var") {
            name='(^|[~'word_chars']){#0['_escape_re_chars(name)']#[ \t]*=}';
         } else {
            name='(^|[~'word_chars']){#0'_escape_re_chars(name)'[ \t]*\:}';
         }
      } else {
         name='(^|[~'word_chars']){#0['word_chars']#[ \t]*[:=]}|{#0\#[ \t]*define[ \t]+['word_chars']#}';
      }
      status=search(name, '@rhixcs');
      //fsay(name);
      //say('******************* 'status);
   } else {
      status=repeat_search();
   }
   ch := "";
   lname := "";
   for (;;) {
      if ( status ) {
         return(status);
      }
      name=get_match_text(0);
      if (substr(name,1,1)=="#") {
         type="define";
         parse name with "define" name "(";
         name=strip(name);
      } else {
         parse name with name '[:=]','r' +0 ch;
         name=strip(name);
         if (ch:==":") {
            type="label";
         } else {
            type="var";
            lname=lowcase(name);
            if (ghashtab._indexin(lname)) {
               status=repeat_search();
               continue;
            }
            col := p_col;
            left();
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            status=search('[~ \t]|^','-@rh');
            if (match_length()) {
               if (get_text()!=":") {
                  if(_clex_find(0,'g')!=CFG_KEYWORD ) {
                     p_col=col;
                     restore_search(s1,s2,s3,s4,s5);
                     status=repeat_search();
                     continue;
                  }
                  typeless junk=0;
                  word := lowcase(cur_word(junk));
                  if (word!="for" && word!="then" && word!="else" && word!="let") {
                     p_col=col;
                     restore_search(s1,s2,s3,s4,s5);
                     status=repeat_search();
                     continue;
                  }
               }
            }
            restore_search(s1,s2,s3,s4,s5);
            p_col=col;
            ghashtab:[lname]=true;
         }
      }
      tag_init_tag_browse_info(auto cm, name, "", type);
      temp_proc_name := tag_compose_tag_browse_info(cm);
      if (proc_name=="") {
         proc_name=temp_proc_name;
         return(0);
      }
      find_name := "";
      find_type := "";
      parse proc_name with find_name"("find_type")";
      if ((find_type:==type || find_type=="") && strieq(find_name,name)) {
         return(0);
      }
      status=repeat_search();
   }
}

_form _seq_extform {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption="SABL Options";
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=2880;
   p_width=3210;
   p_x=0;
   p_y=0;
   _frame frame2 {
      p_backcolor=0x80000005;
      p_caption="Key&word case";
      p_clip_controls=true;
      p_forecolor=0x80000008;
      p_height=2100;
      p_tab_index=3;
      p_width=2925;
      p_x=120;
      p_y=105;
      _radio_button _lower {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption="Lower case";
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=1;
         p_tab_stop=true;
         p_value=1;
         p_width=2400;
         p_x=240;
         p_y=336;
      }
      _radio_button _upper {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption="Upper case";
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=2;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=672;
      }
      _radio_button _capitalize {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption="Capitalize first letter";
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=3;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=1008;
         p_eventtab=_plsql_extform._capitalize;
      }
      _radio_button ctlnone {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption="None";
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=4;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=240;
         p_y=1335;
         p_eventtab=_plsql_extform.ctlnone;
      }
      _check_box ctlautocase {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption="&Auto case keywords";
         p_forecolor=0x80000008;
         p_height=360;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=5;
         p_tab_stop=true;
         p_value=0;
         p_width=2400;
         p_x=255;
         p_y=1650;
      }
   }
   _command_button _ok {
      p_cancel=false;
      p_caption="OK";
      p_default=true;
      p_height=372;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=900;
      p_x=120;
      p_y=2355;
      p_eventtab=_plsql_extform._ok;
   }
   _command_button  {
      p_cancel=true;
      p_caption="&Cancel";
      p_default=false;
      p_height=372;
      p_tab_index=8;
      p_tab_stop=true;
      p_width=900;
      p_x=1134;
      p_y=2355;
   }
   _command_button  {
      p_cancel=false;
      p_caption="&Help";
      p_default=false;
      p_height=372;
      p_tab_index=9;
      p_tab_stop=true;
      p_width=900;
      p_x=2139;
      p_y=2355;
   }
}

