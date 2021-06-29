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
#import "autobracket.e"
#import "autocomplete.e"
#import "c.e"
#import "caddmem.e"
#import "ccontext.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "csymbols.e"
#import "codehelp.e"
#import "cutil.e"
#import "hotspots.e"
#import "notifications.e"
#import "pmatch.e"
#import "pushtag.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "verilog.e"
#endregion

using se.lang.api.LanguageSettings;

static const SYSTEMVERILOG_LANGUAGE_ID=   'systemverilog';
static const SYSTEMVERILOG_WORDCHARS=     'A-Za-z0-9_$';

defeventtab systemverilog_keys;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;
def ' '= systemverilog_space;
def 'ENTER'=systemverilog_enter;
def '}'=systemverilog_endbrace;


/**
 * System Verilog header include path.
 *
 * @see def_systemverilog_parse_includes
 * @default ""
 * @categories Configuration_Variables
 */
_str def_systemverilog_include_path = "";
/**
 * Set to 'true' if the System Verilog tagging parser recursively parse 
 * quoted include files that it can locate in the include path?
 * 
 * @see def_systemverilog_include_path
 * @default true
 * @categories Configuration_Variables
 */
bool def_systemverilog_parse_includes = true;


int _systemverilog_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, 'systemverilog', 'sv', 'SystemVerilog Built-ins', "", false, withRefs, useThread, forceRebuild);
}

_command void systemverilog_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(SYSTEMVERILOG_LANGUAGE_ID);
}

static SYNTAX_EXPANSION_INFO systemverilog_keywords:[] = {
   'case'         => { 'case ... endcase' },
   'casex'        => { 'casex ... endcase' },
   'casez'        => { 'casez ... endcase' },
   'class'        => { 'class ... endclass' },
   'clocking'     => { 'clocking ... endclocking' },
   'covergroup'   => { 'covergroup ... endgroup' },
   'function'     => { 'function ... endfunction' },
   'generate'     => { 'generate ... endgenerate' },
   'interface'    => { 'interface ... endinterface' },
   'module'       => { 'module ... endmodule' },
   'primitive'    => { 'primitive ... endprimitive' },
   'package'      => { 'package ... endpackage' },
   'program'      => { 'program ... endprogram' },
   'property'     => { 'property ... endproperty' },
   'specify'      => { 'specify ... endspecify' },
   'sequence'     => { 'sequence ... endsequence' },
   'table'        => { 'table ... endtable' },
   'task'         => { 'task ... endtask' },

   'enum'         => { 'enum' },
   'union'        => { 'union' },
   'struct'       => { 'struct' },
   'int'          => { 'int' },
   'integer'      => { 'integer' },

   'if'           => { 'if ( ... )' },
   'for'          => { 'for ( ... )' },
   'foreach'      => { 'foreach( ... ) ' },
   'while'        => { "while ( ... )" },
   'repeat'       => { "repeat ( ... )" },
   'expect'       => { "expect ( ... )" },
};

int _systemverilog_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, systemverilog_keywords, prefix, min_abbrev);
}

static _str _systemverilog_expand_space()
{
   aliasfilename := "";
   label := "";


   // Get a line and strip off only the trailing blanks
   orig_line := "";
   get_line(orig_line);
   set_surround_mode_start_line();
   line := strip(orig_line,'T');
   // Proceed only for cursor on first word
   if( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }

   maybe_reposition_block_delimiter();

   // Delete all leading and trailing blanks
   verilogword := strip(line);
   if( verilogword=="" ) {
      // Fall through to space bar key
      return(1);
   }
   if (pos("extern|typedef", line, 1,'er')) {
      return(1);
   }

   // Look for labeled statements (e.g. label_xyz : statement)
   label_col := 0;
   _str rest=line;
   if( pos(':=',line) ) {
      // Variable assignment
      return(1);   // Fall through to space bar key
   } else if( pos('[ \t]@'SYSTEMVERILOG_WORDCHARS'[ \t]@\:',line,1,'er') ) {
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
   PartialWord := lowcase(strip(rest));

   // min_abbrev2 returns the expanded word based upon this fragment
   // the function first checks the _Keywords[] array of strings. If no match
   // there, then it checks the aliasfile. If the match was found
   // in the aliasfile, then the aliasfilename is set to the OS path
   // otherwise it is set to "".
   verilogword=min_abbrev2(PartialWord,systemverilog_keywords,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(PartialWord, verilogword, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }


   modify_line := true;

   clear_hotspots();
   if( verilogword=="" ) {
      // Fall through to space bar key
      //verilogword = strip_last_cc_word();
      modify_line = false;
      return(1);
      /*
      if (verilogword=="") {
         return(1);
      }
      */
   }
   width := 0;
   if (modify_line) {
      line=substr(line,1,length(line)-length(PartialWord)):+verilogword;
      width=text_col(line,length(line)-length(verilogword)+1,'i')-1;
   } else {
      save_pos(auto p);
      _first_non_blank();
      width = p_col-1;
      restore_pos(p);
   }
   if( width<0 ) {
      width=0;
   }
   maybe_insert_semi := ';'; // TODO: maybe add logic to disable automatic ; insertion

   status := 0;
   insertBE := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   doNotify := true;
   if ( verilogword=='begin' ) {
      replace_line(line);
      if( insertBE ) {
         insert_line(indent_string(width)'end');
         up(1);
      } else doNotify = (line != orig_line);
      _end_line();
      ++p_col;
   } else if (verilogword=='case' || verilogword=='casex' || verilogword=='casez') {
      replace_line(line);
      if( insertBE ) {
         insert_line(indent_string(width)'endcase');
         up(1);
      } else doNotify = (line != orig_line);
      _end_line();
      ++p_col;
   } else if (verilogword == 'function' ||
              verilogword == 'task' ||
              verilogword == 'class' ||
              verilogword == 'module' ||
              verilogword == 'program' ||
              verilogword == 'package' ||
              verilogword == 'interface' ||
              verilogword == 'sequence' ||
              verilogword == 'property') {

      newLine := line:+' ':+maybe_insert_semi;
      replace_line(newLine);
      if( insertBE ) {
         insert_line(indent_string(width)'end'verilogword);
         up(1);
      }
      _end_line();
      left();

      doNotify = (insertBE || newLine != orig_line);
   } else if (verilogword == 'covergroup') {
      newLine := line:+' ':+maybe_insert_semi;
      replace_line(newLine);
      if( insertBE ) {
         insert_line(indent_string(width)'endgroup');
         up(1);
      }
      _end_line();
      left();
      doNotify = (insertBE || newLine != orig_line);
   } else if (verilogword=='generate' ||
              verilogword=='specify' ||
              verilogword=='primitive' ||
              verilogword=='table') {
      replace_line(line);
      if( insertBE ) {
         insert_line(indent_string(width)'end'verilogword);
         up(1);
      } else doNotify = (line != orig_line);
      _end_line();
      ++p_col;
   } else if (verilogword=='for' ||
              verilogword=='foreach' ||
              verilogword=='if' ||
              verilogword=='expect' ||
              verilogword=='repeat' ||
              verilogword=='while') {
      replace_line(line' () ');
      end_line();
      add_hotspot();
      left(); left();
      add_hotspot();
   } else if (verilogword=='enum' ||
              verilogword=='union' ||
              verilogword=='struct') {

      replace_line(line' {}');
      end_line();
      left();
   } else {
      // Word is aleady expanded, just add a space
      replace_line(line' ');
      _end_line();
      doNotify = (line != orig_line);
   }
   show_hotspots();

   if( doNotify ) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

_command void systemverilog_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if( command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is SyntaxIndent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _systemverilog_expand_space()
      ) {
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

/* 
   Keyword list:
   begin|case|casex|casez|class|covergroup|fork|function|generate|interface|module|package|primitive|program|property|randcase|randsequence|sequence|specify|table|task
   always|always_comb|always_ff|always_latch|initial|final
   do|else|for|foreach|forever|if|repeat|while
   extern|typedef|virtual
   enum|struct|union
   endcase|endclass|endfunction|endgenerate|endgroup|endinterface|endmodule|endpackage|endprimitive|endprogram|endproperty|endsequence|endspecify|endtable|endtask|end
   join_any|join_none|join

   ; { } ( )
 
   statement indent:
   always(_comb|_ff|_latch|)|do|else|final|for(each|ever|)|if|initial|repeat|while

   indent block:
   begin|case([xz]|)|class|covergroup|fork|function|generate|interface|module|package|primitive|program|property|rand(case|sequence)|sequence|specify|table|task

   end block: 
   end(case|class|function|generate|group|interface|module|package|primitive|program|property|sequence|specify|table|task|)|join(_any|_none|)
 
   [;{}()]|\b(always(_comb|_ff|_latch|)|begin|case([xz]|)|class|covergroup|do|else|end(case|class|function|generate|group|interface|module|package|primitive|program|property|sequence|specify|table|task|)|extern|final|for(each|ever|k|)|function|generate|if|initial|interface|join(_any|_none|)|module|package|primitive|program|property|rand(case|sequence)|repeat|sequence|specify|table|task|typedef|while)\b
*/

enum { 
   SV_DECLARATION_INDENT, 
   SV_STATEMENT_INDENT,
   SV_CASE_STATEMENT,
   SV_BLOCK_INDENT,
   SV_END_INDENT,
   SV_MODIFIER,
};

static int sv_tk:[] = {
   "always"       => SV_STATEMENT_INDENT,
   "always_comb"  => SV_STATEMENT_INDENT,
   "always_ff"    => SV_STATEMENT_INDENT,
   "always_latch" => SV_STATEMENT_INDENT,
   "begin"        => SV_BLOCK_INDENT,
   "case"         => SV_CASE_STATEMENT,
   "casex"        => SV_CASE_STATEMENT,
   "casez"        => SV_CASE_STATEMENT,
   "class"        => SV_DECLARATION_INDENT,
   "covergroup"   => SV_BLOCK_INDENT,
   "do"           => SV_STATEMENT_INDENT,
   "else"         => SV_STATEMENT_INDENT,
   "end"          => SV_END_INDENT,
   "endcase"      => SV_END_INDENT,
   "endclass"     => SV_END_INDENT,
   "endfunction"  => SV_END_INDENT,
   "endgenerate"  => SV_END_INDENT,
   "endgroup"     => SV_END_INDENT,
   "endinterface" => SV_END_INDENT,
   "endmodule"    => SV_END_INDENT,
   "endpackage"   => SV_END_INDENT,
   "endprimitive" => SV_END_INDENT,
   "endprogram"   => SV_END_INDENT,
   "endproperty"  => SV_END_INDENT,
   "endsequence"  => SV_END_INDENT,
   "endspecify"   => SV_END_INDENT,
   "endtable"     => SV_END_INDENT,
   "endtask"      => SV_END_INDENT,
   "extern"       => SV_MODIFIER,
   "final"        => SV_STATEMENT_INDENT,
   "for"          => SV_STATEMENT_INDENT,
   "foreach"      => SV_STATEMENT_INDENT,
   "forever"      => SV_STATEMENT_INDENT,
   "fork"         => SV_BLOCK_INDENT,
   "function"     => SV_DECLARATION_INDENT,
   "generate"     => SV_BLOCK_INDENT,
   "if"           => SV_STATEMENT_INDENT,
   "initial"      => SV_STATEMENT_INDENT,
   "interface"    => SV_BLOCK_INDENT,
   "join"         => SV_END_INDENT,
   "join_any"     => SV_END_INDENT,
   "join_none"    => SV_END_INDENT,
   "module"       => SV_DECLARATION_INDENT,
   "package"      => SV_DECLARATION_INDENT,
   "primitive"    => SV_DECLARATION_INDENT,
   "program"      => SV_DECLARATION_INDENT,
   "property"     => SV_BLOCK_INDENT,
   "randcase"     => SV_CASE_STATEMENT,
   "randsequence" => SV_BLOCK_INDENT,
   "repeat"       => SV_STATEMENT_INDENT,
   "sequence"     => SV_BLOCK_INDENT,
   "specify"      => SV_BLOCK_INDENT,
   "table"        => SV_BLOCK_INDENT,
   "task"         => SV_DECLARATION_INDENT,
   "typedef"      => SV_MODIFIER,
   "while"        => SV_STATEMENT_INDENT,
};

static _str _re_sv_parse = '[;{}()]|\b(always(_comb|_ff|_latch|)|begin|case([xz]|)|class|covergroup|do|else|end(case|class|function|generate|group|interface|module|package|primitive|program|property|sequence|specify|table|task|)|extern|final|for(each|ever|k|)|function|generate|if|initial|interface|join(_any|_none|)|module|package|primitive|program|property|rand(case|sequence)|repeat|sequence|specify|table|task|typedef|while)\b';

static int _systemverilog_find_matching_block_col()
{
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   int status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
   restore_search(s1, s2, s3, s4, s5);
   if (status) {
      restore_pos(p);   // error'd
      return(1);
   }
   _first_non_blank();
   col := p_col;
   restore_pos(p);
   return (col);
}

int _systemverilog_indent_col(int syntax_indent)
{
   orig_col := p_col;
   orig_linenum := p_line;

   save_pos(auto p);
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   _clex_skip_blanks('-');

   first_col := 1;
   save_pos(auto last_tk_pos);
   save_pos(auto last_open_pos);

   hit_semi := 0;
   hit_parens := 0;
   nesting := 0;
   nest_ch := "";
   status := search(_re_sv_parse, "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) {
         ch := get_text();
         switch (ch) {
         case ';':
            if (!nesting) {
               if (!hit_semi) {  // first hit
                  save_pos(last_tk_pos);
                  ++hit_semi;
               } else {
                  if (hit_parens) {
                     restore_pos(last_open_pos);
                  } else {
                     restore_pos(last_tk_pos);
                  }
                  _first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  return (first_col);
               }
            }
            break;

         case '(':
            if (nesting > 0 && nest_ch == ch) {
               --nesting;
               if (!nesting) {
                  ++hit_parens;
                  save_pos(last_open_pos);
               }
            } else if (!nesting) {
               save_pos(last_tk_pos);
               ++p_col;
               status = _clex_skip_blanks();
               if (!status && (p_line < orig_linenum || (p_line == orig_linenum && p_col < orig_col))) {
                  first_col = p_col;
               } else {
                  restore_pos(last_tk_pos);
                  _first_non_blank();
                  first_col = p_col + syntax_indent;
               }
               restore_pos(p);
               return first_col;
            }
            break;

         case ')':
            if (nesting > 0 && nest_ch == '(') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '(';
               ++nesting;
            }
            break;

         case '{':
            if (nesting > 0 && nest_ch == ch) {
               --nesting;
               if (nesting == 0) {
                  ++hit_parens;
                  save_pos(last_open_pos);
               }
            } else if (!nesting) {
               _first_non_blank();
               first_col = p_col;
               restore_pos(p);
               return (first_col + syntax_indent);
            }
            break;

         case '}':
            if (nesting > 0 && nest_ch == '{') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '{';
               ++nesting;
            }
            break;
         }
         status = repeat_search();
         continue;
      } else {
         if (nesting > 0) {
            status = repeat_search();
            continue;
         }
         word := get_match_text();
         switch (sv_tk:[word]) {
         case SV_STATEMENT_INDENT:
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            if (!hit_semi) {
               first_col = first_col + syntax_indent;
            }
            return (first_col);
         
         case SV_CASE_STATEMENT:
            if (hit_semi) {
               restore_pos(last_tk_pos);
            } 
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            if (!hit_semi) {
               first_col = first_col + syntax_indent;
            }
            return (first_col);

         case SV_BLOCK_INDENT:
            _first_non_blank();
            first_col = p_col;
            style := associated_block_style();
            restore_pos(p);
            if (style == BES_BEGIN_END_STYLE_3) {
               return first_col;
            }
            return (first_col + syntax_indent);

         case SV_DECLARATION_INDENT:
            // check for extern/typedef
            save_pos(last_tk_pos);
            status = repeat_search();
            if (!status) {
               word = get_match_text();
               restore_pos(last_tk_pos);
               if (sv_tk:[word] == SV_MODIFIER) {
                  _first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  return (first_col);
               }
            }
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            return (first_col + syntax_indent);

         case SV_END_INDENT:
            style = associated_block_style();
            first_col = _systemverilog_find_matching_block_col();
            restore_pos(p);
            if (style == BES_BEGIN_END_STYLE_3) {
               first_col = max(1, first_col - p_SyntaxIndent);
            }
            return (first_col);

         default:
            status = repeat_search();
            continue;
         }
      }
      break;
   }
   restore_pos(p);
   return 1;
}

bool _systemverilog_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;

   maybe_reposition_block_delimiter();

   int col = _systemverilog_indent_col(SyntaxIndent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void systemverilog_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_systemverilog_expand_enter);
}
bool _systemverilog_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

_command void systemverilog_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('}');
   if (command_state() || 
       p_window_state:=='I' ||
       p_SyntaxIndent<0 ||
       p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      line := "";
      get_line(line);
      if (line=='}') {
         int status;
         save_pos(auto p);
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
         restore_search(s1, s2, s3, s4, s5);
         _first_non_blank();
         col := p_col;
         restore_pos(p);
         if (!status && col > 0) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

/**
 * SystemVerilog <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int systemverilog_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent = p_SyntaxIndent;
   _begin_select(); up(); _end_line();
   int col = _systemverilog_indent_col(syntax_indent);
   return col;
}


//########################################################################
//////////////////////////////////////////////////////////////////////////
// HOOK FUNCTIONS and UTILITY FUNCTIONS
//

int _systemverilog_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator,idexp_info, visited, depth);
}

int _systemverilog_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                     _str lastid,int lastidstart_offset,
                                     int info_flags,typeless otherinfo,
                                     bool find_parents,int max_matches,
                                     bool exact_match,bool case_sensitive,
                                     SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                     SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                     VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   // workaround for queue declaration
   if (prefixexp:=='' && lastid:=='$') {
      errorArgs[1] = lastid;
      errorArgs[2] = 'queue declaration';
      return VSCODEHELPRC_BUILTIN_TYPE;
   }
   return _c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,lastidstart_offset,
                               info_flags,otherinfo,
                               find_parents,
                               max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,
                               visited,depth,prefix_rt);
}

int _systemverilog_fcthelp_get_start(_str (&errorArgs)[],
                                     bool OperatorTyped,
                                     bool cursorInsideArgumentList,
                                     int &FunctionNameOffset,
                                     int &ArgumentStartOffset,
                                     int &flags,
                                     int depth=0)
{
   return _c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,
                               FunctionNameOffset,ArgumentStartOffset,flags,
                               depth);
}

int _systemverilog_fcthelp_get(_str (&errorArgs)[],
                         VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                         bool &FunctionHelp_list_changed,
                         int &FunctionHelp_cursor_x,
                         _str &FunctionHelp_HelpWord,
                         int FunctionNameStartOffset,
                         int flags,
                         VS_TAG_BROWSE_INFO symbol_info=null,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   errorArgs._makeempty();
   return _c_fcthelp_get(errorArgs,
                           FunctionHelp_list,
                           FunctionHelp_list_changed,
                           FunctionHelp_cursor_x,
                           FunctionHelp_HelpWord,
                           FunctionNameStartOffset,
                           flags, symbol_info,
                           visited, depth);
}


/**
 * Modify Symbol Properties form
 * 
 */
void _systemverilog_disable_props()
{
   _nocheck _control ctl_static_check_box;
   _nocheck _control ctl_proto_check_box;
   _nocheck _control ctl_access_check_box;
   _nocheck _control ctl_transient_check_box;
   _nocheck _control ctl_native_check_box;
   _nocheck _control ctl_partial_check_box;
   _nocheck _control ctl_const_check_box;
   _nocheck _control ctl_inline_check_box;
   _nocheck _control ctl_abstract_check_box;
   _nocheck _control ctl_synchronized_check_box;
   _nocheck _control ctl_extern_check_box;
   _nocheck _control ctl_forward_check_box;
   _nocheck _control ctl_final_check_box;
   _nocheck _control ctl_volatile_check_box;
   _nocheck _control ctl_virtual_check_box;
   _nocheck _control ctl_template_check_box;
   _nocheck _control ctl_mutable_check_box;
   _nocheck _control ctl_internal_check_box;
   _nocheck _control ctl_constexpr_check_box;
   _nocheck _control ctl_constinit_check_box;
   _nocheck _control ctl_consteval_check_box;
   _nocheck _control ctl_export_check_box;

   ctl_static_check_box.p_enabled       = false;
   ctl_proto_check_box.p_enabled        = false;
   ctl_access_check_box.p_enabled       = false;
   ctl_transient_check_box.p_enabled    = false;
   ctl_native_check_box.p_enabled       = false;
   ctl_partial_check_box.p_enabled      = false;
   ctl_const_check_box.p_enabled        = false;
   ctl_inline_check_box.p_enabled       = false;
   ctl_abstract_check_box.p_enabled     = false;
   ctl_synchronized_check_box.p_enabled = false;
   ctl_extern_check_box.p_enabled       = false;
   ctl_forward_check_box.p_enabled      = false;
   ctl_final_check_box.p_enabled        = false;
   ctl_volatile_check_box.p_enabled     = false;
   ctl_virtual_check_box.p_enabled      = false;
   ctl_template_check_box.p_enabled     = false;
   ctl_mutable_check_box.p_enabled      = false;
   ctl_internal_check_box.p_enabled     = false;
   ctl_constexpr_check_box.p_enabled    = false;
   ctl_constinit_check_box.p_enabled    = false;
   ctl_consteval_check_box.p_enabled    = false;
   ctl_export_check_box.p_enabled       = false;
}

int _systemverilog_generate_function(VS_TAG_BROWSE_INFO &cm, int &c_access_flags,
                                     _str (&header_list)[],_str function_body,
                                     int indent_col, int begin_col,
                                     bool make_proto=false)
{
   AfterKeyinPos := 0;
   tag_flags := cm.flags;
   decl_type := "function";
   if (cm.return_type == '') {
      decl_type = "task";
   }
   result := "";
   if (tag_flags & SE_TAG_FLAG_EXTERN) {
      strappend(result, "extern ");
   }
   if (tag_flags & SE_TAG_FLAG_STATIC) {
      strappend(result, "static ");
   }
   if (tag_flags & SE_TAG_FLAG_PROTECTED) {
      strappend(result, "protected ");
   } else if (tag_flags & SE_TAG_FLAG_PRIVATE) {
      strappend(result, "local ");
   }
   strappend(result, decl_type:+" ":+cm.member_name:+"(");
   if (cm.arguments) {
      strappend(result, cm.arguments);
   }
   strappend(result, ");");
   _insert_text(result);
   save_pos(AfterKeyinPos);
   insert_line(indent_string(indent_col):+"end":+decl_type);
   return (AfterKeyinPos);
}

bool _systemverilog_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}

const METHOD_KWS = "extern|function|local|protected|pure|static|task|virtual|endfunction|endtask|covergroup|endcovergroup";

void _systemverilog_snippet_find_leading_context(long selstart, long selend)
{
   save_pos(auto pp);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   if (search(METHOD_KWS, 'L@XCS') == 0) {
      here := _QROffset();
      if (here >= selstart && here <= selend) {
         // This contains a method definition, include class decl as 
         // leading context.
         restore_pos(pp);
         search('class', '-@XCS'); 
      } else {
         restore_pos(pp);
      }
   } else {
      restore_pos(pp);
   }
   restore_search(s1, s2, s3, s4, s5);

   _first_non_blank();
   while (p_line > 0) {
      //say('@'_QROffset());
      if (p_col <= 1) {
         p_col = 1;
         //say('col=1 @'_QROffset());
         break;
      } else {
         ty := _clex_find(0, 'G');
         if (ty == CFG_KEYWORD) {
            w := cur_identifier(auto startCol);
            //say('   kw='w);
            if (beginsWith(w, 'end') &&
                find_matching_paren(true) == 0) {
               // Better to start at beginning of block statement then just
               // include an unmatched end in the context.
               _first_non_blank();
               //say('matched @'_QROffset());
               break;
            } else if (w == 'else') {
               search('if', '-<CK');
               _first_non_blank();
               //say('elsed @'_QROffset());
               break;
            } else if (w == 'input' || w == 'output' || w == 'inout' || w == 'ref' ||
                       w == 'bit' || w == 'logic' || w == 'reg') {
               // We're probably in the middle of some declaration, keep going.
               p_line--;
               _first_non_blank();
            } else {
               // This should be fine.
               //say('landed on kw');
               break;
            }
         } else {
            p_line--;
            _first_non_blank();
         }
      }
   }
}

void _verilog_snippet_find_leading_context(long selstart, long selend)
{
   _systemverilog_snippet_find_leading_context(selstart,selend);
}

void _systemverilog_new_language_options_sync(VS_LANGUAGE_OPTIONS& options)
{
   idx := find_index('_generic_new_language_options_sync', PROC_TYPE);
   if (idx > 0) {
      call_index(options, 'systemverilog', false, idx);
   }
}

void _verilog_new_language_options_sync(VS_LANGUAGE_OPTIONS& options)
{
   idx := find_index('_generic_new_language_options_sync', PROC_TYPE);
   if (idx > 0) {
      call_index(options, 'verilog', false, idx);
   }
}
