/*
  This Progress 4GL support module provides the following
  features:
    * SmartPaste(TM)
    * Syntax expansion
    * Syntax indenting
    * Auto keyword case
    * Selective display on procedures

  To install this macro, use the Load module
  dialog box ("Macro", "Load Module...").
*/
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "se/lang/api/LanguageSettings.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "slickc.e"
#import "adaptiveformatting.e"
#import "cutil.e"
#import "seek.e"
#import "beautifier.e"
#import "alias.e"
#import "clipbd.e"
#import "alllanguages.e"
#import "setupext.e"
#import "pmatch.e"
#import "surround.e"
#import "c.e"
#endregion

using se.lang.api.LanguageSettings;

static const IDENTIFIER_CHARS ='a-zA-Z_-0-9#$%&';
static const PROCEDURE_RE= 'proce(d(u(r(e|)|)|)|)';

//bool def_progress4gl_smartpaste=true;
//bool def_progress4gl_autocase=true;

static int gWordEndOffset=-1;
static _str gWord;

static const TK_ID=1;
//#define TK_NUMBER 1
//#define TK_STRING 2
static _str gtkinfo;
static _str gtk;

#if 0
defeventtab progress4gl_keys;
def ':'=progress4gl_colon;
def '.'=progress4gl_period;
def  ' '= progress4gl_space;
def  'ENTER'= progress4gl_enter;
def  'a'-'z','A'-'Z','0'-'9','-','#','$','%','&'= progress4gl_maybe_case_word;
def  'BACKSPACE'= progress4gl_maybe_case_backspace;
#endif

bool _progress4gl_supports_insert_begin_end_immediately() {
   return true;
}
static _str progress4gl_next_sym(bool getword=false)
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   ch:=get_text();
   if (ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      status:=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(progress4gl_next_sym());
   }
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col:=p_col;
      start_line:=p_line;
      status:=_clex_find(STRING_CLEXFLAG,'n');
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
      start_col:=p_col;
      search('[ \t]|$','r@');
      gtk:=gtkinfo=ch;
      gtk=TK_ID;  // This really picks up a word and not and id
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   if (pos('['_clex_identifier_chars()']',ch,1,'r')) {
      start_col:=p_col;
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
      search('[~'p_word_chars']|$','@r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str progress4gl_prev_sym_same_line()
{
   //messageNwait('h0 gtk='gtk);
   /*if (gtk!='(' && gtk!='::') {
      return(progress4gl_prev_sym());
   } */
   orig_linenum:=p_line;
   result:=progress4gl_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      //messageNwait('h2');
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}
static _str progress4gl_prev_sym(bool getword=false)
{
   ch:=get_text();
   if (ch=="\n" || ch=="\r" || ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      status:=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(progress4gl_prev_sym());
   }
   if (pos('['p_word_chars']',ch,1,'r')) {
      end_col:=p_col+1;
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
         search('[~'p_word_chars']\c|^\c','@r-');
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
      end_col:=p_col;
      search('[ \t]|^','-r@');
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
   gtk=gtkinfo=ch;
   return(gtk);
}

/*_command void progress4gl_set_extensions()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON) {
   _CreateExtension('i', 'progress4gl');
} */
_command void progress4gl_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('p');
}
_command void progress4gl_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   generic_enter_handler(progress4gl_expand_enter);
   /*parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_case .;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
        _in_comment(1) ||
        progress4gl_expand_enter(p_SyntaxIndent,expand,be_style,indent_case)
        ) {
      call_root_key(ENTER);
   } else if (_argument=='') {
      _undo('S');
   } */

}
_command void progress4gl_period() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin(last_event());
      return;
   }
   //parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_case .;

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   //syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);


   // check if the word at the cursor is end
   get_line(auto line);
   cfg:=_clex_find(0,'g');
   line=lowcase(line);
   parse line with auto first_word auto second_word;second_word=lowcase(second_word);
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || 
       !(first_word=='end' && 
          (second_word=='' || second_word=='function' || second_word=='procedure' 
           || second_word=='catch' || second_word=='finally' || second_word=='triggers' 
           || second_word=='compares' || second_word=='case' || second_word=='class' 
           || second_word=='method' || second_word=='constructor' || second_word=='destructor'
           || second_word=='get' || second_word=='set'
           || second_word=='enum'|| second_word=='interface'
          ) 
        )
      ) {
      keyin(last_event());
      return;
   }
   save_pos(auto p);
   up();_end_line();
   col:=_progress4gl_find_block_col(auto block_info,false,false);
   if (col) {
      _get_doend_indent_col(col);
   }
   restore_pos(p);
   if (!col) {
      keyin(last_event());
      return;
   }
   if (second_word!='') {
      replace_line(indent_string(col-1)_word_case('end')' '_word_case(second_word)'.');
   } else {
      replace_line(indent_string(col-1)_word_case('end.'));
   }
   _end_line();
}
_command void progress4gl_colon() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin(last_event());
      return;
   }
   //parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_case .;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   // check if the word at the cursor is end
   save_pos(auto p);
   progress4gl_prev_sym_same_line();
   tkinfo1:=lowcase(gtkinfo);
   restore_pos(p);
   cfg:=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || (tkinfo1!='do' && tkinfo1!='repeat' && tkinfo1!='triggers')) {
      keyin(last_event());
      return;
   }
   get_line(auto line);line=lowcase(line);
   prev_word();
   if ((line=='do' || line=='repeat' || line=='triggers') && !(be_style==BES_BEGIN_END_STYLE_3)) {
      save_pos(auto p3);
      col:=_get_doend_indent_col(auto end_col,true);
      restore_pos(p3);
      replace_line(indent_string(end_col-1)_word_case(tkinfo1));
      _end_line();
      save_pos(p);
   }
   _get_doend_indent_col(auto end_col);
   restore_pos(p);
   keyin(last_event());
   _first_non_blank();
   insert_line(indent_string(end_col-1)_word_case('end.'));
   up();_end_line();
   return;
}

static _str _clex_cur_keyword(int &start_col)
{
   save_pos(auto p);
   orig_line:=p_line;
   _clex_find(KEYWORD_CLEXFLAG,'n-');
   if (p_line!=orig_line) {
      start_col=1;
   } else {
      start_col=p_col;
   }
   restore_pos(p);
   status:=_clex_find(KEYWORD_CLEXFLAG,'n');
   if (status) {
      _end_line();
   } else if(p_line!=orig_line) {
      up();_end_line();
   }
   end_col:=p_col;
   restore_pos(p);
   return(_expand_tabsc(start_col,end_col-start_col));
}
_command progress4gl_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   was_space:=(last_event():==' ');
   //parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_case .;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   if ( command_state() || ! expand || p_SyntaxIndent<0 ||
      _in_comment() ||
        progress4gl_expand_space()
        ) {
      if ( was_space ) {
         if ( command_state() ) {
            call_root_key(' ');
         } else {
            keyin(' ');
            save_pos(auto orig_pos);
            left();left();
            cfg:=_clex_find(0,'g');
            if (cfg==CFG_KEYWORD && LanguageSettings.getAutoCaseKeywords(p_LangId) &&
                p_EmbeddedLexerName=="") {
               cw:=_clex_cur_keyword(auto word_col);
               p_col=word_col;
               _delete_text(length(cw));
               _insert_text(_word_case(cw));
            }
            restore_pos(orig_pos);
         }
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO progress4gl_space_words:[]={
   '&analyze-resume' => {'&analyze-resume'},
   '&analyze-suspend'=> {'&analyze-suspend'},
   '&else'           => {'&else'},
   '&elseif'         => {'&elseif'},
   '&endif'          => {'&endif'},
   '&file-name'      => {'&file-name'},
   '&global-define'  => {'&global-define'},
   '&if'             => {'&if'},
   '&message'        => {'&message'},
   '&opsys'          => {'&opsys'},
   '&scoped-define'  => {'&scoped-define'},
   '&then'           => {'&then'},
   '&undefine'       => {'&undefine'},
   'end'             => {'end'},
   'do'              => {'do'},
   'for'             => {'for'},
   'if'              => {'if'},
   'case'            => {'case'},
   'repeat'          => {'repeat'},
   'when'            => {'when'},
   'otherwise'       => {'otherwise'},
   'procedure'       => {'procedure'},
   'function'        => {'function'},
   'trigger'         => {'trigger'},
};

/*
    Returns true if nothing is done
*/
static bool progress4gl_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   save_pos(auto p);
   orig_linenum:=p_line;
   orig_col:=p_col;
   enter_cmd:=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   if (_in_progress4gl_preprocessing()) {
      restore_pos(p);
      return true;
   }
   begin_col:=progress4gl_begin_stat_col(false, /* No RestorePos */
                              false, /* Don't skip first begin statement marker */
                              false, /* Don't return first non-blank */
                              true,  /* Fail if no code before cursor. */
                              false,
                              true
                              );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return true;
   }
   restore_pos(p);
   col:=_progress4gl_indent_col(0);
   if (col<=0) {
      restore_pos(p);
      return true;
   }
   indent_on_enter(syntax_indent,col);
   return false;
}
static void maybe_insert_doend(int syntax_indent,int be_style,int width,_str word,_str begin_word,int adjust_col=0,bool putCursorInsideDoBlock=false)
{
   col:=width+length(word)+2+adjust_col;
   //if (be_style & NO_SPACE_BEFORE_PAREN) --col;
   if ( be_style==BES_BEGIN_END_STYLE_3 ) {
      width += syntax_indent;
   }
   if ( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
      up_count:=1;
      more_indent := 0;
      if (be_style==BES_BEGIN_END_STYLE_2 || be_style==BES_BEGIN_END_STYLE_3) {
         up_count++;
         insert_line(indent_string(width+more_indent):+begin_word);
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) || putCursorInsideDoBlock) {
         up_count++;
         insert_line(indent_string(width+syntax_indent));
      }
      insert_line(indent_string(width):+_word_case('end.'));
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
static _str progress4gl_expand_space()
{
   if_special_case := false;

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   indent_case := (int)p_indent_case_from_switch;

   status := 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,progress4gl_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }
   if ( word=='') {
      // Check for ELSE IF or END; ELSE IF
      parse orig_line with auto first_word auto second_word auto rest;
      first_word=lowcase(first_word);
      second_word=lowcase(second_word);
      if (first_word=='else' && second_word!='' &&
          lowcase(orig_word)==substr('else if',1,length(orig_word))) {
         word='else if';
         if_special_case=true;
      } else if (second_word=='else' && rest!='' && lowcase(orig_word)==substr('end. else if',1,length(orig_word))) {
         word='end. else if';
         if_special_case=true;
      } else if (first_word=='end.else' && second_word!='' && lowcase(orig_word)==substr('end. else if',1,length(orig_word))) {
         word='end. else if';
         if_special_case=true;
      } else {
         return(1);
      }
   }

   line=substr(line,1,length(line)-length(orig_word)):+_word_case(word);
   width:=text_col(line,length(line)-length(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);
   maybespace:=' ';
   //maybespace=(be_style & NO_SPACE_BEFORE_PAREN)?'':' ';
   style:=(be_style==BES_BEGIN_END_STYLE_3);
   e1:=' do:';
   // IF do/end goes on separate line
   if (style==1 || !(LanguageSettings.getInsertBeginEndImmediately(p_LangId)) || (be_style==BES_BEGIN_END_STYLE_2)) {
      e1='';
   }
   if (word=='do') {
      progress4gl_colon();
      /*replace_line(_word_case(line));
      insert_line(indent_string(width)_word_case('end.'));
      up();_end_line();++p_col;*/
   } else if ( word=='if' || if_special_case) {
      replace_line(line:+maybespace:+_word_case(' then':+e1));
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case('do:'));
   } else if (word=='for' || word=='repeat') {
      replace_line(line:+maybespace);
      insert_line(indent_string(width):+_word_case('end.'));
      up();_end_line();
   } else if (word=='case') {
      replace_line(line:+maybespace);
      insert_line(indent_string(width):+_word_case('end case.'));
      up();_end_line();
   } else if (word=='when') {
      col:=_progress4gl_find_block_col(auto block_info,true,true);
      if (col) {
         if (indent_case) {
            width=col-1+p_SyntaxIndent;
         } else {
            width=col-1;
         }
      }
      replace_line(indent_string(width):+_word_case('when  then':+e1));
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case('do:'));
   } else if (word=='otherwise') {
      replace_line(line:+maybespace:+strip(_word_case(e1)));
      maybe_insert_doend(syntax_indent,be_style,width,word,_word_case('do:'),0,true);
   } else if (word=='trigger') {
      replace_line(line' '_word_case('procedure '));
      _end_line();
   } else if (word=='procedure' || word=='function' || substr(word,1,1)=='&') {
      replace_line(line);
      _end_line();++p_col;
   } else if (word=='end') {
      save_pos(auto p);
      up();_end_line();
      col:=_progress4gl_find_block_col(auto block_info,true,true);
      //messageNwait('col='col);
      restore_pos(p);
      if (!col) {
         status=1;
      } else {
         replace_line(indent_string(col-1):+_word_case('end '));
         _end_line();
      }

   } else {
     status=1;
   }
   return(status);

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

int progress4gl_proc_search(_str &proc_name,int find_first)
{
   int status;
   if ( find_first ) {
      ID_CHARS:='\-0-9#$%&a-zA-Z_';
      //ID_CHARS='a-zA-Z';
      variable_re:='(['ID_CHARS']#)';
      // Here we require the PROCEDURE or FUNCTION keyword to be the
      // first non blank character. It's not exactly correct but hopefully good enough.
      // the alternate requires checking what follows the procedure/function name which
      // requires a lot more work.
      re:='^[ \t]@{#1('PROCEDURE_RE'|FUNCTION)}[ \t]+{#0'variable_re'}';
      //re='('PROCEDURE_RE'|FUNCTION)';
      status=search(re,'hri@xcs');
      //say(get_message(status));
   } else {
      status=repeat_search();
   }
   save_pos(auto orig_pos);
   for (;;) {
      if ( status ) {
         restore_pos(orig_pos);
         break;
      }
      name:=get_text(match_length('0'),match_length('S0'));
      if (name=='for') {  // this must be a trigger procedure
         name='trigger(proc)';
      } else {
         typename:=get_text(match_length('1'),match_length('S1'));
         if (lowcase(typename)=='function') {
            if(progress4gl_is_proto()) {
               name :+= '(proto)';
            } else {
               name :+= '(func)';
            }
         } else {
            if(progress4gl_is_proto()) {
               name :+= '(procproto)';
            } else {
               name :+= '(proc)';
            }
         }
      }
      if (proc_name:=='') {
         proc_name=name;
         return(0);
      }
      if (proc_name==name) {
         return(0);
      }
      status=repeat_search();
   }
   return(status);
}

/*
    This functions make show_procs smarter by showing user
    all parameters and attributes of the function definition
    but not the code.
*/
void progress4gl_find_lastprocparam()
{
   save_pos(auto p);
   status:=search('[.:]','hRI@xcs');
   result:=false;
   for (;;) {
      if (status) {
         break;
      }
      word:=lowcase(get_text(match_length(),match_length('S')));
      if (word=='.'){
         if(!progress4gl_period_ends_statement()) {
            status=repeat_search();
            continue;
         }
         break;
      } else if (word==':') {
         if(!progress4gl_colon_ends_statement()) {
            status=repeat_search();
            continue;
         }
         break;
      }
      result=true;
      break;
   }
   if (status) {
      restore_pos(p);
      return;
   }
   orig_col:=p_col;
   _first_non_blank();
   if (p_col==orig_col) {
      up();_end_line();
   }
}

static void progress4gl_get_prev_word(_str &pword) {
   pword='';
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   status:=_clex_skip_blanks('-');
   if (!status) {
      ch:=get_text();
      // Is this a word character?
      if (pos('['p_word_chars']',ch,1,'ri')) {
         pword=cur_identifier(auto junk);
      }

   }
   //prev_word();
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
}
/*
   Check if the FORWARD or IN keyword has been used to indicate a forward declaration of a function
*/
static bool progress4gl_is_proto() {
   save_search(auto a,auto b,auto c,auto d);
   save_pos(auto p);
   status:=search('[.:]|forward|in','hRI@xcs');
   result:=false;
   for (;;) {
      if (status) {
         break;
      }
      word:=lowcase(get_text(match_length(),match_length('S')));
      if (word=='.'){
         if(!progress4gl_period_ends_statement()) {
            status=repeat_search();
            continue;
         }
         break;
      } else if (word==':') {
         if(!progress4gl_colon_ends_statement()) {
            status=repeat_search();
            continue;
         }
         break;
      } else if (word!=lowcase(cur_word(auto junk))) {
         status=repeat_search();
         continue;
      }
      result=true;
      break;
   }
   restore_pos(p);
   restore_search(a,b,c,d);
   return(result);
}

/*
    // method prototype inside interface
    METHOD PUBLIC VOID GetHighCustomerData
    ( OUTPUT DATASET dsHighCustData BIND ).
*/
static bool progress4gl_is_method_proto() {
   save_search(auto a,auto b,auto c,auto d);
   save_pos(auto p);
   status:=search('\)[ \t]*[.:]','hRI@xcs');
   result:=false;
   for (;;) {
      if (status) {
         break;
      }
      word:=lowcase(get_text(match_length(),match_length('S')));
      ch:=_last_char(word);
      if (ch=='.'){
         result=true;
         break;
      } else if (ch==':') {
         result=false;
         break;
      }
      result=true;
      break;
   }
   restore_pos(p);
   restore_search(a,b,c,d);
   return(result);
}


/* 
    GET (....):    <-- this is a definition of a getter. Anything else is not
    SET (....):    <-- this is a definition of a setter. Anything else is not
 
*/
static bool progress4gl_is_property_proto() {
   save_search(auto a,auto b,auto c,auto d);
   save_pos(auto p);
   result:=true;
   p_col+=3;
   status:=_clex_skip_blanks();
   if (!status) {
      if (get_text()=='(') {
         status=_find_matching_paren();
         if (!status) {
            right();
            status=_clex_skip_blanks();
            if (!status) {
               result=get_text()!=':';
            }
         }
      }
   }
   restore_pos(p);
   restore_search(a,b,c,d);
   return(result);
}
static bool progress4gl_at_start_of_statement() {

   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   result:=false;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   pword := "";
   status:=_clex_skip_blanks('-');
   if (!status) {
      ch:=get_text();
      result=ch=='.' || ch==':';
      if (!result) {
         word:=cur_identifier(auto junk);
         // Checking for then only works if 
         if (strieq(word,'then')) {
            result=true;
         }
      }
      // We could get messed up by preprocessing
   } else {
      // Top of file
      result=true;
   }
   //prev_word();
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return(result);
}

/*

    CASE -- prev may not be END
    END.
    REPEAT -- prev may not be END
    END.
    ENUM   prev may not be END or DEFINE
    END ENUM
    CONSTRUCTOR -- prev may not be END
    END CONSTRUCTOR
    DESTRUCTOR  -- prev may not be END
    END DESTRUCTOR
    PROCEDURE  -- prev word may not be END TRIGGER or DELETE
    END PROCEDURE
    FUNCTION   -- prev word may not be END 
    END FUNCTION
    CATCH    -- prev word may not be END 
    END CATCH
    FINALLY  -- prev word may not be END 
    END FINALLY
    COMPARES  -- prev word may not be END 
    END COMPARES  
    CLASS    -- prev word may not be END or AS
    END CLASSS
    TRIGGERS  -- prev word may not be END or DISABLE
    END TRIGGERS
    REPEAT  -- prev word may not be END 
    END
    INTERFACE  -- prev word may not be END 
    END INTERFACE
 
 
    DO  -- Can be anywhere
    END.
 
    FOR  -- Prev must be . : or top of file
    END.
 
    GET       -- Must be followed by (??):
    END GET
    SET      -- Must be followed by (??):
    END SET
 
    // method prototype inside interface
    METHOD PUBLIC VOID GetHighCustomerData
    ( OUTPUT DATASET dsHighCustData BIND ).
 
 
    METHOD -- Must be followed by (??): -- prev may not be END
    END METHOD
 


*/
int _progress4gl_find_block_col(_str &block_info/* currently just block word */,bool restoreCursor,bool returnFirstNonBlank,int direction=-1)
{
   save_pos(auto orig_pos);
   int nesting;
   nesting=1;
   status:=search('do|case|for|repeat|'PROCEDURE_RE'|function|end|enum|method|constructor|destructor|catch|finally|compares|class|triggers|interface|get|set',
                  direction>0?'h@wirxcs':'h@-wirxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      word:=lowcase(get_text(match_length(),match_length('S')));
      //messageNwait(word);
      switch (word) {
      case 'case':
      case 'repeat':
      case 'enum':
      case 'constructor':
      case 'destructor':
      case 'proce':
      case 'proced':
      case 'procedu':
      case 'procedur':
      case 'procedure':
      case 'function':
      case 'catch':
      case 'compares':
      case 'class':
      case 'triggers':
      case 'interface':
      case 'method':
      case 'get':
      case 'set':
         // make sure this is not preceded by END keyword
         progress4gl_get_prev_word(auto pword);pword=lowcase(pword);
         if (pword=='end' || pword=='define' || pword=='trigger' || pword=='delete' || pword=='disable') {
            status=repeat_search();
            continue;
         }
         switch (word) {
         case 'function':
            // Check if the FORWARD or IN keyword has been used to indicate a forward declaration
            if (progress4gl_is_proto()) {
               status=repeat_search();
               continue;
            }
            break;
         case 'method':
            // Make sure this isn't a method proto type in an interface definition
            if (progress4gl_is_method_proto()) {
               status=repeat_search();
               continue;
            }
            break;
         case 'set':
         case 'get':
            // Make sure this isn't a method proto type in an interface definition
            if (progress4gl_is_property_proto()) {
               status=repeat_search();
               continue;
            }
            break;
         }
         nesting+=direction;
         break;
      case 'do':
         nesting+= direction;
         break;
      case 'for':
         if (!progress4gl_at_start_of_statement()) {
            status=repeat_search();
            continue;
         }
         nesting+= direction;
         break;
      case 'end':
         nesting+= -direction;
         break;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         block_info=cur_word(auto junk);
         if (returnFirstNonBlank) {
            _first_non_blank();
         }
         col:=p_col;
         if (restoreCursor) {
            restore_pos(orig_pos);
         }
         return(col);
      }
      status=repeat_search();
   }
}
bool _in_progress4gl_preprocessing()
{
   save_pos(auto p);
   get_line(auto line);line=strip(line,'L');
   if (substr(line,1,1)=="&") {
      restore_pos(p);
      return(true);
   }
   restore_pos(p);
   return(false);
}
static bool progress4gl_colon_ends_statement()
{
   ch:=_expand_tabsc(p_col+1,1);
   // If . is followed by blank or comment (check for slash is good enough)
   return(ch=='' || ch=='/');
}
static bool progress4gl_period_ends_statement()
{
   ch:=_expand_tabsc(p_col+1,1);
   // If . is followed by blank or comment (check for slash is good enough)
   return(ch=='' || ch=='/');
}
/*
   Skip blanks and preprocessing
*/
static int _progress4gl_skip_blanksNpp(...)
{
   MaxSkipPreprocessing:=VSCODEHELP_MAXSKIPPREPROCESSING;
   backwards:=pos('-',arg(1));
   for (;;) {
      status:=_clex_skip_blanks(arg(1));
      if (status) {
         return(status);
      }
      /*if (p_line>FailIfPastLinenum) {
         messageNwait("p_line="p_line" FailIfPastLinenum="FailIfPastLinenum);
         return(STRING_NOT_FOUND_RC);
      }*/
      if (!_in_progress4gl_preprocessing()) {
         return(status);
      }
      --MaxSkipPreprocessing;
      if (MaxSkipPreprocessing<=0) {
         return(STRING_NOT_FOUND_RC);
      }
      if (backwards) {
         up();_end_line();
      } else {
         _end_line();
      }
   }
}
/*

   Return beginning of statement column.  0 if not found.

*/
static int progress4gl_begin_stat_col(bool RestorePos,bool SkipFirstHit,bool ReturnFirstNonBlank,
                              bool FailIfNoPrecedingText=false,
                              bool AlreadyRecursed=false,
                              bool FailWithMinus1_IfNoTextAfterCursor=false,
                              //boolean leave_cursor_at_start_of_word=false
                              )
{

   //messageNwait('start loop');
   orig_linenum:=p_line;orig_col:=p_col;
   save_pos(auto p);
   //status:=search('[:.]|if|do|repeat|for|case|else|otherwise|when','h-RI@xcs');
   status:=search('[:.]','h-RI@xcs');
   nesting:=0;
   hit_top:=false;
   MaxSkipPreprocessing:=VSCODEHELP_MAXSKIPPREPROCESSING;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         word:=lowcase(get_text(match_length(),match_length('S')));
         //messageNwait('loop word='word);
         if (word=='.'){
            if(!progress4gl_period_ends_statement()) {
               SkipFirstHit=false;
               status=repeat_search();
               continue;
            }
         } else if (word==':') {
            if(!progress4gl_colon_ends_statement()) {
               SkipFirstHit=false;
               status=repeat_search();
               continue;
            }
         } else if (word!=lowcase(cur_identifier(auto junk))) {
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
         if (_in_progress4gl_preprocessing()) {
            --MaxSkipPreprocessing;
            if (MaxSkipPreprocessing<=0) {
               status=STRING_NOT_FOUND_RC;
               continue;
            }
            SkipFirstHit=false;
            begin_line();
            status=repeat_search();
            continue;
         }
         if (word=='.' || word==':' /*|| word=='else'*/) {
             p_col+=match_length();
         }
#if 0
         // Special case most words which can be considered to start a statement.
         // If this causes problems in the future, we will have to add a
         // parameter to this function to specify whether this check should
         // be made.
         if (word!='do' && word!='begin' && word!='when') {
            p_col+=match_length();
         }
#endif
      }
      //messageNwait('d1');
      status=_progress4gl_skip_blanksNpp();
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
      if (ReturnFirstNonBlank) {
         _first_non_blank();
      }
      //messageNwait('d2');
      col:=p_col;
      if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>=orig_col)) {
         return(0);
      }
      if (RestorePos) {
         restore_pos(p);
      }
      //messageNwait('d3 col='col);
      return(col);
   }
}
static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   //_message_box("This case not handled yet");
   // Smart paste should set the non_blank_col
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      restore_pos(p);
      return(non_blank_col);
   }
   restore_pos(p);
   begin_stat_col:=progress4gl_begin_stat_col(false /* No RestorePos */,
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
      save_pos(p2);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      ch=get_text();
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
      nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
#endif
      col:=p_col;
      restore_pos(p);
      return(col+syntax_indent);
   }
   restore_pos(p);
   get_line(auto line);line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   _first_non_blank();
   col:=p_col;
   restore_pos(p);
   return(col);
}
static int HandlePartialStatement(int statdelim_linenum,
                                  int sameline_indent,
                                  int nextline_indent,
                                  int orig_linenum,int orig_col)
{
   orig_ch:=get_text();
   save_pos(auto orig_pos);
   //linenum=p_line;col=p_col;

   begin_stat_col:=progress4gl_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker. */,
                                   false /* Don't return first non-blank */,
                                   false,
                                   false,
                                   true   // Fail if no text after cursor
                                   );
   /*if (begin_stat_col>0 && pos('['p_word_chars']',get_text(),1,'r')) {
      word=cur_word(junk);
      p_col+=length(word);
   } */
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=progress4gl_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */
                                      );
      if (p_line==statdelim_linenum) {
         return(begin_stat_col+sameline_indent);
      }
      col:=p_col;
      return(col+nextline_indent);
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
   begin_stat_col:=progress4gl_begin_stat_col(false /* RestorePos */,
                              false /* skip first begin statement marker */,
                              true/* return first non-blank */
                              );
   if (!begin_stat_col) {
      restore_pos(p);
      return(false);
   }
   get_line(auto line);
   parse line with auto label_name':' auto rest;
   if (label_name=='' || pos('[ \t]',label_name,1,'r')) {
      restore_pos(p);
      return(false);
   }
   parse rest with auto b4 'proc(edure|)[ \t;]','ri' +0 rest;
   if (b4!='') {
      restore_pos(p);
      return(false);
   }
   if (rest=='') {
      // This line is just a label
      restore_pos(p);
      return(false);
   }
   restore_pos(p);
   col=begin_stat_col;
   return(true);
}
/*
    Call this function when cursor is sitting on
      DO, REPEAT, FOR, or CASE
*/
static int _get_doend_indent_col(int &end_col,bool multiline=false)
{
   save_pos(auto p2);
   _nrseek(_nrseek()-1);
   multiline=true;

   if (multiline) {
      progress4gl_prev_sym();
   } else {
      progress4gl_prev_sym_same_line();
   }
   begin_stat_col := 0;
   gtkinfo=lowcase(gtkinfo);
   if (gtkinfo=='else' || gtkinfo!='then') {
      if (gtkinfo=='end') {  // This only happens with "END CASE"
         restore_pos(p2);
         _first_non_blank();
         begin_stat_col=p_col;
      } else {
         //messageNwait('gtkinfo='gtkinfo);
         if (gtkinfo!='else') {
            col:=progress4gl_begin_stat_col(false,false,false);
            word:=lowcase(cur_word(auto junk));
            //messageNwait('word='word);
            if (!col || word!='on') {
               restore_pos(p2);
            }
         }
         _first_non_blank();
         begin_stat_col=p_col+p_SyntaxIndent;
      }
      end_col=p_col;
   } else {
      //messageNwait('h3');
      // search for beginning of IF or WHEN statment
      col:=progress4gl_begin_stat_col(true /* RestorePos */,
                              false /* skip first begin statement marker */,
                              true /* return first non-blank */
                              );
      if (!col) {
         restore_pos(p2);
         _first_non_blank();
         begin_stat_col=p_col;
         end_col=p_col;
      } else {
         restore_pos(p2);
         begin_stat_col=col+p_SyntaxIndent;
         end_col=col;
      }
   }
   return(begin_stat_col);
}
/*
   This code is just here incase we get fancy
*/
int _progress4gl_indent_col(int non_blank_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   //syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   orig_col:=p_col;
   orig_linenum:=p_line;
   save_pos(auto p);
   //parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_when UseContOnParameters .;
   syntax_indent:=p_SyntaxIndent;
   // IF user does not want syntax indenting
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   ParameterAlignment := beaut_funcall_param_alignment();
   //style1=be_style & STYLE1_FLAG;
   //style2=be_style & STYLE2_FLAG;
   enter_cmd:=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }

   nesting:=0;OpenParenCol:=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   MaxSkipPreprocessing:=VSCODEHELP_MAXSKIPPREPROCESSING;
   //status=search('[.:()]|for|case|repeat|then|else','h-RI@xcs');
   status:=search('[.:()]|then|else','h-RI@xcs');
   for (;;) {
      if (status) {
         if (nesting<0) {
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         top();_clex_skip_blanks();
         if (get_text()=='&' && (orig_linenum>p_line ||orig_linenum==p_line && orig_col>=p_col)) {
            restore_pos(p);
            return(0);
         }
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      ch:=get_text();
      switch (ch) {
      case '(':
         if (!nesting && !OpenParenCol) {
            typeless p3;
            save_pos(p3);
#if 1
            save_search(auto ss1,auto ss2,auto ss3,auto ss4);
            col:=p_col;
            linenum:=p_line;
            ++p_col;
            status=_clex_skip_blanks();
            /*
               Handle these cases better
             
                foo( /* arg_name */value1,<Enter>
                     /* arg_2*/value2,<Enter>
             
            */
            if (p_line>linenum) {
               _first_non_blank();
            } else {
               restore_pos(p3);++p_col;
               search('[^ \t]|$','r@h');
            }


            if (!(ParameterAlignment==FPAS_CONTINUATION_INDENT) &&
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
               progress4gl_prev_sym();
               if (gtk==TK_ID && !pos(' 'gtkinfo' ',' with for if switch while ')) {
                  restore_pos(p3);
                  _first_non_blank();
                  col=p_col+p_SyntaxIndent-1;
               }
            }
            restore_search(ss1,ss2,ss3,ss4);
#else
            save_search(ss1,ss2,ss3,ss4);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanks();
            if (!status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<=orig_col)
                           )) {
               col=p_col-1;
            }
            restore_search(ss1,ss2,ss3,ss4);
#endif
            OpenParenCol=col;
            restore_pos(p3);
         }
         --nesting;
         status=repeat_search();
         continue;
      case ')':
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
      if (_in_progress4gl_preprocessing()) {
         begin_line();
         status=repeat_search();
         continue;
      }
      word:=get_text(match_length(),match_length('S'));
      if (word!='.' && word!=':' && word!=cur_word(auto junk)) {
         status=repeat_search();
         continue;
      }
      word=lowcase(word);

      //messageNwait("c_indent_col2: ch="ch);
      switch (word) {
      case '.':
      case ':':
         bool was_colon=word==':';
         //messageNwait('case . or :');
         if (word==':') {
            // colon could be end of block.
            if (!progress4gl_colon_ends_statement()) {
               status=repeat_search();
               continue;
            }
         } else {
            // colon could be end of block or statement
            if (!progress4gl_period_ends_statement()) {
               status=repeat_search();
               continue;
            }
         }
         save_pos(auto p2);
         save_search(auto s1,auto s2,auto s3,auto s4);

         statdelim_linenum:=p_line;
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         right();
         col:=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         //messageNwait('col='col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);

         //messageNwait('b4 call');
         begin_stat_col:=progress4gl_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    false /* return first non-blank */
                                    );
         if (was_colon && _clex_find(0,'g')==CFG_KEYWORD) {
            word=lowcase(cur_word(junk));
            /*
               this code does not handle some dangling ifs like:
                IF i<j THEN

                    X=X+1.
                ELSE
                    IF i<j THEN <enter>
                    <end up here>

                OR

                IF i<j THEN

                    X=X+1.
                ELSE
                    IF i<j THEN DO:

                    END.<enter>
                    <end up here>

            */
            //messageNwait('word='word' i='p_SyntaxIndent);
            if (word=='function' || pos(PROCEDURE_RE,word,1,'ri')==1 || word=='trigger') {
               if (!progress4gl_is_proto()) {
                  begin_stat_col=p_col+p_SyntaxIndent;
               } else {
                  _first_non_blank();
                  begin_stat_col=p_col;
               }
            } else if (word=='if' || word=='do' || word=='repeat' || word=='for' || word=='case' || 
                       word=='interface' || word=='constructor' || word=='destructor' || word=='catch' || word=='enum' || word=='compares') {
               // Check if this is part of an else or then clause.
               begin_stat_col=_get_doend_indent_col(auto end_col);
            } else if (word=='when' || word=='else') {
                begin_stat_col=p_col+p_SyntaxIndent;
            } else if (word=='method') {
               if (progress4gl_is_method_proto()) {
                  _first_non_blank();
                  begin_stat_col=p_col;
               } else {
                  begin_stat_col=p_col+p_SyntaxIndent;
               }
            } else if (word=='get' || word=='set') {
               if (progress4gl_is_property_proto()) {
                  _first_non_blank();
                  begin_stat_col=p_col;
               } else {
                  begin_stat_col=p_col+p_SyntaxIndent;
               }
            } else {
               _first_non_blank();
               begin_stat_col=p_col;
            }
         } else {
            _first_non_blank();
         }
         restore_pos(p);
         return(begin_stat_col);
      /*case 'then':

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
            first_non_blank();
            col=p_col+syntax_indent;
            restore_pos(p);
            return(col);
         }
         /*  IF expression THEN

         */
         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);*/
      case 'then':
      case 'else':
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
      default:
         _message_box('unknown word='word);
      }
      status=repeat_search();
   }

}
int progress4gl_smartpaste(bool char_cbtype,int first_col)
{
   comment_col:='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   get_line(auto first_line);
   i:=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!='' && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   status:=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment)
   //  OR  first non-blank code of pasted stuff is preprocessing
   //  OR (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!='')
       || (!status && get_text()=='&')
       || (!status && comment_col!='' && p_col!=comment_col)) {
      return(0);
   }

   //parse name_info(_edit_window().p_index) with . expand . . be_style . . indent_case .;
   //syntax_indent=p_SyntaxIndent;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   be_style := p_begin_end_style;

   //end_comment := (int)LanguageSettings.getBeginEndComments(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);


   word:=lowcase(cur_word(auto junk));
   ignore_column1:=false;
   enter_col := 0;
   if (!status && (word=='end')) {
      save_pos(auto p2);
      up();_end_line();
      enter_col=_progress4gl_find_block_col(auto block_info,false,false);
      block_info=lowcase(block_info);
      if (enter_col) {
         if (block_info=='do' || block_info=='for' || block_info=='repeat' ||
             block_info=='case') {
            _get_doend_indent_col(enter_col);
         } else {
            _first_non_blank();
            //???begin_stat_col=p_col;
         }
      }
      /*if (block_info!='do' && block_info!='begin') {
         first_non_blank();
         enter_col=p_col;
      } */
      restore_pos(p2);
      if (!enter_col) {
         enter_col=0; //???
      }
      _begin_select();get_line(first_line);up();
   } else if (!status && (word=='do')) {
      save_pos(auto p2);
      _get_doend_indent_col(enter_col);
      /*if (block_info!='do' && block_info!='begin') {
         first_non_blank();
         enter_col=p_col;
      } */
      restore_pos(p2);
      if (!enter_col) {
         enter_col=0; //???'';
      }
      _begin_select();get_line(first_line);up();
   } else if (!status && (word=='when')) {
      enter_col=_progress4gl_find_block_col(auto block_info,true,true);
      if (enter_col) {
         if (indent_case) {
            enter_col += p_SyntaxIndent;
         } else {
            enter_col=enter_col;
         }
      }
      if (!enter_col) {
         enter_col=0; // ???'';
      }
      _begin_select();get_line(first_line);up();
   } else {
      ignore_column1=true;
      _begin_select();get_line(first_line);up();
      _end_line();
      enter_col=progress4gl_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && ignore_column1) || enter_col==''
      /*||(substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))*/
       ) {
      return(0);
   }
   return(enter_col);
}

static int progress4gl_enter_col()
{
   //parse name_info(_edit_window().p_index) with . expand . . be_style indent_fl . indent_case .
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      progress4gl_enter_col2(auto enter_col) ) {
      return(0); //???
   }
   return(enter_col);
}


static bool progress4gl_enter_col2(int &enter_col)
{
   enter_col=_progress4gl_indent_col(0);
   return(false);
}
//def ' '=sql_space
//def ENTER=sql_enter*/

//Returns 0 if the letter wasn't upcased, otherwise 1
_command void progress4gl_maybe_case_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _str event=event2name(last_event());
   if (command_state()) {
      keyin(event);
      return;
   }
   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);

   _maybe_case_word(autoCase,gWord,gWordEndOffset);
}

_command void progress4gl_maybe_case_backspace() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _str event=event2name(last_event());
   if (command_state()) {
      call_root_key(BACKSPACE);
      return;
   }
   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);
   _maybe_case_backspace(autoCase,gWord,gWordEndOffset);
}


#region Options Dialog Helper Functions

defeventtab _progress4gl_extform;

void _progress4gl_extform_init_for_options(_str langID)
{
   label2._use_source_window_font();
   label3._use_source_window_font();

   _language_form_init_for_options(langID, _progress4gl_extform_get_value, 
                                   _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(langID);
}

_str _progress4gl_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case "ctlautocase":
      value = (int)LanguageSettings.getAutoCaseKeywords(langId);
      break;
   //case "_comment":
   //   value = (int)LanguageSettings.getBeginEndComments(langId);
   //   break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}

bool _progress4gl_extform_apply()
{
   _language_form_apply(_progress4gl_extform_apply_control);

   return true;
}

_str _progress4gl_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := "";

   switch (controlName) {
   case "ctlautocase":
      LanguageSettings.setAutoCaseKeywords(langId, (int)value != 0);
      break;
   //case "_comment":
   //   LanguageSettings.setBeginEndComments(langId, ((int)value != 0));
   //   break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return updateString;
}

#endregion Options Dialog Helper Functions

void _progress4gl_extform.on_destroy()
{
   _language_form_on_destroy();
}
int _progress4gl_find_matching_word(bool quiet,
                          int pmatch_max_diff_ksize=MAXINT,
                          int pmatch_max_level=MAXINT) {

   save_pos(auto p);
   if (p_col>_text_colc(0,'L')) {
      _end_line();left();
   }
   try_word_at_beginning_of_line := false;
   second_word := "";
   word:=cur_identifier(auto start_col);word=lowcase(word);
   if (word!='') {
      switch (word) {
      case 'case':
      case 'repeat':
      case 'enum':
      case 'constructor':
      case 'destructor':
      case 'proce':
      case 'proced':
      case 'procedu':
      case 'procedur':
      case 'procedure':
      case 'function':
      case 'catch':
      case 'compares':
      case 'class':
      case 'triggers':
      case 'interface':
      case 'method':
      case 'get':
      case 'set':
      case 'for':
      case 'end':
      case 'do':
         break;
      default:
         word='';
      }
   }
   if (word=='') {
      _first_non_blank();
      word=cur_identifier(start_col);word=lowcase(word);
      if (word=='') {
         restore_pos(p);
         return 1;
      }
   }
   if (word=='if') {
      status:=search('do\:|[.:]([ \t/]|$)','ir@hxcs');
      if (!status && match_length()==3) {
         word=cur_identifier(start_col);word=lowcase(word);
         if (word!='do') {
            restore_pos(p);
            return 1;
         }
      }
   }
   if (word=='do') {
      p_col+=length(word);
      col:=_progress4gl_find_block_col(auto block_info,false,false,1);
      if (col) {
         return 0;
      }
      restore_pos(p);
      return 1;
   }
   p_col=start_col;
   switch (word) {
   case 'case':
   case 'repeat':
   case 'enum':
   case 'constructor':
   case 'destructor':
   case 'proce':
   case 'proced':
   case 'procedu':
   case 'procedur':
   case 'procedure':
   case 'function':
   case 'catch':
   case 'compares':
   case 'class':
   case 'triggers':
   case 'interface':
   case 'method':
   case 'get':
   case 'set':
   case 'for':
      if (word=='for') {
         if (!progress4gl_at_start_of_statement()) {
            restore_pos(p);
            return 1;
         }
      }
      switch (word) {
      case 'function':
         // Check if the FORWARD or IN keyword has been used to indicate a forward declaration
         if (progress4gl_is_proto()) {
            restore_pos(p);
            return 1;
         }
         break;
      case 'method':
         // Make sure this isn't a method proto type in an interface definition
         if (progress4gl_is_method_proto()) {
            restore_pos(p);
            return 1;
         }
         break;
      case 'set':
      case 'get':
         // Make sure this isn't a method proto type in an interface definition
         if (progress4gl_is_property_proto()) {
            restore_pos(p);
            return 1;
         }
         break;
      }
      progress4gl_get_prev_word(auto pword);pword=lowcase(pword);
      if (pword=='end' || pword=='define' || pword=='trigger' || pword=='delete' || pword=='disable') {
         try_word_at_beginning_of_line=true;
      }
      if (try_word_at_beginning_of_line) {
         get_line(auto orig_line);
         parse orig_line with word second_word '.';
         word=lowcase(word);second_word=lowcase(second_word);
         _first_non_blank();
      }
      break;
   }
   if (word=='end') {
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      col:=_progress4gl_find_block_col(auto block_info,false,false);
      if (col) {
         return 0;
      }
      restore_pos(p);
      return 1;
   }
   switch (word) {
   case 'case':
   case 'repeat':
   case 'enum':
   case 'constructor':
   case 'destructor':
   case 'proce':
   case 'proced':
   case 'procedu':
   case 'procedur':
   case 'procedure':
   case 'function':
   case 'catch':
   case 'compares':
   case 'class':
   case 'triggers':
   case 'interface':
   case 'method':
   case 'get':
   case 'set':
   case 'for':
      if (try_word_at_beginning_of_line) {
         restore_pos(p);
         return 1;
      }
      p_col+=length(word);
      col:=_progress4gl_find_block_col(auto block_info,false,false,1);
      if (col) {
         return 0;
      }
      restore_pos(p);
      return 1;
   }
   //say('word='word' second_word='second_word);
   restore_pos(p);
   return 1;
}
bool _progress4gl_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
