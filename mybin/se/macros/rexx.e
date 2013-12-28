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
#import "autocomplete.e"
#import "c.e"
#import "csymbols.e"
#import "cutil.e"
#import "notifications.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for rexx syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 0.
       3             Not used.  If we decide to do an "End Style", we will use
                     this postion.(reserved)
       4             reserved.
       5             reserved.

   Used "A Practical Approach to Programming the Rexx Language" for set up

*/
#define REXX_MODE_NAME   'REXX'
#define REXX_LANGUAGE_ID 'rexx'
#define REXX_IDENTIFIER_CHARS  'A-Za-z0-9_!'
#define REXX_VLXLEXERNAME  'REXX'

defeventtab rexx_keys;
def " "=rexx_space;
def "ENTER"=rexx_enter;
def "("=auto_functionhelp_key;
//def "."=auto_codehelp_key;
//def "~"=auto_codehelp_key;

defload()
{
   _str setup_info='MN='REXX_MODE_NAME',TABS=+3,MA=1 74 1,':+
              'KEYTAB='REXX_MODE_NAME'-keys,WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='REXX_IDENTIFIER_CHARS',LN='REXX_VLXLEXERNAME',CF=1,';
   //compile_info='0 cobol *;'
   _str compile_info='';
   _str syntax_info='3 1 1 0 0 1 0';
   _str be_info='';

   _CreateLanguage(REXX_LANGUAGE_ID, REXX_MODE_NAME,
                   setup_info, compile_info,
                   syntax_info, be_info);
   _CreateExtension('rexx', REXX_LANGUAGE_ID);

   // Find the setup for CMD.
   lang := _Ext2LangId("cmd");
   mode_name := _LangId2Modename(lang);
   if (_ModenameEQ(mode_name,'rexx')) {
      _DeleteExtension('cmd');
   }
}


/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _rexx_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
}

_command void rexx_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_rexx_expand_enter, true);
}

/* This command is bound to the SPACE BAR key.  It looks at the text around */
/* the cursor to decide whether insert an expanded template.  If it does not, */
/* the root key table definition for the SPACE BAR key is called. */
_command void rexx_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   // Since rexx strings can span multiple lines, must check if where are in a string
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() || _clex_find(0,'g')==CFG_STRING ||
      rexx_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

/* These constant strings have been defined to make the syntax
 expansion and indenting more data driven and to speed up
 determining whether special processing must be performed. There
 must be a space before and after each key word. */
#define REXX_EXPAND_WORDS ' call exit for forever interpret iterate leave nop options procedure pull push queue say signal trace while by '
#define REXX_ENTER_WORDS  ' do end if otherwise select '

static SYNTAX_EXPANSION_INFO rexx_space_words:[] = {
   'arg'           => { "arg( ... )" },
   'by'            => { "by" },
   'call'          => { "call" },
   'do'            => { "do ... end" },
   'else'          => { "else do ... end" },
   'exit'          => { "exit" },
   'for'           => { "for" },
   'forever'       => { "forever" },
   'if'            => { "if ... then do ... end" },
   'interpret'     => { "interpret" },
   'iterate'       => { "iterate" },
   'label'         => { "label" },
   'leave'         => { "leave" },
   'nop'           => { "nop" },
   'options'       => { "options" },
   'otherwise'     => { "otherwise do ... end" },
   'parse'         => { "parse ... with ..." },
   'procedure'     => { "procedure" },
   'program'       => { "program" },
   'pull'          => { "pull" },
   'push'          => { "push" },
   'queue'         => { "queue" },
   'say'           => { "say" },
   'select'        => { "select ... end" },
   'signal'        => { "signal" },
   'to'            => { "to = o by 1" },
   'trace'         => { "trace" },
   'type'          => { "type" },
   'when'          => { "when ... then do ... end" },
   'while'         => { "while" },
};

/* Returns non-zero number if fall through to enter key required */
boolean _rexx_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

  status := 0;
  /* Is last word begin key word or first word one of indent on enter */
  /* key words?. */
  _str line="";
  get_line(line);
  /* strip comments. */
  _str last_word="";
  parse lowcase(line) with last_word '/*';
  if ( lastpos('{;| (do|if|select|end)([ \t]|$)}',last_word,'','r') ) {
     last_word=substr(last_word,lastpos('S0'),lastpos('0'));
  }
  _str word="";
  _str rest="";
  parse line with '[~ \t]','r' +0 word '[ \t]','r' rest;
  /* Put first word of line into first_word variable. */
  _str first_word=lowcase(word);
  last_word=lowcase(strip(last_word));
  if ( pos(' 'last_word' ',REXX_ENTER_WORDS,1,'i') && expand){
     indent_on_enter(syntax_indent);
     if (last_word=='select') {
        replace_line(indent_string(p_col-1)_word_case('when'):+'  ':+_word_case('then'):+' ':+_word_case('do'));
        insert_line(indent_string(p_col-1)_word_case('end'));
        up();_end_line();
        int i;
        for (i=1;i<9;++i) left();

        // notify user that we did something unexpected
        notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
     }else if (last_word=='end') {
        status=up();
        get_line(line);
        int endstillthere=pos('end',line,1,'i');
        if (!status) down();
        if (endstillthere) {
           save_pos(auto p);
           status=_nocomment_search('do','@h-i');
           if (!status) {
              get_line(line);
              first_non_blank=pos('~[ ]',line,1,'r');
           }else{
              first_non_blank=p_col;
           }
           restore_pos(p);
           p_col=first_non_blank;
           status=0;
        }else{
           status=1;
        }
     }
  } else {
     status=1;
  }
  return(status != 0);

/* Returns non-zero number if fall through to space bar key required */
}
static _str rexx_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   /* Put first word of line in lower case into word variable. */
   _str origLine="";
   get_line(origLine);
   _str line=strip(origLine,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str first="", second="";
   if (pos(' ',orig_word)/* && !pos('do',orig_word,1,'ir')*/) {
      parse orig_word with first second;
      if (lowcase(strip(first))=='do') {
         orig_word=second;
      }
   }
   int i=0;
   int width=0;
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,rexx_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   /* Is the cursor not at the end of the line or the first word */
   /* not one of the SPACE BAR expansion key words. */
   //if ( ! pos(' 'word' ',SPACE_WORDS) ) {
   if ( word=='') return(1)    /* Fall through to space bar key. */
   /* Insert the appropriate template based on the key word. */
   if (!isinteger(word)) {
      line=substr(line,1,length(line)-length(orig_word)):+word;
   }else{
      //expanding
      //DO i=45
   }
   width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   set_surround_mode_start_line();

   doNotify := true;
   status := 0;
   if ( word=='do' ) {
      replace_line(_word_case(line)' ');
      insert_line(indent_string(width):+_word_case('end'));
      set_surround_mode_end_line();
      up();
      _end_line();
   } else if ( word=='arg' ) {
      replace_line(_word_case(line)'()');
      _end_line();
      left();
   } else if ( word=='else' ) {
      replace_line(_word_case(line):+' ':+_word_case('do'));
      insert_line('');
      insert_line(indent_string(width):+_word_case('end'));
      set_surround_mode_end_line();
      up();_end_line();
      p_col=width+syntax_indent+1;
   } else if ( word=='if' || word=='when') {
      replace_line(_word_case(line)'  '_word_case('then')' '_word_case('do'));
      insert_line(indent_string(width):+_word_case('end'));
      set_surround_mode_end_line();
      up();_end_line();
      for (i=1;i<9;++i) left();
   } else if ( word=='otherwise' ) {
      replace_line(_word_case(line):+'  ':+_word_case('do'));
      insert_line(indent_string(width)_word_case('end'));
      set_surround_mode_end_line();
      up();_end_line();
      for (i=1;i<4;++i) left();
   } else if ( word=='parse' ) {
      replace_line(_word_case(line):+'  ':+_word_case('with'));
      _end_line();
      for (i=1;i<6;++i) left();
   } else if ( word=='select' ) {
      replace_line(_word_case(line)' ');
      insert_line(indent_string(width+syntax_indent):+_word_case('end'));
      set_surround_mode_end_line();
      up();
      _end_line();
   } else if ( word=='to' ) {
      int p=pos('do ',line,1,'i');
      _str prefix=substr(line,1,p+length('do ')-1);
      _str suffix=_word_case(substr(line,p+length('do')))' '_word_case('by')' 1';
      line=prefix' = ':+suffix;
      replace_line(line);
      _end_line();
      for (i=1;i<11;++i) left();
   } else if (pos(' 'word' ', REXX_EXPAND_WORDS)) {
      newLine := _word_case(line)' ';
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != origLine);
   } else {
      status = 1;
      doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
   
}
int _rexx_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, rexx_space_words, prefix, min_abbrev);
}
int rexx_proc_search(_str &proc_name,int find_first)
{
   static _str cur_class_name;
   int status=0;
   if (find_first) {
      cur_class_name='';
      _str fn="";
      if (proc_name:=='') {
         fn=_clex_identifier_re():+"|['][^']*[']|[\"][^\"]*[\"]";
      }else{
         fn=_escape_re_chars(proc_name);
      }
      //status=_nocomment_search('^(:b|)'fn'(:b|)\:(:b|)(procedure|)','@ri');  // Allen trying next line
      //status=_nocomment_search('(\:\:)(:b@)requires|(\:\:)(:b@)method|(\:\:)(:b@)class|\:(:b@)procedure','@ri');
      status=search('^(:b|)' :+ '{\:\:(:b|)(requires|method|class):b|}' :+
                    '{'fn'}' :+ '(:b|){\:(:b|)(procedure|)|}', '@rhiXcs');
   }else{
      status=repeat_search();
   }

   for (;;) {
      if (status) {
         return status;
      }
      proc_name=get_match_text(1);
      _str proc_type=get_match_text(0);
      _str proc_proc=get_match_text(2);
      _str proc_class='';
      parse proc_type with '::' proc_type . ;
      //say("rexx_proc_search: type="proc_type" name="proc_name" proc="proc_proc);
      switch (lowcase(strip(proc_type))) {
      case 'class':
         cur_class_name=proc_name;
         proc_type = 'class';
         break;
      case 'method':
         proc_type = 'func';
         proc_class = cur_class_name;
         break;
      case 'requires':
         cur_class_name='';
         proc_type = 'include';
         break;
      case '':
         if (!pos(':',proc_proc) || first_char(proc_name)=='"' || first_char(proc_name)=="'") {
            status=repeat_search();
            continue;
         }
         cur_class_name='';
         proc_type="proc";
         break;
      }

      proc_name=tag_tree_compose_tag(proc_name,proc_class,proc_type,(proc_class!='')? VS_TAGFLAG_inclass:0);
      //say('rexx_proc_search='proc_name);
      return(0);
   }

}
/**
 * Build the REXX tag file which contains all the built-in REXX
 * functions and documentation found in "rexx.tagdoc".
 *
 * @param tfindex Name index of standard REXX tag file
 * @return 0 on success, nonzero on error.
 */
int _rexx_MaybeBuildTagFile(int &tfindex)
{
   return ext_MaybeBuildTagFile(tfindex,'rexx','rexx',"REXX Libraries");
}
/**
 * @see _c_fcthelp_get_start
 */
int _rexx_fcthelp_get_start(_str (&errorArgs)[],
                         boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags));
}
/**
 * @see _c_fcthelp_get
 */
int _rexx_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
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

