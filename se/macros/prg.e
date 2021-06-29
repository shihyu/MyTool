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
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "context.e"
#import "cutil.e"
#import "notifications.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
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
_str _prg_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}
static const PRG_LANGUAGE_ID= 'prg';
_str _no_filename_index;
_str def_memvar_prefix='_';
_str def_memvar_suffix;

defeventtab dbase_keys;
def  ' '= dbase_space;
def  'ENTER'= dbase_enter;


_command dbase_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PRG_LANGUAGE_ID);
}
_command void dbase_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_prg_expand_enter);
}
bool _prg_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
_command dbase_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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

static const PRG_ENTER_WORDS= (' case do else elseif for function if otherwise':+\
                     ' procedure ');
static const PRG_FIRST_LEVEL_WORDS= ' function procedure ';

   /* Space words must be in sorted order. */
static const PRG_EXPAND_WORDS= (' case do else elseif end endcase enddo endif external ':+\
                'function next otherwise private procedure public ');
static const PRG_UNINDENT_WORDS= ' case else elseif ';


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
bool _prg_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;

   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   
   status := 0;
   line := "";
   get_line(line);
   if ( line=='' ) {
      return(true);
   }

   i := 0;
   width := 0;
   indent := 0;
   orig_first_word := "";
   rest := "";
   parse line with orig_first_word rest;
   _str sample=orig_first_word;
   first_word := lowcase(orig_first_word);
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
               temp := "";
               get_line(temp);
               w := "";
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
               i++;
            }
            if ( status ) {  /* endcase or case not found? */
              replace_line(indent_string(width+indent-7)_word_case('case',false,sample));
              insert_line( indent_string(width-7)_word_case('endcase',false,sample));
              up();get_line(line);p_col=text_col(line)+2;

              // notify user that we did something unexpected
              notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
              return(false);
            }
            replace_line(indent_string(width+indent-7)_word_case('case',false,sample));
            get_line(line);p_col=text_col(line)+2;
            /* if not insert_state() then insert_toggle endif */
         }
      } else if ( pos(' 'first_word' ',PRG_UNINDENT_WORDS) ) {
         typeless p=point();
         typeless ln=point('L');
         cl := p_col;
         left_edge := p_left_edge;
         cursor_y := p_cursor_y;
         search_string := "";
         if ( first_word=='case' ) {
            search_string='((do[ \t]*case)|endcase)';
         } else if ( first_word=='elseif' || first_word=='else' || first_word=='endif' ) {
            search_string='(if|endif)';
         }
         status=search('^[ \t]*\c'search_string,'@rhi-');
         sline := "";
         get_line(sline);
         col := p_col;
         goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
         if ( ! status ) {
            if ( pos('^[ \t]*end',sline,1,'ri') ) {
               col -= syntax_indent;
               if ( col<0 ) {
                  col=1;
               }
            }
            if ( indent_case && first_word=='case' ) {
               col += syntax_indent;
            }
            replace_line(indent_string(col-1):+strip(line,'L'));
            _end_line();
            indent_on_enter(syntax_indent);
         } else {
            clear_message();
         }
      } else if ( pos(' 'first_word' ',PRG_FIRST_LEVEL_WORDS) && ! LanguageSettings.getIndentFirstLevel(p_LangId) ) {
         return(true);
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
static bool prg_expand_space()
{
   status := 0;
   origLine := "";
   get_line(origLine);
   line := strip(origLine,'T');
   sample := strip(line);
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(true);
   }

   first_word := "";
   second_word := "";
   aliasfilename := "";
   parse lowcase(orig_word) with first_word second_word;
   _str word=min_abbrev2(orig_word,prg_space_words,'',aliasfilename);

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

   bool is_do_case=first_word=='do' &&
                      second_word==substr('case',1,length(second_word)) &&
                      second_word!='';
   bool is_do_while=first_word=='do' &&
                       second_word==substr('while',1,length(second_word)) &&
                       second_word!='';
   if ( word=='' && !(is_do_case || is_do_while) ) {
      return(true);
   }
   if ( word=='' ) {
      word=orig_word;
   }
   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;

   doNotify := true;
   if ( word=='if' ) {
     replace_line(_word_case(line' ',false,sample));
     /* insert_line indent_string(width)'else' */
     insert_line(indent_string(width)_word_case('endif',false,sample));
     set_surround_mode_end_line();
     up(1);p_col=width+4;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='for' ) {
     replace_line(_word_case(line,false,sample):+' = ':+_word_case('to',false,sample));
     insert_line(indent_string(width)_word_case('next',false,sample));
     set_surround_mode_end_line();
     up();p_col=width+5;
     if ( ! _insert_state() ) _insert_toggle();
   } else if ( is_do_case ) {
     line :+= substr('case',length(second_word)+1);
     newLine := _word_case(line' ',false,sample);
     replace_line(newLine);
     _end_line();

     doNotify = (newLine != origLine);
   } else if ( is_do_while ) {
     line :+= substr('while',length(second_word)+1);
     replace_line(_word_case(line' ',false,sample));
     insert_line(indent_string(width)_word_case('enddo',false,sample));
     set_surround_mode_end_line();
     up();p_col=width+10;
     if ( ! _insert_state() ) _insert_toggle();
   } else if ( pos(' 'word' ',PRG_EXPAND_WORDS) ) {
      newLine := indent_string(width)_word_case(word,false,sample)' ';
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

int prg_proc_search(_str &proc_name,bool find_first)
{
   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["procedure"] = "proc";
      kw_map:["proc"] = "proc";
      kw_map:["function"] = "func";
      kw_map:["funct"] = "func";
      kw_map:["func"] = "func";
   }

   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "procedure|function|proc|funct|func";
   }

   return _generic_regex_proc_search('^([ \t]*<<<TYPE>>>:b<<<NAME>>>[ \t]*([(&]|$)|<<<NAME2>>>[ \t]*=[ \t]*)', proc_name, find_first!=0, "gvar", re_map, kw_map);
}


/*dBASE Options Form*/
defeventtab _prg_extform;

void _prg_extform.on_destroy()
{
   _language_form_on_destroy();
}

/*End dBASE Options Form*/

