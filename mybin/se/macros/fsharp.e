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
// Language support module for F#
// 
#pragma option(pedantic,on)

#region Imports
#include 'slick.sh'
#include 'tagsdb.sh'
#require "se/lang/api/LanguageSettings.e"
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

#define FSHARP_MODE_NAME 'F#'
#define FSHARP_LANGUAGE_ID 'fsharp'
#define FSHARP_LEXERNAME  'FSharp'
#define FSHARP_EXTENSION 'fs'
#define FSHARP_SCRIPT_EXTENSION 'fsx'
#define FSHARP_WORD_CHARS 'a-zA-Z0-9_'
#define FSHARP_KEYS_TABLE 'fsharp-keys'

defload()
{
   _str setup_info='MN='FSHARP_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='FSHARP_KEYS_TABLE',WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='FSHARP_WORD_CHARS',LN='FSHARP_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 0 1 0';
   _str be_info='';
   int kt_index=0;
   _CreateLanguage(FSHARP_LANGUAGE_ID, FSHARP_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension(FSHARP_EXTENSION, FSHARP_LANGUAGE_ID);
   _CreateExtension(FSHARP_SCRIPT_EXTENSION, FSHARP_LANGUAGE_ID);
}

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
int _fsharp_MaybeBuildTagFile(int &tfindex)
{
   _str ext=FSHARP_EXTENSION;
   _str basename=FSHARP_LANGUAGE_ID;

   // maybe we can recycle tag file(s)
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
      return(0);
   }
   tag_close_db(tagfilename);

   // Build tags from fsharp.tagdoc or builtins.fs
   int status=0;
   _str extra_file=ext_builtins_path(ext,basename);
   if(extra_file!='') {
         status=shell('maketags -n "F# Library" -o ' :+
                      maybe_quote_filename(tagfilename)' ' :+
                      maybe_quote_filename(extra_file));
   }
   LanguageSettings.setTagFileList(FSHARP_LANGUAGE_ID, tagfilename, true);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   return(status);
}

/**
 * F# implementation of the ext_proc_search callback. Searches 
 * for F# function identifiers. 
 */
_str fsharp_proc_search(_str &proc_name,boolean find_first)
{
   // Search for let and let rec identifiers starting in the first col
   // May want to extend this to other things, like "open System" directives
   // and other top-level decls. (Refer to haskell.e for example of this
   // two-tiered expression searching)
   _str search_key= '^(?:let\s*)(?:rec\s*)*(\:v)\b\s*([^\=]*)\=';
   // Perl regex. Do not search in comments or strings
   _str searchOptions = '@liXcs'; 
   int status=0;
   if ( find_first ) {
      status=search(search_key,searchOptions);
   } else {
      status=repeat_search(searchOptions);
   }

   if (!status) {
      int indentStart = match_length('S0');
      int indentLen = match_length('0');

      // Distinguish those functions that 
      // have params, and those that don't
      int paramsStart = match_length('S1');
      int paramsLen = match_length('1');
     
      _str decl_identifier = get_text(indentLen, indentStart);
      _str type_name = 'typedef';
      _str arguments = '';
      if(paramsStart > 0 && paramsLen > 0) {
         type_name = 'proto';
         arguments = get_text(paramsLen, paramsStart);
      }
      int tag_flags = 0;

      proc_name = tag_tree_compose_tag(decl_identifier, '', type_name, tag_flags, arguments);
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
 * @return boolean If true, layout alignment was done. Otherwise, false, which falls 
 *         through to default ENTER behavior
 */
boolean _fsharp_expand_enter()
{
   if( command_state()                  ||  // Do not expand if the visible cursor is on the command line
       (p_window_state:=='I')           ||  // Do not expand if window is iconified
       _in_comment(1)){                     // Do not expand if you are inside of a comment
      return true;
   }
   
   int caretNowAt = p_col;
   if(caretNowAt > 3) {
      get_line(auto currentLine);
      // See if this line looks like a function declaration, and if there is at least
      // one non-space char after the equals sign. That is what we'll align on.
      if(pos('^(?:let\s*)(?:rec\s*)*(\:v)\b\s*([^\=]*)\=', currentLine, 1, 'l') > 0){
         int indentPos = pos('S0');
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
 
_command void fsharp_enter() 
   name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL) 
{
   generic_enter_handler(_fsharp_expand_enter);
} 



