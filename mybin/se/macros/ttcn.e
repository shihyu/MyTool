////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45485 $
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
// Language support module for TTCN-3 (Testing Language)
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
#import "csymbols.e"
#import "ccontext.e"
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

#define TTCN_MODE_NAME 'TTCN-3'
#define TTCN_LANGUAGE_ID 'ttcn3'
#define TTCN_LEXERNAME  'TTCN-3'
#define TTCN_EXTENSION 'ttcn'
#define TTCN_WORD_CHARS 'a-zA-Z0-9_'

defload()
{
   _str setup_info='MN='TTCN_MODE_NAME',TABS=+3,MA=1 74 1,':+
                   'KEYTAB='TTCN_LANGUAGE_ID'-keys,WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='TTCN_WORD_CHARS',LN='TTCN_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='3 1 1 0 0 1 0';
   _str be_info='';
   int kt_index=0;
   _CreateLanguage(TTCN_LANGUAGE_ID, TTCN_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension(TTCN_EXTENSION, TTCN_LANGUAGE_ID);
}

_command ttcn_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(TTCN_LANGUAGE_ID);
}

int _ttcn3_MaybeBuildTagFile(int &tfindex)
{
   _str langid = 'ttcn3';
   _str tagfilename = '';
   if (ext_MaybeRecycleTagFile(tfindex, tagfilename, langid, langid)) {
      return(0);
   }

   int status = ext_MaybeBuildTagFile(tfindex, langid, langid, "TTCN-3 Builtins");
   return 0;
}

static SYNTAX_EXPANSION_INFO ttcn3_space_words:[] = {
   'do'             => { "do { ... } while ( ... )" },
   'foreach'        => { "foreach ( in ) { ... }" },
   'if'             => { "if ( ... ) { ... }" },
   'trap'           => { "trap { ... }" },
   'finally'        => { "finally { ... }" },
   'switch'         => { "switch ( ... ) { ... }" },
   'while'          => { "while ( ... ) { ... }" }
};

static int ttcn3_insert_braces(int syntax_indent,int be_style,int width)
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

static _str ttcn3_expand_space()
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
   _str word=min_abbrev2(orig_word,ttcn3_space_words,name_info(p_index),aliasfilename);

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
   if ( word=='for' ) {
      _str foreach_parens = (p_pad_parens) ? '(  in  )':'( in )';
      replace_line(line :+ maybespace :+ foreach_parens :+ be0);
      up(ttcn3_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='if' || word=='while' || word=='switch') { 
      replace_line(line :+ maybespace :+ parens :+ be0);
      up(ttcn3_insert_braces(syntax_indent,be_style,width));
      p_col=width + 1 + word._length() + maybespace._length() + paren_offset;
      if ( ! _insert_state() ) { _insert_toggle(); }
   } else if (word=='trap' || word=='finally' || word=='do') { 
      replace_line(line :+ be0);
      int up_count = ttcn3_insert_braces(syntax_indent,be_style,width);
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

int _ttcn3_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, ttcn3_space_words, prefix, min_abbrev);
}

_command ttcn3_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      ttcn3_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}

_command void ttcn3_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}

/////////////////////////////////////////
// Context tagging functions
/////////////////////////////////////////
int _ttcn3_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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
_str _ttcn3_get_decl(_str lang,
                    VS_TAG_BROWSE_INFO &info,
                    int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   int tag_flags=info.flags;
   _str tag_name=info.member_name;
   _str class_name=info.class_name;
   _str type_name=info.type_name;
   int in_class_def=(flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   int verbose=(flags&VSCODEHELPDCLFLAG_VERBOSE);
   int show_class=(flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   int show_access=(flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   _str arguments = (info.arguments!='')? '('info.arguments')':'';
   _str class_sep = '.';

   switch (type_name) {
   case 'typedef':      // type definition
      return(decl_indent_string'type 'tag_name);
   case 'enum':      // type definition
      return(decl_indent_string'enumerated 'tag_name);
   case 'class':
      return(decl_indent_string'component 'tag_name);
   case 'struct':
      // ports, sets, and records all use 'struct', but the 
      // TTCN type name (for display) in the the return_type
      return(decl_indent_string:+info.return_type' 'tag_name);
   case 'proc':
      return(decl_indent_string'altstep 'tag_name);
   default:
      return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));

   }
}



