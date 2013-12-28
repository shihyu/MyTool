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
#endregion

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

#define ADA_LANGUAGE_ID 'ada'
#define ADA_MODE_NAME   'Ada'

defeventtab ada_keys;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;
def "'"=auto_codehelp_key;
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
_str _ada_keyword_case(_str s, boolean confirm = true)
{
   return _word_case(s, confirm);
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
_command void ada_enter () name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_ada_expand_enter);
}

/* This command is bound to the SPACE BAR key.  It looks at the text around */
/* the cursor to decide whether insert an expanded template.  If it does not, */
/* the root key table definition for the SPACE BAR key is called. */
_command void ada_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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
#define ADA_ENTER_WORDS (' accept begin case else elsif if loop procedure record':+\
                   ' select while ')
#define ADA_EXPAND_WORDS (' abort abstract accept access aliased array begin case constant declare delay ':+\
                   ' delta digits else elsif entry exception exit for function generic if limited ':+\
                   ' loop others package pragma private procedure protected raise range record ':+\
                   ' renames requeue return reverse select separate subtype tagged task terminate ':+\
                   ' type until when while with ')
#define ADA_DECL_WORDS ' type declare '
#define ADA_NAMED_END ' accept function package procedure task '
#define ADA_LABEL_WORDS ' declare begin loop while for '
#define RESERVED_WORDS (' abort abs abstract accept access aliased all and array at begin body case constant declare delay':+\
                     ' delta digits do else elsif end entry exception exit for function generic goto if in is limited':+\
                     ' loop mod new not null of or others out package pragma private procedure protected raise range record':+\
                     ' rem renames requeue return reverse select separate subtype tagged task terminate':+\
                     ' then type until use when while with xor ')


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
boolean _ada_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   
   status := false;
   _str line='';
   get_line(line);
   int width=(pos('[~ \t]',line,1,'r')-1);

   /* strip comments and get the first word */
   parse line with line '--' .;

   // Check for a label.  Two cases: a label by itself on
   // a line, or a label on the same line as expanded text.
   _str temp_label='', remainder='', label_remainder='';
   _str word='', func_name='', first_word='', rest='';
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
         } else { // treat in the usual way, for such things as 'protected T( X : Integer ) is'
            //messagenwait("seeing nonlabeled laine")
            parse line with '[~ \t]','r' +0 word ':b','r' func_name '[ (]','r' rest ' |$|--','r' .;
            first_word=lowcase(word);
         }
      }
   } else { // no colon on this line so treat in the original way
      parse line with '[~ \t]','r' +0 word ':b','r' func_name '[ (]','r' rest ' |$|--','r' .;
      first_word=lowcase(word);
   }

   //messageNwait('first_word='first_word'  func_name='func_name'  rest='rest);
   _str next_line='', before='';
   int file_status=0;
   int j=0;
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
            insert_line(indent_string(width)_word_case('end ')rest';');
            up(2);
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width+syntax_indent));
            up();
         } else {
            //message("eof but not a package body")
            maybe_end_line();
            indent_on_enter(syntax_indent);
         }
      } else {
         //message("not at eof")
         up(); // since went down to check for eof
         maybe_end_line();
         indent_on_enter(syntax_indent);
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
         insert_line(indent_string(width)_word_case('private'));
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
         insert_line(indent_string(width)_word_case('private'));
         down();  // to the 'end;'
         get_line(next_line);
         replace_line(substr(next_line,1,length(next_line)-1)' 'func_name';');
         up(2);
      }
      maybe_end_line();
      indent_on_enter(syntax_indent);
   } else if ( first_word=='task' ) {
      if ( lowcase(func_name)=='body' ) {
         insert_line(indent_string(width):+_word_case('begin'));
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
   } else if ( pos(' 'first_word' ',ADA_ENTER_WORDS,1) ) {
      orig_col := p_col;
      _end_line();
      _clex_skip_blanks('-');
      at_end := (orig_col >= p_col);
      p_col = orig_col;
      if ( at_end ) {
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
   _str orig_line='';
   get_line(orig_line);
   _str line=strip(orig_line,'T');

   /* procede only for cursor on first word */
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str word=strip(line);
   _str aliasfilename='';
   if ( word=='') {
      return(1);    /* Fall through to space bar key. */
   }

   _str label='';
   _str orig_word='';
   typeless mult_line_info;
   int col=0;
   _str line_prefix='';
   _str label_line='';
   int colon_pos=0;
   _str temp_label='', remainder='';
   int width=0;
   if ( pos(':',line,1) == 0 ) { // no colon on this line
      orig_word=lowcase(strip(line));
      word=min_abbrev2(orig_word,ada_space_words,name_info(p_index),aliasfilename);

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
      line=substr(line,1,length(line)-length(orig_word)):+_word_case(word);
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
      orig_word=lowcase(strip(remainder));
      word=min_abbrev2(orig_word,ada_space_words,name_info(p_index),aliasfilename);

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
      line=substr(line,1,length(line)-length(orig_word)):+_word_case(word);
      width=text_col(line,pos(label,line),'i');
   }

   // Insert the appropriate template based on the reserved word
   set_surround_mode_start_line();
   doNotify := true;
   status := 0;
   _str new_line='';
   if ( word=='accept' ) {
      replace_line(line:+' ':+_word_case(' do'));
      insert_line(indent_string(width)_word_case('end;'));
      set_surround_mode_end_line();
      up();
      p_col=p_col+3;
      insert_mode();
   } else if ( word=='if' ) {
      replace_line(line:+' ':+_word_case(' then'));
      insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('if;'));
      set_surround_mode_end_line();
      up();
      p_col=width+4;
      insert_mode();
   } else if ( word=='for' ) {
      // expand it here since it must be a statement
      if (!in_entry_statement() && !in_declarative_part()) {
         new_line=line:+' ':+_word_case(' in '):+' ':+_word_case('loop');
         replace_line(new_line);
         insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('loop'):+label';');
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
         insert_line(indent_string(width)_word_case('end'):+label';');
         set_surround_mode_end_line();
         up();
         _end_line();
         insert_mode();
      } else {
         _str unit_name=associated_decl();
         if (unit_name != '') {
            // two people have asked for this, I give in...
            replace_line(line' -- 'unit_name);
            insert_line(indent_string(width)_word_case('end')' 'unit_name';');
            up();
            insert_line(indent_string(width+syntax_indent));
            insert_mode();
         } else {
            insert_line(indent_string(width+syntax_indent));
            insert_line(indent_string(width)_word_case('end')';');
            set_surround_mode_end_line();
            up();
            _end_line();
            insert_mode();
         }
      }
   } else if ( word=='task' ) {
      replace_line(line:+_word_case('  is'));
      insert_line(indent_string(width)_word_case('end;'));
      up();
      p_col=width+length(word)+2;
      insert_mode();
   } else if ( word=='protected' ) {
      replace_line(line:+_word_case('  is'));
      insert_line(indent_string(width)_word_case('end;'));
      up();
      p_col=width+length(word)+2;
      insert_mode();
   } else if ( word=='while' ) {
      new_line=line:+_word_case('  loop');
      replace_line(new_line);
      insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('loop'):+label';');
      set_surround_mode_end_line();
      up();
      p_col=length(new_line)-4;
      insert_mode();
   } else if ( word=='record' || word=='select' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('end '):+_word_case(word';'));
      up();
      insert_line(indent_string(width+syntax_indent));
      insert_mode();
   } else if ( word=='case' ) {
      replace_line(line:+_word_case('  is'));
      insert_line(indent_string(width)_word_case('end'):+' ':+_word_case('case;'));
      set_surround_mode_end_line();
      up();p_col=width+6;
      insert_mode();
   } else if ( word=='exception' ) {
      replace_line(_word_case(line):+' ');
      insert_line(indent_string(width+syntax_indent)_word_case('when =>'));
      p_col=width+syntax_indent+6;
      insert_mode();
   } else if ( word=='entry' ) {
      if ( !in_declarative_part() ) { //entry declaration
         return(1);
      } else { //entry body
         replace_line(line:+'  '_word_case('when')'  '_word_case('is'));
         insert_line(indent_string(width):+_word_case('begin'));
         insert_line(indent_string(width):+_word_case('end;'));
         set_surround_mode_end_line();
         up(2);
         p_col=width+length(word)+2;
      }
      insert_mode();
   } else if ( word=='loop' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('end'):+' ':+_word_case('loop'):+label';');
      up();
      insert_line(indent_string(width+syntax_indent));
      set_surround_mode_end_line(p_line+1);
      insert_mode();
   } else if ( word=='elsif' ) {
      replace_line(line:+' ':+_word_case(' then'));
      p_col=width+7;
   } else if ( word=='declare' ) {
      replace_line(line);
      insert_line(indent_string(width):+_word_case('begin'));
      insert_line(indent_string(width):+_word_case('end'):+label';');
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

static boolean in_entry_statement()
{
   save_pos(auto p);
   _first_non_blank_col();
   int orig_col=p_col;
   while (up()==0) {
      _first_non_blank_col();
      if (p_col > orig_col) {
         break;
      }
      orig_col = p_col;
      _str prev_line='';
      get_line(prev_line);
      _str prev_first_word='';
      _str prev_second_word='';
      _str rest='';
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

static boolean in_declarative_part()
{
   save_pos(auto p);
   while (up()==0) {
      _str prev_line='';
      get_line(prev_line);
      _str prev_first_word='';
      _str prev_second_word='';
      _str rest='';
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

#define ADA_WORD_SEP_CHARS '([~a-zA-Z0-9_]|^|$)'
#define ADA_IDENTIFIER_CHARS '[a-zA-Z0-9_]'


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
   _str next_line='';
   get_line(next_line);
   _str word1='';
   _str word2='';
   _str rest='';
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
   _str word1='';
   _str word2='';
   _str rest='';
   parse this_line with '[~ \t]','r' +0 word1 ':b','r' word2 ';' rest ' |$|--','r' . ;
   if ( word1=='end' && (word2 != 'loop' && word2 != 'record' && word2 != 'if')  ) {
      return(1);
   }
   return(0);
} // significant_end

static _str associated_decl()
{
   int block_count=0;
   int expecting_declaration=0;
   _str result='';
   int up_count=0;
   _str prev_line='';
   _str word1='';
   _str id='';
   _str rest='';

   int status=up();
   while (status==0) {
      up_count=up_count+1;
      get_line(prev_line);
      if ( pos('begin',prev_line,1,'i') ) {
         //messagenwait("encountered 'begin' with block_count "block_count)
         if (block_count == 0) {
           break;
         } else {
            block_count=block_count+1;
         }
      } else if ( significant_end(prev_line) ) {
         //messagenwait( "encountered significant 'end'")
         block_count=block_count-1;
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
               break;
            } // block_count check
         } // instantiation check
      } // if word of interest
      status=up();
   } // loop
   down(up_count);
   return(result);
} // associated_decl

defload()
{
   _str setup_info='MN='ADA_MODE_NAME',TABS=+3,MA=1 74 1,':+
                   'KEYTAB=ada-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',';
   _str compile_info='';
   _str syntax_info='3 1 1 1 0 1 0';
   _str be_info='(begin)|(end)';
   _CreateLanguage(ADA_LANGUAGE_ID, ADA_MODE_NAME, 
                   setup_info, compile_info, syntax_info, be_info,
                   '', 'A-Za-z0-9_', ADA_MODE_NAME);
   _CreateExtension('ada', ADA_LANGUAGE_ID);
   _CreateExtension('adb', ADA_LANGUAGE_ID);
   _CreateExtension('ads', ADA_LANGUAGE_ID);
}

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
   int view_id=0;
   if ( arg(2)!='' ) {    /* swicth to new view if needed */
      get_window_id(view_id);
      activate_window(arg(2));
   }
   typeless p=point();
   typeless ln=point('L');
   int cl=p_col;
   int left_edge=p_left_edge;
   int cursor_y=p_cursor_y;
   search('^compiling ','@rhi-');
   if ( rc ) {
      filename='';
   } else {
      _str cur_line='';
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
int _ada_get_expression_info(boolean PossibleOperator, 
                             VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_idexp_info_init(idexp_info);
   return _pas_get_expression_info(PossibleOperator, idexp_info, visited, depth);
}
int _ada_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           boolean find_parents,int max_matches,
                           boolean exact_match,boolean case_sensitive,
                           int filter_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _pas_find_context_tags(errorArgs, prefixexp, 
                                 lastid, lastidstart_offset,
                                 info_flags, otherinfo, 
                                 find_parents, max_matches,
                                 exact_match, case_sensitive,
                                 filter_flags, context_flags,
                                 visited, depth);
}
int _ada_fcthelp_get_start(_str (&errorArgs)[],
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   return _pas_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags);
}
int _ada_fcthelp_get(_str (&errorArgs)[],
                     VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                     boolean &FunctionHelp_list_changed,
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

int _ada_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   _str ext='ada';
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,ext)) {
      return(0);
   }

   // the user does not have an extension specific tag file for Ada
   int status=0;
   _str dcc_binary='';
#if !__UNIX__
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            "SOFTWARE\\Free Software Foundation",
                            "GNAT", dcc_binary);
   if (!status) {
      dcc_binary = dcc_binary :+ "\\bin\\adagide.exe";
   }
#endif
   if (dcc_binary=='') {
      dcc_binary=path_search("adagide","","P");
   }
   _str std_libs="";
   if (dcc_binary!="") {
      _str path=_strip_filename(dcc_binary,"n");
      if (last_char(path)==FILESEP) {
         path=substr(path,1,length(path)-1);
      }
      _str name=_strip_filename(path,"p");
      if (file_eq(name,"bin")) {
         path=_strip_filename(path,"n");
      }
      if (last_char(path)!=FILESEP) {
         path=path:+FILESEP;
      }
      _str source_path=file_match(maybe_quote_filename(path:+"lib"), 1);
      if (source_path!='') {
         path=path:+"lib":+FILESEP;
      }
      std_libs=maybe_quote_filename(path:+"*.ads"):+' ':+maybe_quote_filename(path:+"*.adb");
      //say("_ada_MaybeBuildTagFile: path="path" std_libs="std_libs);
   }

   // got the path, now build and save the tag file
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Ada Compiler Libraries",
                           true,std_libs,ext_builtins_path(ext,ext));
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
int _ada_find_matching_word(boolean quiet)
{
   // Get current word at cursor:
   typeless orig_position;
   save_pos(orig_position);
   boolean isKeyword = (_clex_find(0,'g') == CFG_KEYWORD);
   if (!isKeyword && p_col>0) {
      left();
      isKeyword = (_clex_find(0,'g') == CFG_KEYWORD);
      restore_pos(orig_position);
   }
   int start_col=0;
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
   _str direction="";
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
static int matchWord(_str word, _str direction, boolean quiet)
{
   // match in specified direction
   int iterations = 0;
   int level = 0;
   int status = 0;

   // extended support for VHDL syntax
   _str vhdl_regex = "";
   _str vhdl_words = "";
   if (_LanguageInheritsFrom('vhd')) {
      vhdl_words = " process architecture component entity ";
      vhdl_regex = "|process|architecture|component|entity";
   }

   // should we be expecting a 'begin' keyword?
   word_chars := _clex_identifier_chars();
   long begin_pos[];
   begin_pos._makeempty();
   begin_pos[0]=-1;
   boolean expecting_begin[];
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
      int start_col=0;
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
         if (last_char(strip(line))==';') {
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

         _str tag_type = "";
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
         int orig_col = p_col;
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
