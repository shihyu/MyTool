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


#define PROPERTIES_LANGUAGE_ID "properties"
#define PROPERTIES_MODENAME_ID "Java Properties"
#define PROPERTIES_WORDCHARS   "A-Za-z0-9_$."

using se.lang.api.ExtensionSettings;

defload()
{
   setup_info   := "MN="PROPERTIES_MODENAME_ID",TABS=+8,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST="DEFAULT_SPECIAL_CHARS",IN=2,WC="PROPERTIES_WORDCHARS",LN="PROPERTIES_MODENAME_ID",CF=1,";
   compile_info := "";
   syntax_info  := "4 1 1 0 4 1 1";
   be_info      := "";
   word_chars   := PROPERTIES_WORDCHARS;

   _CreateLanguage(PROPERTIES_LANGUAGE_ID,
                   PROPERTIES_MODENAME_ID,
                   setup_info,
                   compile_info,
                   syntax_info,
                   be_info,
                   "",
                   word_chars,
                   PROPERTIES_MODENAME_ID);
   _CreateExtension(PROPERTIES_LANGUAGE_ID, PROPERTIES_LANGUAGE_ID);
   ExtensionSettings.setLangRefersTo('properties', 'properties');
}

int _properties_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
                         boolean find_parents,int max_matches,
                         boolean exact_match, boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth);
}
