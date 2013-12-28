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
#require "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "adaptiveformatting.e"
#import "autocomplete.e"
#import "codehelp.e"
#import "cutil.e"
#import "notifications.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
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
_str _for_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
}
#define FOR_MODE_NAME   'Fortran'
#define FOR_LANGUAGE_ID 'for'

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

defeventtab fortran_keys;
def  ' '= fortran_space;
def  'ENTER'= fortran_enter;

defload()
{
   _str setup_info='MN='FOR_MODE_NAME',TABS=1 7 250 +3,MA=1 74 1,':+
                   'KEYTAB='FOR_MODE_NAME'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',':+
                   'IN=2,WC=A-Za-z0-9_$,LN=Fortran,CF=1,';
   _str compile_info='400 lp77 *';
   _str syntax_info='3 1 1 0 0 1 0';
   _str be_info='';
   _CreateLanguage(FOR_LANGUAGE_ID, FOR_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('f', FOR_LANGUAGE_ID);
   _CreateExtension('for', FOR_LANGUAGE_ID);
   _CreateExtension('f90', FOR_LANGUAGE_ID);
   _CreateExtension('f95', FOR_LANGUAGE_ID);
}

_command fortran_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(FOR_LANGUAGE_ID);
}
_command void fortran_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_fortran_expand_enter);
}
_command fortran_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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
#define FOR_ENTER_WORDS ' do if else '
#define FOR_ENTER_WORDS2 ''
#define FOR_EXPAND_WORDS ' allocatable continue else inquire pointer return '

static SYNTAX_EXPANSION_INFO fortran_space_words:[] = {
   'allocatable' => { "allocatable" },
   'close'       => { "close" },
   'continue'    => { "continue" },
   'else'        => { "else" },
   'format'      => { "format( ... )" },
   'function'    => { "function ... end function " },
   'if'          => { "if ( ... )" },
   'inquire'     => { "inquire( ... )" },
   'integer'     => { "integer" },
   'module'      => { "module ... end module" },
   'open'        => { "open( ... )" },
   'pointer'     => { "pointer" },
   'program'     => { "program ... end program " },
   'read'        => { "read( ... )" },
   'return'      => { "return" },
   'subroutine'  => { "subroutine ... end subroutine " },
   'write'       => { "write( ... )" },
};

/* Returns non-zero number if fall through to enter key required */
boolean _fortran_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   _str line='';
   get_line(line);
   int i=verify(line,'0123456789')  /* Skip the linenumbers */;
   if ( ! i ) {
      i=7;
   }
   _str orig_first_word='';
   _str rest='';
   _str maybe_rest='';
   parse substr(line,i) with orig_first_word rest;
   if (pos(':',orig_first_word)) {
      // This is a label, see if we can do better
      parse rest with next_word maybe_rest;
      if (next_word!='') {
         orig_first_word=next_word;
         rest=maybe_rest;
      }
   }

   // In case we have "if( expr ) then", parse off parens
   int p=pos('\(|\)',orig_first_word,1,'r');
   if (p && p>1) {
      orig_first_word=substr(orig_first_word,1,p-1);
   }
   int old_col=0;
   int new_col=0;
   _str first_word=lowcase(orig_first_word);
   if ( (pos(' 'first_word' ',FOR_ENTER_WORDS) || pos(' 'first_word' ',FOR_ENTER_WORDS2)) &&
       (first_word!='if' || pos('then',line,1,'i')) ) {
      old_col=p_col;
      p_col=verify(line,' ','',i);
      tab();
      new_col=p_col;p_col=old_col;
      indent_on_enter(syntax_indent);
   } else {
      if ( first_word!='' ) {
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
   _str next_line='';
   get_line(next_line);
   if ( p_col<new_col ) {
      int diff=new_col-p_col;
      if ( next_line!='' ) {
         replace_line(substr('',1,diff):+next_line);
      }
      p_col=p_col+diff;
   }
   return(false);

}
static _str fortran_expand_space()
{
   multi_line_if := LanguageSettings.getMultilineIfExpansion(p_LangId);
   
   typeless status=0;
   _str origLine = '';
   get_line(origLine);
   _str line=strip(origLine,'T');
   typeless i=verify(line,'0123456789')  /* Skip the linenumbers */;
   if ( ! i ) {
      return(1);
   }
   _str orig_word=lowcase(strip(substr(line,i)));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,fortran_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=='' ) return(1);
   /* Grab line number with blanks. */
   _str linenum_space=substr(line,1,verify(line,' '\t,'',i)-1);
   _str leading_space=indent_string(length(expand_tabs(linenum_space)));
   doNotify := true;
   if ( word=='if' ) {
      if ( multi_line_if ) {
         set_surround_mode_start_line();
         replace_line(linenum_space:+_word_case('if ()'):+' ':+_word_case('then'));
         insert_line(leading_space:+_word_case('endif'));
         set_surround_mode_end_line();
         up();_end_line();p_col=p_col-6;
         doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      } else {
         replace_line(linenum_space:+_word_case('if () '));
         _end_line();p_col=p_col-2;
      }
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='program' ) {
      replace_line(linenum_space:+_word_case('program '));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('program '));
      up();_end_line();
   } else if ( word=='function' ) {
      replace_line(linenum_space:+_word_case('function '));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('function '));
      up();_end_line();
   } else if ( word=='module' ) {
      replace_line(linenum_space:+_word_case('module '));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('module '));
      up();_end_line();
   } else if ( word=='subroutine' ) {
      replace_line(linenum_space:+_word_case('subroutine '));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('subroutine '));
      up();_end_line();
   // -- I/O statements -- add parentheses after keyword -- (MHP 12/1/99)
   } else if ( word=='open' ) {
      replace_line(linenum_space:+_word_case('open()'));
      _end_line();left();
   } else if ( word=='close' ) {
      replace_line(linenum_space:+_word_case('close()'));
      _end_line();left();
   } else if ( word=='inquire' ) {
      replace_line(linenum_space:+_word_case('inquire()'));
      _end_line();left();
   } else if ( word=='format' ) {
      replace_line(linenum_space:+_word_case('format()'));
      _end_line();left();
   } else if ( word=='read' ) {
      replace_line(linenum_space:+_word_case('read()'));
      _end_line();left();
   } else if ( word=='write' ) {
      replace_line(linenum_space:+_word_case('write()'));
      _end_line();left();
   } else if ( pos(' 'word' ',FOR_EXPAND_WORDS) ) {
      newLine := linenum_space:+_word_case(word' ');
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != origLine);
   } else {
      status=1;
      doNotify = false;
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
   if ( pos(substr(line,1,1),'Cc*') ) {
      return('');
   }
   int i=pos('!',line);
   if ( text_col(line,i,'I')!=6 ) {
      parse line with line '!';  /* LP77 extension */
   }
   return(line);

}
#define LINE_PREFIX_RE '^([0-9 \t][ \t]*(:d)*|)[ \t]*'
#define NAME_RE '{[A-Za-z][ A-Za-z0-9$_]*[A-Za-z0-9$_]}'
//#define PROC_RE (LINE_PREFIX_RE'[~!]*(subroutine|function|program|module) *\c'NAME_RE' *(\(|$|!|    )')
//Changed this b/c a user started his subroutines in col 1.  Also, added module for the same user.
#define PROC_RE (LINE_PREFIX_RE'[~!]*(subroutine|function|program|module) *\c'NAME_RE' *(\(|$|!|    )')

_str for_proc_search(_str &proc_name,int find_first)
{
   typeless status=0;
   if ( find_first ) {
      status=search('(subroutine|function|program|module)','@rihwxsc');
   } else {
      status=repeat_search();
   }
   _str line='';
   _str ret_proc_name='';
   for (;;) {
      if ( status ) {
         return(status);
      }
      get_line(line);
      if ( pos(PROC_RE,line,1,'ri') ) {
         _str word=get_match_text('');
         ret_proc_name=stranslate(substr(line,pos('S0'),pos('0')),'',' ');
         _str type_name='';
         switch (lowcase(word)) {
         case 'subroutine':
            type_name='proc';
            break;
         case 'function':
            type_name='func';
            break;
         case 'program':
            type_name='prog';
            break;
         case 'module':
            type_name='package';
            break;
         }
         ret_proc_name=tag_tree_compose_tag(ret_proc_name,'',type_name,0,'','');
         //pad the line with a space so that we can search for the word "end" (pos doesn't take the 'w' option)
         line=' 'line' ';
         if (pos(' end ',line,1,'ri')) {
            status=repeat_search();
            continue;
         }
         if ( proc_name=='' ) {
            proc_name=ret_proc_name;
         } else if ( strieq(proc_name,ret_proc_name) ) {
            status=repeat_search();
            continue;
         }
         return(0);
      } else {
         status=repeat_search();
      }
   }
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

_command void for_tab() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   int index=_edit_window().p_index;
   p_index=0;
   call_root_key(TAB);
   _edit_window().p_index=index;

}
_command void for_backtab() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   int index=_edit_window().p_index;
   p_index=0;
   call_root_key(S_TAB);
   _edit_window().p_index=index;
}
