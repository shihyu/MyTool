////////////////////////////////////////////////////////////////////////////////////
// $Revision: 42496 $
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
#import "adaptiveformatting.e"
#require "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "notifications.e"
#import "pmatch.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

#define SCALA_LANG_ID    'scala'
#define SCALA_MODE_NAME  'Scala'
#define SCALA_LEXERNAME  'Scala'
#define SCALA_WORDCHARS  'A-Za-z0-9_'

defload()
{
   _str setup_info='MN='SCALA_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='SCALA_LANG_ID'-keys,WW=1,IWT=0,ST=0,IN=2,WC='SCALA_WORDCHARS',LN='SCALA_LEXERNAME',CF=1,LNL=0,TL=0,BNDS=,CAPS=0,SW=0,SOW=0,';
   _str compile_info='';
   _str syntax_info='2 1 1 0 0 3 0';
   _str be_info='';
   _CreateLanguage(SCALA_LANG_ID, SCALA_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("scala", SCALA_LANG_ID);
   LanguageSettings.setAutoBracket(SCALA_LANG_ID, AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT);
}

_command void scala_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(SCALA_LANG_ID);
}

defeventtab scala_keys;
def 'ENTER' = scala_enter;
def ' '     = scala_space;

static SYNTAX_EXPANSION_INFO scala_space_words:[] = {
   'def'       => { "def" },
   'object'    => { "object" },
   'class'     => { "class" },
   'trait'     => { "trait" },
   'package'   => { "package" },
   'for'       => { "for (...)" },
   'if'        => { "if (...)" },
   'while'     => { "while (...)" },
};

int _scala_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, scala_space_words, prefix, min_abbrev);
}

static _str _scala_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);
   typeless status = 0;
   _str orig_line = "";
   get_line(orig_line);
   _str line = strip(orig_line, 'T');
   _str orig_word = strip(line);
   if (p_col != text_col(_rawText(line)) + 1) {
      return(1);
   }

   int width = -1;
   _str aliasfilename = '';
   _str word=min_abbrev2(orig_word, scala_space_words, name_info(p_index), aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return(expandResult != 0);
   }
   if (word == '') {
      return(1);
   }
   typeless block_info = "";
   line = substr(line, 1, length(line) - length(orig_word)):+word;
   if (width < 0) {
      width = text_col(_rawText(line), _rawLength(line) - _rawLength(word) + 1, 'i') - 1;
   }
   orig_word = word;
   word = lowcase(word);
   doNotify := true;
   clear_hotspots();
   if (word == 'if' || word == 'while' || word == 'for') {
      replace_line(line:+' ()');
      _end_line(); add_hotspot();
      p_col = p_col - 1; add_hotspot();

   } else if (word) {
      replace_line(line:+' '); _end_line(); 
      doNotify = false;


   } else {
      status = 1;
      doNotify = false;
   }
   show_hotspots();
   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }
   return(status);
}

_command void scala_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _scala_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}

boolean _scala_expand_enter()
{
// updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
// syntax_indent := p_SyntaxIndent;
   return(true);
}

_command void scala_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_scala_expand_enter, true);
}

