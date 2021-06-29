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
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "c.e"
#import "caddmem.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "notifications.e"
#import "pmatch.e"
#import "pushtag.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

static const VERILOG_LANGUAGE_ID=   'verilog';
static const VERILOG_IDENTIFIER_CHARS=  'A-Za-z0-9_$';

defeventtab verilog_keys;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;
def ' '=verilog_space;
def 'ENTER'=verilog_enter;


/**
 * Verilog header include path.
 *
 * @see def_verilog_parse_includes
 * @default ""
 * @categories Configuration_Variables
 */
_str def_verilog_include_path = "";
/**
 * Set to 'true' if the Verilog tagging parser recursively parse 
 * quoted include files that it can locate in the include path?
 * 
 * @see def_verilog_include_path
 * @default true
 * @categories Configuration_Variables
 */
bool def_verilog_parse_includes = true;


int _verilog_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "verilog", "", "", "", false, withRefs, useThread, forceRebuild);
}

_command void verilog_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(VERILOG_LANGUAGE_ID);
}

/*****************************************************************************/
static _str _re_verilog_parse = '[;()]|\b(always|begin|case([xz]|)|else|end(case|function|generate|module|primitive|specify|table|task|)|for(ever|k|)|function|generate|if|initial|join|module|primitive|repeat|specify|table|task|while)\b';

static int _verilog_find_matching_block_col()
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

bool seek_end_of_prev_nonblank_line()
{
   startLine := p_line;
   line      := '';

   while (p_line > 0) {
      p_line--;
      get_line(line);
      if (strip(line)._length() > 0) {
         _end_line();
         break;
      }
   }

   return p_line < startLine;
}


static _str ensure_supported_block_kw(_str kw)
{
   if (kw == 'if' || kw == 'for' || kw == 'while') {
      return kw;
   }

   return 'if';
}

_str associated_block_kw()
{
   kw := 'if';

   save_pos(auto pp);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   first_ch := get_text_raw();
   fca := _asc(first_ch);

   if (isspace(first_ch) || fca == 10 || fca == 13) {
      search('\S', '-@L');
   }

   cur_id := cur_identifier(auto start);
   if (cur_id != '') {
      p_col = start;
   }

   if (cur_id == 'end') {
      // Need to get to beginning of statement to figure out style.
      find_matching_paren(true);
      cur_id = cur_identifier(start);
      if (cur_id != '') {
         p_col = start;
      }
   }

   if (cur_id == 'begin') {
      search('\s', '-@L');
   }

   search('\S', '-@L');

   ch := get_text();

   if (ch == ')' && find_matching_paren(true) == 0) {
      left();
      if (search('\S', '-@L') == 0) {
         kw = cur_identifier(start);
      }
   }

   restore_search(s1, s2, s3, s4, s5);
   restore_pos(pp);

   return ensure_supported_block_kw(kw);
}

int associated_block_style()
{
   return beaut_style_for_keyword(associated_block_kw(), auto found);
}

static bool semi_before_block_kw() {
   save_pos(auto pp);
   begin_word();
   left();
   _clex_skip_blanks('-');

   found := get_text() == ';';
   restore_pos(pp);

   return found;
}

void maybe_reposition_block_delimiter()
{
   get_line(auto line);
   kw_idx := pos('(begin|end[a-z]*)\s*$', line, 1, 'L');
   curpos := _text_colc(p_col, 'P');
   kwBeforeCursor := curpos >= (pos('S1') + pos('1'));
    
   if (kw_idx > 0 && kwBeforeCursor) {
      kw := substr(line, pos('S1'),  pos('1'));
      alone := pos('^\s*(begin|end[a-z]*)\s*$', line, 1, 'L');

      if (kw == 'begin' && 
          (!beautify_on_edit()|| 
           semi_before_block_kw())) {
         return;
      }

      save_pos(auto pp);
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

      if (pos('end', kw) == 1) {
         if (alone) {
            // Always lined up with line the begin was on.
            search('\S+', 'L-@<');
            status := find_matching_paren(true);
            if (status == 0) {
               ind := _first_non_blank_col();
               restore_pos(pp);
               replace_line(indent_string(max(0, ind-1))kw);
               _end_line();
            } else {
               restore_pos(pp);
            }
         } else {
            // Don't move it if there's something else on the line with 'end'.
            restore_pos(pp);
         }
      } else if (kw == 'begin') {
         style := associated_block_style();

         if (alone) {
            if (style == BES_BEGIN_END_STYLE_1) {
               // This should not be on its own line, but should be joined
               // with the previous line.
               if (seek_end_of_prev_nonblank_line()) {
                  save_pos(auto join_pos);
                  restore_pos(pp);
                  _delete_line();
                  restore_pos(join_pos);
                  get_line(auto join_line);
                  replace_line(strip(join_line, 'T')' begin');
                  _end_line();
               } else {
                  restore_pos(pp);
               }

            } else {
               // Ok for styles 2 and 3 to be on their own line, so just make 
               // sure we get the indent right.
               if (seek_end_of_prev_nonblank_line()) {
                  idx := find_index('_'p_LangId'_indent_col', PROC_TYPE);
                  icol := call_index(p_SyntaxIndent, idx);
                  if (style == BES_BEGIN_END_STYLE_3) {
                     icol += p_SyntaxIndent;
                  }
                  restore_pos(pp);
                  replace_line(indent_string(max(0, icol - 1 - p_SyntaxIndent))'begin');
                  _end_line();
               } else {
                  restore_pos(pp);
               }
            }
         } else {
            // begin at end of line with other stuff.
            if (style != BES_BEGIN_END_STYLE_1) {
               // The begin should be on its own line.
               begStart := pos('\s*begin', line, 1, 'L');
               if (begStart > 0) {
                  begLen := line._length() - begStart;
                  style3Tax := (style == BES_BEGIN_END_STYLE_3) ? p_SyntaxIndent : 0;
                  begCol := _first_non_blank_col() + style3Tax;
                  replace_line(substr(line, 1, line._length() - begLen));
                  insert_blankline_below();
                  replace_line(indent_string(max(0, begCol-1))'begin');
                  _end_line();
               } else {
                  restore_pos(pp);
               }
            } else {
               // Style 1 should be on same line with statement that
               // introduced it, nothing to do.
               restore_pos(pp);
            }
         }
      }

      restore_search(s1, s2, s3, s4, s5);
   }
}

int _verilog_indent_col(int syntax_indent)
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
   status := search(_re_verilog_parse, "-rh@XSC");
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
         }
         status = repeat_search();
         continue;
      } else {
         if (nesting > 0) {
            status = repeat_search();
            continue;
         }

         keyword := get_match_text();
         switch (keyword) {
         case "always":
         case "else":
         case "for":
         case "forever":
         case "if":
         case "initial":
         case "while":
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            if (!hit_semi) {
               first_col = first_col + syntax_indent;
            }
            return (first_col);
         
         case "case":
         case "casex":
         case "casez":
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
            
         case "begin":
         case "fork":
         case "generate":
         case "specify":
         case "table":
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            return (first_col + syntax_indent);

         case "function":
         case "module":
         case "primitive":
         case "task":
            _first_non_blank();
            first_col = p_col;
            restore_pos(p);
            return (first_col + syntax_indent);

         case "end":
         case "endcase":
         case "endfunction":
         case "endgenerate":
         case "endmodule":
         case "endprimitive":
         case "endspecify":
         case "endtable":
         case "endtask":
         case "join":
            first_col = _verilog_find_matching_block_col();
            restore_pos(p);
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

bool _verilog_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;

   maybe_reposition_block_delimiter();

   int col = _verilog_indent_col(SyntaxIndent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void verilog_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   generic_enter_handler(_verilog_expand_enter);
}
bool _verilog_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

/*****************************************************************************/

static SYNTAX_EXPANSION_INFO _Keywords:[] = {
   'always'       => { 'always' },
   'and'          => { 'and' },
   'assign'       => { 'assign' },
   'begin'        => { 'begin ... end' },
   'buf'          => { 'buf' },
   'bufif0'       => { 'bufif0' },
   'bufif1'       => { 'bufif1' },
   'case'         => { 'case ... endcase' },
   'casex'        => { 'casex ... endcase' },
   'casez'        => { 'casez ... endcase' },
   'cmos'         => { 'cmos' },
   'deassign'     => { 'deassign' },
   'default'      => { 'default' },
   'defparam'     => { 'defparam' },
   'disable'      => { 'disable' },
   'edge'         => { 'edge' },
   'else'         => { 'else' },
   'end'          => { 'end' },
   'endcase'      => { 'endcase' },
   'endfunction'  => { 'endfunction' },
   'endmodule'    => { 'endmodule' },
   'endprimitive' => { 'endprimitive' },
   'endspecify'   => { 'endspecify' },
   'endtable'     => { 'endtable' },
   'endtask'      => { 'endtask' },
   'event'        => { 'event' },
   'for'          => { 'for' },
   'force'        => { 'force' },
   'forever'      => { 'forever begin ... end' },
   'fork'         => { 'fork' },
   'function'     => { 'function ... endfunction' },
   'generate'     => { 'generate ... endgenerate' },
   'highz0'       => { 'highz0' },
   'highz1'       => { 'highz1' },
   'if'           => { 'if ()' },
   'initial'      => { 'initial' },
   'inout'        => { 'inout' },
   'input'        => { 'input' },
   'integer'      => { 'integer' },
   'join'         => { 'join' },
   'large'        => { 'large' },
   'macromodule'  => { 'macromodule' },
   'medium'       => { 'medium' },
   'module'       => { 'module ... endmodule' },
   'nand'         => { 'nand' },
   'negedge'      => { 'negedge' },
   'nmos'         => { 'nmos' },
   'nor'          => { 'nor' },
   'not'          => { 'not' },
   'notif0'       => { 'notif0' },
   'notif1'       => { 'notif1' },
   'or'           => { 'or' },
   'output'       => { 'output' },
   'parameter'    => { 'parameter' },
   'pmos'         => { 'pmos' },
   'posedge'      => { 'posedge' },
   'primitive'    => { 'primitive ... endprimitive' },
   'pull0'        => { 'pull0' },
   'pull1'        => { 'pull1' },
   'pulldown'     => { 'pulldown' },
   'pullup'       => { 'pullup' },
   'rcmos'        => { 'rcmos' },
   'reg'          => { 'reg' },
   'release'      => { 'release' },
   'repeat'       => { 'repeat' },
   'rnmos'        => { 'rnmos' },
   'rpmos'        => { 'rpmos' },
   'rtran'        => { 'rtran' },
   'rtranif0'     => { 'rtranif0' },
   'rtranif1'     => { 'rtranif1' },
   'scalared'     => { 'scalared' },
   'small'        => { 'small' },
   'specify'      => { 'specify ... endspecify' },
   'specparam'    => { 'specparam' },
   'strength'     => { 'strength' },
   'strong0'      => { 'strong0' },
   'strong1'      => { 'strong1' },
   'supply0'      => { 'supply0' },
   'supply1'      => { 'supply1' },
   'table'        => { 'table ... endtable' },
   'task'         => { 'task ... endtask' },
   'time'         => { 'time' },
   'tran'         => { 'tran' },
   'tranif0'      => { 'tranif0' },
   'tranif1'      => { 'tranif1' },
   'tri'          => { 'tri' },
   'tri0'         => { 'tri0' },
   'tri1'         => { 'tri1' },
   'triand'       => { 'triand' },
   'trior'        => { 'trior' },
   'trireg'       => { 'trireg' },
   'vectored'     => { 'vectored' },
   'wait'         => { 'wait' },
   'wand'         => { 'wand' },
   'weak0'        => { 'weak0' },
   'weak1'        => { 'weak1' },
   'while'        => { 'while ()' },
   'wire'         => { 'wire' },
   'wor'          => { 'wor' },
   'xnor'         => { 'xnor' },
   'xor'          => { 'xor' },
};

static _str _verilog_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;

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

   // Look for labeled statements (e.g. label_xyz : statement)
   label_col := 0;
   _str rest=line;
   if( pos(':=',line) ) {
      // Variable assignment
      return(1);   // Fall through to space bar key
   } else if( pos('[ \t]@'VERILOG_IDENTIFIER_CHARS'[ \t]@\:',line,1,'er') ) {
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
   verilogword=min_abbrev2(PartialWord,_Keywords,'',aliasfilename);

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
   doNotify := true;
   if ( verilogword=='begin' ) {
      replace_line(line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width)'end');
         set_surround_mode_end_line();
         up(1);
      } else doNotify = (line != orig_line);

      _end_line();
      ++p_col;
   } else if (verilogword=='generate' || 
              verilogword=='module' || 
              verilogword=='function' ||
              verilogword=='task' ||
              verilogword=='primitive' ||
              verilogword=='table') {
      replace_line(line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width)'end'verilogword);
         up(1);
      } else doNotify = (line != orig_line);

      _end_line();
      ++p_col;
   } else if (verilogword=='forever') {
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         replace_line(line' begin');
         insert_line(indent_string(width)'end');
         set_surround_mode_end_line();
         up(1);
      } else {
         replace_line(line);
         doNotify = (line != orig_line);
      }

      _end_line();
      ++p_col;
   } else if( verilogword=='if' ||
              verilogword=='while') {
      replace_line(line' () ');
      end_line();
      add_hotspot();
      left(); left();
      add_hotspot();
   } else if (verilogword=='case' || verilogword=='casex' || verilogword=='casez') {
      replace_line(line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width)'endcase');
         set_surround_mode_end_line();
         up(1);
      } else doNotify = (line != orig_line);

      _end_line();
      ++p_col;
   } else if (verilogword=='specify') {
      replace_line(line);
      if( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
         insert_line(indent_string(width)'endspecify');
         set_surround_mode_end_line();
         up(1);
      } else doNotify = (line != orig_line);

      _end_line();
      ++p_col;
   } else {
      // Word is aleady expanded, just add a space
      replace_line(line' ');
      _end_line();
      doNotify = (line != orig_line);
   }

   show_hotspots();

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return 0;
}

_command verilog_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   // Short-circuit "if" operator in action here!
   if( command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)        ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is SyntaxIndent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _verilog_expand_space()
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

int _verilog_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, _Keywords, prefix, min_abbrev);
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
int _verilog_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator,idexp_info, visited, depth);
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
 * function {@link _verilog_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
static int _verilog_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                                       struct VS_TAG_RETURN_TYPE &rt, 
                                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_type_of_prefix(errorArgs,prefixexp,rt,visited, depth);
}

/**
 * <B>Hook Function</B> -- _[ext]_find_context_tags
 * <P>
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link _verilog_get_expression_info()}.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _verilog_get_expression_info}
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
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _verilog_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                               _str lastid,int lastidstart_offset,
                               int info_flags,typeless otherinfo,
                               bool find_parents,int max_matches,
                               bool exact_match,bool case_sensitive,
                               SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                               SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                               VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_verilog_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // only look for functions if identifier if followed by a paren
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         _CodeHelpListLabels(0, 0, lastid, '',
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth+1);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // find more details about the current tag
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class, auto cur_package,
                                         visited, depth+1);

   // evaluate the prefix expression to get the effective class name
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp!='') {
      int status = _verilog_get_type_of_prefix(errorArgs, prefixexp, rt);
      if (status) {
         return status;
      }
      prefix_rt = rt;
   }

   // try to match the symbol in the current context
   tag_clear_matches();
   num_matches := 0;
   context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      context_flags &= ~SE_TAG_CONTEXT_ALLOW_LOCALS;
   }

   context_list_flags := SE_TAG_CONTEXT_FIND_ALL;
   if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
      context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
   }
   tag_list_symbols_in_context(lastid, rt.return_type, 
                               0, 0, tag_files, '',
                               num_matches, max_matches,
                               filter_flags,context_flags|context_list_flags,
                               exact_match, true, visited, depth+1, rt.template_args);
   // try case insensitive match
   if (num_matches == 0 && !case_sensitive) {
      tag_list_symbols_in_context(lastid, rt.return_type, 
                                  0, 0, tag_files, '',
                                  num_matches, max_matches,
                                  filter_flags,context_flags|context_list_flags,
                                  exact_match, case_sensitive, visited, depth+1, rt.template_args);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
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
int _verilog_fcthelp_get_start(_str (&errorArgs)[],
                               bool OperatorTyped,
                               bool cursorInsideArgumentList,
                               int &FunctionNameOffset,
                               int &ArgumentStartOffset,
                               int &flags,
                               int depth=0)
{
   // TBF
   return _c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,
                               FunctionNameOffset,ArgumentStartOffset,flags,
                               depth);
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
int _verilog_fcthelp_get(_str (&errorArgs)[],
                         VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                         bool &FunctionHelp_list_changed,
                         int &FunctionHelp_cursor_x,
                         _str &FunctionHelp_HelpWord,
                         int FunctionNameStartOffset,
                         int flags,
                         VS_TAG_BROWSE_INFO symbol_info=null,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // TBF
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
 * <B>Hook function</B> -- _[lang]_get_decl
 * <P>
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
_str _verilog_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                       _str decl_indent_string="",
                       _str access_indent_string="")
{
   // TBF
   return _c_get_decl(lang,info,flags,decl_indent_string,access_indent_string);
}

/**
 * Verilog <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int verilog_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent = p_SyntaxIndent;
   _begin_select(); up(); _end_line();
   int col = _verilog_indent_col(syntax_indent);
   return col;
}

bool _verilog_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}
