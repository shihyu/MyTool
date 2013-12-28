////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48920 $
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
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "error.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "notifications.e"
#import "pmatch.e"
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
  Options for COBOL syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The language specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 0.
       3             reserved.
       4             Specifies whether COBOL 74, COBOL 1985 ANSI, or
                     (draft ANSI standard) COBOL 2000 should be supported.
                     Possible values are:
                         1 -- support COBOL 1985 and COBOL 2000 extensions
                         2 -- support COBOL 1974 keywords
                         3 -- support COBOL 1985 keywords only
                     Default value is 1.  (value of 0 is not allowed).
       5             reserved.

  In addition to using the file extension setup menu to configure cobol
  defaults, you can set the variable "def_cobol_levels" with the SET-VAR
  command to configure the columns for level numbers.

  Example

      set-var def_cobol_levels 01=8 03=12 05=16 07=20 77=8 88=8

*/

_str def_cobol_levels = "01=8 03=12 05=16 07=20 77=8 88=8";
_str def_cobol_copy_path = "";
_str def_cobol_copy_extensions = ". .cpy .cbl .cob .cobol";


#define COBOL_MODE_NAME    'Cobol 85'
#define COBOL_LANGUAGE_ID  'cob'

#define COBOL74_MODE_NAME    'Cobol 74'
#define COBOL74_LANGUAGE_ID  'cob74'

#define COBOL2000_MODE_NAME    'Cobol 2000'
#define COBOL2000_LANGUAGE_ID  'cob2000'

defeventtab cobol_keys;
def  ' '= cobol_space;
def  '('= auto_functionhelp_key;
def  '-'= cob_maybe_case_word;
def  '0'-'9'= cob_maybe_case_word;
def  ':'= auto_codehelp_key;
def  'A'-'Z'= cob_maybe_case_word;
def  '_'= cob_maybe_case_word;
def  'a'-'z'= cob_maybe_case_word;
def  'ENTER'= cobol_enter;
def  'BACKSPACE'= cob_maybe_case_backspace;

defload()
{
   _str word_chars='a-zA-Z0-9_\-';
   _str setup_info1985 = 'MN='COBOL_MODE_NAME',TABS=1 8 250 +4,MA=8 72 8,':+
                         'KEYTAB=cobol_keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,':+
                         'WC='word_chars',LN=Cobol,CF=1,LNL=0,TL=-1';
   _str setup_info1974 = 'MN='COBOL74_MODE_NAME',TABS=1 8 250 +4,MA=8 72 8,':+
                         'KEYTAB=cobol_keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,':+
                         'WC='word_chars',LN=Cobol,CF=1,LNL=0,TL=-1';
   _str setup_info2000 = 'MN='COBOL2000_MODE_NAME',TABS=1 8 250 +4,MA=8 72 8,':+
                         'KEYTAB=cobol_keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,':+
                         'WC='word_chars',LN=Cobol2000,CF=1,LNL=0,TL=-1';
   _str compile_info='0 cobol *;';
   _str syntax_info1974='4 1 1 1 0 2 0 0';
   _str syntax_info1985='4 1 1 1 0 3 0 0';
   _str syntax_info2000='4 1 1 1 0 1 0 0';
   _str be_info='';
#if __OS390__ || __TESTS390__
   setup_info = setup_info :+ ',BNDS=,CAPS=2';
   // uppercase keyword: on
   // cobol 74 and 2000: off
   syntax_info='4 1 1 1 0 3 0 0';
   // autocase: on
   LanguageSettings.setAutoCaseKeywords(COBOL_LANGUAGE_ID, 1);
   LanguageSettings.setAutoCaseKeywords(COBOL74_LANGUAGE_ID, 1);
   LanguageSettings.setAutoCaseKeywords(COBOL2000_LANGUAGE_ID, 1);
#endif
   _CreateLanguage(COBOL_LANGUAGE_ID, COBOL_MODE_NAME,
                   setup_info1985, compile_info,
                   syntax_info1985, be_info, "", word_chars);
   _CreateLanguage(COBOL74_LANGUAGE_ID, COBOL74_MODE_NAME,
                   setup_info1974, compile_info,
                   syntax_info1974, be_info, "", word_chars);
   _CreateLanguage(COBOL2000_LANGUAGE_ID, COBOL2000_MODE_NAME,
                   setup_info2000, compile_info,
                   syntax_info2000, be_info, "", word_chars);

   // Cobol 74 and Cobol 85 inherit from the cobol mode
   LanguageSettings.setLangInheritsFrom('cob74', 'cob');
   LanguageSettings.setLangInheritsFrom('cob2000', 'cob');

   // refer cobol extensions to Cobol 85 by default
   _CreateExtension('cob', COBOL_LANGUAGE_ID);
   _CreateExtension('cbl', COBOL_LANGUAGE_ID);
   _CreateExtension('cpy', COBOL_LANGUAGE_ID);

   // interfaces and object cobol 2000
   _CreateExtension('if',  COBOL2000_LANGUAGE_ID);
   _CreateExtension('ocb', COBOL2000_LANGUAGE_ID);

   _str name=VSCOBOL_SQL_LEXER_NAME;
   if(!find_index(name,MISC_TYPE) ) {
      insert_name(name,MISC_TYPE,"DB2");
   }

   LanguageSettings.setReferencedInLanguageIDs(COBOL_LANGUAGE_ID, COBOL2000_LANGUAGE_ID" "COBOL74_LANGUAGE_ID);
   LanguageSettings.setReferencedInLanguageIDs(COBOL74_LANGUAGE_ID, COBOL_LANGUAGE_ID" "COBOL2000_LANGUAGE_ID);
   LanguageSettings.setReferencedInLanguageIDs(COBOL2000_LANGUAGE_ID, COBOL_LANGUAGE_ID" "COBOL74_LANGUAGE_ID);
}


/**
 * @deprecated Use {@link LanguageSettings_API}
 */
boolean def_cob_autocase=0;

/** 
 * These are used by _maybe_case_word and _maybe_case_backspace. 
 */
static int gWordEndOffset=-1;
static _str gWord;

_command void cob_maybe_case_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _str event=event2name(last_event());
   if (command_state()) {
      keyin(event);
      return;
   }
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(COBOL_LANGUAGE_ID);
   if (p_LangId != COBOL_LANGUAGE_ID) {
      LanguageSettings.getAutoCaseKeywords(p_LangId, autoCase);
   }

   _maybe_case_word(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
}

_command void cob_maybe_case_backspace() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _str event=event2name(last_event());
   if (command_state()) {
      call_root_key(BACKSPACE);
      return;
   }
   typeless orig_values='';
   int embedded_status=_EmbeddedStart(orig_values);

   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(COBOL_LANGUAGE_ID);
   if (p_LangId != COBOL_LANGUAGE_ID) {
      LanguageSettings.getAutoCaseKeywords(p_LangId, autoCase);
   }
   _maybe_case_backspace(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
}

/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _cob_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
}

_command cobol_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(COBOL_LANGUAGE_ID);
}

_command void cobol_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_cob_expand_enter,true);
}

_command void cobol_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      call_root_key(' ');
      return;
   }
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
        _in_comment() || cobol_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
   cobol_codehelp_key();
}

#define COBOL_IDENTIFIERS (' identification program-id function-id ':+\
               'class-id interface-id method-id factory object options ':+\
               'environment configuration source-computer object-computer ':+\
               'special-names repository ':+\
               'input-output file-control select i-o-control ':+\
               'data file working-storage local-storage linkage ':+\
               'communication report screen fd rd cd sd 01 66 77 88 ':+\
               'procedure declaratives ')

#define COBOL_VERBS (' accept add allocate alter call cancel ':+\
               'chain close commit compute continue ':+\
               'delete disable display divide ':+\
               'enable enter evaluate exhibit exit free ':+\
               'generate go goback if initialize initiate inspect invoke ':+\
               'merge move multiply open perform purge ':+\
               'raise read receive release return rewrite rollback ':+\
               'search send set sort start stop ':+\
               'service string subtract suppress ':+\
               'terminate unlock unstring validate write ')

#define COBOL_OTHER_VERBS (' else when select use varying ':+\
                'giving remainder tallying thru through until ':+\
                'exec execute exhibit returning using copy replace ')

#define COBOL_END_VERBS (' end-accept end-add end-call end-compute end-delete ':+\
                'end-display end-divide end-evaluate end-exec end-if ':+\
                'end-multiply end-of-page end-perform end-read end-receive ':+\
                'end-return end-rewrite end-search end-start end-string ':+\
                'end-subtract end-unstring end-write ':+\
                'program class interface method function ')

#define COBOL_SYNTAX_WORDS (COBOL_IDENTIFIERS:+COBOL_VERBS:+COBOL_OTHER_VERBS)

#define COBOL_MISC_WORDS (' in of input output i-o extend ':+\
               'file error exception overflow goto procedure ':+\
               'thru through end invalid data normal eop end-of-page ':+\
               'using returning to giving into by remainder also ':+\
               'not free depending converting ':+\
               'replacing after before all leading first initial reference ':+\
               'content value ascending descending key ':+\
               'retry until varying when equal ':+\
               'with advancing up down uccurs address length ':+\
               'delimited count delimiter cd fd sd rd rd redefines ':+\
               'from raising status class ':+\
               'upon line col reporting arithmetic localize ':+\
               'program class interface method function ')

#define COBOL_PREFIXES (COBOL_VERBS:+COBOL_OTHER_VERBS:+COBOL_MISC_WORDS)

#define COBOL_ENTER_WORDS (COBOL_VERBS:+COBOL_OTHER_VERBS:+COBOL_IDENTIFIERS)

#define COBOL_ENTER_WORDS2 ' if else '

#define COBOL_EXPAND_WORDS (COBOL_VERBS:+COBOL_OTHER_VERBS:+COBOL_END_VERBS)

static SYNTAX_EXPANSION_INFO cobol_space_words_2000:[] = {
   'accept'             => { "accept ... from ..." },
   'access'             => { "access" },
   'add'                => { "add ... to ..." },
   'address'            => { "address" },
   'advancing'          => { "advancing" },
   'allocate'           => { "allocate" },
   'also'               => { "also" },
   'alter'              => { "alter ... to ..." },
   'alternate'          => { "alternate" },
   'ascending'          => { "ascending" },
   'assign'             => { "assign" },
   'author'             => { "author." },
   'call'               => { "call ... using ..." },
   'call-convention'    => { "call-convention" },
   'cancel'             => { "cancel" },
   'class'              => { "class" },
   'class-control'      => { "class-control." },
   'class-id'           => { "class-id.  ... end class ." },
   'class-object'       => { "class-object.  ... end class-object." },
   'close'              => { "close" },
   'communication'      => { "communication section." },
   'compute'            => { "compute" },
   'configuration'      => { "configuration section.  source-computer. ... object-computer. ..." },
   'continue'           => { "continue" },
   'data'               => { "data division.  file section.  working-storage section.  linkage section." },
   'declaratives'       => { "declaratives.  ... end declaratives." },
   'delete'             => { "delete ... record" },
   'disable'            => { "disable" },
   'display'            => { "display" },
   'divide'             => { "divide ... into ..." },
   'else'               => { "else" },
   'enable'             => { "enable" },
   'end'                => { "end" },
   'end-accept'         => { "end-accept" },
   'end-add'            => { "end-add" },
   'end-call'           => { "end-call" },
   'end-compute'        => { "end-compute" },
   'end-delete'         => { "end-delete" },
   'end-display'        => { "end-display" },
   'end-divide'         => { "end-divide" },
   'end-evaluate'       => { "end-evaluate" },
   'end-exec'           => { "end-exec" },
   'end-if'             => { "end-if" },
   'end-multiply'       => { "end-multiply" },
   'end-of-page'        => { "end-of-page" },
   'end-perform'        => { "end-perform" },
   'end-read'           => { "end-read" },
   'end-receive'        => { "end-receive" },
   'end-return'         => { "end-return" },
   'end-rewrite'        => { "end-rewrite" },
   'end-search'         => { "end-search" },
   'end-start'          => { "end-start" },
   'end-string'         => { "end-string" },
   'end-subtract'       => { "end-subtract" },
   'end-unstring'       => { "end-unstring" },
   'end-write'          => { "end-write" },
   'ending'             => { "ending" },
   'environment'        => { "environment division.  input-output section.  file-control." },
   'evaluate'           => { "evaluate ... when other ... end-evaluate" },
   'exec'               => { "exec ... end-exec" },
   'execute'            => { "execute ... end-exec" },
   'exit'               => { "exit" },
   'factory'            => { "factory.  ... end factory." },
   'file'               => { "file section." },
   'file-control'       => { "file-control.  select ... assign to ..." },
   'free'               => { "free" },
   'function'           => { "function" },
   'function-id'        => { "function-id.  ... end function ." },
   'generate'           => { "generate" },
   'giving'             => { "giving" },
   'go'                 => { "go to ..." },
   'goback'             => { "goback" },
   'identification'     => { "identification division.  program-id. test." },
   'if'                 => { "if ... end-if" },
   'initialize'         => { "initialize" },
   'initiate'           => { "initiate" },
   'input-output'       => { "input-output section." },
   'inspect'            => { "inspect" },
   'interface-id'       => { "interface-id.   ... end interface ." },
   'invoke'             => { "invoke" },
   'linkage'            => { "linkage section." },
   'local-storage'      => { "local-storage section." },
   'merge'              => { "merge" },
   'method-id'          => { "method-id.  ... end method ." },
   'move'               => { "move ... to ..." },
   'multiply'           => { "multiply ... by ..." },
   'object'             => { "object.  ... end object." },
   'object-storage'     => { "object-storage section." },
   'open'               => { "open" },
   'perform'            => { "perform" },
   'procedure'          => { "procedure division." },
   'program'            => { "program" },
   'program-id'         => { "program-id. ... end program ..." },
   'purge'              => { "purge" },
   'raise'              => { "raise" },
   'read'               => { "read ... record" },
   'receive'            => { "receive ... into ..." },
   'release'            => { "release" },
   'remainder'          => { "remainder" },
   'repository'         => { "repository." },
   'return'             => { "return ... record" },
   'returning'          => { "returning" },
   'rewrite'            => { "rewrite" },
   'search'             => { "search ... when ... end-search" },
   'select'             => { "select ... assign to ..." },
   'send'               => { "send" },
   'set'                => { "set ... to ..." },
   'sort'               => { "sort" },
   'special-names'      => { "special-names." },
   'start'              => { "start" },
   'stop'               => { "stop" },
   'string'             => { "string ... delimited by ... into ... end-string" },
   'subtract'           => { "subtract ... from ..." },
   'suppress'           => { "suppress printing" },
   'tallying'           => { "tallying" },
   'terminate'          => { "terminate" },
   'through'            => { "through" },
   'thru'               => { "thru" },
   'unlock'             => { "unlock" },
   'unstring'           => { "unstring ... delimited by ... into ... end-unstring" },
   'until'              => { "until" },
   'use'                => { "use" },
   'using'              => { "using" },
   'validate'           => { "validate" },
   'varying'            => { "varying ... from 1 by 1" },
   'when'               => { "when" },
   'working-storage'    => { "working-storage section." },
   'write'              => { "write" },
};

static SYNTAX_EXPANSION_INFO cobol_space_words_1985:[] = {
   'accept'             => { "accept ... from ..." },
   'access'             => { "access" },
   'add'                => { "add ... to ..." },
   'advancing'          => { "advancing" },
   'also'               => { "also" },
   'alter'              => { "alter ... to ..." },
   'alternate'          => { "alternate" },
   'ascending'          => { "ascending" },
   'assign'             => { "assign" },
   'author'             => { "author." },
   'call'               => { "call ... using ..." },
   'cancel'             => { "cancel" },
   'close'              => { "close" },
   'communication'      => { "communication section." },
   'compute'            => { "compute " },
   'configuration'      => { "configuration section.  source-computer. ... object-computer. ..." },
   'continue'           => { "continue" },
   'data'               => { "data division.  file section.  working-storage section.  linkage section." },
   'declaratives'       => { "declaratives.  ... end declaratives." },
   'delete'             => { "delete ... record" },
   'disable'            => { "disable" },
   'display'            => { "display" },
   'divide'             => { "divide ... into ..." },
   'else'               => { "else" },
   'enable'             => { "enable" },
   'end'                => { "end" },
   'end-accept'         => { "end-accept" },
   'end-add'            => { "end-add" },
   'end-call'           => { "end-call" },
   'end-compute'        => { "end-compute" },
   'end-delete'         => { "end-delete" },
   'end-display'        => { "end-display" },
   'end-divide'         => { "end-divide" },
   'end-evaluate'       => { "end-evaluate" },
   'end-exec'           => { "end-exec" },
   'end-if'             => { "end-if" },
   'end-multiply'       => { "end-multiply" },
   'end-of-page'        => { "end-of-page" },
   'end-perform'        => { "end-perform" },
   'end-read'           => { "end-read" },
   'end-receive'        => { "end-receive" },
   'end-return'         => { "end-return" },
   'end-rewrite'        => { "end-rewrite" },
   'end-search'         => { "end-search" },
   'end-start'          => { "end-start" },
   'end-string'         => { "end-string" },
   'end-subtract'       => { "end-subtract" },
   'end-unstring'       => { "end-unstring" },
   'end-write'          => { "end-write" },
   'ending'             => { "ending" },
   'environment'        => { "environment division.  input-output section.  file-control." },
   'evaluate'           => { "evaluate ... when other ... end-evaluate" },
   'exec'               => { "exec ... end-exec" },
   'execute'            => { "execute ... end-exec" },
   'exit'               => { "exit" },
   'file'               => { "file section." },
   'file-control'       => { "file-control.  select ... assign to ..." },
   'function'           => { "function" },
   'generate'           => { "generate" },
   'giving'             => { "giving" },
   'go'                 => { "go to ..." },
   'identification'     => { "identification division.  program-id. ..." },
   'if'                 => { "if ... end-if" },
   'initialize'         => { "initialize" },
   'initiate'           => { "initiate" },
   'input-output'       => { "input-output section." },
   'inspect'            => { "inspect" },
   'linkage'            => { "linkage section." },
   'merge'              => { "merge" },
   'move'               => { "move ... to ..." },
   'multiply'           => { "multiply ... by ..." },
   'open'               => { "open" },
   'perform'            => { "perform" },
   'procedure'          => { "procedure division." },
   'program'            => { "program" },
   'program-id'         => { "program-id. ... end program ..." },
   'purge'              => { "purge" },
   'read'               => { "read ... record" },
   'receive'            => { "receive ... into ..." },
   'release'            => { "release" },
   'remainder'          => { "remainder" },
   'return'             => { "return ... record" },
   'rewrite'            => { "rewrite" },
   'search'             => { "search ... when ... end-search" },
   'select'             => { "select ... assign to ..." },
   'send'               => { "send" },
   'set'                => { "set ... to ..." },
   'sort'               => { "sort" },
   'special-names'      => { "special-names." },
   'start'              => { "start" },
   'stop'               => { "stop" },
   'string'             => { "string ... delimited by ... into ... end-string" },
   'subtract'           => { "subtract ... from ..." },
   'suppress'           => { "suppress printing" },
   'tallying'           => { "tallying" },
   'terminate'          => { "terminate" },
   'through'            => { "through" },
   'thru'               => { "thru" },
   'unstring'           => { "unstring ... delimited by ... into ... end-unstring" },
   'until'              => { "until" },
   'use'                => { "use" },
   'varying'            => { "varying ... from 1 by 1" },
   'when'               => { "when" },
   'working-storage'    => { "working-storage section." },
   'write'              => { "write" },
};

static SYNTAX_EXPANSION_INFO cobol_space_words_1974:[] = {
   'accept'             => { "accept ... from ..." },
   'access'             => { "access" },
   'add'                => { "add ... to ..." },
   'advancing'          => { "advancing" },
   'also'               => { "also" },
   'alter'              => { "alter ... to ..." },
   'alternate'          => { "alternate" },
   'ascending'          => { "ascending" },
   'assign'             => { "assign" },
   'author'             => { "author." },
   'call'               => { "call ... using ..." },
   'cancel'             => { "cancel" },
   'close'              => { "close" },
   'communication'      => { "communication section." },
   'compute'            => { "compute" },
   'configuration'      => { "configuration section.  source-computer. ...  object-computer. ..." },
   'continue'           => { "continue" },
   'data'               => { "data division.  file section.  working-storage section.  linkage section." },
   'declaritives'       => { "declaritives" },
   'delete'             => { "delete ... record" },
   'disable'            => { "disable" },
   'display'            => { "display" },
   'divide'             => { "divide ... into ..." },
   'else'               => { "else" },
   'enable'             => { "enable" },
   'environment'        => { "environment division.  configuration section.  source-computer.  ... object-computer.  ... input-output section.  file-control." },
   'exit'               => { "exit" },
   'file'               => { "file section." },
   'file-control'       => { "file-control.  select ... assign to ..." },
   'generate'           => { "generate" },
   'giving'             => { "giving" },
   'go'                 => { "go to ..." },
   'identification'     => { "identification division.  program-id. ..." },
   'if'                 => { "if" },
   'initialize'         => { "initialize" },
   'initiate'           => { "initiate" },
   'input-output'       => { "input-output section." },
   'inspect'            => { "inspect" },
   'linkage'            => { "linkage section." },
   'merge'              => { "merge" },
   'move'               => { "move ... to ..." },
   'multiply'           => { "multiply ... by ..." },
   'open'               => { "open" },
   'perform'            => { "perform" },
   'procedure'          => { "procedure division." },
   'program'            => { "program" },
   'program-id'         => { "program-id" },
   'read'               => { "read ... record" },
   'receive'            => { "receive ... into ..." },
   'release'            => { "release" },
   'remainder'          => { "remainder" },
   'return'             => { "return ... record" },
   'rewrite'            => { "rewrite" },
   'search'             => { "search ... when ... end-search" },
   'select'             => { "select ... assign to ..." },
   'send'               => { "send" },
   'set'                => { "set ... to ..." },
   'sort'               => { "sort" },
   'special-names'      => { "special-names." },
   'start'              => { "start" },
   'stop'               => { "stop" },
   'string'             => { "string ... delimited by ... into " },
   'subtract'           => { "subtract ... from ..." },
   'suppress'           => { "suppress printing" },
   'tallying'           => { "tallying" },
   'terminate'          => { "terminate" },
   'through'            => { "through" },
   'thru'               => { "thru" },
   'unstring'           => { "unstring ... delimited by ... into " },
   'until'              => { "until" },
   'use'                => { "use" },
   'varying'            => { "varying ... from 1 by 1" },
   'when'               => { "when" },
   'working-storage'    => { "working-storage section." },
   'write'              => { "write" },
};

static _str cobol_help_table:[][] = {
   "MOVE" => {
      "SPACES\tFill alphanumeric field with spaces",
      "SPACE\tSpace character",
      "NULL\tNull value",
      "NULLS\tFill field with null values",
      "HIGH-VALUE\tHigh value (one)",
      "HIGH-VALUES\tFill numeric field with ones",
      "LOW-VALUE\tLow value (zero)",
      "LOW-VALUES\tFill numeric field with zeroes",
      "ZERO\tNumeric value of zero",
      "ZEROS\tFill numeric field with zeroes",
      "ZEROES\tFill numeric field with zeroes",
      "CORR\t(Corresponding) Move like named fields from source to target",
      "CORRESPONDING\tMove like named fields from source to target",
      "FUNCTION\tInvoke intrinsic function"
   },
   "VALUE" => {
      "SPACES\tFill alphanumeric field with spaces",
      "SPACE\tSpace character",
      "NULL\tNull value",
      "NULLS\tFill field with null values",
      "HIGH-VALUE\tHigh value (one)",
      "HIGH-VALUES\tFill numeric field with ones",
      "LOW-VALUE\tLow value (zero)",
      "LOW-VALUES\tFill numeric field with zeroes",
      "ZERO\tNumeric value of zero",
      "ZEROS\tFill numeric field with zeroes",
      "ZEROES\tFill numeric field with zeroes"
   },
   "PIC" => {
      "X\tAlphanumeric character",
      "9\tNumeric character",
      "A\tAlphabetic character",
      "B\tfixed blank space",
      "P\tUsed with V to indicate position of the decimal point",
      "S\tIndicates that a numeric field is signed",
      "V\tIndicates the position of an assumed decimal point",
      "Z\tNumeric character, displayed as blank when zero",
      "CR\tCR or credit is displayed when the value is negative",
      "DB\tDB or debit is displayed when the value is negative",
      "$\tCauses the currency character to be written when the item is displayed",
      ",\tCauses a comma to be written in a numeric value when the data is displayed",
      ".\tCauses a decimal point to be written in the numeric value when the data is displayed",
      "+\tWrite the sign of the value when it is displayed",
      "-\tWrite the sign of the value when it is displayed",
      "0\tCauses zeroes to be inserted into a data item",
      "/\tDisplays a / character when a data item is displayed",
      "(2)\tRepeat previous character specification twice",
      "(n)\tRepeat previous character specification 'n' times",
   },
   "ACCEPT FROM" => {
      "COMMAND-LINE\tCommand line input",
      "SYSIN\tStandard input stream",
      "SYSERR\tStandard error output stream",
      "DATE\t[YY]YYMMDD format date, where [YY]YY is year, where MM is month [1-12], and DD is day of month [1-31]",
      "DAY\t[YY]YYDDD style date, where [YY]YY is year, DDD is number of days since Jan 1.",
      "TIME\tHHMMSSHH format time, where HH is military hour [0-23], MM is minutes, SS is seconds, and HH is hundredths of seconds.",
      "DAY-OF-WEEK\tOne digit, 1=Monday,...,7=Sunday"
   },
   "USING BY" => {
      "CONTENT\tPass parameter by content",
      "VALUE\tPass parameter by value",
      "REFERENCE\tPass by reference"
   },
   "ORGANIZATION" => {
      "SEQUENTIAL\tRecords are written in serial order and are read in the same order as written",
      "RELATIVE\tRecords are accessed by reference to their relative position in the file",
      "INDEXED\tSequential file that also allows random access like relative files"
   },
   "DELIMITER" => {
      "STANDARD-1",
      "STANDARD-2",
      "STANDARD-3"
   },
   "MODE" => {
      "SEQUENTIAL\tRecords are read in the order they were written",
      "RANDOM\tRecords may be accessed in any order",
      "DYNAMIC\tRecords may be accessed either sequentially or randomly"
   },
   "USAGE" => {
      "BINARY\tData is stored as a binary value",
      "BINARY-CHAR\tData is stored as binary character [SIGNED or UNSIGNED]",
      "BINARY-SHORT\tData is stored as binary short integer [SIGNED or UNSIGNED]",
      "BINARY-LONG\tData is stored as binary long integer [SIGNED or UNSIGNED]",
      "BINARY-DOUBLE\tData is stored as binary double integer [SIGNED or UNSIGNED]",
      "BIT\tData is stored as bit field",
      "BIT ALIGNED\tData is stored as an aligned bit field",
      "COMP\tData is stored in a format that is most effecient for processing by the system",
      "COMP-1\tData is stored in a format that is most effecient for processing by the system (scheme 1)",
      "COMP-2\tData is stored in a format that is most effecient for processing by the system (scheme 2)",
      "COMP-3\tData is stored in a format that is most effecient for processing by the system (scheme 3)",
      "COMP-4\tData is stored in a format that is most effecient for processing by the system (scheme 4)",
      "COMP-5\tData is stored in a format that is most effecient for processing by the system (scheme 4)",
      "COMPUTATIONAL\tData is stored in a format that is most effecient for processing by the system",
      "COMPUTATIONAL-1\tData is stored in a format that is most effecient for processing by the system (scheme 1)",
      "COMPUTATIONAL-2\tData is stored in a format that is most effecient for processing by the system (scheme 2)",
      "COMPUTATIONAL-3\tData is stored in a format that is most effecient for processing by the system (scheme 3)",
      "COMPUTATIONAL-4\tData is stored in a format that is most effecient for processing by the system (scheme 4)",
      "COMPUTATIONAL-5\tData is stored in a format that is most effecient for processing by the system (scheme 4)",
      "DISPLAY\tData is stored in a standard format -- in the same way it would be displayed when written",
      "FLOAT-SHORT\tData is stored as a normal floating point number",
      "FLOAT-LONG\tData is stored as a double-precision floating point number",
      "INDEX\tUse the data item as an index value for a table",
      "INTEGER\tData is stored as native integer type",
      "IS\toptional keyword",
      "NATIONAL\tData is stored in national format",
      "NUMERIC\tData is numeric",
      "OBJECT REFERENCE\tData stores reference to class instance or FACTORY",
      "PACKED-DECIMAL\tData is stored as a base 10 value",
      "POINTER\tData stores pointer to other data [TO type-name]",
      "PROGRAM-POINTER\tData stores pointer to program [TO program-prototype]"
   },
   "INVOKE" => {
      "SELF\tInvoke method on the current object",
      "SUPER\tInvoke method belong to the immediate parent of the current object"
   },
   "OPEN" => {
      "INPUT\tOpen file for sequential read access",
      "OUTPUT\tOpen file for sequential output",
      "I-O\tOpen file for random access input and output",
      "EXTEND\tOpen file for appending"
   },
   "ENABLE" => {
      "INPUT\tOpen communication device for input",
      "OUTPUT\tOpen communication device for output",
      "I-O\tOpen communication device for input and output",
   },
   "END" => {
      "PROGRAM\tEnd of program unit, matches with PROGRAM-ID",
      "CLASS\tEnd of class definition, matches with CLASS-ID",
      "FACTORY\tEnd of factory section of class definition",
      "FUNCTION\tEnd of function definition, matches with FUNCTION-ID.",
      "OBJECT\tEnd of object section of class definition",
      "METHOD\tEnd of class method definition, matches with METHOD-ID.",
      "INTERFACE\tEnd of interface definition, matches with INTERFACE-ID."
   },
   "ARITHMETIC" => {
      "NATIVE",
      "STANDARD"
   },
   "LOCALIZE" => {
      "LC_COLLATE",
      "LC_CYTPE",
      "LC_CURRENCY"
   },
   "BINARY-CHAR" => {
      "SIGNED\tNumber may be negative",
      "UNSIGNED\tNumber is greater than equal than zero"
   },
   "TYPE" => {
      "RH\tReport header, processed automatically at start of report",
      "REPORT HEADING\tProcessed automatically at start of report",
      "PH\tPage header, processed automatically at start of new page",
      "PAGE HEADING\tProcessed automatically at start of new page",
      "CH\tControl heading, processed at the beginning of the control group",
      "CONTROL HEADING\tProcessed at the beginning of the control group",
      "DE\tDetail item, actual data in report",
      "DETAIL\tDetail item, actual data in report",
      "CF\tControl footer, processed at the end of the control group",
      "CONTROL FOOTING\tProcessed at the end of the control group",
      "PF\tPage footer, processed automatically at the end of a page",
      "PAGE FOOTING\tProcessed automatically at the end of a page",
      "RF\tReport footer, processed automacially at the end of report",
      "REPORT FOOTING\tProcessed automatically at the end of report"
   },
   "FOREGROUND-COLOR" => {
      "0\tBlack",
      "1\tBlue",
      "2\tGreen",
      "3\tCyan",
      "4\tRed",
      "5\tMagenta",
      "6\tBrown",
      "7\tWhite",
      "8\tBright-Black",
      "9\tBright-Blue",
      "10\tBright-Green",
      "11\tBright-Cyan",
      "12\tBright-Red",
      "13\tBright-Magenta",
      "14\tBright-Brown",
      "15\tBright-White"
   },
   "BACKGROUND-COLOR" => {
      "0\tBlack",
      "1\tBlue",
      "2\tGreen",
      "3\tCyan",
      "4\tRed",
      "5\tMagenta",
      "6\tBrown",
      "7\tWhite"
   },
   "WITH" => {
      "DEBUGGING MODE\tused in SOURCE-COMPUTER statement of CONFIGURATION DIVISION",
      "PICTURE SYMBOL\tused in SPECIAL-NAMES section",
      "LOCK\tused in SELECT statement",
      "ALL OTHER\tused in SHARING clause of SELECT statement",
      "NO OTHER\tused in SHARING clause of SELECT statement",
      "READ ONLY\tused in SHARING clause of SELECT statement",
      "FOOTING\tused in FOOTING clause for FD declaration",
      "RESET\tused in PAGE clause of data definition",
      "POINTER\tused in data definition",
      "NO REWIND\tused in OPEN and CLOSE statements",
      "LOCK\tused in OPEN and CLOSE statements",
      "NO LOCK\tused in READ, REWRITE, and WRITE statements",
      "KEY\tused in ENABLE and DISABLE statements",
      "NO ADVANCING\tused in DISPLAY statement",
      "FILLER\tused in INITIALIZE statement",
      "TEST\tused in PERFORM statement",
      "DATA\tused in RECEIVE statement",
      "ESI\tused in SEND statement",
      "EMI\tused in SEND statement",
      "EGI\tused in SEND statement",
      "DUPLICATES\tused in SORT statement",
      "LENGTH\tused in START statement",
      "ERROR\tused in STOP statement",
      "NORMAL\tused in STOP statement"
   }
};

/* Returns non-zero number if fall through to enter key required */
boolean _cob_expand_enter()
{
   if(_EmbeddedLanguageKey(last_event())) return(false);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   get_line(auto line);
   if (p_TruncateLength) {
      line=substr(line,1,p_TruncateLength);
   }
   int new_col=0;
   int i=verify(line,'0123456789');  /* Skip the linenumbers */
   if ( ! i ) {
      i=8;
   }

   int n=0;
   typeless p;
   _str first_word='';
   _str rest='';
   parse substr(line,i) with first_word rest;
   parse first_word with first_word '.';

   if (last_char(strip(rest))=='.') {
      save_pos(p);
      for (n=0;n<20;++n) {
         up();
         _str line_before;get_line(line_before);
         int i_before=verify(line_before,'0123456789');
         if ( ! i_before ) {
            i_before=8;
         }
         _str first_word_before='';
         parse substr(line_before,i_before) with first_word_before rest;
         parse first_word_before with first_word_before '.';
         if (last_char(strip(rest))=='.') {
            break;
         }
         if (first_word_before!='' && pos(' 'first_word_before' ',COBOL_ENTER_WORDS,1,'i')) {
            restore_pos(p);
            call_root_key(ENTER);
            p_col=verify(line_before,' ','',i_before);
            return(false);
         }
      }
      restore_pos(p);
   }
   if ( last_char(strip(rest))!='.' && first_word!='' &&
        //pos(' 'first_word' ',COBOL_ENTER_WORDS,1,'i') &&
        pos(' 'first_word' ',COBOL_ENTER_WORDS2,1,'i')
        ) {
      int old_col=p_col;
      p_col=verify(line,' ','',i);
      tab();
      new_col=p_col;p_col=old_col;
      indent_on_enter(syntax_indent);
   } else {
      if ( first_word!='' ) {
         new_col=verify(line,' ','',i);
      } else {
         if ( i<8 ) {
            i=8;
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

   // notify user that we did something unexpected
   notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

   return(false);
}

static _str division_indent()
{
   save_pos(auto p);
   begin_word();
   int col = p_col;
   restore_pos(p);
   if (p_lexer_name=='cobol2000') {
      return(indent_string(col-1));
   } else {
      return(indent_string(7));
   }
}

static _str comment_indent()
{
   if (p_lexer_name=='cobol2000') {
      return('*');
   } else {
      return(indent_string(6)'*');
   }
}

static _str page_indent()
{
   if (p_lexer_name=='cobol2000') {
      return('/');
   } else {
      return(indent_string(6)'/');
   }
}

#if __OS390__
#define COMPUTER_NAME 'ibm system/390'
#elif __UNIX__
#define COMPUTER_NAME 'unix workstation'
#else
#define COMPUTER_NAME 'ibm personal computer'
#endif
static _str cobol_expand_space()
{
   if(_EmbeddedLanguageKey(last_event())) return(0);

   int status=0;
   _str tline='';
   get_line(tline);
   if (p_TruncateLength) {
      tline=substr(tline,1,p_TruncateLength);
      tline=strip(tline,'T');
   }
   _str line=strip(tline,'T');
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   typeless column=0;
   _str word=strip(tline,'L');
   if ( pos(' 'word'=',' 'def_cobol_levels' ') ) {
      column=eq_name2value(word,def_cobol_levels);
      if ( isinteger(column) ) {
         replace_line(indent_string(column-1):+strip(tline)' ');
         _end_line();
         return(0);
      }
   }
   int col;
   int i=verify(line,'0123456789');  /* Skip the linenumbers */
   if ( ! i ) {
      return(1);
   }
   _str aliasfilename='';
   _str orig_word=lowcase(strip(substr(line,i)));
   typeless words;
   cob_get_space_words(words);
   word=min_abbrev2(orig_word,words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=='' ) return(1);
   int leading_chars=verify(line,' '\t,'',i)-1;
   _str linenum_space=substr(line,1,leading_chars);
   int linenum_chars=text_col(linenum_space,leading_chars);
   if ( !is_ansi_2000() && linenum_chars < 11 ) {
      linenum_space=linenum_space:+substr('',1,11-linenum_chars);
   }
   _str leading_space=substr('',1,text_col(linenum_space,linenum_chars));

   doNotify := true;
   if ( word=='accept' ) {
      replace_line(linenum_space:+_word_case('accept'):+'  ':+_word_case('from '));
      //if ( is_ansi_2000() ) {
      //   insert_line(leading_space:+word_case('end-accept.'));
      //   up();
      //}
      p_col=text_col(leading_space)+8;
   } else if ( word=='add' ) {
      replace_line(linenum_space:+_word_case('add'):+'  ':+_word_case('to '));
      p_col=text_col(leading_space)+5;
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-add.'));
      //   up();
      //}
   } else if ( word=='alter' ) {
      replace_line(linenum_space:+_word_case('alter'):+'  ':+_word_case('to '));
      p_col=text_col(leading_space)+7;
   } else if ( word=='author' ) {
      replace_line(linenum_space:+_word_case('author. '));
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
   } else if ( word=='call' ) {
#if 0
      replace_line(linenum_space:+_word_case('call '));
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
#else
      replace_line(linenum_space:+_word_case('call'):+'  ':+_word_case('using '));
      p_col=text_col(leading_space)+6;
#endif
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-call.'));
      //   up();
      //}
   } else if ( word=='class-control' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('class-control.'));
      p_col=text_col(leading_space)+15;
   } else if ( word=='class-id' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('class-id.'));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('class .'));
      up(); p_col=text_col(leading_space)+11;
   } else if ( word=='class-object' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('class-object.'));
      insert_line( leading_space:+_word_case('end'):+' ':+_word_case('class-object.'));
      up();p_col=text_col(leading_space)+22;
   } else if ( word=='continue' ) {
      newLine := linenum_space:+_word_case('continue');
      replace_line(newLine);
      _TruncEndLine();

      // if we didn't change anything, then don't notify
      doNotify = (tline != newLine);
   } else if ( word=='compute' ) {
      //replace_line(linenum_space:+word_case('compute  = '));
      //p_col=text_col(leading_space)+9;
      // Don't put = because some users might not want space after =
      // and we are not saving any typing here since would have
      // to hit <END> key to move the cursor.
      newLine := linenum_space:+_word_case('compute ');
      replace_line(newLine);
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-compute.'));
      //   up();
      //}

      // if we didn't change anything, then don't notify
      doNotify = (tline != newLine);
   } else if ( word=='communication' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(leading_space:+_word_case('communication'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+23;
   } else if ( word=='configuration' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(leading_space:+_word_case('configuration'):+' ':+_word_case('section.'));
      insert_line(leading_space:+_word_case('source-computer. 'COMPUTER_NAME'.'));
      insert_line(leading_space:+_word_case('object-computer. 'COMPUTER_NAME'.'));
      up(2); p_col=text_col(leading_space)+23;
   } else if ( word=='data' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('data'):+' ':+_word_case('division.'));
      insert_line(leading_space:+_word_case('file'):+' ':+_word_case('section.'));
      insert_line('');
      insert_line(leading_space:+_word_case('working-storage'):+' ':+_word_case('section.'));
      insert_line('');
      insert_line(leading_space:+_word_case('linkage'):+' ':+_word_case('section.'));
      insert_line(page_indent());
      up(4);
      p_col=text_col(leading_space)+1;
   } else if ( word=='declaratives' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('declaratives.'));
      insert_line( leading_space:+_word_case('end'):+' ':+_word_case('declaratives.'));
      up();_TruncEndLine();
   } else if ( word=='delete') {
      replace_line(linenum_space:+_word_case('delete'):+'  ':+_word_case('record'));
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-delete.'));
      //   up();
      //}
      p_col=text_col(leading_space)+8;
   } else if ( word=='display') {
      newLine := linenum_space:+_word_case('display ');
      replace_line(newLine);
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-display.'));
      //   up();
      //}
      p_col=text_col(leading_space)+9;

      // if we didn't change anything, then don't notify
      doNotify = (tline != newLine);
   } else if ( word=='divide' ) {
      replace_line(linenum_space:+_word_case('divide'):+'  ':+_word_case('into '));
      p_col=text_col(leading_space)+8;
/*
   elseif word='else' then
      replace_line linenum_space||word_case(word)
      insert_line ''
      p_col=text_col(leading_space)+1;tab
*/
   } else if ( word=='environment' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('environment'):+' ':+_word_case('division.'));
      if (!is_ansi_1985()) {
         insert_line(leading_space:+_word_case('configuration'):+' ':+_word_case('section.'));
         insert_line(leading_space:+_word_case('source-computer. 'COMPUTER_NAME'.'));
         insert_line(leading_space:+_word_case('object-computer. 'COMPUTER_NAME'.'));
         insert_line('');
      }
      insert_line(leading_space:+_word_case('input-output'):+' ':+_word_case('section.'));
      insert_line(leading_space:+_word_case('file-control.'));
      insert_line('');
      insert_line(page_indent());
      up();
      p_col=text_col(leading_space)+1;
      tab();
   } else if ( word=='evaluate' && is_ansi_1985() ) {
      replace_line(linenum_space:+_word_case('evaluate '));
      p_col=text_col(leading_space)+1;
      tab();
      insert_line(substr('',1,p_col-1):+_word_case('when'):+' ':+_word_case('other '));
      insert_line(leading_space:+_word_case('end-evaluate'));
      up(2);
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
   } else if ( word=='execute') {
      replace_line(linenum_space:+_word_case('execute '));
      insert_line( leading_space:+_word_case('end-exec'));
      up();_end_line();
   } else if ( word=='exec') {
      replace_line(linenum_space:+_word_case('exec '));
      insert_line( leading_space:+_word_case('end-exec'));
      up();
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;
   } else if ( word=='exit' ) {
      newLine := linenum_space:+_word_case('exit ');
      replace_line(newLine);
      _TruncEndLine();
      /* insert_line '' */
      /* p_col=text_col(leading_space)+1 */
      // if we didn't change anything, then don't notify
      doNotify = (tline != newLine);
   } else if ( word=='factory' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('factory.'));
      insert_line( leading_space:+_word_case('end'):+' ':+_word_case('factory.'));
      up();
      _TruncEndLine();
   } else if ( word=='file' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(leading_space:+_word_case('file'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+14;
   } else if ( word=='file-control' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(leading_space:+_word_case('file-control.'));
      insert_line(leading_space:+_word_case('select'):+'  ':+_word_case('assign'):+' ':+_word_case('to '));
      p_col=text_col(leading_space)+8;
   } else if ( word=='function-id' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('function-id.'));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('function .'));
      up(); p_col=text_col(leading_space)+14;
   } else if ( word=='go' ) {
      replace_line(linenum_space:+_word_case('go'):+' ':+_word_case('to '));
      p_col=text_col(leading_space)+7;
   } else if ( word=='identification' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('identification'):+' ':+_word_case('division.'));
      insert_line(leading_space:+_word_case('program-id. '_strip_filename(p_buf_name,'pe')'.'));
      insert_line(comment_indent():+_word_case('author. '));
      insert_line(comment_indent():+_word_case('installation. '));
      insert_line(comment_indent():+_word_case('date-written. '));
      insert_line(comment_indent():+_word_case('date-compiled. '));
      insert_line(page_indent());
      insert_line('');
      p_col=text_col(leading_space)+1;
   } else if ( word=='if' ) {
      newLine := linenum_space:+_word_case('if ');
      replace_line(newLine);
      if (is_ansi_1985() ) {
         set_surround_mode_start_line();
         insert_line(leading_space:+_word_case('end-if'));
         set_surround_mode_end_line();
         up();
         _end_line();search('([~ ]|^)\c','@rh-');++p_col;

         // if we go into dynamic surround, we do not notify separately for syntax expansion
         doNotify = !do_surround_mode_keys(false, NF_SYNTAX_EXPANSION);
      } else {
         p_col=text_col(leading_space)+4;
         // if we didn't change anything, then don't notify
         doNotify = (tline != newLine);
      }
   } else if ( word=='input-output' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('input-output'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+22;
   } else if ( word=='interface-id' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('interface-id.'));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('interface .'));
      up();p_col=text_col(leading_space)+15;
   } else if ( word=='linkage' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('linkage'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+17;
   } else if ( word=='local-storage' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('local-storage'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+23;
   } else if ( word=='method-id' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('method-id.'));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('method .'));
      up();p_col=text_col(leading_space)+12;
   } else if ( word=='move' ) {
      replace_line(linenum_space:+_word_case('move'):+'  ':+_word_case('to '));
      p_col=text_col(leading_space)+6;
   } else if ( word=='multiply' ) {
      replace_line(linenum_space:+_word_case('multiply'):+'  ':+_word_case('by '));
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-multiply.'));
      //   up();
      //}
      p_col=text_col(leading_space)+10;
   } else if ( word=='object' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('object.'));
      insert_line( leading_space:+_word_case('end'):+' ':+_word_case('object.'));
      up();_end_line();
      p_col=text_col(leading_space)+9;
   } else if ( word=='object-storage' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('object-storage'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+24;
   } else if ( word=='perform' && is_ansi_1985() ) {
      replace_line(linenum_space:+_word_case('perform '));
      p_col=text_col(leading_space)+9;
   } else if ( word=='procedure' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      _str using_clause='';
      _UpdateContext(true);
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      int n=tag_get_num_of_context();
      for (i=1; i<=n; ++i) {
         int tag_flags=0;
         _str tag_type='';
         _str tag_class='';
         _str tag_name='';
         tag_get_detail2(VS_TAGDETAIL_context_flags,i,tag_flags);
         tag_get_detail2(VS_TAGDETAIL_context_type,i,tag_type);
         tag_get_detail2(VS_TAGDETAIL_context_class,i,tag_class);
         tag_get_detail2(VS_TAGDETAIL_context_name,i,tag_name);
         if ((tag_flags & VS_TAGFLAG_linkage) &&
             (!pos(VS_TAGSEPARATOR_class,tag_class)) &&
             (!pos(VS_TAGSEPARATOR_package,tag_class)) &&
             (tag_type=='var' || tag_type=='group')) {
            using_clause=using_clause' 'tag_name;
         }
      }
      if (using_clause!='') {
         using_clause=_word_case(' using'):+using_clause;
      }
      replace_line(linenum_space:+_word_case('procedure'):+' ':+_word_case('division'):+using_clause:+'.');
      p_col=text_col(leading_space)+20;
   } else if ( word=='program-id' && is_ansi_1985()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(leading_space:+_word_case('program-id. '_strip_filename(p_buf_name,'pe')'.'));
      insert_line(leading_space:+_word_case('end'):+' ':+_word_case('program '_strip_filename(p_buf_name,'pe')'.'));
      up(); p_col=text_col(leading_space)+13;
   } else if ( word=='read') {
      replace_line(linenum_space:+_word_case('read'):+'  ':+_word_case('record'));
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-read.'));
      //   up();
      //}
      p_col=text_col(leading_space)+6;
   } else if ( word=='receive') {
      replace_line(linenum_space:+_word_case('receive'):+'  ':+_word_case('into'));
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-receive.'));
      //   up();
      //}
      p_col=text_col(leading_space)+9;
   } else if ( word=='repository' && is_ansi_2000()) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('repository.'));
      p_col=text_col(linenum_space)+12;
   } else if ( word=='return') {
      replace_line(linenum_space:+_word_case('return'):+'  ':+_word_case('record'));
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-return.'));
      //   up();
      //}
      p_col=text_col(leading_space)+8;
   } else if ( word=='search') {
      replace_line(linenum_space:+_word_case('search '));
      insert_line(linenum_space:+_word_case('when '));
      insert_line(leading_space:+_word_case('end-search'));
      up(2);p_col=text_col(leading_space)+8;
   } else if ( word=='set' ) {
      replace_line(linenum_space:+_word_case('set'):+'  ':+_word_case('to '));
      p_col=text_col(leading_space)+5;
   } else if ( word=='select' ) {
      replace_line(linenum_space:+_word_case('select'):+'  ':+_word_case('assign'):+' ':+_word_case('to '));
      //if ( is_ansi_1985() ) {
      //   p_col=text_col(leading_space)+1;tab();
      //   insert_line(substr('',1,p_col-1):+word_case('when '));
      //   up();
      //}
      p_col=text_col(leading_space)+8;
   } else if ( word=='special-names' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('special-names.'));
      p_col=text_col(leading_space)+15;
   } else if ( word=='string' ) {
      replace_line(linenum_space:+_word_case('string '));
      p_col=text_col(leading_space)+1;tab();
      if ( is_ansi_1985() ) {
         col=p_col;
         insert_line(substr('',1,col-1):+_word_case('delimited'):+' ':+_word_case('by '));
         insert_line(substr('',1,col-1):+_word_case('into '));
         insert_line(leading_space:+_word_case('end-string'));
         up(3);
      } else {
         insert_line(substr('',1,p_col-1):+_word_case('delimited'):+' ':+_word_case('by '));
         insert_line(leading_space:+_word_case('into '));
         up(2);
       }
      p_col=text_col(leading_space)+8;
   } else if ( word=='subtract' ) {
      replace_line(linenum_space:+_word_case('subtract'):+'  ':+_word_case('from '));
      p_col=text_col(leading_space)+10;
      //if ( is_ansi_1985() ) {
      //   insert_line(leading_space:+word_case('end-subtract.'));
      //}
   } else if ( word=='suppress' ) {
      replace_line(linenum_space:+_word_case('suppress'):+' ':+_word_case('printing'));
      _TruncEndLine();
   } else if ( word=='unstring' ) {
      replace_line(linenum_space:+_word_case('unstring '));
      p_col=text_col(leading_space)+1;tab();
      if ( is_ansi_1985() ) {
         col=p_col;
         insert_line(substr('',1,col-1):+_word_case('delimited'):+' ':+_word_case('by '));
         insert_line(substr('',1,col-1):+_word_case('into '));
         insert_line(leading_space:+_word_case('end-unstring'));
         up(3);
      } else {
         insert_line(substr('',1,p_col-1):+_word_case('delimited'):+' ':+_word_case('by '));
         insert_line(leading_space:+_word_case('into '));
         up(2);
       }
      p_col=text_col(leading_space)+10;
   } else if ( word=='varying' ) {
      replace_line(linenum_space:+_word_case('varying'):+'  ':+_word_case('from 1'):+' ':+_word_case('by 1'));
      p_col=text_col(leading_space)+9;
   } else if ( word=='working-storage' ) {
      leading_space=division_indent();
      linenum_space=substr(linenum_space,1,length(leading_space));
      replace_line(linenum_space:+_word_case('working-storage'):+' ':+_word_case('section.'));
      p_col=text_col(leading_space)+25;
   } else /*if (pos(' 'word' ',COBOL_EXPAND_WORDS)) */ {
      newLine := linenum_space:+_word_case(word' ');
      replace_line(newLine);
      _end_line();search('([~ ]|^)\c','@rh-');++p_col;

      // if we didn't change anything, then don't notify
      doNotify = (tline != newLine);
   }

   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

int _cob_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   typeless cobol_space_words;
   cob_get_space_words(cobol_space_words);
   return AutoCompleteGetSyntaxSpaceWords(words, cobol_space_words, prefix, min_abbrev);
}

static boolean is_ansi_1985()
{
   return (p_LangId == "cob");
}
static boolean is_ansi_1974()
{
   return (p_LangId == "cob74");
}
static boolean is_ansi_2000()
{
   return (p_LangId == "cob2000");
}
static void cob_get_space_words(typeless & words)
{
   switch (p_LangId) {
   case "cob74":
      words=cobol_space_words_1974;
      break;
   case "cob":
      words=cobol_space_words_1985;
      break;
   case "cob2000":
   default:
      words=cobol_space_words_2000;
      break;
   }
}
#if 0
/*
Clark: This code is no longer works because _error_search is not set to the old 
search_for_error function which uses hte old _error_re2 variable.  

We need new code which suports the new error parsing that Mathew did.
Activing error regular expression based on the current files 
extension isn't great. Here are some possibilities:

Already works:
   * User can write a script which filters the compiler error output
      compile|filterScript
   * Add an error regular expression for microfocus COBOL and 
     write a _get_error_info_XXX function.
     Note: there is already a _get_error_info_microfocus function.

Possible new code
   * We could have error regular expression schemes and let the user
     pick the scheme per config/tool. allow user to define a _get_error_info_
     macro when there is a match for that error regular expression.

*/

//  Sample Micro Focus Version 2.5.25 error message.  Running under OS/2
//     2 program-id. test.
//* 106-S****************                                                      **
//**    PROGRAM-ID has illegal format
//
#define MICROFOCUS_RE '^\*(\*|) *{:n-?}\*'

static _str cobol_filename;
_str _error_re2,_error_parse;

void cob_init_error()
{
   _error_parse= find_index('cob-parse-error',PROC_TYPE);
   or_re(_error_re2,MICROFOCUS_RE);
   cobol_filename=p_buf_name;
}
void cob_parse_error(_str &filename,_str &line,_str &col,_str &err_msg,_str arg5='')
{
   int process_line=p_line;
   _str temp='';
   get_line(temp);
   /* Cursor error not supported by cobol  */
   /* since can't determine cobol filename. */
   if ( ! pos(MICROFOCUS_RE,temp,1,'r') || arg5!='' ) {
      parse_error_re(filename,line,col,err_msg,arg5);
      return;
   }
   filename=cobol_filename;
   _str error_code=substr(temp,pos('S0'),pos('0'));
   line=p_line;
   search('^[ \t]*:n','@rh-');
   if ( ! rc ) {
      get_line(temp);
      parse temp with line .;
      if ( ! isinteger(line) ) {
         line=p_line;
      }
   }
   p_line=process_line;
   down();
   get_line(err_msg);
   err_msg=error_code:+err_msg;
   col='';
}
#endif

static _str gtkinfo;
static _str gtk;

static _str cob_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   int status=0;
   _str ch=get_text();
   if (ch:==' ' || (ch=='*' && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(cob_next_sym());
   }
   int start_col=0;
   int start_line=0;
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
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch==':' && get_text()==':') {
      right();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static _str cob_prev_sym_same_line()
{
   int orig_linenum=p_line;
   _str result=cob_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1)) {
      //messageNwait('h2');
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}
static _str cob_prev_sym()
{ 
   _str ch=get_text();
   int status=0;
   if (ch=="\n" || ch=="\r" || ch=='' || _clex_find(0,'g')==CFG_COMMENT) {
      status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(cob_prev_sym());
   }
   if (_clex_find(0,'g')==CFG_LINENUM) {
      int clex_status=_clex_find(LINENUM_CLEXFLAG,'n-');
      // Ignore stuff after column 71. This was causing a overflowed stack
      // issue if this was non ignored. Since stuff after column 71 is not valid
      // anyway this is ok. 
      if (clex_status || (p_col>=72) ) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(cob_prev_sym());
   }
   int end_col=0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      end_col=p_col+1;
      for (;;) {
         if (p_col==1) break;
         left();
         if(_clex_find(0,'g')!=CFG_STRING) {
            right();
            break;
         }
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
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
   if (p_col==1) {
      up();_end_line();
      if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   if (ch==':' && get_text()==':') {
      left();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static int cob_before_id(_str &prefixexp,_str &lastid,
                         int &info_flags,_str &otherinfo)
{
   _str line='';
   _str first_word='';
   for (;;) {
      //say("cob_before_id(): gtk="gtk" info="gtkinfo);
      if (gtk==TK_ID) {
         switch (upcase(gtkinfo)) {
         // just skip over 'IS' keyword
         case 'IS':
            break;
         // file types expected
         case 'SELECT':
         case 'CLOSE':
         case 'DELETE':
         case 'DISABLE':
         case 'ENABLE':
         case 'INITIATE':
         case 'MERGE':
         case 'OPEN':
         case 'INPUT':
         case 'OUTPUT':
         case 'TERMINAL':
         case 'I-O':
         case 'EXTEND':
         case 'PURGE':
         case 'READ':
         case 'RECEIVE':
         case 'RETURN':
         case 'REWRITE':
         case 'FILE':
         case 'SEND':
         case 'SORT':
         case 'START':
         case 'TERMINATE':
         case 'UNLOCK':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // subroutines expected
         case 'PERFORM':
         case 'ERROR':
         case 'EXCEPTION':
         case 'OVERFLOW':
         case 'CALL':
         case 'GO':
         case 'GOTO':
         case 'PROCEDURE':
         case 'THRU':
         case 'THROUGH':
         case 'END':
         case 'INVALID':
         case 'DATA':
         case 'NORMAL':
         case 'EOP':
         case 'END-OF-PAGE':
            info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // class names and 'SELF' expected
         case 'INVOKE':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // data types expected
         case 'ACCEPT':
         case 'ADD':
         case 'GIVING':
         case 'ALLOCATE':
         case 'CANCEL':
         case 'COMPUTE':
         case 'DIVIDE':
         case 'INTO':
         case 'REMAINDER':
         case 'EVALUATE':
         case 'ALSO':
         case 'THROUGH':
         case 'NOT':
         case 'FREE':
         case 'DEPENDING':
         case 'IF':
         case 'INITIALIZE':
         case 'INSPECT':
         case 'CONVERTING':
         case 'REPLACING':
         case 'AFTER':
         case 'BEFORE':
         case 'ALL':
         case 'LEADING':
         case 'FIRST':
         case 'INITIAL':
         case 'REFERENCE':
         case 'CONTENT':
         case 'VALUE':
         case 'ASCENDING':
         case 'DESCENDING':
         case 'KEY':
         case 'MOVE':
         case 'MULTIPLY':
         case 'RETRY':
         case 'UNTIL':
         case 'VARYING':
         case 'RELEASE':
         case 'SEARCH':
         case 'WHEN':
         case 'EQUAL':
         case '=':
         case 'WITH':
         case 'ADVANCING':
         case 'SET':
         case 'UP':
         case 'DOWN':
         case 'OCCURS':
         case 'ADDRESS':
         case 'LENGTH':
         case 'STRING':
         case 'DELIMITED':
         case 'SUBTRACT':
         case 'UNSTRING':
         case 'COUNT':
         case 'DELIMITER':
         case 'WRITE':
         case 'REDEFINES':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         case 'USING':
         case 'RETURNING':
            prefixexp = gtkinfo' 'prefixexp;
            typeless before_using;
            save_pos(before_using);
            int before_line=p_RLine;
            while (before_line-p_RLine<20) {
               get_line(line);
               if (pos("PROCEDURE:bDIVISION",line,1,'wri')) {
                  restore_pos(before_using);
                  otherinfo='PROCEDURE';
                  break;
               }
               parse line with first_word .;
               if (pos(' 'first_word' ',COBOL_SYNTAX_WORDS,1,'i')) {
                  break;
               }
               up();
            }
            restore_pos(before_using);
            return(0);
         // TO requires more informatoin
         case 'TO':
            prefixexp = gtkinfo' 'prefixexp;
            typeless before_to;
            save_pos(before_to);
            //gtk=cob_prev_sym_same_line();
            gtk=cob_prev_sym();
            if (gtk==TK_ID && upcase(gtkinfo)=='GO') {
               prefixexp = "GOTO";
            } else {
               restore_pos(before_to);
            }
            return(0);
         // OF requires more informatoin
         case 'IN':
         case 'OF':
            prefixexp = gtkinfo' 'prefixexp;
            //gtk=cob_prev_sym_same_line();
            gtk=cob_prev_sym();
            if (gtk==TK_ID && upcase(gtkinfo)!='ADDRESS') {
               otherinfo = "HAS ":+gtkinfo;
            }
            return(0);
         // from requires more information
         case 'FROM':
         case 'BY':
            prefixexp = gtkinfo' 'prefixexp;
            break;
         // data declarations
         case 'CD':
         case 'FD':
         case 'SD':
         case 'RD':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // exception types expected
         case 'RAISING':
         case 'RAISE':
         case 'STATUS':
            info_flags |= VSAUTOCODEINFO_IN_THROW_STATEMENT;
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // class name expected
         case 'CLASS':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         // miscellaneous
         case 'ARITHMETIC':
         case 'LOCALIZE':
         case 'DISPLAY':
         case 'UPON':
         case 'LINE':
         case 'COL':
         case 'GENERATE':
         case 'REPORTING':
         case 'VALIDATE':
         case 'PROGRAM':
         case 'METHOD':
         case 'CLASS':
         case 'INTERFACE':
         case 'BACKGROUND-COLOR':
         case 'FOREGROUND-COLOR':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         case 'FUNCTION':
            prefixexp = gtkinfo' 'prefixexp;
            otherinfo=gtkinfo;
            return(0);
         case 'PIC':
         case 'PICTURE':
            prefixexp = 'PIC 'prefixexp;
            return(0);
         case 'BINARY-CHAR':
         case 'BINARY-SHORT':
         case 'BINARY-LONG':
         case 'BINARY-DOUBLE':
            prefixexp = 'BINARY-CHAR 'prefixexp;
            return(0);
         case 'USAGE':
         case 'ORGANIZATION':
         case 'MODE':
         case 'TYPE':
         case 'DELIMITER':
            prefixexp = gtkinfo' 'prefixexp;
            return(0);
         case 'COPY':
         case '-INC':
         case '++INCLUDE':
         case '%INCLUDE':
         case 'INCLUDE':
            prefixexp = 'COPY 'prefixexp;
            return(0);
         // don't know what to expect
         default:
            //say("cob_before_id(): identifier="gtkinfo", prefixexp="prefixexp);
            if (length(gtkinfo)==2 && isinteger(gtkinfo)) {
               gtk=cob_prev_sym_same_line();
               if (gtk=='' || p_col<=8) {
                  prefixexp = '01 'prefixexp;
               }
               return(0);
            } else if (prefixexp=='' ||
                       upcase(strip(prefixexp))=='USING' ||
                       upcase(strip(prefixexp))=='RETURNING') {
               //say("cob_before_id(): prefixexp=''");
               prefixexp = gtkinfo;
               typeless before_invoke;
               save_pos(before_invoke);
               gtk=cob_prev_sym();
               if (gtk==TK_ID && upcase(gtkinfo)=='INVOKE') {
                  otherinfo = 'OF 'prefixexp;
                  prefixexp = gtkinfo' 'prefixexp;
                  return(0);
               }
               restore_pos(before_invoke);
               prefixexp='';
            }
            break;
         }
      } else if (gtk==TK_NUMBER && length(gtkinfo)==2) {
         gtk=cob_prev_sym_same_line();
         if (gtk=='' || p_col<=8) {
            prefixexp = '01 'prefixexp;
         }
         return(0);
      } else {
         return(0);
      }
      gtk=cob_prev_sym_same_line();
      if (gtk=='') {
         return(0);
      }
   }
   return(0);
}

// auto member help and function help are bound to the space key
// for COBOL coding.  First attempt to bring up function help,
// if immediately following a "USING" statement, otherwise invoke
// member help.
//
_command void cobol_codehelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   //say("auto_codehelp_key()");
   if (!command_state()) {
      left();
      int cfg=_clex_find(0,'g');
      right();
      if (!_in_comment() && cfg!=CFG_STRING) {
         save_pos(auto p);
         word_chars := _clex_identifier_chars();
         if (pos('['word_chars']',get_text(),1,'r')) {
            left();
         }
         gtk=cob_prev_sym();
         _str word_before=(gtk==TK_ID)? gtkinfo:'';
         word_before=upcase(strip(word_before));
         gtk=cob_prev_sym_same_line();
         _str word_before_word_before=(gtk==TK_ID)? gtkinfo:'';
         word_before_word_before=upcase(strip(word_before_word_before));
         int word_before_col=(word_before_word_before!='')? p_col:1;
         restore_pos(p);
         if (word_before=='') return;
         //say("cobol_codehelp_key(): word="word_before" before="word_before_word_before);
         if (pos(' 'word_before' ',COBOL_SYNTAX_WORDS,1,'i') &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_SYNTAX_HELP)) {
            _do_function_help(false,false,true);
         } else if (length(word_before)==2 && word_before_col<=8 &&
             isinteger(word_before) && word_before<66 &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_SYNTAX_HELP)) {
            _do_function_help(false,false,true);
         } else if (word_before=='USING' &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP)) {
            _do_function_help(true,false,true);
         } else if (word_before=='RETURNING' &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP)) {
            _do_function_help(true,false,true);
         }
         if ((pos(' 'word_before' ',COBOL_PREFIXES,1,'i') ||
              word_before_word_before=='INVOKE') &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) &&
             word_before!='USING' && word_before!='RETURNING') {
            _do_list_members(true,false);
         } else if (cobol_help_table._indexin(word_before) &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_SYNTAX_HELP) &&
             (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
            _do_list_members(true,false);
         }
      }
   }
}

/**
 * If a symbol is followed by a paren, it might not be a function call, 
 * so ignore the paren if we can verify that the symbol is actually data. 
 * 
 * @param idexp_info    expression information 
 */
static void cob_maybe_ignore_paren(VS_TAG_IDEXP_INFO &idexp_info)
{
   if (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      _UpdateContext(true);
      tag_lock_context(false);
      int context_id = tag_find_context_iterator(idexp_info.lastid, true, false);
      if (context_id > 0) {
         tag_get_context_info(context_id, auto cm);
         if (tag_tree_type_is_data(cm.type_name)) {
            idexp_info.info_flags &= ~VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
      }
      tag_unlock_context();
   }
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
int _cob_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_in_comment()) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
//   say("_cob_get_expression_info(): operator="PossibleOperator);
   tag_idexp_info_init(idexp_info);
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      left();
      _str ch=get_text();
//      say("_cob_get_expression_info(): ch="ch'=');
      switch (ch) {
      case ' ':
         restore_pos(orig_pos);
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         int end_col=p_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         if (p_col==end_col && pos('['word_chars']',get_text(),1,'r')) {
            end_col++;
         }
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         restore_pos(orig_pos);
         left();
         gtk=cob_prev_sym();
         if (gtk!=TK_ID) {
            restore_pos(orig_pos);
            return(1);
         }
         if (upcase(gtkinfo)=='USING' || upcase(gtkinfo)=='RETURNING') {
//            say("_cob_get_expression_info(): found using");
            idexp_info.prefixexp=lowcase(gtkinfo);
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            _clex_skip_blanks('-');
            cob_prev_sym();
            if (gtk!=TK_ID && gtk!=TK_STRING) {
               return(1);
            }
            idexp_info.lastid=gtkinfo;
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            break;
         }
         restore_pos(orig_pos);
         left();
         break;
      case '(':
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         left();
         _clex_skip_blanks('-');
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            restore_pos(orig_pos);
            return(1);
         }
         end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         cob_maybe_ignore_paren(idexp_info);
         if (idexp_info.lastid!='' && pos(' 'idexp_info.lastid' ',COBOL_SYNTAX_WORDS,1,'i')) {
            restore_pos(orig_pos);
            return(1);
         }
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      case ':':
         if (get_text(1,(int)point('s')-1)!=':') {
            restore_pos(orig_pos);
            return(1);
         }
         int orig_col=p_col;
         right();
         // get the id after the ::
         // IF we are on a id character
         if (pos('['word_chars']',get_text(),1,'r')) {
            int start_col=p_col;
            int start_offset=(int)point('s');
            //search('[~'p_word_chars']|$','r@');
            _TruncSearchLine('[~'word_chars']|$','r');
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
         } else {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
         }
         p_col=orig_col;
         break;
      default:
         restore_pos(orig_pos);
         return(1);
      }
   } else {
      // check if we are in a string or number
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_NUMBER) {
         int clex_flag=(cfg==CFG_STRING)? STRING_CLEXFLAG:NUMBER_CLEXFLAG;
         int clex_status=_clex_find(clex_flag,'n-');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         clex_status=_clex_find(clex_flag,'o');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         int start_col=p_col;
         int start_offset=(int)point('s');
         clex_status=_clex_find(clex_flag,'n');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         clex_status=_clex_find(clex_flag,'o-');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         idexp_info.prefixexp='';
         idexp_info.lastidstart_col=start_col;
         idexp_info.lastidstart_offset=start_offset;
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col+1);
         p_col=start_col-1;
         gtk=cob_prev_sym();
         idexp_info.info_flags|=VSAUTOCODEINFO_IN_STRING_OR_NUMBER;
         int id_status=cob_before_id(idexp_info.prefixexp,idexp_info.lastid,idexp_info.info_flags,idexp_info.otherinfo);
         restore_pos(orig_pos);
         return(id_status);
      }
      // IF we are not on an id character.
      _str ch=get_text();
      //say("_cob_get_expression_info(): 2, ch="ch"=");
      int done=0;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',ch,1,'r')) {
         int first_col = 1;
         if (p_col > 1) {
            first_col=0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            if (get_text()=='(') {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            }
            idexp_info.prefixexp='';
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col-first_col;
            idexp_info.lastidstart_offset=(int)point('s');
            cob_maybe_ignore_paren(idexp_info);
            done=1;
         }
      }
      if(!done) {
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         int end_col=p_col;
         // Check if this is a function call
         //search('[~ \t]|$','r@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=='(') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         left();
         cob_maybe_ignore_paren(idexp_info);
      }
   }
   gtk=cob_prev_sym();
//   say("_cob_get_expression_info(): gtk="gtk" gtkinfo="gtkinfo);

   // look for Foo::Bar, alternate invocation syntax
   if (gtk=='::') {
      for (;;) {
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         gtk=cob_prev_sym_same_line();
         if (gtk!=TK_ID) {
            break;
         }
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         gtk=cob_prev_sym_same_line();
         if (gtk!='::') {
            break;
         }
      }
   }
   // look for preceeding keywords
   int status=0;
   if (gtk!='') {
      if (gtk=='.') gtk=cob_prev_sym();
      status=cob_before_id(idexp_info.prefixexp,idexp_info.lastid,idexp_info.info_flags,idexp_info.otherinfo);
      if (idexp_info.prefixexp=="PIC") {
         idexp_info.lastidstart_col+=length(idexp_info.lastid);
         idexp_info.lastid='';
      }
   }
   restore_pos(orig_pos);
   //search('[~'p_word_chars']|$','r@');
   _TruncSearchLine('[~'word_chars']|$','r');
   gtk=cob_next_sym();
   if (gtk==TK_ID && (upcase(gtkinfo)=='OF' || upcase(gtkinfo)=='IN')) {
      _str in_or_of=upcase(gtkinfo);
      gtk=cob_next_sym();
      if (gtk==TK_ID || gtk==TK_STRING) {
         idexp_info.otherinfo=in_or_of" ":+gtkinfo;
      }
   }
   restore_pos(orig_pos);
   if (PossibleOperator && idexp_info.prefixexp=='' && idexp_info.lastid=='') {
//      say("_cob_get_expression_info(): possible operator blowout");
      return(1);
   }
   return(status);
}

/**
 * Insert keyword help for certain COBOL syntax forms so that
 * we can get help on what keywords come next after the current
 * word, for example, the constants such as SPACES, NULL, ZEROS
 * following the keyword "VALUE" in a data definition.
 *
 * @param root_count     (reference) number of items inserted
 * @param keyword        keyword to look up
 */
static void _cob_insert_member_help(int &num_matches, int max_matches,
                                    _str keyword, _str lastid="",
                                    boolean exact_match=false)
{
   keyword = upcase(strip(keyword));
   lastid  = upcase(strip(lastid));
   if (cobol_help_table._indexin(keyword)) {
      help_array := cobol_help_table:[keyword];
      int i;
      for (i=0; i<help_array._length(); i++) {
         item := help_array[i];
         docs := "";
         parse item with item "\t" docs;
         if (exact_match && lastid!=item) continue;
         if (!exact_match && pos(lastid, item)!=1) continue;
         item=_word_case(item);
         tag_insert_match("", item, "statement", "", 1, "", 0, docs);
         if (++num_matches > max_matches) break;
      }
   }
}
/**
 * Find the return type of the given symbol.
 *
 * @param errorArgs          array of error arguments
 * @param tag_files          list of tag files to search
 * @param symbol             symbol to get return type of
 * @param search_class_name  class that symbol belongs to
 * @param match_type         tag type of symbol found
 * @param match_tag          composed tag of symbol found
 *
 * @return 0 on success, <0 on error.
 */
static int _cob_get_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                   _str symbol,_str search_class_name,
                                   _str &match_type,_str &match_tag,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //say("_cob_get_return_type_of(): symbol="symbol" search_class="search_class_name);
   tag_push_matches();

   // first try to find a variable
   int num_matches=0;
   tag_list_symbols_in_context(symbol, '', 0, 0, tag_files, '',
                               num_matches, def_tag_max_find_context_tags,
                               VS_TAGFILTER_ANYDATA,
                               VS_TAGCONTEXT_ONLY_locals|VS_TAGCONTEXT_ALLOW_locals,
                               true, false, visited, 0);
   if (num_matches<=0) {
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, tag_files, '',
                                  num_matches,def_tag_max_find_context_tags,
                                  VS_TAGFILTER_ANYDATA,
                                  VS_TAGCONTEXT_ALLOW_locals,
                                  true, false, visited, 0);
   }
   //say("_cob_get_return_type_of(): matches="num_matches);
   int i=0;
   _str match_tag_file='';
   _str match_tag_name='';
   _str match_tag_type='';
   _str match_file_name='';
   int match_line_no=0;
   _str match_class_name='';
   int match_tag_flags=0;
   _str match_signature='';
   _str match_return_type='';
   _str end_return_type='';
   if (num_matches > 0) {
      for (i=1; i<=tag_get_num_of_matches(); ++i) {
         tag_get_match(i,match_tag_file,match_tag_name,match_tag_type,
                       match_file_name,match_line_no,match_class_name,
                       match_tag_flags,match_signature,match_return_type);
         //say("_cob_get_return_type_of(): i="i" tag="match_tag_name" class="match_class_name" return="match_return_type);
         // check for "POINTER TO" in return type
         _str match_symbol='';
         int p=pos("pointer ",match_return_type,1,'i');
         if (p) {
            end_return_type=substr(match_return_type,p+8);
            p=pos('to ',end_return_type,1,'i');
            if (p==1) {
               end_return_type=substr(end_return_type,4);
            }
            parse end_return_type with match_symbol .;
         }
         // check for OBJECT REFERENCE TO in return type
         p=pos(' object reference ',' 'match_return_type' ',1,'i');
         if (p) {
            match_symbol='Base';
            end_return_type=substr(match_return_type,p+17);
            p=pos('factory ',end_return_type,1,'i');
            if (p==1) {
               end_return_type=substr(end_return_type,9);
            }
            p=pos('of ',end_return_type,1,'i');
            if (p==1) {
               end_return_type=substr(end_return_type,4);
            }
            p=pos('to ',end_return_type,1,'i');
            if (p==1) {
               end_return_type=substr(end_return_type,4);
            }
            if (end_return_type != '') {
               parse end_return_type with match_symbol .;
            }
         }
         // qualify the symbol
         if (match_symbol != '') {
            tag_qualify_symbol_name(match_type,match_symbol,search_class_name,p_buf_name,tag_files,false);
            if (match_type!='') {
               match_tag=tag_tree_compose_tag(match_tag_name,match_class_name,match_tag_type,
                                              match_tag_flags,match_signature,match_return_type);
               tag_pop_matches();
               return(0);
            }
         }
      }
   }

   // no variable found with that name, try class names
   tag_clear_matches();
   tag_list_symbols_in_context(symbol, search_class_name, 0, 0, tag_files, '',
                               num_matches,def_tag_max_find_context_tags,
                               VS_TAGFILTER_ANYSTRUCT, 0,
                               true, false, visited, 0);
   if (num_matches == 0 && search_class_name!='') {
      tag_list_symbols_in_context(symbol, '', 0, 0, tag_files, '',
                                  num_matches,def_tag_max_find_context_tags,
                                  VS_TAGFILTER_ANYSTRUCT, 0,
                                  true, false, visited, 0);
   }
   if (num_matches > 0) {
      for (i=1; i<=tag_get_num_of_matches(); ++i) {
         tag_get_match(i,match_tag_file,match_tag_name,match_tag_type,
                       match_file_name,match_line_no,match_class_name,
                       match_tag_flags,match_signature,match_return_type);
         //say("_cob_get_return_type_of(): i="i" tag="match_tag_name" class="match_class_name" return="match_return_type);
         if (match_tag_type=='class' || match_tag_type=='interface') {
            tag_qualify_symbol_name(match_type,symbol,search_class_name,match_file_name,tag_files,false);
            if (match_type!='') {
               match_tag=tag_tree_compose_tag(match_tag_name,match_class_name,match_tag_type,
                                              match_tag_flags,match_signature,match_return_type);
               tag_pop_matches();
               return(0);
            }
         }
      }
   }

   tag_pop_matches();
   errorArgs[1]=symbol;
   return(VSCODEHELPRC_RETURN_TYPE_NOT_FOUND);
}
/**
 * Evalues the prefix express, code help info flags, and otherinfo
 * in order to set up the pushtag flags, context flags, and other
 * flags used for insert_context_members.
 *
 * @param errorArgs          array of error arguments
 * @param cur_class_name     current class context
 * @param prefixexp          prefixexp, as given by _cob_get_expression_info
 * @param suffixexp          suffixexp, for special cases
 * @param match_class        (reference) class that symbol belongs to
 * @param pointer_count      (reference) pointer count
 * @param cob_return_flags   (reference) return flags
 * @param match_tag          (reference) set to tag found
 * @param files_only         (reference) expect files only?
 * @param funcs_only         (reference) expect paragraphs only?
 * @param data_only          (refernece) expect data items only?
 * @param context_flags      (reference) context flags
 * @param pushtag_flags      (reference) tag filter flags
 * @param depth              recursive search depth
 *
 * @return 0 on success, <0 on error.
 */
static int _cob_get_type_of_prefix(_str (&errorArgs)[], _str cur_class_name,
                                   _str prefixexp, _str suffixexp,
                                   VS_TAG_RETURN_TYPE &rt,
                                   int &context_flags, int &pushtag_flags,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{

   // no prefix expression, update globals and symbols from current context
   int status=0;
   _str qualified_name='';
   typeless tag_files = tags_filenamea(p_LangId);
   _str first_word='', second_word='';
   parse prefixexp with first_word second_word .;
   //say("_cob_get_type_of_prefix(): 1="first_word"= 2="second_word"=");
   switch (upcase(first_word)) {
   // file types expected
   case 'SELECT':
   case 'CLOSE':
   case 'DELETE':
   case 'DISABLE':
   case 'INITIATE':
   case 'MERGE':
   case 'INPUT':
   case 'OUTPUT':
   case 'TERMINAL':
   case 'I-O':
   case 'EXTEND':
   case 'PURGE':
   case 'READ':
   case 'RECEIVE':
   case 'RETURN':
   case 'REWRITE':
   case 'FILE':
   case 'SEND':
   case 'SORT':
   case 'START':
   case 'TERMINATE':
   case 'UNLOCK':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_FILES_ONLY;
      pushtag_flags = VS_TAGFILTER_DATABASE;
      break;
   // subroutines expected
   case 'ERROR':
   case 'EXCEPTION':
   case 'OVERFLOW':
   case 'GO':
   case 'GOTO':
   case 'PROCEDURE':
   case 'THRU':
   case 'THROUGH':
   case 'END':
   case 'INVALID':
   case 'DATA':
   case 'NORMAL':
   case 'EOP':
   case 'END-OF-PAGE':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_FUNCS_ONLY;
      pushtag_flags = VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC;
      break;
   case 'CALL':
      //funcs_only=true;
      pushtag_flags = /*VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC|*/VS_TAGFILTER_PACKAGE;
      break;
   case 'PERFORM':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_FUNCS_ONLY;
      pushtag_flags = VS_TAGFILTER_SUBPROC;
      break;
   case 'INVOKE':
      //say("_cob_get_type_of_prefix(): INVOKE");
      if (second_word=='') {
         pushtag_flags = VS_TAGFILTER_ANYSTRUCT|(VS_TAGFILTER_ANYDATA-VS_TAGFILTER_CONSTANT);
      } else {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_FUNCS_ONLY;
         pushtag_flags = VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC;
         if (upcase(second_word)=='SELF' || upcase(second_word)=='SUPER') {
            //say("_cob_get_type_of_prefix(): SELF");
            rt.return_type = upcase(strip(second_word));
         } else {
            status=_cob_get_return_type_of(errorArgs,tag_files,
                                           second_word,cur_class_name,
                                           qualified_name,rt.taginfo,
                                           visited, depth+1);
            if (status) {
               return(status);
            }
            rt.return_type = qualified_name;
         }
      }
      break;
   case 'USING':
      if (upcase(first_word)=='USING' && upcase(second_word)=="BY") {
         pushtag_flags = 0;
         break;
      }
   case 'ACCEPT':
      if (upcase(first_word)=='ACCEPT' && upcase(second_word)=="FROM") {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_FILES_ONLY;
         pushtag_flags = VS_TAGFILTER_DATABASE;
         break;
      }
   // data types (either condition or field) expected
   case 'IF':
   case 'SET':
   case 'EVALUATE':
   case 'WHEN':
   case 'IS':
   case '88':
   case 'UNTIL':
   case 'AND':
   case 'EQUAL':
   case 'NOT':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_DATA_ONLY;
      pushtag_flags = VS_TAGFILTER_ANYDATA|VS_TAGFILTER_DEFINE;
      break;
   // data types expected (accept case drops through)
   case 'RETURNING':
   case 'ADD':
   case 'TO':
   case 'GIVING':
   case 'ALLOCATE':
   case 'CANCEL':
   case 'COMPUTE':
   case 'DIVIDE':
   case 'INTO':
   case 'BY':
   case 'REMAINDER':
   case 'ALSO':
   case 'THROUGH':
   case 'FREE':
   case 'DEPENDING':
   case 'INITIALIZE':
   case 'INSPECT':
   case 'CONVERTING':
   case 'REPLACING':
   case 'AFTER':
   case 'BEFORE':
   case 'ALL':
   case 'LEADING':
   case 'FIRST':
   case 'INITIAL':
   case 'REFERENCE':
   case 'CONTENT':
   case 'VALUE':
   case 'ASCENDING':
   case 'DESCENDING':
   case 'KEY':
   case 'MOVE':
   case 'MULTIPLY':
   case 'RETRY':
   case 'VARYING':
   case 'RELEASE':
   case 'SEARCH':
   case '=':
   case 'WITH':
   case 'ADVANCING':
   case 'UP':
   case 'DOWN':
   case 'OCCURS':
   case 'ADDRESS':
   case 'LENGTH':
   case 'STRING':
   case 'DELIMITED':
   case 'SUBTRACT':
   case 'UNSTRING':
   case 'COUNT':
   case 'DELIMITER':
   case '01':
   case 'WRITE':
   case 'REDEFINES':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_DATA_ONLY;
      pushtag_flags = (VS_TAGFILTER_ANYDATA-VS_TAGFILTER_CONSTANT)|VS_TAGFILTER_DEFINE;
      break;
   case 'CD':
   case 'FD':
   case 'SD':
   case 'RD':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_FILES_ONLY;
      pushtag_flags = VS_TAGFILTER_DATABASE;
      break;
   case 'FROM':
      // file type or data
      pushtag_flags = (VS_TAGFILTER_ANYDATA-VS_TAGFILTER_CONSTANT)|VS_TAGFILTER_DEFINE|VS_TAGFILTER_DATABASE;
      break;
   // exception types expected
   case 'RAISING':
   case 'RAISE':
   case 'STATUS':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_DATA_ONLY;
      pushtag_flags = VS_TAGFILTER_ANYDATA|VS_TAGFILTER_DEFINE;
      break;
   // class name expected
   case 'CLASS':
      pushtag_flags = VS_TAGFILTER_ANYSTRUCT;
      break;
   // miscellaneous
   case 'DISPLAY':
   case 'UPON':
   case 'LINE':
   case 'COL':
   case 'GENERATE':
   case 'REPORTING':
   case 'VALIDATE':
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_DATA_ONLY;
      pushtag_flags = (VS_TAGFILTER_ANYDATA-VS_TAGFILTER_CONSTANT)|VS_TAGFILTER_DEFINE;
      break;
   // end program
   case 'PROGRAM':
      pushtag_flags = VS_TAGFILTER_PACKAGE;
      break;
   // end class
   case 'CLASS':
      pushtag_flags = VS_TAGFILTER_STRUCT;
      break;
   // end class
   case 'INTERFACE':
      pushtag_flags = VS_TAGFILTER_INTERFACE;
      break;
   // end method or function
   case 'METHOD':
      pushtag_flags = VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC;
      break;
   case 'FUNCTION':
      pushtag_flags = VS_TAGFILTER_PROTO;
      break;
   case 'COPY':
      pushtag_flags = VS_TAGFILTER_INCLUDE;
      context_flags |= VS_TAGCONTEXT_ALLOW_any_tag_type;
      break;
   // don't know what to expect
   case '':
   default:
      if (pos('::',first_word)) {
         parse first_word with rt.return_type '::';
         status=_cob_get_return_type_of(errorArgs,tag_files,
                                        rt.return_type,cur_class_name,
                                        qualified_name,rt.taginfo,
                                        visited, depth+1);
         if (status) {
            return(status);
         }
         rt.return_type = qualified_name;

      } else if (cobol_help_table._indexin(upcase(strip(prefixexp)))) {
         pushtag_flags = 0;
      } else {
         prefixexp='';
      }
      break;
   }

   // evaluate supplementary information
   if (suffixexp!=null && rt.return_type=='') {
      parse suffixexp with first_word second_word .;
      switch (first_word) {
      case 'IN':
      case 'OF':
         tag_qualify_symbol_name(rt.return_type,second_word,rt.return_type,p_buf_name,tag_files,false);
         break;
      default:
         break;
      }
   }
   //say("_cob_get_type_of_prefix(): match_class="match_class);

   // that's all folks
   return (0);
}

/**
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link _cob_get_expression_info()}.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastid_prefix      prefix of identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_*
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 *
 * @return 0 on sucess, nonzero on error
 */
int _cob_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           boolean find_parents,int max_matches,
                           boolean exact_match, boolean case_sensitive,
                           int filter_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_cob_find_context_tags("prefixexp","lastid")");
   errorArgs._makeempty();
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // get the current class and current package from the context
   cur_tag_name := cur_type_name := "";
   cur_class_name := cur_class_only := cur_package_name := "";
   cur_tag_flags := cur_type_id := cur_line_no := 0;
   context_id := tag_get_current_context(cur_tag_name, cur_tag_flags,
                                         cur_type_name, cur_type_id,
                                         cur_class_name, cur_class_only, cur_package_name);
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_line, context_id, cur_line_no);
   }

   // try stripping quotes off last_id, use this as a fallback if
   // the quoted name is not found
   lastid_noquotes := "";
   if (substr(lastid,1,1)=='"') {
      lastid_noquotes=strip(lastid,'B','"');
   } else if (substr(lastid,1,1)=="'") {
      lastid_noquotes=strip(lastid,'B',"'");
   }

   // no prefix expression, update globals and symbols from current context
   prefixexp=strip(prefixexp);
   first_word := second_word := "";
   file_name := "";
   prog_args := "";
   line_num := 0;
   tag_flags := 0;
   tag_type := "";
   tag_class := "";
   i := n := 0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   status := _cob_get_type_of_prefix(errorArgs, cur_class_name,
                                     prefixexp, otherinfo, rt,
                                     context_flags, filter_flags,
                                     visited, depth);

   if (upcase(rt.return_type)=='SELF') {
      rt.return_type=cur_class_name;
   } else if (upcase(rt.return_type)=='SUPER') {
      //say("_cob_find_context_tags(): class="cur_class_name);
      tag_dbs := "";
      parents := cb_get_normalized_inheritance(cur_class_name, tag_dbs, tag_files, true);
      //say("_cob_find_context_tags(): parents="parents);
      parse parents with rt.return_type ';' parents;
      // add each of them to the list also
      orig_db := tag_current_db();
      while (parents != '') {
         parse parents with auto p1 ';' parents;
         parse tag_dbs with auto t1 ';' tag_dbs;
         status = tag_read_db(t1);
         if (status < 0) {
            continue;
         }
         // add transitively inherited class members
         outer_class := "";
         tag_split_class_name(p1, rt.return_type, outer_class);
         status = tag_find_tag(rt.return_type, 'class', outer_class);
         tag_reset_find_tag();
         if (!status) {
            rt.return_type = p1;
            break;
         }
      }
   }
   //say("_cob_find_context_tags(): match_class="match_class" otherinfo="otherinfo);

   // make sure the pushtag flags are set up
   if (filter_flags == VS_TAGFILTER_SUBPROC) {
      tag_files=null;
   }

   // figure out flags for data types, in order to filter constants
   data_flags := VS_TAGFILTER_ANYDATA;
   switch (strip(upcase(prefixexp))) {
   case 'CALL':
      otherinfo=strip(upcase(prefixexp));
      break;
   case 'VALUE':
   case 'VALUES':
      otherinfo="VALUE";
      data_flags = VS_TAGFILTER_CONSTANT;
      break;
   }

   // handle special cases for functions, files, call
   if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_FUNCS_ONLY) && otherinfo=='') {
      otherinfo="PERFORM";
   }
   if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_FILES_ONLY) && otherinfo=='') {
      otherinfo="FD";
   }

   // clear out match set
   tag_clear_matches();
   num_matches := 0;

   // no prefix expression, so show categories
   if (prefixexp=='' || (otherinfo=='' && rt.return_type=='')) {

      //say("_cob_find_context_tags(): no prefix");

       // list suggestions for special clauses
      if (prefixexp!=null) {
         _cob_insert_member_help(num_matches, max_matches, upcase(prefixexp), lastid);
      }

      // insert variables from the current buffer
      tag_list_symbols_in_context(lastid, cur_class_name,
                                  0, 0, null, "",
                                  num_matches,max_matches,
                                  filter_flags,context_flags,
                                  exact_match,case_sensitive,
                                  visited,depth);
      if (lastid_noquotes != "") {
         tag_list_symbols_in_context(lastid_noquotes, cur_class_name, 
                                     0, 0, null, "",
                                     num_matches,max_matches,
                                     filter_flags,context_flags,
                                     exact_match,case_sensitive,
                                     visited,depth);
      }

      // update the symbols from current buffer, give case-sensitive matches preference
      if (cur_class_name=='' &&
          !(context_flags & VS_TAGCONTEXT_ONLY_inclass) &&
          !(context_flags & VS_TAGCONTEXT_NO_globals) &&
          (filter_flags != VS_TAGFILTER_PACKAGE) &&
          (filter_flags != VS_TAGFILTER_STRUCT)) {
         filter_flags_no_data := (filter_flags & ~(VS_TAGFILTER_ANYDATA));
         tag_list_any_symbols(0, 0, lastid, tag_files,
                              filter_flags_no_data, context_flags,
                              num_matches,max_matches,
                              exact_match, case_sensitive);
         if (lastid_noquotes != "") {
            tag_list_any_symbols(0, 0, lastid_noquotes, tag_files,
                                 filter_flags_no_data, context_flags,
                                 num_matches,max_matches,
                                 exact_match, case_sensitive);
         }
      }

   }

   if (filter_flags != 0) {
      if (otherinfo!=null && otherinfo!='') {
         parse otherinfo with first_word second_word .;
         switch (strip(upcase(first_word))) {
         case 'PERFORM':
            tag_list_any_symbols(0, 0, lastid, null,
                                 VS_TAGFILTER_SUBPROC, context_flags,
                                 num_matches, max_matches,
                                 exact_match, case_sensitive);
            if (lastid_noquotes != "") {
               tag_list_any_symbols(0, 0, lastid_noquotes, null,
                                    VS_TAGFILTER_SUBPROC, context_flags,
                                    num_matches, max_matches,
                                    exact_match, case_sensitive);
            }
            break;
         case 'CALL':
            //say("_cob_find_context_tags: HERE");
            tag_push_matches();
            num_programs := 0;
            tag_list_globals_of_type(0, 0, tag_files,
                                     VS_TAGTYPE_program,0,0,
                                     num_programs, max_matches);
            VS_TAG_BROWSE_INFO allMatches[];
            tag_get_all_matches(allMatches);
            n = tag_get_num_of_matches();
            tag_pop_matches();
            for (i=1; i<=n; ++i) {
               prog_name := allMatches[i].member_name;
               parse cur_class_name with cur_package_name ':' .;
               if (strieq(prog_name,cur_package_name)) {
                  continue;
               }
               tag_push_matches();
               context_count3 := 0;
               tag_list_in_class(prog_name,prog_name,0,0,
                                 tag_files,context_count3,10,
                                 VS_TAGFILTER_PROC,
                                 VS_TAGCONTEXT_ANYTHING,
                                 true,false,null,null,visited);
               prog_args = "";
               if (tag_get_num_of_matches()>=1) {
                  tag_get_detail2(VS_TAGDETAIL_match_args,1,prog_args);
               }
               tag_pop_matches();
               if (prog_args!='') {
                  tag_insert_match_info(allMatches[i]);
                  if (++num_matches > max_matches) break;
               }
            }
            break;
         case 'PROCEDURE':
            n=tag_get_num_of_context();
            for (i=1; i<=n; ++i) {
               tag_get_detail2(VS_TAGDETAIL_context_flags,i,tag_flags);
               tag_get_detail2(VS_TAGDETAIL_context_type,i,tag_type);
               tag_get_detail2(VS_TAGDETAIL_context_class,i,tag_class);
               if ((tag_flags & VS_TAGFLAG_linkage) &&
                   (!pos(VS_TAGSEPARATOR_class,tag_class)) &&
                   (!pos(VS_TAGSEPARATOR_package,tag_class)) &&
                   (tag_type=='var' || tag_type=='group')) {
                  tag_insert_match_fast(VS_TAGMATCH_context, i);
                  if (++num_matches > max_matches) break;
               }
            }
            break;
         case 'FD':
            n=tag_get_num_of_context();
            for (i=1; i<=n; ++i) {
               tag_get_detail2(VS_TAGDETAIL_context_type,i,tag_type);
               if (tag_type=='file') {
                  tag_insert_match_fast(VS_TAGMATCH_context, i);
                  if (++num_matches > max_matches) break;
               }
            }
            break;
         case 'FUNCTION':
            tag_list_globals_of_type(0, 0, tag_files,
                                     VS_TAGTYPE_proto,0,0,
                                     num_matches, max_matches);
            break;
         case 'VALUE':
            _cob_insert_member_help(num_matches, max_matches, "VALUE");
            break;
         case 'IN':
         case 'OF':
            tag_list_in_class(lastid,rt.return_type,
                              0, 0, tag_files,
                              num_matches, max_matches,
                              filter_flags,context_flags,
                              exact_match,case_sensitive,
                              null,null, visited, depth);
            if (lastid_noquotes != "") {
               tag_list_in_class(lastid_noquotes,rt.return_type,
                                 0, 0, tag_files,
                                 num_matches, max_matches,
                                 filter_flags,context_flags,
                                 exact_match,case_sensitive,
                                 null,null, visited, depth);
            }
            break;
         case 'HAS':
            _CodeHelpListClassesHaving(0, 0, tag_files,
                                       second_word, cur_class_name,
                                       VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_VAR,
                                       context_flags,
                                       num_matches, max_matches,
                                       exact_match, case_sensitive,
                                       visited, depth);
            break;
         }
      } else {
         if (rt.return_type=='') {
            rt.return_type=cur_class_name;
            tag_list_any_symbols(0, 0, lastid, null,
                                 filter_flags, context_flags,
                                 num_matches,max_matches,
                                 exact_match, case_sensitive);
            if (lastid_noquotes != "") {
               tag_list_any_symbols(0, 0, lastid_noquotes, null,
                                    filter_flags, context_flags,
                                    num_matches,max_matches,
                                    exact_match, case_sensitive);
            }
            tag_list_symbols_in_context(lastid, rt.return_type, 
                                        0, 0, tag_files, '',
                                        num_matches, max_matches,
                                        filter_flags,
                                        context_flags|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_FIND_all,
                                        exact_match, case_sensitive,
                                        visited, depth);
            if (num_matches==0 && lastid_noquotes!=null) {
               tag_list_symbols_in_context(lastid_noquotes, rt.return_type,
                                           0, 0, tag_files, '',
                                           num_matches, max_matches,
                                           filter_flags,
                                           context_flags|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_FIND_all,
                                           exact_match, case_sensitive,
                                           visited, depth);
            }
         }
         if (rt.return_type!='') {
            tag_list_in_class(lastid, rt.return_type,
                              0, 0, tag_files,
                              num_matches,max_matches,
                              filter_flags,context_flags,
                              exact_match, case_sensitive,
                              null,null,visited,depth);
            if (lastid_noquotes != "") {
               tag_list_in_class(lastid_noquotes, rt.return_type,
                                 0, 0, tag_files,
                                 num_matches,max_matches,
                                 filter_flags,context_flags,
                                 exact_match, case_sensitive,
                                 null,null,visited,depth);
            }
         }
      }
   }

   if (num_matches == 0) {
      errorArgs[1] = lastid;
      return(VSCODEHELPRC_NO_SYMBOLS_FOUND);
   }

   return(0);
}
/*
 * Format the given tag for display as the variable definition part
 * in list-members or function help.  This function is also used
 * for generating code (override method, add class member, etc.).
 * The current object must be an editor control.
 *
 * @param lang           Current language ID {@see p_LangId} 
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with.
 *
 * @return string holding formatted declaration.
*/
_str _cob_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   int tag_flags=info.flags;
   _str tag_name=info.member_name;
   _str class_name=info.class_name;
   _str type_name=info.type_name;
   int in_class_def=(flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   int verbose=(flags&VSCODEHELPDCLFLAG_VERBOSE);
   int show_class=(flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   int show_access=(flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   _str arguments = (info.arguments!='')? '('info.arguments')':'';
   _str proto='';

   //say("_pas_get_decl: type_name="type_name);
   switch (type_name) {
   case 'prog':         // Cobol program
      proto=_word_case("PROGRAM-ID"):+'. ':+tag_name;
      if (info.arguments!='') {
         strappend(proto,' '_word_case('USING')' 'info.arguments);
      }
      if (info.return_type!='') {
         strappend(proto,' '_word_case('RETURNING')' 'info.return_type);
      }
      return proto'.';
   case 'proc':         // procedure or command
   case 'proto':        // function prototype
   case 'constr':       // class constructor
   case 'destr':        // class destructor
   case 'func':         // function
   case 'subfunc':      // Nested function or cobol paragraph
   case 'subproc':      // Nested procedure or cobol paragraph
      proto='';
      if (type_name=='proto') {
         if (in_class_def) {
            strappend(proto,_word_case("METHOD-ID"):+'. ');
         } else {
            strappend(proto,_word_case("FUNCTION-ID"):+'. ');
         }
      }
      // prepend qualified class name for C++
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,'::',':');
         class_name = stranslate(class_name,'::','/');
         tag_name   = class_name'::'tag_name;
      }
      strappend(proto,tag_name);
      if (info.arguments!='') {
         strappend(proto,' '_word_case('USING')' 'info.arguments);
      }
      if (info.return_type!='') {
         strappend(proto,' '_word_case('RETURNING')' 'info.return_type);
      }
      //if (pos('proto',type_name)) {
      //   strappend(proto,' 'word_case('IS')' 'word_case('PROTOTYPE'));
      //}
      return proto'.';
   case 'procproto':    // Used for syntax help only
      proto=tag_name;
      _str syntax=info.arguments;
      while (syntax!='') {
         _str phrase='';
         parse syntax with '"' phrase '"' ',' syntax;
         strappend(proto,' 'phrase);
         if (syntax!='') {
            strappend(proto,"\n   ");
         }
      }
      return proto'.';

   case 'define':       // preprocessor macro definition
      return(decl_indent_string'>>':+_word_case("CONSTANT"):+' ':+tag_name:+' ':+_word_case("IS"):+' 'info.return_type);

   case 'typedef':      // type definition
      return(decl_indent_string:+_word_case('type'):+' 'tag_name' = 'info.return_type:+arguments);

   case 'gvar':         // global variable declaration
   case 'var':          // member of a class / struct / package
   case 'lvar':         // local variable declaration
   case 'prop':         // property
   case "param":        // function or procedure parameter
   case 'group':        // Container variable
      /*
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,'::',':');
         class_name = stranslate(class_name,'::','/');
         tag_name   = class_name'::'tag_name;
      }
      */
      return(decl_indent_string:+tag_name' 'info.return_type);

   case 'class':        // class definition
   case 'interface':    // interface, eg, for Java
      if (type_name=='class') {
         type_name="CLASS-ID";
      } else {
         type_name="INTERFACE-ID";
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,'.',':');
         class_name = stranslate(class_name,'.','/');
         tag_name   = class_name'.'tag_name;
      }
      return decl_indent_string:+_word_case(type_name):+'. 'tag_name'.';

   case 'label':        // label
      return(decl_indent_string:+_word_case("LABEL"):+' 'tag_name':');

   case 'import':       // package import or using
      return(decl_indent_string:+_word_case("CLASS")' '_word_case("CONTROL")'. 'tag_name' '_word_case('IS')' 'info.return_type'.');

   case 'friend':       // C++ friend relationship
      return(decl_indent_string:+_word_case('FRIEND')' 'tag_name:+arguments);
   case 'include':      // C++ include or Ada with (dependency)
      return(decl_indent_string:+_word_case('COPY')' 'tag_name'.');

   case 'form':         // GUI Form or window
      return(decl_indent_string:+'_form 'tag_name);
   case 'menu':         // GUI Menu
      return(decl_indent_string:+'_menu 'tag_name);
   case 'control':      // GUI Control or Widget
      return(decl_indent_string:+'_control 'tag_name);
   case 'eventtab':     // GUI Event table
      return(decl_indent_string:+'defeventtab 'tag_name);

   case 'const':        // pascal constant
      proto='';
      /*
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,'::',':');
         class_name= stranslate(class_name,'::','/');
         strappend(proto,class_name:+'::');
      }
      */
      strappend(proto,info.member_name);
      strappend(proto," "_word_case("IS")" "info.return_type);
      return(proto);

   case "file":         // COBOL file descriptor
      proto=_word_case('SELECT')' ';
      /*
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,'::',':');
         class_name= stranslate(class_name,'::','/');
         strappend(proto,class_name:+'::');
      }
      */
      strappend(proto,info.member_name);
      strappend(proto," "_word_case("IS")" "info.return_type);
      return(proto);

   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "cursor":       // Database result set cursor
      return(decl_indent_string:+_word_case(type_name)' 'tag_name);

   default:
      proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,'::',':');
         class_name= stranslate(class_name,'::','/');
         strappend(proto,class_name:+'::');
      }
      strappend(proto,info.member_name);
      if (info.return_type!='') {
         strappend(proto,' '_word_case('IS')' 'info.return_type);
      }
      return(proto);
   }
}

/*
 * Find the start of a function call.  This determines quickly whether
 * or not we are in the context of a function call.
 *
 * @param errorArgs                List of argument for codehelp error messages
 * @param OperatorTyped            When true, user has just typed last
 *                                 character of operator.
 *                                 <PRE>
 *                                    p->myfunc( &lt;Cursor Here&gt;
 *                                 </PRE>
 *                                 This should be false if
 *                                 cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList When true, user requested function help when
 *                                 the cursor was inside an argument list.
 *                                 <PRE>
 *                                    MessageBox(...,&lt;Cursor Here&gt;...)
 *                                 </PRE>
 *                                 Here we give help on MessageBox
 * @param FunctionNameOffset       (reference) Offset to start of first argument
 * @param ArgumentStartOffset      (reference) set to seek position of argument
 * @param flags                    (reference) bitset of VSAUTOCODEINFO_*
 *
 * @return
 *     0    Successful<BR>
 *     VSCODEHELPRC_CONTEXT_NOT_VALID<BR>
 *     VSCODEHELPRC_NOT_IN_ARGUMENT_LIST<BR>
 *     VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 */
int _cob_fcthelp_get_start(_str (&errorArgs)[],
                           boolean OperatorTyped,
                           boolean cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags
                          )
{
   //say("_cob_fcthelp_get_start");
   errorArgs._makeempty();
   flags=0;
   _str ch='';
   int status=0;
   typeless orig_pos;
   save_pos(orig_pos);
   typeless orig_seek=point('s');
   int first_less_than_seek=0;
   if (!ginFunctionHelp && cursorInsideArgumentList) {
      status=search('[.;()]','-rh@xcs');
      if (!status) {
         ch=get_text();
      }
      restore_pos(orig_pos);
   }

   _str lastid='';
   typeless junk;
   _str word='';
   typeless p='';
   typeless p1,p2,p3,p4;
   int end_col=0;
   int orig_col=p_col;
   int orig_line=p_line;
   word_chars := _clex_identifier_chars();
   status=search('[.;()]|[:][:]|['word_chars']#','-rih@xcs');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset= -1;
   for (;;) {
      if (status) {
         break;
      }
      int ch_len=match_length();
      ch=get_text(ch_len);
      //say("_cob_fcthelp_get_start(): ch="ch);
      if (ch=='(') {
         save_pos(p);
         if(p_col==1){up();_end_line();} else {left();}
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         ch=get_text();
         word=cur_word(junk);
         restore_pos(p);
         if (pos('['word_chars']',ch,1,'r')) {
            ArgumentStartOffset=(int)point('s')+1;
         } else {
            if (OperatorTyped && ArgumentStartOffset== -1) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (ch==')') {
               ArgumentStartOffset=(int)point('s')+1;
            }
         }
      } else if (ch==')') {
         status=find_matching_paren(true);
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
         restore_pos(p);
      } else if (ch=='.') {
         save_pos(p);
         p_col--;
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym();
         if (gtk==TK_ID && pos(' 'gtkinfo' ',' division section ',1,'i')) {
            gtk=cob_prev_sym();
         }
         restore_search(p1,p2,p3,p4);
         if (gtk==TK_ID && pos(' 'gtkinfo' ',COBOL_SYNTAX_WORDS,1,'i')) {
            ArgumentStartOffset=(int)point('s');
            FunctionNameOffset=(int)point('s');
            return(0);
         }
         restore_pos(p);
         p_col++;
         break;
      } else if (ch=='::') {
         save_pos(p);
         p_col--;
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym();
         restore_search(p1,p2,p3,p4);
         if (gtk==TK_ID) {
            ArgumentStartOffset=(int)point('s');
            FunctionNameOffset=(int)point('s');
            return(0);
         }
         restore_pos(p);
         p_col++;
         break;
      } else if (upcase(ch)=='USING') { // using
         //say("_cob_fcthelp_get_start(): using");
         ArgumentStartOffset=(int)point('s')+1;
         left();
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym();
         restore_search(p1,p2,p3,p4);
         if (gtk==TK_ID || gtk==TK_STRING) {
            right();
            FunctionNameOffset=(int)point('s');
         }
      } else if (upcase(ch)=='RETURNING') { // returning
         //say("_cob_fcthelp_get_start(): returning");
         ArgumentStartOffset=(int)point('s')+1;
         left();
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym();
         restore_search(p1,p2,p3,p4);
         if (gtk==TK_ID || gtk==TK_STRING) {
            right();
            FunctionNameOffset=(int)point('s');
         }
      } else if (ch!='' && pos(' 'ch' ',COBOL_SYNTAX_WORDS,1,'i')) {
         ArgumentStartOffset=(int)point('s');
         FunctionNameOffset=(int)point('s');
         return(0);
      } else if (length(ch)==2 && isinteger(ch)) {
         save_pos(p);
         left();
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym_same_line();
         restore_search(p1,p2,p3,p4);
         if (gtk=='' || p_col<=8) {
            restore_pos(p);
            ArgumentStartOffset=(int)point('s');
            FunctionNameOffset=(int)point('s');
            return(0);
         }
         restore_pos(p);
      } else if (pos('^['word_chars']#$',ch,1,'r')==1) {
         // unkown identifier or number, do nothing
      } else  {
         p_col++;
         break;
      }
      status=repeat_search();
   }

   if (ArgumentStartOffset<0) {
      ArgumentStartOffset=(int)point('s');
   } else {
      goto_point(ArgumentStartOffset);
   }
   left();
   left();
   search('[~ \t]|^','-rh@');
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      ch=get_text();
      if (ch==')') {
         FunctionNameOffset=ArgumentStartOffset-1;
         return(0);
      } else {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      end_col=p_col+1;
      search('[~'word_chars']\c|^\c','-rh@');
      lastid=_expand_tabsc(p_col,end_col-p_col);
      FunctionNameOffset=(int)point('s');
   }
   return(0);
}

#define RETURNINGPOS 100
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;
/*
 * Context Tagging&reg; hook function for retrieving the information about
 * each function possibly matching the current function call that
 * function help has been requested on.
 * <P>
 * This function also will do syntax help for COBOL, displaying
 * a syntax diagram for the statement under the cursor.
 *
 * @param errorArgs
 * @param FunctionHelp_list            (reference) Structure is initially empty.
 *                                     FunctionHelp_list._isempty()==true
 *                                     You may set argument lengths to 0.
 *                                     See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed    (reference) Indicates whether the data in
 *                                     FunctionHelp_list has been changed.
 *                                     Also indicates whether current
 *                                     parameter being edited has changed.
 * @param FunctionHelp_cursor_x        Indicates the cursor x position
 *                                     in pixels relative to the edit window
 *                                     where to display the argument help.
 * @param FunctionHelp_HelpWord        (reference) set to name of function
 * @param FunctionNameOffset           Offset to start of function name.
 * @param flags                        bitset of VSAUTOCODEINFO_*
 *
 * @return
 *    Returns 0 if we want to continue with function argument
 *    help.  Otherwise a non-zero value is returned and a
 *    message is usually displayed.
 *    <PRE>
 *    1    Not a valid context
 *    (not implemented yet)
 *    10   Context expression too complex
 *    11   No help found for current function
 *    12   Unable to evaluate context expression
 *    </PRE>
*/
int _cob_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   boolean &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   errorArgs._makeempty();
   //say("_cob_fcthelp_get");
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   FunctionHelp_list_changed=0;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   word_chars := _clex_identifier_chars();
   _str common='[.,;()]|['word_chars']#';
   _str cursor_offset=point('s');
   save_pos(auto p);
   int orig_left_edge=p_left_edge;
   goto_point(FunctionNameStartOffset);
   // struct class
   int status=search(common,'rhi@xc');
   int found_using_at=-1;
   int found_builtin_at=-1;
   int found_paren_at=-1;
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   int stack_top=0;
   ParamNum_stack[stack_top]=0;
   int nesting=0;
   for (;;) {
      if (status) {
         break;
      }
      int ch_len=match_length();
      _str ch=get_text(ch_len);
      //say("_cob_fcthelp_get(ch="ch"):"get_text(10)" top="stack_top);
      //say('cursor_offset='cursor_offset' p='point('s'));
      if (stack_top>0 && cursor_offset<=(int)point('s')+ch_len-1) {
         if (upcase(ch)=='RETURNING' && cursor_offset>(int)point('s')) {
            ParamNum_stack[stack_top]=RETURNINGPOS;
         }
         break;
      }
      if (cursor_offset<=(int)point('s')) {
         break;
      }

      // hit statement terminator or start of new expression
      if (ch=='.') {
         typeless dot_pos;
         save_pos(dot_pos);
         p_col--;
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym();
         if (gtk==TK_ID && pos(' 'gtkinfo' ',' division section ',1,'i')) {
            gtk=cob_prev_sym();
         }
         restore_search(p1,p2,p3,p4);
         restore_pos(dot_pos);
         if (gtk==TK_ID && pos(' 'gtkinfo' ',COBOL_SYNTAX_WORDS,1,'i')) {
            status=repeat_search();
            continue;
         }
         // period acts as statement seperator
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);

      } else if (ch==',') {
         // parameter seperator for parenthesized expressions
         if (stack_top && found_using_at!=stack_top && found_builtin_at!=stack_top) {
            ++ParamNum_stack[stack_top];
         } else {
            // lost here
            break;
         }

      } else if (ch==')') {
         // end of parenthesized expression
         if (stack_top > 0) {
            --stack_top;
         }
         if (stack_top<=0) {
            // The close paren has been entered for the outer most function
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }

      } else if (ch=='(') {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');
         found_paren_at=stack_top;

      } else if (upcase(ch)=='USING') {
         // CALL foobar USING ...
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s')+ch_len;
         p_col+=(ch_len-1);
         found_using_at=stack_top;

      } else if (upcase(ch)=='RETURNING') {
         // CALL foobar RETURNING ...
         if (found_using_at!=stack_top) {
            ++stack_top;
            ParamNum_stack[stack_top]=RETURNINGPOS;
            offset_stack[stack_top]=(int)point('s')+ch_len;
            p_col+=(ch_len-1);
         } else {
            ParamNum_stack[stack_top]=RETURNINGPOS;
         }

      } else if (ch!='' && pos(' 'ch' ',COBOL_SYNTAX_WORDS,1,'i')) {
         //say("_cob_fcthelp_get(): builtin");
         if (!stack_top) {
            ++stack_top;
            ParamNum_stack[stack_top]=1;
            offset_stack[stack_top]=(int)point('s');
            p_col+=(ch_len-1);
            found_builtin_at=stack_top;
         } else {
            if (stack_top>0 && stack_top!=found_builtin_at && stack_top!=found_using_at) {
               --stack_top;
            }
            if (stack_top<=0) {
               restore_pos(p);
               return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
            }
         }

      } else if (length(ch)==2 && isinteger(ch)) {
         typeless num_pos;
         save_pos(num_pos);
         left();
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         gtk=cob_prev_sym_same_line();
         int gtk_col=p_col;
         restore_search(p1,p2,p3,p4);
         restore_pos(num_pos);
         if (gtk=='' || gtk_col<=8) {
            if (!stack_top) {
               ++stack_top;
               ParamNum_stack[stack_top]=1;
               offset_stack[stack_top]=(int)point('s');
               p_col+=(ch_len-1);
               found_builtin_at=stack_top;
            } else {
               if (stack_top>0 && stack_top!=found_builtin_at && stack_top!=found_using_at) {
                  --stack_top;
               }
               if (stack_top<=0) {
                  restore_pos(p);
                  return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
               }
            }
         }

      } else if (pos('^['word_chars']#$',ch,1,'r')==1) {
         // parameter to using message
         //say("_cob_fcthelp_get(): ch="ch);
         if (!pos(' 'ch' ',' by returning reference content value ',1,'i')) {
            //say("_cob_fcthelp_get(): cursor="cursor_offset" seek="(int)point('s')+(ch_len-1));
            if (found_using_at==stack_top && cursor_offset>(int)point('s')+ch_len) {
               ++ParamNum_stack[stack_top];
            }
         }
         p_col+=(ch_len-1);
      }
      status=repeat_search();
   }
   if (stack_top<=0) {
      restore_pos(p);
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
   }
   FunctionHelp_list_changed=0;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   //say("_cob_fcthelp_get(): stack_top="stack_top);
   _UpdateContext(true);
   _UpdateLocals(true);
   typeless tag_files = tags_filenamea(p_LangId);
   _str cur_tag_name, cur_type_name, cur_class_name, cur_class_only, cur_package_name;
   int cur_tag_flags, cur_type_id;
   int context_id = tag_get_current_context(cur_tag_name,cur_tag_flags,
                                            cur_type_name,cur_type_id,
                                            cur_class_name,cur_class_only,
                                            cur_package_name);

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   idexp_info.lastid="";

   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]);
      boolean has_parenthesis = (get_text()=='(');
      boolean found_builtin=false;
      goto_point(offset_stack[stack_top]+1);
      //say("_cob_fcthelp_get(): point="point('s')' ch='get_text(10));
      idexp_info.lastidstart_col=p_col;
      idexp_info.lastid=cur_word(idexp_info.lastidstart_col);
      int lastid_pos;
      save_pos(lastid_pos);
      gtk=cob_prev_sym_same_line();
      int lastid_col=(gtkinfo=='')? 1:p_col;
      restore_pos(lastid_pos);
      if ((idexp_info.lastid!='' &&
           upcase(idexp_info.lastid)!='USING' && upcase(idexp_info.lastid)!='RETURNING' &&
           pos(' 'idexp_info.lastid' ',COBOL_SYNTAX_WORDS,1,'i')) ||
          (isinteger(idexp_info.lastid) && length(idexp_info.lastid)==2) && lastid_col<=8) {
         idexp_info.prefixexp='';
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)_QROffset();
         idexp_info.info_flags=0;
         idexp_info.otherinfo='';
         status=0;
         found_builtin=true;
      } else {
         status=_cob_get_expression_info(true,idexp_info,visited,depth);
      }

      errorArgs[1] = idexp_info.lastid;
      if (_chdebug) {
         say('prefixexp='idexp_info.prefixexp' lastid='idexp_info.lastid' lastidstart_col='idexp_info.lastidstart_col' info_flags='dec2hex(idexp_info.info_flags)' otherinfo='idexp_info.otherinfo' status='status);
      }
      //if (upcase(prefixexp)=='USING' || upcase(prefixexp)=='RETURNING') {
      //   prefixexp='';
      //}
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         //say("_cob_fcthelp_get(): paramNum="ParamNum);
         set_scroll_pos(orig_left_edge,p_col);

         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
            gLastContext_FunctionName :== idexp_info.lastid &&
            gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
            prev_otherinfo :== idexp_info.otherinfo &&
            prev_info_flags == idexp_info.info_flags &&
            prev_ParamNum   == ParamNum) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }

         // find matching symbols
         int tag_flags=0;
         boolean globals_only=false;
         _str signature='';
         _str return_type='';
         _str match_list[];
         _str match_symbol = idexp_info.lastid;
         VS_TAG_RETURN_TYPE rt;
         tag_return_type_init(rt);
         int  match_flags = VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC;
         match_flags |= VS_TAGFILTER_DEFINE;
         int no_of_matches;
         if (!found_builtin) {
            no_of_matches = tag_check_for_define(idexp_info.lastid, p_line, tag_files, match_symbol);
         }

         // find symbols matching the given class
         int num_matches = 0;
         tag_clear_matches();

         // analyse prefix epxression to determine effective class
         if (found_builtin) {
            _str search_symbol=match_symbol;
            //say("_cob_fcthelp_get(): match_symbol="match_symbol);
            if (upcase(match_symbol)=='EXECUTE') {
               search_symbol="EXEC";
            }
            if (isinteger(match_symbol) && length(match_symbol)==2 &&
                match_symbol<66 && (!is_ansi_2000() || match_symbol!=1)) {
               search_symbol="99";
            }
            tag_list_in_file(0, 0, search_symbol, tag_files, "builtins.cob",
                             VS_TAGFILTER_PROTO, VS_TAGCONTEXT_ANYTHING,
                             num_matches,def_tag_max_function_help_protos,true,false);
         } else if (num_matches==0) {
            if (idexp_info.prefixexp != '') {
               int context_flags, pushtag_flags;
               status = _cob_get_type_of_prefix(idexp_info.errorArgs, cur_class_name,
                                                idexp_info.prefixexp, idexp_info.otherinfo, rt,
                                                context_flags, pushtag_flags,
                                                visited);
               if (status && (status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) &&
                   (status!=VSCODEHELPRC_BUILTIN_TYPE || idexp_info.lastid!='')) {
                  restore_pos(p);
                  return status;
               }
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
                  globals_only = true;
               }
               if (upcase(rt.return_type)=='SELF') {
                  rt.return_type=cur_class_name;
               } else if (upcase(rt.return_type)=='SUPER') {
                  _str tag_dbs='';
                  _str parents = cb_get_normalized_inheritance(cur_class_name, tag_dbs, tag_files, true);
                  // add each of them to the list also
                  _str orig_db = tag_current_db();
                  while (parents != '') {
                     _str p1, t1, outer_class;
                     parse parents with p1 ';' parents;
                     parse tag_dbs with t1 ';' tag_dbs;
                     status = tag_read_db(t1);
                     if (status >= 0) {
                        // add transitively inherited class members
                        tag_split_class_name(p1, rt.return_type, outer_class);
                        status = tag_find_tag(rt.return_type, 'class', outer_class);
                        tag_reset_find_tag();
                        if (!status) {
                           rt.return_type = p1;
                        }
                     }
                  }
               }
            }
            tag_clear_matches();
            // try to find 'lastid' as a member of the 'match_class'
            // within the current context
            if (idexp_info.lastid!='') {
               //say("_cob_fcthelp_get(): match_symbol="match_symbol);
               int context_flags =  globals_only? 0:VS_TAGCONTEXT_ALLOW_locals;
               tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, false, visited, depth);

               if (num_matches==0 && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, false, visited, depth);
               }
               if (num_matches==0) {
                  // getting desperate, try for prototypes
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              VS_TAGFILTER_PROTO, 0,
                                              true, false, visited, depth);
               }
               if (num_matches==0) {
                  tag_list_any_symbols(0,0,match_symbol,tag_files,VS_TAGFILTER_PROC,
                                       VS_TAGCONTEXT_ONLY_inclass|VS_TAGCONTEXT_ONLY_funcs,
                                       num_matches, def_tag_max_function_help_protos,
                                       true,false);
               }
               if (substr(match_symbol,1,1)=='"' || substr(match_symbol,1,1)=="'") {
                  match_symbol=substr(match_symbol,2,length(match_symbol)-2);
               }
               if (num_matches==0) {
                  tag_list_any_symbols(0,0,match_symbol,tag_files,VS_TAGFILTER_PROC,
                                       VS_TAGCONTEXT_ONLY_inclass|VS_TAGCONTEXT_ONLY_funcs,
                                       num_matches, def_tag_max_function_help_protos,
                                       true,false);
               }
            }
         } else {
            idexp_info.lastid = match_symbol;
         }

         // check if the symbol was on the kill list for this extension
         if (_check_killfcts(match_symbol, rt.return_type, flags)) {
            continue;
         }
         int i, j;

         // remove duplicates from the list of matches
         int unique_indexes[]; unique_indexes._makeempty();
         _str duplicate_indexes[]; duplicate_indexes._makeempty();
         if (!found_builtin) {
            removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         } else {
            num_matches=tag_get_num_of_matches();
            for (i=0; i<num_matches; i++) {
               unique_indexes[i]=i+1;
               duplicate_indexes[i]='';
            }
         }
         int num_unique = unique_indexes._length();
         for (i=0; i<num_unique; i++) {
            j = unique_indexes[i];
            _str tag_file, proc_name, type_name, file_name, class_name;
            int line_no;
            tag_get_match(j,tag_file,proc_name,type_name,
                          file_name,line_no,class_name,tag_flags,
                          signature,return_type);
            //say("_cob_fcthelp_get(): proc_name="proc_name);
            // maybe kick out if already have match or more matches to check
            if (found_builtin && type_name!="procproto") {
               continue;
            }
            if (type_name=="procproto") {
               _str orig_signature=signature;
               signature='';
               while (orig_signature != '') {
                  _str line;
                  parse orig_signature with line "," orig_signature;
                  line=strip(strip(line),'B','"');
                  line=strip(line,'B',"'");
                  if (signature=='') {
                     signature=line;
                  } else {
                     strappend(signature,"\n     "line);
                  }
               }
            }
            if (match_list._length()>0 || i+1<num_unique) {
               //if (file_eq(file_name,p_buf_name) && line_no:==p_line) {
               //   say("_cob_fcthelp_get(): 2");
               //   continue;
               //}
               if (tag_tree_type_is_class(type_name)) {
                  continue;
               }
               if (signature=='' && (tag_flags & VS_TAGFLAG_extern)) {
                  continue;
               }
               if (type_name :== 'define') {
                  if (signature == '') {
                     continue;
                  }
                  return_type = '>>CONSTANT';
               }
            }
            if (class_name!='' && class_name!=proc_name && num_unique==num_matches) {
               proc_name = class_name '::' proc_name;
            }
            match_list[match_list._length()] = proc_name "\t" type_name "\t" signature "\t" return_type"\t"j"\t"duplicate_indexes[i];
         }

         // get rid of any duplicate entries
         //say("_cob_fcthelp_get(): num_matches="match_list._length());

         match_list._sort();
         _aremove_duplicates(match_list, false);

         //say("_cob_fcthelp_get(): num_matches="match_list._length());
         // translate functions into struct needed by function help
         boolean have_matching_params = false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            for (i=0; i<match_list._length(); i++) {
               int k = FunctionHelp_list._length();
               //say("_cob_fcthelp_get(): i="i" k="k);
               if (k >= def_tag_max_function_help_protos) break;
               _str match_tag_name, match_type_name, imatch, duplist;
               parse match_list[i] with match_tag_name "\t" match_type_name "\t" signature "\t" return_type"\t"imatch"\t"duplist;
               //say("_cob_fcthelp_get("match_tag_name","signature","return_type")");
               int base_length = length(match_tag_name);
               int dot_length=0;
               _str prototype = match_tag_name;
               if (found_builtin) {
                  prototype = match_symbol;
                  if (substr(signature,1,1)=='.') {
                     strappend(prototype,signature);
                     dot_length=1;
                  } else if (substr(signature,1,9)=='DIVISION.') {
                     strappend(prototype,' 'signature);
                     dot_length=10;
                  } else if (substr(signature,1,8)=='SECTION.') {
                     strappend(prototype,' 'signature);
                     dot_length=9;
                  } else {
                     strappend(prototype,' 'signature);
                  }
                  base_length=0;
               } else if (has_parenthesis) {
                  strappend(prototype,'('signature')');
                  base_length++;
               } else if (signature != '') {
                  strappend(prototype,' USING 'signature);
                  base_length+=7;
               }
               if (return_type != '') {
                  strappend(prototype," RETURNING "return_type);
               }
               FunctionHelp_list[k].prototype = prototype;
               FunctionHelp_list[k].argstart[0]=1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               FunctionHelp_list[k].ParamName='';
               FunctionHelp_list[k].ParamType='';

               _str z_tag_file, z_proc_name, z_type_name, z_file_name, z_class_name, z_signature, z_return_type;
               int z_line_no, z_tag_flags;
               tag_get_match((int)imatch,z_tag_file,z_proc_name,z_type_name,
                             z_file_name,z_line_no,z_class_name,z_tag_flags,
                             z_signature,z_return_type);
               FunctionHelp_list[k].tagList[0].comment_flags=0;
               FunctionHelp_list[k].tagList[0].comments=null;
               FunctionHelp_list[k].tagList[0].filename=z_file_name;
               FunctionHelp_list[k].tagList[0].linenum=z_line_no;
               FunctionHelp_list[k].tagList[0].taginfo=tag_tree_compose_tag(z_proc_name,z_class_name,z_type_name,z_tag_flags,z_signature,z_return_type);
               int z1;
               _str z;
               for (z1=1;;) {
                  parse duplist with z duplist;
                  if (z=="") break;
                  if (z!=imatch) {
                     tag_get_match((int)z,z_tag_file,z_proc_name,z_type_name,
                                   z_file_name,z_line_no,z_class_name,z_tag_flags,
                                   z_signature,z_return_type);
                     FunctionHelp_list[k].tagList[z1].filename=z_file_name;
                     FunctionHelp_list[k].tagList[z1].linenum=z_line_no;
                     FunctionHelp_list[k].tagList[z1].comment_flags=0;
                     FunctionHelp_list[k].tagList[z1].comments=null;
                     FunctionHelp_list[k].tagList[z1].taginfo=tag_tree_compose_tag(z_proc_name,z_class_name,z_type_name,z_tag_flags,z_signature,z_return_type);
                     ++z1;
                  }
               }

               // parse signature and map out argument ranges ;
               //int j=1;
               int  arg_pos  = 0;
               _str argument = cb_next_arg(signature, arg_pos, 1);
               if (found_builtin) {
                  FunctionHelp_list[k].argstart[1]=1;
                  FunctionHelp_list[k].arglength[1]=length(match_symbol)+dot_length;
               } else {
                  while (argument != '') {
                     j = FunctionHelp_list[k].argstart._length();
                     FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                     FunctionHelp_list[k].arglength[j]=length(argument);
                     if (j==ParamNum) {
                        FunctionHelp_list[k].ParamName=argument;
                     }
                     argument = cb_next_arg(signature, arg_pos, 0);
                  }
                  if (return_type!='') {
                     j = FunctionHelp_list[k].argstart._length();
                     FunctionHelp_list[k].argstart[j]=pos(' RETURNING ',prototype)+1;
                     FunctionHelp_list[k].arglength[j]=length(return_type)+11;
                     if (ParamNum>=RETURNINGPOS) {
                        FunctionHelp_list[k].ParamNum=j;
                     }
                  }
               }
               if (ParamNum != 1 && j < ParamNum) {
                  if (have_matching_params) {
                     FunctionHelp_list._deleteel(k);
                  }
               } else {
                  if (!have_matching_params) {
                     VSAUTOCODE_ARG_INFO func_arg_info = FunctionHelp_list[k];
                     FunctionHelp_list._makeempty();
                     FunctionHelp_list[0] = func_arg_info;
                  }
                  have_matching_params = true;
               }
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=1;
               }
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
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName=idexp_info.lastid;
      gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}

/**
 * Get the default copy file path used by the compiler.
 *
 * @return '' if no path found.
 */
_str _CobolCopyFilePath(_str path=null)
{
   // get copy file include path for NetExpress
   if (path==null) {
      _str cobolList[];
      _CobolInstallPaths(cobolList);
      if (!cobolList._length()) {
         return('');
      }
      if (cobolList._length() > 1) {
         message(nls("Located multiple Cobol compilers, please run autotag."));
      }
      path=cobolList[0];
   }
   // copy file path for MicroFocus COBOL
   _str mf_copy_path = path :+PATHSEP:+
        path :+ 'BASECL'   :+PATHSEP:+
        path :+ 'GUICL'    :+PATHSEP:+
        path :+ 'TEMPLATE' :+FILESEP:+ 'GUIAPP' :+PATHSEP:+
        path :+ 'TEMPLATE' :+FILESEP:+ 'CONTAINER';

   if (path!='' && isdirectory(path:+FILESEP:+"BASECL",1)) {
      // this is MicroFocus
      if (!file_eq(def_cobol_copy_path,mf_copy_path)) {
         def_cobol_copy_path = mf_copy_path;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   } else {
      // Not MicroFocus
      if (file_eq(def_cobol_copy_path,mf_copy_path)) {
         def_cobol_copy_path = '';
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }

   // that's all
   return(def_cobol_copy_path);
}

/**
 * Build tag file for Fujitsu Personal COBOL or MicroFocus COBOL
 * compilers standard header files.  Uses registry to locate
 * the compiler and tags all the COBOL source code under their
 * include directory.
 *
 * @param tfindex   Tag file index
 */
static int generic_cob_MaybeBuildTagFile(int &tfindex, _str langId)
{
#if __UNIX__
   _str name_part='ucobol.vtg';
   _str basename='ucobol';
#else
   _str name_part='cobol.vtg';
   _str basename='cobol';
#endif

   // default language ID is cobol (Cobol 85)
   if (langId == null || langId== "") {
      langId = "cob";
   }

   // maybe we can recycle tag file(s)
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,langId,basename)) {
      return(0);
   }

   // The user does not have an extension specific tag file for InstallScript
   int status=0;

   tag_close_db(tagfilename);
   // get installation paths for Cobol compilers (see slickc.e)
   _str cobolList[];
   _CobolInstallPaths(cobolList);
   if (cobolList._length() > 1) {
      message(nls("Located multiple Cobol compilers, please run autotag."));
      return(1);
   }

   _str extra_file=ext_builtins_path("cob","cobol");
   if (!cobolList._length() || cobolList[0]=='') {
      //say("_cob_MaybeBuildTagFile: path="path);
      // build the tag file
      status=shell('maketags -n "COBOL Libraries" -o ' :+
                   maybe_quote_filename(tagfilename)' ' :+
                   maybe_quote_filename(extra_file));
   } else {
      //say("_cob_MaybeBuildTagFile: path="path);
      _str path=cobolList[0];
      _str copy_path=_CobolCopyFilePath(path);
      // build the tag file
      status=shell('maketags -n "COBOL Libraries" -t -o ' :+
                   maybe_quote_filename(tagfilename)' ' :+
                   maybe_quote_filename(path:+'*.cob')' ':+
                   maybe_quote_filename(path:+'*.ocb')' ':+
                   maybe_quote_filename(path:+'*.cbl'));
      if (!status && extra_file!='') {
         status=shell('maketags -r -o ' :+
                      maybe_quote_filename(tagfilename)' ' :+
                      maybe_quote_filename(extra_file));
      }
   }
   LanguageSettings.setTagFileList(langId, tagfilename, true);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   return(status);
}
int _cob_MaybeBuildTagFile(int &tfindex)
{
   return generic_cob_MaybeBuildTagFile(tfindex, "cob");
}
int _cob74_MaybeBuildTagFile(int &tfindex)
{
   return generic_cob_MaybeBuildTagFile(tfindex, "cob74");
}
int _cob2000_MaybeBuildTagFile(int &tfindex)
{
   return generic_cob_MaybeBuildTagFile(tfindex, "cob2000");
}

static _str gcobol_copy_path;
/**
 * Get the complete list of paths for finding cobol copy books
 * as a delimited string (path list)
 */
_str get_cobol_copy_path()
{
   // get the project or default COBOL project compiler include paths
   _str cobol_copy_path=gcobol_copy_path;
   if (gcobol_copy_path==null) {
      if (_project_name!=''|| (_isEditorCtl() && _LanguageInheritsFrom('cob'))) {
         cobol_copy_path=project_include_filepath();
         gcobol_copy_path=cobol_copy_path;
      } else {
         cobol_copy_path='';
         gcobol_copy_path=null;
      }
   }
   // append the def-var path, set up by autotag
   if (def_cobol_copy_path!='') {
      if (cobol_copy_path!='' && last_char(cobol_copy_path)!=PATHSEP) {
         strappend(cobol_copy_path,PATHSEP);
      }
      strappend(cobol_copy_path,def_cobol_copy_path);
   }
   // check for the new VSLICK_COBOL_PATH environment variable
   _str env_cobol_copy_path=get_env('VSLICKCOBOLPATH');
   if (env_cobol_copy_path!='') {
      if (cobol_copy_path!='' && last_char(cobol_copy_path)!=PATHSEP) {
         strappend(cobol_copy_path,PATHSEP);
      }
      strappend(cobol_copy_path,env_cobol_copy_path);
   }
   // check for the COBCPY environment variable
   env_cobol_copy_path=get_env('COBCPY');
   if (env_cobol_copy_path!='') {
      if (cobol_copy_path!='' && last_char(cobol_copy_path)!=PATHSEP) {
         strappend(cobol_copy_path,PATHSEP);
      }
      strappend(cobol_copy_path,env_cobol_copy_path);
   }
   // remove duplicates from the path and that's all folks!
   return(RemoveDupsFromPathList(cobol_copy_path,true));
}
/**
 * Get the configured list of file extensions that can contain 
 * COBOL copy books.
 */
_str get_cobol_copy_extensions()
{
   return def_cobol_copy_extensions;
}

/**
 * Callback functions for opening a project or modifying the
 * default .cob extension project properties.  Effectively, by
 * setting gcobol_copy_path to null, we reset the cobol lexer
 * and force the lexer to update its cache of the copy book
 * path as well as re-reading any copy books.
 */
void _prjopen_cobol()
{
   gcobol_copy_path=null;
}
/**
 * @see _projopen_cobol
 */
void _prjclose_cobol()
{
   gcobol_copy_path=null;
}
/**
 * @see _projopen_cobol
 */
void _prjupdate_cobol()
{
   gcobol_copy_path=null;
}
/**
 * @see _projopen_cobol
 */
void _prjupdatedirs_cobol()
{
   gcobol_copy_path=null;
}

/**
 * Callback used by dynamic surround to do 
 * language specific indentation and un-indentation.
 * 
 * @param direction '+' for indent, '-' for unindent
 */
void _cob_indent_surround(_str direction)
{
   // get the begin / end style setting
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   boolean doSecondIndent=(p_begin_end_style == BES_BEGIN_END_STYLE_2)? true:false;

   // temporarily remove the line number
   save_pos(auto p);
   lineNumber := "";
   _begin_line();
   boolean found_comment = false;
   if (_clex_find(0,'g')==CFG_LINENUM) {
      startOffset := _QROffset();
      int orig_line = p_line;
      _clex_find(LINENUM_CLEXFLAG,'N');
      if (p_line - 1 == orig_line) {
         up();
         _end_line();
      }
      endOffset := _QROffset();
      _begin_line();
      numChars := (int)(endOffset-startOffset);
      lineNumber = get_text(numChars);
      _delete_text(numChars);
      _insert_text(indent_string(numChars));
      p_col = 7; 
      found_comment = (_clex_find(0,'g')==CFG_COMMENT);
   }
   restore_pos(p);

   if (!found_comment) {
      if (direction=='+') {
         _indent_line(false);
         if (doSecondIndent) {
            indent_line();
         }
      } else {
         unindent_line();
         if (doSecondIndent) {
            unindent_line();
         }
      }
   }

   if (lineNumber != "") {
      save_pos(p);
      _begin_line();
      _delete_text(length(lineNumber),'C');
      _insert_text(lineNumber);
      restore_pos(p);
   }
}

