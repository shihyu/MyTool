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
#include "se/adapt/all.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/adapt/GenericAdaptiveFormattingScanner.e"
#require "se/lang/html/HTMLAdaptiveFormattingScanner.e"
#require "se/lang/cpp/CPPAdaptiveFormattingScanner.e"
#require "se/lang/pas/PascalAdaptiveFormattingScanner.e"
#require "se/lang/tcl/TCLAdaptiveFormattingScanner.e"
#require "se/lang/dbase/DBaseAdaptiveFormattingScanner.e"
#import "slickc.e"
#import "c.e"
#import "clipbd.e"
#import "context.e"
#import "listproc.e"
#import "main.e"
#import "mprompt.e"
#import "notifications.e"
#import "optionsxml.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "util.e"
#import "math.e"
#endregion

using namespace se.lang.api;
using namespace se.adapt;

/** 
 *  To add adaptive formatting support for a language: 
 *  All languages will automatically have AF support for indent settings (syntax
 *  indent, tab settings, indent with tabs).  You don't need to do anything to
 *  get those.  However, you will need to do a little work to get support for
 *  any of the other settings.
 *  
 *  1.  Insert calls to updateAdaptiveFormattingSettings within syntax 
 *  expansion. See _c_expand_space.  It's best to call this function right
 *  before you are about to use one of the buffer settings.  Call it with
 *  whatever flags correspond to the relevant settings.
 *  
 *  2.  Add adaptive formatting links to the Language Formatting Options.  Use
 *  the function setAdaptiveLinks() to automatically set up the checkboxes.  See
 *  _c_extform.
 *  
 *  3.  Add a case for your new language in the switch statement under
 *  getAdaptiveFormattingScanner().
 *  
 *  Declare a scanner.  Unless your language inherits from a language which has
 *  a special scanner, you'll probably use the GenericAdaptiveFormattingScanner.
 *  The constructor takes a set of flags which define which formatting options
 *  it can scan for.   These flags are part of the AdaptiveFormattingFlags
 *  enum_flags.
 *  
 *  Some flags also require special setup to tell the scanner what to look 
 *  for: 
 *  AFF_BEGIN_END_STYLE: 
 *     scanner.SetBeginEndStyle() - sets the words which begin a begin/end
 *     structure.  For C-like languages, this includes things like if, while,
 *     for, etc - whatever words are used in syntax expansion to expand to the
 *     selected brace style.  These words are sent as a single string, with
 *     each word separated by a logical OR ('|').
 *   
 *  AFF_PAD_PARENS 
 *  AFF_NO_SPACE_BEFORE_PAREN 
 *     scanner.SetParenStyle() - sets the words which come before a
 *     parenthetical.  For C-like languages, this includes if, for, etc.
 *     These words are  sent as a single string, with each word separated by a
 *     logical OR ('|').
 *   
 *  AFF_INDENT_CASE
 *     scanner.setSwitch() - takes two arguments, the first being the word
 *     which defines a switch statement ("switch" in C++) and the second being
 *     a list of words which define the cases (case, default in C++).
 *   
 *  You can also call scanner.setIndentRequiresPrevChars() and send a list of 
 *  characters that would be at the end of a line where the next line would 
 *  change indent.  Unless you are using a C-style language, do not call this 
 *  method. 
 */
int def_max_retry_adaptive_format_lines=300;

struct AdaptiveFormattingSettings {
   int BeginEndStyle;
   int SyntaxIndent;
   int IndentCaseFromSwitch;
   int PadParens;
   int NoSpaceBeforeParens;
   int IndentWithTabs;
   int KeywordCasing;
   int TagCasing;
   int AttributeCasing;
   int ValueCasing;
   int HexValueCasing;
   _str Tabs;

   // used for indexing Embedded languages
   int Flags;
   _str BufferName;
};

AdaptiveFormattingSettings g_AdFormEmbeddedSettings:[]:[] = null;

int adaptive_format_get_available_for_language(_str langID)
{
   switch (langID) {
   case "process":
   case "fileman":
   case "grep":
      return 0;
   }

   class se.adapt.AdaptiveFormattingScannerBase scanner;
   scanner = getAdaptiveFormattingScanner(langID, '');
   if (scanner == null) return 0;

   return scanner.getAvailableSettings();
}

void adaptive_format_clear_flag_for_buffer(int flag)
{
   // check the flags for this language - if the flag is included in there, 
   // we don't want to clear it, because that means we would be searching 
   // for a setting the user doesn't want
   if (adaptive_format_get_buffer_flags() & flag) return;

   // get the current flags for this buffer
   current := p_adaptive_formatting_flags;

   // clear out the specified flag
   current &= ~flag;

   // now reset the flags
   p_adaptive_formatting_flags = current;
}

void adaptive_format_clear_embedded(_str lang)
{
   typeless i;
   for (i._makeempty();;) {
      g_AdFormEmbeddedSettings._nextel(i);
      if (i._isempty()) break;
      if (g_AdFormEmbeddedSettings:[i]._indexin(lang)) {
         g_AdFormEmbeddedSettings:[i]._deleteel(lang);
      }
   }
}

void adaptive_format_remove_buffer(int bufID)
{
   if (g_AdFormEmbeddedSettings==null) return;
   // delete adaptive formatting embedded settings for this buffer, if they exist
   if (g_AdFormEmbeddedSettings._indexin(bufID)) {
      g_AdFormEmbeddedSettings._deleteel(bufID);
   }
}

/**
 * Returns the flags to be set as the buffer property 
 * p_adaptive_formatting_flags.  Note that this includes both 
 * the language flags and the on/off flag for the entire 
 * feature.  To just retrieve the flags for the language, use 
 * adaptive_format_get_language_flags. 
 * 
 * @param _str lang           the langID to be retrieved - '' 
 *                            returns for the current buffer
 * 
 * @return int                buffer flags
 */
int adaptive_format_get_buffer_flags(_str lang = '')
{
   if (lang=='') {
      if (_isEditorCtl()) {
         lang = p_LangId;
      }
   }
   if (!LanguageSettings.getUseAdaptiveFormatting(lang)) return -1;

   return adaptive_format_get_language_flags(lang);
}

/** 
 * Get the adaptive formatting flags for the specified language. 
 * 
 * @param lang       language for which to retrieve flags - '' 
 *                   means retrieve for current buffer
 * 
 * @return int       adaptive formatting flags - if a flag is 
 *                   ORed in, that means that we DON'T look for
 *                   it
 */
int adaptive_format_get_language_flags(_str lang='')
{
   if (lang=='') {
      if (_isEditorCtl()) {
         lang = p_LangId;
      } else {
         return def_adaptive_formatting_flags;
      }
   }
   return LanguageSettings.getAdaptiveFormattingFlags(lang);
}

bool adaptive_format_is_adaptive_on(_str lang='')
{
   if (lang=='') {
      if (_isEditorCtl()) {
         lang = p_LangId;
      } else {
         return def_adaptive_formatting_on;
      }
   }

   return LanguageSettings.getUseAdaptiveFormatting(lang);
}

void adaptive_format_set_adaptive_on(bool value, _str lang = '')
{
   if (lang=='') {
      if (_isEditorCtl()) {
         lang = p_LangId;
      } 
   }

   if (lang != '') {
      LanguageSettings.setUseAdaptiveFormatting(lang, value);

      if (value) {
         // Reset p_adaptive_formatting_flags for open buffers 
         // so they won't be shut out from having adaptive formatting
         // analyze them.
         adaptive_format_reset_buffers(0, lang, true);
      } else {
         // Turning off, set p_adaptive_formatting_flags to -1, and revert
         // to the language defaults.
         adaptive_format_reset_buffers(-1, lang, true);
      }
   }
}

/** 
 * Checks whether a particular flag is to be searched for during 
 * adaptive formatting. 
 * 
 * @param flags            flag to be checked (member of 
 *                         AdaptiveFormattingSettings)
 * @param lang             language to be checked
 * 
 * @return bool            whether adaptive formatting is on for 
 *                         that setting in that language
 */
bool adaptive_format_is_flag_on_for_buffer(int flags, _str lang, int adaptiveFlags = null) 
{
   if (adaptiveFlags == null) {
      adaptiveFlags = adaptive_format_get_buffer_flags(lang);
   }
   return ((flags & adaptiveFlags) == 0);
}

bool adaptive_format_is_flag_on_for_language(int flags, _str lang, int adaptiveFlags = null)
{
   if (adaptiveFlags == null) {
      adaptiveFlags = adaptive_format_get_language_flags(lang);
   }
   return ((flags & adaptiveFlags) == 0);
}

/** 
 * Reverts the current buffer's settings to the language 
 * default, overriding any that might have been found using 
 * adaptive formatting. 
 * 
 * @param flags      settings to be reverted
 */
void revertCurrentBuffer(int flags)
{
   bufId := _mdi.p_child;

   langid := bufId.p_LangId;
   //VS_LANGUAGE_OPTIONS options;
   //_GetDefaultLanguageOptions(bufId.p_LangId, options);

   // check for tabs, syntax indent, indent with tabs
   //if (options != null) {
      if (flags & AFF_SYNTAX_INDENT) {
         bufId.p_SyntaxIndent = _LangGetPropertyInt32(langid,LOI_SYNTAX_INDENT);
      }
      if (flags & AFF_TABS) {
         bufId.p_tabs = _LangGetProperty(langid,VSLANGPROPNAME_TABS,"+8");
      }
      if (flags & AFF_INDENT_WITH_TABS) {
         bufId.p_indent_with_tabs = _LangGetPropertyInt32(langid,VSLANGPROPNAME_INDENT_WITH_TABS) != 0;
      }
      if (flags & AFF_BEGIN_END_STYLE) {
         bufId.p_begin_end_style = _LangGetPropertyInt32(langid,LOI_BEGIN_END_STYLE);
      }
      if (flags & AFF_INDENT_CASE) {
         bufId.p_indent_case_from_switch = _LangGetPropertyInt32(langid,LOI_INDENT_CASE_FROM_SWITCH) != 0;
      }
      if (flags & AFF_NO_SPACE_BEFORE_PAREN) {
         bufId.p_no_space_before_paren = _LangGetPropertyInt32(langid,LOI_NO_SPACE_BEFORE_PAREN) != 0;
      }
      if (flags & AFF_PAD_PARENS) {
         bufId.p_pad_parens = _LangGetPropertyInt32(langid,LOI_PAD_PARENS) != 0;
      }
      if (flags & AFF_KEYWORD_CASING) {
         bufId.p_keyword_casing = _LangGetPropertyInt32(langid,LOI_KEYWORD_CASE);
      }
      if (flags & AFF_TAG_CASING) {
         bufId.p_tag_casing = _LangGetPropertyInt32(langid,LOI_TAG_CASE);
      }
      if (flags & AFF_ATTRIBUTE_CASING) {
         bufId.p_attribute_casing = _LangGetPropertyInt32(langid,LOI_ATTRIBUTE_CASE);
      }
      if (flags & AFF_VALUE_CASING) {
         bufId.p_value_casing = _LangGetPropertyInt32(langid,LOI_WORD_VALUE_CASE);
      }
      if (flags & AFF_HEX_VALUE_CASING) { 
         bufId.p_hex_value_casing = _LangGetPropertyInt32(langid,LOI_HEX_VALUE_CASE);
      }
   //}

   bufId.p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(bufId.p_LangId);
}

/** 
 * Creates an update string to be used to revert buffer settings 
 * back to language defaults.  Only uses settings specified by 
 * flags. 
 * 
 * @param flags      settings to be reverted (members of 
 *                   AdaptiveFormattingSettings)
 * @param lang       language to be reset
 * 
 * @return _str      update string to be sent to update_buffers
 */
_str compileUpdateString(int flags, _str lang)
{
   ustr := '';

   VS_LANGUAGE_OPTIONS options;
   if (_GetDefaultLanguageOptions(lang, options) != 0) {
      return '';
   }

   // check for tabs, syntax indent, indent with tabs
   if (flags & AFF_SYNTAX_INDENT) {
      ustr :+= SYNTAX_INDENT_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_SYNTAX_INDENT,0)',';
   }
   if (flags & AFF_TABS) {
      ustr :+= TABS_UPDATE_KEY'='_LangOptionsGetProperty(options,VSLANGPROPNAME_TABS)',';
   }
   if (flags & AFF_INDENT_WITH_TABS) {
      ustr :+= INDENT_WITH_TABS_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,VSLANGPROPNAME_INDENT_WITH_TABS,0)',';
   }
   if (flags & AFF_BEGIN_END_STYLE) {
      ustr :+= BEGIN_END_STYLE_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_BEGIN_END_STYLE,0)',';
   }
   if (flags & AFF_INDENT_CASE) {
      ustr :+= INDENT_CASE_FROM_SWITCH_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_INDENT_CASE_FROM_SWITCH,0)',';
   }
   if (flags & AFF_NO_SPACE_BEFORE_PAREN) {
      ustr :+= NO_SPACE_BEFORE_PAREN_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_NO_SPACE_BEFORE_PAREN,0)',';
   }
   if (flags & AFF_PAD_PARENS) {
      ustr :+= PAD_PARENS_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_PAD_PARENS,0)',';
   }
   if (flags & AFF_KEYWORD_CASING) {
      ustr :+= KEYWORD_CASING_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_KEYWORD_CASE,0)',';
   }
   if (flags & AFF_TAG_CASING) {
      ustr :+= TAG_CASING_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_TAG_CASE,0)',';
   }
   if (flags & AFF_ATTRIBUTE_CASING) {
      ustr :+= ATTRIBUTE_CASING_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_ATTRIBUTE_CASE,0)',';
   }
   if (flags & AFF_VALUE_CASING) {
      ustr :+= VALUE_CASING_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_WORD_VALUE_CASE,0)',';
   }
   if (flags & AFF_HEX_VALUE_CASING) { 
      ustr :+= HEX_VALUE_CASING_UPDATE_KEY'='_LangOptionsGetPropertyInt32(options,LOI_HEX_VALUE_CASE,0)',';
   }

   ustr :+= ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY'='adaptive_format_get_buffer_flags(lang);

   return ustr;
}

/** 
 * Resets all buffers of one language or the current buffer to 
 * the settings specified by language defaults.  Overrides any 
 * settings found by adaptive formatting. 
 * 
 * @param flags         settings to be reset (see 
 *                      AdaptiveFormattingSettings)
 * @param lang          language to be reset, 
 *                      '' for current buffer only
 * @param force         Reset the af flags, even if af wasn't 
 *                      enabled.  
 */
void adaptive_format_reset_buffers(int flags = -1, _str lang = '', 
                                   bool force = false)
{
   // no language means only reset the current buffer
   if (lang == '') {
      if (_isEditorCtl() && (force || LanguageSettings.getUseAdaptiveFormatting(p_LangId))) {
         revertCurrentBuffer(flags);
      }
   } else {
      // compile our list of settings to reset to language settings
      if (force || LanguageSettings.getUseAdaptiveFormatting(lang)) {
         _update_buffers(lang, compileUpdateString(flags, lang));
      }
   }

   // Make sure there are no cached settings. 
   index:=find_index("_beautifier_cache_clear",PROC_TYPE);
   if (index_callable(index)) call_index(lang,index);
}

/** 
 * Turns adaptive formatting off for the specified flags and 
 * language.
 * 
 * @param flags         flags to be turned off
 * @param lang          language for which to turn flags off
 */
void adaptive_format_turn_off(int flags, _str lang)
{
   adaptive_format_toggle_flags(0, flags, lang);
}

/** 
 * Turns adaptive formatting on for the specified flags and 
 * language.
 * 
 * @param flags         flags to be turned on
 * @param lang          language for which to turn flags on
 */
void adaptive_format_turn_on(int flags, _str lang)
{
   adaptive_format_toggle_flags(flags, 0, lang);
}

/** 
 * Toggles the flags specified for the given language. 
 * If a flag is specified to be turned off and on, then an 
 * error is returned. 
 * 
 * @param onFlags          flags to be turned on
 * @param offFlags         flags to be turned off
 * @param lang             language affected
 */
void adaptive_format_toggle_flags(int onFlags, int offFlags, _str lang)
{
   // it's not valid to turn the same flag on and off
   ASSERT(!(onFlags & offFlags));

   current := adaptive_format_get_language_flags(lang);

   // turn on these flags by taking them out
   if (current & onFlags) {
      current &= ~onFlags;
   }

   // turn off these flags by ORing them in
   if ((current & offFlags) != offFlags) {
      current |= offFlags; 
   }

   LanguageSettings.setAdaptiveFormattingFlags(lang, current);
   adaptive_format_reset_buffers(onFlags | offFlags, lang);
}

/** 
 * Returns an AdaptiveFormattingScanner based on the language.
 * 
 * @param lang    language ID
 * 
 * @return se.adapt.AdaptiveFormattingScannerBase
 */
se.adapt.AdaptiveFormattingScannerBase getAdaptiveFormattingScanner(_str lang, _str ext)
{
   se.adapt.AdaptiveFormattingScannerBase scanner = null;

   // don't bother
   if (lang == "fundamental") return null;

   // we are running the switch off of the language ID
   switch (lang) {
   // these languages only need keyword casing support
   case "ada":
   case "bas":
   case "cics":
   case "cob":
   case "cob74":
   case "cob2000":
   case "for":
   case "gl":
   case "pl1":
   case "plsql":
   case "pro":
   case "rexx":
   case "sabl":
   case "sas":
   case "sqlserver":
   case "ansisql":
   case "vbs":
   case "vhd":
      se.adapt.GenericAdaptiveFormattingScanner s(AFF_KEYWORD_CASING, lang);
      scanner = s;
      break;
   case "ansic":
   case "ch":
   case "cfscript":  // <cfscript>...</cfscript>
   case "phpscript":
   case "as":
   case "d":  // DigitalMars D
   case "m":  // Objective-C
   case "js":
      se.adapt.GenericAdaptiveFormattingScanner astext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      astext.setSwitch('switch','case|default');
      if (lang=='phpscript' || lang=="ch" || lang=="d") {
         astext.setParenStyle('if|while|foreach|switch|for');
      } else {
         astext.setParenStyle('if|while|for|switch');
      }
      if (lang=="ch" || lang=="ansic") {
         astext.setBeginEndStyle('do|if|while|for|switch');
      } else if (lang=="d") {
         astext.setBeginEndStyle('do|try|if|foreach|while|for|switch|loop');
      } else if (lang=='phpscript' || lang=="ch") {
         astext.setBeginEndStyle('do|try|if|foreach|while|for|switch');
      } else {
         astext.setBeginEndStyle('do|try|if|while|for|switch');
      }
      if (lang=="ansic" || lang=="ch" || lang=="phpscript" || lang=="m" || lang=="js" || lang=="d") {
         astext.setIndentRequiresPrevChars("){");
      }
      scanner = astext;
      break;
   case "prg":
      se.lang.dbase.DBaseAdaptiveFormattingScanner dbase(lang);
      scanner = dbase;
      break;
   case "tcl":
      se.lang.tcl.TCLAdaptiveFormattingScanner tcltext(lang);
      scanner = tcltext;
      break;
   case "html":
   case "cfml":
      se.lang.html.HTMLAdaptiveFormattingScanner htmltext(AFF_TAG_CASING | AFF_ATTRIBUTE_CASING | 
                                 AFF_VALUE_CASING | AFF_HEX_VALUE_CASING, lang);
      scanner = htmltext;
      break;
   case "xml":
   case "vpj":
   case "vpw":
      se.lang.html.HTMLAdaptiveFormattingScanner xmltext(0, lang);
      scanner = xmltext;
      break;
   case "vera":
      se.adapt.GenericAdaptiveFormattingScanner veratext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS, lang);
      veratext.setParenStyle('if|while|foreach|for|repeat');
      veratext.setBeginEndStyle('if|while|foreach|for|repeat');
      veratext.setIndentRequiresPrevChars("){");
      scanner = veratext;
      break;
   case "powershell":
      se.adapt.GenericAdaptiveFormattingScanner powershelltext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS, lang);
      powershelltext.setParenStyle('if|while|foreach|for|switch|do|trap|finally');
      powershelltext.setBeginEndStyle('if|while|foreach|for|switch|do|trap|finally');
      powershelltext.setIndentRequiresPrevChars("){");
      scanner = powershelltext;
      break;
   case "pas":
      /*
         Here the scanner uses p_LangId="pas" kto 
         determine the begin/end style.
      */
      se.lang.pas.PascalAdaptiveFormattingScanner pastext(lang);
      scanner = pastext;
      break;
   case "rul":
      // Not that C++ like but this scanner still works
      se.adapt.GenericAdaptiveFormattingScanner rultext(AFF_INDENT_CASE, lang);
      rultext.setSwitch('switch','case|default');
      scanner = rultext;
      break;
   case "awk":
      se.adapt.GenericAdaptiveFormattingScanner awktext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      awktext.setSwitch('switch','case|default');
      awktext.setParenStyle('if|while|for');
      awktext.setBeginEndStyle('do|if|while|for');
      scanner = awktext;
      break;
   case "pl":
      se.adapt.GenericAdaptiveFormattingScanner pltext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      // Couldn't find docs on select keyword
      pltext.setSwitch('switch','case|else');  // Perl 5.8
      pltext.setParenStyle('until|if|while|foreach|for');
      pltext.setBeginEndStyle('until|try|do|if|while|foreach|for|switch');
      scanner = pltext;
      break;
   case "coffeescript":
   case "py":
      // function no space before paren is not yet supported
      se.adapt.GenericAdaptiveFormattingScanner pytext(0, lang);
      scanner = pytext;
      break;

   case "cs":
      se.adapt.GenericAdaptiveFormattingScanner cstext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      cstext.setSwitch('switch','case|default');
      cstext.setParenStyle('if|while|foreach|for|switch');
      cstext.setBeginEndStyle('try|do|if|while|foreach|for|switch');
      cstext.setIndentRequiresPrevChars("){");
      scanner = cstext;
      break;
   case "jsl": // J#
   case "java":
      se.adapt.GenericAdaptiveFormattingScanner javatext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      javatext.setSwitch('switch','case|default');
      javatext.setParenStyle('if|while|for|switch');
      javatext.setBeginEndStyle('try|do|if|while|for|switch');
      javatext.setIndentRequiresPrevChars("){");
      scanner = javatext;
      break;
   case "e":
      se.adapt.GenericAdaptiveFormattingScanner etext(AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, lang);
      etext.setSwitch('switch','case|default');
      etext.setParenStyle('if|while|foreach|for|switch');
      etext.setBeginEndStyle('loop|do|if|while|foreach|for|switch');
      etext.setIndentRequiresPrevChars("){");
      scanner = etext;
      break;
   case "c":
      se.lang.cpp.CPPAdaptiveFormattingScanner cpptext(lang);
      prevChars := '){';
      // we make allowances for h files - a bit hacky, but should cover most cases
      if (ext == 'h') {
         // for the colon after private, public, protected
         prevChars :+= ':';
         // there is little indent in a .h file, so allow what we can
         cpptext.setIndentMinColumn(2);
      }
      cpptext.setIndentRequiresPrevChars(prevChars);
      scanner = cpptext;
      break;
   case "googlego":
      se.adapt.GenericAdaptiveFormattingScanner gotext(AFF_INDENT_CASE, lang);
      gotext.setSwitch('switch|select','case|default');
      scanner = gotext;
      break;
   default:      // we can always just figure out indent settings
      if (_LanguageInheritsFrom('html', lang)) {
         se.lang.html.HTMLAdaptiveFormattingScanner htmltext2(AFF_TAG_CASING | AFF_ATTRIBUTE_CASING | 
                                    AFF_VALUE_CASING | AFF_HEX_VALUE_CASING, lang);
         scanner = htmltext2;
         break;
      }
      if (_LanguageInheritsFrom('xml', lang)) {
         se.lang.html.HTMLAdaptiveFormattingScanner xmltext2(0, lang);
         scanner = xmltext2;
         break;
      }
      if (_LanguageInheritsFrom('r', lang)) {
         se.adapt.GenericAdaptiveFormattingScanner rtext(0, lang);
         rtext.setIndentMinColumn(2);
         scanner = rtext;
         break;
      }

      inheritsFrom := LanguageSettings.getLangInheritsFrom(lang);
      if (inheritsFrom != '') {
         scanner = getAdaptiveFormattingScanner(inheritsFrom, ext);
      } else {
         se.adapt.GenericAdaptiveFormattingScanner g(0, lang);
         scanner = g;
      }
   }

   return scanner;
}

int includeAllIndentSettings(int flag)
{
   syntaxFlags := AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS;
   // check to see if we have ANY of these settings
   if (flag & syntaxFlags) {
      // if so, then OR the rest of them in, too
      flag = flag | syntaxFlags;
   }
   return flag;
}

void setBeginEndStyle(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags,
                      int &validFlags)
{
   int braceStyle;
   status := scanner -> getBraceStyle(braceStyle, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_BEGIN_END_STYLE;
      if (p_begin_end_style != braceStyle) {
         p_begin_end_style = braceStyle;
         changedFlags |= AFF_BEGIN_END_STYLE;
      }
      p_adaptive_formatting_flags |= AFF_BEGIN_END_STYLE;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_BEGIN_END_STYLE;
   }  // else there was an error, so we'll try again next time
}

void setIndentSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int flag, int &changedFlags,
                       int& validFlags)
{
   se.adapt.AFIndentSettings indent;
   status := scanner -> getIndentSettings(indent, false);
   if (status == AF_RC_SUCCESS) {
      if ((flag & AFF_SYNTAX_INDENT) && (indent.SyntaxIndent != AF_RC_ERROR)) {
         validFlags |= AFF_SYNTAX_INDENT;
         if (p_SyntaxIndent != indent.SyntaxIndent) {
            p_SyntaxIndent = indent.SyntaxIndent;
            changedFlags |= AFF_SYNTAX_INDENT;
         }
         p_adaptive_formatting_flags |= AFF_SYNTAX_INDENT;
      }
      if ((flag & AFF_INDENT_WITH_TABS) && (indent.IndentWithTabs != AF_RC_ERROR)) {
         validFlags |= AFF_INDENT_WITH_TABS;
         if (p_indent_with_tabs != (indent.IndentWithTabs != 0)) {
            p_indent_with_tabs = (indent.IndentWithTabs != 0);
            changedFlags |= AFF_INDENT_WITH_TABS;
         }
         p_adaptive_formatting_flags |= AFF_INDENT_WITH_TABS;
      }
      if ((flag & AFF_TABS) && (indent.Tabs != '')) {
         validFlags |= AFF_TABS;
         if (p_tabs != indent.Tabs) {
            p_tabs = indent.Tabs;
            changedFlags |= AFF_TABS;
         }
         p_adaptive_formatting_flags |= AFF_TABS;
      }
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= (AFF_SYNTAX_INDENT | AFF_INDENT_WITH_TABS | AFF_TABS);
   } // else there was an error, so we'll try again next time
}


void setParenSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int flag, int &changedFlags,
                      int& validFlags)
{
   se.adapt.AFParenSettings ps;
   status := scanner -> getParenSettings(ps, false);
   if (status == AF_RC_SUCCESS) {
      if ((flag & AFF_NO_SPACE_BEFORE_PAREN) && (ps.NoSpaceBeforeParen != AF_RC_ERROR)) {
         validFlags |= AFF_NO_SPACE_BEFORE_PAREN;
         if (p_no_space_before_paren != (ps.NoSpaceBeforeParen == 1)) {
            p_no_space_before_paren = (ps.NoSpaceBeforeParen == 1);
            changedFlags |= AFF_NO_SPACE_BEFORE_PAREN;
         }
         p_adaptive_formatting_flags |= AFF_NO_SPACE_BEFORE_PAREN;
      }
      if ((flag & AFF_PAD_PARENS) && (ps.PadParens != AF_RC_ERROR)) {
         validFlags |= AFF_PAD_PARENS;
         if (p_pad_parens != (ps.PadParens == 1)) {
            p_pad_parens = (ps.PadParens == 1);
            changedFlags |= AFF_PAD_PARENS;
         }
         p_adaptive_formatting_flags |= AFF_PAD_PARENS;
      }
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= (AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   }
}

void setIndentCaseFromSwitchSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags,
                                     int& validFlags)
{
   int indentCase;
   status := scanner -> getIndentCaseFromSwitch(indentCase, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_INDENT_CASE;
      if (p_indent_case_from_switch != (indentCase == 1)) {
         p_indent_case_from_switch = (indentCase == 1);
         changedFlags |= AFF_INDENT_CASE;
      }
      p_adaptive_formatting_flags |= AFF_INDENT_CASE;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_INDENT_CASE;
   }  // else there was an error, so we'll try again next time
}

void setKeywordCaseSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags,
                            int& validFlags)
{
   int casing;
   status := scanner -> getKeywordCasing(casing, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_KEYWORD_CASING;
      if (p_keyword_casing != casing) {
         p_keyword_casing = casing;
         changedFlags |= AFF_KEYWORD_CASING;
      }
      p_adaptive_formatting_flags |= AFF_KEYWORD_CASING;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_KEYWORD_CASING;
   }  // else there was an error, so we'll try again next time
}


void setTagCaseSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags,
                        int& validFlags)
{
   int casing;
   status := scanner ->getTagCasing(casing, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_TAG_CASING;
      if (p_tag_casing != casing) {
         p_tag_casing = casing;
         changedFlags |= AFF_TAG_CASING;
      }
      p_adaptive_formatting_flags |= AFF_TAG_CASING;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_TAG_CASING;
   }  // else there was an error, so we'll try again next time
}


void setAttributeCaseSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags,
                              int& validFlags)
{
   int casing;
   status := scanner -> getAttributeCasing(casing, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_ATTRIBUTE_CASING;
      if (p_attribute_casing != casing) {
         p_attribute_casing = casing;
         changedFlags |= AFF_ATTRIBUTE_CASING;
      }
      p_adaptive_formatting_flags |= AFF_ATTRIBUTE_CASING;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_ATTRIBUTE_CASING;
   }  // else there was an error, so we'll try again next time
}


void setValueCaseSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags, 
                          int &validFlags)
{
   int casing;
   status := scanner -> getValueCasing(casing, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_VALUE_CASING;
      if (p_value_casing != casing) {
         p_value_casing = casing;
         changedFlags |= AFF_VALUE_CASING;
      }
      p_adaptive_formatting_flags |= AFF_VALUE_CASING;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_VALUE_CASING;
   }  // else there was an error, so we'll try again next time
}


void setHexValueCaseSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int &changedFlags, 
                             int& validFlags)
{
   int casing;
   status := scanner -> getHexValueCasing(casing, false);
   if (status == AF_RC_SUCCESS) {
      validFlags |= AFF_HEX_VALUE_CASING;
      if (p_hex_value_casing != casing) {
         p_hex_value_casing = casing;
         changedFlags |= AFF_HEX_VALUE_CASING;
      }
      p_adaptive_formatting_flags |= AFF_HEX_VALUE_CASING;
   } else if (status == AF_RC_UNAVAILABLE) {
      p_adaptive_formatting_flags |= AFF_HEX_VALUE_CASING;
   }  // else there was an error, so we'll try again next time
}

/**
 * If the given flags are required for the current file based 
 * on the user's adaptive formatting settings, then check if the 
 * file has any tab characters.
 * 
 * @param flag    adaptive formatting settings, bitset of AFF_* flags
 * 
 * @return 'true' if the file has tab characters, 'false' otherwise 
 *         or if the tab/indent settings are not enabled for
 *         adaptive formatting. 
 */
bool areAdaptiveFormattingTabSettingsRequiredImmediately(int flag)
{
   // check if the option is even turned on
   if (adaptive_format_get_buffer_flags() & flag) return false;

   // Allocate a selection for searching top of file
   orig_mark_id := _duplicate_selection('');
   mark_id := _alloc_selection();
   if (mark_id<0) {
      return false;
   }

   // save the current position and last search information
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   // search from the top of the file
   top();
   _begin_line();

   // create a selection of the first [default 4000] lines
   _select_line(mark_id);
   p_line = def_max_adaptive_format_lines;
   _end_select(mark_id);
   _show_selection(mark_id);

   // now search for a single tab character, anywhere
   status := search("\t","@m");

   // This selection can be freed because it is not the active selection.
   _show_selection(orig_mark_id);
   _free_selection(mark_id);

   // restore search and position, and we are done
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return (status == 0);
}

/** 
 * Updates the adaptive formatting settings for the current buffer.  If the 
 * setting has already been inferred, then we do nothing.  Otherwise, we figure 
 * out the setting and set it. 
 *  
 * This function is the main gateway to the automatic adaptive formatter. To add 
 * adaptive formatting language support for a language, see the comment at the 
 * top of this file. 
 * 
 * @param flag         setting that we're looking for 
 * @param updatedFlags if non-null, is assigned the set of flags 
 *                     for settings that actually changed.
 */
void updateAdaptiveFormattingSettings(int flag, bool confirm = true, int* updatedFlags = null)
{
   // if we are getting on indent setting, we might as well get them all
   flag = includeAllIndentSettings(flag);

   // check if this setting has already been set for this buffer
   if ((flag & p_adaptive_formatting_flags)==flag) {
      return;
   }
   
   // grab only settings we don't have
   flag &= ~p_adaptive_formatting_flags;

   // get the scanner for this language
   class se.adapt.AdaptiveFormattingScannerBase scanner;

   lang := p_LangId;
   if (!_no_child_windows() && p_mdi_child) {
      typeless orig_values;
      int embedded_status=_EmbeddedStart(orig_values);
      lang=p_LangId;
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
   }

   ext := '';
   if (p_buf_name != '') {
      ext = _get_extension(p_buf_name);
   }
   scanner = getAdaptiveFormattingScanner(lang, ext);
   if (scanner == null) return;

   // scan for all settings at once
   scanner.automaticAdaptiveFormattingScan(flag);

   // warn user that settings have changed
   if (getNotificationMethod(ALERT_GRP_EDITING_ALERTS, NF_ADAPTIVE_FORMATTING) == NL_DIALOG && p_mdi_child && confirm) {
      // have to restore the last event - maybe a bad idea?
      event := last_event();
      /*
          When we don't get some settings for a file, we don't 
          want to keep scanning the file if the file was a large
          file.
      */
      if (p_Noflines>def_max_retry_adaptive_format_lines) {
         p_adaptive_formatting_flags|=flag;
      }
      _str result=show("-modal _adaptive_format_results", &scanner, flag, null, true);
      // IF dialog was cancelled
      if (result=='') {
         // For now, treat cancel a bit more like a shut up.
         // We could just turn off the flags where something was determined.
         p_adaptive_formatting_flags|=flag;
      }
      last_event(event);
   } else {
      // user already knows, just set the crap
      changedFlags := 0;
      validFlags   := 0;

      // brace style
      if (flag & AFF_BEGIN_END_STYLE) setBeginEndStyle(&scanner, changedFlags, validFlags);
   
      // indent settings
      if (flag & (AFF_SYNTAX_INDENT | AFF_INDENT_WITH_TABS | AFF_TABS)) setIndentSettings(&scanner, flag, changedFlags, validFlags);
   
      // paren settings
      if (flag & (AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS)) setParenSettings(&scanner, flag, changedFlags, validFlags);
   
      // indent case from switch
      if (flag & AFF_INDENT_CASE) setIndentCaseFromSwitchSettings(&scanner, changedFlags, validFlags);
   
      // keyword casing
      if (flag & AFF_KEYWORD_CASING) setKeywordCaseSettings(&scanner, changedFlags, validFlags);
   
      // tag casing
      if (flag & AFF_TAG_CASING) setTagCaseSettings(&scanner, changedFlags, validFlags);
   
      // attribute casing
      if (flag & AFF_ATTRIBUTE_CASING) setAttributeCaseSettings(&scanner, changedFlags, validFlags);
   
      // value casing
      if (flag & AFF_VALUE_CASING) setValueCaseSettings(&scanner, changedFlags, validFlags);
   
      // hex value casing
      if (flag & AFF_HEX_VALUE_CASING) setHexValueCaseSettings(&scanner, changedFlags, validFlags);

      if (p_Noflines>def_max_retry_adaptive_format_lines) {
         p_adaptive_formatting_flags|=flag;
      }

      if (changedFlags) {
         notifyUserOfFeatureUse(NF_ADAPTIVE_FORMATTING, p_buf_name, p_line);
      }

      if (updatedFlags != null) {
         *updatedFlags = validFlags;
      }
   }
}

#region Commands

/** 
 * Perform a manual adaptive formatting scan.  This one will
 * perform a deeper scan than the automatic version.  At
 * completion, will pop up and tell you what was found and give
 * you the opportunity to keep or throw away settings that were
 * discovered.
 * 
 */
_command void adaptive_format_stats() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   class se.adapt.AdaptiveFormattingScannerBase scanner;
   lang := p_LangId;
   if (!_no_child_windows() && p_mdi_child) {
      typeless orig_values;
      int embedded_status=_EmbeddedStart(orig_values);
      lang=p_LangId;
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
   }
   ext := '';
   if (p_buf_name != '') {
      ext = _get_extension(p_buf_name);
   }
   scanner = getAdaptiveFormattingScanner(lang, ext);
   if (scanner != null) {
      scanner.manualAdaptiveFormattingScan();
   } else { 
      // else not available for this language
      message("Adaptive Formatting not available for "_LangGetModeName(lang)".");
   }
}
_command void adaptive_format_update() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   revertCurrentBuffer(-1);
   updateAdaptiveFormattingSettings(-1);
}

#endregion Commands

defeventtab _adaptive_format_results;

int heightSep = 120;

static bool matchesBufferSetting(_str value, int flag)
{
   bufId := _edit_window();

   switch (flag) {
   case AFF_SYNTAX_INDENT:
      return strieq(value, bufId.p_SyntaxIndent);
   case AFF_TABS:
      parse bufId.p_tabs with auto startcol auto endcol auto rest;
      if (rest=='' && isinteger(startcol) && isinteger(endcol) && strieq(value, '+':+((int)endcol-(int)startcol))) return true;
      else {
         step := '';
         parse value with '+'step;
         if (step != '') {
            return (bufId.p_tabs == '1 '(1 + (int)step));
         } else return false;
      }
      return strieq(value, bufId.p_tabs);
   case AFF_INDENT_WITH_TABS:
      return strieq(value, bufId.p_indent_with_tabs);
   case AFF_KEYWORD_CASING:
      return strieq(value, bufId.p_keyword_casing);
   case AFF_TAG_CASING:
      return strieq(value, bufId.p_tag_casing);
   case AFF_ATTRIBUTE_CASING:
      return strieq(value, bufId.p_attribute_casing);
   case AFF_VALUE_CASING:
      return strieq(value, bufId.p_value_casing);
   case AFF_HEX_VALUE_CASING:
      return strieq(value, bufId.p_hex_value_casing);
   case AFF_INDENT_CASE:
      return strieq(value, bufId.p_indent_case_from_switch);
   case AFF_PAD_PARENS:
      return strieq(value, bufId.p_pad_parens);
   case AFF_NO_SPACE_BEFORE_PAREN:
      return strieq(value, bufId.p_no_space_before_paren);
   case AFF_BEGIN_END_STYLE:
      return strieq(value, bufId.p_begin_end_style);
   }

   return false;
}

positionAndSetIndentSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                             AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   se.adapt.AFIndentSettings is;
   if (flags & (AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS ) && 
       !scanner -> getIndentSettings(is, false)) {

      // init syntax indent
      if (is.SyntaxIndent > 0) { 
         if (!automaticScan || (automaticScan && !matchesBufferSetting(is.SyntaxIndent,  AFF_SYNTAX_INDENT))) {
            afs.SyntaxIndent = is.SyntaxIndent;
            
            _lbl_syntax_indent.p_caption = is.SyntaxIndent;
            showSomething = true;
            showSyntaxIndent(shift);
         } else {
            hideSyntaxIndent(shift);
            hiddenFlags |= AFF_SYNTAX_INDENT;
         }
      } else {
         hideSyntaxIndent(shift);
      }

      // tabs
      if (is.Tabs != '') {
         if (!automaticScan || (automaticScan && !matchesBufferSetting(is.Tabs,  AFF_TABS))) {
            afs.Tabs = is.Tabs;
            
            _lbl_tabs.p_caption = is.Tabs;
            showSomething = true;
            showTabs(shift);
         } else {
            hideTabs(shift);
            hiddenFlags |= AFF_TABS;
         }
      } else {
         hideTabs(shift);
      }

      // indent with tabs vs spaces
      if (is.IndentWithTabs >= 0) {          
         if (!automaticScan || (automaticScan && !matchesBufferSetting(is.IndentWithTabs,  AFF_INDENT_WITH_TABS))) {
            afs.IndentWithTabs = is.IndentWithTabs;
            
            _lbl_indent_with_tabs.p_caption = (is.IndentWithTabs)?'True':'False';
            showSomething = true;
            showIndentWithTabs(shift);
         } else {
            hideIndentWithTabs(shift);
            hiddenFlags |= AFF_INDENT_WITH_TABS;
         }
      } else {
         hideIndentWithTabs(shift);
      }

   } else {            // either error or unavailable, we don't want to see it
      hideSyntaxIndent(shift);
      hideTabs(shift);
      hideIndentWithTabs(shift);
   }
}

positionAndSetKeywordCasing(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                            AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_KEYWORD_CASING) && (!scanner -> getKeywordCasing(value, false))) {      
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_KEYWORD_CASING))) {
         switch (value) {
         case WORDCASE_LOWER:
            _lbl_keyword_casing.p_caption = 'Lowercase';
            break;
         case WORDCASE_UPPER:
            _lbl_keyword_casing.p_caption = 'Uppercase';
            break;
         case WORDCASE_CAPITALIZE:
            _lbl_keyword_casing.p_caption = 'Capitalize';
            break;
         case WORDCASE_PRESERVE:
            _lbl_keyword_casing.p_caption = 'Preserve';
            break;
         default:
            hideKeywordCasing(shift);
            break;
         }
         
         // is this visible?  do we add to the shift?
         if (_cb_use_keyword_casing.p_visible) {
            afs.KeywordCasing = value;
         
            showSomething = true;
            showKeywordCasing(shift);
         } 
      } else {
         hideKeywordCasing(shift);
         hiddenFlags |= AFF_KEYWORD_CASING;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideKeywordCasing(shift);
   }
}


positionAndSetTagCasing(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                        AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_TAG_CASING) && (!scanner -> getTagCasing(value, false))) { 
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_TAG_CASING))) {
         switch (value) {
         case WORDCASE_LOWER:
            _lbl_tag_casing.p_caption = 'Lowercase';
            break;
         case WORDCASE_UPPER:
            _lbl_tag_casing.p_caption = 'Uppercase';
            break;
         case WORDCASE_CAPITALIZE:
            _lbl_tag_casing.p_caption = 'Capitalize';
            break;
         case WORDCASE_PRESERVE:
            _lbl_tag_casing.p_caption = 'Preserve';
            break;
         default:
            hideTagCasing(shift);
            break;
         }
      
         if (_cb_use_tag_casing.p_visible) {
            afs.TagCasing = value;
      
            showSomething = true;
            showTagCasing(shift);
         } 
      } else {
         hideTagCasing(shift);
         hiddenFlags |= AFF_TAG_CASING;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideTagCasing(shift);
   }
}

positionAndSetAttributeCasing(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                              AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_ATTRIBUTE_CASING) && (!scanner -> getAttributeCasing(value, false))) { 
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_ATTRIBUTE_CASING))) {
         switch (value) {
         case WORDCASE_LOWER:
            _lbl_attribute_casing.p_caption = 'Lowercase';
            break;
         case WORDCASE_UPPER:
            _lbl_attribute_casing.p_caption = 'Uppercase';
            break;
         case WORDCASE_CAPITALIZE:
            _lbl_attribute_casing.p_caption = 'Capitalize';
            break;
         case WORDCASE_PRESERVE:
            _lbl_attribute_casing.p_caption = 'Preserve';
            break;
         default:
            hideAttributeCasing(shift);
            break;
         }
         
         if (_cb_use_attribute_casing.p_visible) {
            afs.AttributeCasing = value;
         
            showSomething = true;
            showAttributeCasing(shift);
         } 
      } else {
         hideAttributeCasing(shift);
         hiddenFlags |= AFF_ATTRIBUTE_CASING;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideAttributeCasing(shift);
   }
}

positionAndSetValueCasing(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                          AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_VALUE_CASING) && (!scanner -> getValueCasing(value, false))) { 
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_VALUE_CASING))) {
         switch (value) {
         case WORDCASE_LOWER:
            _lbl_value_casing.p_caption = 'Lowercase';
            break;
         case WORDCASE_UPPER:
            _lbl_value_casing.p_caption = 'Uppercase';
            break;
         case WORDCASE_CAPITALIZE:
            _lbl_value_casing.p_caption = 'Capitalize';
            break;
         case WORDCASE_PRESERVE:
            _lbl_value_casing.p_caption = 'Preserve';
            break;
         default:
            hideValueCasing(shift);
            break;
         }
   
         if (_cb_use_value_casing.p_visible) {
            afs.ValueCasing = value;
   
            showSomething = true;
            showValueCasing(shift);
         } 
      } else {
         hideValueCasing(shift);
         hiddenFlags |= AFF_VALUE_CASING;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideValueCasing(shift);
   }
}

positionAndSetHexValueCasing(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                             AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_HEX_VALUE_CASING) && (!scanner -> getHexValueCasing(value, false))) { 
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_HEX_VALUE_CASING))) {
         switch (value) {
         case WORDCASE_LOWER:
            _lbl_hex_value_casing.p_caption = 'Lowercase';
            break;
         case WORDCASE_UPPER:
            _lbl_hex_value_casing.p_caption = 'Uppercase';
            break;
         case WORDCASE_CAPITALIZE:
            _lbl_hex_value_casing.p_caption = 'Capitalize';
            break;
         case WORDCASE_PRESERVE:
            _lbl_hex_value_casing.p_caption = 'Preserve';
            break;
         default:
            hideHexValueCasing(shift);
            break;
         }
   
         if (_cb_use_hex_value_casing.p_visible) {
            afs.HexValueCasing = value;
   
            showSomething = true;
            showHexValueCasing(shift);
         } else {
            shift += _cb_use_hex_value_casing.p_height + _lbl_cl_hex_value_casing.p_height + heightSep;
         }
      } else {
         hideHexValueCasing(shift);
         hiddenFlags |= AFF_HEX_VALUE_CASING;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideHexValueCasing(shift);
   }
}

positionAndSetIndentCase(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                         AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   int value;
   if ((flags & AFF_INDENT_CASE) && (!scanner -> getIndentCaseFromSwitch(value, false)) && (value >= 0)) { 
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_INDENT_CASE))) {
         afs.IndentCaseFromSwitch = value;
   
         _lbl_indent_case.p_caption = (value != 0)?'True':'False';
         showSomething = true;
         showIndentCaseFromSwitch(shift);
      } else {
         hideIndentCaseFromSwitch(shift);
         hiddenFlags |= AFF_INDENT_CASE;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideIndentCaseFromSwitch(shift);
   }
}

positionAndSetParenSettings(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                            AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething)
{
   se.adapt.AFParenSettings ps;
   if ((flags & (AFF_PAD_PARENS | AFF_NO_SPACE_BEFORE_PAREN)) && 
       (!scanner -> getParenSettings(ps, false))) {

      // no space before
      if ((flags & AFF_NO_SPACE_BEFORE_PAREN) && (ps.NoSpaceBeforeParen >= 0)) {
         if (!automaticScan || (automaticScan && !matchesBufferSetting(ps.NoSpaceBeforeParen,  AFF_NO_SPACE_BEFORE_PAREN))) {
            afs.NoSpaceBeforeParens = ps.NoSpaceBeforeParen;
   
            _lbl_no_space.p_caption = (ps.NoSpaceBeforeParen != 0)?'True':'False';
            showSomething = true;
            showNoSpaceBeforeParen(shift);
         } else {
            hideNoSpaceBeforeParen(shift);
            hiddenFlags |= AFF_NO_SPACE_BEFORE_PAREN;
         }
      } else {
         hideNoSpaceBeforeParen(shift);
      }

      // pad parens with spaces
      if ((flags & AFF_PAD_PARENS) && (ps.PadParens >= 0)) {   
         if (!automaticScan || (automaticScan && !matchesBufferSetting(ps.PadParens,  AFF_PAD_PARENS))) {
            afs.PadParens = ps.PadParens;
         
            _lbl_pad_parens.p_caption = (ps.PadParens != 0)?'True':'False';
            showSomething = true;
            showPadParens(shift);
         } else {
            hiddenFlags |= AFF_PAD_PARENS;
            hidePadParens(shift);
         }
      } else {
         hidePadParens(shift);
      }

   } else {            // either error or unavailable, we don't want to see it
      hidePadParens(shift);
      hideNoSpaceBeforeParen(shift);
   }
}

positionAndSetBeginEndStyle(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags, bool automaticScan, 
                            AdaptiveFormattingSettings &afs, int &shift, int &hiddenFlags, bool &showSomething, 
                            _str beStyles[])
{
   int value;
   if ((flags & AFF_BEGIN_END_STYLE) && (!scanner -> getBraceStyle(value, false))) {
      if (!automaticScan || (automaticScan && !matchesBufferSetting(value,  AFF_BEGIN_END_STYLE))) {

         _lbl_bs1._use_source_window_font();
         _lbl_bs2._use_source_window_font();
         _lbl_bs3._use_source_window_font();

         // check for alternate begin/end styles
         if (beStyles != null) {
            width := 0;
            styles := beStyles._length();
            if (beStyles[0] != '') {
               _lbl_bs1.p_caption = beStyles[0];
               width += _lbl_bs1.p_width;
            }

            if (beStyles[1] != '') {
               _lbl_bs2.p_caption = beStyles[1];
               width += _lbl_bs2.p_width;
            }

            if (beStyles[2] != null && beStyles[2] != '') {
               _lbl_bs3.p_caption = beStyles[2];
               width += _lbl_bs3.p_width;
            } else {       // sometimes we only have 2
               _lbl_bs3.p_visible = false;
               _lbl_bes3.p_visible = false;
            }
            // this is possibly overkill, but whatever, i did it
            realignBEStyles(width, styles);
         }
   
         switch (value) {
         case 0:
            _lbl_be_style.p_caption = 'Style 1';
            break;
         case BES_BEGIN_END_STYLE_2:
            _lbl_be_style.p_caption = 'Style 2';
            break;
         case BES_BEGIN_END_STYLE_3:
            _lbl_be_style.p_caption = 'Style 3';
            break;
         default:
            hideBEStyle(shift);
            break;
         }
   
         // add to shift or use it?
         if (_ctl_frame_braces.p_visible) {
            afs.BeginEndStyle = value;
            showSomething = true;
            showBEStyle(shift);
         } 
      } else {
         hideBEStyle(shift);
         hiddenFlags |= AFF_BEGIN_END_STYLE;
      }
   } else {            // either error or unavailable, we don't want to see it
      hideBEStyle(shift);
   }
}

/** 
 * This method handles the creation of the Adaptive Formatting 
 * Results form.  Since every language will support different 
 * options, then the appearance of this form will vary.  Form 
 * handles making some settings invisible and shifting visible 
 * options accordingly. 
 * 
 * @param scanner       the AdaptiveFormattingScanner used for 
 *                      this operation
 */
void _ctl_ok.on_create(se.adapt.AdaptiveFormattingScannerBase * scanner, int flags = -1, 
                       _str beStyles[] = null, bool automaticScan = false)
{
   p_active_form.p_caption=_LangGetModeName(scanner->getLangId())' 'p_active_form.p_caption;
   AdaptiveFormattingSettings afs;

   int value;
   shift := 0;   // how much to shift controls up
   showSomething := false;       // to make sure that we have something showing up
   hiddenFlags := 0;

   // is this an automatic scan?  if so, we need to show the right label
   if (automaticScan) {
      _lbl_ad_form_explain.p_visible = true;
      _lbl_link_to_options.p_visible = true;
      _lbl_use_for_buffer.p_visible = false;
   } else {
      _lbl_ad_form_explain.p_visible = false;
      _lbl_use_for_buffer.p_visible = true;
      _lbl_link_to_options.p_visible = false;
      shift += (_lbl_ad_form_explain.p_height);
      _lbl_use_for_buffer.p_y -= shift;
   }

   // init indent settings
   positionAndSetIndentSettings(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init keyword casing
   positionAndSetKeywordCasing(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init tag casing
   positionAndSetTagCasing(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init attribute casing
   positionAndSetAttributeCasing(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init value casing
   positionAndSetValueCasing(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init hex value casing
   positionAndSetHexValueCasing(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // indent case from switch
   positionAndSetIndentCase(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // no space before parens
   positionAndSetParenSettings(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething);

   // init brace style
   positionAndSetBeginEndStyle(scanner, flags, automaticScan, afs, shift, hiddenFlags, showSomething, beStyles);

   // we were unable to find ANY settings - that is a bummer
   if (!showSomething) {
      p_active_form._delete_window();

      if (!automaticScan) {
         _message_box("Adaptive Formatting was unable to determine any settings from this file.", "Adaptive Formatting");
      } else {
         _mdi.p_child.p_adaptive_formatting_flags |= hiddenFlags;
      }

      return;
   } else {

      if (automaticScan) {
         _mdi.p_child.p_adaptive_formatting_flags |= hiddenFlags;
      }

      // now we shift up the buttons and bottom checkbox
      if (shift) {

         // is this an automatic scan?  if so, we need to show the right checkbox
         if (automaticScan) {
            //_ctl_cancel.p_visible = false;
            _cb_apply_to_language.p_visible = false;
            _cb_confirm.p_visible = true;
            shift += _cb_apply_to_language.p_height;

            // shift after we add in the checkbox, because these things are under it
            _ctl_ok.p_y -= shift;
            _ctl_cancel.p_y -= shift;
            _ctl_stats.p_y -= shift;
            _ctl_help.p_y -= shift;
            _cb_confirm.p_y -= shift;
         } else {
            _cb_apply_to_language.p_visible = true;
            _cb_confirm.p_visible = false;

            // shift before we add in the checkbox, because these things are above it
            _cb_apply_to_language.p_y -= shift;
            _ctl_ok.p_y -= shift;
            _ctl_cancel.p_y -= shift;
            _ctl_stats.p_y -= shift;
            _ctl_help.p_y -= shift;
            shift += _cb_confirm.p_height;
         }

         p_active_form.p_height -= shift;
      }
   
      // get the stats in case user wants them
      _str stats[];
      scanner -> getStatistics(stats);
      _ctl_stats.p_user = stats;

      setConfidenceLevels(stats);
   }

   // save the settings, we'll need them later
   _ctl_ok.p_user = afs;
   _lbl_link_to_options.p_mouse_pointer = MP_HAND;

   // put this in our notification log
   if (automaticScan) {
      notifyUserOfFeatureUse(NF_ADAPTIVE_FORMATTING, _mdi.p_child.p_buf_name, _mdi.p_child.p_line);
   }
}

void _lbl_link_to_options.lbutton_up()
{
   _str modename;
   parse p_parent.p_caption with modename .;
   // show adaptive formatting options for this language
   showOptionsForModename(modename, 'Adaptive Formatting');
}

void hideBEStyle(int &shift)
{
   _cb_use_braces.p_visible = false;
   _lbl_be_style.p_visible = false;
   _ctl_frame_braces.p_visible = false;
   _lbl_cl_bestyle.p_visible = false;
   _div_be_style.p_visible = false;

   shift += _cb_use_braces.p_height + _ctl_frame_braces.p_height + _lbl_cl_bestyle.p_height + heightSep;
}

void showBEStyle(int shift)
{
   _cb_use_braces.p_y -= shift;
   _lbl_be_style.p_y -= shift;
   _ctl_frame_braces.p_y -= shift;
   _lbl_cl_bestyle.p_y -= shift;
   _div_be_style.p_y -= shift;
}

void hidePadParens(int &shift)
{
   _cb_use_pad_parens.p_visible = false;
   _lbl_pad_parens.p_visible = false;
   _lbl_cl_pad_parens.p_visible = false;
   _div_pad_parens.p_visible = false;
   shift += _cb_use_pad_parens.p_height + _lbl_cl_pad_parens.p_height + heightSep;
}

void showPadParens(int shift)
{
   _cb_use_pad_parens.p_y -= shift;
   _lbl_pad_parens.p_y -= shift;
   _lbl_cl_pad_parens.p_y -= shift;
   _div_pad_parens.p_y -= shift;
}

void hideNoSpaceBeforeParen(int &shift)
{
   _cb_use_space_before.p_visible = false;
   _lbl_no_space.p_visible = false;
   _lbl_cl_no_space.p_visible = false;
   _div_no_space.p_visible = false;

   shift += _cb_use_space_before.p_height + _lbl_cl_no_space.p_height + heightSep;
}

void showNoSpaceBeforeParen(int shift)
{
   _cb_use_space_before.p_y -= shift;
   _lbl_no_space.p_y -= shift;
   _lbl_cl_no_space.p_y -= shift;
   _div_no_space.p_y -= shift;
}

void hideIndentCaseFromSwitch(int &shift) 
{
   _cb_use_indent_case.p_visible = false;
   _lbl_indent_case.p_visible = false;
   _lbl_cl_indent_case.p_visible = false;
   _div_indent_case.p_visible = false;
   shift += _cb_use_indent_case.p_height + _lbl_cl_indent_case.p_height + heightSep;
}

void showIndentCaseFromSwitch(int shift)
{
   _cb_use_indent_case.p_y -= shift;
   _lbl_indent_case.p_y -= shift;
   _lbl_cl_indent_case.p_y -= shift;
   _div_indent_case.p_y -= shift;
}

void hideHexValueCasing(int &shift)
{
   _cb_use_hex_value_casing.p_visible = false;
   _lbl_hex_value_casing.p_visible = false;
   _lbl_cl_hex_value_casing.p_visible = false;
   _div_hex_value_casing.p_visible = false;
   shift += _cb_use_hex_value_casing.p_height + _lbl_cl_hex_value_casing.p_height + heightSep;
}

void showHexValueCasing(int shift)
{
   _cb_use_hex_value_casing.p_y -= shift;
   _lbl_hex_value_casing.p_y -= shift;
   _lbl_cl_hex_value_casing.p_y -= shift;
   _div_hex_value_casing.p_y -= shift;
}

void hideValueCasing(int &shift)
{
   _cb_use_value_casing.p_visible = false;
   _lbl_value_casing.p_visible = false;
   _lbl_cl_value_casing.p_visible = false;
   _div_value_casing.p_visible = false;
   shift += _cb_use_value_casing.p_height + _lbl_cl_value_casing.p_height + heightSep;
}

void showValueCasing(int shift)
{
   _cb_use_value_casing.p_y -= shift;
   _lbl_value_casing.p_y -= shift;
   _lbl_cl_value_casing.p_y -= shift;
   _div_value_casing.p_y -= shift;
}

void hideAttributeCasing(int &shift)
{
   _cb_use_attribute_casing.p_visible = false;
   _lbl_attribute_casing.p_visible = false;
   _lbl_cl_attribute_casing.p_visible = false;
   _div_attribute_casing.p_visible = false;
   shift += _cb_use_attribute_casing.p_height + _lbl_cl_attribute_casing.p_height + heightSep;
}

void showAttributeCasing(int shift)
{
   _cb_use_attribute_casing.p_y -= shift;
   _lbl_attribute_casing.p_y -= shift;
   _lbl_cl_attribute_casing.p_y -= shift;
   _div_attribute_casing.p_y -= shift;
}

void hideTagCasing(int &shift)
{
   _cb_use_tag_casing.p_visible = false;
   _lbl_tag_casing.p_visible = false;
   _lbl_cl_tag_casing.p_visible = false;
   _div_tag_casing.p_visible = false;
   shift += _cb_use_tag_casing.p_height + _lbl_cl_tag_casing.p_height + heightSep;
}

void showTagCasing(int shift)
{
   _cb_use_tag_casing.p_y -= shift;
   _lbl_tag_casing.p_y -= shift;
   _lbl_cl_tag_casing.p_y -= shift;
   _div_tag_casing.p_y -= shift;
}

void hideKeywordCasing(int &shift)
{
   _cb_use_keyword_casing.p_visible = false;
   _lbl_keyword_casing.p_visible = false;
   _lbl_cl_keyword_casing.p_visible = false;
   _div_keyword_casing.p_visible = false;
   shift += _cb_use_keyword_casing.p_height + _lbl_cl_keyword_casing.p_height + heightSep;
}

void showKeywordCasing(int shift)
{
   _cb_use_keyword_casing.p_y -= shift;
   _lbl_keyword_casing.p_y -= shift;
   _lbl_cl_keyword_casing.p_y -= shift;
   _div_keyword_casing.p_y -= shift;
}

void hideIndentWithTabs(int &shift)
{
   _cb_use_indent_with_tabs.p_visible = false;
   _lbl_indent_with_tabs.p_visible = false;
   _lbl_cl_indent_with_tabs.p_visible = false;
   _div_indent_with_tabs.p_visible = false;
   shift += _cb_use_indent_with_tabs.p_height + _lbl_cl_indent_with_tabs.p_height + heightSep;
}

void showIndentWithTabs(int shift)
{
   _cb_use_indent_with_tabs.p_y -= shift;
   _lbl_indent_with_tabs.p_y -= shift;
   _lbl_cl_indent_with_tabs.p_y -= shift;
   _div_indent_with_tabs.p_y -= shift;
}

void hideTabs(int &shift)
{
   _cb_use_tabs.p_visible = false;
   _lbl_tabs.p_visible = false;
   _lbl_cl_tabs.p_visible = false;
   _div_tabs.p_visible = false;
   shift += _cb_use_tabs.p_height + _lbl_cl_tabs.p_height + heightSep;
}

void showTabs(int shift)
{
   _cb_use_tabs.p_y -= shift;
   _lbl_tabs.p_y -= shift;
   _lbl_cl_tabs.p_y -= shift;
   _div_tabs.p_y -= shift;
}

void hideSyntaxIndent(int &shift)
{
   _cb_use_indent.p_visible = false;
   _lbl_syntax_indent.p_visible = false;
   _lbl_cl_indent.p_visible = false;
   _div_indent.p_visible = false;
   shift += _cb_use_indent.p_height + _lbl_cl_indent.p_height + heightSep;
}

void showSyntaxIndent(int shift)
{
   _cb_use_indent.p_y -= shift;
   _lbl_syntax_indent.p_y -= shift;
   _lbl_cl_indent.p_y -= shift;
   _div_indent.p_y -= shift;
}

void setConfidenceLevels(_str stats[])
{
   i := 0;
   tabsSet := false;
   while (i < stats._length()) {
      // we've found a heading
      if (!pos(\t, stats[i])) {
         heading := stats[i];
         // go through until we find the biggest percentage
         i++;
         highest := 0.0;
         while (i < stats._length() && pos(\t, stats[i])) {
            if (!pos('Total', stats[i])) {
               // extract the percentage
               percentage := substr(stats[i], lastpos(\t, stats[i]) + 1);
               percentage = substr(percentage, 1, length(percentage) - 1);
               if ((double)percentage > highest) {
                  highest = (double)percentage;
               }
            }
            i++;
         }
         switch (heading) {
         case  "Syntax Indent":
            _lbl_cl_indent.p_caption = 'Confidence level:  'highest'%';
            if (!tabsSet) {
               _lbl_cl_tabs.p_caption = 'Confidence level:  'highest'%';
            }
            break;
         case "Tabs":
             _lbl_cl_tabs.p_caption = 'Confidence level:  'highest'%';
             tabsSet = true;
             break;
         case "Indent with Tabs":
            _lbl_cl_indent_with_tabs.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Keyword Casing":
            _lbl_cl_keyword_casing.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Tag Casing":
            _lbl_cl_tag_casing.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Attribute Casing":
            _lbl_cl_attribute_casing.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Value Casing":
            _lbl_cl_value_casing.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Hex Value Casing":
            _lbl_cl_hex_value_casing.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Indent Case From Switch":
            _lbl_cl_indent_case.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Space Before Parenthesis":
            _lbl_cl_no_space.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Pad Parenthesis":
            _lbl_cl_pad_parens.p_caption = 'Confidence level:  'highest'%';
            break;
         case "Brace Style":
            _lbl_cl_bestyle.p_caption = 'Confidence level:  'highest'%';
            break;
         }
      }
   }
}

/** 
 * Makes the form pretty.
 * 
 * @param width   total width of begin/end style labels
 * @param styles  number of styles being displayed
 */
void realignBEStyles(int width, int styles)
{
   buffer := 750;
   width = _ctl_frame_braces.p_width - (buffer * 2) - width;
   if (width < 0) {
      width += 1000;
      buffer = 250;
   }

   width = width intdiv (styles * 2);
   _lbl_bs1.p_x += width;
   _lbl_bes1.p_x += width;

   if (styles == 2) {
      width = _ctl_frame_braces.p_width - buffer - width - _lbl_bs2.p_width;
      _lbl_bs2.p_x = _lbl_bes2.p_x = width;
   } else {
      _lbl_bs2.p_x = _lbl_bes2.p_x = _lbl_bs1.p_x_extent + (width * 2);;

      width = _ctl_frame_braces.p_width - buffer - width - _lbl_bs3.p_width;
      _lbl_bs3.p_x = _lbl_bes3.p_x = width;
   }
}

void gatherSyntaxIndentSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_indent.p_visible) {
      // we want to use the value
      if (_cb_use_indent.p_value) {
         bufId.p_SyntaxIndent = afs.SyntaxIndent;
         flags |= AFF_SYNTAX_INDENT;
      } else if (automaticScan) {
         // if automatic scan, we want to say that we did scan for this
         flags |= AFF_SYNTAX_INDENT;
      }
   } else {
      afs.SyntaxIndent = -1;
   }
}

void gatherIndentWithTabsSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_indent_with_tabs.p_visible) {
      if (_cb_use_indent_with_tabs.p_value) {
         bufId.p_indent_with_tabs = (afs.IndentWithTabs != 0);
         flags |= AFF_INDENT_WITH_TABS;
      } else if (automaticScan) {
         // if automatic scan, we want to say that we did scan for this
         flags |= AFF_INDENT_WITH_TABS;
      }
   } else {
      afs.IndentWithTabs = -1;
   }
}

void gatherTabsSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_tabs.p_visible) { 
      // we want to use the value
      if (_cb_use_tabs.p_value) {
         bufId.p_tabs = afs.Tabs;
         flags |= AFF_TABS;
      } else if (automaticScan) {
         // if automatic scan, we want to say that we did scan for this
         flags |= AFF_TABS;
      }
   } else {
      afs.Tabs = '';
   }
}

void gatherKeywordCasingSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_keyword_casing.p_visible) {
      if (_cb_use_keyword_casing.p_value) {
         bufId.p_keyword_casing = afs.KeywordCasing;
         flags |= AFF_KEYWORD_CASING;
      } else if (automaticScan) {
         flags |= AFF_KEYWORD_CASING;
      }
   } else {
      afs.KeywordCasing = -2;          // set to -2 because -1 is a valid option (PRESERVE)
   }
}

void gatherTagCasingSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{   
   if (_cb_use_tag_casing.p_visible) { 
      if (_cb_use_tag_casing.p_value) {
         bufId.p_tag_casing = afs.TagCasing;
         flags |= AFF_TAG_CASING;
      } else if (automaticScan) {
         flags |= AFF_TAG_CASING;
      }
   } else {
      afs.TagCasing = -2;           // set to -2 because -1 is a valid option (PRESERVE)
   }
}

void gatherAttributeCasingSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_attribute_casing.p_visible) { 
      if (_cb_use_attribute_casing.p_value) {
         bufId.p_attribute_casing = afs.AttributeCasing;
         flags |= AFF_ATTRIBUTE_CASING;
      } else if (automaticScan) {
         flags |= AFF_ATTRIBUTE_CASING;
      }
   } else {
      afs.AttributeCasing = -2;          // set to -2 because -1 is a valid option (PRESERVE)
   }
}

void gatherValueCasingSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_value_casing.p_visible) { 
      if (_cb_use_value_casing.p_value) {
         bufId.p_value_casing = afs.ValueCasing;
         flags |= AFF_VALUE_CASING;
      } else if (automaticScan) {
         flags |= AFF_VALUE_CASING;
      }
   } else {
      afs.ValueCasing = -2;           // set to -2 because -1 is a valid option (PRESERVE)
   }
}

void gatherHexValueCasingSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_hex_value_casing.p_visible) {
      if (_cb_use_hex_value_casing.p_value) {
         bufId.p_hex_value_casing = afs.HexValueCasing;
         flags |= AFF_HEX_VALUE_CASING;
      } else if (automaticScan) {
         flags |= AFF_HEX_VALUE_CASING;
      }
   } else {
      afs.HexValueCasing = -2;          // set to -2 because -1 is a valid option (PRESERVE)
   }
}

void gatherIndentCaseSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_indent_case.p_visible) {
      if (_cb_use_indent_case.p_value) {
         bufId.p_indent_case_from_switch = (afs.IndentCaseFromSwitch != 0);
         flags |= AFF_INDENT_CASE;
      } else if (automaticScan) {
         flags |= AFF_INDENT_CASE;
      }
   } else {
      afs.IndentCaseFromSwitch = -1;
   }
}

void gatherNoSpaceBeforeParensSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_space_before.p_visible) {
      if (_cb_use_space_before.p_value) {
         bufId.p_no_space_before_paren = (afs.NoSpaceBeforeParens != 0);
         flags |= AFF_NO_SPACE_BEFORE_PAREN;
      } else if (automaticScan) {
         flags |= AFF_NO_SPACE_BEFORE_PAREN;
      }
   } else {
      afs.NoSpaceBeforeParens = -1;
   }
}

void gatherPadParensSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_pad_parens.p_visible) {
      if (_cb_use_pad_parens.p_value) {
         bufId.p_pad_parens = (afs.PadParens != 0);
         flags |= AFF_PAD_PARENS;
      } else if (automaticScan){
         flags |= AFF_PAD_PARENS;
      }
   } else {
      afs.PadParens = -1;
   }
}

void gatherBeginEndStyleSettings(AdaptiveFormattingSettings &afs, int &flags, int bufId, bool automaticScan)
{
   if (_cb_use_braces.p_visible) {
      if (_cb_use_braces.p_value) {
         bufId.p_begin_end_style = afs.BeginEndStyle;
         flags |= AFF_BEGIN_END_STYLE;
      } else if (automaticScan) {
         flags |= AFF_BEGIN_END_STYLE;
      }
   } else {
      afs.BeginEndStyle = -1;
   }
}

/** 
 * Figures out which settings need to be set for the buffer and
 * for the language.
 * 
 */
void _ctl_ok.lbutton_up()
{
   automaticScan := _lbl_ad_form_explain.p_visible;

   AdaptiveFormattingSettings afs = _ctl_ok.p_user;
   int bufId = _mdi.p_child;
   flags := 0;

   // syntax indent
   gatherSyntaxIndentSettings(afs, flags, bufId, automaticScan);

   // tabs settings
   gatherTabsSettings(afs, flags, bufId, automaticScan);

   // indent with tabs
   gatherIndentWithTabsSettings(afs, flags, bufId, automaticScan);

   // keyword casing
   gatherKeywordCasingSettings(afs, flags, bufId, automaticScan);

   // tag casing
   gatherTagCasingSettings(afs, flags, bufId, automaticScan);

   // attribute casing
   gatherAttributeCasingSettings(afs, flags, bufId, automaticScan);

   // value casing
   gatherValueCasingSettings(afs, flags, bufId, automaticScan);

   // hex value casing
   gatherHexValueCasingSettings(afs, flags, bufId, automaticScan);

   // indent case from switch
   gatherIndentCaseSettings(afs, flags, bufId, automaticScan);

   // no space before paren
   gatherNoSpaceBeforeParensSettings(afs, flags, bufId, automaticScan);

   // pad parens
   gatherPadParensSettings(afs, flags, bufId, automaticScan);

   // brace settings
   gatherBeginEndStyleSettings(afs, flags, bufId, automaticScan);
   // we set the flags we collected so that we won't try and figure out these settings again
   bufId.p_adaptive_formatting_flags |= flags;

   // apply these settings to entire language?
   if (_cb_apply_to_language.p_visible && _cb_apply_to_language.p_value) {
      setFormattingOptionsForExtension(afs);
   }

   if (automaticScan) {
      if (_cb_confirm.p_value) {
         setNotificationMethod(ALERT_GRP_EDITING_ALERTS, NF_ADAPTIVE_FORMATTING, NL_MESSAGE);
      } else {
         setNotificationMethod(ALERT_GRP_EDITING_ALERTS, NF_ADAPTIVE_FORMATTING, NL_DIALOG);
      }
   }

   p_active_form._delete_window(1);
}



/** 
 * Sets the settings found from adaptive formatting for the 
 * entire language. 
 * 
 * @param afs        Settings to be set
 */
void setFormattingOptionsForExtension(AdaptiveFormattingSettings afs)
{
   _str langID = _mdi.p_child.p_LangId;

   updateString := "";

   // syntax indent
   if (afs.SyntaxIndent >= 0) {
      LanguageSettings.setSyntaxIndent(langID, afs.SyntaxIndent);
      updateString :+= SYNTAX_INDENT_UPDATE_KEY'='afs.SyntaxIndent;
   }

   if (_LanguageInheritsFrom('html') || _LanguageInheritsFrom('xml')) {

      // tag casing
      if (afs.TagCasing > AF_RC_ERROR) {
         LanguageSettings.setTagCase(langID, afs.TagCasing);
         updateString :+= TAG_CASING_UPDATE_KEY'='afs.TagCasing;
      }

      // attribute casing
      if (afs.AttributeCasing > AF_RC_ERROR) {
         LanguageSettings.setAttributeCase(langID, afs.AttributeCasing);
         updateString :+= ATTRIBUTE_CASING_UPDATE_KEY'='afs.AttributeCasing;
      }

      // value casing
      if (afs.ValueCasing > AF_RC_ERROR) {
         LanguageSettings.setValueCase(langID, afs.ValueCasing);
         updateString :+= VALUE_CASING_UPDATE_KEY'='afs.ValueCasing;
      }

      // hex value casing
      if (afs.HexValueCasing > AF_RC_ERROR) {
         LanguageSettings.setHexValueCase(langID, afs.HexValueCasing);
         updateString :+= HEX_VALUE_CASING_UPDATE_KEY'='afs.HexValueCasing;
      }

   } else {

      // keyword casing
      if (afs.KeywordCasing > AF_RC_ERROR) {
         LanguageSettings.setKeywordCase(langID, afs.KeywordCasing);
         updateString :+= KEYWORD_CASING_UPDATE_KEY'='afs.KeywordCasing;
      }

      // brace style
      if (afs.BeginEndStyle >= 0) {
         LanguageSettings.setBeginEndStyle(langID, afs.BeginEndStyle);
         updateString :+= BEGIN_END_STYLE_UPDATE_KEY'='afs.BeginEndStyle;
      }

      // padding between parens
      if (afs.PadParens >= 0) {
         LanguageSettings.setPadParens(langID, (afs.PadParens != 0));
         updateString :+= PAD_PARENS_UPDATE_KEY'='afs.PadParens;
      }

      // no space before paren
      if (afs.NoSpaceBeforeParens >= 0) {
         LanguageSettings.setNoSpaceBeforeParen(langID, (afs.NoSpaceBeforeParens != 0));
         updateString :+= NO_SPACE_BEFORE_PAREN_UPDATE_KEY'='afs.NoSpaceBeforeParens;
      }

      // indent case from switch
      if (afs.IndentCaseFromSwitch >= 0) {
         LanguageSettings.setIndentCaseFromSwitch(langID, (afs.IndentCaseFromSwitch != 0));
         updateString :+= INDENT_CASE_FROM_SWITCH_UPDATE_KEY'='afs.IndentCaseFromSwitch;
      }
   }


   // tabs
   if (afs.Tabs != '') {
      LanguageSettings.setTabs(langID, afs.Tabs);
      updateString :+= TABS_UPDATE_KEY'='afs.Tabs;
   }

   // indent with tabs
   if (afs.IndentWithTabs >= 0) {
      LanguageSettings.setIndentWithTabs(langID, (afs.IndentWithTabs != 0));
      updateString :+= INDENT_WITH_TABS_UPDATE_KEY'='afs.IndentWithTabs;
   }

   if (updateString != '') _update_buffers(langID, updateString);
}

/** 
 * Shows statistics gathered from scanning.
 * 
 */
void _ctl_stats.lbutton_up()
{
   show("_adaptive_format_statistics", _ctl_stats.p_user);
}

defeventtab _adaptive_format_statistics;

/** 
 * Builds a tree using an array of stats.  Note that if the 
 * array is screwy, your tree will as well.   
 * 
 * @param stats         array of stats
 */
void _ctl_Done.on_create(_str stats[])
{
   // prepare our treee
   _tree_stats._TreeBeginUpdate(TREE_ROOT_INDEX);
   _tree_stats._TreeSetColButtonInfo(0, 3500, -1, -1, 'Style');
   _tree_stats._TreeSetColButtonInfo(1, 1000, TREE_BUTTON_AL_RIGHT, -1, 'Total');
   _tree_stats._TreeSetColButtonInfo(2, 1000, TREE_BUTTON_AL_RIGHT, -1, 'Percentage');

   int total = 0, parent = TREE_ROOT_INDEX;

   // let's make a tree!
   int i;
   for (i = 0; i < stats._length(); i++) {
      // check for tabs - if none, then this is a group heading
      if (!pos(\t, stats[i])) {
         parent = _tree_stats._TreeAddListItem(stats[i], 0, TREE_ROOT_INDEX, 1);
         setBold(parent);
      } else {
         _tree_stats._TreeAddListItem(stats[i], 0, parent);
      }
   }
   _tree_stats._TreeEndUpdate(TREE_ROOT_INDEX);
}

/** 
 * Set the node at index to bold (used for parent nodes).
 * 
 * @param index      node to be bold
 */
void setBold(int index)
{
   int sc, bm1, bm2, flags, line;
   _tree_stats._TreeGetInfo(index, sc, bm1, bm2, flags);
   _tree_stats._TreeSetInfo(index, sc, bm1, bm2, flags | TREENODE_BOLD);
}

/** 
 * Set the node at index to be red.
 * 
 * @param index      node to be red
 */
void setRed(int index)
{
   int sc, bm1, bm2, flags, line;
   _tree_stats._TreeGetInfo(index, sc, bm1, bm2, flags);
   _tree_stats._TreeSetInfo(index, sc, bm1, bm2, flags | TREENODE_FORCECOLOR);
}

/** 
 * Close stats window.
 * 
 */
void _ctl_Done.lbutton_up()
{
   p_active_form._delete_window();
}
#if 0
void _switchbuf_adaptive_formatting(_str old_buffer_name, _str option='') {
   return;
   if (option!='' && option!='W') {
      return;
   }
   say('h1 option='option);
   typeless p;
   save_pos(p);
   top();
   if ( ! read_format_line() ) {
      updateAdaptiveFormattingSettings(AFF_TABS | AFF_INDENT_WITH_TABS | AFF_SYNTAX_INDENT);
   } else {
      // we don't want to overwrite format line settings, because those are hard-core
      // check for temp editor - we don't want to be running this during tagging and whatnot
      updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   }
   //updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS);

   restore_pos(p);
}
#endif

void _cbquit_adaptive_formatting(int buffid, _str name, _str docname= '', int flags = 0)
{
   // remove embedded adaptive formatting settings for this buffer
   adaptive_format_remove_buffer(buffid);
}

/**
 * Gets called when a buffer becomes hidden.
 */
void _cbmdibuffer_hidden_adaptive_formatting(...)
{
   //say('p_buf_name being hidden: '_mdi.p_child.p_buf_name);
   if(!isEclipsePlugin()) {  
      // remove embedded adaptive formatting settings for this buffer
      adaptive_format_remove_buffer(_mdi.p_child.p_buf_id);
   }
}

