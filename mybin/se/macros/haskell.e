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
//
// Language support module for Haskell
// 
#pragma option(pedantic,on)

#region Imports
#include 'slick.sh'
#include 'tagsdb.sh'
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
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

#define HASKELL_MODE_NAME 'Haskell'
#define HASKELL_LANGUAGE_ID 'haskell'
#define HASKELL_LEXERNAME  'Haskell'
#define HASKELL_EXTENSION 'hs'
#define HASKELL_WORD_CHARS 'a-zA-Z0-9_'
#define HASKELL_KEYS_TABLE 'haskell-keys'

defload()
{
   _str setup_info='MN='HASKELL_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='HASKELL_KEYS_TABLE',WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='HASKELL_WORD_CHARS',LN='HASKELL_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 0 1 0';
   _str be_info='';
   int kt_index=0;
   _CreateLanguage(HASKELL_LANGUAGE_ID, HASKELL_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension(HASKELL_EXTENSION, HASKELL_LANGUAGE_ID);
}

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
int _haskell_MaybeBuildTagFile(int &tfindex)
{
   _str ext=HASKELL_EXTENSION;
   _str basename=HASKELL_LANGUAGE_ID;

   // maybe we can recycle tag file(s)
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
      return(0);
   }
   tag_close_db(tagfilename);

   // Build tags from haskell.tagdoc or builtins.hs
   int status=0;
   _str extra_file=ext_builtins_path(ext,basename);
   if(extra_file!='') {
         status=shell('maketags -n "Haskell Prelude" -o ' :+
                      maybe_quote_filename(tagfilename)' ' :+
                      maybe_quote_filename(extra_file));
   }
   LanguageSettings.setTagFileList(HASKELL_LANGUAGE_ID, tagfilename, true);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   return(status);
}

/**
 * Haskell implementation of the ext_proc_search callback. Searches for Haskell 
 * function, data, and type declarations in the current source file. 
 */
_str haskell_proc_search(_str &proc_name,boolean find_first)
{
   // Search for identifiers starting in the first column, which
   // are followed by as assignment operator (read as "meaning")
   // also...
   // Search for class and data declarations
   // Search for prototypes

   // This search is overly broad, but effective for this
   // purpose, at least until a full-blown lexer can be
   // written.
   _str searchOptions = '@riXcs'; // Do not search in comments or strings
   _str search_key= '^([a-z_][a-zA-Z0-9_]#[^\=]#)(\=|(\:\:))[^\n]#';
   int status=0;
   //_str search_key='^[\[]'proc_name'[\]]';
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
      // This is just a candidate line. Just get the whole
      // line from it and try to narrow it down.
      int groupStart = match_length('S');
      int groupLen = match_length('');
      _str wholeLine = get_text(groupLen, groupStart);

      _str decl_identifier = '';
      _str type_name = '';
      _str arguments = '';
      int tag_flags = 0;

      // See if it's a data identifier
      if(pos('^data:b#{#1[A-Z][a-zA-Z0-9_]#}',
              wholeLine, 1, 'r') > 0) {
         // Is it an algebraic ?
         if(pos('^data:b{#0[A-Z][a-zA-Z0-9_]*}(:b)*=(:b)*{#1[A-Z][a-zA-Z0-9_]*(:b)*}{#2\|(:b)*[^\n]#}',
                 wholeLine, 1, 'r') > 0) {
            // A valid algebraic type. Or at least, valid enough
            // for this rough style of checking
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
            // Group 1 and Group 2 concatenated is the full signature
            // of the enumeration names
            _str enumPartOne = substr(wholeLine,pos('S1'),pos('1'));
            _str enumPartTwo = substr(wholeLine,pos('S2'),pos('2'));
            arguments = enumPartOne :+ enumPartTwo;
            type_name = 'enum';
         }
         else if(pos('^data:b#{#0[A-Z][a-zA-Z0-9_]#}(:b)*\={#1((:b)*(\[*)[A-Z][a-zA-Z0-9_]#(\]*))#}(:b)*$',
                     wholeLine, 1, 'r') > 0){
            // A valid user-defined data type (so far at least...)
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
            // Group 1 is the full signature (at least the first line sig)
            arguments = substr(wholeLine,pos('S1'),pos('1'));
            type_name = 'struct';
         }

         // Return early if not set yet
         if(type_name == '') {
            return 1;
         }
      }
      
      // See if it's a type identifier
      if(pos('^type:b{#0[A-Z][a-zA-Z0-9_]*}(:b)*\=((:b)*{#1([\[\(]*)[A-Z][a-zA-Z0-9_]#[^\n]#})$',
             wholeLine, 1, 'r') > 0) {
         // Group 0 is the name (typedef)
         decl_identifier = substr(wholeLine,pos('S0'),pos('0'));
         // Group 1 is the original type
         arguments = substr(wholeLine,pos('S1'),pos('1'));
         type_name = 'typedef';
      }
      
      if(type_name == '') {
         // See if it's a function prototype
         if(pos('^([_a-z][a-zA-Z0-9_]*)\s*::\s*([a-zA-Z\[\(][^\n]*)$',
                wholeLine, 1, 'l') > 0) {
            // Group 0 is the name
            decl_identifier = substr(wholeLine,pos('S1'),pos('1'));
            // Group 1 is the argument (with last being evaluation reduction type)
            arguments = substr(wholeLine,pos('S2'),pos('2'));
            type_name = 'proto';  
         }
      }

      if(type_name == '') {
         // Last gasp. Could be a function declaration, which is
         // the hardest one to parse, and the most common
      }

      if(type_name != '') {
         proc_name = tag_tree_compose_tag(decl_identifier, '', type_name, tag_flags, arguments);
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
 * @return boolean If true, layout alignment was done. Otherwise, false, which falls 
 *         through to default ENTER behavior
 */
boolean _haskell_expand_enter()
{
   if( command_state()                  ||  // Do not expand if the visible cursor is on the command line
       (p_window_state:=='I')           ||  // Do not expand if window is iconified
       _in_comment(1)){                     // Do not expand if you are inside of a comment
      return true;
   }
   
   int caretNowAt = p_col;
   if(caretNowAt > 3) {
      get_line(auto currentLine);
      // See if this line looks like a function declaration, and if there is at least
      // one non-space char after the equals sign. That is what we'll align on.
      if(pos('^[a-z_][a-zA-Z0-9_]#([^\=])#\=(:b)#{:a|[\(\[]}', currentLine, 1, 'r') > 0){
         int indentPos = pos('S0');
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
 
_command void haskell_enter() 
   name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL) 
{
   generic_enter_handler(_haskell_expand_enter);
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
   } else if (_argument=='') {
      _undo('S');
   }

} 
*/

/* 
static _str haskell_expand_space() { 
   //updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT); //syntax_indent =
   p_SyntaxIndent;

   int status=0;
   _str line='';
   get_line(line);
   line=strip(line,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str mult_line_info='';
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,haskell_space_words,name_info(p_index),aliasfilename);
   if (aliasfilename==null) return(0);
   if (word!=''&&aliasfilename!='') {
      if (orig_word:==word && orig_word==get_alias(word,mult_line_info,1,aliasfilename)) {
         _insert_text(' ');
         return(0);
      }
      _str line_prefix='';
      int col=p_col-_rawLength(orig_word);
      if (col==1) {
         line_prefix='';
      }else{
         line_prefix=indent_string(col-1);
      }
      replace_line(line_prefix);
      p_col=col;
      return(expand_alias(word,'',aliasfilename));
   }
   if ( word=='') return(1);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   
   syntax_indent := p_SyntaxIndent;
   _str maybespace = (p_no_space_before_paren) ? '' : ' ';
   _str parens = (p_pad_parens) ? '(  )':'()';
   int paren_offset = (p_pad_parens) ? 2 : 1;
   int paren_width = length(parens);
   
   be_style := p_begin_end_style;
   _str be0 = (be_style & (BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3)) ? '' : ' {';
   int be_width = length(be0);

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
