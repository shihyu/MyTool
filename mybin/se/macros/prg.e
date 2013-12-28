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
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
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

  Options for dBASE syntax expansion/indenting may be accessed from SLICK's
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
       4             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
       5             reserved.

*/

/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _prg_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
}
#define PRG_LANGUAGE_ID 'prg'
#define PRG_MODE_NAME   'dBASE'
_str _no_filename_index;
_str def_memvar_prefix='_';
_str def_memvar_suffix;

defload()
{
   _no_filename_index=find_index('prg_get_filename',PROC_TYPE);
   _str setup_info='MN='PRG_MODE_NAME',TABS=+3,MA=1 74 1,':+
                   'KEYTAB='PRG_MODE_NAME'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',':+
                   'IN=2,WC=A-Za-z0-9_$,LN=xbase,CF=1,';
   _str compile_info='';
   _str syntax_info='3 1 1 1 0 1 0';
   _str be_info='(if)|(endif) (do)|(endcase),(enddo) (for)|(next);i';

   _CreateLanguage(PRG_LANGUAGE_ID, PRG_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('prg', PRG_LANGUAGE_ID);
}
_command dbase_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PRG_LANGUAGE_ID);
}
_command void dbase_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_prg_expand_enter);
}
_command dbase_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless expand=0;
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      prg_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

#define PRG_ENTER_WORDS (' case do else elseif for function if otherwise':+\
                     ' procedure ')
#define PRG_FIRST_LEVEL_WORDS ' function procedure '

   /* Space words must be in sorted order. */
#define PRG_EXPAND_WORDS (' case do else elseif end endcase enddo endif external ':+\
                'function next otherwise private procedure public ')
#define PRG_UNINDENT_WORDS ' case else elseif '


static SYNTAX_EXPANSION_INFO prg_space_words:[] = {
   'case'      => { "case" },
   'do'        => { "do" },
   'do while'  => { "do while ... enddo" },
   'else'      => { "else" },
   'elseif'    => { "elseif" },
   'end'       => { "end" },
   'endcase'   => { "endcase" },
   'enddo'     => { "enddo" },
   'endif'     => { "endif" },
   'external'  => { "external" },
   'for'       => { "FOR ... = ... TO ... NEXT" },
   'function'  => { "function" },
   'if'        => { "IF ... ENDIF" },
   'next'      => { "next" },
   'otherwise' => { "otherwise" },
   'private'   => { "private" },
   'procedure' => { "procedure" },
   'public'    => { "public" },
};

/*
    Returns true if nothing is done
*/
boolean _prg_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;

   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   
   int status=0;
   _str line='';
   get_line(line);
   if ( line=='' ) {
      return(1);
   }

   int i=0;
   int width=0;
   int indent=0;
   _str orig_first_word='';
   _str rest='';
   parse line with orig_first_word rest;
   _str first_word=lowcase(orig_first_word);
   if ( pos(' 'first_word' ',PRG_ENTER_WORDS) ) {
      if ( lowcase(line)=='do case' && expand ) {
         width=text_col(strip(line,'T'));
         indent=0;
         if ( indent_case ) {
            indent=syntax_indent;
         }
         indent_on_enter(indent);
         get_line(line);
         if ( line=='' ) {
            /* check if endcase has been typed */
            i=1;
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
               if ( lowcase(w)=='case' || lowcase(w)=='endcase' ) {
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
              replace_line(indent_string(width+indent-7)_word_case('case'));
              insert_line( indent_string(width-7)_word_case('endcase'));
              up();get_line(line);p_col=text_col(line)+2;

              // notify user that we did something unexpected
              notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
              return(0);
            }
            replace_line(indent_string(width+indent-7)_word_case('case'));
            get_line(line);p_col=text_col(line)+2;
            /* if not insert_state() then insert_toggle endif */
         }
      } else if ( pos(' 'first_word' ',PRG_UNINDENT_WORDS) ) {
         typeless p=point();
         typeless ln=point('L');
         int cl=p_col;
         int left_edge=p_left_edge;
         int cursor_y=p_cursor_y;
         _str search_string='';
         if ( first_word=='case' ) {
            search_string='((do[ \t]*case)|endcase)';
         } else if ( first_word=='elseif' || first_word=='else' || first_word=='endif' ) {
            search_string='(if|endif)';
         }
         status=search('^[ \t]*\c'search_string,'@rhi-');
         _str sline='';
         get_line(sline);
         int col=p_col;
         goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
         if ( ! status ) {
            if ( pos('^[ \t]*end',sline,1,'ri') ) {
               col=col-syntax_indent;
               if ( col<0 ) {
                  col=1;
               }
            }
            if ( indent_case && first_word=='case' ) {
               col=col+syntax_indent;
            }
            replace_line(indent_string(col-1):+strip(line,'L'));
            _end_line();
            indent_on_enter(syntax_indent);
         } else {
            clear_message();
         }
      } else if ( pos(' 'first_word' ',PRG_FIRST_LEVEL_WORDS) && ! LanguageSettings.getIndentFirstLevel(p_LangId) ) {
         return(1);
      } else {
         indent_on_enter(syntax_indent);
      }
   } else {
      status=1;
   }
   return(status!=0);
}
/*
    Returns true if nothing is done.
*/
static boolean prg_expand_space()
{
   int status=0;
   _str origLine='';
   get_line(origLine);
   _str line=strip(origLine,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }

   _str first_word='';
   _str second_word='';
   _str aliasfilename='';
   parse lowcase(orig_word) with first_word second_word;
   _str word=min_abbrev2(orig_word,prg_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   /************************************************
     If you are using prg.e as a template for adding syntax
     expansion and indenting for your own language you
     do not need the code below.   If you only want extension
     specific aliases, just add a return(1) statement here.


       return(1);

   **************************************************/

   boolean is_do_case=first_word=='do' &&
                      second_word==substr('case',1,length(second_word)) &&
                      second_word!='';
   boolean is_do_while=first_word=='do' &&
                       second_word==substr('while',1,length(second_word)) &&
                       second_word!='';
   if ( word=='' && !(is_do_case || is_do_while) ) {
      return(1);
   }
   if ( word=='' ) {
      word=orig_word;
   }
   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;

   doNotify := true;
   if ( word=='if' ) {
     replace_line(_word_case(line' '));
     /* insert_line indent_string(width)'else' */
     insert_line(indent_string(width)_word_case('endif'));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='for' ) {
     replace_line(_word_case(line):+' = ':+_word_case('to'));
     insert_line(indent_string(width)_word_case('next'));
     set_surround_mode_end_line();
     up();p_col=width+5;
     if ( ! _insert_state() ) _insert_toggle();
   } else if ( is_do_case ) {
     line=line:+substr('case',length(second_word)+1);
     newLine := _word_case(line' ');
     replace_line(newLine);
     _end_line();

     doNotify = (newLine != origLine);
   } else if ( is_do_while ) {
     line=line:+substr('while',length(second_word)+1);
     replace_line(_word_case(line' '));
     insert_line(indent_string(width)_word_case('enddo'));
     set_surround_mode_end_line();
     up();p_col=width+10;
     if ( ! _insert_state() ) _insert_toggle();
   } else if ( pos(' 'word' ',PRG_EXPAND_WORDS) ) {
      newLine := indent_string(width)_word_case(word)' ';
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != origLine);
   } else {
     status=1;
     doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status!=0);
}

int _prg_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, prg_space_words, prefix, min_abbrev);
}

int prg_proc_search(_str &proc_name,boolean find_first)
{
   int status=0;
   if ( find_first ) {
      if ( proc_name:=='') {
          proc_name = _clex_identifier_re();
      }
      status=search('^([ \t]*(procedure|function|proc|funct):b\c'proc_name'[ \t]*([(&]|$)|\c'proc_name'[ \t]*=[ \t])','@rhi');
   } else {
      status=repeat_search();
   }
   if ( status ) {
      return(status);
   }
   _str line='';
   get_line(line);
   line=expand_tabs(line);
   int p=pos('([ \t&(=]|$)',line,p_col,'r');
   /* Parse out the name.  Cursor is on first character of name. */
   proc_name=substr(line,p_col,p-p_col);
   /* Parse out the tag type. */
   tag_type := "";
   if ( p_col==1 ) tag_type = 'gvar';
   if ( pos("^[ \\t]*proc", line, 1, "ri") > 0 ) tag_type = 'proc';
   if ( pos("^[ \\t]*func", line, 1, "ri") > 0 ) tag_type = 'func';
   // compose the tag name
   proc_name = tag_tree_compose_tag(proc_name, "", tag_type);
   return(0);
}
