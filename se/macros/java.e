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
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "autobracket.e"
#import "alllanguages.e"
#import "c.e"
#import "clipbd.e"
#import "codehelp.e"
#import "jrefactor.e"
#import "setupext.e"
#import "listbox.e"
#import "seek.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;


defeventtab java_keys;
def  ' '= java_space;
def  '#'= c_pound;
def  '('= c_paren;
def  '*'= c_asterisk;
def  '/'= c_slash;
def  ','= java_comma;
def  '.'= java_auto_codehelp_key;
def  ':'= java_colon;
def  '<'= java_auto_functionhelp_key;
def  '='= java_auto_codehelp_key;
def  '>'= java_auto_codehelp_key;
def  '@'= c_atsign;
def  '['= java_startbracket;
def  '\'= c_backslash;
def  '{'= java_begin;
def  '}'= java_endbrace;
def  'ENTER'= java_enter;
def  'TAB'= smarttab;
def  ';'= c_semicolon;

_command void java_auto_functionhelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   auto_functionhelp_key();
}

_command void java_auto_codehelp_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   auto_codehelp_key();
}

_command void java_startbracket() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if(!command_state() && def_jrefactor_auto_import==1) {
      refactor_add_import(true);
   }
   keyin(l_event);
}

_command void java_comma() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if(!command_state() && def_jrefactor_auto_import==1) {
      refactor_add_import(true);
   }
   keyin(l_event);
}

_command void java_colon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_colon();
}

_command void java_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_jrefactor_auto_import==1) {
      refactor_add_import(true);
   }
   c_space();
}

_command void java_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}

_command void java_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_jrefactor_auto_import==1) {
      refactor_add_import(true);
   }
   c_begin();
}

_command void java_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_endbrace();
}

int java_indent_col(int non_blank_col,bool pasting_open_block)
{
   return(c_indent_col(non_blank_col,pasting_open_block));
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
bool java_is_start_block()
{
   return c_is_start_block();
}


bool _java_surroundable_statement_end() {
   return _c_surroundable_statement_end();
}

bool _java_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}


static const TXT_S1= "Same Line";
static const TXT_S2= "Next Line";
static const TXT_S3= "Next Line Indented";

// Updates brace style example.  Assumes the combo box has already
// been populated with the updated setting.
void clike_update_brace_ex(int ctl, int label)
{
   t := ctl.p_cb_text_box.p_text;
   if (t == TXT_S2) {
      label.p_caption = "if ()\n{\n   ++i;\n}";
   } else if (t == TXT_S3) {
      label.p_caption = "if ()\n   {\n   ++i;\n   }"; 
   } else {
      // Brace style 1, or out of range style.
      label.p_caption = "if () {\n   ++i;\n}";
   }
}
void idl_update_brace_ex(int ctl, int label)
{
    t := ctl.p_cb_text_box.p_text;
    if (t == TXT_S2) {
       label.p_caption = "struct \n{\n  int x,y;\n}";
    } else if (t == TXT_S3) {
       label.p_caption = "struct\n  {\n  int x,y;\n  }"; 
    } else {
       // Brace style 1, or out of range style.
       label.p_caption = "struct {\n  int x,y;\n}";
    }
}


#region Options Dialog Helper Functions

defeventtab _java_extform;

static const FUNC_PARAM_ALIGN_ON_PARENS_TEXT=            'Align on parens';
static const FUNC_PARAM_ALIGN_CONT_INDENT_TEXT=          'Continuation indent';
static const FUNC_PARAM_ALIGN_AUTO_TEXT=                 'Auto';

static _str java_ext_styles[] = { TXT_S1, TXT_S2, TXT_S3 };
static _str java_ext_funalign[] = {FUNC_PARAM_ALIGN_AUTO_TEXT,
                                   FUNC_PARAM_ALIGN_CONT_INDENT_TEXT };
static _str java_ext_py_funalign[] = { 
    FUNC_PARAM_ALIGN_ON_PARENS_TEXT,
    FUNC_PARAM_ALIGN_CONT_INDENT_TEXT, 
    FUNC_PARAM_ALIGN_AUTO_TEXT
};

void _java_extform_init_for_options(_str langID)
{
   if (langID == 'py') {
       populatecb(_control _cb_funparam, 0, java_ext_py_funalign);
   } else {
       populatecb(_control _cb_funparam, 0, java_ext_funalign);
   }
   populatecb(_control _cb_style, 0, java_ext_styles);
   if (langID == 'idl') {
       idl_update_brace_ex(_control _cb_style, _control _cb_style_label);
   } else {
       clike_update_brace_ex(_control _cb_style, _control _cb_style_label);
   }

   // we hide some controls for some languages
   if (langID == 'js' || langID == 'as' || langID == 'cfscript' || langID == 'phpscript') {
      _indent.p_visible = false;

   } else if (langID == 'awk') {
      _indent.p_visible = false;
      _cb_funparam.p_visible = false;
      _cb_funparam_label.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

   } else if (langID == 'r') {
      _indent.p_visible = false;
      //_cb_funparam.p_visible = false;
      //_cb_funparam_label.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

   } else if (langID == 'pl') {
      _indent_case.p_visible = false;
      _cb_funparam.p_visible = false;
      _cb_funparam_label.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

   } else if (langID == 'powershell') {
      _quick_brace.p_visible = false;
      _ctl_cuddle_else.p_visible = false;
      _indent_case.p_visible = false;
      _cb_funparam.p_visible = false;
      _cb_funparam_label.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

   } else if (langID == 'vera') {
      _ctl_cuddle_else.p_visible = false;
      _indent_case.p_visible = false;
      _cb_funparam.p_visible = false;
      _cb_funparam_label.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;

   } else if (langID == 'rul') {
      frame1.p_visible = false;
      _indent.p_visible = false;
      _has_space.p_visible = false;
      _cb_funparam.p_visible = false;
      _cb_funparam_label.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;

   } else if (langID == 'py') {
      frame1.p_visible = false;
      _indent.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;
      _has_space.p_caption = 'Space before function parenthesis';
   } else if (langID == 'idl') {
      _quick_brace.p_visible = false;
      _ctl_cuddle_else.p_visible = false;
      _indent.p_visible = false;
      _indent_case.p_visible = false;
      _indent_case_ad_form_link.p_visible = false;
      _has_space.p_visible = false;
      _no_space_ad_form_link.p_visible = false;
      ctl_pad_between_parens.p_visible = false;
      _pad_parens_ad_form_link.p_visible = false;
   } else if (langID == 'groovy' || langID == 'scala' || _LanguageInheritsFrom('kotlin', langID)) {
      _cb_style.p_enabled = false;
      _ctl_cuddle_else.p_visible = false;
      _indent.p_visible = false;
   } 

   _cb_style_label._use_source_window_font();

   _java_extform_shift_controls();

   // adaptive formatting stuff
   setAdaptiveLinks(langID);

   _language_form_init_for_options(langID, _java_extform_get_value,
                                   _language_formatting_form_is_lang_included);

}

void _cb_style.on_change(int reason) 
{
    langId := _get_language_form_lang_id();

    if (langId == 'idl') {
        idl_update_brace_ex(_control _cb_style, _control _cb_style_label);
    } else {
        clike_update_brace_ex(_control _cb_style, _control _cb_style_label);
    }
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
      shift = _cb_funparam.p_y - frame1.p_y;
   }
   // use continuation indent checkbox
   if (!_cb_funparam.p_visible) {
      shift += _indent.p_y - _cb_funparam.p_y;
   } else {
      _cb_funparam.p_y -= shift;
      _cb_funparam_label.p_y -= shift;
   }

   // indent first level of code
   if (!_indent.p_visible) {
      shift += _indent_case.p_y - _indent.p_y;
   } else {
      _indent.p_y -= shift;
   }

   // indent case from switch
   if (!_indent_case.p_visible) {
      shift += _has_space.p_y - _indent_case.p_y;
   } else {
      _indent_case.p_y -= shift;
      _indent_case_ad_form_link.p_y -= shift;
   }

   // no space before parens
   if (!_has_space.p_visible) {
      shift += ctl_pad_between_parens.p_y - _has_space.p_y;
   } else {
      _has_space.p_y -= shift;
      _no_space_ad_form_link.p_y -= shift;
   }

   // insert padding between parens
   if (ctl_pad_between_parens.p_visible) {
      ctl_pad_between_parens.p_y -= shift;
      _pad_parens_ad_form_link.p_y -= shift;
   }
}

_str _java_extform_get_value(_str controlName, _str langId)
{
   _str value = null;

   switch (controlName) {
   case '_cb_style':
       ls := LanguageSettings.getBeginEndStyle(langId);
       if (ls >= 0 && ls < java_ext_styles._length()) {
           value = java_ext_styles[ls];
       }
       break;

   case '_cb_funparam':
      if (langId == 'py') {
          value = LanguageSettings.getFunctionParameterAlignment(langId);
          switch (value) {
          case FPAS_ALIGN_ON_PARENS:
             value = FUNC_PARAM_ALIGN_ON_PARENS_TEXT;
             break;
          case FPAS_AUTO:
             value = FUNC_PARAM_ALIGN_AUTO_TEXT;
             break;
          case FPAS_CONTINUATION_INDENT:
          default:
             value = FUNC_PARAM_ALIGN_CONT_INDENT_TEXT;
             break;
          }
      } else {
          fp := LanguageSettings.getUseContinuationIndentOnFunctionParameters(langId);
          if (fp >= 0 && fp < java_ext_funalign._length()) {
             value = java_ext_funalign[fp];
          }
      }
      break;

   default:
      value = _language_formatting_form_get_value(controlName, langId);
   }

   return value;
}

bool _java_extform_apply()
{
   _language_form_apply(_java_extform_apply_control);

   return true;
}

_str _java_extform_apply_control(_str controlName, _str langId, _str value)
{
   updateString := '';

   switch (controlName) {
   case '_cb_style':
       idx := comboIndexSelected(value, java_ext_styles);

       LanguageSettings.setBeginEndStyle(langId, idx);
       updateString = BEGIN_END_STYLE_UPDATE_KEY' 'idx;
       break;

   case '_cb_funparam':
      if (langId == 'py') {
          intValue := FPAS_CONTINUATION_INDENT;
          switch (value) {
          case FUNC_PARAM_ALIGN_ON_PARENS_TEXT:
             intValue = FPAS_ALIGN_ON_PARENS;
             break;
          case FUNC_PARAM_ALIGN_AUTO_TEXT:
             intValue = FPAS_AUTO;
             break;
          case FUNC_PARAM_ALIGN_CONT_INDENT_TEXT:
          default:
             intValue = FPAS_CONTINUATION_INDENT;
             break;
          }
          LanguageSettings.setFunctionParameterAlignment(langId, intValue);
      } else {
          idx = comboIndexSelected(value, java_ext_funalign);

          LanguageSettings.setUseContinuationIndentOnFunctionParameters(langId, idx);
      }
      break;

   default:
      updateString = _language_formatting_form_apply_control(controlName, langId, value);
   }

   return updateString;
}

bool _java_allow_AutoBracket(_str key) {
   if (key!='"' || p_col<3) {
      return true;
   }
   seekpos:=_nrseek();
   if (seekpos<2) {
      return true;
   }
   if(get_text(2,seekpos-2)=='""') {
      return false;
   }
   return true;
}

