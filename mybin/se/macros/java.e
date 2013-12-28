////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#import "c.e"
#import "codehelp.e"
#import "jrefactor.e"
#endregion

defeventtab java_keys;
def  ' '= java_space;
def  '#'= c_pound;
def  '('= c_paren;
def  '*'= c_asterisk;
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

_command void java_auto_functionhelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   auto_functionhelp_key();
}

_command void java_auto_codehelp_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   auto_codehelp_key();
}

_command void java_startbracket() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if(!command_state() && def_jrefactor_auto_import==1) {
      jrefactor_add_import(true);
   }
   keyin(l_event);
}

_command void java_comma() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str l_event = last_event();
   if(!command_state() && def_jrefactor_auto_import==1) {
      jrefactor_add_import(true);
   }
   keyin(l_event);
}

_command void java_colon() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_colon();
}

_command void java_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_jrefactor_auto_import==1) {
      jrefactor_add_import(true);
   }
   c_space();
}

_command void java_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}

_command void java_begin() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_jrefactor_auto_import==1) {
      jrefactor_add_import(true);
   }
   c_begin();
}

_command void java_endbrace() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_endbrace();
}

int java_indent_col(int non_blank_col,boolean pasting_open_block)
{
   return(c_indent_col(non_blank_col,pasting_open_block));
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
boolean java_is_start_block()
{
   return c_is_start_block();
}


boolean _java_surroundable_statement_end() {
   return _c_surroundable_statement_end();
}
