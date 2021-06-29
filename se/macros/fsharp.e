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
// Language support module for F#
// 
#pragma option(pedantic,on)

#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#import "se/lang/api/LanguageSettings.e"
#import "context.e"
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

static const FSHARP_LANGUAGE_ID= "fsharp";
static const PERL_VARIABLE_RE=  "(?:[A-Za-z_$][A-Za-z0-9_$]*)";

/**
 * Set current editor language to F#
 */
_command fsharp_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(FSHARP_LANGUAGE_ID);
}

/**
 * Build tag file for the F# library. This is builtin stuff 
 * that doesn't come as part of the "stock" .NET library. 
 * @remarks These are the F# 'shims' that operate on .NET types. 
 *          Example being List.rev function.
 * @param tfindex   Tag file index
 */
int _fsharp_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   lang := FSHARP_LANGUAGE_ID;
   return ext_MaybeBuildTagFile(tfindex, lang, lang,
                                "F# Library", 
                                "", false, withRefs, useThread, forceRebuild);
}

/**
 * F# implementation of the ext_proc_search callback. Searches 
 * for F# function identifiers. 
 */
int fsharp_proc_search(_str &proc_name,bool find_first)
{
   // Search for let and let rec identifiers starting in the first col
   // May want to extend this to other things, like "open System" directives
   // and other top-level decls. (Refer to haskell.e for example of this
   // two-tiered expression searching)
   search_key := '^(?:let\s*)(?:rec\s*)*(\:v)\b\s*([^\=]*)\=';
   // Perl regex. Do not search in comments or strings
   searchOptions := "@liXcs"; 
   status := 0;
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
     
      decl_identifier := get_match_text('1');
      tag_type := SE_TAG_TYPE_VAR;
      // Distinguish those functions that 
      // have params, and those that don't
      paramsStart := match_length('S2');
      paramsLen := match_length('2');
      arguments := "";
      if(paramsStart > 0 && paramsLen > 0) {
         tag_type = SE_TAG_TYPE_PROTO;
         arguments = get_match_text('2');
      }
      tag_init_tag_browse_info(auto cm, decl_identifier, "", tag_type);
      cm.arguments = arguments;
      proc_name = tag_compose_tag_browse_info(cm);
   }
   return(status);
}

/**
 * Attempts to do F# "#light" alignment when continuing 
 * the declaration of function. 
 * @example Proper alignment shown by the # sign below, right under the i in if<pre>
 * let rec myFunc x = match x with 
 *         #
 * </pre>
 * @return bool If true, layout alignment was done. Otherwise, false, which falls 
 *         through to default ENTER behavior
 */
bool _fsharp_expand_enter()
{
   if( command_state()                  ||  // Do not expand if the visible cursor is on the command line
       (p_window_state:=='I')           ||  // Do not expand if window is iconified
       _in_comment(true)){                     // Do not expand if you are inside of a comment
      return true;
   }
   
   caretNowAt := p_col;
   if(caretNowAt > 3) {
      get_line(auto currentLine);
      // See if this line looks like a function declaration, and if there is at least
      // one non-space char after the equals sign. That is what we'll align on.
      if(pos('^(?:let\s*)(?:rec\s*)*('PERL_VARIABLE_RE')\b\s*([^\=]*)\=', currentLine, 1, 'l') > 0){
         indentPos := pos('S0');
         if(indentPos < caretNowAt) {
            indent_on_enter(indentPos-1);
            return false;
         }
      }
   }
   return true;
}
 
defeventtab fsharp_keys;  
def 'ENTER'=fsharp_enter; 
def ' '=ext_space; 
 
_command void fsharp_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL) 
{
   generic_enter_handler(_fsharp_expand_enter);
} 

bool _fsharp_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}


