////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49622 $
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
#include "tagsdb.sh"
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "cbrowser.e"
#import "cjava.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "main.e"
#import "setupext.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

defload()
{
   _str setup_info='MN=JavaScript,TABS=+4,MA=1 74 1,':+
                   'KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=JavaScript,CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 ':+   // <Syntax indent amount>  <expansion on/off>
                    '1 0 4 ':+ // <min abbrev> <not used> <not used>
                    '1 1';     //notused> <notused>
   _str be_info='';
   
   _CreateLanguage("js", "JavaScript",
                   setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("js", "js");
   _CreateExtension("ds", "js");
}

int _js_MaybeBuildTagFile(int &tfindex)
{
   _str ext='js';
   _str base_name="javascript";

   // recycle the javascript tag file
   _str tagfilename='';
   boolean recycle_js = ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,base_name);
   if (recycle_js && tag_read_db(tagfilename)>=0) {
      _str builtins_js = '';
      if (tag_find_file(builtins_js, ext_builtins_path(ext, 'js'))==0) {
         recycle_js = false;
      }
      tag_reset_find_file();
   }

   // build the portable javascript.vtg tag file
   int status=ext_MaybeBuildTagFile(tfindex,ext,base_name,"JavaScript Builtins");

   // that's all folks
   return(status);
}

int _js_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

int _js_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

int _js_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}

int _js_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

int _js_fcthelp_get_start(_str (&errorArgs)[],
                          boolean OperatorTyped,
                          boolean cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}

int _js_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          boolean find_parents,int max_matches,
                          boolean exact_match,boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_clear_matches();
   errorArgs._makeempty();
   if (_chdebug) {
      isay(depth,"_js_find_context_tags: lastid="lastid" prefixexp="prefixexp" otherinfo="otherinfo);
   }

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // watch out for unwelcome 'new' as prefix expression
   if (strip(prefixexp)=='new') {
      prefixexp='';
   }

   // get the list of tag files
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // get the current class and current package from the context
   cur_class_name := cur_package_name := cur_type_name := class_name := "";
   context_id := tag_current_context();
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
      if (tag_tree_type_is_class(cur_type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, class_name);
         cur_class_name = tag_join_class_name(class_name, cur_class_name, tag_files, true);
      }
      if (tag_tree_type_is_package(cur_type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_package_name);
      } else if (pos(VS_TAGSEPARATOR_package, cur_class_name)) {
         cur_package_name = substr(cur_class_name, 1, pos('S')-1);
      }


      tag_get_context_info(context_id, auto cm);
   }

   num_matches := 0;
   // no prefix expression, update globals and symbols from current context

   if (prefixexp == '') {
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         tag_list_class_locals(0, 0, tag_files, lastid, "",
                               filter_flags, context_flags,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               null, visited, depth);
      }

      // now update the globals in the current buffer
      if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) &&
          !(context_flags & VS_TAGCONTEXT_NO_globals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_class)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
      }

      // now update the external globals
      if (!(context_flags & VS_TAGCONTEXT_NO_globals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_file) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_class)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
      }

      if (_chdebug) {
         isay(depth,"_js_find_context_tags: num_matches="num_matches);
         int i,n = tag_get_num_of_matches();
         for (i=1; i<=n; ++i) {
            VS_TAG_BROWSE_INFO cm;
            tag_get_match_info(i, cm);
            tag_browse_info_dump(cm, "_js_find_context_tags", 1);
         }
      }

      // all done
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // maybe prefix expression is a package name or prefix of package name
   is_package := false;
   word_chars := _clex_identifier_chars();
   if (pos("^[."word_chars"]@$", prefixexp, 1, 'r')) {
      is_package = _CodeHelpListPackages(0, 0, 
                                         p_window_id, tag_files,
                                         prefixexp, lastid,
                                         num_matches, max_matches,
                                         exact_match, case_sensitive);
   }

   // evaluate the type of the prefix expression
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   status := _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
   if (!status) {
      if (pos(cur_package_name'/',rt.return_type)==1) {
         context_flags |= VS_TAGCONTEXT_ALLOW_package;
      }
      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
      tag_list_in_class(lastid, rt.return_type,
                        0, 0, tag_files,
                        num_matches, max_matches,
                        filter_flags, context_flags,
                        exact_match, case_sensitive, 
                        null, null, visited, depth+1);

      // Also list the items for the base class Object from which all classes inherit.
      tag_list_in_class(lastid, "Object",
                        0, 0, tag_files,
                        num_matches, max_matches,
                        filter_flags, context_flags,
                        exact_match, case_sensitive, 
                        null, null, visited, depth+1);
   }

   // filter out the tag files that do not have javascript or tagdoc
   // and then list only javascript symbols, anything that matches
   if (num_matches == 0 ) {
      file_name := "";
      _str js_tag_files[];
      for (i:=0; i<tag_files._length(); i++) {
         status = tag_read_db(tag_files[i]);
         if (status >= 0) {
            dummy_lang := '';
            if (tag_find_language(dummy_lang, 'js') < 0 && 
                tag_find_language(dummy_lang, 'tagdoc') < 0) {
               tag_reset_find_language();
               continue;
            }
            tag_reset_find_language();
            js_tag_files[js_tag_files._length()] = tag_files[i];
         }
      }

      tag_list_any_symbols( 0, 0, lastid, js_tag_files, 
                            filter_flags, context_flags, 
                            num_matches, max_matches, 
                            exact_match, case_sensitive );
   }

   // last gasp effort, delegate to _java_find_context_tags()
   if (num_matches == 0) {
      return _java_find_context_tags(errorArgs,
                                     prefixexp,
                                     lastid, lastidstart_offset,
                                     info_flags, otherinfo,
                                     false, max_matches,
                                     exact_match, case_sensitive,
                                     filter_flags, context_flags,
                                     visited, depth);
   }

   // Success!
   return 0;
}

boolean _js_find_surround_lines(int &first_line, int &last_line, 
                                int &num_first_lines, int &num_last_lines, 
                                boolean &indent_change, 
                                boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}

int _js_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix="", 
                                 boolean exact_match=false, boolean case_sensitive=true)
{
   return _java_insert_constants_of_type(rt_expected,
                                         tree_wid,tree_index,
                                         lastid_prefix,
                                         exact_match,case_sensitive);
}

_str _js_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}

int _js_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}

int _js_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
