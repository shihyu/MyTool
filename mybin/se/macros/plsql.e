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
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "cutil.e"
#import "main.e"
#import "markfilt.e"
#import "notifications.e"
#import "optionsxml.e"
#import "pmatch.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  To install this macro, perform use
  the Load module dialog box ("Macro", "Load Module...").

  Built-in aliases

    IF THEN
    ENDIF;
    LOOP
    END LOOP;
    FOR  IN  LOOP
    END LOOP;
    WHILE  LOOP
    END LOOP;
    BEGIN
    END;
    WHEN  THEN
    ELSIF  THEN
    END
    EXCEPTION
    ELSE
    RETURN

    DECLARE
    BEGIN
    END;


*/

#define PLSQL_LANGUAGE_ID  'plsql'
#define PLSQL_MODE_NAME    'PL/SQL'
#define PLSQL_VLXLEXERNAME 'PL/SQL'
#define PLSQL_IDENTIFIER_CHARS  '@A-Za-z0-9_$#'

/**
 * @deprecated Use {@link LanguageSettings_API}
 */
boolean def_plsql_autocase=1;

/** 
 * These are used by _maybe_case_word and _maybe_case_backspace. 
 */
static int gWordEndOffset=-1;
static _str gWord;

defeventtab plsql_keys;
def  ' '= plsql_space;
def  '#'= plsql_maybe_case_word;
def  '$'= plsql_maybe_case_word;
def  '0'-'9'= plsql_maybe_case_word;
def  ';'= plsql_semi;
def  'A'-'Z'= plsql_maybe_case_word;
def  '_'= plsql_maybe_case_word;
def  'a'-'z'= plsql_maybe_case_word;
def  'ENTER'= plsql_enter;
def  'BACKSPACE'= plsql_maybe_case_backspace;

defload()
{
   _str setup_info='MN='PLSQL_MODE_NAME',TABS=+3,MA=1 74 1,':+
               'KEYTAB='PLSQL_LANGUAGE_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='PLSQL_IDENTIFIER_CHARS',LN='PLSQL_VLXLEXERNAME',CF=1,';
   _str compile_info='';
   // The first two number are syntax_indent amount and expand on/off
   // the restore of
   _str syntax_info='3 1 ':+   // <Syntax indent amount> <expansion on/off>
               '1 1 0';   // <min abbrev> <word_case> <begin/end style>
   _str be_info='';
   
   _CreateLanguage(PLSQL_LANGUAGE_ID, PLSQL_MODE_NAME,
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension('plsql', PLSQL_LANGUAGE_ID);

   // force the "sql" extension to refer to the PL/SQL language mode 
   int index=find_index('def-language-sql',MISC_TYPE);
   if (index) delete_name(index);
   index=find_index('def-lang-for-ext-sql',MISC_TYPE);
   if (index) delete_name(index);
   insert_name('def-lang-for-ext-sql',MISC_TYPE,'plsql');

   LanguageSettings.setReferencedInLanguageIDs(PLSQL_LANGUAGE_ID, "ansic c cob cob2000 cob74 db2 sqlserver");
}

_command plsql_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PLSQL_LANGUAGE_ID);
}
_command void plsql_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_plsql_expand_enter);
}
_command void plsql_semi() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      call_root_key(';');
      return;
   }

   // check if the word at the cursor is end
   int cfg=_clex_find(0,'g');
   get_line(auto line);
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || lowcase(line)!='end') {
      keyin(';');
      return;
   }
   typeless orig_pos;
   save_pos(orig_pos);
   up();_end_line();
   _str block_info="";
   int col=_plsql_find_block_col(block_info,true,true);
   restore_pos(orig_pos);
   if (col) {
      replace_line(indent_string(col-1)strip(line)';');_end_line();
   } else {
      keyin(';');
   }
}

_command plsql_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || !doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      plsql_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
         typeless orig_pos;
         save_pos(orig_pos);
         left();left();
         int cfg=_clex_find(0,'g');
         if (cfg==CFG_KEYWORD && LanguageSettings.getAutoCaseKeywords(p_LangId)) {
            int word_pcol=0;
            _str cw=cur_word(word_pcol);
            p_col=_text_colc(word_pcol,'I');
            _delete_text(length(cw));
            _insert_text(_word_case(cw));
         }
         restore_pos(orig_pos);
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO plsql_space_words:[] = {
   'if'         => { "IF ... THEN ... END IF;" },
   'loop'       => { "LOOP ... END LOOP;" },
   'for'        => { "FOR ... IN ... LOOP ... END LOOP;" },
   'while'      => { "WHILE ... LOOP ... END LOOP;" },
   'begin'      => { "BEGIN ... END;" },
   'when'       => { "WHEN ... THEN ..." },
   'end'        => { "END" },
   'return'     => { "RETURN" },
   'exception'  => { "EXCEPTION" },
   'else'       => { "ELSE" },
   'elsif'      => { "ELSIF" },
   'declare'    => { "DECLARE ... BEGIN ... END;" },
};


/*
    Returns true if nothing is done
*/
boolean _plsql_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

#if 0
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }

   // Skip comments to get some real code
   int status=_clex_skip_blanks("-");
   if (status) {
      return(1);
   }
   int col=0;
   int junk=0;
   _str word=cur_word(junk);
   if (lowcase(word)=='then') {
      first_non_blank();col=p_col;
      restore_pos(p);
      col+=syntax_indent;
      // IF user configured ENTER to indent with real spaces
      if( def_enter_indent ) {
         insert_line(indent_string(col-1));
      } else {
         insert_line('');
      }
      p_col=col;
      return(0);   // Indicate that we are done with enter key processing
   }
   restore_pos(p);

   return(1);
   // sample code below in case we get fancy.
#endif
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   int col=0;
   _str line="";
   _str block_info="";
   get_line(line);
   if ((lowcase(line)=='exception')  && p_col==_text_colc()+1) {
      col=_plsql_find_block_col(block_info,true,true);
      if (col) {
         replace_line(indent_string(col-1)_word_case(strip(line)));_end_line();
         save_pos(p);
      }

   } else if (lowcase(line)=='else' && p_col==_text_colc()+1) {
      col=_plsql_find_block_col(block_info,true,true);
      if (col && lowcase(block_info)!='if') {
         col+=syntax_indent;
      }
      if (col) {
         replace_line(indent_string(col-1)_word_case(strip(line)));_end_line();
         save_pos(p);
      }

   } else if (lowcase(line)=='begin' && p_col==_text_colc()+1) {
      col=_plsql_find_begin_block_col(true);
      if (col>0) {
         replace_line(indent_string(col-1)_word_case(strip(line)));_end_line();
         save_pos(p);
      }
   } else if (lowcase(line)=='declare' && p_col==_text_colc()+1) {
      col=_plsql_find_declare_block_col();
      if (col>0) {
         replace_line(indent_string(col-1)_word_case(strip(line)));_end_line();
         save_pos(p);
      }
   }

   int begin_col=plsql_begin_stat_col(false /* No RestorePos */,
                              false /* Don't skip first begin statement marker */,
                              false /* Don't return first non-blank */,
                              true  /* Return 0 if no code before cursor. */,
                              false,
                              true
                              );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(1);
   }
   restore_pos(p);
   col=plsql_indent_col(0);
   indent_on_enter(0,col);
   return(0);
}
/*
    Returns true if nothing is done.
*/
static boolean plsql_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   typeless status=0;
   get_line(auto orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word=strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }

   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,plsql_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=='') return(1);

   typeless p2=0;
   _str block_info="";
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);

   doNotify := true;
   set_surround_mode_start_line();
   if ( word=='if' ) {
      replace_line(_word_case(line:+'  then'));
      insert_line(indent_string(width)_word_case('end if;'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=5;
   } else if (word=='while') {
      replace_line(_word_case(line:+'  loop'));
      insert_line(indent_string(width)_word_case('end loop;'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=5;
   } else if (word=='for') {
      replace_line(_word_case(line:+'  in  loop'));
      insert_line(indent_string(width)_word_case('end loop;'));
      set_surround_mode_end_line();
      up();_end_line();p_col-=9;
   } else if (word=='loop') {
      replace_line(_word_case(line));
      insert_line(indent_string(width)_word_case('end loop;'));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='begin') {
      save_pos(p2);
      first_non_blank();
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      col:=_plsql_find_begin_block_col(false);
      restore_pos(p2);
      if (col<=0) {
         replace_line(_word_case(line));
         insert_line(indent_string(width)_word_case('end;'));
         set_surround_mode_end_line();
         up();_end_line();++p_col;
      } else {
         restore_pos(p2);
         replace_line(indent_string(col-1)_word_case('begin'));
         insert_line(indent_string(col-1)_word_case('end;'));
         set_surround_mode_end_line();
         up();_end_line();++p_col;
      }
   } else if (word=='declare') {
      save_pos(p2);
      col:=_plsql_find_declare_block_col();
      restore_pos(p2);
      if (col<0) {
         replace_line(_word_case(line));
         insert_line(indent_string(width)_word_case('begin'));
         insert_line(indent_string(width)_word_case('end;'));
         set_surround_mode_end_line();
         up(2);_end_line();++p_col;
      } else {
         restore_pos(p2);
         replace_line(indent_string(col-1)_word_case('declare'));
         insert_line(indent_string(col-1)_word_case('begin'));
         insert_line(indent_string(col-1)_word_case('end;'));
         set_surround_mode_end_line();
         up(2);_end_line();++p_col;
      }
   } else if (word=='when') {
      col:=_plsql_find_block_col(block_info,true,true);
      if (col) {
         replace_line(indent_string(col-1+syntax_indent)_word_case(orig_word'  then'));
         _end_line();p_col-=5;
      } else {
         replace_line(line:+_word_case('  then'));
         _end_line();p_col-=5;
      }
   } else if (word=='elsif') {
      col:=_plsql_find_block_col(block_info,true,true);
      if (col) {
         replace_line(indent_string(col-1)_word_case(orig_word'  then'));
         _end_line();p_col-=5;
      } else {
         newLine := _word_case(line);
         replace_line(newLine);
         _end_line();++p_col;

         doNotify = (newLine != line);
      }
   } else if (word=='end' || word=='exception') {
      save_pos(p2);
      if (word=='end') {
         up();_end_line();
      }
      col:=_plsql_find_block_col(block_info,true,true);
      restore_pos(p2);
      newLine := '';
      if (col) {
         newLine = indent_string(col-1)_word_case(orig_word);
      } else {
         newLine = _word_case(line);
      }
      replace_line(newLine);
      _end_line();++p_col;
      doNotify = (newLine != orig_line);
   } else if (word=='return') {
      newLine := _word_case(line);
      replace_line(newLine);
      _end_line();++p_col;
      doNotify = (newLine != line);
   } else if (word=='else') {
      save_pos(p2);
      if (word=='end') {
         up();_end_line();
      }
      col:=_plsql_find_block_col(block_info,true,true);
      restore_pos(p2);
      if (col && lowcase(block_info)!='if') {
         col+=syntax_indent;
      }

      newLine := '';
      if (col) {
         newLine = indent_string(col-1)_word_case(orig_word);
      } else {
         newLine = _word_case(line);
      }
      replace_line(newLine);
      _end_line();++p_col;
      doNotify = (newLine != line);
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

int _plsql_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, plsql_space_words, prefix, min_abbrev);
}

static boolean _isProtoType()
{
   typeless orig_pos;
   save_pos(orig_pos);
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   typeless status=search(';|is|as','@hrixcs');
   _str cw="";
   for (;;) {
      if (status) {
         restore_search(p1,p2,p3,p4);
         restore_pos(orig_pos);
         return(status);
      }
      if (match_length()==1) {
         cw=';';
         break;
      }
      int junk=0;
      cw=upcase(cur_word(junk));
      if(cw=='IS' || cw=='AS') {
         break;
      }
      status=repeat_search();
   }
   restore_search(p1,p2,p3,p4);
   restore_pos(orig_pos);
   return(cw==';');
}
/*

CREATE [OR REPLACE] PACKAGE name {IS|AS}
[BEGIN]
END
CREATE [OR REPLACE] PROCEDURE  name [(args)] {IS|AS}
CREATE [OR REPLACE] FUNCTION  name [(args)] RETURN type {IS|AS}
CREATE [OR REPLACE] TRIGGER name {BEFORE|AFTER} event ON table
 [FOR EACH ROW [WHEN trigger_condition]]
DECLARE
BEGIN
END

CREATE OR REPLACE PACKAGE mypackage AS
  FUNCTION a(x IN CHAR) RETURN VARCHAR2;
  PROCEDURE p(a IN CHAR);
END mypackage;

CREATE [OR REPLACE] TRIGGER mypackage
  AFTER INSERT OR DELETE OR UPDATE ON students
  [FOR EACH ROW [WHEN trigger condition]]
DECLARE
BEGIN
END [mypackage];
<<label>>

*/

_str plsql_proc_search(_str &proc_name,int find_first)
{
   typeless status=0;
   if ( find_first ) {
      word_chars := _clex_identifier_chars();
      _str variable_re='(['word_chars'.]#)';
      _str re='{#1(procedure|function|trigger|cursor)}[ \t]+{#0'variable_re'}';
         //_mdi.p_child.insert_line(re);
      mark_option := (p_EmbeddedLexerName != '')? 'm':'';
      status=search(re,'w:phri'mark_option'@xcs');
   } else {
      status=repeat_search();
   }

   _str type="";
   _str name="";
   _str line="";
   _str first_word="";
   _str keyword="";
   _str classname="";
   typeless orig_pos;
   save_pos(orig_pos);
   for (;;) {
      if ( status ) {
         restore_pos(orig_pos);
         break;
      }
      name=get_match_text(0);
      keyword=get_match_text(1);
      if (lowcase(keyword)=='cursor') {
         type='cursor)';
      } else {
         // Check if this is a prototype or procedure definition
         if (_isProtoType()) {
            type='proto)';
         } else {
            type='func)';
         }
      }
      get_line(line);
      parse line with first_word .;
      if (lowcase(first_word)=='drop' || lowcase(name)=='for') {
         status=repeat_search();
         continue;
      }
      parse name with classname'.'name;
      if (name=='') {
         name=classname;
         classname='(';
      } else {
         classname='(':+classname':';
      }
      name=name:+classname:+type;
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
void plsql_find_lastprocparam()
{
   save_pos(auto p);
   typeless startpos=_nrseek();
   int status=search("is|as|begin|declare","@hrwixcs");
   if (status) {
      restore_pos(p);
      return;
   }
   int orig_col=p_col;
   first_non_blank();
   if (p_col==orig_col) {
      up();_end_line();
   }
}

#if 0
/*

CREATE [OR REPLACE] PACKAGE name {IS|AS}
[BEGIN]
END
CREATE [OR REPLACE] PROCEDURE  name [(args)] {IS|AS}
CREATE [OR REPLACE] FUNCTION  name [(args)] RETURN type {IS|AS}
CREATE [OR REPLACE] TRIGGER name {BEFORE|AFTER} event ON table
 [FOR EACH ROW [WHEN trigger_condition]]
DECLARE
BEGIN
END

CREATE OR REPLACE PACKAGE mypackage AS
  FUNCTION a(x IN CHAR) RETURN VARCHAR2;
  PROCEDURE p(a IN CHAR);
END mypackage;

CREATE [OR REPLACE] TRIGGER mypackage
  AFTER INSERT OR DELETE OR UPDATE ON students
  [FOR EACH ROW [WHEN trigger condition]]
DECLARE
BEGIN
END [mypackage];
<<label>>

*/

static _str gStackEndBelongsTo[];
static _str gPackageName;
_str _proc_search(var proc_name,find_first)
{
   if ( find_first ) {
      variable_re='([A-Za-z]['WORD_CHARS']@)';
      gPackageName='';
      gStackEndBelongsTo._makeempty();
      re='(procedure|function|package|trigger)[ \t]+{#1(body[ \t]+|)}{#0'variable_re'}':+
         '|':+
         'end({#0};|[ \t]+{#0'variable_re'})':+
         '|':+
         'declare([~'WORD_CHARS']|$){#0}':+
         '|':+
         '<<{#0'variable_re'}>>';
         //_mdi.p_child.insert_line(re);
      status=search(re,'hri@xcs');
   } else {
      status=repeat_search();
   }
   save_pos(orig_pos);
   for (;;) {
      if ( status ) {
         restore_pos(orig_pos);
         break;
      }
      // Make sure we have a complete word match just in case
      // there is a new keyword like subend
      ch=get_text(2);
      if (ch!='<<') {
         if (p_col!=1) {
            left();
            if (get_text()!='') {
               right();
               status=repeat_search();
               continue;
            }
            right();
         }
         if (_clex_find(0,'g'):!=CFG_KEYWORD) {
            status=repeat_search();
            continue;
         }
      } else {
         cfg=_clex_find(0,'g');
         if (cfg:==CFG_COMMENT || cfg==CFG_STRING) {
            status=repeat_search();
            continue;
         }
      }
      ch=lowcase(ch);
      name=get_match_text(0);
      if (ch=='en') { // end keyword case
         if (name=='loop' || name=='if') {
             status=repeat_search();
             continue;
         }
         i=gStackEndBelongsTo._length()-1;
         if (i>=0) {
            EndBelongsTo=gStackEndBelongsTo[i];
            gStackEndBelongsTo._deleteel(i);
            if (EndBelongsTo=='package' || EndBelongsTo=='trigger') {
               gPackageName='';
            }
         }
         status=repeat_search();
         continue;
      }
      switch (ch) {
      case 'pr':
      case 'fu':
         save_pos(p);
         save_search(a,b,c,d);
         status=search(';|((^|[~'WORD_CHARS'])begin($|[~'WORD_CHARS']))','hrie@xcs');
         if (status) {
            restore_search(a,b,c,d);
            _end_line();
            status=repeat_search();
            continue;
         }
         type='proto';
         if (get_text():!=';') {
            type=(ch:=='fu')?'func':'proc';
            gStackEndBelongsTo[gStackEndBelongsTo._length()]='procedure';
         }
         restore_pos(p);
         restore_search(a,b,c,d);
         name=name'('gPackageName:+type')';
         break;
      case 'tr':
         gStackEndBelongsTo[gStackEndBelongsTo._length()]='trigger';
         status=repeat_search();
         name=name'('gPackageName:+'trigger)';
         continue;
      case 'pa':
         body=get_match_text(1);
         if (body:!='') {
            status=repeat_search();
            continue;
         }
         gPackageName=name':';
         gStackEndBelongsTo[gStackEndBelongsTo._length()]='package';
         name=name'(package)';
         break;
      case 'de':
         i=gStackEndBelongsTo._length()-1;
         if (i>=0) {
            EndBelongsTo=gStackEndBelongsTo[i];
            if (EndBelongsTo:=='trigger') {
               status=repeat_search();
               continue;
            }
         }
         gStackEndBelongsTo[gStackEndBelongsTo._length()]='declare';
         status=repeat_search();
         continue;
      case '<<':
         name=name'('gPackageName:+'label)';
         break;
      }
      if ( proc_name:=='' ) {
         proc_name=name;
         break;
      }
      if ( proc_name:==name ) {
         break;
      }
      status=repeat_search();
   }
   return(status)
}

/*
    This functions make show_procs smarter by showing user
    all parameters and attributes of the function definition
    but not the code.
*/
void _find_lastprocparam()
{
   save_pos(p);
   startpos=_nrseek();
   status=search("begin","hwixcs");
   if (status) {
      restore_pos(p);
      return;
   }
   orig_col=p_col;
   first_non_blank();
   if (p_col==orig_col) {
      up();
   }
}
#endif
/*
    If DECLARE is inside a block, then
    DECLARE belongs to itself. Otherwise,
    DECLARE may belong to a trigger.

   RETURN
      >0   Column position to place DECLARE keyword
      0    Error/Column position unknown
      -1   Indent to previous statement.

*/
int _plsql_find_declare_block_col()
{
   typeless orig_pos;
   save_pos(orig_pos);

   int status=search('begin|trigger|end','h@-riwxcs');
   if (status) {
      restore_pos(orig_pos);
      return(0);
   }
   int junk=0;
   _str cw=lowcase(cur_word(junk));
   if (cw!='trigger') {
      // This declare does not belong to anything
      restore_pos(orig_pos);
      return(-1);
   }
   first_non_blank();
   int col=p_col;
   restore_pos(orig_pos);
   return(col);
}

/*

   RETURN
      >0   Column position to place BEGIN keyword
      0    Error/Column position unknown
      -1   Indent to previous statement.
*/
int _plsql_find_begin_block_col(boolean skipFirstBegin)
{
   typeless orig_pos;
   save_pos(orig_pos);

   _str block_info="";
   int col=0;
   _str cw="";
   typeless status=0;
   for (;;) {
      status=search('begin|declare|function|procedure|package|trigger|end','h@-riwxcs');
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      int junk=0;
      cw=lowcase(cur_word(junk));
      //messageNwait('cw='cw' 'skipFirstBegin);
      if (cw=='function' || cw=='procedure') {
         // Check if this is a prototype
         if (_isProtoType()) {
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            continue;
         }
      }
      if (cw=='begin') {
         if (skipFirstBegin) {
            skipFirstBegin=false;
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            continue;
         } else {
            // This begin does not belong to anything
            restore_pos(orig_pos);
            return(-1);
         }
      }
      if (cw!='end') {
         first_non_blank();
         col=p_col;
         restore_pos(orig_pos);
         return(col);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      col=_plsql_find_block_col(block_info,false,false);
      if (!col) {
         restore_pos(orig_pos);
         return(0);
      }
      /*
          We are sitting on a begin for
          a function, procedure or trigger.
          It can't be a declare because you
          can't have a declare inside a declare.
          It can't be a package because you
          can't have a package inside a package.
      */
      status=search('function|procedure|trigger','h@-riwxcs');
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
   }
}

/*


  Block constructs
    IF EXPRESSION THEN
    ELSIF expression THEN
    ELSE

    END IF;

    [<<block_name>>]
    DECLARE
       declarations_statements
    BEGIN
    EXCEPTION
    END block_name;

    CREATE [OR REPLACE] TRIGGER mypackage
      AFTER INSERT OR DELETE OR UPDATE ON students
      [FOR EACH ROW [WHEN trigger condition]]
    DECLARE
    BEGIN
    EXCEPTION
    END [mypackage];

    [CREATE [OR REPLACE]] TRIGGER name {BEFORE|AFTER} event ON table
     [FOR EACH ROW [WHEN trigger_condition]]
    DECLARE
    BEGIN
    END;

    [CREATE [OR REPLACE]] PACKAGE mypackage AS
      FUNCTION a(x IN CHAR) RETURN VARCHAR2;
      PROCEDURE p(a IN CHAR);
    END mypackage;


    LOOP
    END LOOP;

    FOR expression IN [REVERSE] low_bound..high_bound LOOP
    END LOOP;

    WHILE expression LOOP
    END LOOP;



*/
int _plsql_find_block_col(_str &block_info/* currently just block word */,boolean restoreCursor,boolean returnFirstNonBlank)
{
   typeless orig_p2=0;
   typeless orig_pos;
   save_pos(orig_pos);
   int junk=0;
   int nesting;
   nesting=1;
   int begin_stat_col=0;
   _str word="";
   typeless p1,p2,p3,p4;
   typeless status=search('begin|end|package|if|loop|case','h@-wirxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      word=lowcase(get_match_text());
      //messageNwait(word);
      switch (word) {
      case 'begin':
         --nesting;
         break;
      case 'case':
         --nesting;
         break;
      case 'if':
         save_pos(orig_p2);
         if (p_col==1) {up();_end_line();} else {left();}
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         // when checking to see if this is 'IF' is part of 
         // an 'END IF' we need to make sure this 'END' isn't
         // the 'END;' terminating a declaration w/no block_name
         // [<<block_name>>]
         // DECLARE
         //    declarations_statements
         // BEGIN
         // EXCEPTION
         // END block_name;

         if (lowcase(cur_word(junk))=='end' && get_text()!=';') {
            p_col-=2;
            ++nesting;
            break;
         }
         restore_pos(orig_p2);
         --nesting;
         break;
      case 'package':
         // See if this is
         /*
            [CREATE [OR REPLACE]] PACKAGE mypackage AS
            ...
            END

               OR

            [CREATE [OR REPLACE]] PACKAGE BODY mypackage AS
            [BEGIN]
            ...
            END

            Since packages can't be nested inside
            packages, we are done.
         */
         nesting=0;
         break;
#if 0
         save_pos(orig_p2);
         save_search(p1,p2,p3,p4);
         p_col+=7;
         _clex_skip_blanks();
         if (lowcase(cur_word(junk))=='body') {
            restore_search(p1,p2,p3,p4);
            break;
         }
         restore_pos(orig_pos);
         if (p_col==1) {up();_end_line();} else {left();}
         _clex_skip_blanks('-');
         if (lowcase(cur_word(junk))=='replace') {
            p_col-=6;
            if (p_col==1) {up();_end_line();} else {left();}
            _clex_skip_blanks('-');
            if (lowcase(cur_word(junk))=='or') {
               p_col-=1;
               if (p_col==1) {up();_end_line();} else {left();}
               _clex_skip_blanks('-');
            }
         }
         word=cur_word(junk);
         if (lowcase(word)=='create') {
            p_col-=5;
            --nesting;
         } else {
            restore_pos(orig_p2);
         }
         restore_search(p1,p2,p3,p4);
         break;
#endif
      case 'loop':
         /*
           LOOP
           END LOOP;

           FOR expression IN [REVERSE] low_bound..high_bound LOOP
           END LOOP;

           WHILE expression LOOP
           END LOOP;
         */
         save_pos(orig_p2);
         if (p_col==1) {up();_end_line();} else {left();}
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         // when checking to see if this is 'LOOP' is part of 
         // an END LOOP we need to make sure this 'END' isn't
         // the 'END;' terminating a declaration w/no block_name
         // [<<block_name>>]
         // DECLARE
         //    declarations_statements
         // BEGIN
         // EXCEPTION
         // END block_name;
         if (lowcase(cur_word(junk))=='end' && get_text()!=';') {
            p_col-=2;
            ++nesting;
            break;
         }
         ++p_col;
         begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                         false /* Don't skip first begin statement marker */,
                                         false /* Don't return first non-blank */
                                         );
         restore_search(p1,p2,p3,p4);
         //messageNwait('begin_stat_col='begin_stat_col);
         --nesting;
         /*if (lowcase(cur_word(junk))=='loop') {
            restore_pos(orig_p2);
         } */

         break;
      case 'end':
         ++nesting;
         break;

      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         block_info=cur_word(junk);
         if (returnFirstNonBlank) {
            first_non_blank();
         }
         int col=p_col;
         if (restoreCursor) {
            restore_pos(orig_pos);
         }
         return(col);
      }
      status=repeat_search();
   }
}

/*


  Block constructs
    LOOP
    END LOOP;

    IF EXPRESSION THEN
    ELSIF expression THEN
    ELSE

    END IF;

    [<<block_name>>]
    DECLARE
       declarations_statements
    BEGIN
    EXCEPTION
    END block_name;

    CREATE [OR REPLACE] TRIGGER mypackage
      AFTER INSERT OR DELETE OR UPDATE ON students
      [FOR EACH ROW [WHEN trigger condition]]
    DECLARE
    BEGIN
    EXCEPTION
    END [mypackage];

    CREATE [OR REPLACE] TRIGGER name {BEFORE|AFTER} event ON table
     [FOR EACH ROW [WHEN trigger_condition]]
    DECLARE
    BEGIN
    END;

    CREATE OR REPLACE PACKAGE mypackage AS
      FUNCTION a(x IN CHAR) RETURN VARCHAR2;
      PROCEDURE p(a IN CHAR);
    END mypackage;


    FOR expression IN [REVERSE] low_bound..high_bound LOOP
    END LOOP;

    WHILE expression LOOP
    END LOOP;



*/
/*

   Return beginning of statement column.  0 if not found.

*/
static int plsql_begin_stat_col(boolean RestorePos,boolean SkipFirstHit,boolean ReturnFirstNonBlank,
                                boolean FailIfNoPrecedingText=false,
                                boolean AlreadyRecursed=false,
                                boolean FailWithMinus1_IfNoTextAfterCursor=false
                                )
{

   int orig_linenum=p_line;
   int orig_col=p_col;
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   typeless junk=0;
   _str word="";
   save_pos(auto p);
   typeless status=search('[;]|is|as|declare|then|loop|else|begin|elsif|exception','h-RI@xcs');
   int nesting=0;
   boolean hit_top=false;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         word=lowcase(get_match_text());
         if (word!=';' && word!=lowcase(cur_word(junk))) {
            SkipFirstHit=0;
            status=repeat_search();
            continue;
         }
         if (SkipFirstHit || nesting) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (word=='is' || word=='as') {
            if (AlreadyRecursed) {
               return(0);
            }
            // Check if this belongs to a create definition
            save_pos(auto p2);
            if (p_col==1) {up();_end_line();} else {--p_col;}
            typeless a1,a2,a3,a4;
            save_search(a1,a2,a3,a4);
            int begin_stat_col=plsql_begin_stat_col(
               false /* No RestorePos */,
               false /* Don't skip first begin statement marker */,
               false /* Don't return first non-blank */,
               false,
               true
               );
            restore_search(a1,a2,a3,a4);
            if (begin_stat_col &&
                (lowcase(cur_word(junk))=='create' ||
                lowcase(cur_word(junk))=='package' ||
                lowcase(cur_word(junk))=='function' ||
                lowcase(cur_word(junk))=='procedure')
                ) {
               restore_pos(p2);
            } else {
               restore_pos(p2);
               status=repeat_search();
               continue;
            }
         }
         p_col+=match_length();
      }
      status=_clex_skip_blanks();
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
      /*
          We could have the following:

            class name:public name2 {

          recurse to look for "case" keyword

      */
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
   int begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker */,
                                   true  /* return first non-blank */
                                   );

   if (begin_stat_col && (p_line<orig_linenum ||
                          (p_line==orig_linenum && p_col<=orig_col)
                         )
      ) {
#if 0
      /*
          We could have code at the top of a file like the following:

             int myproc(int i)<ENTER>

             int myvar=<ENTER>
             class foo :<ENTER>
                public name2

      */
      //messageNwait("fall through case 2");
      restore_pos(p);
      return(begin_stat_col);
#endif
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
      int col=p_col;
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         REPLACE<ENTER>
         <Cursor goes here>PROCEDURE

      */
      /*
      Here we assume that functions start in column 1 and
      variable declarations or statement continuations do not.
      This seems to be a common solution.
      */
      /*if (p_col==1 && ch!=',') {
         restore_pos(p);
         return(col);
      } */
      int nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
   }
   restore_pos(p);
   if (_expand_tabsc()=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   first_non_blank();
   int col=p_col;
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

   /*
       Note that here we don't return first non-blank to handle the
       following case:

       for (;
            ;<ENTER>) {

       However, this does effect the following unusual case
           if (i<j) {abc;<ENTER>def;
           <end up here which is not correct>

       We won't worry about this case because it is unusual.
   */
   int begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                   false /* Don't skip first begin statement marker. */,
                                   false /* Don't return first non-blank */,
                                   false,
                                   false,
                                   true   // Fail if no text after cursor
                                   );
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */
                                      );
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p);
      p_line=orig_linenum;p_col=orig_col;
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks("-");
      _str ch=get_text();
      if (ch:==")") {
         return(begin_stat_col);
      }
      restore_pos(p);
      /*
         IF semicolon is on same line as extra characters

         Example
            {b=<ENTER>
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
int plsql_indent_col(int non_blank_col, boolean pasting_open_block = false)
{
   int orig_col=p_col;
   int orig_linenum=p_line;
   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
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

   int col=0;
   int nesting=0;
   int OpenParenCol=0;
   int begin_stat_col=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   typeless status=search('[;()]|trigger|function|procedure|package|create|declare|is|as|then|loop|else|begin|elsif|exception|select|from|union|where','h-RI@xcs');
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
      _str word=get_match_text();
      int junk=0;
      if (word!=';' && word!=cur_word(junk)) {
         status=repeat_search();
         continue;
      }
      word=lowcase(word);

      //messageNwait("c_indent_col2: ch="ch);
      switch (word) {
      case ';':
         //messageNwait("case ;");
         save_pos(auto p2);
         int statdelim_linenum=p_line;
         begin_stat_col=plsql_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */
                                    );
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
         search('IF|ELSIF|WHEN','h-@rwixcs');
         first_non_blank();
         /*  IF expression THEN

         */
         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);

      case 'loop':
         //messageNwait('loop');
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
         /*
           LOOP
           END LOOP;

           FOR expression IN [REVERSE] low_bound..high_bound LOOP
           END LOOP;

           WHILE expression LOOP
           END LOOP;
         */
         typeless orig_p2;
         save_pos(orig_p2);
         if (p_col==1) {up();_end_line();} else {left();}
         /*save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         if (lowcase(cur_word(junk)=='end')) {
            p_col-=2;
            break;
         } */
         begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                         false /* Don't skip first begin statement marker */,
                                         false /* Don't return first non-blank */
                                         );
         //restore_search(p1,p2,p3,p4);
         //messageNwait('begin_stat_col='begin_stat_col);
         /*if (lowcase(cur_word(junk))=='loop') {
            restore_pos(orig_p2);
         } */
         restore_pos(p);
         return(begin_stat_col+syntax_indent);

         break;
      /*
         For the words below, we indent based on the first
         non-blank.
      */
      case 'else':
      case 'elsif':
      case 'begin':
      case 'exception':
      case 'select':
      case 'from':
      case 'union':
      case 'where':
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
      case 'declare':
      case 'create':
      case 'package':
      case 'function':
      case 'procedure':
      case 'trigger':
         first_non_blank();
         col=p_col+syntax_indent;
         restore_pos(p);
         return(col);
      case 'is':
      case 'as':
         // Check if this belongs to a create definition
         save_pos(p2);
         if (p_col==1) {up();_end_line();} else {--p_col;}
         typeless a1,a2,a3,a4;
         save_search(a1,a2,a3,a4);
         begin_stat_col=plsql_begin_stat_col(false /* No RestorePos */,
                                         false /* Don't skip first begin statement marker */,
                                         false /* Don't return first non-blank */
                                         );
         restore_search(a1,a2,a3,a4);
         if (begin_stat_col && lowcase(cur_word(junk))=='create') {
            restore_pos(p2);

            statdelim_linenum=p_line;
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

            col=begin_stat_col+syntax_indent;
            restore_pos(p);
            return(col);

         } else {
            restore_pos(p2);
            break;
         }

      default:
         _message_box('unknown word='word);
      }
      status=repeat_search();
   }

}
int plsql_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   typeless comment_col='';
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   get_line(auto first_line);
   int i=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!='' && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!='') || (!status && comment_col!='' && p_col!=comment_col)) {
      return(0);
   }

   typeless p2=0;
   typeless enter_col=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   int junk=0;
   _str block_info="";
   _str word=lowcase(cur_word(junk));
   boolean ignore_column1=false;
   if (!status && (word=='end' || word=='elsif' || word=='exception')) {
      save_pos(p2);
      up();_end_line();
      enter_col=_plsql_find_block_col(block_info,true,true);
      restore_pos(p2);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
   } else if (!status && (word=='else')) {
      //messageNwait('it was an else');
      save_pos(p2);
      up();_end_line();
      enter_col=_plsql_find_block_col(block_info,true,true);
      restore_pos(p2);
      if (enter_col && lowcase(block_info)!='if') {
         enter_col+=syntax_indent;
      }
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
   } else if (!status && (word=='begin')) {
      //messageNwait('it was an else');
      save_pos(p2);
      up();_end_line();
      enter_col=_plsql_find_begin_block_col(false);
      restore_pos(p2);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
      if (enter_col==-1) {
         _end_line();
         enter_col=plsql_enter_col();
         status=0;
      }
   } else if (!status && (word=='declare')) {
      //messageNwait('it was an else');
      save_pos(p2);
      up();_end_line();
      enter_col=_plsql_find_declare_block_col();
      restore_pos(p2);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();get_line(first_line);up();
      if (enter_col==-1) {
         _end_line();
         enter_col=plsql_enter_col();
         status=0;
      }
   } else {
      ignore_column1=!allow_col_1;
      _begin_select();get_line(first_line);up();
      _end_line();
      save_pos(p2);
      int orig_linenum=p_line;
      int orig_col=p_col;
      // Check if we are pasting into the middle of an SQL or start task statement
      int begin_col=plsql_begin_stat_col(false /* No RestorePos */,
                                 false /* Don't skip first begin statement marker */,
                                 false /* Don't return first non-blank */,
                                 true  /* Return 0 if no code before cursor. */,
                                 false,
                                 true
                                 );
      int sql_col=0;
      if (begin_col) {
         _str word2=lowcase(cur_word(junk));
         if (word2!='if' && word2!='while' && word2!='for') {
            int statdelim_linenum=p_line;
            sql_col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,syntax_indent,
                                       orig_linenum,orig_col);
            // Don't try to past in the middle of a sequal statement.
            if (sql_col) {
               return(0);
            }
         }
      }

      restore_pos(p2);
      enter_col=plsql_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && ignore_column1) || enter_col=='' ||
      (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static _str plsql_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      plsql_enter_col2(enter_col) ) {
      return('');
   }
   return(enter_col);
}


static boolean plsql_enter_col2(int &enter_col)
{
   enter_col=plsql_indent_col(0);
   return(0);
}

//Returns 0 if the letter wasn't upcased, otherwise 1
_command void plsql_maybe_case_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_word(LanguageSettings.getAutoCaseKeywords(PLSQL_LANGUAGE_ID),gWord,gWordEndOffset);
}

_command void plsql_maybe_case_backspace() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _maybe_case_backspace(LanguageSettings.getAutoCaseKeywords(PLSQL_LANGUAGE_ID),gWord,gWordEndOffset);
}

/* Desc: Find the matching begin/end.

   Supported combinations:
      begin -- end XXXX
      loop -- end XXXX
      package -- end XXXX

   Example:
      procedure calc1 is
      begin                 <-------+
         for month in 1..12         |
         loop             <-------+ |
            calc2(month);         | |
            calc2(month);         | |
         end loop;        <-------+ |
      end;                  <-------+


      while inrange(currentrow) loop  <--------+
         begin                      <------+   |
            asdfasdkflka;                  |   |
         exception                         |   |
            when nodatafound then          |   |
               withinthreshold := 1;       |   |
         end;                       <------+   |
      end loop;                       <--------+
*/
int _plsql_find_matching_word(boolean quiet)
{
   //say("_plsql_find_matching_word");
   typeless ori_position;
   save_pos(ori_position);

   // Get current word at cursor:
   _str word;
   //word = getCurrentWord();
   int sc;
   word = cur_word(sc);
   if (word == "") {
      restore_pos(ori_position);
      if (!quiet) {
         message(nls('Not on begin/end or word pair'));
      }
      return(1);
   }
   word = lowcase(word);

   // Only some words have matching words. Find the actual word
   // to match and the expected word to match.
   /* Ex:
         begin
            helloThere;
         end calc2;
             ^^^^^

         In this example, the caret is over "calc2". The actual
         word to match is "end" and the expected word to match
         is "begin".
   */
   int status;
   _str matchingWord;
   _str direction;
   status = correspondingMatchingWord(word, matchingWord, direction);
   if (status) {
      restore_pos(ori_position);
      if (!quiet) {
         message(nls('Not on begin/end or word pair'));
      }
      return(1);
   }

   // Find the matching word:
   status = matchWord(word);
   if (!status) {
      restore_pos(ori_position);
      if (!quiet) {
         message(nls('Matching word not found'));
      }
      return(1);
   }
   return(0);
}

// Desc: Return the expected matching word for specified word.
// Retn: 0 has expected matching, 1 no expected matching word
static int correspondingMatchingWord(_str & word, _str & matchingWord
                                     ,_str & direction)
{
   if (word == "begin") {
      matchingWord = "end";
      direction = "";
   } else if (word == "end") {
      /*
      // Ignore special "end" that does not map to a block.
      //    "end if"
      _str nextWord;
      nextWord = getNextWord();
      nextWord = lowcase(nextWord);
      if (nextWord == "if") {
         return(1);
      }
      */
      matchingWord = "begin|loop|package|if|case";
      direction = "-";
   } else if (word == "loop") {
      // Look at the previous word to determine if this is the
      // start or the end of a loop block.
      _str prevWord;
      if (matchPreviousWord("end",1)) {  // ending of loop
         word = "end";
         matchingWord = "begin|loop";
         direction = "-";
      } else {                           // starting of loop
         matchingWord = "end";
         direction = "";
      }
   } else if (word == "package") {
      matchingWord = "end";
      direction = "";
   } else if (word == "if") {
      if (matchPreviousWord("end",1)) {  // part of "end if"
         word = "end";
         matchingWord = "if";
         direction = "-";
      } else {
         matchingWord = "end";
         direction = "";
      }
   } else if (word == "case") {
      if (matchPreviousWord("end",1)) {  // part of "end case"
         word = "end";
         matchingWord = "case";
         direction = "-";
      } else {
         matchingWord = "end";
         direction = "";
      }
   } else {
      // Look at the previous word to determine if this is the
      // start or the end of a loop block.
      /* Ex:
            begin
               open site;
               fetch site into siteinfo;
               close site;
            end proc1;
                ^^^^^
      */
      _str prevWord;
      if (matchPreviousWord("end",1)) {
         /*
         // Ignore special "end" that does not map to a block.
         //    "end if"
         _str nextWord;
         nextWord = getNextWord();
         nextWord = lowcase(nextWord);
         if (nextWord == "if") {
            return(1);
         }
         */
         word = "end";
         matchingWord = "begin|loop|package|if|case";
         direction = "-";
      } else {
         return(1);
      }
   }
   return(0);
}

// Desc: Match the word
// Retn: 1 for word matched, 0 not
static int matchWord(_str word)
{
   // Match word forward:
   _str current="";
   int level;
   level = 0;
   int status;
   word_chars := _clex_identifier_chars();
   if (word == "begin" || word == "loop" || word == "package" || word == "if" || word == "case") {
      // Special case for "package":
      // If "package" is immediately followed by "body", there can be
      // a "body" for the package. If we see this "body", we need to skip
      // over it.
      int mayhavebegin;
      mayhavebegin = 0;
      if (word == "package") {
         _str nextword;
         nextword = lowcase(getNextWord());
         if (nextword == "body") {
            mayhavebegin = 1;
         }
      }

      while (1) {
         // Skip over the current word:
         status = search(" |[~"word_chars"]|$", "rh@XCS");
         if (status) {
            return(0);
         }

         // Search for next block key word:
         //messageNwait("h1");
         status = search("begin|loop|end|package|if|function|procedure|case", "rhw@iCK");
         //messageNwait("h2");
         if (status) {
            return(0);
         }

         // For proc headers (function and procedure), skip over proto.
         // If not proto, find the matching "begin" and skip to the matching
         // "end".
         _str ch;
         ch = lowcase(get_text(8));
         if (ch == "function" || ch == "procedur") {
            if (isProcFuncProto()) continue;
            if (skipOverProcFunc()) {
               return(0);
            }
            continue;
         }

         // Check new block keyword. If keyword indicates a new
         // block, increase the nesting level. Otherwise, decrease
         // the nesting level. If current nesting level is 0, we've
         // found the matching word.
         //current = getCurrentWord();
         int sc;
         current = cur_word(sc);
         current = lowcase(current);
         if (current == "begin") {
            if (mayhavebegin && !level) {
               // Do nothing...
               mayhavebegin = 0;
            } else  {
               level++;
            }
         } else if (current == "loop") {
            // Look at the previous word to determine if this is the
            // start or the end of a loop block.
            if (!matchPreviousWord("end",0)) {
               // Found start of new loop block.
               level++;
            }
         } else if (current == "package") {
            level++;
         } else if (current == "if") {
            if (matchPreviousWord("end",0)) {
               continue;
            }
            level++;
         } else if (current == "case") {
            if (matchPreviousWord("end",0)) {
               continue;
            }
            level++;
         } else { // "end" case
            /*
            // Ignore special "end" that does not map to a block.
            //    "end if"
            _str nextWord;
            nextWord = getNextWord();
            nextWord = lowcase(nextWord);
            if (nextWord == "if") {
               continue;
            }
            */
            if (!level) {
               return(1);
            }
            level--;
         }
      }
   }

   // Match word backward:
   while (1) {
      // Skip backward over the current word:
      status = search(" |[~"word_chars"]|$", "-rh@XCS");
      if (status) {
         //messageNwait("exit h1");
         return(0);
      }

      // Search for next block key word:
      status = search("begin|loop|end|package|if|case", "-rhw@iXCS");
      if (status) {
         //messageNwait("exit h2");
         return(0);
      }
      //messageNwait("h1 level="level);

      // Check new block keyword. If keyword indicates a new
      // block, increase the nesting level. Otherwise, decrease
      // the nesting level. If current nesting level is 0, we've
      // found the matching word.
      //current = getCurrentWord();
      int sc;
      current = cur_word(sc);
      current = lowcase(current);
      if (current == "begin" || current == "package") {
         if (!level) {
            return(1);
         }
         level--;
      } else if (current == "if") {
         // Ignore special "if" that is part of "end if".
         if (matchPreviousWord("end",1)) {
            level++;
         } else {
            if (!level) {
               return(1);
            }
            level--;
         }
      } else if (current == "case") {
         if (matchPreviousWord("end",1)) {
            level++;
         } else {
            if (!level) {
               return(1);
            }
            level--;
         }
      } else if (current == "loop") {
         // Look at the previous word to determine if this is the
         // start or the end of a loop block.
         if (matchPreviousWord("end",1)) {
            // Found end of new loop block.
            level++;
         } else {
            // Found start of loop block.
            if (!level) {
               return(1);
            }
            level--;
         }
      } else { // "end" case
         /*
         // Ignore special "end" that does not map to a block.
         //    "end if"
         _str nextWord;
         nextWord = getNextWord();
         nextWord = lowcase(nextWord);
         if (nextWord == "if") {
            continue;
         }
         */
         level++;
      }
   }
   return(0);
}

// Desc: Get the current word at the cursor.
// Retn: word or ""
/*static _str getCurrentWord()
{
   // Get current word at cursor:
   int startCol;
   word_chars := _clex_identifier_chars();
   int status = search(" |[~"word_chars"]|$", "rh@XCS");
   if (status) {
      return("");
   }
   //say("p_line="p_line" p_col="p_col);
   int endSeek;
   endSeek = _nrseek();
   _nrseek(endSeek - 1);
   status = search(" |[~"word_chars"]|^", "-rh@XCS");
   if (status) {
      return("");
   }
   _str ch = get_text();
   if (!isalnum(ch) && ch != "_") {
      _nrseek(_nrseek() + 1);
   }
   int startSeek;
   startSeek = _nrseek();
   _str word;
   word = get_text(endSeek - startSeek);
   return(word);
}*/

// Desc: Get the next word. The caret is not moved.
// Retn: next word, "" for none.
static _str getNextWord()
{
   int oldseekpos;
   oldseekpos = _nrseek();
   word_chars := _clex_identifier_chars();

   int status = search(" |[~"word_chars"]", "rh@XCS");
   if (status) {
      _nrseek(oldseekpos);
      return("");
   }
   _str ch = get_text();
   if (ch != " " && !isalnum(ch)) {
      _nrseek(oldseekpos);
      return(ch);
   }
   status = search(":a", "rh@XCS");
   if (status) {
      _nrseek(oldseekpos);
      return("");
   }
   _str current;
   //current = getCurrentWord();
   int sc;
   current = cur_word(sc);
   _nrseek(oldseekpos);
   return(current);
}

// Desc: Match the previous word with the specified key.
// Ex:
//    end if;               ==> previous word is "end"
//    end loop;             ==> previous word is "end"
//    end someLabelHere;    ==> previous word is "end"
//
//    end; if               ==> previous word is ";"
//
// Retn: 1 for previous word matched, 0 not
static int matchPreviousWord(_str key, int moveCaret)
{
   int oldseekpos;
   oldseekpos = _nrseek();

   // Make sure caret is over a word:
   _str ch;
   ch = get_text();
   if (!isalnum(ch) && ch != "_") {
      _nrseek(oldseekpos);
      return(0);
   }

   // Locate the white space preceeding this word:
   word_chars := _clex_identifier_chars();
   status := search("[~"word_chars"]","-rh@iXCS");
   if (status) {
      _nrseek(oldseekpos);
      return(0);
   }
   // Skip over the white spaces preceeding this word:
   status = search("[~ \t]","-rh@iXCS");
   if (status) {
      _nrseek(oldseekpos);
      return(0);
   }

   // Make sure that we are at the end of a word:
   ch = get_text();
   if (!isalnum(ch) && ch != "_") {
      _nrseek(oldseekpos);
      return(0);
   }

   // Get the word for the comparison:
   _str word;
   //word = getCurrentWord();
   int sc;
   word = cur_word(sc);
   word = lowcase(word);
   //say("matchPreviousWord word="word);
   if (word == key) {
      if (!moveCaret) _nrseek(oldseekpos);
      return(1);
   }

   _nrseek(oldseekpos);
   return(0);
}

// Desc: Check to see if the procedure/function statement is a prototype.
// Retn: 1 for proto, 0 not
static int isProcFuncProto()
{
   int oldseekpos;
   oldseekpos = _nrseek();
   while (1) {
      int status;
      status = search("as|is|begin|end|;","rh@iXCS");  // can't use 'w' in RE because ';'
      if (status) {
         _nrseek(oldseekpos);
         return(0);
      }
      if (get_text() == ";") {
         // Found ';' before any of the block start keywords.
         return(1);
      }
      status = _clex_find(KEYWORD_CLEXFLAG, "G");
      if (status != CFG_KEYWORD) {
         _nrseek(_nrseek() + 1);
         continue;
      }

      // Not a proto... Restore original position.
      _nrseek(oldseekpos);
      return(0);
   }
   _nrseek(oldseekpos);
   return(0);
}

// Desc: Skip over function.
// Retn:  0 for OK, 1 for error.
static int skipOverProcFunc()
{
   int oldseekpos;
   oldseekpos = _nrseek();

   // Locate the "begin":
   int status;
   status = search("begin","rhw@iCK");
   if (status) {
      _nrseek(oldseekpos);
      return 1;
   }

   // Recurse back to matchWord() to skip over begin/end pair:
   status = matchWord("begin");
   if (!status) {
      _nrseek(oldseekpos);
      return 1;
   }

   // Skip over the optional "end" label:
   skipToSemicolon();
   return 0;
}


// Desc:  Go to next semicolon.
// Retn:  0 for OK, 1 for error.
static int skipToSemicolon()
{
   int oldseekpos;
   oldseekpos = _nrseek();

   while (1) {
      int status;
      status = search("[(;]","rh@iXCS");
      if (status) {
         _nrseek(oldseekpos);
         return(1);
      }
      _str ch;
      ch = get_text();
      if (ch == "(") {
         _find_matching_paren(def_pmatch_max_diff);
         continue;
      }

      // Found ';'...
      return(0);
   }
   return(0);
}
