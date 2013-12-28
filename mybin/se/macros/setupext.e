////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50373 $
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
#require "se/color/SymbolColorAnalyzer.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#require "se/options/DialogExporter.e"
#import "adaptiveformatting.e"
#import "aliasedt.e"
#import "alllanguages.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "box.e"
#import "c.e"
#import "cobol.e"
#import "ccode.e"
#import "codehelp.e"
#import "color.e"
#import "commentformat.e"
#import "complete.e"
#import "config.e"
#import "cutil.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "htmltool.e"
#import "ini.e"
#import "ispflc.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "math.e"
#import "mouse.e"
#import "options.e"
#import "optionsxml.e"
#import "picture.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "slickc.e"
#import "xmlwrap.e"
#import "xmldoc.e"
#endregion
 
using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;
using se.color.SymbolColorAnalyzer;

#define NONE_LANGUAGES        '(None)'

/*
    _c_extform
    _e_extform
    _java_extform
    _cs_extform
    _js_extform
    _cfscript_extform
    _phpscript_extform
    _python_extform
    _tcl_extform
    _pl_extform
    _idl_extform
    _pas_extform
    _prg_extform
    _cob_extform
    _bas_extform
    _for_extform
    _ada_extform
*/

/*
  Most options are stored in the def-options-[ext] for the given
  extension setup, which is simply a string of settings, separated
  by spaces.  See the default syntax info below for more information.
  The options, in general, have the following meaning, though, some
  languages have more options or variations.  Notably, HTML is
  differs from this pattern quite a bit.

  Pos.  Ext.  Description                           Default
  ----------------------------------------------------------
  1     all   Smart Indent amount                   4
  2     all   Syntax expansion on/off               1
  3     all   Minimum Expanded Keyword Length       1
  4     most  Keyword case and autocasing option    0
  5     all   Block expansion style                 0
  6     C     Indent first level                    3
        for   Multi-line IF expression              ?
  7     C     main level                            0
        pas   Indent case statement                 ?
        390   line number style options             0
  8     C     Indent case statement                 0
        pl1   Indent when statement                 0
  9     C     Use Cont on Parameter                 0

  For option number 7, by 390, we mean the traditional S/390
  programming languages allowing line numbers in columns
  73-80, including COBOL, asm390, fortran, pl1, jcl, rexx, db2.

  Note: Pascal uses parameter 7 for the case indent style, but
  it would be better if it used parameter 8 for this option
  for consistency.  Unfortunately, it can't realistically be
  fixed.  This does not affect the use of line-number options
  since C and Pascal will not allow line numbers in 73-80 to
  our knowledge, even on OS/390.
*/

#define PROMPT_TABS_DIFFER _tabs.p_user  // whether user was asked if Syntax Indent differs from tabs
#define BEGIN_END_PAIRS _beginend_pairs.p_user
#define SMARTPASTE_INDEX   _smartp.p_user

struct OPENENCODINGTAB {
   _str text;
   _str option;
   int codePage;
   int OEFlags;
};
void _UTF8GetOpenEncodingTable(_str (&encTable)[]);
/*
static OPENENCODINGTAB gOpenEncodingTab[]= {
   {"Default","",-1,OEFLAG_REMOVE_FROM_SAVEAS|OEFLAG_REMOVE_FROM_DIFF/*|OEFLAG_KEEP_FOR_APPEND*/}
   ,{"Auto XML","+fautoxml",-1,OEFLAG_REMOVE_FROM_NEW}
   ,{"Auto Unicode","+fautounicode",-1,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Auto Unicode2","+fautounicode2 ",-1,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Auto EBCDIC","+fautoebcdic ",-1,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Auto EBCDIC and Unicode","+fautoebcdic,unicode ",-1,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Auto EBCDIC and Unicode2","+fautoebcdic,unicode2 ",-1,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Text, SBCS/DBCS mode","+ftext ",VSCP_ACTIVE_CODEPAGE,OEFLAG_REMOVE_FROM_NEW|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Binary, SBCS/DBCS mode","+lb +ftext ",-1,OEFLAG_BINARY|OEFLAG_REMOVE_FROM_DIFF}
   ,{"Text","+facp ",-1}
   ,{"UTF-8","+futf8s ",VSENCODING_UTF8_WITH_SIGNATURE}
   ,{"UTF-8, no signature","+futf8 ",VSENCODING_UTF8,OEFLAG_REMOVE_FROM_OPEN|OEFLAG_REMOVE_FROM_DIFF}
   ,{"UTF-16","+futf16les ",VSENCODING_UTF16LE_WITH_SIGNATURE}
   ,{"UTF-16 big endian","+futf16bes ",VSENCODING_UTF16BE_WITH_SIGNATURE}
   ,{"UTF-16, no signature","+futf16le ",VSENCODING_UTF16LE,OEFLAG_REMOVE_FROM_OPEN|OEFLAG_REMOVE_FROM_DIFF}
   ,{"UTF-16 big endian, no signature","+futf16be ",VSENCODING_UTF16BE,OEFLAG_REMOVE_FROM_OPEN|OEFLAG_REMOVE_FROM_DIFF}
   ,{"UTF-32","+futf32les ",VSENCODING_UTF32LE_WITH_SIGNATURE}
   ,{"UTF-32 big endian","+futf32bes ",VSENCODING_UTF32BE_WITH_SIGNATURE}
   ,{"UTF-32, no signature","+futf32le ",VSENCODING_UTF32LE,OEFLAG_REMOVE_FROM_OPEN|OEFLAG_REMOVE_FROM_DIFF}
   ,{"UTF-32 big endian, no signature","+futf32be ",VSENCODING_UTF32BE,OEFLAG_REMOVE_FROM_OPEN|OEFLAG_REMOVE_FROM_DIFF}
   ,{"EBCDIC, SBCS/DBCS mode",0,VSCP_EBCDIC_SBCS,OEFLAG_REMOVE_FROM_DIFF}
   ,{"Arabic (Windows-1256)",0,1256}
   ,{"Arabic (ISO-8859-6)",0,VSCP_ISO_8859_6}
   ,{"Baltic (Windows-1257)",0,1257}
   ,{"Central and Eastern Europe (ISO-8859-2)",0,VSCP_ISO_8859_2}
   ,{"Chinese Traditional (Big5)",0,936}
   ,{"Cyrillic (ISO-8859-5)",0,VSCP_ISO_8859_5}
   ,{"Cyrillic (KOI8-R)",0,VSCP_CYRILLIC_KOI8_R}
   ,{"Cyrillic (Windows-1251)",0,1251}
   ,{"Greek (Windows-1253)",0,1253}
   ,{"Greek (ISO-8859-7)",0,VSCP_ISO_8859_7}
   ,{"Hebrew (ISO-8859-8)",0,VSCP_ISO_8859_8}
   ,{"Hebrew (Windows-1255)",0,1255}
   ,{"Japanese (Shift-Jis)",0,932}
   ,{"Korean (Windows-949)",0,949}
   ,{"Latin 4 (ISO-8859-4)",0,VSCP_ISO_8859_4}
   ,{"Latin 5 (ISO-8859-9)",0,VSCP_ISO_8859_9}
   ,{"Latin 6 (ISO-8859-10)",0,VSCP_ISO_8859_10}
   ,{"Thai (Windows-874)",0,874}
   ,{"Turkish (Windows-1254)",0,1254}
   ,{"Western European (Windows-1252)",0,1252}
   ,{"Western European (ISO-8859-1)",0,VSCP_ISO_8859_1}
};
*/

/**
 * The <b>setupext</b> command displays the Language Options
 * section of the options dialog.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command setupext(_str extOptions='')
{
   _macro_delete_line();

   // parse dialog initialization options
   _str lang='';
   _str tabNumber='';
   while (extOptions != '') {
      _str word='';
      parse extOptions with word extOptions;
      if (first_char(word)=='-') {
         word = substr(word,2);
         switch (lowcase(word)) {
         case 'indent':          
         case '0':          
            tabNumber = 'Indent'; 
            break;
         case 'wordwrap':
         case '1':
            tabNumber = 'Word Wrap'; 
            break;
         case 'general':    
         case '2':     
            tabNumber = 'General'; 
            break; 
         case 'comments':        
         case '3':        
            tabNumber = 'Comments'; 
            break;
         case 'view':    
            tabNumber = 'View'; 
            break; 
         case 'adaptiveformatting':    
            tabNumber = 'Adaptive Formatting'; 
            break; 
         case 'formatting':    
            tabNumber = 'Formatting'; 
            break; 
         case 'aliases':    
            tabNumber = 'Aliases'; 
            break; 
         case 'commentwrap':     
         case '4':     
            tabNumber = 'Comment Wrap'; 
            break;
         case 'advanced':        
         case '5':        
            tabNumber = 'Advanced'; 
            break;
         case 'autocomplete':    
         case '6':    
            tabNumber = 'Auto-Complete'; 
            break;
         case 'tagging':         
         case '7':         
            tabNumber = 'Context Tagging':+VSREGISTEREDTM; 
            break;
         case 'colorcoding':         
            tabNumber = 'Color Coding'; 
            break;
         case 'fileoptions':         
            tabNumber = 'File Options';
            break;
         default:
            tabNumber = 'General';
            break; 
         }
      } else {
         lang=strip(word' 'extOptions);
         break;
      }
   }
   if (lang=='' && !_no_child_windows()) {
      typeless orig_values;
      int embedded_status=_mdi.p_child._EmbeddedStart(orig_values);
      if (embedded_status==1) {
         lang=_mdi.p_child.p_LangId;
         _mdi.p_child._EmbeddedEnd(orig_values);
      } else {
         lang=_mdi.p_child.p_LangId;
      }
   } else if (lang == '') {
      lang = FUNDAMENTAL_LANG_ID;
   }
   if (tabNumber == '') {
      tabNumber = 'General';
   }

   // now show me the form
   if (lang != '') {
      lang = _LangId2Modename(lang);
      if (lang != '') {

         typeless result = config(lang' > 'tabNumber, 'L');
   
         if (result == '') {
            return(COMMAND_CANCELLED_RC);
         }
      }
   }
}

int _OnUpdate_setupext(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   language := target_wid._GetEmbeddedLangId();
   if (language == "") language = "fundamental";
   modeName := _LangId2Modename(language);

   _menu_get_state(cmdui.menu_handle,command,auto flags,"m",auto caption);
   parse caption with caption "\t" auto keys;
   viewOptions := pos("-view", command)? " View":"";

   int status = _menu_set_state(cmdui.menu_handle,
                                cmdui.menu_pos,
                                MF_ENABLED,
                                "p",
                                modeName :+ viewOptions :+ " &Options...\t"keys);

   return status;
}

void get_language_inheritance_list(_str langId, _str (&ancestors)[])
{
   ancestors._makeempty();
   ancestors[0] = langId;

   for (;;) {

      // look up the language we inherit from
      _str def_inherit = "def-inherit-";
      def_inherit :+= langId;
      index := find_index(def_inherit, MISC_TYPE);

      // nothing?  we are done then
      if (index <= 0) break;

      langId = name_info(index);
      ancestors[ancestors._length()] == langId;
   }
}

boolean _is_syntax_indent_supported(_str langId)
{
   // if we don't have these options, then we wouldn't know what kind of indent to do anyway
   return (find_index('def-options-'langId, MISC_TYPE) > 0 && langId != 'fundamental');
}

boolean _is_smarttab_supported(_str ext)
{
   index := _FindLanguageCallbackIndex("_%s_is_smarttab_supported", ext);
   if (!index || !index_callable(index)) {
      return false;
   }
   return call_index(index);
}

void setAdaptiveLinks(_str langID)
{
   if (langID == '') return;

   if (_find_control('_keyword_case_ad_form_link')) {
      _keyword_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_KEYWORD_CASING);
      _keyword_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_begin_end_ad_form_link')) {
      _begin_end_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_BEGIN_END_STYLE);
      _begin_end_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_indent_case_ad_form_link')) {
      _indent_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_INDENT_CASE);
      _indent_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_no_space_ad_form_link')) {
      _no_space_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_NO_SPACE_BEFORE_PAREN);
      _no_space_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_pad_parens_ad_form_link')) {
      _pad_parens_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_PAD_PARENS);
      _pad_parens_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_tag_case_ad_form_link')) {
      _tag_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_TAG_CASING);
      _tag_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_attribute_case_ad_form_link')) {
      _attribute_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_ATTRIBUTE_CASING);
      _attribute_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_value_case_ad_form_link')) {
      _value_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_VALUE_CASING);
      _value_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_hex_value_case_ad_form_link')) {
      _hex_value_case_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_HEX_VALUE_CASING);
      _hex_value_case_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_indent_ad_form_link')) {
      _indent_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_SYNTAX_INDENT);
      _indent_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_tabs_ad_form_link')) {
      _tabs_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_TABS);
      _tabs_ad_form_link.p_mouse_pointer = MP_HAND;
   }

   if (_find_control('_indent_with_tabs_ad_form_link')) {
      _indent_with_tabs_ad_form_link.p_caption = getAdaptiveLinkText(langID, AFF_INDENT_WITH_TABS);
      _indent_with_tabs_ad_form_link.p_mouse_pointer = MP_HAND;
   }
}


static void FillInLexerNameList()
{
   _lbclear();
   _str filename='';
   _str filenamelist=LEXER_FILE_LIST;
   for (;;) {
      parse filenamelist with filename (PATHSEP) filenamelist;
      if (filename=='') break;
      _ini_list_sections(filename);
   }
   _remove_duplicates();
}
/**
 * Get the encoding list.
 */
void _EncodingListInit(OPENENCODINGTAB (&openEncodingTab)[])
{
   // Get the encoding list.
   int i;
   _str encTable[];
   int encCount;
   _str codePageName, opts;
   _str codePageValue, oeFlags;
   _UTF8GetOpenEncodingTable(encTable);
   for (i=0; i<encTable._length(); i++) {
      parse encTable[i] with codePageName"\t"opts"\t"codePageValue"\t"oeFlags;
      openEncodingTab[i].text = codePageName;
      openEncodingTab[i].option = (opts=="") ? 0:opts;

      // check for code page value
      if (codePageValue != null && codePageValue != "") openEncodingTab[i].codePage = (int)codePageValue;
      else openEncodingTab[i].codePage = -1;

      // check for some flags
      if (oeFlags != null && oeFlags != "") openEncodingTab[i].OEFlags = (int)oeFlags;
      else openEncodingTab[i].OEFlags = 0;
   }
}
_str _EncodingGetComboSetting()
{
   if (!_find_control('ctlencoding')) {
      return('');
   }
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   if (!openEncodingTab._length() && !ctlencoding.p_Noflines) {
      // We have no encodings in the array or in the list box
      return("");
   }
   //If any items were deleted, we have to look it up
   if (ctlencoding.p_Noflines!=openEncodingTab._length()) {
      return(_EncodingGetOptionFromTitle(ctlencoding.p_text));
   }
   _str new_encoding_info=openEncodingTab[ctlencoding.p_line-1].option;
   // IF the encoding info is a code page
   if (!new_encoding_info) {
      new_encoding_info='+fcp'openEncodingTab[ctlencoding.p_line-1].codePage;
   }
   return(new_encoding_info);
}
void _EncodingFillComboList(_str encoding='',_str defaultSetting='Default',int SkipFlags=0)
{
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   int i;
   int init_i= 0;
   openEncodingTab[0].text=defaultSetting;
   encoding=strip(encoding);
   for (i=0;i<openEncodingTab._length();++i) {
      if (!(SkipFlags&openEncodingTab[i].OEFlags)) {
         ctlencoding._lbadd_item(openEncodingTab[i].text);
         if (strieq(strip(openEncodingTab[i].option),encoding) ||
             strieq(strip("+fcp"openEncodingTab[i].codePage),encoding)
             ) {
            init_i=i;
         }
      }
   }
   ctlencoding.p_text=openEncodingTab[init_i].text;
}
_str _EncodingGetOptionFromTitle(_str Title)
{
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   // Run this loop backwards because openEncodingTab[0] is 'DEFAULT' and
   // we don't want to return that name if we can avoid it.
   int i;
   for (i=openEncodingTab._length()-1;i>=0;--i) {
      if (openEncodingTab[i].text==Title) {
         if (!openEncodingTab[i].option) {
            /*
               Clark: Need to return '' if codePage<0.  File->New, select XML, Automatic and 
               get +fcp-1 as the encoding which is garbage.  The codePage for Automatic is -1. 
            */
            if (openEncodingTab[i].codePage<0) return('');
            return('+fcp'openEncodingTab[i].codePage);
         }else {
            return(openEncodingTab[i].option);
         }
      }
   }
   return('');
}

/**
 * Get all the file extensions defined as being mapped to languages. 
 * See our file extension manager dialog ("Tools" > "Options...", 
 * "File Extension Manager") for a complete list of file extensions. 
 * The current object must be a list box, which the file extensions 
 * will be inserted into.
 */
static void get_all_file_extensions()
{
   // get file extensions referred to standard extensions
   index := name_match('def-lang-for-ext-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),18);
     _lbadd_item(name);
     index=name_match('def-lang-for-ext-',0,MISC_TYPE);
   }
}

/**
 * Insert all the language mode names into the current list box. 
 *  
 * options - specify 'I' to get only installed languages, 
 * 'U' to get only user-defined languages.  Anything else 
 * returns all languages. 
 */
void _lbaddModeNames(_str options='')
{
   get_all_mode_names(options);
}

/**
 * Get all the language mode names.  The current object
 * must be a list box, which the mode names will be inserted into. 
 *  
 * options - specify 'I' to get only installed languages, 
 * 'U' to get only user-defined languages.  Anything else 
 * returns all languages. 
 */
void get_all_mode_names(_str options = '')
{
   options = upcase(options);

   // get language specific primary extensions
   index := name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),14);

     do {
        if (options == 'I' && !_IsInstalledLanguage(name)) break;
        if (options == 'U' && _IsInstalledLanguage(name)) break;
        _lbadd_item(_LangId2Modename(name));
     } while (false);

     index=name_match('def-language-',0,MISC_TYPE);
   }
}

/**
 * Get all the language mode names.  The current object
 * must be a list box, which the mode names will be inserted into. 
 *  
 * options - specify 'I' to get only installed languages, 
 * 'U' to get only user-defined languages.  Anything else 
 * returns all languages. 
 */
static void get_all_mode_names_mark_installed()
{
   // get language specific primary extensions
   index := name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),14);

     if (_IsInstalledLanguage(name)) {
        _lbadd_item(_LangId2Modename(name), 100, _pic_lbvs);
     } else {
        _lbadd_item(_LangId2Modename(name), 100);
     }

     index=name_match('def-language-',0,MISC_TYPE);
   }
}

/**
 * Update the set of file extensions associated with the given
 * language mode.
 */
void update_file_extensions(_str lang, _str file_extensions)
{
   // first get rid of stale extension mappings
   changedSomething := false;
   name := "";
   index := name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index > 0) {
      name = substr(name_name(index),18);
      if (name_info(index) == lang) {
         if (!pos(' 'name' ',' 'file_extensions' ') &&
             !pos(' 'name' ',' .'file_extensions' ') ) {
            delete_name(index);
            changedSomething = true;
         }
      }
      index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }
   // next create or update the new mappings
   foreach (name in file_extensions) {
      if (first_char(name)=='.') name = substr(name,2);
      index = find_index('def-lang-for-ext-'name,MISC_TYPE);
      if (index > 0) {
         if (name_info(index) != lang) {
            set_name_info(index,lang);
            changedSomething = true;
         }
      } else {
         insert_name('def-lang-for-ext-'name,MISC_TYPE,lang);
         changedSomething = true;
      }
   }
   // if we changed a language referral, clear the cache
   if (changedSomething) {
      _ClearDefaultLanguageOptionsCache();
   }
}

/**
 * Return a string containing a list of file extensions
 * associated with the given language mode.
 */
static _str get_file_extensions(_str lang)
{
   // look for other file extensions that match
   file_extensions := "";
   index := name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index > 0) {
      if (name_info(index)==lang) {
         name := substr(name_name(index),18);
         _maybe_append(file_extensions," ");
         file_extensions :+= name;
      }
      index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }
   // that's all folks
   return file_extensions;
}

_str get_file_extensions_sorted_with_dot(_str lang)
{
   // look for other file extensions that match
   _str extensions[];
   index := name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index > 0) {
      if (name_info(index)==lang) {
         name := substr(name_name(index),18);
         extensions[extensions._length()] = name;
      }
      index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }

   extensions._sort();

   file_extensions := ". ";
   int i;
   for (i = 0; i < extensions._length(); i++) {
      file_extensions :+= '.'extensions[i]' ';
   }

   // that's all folks
   return strip(file_extensions);
}

_str get_referenced_in_languages(_str lang)
{
   modeList := '';
   langList := LanguageSettings.getReferencedInLanguageIDs(lang);
   foreach (auto refLangID in langList) {
      // no need to include this language
      if (refLangID == lang) continue;

      mode := _LangId2Modename(refLangID);
      if (mode == "") continue;

      if (modeList != '') {
         modeList :+= ", ";
      }
      modeList :+= mode;
   }

   return modeList;
}

void update_referenced_in_languages(_str lang, _str list)
{
   // this will be a list of mode names, we need to make them extensions
   langList := '';
   modeName := '';
   while (true) {
      parse list with modeName ', ' list;
      if (modeName == '') break;

      langId := _Modename2LangId(modeName);
      if (langId == lang) continue;

      langList :+= langId' ';
   }

   langList = strip(langList);
   LanguageSettings.setReferencedInLanguageIDs(lang, langList);
}

_str get_file_extensions_sorted(_str lang)
{
   // look for other file extensions that match
   _str extensions[];
   index := name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index > 0) {
      if (name_info(index)==lang) {
         name := substr(name_name(index),18);
         extensions[extensions._length()] = name;
      }
      index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }

   extensions._sort();

   file_extensions := "";
   int i;
   for (i = 0; i < extensions._length(); i++) {
      file_extensions :+= extensions[i]' ';
   }

   // that's all folks
   return strip(file_extensions);
}

/**
 * Get the codehelp options wich are a bitset of
 * <code>VSCODEHELPFLAG_*</code>.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>def_codehelp_flags</code> as the default.
 * 
 * @param lang    language ID
 * 
 * @return bitset of VSCODEHELPFLAG_* options.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @deprecated Use {@link _GetCodehelpFlags()}
 */
int _ext_codehelp_flags(_str lang='')
{
   return _GetCodehelpFlags(lang);
}
/**
 * Get the codehelp options for the specified language.
 * The options are a bitset of <code>VSCODEHELPFLAG_*</code>.
 * <p>
 * The options are stored per language.  If the options are not yet defined 
 * for a language, then use <code>def_codehelp_flags</code> as the default.
 * 
 * @param lang    language ID, see {@link p_LangId}
 * 
 * @return bitset of VSCODEHELPFLAG_* options.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Tagging_Functions
 */
int _GetCodehelpFlags(_str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }

   return LanguageSettings.getCodehelpFlags(lang);
}

/**
 * Struct holding the language extension comment wrap settings
 */
typedef struct {
   _str enable_block;        
   _str enable_javadoc;    
   _str use_auto_override;         
   _str javadoc_auto_indent; 
   _str use_fixed_width;     
   _str fixed_width_size;    
   _str use_first_para;      
   _str use_fixed_margins;   
   _str right_margin;        
   _str max_right;    
   _str max_right_column;      
   _str max_right_dyn;
   _str max_right_column_dyn;  
   _str match_prev_para;
   _str enable_lineblock;        
   _str enable_commentwrap;
   _str line_comment_min;
} commentWrapSettings_t;
static commentWrapSettings_t CW_commentwrap_flags_hash:[];

/**
 * Get the comment wrap flags.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>CFcommentWrapDefaults</code> as the default.
 * 
 * @param lang    language ID
 * 
 * @return structure of type CommentWrapSettings_t.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 * @deprecated Use {@link _GetCommentWrapFlags()}. 
 */
typeless _ext_commentwrap_flags(int commentWrapOption, _str lang = '')
{
   return _GetCommentWrapFlags(commentWrapOption, lang);
}
/**
 * Get the comment wrap flags.
 * <p>
 * The options are stored per language.  If the options are 
 * not yet defined for the specified language, then use
 * <code>CFcommentWrapDefaults</code> as the default.
 *  
 * @param commentWrapOption   comment wrap option to extract 
 * @param lang                language ID, see {@p_LangId}
 * 
 * @return structure of type CommentWrapSettings_t.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
typeless _GetCommentWrapFlags(int commentWrapOption, _str lang = '')
{
   if (lang == '') {
      lang = CW_saveCurrentLang();
   }
   commentWrapSettings_t flags;
   if (CW_commentwrap_flags_hash._indexin(lang)) {
      flags = CW_commentwrap_flags_hash:[lang];
   } else {
      _str CommentWrapSettings = _GetCommentWrapFlags2(lang);
      parse CommentWrapSettings with flags.enable_block flags.enable_javadoc flags.use_auto_override flags.javadoc_auto_indent flags.use_fixed_width flags.fixed_width_size flags.use_first_para flags.use_fixed_margins flags.right_margin flags.max_right flags.max_right_column flags.max_right_dyn flags.max_right_column_dyn flags.match_prev_para flags.enable_lineblock flags.enable_commentwrap flags.line_comment_min .; 
      CW_commentwrap_flags_hash:[lang] = flags;
   }
   typeless returnVal = '';
   switch (commentWrapOption) {
   case  CW_ENABLE_BLOCK_WRAP: 
      returnVal = flags.enable_block != '0' ? true : false;                  
      if (flags.enable_block == "") {
         returnVal = false;
      }
      if (!commentwrap_isSupportedLanguage(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  CW_ENABLE_COMMENT_WRAP: 
      returnVal = flags.enable_commentwrap != '0' ? true : false;                  
      if (flags.enable_commentwrap == "") {
         returnVal = true;
      }
      if (!commentwrap_isSupportedLanguage(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  CW_ENABLE_LINEBLOCK_WRAP: 
      returnVal = flags.enable_lineblock != '0' ? true : false;  
      if (flags.enable_lineblock == "") {
         returnVal = false;
      }
      if (!commentwrap_isSupportedLanguage(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  CW_ENABLE_DOCCOMMENT_WRAP: 
      returnVal = flags.enable_javadoc != '0' ? true : false;                  
      if (flags.enable_javadoc == "") {
         returnVal = false;
      }
      if (!commentwrap_isSupportedLanguage(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  CW_AUTO_OVERRIDE:                                        
      returnVal = flags.use_auto_override != '0' ? true : false;                  
      break;                                                      
   case  CW_JAVADOC_AUTO_INDENT:                                 
      returnVal = flags.javadoc_auto_indent != '0' ? true : false;                  
      break;                                                      
   case  CW_USE_FIXED_WIDTH:                
      returnVal = flags.use_fixed_width != '0' ? true : false;                  
      break;                                                      
   case  CW_FIXED_WIDTH_SIZE:                                     
      if (isuinteger(flags.fixed_width_size)) {
         returnVal = (int)flags.fixed_width_size;              
      } else {
         returnVal = CW_defaultFixedWidth;
      }
      break;                                                      
   case  CW_USE_FIRST_PARA:                                       
      returnVal = flags.use_first_para != '0' ? true : false;                  
      break;                                                      
   case  CW_USE_FIXED_MARGINS:                                      
      returnVal = flags.use_fixed_margins != '0' ? true : false;                  
      break;                                                      
   case  CW_RIGHT_MARGIN:                                          
      if (isuinteger(flags.right_margin)) {
         returnVal = (int)flags.right_margin;               
      } else {
         returnVal = CW_defaultRightMargin;
      }
      break;                                                      
   case  CW_MAX_RIGHT:                                 
      returnVal = flags.max_right != '0' ? true : false;                  
      break;                                                      
   case  CW_MAX_RIGHT_COLUMN:                                   
      if (isuinteger(flags.max_right_column)) {
         returnVal = (int)flags.max_right_column;              
      } else {
         returnVal = CW_defaultRightMargin;
      }
      break;
   case  CW_MAX_RIGHT_DYN:                                 
      returnVal = flags.max_right_dyn != '0' ? true : false;                  
      break;                                                      
   case  CW_MAX_RIGHT_COLUMN_DYN:
      if (isuinteger(flags.max_right_column_dyn)) {
         returnVal = (int)flags.max_right_column_dyn;             
      } else {
         returnVal = CW_defaultRightMargin;
      }
      break;
   case  CW_MATCH_PREV_PARA:                                 
      returnVal = flags.match_prev_para != '0' ? true : false;                  
      break;                                                      
   case  CW_LINE_COMMENT_MIN:                                     
      if (isuinteger(flags.line_comment_min)) {
         returnVal = (int)flags.line_comment_min;              
      } else {
         returnVal = CW_defaultLineCommentMin;
      }
      break;                                                      
   default:
      break;
   }
   return (returnVal);
}
/**
 * Set comment wrap flags.
 * 
 * @param commentWrapOption 
 * @param value 
 * @param lang 
 * 
 * @deprecated Use _SetCommentWrapFlags()
 */
void _ext_commentwrap_set_flags(int commentWrapOption, typeless value, _str lang='')
{
   _SetCommentWrapFlags(commentWrapOption,value,lang);
}
/**
 * Set comment wrap flags.
 * 
 * @param commentWrapOption 
 * @param value 
 * @param lang 
 */
void _SetCommentWrapFlags(int commentWrapOption, typeless value, _str lang='')
{
   if (lang == '') {
      lang = CW_saveCurrentLang();
   }
   commentWrapSettings_t flags;
   if (CW_commentwrap_flags_hash._indexin(lang)) {
      flags = CW_commentwrap_flags_hash:[lang];
   } else {
      _str CommentWrapSettings = _GetCommentWrapFlags2(lang);
      parse CommentWrapSettings with flags.enable_block flags.enable_javadoc flags.use_auto_override flags.javadoc_auto_indent flags.use_fixed_width flags.fixed_width_size flags.use_first_para flags.use_fixed_margins flags.right_margin flags.max_right flags.max_right_column flags.max_right_dyn flags.max_right_column_dyn flags.match_prev_para flags.enable_lineblock flags.enable_commentwrap flags.line_comment_min .; 
   }
   switch (commentWrapOption) {
   case  CW_ENABLE_BLOCK_WRAP: 
      flags.enable_block = value ? '1' : '0';
      break;                                                      
   case  CW_ENABLE_COMMENT_WRAP: 
      flags.enable_commentwrap = value ? '1' : '0';
      break;                                                      
   case  CW_ENABLE_LINEBLOCK_WRAP: 
      flags.enable_lineblock = value ? '1' : '0';
      break;                                                      
   case  CW_ENABLE_DOCCOMMENT_WRAP: 
      flags.enable_javadoc = value ? '1' : '0';                  
      break;                                                      
   case  CW_AUTO_OVERRIDE:                                        
      flags.use_auto_override = value ? '1' : '0';            
      break;                                                      
   case  CW_JAVADOC_AUTO_INDENT:                                 
      flags.javadoc_auto_indent = value ? '1' : '0';          
      break;                                                      
   case  CW_USE_FIXED_WIDTH:                
      flags.use_fixed_width = value ? '1' : '0';
      break;                                                      
   case  CW_FIXED_WIDTH_SIZE:                                     
      flags.fixed_width_size = value;                 
      break;                                                      
   case  CW_USE_FIRST_PARA:                                       
      flags.use_first_para = value ? '1' : '0';
      break;                                                      
   case  CW_USE_FIXED_MARGINS:                                      
      flags.use_fixed_margins = value ? '1' : '0';
      break;                                                      
   case  CW_RIGHT_MARGIN:                                          
      flags.right_margin = value;                     
      break;                                                      
   case  CW_MAX_RIGHT:                                 
      flags.max_right = value ? '1' : '0';    
      break;                                                      
   case  CW_MAX_RIGHT_COLUMN:                                   
      flags.max_right_column = value;              
      break;
   case  CW_MAX_RIGHT_DYN:                                 
      flags.max_right_dyn = value ? '1' : '0';  
      break;                                                      
   case  CW_MAX_RIGHT_COLUMN_DYN:                                   
      flags.max_right_column_dyn = value;
      break;
   case  CW_MATCH_PREV_PARA:
      flags.match_prev_para = value ? '1' : '0';
      break;
   case  CW_LINE_COMMENT_MIN:                                     
      flags.line_comment_min = value;              
      break;
   }

   _SetLanguageOption(lang, "comment_wrap", flags.enable_block' 'flags.enable_javadoc' 'flags.use_auto_override' 'flags.javadoc_auto_indent' 'flags.use_fixed_width' 'flags.fixed_width_size' 'flags.use_first_para' 'flags.use_fixed_margins' 'flags.right_margin' 'flags.max_right' 'flags.max_right_column' 'flags.max_right_dyn' 'flags.max_right_column_dyn' 'flags.match_prev_para' 'flags.enable_lineblock' 'flags.enable_commentwrap' 'flags.line_comment_min);
   CW_commentwrap_flags_hash:[lang] = flags;
}
static _str _GetCommentWrapFlags2(_str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }
   return LanguageSettings.getCommentWrapOptions(lang);
}

void _ClearCommentWrapFlags(_str lang = '')
{
   if (lang == '') {
      CW_commentwrap_flags_hash._makeempty();
   } else {
      if (CW_commentwrap_flags_hash._indexin(lang)) {
         CW_commentwrap_flags_hash._deleteel(lang);
      }
   }
}

boolean xw_lang_testAndSet(_str& lang) {
   if (_LanguageInheritsFrom('html', lang) && !_LanguageInheritsFrom('tld',lang)) {
      lang = 'html';
      return true;
   }
   if (_LanguageInheritsFrom('xsd', lang)) {
      lang = 'xsd';
      return true;
   }
   if (_LanguageInheritsFrom('xhtml', lang)) {
      lang = 'xhtml';
      return true;
   }
   if (_LanguageInheritsFrom('docbook', lang)) {
      lang = 'docbook';
      return true;
   }
   if (_LanguageInheritsFrom('vpj', lang)) {
      lang = 'vpj';
      return true;
   }
   if (_LanguageInheritsFrom('xml', lang)) {
      lang = 'xml';
      return true;
   }
   return false;
}

boolean XW_isXMLTagLanguage(_str lang = p_LangId) 
{
   return (XW_isSupportedLanguage_XML(lang) && _FindLanguageCallbackIndex("vs%s_list_tags"));
}

boolean XW_isHTMLTagLanguage(_str lang = p_LangId) 
{
   return (XW_isSupportedLanguage_HTML(lang) && _FindLanguageCallbackIndex("vs%s_list_tags"));
}

boolean XW_isSupportedLanguage(_str lang = p_LangId) 
{
   if (XW_isSupportedLanguage_XML(lang) || XW_isSupportedLanguage_HTML(lang)) {
      return (true);
   }
   return (false);
}

boolean XW_isSupportedLanguage_XML(_str lang = p_LangId) 
{
   if (_LanguageInheritsFrom('xml', lang) ||
       _LanguageInheritsFrom('xsd', lang) ||
       _LanguageInheritsFrom('docbook', lang) ||
       _LanguageInheritsFrom('vpj', lang) ||
       _LanguageInheritsFrom('xhtml', lang)) {
      return (true);
   }
   return (false);
}
boolean XW_isSupportedLanguage_HTML(_str lang = p_LangId) 
{
   if (_LanguageInheritsFrom('html', lang) && !_LanguageInheritsFrom('tld',lang)) {
      return (true);
   }
   return (false);
}

boolean XW_isSupportedLanguage2(_str lang = p_LangId) 
{
   if (command_state() || !_isEditorCtl())
      return (XW_isSupportedLanguage(lang));

   boolean returnVal = false;
   // Handle embedded language
   typeless orig_values;
   int embedded_status = _EmbeddedStart(orig_values);
   if (embedded_status == 1) {
      if (XW_isSupportedLanguage(p_LangId) && !_in_comment()) {
         returnVal = true;
      }
      _EmbeddedEnd(orig_values);
   } else {
      if (XW_isSupportedLanguage(lang) && !_in_comment()) {
         returnVal = true;
      }
   }
   return returnVal;
}

/**
 * @return Return the XML wrap options for the specified language.
 * 
 * @param xmlWrapOption    one of XW_ENABLE_*
 * @param lang             language ID, see {@link p_LangId}
 * 
 * @deprecated Use {@link _GetXMLWrapFlags()}
 */
typeless _ext_xmlwrap_flags(int xmlWrapOption, _str lang /*= p_LangId*/)
{
   return _GetXMLWrapFlags(xmlWrapOption, lang);
}
/**
 * @return Return the XML wrap options for the specified language.
 * 
 * @param xmlWrapOption    one of XW_ENABLE_*
 * @param lang             language ID, see {@link p_LangId}
 */
typeless _GetXMLWrapFlags(int xmlWrapOption, _str lang/*=p_LangId*/)
{
   //_str enable_feature;        
   _str enable_CW = '';    
   _str enable_TL = '';    
   _str default_scheme = '';    

   _str xmlWrapSettings = _GetXMLWrapFlags2(lang);
   parse xmlWrapSettings with /*enable_feature*/ enable_CW enable_TL default_scheme .; 
   if (enable_CW == "") enable_CW = '0';
   if (enable_TL == "") enable_TL = '0';
   if (default_scheme == "") default_scheme = XW_NODEFAULTSCHEME;
   typeless returnVal = '';
   switch (xmlWrapOption) {
   case  XW_ENABLE_CONTENTWRAP: 
      returnVal = enable_CW != '1' ? false : true;                  
      if (!XW_isSupportedLanguage2(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  XW_ENABLE_TAGLAYOUT: 
      returnVal = enable_TL != '1' ? false : true;                 
      if (!XW_isSupportedLanguage2(lang)) {
         returnVal = false;
      }
      break;                                                      
   case  XW_DEFAULT_SCHEME: 
      returnVal = default_scheme;                  
      if (!XW_isSupportedLanguage2(lang)) {
         returnVal = XW_NODEFAULTSCHEME;
      }
      break;                                                      
   default:
      break;
   }
   return (returnVal);
}

/**
 * Set the language specific XML wrap options.
 * 
 * @param xmlWrapOption 
 * @param value 
 * @param lang
 * 
 * @deprecated Use {@link _SetXMLWrapFlags()}
 */
void _ext_xmlwrap_set_flags(int xmlWrapOption, typeless value, _str lang = p_LangId)
{
   _SetXMLWrapFlags(xmlWrapOption, value, lang);
}
void _SetXMLWrapFlags(int xmlWrapOption, typeless value, _str lang = p_LangId)
{
   _str enable_feature = '';        
   _str enable_CW = '';    
   _str enable_TL = '';    
   _str default_scheme = '';    

   _str xmlWrapSettings = _GetXMLWrapFlags2(lang);
   parse xmlWrapSettings with enable_CW enable_TL default_scheme .;
   if (enable_CW == "") enable_CW = '0';
   if (enable_TL == "") enable_TL = '0';
   if (default_scheme == "") default_scheme = XW_NODEFAULTSCHEME;
   switch (xmlWrapOption) {
   case  XW_ENABLE_CONTENTWRAP: 
      enable_CW = value ? '1' : '0';
      break;                                                      
   case  XW_ENABLE_TAGLAYOUT: 
      enable_TL = value ? '1' : '0';
      break;                                                      
   case  XW_DEFAULT_SCHEME: 
      default_scheme = value;       
      break;        
   default:
      break;
   }
   LanguageSettings.setXMLWrapOptions(lang, enable_CW' 'enable_TL' 'default_scheme);
}
static _str _GetXMLWrapFlags2(_str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }

   return LanguageSettings.getXMLWrapOptions(lang);
}

/**
 * Determines if the string contains more than one semicolon.
 * 
 * @param BeginEndString         string to check
 * 
 * @return                       true if more than one semicolon is found in the 
 *                               string, false if <= 1 semicolons are found
 */
static boolean HasMultipleSemiColons(_str BeginEndString)
{
   int count=0;
   int p=0;
   for (;;) {
      p=pos(';',BeginEndString,p+1);
      if (!p) break;
      ++count;
      if (count>1) break;
   }
   return(count>1);
}

/**
 * Sets default extension specific options.  Use the _update_buffers 
 * function to change extension specific options for buffers already 
 * loaded.
 * 
 * @param field_name may be one of the following:
 * 
 * <dl>
 * <dt>p_mode_name or MN</dt><dd>
 *    Value specifies mode name.</dd>
 * <dt>p_tabs or TABS</dt><dd>
 *    Value specifies tab settings.</dd>
 * <dt>p_margins or MA</dt><dd>
 *    Value specifies margins.</dd>
 * <dt>p_mode_eventtab or KEYTAB</dt><dd>
 *    Value specifies mode event table.</dd>
 * <dt>p_word_wrap_style or WW</dt><dd>
 *    Value specifies word wrap style.</dd>
 * <dt>p_indent_with_tabs or IWT</dt><dd>
 *    Value specifies indent with tabs.</dd>
 * <dt>p_indent_style or IN</dt><dd>
 *    Value specifies indent style.</dd>
 * <dt>p_word_chars or WC</dt><dd>
 *    Value specifies word chaacters.</dd>
 * <dt>p_lexer_name or LN</dt><dd>
 *    Value specifies lexer name.</dd>
 * <dt>p_color_flags or CF</dt><dd>
 *    Value specifies color flags.</dd>
 * </dl>
 * 
 * <p>For the above options, <i>value</i> may not contain a comma 
 * character.
 * 
 * <p>Additional <i>field_name</i> values:</p>
 * 
 * <dl>
 * <dt>BEGINEND</dt><dd>Value specifies begin/end pairs.</dd>
 * <dt>OPTIONS</dt><dd>Value specifies extension specific options.  
 * We recommend that you use macro recording 
 * to correctly generate calls that set this option.</dd>
 * <dt>SETUP</dt><dd>Value specifies miscellaneous extension 
 * specific options.  This option is very sensitive 
 * to the order of the options.  We recommend 
 * that you use macro recording to correctly 
 * generate calls that set this option.</dd>
 * <dt>ALIAS</dt><dd>Value specifies alias filename.</dd>
 * <dt>SMARTTAB</dt><dd>Set the smart tab value for this extension, one of the following:
 * <ul>
 *    <li> VSSMARTTAB_INDENT
 *    <li> VSSMARTTAB_MAYBE_REINDENT_STRICT
 *    <li> VSSMARTTAB_MAYBE_REINDENT
 *    <li> VSSMARTTAB_ALWAYS_REINDENT
 * </ul>
 * </dd>
 * </dl>
 * 
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    // Can specify "" instead of "fundamental" to refer to buffers with no extension
 *    // Change the default margins for fundamental mode.
 *     _setext("fundamental","p_margins","1 70 1");
 *    // Update buffers already being edited
 *     _update_buffers("fundamental","p_margins=1 70 1");
 * }
 * </pre>
 * 
 * @see _update_buffers
 * 
 * @categories Buffer_Functions
 * @deprecated Use {@link _SetLanguageOption()} 
 */ 
int _setext(_str extension, _str field_name, typeless value)
{
   return _SetLanguageOption(extension,field_name,value);
}

/**
 * Sets default language-specific options.  Use the {@link _update_buffers} 
 * function to change language-specific options for files already loaded.
 *
 * @param lang    Language ID (see {@link p_LangId} 
 *                For list of languages, use our Language Manager dialog
 *                ("Tools", "Options...", "Language Manager").
 *
 * @param field_name    may be one of the following:
 * <dl>
 * <dt>p_mode_name or MN</dt>          <dd>Specifies mode name.</dd> 
 * <dt>p_tabs or TABS</dt>             <dd>Specifies tab settings.</dd> 
 * <dt>p_margins or MA</dt>            <dd>Specifies margins.</dd> 
 * <dt>p_mode_eventtab or KEYTAB</dt>  <dd>Specifies mode event table.</dd> 
 * <dt>p_word_wrap_style or WW</dt>    <dd>Specifies word wrap style.</dd>
 * <dt>p_indent_with_tabs or IWT</dt>  <dd>Specifies indent with tabs.</dd> 
 * <dt>p_show_tabs or ST</dt>          <dd>Specifies to show tabs.</dd> 
 * <dt>p_indent_style or IN</dt>       <dd>Specifies indent style.</dd> 
 * <dt>p_word_chars or WC</dt>         <dd>Specifies word chaacters.</dd>
 * <dt>p_lexer_name or LN</dt>         <dd>Specifies lexer name.</dd> 
 * <dt>p_color_flags or CF</dt>        <dd>Specifies color flags.</dd>
 * <dt>p_line_numbers_len or LNL</dt>  <dd>Specifies line number area size</dd> 
 * <dt>p_softwrap or SW</dt>           <dd>Specifies soft wrap options</dd> 
 * <dt>p_softwraponword or SOW</dd>    <dd>Specifies soft wrap on word</dd>
 * </dl>
 * <p>
 * For the above options, <i>value</i> may not contain a comma character.
 * <p>
 * Additional <i>field_name</i> values:
 * <dl>
 * <dt>LANGUAGE or SETUP</dt>          <dd>General language setup data.</dd> 
 *                                         This option is very sensitive to the 
 *                                         order of the options.  We recommend 
 *                                         that you use macro recording to 
 *                                         correctly generate calls that set 
 *                                         this option.</dd>
 * <dt>ALIAS</dt>                      <dd>Language specific alias file</dd> 
 * <dt>SMARTPASTE</dt>                 <dd>Specifies Smart Paste(TM) options</dd> 
 * <dt>SMARTTAB</dt>                   <dd>Specifies tab expansion options</dd>
 * <dt>SMARTTAB</dt>                   <dd>Set the smart tab value for this 
 *                                         language, one of the following:
 *                                         <ul>
 *                                         <li> VSSMARTTAB_INDENT
 *                                         <li> VSSMARTTAB_MAYBE_REINDENT_STRICT
 *                                         <li> VSSMARTTAB_MAYBE_REINDENT
 *                                         <li> VSSMARTTAB_ALWAYS_REINDENT
 *                                         </ul>
 *                                     </dd>
 * <dt>BEGINEND</dt>                   <dd>Specifies begin/end pairs</dd> 
 * <dt>OPTIONS</dt>                    <dd>Specifies extension specific options.
 *                                         We recommend that you use macro 
 *                                         recording to correctly generate 
 *                                         calls that set this option.</dd>
 * <dt>NUMBERING</dt>                  <dd>Specifies line numbering options</dd> 
 * <dt>SURROUND</dt>                   <dd>Specifies dynamic surround flags</dd> 
 * <dt>AUTOCOMPLETE</dt>               <dd>Specifies auto-complete flags</dd> 
 * <dt>AUTOCOMPLETEMIN</dt>            <dd>Min word length for auto-complete</dd> 
 * <dt>SYMBOLCOLORING</dt>             <dd>Symbol Coloring option flags/dd> 
 * <dt>INDENT</dt>                     <dd>Indentation options</dd> 
 * <dt>CODEHELP</dt>                   <dd>Context Tagging option flags</dd> 
 * <dt>COMMENTEDITING</dt>             <dd>Comment editing option flags</dd> 
 * <dt>DOCCOMMENT</dt>                 <dd>Documentation comment options</dd> 
 * <dt>COMMENT-WRAP</dt>               <dd>Specifies comment wrap options</dd> 
 * <dt>XML-WRAP</dt>                   <dd>Specifies XML wrap options</dd> 
 * <dt>AUTOVALIDATE</dt>               <dd>Specifies XML validation options</dd> 
 * <dt>INHERIT</dt>                    <dd>Specifies parent language for
 *                                         tagging callback inheritance</dd> 
 * <dt>ADAPTIVE-FLAGS</dt>             <dd>Specifies adaptive flags</dd> 
 * <dt>ADAPTIVE-FORMATTING</dt>        <dd>Adaptive formatting flags</dd> 
 * </dl> 
 * <p>
 * The following additional <i>field_name</i> options are actually stored
 * per file extension rather than per language.
 * <dl>
 * <dt>LANG-FOR-EXT</dt>               <dd>Maps file extension to language</dd>
 * <dt>ENCODING</dt>                   <dd>Extension-specific encoding</dd> 
 * <dt>ASSOCIATION</dt>                <dd>Extension-specific open application</dd> 
 * </dl> 
 * 
 * @param value      Value to set the option to.  
 *                   Note that some option values, as noted above,
 *                   can not contain commas.
 * 
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    // Can specify "" instead of "fundamental" to refer to Plain Text mode
 *    // Change the default margins for fundamental mode.
 *     _SetLanguageOption("fundamental","p_margins","1 70 1");
 *    // Update buffers already being edited
 *     _update_buffers("fundamental","p_margins=1 70 1");
 * }
 * </pre>
 * 
 * @see _GetLanguageSpecificOption
 * @see _GetLanguageSetupOptions
 * @see _GetDefaultLanguageOptions
 * @see _update_buffers
 * 
 * @categories Miscellaneous_Functions
 */ 
int _SetLanguageOption(_str lang, _str field_name, typeless value)
{
   _macro('m',_macro('s'));
   _macro_call('_SetLanguageOption', lang, field_name, value);
   if (lang=='') {
      lang=FUNDAMENTAL_LANG_ID;
   }
   /* messageNwait(extension' 'field_name' 'value); */
   /* messageNwait('field_name='field_name) */
   field_name = upcase(field_name);
   int maybe_create_keytab=0;
   int index=0;
   _str before="", after="";
   switch (field_name) {
   /*Combine Alias and Options cases later*/
   case 'LANG-FOR-EXT':
      ExtensionSettings.setLangRefersTo(lang, value);
      break;
   case 'SETUP':
   case 'LANGUAGE':
      index = find_index('def-language-'lang, MISC_TYPE);
      if (!index) {
         index = insert_name('def-language-'lang,MISC_TYPE,value);
         if (!index) return(NOT_ENOUGH_MEMORY_RC);
      } else {
         set_name_info(index, value);
      }
      parse name_info(index) with before ('KEYTAB=') value ',' after ;
      maybe_create_keytab=1;
      break;
   case 'ALIAS' :
      LanguageSettings.setAliasFilename(lang, value);
      break;
   case 'SMARTPASTE' :
      LanguageSettings.setSmartPaste(lang, value);
      break;
   case 'SMARTTAB' :
      LanguageSettings.setSmartTab(lang, value);
      break;
   case 'BEGINEND':
      LanguageSettings.setBeginEndPairs(lang, value);
      break;
   case 'OPTIONS' :
      int options_index = find_index('def-options-'lang, MISC_TYPE);
      if(!options_index){
         index=insert_name('def-options-'lang, MISC_TYPE,value);
         if (!index) return(NOT_ENOUGH_MEMORY_RC);
      } else {
         set_name_info(options_index, value);
      }
      break;
   case 'NUMBERING':
      LanguageSettings.setNumberingStyle(lang, value);
      break;
   case 'SURROUND':
      LanguageSettings.setSurroundOptions(lang, value);
      break;
   case 'AUTOCOMPLETE':
      LanguageSettings.setAutoCompleteOptions(lang, value);
   case 'AUTOCOMPLETEMIN':
      LanguageSettings.setAutoCompleteMinimumLength(lang, value);
      break;
   case 'SYMBOLCOLORING':
      LanguageSettings.setSymbolColoringOptions(lang, value);
      break;
   case 'INDENT':
      LanguageSettings.setBackspaceUnindents(lang, (value != '0' || value != ''));
      break;
   case 'CODEHELP' :
      LanguageSettings.setCodehelpFlags(lang, value);
      break;
   case 'COMMENTEDITING' :
      LanguageSettings.setCommentEditingFlags(lang, value);
      break;
   case 'DOCCOMMENT' :
      LanguageSettings.setDocCommentFlags(lang, value);
      break;
   case 'COMMENT_WRAP' :
      LanguageSettings.setCommentWrapOptions(lang, value);
      break;
   case 'XML_WRAP' :
      LanguageSettings.setXMLWrapOptions(lang, value);
      break;
   case 'ENCODING' :
      ExtensionSettings.setEncoding(lang, value);
      break;
   case 'ASSOCIATION':
      ExtensionSettings.setUseFileAssociation(lang, (value != '0' || value != ''));
      break;
   case 'AUTOVALIDATE' :
      index = find_index('def-autovalidate'lang, MISC_TYPE);
      if(value == ''){
         if (!index) return(0);
         delete_name(index);
      } else {
         if (!index) {
            index=insert_name('def-autovalidate-'lang, MISC_TYPE,value);
            if (!index) return(NOT_ENOUGH_MEMORY_RC);
         } else {
            set_name_info(index, value);
         }
      }
      break;
   case 'INHERIT':
      LanguageSettings.setLangInheritsFrom(lang, value);
      break;
   case 'ADAPTIVE-FLAGS':
      LanguageSettings.setAdaptiveFormattingFlags(lang, value);
      break;
   case 'ADAPTIVE-FORMATTING':
      LanguageSettings.setUseAdaptiveFormatting(lang, value);
      break;
   default:
      VS_LANGUAGE_SETUP_OPTIONS setup;
      if (_GetLanguageSetupOptions(lang,setup)) {
         index = insert_name('def-language-'lang,MISC_TYPE);
         if (!index) return(NOT_ENOUGH_MEMORY_RC);
         // Initialize the setup to fundamental mode.
         init_language(lang);
         _GetLanguageSetupOptions(lang,setup);
      }
      switch (field_name) {
      case 'P_MODE_NAME':
      case 'MN':
         setup.mode_name=value;
         break;
      case 'P_TABS':
      case 'TABS':
         setup.tabs=value;
         break;
      case 'P_MARGINS':
      case 'MA':
         setup.margins=value;
         break;
      case 'P_MODE_EVENTTAB':
      case 'KEYTAB':
         setup.keytab_name=value;
         break;
      case 'P_WORD_WRAP_STYLE':
      case 'WW':
         setup.word_wrap_style=value;
         break;
      case 'P_INDENT_WITH_TABS':
      case 'IWT':
         setup.indent_with_tabs=value;
         break;
      case 'P_SHOW_TABS':
      case 'ST':
         setup.show_tabs=value;
         break;
      case 'P_INDENT_STYLE':
      case 'IN':
         setup.indent_style=value;
         break;
      case 'P_WORD_CHARS':
      case 'WC':
         setup.word_chars=value;
         break;
      case 'P_LEXER_NAME':
      case 'LN':
         setup.lexer_name=value;
         break;
      case 'P_COLOR_FLAGS':
      case 'CF':
         setup.color_flags=value;
         break;
      case 'P_LINE_NUMBERS_LEN':
      case 'LNL':
         setup.line_numbers_len=value;
         break;
      case 'SW':
      case 'P_SOFTWRAP':
         setup.SoftWrap=value;
         break;
      case 'SOW':
      case 'P_SOFTWRAPONWORD':
         setup.SoftWrapOnWord=value;
         break;
      case 'HX':
      case 'P_HEXMODE':
         setup.hex_mode = value;
         break;
      case 'LNF':
         setup.line_numbers_flags = value;
         break;
      default:
         _message_box(field_name' is not a valid argument to _SetLanguageOption');
         return(STRING_NOT_FOUND_RC);
      }
      _SetLanguageSetupOptions(lang,setup);
      break;
   }
   _config_modify_flags(CFGMODIFY_DEFDATA);
   if (maybe_create_keytab && value!='') {
      index = find_index(value, EVENTTAB_TYPE);
      if (!index) {
         index = insert_name(value, EVENTTAB_TYPE);
         if (!index) return(NOT_ENOUGH_MEMORY_RC);
      }
   }
   return(0);
}

/**
 * Get the specified option stored for the given language. 
 * <p>
 * The options are stored per language mode. 
 * If the options are not yet defined for a language, 
 * then return <code>defaultValue</code> as the default. 
 *
 * @param lang    Language ID (see {@link p_LangId} 
 *                For list of languages, use our Language Manager dialog
 *                ("Tools", "Options...", "Language Manager").
 *
 * @param fieldName    may be one of the following:
 * <dl>
 * <dt>p_mode_name or MN</dt>          <dd>Specifies mode name.</dd> 
 * <dt>p_tabs or TABS</dt>             <dd>Specifies tab settings.</dd> 
 * <dt>p_margins or MA</dt>            <dd>Specifies margins.</dd> 
 * <dt>p_mode_eventtab or KEYTAB</dt>  <dd>Specifies mode event table.</dd> 
 * <dt>p_word_wrap_style or WW</dt>    <dd>Specifies word wrap style.</dd>
 * <dt>p_indent_with_tabs or IWT</dt>  <dd>Specifies indent with tabs.</dd> 
 * <dt>p_show_tabs or ST</dt>          <dd>Specifies to show tabs.</dd> 
 * <dt>p_indent_style or IN</dt>       <dd>Specifies indent style.</dd> 
 * <dt>p_word_chars or WC</dt>         <dd>Specifies word chaacters.</dd>
 * <dt>p_lexer_name or LN</dt>         <dd>Specifies lexer name.</dd> 
 * <dt>p_color_flags or CF</dt>        <dd>Specifies color flags.</dd>
 * <dt>p_line_numbers_len or LNL</dt>  <dd>Specifies line number area size</dd> 
 * <dt>p_softwrap or SW</dt>           <dd>Specifies soft wrap options</dd> 
 * <dt>p_softwraponword or SOW</dd>    <dd>Specifies soft wrap on word</dd>
 * </dl>
 * <p>
 * For the above options, <i>value</i> may not contain a comma character.
 * <p>
 * Additional <i>field_name</i> values:
 * <dl>
 * <dt>LANGUAGE</dt>                  <dd>General language setup data.</dd> 
 *                                         This option is very sensitive to the 
 *                                         order of the options.  We recommend 
 *                                         that you use macro recording to 
 *                                         correctly generate calls that set 
 *                                         this option.</dd>
 * <dt>ALIAS</dt>                      <dd>Language specific alias file</dd> 
 * <dt>SMARTPASTE</dt>                 <dd>Specifies Smart Paste(TM) options</dd> 
 * <dt>SMARTTAB</dt>                   <dd>Specifies tab expansion options</dd>
 * <dt>SMARTTAB</dt>                   <dd>Set the smart tab value for this 
 *                                         language, one of the following:
 *                                         <ul>
 *                                         <li> VSSMARTTAB_INDENT
 *                                         <li> VSSMARTTAB_MAYBE_REINDENT_STRICT
 *                                         <li> VSSMARTTAB_MAYBE_REINDENT
 *                                         <li> VSSMARTTAB_ALWAYS_REINDENT
 *                                         </ul>
 *                                     </dd>
 * <dt>BEGINEND</dt>                   <dd>Specifies begin/end pairs</dd> 
 * <dt>OPTIONS</dt>                    <dd>Specifies extension specific options.
 *                                         We recommend that you use macro 
 *                                         recording to correctly generate 
 *                                         calls that set this option.</dd>
 * <dt>NUMBERING</dt>                  <dd>Specifies line numbering options</dd> 
 * <dt>SURROUND</dt>                   <dd>Specifies dynamic surround flags</dd> 
 * <dt>AUTOCOMPLETE</dt>               <dd>Specifies auto-complete flags</dd> 
 * <dt>AUTOCOMPLETEMIN</dt>            <dd>Min word length for auto-complete</dd> 
 * <dt>SYMBOLCOLORING</dt>             <dd>Symbol Coloring option flags/dd> 
 * <dt>INDENT</dt>                     <dd>Indentation options</dd> 
 * <dt>CODEHELP</dt>                   <dd>Context Tagging option flags</dd> 
 * <dt>COMMENTEDITING</dt>             <dd>Comment editing option flags</dd> 
 * <dt>DOCCOMMENT</dt>                 <dd>Documentation comment options</dd> 
 * <dt>COMMENT-WRAP</dt>               <dd>Specifies comment wrap options</dd> 
 * <dt>XML-WRAP</dt>                   <dd>Specifies XML wrap options</dd> 
 * <dt>AUTOVALIDATE</dt>               <dd>Specifies XML validation options</dd> 
 * <dt>INHERIT</dt>                    <dd>Specifies parent language for
 *                                         tagging callback inheritance</dd> 
 * <dt>ADAPTIVE-FLAGS</dt>             <dd>Specifies adaptive flags</dd> 
 * <dt>ADAPTIVE-FORMATTING</dt>        <dd>Adaptive formatting flags</dd> 
 * </dl> 
 * <p>
 * The following additional <i>field_name</i> options are actually stored
 * per file extension rather than per language.
 * <dl>
 * <dt>LANG-FOR-EXT</dt>               <dd>Maps file extension to language</dd>
 * <dt>ENCODING</dt>                   <dd>Extension-specific encoding</dd> 
 * <dt>ASSOCIATION</dt>                <dd>Extension-specific open application</dd> 
 * </dl> 
 * 
 * @param defaultValue      Value to use if the option is not already set 
 *                          for this langauge.
 *  
 * @see _SetLanguageOption
 * @see _GetLanguageSetupOptions
 * @see _GetDefaultLanguageOptions
 * 
 * @categories Miscellaneous_Functions
 */
typeless _GetLanguageSpecificOption(_str lang, _str fieldName, typeless defaultValue=null)
{
   // make sure we have a valid language ID
   if (lang=='') {
      if (!_isEditorCtl()) return defaultValue;
      lang = p_LangId;
   }

   // now look up the stock field value
   int index = find_index('def-'lowcase(fieldName)'-'lang, MISC_TYPE);
   if (index > 0) return name_info(index);

   // special case for BEGINEND
   if (fieldName == "BEGINEND") {
      return LanguageSettings.getBeginEndPairs(lang, defaultValue);
   }

   // check if this is a language setup field
   switch (fieldName) {
   case 'P_MODE_NAME':
   case 'MN':
   case 'P_TABS':
   case 'TABS':
   case 'P_MARGINS':
   case 'MA':
   case 'P_MODE_EVENTTAB':
   case 'KEYTAB':
   case 'P_WORD_WRAP_STYLE':
   case 'WW':
   case 'P_INDENT_WITH_TABS':
   case 'IWT':
   case 'P_SHOW_TABS':
   case 'ST':
   case 'P_INDENT_STYLE':
   case 'IN':
   case 'P_WORD_CHARS':
   case 'WC':
   case 'P_LEXER_NAME':
   case 'LN':
   case 'P_COLOR_FLAGS':
   case 'CF':
   case 'P_LINE_NUMBERS_LEN':
   case 'LNL':
   case 'SW':
   case 'P_SOFTWRAP':
   case 'SOW':
   case 'P_SOFTWRAPONWORD':
   case 'HX':
   case 'P_HEXMODE':
   case 'LNF':
      break;
   default:
      // if not, assume the field is simply not set and return the default
      return defaultValue;
   }

   // get langauge setup information, if none is there, 
   // assume the default value
   VS_LANGUAGE_SETUP_OPTIONS setup;
   if (_GetLanguageSetupOptions(lang,setup)) {
      return defaultValue;
   }

   // finally, return the value
   switch (fieldName) {
   case 'P_MODE_NAME':
   case 'MN':
      return setup.mode_name;
   case 'P_TABS':
   case 'TABS':
      return setup.tabs;
   case 'P_MARGINS':
   case 'MA':
      return setup.margins;
   case 'P_MODE_EVENTTAB':
   case 'KEYTAB':
      return setup.keytab_name;
   case 'P_WORD_WRAP_STYLE':
   case 'WW':
      return setup.word_wrap_style;
   case 'P_INDENT_WITH_TABS':
   case 'IWT':
      return setup.indent_with_tabs;
   case 'P_SHOW_TABS':
   case 'ST':
      return setup.show_tabs;
   case 'P_INDENT_STYLE':
   case 'IN':
      return setup.indent_style;
   case 'P_WORD_CHARS':
   case 'WC':
      return setup.word_chars;
   case 'P_LEXER_NAME':
   case 'LN':
      return setup.lexer_name;
   case 'P_COLOR_FLAGS':
   case 'CF':
      return setup.color_flags;
   case 'P_LINE_NUMBERS_LEN':
   case 'LNL':
      return setup.line_numbers_len;
   case 'SW':
   case 'P_SOFTWRAP':
      return setup.SoftWrap;
   case 'SOW':
   case 'P_SOFTWRAPONWORD':
      return setup.SoftWrapOnWord;
   case 'HX':
   case 'P_HEXMODE':
      return setup.hex_mode;
   case 'LNF':
      return setup.line_numbers_flags;
   default:
      return defaultValue;
   }
}

/**
 * Gets the default list of updates to be used when we call _update_buffers with 
 * no parameters. 
 * 
 * @param lang                language we want to update
 * 
 * @return _str               default list of updates
 */
_str _get_default_update_list(_str lang)
{
   index := find_index('def-language-'lang, MISC_TYPE);
   updates := name_info(index);

   return updates;
}

/**
 * Builds a hash table of buffer updates (field names => values) to be used when 
 * we call _update_buffers_from_table. 
 * 
 * @param updateList             comma-delimited list of updates
 * @param updateTable            hash table of updates
 */
void _build_update_table_from_list(_str updateList, typeless (&updateTable):[])
{
   _str key, value;
   for (;;) {
      parse updateList with key '=' value ',' updateList ;
      if (key == '') break;

      key = upcase(key);
      updateTable:[key] = value;
   }
}

/**
 * Updates language specific options you specify for all open files. 
 *  
 * This function takes a hash table of field/value pairs.  To use the 
 * old style string function, you can still call _update_buffers, which
 * will in term call this function.  This function was added because 
 * the desire to include commas in values, which is not possible in a 
 * comma-delimited string. 
 *  
 * @param lang    Language ID (see {@link p_LangId} 
 *  
 * @param updateTable   A hashtable of fieldName => values.  Each field
 *                      name corresponds to a buffer property which
 *                      will be set with the associated value.
 *                      Examples of field names are <FIELD>_UPDATE_KEY.
 * 
 * 
 * @see _update_buffers
 * 
 * @categories Buffer_Functions
 */ 
void _update_buffers_from_table(_str lang, typeless (&updateTable):[] = null)
{
   if (lang == '') return;

   if (updateTable == null) {
      updateList := _get_default_update_list(lang);
      _build_update_table_from_list(updateList, updateTable);
   }

   validate_update_keys_and_data(updateTable);

   update_ad_form_flags := updateTable._indexin(TABS_UPDATE_KEY) ||
                           updateTable._indexin(INDENT_WITH_TABS_UPDATE_KEY) ||
                           updateTable._indexin(BEGIN_END_STYLE_UPDATE_KEY) ||
                           updateTable._indexin(NO_SPACE_BEFORE_PAREN_UPDATE_KEY) ||
                           updateTable._indexin(INDENT_CASE_FROM_SWITCH_UPDATE_KEY) ||
                           updateTable._indexin(PAD_PARENS_UPDATE_KEY) ||
                           updateTable._indexin(KEYWORD_CASING_UPDATE_KEY) ||
                           updateTable._indexin(TAG_CASING_UPDATE_KEY) ||
                           updateTable._indexin(ATTRIBUTE_CASING_UPDATE_KEY) ||
                           updateTable._indexin(VALUE_CASING_UPDATE_KEY) ||
                           updateTable._indexin(HEX_VALUE_CASING_UPDATE_KEY) ||
                           updateTable._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY) ||
                           updateTable._indexin(SYNTAX_INDENT_UPDATE_KEY);

   // we need to make sure these settings are appropriate for ISPF emulation
   if (updateTable._indexin(LINE_NUMBERS_FLAGS_UPDATE_KEY)) {

      // if we are not also currently turning on the line numbers length,
      // we need to get that info
      if (!updateTable._indexin(LINE_NUMBERS_LEN_UPDATE_KEY)) {
         updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY] = LanguageSettings.getLineNumbersLength(lang);;
      }

      lnf := (int)updateTable:[LINE_NUMBERS_FLAGS_UPDATE_KEY];
      lnl := (int)updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY];
      checkLineNumbersLengthForISPF(lnf, lnl);
      updateTable:[LINE_NUMBERS_FLAGS_UPDATE_KEY] = lnf;
      updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY] = lnl;

   } else if (updateTable._indexin(LINE_NUMBERS_LEN_UPDATE_KEY)) {
      lnl := (int)updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY];
      checkLineNumbersLengthForISPF(0, lnl);
      updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY] = lnl;
   }

   // if we are not updating the color flags, we might need to
   // update them anyway because of a lexer name change
   if (updateTable._indexin(LEXER_NAME_UPDATE_KEY) && !updateTable._indexin(COLOR_FLAGS_UPDATE_KEY)) {
      colorFlags := LanguageSettings.getColorFlags(lang);
      updateTable:[COLOR_FLAGS_UPDATE_KEY] = colorFlags;
   }

   // might need to do some special adaptive formatting stuff
   adaptiveFlags := adaptive_format_get_buffer_flags(lang);
   if (update_ad_form_flags) {
      // clear the embedded settings if we are changing anything that might affect adaptive formatting
      adaptive_format_clear_embedded(lang);

      if (!updateTable._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY)) {
         // we have to reset the adaptive formatting settings, but we need to retrieve the flags
         updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY] = adaptiveFlags;
      }
   }

   // do we update the indent settings in each buffer right now? - only if tabs are on and 
   // we have cleared the settings that we found
   // we want to update tabs NOW, otherwise, they will be typing along and suddenly the file
   // change appearance, and that is bad.
   update_ad_form_now := update_ad_form_flags && adaptive_format_is_flag_on_for_buffer(AFF_TABS, lang, adaptiveFlags); 

   typeless found_match=0;
   _safe_hidden_window();
   int view_id=0;
   save_view(view_id);
   int first_buf_id=p_buf_id;

   int displayProgressCount=0;
   int progressWid=0;

   for (;;) {

      // we have to call this so that the form gets painted
      // we don't want to do anything with it because we don't even have a cancel button
      if (update_ad_form_now) {
         cancel_form_cancelled();
      }

      // Need to be able to set the extension options for a buffer
      // that has tagging disabled.  p_LangId==NotSupported_asm390
      _str supportedLang = _getSupportedLangId(p_LangId);
      found_match = (lang == supportedLang);

      if (found_match) {

         if (updateTable._indexin(LEXER_NAME_UPDATE_KEY)) {
            lexerName := updateTable:[LEXER_NAME_UPDATE_KEY];
            if (!strieq(p_lexer_name, lexerName)) {
               p_lexer_name = lexerName;
            }
         }

         if (updateTable._indexin(COLOR_FLAGS_UPDATE_KEY)) p_color_flags = updateTable:[COLOR_FLAGS_UPDATE_KEY];
         if (updateTable._indexin(LINE_NUMBERS_LEN_UPDATE_KEY)) p_line_numbers_len = updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY];
         if (updateTable._indexin(LINE_NUMBERS_FLAGS_UPDATE_KEY)) {
            if (updateTable:[LINE_NUMBERS_FLAGS_UPDATE_KEY] & LNF_ON) {

               p_line_numbers_len = updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY];

               // we are turning them on
               if (updateTable:[LINE_NUMBERS_FLAGS_UPDATE_KEY] & LNF_AUTOMATIC) {
                  // we want automatic mode...
                  p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS;
                  p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS_AUTO;
               } else {
                  p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS_AUTO;
                  p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
               }
            } else {
               // we're turning line numbers off
               p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
            }
         }

         if (updateTable._indexin(TRUNCATE_LENGTH_UPDATE_KEY)) {

            truncateLength := updateTable:[TRUNCATE_LENGTH_UPDATE_KEY];
            if (truncateLength >= 0) {
               p_TruncateLength = truncateLength;
            } else {
               truncateLength = p_MaxLineLength - 8;
               if (truncateLength >= 2) {
                  p_TruncateLength = truncateLength;
               }
            }
         }

         if (updateTable._indexin(BOUNDS_UPDATE_KEY)) {
            typeless boundsStart = "", boundsEnd = "";
            parse updateTable:[BOUNDS_UPDATE_KEY] with boundsStart boundsEnd .;
            if (!isinteger(boundsStart) || !isinteger(boundsEnd) || boundsStart <= 0)  {
               if (p_TruncateLength) {
                  p_BoundsStart = 1;
                  p_BoundsEnd = p_TruncateLength;
               } else {
                  p_BoundsStart = 0;
                  p_BoundsEnd = 0;
               }
            } else {
               p_BoundsStart = boundsStart;
               p_BoundsEnd = boundsEnd;
            }
            // this is only callable if ispf has been loaded
            if (index_callable(find_index('ispf_adjust_lc_bounds', PROC_TYPE))) {
               ispf_adjust_lc_bounds();
            }
         }

         if (updateTable._indexin(CAPS_UPDATE_KEY)) p_caps = updateTable:[CAPS_UPDATE_KEY];
         if (updateTable._indexin(SOFT_WRAP_UPDATE_KEY)) p_SoftWrap = updateTable:[SOFT_WRAP_UPDATE_KEY];
         if (updateTable._indexin(SOFT_WRAP_ON_WORD_UPDATE_KEY)) p_SoftWrapOnWord = updateTable:[SOFT_WRAP_ON_WORD_UPDATE_KEY];
         if (updateTable._indexin(HEX_MODE_UPDATE_KEY)) p_hex_mode = updateTable:[HEX_MODE_UPDATE_KEY];
         if (updateTable._indexin(SHOW_SPECIAL_CHARS_UPDATE_KEY)) p_ShowSpecialChars = updateTable:[SHOW_SPECIAL_CHARS_UPDATE_KEY];

         if ( ! read_format_line() ) {
            if (updateTable._indexin(TABS_UPDATE_KEY)) p_tabs = updateTable:[TABS_UPDATE_KEY];
            if (updateTable._indexin(MARGINS_UPDATE_KEY)) p_margins = updateTable:[MARGINS_UPDATE_KEY];
            if (updateTable._indexin(WORD_WRAP_UPDATE_KEY)) p_word_wrap_style = updateTable:[WORD_WRAP_UPDATE_KEY];
            if (updateTable._indexin(INDENT_WITH_TABS_UPDATE_KEY)) p_indent_with_tabs = updateTable:[INDENT_WITH_TABS_UPDATE_KEY];
            if (updateTable._indexin(SHOW_TABS_UPDATE_KEY)) p_show_tabs = updateTable:[SHOW_TABS_UPDATE_KEY];
            if (updateTable._indexin(INDENT_STYLE_UPDATE_KEY)) p_indent_style = updateTable:[INDENT_STYLE_UPDATE_KEY];
            if (updateTable._indexin(WORD_CHARS_UPDATE_KEY)) p_word_chars = updateTable:[WORD_CHARS_UPDATE_KEY];
         }

         if (updateTable._indexin(MODE_NAME_UPDATE_KEY) && !p_readonly_mode) {
            p_mode_name = updateTable:[MODE_NAME_UPDATE_KEY];
            p_LangId=_Modename2LangId(p_mode_name);
         }
         if (updateTable._indexin(KEY_TABLE_UPDATE_KEY)) {
            index := find_index(updateTable:[KEY_TABLE_UPDATE_KEY], EVENTTAB_TYPE);
            if (index) {
               p_mode_eventtab = index;
            } else {
               p_mode_eventtab = _default_keys;
            }
         }

         if (updateTable._indexin(BEGIN_END_STYLE_UPDATE_KEY)) p_begin_end_style = updateTable:[BEGIN_END_STYLE_UPDATE_KEY];
         if (updateTable._indexin(NO_SPACE_BEFORE_PAREN_UPDATE_KEY)) p_no_space_before_paren = updateTable:[NO_SPACE_BEFORE_PAREN_UPDATE_KEY];
         if (updateTable._indexin(INDENT_CASE_FROM_SWITCH_UPDATE_KEY)) p_indent_case_from_switch = updateTable:[INDENT_CASE_FROM_SWITCH_UPDATE_KEY];
         if (updateTable._indexin(PAD_PARENS_UPDATE_KEY)) p_pad_parens = updateTable:[PAD_PARENS_UPDATE_KEY];
         if (updateTable._indexin(POINTER_STYLE_UPDATE_KEY)) p_pointer_style = updateTable:[POINTER_STYLE_UPDATE_KEY];
         if (updateTable._indexin(FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY)) p_function_brace_on_new_line = updateTable:[FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY];
         if (updateTable._indexin(KEYWORD_CASING_UPDATE_KEY)) p_keyword_casing = updateTable:[KEYWORD_CASING_UPDATE_KEY];
         if (updateTable._indexin(TAG_CASING_UPDATE_KEY)) p_tag_casing = updateTable:[TAG_CASING_UPDATE_KEY];
         if (updateTable._indexin(ATTRIBUTE_CASING_UPDATE_KEY)) p_attribute_casing = updateTable:[ATTRIBUTE_CASING_UPDATE_KEY];
         if (updateTable._indexin(VALUE_CASING_UPDATE_KEY)) p_value_casing = updateTable:[VALUE_CASING_UPDATE_KEY];
         if (updateTable._indexin(HEX_VALUE_CASING_UPDATE_KEY)) p_hex_value_casing = updateTable:[HEX_VALUE_CASING_UPDATE_KEY];

         // we update this if the flags changed
         // we also reset it when any of the values have changed
         if (updateTable._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY) || update_ad_form_flags) {
            p_adaptive_formatting_flags = updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY];
         }

         if (updateTable._indexin(SYNTAX_INDENT_UPDATE_KEY)) {
            p_SyntaxIndent = updateTable:[SYNTAX_INDENT_UPDATE_KEY];
         } else {
            // go ahead and set the syntax indent to the default
            p_SyntaxIndent = LanguageSettings.getSyntaxIndent(lang);
         }
         if (update_ad_form_now) {
            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS, false);
            ++displayProgressCount;
            if (!progressWid && displayProgressCount>=30) {
               if (update_ad_form_now) {
                  progressWid = show_cancel_form("Updating settings", null, false);
               }
            }
            if (progressWid) {
               cancel_form_set_labels(progressWid, "Updating "p_buf_name" with new settings...");
            }
         }
      }
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   if (update_ad_form_now && progressWid) {
      close_cancel_form(progressWid);
   }
   activate_window(view_id);
}

/**
 * Makes sure that keys sent to _update_buffers are uniform and that data is 
 * valid. 
 * 
 * @param updateTable            hashtable of field => values
 */
static void validate_update_keys_and_data(typeless (&updateTable):[])
{
   _str oldTable:[] = updateTable;
   updateTable._makeempty();

   _str key, value;
   foreach (key => value in oldTable) {
      newKey := get_update_key(key);
      newValue := validate_update_data(newKey, value);

      if (newValue != null) {
         updateTable:[newKey] = newValue;
      }
   }
}

/**
 * Retrieves the uniform UPDATE_KEY used by _update_buffers.  Previously, we 
 * allowed multiple keys to reference the same field.  We want to use a uniform 
 * set of keys so we don't have to check a bunch of different fields. 
 * 
 * @param key                    key used in table
 * 
 * @return _str                  uniform key that refers to the same field (may 
 *                               be the same as parameter)
 */
static _str get_update_key(_str key)
{
   unifiedKey := key;
   
   switch (upcase(key)) {
   case MODE_NAME_SHORT_KEY:
      unifiedKey = MODE_NAME_UPDATE_KEY;
      break;
   case TABS_SHORT_KEY:
      unifiedKey = TABS_UPDATE_KEY;
      break;
   case MARGINS_SHORT_KEY:
      unifiedKey = MARGINS_UPDATE_KEY;
      break;
   case KEY_TABLE_SHORT_KEY:
      unifiedKey = KEY_TABLE_UPDATE_KEY;
      break;
   case WORD_WRAP_SHORT_KEY:
      unifiedKey = WORD_WRAP_UPDATE_KEY;
      break;
   case INDENT_WITH_TABS_SHORT_KEY:
      unifiedKey = INDENT_WITH_TABS_UPDATE_KEY;
      break;
   case SHOW_TABS_SHORT_KEY:
      unifiedKey = SHOW_TABS_UPDATE_KEY;
      break;
   case INDENT_STYLE_SHORT_KEY:
      unifiedKey = INDENT_STYLE_UPDATE_KEY;
      break;
   case WORD_CHARS_SHORT_KEY:
      unifiedKey = WORD_CHARS_UPDATE_KEY;
      break;
   case LEXER_NAME_SHORT_KEY:
      unifiedKey = LEXER_NAME_UPDATE_KEY;
      break;
   case COLOR_FLAGS_SHORT_KEY:
      unifiedKey = COLOR_FLAGS_UPDATE_KEY;
      break;
   case LINE_NUMBERS_LEN_SHORT_KEY:
      unifiedKey = LINE_NUMBERS_LEN_UPDATE_KEY;
      break;
   case TRUNCATE_LENGTH_SHORT_KEY:
      unifiedKey = TRUNCATE_LENGTH_UPDATE_KEY;
      break;
   case SOFT_WRAP_SHORT_KEY:
      unifiedKey = SOFT_WRAP_UPDATE_KEY;
      break;
   case SOFT_WRAP_ON_WORD_SHORT_KEY:
      unifiedKey = SOFT_WRAP_ON_WORD_UPDATE_KEY;
      break;
   case HEX_MODE_SHORT_KEY:
      unifiedKey = HEX_MODE_UPDATE_KEY;
      break;
   }

   return unifiedKey;
}

/**
 * Makes sure the data being passed to _update_buffers is valid for each 
 * individual field. 
 * 
 * @param key                 update key (see <FIELD>_UPDATE_KEY in 
 *                            LanguageSettings.sh)
 * @param value               value to be validated
 * 
 * @return typeless           the "new" value - may be changed to a different 
 *                            type or set to null if the value was not valid for
 *                            the field
 */
static typeless validate_update_data(_str key, typeless value)
{
   typeless newValue = null;
   switch (key) {
   case COLOR_FLAGS_UPDATE_KEY:
   case LINE_NUMBERS_LEN_UPDATE_KEY:
   case HEX_MODE_UPDATE_KEY:
   case LINE_NUMBERS_FLAGS_UPDATE_KEY:
   case SHOW_SPECIAL_CHARS_UPDATE_KEY:
   case WORD_WRAP_UPDATE_KEY:
   case INDENT_WITH_TABS_UPDATE_KEY:
   case SHOW_TABS_UPDATE_KEY: 
   case INDENT_STYLE_UPDATE_KEY:
   case BEGIN_END_STYLE_UPDATE_KEY:
   case POINTER_STYLE_UPDATE_KEY:
   case KEYWORD_CASING_UPDATE_KEY:
   case TAG_CASING_UPDATE_KEY:
   case ATTRIBUTE_CASING_UPDATE_KEY:
   case VALUE_CASING_UPDATE_KEY:
   case HEX_VALUE_CASING_UPDATE_KEY:
   case ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY:
   case SYNTAX_INDENT_UPDATE_KEY:
      // these are just plain integers - if they're not, we don't want them at all
      if (isinteger(value)) {
         newValue = (int)value;
      } 
      break;
   case SOFT_WRAP_UPDATE_KEY:
   case SOFT_WRAP_ON_WORD_UPDATE_KEY:
   case NO_SPACE_BEFORE_PAREN_UPDATE_KEY:
   case INDENT_CASE_FROM_SWITCH_UPDATE_KEY:
   case PAD_PARENS_UPDATE_KEY:
   case FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY:
      // these are bools pretending to be integers
      if (isinteger(value)) {
         newValue = (value != 0);
      } 
      break;
   case TRUNCATE_LENGTH_UPDATE_KEY:
      if (isinteger(value)) {
         newValue = (int)value;
      } else {
         newValue = 0;
      }
      break;
   case CAPS_UPDATE_KEY:
      if (!isinteger(value)) {
         value = CM_CAPS_OFF;
      } 

      if (value == CM_CAPS_AUTO) {
         newValue = (_GetCaps() != 0);
      } else {
         newValue = (value != 0);
      }

      break;
   case WORD_CHARS_UPDATE_KEY:
      // we don't want to allow this placeholder value
      if (value != WORD_CHARS_NOT_APPLICABLE) {
         newValue = value;
      }
      break;
   default:
      newValue = value;
   }

   return newValue;
}

/**
 * Updates language specific options you specify for all open files. 
 *  
 * This function takes either a string or a hash table of field/value 
 * pairs. To use the old style string function, you can still call 
 * this function.  The ability to use a hash table was added because of 
 * the desire to include commas in values, which is not possible in a 
 * comma-delimited string. 
 *  
 * This function does not change the default language specific options. 
 * Use {@link _SetLanguageOption}, {@link _SetLanguageSetupOptions}, 
 * {@link _SetDefaultLanguageOptions} function, or the LanguageSettings
 * API to change language specific defaults. 
 * 
 * @param lang    Language ID (see {@link p_LangId} 
 *  
 * @param updates       Either a hashtable of fieldName => values or a 
 *                      string of format "fieldName=value','...". Each
 *                      field name corresponds to a buffer property
 *                      which will be set with the associated value.
 *                      Examples of field names are <FIELD>_UPDATE_KEY.
 * 
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    //Change the default margins for fundamental mode.
 *    LanguageSettings.setMargins("fundamental", "1 70 1");
 *
 *    // Update buffers already being edited - using a string
 *     _update_buffers("fundamental", MARGINS_UPDATE_KEY"=1 70 1");
 *
 *    // Update buffers using a hash table
 *    _str table:[];
 *    table:[MARGINS_UPDATE_KEY] = "1 70 1";
 *     _update_buffers("fundamental", table);
 * }
 * </pre>
 * 
 * @see _SetLanguageOption 
 * @see _SetDefaultLanguageOptions 
 * @see _SetLanguageSetupOptions 
 * 
 * @categories Buffer_Functions
 */ 
void _update_buffers(_str lang, typeless updates = null)
{
   if ( lang=='' ) return;

   // changed a language or extension option, so clear cache
   _ClearDefaultLanguageOptionsCache();

   typename := updates._typename();
   switch (typename) {
   case '_str':
      // this is a string, though it might be empty
      typeless updateTable:[];
      if (updates == "") {
         updates = _get_default_update_list(lang);
      }
      _build_update_table_from_list(updates, updateTable);
      _update_buffers_from_table(lang, updateTable);
      break;
   case ':[]':
   case 'null':
      _update_buffers_from_table(lang, updates);
      break;
   }
}

/** 
 * Update the language mode for buffers with the given file extension. 
 * This function is used for updating buffers after changes have been 
 * made to the file extension mappings in the File Extension Manager. 
 *  
 * @param ext     Physical file extension 
 * @param lang    Language ID (see {@link p_LangId} 
 *  
 * @see _CreateExtension 
 * @see _update_buffers 
 * 
 * @categories Buffer_Functions
 */ 
void _update_buffers_for_ext(_str ext, _str lang="")
{
   // map extension if lang was not given explicitely
   if (lang == "") {
      lang = _Ext2LangId(ext);
   }

   // switch to hidden editor window
   get_window_id(auto orig_wid);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();

   // for each buffer
   first_buf_id := p_buf_id;
   for (;;) {

      // if the extension matches and the language doesn't
      bufext := _get_extension(p_buf_name);
      if (file_eq(bufext,ext) && p_LangId != lang) {
         // switch language modes
         _SetEditorLanguage(lang);
      }

      // next please
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }

   // restore original window id
   activate_window(orig_wid);
}

/**
 * Don't use this helper function again.
 * 
 * @deprecated Use {@link _Ext2LangId()}
 * 
 * @return _str 
 */
_str _check_newext(_str ext, int wid)
{
   return(0);
}

static void add_default_language(_str lang)
{
   // There was no support for this module
   // Add a few options to make this more programmer-friendly -- DJB 2/9/2000
   // Turn off color current line.  This is annoying if you add a color coding
   // lexer.
   _SetLanguageSetupDefaults(lang);

   // add this extension to the extension list
   lang = _file_case(lang);
   _extension._lbadd_item(lang);
   //init_ext(ext);

   // set up the default options string
   int options_index=find_index('def-options-'lang,MISC_TYPE);
   _str syntax_info=DEFAULT_SYNTAX_INFO;
   if (!options_index) {
      options_index=insert_name('def-options-'lang,MISC_TYPE,syntax_info);
   } else {
      set_name_info(options_index,syntax_info);
   }

   // language settings changed, so clear cache
   _ClearDefaultLanguageOptionsCache();
}

static void init_language(_str lang)
{
   int new_index = find_index('def-language-'lang, MISC_TYPE);
   if (!new_index) {
      return;
   }
   int index = find_index('def-language-fundamental', MISC_TYPE);
   _str info = name_info(index);
   _str mode_name="", rest="";
   parse info with 'MN=' mode_name ',' rest ;
   info = 'MN=,' rest;
   set_name_info(new_index, info);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   // language settings changed, so clear cache
   _ClearDefaultLanguageOptionsCache();
}
/* End Extension Options form*/

defeventtab _add_language_form;

#define CREATE_LEXER_TEXT "<Create new lexer>"

_str _GenerateLangIdFromModeName(_str modename)
{
   // first remove all spaces
   langId := stranslate(modename, '', ' ');

   // go to lowercase
   langId = lowcase(langId);

   // check for non alphanumerics
   if (pos('[~A-Za-z0-9_]', langId, 1, 'R')) {
      // translate everything
      // + -> p
      langId = stranslate(langId, 'p', '+');
      // - -> m
      langId = stranslate(langId, 'm', '-');
      // ! -> bang
      langId = stranslate(langId, 'bang', '!');
      // @ -> at
      langId = stranslate(langId, 'at', '@');
      // # -> s
      langId = stranslate(langId, 's', '#');
      // $ -> d
      langId = stranslate(langId, 'd', '$');
      // % -> per
      langId = stranslate(langId, 'per', '%');
      // ^ -> caret
      langId = stranslate(langId, 'caret', '^');
      // & -> and
      langId = stranslate(langId, 'and', '&');
      // * -> splat
      langId = stranslate(langId, 'splat', '*');
      // blank out anything else
      langId = stranslate(langId, '', '[~A-Za-z0-9_]', 'R');
   }

   // our last resort - if it still matches something, we just add a # to it
   count := 2;
   tempId := langId;
   while (_LangId2Modename(tempId) != '') {
      tempId = langId :+ count;
      ++count;
   }
   langId = tempId;

   // this is good to go
   return langId;
}

void _ctl_add.on_create()
{
   // load lexer names into combo box
   _lexer_name.FillInLexerNameList();
   _lexer_name._lbadd_item(CREATE_LEXER_TEXT);
   _lexer_name._lbsort('i');
   _lexer_name._lbtop();
   _lexer_name._lbselect_line();

   // load the languages in the combo box
   _ctl_lang_combo._lbclear();
   _ctl_lang_combo.get_all_mode_names();
   _ctl_lang_combo._lbsort();
   _ctl_lang_combo._lbtop();
   _ctl_lang_combo.p_text = _ctl_lang_combo._lbget_text();
}

void _ctl_add.lbutton_up()
{
   // check that the mode name doesn't already exist
   modeName := strip(_ctl_mode_name.p_text);
   extensions := strip(_ctl_extensions.p_text);

   if (modeName == '' || extensions == '') {
      _message_box('Please specify a mode name and at least one extension for this language.');
      return;
   }

   if (_Modename2LangId(modeName) != '') {
      _message_box('The mode 'modeName' already exists.  Please specify a unique mode name for this language.');
      return;
   }

   if (pos(',', modeName)) {
      _message_box('Mode names may not contain commas.');
      return;
   }

   // go through extensions and see if they point to other things
   _str extList[];
   split(extensions, ' ', extList);
   int i;
   atLeastOne := false;
   for (i = 0; i < extList._length(); i++) {
      ext := strip(extList[i]);
      currentMode := _LangId2Modename(_Ext2LangId(ext));
      if (currentMode != '') {
         ret := _message_box('The extension 'ext' currently is associated with 'currentMode'.  ':+
                             'Would you like to overwrite this setting?', "Overwrite extension", 
                             MB_YESNO | MB_ICONQUESTION);
         if (ret == IDNO) {
            extList[i] = '';
         } else {
            extList[i] = ext;
            atLeastOne = true;
         }
      } else {
         atLeastOne = true;
      }
   }

   if (!atLeastOne) {
      _ctl_extensions.p_text = '';
      return;
   }

   // generate our lang id
   langId := _GenerateLangIdFromModeName(modeName);

   // add the new lang id
   _SetLanguageSetupDefaults(modeName, langId);

   // set the lexer
   lexerName := _lexer_name.p_text;
   if (lexerName == CREATE_LEXER_TEXT) {
      // create a new lexer using this mode name
      addNewBlankLexer(modeName);
      lexerName = modeName;
      set_refresh_lexer_list();
   } 

   if (lexerName != '') LanguageSettings.setLexerName(langId, lexerName);

   // set up the default options string
   optionsIndex := find_index('def-options-'langId, MISC_TYPE);
   syntaxInfo := DEFAULT_SYNTAX_INFO;
   if (!optionsIndex) {
      optionsIndex = insert_name('def-options-'langId, MISC_TYPE, syntaxInfo);
   } else {
      set_name_info(optionsIndex, syntaxInfo);
   }

   // add the extensions which refer to this language
   for (i = 0; i < extList._length(); i++) {
      if (extList[i] != '') {
         _SetExtensionReferTo(extList[i], langId);
      }
   }

   copyLanguageSettings(langId);

   _config_modify_flags(CFGMODIFY_DEFDATA);

   p_active_form._delete_window(modeName);

   // make the change in xml
   addNewLanguageToOptionsXML(langId);
}

void _lexer_name.on_change(int reason)
{
   _ctl_color_coding.p_enabled = (_lexer_name.p_text == '' && _ctl_copy_settings.p_value != 0);
}

void _ctl_copy_settings.LBUTTON_UP()
{
   enabled := (_ctl_copy_settings.p_value != 0);
   _ctl_lang_combo.p_enabled = _ctl_general.p_enabled = _ctl_indent.p_enabled = _ctl_view.p_enabled = 
      _ctl_word_wrap.p_enabled = _ctl_aliases.p_enabled = _ctl_comments.p_enabled = _ctl_autocomplete.p_enabled =
      _ctl_file_options.p_enabled = _ctl_keybindings.p_enabled = enabled;

   _ctl_adaptive_formatting.p_enabled = _ctl_tagging.p_enabled = enabled && _ctl_keybindings.p_value;
   _ctl_color_coding.p_enabled = enabled && (_lexer_name.p_text == '');
}

void _ctl_keybindings.LBUTTON_UP()
{
   _ctl_adaptive_formatting.p_enabled = _ctl_tagging.p_enabled = (_ctl_keybindings.p_value != 0);
}

void copyLanguageSettings(_str destLang)
{
   if (_ctl_copy_settings.p_value) {

      srcLang := _ctl_lang_combo.p_text;
      srcLang = _Modename2LangId(srcLang);

      if (_ctl_general.p_value) _copy_language_general_settings(srcLang, destLang);
      if (_ctl_indent.p_value) _copy_language_indent_settings(srcLang, destLang);
      if (_ctl_view.p_value) _copy_language_view_settings(srcLang, destLang);
      if (_ctl_word_wrap.p_value) _copy_language_word_wrap_settings(srcLang, destLang);
      if (_ctl_aliases.p_value) _copy_language_aliases(srcLang, destLang);
      if (_ctl_comments.p_value) _copy_language_comments_settings(srcLang, destLang);
      if (_ctl_color_coding.p_value) _copy_language_color_coding(srcLang, destLang);
      if (_ctl_autocomplete.p_value) _copy_language_autocomplete_settings(srcLang, destLang);
      if (_ctl_file_options.p_value) _copy_language_file_options(srcLang, destLang);
      if (_ctl_keybindings.p_value) {
         _copy_language_keytable(srcLang, destLang);
         _copy_language_inheritance(srcLang, destLang);
         if (_ctl_adaptive_formatting.p_value) _copy_language_adaptive_formatting_settings(srcLang, destLang);
         if (_ctl_tagging.p_value) _copy_language_tagging_settings(srcLang, destLang);
      }
   }

}

boolean _CopyLanguageOption(_str srcLang, _str destLang, _str fieldName)
{
   srcIndex := find_index('def-'fieldName'-'srcLang, MISC_TYPE);
   if (srcIndex) {
      info := name_info(srcIndex);

      destIndex := find_index('def-'fieldName'-'destLang, MISC_TYPE);
      if (!destIndex) {
         destIndex = insert_name('def-'fieldName'-'destLang, MISC_TYPE, info);
         if (!destIndex) return false;
      } else {
         set_name_info(destIndex, info);
      }
   } 

   return true;
}

/**
 * Copies the options found at Language > General from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_general_settings(_str srcLang, _str destLang)
{  
   VS_LANGUAGE_SETUP_OPTIONS srcSetup;
   VS_LANGUAGE_SETUP_OPTIONS destSetup;
   LanguageSettings.getLanguageDefinitionOptions(srcLang, srcSetup);
   LanguageSettings.getLanguageDefinitionOptions(destLang, destSetup);
   
   destSetup.TruncateLength = srcSetup.TruncateLength;
   destSetup.bounds = srcSetup.bounds;
   destSetup.caps = srcSetup.caps;
   destSetup.word_chars = srcSetup.word_chars;
     
   LanguageSettings.setLanguageDefinitionOptions(destLang, destSetup);
 
   return _CopyLanguageOption(srcLang, destLang, 'menu') && 
      _CopyLanguageOption(srcLang, destLang, 'begin-end');
}

/**
 * Copies the options found at Language > Indent from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_indent_settings(_str srcLang, _str destLang)
{
   VS_LANGUAGE_OPTIONS srcLangInfo;
   VS_LANGUAGE_OPTIONS destLangInfo;
   LanguageSettings.getAllLanguageOptions(srcLang, srcLangInfo);
   LanguageSettings.getAllLanguageOptions(destLang, destLangInfo);
   
   destLangInfo.szTabs = srcLangInfo.szTabs;
   destLangInfo.IndentWithTabs = srcLangInfo.IndentWithTabs;
   destLangInfo.IndentStyle = srcLangInfo.IndentStyle;
   destLangInfo.szEventTableName = srcLangInfo.szEventTableName;
   destLangInfo.SyntaxExpansion = srcLangInfo.SyntaxExpansion;
   destLangInfo.SyntaxIndent = srcLangInfo.SyntaxIndent;
   destLangInfo.minAbbrev = srcLangInfo.minAbbrev;
   
   LanguageSettings.setAllLanguageOptions(destLang, destLangInfo);

   return _CopyLanguageOption(srcLang, destLang, 'indent') &&
      _CopyLanguageOption(srcLang, destLang, 'smartpaste') &&
      _CopyLanguageOption(srcLang, destLang, 'surround') &&
      _CopyLanguageOption(srcLang, destLang, 'smarttab');
   
}

/**
 * Copies the options found at Language > View from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_view_settings(_str srcLang, _str destLang)
{
   
   VS_LANGUAGE_SETUP_OPTIONS srcSetup;
   VS_LANGUAGE_SETUP_OPTIONS destSetup;
   LanguageSettings.getLanguageDefinitionOptions(srcLang, srcSetup);
   LanguageSettings.getLanguageDefinitionOptions(destLang, destSetup);

   destSetup.show_tabs = srcSetup.show_tabs;
   destSetup.line_numbers_len = srcSetup.line_numbers_len;
   destSetup.line_numbers_flags = srcSetup.line_numbers_flags;
   destSetup.hex_mode = srcSetup.hex_mode;
   destSetup.color_flags = srcSetup.color_flags;            // modified lines and current line
   
   LanguageSettings.setLanguageDefinitionOptions(destLang, destSetup);

   // symbol coloring stuff
   srcSCOptions := _GetSymbolColoringOptions(srcLang);
   _SetSymbolColoringOptions(destLang, srcSCOptions);
   SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme,true);

   return true;
}

/**
 * Copies the options found at Language > Word Wrap from one language to 
 * another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_word_wrap_settings(_str srcLang, _str destLang)
{
   VS_LANGUAGE_SETUP_OPTIONS srcSetup;
   VS_LANGUAGE_SETUP_OPTIONS destSetup;
   LanguageSettings.getLanguageDefinitionOptions(srcLang, srcSetup);
   LanguageSettings.getLanguageDefinitionOptions(destLang, destSetup);
   
   destSetup.SoftWrap = srcSetup.SoftWrap;
   destSetup.SoftWrapOnWord = srcSetup.SoftWrapOnWord;
   destSetup.margins = srcSetup.margins;
   destSetup.word_wrap_style = srcSetup.word_wrap_style;

   LanguageSettings.setLanguageDefinitionOptions(destLang, destSetup);
   
   return true;
}

/**
 * Copies the options found at Language > Autocomplete from one language to 
 * another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_autocomplete_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, 'autocomplete') &&
      _CopyLanguageOption(srcLang, destLang, 'autocompletemin');
}

/**
 * Copies the language inheritance and callbacks from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_inheritance(_str srcLang, _str destLang)
{
   // set the destination language to inherit from the source
   replace_def_data('def-inherit-'destLang, srcLang);

   return true;
}


/**
 * Copies the settings found on [Language] > Adaptive Formatting from one 
 * language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_adaptive_formatting_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, 'adaptive-formatting') &&
      _CopyLanguageOption(srcLang, destLang, 'adaptive-flags');
}

/**
 * Copies the settings found on [Language] > Context Tagging from one language 
 * to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_tagging_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, 'codehelp');
}

/**
 * Copies the keytable from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_keytable(_str srcLang, _str destLang)
{
   srcIndex := find_index("def-language-"srcLang, MISC_TYPE);
   destIndex := find_index("def-language-"destLang, MISC_TYPE);
   if (srcIndex && destIndex) {
      typeless s1, srcKeytab;
      parse name_info(srcIndex) with s1 'KEYTAB='srcKeytab',' . ;

      typeless d1, destKeytab, d2;
      parse name_info(destIndex) with d1 'KEYTAB='destKeytab','d2;
      set_name_info(destIndex, d1'KEYTAB='srcKeytab','d2);

   } else return false;

   return true;
}

/**
 * Copies the settings found on [Language] > Color Coding from one language to 
 * another.  If the destination language does not have a lexer, creates a new 
 * lexer with the mode name of the destination language. 
 *  Then copies the lexer settings from the source to the destination. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_color_coding(_str srcLang, _str destLang)
{
   // get the name of the lexers
   srcLexer := LanguageSettings.getLexerName(srcLang);
   destLexer := _LangId2Modename(destLang);

   // set the name of the destination lexer
   if (copyLexer(srcLexer, destLexer)) {
      // set the name, please
      LanguageSettings.setLexerName(destLang, destLexer);
      return true;
   }

   // boo, we failed
   return false;
}

/**
 * Copies the settings found on [Language] > Aliases from one language to 
 * another.  Copies the alias file, which replaces any aliases that might have 
 * been saved in the destination language 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_aliases(_str srcLang, _str destLang)
{
   srcFile := _ConfigPath() :+ getAliasFileNameForLang(srcLang);
   destFile :=_ConfigPath() :+  getAliasFileNameForLang(destLang);

   // now see if the source file exists
   if (file_exists(srcFile)) {
   
      // if so, copy it over the destination file
      if (!copy_file(srcFile, destFile)) return false;
   
   }  // if it doesn't exist, it's no biggie

   // we are so done
   return true;
}

/**
 * Copies the settings found on [Language] > File Options from one language to 
 * another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
boolean _copy_language_file_options(_str srcLang, _str destLang)
{
   // that's all there is to it
   return (_CopyLanguageOption(srcLang, destLang, 'load') && _CopyLanguageOption(srcLang, destLang, 'save'));
}

defeventtab _manage_languages_form;

#region Options Dialog Helper Functions

boolean _manage_languages_form_is_modified()
{
   return false;
}

_str _manage_languages_form_get_tags()
{
   tags := '';
   
   // get language specific primary extensions
   index := name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),14);
     tags :+= name' ';

     index=name_match('def-language-',0,MISC_TYPE);
   }
   
   return tags;
}

#endregion Options Dialog Helper Functions

void _manage_languages_form.on_resize()
{
   padding := _ctl_languages.p_x;

   widthDiff := p_width - (_ctl_add.p_x + _ctl_add.p_width + padding);
   if (widthDiff) {
      _ctl_add.p_x += widthDiff;
      _ctl_delete.p_x = _ctl_setup.p_x = _ctl_add.p_x;
      _ctl_languages.p_width += widthDiff;
   }

   heightDiff := p_height - (_ctl_languages.p_y + _ctl_languages.p_height + padding);
   if (heightDiff) {
      _ctl_languages.p_height += heightDiff;
   }
}

_ctl_add.on_create()
{
   refresh_languages();

   // disable this at first until we select something
   _ctl_setup.p_enabled = false;
}

void _ctl_add.lbutton_up()
{
   newMode := show("-modal _add_language_form");
   // IF user cancelled
   if (newMode=='') return;
   refresh_languages();

   _ctl_languages._lbfind_and_select_item(newMode);
   _update_buffers(newMode);
}

void _ctl_delete.lbutton_up()
{
   // get the selected language
   modeName := _ctl_languages._lbget_text();
   langId := _Modename2LangId(modeName);

   result := _message_box("Are you sure you wish to delete the language "modeName"?", 
                          "Delete Language", MB_YESNO | MB_ICONEXCLAMATION);
   if (result == IDNO) return;

   // delete it by the langid
   _DeleteLanguageOptions(langId);

   // refresh our list of languages
   refresh_languages();
   _ctl_languages.p_text = _ctl_languages._lbget_text();
   _ctl_languages.call_event(_ctl_languages, CHANGE_CLINE);

   // make the change in xml
   removeLanguageFromOptionsXML(modeName);

   // make sure we're not saving this lang's unsaved lexer info
   clear_unsaved_lexer_info_for_langId(langId);

   // For each buffer using this languages, select a different language mode.
   _safe_hidden_window();
   int view_id=0;
   save_view(view_id);
   int first_buf_id=p_buf_id;
   for (;;) {

      if(p_LangId==langId) _SetEditorLanguage();

      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   activate_window(view_id);
}

void _ctl_setup.lbutton_up()
{
   // check to see if we have a valid mode name...
   lang := _ctl_languages._lbget_text();
   if (lang != '') {
      showOptionsForModename(lang, 'General');
   } else {
      _message_box('Please select a language.');
   }
}

void _ctl_languages.on_change(int reason)
{
   if (reason == CHANGE_CLINE) {
      _ctl_languages.p_text = _ctl_languages._lbget_text();
   } else if (reason == CHANGE_OTHER) {  // if user types in name, select it.
      _ctl_languages._lbselect_line();
   }

   // if the item text is a substring of the selected item, then we enable 
   // this button - we don't want it enabled when we have a nonsense string entered
   if (pos(_ctl_languages.p_text, _ctl_languages._lbget_text(), 1, 'I') == 1){
      _ctl_setup.p_enabled = true;

      // only allow deletion of user-defined languages
      langId := _Modename2LangId(_ctl_languages._lbget_text());
      _ctl_delete.p_enabled = !_IsInstalledLanguage(langId);

   } else {
      _ctl_setup.p_enabled = false;
      _ctl_delete.p_enabled = false;
   }

}

refresh_languages()
{
   _ctl_languages._lbclear();
   _ctl_languages.p_picture = _pic_lbvs;
   _ctl_languages.p_pic_space_y = 60;
   _ctl_languages.p_pic_point_scale = 8;
   _ctl_languages.get_all_mode_names_mark_installed();
   _ctl_languages._lbsort();
   _ctl_languages._lbtop();
}

defeventtab _manage_extensions_form;

#region Options Dialog Helper Functions

int _manage_extensions_form_save_state()
{
   applyChangesToCurrentExtensionInfo();

   // everything is cool
   return 0;
}

void _manage_extensions_form_restore_state()
{
   // save the current extension, we're about to delete it
   curExt := CURRENT_EXTENSION;

   refresh_extensions_and_languages();

   // restore the current extension
   _ctl_extensions._lbfind_and_select_item(curExt);
}

boolean _manage_extensions_form_is_modified()
{
   return false;
}

_str _manage_extensions_form_get_tags()
{
   tags := '';
   
   // stuff from the encoding combo box
   if (_UTF8()) {
      
      // Get the encoding list.
      OPENENCODINGTAB openEncodingTab[];
      _EncodingListInit(openEncodingTab);

      int i;
      int init_i= 0;
      openEncodingTab[0].text='Default';
      for (i = 0; i < openEncodingTab._length(); ++i) {
         if (!(OEFLAG_REMOVE_FROM_OPEN & openEncodingTab[i].OEFlags)) {
            tags :+= openEncodingTab[i].text' ';
         }
      }
   } 

   index := name_match('def-lang-for-ext-', 1, MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),18);
     tags :+= name' ';
     index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }
   
   // get language specific primary extensions
   index = name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     name := substr(name_name(index),14);
     tags :+= name' ';

     index=name_match('def-language-',0,MISC_TYPE);
   }
   
   return tags;
}

#endregion Options Dialog Helper Functions

#define CURRENT_EXTENSION _ctl_extensions.p_user
#define ALL_EXTENSIONS     "All Extensions"
#define EXTENSIONS_DIFFER  "Extensions Differ"

void _manage_extensions_form.on_resize()
{
   padding := _ctl_extensions.p_x;

   widthDiff := p_width - (_ctlae_labeldiv.p_x + _ctlae_labeldiv.p_width + padding);
   if (widthDiff) {
      _ctl_extensions.p_width += widthDiff;
      ctllabel9.p_x += widthDiff;
      _ctl_languages.p_x = _ctlae_labeldiv.p_x = ctlencodinglabel.p_x = 
         ctlencoding.p_x = ctlpicture1.p_x = ctllabel7.p_x = 
         ctlAlternateEditor.p_x = ctlUseFileAssociation.p_x = 
         ctllabel8.p_x = ctllabel9.p_x;

      _ctl_lang_setup.p_x += widthDiff;
      ctlBrowseBtn.p_x += widthDiff;
      ctlFilterAppCmdButton.p_x += widthDiff;
   }

   heightDiff := p_height - (_ctl_new.p_y + _ctl_new.p_height);
   if (heightDiff) {
      _ctl_new.p_y += heightDiff;
      _ctl_delete.p_y = _ctl_new.p_y;

      _ctl_extensions.p_height += heightDiff;
   }
}

void applyChangesToCurrentExtensionInfo()
{
   ext := CURRENT_EXTENSION;

   if (ext == ALL_EXTENSIONS) {
      if (ctlencoding.p_text != EXTENSIONS_DIFFER) {
         new_encoding_info := _EncodingGetComboSetting();

         // set this encoding for all our extensions
         index := name_match('def-lang-for-ext-',1,MISC_TYPE);
         for (;;) {
           if ( ! index ) { break; }
           thisExt := substr(name_name(index),18);
   
           // get the encoding for this extension, see if it matches
           ExtensionSettings.setEncoding(thisExt, new_encoding_info);
   
           index=name_match('def-lang-for-ext-',0,MISC_TYPE);
         }
      }
   } else {
      // has the refers to changed?
      langId := _Ext2LangId(ext);
      if (_LangId2Modename(langId) != _ctl_languages.p_text && _ctl_languages.p_text != NONE_LANGUAGES) {
      
         // create an association from ext -> refLangId
         langId = _Modename2LangId(_ctl_languages.p_text);
         _SetExtensionReferTo(ext, langId);
      
         _update_buffers_for_ext(ext, langId);
      }
      
      // has the encoding changed?
      new_encoding_info := _EncodingGetComboSetting();
      ExtensionSettings.setEncoding(ext, new_encoding_info);
      
      // have the open application settings changed?
      ExtensionSettings.setUseFileAssociation(ext, (ctlUseFileAssociation.p_value != 0));
      ExtensionSettings.setOpenApplication(ext,  ctlAlternateEditor.p_text);
   }

}

void _ctl_new.on_create()
{
   _manage_extensions_form_initial_alignment();

   // fill up the encoding combo box
   if (_UTF8()) {
      ctlencoding._lbadd_item('Automatic');
      _EncodingFillComboList('','Default',OEFLAG_REMOVE_FROM_OPEN);
   } else {
      // Remove encoding text box
      ctlencoding.p_visible=0;
      ctlencodinglabel.p_visible=0;
   }

   // load up the extensions and languages
   refresh_extensions_and_languages();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _manage_extensions_form_initial_alignment()
{
   rightAlign := ctlencoding.p_x + ctlencoding.p_width;
   sizeBrowseButtonToTextBox(ctlAlternateEditor.p_window_id, ctlBrowseBtn.p_window_id, ctlFilterAppCmdButton.p_window_id, rightAlign);
}

void refresh_extensions_and_languages()
{
   CURRENT_EXTENSION = '';

   // load the languages in the combo box
   _ctl_languages._lbclear();
   _ctl_languages.get_all_mode_names();
   _ctl_languages._lbsort();
   _ctl_languages._lbtop();
   _ctl_languages.p_text = _ctl_languages._lbget_text();

   // load the extensions in the list box
   _ctl_extensions._lbclear();
   _ctl_extensions.get_all_file_extensions();
   // add a blank item to hold the top spot for ALL_EXTENSIONS
   _ctl_extensions._lbadd_item('  ');
   _ctl_extensions._lbsort();
   _ctl_extensions.top();

   // add an "All Extensions" option 
   _ctl_extensions._lbset_item(ALL_EXTENSIONS);

   _ctl_extensions._lbselect_line();
   _ctl_extensions.call_event(CHANGE_SELECTED, _ctl_extensions, ON_CHANGE, 'W');

}

void _ctl_new.lbutton_up()
{
   typeless support = 0;

   result := show('-modal _newext_form');

   // _param1 = '' if someone presses ok on an empty box
   if (result == '' || _param1 == '' || _param2 == '') {
      return;
   }

   // set extension (_param1) to refer to langID (_param2)
   _SetExtensionReferTo(_param1, _param2);
   CURRENT_EXTENSION = '';
   p_window_id = _ctl_new.p_parent;
   _ctl_extensions._lbclear();
   _ctl_extensions.get_all_file_extensions();
   _ctl_extensions._lbsort();

   _ctl_extensions._lbfind_and_select_item(_param1, 'i', true);

   _update_buffers_for_ext(_param1);
}

void _ctl_delete.lbutton_up()
{
   extension := _ctl_extensions.p_text;
   int result = _message_box('Are you sure you wish to delete the extension 'extension'?',
                '',
                MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result == IDNO || result == IDCANCEL) {
      return;
   }
   _DeleteExtension(extension);

   CURRENT_EXTENSION = '';

   _ctl_extensions._lbfind_and_delete_item(extension, 'i');
   _ctl_extensions._lbselect_line();
   _ctl_extensions.call_event(CHANGE_CLINE, _ctl_extensions, ON_CHANGE, 'W');
}

void _ctl_lang_setup.lbutton_up()
{
   showOptionsForModename(_ctl_languages._lbget_text(), 'General');
}

void _ctl_extensions.on_change(int reason)
{
   switch (reason) {
   case CHANGE_OTHER:         // if user types in extension, select it
      _ctl_extensions._lbselect_line();
      _ctl_extensions.call_event(CHANGE_SELECTED, _ctl_extensions, ON_CHANGE, 'W');
      break;
   case CHANGE_CLINE:
      if (_ctl_extensions.p_text!=_ctl_extensions._lbget_text()) {
         _ctl_extensions.p_text := _ctl_extensions._lbget_text();
      }
   case CHANGE_SELECTED:
      p_window_id = p_parent;
      
      // before we load everything up, we need to save our current stuff
      if (CURRENT_EXTENSION != '') applyChangesToCurrentExtensionInfo();
      
      // have we modified this one?
      ext := _ctl_extensions._lbget_text();
      
      // set the current extension
      CURRENT_EXTENSION = ext;
      
      // enable/disable based on whether this is ALL_EXTENSIONS      
      _ctl_languages.p_enabled = _ctl_lang_setup.p_enabled = ctlAlternateEditor.p_enabled = 
         ctlUseFileAssociation.p_enabled = ctlBrowseBtn.p_enabled = ctlFilterAppCmdButton.p_enabled = ctllabel9.p_enabled = 
         ctllabel7.p_enabled = ctllabel8.p_enabled = _ctl_delete.p_enabled = (ext != ALL_EXTENSIONS);

      if (ext == ALL_EXTENSIONS) {
         // special handling
         _ctl_languages._lbadd_item_no_dupe(NONE_LANGUAGES, '', LBADD_TOP, true);

         // figure out whether everything has the same encoding
         index := name_match('def-lang-for-ext-',1,MISC_TYPE);
         sharedEncoding := '';
         allMatch := true;
         for (;;) {
           if ( ! index ) { break; }
           thisExt := substr(name_name(index),18);

           // get the encoding for this extension, see if it matches
           thisEncoding := ExtensionSettings.getEncoding(thisExt);
           if (sharedEncoding == '') {
              // this is the first one, save it
              sharedEncoding = thisEncoding;
           } else if (sharedEncoding != thisEncoding) {
              // they don't match, so we might as well quit
              allMatch = false;
              break;
           } // else they match so far, keep going

           index=name_match('def-lang-for-ext-',0,MISC_TYPE);
         }

         if (allMatch) {
            ctlencoding.p_text = encodingToTitle(sharedEncoding);
         } else {
            ctlencoding._lbadd_item_no_dupe(EXTENSIONS_DIFFER, '', LBADD_TOP, true);
         }
      } else {
         // remove these things - we only need them for All Extensions
         ctlencoding._lbfind_and_delete_item(EXTENSIONS_DIFFER);
         _ctl_languages._lbfind_and_delete_item(NONE_LANGUAGES);

         // just a regular language
         langId := _Ext2LangId(ext);
         language := _LangId2Modename(langId);

         // select the language
         if (_ctl_languages._lbfind_and_select_item(language, '' , true)) {
            // not found, pick the NONE option
            _ctl_languages.p_text = NONE_LANGUAGES;
         }

         // now load the encoding
         ctlencoding.p_text = encodingToTitle(ExtensionSettings.getEncoding(ext));

         // and the open application options
   #if __UNIX__
         ctlUseFileAssociation.p_enabled=false;
   #endif
         ctlUseFileAssociation.p_value = (int)ExtensionSettings.getUseFileAssociation(ext);
         ctlAlternateEditor.p_text = ExtensionSettings.getOpenApplication(ext);
      }
      break;
   }
}

_str encodingToTitle(_str encoding)
{
   if (_UTF8()) {
      OPENENCODINGTAB openEncodingTab[];
      _EncodingListInit(openEncodingTab);

      if (encoding != '') {
         _str text='';
         for (i := 0; i < openEncodingTab._length(); ++i) {
             if (openEncodingTab[i].option == encoding ||
                 "+fcp"openEncodingTab[i].codePage == encoding) {
                return openEncodingTab[i].text;
                break;
             }
         }
      } else {
         return openEncodingTab[0].text;
      }
   }

   return '';
}

void _ctl_languages.on_change(int reason)
{
   if (_ctl_languages.p_text == NONE_LANGUAGES) {
      _ctl_lang_setup.p_enabled = false;
   } else {
      _ctl_lang_setup.p_enabled = true;
   }
}

void ctlBrowseBtn.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                               'Choose Application',        // Dialog Box Title
                               '',                   // Initial Wild Cards
                               "All Files (" ALLFILES_RE ")", // File Type List
                               OFN_FILEMUSTEXIST|OFN_NOCHANGEDIR     // Flags
                               );
   result=strip(result,'B','"');

   if ( result !='' ) {
      ctlAlternateEditor.p_text=result;
      ctlAlternateEditor.end_line();
      ctlAlternateEditor._set_focus();
   }
}

/* Dialog for creating a new extension and referring it */
defeventtab _newext_form;

_ok.on_create()
{
   ctl_referto.get_all_mode_names();
   ctl_referto._lbsort();
   ctl_referto._lbdeselect_line();
   ctl_referto.top();
   ctl_referto.up();

   // select plain text by default
   ctl_referto._lbfind_and_select_item('Plain Text');
}

_ok.lbutton_up()
{
   ext := ctl_extension.p_text;
   modename := ctl_referto.p_text;

   // make sure they specify a refer-to
   if (modename == '') {
      _message_box("Please specify a language to be associated with this extension.", "New Extension");
      return '';
   }

   langId := _Ext2LangId(ext);
   if (langId != '') {
      result := _message_box('The extension 'ext' is already associated with '_LangId2Modename(langId)'.  Do you wish to continue?', 'New Extension', MB_YESNO | MB_ICONEXCLAMATION);
      if (result == IDNO) return '';
   }

   // check that the referred to extension still exists
   language := _Modename2LangId(modename);
   if (language == '') {
      _message_box('Language doesn''t exist.');
      return('');
   }

   _param1 = ext;
   _param2 = language;
   p_active_form._delete_window(1);
}
/* END new extension dialog */

/*
  Verify that the value in min_abbrev is correct.
  The current object must be the text box associated
  with "Minimum Expandable Keyword Length".
  Pops up a message box and returns false if the length
  is invalid.
*/
static boolean check_min_abbrev()
{
   if (!isinteger(p_text) || p_text<1) {
      _message_box(nls("Invalid minimum expandable keyword length"));
      return false;
   }
   return true;
}

_str def_cpp_include_path_re;

defeventtab _java_extform;

#region Options Dialog Helper Functions

void _java_extform_init_for_options(_str langID)
{
   // we hide some controls for some languages
   shift := false;
   if (langID == 'js' || langID == 'as' || langID == 'cfscript' || langID == 'phpscript') {
      _indent.p_visible = false;

      shift = true;
   } else if (langID == 'awk') {
      _indent.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

      shift = true;
   } else if (langID == 'pl') {
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

      shift = true;
   } else if (langID == 'powershell') {
      _quick_brace.p_visible = false;
      _ctl_cuddle_else.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

      shift = true;
   } else if (langID == 'vera') {
      _ctl_cuddle_else.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

      shift = true;
   } else if (langID == 'rul') {
      frame1.p_visible = false;
      _indent.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _no_space.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;

      shift = true;
   } else if (langID == 'py') {
      frame1.p_visible = false;
      _indent.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

      _no_space.p_caption = 'No space before function parenthesis';

      shift = true;
   } else if (langID == 'idl') {
      label2.p_caption="struct {\n  int x,y;\n}";
      label3.p_caption="struct \n{\n  int x,y;\n}";
      label4.p_caption="struct\n  {\n  int x,y;\n  }";

      _quick_brace.p_visible = false;
      _ctl_cuddle_else.p_visible = false;
      _indent.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;
      _no_space.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;

      shift = true;
   }

   if (shift) _java_extform_shift_controls();

   // adaptive formatting stuff
   setAdaptiveLinks(langID);

   _language_form_init_for_options(langID, _language_formatting_form_get_value,
                                   _language_formatting_form_is_lang_included);

}

static void _java_extform_shift_controls()
{
   // not every option is available for every language that inherits this
   // form, so we hide some things and shift the other things up
   shift := 0;

   if (frame1.p_visible) {
      // quick brace/unbrace
      if (!_quick_brace.p_visible) {
         shift += _ctl_cuddle_else.p_y - _quick_brace.p_y;
      } else {
         _quick_brace.p_y -= shift;
      }

      // place "else" on same line
      if (!_ctl_cuddle_else.p_visible) {
         shift += frame1.p_height - _ctl_cuddle_else.p_y;
      } else {
         _ctl_cuddle_else.p_y -= shift;
      }

      // brace style frame
      frame1.p_height -= shift;
   } else {
      shift = _indent.p_y - frame1.p_y;
   }

   // indent first level of code
   if (!_indent.p_visible) {
      shift += ctlUseContOnParameters.p_y - _indent.p_y;
   } else {
      _indent.p_y -= shift;
   }

   // use continuation indent
   if (!ctlUseContOnParameters.p_visible) {
      shift += _indent_case.p_y - ctlUseContOnParameters.p_y;
   } else {
      ctlUseContOnParameters.p_y -= shift;
   }

   // indent case from switch
   if (!_indent_case.p_visible) {
      shift += _no_space.p_y - _indent_case.p_y;
   } else {
      _indent_case.p_y -= shift;
      _indent_case_ad_form_link.p_y -= shift;
   }

   // no space before parens
   _no_space.p_y -= shift;
   _no_space_ad_form_link.p_y -= shift;

   // insert padding
   ctl_pad_between_parens.p_y -= shift;
   _pad_parens_ad_form_link.p_y -= shift;
}
/*END C AND SLICK AND AWK AND PERL OPTIONS EVENT TABLE*/

/*dBASE Options Form*/
defeventtab _prg_extform;

void _prg_extform.on_destroy()
{
   _language_form_on_destroy();
}

/*End dBASE Options Form*/

/*Pascal Options Form*/
defeventtab _pas_extform;

#region Options Dialog Helper Functions

void _pas_extform_init_for_options(_str langID)
{
   _language_form_init_for_options(langID, _pas_extform_get_value, 
                                   _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(langID);
}

_str _pas_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_comment':
      value = (int)LanguageSettings.getBeginEndComments(langId);
      break;
   case '_delphi_expand':
      value = (int)LanguageSettings.getDelphiExpansions(langId, true);
      break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}

boolean _pas_extform_apply()
{
   _language_form_apply(_pas_extform_apply_control);

   return true;
}

_str _pas_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := '';

   switch (controlName) {
   case '_comment':
      LanguageSettings.setBeginEndComments(langId, ((int)value != 0));
      break;
   case '_delphi_expand':
      LanguageSettings.setDelphiExpansions(langId, ((int)value != 0));
      break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return updateString;
}

#endregion Options Dialog Helper Functions

void _pas_extform.on_destroy()
{
   _language_form_on_destroy();
}

/*End Pascal Options Form*/

/*COBOL Options Form*/

/** 
 * 
 * Displays <b>Cobol Options dialog box</b> which is used for modifying 
 * the extension specific options for Cobol.
 * 
 * @example: 
 * <pre>
 *    <i>Syntax</i>  void show('_cob_extform')
 * </pre>
 * 
 * @categories Forms
 */

defeventtab _cob_extform;


#region Options Dialog Helper Functions

boolean _cob_extform_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == 'pl1' && action == OPTIONS_APPLYING) {
      
      _nocheck _control text1, text2;
      // code margins 
      text := '';
      validateBoundsStart := _language_form_control_needs_validation(text1.p_window_id, text);
      if (!validateLangIntTextBox(text1.p_window_id)) {
         return false;
      }
   
      validateBoundsEnd := _language_form_control_needs_validation(text2.p_window_id, text);
      if (!validateLangIntTextBox(text2.p_window_id)) {
         return false;
      }
   
      if (validateBoundsStart || validateBoundsEnd) {
         if (isinteger(text1.p_text) && isinteger(text2.p_text) && text1.p_text > text2.p_text) {
            text1._text_box_error("The left margin must be less than the right margin.");
            return false;
         }
      }
   } else if (action == OPTIONS_APPLYING && _find_control('_first_indent')) {
      if (_first_indent.p_visible && (!isinteger(_first_indent.p_text) || (int)_first_indent.p_text < 0)) {
         _message_box('Indent amount for first level of code must be a positive integer.');
         return false;
      }
      return _language_formatting_form_validate(action);
   }

   return true;
}

void _cob_extform_init_for_options(_str langID)
{
   // these controls only go with one or two languages
   if (_find_control('_first_indent')) {
      label2.p_visible = _first_indent.p_visible = (langID == 'bas' || langID == 'vbs');
   }
   if (_find_control('_multiline_exp')) {
      _multiline_exp.p_visible = (langID == 'for');
   }
   if (_find_control('_ctl_auto_insert_label')) {
      _ctl_auto_insert_label.p_visible = (langID == 'vhd');
   }

   doShift := false;
   if (langID == 'cob') {
      license1 := _default_option(VSOPTION_PACKFLAGS1);
      if (!(license1 & VSPACKFLAG1_COB) && !(license1 & VSPACKFLAG1_ASM)) {
         ctlautosyntaxhelp.p_enabled = false;
      }
      doShift = true;
   } else {
      if (langID == 'plsql' || langID == 'sqlserver') {
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctlnumbers.p_visible = false;
         doShift = true;
      } else if (langID == 'asm390') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctl_numbers_cobol.p_visible = false;
         _keyword_case_ad_form_link.p_visible = false;
         doShift = true;
      } else if (langID == 'cics') {
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         doShift = true;
      } else if (langID == 'jcl') {
         ctlcase.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctl_numbers_cobol.p_visible = false;
         doShift = true;
      } else if (langID == 'rexx') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctl_numbers_cobol.p_visible = false;
         doShift = true;
      } else if (langID == 'ada' || langID == 'gl' || langID == 'sas') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctlnumbers.p_visible = false;
         doShift = true;
      } else if (langID == 'bas' || langID == 'vbs') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctlnumbers.p_visible = false;
         doShift = true;
      } else if (langID == 'for') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         doShift = true;
      } else if (langID == 'vhd') {
         ctlautocase.p_visible = false;
         ctlautosyntaxhelp.p_visible = false;
         ctlsqldialect.p_visible = false;
         ctlnumbers.p_visible = false;
         doShift = true;
      }
   }

   // if we hid anything, then we need to readjust everything else
   if (doShift) _cob_extform_shift_controls();

   _language_form_init_for_options(langID, _cob_extform_get_value, 
                                   _language_formatting_form_is_lang_included);

   setAdaptiveLinks(langID);
}

static void _cob_extform_shift_controls()
{
   // not all languages which use this form support all the
   // options, so we have to hide some and shift the others
   shift := 0;
   if (!ctlautocase.p_visible) {
      shift += ctlautosyntaxhelp.p_y - ctlautocase.p_y;
   }

   if (!ctlautosyntaxhelp.p_visible) {
      shift += ctlcase.p_height - ctlautosyntaxhelp.p_y;
   }

   ctlcase.p_height -= shift;

   // second column
   shift = 0;

   if (!ctlnumbers.p_visible && !ctlsqldialect.p_visible) {
      // if the larger frames are not there, then move these guys to column 1

      // padding between frame and label
      pad := label2.p_y - (ctlsqldialect.p_y + ctlsqldialect.p_height);
      yPos := ctlcase.p_y + ctlcase.p_height + pad;
      if (label2.p_visible) {
         // keep track of the shifts so we can mantain the same
         // distance b/t the label and the textbox
         yShift := label2.p_y - yPos;
         xShift := label2.p_x - ctlcase.p_x;

         label2.p_y -= yShift;
         label2.p_x -= xShift;
         _first_indent.p_y -= yShift;
         _first_indent.p_x -= xShift;

         yPos = label2.p_y + label2.p_height + pad;
      }

      // padding between two checkboxes
      pad = (_ctl_auto_insert_label.p_y - (_multiline_exp.p_y + _multiline_exp.p_height));
      if (_multiline_exp.p_visible) {
         _multiline_exp.p_y = yPos;
         _multiline_exp.p_x = ctlcase.p_x;
         yPos = _multiline_exp.p_y + _multiline_exp.p_height + pad;
      }

      if (_ctl_auto_insert_label.p_visible) {
         _ctl_auto_insert_label.p_y = yPos;
         _ctl_auto_insert_label.p_x = ctlcase.p_x;
      }
   } else {
      if (ctlnumbers.p_visible) {
         if (!ctl_numbers_cobol.p_visible) {
            shift = ctl_numbers_spf.p_y - ctl_numbers_cobol.p_y;
            ctlnumbers.p_height -= shift;
            ctl_numbers_spf.p_y = ctl_numbers_cobol.p_y;
         }
      } else {
         shift = ctlsqldialect.p_y - ctlnumbers.p_y;
      }

      if (!ctlsqldialect.p_visible) {
         shift += label2.p_y - ctlsqldialect.p_y;
      } else {
         ctlsqldialect.p_y -= shift;
      }

      if (!label2.p_visible) {
         shift += _multiline_exp.p_y - label2.p_y;
      } else {
         label2.p_y -= shift;
         _first_indent.p_y -= shift;
      }

      if (_multiline_exp.p_visible) {
         _multiline_exp.p_y -= shift;
      }
   }
}

_str _cob_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'text1':
      _str margins = LanguageSettings.getCodeMargins(langId);
      parse margins with auto leftMargin . ;
      value = leftMargin;
      break;
   case 'text2':
      margins = LanguageSettings.getCodeMargins(langId);
      parse margins with . auto rightMargin . ;
      value = rightMargin;
      break;
   case 'ctlautocase':
      value = (int)LanguageSettings.getAutoCaseKeywords(langId);
      break;
   case 'ctlsqlserver':
   case 'ctldb2':
   case 'ctlplsql':
      index := find_index(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE);
      if (!index) {
         index = insert_name(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE, "PL/SQL");
      }

      switch (name_info(index)) {
      case "SQL Server":
         value = 'ctlsqlserver';
         break;
      case "DB2":
         value = 'ctldb2';
         break;
      default: // "PL/SQL":
         value = 'ctlplsql';
         break;
      }
      break;
   case 'ctlautosyntaxhelp':
      value = (LanguageSettings.getCodehelpFlags(langId) & VSCODEHELPFLAG_AUTO_SYNTAX_HELP) ? 1 : 0;
      break;
   case 'ctl_numbers_cobol':
      numStyle := LanguageSettings.getNumberingStyle(langId);
      value = (numStyle & VSRENUMBER_COBOL)? 1 : 0;
      break;
   case 'ctl_numbers_spf':
      numStyle = LanguageSettings.getNumberingStyle(langId);
      value = (numStyle & VSRENUMBER_STD)? 1 : 0;
      break;
   case '_multiline_exp':
      value = (int)LanguageSettings.getMultilineIfExpansion(langId);
      break;
   case '_first_indent':
      value = LanguageSettings.getIndentFirstLevel(langId, 3);
      break;
   case '_ctl_auto_insert_label':
      value = (int)LanguageSettings.getAutoInsertLabel(langId);
      break;
   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}

boolean _cob_extform_apply()
{
   _language_form_apply(_cob_extform_apply_control);

   return true;
}

_str _cob_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := '';

   switch (controlName) {
   case 'text1':
      _str margins = LanguageSettings.getCodeMargins(langId);
      parse margins with auto leftMargin auto rightMargin;
      _str newMargins = value' 'rightMargin;
      LanguageSettings.setCodeMargins(langId, newMargins);
      break;
   case 'text2':
      margins = LanguageSettings.getCodeMargins(langId);
      parse margins with leftMargin rightMargin;
      newMargins = leftMargin' 'value;
      LanguageSettings.setCodeMargins(langId, newMargins);
      break;
   case 'ctlautocase':
      LanguageSettings.setAutoCaseKeywords(langId, (int)value != 0);
      break;
   case 'ctlsqlserver':
      index := find_index(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE);
      info := "SQL Server";

      if (index) {
         set_name_info(index, info);
      } else {
         insert_name(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE,info);
      }
      break;
   case 'ctldb2':
      index = find_index(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE);
      info = "DB2";

      if (index) {
         set_name_info(index, info);
      } else {
         insert_name(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE,info);
      }
      break;
   case 'ctlplsql':
      index = find_index(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE);
      info = "PL/SQL";

      if (index) {
         set_name_info(index, info);
      } else {
         insert_name(VSCOBOL_SQL_LEXER_NAME,MISC_TYPE,info);
      }
      break;
   case 'ctlautosyntaxhelp':
      codehelpFlags := LanguageSettings.getCodehelpFlags(langId);
      if ((int)value) {
         codehelpFlags |= VSCODEHELPFLAG_AUTO_SYNTAX_HELP;
      } else {
         codehelpFlags &= ~VSCODEHELPFLAG_AUTO_SYNTAX_HELP;
      }

      LanguageSettings.setCodehelpFlags(langId, codehelpFlags);
      break;
   case 'ctl_numbers_spf':
      numStyle := LanguageSettings.getNumberingStyle(langId);
      if ((int)value) {
         numStyle |= VSRENUMBER_STD;
      } else {
         numStyle &= ~VSRENUMBER_STD;
      }
      LanguageSettings.setNumberingStyle(langId, numStyle);
      break;
   case 'ctl_numbers_cobol':
      numStyle = LanguageSettings.getNumberingStyle(langId);
      if ((int)value) {
         numStyle |= VSRENUMBER_COBOL;
      } else {
         numStyle &= ~VSRENUMBER_COBOL;
      }
      LanguageSettings.setNumberingStyle(langId, numStyle);
      break;
   case '_multiline_exp':
      LanguageSettings.setMultilineIfExpansion(langId, ((int)value != 0));
      break;
   case '_first_indent':
      LanguageSettings.setIndentFirstLevel(langId, (int)value);
      break;
   case '_ctl_auto_insert_label':
      LanguageSettings.setAutoInsertLabel(langId, (int)value != 0);
      break;
   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return updateString;
}

#endregion Options Dialog Helper Functions

void _cob_extform.on_destroy()
{
   _language_form_on_destroy();
}

void _none.lbutton_up()
{
   ctlautocase.p_enabled=_none.p_value==0;
}

/*End COBOL Options Form*/

/*CICS Options Form inherits all events and callbacks from COBOL*/

/**
 * Removes the language setup options for the specific 
 * file extension.  If the given extension is just 
 * referred to another extension, then only remove the 
 * referral, not the entire language setup. 
 *
 * @param extension  File extension. 
 *
 * @see _SetDefaultLanguageOptions
 * @see _GetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions 
 * @see _Filename2LangId 
 * @see _Ext2LangId
 * @see setupext 
 *
 * @categories Configuration_Functions 
 *  
 * @deprecated Use {@link _DeleteExtension()} or 
 *                 {@link _DeleteLanguageOptions()} instead. 
 */
void _DeleteExtensionOptions(_str extension)
{
   // if the extension is referred, just delete the referal
   lang := _Ext2LangId(extension);
   _DeleteExtension(extension);
   if (lang != extension) {
      return;
   }

   // this is a real language ID, so delete it entirely
   _DeleteLanguageOptions(extension);
}

/** 
 * Deletes a file extension mapping.
 *
 * @param extension  File extension. 
 *                   For list of file extensions, use our
 *                   Language Options dialog ("Tools",
 *                   "Options...", "File Extension Manager").
 *  
 * @see _CreateExtension 
 * @see _DeleteLanguageOptions 
 * @see _Filename2LangId 
 * @see _Ext2LangId
 * @see setupext 
 *
 * @categories Configuration_Functions
 */
void _DeleteExtension(_str extension)
{
   // if the extension is referred, just delete the referal
   extension=_file_case(extension);
   int index= find_index('def-lang-for-ext-'extension, MISC_TYPE);
   if (!index) return;

   // changing an extension referral option, so clear cache
   _ClearDefaultLanguageOptionsCache();

   // delete def-lang-for-[extension]
   delete_name(index);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   // These three settings are per-extension, not just per-language
   index= find_index('def-encoding-'extension, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-default-dtd-'extension, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-association-'extension, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

/**
 * Removes the language setup options for the specific 
 * language, as specified by the given language ID. 
 * Note that 'lang' must be a real language ID, not a 
 * referred file extension. 
 *
 * @param lang    Language ID (see {@link p_LangId} 
 *
 * @see _SetDefaultLanguageOptions
 * @see _GetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteExtensionOptions 
 * @see _Filename2LangId 
 * @see _Ext2LangId
 * @see setupext 
 *
 * @categories Configuration_Functions 
 * @since 13.0 
 */
void _DeleteLanguageOptions(_str lang)
{
   // changed a language option, so clear cache
   _ClearDefaultLanguageOptionsCache();

   index := find_index('def-language-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index = find_index('def-setup-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-options-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-begin-end-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-alias-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
#if 0
   index= find_index('def-encoding-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-default-dtd-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index= find_index('def-association-'lang, MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
#endif
   index=find_index('def-tagfiles-'lang,MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index=find_index('def-killfcts-'lang,MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index=find_index('def-inherit-'lang,MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   index=find_index('def-menu-'lang,MISC_TYPE);
   if (index) {
      delete_name(index);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }

   // Remove all extensions that are referred to this language
   _str referrals[];
   index = name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index > 0) {
      if (name_info(index) == lang) {
         //referrals[referrals._length()] = index;
         parse name_name(index) with 'def-lang-for-ext-' auto ext;
         referrals[referrals._length()]= ext;
      }
      index = name_match('def-lang-for-ext-',0,MISC_TYPE);
   }
   foreach (auto ext in referrals) {
      _DeleteExtension(ext);
   }
}

int _GetExtIndentOptions(_str lang, int &IndentStyle, int &SyntaxIndent)
{
   VS_LANGUAGE_OPTIONS op;
   if (_GetDefaultLanguageOptions(lang, '', op)) {
      return 1;
   }
   IndentStyle = op.IndentStyle;
   SyntaxIndent = op.SyntaxIndent;
   return (0);
}

/**
 * Allows you to specify that a file extension is associated 
 * with the specified language.  This information is used to
 * determine what language mode to choose when a file with the
 * given extension is opened.
 *
 * @param extension  File extension.  For list of file extension
 *                   types, use our Options dialog ("Tools",
 *                   "Options...", "File Extension Manager").
 *
 * @param lang File language ID (see {@link p_LangId}).
 *             For list of language types, 
 *             use our Language Options dialog
 *             ("Tools", "Options...", "Language Manager")
 *
 * @see _SetDefaultLanguageOptions
 * @see _DeleteExtensionOptions 
 * @see _DeleteLanguageOptions 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 */
void _SetExtensionReferTo(_str extension, _str lang)
{
   // changed an extension option, so clear cache
   _ClearDefaultLanguageOptionsCache();

   // Can't refer to self
   extension=_file_case(extension);
#if 0
   _str OldLangId=_Ext2LangId(extension);
   if (OldLangId==extension) {
      if (lang=="") {
         return;
      }
      // Clean out whats here
      _DeleteExtension(extension);
   }
#endif
   /*
   _str name='def-language-'extension;
   int setup_index=find_index(name,MISC_TYPE);
   if (setup_index && first_char(name_info(setup_index))=='@') {
      delete_name(setup_index);
   }
   */

   // in SE 2008, we refer extensions using the lang-for-ext map
   name  := 'def-lang-for-ext-'extension;
   index := find_index(name,MISC_TYPE);
   if (lang!="") {
      if (!index) {
         index = insert_name(name,MISC_TYPE,lang);
      } else {
         set_name_info(index,lang);
      }
   } else {
      if (index) delete_name(index);
   }
   _config_modify_flags(CFGMODIFY_DEFDATA);
}
/**
 * @deprecated Use {@link SetLanguageInheritsFrom}.
 */
void _SetDefaultExtensionInheritFrom(_str extension,_str parent_ext)
{
   // Can't inherit from self
   if (file_eq(extension,parent_ext)) {
      return;
   }
   extension=_file_case(extension);
   _str name='def-inherit-'extension;
   int setup_index=find_index(name,MISC_TYPE);
   if (parent_ext!="") {
      if (!setup_index) {
         setup_index=insert_name(name,MISC_TYPE,parent_ext);
      } else {
         set_name_info(setup_index,parent_ext);
      }
   } else {
      if (setup_index) delete_name(setup_index);
   }
}
/**
 * @return Return the name of the color coding lexer for the given
 *         file extension.
 *  
 * @deprecated Use {@link _LangId2LexerName()}. 
 */
_str _ext2lexername(_str ext,int &setup_index)
{
   // find language corresponding to 'ext'
   lang := _Ext2LangId(ext);
   if (ext == '') {
      setup_index=0;
      return '';
   }

   return _LangId2LexerName(lang);
}

/**
 * Sets language specific options for a specific file extension.
 *
 * @param extension     File extension. For list of file extension types,
 *                      use our File Extension Manager dialog ("Tools",
 *                      "Options...", "File Extension Manager")
 * @param langOptions   New language specific options for
 *                      <i>pszExtension</i>.  Since all options are
 *                      must be set, use the 
 *                      <b>vsGetDefaultExtensionOptions</b>
 *                      first to query the existing value before 
 *                      setting new values.
 * @param reserved      unused
 *
 * @see _GetDefaultExtensionOptions
 * @see _SetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteExtensionOptions
 * @see _DeleteLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * 
 * @deprecated Use {@link _SetDefaultLanguageOptions}
 */
void _SetDefaultExtensionOptions(_str extension,
                                 VS_LANGUAGE_OPTIONS &langOptions,
                                 int reserved)
{
   extension=_file_case(extension);
   lang := extension;
   if (langOptions.szRefersToLanguage!="") {
      lang = langOptions.szRefersToLanguage;
   }
   _SetDefaultLanguageOptions(lang,extension,langOptions);
}
/**
 * Sets language specific options for a specific language.
 *
 * @param lang          File language ID (see {@link p_LangId}).
 *                      For list of language types, 
 *                      use our Language Options dialog
 *                      ("Tools", "Options...", "Language Manager")
 * @param origExtension File extension referred to 'lang'. 
 *                      This is necessary for retrieving options
 *                      which are genuinely per extension, such as
 *                      encoding and associated open application. 
 * @param langOptions   New language specific options for
 *                      <i>pszExtension</i>.  Since all options are
 *                      must be set, use the 
 *                      <b>vsGetDefaultLanguageOptions</b>
 *                      first to query the existing value before
 *                      setting new values.
 *
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions 
 * @since 13.0 
 */
void _SetDefaultLanguageOptions(_str lang, _str origExtension,
                                VS_LANGUAGE_OPTIONS &langOptions)
{
   // changed an extension option, so clear cache
   _ClearDefaultLanguageOptionsCache();

   origExtension = _file_case(origExtension);
   _str info="";
   _str name="";
   _str OldReferTo=_Ext2LangId(origExtension);
   int setup_index=0;
   // If this is just referring an extension to a language
   if (langOptions.szRefersToLanguage!="" &&
       !file_eq(OldReferTo,langOptions.szRefersToLanguage)) {
      if (OldReferTo==origExtension) {
         // Clean out whats here
         _DeleteExtension(origExtension);
      }
      if (langOptions.szRefersToLanguage!="") {
         name='def-lang-for-ext-'origExtension;
         info=langOptions.szRefersToLanguage;
         setup_index=find_index(name,MISC_TYPE);
         if (!setup_index) {
            setup_index=insert_name(name,MISC_TYPE,info);
         } else {
            set_name_info(setup_index,info);
         }
      }
   }
   if (lang=='' && langOptions.szRefersToLanguage!="") {
      lang=langOptions.szRefersToLanguage;
   }
   
   // derive mode name if not specified
   if (langOptions.szModeName == "") {
      langOptions.szModeName=lang;
   }
   
   if (langOptions.szEventTableName == "" && lang != FUNDAMENTAL_LANG_ID) {
      langOptions.szEventTableName = 'ext_keys';
   }
   
   LanguageSettings.setAllLanguageOptions(lang, langOptions);
   
   // update list of file extensions referred for this extension
   _str file_extensions = langOptions.szFileExtensions;
   if (file_extensions=="") {
      file_extensions = lang;
   }
   update_file_extensions(lang, file_extensions);

   ExtensionSettings.setEncoding(origExtension, langOptions.encoding);
   ExtensionSettings.setDefaultDTD(origExtension, langOptions.default_dtd);
   ExtensionSettings.setOpenApplication(origExtension, langOptions.szOpenApplication);
   ExtensionSettings.setUseFileAssociation(origExtension, langOptions.UseFileAssociation);

   _config_modify_flags(CFGMODIFY_DEFDATA);
}

/**
 * Gets language specific options for a specific file extension.
 *
 * @return Returns 0 if successful.
 *
 * @param extension     File extension. For list of file extension types,
 *                      use our File Extension Manager dialog ("Tools",
 *                      "Options...", "File Extension Manager")
 * @param langOptions   Initialized to language specific options 
 *                      for <i>extension</i>.
 *    
 * @see _SetDefaultExtensionOptions
 * @see _GetDefaultLanguageOptions
 * @see _SetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions 
 * @deprecated Use {@link _GetDefaultLanguageOptions()} 
 */
int _GetDefaultExtensionOptions(_str extension, VS_LANGUAGE_OPTIONS &langOptions)
{
   extension = _file_case(extension);
   lang := _Ext2LangId(extension);
   langOptions.szRefersToLanguage = lang;
   return _GetDefaultLanguageOptions(lang,extension,langOptions);
}

/**
 * Gets language specific options for a specific language type.
 *
 * @return Returns 0 if successful.
 *
 * @param lang          Language ID (see {@link p_LangId}).
 *                      For list of language types, 
 *                      use our Language Manager dialog
 *                      ("Tools", "Options...", "Language Manager")
 * @param origExtension File extension referred to this language.
 *                      This is necessary for retrieving options
 *                      which are genuinely per extension, such as
 *                      encoding and associated open application. 
 * @param langOptions   Initialized to language specific options 
 *                      for <i>pszLangId</i>.
 *    
 * @see _SetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions
 * @see _SetDefaultLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * @since 13.0
 */
int _GetDefaultLanguageOptions(_str lang, _str origExtension,
                               VS_LANGUAGE_OPTIONS &langOptions)
{
   // construct the hash table key
   key := lang;
   if (origExtension != null) {
      key :+= ',';
      key :+= origExtension;
   }

   // try to get the langauge setup information object from the cache
   VS_LANGUAGE_OPTIONS (*languageInfoCache):[];
   languageInfoCache = _GetDialogInfoHtPtr(LANGUAGE_OPTIONS_KEY,_mdi);
   if (languageInfoCache != null) {
      if (languageInfoCache->_indexin(key)) {
         langOptions = (*languageInfoCache):[key];
         return 0;
      }
   }

   // Check setup information for this extension
   VS_LANGUAGE_SETUP_OPTIONS setup;
   if (_GetLanguageSetupOptions(lang,setup)) {
      return(1);
   }

   // use the LanguageSettings API to get the options
   if (origExtension=='') origExtension=lang;
   LanguageSettings.getAllLanguageOptions(lang, langOptions);
   
   langOptions.szRefersToLanguage = ExtensionSettings.getLangRefersTo(origExtension);

   // find all file extensions that refer to this language extension
   langOptions.szFileExtensions=get_file_extensions(lang);
   langOptions.encoding = ExtensionSettings.getEncoding(origExtension);
   langOptions.default_dtd=ExtensionSettings.getDefaultDTD(origExtension);
   langOptions.UseFileAssociation = ExtensionSettings.getUseFileAssociation(origExtension);
   langOptions.szOpenApplication = ExtensionSettings.getOpenApplication(origExtension);

   // Save the language options in the language options cache
   if (languageInfoCache == null) {
      VS_LANGUAGE_OPTIONS languageInfoHash:[];
      languageInfoHash:[key] = langOptions;
      _SetDialogInfoHt(LANGUAGE_OPTIONS_KEY, languageInfoHash, _mdi);
   } else {
      (*languageInfoCache):[key] = langOptions;
   }

   // that's all folks
   return(0);
}

void _ClearDefaultLanguageOptionsCache()
{
   _SetDialogInfoHt(LANGUAGE_OPTIONS_KEY, null, _mdi);
}

/**
 * This variable contains a space separated list of all 
 * the standard languages supported by SlickEdit.  The list 
 * is constructed when the state file is built, and never 
 * modified.  You will not be allowed to delete languages 
 * that are on this list. 
 */
_str gInstalledLanguages = "";

/**
 * Catalog all the standard languages supported at installation time. 
 * The data constructed here is used to recognize which languages
 * you are not allowed to delete from the language setup dialog.
 * 
 * @see _IsInstalledLanguage
 */
void _EnumerateInstalledLanguages()
{
   index := name_match("def-language-",1,MISC_TYPE);
   while (index > 0) {
      lang := substr(name_name(index),14);
      gInstalledLanguages :+= lang;
      gInstalledLanguages :+= ' ';
      index = name_match("def-language-",0,MISC_TYPE);
   }
   // special case for PV-WAVE and SABL, which are loaded dynamically
   if (!_IsInstalledLanguage('seq')) gInstalledLanguages :+= "seq ";
   if (!_IsInstalledLanguage('pro')) gInstalledLanguages :+= "pro ";
}

/**
 * Add a language to the installed language list. Mostly for 
 * OEM use 
 * 
 * @param lang language ID
 */
void _AppendInstalledLanguage(_str lang)
{
   if (!_IsInstalledLanguage(lang)) gInstalledLanguages :+= lang:+" ";
}

typedef _str (*STRHASHPTR):[];

void _set_language_form_lang_id(_str langID, int wid = 0)
{
   _SetDialogInfoHt('langID', langID, wid);
}

_str _get_language_form_lang_id(int wid = 0)
{
   return _GetDialogInfoHt('langID', wid);
}

void _set_language_form_mode_name(_str modeName, int wid = 0)
{
   _SetDialogInfoHt('modeName', modeName, wid);
}

int _get_language_form_mode_name(int wid = 0)
{
   return _GetDialogInfoHt('modeName', wid);
}

void _create_language_form_settings(int wid = 0)
{
   _str settings:[];
   _SetDialogInfoHt('settings', settings, wid);
}

STRHASHPTR _get_language_form_settings(int wid = 0)
{
   return _GetDialogInfoHtPtr('settings', wid);
}

/**
 * Validates a language form text box meant to hold an integer value.
 * 
 * @param wid 
 * @param error 
 * @param min 
 * @param max 
 * 
 * @return                    false if the value in the text box is not valid, 
 *                            true if it is valid or does not need to be
 *                            checked.
 */
boolean validateLangIntTextBox(int wid, int min = null, int max = null, _str error = '')
{
   // just make sure this is the right thing
   if (wid.p_object != OI_TEXT_BOX) return false;

   text := '';
   if (_language_form_control_needs_validation(wid, text)) {

      checkMin := (min != null);
      checkMax := (max != null);

      if (text == '' || !isuinteger(text) || 
          (checkMin && (int)text < min) || 
          (checkMax && (int)text > max)) {

         // build our own custom error message!
         if (error == '') {
            error = 'Expecting a positive integer value';
            if (checkMin) {
               error :+= ' greater than 'min;
               if (checkMax) {
                  error :+= ', and';
               }
            }
            if (checkMax) {
               error :+= ' less than 'max;
            }

            error :+= '.';
         }

         wid._text_box_error(error);
         return false;
      }
   }

   return true;
}

boolean isLangAliasesFormExcludedForMode(_str langId)
{
   return (langId == ALL_LANGUAGES_ID);
}

boolean isLangColorCodingFormExcludedForMode(_str langId)
{
   return (langId == ALL_LANGUAGES_ID);
}

defeventtab _language_general_form;

#define FILE_EXTENSIONS_LABEL_HEIGHT   _file_extensions_lbl.p_user
#define FILE_LANGUAGES_LABEL_HEIGHT    _mixed_languages_label.p_user

#define INDENT_STYLE_NONE_TEXT            'None'
#define INDENT_STYLE_AUTO_TEXT            'Auto'
#define INDENT_STYLE_SYNTAX_INDENT_TEXT   'Syntax indent'

#region Options Dialog Helper Functions

void _language_general_form_init_for_options(_str langID)
{
   // context menu stuff - fill in our choices
   _menu_list._lbclear();
   _menu_list.fill_in_menu_list();
   _selection_menu_list._lbclear();
   _selection_menu_list.fill_in_menu_list();

   // bounds only visible in ispf mode
   if (def_keys!='ispf-keys') {
      ctlBoundsFrame.p_visible = false;

      // move everything else up...
      yShift := ctlLeadingBlanksTab.p_y - ctlBoundsFrame.p_y;
      ctlLeadingBlanksTab.p_y -= yShift;
      ctlBeginEndPairsLabel.p_y -= yShift;
      _beginend_pairs.p_y -= yShift;
      ctlWordCharsLabel.p_y -= yShift;
      _word_chars.p_y -= yShift;
      ctllabel16.p_y -= yShift;
      ctlIndentStyle.p_y -= yShift;
      _project.p_y -= yShift;
   }

   if (langID == ALL_LANGUAGES_ID) {
      // hide the mode name and extensions stuff
      label1.p_visible = _mode_name.p_visible = false;
      ctllabel14.p_visible = _file_extensions_lbl.p_visible = false;
      _ctl_edit_extensions.p_visible = false;
      ctllabel15.p_visible = _mixed_languages_label.p_visible = false;
      _ctl_edit_languages.p_visible = false;
      _project.p_visible = _ctl_extensionless_files_link.p_visible = false;
   } else {
      // enable or disable the projects button
      if (langID != ALL_LANGUAGES_ID && !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS)) {
         _project.p_enabled=0;
      }

      // get and sort list of file extensions
      _file_extensions_lbl.p_caption = get_file_extensions_sorted(langID);

      // get list of referenced languages
      _mixed_languages_label.p_caption = get_referenced_in_languages(langID);

      if (!new_beautifier_supported_language(langID)) {
         _beaut_edit.p_visible = false;
         _beaut_syntax.p_visible = false;
         _beaut_alias.p_visible = false;
         _beaut_paste.p_visible = false;
      }
   }


   ctlIndentStyle._lbadd_item(INDENT_STYLE_NONE_TEXT);
   ctlIndentStyle._lbadd_item(INDENT_STYLE_AUTO_TEXT);
   if (_is_syntax_indent_supported(langID)) {
      ctlIndentStyle._lbadd_item(INDENT_STYLE_SYNTAX_INDENT_TEXT);
   }

   _language_form_init_for_options(langID, _language_general_form_get_value, _language_general_form_is_lang_included);

   FILE_EXTENSIONS_LABEL_HEIGHT = _file_extensions_lbl.p_height;
   sizeExtensionsLabel();

   FILE_LANGUAGES_LABEL_HEIGHT = _mixed_languages_label.p_height;
   sizeLanguagesLabel();

   // this is a link - give it a hand
   _ctl_extensionless_files_link.p_mouse_pointer = MP_HAND;
}

_str _language_general_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_beaut_syntax':
      if (LanguageSettings.getBeautifierExpansions(langId) & BEAUT_EXPAND_SYNTAX) {
         value = '1';
      } else {
         value = '0';
      }
      break;

   case '_beaut_alias':
      if (LanguageSettings.getBeautifierExpansions(langId) & BEAUT_EXPAND_ALIAS) {
         value = '1';
      } else {
         value = '0';
      }
      break;

   case '_beaut_edit':
      if (LanguageSettings.getBeautifierExpansions(langId) & BEAUT_EXPAND_ON_EDIT) {
         value = '1';
      } else {
         value = '0';
      }
      break;

   case '_beaut_paste':
      if (LanguageSettings.getBeautifierExpansions(langId) & BEAUT_EXPAND_PASTE) {
         value = '1';
      } else {
         value = '0';
      }
      break;

   case '_mode_name':
      value = LanguageSettings.getModeName(langId);
      break;
   case '_file_extensions_lbl':
      value = get_file_extensions_sorted(langId);
      break;
   case 'ctlTruncateLength':
      truncateLength := LanguageSettings.getTruncateLength(langId);
      // we only display this if it is turned on
      if (truncateLength <= 0) {
         value = '';
      } else {
         value = truncateLength;
      }
      break;
   case 'ctlTruncOn':
   case 'ctlTruncOff':
   case 'ctlTruncAuto':
      // with all of these, we return the name of the control which has the value
      truncateLength = LanguageSettings.getTruncateLength(langId);
      if (truncateLength > 0) {
         value = 'ctlTruncOn';
      } else if (truncateLength < 0) {
         value = 'ctlTruncAuto';
      } else {
         value = 'ctlTruncOff';
      }
      break;
   case 'ctlBoundsStart':
      bounds := LanguageSettings.getBounds(langId);
      parse bounds with auto boundsStart .;
      if (isinteger(boundsStart) && boundsStart >= 0) {
         value = boundsStart;
      } else value = '';
      break;
   case 'ctlBoundsEnd':
      bounds = LanguageSettings.getBounds(langId);
      parse bounds with . auto boundsEnd .;
      if (isinteger(boundsEnd) && boundsEnd >= 0) {
         value = boundsEnd;
      } else value = '';
      break;
   case 'ctlBoundsOn':
   case 'ctlBoundsOff':
      bounds = LanguageSettings.getBounds(langId);
      parse bounds with boundsStart .;
      value = (isinteger(boundsStart) && boundsStart >= 0) ? 'ctlBoundsOn' : 'ctlBoundsOff';
      break;
   case 'ctlcaps':
      value = (int)(LanguageSettings.getCaps(langId) == CM_CAPS_AUTO);
      break;
   case '_menu_list':
      value = LanguageSettings.getMenuIfNoSelection(langId);
      break;
   case '_selection_menu_list':
      value = LanguageSettings.getMenuIfSelection(langId);
      break;
   case '_beginend_pairs':
      value = LanguageSettings.getBeginEndPairs(langId);
      break;
   case '_word_chars':
      value = _prepare_word_chars(LanguageSettings.getWordChars(langId));
      break;
   case 'ctlIndent':
   case 'ctlReindentAlways':
   case 'ctlReinent':
      smartTab := LanguageSettings.getSmartTab(langId);
      if (smartTab < 0) smartTab = -smartTab;

      // radio button set - return the control which has the value
      switch (smartTab) {
      case VSSMARTTAB_INDENT:
         value = 'ctlIndent';
         break;
      case VSSMARTTAB_MAYBE_REINDENT_STRICT:
      case VSSMARTTAB_MAYBE_REINDENT:
         value = 'ctlReindent';
         break;
      case VSSMARTTAB_ALWAYS_REINDENT:
         value = 'ctlReindentAlways';
         break;
      }
      break;
   case 'ctlReindentStrict':
      smartTab = LanguageSettings.getSmartTab(langId);
      if (smartTab < 0) smartTab = -smartTab;

      value = (smartTab == VSSMARTTAB_MAYBE_REINDENT_STRICT);
      break;
   case 'ctlInsertRealIndent':
      value = (int)LanguageSettings.getInsertRealIndent(langId);
      break;
   case 'ctlBackspaceUnindent':
      value = LanguageSettings.getBackspaceUnindents(langId);
      break;
   case '_smartp':
      value = LanguageSettings.getSmartPaste(langId);
      break;
   case 'ctlIndentStyle':
      value = LanguageSettings.getIndentStyle(langId);
      switch (value) {
      case INDENT_NONE:
         value = INDENT_STYLE_NONE_TEXT;
         break;
      case INDENT_AUTO:
         value = INDENT_STYLE_AUTO_TEXT;
         break;
      case INDENT_SMART:
      default:
         value = INDENT_STYLE_SYNTAX_INDENT_TEXT;
         break;
      }
      break;
   }

   return value;
}

boolean _language_general_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctlcaps':
      // we only check this for disabling on the form
      if (!allLangsExclusion) {
         included = isAutoCapsEnabled(langId);
      }
      break;
   case '_menu_list':
   case 'ctllabel2':
      // we only exclude this for AL, not for disabling on the form
      if (allLangsExclusion) {
         included = !(_LanguageInheritsFrom('grep', langId) || _LanguageInheritsFrom('process', langId));
      }
      break;
   case '_selection_menu_list':
   case 'label3':
      // we only exclude this for AL, not for disabling on the form
      if (allLangsExclusion) {
         included = !(_LanguageInheritsFrom('grep', langId));
      }
      break;
   case '_beginend_pairs':
   case 'ctlBeginEndPairsLabel':
      // HTML,C,E,CS extensions do not support BEGIN/END pairs.  They
      // use a hook function.
      included = !(_FindLanguageCallbackIndex('_%s_find_matching_word', langId));
      break;
   case 'ctlBackspaceUnindent':
      included = !(_LanguageInheritsFrom(FUNDAMENTAL_LANG_ID, langId));
      break;
   case 'ctlIndentStyle':
      if (allLangsExclusion) {
         included = !(_LanguageInheritsFrom(FUNDAMENTAL_LANG_ID, langId));
      }
      break;
   case 'ctlLeadingBlanksTab':
      // this exclusion will apply to the whole frame, so we go by the group control name,
      // which is then applied to the rest of the group
      included = false;

      keytab := LanguageSettings.getKeyTableName(langId);
      if ((_FindLanguageCallbackIndex('%s_smartpaste', langId) != 0) && keytab != '') {
         index := find_index(keytab, EVENTTAB_TYPE);
         command := name_name(eventtab_index(index, index, event2index(TAB)));
         if (command=='smarttab' || command=='c-tab' || command=='gnu-ctab' ||
             _is_smarttab_supported(langId)) {
            included = true;
         }
      }
      break;
   case '_smartp':
      included = (_FindLanguageCallbackIndex('%s_smartpaste', langId) != 0);
      break;
      /*
   case '_minimum_expandable':
   case '_minimum_expandable_label':
   case '_minimum_expandable_spinner':
      included = !(_LanguageInheritsFrom('html', langId) || _LanguageInheritsFrom('xml', langId) || _LanguageInheritsFrom('dtd', langId));
      break;
      */
   }

   return included;
}

boolean _language_general_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
   
      if (_mode_name.p_visible && _mode_name.p_enabled) {
         new_mode_name := _mode_name.p_text;        //Get Mode Name
         if (new_mode_name == '') {
            _message_box('Please specify a mode name and at least one extension for this language.');
            return false;
         }
      
         if (_Modename2LangId(new_mode_name) != '' && _Modename2LangId(new_mode_name) != langID) {
            _message_box('The mode 'new_mode_name' already exists.  Please specify a unique mode name for this language.');
            return false;
         }
      
         if (pos(',', new_mode_name)) {
            _message_box('Mode names may not contain commas.');
            return false;
         }
      }
      
      /*
      // verify minimum expandable keywords
      if (!validateLangIntTextBox(_minimum_expandable.p_window_id)) {
         return false;
      }
      */

      // validate begin/end pairs
      beginEndText := '';
      if (_language_form_control_needs_validation(_beginend_pairs.p_window_id, beginEndText)) {
         if (HasMultipleSemiColons(beginEndText)) {
            _beginend_pairs._text_box_error("This string can not contain multiple semi-colons");
            return false;
         }
      }
   
      // validate word chars
      wordCharsText := '';
      if (_language_form_control_needs_validation(_word_chars.p_window_id, wordCharsText)) {
         new_word_chars := _word_chars.p_text;
         if (_check_word_chars(new_word_chars)) {
            p_window_id =  _word_chars;
            _set_sel(1, length(_word_chars.p_text) + 1);
            _set_focus();
            return false;
         }
      }
   
      // truncation
      if (!validateLangIntTextBox(ctlTruncateLength.p_window_id)) {
         return false;
      }
   
      // bounds
      text := '';
      validateBoundsStart := _language_form_control_needs_validation(ctlBoundsStart.p_window_id, text);
      if (!validateLangIntTextBox(ctlBoundsStart.p_window_id)) {
         return false;
      }
   
      validateBoundsEnd := _language_form_control_needs_validation(ctlBoundsEnd.p_window_id, text);
      if (!validateLangIntTextBox(ctlBoundsEnd.p_window_id)) {
         return false;
      }
   
      if (validateBoundsStart || validateBoundsEnd) {
         if (isinteger(ctlBoundsStart.p_text) && isinteger(ctlBoundsEnd.p_text) && ctlBoundsStart.p_text > ctlBoundsEnd.p_text) {
            ctlBoundsStart._text_box_error("The starting bounds must be less than the ending bounds.");
            return false;
         }
      }
   }

   // we made it all the way through all the validation
   return true;
}

void _language_general_form_restore_state()
{
   langID := _get_language_form_lang_id();
   if (langID != ALL_LANGUAGES_ID) {
      // check for auto CAPS
      ctlcaps.p_enabled = isAutoCapsEnabled(langID);
   
      // see if this has changed any
      _file_extensions_lbl.p_caption = get_file_extensions_sorted(langID);

      // get and sort list of referenced languages
      modeList := _LangId2Modename(langID);
      langList := LanguageSettings.getReferencedInLanguageIDs(langID);
      foreach (auto refLangID in langList) {
         mode := _LangId2Modename(refLangID);
         if (mode == "") continue;
         if (modeList._length() > 0) modeList :+= ", ";
         modeList :+= mode;
      }
      _mixed_languages_label.p_caption = modeList;
   }

   _language_form_restore_state(_language_general_form_get_value, 
                                _language_general_form_is_lang_included);
}

boolean _language_general_form_apply()
{
   _language_form_apply(_language_general_form_apply_control);

   return true;
}

_str _language_general_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   switch (controlName) {
   case '_beaut_syntax':
      updateKey = '';
      updateValue = '';
      if (value != 0) {
         LanguageSettings.setBeautifierExpansions(langId, BEAUT_EXPAND_SYNTAX | LanguageSettings.getBeautifierExpansions(langId));
      } else {
         LanguageSettings.setBeautifierExpansions(langId, ~BEAUT_EXPAND_SYNTAX & LanguageSettings.getBeautifierExpansions(langId));
      }
      break;

   case '_beaut_alias':
      updateKey = '';
      updateValue = '';
      if (value != 0) {
         LanguageSettings.setBeautifierExpansions(langId, BEAUT_EXPAND_ALIAS | LanguageSettings.getBeautifierExpansions(langId));
      } else {
         LanguageSettings.setBeautifierExpansions(langId, ~BEAUT_EXPAND_ALIAS & LanguageSettings.getBeautifierExpansions(langId));
      }
      break;

   case '_beaut_edit':
      updateKey = '';
      updateValue = '';
      if (value != 0) {
         LanguageSettings.setBeautifierExpansions(langId, BEAUT_EXPAND_ON_EDIT | LanguageSettings.getBeautifierExpansions(langId));
      } else {
         LanguageSettings.setBeautifierExpansions(langId, ~BEAUT_EXPAND_ON_EDIT & LanguageSettings.getBeautifierExpansions(langId));
      }
      break;

   case '_beaut_paste':
      updateKey = '';
      updateValue = '';
      if (value != 0) {
         LanguageSettings.setBeautifierExpansions(langId, BEAUT_EXPAND_PASTE | LanguageSettings.getBeautifierExpansions(langId));
      } else {
         LanguageSettings.setBeautifierExpansions(langId, ~BEAUT_EXPAND_PASTE & LanguageSettings.getBeautifierExpansions(langId));
      }
      break;

   case '_mode_name':
      oldModeName := LanguageSettings.getModeName(langId);
      scheduleModeNameForRenaming(oldModeName, value);

      updateKey = MODE_NAME_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setModeName(langId, value);
      break;
   case 'ctlTruncateLength':
      updateKey = TRUNCATE_LENGTH_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setTruncateLength(langId, (int)value);
      break;
   case 'ctlTruncOn':
      // don't do anything, it will be handled by the call to set ctlTruncateLength
      break;
   case 'ctlTruncOff':
      updateKey = TRUNCATE_LENGTH_UPDATE_KEY;
      updateValue = 0;

      LanguageSettings.setTruncateLength(langId, 0);
      break;
   case 'ctlTruncAuto':
      updateKey = TRUNCATE_LENGTH_UPDATE_KEY;
      updateValue = -1;

      LanguageSettings.setTruncateLength(langId, -1);
      break;
   case 'ctlBoundsStart':
      oldBounds := LanguageSettings.getBounds(langId);
      parse oldBounds with auto boundsStart auto boundsEnd;

      newBounds := strip(value) ' ' boundsEnd;

      updateKey = BOUNDS_UPDATE_KEY;
      updateValue = newBounds;

      LanguageSettings.setBounds(langId, newBounds);   
      break;
   case 'ctlBoundsEnd':
      oldBounds = LanguageSettings.getBounds(langId);
      parse oldBounds with boundsStart boundsEnd;

      newBounds = boundsStart ' 'strip(value);

      updateKey = BOUNDS_UPDATE_KEY;
      updateValue = newBounds;

      LanguageSettings.setBounds(langId, newBounds);   
      break;
   case 'ctlBoundsOn':
      // don't do anything here, it will be handled by the call to apply ctlBoundsStart and ctlBoundsEnd
      break;
   case 'ctlBoundsOff':
      updateKey = BOUNDS_UPDATE_KEY;
      updateValue = '';

      LanguageSettings.setBounds(langId, '');   
      break;
   case 'ctlcaps':
      updateKey = CAPS_UPDATE_KEY;
      updateValue  = (value) ? CM_CAPS_AUTO : CM_CAPS_OFF;

      LanguageSettings.setCaps(langId, (int)updateValue);
      break;
   case '_menu_list':
      LanguageSettings.setMenuIfNoSelection(langId, value);
      break;
   case '_selection_menu_list':
      LanguageSettings.setMenuIfSelection(langId, value);
      break;
   case '_beginend_pairs':
      LanguageSettings.setBeginEndPairs(langId, strip(value));
      break;
   case '_word_chars':
      updateKey = WORD_CHARS_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setWordChars(langId, value);
      break;
   case 'ctlIndent':
      LanguageSettings.setSmartTab(langId, VSSMARTTAB_INDENT);
      break;
   case 'ctlReindentAlways':
      LanguageSettings.setSmartTab(langId, VSSMARTTAB_ALWAYS_REINDENT);
      break;
   case 'ctlReindent':
      LanguageSettings.setSmartTab(langId, VSSMARTTAB_MAYBE_REINDENT);
      break;
   case 'ctlReindentStrict':
      if ((int)value) {
         LanguageSettings.setSmartTab(langId, VSSMARTTAB_MAYBE_REINDENT_STRICT);
      }
      break;
   case 'ctlInsertRealIndent':
      LanguageSettings.setInsertRealIndent(langId, value != 0);
      break;
   case 'ctlBackspaceUnindent':
      LanguageSettings.setBackspaceUnindents(langId, (value != 0));
      break;
   case '_smartp':
      LanguageSettings.setSmartPaste(langId, (value != 0));
      break;
   case 'ctlIndentStyle':
      switch (value) {
      case INDENT_STYLE_NONE_TEXT:
         updateValue = INDENT_NONE;
         break;
      case INDENT_STYLE_AUTO_TEXT:
         updateValue = INDENT_AUTO;
         break;
      case INDENT_STYLE_SYNTAX_INDENT_TEXT:
      default:
         updateValue = INDENT_SMART;
         break;
      }
      updateKey = INDENT_STYLE_UPDATE_KEY;
      LanguageSettings.setIndentStyle(langId, (int)updateValue);
      break;
   }

   return updateKey' 'updateValue;
}

boolean isAutoCapsEnabled(_str langId)
{
   // we need to see if our auto caps is commented out
   cs := get_unsaved_lexer_case_sensitivity_for_langId(langId);
   if (cs != '') {
      return (cs == '0');
   }

   // we haven't been messing with the color coding, so we can just look 
   // at the saved lexer name
   lexer := LanguageSettings.getLexerName(langId);

   if (lexer == '') return true;

   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   p_lexer_name = lexer;
   lc := p_EmbeddedCaseSensitive;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   return !lc;
}

#endregion Options Dialog Helper Functions

void _language_general_form.on_destroy()
{
   _language_form_on_destroy();
}

void ctlIndent.lbutton_up()//_html_extform.ctl_XW_autoSymbolTrans_button
{
   ctlReindentStrict.p_value = 0;
   ctlReindentStrict.p_enabled = false;
}

void ctlReindentAlways.lbutton_up()
{
   ctlReindentStrict.p_value = 0;
   ctlReindentStrict.p_enabled = false;
}

void ctlReindent.lbutton_up()
{
   ctlReindentStrict.p_enabled = ctlReindent.p_enabled;
   ctlReindentStrict.p_value = 0;
}

/**
 * Initialize the checkbox "_smartp" with the correct value
 * for SmartPaste&reg;, and disable the check box if other
 * options are not correctly set.
 *
 * @param ext    file extension
 * @param smart_indent
 *               value for smart indent
 * @param syntax_indent
 *               value for syntax indent
 */
void init_smartpaste_option(_str smart_indent, _str syntax_indent)
{
   langId := _get_language_form_lang_id();

   // we don't mess with this for All Languages
   if (langId == ALL_LANGUAGES_ID) return;

   if (SMARTPASTE_INDEX == '') {
      SMARTPASTE_INDEX = _FindLanguageCallbackIndex('%s_smartpaste', langId);
   }
   smartpaste_index := SMARTPASTE_INDEX;

   _smartp.p_enabled=smartpaste_index && (syntax_indent>0 && syntax_indent!='' && smart_indent);
}

void _ctl_edit_extensions.lbutton_up()
{
   _str a[];
   split(_file_extensions_lbl.p_caption, ' ', a);
   langID := _get_language_form_lang_id();
   mode := _LangId2Modename(langID);

   result := show('-modal -xy _list_editor_form',
                  mode' File Extensions',
                  'Extensions for 'mode':',
                  a,
                  validate_new_extension_callback, 
                  '',
                  'File Extensions dialog',
                  true);

   if (result :!= '') {
      // result is an array - we need to check for any extensions that were deleted
      _add_delete_extensions(langID, a, _param1);
      _file_extensions_lbl.p_caption = get_file_extensions(langID);

      _config_modify_flags(CFGMODIFY_DEFDATA);
   }

}

void _ctl_edit_languages.lbutton_up()
{
   _str mode;
   _str origList = _mixed_languages_label.p_caption;
   _str a[];
   split(origList, ',', a);
   for (i:=0; i<a._length(); i++) {
      a[i] = strip(a[i]);
   }

   langID := _get_language_form_lang_id();
   mode = _LangId2Modename(langID);

   result := show('-modal -xy _list_editor_form',
                  mode' Referenced in Languages',
                  ' Languages referencing 'mode':',
                  a,
                  validate_new_modename_callback, 
                  '',
                  'Referenced in Languages dialog',
                  true, null, MODENAME_ARG);

   if (result :!= '') {
      a._makeempty();
      foreach (auto refMode in _param1) {
         a[a._length()] = refMode;
      }
      a._sort();
      _aremove_duplicates(a,false);

      modeList := _LangId2Modename(langID);
      langList := "";
      for (i=0; i<a._length(); i++) {
         if (a[i] == "" || a[i]==mode) continue;
         if (i > 0) langList :+= " ";
         langList :+= _Modename2LangId(a[i]);
         modeList :+= ", ";
         modeList :+= a[i];
      }

      if (modeList != origList) {
         LanguageSettings.setReferencedInLanguageIDs(langID, langList);
         _mixed_languages_label.p_caption = modeList;
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   }
}

/**
 * Resizes the File extensions label.  Some languages have a
 * long list of extensions and the list can get unruly. 
 */
static void sizeExtensionsLabel()
{
   if (!_file_extensions_lbl.p_visible) return;

   if (_file_extensions_lbl.p_auto_size) {
      // see how long it is, it might be a bit crazy
      targetWidth := 1.5 * _beginend_pairs.p_width;
      if (_file_extensions_lbl.p_width > targetWidth) {
         linesNeeded := ceiling((double)_file_extensions_lbl.p_width / targetWidth);
         _file_extensions_lbl.p_auto_size = false;
         _file_extensions_lbl.p_word_wrap = true;

         heightAdded := (FILE_EXTENSIONS_LABEL_HEIGHT * linesNeeded) - _file_extensions_lbl.p_height;
         _file_extensions_lbl.p_height += heightAdded;
         _file_extensions_lbl.p_width = (int)targetWidth;

         // now shift everything down
         nextControl := _file_extensions_lbl.p_next;
         while (nextControl.p_y > _file_extensions_lbl.p_y) {
            nextControl.p_y += heightAdded;
            nextControl = nextControl.p_next;
         }

         // refresh the control
         text := _file_extensions_lbl.p_caption;
         _file_extensions_lbl.p_caption = "";
         _file_extensions_lbl.p_caption = text;
      }
   }
}

/**
 * Resizes the File extensions label.  Some languages have a long list of 
 * extensions and the list can get unruly. 
 */
static void sizeLanguagesLabel()
{
   if (!_mixed_languages_label.p_visible) return;

   if (_mixed_languages_label.p_auto_size) {
      // see how long it is, it might be a bit crazy
      targetWidth := 1.5 * _beginend_pairs.p_width;
      if (_mixed_languages_label.p_width > targetWidth) {
         linesNeeded := ceiling((double)_mixed_languages_label.p_width / targetWidth);
         _mixed_languages_label.p_auto_size = false;
         _mixed_languages_label.p_word_wrap = true;

         heightAdded := (FILE_LANGUAGES_LABEL_HEIGHT * linesNeeded) - _mixed_languages_label.p_height;
         _mixed_languages_label.p_height += heightAdded;
         _mixed_languages_label.p_width = (int)targetWidth;

         // now shift everything down
         nextControl := _mixed_languages_label.p_next;
         while (nextControl.p_y > _mixed_languages_label.p_y) {
            nextControl.p_y += heightAdded;
            nextControl = nextControl.p_next;
         }

         // refresh the control
         text := _mixed_languages_label.p_caption;
         _mixed_languages_label.p_caption = "";
         _mixed_languages_label.p_caption = text;
      }
   }
}

void _add_delete_extensions(_str langId, _str origList[], _str modList[])
{
   // sort both lists
   origList._sort();
   modList._sort();

   int i;
   oIndex := 0;
   mIndex := 0;
   _str orig, mod;
   while (oIndex < origList._length() && mIndex < modList._length()) {
      orig = origList[oIndex];
      mod = modList[mIndex];

      if (orig == mod) {            // everything is fine
         ++oIndex;
         ++mIndex;
      } else if (orig < mod) {      // something was deleted
         while (orig < mod && oIndex < origList._length()) {
            // delete the extension orig
            _DeleteExtension(orig);

            ++oIndex;
            if (oIndex < origList._length()) {
               orig = origList[oIndex];
            }
         }
      } else {                      // something was added
         while (orig > mod && mIndex < modList._length()) {
            mod = strip(mod);
            if (pos(" ",mod) > 0) {
               _message_box("Extension " mod " ignored.  ":+
                              "Extensions must not contain whitespace.");
            } else {
               _SetExtensionReferTo(mod, langId);
            }

            ++mIndex;
            if (mIndex < modList._length()) {
               mod = modList[mIndex];
            }
         }
      }
   }

   // we don't know why we stopped - if we still have stuff to look at 
   // in the original list, they all get deleted
   while (oIndex < origList._length()) {
      orig = origList[oIndex];
      _DeleteExtension(orig);
      ++oIndex;
   }

   while (mIndex < modList._length()) {
      mod = modList[mIndex];
      _SetExtensionReferTo(mod, langId);
      ++mIndex;
   }
}

static _str validate_new_extension_callback()
{
   // prompt for name, check for duplicate, and add to list
   result := show("-modal _textbox_form",
                  "Enter the new extension",
                  0,
                  "",
                  "",
                  "",
                  "",
                  "Extension:" "" );
   if (result == "") return '';        // user cancelled operation
   else {
      // check if this extension already points to something else
      newExt := _param1;
      new_index := find_index('def-lang-for-ext-'newExt, MISC_TYPE);
      if (new_index) {
         // make sure user wants to make this change
         currentLang := _LangId2Modename(name_info(new_index));
         if (currentLang != '') {
            result = _message_box('The extension 'newExt' is already associated with 'currentLang'.  Do you wish to continue?', 'Refer Extension', MB_YESNO | MB_ICONEXCLAMATION);
            if (result == IDNO) return '';
         }
      } 

      return newExt;
   }
}

static _str validate_new_modename_callback()
{
   // get all the language mode names
   _str modeNames[];
   index := name_match("def-language-",1,MISC_TYPE);
   while (index > 0) {
      lang := substr(name_name(index),14);
      modeNames[modeNames._length()] = _LangId2Modename(lang);
      index = name_match("def-language-",0,MISC_TYPE);
   }

   modeNames._sort();
   _str result = select_tree(modeNames, null, null, null, null, null, null,
                             "Select Language", 0, null, null, true);
   if (result == COMMAND_CANCELLED_RC || result == '') {
      return '';
   }
   return result;
}

void _ctl_extensionless_files_link.lbutton_up()
{
   config('_manage_advanced_file_types_form', 'D');
}

void ctlBoundsOn.lbutton_up()
{
   if (ctlBoundsOn.p_value) {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=1;
   } else {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=0;
   }
}

void ctlTruncOn.lbutton_up()
{
   if (ctlTruncOn.p_value) {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=1;
      if (!isinteger(ctlTruncateLength.p_text) || ctlTruncateLength.p_text<=1) {
         ctlTruncateLength.p_text=72;
      }
   } else {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=0;
   }
}

void ctlcolor_coding.lbutton_up()
{
   modeName := _get_language_form_mode_name();
   showOptionsForModename(modeName, 'Color Coding');
}

_project.lbutton_up()
{
   langID := _get_language_form_lang_id();
   show('-mdi -modal -xy _project_form','.'langID, gProjectExtHandle);
}


#define NOSEL_MENU '_ext_menu_default'
#define SEL_MENU '_ext_menu_default_sel'

static fill_in_menu_list()
{
   int index=name_match('',1,oi2type(OI_MENU));
   while (index) {
      _str menu_name=name_name(index);
      menu_name=stranslate(menu_name,'_','-');
      _lbadd_item(menu_name);
      index=name_match('',0,oi2type(OI_MENU));
   }
   _lbdeselect_all();
   _lbsort();
   _lbtop();
   _lbselect_line();
}

static get_tab_distance(_str tabs)
{
   typeless first="", second="";
   parse tabs with first second .;
   if (second == '') {
      if (substr(first, 1, 1) != '+') {
         return('');
      }
      return(substr(first,2));
   }
   return(second - first);
}

static get_end_tab(_str tabs)
{
   int index = lastpos(' ', tabs);
   _str last_tab = substr(tabs, index + 1);
   if (substr(last_tab, 1, 1) != '+') {
      return('');
   }
   if (isinteger(substr(last_tab,2))) {
      return(substr(last_tab,2));
   }
}

defeventtab _language_word_wrap_form;

#region Options Dialog Helper Functions

void _language_word_wrap_form_init_for_options(_str langID)
{
   _language_form_init_for_options(langID, _language_word_wrap_form_get_value, 
                                   _language_word_wrap_form_is_lang_included);
}

_str _language_word_wrap_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'text1':
      margins := LanguageSettings.getMargins(langId);
      parse margins with auto leftMargin . ;
      value = leftMargin;
      break;
   case 'text2':
      margins = LanguageSettings.getMargins(langId);
      parse margins with . auto rightMargin . ;
      value = rightMargin;
      break;
   case 'text3':
      margins = LanguageSettings.getMargins(langId);
      parse margins with leftMargin . auto para;
      if (para == '') para = leftMargin;
      value = para;
      break;
   case '_left_and_respace':
   case '_left':
   case '_justified':
      wordWrapStyle := LanguageSettings.getWordWrapStyle(langId);

      if (wordWrapStyle & JUSTIFY_WWS) {
         value = '_justified';
      } else if (wordWrapStyle & STRIP_SPACES_WWS) {
         value = '_left_and_respace';
      } else {
         value = '_left';
      }
      break;
   case '_one_space':
      wordWrapStyle = LanguageSettings.getWordWrapStyle(langId);
      value = (wordWrapStyle & ONE_SPACE_WWS) ? 1 : 0;
      break;
   case '_word_wrap':
      wordWrapStyle = LanguageSettings.getWordWrapStyle(langId);
      value = (wordWrapStyle & WORD_WRAP_WWS) ? 1 : 0;
      break;
   case 'ctlsoftwrap':
      value = (int)LanguageSettings.getSoftWrap(langId);
      break;
   case 'ctlbreakonword':
      value = (int)LanguageSettings.getSoftWrapOnWord(langId);
      break;
   }

   return value;
}

boolean _language_word_wrap_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case '_word_wrap':
      included = !XW_isSupportedLanguage(langId);
      break;
   }

   return included;
}

boolean _language_word_wrap_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      
      // validate the margins, maybe
      typeless leftMargin;
      validateLeft := _language_form_control_needs_validation(text1.p_window_id, leftMargin);
      if (!validateLangIntTextBox(text1.p_window_id, 1, MAX_LINE)) {
         return false;
      }
   
      typeless rightMargin;
      validateRight := _language_form_control_needs_validation(text2.p_window_id, rightMargin);
      if (!validateLangIntTextBox(text2.p_window_id, 1, MAX_LINE)) {
         return false;
      }
   
      if (validateLeft || validateRight) {
         // we have to check if they are integers again - they are occasionally blank on All Languages
         if (isinteger(leftMargin) && isinteger(rightMargin)) {
            if (leftMargin + 2 > rightMargin) {
               text1._text_box_error("The left margin must be less than the right margin.");
               return false;
            }
         }
      }
   
      if (!validateLangIntTextBox(text3.p_window_id, 1, MAX_LINE)) {
         return false;
      }
   }

   return true;
}

void _language_word_wrap_form_restore_state()
{
   _language_form_restore_state(_language_word_wrap_form_get_value, _language_word_wrap_form_is_lang_included);
}

boolean _language_word_wrap_form_apply()
{
   _language_form_apply(_language_word_wrap_form_apply_control);

   return true;
}

_str _language_word_wrap_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   oldValue := 0;
   newValue := 0;

   switch (controlName) {
   case 'text1':
      oldMargins := LanguageSettings.getMargins(langId);
      parse oldMargins with auto leftMargin auto rightMargin auto para;

      newMargins := value' 'rightMargin' 'para;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case 'text2':
      oldMargins = LanguageSettings.getMargins(langId);
      parse oldMargins with leftMargin rightMargin para;

      newMargins = leftMargin' 'value' 'para;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case 'text3':
      oldMargins = LanguageSettings.getMargins(langId);
      parse oldMargins with leftMargin rightMargin para;

      newMargins = leftMargin' 'rightMargin' 'value;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case '_left_and_respace':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) {
         newValue = oldValue | STRIP_SPACES_WWS;
         newValue = newValue & ~JUSTIFY_WWS;
      } 

      if (newValue != oldValue) {
         updateKey = WORD_WRAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setWordWrapStyle(langId, newValue);
      }
      break;
   case '_one_space':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) newValue = oldValue | ONE_SPACE_WWS;
      else newValue = oldValue & ~ONE_SPACE_WWS;

      if (newValue != oldValue) {
         updateKey = WORD_WRAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setWordWrapStyle(langId, newValue);
      }
      break;
   case '_left':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) {
         newValue = oldValue & ~JUSTIFY_WWS;
         newValue = newValue & ~STRIP_SPACES_WWS;
      } 

      if (newValue != oldValue) {
         updateKey = WORD_WRAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setWordWrapStyle(langId, newValue);
      }
      break;
   case '_justified':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) {
         newValue = oldValue | JUSTIFY_WWS;
         newValue = newValue & ~STRIP_SPACES_WWS;
      } 

      if (newValue != oldValue) {
         updateKey = WORD_WRAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setWordWrapStyle(langId, newValue);
      }
      break;
   case '_word_wrap':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) {
         newValue = oldValue | WORD_WRAP_WWS;
      } else {
         newValue = oldValue & ~WORD_WRAP_WWS;
      }

      if (newValue != oldValue) {
         updateKey = WORD_WRAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setWordWrapStyle(langId, newValue);
      }
      break;
   case 'ctlsoftwrap':
      updateKey = SOFT_WRAP_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setSoftWrap(langId, (int)value != 0);
      break;
   case 'ctlbreakonword':
      updateKey = SOFT_WRAP_ON_WORD_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setSoftWrapOnWord(langId, (int)value != 0);
      break;
   }

   return updateKey' 'updateValue;
}

#endregion Options Dialog Helper Functions

void _language_word_wrap_form.on_destroy()
{
   _language_form_on_destroy();
}

void ctl_margin_color.lbutton_up()
{
   typeless color = show_color_picker(p_backcolor);
   if (color != COMMAND_CANCELLED_RC) {
      p_backcolor = color;
   }
}

void _justified.lbutton_up()
{
   _one_space.p_enabled = 0;
}

void _left.lbutton_up()
{
   _one_space.p_enabled = 0;
}

void _left_and_respace.lbutton_up()
{
   _one_space.p_enabled = 1;
}

defeventtab _language_comments_form;

#region Options Dialog Helper Functions

void _language_comments_form_init_for_options(_str langID)
{
   // this is only available for c
   if (langID != 'c') {
      ctl_auto_xmldoc_comment.p_visible = false;
      shift := ctl_auto_xmldoc_comment.p_y - ctl_auto_doc_comment.p_y;

      ctl_editDocCommentAlias.p_y -= shift;
      ctl_auto_insert_leading_asterick.p_y -= shift;
      ctlframe8.p_height -= shift;

      ctlframe15.p_y -= shift;
      ctlframe16.p_y -= shift;
   }

   // we disable a bunch of stuff for all langs
   if (langID == ALL_LANGUAGES_ID) {
      ctlframe2.p_visible = ctlframe3.p_visible = false;

      // move everything over now
      ctl_auto_close_block.p_x = ctlframe8.p_x = ctlframe15.p_x = ctlframe16.p_x = ctlframe2.p_x;

      // remove the "affects all languages" tag
      ctl_auto_close_block.p_caption = "Automatically close &block comments";

      ctl_editDocCommentAlias.p_visible = false;
      heightDiff := ctl_editDocCommentAlias.p_height + 120;
      ctl_auto_insert_leading_asterick.p_y -= heightDiff;

      ctlframe8.p_height -= heightDiff;
      ctlframe15.p_y -= heightDiff;
      ctlframe16.p_y -= heightDiff;
   } 

   _language_form_init_for_options(langID, _language_comments_form_get_value, 
                                   _language_comments_form_is_lang_included);

   // we load and apply these comment settings separately.  They are not included 
   // in ALL LANGUAGES, and they do file i/o every time each one is set - therefore, 
   // it is a terrible idea to set them individually in a callback
   if (langID != ALL_LANGUAGES_ID) {
      // load up the left side of the page, which is not included in ALL LANGUAGES
      BlockCommentSettings_t p;
      getLangCommentSettings(langID, p);

      _ctl_tlc.p_text = p.tlc;
      _ctl_thside.p_text = p.thside;
      _ctl_trc.p_text = p.trc;
      _ctl_lvside.p_text = p.lvside;
      _ctl_rvside.p_text = p.rvside;
      _ctl_blc.p_text = p.blc;
      _ctl_bhside.p_text = p.bhside;
      _ctl_brc.p_text = p.brc;
      _ctl_firstline_is_top.p_value = (int)p.firstline_is_top;
      _ctl_lastline_is_bottom.p_value = (int)p.lastline_is_bottom;
      _ctl_left.p_text = p.comment_left;
      _ctl_right.p_text = p.comment_right;

      if (p.mode == START_AT_COLUMN) {
         if ( isinteger(p.comment_col) && p.comment_col>0 ) {
            _ctl_start_column.p_value = 1;
            _ctl_comment_col.p_text = p.comment_col;
         } else {
            p.mode = def_comment_line_mode;
         }
      } else if (p.mode == LEVEL_OF_INDENT) {
         _ctl_level_indent.p_value = 1;
      } else {
         _ctl_left_margin.p_value = 1;
      }

      call_event(_ctl_start_column.p_window_id, LBUTTON_UP);
      call_event(_ctl_firstline_is_top.p_window_id, LBUTTON_UP);
      call_event(_ctl_lastline_is_bottom.p_window_id, LBUTTON_UP);

      // we have to add these settings to the ones we saved
      STRHASHPTR settings = _get_language_form_settings();
      compileCurrentSettings(ctlframe2.p_child, *settings, true);
      compileCurrentSettings(ctlframe3.p_child, *settings, true);
   }
}

_str _language_comments_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'ctl_auto_insert_leading_asterick':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK, langId) ? 1 : 0;
      break;
   case 'ctl_auto_linecomment':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS, langId) ? 1 : 0;
      break;
   case 'ctl_extend_linecomment':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS, langId) ? 1 : 0;
      break;
   case 'ctl_auto_doc_comment':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT, langId) ? 1 : 0;
      break;
   case 'ctl_join_comments':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS, langId) ? 1 : 0;
      break;
   case 'ctl_auto_string':
      value = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS, langId) ? 1 : 0;
      break;
   case 'ctl_auto_close_block':
      value = def_auto_complete_block_comment;
      break;
   case 'ctl_auto_xmldoc_comment':
      value = def_c_xmldoc;
      break;
   }

   return value;
}

boolean _language_comments_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctl_auto_xmldoc_comment':
      included = (langId == 'c');
      break;
   case 'ctlframe8':
   case 'ctlframe16':
      // since these exclusions apply to every control within the groups, we only 
      // call them for the groups
      included = _lang_doc_comments_enabled(langId);
      break;
   case 'ctlframe15':
      // does this language have line comments?
      if (!allLangsExclusion) {
         // since this is more of a temporary exclusion, we only use it for disabling purposes
         lexer_name := _LangId2LexerName(langId);
         if (lexer_name == '') {
            lexer_name = _LangId2Modename(langId);
         }
   
         if (lexer_name != '') {
            _str commentChars[];
            _getLineCommentChars(commentChars, lexer_name);
            included = (commentChars._length() > 0);
         } else included = false;
      }
      break;
   }

   return included;
}

void _language_comments_form_restore_state()
{
   _language_form_restore_state(_language_comments_form_get_value, _language_comments_form_is_lang_included);
}

boolean _language_comments_form_validate(int action)
{
   langID := _get_language_form_lang_id();

   if (langID != ALL_LANGUAGES_ID && action == OPTIONS_APPLYING) {

      if ( _ctl_start_column.p_value ) {
         if (!isinteger(_ctl_comment_col.p_text) || _ctl_comment_col.p_text < 0) {
            _message_box('Invalid comment column');
            p_window_id = _ctl_comment_col;
            _set_sel(1,length(p_text)+1);_set_focus();
            return false;
         } 
      }
   }

   return true;
}

boolean _language_comments_form_apply()
{
   langID := _get_language_form_lang_id();

   if (langID != ALL_LANGUAGES_ID) {

      //Changed this to preserve spaces, expect for trailing
      //spaces on RHS borders. Previous method stripped just trailing
      //from all eight border strings (02/13/06)
      BlockCommentSettings_t curSettings;
      curSettings.tlc    = _ctl_tlc.p_text;
      curSettings.thside = strip(_ctl_thside.p_text, 'B');;
      curSettings.trc    = _ctl_trc.p_text;
      curSettings.lvside = _ctl_lvside.p_text;
      curSettings.rvside = _ctl_rvside.p_text;
      curSettings.blc    = _ctl_blc.p_text;
      curSettings.bhside = strip(_ctl_bhside.p_text, 'B');
      curSettings.brc    = _ctl_brc.p_text;
      curSettings.comment_left  = _ctl_left.p_text;
      curSettings.comment_right = _ctl_right.p_text;
      curSettings.firstline_is_top= (_ctl_firstline_is_top.p_value != 0);
      curSettings.lastline_is_bottom= (_ctl_lastline_is_bottom.p_value != 0);

      curSettings.comment_col = 0;
      if ( _ctl_start_column.p_value ) {
         curSettings.comment_col = (_ctl_comment_col.p_text == '') ? 0 : (int)_ctl_comment_col.p_text;
         curSettings.mode = START_AT_COLUMN;

         if (!isinteger(_ctl_comment_col.p_text) || _ctl_comment_col.p_text < 0) {
            _message_box('Invalid comment column');
            p_window_id = _ctl_comment_col;
            _set_sel(1,length(p_text)+1);_set_focus();
            return false;
         } else curSettings.comment_col = (int)_ctl_comment_col.p_text;

      } else if (_ctl_level_indent.p_value) {
         curSettings.mode = LEVEL_OF_INDENT;
      } else {
         curSettings.mode = LEFT_MARGIN;
      }

      // compare to the original ones
      BlockCommentSettings_t origSettings;
      getLangCommentSettings(langID, origSettings);
      if (curSettings != origSettings) {
         if (saveCommentSettings(langID, curSettings) ) {
            _message_box('Error saving settings for language .'_LangId2Modename(langID));
            return false;
         }

         // Maybe update the lexer settings if the line comment settings have changed.
         _maybe_update_lexer_settings(_LangId2LexerName(langID), origSettings, curSettings);
      }

      // now save these settings since they have already been applied
      STRHASHPTR settings = _get_language_form_settings();
      compileCurrentSettings(ctlframe2.p_child, *settings, true);
      compileCurrentSettings(ctlframe3.p_child, *settings, true);

      // make these invisible so that the _language_general_apply method 
      // won't try and apply these controls
      ctlframe2.p_visible = ctlframe3.p_visible = false;
   }

   _language_form_apply(_language_comments_form_apply_control);

   ctlframe2.p_visible = ctlframe3.p_visible = (langID != ALL_LANGUAGES_ID);

   return true;
}

void _maybe_update_lexer_settings(_str lexername, BlockCommentSettings_t& orig, BlockCommentSettings_t& cur)
{
   if (cur.comment_left != orig.comment_left || cur.comment_right != orig.comment_right) {

      int resp = _message_box("You have made changes to the line comment settings that require " :+
                              "matching changes in the color coding setup for the commenting support " :+
                              "to work.  Make these changes automatically?", 
                              "Update comment settings", 
                              MB_YESNO|MB_ICONQUESTION);

      if (resp == IDNO) {
         return;
      }

      if (cur.comment_left != '') {
         if (cur.comment_right != '') {
            _block_comment_maybe_update_lexer(lexername, cur.comment_left, cur.comment_right);
         } else {
            _line_comment_maybe_update_lexer(lexername, cur.comment_left);
         }
      }
   }
}

void _language_comments_form_apply_control(_str controlName, _str langId, _str value)
{
   checked := (int)value != 0;
   commentFlags := _GetCommentEditingFlags(0, langId);

   flag := 0;
   switch (controlName) {
   case 'ctl_auto_insert_leading_asterick':
      flag = VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK;
      break;
   case 'ctl_auto_linecomment':
      flag = VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS;
      break;
   case 'ctl_extend_linecomment':
      flag = VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS;
      break;
   case 'ctl_auto_doc_comment':
      flag = VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT;
      break;
   case 'ctl_join_comments':
      flag = VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS;
      break;
   case 'ctl_auto_string':
      flag = VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS;
      break;
   case 'ctl_auto_close_block':
      def_auto_complete_block_comment = checked;
      break;
   case 'ctl_auto_xmldoc_comment':
      def_c_xmldoc = checked;
      break;
   }

   if (flag) {
      if (checked) {
         commentFlags |= flag;
      } else {
         commentFlags &= ~flag;
      }
   
      _SetLanguageOption(langId, 'commentediting', commentFlags);
   }

}

#endregion Options Dialog Helper Functions

void _language_comments_form.on_destroy()
{
   // remove the settings we saved for this language
   langID := _get_language_form_lang_id();
   if (langID != null) {
      clearCommentSettings(langID);

      _language_form_on_destroy();
   }
}

void ctl_editDocCommentAlias.lbutton_up()
{
   if (_create_config_path()) {
      message('Unable to find config path.');
      return;
   }

   langID := _get_language_form_lang_id();
   filename := getCWaliasFile(langID);

   // now launch the alias dialog
   typeless result = show('-new -modal _alias_editor_form', filename, false, '/**', DOCCOMMENT_ALIAS_FILE);

   return;
}

/** 
 * The start in column text box and spinner should be disabled 
 * except when the start in column radio button is selected. 
 */
_ctl_start_column.lbutton_up()
{
   _ctl_comment_col.p_enabled = (_ctl_start_column.p_value != 0);
   _ctl_comment_col.p_next.p_enabled=(_ctl_start_column.p_value != 0);
}

_ctl_firstline_is_top.lbutton_up()
{
   _ctl_thside.p_enabled= !_ctl_firstline_is_top.p_value;
}

_ctl_lastline_is_bottom.lbutton_up()
{
   _ctl_bhside.p_enabled= !_ctl_lastline_is_bottom.p_value;
}

ctl_auto_doc_comment.lbutton_up()
{
   ctl_auto_xmldoc_comment.p_enabled = (p_value != 0);
}

defeventtab _language_comment_wrap_form;

#region Options Dialog Helper Functions

/**
 * Determines whether the _ext_comment_wrap_form would be 
 * unavailable for the given mode name. 
 * 
 * @param _str modeName       mode name in question
 * 
 * @return boolean            true if EXcluded, false if 
 *                            included
 */
boolean isLangCommentWrapFormExcludedForMode(_str langId)
{
   // if it's supported, then it's not excluded...
   return (langId != ALL_LANGUAGES_ID && !commentwrap_isSupportedLanguage(langId));
}

void _language_comment_wrap_form_init_for_options(_str langID)
{
   _ctl_vert_line_col_frame.p_visible = (langID != ALL_LANGUAGES_ID);
   if (_ctl_vert_line_col_frame.p_visible) {
      _ctl_vert_line_col_link.p_backcolor = 0x80000022;
      _ctl_vert_line_col_link._minihtml_UseDialogFont();
      _ctl_vert_line_col_link.p_text = 'The vertical line column can also be set on <a href="slickc:config Appearance > General">Tools > Options > Appearance > General.</a>';

      _ctl_vert_line_col_link.p_height *= 10;
      _ctl_vert_line_col_link._minihtml_ShrinkToFit();

      heightDiff := (_ctl_vert_line_col_frame.p_height - (_ctl_vert_line_col_link.p_y + _ctl_vert_line_col_link.p_height + _ctl_vert_line_col_link.p_x));
      _ctl_vert_line_col_frame.p_height -= heightDiff;
   }

   _language_form_init_for_options(langID, _language_comment_wrap_form_get_value, 
                                   _language_comment_wrap_form_is_lang_included);

   // change the enable caption for pl1 for preserve trailing comment feature 
   boolean isPL1 = (langID == 'pl1');
   if (isPL1) {
      _ctl_CW_enable_lineblock.p_caption = 'Preserve location of trailing comments';
   } else {
      _ctl_CW_enable_lineblock.p_caption = 'Enable line comment wrap';
   }

   CW_enable_lbutton_up();
}

_str _language_comment_wrap_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_ctl_CW_enable_commentwrap':
      value = _GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP, langId) ? 1 : 0;
      break;
   case '_ctl_CW_enable_block':
      value = _GetCommentWrapFlags(CW_ENABLE_BLOCK_WRAP, langId) ? 1 : 0;
      break;
   case '_ctl_CW_enable_lineblock':
      value = _GetCommentWrapFlags(CW_ENABLE_LINEBLOCK_WRAP, langId) ? 1 : 0;
      break;
   case '_ctl_CW_enable_javadoc':
      value = _GetCommentWrapFlags(CW_ENABLE_DOCCOMMENT_WRAP, langId) ? 1 : 0;
      break;
   case '_ctl_CW_auto_override':
      value = _GetCommentWrapFlags(CW_AUTO_OVERRIDE, langId) ? 1 : 0;
      break;
   case '_ctl_CW_javadoc_auto_indent':
      value = _GetCommentWrapFlags(CW_JAVADOC_AUTO_INDENT, langId) ? 1 : 0;
      break;
   case '_ctl_CW_use_fixed_width':
   case '_ctl_CW_use_first_para':
   case '_ctl_CW_use_fixed_margins':
      if (_GetCommentWrapFlags(CW_USE_FIXED_WIDTH, langId)) {
         value = '_ctl_CW_use_fixed_width';
      } else if (_GetCommentWrapFlags(CW_USE_FIRST_PARA, langId)) {
         value = '_ctl_CW_use_first_para';
      } else {
         value = '_ctl_CW_use_fixed_margins';
      }
      break;
   case '_ctl_CW_fixed_width_size':
      value = _GetCommentWrapFlags(CW_FIXED_WIDTH_SIZE, langId);
      break;
   case '_ctl_CW_right_margin':
      value = _GetCommentWrapFlags(CW_RIGHT_MARGIN, langId);
      break;
   case '_ctl_CW_max_right_column':
      value = _GetCommentWrapFlags(CW_MAX_RIGHT, langId) ? 1 : 0;
      break;
   case '_ctl_CW_max_right_size':
      value = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN, langId);
      break;
   case '_ctl_CW_max_right_column_dyn':
      value = _GetCommentWrapFlags(CW_MAX_RIGHT_DYN, langId) ? 1 : 0;
      break;
   case '_ctl_CW_max_right_size_dyn':
      value = _GetCommentWrapFlags(CW_MAX_RIGHT_COLUMN_DYN, langId);
      break;
   case '_ctl_CW_match_prev_para':
      value = _GetCommentWrapFlags(CW_MATCH_PREV_PARA, langId) ? 1 : 0;
      break;
   case '_ctl_CW_start_wrapping_from':
      value = _GetCommentWrapFlags(CW_LINE_COMMENT_MIN, langId);
      break;
   }

   return value;
}

boolean _language_comment_wrap_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;
   if (controlName == '_language_comment_wrap_form') {
      included = commentwrap_isSupportedLanguage(langId);
   }

   return included;
}

void _language_comment_wrap_form_restore_state()
{
   _language_form_restore_state(_language_comment_wrap_form_get_value, _language_comment_wrap_form_is_lang_included);
}

boolean _language_comment_wrap_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      
      // gots to validate all those text boxes
      if (!validateLangIntTextBox(_ctl_CW_start_wrapping_from.p_window_id)) {
         return false;
      }
   
      if (!validateLangIntTextBox(_ctl_CW_fixed_width_size.p_window_id)) {
         return false;
      }
   
      if (!validateLangIntTextBox(_ctl_CW_max_right_size.p_window_id)) {
         return false;
      }
   
      if (!validateLangIntTextBox(_ctl_CW_max_right_size_dyn.p_window_id)) {
         return false;
      }
   
      if (!validateLangIntTextBox(_ctl_CW_right_margin.p_window_id)) {
         return false;
      }
   }

   return true;
}

boolean _language_comment_wrap_form_apply()
{
   langID := _get_language_form_lang_id();

   //Clear local hash table of settings.
   XWclearState();

   if (langID != ALL_LANGUAGES_ID) {
      _ClearCommentWrapFlags(langID);
   } else {
      _ClearCommentWrapFlags();
   }

   _language_form_apply(_language_comment_wrap_form_apply_control);

   CW_clearCommentState();

   return true;
}

void _language_comment_wrap_form_apply_control(_str controlName, _str langId, _str value)
{
   flag := 0;
   typeless flagValue;

   switch (controlName) {
   case '_ctl_CW_enable_commentwrap':
      flag = CW_ENABLE_COMMENT_WRAP;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_enable_block':
      flag = CW_ENABLE_BLOCK_WRAP;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_enable_lineblock':
      flag = CW_ENABLE_LINEBLOCK_WRAP;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_enable_javadoc':
      flag = CW_ENABLE_DOCCOMMENT_WRAP;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_auto_override':
      flag = CW_AUTO_OVERRIDE;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_javadoc_auto_indent':
      flag = CW_JAVADOC_AUTO_INDENT;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_use_fixed_width':
   case '_ctl_CW_use_first_para':
   case '_ctl_CW_use_fixed_margins':
      // we have to set each one individually - this will only be called once for 
      // the whole radio button set - for the control with a value of 1
      _SetCommentWrapFlags(CW_USE_FIXED_WIDTH, (controlName == '_ctl_CW_use_fixed_width'), langId);
      _SetCommentWrapFlags(CW_USE_FIRST_PARA, (controlName == '_ctl_CW_use_first_para'), langId);
      _SetCommentWrapFlags(CW_USE_FIXED_MARGINS, (controlName == '_ctl_CW_use_fixed_margins'), langId);
      break;
   case '_ctl_CW_fixed_width_size':
      flag = CW_FIXED_WIDTH_SIZE;
      flagValue = (int)strip(value);
      break;
   case '_ctl_CW_right_margin':
      flag = CW_RIGHT_MARGIN;
      flagValue = (int)strip(value);
      break;
   case '_ctl_CW_max_right_column':
      flag = CW_MAX_RIGHT;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_max_right_size':
      flag = CW_MAX_RIGHT_COLUMN;
      flagValue = (int)strip(value);
      break;
   case '_ctl_CW_max_right_column_dyn':
      flag = CW_MAX_RIGHT_DYN;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_max_right_size_dyn':
      flag = CW_MAX_RIGHT_COLUMN_DYN;
      flagValue = (int)strip(value);
      break;
   case '_ctl_CW_match_prev_para':
      flag = CW_MATCH_PREV_PARA;
      flagValue = (value != 0);
      break;
   case '_ctl_CW_start_wrapping_from':
      flag = CW_LINE_COMMENT_MIN;
      flagValue = (int)strip(value);
      break;
   }

   if (flag) {
      _SetCommentWrapFlags(flag, value, langId);
   }
}

#endregion Options Dialog Helper Functions

void _language_comment_wrap_form.on_destroy()
{
   _language_form_on_destroy();
}

// this same event handler is used for all four "ENABLE" checkboxes at the top of the form
void _ctl_CW_enable_commentwrap.lbutton_up() {
   CW_enable_lbutton_up();
}

// this same event handler is used for all the radio buttons in this group, 
// as well as the "Maximum Right Column" checkboxes
void _ctl_CW_use_fixed_width.lbutton_up() {
   CW_setWidthSubControls();
}

void _ctl_CW_sync_vertical_line.lbutton_up()
{
   if (!(_ctl_CW_enable_block.p_value || _ctl_CW_enable_javadoc.p_value || _ctl_CW_enable_lineblock.p_value || (_ctl_CW_enable_commentwrap.p_value))) {
      return;
   }
   if (_ctl_CW_use_fixed_width.p_value && _ctl_CW_max_right_column.p_value) {
      _default_option('R', strip(_ctl_CW_max_right_size.p_text));
   }
   if (_ctl_CW_use_first_para.p_value && _ctl_CW_max_right_column_dyn.p_value) {
      _default_option('R', strip(_ctl_CW_max_right_size_dyn.p_text));
   }
   if (_ctl_CW_use_fixed_margins.p_value) {
      _default_option('R', strip(_ctl_CW_right_margin.p_text));
   }
   return;
}

/**
 * Only used for PL1, because with PL1 we have one comment wrap 
 * feature available: Preserve location of trailing comments. 
 * 
 */
static void CW_disableSubControls() {
   _ctl_CW_fixed_width_size.p_enabled = false;
   _ctl_CW_javadoc_auto_indent.p_enabled = false;
   _ctl_CW_max_right_column.p_enabled = false;
   _ctl_CW_max_right_column_dyn.p_enabled = false;
   _ctl_CW_max_right_size.p_enabled = false;
   _ctl_CW_max_right_size_dyn.p_enabled = false;
   _ctl_CW_right_margin.p_enabled = false;
   _ctl_CW_auto_override.p_enabled = false;
   _ctl_CW_match_prev_para.p_enabled = false;
   _ctl_CW_use_first_para.p_enabled = false;
   _ctl_CW_use_fixed_margins.p_enabled = false;
   _ctl_CW_use_fixed_width.p_enabled = false;
   _ctl_CW_right_margin_label.p_enabled = false;
   _ctl_CW_fixed_width_spin.p_enabled = false;
   _ctl_CW_max_right_spin.p_enabled = false;
   _ctl_CW_max_right_spin_dyn.p_enabled = false;
   _ctl_CW_right_margin_spin.p_enabled = false;
   _ctl_CW_sync_vertical_line.p_enabled = false;
}

/**
 * Enables the proper controls on comment wrap tab based on the width 
 * determination method chosen.
 */
static void CW_setWidthSubControls() {
   // first we disable all of the sub controls that deal with comment width
   boolean enabled = false;
   _ctl_CW_fixed_width_size.p_enabled     = enabled;
   _ctl_CW_fixed_width_spin.p_enabled     = enabled;
   _ctl_CW_max_right_column.p_enabled     = enabled;
   _ctl_CW_max_right_size.p_enabled       = enabled;
   _ctl_CW_max_right_spin.p_enabled       = enabled;
   _ctl_CW_max_right_column_dyn.p_enabled = enabled;
   _ctl_CW_max_right_size_dyn.p_enabled   = enabled;
   _ctl_CW_max_right_spin_dyn.p_enabled   = enabled;
   _ctl_CW_right_margin_label.p_enabled   = enabled;
   _ctl_CW_right_margin.p_enabled         = enabled;
   _ctl_CW_right_margin_spin.p_enabled    = enabled;
   _ctl_CW_sync_vertical_line.p_enabled   = enabled;

   enabled = true;
   // only do this mess if this section is even enabled
   if (_ctl_CW_use_fixed_width.p_enabled) {
      if (_ctl_CW_use_fixed_width.p_value) {
         // if fixed width is enabled and set to true, we enable these controls
         _ctl_CW_fixed_width_size.p_enabled     = enabled;
         _ctl_CW_fixed_width_spin.p_enabled     = enabled;
         _ctl_CW_max_right_column.p_enabled     = enabled;
   
         enabled = (_ctl_CW_max_right_column.p_value != 0);
         _ctl_CW_sync_vertical_line.p_enabled   = enabled;
         _ctl_CW_max_right_size.p_enabled       = enabled;
         _ctl_CW_max_right_spin.p_enabled       = enabled;
   
      } else if (_ctl_CW_use_fixed_margins.p_value) {
         // if fixed right margin is enabled and set to true, we enable these controls
         _ctl_CW_right_margin_label.p_enabled   = enabled;
         _ctl_CW_right_margin.p_enabled         = enabled;
         _ctl_CW_right_margin_spin.p_enabled    = enabled;
         _ctl_CW_sync_vertical_line.p_enabled   = enabled;
   
      } else if (_ctl_CW_use_first_para.p_value) {
         // if automatic width is enabled and set to true, we enable these controls
         _ctl_CW_max_right_column_dyn.p_enabled = enabled;
   
         enabled = (_ctl_CW_max_right_column_dyn.p_value != 0);
         _ctl_CW_sync_vertical_line.p_enabled   = enabled;
         _ctl_CW_max_right_size_dyn.p_enabled   = enabled;
         _ctl_CW_max_right_spin_dyn.p_enabled   = enabled;
      }
   }
}

void CW_enable_lbutton_up()
{
   enabledAll := _ctl_CW_enable_commentwrap.p_value != 0;
   boolean isPL1 = (_ctl_CW_enable_lineblock.p_caption == 'Preserve location of trailing comments');

   // these top things are enabled based on the very top checkbox
   _ctl_CW_enable_block.p_enabled = enabledAll && !isPL1;
   _ctl_CW_enable_lineblock.p_enabled = enabledAll;
   _ctl_CW_enable_javadoc.p_enabled = enabledAll && !isPL1;
   _ctl_CW_start_wrap_label.p_enabled = _ctl_CW_start_wrapping_from.p_enabled =
      (_ctl_CW_enable_lineblock.p_enabled && _ctl_CW_enable_lineblock.p_value && !isPL1);

   // the javadoc section is enabled based on whether doc comment wrap is turned on
   _ctl_CW_javadoc_auto_indent.p_enabled = enabledAll && _ctl_CW_enable_javadoc.p_value != 0 && !isPL1;

   // the rest of the stuff is enabled based on whether one of 
   // the top three checkboxes are checked
   enabled := (enabledAll && 
               (_ctl_CW_enable_block.p_value != 0 ||
                _ctl_CW_enable_lineblock.p_value != 0 ||
                _ctl_CW_enable_javadoc.p_value != 0));

   // maybe enable these guys...which are kinda on their own
   _ctl_CW_auto_override.p_enabled = enabled;
   _ctl_CW_match_prev_para.p_enabled = enabled;

   // now maybe enable the radio buttons, and it'll all trickle down from there
   _ctl_CW_use_first_para.p_enabled = enabled;
   _ctl_CW_use_fixed_margins.p_enabled = enabled;
   _ctl_CW_use_fixed_width.p_enabled = enabled;

   CW_setWidthSubControls();
   if (isPL1) {
      CW_disableSubControls();
   }
}

const AC_INCLUDE_NONE_CB_TEXT        = "Do not list include files";
const AC_INCLUDE_QUOTED_CB_TEXT      = "List quoted files after typing #include";
const AC_INCLUDE_AFTER_QUOTE_CB_TEXT = "List files after typing \" or <";

const AC_PRESERVE_IDENTIFIER_FOR_ALM = "Preserve for auto list members only";
const AC_PRESERVE_IDENTIFIER         = "Preserve always";
const AC_REPLACE_IDENTIFIER          = "Replace entire identifier";

const AC_SELECTION_METHOD_MANUAL     = "Manually choose completion";
const AC_SELECTION_METHOD_INSERT     = "Insert current completion in file";
const AC_SELECTION_METHOD_UNIQUE     = "Automatically choose unique completion";

defeventtab _language_auto_complete_form;

#define BRACE_LANGUAGES    ' ansic cs c d jsl java m pas awk ch pl tcl as cfscript js phpscript pl1 vera vhd e idl '
#define BRACES_SUPPORTED   _insert.p_user

#region Options Dialog Helper Functions

void _language_auto_complete_form_init_for_options(_str langID)
{
   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_MANUAL);
   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_INSERT);
   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_UNIQUE);

   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_NONE_CB_TEXT);
   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_QUOTED_CB_TEXT);
   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_AFTER_QUOTE_CB_TEXT);

   ctlpreserveidentifier._lbadd_item(AC_PRESERVE_IDENTIFIER_FOR_ALM);
   ctlpreserveidentifier._lbadd_item(AC_PRESERVE_IDENTIFIER);
   ctlpreserveidentifier._lbadd_item(AC_REPLACE_IDENTIFIER);

   _language_form_init_for_options(langID, _language_auto_complete_form_get_value, 
                                   _language_auto_complete_form_is_lang_included);

   // will enable/disable everything based on the top checkbox
   call_event(ctl_auto_complete_frame.p_window_id, LBUTTON_UP);

   // set up the illustration
   ctl_auto_complete_pic_bulb.p_visible = (ctl_auto_complete_show_bulb.p_value != 0);
   ctl_auto_complete_pic_word.p_visible = (ctl_auto_complete_show_word.p_value != 0);

   AutoCompleteShowHideComments();
   AutoCompleteShowHideList();
   AutoCompleteAdjustComments();
   ctl_auto_complete_pic_main.refresh();

   // determine whether this language supports inserting braces
   if (langID == ALL_LANGUAGES_ID) {
      BRACES_SUPPORTED = true;
   } else {
      BRACES_SUPPORTED = false;
      _str list[];
      get_language_inheritance_list(langID, list);
      for (i := 0; i < list._length(); i++) {
         if (pos(' 'list[i]' ', BRACE_LANGUAGES) > 0) {
            BRACES_SUPPORTED = true;
            break;
         }
      }
   }

   call_event(_syntax_expansion.p_window_id, LBUTTON_UP);

   ctlautolistmembers.call_event(ctlautolistmembers,lbutton_up);
}

_str _language_auto_complete_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   flags := AutoCompleteGetOptions(langId);
   codehelpFlags := LanguageSettings.getCodehelpFlags(langId);

   switch (controlName) {
   case '_ctl_blankline':
      value = LanguageSettings.getInsertBlankLineBetweenBeginEnd(langId) ? 1 : 0;
      break;
   case 'ctl_auto_complete_frame':
      value = (flags & AUTO_COMPLETE_ENABLE) ? 1 : 0;
      break;
   case 'ctl_auto_complete_expand_syntax':
      value = (flags & AUTO_COMPLETE_SYNTAX) ? 1 : 0;
      break;
   case 'ctl_auto_complete_keywords':
      value = (flags & AUTO_COMPLETE_KEYWORDS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_expand_alias':
      value = (flags & AUTO_COMPLETE_ALIAS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_symbols':
      value = (flags & AUTO_COMPLETE_SYMBOLS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_locals':
      value = (flags & AUTO_COMPLETE_LOCALS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_members':
      value = (flags & AUTO_COMPLETE_MEMBERS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_current_file':
      value = (flags & AUTO_COMPLETE_CURRENT_FILE) ? 1 : 0;
      break;
   case 'ctl_auto_complete_words':
      value = (flags & AUTO_COMPLETE_WORDS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_arguments':
      value = (flags & AUTO_COMPLETE_LANGUAGE_ARGS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_includes':
      switch (LanguageSettings.getAutoCompletePoundIncludeOption(langId)) {
      case AC_POUND_INCLUDE_QUOTED_ON_SPACE:
         value = AC_INCLUDE_QUOTED_CB_TEXT;
         break;
      case AC_POUND_INCLUDE_ON_QUOTELT:
         value = AC_INCLUDE_AFTER_QUOTE_CB_TEXT;
         break;
      case AC_POUND_INCLUDE_NONE:
      default:
         value = AC_INCLUDE_NONE_CB_TEXT;
         break;
      }
      break;
   case 'ctl_auto_complete_tab_insert':
      value = (flags & AUTO_COMPLETE_TAB_INSERTS_PREFIX) ? 1 : 0;
      break;
   case 'ctl_auto_complete_tab_next':
      value = (flags & AUTO_COMPLETE_TAB_NEXT) ? 1 : 0;
      break;
   case 'ctl_auto_complete_minimum':
      value = AutoCompleteGetMinimumLength(langId);
      break;
   case 'ctl_auto_complete_selection_method':
      if (flags & AUTO_COMPLETE_NO_INSERT_SELECTED) {
         if (flags & AUTO_COMPLETE_UNIQUE) {
            value = AC_SELECTION_METHOD_UNIQUE;
         } else {
            value = AC_SELECTION_METHOD_MANUAL;
         }
      } else {
         value = AC_SELECTION_METHOD_INSERT;
      }
      break;
   case 'ctl_auto_complete_show_bulb':
      value = (flags & AUTO_COMPLETE_SHOW_BULB) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_word':
      value = (flags & AUTO_COMPLETE_SHOW_WORD) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_list':
      value = (flags & AUTO_COMPLETE_SHOW_LIST) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_icons':
      value = (flags & AUTO_COMPLETE_SHOW_ICONS) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_categories':
      value = (flags & AUTO_COMPLETE_SHOW_CATEGORIES) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_prototypes':
      value = (flags & AUTO_COMPLETE_SHOW_PROTOTYPES) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_decl':
      value = (flags & AUTO_COMPLETE_SHOW_DECL) ? 1 : 0;
      break;
   case 'ctl_auto_complete_show_comments':
      value = (flags & AUTO_COMPLETE_SHOW_COMMENTS) ? 1 : 0;
      break;

   case '_syntax_expansion':
      value = LanguageSettings.getSyntaxExpansion(langId);
      break;
   case '_minimum_expandable':
      value = LanguageSettings.getMinimumAbbreviation(langId);
      break;
   case '_surround':
      value = LanguageSettings.getSurroundOptions(langId);
      break;
   case '_expand_alias_on_space':
      value = LanguageSettings.getExpandAliasOnSpace(langId);
      break;

   case 'ctlautolistmembers':
      value = (codehelpFlags & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) ? 1 : 0;
      break;
   case 'ctlCompletionOnSpace':
      value = (codehelpFlags & VSCODEHELPFLAG_SPACE_COMPLETION) ? 1 : 0;
      break;
   case 'ctlSpaceInsertsSpace':
      value = (codehelpFlags & VSCODEHELPFLAG_SPACE_INSERTS_SPACE) ? 1 : 0;
      break;
   case 'ctlEnterAlwaysInserts':
      value = (flags & AUTO_COMPLETE_ENTER_ALWAYS_INSERTS) ? 1 : 0;
      break;
   case 'ctlInsertOpenParen':
      value = (codehelpFlags & VSCODEHELPFLAG_INSERT_OPEN_PAREN) ? 1 : 0;
      break;
   case 'ctlpreserveidentifier':
      preserveFlag := (codehelpFlags & VSCODEHELPFLAG_PRESERVE_IDENTIFIER) != 0;
      replaceFlag := (codehelpFlags & VSCODEHELPFLAG_REPLACE_IDENTIFIER) != 0;
      if (preserveFlag == replaceFlag) {
         value = AC_PRESERVE_IDENTIFIER_FOR_ALM;
      } else if (preserveFlag) {
         value = AC_PRESERVE_IDENTIFIER;
      } else {
         value = AC_REPLACE_IDENTIFIER;
      }
      break;
   case 'ctlautolistvalues':
      value = (codehelpFlags & VSCODEHELPFLAG_AUTO_LIST_VALUES) ? 1 : 0;
      break;
   case 'ctllistmemcasesensitive':
      value = (codehelpFlags & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) ? 1 : 0;
      break;
   case '_insert':
      value = (int)LanguageSettings.getInsertBeginEndImmediately(langId);
      break;

   }

   return value;
}

boolean _language_auto_complete_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctl_auto_complete_includes':
      included = isAutoCompletePoundIncludeSupported(langId);
      break;
   case 'ctl_auto_complete_expand_syntax':
      included = (_FindLanguageCallbackIndex("_%s_get_syntax_completions",langId) != 0);
      break;
   case 'ctl_auto_complete_symbols':
   case 'ctl_auto_complete_members':
   case 'ctl_auto_complete_current_file':
      included = (_istagging_supported(langId));
      break;
   case 'ctl_auto_complete_locals':
      included = (_are_locals_supported(langId));
      break;
   case 'ctl_auto_complete_arguments':
      included = (_FindLanguageCallbackIndex("_%s_autocomplete_get_arguments", langId) != 0);
      break;

   case '_minimum_expandable':
   case '_minimum_expandable_label':
   case '_minimum_expandable_spinner':
      included = !(_LanguageInheritsFrom('html', langId) || _LanguageInheritsFrom('xml', langId) || _LanguageInheritsFrom('dtd', langId));
      break;

   case 'ctlautolistmembers':
      included = (_FindLanguageCallbackIndex("_%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("vs%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("_%s_get_idexp", langId) != 0);
      break;
   case 'ctlCompletionOnSpace':
   case 'ctlSpaceInsertsSpace':
   case 'ctlInsertOpenParen':
   case 'ctlpreserveidentifier':
   case 'cltnavigation':
   case 'ctlignoreforwardclass':
   case 'ctlmouseoverinfo':
   case 'ctlhighlighttag':
   case 'ctllabel1':
   case 'ctllabel2':
      included = (_FindLanguageCallbackIndex("vs%s_list_tags", langId)!=0 ||
                  _FindLanguageCallbackIndex("%s_proc_search", langId)!=0 ||
                  _FindLanguageCallbackIndex("_%s_find_context_tags", langId)!=0 ||
                  _FindLanguageCallbackIndex("_%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("vs%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("_%s_get_idexp", langId) != 0);
      break;
   case 'ctlautolistvalues':
      included = (_FindLanguageCallbackIndex("_%s_get_expression_pos", langId) != 0 &&
                  _FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      break;
   case '_insert':
      included = LanguageSettings.doesOptionApplyToLanguage(langId, LOI_INSERT_BEGIN_END_IMMEDIATELY);
      break;
   }

   return included;
}

void _language_auto_complete_form_restore_state()
{
   _language_form_restore_state(_language_auto_complete_form_get_value, _language_auto_complete_form_is_lang_included);
}

boolean _language_auto_complete_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      
      if (!validateLangIntTextBox(ctl_auto_complete_minimum.p_window_id)) {
         return false;
      }
   }

   // verify minimum expandable keywords
   if (!validateLangIntTextBox(_minimum_expandable.p_window_id)) {
      return false;
   }

   return true;
}

boolean _language_auto_complete_form_apply()
{
   langID := _get_language_form_lang_id();

   _language_form_apply(_language_auto_complete_form_apply_control);

   return true;
}

void _language_auto_complete_form_apply_control(_str controlName, _str langId, _str value)
{
   oldCodehelpFlags := LanguageSettings.getCodehelpFlags(langId);
   newCodehelpFlags := oldCodehelpFlags;
   codehelpFlag := 0;

   oldFlags := AutoCompleteGetOptions(langId);
   newFlags := oldFlags;
   flag := 0;

   flagOn := false;
   if (isinteger(value)) {
      flagOn = ((int)value != 0);
   }

   switch (controlName) {
   case '_ctl_blankline':
      LanguageSettings.setInsertBlankLineBetweenBeginEnd(langId, _ctl_blankline.p_value != 0);
      return;
   case 'ctl_auto_complete_frame':
      flag = AUTO_COMPLETE_ENABLE;
      break;
   case 'ctl_auto_complete_expand_syntax':
      flag = AUTO_COMPLETE_SYNTAX;
      break;
   case 'ctl_auto_complete_keywords':
      flag = AUTO_COMPLETE_KEYWORDS;
      break;
   case 'ctl_auto_complete_expand_alias':
      flag = AUTO_COMPLETE_ALIAS;
      break;
   case 'ctl_auto_complete_symbols':
      flag = AUTO_COMPLETE_SYMBOLS;
      break;
   case 'ctl_auto_complete_locals':
      flag = AUTO_COMPLETE_LOCALS;
      break;
   case 'ctl_auto_complete_members':
      flag = AUTO_COMPLETE_MEMBERS;
      break;
   case 'ctl_auto_complete_current_file':
      flag = AUTO_COMPLETE_CURRENT_FILE;
      break;
   case 'ctl_auto_complete_words':
      flag = AUTO_COMPLETE_WORDS;
      break;
   case 'ctl_auto_complete_arguments':
      flag = AUTO_COMPLETE_LANGUAGE_ARGS;
      break;
   case 'ctl_auto_complete_includes':
      switch (value) {
      case AC_INCLUDE_QUOTED_CB_TEXT:
         LanguageSettings.setAutoCompletePoundIncludeOption(langId, AC_POUND_INCLUDE_QUOTED_ON_SPACE);
         break;
      case AC_INCLUDE_AFTER_QUOTE_CB_TEXT:
         LanguageSettings.setAutoCompletePoundIncludeOption(langId, AC_POUND_INCLUDE_ON_QUOTELT);
         break;
      case AC_INCLUDE_NONE_CB_TEXT:
      default:
         LanguageSettings.setAutoCompletePoundIncludeOption(langId, AC_POUND_INCLUDE_NONE);
         break;
      }
      break;
   case 'ctl_auto_complete_tab_insert':
      flag = AUTO_COMPLETE_TAB_INSERTS_PREFIX;
      break;
   case 'ctl_auto_complete_tab_next':
      flag = AUTO_COMPLETE_TAB_NEXT;
      break;
   case 'ctl_auto_complete_minimum':
      LanguageSettings.setAutoCompleteMinimumLength(langId, (int)value);
      break;
   case 'ctl_auto_complete_selection_method':
      if (value == AC_SELECTION_METHOD_INSERT) {
         newFlags = oldFlags & ~AUTO_COMPLETE_NO_INSERT_SELECTED;
         newFlags = newFlags & ~AUTO_COMPLETE_UNIQUE;
      } else if (value == AC_SELECTION_METHOD_UNIQUE) {
         newFlags = oldFlags | AUTO_COMPLETE_UNIQUE;
         newFlags = newFlags | AUTO_COMPLETE_NO_INSERT_SELECTED;
      } else {
         newFlags = oldFlags & ~AUTO_COMPLETE_UNIQUE;
         newFlags = newFlags | AUTO_COMPLETE_NO_INSERT_SELECTED;
      }
      break;
   case 'ctl_auto_complete_show_bulb':
      flag = AUTO_COMPLETE_SHOW_BULB;
      break;
   case 'ctl_auto_complete_show_word':
      flag = AUTO_COMPLETE_SHOW_WORD;
      break;
   case 'ctl_auto_complete_show_list':
      flag = AUTO_COMPLETE_SHOW_LIST;
      break;
   case 'ctl_auto_complete_show_icons':
      flag = AUTO_COMPLETE_SHOW_ICONS;
      break;
   case 'ctl_auto_complete_show_categories':
      flag = AUTO_COMPLETE_SHOW_CATEGORIES;
      break;
   case 'ctl_auto_complete_show_prototypes':
      flag = AUTO_COMPLETE_SHOW_PROTOTYPES;
      break;
   case 'ctl_auto_complete_show_decl':
      flag = AUTO_COMPLETE_SHOW_DECL;
      break;
   case 'ctl_auto_complete_show_comments':
      flag = AUTO_COMPLETE_SHOW_COMMENTS;
      break;

   case '_syntax_expansion':
      LanguageSettings.setSyntaxExpansion(langId, value != 0);
      break;
   case '_minimum_expandable':
      LanguageSettings.setMinimumAbbreviation(langId, (int)value);
      break;
   case '_insert':
      LanguageSettings.setInsertBeginEndImmediately(langId, ((int)value != 0));
      break;
   case '_surround':
      if (value && !(def_surround_mode_options & VS_SURROUND_MODE_ENABLED)) {
         def_surround_mode_options = 0xFFFF;
      }
      LanguageSettings.setSurroundOptions(langId, value ? def_surround_mode_options : 0);
      break;
   case '_expand_alias_on_space':
      LanguageSettings.setExpandAliasOnSpace(langId, value != 0);
      break;

   case 'ctlautolistmembers':
      codehelpFlag = VSCODEHELPFLAG_AUTO_LIST_MEMBERS;
      break;
   case 'ctlCompletionOnSpace':
      codehelpFlag = VSCODEHELPFLAG_SPACE_COMPLETION;
      break;
   case 'ctlSpaceInsertsSpace':
      codehelpFlag = VSCODEHELPFLAG_SPACE_INSERTS_SPACE;
      break;
   case 'ctlEnterAlwaysInserts':
      flag = AUTO_COMPLETE_ENTER_ALWAYS_INSERTS;
      break;
   case 'ctlInsertOpenParen':
      codehelpFlag = VSCODEHELPFLAG_INSERT_OPEN_PAREN;
      break;
   case 'ctlpreserveidentifier':
      if (value == AC_PRESERVE_IDENTIFIER_FOR_ALM) {
         newCodehelpFlags = (oldCodehelpFlags | VSCODEHELPFLAG_PRESERVE_IDENTIFIER);
         newCodehelpFlags = (newCodehelpFlags | VSCODEHELPFLAG_REPLACE_IDENTIFIER);
      } else if (value == AC_PRESERVE_IDENTIFIER) {
         newCodehelpFlags = (oldCodehelpFlags | VSCODEHELPFLAG_PRESERVE_IDENTIFIER);
         newCodehelpFlags = (newCodehelpFlags & ~VSCODEHELPFLAG_REPLACE_IDENTIFIER);
      } else {
         newCodehelpFlags = (oldCodehelpFlags | VSCODEHELPFLAG_REPLACE_IDENTIFIER);
         newCodehelpFlags = (newCodehelpFlags & ~VSCODEHELPFLAG_PRESERVE_IDENTIFIER);
      }
      break;
   case 'ctlautolistvalues':
      codehelpFlag = VSCODEHELPFLAG_AUTO_LIST_VALUES;
      break;
   case 'ctllistmemcasesensitive':
      codehelpFlag = VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE;
      break;
   }

   if (flag != 0) {
      if (flagOn) {
         newFlags = oldFlags | flag;
      } else {
         newFlags = oldFlags & ~flag;
      }
   }
   if (newFlags != oldFlags) {
      LanguageSettings.setAutoCompleteOptions(langId, newFlags);
   }

   if (codehelpFlag != 0) {
      if (flagOn) {
         newCodehelpFlags = oldCodehelpFlags | codehelpFlag;
      } else {
         newCodehelpFlags = oldCodehelpFlags & ~codehelpFlag;
      }
   }
   if (newCodehelpFlags != oldCodehelpFlags) {
      LanguageSettings.setCodehelpFlags(langId, newCodehelpFlags);
   }

}

#endregion Options Dialog Helper Functions

void _language_auto_complete_form.on_destroy()
{
   _language_form_on_destroy();
}

void ctlCompletionOnSpace.lbutton_up()
{
   if (p_value) {
      ctlSpaceInsertsSpace.p_value=0;
   }
}

void ctlSpaceInsertsSpace.lbutton_up()
{
   if (p_value) {
      ctlCompletionOnSpace.p_value=0;
   }
}

_syntax_expansion.lbutton_up()
{
   langID := _get_language_form_lang_id();
   if (_LanguageInheritsFrom('html',langID) || _LanguageInheritsFrom('xml',langID) || _LanguageInheritsFrom('dtd',langID)) {
      _minimum_expandable.p_enabled = false;
      _minimum_expandable_label.p_enabled = false;
      _minimum_expandable_spinner.p_enabled = false;
      _expand_alias_on_space.p_enabled = true;
   } else {
      _minimum_expandable.p_enabled = _syntax_expansion.p_value != 0;
      _minimum_expandable_label.p_enabled = _syntax_expansion.p_value != 0;
      _minimum_expandable_spinner.p_enabled = _syntax_expansion.p_value != 0;
      _expand_alias_on_space.p_enabled = _syntax_expansion.p_value != 0;
      _ctl_blankline.p_enabled = _syntax_expansion.p_value != 0;
   }

   _insert.p_enabled = _ctl_blankline.p_enabled = _syntax_expansion.p_value != 0 && BRACES_SUPPORTED;
// _surround.p_enabled = _syntax_expansion.p_value != 0 && _insert.p_enabled && _insert.p_value != 0;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Verify that the auto complete display settings are consistent with
 * logic.  For example, you can not disable everything, because auto
 * complete must give the user some visual clue.
 */
static void AutoCompleteCheckDetails()
{
   if (ctl_auto_complete_show_bulb.p_value==0 &&
       //ctl_auto_complete_show_bar.p_value==0 &&
       ctl_auto_complete_show_list.p_value==0 &&
       ctl_auto_complete_show_decl.p_value==0 &&
       ctl_auto_complete_show_comments.p_value==0 &&
       ctl_auto_complete_show_word.p_value==0) {
      _message_box("At least one detail must be displayed.");
      p_value=1;
   }
}

/**
 * Reposition the comments and declaration bitmaps if we are showing the list.
 */
static void AutoCompleteAdjustComments()
{
   int x = ctl_auto_complete_pic_list.p_x;
   int y = ctl_auto_complete_pic_list.p_y;
   if (ctl_auto_complete_show_list.p_value) {
      x += ctl_auto_complete_pic_list.p_width;
      y += 450;
   }

   ctl_auto_complete_pic_decl.p_x = x;
   ctl_auto_complete_pic_comment1.p_x = x;
   ctl_auto_complete_pic_comment2.p_x = x;
   ctl_auto_complete_pic_decl.p_y = y;
   ctl_auto_complete_pic_comment1.p_y = y;
   ctl_auto_complete_pic_comment2.p_y = y;
}

/**
 * Display or hide the comments and declaration bitmaps
 * depending on the current settings.
 */
static void AutoCompleteShowHideComments()
{
   if (ctl_auto_complete_show_decl.p_value) {
      if (ctl_auto_complete_show_comments.p_value) {
         // show both
         ctl_auto_complete_pic_comment1.p_visible = false;
         ctl_auto_complete_pic_comment2.p_visible = true;
         ctl_auto_complete_pic_decl.p_visible = false;
      } else {
         // just show declaration
         ctl_auto_complete_pic_comment1.p_visible = false;
         ctl_auto_complete_pic_comment2.p_visible = false;
         ctl_auto_complete_pic_decl.p_visible = true;
      }

   } else {
      if (ctl_auto_complete_show_comments.p_value) {
         // just show comments
         ctl_auto_complete_pic_comment1.p_visible = true;
         ctl_auto_complete_pic_comment2.p_visible = false;
         ctl_auto_complete_pic_decl.p_visible = false;
      } else {
         // hide both
         ctl_auto_complete_pic_comment1.p_visible = false;
         ctl_auto_complete_pic_comment2.p_visible = false;
         ctl_auto_complete_pic_decl.p_visible = false;
      }
   }
}

/**
 * Display or hide the result list and icons depending
 * on the current settings.
 */
static void AutoCompleteShowHideList()
{
   if (ctl_auto_complete_show_list.p_value) {
      int icon_value = ctl_auto_complete_show_icons.p_value;
      int cat_value  = ctl_auto_complete_show_categories.p_value;
      ctl_auto_complete_pic_icons.p_visible      = (icon_value && cat_value)?   true:false;
      ctl_auto_complete_pic_list.p_visible       = (!icon_value && cat_value)?  true:false;
      ctl_auto_complete_pic_icons_flat.p_visible = (icon_value && !cat_value)?  true:false;
      ctl_auto_complete_pic_list_flat.p_visible  = (!icon_value && !cat_value)? true:false;
   } else {
      ctl_auto_complete_pic_icons.p_visible = false;
      ctl_auto_complete_pic_list.p_visible = false;
      ctl_auto_complete_pic_icons_flat.p_visible = false;
      ctl_auto_complete_pic_list_flat.p_visible  = false;
   }
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Disable all auto complete options if auto complete is disabled.
 */
void ctl_auto_complete_frame.lbutton_up()
{
   langId := _get_language_form_lang_id();

   boolean hasTagging = (langId == ALL_LANGUAGES_ID) || _istagging_supported(langId);
   boolean hasSyntax  = (langId == ALL_LANGUAGES_ID) || _FindLanguageCallbackIndex("_%s_get_syntax_completions",langId)!=0;
   boolean hasArguments = (langId == ALL_LANGUAGES_ID) || _FindLanguageCallbackIndex("_%s_autocomplete_get_arguments",langId)!=0;

   boolean enabled = ctl_auto_complete_frame.p_value? true:false;

   ctl_auto_complete_expand_syntax.p_enabled=enabled && hasSyntax;
   ctl_auto_complete_keywords.p_enabled=enabled;
   ctl_auto_complete_expand_alias.p_enabled=enabled;
   ctl_auto_complete_symbols.p_enabled=enabled && hasTagging;
   ctl_auto_complete_words.p_enabled=enabled;
   ctl_auto_complete_arguments.p_enabled=enabled && hasArguments;
   ctl_auto_complete_includes.p_enabled = enabled;
   ctl_auto_complete_includes_label.p_enabled = enabled;

   ctl_auto_complete_tab_insert.p_enabled=enabled;
   ctl_auto_complete_tab_next.p_enabled=enabled;
   ctl_auto_complete_selection_label.p_enabled = enabled;
   ctl_auto_complete_selection_method.p_enabled = enabled;

   ctl_auto_complete_show_bulb.p_enabled=enabled;
   ctl_auto_complete_show_list.p_enabled=enabled;
   ctl_auto_complete_show_icons.p_enabled=enabled && (ctl_auto_complete_show_list.p_value? true:false);
   ctl_auto_complete_show_categories.p_enabled=enabled && (ctl_auto_complete_show_list.p_value? true:false);
   ctl_auto_complete_show_decl.p_enabled=enabled;
   ctl_auto_complete_show_comments.p_enabled=enabled;
   ctl_auto_complete_show_word.p_enabled=enabled;

   ctl_auto_complete_minimum_label.p_enabled=enabled;
   ctl_auto_complete_minimum.p_enabled=enabled;
   ctl_auto_complete_minimum_spinner.p_enabled=enabled;
}

/**
 * Check consistency, then toggle picture in auto complete illustration.
 */
void ctl_auto_complete_show_bulb.lbutton_up() {
   AutoCompleteCheckDetails();
   ctl_auto_complete_pic_bulb.p_visible = p_value? true:false;
}
/**
 * Check consistency, then toggle picture in auto complete illustration.
 */
void ctl_auto_complete_show_list.lbutton_up() {
   AutoCompleteCheckDetails();
   AutoCompleteShowHideList();
   AutoCompleteAdjustComments();
   ctl_auto_complete_show_icons.p_enabled = p_value? true:false;
   ctl_auto_complete_show_categories.p_enabled = p_value? true:false;
   ctl_auto_complete_show_prototypes.p_enabled = p_value? true:false;
}
void ctl_auto_complete_show_icons.lbutton_up() {
   AutoCompleteShowHideList();
}
void ctl_auto_complete_show_categories.lbutton_up() {
   AutoCompleteShowHideList();
}
/**
 * Check consistency, then toggle picture in auto complete illustration.
 */
void ctl_auto_complete_show_comments.lbutton_up() {
   AutoCompleteCheckDetails();
   AutoCompleteShowHideComments();
}
/**
 * Check consistency, then toggle picture in auto complete illustration.
 */
void ctl_auto_complete_show_word.lbutton_up() {
   AutoCompleteCheckDetails();
   ctl_auto_complete_pic_word.p_visible = p_value? true:false;
}
/**
 * Check consistency, then toggle picture in auto complete illustration.
 */
void ctl_auto_complete_show_decl.lbutton_up() {
   AutoCompleteCheckDetails();
   AutoCompleteShowHideComments();
}

defeventtab _language_auto_bracket_form;

#region Options Dialog Helper Functions

void _language_auto_bracket_form_init_for_options(_str langID)
{
   // {} braces only currently supported for C languages and known block brace languages
   enable_braces := false;
   enable_brace_pad := false;
   if (langID == ALL_LANGUAGES_ID) {
      enable_braces = true;
   } else {
      enable_braces = !isLangAutoCloseBraceExcludedForLanguage(langID);
      enable_brace_pad = !isLangAutoClosePadBracesExcludedForLanguage(langID);

      if (enable_braces) {
         flags := LanguageSettings.getAutoBracket(langID);
      }
   }
   _cb_ab_brace.p_visible = _cb_ab_brace.p_enabled = enable_braces;

   if (!isLangAutoCloseAdvanceBraceExcludedForLanguage(langID)) {
      _advanced_brace.p_visible = true;
      _cb_ab_brace.p_visible = false;
      _advanced_brace.p_y = _cb_ab_brace.p_y;
   } else {
      _advanced_brace.p_visible = false;
   }
    
   _cb_ab_brace_pad.p_visible = _cb_ab_brace_pad.p_enabled = enable_brace_pad;

   _language_form_init_for_options(langID, _language_auto_bracket_form_get_value, 
                                   _language_auto_bracket_form_is_lang_included);

   _link_ab_config.p_mouse_pointer = MP_HAND;
   call_event(_cb_auto_bracket.p_window_id, LBUTTON_UP);
}

_str _language_auto_bracket_form_get_value(_str controlName, _str langId)
{
   _str value = 0;
   flags := LanguageSettings.getAutoBracket(langId);
   switch (controlName) {
   case '_cb_auto_bracket':
      value = (flags & AUTO_BRACKET_ENABLE) ? 1 : 0;
      break;
   case '_cb_ab_paren':
      value = (flags & AUTO_BRACKET_PAREN) ? 1 : 0;
      break;
   case '_cb_ab_paren_pad':
      value = (flags & AUTO_BRACKET_PAREN_PAD) ? 1 : 0;
      break;
   case '_cb_ab_bracket':
      value = (flags & AUTO_BRACKET_BRACKET) ? 1 : 0;
      break;
   case '_cb_ab_bracket_pad':
      value = (flags & AUTO_BRACKET_BRACKET_PAD) ? 1 : 0;
      break;
   case '_cb_ab_angle':
      value = (flags & AUTO_BRACKET_ANGLE_BRACKET) ? 1 : 0;
      break;
   case '_cb_ab_angle_pad':
      value = (flags & AUTO_BRACKET_ANGLE_BRACKET_PAD) ? 1 : 0;
      break;
   case '_cb_ab_dquote':
      value = (flags & AUTO_BRACKET_DOUBLE_QUOTE) ? 1 : 0;
      break;
   case '_cb_ab_squote':
      value = (flags & AUTO_BRACKET_SINGLE_QUOTE) ? 1 : 0;
      break;
   case '_cb_ab_brace':
   case '_advanced_brace':
      value = (flags & AUTO_BRACKET_BRACE) ? 1 : 0;
      break;
   case '_cb_ab_brace_pad':
      value = (flags & AUTO_BRACKET_BRACE_PAD) ? 1 : 0;
      break;

   case '_ctl_sameline':
      switch (LanguageSettings.getAutoBracePlacement(langId)) {
      case AUTOBRACE_PLACE_SAMELINE:
         value = '_ctl_sameline';
         break;

      case AUTOBRACE_PLACE_NEXTLINE:
         value = '_ctl_nextline';
         break;

      case AUTOBRACE_PLACE_AFTERBLANK:
         value = '_ctl_afterblank';
         break;
      }
      break;
   }
   return value;
}

boolean _language_auto_bracket_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case '_cb_ab_squote':
      // 11887 - disable for VBScript, since single quote is a comment character
      included = (langId != 'vbs');
      break;
   }

   return included;
}

void _language_auto_bracket_form_restore_state()
{
   _language_form_restore_state(_language_auto_bracket_form_get_value, _language_auto_bracket_form_is_lang_included);
}

boolean _language_auto_bracket_form_apply()
{
   _language_form_apply(_language_auto_bracket_form_apply_control);
   return true;
}

void _language_auto_bracket_form_apply_control(_str controlName, _str langId, _str value)
{
   oldFlags := LanguageSettings.getAutoBracket(langId);
   newFlags := oldFlags;

   flagOn := false;
   if (isinteger(value)) {
      flagOn = ((int)value != 0);
   }
   flag := 0;

   switch (controlName) {
   case '_cb_auto_bracket':
      flag = AUTO_BRACKET_ENABLE;
      break;
   case '_cb_ab_paren':
      flag = AUTO_BRACKET_PAREN;
      break;
   case '_cb_ab_paren_pad':
      flag = AUTO_BRACKET_PAREN_PAD;
      break;
   case '_cb_ab_bracket':
      flag = AUTO_BRACKET_BRACKET;
      break;
   case '_cb_ab_bracket_pad':
      flag = AUTO_BRACKET_BRACKET_PAD;
      break;
   case '_cb_ab_angle':
      flag = AUTO_BRACKET_ANGLE_BRACKET;
      break;
   case '_cb_ab_angle_pad':
      flag = AUTO_BRACKET_ANGLE_BRACKET_PAD;
      break;
   case '_cb_ab_dquote':
      flag = AUTO_BRACKET_DOUBLE_QUOTE;
      break;
   case '_cb_ab_squote':
      flag = AUTO_BRACKET_SINGLE_QUOTE;
      break;
   case '_cb_ab_brace':
   case '_advanced_brace':
      flag = AUTO_BRACKET_BRACE;
      break;
   case '_cb_ab_brace_pad':
      flag = AUTO_BRACKET_BRACE_PAD;
      break;
   case '_ctl_sameline':
         LanguageSettings.setAutoBracePlacement(langId, AUTOBRACE_PLACE_SAMELINE);
         return;

   case '_ctl_afterblank':
      LanguageSettings.setAutoBracePlacement(langId, AUTOBRACE_PLACE_AFTERBLANK);
      return;

   case '_ctl_nextline':
      LanguageSettings.setAutoBracePlacement(langId, AUTOBRACE_PLACE_NEXTLINE);
      return;
   }

   if (flag != 0) {
      if (flagOn) {
         newFlags = oldFlags | flag;
      } else {
         newFlags = oldFlags & ~flag;
      }
   }

   if (newFlags != oldFlags) {
      LanguageSettings.setAutoBracket(langId, newFlags);

      if ((oldFlags & AUTO_BRACKET_ENABLE) != (newFlags & AUTO_BRACKET_ENABLE)) {
         // adjust callbacks
         get_window_id(auto orig_wid);
         activate_window(VSWID_HIDDEN);
         _safe_hidden_window();
         first_buf_id := p_buf_id;
         for (;;) {
            if (p_LangId == langId) {
               setAutoBracketCallback(langId);
            }
            _next_buffer('HN');
            if ( p_buf_id==first_buf_id ) {
               break;
            }
         }
         activate_window(orig_wid);
      }
   }
}

#endregion Options Dialog Helper Functions

void _language_auto_bracket_form.on_destroy()
{
   _language_form_on_destroy();
}

void _cb_auto_bracket.lbutton_up()
{
   boolean enabled = _cb_auto_bracket.p_value ? true : false;
   _cb_ab_paren.p_enabled=enabled;
   _cb_ab_paren_pad.p_enabled=enabled && _cb_ab_paren.p_value;
   _cb_ab_bracket.p_enabled=enabled;
   _cb_ab_bracket_pad.p_enabled=enabled && _cb_ab_bracket.p_value;
   _cb_ab_angle.p_enabled=enabled;
   _cb_ab_angle_pad.p_enabled=enabled && _cb_ab_angle.p_value;
   _cb_ab_dquote.p_enabled=enabled;

   // this is disabled for VBScript
   _cb_ab_squote.p_enabled=(enabled && _get_language_form_lang_id() != 'vbs');

   _cb_ab_brace.p_enabled=enabled;
   _cb_ab_brace_pad.p_enabled=enabled && _cb_ab_brace.p_value;
}

void _cb_ab_paren.lbutton_up()
{
   boolean enabled = p_value ? true : false;
   _cb_ab_paren_pad.p_enabled=enabled;
}

void _cb_ab_bracket.lbutton_up()
{
   boolean enabled = p_value ? true : false;
   _cb_ab_bracket_pad.p_enabled=enabled;
}

void _cb_ab_angle.lbutton_up()
{
   boolean enabled = p_value ? true : false;
   _cb_ab_angle_pad.p_enabled=enabled;
}

void _cb_ab_brace.lbutton_up()
{
   boolean enabled = p_value ? true : false;
   _cb_ab_brace_pad.p_enabled=enabled;
}

void _link_ab_config.lbutton_up()
{
   config('Auto-Close', 'N', CFG_CLINE);
}

void _link_comments_config.lbutton_up()
{
   langId := _get_language_form_lang_id();
   modeName := _LangId2Modename(langId);
   showOptionsForModename(strip(modeName), 'Comments');
}

defeventtab _language_tagging_form;

const TAG_NAVIGATION_PROMPT             = "Prompt with all choices";
const TAG_NAVIGATION_PREFER_DEFINITION  = "Symbol definition (proc)";
const TAG_NAVIGATION_PREFER_DECLARATION = "Symbol declaration (proto)";

#region Options Dialog Helper Functions

/**
 * Determines whether the _ext_tagging_form would be unavailable
 * for the given mode name. 
 * 
 * @param _str modeName       mode name in question
 * 
 * @return boolean            true if EXcluded, false if ,
 *                            included
 */
boolean isLangTaggingFormExcludedForMode(_str langId)
{
   // we automatically allow ALL LANGUAGES
   if (langId == ALL_LANGUAGES_ID) return false;

   // if jaws mode is on, we don't want this to be enabled.
   if (_jaws_mode()) return true;

   // if everything is disabled, there's just not much point...
   enabled := false;
   do {

      // if any of these things are true, we like it...
      enabled = enabled || (_FindLanguageCallbackIndex("_%s_get_expression_info", langId) != 0 || 
                            _FindLanguageCallbackIndex("vs%s_get_expression_info", langId) != 0 || 
                            _FindLanguageCallbackIndex("_%s_get_idexp", langId) != 0);
      if (enabled) break;

      enabled = enabled || (_FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      if (enabled) break;

      enabled = enabled || (_FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      if (enabled) break;

      enabled = enabled || (_FindLanguageCallbackIndex("_%s_get_expression_pos", langId) != 0 &&
                            _FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      if (enabled) break;
   
      enabled = enabled || (_FindLanguageCallbackIndex("vs%s_list_tags", langId)!=0 ||
                            _FindLanguageCallbackIndex("%s_proc_search", langId)!=0 ||
                            _FindLanguageCallbackIndex("_%s_find_context_tags", langId)!=0);
      if (enabled) break;

   } while (false);

   return !enabled;
}

void _language_tagging_form_init_for_options(_str langID)
{
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PROMPT);
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PREFER_DEFINITION);
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PREFER_DECLARATION);

   _language_form_init_for_options(langID, _language_tagging_form_get_value, 
                                   _language_tagging_form_is_lang_included);

   _link_auto_complete_config.p_mouse_pointer = MP_HAND;

   ctlmouseoverinfo.call_event(ctlmouseoverinfo.p_window_id, LBUTTON_UP);
}

_str _language_tagging_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   codehelpFlags := LanguageSettings.getCodehelpFlags(langId);
   switch (controlName) {
   case 'ctlautofunctionhelp':
      value = (codehelpFlags & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) ? 1 : 0;
      break;
   case 'ctldispfunctioncomment':
      value = (codehelpFlags & VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS) ? 1 : 0;
      break;
   case 'ctlautoinsertparam':
      value = (codehelpFlags & VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION) ? 1 : 0;
      break;
   case 'ctlautolistparams':
      value = (codehelpFlags & VSCODEHELPFLAG_AUTO_LIST_PARAMS) ? 1 : 0;
      break;
   case 'ctlspaceafterparen':
      value = (codehelpFlags & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN) ? 0 : 1;
      break;
   case 'ctlspaceaftercomma':
      value = (codehelpFlags & VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA) ? 0 : 1;
      break;
   case 'ctlnavigation':
      if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
         value = TAG_NAVIGATION_PREFER_DEFINITION;
      } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
         value = TAG_NAVIGATION_PREFER_DECLARATION;
      } else {
         value = TAG_NAVIGATION_PROMPT;
      }
      break;
   case 'ctlignoreforwardclass':
      value = (codehelpFlags & VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS) ? 0 : 1;
      break;
   case 'ctlgotodefcasesensitive':
      value = (codehelpFlags & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE) ? 1 : 0;
      break;
   case 'ctlfilteroverloads':
      value = (codehelpFlags & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS) ? 1 : 0;
      break;
   case 'ctlmouseoverinfo':
      value = (codehelpFlags & VSCODEHELPFLAG_MOUSE_OVER_INFO) ? 1 : 0;
      break;
   case 'ctldispmembercomment':
      value = (codehelpFlags & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS) ? 1 : 0;
      break;
   case 'ctlhighlighttag':
      value = (codehelpFlags & VSCODEHELPFLAG_HIGHLIGHT_TAGS) ? 1 : 0;
      break;
   case 'ctlidentcasesensitive':
      value = (codehelpFlags & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE) ? 1 : 0;
      break;
   }

   return value;
}

boolean _language_tagging_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctldispmembercomment':
      included = (_FindLanguageCallbackIndex("vs%s_list_tags", langId)!=0 ||
                  _FindLanguageCallbackIndex("%s_proc_search", langId)!=0 ||
                  _FindLanguageCallbackIndex("_%s_find_context_tags", langId)!=0 ||
                  _FindLanguageCallbackIndex("_%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("vs%s_get_expression_info", langId) != 0 ||
                  _FindLanguageCallbackIndex("_%s_get_idexp", langId) != 0);
      break;
   case 'ctlautofunctionhelp':
   case 'ctlspaceaftercomma':
   case 'ctlspaceafterparen':
   case 'ctldispfunctioncomment':
      included = (_FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      break;
   case 'ctlautoinsertparam':
      included = (def_persistent_select=='D' && _FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      break;
   case 'ctlautolistparams':
   case 'ctlfilteroverloads':
      included = (_FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      break;
   }

   return included;
}

void _language_tagging_form_restore_state()
{
   _language_form_restore_state(_language_tagging_form_get_value, _language_tagging_form_is_lang_included);
}

boolean _language_tagging_form_apply()
{
   _language_form_apply(_language_tagging_form_apply_control);

   return true;
}

void _language_tagging_form_apply_control(_str controlName, _str langId, _str value)
{
   codehelpFlags := LanguageSettings.getCodehelpFlags(langId);
   newFlags := codehelpFlags;

   turnFlagOn := false;
   if (isinteger(value)) {
      turnFlagOn = ((int)value != 0);
   }
   flag := 0;

   switch (controlName) {
   case 'ctlautofunctionhelp':
      flag = VSCODEHELPFLAG_AUTO_FUNCTION_HELP;
      break;
   case 'ctldispfunctioncomment':
      flag = VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS;
      break;
   case 'ctlautoinsertparam':
      flag = VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION;
      break;
   case 'ctlautolistparams':
      flag = VSCODEHELPFLAG_AUTO_LIST_PARAMS;
      break;
   case 'ctlspaceafterparen':
      flag = VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlspaceaftercomma':
      flag = VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlnavigation':
      if (value == TAG_NAVIGATION_PREFER_DEFINITION) {
         newFlags = codehelpFlags | VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
         newFlags = newFlags & ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
      } else if (value == TAG_NAVIGATION_PREFER_DECLARATION) {
         newFlags = codehelpFlags | VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
         newFlags = newFlags & ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
      } else {
         newFlags = codehelpFlags & ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION | VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
      }
      break;
   case 'ctlfinddefinition':
      flag = VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
      break;
   case 'ctlfinddeclaration':
      flag = VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
      break;
   case 'ctlignoreforwardclass':
      flag = VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlgotodefcasesensitive':
      flag = VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE;
      break;
   case 'ctlfilteroverloads':
      flag = VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS;
      break;
   case 'ctlmouseoverinfo':
      flag = VSCODEHELPFLAG_MOUSE_OVER_INFO;
      break;
   case 'ctldispmembercomment':
      flag = VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS;
      break;
   case 'ctlhighlighttag':
      flag = VSCODEHELPFLAG_HIGHLIGHT_TAGS;
      break;
   case 'ctlidentcasesensitive':
      flag = VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE;
      break;
   }

   if (flag) {
      if (turnFlagOn) {
         newFlags = codehelpFlags | flag;
      } else {
         newFlags = codehelpFlags & ~flag;
      }
   }

   if (newFlags != codehelpFlags) {
      LanguageSettings.setCodehelpFlags(langId, newFlags);
   }
}

#endregion Options Dialog Helper Functions

void _language_tagging_form.on_destroy()
{
   _language_form_on_destroy();
}

void ctlautofunctionhelp.lbutton_up()
{
   ctlautoinsertparam.p_enabled=((p_value)!=0 && p_enabled);
   ctlspaceaftercomma.p_enabled=((p_value)!=0 && p_enabled);
   ctlspaceafterparen.p_enabled=ctlspaceaftercomma.p_enabled;
}

void _link_auto_complete_config.lbutton_up()
{
   langId := _get_language_form_lang_id();
   modeName := _LangId2Modename(langId);
   showOptionsForModename(strip(modeName), 'Auto-Complete');
}

void ctlmouseoverinfo.lbutton_up()
{
   ctldispmembercomment.p_enabled = (ctlmouseoverinfo.p_value != 0);
}

defeventtab _language_adaptive_formatting_form;

#region Options Dialog Helper Functions

void positionControl(int wid, int availFlags, int adFlag, int &shift, _str lang)
{
   if (availFlags & adFlag) {
      wid.p_y -= shift;
   } else {
      wid.p_visible = false;
      shift += wid.p_height + 120;
   }
}

void _language_adaptive_formatting_form_init_for_options(_str langID)
{  
   // if this is NOT all languages, then we might need to do some shifty hiding.
   if (langID != ALL_LANGUAGES_ID) {

      // the default distance between checkboxes
      shiftAmount := 120;
      availFlags := adaptive_format_get_available_for_language(langID);
   
      // determine what gets shown and what the value is
      shift := 0;
   
      // do this once for each control to dynamically figure out what we need to show
      positionControl(_cb_syntax_indent.p_window_id, availFlags, AFF_SYNTAX_INDENT, shift, langID);
      positionControl(_cb_tabs.p_window_id, availFlags, AFF_TABS, shift, langID);
      positionControl(_cb_indent_with_tabs.p_window_id, availFlags, AFF_INDENT_WITH_TABS, shift, langID);
      positionControl(_cb_keyword_casing.p_window_id, availFlags, AFF_KEYWORD_CASING, shift, langID);
      positionControl(_cb_tag_casing.p_window_id, availFlags, AFF_TAG_CASING, shift, langID);
      positionControl(_cb_attribute_casing.p_window_id, availFlags, AFF_ATTRIBUTE_CASING, shift, langID);
      positionControl(_cb_value_casing.p_window_id, availFlags, AFF_VALUE_CASING, shift, langID);
      positionControl(_cb_hex_value_casing.p_window_id, availFlags, AFF_HEX_VALUE_CASING, shift, langID);
      positionControl(_cb_indent_case.p_window_id, availFlags, AFF_INDENT_CASE, shift, langID);
      positionControl(_cb_no_space_before.p_window_id, availFlags, AFF_NO_SPACE_BEFORE_PAREN, shift, langID);
      positionControl(_cb_pad_parens.p_window_id, availFlags, AFF_PAD_PARENS, shift, langID);
      positionControl(_cb_begin_end_style.p_window_id, availFlags, AFF_BEGIN_END_STYLE, shift, langID);
   }

   _language_form_init_for_options(langID, _language_adaptive_formatting_form_get_value, 
                                   _language_adaptive_formatting_form_is_lang_included);

   // click the button so we know what is disabled and what is not
   _cb_ad_form.call_event(_cb_ad_form, LBUTTON_UP, 'W');
}

_str _language_adaptive_formatting_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_cb_ad_form':
      value = (int)LanguageSettings.getUseAdaptiveFormatting(langId);
      break;
   case '_cb_syntax_indent':
   case '_cb_tabs':
   case '_cb_indent_with_tabs':
   case '_cb_keyword_casing':
   case '_cb_tag_casing':
   case '_cb_attribute_casing':
   case '_cb_value_casing':
   case '_cb_hex_value_casing':
   case '_cb_indent_case':
   case '_cb_no_space_before':
   case '_cb_pad_parens':
   case '_cb_begin_end_style':
      flag := afControlToFlag(controlName);
      value = (int)adaptive_format_is_flag_on_for_language(flag, langId);
      break;
   }

   return value;
}

boolean _language_adaptive_formatting_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;
   availFlags := adaptive_format_get_available_for_language(langId);

   switch (controlName) {
   case '_cb_ad_form':
      included = (availFlags != 0);
      break;
   case '_cb_syntax_indent':
   case '_cb_tabs':
   case '_cb_indent_with_tabs':
   case '_cb_keyword_casing':
   case '_cb_tag_casing':
   case '_cb_attribute_casing':
   case '_cb_value_casing':
   case '_cb_hex_value_casing':
   case '_cb_indent_case':
   case '_cb_no_space_before':
   case '_cb_pad_parens':
   case '_cb_begib_end_style':
      flag := afControlToFlag(controlName);
      included = (availFlags & flag) != 0;
      break;
   }

   return included;
}
 
void _language_adaptive_formatting_form_restore_state()
{
   _language_form_restore_state(_language_adaptive_formatting_form_get_value, 
                                _language_adaptive_formatting_form_is_lang_included);
}

void _language_adaptive_formatting_form_apply()
{
   _language_form_apply(_language_adaptive_formatting_form_apply_control_value);
}

_str _language_adaptive_formatting_form_apply_control_value(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   checked := ((int)value != 0);

   switch (controlName) {
   case '_cb_ad_form':
      LanguageSettings.setUseAdaptiveFormatting(langId, checked);
      break;
   case '_cb_syntax_indent':
   case '_cb_tabs':
   case '_cb_indent_with_tabs':
   case '_cb_keyword_casing':
   case '_cb_tag_casing':
   case '_cb_attribute_casing':
   case '_cb_value_casing':
   case '_cb_hex_value_casing':
   case '_cb_indent_case':
   case '_cb_no_space_before':
   case '_cb_pad_parens':
   case '_cb_begin_end_style':
      oldFlags := LanguageSettings.getAdaptiveFormattingFlags(langId);
      newFlags := oldFlags;

      // I know this looks backwards...but trust me
      flag := afControlToFlag(controlName);
      if (!checked) {
         newFlags = oldFlags | flag;
      } else {
         newFlags = oldFlags & ~flag;
      }

      if (newFlags != oldFlags) {
         updateKey = ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY;
         updateValue = newFlags;

         LanguageSettings.setAdaptiveFormattingFlags(langId, newFlags);
      }
      break;
   }

   return updateKey' 'updateValue;

}

/**
 * Determines whether the _ext_adaptive_formatting_form would be
 * unavailable for the given mode name. 
 * 
 * @param _str modeName       mode name in question
 * 
 * @return boolean            true if EXcluded, false if 
 *                            included
 */
boolean isLangAdaptiveFormattingExcludedForMode(_str langId)
{
   return (adaptive_format_get_available_for_language(langId) == 0);
}

#endregion Options Dialog Helper Functions

void _language_adaptive_formatting_form.on_destroy()
{
   _language_form_on_destroy();
}

static int afControlToFlag(_str controlName)
{
   flag := 0;

   switch (controlName) {
   case '_cb_syntax_indent':
      flag = AFF_SYNTAX_INDENT;
      break;
   case '_cb_tabs':
      flag = AFF_TABS;
      break;
   case '_cb_indent_with_tabs':
      flag = AFF_INDENT_WITH_TABS;
      break;
   case '_cb_keyword_casing':
      flag = AFF_KEYWORD_CASING;
      break;
   case '_cb_tag_casing':
      flag = AFF_TAG_CASING;
      break;
   case '_cb_attribute_casing':
      flag = AFF_ATTRIBUTE_CASING;
      break;
   case '_cb_value_casing':
      flag = AFF_VALUE_CASING;
      break;
   case '_cb_hex_value_casing':
      flag = AFF_HEX_VALUE_CASING;
      break;
   case '_cb_indent_case':
      flag = AFF_INDENT_CASE;
      break;
   case '_cb_no_space_before':
      flag = AFF_NO_SPACE_BEFORE_PAREN;
      break;
   case '_cb_pad_parens':
      flag = AFF_PAD_PARENS;
      break;
   case '_cb_begin_end_style':
      flag = AFF_BEGIN_END_STYLE;
      break;
   }

   return flag;
}

static _str afFlagToControl(int flag)
{
   controlName := '';
   switch (flag) {
   case AFF_SYNTAX_INDENT:
      controlName = '_cb_syntax_indent';
      break;
   case AFF_TABS:
      controlName = '_cb_tabs';
      break;
   case AFF_INDENT_WITH_TABS:
      controlName = '_cb_indent_with_tabs';
      break;
   case AFF_KEYWORD_CASING:
      controlName = '_cb_keyword_casing';
      break;
   case AFF_TAG_CASING:
      controlName = '_cb_tag_casing';
      break;
   case AFF_ATTRIBUTE_CASING:
      controlName = '_cb_attribute_casing';
      break;
   case AFF_VALUE_CASING:
      controlName = '_cb_value_casing';
      break;
   case AFF_HEX_VALUE_CASING:
      controlName = '_cb_hex_value_casing';
      break;
   case AFF_INDENT_CASE:
      controlName = '_cb_indent_case';
      break;
   case AFF_NO_SPACE_BEFORE_PAREN:
      controlName = '_cb_no_space_before';
      break;
   case AFF_PAD_PARENS:
      controlName = '_cb_pad_parens';
      break;
   case AFF_BEGIN_END_STYLE:
      controlName = '_cb_begin_end_style';
      break;
   }

   return controlName;
}

boolean isModifiedAdaptiveFormattingOn(_str langId, int flag)
{
   // for AF to be on for a flag, it has to be on for both the flag and the overall value
   isAFOn := false;
   isFlagOn := false;

   // we need to use the all_langs_mgr to find out!
   formName := '_language_adaptive_formatting_form';

   // first check the overall setting
   controlName := '_cb_ad_form';

   // see if this control is being overridden by all languages
   if (all_langs_mgr.doesAllLanguagesOverride(formName, controlName, langId)) {
      isAFOn = ((int)all_langs_mgr.getLanguageValue(formName, controlName, ALL_LANGUAGES_ID) != 0);
   } else {
      value := all_langs_mgr.getLanguageValue(formName, controlName, langId);

      if (value != null) {
         isAFOn = ((int)value != 0);
      } else {
         isAFOn = adaptive_format_is_adaptive_on(langId);
      }
   }

   if (isAFOn) {
   
      // what is our control name
      controlName = afFlagToControl(flag);
   
      // see if this control is being overridden by all languages
      if (all_langs_mgr.doesAllLanguagesOverride(formName, controlName, langId)) {
         isFlagOn = ((int)all_langs_mgr.getLanguageValue(formName, controlName, ALL_LANGUAGES_ID) != 0);
      } else {
         value := all_langs_mgr.getLanguageValue(formName, controlName, langId);
         if (value != null) {
            isFlagOn = ((int)value != 0);
         } else {
            isFlagOn = adaptive_format_is_flag_on_for_language(flag, langId);
         }
      }
   }

   return isAFOn && isFlagOn;
}

void _cb_ad_form.lbutton_up()
{
   enabled := (_cb_ad_form.p_value != 0);
   _cb_syntax_indent.p_enabled = _cb_tabs.p_enabled = _cb_indent_with_tabs.p_enabled = _cb_keyword_casing.p_enabled = 
      _cb_tag_casing.p_enabled = _cb_attribute_casing.p_enabled = _cb_value_casing.p_enabled = 
      _cb_hex_value_casing.p_enabled = _cb_indent_case.p_enabled = _cb_no_space_before.p_enabled = 
      _cb_pad_parens.p_enabled = _cb_begin_end_style.p_enabled = enabled;
}

defeventtab _language_view_form;

#define SYMBOL_COLORING_MODIFIED       ctl_symbol_coloring.p_user

#region Options Dialog Helper Functions

void _language_view_form_init_for_options(_str langID)
{
   // load up our hex mode options
   _ctl_hex_combo._lbadd_item('None');
   _ctl_hex_combo._lbadd_item('Hex');
   _ctl_hex_combo._lbadd_item('Line hex');
   
   // check if ISPF is active - disable line numbers!
   //ctlframe2.p_enabled = _ctl_line_numbers.p_enabled = _ctl_auto_text.p_enabled = 
   //   ctllabel2.p_enabled = (def_keys != 'ispf-keys');
      
   if (langID == ALL_LANGUAGES_ID) {
      _modified_lines_link.p_visible = _current_line_link.p_visible = 
         _ctl_config_special_chars.p_visible = ctl_configure_symbol_coloring.p_visible = false;

      heightDiff := ctl_configure_symbol_coloring.p_height + 120;
      ctl_symbol_coloring.p_height -= heightDiff;
      _modified_lines.p_y -= heightDiff;
      _current_line.p_y -= heightDiff;
      ctllabel1.p_y -= heightDiff;
      _ctl_hex_combo.p_y -= heightDiff;
   } else {
      // set up links to look right
      _modified_lines_link.p_mouse_pointer = MP_HAND;
      _current_line_link.p_mouse_pointer = MP_HAND;
   }

   ctl_strict_symbols._lbadd_item("Use strict symbol lookups (full symbol analysis)");
   ctl_strict_symbols._lbadd_item("Use relaxed symbol lookups (symbol analysis with relaxed rules)");
   ctl_strict_symbols._lbadd_item("Use fast, simplistic symbol lookups (symbol name only)");

   _language_form_init_for_options(langID, _language_view_form_get_value, _language_view_form_is_lang_included);

   if (ctl_symbol_coloring.p_enabled) {
      ctl_symbol_coloring.call_event(ctl_symbol_coloring, LBUTTON_UP);
   }

}

_str _language_view_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_ctl_special_chars':
      specialChars := LanguageSettings.getShowTabs(langId);
      value = ((specialChars & SHOWSPECIALCHARS_ALL) == SHOWSPECIALCHARS_ALL) ? 1: 0;
      break;
   case '_ctl_tabs':
      showTabs := LanguageSettings.getShowTabs(langId);
      value = (showTabs & SHOWSPECIALCHARS_TABS) ? 1: 0;
      break;
   case '_ctl_spaces':
      showSpaces := LanguageSettings.getShowTabs(langId);
      value = (showSpaces & SHOWSPECIALCHARS_SPACES) ? 1: 0;
      break;
   case '_ctl_newline':
      showNL := LanguageSettings.getShowTabs(langId);
      value = (showNL & SHOWSPECIALCHARS_NLCHARS) ? 1: 0;
      break;
   case '_ctl_ctrl_chars':
      showCC := LanguageSettings.getShowTabs(langId);
      value = (showCC & SHOWSPECIALCHARS_CTRL_CHARS) ? 1: 0;
      break;
   case '_ctl_line_numbers':
      lnOn := LanguageSettings.getLineNumbersFlags(langId);
      value = (lnOn & LNF_ON) ? 1 : 0;
      break;
   case '_ctl_auto_text':
      value = LanguageSettings.getLineNumbersLength(langId);
      break;
   case '_ctl_hex_combo':
      hexMode := LanguageSettings.getHexMode(langId);
      switch(hexMode) {
      case HM_HEX_ON:
         value = 'Hex';
         break;
      case HM_HEX_LINE:
         value = 'Line hex';
         break;
      default:
         value = 'None';
         break;
      }
      break;
   case 'ctl_symbol_coloring':
      symbolColoring := LanguageSettings.getSymbolColoringOptions(langId);
      value = (symbolColoring & SYMBOL_COLOR_DISABLED) ? 0 : 1;
      break;
   case 'ctl_bold_symbols':
      bold := LanguageSettings.getSymbolColoringOptions(langId);
      value = (bold & SYMBOL_COLOR_BOLD_DEFINITIONS) ? 1 : 0;
      break;
   case 'ctl_symbol_errors':
      errors := LanguageSettings.getSymbolColoringOptions(langId);
      value = (errors & SYMBOL_COLOR_SHOW_NO_ERRORS) ? 0 : 1;
      break;
   case 'ctl_strict_symbols':
      strict := LanguageSettings.getSymbolColoringOptions(langId);
      if (strict & SYMBOL_COLOR_SIMPLISTIC_TAGGING) {
         value = "Use fast, simplistic symbol lookups (symbol name only)";
      } else if (strict & SYMBOL_COLOR_NO_STRICT_TAGGING) {
         value = "Use relaxed symbol lookups (symbol analysis with relaxed rules)";
      } else {
         value = "Use strict symbol lookups (full symbol analysis)";
      }
      break;
   case '_current_line':
      currentLine := LanguageSettings.getColorFlags(langId);
      value = (currentLine & CLINE_COLOR_FLAG) ? 1 : 0;
      break;
   case '_modified_lines':
      modifiedLine := LanguageSettings.getColorFlags(langId);
      value = (modifiedLine & MODIFY_COLOR_FLAG) ? 1 : 0;
      break;
   }

   return value;
}

boolean _language_view_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctl_symbol_errors':
      included = (_FindLanguageCallbackIndex("%s_list_locals", langId) > 0);
   case 'ctl_symbol_coloring':
   case 'ctl_bold_symbols':
   case 'ctl_strict_symbols':
   case 'ctl_configure_symbol_coloring':
      included = included && _QSymbolColoringSupported(langId);
      break;
   }

   return included;
}

boolean _language_view_form_validate(int action)
{
   langID := _get_language_form_lang_id();

   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      if (!validateLangIntTextBox(_ctl_auto_text.p_window_id)) {
         return false;
      }
   }

   return true;
}

void _language_view_form_restore_state()
{
   // check if ISPF is active - disable line numbers!
   //ctlframe2.p_enabled = _ctl_line_numbers.p_enabled = _ctl_auto_text.p_enabled = 
   //   ctllabel2.p_enabled = (def_keys != 'ispf-keys');

   _language_form_restore_state(_language_view_form_get_value, 
                                _language_view_form_is_lang_included);
}

boolean _language_view_form_apply()
{
   SYMBOL_COLORING_MODIFIED = false;

   _language_form_apply(_language_view_form_apply_control);

   if (SYMBOL_COLORING_MODIFIED) {
      SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme, true);
   }

   return true;
}

_str _language_view_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   oldValue := 0;
   newValue := 0;
   switch (controlName) {
   case '_ctl_special_chars':
      oldValue = LanguageSettings.getShowTabs(langId);

      if ((int)value) newValue = oldValue | SHOWSPECIALCHARS_ALL;
      else {
         // take out the all value
         newValue = (oldValue & ~SHOWSPECIALCHARS_ALL);
         // but leave the ones that can be controlled by individual checkboxes - they'll get turned off in their own section
         newValue = newValue | (SHOWSPECIALCHARS_TABS | SHOWSPECIALCHARS_SPACES | SHOWSPECIALCHARS_NLCHARS | SHOWSPECIALCHARS_CTRL_CHARS);
      }

      if (oldValue != newValue) {
         updateKey = SHOW_SPECIAL_CHARS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowTabs(langId, newValue);
      }
      break;
   case '_ctl_tabs':
      oldValue = LanguageSettings.getShowTabs(langId);

      if ((int)value) newValue = oldValue | SHOWSPECIALCHARS_TABS;
      else newValue = oldValue & ~SHOWSPECIALCHARS_TABS;

      if (oldValue != newValue) {
         updateKey = SHOW_SPECIAL_CHARS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowTabs(langId, newValue);
      }
      break;
   case '_ctl_spaces':
      oldValue = LanguageSettings.getShowTabs(langId);

      if ((int)value) newValue = oldValue | SHOWSPECIALCHARS_SPACES;
      else newValue = oldValue & ~SHOWSPECIALCHARS_SPACES;

      if (oldValue != newValue) {
         updateKey = SHOW_SPECIAL_CHARS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowTabs(langId, newValue);
      }
      break;
   case '_ctl_newline':
      oldValue = LanguageSettings.getShowTabs(langId);

      if ((int)value) newValue = oldValue | SHOWSPECIALCHARS_NLCHARS;
      else newValue = oldValue & ~SHOWSPECIALCHARS_NLCHARS;

      if (oldValue != newValue) {
         updateKey = SHOW_SPECIAL_CHARS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowTabs(langId, newValue);
      }
      break;
   case '_ctl_ctrl_chars':
      oldValue = LanguageSettings.getShowTabs(langId);

      if ((int)value) newValue = oldValue | SHOWSPECIALCHARS_CTRL_CHARS;
      else newValue = oldValue & ~SHOWSPECIALCHARS_CTRL_CHARS;

      if (oldValue != newValue) {
         updateKey = SHOW_SPECIAL_CHARS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowTabs(langId, newValue);
      }
      break;
   case '_ctl_line_numbers':
      updateKey = LINE_NUMBERS_FLAGS_UPDATE_KEY;
      updateValue = (int)value ? (LNF_ON | LNF_AUTOMATIC) : 0;

      LanguageSettings.setLineNumbersFlags(langId, (int)value ? (LNF_ON | LNF_AUTOMATIC) : 0);
      break;
   case '_ctl_auto_text':
      updateKey = LINE_NUMBERS_LEN_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setLineNumbersLength(langId, (int)value);
      break;
   case '_ctl_hex_combo':
      switch(value) {
      case 'Hex':
         newValue = HM_HEX_ON;
         break;
      case 'Line hex':
         newValue = HM_HEX_LINE;
         break;
      default:
         newValue = HM_HEX_OFF;
         break;
      }
      updateKey = HEX_MODE_UPDATE_KEY;
      updateValue = newValue;

      LanguageSettings.setHexMode(langId, newValue);
      break;
   case 'ctl_symbol_coloring':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);

      if (!(int)value) newValue = oldValue | SYMBOL_COLOR_DISABLED;
      else newValue = oldValue & ~SYMBOL_COLOR_DISABLED;

      if (oldValue != newValue) {
         SYMBOL_COLORING_MODIFIED = true;
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_bold_symbols':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);

      if ((int)value) newValue = oldValue | SYMBOL_COLOR_BOLD_DEFINITIONS;
      else newValue = oldValue & ~SYMBOL_COLOR_BOLD_DEFINITIONS;

      if (oldValue != newValue) {
         SYMBOL_COLORING_MODIFIED = true;
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_symbol_errors':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);

      if (!(int)value) newValue = oldValue | SYMBOL_COLOR_SHOW_NO_ERRORS;
      else newValue = oldValue & ~SYMBOL_COLOR_SHOW_NO_ERRORS;

      if (oldValue != newValue) {
         SYMBOL_COLORING_MODIFIED = true;
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_strict_symbols':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);
      newValue = oldValue & ~(SYMBOL_COLOR_NO_STRICT_TAGGING|SYMBOL_COLOR_SIMPLISTIC_TAGGING);
      switch (value) {
      case "Use strict symbol lookups (full symbol analysis)":
         break;
      case "Use relaxed symbol lookups (symbol analysis with relaxed rules)":
         newValue |= SYMBOL_COLOR_NO_STRICT_TAGGING;
         break;
      case "Use fast, simplistic symbol lookups (symbol name only)":
         newValue |= SYMBOL_COLOR_SIMPLISTIC_TAGGING;
         break;
      }
      if (oldValue != newValue) {
         SYMBOL_COLORING_MODIFIED = true;
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case '_current_line':
      oldValue = LanguageSettings.getColorFlags(langId);

      if ((int)value) newValue = oldValue | CLINE_COLOR_FLAG;
      else newValue = oldValue & ~CLINE_COLOR_FLAG;

      if (oldValue != newValue) {
         updateKey = COLOR_FLAGS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setColorFlags(langId, newValue);
      }
      break;
   case '_modified_lines':
      oldValue = LanguageSettings.getColorFlags(langId);

      if ((int)value) newValue = oldValue | MODIFY_COLOR_FLAG;
      else newValue = oldValue & ~MODIFY_COLOR_FLAG;

      if (oldValue != newValue) {
         updateKey = COLOR_FLAGS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setColorFlags(langId, newValue);
      }
      break;
   }

   return updateKey' 'updateValue;
}

#endregion Options Dialog Helper Functions

void _language_view_form.on_destroy()
{
   _language_form_on_destroy();
}

_ctl_config_special_chars.lbutton_up()
{  
   config('Special Characters');
}

ctl_configure_symbol_coloring.lbutton_up()
{  
   config('Symbol Coloring');
}

ctl_symbol_coloring.lbutton_up()
{
   langId := _get_language_form_lang_id();
   if (langId != ALL_LANGUAGES_ID) {

      enabled := (p_enabled && p_value != 0);

      ctl_bold_symbols.p_enabled = enabled;
      ctl_strict_symbols.p_enabled = enabled;

      ctl_symbol_errors.p_enabled = enabled &&
         _language_view_form_is_lang_included('ctl_symbol_errors', langId, false);
   }
}

_ctl_special_chars.lbutton_up()
{
   _ctl_tabs.p_value = _ctl_spaces.p_value = _ctl_newline.p_value = _ctl_ctrl_chars.p_value = _ctl_special_chars.p_value;
}

// All the individual special characters checkboxes come here.
_ctl_tabs.lbutton_up()
{
   // if we've turned this off and the Special Chars group checkbox is on, turn that off
   if (!p_value && _ctl_special_chars.p_value) _ctl_special_chars.p_value = 0;

   // if we've turned this on, and everything else is on, go ahead and turn on all special chars
   if (_ctl_tabs.p_value && _ctl_spaces.p_value && _ctl_newline.p_value && _ctl_ctrl_chars.p_value) _ctl_special_chars.p_value = 1;
}

void _modified_lines_link.lbutton_up()
{
   config('Colors', 'N', CFG_MODIFIED_LINE);
}

void _current_line_link.lbutton_up()
{
   config('Colors', 'N', CFG_CLINE);
}

defeventtab _language_formatting_form;

#region Options Dialog Helper Functions

void _language_formatting_form_init_for_options(_str langId)
{
   if (langId == ALL_LANGUAGES_ID) {
      // load our scheme names
      _str schemeNames[];
      XW_schemeNamesM(schemeNames);
      XW_selectSchemeDB._lbclear();
      for (i := 0; i < schemeNames._length(); i++) {
         XW_selectSchemeDB._lbadd_item(schemeNames[i]);
      }

      _indent_with_tabs_ad_form_link.p_visible = false;
      _indent_ad_form_link.p_visible = false;
      _tabs_ad_form_link.p_visible = false;

      // we want to get rid of these for beta 2, for now, just hide them
      _no_space.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
//    ctl_XW_autoSymbolTrans_check.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;

      ctl_XW_autoSymbolTrans_check.p_y = ctlUseContOnParameters.p_y;

   } else {
      // if we are using the actual _language_formatting_form (instead
      // of calling this function to act on an inherited form), then
      // we need to hide some things
      if (p_name == '_language_formatting_form') {
         _ctl_frame_be_style.p_visible = false;
         _no_space.p_visible = false;
         ctl_pad_between_parens.p_visible = false;
         _ctl_frame_tag_case.p_visible = false;
         _ctl_frame_attrib_case.p_visible = false;
         _ctl_frame_word_value_case.p_visible = false;
         _ctl_frame_hex_value_case.p_visible = false;
         _ctl_frame_auto_format.p_visible = false;
         ctl_XW_autoSymbolTrans_check.p_visible = false;
         _ctl_frame_keyword_case.p_visible = false;
         ctlUseContOnParameters.p_visible = false;
         _indent_case.p_visible = false;
      }
   }

   _language_form_init_for_options(langId, _language_formatting_form_get_value, _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(langId);

   PROMPT_TABS_DIFFER=1;      // Signifies user was asked once if Syntax Indent differs from tabs
}

_str _language_formatting_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_style0':
   case '_style1':
   case '_style2':
      style := LanguageSettings.getBeginEndStyle(langId);
      value = '_style'style;
      break;
   case '_no_space':
      value = (int)LanguageSettings.getNoSpaceBeforeParen(langId);
      break;
   case 'ctl_pad_between_parens':
      value = (int)LanguageSettings.getPadParens(langId);
      break;
   case '_quick_brace':
      value = (int)LanguageSettings.getQuickBrace(langId);
      break;
   case '_ctl_cuddle_else':
      value = (int)LanguageSettings.getCuddleElse(langId);
      break;
   case '_indent':
      value = (int)LanguageSettings.getIndentFirstLevel(langId, 1);
      break;
   case 'ctlUseContOnParameters':
      value=(int)LanguageSettings.getUseContinuationIndentOnFunctionParameters(langId);
      break;
   case '_indent_case':
      value = (int)LanguageSettings.getIndentCaseFromSwitch(langId);
      break;
   case 'ctl_XW_autoSymbolTrans_check':
      value = (int)LanguageSettings.getAutoSymbolTranslation(langId);
      break;
   case 'tag_lowcase':
   case 'tag_cap':
   case 'tag_upcase':
      switch(LanguageSettings.getTagCase(langId, WORDCASE_UPPER)) {
      case WORDCASE_LOWER:
         value = 'tag_lowcase';
         break;
      case WORDCASE_CAPITALIZE:
         value = 'tag_cap';
         break;
      case WORDCASE_UPPER:
         value = 'tag_upcase';
         break;
      }
      break;
   case 'attrib_lowcase':
   case 'attrib_cap':
   case 'attrib_upcase':
      switch(LanguageSettings.getAttributeCase(langId, WORDCASE_UPPER)) {
      case WORDCASE_LOWER:
         value = 'attrib_lowcase';
         break;
      case WORDCASE_CAPITALIZE:
         value = 'attrib_cap';
         break;
      case WORDCASE_UPPER:
         value = 'attrib_upcase';
         break;
      }
      break;
   case 'sword_lowcase':
   case 'sword_cap':
   case 'sword_upcase':
      switch(LanguageSettings.getValueCase(langId, WORDCASE_UPPER)) {
      case WORDCASE_LOWER:
         value = 'sword_lowcase';
         break;
      case WORDCASE_CAPITALIZE:
         value = 'sword_cap';
         break;
      case WORDCASE_UPPER:
         value = 'sword_upcase';
         break;
      }
      break;
   case 'html_hex_upcase':
   case 'html_hex_lowcase':
      if (LanguageSettings.getHexValueCase(langId) == WORDCASE_UPPER) {
         value = 'html_hex_upcase';
      } else {
         value = 'html_hex_lowcase';
      }
      break;
   case 'XW_selectSchemeDB':
      value = _GetXMLWrapFlags(XW_DEFAULT_SCHEME, langId);
      break;
   case 'XW_clt_CWcurrentDoc':
      value = _GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, langId);
      break;
   case 'XW_clt_TLcurrentDoc':
      value = _GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, langId);
      break;
   case '_lower':
   case '_upper':
   case '_capitalize':
   case '_none':
      kwCase := se.lang.api.LanguageSettings.getKeywordCase(langId);
      switch (kwCase) {
      case WORDCASE_LOWER:
         value = '_lower';
         break;
      case WORDCASE_UPPER:
         value = '_upper';
         break;
      case WORDCASE_CAPITALIZE:
         value = '_capitalize';
         break;
      case WORDCASE_PRESERVE:
         value = '_none';
         break;
      }
      break;
   case '_insmart':
      value = LanguageSettings.getSyntaxIndent(langId);
      break;
   case '_tabs':
      value = LanguageSettings.getTabs(langId);
      break;
   case '_indent_with_tabs':
      value = LanguageSettings.getIndentWithTabs(langId);
      break;
   }

   return value;
}

boolean _language_formatting_form_is_lang_included(_str controlName, _str langId, boolean allLangsExclusion)
{
   // all the new beautifier options are excluded from this...for now
   if (allLangsExclusion && new_beautifier_supported_language(langId)) {
      return false;
   }

   included := true;

   optionFlag := -1;

   switch (controlName) {
   case '_style0':
   case '_style1':
   case '_style2':
      included = (!allLangsExclusion || !isLangExcludedFromAllLangsBraceStyle(langId));
      optionFlag = LOI_BEGIN_END_STYLE;
      break;
   case '_no_space':
      optionFlag = LOI_NO_SPACE_BEFORE_PAREN;
      break;
   case 'ctl_pad_between_parens':
      optionFlag = LOI_PAD_PARENS;
      break;
   case '_quick_brace':
      optionFlag = LOI_QUICK_BRACE;
      break;
   case '_ctl_cuddle_else':
      optionFlag = LOI_CUDDLE_ELSE;
      break;
   case 'ctlUseContOnParameters':
      optionFlag = LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS;
      break;
   case '_indent_case':
      optionFlag = LOI_INDENT_CASE_FROM_SWITCH;
      break;
   case 'ctl_XW_autoSymbolTrans_check':
      optionFlag = LOI_AUTO_SYMBOL_TRANSLATION;
      break;
   case '_ctl_frame_tag_case':
      optionFlag = LOI_TAG_CASE;
      break;
   case '_ctl_frame_attrib_case':
      optionFlag = LOI_ATTRIBUTE_CASE;
      break;
   case '_ctl_frame_word_value_case':
      optionFlag = LOI_WORD_VALUE_CASE;
      break;
   case '_ctl_frame_hex_value_case':
      optionFlag = LOI_HEX_VALUE_CASE;
      break;
   case '_ctl_frame_auto_format':
      included = XW_isSupportedLanguage(langId);
      break;
   case '_ctl_frame_keyword_case':
      optionFlag = LOI_KEYWORD_CASE;
      break;
   case '_tabs':
   case '_indent_with_tabs':
      // only exclude for all languages, do not disable the controls
      included = (!allLangsExclusion || !isLangExcludedFromAllLangsTabs(langId));
      break;
   case '_insmart':
      included = _is_syntax_indent_supported(langId);
      break;
   }

   if (optionFlag != -1) {
      included = included && LanguageSettings.doesOptionApplyToLanguage(langId, optionFlag);
   }

   return included;
}

void _language_formatting_form_save_state()
{
   _language_form_save_state();
}

boolean _language_formatting_form_is_modified()
{
   return _language_form_is_modified();
}

boolean _language_formatting_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {

      // verify auto syntax indent
      if (!validateLangIntTextBox(_insmart.p_window_id)) {
         return false;
      }

      // see if tabs are okay
      tabs := '';
      if (_language_form_control_needs_validation(_tabs.p_window_id, tabs)) {
         if (_tabs.p_text=='') {
            _tabs._text_box_error("Please enter a tabs value.");
            return false;
         }
      }

      if (tabs == null || tabs == '') {
         tabs = _tabs.p_text;
      }
      typeless tab_distance = get_tab_distance(tabs);
      if (tab_distance != _insmart.p_text) {
         typeless tab_distance2 = get_end_tab(tabs);
         if (tab_distance2 == _insmart.p_text) {
            tab_distance = tab_distance2;//If the last tab in the string was valid
         }                              //Take that value if the first wasn't valid
      }

      // verify that tabs = indent, and if not, that this is okay
      typeless result = 0;
      if ((tab_distance != _insmart.p_text) && !PROMPT_TABS_DIFFER && _insmart.p_enabled){
         PROMPT_TABS_DIFFER = 1;//Signifies user was asked once
         result = _message_box("You have selected tab stops which differ from the Smart indent amount.\n\nAre you sure this is what you want?",
                               '',
                               MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result == IDCANCEL||result == IDNO) {
            PROMPT_TABS_DIFFER = 0;

            /*The Changing of PROMPT_TABS_DIFFER is not really necessary in this case
              because If the user presses yes, the window closes.  However, if
              this is not the Update button is pressed, this is more crucial so
              I left it in to remind me when I do the Update button
            */

            p_window_id= _tabs;
            _set_sel(1,length(p_text)+1);_set_focus();
            return false;
         }
      }
   }

   // phew!  we made it!
   return true;
}

void _language_formatting_form_restore_state()
{
   _language_form_restore_state(_language_formatting_form_get_value, 
                                _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(_get_language_form_lang_id());
}

boolean _language_formatting_form_apply()
{
   _language_form_apply(_language_formatting_form_apply_control);

   return true;
}

_str _language_formatting_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   switch (controlName) {
   case '_style0':
      LanguageSettings.setBeginEndStyle(langId, BES_BEGIN_END_STYLE_1);

      updateKey = BEGIN_END_STYLE_UPDATE_KEY;
      updateValue = BES_BEGIN_END_STYLE_1;
      break;
   case '_style1':
      LanguageSettings.setBeginEndStyle(langId, BES_BEGIN_END_STYLE_2);

      updateKey = BEGIN_END_STYLE_UPDATE_KEY;
      updateValue = BES_BEGIN_END_STYLE_2;
      break;
   case '_style2':
      LanguageSettings.setBeginEndStyle(langId, BES_BEGIN_END_STYLE_3);

      updateKey = BEGIN_END_STYLE_UPDATE_KEY;
      updateValue = BES_BEGIN_END_STYLE_3;
      break;
   case '_no_space':
      LanguageSettings.setNoSpaceBeforeParen(langId, ((int)value != 0));

      updateKey = NO_SPACE_BEFORE_PAREN_UPDATE_KEY;
      updateValue = value;
      break;
   case 'ctl_pad_between_parens':
      LanguageSettings.setPadParens(langId, ((int)value != 0));

      updateKey = PAD_PARENS_UPDATE_KEY;
      updateValue = value;
      break;
   case '_quick_brace':
      LanguageSettings.setQuickBrace(langId, ((int)value != 0));
      break;
   case '_ctl_cuddle_else':
      LanguageSettings.setCuddleElse(langId, ((int)value != 0));

      updateKey = CUDDLE_ELSE_UPDATE_KEY;
      updateValue = value;
      break;
   case '_indent':
      LanguageSettings.setIndentFirstLevel(langId, (int)value);
      break;
   case 'ctlUseContOnParameters':
      LanguageSettings.setUseContinuationIndentOnFunctionParameters(langId, ((int)value != 0));
      break;
   case '_indent_case':
      LanguageSettings.setIndentCaseFromSwitch(langId, ((int)value != 0));

      updateKey = INDENT_CASE_FROM_SWITCH_UPDATE_KEY;
      updateValue = value;
      break;
   case 'ctl_XW_autoSymbolTrans_check':
      LanguageSettings.setAutoSymbolTranslation(langId, ((int)value != 0));
      break;
   case 'tag_lowcase':
      LanguageSettings.setTagCase(langId, WORDCASE_LOWER);

      updateKey = TAG_CASING_UPDATE_KEY;
      updateValue = WORDCASE_LOWER;
      set_html_scheme_value('tagcase', WORDCASE_LOWER);
      break;
   case 'tag_cap':
      LanguageSettings.setTagCase(langId, WORDCASE_CAPITALIZE);

      updateKey = TAG_CASING_UPDATE_KEY;
      updateValue = WORDCASE_CAPITALIZE;
      set_html_scheme_value('tagcase', WORDCASE_CAPITALIZE);
      break;
   case 'tag_upcase':
      LanguageSettings.setTagCase(langId, WORDCASE_UPPER);

      updateKey = TAG_CASING_UPDATE_KEY;
      updateValue = WORDCASE_UPPER;
      set_html_scheme_value('tagcase', WORDCASE_UPPER);
      break;
   case 'attrib_lowcase':
      LanguageSettings.setAttributeCase(langId, WORDCASE_LOWER);

      updateKey = ATTRIBUTE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_LOWER;
      set_html_scheme_value('attribcase', WORDCASE_LOWER);
      break;
   case 'attrib_cap':
      LanguageSettings.setAttributeCase(langId, WORDCASE_CAPITALIZE);

      updateKey = ATTRIBUTE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_CAPITALIZE;
      set_html_scheme_value('attribcase', WORDCASE_CAPITALIZE);
      break;
   case 'attrib_upcase':
      LanguageSettings.setAttributeCase(langId, WORDCASE_UPPER);

      updateKey = ATTRIBUTE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_UPPER;
      set_html_scheme_value('attribcase', WORDCASE_UPPER);
      break;
   case 'sword_lowcase':
      LanguageSettings.setValueCase(langId, WORDCASE_LOWER);

      updateKey = VALUE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_LOWER;
      set_html_scheme_value('wordvalcase', WORDCASE_LOWER);
      break;
   case 'sword_cap':
      LanguageSettings.setValueCase(langId, WORDCASE_CAPITALIZE);

      updateKey = VALUE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_CAPITALIZE;
      set_html_scheme_value('wordvalcase', WORDCASE_CAPITALIZE);
      break;
   case 'sword_upcase':
      LanguageSettings.setValueCase(langId, WORDCASE_UPPER);

      updateKey = VALUE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_UPPER;
      set_html_scheme_value('wordvalcase', WORDCASE_UPPER);
      break;
   case 'html_hex_upcase':
      LanguageSettings.setHexValueCase(langId, WORDCASE_UPPER);

      updateKey = HEX_VALUE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_UPPER;
      set_html_scheme_value('hexvalcase', WORDCASE_UPPER);
      break;
   case 'html_hex_lowcase':
      LanguageSettings.setHexValueCase(langId, WORDCASE_LOWER);

      updateKey = HEX_VALUE_CASING_UPDATE_KEY;
      updateValue = WORDCASE_LOWER;
      set_html_scheme_value('hexvalcase', WORDCASE_LOWER);
      break;
   case 'XW_selectSchemeDB':
      _SetXMLWrapFlags(XW_DEFAULT_SCHEME, value, langId);
      break;
   case 'XW_clt_CWcurrentDoc':
      _SetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, value, langId);
      break;
   case 'XW_clt_TLcurrentDoc':
      _SetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, value, langId);
      break;
   case '_lower':
      LanguageSettings.setKeywordCase(langId, WORDCASE_LOWER);

      updateKey = KEYWORD_CASING_UPDATE_KEY;
      updateValue = WORDCASE_LOWER;
      break;
   case '_upper':
      LanguageSettings.setKeywordCase(langId, WORDCASE_UPPER);

      updateKey = KEYWORD_CASING_UPDATE_KEY;
      updateValue = WORDCASE_UPPER;
      break;
   case '_capitalize':
      LanguageSettings.setKeywordCase(langId, WORDCASE_CAPITALIZE);

      updateKey = KEYWORD_CASING_UPDATE_KEY;
      updateValue = WORDCASE_CAPITALIZE;
      break;
   case '_none':
      LanguageSettings.setKeywordCase(langId, WORDCASE_PRESERVE);

      updateKey = KEYWORD_CASING_UPDATE_KEY;
      updateValue = WORDCASE_PRESERVE;
      break;
   case '_tabs':
      updateKey = TABS_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setTabs(langId, value);
      break;
   case '_indent_with_tabs':
      updateKey = INDENT_WITH_TABS_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setIndentWithTabs(langId, value != 0);
      break;
   case '_insmart':
      updateKey = SYNTAX_INDENT_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setSyntaxIndent(langId, (int)value);
      break;
   }

   return updateKey' 'updateValue;
}

#endregion Options Dialog Helper Functions

void _language_formatting_form.on_destroy()
{
   _language_form_on_destroy();
}

_insmart.on_change()
{
   if (_insmart.p_text == 0 && _insmart.p_enabled) {
      _message_box('Syntax Indent Amount Must be Greater Than 0');
   }
   PROMPT_TABS_DIFFER=0;//Signifies user was not yet asked if Syntax Indent
                  //differs from tabs
}

_insmart.enter()
{
   if (_insmart.p_text == 0 && _insmart.p_enabled) {
      _message_box('Syntax Indent Amount Must be Greater Than 0');
      return('');
   }
}

// This should work for any adaptive formatting link
void _ad_form_link.lbutton_up()
{
   showAdaptiveFormattingOptionsForLanguage();
}

void _tabs.on_change()
{
   PROMPT_TABS_DIFFER=0;//Signifies user was not yet asked if Syntax Indent
                  //differs from tabs
}

/**
 * Comment matching function. 
 * @see _common_comment_maybe_update_lexer 
 */
typedef boolean (*CommentMatchFn)(COMMENT_TYPE*, _str, _str);


/**
 * Adds the given comment to the lexer if 
 * the comment isn't already defined. 
 * 
 * 
 * @param lexername Name of the lexer
 * @param delim1 The first delimiter.  (the only one for line 
 *               comments).
 * @param delim2 For block comments, the closing delimiter.
 * @param fieldname Field name of the comment type we're 
 *                  updating in the .vlx file.
 * @param matcher Function that compares a COMMENT_TYPE and 
 *                delim1 & delim2 to see if they match.
 *  
 * @see CommentMatchFn 
 */
void _common_comment_maybe_update_lexer(_str lexername, _str delim1, _str delim2, _str fieldname, CommentMatchFn matcher)
{
   _str lexerfile = _FindLexerFile(lexername);

   if (lexerfile == '') {
      return;
   }

   _str seclines[] = null;
   int config_updated = 0;

   if (_ini_get_section_array(lexerfile, lexername, seclines)) {
      message("Could not load config for " :+ lexerfile :+ "/" :+ lexername);
      return;
   }

   _str ln;
   foreach (ln in seclines) {
      if (pos(fieldname, ln) == 0) {
         continue;
      }

      COMMENT_TYPE ty = _process_comment(ln);

      if ((*matcher)(&ty, delim1, delim2)) {
         // Found it, no need to modify lexer.
         //say("Found delimiter: " :+ comment_delim);
         return;
      }
  }

   // If we got here, the delim is not defined in the language lexer.
//   _str reply = _message_box("The Color Coding configuration should be", "Overwrite extension", 
//                             MB_YESNO | MB_ICONQUESTION);
   if (delim2 == '') {
      seclines[seclines._length()] = fieldname :+ "=\"" :+ delim1 :+ "\"";
   } else {
      // spaces supported in line comments, but not here in block comments.
      seclines[seclines._length()] = fieldname :+ "=" :+ delim1 :+ " " :+ delim2;
   }


   _str txt = '';

   foreach (ln in seclines) {
      txt :+= ln;
      txt :+= "\n";
   }

   // Update user's lexer file.  (not the system one :)
   _str user_lexerfile = _ConfigPath():+USER_LEXER_FILENAME;


   // This first line ensures the user.vlx is created, so
   // the following lines can succeed.
   _ini_set_value(user_lexerfile, lexername, "x", "y");
   _ini_delete_section(user_lexerfile, lexername);
   _ini_append_section(user_lexerfile, lexername, txt, false);

   // Keep config happy and update open buffers with our changes.
   _config_modify_flags(CFGMODIFY_OPTION);
   _clex_load(user_lexerfile);
   _update_buffers(_LexerName2LangId(lexername), LEXER_NAME_UPDATE_KEY'='lexername);
   call_list("_lexer_updated_", lexername);
}


boolean _line_comment_match(COMMENT_TYPE* ty, _str delim1, _str delim2) 
{
   return ty->delim1 :== delim1;
}

boolean _block_comment_match(COMMENT_TYPE* ty, _str delim1, _str delim2)
{
   return ty->delim1 :== delim1 && ty->delim2 :== delim2;
}


/**
 * Updates the lexer def with the single line comment type, 
 * if it does not already exist. 
 * 
 * 
 * @param lexername 
 * @param comment_delim 
 */
void _line_comment_maybe_update_lexer(_str lexername, _str comment_delim) 
{
   _common_comment_maybe_update_lexer(lexername, comment_delim, '', 'linecomment', _line_comment_match);
}

/**
 * Updates the lexer def with the block comment type, 
 * if it does not already exist. 
 * 
 * 
 * @param lexername 
 * @param begin_delim 
 * @param end_delim 
 */
void _block_comment_maybe_update_lexer(_str lexername, _str begin_delim, _str end_delim) 
{
   _common_comment_maybe_update_lexer(lexername, begin_delim, end_delim, 'mlcomment', _block_comment_match);
}


