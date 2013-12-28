////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45485 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc. 
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
// Language support module for Coffeescript
// 
#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#import "main.e"
#import "slickc.e"
#import "stdcmds.e"
#import "tags.e"
#import "util.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define GOOGLE_GO_MODE_NAME   'Google Go'
#define GOOGLE_GO_LANGUAGE_ID 'googlego'
#define GOOGLE_GO_LEXERNAME   'Google Go'
#define GOOGLE_GO_EXTENSION   'go'
#define GOOGLE_GO_WORD_CHARS  'a-zA-Z0-9_$'

defeventtab googlego_keys;
def  ' '= c_space;
def  '('= c_paren;
def  '.'= auto_codehelp_key;
def  ':'= c_colon;
def  '\'= c_backslash;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  'ENTER'= c_enter;
def  'TAB'= smarttab;
def  ';'= c_semicolon;

defload()
{
   _str setup_info='MN='GOOGLE_GO_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='GOOGLE_GO_LANGUAGE_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='GOOGLE_GO_WORD_CHARS',LN='GOOGLE_GO_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 ':+   // <Syntax indent amount>  <expansion on/off>
                    '1 0 4 ':+ // <min abbrev> <keyword case - not used> <brace style>
                    '1 1';     // <indent first level> <main style - not used>
   _str be_info='';
   _CreateLanguage(GOOGLE_GO_LANGUAGE_ID, GOOGLE_GO_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _SetLanguageInheritsFrom(GOOGLE_GO_LANGUAGE_ID, 'c');
   _CreateExtension(GOOGLE_GO_EXTENSION, GOOGLE_GO_LANGUAGE_ID);
}

_command googlego_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(GOOGLE_GO_LANGUAGE_ID);
}

int _googlego_MaybeBuildTagFile(int &tfindex)
{
   say('_googlego_MaybeBuildTagFile(tfindex='(tfindex!=null?'nonnull':'null')' )');
   // maybe we can recycle tag file(s)
   lang := GOOGLE_GO_LANGUAGE_ID;
   if (ext_MaybeRecycleTagFile(tfindex, auto tagfilename, lang, GOOGLE_GO_LANGUAGE_ID)) {
      return 0;
   }

   // IF the user does not have an extension specific tag file for this language
   status := 0;
   goPath := '';
#if !__UNIX__
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment",
                            "GOROOT", goPath);
   //if (!status) {
   //   compiler_binary = compiler_binary :+ "\\bin\\go.exe";
   //}
#endif
   if (goPath=='') {
      // look for gofmt, since there may be other things named go
      goPath = path_search("gofmt", "", "P");
   }
//#if !__UNIX__
//   if (d_compiler_binary=='') {
//      d_compiler_binary='C:\Program Files\DigitalMars\dmd\bin\dmd.exe';
//   }
//#endif
   if (goPath == '') return 1;

   //std_libs := _strip_filename(d_compiler_binary, 'N');
   //if (last_char(std_libs)==FILESEP) std_libs=substr(std_libs, 1, length(std_libs)-1);
   //std_libs = _strip_filename(std_libs, 'N');
   //if (last_char(std_libs)==FILESEP) std_libs=substr(std_libs, 1, length(std_libs)-1);
   //std_libs :+= FILESEP;
   //std_libs :+= "src";
   //std_libs :+= FILESEP;
   //std_libs :+= "phobos";
   //std_libs :+= FILESEP;
   //std_libs :+= "*.d";
   _maybe_append_filesep(goPath);
   std_libs := goPath :+ 'src' :+ FILESEP :+ '*.go';
   say('std_libs is 'std_libs);

// Build and Save tag file
   return ext_BuildTagFile(tfindex, tagfilename, lang, "Google Go Compiler Libraries",
                           true, std_libs, ext_builtins_path(lang, GOOGLE_GO_LANGUAGE_ID));
}


///**
// * @see _java_find_context_tags
// */
//int _d_find_context_tags(_str (&errorArgs)[],_str prefixexp,
//                         _str lastid,int lastidstart_offset,
//                         int info_flags,typeless otherinfo,
//                         boolean find_parents,int max_matches,
//                         boolean exact_match, boolean case_sensitive,
//                         int filter_flags=VS_TAGFILTER_ANYTHING,
//                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
//                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
//{
//   status := _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
//                                     info_flags,otherinfo,find_parents,max_matches,
//                                     exact_match,case_sensitive,
//                                     filter_flags,context_flags,visited,depth);
//
//   // if we were looking up an operator and didn't find it, out of desparation
//   // try for the "_r" version of the operator.
//   if (status && (info_flags & VSAUTOCODEINFO_CPP_OPERATOR)) {
//      status = _java_find_context_tags(errorArgs,prefixexp,lastid:+"_r",lastidstart_offset,
//                                       info_flags,otherinfo,find_parents,max_matches,
//                                       exact_match,case_sensitive,
//                                       filter_flags,context_flags,visited,depth);
//   }
//
//   return status;
//}
