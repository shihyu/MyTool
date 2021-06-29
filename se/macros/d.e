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
#import "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "cjava.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "slickc.e"
#import "tags.e"
#import "util.e"
#import "sftp.e"
#endregion

using se.lang.api.LanguageSettings;


int _d_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   lang := 'd';
   if (ext_MaybeRecycleTagFile(tfindex,auto tagfilename,lang) && !forceRebuild) {
      return(0);
   }

   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   d_compiler_binary := '';
   if (_isWindows()) {
      status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                               "SOFTWARE\\DigitalMars\\DMD",
                               "BIN", d_compiler_binary);
      if (!status) {
         d_compiler_binary :+= "\\dmd.exe";
      }
   }
   if (d_compiler_binary=='') {
      d_compiler_binary=path_search("dmd","","P");
   }
   if (d_compiler_binary=='') {
      d_compiler_binary=path_search("ldc2","","P");
   }
   if (d_compiler_binary=='') {
      d_compiler_binary=path_search("gdc","","P");
   }
   if (_isWindows()) {
      if (d_compiler_binary=='') {
         d_compiler_binary='C:\Program Files\DigitalMars\dmd\bin\dmd.exe';
      }
   }
   if (_isUnix()) {
      if (d_compiler_binary=='' && file_exists("/usr/local/bin/ldc2")) {
         d_compiler_binary="/usr/local/bin/ldc2";
      }
      if (d_compiler_binary=='' && file_exists("/usr/local/bin/gdc")) {
         d_compiler_binary="/usr/local/bin/gdc";
      }
   }

   std_libs := _strip_filename(d_compiler_binary, 'N');
   _maybe_strip_filesep(std_libs);
   std_libs = _strip_filename(std_libs, 'N');
   _maybe_strip_filesep(std_libs);
   base_libs := std_libs;
   std_libs :+= FILESEP;
   std_libs :+= "src";
   std_libs :+= FILESEP;
   std_libs :+= "phobos";
   if (_isUnix() && !file_exists(std_libs) && file_exists(base_libs:+FILESEP:+"include/d")) {
      std_libs = base_libs:+FILESEP:+"include/d";
   }
   if (_isMac() && !file_exists(std_libs) && file_exists("/Library/D/dmd/src/phobos")) {
      std_libs = "/Library/D/dmd/src/phobos";
   }
   std_libs :+= FILESEP;
   std_libs :+= "*.d";

   // Build and Save tag file
   return ext_BuildTagFile(tfindex,tagfilename,lang,"D Compiler Libraries",
                           true,std_libs,ext_builtins_path(lang), withRefs, useThread);
}


/**
 * @see _java_find_context_tags
 */
int _d_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         bool find_parents,int max_matches,
                         bool exact_match, bool case_sensitive,
                         SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                         SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                         VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
      isay(depth, "_d_find_context_tags: ------------------------------------------------------");
      isay(depth, "_d_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case_sensitive="case_sensitive);
   }
   status := _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                     info_flags,otherinfo,find_parents,max_matches,
                                     exact_match,case_sensitive,
                                     filter_flags,context_flags,
                                     visited,depth+1,prefix_rt);

   // if we were looking up an operator and didn't find it, out of desparation
   // try for the "_r" version of the operator.
   if (status && (info_flags & VSAUTOCODEINFO_CPP_OPERATOR)) {
      status = _java_find_context_tags(errorArgs,prefixexp,lastid:+"_r",lastidstart_offset,
                                       info_flags,otherinfo,find_parents,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
   }

   return status;
}


bool _d_auto_surround_char(_str key) {
   return _c_auto_surround_char(key);
}
