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
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "cutil.e"
#import "markfilt.e"
#import "msqbas.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for VBScript syntax expansion/indenting may be accessed from
  SLICK's file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             Keyword case.  Values may be 0,1, or 2 which correspond
                     to lower case, upper case, and capitalized.  Default
                     is 0.
       3             reserved
       4             Amount to indent for first level of code.  Default is 3.
                     Specify 0 if you want first level statements to
                     start in column 1.
       5             reserved.
*/

static const VBS_LANGUAGE_ID= 'vbs';
static const VBS_WORD_CHARS=  'a-zA-Z0-9_$!%#&';

defeventtab vbscript_keys;
def  ' '= vbscript_space;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  'ENTER'= vbscript_enter;

_str _vbs_keyword_case(_str s, bool confirm=true, _str sample="")
{
   updateAdaptiveFormattingSettings(AFF_KEYWORD_CASING, confirm);
   if( p_keyword_casing == WORDCASE_CAPITALIZE ) {

      // these are special cases for capitalization
      if (lowcase(s)=='redim') return 'ReDim';
      if (lowcase(s)=='executeglobal') return 'ExecuteGlobal';
   }

   return _word_case(s, confirm, sample);
}

/* This command forces the current buffer to be in VBScript mode. */
/* Unfortunately, this command only changes the mode-name, tab options, */
/* word wrap options, and mode key table. */
/* Not necessary for syntax expansion and indenting. */
_command vbscript_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   /* The SELECT_EDIT_MODE procedure can find the file extension setup */
   /* data by passing it the 'vbs' extension. */
   _SetEditorLanguage(VBS_LANGUAGE_ID);
}

/* This command is bound to the ENTER key.  It looks at the text around the */
/* cursor to decide whether to indent another level.  If it does not, the */
/* root key table definition for the ENTER key is called. */
_command void vbscript_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_vbs_expand_enter);
}
bool _vbs_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

/* This command is bound to the SPACE BAR key.  It looks at the text around */
/* the cursor to decide whether insert an expanded template.  If it does not, */
/* the root key table definition for the SPACE BAR key is called. */
_command vbscript_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
       _in_comment() ||
       vbscript_expand_space() ) {
      if( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if( _argument=="" ) {
      _undo('S');
   }
   if (_haveContextTagging())
       vbscript_codehelp_key();
}

/* These constant strings have been defined to make the syntax
 expansion and indenting more data driven and to speed up
 determining whether special processing must be performed. There
 must be a space before and after each key word. */
static const VBS_EXPAND_WORDS= (' call class const dim do erase execute executeglobal exit for function':+\
   ' if on option private property public randomize redim rem select set':+\
   ' stop sub while with' );

static SYNTAX_EXPANSION_INFO vbs_space_words:[] = {
   'call'            => { "call" },
   'class'           => { "class ... end class" },
   'const'           => { "const" },
   'dim'             => { "dim" },
   'do'              => { "do ... loop" },
   'erase'           => { "erase" },
   'execute'         => { "execute" },
   'executeglobal'   => { "executeglobal" },
   'exit'            => { "exit" },
   'for'             => { "for ... next" },
   'function'        => { "function ... end function" },
   'if'              => { "if ... then ... end if" },
   'on'              => { "on" },
   'option'          => { "option" },
   'private'         => { "private" },
   'property'        => { "property ... end property" },
   'public'          => { "public" },
   'randomize'       => { "randomize" },
   'redim'           => { "redim" },
   'rem'             => { "rem" },
   'select'          => { "select case ... end select" },
   'set'             => { "set" },
   'stop'            => { "stop" },
   'sub'             => { "sub ... end sub" },
   'while'           => { "while ... wend" },
   'with'            => { "with ... end with" },
};

static const ENTER_WORDS= ' case do for if select type while ';
static const FIRST_WORDS=  ' class function private public sub ';

static _str vbscript_expand_space()
{
   /* Put first word of line in lower case into word variable. */
   _str orig_line;
   get_line(orig_line);
   _str line = orig_line;
   _str first,second,third,fourth;
   parse lowcase(line) with first second third fourth;

   line=strip(line,'T');
   sample := strip(line);
   orig_word := lowcase(strip(line));
   if( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,vbs_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   /* Insert the appropriate template based on the key word. */
   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   int i;
   _str second_word,third_word;

   doNotify := true;
   if( word=='class' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('class',false,sample),true);
      if( endInserted ) {
         up();up();_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( word=='do' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('Loop',false,sample),true);
      if( endInserted ) {
         up();up();_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( word=='for' ) {

      // We are implementing for to include both 'for' and 'for each'.  
      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('next',false,sample),true);
      if( endInserted ) {
         up();up();_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( word=='function' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('function',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( ((first=='public' || first=='default' || first=='private') && second=='function') ||
               (first=='public') && (second=='default') && (third=='function')) {

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('function',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = endInserted;
   } else if( word=='if' ) {

      replace_line(_vbs_keyword_case(line,false,sample):+"  ":+_vbs_keyword_case('then',false,sample));
      if( maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('end',false,sample):+" ":+_vbs_keyword_case('if',false,sample)) ) {
         up();p_col=width+4;
      } else {
         p_col=width+4;
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

   } else if( word=='property' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('property',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( (first=='public' || first=='default' || first=='private') &&
              (second=='property') ) {

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('property',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }

      doNotify = endInserted;
   } else if( (first=='public') && (second=='default') && (third=='property') ) {

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('property',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = endInserted;
   } else if( word=='select' ) {

      replace_line(_vbs_keyword_case(line,false,sample)' '_vbs_keyword_case('case',false,sample));
      if( maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('select',false,sample)) ) {
         up();_end_line();right();
      } else {
         _end_line();right();
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

   } else if( word=='sub' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('sub',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( ((first=='public' || first=='default' || first=='private') && second=='sub') || 
              ((first=='public') && (second=='default') && (third=='sub')) ) {

      endInserted := maybe_insert_end_clause(indent_string(width):+_vbs_keyword_case('end',false,sample)' '_vbs_keyword_case('sub',false,sample));
      if( endInserted ) {
         up(1);_end_line();right();
      } else {
         _end_line();right();
      }

      doNotify = endInserted;
   } else if( word=='while' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('wend',false,sample));
      if( endInserted ) {
         up();p_col=width+7;
      } else {
         p_col=width+7;
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( word=='with' ) {

      newLine := _vbs_keyword_case(line,false,sample);
      replace_line(newLine);

      endInserted := maybe_insert_end_clause(indent_string(width)_vbs_keyword_case('end',false,sample):+' ':+_vbs_keyword_case('with',false,sample));
      if( endInserted ) {
         up();p_col=width+=6;
      } else {
         p_col=width+=6;
      }
      if( ! _insert_state() ) {
         _insert_toggle();
      }

      doNotify = (endInserted || newLine != orig_line);
   } else if( pos(' 'word' ',VBS_EXPAND_WORDS) ) {

      // Two special cases where the expanded words have a capital letter
      // within the word.  Word_case, when passed in true, will leave the word
      // alone if the setting is to capitalize first letter, and will indent it properly.
      _str finalword;
      if( word=='executeglobal' ) {
         finalword = _vbs_keyword_case('ExecuteGlobal',false,sample);
      } else if( word=='redim' ) {
         finalword = _vbs_keyword_case('ReDim',false,sample);
      } else
         finalword = _vbs_keyword_case(word,false,sample);

      newLine := indent_string(width)finalword' ';
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != orig_line);
   } else {

      // not a recognized syntax expansion statement
      if( ! _insert_state() ) {
         _insert_toggle();
      }
      return(1);

   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if( ! _insert_state() ) {
      _insert_toggle();
   }
   return(0);
}

int _vbs_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, vbs_space_words, prefix, min_abbrev);
}

static bool maybe_insert_end_clause(_str line, bool insert_blank_line=false)
{
   if( line=="" ) {
      insert_line(line);
      return true;
   }
   _str endclause = line;
   int startcol = pos('[~ \t]',expand_tabs(line),1,'er');
   if( startcol>1 ) {
      endclause=strip(substr(expand_tabs(line),startcol),'T');
   }
   _str end_re = endclause;
   if( startcol>1 ) {
      // Look for an indented clause
      end_re='^[ \t]#'end_re;
   }
   save_pos(auto p);
   found_endclause := false;
   while( !down() ) {
      if( _expand_tabsc()=="" ) {
         // Blank line
         continue;
      }
      if( pos(end_re,_expand_tabsc(),1,'ir') ) {
         int col = pos('[~ \t]',_expand_tabsc(),1,'er');
         if( col==startcol ) {
            found_endclause=true;
         }
      }
      // If we got here, then we found a non-blank line, so we are
      // done.
      break;
   }
   restore_pos(p);
   if( !found_endclause ) {
      // Did not find the end clause, so insert it
      if( insert_blank_line ) {
         insert_line("");
      }
      insert_line(line);
      set_surround_mode_end_line();
      return true;
   }

   // If we got here, then we found an already-existing end clause
   return false;
}

/* Returns non-zero number if fall through to enter key required */
bool _vbs_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   first_indent := LanguageSettings.getIndentFirstLevel(p_LangId);

   status := false;
   /* Put last word of line into last_word variable. */
   _str line;
   get_line(line);
   _str last_word,word,rest;
   parse lowcase(line) with 'begin' +0 last_word;
   
   /* Is last word begin key word or first word one of indent on enter */
   /* key words?. */
   get_line(line);

   non_blank_col := p_col;
   non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
   past_non_blank := (p_col>non_blank_col || name_on_key(ENTER)=='nosplit-insert-line');

   parse lowcase(line) with 'begin' +0 last_word;
   parse line with '[~ \t]','r' +0 word '[ \t]','r' rest;
   /* Put first word of line into first_word variable. */
   _str sample=word;
   first_word := lowcase(word);
   if( first_word=='for' && name_on_key(ENTER)=='nosplit-insert-line' ) {
      /* tab to fields of qbasic for statement */
      line=expand_tabs(line);
      _str before;
      parse lowcase(line) with before '=';
      if( length(before)+1>=p_col ) {
         p_col=_rawLength(before)+3;
      } else {
         parse lowcase(line) with before 'to';
         if( length(before)>=p_col ) {
            p_col=_rawLength(before)+4;
         } else {
            indent_on_enter(syntax_indent);
         }
      }
   } else if( first_word=='select' ) {
      // Get the line after the indent and check to see if we actually moved
      // part of a line.  If we did not, do the replace line with the case
      indent_on_enter(0);
      new_line := "";
      get_line(new_line);
      if ( rest=="" && new_line=="" ) {
         replace_line(indent_string(p_col-1)_vbs_keyword_case('case ',false,sample));
         _end_line();

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
   } else if( pos(' 'first_word' ',ENTER_WORDS,1,'i') ) {
      newLine := substr(line,1,pos(word,line)-1)_vbs_keyword_case(first_word,false,sample) " "rest;
      replace_line(newLine);
      int indent = past_non_blank?syntax_indent:0;
      indent_on_enter(indent);

      // notify user that we did something unexpected
      if (newLine != line) notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   } else if( pos(' 'first_word' ',FIRST_WORDS,1,'i') ) {
      int indent = past_non_blank?first_indent:0;
      indent_on_enter(indent);
   } else {
      status=true;
   }
   return(status);
}

int vbs_proc_search(_str &proc_name,int find_first, _str ext="",
                    int start_seekpos=0, int end_seekpos=0)
{
   search_type := "";
   mark_opt := "";
   if( end_seekpos >= _QROffset() && select_active() ) {
      mark_opt='M';
   }
   // now search
   status := 0;
   if( find_first ) {
      modifiers := '(((overrides|mustoverride|public|private|protected)[ \t]#)*)';
      keywords := "sub|function|property|const|attribute|class|namespace|imports";
      letget := "[lg]et";
      if( proc_name:=="" ) {
         variable_re := '([A-Za-z][.'VBS_WORD_CHARS']@)';
         signature_re := '[ \t]*([(]{#1[^)]*}[)_][ \t]*|)(as[ \t]*{#2'variable_re'}|=|$)';
         //status=search('^[ \t]@({#0:i}|{#0'variable_re'}\:|'modifiers'('keywords')[ \t]#('letget'[ \t]#|){#0'variable_re'}('signature_re'|$))','r@i');
         status=search('^[ \t]@({#0'variable_re'}\:|'modifiers'('keywords')[ \t]#('letget'[ \t]#|){#0'variable_re'}('signature_re'|$))','rh@i'mark_opt);
      } else {
         tag_decompose_tag_browse_info(proc_name, auto cm);
         search_type = cm.type_name;
         proc_name = cm.member_name;
         proc_name_re := stranslate(proc_name,'\$','$');
         proc_name_re=stranslate(proc_name_re,'\#','#');
         if( isinteger(proc_name) ) {
            status=search('^[ \t]@\c{#0'proc_name'}([~'VBS_WORD_CHARS']|$)','rh@i'mark_opt);
         } else {
            status=search('^[ \t]@(\c{#0'proc_name_re'}\:|'modifiers'('keywords')[ \t]*('letget'[ \t]#|)\c{#0'proc_name_re'}([~'VBS_WORD_CHARS']|$))','rh@i'mark_opt);
         }
      }
   } else {
      status=repeat_search();
   }
   for( ;; ) {
      if( status ) {
         break;
      }
      sm := match_length('S');
      s0 := match_length('S0');
      l0 := match_length('0');
      curline := get_text(s0-sm,sm);
      tag_flags := SE_TAG_FLAG_NULL;
      if ( pos("private",curline,1,'iw') ) {
         tag_flags = SE_TAG_FLAG_STATIC;
      }
      if ( pos("protected",curline,1,'iw') ) {
         tag_flags = SE_TAG_FLAG_PROTECTED;
      }
      type_name := "";
      if ( pos("sub",curline,1,'iw') ) {
         type_name = 'proc';
      } else if( pos('function', curline, 1, 'iw') ) {
         type_name = 'func';
      } else if( pos('property', curline, 1, 'iw') ) {
         if( pos('get',curline,1,'iw') ) {
            type_name = 'func';
            tag_flags |= SE_TAG_FLAG_CONST;
         } else if( pos('let',curline,1,'iw') ) {
            type_name = 'proc';
         } else {
            type_name = 'prop';
         }
      } else if( pos('const', curline, 1, 'iw') ) {
         type_name = 'const';
      } else if( pos('namespace', curline, 1, 'iw') ) {
         type_name = 'package';
      } else if( pos('imports', curline, 1, 'iw') ) {
         type_name = 'import';
      } else if( pos('class', curline, 1, 'iw') ) {
         type_name = 'class';
      } else if( pos('dim', curline, 1, 'iw') ) {
         type_name = 'gvar';
      } else if( pos('attribute', curline, 1, 'iw') ) {
         type_name = 'const';
      } else if( curline=="" ) {
         type_name = 'label';
      }
      name := get_text(l0,s0);
      if( pos(' 'lowcase(name)' ',' else ') ) {
         status=repeat_search();
         continue;
      }
      _str arguments=null;
      _str return_type=null;
      if( tag_tree_type_is_func(type_name) ) {
         arguments=get_match_text(1);
         return_type=get_match_text(2);
         // in case if argument list is continued, parse the rest
         get_line(auto cur_line);
         cur_line=strip(cur_line);
         while( _last_char(cur_line)=='_' ) {
            //say("vbs_proc_search: cur_line="cur_line" args="arguments);
            if( down() ) break;
            get_line(cur_line);
            cur_line=strip(cur_line);
            if( _last_char(cur_line)=='_' ) {
               arguments :+= ' 'substr(cur_line,1,length(cur_line)-1);
            } else if( lastpos(')',cur_line) ) {
               arguments :+= ' 'substr(cur_line,1,pos('s')-1);
               return_type=strip(substr(cur_line,pos('s')+1));
               if( pos('as[ \t]#',return_type,1,'ri') ) {
                  return_type=substr(return_type,pos("")+1);
               }
               break;
            } else {
               break;
            }
         }
      }
      if ( proc_name:=="" ) {
         tag_init_tag_browse_info(auto tcm, name, "", type_name, tag_flags, "", 0, 0, arguments, return_type);
         taginfo := tag_compose_tag_browse_info(tcm);
         break;
      }
      if( proc_name==name && (search_type=="" || search_type==type_name) ) {
         break;
      }
      status=repeat_search();
   }
   return(status);
}

int _vbs_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex,'vbs','vbscript',"VBScript Builtins", "", false, withRefs, useThread, forceRebuild);
}



/*
 GENERAL NOTES:
    1) Context Tagging&reg; hook functions are documented as
       "Hook Function" -- _<ext>_<function_name>, where
       <ext> is lowcase(p_LangId) for your language.

    2) other useful utility functions that you might want
       to construct for your implementation of context
       tagging are also documented here (all are static).

    3) parts that we recommend that you costomize for your
       language application are marked with ##SKELETON##
*/


//########################################################################
//////////////////////////////////////////////////////////////////////////
// GLOBAL VARIABLES
//

/*
 cache name and seek position of last function
 we got function help on (for performance)
*/
static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;

static const VBS_COMMON_END_OF_STATEMENT_RE= 'if|while|select|for|case|public|private|class|do|else|set|get|let|redim|property|option|on|exit';
static const VBS_NOT_FUNCTION_WORDS=  ' do for if while for call class dim end erase error exit goto on stop set let get select case with while return resume redim public private ';

/*
 needed for tokenizer for SKT language
 see vbs_next_sym() and vbs_prev_sym() below
*/
static _str gtkinfo;
static _str gtk;


//########################################################################
//////////////////////////////////////////////////////////////////////////
// HOOK FUNCTIONS and UTILITY FUNCTIONS
//

/**
 * Useful utility function for getting the next token, symbol, or
 * identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string)
 *
 * @return next token or ''
 */
static _str vbs_next_sym()
{
   // TBF
   // ch=get_text();
   // gtk=gtkinfo=ch;
   // return(gtk);


   _str ch;
   status := 0;
   start_col := 0;
   start_line := 0;
   if( p_col>_text_colc() ) {
      //if(down()) {
      gtk=gtkinfo="";
      return("");
      //}
      //_begin_line();
   }
   ch=get_text();
   if( _clex_find(0,'g')==CFG_COMMENT ) {
      gtk=gtkinfo="";
      return("");
   }
   if( ch=="" ) {
      status=_clex_skip_blanks();
      if( status ) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(vbs_next_sym());
   }
   if( (ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING ) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if( status ) {
         _end_line();
      } else if( p_col==1 ) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if( pos('['word_chars']',ch,1,'r') ) {
      start_col=p_col;
      if( _clex_find(0,'g')==CFG_NUMBER ) {
         for( ;; ) {
            if( p_col>_text_colc() ) break;
            right();
            if( _clex_find(0,'g')!=CFG_NUMBER ) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   // right();
   //if (ch=='-' && get_text()=='>') {
   //   right();
   //   gtk=gtkinfo='->';
   //   return(gtk);
   //
   //}
   //if (ch==':' && get_text()==':') {
   //   right();
   //   gtk=gtkinfo='::';
   //   return(gtk);
   //}

   gtk=gtkinfo=ch;

   // Have to increment the column becuase we did not move when we got ch,
   // otherwise, we'll return the right token, but _vbs_fcthelp_get_start
   // will get stuck here.
   right();
   return(gtk);

}

/**
 * Useful utility function for getting the next token on the
 * same line, or '' if the next token is on a different line.
 *
 * @return
 *    next token or '' if no next token on current line
 */
static _str vbs_next_sym_same_line()
{
   orig_linenum := p_line;
   _str result=vbs_next_sym();
   if( p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum+1) ) {
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}

/**
 * Useful utility function for getting the previous token on the
 * same line, or '' if the previous token is on a different line.
 *
 * @return
 *    previous token or '' if no previous token on current line
 */
static _str vbs_prev_sym_same_line()
{
   orig_linenum := p_line;
   _str result=vbs_prev_sym();
   if( p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}

/**
 * Useful utility function for getting the previous token, symbol,
 * or identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string).
 *
 * @return previous token or ''
 */
static _str vbs_prev_sym()
{
   //##SKELETON## -- implement [ext]_prev_sym, it will make it easier
   //                to write the get_expression_info and fcthelp hook functions.

   ch := get_text();
   status := 0;

   if( ch=="\n" || ch=="\r" || ch=="" || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT) ) {
      status=_clex_skip_blanks('-');
      if( status ) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(vbs_prev_sym());
   }
   if( ch=="\n" || ch=="\r" ) {
      gtk=gtkinfo="";
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if( pos('['word_chars']',ch,1,'r') ) {
      int end_col=p_col+1;
      if( _clex_find(0,'g')==CFG_NUMBER ) {
         for( ;; ) {
            if( p_col==1 ) break;
            left();
            if( _clex_find(0,'g')!=CFG_NUMBER ) {
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
      if( p_col==1 ) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if( p_col==1 ) {
      up();_end_line();
      if( _on_line0() ) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();

   if( ch=='=' && pos(get_text(),'=+!%^*&|/><') ) {
      gtk=gtkinfo=get_text()'=';
      left();
      return(gtk);
   }
   if( ch==':' && get_text()==':' ) {
      left();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
/**
 * Utility function for parsing part of prefix expression before a
 * dot (member access operator), called starting from _vbs_get_expression_info
 * or vbs_before_id, etc.  Basic plan is to parse code backwards
 * from the cursor location until you reach a stopping point.
 *
 * @param prefixexp              (reference), prefix expression to prepend
 *                               new parts of expression onto
 * @param prefixexpstart_offset  (reference) start of prefix expression
 * @param lastid                 (reference, unused)
 *
 * @return
 * <LI>0  -- finished
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int vbs_before_dot(_str &prefixexp,
                          int &prefixexpstart_offset,
                          _str &lastid)
{

   status := 0;
   outer_loop:
   for( ;; ) {
      prefixexpstart_offset=(int)point('s')+1;


      switch( gtk ) {
      case ')':
         nest_level := 0;
         count := 0;
         for( count=0;;++count ) {
            if( count>200 ) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if( gtk:=="" ) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if( gtk==']' ) {
               prefixexp='[]':+prefixexp;
               right();
               status=find_matching_paren(true);
               if( status ) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               left();
            } else {
               if( gtk==TK_ID ) {
                  prefixexp=gtkinfo' ':+prefixexp;
               } else {
                  prefixexp=gtkinfo:+prefixexp;
               }
            }
            prefixexpstart_offset=(int)point('s')+1;
            if( gtk=='(' ) {
               --nest_level;
               if( nest_level<=0 ) {
                  gtk=vbs_prev_sym_same_line();
                  if( gtk!=TK_ID ) {

                     if( gtk==']' ) {
                        continue outer_loop;
                     }
                     if( gtk==')' ) {
                        continue;
                     }
                     if( gtk=="" ) {
                        return(0);
                     }
                     return(0);
                  }
                  prefixexp=gtkinfo:+prefixexp;
                  prefixexpstart_offset=(int)point('s')+1;
                  gtk=vbs_prev_sym_same_line();
                  return(2);// Tell call to continue processing
               }
            } else if( gtk==')' ) {
               ++nest_level;
            }
            gtk=vbs_prev_sym();
         }
         break;
      default:
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
   return(VSCODEHELPRC_CONTEXT_NOT_VALID);
}


/**
 * Utility function for parsing part of prefix expression before
 * an identifier, called starting from _vbs_get_expression_info
 * or vbs_before_dot, etc.  Basic plan is to parse code backwards
 * from the cursor location until you reach a stopping point.
 *
 * @param prefixexp              (reference), prefix expression to prepend new
 * @param prefixexpstart_offset               parts of expression onto
 * @param lastid                 (reference, unused)
 * @param info_flags             (reference) VSCODEHELPFLAG_* bitset
 * @param otherinfo              (reference) auxilliary info
 *
 * @return
 * <LI>0  -- finished
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int vbs_before_id(_str &prefixexp,int &prefixexpstart_offset,
                         _str &lastid,int &info_flags,typeless &otherinfo)
{
   status := 0;
   for( ;; ) {
      switch( gtk ) {
      case '.':
         status=vbs_before_dot(prefixexp,prefixexpstart_offset,lastid);
         prefixexp=gtkinfo:+prefixexp;
         prefixexpstart_offset=(int)point('s')+1;
         gtk=vbs_prev_sym_same_line();

         if( gtk!=TK_ID ) {
            status=vbs_before_dot(prefixexp,prefixexpstart_offset,lastid);
            if( status!=2 ) {
               return(status);
            }
         } else {
            prefixexp=gtkinfo:+prefixexp;
            prefixexpstart_offset=(int)point('s')+1;
            gtk=vbs_prev_sym_same_line();
         }
         break;

      case TK_ID:
         if( strieq(gtkinfo,'new') ) {
            gtk=vbs_prev_sym_same_line();
            prefixexp='new ':+prefixexp;
            prefixexpstart_offset=(int)point('s')+1;
            gtk=vbs_prev_sym_same_line();
            if( gtk!='.' ) {
               return(0);
            }
            continue;
         } else if( strieq(gtkinfo,'goto') ) {
            info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;

         } else if( strieq(gtkinfo,'raiseevent') ) {
            info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
         }
         return(0);

      default:
         return(0);
      }
   }
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get_start
 * <P>
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.  This determines
 * quickly whether or not we are in the context of a function call.
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
 *    0    Successful<BR>
 *    VSCODEHELPRC_CONTEXT_NOT_VALID<BR>
 *    VSCODEHELPRC_NOT_IN_ARGUMENT_LIST<BR>
 *    VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 */
int _vbs_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   if (_chdebug) {
      isay(depth, "_vbs_fcthelp_get_start: ****************************");
   }
   errorArgs._makeempty();
   flags=0;
   junk := 0;
   word := "";
   typeless p1,p2,p3,p4;
   _str ch;
   status := 0;
   int orig_pos,p;
   save_pos(orig_pos);
   int orig_seek=(int)point('s');
   first_less_than_seek := 0;
   if (!ginFunctionHelp && cursorInsideArgumentList) {
      status=search('[;}{()]','-rh@xcs');
      if (!status) {
         ch=get_text();
      }
      restore_pos(orig_pos);
   }

   orig_col := p_col;
   orig_line := p_line;
   status=search('[;}{()]','-rh@xcs');
   if (!status && p_line==orig_line && p_col==orig_col) {
      status=repeat_search();
   }
   ArgumentStartOffset= -1;
   word_chars := _clex_identifier_chars();
   for (;;) {
      if (status) {
         break;
      }
      ch=get_text();
      if (ch=='(') {
         save_pos(p);
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         ch=get_text();
         word=cur_word(junk);
         restore_pos(p);
         if (pos('['word_chars']',ch,1,'r')) {
            if (pos(' 'word' ',VBS_NOT_FUNCTION_WORDS)) {
               if (OperatorTyped && ArgumentStartOffset== -1) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               break;
            }
            ArgumentStartOffset=(int)point('s')+1;
         } else {
            /*
               OperatorTyped==TRUE
                   Avoid give help when have
                   myproc(....4+( <CursorHere>

            */
            if (OperatorTyped && ArgumentStartOffset== -1 &&
                ch!=')' &&   // (*pfn)(a,b,c)  OR  f(x)(a,b,c)
                ch!=']'      // calltab[a](a,b,c)
               ) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (ch==')' || ch==']') {
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
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         save_search(p1,p2,p3,p4);
         _clex_skip_blanks('-');
         restore_search(p1,p2,p3,p4);
         word=cur_word(junk);
         if (pos(' 'lowcase(word)' ',' if while select for with call function ')) {
            break;
         }
         restore_pos(p);
      } else {
         break;
      }
      orig_line=p_line;
      status=repeat_search();
      if (!status && p_line<orig_line) {
         break;
      }
   }

   // VBScript allows function argument lists to start with ' '
   // when not part of an expression or assignment.
   // The following are identical:
   //
   //   Debug.write("string")
   //   Debug.write "string"
   //
   // The argument list MUST start on the same line. We do not currently
   // support argument lists on continued lines (using _) with an argument
   // list that is not enclosed in parens. For example, the following is
   // not supported:
   //
   //   Debug.write _
   //     "string"

   if( ArgumentStartOffset<0 ) {
      // Handle the following cases:
      //
      // Foo <-- argument list
      // Foo.Bar <-- argument list
      // Foo("arguments").Bar <-- argument list

      save_pos(p);
      restore_pos(orig_pos);
      _begin_line();

      ch=vbs_next_sym_same_line();
      while( ch!="" ) {
         if( ch=='(' ) {
            status=find_matching_paren(true);
            if( status ) {
               // Lost!
               restore_pos(orig_pos);
               return(1);
            }
            // Skip the )
            right();
            ch=vbs_next_sym_same_line();
            continue;
         }
         if( ch=='.' ) {
            right();
            ch=vbs_next_sym_same_line();
            if( gtk!=TK_ID ) {
               continue;
            }
         }
         if( gtk==TK_ID ) {
            int after_id_offset = (int)point('s');
            ch=vbs_next_sym_same_line();
            if( ch!='(' && ch!='.' ) {
               goto_point(after_id_offset);
               if( get_text()!="" ) {
                  // Lost!
                  restore_pos(orig_pos);
                  return(1);
               }
               ArgumentStartOffset=after_id_offset+1;
               break;
            }
            continue;
         }
         ch=vbs_next_sym_same_line();
      }
      if( ArgumentStartOffset<0 ) {
         restore_pos(p);
      }
   }

   if (ArgumentStartOffset>=0) {
      goto_point(ArgumentStartOffset);
   } else {
      ArgumentStartOffset=(int)point('s');
   }
   left();
   left();
   status=search('[~ \t]|^','-rh@');
   lastid := "";
   if (pos('[~'word_chars']',get_text(),1,'r')) {
      ch=get_text();
      if (ch==')' || ch==']') {
         FunctionNameOffset=ArgumentStartOffset-1;
         return(0);
      } else {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      int end_col=p_col+1;
      search('[~'word_chars']\c|^\c','-rh@');
      lastid=_expand_tabsc(p_col,end_col-p_col);
      FunctionNameOffset=(int)point('s');
   }
   if (pos(' 'lastid' ',VBS_NOT_FUNCTION_WORDS)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   return(0);
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get
 * <P>
 * Context Tagging&reg; hook function for retrieving the information
 * about each function possibly matching the current function call
 * that function help has been requested on.
 * <P>
 * If there is no help for the first function, a non-zero value
 * is returned and message is usually displayed.
 * <P>
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 * <P>
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <PRE>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type='';
 * </PRE>
 *
 * @param errorArgs                    (reference) error message arguments
 *                                     refer to codehelp.e VSCODEHELPRC_*
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
 * @param FunctionNameStartOffset      Offset to start of function name.
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
int _vbs_fcthelp_get(_str (&errorArgs)[],
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
   //say('_vbs_fcthelp_get: *************************');
   //say('_vbs_fcthelp_get: FunctionNameStartOffset='FunctionNameStartOffset);

   errorArgs._makeempty();
   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;

   FunctionHelp_list_changed=false;
   if (FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }

   common := '[,#{};()]|'VBS_COMMON_END_OF_STATEMENT_RE;
   int cursor_offset=(int)point('s');
   junk := 0;
   _str ch,word;
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   orig_line := p_line;
   goto_point(FunctionNameStartOffset);

   // We are no longer in a VBScript function call after the user moves
   // to the next line (i.e. hits ENTER).
   //
   // Note: We do not currently support VBScript continued lines (using _).
   // For example:
   //
   // MsgBox("prompt", _
   //   0, "title")
   if( p_line!=orig_line ) {
      restore_pos(p);
      return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
   }

   preprocessing_top := 0;
   int preprocessing_ParamNum_stack[];
   int preprocessing_offset_stack[];
   int ParamNum_stack[];
   int offset_stack[];  // offset of this function open parenthesis
   stack_top := 0;
   ParamNum_stack[stack_top]=0;
   nesting := 0;
   status := 0;

   // VBScript allows function argument lists to start with ' '
   // when not part of an expression or assignment.
   // The following are identical:
   //
   //   Debug.write("string")
   //   Debug.write "string"
   //
   // The argument list MUST start on the same line. We do not currently
   // support argument lists on continued lines (using _) with an argument
   // list that is not enclosed in parens. For example, the following is
   // not supported:
   //
   //   Debug.write _
   //     "string"

   // Skip to char just after the function name
   word_chars := _clex_identifier_chars();
   word=cur_word(junk);
   p_col += length(word);
   ch=get_text();
   if( ch==' ' || ch=='\t' ) {
      int space_offset = (int)point('s');
      // Skip to first non-blank on same line
      ch="";
      int p2;
      save_pos(p2);
      orig_line = p_line;
      status=search('[~ \t]','rh@');
      if( !status ) {
         if( p_line!=orig_line ) {
            restore_pos(p2);
         } else {
            ch=get_text();
         }
      }
      if( ch!='(' ) {
         // This function's argument list is started with ' ', so
         // prime the parameter stack.
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=space_offset;
         //messageNwait('_vbs_fcthelp_get: offset='offset_stack[stack_top]);
      } else {
         // Start over
         restore_pos(p);
         goto_point(FunctionNameStartOffset);
      }
   } else {
      // Start over
      restore_pos(p);
      goto_point(FunctionNameStartOffset);
   }

   status=search(common,'rh@xcs');
   for (;;) {
      if (status) {
         break;
      }

      ch=get_text();
      //say('cursor_offset='cursor_offset' p='point('s'));
      if (cursor_offset<=point('s')) {
         break;
      }
      if (ch==',') {
         ++ParamNum_stack[stack_top];
         status=repeat_search();
         continue;
      }
      if (ch==')') {
         --stack_top;
         if (stack_top<=0) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         status=repeat_search();
         continue;
      }
      if (ch=='(') {
         // Determine if this is a new function
         ++stack_top;
         ParamNum_stack[stack_top]=1;
         offset_stack[stack_top]=(int)point('s');
         status=repeat_search();
         continue;
      }
      if (ch=='[') {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(p);
            return(VSCODEHELPRC_BRACKETS_MISMATCH);
         }
         status=repeat_search();
         continue;
      }
      if (ch=='}' || ch==';') {
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      if (ch=='#' || ch=='{' || (pos('[~'word_chars']',get_text(1,match_length('s')-1),1,'r') &&
                                 pos('[~'word_chars']',get_text(1,match_length('s')+match_length()),1,'r'))
         ) {
         // IF this could be enum, struct, or class
         if (stack_top>1 && (ch=='e' || ch=='s' || ch=='c')) {
            word=cur_word(junk);
            if (word=='enum' || word=='struct' || word=='class' || word=='typedef') {
               status=repeat_search();
               continue;
            }
         }
         // IF we need to check for conditional preprocessing
         if (ch=='#' && stack_top>0) {
            right();
            word=lowcase(cur_word(junk));
            if (word=='if' || word=='ifdef' || word=='ifndef') {
               // IF we are in conditional preprocessing.
               ++preprocessing_top;
               preprocessing_ParamNum_stack[preprocessing_top]=ParamNum_stack[stack_top];
               preprocessing_offset_stack[preprocessing_top]=offset_stack[stack_top];
               status=repeat_search();
               continue;
            } else if (word=='elif' || word=='else') {
               if (preprocessing_top && stack_top>0 &&
                   preprocessing_offset_stack[preprocessing_top]==offset_stack[stack_top]
                   ) {
                  ParamNum_stack[stack_top]=preprocessing_ParamNum_stack[preprocessing_top];
                  status=repeat_search();
                  continue;
               }

            } else if (word=='endif') {
               if (preprocessing_top) {
                  --preprocessing_top;
               }
               status=repeat_search();
               continue;
            } else if (word!='const' && word!='undef' && word!='include') {
               status=repeat_search();
               continue;
            }
         }
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      status=repeat_search();
   }

   _UpdateContextAndTokens(true);
   _UpdateLocals(true);
   typeless tag_files = tags_filenamea(p_LangId);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(offset_stack[stack_top]+1);

      status=_vbs_get_expression_info(true,idexp_info,visited,depth+1);
      idexp_info.errorArgs[1] = idexp_info.lastid;
      //say('prefixexp='prefixexp' lastid='lastid' lastidstart_col='lastidstart_col' info_flags='dec2hex(info_flags)' otherinfo='otherinfo' status='status);

      // We are not able to look up types of prefixes yet for VBScript, so clear this or else
      // we will get no function help.
      idexp_info.prefixexp="";

      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ParamNum_stack[stack_top];
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
         //say('lastid='lastid' prefixexp='prefixexp' ParamNum='ParamNum' otherinfo='otherinfo);
         globals_only := false;
         _str match_list[];
         _str match_symbol = idexp_info.lastid;
         match_class := "";
         match_flags := SE_TAG_FILTER_ANY_PROCEDURE;
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);

         // find symbols matching the given class
         num_matches := 0;
         tag_clear_matches();
         // this may be a variable MYCLASS a(
         if (idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL) {
            idexp_info.otherinfo    = stranslate(idexp_info.otherinfo,':','::');
            tag_split_class_name(idexp_info.otherinfo, match_symbol, match_class);
            cmatch_class := tag_join_class_name(match_symbol, match_class, tag_files, false, false, false, visited, depth+1);
            tag_clear_matches();
            _UpdateLocals(true);
            tag_list_in_class(match_symbol, cmatch_class, 0, 0, tag_files,
                              num_matches, def_tag_max_function_help_protos,
                              SE_TAG_FILTER_ANY_PROCEDURE,
                              SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS,
                              true, false, null, null, visited, depth+1);
            if (num_matches <= 0) {
               match_symbol = idexp_info.lastid;
            }
         }

         // analyse prefix epxression to determine effective class
         if (num_matches == 0) {
            if (pos('new ',idexp_info.prefixexp) == 1) {
               // handle 'new' expressions as a special case
               outer_class := substr(idexp_info.prefixexp, 5);
               _maybe_strip(outer_class, '::');
               _maybe_strip(outer_class, '.');
               outer_class = stranslate(outer_class, ':', '::');
               if (outer_class=="") {
                  //match_class = _QualifySymbolName(match_symbol, "", p_buf_name, true);
                  tag_qualify_symbol_name(rt.return_type,match_symbol,"",p_buf_name,tag_files,false,visited,depth+1);
               } else {
                  rt.return_type = tag_join_class_name(match_symbol, outer_class, tag_files, false, false, false, visited, depth+1);
               }
               rt.pointer_count = 1;
               status = 0;
            } else if (idexp_info.prefixexp != "") {
               status = _vbs_get_type_of_prefix(idexp_info.errorArgs, idexp_info.prefixexp, rt, visited, depth+1);
               if (status && (status!=VSCODEHELPRC_BUILTIN_TYPE || idexp_info.lastid!="")) {
                  restore_pos(p);
                  continue;
               }
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
                  globals_only = true;
               }
               //say("_vbs_fcthelp_get: match_symbol="match_symbol" prefix="prefixexp"=");
               if (pos('new ',idexp_info.prefixexp)==1) {
                  if (match_symbol=="" && rt.return_type!="") {
                     colon_pos := lastpos('[:/]',rt.return_type,1,'r');
                     if (colon_pos) {
                        match_symbol=substr(rt.return_type,colon_pos+1);
                     } else {
                        match_symbol=rt.return_type;
                     }
                  } else {
                     rt.return_type=match_symbol;
                  }
               }
               //say("_vbs_fcthelp_get: XXX match_class="match_class" match_symbol="match_symbol);
            }
            context_flags := globals_only? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
            tag_clear_matches();
            // try to find 'lastid' as a member of the 'match_class'
            // within the current context
            if (idexp_info.lastid!="" || match_symbol!="") {
               tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                           0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, false, 
                                           visited, depth+1, 
                                           rt.template_args);
               if (num_matches==0 && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                              0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, false, 
                                              visited, depth+1, 
                                              rt.template_args);
               }
            }
            if (idexp_info.lastid == "" && rt.taginfo != "") {
               tag_get_info_from_return_type(rt, auto rt_cm);
               tr := rt.return_type;
               parse tr with tr '[' .;
               tag_clear_matches();
               tag_insert_match_info(rt_cm);
               num_matches = 1;
               if (rt.return_type!="" && !pos('(',tr)) {
                  _str orig_return_type=rt.return_type;
                  status = _vbs_get_return_type_of(errorArgs,tag_files,'()',rt.return_type,
                                                   0,SE_TAG_FILTER_ANY_PROCEDURE,
                                                   false,rt,visited);
                  if (!status) {
                     tag_get_info_from_return_type(rt, rt_cm);
                     tag_clear_matches();
                     tag_insert_match_info(rt_cm);
                     num_matches++;
                  }
               }
            }
         } else {
            idexp_info.lastid = match_symbol;
         }


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
               if (cm.type_name :== 'define') {
                  if (cm.arguments == "") {
                     continue;
                  }
               }
            }
            proc_name := cm.member_name;
            if (cm.class_name != "") {
               proc_name = cm.class_name '.' proc_name;
            }
            if (tag_tree_type_is_func(cm.type_name)) {
               if (cm.arguments == 'void') {
                  cm.arguments = "";
               }
            } else if (cm.type_name :== 'define') {
               cm.return_type = '#Const';
            }
            cm.type_name='proc';
            match_list[match_list._length()] = proc_name "\t" cm.type_name "\t" cm.arguments "\t" cm.return_type"\t"j"\t"duplicate_indexes[i];
         }

         // get rid of any duplicate entries
         match_list._sort();
         //_aremove_duplicates(match_list, false);

         // translate functions into struct needed by function help
         have_matching_params := false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            for (i=0; i<match_list._length(); i++) {
               k := FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               parse match_list[i] with auto match_tag_name "\t" auto match_type_name "\t" auto signature "\t" auto return_type "\t" auto imatch "\t" auto duplist;
               tag_get_match_browse_info((int)imatch, auto cm);
               as_return_type := (return_type=="")? "":' As ':+return_type;
               prototype := match_tag_name'('signature')':+as_return_type;
               tag_autocode_arg_info_from_browse_info(FunctionHelp_list[k], cm, prototype, rt);
               base_length := length(match_tag_name) + 1;
               FunctionHelp_list[k].argstart[0]=1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               foreach (auto z in duplist) {
                  if (z == imatch) continue;
                  tag_get_match_browse_info((int)z,cm);
                  tag_autocode_arg_info_add_browse_info_to_tag_list(FunctionHelp_list[k], cm, rt);
               }

               // parse signature and map out argument ranges
               j := arg_pos := 0;
               _str argument = cb_next_arg(signature, arg_pos, 1);
               while (argument != "") {
                  // allow for variable length argument lists
                  if (!pos(',',substr(signature,arg_pos))) {
                     if (argument=='...' ||
                         (pos('[',argument)) ||
                         (substr(argument,1,7):=='params ') ||
                         (lowcase(substr(argument,1,9)):=='optional ')
                        ) {
                        while (j < ParamNum-1) {
                           j = FunctionHelp_list[k].argstart._length();
                           FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                           FunctionHelp_list[k].arglength[j]=0;
                        }
                     }
                  }
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_pos;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  _str param_name,param_type,pvarname;
                  if (j == ParamNum) {
                     if (pos("^["word_chars"]*([=]?*|)$",argument,1,'r')) {
                        parse argument with argument '=' auto init_to;
                        param_name=argument;
                        param_type=argument;
                        if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                           FunctionHelp_list[k].ParamType=argument;
                        }
                        FunctionHelp_list[k].ParamName=argument;
                     } else {
                        // parse out the return type of the current parameter
                        pslang := p_LangId;
                        utf8 := p_UTF8;
                        psindex := find_index(pslang'_proc_search',PROC_TYPE);
                        int temp_view_id;
                        int orig_view_id=_create_temp_view(temp_view_id);
                        p_UTF8=utf8;
                        _insert_text(argument';');
                        top();
                        pvarname="";
                        if (index_callable(psindex)) {
                           status=call_index(pvarname,1,pslang,psindex);
                        } else {
                           _SetEditorLanguage(pslang,false);
                           status=_VirtualProcSearch(pvarname);
                        }
                        if (status) {
                           // major hack, try again with a faked out argument name
                           top();
                           _delete_text(p_RBufSize);
                           _insert_text('Dim a As 'argument);
                           top();
                           if (index_callable(psindex)) {
                              status=call_index(pvarname,1,pslang,psindex);
                           } else {
                              status=_VirtualProcSearch(pvarname);
                           }
                           if (substr(pvarname,1,2)!='a(') {
                              status=STRING_NOT_FOUND_RC;
                           }
                        }
                        if (!status) {
                           tag_decompose_tag_browse_info(pvarname, auto param_cm);
                           if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                              FunctionHelp_list[k].ParamType=cm.return_type;
                           }
                           FunctionHelp_list[k].ParamName=cm.member_name;
                           param_name = cm.member_name;
                           param_type = cm.return_type;
                        }
                        _delete_temp_view(temp_view_id);
                        p_window_id = orig_view_id;
                     }
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
int _vbs_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //Clean up the Error Arguments
   idexp_info.errorArgs._makeempty();
   idexp_info.otherinfo="";

   int orig_info_flags=idexp_info.info_flags;

   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;

   done := false;
   _str ch;
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();

   // check color coding for comment or string
   cfg := 0;
   if (PossibleOperator) {

      left();cfg=_clex_find(0,'g');right();

   } else {
      cfg=_clex_find(0,'g');
   }

   if (cfg==CFG_COMMENT) {

      return(VSCODEHELPRC_CONTEXT_NOT_VALID);

   } else if (cfg==CFG_STRING || cfg==CFG_NUMBER) {

      int orig_cfg=cfg;

      left();cfg=_clex_find(0,'g');
      ch=get_text(); right();

      // If we are doing auto list members, we need to tell
      // SlickEdit how big the string or number is so it knows
      // what to replace if a parameter is selected
      // We set lastid to the string or number and
      // lastid_start, lastid_startoffset, and prefixexpstart_offset

      if (orig_info_flags & VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS) {

         if (cfg==CFG_STRING || cfg==CFG_NUMBER ||
             !pos('['word_chars'.>:]',ch,1,'r')) {

            int clex_flag=(cfg==CFG_STRING)? STRING_CLEXFLAG:NUMBER_CLEXFLAG;

            // Look backward for first character that is not string or number
            int clex_status=_clex_find(clex_flag,'n-');

            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            // Look ahead to next string or number
            clex_status=_clex_find(clex_flag,'o');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            start_col := p_col;
            int start_offset=(int)point('s');
            clex_status=_clex_find(clex_flag,'n');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            clex_status=_clex_find(clex_flag,gtk);
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp="";
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col+1);

            restore_pos(orig_pos);
            return(0);
         }
      } else if (cfg==orig_cfg || cfg==CFG_COMMENT) {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }

   // An operator has been typed
   if (PossibleOperator) {
      left();
      ch=get_text();
      switch (ch) {
      case '>':
      case '.':
         orig_col := p_col;
         if (ch=='.') {
            // foo.bar, foo is not a constructor or destructor, even if name matches
            idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
            // Screen out floating point.  1.0
            if (isdigit(get_text(1,(int)point('s')-1))) {
               // Check if identifier before . is a number

               save_pos(auto p2);
               left();

               search('[~'word_chars']\c|^\c','-rh@');

               if (isdigit(get_text())) {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }

               restore_pos(p2);

            }
            _str line;get_line(line);
            right();

            // Get the id after the dot
            // if we are on a id character

            if (pos('['word_chars']',get_text(),1,'r')) {
               start_col := p_col;
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
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            p_col=orig_col;
            break;

         }
      case ' ':
         // Foo |<-- ' ' starts off the argument list for Foo
      case '(':
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         idexp_info.lastidstart_col=p_col;
         left();
         // IF languages has preprocessing
         search('[~ \t]|^','-rh@');

         if (pos('[~'word_chars']',get_text(),1,'r')) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         int end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if (pos(' 'idexp_info.lastid' ',VBS_NOT_FUNCTION_WORDS)) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      default:
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      // IF we are not on an id character.
      ch=get_text();
      done=false;

      if (pos('[~'word_chars']',ch,1,'r')) {
         // not an ID character
         left();
         ch=get_text();
         if (ch=='.') {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            done=true;
         }
      }
      if (!done) {

         // IF we are not on an id character.
         if (pos('[~'word_chars']',get_text(),1,'r')) {

            restore_pos(orig_pos);
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;

            gtk=vbs_prev_sym_same_line();
            if (gtk==TK_ID) {
               idexp_info.prefixexp=lowcase(gtkinfo)' ';
               switch (lowcase(gtkinfo)) {
               case 'goto':
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_GOTO_STATEMENT;
                  break;
               default:
                  idexp_info.prefixexp="";
                  break;
               }
            }
            restore_pos(orig_pos);
            return(0);
         }
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col := p_col;
         // Check if this is a function call
         //search('[~ \t]|$','r@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=='(') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         // check if this is NOT a function call
         if (pos(get_text(),'*&.:,{[<') || get_text(2)=='::' || get_text(2)=='->') {
            idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
      }
   }
   idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
   idexp_info.prefixexp="";
   gtk=vbs_prev_sym_same_line();



   hit_colon_colon := false;
   if (gtk=='::') {
      for (;;) {
         hit_colon_colon=true;
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset=(int)point('s')+1;
         gtk=vbs_prev_sym_same_line();
         if (gtk!=TK_ID) {
            break;
         }
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset=(int)point('s')+1;
         gtk=vbs_prev_sym_same_line();
         if (gtk!='::') {
            break;
         }
      }
   }

   int status=vbs_before_id(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,idexp_info.lastid,idexp_info.info_flags,idexp_info.otherinfo);
   restore_pos(orig_pos);
   return(status);

}

/**
 * Utility function for determining the effective type of a prefix
 * expression.  It parses the expression from left to right, keeping
 * track of the current type of the prefix expression and using that
 * to evaluate the type of the next part of the expression in context.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 * <P>
 * This function is technically private, use the public
 * function {@link _vbs_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
static int _vbs_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                                   struct VS_TAG_RETURN_TYPE &rt, 
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // initiialize return values
   rt.return_type   = "";
   rt.pointer_count = 0;
   rt.return_flags  = 0;

   // loop variables
   typeless tag_files       = tags_filenamea(p_LangId);
   _str     full_prefixexp  = prefixexp;
   previous_id := "";
   reference_count := 0;
   found_define    := false;

   // save the arguments, for retries later
   VS_TAG_RETURN_TYPE orig_rt = rt;
   _str     orig_prefixexp       = prefixexp;
   int      orig_reference_count = reference_count;
   _str     orig_previous_id     = previous_id;

   // process the prefix expression, token by token, delegate
   // most of processing to recursive func _vbs_get_type_of_part
   status := 0;
   while (prefixexp != "") {

      // get next token from expression
      _str ch = _vbs_get_expr_token(prefixexp);
      if (ch == "") {
         // don't recognize something we saw
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }

      // process this part of the prefix expression

      //rt is detrmines the type of class, structure etc For Gea...Student
      status = _vbs_get_type_of_part(errorArgs, tag_files,
                                     previous_id, ch, prefixexp, full_prefixexp,
                                     rt, visited, reference_count, depth);
      //say("_vbs_get_type_of_prefix: status="status" ch="ch" type="rt.return_type);
      if (status) {
         return status;
      }

      // check if 'previous' ID was a define
      orig_previous_id = previous_id;

      // save the arguments, for retries later
      orig_prefixexp       = prefixexp;
      orig_rt              = rt;
      orig_reference_count = reference_count;
   }

   //Does not Happen Very Often
   if (previous_id != "") {
      //say("before previous_id="previous_id" match_class="rt.return_type);
      var_filters := SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_PROCEDURE;
      status = _vbs_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                       var_filters, true, rt, visited);
      if (status) {
         return status;
      }
      previous_id = "";
   }

   //Keep track of the dimensions in array
   rt.pointer_count += reference_count;

   //say("_vbs_get_type_of_prefix: returns "match_class);
   return 0;
}

/*
 * Utility function for getting the next token from the given prefix
 * expression string.
 *
 * @param prefixexp     (reference), prefix expression, after the function
 *                                   returns, contains prefix expression
 *                                   with the first token removed.
 *
 * @return string containing the next token in the prefix expression. "" if nothing.
 */
static _str _vbs_get_expr_token(_str &prefixexp)
{
   // get next token from expression
   int p = pos('^ @{<<|>>|\&\&|\|\||[<>=\|\&\*\+-/~\^\%](=|)|:v|[()\.]|\[|\]}', prefixexp, 1, 'r');
   if (!p) {
      return "";
   }
   p = pos('S0');
   n := pos('0');
   ch := substr(prefixexp, p, n);
   prefixexp = substr(prefixexp, p+n);
   return ch;
}

/**
 * Utility function for parsing the next part of the prefix expression.
 * This is called repeatedly by _vbs_get_type_of_prefix (below) as it
 * parses the prefix expression from left to right, tracking the return
 * type as it goes along.
 * <P>
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_
 * @param tag_files           list of extension specific tag files
 * @param previous_id         the last identifier seen in the prefix expression
 * @param ch                  the last token removed from the prefix expression
 *                            (parsed out using _vbs_get_expr_token, above)
 * @param prefixexp           (reference) The remainder of the prefix expression
 * @param full_prefixexp      The entire prefix expression
 * @param rt                  (reference) set to return type result
 * @param visited             (reference) prevent recursion, cache results
 * @param reference_count     current class context (from tag_current_context)
 * @param depth               depth of recursion (for handling typedefs)
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _vbs_get_type_of_part(_str (&errorArgs)[], typeless tag_files,
                                 _str &previous_id, _str ch,
                                 _str &prefixexp, _str &full_prefixexp,
                                 struct VS_TAG_RETURN_TYPE &rt,
                                 struct VS_TAG_RETURN_TYPE (&visited):[],
                                 int &reference_count, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_vbs_get_type_of_part("previous_id","ch","prefixexp","full_prefixexp")");

   _str current_id = previous_id;

   // number of arguments in paren or brackets group
   num_args := 0;
   status := 0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // process token
   switch (lowcase(ch)) {
   case '.':     // member access operator
      //say("_vbs_get_type_of_part: DOT");
      if (previous_id != "") {
         //say("before previous_id="previous_id" match_class="rt.return_type);
         status = _vbs_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ENUM,
                                          true,rt,visited);
         if (status) {
            return status;
         }
         previous_id = "";
         //say("after previous_id="previous_id" match_class="rt.return_type" pointer_count="rt.pointer_count);
      }
      //rt.pointer_count=0;
      if (rt.pointer_count > 0) {
         errorArgs[1] = '.';
         errorArgs[2] = current_id;
         return(VSCODEHELPRC_DOT_FOR_POINTER);
      } else if (rt.pointer_count < 0) {
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }
      break;

   case 'new':   // new keyword
      // Just ignore 'new' if we don't know what to do with it
      if (depth==0 && !pos('[(.-]',prefixexp,1,'r')) {
         break;
      }
      p := pos('^:b{:v}', prefixexp, 1, 'r');
      if (!p) {
         // this is not good news...
         errorArgs[1] = 'new ' prefixexp;
         return VSCODEHELPRC_INVALID_NEW_EXPRESSION;
      }
      ch = substr(prefixexp, pos('S0'), pos('0'));
      prefixexp = substr(prefixexp, p+pos(""));
      rt.return_type = ch;
      if (substr(prefixexp, 1, 1):=='(') {
         prefixexp = substr(prefixexp, 2);
         _str parenexp;
         if (!match_parens(prefixexp, parenexp, num_args)) {
            // this is not good
            errorArgs[1] = 'new 'ch' 'prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
      }
      previous_id = "";
      break;


      //We need to find a way to handle arrays
   case '(':     // function call, cast, or expression grouping
      _str cast_type;
      if (!match_parens(prefixexp, cast_type, num_args)) {
         // this is not good
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_PARENTHESIS_MISMATCH;
      }

      if (previous_id != "") {
         //Check if there is any casting
         // this was a function call
         _str orig_return_type = rt.return_type;
         status = _vbs_get_return_type_of(errorArgs,tag_files,previous_id,
                                          rt.return_type, num_args,
                                          SE_TAG_FILTER_ANY_PROCEDURE, false,
                                          rt,visited);

         if (status!=0) {

            current_id = previous_id;
            status = _vbs_get_return_type_of(errorArgs, tag_files,
                                             previous_id, rt.return_type, 0,
                                             SE_TAG_FILTER_ANY_DATA, false,
                                             rt,visited);
         }


         _str new_match_class=rt.return_type;
         rt.return_type=orig_return_type;
         if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND &&
             status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
            return status;
         }

         //This may not apply to Visaul Basic
         // did we find a variable of a function or function pointer?
         is_function := false;
         if (rt.taginfo != "") {
            tag_get_info_from_return_type(rt, auto rt_cm);
            if (tag_tree_type_is_func(rt_cm.type_name) || pos('(',rt_cm.return_type)) {
               is_function=true;
            }
         }
         //say("3 new_match_class="new_match_class);
         // could not find match class, maybe this is a function-style cast?
         if (new_match_class == "") {
            num_matches := 0;
            tag_list_symbols_in_context(previous_id, rt.return_type, 
                                        0, 0, tag_files, "",
                                        num_matches, def_tag_max_find_context_tags,
                                        SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_TYPEDEF,
                                        SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_FIND_ALL,
                                        true, false, 
                                        visited, depth+1, 
                                        rt.template_args);
            if (num_matches > 0) {
               dummy_tag := "";
               status = _vbs_parse_return_type(errorArgs, tag_files, "", "", p_buf_name,
                                               previous_id, rt, visited);
               if (!status) {
                  is_function = true;
               }
            } else if (rt.return_type != "") {
               rt.pointer_count = 0;
            }
         } else {
            rt.return_type = new_match_class;
            previous_id="";
         }
         previous_id = "";
      } else {
         //Don't have to worry aboout casting in Visual Basic
         if (pos("^[*&(]@:v",prefixexp,1,'r')) {
            // a cast will be followed by an identifier, (, *, or &
            //say("think it's a cast, depth="depth);
            if (depth > 0) {
               status = _vbs_parse_return_type(errorArgs, tag_files,
                                               "", "", p_buf_name,
                                               cast_type, rt, visited);
               prefixexp="";
               return status;
            }
            // otherwise, just ignore the cast
         } else if (pos('^[ \t]*new[ \t]',cast_type,1,'re')) {
            // object creation expression
            parse cast_type with 'new' cast_type;
            //say("_vbs_get_type_of_part: think it's a new expression");
            status = _vbs_parse_return_type(errorArgs, tag_files,
                                            "", "", p_buf_name,
                                            cast_type, rt, visited);
            //say("NEW: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type" status="status);
            prefixexp="";
            if (status) {
               return status;
            }
         } else {
            // not a cast, must be an expression, go recursive
            //say("think it's an expression, cast_type="cast_type);
            status = _vbs_get_type_of_prefix(errorArgs, cast_type, rt, visited, depth+1);
            if (status) {
               return status;
            }
            //say("EXPR: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
         }
      }
      break;

   case ')':
      // what do I do here?
      errorArgs[1] = full_prefixexp;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;


   // binary operators within expression
   case '=':
   case '<>':
   case '-':
   case '+':
   case '/':
   case '\\':
   case 'mod':
   case '^':
   case '&':
   case '<=':
   case '>=':
   case '<':
   case '>':
   case 'or':
   case 'and':
   case 'xor':
   case 'eqv':
   case 'imp':
      if (depth <= 0) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (previous_id != "") {
         rt.taginfo = "";
         status = _vbs_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          SE_TAG_FILTER_ANY_DATA,
                                          true, rt, visited);
         if (status) {
            return status;
         }
         if (rt.return_type == "") {
            errorArgs[1] = full_prefixexp;
            return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
         }
         prefixexp = "";  // breaks us out of loop
      }
      break;

   default:
      // this must be an identifier (or drop-through case)
      rt.taginfo = "";
      previous_id = ch;
      int var_filters = SE_TAG_FILTER_MEMBER_VARIABLE|SE_TAG_FILTER_PROPERTY;
      if (rt.return_type == "") {
         var_filters |= SE_TAG_FILTER_LOCAL_VARIABLE|SE_TAG_FILTER_GLOBAL_VARIABLE;
      }
      if (rt.return_type=="") {
         // search ahead and try to match up package name
         _str package_name = previous_id;
         _str orig_prefix  = prefixexp;
         while (orig_prefix != "") {
            //say("package_name="package_name);
            if (tag_check_for_package(package_name, tag_files, true, false, null, visited, depth+1)) {
               rt.return_type = package_name;
               previous_id = "";
               //say("found package "package_name);
               prefixexp = orig_prefix;
            }
            ch = _vbs_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch != '.') {
               break;
            }
            _str sepch=ch;
            ch = _vbs_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch == "" || !isid_valid(ch)) {
               break;
            }
            package_name :+= sepch :+ ch;
         }
      }
      break;
   }

   // successful so far, cool.
   //say("_vbs_get_type_of_part: success");
   return 0;
}

/**
 * Utility function for retrieving the return type of the given symbol.
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs                  instruction_case; * @param tag_files
 *                                   refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files                  list of extension specific tag files
 * @param symbol                     name of symbol having given return type
 * @param search_class_name          class context to evaluate return type relative to
 * @param min_args                   minimum number of arguments for function, used
 *                                   to resolve overloading.
 * @param filter_flags               bitset of VS_TAGFILTER_*, allows us to search only
 *                                   certain items in the database (e.g. functions only)
 * @param maybe_class_name           Could the symbol be a class name, for example
 *                                   C++ syntax of BaseObject::method, BaseObject might
 *                                   be a class name.
 * @param rt                         (reference) set to return type information
 * @param visited                    (reference) have we evalued this return type before?
 * @param depth                      depth of recursion (for handling typedefs)
 * @param match_type
 * @param pointer_count
 * @param bas_return_flags
 * @param match_tag
 * @param depth
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _vbs_get_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                   _str symbol, _str search_class_name,
                                   int min_args, 
                                   SETagFilterFlags filter_flags, 
                                   bool maybe_class_name,
                                   struct VS_TAG_RETURN_TYPE &rt,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_vbs_get_return_type_of("symbol","search_class_name","depth")");
   // filter out mutual recursion
   _str input_args='get;'symbol';'search_class_name';'min_args';'filter_flags';'maybe_class_name';'p_buf_name;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;

   // initialize return_flags
   rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                        VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                        VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                        VSCODEHELP_RETURN_TYPE_ARRAY
                       );

   // get the current class from the context
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_class_name, auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);

   status := _vbs_match_return_type_of(errorArgs,tag_files,
                                       symbol,search_class_name,
                                       cur_class_name, min_args,
                                       maybe_class_name,
                                       filter_flags, rt.return_flags,
                                       rt, visited, depth+1);

   // check for error condition
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   }
   return status;
}

/**
 * Utility function for searching the current context and tag files
 * for symbols matching the given symbol and search class, filtering
 * based on the filter_flags and bas_return_flags.  The number of
 * matches is returned and can be obtained using TAGSDB function
 * tag_get_match_browse_info(...).
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param cur_class_name      current class context
 * @param min_args            minimum number of args, for resolving overloading
 * @param maybe_class_name    maybe the given symbol is a class name?
 * @param filter_flags        bitset of VS_TAGFILTER_*, allows us to search only
 *                            certain items in the database (e.g. functions only)
 * @param bas_return_flags    VSCODEHELP_RETURN_TYPE_* flags
 * @param rt                  (reference) return type to match
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               prevent deep recursion when evaluating results
 *
 * @return number of matches on success,
 *         <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _vbs_match_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                     _str symbol, _str search_class_name,
                                     _str cur_class_name, int min_args,
                                     bool maybe_class_name,
                                     SETagFilterFlags filter_flags, 
                                     int vbs_return_flags,
                                     struct VS_TAG_RETURN_TYPE &rt,
                                     VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_vbs_match_return_type_of("symbol","search_class_name")");
   // filter out mutual recursion
   _str input_args='match;'symbol';'search_class_name';'cur_class_name';'min_args';'maybe_class_name';'filter_flags';'vbs_return_flags;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         //say("_vbs_match_return_type_of: SHORTCUT failure");
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         //say("_vbs_match_return_type_of: SHORTCUT success");
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;

   // Attempt to qualify symbols to their appropriate package for Java
   if (search_class_name=="") {
      _str junk;
      tag_qualify_symbol_name(search_class_name,symbol,search_class_name,p_buf_name,tag_files,false,visited,depth+1);
      tag_split_class_name(search_class_name, junk, search_class_name);
   }
   //say("2 before previous_id="symbol" match_class="search_class_name);

   // try to find match for 'symbol' within context, watch for
   // C++ global designator (leading ::)
   i := num_matches := 0;
   tag_clear_matches();
   if (vbs_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      //say("_vbs_match_return_type_of: matching globals");
      tag_list_context_globals(0, 0, symbol, true, tag_files, filter_flags,
                               SE_TAG_CONTEXT_ONLY_NON_STATIC,
                               num_matches, def_tag_max_function_help_protos, 
                               true, false,
                               visited, depth+1);
   } else {
      //say("matching class symbols, search_class="search_class_name" symbol="symbol" filter_flags="filter_flags);
      tag_list_symbols_in_context(symbol, search_class_name, 
                                  0, 0, tag_files, "",
                                  num_matches, def_tag_max_function_help_protos,
                                  filter_flags, 
                                  SE_TAG_CONTEXT_ALLOW_LOCALS,
                                  true, false, visited, depth+1);

   }

   // check for error condition
   //say("_vbs_get_return_type_of: num_matches="num_matches);
   if (num_matches < 0) {
      return num_matches;
   }

   // resolve the type of the matches
   rt.taginfo = "";
   int status = _vbs_get_type_of_matches(errorArgs, tag_files, symbol,
                                         search_class_name, cur_class_name,
                                         min_args, maybe_class_name,
                                         rt, visited, depth+1);
   if (!status && (vbs_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
   }
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   }
   return status;
}

/**
 * Utility function for evaluating the return types of a match set
 * for a given symbol in order to resolve function overloading and
 * come to a consensus on the return type of the given symbol.
 * Returns the class name of the match, depth of pointer indirection
 * in return type, return type flags, and tag information for match.
 * If the given symbol is overloaded and returns different types,
 * this may return an error if it cannot resolve the overloading.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param cur_class_name      current class context (from tag_current_context)
 * @param min_args            minimum number of arguments for function, used
 *                            to resolve overloading.
 * @param maybe_class_name    Could the symbol be a class name, for example
 *                            C++ syntax of BaseObject::method, BaseObject might
 *                            be a class name.
 * @param rt                  (reference) set to return type (result)
 * @param visited             (reference) used to cache results and avoid recursion
 * @param depth               used to avoid recursion
 *
 * @return int
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _vbs_get_type_of_matches(_str (&errorArgs)[], typeless tag_files,
                                    _str symbol, _str search_class_name,
                                    _str cur_class_name, int min_args,
                                    bool maybe_class_name,
                                    struct VS_TAG_RETURN_TYPE &rt,
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_vbs_get_type_of_matches("symbol","search_class_name")");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   // filter out matches based on number of arguments
   _str matchlist[];
   check_args := true;
   tag_init_tag_browse_info(auto cm);
   num_matches := tag_get_num_of_matches();
   //say("_vbs_get_type_of_matches num="num_matches", depth="depth);

   for (;;) {
      for (i:=1; i<=num_matches; i++) {
         tag_get_match_browse_info(i, cm);

         // check that number of argument matches.
         if (check_args && num_matches>1 && tag_tree_type_is_func(cm.type_name) &&
             !(cm.flags & SE_TAG_FLAG_OPERATOR)) {
            arg_pos := 0;
            num_args := 0;
            def_args := 0;
            ff := 1;
            for (;;) {
               _str parm = cb_next_arg(cm.arguments, arg_pos, ff);
               if (parm == "") {
                  break;
               }
               if (pos('=', parm)) {
                  def_args++;
               }
               if (parm :== '...') {
                  num_args = min_args;
                  break;
               }
               if (pos('[',parm) && !pos(',',substr(cm.arguments,arg_pos))) {
                  num_args = min_args;
                  break;
               }
               if (substr(parm,1,7):=='params ') {
                  num_args = min_args;
                  break;
               }
               if (lowcase(substr(parm,1,9)):=='optional ') {
                  num_args = min_args;
                  break;
               }
               num_args++;
               ff=0;
            }
            // this prototype doesn't take enough arguments?
            //say("_vbs_get_type_of_matches: num="num_args" min="min_args);
            if (num_args < min_args) {
               continue;
            }
            // this prototype requires too many arguments?
            if (num_args - def_args > min_args) {
               continue;
            }
         } else if (cm.type_name=="typedef") {
            // skip over recursive typedefs
            _str p1,p2;
            parse cm.return_type with p1 ' ' p2;
            if (symbol==cm.return_type || symbol==p2) {
               continue;
            }
         }
         if ((cm.flags & SE_TAG_FLAG_OPERATOR) && cm.class_name :!= search_class_name) {
            continue;
         }
         //say("WHERE proc_name="proc_name" class="class_name" return_type="return_type);
         if (rt.taginfo == "") {
            rt.taginfo = tag_compose_tag_browse_info(cm);
         }
         if (tag_tree_type_is_class(cm.type_name) || cm.type_name=="enum") {
            cm.return_type = cm.member_name;
         }
         if (cm.return_type != "") {
            matchlist[matchlist._length()] = cm.member_name "\t" cm.class_name "\t" cm.file_name "\t" cm.return_type;
         }
      }
      // break out of loop if we found something or check args is off
      if (min_args>0 || matchlist._length()>0 || !check_args) break;
      check_args=false;
   }

   // for each match in list, (have to do it this way because
   // _vbs_parse_return_type()) uses the context match set.
   VS_TAG_RETURN_TYPE found_rt;tag_return_type_init(found_rt);
   VS_TAG_RETURN_TYPE match_rt;tag_return_type_init(match_rt);
   rt.return_type = "";
   errorArgs[1]=symbol;
   status := VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   found_status := status;
   num_repeats := 0;
   for (i:=0; i<matchlist._length(); i++) {

      parse matchlist[i] with auto proc_name "\t" auto class_name "\t" auto file_name "\t" auto return_type;
      //say("HERE proc_name="proc_name" class="class_name" return_type="return_type);

      tag_return_type_init(found_rt);
      found_rt.template_args = rt.template_args;
      found_rt.template_names = rt.template_names;
      found_rt.istemplate    = rt.istemplate;
      if (class_name=="") {
         status = _vbs_parse_return_type(errorArgs, tag_files, proc_name, cur_class_name,
                                         file_name, cm.return_type, found_rt, visited, depth+1);
      } else {
         status = _vbs_parse_return_type(errorArgs, tag_files, proc_name, class_name,
                                         file_name, cm.return_type, found_rt, visited, depth+1);
      }
      //say("**found_type="found_rt.return_type" match_type="rt.return_type" flags="found_rt.return_flags" status="status);
      if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         // skip over overloaded return types we can't handle
         status=found_status;
         found_rt=match_rt;
         continue;
      }
      if (found_rt.return_type != "") {

         if (rt.return_type=="") {
            found_status=status;
            match_rt=found_rt;
            rt.return_type = found_rt.return_type;
            //_message_box("new match type="rt.return_type);
            rt.return_flags = found_rt.return_flags;
            rt.pointer_count += found_rt.pointer_count;
            //say("RETURN, pointer_count="rt.pointer_count" found_pointer_count="found_rt.pointer_count" found_type="found_rt.return_type);
            match_rt.pointer_count = found_rt.pointer_count;
         } else {
            // different opinions on static_only or const_only, chose more general
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
            }
            if (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2)) {
               rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2);
               rt.return_flags |= (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2));
            }
            if (rt.return_type :!= found_rt.return_type || match_rt.pointer_count != found_rt.pointer_count) {
               // different return type, this is not good.
               //say("MATCH_TYPE="rt.return_type" FOUND_TYPE="found_rt.return_type" pointer="match_rt.pointer_count" found_pointer="found_rt.pointer_count);
               errorArgs[1] = symbol;
               return VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
            }
         }
         // if we have over five matching return types, then call it good
         num_repeats++;
         if (num_repeats>=4) {
            //say("_vbs_get_type_of_matches: GOT FOUR IDENTICAL TYPES");
            break;
         }
      }
   }
   if (status && status!=VSCODEHELPRC_BUILTIN_TYPE &&
       status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
      return status;
   }
   rt.template_args._makeempty();
   rt.template_names._makeempty();
   rt.istemplate = found_rt.istemplate;
   if (found_rt.istemplate) {
      rt.template_args = found_rt.template_args;
      rt.template_names = found_rt.template_names;
   }

   //say("maybe class name, num_matches="num_matches);
   // Java syntax like Class.blah... or C++ style iostream::blah
   if (maybe_class_name && num_matches==0) {
      //say("111 searching for class name, symbol="symbol" class="search_class_name);
      class_context_flags := SE_TAG_CONTEXT_ANYTHING;
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS);
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_PROTECTED);
      tag_list_symbols_in_context(symbol, search_class_name, 
                                  0, 0, tag_files, "",
                                  num_matches, def_tag_max_function_help_protos,
                                  SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_UNION,
                                  class_context_flags,
                                  true, false, visited, depth+1);

      //say("found "num_matches" matches");
      if (num_matches > 0) {
         tag_get_match_browse_info(1, auto xInfo);
         //say("X tag="x_tag_name" class="x_class_name" type="x_type_name);
         rt.return_type = symbol;
         if (search_class_name == "" || search_class_name == cur_class_name) {
            _str outer_class_name = cur_class_name;
            local_matches := 0;
            if (xInfo.flags & SE_TAG_FLAG_TEMPLATE) {
               rt.istemplate=true;
            }
            for (;;) {
               tag_list_symbols_in_context(rt.return_type, cur_class_name, 
                                           0, 0, tag_files, "",
                                           local_matches, def_tag_max_function_help_protos,
                                           SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_UNION,
                                           class_context_flags,
                                           true, false, visited, depth+1);
               //say("222 match_type="rt.return_type" cur_class_name="cur_class_name" num_matches="local_matches);
               if (local_matches > 0) {
                  tag_get_match_browse_info(1, auto relInfo);
                  rt.return_type = tag_join_class_name(rt.return_type, relInfo.class_name, tag_files, true, true, false, visited, depth+1);
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                  break;
               }
               _str junk;
               tag_split_class_name(outer_class_name, junk, outer_class_name);
               if (outer_class_name=="") {
                  break;
               }
            }
         } else if (search_class_name != "") {
            rt.return_type = tag_join_class_name(rt.return_type, search_class_name, tag_files, true, true, false, visited, depth+1);
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         }
      }
   }


   // no matches?
   if (num_matches == 0) {
      //say("_vbs_get_type_of_matches: no symbols found");
      errorArgs[1] = symbol;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // check if we should list private class members
   //say("_vbs_get_type_of_matches: match_type="rt.return_type" cur_class="cur_class_name);
   if (tag_current_context() > 0) {
      // current method is from same class, then we have private access
      class_pos := lastpos(cur_class_name,rt.return_type);
      if (class_pos>0 && class_pos+length(cur_class_name)==length(rt.return_type)+1) {
         if (class_pos==1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         } else if (substr(rt.return_type,class_pos-1,1)==VS_TAGSEPARATOR_package) {
            // maybe class comes from imported namespace
            import_name := substr(rt.return_type,1,class_pos-2);
            int import_id = tag_find_local_iterator(import_name,true,false,false,"");
            _str import_type;
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_local_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_local_iterator(import_name,import_id,true,true,false,"");
            }
            import_id = tag_find_context_iterator(import_name,true,false,false,"");
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_context_iterator(import_name,import_id,true,true,false,"");
            }
         }
      }
   }
   //say("_vbs_get_type_of_matches() returns "rt.return_type" pointers="rt.pointer_count);
   return 0;
}

/**
 * Utility function for parsing the syntax of a return type
 * pulled from the tag database, tag_get_detail(VS_TAGDETAIL_return, ...)
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param symbol             name of symbol having given return type
 * @param search_class_name  class context to evaluate return type relative to
 * @param file_name          file from which return type string comes
 * @param return_type        return type string to be parsed (e.g. FooBar **)
 * @param rt                 (reference) return type information
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _vbs_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                                  _str symbol, _str search_class_name,
                                  _str file_name, _str return_type,
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // filter out mutual recursion
   _str input_args='parse;'symbol';'search_class_name';'file_name';'return_type;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;

   found_seperator := false;
   allow_local_class := true;
   _str orig_return_type = return_type;
   found_type := "";
   rt.return_type = "";

   verified_package := "";
   package_name := "";
   ch := "";
   num_args := 0;
   status := 0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true);

   while (return_type != "") {
      int p = pos('^ @{\[|\]|[.()]|:v}', return_type, 1, 'r');
      if (p <= 0) {
         break;
      }
      p = pos('S0');
      n := pos('0');
      ch = substr(return_type, p, n);
      return_type = substr(return_type, p+n);
      //say("return ch="ch" return_type="return_type" package_name="package_name);
      switch (lowcase(ch)) {
      case '.':
         if (package_name != "") {
            found_seperator = true;
            //say("_vbs_parse_return_type: package="package_name);
            if (pos('/',package_name)) {
               // maybe we need to move the package separator back
               new_package_name := stranslate(package_name,ch,VS_TAGSEPARATOR_package);
               new_package_name = stranslate(new_package_name,ch,VS_TAGSEPARATOR_class);
               if (tag_check_for_package(new_package_name, tag_files, true, false, null, visited, depth+1)) {
                  verified_package=new_package_name;
                  package_name = new_package_name :+ VS_TAGSEPARATOR_package;
               } else {
                  package_name :+= VS_TAGSEPARATOR_class;
               }
            } else if (tag_check_for_package(package_name, tag_files, true, false, null, visited, depth+1)) {
               // this is a known package
               verified_package=stranslate(package_name,ch,VS_TAGSEPARATOR_class);
               package_name :+= VS_TAGSEPARATOR_package;
            } else if (tag_check_for_package(package_name:+ch, tag_files, false, false, null, visited, depth+1)) {
               // this is a package prefix
               package_name :+= ch;
            } else if (package_name != "") {
               // this must be a class name
               package_name :+= VS_TAGSEPARATOR_class;
            }
         }
         break;
      case '[':
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         rt.pointer_count++;
         break;
      case ']':
         break;
      case '(':
         _str parenexp;
         if (!match_parens(return_type, parenexp, num_args)) {
            // this is not good
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         while (pos('[', parenexp)) {
            parenexp = substr(parenexp, pos('S')+1);
            if (!match_brackets(parenexp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            rt.pointer_count++;
         }
         break;
      case ')':
         break;
      case 'const':
      case 'extern':
         if (ch:=='const') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         break;
      case 'byref':
         if (ch:=='byref') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }
      case 'byval':
         if (ch:=='byval') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_IN;
            break;
         }
         // drop through, treat as a plain identifier
      case 'readonly':
         if (ch:=='readonly') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            break;
         }
         // drop through, treat as a plain identifier
      default:
         // this must be an identifier
         // try simple macro substitution
         _UpdateContextAndTokens(true);
         package_name :+= ch;
         if (found_type != "" && allow_local_class && found_seperator) {
            found_type :+= VS_TAGSEPARATOR_class :+ ch;
            found_seperator = false;
         } else if (found_type != "" && !found_seperator) {
            found_type :+= ' ' ch;
         } else {
            found_type = ch;
         }
      }
   }
   //say("LOCAL search_class="search_class_name" found_type="found_type);
   _str qualified_name = found_type;
   if (pos('/', package_name)) {
      found_type = package_name;
   }
   if (allow_local_class) {
      _str inner_name, outer_name;
      tag_split_class_name(found_type, inner_name, outer_name);
      qualified_name="";
      if (length(outer_name) < length(search_class_name) && pos(outer_name,search_class_name)) {
         outer_name = tag_join_class_name(inner_name, search_class_name, tag_files, false, true, false, visited, depth+1);
         qualified_name = outer_name;
         if (outer_name :== "" && search_class_name :!= "" && found_type :!= inner_name) {
            outer_name = found_type;
         }
      }
      if (qualified_name=="") {
         // first qualify the outer name
         outer_qualified := "";
         if (outer_name!="") {
            status = tag_qualify_symbol_name(outer_qualified, outer_name, search_class_name, file_name, tag_files, false, visited, depth+1);
            if (outer_qualified!="" && outer_qualified != outer_name) {
               //say("_vbs_parse_return_type: outer_qualified="outer_qualified);
               outer_name=outer_qualified;
            }
         }
         _str package_inner=(verified_package!="")? (verified_package:+VS_TAGSEPARATOR_package:+inner_name) : inner_name;
         if (outer_name=="" && search_class_name!="") {
            status = tag_qualify_symbol_name(qualified_name, package_inner, search_class_name, file_name, tag_files, false, visited, depth+1);
         } else {
            status = tag_qualify_symbol_name(qualified_name, package_inner, outer_name, file_name, tag_files, false, visited, depth+1);
         }
      }
      if (qualified_name=="") {
         qualified_name = found_type;
      }
   }

   // try to handle typedefs
   if (depth < VSCODEHELP_MAXRECURSIVETYPESEARCH) {
      _str qualified_inner;
      _str qualified_outer;
      tag_split_class_name(qualified_name, qualified_inner, qualified_outer);
      //say("_vbs_parse_return_type: inner="qualified_inner" outer="qualified_outer);
      if (tag_check_for_typedef(/*found_type*/qualified_inner, tag_files, false, qualified_outer, visited, depth+1)) {
         //say(qualified_name" is a typedef");
         //say(indent_string(depth*2)"_vbs_parse_return_type: typedef="qualified_name);
         orig_const_only := (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
         orig_is_array   := (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES);
         //say("istemplate="istemplate);
         rt.return_type=qualified_name;
         status = _vbs_get_return_type_of(errorArgs, tag_files, qualified_inner, qualified_outer,
                                          0, SE_TAG_FILTER_TYPEDEF, false, rt, visited, depth+1);
         if (status==VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
            return(status);
         } else {
            qualified_name=rt.return_type;
            //say("_vbs_parse_return_type: match_tag="rt.taginfo" status="status", qual="qualified_name);
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags |= orig_const_only;
            }
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
               rt.return_flags |= orig_is_array;
            }
            if (status) {
               return status;
            }
         }
      }
      //say("qualify = "qualified_name" found_type="found_type);
   } else {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   rt.return_type = qualified_name;
   //say("_vbs_parse_return_type returns "rt.return_type);
   if (rt.return_type == "") {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   visited:[input_args]=rt;
   return 0;
}

_command void vbscript_codehelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if( !command_state() ) {
      int cfg;
      left();cfg=_clex_find(0,'g');right();
      if( !_in_comment() && cfg!=CFG_STRING ) {
         save_pos(auto p);
         word_chars := _clex_identifier_chars();
         if( pos('['word_chars']',get_text(),1,'r') ) {
            left();
         }
         gtk=vbs_prev_sym_same_line();
         _str word_before = (gtk==TK_ID)?gtkinfo:"";
         word_before=upcase(strip(word_before));
         gtk=vbs_prev_sym_same_line();
         _str word_before_word_before = (gtk==TK_ID)?gtkinfo:"";
         word_before_word_before=upcase(strip(word_before_word_before));
         int word_before_col = (word_before_word_before!="")?p_col:1;
         restore_pos(p);
         if( word_before=="" ) return;
         if( _GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP ) {
            _do_function_help(OperatorTyped:true, 
                              DisplayImmediate:false,
                              cursorInsideArgumentList:true);
         }
      }
   }
}

int _vbs_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   int nRet = _bas_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                     info_flags,otherinfo,false,max_matches,
                                     exact_match,case_sensitive,
                                     filter_flags,context_flags,
                                     visited,depth,prefix_rt);
   return nRet;
}

