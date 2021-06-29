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
#require "se/lang/api/BlockCommentSettings.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "adaptiveformatting.e"
#import "aliasedt.e"
#import "alias.e"
#import "alllanguages.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "box.e"
#import "c.e"
#import "cfg.e"
#import "clipbd.e"
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
#import "listedit.e"
#import "listproc.e"
#import "main.e"
#import "math.e"
#import "mouse.e"
#import "options.e"
#import "optionsxml.e"
#import "picture.e"
#import "ppedit.e"
#import "proctree.e"
#import "reflow.e"
#import "recmacro.e"
#import "seldisp.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "taggui.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "slickc.e"
#import "xmlwrap.e"
#import "xmldoc.e"
#endregion
 
using se.lang.api.BlockCommentSettings;
using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;
using se.color.SymbolColorAnalyzer;

static const NONE_LANGUAGES=           "(None)";
static const IGNORESUFFIX_LANGUAGES=   "(Ignore File Suffix)";
static const PLAINTEXT_LANGUAGES=      "(Plain Text)";
static const DEFAULT_ENCODING=         "Automatic";

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

// whether user was asked if Syntax Indent differs from tabs
static int PROMPT_TABS_DIFFER(...) {
   if (arg()) _tabs.p_user=arg(1);
   return _tabs.p_user;
}
static typeless SMARTPASTE_INDEX(...) {
   if (arg()) _smartp.p_user=arg(1);
   return _smartp.p_user;
}

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
   lang := "";
   tabNumber := "";
   while (extOptions != '') {
      word := "";
      parse extOptions with word extOptions;
      if (_first_char(word)=='-') {
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
         case 'interactiveprofiles':         
            tabNumber = 'Interactive Profiles';
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
      lang = _LangGetModeName(lang);
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
   modeName := _LangGetModeName(language);

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
      langId=_LangGetProperty(langId,VSLANGPROPNAME_INHERITS_FROM);
      if (langId=='') return;

      ancestors[ancestors._length()] == langId;
   }
}

/**
 * 
 * @param langId
 * @param return_true_if_uses_syntax_indent_property 
 * 
 * @return 
 *           <p>When
 *           return_true_if_uses_syntax_indent_property== true,
 *           indicates whether this language should allow the
 *           p_SyntaxIndent property to be set. For example,
 *           this returns false for fundamental so that the Tab
 *           key uses the tab stops and not syntax indent. For
 *           cob (Cobol), this returns true which may seem odd
 *           but the cob_tab command takes care of making sure
 *           the Tab key uses the tab stops. asm390 returns true
 *           because it also uses the cob_tab command. The masm,
 *           unixasm, and npasm assembly languages use ext_keys
 *           and return true for this. Keep in mind that even if
 *           the p_SyntaxIndent is configurable by the use, it
 *           can be set to 0 so that the Tab key uses the tab
 *           stops.
 *           <p>When
 *           return_true_if_uses_syntax_indent_property==false,
 *           indicates whether smart indenting (smart syntax
 *           indenting) with the Enter key is supported.
 */
bool _is_syntax_indent_supported(_str langId,bool return_true_if_uses_syntax_indent_property=true) {
   if (langId==ALL_LANGUAGES_ID) {
      return true;
   }
   index := _FindLanguageCallbackIndex('_%s_supports_syntax_indent',langId);
   if (index<=0) {
      eventtab_name:=_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME);
      if (eventtab_name=='c-keys' || eventtab_name=='csharp-keys' ||
          // ext_space command supports alias expansion which supports p_SyntaxIndent property
          (return_true_if_uses_syntax_indent_property && eventtab_name=='ext-keys') || 
          eventtab_name=='xml-keys' || eventtab_name=='java-keys') {
         return true;
      }
      // ext_space command supports alias expansion which supports p_SyntaxIndent property
      if (eventtab_name!='' && return_true_if_uses_syntax_indent_property) {
         // Check if ext_space command is bound to space key for this mode
         etab_index:=find_index(eventtab_name,EVENTTAB_TYPE);
         if (etab_index>0) {
            cmd_index:=eventtab_index(etab_index,etab_index,event2index(' '));
            if (name_name(cmd_index)=='ext-space') {
               return true;
            }
         }
      }
      return false;
   }
   return call_index(return_true_if_uses_syntax_indent_property,index);
}
bool _is_syntax_indent_tab_style_supported(_str langId) {
   if (langId==ALL_LANGUAGES_ID) {
      return false;
   }

   eventtab_name:=_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME);
   // ext_space command supports alias expansion which supports p_SyntaxIndent property
   if (eventtab_name!='') {
      // Check if ext_space command is bound to space key for this mode
      etab_index:=find_index(eventtab_name,EVENTTAB_TYPE);
      if (etab_index>0) {
         cmd_index:=eventtab_index(etab_index,etab_index,event2index(TAB));
         n:=name_name(cmd_index);
         if (n:=='' || n:!='cob-tab') {
         } else {
            return false;
         }
      }
   }

   return _is_syntax_indent_supported(langId);
}
bool _is_insert_begin_end_immediately_supported(_str langId) {
   if (langId==ALL_LANGUAGES_ID) {
      return true;
   }
   index := _FindLanguageCallbackIndex('_%s_supports_insert_begin_end_immediately',langId);
   if (index<=0) {
      eventtab_name:=_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME);
      if (eventtab_name=='c-keys' || eventtab_name=='java-keys') {
         return true;
      }
      return false;
   }
   return call_index(index);
}

bool _is_smarttab_supported(_str ext)
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
   _str profileNames[];
   _plugin_list_profiles(VSCFGPACKAGE_COLORCODING_PROFILES,profileNames);
   for (i:=0;i<profileNames._length();++i) {
      _lbadd_item(profileNames[i]);
   }
   _lbsort('i');
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
      if (codePageValue != null && codePageValue != "") {
         openEncodingTab[i].codePage = (int)codePageValue;
      } else {
         openEncodingTab[i].codePage = -1;
      }

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
      if (openEncodingTab[ctlencoding.p_line-1].codePage<0) {
         new_encoding_info='';
      } else {
         new_encoding_info='+fcp'openEncodingTab[ctlencoding.p_line-1].codePage;
      }
   }
   return(new_encoding_info);
}

void _EncodingFillComboList(_str encoding='',_str defaultSetting=DEFAULT_ENCODING,int SkipFlags=0)
{
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   int i;
   init_i := 0;
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
void _lbaddFileExtensions()
{
   _str extList[];
   _GetAllExtensions(extList);
   for (i := 0; i < extList._length(); i++) {
      _lbadd_item(extList[i]);
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

   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i := 0; i < langs._length(); i++) {
      name := langs[i];

      do {
         if (options == 'I' && !_IsInstalledLanguage(name)) break;
         if (options == 'U' && _IsInstalledLanguage(name)) break;
         _lbadd_item(_LangGetModeName(name));
      } while (false);
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
   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i := 0; i < langs._length(); i++) {
      name := langs[i];

     if (_IsInstalledLanguage(name)) {
        _lbadd_item(_LangGetModeName(name), 100, _pic_lbvs);
     } else {
        _lbadd_item(_LangGetModeName(name), 100);
     }
   }
}

_str get_file_extensions_sorted_with_dot(_str lang)
{
   list := _LangGetExtensions(lang);
   _str extensions[];
   split(list, ' ',  extensions);

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

      mode := _LangGetModeName(refLangID);
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
   list := _LangGetExtensions(lang);
   _str extensions[];
   split(list, ' ',  extensions);

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
VSCodeHelpFlags _ext_codehelp_flags(_str lang='')
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
VSCodeHelpFlags _GetCodehelpFlags(_str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }

   return LanguageSettings.getCodehelpFlags(lang);
}

/**
 * Determines if the string contains more than one semicolon.
 * 
 * @param BeginEndString         string to check
 * 
 * @return                       true if more than one semicolon is found in the 
 *                               string, false if <= 1 semicolons are found
 */
static bool HasMultipleSemiColons(_str BeginEndString)
{
   count := 0;
   p := 0;
   for (;;) {
      p=pos(';',BeginEndString,p+1);
      if (!p) break;
      ++count;
      if (count>1) break;
   }
   return(count>1);
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
   return '';
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


      // sometimes we get the short keys instead of the update keys, translate them
      switch (upcase(key)) {
      case MODE_NAME_SHORT_KEY:
         key = MODE_NAME_UPDATE_KEY;
         break;
      case TABS_SHORT_KEY:
         key = TABS_UPDATE_KEY;
         break;
      case MARGINS_SHORT_KEY:
         key = MARGINS_UPDATE_KEY;
         break;
      case KEY_TABLE_SHORT_KEY:
         key = KEY_TABLE_UPDATE_KEY;
         break;
      case WORD_WRAP_SHORT_KEY:
         key = WORD_WRAP_UPDATE_KEY;
         break;
      case INDENT_WITH_TABS_SHORT_KEY:
         key = INDENT_WITH_TABS_UPDATE_KEY;
         break;
      case SHOW_TABS_SHORT_KEY:
         key = SHOW_TABS_UPDATE_KEY;
         break;
      case INDENT_STYLE_SHORT_KEY:
         key = INDENT_STYLE_UPDATE_KEY;
         break;
      case WORD_CHARS_SHORT_KEY:
         key = WORD_CHARS_UPDATE_KEY;
         break;
      case LEXER_NAME_SHORT_KEY:
         key = LEXER_NAME_UPDATE_KEY;
         break;
      case COLOR_FLAGS_SHORT_KEY:
         key = COLOR_FLAGS_UPDATE_KEY;
         break;
      case LINE_NUMBERS_LEN_SHORT_KEY:
         key = LINE_NUMBERS_LEN_UPDATE_KEY;
         break;
      case TRUNCATE_LENGTH_SHORT_KEY:
         key = TRUNCATE_LENGTH_UPDATE_KEY;
         break;
      case SOFT_WRAP_SHORT_KEY:
         key = SOFT_WRAP_UPDATE_KEY;
         break;
      case SHOW_MINIMAP_SHORT_KEY:
         key = SHOW_MINIMAP_UPDATE_KEY;
         break;
      case HEX_NOFCOLS_SHORT_KEY:
         key = HEX_NOFCOLS_UPDATE_KEY;
         break;
      case HEX_BYTES_PER_COL_SHORT_KEY:
         key = HEX_BYTES_PER_COL_UPDATE_KEY;
         break;
      case SOFT_WRAP_ON_WORD_SHORT_KEY:
         key = SOFT_WRAP_ON_WORD_UPDATE_KEY;
         break;
      case HEX_MODE_SHORT_KEY:
         key = HEX_MODE_UPDATE_KEY;
         break;
      case AUTO_LEFT_MARGIN_SHORT_KEY:
         key = AUTO_LEFT_MARGIN_UPDATE_KEY;
         break;
      case FIXED_WIDTH_RIGHT_MARGIN_SHORT_KEY:
         key = FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY;
         break;
      }

      updateTable:[key] = value;
   }
}

void _get_update_table_for_language_from_settings(_str langId, _str (&updateTable):[])
{
   // first, get the stuff in the language definition
   updateList := _get_default_update_list(langId);
   _build_update_table_from_list(updateList, updateTable);

   // now add the other stuff that is not included in the definition
   updateTable:[SHOW_SPECIAL_CHARS_UPDATE_KEY] = LanguageSettings.getShowTabs(langId);
   updateTable:[WORD_CHARS_UPDATE_KEY] = LanguageSettings.getWordChars(langId);
   updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY] = LanguageSettings.getAdaptiveFormattingFlags(langId);
   updateTable:[SYNTAX_INDENT_UPDATE_KEY] = LanguageSettings.getSyntaxIndent(langId);

   // some things do not apply to all languages
   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_BEGIN_END_STYLE)) {
      updateTable:[BEGIN_END_STYLE_UPDATE_KEY] = LanguageSettings.getBeginEndStyle(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_NO_SPACE_BEFORE_PAREN)) {
      updateTable:[NO_SPACE_BEFORE_PAREN_UPDATE_KEY] = LanguageSettings.getNoSpaceBeforeParen(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_INDENT_CASE_FROM_SWITCH)) {
      updateTable:[INDENT_CASE_FROM_SWITCH_UPDATE_KEY] = LanguageSettings.getIndentCaseFromSwitch(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_PAD_PARENS)) {
      updateTable:[PAD_PARENS_UPDATE_KEY] = LanguageSettings.getPadParens(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_POINTER_STYLE)) {
      updateTable:[POINTER_STYLE_UPDATE_KEY] = LanguageSettings.getPointerStyle(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_FUNCTION_BEGIN_ON_NEW_LINE)) {
      updateTable:[FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY] = LanguageSettings.getFunctionBeginOnNewLine(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_KEYWORD_CASE)) {
      updateTable:[KEYWORD_CASING_UPDATE_KEY] = LanguageSettings.getKeywordCase(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_TAG_CASE)) {
      updateTable:[TAG_CASING_UPDATE_KEY] = LanguageSettings.getTagCase(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_ATTRIBUTE_CASE)) {
      updateTable:[ATTRIBUTE_CASING_UPDATE_KEY] = LanguageSettings.getAttributeCase(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_WORD_VALUE_CASE)) {
      updateTable:[VALUE_CASING_UPDATE_KEY] = LanguageSettings.getValueCase(langId);
   }

   if (LanguageSettings.doesOptionApplyToLanguage(langId, LOI_HEX_VALUE_CASE)) {
      updateTable:[HEX_VALUE_CASING_UPDATE_KEY] = LanguageSettings.getHexValueCase(langId);
   }
}
void _get_update_table_for_all_buffer_settings(_str langId,_str (&updateTable):[]) {
   updateTable._makeempty();
   // Get some language specific settings. 
   _get_update_table_for_language_from_settings(langId,updateTable);
#if 0
   updateTable:[NO_SPACE_BEFORE_PAREN_UPDATE_KEY]=LanguageSettings.getNoSpaceBeforeParen(langId);
   updateTable:[INDENT_CASE_FROM_SWITCH_UPDATE_KEY]=LanguageSettings.getIndentCaseFromSwitch(langId);
   updateTable:[PAD_PARENS_UPDATE_KEY]=LanguageSettings.getPadParens(langId);
   updateTable:[KEYWORD_CASING_UPDATE_KEY]=LanguageSettings.getKeywordCase(langId);
   updateTable:[TAG_CASING_UPDATE_KEY]=LanguageSettings.getTagCase(langId);
   updateTable:[ATTRIBUTE_CASING_UPDATE_KEY]=LanguageSettings.getAttributeCase(langId);
   updateTable:[VALUE_CASING_UPDATE_KEY]=LanguageSettings.getValueCase(langId);
   updateTable:[HEX_VALUE_CASING_UPDATE_KEY]=LanguageSettings.getHexValueCase(langId);
   updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY]=LanguageSettings.getAdaptiveFormattingFlags(langId);
   updateTable:[SYNTAX_INDENT_UPDATE_KEY]=LanguageSettings.getSyntaxIndent(langId);
#endif

   updateTable:[LEXER_NAME_UPDATE_KEY]=LanguageSettings.getLexerName(langId);
   updateTable:[COLOR_FLAGS_UPDATE_KEY]=LanguageSettings.getColorFlags(langId);
   updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY]=LanguageSettings.getLineNumbersLength(langId);
   updateTable:[LINE_NUMBERS_FLAGS_UPDATE_KEY]=LanguageSettings.getLineNumbersFlags(langId);
   updateTable:[TRUNCATE_LENGTH_UPDATE_KEY]=LanguageSettings.getTruncateLength(langId);
   updateTable:[BOUNDS_UPDATE_KEY]=LanguageSettings.getBounds(langId);
   updateTable:[CAPS_UPDATE_KEY]=LanguageSettings.getCaps(langId);
   updateTable:[VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING]=LanguageSettings.getSpellCheckWhileTyping(langId);
   updateTable:[VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS]=LanguageSettings.getSpellCheckWhileTypingElements(langId);
   updateTable:[SHOW_MINIMAP_UPDATE_KEY]=LanguageSettings.getShowMinimap(langId);
   updateTable:[HEX_NOFCOLS_UPDATE_KEY]=LanguageSettings.getHexNofCols(langId);
   updateTable:[HEX_BYTES_PER_COL_UPDATE_KEY]=LanguageSettings.getHexBytesPerCol(langId);
   updateTable:[SOFT_WRAP_UPDATE_KEY]=LanguageSettings.getSoftWrap(langId);
   updateTable:[SOFT_WRAP_ON_WORD_UPDATE_KEY]=LanguageSettings.getSoftWrapOnWord(langId);
   updateTable:[HEX_MODE_UPDATE_KEY]=LanguageSettings.getHexMode(langId);
   //updateTable:[SHOW_SPECIAL_CHARS_UPDATE_KEY]=LanguageSettings.getShowTabs(langId);
   updateTable:[TABS_UPDATE_KEY]=LanguageSettings.getTabs(langId);
   updateTable:[MARGINS_UPDATE_KEY]=LanguageSettings.getMargins(langId);
   updateTable:[WORD_WRAP_UPDATE_KEY]=LanguageSettings.getWordWrapStyle(langId);
   updateTable:[INDENT_WITH_TABS_UPDATE_KEY]=LanguageSettings.getIndentWithTabs(langId);
   updateTable:[INDENT_STYLE_UPDATE_KEY]=LanguageSettings.getIndentStyle(langId);
   //updateTable:[WORD_CHARS_UPDATE_KEY]=LanguageSettings.getWordChars(langId);
   updateTable:[AUTO_LEFT_MARGIN_UPDATE_KEY]=LanguageSettings.getAutoLeftMargin(langId);
   updateTable:[FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY]=LanguageSettings.getFixedWidthRightMargin(langId);
   updateTable:[MODE_NAME_UPDATE_KEY]=LanguageSettings.getModeName(langId);
   updateTable:[KEY_TABLE_UPDATE_KEY]=LanguageSettings.getKeyTableName(langId);
}
static void maybe_use_override(_str prop_name,typeless (&updateTable):[],VS_LANGUAGE_OPTIONS &langOptions) {
    if (updateTable._indexin(prop_name)) {
       _str value=_LangOptionsGetProperty(langOptions,prop_name,null);
       if (value!=null) {
           updateTable:[prop_name]=value;
       }
    }
}
static void _update_cur_buffer(_str lang,typeless (&arg_updateTable):[],bool update_ad_form_now, bool update_ad_form_flags,int &progressWid,int &displayProgressCount,bool allow_ad_progress_dialog=true,bool apply_overrides=false) {
    typeless updateTable=arg_updateTable;
   if (updateTable._indexin(LEXER_NAME_UPDATE_KEY)) {
      lexerName := updateTable:[LEXER_NAME_UPDATE_KEY];
      if (!strieq(p_lexer_name, lexerName)) {
         p_lexer_name = lexerName;
      }
   }
	EDITOR_CONFIG_PROPERITIES ecprops;
    ecprops.m_property_set_flags=0;
	if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
        if (apply_overrides) {
            VS_LANGUAGE_OPTIONS langOptions=null;
            _LangOptionsApplyOverrides(langOptions,p_LangId,p_buf_name);

            maybe_use_override(VSLANGPROPNAME_TABS,updateTable,langOptions);
            maybe_use_override(VSLANGPROPNAME_INDENT_WITH_TABS,updateTable,langOptions);
            maybe_use_override(LOI_SYNTAX_INDENT,updateTable,langOptions);


            maybe_use_override(LOI_TAG_CASE,updateTable,langOptions);
            maybe_use_override(LOI_ATTRIBUTE_CASE,updateTable,langOptions);
            maybe_use_override(LOI_WORD_VALUE_CASE,updateTable,langOptions);
            maybe_use_override(LOI_HEX_VALUE_CASE,updateTable,langOptions);


            maybe_use_override(LOI_QUOTE_WORD_VALUES,updateTable,langOptions);
            maybe_use_override(LOI_QUOTE_NUMBER_VALUES,updateTable,langOptions);

            maybe_use_override(LOI_KEYWORD_CASE,updateTable,langOptions);

            maybe_use_override(LOI_BEGIN_END_STYLE,updateTable,langOptions);
            maybe_use_override(LOI_PAD_PARENS,updateTable,langOptions);
            maybe_use_override(LOI_NO_SPACE_BEFORE_PAREN,updateTable,langOptions);

            maybe_use_override(LOI_INDENT_CASE_FROM_SWITCH,updateTable,langOptions);

            maybe_use_override(LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS,updateTable,langOptions);

            maybe_use_override(LOI_FUNCTION_BEGIN_ON_NEW_LINE,updateTable,langOptions);

            maybe_use_override(LOI_CUDDLE_ELSE,updateTable,langOptions);

            maybe_use_override(LOI_POINTER_STYLE,updateTable,langOptions);

        } else {
            _EditorConfigGetProperties(p_buf_name,ecprops,p_LangId,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
        }
	}

   if (updateTable._indexin(COLOR_FLAGS_UPDATE_KEY)) {
      // don't modify the color coding flag
      int flags=updateTable:[COLOR_FLAGS_UPDATE_KEY];;
      p_color_flags = flags|(p_color_flags &LANGUAGE_COLOR_FLAG);
   }
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
   if (updateTable._indexin(VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING)) {
      if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
         p_spell_check_while_typing=false;
      } else {
         p_spell_check_while_typing = updateTable:[VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING];
      }
   }
   if (updateTable._indexin(VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS)) p_spell_check_while_typing_elements = updateTable:[VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS];
   if (updateTable._indexin(SHOW_MINIMAP_UPDATE_KEY)) p_show_minimap = updateTable:[SHOW_MINIMAP_UPDATE_KEY];
   if (updateTable._indexin(HEX_NOFCOLS_UPDATE_KEY)) p_hex_Nofcols = updateTable:[HEX_NOFCOLS_UPDATE_KEY];
   if (updateTable._indexin(HEX_BYTES_PER_COL_UPDATE_KEY)) p_hex_bytes_per_col = updateTable:[HEX_BYTES_PER_COL_UPDATE_KEY];
   if (updateTable._indexin(SOFT_WRAP_UPDATE_KEY)) p_SoftWrap = updateTable:[SOFT_WRAP_UPDATE_KEY];
   if (updateTable._indexin(SOFT_WRAP_ON_WORD_UPDATE_KEY)) p_SoftWrapOnWord = updateTable:[SOFT_WRAP_ON_WORD_UPDATE_KEY];
   if (updateTable._indexin(HEX_MODE_UPDATE_KEY)) p_hex_mode = updateTable:[HEX_MODE_UPDATE_KEY];
   if (updateTable._indexin(SHOW_SPECIAL_CHARS_UPDATE_KEY)) p_ShowSpecialChars = updateTable:[SHOW_SPECIAL_CHARS_UPDATE_KEY];

   if ( ! read_format_line() ) {
      if (updateTable._indexin(TABS_UPDATE_KEY) && !(ecprops.m_property_set_flags & (ECPROPSETFLAG_TAB_SIZE|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE))) p_tabs = updateTable:[TABS_UPDATE_KEY];
      if (updateTable._indexin(MARGINS_UPDATE_KEY)) p_margins = updateTable:[MARGINS_UPDATE_KEY];
      if (updateTable._indexin(WORD_WRAP_UPDATE_KEY)) p_word_wrap_style = updateTable:[WORD_WRAP_UPDATE_KEY];
      if (updateTable._indexin(INDENT_WITH_TABS_UPDATE_KEY) && !(ecprops.m_property_set_flags & (ECPROPSETFLAG_INDENT_WITH_TABS|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE))) p_indent_with_tabs = updateTable:[INDENT_WITH_TABS_UPDATE_KEY];
      //if (updateTable._indexin(SHOW_TABS_UPDATE_KEY)) p_show_tabs = updateTable:[SHOW_TABS_UPDATE_KEY];
      if (updateTable._indexin(INDENT_STYLE_UPDATE_KEY)) p_indent_style = updateTable:[INDENT_STYLE_UPDATE_KEY];
      if (updateTable._indexin(WORD_CHARS_UPDATE_KEY)) p_word_chars = updateTable:[WORD_CHARS_UPDATE_KEY];
      if (updateTable._indexin(AUTO_LEFT_MARGIN_UPDATE_KEY)) p_AutoLeftMargin = updateTable:[AUTO_LEFT_MARGIN_UPDATE_KEY];
      if (updateTable._indexin(FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY)) p_FixedWidthRightMargin = updateTable:[FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY];
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

   if (updateTable._indexin(BEGIN_END_STYLE_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_begin_end_style = updateTable:[BEGIN_END_STYLE_UPDATE_KEY];
   if (updateTable._indexin(NO_SPACE_BEFORE_PAREN_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_no_space_before_paren = updateTable:[NO_SPACE_BEFORE_PAREN_UPDATE_KEY];
   if (updateTable._indexin(INDENT_CASE_FROM_SWITCH_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_indent_case_from_switch = updateTable:[INDENT_CASE_FROM_SWITCH_UPDATE_KEY];
   if (updateTable._indexin(PAD_PARENS_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_pad_parens = updateTable:[PAD_PARENS_UPDATE_KEY];
   if (updateTable._indexin(POINTER_STYLE_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_pointer_style = updateTable:[POINTER_STYLE_UPDATE_KEY];
   if (updateTable._indexin(FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_function_brace_on_new_line = updateTable:[FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY];
   if (updateTable._indexin(KEYWORD_CASING_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_keyword_casing = updateTable:[KEYWORD_CASING_UPDATE_KEY];
   if (updateTable._indexin(TAG_CASING_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_tag_casing = updateTable:[TAG_CASING_UPDATE_KEY];
   if (updateTable._indexin(ATTRIBUTE_CASING_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_attribute_casing = updateTable:[ATTRIBUTE_CASING_UPDATE_KEY];
   if (updateTable._indexin(VALUE_CASING_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_value_casing = updateTable:[VALUE_CASING_UPDATE_KEY];
   if (updateTable._indexin(HEX_VALUE_CASING_UPDATE_KEY) && !(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) p_hex_value_casing = updateTable:[HEX_VALUE_CASING_UPDATE_KEY];

   // we update this if the flags changed
   // we also reset it when any of the values have changed
   if (updateTable._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY) || update_ad_form_flags) {
      p_adaptive_formatting_flags = updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY];
   }

	if (!(ecprops.m_property_set_flags & (ECPROPSETFLAG_SYNTAX_INDENT|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE))) {
		if (updateTable._indexin(SYNTAX_INDENT_UPDATE_KEY)) {
			p_SyntaxIndent = updateTable:[SYNTAX_INDENT_UPDATE_KEY];
		} else {
			// go ahead and set the syntax indent to the default
			p_SyntaxIndent = LanguageSettings.getSyntaxIndent(lang);
		}
	}
   if (update_ad_form_now) {
      updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS, false);
      if (allow_ad_progress_dialog) {
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
}

void _update_buffer_from_new_setting(_str (updateTable):[],_str langId='') {


   displayProgressCount := 0;
   progressWid := 0;

   // switch to hidden editor window
   get_window_id(auto orig_wid);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();

   // for each buffer
   first_buf_id := p_buf_id;
   for (;;) {
      // we have to call this so that the form gets painted
      // we don't want to do anything with it because we don't even have a cancel button
      /*if (update_ad_form_now) {
         cancel_form_cancelled();
      }*/
      _str lang = _getSupportedLangId(p_LangId);

      if (_LangIsDefined(lang) && (langId=='' || lang==langId)) {
         typeless updateTable2:[];
         foreach (auto key=>. in updateTable) {
            value:=_LangGetProperty(lang,key,null);
            if (value!=null /*value!='' || key!=VSLANGPROPNAME_TABS*/) {
               updateTable2:[key]=value;
            }
         }
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

         adaptiveFlags := adaptive_format_get_buffer_flags(lang);
         if (update_ad_form_flags) {
            // clear the embedded settings if we are changing anything that might affect adaptive formatting
            adaptive_format_clear_embedded(lang);

            if (!updateTable2._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY)) {
               // we have to reset the adaptive formatting settings, but we need to retrieve the flags
               updateTable2:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY] = adaptiveFlags;
            }
         }

         // do we update the indent settings in each buffer right now? - only if tabs are on and 
         // we have cleared the settings that we found
         // we want to update tabs NOW, otherwise, they will be typing along and suddenly the file
         // change appearance, and that is bad.
         update_ad_form_now := update_ad_form_flags && adaptive_format_is_flag_on_for_buffer(AFF_TABS, lang, adaptiveFlags); 

         _update_cur_buffer(lang,updateTable2,update_ad_form_now,update_ad_form_flags,progressWid,displayProgressCount,false,true);
      }

      // next please
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   /*if (update_ad_form_now && progressWid) {
      close_cancel_form(progressWid);
   } */

   // restore original window id
   activate_window(orig_wid);
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
void _update_buffers_from_table(_str lang, typeless (&updateTable):[] = null, bool resetAll=false, bool getSettingsTable=false, typeless (&settingsTable):[]:[]=null)
{
   bool apply_to_all_langids= (lang=='');
   if (lang=='') {
      lang='fundamental';
   }

   if (resetAll) {
      updateTable._makeempty();
      _get_update_table_for_all_buffer_settings('fundamental',updateTable);
   }
   if (updateTable == null) {
      _get_update_table_for_language_from_settings(lang, updateTable);
   }

   typeless found_match=0;
   get_window_id(auto view_id);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int first_buf_id=p_buf_id;

   displayProgressCount := 0;
   progressWid := 0;

   for (;;) {

      // Need to be able to set the extension options for a buffer
      // that has tagging disabled.  p_LangId==NotSupported_asm390
      _str supportedLang = _getSupportedLangId(p_LangId);
      found_match = (apply_to_all_langids || lang == supportedLang);

      if (found_match && !(resetAll && getSettingsTable && settingsTable._indexin(p_LangId))) {
         if (resetAll) {
            updateTable._makeempty();
            _get_update_table_for_all_buffer_settings(p_LangId,updateTable);
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
               updateTable:[LINE_NUMBERS_LEN_UPDATE_KEY] = LanguageSettings.getLineNumbersLength(p_LangId);;
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
            colorFlags := LanguageSettings.getColorFlags(p_LangId);
            updateTable:[COLOR_FLAGS_UPDATE_KEY] = colorFlags;
         }

         // might need to do some special adaptive formatting stuff
         adaptiveFlags := adaptive_format_get_buffer_flags(p_LangId);
         if (update_ad_form_flags) {
            // clear the embedded settings if we are changing anything that might affect adaptive formatting
            adaptive_format_clear_embedded(p_LangId);

            if (!updateTable._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY)) {
               // we have to reset the adaptive formatting settings, but we need to retrieve the flags
               updateTable:[ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY] = adaptiveFlags;
            }
         }

         // do we update the indent settings in each buffer right now? - only if tabs are on and 
         // we have cleared the settings that we found
         // we want to update tabs NOW, otherwise, they will be typing along and suddenly the file
         // change appearance, and that is bad.
         update_ad_form_now := update_ad_form_flags && adaptive_format_is_flag_on_for_buffer(AFF_TABS, p_LangId, adaptiveFlags); 

         // we have to call this so that the form gets painted
         // we don't want to do anything with it because we don't even have a cancel button
         if (update_ad_form_now) {
            cancel_form_cancelled();
         }
         if (getSettingsTable) {
            settingsTable:[p_LangId]=updateTable;
         } else {
            _update_cur_buffer(p_LangId,updateTable,update_ad_form_now,update_ad_form_flags,progressWid,displayProgressCount);
         }
      }
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   if (progressWid) {
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
   case SHOW_MINIMAP_SHORT_KEY:
      unifiedKey = SHOW_MINIMAP_UPDATE_KEY;
      break;
   case HEX_NOFCOLS_SHORT_KEY:
      unifiedKey = HEX_NOFCOLS_UPDATE_KEY;
      break;
   case HEX_BYTES_PER_COL_SHORT_KEY:
      unifiedKey = HEX_BYTES_PER_COL_UPDATE_KEY;
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
   newValue := null;
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
   case HEX_NOFCOLS_UPDATE_KEY:
   case HEX_BYTES_PER_COL_UPDATE_KEY:
      // these are just plain integers - if they're not, we don't want them at all
      if (isinteger(value)) {
         newValue = (int)value;
      } 
      break;
   case SHOW_MINIMAP_UPDATE_KEY:
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
 * Use {@link _LangSetProperty}, {@link
 * _SetLanguageSetupOptions}, {@link _SetDefaultLanguageOptions}
 * function, or the LanguageSettings API to change language
 * specific defaults.
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
 * @see _LangSetProperty 
 * @see _SetDefaultLanguageOptions 
 * @see _SetLanguageSetupOptions 
 * 
 * @categories Buffer_Functions
 */ 
void _update_buffers(_str lang, typeless updates = null)
{
   if ( lang=='' ) return;

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
   if (lang == "" && !_ExtensionGetIgnoreSuffix(ext)) {
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
      if (_file_eq(bufext,ext) && p_LangId != lang) {
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

/* End Extension Options form*/

defeventtab _add_language_form;

static const CREATE_LEXER_TEXT= "<Create new profile>";
static const SELECT_LANG_TEXT= "Select a language";

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
   while (_LangIsDefined(tempId)) {
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
   _ctl_lang_combo._lbadd_item(SELECT_LANG_TEXT);
   _ctl_lang_combo.p_text = _ctl_lang_combo._lbget_text();

   if (!_haveContextTagging()) {
      _ctl_tagging.p_visible = false;

      diff := (_ctl_tagging.p_y - _ctl_adaptive_formatting.p_y);
      _ctl_add.p_y -= diff;
      _ctl_cancel.p_y = ctlcommand1.p_y = _ctl_add.p_y;
      p_active_form.p_height -= diff;
   }
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

   if (_ctl_copy_settings.p_value && _ctl_lang_combo.p_text == SELECT_LANG_TEXT) {
      _message_box('Please select a language to copy settings from.');
      return;
   }

   // go through extensions and see if they point to other things
   _str extList[];
   split(extensions, ' ', extList);
   int i;
   atLeastOne := false;
   for (i = 0; i < extList._length(); i++) {
      ext := strip(extList[i]);
      currentMode := _LangGetModeName(_Ext2LangId(ext));
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

   // set the lexer
   lexerName := _lexer_name.p_text;
   if (lexerName == CREATE_LEXER_TEXT) {
      // create a new lexer using this mode name
      addNewBlankLexer(modeName);
      lexerName = modeName;
      set_refresh_lexer_list();
   } 

   VS_LANGUAGE_OPTIONS langOptions;

   _LangInitOptions(langOptions,true,modeName);
   if (lexerName != '') {
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_LEXER_NAME,lexerName);
      //LanguageSettings.setLexerName(langId, lexerName);
   }
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);
   _SetDefaultLanguageOptions(langId,langOptions);
   /*
   
      0. LOI_SYNTAX_INDENT
      1. LOI_SYNTAX_EXPANSION
      2. LOI_MIN_ABBREVIATION
      3. LOI_KEYWORD_CASE
      4. begin/end style
      5. not used??
      6. LOI_INDENT_CASE_FROM_SWITCH
#define DEFAULT_SYNTAX_INFO  '4 1 1 0 0 3 0'

   */

   // add the extensions which refer to this language
   for (i = 0; i < extList._length(); i++) {
      if (extList[i] != '') {
         _SetExtensionReferTo(extList[i], langId);
      }
   }

   copyLanguageSettings(langId);
   eventtab_name:=_LangGetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME);
   if (eventtab_name=='ext-keys') {
      j := 1;
      for (;;) {
         if (j<=1) {
            eventtab_name=langId:+"-keys";
         } else {
            eventtab_name=langId:+j:+"-keys";
         }
         if (!_plugin_has_builtin_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,eventtab_name)) {
            break;
         }
      }

      ext_keys_index:=find_index('ext-keys',EVENTTAB_TYPE);
      if (ext_keys_index) {
         etab_index:=_eventtab_get_mode_keys(eventtab_name);
         int key_index;
         int index;

         key_index=event2index(' ');
         index=eventtab_index(ext_keys_index,ext_keys_index,key_index);
         set_eventtab_index(etab_index,key_index,index);
         key_index=event2index('(');
         index=eventtab_index(ext_keys_index,ext_keys_index,key_index);
         set_eventtab_index(etab_index,key_index,index);

         _update_profile_for_eventtab(etab_index);
      }
      _LangSetProperty(langId,VSLANGPROPNAME_EVENTTAB_NAME,eventtab_name);
   }

   //_config_modify_flags(CFGMODIFY_DEFDATA);

   p_active_form._delete_window(modeName);

   // make the change in xml
   addNewLanguageToOptionsXML(langId);
}

void _lexer_name.on_change(int reason)
{
   _ctl_color_coding.p_enabled = (_lexer_name.p_text == CREATE_LEXER_TEXT && _ctl_copy_settings.p_value != 0);

   // maybe set the language to copy setings from
   if (_ctl_lang_combo.p_text == SELECT_LANG_TEXT && _lexer_name.p_text != CREATE_LEXER_TEXT) {
      lang := _LexerName2LangId(_lexer_name.p_text);
      lang = _LangGetModeName(lang);

      _ctl_lang_combo._lbfind_and_select_item(lang);
   }
}

void _ctl_copy_settings.LBUTTON_UP()
{
   enabled := (_ctl_copy_settings.p_value != 0);
   _ctl_lang_combo.p_enabled = _ctl_general.p_enabled = _ctl_indent.p_enabled = _ctl_view.p_enabled = 
      _ctl_word_wrap.p_enabled = _ctl_aliases.p_enabled = _ctl_comments.p_enabled = _ctl_autocomplete.p_enabled =
      _ctl_file_options.p_enabled = _ctl_keybindings.p_enabled = enabled;

   _ctl_adaptive_formatting.p_enabled = _ctl_tagging.p_enabled = enabled && _ctl_keybindings.p_value;
   _ctl_color_coding.p_enabled = enabled && (_lexer_name.p_text == CREATE_LEXER_TEXT);
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

bool _CopyLanguageOption(_str srcLang, _str destLang, _str fieldName)
{
   value:=_LangGetProperty(srcLang,fieldName,null);
   if (!value._isempty()) {
      _LangSetProperty(destLang,fieldName,value);
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
bool _copy_language_general_settings(_str srcLang, _str destLang)
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
 
   return _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_CONTEXT_MENU) && _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION) && 
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_BEGIN_END_PAIRS);
}

/**
 * Copies the options found at Language > Indent from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
bool _copy_language_indent_settings(_str srcLang, _str destLang)
{
   VS_LANGUAGE_OPTIONS srcLangInfo;
   VS_LANGUAGE_OPTIONS destLangInfo;
   LanguageSettings.getAllLanguageOptions(srcLang, srcLangInfo);
   LanguageSettings.getAllLanguageOptions(destLang, destLangInfo);
   
   _LangOptionsSetProperty(destLangInfo,VSLANGPROPNAME_TABS, _LangOptionsGetProperty(srcLangInfo,VSLANGPROPNAME_TABS));
   _LangOptionsSetProperty(destLangInfo,VSLANGPROPNAME_INDENT_WITH_TABS, _LangOptionsGetPropertyInt32(srcLangInfo,VSLANGPROPNAME_INDENT_WITH_TABS,0));
   _LangOptionsSetProperty(destLangInfo,VSLANGPROPNAME_INDENT_STYLE, _LangOptionsGetPropertyInt32(srcLangInfo,VSLANGPROPNAME_INDENT_STYLE,0));
   // Don't copy this
   //_LangOptionsSetProperty(destLangInfo,VSLANGPROPNAME_EVENTTAB_NAME, _LangOptionsGetProperty(srcLangInfo,VSLANGPROPNAME_EVENTTAB_NAME));
   _LangOptionsSetProperty(destLangInfo,LOI_SYNTAX_EXPANSION, _LangOptionsGetPropertyInt32(srcLangInfo,LOI_SYNTAX_EXPANSION,0));
   _LangOptionsSetProperty(destLangInfo,LOI_SYNTAX_INDENT, _LangOptionsGetPropertyInt32(srcLangInfo,LOI_SYNTAX_INDENT,0));
   _LangOptionsSetProperty(destLangInfo,LOI_MIN_ABBREVIATION, _LangOptionsGetPropertyInt32(srcLangInfo,LOI_MIN_ABBREVIATION,1));
   
   LanguageSettings.setAllLanguageOptions(destLang, destLangInfo);

   return _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_BACKSPACE_UNINDENTS) &&
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_SMART_PASTE) &&
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_SURROUND_FLAGS) &&
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_SMART_TAB);
   
}

/**
 * Copies the options found at Language > View from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
bool _copy_language_view_settings(_str srcLang, _str destLang)
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

   if (def_symbol_color_profile != "" && def_symbol_color_profile != CONFIG_AUTOMATIC) {
      //Reinitialize symbol analyzers
      se.color.SymbolColorRuleBase rb;
      rb.loadProfile(def_symbol_color_profile);
      SymbolColorAnalyzer.initAllSymbolAnalyzers(&rb,true);
   }

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
bool _copy_language_word_wrap_settings(_str srcLang, _str destLang)
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
bool _copy_language_autocomplete_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_AUTO_COMPLETE_FLAGS) &&
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_AUTO_COMPLETE_MIN);
}

/**
 * Copies the language inheritance and callbacks from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
bool _copy_language_inheritance(_str srcLang, _str destLang)
{
   // set the destination language to inherit from the source
   _LangSetProperty(destLang, VSLANGPROPNAME_INHERITS_FROM,srcLang);

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
bool _copy_language_adaptive_formatting_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING) &&
      _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS);
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
bool _copy_language_tagging_settings(_str srcLang, _str destLang)
{
   return _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_CODE_HELP_FLAGS);
}

/**
 * Copies the keytable from one language to another. 
 * 
 * @param srcLang          language to copy settings FROM
 * @param destLang         language to copy settings TO
 * 
 * @return                 true if successful, false otherwise
 */
bool _copy_language_keytable(_str srcLang, _str destLang)
{
   keytab := LanguageSettings.getKeyTableName(srcLang);
   if (keytab != '') {
      LanguageSettings.setKeyTableName(destLang, keytab);
      return true;
   }

   return false;
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
bool _copy_language_color_coding(_str srcLang, _str destLang)
{
   // get the name of the lexers
   srcLexer := LanguageSettings.getLexerName(srcLang);
   destLexer := _LangGetModeName(destLang);

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
bool _copy_language_aliases(_str srcLang, _str destLang)
{
   // Fetch source profile
   handle:=_plugin_get_profile(vsCfgPackage_for_Lang(srcLang),VSCFGPROFILE_ALIASES);
   if (handle>=0) {
      // Set profile path to dest profilePath
      profile:=_xmlcfg_set_path(handle,"/profile");
      _xmlcfg_set_attribute(handle,profile,VSXMLCFG_PROFILE_NAME,getAliasLangProfileName(destLang));
      _plugin_set_profile(handle);
   }
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
bool _copy_language_file_options(_str srcLang, _str destLang)
{
   // that's all there is to it
   return (_CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_LOAD_FILE_OPTIONS) && _CopyLanguageOption(srcLang, destLang, VSLANGPROPNAME_SAVE_FILE_OPTIONS));
}

#region Options Dialog Helper Functions (Languages > Language Manager)

defeventtab _manage_languages_form;

bool _manage_languages_form_is_modified()
{
   return false;
}

_str _manage_languages_form_get_tags()
{
   tags := '';
   
   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i := 0; i < langs._length(); i++) {
     tags :+= langs[i]' ';
   }
   
   return tags;
}

void _manage_languages_form.on_resize()
{
   padding := _ctl_languages.p_x;

   widthDiff := p_width - (_ctl_add.p_x_extent + padding);
   if (widthDiff) {
      _ctl_add.p_x += widthDiff;
      _ctl_delete.p_x = _ctl_setup.p_x = _ctl_add.p_x;
      _ctl_languages.p_width += widthDiff;
   }

   heightDiff := p_height - (_ctl_languages.p_y_extent + padding);
   if (heightDiff) {
      _ctl_languages.p_height += heightDiff;
   }
}

_ctl_add.on_create()
{
   refresh_languages();

   // disable this at first until we select something
   _ctl_setup.p_enabled = false;

   // match the longest button
   _ctl_setup.p_width = _ctl_add.p_width = _ctl_delete.p_width;
}

void _ctl_add.lbutton_up()
{
   newMode := show("-modal _add_language_form");
   // IF user cancelled
   if (newMode=='') return;
   refresh_languages();

   _ctl_languages._lbfind_and_select_item(newMode);
   // Look for buffers that look like they should be using this new language mode.
   langId:=_Modename2LangId(newMode);
     
   get_window_id(auto view_id);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int first_buf_id=p_buf_id;
   for (;;) {
      if (!(p_buf_flags & VSBUFFLAG_HIDDEN)) {
         if (_Filename2LangId(p_buf_name,F2LI_NO_CHECK_OPEN_BUFFERS|F2LI_NO_CHECK_PERFILE_DATA)==langId) {
            _SetEditorLanguage(langId);
         }
      }
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   activate_window(view_id);
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
   _ctl_languages.call_event(CHANGE_CLINE,_ctl_languages, ON_CHANGE,'W');

   // make the change in xml
   removeLanguageFromOptionsXML(modeName);

   // make sure we're not saving this lang's unsaved lexer info
   clear_unsaved_lexer_info_for_langId(langId);

   // For each buffer using this languages, select a different language mode.
   _safe_hidden_window();
   view_id := 0;
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

static void refresh_languages()
{
   _ctl_languages._lbclear();
   _ctl_languages.p_picture = _pic_lbvs;
   _ctl_languages.p_pic_space_y = 60;
   _ctl_languages.p_pic_point_scale = 8;
   _ctl_languages.get_all_mode_names_mark_installed();
   _ctl_languages._lbsort();
   _ctl_languages._lbtop();
}

#endregion Options Dialog Helper Functions (Languages > Language Manager)


#region Options Dialog Helper Functions (Languages > File Extension Manager)

defeventtab _manage_extensions_form;

int _manage_extensions_form_save_state()
{
   applyChangesToCurrentExtensionInfo();

   // everything is cool
   return 0;
}

void _manage_extensions_form_restore_state()
{
   // save the current extension, we're about to delete it
   curExt := CURRENT_EXTENSION();

   refresh_extensions_and_languages();

   // restore the current extension
   _ctl_extensions._lbfind_and_select_item(curExt);
}

bool _manage_extensions_form_is_modified()
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

      excludeFlags:=0; //OEFLAG_REMOVE_FROM_OPEN
      int i;
      init_i := 0;
      openEncodingTab[0].text=DEFAULT_ENCODING;
      for (i = 0; i < openEncodingTab._length(); ++i) {
         if (!(excludeFlags & openEncodingTab[i].OEFlags)) {
            tags :+= openEncodingTab[i].text' ';
         }
      }
   } 

   _str extList[];
   _GetAllExtensions(extList);
   for (i := 0; i < extList._length(); i++) {
      tags :+= extList[i]' ';
   }
   
   _str langs[];
   LanguageSettings.getAllLanguageIds(langs);
   for (i = 0; i < langs._length(); i++) {
      tags :+= langs[i]' ';
   }
   
   return tags;
}

static const EXT_LANG_IMPORT_LABEL=             'language';
static const EXT_ENCODING_IMPORT_LABEL=         'encoding';
static const EXT_OPEN_APP_IMPORT_LABEL=         'open application';
static const EXT_USE_FILE_ASSOC_IMPORT_LABEL=   'use file association';

_str _manage_extensions_form_build_export_summary(PropertySheetItem (&summary)[])
{
   error := '';
   PropertySheetItem psi;
   psi.ChangeEvents = 0;

   // get all the extensions
   _str extList[];
   _GetAllExtensions(extList);
   OPENENCODINGTAB openEncodingTab[];
   foreach (auto ext in extList) {
      // for each extension, we create a summary item for the language, encoding,
      // open app, and use file association
      psi.Caption = ext' 'EXT_LANG_IMPORT_LABEL;
      lang := ExtensionSettings.getLangRefersTo(ext);
      psi.Value = (lang != null) ? lang : '';
      summary[summary._length()] = psi;

      psi.Caption = ext' 'EXT_ENCODING_IMPORT_LABEL;
      psi.Value = encodingToTitle(ExtensionSettings.getEncoding(ext), openEncodingTab);
      summary[summary._length()] = psi;

      psi.Caption = ext' 'EXT_OPEN_APP_IMPORT_LABEL;
      psi.Value = ExtensionSettings.getOpenApplication(ext);
      summary[summary._length()] = psi;

      psi.Caption = ext' 'EXT_USE_FILE_ASSOC_IMPORT_LABEL;
      psi.Value = ExtensionSettings.getUseFileAssociation(ext) ? 'True' : 'False';
      summary[summary._length()] = psi;
   }

   return error;
}

_str _manage_extensions_form_import_summary(PropertySheetItem (&summary)[])
{
   error := '';

   PropertySheetItem psi;
   _str ext, label;
   foreach (psi in summary) {
      // key off the caption
      parse psi.Caption with ext label;
      if (ext != '' && label != '') {
         switch (label) {
         case EXT_LANG_IMPORT_LABEL:
            // see if this has changed
            if (ExtensionSettings.getLangRefersTo(ext) != psi.Value) {
               ExtensionSettings.setLangRefersTo(ext, psi.Value);
               _update_buffers_for_ext(ext);
            }
            break;
         case EXT_ENCODING_IMPORT_LABEL:
            ExtensionSettings.setEncoding(ext, _EncodingGetOptionFromTitle(psi.Value));
            break;
         case EXT_OPEN_APP_IMPORT_LABEL:
            ExtensionSettings.setOpenApplication(ext, psi.Value);
            break;
         case EXT_USE_FILE_ASSOC_IMPORT_LABEL:
            ExtensionSettings.setUseFileAssociation(ext, (psi.Value == 'True'));
            break;
         }
      }
   }

   // all done
   return error;
}

static _str CURRENT_EXTENSION(...) {
   if (arg()) _ctl_extensions.p_user=arg(1);
   return _ctl_extensions.p_user;
}
static const ALL_EXTENSIONS=     "All Extensions";
static const EXTENSIONS_DIFFER=  "Extensions Differ";

void _manage_extensions_form.on_resize()
{
   padding := _ctl_extensions.p_x;

   widthDiff := p_width - (_ctlae_labeldiv.p_x_extent + padding);
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

   heightDiff := p_height - (_ctl_new.p_y_extent);
   if (heightDiff) {
      _ctl_new.p_y += heightDiff;
      _ctl_delete.p_y = _ctl_new.p_y;

      _ctl_extensions.p_height += heightDiff;
   }
}

void applyChangesToCurrentExtensionInfo()
{
   ext := CURRENT_EXTENSION();
   if (ext == ALL_EXTENSIONS) {
      if (ctlencoding.p_text != EXTENSIONS_DIFFER) {
         new_encoding_info := _EncodingGetComboSetting();

         // set this encoding for all our extensions
         _str extList[];
         _GetAllExtensions(extList);
         for (i := 0; i < extList._length(); i++) {
            ExtensionSettings.setEncoding(extList[i], new_encoding_info);
         }
      }
   } else if (ext != "") {
      // has the refers to changed?
      langId := _Ext2LangId(ext);
      isIgnoreSuffixExt := _ExtensionGetIgnoreSuffix(ext);

      if (_ctl_languages.p_text == NONE_LANGUAGES) {
         // do nothing, this is the All languages case

      } else if (langId == "" && isIgnoreSuffixExt && _ctl_languages.p_text == IGNORESUFFIX_LANGUAGES) {
         // still ignoring suffix, do nothing.

      } else if (_LangGetModeName(langId) == _ctl_languages.p_text) {
         // extension is still bound to the same language mode
      
      } else {
         modeName := _ctl_languages.p_text;
         if (modeName == IGNORESUFFIX_LANGUAGES) {
            // mark this file extension as ignored
            _SetExtensionReferTo(ext, "");
            _SetExtensionIgnoreSuffix(ext, true);
            _update_buffers_for_ext(ext, "");
         } else {
            // create an association from ext -> refLangId
            langId = _Modename2LangId(_ctl_languages.p_text);
            if (modeName == PLAINTEXT_LANGUAGES) langId = "fundamental";
            _SetExtensionReferTo(ext, langId);
            _SetExtensionIgnoreSuffix(ext, false);
            _update_buffers_for_ext(ext, langId);
         }
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
      _EncodingFillComboList('', DEFAULT_ENCODING, 0 /*OEFLAG_REMOVE_FROM_OPEN*/);
   } else {
      // Remove encoding text box
      ctlencoding.p_visible=false;
      ctlencodinglabel.p_visible=false;
   }

   // load up the extensions and languages
   refresh_extensions_and_languages();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _manage_extensions_form_initial_alignment()
{
   rightAlign := ctlencoding.p_x_extent;
   sizeBrowseButtonToTextBox(ctlAlternateEditor.p_window_id, ctlBrowseBtn.p_window_id, ctlFilterAppCmdButton.p_window_id, rightAlign);
}

void refresh_extensions_and_languages()
{
   CURRENT_EXTENSION('');

   // load the languages in the combo box
   _ctl_languages._lbclear();
   _ctl_languages.get_all_mode_names();
   _ctl_languages._lbsort();
   _ctl_languages._lbtop();
   _ctl_languages._lbadd_item_no_dupe(IGNORESUFFIX_LANGUAGES, "", LBADD_TOP);
   _ctl_languages._lbadd_item_no_dupe(PLAINTEXT_LANGUAGES, "",  LBADD_TOP);
   _ctl_languages.p_text = _ctl_languages._lbget_text();

   // load the extensions in the list box
   _ctl_extensions._lbclear();
   _ctl_extensions._lbaddFileExtensions();
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

   applyChangesToCurrentExtensionInfo();

   // set extension (_param1) to refer to langID (_param2)
   if (_param2 == IGNORESUFFIX_LANGUAGES) {
      _SetExtensionIgnoreSuffix(_param1, true);
      _SetExtensionReferTo(_param1, "");
   } else {
      _SetExtensionIgnoreSuffix(_param1, false);
      _SetExtensionReferTo(_param1, _param2);
   }

   CURRENT_EXTENSION("");
   p_window_id = _ctl_new.p_parent;
   _ctl_extensions._lbclear();
   _ctl_extensions._lbaddFileExtensions();
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

   CURRENT_EXTENSION("");
   _ctl_extensions._lbfind_and_delete_item(extension, 'i');
   _ctl_extensions._lbselect_line();
   CURRENT_EXTENSION("");
   _ctl_extensions.call_event(CHANGE_CLINE, _ctl_extensions, ON_CHANGE, 'W');
}

void _ctl_lang_setup.lbutton_up()
{
   modeName := _ctl_languages._lbget_text();
   switch (modeName) {
   case NONE_LANGUAGES:
      _message_box("No language mode selected!");
      break;
   case IGNORESUFFIX_LANGUAGES:
   case PLAINTEXT_LANGUAGES:
   case "":
      showOptionsForModename("fundamental", 'General');
      break;
   default:
      showOptionsForModename(modeName, 'General');
      break;
   }
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
         _ctl_extensions.p_text = _ctl_extensions._lbget_text();
      }
   case CHANGE_SELECTED:
      oldWid := p_window_id;
      p_window_id = p_parent;
      
      // before we load everything up, we need to save our current stuff
      if (CURRENT_EXTENSION() != "") applyChangesToCurrentExtensionInfo();
      
      // have we modified this one?
      ext := _ctl_extensions._lbget_text();
      
      // set the current extension
      CURRENT_EXTENSION(ext);
      
      // enable/disable based on whether this is ALL_EXTENSIONS      
      _ctl_languages.p_enabled = _ctl_lang_setup.p_enabled = ctlAlternateEditor.p_enabled = 
         ctlUseFileAssociation.p_enabled = ctlBrowseBtn.p_enabled = ctlFilterAppCmdButton.p_enabled = ctllabel9.p_enabled = 
         ctllabel7.p_enabled = ctllabel8.p_enabled = _ctl_delete.p_enabled = (ext != ALL_EXTENSIONS);

      if (ext == ALL_EXTENSIONS) {
         // special handling
         _ctl_languages._lbadd_item_no_dupe(NONE_LANGUAGES, '', LBADD_TOP, true);

         // figure out whether everything has the same encoding
         _str extList[];
         _GetAllExtensions(extList);
         sharedEncoding := '';
         allMatch := true;
         for (i := 0; i < extList._length(); i++) {

           // get the encoding for this extension, see if it matches
           thisEncoding := ExtensionSettings.getEncoding(extList[i]);
           if (sharedEncoding == '') {
              // this is the first one, save it
              sharedEncoding = thisEncoding;
           } else if (sharedEncoding != thisEncoding) {
              // they don't match, so we might as well quit
              allMatch = false;
              break;
           } // else they match so far, keep going
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
         _ctl_languages._lbadd_item_no_dupe(IGNORESUFFIX_LANGUAGES, '', LBADD_TOP);
         _ctl_languages._lbadd_item_no_dupe(PLAINTEXT_LANGUAGES, '', LBADD_TOP);

         // just a regular language
         langId := _Ext2LangId(ext);
         language := _LangGetModeName(langId);

         // select the language
         if (length(langId) <= 0 && _ExtensionGetIgnoreSuffix(ext)) {
            // not found, pick the Ignore suffix option
            _ctl_languages._lbfind_and_select_item(IGNORESUFFIX_LANGUAGES, '' , true);
         } else if (length(langId) <= 0) {
            // not found, pick the Plain Text option
            _ctl_languages._lbfind_and_select_item(PLAINTEXT_LANGUAGES, '' , true);
         } else if (_ctl_languages._lbfind_and_select_item(language, '' , true)) {
            // not found, pick the NONE option
            _ctl_languages._lbadd_item_no_dupe(NONE_LANGUAGES, '', LBADD_TOP, true);
            _ctl_languages.p_text = NONE_LANGUAGES;
         }

         // now load the encoding
         ctlencoding.p_text = encodingToTitle(ExtensionSettings.getEncoding(ext));

         // and the open application options
         if (_isUnix()) {
            if (!_isMac()) {
               ctlUseFileAssociation.p_enabled=false;
            }
         }
         ctlUseFileAssociation.p_value = (int)ExtensionSettings.getUseFileAssociation(ext);
         ctlAlternateEditor.p_text = ExtensionSettings.getOpenApplication(ext, '');
      }
      p_window_id = oldWid;
      break;
   }
}

_str encodingToTitle(_str encoding, OPENENCODINGTAB (&openEncodingTab)[]=null)
{
   if (_UTF8()) {
      if (openEncodingTab == null) {
         _EncodingListInit(openEncodingTab);
      }

      if (encoding != '' && encoding != null) {
         text := "";
         for (i := 0; i < openEncodingTab._length(); ++i) {
             if (openEncodingTab[i].option == encoding ||
                 "+fcp"openEncodingTab[i].codePage == encoding ||
                 openEncodingTab[i].codePage == encoding) {
                return openEncodingTab[i].text;
                break;
             }
         }
      } else {
         return openEncodingTab[0].text;
      }
   }

   return DEFAULT_ENCODING;
}

void _ctl_languages.on_change(int reason)
{
   if (_ctl_languages.p_text == NONE_LANGUAGES || _ctl_languages.p_text == IGNORESUFFIX_LANGUAGES) {
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

#endregion Options Dialog Helper Functions (Languages > File Extension Manager)


#region Options Dialog Helper Functions (Languages > File Extension Manager > New...)

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
   ctl_referto._lbadd_item_no_dupe(IGNORESUFFIX_LANGUAGES, "", LBADD_TOP);
   ctl_referto._lbadd_item_no_dupe(PLAINTEXT_LANGUAGES, "",  LBADD_TOP);
   ctl_referto._lbfind_and_select_item(PLAINTEXT_LANGUAGES);
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
   if (langId != "") {
      result := _message_box('The extension 'ext' is already associated with '_LangGetModeName(langId)'.  Do you wish to continue?', 'New Extension', MB_YESNO | MB_ICONEXCLAMATION);
      if (result == IDNO) return '';
   }

   // check that the referred to extension still exists
   language := "";
   if (modename == IGNORESUFFIX_LANGUAGES) {
      language = modename;
   } else if (modename == PLAINTEXT_LANGUAGES) {
      language = "fundamental";
   } else {
      language = _Modename2LangId(modename);
   }
   if (language == "") {
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
static bool check_min_abbrev()
{
   if (!isinteger(p_text) || p_text<1) {
      _message_box(nls("Invalid minimum expandable keyword length"));
      return false;
   }
   return true;
}

void populatecb(int ctl, int defval, _str (&items)[]) 
{
   int i;

   for (i = 0; i < items._length(); i++) {
      ctl.p_cb_list_box._lbadd_item(items[i]);
   }

   ctl.p_cb_text_box.p_text = items[defval];
}

int comboIndexSelected(_str val, _str (&items)[], int defval = 0) 
{
    int i;

    for (i = 0; i < items._length(); i++) {
        if (val == items[i]) {
            return i;
        }
    }

    return defval;
}

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

int _GetExtIndentOptions(_str lang, int &IndentStyle, int &SyntaxIndent)
{
   VS_LANGUAGE_OPTIONS op;
   if (_GetDefaultLanguageOptions(lang, op)) {
      return 1;
   }
   IndentStyle = _LangGetPropertyInt32(lang,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);
   SyntaxIndent = _LangGetPropertyInt32(lang,LOI_SYNTAX_INDENT);
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
   // Can't refer to self
   extension=_file_case(extension);
   ExtensionSettings.setLangRefersTo(extension, lang);
}
void _SetExtensionIgnoreSuffix(_str extension, bool yesno)
{
   // Can't refer to self
   extension=_file_case(extension);
   ExtensionSettings.setExtensionIgnoreSuffix(extension, yesno);
}
/**
 * @return Return the name of the color coding lexer for the given
 *         file extension.
 *  
 * @deprecated Use {@link _LangGetLexerName()}. 
 */
_str _ext2lexername(_str ext,int &setup_index)
{
   // find language corresponding to 'ext'
   lang := _Ext2LangId(ext);
   if (ext == '') {
      setup_index=0;
      return '';
   }

   return _LangGetLexerName(lang);
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
bool validateLangIntTextBox(int wid, int min = null, int max = null, _str error = '')
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
               error :+= ' >= 'min;
               if (checkMax) {
                  error :+= ', and';
               }
            }
            if (checkMax) {
               error :+= ' <= 'max;
            }

            error :+= '.';
         }

         wid._text_box_error(error);
         return false;
      }
   }

   return true;
}

bool isLangSingleFileProjectsmExcludedForMode(_str langId='')
{
   switch (langId) {
   case ALL_LANGUAGES_ID:
   case "process":
   case "fileman":
   case "grep":
   case "vlx":
   case "tagdoc":
   case "vsm":
   case "vpj":
      return true;
   default:
      return false;
   }
}
bool isLangAliasesFormExcludedForMode(_str langId='')
{
   return (langId == ALL_LANGUAGES_ID);
}

bool isLangColorCodingFormExcludedForMode(_str langId)
{
   return (langId == ALL_LANGUAGES_ID);
}

bool isLangExcludedFromGenericLiveErrors(_str langId)
{
   return (langId == 'java' || langId == ALL_LANGUAGES_ID);
}

#endregion Options Dialog Helper Functions (Languages > File Extension Manager > New...)


#region Options Dialog Helper Functions  (Language > General)

defeventtab _language_general_form;

static int FILE_EXTENSIONS_LABEL_HEIGHT(...) {
   if (arg()) _file_extensions_lbl.p_user=arg(1);
   return _file_extensions_lbl.p_user;
}
static int FILE_LANGUAGES_LABEL_HEIGHT(...) {
   if (arg()) _mixed_languages_label.p_user=arg(1);
   return _mixed_languages_label.p_user;
}

void _language_general_form_init_for_options(_str langID)
{
   // context menu stuff - fill in our choices
   _menu_list._lbclear();
   _menu_list.fill_in_menu_list();
   _selection_menu_list._lbclear();
   _selection_menu_list.fill_in_menu_list();

   if (langID == ALL_LANGUAGES_ID) {
      // hide the mode name and extensions stuff
      label1.p_visible = _mode_name.p_visible = false;
      ctllabel14.p_visible = _file_extensions_lbl.p_visible = false;
      _ctl_edit_extensions.p_visible = false;
      ctllabel15.p_visible = _mixed_languages_label.p_visible = false;
      _ctl_edit_languages.p_visible = false;
      /*_project.p_visible = */_ctl_extensionless_files_link.p_visible = _ctl_file_associations_link.p_visible = false;

      // There's just no way that a user would want to configure every language with the same
      // begin/end pairs. This is dangerous.
      ctlBeginEndPairsLabel.p_visible=_beginend_pairs.p_visible=false;
      y_adjust := (_word_chars.p_y - _beginend_pairs.p_y);
      ctlWordCharsLabel.p_y -= y_adjust;
      _word_chars.p_y -= y_adjust;
      ctlspellwt.p_y -= y_adjust;
      ctlspellwt_elements.p_y -= y_adjust;
      ctlcaps.p_y -= y_adjust;
      ctlWordsFrame.p_height -= y_adjust;

   } else {
      // enable or disable the projects button
      /*if (langID != ALL_LANGUAGES_ID && !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS)) {
         _project.p_enabled=false;
      } */

      // get and sort list of file extensions
      _file_extensions_lbl.p_caption = get_file_extensions_sorted(langID);

      // get list of referenced languages
      _mixed_languages_label.p_caption = get_referenced_in_languages(langID);
   }

   _language_form_init_for_options(langID, _language_general_form_get_value, _language_general_form_is_lang_included);

   FILE_EXTENSIONS_LABEL_HEIGHT(_file_extensions_lbl.p_height);
   sizeExtensionsLabel();

   FILE_LANGUAGES_LABEL_HEIGHT(_mixed_languages_label.p_height);
   sizeLanguagesLabel();

   // only on windows
   if (_isUnix()) {
      _ctl_file_associations_link.p_visible = false;
   }
   if (langID!=ALL_LANGUAGES_ID) {
      lexer_name:=_LangGetProperty(langID,VSLANGPROPNAME_LEXER_NAME);
      if (lexer_name=='') {
         ctlspellwt_elements.p_visible=false;
      } else {
         styles:=' '_plugin_get_property(VSCFGPACKAGE_COLORCODING_PROFILES,lexer_name,'styles')' ';
         // If this is a tag/element language.
         if (pos(' xml ',styles) 
             || pos(' html ',styles) 
             || pos(' bbc ',styles) 
             ) {
            ctlspellwt_elements.p_visible=false;
         }
      }
   }

   // this is a link - give it a hand
   _ctl_extensionless_files_link.p_mouse_pointer = MP_HAND;
   _ctl_file_associations_link.p_mouse_pointer = MP_HAND;
   ctlspellwt_elements.p_mouse_pointer = MP_HAND;
}

_str _language_general_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'ctlspellwt':
      value= _LangGetPropertyInt32(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING, 0);
      if (value) {
         value = '1';
      } else {
         value = '0';
      }
      break;
   case 'ctlspellwt_elements':
      value= _LangGetProperty(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS);
      break;

   case '_mode_name':
      value = LanguageSettings.getModeName(langId);
      break;
   case '_file_extensions_lbl':
      value = get_file_extensions_sorted(langId);
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
   }

   return value;
}

static bool isAutoCapsEnabled(_str langId)
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

bool _language_general_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;
   index := -1;
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
   }

   return included;
}

bool _language_general_form_validate(int action)
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
      modeList := _LangGetModeName(langID);
      langList := LanguageSettings.getReferencedInLanguageIDs(langID);
      foreach (auto refLangID in langList) {
         mode := _LangGetModeName(refLangID);
         if (mode == "") continue;
         if (modeList._length() > 0) modeList :+= ", ";
         modeList :+= mode;
      }
      _mixed_languages_label.p_caption = modeList;
   }

   _language_form_restore_state(_language_general_form_get_value, 
                                _language_general_form_is_lang_included);
}

bool _language_general_form_apply()
{
   _language_form_apply(_language_general_form_apply_control);

   return true;
}

_str _language_general_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   switch (controlName) {
   case 'ctlspellwt':
      updateKey = VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING;
      updateValue = value;
      _LangSetPropertyInt32(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING, (int)value);
      break;
   case 'ctlspellwt_elements':
      updateKey = VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS;
      updateValue = value;
      _LangSetProperty(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS, value);
      break;

   case '_mode_name':
      oldModeName := LanguageSettings.getModeName(langId);
      scheduleModeNameForRenaming(oldModeName, value);

      updateKey = MODE_NAME_UPDATE_KEY;
      updateValue = value;

      LanguageSettings.setModeName(langId, value);
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
   }

   return updateKey' 'updateValue;
}

void _language_general_form.on_destroy()
{
   _language_form_on_destroy();
}

void _ctl_edit_extensions.lbutton_up()
{
   _str a[];
   split(_file_extensions_lbl.p_caption, ' ', a);
   langID := _get_language_form_lang_id();
   mode := _LangGetModeName(langID);

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
      _file_extensions_lbl.p_caption = _LangGetExtensions(langID);
   }

}

void _ctl_edit_languages.lbutton_up()
{
   _str mode;
   origList := _mixed_languages_label.p_caption;
   _str a[];
   split(origList, ',', a);
   for (i:=0; i<a._length(); i++) {
      a[i] = strip(a[i]);
   }

   langID := _get_language_form_lang_id();
   mode = _LangGetModeName(langID);

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

      modeList := _LangGetModeName(langID);
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
      //targetWidth := 1.5 * _beginend_pairs.p_width;
      targetWidth := ctlWordsFrame.p_x_extent - _file_extensions_lbl.p_x;
      if (_file_extensions_lbl.p_width > targetWidth) {
         //linesNeeded := ceiling((double)_file_extensions_lbl.p_width / targetWidth);
         linesNeeded := (_file_extensions_lbl.p_width + targetWidth) intdiv targetWidth;
         _file_extensions_lbl.p_auto_size = false;
         _file_extensions_lbl.p_word_wrap = true;

         heightAdded := (FILE_EXTENSIONS_LABEL_HEIGHT() * linesNeeded) - _file_extensions_lbl.p_height;
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
      //targetWidth := 1.5 * _beginend_pairs.p_width;
      targetWidth := ctlWordsFrame.p_x_extent - _mixed_languages_label.p_x;
      if (_mixed_languages_label.p_width > targetWidth) {
         //linesNeeded := ceiling((double)_mixed_languages_label.p_width / targetWidth);
         linesNeeded := (_mixed_languages_label.p_width + targetWidth) intdiv targetWidth;
         _mixed_languages_label.p_auto_size = false;
         _mixed_languages_label.p_word_wrap = true;

         heightAdded := (FILE_LANGUAGES_LABEL_HEIGHT() * linesNeeded) - _mixed_languages_label.p_height;
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
   typeless orig_list=_list_editor_get_orig_list();
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
      _nocheck _control ctl_tree;
      status:=ctl_tree._TreeSearch(TREE_ROOT_INDEX, newExt,'T'_fpos_case);
      if (status>=0) {
         _message_box('The extension 'newExt' is already in list');
         return '';
      }
      currentLang := _Ext2LangId(newExt);
      if (currentLang != '') {
         // make sure user wants to make this change
         currentLang = _LangGetModeName(currentLang);
         if (currentLang != '') {
            for (i:=0;i<orig_list._length();++i) {
               if (file_eq(orig_list[i],newExt)) {
                  return newExt;
               }
            }
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
   LanguageSettings.getAllLanguageIds(auto langs);
   for (i := 0; i < langs._length(); i++) {
      modeNames[modeNames._length()] = _LangGetModeName(langs[i]);
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

void _ctl_file_associations_link.lbutton_up()
{
   config('_associate_file_types_form', 'D');
}
void ctlspellwt_elements.lbutton_up()
{
   result:=show('-wh -modal _color_element_list_form', ctlspellwt_elements.p_user);
   if (result==1) {
      ctlspellwt_elements.p_user=_param1;
   }

}

void ctlcolor_coding.lbutton_up()
{
   modeName := _get_language_form_mode_name();
   showOptionsForModename(modeName, 'Color Coding');
}


static fill_in_menu_list()
{
   int index=name_match('',1,oi2type(OI_MENU));
   while (index) {
      menu_name := name_name(index);
      menu_name=stranslate(menu_name,'_','-');
      _lbadd_item(menu_name);
      index=name_match('',0,oi2type(OI_MENU));
   }
   _lbdeselect_all();
   _lbsort();
   _lbtop();
   _lbselect_line();
}

#endregion Options Dialog Helper Functions (Language > General)

#region Options Dialog Helper Functions (Language > Editing)

defeventtab _language_editing_form;

static _str BRACES_SUPPORTED(...) {
   if (arg()) _insert.p_user=arg(1);
   return _insert.p_user;
}

static const INDENT_STYLE_NONE_TEXT=            'None';
static const INDENT_STYLE_AUTO_TEXT=            'Auto';
static const INDENT_STYLE_SYNTAX_INDENT_TEXT=   'Syntax indent';

static const TAB_REINDENT_NEVER=                 'Never';
static const TAB_REINDENT_ALWAYS=                'Always';
static const TAB_REINDENT_IN_LEADING_BLANKS=     'In leading blanks';
static const TAB_REINDENT_IN_LEADING_BLANKS_STRICT='In leading blanks strict';

static const TAB_STYLE_SYNTAX_INDENT=    'Indent by syntax indent';
static const TAB_STYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS= 'Use syntax indent as tab stops';
static const TAB_STYLE_USE_TAB_STOPS=     'Use tab stops and not syntax indent';

bool indent_defines_blocks(_str langID) {
   return langID == 'py';
}

void _language_editing_form_init_for_options(_str langID)
{
   // bounds only visible in ispf mode
   if (def_keys!='ispf-keys') {
      ctlBoundsFrame.p_visible = false;
   }

   if (langID == ALL_LANGUAGES_ID) {
      // Since Python is the only language that supports this option,
      // Don't bother showing this option
      ctltabcycle.p_visible=false;
      // Do not want to set indent style for all languages
      ctllabel16.p_visible=ctltabstyle.p_visible=ctllabel18.p_visible=ctlIndentStyle.p_visible=false;

      y_adjust := (ctlInsertRealIndent.p_y - ctltabstyle.p_y);
      ctlInsertRealIndent.p_y -= y_adjust;
      ctlBackspaceUnindent.p_y -= y_adjust;
      _smartp.p_y -= y_adjust;
      ctlLeadingBlanksTab.p_height -= y_adjust;
      _syntax_expansion_frame.p_y -= y_adjust;


   } else {
      ctltabcycle.p_visible = indent_defines_blocks(langID);
      if (!ctltabcycle.p_visible) {
         y_adjust := (ctlInsertRealIndent.p_y - ctltabcycle.p_y);
         ctlInsertRealIndent.p_y -= y_adjust;
         ctlBackspaceUnindent.p_y -= y_adjust;
         _smartp.p_y -= y_adjust;
         ctlLeadingBlanksTab.p_height -= y_adjust;
         _syntax_expansion_frame.p_y -= y_adjust;
      }

      if (!new_beautifier_supported_language(langID) || !_haveBeautifiers()) {
         _beaut_edit.p_visible = false;
         _beaut_syntax.p_visible = false;
         _beaut_alias.p_visible = false;
         _beaut_paste.p_visible = false;
      }

      if (!beautifier_supports_typing(langID)) {
         _beaut_edit.p_visible = false;
         _beaut_paste.p_visible = false;
      } else if (new_beautifier_supported_language(langID) &&
                 (_LanguageInheritsFrom('xml', langID) || _LanguageInheritsFrom('html', langID))) {
         dist1 := _beaut_alias.p_y - _beaut_syntax.p_y;
         _beaut_alias.p_visible = false;
         _beaut_syntax.p_visible = false;
         _beaut_edit.p_y -= 2*dist1;
         _beaut_paste.p_y -= 2*dist1;
      }
   }

   if (!ctlBoundsFrame.p_visible) {
      y_adjust := ctlBoundsFrame.p_y_extent - ctlTruncationFrame.p_y_extent;
      ctlBeautifyFrame.p_y -= y_adjust;
   }

   _ctl_beautify_line.p_visible = beaut_on_tab_supported(langID);

   last_invisible_wid := _beaut_paste.p_window_id;
   last_visible_wid := _beaut_paste.p_window_id;
   int ctl_array[];
   ctl_array :+= _ctl_beautify_line.p_window_id;
   ctl_array :+= _beaut_syntax.p_window_id;
   ctl_array :+= _beaut_alias.p_window_id;
   ctl_array :+= _beaut_edit.p_window_id;
   ctl_array :+= _beaut_paste.p_window_id;
   for (i:=0; i<ctl_array._length(); i++) {
      if (!ctl_array[i].p_visible) {
         last_invisible_wid = ctl_array[i];
         ctl_array._deleteel(i);
         --i;
      } else {
         last_visible_wid = ctl_array[i];
      }
   }
   if (ctl_array._length() == 0) {
      ctlBeautifyFrame.p_visible = false;
   } else {
      while (ctl_array._length() < 5) {
         ctl_array :+= last_invisible_wid;
      }

      space_y :=  (_beaut_alias.p_y - _beaut_syntax.p_y_extent);
      alignControlsVertical(_ctl_beautify_line.p_x, 
                            _ctl_beautify_line.p_y, 
                            space_y,
                            ctl_array[0],
                            ctl_array[1],
                            ctl_array[2],
                            ctl_array[3],
                            ctl_array[4]);
      ctlBeautifyFrame.p_height = last_visible_wid.p_y_extent + 2*space_y;
   }

   ctltabreindent._lbadd_item(TAB_REINDENT_NEVER);
   ctltabreindent._lbadd_item(TAB_REINDENT_ALWAYS);
   ctltabreindent._lbadd_item(TAB_REINDENT_IN_LEADING_BLANKS);
   ctltabreindent._lbadd_item(TAB_REINDENT_IN_LEADING_BLANKS_STRICT);

   if (_is_syntax_indent_tab_style_supported(langID)) {
      ctltabstyle._lbadd_item(TAB_STYLE_SYNTAX_INDENT);
      ctltabstyle._lbadd_item(TAB_STYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS);
   } else {
      ctltabstyle.p_enabled=false;
   }
   ctltabstyle._lbadd_item(TAB_STYLE_USE_TAB_STOPS);


   ctlIndentStyle._lbadd_item(INDENT_STYLE_NONE_TEXT);
   ctlIndentStyle._lbadd_item(INDENT_STYLE_AUTO_TEXT);
   if (_is_syntax_indent_supported(langID,false)) {
      ctlIndentStyle._lbadd_item(INDENT_STYLE_SYNTAX_INDENT_TEXT);
   }

   // determine whether this language supports inserting braces
   if (langID == ALL_LANGUAGES_ID) {
      BRACES_SUPPORTED(true);
   } else {
      BRACES_SUPPORTED(false);
      _str list[];
      get_language_inheritance_list(langID, list);
      for (i = 0; i < list._length(); i++) {
         if (_is_insert_begin_end_immediately_supported(list[i])) {
            BRACES_SUPPORTED(true);
            break;
         }
      }
   }
   _language_form_init_for_options(langID, _language_editing_form_get_value, _language_editing_form_is_lang_included);
   call_event(_syntax_expansion.p_window_id, LBUTTON_UP);
   ctltabreindent.call_event(CHANGE_OTHER,_control ctltabreindent,ON_CHANGE,'W');

}

_str _language_editing_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case 'ctltabcycle':
      value = LanguageSettings.getTabCyclesIndents(langId) ? '1' : '0';
      break;
   case 'ctlspellwt':
      value= _LangGetPropertyInt32(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING, 0);
      if (value) {
         value = '1';
      } else {
         value = '0';
      }
      break;
   case 'ctlspellwt_elements':
      value= _LangGetProperty(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS);
      break;

   case '_ctl_beautify_line':
      if (LanguageSettings.getBeautifierExpansions(langId) & BEAUT_ON_TAB) {
         value = '1';
      } else {
         value = '0';
      }
      break;

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

   case 'ctlDiffStart':
      bounds = LanguageSettings.getDiffColumns(langId);
      parse bounds with auto onOff auto diffStart .;
      if (isinteger(diffStart) && diffStart >= 0) {
         value = diffStart;
      } else value = '';
      break;
   case 'ctlDiffEnd':
      bounds = LanguageSettings.getDiffColumns(langId);
      parse bounds with . . auto diffEnd .;
      if (isinteger(diffEnd) && diffEnd >= 0) {
         value = diffEnd;
      } else value = '';
      break;
   case 'ctlDiffColOn':
   case 'ctlDiffColOff':
      bounds = LanguageSettings.getDiffColumns(langId);
      parse bounds with auto diffColOn .;
      value = (isinteger(diffColOn) && diffColOn>0) ? 'ctlDiffColOn' : 'ctlDiffColOff';
      break;

   case 'ctltabreindent':
      smartTab := LanguageSettings.getSmartTab(langId);
      if (smartTab < 0) smartTab = -smartTab;

      // radio button set - return the control which has the value
      switch (smartTab) {
      case VSSMARTTAB_MAYBE_REINDENT_STRICT:
         value = TAB_REINDENT_IN_LEADING_BLANKS_STRICT;
         break;
      case VSSMARTTAB_MAYBE_REINDENT:
         value = TAB_REINDENT_IN_LEADING_BLANKS;
         break;
      case VSSMARTTAB_ALWAYS_REINDENT:
         value = TAB_REINDENT_ALWAYS;
         break;
      case VSSMARTTAB_INDENT:
      default:
         value = TAB_REINDENT_NEVER;
         break;
      }
      break;
   case 'ctltabstyle':
      tabstyle := LanguageSettings.getTabStyle(langId);
      if (tabstyle < 0) tabstyle = -tabstyle;

      // radio button set - return the control which has the value
      if (!_is_syntax_indent_tab_style_supported(langId)) {
         value = TAB_STYLE_USE_TAB_STOPS;
      } else {
         switch (tabstyle) {
         case VSTABSTYLE_SYNTAX_INDENT:
            value = TAB_STYLE_SYNTAX_INDENT;
            break;
         case VSTABSTYLE_USE_TAB_STOPS:
            value = TAB_STYLE_USE_TAB_STOPS;
            break;
         case VSTABSTYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS:
         default:
            value = TAB_STYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS;
            break;
         }
      }
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
   case '_insert':
      value = (int)LanguageSettings.getInsertBeginEndImmediately(langId);
      break;
   case '_ctl_blankline':
      value = LanguageSettings.getInsertBlankLineBetweenBeginEnd(langId) ? 1 : 0;
      break;
   }

   return value;
}

bool _language_editing_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;
   index := -1;
   switch (controlName) {
   case 'ctlTruncationFrame':
      index = _FindLanguageCallbackIndex('_%s_is_truncation_supported', langId);
      if (index > 0)  {
         return call_index(index);
      }
      break;
   case 'ctlBackspaceUnindent':
      included = !(_LanguageInheritsFrom(FUNDAMENTAL_LANG_ID, langId));
      break;
   case 'ctlIndentStyle':
      if (allLangsExclusion) {
         included = !(_LanguageInheritsFrom(FUNDAMENTAL_LANG_ID, langId));
      }
      break;
   case 'ctltabstyle':
      if (allLangsExclusion) {
         included = false;
      } else {
         included=_is_syntax_indent_tab_style_supported(langId);
      }
      break;
   case 'ctltabreindent':
      // this exclusion will apply to the whole frame, so we go by the group control name,
      // which is then applied to the rest of the group
      included = false;

      keytab := LanguageSettings.getKeyTableName(langId);
      if ((_FindLanguageCallbackIndex('%s_smartpaste', langId) != 0) && keytab != '') {
         index = find_index(keytab, EVENTTAB_TYPE);
         if (index > 0) {
            command := name_name(eventtab_index(index, index, event2index(TAB)));
            if (command=='smarttab' || command=='c-tab' || command=='gnu-ctab' ||
                _is_smarttab_supported(langId)) {
               included = true;
            }
         }
      }
      break;

   case 'ctlLeadingBlanksTab':
      // Can't just disable this whole frame because it now contains options which
      // have nothing to do with the Tab key.
      included=true;
#if 0
      // this exclusion will apply to the whole frame, so we go by the group control name,
      // which is then applied to the rest of the group
      included = false;

      keytab := LanguageSettings.getKeyTableName(langId);
      if ((_FindLanguageCallbackIndex('%s_smartpaste', langId) != 0) && keytab != '') {
         index = find_index(keytab, EVENTTAB_TYPE);
         if (index > 0) {
            command := name_name(eventtab_index(index, index, event2index(TAB)));
            if (command=='smarttab' || command=='c-tab' || command=='gnu-ctab' ||
                _is_smarttab_supported(langId)) {
               included = true;
            }
         }
      }
#endif
      break;
   case '_smartp':
      included = (_FindLanguageCallbackIndex('%s_smartpaste', langId) != 0);
      break;
   case '_minimum_expandable':
   case '_minimum_expandable_label':
   case '_minimum_expandable_spinner':
      included = !(_LanguageInheritsFrom('html', langId) || _LanguageInheritsFrom('xml', langId) || _LanguageInheritsFrom('dtd', langId));
      break;
   case '_insert':
      included = LanguageSettings.doesOptionApplyToLanguage(langId, LOI_INSERT_BEGIN_END_IMMEDIATELY);
      break;
   }

   return included;
}

bool _language_editing_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
   
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
      if (ctlDiffColOn.p_value) {
         if (ctlDiffStart.p_text=="") {
            ctlDiffStart._text_box_error("When Diff columns are on, a start column must be specified");
            return false;
         }
         if ( !isinteger(ctlDiffStart.p_text) ) {
            ctlDiffStart._text_box_error("This must be an integer value");
            return false;
         }
         if ( !isinteger(ctlDiffEnd.p_text) && ctlDiffEnd.p_text!="" ) {
            ctlDiffEnd._text_box_error("This must be an integer value");
            return false;
         }
         if ( ctlDiffEnd.p_text!="" ) {
            if ( ctlDiffEnd.p_text <= ctlDiffStart.p_text ) {
               ctlDiffEnd._text_box_error("End must be greater than start value");
               return false;
            }
         }
      }
   }

   // verify minimum expandable keywords
   if (!validateLangIntTextBox(_minimum_expandable.p_window_id)) {
      return false;
   }

   // we made it all the way through all the validation
   return true;
}

void _language_editing_form_restore_state()
{
   langID := _get_language_form_lang_id();
   _language_form_restore_state(_language_editing_form_get_value, 
                                _language_editing_form_is_lang_included);
}

bool _language_editing_form_apply()
{
   _language_form_apply(_language_editing_form_apply_control);

   return true;
}

_str _language_editing_form_apply_control(_str controlName, _str langId, _str value)
{
   updateKey := '';
   updateValue := '';

   switch (controlName) {
   case 'ctltabcycle':
      updateKey = '';
      updateValue = '';
      if (indent_defines_blocks(langId) || langId==ALL_LANGUAGES_ID) {
         LanguageSettings.setTabCyclesIndents(langId, value != '0');
      }
      break;

   case 'ctlspellwt':
      updateKey = VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING;
      updateValue = value;
      _LangSetPropertyInt32(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING, (int)value);
      break;
   case 'ctlspellwt_elements':
      updateKey = VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS;
      updateValue = value;
      _LangSetProperty(langId, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS, value);
      break;

   case '_ctl_beautify_line':
      updateKey = '';
      updateValue= '';
      if (value != 0) {
         LanguageSettings.setBeautifierExpansions(langId, BEAUT_ON_TAB | LanguageSettings.getBeautifierExpansions(langId));
      } else {
         LanguageSettings.setBeautifierExpansions(langId, ~BEAUT_ON_TAB & LanguageSettings.getBeautifierExpansions(langId));
      }
      break;

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
   case 'ctlDiffColOn':
      // don't do anything here, it will be handled by the call to apply ctlBoundsStart and ctlBoundsEnd
      updateKey = DIFFCOL_UPDATE_KEY;

      diffColumns := LanguageSettings.getDiffColumns(langId);   
      parse diffColumns with auto diffColOnOff auto diffStartCol auto diffEndCol;
      updateValue = '1 'diffStartCol' 'diffEndCol;
      LanguageSettings.setDiffColumns(langId, '1 'diffStartCol' 'diffEndCol);
      break;
   case 'ctlDiffColOff':
      updateKey = DIFFCOL_UPDATE_KEY;

      diffColumns = LanguageSettings.getDiffColumns(langId);   
      parse diffColumns with diffColOnOff diffStartCol diffEndCol;
      updateValue = '0 'diffStartCol' 'diffEndCol;
      LanguageSettings.setDiffColumns(langId, '0 'diffStartCol' 'diffEndCol);   
      break;
   case 'ctlDiffStart':
      oldDiff := LanguageSettings.getDiffColumns(langId);
      parse oldDiff with diffColOnOff auto DiffStart auto DiffEnd;

      newDiff := diffColOnOff' 'strip(value) ' ' DiffEnd;

      updateKey = DIFFCOL_UPDATE_KEY;
      updateValue = newDiff;

      LanguageSettings.setDiffColumns(langId, newDiff);   
      break;
   case 'ctlDiffEnd':
      oldDiff = LanguageSettings.getDiffColumns(langId);
      parse oldDiff with diffColOnOff DiffStart DiffEnd;

      newDiff = diffColOnOff' 'DiffStart ' 'strip(value);

      updateKey = DIFFCOL_UPDATE_KEY;
      updateValue = newDiff;

      LanguageSettings.setDiffColumns(langId, newDiff);   
      break;
   case 'ctltabreindent':
      switch (value) {
      case TAB_REINDENT_NEVER:
         updateValue = VSSMARTTAB_INDENT;
         break;
      case TAB_REINDENT_ALWAYS:
         updateValue = VSSMARTTAB_ALWAYS_REINDENT;
         break;
      case TAB_REINDENT_IN_LEADING_BLANKS:
         updateValue = VSSMARTTAB_MAYBE_REINDENT;
         break;
      case TAB_REINDENT_IN_LEADING_BLANKS_STRICT:
         updateValue = VSSMARTTAB_MAYBE_REINDENT_STRICT;
         break;
      default:
         updateValue = VSSMARTTAB_INDENT;
         break;
      }
      updateKey = VSLANGPROPNAME_SMART_TAB;
      LanguageSettings.setSmartTab(langId, (int)updateValue);
      break;
   case 'ctltabstyle':
      switch (value) {
      case TAB_STYLE_SYNTAX_INDENT:
         updateValue = VSTABSTYLE_SYNTAX_INDENT;
         break;
      case TAB_STYLE_USE_TAB_STOPS:
         updateValue = VSTABSTYLE_USE_TAB_STOPS;
         break;
      case TAB_STYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS:
      default:
         updateValue = VSTABSTYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS;
         break;
      }
      updateKey = VSLANGPROPNAME_TAB_STYLE;
      LanguageSettings.setTabStyle(langId, (int)updateValue);
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
      if (value && !(def_surround_mode_flags & VS_SURROUND_MODE_ENABLED)) {
         def_surround_mode_flags = 0xFFFF;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      LanguageSettings.setSurroundOptions(langId, value ? def_surround_mode_flags : 0);
      break;
   case '_expand_alias_on_space':
      LanguageSettings.setExpandAliasOnSpace(langId, value != 0);
      break;
   case '_ctl_blankline':
      LanguageSettings.setInsertBlankLineBetweenBeginEnd(langId, _ctl_blankline.p_value != 0);
      break;
   }

   return updateKey' 'updateValue;
}

void _language_editing_form.on_destroy()
{
   _language_form_on_destroy();
}

#if 0
void ctlIndent.lbutton_up()
{
   ctlReindentStrict.p_value = 0;
   ctlReindentStrict.p_enabled = false;
   _ctl_beautify_line.p_enabled = false;
   _ctl_beautify_line.p_value = 0;
}

void ctlReindentAlways.lbutton_up()
{
   ctlReindentStrict.p_value = 0;
   ctlReindentStrict.p_enabled = false;
   _ctl_beautify_line.p_enabled = true;
}

void ctlReindent.lbutton_up()
{
   ctlReindentStrict.p_enabled = ctltabreindent.p_enabled;
   ctlReindentStrict.p_value = 0;
   _ctl_beautify_line.p_enabled = true;
}
#endif
void ctltabreindent.on_change() {
   if (p_text==TAB_REINDENT_IN_LEADING_BLANKS ||
       p_text==TAB_REINDENT_IN_LEADING_BLANKS_STRICT) {
      _ctl_beautify_line.p_enabled = true;
   } else if (p_text==TAB_REINDENT_ALWAYS) {
      _ctl_beautify_line.p_enabled = true;
   } else {
      _ctl_beautify_line.p_enabled = false;
      _ctl_beautify_line.p_value = 0;
   }
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

   if (SMARTPASTE_INDEX() == '') {
      SMARTPASTE_INDEX(_FindLanguageCallbackIndex('%s_smartpaste', langId));
   }
   smartpaste_index := SMARTPASTE_INDEX();

   _smartp.p_enabled=smartpaste_index && (syntax_indent>0 && syntax_indent!='' && smart_indent);
}

void ctlBoundsOn.lbutton_up()
{
   if (ctlBoundsOn.p_value) {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=true;
   } else {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=false;
   }
}

void ctlDiffColOn.lbutton_up()
{
   if (ctlDiffColOn.p_value) {
      ctlDiffStartLab.p_enabled=ctlDiffEndLab.p_enabled=ctlDiffStart.p_enabled=ctlDiffEnd.p_enabled=true;
   } else {
      ctlDiffStartLab.p_enabled=ctlDiffEndLab.p_enabled=ctlDiffStart.p_enabled=ctlDiffEnd.p_enabled=false;
   }
}

void ctlTruncOn.lbutton_up()
{
   if (ctlTruncOn.p_value) {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=true;
      if (!isinteger(ctlTruncateLength.p_text) || ctlTruncateLength.p_text<=1) {
         ctlTruncateLength.p_text=72;
      }
   } else {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=false;
      ctlTruncateLength.p_text='';
   }
}

void ctlcolor_coding.lbutton_up()
{
   modeName := _get_language_form_mode_name();
   showOptionsForModename(modeName, 'Color Coding');
}

void ctlBoundsOn.lbutton_up()
{
   if (ctlBoundsOn.p_value) {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=true;
   } else {
      ctlBoundsStartLab.p_enabled=ctlBoundsEndLab.p_enabled=ctlBoundsStart.p_enabled=ctlBoundsEnd.p_enabled=false;
   }
}

void ctlDiffColOn.lbutton_up()
{
   if (ctlDiffColOn.p_value) {
      ctlDiffStartLab.p_enabled=ctlDiffEndLab.p_enabled=ctlDiffStart.p_enabled=ctlDiffEnd.p_enabled=true;
   } else {
      ctlDiffStartLab.p_enabled=ctlDiffEndLab.p_enabled=ctlDiffStart.p_enabled=ctlDiffEnd.p_enabled=false;
   }
}

void ctlTruncOn.lbutton_up()
{
   if (ctlTruncOn.p_value) {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=true;
      if (!isinteger(ctlTruncateLength.p_text) || ctlTruncateLength.p_text<=1) {
         ctlTruncateLength.p_text=72;
      }
   } else {
      ctlTruncateLengthLab.p_enabled=ctlTruncateLength.p_enabled=false;
      ctlTruncateLength.p_text='';
   }
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
   index := lastpos(' ', tabs);
   last_tab := substr(tabs, index + 1);
   if (substr(last_tab, 1, 1) != '+') {
      return('');
   }
   if (isinteger(substr(last_tab,2))) {
      return(substr(last_tab,2));
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
      //_expand_alias_on_space.p_enabled = _syntax_expansion.p_value != 0;
      _ctl_blankline.p_enabled = _syntax_expansion.p_value != 0;
   }

   _insert.p_enabled = _ctl_blankline.p_enabled = _syntax_expansion.p_value != 0 && BRACES_SUPPORTED();
// _surround.p_enabled = _syntax_expansion.p_value != 0 && _insert.p_enabled && _insert.p_value != 0;
}


#endregion Options Dialog Helper Functions (Language > Editing)

#region Options Dialog Helper Functions (Language > Word Wrap)

defeventtab _language_word_wrap_form;

void _language_word_wrap_form_init_for_options(_str langID)
{
   _language_form_init_for_options(langID, _language_word_wrap_form_get_value, 
                                   _language_word_wrap_form_is_lang_included);
#if 0
   if (LanguageSettings.getAutoLeftMargin(langID)) {
      ctlAutomaticRadio.p_value=1;
   } else {
      ctlFixedLeftColumnRadio.p_value=1;
   }
   int fixedWidthRightMargin = LanguageSettings.getFixedWidthRightMargin(langID);

   if (fixedWidthRightMargin) {
      say('fixed width fixedWidthRightMargin='fixedWidthRightMargin);
      ctlAutoFixedWidthRightMarginRadio.p_value=1;
   } else {
      say('column');
      ctlAutoFixedRightColumnRadio.p_value=1;
   }
#endif
}

_str _language_word_wrap_form_get_value(_str controlName, _str langId)
{
   _str value = null;
   bool automatic;
   int fixedWidthRightMargin;

   switch (controlName) {
   case 'ctlFixedLeftColumn':
      margins := LanguageSettings.getMargins(langId);
      parse margins with auto leftMargin . ;
      value = leftMargin;
      break;
   case 'ctlFixedRightColumn':
   case 'ctlAutoFixedRightColumn':
      margins = LanguageSettings.getMargins(langId);
      parse margins with . auto rightMargin . ;
      value = rightMargin;
      break;
   case 'ctlNewParagraphLeftColumn':
      margins = LanguageSettings.getMargins(langId);
      parse margins with leftMargin . auto para;
      if (para == '') para = leftMargin;
      value = para;
      break;
   case 'ctlAutomaticRadio':
   case 'ctlFixedLeftColumnRadio':
      if (LanguageSettings.getAutoLeftMargin(langId)!=0) {
         value='ctlAutomaticRadio';
      } else {
         value='ctlFixedLeftColumnRadio';
      }
      break;
   case 'ctlAutoFixedRightColumnRadio':
   case 'ctlAutoFixedWidthRightMarginRadio':
      //automatic = LanguageSettings.getAutoLeftMargin(langId)!=0;
      fixedWidthRightMargin = LanguageSettings.getFixedWidthRightMargin(langId);
      //say('h1 fixedWidthRightMargin='fixedWidthRightMargin);
      if (fixedWidthRightMargin) {
         value='ctlAutoFixedWidthRightMarginRadio';
      } else {
         value='ctlAutoFixedRightColumnRadio';
      }
      break;
   case 'ctlAutoFixedWidthRightMargin':
      automatic = LanguageSettings.getAutoLeftMargin(langId)!=0;
      fixedWidthRightMargin = LanguageSettings.getFixedWidthRightMargin(langId);
      //say('h2 fixedWidthRightMargin='fixedWidthRightMargin);
      if (fixedWidthRightMargin) {
         value=fixedWidthRightMargin;
      } else {
         margins = LanguageSettings.getMargins(langId);
         parse margins with . rightMargin . ;
         value = rightMargin;
      }
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
   case 'ctlpartial':
      wordWrapStyle = LanguageSettings.getWordWrapStyle(langId);
      value = (wordWrapStyle & PARTIAL_WWS) ? 1 : 0;
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

bool _language_word_wrap_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case '_word_wrap':
      included = !XW_isSupportedLanguage(langId);
      break;
   }

   return included;
}

bool _language_word_wrap_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      
      bool validateLeft;
      // validate the margins, maybe
      typeless leftMargin;
      bool validateRight;
      typeless rightMargin;
      if (ctlAutomaticRadio.p_value) {
         if (ctlAutoFixedWidthRightMarginRadio.p_value) {
            validateLeft=false;
            validateRight=false;
         } else {
            leftMargin=1;
            validateLeft=true;
            validateRight = _language_form_control_needs_validation(ctlAutoFixedRightColumn.p_window_id, rightMargin);
            if (!validateLangIntTextBox(ctlAutoFixedRightColumn.p_window_id, 1, MAX_LINE)) {
               return false;
            }
         }
      } else {
         validateLeft = _language_form_control_needs_validation(ctlFixedLeftColumn.p_window_id, leftMargin);
         if (!validateLangIntTextBox(ctlFixedLeftColumn.p_window_id, 1, MAX_LINE)) {
            return false;
         }
         validateRight = _language_form_control_needs_validation(ctlFixedRightColumn.p_window_id, rightMargin);
         if (!validateLangIntTextBox(ctlFixedRightColumn.p_window_id, 1, MAX_LINE)) {
            return false;
         }
      }
      if (validateLeft || validateRight) {
         // we have to check if they are integers again - they are occasionally blank on All Languages
         if (isinteger(leftMargin) && isinteger(rightMargin)) {
            if (leftMargin + 2 > rightMargin) {
               if (ctlAutomaticRadio.p_value) {
                  ctlAutoFixedRightColumn._text_box_error("The right margin must be at least left margin+3.");
               } else {
                  ctlFixedRightColumn._text_box_error("The right margin must be at least left margin+3.");
               }
               return false;
            }
         }
      }
   
      if (!validateLangIntTextBox(ctlNewParagraphLeftColumn.p_window_id, 1, MAX_LINE)) {
         return false;
      }

      if (!validateLangIntTextBox(ctlAutoFixedRightColumn.p_window_id, 1, MAX_LINE)) {
         return false;
      }

      if (!validateLangIntTextBox(ctlAutoFixedWidthRightMargin.p_window_id, 3, MAX_LINE)) {
         return false;
      }
   }

   return true;
}

void _language_word_wrap_form_restore_state()
{
   _language_form_restore_state(_language_word_wrap_form_get_value, _language_word_wrap_form_is_lang_included);
}

bool _language_word_wrap_form_apply()
{
   _language_form_apply(_language_word_wrap_form_apply_control);

   return true;
}

_str _language_word_wrap_form_apply_control(_str controlName, _str langId, _str value)
{
   bool automatic;

   updateKey := '';
   updateValue := '';

   oldValue := 0;
   newValue := 0;

   switch (controlName) {
   case 'ctlFixedLeftColumn':
      oldMargins := LanguageSettings.getMargins(langId);
      parse oldMargins with auto leftMargin auto rightMargin auto para;

      newMargins := value' 'rightMargin' 'para;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case 'ctlFixedRightColumn':
   case 'ctlAutoFixedRightColumn':
      automatic=ctlAutomaticRadio.p_value!=0;
      oldMargins = LanguageSettings.getMargins(langId);
      parse oldMargins with leftMargin rightMargin para;

      newMargins = leftMargin' 'value' 'para;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case 'ctlNewParagraphLeftColumn':
      oldMargins = LanguageSettings.getMargins(langId);
      parse oldMargins with leftMargin rightMargin para;

      newMargins = leftMargin' 'rightMargin' 'value;

      updateKey = MARGINS_UPDATE_KEY;
      updateValue = newMargins;

      LanguageSettings.setMargins(langId, newMargins);
      break;
   case 'ctlAutomaticRadio':
      oldAutoLeftMargin := LanguageSettings.getAutoLeftMargin(langId)!=0;

      newAutoLeftMargin := value!=0;

      updateKey = AUTO_LEFT_MARGIN_UPDATE_KEY;
      updateValue = newAutoLeftMargin;

      LanguageSettings.setAutoLeftMargin(langId, newAutoLeftMargin);
      break;
   case 'ctlFixedLeftColumnRadio':
      oldAutoLeftMargin = LanguageSettings.getAutoLeftMargin(langId)!=0;

      newAutoLeftMargin = value==0;

      updateKey = AUTO_LEFT_MARGIN_UPDATE_KEY;
      updateValue = newAutoLeftMargin;

      LanguageSettings.setAutoLeftMargin(langId, newAutoLeftMargin);
      break;
   case 'ctlAutoFixedWidthRightMarginRadio':
      oldFixedWidthRightMargin := LanguageSettings.getFixedWidthRightMargin(langId);

      newFixedWidthRightMargin := (int)ctlAutoFixedWidthRightMargin.p_text;

      updateKey = FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY;
      updateValue = newFixedWidthRightMargin;

      LanguageSettings.setFixedWidthRightMargin(langId, newFixedWidthRightMargin);
      break;
   case 'ctlAutoFixedRightColumnRadio':
      oldFixedWidthRightMargin = LanguageSettings.getFixedWidthRightMargin(langId);

      newFixedWidthRightMargin = 0;

      updateKey = FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY;
      updateValue = newFixedWidthRightMargin;

      LanguageSettings.setFixedWidthRightMargin(langId, newFixedWidthRightMargin);
      break;
   case 'ctlAutoFixedWidthRightMargin':
      oldFixedWidthRightMargin = LanguageSettings.getFixedWidthRightMargin(langId);

      newFixedWidthRightMargin = (int)value;

      updateKey = FIXED_WIDTH_RIGHT_MARGIN_UPDATE_KEY;
      updateValue = newFixedWidthRightMargin;

      LanguageSettings.setFixedWidthRightMargin(langId, newFixedWidthRightMargin);

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
   case 'ctlpartial':
      oldValue = LanguageSettings.getWordWrapStyle(langId);

      if ((int)value) {
         newValue = oldValue | PARTIAL_WWS;
      } else {
         newValue = oldValue & ~PARTIAL_WWS;
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
   _one_space.p_enabled = false;
}

void _left.lbutton_up()
{
   _one_space.p_enabled = false;
}

void _left_and_respace.lbutton_up()
{
   _one_space.p_enabled = true;
}


void ctlAutoFixedWidthRightMarginRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlAutoFixedRightColumnRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlAutomaticRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlFixedLeftColumnRadio.lbutton_up() {
   _margins_form_set_enabled();
}

#endregion Options Dialog Helper Functions (Language > Word Wrap)


#region Options Dialog Helper Functions (Language > Comments)

defeventtab _language_comments_form;

/**
 * Determines whether the language-specific Comments Form would be 
 * unavailable for the given mode name. 
 * 
 * @param _str langId         language mode in question
 * 
 * @return bool               true if EXcluded, false if included
 */
bool isLangCommentsFormExcludedForMode(_str langId)
{
   // if it's supported, then it's not excluded...
   switch (langId) {
   case "process":
   case "fileman":
   case "grep":
      return true;
   default:
      return false;
   }
}

void _language_comments_form_init_for_options(_str langID)
{
   // this is only available for c
   if (langID != 'c') {
      ctl_auto_xmldoc_comment.p_visible = false;
      heightDiff := ctl_auto_xmldoc_comment.p_y - ctl_auto_doc_comment.p_y;

      ctl_editDocCommentAlias.p_y -= heightDiff;
      ctl_auto_insert_leading_asterick.p_y -= heightDiff;
      ctl_doc_comment_style_label.p_y -= heightDiff;
      ctl_doc_comment_style.p_y -= heightDiff;
      ctl_tag_comments.p_y -= heightDiff;
      ctlframe8.p_height -= heightDiff;

      ctlframe15.p_y -= heightDiff;
      ctlframe16.p_y -= heightDiff;
   }

   // we disable a bunch of stuff for all langs
   if (langID == ALL_LANGUAGES_ID) {
      ctlframe2.p_visible = ctlframe3.p_visible = false;

      // move everything over now
      ctlframe8.p_x = ctlframe15.p_x = ctlframe16.p_x = ctlframe2.p_x;

      // remove the "affects all languages" tag
      ctl_auto_close_block.p_caption = "Automatically close &block comments";

      ctl_editDocCommentAlias.p_visible = false;
      heightDiff := ctl_editDocCommentAlias.p_height + 120;
      ctl_auto_insert_leading_asterick.p_y -= heightDiff;
      ctl_doc_comment_style_label.p_y -= heightDiff;
      ctl_doc_comment_style.p_y -= heightDiff;
      ctl_tag_comments.p_y -= heightDiff;

      ctlframe8.p_height -= heightDiff;
      ctlframe15.p_y -= heightDiff;
      ctlframe16.p_y -= heightDiff;
   } 

   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_PROMPT));
   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_KEEP));
   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_JAVADOC));
   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN));
   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN1));
   ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN2));
   if (_is_xmldoc_supported(langID)) {
      ctl_doc_comment_style._lbadd_item(get_message(VSRC_DOC_COMMENT_STYLE_XMLDOC));
   }

   _language_form_init_for_options(langID, _language_comments_form_get_value, 
                                   _language_comments_form_is_lang_included);

   // we load and apply these comment settings separately.  They are not included 
   // in ALL LANGUAGES, and they do file i/o every time each one is set - therefore, 
   // it is a terrible idea to set them individually in a callback
   if (langID != ALL_LANGUAGES_ID) {
      // load up the left side of the page, which is not included in ALL LANGUAGES
      BlockCommentSettings p;
      getLangCommentSettings(langID, p);

      _ctl_tlc.p_text = p.m_tlc;
      _ctl_thside.p_text = p.m_thside;
      _ctl_trc.p_text = p.m_trc;
      _ctl_lvside.p_text = p.m_lvside;
      _ctl_rvside.p_text = p.m_rvside;
      _ctl_blc.p_text = p.m_blc;
      _ctl_bhside.p_text = p.m_bhside;
      _ctl_brc.p_text = p.m_brc;
      _ctl_firstline_is_top.p_value = (int)p.m_firstline_is_top;
      _ctl_lastline_is_bottom.p_value = (int)p.m_lastline_is_bottom;
      _ctl_left.p_text = p.m_comment_left;
      _ctl_right.p_text = p.m_comment_right;

      if (p.m_mode == START_AT_COLUMN) {
         if ( isinteger(p.m_comment_col) && p.m_comment_col>0 ) {
            _ctl_start_column.p_value = 1;
            _ctl_comment_col.p_text = p.m_comment_col;
         } else {
            p.m_mode = def_comment_line_mode;
         }
      } else if (p.m_mode == LEVEL_OF_INDENT) {
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
   case 'ctl_doc_comment_style':
      if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC, langId)) {
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN, langId)) {
            value = get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN);
         } else {
            value = get_message(VSRC_DOC_COMMENT_STYLE_JAVADOC);
         }
      } else if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC,  langId)) {
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN, langId)) {
            value = get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN2);
         } else {
            value = get_message(VSRC_DOC_COMMENT_STYLE_XMLDOC);
         }
      } else if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN, langId)) {
         value = get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN1);
      } else if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT, langId)) {
         value = get_message(VSRC_DOC_COMMENT_STYLE_KEEP);
      } else {
         value = get_message(VSRC_DOC_COMMENT_STYLE_PROMPT);
      }
      break;
   case 'ctl_auto_close_block':
      value = def_auto_complete_block_comment;
      break;
   case 'ctl_auto_xmldoc_comment':
      value = def_c_xmldoc;
      break;
   case 'ctl_tag_comments':
      value = (_GetCodehelpFlags(langId) & VSCODEHELPFLAG_NO_COMMENT_TAGGING)? 0:1;
      break;
   }

   return value;
}

bool _language_comments_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case 'ctl_auto_xmldoc_comment':
      included = (langId == 'c');
      break;
   case 'ctlframe16':
      included = _lang_split_strings_on_enter_enabled(langId);
      break;
   
   case 'ctlframe8':
   case 'ctl_doc_comment_style':
      // since these exclusions apply to every control within the groups, we only 
      // call them for the groups
      included = _lang_doc_comments_enabled(langId);
      break;
   case 'ctlframe15':
      // does this language have line comments?
      if (!allLangsExclusion) {
         // since this is more of a temporary exclusion, we only use it for disabling purposes
         lexer_name := _LangGetLexerName(langId);
         if (lexer_name == '') {
            lexer_name = _LangGetModeName(langId);
         }
   
         if (lexer_name != '') {
            _str commentChars[];
            _getLineCommentChars(commentChars, lexer_name);
            included = (commentChars._length() > 0);
         } else included = false;
      }
      break;
   case 'ctl_tag_comments':
      included = _is_background_tagging_supported(langId);
      break;
   }

   return included;
}

void _language_comments_form_restore_state()
{
   _language_form_restore_state(_language_comments_form_get_value, _language_comments_form_is_lang_included);
}

bool _language_comments_form_validate(int action)
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

bool _language_comments_form_apply()
{
   langID := _get_language_form_lang_id();

   if (langID != ALL_LANGUAGES_ID) {

      //Changed this to preserve spaces, expect for trailing
      //spaces on RHS borders. Previous method stripped just trailing
      //from all eight border strings (02/13/06)
      BlockCommentSettings curSettings;
      curSettings.m_tlc    = _ctl_tlc.p_text;
      curSettings.m_thside = strip(_ctl_thside.p_text, 'B');;
      curSettings.m_trc    = _ctl_trc.p_text;
      curSettings.m_lvside = _ctl_lvside.p_text;
      curSettings.m_rvside = _ctl_rvside.p_text;
      curSettings.m_blc    = _ctl_blc.p_text;
      curSettings.m_bhside = strip(_ctl_bhside.p_text, 'B');
      curSettings.m_brc    = _ctl_brc.p_text;
      curSettings.m_comment_left  = _ctl_left.p_text;
      curSettings.m_comment_right = _ctl_right.p_text;
      curSettings.m_firstline_is_top= (_ctl_firstline_is_top.p_value != 0);
      curSettings.m_lastline_is_bottom= (_ctl_lastline_is_bottom.p_value != 0);

      curSettings.m_comment_col = 0;
      if ( _ctl_start_column.p_value ) {
         curSettings.m_comment_col = (_ctl_comment_col.p_text == '') ? 0 : (int)_ctl_comment_col.p_text;
         curSettings.m_mode = START_AT_COLUMN;

         if (!isinteger(_ctl_comment_col.p_text) || _ctl_comment_col.p_text < 0) {
            _message_box('Invalid comment column');
            p_window_id = _ctl_comment_col;
            _set_sel(1,length(p_text)+1);_set_focus();
            return false;
         } else curSettings.m_comment_col = (int)_ctl_comment_col.p_text;

      } else if (_ctl_level_indent.p_value) {
         curSettings.m_mode = LEVEL_OF_INDENT;
      } else {
         curSettings.m_mode = LEFT_MARGIN;
      }

      // compare to the original ones
      BlockCommentSettings origSettings;
      getLangCommentSettings(langID, origSettings);
      if (curSettings != origSettings) {
         if (saveCommentSettings(langID, curSettings) ) {
            _message_box('Error saving settings for language .'_LangGetModeName(langID));
            return false;
         }

         // Maybe update the lexer settings if the line comment settings have changed.
         _maybe_update_lexer_settings(_LangGetLexerName(langID), origSettings, curSettings);
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

void _maybe_update_lexer_settings(_str lexername, BlockCommentSettings& orig, BlockCommentSettings& cur)
{
#if 0
   if (cur.m_comment_left != orig.m_comment_left || cur.m_comment_right != orig.m_comment_right) {

      int resp = _message_box("You have made changes to the line comment settings that require " :+
                              "matching changes in the color coding setup for the commenting support " :+
                              "to work.  Make these changes automatically?", 
                              "Update comment settings", 
                              MB_YESNO|MB_ICONQUESTION);

      if (resp == IDNO) {
         return;
      }

      if (cur.m_comment_left != '') {
         if (cur.m_comment_right != '') {
            _block_comment_maybe_update_lexer(lexername, cur.m_comment_left, cur.m_comment_right);
         } else {
            _line_comment_maybe_update_lexer(lexername, cur.m_comment_left);
         }
      }
   }
#endif
}

void _language_comments_form_apply_control(_str controlName, _str langId, _str value)
{
   checked := isinteger(value) && ((int)value != 0);
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
   case 'ctl_doc_comment_style':
      checked = true;
      commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC;
      commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC;
      commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
      commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT;
      switch (substr(value,1,3)) {
      case CODEHELP_JAVADOC_PREFIX:
         flag = VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC;
         break;
      case CODEHELP_DOXYGEN_PREFIX:
         flag = VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC|VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
         break;
      case CODEHELP_DOXYGEN_PREFIX1:
         flag = VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
         break;
      case CODEHELP_DOXYGEN_PREFIX2:
         if (pos("XMLDOC", value, 1, 'i')) {
            flag = VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC;
         } else {
            flag = VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN|VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC;
         }
         break;
      default:
         if (!pos("Prompt", value, 1, 'i')) {
            flag = VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT;
            checked = true;
         } else {
            flag = VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT;
            checked = false;
         }
         break;
      }
      break;
   case 'ctl_auto_close_block':
      def_auto_complete_block_comment = checked;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      break;
   case 'ctl_auto_xmldoc_comment':
      def_c_xmldoc = checked;
      flag = VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      break;
   case 'ctl_tag_comments':
      {
         // never turn off documentation comments for xmldoc and tagdoc
         codehelpFlags := LanguageSettings.getCodehelpFlags(langId);
         newFlags      := codehelpFlags;
         if (checked || langId == "tagdoc" || langId == "xmldoc" || langId == "tld") {
            newFlags &= ~VSCODEHELPFLAG_NO_COMMENT_TAGGING;
         } else {
            newFlags |= VSCODEHELPFLAG_NO_COMMENT_TAGGING;
         }
         if (newFlags != codehelpFlags) {
            LanguageSettings.setCodehelpFlags(langId, newFlags);
            RetagCppBuffers(updateCurrentFile:true, langId);
         }
         return;
      }
   }

   if (flag) {
      if (checked) {
         commentFlags |= flag;
      } else {
         commentFlags &= ~flag;
      }
   
      _LangSetProperty(langId,VSLANGPROPNAME_COMMENT_EDITING_FLAGS, commentFlags);
   }

}

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
   filename := getDocAliasProfileName(langID);

   // now launch the alias dialog
   typeless result = show("-new -modal _alias_editor_form", filename, false, "/**", DOCCOMMENT_ALIAS_FILE);

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

#endregion Options Dialog Helper Functions (Language > Comments)


#region Options Dialog Helper Functions (Language > Comment Wrap)

defeventtab _language_comment_wrap_form;

/**
 * Determines whether the _ext_comment_wrap_form would be 
 * unavailable for the given mode name. 
 * 
 * @param _str langId         language mode in question
 * 
 * @return bool               true if EXcluded, false if included
 */
bool isLangCommentWrapFormExcludedForMode(_str langId)
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

      heightDiff := (_ctl_vert_line_col_frame.p_height - (_ctl_vert_line_col_link.p_y_extent + _ctl_vert_line_col_link.p_x));
      _ctl_vert_line_col_frame.p_height -= heightDiff;
   }

   _language_form_init_for_options(langID, _language_comment_wrap_form_get_value, 
                                   _language_comment_wrap_form_is_lang_included);

   // change the enable caption for pl1 for preserve trailing comment feature 
   isPL1 := (langID == 'pl1');
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

bool _language_comment_wrap_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
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

bool _language_comment_wrap_form_validate(int action)
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

bool _language_comment_wrap_form_apply()
{
   langID := _get_language_form_lang_id();

   //Clear local hash table of settings.
   //XWclearState();

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
   enabled := false;
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
   isPL1 := (_ctl_CW_enable_lineblock.p_caption == 'Preserve location of trailing comments');

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

#endregion Options Dialog Helper Functions (Language > Comment Wrap)


#region Options Dialog Helper Functions (Language > Auto Complete)

static const AC_INCLUDE_NONE_CB_TEXT        = "Do not list include files";
static const AC_INCLUDE_QUOTED_CB_TEXT      = "List quoted files after typing #include";
static const AC_INCLUDE_AFTER_QUOTE_CB_TEXT = "List files after typing \" or <";

static const AC_PRESERVE_IDENTIFIER_FOR_ALM = "Preserve for auto list members only";
static const AC_PRESERVE_IDENTIFIER         = "Preserve always";
static const AC_REPLACE_IDENTIFIER          = "Replace entire identifier";

static const AC_SELECTION_METHOD_MANUAL     = "Manually choose completion";
static const AC_SELECTION_METHOD_INSERT     = "Insert current completion in file";
static const AC_SELECTION_METHOD_UNIQUE     = "Automatically choose unique completion";

static const AC_PATTERN_MATCH_STSK_SUBWORD  = "Stone-skipping with subword boundaries";
static const AC_PATTERN_MATCH_STSK_ACRONYM  = "Acronyms using subword boundaries";
static const AC_PATTERN_MATCH_STSK_PURE     = "Pure stone-skipping";
static const AC_PATTERN_MATCH_CHAR_BITSET   = "Character matching in any order";
static const AC_PATTERN_MATCH_SUBSTRING     = "Simple substring matching";
static const AC_PATTERN_MATCH_SUBWORD       = "Subword matching";
static const AC_PATTERN_MATCH_PREFIX        = "Prefix matching only (subword matching OFF)";


defeventtab _language_auto_complete_form;

void _language_auto_complete_form_init_for_options(_str langID)
{
   // hide some things if tagging is not available
   if (!_haveContextTagging()) {
      
      // hide symbol-related auto-complete options
      ctl_auto_complete_locals.p_visible = false;
      ctl_auto_complete_members.p_visible = false;
      ctl_auto_complete_current_file.p_visible = false;
      ctl_auto_complete_arguments.p_visible = false;

      yDiff := ctl_auto_complete_expand_syntax.p_y - ctl_auto_complete_locals.p_y;
      ctl_auto_complete_expand_syntax.p_y -= yDiff;
      ctl_auto_complete_expand_alias.p_y -= yDiff;
      ctl_auto_complete_keywords.p_y -= yDiff;
      ctl_auto_complete_words.p_y -= yDiff;

      // hide symbol related visual details
      ctl_auto_complete_show_prototypes.p_visible = false;
      ctl_auto_complete_show_decl.p_visible = false;
      ctl_auto_complete_show_comments.p_visible = false;

      // adjust the height of the two top frames
      ctl_auto_complete_details.p_height = 2*ctl_auto_complete_pic_main.p_y + ctl_auto_complete_pic_main.p_height;
      yDiff = ctl_auto_complete_frame.p_height - ctl_auto_complete_details.p_height;
      ctl_auto_complete_frame.p_height = ctl_auto_complete_details.p_height;

      ctl_auto_complete_options.p_y -= yDiff;
      ctlListSymbolsFrame.p_y -= yDiff;
      ctlCaseSensFrame.p_y -= yDiff;
      ctlSubwordFrame.p_y -= yDiff;

      // hide list-symbols options and subword matching options
      ctlListSymbolsFrame.p_visible = false;
      ctlSubwordFrame.p_visible = false;
      ctlautolistmembers.p_visible = false;
      ctlautolistvalues.p_visible=false;

      yDiff = ctlCaseSensFrame.p_y - ctlListSymbolsFrame.p_y;
      ctlCaseSensFrame.p_y -= yDiff;
      ctlSubwordFrame.p_y -= yDiff;

      // hide insert open parenthesis option
      ctlInsertOpenParen.p_visible=false;
      yDiff = ctl_auto_complete_tab_insert.p_y - ctlInsertOpenParen.p_y;
      next_wid := ctlInsertOpenParen.p_next;
      while (next_wid && next_wid != ctlInsertOpenParen.p_window_id) {
         next_wid.p_y -= yDiff;
         next_wid = next_wid.p_next;
      }
      ctl_auto_complete_includes_label.p_visible=false;
      ctl_auto_complete_includes.p_visible=false;
      ctl_auto_complete_options.p_height = ctl_auto_complete_includes_label.p_y;
   }

   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_MANUAL);
   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_INSERT);
   ctl_auto_complete_selection_method._lbadd_item(AC_SELECTION_METHOD_UNIQUE);

   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_NONE_CB_TEXT);
   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_QUOTED_CB_TEXT);
   ctl_auto_complete_includes._lbadd_item(AC_INCLUDE_AFTER_QUOTE_CB_TEXT);

   if (_haveContextTagging()) {
      ctlpreserveidentifier._lbadd_item(AC_PRESERVE_IDENTIFIER_FOR_ALM);
   }
   ctlpreserveidentifier._lbadd_item(AC_PRESERVE_IDENTIFIER);
   ctlpreserveidentifier._lbadd_item(AC_REPLACE_IDENTIFIER);


   sizeBrowseButtonToTextBox(ctl_subword_strategy_label.p_window_id, ctl_subword_strategy_help.p_window_id);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_STSK_SUBWORD);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_STSK_ACRONYM);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_STSK_PURE);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_CHAR_BITSET);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_SUBSTRING);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_SUBWORD);
   ctl_subword_strategy._lbadd_item(AC_PATTERN_MATCH_PREFIX);

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

   ctlautolistmembers.call_event(ctlautolistmembers,lbutton_up);
}

_str _language_auto_complete_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   flags := AutoCompleteGetOptions(langId);
   codehelpFlags := LanguageSettings.getCodehelpFlags(langId);

   switch (controlName) {
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
      if (_haveContextTagging() && preserveFlag == replaceFlag) {
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

   case 'ctlautocompletecasesensitive':
      value = (flags & AUTO_COMPLETE_NO_STRICT_CASE) ? 0 : 1;
      break;
   case 'ctllistmemcasesensitive':
      value = (codehelpFlags & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) ? 1 : 0;
      break;
   case 'ctlidentcasesensitive':
      value = (codehelpFlags & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE) ? 1 : 0;
      break;

   case 'ctl_auto_complete_subwords':
      value = (flags & AUTO_COMPLETE_SUBWORD_MATCHES) ? 1 : 0;
      break;
   case 'ctl_auto_complete_no_globals':
      value = (flags & AUTO_COMPLETE_SUBWORD_NO_GLOBALS) ? 1 : 0;
      break;
   case 'ctl_list_members_subwords':
      value = (codehelpFlags & VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES) ? 0 : 1;
      break;
   case 'ctl_completion_subwords':
      value = (codehelpFlags & VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES) ? 0 : 1;
      break;
   case 'ctl_completion_on_retry':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY) ? 1 : 0;
      break;
   case 'ctl_completion_relax_order':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_RELAX_ORDER) ? 1 : 0;
      break;
   case 'ctl_completion_globals_first_char':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_GLOBALS_FIRST_CHAR) ? 1 : 0;
      break;
   case 'ctl_completion_subwords_workspace':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_WORKSPACE_ONLY) ? 1 : 0;
      break;
   case 'ctl_completion_subwords_include_auto_updated':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_AUTO_UPDATED) ? 1 : 0;
      break;
   case 'ctl_completion_subwords_include_compiler':
      value = (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_COMPILER) ? 1 : 0;
      break;
   case 'ctl_completion_fuzzy':
      value = (codehelpFlags & VSCODEHELPFLAG_COMPLETION_NO_FUZZY_MATCHES) ? 0 : 1;
      break;

   case 'ctl_subword_strategy':
      switch (LanguageSettings.getAutoCompleteSubwordPatternOption(langId)) {
      case AUTO_COMPLETE_SUBWORD_MATCH_NONE:
         value = AC_PATTERN_MATCH_PREFIX;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_STSK_SUBWORD:
         value = AC_PATTERN_MATCH_STSK_SUBWORD;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_STSK_ACRONYM:
         value = AC_PATTERN_MATCH_STSK_ACRONYM;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_STSK_PURE:
         value = AC_PATTERN_MATCH_STSK_PURE;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_CHAR_BITSET:
         value = AC_PATTERN_MATCH_CHAR_BITSET;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_SUBSTRING:
         value = AC_PATTERN_MATCH_SUBSTRING;
         break;
      case AUTO_COMPLETE_SUBWORD_MATCH_SUBWORD:
         value = AC_PATTERN_MATCH_SUBWORD;
         break;
      }
      break;

   }

   return value;
}

bool _language_auto_complete_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
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
   case 'ctl_auto_complete_show_prototypes':
   case 'ctl_auto_complete_show_decl':
   case 'ctl_auto_complete_show_comments':
   case 'ctllistmemcasesensitive':
   case 'ctlidentcasesensitive':
   case 'ctl_completion_subwords':
   case 'ctl_completion_on_retry':
   case 'ctl_auto_complete_subwords':
   case 'ctl_auto_complete_no_globals':
   case 'ctl_list_members_subwords':
   case 'ctl_subword_strategy':
   case 'ctl_subword_strategy_label':
   case 'ctl_subword_strategy_help':
   case 'ctl_completion_relax_order':
   case 'ctl_completion_globals_first_char':
   case 'ctl_completion_subwords_workspace':
   case 'ctl_completion_subwords_include_auto_updated':
   case 'ctl_completion_subwords_include_compiler':
   case 'ctl_completion_fuzzy':
      included = (_istagging_supported(langId));
      break;
   case 'ctl_auto_complete_locals':
      included = (_are_locals_supported(langId));
      break;
   case 'ctl_auto_complete_arguments':
      included = (_FindLanguageCallbackIndex("_%s_autocomplete_get_arguments", langId) != 0);
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
   }

   return included;
}

void _language_auto_complete_form_restore_state()
{
   _language_form_restore_state(_language_auto_complete_form_get_value, _language_auto_complete_form_is_lang_included);
}

bool _language_auto_complete_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      
      if (!validateLangIntTextBox(ctl_auto_complete_minimum.p_window_id)) {
         return false;
      }
   }

   return true;
}

bool _language_auto_complete_form_apply()
{
   langID := _get_language_form_lang_id();

   _language_form_apply(_language_auto_complete_form_apply_control);

   return true;
}

void _language_auto_complete_form_apply_control(_str controlName, _str langId, _str value)
{
   oldCodehelpFlags := LanguageSettings.getCodehelpFlags(langId);
   newCodehelpFlags := oldCodehelpFlags;
   codehelpFlag := VSCODEHELPFLAG_NULL;

   oldFlags := AutoCompleteGetOptions(langId);
   newFlags := oldFlags;
   flag := (AutoCompleteFlags)0;

   turnFlagOn := false;
   if (isinteger(value)) {
      turnFlagOn = ((int)value != 0);
   }

   switch (controlName) {
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
   case 'ctlautocompletecasesensitive':
      flag = AUTO_COMPLETE_NO_STRICT_CASE;
      turnFlagOn = true;
      break;
   case 'ctllistmemcasesensitive':
      codehelpFlag = VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE;
      break;
   case 'ctlidentcasesensitive':
      codehelpFlag = VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE;
      break;

   case 'ctl_auto_complete_subwords':
      flag = AUTO_COMPLETE_SUBWORD_MATCHES;
      break;
   case 'ctl_auto_complete_no_globals':
      flag = AUTO_COMPLETE_SUBWORD_NO_GLOBALS;
      break;
   case 'ctl_list_members_subwords':
      codehelpFlag = VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES;
      turnFlagOn = true;
      break;
   case 'ctl_completion_subwords':
      codehelpFlag = VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES;
      turnFlagOn = true;
      break;
   case 'ctl_completion_on_retry':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY;
      break;
   case 'ctl_completion_relax_order':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_RELAX_ORDER;
      break;
   case 'ctl_completion_globals_first_char':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_GLOBALS_FIRST_CHAR;
      break;
   case 'ctl_completion_subwords_workspace':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_WORKSPACE_ONLY;
      break;
   case 'ctl_completion_subwords_include_auto_updated':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_INC_AUTO_UPDATED;
      break;
   case 'ctl_completion_subwords_include_compiler':
      codehelpFlag = VSCODEHELPFLAG_SUBWORD_MATCHING_INC_COMPILER;
      break;
   case 'ctl_completion_fuzzy':
      codehelpFlag = VSCODEHELPFLAG_COMPLETION_NO_FUZZY_MATCHES;
      turnFlagOn = true;
      break;

   case 'ctl_subword_strategy':
      switch (value) {
      case AC_PATTERN_MATCH_PREFIX:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_NONE);
         break;
      case AC_PATTERN_MATCH_STSK_SUBWORD:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_STSK_SUBWORD);
         break;
      case AC_PATTERN_MATCH_STSK_ACRONYM:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_STSK_ACRONYM);
         break;
      case AC_PATTERN_MATCH_STSK_PURE:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_STSK_PURE);
         break;
      case AC_PATTERN_MATCH_CHAR_BITSET:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_CHAR_BITSET);
         break;
      case AC_PATTERN_MATCH_SUBSTRING:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_SUBSTRING);
         break;
      case AC_PATTERN_MATCH_SUBWORD:
         LanguageSettings.setAutoCompleteSubwordPatternOption(langId, AUTO_COMPLETE_SUBWORD_MATCH_SUBWORD);
         break;
      }
      break;
   }

   if (flag != 0) {
      if (turnFlagOn) {
         newFlags = oldFlags | flag;
      } else {
         newFlags = oldFlags & ~flag;
      }
   }
   if (newFlags != oldFlags) {
      LanguageSettings.setAutoCompleteOptions(langId, newFlags);
   }

   if (codehelpFlag != 0) {
      if (turnFlagOn) {
         newCodehelpFlags = oldCodehelpFlags | codehelpFlag;
      } else {
         newCodehelpFlags = oldCodehelpFlags & ~codehelpFlag;
      }
   }
   if (newCodehelpFlags != oldCodehelpFlags) {
      LanguageSettings.setCodehelpFlags(langId, newCodehelpFlags);
   }
}


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

void ctl_completion_subwords.lbutton_up()
{
   ctl_completion_on_retry.p_enabled = (ctl_completion_subwords.p_value != 0 || ctl_list_members_subwords.p_value != 0);
}

void ctl_completion_subwords_workspace.lbutton_up()
{
   ctl_completion_subwords_include_auto_updated.p_enabled = (ctl_completion_subwords_workspace.p_value != 0);
   ctl_completion_subwords_include_compiler.p_enabled = (ctl_completion_subwords_workspace.p_value != 0);
}

void ctl_subword_strategy.on_change(int reason)
{
   switch (p_text) {
   case AC_PATTERN_MATCH_STSK_SUBWORD:
   case AC_PATTERN_MATCH_STSK_ACRONYM:
   case AC_PATTERN_MATCH_STSK_PURE:
      ctl_completion_relax_order.p_enabled = true;
      break;
   default:
      ctl_completion_relax_order.p_enabled = false;
      break;
   }
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

   hasTagging := (langId == ALL_LANGUAGES_ID) || _istagging_supported(langId);
   hasSyntax  := (langId == ALL_LANGUAGES_ID) || _FindLanguageCallbackIndex("_%s_get_syntax_completions",langId)!=0;
   hasArguments := (langId == ALL_LANGUAGES_ID) || _FindLanguageCallbackIndex("_%s_autocomplete_get_arguments",langId)!=0;

   enabled := ctl_auto_complete_frame.p_value? true:false;

   ctl_auto_complete_expand_syntax.p_enabled=enabled && hasSyntax;
   ctl_auto_complete_keywords.p_enabled=enabled;
   ctl_auto_complete_expand_alias.p_enabled=enabled;
   ctl_auto_complete_symbols.p_enabled=enabled && hasTagging;
   ctl_auto_complete_locals.p_enabled=enabled && hasTagging;
   ctl_auto_complete_members.p_enabled=enabled && hasTagging;
   ctl_auto_complete_current_file.p_enabled=enabled && hasTagging;
   ctl_auto_complete_words.p_enabled=enabled;
   ctl_auto_complete_arguments.p_enabled=enabled && hasArguments;
   ctl_auto_complete_includes.p_enabled = enabled;
   ctl_auto_complete_includes_label.p_enabled = enabled;

   ctl_auto_complete_tab_insert.p_enabled=enabled;
   ctl_auto_complete_tab_next.p_enabled=enabled;
   ctl_auto_complete_selection_label.p_enabled = enabled;
   ctl_auto_complete_selection_method.p_enabled = enabled;

   ctlautocompletecasesensitive.p_enabled=enabled && hasTagging;
   ctllistmemcasesensitive.p_enabled=enabled && hasTagging;
   ctlidentcasesensitive.p_enabled=enabled && hasTagging;

   ctl_auto_complete_subwords.p_enabled=enabled && hasTagging;
   ctl_auto_complete_no_globals.p_enabled=enabled && hasTagging;
   ctl_list_members_subwords.p_enabled=enabled && hasTagging;
   ctl_completion_subwords.p_enabled=enabled && hasTagging;
   ctl_completion_on_retry.p_enabled=enabled && hasTagging;
   ctl_subword_strategy_label.p_enabled=enabled && hasTagging;
   ctl_subword_strategy_help.p_enabled=enabled && hasTagging;
   ctl_subword_strategy.p_enabled=enabled && hasTagging;
   ctl_completion_relax_order.p_enabled=enabled && hasTagging;
   ctl_completion_globals_first_char.p_enabled=enabled && hasTagging;
   ctl_completion_subwords_workspace.p_enabled=enabled && hasTagging;
   ctl_completion_subwords_include_auto_updated.p_enabled=enabled && hasTagging;
   ctl_completion_subwords_include_compiler.p_enabled=enabled && hasTagging;
   ctl_completion_fuzzy.p_enabled=enabled && hasTagging;

   ctl_auto_complete_show_bulb.p_enabled=enabled;
   ctl_auto_complete_show_list.p_enabled=enabled;
   ctl_auto_complete_show_icons.p_enabled=enabled && (ctl_auto_complete_show_list.p_value? true:false);
   ctl_auto_complete_show_categories.p_enabled=enabled && (ctl_auto_complete_show_list.p_value? true:false);
   ctl_auto_complete_show_decl.p_enabled=enabled && hasTagging;
   ctl_auto_complete_show_comments.p_enabled=enabled && hasTagging;
   ctl_auto_complete_show_prototypes.p_enabled=enabled && hasArguments;
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

#endregion Options Dialog Helper Functions (Language > Auto Complete)


#region Options Dialog Helper Functions (Language > Auto-Close)

defeventtab _language_auto_bracket_form;

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

   yDiff := 0;
   if (!isLangAutoCloseAdvanceBraceExcludedForLanguage(langID)) {
      _advanced_brace.p_visible = true;
      _cb_ab_brace.p_visible = false;

      yDiff = _advanced_brace.p_y - _cb_ab_brace.p_y;
      _advanced_brace.p_y -= yDiff;
   } else {
      yDiff = _ctl_enable_autobracket.p_y - _advanced_brace.p_y;
      _advanced_brace.p_visible = false;
   }
    
   _ctl_enable_autobracket.p_y -= yDiff;

   // For languages with new beautifier, quick brace settings has moved
   // to auto-close.
   if (_beautifier_gui_uses_options_xml(langID)) {
      _ctl_enable_autobracket.p_visible = true;
   } else {
      _ctl_enable_autobracket.p_visible = false;
      yDiff += _ctl_enable_autobracket.p_height;
   }

   _link_ab_config.p_y -= yDiff;
   _link_comments_config.p_y -= yDiff;

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

   case '_ctl_enable_autobracket':
      value = LanguageSettings.getQuickBrace(langId) ? 1 : 0;
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

bool _language_auto_bracket_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
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

bool _language_auto_bracket_form_apply()
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

   case '_ctl_enable_autobracket':
      LanguageSettings.setQuickBrace(langId, flagOn);
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

void _language_auto_bracket_form.on_destroy()
{
   _language_form_on_destroy();
}

void _cb_auto_bracket.lbutton_up()
{
   enabled := _cb_auto_bracket.p_value ? true : false;
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
   _advanced_brace.p_enabled=enabled;
}

void _cb_ab_paren.lbutton_up()
{
   enabled := p_value ? true : false;
   _cb_ab_paren_pad.p_enabled=enabled;
}

void _cb_ab_bracket.lbutton_up()
{
   enabled := p_value ? true : false;
   _cb_ab_bracket_pad.p_enabled=enabled;
}

void _cb_ab_angle.lbutton_up()
{
   enabled := p_value ? true : false;
   _cb_ab_angle_pad.p_enabled=enabled;
}

void _cb_ab_brace.lbutton_up()
{
   enabled := p_value ? true : false;
   _cb_ab_brace_pad.p_enabled=enabled;
}

void _link_ab_config.lbutton_up()
{
   config('Auto-Close', 'N');
}

void _link_comments_config.lbutton_up()
{
   showOptionsForLangId(_get_language_form_lang_id(), 'Comments');
}

#endregion Options Dialog Helper Functions (Language > Auto-Close)


#region Options Dialog Helper Functions (Language > Auto-Surround)

defeventtab _language_auto_surround_form;

void _language_auto_surround_form_init_for_options(_str langID)
{
   _language_form_init_for_options(langID, _language_auto_surround_form_get_value, 
                                   _language_auto_surround_form_is_lang_included);

   call_event(_cb_auto_surround.p_window_id, LBUTTON_UP);
}

_str _language_auto_surround_form_get_value(_str controlName, _str langId)
{
   _str value = 0;
   flags := LanguageSettings.getAutoSurround(langId);
   switch (controlName) {
   case '_cb_auto_surround':
      value = (flags & AUTO_BRACKET_ENABLE) ? 1 : 0;
      break;
   case '_cb_as_paren':
      value = (flags & AUTO_BRACKET_PAREN) ? 1 : 0;
      break;
   case '_cb_as_bracket':
      value = (flags & AUTO_BRACKET_BRACKET) ? 1 : 0;
      break;
   case '_cb_as_angle':
      value = (flags & AUTO_BRACKET_ANGLE_BRACKET) ? 1 : 0;
      break;
   case '_cb_as_dquote':
      value = (flags & AUTO_BRACKET_DOUBLE_QUOTE) ? 1 : 0;
      break;
   case '_cb_as_squote':
      value = (flags & AUTO_BRACKET_SINGLE_QUOTE) ? 1 : 0;
      break;
   case '_cb_as_brace':
      value = (flags & AUTO_BRACKET_BRACE) ? 1 : 0;
      break;
   }
   return value;
}

bool _language_auto_surround_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;

   switch (controlName) {
   case '_cb_as_squote':
      // 11887 - disable for VBScript, since single quote is a comment character
      included = (langId != 'vbs');
      break;
   }

   return included;
}

void _language_auto_surround_form_restore_state()
{
   _language_form_restore_state(_language_auto_surround_form_get_value, _language_auto_surround_form_is_lang_included);
}

bool _language_auto_surround_form_apply()
{
   _language_form_apply(_language_auto_surround_form_apply_control);
   return true;
}

void _language_auto_surround_form_apply_control(_str controlName, _str langId, _str value)
{
   // try auto suround
   oldFlags := LanguageSettings.getAutoSurround(langId);
   newFlags := oldFlags;

   flagOn := false;
   if (isinteger(value)) {
      flagOn = ((int)value != 0);
   }
   flag := 0;

   switch (controlName) {
   case '_cb_auto_surround':
      flag = AUTO_BRACKET_ENABLE;
      break;
   case '_cb_as_paren':
      flag = AUTO_BRACKET_PAREN;
      break;
   case '_cb_as_bracket':
      flag = AUTO_BRACKET_BRACKET;
      break;
   case '_cb_as_angle':
      flag = AUTO_BRACKET_ANGLE_BRACKET;
      break;
   case '_cb_as_dquote':
      flag = AUTO_BRACKET_DOUBLE_QUOTE;
      break;
   case '_cb_as_squote':
      flag = AUTO_BRACKET_SINGLE_QUOTE;
      break;
   case '_cb_as_brace':
      flag = AUTO_BRACKET_BRACE;
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
      LanguageSettings.setAutoSurround(langId, newFlags);
   }
}


void _language_auto_surround_form.on_destroy()
{
   _language_form_on_destroy();
}

void _cb_auto_surround.lbutton_up()
{
   enabled := _cb_auto_surround.p_value ? true : false;
   _cb_as_paren.p_enabled=enabled;
   _cb_as_bracket.p_enabled=enabled;
   _cb_as_angle.p_enabled=enabled;
   _cb_as_dquote.p_enabled=enabled;
   // this is disabled for VBScript
   _cb_as_squote.p_enabled=(enabled && _get_language_form_lang_id() != 'vbs');
   _cb_as_brace.p_enabled=enabled;
}

#endregion Options Dialog Helper Functions (Language > Auto-Surround)


#region Options Dialog Helper Functions (Language > Tag Files)

defeventtab _language_tagging_form;

static const TAG_NAVIGATION_PROMPT             = "Prompt with all choices";
static const TAG_NAVIGATION_PREFER_DEFINITION  = "Symbol definition (proc)";
static const TAG_NAVIGATION_PREFER_DECLARATION = "Symbol declaration (proto)";
static const TAG_NAVIGATION_ONLY_WORKSPACE     = "Only Show Symbols in Current Workspace";
static const TAG_NAVIGATION_ONLY_PROJECT       = "Only Show Symbols in Current Project";

/**
 * Determines whether the _ext_tagging_form would be unavailable
 * for the given mode name. 
 * 
 * @param _str modeName       mode name in question
 * 
 * @return bool               true if EXcluded, false if ,
 *                            included
 */
bool isLangTaggingFormExcludedForMode(_str langId)
{
   // we automatically allow ALL LANGUAGES
   if (langId == ALL_LANGUAGES_ID) return false;

   // if jaws mode is on, we don't want this to be enabled.
   if (_jaws_mode()) return true;

   // disable it for Build Window, Search Results, and File Manager
   switch (langId) {
   case "process":
   case "fileman":
   case "grep":
      return true;
   }

   // if everything is disabled, there's just not much point...
   enabled := false;
   do {

      // if any of these things are true, we like it...
      enabled = (_FindLanguageCallbackIndex("_%s_get_expression_info", langId) != 0 || 
                            _FindLanguageCallbackIndex("vs%s_get_expression_info", langId) != 0 || 
                            _FindLanguageCallbackIndex("_%s_get_idexp", langId) != 0);
      if (enabled) break;

      enabled = (_FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      if (enabled) break;

      enabled = (_FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      if (enabled) break;

      enabled = (_FindLanguageCallbackIndex("_%s_get_expression_pos", langId) != 0 &&
                            _FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      if (enabled) break;
   
      enabled = (_FindLanguageCallbackIndex("vs%s_list_tags", langId)!=0 ||
                            _FindLanguageCallbackIndex("%s_proc_search", langId)!=0 ||
                            _FindLanguageCallbackIndex("_%s_find_context_tags", langId)!=0);
      if (enabled) break;

      enabled = isLangReferencedByTaggingLanguage(langId);

   } while (false);

   return !enabled;
}

static bool isLangReferencedByTaggingLanguage(_str langId)
{
   _str allLangIds[];
   _GetAllLangIds(allLangIds);
   for (i:=0;i<allLangIds._length();++i) {
      refLang:=allLangIds[i];
      list:=_LangGetProperty(refLang,VSLANGPROPNAME_REFERENCED_IN_LANGIDS);
      // see if our target language is in the list
      if (pos(' 'langId' ', ' 'list' ')) {
         // get the referenced lang - see if it has tagging available
         if (refLang != langId && !isLangTaggingFormExcludedForMode(refLang)) return true;
      }
   }
   // found nothing
   return false;
}

void _language_tagging_form_init_for_options(_str langID)
{
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PROMPT);
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PREFER_DEFINITION);
   ctlnavigation._lbadd_item(TAG_NAVIGATION_PREFER_DECLARATION);

   ctlnavchoices._lbadd_item(TAG_NAVIGATION_PROMPT);
   ctlnavchoices._lbadd_item(TAG_NAVIGATION_ONLY_WORKSPACE);
   ctlnavchoices._lbadd_item(TAG_NAVIGATION_ONLY_PROJECT);

   label_x_extent := max(ctlnavigation.p_prev.p_x_extent, ctlnavchoices.p_prev.p_x_extent);
   ctlnavigation.p_x = ctlnavchoices.p_x = label_x_extent+150;
   ctlnavigation.p_x_extent = ctlnavchoices.p_x_extent = ctlframe11.p_width - ctlmouseoverinfo.p_x;

   _language_form_init_for_options(langID, _language_tagging_form_get_value, 
                                   _language_tagging_form_is_lang_included);

   _link_auto_complete_config.p_mouse_pointer = MP_HAND;

   ctlmouseoverinfo.call_event(ctlmouseoverinfo.p_window_id, LBUTTON_UP);

   has_lang_keywords := _LanguageInheritsFrom("cs", langID);
   ctlinsertparamkeyword.p_enabled = has_lang_keywords;
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
   case 'ctlinsertparamkeyword':
      value = (codehelpFlags & VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS) ? 0 : 1;
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
   case 'ctlnavchoices':
      if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT) {
         value = TAG_NAVIGATION_ONLY_PROJECT;
      } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE) {
         value = TAG_NAVIGATION_ONLY_WORKSPACE;
      } else {
         value = TAG_NAVIGATION_PROMPT;
      }
      break;
   case 'ctlpreferproject':
      value = (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT) ? 1 : 0;
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
   case 'ctlfindoverriddenmethods':
      value = (codehelpFlags & VSCODEHELPFLAG_FIND_NO_DERIVED_VIRTUAL_OVERRIDES) ? 0 : 1;
      break;
   case 'ctlmouseoverinfo':
      value = (codehelpFlags & VSCODEHELPFLAG_MOUSE_OVER_INFO) ? 1 : 0;
      break;
   case 'ctldispmembercomment':
      value = (codehelpFlags & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS) ? 1 : 0;
      break;
   case 'ctldispreturntype':
      value = (codehelpFlags & VSCODEHELPFLAG_DISPLAY_RETURN_TYPE) ? 1 : 0;
      break;
   case 'ctlhighlighttag':
      value = (codehelpFlags & VSCODEHELPFLAG_HIGHLIGHT_TAGS) ? 1 : 0;
      break;
   case 'ctlpreviewinfo':
      value = (codehelpFlags & VSCODEHELPFLAG_NO_PREVIEW_INFO) ? 0 : 1;
      break;
   case 'ctlpreviewcomment':
      value = (codehelpFlags & VSCODEHELPFLAG_PREVIEW_NO_COMMENTS) ? 0 : 1;
      break;
   case 'ctlpreviewreturntype':
      value = (codehelpFlags & VSCODEHELPFLAG_PREVIEW_RETURN_TYPE) ? 1 : 0;
      break;
   case 'ctlshowstatements':
      value = (codehelpFlags & VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS) ? 1 : 0;
      break;
   }

   return value;
}

bool _language_tagging_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion=false)
{
   included := true;

   switch (controlName) {
   case 'ctlmouseoverinfo':
   case 'ctldispmembercomment':
   case 'ctlpreviewcomment':
   case 'ctlpreviewinfo':
   case 'ctlhighlighting':
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
   case 'ctlfindoverriddenmethods':
      included = (_FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      break;
   case 'ctlautoinsertparam':
      included = (_haveContextTagging() && def_persistent_select=='D' && _FindLanguageCallbackIndex("_%s_fcthelp_get", langId) != 0);
      break;
   case 'ctlautolistparams':
   case 'ctlfilteroverloads':
      included = (_haveContextTagging() && _FindLanguageCallbackIndex("_%s_analyze_return_type", langId) != 0);
      break;
   case 'ctldispreturntype':
   case 'ctlpreviewreturntype':
      included = _haveContextTagging() && 
                 (_FindLanguageCallbackIndex("_%s_parse_return_type", langId) != 0 ||
                 _FindLanguageCallbackIndex("_%s_get_type_of_expression", langId) != 0);
      break;
   case 'ctlshowstatements':
      included = (_haveContextTagging() && _are_statements_supported(langId) != 0);
      break;
   }

   return included;
}

void _language_tagging_form_restore_state()
{
   _language_form_restore_state(_language_tagging_form_get_value, _language_tagging_form_is_lang_included);
}

bool _language_tagging_form_apply()
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
   flag := VSCODEHELPFLAG_NULL;

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
   case 'ctlinsertparamkeyword':
      flag = VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlnavigation':
      newFlags = codehelpFlags & ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION | VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
      if (value == TAG_NAVIGATION_PREFER_DEFINITION) {
         newFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
      } else if (value == TAG_NAVIGATION_PREFER_DECLARATION) {
         newFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
      }
      break;
   case 'ctlnavchoices':
      newFlags = codehelpFlags & ~(VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE | VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT);
      if (value == TAG_NAVIGATION_ONLY_WORKSPACE) {
         newFlags |= VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE;
      } else if (value == TAG_NAVIGATION_ONLY_PROJECT) {
         newFlags |= VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT;
      }
      break;
   case 'ctlpreferproject':
      flag = VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT;
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
   case 'ctlfindoverriddenmethods':
      flag = VSCODEHELPFLAG_FIND_NO_DERIVED_VIRTUAL_OVERRIDES;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlmouseoverinfo':
      flag = VSCODEHELPFLAG_MOUSE_OVER_INFO;
      break;
   case 'ctldispmembercomment':
      flag = VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS;
      break;
   case 'ctldispreturntype':
      flag = VSCODEHELPFLAG_DISPLAY_RETURN_TYPE;
      break;
   case 'ctlpreviewinfo':
      flag = VSCODEHELPFLAG_NO_PREVIEW_INFO;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlpreviewcomment':
      flag = VSCODEHELPFLAG_PREVIEW_NO_COMMENTS;
      turnFlagOn = !turnFlagOn;
      break;
   case 'ctlpreviewreturntype':
      flag = VSCODEHELPFLAG_PREVIEW_RETURN_TYPE;
      break;
   case 'ctlhighlighttag':
      flag = VSCODEHELPFLAG_HIGHLIGHT_TAGS;
      break;
   case 'ctlshowstatements':
      flag = VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS;
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

      // update the Defs tool window if something changed here
      if (((codehelpFlags & flag) != 0) != (turnFlagOn)) {
         _reset_defs_tool_window_options(langId);
      }
   }
}


void _language_tagging_form.on_destroy()
{
   _language_form_on_destroy();
}

void ctlautofunctionhelp.lbutton_up()
{
   en := ((p_value)!=0 && p_enabled);
   ctlautoinsertparam.p_enabled = en;
   ctlspaceaftercomma.p_enabled = en;
   ctlinsertparamkeyword.p_enabled = en;
   ctlspaceafterparen.p_enabled = en;
}

void _link_auto_complete_config.lbutton_up()
{
   showOptionsForLangId(_get_language_form_lang_id(), 'Auto-Complete');
}

void ctlmouseoverinfo.lbutton_up()
{
   ctldispmembercomment.p_enabled = (ctlmouseoverinfo.p_value != 0);
   if (_language_tagging_form_is_lang_included("ctldispreturntype", _get_language_form_lang_id())) {
      ctldispreturntype.p_enabled = (ctlmouseoverinfo.p_value != 0);
   }
}

void ctlpreviewinfo.lbutton_up()
{
   ctlpreviewcomment.p_enabled = (ctlpreviewinfo.p_value != 0);
   if (_language_tagging_form_is_lang_included("ctlpreviewreturntype", _get_language_form_lang_id())) {
      ctlpreviewreturntype.p_enabled = (ctlpreviewinfo.p_value != 0);
   }
}

#endregion Options Dialog Helper Functions (Language > Tag Files)


#region Options Dialog Helper Functions (Language > Adaptive Formatting)

defeventtab _language_adaptive_formatting_form;

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

bool _language_adaptive_formatting_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
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
 * @return bool               true if EXcluded, false if 
 *                            included
 */
bool isLangAdaptiveFormattingExcludedForMode(_str langId)
{
   return (adaptive_format_get_available_for_language(langId) == 0);
}


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

bool isModifiedAdaptiveFormattingOn(_str langId, int flag)
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

#endregion Options Dialog Helper Functions (Language > Adaptive Formatting)


#region Options Dialog Helper Functions (Language > View)

defeventtab _language_view_form;

static _str VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(...) {
   if (arg()) ctl_symbol_coloring.p_user=arg(1);
   return ctl_symbol_coloring.p_user;
}

static _str VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(...) {
   if (arg()) ctl_sel_disp_frame.p_user=arg(1);
   return ctl_sel_disp_frame.p_user;
}

void _language_view_form_init_for_options(_str langID)
{
   // load up our hex mode options
   _ctl_hex_combo._lbadd_item('None');
   _ctl_hex_combo._lbadd_item('Hex');
   _ctl_hex_combo._lbadd_item('Line hex');
   
   _ctl_special_chars.p_style=PSCH_AUTO3STATEB;
   // check if ISPF is active - disable line numbers!
   //ctlframe2.p_enabled = _ctl_line_numbers.p_enabled = _ctl_auto_text.p_enabled = 
   //   ctllabel2.p_enabled = (def_keys != 'ispf-keys');
      
   if (langID == ALL_LANGUAGES_ID) {
      _modified_lines_link.p_visible = _current_line_link.p_visible = 
         _ctl_config_special_chars.p_visible = ctl_configure_symbol_coloring.p_visible = false;

      heightDiff := ctl_configure_symbol_coloring.p_height + 120;
      ctl_symbol_coloring.p_height -= heightDiff;

      combo_heightDiff:=_ctl_hex_combo.p_height+120;
      ctlhex_frame.p_y -= heightDiff;
      ctlhex_frame.p_height-=combo_heightDiff;

      // There's just no way that a user would want to configure every language to come up in
      // hex. This is dangerous.
      ctllabel1.p_visible=_ctl_hex_combo.p_visible=false;
   } else {
      // set up links to look right
      _modified_lines_link.p_mouse_pointer = MP_HAND;
      _current_line_link.p_mouse_pointer = MP_HAND;
   }

   if (_haveContextTagging()) {
      ctl_strict_symbols._lbadd_item("Use strict symbol lookups (full symbol analysis)");
      ctl_strict_symbols._lbadd_item("Use relaxed symbol lookups (symbol analysis with relaxed rules)");
      ctl_strict_symbols._lbadd_item("Use fast, simplistic symbol lookups (symbol name only)");
   } else {
      // no symbol coloring, hide it and move the other stuff
      ctl_symbol_coloring.p_visible = ctl_positional_keywords.p_visible = false;

      yDiff := _modified_lines.p_y - ctl_positional_keywords.p_y;
      _modified_lines.p_y -= yDiff;
      _modified_lines_link.p_y -= yDiff;
      _current_line.p_y -= yDiff;
      _current_line_link.p_y -= yDiff;
      _show_minimap.p_y -= yDiff;
      //ctllabel1.p_y -= yDiff;
      //_ctl_hex_combo.p_y -= yDiff;
      ctlhex_frame.p_y=ctl_symbol_coloring.p_y;
   }

   _language_form_init_for_options(langID, _language_view_form_get_value, _language_view_form_is_lang_included);

   if (ctl_symbol_coloring.p_visible && ctl_symbol_coloring.p_enabled) {
      ctl_symbol_coloring.call_event(ctl_symbol_coloring, LBUTTON_UP);
   }

   if (!_are_positional_keywords_supported(langID) && langID != ALL_LANGUAGES_ID) {
      ctl_positional_keywords.p_enabled = false;
   }

   if (!_are_statements_supported(langID)) {
      ctl_seldisp_statement_outline.p_enabled = false;
   }
}

_str _language_view_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_ctl_special_chars':
      specialChars := LanguageSettings.getShowTabs(langId);
      value = ((specialChars & SHOWSPECIALCHARS_ALL) == SHOWSPECIALCHARS_ALL) ? 1 : ((specialChars == 0) ? 0 : 2);
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
   case 'ctl_positional_keywords':
      keywords := LanguageSettings.getSymbolColoringOptions(langId);
      value = (keywords & SYMBOL_COLOR_POSITIONAL_KEYWORDS) ? 1 : 0;
      break;
   case '_current_line':
      currentLine := LanguageSettings.getColorFlags(langId);
      value = (currentLine & CLINE_COLOR_FLAG) ? 1 : 0;
      break;
   case '_modified_lines':
      modifiedLine := LanguageSettings.getColorFlags(langId);
      value = (modifiedLine & MODIFY_COLOR_FLAG) ? 1 : 0;
      break;
   case '_show_minimap':
      showMinimap := LanguageSettings.getShowMinimap(langId);
      value = showMinimap ? 1 : 0;
      break;
   case 'ctlhex_nofcols':
      value = LanguageSettings.getHexNofCols(langId);
      break;
   case 'ctlhex_bytes_per_col':
      value = LanguageSettings.getHexBytesPerCol(langId);
      break;
   case 'ctl_seldisp_symbol_outline':
   case 'ctl_seldisp_statement_outline':
   case 'ctl_seldisp_no_outline':
      flags := LanguageSettings.getSelectiveDisplayFlags(langId);
      if (flags & SELDISP_SYMBOL_OUTLINE_ON_OPEN) {
         value = 'ctl_seldisp_symbol_outline';
      } else if (flags & SELDISP_STATEMENT_OUTLINE_ON_OPEN) {
         value = 'ctl_seldisp_statement_outline';
      } else {
         value = 'ctl_seldisp_no_outline';
      }
      break;
   case 'ctl_seldisp_doc_comments':
      value = LanguageSettings.getSelectiveDisplayFlags(langId) & SELDISP_HIDE_DOC_COMMENTS_ON_OPEN;
      break;
   case 'ctl_seldisp_other_comments':
      value = LanguageSettings.getSelectiveDisplayFlags(langId) & SELDISP_HIDE_OTHER_COMMENTS_ON_OPEN;
      break;
   }

   return value;
}

bool _language_view_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
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

bool _language_view_form_validate(int action)
{
   langID := _get_language_form_lang_id();

   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {
      if (!validateLangIntTextBox(_ctl_auto_text.p_window_id)) {
         return false;
      }

      if (!validateLangIntTextBox(ctlhex_nofcols.p_window_id,1)) {
         return false;
      }
      if (!validateLangIntTextBox(ctlhex_bytes_per_col.p_window_id,1)) {
         return false;
      }
      typeless HexNofcols=ctlhex_nofcols.p_text;
      typeless HexBytesPerCol=ctlhex_bytes_per_col.p_text;
      if (isinteger(HexNofcols) && isinteger(HexBytesPerCol)) {
         int NofbytesPerLine=HexNofcols*HexBytesPerCol;
         int HexAsciiOffset=HexNofcols*(HexBytesPerCol*2+1);
         int requiredlinelen=HexAsciiOffset+NofbytesPerLine;

         if (requiredlinelen>_default_option(VSOPTION_FORCE_WRAP_LINE_LEN)) {
            //Nofcols*(BytesPerCol*2+1)+ Nofcols*BytesPerCol
            ctlhex_nofcols._text_box_error("Line length created by settings for 'Number of columns' and 'Bytes per column' is too large (must be less than 'Wrap line length').\n\nPlease make them smaller");
            return false;
         }
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

bool _language_view_form_apply()
{
   VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(false);
   VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(false);

   _language_form_apply(_language_view_form_apply_control);

   if (VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED()) {
      if (def_symbol_color_profile != "" && def_symbol_color_profile != CONFIG_AUTOMATIC) {
         //Reinitialize symbol analyzers
         se.color.SymbolColorRuleBase rb;
         rb.loadProfile(def_symbol_color_profile);
         SymbolColorAnalyzer.initAllSymbolAnalyzers(&rb,true);
      }
   }

   if (VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED()) {
      langId := _get_language_form_lang_id();
      orig_window := p_window_id;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      orig_buf_id := p_buf_id;
      for (;;) {
         if (_LanguageInheritsFrom(langId, p_LangId)) {
            _SetBufferInfoHt("selective_display_file_time", -1);
         }
         _next_buffer('hr');
         if (p_buf_id == orig_buf_id) {
            break;
         }
      }
      activate_window(orig_window);
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

      if ((int)value == 0) {
         newValue = (oldValue & ~SHOWSPECIALCHARS_ALL);
      } else if ((int)value == 1) {
         newValue = oldValue | SHOWSPECIALCHARS_ALL;
      } else {
         // tri-state, they'll get turned off in their own section
         newValue = oldValue;
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
         VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(true);
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_bold_symbols':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);

      if ((int)value) newValue = oldValue | SYMBOL_COLOR_BOLD_DEFINITIONS;
      else newValue = oldValue & ~SYMBOL_COLOR_BOLD_DEFINITIONS;

      if (oldValue != newValue) {
         VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(true);
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_symbol_errors':
      oldValue = LanguageSettings.getSymbolColoringOptions(langId);

      if (!(int)value) newValue = oldValue | SYMBOL_COLOR_SHOW_NO_ERRORS;
      else newValue = oldValue & ~SYMBOL_COLOR_SHOW_NO_ERRORS;
      if ((int)value) newValue |= SYMBOL_COLOR_PARSER_ERRORS;
      else newValue &= ~SYMBOL_COLOR_PARSER_ERRORS;

      if (oldValue != newValue) {
         VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(true);
         LanguageSettings.setSymbolColoringOptions(langId, newValue);
      }
      break;
   case 'ctl_positional_keywords':
      if (_are_positional_keywords_supported(langId) || langId==ALL_LANGUAGES_ID) {
         oldValue = LanguageSettings.getSymbolColoringOptions(langId);

         if ((int)value) newValue = oldValue | SYMBOL_COLOR_POSITIONAL_KEYWORDS;
         else newValue = oldValue & ~SYMBOL_COLOR_POSITIONAL_KEYWORDS;

         if (oldValue != newValue) {
            VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(true);
            LanguageSettings.setSymbolColoringOptions(langId, newValue);
         }
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
         VIEW_OPTIONS_SYMBOL_COLORING_MODIFIED(true);
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
   case '_show_minimap':
      oldValue = LanguageSettings.getShowMinimap(langId)?1:0;

      newValue=(int)value;
      if (oldValue != newValue) {
         updateKey = SHOW_MINIMAP_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setShowMinimap(langId, newValue?true:false);
      }
      break;
   case 'ctlhex_nofcols':
      oldValue = LanguageSettings.getHexNofCols(langId);

      newValue=(int)value;
      if (oldValue != newValue) {
         updateKey = HEX_NOFCOLS_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setHexNofCols(langId, newValue);
      }
      break;
   case 'ctlhex_bytes_per_col':
      oldValue = LanguageSettings.getHexBytesPerCol(langId);

      newValue=(int)value;
      if (oldValue != newValue) {
         updateKey = HEX_BYTES_PER_COL_UPDATE_KEY;
         updateValue = newValue;

         LanguageSettings.setHexBytesPerCol(langId, newValue);
      }
      break;
   case 'ctl_seldisp_symbol_outline':
      oldValue = LanguageSettings.getSelectiveDisplayFlags(langId);
      newValue = oldValue & ~SELDISP_STATEMENT_OUTLINE_ON_OPEN;
      newValue |= SELDISP_SYMBOL_OUTLINE_ON_OPEN;
      if (oldValue != newValue) {
         VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(true);
         LanguageSettings.setSelectiveDisplayFlags(langId, newValue);
      }
      break;
   case 'ctl_seldisp_statement_outline':
      oldValue = LanguageSettings.getSelectiveDisplayFlags(langId);
      newValue = oldValue & ~SELDISP_SYMBOL_OUTLINE_ON_OPEN;
      newValue |= SELDISP_STATEMENT_OUTLINE_ON_OPEN;
      if (oldValue != newValue) {
         VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(true);
         LanguageSettings.setSelectiveDisplayFlags(langId, newValue);
      }
      break;
   case 'ctl_seldisp_no_outline':
      oldValue = LanguageSettings.getSelectiveDisplayFlags(langId);
      newValue = oldValue & ~(SELDISP_SYMBOL_OUTLINE_ON_OPEN | SELDISP_STATEMENT_OUTLINE_ON_OPEN);
      if (oldValue != newValue) {
         VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(true);
         LanguageSettings.setSelectiveDisplayFlags(langId, newValue);
      }
      break;
   case 'ctl_seldisp_doc_comments':
      oldValue = LanguageSettings.getSelectiveDisplayFlags(langId);
      if ((int)value) newValue = oldValue | SELDISP_HIDE_DOC_COMMENTS_ON_OPEN;
      else newValue = oldValue & ~SELDISP_HIDE_DOC_COMMENTS_ON_OPEN;
      if (oldValue != newValue) {
         VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(true);
         LanguageSettings.setSelectiveDisplayFlags(langId, newValue);
      }
      break;
   case 'ctl_seldisp_other_comments':
      oldValue = LanguageSettings.getSelectiveDisplayFlags(langId);
      if ((int)value) newValue = oldValue | SELDISP_HIDE_OTHER_COMMENTS_ON_OPEN;
      else newValue = oldValue & ~SELDISP_HIDE_OTHER_COMMENTS_ON_OPEN;
      if (oldValue != newValue) {
         VIEW_OPTIONS_SELECTIVE_DISPLAY_MODIFIED(true);
         LanguageSettings.setSelectiveDisplayFlags(langId, newValue);
      }
      break;
   }

   return updateKey' 'updateValue;
}


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
   if (_ctl_special_chars.p_value == 2) {
      _ctl_special_chars.p_value = 0;
   }
   _ctl_tabs.p_value = _ctl_spaces.p_value = _ctl_newline.p_value = _ctl_ctrl_chars.p_value = _ctl_special_chars.p_value;
}

static void _ctl_special_chars_update()
{
   if (_ctl_tabs.p_value && _ctl_spaces.p_value && _ctl_newline.p_value && _ctl_ctrl_chars.p_value) _ctl_special_chars.p_value = 1;
   else if (_ctl_tabs.p_value || _ctl_spaces.p_value || _ctl_newline.p_value || _ctl_ctrl_chars.p_value) _ctl_special_chars.p_value = 2;
   else _ctl_special_chars.p_value = 0;
}

// All the individual special characters checkboxes come here.
_ctl_tabs.lbutton_up()
{
   _ctl_special_chars_update();
}

void _modified_lines_link.lbutton_up()
{
   config('Colors', 'N', CFG_MODIFIED_LINE);
}

void _current_line_link.lbutton_up()
{
   config('Colors', 'N', CFG_CLINE);
}

#endregion Options Dialog Helper Functions (Language > View)


#region Options Dialog Helper Functions (Language > Formatting)

defeventtab _language_formatting_form;

void _language_formatting_form_init_for_options(_str langId)
{
   if (langId == ALL_LANGUAGES_ID) {
      _indent_with_tabs_ad_form_link.p_visible = false;
      _indent_ad_form_link.p_visible = false;
      _tabs_ad_form_link.p_visible = false;

      // we want to get rid of these for beta 2, for now, just hide them
      _no_space.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
//    ctl_XW_autoSymbolTrans_check.p_visible = false;
      ctlUseContOnParameters.p_visible = false;
      _indent_case.p_visible = false;

      _ctl_frame_tag_case.p_visible = false;
      _ctl_frame_attrib_case.p_visible = false;
      _ctl_frame_word_value_case.p_visible = false;
      _ctl_frame_hex_value_case.p_visible = false;

      ctl_XW_autoSymbolTrans_check.p_y = _ctl_frame_tag_case.p_y; //ctlUseContOnParameters.p_y;
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
         //_ctl_frame_auto_format.p_visible = false;
         ctl_XW_autoSymbolTrans_check.p_visible = false;
         _ctl_frame_keyword_case.p_visible = false;
         ctlUseContOnParameters.p_visible = false;
         _indent_case.p_visible = false;
      }
   }

   if (_find_control('_ctl_brace_style')) {
      // add our brace style options
      _ctl_brace_style._lbadd_item(CBV_SAMELINE);
      _ctl_brace_style._lbadd_item(CBV_NEXTLINE);
      _ctl_brace_style._lbadd_item(CBV_NEXTLINE_IN);
   }

   if (_find_control('_brace_style_example')) {
      _brace_style_example._use_source_window_font();
   }

   _language_form_init_for_options(langId, _language_formatting_form_get_value, _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting 
   // info - this will set them if they are present
   setAdaptiveLinks(langId);

   PROMPT_TABS_DIFFER(1);      // Signifies user was asked once if Syntax Indent differs from tabs
}

_str _language_formatting_form_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
      case '_ctl_brace_style':
         braceStyle := LanguageSettings.getBeginEndStyle(langId);
         switch(braceStyle) {
         case BES_BEGIN_END_STYLE_1:
            value = CBV_SAMELINE;
            break;
         case BES_BEGIN_END_STYLE_2:
            value = CBV_NEXTLINE;
            break;
         case BES_BEGIN_END_STYLE_3:
            value = CBV_NEXTLINE_IN;
            break;
         }
      break;
   case '_style0':
   case '_style1':
   case '_style2':
      style := LanguageSettings.getBeginEndStyle(langId);
      value = '_style'style;
      break;
   case '_no_space':
      value = (int)LanguageSettings.getNoSpaceBeforeParen(langId);
      break;
   case '_has_space':
       // It's "no-space-before-paren" but worded differently.
       value = !(int)LanguageSettings.getNoSpaceBeforeParen(langId);
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
   //case 'XW_selectSchemeDB':
   //   value = _GetXMLWrapFlags(XW_DEFAULT_SCHEME, langId);
   //   break;
   case 'XW_clt_CWcurrentDoc':
      value = 0; //_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, langId);
      break;
   case 'XW_clt_TLcurrentDoc':
      value = 0; //_GetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, langId);
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

bool _language_formatting_form_is_lang_included(_str controlName, _str langId, bool allLangsExclusion)
{
   included := true;

   optionFlag := -1;

   switch (controlName) {
   case '_style0':
   case '_style1':
   case '_style2':
   case '_ctl_brace_style':
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
   //case '_ctl_frame_auto_format':
   //   included = XW_isSupportedLanguage(langId);
   //   break;
   case '_ctl_frame_keyword_case':
      optionFlag = LOI_KEYWORD_CASE;
      break;
   case '_tabs':
   case '_indent_with_tabs':
      // only exclude for all languages, do not disable the controls
      included = (!allLangsExclusion || !isLangExcludedFromLangTabs(langId));
      break;
   case '_insmart':
   case '_insmart_spinner':
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

bool _language_formatting_form_is_modified()
{
   return _language_form_is_modified();
}

bool _language_formatting_form_validate(int action)
{
   langID := _get_language_form_lang_id();
   if (langID == ALL_LANGUAGES_ID || action == OPTIONS_APPLYING) {

      // verify auto syntax indent
      if (!validateLangIntTextBox(_insmart.p_window_id, 0, null, "Syntax indent must be 0 or greater.")) {
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
      if ((tab_distance != _insmart.p_text) && !PROMPT_TABS_DIFFER() && _insmart.p_enabled){
         PROMPT_TABS_DIFFER(1);//Signifies user was asked once
         result = _message_box("You have selected tab stops which differ from the Syntax indent amount.\n\nAre you sure this is what you want?",
                               '',
                               MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result == IDCANCEL||result == IDNO) {
            PROMPT_TABS_DIFFER(0);

            /*The Changing of PROMPT_TABS_DIFFER() is not really necessary in this case
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

bool _language_formatting_form_apply()
{
   _language_form_apply(_language_formatting_form_apply_control);

   return true;
}

_str _language_formatting_form_apply_control(_str controlName, _str langId, _str value,bool isForAllLangIds=false)
{
   updateKey := '';
   updateValue := '';

   switch (controlName) {
   case '_ctl_brace_style':
      switch (value) {
      case CBV_SAMELINE:
         updateValue = BES_BEGIN_END_STYLE_1;
         break;
      case CBV_NEXTLINE:
         updateValue = BES_BEGIN_END_STYLE_2;
         break;
      case CBV_NEXTLINE_IN:
         updateValue = BES_BEGIN_END_STYLE_3;
         break;
      }
      LanguageSettings.setBeginEndStyle(langId, (int)updateValue);
      updateKey = BEGIN_END_STYLE_UPDATE_KEY;
      break;
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
   case '_has_space':
      LanguageSettings.setNoSpaceBeforeParen(langId, ((int)value == 0));

      updateKey = NO_SPACE_BEFORE_PAREN_UPDATE_KEY;
      updateValue = !value;
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
      LanguageSettings.setUseContinuationIndentOnFunctionParameters(langId, (int)value);
      break;
   case '_indent_case':
      LanguageSettings.setIndentCaseFromSwitch(langId, ((int)value != 0));

      updateKey = INDENT_CASE_FROM_SWITCH_UPDATE_KEY;
      updateValue = value;
      break;
   case 'ctl_XW_autoSymbolTrans_check':
      LanguageSettings.setAutoSymbolTranslation(langId, ((int)value != 0));
      break;
   //case 'XW_selectSchemeDB':
   //   _SetXMLWrapFlags(XW_DEFAULT_SCHEME, value, langId);
   //  break;
   //case 'XW_clt_CWcurrentDoc':
   //   _SetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, value, langId);
   //   break;
   //case 'XW_clt_TLcurrentDoc':
   //   _SetXMLWrapFlags(XW_ENABLE_TAGLAYOUT, value, langId);
   //   break;
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

      if (  (isForAllLangIds && !isLangExcludedFromAllLangsTabs(langId))
           || (!isForAllLangIds)
          
         ) {
          LanguageSettings.setTabs(langId, value);
      }
      break;
   case '_indent_with_tabs':
      updateKey = INDENT_WITH_TABS_UPDATE_KEY;
      updateValue = value;

      if ( (isForAllLangIds && !isLangExcludedFromAllLangsIndentWithTabs(langId))
           || (!isForAllLangIds)
         ) {
          LanguageSettings.setIndentWithTabs(langId, value != 0);
      }
      break;
   case '_insmart':
      updateKey = SYNTAX_INDENT_UPDATE_KEY;
      updateValue = value;
      if ( (isForAllLangIds && !isLangExcludedFromAllLangsSyntaxIndent(langId))
           || (!isForAllLangIds && _is_syntax_indent_supported(langId))
         ) {
          LanguageSettings.setSyntaxIndent(langId, (int)value);
      }
      break;
   }

   return updateKey' 'updateValue;
}

void _language_formatting_form.on_destroy()
{
   _language_form_on_destroy();
}

_insmart.on_change()
{
   PROMPT_TABS_DIFFER(0);//Signifies user was not yet asked if Syntax Indent
                  //differs from tabs
}


// This should work for any adaptive formatting link
void _ad_form_link.lbutton_up()
{
   showAdaptiveFormattingOptionsForLanguage();
}

void _tabs.on_change()
{
   PROMPT_TABS_DIFFER(0);//Signifies user was not yet asked if Syntax Indent
                  //differs from tabs
}

/**
 * Comment matching function. 
 * @see _common_comment_maybe_update_lexer 
 */
typedef bool (*CommentMatchFn)(COMMENT_TYPE*, _str, _str);


bool _line_comment_match(COMMENT_TYPE* ty, _str delim1, _str delim2) 
{
   return ty->delim1 :== delim1;
}

bool _block_comment_match(COMMENT_TYPE* ty, _str delim1, _str delim2)
{
   return ty->delim1 :== delim1 && ty->delim2 :== delim2;
}

#endregion Options Dialog Helper Functions (Language > Formatting)

