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
#import "pmatch.e"
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

  Options for MODULA-2 syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2-5           reserved.
*/
#define MOD_MODE_NAME   'Modula'
#define MOD_LANGUAGE_ID 'mod'

defload()
{
   _str setup_info='MN='MOD_MODE_NAME',TABS=+3,MA=1 74 1,':+
                   'KEYTAB='MOD_MODE_NAME'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',':+
                   'IN=2,WC=A-Za-z0-9_$,LN=Modula-2,CF=1,';
   _str compile_info='';
   _str syntax_info='3 1 1 0 0 1 0';
   _str be_info='(WITH),(IF),(BEGIN),(WHILE),(CASE),(FOR),(LOOP)(RECORD)|(END) (REPEAT)|(UNTIL)';
   _CreateLanguage(MOD_LANGUAGE_ID, MOD_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('mod', MOD_LANGUAGE_ID);
}
_command modula_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(MOD_LANGUAGE_ID);

}
_command void modula_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_mod_expand_enter);
}
_command modula_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      modula_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}
#define MOD_ENTER_WORDS  (' begin case repeat var type const procedure implementation':+\
                ' label module if for while with elsif else definition module ')
#define MOD_DECL_WORDS ' type var label const else '
#define MOD_EXPAND_WORDS ' export end '

static SYNTAX_EXPANSION_INFO modula_space_words:[] = {
   'begin'          => { "BEGIN ... END" },
   'case'           => { "CASE ... OF ... END (* CASE *);" },
   'const'          => { "CONST" },
   'definition'     => { "DEFINITION MODULE ... BEGIN ... END." },
   'else'           => { "ELSE" },
   'elsif'          => { "ELSIF ... THEN ..." },
   'end'            => { "END" },
   'export'         => { "EXPORT" },
   'for'            => { "FOR ... := ... TO ... BY 1 DO ... END (* FOR *);" },
   'from'           => { "FROM ... IMPORT ..." },
   'if'             => { "IF ... THEN ... END (* IF *);" },
   'implementation' => { "IMPLEMENTATION MODULE ... BEGIN ... END." },
   'label'          => { "LABEL" },
   'loop'           => { "LOOP ... END (* LOOP *);" },
   'module'         => { "MODULE ... BEGIN ... END." },
   'procedure'      => { "PROCEDURE ... BEGIN ... END;" },
   'repeat'         => { "REPEAT ... UNTIL ... ;" },
   'type'           => { "TYPE" },
   'var'            => { "VAR" },
   'while'          => { "WHILE ... DO ... END (* WHILE *);" },
   'with'           => { "WITH ... DO ... END (* WITH *);" },
};

/* Returns non-zero number if modulas through to enter key required */
boolean _mod_expand_enter()
{
  updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
  syntax_indent := p_SyntaxIndent;
  expand := LanguageSettings.getSyntaxExpansion(p_LangId);

  status := false;
  _str line='';
  get_line(line);
  _str orig_first_word='';
  _str rest='';
  parse line with orig_first_word rest ;
  _str first_word=lowcase(orig_first_word);
  
  if ( pos(' 'first_word' ',MOD_ENTER_WORDS) ) {
     if ( first_word=='for' && name_on_key(ENTER)=='nosplit-insert-line' ) {
        /* tab to fields of modula for statement */
        line=expand_tabs(line);
        _str before='';
        parse lowcase(line) with before ':=' ;
        if ( length(before)+1>=p_col ) {
           p_col=length(before)+4;
        } else {
           parse line with before 'TO' ;
           if ( length(before)>=p_col ) {
              p_col=length(before)+4;
           } else {
              indent_on_enter(syntax_indent);
           }
        }
     } else if ( expand && (first_word=='implementation' || first_word=='procedure' ||
           first_word=='definition' || first_word=='module') ) {
        /* If next line is begin key word, comment begin/end with function name */
        down();
        _str next_line='';
        _str keyword='';
        _str function_name='';
        get_line(next_line);
        if ( lowcase(next_line)=='begin' && p_col>text_col(_rawText(line)) ) {
           up();
           if ( first_word=='module' || first_word=='procedure' ) {
              parse line with keyword function_name '([\:\(;])|$','r' ;
           } else {
              parse line with . . function_name '([\:\(;])|$','r' ;
           }
           down();
           function_name=strip(function_name);
           replace_line(next_line' (* 'function_name' *)');
           down();
           get_line(line);
           parse line with 'END[.;]','r' +3 rest ;
           if ( line=='END;' || line=='END.' ) {
              replace_line(substr(line,1,length(line)-1)' 'function_name:+rest);
           }
           up(2);
           indent_on_enter(syntax_indent);

           // notify user that we did something unexpected
           notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
        } else {
           up();
           indent_on_enter(syntax_indent);
        }
     } else {
        int i=pos(orig_first_word,line);
        replace_line(substr(line,1,i-1):+upcase(orig_first_word):+
                     substr(line,i+length(orig_first_word)));
        indent_on_enter(syntax_indent);
     }
  } else {
    status=true;
  }
  return(status);

}
static _str modula_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   int status=0;
   _str origLine='';
   get_line(origLine);
   _str line=strip(origLine,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,modula_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=='') return(1);
   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;

   doNotify := true;
   if ( word=='if' ) {
     replace_line(upcase(line)'  THEN');
     /* insert_line indent_string(width)'end else begin' */
     insert_line(indent_string(width)'END (* IF *);');
     set_surround_mode_end_line();
     up();p_col=width+4;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='elsif' ) {
      replace_line(upcase(line'  then'));
      p_col=width+7;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='implementation' || word=='procedure' ||  word=='definition' || word=='module' ) {
      if ( word=='implementation' ) {
         line=upcase(word)' MODULE';
      } else if ( word=='definition' ) {
         line=upcase(word)' MODULE';
      }
      replace_line(upcase(line));
      insert_line(indent_string(width):+'BEGIN');
      if ( word=='procedure' ) {
         insert_line(indent_string(width):+'END;');
      } else {
         insert_line('END.');
      }
      up(2);_end_line();right();
   } else if ( word=='for' ) {
     replace_line(upcase(line)' :=  TO  BY 1 DO');
     insert_line(indent_string(width)'END (* FOR *);');
     set_surround_mode_end_line();
     up();p_col=width+5;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='loop' ) {
     replace_line(upcase(line));
     insert_line(indent_string(width)'END (* LOOP *);');
     up();
     nosplit_insert_line();
     set_surround_mode_end_line(p_line+1);
     p_col=p_col+syntax_indent;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='begin' ) {
     replace_line(upcase(line));
     insert_line(indent_string(width)'END ');  /* Hard to find ident */
     set_surround_mode_end_line();
/*
     up;call nosplit_insert_line()
     p_col=p_col+syntax_indent
     if not insert_state() then insert_toggle endif
*/
   } else if ( word=='while' ) {
     replace_line(upcase(line)'  DO');
     insert_line(indent_string(width)'END (* WHILE *);');
     set_surround_mode_end_line();
     up();p_col=width+7;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='from' ) {
     replace_line(upcase(line)'  IMPORT ');
     p_col=width+6;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='with' ) {
     replace_line(upcase(line)'  DO');
     insert_line(indent_string(width)'END (* WITH *);');
     set_surround_mode_end_line();
     up();p_col=width+6;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='case' ) {
     replace_line(upcase(line)'  OF');
     insert_line(indent_string(width)'END (* CASE *);');
     set_surround_mode_end_line();
     up();p_col=width+6;
     if ( ! _insert_state() ) { _insert_toggle(); }
   } else if ( word=='repeat' ) {
     replace_line(upcase(line));
     insert_line(indent_string(width)'UNTIL  ;');
     up();
     nosplit_insert_line();
     set_surround_mode_end_line(p_line+1);
     p_col=p_col+syntax_indent;
   } else if ( pos(' 'word' ',MOD_DECL_WORDS) ) {
      newLine := indent_string(width)upcase(word);
      replace_line(newLine);
      indent_on_enter(syntax_indent);
      doNotify = (newLine != origLine);
   } else if ( pos(' 'word' ',MOD_EXPAND_WORDS) ) {
      newLine := indent_string(width)upcase(word)' ';
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

   return status;
}

int _mod_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, modula_space_words, prefix, min_abbrev);
}

_str mod_proc_search(var proc_name,boolean find_first,_str extension)
{
   int status=0;
   _str _keywords='(PROCEDURE)';
   if ( find_first ) {
      if ( proc_name:=='' ) {
         status=search('^[ \t]*'_keywords':b:v[ \t]*[(;:]','@rhe');
      } else {
         word_chars := _clex_identifier_chars();
         status=search(proc_name,'@he>w=['word_chars']');
      }
   } else {
      status=repeat_search();
   }
   for (;;) {
      if ( status ) {
         return(status);
      }
      if (_in_comment()) {
         status=repeat_search();
         continue;
      }
      _str line='';
      get_line(line);
      line=expand_tabs(line);
      int col=p_col;
      if ( pos(' '_keywords'[ \t]',' 'line,1,'r'):==0 ) {
         status=repeat_search();continue;
      }
      int p=pos('[(;:]',line,1,'r');
      if ( p ) {
         if ( substr(line,p,1):=='(' ) {
            p_col=p;
            if ( _find_matching_paren(def_pmatch_max_diff) ) {
               status=repeat_search();
               continue;
            }
            _find_matching_paren(def_pmatch_max_diff);
         }
         _str temp='';
         get_line(temp);
         temp=expand_tabs(temp);
         if ( pos('forward;',temp) ) {
            status=repeat_search();
            continue;
         }
         line=strip(substr(line,1,p-1));
         int i=lastpos(' ',translate(line,' ',\t));
         proc_name=substr(line,i+1);
         return(0);
      }
      status=repeat_search();
   }

}
