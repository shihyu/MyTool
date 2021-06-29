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
#import "ada.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "codehelp.e"
#import "cutil.e"
#import "main.e"
#import "notifications.e"
#import "optionsxml.e"
#import "pascal.e"
#import "pushtag.e"
#import "setupext.e"
#import "slickc.e"
#import "stdprocs.e" 
#import "stdcmds.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * 6/10/2000
 * VHDL language support.
 * Thanks to Intrinsix Corporation.
 */


/*
  Options for VHDL syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").
  Insert begin/end pairs.
*/

static const VHDL_LANGUAGE_ID=        'vhd';
static const VHDL_WORD_SEP=           '([~a-zA-Z0-9_]|^|$)';
static const VHDL_IDENTIFIER=         '[a-zA-Z0-9_]';

static _str VHDLBeginEndPairs = '';

static _str _KeywordsPreceededByLabels =  'assert '              :+
                                          'block '               :+
                                          'case '                :+
                                          'exit '                :+
                                          'for '                 :+
                                          'if '                  :+
                                          'loop '                :+
                                          'next '                :+
                                          'postponed '           :+
                                          'procedure_call '      :+
                                          'process '             :+
                                          'report '              :+
                                          'return '              :+
                                          'signal_assignment '   :+
                                          'variable_assignment ' :+
                                          'wait '                :+
                                          'while ';

// sorted combination of IEEE 1076-1993 and 1076.4
static SYNTAX_EXPANSION_INFO _Keywords:[] = {
   'abs'                => { 'abs' },
   'access'             => { 'access' },
   'after'              => { 'after' },
   'alias'              => { 'alias' },
   'all'                => { 'all' },
   'allow'              => { 'allow' },
   'and'                => { 'and' },
   'append_mode'        => { 'append_mode' },
   'architecture'       => { 'architecture ... of ... is ... begin ... end architecture;' },
   'array'              => { 'array' },
   'assert'             => { 'assert' },
   'attribute'          => { 'attribute' },
   'begin'              => { 'begin ... end ;' },
   'bit'                => { 'bit' },
   'bit_vector'         => { 'bit_vector' },
   'block'              => { 'block ... begin ... end ;' },
   'body'               => { 'body' },
   'boolean'            => { 'boolean' },
   'buffer'             => { 'buffer' },
   'bus'                => { 'bus' },
   'case'               => { 'case is ... when => ... end case;' },
   'character'          => { 'character' },
   'component'          => { 'component ... is ... end component;' },
   'configuration'      => { 'configuration ... of ... is ... begin ... end configuration;' },
   'constant'           => { 'constant' },
   'delay_length'       => { 'delay_length' },
   'disconnect'         => { 'disconnect after' },
   'downto'             => { 'downto' },
   'element'            => { 'element' },
   'else'               => { 'else' },
   'elsif'              => { 'elsif ... then' },
   'end'                => { 'end' },
   'endfile'            => { 'endfile' },
   'entity'             => { 'entity ... is ... end entity;' },
   'error'              => { 'error' },
   'exit'               => { 'exit' },
   'failure'            => { 'failure' },
   'falling_edge'       => { 'falling_edge' },
   'false'              => { 'false' },
   'field'              => { 'field' },
   'file'               => { 'file' },
   'file_open_kind'     => { 'file_open_kind' },
   'file_open_status'   => { 'file_open_status' },
   'for'                => { 'for ... in ... loop ... end loop;' },
   'foreign'            => { 'foreign' },
   'fs'                 => { 'fs' },
   'function'           => { 'function' },
   'generate'           => { 'generate' },
   'generic'            => { 'generic' },
   'good'               => { 'good' },
   'group'              => { 'group' },
   'guarded'            => { 'guarded' },
   'hr'                 => { 'hr' },
   'if'                 => { 'if ... then' },
   'impure'             => { 'impure function' },
   'in'                 => { 'in' },
   'inertial'           => { 'inertial' },
   'inout'              => { 'inout' },
   'input'              => { 'input' },
   'integer'            => { 'integer' },
   'is'                 => { 'is' },
   'is_x'               => { 'is_x' },
   'justified'          => { 'justified' },
   'label'              => { 'label' },
   'left'               => { 'left' },
   'library'            => { 'library' },
   'line'               => { 'line' },
   'linkage'            => { 'linkage' },
   'literal'            => { 'literal' },
   'loop'               => { 'loop ... end loop;' },
   'map'                => { 'map' },
   'min'                => { 'min' },
   'mod'                => { 'mod' },
   'mode_error'         => { 'mode_error' },
   'ms'                 => { 'ms' },
   'name_error'         => { 'name_error' },
   'nand'               => { 'nand' },
   'natural'            => { 'natural' },
   'new'                => { 'new' },
   'next'               => { 'next' },
   'nor'                => { 'nor' },
   'not'                => { 'not' },
   'note'               => { 'note' },
   'now'                => { 'now' },
   'ns'                 => { 'ns' },
   'null'               => { 'null' },
   'of'                 => { 'of' },
   'on'                 => { 'on' },
   'open'               => { 'open' },
   'open_ok'            => { 'open_ok' },
   'or'                 => { 'or' },
   'others'             => { 'others' },
   'out'                => { 'out' },
   'output'             => { 'output' },
   'package'            => { 'package' },
   'port'               => { 'port' },
   'positive'           => { 'positive' },
   'postponed'          => { 'postponed' },
   'procedure'          => { 'procedure' },
   'process'            => { 'process ... begin ... end process;' },
   'ps'                 => { 'ps' },
   'pure'               => { 'pure function' },
   'range'              => { 'range' },
   'read'               => { 'read' },
   'read_mode'          => { 'read_mode' },
   'readline'           => { 'readline' },
   'real'               => { 'real' },
   'record'             => { 'record ... end record;' },
   'register'           => { 'register' },
   'reject'             => { 'reject' },
   'rem'                => { 'rem' },
   'report'             => { 'report' },
   'resolved'           => { 'resolved' },
   'return'             => { 'return' },
   'right'              => { 'right' },
   'rising_edge'        => { 'rising_edge' },
   'rol'                => { 'rol' },
   'ror'                => { 'ror' },
   'sec'                => { 'sec' },
   'select'             => { 'select' },
   'severity'           => { 'severity' },
   'severity_level'     => { 'severity_level' },
   'shared'             => { 'shared' },
   'side'               => { 'side' },
   'signal'             => { 'signal' },
   'sla'                => { 'sla' },
   'sll'                => { 'sll' },
   'sra'                => { 'sra' },
   'srl'                => { 'srl' },
   'status_error'       => { 'status_error' },
   'std_input'          => { 'std_input' },
   'std_logic'          => { 'std_logic' },
   'std_logic_vector'   => { 'std_logic_vector' },
   'std_output'         => { 'std_output' },
   'std_ulogic'         => { 'std_ulogic' },
   'std_ulogic_vector'  => { 'std_ulogic_vector' },
   'string'             => { 'string' },
   'subtype'            => { 'subtype' },
   'text'               => { 'text' },
   'then'               => { 'then' },
   'time'               => { 'time' },
   'to'                 => { 'to' },
   'to_bit'             => { 'to_bit' },
   'to_bitvector'       => { 'to_bitvector' },
   'to_stdlogicvector'  => { 'to_stdlogicvector' },
   'to_stdulogic'       => { 'to_stdulogic' },
   'to_stdulogicvector' => { 'to_stdulogicvector' },
   'to_ux01'            => { 'to_ux01' },
   'to_x01'             => { 'to_x01' },
   'to_x01z'            => { 'to_x01z' },
   'transport'          => { 'transport' },
   'true'               => { 'true' },
   'type'               => { 'type' },
   'unaffected'         => { 'unaffected' },
   'units'              => { 'units ... end units;' },
   'until'              => { 'until' },
   'us'                 => { 'us' },
   'use'                => { 'use' },
   'ux01'               => { 'ux01' },
   'ux01z'              => { 'ux01z' },
   'value'              => { 'value' },
   'variable'           => { 'variable' },
   'wait'               => { 'wait' },
   'warning'            => { 'warning' },
   'when'               => { 'when' },
   'while'              => { 'while loop ... end loop;' },
   'width'              => { 'width' },
   'with'               => { 'with' },
   'write'              => { 'write' },
   'write_mode'         => { 'write_mode' },
   'writeline'          => { 'writeline' },
   'x01'                => { 'x01' },
   'x01z'               => { 'x01z' },
   'xnor'               => { 'xnor' },
   'xor'                => { 'xor' },
};

// Used to automatically create consecutively numbered labels
int VHDLLabelAutoCounter;

// VHDL keys for auto function help and auto-list members
defeventtab vhd_keys;
def  ' '= vhd_space;
def  "'"= auto_codehelp_key;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  'ENTER'= vhd_enter;


definit() {
   // Used to automatically create consecutively numbered labels
   VHDLLabelAutoCounter=1;   // Set this back to 1 whenever we reload the editor
}


/**
 * <P>
 * Sets tab options, word wrap options, and mode key table
 * for current buffer.  The current buffer is extension or
 * extension given determines what mode information created
 * by the "File extension setup" menu is used.
 * </P>
 * <P>
 * If a procedure called "suffix-extension" exists, it is
 * called to set up the mode information.
 * </P>
 * <P>
 * <B>Important note:</B>
 * <BR>
 * Executing this command on a buffer causes THAT buffer
 * to be treated as if it were in VHD mode regardless of the
 * extension.
 * </P>
 *
 * @return
 */
_command vhd_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(VHDL_LANGUAGE_ID);
}


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
_str _vhd_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

static void insert_mode()
{
   if( !_insert_state() ) _insert_toggle();
}

static int significant_end(_str this_line)
{
   // 'end;' and 'end identifier' are significant, all others are not
   if( pos('end;',this_line,1) ) {
      return(1);
   }
   word1 := word2 := rest := "";
   parse this_line with '[~ \t]','r' +0 word1 ':b','r' word2 ';' rest ' |$|--','r' .;
   word1=lowcase(word1);
   word2=lowcase(word2);
   if( word1=='end' && ((word2 != 'loop') &&
                        (word2 != 'record') &&
                        (word2 != 'if')) ) {
      return(1);
   }

   return(0);
} // significant_end

static _str associated_decl()
{
   block_count := 0;
   expecting_declaration := false;
   typeless result="";

   save_pos(auto p);
   up();
   for( ;; ) {
      if( _on_line0() ) break;
      get_line(auto prev_line);

      // Looking for the word "begin" on the previous line
      if( pos('begin',prev_line,1,'i') ) {
         if( block_count==0 ) {
            break;
         } else {
            block_count++;
         }
      } else if( significant_end(prev_line) ) {
         block_count--;
         expecting_declaration=true;
      } else if( pos(VHDL_WORD_SEP'{procedure|function}'VHDL_WORD_SEP,prev_line,1,'ir') ) {
         // Found subprogram keyword
         if( expecting_declaration ) {
            // Found decl for previously encountered begin/end
            expecting_declaration=false;
         } else { // use this one
            word1 := id := rest := "";
            parse prev_line with '[ \t]@','r' word1 ':b','r' id  '([~a-zA-Z0-9_.])','r' rest;
            result=word1' 'id;   // i.e. procedure abc
            break;
         }
      }
      up();
   }
   restore_pos(p);

   return(result);
} // associated_decl

//Formal Definition
//
//A component instantiation statement defines a subcomponent of the design entity in which it appears, associates signals or values with the ports of that subcomponent, and associates values with generics of that subcomponent.
//
//label : [ component ] component_name
//
//         generic map ( generic_association_list )
//
//         port map ( port_association_list );
//
//label : entity entity_name [(architecture_identifier)]
//
//         generic map ( generic_association_list )
//
//         port map ( port_association_list );
//
//label : configuration configuration_name
//
//         generic map ( generic_association_list )
//
//         port map ( port_association_list );

static bool _vhdl_check_component_instantiation(_str kw='')
{
   result := false;
   orig_linenum := p_line;
   save_pos(auto p);
   p_col = p_col - length(kw) - 1;
   status := _clex_skip_blanks('-h');
   if (!status  && (p_line == orig_linenum)) {
      result = (get_text() == ':');
   }
   restore_pos(p);
   return result;
}

/**
 * <B>Limitations:</B>
 * <BR>
 * Does not expand postponed process or impure function.
 *
 * @return 'true' if nothing is done
 */
static _str _vhd_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;
   AutoInsertLabel := LanguageSettings.getAutoInsertLabel(p_LangId);

   aliasfilename := "";
   label := "";

   // Get a line and strip off only the trailing blanks
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');

   // Proceed only for cursor on first word
   if( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }

   // Delete all leading and trailing blanks
   VHDLword := strip(line);
   if( VHDLword=="" ) {
      // Fall through to space bar key
      return(1);
   }

   // Look for labeled statements (e.g. label_xyz : statement)
   label="";
   label_col := 0;
   _str rest=line;
   if( pos(':=',line) ) {
      // Variable assignment
      return(1);   // Fall through to space bar key
   } else if( pos('[ \t]@'VHDL_IDENTIFIER'[ \t]@\:',line,1,'er') ) {
      // Found label
      label_col=text_col(line,pos('[~ \t]',line,1,'er'),'i');
      parse strip(line) with label ':' rest;

      // Treat as a label, even if it will not be, such as in variable declarations.
      // Since we only use it where allowed, this is not a problem.
      label=strip(label);

      if( rest=="" ) {
         return(1);
      }
   }

   // Here is the word fragment (e.g. ent[ity] ) we are typing
   SampleWord  := strip(rest);
   PartialWord := lowcase(strip(rest));

   // min_abbrev2 returns the expanded word based upon this fragment
   // the function first checks the _Keywords[] array of strings. If no match
   // there, then it checks the aliasfile. If the match was found
   // in the aliasfile, then the aliasfilename is set to the OS path
   // otherwise it is set to "".
   VHDLword=min_abbrev2(PartialWord,_Keywords,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(PartialWord, VHDLword, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if( VHDLword=="" ) {
      // Fall through to space bar key
      return(1);
   }

   line=substr(line,1,length(line)-length(PartialWord)):+_word_case(VHDLword,false,SampleWord);

   width := 0;
   before := "";
   after := "";
   new_line := "";

   if( label!="" && pos(' 'VHDLword' ',_KeywordsPreceededByLabels) ) {
      width=label_col-1;
      before=expand_tabs(line,1,width,'S');
      after=expand_tabs(line,label_col+length(label),-1,'S');
      line=before:+_word_case(label,false,SampleWord):+after;
   } else {
      width=text_col(line,length(line)-length(VHDLword)+1,'i')-1;
   }
   if( width<0 ) {
      width=0;
   }

   status := 0;
   doNotify := true;
   insertBE := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   set_surround_mode_start_line();
   if( VHDLword=='assert' ) {
      // assert BooleanFalseCondition REPORT StringExpression SEVERITY NOTE|WARNING|ERROR|FAILURE;
      replace_line(line);

      _end_line();
      ++p_col;
      doNotify = (line != orig_line);
   } else if( VHDLword=='begin' ) {
      replace_line(line);
      if( insertBE ) {
         if( label!="" ) {
            // Label exists
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case(label)';');
            set_surround_mode_end_line();
            up(1);
            _end_line();
            ++p_col;   // 1 past end of line, so do not get double expansion
            insert_mode();
         } else {
            // No label
            _str unit_name=associated_decl();
            insert_line(indent_string(width)_word_case('end',false,SampleWord)' 'unit_name';');
            set_surround_mode_end_line();
            up(1);
            _end_line();
            ++p_col;   // 1 past end of line, so do not get double expansion
            insert_mode();
         }
      } else doNotify = (line != orig_line);

      _end_line();
      ++p_col;
   } else if( VHDLword=='block' ) {

      // Strip away leading and trailing spaces
      line=strip(line,'B');

      // If the loop does not have a label, then add one
      if( AutoInsertLabel && label=="" ) {
         VHDLLabelAutoCounter++;
         label='block_n'VHDLLabelAutoCounter;
         new_line=_word_case(label,false,SampleWord):+' : ':+line;
      } else {
         new_line=line;
      }
      replace_line(indent_string(width):+new_line);
      if( insertBE ) {
         insert_line(indent_string(width):+_word_case('begin',false,SampleWord));
         if( label=="" ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('block',false,SampleWord)';');
         } else {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('block',false,SampleWord)' '_word_case(label)';');
         }
         set_surround_mode_end_line();
         up(2);
         _end_line();
         ++p_col;
      } else {
         _end_line();
         ++p_col;
      }
      doNotify = (new_line != orig_line || insertBE);

      insert_mode();
   } else if( VHDLword=='case' ) {
      //   case expression is
      //      when choice_1 => sequential_statement;
      //      when others   => default_statments;
      //   end case;
      new_line=line:+'  ':+_word_case('is',false,SampleWord);
      replace_line(new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width+SyntaxIndent):+_word_case('when',false,SampleWord)' => ;');
         if( label=="" ) {
            insert_line(indent_string(width)_word_case('end',false,SampleWord)' '_word_case('case',false,SampleWord)';');
         } else {
            insert_line(indent_string(width)_word_case('end',false,SampleWord)' '_word_case('case',false,SampleWord)' '_word_case(label)';');
         }
         set_surround_mode_end_line();
         up(2);
         // text_col determines the "imaginary" column
         p_col=text_col(_rawText(new_line)) - 2;
      } else {
         ++p_col;
      }
      insert_mode();
   } else if( VHDLword=='elsif' ) {
      new_line=line'  '_word_case('then',false,SampleWord);
      replace_line(new_line);
      _end_line();
      p_col -= text_col('  then')-1;
      insert_mode();
   } else if( VHDLword=='for' ) {

      // Strip away leading and trailing spaces
      line=strip(line,'B');

      // If the for loop does not have a label, then add one
      if( AutoInsertLabel && label=="" ) {
         VHDLLabelAutoCounter++;
         label='forloop_n'VHDLLabelAutoCounter;
         new_line=_word_case(label)' : 'line'  '_word_case('in',false,SampleWord)'  '_word_case('loop',false,SampleWord);
      } else {
         new_line=line'  '_word_case('in',false,SampleWord)'  '_word_case('loop',false,SampleWord);
      }
      replace_line(indent_string(width):+new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         if( label=="" ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop;',false,SampleWord));
         } else {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop',false,SampleWord)' '_word_case(label)';');
         }
         set_surround_mode_end_line();
         up(1);
         p_col=_text_colc()-text_col('  in  loop') + 2;
      } else {
         p_col=_text_colc()-text_col('  in  loop') + 2;
      }
      insert_mode();
   } else if( VHDLword=='if' ) {
      // [label:] if (booleanexpression) then
      //   statement
      // end if;
      new_line=line'  '_word_case('then',false,SampleWord);
      replace_line(new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('if',false,SampleWord)';');
         set_surround_mode_end_line();
         up(1);
         p_col=text_col(_rawText(new_line)) - text_col(' then')+1;
      } else {
         p_col=text_col(_rawText(new_line)) - text_col(' then')+1;
      }
      insert_mode();
   } else if( VHDLword=='loop' ) {

      // Strip away leading and trailing spaces
      line=strip(line,'B');

      // If the loop does not have a label, then add one
      if( AutoInsertLabel && label=="" ) {
         VHDLLabelAutoCounter++;
         label='loop_n'VHDLLabelAutoCounter;
         new_line=_word_case(label)' : 'line;
      } else {
         new_line=line;
      }
      replace_line(indent_string(width):+new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         if( label=="" ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop;',false,SampleWord));
         } else {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop',false,SampleWord)' ':+_word_case(label)';');
         }
         set_surround_mode_end_line();
         up(1);
         _end_line();
         ++p_col;
      } else {
         _end_line();
         ++p_col;
      }
      insert_mode();
      doNotify = (new_line != orig_line || insertBE);
   } else if( VHDLword=='process' ) {

      // Strip away leading and trailing spaces
      line=strip(line,'B');

      if( AutoInsertLabel && label=="" ) {
         VHDLLabelAutoCounter++;
         label='process_n'VHDLLabelAutoCounter;
         new_line=_word_case(label)' : 'line;
      } else {
         new_line=line;
      }
      replace_line(indent_string(width):+new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width):+_word_case('begin',false,SampleWord));
         if( label=="" ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('process',false,SampleWord)';');
         } else {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('process',false,SampleWord)' '_word_case(label)';');
         }
         up(2);
         _end_line();
         ++p_col;
      } else {
         _end_line();
         ++p_col;
      }
      insert_mode();        // Goto insertion mode
      doNotify = (new_line != orig_line || insertBE);
   } else if( VHDLword=='architecture' || VHDLword=='configuration' ) {
      // Strip away leading and trailing spaces
      line=strip(line,'B');
      replace_line(indent_string(width):+line'  '_word_case('of',false,SampleWord)'  '_word_case('is',false,SampleWord));
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width):+_word_case('begin',false,SampleWord));
         insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case(VHDLword,false,SampleWord)';');
         up(2);
      }
      //insert_mode();        // Goto insertion mode
      p_col=width+length(VHDLword)+2;   // Locate the cursor after the keyword
   } else if( VHDLword=='entity' || VHDLword=='component' ) {
      // Strip away leading and trailing spaces
      if (!_vhdl_check_component_instantiation(VHDLword)) {
         line=strip(line,'B');
         replace_line(indent_string(width):+line'  '_word_case('is',false,SampleWord));
         if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case(VHDLword,false,SampleWord)';');
            up();
         }
         //insert_mode();        // Goto insertion mode
         p_col=width+length(VHDLword)+2;   // Locate the cursor after the keyword
      } else {
         status = 1;
      }
   } else if( VHDLword=='units' || VHDLword=='record' ) {
      // Strip away leading and trailing spaces
      line=strip(line,'B');
      replace_line(indent_string(width):+line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case(VHDLword,false,SampleWord)';');
         up();
      } else doNotify = line != orig_line;
      insert_mode();        // Goto insertion mode
      p_col=width+length(VHDLword)+2;   // Locate the cursor after the keyword
   } else if( VHDLword=='report' ) {
      // REPORT StringExpression SEVERITY NOTE|WARNING|ERROR|FAILURE;
      new_line=line:+' ""';
      replace_line(new_line);
      #if 0
      insert_line(indent_string(width+SyntaxIndent):+_word_case('severity')' ;');
      up(1);
      #endif
      // text_col determines the "imaginary" column
      p_col=text_col(_rawText(new_line)) - 0;
      insert_mode();
   } else if( VHDLword=='disconnect' ) {
      // DISCONNECT ... AFTER ...;
      new_line=line'  ';
      replace_line(new_line:+_word_case('after',false,SampleWord));
      // text_col determines the "imaginary" column
      p_col=text_col(_rawText(new_line));
      insert_mode();
   } else if( VHDLword=='pure' || VHDLword=='impure' ) {
      // [PURE|IMPURE] FUNCTION ...
      new_line=line' '_word_case('function',false,SampleWord);
      replace_line(new_line);
      // text_col determines the "imaginary" column
      p_col=text_col(_rawText(new_line))+2;
   } else if( VHDLword=='while' ) {

      // Strip away leading and trailing spaces
      line=strip(line,'B');

      // If the for loop does not have a label, then add one
      if( AutoInsertLabel && label=="" ) {
         VHDLLabelAutoCounter++;
         label='loop_n'VHDLLabelAutoCounter;
         new_line=_word_case(label)' : 'line'  '_word_case('loop',false,SampleWord);
      } else {
         new_line=line'  '_word_case('loop',false,SampleWord);
      }
      replace_line(indent_string(width):+new_line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         if( label=="" ) {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop',false,SampleWord)';');
         } else {
            insert_line(indent_string(width):+_word_case('end',false,SampleWord)' '_word_case('loop',false,SampleWord)' '_word_case(label)';');
         }
         set_surround_mode_end_line();
         up(1);
         p_col=_text_colc()-text_col(' loop')+1;
      } else {
         p_col=_text_colc()-text_col(' loop')+1;
      }
      insert_mode();
   } else if( _Keywords._indexin(VHDLword) &&
              _Keywords:[VHDLword].statement == VHDLword ) {
      // Word is aleady expanded, just add a space
      replace_line(line' ');
      _end_line();
      doNotify = line != orig_line;
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

int _vhd_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,_Keywords);
}

/**
 * This command is bound to the SPACEBAR key.  It looks at the text around
 * the cursor to decide whether insert an expanded template.  If it does not,
 * the root key table definition for the SPACEBAR key is called.
 *
 * @return
 */
_command vhd_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   // Short-circuit "if" operator in action here!
   if( command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)        ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is SyntaxIndent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _vhd_expand_space() ) {
      // If this was not the first space character typed, then add another space character
      if( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if( _argument=='' ) {
      _undo('S');
   }
}

// Words must be in sorted order
static _str _KeywordsWhichImmediatelyPrecedeENTERkey = 'assert '   :+
                                                       'begin '    :+
                                                       'block '    :+
                                                       'component ':+
                                                       'else '     :+
                                                       'entity '   :+
                                                       'generate ' :+
                                                       'is '       :+
                                                       'loop '     :+
                                                       'package '  :+
                                                       'then '     :+
                                                       'record '   :+
                                                       'select '   :+
                                                       'units ';

static int declarative_part()
{
   typeless result=0;   // False

   save_pos(auto p);
   typeless status=up(1); // Go up one line
   while( status==0 ) {
      get_line(auto prev_line);
      prev_first_word := prev_second_word := rest := "";
      parse prev_line with '[~ \t]','r' +0 prev_first_word ':b','r' prev_second_word '([~a-zA-Z0-9_.])','r' rest ' |$|--','r' .;
      if( prev_first_word=='architecture' ||
          prev_first_word=='component' ||
          prev_first_word=='procedure' ||
          prev_first_word=='function' ||
          prev_first_word=='configuration' ||
          prev_first_word=='block' ||
          prev_first_word=='package' ) {

         if( prev_second_word=='body' ) {
            result=0; // False
            break;
         } else {
            result=1; // True
            break;
         }
      }
      status=up();
   }
   restore_pos(p);

   return(result);
}

static void maybe_end_line() {
   if( name_on_key(ENTER)!='split-insert-line' ) {
      // Place cursor at end of this line
      _end_line();
   }
}

bool _vhd_expand_enter() 
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;

   aliasfilename := "";
   label := "";

   _str line;
   get_line_raw(line);
   _str orig_line=line;

   // Strip comments
   parse line with line '--',p_rawpos .;

   // Strip parens (e.g. 'if', 'elsif', 'assert', 'process')
   parse line with line '(',p_rawpos;

   // Look for labeled statements (e.g. label_xyz : statement )

   label="";
   label_col := 0;
   _str rest=line;
   if( pos(':=',line,1,p_rawpos) ) {
      // Variable assignment
      return(true);
   } else if( pos('[ \t]@'VHDL_IDENTIFIER'[ \t]@\:',line,1,p_rawpos'er') ) {
      // Found label
      label_col=text_col(line,pos('[~ \t]',line,1,p_rawpos'er'),'i');
      parse strip(line) with label ':',p_rawpos rest;

      // Treat as a label, even if it will not be, such as in variable declarations.
      // Since we only use it where allowed, this is not a problem.
      label=strip(label);

      if( rest=="" ) {
         // Only a label on this line, nothing else.
         // This is a line containing only a label and colon, statement
         // follows on next line the next line is indented SyntaxIndent
         // characters relative to the first column of the label.
         indent_on_enter(SyntaxIndent);
         return(false);
      }
   }

   _str last_word=strip_last_word(rest);

   if( text_col(orig_line)>p_col ) {
      // You are NOT at the end of the line, instead, you entered an ENTER key
      // at current column inside of the line in order to split this line into
      // two lines. No need to go further.
      return(true);
   }

   // Find the column position of the first non-space character = pos('[~ \t]',line,1,'r')
   // then get the imaginary column of this virtual column
   // for example, for tabs is vitual column 4, but if tabs are 4 spaces, then
   // the imaginary column is actually 16.
   int width=text_col(line,pos('[~ \t]',line,1,p_rawpos'er'),'i') - 1;
   if( width<0 ) {
      width=0;
   }

   if( pos(last_word,_KeywordsWhichImmediatelyPrecedeENTERkey,1,p_rawpos'i') ) {
      replace_line_raw(orig_line);
      maybe_end_line();
      indent_on_enter(SyntaxIndent);
      return(false);
   } else {
      // Normal enter key
      return(true);
   }
}

/**
 * This command is bound to the ENTER key.  It looks at the text around the
 * cursor to decide whether to indent another level.  If it does not, the
 * root key table definition for the ENTER key is called.
 *
 * @return
 */
_command void vhd_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   generic_enter_handler(_vhd_expand_enter);
} // vhd_enter()
bool _vhd_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _vhd_supports_insert_begin_end_immediately() {
   return true;
}

/*
 * ===========================================================================
 * VHDL Error Parsing
 * ===========================================================================
 *
 * How to build error parsing support for your favorite simulator
 * 
 * See comment at the top of error.e
 * 
 */

_str _no_filename_index;

//
// Model Technology VCOM 4.6f (Jan 1997)
// -- Loading package standard
// -- Loading package std_logic_1164
// -- Loading package std_logic_arith
// ERROR: Could not open library gencomps at gencomps: No such file or directory
//
// ERROR: P:\dmiou\vhdl\dmiou.fix(5): Library gencomps not found.
// ###### C:\mwi\ctl\mc68450\src\dmach.vhd(978): cseq_state(1) <= DNLOAD;
// ERROR: C:\mwi\ctl\mc68450\src\dmach.vhd(978): Incompatible types for assignment.
// ** Error: D:\Projects\SandBox\Processors\ML403Tests\Cores\MyProcessorIPLib\pcores\opb_test_connect_v1_00_a\hdl\vhdl\core_logic.vhd(1145): near ")": syntax error
//
static const ModelTechErr_VHDL= '[* ]*Error\: {#0:p}\({#1:i}\)\: {#3?@}';

//
// Error: Line 23: File c:\sundar_stuff\dec_conc.vhd: Type error: type in constant declaration must be "std_logic_vector"
// Error: +:   type is
// Error: +:   integer literal: any integer type
// Error: Line 24: File c:\sundar_stuff\dec_conc.vhd: Type error: type in constant declaration must be "std_logic_vector"
// Error: +:   type is
// Error: +:   integer literal: any integer type
// Info: Information on Architecture ISA_DEC-SYNTHESIS was not stored
//
static const AlteraErr_VHDL= 'Error\: Line {#1:i}\: File {#0:p}\: {#3?@}';

// Note: Parsing Issue: Filename is NOT on the same line as the error.
//
//     VHDL Compiler, Release 5.200
//     Copyright (c) 1994, Vantage Analysis Systems, Inc.
//     Compiler invocation:   analyze -src dec_conc.vhd -dbg 2 -libfile vsslib.ini
//     Working library MYLIB "/home/projects/test/user.lib".
//     --
//     Compiling "dec_conc.vhd" line 1...
//     Compiled entity MYLIB.ISA_DEC
//     --
//     Compiling "dec_conc.vhd" line 18...
// **Error: LINE 23 *** The type required in this context does not match that of this expression.   (compiler/analyzer/3)
//
// **Error: LINE 23 *** No legal integer type for integer literal >>0<<.   (compiler/analyzer/3)
//
// **Error: LINE 27 *** No legal integer type for integer literal >>4<<.   (compiler/analyzer/3)
//
//     --
//     1/2 design unit(s) compiled successfully.
//     Syntax summary: 10 error(s), 0 warning(s) found.
//
static const VantageErrLine1_VHDL= '?*[ \t]+(Compiling)[ \t]{#0:q}';
static const VantageErrLine2_VHDL= '\*\*Error\: LINE {#1:i}{#0} \*\*\* {#3?@}';

//
// $ Start of Compile
// #Wed Feb 18 11:25:18 1998
//
// Synplify VHDL Compiler, version 3.0b, built Dec 17 1997
// Copyright (C) 1994-1997, Synplicity Inc.  All Rights Reserved
//
// VHDL syntax check successful!
// Synthesizing work.isa_dec.synthesis
// @E:"c:\book\ch3\dec_conc.vhd":23:60:23:68|Expression does not match type std_logic_vector
// @E:"c:\book\ch3\dec_conc.vhd":23:60:23:68|Width mismatch, location has width 17, value 32
// @END
//
static const SynplifyErr_VHDL= '\@E\:\"{#0:p}\"\:{#1:i}\::i\::i\::i\|{#3?@}';

//static const ErrParseLine1_VHDL= '^'VantageErrLine1_VHDL;
static const ErrParseLine2_VHDL= '^('ModelTechErr_VHDL')|('VantageErrLine2_VHDL')|('AlteraErr_VHDL')';

static void get_filename_onprevline(_str &filename)
{
   filename="";

   get_line(auto line);
   if( !pos('^'VantageErrLine2_VHDL,line,1,'ri') ) {
      return;
   }

   save_pos(auto p);

   // Do a [r]egular expession, case [i]nsensitive, backward[-] search
   status := search('^'VantageErrLine1_VHDL,'@rhi-');

   if( !status ) {
      filename=get_text(match_length('0'),match_length('S0'));
   }

   restore_pos(p);

   return;
}

bool _get_error_info_vhdl(_str &filename,_str &linenum, _str &col, _str &err_msg)
{
   get_line(auto line);
   if( !pos(ErrParseLine2_VHDL,line,1,'ri')) {
      return(false);
   }
   found_filename := substr(line,pos('S0'),pos('0'));
   found_linenum := substr(line,pos('S1'),pos('1'));
   found_col := substr(line,pos('S2'),pos('2'));
   found_err_msg := substr(line,pos('S3'),pos('3'));

   if( found_filename=="" ) {
      get_filename_onprevline(found_filename);
      if( found_filename=="" ) {
         return(false);
      }
   }
   filename=found_filename;
   linenum=found_linenum;
   col=found_col;
   err_msg=found_err_msg;

   return(true);
}

/*
 * ===========================================================================
 * VHDL Context Tagging(R) callbacks
 * ===========================================================================
 */

// generate variable / symbol declaration
_str _vhd_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return _pas_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

int _vhd_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex,'vhd','vhdl',"VHDL Builtins", "", false, withRefs, useThread, forceRebuild);
}

int _vhd_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                            VS_TAG_RETURN_TYPE &rt,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _pas_get_type_of_prefix(errorArgs,prefixexp,rt,visited,depth);
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
int _vhd_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _pas_get_expression_info(PossibleOperator,idexp_info,visited,depth);
}
int _vhd_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _pas_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                 info_flags,otherinfo,find_parents,max_matches,
                                 exact_match,case_sensitive,
                                 filter_flags,context_flags,
                                 visited,depth,prefix_rt);
}
int _vhd_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return _pas_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth);
}
int _vhd_fcthelp_get(_str (&errorArgs)[],
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
/**
 * @see _ada_find_matching_word
 */
int _vhd_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   return _ada_find_matching_word(quiet,pmatch_max_diff_ksize,pmatch_max_level);
}

