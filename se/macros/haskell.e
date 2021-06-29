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
//
// Language support module for Haskell
// 
#pragma option(pedantic,on)

#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "context.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

static const HASKELL_LANGUAGE_ID= "haskell";

/**
 * Set current editor language to Haskell
 */
_command haskell_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(HASKELL_LANGUAGE_ID);
}

/**
 * Build tag file for the Haskell Prelude
 * @remarks Prelude definitions in haskell.tagdoc
 * @param tfindex   Tag file index
 */
int _haskell_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   lang := HASKELL_LANGUAGE_ID;
   return ext_MaybeBuildTagFile(tfindex, lang, lang,
                                "Haskell Prelude", 
                                "", false, withRefs, useThread, forceRebuild);
}

/**
 * Haskell implementation of the ext_proc_search callback. Searches for Haskell 
 * function, data, and type declarations in the current source file. 
 */
int haskell_proc_search(_str &proc_name,bool find_first)
{
   // Search for identifiers starting in the first column, which
   // are followed by as assignment operator (read as "meaning")
   // also...
   // Search for class and data declarations
   // Search for prototypes

   // This search is overly broad, but effective for this
   // purpose, at least until a full-blown lexer can be
   // written.
   searchOptions := "@riXcs"; // Do not search in comments or strings
   search_key := '^([a-z_][a-zA-Z0-9_]#[^\=]#)(\=|(\:\:))[^\n]#';
   status := 0;
   //_str search_key='^[\[]'proc_name'[\]]';
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
      // This is just a candidate line. Just get the whole
      // line from it and try to narrow it down.
      groupStart := match_length('S');
      groupLen := match_length("");
      wholeLine := get_text(groupLen, groupStart);

      decl_identifier := "";
      arguments := "";
      tag_type  := SE_TAG_TYPE_NULL;
      tag_flags := SE_TAG_FLAG_NULL;

      // See if it's a data identifier
      if (pos('^data:b#{#1[A-Z][a-zA-Z0-9_]#}',
              wholeLine, 1, 'r') > 0) {
         // Is it an algebraic ?
         if (pos('^data:b{#0[A-Z][a-zA-Z0-9_]*}(:b)*=(:b)*{#1[A-Z][a-zA-Z0-9_]*(:b)*}{#2\|(:b)*[^\n]#}',
                 wholeLine, 1, 'r') > 0) {
            // A valid algebraic type. Or at least, valid enough
            // for this rough style of checking
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
            // Group 1 and Group 2 concatenated is the full signature
            // of the enumeration names
            enumPartOne := substr(wholeLine,pos('S1'),pos('1'));
            enumPartTwo := substr(wholeLine,pos('S2'),pos('2'));
            arguments = enumPartOne :+ enumPartTwo;
            tag_type = SE_TAG_TYPE_ENUM;
         }
         else if (pos('^data:b#{#0[A-Z][a-zA-Z0-9_]#}(:b)*\={#1((:b)*(\[*)[A-Z][a-zA-Z0-9_]#(\]*))#}(:b)*$',
                     wholeLine, 1, 'r') > 0){
            // A valid user-defined data type (so far at least...)
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
            // Group 1 is the full signature (at least the first line sig)
            arguments = substr(wholeLine,pos('S1'),pos('1'));
            tag_type = SE_TAG_TYPE_STRUCT;
         }

         // Return early if not set yet
         if(tag_type == SE_TAG_TYPE_NULL) {
            return 1;
         }
      }
      
      // See if it's a type identifier
      if (pos('^type:b{#0[A-Z][a-zA-Z0-9_]*}(:b)*\=((:b)*{#1([\[\(]*)[A-Z][a-zA-Z0-9_]#[^\n]#})$',
             wholeLine, 1, 'r') > 0) {
         // Group 0 is the name (typedef)
         decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
         // Group 1 is the original type
         arguments = substr(wholeLine,pos('S1'),pos('1'));
         tag_type = SE_TAG_TYPE_TYPEDEF;
      }
      
      if (tag_type == SE_TAG_TYPE_NULL) {
         // See if it's a function prototype
         if(pos('^([_a-z][a-zA-Z0-9_]*)\s*::\s*([a-zA-Z\[\(][^\n]*)$',
                wholeLine, 1, 'l') > 0) {
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S1'),pos('1'));
            // Group 1 is the argument (with last being evaluation reduction type)
            arguments = substr(wholeLine,pos('S2'),pos('2'));
            tag_type = SE_TAG_TYPE_PROTO;
         }
      }

      if (tag_type == SE_TAG_TYPE_NULL) {
         // Last gasp. Could be a function declaration, which is
         // the hardest one to parse, and the most common
      }

      if (tag_type != SE_TAG_TYPE_NULL) {
         tag_init_tag_browse_info(auto cm, decl_identifier, "", (int)tag_type, tag_flags);
         cm.arguments = arguments;
         proc_name = tag_compose_tag_browse_info(cm);
      }
   }
   return(status);
}

/**
 * Attempts to do haskell "layout" alignment when continuing 
 * the declaration of function. 
 * @example Proper alignment shown by the # sign below, right under the i in if<pre>
 * myFunc n xs = if n <= 0 || null
 *               #
 * </pre>
 * @return bool If true, layout alignment was done. Otherwise, false, which falls 
 *         through to default ENTER behavior
 */
bool _haskell_expand_enter()
{
   if( command_state()                  ||  // Do not expand if the visible cursor is on the command line
       (p_window_state:=='I')           ||  // Do not expand if window is iconified
       _in_comment(true)){                     // Do not expand if you are inside of a comment
      return true;
   }
   
   caretNowAt := p_col;
   if(caretNowAt > 3) {
      get_line(auto currentLine);
      // See if this line looks like a function declaration, and if there is at least
      // one non-space char after the equals sign. That is what we'll align on.
      if(pos('^[a-z_][a-zA-Z0-9_]#([^\=])#\=(:b)#{:a|[\(\[]}', currentLine, 1, 'r') > 0){
         indentPos := pos('S0');
         if(indentPos < caretNowAt) {
            indent_on_enter(indentPos-1);
            return false;
         }
      }
   }
   return true;
}
 
defeventtab haskell_keys;  
def 'ENTER'=haskell_enter; 
def ' '=ext_space; 
 
_command void haskell_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL) 
{
   generic_enter_handler(_haskell_expand_enter);
} 
bool _haskell_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}



/* 
def ' '=haskell_space; 
 
static SYNTAX_EXPANSION_INFO haskell_space_words:[] = { 
}; 

int _haskell_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,haskell_space_words);
} 
 
*/
 
/* 
_command haskell_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! LanguageSettings.getSyntaxExpansion(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      haskell_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=="") {
      _undo('S');
   }

} 
*/

/* 
static _str haskell_expand_space() { 
   //updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT); //syntax_indent =
   p_SyntaxIndent;

   status := 0;
   line := "";
   get_line(line);
   line=strip(line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   mult_line_info := "";
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,haskell_space_words,"",aliasfilename);
   if (aliasfilename==null) return(0);
   if (word!=""&&aliasfilename!="") {
      if (orig_word:==word && orig_word==get_alias(word,mult_line_info,1,aliasfilename)) {
         _insert_text(' ');
         return(0);
      }
      line_prefix := "";
      int col=p_col-_rawLength(orig_word);
      if (col==1) {
         line_prefix="";
      }else{
         line_prefix=indent_string(col-1);
      }
      replace_line(line_prefix);
      p_col=col;
      return(expand_alias(word,"",aliasfilename));
   }
   if ( word=="") return(1);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   
   syntax_indent := p_SyntaxIndent;
   _str maybespace = (p_no_space_before_paren) ? "" : ' ';
   _str parens = (p_pad_parens) ? '(  )':'()';
   int paren_offset = (p_pad_parens) ? 2 : 1;
   paren_width := length(parens);
   
   be_style := p_begin_end_style;
   _str be0 = (be_style & (BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3)) ? "" : ' {';
   be_width := length(be0);

   set_surround_mode_start_line();
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   if ( word=='foreach' ) {
      _str foreach_parens = (p_pad_parens) ? '(  in  )':'( in )';
      replace_line(line :+ maybespace :+ foreach_parens :+ be0);
      up(haskell_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='if' || word=='while' || word=='switch') { 
      replace_line(line :+ maybespace :+ parens :+ be0);
      up(haskell_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='trap' || word=='finally' || word=='do') { 
      replace_line(line :+ be0);
      int up_count = haskell_insert_braces(syntax_indent,be_style,width);
      if (word == 'do') {
         end_line();
         if (be_style == BES_BEGIN_END_STYLE_3) {
            insert_line(indent_string(width));
            _insert_text('while' :+ maybespace :+ parens);
         } else {
            _insert_text(' while' :+ maybespace :+ parens);
         }
      }
      up(up_count);
      insert_line(indent_string(width+syntax_indent));
      if ( ! _insert_state() ) { _insert_toggle(); }
   }
   
   do_surround_mode_keys();
   return status;
}
*/
