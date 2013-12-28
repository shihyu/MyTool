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
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#require "se/lang/api/LanguageSettings.e"
#import "cjava.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "slickc.e"
#import "tags.e"
#import "util.e"
#import "sftp.e"
#endregion

using se.lang.api.LanguageSettings;


#define D_LANGUAGE_ID "d"

defload()
{
   setup_info   := "MN=D,TABS=+8,MA=1 74 1,KEYTAB=c-keys,WW=0,IWT=0,ST="DEFAULT_SPECIAL_CHARS",IN=2,WC=A-Za-z0-9_$,LN=D,CF=1,LNL=0,TL=-1";
   compile_info := "dmd";
   syntax_info  := "4 1 1 0 1029 1 1 0 0";
   be_info      := "";
   word_chars   := "A-Za-z0-9_$\\p{L}";

   _CreateLanguage(D_LANGUAGE_ID, 
                   upcase(D_LANGUAGE_ID), 
                   setup_info, 
                   compile_info, 
                   syntax_info, 
                   be_info, 
                   "", 
                   word_chars, 
                   upcase(D_LANGUAGE_ID));
   _CreateExtension(D_LANGUAGE_ID, D_LANGUAGE_ID);
   _SetLanguageInheritsFrom(D_LANGUAGE_ID, 'c');
   _CreateExtension("di", D_LANGUAGE_ID);
   LanguageSettings.setReferencedInLanguageIDs(D_LANGUAGE_ID, 'ansic asm c masm s unixasm');
}



int _d_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   lang := 'd';
   if (ext_MaybeRecycleTagFile(tfindex,auto tagfilename,lang,"d")) {
      return(0);
   }

   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   d_compiler_binary := '';
#if !__UNIX__
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            "SOFTWARE\\DigitalMars\\DMD",
                            "BIN", d_compiler_binary);
   if (!status) {
      d_compiler_binary = d_compiler_binary :+ "\\dmd.exe";
   }
#endif
   if (d_compiler_binary=='') {
      d_compiler_binary=path_search("dmd","","P");
   }
#if !__UNIX__
   if (d_compiler_binary=='') {
      d_compiler_binary='C:\Program Files\DigitalMars\dmd\bin\dmd.exe';
   }
#endif

   std_libs := _strip_filename(d_compiler_binary, 'N');
   if (last_char(std_libs)==FILESEP) std_libs=substr(std_libs, 1, length(std_libs)-1);
   std_libs = _strip_filename(std_libs, 'N');
   if (last_char(std_libs)==FILESEP) std_libs=substr(std_libs, 1, length(std_libs)-1);
   std_libs :+= FILESEP;
   std_libs :+= "src";
   std_libs :+= FILESEP;
   std_libs :+= "phobos";
   std_libs :+= FILESEP;
   std_libs :+= "*.d";

// Build and Save tag file
   return ext_BuildTagFile(tfindex,tagfilename,lang,"D Compiler Libraries",
                           true,std_libs,ext_builtins_path(lang,'d'));
}


/**
 * @see _java_find_context_tags
 */
int _d_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match, boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   status := _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                     info_flags,otherinfo,find_parents,max_matches,
                                     exact_match,case_sensitive,
                                     filter_flags,context_flags,visited,depth);

   // if we were looking up an operator and didn't find it, out of desparation
   // try for the "_r" version of the operator.
   if (status && (info_flags & VSAUTOCODEINFO_CPP_OPERATOR)) {
      status = _java_find_context_tags(errorArgs,prefixexp,lastid:+"_r",lastidstart_offset,
                                       info_flags,otherinfo,find_parents,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,visited,depth);
   }

   return status;
}
