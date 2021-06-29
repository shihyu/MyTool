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
#include "color.sh"
#include "tagsdb.sh"
#import "c.e"
#import "complete.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "ini.e"
#import "last.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "picture.e"
#import "recmacro.e"
#import "savecfg.e"
#import "cfg.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "xml.e"
#import "xmldoc.e"
#import "c.e"
#import "cfcthelp.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

static const NO_LEXER=     '(None)';

static const USE_SCHEMA_KEY=        'UseSchema';
static const CASE_SENSITIVE_KEY=    'CaseSensitive';
static const LEXER_NAME_KEY=        'Lexer';
static const CUR_LANG_KEY=          'currentLangId';


enum_flags CLEX_MATCH_NUMBER {
    CLEXMN_NONE =0,
    // match_number,match_dot_number flags
    CLEXMN_DIGIT_INT        =0x00004,  // Match integer starting with digi8t
    CLEXMN_DIGIT_FLOAT      =0x00008,  // Match integer or float starting with digit
    CLEXMN_DOT_FLOAT        =0x00010,  // Match float starting with decimal point
    CLEXMN_ZEROX_P_FLOAT    =0x00020,  // Allow 0x1f.f2p4
    CLEXMN_D_EXPONENT       =0x00040,  // 1.2D4 (Fortran)
    CLEXMN_DOTE_FLOAT       =0x00080,  // Allow 1.e4
    CLEXMN_DOTP_FLOAT       =0x00100,  // Allow 1.p4
    //CLEXMN_TRAILING_DOT_FLOAT =0x00200,  // Allow 1.  (maybe add support for this later)
    CLEXMN_VERILOG_BASE_SQUOTE_HEX =0x00400,  // 16'H5A0F 16'B0101 16'O777 16'D9100
    CLEXMN_NO_EXPONENT      =0x00800,  // Don't allow 1.2e4 but allow 1.2 if DOT_FLOAT or DIGIT_FLOAT specified
    CLEXMN_ALLOW_HEX_DIGITS =0x01000,  // 1AFFH (Modula-2 and Asm)
    CLEXMN_ZEROX_HEX        =0x02000,  // 0xHHHH
    CLEXMN_ZEROO_OCTAL      =0x04000,  // 0oOOOO
    CLEXMN_ZEROB_BINARY     =0x08000,  // 0bBBBB
    CLEXMN_ZEROD_DECIMAL    =0x10000,  // 0dDDDD
    CLEXMN_COLOR_LEADING_SIGN  =0x20000,  // Color sign as part of number '+123'
};
struct CLEX_TAGDEF_TYPE {
   _str comment_keywords;
   _str comment_attributes:[];//3:02pm 1/6/1998 For xml/html embedded languages
   _str comment_values:[];    //12:14pm 8/14/2001 for xml/html languages
};

struct CLEXDEF {
   bool case_sensitive;
   _str idchars;
   _str styles;
   CLEX_MATCH_NUMBER mn_flags;
   _str mn_int_suffixes;
   _str mn_float_suffixes;
   _str mn_hex_suffixes;
   _str mn_digit_separator_char;
   _str inherit;
   int ignore_text_after_start_col;
   bool jinja_enabled;
   _str jinja_block_start_string;
   _str jinja_block_end_string;
   _str jinja_variable_start_string;
   _str jinja_variable_end_string;
   _str jinja_comment_start_string;
   _str jinja_comment_end_string;
   _str jinja_line_statement_prefix;
   _str jinja_line_comment_prefix;
   COMMENT_TYPE comments[];
   CLEX_TAGDEF_TYPE tagdef:[];
};
static bool _clex_jinja_is_defaults(CLEXDEF &clexdef) {
   return clexdef.jinja_enabled==false && 
      clexdef.jinja_block_start_string=='{%'&&
      clexdef.jinja_block_end_string=='%}'&&
      clexdef.jinja_variable_start_string=='{{'&&
      clexdef.jinja_variable_end_string=='}}'&&
      clexdef.jinja_comment_start_string=='{#'&&
      clexdef.jinja_comment_end_string=='#}'&&
      clexdef.jinja_line_statement_prefix=='' &&
      clexdef.jinja_line_comment_prefix=='';
}
void _clex_init(CLEXDEF &clexdef) {
   clexdef.case_sensitive=false;
   clexdef.idchars='';
   clexdef.styles='';
   clexdef.mn_flags=CLEXMN_NONE;
   clexdef.mn_int_suffixes='';
   clexdef.mn_float_suffixes='';
   clexdef.mn_hex_suffixes='';
   clexdef.mn_digit_separator_char='';
   clexdef.inherit='';
   clexdef.ignore_text_after_start_col=0;


   clexdef.jinja_enabled=false;
   clexdef.jinja_block_start_string='{%';
   clexdef.jinja_block_end_string='%}';
   clexdef.jinja_variable_start_string='{{';
   clexdef.jinja_variable_end_string='}}';
   clexdef.jinja_comment_start_string='{#';
   clexdef.jinja_comment_end_string='#}';
   clexdef.jinja_line_statement_prefix=''; //'#';
   clexdef.jinja_line_comment_prefix='';//'##';

   clexdef.comments._makeempty();
   clexdef.tagdef._makeempty();
}
static void _clex_init_tagdef(CLEX_TAGDEF_TYPE *ptd) {
   ptd->comment_keywords='';
   ptd->comment_attributes._makeempty();
   ptd->comment_values._makeempty();
}

/**
 * Adds a new blank lexer with the given name to the user's 
 * color coding file. 
 * 
 * @param lexer      name for lexer
 */
void addNewBlankLexer(_str lexer) 
{
   CLEXDEF clexdef;
   _clex_init(clexdef);
   clexdef.idchars='a-zA-Z_$ 0-9';
   clexdef.case_sensitive=false;
   // Assume this is a programming language which supports integers and typical floating point.
   clexdef.mn_flags=CLEXMN_DIGIT_INT|CLEXMN_DIGIT_FLOAT|CLEXMN_DOT_FLOAT;
   _clex_save_profile(lexer,clexdef);
}

/**
 * Copies a lexer.
 *  
 * @param srcLexer      name of source lexer
 * @param destLexer     name of destination lexer.
 * 
 * @return              whether lexer copy was successful
 */
bool copyLexer(_str srcLexer, _str destLexer)
{
   _plugin_copy_profile(VSCFGPACKAGE_COLORCODING_PROFILES,srcLexer,destLexer);
   return true;
}


#region Options Dialog Helper Functions

defeventtab _cc_form;

static typeless OTHER_STYLES_TABLE(...){
   if (arg()) ctlzerox_hex.p_user=arg(1);
   return ctlzerox_hex.p_user;
}
static int IN_LEXER_LIST_ON_CHANGE(...) {
   if (arg()) _ctlcolors.p_user=arg(1);
   return _ctlcolors.p_user;
}
static int DONT_UPDATE_LIST(...){
   if (arg()) ctladd_other.p_user=arg(1);
   return ctladd_other.p_user;
}
static const MODIFIED_LEXER_HASHTAB= 'mod_lexer_ht';
static _str LAST_LEXER_NAME(...) {
   if (arg()) _ctllexer_list.p_user=arg(1);
   return _ctllexer_list.p_user;
}
static const DELETE_LEXER_HASHTAB='del_lexer_ht';
static _str CUR_TAG_NAME(...) {
   if (arg()) _ctlattr_list.p_user=arg(1);
   return _ctlattr_list.p_user;
}
static int IGNORE_TAG_LIST_ON_CHANGE(...) {
   if (arg()) _ctltag_list.p_user=arg(1);
   return  _ctltag_list.p_user;
}
static _str CUR_ATTR_NAME(...) {
   if (arg()) _ctlnew_attr.p_user=arg(1);
   return _ctlnew_attr.p_user;
}
static _str CUR_ATTR_VALUES(...) {
   if (arg()) _ctlnew_value.p_user=arg(1);
   return _ctlnew_value.p_user;
}
static _str ERROR_ON_LEXER_NAME_CHANGE(...) {
   if (arg()) _ctlnew_tag.p_user=arg(1);
   return _ctlnew_tag.p_user;
}
static int ORIG_FORM_HEIGHT(...) {
   if (arg()) ctladd_words.p_user=arg(1);
   return ctladd_words.p_user;
}
static int ORIG_CTLSSTAB_HEIGHT(...) {
   if (arg()) ctlsstab.p_user=arg(1);
   return ctlsstab.p_user;
}
static int ORIG_CTLSSTAB_Y(...) {
   if (arg()) ctltype.p_user=arg(1);
   return ctltype.p_user;
}
static int ORIG_CTLSSTAB2_Y(...) {
   if (arg()) ctlsstab2.p_user=arg(1);
   return ctlsstab2.p_user;
}
static int ORIG_CTLIMPORT_Y(...) {
   if (arg()) _ctlimport.p_user=arg(1);
   return _ctlimport.p_user;
}
static int ORIG_CTLTREE1_HEIGHT(...) {
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user;
}

static const CLEXTAB_GENERAL=  0;
static const CLEXTAB_TOKENS=   1;
     static const CLEXTAB_TOKENS_SETTINGS=   0;
     static const CLEXTAB_TOKENS_MORE=       1;
     static const CLEXTAB_TOKENS_EMBEDDED=   2;
static const CLEXTAB_NUMBERS=  2;
static const CLEXTAB_LANGUAGE= 3;
static const CLEXTAB_TAGS=     4;

static int refresh_lexer_list = 0;

static CLEXDEF gnew_keyword_table:[];

_str unsaved_lexer_language_table:[];

void _cc_form.on_resize() {
   // I'm not sure what code is change ctlsstab.p_y as well as other controls.
   // Adjust for it here.
   int diff1=ctlsstab.p_y-ORIG_CTLSSTAB_Y();
   if (diff1<0) {
      diff1=0;
   }

   int diff=p_active_form.p_height-ORIG_FORM_HEIGHT()-diff1;
   if (diff<0) diff=0;
   diff=_ly2dy(SM_TWIP,diff);
   diff=_dy2ly(SM_TWIP,diff);
   
   ctlsstab.p_height=ORIG_CTLSSTAB_HEIGHT()+diff;
   ctltree1.p_height=ORIG_CTLTREE1_HEIGHT()+diff;
   ctlsstab2.p_y=ORIG_CTLSSTAB2_Y()+diff;
   //_ctlimport.p_y=_ctlcolors.p_y=ORIG_CTLIMPORT_Y()+diff+diff1;
   resizeTagsTab();

}
void set_refresh_lexer_list()
{
   refresh_lexer_list = 1;
}

void maybe_refresh_lexer_list()
{
   // we don't even need to do this
   if (!refresh_lexer_list) return;

   // get all the user lexers
   _str lexers[];
   _plugin_list_profiles(VSCFGPACKAGE_COLORCODING_PROFILES,lexers);

   for (i := 0; i < lexers._length(); i++) {
      lexer := lexers[i];
      // see if this lexer is in our list box
      if (_ctllexer_list._lbfind_item(lexer) < 0) {
         // no?  maybe it has been deleted!
         if (!_GetDialogInfoHtPtr(DELETE_LEXER_HASHTAB)->_indexin(lowcase(lexer)) || _plugin_has_builtin_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexer)) {
            // we best add it then
            _ctllexer_list._lbadd_item(lexer);
         }
      }
   }

   // i feel refreshed
   refresh_lexer_list = 0;
}

void clear_unsaved_lexer_info_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId :+ CASE_SENSITIVE_KEY)) {
      unsaved_lexer_language_table._deleteel(langId :+ CASE_SENSITIVE_KEY);
   } 
   if (unsaved_lexer_language_table._indexin(langId :+ USE_SCHEMA_KEY)) {
      unsaved_lexer_language_table._deleteel(langId :+ USE_SCHEMA_KEY);
   }
   if (unsaved_lexer_language_table._indexin(langId :+ LEXER_NAME_KEY)) {
      unsaved_lexer_language_table._deleteel(langId :+ LEXER_NAME_KEY);
   } 
}

_str get_unsaved_lexer_case_sensitivity_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId :+ CASE_SENSITIVE_KEY)) {
      // now look up the value in the gnew_keyword_table
      return unsaved_lexer_language_table:[langId :+ CASE_SENSITIVE_KEY];
   } 

   return '';
}

_str get_unsaved_lexer_name_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId :+ LEXER_NAME_KEY)) {
      // now look up the value in the gnew_keyword_table
      return unsaved_lexer_language_table:[langId :+ LEXER_NAME_KEY];
   } 

   return '';
}

void _cc_form_init_for_options(_str langId)
{
   _ctlok.p_visible = false;
   _ctlcancel.p_visible = false;
   _ctlhelp.p_visible = false;

   // set the proper lexer to display
   lexer_name := LanguageSettings.getLexerName(langId);

   _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);

   // save the current lang id
   unsaved_lexer_language_table:[CUR_LANG_KEY] = langId;

   setUseSchemaValue(langId);
}

static void setUseSchemaValue(_str langId) {
   // this is actually a language setting hiding on the lexer page
   ctluseschema.p_enabled = _LanguageInheritsFrom('xml', langId);
   if (ctluseschema.p_enabled) {

      if (unsaved_lexer_language_table._indexin(langId :+ USE_SCHEMA_KEY)) {
         ctluseschema.p_value = (int)unsaved_lexer_language_table:[langId :+ USE_SCHEMA_KEY];
      } else {
         ctluseschema.p_value = (int)use_schema_for_color_coding(langId);
      }
   } else {
      ctluseschema.p_value = 0;
   }
}

bool _cc_form_validate()
{
   // save the settings from this version of the lexer options - we do this
   // in validate so that we have the chance to cancel the switch to another
   // options node if necessary

   curLangId := unsaved_lexer_language_table:[CUR_LANG_KEY];
   if (curLangId != null) {
      unsaved_lexer_language_table:[curLangId :+ LEXER_NAME_KEY] = _ctllexer_list.p_text;
      unsaved_lexer_language_table:[curLangId :+ CASE_SENSITIVE_KEY] = ctlcase_sensitive.p_value;

      if (ctluseschema.p_enabled && (ctluseschema.p_value != (int)use_schema_for_color_coding(curLangId))) {
         unsaved_lexer_language_table:[curLangId :+ USE_SCHEMA_KEY] = ctluseschema.p_value;
      }
   }
   if (save_last_settings()) return false;

   // everything checked out fine
   return true;
}

void _cc_form_restore_state(_str langId)
{
   // we might have to refresh the list, if something has been added
   maybe_refresh_lexer_list();

   // see if we've already looked at this language and saved this info
   if (unsaved_lexer_language_table._indexin(langId :+ LEXER_NAME_KEY)) {
      lexer_name := unsaved_lexer_language_table:[langId :+ LEXER_NAME_KEY];
      if (lexer_name != _ctllexer_list._lbget_text()) {
         _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);
      }


   } else {
      // we haven't looked at this one yet.  look at it now!
      lexer_name := LanguageSettings.getLexerName(langId);
      unsaved_lexer_language_table:[langId] = lexer_name;

      _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);
   }

   setUseSchemaValue(langId);
   unsaved_lexer_language_table:[CUR_LANG_KEY] = langId;
}

bool _cc_form_is_modified() {
   save_last_settings();
   //if (save_last_settings()) return false;
   // see if current lexer for this language was modified
   langId := unsaved_lexer_language_table:[CUR_LANG_KEY];

   if (unsaved_lexer_language_table._indexin(langId :+ USE_SCHEMA_KEY)) {
      //say('modified schema');
      return true;
   }

   lexer := LanguageSettings.getLexerName(langId);
   if (stricmp(lexer, _ctllexer_list.p_text) && !(lexer == '' && _ctllexer_list.p_text == NO_LEXER)) {
      //say('changed lexer');
      return true;
   }

   if (_GetDialogInfoHtPtr(DELETE_LEXER_HASHTAB)->_varformat() == VF_HASHTAB) {
      //say('deleted lexer');
      return true;
   }
   /*if (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat() == VF_HASHTAB && _GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_indexin(_ctllexer_list.p_text)) {
      say('modified lexer='_ctllexer_list.p_text);
   } */

   return (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat() == VF_HASHTAB && _GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_indexin(_ctllexer_list.p_text));
}

bool _cc_form_apply()
{
   if (!DONT_UPDATE_LIST()) {
      if(save_last_settings()) {
         return false;
      }
   }

   mou_hour_glass(true);
   orig_view_id := p_window_id;
   status := 0;
   filename := "";
   cur := "";
   typeless ptr;
   typeless temp;
   typeless hashindex;
   for (hashindex._makeempty();;) {
      ptr=&gnew_keyword_table._nextel(hashindex);
      if (hashindex._isempty()) {
         break;
      }
      _str lexername=hashindex;
      if (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat()!=VF_HASHTAB || !_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_indexin(lexername)) {
         continue;
      }
      _clex_save_profile(lexername,gnew_keyword_table:[lexername]);

      call_list('_lexer_updated_', lexername);
   }
   p_window_id=orig_view_id;//Paranoia
   delete_lexers(*_GetDialogInfoHtPtr(DELETE_LEXER_HASHTAB));
   *_GetDialogInfoHtPtr(DELETE_LEXER_HASHTAB)=null;
   _str profileNames[];
   _plugin_list_profiles(VSCFGPACKAGE_COLORCODING_PROFILES,profileNames);
   for (i:=0;i<profileNames._length();++i) {
      status=_clex_load(profileNames[i]);
      if (status) {
         _message_box(nls("Could not load file '%s'\n\n%s",profileNames[i],get_message(status)));
      }
   }

   // first things first - set each lexer to their langID
   _str key, value;
   foreach (key => value in unsaved_lexer_language_table) {

      // determine if this is a lexer key by checking for the word 'Lexer'
      strPos := pos(LEXER_NAME_KEY, key);
      if (strPos) {
         langId := substr(key, 1, strPos - 1);
         if (langId != '' && langId != '0') {
            // set the new lexer for the language
            if (value != null) {
               if (value==NO_LEXER) {
                  value='';
               }
               LanguageSettings.setLexerName(langId, value);

               // update the open buffers in this language
               _update_buffers(langId, LEXER_NAME_UPDATE_KEY'='value);
            }
         }
      } else {
         // no?  maybe a use schema value
         strPos = pos(USE_SCHEMA_KEY, key);
         if (strPos) {
            langId := substr(key, 1, strPos - 1);
            if (langId != '' && langId != '0') {
               if (value != null) {
                  use_schema_for_color_coding(langId, (value != '0'));
               }
            }
         }
      }
   }

   // clear out the hash table
   curId := unsaved_lexer_language_table:[CUR_LANG_KEY];
   unsaved_lexer_language_table._makeempty();
   unsaved_lexer_language_table:[CUR_LANG_KEY] = curId;

   _SetDialogInfoHt(MODIFIED_LEXER_HASHTAB,null);

   mou_hour_glass(false);

   return true;
}

void _cc_form_cancel()
{
   // clear out the hash table
   unsaved_lexer_language_table._makeempty();

   if (LAST_LEXER_NAME()!=null && LAST_LEXER_NAME()!='' && LAST_LEXER_NAME()!=NO_LEXER) {
      _str orig_styles=gnew_keyword_table:[LAST_LEXER_NAME()].styles;
      gnew_keyword_table:[LAST_LEXER_NAME()].styles=get_styles();
      if (!cc_styles_eq(gnew_keyword_table:[LAST_LEXER_NAME()].styles,orig_styles)) {
         AddLexerToModList();
      }
      CLEX_MATCH_NUMBER orig_mn_flags=gnew_keyword_table:[LAST_LEXER_NAME()].mn_flags;
      gnew_keyword_table:[LAST_LEXER_NAME()].styles=get_styles();
      if (gnew_keyword_table:[LAST_LEXER_NAME()].mn_flags!=orig_mn_flags) {
         AddLexerToModList();
      }
#if 0
      _str orig_styles=gnew_keyword_table:[LAST_LEXER_NAME()].styles;
      gnew_keyword_table:[LAST_LEXER_NAME()].styles=get_styles();
      if (!cc_styles_eq(gnew_keyword_table:[LAST_LEXER_NAME()].styles,orig_styles)) {
         AddLexerToModList();
      }
#endif
      cc_update_tags(false);
   }
}

_str _cc_form_export_settings(_str &file, _str &args, _str langID)
{
   error := '';
   
   // just set the args to be the lexer name for this langauge
   args = LanguageSettings.getLexerName(langID);
   if (args == null || args == '' || args == NO_LEXER) {
      // if it doesn't exist, we just ignore it
      args = NO_LEXER;
      return '';
   }
   _plugin_export_profile(file,VSCFGPACKAGE_COLORCODING_PROFILES,args,langID);
   return error;
}

_str _cc_form_import_settings(_str &file, _str &args, _str langID)
{
   error := '';
   
   if (args == '' || args == null) {
      args = NO_LEXER;
   }

   if (args == NO_LEXER) {
      // in that case, we don't care about the file, just set the lexer to null
      LanguageSettings.setLexerName(langID, '');
      return error;
   }
   LanguageSettings.setLexerName(langID, args);
   if (_file_eq(_get_extension(file),'vlx')) {
      cload(file,args);
      return '';
   }
   error=_plugin_import_profile(file,VSCFGPACKAGE_COLORCODING_PROFILES,langID);
   _clex_load(args);
   
   return error;
}

#endregion Options Dialog Helper Functions

#if 0
// Maybe this could be used for atttribute values.
// Right now, attribute values don't support spaces.
_str clex_parse_word(var line) {
   line=strip(line,'B');
   word := "";
   ch := substr(line,1,1);
   if (ch=='"') {
      end_quote := pos(ch,line,2);
      for (;;) {
         if (!end_quote) {
            end_quote=length(line);
            break;
         } else if (substr(line, end_quote-1, 1) == '\') {
            end_quote = pos(ch, line, end_quote+1);
         } else {
            break;
         }
      }
      
      word=substr(line,1,end_quote);
      line=strip(substr(line,end_quote+1),'B');
      return(word);
   }
   parse line with word line ;
   return(word);
}
#endif
_ctlok.on_create(_str lexer_name='', int initial_tab=-1) {
   IGNORE_TAG_LIST_ON_CHANGE(0);
   ORIG_FORM_HEIGHT( _dy2ly(SM_TWIP,_ly2dy(SM_TWIP,p_active_form.p_height)));
   ORIG_CTLSSTAB_HEIGHT(ctlsstab.p_height);
   ORIG_CTLSSTAB_Y(ctlsstab.p_y);
   ORIG_CTLSSTAB2_Y(ctlsstab2.p_y);
   ORIG_CTLIMPORT_Y(_ctlimport.p_y);
   ORIG_CTLTREE1_HEIGHT(ctltree1.p_height);
   // we don't need to refresh, we are starting anew!
   refresh_lexer_list = 0;

   col0Width := 2000;
   col1Width := 0;
   col2Width := 0;

   col0Width = 1500;
   col1Width = 1500;
   col2Width = 0;

   ctltree1._TreeSetColButtonInfo(0,col0Width,0 /*TREE_BUTTON_PUSHBUTTON*//*|TREE_BUTTON_SORT*/,0,"Type");
   ctltree1._TreeSetColButtonInfo(1,col1Width,0 /*TREE_BUTTON_PUSHBUTTON*//*|TREE_BUTTON_SORT*/,0,"Start");
   ctltree1._TreeSetColButtonInfo(2,col2Width,0 /*TREE_BUTTON_PUSHBUTTON*//*|TREE_BUTTON_SORT*/,0,"End");

   // restore the initial tab
   if (initial_tab>=0) {
      ctlsstab.p_ActiveTab=initial_tab;
   } else {
      ctlsstab._retrieve_value();
   }

   // clear out the table of unsaved lexers
   unsaved_lexer_language_table._makeempty();
   ctlstart_delim_search.cc_fill_search_combo();
   ctlend_delim_search.cc_fill_search_combo();
   ctltype.cc_fill_color_combo();
   ctlcolor_to_eol.cc_fill_color_combo(true);
   ctlend_color_to_eol.cc_fill_color_combo(true);
   ctlstart_color.cc_fill_color_combo(true);
   ctlend_color.cc_fill_color_combo(true);
   ctlmultiline._cc_fill_multiline_combo();
   ctlembedded_color_style._cc_fill_embedded_color_style_combo();

   ctlsstab.p_width=ctlsstab2.p_x*2+ctlsstab2.p_width;
   int border_width=p_active_form.p_width-_dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   p_active_form.p_width=ctlsstab.p_x_extent+ctlsstab.p_x+border_width;
   //CUR_COMMENT_INDEX=-1;

   // if we are coming from an mdi window, set the lexer to the current one
   int wid=_form_parent();
   if (lexer_name=="" && wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
      lexer_name=wid.p_lexer_name;
   }

   //gnew_keyword_table=_notinit;
   //This cannot be here because the function is re-entrant

   // add the lexers to the combo box
   _ctllexer_list.cc_fill_profile_names();
   ctlinherit_list.cc_fill_profile_names();
   ctlembedded_profile.cc_fill_profile_names();
   ctlembedded_profile._lbadd_item('');
   ctlembedded_profile._lbsort('i');


   // add any additional lexers from the keyword table - no need to search,
   // as we will remove duplicates later
   typeless status=0;
   if (gnew_keyword_table._varformat()!=VF_EMPTY) {
      typeless i;
      for (i._makeempty();;) {
         typeless ptr=&gnew_keyword_table._nextel(i);
         if (i._isempty()) break;
         _ctllexer_list._lbadd_item(i);
      }
   }


   _ctllexer_list._lbadd_item(NO_LEXER);
   _ctllexer_list._lbsort('i');
   _ctllexer_list._lbremove_duplicates();
   _ctllexer_list._lbtop();

   ctlinherit_list._lbadd_item(NO_LEXER);
   ctlinherit_list._lbsort('i');
   ctlinherit_list._lbremove_duplicates();
   ctlinherit_list._lbtop();


   _cc_form_initial_alignment();

   _SetDialogInfoHt(MODIFIED_LEXER_HASHTAB,null);
   _SetDialogInfoHt(DELETE_LEXER_HASHTAB,null);

   // select the lexer specified
   if (lexer_name!='' && lexer_name!='fundamental') {
      if (_ctllexer_list._lbfind_item(lexer_name) < 0) {
         // it's not in there, so add it
         AddNewLexer(lexer_name);
      }
   }

   _ctllexer_list._lbselect_line();
   DONT_UPDATE_LIST(0);
}

_ctlok.on_destroy()
{
   ctlsstab._append_retrieve(ctlsstab, ctlsstab.p_ActiveTab);
   gnew_keyword_table._makeempty();
   //show('-mdi _var_editor_form','',&gnew_keyword_table);
}


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _cc_form_initial_alignment()
{
}

static void resizeTagsTab()
{
   form_height := /*_dx2lx*/(/*SM_TWIP,*/ctlsstab.p_child.p_height);
   form_width  := /*_dx2lx*/(/*SM_TWIP,*/ctlsstab.p_child.p_width);
   margin_x := _ctltag_list.p_prev.p_x;
   margin_y := _ctltag_list.p_prev.p_y;

   // tag list
   alignControlsVertical(_ctltag_list.p_prev.p_x, _ctltag_list.p_prev.p_y, margin_y,
                         _ctltag_list.p_prev.p_window_id,
                         _ctltag_list.p_window_id);
   _ctltag_list.p_y_extent = form_height - margin_y;
   _ctltag_list.p_width  = (form_width intdiv 2) - _ctlnew_tag.p_width - 2*margin_y;
   alignUpDownListButtons(_ctltag_list, 0, _ctlnew_tag.p_window_id, _ctldelete_tag.p_window_id);

   // attributes
   _ctlattr_list.p_height = (form_height - 2*_ctltag_list.p_y - 2*margin_y) intdiv 2;
   _ctlattr_list.p_width  = _ctltag_list.p_width;
   alignControlsHorizontal(_ctlnew_tag.p_x, _ctlnew_tag.p_y, margin_x, 
                           _ctlnew_tag.p_window_id,
                           _ctlattr_list.p_window_id);
   _ctlattr_list.p_prev.p_x = _ctlattr_list.p_x;
   _ctlattr_list.p_prev.p_y = _ctltag_list.p_prev.p_y;
   alignUpDownListButtons(_ctlattr_list.p_window_id, 0, _ctlnew_attr.p_window_id, _ctldelete_attr.p_window_id);
   
   // values
   alignControlsVertical(_ctlattr_list.p_x,
                         _ctlattr_list.p_y_extent+margin_y,
                         margin_y,
                         _ctlvalue_list.p_prev.p_prev,
                         _ctlvalue_list.p_window_id);
   _ctlvalue_list.p_y_extent = form_height - margin_y;
   _ctlvalue_list.p_width  = _ctltag_list.p_width;
   ctlalltags.p_x = _ctlvalue_list.p_prev.p_prev.p_x + _ctlvalue_list.p_prev.p_prev.p_width+margin_x;
   ctlalltags.p_y = _ctlvalue_list.p_prev.p_prev.p_y;
   alignUpDownListButtons(_ctlvalue_list.p_window_id, 0, _ctlnew_value.p_window_id, _ctldelete_value.p_window_id);

}

static void cc_prepare_tags_tab()
{
   int orig_active=ctlsstab.p_ActiveTab;
   ctlsstab.p_ActiveTab=CLEXTAB_TAGS;
   ctlsstab.p_ActiveEnabled=((ctlhtml.p_value || ctlxml.p_value)? true:false);
   ctlsstab.p_ActiveTab=orig_active;
   if (!ctlhtml.p_value && !ctlxml.p_value && orig_active==CLEXTAB_TAGS) {
      ctlsstab.p_ActiveTab=CLEXTAB_GENERAL;
   }
}

static void AddLexerToModList()
{
   if (LAST_LEXER_NAME() == NO_LEXER) return;

   fid := p_active_form;
   if (p_active_form.p_name!='_cc_form') {
      //return;
      fid=_find_formobj('_cc_form','N');
      if (!fid) return;
   }
   _str lexername=fid.LAST_LEXER_NAME();
   fid._GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->:[lexername]=1;
   _nocheck _control _ctlcancel;
   _nocheck _control _ctldelete_lexer;
   fid._ctldelete_lexer.p_enabled=true;
   if (_plugin_has_builtin_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexername)) {
      fid._ctldelete_lexer.p_caption="Reset";
   } else {
      fid._ctldelete_lexer.p_caption="Delete";
   }
}

void ctlperl.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      if (p_parent.p_name=='ctlframe1') {
         if (p_value) {
            bbc_value:=ctlbbc.p_value;
            html_value:=ctlhtml.p_value;
            ctlperl.cc_clear_all_check_boxes();
            // Allow HTML and BBC to be on at the same time.
            if (p_window_id==ctlhtml || p_window_id==ctlbbc) {
               ctlbbc.p_value=bbc_value;
               ctlhtml.p_value=html_value;
            }
            p_value=1;
         }
         cc_prepare_tags_tab();
         ctlos390asm_flow.p_enabled=ctlos390asm.p_value!=0;
      }
      AddLexerToModList();
   }
}
void ctldigit_float.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      ctldote_float.p_enabled=ctld_exponent.p_enabled=(p_value!=0);
      AddLexerToModList();
   }
}
void ctlzerox_p_float.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      ctldotp_float.p_enabled=(p_value!=0);
      AddLexerToModList();
   }
}
void ctldigit_separator_char.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      AddLexerToModList();
   }
}
void ctllinenum.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      AddLexerToModList();
   }
}
void _ctlcancel.lbutton_up() {
   _cc_form_cancel();

   if (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat()==VF_HASHTAB) {//Has been changed to list
      _str temp=MODIFIED_LEXER_HASHTAB;
      int result=_message_box(nls("Changes have been made.\n\nExit Anyway?"),
                          '',
                          MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result!=IDYES) return;
   }
   p_active_form._delete_window('');
}

void ctlcase_sensitive.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      gnew_keyword_table:[_ctllexer_list.p_text].case_sensitive=ctlcase_sensitive.p_value?true:false;
      AddLexerToModList();
   }
}

void ctlfollow_idchars.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      gnew_keyword_table:[_ctllexer_list.p_text].idchars=ctlstart_idchars.p_text' 'ctlfollow_idchars.p_text;
      AddLexerToModList();//say('mod5');
   }
}

void ctlstart_idchars.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      gnew_keyword_table:[_ctllexer_list.p_text].idchars=ctlstart_idchars.p_text' 'ctlfollow_idchars.p_text;
      AddLexerToModList();//say('mod5');
   }
}
void ctlignore_text_start_col.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      value:=ctlignore_text_start_col.p_text;
      if (isinteger(value) && value>0) {
         gnew_keyword_table:[_ctllexer_list.p_text].ignore_text_after_start_col=(int)value;
      } else {
         gnew_keyword_table:[_ctllexer_list.p_text].ignore_text_after_start_col=0;
      }
      AddLexerToModList();//say('mod5');
   }
}


void ctlinherit_list.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      gnew_keyword_table:[_ctllexer_list.p_text].inherit=p_text;
      AddLexerToModList();//say('mod5');
   }
}

void ctltoken_case_sensitive.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->case_sensitive=ctltoken_case_sensitive.p_value;
      AddLexerToModList();
   }
}
void ctltype.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->type=_cc_convert_from_dlg_color_name(ctltype.p_text);
      cc_update_current(*pcomment);
      AddLexerToModList();
   }
}
void ctlstart_delim.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->delim1=ctlstart_delim.p_text;
      cc_update_current(*pcomment);
      AddLexerToModList();
   }
}

void ctlend_delim.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->delim2=ctlend_delim.p_text;
      cc_update_current(*pcomment);
      cc_enabled_multiline(pcomment);
      AddLexerToModList();
   }
}
void ctlstart_delim_search.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      _cc_set_search(false);
      AddLexerToModList();
   }
}
void ctlend_delim_search.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      _cc_set_search(true);
      AddLexerToModList();
   }
}

void ctlcolor_to_eol.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->color_to_eol=_cc_convert_from_dlg_color_name(ctlcolor_to_eol.p_text);
      cc_enabled_multiline(pcomment);
      AddLexerToModList();
   }
}
void ctlend_color_to_eol.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->end_color_to_eol=_cc_convert_from_dlg_color_name(ctlend_color_to_eol.p_text);
      AddLexerToModList();
   }
}
void ctlmultiline.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      _cc_set_multiline();
   }
}
void ctlcolor_to_eof.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&= ~(CLEXMF_MULTILINE|CLEXMF_TERMINATE);
      if (p_value) {
         pcomment->flags|= (CLEXMF_MULTILINE);
      }
      _cc_set_multiline_from_flags(pcomment);
      cc_enabled_multiline(pcomment);
      AddLexerToModList();
   }
}
void ctldoubles_char.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->doubles_char=ctldoubles_char.p_text;
      AddLexerToModList();
   }
}
void ctlescape_char.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->escape_char=ctlescape_char.p_text;
      AddLexerToModList();
   }
}

void ctlline_continuation_char.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->line_continuation_char=ctlline_continuation_char.p_text;
      AddLexerToModList();
   }
}
void _ctlnesting.lbutton_up() {
   cc_enabled_nesting();
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->nesting=ctlnesting.p_value;
      AddLexerToModList();
   }
}

void ctlnest_start.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->nestingStart=ctlnest_start.p_text;
      AddLexerToModList();
   }
}
void ctlnest_end.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->nestingEnd=ctlnest_end.p_text;
      AddLexerToModList();
   }
}
void ctlfirst_non_blank.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_FIRST_NON_BLANK;
      if (ctlfirst_non_blank.p_value) {
         pcomment->flags|=CLEXMF_FIRST_NON_BLANK;
      }
      AddLexerToModList();
   }
}
void ctlcheck_first.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_CHECK_FIRST;
      if (ctlcheck_first.p_value) {
         pcomment->flags|=CLEXMF_CHECK_FIRST;
      }
      AddLexerToModList();
   }
}
void ctlstart_color.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->start_color=_cc_convert_from_dlg_color_name(ctlstart_color.p_text);
      AddLexerToModList();
   }
}
void ctlend_color.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->end_color=_cc_convert_from_dlg_color_name(ctlend_color.p_text);
      AddLexerToModList();
   }
}
void ctlstart_col.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->startcol=(isinteger(ctlstart_col.p_text) && ctlstart_col.p_text>0)?(int)ctlstart_col.p_text:0;
      AddLexerToModList();
   }
}
void ctlend_col.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->endcol=(isinteger(ctlend_col.p_text) && ctlend_col.p_text>0)?(int)ctlend_col.p_text:0;
      AddLexerToModList();
   }
}
void ctlend_start_col.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->end_startcol=(isinteger(ctlend_start_col.p_text) && ctlend_start_col.p_text>0)?(int)ctlend_start_col.p_text:0;
      AddLexerToModList();
   }
}
void ctlend_end_col.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->end_endcol=(isinteger(ctlend_end_col.p_text) && ctlend_end_col.p_text>0)?(int)ctlend_end_col.p_text:0;
      AddLexerToModList();
   }
}
void ctlorder.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->order=(isinteger(ctlorder.p_text))?(int)ctlorder.p_text:0;
      AddLexerToModList();
   }
}
void ctlembedded_profile.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->embedded_lexer=ctlembedded_profile.p_text;
      cc_enabled_multiline(pcomment);
      AddLexerToModList();
   }
}
void ctlembedded_prefix_match.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_EMBEDDED_LEXER_PREFIX_MATCH;
      if (ctlembedded_prefix_match.p_value) {
         pcomment->flags|=CLEXMF_EMBEDDED_LEXER_PREFIX_MATCH;
      }
      AddLexerToModList();
   }
}
void ctlembedded_end_is_token.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_EMBEDDED_END_IS_TOKEN;
      if (ctlembedded_end_is_token.p_value) {
         pcomment->flags|=CLEXMF_EMBEDDED_END_IS_TOKEN;
      }
      AddLexerToModList();
   }
}

void ctlapply_multiline_at_eol.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_APPLY_MULTILINE_AT_EOL;
      if (ctlapply_multiline_at_eol.p_value) {
         pcomment->flags|=CLEXMF_APPLY_MULTILINE_AT_EOL;
      }
      AddLexerToModList();
   }
}
void ctlend_embedded_at_bol_if_possible.lbutton_up() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      COMMENT_TYPE *pcomment=get_item_pointer();
      pcomment->flags&=~ CLEXMF_END_EMBEDED_AT_BOL_IF_POSSIBLE;
      if (ctlend_embedded_at_bol_if_possible.p_value) {
         pcomment->flags|=CLEXMF_END_EMBEDED_AT_BOL_IF_POSSIBLE;
      }
      AddLexerToModList();
   }
}
void ctlembedded_color_style.on_change() {
   if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
      _cc_set_embedded_color_style();
   }
}



void disable_enable_tabs(int tabControl, bool enable)
{
   int i;
   for (i = 0; i < tabControl.p_NofTabs; i++) {
      tabControl._setEnabled(i, (int)enable);
   }
}

void _ctllexer_list.on_change(int reason)
{
   if (ERROR_ON_LEXER_NAME_CHANGE()==1) {
      return;
   }
   IN_LEXER_LIST_ON_CHANGE(1);
   // validate any changes that were made
   error := validate_lexer();
   if (error) {
      // failed validation, switch back to the last lexer
      ERROR_ON_LEXER_NAME_CHANGE(1);
      _ctllexer_list.p_text=LAST_LEXER_NAME();
      ERROR_ON_LEXER_NAME_CHANGE('');

      // switch to the tab that errored
      //ctlsstab.p_ActiveTab = errorTab;
      IN_LEXER_LIST_ON_CHANGE(0);
      return;
   }

   if (!DONT_UPDATE_LIST()) {
      // Save the last settings
      if(save_last_settings() ) {
         ERROR_ON_LEXER_NAME_CHANGE(1);
         _ctllexer_list.p_text=LAST_LEXER_NAME();
         ERROR_ON_LEXER_NAME_CHANGE('');
         IN_LEXER_LIST_ON_CHANGE(0);
         return;
      }
   }
   LAST_LEXER_NAME(_ctllexer_list.p_text);

   //Reset all the values
   ctlcase_sensitive.p_value=0;
   ctlstart_idchars.p_text='';
   ctlfollow_idchars.p_text='';
   ctlignore_text_start_col.p_text='';

   if (_ctllexer_list.p_text == NO_LEXER) {
      // disable all controls
      _ctldelete_lexer.p_enabled = false;
      disable_enable_tabs(ctlsstab.p_window_id, false);
      return;
   } 
   if (!_ctldelete_lexer.p_enabled) {
      _ctldelete_lexer.p_enabled = true;
      disable_enable_tabs(ctlsstab.p_window_id, true);
   }

   //We need to check and see if the lexer is loaded.  Any field should be ok
   if (gnew_keyword_table:[_ctllexer_list.p_text].case_sensitive._varformat()==VF_EMPTY) {
      _clex_load_profile(_ctllexer_list.p_text,gnew_keyword_table:[_ctllexer_list.p_text]);
   }
   
   ctlcase_sensitive.p_value=(int)gnew_keyword_table:[_ctllexer_list.p_text].case_sensitive;
   CLEXDEF *pclexdef= &gnew_keyword_table:[_ctllexer_list.p_text];
   _str idchars= pclexdef->idchars;
   _str start,follow;
   parse idchars with start follow;
   ctlstart_idchars.p_text=start;
   ctlfollow_idchars.p_text=follow;
   if (pclexdef->inherit=='') {
      ctlinherit_list.p_text= NO_LEXER;
   } else {
      if (ctlinherit_list._lbfind_item(_ctllexer_list.p_text) < 0) {
         _lbadd_item(_ctllexer_list.p_text);
      }
      ctlinherit_list.p_text= pclexdef->inherit;
   }
   if (pclexdef->ignore_text_after_start_col>0) {
      ctlignore_text_start_col.p_text=pclexdef->ignore_text_after_start_col;
   } else {
      ctlignore_text_start_col.p_text='';
   }
   
   cc_prepare_tokens_tab(_ctllexer_list.p_text);
   cc_prepare_numbers_tab(_ctllexer_list.p_text);
   cc_prepare_language_tab(_ctllexer_list.p_text);
   cc_prepare_tags(_ctllexer_list.p_text);
   cc_prepare_tags_tab();
   //_ctlcomment_list.call_event(CHANGE_SELECTED,_ctlcomment_list,on_change,'W');
   // If there are some user settings OR ...
   _ctldelete_lexer.p_enabled=_plugin_has_user_profile(VSCFGPACKAGE_COLORCODING_PROFILES,_ctllexer_list.p_text) || 
      (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat() == VF_HASHTAB && _GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_indexin(_ctllexer_list.p_text));
   if (_plugin_has_builtin_profile(VSCFGPACKAGE_COLORCODING_PROFILES,_ctllexer_list.p_text)) {
      _ctldelete_lexer.p_caption="Reset";
   } else {
      _ctldelete_lexer.p_caption="Delete";
   }
   IN_LEXER_LIST_ON_CHANGE(0);
}
void ctltree1.on_change(int reason,int index) {
   switch (reason) {
   case CHANGE_SELECTED:
      if (p_active_form.p_visible && !IN_LEXER_LIST_ON_CHANGE()) {
         IN_LEXER_LIST_ON_CHANGE(1);
         cc_prepare_token();
         IN_LEXER_LIST_ON_CHANGE(0);
      }
      break;
   }
}

static void AddNewLexer(_str LexerName, _str copyFromLexer = '')
{
   wid := p_window_id;
   p_window_id=_ctllexer_list;
   save_pos(auto p);
   _lbtop();_lbup();
   //p_window_id=wid;
   if (!_lbfind_and_select_item(LexerName)) {
      _message_box(nls("A lexer definition named '%s' already exists.",LexerName));
      p_window_id=wid;
      return;
   }
   restore_pos(p);
   if (copyFromLexer == '') {
      _clex_init(gnew_keyword_table:[LexerName]);
      gnew_keyword_table:[LexerName].idchars='a-zA-Z 0-9_';
   } else {
      // do not load it, just copy the settings and the _ctllexer_list
      // on_change event will handle it
      copyLexer(copyFromLexer, LexerName);
   }
   wid=p_window_id;
   p_window_id=_ctllexer_list;
   _lbadd_item(LexerName);
   _lbsort('i');
   _lbfind_and_select_item(LexerName);
   AddLexerToModList();
   p_window_id=wid;
}

_ctlnew.lbutton_up()
{
   result := show('-modal _create_new_lexer_form');

   if (result != '') {
      AddNewLexer(_param1, _param2);
   }
}

/**
 * Callback to ensure that the lexer name is acceptable as according to our very 
 * high standards. 
 * 
 * @param name    the lexer name to be verified
 * 
 * @return        0 for successful validation, error otherwise
 */
bool verifyLexerName(_str name)
{
   // we don't allow no blank lexer names 'round here
   if (name == '') {
      _message_box("Please enter a lexer name.");
      return true;
   }

   // everything's alright
   return false;
}

ctltree1.DEL()
{
   if (ctldelete.p_enabled) {
      ctldelete.call_event(ctldelete,LBUTTON_UP,'W');
   }
}
void ctldelete.lbutton_up() {
   AddLexerToModList();
   IN_LEXER_LIST_ON_CHANGE(1);
   mou_hour_glass(true);
   cur_tree_wid:=ctltree1;
   int index;
   info := 0;
   ff:=1;
   int array[];
   for (;;ff=0) {
      index = cur_tree_wid._TreeGetNextSelectedIndex(ff,info);
      if (ff && index <= 0) {
         array[array._length()]=cur_tree_wid._TreeCurIndex();
         break;
      }
      if (index <= 0) break;
      array[array._length()]=index;
   }
   index=ctltree1._TreeCurIndex();
   prev:=ctltree1._TreeGetPrevSiblingIndex(index);
   parent_index:=ctltree1._TreeGetParentIndex(index);
   len := array._length();
   for (i:=0;i<len;++i) {
      index=array[i];
      p:=cur_tree_wid._TreeGetParentIndex(index);
      n:=cur_tree_wid._TreeGetPrevSiblingIndex(index);
      if (n<0) {
         n=cur_tree_wid._TreeGetNextSiblingIndex(index);
      }
      cur_tree_wid.delete_tree_item_recursive(index);
      if (n<0) {
         cur_tree_wid._TreeSetInfo(p,TREE_NODE_LEAF);
      }
   }
   mou_hour_glass(false);
   index=ctltree1._TreeCurIndex();
   if (index<=0) {
      if (prev>0) {
         ctltree1._TreeSetCurIndex(prev);
      } else if (parent_index>0) {
         ctltree1._TreeSetCurIndex(parent_index);
      } else {
         index=ctltree1._TreeGetFirstChildIndex(0);
         if (index>0) {
            ctltree1._TreeSetCurIndex(index);
         }
      }
   }
   index=ctltree1._TreeCurIndex();
   if (index==0) {
      index=ctltree1._TreeGetFirstChildIndex(0);
   }
   if (index>0) {
      ctltree1._TreeSelectLine(index);
   }
   cc_set_token_enable();
   if (index>=0) {
      cc_prepare_token();
   }
   IN_LEXER_LIST_ON_CHANGE(0);
}
typedef COMMENT_TYPE (*pcomments_t)[];
static pcomments_t get_parent_comments_pointer(int &parent) {
   index:=ctltree1._TreeCurIndex();
   if (index<=0) {
      parent=0;
      return &gnew_keyword_table:[LAST_LEXER_NAME()].comments;
   }
   parent=ctltree1._TreeGetParentIndex(index);
   parse ctltree1._TreeGetUserInfo(index) with auto pcomments .;
   return (typeless)pcomments;
}
static COMMENT_TYPE *get_item_pointer() {
   index:=ctltree1._TreeCurIndex();
   if (index<=0) {
      return null;
   }
   parse ctltree1._TreeGetUserInfo(index) with . auto pcomment;
   return (typeless)pcomment;
}
static int find_array_index(COMMENT_TYPE (*pcomments)[],COMMENT_TYPE *pcomment) {
   int len=pcomments->_length();
   for (i:=0;i<len;++i) {
      if (&pcomments->[i]==pcomment) {
         return i;
      }
   }
   return -1;
}
static void delete_tree_item_recursive(int index) {
   typeless pcomments,pcomment;
   parse _TreeGetUserInfo(index) with pcomments pcomment;
   i:=find_array_index(pcomments,pcomment);
   // Delete the children
   child:=_TreeGetFirstChildIndex(index);
   while (child>=0) {
      delete_tree_item_recursive(child);
      child=_TreeGetNextSiblingIndex(child);
   }
   _TreeDelete(index);
   pcomments->_deleteel(i);
}
static void cc_update_current(COMMENT_TYPE &comment) {
   text:=_cc_convert_to_dlg_color_name(comment.type)"\t"comment.delim1"\t"comment.delim2;
   ctltree1._TreeSetCaption(ctltree1._TreeCurIndex(),text);
}
void ctlimport_word_list.lbutton_up()
{

   result:=show(' -modal _cc_import_word_list');
   if (result=='') {
      return;
   }
#if 0
   typeless result=_OpenDialog('-modal ',
               'Get File',
               '*.*',
               'All Files (*.*)',
               OFN_FILEMUSTEXIST,  //OFN_FILEMUSTEXIST can create new file.
               '',
               '',
               '');
   if (result=='') return;
#endif
   type:=_param2;
   _str filename=_param1;
   mou_hour_glass(true);
   temp_view_id := 0;
   orig_view_id := 0;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,'+d');
   if (status) {
      _message_box(nls("Could not open %s\n\n%s",filename,get_message(status)));
      mou_hour_glass(false);
      return;
   }
   p_window_id=orig_view_id;
   temp_view_id.up();
   ctltree1._TreeDeselectAll();
   line := "";
   ctlsstab2.p_ActiveTab=0; // Activate the Settings tab
   int parent;
   COMMENT_TYPE (*pcomments)[]=get_parent_comments_pointer(parent);
   first_child:= -1;
   IN_LEXER_LIST_ON_CHANGE(1);
   while (!temp_view_id.down()) {
      temp_view_id.get_line(line);
      for (;;) {
         _str cur = parse_file(line,false);
         if (cur=='') break;
         COMMENT_TYPE comment;
         _init_comment(comment);
         comment.type=type;
         comment.delim1=cur;
         comment.case_sensitive=_param3;
         pcomments->[pcomments->_length()]=comment;
         child:=ctltree1._cc_add_tree_item(parent,*pcomments,pcomments->_length()-1);
         if (first_child<0) {
            first_child=child;
         }
      }
   }
   IN_LEXER_LIST_ON_CHANGE(0);
   _delete_temp_view(temp_view_id);
   AddLexerToModList();
   mou_hour_glass(false);
   index:=ctltree1._TreeCurIndex();
   ctldelete.p_enabled=index>0;
   if (first_child>=0) {
      IN_LEXER_LIST_ON_CHANGE(1);
      ctltree1._TreeSetCurIndex(first_child);
      IN_LEXER_LIST_ON_CHANGE(0);
      ctltree1.call_event(CHANGE_SELECTED,first_child,ctltree1,ON_CHANGE,'W');
   }
}
void ctladd_words.lbutton_up() {
   result:=show(' -modal _cc_add_words');
   if (result=='') {
      return;
   }
   ctltree1._TreeDeselectAll();
   AddLexerToModList();

   int parent;
   COMMENT_TYPE (*pcomments)[]=get_parent_comments_pointer(parent);
   line:=_param1;
   type:=_param2;
   first_child:= -1;
   ctlsstab2.p_ActiveTab=0; // Activate the Settings tab
   IN_LEXER_LIST_ON_CHANGE(1);
   for (;;) {
      _str cur = parse_file(line,false);
      if (cur=='') break;
      COMMENT_TYPE comment;
      _init_comment(comment);
      comment.type=type;
      comment.delim1=cur;
      comment.case_sensitive=_param3;
      pcomments->[pcomments->_length()]= comment;
      child:=ctltree1._cc_add_tree_item(parent,*pcomments,pcomments->_length()-1);
      if (first_child<0) {
         first_child=child;
      }
   }
   IN_LEXER_LIST_ON_CHANGE(0);
   index:=ctltree1._TreeCurIndex();
   ctldelete.p_enabled=index>0;
   if (first_child>=0) {
      IN_LEXER_LIST_ON_CHANGE(1);
      ctltree1._TreeSetCurIndex(first_child);
      IN_LEXER_LIST_ON_CHANGE(0);
      cc_set_token_enable();
      ctltree1.call_event(CHANGE_SELECTED,first_child,ctltree1,ON_CHANGE,'W');
   }
   //ctlstart_delim._set_focus();
}
void ctladd_other.lbutton_up() {
   ctltree1._TreeDeselectAll();
   AddLexerToModList();
   ctlsstab2.p_ActiveTab=0; // Activate the Settings tab
   int parent;
   COMMENT_TYPE (*pcomments)[]=get_parent_comments_pointer(parent);
   COMMENT_TYPE comment;
   _init_comment(comment);
   comment.type='comment';
   comment.delim1='';
   pcomments->[pcomments->_length()]=comment;
   index:=ctltree1._TreeCurIndex();
   IN_LEXER_LIST_ON_CHANGE(1);
   first_child:=ctltree1._cc_add_tree_item(parent,*pcomments,pcomments->_length()-1);
   IN_LEXER_LIST_ON_CHANGE(0);
   ctldelete.p_enabled=index>0;
   if (first_child>=0) {
      IN_LEXER_LIST_ON_CHANGE(1);
      ctltree1._TreeSetCurIndex(first_child);
      IN_LEXER_LIST_ON_CHANGE(0);
      cc_set_token_enable();
      ctltree1.call_event(CHANGE_SELECTED,first_child,ctltree1,ON_CHANGE,'W');
   }
   ctlstart_delim._set_focus();
}
void ctladd_sub_item.lbutton_up() {
   ctltree1._TreeDeselectAll();
   AddLexerToModList();
   ctlsstab2.p_ActiveTab=0; // Activate the Settings tab
   int parent;
   COMMENT_TYPE *pcomments=get_item_pointer();
   COMMENT_TYPE comment;
   _init_comment(comment);
   comment.type='k';
   comment.delim1='';
   pcomments->comments[pcomments->comments._length()]=comment;
   index:=ctltree1._TreeCurIndex();
   ctltree1._TreeSetInfo(index,TREE_NODE_EXPANDED);
   first_child:=ctltree1._cc_add_tree_item(index,pcomments->comments,pcomments->comments._length()-1);
   ctldelete.p_enabled=index>0;
   if (first_child>=0) {
      ctltree1._TreeSetCurIndex(first_child);
   }
   ctlstart_delim._set_focus();
}


static void make_keyword_list(_str (&list)[])
{
   list_size := p_Noflines;
   list._makeempty();
   if (list_size == 0) {
      return;
   }
   list[list_size-1] = "";
   mou_hour_glass(true);
   count := 0;
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str text=_lbget_text();
      if (pos(' ',text) && !(substr(text, 1, 1)=='"' && substr(text, length(text), 1)=='"')) {
         text=_dquote(text);
      }
      list[count] = text; count++;
   }
   mou_hour_glass(false);
}

static void add_to_str(_str &str,_str newinfo,_str spacer=' ')
{
   if (str=='') {
      str=newinfo;
   }else{
      str :+= spacer:+newinfo;
   }
}


/**
 * Retrieves an array of commenting styles.  Modified from 
 * GetAllComments in diffmf.e. 
 *  
 * @param comments   array in which to place commenting styles, 
 *                   one per element.  Multi-lined comments are
 *                   space delimited (left_comment'
 *                   'right_comment).
 * @param option     Can be "" (may return strings and other 
 *                   stuff), "L" (line-comments) , "M"
 *                   (multi-line comments), "A" (all commments)
 */
void GetComments(COMMENT_TYPE (&comments)[], _str option, _str profileName)
{
   comments._makeempty();
   int handle=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,profileName);
   // Try loading a profile which should be ok
   if(handle<0) {
      return;

   }
   profile_node:=_xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   LoadComments(handle,profile_node,comments);
   if (option!='') {
      option=upcase(option);
      for (i:=0;i<comments._length();++i) {
         doDelete := false;
         if (comments[i].type!='comment' && comments[i].type!='doc_comment') {
            doDelete=true;
         } else if (comments[i].delim2!='') {
            if (option=='L') {
               doDelete=true; //Only want linecomment not mlcomment
            }
         } else if (option=='M') {
            doDelete=true;   // Only want mlcomment not linecomment
         }
         if (doDelete) {
            comments._deleteel(i);--i;
         }
      }
   }
   _xmlcfg_close(handle);
}


static void LoadComments(int handle,int profile_node,COMMENT_TYPE (&comments)[]) {
   typeless array[];
   _xmlcfg_find_simple_array(handle,"p[contains(@n,'^(comment|doc_comment),','r')]/attrs[@end or @color_to_eol]",array,profile_node);
   for (i:=0;i<array._length();++i) {
      int attrs_node=array[i];
      int property_node=_xmlcfg_get_parent(handle,attrs_node);
      if(!_clex_has_non_regex(handle,property_node)) {
         continue;
      }
      _str name;
      name=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
      parse name with auto color (VSXMLCFG_PROPERTY_SEPARATOR) name;
      _clex_add_item(handle,property_node,comments,color,name);
   }
}

static void LoadMLCKeyword(int handle,int property_node,CLEXDEF &Lexer)
{
   case_sensitive := Lexer.case_sensitive;

   list:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
   j := 2;
   mlcomment_start:=_pos_parse_wordsep(j,list,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
   if (mlcomment_start==null || mlcomment_start=='') {
      return;
   }
   mlcomment_start=strip(mlcomment_start);
   mlckeyword:=_pos_parse_wordsep(j,list,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
   if (mlckeyword==null) {
      // This isn't supposed to happen
      return;
   }
   mlckeyword=strip(mlckeyword);
   attr:=_pos_parse_wordsep(j,list,VSXMLCFG_PROPERTY_SEPARATOR,VSSTRWF_NONE,VSXMLCFG_PROPERTY_ESCAPECHAR);
   if (attr==null) {
      // This isn't supposed to happen
      return;
   }
   CLEX_TAGDEF_TYPE *ptd=&Lexer.tagdef:[mlcomment_start];
   if (ptd->comment_keywords==null) {
      _clex_init_tagdef(ptd);
   }
   //Lexer.mlcomment_start=mlcomment_start;
   if (attr!='') {
      values:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
      if (mlckeyword!='') {
         if (case_sensitive) {
            ptd->comment_values:[attr'('mlckeyword')']=strip(values);
         } else {
            ptd->comment_values:[lowcase(attr'('mlckeyword')')]=strip(values);
         }
      } else {
         if (case_sensitive) {
            ptd->comment_values:[attr]=strip(values);
         } else {
            ptd->comment_values:[lowcase(attr)]=strip(values);
         }
      }
   } else {
      if (ptd->comment_keywords=='') {
         ptd->comment_keywords=mlckeyword;
      }else{
         ptd->comment_keywords=ptd->comment_keywords' 'mlckeyword;
      }
      attrs:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
      if (attrs!='') {
         if (case_sensitive) {
            ptd->comment_attributes:[mlckeyword]=strip(attrs);
         } else {
            ptd->comment_attributes:[lowcase(mlckeyword)]=strip(attrs);
         }
      }
   }
}
void _cc_set_property(int handle,int profileNode,int (&propery_to_node):[],bool case_sensitive,_str name,_str value) {
   int *pnode;
   _str key=name;
   if (!case_sensitive) key=lowcase(key);
   pnode=propery_to_node._indexin(key);
   int propertyNode;
   if (!pnode) {
      propertyNode=_xmlcfg_add_property(handle,profileNode,name);
      propery_to_node:[key]=propertyNode;
   } else {
      propertyNode=*pnode;
      if (value==null) {
         child:=_xmlcfg_get_first_child(handle,propertyNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         if (child>=0) {
            _xmlcfg_add(handle,propertyNode,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            return;
         }
      }
   }
   if (value!=null) {
      _xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_VALUE,value);
   }
}
static _str gcolor_to_dlg_color:[] = {
   'other'=> 'Other',
   'k'=> 'Keyword',
   'number'=> 'Number',
   'float'=> 'Float',
   'hex_int'=> 'Hexadecimal Integer',
   'string'=> 'String',
   'comment'=> 'Comment',
   'pp'=> 'Preprocessor Keyword',
   'linenum'=> 'Line Number',
   'pu'=> 'Punctuation',
   'lib'=> 'Library Symbol',
   'op'=> 'Operator',
   'user'=> 'User Defined Keyword',
   'function'=> 'Function',
   'attribute'=> 'Attribute',
   'unknown_attribute'=> 'Unknown Attribute',
   'tag'=> 'Tag',
   'xhtml_element_in_xsl'=> 'XHTML Element in XSL',
   'unknown_tag'=> 'Unknown Tag',
   'doc_comment'=> 'Doc Comment',
   'doc_keyword'=> 'Doc Keyword',
   'doc_punctuation'=> 'Doc Punctuation',
   'doc_attribute'=> 'Doc Attribute',
   'doc_attr_value'=> 'Doc Attribute Value',
   'identifier'=> 'Identifier',
   'identifier2'=> 'Identifier2',
   'inactive_code'=> 'Inactive Code',
   'inactive_keyword'=> 'Inactive Keyword',
   'inactive_comment'=> 'Inactive Comment',
   'xml_character_reference'=> 'XML/HTML Numeric Char Ref',
   'markdown_header'=> 'Markdown Header',
   'markdown_code'=> 'Markdown Code',
   'markdown_blockquote'=> 'Markdown Blockquote',
   'markdown_link'=> 'Markdown Link',
   'markdown_link2'=> 'Markdown Link2',
   'markdown_bullet'=> 'Markdown Bullet',
   'markdown_emphasis'=> 'Markdown Emphasis',
   'markdown_emphasis2'=> 'Markdown Emphasis2',
   'markdown_emphasis3'=> 'Markdown Emphasis3',
   'markdown_emphasis4'=> 'Markdown Emphasis4',
   'css_element'=> 'CSS Element',
   'css_class'=> 'CSS Class',
   'css_property'=> 'CSS Property',
   'css_selector'=> 'CSS Selector',
   'modified_line'=> 'Modified line',
   'inserted_line'=> 'Inserted line',
   'deleted_line'=> 'Deleted line',
   'yaml_text_colon'=>'YAML Text Colon',
   'yaml_text'=>'YAML Text',
   'yaml_tag'=>'YAML Tag',
   'yaml_directive'=>'YAML Directive',
   'yaml_anchor_def'=>'YAML Anchor Definition',
   'yaml_anchor_ref'=>'YAML Anchor Reference',
   'yaml_punctuation'=>'YAML Punctuation',
   'yaml_operator'=>'YAML Operator',
};
static _str _cc_convert_from_dlg_color_name(_str color) {

   color=lowcase(color);
   foreach ( auto xml_color => auto dlg_color in gcolor_to_dlg_color  ) {
      if (color==lowcase(dlg_color)) {
         return xml_color;
      }
   }
   return '';
}
static const NULL_COLOR='(None)';
static _str _cc_convert_to_dlg_color_name(_str color) {
   _str *presult=gcolor_to_dlg_color._indexin(color);
   if (presult) {
      return *presult;
   }
   return NULL_COLOR;
}
static int gclexmf_table:[]={
   'check_first'=>CLEXMF_CHECK_FIRST,
   'first_non_blank'=>CLEXMF_FIRST_NON_BLANK,
   'regex'=>CLEXMF_REGEX,
   'perlre'=>CLEXMF_PERLRE,
   'end_regex'=>CLEXMF_END_REGEX,
   'end_perlre'=>CLEXMF_END_PERLRE,
   'multiline'=>CLEXMF_MULTILINE,
   'terminate'=>CLEXMF_TERMINATE,
   'embedded_lexer_prefix_match'=>CLEXMF_EMBEDDED_LEXER_PREFIX_MATCH,
   'dont_color_as_embedded_if_possible'=>CLEXMF_DONT_COLOR_AS_EMBEDDED_IF_POSSIBLE,
   'color_as_embedded_if_found'=>CLEXMF_COLOR_AS_EMBEDDED_IF_FOUND,
   'embedded_end_is_token'=>CLEXMF_EMBEDDED_END_IS_TOKEN,
   'apply_multiline_at_eol'=>CLEXMF_APPLY_MULTILINE_AT_EOL,
   'end_embeded_at_bol_if_possible'=>CLEXMF_END_EMBEDED_AT_BOL_IF_POSSIBLE,
};
static int gclexmn_table:[]={
   "digit_int"=>CLEXMN_DIGIT_INT,
   "digit_float"=>CLEXMN_DIGIT_FLOAT,
   "dot_float"=>CLEXMN_DOT_FLOAT,
   "zerox_p_float"=>CLEXMN_ZEROX_P_FLOAT,
   "d_exponent"=>CLEXMN_D_EXPONENT,
   "dote_float"=>CLEXMN_DOTE_FLOAT,
   "dotp_float"=>CLEXMN_DOTP_FLOAT,
   "verilog_base_squote_hex"=>CLEXMN_VERILOG_BASE_SQUOTE_HEX,
   "no_exponent"=>CLEXMN_NO_EXPONENT,
   "allow_hex_digits"=>CLEXMN_ALLOW_HEX_DIGITS,
   "zerox_hex"=>CLEXMN_ZEROX_HEX,
   "zeroo_octal"=>CLEXMN_ZEROO_OCTAL,
   "zerob_binary"=>CLEXMN_ZEROB_BINARY,
   "zerod_decimal"=>CLEXMN_ZEROD_DECIMAL,
   "color_leading_sign"=>CLEXMN_COLOR_LEADING_SIGN,
};
static _clex_add_xml_attrs(int handle,int attrs_node,COMMENT_TYPE &info) {
   if (info.startcol>=1 || info.endcol>=1) {
      if (info.startcol<1) info.startcol=1;
      _xmlcfg_set_attribute(handle,attrs_node,'start_col',info.startcol);
   }
   if (info.endcol>=1) _xmlcfg_set_attribute(handle,attrs_node,'end_col',info.endcol);
   if (info.delim2:!='') {
      _xmlcfg_set_attribute(handle,attrs_node,'end',info.delim2);
   }
   if (info.end_startcol>=1 || info.end_endcol>=1) {
      if (info.end_startcol<1) info.end_startcol=1;
      _xmlcfg_set_attribute(handle,attrs_node,'end_start_col',info.end_startcol);
   }
   if (info.end_endcol>=1) _xmlcfg_set_attribute(handle,attrs_node,'end_end_col',info.end_endcol);

   _str new_flags=_clex_flags_to_str(gclexmf_table,info.flags);
   if (new_flags=='') {
      _xmlcfg_delete_attribute(handle,attrs_node,'flags');
   } else {
      // Keep them in the same order they were and add the new ones
      new_flags=_plugin_update_word_list(info.orig_flags,new_flags);
      _xmlcfg_set_attribute(handle,attrs_node,'flags',new_flags);
   }

   if (info.order) _xmlcfg_set_attribute(handle,attrs_node,'order',info.order);
   if (info.case_sensitive==0 || info.case_sensitive==1) _xmlcfg_set_attribute(handle,attrs_node,'case_sensitive',info.case_sensitive);

   if (info.start_color!='') _xmlcfg_set_attribute(handle,attrs_node,'start_color',info.start_color);
   if (info.end_color!='') _xmlcfg_set_attribute(handle,attrs_node,'end_color',info.end_color);
   if (info.color_to_eol!='') _xmlcfg_set_attribute(handle,attrs_node,'color_to_eol',info.color_to_eol);
   if (info.end_color_to_eol!='') _xmlcfg_set_attribute(handle,attrs_node,'end_color_to_eol',info.end_color_to_eol);
   if (info.escape_char!='') _xmlcfg_set_attribute(handle,attrs_node,'escape_char',info.escape_char);
   if (info.line_continuation_char!='') _xmlcfg_set_attribute(handle,attrs_node,'line_continuation_char',info.line_continuation_char);
   if (info.doubles_char!='') _xmlcfg_set_attribute(handle,attrs_node,'doubles_char',info.doubles_char);
   if (info.embedded_lexer!='') _xmlcfg_set_attribute(handle,attrs_node,'embedded_lexer',info.embedded_lexer);
   if (info.nesting) {
      if (info.nestingStart=='') {
         info.nestingStart=info.delim1;
      }
      if (info.nestingEnd=='') {
         info.nestingEnd=info.delim2;
      }
   }
   if (info.nestingStart!='' && info.nestingEnd!='') {
      _xmlcfg_set_attribute(handle,attrs_node,'nest_start',info.nestingStart);
      _xmlcfg_set_attribute(handle,attrs_node,'nest_end',info.nestingEnd);
   }
   for (i:=0;i<info.comments._length();++i) {
      iattrs_node:=_xmlcfg_add(handle,attrs_node,"iattrs",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle,iattrs_node,"type",info.comments[i].type);
      _xmlcfg_set_attribute(handle,iattrs_node,"start",info.comments[i].delim1);
      _clex_add_xml_attrs(handle,iattrs_node,info.comments[i]);
   }
}
static void _clex_add_property_item(int handle,int profileNode,int (&property_to_node):[],COMMENT_TYPE &info) {
   int *pnode;
   name := info.type','info.delim1;
   _str key=name;

   pnode=property_to_node._indexin(key);
   int propertyNode;
   if (!pnode) {
      propertyNode=_xmlcfg_add_property(handle,profileNode,name);
      property_to_node:[key]=propertyNode;
   } else {
      propertyNode=*pnode;
   }
   /*
      Check if we need an attrs element
   */
   if (info.delim2!='' || info.startcol>0 || info.endcol>0 || 
       info.end_startcol>0 || info.end_endcol>0 || 
       info.order 
       || info.case_sensitive<2 || info.start_color!='' || info.end_color!=''
       || info.color_to_eol!='' || info.end_color_to_eol!='' || info.escape_char!=''
       || info.line_continuation_char!='' || info.doubles_char!='' || info.embedded_lexer!=''
       || info.flags!=CLEXMF_NONE || info.nesting || info.comments._length()
       ) {
      attrs_node:=_xmlcfg_add(handle,propertyNode,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _clex_add_xml_attrs(handle,attrs_node,info);
   }

}
_command void toggle_jinja_color_coding() name_info(',') {
   if (p_lexer_name=='') {
      return;
   }
   profileName:=p_lexer_name;
   int handle=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,profileName);
   profileNode:=_xmlcfg_get_document_element(handle);
   jinja_node:=_xmlcfg_find_property(handle,profileNode,'jinja');
   bool enabled;
   if (jinja_node<0) {
      jinja_node=_xmlcfg_add(handle,profileNode,VSXMLCFG_PROPERTY,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle,jinja_node,VSXMLCFG_PROPERTY_NAME,'jinja');
      enabled=true;
   } else {
      enabled=_xmlcfg_get_attribute(handle,jinja_node,'enabled')!=0;
      enabled=!enabled;
   }
   _xmlcfg_set_attribute(handle,jinja_node,'enabled',enabled);

    _plugin_set_profile(handle);
   _xmlcfg_close(handle);
   call_list('_lexer_updated_', profileName);
   _clex_load(profileName);
}
_command void toggle_blade_color_coding() name_info(',') {
   if (p_lexer_name=='') {
      return;
   }
   profileName:=p_lexer_name;
   int handle=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,profileName);
   profileNode:=_xmlcfg_get_document_element(handle);
   styles_node:=_xmlcfg_find_property(handle,profileNode,'styles');
   styles:='';
   if (styles_node>0) {
      styles=_xmlcfg_get_attribute(handle,styles_node,VSXMLCFG_PROPERTY_VALUE);
   }
   if (styles_node<0 || !pos(' blade ',' 'styles' ')) {
      replace_styles(handle,profileNode,profileName,styles' blade');
   } else {
      styles=stranslate(styles,'','blade','i');
      replace_styles(handle,profileNode,profileName,styles);
   }

    _plugin_set_profile(handle);
   _xmlcfg_close(handle);
   call_list('_lexer_updated_', profileName);
   _clex_load(profileName);
}
static void replace_styles(int handle,int profileNode,_str profileName,_str new_styles) {
   styles:=_plugin_get_property(VSCFGPACKAGE_COLORCODING_PROFILES,profileName,'styles','',null,1);
   styles=_plugin_update_word_list(styles,new_styles);
   if (styles=='') {
      _xmlcfg_delete_property(handle,profileNode,'styles');
   } else {
      _xmlcfg_set_property(handle,profileNode,'styles',styles);
   }
}
void _clex_save_profile(_str profileName,CLEXDEF &clexdef) {
   lexername:=profileName;
   case_sensitive := clexdef.case_sensitive;
   handle:=_xmlcfg_create('',VSENCODING_UTF8);

   int propery_to_node:[];
   profileNode:=_xmlcfg_add(handle,0,VSXMLCFG_PROFILE,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   profilePath:=_plugin_append_profile_name(VSCFGPACKAGE_COLORCODING_PROFILES, profileName);
   _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_NAME,profilePath);
   _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_VERSION,VSCFGPROFILE_COLORCODING_VERSION);

   _xmlcfg_set_property(handle,profileNode,'idchars',clexdef.idchars);
   _xmlcfg_set_property(handle,profileNode,'case_sensitive',clexdef.case_sensitive);
   replace_styles(handle,profileNode,lexername,clexdef.styles);

   old_mn_flags:=_plugin_get_property(VSCFGPACKAGE_COLORCODING_PROFILES,profileName,'mn_flags','',null,1);
   new_mn_flags:=_clex_flags_to_str(gclexmn_table,clexdef.mn_flags);
   new_mn_flags=_plugin_update_word_list(old_mn_flags,new_mn_flags);
   if (new_mn_flags=='') {
      _xmlcfg_delete_property(handle,profileNode,'mn_flags');
   } else {
      _xmlcfg_set_property(handle,profileNode,'mn_flags',new_mn_flags);
   }
   if (clexdef.mn_int_suffixes=='') {
      _xmlcfg_delete_property(handle,profileNode,'mn_int_suffixes');
   } else {
      _xmlcfg_set_property(handle,profileNode,'mn_int_suffixes',clexdef.mn_int_suffixes);
   }
   if (clexdef.mn_float_suffixes=='') {
      _xmlcfg_delete_property(handle,profileNode,'mn_float_suffixes');
   } else {
      _xmlcfg_set_property(handle,profileNode,'mn_float_suffixes',clexdef.mn_float_suffixes);
   }
   if (clexdef.mn_hex_suffixes=='') {
      _xmlcfg_delete_property(handle,profileNode,'mn_hex_suffixes');
   } else {
      _xmlcfg_set_property(handle,profileNode,'mn_hex_suffixes',clexdef.mn_hex_suffixes);
   }
   if (clexdef.mn_digit_separator_char=='') {
      _xmlcfg_delete_property(handle,profileNode,'mn_digit_separator_char');
   } else {
      _xmlcfg_set_property(handle,profileNode,'mn_digit_separator_char',clexdef.mn_digit_separator_char);
   }
   if (clexdef.inherit=='') {
      _xmlcfg_delete_property(handle,profileNode,'inherit');
   } else {
      _xmlcfg_set_property(handle,profileNode,'inherit',clexdef.inherit);
   }
   if (clexdef.ignore_text_after_start_col>0) {
      _xmlcfg_set_property(handle,profileNode,'ignore_text_after_start_col',clexdef.ignore_text_after_start_col);
   } else {
      _xmlcfg_delete_property(handle,profileNode,'ignore_text_after_start_col');
   }
   if ( !_clex_jinja_is_defaults(clexdef) ) {
      jinja_node:=_xmlcfg_add(handle,profileNode,VSXMLCFG_PROPERTY,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle,jinja_node,VSXMLCFG_PROPERTY_NAME,'jinja');
      _xmlcfg_set_attribute(handle,jinja_node,'enabled',clexdef.jinja_enabled)!=0;
      _xmlcfg_set_attribute(handle,jinja_node,'block_start_string',clexdef.jinja_block_start_string);
      _xmlcfg_set_attribute(handle,jinja_node,'block_end_string',clexdef.jinja_block_end_string);
      _xmlcfg_set_attribute(handle,jinja_node,'variable_start_string',clexdef.jinja_variable_start_string);
      _xmlcfg_set_attribute(handle,jinja_node,'variable_end_string',clexdef.jinja_variable_end_string);
      _xmlcfg_set_attribute(handle,jinja_node,'comment_start_string',clexdef.jinja_comment_start_string);
      _xmlcfg_set_attribute(handle,jinja_node,'comment_end_string',clexdef.jinja_comment_end_string);
      _xmlcfg_set_attribute(handle,jinja_node,'line_statement_prefix',clexdef.jinja_line_statement_prefix);
      _xmlcfg_set_attribute(handle,jinja_node,'line_comment_prefix',clexdef.jinja_line_comment_prefix);
   }
   

   COMMENT_TYPE comments[];comments=clexdef.comments;
   for (i:=0;i<comments._length();++i) {
      _clex_add_property_item(handle,profileNode,propery_to_node,comments[i]);
   }
   typeless k;
   for (k._makeempty();;) {
      CLEX_TAGDEF_TYPE *ptd=&clexdef.tagdef._nextel(k);
      if (k._isempty()) break;
      //CLEX_TAGDEF_TYPE *ptd=&clexdef.tagdef:[k];
      _str mlcomment_start=_plugin_escape_property(k);
      _str comment_keywords=ptd->comment_keywords;
      if (comment_keywords!='') {
         _str keyword_list=comment_keywords;
         for (;;) {
            parse keyword_list with auto mlckeyword keyword_list;
            if (mlckeyword=='') {
               break;
            }
            _str key=mlckeyword;
            if (!case_sensitive) key=lowcase(key);
            _str *pattrs=ptd->comment_attributes._indexin(key);
            name := VSXMLCFG_PROPERTY_SEPARATOR:+mlcomment_start:+VSXMLCFG_PROPERTY_SEPARATOR:+_plugin_escape_property(mlckeyword):+VSXMLCFG_PROPERTY_SEPARATOR;
            value := "";
            if (pattrs) {
               value=*pattrs;
            }
            _cc_set_property(handle,profileNode,propery_to_node,case_sensitive,name,value);
         }
      }

      comment_values:=ptd->comment_values;
      if (comment_values._varformat()==VF_HASHTAB) {
         typeless hi;
         for (hi._makeempty();;) {
            comment_values._nextel(hi);
            if (hi._isempty()) break;
            _str attr=comment_values:[hi];
            if (attr!='') {
               parse hi with attr '(' auto mlckeyword ')';
               name := VSXMLCFG_PROPERTY_SEPARATOR:+mlcomment_start:+VSXMLCFG_PROPERTY_SEPARATOR:+_plugin_escape_property(mlckeyword):+VSXMLCFG_PROPERTY_SEPARATOR:+_plugin_escape_property(attr);
               _cc_set_property(handle,profileNode,propery_to_node,case_sensitive,name,comment_values:[hi]);
            }
         }
      }
   }
   _plugin_set_profile(handle);
   _xmlcfg_close(handle);
}

static void _clex_add_item2(int handle,int attrs_node,COMMENT_TYPE (&comments)[],COMMENT_TYPE comment) {
   _str temp;
   temp=_xmlcfg_get_attribute(handle,attrs_node,'type');
   if (temp!='') comment.type=temp;
   temp=_xmlcfg_get_attribute(handle,attrs_node,'start');
   if (temp!='') comment.delim1=temp;

   comment.delim2=_xmlcfg_get_attribute(handle,attrs_node,'end');
   
   temp=_xmlcfg_get_attribute(handle,attrs_node,'start_col');
   if (isinteger(temp) && temp>=0) comment.startcol= (int)temp;
   temp=_xmlcfg_get_attribute(handle,attrs_node,'end_col');
   if (isinteger(temp) && temp>=0) comment.endcol= (int)temp;

   temp=_xmlcfg_get_attribute(handle,attrs_node,'end_start_col');
   if (isinteger(temp) && temp>=0) comment.end_startcol= (int)temp;
   temp=_xmlcfg_get_attribute(handle,attrs_node,'end_end_col');
   if (isinteger(temp) && temp>=0) comment.end_endcol= (int)temp;

   temp=_xmlcfg_get_attribute(handle,attrs_node,'order');
   if (isinteger(temp)) comment.order= (int)temp;

   temp=_xmlcfg_get_attribute(handle,attrs_node,'case_sensitive');
   if (temp:==0 || temp:==1) comment.case_sensitive= (int)temp;

   comment.start_color=_xmlcfg_get_attribute(handle,attrs_node,'start_color');
   comment.end_color=_xmlcfg_get_attribute(handle,attrs_node,'end_color');
   comment.color_to_eol=_xmlcfg_get_attribute(handle,attrs_node,'color_to_eol');
   comment.end_color_to_eol=_xmlcfg_get_attribute(handle,attrs_node,'end_color_to_eol');
   comment.escape_char=_xmlcfg_get_attribute(handle,attrs_node,'escape_char');
   comment.line_continuation_char=_xmlcfg_get_attribute(handle,attrs_node,'line_continuation_char');
   comment.doubles_char=_xmlcfg_get_attribute(handle,attrs_node,'doubles_char');
   comment.embedded_lexer=_xmlcfg_get_attribute(handle,attrs_node,'embedded_lexer');

   temp=_xmlcfg_get_attribute(handle,attrs_node,'flags');
   comment.orig_flags=temp;
   comment.flags=(CLEX_MATCH_FLAGS)_clex_str_to_flags(gclexmf_table,temp);
   temp=_xmlcfg_get_attribute(handle,attrs_node,'nest_start');
   if (temp!='') {
      comment.nesting=1;
      comment.nestingStart=temp;
      comment.nestingEnd=_xmlcfg_get_attribute(handle,attrs_node,'nest_end');
   }
   int iattrs_node=_xmlcfg_get_first_child(handle,attrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   if (iattrs_node>=0) {
      // check for attrs node with no attributes
      COMMENT_TYPE icomment;
      _init_comment(icomment);
      icomment.type=comment.type;
      while (iattrs_node>=0) {
         _clex_add_item2(handle,iattrs_node,comment.comments,icomment);
         iattrs_node=_xmlcfg_get_next_sibling(handle,iattrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
   }

   comments[comments._length()]=comment;
}
static _str _clex_flags_to_str(int (&flag_table):[], int flags) {
   result := "";
   foreach ( auto key => auto flag in flag_table) {
      if (flag & flags) {
         strappend(result,' 'key);
      }
   }
   return strip(result);
}
static int _clex_str_to_flags(int (&flag_table):[], _str value) {
   flags := 0;
   for (;;) {
      parse value with auto word value;
      if (word=='') break;
      int *pi=flag_table._indexin(word);
      if (pi) {
         flags|=*pi;
      }
   }
   return flags;
}
static void _clex_add_item(int handle,int property_node, COMMENT_TYPE (&comments)[],_str color, _str name) {

   COMMENT_TYPE comment;
   _init_comment(comment);
   comment.type=color;
   comment.delim1=name;

   int attrs_node=_xmlcfg_get_first_child(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   if (attrs_node>=0) {
      // check for attrs node with no attributes
      while (attrs_node>=0) {
         _clex_add_item2(handle,attrs_node,comments,comment);
         attrs_node=_xmlcfg_get_next_sibling(handle,attrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
   } else {
      comments[comments._length()]=comment;
   }
}
void _clex_load_profile(_str profileName,CLEXDEF &Lexer,int optionLevel=0) {
   _clex_init(Lexer);
   int handle=_plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,profileName,optionLevel);
   // Try loading a profile which should be ok
   if(handle<0) {
      _message_box(nls("Unable to load color coding profile '%s'",profileName));

   }
   profile_node:=_xmlcfg_get_document_element(handle);


   int node;
   node=_xmlcfg_get_first_child(handle,profile_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (node>=0) {
      _str name;
      name=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
      if (substr(name,1,1)==',') {
         LoadMLCKeyword(handle,node,Lexer);
         node=_xmlcfg_get_next_sibling(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         continue;
      }
      parse name with auto color (VSXMLCFG_PROPERTY_SEPARATOR) name;
      if (name!='') {
         _clex_add_item(handle,node,Lexer.comments,color,name);
      } else {
         if (color=='idchars') {
            Lexer.idchars=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='case_sensitive') {
            result:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
            if (isinteger(result)) {
               Lexer.case_sensitive=result?true:false;
            }
         } else if (color=='styles') {
            Lexer.styles=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='mn_flags') {
            temp:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
            Lexer.mn_flags=(CLEX_MATCH_NUMBER)_clex_str_to_flags(gclexmn_table,temp);
         } else if (color=='mn_int_suffixes') {
            Lexer.mn_int_suffixes=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='mn_float_suffixes') {
            Lexer.mn_float_suffixes=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='mn_hex_suffixes') {
            Lexer.mn_hex_suffixes=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='mn_digit_separator_char') {
            Lexer.mn_digit_separator_char=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='inherit') {
            Lexer.inherit=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         } else if (color=='ignore_text_after_start_col') {
            result:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
            if (isinteger(result) && result>0) {
               Lexer.ignore_text_after_start_col=(int)result;
            }
         } else if (color=='jinja') {
            Lexer.jinja_enabled=_xmlcfg_get_attribute(handle,node,'enabled','0')!=0;
            Lexer.jinja_block_start_string=_xmlcfg_get_attribute(handle,node,'block_start_string','{%');
            Lexer.jinja_block_end_string=_xmlcfg_get_attribute(handle,node,'block_end_string','%}');
            Lexer.jinja_variable_start_string=_xmlcfg_get_attribute(handle,node,'variable_start_string','{{');
            Lexer.jinja_variable_end_string=_xmlcfg_get_attribute(handle,node,'variable_end_string','}}');
            Lexer.jinja_comment_start_string=_xmlcfg_get_attribute(handle,node,'comment_start_string','{#');
            Lexer.jinja_comment_end_string=_xmlcfg_get_attribute(handle,node,'comment_end_string','#}');
            Lexer.jinja_line_statement_prefix=_xmlcfg_get_attribute(handle,node,'line_statement_prefix','#');
            Lexer.jinja_line_comment_prefix=_xmlcfg_get_attribute(handle,node,'line_comment_prefix','##');
         }
      }
      node=_xmlcfg_get_next_sibling(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
}

static void ReplaceStylesLine(_str Styles)
{
   top();up();
   int status=search('^styles( |\t)@=','ri@');
   if (!status) {
      _delete_line();
   }

   //5:10pm 7/12/1999
   //Have to be sure that the styles come before the keywords....
   //All the keywords are inserted first, so this is cool.
   top();up();
   status=search('^keywords( |\t)@=','ri@');
   if (status) {
      top();
      int status1=search('^idchars( |\t)@=','ri@');
      line1 := p_line;
      int status2=search('^case-sensitive( |\t)@=','ri@');
      line2 := p_line;
      if (!status1 && !status2) {
         p_line=max(line1,line2);
      }
   }else{
      up();
   }
   if (Styles._varformat()!=VF_EMPTY) {
      insert_line('styles='Styles);
   }
}
static bool save_last_settings()
{
   if (LAST_LEXER_NAME() == NO_LEXER) return false;
   CLEXDEF *pclexdef=&gnew_keyword_table:[LAST_LEXER_NAME()];

   // save all the good stuff in the new keyword table
   pclexdef->idchars=ctlstart_idchars.p_text' 'ctlfollow_idchars.p_text;
   pclexdef->case_sensitive=ctlcase_sensitive.p_value!=0;
   value:=ctlignore_text_start_col.p_text;
   if (isinteger(value) && value>0) {
      pclexdef->ignore_text_after_start_col=(int)value;
   } else {
      pclexdef->ignore_text_after_start_col=0;
   }
   //pclexdef->filename=CUR_LEXER_FILE;

   // save styles, comments, numbers, language specific
   _str orig_styles=pclexdef->styles;
   pclexdef->styles=get_styles();
   // if the styles are not equal, add this one to the mod list
   if (!cc_styles_eq(pclexdef->styles,orig_styles)) {
      AddLexerToModList();
   }

   CLEX_MATCH_NUMBER orig_mn_flags=pclexdef->mn_flags;
   pclexdef->mn_flags=get_mn_flags();
   if (pclexdef->mn_flags!=orig_mn_flags) {
      AddLexerToModList();
   }
   pclexdef->mn_digit_separator_char=ctldigit_separator_char.p_text;
   pclexdef->mn_int_suffixes=ctlint_suffixes.p_text;
   pclexdef->mn_float_suffixes=ctlfloat_suffixes.p_text;
   pclexdef->mn_hex_suffixes=ctlhex_suffixes.p_text;


   // finally, update the tags, keywords
   cc_update_tags(false);
#if 0
   STRARRAYPTR keyword_list = GetLastTypeKeywordList();
   if (keyword_list != null) {
      _ctlkw_list.make_keyword_list(*keyword_list);
   }
#endif

   return(false);
}
void ctljinja.lbutton_up() {

   if (save_last_settings()) return;
   CLEXDEF *pclexdef=&gnew_keyword_table:[LAST_LEXER_NAME()];
   result := show("-modal _textbox_form",
                 "Jinja Settings", // Form caption
                 0,                // Flags
                 0,                // Use default textbox width
                 "",               // Help item
                 "Save Settings,Cancel:_cancel\t",
                 "",               // Retrieve Name
                 "-CHECKBOX Enable:":+pclexdef->jinja_enabled,
                 "Block start string:"pclexdef->jinja_block_start_string,
                 "Block end string:"pclexdef->jinja_block_end_string,
                    "Variable start string:"pclexdef->jinja_variable_start_string,
                    "Variable end string:"pclexdef->jinja_variable_end_string,
                    "Comment start string:"pclexdef->jinja_comment_start_string,
                    "Comment end string:"pclexdef->jinja_comment_end_string,
                    "Line statement prefix:"pclexdef->jinja_line_statement_prefix,
                    "Line comment prefix:"pclexdef->jinja_line_comment_prefix
                 );
   if (result==1) {
      if (pclexdef->jinja_block_start_string!=_param2) {
         AddLexerToModList();
         pclexdef->jinja_block_start_string=_param2;
      }
      if (pclexdef->jinja_block_end_string!=_param3) {
         AddLexerToModList();
         pclexdef->jinja_block_end_string=_param3;
      }
      if (pclexdef->jinja_variable_start_string!=_param4) {
         AddLexerToModList();
         pclexdef->jinja_variable_start_string=_param4;
      }
      if (pclexdef->jinja_variable_end_string!=_param5) {
         AddLexerToModList();
         pclexdef->jinja_variable_end_string=_param5;
      }
      if (pclexdef->jinja_comment_start_string!=_param6) {
         AddLexerToModList();
         pclexdef->jinja_comment_start_string=_param6;
      }
      if (pclexdef->jinja_comment_end_string!=_param7) {
         AddLexerToModList();
         pclexdef->jinja_comment_end_string=_param7;
      }
      if (pclexdef->jinja_line_statement_prefix!=_param8) {
         AddLexerToModList();
         pclexdef->jinja_line_statement_prefix=_param8;
      }
      if (pclexdef->jinja_line_comment_prefix!=_param9) {
         AddLexerToModList();
         pclexdef->jinja_line_comment_prefix=_param9;
      }
      if (pos('yaml',pclexdef->styles) || pos('markdown',pclexdef->styles)) {
         orig_jinja_enabled:=pclexdef->jinja_enabled;
         pclexdef->jinja_enabled=false;
         if (_param1 && !_clex_jinja_is_defaults(*pclexdef)) {
            _message_box('Changing the default Jinja settings for this language might not work as well as using the default settings');
         }
         pclexdef->jinja_enabled=orig_jinja_enabled;
      }
      if (pclexdef->jinja_enabled!=_param1) {
         AddLexerToModList();
         pclexdef->jinja_enabled=_param1;
      }
   }
}
int _ctlok.lbutton_up()
{
   if (_cc_form_apply()) {
      p_active_form._delete_window(0);
      return(0);
   }

   return (1);
}

static void delete_lexers(_str (&list):[]) {
   foreach (auto key=>auto value in list) {
      _plugin_delete_profile(VSCFGPACKAGE_COLORCODING_PROFILES,key);
   }
}

void _ctldelete_lexer.lbutton_up()
{
   lexername := _ctllexer_list.p_text;
   if (lexername!='') {
      int result;
      // If there is a built-in profile
      if (_plugin_has_builtin_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexername)) {
         result=_message_box(nls("Are you sure that you wish to reset the lexer '%s'",lexername),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      } else {
         result=_message_box(nls("Are you sure that you wish to delete the lexer '%s'",lexername),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      }
      if (result!=IDYES) return;
      if (_plugin_has_builtin_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexername)) {
         _clex_load_profile(_ctllexer_list.p_text,gnew_keyword_table:[_ctllexer_list.p_text],1 /* load with system profile settings */);
         // Throw away current settings
         LAST_LEXER_NAME(NO_LEXER);
         _ctllexer_list.call_event(CHANGE_SELECTED,_ctllexer_list,on_change,'W');
         AddLexerToModList();
         _ctldelete_lexer.p_enabled=false;
      } else {
         _ctllexer_list._lbdelete_item();
         _ctllexer_list.p_text=_ctllexer_list._lbget_text();
         _GetDialogInfoHtPtr(DELETE_LEXER_HASHTAB)->:[lowcase(lexername)]=1;
         gnew_keyword_table._deleteel(lexername);
      }
   }
}
_ctlcolors.lbutton_up()
{
   config('_color_form', 'D');
}

void _ctlimport.lbutton_up()
{
   if (_cc_form_is_modified()) {
      result:=_message_box("Changes must be saved before importing profiles.\n\nContinue?",'',MB_YESNO);
      if (result==IDCANCEL || result==IDNO) return;
      _cc_form_apply();
   }
   typeless result=_OpenDialog(
      '-modal',
      'Open Color Coding Config File', '*.cfg.xml',
      "Color Coding Config Files (*.cfg.xml;*.vlx),All Files ("ALLFILES_RE")",
      OFN_FILEMUSTEXIST,  //OFN_FILEMUSTEXIST can create new file.
      '',
      '',
      '',
      'colorcoding_profile_cfgxml' // Retrieve name
      );

   if (result=='') return;
   //save_last_settings(); Already saved changes.
   status:=p_window_id.cload(result);
   if (status) {
      return;
   }
   _message_box('profile(s) imported');
   // Reload all lexers
   gnew_keyword_table._makeempty();
   refresh_lexer_list=1;
   ERROR_ON_LEXER_NAME_CHANGE(1);
   orig_lexer:=_ctllexer_list.p_text;
   _ctllexer_list._lbclear();
   maybe_refresh_lexer_list();
   ERROR_ON_LEXER_NAME_CHANGE(0);
   LAST_LEXER_NAME(NO_LEXER);
   _ctllexer_list.p_text = orig_lexer;
#if 0

   last_lexer_name := "";
   while (result != '') {
      int loadlexer = IDYES;
      lexername := "";
      parse result with lexername "\n" result;
      if (gnew_keyword_table._indexin(lexername)) {
         loadlexer = _message_box(nls("Replace existing lexer definition '%s'?", lexername),
                                  "Replace",
                                  MB_YESNOCANCEL|MB_ICONQUESTION);
         if (loadlexer == IDCANCEL) break;
      }
      if (loadlexer == IDYES) {
         orig_wid := p_window_id;
         _clex_load_profile(lexername, gnew_keyword_table:[lexername]);
         _ctllexer_list._lbadd_item_no_dupe(lexername, '', LBADD_SORT);
         p_window_id = orig_wid;

         _str temp:[];
         if (_GetDialogInfoHtPtr(MODIFIED_LEXER_HASHTAB)->_varformat() == VF_HASHTAB) {
            temp = MODIFIED_LEXER_HASHTAB;
         }
         temp:[lexername] = 1;
         MODIFIED_LEXER_HASHTAB = temp;
         last_lexer_name = lexername;
      }
   }
   if (last_lexer_name != '') {
      LAST_LEXER_NAME(NO_LEXER);
      _ctllexer_list.p_text = last_lexer_name;
   }
#endif
}


static void append_styles(_str &line) {
   int first_child,child;
   first_child=child=p_window_id;
   for (;;) {
      if ((child.p_object==OI_CHECK_BOX || child.p_object==OI_RADIO_BUTTON) && child.p_value && child.p_name!='ctluseschema') {
         strappend(line,' 'substr(child.p_name,4));
      }
      child=child.p_next;
         
      if (child==first_child) break;
   }
}
static _str get_styles() {
   line := "";
   ctlperl.append_styles(line);
   ctllinenum.append_styles(line);
   ctljavadoc.append_styles(line);
   _str OtherStyles[];
   OtherStyles=OTHER_STYLES_TABLE();
   int i;
   for (i=0;i<OtherStyles._length();++i) {
      strappend(line,' 'OtherStyles[i]);
   }
   return line;
}
static CLEX_MATCH_NUMBER get_mn_flags() {
   line := "";
   ctldigit_int.append_styles(line);
   return (CLEX_MATCH_NUMBER)_clex_str_to_flags(gclexmn_table,line);
}
static void cc_prepare_numbers_tab(_str lexername) {
   // Clear the check boxes on this tab.
   ctldigit_int.cc_clear_all_check_boxes();
   CLEXDEF *pclexdef= &gnew_keyword_table:[lexername];
   CLEX_MATCH_NUMBER iflags=pclexdef->mn_flags;
   _str line=_clex_flags_to_str(gclexmn_table,iflags);

   for (;;) {
      cur := "";
      parse line with cur line;
      if (cur=='') break;
      cur=lowcase(cur);
      wid:=_find_control('ctl'cur);
      if (wid) {
         wid.p_value=1;
      }
   }
   ctldigit_separator_char.p_text=pclexdef->mn_digit_separator_char;
   ctlint_suffixes.p_text=pclexdef->mn_int_suffixes;
   ctlfloat_suffixes.p_text=pclexdef->mn_float_suffixes;
   ctlhex_suffixes.p_text=pclexdef->mn_hex_suffixes;

   ctldote_float.p_enabled=ctld_exponent.p_enabled=(ctldigit_float.p_value!=0);
   ctldotp_float.p_enabled=(ctlzerox_p_float.p_value!=0);
}
static void cc_clear_all_check_boxes() {
   int first_child,child;
   first_child=child=p_window_id;
   for (;;) {
      if (child.p_object==OI_CHECK_BOX) {
         child.p_value=0;
      }
      child=child.p_next;
         
      if (child==first_child) break;
   }
}
static void cc_prepare_language_tab(_str lexername) {
   ctllinenum.p_value=0;
   ctlxml_literals.p_value=0;
   ctlhere_document.p_value=0;
   ctlidparenfunction.p_value=0;
   ctlpackageimport.p_value=0;
   ctlppkeywordsanywhere.p_value=0;
   ctlidstartnum.p_value=0;
   ctleof.p_value=0;
   ctlcolor_inactive_cpp.p_value=0;
   ctljavadoc.p_value=0;
   ctlxmldoc.p_value=0;
   ctldoxygen.p_value=0;
   ctlblade.p_value=0;
   ctlos390asm_flow.p_value=0;
   ctlperl.cc_clear_all_check_boxes();

   orig_view_id := p_window_id;
   //p_active_form.p_caption='Styles for 'lexername;
   _str OtherStyleTable[];
   if (gnew_keyword_table:[lexername].styles._varformat()!=VF_EMPTY) {
      _str line=gnew_keyword_table:[lexername].styles;
      for (;;) {
         cur := "";
         parse line with cur line;
         if (cur=='') break;
         cur=lowcase(cur);
         wid:=_find_control('ctl'cur);
         if (wid) {
            wid.p_value=1;
         } else {
            OtherStyleTable[OtherStyleTable._length()]=cur;
         }
      }
      /*if (!ctlperl.p_value && !ctlpython.p_value && !ctltcl.p_value && !ctlruby.p_value && !ctllua.p_value &&
          !ctldlang.p_value && !ctlhtml.p_value && !ctlxml.p_value && !ctlcics.p_value && !ctlmodel204.p_value && !ctlos390asm.p_value &&
          !ctlcobol.p_value && !ctljcl.p_value && !ctlprogress.p_value && !ctlverilog.p_value) {
         ctlother.p_value=1;
      } */
   }else{
      //Taking out this message because there is no styles information if the user
      //is starting a new lexer
      //_message_box(nls("No styles information loaded."));
   }
   OTHER_STYLES_TABLE(OtherStyleTable);

   ctlos390asm_flow.p_enabled=ctlos390asm.p_value!=0;
}

static void _remove_array_duplicates(_str (&array)[]) {
   if (!array._length()) return;
   _str previous=array[0];
   for (i:=1;i<array._length();++i) {
      if (previous!=array[i]) {
         previous=array[i];
      } else {
         array._deleteel(i,1);
         --i;
      }
   }
}
static bool cc_styles_eq(_str style1, _str style2)
{
   // split the styles into arrays
   _str sa1[], sa2[];
   split(strip(style1), ' ', sa1);
   split(strip(style2), ' ', sa2);

   sa1._sort();
   _remove_array_duplicates(sa1);
   sa2._sort();
   _remove_array_duplicates(sa2);
   if (sa1._length()!=sa2._length()) {
      return(false);
   }
   int i,n=sa1._length();
   for (i=0; i<n; ++i) {
      if (!strieq(sa1[i],sa2[i])) {
         return(false);
      }
   }
   return(true);
}

static int ArrayComp(var one,var two)
{
   if (one._length()!=two._length()) {
      return(0);
   }
   int i;
   for (i=0;i<one._length();++i) {
      if (one[i]!=two[i]) {
         return(0);
      }
   }
   return(1);
}

static int _cc_add_tree_item(int parent,COMMENT_TYPE (&comments)[],int i) {
   text:=_cc_convert_to_dlg_color_name(comments[i].type)"\t"comments[i].delim1"\t"comments[i].delim2;
   child:=_TreeAddItem(parent,text,TREE_ADD_AS_CHILD,0,0,(comments[i].comments._length())?TREE_NODE_EXPANDED:TREE_NODE_LEAF);
   _cc_add_tree_items(child,comments[i].comments);
   _str line=(typeless)&comments' '(typeless)&comments[i];
   _TreeSetUserInfo(child,line);
   return child;
}
static void _cc_add_tree_items(int parent,COMMENT_TYPE (&comments)[]) {
   len := comments._length();
   for (i:=0;i<len;++i) {
      _cc_add_tree_item(parent,comments,i);
   }
}
static void cc_enabled_nesting() {
   ctlnest_start.p_enabled = ctlnest_end.p_enabled = ctlnest_start_label.p_enabled = ctlnest_end_label.p_enabled = (ctlnesting.p_value != 0);
}
static void cc_set_token_enable() {
   index:=ctltree1._TreeGetFirstChildIndex(0);
   enable := true;
   if (index<0) {
      enable=false;
   }
   ctldelete.p_enabled=enable;
   ctltype.p_enabled=ctltype_label.p_enabled=enable;
   ctltoken_case_sensitive.p_enabled=enable;
   ctlstart_delim.p_enabled=ctlstart_delim_label.p_enabled=ctlstart_delim_search.p_enabled=enable;
   ctlend_delim.p_enabled=ctlend_delim_label.p_enabled=ctlend_delim_search.p_enabled=enable;
   ctlcolor_to_eol.p_enabled=ctlcolor_to_eol_label.p_enabled=enable;
   ctlend_color_to_eol.p_enabled=ctlend_color_to_eol_label.p_enabled=enable;
   ctlmultiline.p_enabled=ctlmultiline_label.p_enabled=enable;
   ctldoubles_char.p_enabled=ctldoubles_char_label.p_enabled=enable;
   ctlescape_char.p_enabled=ctlescape_char_label.p_enabled=enable;
   ctlline_continuation_char.p_enabled=ctlline_continuation_char_label.p_enabled=enable;
   ctlnesting.p_enabled=ctlnest_start.p_enabled=ctlnest_start_label.p_enabled=ctlnest_end.p_enabled=ctlnest_end_label.p_enabled=enable;
   ctlfirst_non_blank.p_enabled=enable;
   ctlcheck_first.p_enabled=enable;
   ctlstart_color.p_enabled=ctlstart_color_label.p_enabled=enable;
   ctlend_color.p_enabled=ctlend_color_label.p_enabled=enable;
   ctlstart_col.p_enabled=ctlstart_col_label.p_enabled=enable;
   ctlend_col.p_enabled=ctlend_col_label.p_enabled=enable;
   ctlorder.p_enabled=ctlorder_label.p_enabled=enable;
   ctlembedded_profile.p_enabled=ctlembedded_profile_label.p_enabled=enable;
   ctlembedded_prefix_match.p_enabled=enable;
   ctlembedded_end_is_token.p_enabled=enable;
   ctlapply_multiline_at_eol.p_enabled=enable;
   ctlend_embedded_at_bol_if_possible.p_enabled=enable;
   ctlembedded_color_style_label.p_enabled=ctlembedded_color_style.p_enabled=enable;
}
static void cc_fill_profile_names() {
   _lbclear();
   _str profileNames[];
   _plugin_list_profiles(VSCFGPACKAGE_COLORCODING_PROFILES,profileNames);
   for (j:=0;j<profileNames._length();++j) {
      _lbadd_item(profileNames[j]);
   }
}
static void cc_fill_search_combo() {
   _lbadd_item('Plain text search');
   _lbadd_item('Perl regex');
   _lbadd_item('SlickEdit regex');
}
static void _cc_set_search(bool doEnd) {
   CLEX_MATCH_FLAGS flag=CLEXMF_NONE;
   if (strieq(p_text,"SlickEdit regex")) {
      flag=(doEnd)?CLEXMF_END_REGEX:CLEXMF_REGEX;
   } else if (strieq(p_text,"Perl regex")) {
      flag=(doEnd)?CLEXMF_END_PERLRE:CLEXMF_PERLRE;
   }
   COMMENT_TYPE *pcomment=get_item_pointer();
   if (doEnd) {
      pcomment->flags&= ~(CLEXMF_END_PERLRE|CLEXMF_END_REGEX);
   } else {
      pcomment->flags&= ~(CLEXMF_PERLRE|CLEXMF_REGEX);
   }
   pcomment->flags|= flag;
   AddLexerToModList();
}
static void cc_fill_color_combo(bool add_none=false) {
   if (add_none) {
      _lbadd_item(NULL_COLOR);
   }
   foreach ( auto xml_color => auto dlg_color in gcolor_to_dlg_color  ) {
      _lbadd_item(dlg_color);
   }
   _lbsort('i');
}
static void _cc_fill_multiline_combo() {
   _lbadd_item("Color to end across multiple lines");
   _lbadd_item("Color start as Other color");
   _lbadd_item("Color to end of line");
}
static void _cc_set_multiline_from_flags(COMMENT_TYPE *pcomment) {
   if (pcomment->flags&CLEXMF_MULTILINE) {
      ctlmultiline.p_text="Color to end across multiple lines";
   } else if (pcomment->flags&CLEXMF_TERMINATE) {
      ctlmultiline.p_text="Color start as Other color";
   } else {
      ctlmultiline.p_text="Color to end of line";
   }
}
static void _cc_set_multiline() {
   CLEX_MATCH_FLAGS flag=CLEXMF_NONE;
   if (strieq(p_text,"Color to end across multiple lines")) {
      flag=CLEXMF_MULTILINE;
   } else if (strieq(p_text,"Color start as Other color")) {
      flag=CLEXMF_TERMINATE;
   }
   COMMENT_TYPE *pcomment=get_item_pointer();
   pcomment->flags&= ~(CLEXMF_TERMINATE|CLEXMF_MULTILINE);
   pcomment->flags|= flag;
   ctlcolor_to_eof.p_value=(pcomment->flags&CLEXMF_MULTILINE);
   cc_enabled_multiline(pcomment);
   AddLexerToModList();
}
static void _cc_fill_embedded_color_style_combo() {
   _lbadd_item("Don't color as embedded if possible");
   _lbadd_item("Color as embeded if profile found");
   _lbadd_item("Color as embedded");
}
static void _cc_set_embedded_color_style() {
   CLEX_MATCH_FLAGS flag=CLEXMF_NONE;
   if (strieq(p_text,"Don't color as embedded if possible")) {
      flag=CLEXMF_DONT_COLOR_AS_EMBEDDED_IF_POSSIBLE;
   } else if (strieq(p_text,"Color as embeded if profile found")) {
      flag=CLEXMF_COLOR_AS_EMBEDDED_IF_FOUND;
   }
   COMMENT_TYPE *pcomment=get_item_pointer();
   pcomment->flags&= ~(CLEXMF_DONT_COLOR_AS_EMBEDDED_IF_POSSIBLE|CLEXMF_COLOR_AS_EMBEDDED_IF_FOUND);
   pcomment->flags|= flag;
   AddLexerToModList();
}
static void cc_enabled_multiline(COMMENT_TYPE *pcomment) {
   has_end := length(pcomment->delim2)!=0;
   color_continues_after_start := has_end || (pcomment->flags & CLEXMF_MULTILINE) || (pcomment->color_to_eol!='');
   ctlend_delim_search.p_enabled=has_end;
   ctlend_color_to_eol_label.p_enabled=ctlend_color_to_eol.p_enabled=has_end;
   ctlend_color_label.p_enabled=ctlend_color.p_enabled=has_end;
   ctlend_col_label.p_enabled=ctlend_start_col.p_enabled=ctlend_end_col.p_enabled=has_end;

   //ctlcolor_to_eof.p_x=ctlmultiline_label..p_x;ctlcolor_to_eof.p_y=ctlmultiline_label..p_y;
   ctlmultiline_label.p_visible=ctlmultiline.p_visible=has_end;
   ctlcolor_to_eof.p_visible=!has_end;
   ctldoubles_char_label.p_enabled=ctldoubles_char.p_enabled=color_continues_after_start;
   ctlescape_char_label.p_enabled=ctlescape_char.p_enabled=color_continues_after_start;

   ctlline_continuation_char_label.p_enabled=ctlline_continuation_char.p_enabled= !(pcomment->flags & CLEXMF_MULTILINE) && (pcomment->color_to_eol!='' || has_end);

   //ctlnesting.p_enabled=ctlnest_start_label.p_enabled=ctlnest_start.p_enabled=ctlnest_end_label.p_enabled=ctlnest_end.p_enabled=color_continues_after_start;

   ctlembedded_profile_label.p_enabled=ctlembedded_profile.p_enabled=color_continues_after_start;
   ctlapply_multiline_at_eol.p_enabled=(pcomment->flags & CLEXMF_MULTILINE)?true:false;
   bool embeded_options_enabled=color_continues_after_start && length(pcomment->embedded_lexer)!=0;

   ctlembedded_prefix_match.p_enabled=embeded_options_enabled;
   ctlembedded_end_is_token.p_enabled=embeded_options_enabled;
   ctlend_embedded_at_bol_if_possible.p_enabled=embeded_options_enabled;
   ctlembedded_color_style_label.p_enabled=ctlembedded_color_style.p_enabled=embeded_options_enabled;
}
static void cc_prepare_token() {
   COMMENT_TYPE *pcomment=get_item_pointer();
   ctltype.p_text=_cc_convert_to_dlg_color_name(pcomment->type);
   ctltoken_case_sensitive.p_value=pcomment->case_sensitive;
   ctlstart_delim.p_text=pcomment->delim1;
   if (pcomment->flags&CLEXMF_REGEX) {
      ctlstart_delim_search.p_text="SlickEdit regex";
   } else if (pcomment->flags&CLEXMF_PERLRE) {
      ctlstart_delim_search.p_text="Perl regex";
   } else {
      ctlstart_delim_search.p_text="Plain text search";
   }
   ctlend_delim.p_text=pcomment->delim2;
   if (pcomment->flags&CLEXMF_END_REGEX) {
      ctlend_delim_search.p_text="SlickEdit regex";
   } else if (pcomment->flags&CLEXMF_END_PERLRE) {
      ctlend_delim_search.p_text="Perl regex";
   } else {
      ctlend_delim_search.p_text="Plain text search";
   }
   ctlcolor_to_eol.p_text= _cc_convert_to_dlg_color_name(pcomment->color_to_eol);
   ctlend_color_to_eol.p_text= _cc_convert_to_dlg_color_name(pcomment->end_color_to_eol);
   _cc_set_multiline_from_flags(pcomment);
   ctlcolor_to_eof.p_value=(pcomment->flags&CLEXMF_MULTILINE);
   cc_enabled_multiline(pcomment);


   ctldoubles_char.p_text=pcomment->doubles_char;
   ctlescape_char.p_text=pcomment->escape_char;
   ctlline_continuation_char.p_text=pcomment->line_continuation_char;
   ctlnesting.p_value=pcomment->nesting;ctlnest_start.p_text=pcomment->nestingStart; ctlnest_end.p_text=pcomment->nestingEnd;
   ctlfirst_non_blank.p_value=(pcomment->flags&CLEXMF_FIRST_NON_BLANK);
   ctlcheck_first.p_value=(pcomment->flags&CLEXMF_CHECK_FIRST);
   ctlstart_color.p_text=_cc_convert_to_dlg_color_name(pcomment->start_color);
   ctlend_color.p_text=_cc_convert_to_dlg_color_name(pcomment->end_color);
   ctlstart_col.p_text=(pcomment->startcol>0)?pcomment->startcol:'';
   ctlend_col.p_text=(pcomment->endcol>0)?pcomment->endcol:'';
   ctlorder.p_text=pcomment->order;
   ctlembedded_profile.p_text=pcomment->embedded_lexer;
   ctlembedded_prefix_match.p_value=(pcomment->flags&CLEXMF_EMBEDDED_LEXER_PREFIX_MATCH);
   ctlembedded_end_is_token.p_value=(pcomment->flags&CLEXMF_EMBEDDED_END_IS_TOKEN);
   ctlapply_multiline_at_eol.p_value=(pcomment->flags&CLEXMF_APPLY_MULTILINE_AT_EOL);
   ctlend_embedded_at_bol_if_possible.p_value=(pcomment->flags&CLEXMF_END_EMBEDED_AT_BOL_IF_POSSIBLE);
   if (pcomment->flags&CLEXMF_DONT_COLOR_AS_EMBEDDED_IF_POSSIBLE) {
      ctlembedded_color_style.p_text="Don't color as embedded if possible";
   } else if (pcomment->flags&CLEXMF_COLOR_AS_EMBEDDED_IF_FOUND) {
      ctlembedded_color_style.p_text="Color as embeded if profile found";
   } else {
      ctlembedded_color_style.p_text="Color as embedded";
   }
   cc_enabled_nesting();
   // check_first and first_non_blank are not supported for sub items
   parent:=ctltree1._TreeGetParentIndex(ctltree1._TreeCurIndex());
   ctlcheck_first.p_enabled=ctlfirst_non_blank.p_enabled=(parent==TREE_ROOT_INDEX);
}
static void cc_prepare_tokens_tab(_str lexername) {
   CLEXDEF *pclexdef= &gnew_keyword_table:[lexername];
   ctltree1._TreeDelete(0,'C');
   ctltree1._TreeSetUserInfo(0,'');
   ctltree1._cc_add_tree_items(0,pclexdef->comments);
   ctltree1._TreeSortCaption(TREE_ROOT_INDEX,'I');

   index:=ctltree1._TreeGetFirstChildIndex(0);
   cc_set_token_enable();
   if (index<0) {
      return;
   }
   ctltree1._TreeSetCurIndex(index);
   cc_prepare_token();
}

/**
 * Initializes a COMMENT_TYPE to all the default values.
 * 
 * @param COMMENT_TYPE& comment 
 */
void _init_comment(COMMENT_TYPE &comment) {
   comment.type=0;
   comment.delim1='';
   comment.delim2='';
   comment.startcol=0;comment.endcol=0;
   comment.end_startcol=0;comment.end_endcol=0;
   comment.order=0;
   comment.case_sensitive=2;
   comment.start_color='';
   comment.end_color='';
   comment.color_to_eol='';
   comment.end_color_to_eol='';
   comment.escape_char='';
   comment.line_continuation_char='';
   comment.doubles_char='';
   comment.embedded_lexer='';
   comment.flags=CLEXMF_NONE;

   comment.nesting=0;
   comment.nestingStart='';
   comment.nestingEnd='';
   comment.orig_flags='';
   comment.comments._makeempty();
}

static bool isvalid_column() {
   if (p_text=='') {
      return true;
   }
   if (!isinteger(p_text)) {
      return false;
   }
   return length(p_text)>=1;
}

/**
 * Goes through and validates changes made to the lexer.  If
 * anything needs to be fixed, we return the tab number with the
 * problem.  Otherwise, we return -1.
 *
 * @return int          tab number that failed validation
 */
static int validate_lexer() {
   if (length(ctlescape_char.p_text)>=2) {
      ctlescape_char._text_box_error("Length of character must be 1 byte. Unicode characters not yet supported.");
      return 1;
   }
   if (length(ctlline_continuation_char.p_text)>=2) {
      ctlline_continuation_char._text_box_error("Length of character must be 1 byte. Unicode characters not yet supported.");
      return 1;
   }
   if (!ctlstart_col.isvalid_column()) {
      ctlsstab.p_ActiveTab=CLEXTAB_TOKENS;
      ctlsstab2.p_ActiveTab=CLEXTAB_TOKENS_MORE;
      ctlstart_col._text_box_error("Column must be a valid integer >=1");
      return 1;
   }
   if (!ctlend_col.isvalid_column()) {
      ctlsstab.p_ActiveTab=CLEXTAB_TOKENS;
      ctlsstab2.p_ActiveTab=CLEXTAB_TOKENS_MORE;
      ctlend_col._text_box_error("Column must be a valid integer >=1");
      return 1;
   }
   if (!ctlend_start_col.isvalid_column()) {
      ctlsstab.p_ActiveTab=CLEXTAB_TOKENS;
      ctlsstab2.p_ActiveTab=CLEXTAB_TOKENS_MORE;
      ctlend_start_col._text_box_error("Column must be a valid integer >=1");
      return 1;
   }
   if (!ctlend_end_col.isvalid_column()) {
      ctlsstab.p_ActiveTab=CLEXTAB_TOKENS;
      ctlsstab2.p_ActiveTab=CLEXTAB_TOKENS_MORE;
      ctlend_end_col._text_box_error("Column must be a valid integer >=1");
      return 1;
   }
   if (ctlorder.p_text!='' && !isinteger(ctlorder.p_text)) {
      ctlsstab.p_ActiveTab=CLEXTAB_TOKENS;
      ctlsstab2.p_ActiveTab=CLEXTAB_TOKENS_MORE;
      ctlend_end_col._text_box_error("Column must be a valid integer >=1");
      return 1;
   }
   return 0;
}



//defeventtab _cc_comment_ml_form;
void _ctltag_list.on_change(int reason)
{
   if (IGNORE_TAG_LIST_ON_CHANGE()) return;

   if (reason==CHANGE_SELECTED) {
      cc_update_tags();
      cc_prepare_attrs(_ctltag_list._lbget_seltext());
      CUR_TAG_NAME(_ctltag_list._lbget_seltext());
   }
}
void _ctlattr_list.on_change(int reason)
{
   if (IGNORE_TAG_LIST_ON_CHANGE()) return;

   if (reason==CHANGE_SELECTED) {
      cc_update_tags();
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
      CUR_ATTR_NAME(_ctlattr_list._lbget_seltext());
   }
}
_ctlnew_tag.lbutton_up()
{
   first_word := "";
   word := "";
   _str name=show('-modal _textbox_form',
             'Enter New Tags/Elements',
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New Tags/Elements:' //prompt
             );
   if (name!='') {
      //cc_update_tag();
      AddLexerToModList();
      //say('mod15');
      name=_param1;
      wid := p_window_id;p_window_id=_control _ctltag_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      _lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
      _ctltag_list.call_event(CHANGE_SELECTED,_ctltag_list,ON_CHANGE,'W');
      //cc_prepare_attrs(_ctltag_list._lbget_seltext());
      //CUR_TAG_NAME(_ctltag_list._lbget_seltext());
      _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
#if 0
      _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
      _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
#endif
   }
}
_ctltag_list.DEL()
{
   if (_ctldelete_tag.p_enabled) {
      _ctldelete_tag.call_event(_ctldelete_tag,LBUTTON_UP,'W');
   }
}
_ctldelete_tag.lbutton_up()
{
   mou_hour_glass(true);
   if (_ctltag_list.p_Nofselected==1) {
      _ctltag_list._lbdelete_item();
      _ctltag_list._lbselect_line();
   } else {
      ff := true;
      p_window_id=_control _ctltag_list;
      while (!_lbfind_selected(ff)) {
         _lbdelete_item();
         _lbup();
         ff=false;
      }
      _lbselect_line();
   }
   AddLexerToModList();
   //say('mod16');
   _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctlnew_value.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
   cc_prepare_attrs(_ctltag_list._lbget_seltext());
   CUR_TAG_NAME(_ctltag_list._lbget_seltext());
   mou_hour_glass(false);
}

_ctlnew_attr.lbutton_up()
{
   word := "";
   first_word := "";
   _str keyword=CUR_TAG_NAME();
   _str name=show('-modal _textbox_form',
             'Enter New Attributes for 'keyword,
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New Attributes:' //prompt
             );
   if (name!='') {
      cc_update_tags();
      AddLexerToModList();
      //say('mod17');
      name=_param1;
      wid := p_window_id;p_window_id=_control _ctlattr_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      //_lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
      _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
      CUR_ATTR_NAME(_ctlattr_list._lbget_seltext());
      CUR_ATTR_VALUES('');
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
   }
}
_ctlattr_list.DEL()
{
   if (_ctldelete_attr.p_enabled) {
      _ctldelete_attr.call_event(_ctldelete_attr,LBUTTON_UP,'W');
   }
}
static CLEX_TAGDEF_TYPE *cc_get_tagdef(CLEXDEF &clexdef) {
    CLEX_TAGDEF_TYPE *ptd=clexdef.tagdef._indexin('<');
    if (ptd) {
       return ptd;
    }
    // Look for the first entry
    typeless k;
    k._makeempty();
    ptd=&clexdef.tagdef._nextel(k);
    if (!k._isempty()) return ptd;
    // Need to make an entry
    i:=pos(' (xml|html) ',' 'clexdef.styles' ',1,'r');
    if (i) {
       ptd=&clexdef.tagdef:['<'];
       _clex_init_tagdef(ptd);
       return ptd;
    }
    i=pos(' bbc ',' 'clexdef.styles' ',1);
    if (i) {
       ptd=&clexdef.tagdef:['['];
       _clex_init_tagdef(ptd);
       return ptd;
    }
    ptd=&clexdef.tagdef:['<'];
    _clex_init_tagdef(ptd);
    return ptd;
}
_ctldelete_attr.lbutton_up()
{
   if (CUR_ATTR_VALUES()=='') {
      CUR_ATTR_VALUES(CUR_ATTR_NAME()'('CUR_TAG_NAME()')');
   }
   if (ctlalltags.p_value && pos('(',CUR_ATTR_VALUES())) {
      CUR_ATTR_VALUES(CUR_ATTR_NAME());
   } else if (!ctlalltags.p_value && !pos('(',CUR_ATTR_VALUES())) {
      CUR_ATTR_VALUES(CUR_ATTR_NAME()'('CUR_TAG_NAME()')');
   }
   CLEX_TAGDEF_TYPE *ptd=cc_get_tagdef(gnew_keyword_table:[_ctllexer_list.p_text]);
   ptd->comment_values._deleteel(CUR_ATTR_VALUES());
   mou_hour_glass(true);
   if (_ctlattr_list.p_Nofselected==1) {
      _ctlattr_list._lbdelete_item();
      _ctlattr_list._lbselect_line();
   } else {
      ff := true;
      p_window_id=_control _ctlattr_list;
      while (!_lbfind_selected(ff)) {
         _lbdelete_item();
         _lbup();
         ff=false;
      }
      _lbselect_line();
   }
   AddLexerToModList();
   //say('mod18');
   mou_hour_glass(false);

   if (_ctlattr_list.p_Noflines) {
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
   } else {
      _ctlvalue_list._lbclear();

   }
   CUR_ATTR_NAME(_ctlattr_list._lbget_seltext());

   _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;

}
_ctlnew_value.lbutton_up()
{
   first_word := "";
   word := "";
   _str keyword=CUR_ATTR_NAME();
   _str name=show('-modal _textbox_form',
             'Enter New Values for 'keyword,
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New attribute values:' //prompt
             );
   if (name!='') {
      AddLexerToModList();
      //say('mod19');
      name=_param1;
      wid := p_window_id;p_window_id=_control _ctlvalue_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      //_lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
   }
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
}
_ctlvalue_list.DEL()
{
   if (_ctldelete_value.p_enabled) {
      _ctldelete_value.call_event(_ctldelete_value,LBUTTON_UP,'W');
   }
}
_ctldelete_value.lbutton_up()
{
   mou_hour_glass(true);
   ff := true;
   p_window_id=_control _ctlvalue_list;
   while (!_lbfind_selected(ff)) {
      _lbdelete_item();
      _lbup();
      ff=false;
   }
   _lbselect_line();
   AddLexerToModList();
   //say('mod20');
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
   mou_hour_glass(false);
}


static void cc_prepare_tags(_str lexername) {
   CUR_TAG_NAME('');CUR_ATTR_NAME('');CUR_ATTR_VALUES('');
   _ctltag_list._lbclear();
   _ctlattr_list._lbclear();
   _ctlvalue_list._lbclear();
   if (!ctlhtml.p_value && !ctlxml.p_value) {
      return;
   }
   // activate the tags tab so it can be refreshed
   int orig_active=ctlsstab.p_ActiveTab;
   ctlsstab.p_ActiveTab=CLEXTAB_TAGS;
   ctlsstab.p_ActiveEnabled=true;
   ctlsstab.p_ActiveTab=orig_active;

   cur := "";
   CLEX_TAGDEF_TYPE *ptd=cc_get_tagdef(gnew_keyword_table:[lexername]);
   _str keywords=ptd->comment_keywords;
   if (keywords!=null && keywords!='') {
      for (;;) {
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctltag_list._lbadd_item(strip(cur));
      }
      _ctltag_list._lbtop();
      _ctltag_list._lbselect_line();
   }
   _ctltag_list._lbsort();
   _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=false;
   _ctlnew_value.p_enabled=false;
   _ctldelete_value.p_enabled=false;
   if (_ctltag_list.p_Noflines>0) {
      cc_prepare_attrs(_ctltag_list._lbget_seltext());
   }
   CUR_TAG_NAME(_ctltag_list._lbget_text());
   CUR_ATTR_VALUES('');
}
static void cc_prepare_attrs(_str tagname)
{
   _str attributes:[];
   CLEX_TAGDEF_TYPE *ptd=cc_get_tagdef(gnew_keyword_table:[_ctllexer_list.p_text]);
   attributes=ptd->comment_attributes;

   _ctlattr_list._lbclear();
   keywords := "";
   if (attributes._indexin(tagname)) {
      keywords=attributes:[tagname];
   } else if (!gnew_keyword_table:[_ctllexer_list.p_text].case_sensitive && attributes._indexin(lowcase(tagname))) {
      keywords=attributes:[lowcase(tagname)];
   }

   if (keywords!=null && keywords!='') {
      for (;;) {
         cur := "";
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctlattr_list._lbadd_item(strip(cur));
      }
      _ctlattr_list._lbtop();
      _ctlattr_list._lbselect_line();
   }
   //_ctlattr_list._lbsort();
   _ctlvalue_list._lbclear();
   _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=false;
   if (_ctlattr_list.p_Noflines>0) {
      cc_prepare_values(tagname,_ctlattr_list._lbget_seltext());
   }
   CUR_ATTR_NAME(_ctlattr_list._lbget_text());
   CUR_ATTR_VALUES('');
}
static void cc_prepare_values(_str tagname, _str attrname)
{
   _str attrvalues:[];
   CLEX_TAGDEF_TYPE *ptd=cc_get_tagdef(gnew_keyword_table:[_ctllexer_list.p_text]);
   attrvalues= ptd->comment_values;

   _ctlvalue_list._lbclear();
   keywords := "";
   //say('**********************************************************');
   // IF we have attributes for this specific tag
   if (attrvalues._indexin(attrname'('tagname')')) {
      keywords=attrvalues:[attrname'('tagname')'];
      CUR_ATTR_VALUES(attrname'('tagname')');
      ctlalltags.p_value=0;
   } else if (attrvalues._indexin(upcase(attrname'('tagname')'))) {
      keywords=attrvalues:[upcase(attrname'('tagname')')];
      CUR_ATTR_VALUES(upcase(attrname'('tagname')'));
      ctlalltags.p_value=0;
   } else if (attrvalues._indexin(attrname)) {
      keywords=attrvalues:[attrname];
      CUR_ATTR_VALUES(attrname);
      ctlalltags.p_value=1;
   } else if (attrvalues._indexin(upcase(attrname))) {
      keywords=attrvalues:[upcase(attrname)];
      CUR_ATTR_VALUES(upcase(attrname));
      ctlalltags.p_value=1;
   } else {
      CUR_ATTR_VALUES('');
      ctlalltags.p_value=0;
   }
   if (keywords!=null && keywords!='') {
      for (;;) {
         cur := "";
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctlvalue_list._lbadd_item(strip(cur));
      }
      _ctlvalue_list._lbtop();
      _ctlvalue_list._lbselect_line();
   }
   //_ctlvalue_list._lbsort();
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
}


static void cc_update_tags(bool useCurrent = true)
{
   // ignore any tag list change events - causes recursion problems because
   // we are iterating through the list boxes
   IGNORE_TAG_LIST_ON_CHANGE(1);

   // whether we are updating the current lexer or saving 
   // the last lexer before showing a new one
   lexer := _ctllexer_list.p_text;
   if (!useCurrent) {
      lexer = LAST_LEXER_NAME();
   }

   // first update the list of tags
   wid := p_window_id;
   p_window_id=_ctltag_list;
   save_pos(auto p);
   _lbtop();
   _lbup();
   keyword := "";
   keyword_list := "";
   while (!_lbdown()) {
      keyword=_lbget_text();
      if (keyword_list=='') {
         keyword_list=keyword;
      }else{
         keyword_list :+= ' 'keyword;
      }
   }
   restore_pos(p);
   _lbselect_line();

   p_window_id=wid;
   orig_tags := "";
   CLEX_TAGDEF_TYPE *ptd=cc_get_tagdef(gnew_keyword_table:[lexer]);
   if (ptd->comment_keywords!=null) {
      orig_tags=ptd->comment_keywords;
   }
   if (keyword_list != orig_tags && (ctlhtml.p_value || ctlxml.p_value)) {
      ptd->comment_keywords=keyword_list;
   }

   // update the list of attributes for selected tag
   if (CUR_TAG_NAME()!=null && CUR_TAG_NAME()!='') {
      wid=p_window_id;
      p_window_id=_ctlattr_list;
      save_pos(p);
      _lbtop();_lbup();
      keyword_list='';
      while (!_lbdown()) {
         keyword=_lbget_text();
         if (keyword_list=='') {
            keyword_list=keyword;
         }else{
            keyword_list :+= ' 'keyword;
         }
      }
      restore_pos(p);_lbselect_line();
      p_window_id=wid;
      orig_attrs := "";
      _str cur_tag_name=gnew_keyword_table:[lexer].case_sensitive?CUR_TAG_NAME():lowcase(CUR_TAG_NAME());
      if (ptd->comment_attributes._indexin(cur_tag_name)) {
         orig_attrs=ptd->comment_attributes:[cur_tag_name];
      }
      //say('na='keyword_list);say('oa='orig_attrs);
      if (keyword_list != orig_attrs) {
         ptd->comment_attributes:[cur_tag_name]=keyword_list;
      }
   }

   // update the list of values for the attributes
   if (CUR_ATTR_NAME()!=null && CUR_ATTR_NAME()!='') {
      if (CUR_ATTR_VALUES()=='') {
         CUR_ATTR_VALUES(CUR_ATTR_NAME()'('CUR_TAG_NAME()')');
      }
      if (ctlalltags.p_value && pos('(',CUR_ATTR_VALUES())) {
         CUR_ATTR_VALUES(CUR_ATTR_NAME());
      } else if (!ctlalltags.p_value && !pos('(',CUR_ATTR_VALUES())) {
         CUR_ATTR_VALUES(CUR_ATTR_NAME()'('CUR_TAG_NAME()')');
      }
      wid=p_window_id;
      p_window_id=_ctlvalue_list;
      save_pos(p);
      _lbtop();_lbup();
      keyword_list='';
      while (!_lbdown()) {
         keyword=_lbget_text();
         if (keyword_list=='') {
            keyword_list=keyword;
         }else{
            keyword_list :+= ' 'keyword;
         }
      }
      restore_pos(p);_lbselect_line();
      p_window_id=wid;
      orig_vals := "";
      if (ptd->comment_values._indexin(CUR_ATTR_VALUES())) {
         orig_vals=ptd->comment_values:[CUR_ATTR_VALUES()];
      }
      if (keyword_list != orig_vals) {
         ptd->comment_values:[CUR_ATTR_VALUES()]=keyword_list;

         _str attrvalues:[];
         attrvalues=ptd->comment_values;
      }
      if (ctlalltags.p_value) {
         ptd->comment_values._deleteel(CUR_ATTR_NAME()'('CUR_TAG_NAME()')');
      }
   }

   IGNORE_TAG_LIST_ON_CHANGE(0);
}


ctlstart_col.on_change()
{
   if (p_window_id!=ctlend_col) {
      //If it just changed, I don't think that we would need to disable it
      ctlend_col.p_enabled=(ctlstart_col.p_text!='');
   }
   //update_message_label();
#if 0
   if (isinteger(ctlstart_col.p_text)||ctlstart_col.p_text!='') {
      _ctlcheckfirst_ml.p_enabled=true;
      _ctlleading_ml.p_enabled=true;
      _ctllastchar.p_enabled=true;
      _ctlnesting.p_enabled=false;
      ctlnest_start.p_enabled=false;
      ctlnest_end.p_enabled=false;
      ctlblockdocs.p_enabled=false;
      //_ctlidchars.p_enabled=false;
      _ctlcolor_name.p_enabled=false;
      _ctlcolor_label.p_enabled=false;
      //_ctlidchars_label.p_enabled=false;
   }else{
      _ctlcheckfirst_ml.p_enabled=false;
      _ctlleading_ml.p_enabled=false;
      _ctllastchar.p_enabled=false;
      _ctlnesting.p_enabled=true;
      ctlnest_start.p_enabled=true;
      ctlnest_end.p_enabled=true;
      ctlblockdocs.p_enabled=true;
      //_ctlidchars.p_enabled=true;
      _ctlcolor_name.p_enabled=true;
      _ctlcolor_label.p_enabled=true;
      //_ctlidchars_label.p_enabled=true;
   }
#endif
}

int vlx_proc_search(_str &proc_name,bool find_first)
{
   return ini_proc_search(proc_name,find_first);
}

int ini_proc_search(_str &proc_name,bool find_first)
{
   _str re_map:[];
   re_map:["NAME"] = '[^\]]#';
   return _generic_regex_proc_search('^[\[]<<<NAME>>>[\]]', proc_name, find_first!=0, "label", re_map);
}
int forth_proc_search(_str &proc_name,bool find_first)
{
   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = '(create|buffer\:|fconstant|constant|fvariable|variable|wvariable|cvariable|lvariable|equ|2variable|2constant|\:)';
      re_map:["NAME"] = '([\x0-\x8\xB\xC\xE-\x1F\x21-\xFFFF]#)';
   }

   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["variable"] = "gvar";
      kw_map:["fvariable"] = "gvar";
      kw_map:["lvariable"] = "gvar";
      kw_map:["cvariable"] = "gvar";
      kw_map:["wvariable"] = "gvar";
      kw_map:["equ"] = "define";
      kw_map:["constant"] = "const";
      kw_map:["fconstant"] = "const";
      kw_map:["buffer:"] = "gvar";
      kw_map:["create"] = "const";
      kw_map:["2variable"] = "gvar";
      kw_map:["2constant"] = "const";
      kw_map:[":"] = "label";
   }
   return _generic_regex_proc_search('(#<=^|[^\x0-\x8\xB\xC\xE-\x1F\x21-\xFFFF]#)<<<TYPE>>>[ \t]+<<<NAME>>>', proc_name, find_first!=0, "", re_map, kw_map);

}
int _forth_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex,'forth','forth',"Forth Builtins", "", false, withRefs, useThread, forceRebuild);
}
/**
 * @see _c_fcthelp_get_start
 */
int _forth_fcthelp_get_start(_str (&errorArgs)[],
                            bool OperatorTyped,
                            bool cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags,
                            int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags,
                               depth));
}
/**
 * @see _c_fcthelp_get
 */
int _forth_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
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

int rc_proc_search(_str &proc_name,bool find_first)
{
   proc_name='';
   return(STRING_NOT_FOUND_RC);
}

int diffpatch_proc_search(_str &proc_name,bool find_first)
{
   _str re_map:[];
   re_map:["NAME"] = ":p";
   return _generic_regex_proc_search('^diff(:b-[a-zA-Z0-9-]+)+:b<<<NAME>>>', proc_name, find_first!=0, "file", re_map);
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _m4_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "m4", "", "", "", false, withRefs, useThread, forceRebuild);
}

int m4_proc_search(_str &proc_name,bool find_first)
{
   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "define|defun|m4_define|m4_defun|defun_once|m4_defun_once|include|m4_include|require|m4_require|AC_DEFUN|sinclude|m4_sinclude|AC_REQUIRE|AC_DEFINE|AC_INCLUDE";
   }

   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["define"] = "define";
      kw_map:["m4_define"] = "define";
      kw_map:["AC_DEFINE"] = "define";
      kw_map:["AC_DEFUN"] = "func";
      kw_map:["defun"] = "func";
      kw_map:["defun_once"] = "func";
      kw_map:["m4_defun"] = "func";
      kw_map:["m4_defun"] = "func";
      kw_map:["m4_defun_once"] = "func";
      kw_map:["include"] = "include";
      kw_map:["m4_include"] = "include";
      kw_map:["AC_INCLUDE"] = "include";
      kw_map:["sinclude"] = "include";
      kw_map:["m4_sinclude"] = "include";
      kw_map:["require"] = "import";
      kw_map:["m4_require"] = "import";
      kw_map:["AC_REQUIRE"] = "import";
   }

   return _generic_regex_proc_search("^[ \\t]*<<<TYPE>>>\\(([\\[`]|)<<<NAME>>>([\\]\\']|)[ \\t,)]", proc_name, find_first!=0, "", re_map, kw_map);
}

defeventtab _create_new_lexer_form;

void ctlok.on_create()
{
   // add the lexers to the combo box
   ctllexer_list._lbclear();

   _str profileNames[];
   _plugin_list_profiles(VSCFGPACKAGE_COLORCODING_PROFILES,profileNames);
   for (i:=0;i<profileNames._length();++i) {
      ctllexer_list._lbadd_item(profileNames[i]);
   }

   ctllexer_list._lbsort();
   ctllexer_list._lbtop();
   ctllexer_list._lbselect_line();

   ctlcopy_cb.call_event(ctlcopy_cb, LBUTTON_UP);
}

void ctlcopy_cb.lbutton_up()
{
   ctllexer_list.p_enabled = (ctlcopy_cb.p_value != 0);
}

void ctlok.lbutton_up()
{
   if (verifyLexerName(ctllexer_name.p_text)) return;

   _param1 = ctllexer_name.p_text;

   if (ctlcopy_cb.p_value) {
      _param2 = ctllexer_list.p_text;
   } else {
      _param2 = '';
   }


   p_active_form._delete_window(IDOK);
}
defeventtab _cc_add_words;
void ctlok.on_create() {
   ctltype.cc_fill_color_combo();
   ctltype.p_text='Keyword';
}
void ctlok.lbutton_up() {
   _param1=ctltext1.p_text;
   if (_param1=='') {
      p_active_form._delete_window();
      return;
   }
   _param2=_cc_convert_from_dlg_color_name(ctltype.p_text);
   _param3=ctltoken_case_sensitive.p_value;
   p_active_form._delete_window(1);
}

defeventtab _cc_import_word_list;
void ctlok.on_create() {
   ctltype.cc_fill_color_combo();
   ctltype.p_text='Keyword';
   sizeBrowseButtonToTextBox(ctltext1.p_window_id, ctlbrowse.p_window_id, 0, p_active_form.p_width-ctllabel1.p_x);
}
void ctlok.lbutton_up() {
   _param1=ctltext1.p_text;
   if (_param1=='') {
      p_active_form._delete_window();
      return;
   }
   _param2=_cc_convert_from_dlg_color_name(ctltype.p_text);
   _param3=ctltoken_case_sensitive.p_value;
   p_active_form._delete_window(1);
}
void ctlbrowse.lbutton_up()
{
   initialDirectory := absolute(p_prev.p_text);
   if ( !isdirectory(initialDirectory) ) {
      initialDirectory = _file_path(initialDirectory);
   }
   result:=_OpenDialog('-modal',
                      '',
                      'Select file to import',
                      '',
                      OFN_FILEMUSTEXIST,
                      '',
                      '',
                      initialDirectory
                      );
   if ( result=='' ) return;
   result = strip(result,'B','"');
   p_window_id=ctlbrowse.p_prev;
   p_text=result;
   end_line();
   _set_focus();
}

_form _color_element_list_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption="Choose Color Elements";
   p_forecolor=0x80000008;
   p_height=5070;
   p_width=6015;
   p_x=32445;
   p_y=3540;
   p_eventtab=_color_element_list_form;
   _tree_view ctltree1 {
      p_after_pic_indent_x=50;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_CheckListBox=false;
      p_ColorEntireLine=false;
      p_EditInPlace=false;
      p_delay=0;
      p_forecolor=0x80000008;
      p_Gridlines=TREE_GRID_NONE;
      p_height=4545;
      p_LevelIndent=50;
      p_LineStyle=TREE_DOTTED_LINES;
      p_multi_select=MS_NONE;
      p_NeverColorCurrent=false;
      p_ShowRoot=false;
      p_AlwaysColorCurrent=false;
      p_SpaceY=50;
      p_scroll_bars=SB_VERTICAL;
      p_UseFileInfoOverlays=FILE_OVERLAYS_NONE;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=5940;
      p_x=60;
      p_y=60;
      p_eventtab2=_ul2_tree;
   }
   _command_button ctlok {
      p_auto_size=true;
      p_cancel=false;
      p_caption="OK";
      p_default=true;
      p_height=345;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=1125;
      p_x=75;
      p_y=4665;
   }
   _command_button ctlcancel {
      p_auto_size=true;
      p_cancel=true;
      p_caption="Cancel";
      p_default=false;
      p_height=345;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1125;
      p_x=1425;
      p_y=4665;
   }
}
static _str gcc_token_table[]={
   "attribute",
   "backquoted_string",
   "comment",
   "css_class",
   "css_element",
   "css_property",
   "css_selector",
   "doc_attr_value",
   "doc_attribute",
   "doc_keyword",
   "doc_punctuation",
   "documentation",
   "function",
   "floating_number",
   "hex_number",
   "identifier",
   "identifier2",
   "inactive_code",
   "inactive_comment",
   "inactive_keyword",
   "keyword",
   "linenum",
   "line_comment",
   "library_symbol",
   "markdown_blockquote",
   "markdown_bullet",
   "markdown_code",
   "markdown_emphasis",
   "markdown_emphasis2",
   "markdown_emphasis3",
   "markdown_emphasis4",
   "markdown_header",
   "markdown_link",
   "markdown_link2",
   "number",
   "operator",
   "ppkeyword",
   "punctuation",
   "string",
   "singlequoted_string",
   "tag",
   "unknown_tag",
   "unknown_attribute",
   "unterminated_string",
   "user_defined",
   "window_text",
   "xhtmlelementinxsl",
   "xml_character_ref",
   "yaml_text_colon",
   "yaml_text",
   "yaml_tag",
   "yaml_directive",
   "yaml_anchor_def",
   "yaml_anchor_ref",
   "yaml_punctuation",
   "yaml_operator",
};
static _str gcc_title_table[]={
   "Attribute",
   "Back Quoted String",
   "Comment",
   "CSS Class",
   "CSS Element",
   "CSS Property",
   "CSS Selector",
   "Documentation Attribute Value",
   "Documentation Attribute",
   "Documentation Keyword",
   "Documentation Punctuation",
   "Documentation",
   "Function",
   "Floating Number",
   "Hexadecimal Number",
   "Identifier",
   "Identifier2",
   "Inactive Code",
   "Inactive Comment",
   "Inactive Keyword",
   "Keyword",
   "Linenum",
   "Line Comment",
   "Library Symbol",
   "Markdown Blockquote",
   "Markdown Bullet",
   "Markdown Code",
   "Markdown Emphasis",
   "Markdown Emphasis2",
   "Markdown Emphasis3",
   "Markdown Emphasis4",
   "Markdown Header",
   "Markdown Link",
   "Markdown Link2",
   "Number",
   "Operator",
   "Preprocessor",
   "Punctuation",
   "String",
   "Single Quoted String",
   "Tag/Element",
   "Unknown Tag/Element",
   "Unknown Attribute",
   "Unterminated String",
   "User Defined",
   "Window Text",
   "XHTML Element in XSL",
   "XML/HTML Numeric Character Reference",
   "YAML Text Colon",
   "YAML Text",
   "YAML Tag",
   "YAML Directive",
   "YAML Anchor Definition",
   "YAML Anchor Reference",
   "YAML Punctuation",
   "YAML Operator",
};
defeventtab _color_element_list_form;

void _color_element_list_form.on_resize() {
   int form_height=_dy2ly(SM_TWIP,p_active_form.p_client_height);
   int form_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int space_y=(ctlok.p_y)-(ctltree1.p_y_extent);
   int tree_height=form_height-ctlok.p_height-2*(space_y)-ctltree1.p_y;
   if (tree_height<ctlok.p_height) {
      tree_height=ctlok.p_height;
   }
   ctltree1.p_height=tree_height;
   int tree_width=form_width-2*ctltree1.p_x;
   if (tree_width<ctlok.p_width) tree_width=ctlok.p_width;
   ctltree1.p_width=tree_width;
   ctlcancel.p_y=ctlok.p_y=ctltree1.p_y_extent+space_y;
}

int _array_find_item(_str (&array)[], _str s) {
   foreach (auto k=>auto v in array) {
      if (s:==v) {
         return k;
      }
   }
   return -1;
}

void ctltree1.on_create(_str elements='') {
   //elements='keyword string';
   elements=' 'elements' ';

   foreach (auto i=>auto v in gcc_title_table) {
      index:=_TreeAddItem(TREE_ROOT_INDEX,v,TREE_ADD_AS_CHILD,0,0,-1);
      if (pos(' 'gcc_token_table[i]' ',elements)) {
         _TreeSetCheckable(index,1,0,1);
      } else {
         _TreeSetCheckable(index,1,0,0);
      }
   }

}
void ctlok.lbutton_up() {
   elements := "";
   int index;
   index=ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index>=0) {
      
      if (ctltree1._TreeGetCheckState(index)) {
         k:=_array_find_item(gcc_title_table,ctltree1._TreeGetCaption(index));
         if (elements=='') {
            elements=gcc_token_table[k];
         } else {
            strappend(elements,' ');
            strappend(elements,gcc_token_table[k]);
         }
      }
      index=ctltree1._TreeGetNextSiblingIndex(index);
   }
   _param1=elements;
   p_active_form._delete_window(1);
}

