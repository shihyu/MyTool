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
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "cutil.e"
#import "notifications.e"
#import "optionsxml.e"
#import "se/lang/api/LanguageSettings.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*


   CASE
     WHEN
     OTHERWISE
   end case
   CONTINUE
   DECLARE xxx
   DEFINE  xxx
   FOR i= e TO e STEP 1
   END FOR
   FOREACH I INTO
   END FOREACH
   FUNCTION NAME(a,b,c
   END FUNCTION
   EXIT
   GLOBALS
   GOTO label
   IF  THEN
   ELSE
   END IF
   LABEL ID:
   LET v=expr
   MAIN
     statement
   END MAIN
   MENU name
   END MENU
   INPUT
   END INPUT
   PROMPT
   END PROMPT
   REPORT
   END REPORT
   WHILE
   END WHILE

INSTALLATION:

    -  Load this macro module with LOAD command (MENU, "Macro", "Load").
    -  Save the configuration. (CONFIG,Save configuration...)

  Options for 4GL syntax expansion/indenting may be accessed from the
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 1.
       3             Indent CASE from DO CASE.  Default is 0.  Specify
                     1 if you want CASE statements indented from the
                     DO CASE.
       4             reserved.
       5             reserved.


*/

static const GL_MODE_NAME= 'GL';
static const GL_LANGUAGE_ID='gl';

defeventtab gl_keys;
def ' '= gl_space;
def 'ENTER'= gl_enter;

/**
 * @deprecated Use {@link_word_case} instead
 */
_str _gl_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}
_command gl_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(GL_LANGUAGE_ID);
}

_command void gl_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_gl_expand_enter);
}
bool _gl_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
_command gl_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      gl_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}
static const GL_ENTER_WORDS=(' case for foreach function if main menu input prompt ':+\
                     'report when while ');
static const GL_ENTER_WORDS2= '';
static const GL_EXPAND_WORDS= ' continue declare define exit globals goto label let ';
static const GL_EXPAND_WORDS2= '';

static SYNTAX_EXPANSION_INFO gl_space_words:[] = {
   'case'      => { "CASE ... END CASE" },
   'continue'  => { "CONTINUE" },
   'declare'   => { "DECLARE" },
   'define'    => { "DEFINE" },
   'exit'      => { "EXIT" },
   'for'       => { "FOR ... = ... TO ... STEP 1 ... END FOR" },
   'foreach'   => { "FOREACH ... INTO ... END FOREACH" },
   'function'  => { "FUNCTION ... END FUNCTION" },
   'globals'   => { "GLOBALS" },
   'goto'      => { "GOTO" },
   'if'        => { "IF ... END IF" },
   'label'     => { "LABEL" },
   'let'       => { "LET" },
   'main'      => { "MAIN ... END MAIN" },
   'menu'      => { "MENU ... END MENU" },
   'input'     => { "INPUT ... END INPUT" },
   'prompt'    => { "PROMPT ... END PROMPT" },
   'report'    => { "REPORT ... END REPORT" },
   'while'     => { "WHILE ... END WHILE" },
};

/* Returns non-zero number if fall through to enter key required */
bool _gl_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   status := 0;
   line := "";
   get_line(line);
   orig_first_word := rest := before := "";
   width := indent := 0;
   parse line with orig_first_word rest;
   first_word := lowcase(orig_first_word);
   if ( pos(' 'first_word' ',GL_ENTER_WORDS) || pos(' 'first_word' ',GL_ENTER_WORDS2) ) {
      if ( first_word=='for' && name_on_key(ENTER)=='nosplit-insert-line' ) {
         /* tab to fields of pascal for statement */
         line=expand_tabs(line);
         parse lowcase(line) with before '=';
         if ( length(before)+1>=p_col ) {
            p_col=length(before)+3;
         } else {
            parse lowcase(line) with before 'to';
            if ( length(before)>=p_col ) {
               p_col=length(before)+4;
            } else {
               indent_on_enter(syntax_indent);
            }
         }
      } else if ( first_word=='case' && expand ) {
         width=text_col(strip(line,'T'));
         indent=0;
         if ( indent_case ) {
            indent=syntax_indent;
         }
         indent_on_enter(indent);
         get_line(line);
         if ( line=='' ) {
            /* check if endcase has been typed */
            i := 1;
            for (;;) {
               status=down();
               if ( status ) {
                  up(i-1);
                  break;
               }
               temp := "";
               get_line(temp);
               w := "";
               parse temp with w .;
               if ( lowcase(w)=='when' || lowcase(w)=='end' ) {
                  up(i);
                  break;
               }
               if ( temp!='' || i>=10 ) {
                  up(i);
                  status=1;
                  break;
               }
               i++;
            }
            if ( status ) {  /* endcase or case not found? */
              replace_line(indent_string(width+indent-8)_word_case('when',false,orig_first_word));
              insert_line(indent_string(width-8)_word_case('end',false,orig_first_word):+' ':+_word_case('case',false,orig_first_word));
              up();get_line(line);p_col=text_col(line)+2;

              // notify user that we did something unexpected
              notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

              return(false);
            }
            replace_line(indent_string(width+indent-8)_word_case('when',false,orig_first_word));
            get_line(line);p_col=text_col(line)+2;
            /* if not insert_state() then insert_toggle endif */
         }
      } else if ( first_word=='when' ) {
         /* align WHEN with CASE */
         /* does nothing when in nested switches */
         typeless p=point();
         typeless ln=point('L');
         cl := p_col;
         left_edge := p_left_edge;
         cursor_y := p_cursor_y;
         status2 := search('^[ \t]*\ccase','rhi-@');
         col := p_col;
         goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
         if ( ! status2 ) {
            if ( indent_case ) {
               col += syntax_indent;
            }
            line=strip(line,'L');
            replace_line(indent_string(col-1):+_word_case('when',false,orig_first_word):+substr(line,5));
            _end_line();
         }
         indent_on_enter(syntax_indent);
      } else {
         indent_on_enter(syntax_indent);
      }
   } else {
     status=1;
   }

   if (!status) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status != 0);

}
static _str gl_expand_space()
{
   status := 0;
   tline := "";
   get_line(tline);
   line := strip(tline,'T');
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   word := strip(tline,'L');
   int i=verify(line,'0123456789');  /* Skip the linenumbers */
   if ( ! i ) {
      return(1);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;

   sample := strip(substr(line,i));
   orig_word := lowcase(strip(substr(line,i)));
   //words=SPACE_WORDS
   //word=min_abbrev(orig_word,words,'')
   aliasfilename := "";
   col := 0;
   line_prefix := "";
   word=min_abbrev2(orig_word,gl_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   set_surround_mode_start_line();
   if ( word=='' ) return(1);

   // sometimes, we expand, but we only add a space - do not notify 
   // user of syntax expansion
   doNotify := true;

   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   if ( word=='case' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('case',false,sample));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     _end_line();
   } else if ( word=='for' ) {
     replace_line(_word_case(line):+' =  ':+_word_case('to ',false,sample):+' ':+_word_case('step 1',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('for',false,sample));
     set_surround_mode_end_line();
     up();p_col=width+5;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='foreach' ) {
     replace_line(_word_case(line):+'  ':+_word_case('into ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('foreach',false,sample));
     set_surround_mode_end_line();
     up();p_col=width+9;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='function' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('function',false,sample));
     up();p_col=width+10;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='if' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('if',false,sample));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='main' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('main',false,sample));
     up(1);
     insert_line('');
     p_col=width+syntax_indent+1;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='menu' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('menu',false,sample));
     up(1);p_col=width+6;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='input' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('input',false,sample));
     up(1);p_col=width+7;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='prompt' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('prompt',false,sample));
     up(1);p_col=width+8;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='report' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('report',false,sample));
     up(1);p_col=width+8;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='while' ) {
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('while',false,sample));
     set_surround_mode_end_line();
     up();p_col=width+7;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( pos(' 'word' ',GL_EXPAND_WORDS) || pos(' 'word' ',GL_EXPAND_WORDS2) ) {
      newLine := indent_string(width)_word_case(word,false,sample)' ';
      replace_line(newLine);
      _end_line();

      // compare what we did to the original
      if (newLine == tline) {
         doNotify = false;
      }
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
int _gl_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,gl_space_words,0);
}

int gl_proc_search(_str &proc_name, int find_first)
{
   return _generic_regex_proc_search('^[ \t]*(function):b<<<NAME>>>[ \t]*([(]<<<ARGS>>>[)]|$)', proc_name, find_first!=0, "func");
}
