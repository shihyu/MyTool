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
// Language support module for Windows PowerShell
// TSFKA (the shell formerly known as) Microsoft Command Shell, Monad shell
// 
#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#include 'tagsdb.sh'
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define POWERSHELL_MODE_NAME 'Windows PowerShell'
#define POWERSHELL_LANGUAGE_ID 'powershell'
#define POWERSHELL_LEXERNAME  'Windows PowerShell'
#define POWERSHELL_EXTENSION 'ps1'
#define POWERSHELL_WORD_CHARS 'a-zA-Z0-9_$-'

defload()
{
   _str setup_info='MN='POWERSHELL_MODE_NAME',TABS=+3,MA=1 74 1,':+
                   'KEYTAB='POWERSHELL_LANGUAGE_ID'-keys,WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='POWERSHELL_WORD_CHARS',LN='POWERSHELL_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='3 1 1 0 0 1 0';
   _str be_info='';
   int kt_index=0;
   _CreateLanguage(POWERSHELL_LANGUAGE_ID, POWERSHELL_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension(POWERSHELL_EXTENSION, POWERSHELL_LANGUAGE_ID);
}

_command ps1_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(POWERSHELL_LANGUAGE_ID);
}

static SYNTAX_EXPANSION_INFO powershell_space_words:[] = {
   'do'             => { "do { ... } while ( ... )" },
   'foreach'        => { "foreach ( in ) { ... }" },
   'if'             => { "if ( ... ) { ... }" },
   'trap'           => { "trap { ... }" },
   'finally'        => { "finally { ... }" },
   'switch'         => { "switch ( ... ) { ... }" },
   'while'          => { "while ( ... ) { ... }" }
};

static int powershell_insert_braces(int syntax_indent,int be_style,int width)
{
   int up_count = 0;
   if ( be_style == BES_BEGIN_END_STYLE_3 ) {
      width=width+syntax_indent;
   }
   up_count=1;
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
   set_surround_mode_end_line();
   return up_count;
}

static _str powershell_expand_space()
{
   int status=0;
   _str line='';
   get_line(line);
   line=strip(line,'T');
   _str orig_word=lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,powershell_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
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

   doNotify := true;
   if ( word=='foreach' ) {
      _str foreach_parens = (p_pad_parens) ? '(  in  )':'( in )';
      replace_line(line :+ maybespace :+ foreach_parens :+ be0);
      up(powershell_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='if' || word=='while' || word=='switch') { 
      replace_line(line :+ maybespace :+ parens :+ be0);
      up(powershell_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='trap' || word=='finally' || word=='do') { 
      replace_line(line :+ be0);
      int up_count = powershell_insert_braces(syntax_indent,be_style,width);
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

int _powershell_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, powershell_space_words, prefix, min_abbrev);
}

_str powershell_proc_search(_str &proc_name,boolean find_first)
{
   // ^:b*{#0(function|filter|alias|cmdlet)}:b{#0([a-z0-9\-]#)}
   // or for existing
   // ^:b*{#0(function|filter|alias|cmdlet)}:b{#1(proc-name)}
   _str searchOptions = '@riXc';
   _str procSearchName = '[a-z0-9\-]#';
   _str rePart1 = '^[ \t]*{#0(function|filter|alias|cmdlet)}:b{#1(';
   _str rePart2 = ')}';

   if ( proc_name != '' ) {
      procSearchName = _escape_re_chars(proc_name);
   }

   _str search_key= rePart1 :+ procSearchName :+ rePart2;
   int status=0;
   //_str search_key='^[\[]'proc_name'[\]]';
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
      // Pick out the name of this function, filter, or alias
      // from the tagged expression #1
      int groupStart = match_length('S1');
      int groupLen = match_length('1');
      _str tempFoundProc = get_text(groupLen, groupStart);

      groupStart = match_length('S0');
      groupLen = match_length('0');
      _str procType = get_text(groupLen, groupStart);

      _str type_name = '';
      _str arguments = '';
      int tag_flags = 0;
      if(strieq('function', procType))
      {
         type_name = 'function';
         // TODO: Search down from within the enclosing brace
         // for the param keyword, and add the arguments spec
      }
      else if (strieq('filter', procType))
      {
         type_name = 'proc';
      }
      else if (strieq('alias', procType))
      {
         type_name = 'typedef';
      }
      else if (strieq('cmdlet', procType))
      {
         type_name = 'class';
         // TODO: When PowerShell v2 cmdlet syntax is finalized, add
         // support for the child param, begin, process, and end blocks
         // when present
      }

      proc_name = tag_tree_compose_tag(tempFoundProc, '', type_name, tag_flags, arguments);
   }
   return(status);
}

_command powershell_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      powershell_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}

_command void powershell_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}

/**
 * Build tag file for Windows PowerShell
 *
 * @param tfindex   Tag file index
 */
int _powershell_MaybeBuildTagFile(int &tfindex)
{
   _str ext=POWERSHELL_EXTENSION;
   _str basename=POWERSHELL_LANGUAGE_ID;

   // maybe we can recycle tag file(s)
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
      return(0);
   }
   tag_close_db(tagfilename);

   // Build tags from powershell.tagdoc or builtins.ps1
   int status=0;
   _str extra_file=ext_builtins_path(ext,'powershell');
   if(extra_file!='') {
         status=shell('maketags -n "PowerShell Libraries" -o ' :+
                      maybe_quote_filename(tagfilename)' ' :+
                      maybe_quote_filename(extra_file));
   }
   LanguageSettings.setTagFileList(POWERSHELL_LANGUAGE_ID, tagfilename, true);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   return(status);
}
