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
// Language support module for Apple Swift 1.x and 2.x
//
#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#import "ccontext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "tags.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

static const SWIFT_LANGUAGE_ID= 'swift';

_command swift_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(SWIFT_LANGUAGE_ID);
}

int _swift_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   lang := "swift";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,lang,lang) && !forceRebuild) {
      return(0);
   }

   //// IF the user does not have an extension specific tag file for Slick-C
   //int status=0;
   //_str perl_binary='';
   //if (_isWindows()) {
   //   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
   //                            "SOFTWARE\\ActiveWare\\Perl5",
   //                            "BIN", perl_binary);
   //   if (!status) {
   //      perl_binary = perl_binary :+ "\\perl.exe";
   //   }
   //}
   //if (perl_binary=='') {
   //   perl_binary=path_search("perl","","P");
   //}
   //if (_isWindows()) {
   //   if (perl_binary=='') {
   //      perl_binary=_path2cygwin('/bin/perl.exe');
   //   }
   //}
   //
   //std_libs := get_perl_std_libs(perl_binary);
   std_libs := "";

   // Build and Save tag file
   return ext_BuildTagFile(tfindex,
                           tagfilename,
                           lang,
                           "Swift Libraries",
                           true,
                           std_libs,
                           ext_builtins_path(lang,lang), 
                           withRefs, 
                           useThread);
}


int _swift_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                             _str lastid,int lastidstart_offset,
                             int info_flags,typeless otherinfo,
                             bool find_parents,int max_matches,
                             bool exact_match, bool case_sensitive,
                             SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                             SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                             VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _c_find_context_tags(errorArgs,prefixexp,
                               lastid,lastidstart_offset,
                               info_flags,otherinfo,
                               find_parents,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,
                               visited,depth,
                               prefix_rt);
}
