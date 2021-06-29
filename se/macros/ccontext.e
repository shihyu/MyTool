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
#import "cbrowser.e"
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

static int _c_find_class_parents(_str (&errorArgs)[],
                                 _str tag_files[], 
                                 _str search_file_name,
                                 _str class_name, 
                                 _str lastid,
                                 bool exact_match,bool case_sensitive,
                                 int &num_matches, int max_matches,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // get the fully qualified parents of this class
   if (_chdebug) {
      isay(depth, "_c_find_class_parents H"__LINE__": class_name="class_name" lastid="lastid);
   }
   orig_tag_file := tag_current_db();
   parents := cb_get_normalized_inheritance(class_name, auto tag_dbs, tag_files, 
                                            check_context:true, "", search_file_name, "", 
                                            includeTemplateParameters:true, visited, depth+1);

   // add the current class name to the list (for C++11 delegating constructors)
   parents = class_name    ";" parents;
   tag_dbs = orig_tag_file ";" tag_dbs;

   // add each of them to the list also
   while (parents != "") {
      parse parents with auto cur_parent_class ";" parents;
      parse tag_dbs with auto cur_tag_file     ";" tag_dbs;
      status := tag_read_db(cur_tag_file);
      if (status < 0) {
         continue;
      }
      if (_chdebug) {
         isay(depth, "_c_find_class_parents H"__LINE__": cur_parent_class="cur_parent_class);
      }

      // add transitively inherited class members
      tag_flags := (pos('<', cur_parent_class) > 0)? SE_TAG_FLAG_TEMPLATE : SE_TAG_FLAG_NULL;
      parse cur_parent_class with cur_parent_class "<" auto template_arguments ">";
      tag_split_class_name(cur_parent_class, auto class_name_only, auto outer_class_name);

      // check if the parent matches the identifier we are looking for
      if (lastid != "") {
         class_name_prefix := class_name_only;
         if (!exact_match) {
            class_name_prefix = substr(class_name_only, 1, length(lastid));
         }
         if (case_sensitive) {
            if (lastid != class_name_prefix) continue;
         } else {
            if (!strieq(lastid, class_name_prefix)) continue;
         }
      }

      // go get those constructors
      if (_chdebug) {
         isay(depth, "_c_find_class_parents H"__LINE__": lastid="lastid" cur_parent_class="cur_parent_class);
      }
      tag_list_in_class(lastid, cur_parent_class, 
                        0, 0, tag_files, 
                        num_matches, max_matches, 
                        SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE, 
                        SE_TAG_CONTEXT_ACCESS_PRIVATE|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ONLY_CONSTRUCTORS, 
                        exact_match, case_sensitive, 
                        null, null, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_c_find_class_parents H"__LINE__": num_matches="num_matches);
      }
   }

   // return to the original tag file and return, successful
   tag_read_db(orig_tag_file);
   return 0;
}

/**
 * Table of escape sequences for C/C++ string escape sequences.
 */
_str c_string_escape_sequences:[] = _reinit {
   'n' => "Newline",
   't' => "Horizontal tab",
   'v' => "Vertical tab",
   'b' => "Backspace",
   'r' => "Carriage return",
   'f' => "Form feed",
   'a' => "Alert",
   '\' => "Backslash",
   '?' => "Question mark",
   "'" => "Single quote",
   '"' => "Double quote",
   '0' => "The null character",
   'ooo' => "Octal",
   'xhh' => "Hexadecimal",
   'uxxxx' => "Unicode (16-bit)",
   'Uxxxxxxxx' => "Unicode (32-bit)",
};

/**
 * Table of escape sequences for C/C++ string escape sequences.
 */
_str c_printf_escape_sequences:[] = _reinit {
   'd'   => "Signed decimal integer (int)",
   '2d'  => "Signed decimal integer (2 digits)",
   '4d'  => "Signed decimal integer (4 digits)",
   '-8d' => "Signed decimal integer (8 digits, left-align)",
   '+8d' => "Signed decimal integer (8 digits, right-align, with leading +/-)",
   'hhd' => "Signed decimal integer (char)",
   'hd'  => "Signed decimal integer (short)",
   'ld'  => "Signed decimal integer (long)",
   'lld' => "Signed decimal integer (long long)",
   'jd'  => "Signed decimal integer (intmax_t)",
   'zd'  => "Signed decimal integer (ssize_t)",
   'td'  => "Signed decimal integer (ptrdiff_t)",
   'i'   => "Signed decimal integer (int)",
   '2i'  => "Signed decimal integer (2 digits)",
   '4i'  => "Signed decimal integer (4 digits)",
   '-8i' => "Signed decimal integer (8 digits, left-align)",
   '+8i' => "Signed decimal integer (8 digits, right-align, with leading +/-)",
   'hhi' => "Signed decimal integer (char)",
   'hi'  => "Signed decimal integer (short)",
   'li'  => "Signed decimal integer (long)",
   'lli' => "Signed decimal integer (long long)",
   'ji'  => "Signed decimal integer (intmax_t)",
   'zi'  => "Signed decimal integer (ssize_t)",
   'ti'  => "Signed decimal integer (ptrdiff_t)",
   'u'   => "Unsigned decimal integer (unsigned int)",
   '2u'  => "Unsigned decimal integer (2 digits)",
   '4u'  => "Unsigned decimal integer (4 digits)",
   'hhu' => "Unsigned decimal integer (char)",
   'hu'  => "Unsigned decimal integer (short)",
   'lu'  => "Unsigned decimal integer (long)",
   'llu' => "Unsigned decimal integer (long long)",
   'ju'  => "Unsigned decimal integer (intmax_t)",
   'zu'  => "Unsigned decimal integer (size_t)",
   'tu'  => "Unsigned decimal integer (ptrdiff_t)",
   'o'   => "Unsigned octal (int)",
   '3o' => "Unsigned octal (3 digits)",
   '#3o' => "Unsigned octal (3 digits, leading zeroes)",
   'hho' => "Unsigned octal integer (char)",
   'ho'  => "Unsigned octal integer (short)",
   'lo'  => "Unsigned octal integer (long)",
   'llo' => "Unsigned octal integer (long long)",
   'jo'  => "Unsigned octal integer (intmax_t)",
   'zo'  => "Unsigned octal integer (size_t)",
   'to'  => "Unsigned octal integer (ptrdiff_t)",
   'x'   => "Unsigned hexadecimal integer (unsigned int)",
   '#x'  => "Unsigned hexadecimal integer (with leading 0x)",
   '2x'  => "Unsigned hexadecimal integer (2 digits)",
   '4x'  => "Unsigned hexadecimal integer (4 digits)",
   '8x'  => "Unsigned hexadecimal integer (8 digits)",
   '02x' => "Unsigned hexadecimal integer (2 digits, leading zeroes)",
   '04x' => "Unsigned hexadecimal integer (4 digits, leading zeroes)",
   '08x' => "Unsigned hexadecimal integer (8 digits, leading zeroes)",
   'hhx' => "Unsigned hexadecimal integer (char)",
   'hx'  => "Unsigned hexadecimal integer (short)",
   'lx'  => "Unsigned hexadecimal integer (long)",
   'llx' => "Unsigned hexadecimal integer (long long)",
   'jx'  => "Unsigned hexadecimal integer (intmax_t)",
   'zx'  => "Unsigned hexadecimal integer (size_t)",
   'tx'  => "Unsigned hexadecimal integer (ptrdiff_t)",
   'X'   => "Unsigned hexadecimal integer, uppercase (unsigned int)",
   '#X'  => "Unsigned hexadecimal integer, uppercase (with leading 0X)",
   '2X'  => "Unsigned hexadecimal integer, uppercase (2 digits)",
   '4X'  => "Unsigned hexadecimal integer, uppercase (4 digits)",
   '8X'  => "Unsigned hexadecimal integer, uppercase (8 digits)",
   '02X' => "Unsigned hexadecimal integer, uppercase (2 digits, leading zeroes)",
   '04X' => "Unsigned hexadecimal integer, uppercase (4 digits, leading zeroes)",
   '08X' => "Unsigned hexadecimal integer, uppercase (8 digits, leading zeroes)",
   'hhX' => "Unsigned hexadecimal integer, uppercase (char)",
   'hX'  => "Unsigned hexadecimal integer, uppercase (short)",
   'lX'  => "Unsigned hexadecimal integer, uppercase (long)",
   'llX' => "Unsigned hexadecimal integer, uppercase (long long)",
   'jX'  => "Unsigned hexadecimal integer, uppercase (intmax_t)",
   'zX'  => "Unsigned hexadecimal integer, uppercase (size_t)",
   'tX'  => "Unsigned hexadecimal integer, uppercase (ptrdiff_t)",
   'f'   => "Decimal floating point, lowercase (double)",
   'lf'  => "Decimal floating point, lowercase (double)",
   'Lf'  => "Decimal floating point, lowercase (long double)",
   'F'   => "Decimal floating point, uppercase (double)",
   'lF'  => "Decimal floating point, uppercase (double)",
   'LF'  => "Decimal floating point, uppercase (long double)",
   'e'   => "Scientific notation (mantissa/exponent), lowercase (double)",
   'le'  => "Scientific notation (mantissa/exponent), lowercase (double)",
   'Le'  => "Scientific notation (mantissa/exponent), lowercase (long double)",
   'E'   => "Scientific notation (mantissa/exponent), uppercase (double)",
   'lE'  => "Scientific notation (mantissa/exponent), uppercase (double)",
   'LE'  => "Scientific notation (mantissa/exponent), uppercase (long double)",
   'g'   => "Use the shortest representation: %e or %f (double)",
   'lg'  => "Use the shortest representation: %e or %f (double)",
   'Lg'  => "Use the shortest representation: %e or %f (long double)",
   'G'   => "Use the shortest representation: %E or %F (double)",
   'lG'  => "Use the shortest representation: %E or %F (double)",
   'LG'  => "Use the shortest representation: %E or %F (long double)",
   'a'   => "Hexadecimal floating point, lowercase (double)",
   'la'  => "Hexadecimal floating point, lowercase (double)",
   'La'  => "Hexadecimal floating point, lowercase (long double)",
   'A'   => "Hexadecimal floating point, uppercase (double)",
   'lA'  => "Hexadecimal floating point, uppercase (double)",
   'LA'  => "Hexadecimal floating point, uppercase (long double)",
   'c'   => "Character (char)",
   'lc'  => "Wide character (wchar_t)",
   's'   => "String of characters (char*)",
   '-8s' => "String of characters (8 chars, left-align)",
   'ls'  => "String of wide characters (wchar_t*)",
   'p'   => "Pointer address (void*)",
   'n'   => "Nothing printed. The corresponding argument must be a pointer to a signed int. The number of characters written so far is stored in the pointed location.",
   'hhn' => "Nothing printed. The corresponding argument must be a pointer to a char. The number of characters written so far is stored in the pointed location.",
   'hn'  => "Nothing printed. The corresponding argument must be a pointer to a short. The number of characters written so far is stored in the pointed location.",
   'ln'  => "Nothing printed. The corresponding argument must be a pointer to a long. The number of characters written so far is stored in the pointed location.",
   'lln' => "Nothing printed. The corresponding argument must be a pointer to a long long. The number of characters written so far is stored in the pointed location.",
   'jn'  => "Nothing printed. The corresponding argument must be a pointer to a intmax_t. The number of characters written so far is stored in the pointed location.",
   'zn'  => "Nothing printed. The corresponding argument must be a pointer to a size_t. The number of characters written so far is stored in the pointed location.",
   'tn'  => "Nothing printed. The corresponding argument must be a pointer to a ptrdiff_t. The number of characters written so far is stored in the pointed location.",
   '%'   => "A % followed by another % character will write a single % to the stream.",
};

/**
 * Look up symbols to match against a canned list of escape sequences 
 * for printf or C-style string escape sequences. 
 * 
 * @param lastid                Could be the first character of the escape sequence
 * @param escapeSequenceTable   Table of escape sequences for the given prefix.
 * 
 * @return Returns the number of matches found.
 */
static int _c_find_escape_sequences(_str lastid, _str (&escapeSequenceTable):[])
{
   num_matches := 0;
   foreach (auto sequenceName => auto description in escapeSequenceTable) {
      if (lastid == "" || pos(lastid, sequenceName) == 1) {
         tag_browse_info_init(auto cm, sequenceName, "", SE_TAG_TYPE_CLAUSE, SE_TAG_FLAG_NULL, "", p_line, _QROffset());
         cm.doc_type = SE_TAG_DOCUMENTATION_HTML;
         cm.doc_comments = description;
         num_matches++;
         tag_insert_match_browse_info(cm);
      }
   }
   return num_matches;
}


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
 * @param prefix_rt          (output) set to return type of prefix expression
 *
 * @return 0 on sucess, nonzero on error
 */
int _c_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         bool find_parents,int max_matches,
                         bool exact_match,bool case_sensitive,
                         SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                         SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                         VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_c_find_context_tags: ------------------------------------------------------");
      isay(depth,"_c_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case="case_sensitive);
      tag_dump_filter_flags(filter_flags, "_c_find_context_tags: FILTER FLAGS", depth);
      tag_dump_context_flags(context_flags, "_c_find_context_tags: CONTEXT FLAGS", depth);
   }

   // hook for javadoc tags, adapted to find-context tags.
   tag_return_type_init(prefix_rt);
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth+1);
   }

   // if we are in a string, maybe we can help them with escape sequences
   if ((info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER) && (_clex_find(0,'g') == CFG_STRING)) {
      string_escape_count := 0;
      if (prefixexp == '\') {
         string_escape_count = _c_find_escape_sequences(lastid, c_string_escape_sequences);
      } else if (prefixexp == '%') {
         string_escape_count = _c_find_escape_sequences(lastid, c_printf_escape_sequences);
      }
      return (string_escape_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         _CodeHelpListLabels(0, 0, lastid, "",
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth+1);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // special case for #import or #require "string.e"
   if ((prefixexp == "#import" || prefixexp=="#require" || prefixexp=="#include") &&
       (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {

      bool been_there_done_that:[];
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

      if (prefixChar != "<") {
         num_headers += insert_files_of_extension(0, 0,
                                                  p_buf_name,
                                                  ";h;hpp;hxx;h++;inl;hxx;hh;qth;;",
                                                  false, extraDir, true,
                                                  lastid, exact_match);
         been_there_done_that:[_file_case(_strip_filename(p_buf_name, 'N'))] = true;
      }

      origProjectFileName := _project_get_filename();
      info := _ProjectGet_IncludesList(_ProjectHandle(), _project_get_section(gActiveConfigName));
      info = _absolute_includedirs(info, origProjectFileName);
      while (info != "") {
         if (_CheckTimeout()) break;
         includePath := "";
         parse info with includePath (PARSE_PATHSEP_RE),'r' info;
         _maybe_append_filesep(includePath);
         if (been_there_done_that._indexin(_file_case(includePath))) continue;
         been_there_done_that:[_file_case(includePath)] = true;
         includePath :+= "junk.h";
         num_headers += insert_files_of_extension(0, 0,
                                                  includePath,
                                                  ";h;hpp;hxx;h++;inl;hxx;hh;qth;;",
                                                  false, extraDir, true,
                                                  lastid, exact_match);
      }

      _str allProjectFiles[];
      allProjectFiles = _WorkspaceFindAllProjectsWithFile(p_buf_name, _workspace_filename, true);
      foreach (auto projectFileName in allProjectFiles) {
         if (_CheckTimeout()) break;
         if (_file_eq(projectFileName, origProjectFileName )) {
            continue;
         }
         info = _ProjectGet_IncludesList(_ProjectHandle(projectFileName), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, projectFileName);
         while (info != "") {
            if (_CheckTimeout()) break;
            includePath := "";
            parse info with includePath (PARSE_PATHSEP_RE),'r' info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath :+= "junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;h++;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }

      }

      if (prefixChar == "<") {
         info = _ProjectGet_SysIncludesList(_ProjectHandle(), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, origProjectFileName);
         while (info!="") {
            if (_CheckTimeout()) break;
            includePath := "";
            parse info with includePath (PARSE_PATHSEP_RE),'r' info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath :+= "junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;h++;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }

         info = _ProjectGet_SystemIncludes(_ProjectHandle(), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, origProjectFileName);
         while (info!="") {
            if (_CheckTimeout()) break;
            includePath := "";
            parse info with includePath (PARSE_PATHSEP_RE),'r' info;
            _maybe_append_filesep(includePath);
            if (been_there_done_that._indexin(_file_case(includePath))) continue;
            been_there_done_that:[_file_case(includePath)] = true;
            includePath :+= "junk.h";
            num_headers += insert_files_of_extension(0, 0,
                                                     includePath,
                                                     ";h;hpp;hxx;h++;inl;hxx;hh;qth;;",
                                                     false, extraDir, true,
                                                     lastid, exact_match);
         }
      }

      errorArgs[1] = lastid;
      return (num_headers==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   // watch out for unwelcome 'new' as part of prefix expression
   is_new_expr := false;
   if (pos("new ", prefixexp) == 1) {
      prefixexp = substr(prefixexp, 5);
      is_new_expr = true;
   } else if (pos("gcnew ", prefixexp) == 1) {
      prefixexp = substr(prefixexp, 7);
      is_new_expr = true;
   }
   if (_chdebug > 0) {
      isay(depth,"_c_find_context_tags: prefixexp is_new_expr="is_new_expr);
   }
   
   // get the tag file list
   errorArgs._makeempty();
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
   if (_chdebug) {
      foreach (auto i => auto tf in tag_files) {
         isay(depth,"_c_find_context_tags: tag_files["i"]="tf);
      }
   }

   // is the cursor on #import or #include?
   if (prefixexp == "#" && (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // context is in using or import statement?
   if (prefixexp == "" && (info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT)) {
      num_imports := 0;
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: IN IMPORT STATEMENT, list context globals");
      }
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_imports, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      if (num_imports > 0) {
         return 0;
      }
   }

   // clear match set
   num_matches := 0;
   constructor_class := "";
   tag_clear_matches();

   // maybe prefix expression is a package name or prefix of package name
   package_prefix := prefixexp:+lastid;
   if (pos("::",prefixexp) > 0 &&
       tag_check_for_package(package_prefix,tag_files,false,true, null, visited, depth+1)) {
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: PREFIXEXP starts with ::, list packages");
      }
      tag_push_matches();
      tag_list_context_packages(0,0,package_prefix,tag_files,num_matches,max_matches,false,true,visited,depth+1);
      start := length(package_prefix);
      VS_TAG_BROWSE_INFO package_names[];
      for (i:=1; i<=tag_get_num_of_matches(); ++i) {
         _str pkg_name;
         tag_get_detail2(VS_TAGDETAIL_match_name,i,pkg_name);
         if (pos(package_prefix, pkg_name)!=1 ||
             length(pkg_name)<start || (exact_match && length(pkg_name)>start)) {
            continue;
         }
         tag_get_match_info(i, auto cm);
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
   status := 0;

   // handle 'new' expressions as a special case
   if (is_new_expr) {
      outer_class := prefixexp;
      _maybe_strip(outer_class, '::');
      _maybe_strip(outer_class, '.');
      outer_class = stranslate(outer_class, ":", "::");


      if ((info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) ||
          (prefixexp == "new" && !(info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL)) ) {
         // In this case, we're (probably) moving through a complete constructor
         if (outer_class=="") {
            tag_qualify_symbol_name(constructor_class, lastid, 
                                    "", p_buf_name, tag_files, 
                                    true, visited, depth+1);
         } else {
            constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true, false, false, visited, depth+1);
         }
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: outer_class="outer_class" constructor_class="constructor_class);
         }
      } else {
         // In this case, they're probably still typing the constructor name, so
         // don't count on outer_class actually being a class name, do a more lenient
         // match.
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: NEW exprssion followed by paren, outer_class="outer_class);
         }
         status = tag_list_symbols_in_context(outer_class, null, 0, 0, tag_files, "", num_matches, max_matches,
                                              SE_TAG_FILTER_ANYTHING|SE_TAG_FILTER_CASE_SENSITIVE,
                                              SE_TAG_CONTEXT_ONLY_CLASSES, 
                                              exact_match, case_sensitive, 
                                              visited, depth+1);
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: loose match "status", nm="num_matches);
            if (_chdebug) {
               tag_dump_matches("_c_find_context_tags:", depth+1);
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

   // special handling for C++11 user defined string literal operators
   if (substr(prefixexp,1,2) == "\"\"" && (info_flags & VSAUTOCODEINFO_CPP_OPERATOR)) {
      num_operators := 0;
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: LOOK FOR C++11 USER DEFINED STRING LITERAL OPERATORS");
      }
      tag_list_context_globals(0, 0, "\"\"":+lastid,
                               true, tag_files,
                               SE_TAG_FILTER_ANY_PROCEDURE, context_flags,
                               num_operators, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      if (num_operators > 0) {
         return 0;
      }
      // this could just be old code doing string concatenation.
      // C++11 user defined string operators should start with "_" anyway.
      if (_LanguageInheritsFrom('ansic') || 
          _first_char(lastid) != '_' ||
          tag_check_for_define(lastid, MAXINT, tag_files, auto id_defined_to, auto arg_list="") > 0) {
         prefixexp = "";
         info_flags &= ~VSAUTOCODEINFO_CPP_OPERATOR;
      }
   }

   if (prefixexp!="") {

      // evaluate the prefix expression to set up the return type 'rt'
      save_pos(auto orig_seekpos);
      symbol := (lastid != "" && exact_match)? lastid:"";
      status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, 0, symbol);
      if (status) {
         tag_pop_matches();
         return status;
      }

      prefix_rt = rt;
      if (_chdebug) {
         tag_return_type_dump(rt, "_c_find_context_tags: rt", depth);
      }

      if (!rt.istemplate) {
         rt.template_args._makeempty();
         rt.template_names._makeempty();
         rt.template_types._makeempty();
      }

      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
      restore_pos(orig_seekpos);
   }
   tag_pop_matches();

   // this instance is not a function, so mask it out of filter flags
   //SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING;
   //if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
   //   filter_flags &= ~(SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE);
   //}

   // get the current class and current package from the context
   cur_scope_seekpos := 0;
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class,
                                         auto cur_package,
                                         visited, depth+1);
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, cur_scope_seekpos);
   }

   // properly qualify the current scope
   orig_cur_context := cur_context;
   if (cur_context != "") {
      VS_TAG_RETURN_TYPE scope_rt;
      tag_return_type_init(scope_rt);
      tag_push_matches();
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: EVALUATING CURRENT CLASS SCOPE, cur_class_name="cur_context);
      }
      save_pos(auto orig_seekpos);
      if (cur_scope_seekpos > 0 && cur_scope_seekpos < _QROffset()) {
         _GoToROffset(cur_scope_seekpos);
      }
      if (!_c_parse_return_type(errorArgs, tag_files,
                                cur_tag_name, cur_package,
                                p_buf_name, cur_context,
                                false, scope_rt, 
                                visited, depth+1)) {
         cur_context = tag_return_type_string(scope_rt);
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: EVALUATED CURRENT CLASS SCOPE, cur_context="cur_context);
         }
         if (prefixexp == "") {
            prefix_rt = scope_rt;
         }
      }
      restore_pos(orig_seekpos);
      tag_pop_matches();
   }

   // attempt to properly qualify the current scope
   inner_name := outer_name := qualified_name := "";
   tag_split_class_name(cur_context,inner_name,outer_name);
   tag_qualify_symbol_name(qualified_name, 
                           inner_name, outer_name,
                           p_buf_name, tag_files,
                           true, visited, depth+1);
   if (qualified_name!="" && qualified_name!=inner_name) {
      cur_context=qualified_name;
   }

   // report information about current scope
   if (_chdebug) {
      isay(depth, "_c_find_context_tags: context_id="context_id" tag="cur_tag_name" scope="cur_context);
   }
   
   // if the current tag is a function, but not necessarily static or inline
   // try to find its matching prototype.
   if (context_id>0 && cur_type_id==SE_TAG_TYPE_FUNCTION &&
       cur_context!="" && !(cur_flags & SE_TAG_FLAG_STATIC)) {
      cur_arguments := "";
      tag_get_detail2(VS_TAGDETAIL_context_args,context_id,cur_arguments);

      // first try to find the tag within the current context
      found_flags := SE_TAG_FLAG_NULL;
      found_type_name := "";
      found_args := "";

      status = 0;
      i := tag_find_context_iterator(cur_tag_name,true,true,false,cur_context);
      while (i>0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,i,found_type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags,i,found_flags);
         tag_get_detail2(VS_TAGDETAIL_context_args,i,found_args);
         if (found_type_name=="proto" &&
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
            if (tf=="") {
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
         cur_flags |= (found_flags & (SE_TAG_FLAG_STATIC|SE_TAG_FLAG_INLINE|SE_TAG_FLAG_VIRTUAL));
      }
   }

   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==SE_TAG_TYPE_FUNCTION && cur_context!="" && prefixexp=="") {
      if (!(context_flags & SE_TAG_CONTEXT_FIND_LENIENT) && (cur_flags & SE_TAG_FLAG_STATIC)) {
         outer_id := 0;
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, outer_id);
         if (outer_id > 0) {
            outer_type := 0;
            tag_get_detail2(VS_TAGDETAIL_context_type, outer_id, outer_type);
            if (!tag_tree_type_is_package(outer_type)) {
               context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
            }
         }
      }
   }

   // are we in a class scope?
   orig_return_type := rt.return_type;
   if (prefixexp=="" && cur_context!="") {
      if ( _chdebug ) {
         isay(depth, "_c_find_context_tags:  reverting rt.return_type to current context: "cur_context);
      }
      rt.return_type = cur_context;
      if (_QROffset() >= cur_scope_seekpos) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PRIVATE;
      }
      if (info_flags & (VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) {
         context_flags |= SE_TAG_CONTEXT_ONLY_INCLASS|SE_TAG_CONTEXT_ONLY_THIS_CLASS|SE_TAG_CONTEXT_ONLY_DATA;
      }
   }

   // propagate private, protected, package flags
   if (rt.return_type != "") {
      _c_check_context_for_private_scope(rt, cur_context, depth);
   }
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
      context_flags |= SE_TAG_CONTEXT_ALLOW_PRIVATE;
      context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
      context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
   } 

   // compute current context, package name, and class name to
   // determine unusual access restrictions for java
   if ((pos(cur_package"/",rt.return_type)==1) ||
       (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
        !pos(VS_TAGSEPARATOR_package,cur_class))) {
      context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
      context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
   }

   // construct context flags for the first, very targetted search
   first_context_flags := context_flags;
   first_context_flags |= SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE;
   if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      first_context_flags |= SE_TAG_CONTEXT_ALLOW_LOCALS;
   }

   // not a function call?
   orig_filter_flags := filter_flags;
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE);
   }
   if (info_flags & VSAUTOCODEINFO_HAS_CLASS_SPECIFIER) {
      filter_flags &= ~(SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_CONSTANT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_TYPEDEF);
      filter_flags |= SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_ENUM;
      filter_flags |= SE_TAG_FILTER_DEFINE;
   }
   if ((info_flags & VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER) || (info_flags & VSAUTOCODEINFO_CPP_OPERATOR)) {
      filter_flags &= ~(SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_CONSTANT|SE_TAG_FILTER_ANY_DATA);
      filter_flags |= SE_TAG_FILTER_ANY_PROCEDURE;
   }
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      filter_flags = SE_TAG_FILTER_LABEL;
      filter_flags |= SE_TAG_FILTER_DEFINE;
   }

   // if the current symbol under the cursor is a variable with the same
   // stupid name as the type the variable is declared as, then don't look 
   // for variables.  This could be general purpose, but in order not
   // to break things, I'm making this specific to Verilog.
   if (_LanguageInheritsFrom("systemverilog") || _LanguageInheritsFrom("verilog")) {
      if (prefixexp == "") {
         if (!(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) && 
             !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_ASSIGNMENT) && 
             !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) {
            var_id := tag_current_context();
            if (var_id != 0) {
               tag_get_context_browse_info(var_id, auto var_cm);
               if (var_cm.member_name == lastid && 
                   var_cm.class_name  == cur_context &&
                   var_cm.name_seekpos != lastidstart_offset &&
                   var_cm.seekpos <= lastidstart_offset &&
                   lastidstart_offset <= var_cm.end_seekpos && 
                   tag_tree_type_is_data(var_cm.type_name)) {
                  filter_flags &= ~SE_TAG_FILTER_MEMBER_VARIABLE;
               }
            }
         }
      }
   }

   // Allow non-static functions to be listed if they are typing
   // a member function definition
   if ((context_flags & SE_TAG_CONTEXT_ONLY_STATIC) && 
       rt.return_type!="" && cur_type_name=="" &&
       length(prefixexp) > 2 && substr(prefixexp, length(prefixexp)-1, 2) :== "::") {
      context_flags &= ~SE_TAG_CONTEXT_ONLY_STATIC;
   }
   if (_chdebug) {
      tag_dump_filter_flags(filter_flags, "_c_find_context_tags: FILTER FLAGS", depth);
      tag_dump_context_flags(context_flags, "_c_find_context_tags: CONTEXT FLAGS", depth);
   }

   // now update the #define parameters
   if ( cur_type_name=="define" && exact_match && prefixexp=="" ) {
      // insert parameters of #define statement or template class
      int orig_num_matches=num_matches;
      _ListParametersOfDefine(0, 0, num_matches, max_matches, lastid);
      if (num_matches > orig_num_matches) return 0;
   }

   // insert 'this' keyword
   if ( prefixexp == "" ) {
      thisVar := (_LanguageInheritsFrom("m") || _LanguageInheritsFrom("swift"))? "self" : "this";
      _CodeHelpMaybeInsertThis(lastid, thisVar, tag_files, 
                               filter_flags, context_flags, 
                               exact_match, case_sensitive,
                               false, "", visited, depth+1);
   }

   // check for C++ overloaded operators
   if (pos("operator ", lastid, 1)) {
      parse lastid with . lastid;
   }

   // get the list of friend relationships for the current context
   friend_list := "";
   if (  _LanguageInheritsFrom("c") && 
         !_LanguageInheritsFrom("d") && 
         !_LanguageInheritsFrom("cs") && 
         !_LanguageInheritsFrom("java") && 
         !_LanguageInheritsFrom("m")) {
      if (rt.return_type == "" || rt.return_type == cur_context) {
         tag_find_friends_to_tag(cur_tag_name, cur_context, tag_files, friend_list);
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: cur_tag_name="cur_tag_name" cur_context="cur_context" friend_list="friend_list);
         }
      } else {
         tag_find_friends_of_class(rt.return_type, tag_files, friend_list);
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: rt.return_type="rt.return_type" friend_list="friend_list);
         }
      }
   }
   // report debug information about the current class
   if (_chdebug) {
      isay(depth, "_c_find_context_tags: tag="cur_tag_name" type="cur_type_name" flags="tag_dump_tag_flags(cur_flags)" class="cur_context" only="cur_class" package="cur_package);
   }

   if ( _LanguageInheritsFrom("c") || _LanguageInheritsFrom("m")) {
      context_flags |= SE_TAG_CONTEXT_NO_SELECTORS | SE_TAG_CONTEXT_NO_GROUPS;
   }

   orig_num_matches := num_matches;
   if ((context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) && prefixexp == "") {
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: LOCALS: lastid="lastid);
         tag_dump_context_flags(context_flags, "_c_find_context_tags: context_flags=", depth);
      }
      status = tag_list_class_locals(0, 0, null, lastid, "",
                                     filter_flags, context_flags,
                                     num_matches, max_matches,
                                     exact_match, case_sensitive,
                                     friend_list, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: LOCALS lastid="lastid" status="status" num_matches="num_matches);
      }
   } else if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
              (rt.return_type=="::" || rt.return_type=="" || orig_return_type=="")) {
      // :: operator
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: GLOBALS: lastid="lastid);
      }
      status = tag_list_context_globals(0,0,lastid,
                                        true, tag_files,
                                        filter_flags, context_flags,
                                        num_matches, max_matches,
                                        exact_match, case_sensitive,
                                        visited, depth+1);
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: GLOBALS lastid="lastid" status="status" num_matches="num_matches);
      }
   } else if (rt.return_type != "") {
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: IN CLASS lastid="lastid" return_type="rt.return_type);
         }
         status = tag_list_in_class(lastid, rt.return_type,
                                    0, 0, tag_files,
                                    num_matches, max_matches,
                                    filter_flags, context_flags,
                                    exact_match, case_sensitive,
                                    rt.template_args, friend_list, 
                                    visited, depth+1);
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: IN CLASS status="status" num_matches="num_matches);
         }
         if (prefixexp != "") {
            context_flags |= SE_TAG_CONTEXT_ONLY_THIS_CLASS;
         }
      }
   }

   // if we are in a function definition that was not explicitely 
   // namespace qualified, try to search within the unqualified class space
   // also.  This helps us locate items that we might not otherwise find.
   if (rt.return_type == cur_context && 
       rt.return_type != orig_cur_context && 
       prefixexp=="" && rt.alt_return_types._length() == 0) {
      temp_rt := rt;
      temp_rt.return_type = orig_cur_context;
      rt.alt_return_types[0] = temp_rt;
   }

   // try finding tags in alternate return type scopes
   if (rt.alt_return_types._length() > 0) {
      for (i:=0; i<rt.alt_return_types._length(); i++) {
         if (num_matches > max_matches) break;
         if (_CheckTimeout()) break;

         VS_TAG_RETURN_TYPE alt = rt.alt_return_types[i];
         if ((context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) && prefixexp == "") {
            if (_chdebug) {
               isay(depth, "_c_find_context_tags: ALT LOCALS: lastid="lastid);
            }
            status = tag_list_class_locals(0, 0, null, lastid, "",
                                           filter_flags, context_flags,
                                           num_matches, max_matches,
                                           exact_match, case_sensitive,
                                           friend_list, visited, depth+1);
            if (_chdebug) {
               isay(depth, "_c_find_context_tags: ALT LOCALS lastid="lastid" status="status" num_matches="num_matches);
            }
         } else if ((alt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
             (alt.return_type=="::" || alt.return_type=="")) {
            // :: operator
            if (_chdebug) {
               isay(depth, "_c_find_context_tags: ALT GLOBALS: lastid="lastid);
            }
            status = tag_list_context_globals(0,0,lastid,
                                              true, tag_files,
                                              filter_flags, context_flags,
                                              num_matches, max_matches,
                                              exact_match, case_sensitive,
                                              visited, depth+1);
            if (_chdebug) {
               isay(depth, "_c_find_context_tags: ALT GLOBALS lastid="lastid" status="status" num_matches="num_matches);
            }
         } else if (alt.return_type != "") {
            if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
               if (_chdebug) {
                  isay(depth, "_c_find_context_tags: ALT IN CLASS: "alt.return_type);
               }
               status = tag_list_in_class(lastid, alt.return_type,
                                          0, 0, tag_files,
                                          num_matches, max_matches,
                                          filter_flags, context_flags,
                                          exact_match, case_sensitive,
                                          alt.template_args, friend_list, 
                                          visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_c_find_context_tags: ALT IN CLASS lastid="lastid" status="status" num_matches="num_matches);
               }
            }
         }
      }
   }

   // try to match local variables first
   // do not do this if we are looking for prefix matches.
   // use language-specific case sensitivity rules here
   // because if we find something we might shortcut the search,
   // so we need to know we found a real match.
   filter_flags_no_imports := filter_flags;
   filter_flags_no_imports &= ~SE_TAG_FILTER_INCLUDE;
   have_extern_local := false;
   if ((exact_match || lastid=="") && prefixexp=="" && (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS)) {
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: IN CONTEXT LOCALS ONLY");
      }
      status = tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "", 
                                           num_matches, max_matches, 
                                           filter_flags_no_imports, 
                                           first_context_flags|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_LOCALS,
                                           exact_match, case_sensitive, 
                                           visited, depth+1, 
                                           rt.template_args);
      // check if we caught an extern local
      for (j:=1; j<=tag_get_num_of_matches(); j++) {
         tag_get_detail2(VS_TAGDETAIL_match_flags, j, auto j_flags);
         if (j_flags & SE_TAG_FLAG_EXTERN) {
            have_extern_local = true;
            break;
         }
      }
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: IN CONTEXT LOCALS lastid="lastid" status="status" num_matches="num_matches);
      }
   }

   // try to match the symbol in the current context
   if (_chdebug) {
      tag_return_type_dump(rt, "_c_find_context_tags AFTER",depth);
   }
   context_list_flags := SE_TAG_CONTEXT_ANYTHING;
   if (prefixexp == "") context_list_flags |= SE_TAG_CONTEXT_ALLOW_LOCALS;
   if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
      context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
   }
   if (rt.return_type != "" && prefixexp != "") {
      context_list_flags |= SE_TAG_CONTEXT_NO_GLOBALS;
   }

   if (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("m")) {
      context_list_flags |= SE_TAG_CONTEXT_NO_SELECTORS | SE_TAG_CONTEXT_NO_GROUPS;
   }

   // check if we caught a declaration or definition
   have_definition_or_declaration := false;
   if ( num_matches > orig_num_matches ) {
      for (j:=1; j<=tag_get_num_of_matches(); j++) {
         tag_get_detail2(VS_TAGDETAIL_match_flags, j, auto j_flags);
         tag_get_detail2(VS_TAGDETAIL_match_type,  j, auto j_type);
         if (tag_can_be_definition_or_declaration(j_type, j_flags)) {
            have_definition_or_declaration = true;
            if (_chdebug) {
               isay(depth,"_c_find_context_tags: H"__LINE__" HAVE DEFINITION OR DECLARATION");
            }
            break;
         }
      }
   }

   // try a more detailed search, unless we already searched classes
   if (prefixexp=="" || num_matches == orig_num_matches) {
      if (num_matches == orig_num_matches || 
          have_extern_local || !have_definition_or_declaration ||
          (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) || 
          (context_flags & SE_TAG_CONTEXT_FIND_ALL)) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: IN CONTEXT FIND ALL");
            tag_dump_context_flags(first_context_flags, "_c_find_context_tags: first_context_flags=", depth);
            tag_dump_context_flags(context_list_flags,  "_c_find_context_tags: context_list_flags=", depth);
            tag_dump_filter_flags(filter_flags_no_imports, "_c_find_context_tags: FILTER FLAGS NO IMPORTS=", depth);
         }
         status = tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                              tag_files, "",
                                              num_matches, max_matches,
                                              filter_flags_no_imports, 
                                              first_context_flags|context_list_flags,
                                              exact_match, case_sensitive, 
                                              visited, depth+1, rt.template_args);
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: IN CONTEXT FIND ALL lastid="lastid" return_type="rt.return_type" status="status" num_matches="num_matches);
         }
         // maybe we caught the declaration this time
         if ( num_matches > orig_num_matches ) {
            for (j:=1; j<=tag_get_num_of_matches(); j++) {
               tag_get_detail2(VS_TAGDETAIL_match_flags, j, auto j_flags);
               tag_get_detail2(VS_TAGDETAIL_match_type,  j, auto j_type);
               if (tag_can_be_definition_or_declaration(j_type, j_flags)) {
                  have_definition_or_declaration = true;
                  if (_chdebug) {
                     isay(depth,"_c_find_context_tags: H"__LINE__" HAVE DEFINITION OR DECLARATION");
                  }
                  break;
               }
            }
         }
      }
   }

   // remove ONLY static flag if search yielded no results
   if (prefixexp=="" || num_matches == orig_num_matches) {
      if ((num_matches == orig_num_matches || !have_definition_or_declaration) && 
          rt.return_type != "" &&
          (context_flags & (SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC))) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: RETRY IGNORING STATIC");
            tag_dump_context_flags(first_context_flags, "_c_find_context_tags: first_context_flags=", depth);
            tag_dump_context_flags(context_list_flags,  "_c_find_context_tags: context_list_flags=", depth);
         }
         context_flags &= ~SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC;
         status = tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                              tag_files, "",
                                              num_matches, max_matches,
                                              filter_flags, 
                                              first_context_flags|context_list_flags,
                                              exact_match, case_sensitive, 
                                              visited, depth+1, rt.template_args);
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: IN CONTEXT FIND IGNORE STATIC lastid="lastid" return_type="rt.return_type" status="status" num_matches="num_matches);
         }
      }
   }

   // re-instate previous function filter flags if search yielded no results
   if (prefixexp=="" || num_matches == orig_num_matches) {
      if ((num_matches == orig_num_matches || !have_definition_or_declaration) && 
          filter_flags != orig_filter_flags && (info_flags & (VSAUTOCODEINFO_NOT_A_FUNCTION_CALL|VSAUTOCODEINFO_HAS_CLASS_SPECIFIER))) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: RETRY IGNORING NOT A FUNCTION CALL");
            tag_dump_context_flags(first_context_flags, "_c_find_context_tags: first_context_flags=", depth);
            tag_dump_context_flags(context_list_flags,  "_c_find_context_tags: context_list_flags=", depth);
         }
         status = tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                              tag_files, "",
                                              num_matches, max_matches,
                                              filter_flags | (orig_filter_flags & SE_TAG_FILTER_ANY_PROCEDURE) | (orig_filter_flags & SE_TAG_FILTER_TYPEDEF), 
                                              first_context_flags|context_list_flags,
                                              exact_match, case_sensitive, 
                                              visited, depth+1, rt.template_args);
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: IN CONTEXT FIND IGNORE NOT A FUNCTION CALL lastid="lastid" return_type="rt.return_type" status="status" num_matches="num_matches);
         }
      }
   }

   // check for prefix match with overloaded operators
   if (!exact_match && rt.return_type != "" && lastid != "" &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) && 
       !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) && 
       _CodeHelpDoesIdMatch(lastid, "operator ", false, true)) {
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: OPERATORS");
      }
      foreach (auto op in "~ ! ^ & | ( [ - + * / % = < > ? new delete") {
         tag_list_in_class(op, rt.return_type, 0, 0, tag_files, 
                           num_matches, max_matches, 
                           filter_flags, context_flags, 
                           exact_match, case_sensitive, 
                           rt.template_args, friend_list, visited, depth+1);
      }
      if (_chdebug) {
         isay(depth,"_c_find_context_tags: OPERATORS lastid="lastid" num_matches="num_matches);
      }
   }

   // try listing symbols in context, looking for globals this time instead
   // of symbols from the current scope, unless we are already in global scope
   if (prefixexp=="" && (!exact_match || num_matches == orig_num_matches)) {
      if (num_matches == orig_num_matches || !exact_match ||
          have_extern_local || !have_definition_or_declaration ||
          (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) || 
          (context_flags & SE_TAG_CONTEXT_FIND_ALL)) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: IN CONTEXT FIND ALL GLOBAL SCOPE");
            tag_dump_context_flags(first_context_flags, "_c_find_context_tags: first_context_flags=", depth);
            tag_dump_context_flags(context_list_flags,  "_c_find_context_tags: context_list_flags=", depth);
         }
         context_list_flags &= ~SE_TAG_CONTEXT_NO_GLOBALS;
         status = tag_list_symbols_in_context(lastid, "", 0, 0, 
                                              tag_files, "",
                                              num_matches, max_matches,
                                              filter_flags,
                                              first_context_flags|context_list_flags,
                                              exact_match, case_sensitive, 
                                              visited, depth+1, rt.template_args); 
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: IN CONTEXT FIND ALL GLOBAL SCOPE lastid="lastid" status="status" num_matches="num_matches);
         }
      }
   }

   // if the symbol matches a class template parameter, search locals
   if (num_matches==orig_num_matches && exact_match && rt.istemplate && rt.template_args._indexin(lastid)) {
      tag_init_tag_browse_info(auto cm, lastid, "", SE_TAG_TYPE_PARAMETER, SE_TAG_FLAG_NULL, rt.filename, rt.line_number, 0);
      cm.return_type = rt.template_args:[lastid];
      tag_insert_match_browse_info(cm,true);
      num_matches++;
      if (_chdebug) {
         isay(depth,"_c_find_context_tags: LOCAL TEMPLATE PARAMS status="status" num_matches="num_matches);
      }
   }

   // try searching for any tag type
   if (num_matches == orig_num_matches) {
      if (_chdebug) {
         isay(depth, "_c_find_context_tags: STILL NO MATCHES, TRY FOR ANY TAG TYPE");
         tag_dump_context_flags(context_flags,       "_c_find_context_tags: context_flags=", depth);
         tag_dump_context_flags(first_context_flags, "_c_find_context_tags: first_context_flags=", depth);
         tag_dump_context_flags(context_list_flags,  "_c_find_context_tags: context_list_flags=", depth);
      }
      status = tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, 
                                           tag_files, "",
                                           num_matches, max_matches,
                                           filter_flags, 
                                           context_flags | context_list_flags | SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE | SE_TAG_CONTEXT_ALLOW_FORWARD | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS),
                                           exact_match, case_sensitive, 
                                           visited, depth+1, rt.template_args); 
      if (_chdebug) {
         isay(depth,"_c_find_context_tags: ANY TAG TYPE lastid="lastid" return_type="rt.return_type" status="status" num_matches="num_matches);
      }
   }

   if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
      if (info_flags & (VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) {
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: LOOKING FOR PARENTS OF CLASS: "cur_context);
         }
         _c_find_class_parents(errorArgs, tag_files, p_buf_name, cur_context, lastid, exact_match, case_sensitive, num_matches, max_matches, visited, depth+1);
      }
   }

   // if the symbol was followed by a paren and all the matches were class names,
   // maybe we should also look for constructors
   if (exact_match && constructor_class=="" && (info_flags & (VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACES))) {
      found_class_name := "";
      for (i:=1; i<=tag_get_num_of_matches(); ++i) {
         tag_get_detail2(VS_TAGDETAIL_match_type,i,auto cls_type);
         if (tag_tree_type_is_class(cls_type)) {
            tag_get_match_browse_info(i, auto cls_cm);
            orig_class_name := found_class_name;
            found_class_name = tag_join_class_name(cls_cm.member_name, cls_cm.class_name, tag_files, case_sensitive, false, false, visited, depth+1);
            if (orig_class_name != "" && tag_compare_classes(orig_class_name, found_class_name, case_sensitive) != 0) {
               found_class_name = "";
               break;
            }
         } else {
            found_class_name = "";
            break;
         }
      }
      if (found_class_name != "") {
         constructor_class = found_class_name;
         filter_flags |= (orig_filter_flags & (SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE));
      }
   }

   // do we think we need to search for constructors here?
   if (constructor_class!="") {
      constructor_name := lastid;
      if (_LanguageInheritsFrom("phpscript")) {
         constructor_name = "__construct";
      }
      if (_LanguageInheritsFrom("d")) {
         constructor_name = "this";
      }
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
         if (_chdebug) {
            isay(depth, "_c_find_context_tags: LIST CONSTRUCTOR NAMES");
         }
         status = tag_list_in_class(constructor_name, constructor_class, 
                                    0, 0, tag_files, 
                                    num_matches, max_matches,
                                    filter_flags, 
                                    context_flags|SE_TAG_CONTEXT_ONLY_CONSTRUCTORS|SE_TAG_CONTEXT_ONLY_THIS_CLASS,
                                    exact_match, case_sensitive, 
                                    rt.template_args, friend_list,
                                    visited, depth+1);
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: CONSTRUCTORS lastid="lastid" constructor_class="constructor_class" status="status" num_matches="num_matches);
         }
      }
   }

   if (_chdebug) {
      n := tag_get_num_of_matches();
      isay(depth,"_c_find_context_tags: FINAL COUNT num_matches="n);
      for (i:=1; i<=n; ++i) {
         tag_get_match_info(i, auto cm);
         tag_browse_info_dump(cm, "_c_find_context_tags", depth+1);
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=="")? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

void _c_check_context_for_private_scope(VS_TAG_RETURN_TYPE &rt, _str cur_class_name, int depth=0)
{
   // check if we should list private class members
   if (_chdebug) {
      isay(depth, "_c_check_context_for_private_scope: match_type="rt.return_type" cur_class="cur_class_name" p_buf_name="p_buf_name);
   }
   int cur_context_id = tag_current_context();
   if (cur_context_id == 0) {
      // if the current context is global, then include private members
      // because they may be trying to put together a function definition
      // for a private method.
      if (!_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("cs")) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         if (_chdebug) {
            isay(depth, "_c_check_context_for_private_scope: NO CURRENT CONTEXT");
         }
      }
   } else {
      // current method is from same class, then we have private access
      class_pos := lastpos(cur_class_name,rt.return_type);
      if (class_pos>0 && class_pos+length(cur_class_name)==length(rt.return_type)+1) {
         if (class_pos==1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            if (_chdebug) {
               isay(depth, "_c_check_context_for_private_scope: CURRENT METHOD IS FROM SAME CLASS");
            }
         } else if (substr(rt.return_type,class_pos-1,1)==VS_TAGSEPARATOR_package) {
            // maybe class comes from imported namespace
            import_type := "";
            import_name := substr(rt.return_type,1,class_pos-2);
            int import_id = tag_find_local_iterator(import_name,true,true,false,"");
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_local_type,import_id,import_type);
               if (import_type == "import" || import_type == "package" ||
                   import_type == "library" || import_type == "program") {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  if (_chdebug) {
                     isay(depth, "_c_check_context_for_private_scope: LOCAL IMPORT SCOPE");
                  }
                  break;
               }
               import_id = tag_next_local_iterator(import_name,import_id,true,true,false,"");
            }
            import_id = tag_find_context_iterator(import_name,true,true,false,"");
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type,import_id,import_type);
               if (import_type == "import" || import_type == "package" ||
                   import_type == "library" || import_type == "program") {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  if (_chdebug) {
                     isay(depth, "_c_check_context_for_private_scope: CONTEXT IMPORT SCOPE");
                  }
                  break;
               }
               import_id = tag_next_context_iterator(import_name,import_id,true,true,false,"");
            }
         }
      } else if (cur_class_name != "") {
         // if the current context is a namespace, then include private members
         // because they may be trying to put together a function definition
         // for a private method.
         if (!_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("cs")) {
            cur_context_type := "";
            tag_get_detail2(VS_TAGDETAIL_context_type, cur_context_id, cur_context_type);
            if (tag_tree_type_is_package(cur_context_type)) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
               if (_chdebug) {
                  isay(depth, "_c_check_context_for_private_scope: PACKAGE SCOPE");
               }
            }
         }
         // if we are in an inner class, we have private access to the class
         // we are nested in.
         if (pos(rt.return_type:+VS_TAGSEPARATOR_class, cur_class_name) == 1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            if (_chdebug) {
               isay(depth, "_c_check_context_for_private_scope: INNER CLASS");
            }
         }
      }
   }
}

// Insert files with the given extension in the same directory as
// the current buffer into the tree
int insert_files_of_extension(int tree_wid, int tree_root,
                              _str buf_name,_str extension_list,
                              bool referExtension=false,
                              _str directoryPrefix="",
                              bool includeDirs=false,
                              _str lastid="", 
                              bool exact_match=false)
{
   //say("insert_files_of_extension: includePath="buf_name" directoryPrefix="directoryPrefix);
   // get the path of the current buffer
   dir_name := _strip_filename(buf_name,'N');
   if (dir_name=="") {
      return(0);
   }
   origDirectory := directoryPrefix;
   _maybe_append_filesep(dir_name);
   directoryPrefix = stranslate(directoryPrefix, FILESEP, FILESEP2);
   _maybe_append_filesep(directoryPrefix);
   if (length(directoryPrefix) > 1) {
      dir_name :+= directoryPrefix;
   } else {
      directoryPrefix = "";
   }

   //  No directories will be found since the D switch is not on.
   num_files := 0;
   prefixOpt := exact_match? "" : " +P";
   wildcards := exact_match? "" : "*";

   // if they are including directories, first search for directories
   // that match the prefix expression.
   if (includeDirs) {
      filename := file_match(_maybe_quote_filename(dir_name:+lastid:+wildcards):+prefixOpt" -X",1); // find first.
      for (;;) {
         if (_CheckTimeout()) return num_files;
         if (filename=="=" || filename=="")  break;
         if (_last_char(filename)==FILESEP) {
            includeFile := substr(filename, 1, length(filename)-1);
            includeFile = _strip_filename(includeFile,'P');
            if (_first_char(includeFile) != "." || (includeFile == ".." && directoryPrefix=="") ) {
               tag_tree_insert_tag(tree_wid, tree_root, 0, 1, TREE_ADD_AS_CHILD, origDirectory:+includeFile:+"/", "file", filename, 1, "", 0, "");
               num_files++;
            }
         }
         // Be sure to pass filename with correct path.
         // Result filename is built with path of given file name.
         filename=file_match(filename,0);  // find next.
      }
   }

   // split up the list of extensions (for effeciency)
   searchExt := "";
   _str allExtensions[];
   split(substr(extension_list,2,length(extension_list)-2), ";", allExtensions);

   // if there are more than 10 extensions to search for, then
   // just do a simple wildcard search for all files and filter later
   if (!exact_match && allExtensions._length() > 10) {
      allExtensions._makeempty();
      allExtensions[0] = ALLFILES_RE;
   } else if (pos(".", lastid) > 0) {
      allExtensions[allExtensions._length()] = "";
   }

   // next search through the extensions
   foreach (searchExt in allExtensions) {
      if (searchExt != ALLFILES_RE && searchExt != "") {
         searchExt = wildcards:+".":+searchExt;
      }
      filename := file_match(_maybe_quote_filename(dir_name:+lastid:+searchExt):+prefixOpt" -D",1); // find first.
      for (;;) {
         if (_CheckTimeout()) return num_files;
         if (filename=="=" || filename=="")  break;
         _str ext=_get_extension(filename);
         if (referExtension) ext=_Ext2LangId(ext);
         if (pos(";"ext";",extension_list)) {
            includeFile := _strip_filename(filename,'P');
            tag_tree_insert_tag(tree_wid, tree_root, 0, 1, TREE_ADD_AS_CHILD, origDirectory:+includeFile, "file", filename, 1, "", 0, "");
            num_files++;
         }
         // Be sure to pass filename with correct path.
         // Result filename is built with path of given file name.
         filename=file_match(filename,0);  // find next.
      }
   }

   // that's all folkses
   return(num_files);
}

