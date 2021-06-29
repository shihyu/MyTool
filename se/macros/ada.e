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
#import "files.e"
#import "env.e"
#import "mprompt.e"
#import "help.e"
#import "saveload.e"
#import "applet.e"
#import "projconv.e"
#import "wkspace.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "context.e"
#import "cutil.e"
#import "main.e"
#import "notifications.e"
#import "pascal.e"
#import "se/lang/api/LanguageSettings.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "se/tags/TaggingGuard.e"
#endregion

_str def_gprbuild_exe_path;

using se.lang.api.LanguageSettings;

/* 11/19/1996 - Ada95 support courtesy of Pat Rogers */

/*for Ada syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 0.
       3             Begin/end style. Not applicable to Ada.

       4             reserved.
       5             reserved.

*/

static const ADA_LANGUAGE_ID= 'ada';
static const ADA_MODE_NAME='Ada';

defeventtab ada_keys;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;
def "'"=auto_codehelp_key;
def ' '=ada_space;
def 'ENTER'=ada_enter;
//def 'C- '=codehelp_complete



/*
 * ===========================================================================
 * Syntax Expansion and Indenting
 * ===========================================================================
 * When you type a keyword such as MODULE and press Space Bar, a template
 * is inserted.  This is called syntax expansion.  For the VHDL language,
 * you would see the  following text expansion:
 *
 *      label_n132: process ()
 *      begin
 *
 *      end process; //label_n132
 *
 * You DO NOT have to type the entire keyword for syntax expansion to
 * occur.  If there is more than one keyword that matches what you have
 * typed, a selection list of possible keyword matches is displayed.
 * To get the template above you could just type "pr" followed by
 * Space Bar to get the same results.
 *
 * When the ENTER key is pressed while editing a source file
 * SlickEdit will indent to the next level if the cursor is moved
 * inside a structure block.  This is called syntax indenting.  For example,
 * if you edit a C file and the cursor is on a line containing "for (;;){"
 * and you press ENTER, a new line will be inserted and the cursor will be
 * indented three spaces in from the 'f' character in for.
 */


/**
 * Case the string 's' according to syntax expansion settings.
 *
 * @return The string 's' cased according to syntax expansion settings.
 *  
 * @deprecated Use {@link_word_case} instead
 */
_str _ada_keyword_case(_str s, bool confirm = true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

/* This command forces the current buffer to be in Ada mode. */
/* Unfortunately, this command only changes the mode-name, tab options, */
/* word wrap options, and mode key table. */
/* Not necessary for syntax expansion and indenting. */
_command void ada_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   /* The SELECT_EDIT_MODE procedure can find the file extension setup */
   /* data by passing it the 'ada' extension. */

   _SetEditorLanguage('ada');
}

/* This command is bound to the ENTER key.  It looks at the text around the */
/* cursor to decide whether to indent another level.  If it does not, the */
/* root key table definition for the ENTER key is called. */
_command void ada_enter () name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_ada_expand_enter);
}
bool _ada_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

/* This command is bound to the SPACE BAR key.  It looks at the text around */
/* the cursor to decide whether insert an expanded template.  If it does not, */
/* the root key table definition for the SPACE BAR key is called. */
_command void ada_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      ada_expand_space() ) {
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

/* Words must be in sorted order */
static const ADA_ENTER_WORDS= (' accept begin case else elsif if loop procedure record':+\
                   ' select while ');
static const ADA_EXPAND_WORDS= (' abort abstract accept access aliased array begin case constant declare delay ':+\
                   ' delta digits else elsif entry exception exit for function generic if limited ':+\
                   ' loop others package pragma private procedure protected raise range record ':+\
                   ' renames requeue return reverse select separate subtype tagged task terminate ':+\
                   ' type until when while with ');
static const ADA_DECL_WORDS= ' type declare ';
static const ADA_NAMED_END= ' accept function package procedure task ';
static const ADA_LABEL_WORDS= ' declare begin loop while for ';
static const RESERVED_WORDS= (' abort abs abstract accept access aliased all and array at begin body case constant declare delay':+\
                     ' delta digits do else elsif end entry exception exit for function generic goto if in is limited':+\
                     ' loop mod new not null of or others out package pragma private procedure protected raise range record':+\
                     ' rem renames requeue return reverse select separate subtype tagged task terminate':+\
                     ' then type until use when while with xor ');


static SYNTAX_EXPANSION_INFO ada_space_words:[]={
   'abort'       => { "ABORT" },
   'abstract'    => { "ABSTRACT" },
   'accept'      => { "ACCEPT ... DO ... END;" },
   'access'      => { "ACCESS" },
   'aliased'     => { "ALIASED" },
   'array'       => { "ARRAY" },
   'begin'       => { "BEGIN ... END;" },
   'case'        => { "CASE ... IS ... END CASE;" },
   'constant'    => { "CONSTANT" },
   'declare'     => { "DECLARE ... BEGIN END;" },
   'delay'       => { "DELAY" },
   'delta'       => { "DELTA" },
   'digits'      => { "DIGITS" },
   'else'        => { "ELSE" },
   'elsif'       => { "ELSIF ... THEN ..." },
   'entry'       => { "ENTRY ... WHEN ... IS ... BEGIN ... END;" },
   'exception'   => { "EXCEPTION ... WHEN => ..." },
   'exit'        => { "EXIT" },
   'for'         => { "FOR ... IN ... LOOP ... END LOOP;" },
   'function'    => { "FUNCTION" },
   'generic'     => { "GENERIC" },
   'if'          => { "IF ... THEN ... END IF;" },
   'limited'     => { "LIMITED" },
   'loop'        => { "LOOP ... END LOOP;" },
   'others'      => { "OTHERS" },
   'package'     => { "PACKAGE" },
   'pragma'      => { "PRAGMA" },
   'private'     => { "PRIVATE" },
   'procedure'   => { "PROCEDURE" },
   'protected'   => { "PROTECTED ... IS ... END;" },
   'raise'       => { "RAISE" },
   'range'       => { "RANGE" },
   'record'      => { "RECORD ... END RECORD;" },
   'renames'     => { "RENAMES" },
   'requeue'     => { "REQUEUE" },
   'return'      => { "RETURN" },
   'reverse'     => { "REVERSE" },
   'select'      => { "SELECT ... END SELECT;" },
   'separate'    => { "SEPARATE" },
   'subtype'     => { "SUBTYPE" },
   'tagged'      => { "TAGGED" },
   'task'        => { "TASK ... IS ... END;" },
   'terminate'   => { "TERMINATE" },
   'type'        => { "TYPE" },
   'until'       => { "UNTIL" },
   'when'        => { "WHEN" },
   'while'       => { "WHILE ... LOOP ... END LOOP;" },
   'with'        => { "WITH" },
};

/* Returns non-zero number if fall through to enter key required */
bool _ada_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   
   status := false;
   line := "";
   get_line(line);
   int width=(pos('[~ \t]',line,1,'r')-1);

   /* strip comments and get the first word */
   parse line with line '--' .;

   // Check for a label.  Two cases: a label by itself on
   // a line, or a label on the same line as expanded text.
   temp_label := remainder := label_remainder := "";
   word := func_name := first_word := rest := sample := "";
   if ( pos(':',line) ) { // found a colon, which might be for a label
      parse line with '[ \t]@','r' temp_label ':' remainder '--','r' .;
      if ( remainder == '' ) { // may be a label for next line
         if ( temp_label != '' && remainder == '' ) {
            //this is a stand-alone label
            indent_on_enter(syntax_indent);
            return(false); //don't do the keyword evaluation below, and no need for root enter key
         }
      } else { // something after the potential label
         parse temp_label with temp_label ':b','r' label_remainder;
         //messagenwait("temp_label is '"temp_label"'")
         if ( pos(temp_label,RESERVED_WORDS) == 0 ) { // really is a labeled statment
            // the following is the same as the original, except parses remainder
            parse remainder with '[~ \t]','r' +0 word ':b','r' func_name '[ (]','r' rest ' |$|--','r' .;
            first_word=lowcase(word);
            sample=word;
         } else { // treat in the usual way, for such things as 'protected T( X : Integer ) is'
            //messagenwait("seeing nonlabeled laine")
            parse line with '[~ \t]','r' +0 word ':b','r' func_name '[ (]','r' rest ' |$|--','r' .;
            first_word=lowcase(word);
            sample=word;
         }
      }
   } else { // no colon on this line so treat in the original way
      parse line with '[~ \t]','r' +0 word ':b','r' func_name '[ (]','r' rest ' |$|--','r' .;
      first_word=lowcase(word);
      sample=word;
   }

   enter_cmd:=name_on_key(ENTER);
   //messageNwait('first_word='first_word'  func_name='func_name'  rest='rest);
   next_line := before := "";
   file_status := 0;
   j := 0;
   if ( first_word=='entry' ) {
      if ( in_declarative_part() ) {
          insert_line(indent_string(width));
      } else { // body
          down(2); // to the 'end;', if this is the first time
          get_line(next_line);
          if ( pos('end;',next_line) ) {
             replace_line(substr(next_line,1,length(next_line)-1)' 'func_name';');
             up(); // to the 'begin'
             maybe_end_line();
             indent_on_enter(syntax_indent);
          } else {
             up(2);
          }
      }
   } else if ( first_word=='accept' ) { // no 'begin'
       down(); // to the 'end;'
       get_line(next_line);
       replace_line(substr(next_line,1,length(next_line)-1)' 'func_name';');
       up();
       maybe_end_line();
       indent_on_enter(syntax_indent);
   } else if ( first_word=='for' ) {
      // move to fields of 'for' statement
      line=expand_tabs(line);
      parse lowcase(line) with before 'in';
      if ( length(before)+1>=p_col ) {
         p_col=length(before)+4;  //move to the next field
      } else { //ready for sequence_of_statements
         maybe_end_line();
         indent_on_enter(syntax_indent);
      }
   } else if ( first_word=='package' ) {
      // not expanding package declarations due to generic instantations etc.
      // should only expand the body if this is the last line in the buffer
      file_status=down();
      if (file_status==BOTTOM_OF_FILE_RC) {  // should really be if "no text following"...
         if ( lowcase(func_name)=='body' ) {
            //message("package body at eof")
            insert_line(indent_string(width+syntax_indent));
            // no 'begin' since not frequently needed
            insert_line(indent_string(width)_word_case('end ',false,sample)rest';');
            up(2);
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            up();
         } else {
            //message("eof but not a package body")
            if ((enter_cmd=='nosplit-insert-line' || 
                (enter_cmd:=='maybe-split-insert-line' && !_insert_state())) ||
                p_col>=_text_colc()
                ) {
               _end_line();
               indent_on_enter(syntax_indent);
            } else { 
               indent_on_enter(0);
            }
         }
      } else {
         //message("not at eof")
         up(); // since went down to check for eof
         //maybe_end_line();
         if ((enter_cmd=='nosplit-insert-line' || 
             (enter_cmd:=='maybe-split-insert-line' && !_insert_state())) ||
             p_col>=_text_colc()
             ) {
            _end_line();
            indent_on_enter(syntax_indent);
         } else { 
            indent_on_enter(0);
         }
      }
   } else if ( first_word=='protected' ) {
      //messagenwait("seeing protected")
      if ( lowcase(func_name)=='body' ) {
         down();
         get_line(next_line);
         j=pos(';',next_line)-1;
         if ( j>=1 ) {
            replace_line(substr(next_line,1,j):+' 'rest';');
         }
         up();
      } else if ( lowcase(func_name)=='type' ) {
         //messagenwait("seeing type")
         insert_line(indent_string(width)_word_case('private',false,sample));
         down();
         get_line(next_line);
         j=pos(';',next_line)-1;
         if ( j>=1 ) {
            parse rest with func_name '[ (]','r' rest;
            replace_line(substr(next_line,1,j):+' 'func_name';');
         }
         up(2);
      } else { // object declaration
         //messagenwait("seeing object")
         insert_line(indent_string(width)_word_case('private',false,sample));
         down();  // to the 'end;'
         get_line(next_line);
         replace_line(substr(next_line,1,length(next_line)-1)' 'func_name';');
         up(2);
      }
      maybe_end_line();
      indent_on_enter(syntax_indent);
   } else if ( first_word=='task' ) {
      if ( lowcase(func_name)=='body' ) {
         insert_line(indent_string(width):+_word_case('begin',false,sample));
         down();
         get_line(next_line);
         j=pos(';',next_line)-1;
         if ( j>=1 ) {
            replace_line(substr(next_line,1,j):+' 'rest';');
         }
      } else if (lowcase(func_name)=='type' ) {
         down();
         get_line(next_line);
         j=pos(';',next_line)-1;
         if ( j>=1 ) {
            parse rest with func_name '[ (]','r' rest;
            replace_line(substr(next_line,1,j):+' 'func_name';');
         }
      } else { // object declaration
         down(); // to the 'end;'
         get_line(next_line);
         replace_line(substr(next_line,1,length(next_line)-1)' 'func_name';');
      }
      up();
      maybe_end_line();
      indent_on_enter(syntax_indent);
   } else if ((first_word=='end;' || first_word=='end') && ((enter_cmd=='nosplit-insert-line' || 
                (enter_cmd:=='maybe-split-insert-line' && !_insert_state())) ||
                p_col>=_text_colc()
              ) && associated_decl(auto unit_name2,auto non_blank_col2,true)!='') {
      get_line(auto orig_line);
      replace_line(indent_string(non_blank_col2-1):+strip(orig_line,'L'));
      _end_line();
      status=true;
   } else if ( pos(' 'first_word' ',ADA_ENTER_WORDS,1) ) {
      orig_col := p_col;
      _end_line();
      _clex_skip_blanks('-');
      at_end := (orig_col >= p_col);
      p_col = orig_col;
      if ( at_end ) {
         if ( line=='begin' && 
              ((enter_cmd=='nosplit-insert-line' || 
                (enter_cmd:=='maybe-split-insert-line' && !_insert_state())) ||
                orig_col>=_text_colc()
              )
              ) {
            auto unit_name=associated_decl(unit_name,auto non_blank_col);
            if (unit_name!='') {
               get_line(auto orig_line);
               replace_line(indent_string(non_blank_col-1):+strip(orig_line,'L'));
               _end_line();
            }
         }

         //maybe_end_line();
         indent_on_enter(syntax_indent);
      } else {
         status=true;     // just do a normal enter key
      }

   } else {
     status=true;     // just do a normal enter key
   }

   if (!status) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
}

/* Returns non-zero number if fall through to space bar key required */
static _str ada_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   
   /* Put first word of line in lower case into word variable. */
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');

   /* procede only for cursor on first word */
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   word := strip(line);
   aliasfilename := "";
   if ( word=='') {
      return(1);    /* Fall through to space bar key. */
   }

   label := "";
   orig_word := "";
   typeless mult_line_info;
   col := 0;
   line_prefix := "";
   label_line := "";
   colon_pos := 0;
   temp_label := remainder := "";
   width := 0;
   sample := "";
   if ( pos(':',line,1) == 0 ) { // no colon on this line
      sample=strip(line);
      orig_word=lowcase(strip(line));
      word=min_abbrev2(orig_word,ada_space_words,'',aliasfilename);

      // can we expand an alias?
      if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
         // if the function returned 0, that means it handled the space bar
         // however, we need to return whether the expansion was successful
         return expandResult;
      }

      if ( word=='') {
         return(1);    /* Fall through to space bar key. */
      }
      // look on the previous line for a stand-alone label
      // Rather than go hunting, the label, if any, must be only 1 line up.
      // This will be ok since a label is never the first line of a program unit.
      up();
      get_line(label_line);
      colon_pos=pos(':',label_line);
      if ( colon_pos != 0 ) { // found a colon, which might be for a label
         parse label_line with '[ \t]@','r' temp_label ':' remainder '--','r' .;
         if ( remainder == '' ) { // a label for previous line
            if ( temp_label != '' ) { //found a label
               if ( pos(' 'word' ',ADA_LABEL_WORDS) != 0 ) { // the word is allowed to have a label
                  label=' 'strip(temp_label);
               } else { // illegal label word
                  down();
                  message("Only these can have a statement identifier: "ADA_LABEL_WORDS);
                  return(1);
               } // legal label word
            } // is an attempted label
         } // could be a label
      } // found colon
      down();
      line=substr(line,1,length(line)-length(orig_word)):+_word_case(word,false,sample);
      width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   } else { // found ':'
      parse line with '[ \t]@','r' label ':' remainder;
      if ( pos('=',remainder,1) == 1 ) { // found assignment operation
         return(1); //fall through to space bar key
      }
      // Treat as a label, even if it won't be, such as in variable declarations.
      // Since we only use it where allowed, this isn't a problem.
      label=' 'strip(label);
      if (remainder=='') {
         return(1);
      }
      sample=strip(remainder);
      orig_word=lowcase(strip(remainder));
      word=min_abbrev2(orig_word,ada_space_words,'',aliasfilename);

      // can we expand an alias?
      if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
         // if the function returned 0, that means it handled the space bar
         // however, we need to return whether the expansion was successful
         return expandResult;
      }

      if ( word=='') {
         return(1);    /* Fall through to space bar key. */
      }
      if ( pos(' 'word' ',ADA_LABEL_WORDS) == 0 ) { // these can't have a label!
         message("Only these can have a statement identifier: "ADA_LABEL_WORDS);
         return(1);
      }
      line=substr(line,1,length(line)-length(orig_word)):+_word_case(word,false,sample);
      width=text_col(line,pos(label,line),'i');
   }

   // Insert the appropriate template based on the reserved word
   set_surround_mode_start_line();
   doNotify := true;
   status := 0;
   new_line := "";
   if ( word=='accept' ) {
      replace_line(line:+' ':+_word_case(' do',false,sample));
      insert_line(indent_string(width)_word_case('end;',false,sample));
      set_surround_mode_end_line();
      up();
      p_col += 3;
      insert_mode();
   } else if ( word=='if' ) {
      replace_line(line:+' ':+_word_case(' then',false,sample));
      insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('if;',false,sample));
      set_surround_mode_end_line();
      up();
      p_col=width+4;
      insert_mode();
   } else if ( word=='for' ) {
      // expand it here since it must be a statement
      if (!in_entry_statement() && !in_declarative_part()) {
         new_line=line:+' ':+_word_case(' in ',false,sample):+' ':+_word_case('loop',false,sample);
         replace_line(new_line);
         insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('loop',false,sample):+label';');
         set_surround_mode_end_line();
         up();
         p_col=length(new_line)-8;
         insert_mode();
      } else { 
         // leave it alone due to attribute clauses, etc. (use alias facility)
         replace_line(line);
         _end_line();
         return(1);
      }
   } else if ( word=='begin' ) {
      replace_line(line);
      if (label != '') {
         insert_line(indent_string(width+syntax_indent));
         insert_line(indent_string(width)_word_case('end',false,sample):+label';');
         set_surround_mode_end_line();
         up();
         _end_line();
         insert_mode();
      } else {
         _str unit_name=associated_decl(unit_name,auto non_blank_col);
         if (unit_name != '') {
            // two people have asked for this, I give in...
            width=non_blank_col-1;
            replace_line(indent_string(width)strip(line)' -- 'unit_name);
            insert_line(indent_string(width)_word_case('end',false,sample)' 'unit_name';');
            up();
            insert_line(indent_string(width+syntax_indent));
            insert_mode();
         } else {
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width)_word_case('end',false,sample)';');
            set_surround_mode_end_line();
            up();
            _end_line();
            insert_mode();
         }
      }
   } else if ( word=='task' ) {
      replace_line(line:+_word_case('  is',false,sample));
      insert_line(indent_string(width)_word_case('end;',false,sample));
      up();
      p_col=width+length(word)+2;
      insert_mode();
   } else if ( word=='protected' ) {
      replace_line(line:+_word_case('  is',false,sample));
      insert_line(indent_string(width)_word_case('end;',false,sample));
      up();
      p_col=width+length(word)+2;
      insert_mode();
   } else if ( word=='while' ) {
      new_line=line:+_word_case('  loop',false,sample);
      replace_line(new_line);
      insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('loop',false,sample):+label';');
      set_surround_mode_end_line();
      up();
      p_col=length(new_line)-4;
      insert_mode();
   } else if ( word=='record' || word=='select' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('end ',false,sample):+_word_case(word';',false,sample));
      up();
      insert_line(indent_string(width+syntax_indent));
      insert_mode();
   } else if ( word=='case' ) {
      replace_line(line:+_word_case('  is',false,sample));
      insert_line(indent_string(width)_word_case('end',false,sample):+' ':+_word_case('case;',false,sample));
      set_surround_mode_end_line();
      up();p_col=width+6;
      insert_mode();
   } else if ( word=='exception' ) {
      replace_line(_word_case(line,false,sample):+' ');
      insert_line(indent_string(width+syntax_indent)_word_case('when =>',false,sample));
      p_col=width+syntax_indent+6;
      insert_mode();
   } else if ( word=='entry' ) {
      if ( !in_declarative_part() ) { //entry declaration
         return(1);
      } else { //entry body
         replace_line(line:+'  '_word_case('when',false,sample)'  '_word_case('is',false,sample));
         insert_line(indent_string(width):+_word_case('begin',false,sample));
         insert_line(indent_string(width):+_word_case('end;',false,sample));
         set_surround_mode_end_line();
         up(2);
         p_col=width+length(word)+2;
      }
      insert_mode();
   } else if ( word=='loop' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('end',false,sample):+' ':+_word_case('loop',false,sample):+label';');
      up();
      insert_line(indent_string(width+syntax_indent));
      set_surround_mode_end_line(p_line+1);
      insert_mode();
   } else if ( word=='elsif' ) {
      replace_line(line:+' ':+_word_case(' then',false,sample));
      p_col=width+7;
   } else if ( word=='declare' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('begin',false,sample));
      insert_line(indent_string(width):+_word_case('end',false,sample):+label';');
      up(2);_end_line();
      indent_on_enter(syntax_indent);
      insert_mode();

      set_surround_mode_end_line(p_line+2);
   } else if ( pos(' 'word' ',ADA_EXPAND_WORDS) ) {
      replace_line(line:+' ');
      _end_line();

      doNotify = (line != orig_line);
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

int _ada_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, ada_space_words, prefix, min_abbrev);
}

static void maybe_end_line() {
   if (name_on_key(ENTER)=='split-insert-line') {
     _end_line();
   }
}

static bool in_entry_statement()
{
   save_pos(auto p);
   _first_non_blank_col();
   orig_col := p_col;
   while (up()==0) {
      _first_non_blank_col();
      if (p_col > orig_col) {
         break;
      }
      orig_col = p_col;
      prev_line := "";
      get_line(prev_line);
      prev_first_word := "";
      prev_second_word := "";
      rest := "";
      parse prev_line with '[~ \t]','r' +0 prev_first_word ':b','r' prev_second_word '([~a-zA-Z0-9_.])','r' rest ' |$|--','r' . ;
      if ( prev_first_word=='end' ) break;
      if ( prev_first_word=='entry' ) {
         restore_pos(p);
         return true;
      }
   } // loop
   restore_pos(p);
   return false;
}

static bool in_declarative_part()
{
   save_pos(auto p);
   while (up()==0) {
      prev_line := "";
      get_line(prev_line);
      prev_first_word := "";
      prev_second_word := "";
      rest := "";
      parse prev_line with '[~ \t]','r' +0 prev_first_word ':b','r' prev_second_word '([~a-zA-Z0-9_.])','r' rest ' |$|--','r' . ;
      if ( prev_first_word=='task' ||
           prev_first_word=='protected' ||
           prev_first_word=='private' ||
           prev_first_word=='procedure' ||
           prev_first_word=='function' ||
           prev_first_word=='package' ) {
         if ( prev_second_word=='body' ) {
            break;
         }
         restore_pos(p);
         return true;
      }
      if (prev_first_word=='begin') {
         break;
      }
   } // loop
   restore_pos(p);
   return false;
}

static const ADA_WORD_SEP_CHARS= '([~a-zA-Z0-9_]|^|$)';
static const ADA_IDENTIFIER_CHARS= '[a-zA-Z0-9_]';


static void insert_mode()
{
   if ( ! _insert_state() ) _insert_toggle();
} // insert_mode

static int instantiation(_str first_line)
{
   // check for an instantiation *on the same line* as the subprogram decl
   if ( pos(ADA_WORD_SEP_CHARS'is'ADA_WORD_SEP_CHARS'new', first_line, 1, 'r') ) {
      //messagenwait("encountered subprogram instantiation")
      return(1);
   }

   // check for instantiation on multiple lines
   down();
   next_line := "";
   get_line(next_line);
   word1 := "";
   word2 := "";
   rest := "";
   parse next_line with '[~ \t]','r' +0 word1 ':b','r' word2 ';' rest ' |$|--','r' . ;
   if (word1 == 'new') {
      up();
      return(1);
   } else {
      up();
   }
   return(0); // default result
} // instantiation

static int significant_end(_str this_line)
{
   // 'end;' and 'end identifier' are significant, all others are not
   if ( pos('end;',this_line,1) ) {
      return(1);
   }
   word1 := "";
   word2 := "";
   rest := "";
   parse this_line with '[~ \t]','r' +0 word1 ':b','r' word2 ';' rest ' |$|--','r' . ;
   if ( word1=='end' && (word2 != 'loop' && word2 != 'record' && word2 != 'if')  ) {
      return(1);
   }
   return(0);
} // significant_end

static _str associated_decl(_str &result,int &non_blank_col=0, bool do_end=false)
{
   block_count := 0;
   expecting_declaration := 0;
   up_count := 0;
   prev_line := "";
   word1 := "";
   id := "";
   rest := "";
   result='';

   se.tags.TaggingGuard sentry;
   save_pos(auto startPos);
   orig_line:="";

   if (do_end) {
      _first_non_blank();
   } else {
      get_line(orig_line);
      replace_line('begin');
      insert_line('x:=x+1;');
      insert_line('end;');_begin_line();
   }

   sentry.lockContext(false);

   _UpdateContext(true,true,VS_UPDATEFLAG_context/*|VS_UPDATEFLAG_statement*/);
   //_UpdateStatements(true,true);
   ctx := tag_current_context();
   //ctx := tag_current_statement();

   if (ctx>0) {
      tag_get_detail2(VS_TAGDETAIL_statement_start_linenum, ctx, auto startLine);
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, ctx, auto startSeek);
      tag_get_detail2(VS_TAGDETAIL_statement_end_linenum, ctx, auto endLine);
      tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, ctx, auto endSeek);
      //tag_get_detail2(VS_TAGDETAIL_statement_type, ctx, auto tagType);
      //tag_get_detail2(VS_TAGDETAIL_statement_outer, ctx, auto outer);
      //say('ctx='ctx' startSeek='startSeek' p_line='p_line' end='end_line);
      if (p_line==endLine) {
         _GoToROffset(startSeek);
         _begin_line();
         int status;
         if (do_end) {
            status=search("^[ \t]@((task|package)[ \t]#body|function|procedure|entry)[ \t#]{#1[a-zA-Z0-9_]#}|",'r@'
                           //:+"|":+"task[ \t]#body[ \t#]{#1[a-zA-Z0-9_]#}"
                           );
         } else {
            status=search("^[ \t]@(task[ \t]#body|function|procedure|entry)[ \t#]{#1[a-zA-Z0-9_]#}|",'r@'
                           //:+"|":+"task[ \t]#body[ \t#]{#1[a-zA-Z0-9_]#}"
                           );
         }
         if (!status && match_length()) {
            result=get_match_text(1);
            _first_non_blank();
            non_blank_col=p_col;
         }

      }
   }
   restore_pos(startPos);
   if (!do_end) {
      down();
      _delete_line();_delete_line();
      restore_pos(startPos);
      replace_line(orig_line);
   }
   return result;
#if 0
   int status=up();
   while (status==0) {
      up_count++;
      get_line(prev_line);
      if ( pos('begin',prev_line,1,'i') ) {
         //messagenwait("encountered 'begin' with block_count "block_count)
         if (block_count == 0) {
           break;
         } else {
            block_count++;
         }
      } else if ( significant_end(prev_line) ) {
         //messagenwait( "encountered significant 'end'")
         block_count--;
         expecting_declaration=1;
      } else if ( pos(ADA_WORD_SEP_CHARS'{procedure|function}'ADA_WORD_SEP_CHARS, prev_line, 1, 'ri') ) {
         // found subprogram keyword
         //messagenwait('subprogram encountered')
         if ( ! instantiation(prev_line) ) {
            if (expecting_declaration) { // found decl for previously encountered begin/end
               //messagenwait("ignoring expected subprogrm decl")
               expecting_declaration=0;
            } else { // use this one
               parse prev_line with '[ \t]@','r' word1 ':b','r' id '([~a-zA-Z0-9_."=/<>&*+-])','r' rest ;
               result=id;
               save_pos(auto p);
               first_non_blank();
               non_blank_col=p_col;
               restore_pos(p);
               break;
            } // block_count check
         } // instantiation check
      } // if word of interest
      status=up();
   } // loop
   down(up_count);
   return(result);
#endif
} // associated_decl


/* ada_get_filename performs the following;
      1) if new view info supplied then switch to new view
      2) capture current buffer view info
      3) reverse search for "compiling " at beginning of line
      4) set filename='' if "compiling " not found
         or set filename to value on line after "compiling"
      5) reset old view
*/
_str ada_get_filename(_str &filename)
{
   view_id := 0;
   if ( arg(2)!='' ) {    /* swicth to new view if needed */
      get_window_id(view_id);
      activate_window(arg(2));
   }
   typeless p=point();
   typeless ln=point('L');
   cl := p_col;
   left_edge := p_left_edge;
   cursor_y := p_cursor_y;
   search('^compiling ','@rhi-');
   if ( rc ) {
      filename='';
   } else {
      cur_line := "";
      get_line(cur_line);
      parse cur_line with . filename;
      goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
   }
   if ( arg(2)!='' ) {
      activate_window(view_id);
   }
   return('');
}



//////////////////////////////////////////////////////////////////////////
// Context Tagging(R) support functions, delegated mostly to pascal.e
//

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
int _ada_get_expression_info(bool PossibleOperator, 
                             VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _pas_get_expression_info(PossibleOperator, idexp_info, visited, depth);
}
int _ada_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _pas_find_context_tags(errorArgs, prefixexp, 
                                 lastid, lastidstart_offset,
                                 info_flags, otherinfo, 
                                 find_parents, max_matches,
                                 exact_match, case_sensitive,
                                 filter_flags, context_flags,
                                 visited, depth, prefix_rt);
}
int _ada_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return _pas_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth);
}
int _ada_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     bool &FunctionHelp_list_changed,
                     int &FunctionHelp_cursor_x,
                     _str &FunctionHelp_HelpWord,
                     int FunctionNameStartOffset,
                     int flags,
                     VS_TAG_BROWSE_INFO symbol_info=null,
                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _pas_fcthelp_get(errorArgs,
                           FunctionHelp_list,
                           FunctionHelp_list_changed,
                           FunctionHelp_cursor_x,
                           FunctionHelp_HelpWord,
                           FunctionNameStartOffset,
                           flags, symbol_info,
                           visited, depth);
}

int _ada_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "ada";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext) && !forceRebuild) {
      return(0);
   }

   // the user does not have an extension specific tag file for Ada
   status := 0;
   dcc_binary := "";
   std_libs := "";
   dcc_binary=path_search('gprbuild','PATH','P');
   if (dcc_binary=='') {
      parse _ntRegQueryValue(HKEY_CURRENT_USER,
                               'SOFTWARE\Classes\adb_auto_file\shell\Open\Command') with auto value .;
      name:=_strip_filename(value,'p');
      if (file_eq(name,'gps.exe')) {
         dcc_binary=_strip_filename(value,'n');
      }
   }
   if (dcc_binary=='') {
      if (_isWindows()) {
         status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                                  "SOFTWARE\\Free Software Foundation",
                                  "GNAT", dcc_binary);
         if (!status) {
            dcc_binary :+= "\\bin\\adagide.exe";
         }
      }
      if (dcc_binary=='') {
         dcc_binary=path_search("adagide","","P");
      }
      if (dcc_binary!="") {
         path := _strip_filename(dcc_binary,"n");
         _maybe_strip_filesep(path);
         name := _strip_filename(path,"p");
         if (_file_eq(name,"bin")) {
            path=_strip_filename(path,"n");
         }
         _maybe_append_filesep(path);
         source_path := file_match(_maybe_quote_filename(path:+"lib"), 1);
         if (source_path!='') {
            path :+= "lib":+FILESEP;
         }
         std_libs=_maybe_quote_filename(path:+"*.ads"):+' ':+_maybe_quote_filename(path:+"*.adb");
         //say("_ada_MaybeBuildTagFile: path="path" std_libs="std_libs);
      }
   } else {
      path:=_strip_filename(absolute(dcc_binary),'n');
      // Remove "bin" directory
      _maybe_strip_filesep(path);
      path = _strip_filename(path,"n");
      //c:\gnat\2019\lib\gcc\x86_64-pc-mingw32\
      path2:=path:+'lib/gcc/x86_64-pc-mingw32/';
      path:+='include/';
      //say('include path='path);
      std_libs=_maybe_quote_filename(path:+"*.ads"):+' ':+_maybe_quote_filename(path:+"*.adb"):+
         ' ':+_maybe_quote_filename(path2:+"*.adb"):+' ':+_maybe_quote_filename(path2:+"*.ads");
   }
   

   // got the path, now build and save the tag file
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Ada Compiler Libraries",
                           true,std_libs,ext_builtins_path(ext,ext), withRefs, useThread);
}

/**
 * This function implements the callback for block matching in Ada.
 * <p>
 * It handles the following cases:
 * <ul>
 * <li>Simple loop statement
 * <pre>
 *   |---> loop
 *   |        statements
 *   |---> end loop;
 * </pre>
 * <li>While statement
 * <pre>
 *   |---> while x = 0
 *   |---> loop
 *   |        statements
 *   |---> end loop;
 * </pre>
 * <li>For statement
 * <pre>
 *   |---> for i in spec
 *   |---> loop
 *   |        statements
 *   |---> end loop;
 * </pre>
 * <li>If statement
 * <pre>
 *   |---> if x = 1 then
 *   |        statements
 *   |---> elsif x = 2 then
 *   |        statements
 *   |---> elsif x = 3 then
 *   |        statements
 *   |---> else
 *   |        statements
 *   |---> end if;
 * </pre>
 * <li>Declare statement
 * <pre>
 *   |---> declare
 *   |        x : integer;
 *   |---> begin
 *   |        statements
 *   |---> end;
 * </pre>
 * <li>Select statement
 * <pre>
 *   |---> select
 *   |       accept a;
 *   |     or
 *   |       delay 2.5;
 *   |---> else
 *   |        statements
 *   |---> end select;
 * </pre>
 * <li>Case statement
 * <pre>
 *   |---> case x is
 *   |        when 100000 => statements
 *   |        when others => statements
 *   |---> end case;
 * </pre>
 * <li>Accept statement
 * <pre>
 *   |---> accept e
 *   |        statements
 *   |---> end e;
 * </pre>
 * <li>Record declaration
 * <pre>
 *   |---> record
 *   |        x : integer;
 *   |---> end;
 * </pre>
 * <li>Record declaration
 * <pre>
 *   |---> record
 *   |        x : integer;
 *   |---> end record;
 * </pre>
 * <li>Package declaration
 * <pre>
 *   |---> package XXX is
 *   |        x : integer;
 *   |---> end package;
 * </pre>
 * <li>Package body
 * <pre>
 *   |---> package body XXX is
 *   |        x : integer;
 *   |---> private
 *   |        z : integer;
 *   |---> begin
 *   |        statements
 *   |---> end package;
 * </pre>
 * <li>Task declaration
 * <pre>
 *   |---> task XXX is
 *   |        x : integer;
 *   |---> end task;
 * </pre>
 * <li>Task body
 * <pre>
 *   |---> task body XXX is
 *   |        x : integer;
 *   |---> begin
 *   |        statements
 *   |---> end task;
 * </pre>
 * <li>Procedure definition
 * <pre>
 *   |---> procedure XXX is
 *   |        x : integer;
 *   |---> begin
 *   |        statements
 *   |---> end XXX;
 * </pre>
 * <li>Function definition
 * <pre>
 *   |---> function XXX(y:integer) return boolean is
 *   |        x : integer;
 *   |---> begin
 *   |        statements
 *   |---> end XXX;
 * </pre>
 * <li>Entry definition
 * <pre>
 *   |---> entry XXX(y:integer) 
 *   |        for i in extent
 *   |        when x = 0 is
 *   |---> begin
 *   |        statements
 *   |---> end XXX;
 * </pre>
 * </ul>
 * <p>
 * The following additional statements are handled for VHDL.
 * <ul>
 * <pre>
 *   |---> process(input,output)
 *   |---> begin
 *   |        statements
 *   |---> end XXX;
 * </pre>
 * <pre>
 *   |---> process(input,output)
 *   |---> begin
 *   |        statements
 *   |---> end XXX;
 * </pre>
 * <pre>
 *   |---> entity XXX
 *   |---> end XXX;
 * </pre>
 * </ul>
 * 
 * @param quiet   just return status, no messages
 * @return 0 on success, nonzero if no match
 */
int _ada_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   // Get current word at cursor:
   typeless orig_position;
   save_pos(orig_position);
   isKeyword := (_clex_find(0,'g') == CFG_KEYWORD);
   if (!isKeyword && p_col>0) {
      left();
      isKeyword = (_clex_find(0,'g') == CFG_KEYWORD);
      restore_pos(orig_position);
   }
   start_col := 0;
   _str word = cur_identifier(start_col);
   word = lowcase(word);
   restore_pos(orig_position);
   if (word == "" || !isKeyword) {
      if (!quiet) {
         message(nls('Not on begin/end or word pair'));
      }
      return 1;
   }

   // Only some words have matching words. Find the actual word
   // to match and the expected word to match.
   direction := "";
   if (word=="while" || word=="for" || 
       word=="if" || word=="then" ||
       word=="declare" || word=="case" || 
       word=="record" || word=="loop" ||
       word=="package" || word=="task" ||
       word=="procedure" || word=="function" ||
       word=="accept" ||
       word=="entry" || word=="select" ||
       (
          _LanguageInheritsFrom("vhd") &&
          (
            word=="architecture" || word=="component" ||
            word=="process" || word=="entity"
          )
       )) {

      direction = "";
      p_col = start_col - 2;
      _str prev_word = cur_identifier(start_col);
      prev_word = lowcase(prev_word);
      if (prev_word == "end") {
         direction = "-";
         p_col = start_col;
         word=prev_word;
      } else {
         restore_pos(orig_position);
      }

   } else if (word == "begin" || word=="private" ||
              word == "elsif" || word=="else" ) {
      direction = "";

   } else if (word == "end") {
      direction = "-";

   } else {
      if (!quiet) {
         message(nls('Not on begin/end or word pair'));
      }
      return 1;
   }

   // Find the matching word:
   int status = matchWord(word, direction, quiet);
   if (!status) {
      restore_pos(orig_position);
      if (!quiet) {
         message(nls('Matching word not found'));
      }
      return 1;
   }

   return 0;
}

// Desc: Match the word
// Retn: 1 for word matched, 0 not
static int matchWord(_str word, _str direction, bool quiet)
{
   // match in specified direction
   iterations := 0;
   level := 0;
   status := 0;

   // extended support for VHDL syntax
   vhdl_regex := "";
   vhdl_words := "";
   if (_LanguageInheritsFrom('vhd')) {
      vhdl_words = " process architecture component entity ";
      vhdl_regex = "|process|architecture|component|entity";
   }

   // should we be expecting a 'begin' keyword?
   word_chars := _clex_identifier_chars();
   long begin_pos[];
   begin_pos._makeempty();
   begin_pos[0]=-1;
   bool expecting_begin[];
   expecting_begin._makeempty();
   expecting_begin[0]=false;
   if (pos(' 'word' ', ' procedure function package task declare select entry for while ':+vhdl_words)) {
      expecting_begin[0] = true;
   }

   while (1) {

      // if in quiet mode and the user typed something, just give up
      // and return focus to the user.
      if ((++iterations % 100) == 0 && quiet && _IsKeyPending()) {
         return 0;
      }

      // Skip over the current word:
      status = search(" |[~"word_chars"]|$", direction"rh@XCS");
      if (status) {
         return 0;
      }

      // Search for next block key word:
      status = search("procedure|function|begin|end|while|if|loop|elsif|else|for|declare|case|record|package|task|accept|entry|select|private":+vhdl_regex, direction"rwh@iCK");
      if (status) {
         return 0;
      }

      // Check new block keyword. If keyword indicates a new
      // block, increase the nesting level. Otherwise, decrease
      // the nesting level. If current nesting level is 0, we've
      // found the matching word.
      start_col := 0;
      _str current = cur_identifier(start_col);
      current = lowcase(current);

      // skip over extraneous 'for' keywords
      if (current=="for" && (in_entry_statement() || in_declarative_part())) {
         continue;
      }

      // skip over extraneous 'else' keywords
      if (current=="else" && _LanguageInheritsFrom('vhd')) {
         get_line(auto line);
         if (pos(":bwhen:b", line, 1, 'r')) {
            continue;
         }
      }

      // cheap, somewhat innacrate way to check for forward declarations
      if (current=="package" || 
          current=="process" || 
          current=="entity" || 
          current=="architecture" || 
          current=="component" || 
          current=="task" || 
          current=="entry" || 
          current=="accept") {
         get_line(auto line);
         if (_last_char(strip(line))==';') {
            continue;
         }
      }

      // skip over private if searching backwards or nested
      if ((direction=="-" || level>=1) && current=="private") {
         continue;
      }

      // check for prototypes
      if (current == "procedure" || current=="function") {

         // watch out for "generic with procedure"
         get_line(auto line);
         if (pos(":bwith:b"current":b", line, 1, 'ir')) {
            continue;
         }
         if (pos(current":bis:b", line, 1, 'ir')) {
            continue;
         }

         tag_type := "";
         tag_lock_context(true);
         _UpdateContext(true);
         int context_id = tag_current_context();
         if (context_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_type, context_id, tag_type);
            if (tag_type == "proto" || tag_type=="procproto") {
               tag_unlock_context();
               continue;
            }
            // maybe it is a local prototype?
            if (tag_tree_type_is_func(tag_type)) {
               _UpdateLocals(true, true);
               int local_id = tag_current_local();
               if (local_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_local_type, local_id, tag_type);
                  if (tag_type == "proto" || tag_type=="procproto") {
                     tag_unlock_context();
                     continue;
                  }
               }
            }
         }
         tag_unlock_context();
      }

      // check if we are on 'end if' or something like that
      if (direction=='-' && current!='end') {
         orig_col := p_col;
         p_col = start_col - 2;
         _str prev_word = cur_identifier(start_col);
         if (lowcase(prev_word) == "end") {
            current = "end";
         } else {
            p_col = orig_col;
         }
      }

      //say("matchWord: word="current" line="p_line" expecting_begin="expecting_begin[level]" begin_pos["level"]="begin_pos[level]);
      if (current == "begin" || current=="loop" || current=="private") {
         if (direction=='') {
            if (expecting_begin[level]) {
               level--;
            }
            if (level<0) {
               return 1;
            }
            level++;
            begin_pos[level]=-1;
            expecting_begin[level]=false;
         } else {
            // check for mismatched begin/end pairs
            if (begin_pos[level] < 0) {
               begin_pos[level] = _QROffset();
            } else {
               while (level > 0 && begin_pos[level] >= 0) {
                  level--;
               }
               if (level == 0 && begin_pos[level] >= 0) {
                  _GoToROffset(begin_pos[level]);
                  return 1;
               }
            }
         }

      } else if (current=="else" || current=="elsif") {
         if (level > 0) {
            continue;
         }
         if (direction=='') {
            return 1;
         } else {
            // check for mismatched begin/end pairs
            while (level > 0 && begin_pos[level] >= 0) {
               level--;
            }
            if (level == 0 && begin_pos[level] >= 0) {
               _GoToROffset(begin_pos[level]);
               return 1;
            }
         }

      } else if (current == "end") {
         if (direction=='') {
            level--;
            if (level < 0) {
               return 1;
            }
            _end_line();
         } else {
            // check for simple mismatched begin/end pair
            level++;
            begin_pos[level]=-1;
            expecting_begin[level]=false;
         }

      } else {

         if (direction == '') {
            level++;
            begin_pos[level]=-1;
            expecting_begin[level]=false;
            if (pos(' 'current' ', ' procedure function package declare select task entry for while ':+vhdl_words)) {

               expecting_begin[level] = true;

               if (current == "package") {
                  _str line, first_word, second_word;
                  get_line(line);
                  parse line with first_word second_word . ;
                  if (lowcase(first_word)=="package" && lowcase(second_word)!="body") {
                     expecting_begin[level]=false;
                  }
                  if (lowcase(first_word)=="task" && lowcase(second_word)!="body") {
                     expecting_begin[level]=false;
                  }
               }
            }
         } else {

            if (level==0) {
               // check for simple mismatched begin/end pair
               if (begin_pos[level] >= 0 && !pos(' 'current' ', ' procedure function package task declare select entry for while ':+vhdl_words)) {
                  _GoToROffset(begin_pos[level]);
                  return 1;
               }
               return 1;
            } else {
               level--;
               if (level < 0) {
                  return 1;
               }
            }
         }
      }
   }

   return 0;
}
_command int new_gprbuild_proj(_str configName = 'Debug') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status;
   status=mkdir('src');
   if (status) {
      _message_box("Unable to make 'src' directory");
      return 1;
   }
   status=mkdir('obj');
   if (status) {
      _message_box("Unable to make 'obj' directory");
      return 1;
   }
   _str filename;
   status=generate_main(filename);
   if (status) {
      return COMMAND_CANCELLED_RC;
   }
   status=generate_gprbuild();
   if (status) {
      return COMMAND_CANCELLED_RC;
   }
   status=edit(_maybe_quote_filename(filename));
   return 0;
}
static int generate_gprbuild() {
   // build filename with appropriate extension
   filename:= _strip_filename(_project_name,'N'):+ _strip_filename(_project_name,'PE'):+'.gpr';

   // if the file already exists, see if it should be overwritten
   if (file_exists(filename)) {
      int result = _message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if(result == IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      } else if(result == IDNO) {
         return 1;
      }
   }

   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = filename;
   //p_UTF8 = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr = indent_string(p_SyntaxIndent);
   name:=_strip_filename(filename,'pe');
   insert_line('project 'name' is');
   insert_line('    for Source_Dirs use ("src");');
   insert_line('    for Object_Dir use "obj";');
   insert_line('    for Main use ("main.adb");');
   insert_line('');
   insert_line('    package Compiler is');
   insert_line('       for Switches ("ada") use ("-g", "-gnata");');
   insert_line('    end Compiler;');
   insert_line('');
   insert_line('    package Pretty_Printer is');
   insert_line('        for Default_Switches ("ada") use ("-i4", "-kU", "-c4", "-c3", "--no-separate-is");');
   insert_line('    end Pretty_Printer;');
   insert_line('end 'name';');

   int status=_save_file(build_save_options(p_buf_name));

   _AddFileToProject(filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}
static int generate_main(_str &filename) {
   // build filename with appropriate extension
   filename= _strip_filename(_project_name,'N') :+ 'src/main.adb';

   // if the file already exists, see if it should be overwritten
   if (file_exists(filename)) {
      int result = _message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if(result == IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      } else if(result == IDNO) {
         return 1;
      }
   }

   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = filename;
   //p_UTF8 = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr = indent_string(p_SyntaxIndent);

   insert_line('with Ada.Text_IO; use Ada.Text_IO;');
   insert_line('');
   insert_line('procedure Main is');
   insert_line('begin');
   insert_line(indentStr:+'Put_Line("Hello World");');
   insert_line('end Main;');

   int status=_save_file(build_save_options(p_buf_name));

   _AddFileToProject(filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}
static _str guessgprbuildCompilerExePath()
{
   if( def_gprbuild_exe_path != "" ) {
      // No guessing necessary
      return def_gprbuild_exe_path;
   }
   if (_isWindows()) {
      return 'c:\gnat\2019\bin\gprbuild.exe';
   }
   return 'gprbuild';
}
int _gprbuild_set_environment() {
    _str gprbuild_filename=_orig_path_search('gprbuild');
    if (gprbuild_filename!="") {
        //if (!quiet) {
        //   _message_box('Rust is already setup.  rustc is already in your PATH.');
        //}
        _restore_origenv(true);
        return(0);
    }

    gprbuildExePath := "";
    if( def_gprbuild_exe_path != "" ) {
       _restore_origenv(false);
       // Use def_gprbuild_exe_path
       gprbuildExePath = def_gprbuild_exe_path;
    } else {
       _restore_origenv(true);

       for (;;) {
           // Prompt user for interpreter
           int status = _mdi.textBoxDialog("gprbuild Executable",
                                           0,
                                           0,
                                           "",
                                           "OK,Cancel:_cancel\tSpecify the path and name to 'gprbuild"EXTENSION_EXE"'",  // Button List
                                           "",
                                           "-bf gprbuild Executable:":+guessgprbuildCompilerExePath());
           if( status < 0 ) {
              // Probably COMMAND_CANCELLED_RC
              return status;
           }
           if (file_exists(_param1)) {
              break;
           }
           _message_box('gprbuild executable not found. Please correct the path or cancel');
       }

       // Save the values entered and mark the configuration as modified
       def_gprbuild_exe_path = _param1;
       _config_modify_flags(CFGMODIFY_DEFVAR);
       gprbuildExePath = def_gprbuild_exe_path;
    }

    // Make sure we got a path
    if( gprbuildExePath == "" ) {
       return COMMAND_CANCELLED_RC;
    }

    // Set the environment
    //set_env('SLICKEDIT_gprbuild_EXE',gprbuildExePath);
    gprbuildDir := _strip_filename(gprbuildExePath,'N');
    _maybe_strip_filesep(gprbuildDir);
    // PATH
    _str path = _replace_envvars("%PATH%");
    _maybe_prepend(path,PATHSEP);
    path = gprbuildDir:+path;
    set("PATH="path);

    // Success
    return 0;
}
