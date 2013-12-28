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

#define GL_MODE_NAME    'GL'
#define GL_LANGUAGE_ID  'gl'

defload()
{
   _str setup_info='MN='GL_MODE_NAME',TABS=1 8 250 +4,MA=1 74 1,':+
                   'KEYTAB='GL_MODE_NAME'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=GL,CF=1';
   _str compile_info='';
   _str syntax_info='3 1 1 1 0 1 0';
   _str be_info='(if),(case),(for),(foreach),(function),(main),(menu)(input)(prompt)(while)(report)|(end);i';

   _CreateLanguage(GL_LANGUAGE_ID, GL_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('gl', GL_LANGUAGE_ID);
   _CreateExtension('4gl', GL_LANGUAGE_ID);
   _CreateExtension('p4gl', GL_LANGUAGE_ID);
}

/**
 * @deprecated Use {@link_word_case} instead
 */
_str _gl_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
}
_command gl_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(GL_LANGUAGE_ID);
}

_command void gl_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_gl_expand_enter);
}
_command gl_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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
#define GL_ENTER_WORDS (' case for foreach function if main menu input prompt ':+\
                     'report when while ')
#define GL_ENTER_WORDS2 ''
#define GL_EXPAND_WORDS ' continue declare define exit globals goto label let '
#define GL_EXPAND_WORDS2 ''

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
boolean _gl_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   status := 0;
   _str line='';
   get_line(line);
   _str orig_first_word='', rest='', before='';
   int width=0, indent=0;
   parse line with orig_first_word rest;
   _str first_word=lowcase(orig_first_word);
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
            int i=1;
            for (;;) {
               status=down();
               if ( status ) {
                  up(i-1);
                  break;
               }
               _str temp='';
               get_line(temp);
               _str w='';
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
               i=i+1;
            }
            if ( status ) {  /* endcase or case not found? */
              replace_line(indent_string(width+indent-8)_word_case('when'));
              insert_line(indent_string(width-8)_word_case('end'):+' ':+_word_case('case'));
              up();get_line(line);p_col=text_col(line)+2;

              // notify user that we did something unexpected
              notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

              return(false);
            }
            replace_line(indent_string(width+indent-8)_word_case('when'));
            get_line(line);p_col=text_col(line)+2;
            /* if not insert_state() then insert_toggle endif */
         }
      } else if ( first_word=='when' ) {
         /* align WHEN with CASE */
         /* does nothing when in nested switches */
         typeless p=point();
         typeless ln=point('L');
         int cl=p_col;
         int left_edge=p_left_edge;
         int cursor_y=p_cursor_y;
         int status2=search('^[ \t]*\ccase','rhi-@');
         int col=p_col;
         goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
         if ( ! status2 ) {
            if ( indent_case ) {
               col=col+syntax_indent;
            }
            line=strip(line,'L');
            replace_line(indent_string(col-1):+_word_case('when'):+substr(line,5));
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
   int status=0;
   _str tline='';
   get_line(tline);
   _str line=strip(tline,'T');
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str word=strip(tline,'L');
   int i=verify(line,'0123456789');  /* Skip the linenumbers */
   if ( ! i ) {
      return(1);
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;

   _str orig_word=lowcase(strip(substr(line,i)));
   //words=SPACE_WORDS
   //word=min_abbrev(orig_word,words,name_info(p_index))
   _str aliasfilename='';
   int col=0;
   _str line_prefix='';
   word=min_abbrev2(orig_word,gl_space_words,name_info(p_index),aliasfilename);

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
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('case'));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     _end_line();
   } else if ( word=='for' ) {
     replace_line(_word_case(line):+' =  ':+_word_case('to '):+' ':+_word_case('step 1'));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('for'));
     set_surround_mode_end_line();
     up();p_col=width+5;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='foreach' ) {
     replace_line(_word_case(line):+'  ':+_word_case('into '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('foreach'));
     set_surround_mode_end_line();
     up();p_col=width+9;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='function' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('function'));
     up();p_col=width+10;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='if' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('if'));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='main' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('main'));
     up(1);
     insert_line('');
     p_col=width+syntax_indent+1;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='menu' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('menu'));
     up(1);p_col=width+6;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='input' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('input'));
     up(1);p_col=width+7;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='prompt' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('prompt'));
     up(1);p_col=width+8;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='report' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('report'));
     up(1);p_col=width+8;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='while' ) {
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('while'));
     set_surround_mode_end_line();
     up();p_col=width+7;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( pos(' 'word' ',GL_EXPAND_WORDS) || pos(' 'word' ',GL_EXPAND_WORDS2) ) {
      newLine := indent_string(width)_word_case(word)' ';
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

_str gl_proc_search(_str &proc_name, int find_first)
{
   if ( find_first ) {
      if ( proc_name:=='' ) {
          proc_name=_clex_identifier_re();
      }
      search('^[ \t]*(function):b\c'proc_name'[ \t]*([(]|$)','@rih');
   } else {
      repeat_search();
   }
   if ( rc ) {
      return(rc);
   }
   _str line='';
   get_line(line);
   line=expand_tabs(line);
   int p=pos('([ \t(]|$)',line,p_col,'r');
   /* Parse out the name.  Cursor is on first character of name. */
   proc_name=substr(line,p_col,p-p_col);
   return(0);
}
