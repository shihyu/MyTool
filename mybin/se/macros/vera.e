////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50341 $
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
#include 'slick.sh'
#include 'tagsdb.sh'
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "c.e"
#import "caddmem.e"
#import "ccontext.e"
#import "codehelp.e"
#import "cutil.e"
#import "pmatch.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "main.e"
#import "notifications.e"
#import "seek.e"
#import "csymbols.e"
#import "box.e"
#import "clipbd.e"
#import "commentformat.e"
#import "context.e"
#import "markfilt.e"
#import "hotspots.e"
#endregion

using se.lang.api.LanguageSettings;

#define VERA_LANG_ID    'vera'
#define VERA_MODE_NAME  'Vera'
#define VERA_LEXERNAME  'Vera'
#define VERA_WORDCHARS  'A-Za-z0-9_'

defload()
{
   _str setup_info='MN='VERA_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='VERA_LANG_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='VERA_WORDCHARS',LN='VERA_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 4 1 0';
   _str be_info='';
   _CreateLanguage(VERA_LANG_ID, VERA_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("vr", VERA_LANG_ID);
   _CreateExtension("vrh", VERA_LANG_ID);
   _CreateExtension("vri", VERA_LANG_ID);
   LanguageSettings.setAutoBracket('vera', AUTO_BRACKET_ENABLE|AUTO_BRACKET_PAREN|AUTO_BRACKET_BRACKET|AUTO_BRACKET_DOUBLE_QUOTE|AUTO_BRACKET_BRACE);
}

defeventtab vera_keys;
def '('=vera_paren;
def '.'=auto_codehelp_key;
def ' '= vera_space;
def 'ENTER'=vera_enter;
def '{'= vera_beginbrace;
def '}'= vera_endbrace;
def tab= smarttab;

int _vera_MaybeBuildTagFile(int &tfindex)
{
   return ext_MaybeBuildTagFile(tfindex,'vera','vera','Vera Built-ins');
}

_command void vera_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(VERA_LANG_ID);
}

#define VERA_EXPAND_WORDS (' #define #elif #else #endif #error #if #ifdef #ifndef':+\
                ' #include #pragma #undef class constraint coverage_group default else enum':+\
                ' function integer interface program port rand randc typedef static task' :+\
                ' public protected ')

static SYNTAX_EXPANSION_INFO vera_keywords:[] = {
   '#define'          => { "#define" },
   '#elif'            => { "#elif" },
   '#else'            => { "#else" },
   '#endif'           => { "#endif" },
   '#error'           => { "#error" },
   '#if'              => { "#if" },
   '#ifdef'           => { "#ifdef" },
   '#ifndef'          => { "#ifndef" },
   '#include'         => { "#include" },
   '#pragma'          => { "#pragma" },
   '#undef'           => { "#undef" },
   'break'            => { "break;" },
   'case'             => { "case ( ... ) { ... }" },
   'casex'            => { "casex ( ... ) { ... }" },
   'casez'            => { "casez ( ... ) { ... }" },
   'class'            => { "class { ... }" },
   'constraint'       => { 'constraint { ... }' },
   'continue'         => { "continue;" },
   'coverage_group'   => { 'coverage_group { ... }' },
   'default'          => { "default" },
   'do'               => { "do { ... } while ( ... );" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'enum'             => { "enum" },
   'for'              => { 'for ( ... )' },
   'foreach'          => { 'foreach ( ... ) ' },
   'function'         => { 'function ( ... ) { ... }' },
   'integer'          => { 'integer' },
   'interface'        => { 'interface { ... }' },
   'if'               => { 'if ( ... )' },
   'protected'        => { "protected" },
   'public'           => { "public" },
   'program'          => { 'program { ... }' },
   'port'             => { 'port { ... }' },
   'rand'             => { "rand" },
   'randc'            => { "randc" },
   'randseq'          => { "randseq ( ... ) { ... }" },
   'randcase'         => { "randcase { ... }" },
   'repeat'           => { "repeat ( ... )" },
   'task'             => { 'task ( ... ) { ... }' },
   'typedef'          => { "typedef" },
   'while'            => { "while ( ... )" },
};

static void vera_insert_braces(int syntax_indent,int be_style,int width)
{
   if ( be_style == BES_BEGIN_END_STYLE_3 ) {
      width=width+syntax_indent;
   }
   if ( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
      int up_count=1;
      if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
         up_count=up_count+1;
         insert_line(indent_string(width)'{');
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
         up_count=up_count+1;
         if (be_style == BES_BEGIN_END_STYLE_3) {
            insert_line(indent_string(width));
         } else {
            insert_line(indent_string(width+syntax_indent));
         }
      }
      insert_line(indent_string(width)'}');
      up(up_count);
   }
}

int _vera_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, vera_keywords, prefix, min_abbrev);
}

_command void vera_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if( command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       vera_expand_space()) {
      if( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if( _argument=='' ) {
      _undo('S');
   }
}
static void maybe_insert_braces(boolean noSpaceBeforeParen, boolean insertBraceImmediately, int width,
                                _str word,boolean no_close_brace=false)
{
   int col=width+length(word)+3;
   updateAdaptiveFormattingSettings(AFF_PAD_PARENS | AFF_NO_SPACE_BEFORE_PAREN);
   // do this extra check because we might have forced in the no space before paren setting in c_expand_space
   if ( noSpaceBeforeParen ) --col;
   if ( p_pad_parens ) ++col;
   if ( p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
      width=width+p_SyntaxIndent;
   }
   if ( insertBraceImmediately ) {
      int up_count=1;
      if ( p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
         up_count=up_count+1;
         insert_line(indent_string(width)'{');
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
         up_count=up_count+1;
         if ( p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            insert_line(indent_string(width));
         } else {
            insert_line(indent_string(width+p_SyntaxIndent));
         }
      }
      _end_line();
      add_hotspot();
      if (no_close_brace) {
         up_count--;
      } else {
         insert_line(indent_string(width)'}');
         set_surround_mode_end_line();
      }
      up(up_count);
   }
   p_col=col;
   if ( ! _insert_state() ) _insert_toggle();
}
static int vera_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);

   int status=0;
   _str orig_line='';
   get_line(orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word=strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   set_surround_mode_start_line();
   boolean open_paren_case=(last_event()=='(');
   boolean semicolon_case=(last_event()==';');
   boolean if_special_case=false;
   boolean else_special_case=false;
   boolean pick_else_or_else_if=false;
   _str brace_before='';
   _str aliasfilename='';
   _str word='';
   word=min_abbrev2(orig_word,vera_keywords,name_info(p_index),
                    aliasfilename,!open_paren_case,open_paren_case);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=='') {
      // Check for } else
      _str first_word, second_word, rest;
      parse orig_line with first_word second_word rest;
      if (!def_always_prompt_for_else_if && first_word=='}' && second_word!='' && rest=='' && second_word=='else') {
         //Can't force user to use modal dialog insead of just typing "} else {"
         //We need a modeless dialog so user can keep typing.
         return(1);
      } else if (!def_always_prompt_for_else_if && second_word=='' && length(first_word)>1 && first_word:=='}else') {
         //Can't force user to use modal dialog insead of just typing "}else {"
         //We need a modeless dialog so user can keep typing.
         return(1);
      } else if (first_word=='}' && second_word!='' && rest=='' && second_word:==substr('else',1,length(second_word))) {
         brace_before='} ';
         first_word=second_word;
         pick_else_or_else_if=true;
      } else if (second_word=='' && length(first_word)>1 && first_word:==substr('}else',1,length(first_word))) {
         brace_before='}';
         first_word=substr(first_word,2);
         pick_else_or_else_if=true;
      } else if (first_word=='else' && orig_word==substr('else if',1,length(orig_word))) {
         word='else if';
         if_special_case=true;
      } else if (second_word=='else' && rest!='' && orig_word==substr('} else if',1,length(orig_word))) {
         word='} else if';
         if_special_case=true;
      } else if (first_word=='}else' && second_word!='' && orig_word==substr('}else if',1,length(orig_word))) {
         word='}else if';
         if_special_case=true;
      } else {
         return(1);
      }
   } else if (!def_always_prompt_for_else_if && orig_word=='else' && word=='else') {
      //Can't force user to use modal dialog insead of just typing "}else {"
      //We need a modeless dialog so user can keep typing.
      return(1);
   } else if (orig_word=='else' && word=='else') {
      pick_else_or_else_if=true;
   }
   //_message_box('h1 if_special_case='if_special_case);
   if (pick_else_or_else_if) {
      word=min_abbrev2('els',vera_keywords,name_info(p_index),'');
      switch (word) {
      case 'else':
         word=brace_before:+word;
         else_special_case=true;
         break;
      case 'elseif':
      case 'else if':
         word=brace_before:+word;
         if_special_case=true;
         break;
      default:
         return(1);
      }
   }

   // special case for open parenthesis (see c_paren)
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   noSpaceBeforeParen := p_no_space_before_paren;
   if ( open_paren_case ) {
      noSpaceBeforeParen = true;
      if ( length(word) != length(orig_word) ) {
         return 1;
      }
      switch ( word ) {
      case 'if':
      case 'while':
      case 'repeat':
      case 'for':
      case 'foreach':
      case 'else if':
      case 'case':
      case 'casex':
      case 'casez':
      case 'randseq':
         break;
      default:
         return 1;
      }
   } 

   // special case for semicolon
   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   if ( semicolon_case ) {
      insertBraceImmediately = false;
      if ( length(word) != length(orig_word) ) {
         return 1;
      }
      switch ( word ) {
      case 'if':
      case 'while':
      case 'repeat':
      case 'case':
      case 'casex':
      case 'casez':
      case 'randseq':
      case 'for':
      case 'foreach':
      case 'else if':
         break;
      default:
         return 1;
      }
   }

   // if they type the whole keyword and then space, ignore
   // the "no space before paren" option, always insert the space
   // 11/30/2006 - rb
   // Commented out because the user (me) could have trained themself to
   // type 'if<SPACE>' in order to get an expanded if-statement. This would
   // have always put the SPACE in regardless of the "no space before paren"
   // option.
   //if ( word == orig_word && last_event() :== ' ') {
   //   be_style &= ~VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN;
   //}

   clear_hotspots();
   _str maybespace=(noSpaceBeforeParen)?'':' ';
   _str parenspace=(p_pad_parens)? ' ':'';
   _str bracespace=' ';
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   style2 := p_begin_end_style == BES_BEGIN_END_STYLE_2;
   style3 := p_begin_end_style == BES_BEGIN_END_STYLE_3;
   _str e1=' {';
   if (! ((word=='do') && !style2 && !style3) ) {
      if ( style2 || style3 || !insertBraceImmediately ) {
         e1='';
      } else if (word=='}else') {
         e1='{';
      }
   } else if (last_event()=='{') {
      e1='{';
      bracespace='';
   }
   if (semicolon_case) e1=' ;';

   doNotify := true;
   if ( word=='if' || word=='else if' || if_special_case) {
      replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word));
      add_hotspot();
   } else if ( word=='else') {
      typeless p;
      typeless s1,s2,s3,s4;
      save_pos(p);
      save_search(s1,s2,s3,s4);
      up();_end_line();
      search('[^ \t\n\r]','@-rhXc');
      if (get_text()=='}') {
         insertBraceImmediately = true;
      } else {
         e1=' ';
         insertBraceImmediately = false;
      }
      restore_search(s1,s2,s3,s4);
      restore_pos(p);

      newLine := line :+ e1;
      replace_line(newLine);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      _end_line();

      doNotify = (newLine != orig_line) || insertBraceImmediately;
   } else if ( else_special_case) {
      replace_line(line:+e1);
      maybe_insert_braces(noSpaceBeforeParen, true, width,word);
      _end_line();
   } else if ( word=='for' || word=='foreach') {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
   } else if ( word=='task' || word=='function') {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
      left();
   } else if ( word=='class' || word=='coverage_group' || word=='program' || word=='constraint' || word=='port' || word=='interface') {
      newLine := line:+e1;
      replace_line(newLine);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
      left();

      doNotify = (newLine != orig_line || insertBraceImmediately);
   }else if ( word=='while' || word=='repeat') {
      if (c_while_is_part_of_do_loop()) {
         replace_line(line:+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;
         if (p_pad_parens) --p_col;
      } else {
         replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
         maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
         add_hotspot();
      }
   } else if ( word=='case' || word=='casex' || word=='casez' || word=='randseq') {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
   } else if ( word=='do' ) {
      insertBraceImmediately=true;  // This doesn't work well if this is turned off!
      // Always insert braces for do loop unless braces are on separate
      // line from do and while statements
      int num_end_lines=1;
      replace_line(line:+e1);
      if ( ! style3 ) {
         if (style2 ) {
            insert_line(indent_string(width)'{');
         }
         insert_line(indent_string(width)'}'bracespace'while':+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;

         updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
         if (p_pad_parens) p_col--;
         add_hotspot();
         up();
      } else if ( style3 ) {
         if (insertBraceImmediately) {
            num_end_lines=2;
            insert_line(indent_string(width+syntax_indent)'{');
            insert_line(indent_string(width+syntax_indent)'}');
            insert_line(indent_string(width)'while':+maybespace'('parenspace:+parenspace');');
            _end_line();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(2);
            //syntax_indent=0;
         } else {
            insert_line(indent_string(width)'while'maybespace:+'('parenspace:+parenspace');');
            _end_line();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            //add_hotspot();
            up(1);
            //syntax_indent=0
         }
      }
      if (insertBraceImmediately) {
         nosplit_insert_line();
         set_surround_mode_end_line(p_line+1, num_end_lines);
         p_col=width+syntax_indent+1;
      } else {
         _end_line();++p_col;
      }
      if (insertBraceImmediately) {
         add_hotspot();
      }
   } else if ( word=='randcase' ) {
      if (!insertBraceImmediately) {
         replace_line(line);_end_line();p_col=p_col+1;
      } else {
         // Always insert braces for do loop unless braces are on separate
         // line from do and while statements
         int num_end_lines=1;
         newLine := line:+e1;
         replace_line(newLine);
         if ( ! style3 ) {
            if (insertBraceImmediately) {
               if (style2 ) {
                  insert_line(indent_string(width)'{');
               }
               insert_line(indent_string(width)'}');
            }
            _end_line();
            p_col -= 2;

            if (insertBraceImmediately) {
               add_hotspot();
               up();
            }
         } else if ( style3 ) {
            if (insertBraceImmediately) {
               num_end_lines=2;
               insert_line(indent_string(width+syntax_indent)'{');
               insert_line(indent_string(width+syntax_indent)'}');
               _end_line();
               add_hotspot();
               up(1);

            } else {
               insert_line(indent_string(width));
               _end_line();
               p_col -= 2;
               up(1);
            }
         }
         nosplit_insert_line();
         set_surround_mode_end_line(p_line+1, num_end_lines);
         p_col=width+syntax_indent+1;
         add_hotspot();

         doNotify = (newLine != orig_line || insertBraceImmediately);
      }
   } else if ( word=='continue' || word=='break' ) {
      replace_line(indent_string(width)word';');
      _end_line();
   // BUG: Expansions for 'function', 'task', and 'class' are
   // not being expanded. Is min_abbrev2 not returning the 
   // correct value? 
   } else if ( pos(' 'word' ',VERA_EXPAND_WORDS) ) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();

      doNotify = (newLine != orig_line);
   } else {
     status=1;
     doNotify = false;
   }
   if (semicolon_case) {
      orig_col := p_col;
      _end_line();
      left();
      add_hotspot();
      p_col = orig_col;
   }
   show_hotspots();

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if (open_paren_case) {
      AutoBracketCancel();
   }
   return(status);
}

enum {
   VERA_INDENT_SAW_STATEMENT  = 0x0001,
   VERA_INDENT_SAW_BRACES     = 0x0002,
   VERA_INDENT_SAW_KEYWORD    = 0x0004,
};

static int _vera_indent_col(int syntax_indent, int be_style, int indent_fl)
{
   int orig_linenum = p_line;
   int orig_col = p_col;
   typeless s1, s2, s3, s4, s5;
   typeless p, p1;
   int col;
   int indent_state = 0;
   save_pos(p); p1 = p;
   _str line = "";
   left(); _clex_skip_blanks('-');
   int status = search('[;{}()]|\b(if|else|randcase|rand|randseq|fork|join|case|for|foreach|while|repeat)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      _str word = get_match_text();
      int cfg = _clex_find(0,'g');
      col = p_col;
      if (cfg == CFG_KEYWORD) {
         if (!indent_state) {
            first_non_blank();
            col = p_col + syntax_indent;
            restore_pos(p);
            return(col);
         }
         if (indent_state & (VERA_INDENT_SAW_STATEMENT|VERA_INDENT_SAW_BRACES)) {
            indent_state &= ~(VERA_INDENT_SAW_STATEMENT|VERA_INDENT_SAW_BRACES);
         }
         indent_state |= VERA_INDENT_SAW_KEYWORD; 
         save_pos(p1);

      } else if (indent_state & VERA_INDENT_SAW_KEYWORD) {
         switch (word) {
         case ')':
            save_search(s1, s2, s3, s4, s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(0);
            }
            break;
         default:
            restore_pos(p1);
            first_non_blank();
            col = p_col;
            restore_pos(p);
            return(col);
         }
      } else {
         switch (word) {
         case '(':
            restore_pos(p);
            return(0);
   
         case ')':
            save_search(s1, s2, s3, s4, s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(0);
            }
            break;
   
         case '{':
            if (indent_state & VERA_INDENT_SAW_BRACES) {
               restore_pos(p1);
               first_non_blank();
               col = p_col;
            } else {
               if (indent_state & VERA_INDENT_SAW_STATEMENT) {
                  col = 0;
               } else { 
                  first_non_blank();
                  if (be_style == BES_BEGIN_END_STYLE_3) {
                     col = p_col;
                  } else {
                     col = p_col + syntax_indent;
                  }
               }
            }
            restore_pos(p);
            return(col);
            
         case '}':
            if (indent_state & (VERA_INDENT_SAW_BRACES|VERA_INDENT_SAW_STATEMENT)) {
               restore_pos(p1);
               first_non_blank();
               col = p_col;
               restore_pos(p);
               return(col);
            }
            save_search(s1, s2, s3, s4, s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(0);
            }
            save_pos(p1);
            indent_state |= VERA_INDENT_SAW_BRACES;
            break;
   
         case ';':
            if (indent_state & VERA_INDENT_SAW_BRACES) {
               restore_pos(p1);
               first_non_blank();
               col = p_col;
               restore_pos(p);
               return(col);
            }
            if (indent_state & VERA_INDENT_SAW_STATEMENT) {
               restore_pos(p);
               return(0);
            }
            save_pos(p1);
            indent_state |= VERA_INDENT_SAW_STATEMENT;
            break;
         }

      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

boolean _vera_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   int indent_case = -1;
 
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   if (_in_c_preprocessing()) {
      restore_pos(p);
      return(true);
   }
   int begin_col=vera_begin_stat_col(false /* No RestorePos */,
                                  false /* Don't skip first begin statement marker */,
                                  false /* Don't return first non-blank */,
                                  1  /* Return 0 if no code before cursor. */,
                                  false,
                                  1
                                  );
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(true);
   }
   int status=0;
   boolean LineEndsWithBrace=false;
   int java=0;
   if (p_line>orig_linenum) {
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanksNpp("-");
      LineEndsWithBrace= (orig_linenum==p_line && get_text()=='{');
      first_non_blank();
   } else if (p_line==orig_linenum && begin_col<0) {
      LineEndsWithBrace= (orig_linenum==p_line && get_text()=='{');
      first_non_blank();
   }
   int col=0,first_word_col=p_col;
   int junk=0;
   _str first_word=cur_word(junk);
   int first_word_color=_clex_find(0,'g');
   _str cur_line, line, orig_line;
   get_line_raw(cur_line);
   boolean BeginningOfStatementOnSameLine=(orig_linenum==p_line);
   restore_pos(p);
   enter_cmd=name_on_key(ENTER);
   if ( expand && BeginningOfStatementOnSameLine &&
        !(_expand_tabsc(orig_col)!="" &&
          (_will_split_insert_line()
          )
        ) &&
        first_word_color==CFG_KEYWORD
        ) {
      if ( first_word=='for' && name_on_key(ENTER):=='nosplit-insert-line' ) {
         if ( name_on_key(ENTER):=='nosplit-insert-line' ) {
            /* tab to fields of C for statement */
            p_col=orig_col;
            line=expand_tabs(cur_line);
            int semi1_col=pos(';',line,p_col,p_rawpos);
            if ( semi1_col>0 && semi1_col>=p_col ) {
               p_col=semi1_col+1;
            } else {
               int semi2_col=pos(';',line,semi1_col+1,p_rawpos);
               if ( (semi2_col>0) && (semi2_col>=p_col) ) {
                  p_col=semi2_col+1;
               } else {
                  status=1;
               }
            }
         } else {
            status=1;
         }
      /*} else if ( (first_word=='case' || first_word=='default') &&
                 (orig_col>first_word_col ||
                  enter_cmd=='nosplit-insert-line') ) {
         _str eol='';
         if (indent_case<0) {
            updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
            indent_case=(int)p_indent_case_from_switch;
         }
         if( _will_split_insert_line() ){
            get_line_raw(orig_line);
            eol=expand_tabs(orig_line,p_col,-1,'s');
            replace_line_raw(expand_tabs(orig_line,1,p_col-1,'s'));
         }
         /* Indent case based on indent of switch. */
         col=_c_last_switch_col();
         if ( col && eol:=='') {
            if ((indent_case && indent_case!='') || (be_style == BES_BEGIN_END_STYLE_3)) {
               col=col+syntax_indent;
            }
            replace_line_raw(indent_string(col-1):+""strip(cur_line,'L'));
            _end_line();
         }
         indent_on_enter(syntax_indent);
         if (eol:!='') {
            replace_line_raw(indent_string(p_col-1):+eol);
         }*/
      /*} else if ( first_word=='switch' && LineEndsWithBrace) {
         if (indent_case<0) {
            updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
            indent_case=(int)p_indent_case_from_switch;
         }
         down();
         get_line_raw(line);
         up();
         int extra_case_indent=0;
         if ((indent_case && indent_case!='') || (be_style&VS_C_OPTIONS_STYLE2_FLAG)) {
            extra_case_indent=syntax_indent;
         }
         if ( pos('}',line,1,p_rawpos) > 0 ) {
            indent_on_enter(syntax_indent);
            get_line_raw(line);
            if ( line=='' ) {
               col=p_col-syntax_indent;
               replace_line_raw(indent_string(col-1+extra_case_indent)'case ');
               _end_line();
               c_maybe_list_args(true);
            }
         } else {
            indent_on_enter(syntax_indent);
            get_line_raw(line);
            if ( line=='' ) {
               col=p_col-syntax_indent;
               replace_line_raw(indent_string(col-1+extra_case_indent)'case ');
               _end_line();
               c_maybe_list_args(true);
            }
         }
      */ 
      } else if (first_word=='join') {
         first_non_blank();auto new_col=p_col;p_col=orig_col;
         indent_on_enter(0,new_col);
         return(false);
     } else {
       status=1;
     }
   } else {
     status=1;
   }
   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      col=vera_indent_col2(0,0);
      indent_on_enter(0,col);
   }
   return(status != 0);
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
   int begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                       false /* Don't skip first begin statement marker */,
                                       true  /* Don't return first non-blank */
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
      int status=_clex_skip_blanksNpp("-");
      if (status) {
         restore_pos(p);
         return(orig_col);
      }
      _str ch=get_text();
      if (ch:==")") {
         restore_pos(p);
         return(begin_stat_col);
      }
      restore_pos(p2);
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
         restore_pos(p);
         return(col);
      }
      int nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
   }
   restore_pos(p);
   get_line(auto line);
   line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   first_non_blank();
   int col=p_col;
   restore_pos(p);
   return(col);
}
static boolean _isVarInitList(boolean checkEnum=false)
{
   /*
      Check for the array/struct initialization case by
      check for equal sign before open brace.  This won't
      work if preprocessing is present.

        int array[]={
           a,
           b,<ENTER>
           int a,
           b,
           c,


      object array[]={
         "a","b",
         "c",{"a",
            "b","c"
         }
      };

      also check for enum declaration like
         enum {
           a,
           b,
      or
         enum XXX {
            a,
            b,


   */
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   _clex_skip_blanksNpp('-');
   int cfg=_clex_find(0,'g');
   int junk;
   boolean in_init=(get_text()=='=' || get_text()==']' ||
                    get_text()==',' || get_text()=='{' ||
                    (checkEnum && cfg==CFG_KEYWORD && cur_word(junk)=='enum'));
   //messageNwait('ch='get_text()' in_init='in_init);

   word_chars := _clex_identifier_chars();
   if (!in_init && checkEnum && cfg==CFG_WINDOW_TEXT &&
       pos('['word_chars']',get_text(),1,'r')) {

      int status=search("[^"word_chars"]","@-Rh");
      if (!status) {
         _clex_skip_blanksNpp('-');
         if (_clex_find(0,'g')==CFG_KEYWORD && cur_word(junk)=='enum') {
            in_init=1;
         }
      }
   }
   return(in_init);
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
   int begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                       false /* Don't skip first begin statement marker. */,
                                       false /* Don't return first non-blank */,
                                       false,
                                       false,
                                       1   // Fail if no text after cursor
                                       );
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
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
      _clex_skip_blanksNpp("-");
      _str ch=get_text();
      if (ch:==")") {
         return(begin_stat_col);
      }
      if (orig_ch:=='}' && ch:==',' && statdelim_linenum==p_line) {
         /*
             Also check if this line ends with a comma and handle the
             case where the user is in a declaration list like
             the following.

             MYSTRUCT array[]={
                {a,b,c},<ENTER>
                a,
                {a,b,c},<ENTER>
                {a,b,c},a,b,<ENTER>
                {a,{a,b,c}},<ENTER>
                d,
                {a,
                 {a,b,c}},
                 x,<ENTER>
                },
                b,
         */
         restore_pos(orig_pos);
         int status=_find_matching_paren(def_pmatch_max_diff);
         if (!status) {
            first_non_blank();
            return(p_col);
         }
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
static boolean _isQmarkExpression(_str more_charset_re='')
{
   // cursor is sitting colon
   /*
      could have
             (c)?s:t,
             with abc:<enter>
            a::mytype var

            default :
            'a':
            ('a'+'b')-1:
    
      Give up on } for now.
   */
   int status=search('[?;})]|default|with','-@rhxcs');
   for (;;) {
      if (status) {
         return(false);
      }
      switch(get_match_text()) {
      case '?':
         return(true);
      case ';':
      case '}':
         return(false);
      case ')':
         status=find_matching_paren(true);
         if (status) {
            return(false);
         }
         status=repeat_search();
         continue;
      default:
         if (_clex_find(0,'g')==CFG_KEYWORD) {
            //status=repeat_search();
            return(false);
         }
         return(false);
      }
   }
}
static int vera_indent_col2(int non_blank_col,boolean pasting_open_block)
{
   int orig_col=p_col;
   int orig_linenum=p_line;
   int orig_embedded=p_embedded;
   int col=orig_col;
   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   be_style := p_begin_end_style;
   UseContOnParameters := LanguageSettings.getUseContinuationIndentOnFunctionParameters(p_LangId);
   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   boolean style3=be_style == BES_BEGIN_END_STYLE_3;

   if (pasting_open_block) {
      // Look for for,while,switch
      save_pos(auto p2);
      col= find_block_col();
      restore_pos(p2);
      if (col) {
         restore_pos(p);
         if (style3) {
            return(col+syntax_indent);
         }
         return(col);
      }
      /*
          Note:
             pasting open brace does not yet work well
             for style2 when pasting brace out side class/while/for/switch blocks.
             Braces are not indented.

             pasting open brace does not yet work well
             for style2!=2 when pasting braces for a class.  Braces
             end up indented when they are not supposed to be.
      */
   }

   // locals
   int cfg=0;
   int begin_stat_col=0;
   _str ch='';
   _str word='';
   int junk=0;
   _str line='';
   _str kwd='';
   typeless p2,p3;

/*
   beginning of statement
     {,},;,:

   cases
     -  in-comment or in-string
     - for (;;) <ENTER>


     - myproc(myproc() <ENTER>
     - myproc(a,<ENTER>
     - myproc(a);
     - if/while/for/switch (...) <ENTER>
     - (col1)myproc(a)<ENTER>
     - (col>1)myproc(a)<ENTER>
     - (col>1)myproc(a)<ENTER>
     - case a: <ENTER>
     - default: <ENTER>
     -  if (...) {<ENTER>
     -  if (...) <ENTER>
     -  if (...) ++i; else <ENTER>
     -  if (...) ++i; else <ENTER>
     -  myproc (...) {<ENTER>
     -  statement;
         {<ENTER>
     -  if (a && b
     -  if (a && b,b
     -  <ENTER>  no code above
     -  int a,
     -  if {
           }<ENTER>
     -  {
        }<ENTER>
     - for (;<ENTER>;<ENTER>)
     - for (<ENTER>;;<ENTER>)
     - for (i=1;i<j;<ENTER>
     - if (a<b) {
          x=1;
       } else if( sfsdfd) {<ENTER>}

     {sdfsdf;
      ddd


*/

   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   /*
       Handle a few special cases where line begins with
         close brace, "case", "default","public", "private",
         and "protected".
   */
   {
      save_pos(p2);
      //first_non_blank();
      begin_word();
      if (orig_col<=p_col) {
         cfg=_clex_find(0,'g');
         if (cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
            word=cur_word(junk);
            ch=get_text();
            if (ch=="}") {
               right();
               col=vera_endbrace_col();
               if (col) {
                  restore_pos(p);
                  return(col);
               }
            }
         }
      }
      restore_pos(p2);
   }

   // Are we in an embedded context?
   // Then find the beginning of the embedded code
   long embedded_start_pos=0;
   if (p_EmbeddedLexerName!='') {
      save_pos(p2);
      if (!_clex_find(0,'-S')) {
         embedded_start_pos=_QROffset();
      }
      restore_pos(p2);
   }

   in_csharp := _LanguageInheritsFrom('cs');
   int nesting=0;
   int OpenParenCol=0;
   int maybeInAttribute=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   int status=search('[{;}:()\[\]]|with|if|while|repeat|for|foreach|casex|casez|case|randcase|rand|randseq',"@rh-");
   for (;;) {
      if (status) {
         if (nesting<0) {
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      if (_QROffset() < embedded_start_pos && p_embedded) {
         // we are embedded in HTML and hit script start tag
         //return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
         restore_pos(p);
         if (nesting<0) {
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         /* Cases:
              <%
                  <ENTER>
              %>
              <? <ENTER>
              ?>
              <script ...> <ENTER>
              </script>

             <cfif
                 IsDate(...) and<ENTER>
             </cfif>
         */
         _str orig_EmbeddedLexerName=p_EmbeddedLexerName;
         // Look for first non blank that is in this embedded language
         first_non_blank();
         int ilen=_text_colc();
         //_message_box('xgot here');
         for(;;) {
            if (p_col>ilen) {
               //_message_box('got here');
               return(orig_col);
            } else if (orig_EmbeddedLexerName==p_EmbeddedLexerName && get_text():!=' ') {
               //refresh();_message_box('break col='p_col' l='p_line);
               break;
            }
            ++p_col;
         }
         col=p_col;
         restore_pos(p);
         return(col);
      }

      cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         status=repeat_search();
         continue;
      }

      ch=get_text();
      //messageNwait('ch='ch);
      switch (ch) {
      case ']':  // maybe C# attribute
         status=repeat_search();
         continue;
      case '[':  // maybe C# attribute
         status=repeat_search();
         continue;
      case '(':
         if (!nesting && !OpenParenCol) {
            save_pos(p3);
#if 1
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanksNpp();

            if (!(UseContOnParameters==1) &&
                !status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<orig_col)
                           )) {
               col=p_col-1;
            } else {
               /*
                  case: Use continuation indent instead of lining up on
                  open paren.

                  aButton.addActionListener(<Enter here. No args follow>
                      a,
                      b,
               */
               restore_pos(p3);
               goto_point(_nrseek()-1);
               //if (_clex_skip_blanks('-')) return(0);
               //word=cur_word(junk);
               c_prev_sym2();
               /*if (c_sym_gtk()=='>') {
                  parse_template_args();
               } */
               if (c_sym_gtk()==TK_ID && !pos(' 'c_sym_gtkinfo()' ',' for foreach if elsif elseif case casex casez randseq while repeat ')) {
                  restore_pos(p3);
                  first_non_blank();
                  col=p_col+p_SyntaxIndent-1;
               }
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#else
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanksNpp();
            if (!status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<=orig_col)
                           )) {
               col=p_col-1;
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#endif
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
      if (_in_c_preprocessing()) {
         begin_line();
         status=repeat_search();
         continue;
      }
      //messageNwait("c_indent_col2: ch="ch);
      switch (ch) {
      case '{':
         //messageNwait("case {");
         int openbrace_col=p_col;
         int statdelim_linenum=p_line;
         /*
            Could have
              for (;
                    ;) {<ENTER>

              myproc ( xxxx ) {<ENTER>

              myproc (xxx ) {
                 int i,<ENTER>

              {<ENTER>

              else {<ENTER>

              else
                 {<ENTER>

              class name : public name2 {<ENTER>

              if ( xxx ) {<ENTER>

              if ( xxx )
                 {<ENTER>

              if ( xxx )
              {<ENTER>

              int array[]={
                 a,
                 b,<ENTER>

         */
         save_pos(p2);

         if (_isVarInitList(true)) {
            restore_pos(p2);
            first_non_blank();
            col=p_col;
            restore_pos(p);
            return(col+p_SyntaxIndent);
#if 0
            restore_pos(p2);
            begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                            true /* skip first begin statement marker */,
                                            true /* return first non-blank */
                                            );
            restore_pos(p2);
            // Now check if there are any characters between the
            // beginning of the previous statement and the original
            // cursor position
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,0,
                                       orig_linenum,orig_col);
            if (col) {
               restore_pos(p);
               return(col);
            }
#endif
         }

         restore_pos(p2);

         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         _clex_skip_blanksNpp('-');
         status=1;
         if (get_text()==')') {
            status=_find_matching_paren(def_pmatch_max_diff);
            save_pos(p3);
         }
         if (!status) {
            status=1;
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            _clex_skip_blanksNpp('-');
            if (_clex_find(0,'g')==CFG_KEYWORD) {
               kwd=cur_word(junk);
               status=(int) !pos(' 'kwd' ',' if while repeat case casex casez randseq for foreach ');
               // IF this is the beginning of a "if/while/switch/for" block
               if (!status) {
                  first_non_blank();
                  int block_col=p_col;
                  // Now check if there are any characters between the
                  // beginning of the previous statement and the original
                  // cursor position
                  restore_pos(p2);


                  col=HandlePartialStatement(statdelim_linenum,
                                             syntax_indent,syntax_indent,
                                             orig_linenum,orig_col);
                  if (col) {
                     restore_pos(p);
                     return(col);
                  }

                  restore_pos(p);
                  return(block_col+syntax_indent);
               }
            }

            // Now check if there are any characters between the
            // beginning of the previous statement and the original
            // cursor position
            restore_pos(p2);
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,syntax_indent,
                                       orig_linenum,orig_col);
            if (col) {
               restore_pos(p);
               return(col);
            }

            //  This open brace is to a function or method or some
            //  very strange preprocessing.
            restore_pos(p2); // Restore cursor to open brace
            first_non_blank();
            if (p_col==openbrace_col) {
               begin_stat_col=openbrace_col;
            } else {
               restore_pos(p3); // Restore cursor to open paren
               begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                               false /* Don't skip first begin statement marker */,
                                               false /* Don't return first non-blank */
                                               );
               if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
                  begin_stat_col+=syntax_indent;
               }
            }

            if (begin_stat_col==1 && !indent_fl) {
               restore_pos(p);
               return(1);
            }
            restore_pos(p);
            if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
               return(begin_stat_col);
            }
            return(begin_stat_col+syntax_indent);
         }
         restore_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position


         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         restore_pos(p2);
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }

         /*
             Probably have one of these case here

              {<ENTER>

              else {<ENTER>

              else
                 {<ENTER>

              class name : public name2 {<ENTER>

              if (a<b) x=1; else {<ENTER>}

              if (a<b) {
                 x=1;
              } else {<ENTER>}

         */
         restore_pos(p2);
         if (style3) {
            first_non_blank();
            // IF the open brace is the first character in the line
            if (openbrace_col==p_col) {

               begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                               true /* skip first begin statement marker */,
                                               true /* return first non-blank */
                                               );
               // IF there is stuff between the previous statement and
               //    this statement, we must be in a class/struct
               //    definition.  IF/While/FOR Etc. cases have been
               //    handled above.
               if (openbrace_col!=p_col || statdelim_linenum!=p_line) {
                  restore_pos(p);
                  return(begin_stat_col+syntax_indent);
               }
               // We could check here for extra stuff after the
               // open brace
               restore_pos(p);
               return(openbrace_col);
            }
            restore_pos(p2);
         }
         begin_stat_col=vera_begin_stat_col(false /* No RestorePos */,
                                         true /* skip first begin statement marker */,
                                         true /* return first non-blank */
                                         );
         restore_pos(p);
         return(begin_stat_col+syntax_indent);

      case ';':
         //messageNwait("case ;");
         save_pos(p2);
         statdelim_linenum=p_line;
         begin_stat_col=vera_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */
                                    );
         /* IF there is extra stuff before the beginning of this
               statement
            Example
                x=1;y=2;<ENTER>
                       OR
                for (x=1;<ENTER>
            NOTE:  The following code fragrament does not work
                   properly.
                for (i=1;i<j;++i) ++i;<ENTER>
                for (i=1;
                     i<j;<ENTER>
         */
         word=cur_word(junk);
         if (word=='for') {
            // Here we try to indent after open brace for
            // loop unless the cursor is after the close paren.
            get_line_raw(line);line=expand_tabs(line);
            col=pos('(',line,1,p_rawpos);
            if (!col) {
               col=p_col;
               restore_pos(p);
               return(col+syntax_indent);
            }
            int result_col=col;
            p_col=col+1;
            search('[~ \t]','@rh');
            cfg=_clex_find(0,'g');
            if (get_text()!='' && cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
               ++result_col;
            }
            p_col=col;
            status=find_matching_paren(true);
            // IF cursor is after close paren of for loop
            if (!status && (orig_linenum>p_line ||
                            (p_line==orig_linenum && orig_col>p_col)
                           )
               ) {
               // Cursor is after close paren of for loop.
               //messageNwait('f1');
               restore_pos(p);
               return(begin_stat_col);
            }
            // Align cursor after open brace of for loop
            restore_pos(p);
            return(result_col+1);
         }

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
      case '}':
         //messageNwait("case }");
         /*
            Don't forget to test

            if (i<j)
               {
               }<ENTER>

            if (i<j)
               {
               }
            else
               {
               }<ENTER>


         */
         statdelim_linenum=p_line;
         save_pos(p2);
         /*
            Check if we are in a variable initialization list.
            We don't want to handle this with the HandlePartialStatement statement.
             MYRECORD array[]={
                {a,b,c}
                ,{a,b,c},
                b,<ENTER>
                <End UP HERE, ALIGNED WITH b>

         */
         right();
         _clex_skip_blanks();
         if (get_text()==',') {
            restore_pos(p2);
         } else {
            restore_pos(p2);
            /* Now check if there are any characters between the
               beginning of the previous statement and the original
               cursor position

               Could have
                 struct name {
                 } name1, <ENTER>

                 myproc() {
                 }
                    int i,<ENTER>
            */
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,syntax_indent,
                                       orig_linenum,orig_col);
            if (col) {
               restore_pos(p);
               return(col);
            }
         }



         /*
             Handle the following cases
             for (;;)
                 {
                 }<ENTER>

                 {
                 }<ENTER>

             MYRECORD array[]={
                {a,b,c}<ENTER>

             MYRECORD array[]={
                {a,b,c}
                ,{a,b,c}<ENTER>

         */
         restore_pos(p2);
         ++p_col;
         boolean style3_MustBackIndent=false;
         col=vera_endbrace_col2(be_style, style3_MustBackIndent);
         if (col) {
            if (!style3 || !style3_MustBackIndent) {
               restore_pos(p);
               return(col);
            }
            col-=syntax_indent;
            if (col<1) col=1;
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);
         if (!style3 || !style3_MustBackIndent) {
            col=p_col;
            restore_pos(p);
            return(col);
         }
         col=p_col-syntax_indent;
         if (col<1) col=1;
         restore_pos(p);
         return(col);
      case ':':
         //messageNwait("case :");
         if (p_col!=1) {
            left();
            if (get_text()==":") {
               // skip ::
               //messageNwait('skip ::');
               status=repeat_search();
               continue;
            }
            right();
         }

         save_pos(p2);
         typeless t1,t2,t3,t4;
         save_search(t1,t2,t3,t4);
         boolean bool=_isQmarkExpression();
         //messageNwait('isQmark='bool);
         restore_pos(p2);
         restore_search(t1,t2,t3,t4);
         if (bool) {
            //skip this question mark expression colon
            /*
               NOTE: We could handle the following case better here:
               myproc(b,
                     (c)?s:<ENTER>
                     )
               which is different from
               myproc(b,
                     (c)?s:t,<ENTER>
                     )
            */
            status=repeat_search();
            continue;
         }

         /* Now check if there are any characters between the
            beginning of the previous statement and the original
            cursor position

            Could have
             case 'a':
                 int i,<ENTER>

            MyConstructor(): a(1),<ENTER>b(2)
         */
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            //messageNwait('c1');
            restore_pos(p);
            return(col);
         }
         //messageNwait('c2');

         restore_pos(p2);


         /*

             default:<ENTER>
             case ???:<ENTER>
             (abc)? a: b;<ENTER>
             class name1:public<ENTER>
         */
         begin_stat_col=vera_begin_stat_col(false /* RestorePos */,
                                    true /* skip first begin statement marker */,
                                    true /* return first non-blank */,
                                    1
                                    );

         if (p_line==orig_linenum) {
            word=cur_word(junk);
            if (word=='case' || word=='default') {
               first_non_blank();
               // IF the 'case' word is the first non-blank on this line
               if (p_col==begin_stat_col) {
                  col=p_col;
                  restore_pos(p);
                  //messageNwait('c3');
                  return(col);
               }
            }
         }
         //messageNwait('c4');
         restore_pos(p);
         return(begin_stat_col+syntax_indent);
      default:
         if (cfg==CFG_KEYWORD) {
            /*
               Cases
                 if ()
                    if () <ENTER>
                 for <ENTER>

            */
            first_non_blank();
            col=p_col+syntax_indent;
            restore_pos(p);
            return(col);
         }
      }

      status=repeat_search();
   }

}

_command void vera_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (ispf_common_enter()) return;
   if (command_state()) {
      call_root_key(ENTER);
      return;
   }

   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(ENTER, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART) {
      call_root_key(ENTER);
   } else {
      if (_in_comment(true)) {
         // start of a Java doc comment?
         get_line(auto first_line);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) &&
             (first_line=='/***/' || first_line=='/*!*/') && get_text(2)=='*/' && _is_line_before_decl()) {
            //_document_comment(DocCommentTrigger1);commentwrap_SetNewJavadocState();return;
            //get_line_raw(auto recoverLine);
            p_line += 1;
            first_non_blank();
            int pc = p_col - 1;
            p_line -= 1;
            p_col = 1;
            _delete_end_line(); 
            _insert_text_raw(indent_string(pc));
            if (!expand_alias(substr(strip(first_line), 1, 3), '', getCWaliasFile(p_LangId), true)) {
               CW_doccomment_nag();
            }
            commentwrap_SetNewJavadocState();
            return;
         }
         //Try to handle with comment wrap.  If comment wrap
         //handled the keystroke then return.
         if (commentwrap_Enter()) {
            return;
         }
         // multi-line comment
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK) && commentwrap_Enter(true)) {
            //do nothing
         } else {
            call_root_key(ENTER);
         }
         return;
      }
      if (_in_comment(false)) {
         // single line comment

         //Check for case of '//!'
         _str line; get_line(line);
         boolean double_slash_bang = (line == '//!');
         _str commentChars='';
         int line_col = _inExtendableLineComment(commentChars, double_slash_bang);
         //messageNwait('@'line_col);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS) &&
             line_col && _will_split_insert_line() && /*get_text()!='/'*/ p_col - line_col > 2) {
            // check for xmldoc comment
            int orig_col=p_col;
            p_col = line_col;
            boolean triple_slash = (get_text(3)=='///' && get_text(4)!='////');
            //messageNwait('Checking double slash bang');
            double_slash_bang = (get_text(3)=='//!');
            p_col = orig_col;
            if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT) &&
                (triple_slash || double_slash_bang) && (_LanguageInheritsFrom('cs') || _LanguageInheritsFrom('c') || _LanguageInheritsFrom('jsl')) &&//) {
               (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) && c_maybe_create_xmldoc_comment(double_slash_bang ? '//!' : '///', true)) ) {
               CW_doccomment_nag();
               return;
            }
            //Try to handle with comment wrap.  If comment wrap
            //handled the keystroke then return.
            if (commentwrap_Enter()) {
               return;
            }

            indent_on_enter(0,line_col);
            if (get_text(2)!='//') {
               if (triple_slash) {
                  keyin('/// ');
               } else {
                  keyin('// ');
               }
            }
            return;
         }
      }

      //Try to handle with comment wrap.  If comment wrap
      //handled the keystroke then return.
      if (commentwrap_Enter()) {
         return;
      }

      if (_in_string()) {
         if (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('java')) {
            _str delim='';
            int string_col = _inString(delim);
            if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS) && 
                string_col && p_col > string_col && _will_split_insert_line()) {
               _insert_text(delim);
               if (_LanguageInheritsFrom('java')) _insert_text('+');
               if (_LanguageInheritsFrom('cs')) _insert_text('+');
               indent_on_enter(0,string_col);
               keyin(delim);
               return;
            }
         }
      }
      if (_vera_expand_enter() ) {
          call_root_key(ENTER);
      } else if (_argument=='') {
         _undo('S');
      }
   }
}

static typeless prev_stat_has_semi()
{
   typeless status=1;
   typeless p=0;
   _str line="";
   int col=0;
   up();
   if ( ! rc ) {
      col=p_col;_end_line();get_line_raw(line);
      parse line with line '\#',(p_rawpos'r');
      /* parse line with line '{' +0 last_word ; */
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line='' or last_word='{' */
      line=strip(line,'T');
      if (raw_last_char(line)==')') {
         save_pos(p);
         p_col=text_col(line);
         status=_find_matching_paren(def_pmatch_max_diff);
         if (!status) {
            status=search('[~( \t]','@-rh');
            if (!status) {
               if (!_clex_find(0,'g')==CFG_KEYWORD) {
                  status=1;
               } else {
                  typeless junk=0;
                  _str kwd=cur_word(junk);
                  status=!pos(' 'kwd' ',' if do while foreach for repeat');
               }
            }
         }
         restore_pos(p);
      } else {
         status=raw_last_char(line)!=')' && !pos('(\}|)else$',line,1,p_rawpos'r');
      }
      down();
      p_col=col;
   }
   return(status);
}


_command void vera_beginbrace() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   int cfg = 0;
   if (!command_state() && p_col>1) {
      left();cfg=_clex_find(0,'g');right();
   }
   if ( command_state() || cfg==CFG_STRING || _in_comment() ||
       vera_expand_begin() ) {
      call_root_key('{');
   } else if (_argument=='') {
      _undo('S');
   }
}

static boolean maybe_surround_conditional_statement()
{
   // make sure the option is enabled
   if (!LanguageSettings.getQuickBrace(p_LangId)) {
      return false;
   }

   // now attempt to find a brace matching the brace we just put in
   // if it falls in a column that matches the expected indentation
   // then do not insert the closing brace.  If the cursor was past the
   // real end of the line, pretend there were real spaces there.
   save_pos(auto p);
   int orig_col = p_col;
   _end_line();
   int end_col = p_col;
   first_non_blank();
   int indent_col = p_col;
   if (indent_col == end_col && orig_col > indent_col) {
      indent_col = orig_col;
      p_col = indent_col;
   }
   
   restore_pos(p);
   _insert_text('{');
   if (!find_matching_paren(true)) {
      if (p_col >= indent_col && p_col <= indent_col+p_SyntaxIndent) {
         restore_pos(p);
         _delete_text(1);
         return false;
      }
   }
   restore_pos(p);
   _delete_text(1);
   restore_pos(p);

   // save the original cursor position and seach parameters
   status := 0;
   save_search(auto s1,auto s2, auto s3, auto s4, auto s5);

   // do - while - false
   do {
      orig_line := p_line;

      // skip backwards over whitespace
      left();
      status = search("[^ \t]", '-@r');
      if (status) {
         break;
      }

      // skip line comment if we encounter one
      if (_in_comment()) {
         _clex_skip_blanks('-');
      }

      // if we have a paren, skip backwards over it
      paren_line := p_line;
      haveParen := (get_text()==')');
      if (get_text()==')') {
         status = find_matching_paren(true);
         if (status) {
            break;
         }

         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }
      }

      // check keyword under cursor
      left();
      col := 0;
      kw := cur_identifier(col);
      kw_line := p_RLine;
      if (kw != 'if' && kw != 'for' && kw!='while' && kw!='foreach' && kw!='else') {
         status = STRING_NOT_FOUND_RC;
         break;
      }
      if (kw=='else' && haveParen) {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // check for type 2 or 3 braces
      boolean type23_braces=false;
      if (paren_line == orig_line) {
         type23_braces=false;
      } else if (paren_line < orig_line) {                 
         type23_braces=true;
      } else {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // check for "else if"
      if (kw == 'if') {
         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }
   
         save_pos(auto pif);
         left();
         if_col := 0;
         kw = cur_identifier(if_col);
         if (kw!='else') {
            restore_pos(pif);
         } else {
            col = if_col;
         }
      }

      // check for "} else"
      if (kw == 'else') {
         p_col = col;
         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }
         if (get_text() == '}') {
            col = p_col;
         }
      }

      // for type2 and type3 braces, have to be at start of line
      if (type23_braces) {
         restore_pos(p);
         orig_col = p_col;
         first_non_blank();
         if (p_col < orig_col && !at_end_of_line()) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
      }

      // back where we started, as skip backwards over whitespace
      restore_pos(p);
      status = search('[^ \t]', '@r');
      if (status) {
         break;
      }

      // make sure we land where we expected
      if (p_col <= col) {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // check that the current statement starts here
      _UpdateContext(true,false,VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int cur_statement_id = tag_current_statement();
      if (cur_statement_id <= 0) {
         status = STRING_NOT_FOUND_RC;
         break;
      }
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, cur_statement_id, auto cur_statement_line);
      if (cur_statement_line < kw_line || cur_statement_line > p_RLine) {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // jump to the end of the conditional statement
      status = end_statement(true);
      if (status) {
         break;
      }

      // insert the closing brace
      updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE | AFF_SYNTAX_INDENT);
      if (type23_braces && (p_begin_end_style == VS_C_OPTIONS_STYLE2_FLAG)) {
         insert_line(indent_string(col-1+p_SyntaxIndent):+"}");
      } else {
         insert_line(indent_string(col-1):+"}");
      }
      last_line := p_line;

      // check for trailing else and join to close brace
      save_pos(auto pend);
      down();
      first_non_blank();
      end_col = 0;
      kw = cur_identifier(end_col);
      restore_pos(pend);
      if (kw=='else' && !type23_braces) {
         if (LanguageSettings.getCuddleElse(p_LangId)) {
            join_line(1);
            _insert_text(' ');
         }
      }

      // check for incorrect brace style, I mean, 
      // check for something other than style 1
      restore_pos(p);
      if (type23_braces) {
         if (p_begin_end_style == BES_BEGIN_END_STYLE_2) {
            p_col = col;
         } else if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            p_col = col+p_SyntaxIndent;
         } else {
            p_col = col;
         }
         // re-indent the line using user's preferred tab style 
         get_line(auto line);
         line = reindent_line(line, 0);
         replace_line(line);
      }

      // finally, insert the opening brace
      if (!_insert_state() && get_text()==' ') _delete_text(1);
      _insert_text('{');
      save_pos(p);
      status = search('[^ \t]', '@r');
      if (!status && p_line == orig_line && !_in_comment()) {
         split_line();
         strip_trailing_spaces();
         last_line++;
      }

      // re-indent the statement, no matter how many lines
      down();
      while (p_line < last_line) {
         first_non_blank();
         while (p_col < col+p_SyntaxIndent) {
            _insert_text(' ');
         }
         get_line(auto line);
         line = reindent_line(line, 0);
         replace_line(line);
         down();
      }

      // drop into dynamic surround so they can move
      // single statement out of the loop if they want to
      //set_surround_mode_start_line(orig_line,1);
      //set_surround_mode_end_line(p_line);
      //restore_pos(p);
      //do_surround_mode_keys(false);

   } while (false);

   restore_pos(p);
   restore_search(s1,s2,s3,s4,s5);
   return status==0;
}
static int vera_expand_begin()
{
   if (maybe_surround_conditional_statement()) {
      return 0;
   }

   // check if they typed "do{" or "try{"
   get_line(auto line);
   if (line=='do') {
      if (!vera_expand_space()) {
         return 0;
      }
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   if (first_char(strip(line)) == '}') {
      parse line with '}' line;
   }
   if (line=='if' || line=='while' || line=='for' || line=='foreach' || 
       line=='else if' || line=='case' || line=='casex' || line=='casez' || 'repeat' || 'randseq'
        /*|| line=='with' || line=='lock' || line=='catch' || 
       line=='fixed' || line=='using'*/) {
      insertBraceImmediately = true;
      if (!vera_expand_space()) {
         return 0;
      }
   }

   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);

   int brace_indent=0;
   keyin('{');
   get_line(line);
   int pcol=_text_colc(p_col,'P');
   _str last_word='';
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);

   // first, back up and look for a parenthesized expression
   // which would be part of the if, while, or for statement
   left();
   left();
   _clex_skip_blanks('-');
   if (get_text()!=')' || find_matching_paren(true) != 0) {
      restore_pos(AfterKeyinPos);
   }

   // compute the simple indentation column for this line
   first_non_blank();
   int indent_col = p_col;

   // now attempt to find a brace matching the brace we just put in
   // if it falls in a column that matches the expected indentation
   // then do not insert the closing brace
   boolean orig_expand=expand;
   restore_pos(AfterKeyinPos);
   if (expand && !find_matching_paren(true)) {
      if (p_col >= indent_col && p_col <= indent_col+p_SyntaxIndent) {
         expand=0;
      }
   }
   restore_pos(AfterKeyinPos);

   /*
        Don't insert end brace for these cases in a variable initializer
        object array={
           {<DONT EXPAND THIS>
        }
        object array={
           a,{<DONT EXPAND THIS>
        }

   */
   left();
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   _clex_skip_blanksNpp('-');
   if (get_text()==',') {
      restore_pos(AfterKeyinPos);
      return(0);
   }
   if (get_text()=='{') {
      // This won't work for C because of function variable declarations but should work pretty well for C++
      // Worst case, user has to type close brace
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanksNpp('-');
      if (get_text()!=')') {
         restore_pos(AfterKeyinPos);
         return(0);
      }
   }
   restore_pos(AfterKeyinPos);

   int old_linenum=p_line;
   int col=0, old_col=p_col;
   int begin_brace_col=0;
   int status=_clex_skip_blanks();
   boolean end_brace_is_last_char=status || p_line>old_linenum;
   restore_pos(AfterKeyinPos);

   if ( line!='{' ) {
      if (!end_brace_is_last_char) {
         return(0);
      }
   } else if ( p_begin_end_style != BES_BEGIN_END_STYLE_3 ) {
      /*
          Now that "class name<ENTER>" usually indents, we need
          the begin brace to be moved correctly to align under the
          "class" keyword.
      */
      save_pos(auto p);
      left();
      //begin_brace_col=p_col;
      col= find_block_col();
      if (!col) {
         restore_pos(p);left();
         col=vera_begin_stat_col(true,true,true);
      } else {
         // Indenting for class/struct/interface/variable initialization
         /*style=(be_style & VS_C_OPTIONS_STYLE2_FLAG);
         if (style!=0) {
            col=begin_brace_col;
         }*/
      }
      restore_pos(p);
      if (col) {
         expand=orig_expand;
         replace_line(indent_string(col-1)'{');
         _end_line();save_pos(AfterKeyinPos);
      }

   } else if ( p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
      /*
         A few customers like the way 1.7 let them type braces
         for functions indented.

         Brief does not do this.

      */
      /*
          Now that "class name<ENTER>" usually indents, we need
          the begin brace to be moved correctly to align under the
          "class" keyword.
      */
      save_pos(auto p);
      left();
      begin_brace_col=p_col;
      col= find_block_col();
      if (!col) {
         restore_pos(p);left();
         col=vera_begin_stat_col(true,true,true);
         if ((p_begin_end_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
            col+=syntax_indent;
         }
      } else {
         // Indenting for class/struct/interface/variable initialization
         if (p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            col=begin_brace_col;
         }
      }
      restore_pos(p);
      if (col) {
         expand=orig_expand;
         replace_line(indent_string(col-1)'{');
         _end_line();save_pos(AfterKeyinPos);

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }

   }
   first_non_blank();
   if ( expand ) {
      col=p_col-1;
      
      indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
      if ( (col && (p_begin_end_style == BES_BEGIN_END_STYLE_3)) || (! (indent_fl+col)) ) {
         syntax_indent=0;
      }
      insert_line(indent_string(col+brace_indent));
      set_surround_mode_start_line(old_linenum);
      brace_indent=p_col-1;
      vera_endbrace();
      restore_pos(AfterKeyinPos);//_end_line();
      if ( insertBraceImmediately ) {
         _end_line();
         vera_enter();
      }
      set_surround_mode_end_line(p_line+1);

      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   } else {
      restore_pos(AfterKeyinPos);//_end_line();
   }
   typeless done_pos;
   save_pos(done_pos);
   if (1) {
      restore_pos(AfterKeyinPos);
      _str class_name='';
      _str implement_list='';
      _str class_type_name;
      int vsImplementFlags=0;
      get_line(auto temp_line);
      parse temp_line with auto first_word .;
      //_message_box('first_word='first_word);
      indent_col=c_parse_class_definition(class_name,class_type_name,implement_list,vsImplementFlags,AfterKeyinPos);
      if (!indent_col) {
         restore_pos(done_pos);
         // do block surround only if we are already in a function scope
         if (_in_function_scope()) {
            do_surround_mode_keys();
         } else {
            clear_surround_mode_line();
         }
         return(0);
      }

      clear_surround_mode_line();
      restore_pos(AfterKeyinPos);
      /*
         For simplicity, remove blank line that was inserted
      */
      if (expand && insertBraceImmediately ) {
         down();
         _delete_line();
         restore_pos(AfterKeyinPos);
      }
#if 0
      int count;
      //messageNwait('class_name='class_name' implement_list='implement_list);
      int context_id=tag_current_context();
      _str outer_class="";
      _str tag_name="";
      if (context_id>0) {
         tag_get_detail2(VS_TAGDETAIL_context_class, context_id, outer_class);
      }
      if (class_name=='') {
         class_name=implement_list;
      }
      count=_do_default_get_implement_list(class_name, outer_class,vsImplementFlags,false);
      _str lastext="";
      int index=0;
      boolean CursorDone=false;
      int c_access_flags = VS_TAGFLAG_private;
      int match_id;
      for (match_id=1;match_id<=count;++match_id) {
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(match_id, cm);

         // Can't we get source comments?
         _str header_list[];header_list._makeempty();
         _ExtractTagComments(header_list,2000,cm.member_name,cm.file_name,cm.line_no,
                             cm.type_name, cm.class_name, indent_col);
         // generate the match signature for this function, not a prototype
         int akpos=_c_generate_function(cm,c_access_flags,header_list,null,
                                               indent_col,brace_indent,false);
         if (!CursorDone) {
            CursorDone=true;
            AfterKeyinPos = akpos;
         }
      }
#endif
      down();
      get_line(auto cur_line);
      if (first_word=='enum' && cur_line=='}') {
         // Not sure if semicolon is required for enum
         replace_line(strip(cur_line,'T'):+';');

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
      restore_pos(AfterKeyinPos);
      return(0);
   }

   // do block surround only if we are already in a function scope
   if (_in_function_scope()) {
      do_surround_mode_keys();
   } else {
      clear_surround_mode_line();
   }
   return(0);
}
static boolean probably_is_label() {
   typeless p;
   save_pos(p);
   int status=search('[?;{})\[\]]|default|with','-@rhxcs');
   for (;;) {
      if (status) {
         restore_pos(p);
         return(false);
      }
      switch(get_match_text()) {
      case '?':
         restore_pos(p);
         return(false);
      case ';':
      case ']':
         // Look for braces only
         status=search('[{}]','-@rhxcs');
         break;
      case '{':
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         _clex_skip_blanks('-');
         if (get_text()==')') {
            restore_pos(p);
            return(true);
         }
         if(cur_word(auto junk_col)=='randcase') {
            restore_pos(p);
            return(true);
         }

      case '}':
      case ')':
         status=find_matching_paren(true);
         if (status) {
            return(false);
         }
         status=repeat_search();
         continue;
      default:
         if (_clex_find(0,'g')==CFG_KEYWORD) {
            //status=repeat_search();
            return(false);
         }
         return(false);
      }
   }

}
/**
 * look for beginning of statement by searching for the following
 * <PRE>
 *      '{', '}', ';', ':', 'if', 'while','switch','for', 'with' (perl)
 * </PRE>
 * <P>
 * If a non-alpha symbol is found, we look ahead for the first a non-blank
 * character that is not in a comment.
 * <P>
 * NOTE:  Calling this function for code like the following will
 *        find the beginning of the code block and not the statement:
 * <PRE>
 *    &lt;Find Here&gt;for (...) ++i&lt;Cursor Here&gt;
 *    &lt;Find Here&gt;if/while (...) ++i&lt;Cursor Here&gt;
 * </PRE>
 *
 * @param RestorePos
 * @param SkipFirstHit
 * @param ReturnFirstNonBlank
 * @param FailIfNoPrecedingText
 * @param AlreadyRecursed
 * @param FailWithMinus1_IfNoTextAfterCursor
 *
 * @return int
*/
int vera_begin_stat_col(boolean RestorePos,boolean SkipFirstHit,boolean ReturnFirstNonBlank,
                     boolean FailIfNoPrecedingText=false,
                     boolean AlreadyRecursed=false,
                     boolean FailWithMinus1_IfNoTextAfterCursor=false)
{
   int orig_linenum=p_line;
   int orig_col=p_col;
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   save_pos(auto p);
   int status=search('[{};:()]|if|while|repeat|casex|casez|case|foreach|for|randseq','-Rh@');
   int nesting=0;
   boolean hit_top=false;
   int MaxSkipPreprocessing=VSCODEHELP_MAXSKIPPREPROCESSING;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         int cfg=_clex_find(0,'g');
         if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         switch (get_text()) {
         case '(':
            FailIfNoPrecedingText=false;
            if (nesting>0) {
               --nesting;
            }
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         case ')':
            FailIfNoPrecedingText=false;
            ++nesting;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (SkipFirstHit || nesting) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (_in_c_preprocessing()) {
            --MaxSkipPreprocessing;
            if (MaxSkipPreprocessing<=0) {
               status=STRING_NOT_FOUND_RC;
               continue;
            }
            SkipFirstHit=false;
            begin_line();
            status=repeat_search();
            continue;
         }

         _str ch=get_text();
         if (!AlreadyRecursed && ch:==':') {
            save_pos(auto p2);
            _str word='';

            if (p_col!=1) {
               left();
               int junk=0;
               word=cur_word(junk);
               // IF we are seeing  classname::name
               if (get_text()==':') {
                  status=repeat_search();
                  continue;
               }
               right();
            }
            if (probably_is_label()) {
               first_non_blank();
               p_col+=p_SyntaxIndent;
            } else {
               int col=vera_begin_stat_col(false,true,false,false,1);
            }
#if 1
            if (word=='default') {
               restore_pos(p2);
               first_non_blank();
               p_col+=p_SyntaxIndent;
#if 0
            } else if (!_LanguageInheritsFrom("cs") && (word=='public' || word=='private' || word=='protected') || 
                       (_LanguageInheritsFrom("c") && word=='signals')
                       ) {
               restore_pos(p2);
               right();
#endif
            }
#endif
         } else {
            /*
                Handle where constraint case for csharp.  Need to go back to beginning of class definition.
                The only down side to doing this is that if the constraints are on multiple lines we will
                indent back to the "where" column.  This is not a likely case so we can forget about it.

                class myclass<a>
                    where a: constraint1,constraint2,constraint3
                    where b: constraint1,constraint2,constraint3
            */
            if (AlreadyRecursed && ch:==':') {
               if (_LanguageInheritsFrom('cs')) {
                  _str line, word, more;
                  get_line(line);
                  parse line with word more':';
                  if (word=='where') {
                     status=repeat_search();
                     continue;
                  }
               } else {
                  if (p_col!=1) {
                     left();
                     // IF we are seeing  classname::name
                     if (get_text()==':') {
                        status=repeat_search();
                        continue;
                     }
                     right();
                  }
               }
            }
            if (isalpha(ch)) {
               if(cfg!=CFG_KEYWORD) {
                  if (cfg!=CFG_STRING && cfg!=CFG_COMMENT) {
                     FailIfNoPrecedingText=false;
                  }
                  status=repeat_search();
                  continue;
               }
            } else {
               right();
            }
         }
      }
      status=_clex_skip_blanksNpp();
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

static int _vera_block_col()
{
   int orig_col = p_col;
   typeless s1, s2, s3, s4, s5;
   typeless p;
   int col;
   int indent_state = 0;
   save_pos(p);
   left(); _clex_skip_blanks('-');
   int status = search('[;{}()]|\b(if|else|for|foreach|while|repeat|case|case[xz]|randcase|enum|class|interface|port|task|function|program|coverage_group|extends|bind)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(orig_col);
      }
      _str word = get_match_text();
      int cfg = _clex_find(0,'g');
      if (cfg == CFG_KEYWORD) {
         first_non_blank();
         col = p_col;
         restore_pos(p);
         return(col);
      } else {
         switch (word) {
         case ';':
         case '{':
         case '}':
         case '(':
            restore_pos(p);
            return(orig_col);
   
         case ')':
            save_search(s1, s2, s3, s4, s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(orig_col);
            }
            break;
         }
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(orig_col);
}

static int find_block_col()
{
   _str word;
   int col=0;
   --p_col;
   if (_clex_skip_blanks('-')) return(0);
   if (get_text()!=')') {
      if (_clex_find(0,'g')!=CFG_KEYWORD) {
         return(0);
      }
      word=cur_word(col);
      if (word=='do' || word=='else' || word=='rand' || word=='randcase') {
         first_non_blank();
         return(p_col);
         //return(p_col-length(word)+1);
      }
      return(0);
   }
   // Here we match round parens. ()
   int status=_find_matching_paren(def_pmatch_max_diff);
   if (status) return(0);
   if (p_col==1) return(1);
   --p_col;

   if (_clex_skip_blanks('-')) return(0);
   /*if (_clex_find(0,'g')!=CFG_KEYWORD) {
      return(0);
   }
   */
   word=cur_word(col);
   if (pos(' 'word' ',' for foreach if case casex casez while repeat randseq ')) {
      first_non_blank();
      return(p_col);
      //return(p_col-length(word)+1);
   } else if (_LanguageInheritsFrom('java')) {
      // Check if we have a new construct
      p_col=_text_colc(col,'I');
      if (p_col>1) {
         left();
         if (_clex_skip_blanks('-')) return(0);
         word=cur_word(col);
         if (word=='new') {
            p_col=_text_colc(col,'I');
            col=p_col;
            first_non_blank();
            if (col!=p_col) {
               p_col+=p_SyntaxIndent;
            }
            return(p_col);
         }
      }
   }
   return(0);
}
/**
 * On entry, the cursor is sitting on a } (close brace)
 * <PRE>
 * static void
 *    main () /* this is a test */ {
 * }
 * static void main /* this is a test */
 *   ()
 * {
 * }
 * </PRE>
 *
 * @param be_style  begin-end brace style
 * <PRE>
 * for (;;) {     for (;;)        for (;;)
 *                {                  {
 *                }                  }
 * }
 * style 0        style 1         style 2
 * </PRE>
 *
 * @return
 * Returns column where end brace should go.
 * Returns 0 if this function does not know the column where the
 * end brace should go.
*/
int vera_endbrace_col()
{
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   boolean style3_MustBackIndent=false;
   return(vera_endbrace_col2(p_begin_end_style,style3_MustBackIndent));
}
int vera_endbrace_col2(int be_style, boolean &style3_MustBackIndent)
{
   style3_MustBackIndent=false;
   if (p_lexer_name=='') {
      return(0);
   }
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   save_pos(auto p2);
   int begin_brace_col=p_col;
   // Check if the first char before open brace is close paren
   int col= find_block_col();
   if (!col) {
      restore_pos(p2);
      if (_isVarInitList(true)) {
         restore_pos(p2);
         first_non_blank();
         col=p_col;
         restore_pos(p);
         return(col);
      }
      restore_pos(p2);
#if 0
      if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
         // check if this parenthesis is on a line by itself;
         get_line(line);
         if (line=="{") {
            style3_MustBackIndent=true;
            first_non_blank();
            col=p_col;
            restore_pos(p);
            return(col);
         }
      }
#endif
      col=vera_begin_stat_col(true,true,true);
      restore_pos(p);
      if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
         style3_MustBackIndent=true;
         col+=p_SyntaxIndent;
      }
      return(col);
   }
   style3_MustBackIndent=true;
   if (be_style == BES_BEGIN_END_STYLE_3) {
      restore_pos(p);
      //return(begin_brace_col);
      return(col+p_SyntaxIndent);
   }
   restore_pos(p);
   return(col);
}

_command void vera_endbrace() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   int cfg=0;
   if (!command_state() && p_col>1) {
      left();cfg=_clex_find(0,'g');right();
   }
   keyin('}');
   if ( command_state() || cfg==CFG_STRING || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      get_line(auto line);
      if (line=='}') {
         int col=vera_endbrace_col();
         if (col) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

int vera_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

/**
 * (C mode only) Open Parenthesis
 * <p>
 * Handles syntax expansion or auto-function-help for C/C++ mode
 * and several other C-like languages.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void vera_paren() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   // Called from command line?
   if (command_state()) {
      call_root_key('(');
      return;
   }
#if 0
   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values,'');
   if (embedded_status==1) {
      call_key(last_event());
      _EmbeddedEnd(orig_values);
      return;
   }
#endif

   // Check syntax expansion options
   if (LanguageSettings.getSyntaxExpansion(p_LangId) && p_SyntaxIndent>=0 && !_in_comment() &&
       !vera_expand_space()) {
      return;
   }

   // not the syntax expansion case, so try function help
   auto_functionhelp_key();
}
int _vera_delete_char(_str force_wrap='') {
   return(_c_delete_char(force_wrap));
}
int _vera_rubout_char(_str force_wrap='') {
   return(_c_rubout_char(force_wrap));
}

/////////////////////////////////////////
// Context tagging functions
/////////////////////////////////////////
int _vera_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          boolean find_parents,int max_matches,
                          boolean exact_match,boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }
   return _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth);
}

int _vera_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_get_expression_info(PossibleOperator, info, visited, depth);
   return status;
}

int _vera_fcthelp_get_start(_str (&errorArgs)[],
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

int _vera_fcthelp_get(_str (&errorArgs)[],
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

int _vera_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                               _str (&header_list)[],_str function_body,
                               int indent_col, int begin_col,
                               boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}
