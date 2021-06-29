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
#import "cidexpr.e"
#import "cjava.e"
#import "context.e"
#import "csymbols.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "slickc.e"
#import "tags.e"
#import "util.e"
#import "sftp.e"
#require "se/lang/api/ExtensionSettings.e"
#endregion


using se.lang.api.ExtensionSettings;

int _properties_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

_str _properties_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0, _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null)
{
   if (info == null) {
      return '';
   }
   return decl_indent_string:+info.member_name:+'='info.return_type;
}

int _properties_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                  _str lastid,int lastidstart_offset,
                                  int info_flags,typeless otherinfo,
                                  bool find_parents,int max_matches,
                                  bool exact_match, bool case_sensitive,
                                  SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                  SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                  VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                  VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}
