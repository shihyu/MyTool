////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45203 $
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
#import "c.e"
#import "cjava.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "main.e"
#import "math.e"
#import "objc.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#endregion

/**
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link _c_get_expression_info()}.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastid_prefix      prefix of identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_*
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _c_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match,boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth,"_c_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   }

   // hook for javadoc tags, adapted to find-context tags.
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth);
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         _CodeHelpListLabels(0, 0, lastid, '',
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // special case for #import or #require "string.e"
   if ((prefixexp == '#import' || prefixexp=="#require" || prefixexp=="#include") &&
       (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {

      boolean been_there_done_that:[];
      num_headers := 0;
      prefixChar := get_text(1, lastidstart_offset-1);
      extraDir := "";
      lastid = strip(lastid, "B", "\"");
      last_slash := lastpos("/", lastid);
      if (last_slash==0) {
         last_slash = lastpos("\\", lastid);
      }
      if (last_slash) {
         extraDir = substr(lastid,1,last_slash);
         lastid = substr(lastid,last_slash+1);
      }

      if (prefixChar != '<') {
         num_headers += insert_files_of_extension(0, 0,
                                                  p_buf_name,
                                                  ";h;hpp;hxx;inl;hxx;hh;qth;;",
                                                  false, extraDir, true,
                                                  lastid, exact_match);
         been_there_done_that:[_file_case(_strip_filename(p_buf_name, 'N'))] = true;
      }

      origProjectFileName := _project_get_filename();
      info := _ProjectGet_IncludesList(_ProjectHandle(), _project_get_section(gActiveConfigName));
      info = _absolute_includedirs(info, origProjectFileName);
      while (info != "") {
         if (_CheckTimeout()) break;
         _str includePath='';
         parse info with includePath PATHSEP info;
         _maybe_append_filesep(includePath);
         if (been_there_done_that._indexin(_file_case(includePath))) continue;
         been_there_done_that:[_file_case(includePath)] = true;
         includePath = includePath:+"junk.h";
         num_headers += insert_files_of_extension(0, 0,
                                                  includePath,
                                                  ";h;hpp;hxx;inl;hxx;hh;qth;;",
                                                  false, extraDir, true,
                                                  lastid, exact_match);
      }

      _str allProjectFiles[];
      allProjectFiles = _WorkspaceFindAllProjectsWithFile(p_buf_name, _workspace_filename, true);
      foreach (auto projectFileName in allProjectFiles) {
         if (_CheckTimeout()) break;
         if (file_eq(projectFileName, origProjectFileName )) {
            continue;
         }
         info = _ProjectGet_IncludesList(_ProjectHandle(projectFileName), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, projectFileName);
         while (info != "") {
            if (_CheckTimeout()) break;
            _str includePath='';
            parse info with includePath PATHSEP info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath = includePath:+"junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }

      }

      if (prefixChar == '<') {
         info = _ProjectGet_SysIncludesList(_ProjectHandle(), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, origProjectFileName);
         while (info!='') {
            if (_CheckTimeout()) break;
            _str includePath='';
            parse info with includePath PATHSEP info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath = includePath:+"junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }

         info = _ProjectGet_SystemIncludes(_ProjectHandle(), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, origProjectFileName);
         while (info!='') {
            if (_CheckTimeout()) break;
            _str includePath='';
            parse info with includePath PATHSEP info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath = includePath:+"junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }
      }

      errorArgs[1] = lastid;
      return (num_headers==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   // watch out for unwelcome 'new' as part of prefix expression
   boolean is_new_expr = false;
   if (pos("new ", prefixexp) == 1) {
      prefixexp = substr(prefixexp, 5);
      is_new_expr = true;
   } else if (pos("gcnew ", prefixexp) == 1) {
      prefixexp = substr(prefixexp, 7);
      is_new_expr = true;
   }
   if (_chdebug > 0) {
      say("_c_find_context_tags: prefixexp is_new_expr="is_new_expr);
   }
   
   //say("_c_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // context is in using or import statement?
   if (prefixexp == '' && (info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT)) {
      num_imports := 0;
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_imports, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
      return (num_imports > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // clear match set
   num_matches := 0;
   constructor_class := "";
   tag_clear_matches();

   // maybe prefix expression is a package name or prefix of package name
   package_prefix := prefixexp:+lastid;
   if (pos('::',prefixexp) > 0 &&
       tag_check_for_package(package_prefix,tag_files,false,true)) {
      tag_push_matches();
      tag_list_context_packages(0,0,package_prefix,tag_files,num_matches,max_matches,false,true);
      int start = length(package_prefix);
      VS_TAG_BROWSE_INFO package_names[];
      for (i:=1; i<=tag_get_num_of_matches(); ++i) {
         _str pkg_name;
         tag_get_detail2(VS_TAGDETAIL_match_name,i,pkg_name);
         if (pos(package_prefix, pkg_name)!=1 ||
             length(pkg_name)<start || (exact_match && length(pkg_name)>start)) {
            continue;
         }
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i, cm);
         package_names[package_names._length()]=cm;
         if (num_matches+package_names._length() > max_matches) {
            break;
         }
      }
      tag_pop_matches();
      for (i=0; i<package_names._length(); ++i) {
         tag_insert_match_info(package_names[i]);
         if (++num_matches > max_matches) break;
      }
   }

   //say "_c_find_context_tags"
   tag_push_matches();
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   int status = 0;
   if (prefixexp!='') {
      // handle 'new' expressions as a special case
      if ((pos('new ',prefixexp' ')==1 || pos('gcnew ',prefixexp' ')==1)) {
         _str outer_class = substr(prefixexp, 5);
         if (substr(prefixexp,1,2)=='gc') {
            outer_class = substr(prefixexp, 7);
         }
         if (last_char(outer_class)==':') {
            outer_class = substr(outer_class, 1, length(outer_class)-2);
         }
         if (last_char(outer_class)=='.') {
            outer_class = substr(outer_class, 1, length(outer_class)-1);
         }
         outer_class = stranslate(outer_class, ':', '::');
         
         if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
            // In this case, we're (probably) moving through a complete constructor
            if (outer_class=='') {
               tag_qualify_symbol_name(constructor_class, lastid, 
                                       '', p_buf_name, tag_files, 
                                       true, visited, 0);
            } else {
               constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true);
            }
         } else {
            // In this case, they're probably still typing the constructor name, so
            // don't count on outer_class actually being a class name, do a more lenient
            // match.
            status = tag_list_symbols_in_context(outer_class, null, 0, 0, tag_files, '', num_matches, max_matches,
                                                 VS_TAGFILTER_ANYTHING,
                                                 VS_TAGCONTEXT_ONLY_classes, exact_match, case_sensitive, visited, depth);
            if (_chdebug > 9) {
               isay(depth, "_c_find_context_tags: loose match "status", nm="num_matches);
               if (_chdebug) {
                  isay(depth,"_c_find_context_tags: num_matches="num_matches);
                  int i,n = tag_get_num_of_matches();
                  for (i=1; i<=n; ++i) {
                     VS_TAG_BROWSE_INFO cm;
                     tag_get_match_info(i, cm);
                     tag_browse_info_dump(cm, "_c_find_context_tags", 1);
                  }
               }
            }
         
            if (status) {
               tag_pop_matches();
               return (status);
            } else {
               tag_join_matches();
               return 0;
            }
         }
      }

      // evaluate the prefix expression to set up the return type 'rt'
      status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited);
      if (status) {
         tag_pop_matches();
         return status;
      }

      if (_chdebug) {
         tag_return_type_dump(rt, "_c_find_context_tags");
      }

      if (!rt.istemplate) {
         rt.template_args._makeempty();
         rt.template_names._makeempty();
         rt.template_types._makeempty();
      }

      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
   }
   tag_pop_matches();

   // this instance is not a function, so mask it out of filter flags
   //int filter_flags=VS_TAGFILTER_ANYTHING;
   //if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
   //   filter_flags &= ~(VS_TAGFILTER_PROC|VS_TAGFILTER_PROTO);
   //}

   // get the current class and current package from the context
   cur_tag_name := cur_type_name := "";
   cur_context := cur_class := cur_package := "";
   cur_flags := cur_type_id := cur_scope_seekpos := 0;
   context_id := tag_get_current_context(cur_tag_name, cur_flags,
                                         cur_type_name, cur_type_id,
                                         cur_context, cur_class,
                                         cur_package);
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, cur_scope_seekpos);
   }

   // properly qualify the current scope
   if (cur_context != '') {
      VS_TAG_RETURN_TYPE scope_rt;
      tag_return_type_init(scope_rt);
      tag_push_matches();
      if (_chdebug) {
         say("_c_find_context_tags: EVALUATING CURRENT CLASS SCOPE, cur_class_name="cur_context);
      }
      if (!_c_parse_return_type(errorArgs, tag_files,
                                cur_tag_name, cur_package,
                                p_buf_name, cur_context,
                                false, scope_rt, 
                                visited, depth+1)) {
         cur_context = tag_return_type_string(rt);
      }
      tag_pop_matches();
   }

   // attempt to properly qualify the current scope
   _str inner_name='',outer_name='',qualified_name='';
   tag_split_class_name(cur_context,inner_name,outer_name);
   tag_qualify_symbol_name(qualified_name, 
                           inner_name, outer_name,
                           p_buf_name, tag_files,
                           true, visited);
   if (qualified_name!='' && qualified_name!=inner_name) {
      cur_context=qualified_name;
   }

   // report information about current scope
   if (_chdebug) {
      say("_c_find_context_tags: context_id="context_id" tag="cur_tag_name" scope="cur_context);
   }
   
   // if the current tag is a function, but not necessarily static or inline
   // try to find its matching prototype.
   if (context_id>0 && cur_type_id==VS_TAGTYPE_function &&
       cur_context!='' && !(cur_flags & VS_TAGFLAG_static)) {
      _str cur_arguments='';
      tag_get_detail2(VS_TAGDETAIL_context_args,context_id,cur_arguments);

      // first try to find the tag within the current context
      int i;
      int found_flags=0;
      _str found_type_name='';
      _str found_args='';

      status = 0;
      i=tag_find_context_iterator(cur_tag_name,true,true,false,cur_context);
      while (i>0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,i,found_type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags,i,found_flags);
         tag_get_detail2(VS_TAGDETAIL_context_args,i,found_args);
         if (found_type_name=='proto' &&
             !tag_tree_compare_args(VS_TAGSEPARATOR_args:+cur_arguments,
                                    VS_TAGSEPARATOR_args:+found_args,false)) {
            break;
         }
         i=tag_next_context_iterator(cur_tag_name,i,true,true,false,cur_context);
      }
      // no luck, try the tag files
      if (i<0) {
         for (i=0;;) {
            _str tf = next_tag_filea(tag_files,i,false,true);
            if (tf=='') {
               break;
            }
            status = tag_find_tag(cur_tag_name,"proto",cur_context);
            while (!status) {
               tag_get_detail(VS_TAGDETAIL_arguments,found_args);
               tag_get_detail(VS_TAGDETAIL_flags,found_flags);
               if (!tag_tree_compare_args(VS_TAGSEPARATOR_args:+cur_arguments,
                                          VS_TAGSEPARATOR_args:+found_args,false)) {
                  break;
               }
               status=tag_next_tag(cur_tag_name,"proto",cur_context);
            }
            tag_reset_find_tag();
         }
      }
      // we found a match, pull over the flags
      if (!status) {
         cur_flags |= (found_flags & (VS_TAGFLAG_static|VS_TAGFLAG_inline|VS_TAGFLAG_virtual));
      }
   }

   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==VS_TAGTYPE_function && cur_context!='' && prefixexp=='') {
      if (!(context_flags & VS_TAGCONTEXT_FIND_lenient) && (cur_flags & VS_TAGFLAG_static)) {
         context_flags |= VS_TAGCONTEXT_ONLY_static;
      }
   }

   // are we in a class scope?
   if (prefixexp=='' && cur_context!='') {
      rt.return_type = cur_context;
      if (_QROffset() >= cur_scope_seekpos) {
         context_flags |= VS_TAGCONTEXT_ALLOW_protected|VS_TAGCONTEXT_ALLOW_private;
      }
      if (info_flags & (VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) {
         context_flags |= VS_TAGCONTEXT_ONLY_inclass|VS_TAGCONTEXT_ONLY_this_class|VS_TAGCONTEXT_ONLY_data;
      }
   }

   // propagate private, protected, package flags
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
      context_flags |= VS_TAGCONTEXT_ALLOW_private;
      context_flags |= VS_TAGCONTEXT_ALLOW_protected;
      context_flags |= VS_TAGCONTEXT_ALLOW_package;
   } 

   // compute current context, package name, and class name to
   // determine unusual access restrictions for java
   if ((pos(cur_package'/',rt.return_type)==1) ||
       (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
        !pos(VS_TAGSEPARATOR_package,cur_class))) {
      context_flags |= VS_TAGCONTEXT_ALLOW_package;
      context_flags |= VS_TAGCONTEXT_ALLOW_protected;
   }

   // construct context flags for the first, very targetted search
   int first_context_flags = context_flags;
   first_context_flags |= VS_TAGCONTEXT_ALLOW_any_tag_type;
   if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      first_context_flags |= VS_TAGCONTEXT_ALLOW_locals;
   }

   // not a function call?
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(VS_TAGFILTER_PROC|VS_TAGFILTER_PROTO);
   }
   if (info_flags & VSAUTOCODEINFO_HAS_CLASS_SPECIFIER) {
      filter_flags &= ~(VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYCONSTANT|VS_TAGFILTER_ANYDATA);
      filter_flags |= VS_TAGFILTER_STRUCT|VS_TAGFILTER_PACKAGE|VS_TAGFILTER_INTERFACE;
      filter_flags |= VS_TAGFILTER_DEFINE;
   }
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      filter_flags = VS_TAGFILTER_LABEL;
      filter_flags |= VS_TAGFILTER_DEFINE;
   }

   // Allow non-static functions to be listed if they are typing
   // a member function definition
   if ((context_flags & VS_TAGCONTEXT_ONLY_static) && 
       rt.return_type!='' && cur_type_name=='' &&
       length(prefixexp) > 2 && substr(prefixexp, length(prefixexp)-1, 2) :== '::') {
      context_flags &= ~VS_TAGCONTEXT_ONLY_static;
   }

   // now update the #define parameters
   if ( cur_type_name=='define' && exact_match && prefixexp=='' ) {
      // insert parameters of #define statement or template class
      int orig_num_matches=num_matches;
      _ListParametersOfDefine(0, 0, num_matches, max_matches, lastid);
      if (num_matches > orig_num_matches) return 0;
   }

   // insert 'this' keyword
   if ( prefixexp == "" ) {
      thisVar := _LanguageInheritsFrom("m")? "self" : "this";
      _CodeHelpMaybeInsertThis(lastid, thisVar, tag_files, 
                               filter_flags, context_flags, 
                               exact_match, case_sensitive);
   }

   // check for C++ overloaded operators
   if (pos('operator ', lastid, 1)) {
      parse lastid with . lastid;
   }

   // get the list of friend relationships for the current context
   friend_list := "";
   if (  _LanguageInheritsFrom("c") && 
         !_LanguageInheritsFrom("d") && 
         !_LanguageInheritsFrom("cs") && 
         !_LanguageInheritsFrom("java") && 
         !_LanguageInheritsFrom("m")) {
      tag_find_friends_to_tag(cur_tag_name, cur_context, tag_files, friend_list);
   }
   // report debug information about the current class
   if (_chdebug) {
      say("_c_find_context_tags: tag="cur_tag_name" type="cur_type_name" flags="cur_flags" class="cur_context" only="cur_class" package="cur_package);
   }

   if ( _LanguageInheritsFrom("c") || _LanguageInheritsFrom('m')) {
      context_flags |= VS_TAGCONTEXT_NO_selectors | VS_TAGCONTEXT_NO_groups;
   }

   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) && prefixexp == "") {
      tag_list_class_locals(0, 0, null, lastid, "",
                            filter_flags, context_flags,
                            num_matches, max_matches,
                            exact_match, case_sensitive,
                            friend_list, visited, depth);
      if (_chdebug) {
         say("_c_find_context_tags: LOCALS num_matches="num_matches);
      }
   } else if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
       (rt.return_type=='::' || rt.return_type=='')) {
      // :: operator
      tag_list_context_globals(0,0,lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
      if (_chdebug) {
         say("_c_find_context_tags: GLOBALS num_matches="num_matches);
      }
   } else if (rt.return_type != "") {
      if (!(context_flags & VS_TAGCONTEXT_ONLY_locals)) {
         tag_list_in_class(lastid, rt.return_type,
                           0, 0, tag_files,
                           num_matches, max_matches,
                           filter_flags, context_flags,
                           exact_match, case_sensitive,
                           rt.template_args, friend_list, 
                           visited, depth);
         if (_chdebug) {
            say("_c_find_context_tags: IN CLASS num_matches="num_matches);
         }
      }
   }

   // try to match local variables first
   // only do this if searching for exact matches.
   // use language-specific case sensitivity rules here
   // because if we find something we might shortcut the search,
   // so we need to know we found a real match.
   orig_num_matches := num_matches;
   if (exact_match && prefixexp=='' && (context_flags & VS_TAGCONTEXT_ALLOW_locals)) {
      tag_list_symbols_in_context(lastid, '', 0, 0, tag_files, '', 
                                  num_matches, max_matches, 
                                  filter_flags, 
                                  first_context_flags|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_locals,
                                  exact_match, case_sensitive, 
                                  visited, depth, 
                                  rt.template_args);
      if (_chdebug) {
         say("_c_find_context_tags: IN CONTEXT num_matches="num_matches);
      }
   }

   // try to match the symbol in the current context
   //say("_c_find_context_tags: rt.return_type="rt.return_type);
   if (_chdebug) {
      _dump_var(rt, "_c_find_context_tags");
   }
   int context_list_flags = 0;
   if (prefixexp == "") context_list_flags |= VS_TAGCONTEXT_ALLOW_locals;
   if (find_parents)    context_list_flags |= VS_TAGCONTEXT_FIND_parents;
   if (rt.return_type != '' && prefixexp != '') {
      context_list_flags |= VS_TAGCONTEXT_NO_globals;
   }

   if (_LanguageInheritsFrom("c") || _LanguageInheritsFrom('m')) {
      context_list_flags |= VS_TAGCONTEXT_NO_selectors | VS_TAGCONTEXT_NO_groups;
   }

   if (num_matches == orig_num_matches || 
       (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) || 
       (context_flags & VS_TAGCONTEXT_FIND_all)) {
      tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                  tag_files, '',
                                  num_matches, max_matches,
                                  filter_flags, first_context_flags | context_list_flags,
                                  exact_match, case_sensitive, 
                                  visited, depth, rt.template_args);
      if (_chdebug) {
         say("_c_find_context_tags: IN CONTEXT FIND ALL num_matches="num_matches);
      }
   }

   // check for prefix match with overloaded operators
   if (!exact_match && rt.return_type != "" &&
       !(context_flags & VS_TAGCONTEXT_ONLY_locals) && 
       !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) && 
       _CodeHelpDoesIdMatch(lastid, "operator ", false, true)) {
      foreach (auto op in "~ ! ^ & | ( [ - + * / % = < > ? new delete") {
         tag_list_in_class(op, rt.return_type, 0, 0, tag_files, 
                           num_matches, max_matches, 
                           filter_flags, context_flags, 
                           exact_match, case_sensitive, 
                           rt.template_args, friend_list, visited, depth);
      }
      if (_chdebug) {
         say("_c_find_context_tags: OPERATORS num_matches="num_matches);
      }
   }

   // try listing symbols in context, looking for globals this time instead
   // of symbols from the current scope, unless we are already in global scope
   if (rt.return_type != "" && prefixexp=="") {
      if (num_matches == orig_num_matches || 
          (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) || 
          (context_flags & VS_TAGCONTEXT_FIND_all)) {
         tag_list_symbols_in_context(lastid, '', 0, 0, 
                                     tag_files, '',
                                     num_matches, max_matches,
                                     filter_flags, first_context_flags | context_list_flags,
                                     exact_match, case_sensitive, 
                                     visited, depth, rt.template_args); 
         if (_chdebug) {
            say("_c_find_context_tags: IN CONTEXT FIND ALL 2 num_matches="num_matches);
         }
      }
   }

   // try case insensitive match
   if (num_matches == orig_num_matches) {
      tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                  tag_files, '',
                                  num_matches, max_matches,
                                  filter_flags, 
                                  context_flags | context_list_flags | VS_TAGCONTEXT_ALLOW_any_tag_type | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals),
                                  exact_match, case_sensitive, 
                                  visited, depth, rt.template_args); 
      if (_chdebug) {
         say("_c_find_context_tags: CASE INSENSITIVE num_matches="num_matches);
      }
   }

   if (constructor_class!='') {
      constructor_name := lastid;
      if (_LanguageInheritsFrom('phpscript')) {
         constructor_name = "__construct";
      }
      if (_LanguageInheritsFrom('d')) {
         constructor_name = "this";
      }
      if (!(info_flags & VS_TAGCONTEXT_ONLY_locals)) {
         tag_list_in_class(constructor_name, constructor_class, 
                           0, 0, tag_files, 
                           num_matches, max_matches,
                           filter_flags, 
                           context_flags|VS_TAGCONTEXT_ONLY_constructors|VS_TAGCONTEXT_ONLY_this_class,
                           exact_match, case_sensitive, 
                           rt.template_args, friend_list,
                           visited, depth);
         if (_chdebug) {
            say("_c_find_context_tags: CONSTRUCTORS num_matches="num_matches);
         }
      }
   }

   if (_chdebug) {
      isay(depth,"_c_find_context_tags: num_matches="num_matches);
      int i,n = tag_get_num_of_matches();
      for (i=1; i<=n; ++i) {
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i, cm);
         tag_browse_info_dump(cm, "_c_find_context_tags", 1);
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

