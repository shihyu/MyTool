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
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "notifications.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   Built-in syntax expansion
   BEGIN
   END
   FIND
   END FIND
   FOR
   END FOR
   IF
   END IF

   ELSE

   ELSEIF  THEN

   REPEAT
   END REPEAT
   UPDATE
   END UPDATE
   STORE
   END STORE
   CREATE
   END

   ON
   END ON
   MENU
   END MENU
   SCREEN
   END SCREEN
   IMAGE
   END IMAGE

   ARRAY
   END ARRAY

   PROCEDURE
   END PROCEDURE
   subroutine.name: SUBROUTINE
   END SUBROUTINE  subroutine.name
   INCLUDE

   Features implemented
       * Color coding
       * Syntax expansion
       * Syntax indenting
       * SmartPaste(R).  When lines of text are pasted into a source file, the
         added lines are reindented according to the surrounding code.
       * Tagging for subroutines, procedures, labels, Screens, images, and menus.  You
         can go to the definition of one of these tags (Ctrl+Dot by default). The
         Procs Tab list these symbols for the current buffer.  The symbol window
         will show the source or list symbols when the cursor is over a tag.  You
         can use Alt+Dot to list/retrieve tag symbols in the current file.
       * Auto function help for built-in $functions.  Includes documentations in the form
         of HTML comments.

   Limitations
       *  Color coding may indicate a word is a keyword when it is actually not.  This is due
          to the fact that Model 204 (like other SQL languages we support) has almost no
          reserved words.
       *  SmartPaste(R) relies on statement continuation characters being present.  The
          Model 204 language docs indicated that "AND -"  is assumed when not present.
       *  Tagging currently only picks up subroutines, procedures, and labels definitions. %variables,
          subroutine arguments, prototypes, and image content data is not picked up.  There is
          Auto function help for built-in $functions.
       *  Tagging does not understand scope.  This is because Context Tagging&reg;
          (very smart tagging) has not been implemented.  All tags act like they are
          global scope.
       *  When matching blocks such as "if" and "end if", the end block type must be fully specified.
          That is, "end" won't work but "end if" will.
       *  We have added some very special case code for handling the IN clause to allow the FOR
          or FIND keyword NOT to be indented when there is a statement continuation.

          This allows for the following:
              IN ?&FIMETA -
              FDWOL MEMBER.TYPE          = %VAL.M204PROCEDURE
              END FIND

          Instead of

              IN ?&FIMETA -
                 FDWOL MEMBER.TYPE          = %VAL.M204PROCEDURE
              END FIND

          which would happen without the special case code.  We think this special case code will
          do what users really.  However, we are not sure if there are any significant scenerios
          not handled by this code.

       *  Line comments that are not indented are not treated specially by syntax indenting. Pressing
          ENTER place cursor in code column.  If the user uses multi-line comments, there is
          no problem here.  We could treat line comments that start in column 1 like multi-line
          comments.




*/
/*
    Some sample constructs

    BEGIN  <-- begin can be abbreviated as B
    END


    FIND ALL
    END FIND

    REPEAT WHILE  expr
    END REPEAT

    IF expr THEN
    ELSEIF expre
    END IF


   FD                               FIND ALL RECORDS
   FD                               FIND ALL RECORDS FOR WHICH
   FD IN label                      FIND ALL RECORDS IN label FOR WHICH
   FD ON listname                   FIND ALL RECORDS ON LIST listname FOR WHICH
   FDR                              FIND AND RESERVE ALL RECORDS
   FDR                              FIND AND RESERVE ALL RECORDS FOR WHICH
   FDR IN label                     FIND AND RESERVE ALL RECORDS IN label FOR WHICH
   FDR ON listname                  FIND AND RESERVE ALL RECORDS ON LIST listname FOR WHICH
   FDV fieldname                    FIND ALL VALUES OF fieldname
   FDWOL RECORDS                    FIND WITHOUT LOCKS RECORDS
   FPC                              FIND AND PRINT COUNT
   END FIND

   FEO fieldname                    FOR EACH OCCURRENCE OF fieldname
   FR                               FOR EACH RECORD
   FR label                         FOR EACH RECORD IN label
   FR IN label                      FOR EACH RECORD IN label
   FR ON listname                   FOR EACH RECORD ON LIST listname
   FRN                              FOR RECORD NUMBER
   FRV fieldname                    FOR EACH VALUE OF fieldname
   FRV IN label                     FOR EACH VALUE IN label
   END FOR

    ON ERROR
    ON {FIELD CONSTRAINT CONFLICT |FCC}
    ON FIND CONFLICT
    ON RECORD
    ON MISSING FILE
    ON MISSING MEMBER
    ON RECORD LOCKING CONFLICT

    END ON [ label]

    UPDATE RECORD
            update-statement-1
            update-statement-2
            .
            .
            .
            update-statement-N
    END UPDATE
    STORE RECORD
            fieldname = value
            .
            .
            .
    END STORE [ label]

    FOR %i FROM 1 TO 147
       PRINT %x
       %x = %x*10
    END FOR
    CREATE [TEMP] GROUP groupname FROM filename [, filename ...]
       [PARAMETER parameter list]
       ...
    END
    [DECLARE] SCREEN screenname [GLOBAL [PERMANENT | TEMPORARY] | [PERMANENT | TEMPORARY] GLOBAL | COMMON]
            screenline
            .
            .
            .
    END SCREEN
    MENU menuname [GLOBAL [PERMANENT | TEMPORARY]
        | [PERMANENT | TEMPORARY] GLOBAL
        | COMMON]
    END MENU

    IMAGE imagename [AT { itemname | imagname1 | arrayname}
            | GLOBAL [PERMANENT | TEMPORARY]
            | [PERMANENT | TEMPORARY] GLOBAL
            | COMMON]
         itemname [IS [TYPE] type description]
         itemname [IS [TYPE] type description]
         ...
    END IMAGE
    IMAGE GENERAL.LEDGER.RECORD
            GL.RECORD.TYPE IS STRING LEN 1
            GL.NUMBER IS STRING LEN 10 DP 3
            GL.INV.TYPE IS STRING LEN 2
    IMAGE ACCOUNTS.REC.RECORD
            AR.RECORD.TYPE IS STRING LEN 1
            AR.ACCT.NO IS STRING LEN 6
            AR.BALANCE IS PACKED DIGITS 9 DP 2
    END IMAGE
    ARRAY [ arrayname] OCCURS n DEPENDING ON { itemname | %variable}
    END ARRAY
    ARRAY [ arrayname] OCCURS n
        [AFTER { itemname | arrayname}
        | AT { position | itemname | imagname1 | arrayname}
    END ARRAY

   {PROCEDURE|PROC} procname
   END {PROCEDURE|PROC} [procname]
   subroutine.name: SUBROUTINE [(paramdecl [INPUT|OUTPUT|INPUT OUTPUT|INOUT],  paramdecl [INPUT|OUTPUT|INPUT OUTPUT|INOUT], ...)]
   END SUBROUTINE

   When matching begin/ends, watch out for the LOOP END statement which breaks a loop. For
   now ignore skip "END MORE" and "END NORUN" statements as well.

*/

static const MODEL204_LANGUAGE_ID=  'model204';
// The characters {}[]\  and | may be valid.
static const MODEL204_LABEL_WORD_CHARS= '0-9A-Z._:';

defeventtab model204_keys;
def  ' '= model204_space;
def  '('= auto_functionhelp_key;
def  'ENTER'= model204_enter;

_command model204_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(MODEL204_LANGUAGE_ID);
}
_command void model204_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_model204_expand_enter);
}
bool _model204_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
_command model204_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      model204_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=="") {
      _undo('S');
   }
}

static SYNTAX_EXPANSION_INFO model204_space_words:[] = {
   'array'                        => { "ARRAY ... END ARRAY" },
   'begin'                        => { "BEGIN ... END" },
   'else'                         => { "ELSE" },
   'elseif'                       => { "ELSEIF" },
   // abbreviated find statements 
   'fd'                           => { "FD ... END FIND" },
   'fdr'                          => { "FDR ... END FIND" },
   'fdv'                          => { "FDV ... END FIND" },
   'fdwol'                        => { "FDWOL ... END FIND" },
   'feo'                          => { "FEO ... END FIND" },
   'fpc'                          => { "FPC ... END FIND" },
   // find statements             
   'find all records'             => { "FIND ALL RECORDS ... END FIND" },
   'find and reserve'             => { "FIND AND RESERVE ... END FIND" },
   'find all values'              => { "FIND ALL VALUES ... END FIND" },
   'find without locks'           => { "FIND WITHOUT LOCKS ... END FIND" },
   'find and print count'         => { "FIND AND PRINT COUNT ... END FIND" },
   // other statements
   'for'                          => { "FOR ... END FOR" },
   'fr'                           => { "FR ... END FOR" },
   'frn'                          => { "FRN ... END FOR" },
   'frv'                          => { "FRV ... END FOR" },
   'for each occurrence of'       => { "FOR EACH OCCURRENCE OF ... END FOR" },
   'for each record'              => { "FOR EACH RECORD .. END FOR" },
   'for record number'            => { "FOR RECORD NUMBER ... END FOR" },
   'for each value'               => { "FOR EACH VALUE ... END FOR" },
   'if'                           => { "IF ... END IF" },
   'image'                        => { "IMAGE ... END IMAGE" },
   'menu'                         => { "MENU ... END MENU" },
   'on'                           => { "ON ... END ON" },
   'procedure'                    => { "PROCEDURE ... END PROCEDURE" },
   'repeat'                       => { "REPEAT ... END REPEAT" },
   'screen'                       => { "SCREEN ... END SCREEN" },
   'store'                        => { "STORE ... END STORE" },
   'subroutine'                   => { "SUBROUTINE ... END SUBROUTINE " },
   'update'                       => { "UPDATE ... END UPDATE" },
   'include'                      => { "INCLUDE" },
};

static const FOR_STATEMENT_WORDS= 'FEO FOR FR FRN FRV';
static const FIND_STATEMENT_WORDS= 'FIND FD FDR FDV FDWOL FEO FPC';
static const IN_STATEMENT_SPECIAL_WORDS= FOR_STATEMENT_WORDS' 'FIND_STATEMENT_WORDS;
static const SUPPORTED_END_WORDS= 'IF REPEAT 'FOR_STATEMENT_WORDS' 'FIND_STATEMENT_WORDS' SCREEN IMAGE MENU ON ARRAY';

/*
    Returns true if nothing is done
*/
bool _model204_expand_enter()
{
   col := 0;
   typeless p=0;
   if (!_is_line_continuation()) {
      save_pos(p);
      orig_linenum := p_line;
      orig_col := p_col;
      _str enter_cmd=name_on_key(ENTER);
      if (enter_cmd=='nosplit-insert-line') {
         _end_line();
      }
      line := "";
      get_line(line);
      lline := lowcase(line);
      if (p_col==_text_colc()+1) {
         if (lline=='else' || lline=='elseif') {
            col=_model204_find_block_col();
            if (col) {
               replace_line(indent_string(col-1)strip(line));_end_line();
               save_pos(p);
            }
         }
      }
      restore_pos(p);
   }
#if 0
   begin_col=model204_begin_stat_col(false /* No RestorePos */,
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
#endif
   col=model204_indent_col(0);
   indent_on_enter(0,col);
   return(false);
}
static bool _is_IN_statement_special_case()
{
   typeless junk;
   model204_code_indent();
   if (lowcase(cur_word(junk))!='in') {
      return(false);
   }
   line := "";
   get_line(line);
   begin_line();
   orig_line := p_line;
   int status=search(translate(IN_STATEMENT_SPECIAL_WORDS,'|',' ')"|$",'@rih');
   for (;;) {
      if (status || !match_length() || p_line!=orig_line) {
         //_message_box('special case');
         return(true);
      }
      if (_clex_find(0,'g')!=CFG_KEYWORD) {
         status=repeat_search();
         continue;
      }
      if(pos(' 'cur_word(junk)' ',' 'IN_STATEMENT_SPECIAL_WORDS' ',1,'i')) {
         return(false);
      }
      status=repeat_search();
   }
}
static bool _is_line_continuation(bool SpecialCaseInClause=true)
{
   save_pos(auto p);
   up();
   tline := "";
   get_line(tline);
   _TruncEndLine();left();
   if (get_text()=='-' && _clex_find(0,'G')==CFG_WINDOW_TEXT) {
      if (SpecialCaseInClause && !_is_IN_statement_special_case()) {
         restore_pos(p);
         return(true);
      }
   }
   restore_pos(p);
   return(false);
}
static bool _is_line_continuation_to_next()
{
   save_pos(auto p);
   _TruncEndLine();left();
   if (get_text()=='-' && _clex_find(0,'G')==CFG_WINDOW_TEXT) {
      if (!_is_IN_statement_special_case()) {
         restore_pos(p);
         return(true);
      }
   }
   restore_pos(p);
   return(false);
}
/*
    Returns true if nothing is done.
*/
static bool model204_expand_space()
{
   status := false;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(true);
   }
   if (_is_line_continuation()) {
      return(true);
   }
   orig_word := "";
   labelcol := 0;
   typeless p=0;
   labelname := rest := "";
   parse line with labelname rest;
   if (isalpha(substr(labelname,1,1)) && _last_char(labelname)==':' &&
       !pos('[~'MODEL204_LABEL_WORD_CHARS']',labelname,1,'RI')) {
      labelname=substr(labelname,1,length(labelname)-1);
      save_pos(p);
      _first_non_blank();
      labelcol=p_col;
      restore_pos(p);
      orig_word=strip(rest);
   } else {
      orig_word=strip(line);
      labelname="";
   }
   col := 0;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,model204_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=="") return(true);

   sample:=orig_word;
   line=substr(line,1,length(line)-length(orig_word)):+_word_case(word,false,sample);
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);
   set_surround_mode_start_line();
   //'FD','FDR','FDV','FEO','FIND','FPC'
   if (pos(' 'word' ',' 'FIND_STATEMENT_WORDS' ',1,'I') ||
       word=='find all records' || word=='find and reserve' || word=='find all values' || word=='find without locks' || word=='find and print count'
       ) {
      replace_line(line);
      insert_line(indent_string(width)_word_case('end find',false,sample));
      up();_end_line();++p_col;

      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      return(false);
   } else if (pos(' 'word' ',' 'FOR_STATEMENT_WORDS' ',1,'I') ||
              word=='for each occurrence of' || word=='for each record' || word=='for record number' || word=='for each value'
              ) {
      replace_line(line);
      insert_line(indent_string(width)_word_case('end for',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;

      // maybe do dynamic surround
      if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION)){
         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
      return(false);
   } else if (word=='subroutine') {
      replace_line(line);
      _first_non_blank();
      col=p_col;
      insert_line(indent_string(col-1)_word_case('end subroutine',false,sample)' 'labelname);
      up();_end_line();++p_col;

      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      return(false);
   }
   if (labelname!="") {
      return(true);
   }

   doNag := true;
   if ( word=='begin' || word=='B') {
      replace_line(line);
      insert_line(indent_string(width)_word_case('end',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='if') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end if',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='repeat') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end repeat',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='update') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end update',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='store') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end store',false,sample));
      up();_end_line();++p_col;
   } else if (word=='create') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end',false,sample));
      up();_end_line();++p_col;
   } else if (word=='on') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end on',false,sample));
      set_surround_mode_end_line();
      up();_end_line();++p_col;
   } else if (word=='menu') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end menu',false,sample));
      up();_end_line();++p_col;
   } else if (word=='screen') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end screen',false,sample));
      up();_end_line();++p_col;
   } else if (word=='image') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end image',false,sample));
      up();_end_line();++p_col;
   } else if (word=='array') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end array',false,sample));
      up();_end_line();++p_col;
   } else if (word=='procedure') {
      replace_line(_word_case(line,false,sample));
      insert_line(indent_string(width)_word_case('end procedure',false,sample));
      up();_end_line();++p_col;
   } else if (word=='elseif') {
      col=_model204_find_block_col();
      if (col) {
         replace_line(indent_string(col-1)_word_case(orig_word'  then',false,sample));
         _end_line();p_col-=5;
      } else {
         replace_line(_word_case(line,false,sample));
         _end_line();++p_col;
      }
   } else if (word=='else') {
      col=_model204_find_block_col();
      newLine := "";
      if (col) {
         newLine = indent_string(col-1):+_word_case(orig_word,false,sample);
      } else {
         newLine = _word_case(line,false,sample);
      }
      replace_line(newLine);
      _end_line();++p_col;
      doNag = (newLine != line);
   } else {
      newLine := _word_case(line,false,sample);
      replace_line(newLine);
      _end_line();++p_col;
      doNag = (newLine != line);
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNag) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

_str _model204_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}
int _model204_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, model204_space_words, prefix, min_abbrev);
}

void model204_skip_label()
{
   line := "";
   _first_non_blank();
   get_line(line);
   labelname := rest := "";
   parse line with labelname rest;
   if (isalpha(substr(labelname,1,1)) && _last_char(labelname)==':' &&
       !pos('[~'MODEL204_LABEL_WORD_CHARS']',labelname,1,'RI')) {
      found_label := true;
      p_col+=length(labelname);
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      search('[~ \t]|$','@rh');
      restore_search(p1,p2,p3,p4);
   }
}
void model204_code_indent(bool &skipped_label=false,bool &code_follows_label=false)
{
   line := "";
   _first_non_blank();
   get_line(line);
   labelname := rest := "";
   parse line with labelname rest;
   skipped_label=false;
   if (p_col==1 && isalpha(substr(labelname,1,1)) && _last_char(labelname)==':' &&
       !pos('[~'MODEL204_LABEL_WORD_CHARS']',labelname,1,'RI')) {
      skipped_label=true;
      p_col+=length(labelname);
      search('[~ \t]|$','@rh');
      code_follows_label=(rest!="" && rest!='-');
   }
}
/*
    Handles
      if/end if
      repeat/end repeat
      for/end for
      find/end find
      for/end for
      screen/end screen
      image/end image
      menu/end menu
      array/end array
      on/end array

*/
int _model204_find_block_col(_str start_word='if')
{
   _str start_word_list=start_word;
   if (start_word=='find') {
      start_word_list=translate(FIND_STATEMENT_WORDS,'|',' ');
   } else if (start_word=='for') {
      start_word_list=translate(FOR_STATEMENT_WORDS,'|',' ');
   }
   word := "";
   typeless orig_p2=0;
   typeless orig_pos;
   save_pos(orig_pos);
   nesting := 1;
   typeless status=search(start_word_list'|end','@-wirhxcs');
   //status=search('xxx','@-wirxcs');
   for (;;) {
      if (status) {
         restore_pos(orig_pos);
         return(0);
      }
      if (start_word!='find' && start_word!='for') {
         if (_is_line_continuation()) {
            status=repeat_search();
            continue;
         }
         orig_col := p_col;
         save_pos(orig_p2);
         model204_skip_label();
         if (orig_col!=p_col) {
            restore_pos(orig_p2);
            status=repeat_search();
            continue;
         }
         restore_pos(orig_p2);
      }
      word=lowcase(get_match_text());
      if (word=='end') {
         save_pos(orig_p2);
         p_col+=3;
         typeless p1,p2,p3,p4;
         save_search(p1,p2,p3,p4);
         search('[~ \t]|$','@rh');
         restore_search(p1,p2,p3,p4);
         typeless junk=0;
         if (lowcase(cur_word(junk))==start_word) {   // Found "end if"
            ++nesting;
         }
         restore_pos(orig_p2);
      } else {
         --nesting;
      }
      //messageNwait('word='word' nesting='nesting);
      if (nesting<=0) {
         model204_code_indent();
         col := p_col;
         restore_pos(orig_pos);
         return(col);
      }
      status=repeat_search();
   }
}

   // IF we get fancy, we will want to pull some code from below.
/*


  DON't indent on BEGIN CLASS


  Block constructs
    [label:]EVENT LOOP [is]  page 98.
      PREREGISTER
         [statement_list]
      POSTREGISTER
         [statement_list]
      WHEN expression DO
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END EVENT;

    EVENT CASE [IS]
      PREREGISTER
         [statement_list]
      POSTREGISTER
         [statement_list]
      WHEN expression DO
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE
         [statement_list]
    END EVENT;

    WHEN expression DO

    ELSE  -- part of exception or if statement

    IF expression THEN
    ELSEIF expression THEN
         [statement_list]
    ELSE
         [statement_list]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END IF;


    [label:]CASE expression IS
       WHEN expression DO
       ELSE [DO]


    [label:]WHILE expression DO
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END WHILE;

    [label:]FOR expression IN expression [TO expression|CURSOR ...] DO
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [DO]
         [statement_list]
    END FOR
    START TASK [object_reference.]method[(parameter_list)]
      [WHERE setting,setting,...]

    CLASS name [IS MAPPED] INHERITS [FROM] object_reference.]method
    HAS FILE filename;
    HAS PRIVATE
    HAS PUBLIC
      stuff
    HAS PROPERTY
    END CLASS

    INTERFACE name INHERITS [FROM] object_reference.]method
    HAS PUBLIC
      stuff
    HAS PROPERTY
    END INTERFACE;

    CURSOR name [(parameter_list)]
    BEGIN
       select_statement;
    END;

    BEGIN CLASS;
    END CLASS

    BEGIN [TOOL|C|DCE|OBB] project_name;
     [INCLUDES project_name;]
     [HAS PROPERTY {property;}
    END project_name;

    [label:] BEGIN [DEPENDENT|NESTED|INDEPENDENT] TRANSACTION]
    [EXCEPTION]
      WHEN expression DO
         [statement_list]
      ELSE [do]
         [statement_list]
    END TRANSACTION;


*/
static int model204_clex_skip_blanks()
{
   for (;;) {
      int status=_clex_skip_blanks();
      if (status) {
         return(status);
      }
      if (get_text()=='-' && _clex_find(0,'G')==CFG_WINDOW_TEXT && _text_colc(0,'E')==p_col) {
         right();
      } else {
         return(0);
      }
   }
}
/*
   This code is just here incase we get fancy
*/
int model204_indent_col(int non_blank_col, bool pasting_open_block = false)
{
   orig_col := p_col;
   orig_linenum := p_line;
   save_pos(auto p);
   //start_offset=_nrseek();
   typeless expand;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   // IF user does not want syntax indenting
   if ( syntax_indent<=0) {
      if (non_blank_col) {
         return(non_blank_col);
      }
      return(orig_col);
   }
   typeless markid=_alloc_selection();
   _select_char(markid);
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }

   nesting := 0;
   OpenParenCol := 0;

   // This might be slow.  May need to break this up into two loops.
   //status=search('[~ \t]|[(]','-RI@xcs');
   skipped_label := false;
   code_follows_label := false;
   statement_continuation := false;
   typeless status=0;
   line := "";
   get_line(line);
   replace_line(_expand_tabsc(1,p_col-1));
   line_contains_more_than_just_a_label := true;
   {
      save_pos(auto p4);
      model204_code_indent(skipped_label,code_follows_label);
      if (skipped_label) {
         if (!code_follows_label) {
            // This line contains just a label
            line_contains_more_than_just_a_label=false;
         }
      }
      restore_pos(p4);
   }
   // IF the current line continues on to the next line
   if (_is_line_continuation_to_next() && p_col>_text_colc(0,'E') && line_contains_more_than_just_a_label) {
      replace_line(line);
      statement_continuation=true;
      for (;;) {
         if (!_is_line_continuation()) {
            break;
         }
         up();
      }
   } else {
      replace_line(line);

      if (p_col==1) {
         up();_TruncEndLine();
      } else {
         left();
      }
      for (;;) {
         status=_clex_skip_blanks('-');
         if (status) {
            break;
         }
         orig_col=p_col;
         model204_code_indent(skipped_label,code_follows_label);
         if (skipped_label) {
            if (!code_follows_label) {
               // This line contains just a label
               up();_TruncEndLine();
               continue;
            }
         }
         p_col=orig_col;
         break;
      }
      //messageNwait('h1 status='status);
      if (status) {
         if (non_blank_col) {
            return(non_blank_col);
         }
         return(orig_col);
      }
      if (_is_line_continuation()) {
         for (;;) {
            up();
            if (!_is_line_continuation()) {
               break;
            }
         }
      }
   }
   typeless junk=0;
   start_stat_word := "";
   _first_non_blank();
   nonblank_col := p_col;
   model204_code_indent();
   if (!statement_continuation) {
      save_pos(auto p2);
      model204_skip_label();
      start_stat_word=lowcase(cur_word(junk));
      restore_pos(p2);
   }
   //messageNwait('h2 status='status);
   col := 0;
   _select_char(markid);
   //end_offset=_nrseek();
   begin_stat_col := p_col;
   _begin_select(markid);
   // Check if the cursor is inside parenthesis
   typeless orig_markid=_duplicate_selection("");
   _show_selection(markid);
   //messageNwait('h3');
   status=search('[()]','mrhi@xcs');
   for (;;) {
      if (status) {
         break;
      }
      if(get_text()=='(') {
         if (!nesting && !OpenParenCol) {
            save_pos(auto p3);
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            //messageNwait('a1');
            status=model204_clex_skip_blanks();
            //messageNwait('a2 status='status);


            if (!status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<orig_col)
                           )) {
               hit_special := false;
               if (p_line!=orig_linenum) {
                  save_pos(auto p4);
                  p_line=orig_linenum;
                  _first_non_blank();
                  if (!(get_text()=='-' && _clex_find(0,'G')==CFG_WINDOW_TEXT && _text_colc(0,'E')==p_col)) {
                     col=p_col-1;
                     hit_special=true;
                     //messageNwait('special');
                  } else {
                     restore_pos(p4);
                  }
               }
               if (!hit_special) {
                  col=p_col-1;
               }
               //messageNwait('got here');
            } else {
               model204_code_indent();
               col=p_col+p_SyntaxIndent-1;
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
            OpenParenCol=col;
            restore_pos(p3);
         }
         --nesting;
      } else {
         ++nesting;
      }
      status=repeat_search();
   }
   if (nesting<0) {
      _show_selection(orig_markid);
      _free_selection(markid);
      restore_pos(p);
      return(OpenParenCol+1);
   }
   if (statement_continuation) {
      _show_selection(orig_markid);
      _free_selection(markid);
      restore_pos(p);
      return(begin_stat_col+p_SyntaxIndent);
   }
   if (pos(' 'start_stat_word' ',' else elseif if repeat screen image menu on array subroutine procedure begin ',1,'i')) {
      _show_selection(orig_markid);
      _free_selection(markid);
      restore_pos(p);
      if (strieq(start_stat_word,'subroutine')) {
         return(nonblank_col+p_SyntaxIndent);
      }
      return(begin_stat_col+p_SyntaxIndent);
   }
   if (!strieq(start_stat_word,'in')) {
      _show_selection(orig_markid);
      _free_selection(markid);
      restore_pos(p);
      return(begin_stat_col);
   }
   _begin_select(markid);
   _str re=translate(IN_STATEMENT_SPECIAL_WORDS,'|',' ');
   status=search(re,'@mrhi');
   for (;;) {
      if (status) {
         break;
      }
      if (_clex_find(0,'g')!=CFG_KEYWORD) {
         status=repeat_search();
         continue;
      }
      if(pos(' 'cur_word(junk)' ',' 'IN_STATEMENT_SPECIAL_WORDS' ',1,'i')) {
         break;
      }
      status=repeat_search();
   }
   _show_selection(orig_markid);
   _free_selection(markid);
   if (status) {
      restore_pos(p);
      return(begin_stat_col);
   }
   restore_pos(p);
   return(begin_stat_col+p_SyntaxIndent);

}
static void model204_reindent_curline(int adjust_col)
{
   line := "";
   skipped_label := false;
   code_follows_label := false;
   model204_code_indent(skipped_label,code_follows_label);
   if (skipped_label) {
      if (!code_follows_label) {
         return;
      }
      get_line(line);
      labelname := rest := "";
      parse line with labelname' 'rest;

      replace_line(labelname' 'reindent_line(rest,adjust_col));
      return;
   }
   get_line(line);
   line=reindent_line(line,adjust_col);
   // IF line just constists of blanks and tab characters
   if (line=="") line="";
   replace_line(line);
}
void model204_smartpaste_reindent(int first_col,int enter_col,int Noflines,bool char_cbtype,int dest_col,typeless &savedPos2)
{
   line := "";
   skipped_label := false;
   code_follows_label := false;
   save_pos(auto p4);
   int i;
   for (i=1;i<=Noflines;++i) {
      get_line(line);
      if (line!="") {
         model204_code_indent(skipped_label,code_follows_label);
         //messageNwait('col='p_col);
         if (!code_follows_label && skipped_label) {
            down();
            continue;
         }
         break;
      }
      down();
   }
   undo_s_done:=false;
   if (i<=Noflines) {
      int adjust_col=enter_col-p_col;
      restore_pos(p4);
      if (adjust_col) {
         if (!undo_s_done) {
            save_pos(auto pus);
            _restore_pos2(savedPos2);_save_pos2(savedPos2);
            _deselect();
            undo_s_done=true;
            _undo('s');
            restore_pos(pus);
         }
         for (i=1;i<=Noflines;++i) {
            model204_reindent_curline(adjust_col);
            down();
         }
      } else {
         down(Noflines-i+1);
      }
   }
   if (char_cbtype && dest_col>1) {
      if (!undo_s_done) {
         save_pos(auto pus);
         _restore_pos2(savedPos2);_save_pos2(savedPos2);
         _deselect();
         undo_s_done=true;
         _undo('s');
         restore_pos(pus);
      }
      model204_reindent_curline(dest_col-1);
      /*first_non_blank();
      NofLeadingBlankCols=p_col+paste_col;*/
   }
}
int model204_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{

   typeless comment_col="";
   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   first_line := "";
   get_line(first_line);
   int i=verify(first_line,' '\t);
   if ( i ) p_col=text_col(first_line,i,'I');
   if ( first_line!="" && _clex_find(0,'g')==CFG_COMMENT) {
      comment_col=p_col;
   }

   comment_col=p_col;
   // Look for first piece of code not in a comment
   int status=_clex_skip_blanks('m');
   // IF (no code found AND pasting comment) OR
   //   (code found AND pasting comment AND code col different than comment indent)
   if ((status && comment_col!="") || (!status && comment_col!="" && p_col!=comment_col)) {
      return(0);
   }
   typeless junk=0;
   special_case_label_in_col1 := false;
   skipped_label := false;
   model204_code_indent(skipped_label);
   if (skipped_label) {
      special_case_label_in_col1=!strieq(cur_word(junk),'subroutine');
   }
#if 0
   for (;;) {
      model204_code_indent(skipped_label);
      if (p_col>=_text_colc(0,'E') && skipped_label) {
         if(down()) return(0);
         if (_end_select_compare()>0) {
            return(0);
         }
      }
      break;
   }
#endif
   typeless p2=0;
   typeless enter_col=0;
   typeless expand;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   word := lowcase(cur_word(junk));
   linecont := _is_line_continuation();
   if (!status && !linecont && (word=='end')) {
      //messageNwait('it was an end');
      save_pos(p2);
      p_col+=3;
      search('[~ \t]|$','@rh');
      word=lowcase(cur_word(junk));
      if (pos(' 'word' ',' 'SUPPORTED_END_WORDS' ',1,'i')) {
         restore_pos(p2);
         up();_end_line();
         enter_col=_model204_find_block_col(word);
         restore_pos(p2);
         if (!enter_col) {
            enter_col="";
         }
         _begin_select();get_line(first_line);up();
      } else {
         return(0);
      }
   } else if (!status && !linecont && (word=='else' || word=='elseif')) {
      //messageNwait('it was an else');
      save_pos(p2);
      up();_end_line();
      enter_col=_model204_find_block_col();
      restore_pos(p2);
      if (!enter_col) {
         enter_col="";
      }
      _begin_select();get_line(first_line);up();
   } else {
      _begin_select();get_line(first_line);up();
      _end_line();
      enter_col=model204_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || (enter_col==1 && 0) || enter_col=="" ||
      (substr(first_line,1,1)!="" && !special_case_label_in_col1 && (!char_cbtype ||first_col<=1))) {
      return(0);
   }
   return(enter_col);
}

static _str model204_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      model204_enter_col2(enter_col) ) {
      return("");
   }
   return(enter_col);
}


static bool model204_enter_col2(int &enter_col)
{
   enter_col=model204_indent_col(0);
   return(false);
}

#if 0
/*
    This functions make show_procs smarter by showing user
    all parameters and attributes of the function definition
    but not the code.
*/
void model204_find_lastprocparam()
{
   save_pos(p);
   startpos=_nrseek();
   status=search("begin","@whixcs");
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
int model204_proc_search(_str &proc_name,bool find_first)
{
   typeless status=0;
   search_re := '{#0[A-Z][A-Z0-9_.]@}\:{#1([ \t]|$)}|{#1proc|procedure|screen|image|menu}[ \t]#{#0[~ (\t]#}';
   search_re='^[ \t]@('search_re')';
   if (find_first) {
      status=search(search_re,'@rih');
   } else {
      status=repeat_search();
   }
   tag_name := "";
   name := "";
   type := "";
   for (;;) {
      if (status) {
         return(STRING_NOT_FOUND_RC);
      }
      name=get_match_text(0);
      type=lowcase(get_match_text(1));
      switch (type) {
      case 'procedure':
         type='proc';
         break;
      case 'image':
         type='struct';
         break;
      case 'screen':
         type='form';
         break;
      case 'proc':
      case 'menu':
         break;
      default:
         line := "";
         subkeyword := "";
         get_line(line);
         parse line with . subkeyword .;
         if (strieq(subkeyword,'subroutine')) {
            type='subproc';
         } else {
            type='label';
         }
      }
      tag_name=name'('type')';
      if (proc_name:=="") {
         proc_name=tag_name;
         return(0);
      }
      if (strieq(proc_name,tag_name)) {
         return(0);
      }
      status=repeat_search();
   }

}
int _model204_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   ext := "model204";
   return ext_MaybeBuildTagFile(tfindex,ext,ext,"Model 204 Libraries", "", false, withRefs, useThread, forceRebuild);
}
/*
   PARAMETERS
      OperatorTyped     When true, user has just typed comma or
                        open paren.

                        Example
                           myfun(<Cursor Here>
                             OR
                           myproc ,

                        This should be false if cursorInsideArgumentList
                        is true.
      cursorInsideArgumentList
                        When true, user requested function help when
                        the cursor was inside an argument list.

                        Example
                          MessageBox(...,&lt;Cursor Here&gt;...)

                        Here we give help on MessageBox
      FunctionNameOffset  OUTPUT. Offset to start of function name.

      ArgumentStartOffset OUTPUT. Offset to start of first argument

  RETURN CODES
      0    Successful
      VSCODEHELPRC_CONTEXT_NOT_VALID
      VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
      VSCODEHELPRC_NO_HELP_FOR_FUNCTION
*/
int _model204_fcthelp_get_start(_str (&errorArgs)[],
                                bool OperatorTyped,
                                bool cursorInsideArgumentList,
                                int &FunctionNameOffset,
                                int &ArgumentStartOffset,
                                int &flags,
                                int depth=0)
{
   errorArgs._makeempty();
   flags=0;
   //if (cursorInsideArgumentList || OperatorTyped)
   typeless p, junk=0;
   typeless p1,p2,p3,p4;
   typeless orig_pos;
   save_pos(orig_pos);
   orig_col := p_col;
   orig_line := p_line;
   search_string := "[()]|^";
   word := "";
   status := search(search_string,'-rh@');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset= -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) break;
      if (!match_length()) {
         if (_is_line_continuation(false)) {
            if(up()) break;
            _end_line();
            status=search(search_string,'-rh@');
            continue;
         }
         break;
      }
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      ch := get_text();
      //say("CCH="ch);
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
            /*if (pos(' 'word' ',C_NOT_FUNCTION_WORDS)) {
               if (OperatorTyped && ArgumentStartOffset== -1) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               break;
            }
            */

            ArgumentStartOffset=(int)point('s')+1;
         } else {
            /*
               OperatorTyped==true
                   Avoid giving help when have
                   myproc(....4+( <CursorHere>

            */
            if (OperatorTyped && ArgumentStartOffset== -1 ){
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
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
         /*if (pos(' 'word' ',' if while catch switch ')) {
            break;
         }
         */
         restore_pos(p);
      } else  {
         break;
      }
      status=repeat_search();
   }
   if (ArgumentStartOffset<0) {
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
   }
   goto_point(ArgumentStartOffset);

   // Cursor is after , or (
   left();  // cursor to , or (
   left();  // cursor to before , or (
   search('[~ \t]|^','-rh@');  // Search for last char of ID
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   int end_col=p_col+1;
   search('[~'word_chars']\c|^\c','-rh@');
   _str lastid=_expand_tabsc(p_col,end_col-p_col);
   FunctionNameOffset=(int)point('s');
   /*if (pos(' 'lastid' ',C_NOT_FUNCTION_WORDS)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   */
   return(0);
}
/*
   PARAMETERS
      FunctionHelp_list    (Input/Ouput)
                           Structure is initially empty.
                              FunctionHelp_list._isempty()==true
                           You may set argument lengths to 0.
                           See VSAUTOCODE_ARG_INFO structure in slick.sh.
      FunctionHelp_list_changed   (Output) Indicates whether the data in
                                  FunctionHelp_list has been changed.
                                  Also indicates whether current
                                  parameter being edited has changed.
      FunctionHelp_cursor_x  (Output) Indicates the cursor x
                             position in pixels relative to the
                             edit window where to display the
                             argument help.

      FunctionNameStartOffset,ArgumentEndOffset
                              (INPUT) The text between these two
                              end points needs to be parsed
                              to determine the new argument
                              help.
   RETURN
     Returns 0 if we want to continue with function argument
     help.  Otherwise a non-zero value is returned and a
     message is usually displayed.

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

  RETURN CODES
     1   Not a valid context
     (not implemented yet)
     10   Context expression too complex
     11   No help found for current function
     12   Unable to evaluate context expression
*/
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;
int _model204_fcthelp_get(_str (&errorArgs)[],
                          VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                          bool &FunctionHelp_list_changed,
                          int &FunctionHelp_cursor_x,
                          _str &FunctionHelp_HelpWord,
                          int FunctionNameStartOffset,
                          int flags,
                          VS_TAG_BROWSE_INFO symbol_info=null,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   errorArgs._makeempty();
   //say("_model204_fcthelp_get");
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }
   _str  cursor_offset=point('s');
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   goto_point(FunctionNameStartOffset);
   // enum, struct class
   search_string := "[,()]|$";
   status := search(search_string,'rh@');
   //found_function_pointer := false;
   int ParamNum_stack[];
   _str ParamKeyword_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   stack_top := 0;
   ParamNum_stack[stack_top]=0;
   ParamKeyword_stack[stack_top]="";
   nesting := 0;
   for (;;) {
      if (status) {
         break;
      }
      if (cursor_offset<=point('s')) {
         break;
      }
      if (!match_length()) {
         /*if (_curlinecont()) {
            if(down()) break;
            _begin_line();
            status=search(search_string,'r@');
            continue;
         }*/
         p_col=_text_colc(_line_length(true),'I')+1;
         if (cursor_offset<=point('s')) {
            break;
         }
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      _str cfg=_clex_find(0,'g');
      if (cfg==CFG_STRING || cfg==CFG_COMMENT) {
         status=repeat_search();
         continue;
      }
      ch := get_text();
      if (ch==',') {
         ++ParamNum_stack[stack_top];
         ParamKeyword_stack[stack_top]="";
         status=repeat_search();
         continue;
      }
      if (ch==')') {
         --stack_top;
         if (stack_top<=0 /*&& (!found_function_pointer && stack_top<0)*/) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         //found_function_pointer = false;
         status=repeat_search();
         continue;
      }
      if (ch=='(') {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         ParamKeyword_stack[stack_top]="";
         offset_stack[stack_top]=(int)point('s');
         /*if (get_text(2)=='(*') {
            found_function_pointer = true;
         } */
         status=repeat_search();
         continue;
      }
      status=repeat_search();
   }
   lastid := "";
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]+1);
      status=_do_default_get_expression_info(true,idexp_info,visited,depth+1);
      errorArgs[1] = idexp_info.lastid;

      if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_model204_fcthelp_get",depth);
         isay(depth, "_model204_fcthelp_get: status="status);
      }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
         if (ParamNum<=0) ParamNum=1;
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
         // lastid is name of function or proc
         // (info_flags & VSAUTOCODEINFO_PVWAVE_IS_FUNC) indicates function
         // (info_flags & VSAUTOCODEINFO_PVWAVE_IS_PROC) indicates procedure

         tag_clear_matches();
         num_matches := 0;

         _UpdateContext(true);
         _UpdateLocals(true);
         typeless tag_files = tags_filenamea(p_LangId);
         tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     SE_TAG_FILTER_ANY_PROCEDURE, 
                                     SE_TAG_CONTEXT_ALLOW_LOCALS,
                                     true, p_EmbeddedCaseSensitive, visited, depth+1);
         //_message_box('lastid='lastid' num_matches='num_matches);

         isproc := false; //(info_flags & VSAUTOCODEINFO_PVWAVE_IS_PROC);
         // find matching symbols
         //say('lastid='lastid' num_matches='num_matches);
         _str match_list[];
         // remove duplicates from the list of matches
         int unique_indexes[];
         _str duplicate_indexes[];
         removeDuplicateFunctions(unique_indexes,duplicate_indexes);

         num_unique := unique_indexes._length();
         for (i:=0; i<num_unique; i++) {
            j := unique_indexes[i];
            tag_get_match_browse_info(j, auto cm);
            // maybe kick out if already have match or more matches to check
            if (match_list._length()>0 || i+1<num_unique) {
               if (_file_eq(cm.file_name,p_buf_name) && cm.line_no:==p_line) {
                  continue;
               }
               if (tag_tree_type_is_class(cm.type_name)) {
                  continue;
               }
               if (cm.arguments=="" && (cm.flags & SE_TAG_FLAG_EXTERN)) {
                  continue;
               }
               if (cm.type_name :== "define") {
                  if (cm.arguments == "") {
                     continue;
                  }
               }
            }
            list_proc_name := cm.member_name;
            if (cm.flags & SE_TAG_FLAG_OPERATOR) {
               list_proc_name= "operator "list_proc_name;
            }
            /*if (class_name != "") {
               if (javascript || isjava || slickc || isphp) {
                  list_proc_name = class_name '.' list_proc_name;
               } else {
                  list_proc_name = class_name '::' list_proc_name;
               }
            } */
            if (tag_tree_type_is_func(cm.type_name)) {
               if (cm.arguments == "void") {
                  cm.arguments = "";
               }
            } else if (cm.type_name :== "define") {
               cm.return_type = '#define';
            }
            cm.type_name = "proc";
            match_list[match_list._length()] = list_proc_name "\t" cm.type_name "\t" cm.arguments "\t" cm.return_type"\t"j"\t"duplicate_indexes[i];
            //say("match_list[i] = "match_list[match_list._length()-1]);
         }

         // get rid of any duplicate entries
         match_list._sort();

         // translate functions into struct needed by function help
         have_matching_params := false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = lastid;

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            for (i=0; i<match_list._length(); i++) {
               k := FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               parse match_list[i] with auto match_tag_name "\t" auto match_type_name "\t" auto signature "\t" auto return_type "\t" auto imatch "\t" auto duplist;
               //say("tag="match_tag_name" sig="signature" ret="return_type);
               tag_get_match_browse_info((int)imatch, auto cm);
               tag_autocode_arg_info_add_browse_info_to_tag_list(FunctionHelp_list[k], cm);
               FunctionHelp_list[k].prototype = return_type' 'match_tag_name'('signature')';
               base_length := length(return_type) + length(match_tag_name) + 2;
               FunctionHelp_list[k].argstart[0]=length(return_type)+1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               foreach (auto z in duplist) {
                  if (z == imatch) continue;
                  tag_get_match_browse_info((int)z,cm);
                  tag_autocode_arg_info_add_browse_info_to_tag_list(FunctionHelp_list[k], cm);
               }

               // parse signature and map out argument ranges
               arg_pos := 0;
               j := 0;
               argument := cb_next_arg(signature, arg_pos, 1);
               while (argument != "") {
                  //say("argument="argument);
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  if (j == ParamNum) {
                     // parse out the return type of the current parameter
                     pslang := p_LangId;
                     psindex := _FindLanguageCallbackIndex('%s_proc_search',pslang);
                     int temp_view_id;
                     int orig_view_id=_create_temp_view(temp_view_id);
                     _insert_text(argument';');
                     top();
                     if (psindex) {
                        _str pvarname;
                        pvarname="";
                        status=call_index(pvarname,1,pslang,psindex);
                        if (!status) {
                           tag_decompose_tag_browse_info(pvarname,auto param_cm);
                           FunctionHelp_list[k].ParamType=param_cm.return_type;
                           FunctionHelp_list[k].ParamName=param_cm.member_name;
                        }
                     }
                     _delete_temp_view(temp_view_id);
                     p_window_id = orig_view_id;
                  }
                  argument = cb_next_arg(signature, arg_pos, 0);
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
                  FunctionHelp_list_changed=true;
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
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName=idexp_info.lastid;
      gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}
