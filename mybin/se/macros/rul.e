////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "notifications.e"
#import "optionsxml.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "main.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  To install this macro, perform use
  the Load module dialog box ("Macro", "Load Module...").
*/

#define RUL_LANGUAGE_ID    'rul'
#define RUL_MODE_NAME      'InstallScript'
#define RUL_VLXLEXERNAME   'InstallScript'
#define RUL_IDENTIFIER_CHARS  'A-Za-z0-9_'

#define RUL_MAXSKIPPREPROCESSING   100

/*
 cache name and seek position of last function
 we got function help on (for performance)
*/
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;

/*
 regular expressions and strings
 used for picking out Rul keywords
*/
//#define RUL_COMMON_END_OF_STATEMENT_RE 'abort|begin|case|default|downto|else|elseif|end|endfor|endif|endprogram|endswitch|endwhile|exit|for|function|goto|if|program|prototype|repeat|return|step|switch|then|to|typedef|until|while'
//#define RUL_NOT_FUNCTION_WORDS  ' abort case downto elseif exit for goto if return step switch to until while '

defeventtab rul_keys;
def  ' '= rul_space;
def  '#'= auto_codehelp_key;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  ';'= rul_semi;
def  '>'= auto_codehelp_key;
def  'ENTER'= rul_enter;

defload()
{
   _str setup_info='MN='RUL_MODE_NAME',TABS=+4,MA=1 74 1,':+
               'KEYTAB=rul-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='RUL_IDENTIFIER_CHARS',LN='RUL_VLXLEXERNAME',CF=1,';
   _str compile_info='';
   // The first two number are syntax_indent amount and expand on/off
   // the restore of
   _str syntax_info='4 1 ':+   // <Syntax indent amount>  <expansion on/off>
               '1 1 0 0';   // <min abbrev> <not used> <begin/end style> <indent-case>
   _str be_info='';

   _CreateLanguage(RUL_LANGUAGE_ID, RUL_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('rul', RUL_LANGUAGE_ID);
}

_command rul_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(RUL_LANGUAGE_ID);
}
_command void rul_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_rul_expand_enter);
}
_command void rul_semi() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin(';');
      return;
   }
   // check if the word at the cursor is end
   int cfg=_clex_find(0,'g');
   _str line="";
   get_line(line);
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || lowcase(line)!='end') {
      keyin(';');
      return;
   }
   typeless orig_pos;
   save_pos(orig_pos);
   up();_end_line();
   typeless block_info="";
   int col=_rul_find_block_col(block_info);
   restore_pos(orig_pos);
   if (col) {
      replace_line(indent_string(col-1)strip(line)';');_end_line();
   } else {
      keyin(';');
   }

}
_command rul_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      rul_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO rul_space_words:[] = {
   'if'          => { "if ... then ... endif;" },
   'while'       => { "while ( ... ) ... endwhile;" },
   'case'        => { "case :" },
   'switch'      => { "switch ( ... ) ... endswitch;" },
   'default'     => { "default:" },
   'repeat'      => { "repeat ... until ( ... );" },
   'return'      => { "return" },
   'end'         => { "end" },
   'else'        => { "else" },
   'elseif'      => { "elseif ... then ..." },
   'for'         => { "for ... step 1 endfor;" },
   'program'     => { "program ... endprogram" },
   'function'    => { "function ... begin ... end;" },
   'prototype'   => { "prototype" },
   'typedef'     => { "typedef ... begin end;" },
   'begin'       => { "begin ... end" },
};


/*
    Returns true if nothing is done.
*/
static boolean rul_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   typeless status=0;
   _str orig_line="";
   get_line(orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word=strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }

   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,rul_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=='') return(1);

   typeless block_info="";
   typeless p2=0;
   typeless indent_case="";
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);
   set_surround_mode_start_line();

   doNotify := true;
   if ( word=='if' ) {
      replace_line(line:+'  then');
      insert_line(indent_string(width)'endif;');
      set_surround_mode_end_line();
      up();_end_line();p_col-=5;
   } else if (word=='while') {
      replace_line(line:+' ()');
      insert_line(indent_string(width)'endwhile;');
      set_surround_mode_end_line();
      up();_end_line();p_col-=1;
   } else if (word=='case') {
      updateAdaptiveFormattingSettings(AFF_INDENT_CASE);

      save_pos(p2);
      up();_end_line();
      col:=_rul_find_block_col(block_info);
      restore_pos(p2);
      if (col) {
         if (p_indent_case_from_switch) {
            col+=syntax_indent;
         }
         replace_line(indent_string(col-1)orig_word' :');
      } else {
         replace_line(line:+' :');
      }
      _end_line();--p_col;
   } else if (word=='switch') {
      replace_line(line:+' ()');
      insert_line(indent_string(width)'endswitch;');
      set_surround_mode_end_line();
      up();_end_line();p_col-=1;
   } else if (word=='default') {
      replace_line(line:+':');
      _end_line();
   } else if (word=='repeat') {
      replace_line(line);
      //insert_line('');
      insert_line(indent_string(width)'until ();');
      up();_end_line();++p_col;
      //up();p_col=width+syntax_indent+1;
      rul_enter();
      set_surround_mode_end_line(p_line+1);
   } else if (word=='return') {
      replace_line(line:+' ');
      _end_line();

      doNotify = (line != orig_line);
   } else if (word=='end') {
      save_pos(p2);
      up();_end_line();
      col:=_rul_find_block_col(block_info);
      restore_pos(p2);
      newLine := '';
      if (col) {
         newLine = indent_string(col-1)orig_word' ';
         replace_line(newLine);
         _end_line();
      } else {
         newLine = line;
         replace_line(newLine);
         _end_line();++p_col;
      }
      doNotify = (newLine != orig_line);
   } else if (word=='else') {
      save_pos(p2);
      col:=_rul_find_block_col(block_info);
      restore_pos(p2);
      newLine := '';
      if (col) {
         newLine = indent_string(col-1)orig_word;
      } else {
         newLine = line;
      }
      replace_line(line);
      _end_line();++p_col;
      doNotify = (newLine != orig_line);
   } else if (word=='elseif') {
      save_pos(p2);
      col:=_rul_find_block_col(block_info);
      restore_pos(p2);
      if (col) {
         replace_line(indent_string(col-1)orig_word'  then');
      } else {
         replace_line(line'  then');
      }
      _end_line();p_col-=5;
   } else if (word=='for') {
      replace_line(line:+'  step 1');
      insert_line(indent_string(width)'endfor;');
      set_surround_mode_end_line();
      up();_end_line();p_col-=7;
   } else if (word=='program') {
      replace_line(line);
      //insert_line('');
      insert_line(indent_string(width)'endprogram');
      up();_end_line();++p_col;
      rul_enter();
   } else if (word=='function') {
      replace_line(line);
      //insert_line('');
      insert_line(indent_string(width)'begin');
      insert_line(indent_string(width)'end;');
      up(2);_end_line();++p_col;
   } else if (word=='prototype') {
      replace_line(line);
      _end_line();++p_col;
      doNotify = (line != orig_line);
   } else if (word=='typedef') {
      replace_line(line);
      insert_line(indent_string(width)'begin');
      insert_line(indent_string(width)'end;');
      up(2);_end_line();++p_col;
   } else if (word=='begin') {
      save_pos(p2);
      col:=_rul_find_block_col(block_info);
      restore_pos(p2);
      if (col) {
         replace_line(indent_string(col-1)orig_word);
         insert_line(indent_string(col-1)'end;');
         _end_line();++p_col;
      } else {
         replace_line(line);
         insert_line(indent_string(width)'end;');
         _end_line();++p_col;
      }
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else {
     status=1;
     doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}
int _rul_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,rul_space_words);
}
/*
    Returns true if nothing is done
*/
boolean _rul_expand_enter()
{
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   int col=0;
   _str block_info="";
   _str line="";
   get_line(line);
   if ((line=='else' || line=='begin') && p_col==_text_colc()+1) {
      col=_rul_find_block_col(block_info);
      if (col) {
         replace_line(indent_string(col-1)strip(line));_end_line();
         save_pos(p);
      }

   }

   int begin_col=rul_begin_stat_col(false /* No RestorePos */,
                              false /* Don't skip first begin statement marker */,
                              false /* Don't return first non-blank */,
                              1  /* Return 0 if no code before cursor. */,
                              false,
                              1
                              );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(1);
   }
   restore_pos(p);
   col=rul_indent_col(0);
   indent_on_enter(0,col);
   return(0);
}

/*

   while expr
   endwhile;
   repeat
   until expr;

   if expr goto name;

   if expr then
   elseif
   else
   endif
   program
   endprogram
   switch expr
   endswitch
   function name(a,b,c)
   begin
   end;
   typedef name
   begin
   end

*/
int _rul_find_block_col(_str &block_info /* currently just block word */)
{
   typeless orig_pos;
   save_pos(orig_pos);
   int nesting;
   nesting=1;
   _str word="";
   //event|end|case|if|while|for|begin|class|interface
   _str beginend_word_re='while|endwhile|repeat|until|if|endif|program|endprogram|switch|endswitch|function|begin|end|typedef';
   typeless status=search(beginend_word_re,'@-wrhxcs');
   //status=search('xxx','@-wrxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      word=lowcase(get_match_text());
      switch (word) {
      case 'while':
      case 'repeat':
      case 'program':
      case 'switch':
         --nesting;
         break;
      case 'endwhile':
      case 'until':
      case 'endprogram':
      case 'endswitch':
         ++nesting;
         break;
      case 'if':
         // Could have "if expr then" or "if expr goto" or may be
         // the user has not finished typing in the statement.
         typeless orig_p2;
         save_pos(orig_p2);
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         right();
         status=search('then|;|goto|'beginend_word_re,'@wrhxcs');
         word=get_match_text();
         restore_search(p1,p2,p3,p4);
         restore_pos(orig_p2);
         if (!status) {
             if (word=='then') {
                --nesting;
             }
         }
         break;
      case 'function':
      case 'typedef':
         if (nesting>0) {
            nesting=0;
         }
         break;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         typeless junk=0;
         block_info=cur_word(junk);
         first_non_blank();
         int col=p_col;
         restore_pos(orig_pos);
         return(col);
      }
      status=repeat_search();
   }
}

/*


   while expr
   endwhile;
   repeat
   until expr;

   if expr goto name;

   if expr then
   elseif
   else
   endif
   program
   endprogram
   switch expr
   endswitch
   function name(a,b,c)
   begin
   end;
   typedef name
   begin
   end

   Return beginning of statement column.  0 if not found.

*/
static int rul_begin_stat_col(boolean RestorePos,boolean SkipFirstHit,boolean ReturnFirstNonBlank,
                              boolean FailIfNoPrecedingText=false, boolean AlreadyRecursed=false,
                              boolean FailWithMinus1_IfNoTextAfterCursor=false)
{

   int orig_linenum=p_line;
   int orig_col=p_col;
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   save_pos(auto p);
   typeless status=search('[;:]|then|else|elseif|begin|program|function|typedef|end|endprogram','-Rh@xcs');
   int cfg=0;
   int nesting=0;
   boolean hit_top=false;
   int MaxSkipPreprocessing=RUL_MAXSKIPPREPROCESSING;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         cfg=_clex_find(0,'g');
         if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (SkipFirstHit || nesting) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (_in_c_preprocessing()) {
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
         _str ch=get_text();
         if (!AlreadyRecursed && ch:==':') {
            save_pos(auto p2);
            int col=rul_begin_stat_col(false,true,false,false,1);
            typeless junk=0;
            _str word=cur_word(junk);
            if (word=='case' || word=='default') {
               restore_pos(p2);
               right();
            }
         } else {
            if (isalpha(ch)) {
               if(cfg!=CFG_KEYWORD) {
                  FailIfNoPrecedingText=false;
                  status=repeat_search();
                  continue;
               }
               _str word=cur_word(auto junk);
               if (word=='then' || word=='begin') {
                  p_col+=length(word);
               }
            } else {
               right();
            }
         }
      }
      status=_clex_skip_blanksNpp();
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
         first_non_blank();
      }
      int col=p_col;
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
   int begin_stat_col=rul_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker */,
                                   true  /* Don't return first non-blank */
                                   );

   int col=0;
   if (begin_stat_col && (p_line<orig_linenum ||
                          (p_line==orig_linenum && p_col<=orig_col)
                         )
      ) {
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
      _str ch=get_text();
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
   }
   restore_pos(p);
   get_line(auto line);line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   first_non_blank();
   col=p_col;
   restore_pos(p);
   return(col);
}
static int HandlePartialStatement(int statdelim_linenum,
                                  int sameline_indent,
                                  int nextline_indent,
                                  int orig_linenum,int orig_col)
{
   _str orig_ch=get_text();
   typeless orig_pos;
   save_pos(orig_pos);
   //linenum=p_line;col=p_col;

   int begin_stat_col=rul_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker. */,
                                   false /* Don't return first non-blank */,
                                   false,
                                   false,
                                   1   // Fail if no text after cursor
                                   );
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=rul_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */
                                      );
      save_pos(auto p);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      _str ch=get_text();
#if 0
      if (ch:==")") {
         return(begin_stat_col);
      }
#endif
      restore_pos(p);
      /*
         IF semicolon is on same line as extra characters

         Example
            then b=<ENTER>
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
      int col=p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ch!=',') {
         return(col);
      }
      return(col+nextline_indent);
   }
   return(0);
}
/*
   This code is just here incase we get fancy
*/
int rul_indent_col(int non_blank_col, boolean pasting_open_block = false)
{
   int orig_col=p_col;
   int orig_linenum=p_line;
   save_pos(auto p);
// updateAdaptiveFormatttingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   // IF user does not want syntax indenting
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }

   typeless p2=0;
   typeless junk=0;
   _str word="";
   _str line="";
   _str word1="";
   _str word2="";
   int col=0;
   int begin_stat_col=0;
   int nesting=0;
   int OpenParenCol=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   typeless status=search('[;:()]|then|else|elseif|begin|program|function|typedef|end|endprogram|while|switch|if|for|repeat','-Rh@xcs');
   for (;;) {
      if (status) {
         if (nesting<0) {
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      _str ch=get_text();
      switch (ch) {
      case '(':
         if (!nesting && !OpenParenCol) {
            save_pos(auto p3);
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
      if (_in_c_preprocessing()) {
         begin_line();
         status=repeat_search();
         continue;
      }
      word=get_match_text();
      if (word!=';' && word!=':' && word!=cur_word(junk)) {
         status=repeat_search();
         continue;
      }
      word=lowcase(word);

      //messageNwait("c_indent_col2: ch="ch);
      switch (word) {
      case ';':
         //messageNwait("case ;");
         save_pos(p2);
         int statdelim_linenum=p_line;
         begin_stat_col=rul_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */
                                    );
         get_line(line);
         parse lowcase(line) with word1 word2 ';';
         if ((word1=='begin' && word2!='class') || word1=='program') {
            begin_stat_col+=syntax_indent;
         }
         restore_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p);
         return(begin_stat_col);
      case ':':
         //messageNwait("case :");
         if (p_col!=1) {
            left();
            if (get_text()==":") {
               status=repeat_search();
               continue;
            }
            right();
         }

         save_pos(p2);

         /* Now check if there are any characters between the
            beginning of the previous statement and the original
            cursor position

            Could have
             case 'a':
                 int i,<ENTER>
         */
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }

         restore_pos(p2);


         /*

             default:<ENTER>
             case ???:<ENTER>
             (abc)? a: b;<ENTER>
         */
         begin_stat_col=c_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */,
                                    1
                                    );

         if (p_line==orig_linenum) {
            word=cur_word(junk);
            if (word=='case' || word=='default') {
               first_non_blank();
               // IF the 'case' word is the first non-blank on this line
               if (p_col==begin_stat_col) {
                  col=p_col;
                  restore_pos(p);
                  return(col);
               }
            }
         }
         restore_pos(p);
         return(begin_stat_col+syntax_indent);
      case 'then':

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
         search('if','-@hwxcs');
         /*  IF expression THEN

         */
         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);

      /*
         For the words below, we indent based on the first
         non-blank.
      */
      case 'else':
      case 'elseif':
      case 'begin':
      case 'program':
      case 'function':
      case 'typedef':
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

         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);
      case 'end':
      case 'endprogram':
         first_non_blank();
         col=p_col;
         restore_pos(p);
         return(col);
      case 'while':
      case 'switch':
      case 'if':
      case 'for':
      case 'repeat':
         /*
            Cases
              while ()
                 if () <ENTER>
              switch <ENTER>
         */
         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);
      default:
         _message_box('unknown word='word);
      }
      status=repeat_search();
   }

}
int rul_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   _str first_line="";
   get_line(first_line);
   int i=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!='' && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   int status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!='') || (!status && comment_col!='' && p_col!=comment_col)) {
      return(0);
   }

   typeless enter_col=0;
   typeless block_info="";
   typeless p2=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   typeless junk=0;
   _str word=lowcase(cur_word(junk));
   if (!status && (word=='end' || word=='endprogram' || word=='elseif' ||
                   word=='else' || word=='until' || word=='case' || word=='default')) {
      //messageNwait('it was an end');
      save_pos(p2);
      up();_end_line();
      enter_col=_rul_find_block_col(block_info);
      restore_pos(p2);
      if (enter_col && word=='case') {
         updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
         if (p_indent_case_from_switch) {
            enter_col+=p_SyntaxIndent;
         }
      }
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
   } else {
      _begin_select();get_line(first_line);up();
      _end_line();
      save_pos(p2);
      // Check if we are pasting into the middle of an SQL or start task statement
      int begin_col=rul_begin_stat_col(false /* No RestorePos */,
                                 false /* Don't skip first begin statement marker */,
                                 false /* Don't return first non-blank */,
                                 1  /* Return 0 if no code before cursor. */,
                                 false,
                                 1
                                 );
      restore_pos(p2);
      enter_col=rul_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && !allow_col_1) || enter_col=='' ||
      (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static _str rul_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      rul_enter_col2(enter_col) ) {
      return('');
   }
   return(enter_col);
}


static boolean rul_enter_col2(int &enter_col)
{
   enter_col=rul_indent_col(0);
   return(0);
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
int _rul_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * Find a list of tags matching the given identifier after
 * evaluating the prefix expression.
 * 
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param prefixexp           prefix of expression (from _[ext]_get_expression_info
 * @param lastid              last identifier in expression
 * @param lastidstart_offset  seek position of last identifier
 * @param info_flags          bitset of VS_CODEHELPFLAG_*
 * @param otherinfo           used in some cases for extra information
 *                            tied to info_flags
 * @param find_parents        for a virtual class function, list all
 *                            overloads of this function
 * @param max_matches         maximum number of matches to locate
 * @param exact_match         if true, do an exact match, otherwise
 *                            perform a prefix match on lastid
 * @param case_sensitive      if true, do case sensitive name comparisons
 * @param visited             hash table of prior results
 * @param depth               depth of recursive search
 * 
 * @return  The number of matches found or <0 on error 
 *          (one of VSCODEHELPRC_*, errorArgs must be set).
 */
int _rul_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match,boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                               info_flags,otherinfo,find_parents,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,visited,depth);
}

/*
 <B>Purpose</B>
    Context Tagging&reg; hook function for function help.  Finds the start
    location of a function call and the function name.
 <B>Parameters</B>
    <CODE>errorArgs                </CODE>array of strings for error message arguments
    <CODE>                         </CODE>refer to codehelp.e VSCODEHELPRC_*
    <CODE>OperatorTyped            </CODE>When true, user has just typed last
    <CODE>                         </CODE>character of operator.
    <CODE>                         </CODE>Example: <CODE>p-></CODE><Cursor Here>
    <CODE>                         </CODE>This should be false if cursorInsideArgumentList is true.
    <CODE>cursorInsideArgumentList </CODE>When true, user requested function help
    <CODE>                         </CODE>when the cursor was inside an argument list.
    <CODE>                         </CODE>Example: <CODE>MessageBox(...,</CODE><Cursor Here><CODE>...)</CODE>
    <CODE>                         </CODE>Here we give help on MessageBox
    <CODE>FunctionNameOffset       </CODE>(reference) Offset to start of function name.
    <CODE>ArgumentStartOffset      </CODE>(reference) Offset to start of first argument
    <CODE>flags                    </CODE>(reference) function help flags
 <B>Returns</B>
    0    Successful
    VSCODEHELPRC_CONTEXT_NOT_VALID
    VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
    VSCODEHELPRC_NO_HELP_FOR_FUNCTION
*/
int _rul_fcthelp_get_start(_str (&errorArgs)[],
                           boolean OperatorTyped,
                           boolean cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags
                          )
{
   return _c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags);
}

/*
 <B>Purpose</B>
    Context Tagging&reg; hook function for retrieving the information about
    each function possibly matching the current function call that
    function help has been requested on.

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
          FunctionHelp_list[0].return_type=0;

 <B>Parameters</B>
    <CODE>errorArgs                 </CODE>array of strings for error message arguments
    <CODE>                          </CODE>refer to codehelp.e VSCODEHELPRC_*
    <CODE>FunctionHelp_list         </CODE>Structure is initially empty.
    <CODE>                          </CODE>FunctionHelp_list._isempty()==true
    <CODE>                          </CODE>You may set argument lengths to 0.
    <CODE>                          </CODE>See VSAUTOCODE_ARG_INFO structure in slick.sh.
    <CODE>FunctionHelp_list_changed </CODE>(reference)Indicates whether the data in
    <CODE>                          </CODE>FunctionHelp_list has been changed.
    <CODE>                          </CODE>Also indicates whether current
    <CODE>                          </CODE>parameter being edited has changed.
    <CODE>FunctionHelp_cursor_x     </CODE>(reference) Indicates the cursor x position
    <CODE>                          </CODE>in pixels relative to the edit window
    <CODE>                          </CODE>where to display the argument help.
    <CODE>FunctionNameStartOffset   </CODE>The text between this point and
    <CODE>                          </CODE>ArgumentEndOffset needs to be parsed
    <CODE>                          </CODE>to determine the new argument help.
    <CODE>ArgumentEndOffset         </CODE>see FunctionNameStartOffset (above)
    <CODE>flags                     </CODE>function help flags (from fcthelp_get_start)

 <B>Returns</B>
    Returns 0 if we want to continue with function argument
    help.  Otherwise a non-zero value is returned and a
    message is usually displayed.
       1   Not a valid context
       2-9  (not implemented yet)
       10   Context expression too complex
       11   No help found for current function
       12   Unable to evaluate context expression
*/
int _rul_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   boolean &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth);
}

/*
 <B>Purpose</B>
    Merges prototypes (which have argument signatures only
    with functions (which have argument names only) for display
    using function help.
 <B>Parameters</B>
    <CODE>match_list                </CODE>array of function info of the form
    <CODE>                          </CODE>func_name \t type \t sig \t returns
*/
void _rul_merge_and_remove_duplicates(_str (&match_list)[])
{
   _str name1="", type1="", sig1="", ret1="", duplist1="", part1="", arg1="";
   _str name2="", type2="", sig2="", ret2="", duplist2="", part2="", arg2="";
   typeless j1="", j2="";
   int i=1;
   while (i<match_list._length()) {
      _str item1=match_list[i];
      _str item2=match_list[i-1];
      parse item1 with name1 "\t" type1 "\t" sig1 "\t" ret1"\t"j1"\t"duplist1;
      parse item2 with name2 "\t" type2 "\t" sig2 "\t" ret2"\t"j2"\t";
      if (name1:==name2) {

         parse sig1 with part1 ',' .;
         part1=strip(stranslate(part1,"","POINTER|BYREF",'rw'));
         if (pos(' ',part1)) {
            match_list[i-1]=item1;
            match_list[i]=item2;
            i++;
            continue;
         }
         parse sig2 with part2 ',' .;
         part2=strip(stranslate(part2,"","POINTER|BYREF",'rw'));
         if (pos(' ',part2)) {
            i++;
            continue;
         }

         if (type1=='proto' && type2=='func') {
            name2=sig2;
            sig2=sig1;
            sig1=name2;
            type1=type2;
         } else if (type1=='func' && type2=='proto') {
         } else {
            i++;
            continue;
         }

         _str sig_types[]; sig_types._makeempty();
         _str sig_names[]; sig_names._makeempty();
         while (sig1!='') {
            parse sig1 with arg1 ',' sig1;
            sig_names[sig_names._length()]=strip(arg1);
         }
         while (sig2!='') {
            parse sig2 with arg1 ',' sig2;
            sig_types[sig_types._length()]=strip(arg1);
         }
         if (sig_types._length()==sig_names._length()) {
            sig1='';
            if (sig_types._length()>0) {
               sig1=sig_types[0]' 'sig_names[0];
            }
            int j;
            for (j=1; j<sig_types._length(); j++) {
               strappend(sig1,', 'sig_types[j]' 'sig_names[j]);
            }
            match_list._deleteel(i);
            match_list[i-1]=name1"\tfunc\t"sig1"\t"ret1"\t"j1"\t"duplist1" "j2;
            i=i+2;
         }
      }
      i++;
   }
}

// Since InstallScript functions only have the variable names in
// the signature, not their types, we need this in order to locate
// the corresponding function prototype in the database and find
// the return types of each parameter.
// 
// This function does not require synchronization for accessing
// the context because it is only called from _UpdateLocals()
// which already will have an exclusive write-only lock on the locals.
//
void _rul_after_UpdateLocals()
{
   // find the current function name
   int context_id = tag_current_context();
   if (context_id <= 0) {
      return;
   }
   _str func_name="", type_name="", func_args="";
   tag_get_detail2(VS_TAGDETAIL_context_name,context_id,func_name);
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
   tag_get_detail2(VS_TAGDETAIL_context_args,context_id,func_args);
   if ((type_name != 'func' && type_name != 'proto') || func_args == '') {
      return;
   }

   // func looking for proto or proto looking for func?
   _str search_type = 'proto';
   if (type_name == 'proto') {
      search_type = 'func';
   }

   // try to find corresponding prototype in current context
   _str alt_args='';
   _str alt_type='';
   int alt_id=tag_find_context_iterator(func_name,true,true);
   while (alt_id>0) {
      tag_get_detail2(VS_TAGDETAIL_context_args,alt_id,alt_args);
      tag_get_detail2(VS_TAGDETAIL_context_type,alt_id,alt_type);
      if (alt_type==search_type && alt_args!='') {
         break;
      }
      alt_args='';
      alt_id=tag_next_context_iterator(func_name,alt_id,true,true);
   }

   // nothing found in current context, try tag files
   int i,n=0;
   if (alt_args=='') {
      typeless tag_files=tags_filenamea('rul');
      for (i=0;;i++) {
         _str tag_filename=next_tag_filea(tag_files,i,false,true);
         if (tag_filename=='') {
            break;
         }
         int status=tag_find_tag(func_name,search_type,'');
         while (!status) {
            tag_get_detail(VS_TAGDETAIL_arguments,alt_args);
            if (alt_args!='') {
               break;
            }
            status=tag_next_tag(func_name,search_type,'');
         }
         tag_reset_find_tag();
      }
   }
   if (alt_args=='') {
      return;
   }

   // save/append the current locals to an array
   _str argument="";
   VS_TAG_BROWSE_INFO outer_locals[];
   outer_locals._makeempty();
   n=tag_get_num_of_locals();
   for (i=1; i<=n; i++) {
      VS_TAG_BROWSE_INFO cm;
      tag_get_local_info(i, cm);
      if (cm.type_name:=='param') {
         parse alt_args with argument ',' alt_args;
         if (search_type=='proto') {
            cm.return_type = strip(argument);
         } else if (pos("^p[0-9]*$",cm.member_name,1,'r')) {
            cm.member_name = strip(argument);
         }
      }
      outer_locals[outer_locals._length()] = cm;
   }

   // re-insert the locals
   tag_clear_locals(0);
   n=outer_locals._length();
   for (i=0; i<n; i++) {
      VS_TAG_BROWSE_INFO cm = outer_locals[i];
      _str local_sig = cm.return_type;
      if (cm.arguments!='') {
         strappend(local_sig, VS_TAGSEPARATOR_args:+cm.arguments);
      }
      int k=tag_insert_local2(cm.member_name, cm.type_name, cm.file_name,
                          cm.line_no, cm.seekpos,
                          cm.scope_line_no, cm.scope_seekpos,
                          cm.end_line_no, cm.end_seekpos,
                          cm.class_name, cm.flags, local_sig);
      if (cm.name_line_no > 0) {
         tag_set_local_name_location(k,cm.name_line_no,cm.name_seekpos);
      }
   }

   // that's all folks
   return;
}

/*
 <B>Purpose</B>
    Get installation path for InstallShield from registry.
 <B>Returns</B>
    '' if InstallShield not found, path if it is found.
*/
static _str gInstallShieldList[]={
   "Software\\InstallShield\\InstallShield Professional",
   "Software\\InstallShield\\InstallShield Express",
   "Software\\InstallShield\\InstallShield Free Edition"
};
_str _InstallShieldIncludePath()
{
#if !__UNIX__
   int i;
   for (i=0;i<gInstallShieldList._length();++i) {

      subkey := gInstallShieldList[i];

      // get the latest version number for this path
      version := '';
      status := _ntRegFindLatestVersion(HKEY_LOCAL_MACHINE, subkey, version);
//    _str name="";
//    int status=_ntRegFindVersionKeyName(HKEY_LOCAL_MACHINE,gInstallShieldList[i],0,"main",name);

      if (!status) {
         _maybe_append_filesep(subkey);
         subkey :+= version :+ FILESEP :+ 'main';
         _str path=_ntRegQueryValue(HKEY_LOCAL_MACHINE,subkey,"","Path");
         if (path!="") {
            if (last_char(path)!=FILESEP) {
               path=path:+FILESEP;
            }
            path=path:+"Include";
            if (file_match(maybe_quote_filename(path), 1)!='') {
               return(path:+FILESEP);
            }
         }
      }
   }
#endif
   return('');
}

/*
 <B>Purpose</B>
    Build tag file for InstallShield's InstallScript language
    standard header files.  Uses registry to locate InstallShield
    and tags all the headers and .rul files under their include
    directory.
 <B>Parameters</B>
    <CODE>tfindex    </CODE>Tag file index
*/
int _rul_MaybeBuildTagFile(int &tfindex)
{
   // Only works on Windows 9x and NT
   if (machine()!='WINDOWS') {
      return(1);
   }
   // maybe we can recycle tag file(s)
   _str ext='rul';
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"rultags")) {
      return(0);
   }
   // get installation path for InstallShield
   _str path=_InstallShieldIncludePath();
   _str std_libs="";
   if (path!='') {
      std_libs=maybe_quote_filename(path:+'*.h')' 'maybe_quote_filename(path:+'*.rul');
   }

   // Now build and save the tag file
   return ext_BuildTagFile(tfindex,tagfilename,ext,"InstallScript Libraries",
                           true,std_libs,ext_builtins_path(ext,ext));
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
boolean rul_is_start_block()
{
   return c_is_start_block();
}
