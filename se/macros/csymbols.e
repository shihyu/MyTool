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
#import "c.e"
#import "cbrowser.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "ccontext.e"
#import "cutil.e"
#import "dlgman.e"
#import "main.e"
#import "recmacro.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "se/tags/TaggingGuard.e"
#endregion

/**
 * Structure used to group together items related to the actual function 
 * arguments passed into a function for function overloading resolution. 
 */
struct C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS {
   bool filterFunctionSignatures;
   _str functionArguments;
   int  numFunctionArguments;
   _str functionArgumentsFilename;
   int  functionArgumentsLine;
   long functionArgumentsPos;
};

/*
  The syntax T? is shorthand for System.Nullable<T>, and the two forms can be used interchangeably.
  For simplicity, convert this to the longer form.
*/
static void _xlat_csharp_shorthand_nullable(_str &return_type)
{

   //System.Nullable<System.Nullable<int> [] > ?;
   //int ?[]?;

   //System.Nullable<System.Nullable<int> []>;

   for (;;) {
      _str s1, s2;
      parse return_type with s1 "?" +0 s2;
      if (s2=="") {
         return;
      }
      return_type="System.Nullable<"s1">":+substr(s2,2);
   }
}

// Returns true if brackets in an expression indicate array
// indexing.  Not true for Scala.
static bool brackets_index_arrays()
{
   return !_LanguageInheritsFrom('scala');
}

// Returns a signature for the current function scope.
// This is used to construct the hash key for 
// caching past context tagging results.
static _str _c_get_current_scope_signature(VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                         auto cur_type_name, auto cur_type_id, 
                                         auto cur_context, auto cur_class, auto cur_package,
                                         visited, depth+1);
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_args, context_id, auto cur_args);
      result := cur_context;
      _maybe_append(result, '.');
      result :+= cur_tag_name;
      if (cur_args != "") {
         result :+= "(":+cur_args:+")";
      }
      if (cur_flags & SE_TAG_FLAG_CONSTEXPR) {
         result :+= " constexpr";
      } else if (cur_flags & SE_TAG_FLAG_CONSTEVAL) {
         result :+= " consteval";
      } else if (cur_flags & SE_TAG_FLAG_CONSTINIT) {
         result :+= " constinit";
      } 
      if (cur_flags & SE_TAG_FLAG_CONST) {
         result :+= " const";
      }
      if (cur_flags & SE_TAG_FLAG_VOLATILE) {
         result :+= " volatile";
      }
      return result;
   }
   return "";
}

/**
 * Utility function for parsing the syntax of a return type
 * pulled from the tag database, tag_get_detail(VS_TAGDETAIL_return, ...)
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param symbol             name of symbol having given return type
 * @param search_class_name  class context to evaluate return type relative to
 * @param file_name          file from which return type string comes
 * @param return_type        return type string to be parsed (e.g. FooBar **)
 * @param isjava             Is this Java, JavaScript, or similar language?
 * @param rt                 (reference) return type information
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _c_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                         _str symbol, _str search_class_name,
                         _str file_name, _str return_type, bool isjava,
                         struct VS_TAG_RETURN_TYPE &rt,
                         VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_parse_return_type: ==============================================================");
      isay(depth,"_c_parse_return_type(symbol="symbol", search_class="search_class_name", return_type="return_type);
      isay(depth,"_c_parse_return_type(file_name="file_name", depth="depth")");
   }

   // filter out mutual recursion
   current_scope := _c_get_current_scope_signature(visited, depth);
   input_args := "parse;"symbol";"current_scope";"search_class_name";"file_name";"return_type";"p_buf_name";"tag_return_type_string(rt);
   status := _CodeHelpCheckVisited(input_args, "_c_parse_return_type", rt, visited, depth);
   if (!status) {
      if (_chdebug) {
         tag_return_type_dump(rt,"_c_parse_return_type: SHORTCUT SUCCESS",depth);
      }
      return 0;
   }
   if (status < 0) {
      errorArgs[1]= (symbol != "")? symbol : return_type;
      if (_chdebug) {
         isay(depth, "_c_parse_return_type: FAIL, WHY");
      }
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // locals
   num_args := 0;
   found_seperator := false;
   orig_return_type := return_type;
   orig_search_class := search_class_name;
   template_sig := "";
   VS_TAG_RETURN_TYPE orig_rt = rt;
   tag_return_type_init(rt);
   if (_chdebug) {
      tag_return_type_dump(orig_rt,"_c_parse_return_type: ORIG_RT",depth+1);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true);

   //
   // C# nullable types
   //    int?
   //    double?
   //    mytype?
   //    new T?(x)
   //
   // The syntax T? is shorthand for System.Nullable<T>,
   // and the two forms can be used interchangeably.
   //
   if (_LanguageInheritsFrom("cs") && pos("?",return_type)) {
      _xlat_csharp_shorthand_nullable(return_type);
   }

   // Slick-C type inferred declarations
   //    b := 3;
   //    auto b = 3;
   // Get the type of the RHS of the expression.
   //
   if (_c_is_type_inferred(return_type, auto add_const=false)) {
      if (_chdebug) {
         isay(depth, "_c_parse_return_type: INFERRED TYPE, return_type="return_type);
      }
      parse return_type with . "=" return_type;
      doInferredLookup := true;
      return_type = strip(return_type, 'L');
      if (_LanguageInheritsFrom("py")) {
         /*
            If you modify this code below, you also need to modify
            the code in PythonParser.cpp for handling the return
            type inference.

            PythonParser::maybeSetFunctionReturnType()
         */
         ch1 := substr(return_type,1,1);
         if (ch1=="[") {
            return_type="types.ListType";
            doInferredLookup=false;
         } else if (ch1=="{") {
            // This will get confused if a string contains a colon or a comma
            i := pos("[:,]",return_type,1,"r");
            hit_colon := false;
            if (i && substr(return_type,i,1)==":") {
               hit_colon=true;
            }
            if (return_type=="{}" || return_type=="{ }" || hit_colon) {
               return_type="types.DictType";
            } else {
               return_type="PySet";
            }
            doInferredLookup=false;
         } else if (ch1=="(") {
            return_type="types.TupleType";
            doInferredLookup=false;
         } else if (ch1=='"' || ch1=="'" || 
                    ( (strieq(ch1,'r') || strieq(ch1,'u')) && 
                      (substr(return_type,2,1)=='"' || substr(return_type,2,1)=="'")
                    ) ||
                    ( strieq(substr(return_type,1,2),"ur") &&
                      (substr(return_type,3,1)=='"' || substr(return_type,3,1)=="'")
                    )
                    ) {
            strip(return_type,"L","u");
            return_type="types.StringType";
            doInferredLookup=false;
         } else if (ch1=='"' || ch1=="'" || 
                    ( (strieq(ch1,"b")) && 
                      (substr(return_type,2,1)=='"' || substr(return_type,2,1)=="'")
                    ) 
                   ) {
            strip(return_type,"L","u");
            return_type="PyBytes";
            doInferredLookup=false;
         /*} else if (isdigit(ch1)) {
            return_type="PyObject";
            doInferredLookup=false;*/
         }
      }
      alternate_return_type := "";
      if (_LanguageInheritsFrom("c") && _first_char(return_type) == ":") {
         return_type = "*((" :+ substr(return_type, 2) :+ ").begin())";
         alternate_return_type = "(" :+ substr(return_type, 2) :+ ")[0]";
      }
      if (_LanguageInheritsFrom("java") && _first_char(return_type) == ":") {
         return_type = substr(return_type, 2) :+ ".iterator().next()";
      }
      if (doInferredLookup) {
         orig_inferred_rt := rt;
         status = _c_get_type_of_expression(errorArgs, tag_files,
                                            symbol, search_class_name, "", 
                                            VSCODEHELP_PREFIX_NULL, 
                                            expr:return_type, 
                                            rt, visited, depth+1);
         if (add_const) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (_chdebug) {
            tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
         }
         if (_LanguageInheritsFrom("py") && (status || rt.return_type=="")) {
            return_type="PyObject";
            status = _c_get_type_of_expression(errorArgs, tag_files,
                                               symbol, search_class_name, "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:return_type, 
                                               rt, visited, depth+1);
            if (add_const) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (_chdebug) {
               tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
            }
         }
         if ((status < 0 || rt.return_type == "") && alternate_return_type != "") {
            rt = orig_inferred_rt;
            status = _c_get_type_of_expression(errorArgs, tag_files,
                                               symbol, search_class_name, "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:alternate_return_type, 
                                               rt, visited, depth+1);
            if (add_const) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (_chdebug) {
               tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
            }
            if (_LanguageInheritsFrom("py") && (status || rt.return_type=="")) {
               return_type="PyObject";
               status = _c_get_type_of_expression(errorArgs, tag_files,
                                                  symbol, search_class_name, "", 
                                                  VSCODEHELP_PREFIX_NULL, 
                                                  expr:return_type, 
                                                  rt, visited, depth+1);
               if (add_const) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
               if (_chdebug) {
                  tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
               }
            }
         }
         if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
            visited:[input_args]=rt;
         } else if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
         }
         return status;
      }
   }

   if (_chdebug) {
      isay(depth, "_c_parse_return_type: NOT INFERRED");
   }

   not_result := false;
   loopCount := 0;
   ch := prev_ch := next_ch := ""; 
   notparen := _LanguageInheritsFrom("d")? '|\!\(|\!':'';
   maybenum := _LanguageInheritsFrom("rs")? '|:i':'';
   ch_re := '^ @{\:\:|\:|\/|\.\.\.|\:\[|\[|\]'notparen'|[.<>*&!()\^]|:v|'_clex_identifier_re()'|\@:i:v|\@:v|\@:i'maybenum'}';

   while (return_type != "") {

      if (_chdebug) {
         isay(depth, "_c_parse_return_type: REMAINING return_type="return_type);
         tag_return_type_dump(rt, "_c_parse_return_type: REMAINING rt= ", depth+1);
      }

      // evaluating a prefix should not take more than 20 iterations
      loopCount++;
      if (loopCount > 20) {
         //isay(depth, "_c_parse_return_type: BREAKING ENDLESS LOOP return_type="return_type);
         break;
      }

      // if the return type is simply a builtin, then stop here
      if (_c_is_builtin_type(strip(return_type)) && rt.return_type=="" &&
          !_LanguageInheritsFrom("cs") && 
          !(_LanguageInheritsFrom("e") && return_type=="int") && 
          !_LanguageInheritsFrom("d")) {
         //isay(depth, "_c_parse_return_type: BUILTIN");
         rt.return_type = strip(return_type);
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         if (_c_is_builtin_type(rt.return_type,true)) {
            visited:[input_args]=rt;
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: BUILTIN TYPE="return_type);
            }
            return 0;
         }
         visited:[input_args]=rt;
         errorArgs[1] = rt.return_type;
         errorArgs[2] = orig_return_type;
         return VSCODEHELPRC_BUILTIN_TYPE;
      }

      // parse the next token off of the return type
      if (pos(ch_re, return_type, 1, 'r') <= 0) {
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: NO REGEX MATCH PARSING RETURN TYPE");
         }
         break;
      }
      prev_ch = ch;
      ch = substr(return_type, pos('S0'), pos('0'));
      return_type = substr(return_type, pos('S0')+pos('0'));

      // get the next, next token from the return type
      if (pos(ch_re, return_type, 1, 'r') <= 0) {
         next_ch = "";
      } else {
         next_ch = substr(return_type, pos('S0'), pos('0'));
      }

      // report parsing information
      if (_chdebug) {
         isay(depth,"_c_parse_return_type: -------------------------------------------------------------------");
         isay(depth,"_c_parse_return_type: prev_ch="prev_ch" ch="ch" next_ch="next_ch" return_type="return_type);
         tag_return_type_dump(rt, "_c_parse_return_type", depth);
      }

      // do the right thing depending on the token
      switch (ch) {

      // package separators, leading '::" implies global scope
      case "::":
      case "/":
         search_class_name = rt.return_type;
         found_seperator = true;
         if (rt.return_type == "") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         }
         break;

      // member access or tag database class separator
      case ".":
      case ":":
         search_class_name = rt.return_type;
         found_seperator = true;
         if (ch=="." && _LanguageInheritsFrom("d") && rt.return_type == "") {
            tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                    auto cur_type_name, auto cur_type_id, 
                                    auto cur_context, auto cur_class, auto cur_package,
                                    visited, depth+1);
            rt.return_type = cur_package;
            search_class_name = cur_package; 
         } else if (ch == ':' && rt.return_type == "") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         }
         break;

      // increment the number of pointers
      case "*":
      case "^":
         if (rt.return_type != "") {
            rt.pointer_count++;
         }
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: PARSE("ch") pointer_count="rt.pointer_count);
         }
         break;

      // as far as our analysis cares, references are just like values
      case "&":
      case "%":
         if (rt.return_type != "") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
         }
         break;

      // Slick-C hash table
      case ":[":
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         if (rt.pointer_count==0) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_HASHTABLE;
         } else if (rt.pointer_count==1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_HASHTABLE2;
         }
         rt.pointer_count++;
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: PARSE:[], pointer_count="rt.pointer_count);
         }
         break;

      // Array type, increment the pointer count
      case "?[":
      case "[":
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         if (_LanguageInheritsFrom("rul") && rt.return_type=="STRING" && rt.pointer_count==0) {
            // the array just indicates the array size
         } else {
            if (brackets_index_arrays()) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
               rt.pointer_count++;
            }
         }
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: PARSE[], pointer_count="rt.pointer_count);
         }
         break;

      // closing bracket, ignore it
      case "]":
         break;

      // Java 5 variable length argument lists, final argument is really array
      case "...":
         if (_LanguageInheritsFrom("java")) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
            rt.pointer_count++;
         }
         break;

      // function call, #define, or cast
      case "(":
         parenexp := "";
         if (!match_parens(return_type, parenexp, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         // verify that array arguments within parens all match
         while (pos("[", parenexp)) {
            parenexp = substr(parenexp, pos('S')+1);
            if (!match_brackets(parenexp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            rt.pointer_count++;
         }
         // this is a pointer to array
         if (next_ch == "[" || next_ch == ":[" || next_ch == "?[") {
            while (pos("*", parenexp)) {
               parenexp = substr(parenexp, pos('S')+1);
               rt.pointer_count++;
            }
         }
         break;

      // closing parenthesis, ignore it
      case ")":
         break;

      // not expression, or perhaps D template shorthand expression
      case "!":
         if (rt.return_type == "") {
            not_result = !not_result;
         } else if (_LanguageInheritsFrom("d")) {
            // drop through to D template case
         } else {
            break;
         }

      // template arguments
      case "<":
      case "!(":
         // first try to match leading < with > for template arguments
         _str template_parms[];
         if (ch :== "!") {
            paren_pos := pos('[^!]\(', return_type, 1, 'r');
            if (paren_pos > 0) {
               template_parms[0] = substr(return_type, 1, paren_pos-1);
               return_type = substr(return_type, paren_pos);
            } else {
               template_parms[0] = return_type;
               return_type = "";
            }
         } else if (!match_templates(return_type, template_parms)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH;
         }
         // look up specialized template
         template_class_name := rt.return_type;
         template_args := join(template_parms,",");
         template_inner := "";
         template_outer := "";
         status = 0;
         tag_split_class_name(rt.return_type, template_inner, template_outer);
         specialized := tag_check_for_template(template_inner:+"<"template_args">", template_outer, true, tag_files, template_sig, visited, depth+1);
         if (!specialized && template_inner == "__tree_node_types" && _LanguageInheritsFrom("c") && _c_is_stl_class(rt.return_type)) {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: SPECIAL CASE __tree_node_type: "template_inner:+"<"template_args">");
            }
            specialized = 1;
         }
         if (specialized > 0) {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: SPECIALIZED TEMPLATE: "template_inner:+"<"template_args">");
            }
            template_rt := rt;
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files, 
                                                  template_inner"<"template_args">",
                                                  template_outer, 
                                                  isjava, 
                                                  SE_TAG_FILTER_ANYTHING,
                                                  context_flags:0, 
                                                  maybe_class_name:true, 
                                                  substituteTemplateArguments:false,
                                                  actualFunctionArguments:null, 
                                                  template_rt, 
                                                  visited, 
                                                  depth+1);
            if (status == 0) {
               rt = template_rt;
            } else {
               specialized=0;
            }
         }

         // now look up just the class, is it a template?
         // also look for an imported template type
         if (status >= 0 && !specialized) {
            if (tag_check_for_template(template_inner, template_outer, true, tag_files, template_sig, visited, depth+1)) {
               if (template_sig == "") {
                  tag_get_info_from_return_type(rt, auto template_cm);
                  template_sig = template_cm.template_args;
               }
            } else if (_LanguageInheritsFrom("c") && tag_check_for_import(template_inner, template_outer, tag_files, true, visited, depth+1)) {
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: IMPORTED TEMPLATE: "template_inner:+"<"template_args">");
               }
               template_rt := rt;
               status = _c_get_return_type_of_symbol(errorArgs, 
                                                     tag_files, 
                                                     template_inner,
                                                     template_outer, 
                                                     isjava, 
                                                     SE_TAG_FILTER_ANYTHING,
                                                     context_flags:0, 
                                                     maybe_class_name:true, 
                                                     substituteTemplateArguments:false,
                                                     actualFunctionArguments:null, 
                                                     template_rt, 
                                                     visited, 
                                                     depth+1);
               if (status == 0 && template_rt.istemplate) {
                  rt = template_rt;
               }
            } else {
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: NOT A TEMPLATE specialized="specialized);
                  isay(depth, "_c_parse_return_type: NOT A TEMPLATE rt.return_type="rt.return_type);
                  isay(depth, "_c_parse_return_type: NOT A TEMPLATE template_inner="template_inner);
                  isay(depth, "_c_parse_return_type: NOT A TEMPLATE template_outer="template_outer);
                  isay(depth, "_c_parse_return_type: NOT A TEMPLATE status="status);
               }
               errorArgs[1] = rt.return_type;
               return VSCODEHELPRC_NOT_A_TEMPLATE_CLASS;
            }
         }

         if (_chdebug) {
            isay(depth,"_c_parse_return_type: CLASS="rt.return_type" TEMPLATE_SIG="template_sig);
            isay(depth,"_c_parse_return_type: CLASS="rt.return_type" TEMPLATE_ARGS="template_args);
            tag_return_type_dump(rt, "_c_parse_return_type: TEMPLATE rt", depth);
            tag_return_type_dump(orig_rt, "_c_parse_return_type: TEMPLATE orig_rt", depth);
         }
         // now create hash table of formal params to actual
         rt.istemplate = true;
         rt.isvariadic = false;
         if (status >= 0 && rt.return_type :!= search_class_name) {

            // transfer template arguments
            rt.template_args  = orig_rt.template_args;
            rt.template_names = orig_rt.template_names;
            rt.template_types = orig_rt.template_types;

            status = _c_substitute_template_args(orig_search_class, 
                                                 file_name, isjava, 
                                                 template_parms, 
                                                 template_sig,
                                                 rt.template_args, 
                                                 rt.template_names, 
                                                 rt.template_types,
                                                 rt.isvariadic,
                                                 template_class_name, 
                                                 template_file:"",
                                                 tag_files, 
                                                 visited, depth+1);
            if (_chdebug) {
               tag_return_type_dump(rt, "_c_parse_return_type: NEW TEMPLATE ARGS", depth);
            }
            /*
            // combine the template arguments from this template with the
            // template arguments from the enclosing template body
            arg_name := "";
            arg_value := "";
            VS_TAG_RETURN_TYPE arg_type;
            foreach (arg_name => arg_value in orig_rt.template_args) {
               if (!rt.template_args._indexin(arg_name)) {
                  rt.template_args:[arg_name] = arg_value;
               }
            }
            foreach (arg_name in orig_rt.template_names) {
               if (!_inarray(arg_name, rt.template_names)) {
                  rt.template_names :+= arg_name;
               }
            }
            foreach (arg_name => arg_type in orig_rt.template_types) {
               if (!rt.template_types._indexin(arg_name)) {
                  rt.template_types:[arg_name] = arg_type;
               }
            }
            if (_chdebug) {
               tag_return_type_dump(rt, "_c_parse_return_type: ALL TEMPLATE ARGS", depth);
            }
            */
         }
         if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
            return status;
         }
         break;

      // closing template arguments, ignore it
      case ">":
         break;

      // all keywords need to drop through to the identifier case if
      // they do not apply to the current language
      case "const":
      case "constexpr":
      case "constinit":
      case "consteval":
      case "volatile":
      case "restrict":
      case "extern":
      case "struct":
      case "class":
      case "interface":
      case "union":
      case "typename":
      case "template":
      case "enum":
      case "enum_flags":
         if (!_LanguageInheritsFrom("rul") && !_LanguageInheritsFrom("cs")) {
            if (ch:=="volatile") {
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
               }
            } else if (ch:=="const" || ch:=="constexpr" || ch:=="constinit" || ch:=="consteval") {
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
            } else if (ch:=="interface" && return_type=="" && rt.return_type=="") {
               rt.return_type=ch;
            }
            break;
         }


      // handle special Slick-C builtins, mapped to internal classes
      case "typeless":          if (ch:=="typeless"          && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_typeless"; break;}
      case "_str":              if (ch:=="_str"              && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_string";   break;}
      case "_control":          if (ch:=="_control"          && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_control";  break;}
      case "_sc_lang_control":  if (ch:=="_sc_lang_control"  && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_control";  break;}
      case "_sc_lang_string":   if (ch:=="_sc_lang_string"   && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_string";   break;}
      case "_sc_lang_typeless": if (ch:=="_sc_lang_typeless" && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_typeless"; break;}
      case "_sc_lang_form":     if (ch:=="_sc_lang_form"     && _LanguageInheritsFrom("e")) {rt.return_type="_sc_lang_form";     break;}
      case "_form":
      case "_editor":
      case "_text_box":
      case "_check_box":
      case "_command_button":
      case "_radio_button":
      case "_frame":
      case "_label":
      case "_list_box":
      case "_vscroll_bar":
      case "_hscroll_bar":
      case "_combo_box":
      case "_picture_box":
      case "_image":
      case "_gauge":
      case "_spin":
      case "_sstab":
      case "_minihtml":
      case "_tree_view":
      case "_switch":
      case "_textbrowser":
         if (_LanguageInheritsFrom("e")) {
            sc_lang_type := _c_get_boxing_conversion(ch, "e");
            if (sc_lang_type != "") rt.return_type = sc_lang_type;
            break;
         }

      // handle special C# builtins, mapped to System classes
      case "object":   if (ch:=="object"   && _LanguageInheritsFrom("cs")) {rt.return_type="System/Object";break;}
                       if (ch:=="object"   && _LanguageInheritsFrom("jsl")){rt.return_type="System/Object";break;}
      case "string":   if (ch:=="string"   && _LanguageInheritsFrom("cs")) {rt.return_type="System/String";break;}
                       if (ch:=="string"   && _LanguageInheritsFrom("jsl")){rt.return_type="System/String";break;}
      case "delegate": if (ch:=="delegate" && _LanguageInheritsFrom("cs")) {rt.return_type="System/Delegate";break;}
                       if (ch:=="delegate" && _LanguageInheritsFrom("jsl")){rt.return_type="System/Delegate";break;}
      case "void":     if (ch:=="void"     && _LanguageInheritsFrom("d"))  {rt.return_type="__ANY_TYPE";break;}
      case "str":      if (ch:=="str"      && _LanguageInheritsFrom("rs")) {rt.return_type="alloc/str/str";break;}
      case "String":   if (ch:=="String"   && _LanguageInheritsFrom("rs")) {rt.return_type="alloc/string/String";break;}
      //case "id":       if (ch:=="id"       && _LanguageInheritsFrom("m"))  {rt.return_type="NSObject";break;}
      case "CFString": if (ch:=="CFString" && _LanguageInheritsFrom("m"))  {rt.return_type="NSString";break;}
      
      // InstallScript pointers
      case "POINTER":
         if (_LanguageInheritsFrom("rul") && ch:=="POINTER" && rt.return_type!="") {
            rt.pointer_count++;
            break;
         }

      // InstallScript reference types
      case "BYREF":
         if (_LanguageInheritsFrom("rul") && ch:=="BYREF") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }

      // Slick-C typeless reference variables
      case "var":
         if (_LanguageInheritsFrom("e") && ch:=="var") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            rt.return_type="typeless";
            visited:[input_args]=rt;
            return(0);
         }

      // C# parameter tyupes, by reference
      case "in":
      case "ref":
      case "out":
      case "params":
         if (_LanguageInheritsFrom("cs") && ch:=="out") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_OUT;
            break;
         }
         if (_LanguageInheritsFrom("cs") && ch:=="ref") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }
         if (_LanguageInheritsFrom("rs") && ch:=="ref") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }
         if (_LanguageInheritsFrom("cs") && ch:=="in") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_IN;
            break;
         }
         if (_LanguageInheritsFrom("cs") && ch:=="params") {
            break;
         }

      // C++ static and inline (ignore them)
      case "static":
      case "inline":
         if (_LanguageInheritsFrom("c") && ch:=="static") {
            break;
         }
         if (_LanguageInheritsFrom("c") && ch:=="inline") {
            break;
         }

      // Rust parameter types, by reference
      case "mut":
      case "box":
         if (_LanguageInheritsFrom("rs") && ch:=="mut") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_OUT;
            break;
         }
         if (_LanguageInheritsFrom("rs") && ch:=="box") {
            break;
         }

      // C# readonly parameters, treat this like 'const'
      case "readonly":
         if (_LanguageInheritsFrom("cs") && (ch:=="readonly")) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            break;
         }

      // C/C++ signed and unsigned builtin types
      case "signed":
      case "unsigned":
         if (_LanguageInheritsFrom("c") && (ch:=="signed" || ch:=="unsigned")) {
            if (_c_is_builtin_type(return_type) && rt.return_type=="") {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               rt.return_type=ch" "return_type;
               visited:[input_args]=rt;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return VSCODEHELPRC_BUILTIN_TYPE;
            }
         }
         
      // C/C++ long integers, long long, and long double
      case "long":
         if (_LanguageInheritsFrom("c") && ch:=="long") {
            if (_c_is_builtin_type(return_type) && rt.return_type=="") {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               rt.return_type=ch" "return_type;
               visited:[input_args]=rt;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return VSCODEHELPRC_BUILTIN_TYPE;
            }
         }

      // C/C++ integers, long int, and singed int, etc
      case "int":
         if (_LanguageInheritsFrom("c") && ch:=="int") {
            if (_c_is_builtin_type(return_type) && rt.return_type=="") {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               rt.return_type=ch" "return_type;
               visited:[input_args]=rt;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return VSCODEHELPRC_BUILTIN_TYPE;
            }
         } else if (_LanguageInheritsFrom("e") && rt.return_type=="" && rt.pointer_count==0) {
            box_type := _e_get_control_name_type(ch,symbol);
            if (box_type != "") {
               rt.return_type = box_type;
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               visited:[input_args]=rt;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return 0;
            }
         }

      // Shortcut all the C++ STL reference and pointer nonsense
      //case "shared_ptr":
      //case "unique_ptr":
      //case "weak_ptr":
      //case "auto_ptr":
      case "const_reference":
      case "reference":
      case "const_pointer":
      case "pointer":
      case "__const_pointer":
      case "__pointer":
      case "__rebind_pointer":
      case "__pointer_type":
         if (_LanguageInheritsFrom("c") &&
             _c_is_stl_class(search_class_name) &&
             pos(' 'ch' ', " const_reference reference const_pointer pointer __const_pointer __pointer __pointer_type __rebind_pointer "/*shared_ptr unique_ptr weak_ptr auto_ptr "*/)) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            template_arg_type := "";
            template_arg_name := "";
            status = 0;
            foreach (auto targ_name in "_Ty _Ty2 _Tp _Kty _To value_type _Pr T") {
               if (orig_rt.template_args._indexin(targ_name) && orig_rt.template_types._indexin(targ_name)) {
                  template_arg_type = orig_rt.template_args:[targ_name];
                  typeof_rt         = orig_rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               }
            }
            if (template_arg_name != "") {
               if (typeof_rt.return_type == "" && orig_rt != null) {
                  typeof_rt = orig_rt;
                  status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                     "", "", "", 
                                                     VSCODEHELP_PREFIX_NULL, 
                                                     expr:template_arg_type, 
                                                     typeof_rt, 
                                                     visited, depth+1);
               }
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: POINTER OR REFERENCE ch="ch" status="status" template_arg_name="template_arg_name" template_arg_type="template_arg_type" typeof_rt="typeof_rt.return_type);
               }
               if (status) return status;
               if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) && pos("const", ch)) {
                  typeof_rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
               if (pos("pointer", ch) || pos("_ptr", ch)) {
                  if (typeof_rt != null && isinteger(typeof_rt.pointer_count)) {
                     typeof_rt.pointer_count++;
                  }
               }
               if (orig_rt != null && 
                   substr(search_class_name,1,9) == "std/_Tree" &&
                   orig_rt.template_args._indexin("_Kty") && orig_rt.template_types._indexin("_Kty") && 
                   orig_rt.template_args._indexin("_Ty")  && orig_rt.template_types._indexin("_Ty")) {
                  typeof_rt.return_type = "std/pair";
                  typeof_rt.template_names[0]="_Ty1";
                  typeof_rt.template_names[1]="_Ty2";
                  typeof_rt.template_args:["_Ty1"] = orig_rt.template_args:["_Kty"];
                  typeof_rt.template_args:["_Ty2"] = orig_rt.template_args:["_Ty"];
                  typeof_rt.template_types:["_Ty1"] = orig_rt.template_types:["_Kty"];
                  typeof_rt.template_types:["_Ty2"] = orig_rt.template_types:["_Ty"];
               }
               rt = typeof_rt;
               continue;
            }
         }

      case "__node_type":
      case "__node_pointer":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             (ch :== "__node_type" || ch :== "__node_pointer" )) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            template_arg_type := "";
            template_arg_name := "";
            status = 0;
            foreach (auto targ_name in "_Tp _NodeT _NodePtr") {
               if (orig_rt.template_args._indexin(targ_name) && orig_rt.template_types._indexin(targ_name) && _inarray(targ_name,orig_rt.template_names)) {
                  template_arg_type = orig_rt.template_args:[targ_name];
                  typeof_rt         = orig_rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               } else if (rt.template_args._indexin(targ_name) && rt.template_types._indexin(targ_name) && _inarray(targ_name,rt.template_names)) {
                  template_arg_type = rt.template_args:[targ_name];
                  typeof_rt         = rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               }
            }
            if (template_arg_name != "") {
               if (typeof_rt.return_type == "" && orig_rt != null) {
                  typeof_rt = orig_rt;
                  status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                     "", "", "", 
                                                     VSCODEHELP_PREFIX_NULL, 
                                                     expr:template_arg_type, 
                                                     typeof_rt, 
                                                     visited, depth+1);
               }
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: __NODE_TYPE or __NODE_POINTER ch="ch" status="status" template_arg_name="template_arg_name" template_arg_type="template_arg_type" typeof_rt="typeof_rt.return_type);
               }
               if (status) {
                  if (status == TAGGING_TIMEOUT_RC) {
                     visited._deleteel(input_args);
                  }
                  return status;
               }
               if (typeof_rt != null && isinteger(typeof_rt.pointer_count) && typeof_rt.pointer_count > 0 && template_arg_name == "_NodePtr") {
                  typeof_rt.pointer_count--;
               }
               if (typeof_rt != null && isinteger(typeof_rt.pointer_count) && typeof_rt.pointer_count >= 0 && ch :== "__node_pointer") {
                  typeof_rt.pointer_count++;
               }
               rt = typeof_rt;
               continue;
            }
         }

      case "__node_value_type":
      case "__node_value_type_pointer":
      case "__const_node_value_type_pointer":
      case "__map_value_type_pointer":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             pos(' 'ch' ', " __node_value_type _node_value_type_pointer __const_node_value_type_pointer __map_value_type_pointer " )) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            template_arg_type := "";
            template_arg_name := "";
            status = 0;
            foreach (auto targ_name in "_Tp _NodeT _NodePtr") {
               if (orig_rt.template_args._indexin(targ_name) && orig_rt.template_types._indexin(targ_name) && _inarray(targ_name,orig_rt.template_names)) {
                  template_arg_type = orig_rt.template_args:[targ_name];
                  typeof_rt         = orig_rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               } else if (rt.template_args._indexin(targ_name) && rt.template_types._indexin(targ_name) && _inarray(targ_name,rt.template_names)) {
                  template_arg_type = rt.template_args:[targ_name];
                  typeof_rt         = rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               }
            }
            if (template_arg_name != "") {
               if (typeof_rt.return_type == "" && orig_rt != null) {
                  typeof_rt = orig_rt;
                  status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                     "", "", "", 
                                                     VSCODEHELP_PREFIX_NULL, 
                                                     expr:template_arg_type, 
                                                     typeof_rt, 
                                                     visited, depth+1);
               }
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: __NODE_VALUE_TYPE or POINTER ch="ch" status="status" template_arg_name="template_arg_name" template_arg_type="template_arg_type" typeof_rt="typeof_rt.return_type);
               }
               if (status) return status;
               if (typeof_rt != null && isinteger(typeof_rt.pointer_count) && typeof_rt.pointer_count > 0 && template_arg_name == "_NodePtr") {
                  typeof_rt.pointer_count--;
               }
               if (typeof_rt != null && isinteger(typeof_rt.pointer_count) && ch :== "__node_value_type_pointer") {
                  typeof_rt.pointer_count++;
               } else if (typeof_rt != null && isinteger(typeof_rt.pointer_count) && ch :== "__const node_value_type_pointer") {
                  typeof_rt.pointer_count++;
                  typeof_rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               } else if (typeof_rt != null && typeof_rt.return_type == "std/__value_type" && ch :== "__map_value_type_pointer") {
                  if (typeof_rt.template_types._indexin("_Allocator")) {
                     alloc_rt := typeof_rt.template_types:["_Allocator"];
                     if (alloc_rt.template_types._indexin("_Tp")) {
                        typeof_rt = alloc_rt.template_types:["_Tp"];
                     } else if (alloc_rt.template_types._indexin("T")) {
                        typeof_rt = alloc_rt.template_types:["T"];
                     }
                  } else if (typeof_rt.template_args._indexin("_Tp")  && typeof_rt.template_types._indexin("_Tp") && 
                             typeof_rt.template_args._indexin("_Key") && typeof_rt.template_types._indexin("_Key")) {
                     typeof_rt.return_type = "std/pair";
                     typeof_rt.template_names[0]="_T1";
                     typeof_rt.template_names[1]="_T2";
                     typeof_rt.template_args:["_T1"] = typeof_rt.template_args:["_Key"];
                     typeof_rt.template_args:["_T2"] = typeof_rt.template_args:["_Tp"];
                     typeof_rt.template_types:["_T1"] = typeof_rt.template_types:["_Key"];
                     typeof_rt.template_types:["_T2"] = typeof_rt.template_types:["_Tp"];
                  }
               }
               rt = typeof_rt;
               continue;
            }
         }

      case "__allocator_type":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             (ch :== "__allocator_type" )) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            template_arg_type := "";
            template_arg_name := "";
            status = 0;
            foreach (auto targ_name in "_Allocator _Alloc") {
               if (orig_rt.template_args._indexin(targ_name) && orig_rt.template_types._indexin(targ_name) && _inarray(targ_name,orig_rt.template_names)) {
                  template_arg_type = orig_rt.template_args:[targ_name];
                  typeof_rt         = orig_rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               } else if (rt.template_args._indexin(targ_name) && rt.template_types._indexin(targ_name) && _inarray(targ_name,rt.template_names)) {
                  template_arg_type = rt.template_args:[targ_name];
                  typeof_rt         = rt.template_types:[targ_name];
                  template_arg_name = targ_name;
                  break;
               }
            }
            if (template_arg_name != "") {
               if (typeof_rt.return_type == "" && orig_rt != null) {
                  typeof_rt = orig_rt;
                  status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                     "", "", "", 
                                                     VSCODEHELP_PREFIX_NULL, 
                                                     expr:template_arg_type, 
                                                     typeof_rt, 
                                                     visited, depth+1);
               }
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: __ALLOCATOR_TYPE ch="ch" status="status" template_arg_name="template_arg_name" template_arg_type="template_arg_type" typeof_rt="typeof_rt.return_type);
               }
               if (status) {
                  if (status == TAGGING_TIMEOUT_RC) {
                     visited._deleteel(input_args);
                  }
                  return status;
               }
               rt = typeof_rt;
               continue;
            }
         }

      case "void_pointer":
      case "const_void_pointer":
      case "__void_pointer":
      case "__const_void_pointer":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             pos(' 'ch' ', " __void_pointer __const_void_pointer void_pointer const_void_pointer ")) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            typeof_rt.return_type = "void";
            typeof_rt.pointer_count = 1;
            if (pos("const", ch)) {
               typeof_rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: VOID POINTER ch="ch" status="status" typeof_rt="typeof_rt.return_type);
            }
            rt = typeof_rt;
            continue;
         }

      case "difference_type":
      case "size_type":
      case "__alloc_traits_size_type":
      case "__alloc_traits_difference_type":
      case "__difference_type":
      case "__size_type":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             pos(' 'ch' ', " difference_type size_type __alloc_traits_difference_type __alloc_traits_size_type __difference_type __size_type ")) {
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            typeof_rt.return_type = "size_t";
            typeof_rt.pointer_count = 0;
            if (pos("difference", ch)) {
               typeof_rt.return_type = "ssize_t";
            }
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: SIZE or DIFFERENCE TYPE ch="ch" status="status" typeof_rt="typeof_rt.return_type);
            }
            rt = typeof_rt;
            continue;
         }

      case "__has_allocator_type":
      case "__has_const_pointer":
      case "__has_const_void_pointer":
      case "__has_difference_type":
      case "__has_element_type":
      case "__has_pointer_type":
      case "__has_rebind":
      case "__has_rebind_other":
      case "__has_result_type":
      case "__has_size_type":
      case "__has_void_pointer":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             _first_char(return_type) == '<'    &&
             pos(' 'ch' ', " __has_allocator_type __has_const_pointer __has_const_void_pointer __has_difference_type __has_element_type __has_pointer_type __has_rebind __has_rebind_other __has_result_type __has_size_type __has_void_pointer " )
             ) {
            has_template_return_type := substr(return_type,2);
            _str has_template_parms[];
            if (match_templates(has_template_return_type, has_template_parms) && has_template_parms._length() > 0 && substr(has_template_return_type,1,6) :== "::value") {
               VS_TAG_RETURN_TYPE typeof_rt;
               tag_return_type_init(typeof_rt);
               has_template_return_type = substr(has_template_return_type, 8);
               tag_push_matches();
               num_rebinds := 0;
               type_rt := orig_rt;
               status = _c_parse_return_type(errorArgs, tag_files,
                                             "", rt.return_type, file_name,
                                             has_template_parms[0],
                                             isjava, type_rt,
                                             visited, depth+1);

               // clip off __has_
               look_for_symbol := substr(ch, 7);
               look_for_class  := type_rt.return_type;
               switch (ch) {
               case "__has_rebind_other":
                  look_for_symbol = "other";
                  look_for_class  = type_rt.return_type:+VS_TAGSEPARATOR_package:+"rebind";
                  break;
               case "__has_pointer_type":
                  look_for_symbol = "type";
                  look_for_class  = type_rt.return_type:+VS_TAGSEPARATOR_package:+"pointer";
                  break;
               case "__has_const_pointer":
               case "__has_const_void_pointer":
               case "__has_void_pointer":
                  look_for_class  = type_rt.return_type:+VS_TAGSEPARATOR_package:+look_for_symbol;
                  look_for_symbol = "type";
                  break;
               }
               status = tag_list_in_class(look_for_symbol, look_for_class, 0, 0, tag_files, num_rebinds, 10, SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_TYPEDEF|SE_TAG_FILTER_PACKAGE, SE_TAG_CONTEXT_ANYTHING, true, true, null, null, visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_c_parse_return_type: __HAS TEMPLATE ch="ch" status="status" num_matches="tag_get_num_of_matches());
               }
               if (status > 0 && tag_get_num_of_matches() > 0) {
                  typeof_rt.return_type = "true";
               } else {
                  typeof_rt.return_type = "false";
               }
               tag_pop_matches();
               rt = typeof_rt;
               return_type = has_template_return_type;
               continue;
            }
         }

      case "rebind":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             _first_char(return_type) == '<' &&
             ch :== "rebind" ) {
            rebind_template_return_type := substr(return_type,2);
            _str rebind_template_parms[];
            if (match_templates(rebind_template_return_type, rebind_template_parms) && rebind_template_parms._length() > 0) {
               // evaluate the last parameter, it should be the return type
               if ( _chdebug ) {
                  isay(depth, "_c_parse_return_type: REBIND, first template argument is: "rebind_template_parms[0]);
               }
               value_rt := orig_rt;
               status = _c_parse_return_type(errorArgs, tag_files,
                                             "", "", file_name,
                                             rebind_template_parms[0],
                                             isjava, value_rt,
                                             visited, depth+1);
               if ( _chdebug ) {
                  isay(depth, "_c_parse_return_type: REBIND, status="status);
               }
               // And then use the result
               if (!status) {
                  rt = value_rt;
                  return_type = rebind_template_return_type;
                  continue;
               }
            }
         }

      case "rebind_alloc":
      case "__rebind_pointer":
      case "__pointer_traits_element_type":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             _first_char(return_type) == '<' && 
             pos(' 'ch' ', " rebind_alloc __rebind_pointer __pointer_traits_element_type ")) {
            rebind_template_return_type := substr(return_type,2);
            _str rebind_template_parms[];
            if (match_templates(rebind_template_return_type, rebind_template_parms) && rebind_template_parms._length() > 0 && substr(rebind_template_return_type,1,6) :== "::type") {

               VS_TAG_RETURN_TYPE typeof_rt;
               tag_return_type_init(typeof_rt);
               rebind_template_return_type = substr(rebind_template_return_type, 7);

               // evaluate the last parameter, it should be the return type
               if ( _chdebug ) {
                  isay(depth, "_c_parse_return_type: REBIND, last template argument is: "rebind_template_parms[rebind_template_parms._length()-1]);
               }
               value_rt := orig_rt;
               status = _c_parse_return_type(errorArgs, tag_files,
                                             "", "", file_name,
                                             rebind_template_parms[rebind_template_parms._length()-1],
                                             isjava, value_rt,
                                             visited, depth+1);
               if ( _chdebug ) {
                  isay(depth, "_c_parse_return_type: REBIND, status="status);
               }
               // And then use the result
               if (!status) {
                  if (ch :== "__rebind_pointer") {
                     value_rt.pointer_count++;
                  } else if (ch :== "__pointer_traits_element_type" && value_rt.pointer_count > 0) {
                     value_rt.pointer_count--;
                  }
                  rt = value_rt;
                  return_type = rebind_template_return_type;
                  continue;
               }
            }
         }

      case "tuple_element":
         if (_LanguageInheritsFrom("c") && 
             _c_is_stl_class(search_class_name) &&
             _first_char(return_type) == '<' &&
             orig_rt.istemplate &&
             orig_rt.isvariadic &&
             ch :== "tuple_element" ) {
            if (_chdebug) {
               tag_return_type_dump(rt, "_c_parse_return_type: TUPLE_ELEMENT rt=", depth+1);
               tag_return_type_dump(orig_rt, "_c_parse_return_type: TUPLE_ELEMENT orig_rt=", depth+1);
            }
            tuple_template_return_type := substr(return_type,2);
            _str tuple_template_parms[];
            if (match_templates(tuple_template_return_type, tuple_template_parms) && tuple_template_parms._length() > 1) {

               tuple_template_return_type = strip(tuple_template_return_type);
               if (substr(tuple_template_return_type,1,2) == "::") {
                  tuple_template_return_type = strip(substr(tuple_template_return_type,3));
                  if (substr(tuple_template_return_type,1,4) == "type") {
                     tuple_template_return_type = strip(substr(tuple_template_return_type,5));
                     // evaluate the last parameter, it should be the return type
                     if ( _chdebug ) {
                        isay(depth, "_c_parse_return_type: tuple_template_return_type="tuple_template_return_type);
                        isay(depth, "_c_parse_return_type: TUPLE_ELEMENT, first template argument is: "tuple_template_parms[0]);
                     }
                     value_rt := orig_rt;
                     status = _c_parse_return_type(errorArgs, tag_files,
                                                   "", "", file_name,
                                                   tuple_template_parms[0],
                                                   isjava, value_rt,
                                                   visited, depth+1);
                     if ( _chdebug ) {
                        isay(depth, "_c_parse_return_type: TUPLE_ELEMENT, status="status);
                        tag_return_type_dump(value_rt, "_c_parse_return_type: TUPLE_ELEMENT, rt=", depth);
                     }
                     // if that fails just try to use the expression they gave
                     if (status) value_rt.return_type = tuple_template_parms[0];
                     if (isuinteger(value_rt.return_type)) {
                        if (_chdebug) {
                           isay(depth, "_c_parse_return_type: have integer index="value_rt.return_type);
                        }
                        tuple_template_index := (int)value_rt.return_type;
                        if (tuple_template_index+1 < orig_rt.template_names._length()) {
                           el := orig_rt.template_names[tuple_template_index+1];
                           if (orig_rt.template_types._indexin(el)) {
                              rt = orig_rt.template_types:[el];
                              return_type = tuple_template_return_type;
                              continue;
                           } else if (orig_rt.template_args._indexin(el)) {
                              return_type = orig_rt.template_args:[el];
                              continue;
                           }
                        }
                     }
                  }
               }
            }
         }

      case "Func":
      case "Delegate":
         if (_LanguageInheritsFrom("cs") && (ch:=="Func" || ch:=="Delegate") && _first_char(return_type)=="<") {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: C# Func or Delegate TEMPLATE");
            }
            if_template_return_type := substr(return_type,2);
            _str if_template_parms[];
            if (match_templates(if_template_return_type, if_template_parms)) {
               if (if_template_parms._length() >= 1) {
                  // evaluate the last parameter, it should be the return type
                  if ( _chdebug ) {
                     isay(depth, "_c_parse_return_type: C# Func or Delegate TEMPLATE, first template argument is: "if_template_parms[0]);
                  }
                  value_rt := orig_rt;
                  status = _c_parse_return_type(errorArgs, tag_files,
                                                "", "", file_name,
                                                if_template_parms[0],
                                                isjava, value_rt,
                                                visited, depth+1);
                  if ( _chdebug ) {
                     isay(depth, "_c_parse_return_type: C# Func or Delegate TEMPLATE, status="status);
                  }
                  // And then use the result
                  if (!status) {
                     rt = value_rt;
                     return_type = if_template_return_type;
                     continue;
                  }
               }
            }
         }

      case "input":
      case "output":
      case "inout":
      case "ref":
         if ((_LanguageInheritsFrom("verilog") || _LanguageInheritsFrom("systemverilog")) && 
             (ch:=="input" || ch:=="output" || ch:=="inout" || ch:=="ref")) {
            rt.return_type=ch;
            break;
         }

      case "packed":
         if (_LanguageInheritsFrom("verilog") || _LanguageInheritsFrom("systemverilog")) {
            break;
         }

      case "true":
      case "false":
         if (ch:=="true" || ch:=="false") {
            rt.return_type = "bool";
            break;
         }

      case "null":
         // null object or NULL pointer constant
         if (ch:=="null") {
            if (_LanguageInheritsFrom("java")) {
               rt.return_type = "java/lang/Object";
               visited:[input_args]=rt;
               return 0;
            } else if (_LanguageInheritsFrom("cs")) {
               rt.return_type = "System/Object";
               visited:[input_args]=rt;
               return 0;
            } else if (_LanguageInheritsFrom("e")) {
               rt.return_type = "typeless";
               visited:[input_args]=rt;
               return 0;
            } else {
               rt.return_type = "void";
               rt.pointer_count = 1;
               visited:[input_args]=rt;
               return 0;
            }
         }

      case "NULL":
      case "nullptr":
         // NULL pointer constant
         if (ch:=="NULL" || ch :== "nullptr") {
            rt.return_type = "void";
            rt.pointer_count = 1;
            visited:[input_args]=rt;
            return 0;
         }

      case "nil":
      case "Nil":
      case "NSNull":
         // Objective-C null variants
         if (_LanguageInheritsFrom("m")) {
            if (ch :== "nil") {
               rt.return_type = "Object";
               visited:[input_args]=rt;
               return 0;
            } else if (ch :== "Nil") {
               rt.return_type = "Class";
               visited:[input_args]=rt;
               return 0;
            } else if (ch :== "NSNull") {
               rt.return_type = "NSNull";
               visited:[input_args]=rt;
               return 0;
            }
         }

      case "const_cast":
      case "static_cast":
      case "dynamic_cast":
      case "reinterpret_cast":
      case "decltype":
      case "typeof":
      case "__typeof":
      case "__typeof__":
      case "_If":
      case "enable_if":
      case "enable_if_t":
      case "_Is_simple_alloc":
      case "is_same":
      case "noexcept":
         {
            special_status := _c_get_type_of_special_case_id(errorArgs, 
                                                             tag_files, isjava, 
                                                             ch, return_type, 0, 
                                                             symbol, 
                                                             (rt != null && rt.return_type != "")? rt.return_type : search_class_name, 
                                                             rt, visited, depth+1);
            if (special_status == 0 || special_status == VSCODEHELPRC_BUILTIN_TYPE) {
               continue;
            }
         }

      // Any other type of identifier
      default:

         // report the identifier we are looking up
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: IDENTIFIER, ch="ch);
         }

         // is the current token a builtin?
         if (_c_is_builtin_type(ch) && rt.return_type=="") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
            rt.return_type = ch;
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: depth: IDENTIFIER IS BUILTIN");
            }
            continue;
         }

         // try simple macro substitution
         orig_ch := ch;
         if (!isjava && ch!="interface" &&
             tag_check_for_class(ch, rt.return_type, true, tag_files, visited, depth+1) <= 0 && 
             tag_check_for_define(ch, 0, tag_files, ch)) {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: IDENTIFIER IS #define to "ch);
            }
            switch (ch) {
            case "":
            case "extern":
            case "static":
            case "inline":
            case "struct":
            case "class":
            case "interface":
            case "union":
            case "typename":
            case "enum":
            case "enum_flags":
               continue;
            case "volatile":
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
               }
               continue;
            case "const":
            case "constexpr":
            case "constinit":
            case "consteval":
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
               continue;
            }
         }

         // try template argument substitution
         if (!found_seperator && orig_rt.template_types._indexin(ch)) {
            if (_chdebug) {
               isay(depth,"_c_parse_return_type: USING TEMPLATE ARGUMENT (TYPE): "ch);
            }
            rt = orig_rt.template_types:[ch];
            if ((rt == null || rt.return_type == "") && orig_rt.template_args._indexin(ch)) {
               rt.return_type = orig_rt.template_args:[ch];
            }
            continue;
         }
         if (!found_seperator && orig_rt.template_args._indexin(ch) && orig_rt.template_args:[ch] != "") {
            if (_chdebug) {
               isay(depth,"_c_parse_return_type: USING TEMPLATE ARGUMENT (STRING): "ch);
            }
            tag_return_type_init(auto arg_rt);
            arg_status := _c_parse_return_type(errorArgs, 
                                               tag_files, 
                                               ch, search_class_name, 
                                               file_name, 
                                               orig_rt.template_args:[ch], 
                                               isjava, arg_rt, 
                                               visited, depth+1);
            if (arg_status < 0 && search_class_name != null && search_class_name != "") {
               tag_return_type_init(arg_rt);
               arg_status = _c_parse_return_type(errorArgs, 
                                                 tag_files, 
                                                 ch, "",
                                                 file_name, 
                                                 orig_rt.template_args:[ch], 
                                                 isjava, arg_rt, 
                                                 visited, depth+1);
            }
            if (arg_status == 0 || arg_status == VSCODEHELPRC_BUILTIN_TYPE) {
               rt = arg_rt;
               continue;
            }
         }

         // check for an unqualfied package name
         // if we find a namespace alias, let it be handled below
         // if this is a pointer or reference type, then it can't be a namespace
         aliased_to := "";
         if (rt.return_type == "" && !found_seperator && 
             return_type != "" && 
             _first_char(return_type) != "*"      && 
             _first_char(return_type) != "&"      &&
             _first_char(return_type) != "^"      &&
             substr(return_type,1,6) != "const"  &&
             substr(return_type,1,6) != "const&" &&
             substr(return_type,1,6) != "const^" &&
             substr(return_type,1,6) != "const*" &&
             tag_check_for_package(ch, tag_files, true, true, aliased_to, visited, depth+1) && aliased_to=="") {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: package_name="ch);
            }
            rt.return_type = ch;
            continue;
         }

         // check for a qualified package name
         switch (prev_ch) {
         case "::":
         case "/":
         case ":":
         case ".":
            if (rt.return_type!="" && tag_check_for_package(rt.return_type:+prev_ch:+ch, tag_files, false, true, null, visited, depth+1)) {
               rt.return_type = rt.return_type:+prev_ch:+ch;
               found_seperator = false;
               continue;
            }
            if (rt.return_type!="" && tag_check_for_package(rt.return_type:+"/":+ch, tag_files, true, true, null, visited, depth+1)) {
               rt.return_type = rt.return_type:+"/":+ch;
               found_seperator = false;
               continue;
            }
            if (rt.return_type!="" && tag_check_for_class(ch, rt.return_type, true, tag_files, visited, depth+1)) {
               rt.return_type = rt.return_type:+":":+ch;
               found_seperator = false;
               continue;
            }
            break;
         }

         // check for specific qualified package name
         alt_ch1 := "";
         alt_ch2 := "";
         switch (prev_ch) {
         case "::":  alt_ch1 = "/";  break;
         case "/":   alt_ch1 = "::"; break;
         case ":":   alt_ch1 = "."; alt_ch2 = "::"; break;
         case ".":   alt_ch1 = ":"; alt_ch2 = "::"; break;
         }
         if (rt.return_type!="") {
            if (alt_ch1 != "") {
               if (tag_check_for_package(rt.return_type:+alt_ch1:+ch, tag_files, true, true, null, visited, depth+1) ||
                   tag_check_for_package(rt.return_type:+alt_ch1:+ch:+alt_ch1, tag_files, false, true, null, visited, depth+1)) {
                  rt.return_type = rt.return_type:+alt_ch1:+ch;
                  found_seperator = false;
                  continue;
               }
            }
            if (alt_ch2 != "") {
               if (tag_check_for_package(rt.return_type:+alt_ch2:+ch, tag_files, false, true, null, visited, depth+1) &&
                   tag_check_for_package(rt.return_type:+alt_ch2:+ch:+alt_ch2, tag_files, false, true, null, visited, depth+1)) {
                  rt.return_type = rt.return_type:+alt_ch2:+ch;
                  found_seperator = false;
                  continue;
               }
            }
         }
         if (!found_seperator && rt.return_type=="" && (next_ch == "." || next_ch == "::")) {
            if (tag_check_for_package(ch:+next_ch, tag_files, false, true, null, visited, depth+1)) {
               rt.return_type = ch;
               continue;
            }
         }

         // check for compound builtin type names
         if (_c_is_builtin_type(rt.return_type) && _c_is_builtin_type(ch)) {
            rt.return_type = rt.return_type " " ch;
         } else if (rt.return_type=="" && _c_is_builtin_type(ch)) {
            rt.return_type=ch;
         }

         // look up 'ch' using Context Tagging&reg; to it's fullest power
         VS_TAG_RETURN_TYPE ch_rt;
         tag_return_type_init(ch_rt);
         if (found_seperator) {
            ch_rt.template_args  = rt.template_args;
            ch_rt.template_names = rt.template_names;
            ch_rt.template_types = rt.template_types;
            if (rt.return_type != "") {
               search_class_name = rt.return_type;
               if (!tag_check_for_package(rt.return_type, tag_files, true, true, null, visited, depth+1)) {
                  ch_rt.return_flags |= VSCODEHELP_RETURN_TYPE_INCLASS_ONLY;
               }
            } else {
               ch_rt.return_flags = (rt.return_flags | VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY);
            }
         } else {
            ch_rt.template_args  = orig_rt.template_args;
            ch_rt.template_names = orig_rt.template_names;
            ch_rt.template_types = orig_rt.template_types;
            ch_rt.filename       = orig_rt.filename;
            ch_rt.line_number    = orig_rt.line_number;
            if (ch_rt.filename=="") {
               ch_rt.filename=file_name;
            }
         }

         filter_flags := SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ENUM;
         if (next_ch != "<") {
            filter_flags |= SE_TAG_FILTER_TYPEDEF;
            if (next_ch != "") {
               filter_flags |= SE_TAG_FILTER_PACKAGE;
            } else {
               filter_flags |= SE_TAG_FILTER_CONSTANT;
               filter_flags |= SE_TAG_FILTER_MEMBER_VARIABLE;
               filter_flags |= SE_TAG_FILTER_LOCAL_VARIABLE;
               if (prev_ch=="" && rt.return_type=="" && tag_check_for_package(ch, tag_files, true, true, null, visited, depth+1)) {
                  filter_flags |= SE_TAG_FILTER_PACKAGE;
               }
            }
         } else {
            ch_rt.istemplate = true;
         }

         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               ch,
                                               search_class_name, 
                                               isjava, 
                                               filter_flags,
                                               context_flags:0, 
                                               maybe_class_name:true, 
                                               substituteTemplateArguments:false,
                                               actualFunctionArguments:null, 
                                               ch_rt, 
                                               visited, 
                                               depth+1);
         if (_chdebug) {
            isay(depth,"_c_parse_return_type(CH): status="status);
            tag_return_type_dump(ch_rt, "_c_parse_return_type(CH)", depth);
         }
         if (status < 0 && rt.return_type != "" && prev_ch==':' && _LanguageInheritsFrom("c")) {
            break;
         }
         if (!status) {
            if (next_ch != "<") {
               if (ch_rt.return_type :== search_class_name) {
                  ch_rt.template_args  = orig_rt.template_args;
                  ch_rt.template_names = orig_rt.template_names;
                  ch_rt.template_types = orig_rt.template_types;
               } else if (prev_ch == "::") {
                  tag_return_type_merge_templates(ch_rt, rt);
               }
            }
            orig_const_only := (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
            rt = ch_rt;
            rt.return_flags |= orig_const_only;
            found_seperator=false;
            //if (next_ch == "" && _LanguageInheritsFrom("cs") && rt.pointer_count == 0 &&
            //    !(rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN) &&
            //    !(rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
            //   rt.return_flags |= VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            //}
            continue;
         }
         // check for an unqualfied package name
         if (rt.return_type == "" && !found_seperator &&
             tag_check_for_package(ch, tag_files, false, true, null, visited, depth+1) &&
             (tag_check_for_package(ch".", tag_files, false, true, null, visited, depth+1) ||
              tag_check_for_package(ch"/", tag_files, false, true, null, visited, depth+1) ||
              tag_check_for_package(ch":", tag_files, false, true, null, visited, depth+1))) {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: package_name="ch);
            }
            rt.return_type = ch;
            continue;
         }
         if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
            return status;
         }
         if (/*rt.return_type=="" &&*/ return_type=="" && status < 0) {
            return status;
         }
         if (rt.return_type=="" && status==VSCODEHELPRC_NO_SYMBOLS_FOUND) {
            return status;
         }
      }
   }

   if (not_result) {
      //rt.return_type = "!":+rt.return_type;
   }

   if (status == TAGGING_TIMEOUT_RC) {
      visited._deleteel(input_args);
      return status;
   }
   if (rt.return_type == "") {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   if (_chdebug) {
      tag_return_type_dump(rt, "_c_parse_return_type: HERE"__LINE__" returns", depth);
   }
   visited:[input_args]=rt;
   return 0;
}

/**
 * Utility function for retrieving the return type of the given symbol.
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs                    refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files                    list of extension specific tag files
 * @param symbol                       name of symbol having given return type
 * @param search_class_name            class context to evaluate return type relative to
 * @param min_args                     minimum number of arguments for function, used
 *                                     to resolve overloading.
 * @param isjava                       Is this Java, JavaScript, C# or similar?
 * @param filter_flags                 bitset of VS_TAGFILTER_*, allows us to search only
 *                                     certain items in the database (e.g. functions only)
 * @param maybe_class_name             Could the symbol be a class name, for example
 *                                     C++ syntax of BaseObject::method, BaseObject might
 *                                     be a class name.
 * @param rt                           (reference) set to return type information
 * @param visited                      (reference) have we evalued this return type before?
 * @param depth                        depth of recursion (for handling typedefs)
 * @param context_flags                bitset of VS_TAGCONTEXT_* 
 * @param substituteTemplateArguments  substitute template arguments? 
 * @param actualFunctionArguments      (optional, default null) information about 
 *                                     actual function arguments for this symbol
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _c_get_return_type_of(_str (&errorArgs)[], 
                          typeless tag_files,
                          _str symbol, 
                          _str search_class_name,
                          int min_args, 
                          bool isjava,
                          SETagFilterFlags filter_flags, 
                          bool maybe_class_name,
                          bool filterFunctionSignatures,
                          struct VS_TAG_RETURN_TYPE &rt,
                          VS_TAG_RETURN_TYPE (&visited):[], 
                          int depth=0, 
                          SETagContextFlags context_flags=0,
                          bool substituteTemplateArguments=false,
                          _str actualFunctionArguments="")
{
   C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS args;
   args.filterFunctionSignatures= filterFunctionSignatures;
   args.functionArguments = actualFunctionArguments;
   args.numFunctionArguments = min_args;
   args.functionArgumentsFilename = "";
   args.functionArgumentsLine = 1;
   args.functionArgumentsPos = 0;
   if (_isEditorCtl()) {
      args.functionArgumentsFilename = p_buf_name;
      args.functionArgumentsLine = p_RLine;
      args.functionArgumentsPos = _QROffset();
   }
   return _c_get_return_type_of_symbol(errorArgs, 
                                       tag_files, 
                                       symbol, 
                                       search_class_name, 
                                       isjava, 
                                       filter_flags, 
                                       context_flags, 
                                       maybe_class_name, 
                                       substituteTemplateArguments, 
                                       args, 
                                       rt, 
                                       visited, 
                                       depth);
}

/**
 * Utility function for retrieving the return type of the given symbol.
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs                    refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files                    list of extension specific tag files
 * @param symbol                       name of symbol having given return type
 * @param search_class_name            class context to evaluate return type relative to
 * @param min_args                     minimum number of arguments for function, used
 *                                     to resolve overloading.
 * @param isjava                       Is this Java, JavaScript, C# or similar?
 * @param filter_flags                 bitset of VS_TAGFILTER_*, allows us to search only
 *                                     certain items in the database (e.g. functions only)
 * @param maybe_class_name             Could the symbol be a class name, for example
 *                                     C++ syntax of BaseObject::method, BaseObject might
 *                                     be a class name.
 * @param rt                           (reference) set to return type information
 * @param visited                      (reference) have we evalued this return type before?
 * @param depth                        depth of recursion (for handling typedefs)
 * @param context_flags                bitset of VS_TAGCONTEXT_* 
 * @param substituteTemplateArguments  substitute template arguments? 
 * @param actualFunctionArguments      (optional, default null) information about 
 *                                     actual function arguments for this symbol
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _c_get_return_type_of_symbol(_str(&errorArgs)[], 
                                 typeless tag_files,
                                 _str symbol, 
                                 _str search_class_name,
                                 bool isjava, 
                                 SETagFilterFlags filter_flags,
                                 SETagContextFlags context_flags, 
                                 bool maybe_class_name,
                                 bool substituteTemplateArguments,
                                 C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS actualFunctionArguments,
                                 struct VS_TAG_RETURN_TYPE& rt, 
                                 VS_TAG_RETURN_TYPE(&visited):[]=null, 
                                 int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_get_return_type_of_symbol: =======================================");
      isay(depth,"_c_get_return_type_of_symbol: symbol="symbol" class="search_class_name);
      tag_return_type_dump(rt, "_c_get_return_type_of_symbol", depth);
      if (_isEditorCtl()) {
         isay(depth, "_c_get_return_type_of_symbol: p_buf_name="p_buf_name);
         isay(depth, "_c_get_return_type_of_symbol: p_RLine="p_RLine);
      }
   }

   if (depth > 100) {
      if (_chdebug) {
         isay(depth, "_c_get_return_type_of_symbol: recursion too deep");
      }
      errorArgs[1] = symbol;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
   }

   // filter out mutual recursion
   current_scope := _c_get_current_scope_signature(visited, depth);
   input_args := "get;"symbol";"search_class_name";"current_scope";"tag_return_type_string(rt)";"(actualFunctionArguments!=null? actualFunctionArguments.numFunctionArguments:0)";"isjava";"filter_flags";"maybe_class_name";"(actualFunctionArguments!=null?actualFunctionArguments.filterFunctionSignatures:false)";"substituteTemplateArguments";"p_buf_name';'(actualFunctionArguments!=null? actualFunctionArguments.functionArguments : "");
   status := _CodeHelpCheckVisited(input_args, "_c_get_return_type_of_symbol", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // open the expected file in a temp view
   orig_search_file := p_buf_name;
   search_file := rt.filename;
   if (search_file == "" && rt.return_type == "") {
      search_file = p_buf_name;
   }
   temp_view_id := 0;
   orig_view_id := 0;
   inmem := false;
   temp_view_status := -1;
   if (rt.filename != "" && rt.line_number != 0) {
      if (_chdebug) {
         isay(depth, "_c_get_return_type_of_symbol: rt.filename="rt.filename" rt.line_number="rt.line_number);
      }
      lang := _Filename2LangId(rt.filename);
      if (lang!="xml" && !_QBinaryLoadTagsSupported(rt.filename)) {
         temp_view_status = _open_temp_view(rt.filename,temp_view_id,orig_view_id,"",inmem,false,true);
         if (!temp_view_status) {
            if (rt.line_number > 0) {
               p_RLine = rt.line_number;
               _first_non_blank();
            }
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_push_context();
            _UpdateContextAndTokens(true);
            // DJB 07-18-2006
            // Update the list of local variables if we are
            // not specifically searching in a class scope
            if (search_class_name=="") {
               _UpdateLocals(true);
            }
         }
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   save_pos(auto orig_pos);

   // initialize c_return_flags
   rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                        VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                        VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY|
                        VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                        VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                        VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY|
                        VSCODEHELP_RETURN_TYPE_ARRAY|
                        VSCODEHELP_RETURN_TYPE_HASHTABLE|
                        VSCODEHELP_RETURN_TYPE_HASHTABLE2
                       );
   if (search_class_name == "::") {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
      search_class_name = "";
   }

   // get the current class from the context
   context_id := tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                         auto cur_type_name,auto cur_type_id,
                                         auto cur_class_name,auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);
   if (_chdebug) {
      isay(depth, "_c_get_return_type_of_symbol: cur_tag_name="cur_tag_name);
      isay(depth, "_c_get_return_type_of_symbol: cur_type_name="cur_type_name);
      isay(depth, "_c_get_return_type_of_symbol: cur_class_name="cur_class_name);
      isay(depth, "_c_get_return_type_of_symbol: cur_class_only="cur_class_only);
      isay(depth, "_c_get_return_type_of_symbol: cur_package_name="cur_package_name);
   }
   if ( context_id > 0 ) {
      cur_seekpos := _QROffset();
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, auto start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, auto scope_seekpos);
      if (cur_seekpos >= start_seekpos && cur_seekpos < scope_seekpos) {
         _GoToROffset(scope_seekpos);
      }
   }

   // evaluate the scope of this context so that cur_class_name is qualified.
   parsed_cur_class_name := false;
   if (cur_class_name != "" && !maybe_class_name && 
       !_LanguageInheritsFrom("java") &&
       !(cur_tag_flags & SE_TAG_FLAG_INCLASS) &&
       !(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
       !(rt.return_flags & VSCODEHELP_RETURN_TYPE_INCLASS_ONLY)) {
      VS_TAG_RETURN_TYPE scope_rt;
      tag_return_type_init(scope_rt);
      if (!_c_parse_return_type(errorArgs, tag_files,
                                cur_tag_name, search_class_name,
                                p_buf_name, cur_class_name,
                                isjava, scope_rt, visited, depth+1)) {
         cur_class_name = scope_rt.return_type;
         parsed_cur_class_name = true;
      }
   }

   // attempt to resolve the class name to a package
   // need this for C++ namespaces
   qualified_name := "";
   tag_split_class_name(cur_class_name,auto inner_name,auto outer_name);
   if (!parsed_cur_class_name && !(cur_tag_flags & SE_TAG_FLAG_INCLASS) &&
       !tag_qualify_symbol_name(qualified_name,
                                inner_name, outer_name,
                                p_buf_name, tag_files,
                                true, visited, depth+1)) {
      cur_class_name=qualified_name;
   } else {
      qualified_name=cur_class_name;
   }
   if (_chdebug) {
      isay(depth, "_c_get_return_type_of_symbol: H"__LINE__" qualified_name="qualified_name);
      isay(depth, "_c_get_return_type_of_symbol: H"__LINE__" cur_class_name="cur_class_name);
   }

   // special case keyword 'this'
   if (symbol :== "this" && !(cur_tag_flags & SE_TAG_FLAG_STATIC) && cur_class_name!="") {
      if (search_class_name :== "" && context_id > 0) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         if (cur_tag_flags & SE_TAG_FLAG_CONST) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (cur_tag_flags & SE_TAG_FLAG_VOLATILE) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         // revert to cur_class_name if we could not qualify class name
         if (qualified_name=="" || qualified_name==inner_name) {
            rt.return_type = cur_class_name;
         } else {
            rt.return_type = qualified_name;
         }
         this_is_reference := (_LanguageInheritsFrom("groovy") ||
                               _LanguageInheritsFrom("js") || 
                               _LanguageInheritsFrom("as") || 
                               _LanguageInheritsFrom("e") || 
                               _LanguageInheritsFrom("d") ||
                               _LanguageInheritsFrom("lua") ||
                               _LanguageInheritsFrom("vera") ||
                               _LanguageInheritsFrom("systemverilog")); 
         rt.pointer_count = (isjava || this_is_reference )? 0 : 1;

         // use the heavy artillery to compute this function's class
         VS_TAG_RETURN_TYPE this_rt = rt;
         status = _c_parse_return_type(errorArgs, tag_files, symbol,
                                       search_class_name, p_buf_name,
                                       rt.return_type, isjava,
                                       this_rt, visited, depth+1);
         if (!status) {
            rt = this_rt;
            // if the return type matches the current class,
            // allow private access
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            if (rt.return_type == cur_class_name) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            }
         }
         if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
            visited:[input_args]=rt;
         } else if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
         }

         // close the temp view
         restore_pos(orig_pos);
         if (temp_view_status == 0) {
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_pop_context();
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
         }
         return status;

      } else if (isjava && search_class_name != "") {
         rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                              VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                              VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY|
                              VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                              VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY|
                              VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                              VSCODEHELP_RETURN_TYPE_ARRAY|
                              VSCODEHELP_RETURN_TYPE_HASHTABLE|
                              VSCODEHELP_RETURN_TYPE_HASHTABLE2
                             );
         rt.return_type = search_class_name;
         rt.pointer_count = 0;
         if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
            visited:[input_args]=rt;
         } else if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
         }

         // close the temp view
         restore_pos(orig_pos);
         if (temp_view_status == 0) {
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_pop_context();
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
         }
         return 0;
      }
   }

   // special case keyword 'this'
   if (symbol :== "this" && context_id > 0 && !(cur_tag_flags & SE_TAG_FLAG_STATIC) && 
       (cur_type_name=="closure" || cur_type_name=="subfunc" || cur_type_name=="subproc")) {
      outer_id := context_id;
      while ( outer_id > 0 ) {
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, outer_id);
         if ( outer_id <= 0 ) break;
         tag_get_context_browse_info(outer_id, auto outer_cm);
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         if (outer_cm.flags & SE_TAG_FLAG_CONST) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (outer_cm.flags & SE_TAG_FLAG_VOLATILE) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         // revert to cur_class_name if we could not qualify class name
         rt.return_type = outer_cm.class_name;
         this_is_reference := (_LanguageInheritsFrom("groovy") ||
                               _LanguageInheritsFrom("js") || 
                               _LanguageInheritsFrom("as") || 
                               _LanguageInheritsFrom("e") || 
                               _LanguageInheritsFrom("d") ||
                               _LanguageInheritsFrom("lua") ||
                               _LanguageInheritsFrom("vera") ||
                               _LanguageInheritsFrom("systemverilog")); 
         rt.pointer_count = (isjava || this_is_reference )? 0 : 1;

         // use the heavy artillery to compute this function's class
         VS_TAG_RETURN_TYPE this_rt = rt;
         status = _c_parse_return_type(errorArgs, tag_files, symbol,
                                       search_class_name, p_buf_name,
                                       rt.return_type, isjava,
                                       this_rt, visited, depth+1);
         if (!status) {
            rt = this_rt;
            // if the return type matches the current class,
            // allow private access
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            if (rt.return_type == cur_class_name) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            }
         }
         if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
            visited:[input_args]=rt;
         } else if (status == TAGGING_TIMEOUT_RC) {
            visited._deleteel(input_args);
         }

         // close the temp view
         restore_pos(orig_pos);
         if (temp_view_status == 0) {
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_pop_context();
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
         }
         return status;
      }
   }

   //tag_return_type_dump(rt, "_c_get_return_type_of (BEFORE)", depth);
   status = _c_find_return_type_of(errorArgs, 
                                   tag_files,
                                   symbol, 
                                   search_class_name, 
                                   search_file,
                                   cur_class_name, 
                                   isjava, 
                                   maybe_class_name,
                                   actualFunctionArguments,
                                   filter_flags,
                                   context_flags,
                                   rt, 
                                   visited, 
                                   depth+1);
   if (_chdebug) {
      isay(depth, "_c_get_return_type_of_symbol: HERE"__LINE__" status="status);
      tag_return_type_dump(rt,"_c_get_return_type_of_symbol: HERE"__LINE__" returns", depth);
   }

   if (status < 0 && maybe_class_name && 
       (filter_flags & SE_TAG_FILTER_ANY_DATA) && 
       (filter_flags & SE_TAG_FILTER_ANY_STRUCT)) {
      // If we have a variable with the same name as a class we are looking for,
      // let's look again without allowing variables to match.
      status = _c_find_return_type_of(errorArgs, 
                                      tag_files,
                                      symbol, 
                                      search_class_name, 
                                      search_file,
                                      cur_class_name, 
                                      isjava, 
                                      maybe_class_name, 
                                      null,
                                      (filter_flags & ~SE_TAG_FILTER_ANY_DATA),
                                      (context_flags & ~SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE),
                                      rt, 
                                      visited, 
                                      depth+1); 
      if (_chdebug) {
         isay(depth, "_c_get_return_type_of_symbol: HERE"__LINE__" status="status);
         tag_return_type_dump(rt,"_c_get_return_type_of_symbol: RETRY WITH NO DATA returns", depth);
      }
   }

   // close the temp view
   restore_pos(orig_pos);
   if (temp_view_status == 0) {
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      _UpdateContextAndTokens(true);
      _UpdateLocals(true);
   }

   // maybe have to substitute template arguments now
   if (status >= 0 && substituteTemplateArguments) {
      do {
         if (!rt.istemplate) break;
         if (rt.return_type == "") break;
         tag_get_info_from_return_type(rt, auto rt_cm);
         if (!(rt_cm.flags & SE_TAG_FLAG_TEMPLATE)) break;
         if (rt_cm.template_args == "") break;
         if (!rt.template_types._isempty()) break;

         // open the class definition in a temporary view to evaluate default
         // template arguments in the context in which they are declared
         temp_view_status = -1;
         rt_filename := rt_cm.file_name;
         if (rt_filename == "") rt_filename = rt.filename;
         rt_linenumber := rt_cm.line_no;
         if (rt_linenumber <= 1) rt_linenumber = rt.line_number;
         if (rt_filename != "") {
            lang := rt_cm.language;
            if (lang != "") lang = _Filename2LangId(rt.filename);
            if (lang != "xml" && !_QBinaryLoadTagsSupported(rt_filename)) {
               temp_view_status = _open_temp_view(rt_filename,temp_view_id,orig_view_id,"",inmem,false,true);
               if (!temp_view_status) {
                  if (rt_linenumber > 0) {
                     p_RLine = rt_linenumber;
                     _first_non_blank();
                  }
                  _UpdateContextAndTokens(true);
                  _UpdateLocals(true);
               }
            }
         }

         // now substitute the template arguments
         rt.istemplate = true;
         rt.isvariadic = false;
         if (_chdebug) {
            isay(depth, "_c_get_return_type_of_symbol: SUBSTITUTE TEMPLATE PARAMETERS, class="rt.return_type", args="rt_cm.template_args);
         }
         _str default_template_parms[];
         for (i:=0; i<rt.template_names._length(); i++) {
            default_template_parms[i] = "";
         }
         status = _c_substitute_template_args(rt.return_type, 
                                              rt_filename, isjava, 
                                              default_template_parms,
                                              rt_cm.template_args,
                                              rt.template_args,
                                              rt.template_names,
                                              rt.template_types,
                                              rt.isvariadic,
                                              rt.return_type,
                                              rt_filename,
                                              tag_files,
                                              visited,depth+1);
         if (_chdebug) {
            tag_return_type_dump(rt, "_c_get_return_type_of_symbol: AFTER SUBSTITUTE TEMPLATE ARGS", depth);
         }

         // close the temp view
         restore_pos(orig_pos);
         if (temp_view_status == 0) {
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContextAndTokens(true);
            _UpdateLocals(true);
         }
      } while (false);
   }

   // check for error condition
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   } else if (status == TAGGING_TIMEOUT_RC) {
      visited._deleteel(input_args);
   }
   return status;
}
/**
 * Utility function for searching the current context and tag files
 * for symbols matching the given symbol and search class, filtering
 * based on the filter_flags and toy_return_flags.  The number of
 * matches is returned and can be obtained using TAGSDB function
 * tag_get_match_browse_info(...).
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param filter_flags        bitset of VS_TAGFILTER_*, allows us to search only
 *                            certain items in the database (e.g. functions only)
 * @param rt                  return type information
 *
 * @return 0 on success,
 *         < 0 on other error (normal slickedit RC)
 */
static int _c_find_return_type_of(_str (&errorArgs)[], 
                                  typeless tag_files,
                                  _str symbol, 
                                  _str search_class_name,
                                  _str search_file, 
                                  _str cur_class_name,
                                  bool isjava, 
                                  bool maybe_class_name,
                                  C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS actualFunctionArguments,
                                  SETagFilterFlags filter_flags, 
                                  SETagContextFlags context_filter_flags,
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0) 
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_find_return_type_of(symbol="symbol", search_class="search_class_name", cur_class="cur_class_name")");
      tag_return_type_dump(rt, "_c_find_return_type_of", depth);
      if (_isEditorCtl()) {
         isay(depth, "_c_find_return_type_of: p_buf_name="p_buf_name);
         isay(depth, "_c_find_return_type_of: p_RLine="p_RLine);
         isay(depth, "_c_find_return_type_of: search_file="search_file);
      }
   }

   // filter out mutual recursion
   current_scope := _c_get_current_scope_signature(visited, depth);
   input_args := "match;"symbol";"search_class_name";"search_file";"cur_class_name";"current_scope";"(actualFunctionArguments!=null? actualFunctionArguments.numFunctionArguments:0)";"isjava";"maybe_class_name";"filter_flags";"(actualFunctionArguments!=null? actualFunctionArguments.filterFunctionSignatures:false)";"tag_return_type_string(rt)";"(actualFunctionArguments!=null? actualFunctionArguments.functionArguments : "");
   status := _CodeHelpCheckVisited(input_args, "_c_find_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // Attempt to qualify symbols to their appropriate package for Java
   if (/*isjava &&*/ search_class_name=="" && !tag_check_for_class(symbol, cur_class_name, true, tag_files, visited, depth+1)) {
      junk := "";
      tag_qualify_symbol_name(search_class_name,
                              symbol, cur_class_name,
                              search_file, tag_files,
                              true, visited, depth+1);
      // This fix is harmless and only exists to work around a bug in 21.0.x that is fixed in 22.
      tag_split_class_name(search_class_name, junk, auto just_outer_name, true);
      tag_split_class_name(search_class_name, junk, search_class_name, false);
      if (length(just_outer_name) > length(search_class_name)) search_class_name=just_outer_name;
      if (_chdebug) {
         isay(depth, "_c_find_return_type_of: qualified search_class_name="search_class_name);
      }
   }
   //say("2 before previous_id="symbol" match_class="search_class_name);

   // try to find match for "symbol" within context, watch for
   // C++ global designator (leading ::)
   i := num_matches := 0;
   tag_clear_matches();
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      if (_chdebug) {
         isay(depth,"_c_find_return_type_of: matching globals");
      }
      status = tag_list_context_globals(0, 0, symbol, true, tag_files, filter_flags,
                                        SE_TAG_CONTEXT_ONLY_NON_STATIC,
                                        num_matches, def_tag_max_function_help_protos, 
                                        true, true, visited, depth+1);
   } else {
      if (_chdebug) {
         isay(depth,"_c_find_return_type_of: matching class symbols, search_class="search_class_name" symbol="symbol);
         tag_dump_filter_flags(filter_flags, "_c_find_return_type_of: filter_flags", depth);
      }
      context_flags := SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_ANONYMOUS;
      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags,context_flags);
      strict := (rt.return_flags & VSCODEHELP_RETURN_TYPE_INCLASS_ONLY)? true:false;
      if (strict) context_flags |= SE_TAG_CONTEXT_ONLY_INCLASS;
      if (pos(search_class_name, cur_class_name)==1 &&
          substr(cur_class_name, length(search_class_name)+1, 1) == ":") {
         context_flags |= SE_TAG_CONTEXT_ALLOW_PRIVATE;
      }
      if (rt.istemplate && !(filter_flags & ~SE_TAG_FILTER_ANY_STRUCT)) {
         context_flags |= SE_TAG_CONTEXT_ONLY_TEMPLATES;
      }
      context_list_flags := (strict)? SE_TAG_CONTEXT_ANYTHING : SE_TAG_CONTEXT_FIND_LENIENT;
      if (_chdebug) {
         isay(depth, "_c_find_return_type_of: calling tag_list_symbols_in_context, return_type="rt.return_type" search_class="search_class_name", istemplate="rt.istemplate);
      }
      // Need these flags in order to find using statements and typedefs in STL classes
      filter_flags  |= SE_TAG_FILTER_INCLUDE;
      filter_flags  |= SE_TAG_FILTER_TYPEDEF;
      context_flags |= SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE;
      if (_chdebug) {
         tag_dump_filter_flags(filter_flags, "_c_find_return_type_of: filter_flags", depth);
         tag_dump_context_flags(context_flags|context_list_flags, "_c_find_return_type_of: context_flags", depth);
      }
      // search for the symbol (first attempt is not lenient)
      if (status != TAGGING_TIMEOUT_RC && num_matches == 0 && !strict) {
         status = tag_list_symbols_in_context(symbol, search_class_name, 0, 0, 
                                              tag_files, ""/*search_file*/, 
                                              num_matches, def_tag_max_function_help_protos, 
                                              filter_flags, context_flags | context_filter_flags,
                                              true, true, visited, depth+1, rt.template_args);
      }

      // if we didn't have a search class, try again using cur_class_name
      if (status != TAGGING_TIMEOUT_RC && num_matches == 0 && 
          search_class_name != cur_class_name && 
          (search_class_name=="" || rt.return_type=="") &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {
         if (_chdebug) {
            isay(depth, "_c_find_return_type_of: trying from cur_class="cur_class_name);
         }
         tag_clear_matches();
         alt_context_flags := context_flags | context_filter_flags | context_list_flags;
         alt_context_flags &= ~SE_TAG_CONTEXT_ONLY_INCLASS;
         alt_context_flags &= ~SE_TAG_CONTEXT_FIND_LENIENT;
         alt_context_flags &= ~SE_TAG_CONTEXT_ONLY_TEMPLATES;
         status = tag_list_symbols_in_context(symbol, cur_class_name, 0, 0, 
                                              tag_files, ""/*search_file*/, 
                                              num_matches, def_tag_max_function_help_protos, 
                                              filter_flags, alt_context_flags,
                                              true, true, visited, depth+1);
      } else if (status != TAGGING_TIMEOUT_RC && num_matches == 0 && pos(VS_TAGSEPARATOR_package, search_class_name)) {
         if (_chdebug) {
            isay(depth, "_c_find_return_type_of: trying list_symbols_in_context="search_class_name);
         }
         tag_clear_matches();
         alt_context_flags := context_flags | context_filter_flags | context_list_flags;
         alt_context_flags &= ~SE_TAG_CONTEXT_ONLY_INCLASS;
         status = tag_list_symbols_in_context(symbol, search_class_name, 0, 0, 
                                              tag_files, ""/*search_file*/, 
                                              num_matches, def_tag_max_function_help_protos, 
                                              filter_flags, alt_context_flags, 
                                              true, true, visited, depth+1, rt.template_args);
      }
      // try language-specific find-context tags
      if (_isEditorCtl() && status != TAGGING_TIMEOUT_RC && num_matches==0) {
         if (_chdebug) {
            isay(depth, "_c_find_return_type_of: trying language specific find context tags");
            isay(depth, "_c_find_return_type_of: search_class_name="search_class_name);
            isay(depth, "_c_find_return_type_of: cur_class_name="cur_class_name);
         }
         tag_clear_matches();
         find_prefixexp := "";
         if (search_class_name != "" && search_class_name != cur_class_name) {
            find_prefixexp = search_class_name:+".";
         }
         status = _Embeddedfind_context_tags(errorArgs, 
                                             find_prefixexp,
                                             symbol, 
                                             (int)_QROffset(), 0, "", 
                                             false, def_tag_max_function_help_protos, 
                                             true, true, 
                                             filter_flags, context_flags|context_filter_flags|context_list_flags,
                                             visited, depth+1);
      }
   }

   // check for error condition
   if (_chdebug) {
      isay(depth,"_c_find_return_type_of: num_matches="num_matches" status="status);
   }
   if (num_matches < 0) {
      return num_matches;
   }
   if (status < 0 && num_matches == 0) {
      if (status == VSCODEHELPRC_BUILTIN_TYPE) {
         visited:[input_args]=rt;
      } else if (status == TAGGING_TIMEOUT_RC) {
         visited._deleteel(input_args);
      }
      return status;
   }

   // resolve the type of the matches
   rt.taginfo = "";
   rt.filename = "";
   rt.line_number = 0;
   status = _c_get_type_of_matches(errorArgs, 
                                   tag_files, 
                                   symbol,
                                   search_class_name, 
                                   cur_class_name,
                                   isjava, 
                                   maybe_class_name,
                                   actualFunctionArguments,
                                   rt, 
                                   visited, 
                                   depth+1);

   if (_chdebug) {
      tag_return_type_dump(rt,"_c_find_return_type_of(AFTER)",depth);
   }
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   } else if (status == TAGGING_TIMEOUT_RC) {
      visited._deleteel(input_args);
   }
   return status;
}
/**
 * Utility function for evaluating the return types of a match set
 * for a given symbol in order to resolve function overloading and
 * come to a consensus on the return type of the given symbol.
 * Returns the class name of the match, depth of pointer indirection
 * in return type, return type flags, and tag information for match.
 * If the given symbol is overloaded and returns different types,
 * this may return an error if it cannot resolve the overloading.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param cur_class_name      current class context (from tag_current_context)
 * @param min_args            minimum number of arguments for function, used
 *                            to resolve overloading.
 * @param isjava              Is this Java, JavaScript or similar lang?
 * @param maybe_class_name    Could the symbol be a class name, for example
 *                            C++ syntax of BaseObject::method, BaseObject might
 *                            be a class name.
 * @param rt                  (reference) set to return type (result)
 * @param visited             (reference) used to cache results and avoid recursion
 * @param depth               used to avoid recursion
 *
 * @return int
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _c_get_type_of_matches(_str (&errorArgs)[], 
                                  typeless tag_files,
                                  _str symbol, 
                                  _str search_class_name,
                                  _str cur_class_name, 
                                  bool isjava, 
                                  bool maybe_class_name,
                                  C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS actualFunctionArguments,
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_get_type_of_matches: ===================================================");
      isay(depth,"_c_get_type_of_matches(symbol="symbol", search_class="search_class_name", cur_class="cur_class_name")");
      tag_return_type_dump(rt, "_c_get_type_of_matches", depth);
      if (_isEditorCtl()) {
         isay(depth, "_c_get_type_of_matches: p_buf_name="p_buf_name);
         isay(depth, "_c_get_type_of_matches: p_RLine="p_RLine);
      }
   }

   // used for going through match list
   VS_TAG_BROWSE_INFO cm;
   i := 0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // remove duplicate matches
   tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false,
                                       filterDuplicateGlobalVars:false,
                                       filterDuplicateClasses:true,
                                       filterAllImports:false,
                                       filterDuplicateDefinitions:true,
                                       filterAllTagMatchesInContext:false,
                                       matchExact:"",
                                       (actualFunctionArguments!=null? actualFunctionArguments.filterFunctionSignatures:false),
                                       visited,depth+1,
                                       filterAnonymousClasses:false,
                                       filterBinaryLoadedTags:false);

   // filter out matches based on number of arguments
   VS_TAG_BROWSE_INFO matchlist[];
   min_args := (actualFunctionArguments!=null? actualFunctionArguments.numFunctionArguments:0);
   check_args := true;
   have_class_type := false;
   orig_file := (_isEditorCtl()? p_buf_name : rt.filename);
   num_matches := tag_get_num_of_matches();
   if (_chdebug) {
      isay(depth,"_c_get_type_of_matches: num_matches="num_matches);
   }
   for (;;) {
      for (i=1; i<=num_matches; i++) {
         tag_get_match_info(i,cm);
         if (_chdebug) {
            tag_browse_info_dump(cm, "_c_get_type_of_matches: i=":+i, depth);
         }
         // check that number of argument matches.
         if (check_args && num_matches>1 && tag_tree_type_is_func(cm.type_name) &&
             !(cm.flags & SE_TAG_FLAG_OPERATOR) && !(cm.flags & SE_TAG_FLAG_MAYBE_VAR)) {
            num_args := 0;
            def_args := 0;
            arg_pos := 0;
            for (;;) {
               parm := "";
               tag_get_next_argument(cm.arguments, arg_pos, parm);
               if (parm == "") {
                  break;
               }
               if (pos("=", parm)) {
                  def_args++;
               }
               if (parm :== "...") {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("c") && pos("...",parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("java") && pos("...",parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("d") && pos("...",parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("lua") && pos("...",parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("cs") && pos("[",parm) && !pos(",",substr(cm.arguments,arg_pos))) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom("cs") && substr(parm,1,7):=="params ") {
                  num_args = min_args;
                  break;
               }
               num_args++;
            }
            // this prototype doesn't take enough arguments?
            //say("_c_get_type_of_matches: num="num_args" min="min_args);
            if (num_args < min_args) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: num_args="num_args" min_args="min_args);
               }
               continue;
            }
            // this prototype requires too many arguments?
            if (num_args - def_args > min_args) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: num_args="num_args" min_args="min_args" def_args="def_args);
               }
               continue;
            }
         } else if (cm.type_name=="typedef") {
            // skip over recursive typedefs
            p1 := p2 := "";
            parse cm.return_type with p1 " " p2;
            if (symbol==cm.return_type || symbol==p2) {
               continue;
            }
         }
         // As it turns out, in C++, you can inherit operators
         //if ((tag_flags & SE_TAG_FLAG_OPERATOR) && class_name :!= search_class_name) {
         //   continue;
         //}
         //say("WHERE proc_name="proc_name" class="class_name" return_type="return_type);
         if (rt.taginfo == "") {
            rt.taginfo = tag_compose_tag_browse_info(cm);
            rt.filename = cm.file_name;
            rt.line_number = cm.line_no;
            //say("MATCH TAG="match_tag);
         }
         if (cm.type_name == "friend") {
            continue;
         }
         if ((cm.flags & SE_TAG_FLAG_FORWARD) && (matchlist._length() > 0 || i+1 < num_matches)) {
            continue;
         }
         if ( cm.language != null && cm.language != "" && 
              cm.language != "binary" && cm.language != "tagdoc" && cm.language != "xmldoc" &&
              !_QBinaryLoadTagsSupported(cm.file_name) && 
              !_LanguageInheritsFrom(cm.language) && 
              (!_isEditorCtl() || !_LanguageReferencedIn(p_LangId, cm.language)) ) {
            if ( _chdebug ) {
               isay(depth, "_c_get_type_of_matches: SKIP symbol from wrong language");
            }
            continue;
         }
         if (tag_tree_type_is_func(cm.type_name) && (cm.flags & SE_TAG_FLAG_CONSTRUCTOR) && pos(cm.member_name, cm.class_name)) {
            cm.return_type = cm.class_name;
         }
         if (tag_tree_type_is_class(cm.type_name) || cm.type_name=="enum") {
            cm.return_type = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true, false, false, visited, depth+1);
            if (cm.return_type=="") cm.return_type = cm.member_name;
            have_class_type = true;
         }
         // construct return type for namespaces to match the actual namespace
         // declaration.  make sure that you leave namespace aliases intact
         if (tag_tree_type_is_package(cm.type_name) && (cm.return_type=="") &&
             ((cm.class_name==rt.return_type) || (rt.return_type=="") || (rt.return_type=="::"))) {
            cm.return_type = cm.member_name;
            if (cm.class_name != "") {
               cm.return_type = cm.class_name:+VS_TAGSEPARATOR_package:+cm.member_name;
            }
            // take a huge shortcut for namespaces "std" and "boost"
            if (i==1 && !isjava && _LanguageInheritsFrom("c") && rt.return_type=="" && !rt.istemplate) {
               if (_c_is_stl_class(cm.member_name:+VS_TAGSEPARATOR_package)) {
                  if (cm.class_name=="" && cm.member_name == symbol) {
                     rt.return_type=symbol;
                     rt.pointer_count=0;
                     rt.istemplate=false;
                     rt.isvariadic=false;
                     rt.filename = cm.file_name;
                     rt.line_number = cm.line_no;
                     rt.taginfo=symbol"(package)";
                     rt.template_args._makeempty();
                     rt.template_names._makeempty();
                     rt.template_types._makeempty();
                     return 0;
                  }
               }
            }
            if (i==1 && !isjava && _LanguageInheritsFrom("c") && rt.return_type=="boost" && !rt.istemplate) {
               if (cm.member_name=="container" || cm.member_name=="detail") {
                  if (cm.class_name=="boost" && cm.member_name == symbol) {
                     rt.return_type=symbol;
                     rt.pointer_count=0;
                     rt.istemplate=false;
                     rt.isvariadic=false;
                     rt.filename = cm.file_name;
                     rt.line_number = cm.line_no;
                     rt.taginfo="boost/"symbol"(package)";
                     rt.template_args._makeempty();
                     rt.template_names._makeempty();
                     rt.template_types._makeempty();
                     return 0;
                  }
               }
            }
         }

         // are we in a class template, trying to evaluate the type of a parameter
         if ((cm.flags & SE_TAG_FLAG_TEMPLATE) && cm.type_name == "param" && cm.return_type=="") {
            if (_LanguageInheritsFrom("cs")) {
               cm.return_type = "object";
            } else if (_LanguageInheritsFrom("java")) {
               cm.return_type = "Object";
            }
         }
         if ((cm.flags & SE_TAG_FLAG_TEMPLATE) && cm.type_name == "param" && 
             (!rt.template_args._indexin(cm.member_name)) &&
             (substr(cm.return_type,1,6) == "class=" || substr(cm.return_type,1,9) == "typename=")) {
            if (_LanguageInheritsFrom("c")) {
               parse cm.return_type with . '=' cm.return_type;
            }
         }

         if (_LanguageInheritsFrom("cs") && cm.type_name=="enum") {
            cm.return_type = cm.member_name;
         } else if (_LanguageInheritsFrom("java") && cm.type_name=="enum") {
            cm.return_type = cm.member_name;
         }

         // if this is *another* local variable, take it and toss out the
         // earlier one (which will be in a more distant scope, thus shadowed)
         if (cm.type_name == "lvar" && cm.return_type != "" && matchlist._length() >= 1) {
            last_match := matchlist[matchlist._length()-1];
            if (last_match.type_name == "lvar" && 
                last_match.member_name == cm.member_name && 
                last_match.class_name == cm.class_name) {
               matchlist._deleteel(matchlist._length()-1);
            }
         }

         if (cm.return_type != "") {
            matchlist :+= cm;
         } else {
            //num_matches--;
         }
      }
      // break out of loop if we found something or check args is off
      if (min_args>0 || matchlist._length()>0 || !check_args) break;
      check_args=false;
   }

   if (_chdebug) {
      isay(depth,"_c_get_type_of_matches: matchlist._length()="matchlist._length());
   }

   // This is the return type is calculated for each iteration
   // and ultimately is the one copied into 'rt'
   VS_TAG_RETURN_TYPE found_rt;
   tag_return_type_init(found_rt);
   // This is the last "successful" return type calculation.
   VS_TAG_RETURN_TYPE match_rt;
   tag_return_type_init(match_rt);

   // for each match in list, (have to do it this way because
   // _c_parse_return_type()) uses the context match set.
   rt.return_type = "";
   int status=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   found_status := 1;
   num_repeats := 0;
   bool found_return_types:[] = null;
   for (i=0; i<matchlist._length(); i++) {

      // get the symbol information
      cm = matchlist[i];
      if (cm == null) continue;

      // check for search timeout
      if (i>0 && _CheckTimeout()) {
         status = found_status = TAGGING_TIMEOUT_RC;
         break;
      }

      tag_return_type_init(found_rt);
      found_rt.template_args  = rt.template_args;
      found_rt.template_names = rt.template_names;
      found_rt.template_types = rt.template_types;
      found_rt.istemplate     = rt.istemplate;
      found_rt.isvariadic     = rt.isvariadic;
      found_rt.filename       = cm.file_name;
      found_rt.line_number    = cm.line_no;
      if (_chdebug) {
         tag_browse_info_dump(cm,"_c_get_type_of_matches: matchlist["i"] (cm.BEFORE)", depth);
         tag_return_type_dump(found_rt,"_c_get_type_of_matches: matchlist["i"] (rt.BEFORE)", depth);
      }
      if ((tag_tree_type_is_package(cm.type_name) || (cm.type_name=="import")) && 
          cm.return_type != "" && cm.return_type != cm.member_name && 
          cm.return_type != cm.class_name:+VS_TAGSEPARATOR_package:+cm.member_name &&
          (cm.return_type != "module" || !(_LanguageInheritsFrom("verilog") || _LanguageInheritsFrom("systemverilog"))) ) {
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches: PACKAGE OR IMPORT, type="cm.type_name);
         }
         // namespace alias
         status = _c_parse_return_type(errorArgs, tag_files, 
                                       cm.member_name, cur_class_name,
                                       cm.file_name, cm.return_type, 
                                       isjava, found_rt, 
                                       visited, depth+1);
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches:: matchlist["i"] MAY BE PACKAGE NAME, return_type="cm.return_type" class="cm.class_name" member="cm.member_name);
         }

      } else if (tag_tree_type_is_class(cm.type_name) || tag_tree_type_is_package(cm.type_name) || cm.type_name=="enum") {
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches:: matchlist["i"] MAY BE CLASS class="cm.class_name" member="cm.member_name);
         }
         found_rt.return_type = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true, true, false, visited, depth+1);
         found_rt.taginfo = tag_compose_tag_browse_info(cm);
         found_rt.filename = cm.file_name;
         found_rt.line_number = cm.line_no;
         if (cm.flags & SE_TAG_FLAG_TEMPLATE) {
            found_rt.istemplate = true;
            found_rt.isvariadic = false;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: WOULD HAVE SUBSTITUTED TEMPLATE PARAMETERS, BUT NOT DOING IT NOW");
            }
            if (false && cm.template_args != "") {
               _str default_template_parms[];
               status = _c_substitute_template_args(found_rt.return_type, 
                                                    cm.file_name, isjava, 
                                                    default_template_parms,
                                                    cm.template_args,
                                                    found_rt.template_args,
                                                    found_rt.template_names,
                                                    found_rt.template_types,
                                                    found_rt.isvariadic,
                                                    found_rt.return_type,
                                                    cm.file_name,
                                                    tag_files,
                                                    visited,depth+1);
               if (_chdebug) {
                  tag_return_type_dump(found_rt, "_c_get_type_of_matches: matchlist["i"] IS TEMPLATE CLASS", depth);
               }
            }
         }
         if ((tag_tree_type_is_class(cm.type_name) || cm.type_name=="enum") && !_LanguageInheritsFrom("lua")) {
            isParentClass := tag_is_parent_class(found_rt.return_type, cur_class_name,
                                                 tag_files, true, false, found_rt.filename, 
                                                 visited, depth+1) != 0;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches:: matchlist["i"] CHECK FOR STATIC ONLY, isParentClass="isParentClass);
            }
            if (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("cs")) {
               /*
                  For Python and C#, whenever the class name is specified, the function

                    baseclass.__init__(

               */
               found_rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches:: matchlist["i"] CHECK FOR STATIC ONLY, PYTHON");
               }
            } else if (_in_function_scope() && !_is_return_type_local(rt) && !isParentClass && 
                       found_rt.return_type != cur_class_name &&
                       cm.type_name != "union" && cm.type_name != "group" && cm.type_name != "interface" && cm.type_name != "enum") {
               found_rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches:: matchlist["i"] CHECK FOR STATIC ONLY, OUTSIDE OF CLASS");
               }
            } else if (isParentClass) {
               found_rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches:: matchlist["i"] CHECK FOR STATIC ONLY, PARENT CLASS");
               }
            } else {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches:: matchlist["i"] CHECK FOR STATIC ONLY, NOT PARENT CLASS");
               }
            }
         }
         status = 0;
      } else {

         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches: HAVE SOMETHING ELSE, type="cm.type_name);
         }

         if (have_class_type && tag_tree_type_is_func(cm.type_name) && (cm.flags & SE_TAG_FLAG_CONSTRUCTOR)) {
            continue;
         }

         // check if we have a template function
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches: is func="tag_tree_type_is_func(cm.type_name));
            isay(depth, "_c_get_type_of_matches: is template="(cm.flags & SE_TAG_FLAG_TEMPLATE));
            isay(depth, "_c_get_type_of_matches: template args="cm.template_args);
            isay(depth, "_c_get_type_of_matches: function args="(actualFunctionArguments!=null? actualFunctionArguments.functionArguments:""));
         }
         inferred_function_template_return_type := false;
         if ( (tag_tree_type_is_func(cm.type_name) || tag_tree_type_is_data(cm.type_name)) && 
              (cm.flags & SE_TAG_FLAG_TEMPLATE) && cm.template_args != "" && 
              cm.arguments != "" && actualFunctionArguments != null && actualFunctionArguments.functionArguments != "") {
            orig_rt := rt;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: HAVE FUNCTION TEMPLATE, args="actualFunctionArguments.functionArguments);
               if (_isEditorCtl()) {
                  isay(depth, "_c_get_type_of_matches: p_buf_name="p_buf_name);
                  isay(depth, "_c_get_type_of_matches: p_RLine="p_RLine);
               }
            }

            // open a temp-view and move to the location of the argument list
            // in order to evaluate the types of the arguments correctly
            save_pos(auto args_orig_pos);
            args_temp_view_id := 0;
            args_orig_view_id := 0;
            args_inmem := false;
            args_temp_view_status := -1;
            if (actualFunctionArguments.functionArgumentsFilename != "") {
               lang := _Filename2LangId(actualFunctionArguments.functionArgumentsFilename);
               if (lang!="xml" && !_QBinaryLoadTagsSupported(actualFunctionArguments.functionArgumentsFilename)) {
                  args_temp_view_status = _open_temp_view(actualFunctionArguments.functionArgumentsFilename,args_temp_view_id,args_orig_view_id,"",args_inmem,false,true);
                  if (!args_temp_view_status) {
                     if (actualFunctionArguments.functionArgumentsLine > 0) {
                        p_RLine = actualFunctionArguments.functionArgumentsLine;
                     }
                     if (actualFunctionArguments.functionArgumentsPos > 0) {
                        _GoToROffset(actualFunctionArguments.functionArgumentsPos);
                     }
                     _UpdateContextAndTokens(true);
                     _UpdateLocals(true);
                  }
               }
            }

            // evalute all of the actual function arguments
            VS_TAG_RETURN_TYPE func_argument_rt[];
            _str func_argument_exprs[];
            _str func_argument_types[];
            arg_pos := 0;
            argument := "";
            while (tag_get_next_argument(actualFunctionArguments.functionArguments, arg_pos, argument) >= 0) {
               //say("cb_next_arg returns "argument);
               func_argument_exprs :+= argument;
               tag_return_type_init(auto argument_rt);
               arg_status := _c_get_type_of_expression(errorArgs, tag_files, symbol, rt.return_type, p_buf_name, 0, argument, argument_rt, visited, depth+1);
               if (arg_status == 0 || arg_status == VSCODEHELPRC_BUILTIN_TYPE) {
                  func_argument_rt    :+= argument_rt;
                  func_argument_types :+= tag_return_type_string(argument_rt);
                  if (_chdebug) {
                     isay(depth, "_c_get_type_of_matches: FUNCTION TEMPLATE CASE: ACTUAL ARGUMENT, expr="argument);
                     tag_return_type_dump(argument_rt, "_c_get_type_of_matches: FUNCTION TEMPLATE CASE: ACTUAL ARGUMENT", depth);
                  }
               } else {
                  func_argument_rt    :+= argument_rt;
                  func_argument_types :+= argument;
               }
            }

            // clean up the argument parsing temp view
            if (args_temp_view_status == 0) {
               _delete_temp_view(args_temp_view_id);
               p_window_id=args_orig_view_id;
               restore_pos(args_orig_pos);
               _UpdateContextAndTokens(true);
               _UpdateLocals(true);
            }

            // get the function's template argument list
            VS_TAG_RETURN_TYPE func_template_types:[];
            _str func_template_args:[];
            _str func_template_names[];
            func_is_variadic_template := false;
            arg_pos = 0;
            arg_name := "";
            tag_get_next_argument(cm.template_args, arg_pos, arg_name);
            while (arg_name !="") {
               arg_default := "";
               parse arg_name with arg_name "=" arg_default;
               arg_value := arg_default;
               if (arg_value=="") {
                  if (arg_default!="") {
                     arg_value=arg_default;
                  } else if (_LanguageInheritsFrom("java")) {
                     arg_value="java.lang.Object";
                  }
               }
               //isay(depth,"_c_get_type_of_matches: %%%%%%%%%%%%%%%%%%%%%%");
               //isay(depth,"_c_get_type_of_matches: "arg_name" --> "arg_value);

               arg_type := "";
               arg_name = strip(arg_name);
               if (pos(":v", arg_name, 1, 'r') == 1) {
                  arg_type = substr(arg_name, 1, pos(''));
                  arg_rest := strip(substr(arg_name, pos('')+1));
                  if (pos("...", arg_rest)) {
                     func_is_variadic_template = true;
                     arg_type :+= "...";
                     arg_rest = substr(arg_rest, 4);
                  }
                  arg_name = arg_rest;
               }

               if (!_inarray(arg_name, func_template_names)) {
                  func_template_names :+= arg_name;
               }
               func_template_args:[arg_name] = arg_value;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: FUNCTION TEMPLATE ARG name="arg_name" default="arg_value);
               }
               tag_get_next_argument(cm.template_args, arg_pos, arg_name);
            }

            // get the function formal parameter list
            _str func_parameter_type_list[];
            VS_TAG_RETURN_TYPE func_parameter_return_types[];
            arg_pos = 0;
            argument = "";
            word_chars := _clex_identifier_chars();
            while (tag_get_next_argument(cm.arguments, arg_pos, argument) >= 0) {
               //say("cb_next_arg returns "argument);
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: FUNCTION TEMPLATE FORMAL PARAMETER="argument);
               }

               func_parameter_name := "";
               func_parameter_type := argument;

               if (pos("^["word_chars"]*([=]?*|)$",argument,1,'r')) {
                  parse argument with argument "=";
                  func_parameter_type = argument;
                  func_parameter_name = argument;
               } else {
                  // parse out the return type of the current parameter
                  pslang := p_LangId;
                  utf8 := p_UTF8;
                  psindex := _FindLanguageCallbackIndex("%s_proc_search",pslang);
                  temp_view_id := 0;
                  orig_view_id := _create_temp_view(temp_view_id);
                  p_UTF8=utf8;
                  _insert_text(argument";");
                  top();
                  pvarname := "";
                  if (index_callable(psindex)) {
                     status=call_index(pvarname,1,pslang,psindex);
                  } else {
                     _SetEditorLanguage(pslang,false);
                     status=_VirtualProcSearch(pvarname, false);
                  }
                  if (status) {
                     // major hack, try again with a faked out argument name
                     top();
                     _delete_text(p_RBufSize);
                     _insert_text(argument" a;");
                     top();
                     if (index_callable(psindex)) {
                        status=call_index(pvarname,1,pslang,psindex);
                     } else {
                        status=_VirtualProcSearch(pvarname, false);
                     }
                     if (substr(pvarname,1,2)!="a(") {
                        status=STRING_NOT_FOUND_RC;
                     }
                  }
                  if (!status) {
                     tag_decompose_tag_browse_info(pvarname, auto pvarInfo);
                     func_parameter_name = pvarInfo.member_name;
                     func_parameter_type = pvarInfo.return_type;
                  } else {
                  }
                  _delete_temp_view(temp_view_id);
                  p_window_id = orig_view_id;
               }

               tag_return_type_init(auto arg_rt);
               arg_rt.template_args = func_template_args;
               arg_rt.template_names = func_template_names;
               for (j := 0; j<func_template_names._length(); j++) {
                  tag_return_type_init(auto fake_template_type);
                  fake_template_type.return_type = func_template_names[j];
                  fake_template_type.taginfo = func_template_names[j];
                  fake_template_type.filename = rt.filename;
                  fake_template_type.line_number = rt.line_number;
                  fake_template_type.return_flags = rt.return_flags;
                  fake_template_type.return_flags |= VSCODEHELP_RETURN_TYPE_IS_FAKE;
                  arg_rt.template_types:[func_template_names[j]] = fake_template_type;
               }
               arg_status := _c_parse_return_type(errorArgs, tag_files, "", rt.return_type, rt.filename, func_parameter_type, isjava, arg_rt, visited, depth+1);
               func_parameter_return_types :+= arg_rt;
               func_parameter_type_list    :+= func_parameter_type;
               if (arg_status == 0 || arg_status == VSCODEHELPRC_BUILTIN_TYPE) {
                  if (_chdebug) {
                     tag_return_type_dump(arg_rt, "_c_get_type_of_matches: FUNCTION TEMPLATE FORMAL ARGUMENT TYPE", depth);
                  }
               }
            }
            
            got_a_template_parameter := false;
            if (_c_is_stl_class(cm.class_name) && 
                (cm.member_name == "make_tuple" || cm.member_name == "tie" || cm.member_name == "forward_as_tuple") && 
                func_template_names._length() >= 1 && func_template_names[0] != "") {

               tag_return_type_init(auto func_rt);
               func_rt.return_type = "std/tuple";
               func_rt.istemplate  = true;
               func_rt.isvariadic  = true;
               func_rt.template_names = func_template_names;
               base_arg_name := func_template_names[0];
               for (j:=0; j<func_argument_types._length(); j++) {
                  variadic_arg_name := (j==0)? base_arg_name : base_arg_name:+"+":+(j+1);
                  func_rt.template_names[j] = variadic_arg_name;
                  func_rt.template_args:[variadic_arg_name]  = func_argument_types[j];
                  if (j < func_argument_rt._length()) {
                     func_rt.template_types:[variadic_arg_name] = func_argument_rt[j];
                  }
                  if (cm.member_name == "tie" || cm.member_name == "forward_as_tuple") {
                     func_rt.template_types:[variadic_arg_name].return_flags |= VSCODEHELP_RETURN_TYPE_REF;
                  }
               }
               rt = func_rt;
               status = 0;
               inferred_function_template_return_type = true;

            } else if (_c_is_stl_class(cm.class_name) && 
                       cm.member_name == "tuple_cat" && 
                       (cm.flags & SE_TAG_FLAG_TEMPLATE) && 
                       func_template_names._length() >= 1) {

                  func_rt  := func_argument_rt[0];
                  num_args := func_rt.template_names._length();
                  base_arg_name := func_template_names[0];
                  if (base_arg_name == null || base_arg_name == "") {
                     if (func_rt.template_names._length() > 0) {
                        base_arg_name = func_rt.template_names[0];
                     } else {
                        base_arg_name = "_Tp";
                     }
                  }
                  for (j:=1; j<func_argument_rt._length(); j++) {
                     arg_rt := func_argument_rt[j];
                     if (arg_rt == null) continue;
                     if (pos("tuple", arg_rt.return_type)) {
                        for (k:=0; k<arg_rt.template_names._length(); k++) {
                           orig_arg_name := arg_rt.template_names[k];
                           variadic_arg_name := base_arg_name:+"+":+(++num_args);
                           func_rt.template_names :+= variadic_arg_name;
                           func_rt.template_args:[variadic_arg_name]  = arg_rt.template_args:[orig_arg_name];
                           func_rt.template_types:[variadic_arg_name] = arg_rt.template_types:[orig_arg_name];
                        }
                     } else {
                        variadic_arg_name := base_arg_name:+"+":+(++num_args);
                        func_rt.template_names :+= variadic_arg_name;
                        func_rt.template_args:[variadic_arg_name] = func_argument_types[j];
                        if (j < func_argument_rt._length()) {
                           func_rt.template_types:[variadic_arg_name] = func_argument_rt[j];
                        }
                     }
                  }
                  rt = func_rt;
                  status = 0;
                  inferred_function_template_return_type = true;

            } else {

               for (j:=0; j<func_parameter_type_list._length() && j<func_argument_types._length(); j++) {
                  if (tag_return_type_infer_template_arguments(func_template_names,
                                                               func_template_args,
                                                               func_template_types,
                                                               func_argument_rt[j],
                                                               func_parameter_return_types[j],
                                                               func_is_variadic_template,
                                                               depth+1)) {
                     got_a_template_parameter = true;
                     if (_chdebug) {
                        foreach (auto a in func_template_names) {
                           isay(depth, "_c_get_type_of_matches: INFERRED arg name="a);
                           if (func_template_args._indexin(a)) {
                              isay(depth, "_c_get_type_of_matches: INFERRED arg type="func_template_args:[a]);
                           }
                           if (func_template_types._indexin(a)) {
                              tag_return_type_dump(func_template_types:[a], "_c_get_type_of_matches: INFERRED arg type:", depth+1);
                           }
                        }
                     }
                  }
               }
            }

            if (got_a_template_parameter) {
               tag_return_type_init(auto func_rt);
               func_rt.template_names = func_template_names;
               func_rt.template_args  = func_template_args;
               func_rt.template_types = func_template_types;
               func_rt.istemplate = true;
               func_rt.isvariadic = func_is_variadic_template;
               tag_return_type_merge_templates(func_rt, found_rt);
               if (_chdebug) {
                  tag_return_type_dump(found_rt, "_c_get_type_of_matches: FUNCTION TEMPLATE (found_rt)", depth);
                  tag_return_type_dump(func_rt, "_c_get_type_of_matches: FUNCTION TEMPLATE (func_rt)", depth);
                  isay(depth, "_c_get_type_of_matches: FUNCTION TEMPLATE trying to parse return type, func_cm.return_type="cm.return_type);
               }
               rt_status := _c_parse_return_type(errorArgs, tag_files, cm.member_name, cm.class_name, p_buf_name, cm.return_type, isjava, func_rt, visited, depth+1);
               if (rt_status == 0 || rt_status == VSCODEHELPRC_BUILTIN_TYPE) {
                  if (_chdebug) {
                     tag_return_type_dump(func_rt, "_c_get_type_of_matches: FUNCTION TEMPLATE RETURN TYPE", depth);
                  }
                  rt = func_rt;
                  status = rt_status;
                  inferred_function_template_return_type = true;
               }
            }
         }

         if (inferred_function_template_return_type) {
            // did you see that?  just above, where we performed a miracle?
            found_rt = rt;

         } else if ((p_LangId == "groovy" || _LanguageInheritsFrom('kotlin')) && _c_is_type_inferred(cm.return_type)) {
            _str return_type;
            parse cm.return_type with . "=" return_type;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: GROOVY inferred case, return_type="cm.return_type);
            }
            status = _c_get_type_of_expression(errorArgs,tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:return_type, 
                                               found_rt, visited, depth+1);
         } else if ( _LanguageInheritsFrom("e") && cm.type_name=="lvar" && 
              (cm.return_type=="auto" || _c_is_type_inferred(cm.return_type))) {
            // Slick-C auto-declared local variable with type of reference parameter
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: Slick-C inferred case, return_type="cm.return_type);
            }
            status = _c_get_type_of_parameter(errorArgs,tag_files,cm,found_rt,visited,depth+1);
            if (status) {
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cur_class_name,
                                             cm.file_name, cm.return_type, 
                                             isjava, found_rt, 
                                             visited, depth+1);
            }
         } else if ( _LanguageInheritsFrom("cs") && cm.type_name=="param" && (cm.return_type=="" || cm.return_type=="var" || cm.return_type == "object") ) {
            // C# closure parameter with type of reference parameter
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: C# closure parameter, return_type="cm.return_type);
            }
            status = _c_get_type_of_parameter(errorArgs,tag_files,cm,found_rt,visited,depth+1);
            if (status) {
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cur_class_name,
                                             cm.file_name, cm.return_type, 
                                             isjava, found_rt, 
                                             visited, depth+1);
            }
         } else if ( _LanguageInheritsFrom("cs") && cm.type_name=="lvar" && (cm.return_type=="out" || cm.return_type=="var")) {
            // C# output parameter with type of reference parameter
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: C# out variable case, return_type="cm.return_type);
            }
            status = _c_get_type_of_parameter(errorArgs,tag_files,cm,found_rt,visited,depth+1);
            if (status) {
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cur_class_name,
                                             cm.file_name, cm.return_type, 
                                             isjava, found_rt, 
                                             visited, depth+1);
            }
         } else if (cm.class_name=="") {
            found_rt.filename = cm.file_name;
            found_rt.line_number = cm.line_no;
            status = _c_parse_return_type(errorArgs, tag_files, 
                                          cm.member_name, cm.class_name,
                                          cm.file_name, cm.return_type, 
                                          isjava, found_rt,
                                          visited, depth+1);
         } else if (cm.type_name=="enumc") {
            found_rt.filename = cm.file_name;
            found_rt.line_number = cm.line_no;
            status = _c_parse_return_type(errorArgs, tag_files, 
                                          cm.member_name, cm.class_name,
                                          cm.file_name, cm.return_type, 
                                          isjava, found_rt,
                                          visited, depth+1);
            if (status < 0) {
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cm.class_name,
                                             cm.file_name, cm.class_name, 
                                             isjava, found_rt,
                                             visited, depth+1);
            }
         } else {
            status = _c_get_inherited_template_args(errorArgs, tag_files, cm.class_name,
                                                    search_class_name, 
                                                    (orig_file != "")? orig_file : cm.file_name,
                                                    found_rt, visited, depth+1);
            if (status >= 0) {
               found_rt.filename = cm.file_name;
               found_rt.line_number = cm.line_no;
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cm.class_name,
                                             cm.file_name, cm.return_type, 
                                             isjava, found_rt,
                                             visited, depth+1);
            }
         }

         // is the return type a builtin that has a boxing conversion?
         if (_c_is_builtin_type(rt.return_type)) {
            box_type := _c_get_boxing_conversion(rt.return_type);
            if (box_type != "") {
               rt.return_type = box_type;
            }
            if (_LanguageInheritsFrom("e")) {
               box_type = _e_get_control_name_type(rt.return_type,symbol);
               if (box_type != "") {
                  rt.return_type = box_type;
               }
            }
         }
         if (found_rt != null) {
            if ((cm.flags & SE_TAG_FLAG_TEMPLATE) && cm.type_name != "param") {
               found_rt.istemplate = true;
            }
            found_rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            found_rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            found_rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         }
      }
      if (_chdebug) {
         isay(depth, "_c_get_type_of_matches: matchlist["i"] status="status);
         tag_return_type_dump(found_rt, "_c_get_type_of_matches matchlist["i"] found_rt.AFTER", depth);
      }
      // watch out for case where we ran out of energy
      if (status == TAGGING_TIMEOUT_RC) {
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches: TIMEOUT");
         }
         found_status = status;
         break;
      }
      // skip over overloaded return types we can't handle
      if (status<0 && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         if (found_status > 0) found_status = status;
         found_rt=match_rt;
         continue;
      }
      // previous overload failed, but now we have a good one
      found_status = 0;
      if (found_rt.return_type != "") {

         if (rt.return_type=="") {
            match_rt=found_rt;
            rt.return_type = found_rt.return_type;
            //_message_box("new match type="rt.return_type);
            rt.return_flags = found_rt.return_flags;
            rt.pointer_count = found_rt.pointer_count;
            rt.alt_return_types = found_rt.alt_return_types;
            //say("RETURN, pointer_count="rt.pointer_count" found_pointer_count="found_rt.pointer_count" found_type="found_rt.return_type);
            match_rt.pointer_count = found_rt.pointer_count;

            // If the original type was an import, swap in the tag info for the resolved type
            tag_get_info_from_return_type(found_rt, auto found_cm);
            found_taginfo := found_rt.taginfo;

            // very, very special case for handling the case where a function pointer typedef
            // has a return type which is also a typedef, and the two need to be pasted together
            if ((cm.type_name == "typedef" && cm.arguments != "" && pos("(", cm.return_type)) &&
                (found_cm.type_name == "typedef" && found_cm.arguments == "")) {
               found_cm.member_name = cm.member_name;
               found_cm.arguments = cm.arguments;
               found_taginfo = tag_compose_tag_browse_info(found_cm);
            }
            if (length(found_taginfo) > 0 && (cm.type_name == "import" || found_taginfo != rt.taginfo)) {
               rt.taginfo = found_taginfo;
               rt.filename = found_rt.filename;
               rt.line_number = found_rt.line_number;
            }

         } else {
            // different opinions on static_only or const_only, chose more general
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
            }
            if (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2)) {
               rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2);
               rt.return_flags |= (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2));
            }
            if (rt.return_type :!= found_rt.return_type || match_rt.pointer_count != found_rt.pointer_count) {
               // different return type, this is not good
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches:: matchlist["i"] DIFFERENT MATCH_TYPE="rt.return_type" FOUND_TYPE="found_rt.return_type" pointer="match_rt.pointer_count" found_pointer="found_rt.pointer_count);
               }
               //errorArgs[1] = symbol;
               //return VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
               found_hash_key := tag_return_type_string(found_rt, false);
               if (!found_return_types._indexin(found_hash_key)) {
                  found_return_types:[found_hash_key] = true;
                  rt.alt_return_types[rt.alt_return_types._length()] = found_rt;
                  if (_chdebug) {
                     tag_return_type_dump(rt, "_c_get_type_of_matches DUPLICATE rt.FINAL", depth);
                  }
               }
               continue;
            }
            //say("_c_get_type_of_matches: here");
         }
         // if we have over five matching return types, then call it good
         num_repeats++;
         if (num_repeats>=4) {
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: GOT FOUR IDENTICAL TYPES");
            }
            break;
         }
      }
   }

   if (found_status < 0 && found_status != VSCODEHELPRC_BUILTIN_TYPE) {
      if (_chdebug) {
         isay(depth, "_c_get_type_of_matches: error="status);
      }
      if (status < 0 && errorArgs._length() > 0) return status;
      if (errorArgs._length() == 0) errorArgs[1]=symbol;
      return found_status;
   }


   // transfer template arguments from outer to inner class
   if (_chdebug) {
      tag_return_type_dump(rt, "_c_get_type_of_matches OUT OF LOOP rt", depth);
   }
   rt.istemplate = (found_rt.istemplate || rt.istemplate);
   rt.isvariadic = found_rt.isvariadic;
   rt.template_args  = found_rt.template_args;
   rt.template_names = found_rt.template_names;
   rt.template_types = found_rt.template_types;

   //say("maybe class name, num_matches="num_matches);
   // Java syntax like Class.blah... or C++ style iostream::blah
   if (maybe_class_name && num_matches==0) {
      //if (_chdebug) {
      //   isay(depth, "111 searching for class name, symbol="symbol" class="search_class_name);
      //}
      class_context_flags := SE_TAG_CONTEXT_ANYTHING;
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS);
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_PROTECTED);
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, 
                                  tag_files, "", num_matches, def_tag_max_function_help_protos, 
                                  SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_UNION,
                                  class_context_flags,
                                  true, true, visited, depth+1);


      //say("found "num_matches" matches");
      if (num_matches > 0) {
         tag_get_match_info(1,auto x_cm);
         //say("X tag="x_tag_name" class="x_class_name" type="x_type_name);
         //isay(depth, "_c_get_type_of_matches: symbol="symbol);
         rt.return_type = symbol;
         if (search_class_name == "" || search_class_name == cur_class_name) {
            _str outer_class_name = cur_class_name;
            local_matches := 0;
            if (x_cm.flags & SE_TAG_FLAG_TEMPLATE) {
               rt.istemplate=true;
            }
            //while (outer_class_name != "") {
            for (;;) {
               tag_list_symbols_in_context(rt.return_type, cur_class_name, 0, 0, 
                                           tag_files, "", 
                                           num_matches, def_tag_max_function_help_protos,
                                           SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE|SE_TAG_FILTER_UNION,
                                           class_context_flags,
                                           true, true, visited, depth+1);

               //say("222 match_type="rt.return_type" cur_class_name="cur_class_name" num_matches="local_matches);
               if (local_matches > 0) {
                  tag_get_match_info(1,auto rel_cm);
                  rt.return_type = tag_join_class_name(rt.return_type, rel_cm.class_name, tag_files, true, true, false, visited, depth+1);
                  //isay(depth, "_c_get_type_of_matches(222): return_type="rt.return_type);
                  //say("type_name="rel_type_name" MATCH_TYPE="match_type);
                  if (isjava) {
                     rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                  }
                  break;
               }
               _str junk;
               tag_split_class_name(outer_class_name, junk, outer_class_name);
               if (outer_class_name=="") {
                  break;
               }
            }
         } else if (search_class_name != "") {
            rt.return_type = tag_join_class_name(rt.return_type, search_class_name, tag_files, true, true, false, visited, depth+1);
            //isay(depth, "_c_get_type_of_matches: rt.return_type="rt.return_type);
            if (isjava) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
         }
      }
   }

   // maybe this is an integer which is actually a control name
   if (rt.return_type=="int" && _LanguageInheritsFrom("e")) {
      maybe_form_type := _e_get_control_name_type(rt.return_type, symbol);
      if (maybe_form_type != "") {
         rt.return_type = maybe_form_type;
      }
   }

   // see if 'symbol' is a control for Slick-C
   if ((num_matches==0 || rt.return_type=="" || rt.return_type=="_sc_lang_form" || rt.return_type=="_sc_lang_window") && _LanguageInheritsFrom("e")) {
      //if (_chdebug) {
      //   isay(depth, "_c_get_type_of_matches: Slick-C");
      //}
      // maybe should just search source here...
      eventtab_name := "";
      save_pos(auto p);
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      if (!search('^ *defeventtab +{:v}','@-hr')) {
         eventtab_name = get_match_text(0);
         eventtab_name=stranslate(eventtab_name,"-","_");
      }
      restore_search(p1,p2,p3,p4);
      restore_pos(p);

      if (_chdebug) {
         isay(depth, "_c_get_type_of_matches: Slick-C eventtab="eventtab_name);
      }
      name_symbol := stranslate(symbol,"-","_");
      int wid=_find_formobj(eventtab_name,'E');
      if (!wid) {
         wid = find_index(eventtab_name,oi2type(OI_FORM));
      }
      if (wid && _iswindow_valid(wid)) {
         wid = (int)_for_each_control(wid,"_compare_control_name","H",name_symbol);
      }
      //say("_c_get_type_of_matches: wid="wid);
      if (wid && _iswindow_valid(wid)) {
         rt.return_type = "";
         int t = wid.p_object;
         if (t == OI_MDI_FORM)             rt.return_type = "_mdi_form";
         else if (t == OI_FORM)            rt.return_type = "_form";
         else if (t == OI_TEXT_BOX)        rt.return_type = "_text_box";
         else if (t == OI_CHECK_BOX)       rt.return_type = "_check_box";
         else if (t == OI_COMMAND_BUTTON)  rt.return_type = "_command_button";
         else if (t == OI_RADIO_BUTTON)    rt.return_type = "_radio_button";
         else if (t == OI_FRAME)           rt.return_type = "_frame";
         else if (t == OI_LABEL)           rt.return_type = "_label";
         else if (t == OI_LIST_BOX)        rt.return_type = "_list_box";
         else if (t == OI_HSCROLL_BAR)     rt.return_type = "_hscroll_bar";
         else if (t == OI_VSCROLL_BAR)     rt.return_type = "_vscroll_bar";
         else if (t == OI_COMBO_BOX)       rt.return_type = "_combo_box";
         else if (t == OI_HTHELP)          rt.return_type = "_hthelp";
         else if (t == OI_PICTURE_BOX)     rt.return_type = "_picture_box";
         else if (t == OI_IMAGE)           rt.return_type = "_image";
         else if (t == OI_GAUGE)           rt.return_type = "_gauge";
         else if (t == OI_SPIN)            rt.return_type = "_spin";
         else if (t == OI_MENU)            rt.return_type = "_menu";
         else if (t == OI_MENU_ITEM)       rt.return_type = "_window";
         else if (t == OI_TREE_VIEW)       rt.return_type = "_tree_view";
         else if (t == OI_SSTAB)           rt.return_type = "_sstab";
         else if (t == OI_DESKTOP)         rt.return_type = "_window";
         else if (t == OI_SSTAB_CONTAINER) rt.return_type = "_sstab_container";
         else if (t == OI_EDITOR)          rt.return_type = "_editor";
         //say("t="t" match_type="rt.return_type);
         if (rt.return_type != "") {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
            return 0;
         }
      }
   }

   // no matches?
   if (num_matches == 0) {
      if (_chdebug) {
         isay(depth, "_c_get_type_of_matches: no symbols found");
      }
      errorArgs[1] = symbol;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // check if we should list private class members
   _c_check_context_for_private_scope(rt, cur_class_name, depth);

   // that's all folks
   if (_chdebug) {
      tag_return_type_dump(rt, "_c_get_type_of_matches: returns", depth);
   }
   return 0;
}

// returns true if match was found, false otherwise
static _str _c_get_expr_token(_str &prefixexp)
{
   p := 0;
   if (_LanguageInheritsFrom("groovy")) {
      p = pos("^ @{[0-9_]#UL|[0-9_]#[LGIDFU]|[0-9_]#LU|0x[0-9A-F_]#[ulgidf]@|[0-9]#[_.e+\\-0-9]#[fdb]@|[LS]@\"[~\"]@\"|'\\[ux][0-9A-F_]#'|'\\[0-9_]#'}", prefixexp, 1, 'ri');
   } else if (_LanguageInheritsFrom("rs")) {
      p = pos("^ @{(0[box]|)[0-9_]#([iuf](8|16|32|64)|)|[0-9_]#(\\.[0-9_#]|)(e([+-]|)[0-9_]#|)(f(8|16|32|64)|)}", prefixexp, 1, 'ri');
   } else {
      p = pos("^ @{[0-9]#UL|[0-9]#[LU]|[0-9]#LU|0x[0-9A-F]#[ul]@|:n[fd]@|[LS@]@\"[~\"]@\"|'\\[ux][0-9A-F]#'|'\\[0-9]#'}", prefixexp, 1, 'ri');
   }

   // get the length of the match
   n := 0;
   if (p) {
      n = pos('0');
      p = pos('S0');
   }

   // C++11 user-defined literal
   if (p>0 && n>0 && _LanguageInheritsFrom("c")) {
      np := pos(_clex_identifier_re(),prefixexp,p+n,'ri');
      if (np == p+n) {
         p = pos('S');
         n = pos('');
         ch := '""' :+ substr(prefixexp, p, n);
         prefixexp = substr(prefixexp, p+n);
         return ch;
      }
   }

   if (!p) {
      // get next token from expression
      notparen := "";
      if (_LanguageInheritsFrom('d')) notparen='|\!\(|\!';
      if (_LanguageInheritsFrom('m')) notparen='|[@](:q|\[|\{)';
      p = pos('^ @{->(\*|)|!!\.|\?\.|\.\*|\:\:|<<'notparen'|>>|\&\&|\|\||[<>=\|\&\*\+-/~\^\%\:](=|)|[@]:v|:v|'_clex_identifier_re()'|:q|[()\.]|\:\[|\[|\]}', prefixexp, 1, 'ri');
      if (!p) {
         return "";
      }
      n = pos('0');
      p = pos('S0');
   }

   ch := substr(prefixexp, p, n);
   prefixexp = substr(prefixexp, p+n);
   return ch;
}

// Unix regular expression matching a double quoted string
// For example  "howdy"
static const RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL= "(?:\"[^\"]*\")";

/**
 * Utility function for parsing the next part of the prefix expression.
 * This is called repeatedly by _toy_get_type_of_prefix (below) as it
 * parses the prefix expression from left to right, tracking the return
 * type as it goes along.
 * <P>
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_
 * @param tag_files           list of extension specific tag files
 * @param previous_id         the last identifier seen in the prefix expression
 * @param ch                  the last token removed from the prefix expression
 *                            (parsed out using _toy_get_expr_token, above)
 * @param prefixexp           (reference) The remainder of the prefix expression
 * @param full_prefixexp      The entire prefix expression
 * @param rt                  (reference) set to return type result
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               depth of recursion (for handling typedefs)
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param symbol              name of symbol corresponding to current context 
 * @param search_class_name   class name of current context 
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _c_get_type_of_part(_str (&errorArgs)[], typeless tag_files, bool isjava,
                               _str &previous_id, _str ch,
                               _str &prefixexp, _str &full_prefixexp,
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0,
                               CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL,
                               _str symbol="", _str search_class_name="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_get_type_of_part: ===================================================");
      isay(depth,"_c_get_type_of_part(prev_id="previous_id", ch="ch", prefixexp="prefixexp",full_prefixexp="full_prefixexp", depth="depth")");
      if (_isEditorCtl()) {
         isay(depth, "_c_get_type_of_part: p_buf_name="p_buf_name);
         isay(depth, "_c_get_type_of_part: p_RLine="p_RLine);
      }
   }

   // was the previous identifier a builtin type?
   orig_prefixexp := prefixexp;
   current_id := previous_id;
   previous_builtin := false;
   if (_c_is_builtin_type(previous_id)) {
      previous_builtin=true;
   }

   // number of arguments in paren or brackets group
   status := 0;
   num_args := 0;
   cast_type := "";
   alternate_i := 0;
   alternates := rt.alt_return_types;

   // is the current token a builtin?
   if (_c_is_builtin_type(ch)) {
      if (rt.return_type=="" && _c_has_boxing_conversion(p_LangId)) {
         rt.return_type = _c_get_boxing_conversion(ch);
         if (rt.return_type != "") {
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: BOXING CONVERSION FOR "ch" to "rt.return_type);
            }
            return 0;
         }
      }

      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: BUILTIN");
      }
      previous_builtin=true;
      previous_id = ch;
      return 0;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // process token
   switch (ch) {
   case "->":     // pointer to member
      if (previous_id != "") {
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files,
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:true, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part: ID -> FOUND, match_class="rt.return_type" pointer_count="rt.pointer_count" status="status);
         }
         // -> should have never been in the prefix expression for Java
         if (_LanguageInheritsFrom("java")) {
            if (status || (rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN)) {
               tag_return_type_init(rt);
               if (prefixexp == "") {
                  return VSCODEHELPRC_CONTEXT_NOT_VALID;
               }
            }
         }
         if (status) {
            return status;
         }
         previous_id = "";
      }
      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: -> FOUND, pointer_count="rt.pointer_count);
      }
      alternate_i = 0;
      alternates = rt.alt_return_types;
      loop {
         status = 0;
         if (rt.pointer_count != 1) {
            if (rt.pointer_count < 1) {
               if (!(isjava && !_LanguageInheritsFrom("cs")) && !_LanguageInheritsFrom("pl") && !_LanguageInheritsFrom("phpscript") && !_LanguageInheritsFrom("e")) {
                  if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) {
                     if (_chdebug) {
                        isay(depth, "_c_get_type_of_part: INTERPRETING ARRAY VALUE AS POINTER WITH ->");
                     }
                     rt.alt_return_types._makeempty();
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
                     break;
                  }
                  if (_chdebug) {
                     isay(depth, "_c_get_type_of_part: TRYING TO FIND OPERATOR ->");
                  }
                  _str unusedErrorArgs[];
                  status = _c_get_return_type_of_symbol(unusedErrorArgs,
                                                        tag_files,
                                                        "->", 
                                                        rt.return_type, isjava:false,
                                                        SE_TAG_FILTER_ANY_PROCEDURE, 
                                                        context_flags:0,
                                                        maybe_class_name:false, 
                                                        substituteTemplateArguments:true, 
                                                        actualFunctionArguments:null, 
                                                        rt, 
                                                        visited, 
                                                        depth+1);
                  if (_chdebug ) {
                     isay(depth, "_c_get_type_of_part: OPERATOR ->, match_class="rt.return_type);
                  }
                  if (status) {
                     rt.return_type="";
                  }
                  previous_id = "";
               }
               if (_LanguageInheritsFrom("pl")) {
                  rt.pointer_count=0;
               } else if (rt.return_type == "") {
                  errorArgs[1] = "->";
                  errorArgs[2] = current_id;
                  status = VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER;
               } else if (rt.pointer_count > 0) {
                  rt.pointer_count--;
               }
               break;
            } else {
               if (_LanguageInheritsFrom("e") && substr(prefixexp,1,1)=="[") {
                  --rt.pointer_count;
                  break;
               }
               errorArgs[1] = "->";
               errorArgs[2] = current_id;
               status = VSCODEHELPRC_DASHGREATER_FOR_PTR_TO_POINTER;
            }
         }
         // successful
         if (!status) {
            rt.alt_return_types._makeempty();
            break;
         }
         // try alternate return type
         if (alternate_i >= alternates._length()) break;
         rt = alternates[alternate_i];
         alternate_i++;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part:  trying alternate rt="rt.return_type);
         }
         continue;
      }
      if (status) {
         return status;
      }
      rt.pointer_count = 0;
      break;

   case "?.":
   case "!!.":
   case ".":     // member access operator
      //isay(depth, "_c_get_type_of_part: DOT");
      if ((_LanguageInheritsFrom("d") || _LanguageInheritsFrom("swift") ) &&
          previous_id == "" && rt.return_type=="") {
         tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                 auto cur_type_name, auto cur_type_id, 
                                 auto cur_context, auto cur_class, auto cur_package,
                                 visited, depth+1);
         rt.return_type = cur_package; 
      }
      if (previous_id != "") {
         //isay(depth, "_c_get_type_of_part(DOT): before previous_id="previous_id" match_class="rt.return_type);
         orig_rt := rt;
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files,
                                               previous_id, 
                                               rt.return_type, 
                                               isjava, 
                                               SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ENUM|SE_TAG_FILTER_TYPEDEF|SE_TAG_FILTER_PACKAGE,
                                               context_flags:0,
                                               maybe_class_name:true, 
                                               substituteTemplateArguments:(prefixexp != ""), 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         // special case for array, hash tables in slick-C, javascript
         //say("status="status" p_mode_name="p_mode_name" c-return_flags="c_return_flags);
         // unknown variable used in slick-c 'DOT' expression, then just skip it
         if (_LanguageInheritsFrom("e") &&
             depth < VSCODEHELP_MAXRECURSIVETYPESEARCH &&
             (status == VSCODEHELPRC_BUILTIN_TYPE ||
              status == VSCODEHELPRC_NO_SYMBOLS_FOUND)) {
            return _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, 0, symbol, search_class_name);
         } 

         // If the right hand side is a class name, then only look for 
         // members of this class, not inherited members.
         if (status == 0 && isjava) {
            lhs_type := tag_get_tag_type_of_return_type(rt);
            if (tag_tree_type_is_class(lhs_type)) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
            }
         }

         if (status == 0 && _LanguageInheritsFrom("c")) {
            // Special case for C++/CLI "enum class/struct" - 
            // for these types of enums, 'EnumNAme.ValueName'
            // is not valid syntax for referring to the values.
            // (EnumName::ValueName is the correct way).
            tg_flags:=SE_TAG_FLAG_NULL;
            tag_get_tag_type_of_return_type(rt, tg_flags);
            if (tg_flags & SE_TAG_FLAG_OPAQUE) {
               // Not perfect, but retrying while excluding enums should
               // work in most cases.
               rt = orig_rt;
               status = _c_get_return_type_of_symbol(errorArgs, 
                                                     tag_files,
                                                     previous_id, 
                                                     rt.return_type, 
                                                     isjava, 
                                                     SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_TYPEDEF|SE_TAG_FILTER_PACKAGE,
                                                     context_flags:0,
                                                     maybe_class_name:true, 
                                                     substituteTemplateArguments:false, 
                                                     actualFunctionArguments:null, 
                                                     rt, 
                                                     visited, 
                                                     depth+1);
            }
            
         }

         if (status) {
            return status;
         }
         previous_id = "";
         //isay(depth, "_c_get_type_of_part(DOT): after previous_id="previous_id" match_class="rt.return_type" pointer_count="rt.pointer_count);
      }
      alternate_i = 0;
      alternates = rt.alt_return_types;
      loop {
         //isay(depth, "_c_get_type_of_part: xxx");
         status = 0;
         if (rt.pointer_count > 0) {
            //say("checking pointer count > 0");
            if (_LanguageInheritsFrom("js") || _LanguageInheritsFrom("cfscript")) {
               rt.return_type = "Array";
               rt.pointer_count = 0;
            } else if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("groovy") || _LanguageInheritsFrom("scala")) {
               rt.return_type = "java/lang/Object";
               rt.pointer_count = 0;
            } else if (_LanguageInheritsFrom("cs")) {
               rt.return_type = "System/Array";
               rt.pointer_count = 0;
            } else if (_LanguageInheritsFrom("d") && (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
               rt.return_type = "__ARRAY_TYPE";
               rt.pointer_count = 0;
            } else if (_LanguageInheritsFrom("d") && rt.pointer_count==1) {
               // can use '.' even for pointer types in D language
               rt.pointer_count = 0;
            } else if (_LanguageInheritsFrom("e")) {
               //say("_c_get_type_of_part(): flags="c_return_flags" pointer="pointer_count);
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) {
                  if (rt.pointer_count==1 && (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
                     rt.return_type = "_sc_lang_hashtable";
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE;
                  } else if (rt.pointer_count==2 && (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
                     rt.return_type = "_sc_lang_hashtable";
                     if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE2) {
                        rt.return_flags |= VSCODEHELP_RETURN_TYPE_HASHTABLE;
                        rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE2;
                     }
                  } else {
                     rt.return_type = "_sc_lang_array";
                  }
                  if (rt.pointer_count==1) {
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
                  }
                  rt.pointer_count = 0;
               } else {
                  errorArgs[1] = ".";
                  errorArgs[2] = current_id;
                  status = VSCODEHELPRC_DOT_FOR_POINTER;
               }
            } else if (_LanguageInheritsFrom("systemverilog") && (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
               rt.return_type = "__ARRAY_TYPE";
               rt.pointer_count = 0;

            } else if (_LanguageInheritsFrom("m") && rt.pointer_count==1) {
               // TODO: handle '.' syntax for matching selectors (getter/setter type)
               errorArgs[1] = ".";
               errorArgs[2] = current_id;
               status = VSCODEHELPRC_DOT_FOR_POINTER;
            } else {
               errorArgs[1] = ".";
               errorArgs[2] = current_id;
               status = VSCODEHELPRC_DOT_FOR_POINTER;
            }
         } else if (rt.pointer_count < 0) {
            // maybe they overloaded operator *
            if (rt.pointer_count==-1 && _LanguageInheritsFrom("c")) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_part: TRYING TO FIND OPERATOR *");
               }
               status = _c_get_return_type_of_symbol(errorArgs,
                                                     tag_files,
                                                     "*", 
                                                     rt.return_type, 
                                                     isjava:false,
                                                     SE_TAG_FILTER_ANY_PROCEDURE, 
                                                     context_flags:0,
                                                     maybe_class_name:false, 
                                                     substituteTemplateArguments:true, 
                                                     actualFunctionArguments:null, 
                                                     rt, 
                                                     visited, 
                                                     depth+1);
               if (status) {
                  errorArgs[1] = full_prefixexp;
                  status = VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
               }
               previous_id = "";
            } else {
               errorArgs[1] = full_prefixexp;
               status = VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
            }
         }
         // successful
         if (!status) {
            rt.alt_return_types._makeempty();
            break;
         }
         // try alternate return type
         if (alternate_i >= alternates._length()) break;
         rt = alternates[alternate_i];
         alternate_i++;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part:  trying alternate rt="rt.return_type);
         }
         continue;
      }
      if (status) {
         return status;
      }
      break;

   case "::":    // static member or global scope indicator
   case ":":     // class separator
      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: :: previous_id="previous_id" match_class="rt.return_type);
      }
      if (previous_id == "" && rt.return_type=="") {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         rt.return_type = "::";
         //say("XX match_class=::");
      } else if (previous_id != "") {
         orig_rt := rt;
         cc_filter_flags := SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_TYPEDEF;
         if (_LanguageInheritsFrom("cs")) cc_filter_flags = SE_TAG_FILTER_PACKAGE;
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files,
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               cc_filter_flags, 
                                               context_flags:0,
                                               maybe_class_name:true, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part: :: match_class="rt.return_type" status="status);
         }
         if (status) {
            rt = orig_rt;
         } else {
            // If the right hand side is a class name, then only look for 
            // members of this class, not inherited members.
            lhs_type := tag_get_tag_type_of_return_type(rt);
            if (tag_tree_type_is_class(lhs_type)) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
            }
         }

         if (status && (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("rs"))) {
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: TRYING ENUM CASE");
            }
            // Check for C++/CLI "enum class" or "enum stuct" case
            // where we want to access enum members via ::
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files,
                                                  previous_id, 
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ENUM, 
                                                  context_flags:0,
                                                  maybe_class_name:true, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);

            if (!status) {
               tg_flags:=SE_TAG_FLAG_NULL;
               tag_get_tag_type_of_return_type(rt, tg_flags);
               if (!(tg_flags & SE_TAG_FLAG_OPAQUE)) {
                  if (_chdebug) {
                     isay(depth, "_c_get_type_of_part: NOT AN OPAQUE ENUM");
                  }
                  // Not the case, we don't want this info.
                  status = 1;
                  rt = orig_rt;
               }
            }
         }

         // THIS could be just a class qualification for making an
         // assignment to a pointer to member or pointer to member func.
         // SO, we have to list everything, not just statics.
         // ALSO, the class could be a base class qualification for a
         // function call BASE::myvirtualfunc();
         if (status && tag_check_for_typedef(previous_id, tag_files, true, rt.return_type, visited, depth+1)) {
            //say(previous_id" is a typedef");
            orig_const_only    := (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
            orig_volatile_only := (rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY);
            orig_is_array      := (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES);
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files,
                                                  previous_id, 
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_TYPEDEF, 
                                                  context_flags:0,
                                                  maybe_class_name:true, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            //say(":: match_class="match_class" status="status);
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags |= orig_const_only;
            }
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY)) {
               rt.return_flags |= orig_volatile_only;
            }
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
               rt.return_flags |= orig_is_array;
            }
         }
         if (status) {
            rt.return_type="";
            return status;
         }
         previous_id = "";
      } else {
         //say(":: already processed previous ID");
      }
      break;

   case ":[":
   case "?[":
   case "[":
      if (_LanguageInheritsFrom("m") && previous_id == "" && rt.return_type == "") {
         match_generic(prefixexp, auto bracketexp, num_args, "[],");
         status = _c_get_type_of_expression(errorArgs, tag_files, 
                                            "", "", "", 
                                            VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE, 
                                            expr:bracketexp, 
                                            rt, visited, depth+1);
         if (status) {
            return status;
         }
         previous_id = "";
         break;
      }

      // handle slick-c hash tables
      slickc_hash_table := false;
      if (_LanguageInheritsFrom("e") && ch==":[") {
         slickc_hash_table=true;
         //prefixexp=substr(prefixexp,2);
      }

      arrayexp := "";
      if (!match_generic(prefixexp, arrayexp, num_args, '[],')) {
         // this is not good
         //say("return from [");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (previous_id != "") {
         current_id = previous_id;
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files,
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:true, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         previous_id = "";
      }
      if (rt.pointer_count <= 0) {
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY_TYPES;
            break;
         }
         if (_LanguageInheritsFrom("kotlin") ||
             !isjava || 
             _LanguageInheritsFrom("cs") || 
             _LanguageInheritsFrom("d")  ||
             _LanguageInheritsFrom("e")) {
            //say("TRYING TO FIND OPERATOR []");
            array_operator_name := "[]";
            if (_LanguageInheritsFrom("kotlin")) {
               array_operator_name = "get";
            } else if (_LanguageInheritsFrom("d")) {
               array_operator_name = "opIndex";
            } else if (_LanguageInheritsFrom("e")) {
               if (slickc_hash_table) {
                  array_operator_name = "_hash_el";
               } else {
                  array_operator_name = "_array_el";
               }
            }
            if ( _chdebug ) {
               isay(depth, "_c_get_type_of_part: LOOKING FOR OPERATOR [] rt.return_type="rt.return_type" op="array_operator_name);
            }
            orig_rt := rt;
            status = _c_get_return_type_of_symbol(errorArgs,
                                                  tag_files,
                                                  array_operator_name, 
                                                  rt.return_type, 
                                                  isjava:false,
                                                  SE_TAG_FILTER_ANY_PROCEDURE, 
                                                  context_flags:0,
                                                  maybe_class_name:false, 
                                                  substituteTemplateArguments:true, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            if ( _chdebug ) {
               isay(depth, "_c_get_type_of_part: OPERATOR [] status="status" rt.return_type="rt.return_type);
            }
            if (status) {
               if (_LanguageInheritsFrom("c") && orig_rt.return_type != "" && num_args==1 && _first_char(arrayexp)=='+' && isuinteger(substr(arrayexp,2))) {
                  member_status := _c_get_return_type_of_structured_binding(errorArgs,tag_files,orig_rt,(int)substr(arrayexp,2),visited,depth+1);
                  if (member_status < 0) return status;
                  status = member_status;
                  rt = orig_rt;
               } else {
                  return status;
               }
            }
            previous_id = "";
         }
         if (rt.return_type == "") {
            errorArgs[1] = current_id;
            return (VSCODEHELPRC_SUBSCRIPT_BUT_NOT_ARRAY_TYPE);
         }
         break;
      }
      if (rt.pointer_count==2) {
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE) {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE;
         }
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE2) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_HASHTABLE;
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE2;
         }
      } else if (rt.pointer_count==1) {
         rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2);
      }
      rt.pointer_count--;
      //say("PREFIX[], pointer_count="pointer_count);
      break;

   case "@[":
      arrayexp = "";
      if (!match_generic(prefixexp, arrayexp, num_args, '[],')) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (_chdebug) {
         isay(depth,"_c_get_type_of_part: Objective-C array, previous_id="previous_id);
      }
      rt.pointer_count = 1;
      rt.return_type = "NSArray";
      rt.return_flags = VSCODEHELP_RETURN_TYPE_ARRAY;
      rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE;
      rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE2;
      break;
   case "@{":
      dictexp := "";
      if (!match_generic(prefixexp, dictexp, num_args, '{},')) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (_chdebug) {
         isay(depth,"_c_get_type_of_part: Objective-C dictionary, previous_id="previous_id);
      }
      rt.pointer_count = 1;
      rt.return_type = "NSDictionary";
      rt.return_flags = VSCODEHELP_RETURN_TYPE_HASHTABLE;
      rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
      rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE2;
      break;

   case "]":     // array subscript close
      // what do I do here?
      break;

   case "(":     // function call, cast, or expression grouping
      if (!match_parens(prefixexp, cast_type, num_args)) {
         // this is not good
         //say("return from (");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_PARENTHESIS_MISMATCH;
      }
      if (_chdebug) {
         isay(depth,"_c_get_type_of_part: PAREN cast_type="cast_type" previous_id="previous_id);
      }
      if (previous_id != "") {
         if (previous_builtin) {
            // this is a new-style C++ cast expression int(3), for example
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN BUILTIN previous_id="previous_id);
            }
            rt.return_type = previous_id;
            rt.pointer_count = 0;
         } else {
            // this was a function call or new style function pointer
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN AFTER ID, previous_id="previous_id" match_class="rt.return_type" num_args="num_args);
               isay(depth, "_c_get_type_of_part: prefixexp="prefixexp);
            }
            proc_status := 0;
            orig_rt := rt;
            C_RETURN_TYPE_ACTUAL_FUNCTION_ARGUMENTS actualFunctionArguments;
            actualFunctionArguments.filterFunctionSignatures = (prefixexp != "" && (_GetCodehelpFlags() & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS) != 0);
            actualFunctionArguments.functionArguments = cast_type;
            actualFunctionArguments.numFunctionArguments = num_args;
            actualFunctionArguments.functionArgumentsFilename = p_buf_name;
            actualFunctionArguments.functionArgumentsLine = p_RLine;
            actualFunctionArguments.functionArgumentsPos = _QROffset();
            status = _c_get_return_type_of_symbol(errorArgs,
                                                  tag_files,
                                                  previous_id,
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA,
                                                  context_flags:0,
                                                  maybe_class_name:false, 
                                                  substituteTemplateArguments:false,
                                                  actualFunctionArguments, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            proc_status = status;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN AFTER ID, status="status);
            }
            is_constructor := false;
            if (status==VSCODEHELPRC_NO_SYMBOLS_FOUND || status == VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID TRY AGAIN AND LOOK FOR CONSTRUCTOR");
               }
               rt = orig_rt;
               status = _c_get_return_type_of_symbol(errorArgs,
                                                     tag_files,
                                                     previous_id,
                                                     rt.return_type, 
                                                     isjava,
                                                     SE_TAG_FILTER_ANY_STRUCT,
                                                     context_flags:0,
                                                     maybe_class_name:true, 
                                                     substituteTemplateArguments:false,
                                                     actualFunctionArguments, 
                                                     rt, 
                                                     visited,
                                                     depth+1);
               is_constructor=(status >=0 && rt.return_type!="");
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID, CONSTRUCTOR status="status" return_type="rt.return_type);
               }
            }
            // maybe this is a Slick-C control of some sort
            if (status==VSCODEHELPRC_NO_SYMBOLS_FOUND || status == VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
               if (_LanguageInheritsFrom("e")) {
                  switch (rt.return_type) {
                  case "_sc_lang_control":
                  case "_sc_lang_mdi_form":
                  case "_sc_lang_basewindow":
                  case "_sc_lang_window":
                  case "_sc_lang_text_window":
                  case "_sc_lang_scrollable":
                  case "_sc_lang_form":
                  case "_sc_lang_text_or_list_box":
                  case "_sc_lang_text_box":
                  case "_sc_lang_list_box":
                  case "_sc_lang_combo_box":
                  case "_sc_lang_frame":
                  case "_sc_lang_label":
                  case "_sc_lang_radio_button":
                  case "_sc_lang_check_box":
                  case "_sc_lang_scroll_bar":
                  case "_sc_lang_hscroll_bar":
                  case "_sc_lang_vscroll_bar":
                  case "_sc_lang_picture_box":
                  case "_sc_lang_command_button":
                  case "_sc_lang_image":
                  case "_sc_lang_gauge":
                  case "_sc_lang_spin":
                  case "_sc_lang_menu":
                  case "_sc_lang_menu_item":
                  case "_sc_lang_tabbed":
                  case "_sc_lang_sstab":
                  case "_sc_lang_sstab_container":
                  case "_sc_lang_tree_view":
                  case "_sc_lang_editor":
                  case "_sc_lang_minihtml":
                  case "_sc_lang_print_preview":
                  case "_sc_lang_switch":
                     if (_chdebug) {
                        isay(depth, "_c_get_type_of_part: SLICK-C CONTROL, LOOK FOR METHOD CALL");
                     }
                     rt = orig_rt;
                     rt.return_type = "";
                     status = _c_get_return_type_of_symbol(errorArgs,
                                                           tag_files,
                                                           previous_id,
                                                           search_class_name:"",
                                                           isjava, 
                                                           SE_TAG_FILTER_ANY_PROCEDURE,
                                                           context_flags:0,
                                                           maybe_class_name:false, 
                                                           substituteTemplateArguments:false,
                                                           actualFunctionArguments:null, 
                                                           rt, 
                                                           visited, 
                                                           depth+1);
                     if (_chdebug) {
                        isay(depth, "_c_get_type_of_part: SLICK-C CONTROL status="status" return_type="rt.return_type);
                     }
                     break;
                  default:
                     break;
                  }
               }
            }
            if (!(actualFunctionArguments!=null && actualFunctionArguments.filterFunctionSignatures) && 
                (proc_status == VSCODEHELPRC_OVERLOADED_RETURN_TYPE || proc_status == VSCODEHELPRC_RETURN_TYPE_NOT_FOUND)) {
               rt = orig_rt;
               actualFunctionArguments.filterFunctionSignatures = true;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID RETRY WITH FUNCTION ARGUMENT MATCHING, p_col="p_col);
               }
               status = _c_get_return_type_of_symbol(errorArgs,
                                                     tag_files,
                                                     previous_id,
                                                     rt.return_type, 
                                                     isjava,
                                                     SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA,
                                                     context_flags:0,
                                                     maybe_class_name:false, 
                                                     substituteTemplateArguments:false,
                                                     actualFunctionArguments, 
                                                     rt, 
                                                     visited, 
                                                     depth+1);
            }
            new_match_class := rt.return_type;
            rt.return_type=orig_rt.return_type;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN AFTER ID status="status" pointer_count="rt.pointer_count" match_tag="rt.taginfo);
            }
            if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND && status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
               return status;
            }
            // did we find a variable of a function or function pointer?
            is_function := false;
            if (rt.taginfo != "") {
               tag_get_info_from_return_type(rt, auto func_cm);
               if (tag_tree_type_is_func(func_cm.type_name) || pos("(",func_cm.return_type)) {
                  is_function=true;
                  rt.pointer_count -= orig_rt.pointer_count;
               }
               if (rt.istemplate) {
                  tag_return_type_merge_templates(rt, orig_rt);
               }
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN AFTER ID new_match_class="new_match_class);
            }
            // could not find match class, maybe this is a function-style cast?
            if (/*!isjava &&*/ new_match_class == "") {
               num_matches := 0;
               tag_list_symbols_in_context(previous_id, rt.return_type, 0, 0, 
                                           tag_files, "", 
                                           num_matches, def_tag_max_find_context_tags, 
                                           SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_TYPEDEF,
                                           SE_TAG_CONTEXT_ALLOW_LOCALS | SE_TAG_CONTEXT_FIND_ALL,
                                           true, true, visited, depth+1, rt.template_args);

               if (num_matches > 0) {
                  if (_chdebug) {
                     isay(depth, "_c_get_type_of_part: PAREN AFTER ID "previous_id" is a struct or typedef");
                  }
                  status = _c_parse_return_type(errorArgs, tag_files,
                                                "", "", p_buf_name,
                                                previous_id, isjava, rt, 
                                                visited, depth+1);
                  if (!status) {
                     is_function = true;
                  }
               } else if (rt.return_type != "") {
                  rt.pointer_count = 0;
               }
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID match_class="rt.return_type" status="status" pointer_count="rt.pointer_count);
               }
            } else {
               rt.return_type = new_match_class;
               previous_id="";
            }
            // maybe they have function call operator
            if (!is_constructor && !isjava && rt.return_type!="" && status && !is_function) {
               status = _c_get_return_type_of_symbol(errorArgs,
                                                     tag_files,
                                                     "()",
                                                     rt.return_type, 
                                                     isjava,
                                                     SE_TAG_FILTER_ANY_PROCEDURE, 
                                                     context_flags:0,
                                                     maybe_class_name:false, 
                                                     substituteTemplateArguments:false, 
                                                     actualFunctionArguments:null, 
                                                     rt, 
                                                     visited, 
                                                     depth+1);
               if (status && 
                   status != VSCODEHELPRC_BUILTIN_TYPE &&
                   status != VSCODEHELPRC_NO_SYMBOLS_FOUND) {
                  return status;
               }
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID match_class="rt.return_type" status="status" pointer="rt.pointer_count);
               }
            }
            previous_id = "";
         }

      } else {
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part: CAST PAREN cast_type="cast_type" prefixexp="prefixexp);
         }
         // perhaps a function pointer call
         if (pos('^[ \t]*\*[ \t]*{:v|'_clex_identifier_re()'|[(]}',cast_type,1,'r') && pos('(',prefixexp)==1) {
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a function pointer");
            }
            cast_type = substr(cast_type, 2);
            status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, cast_type, rt, visited, depth+1, 0);
            if (status) {
               return status;
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PFN: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
            }
            prefixexp = substr(prefixexp, 2);
            if (!match_parens(prefixexp, cast_type, num_args)) {
               // this is not good
               //say("return from (");
               errorArgs[1] = full_prefixexp;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }

         } else if (_first_char(strip(prefixexp)) == '?' && pos(':',prefixexp)) {
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a ternary expression");
            }
            // take the third term of the ternary expression
            parse prefixexp with . ':' prefixexp;

         } else if (pos("([-][>]|[.])[*]", cast_type, 1, 'r') && pos("(",prefixexp)==1) {

            // this is a pointer to member function invocation
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a pointer to member function");
            }
            status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, cast_type, rt, visited, depth+1, 0);
            if (status) {
               return status;
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PFMF: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
            }
            prefixexp = substr(prefixexp, 2);
            if (!match_parens(prefixexp, cast_type, num_args)) {
               // this is not good
               //say("return from (");
               errorArgs[1] = full_prefixexp;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }

         } else if (pos("^[ \t]*[*^&(]*[ \t]*(:v|"_clex_identifier_re()"|:n|\\-\\-|\\+\\+)",prefixexp,1,'r')) {

            // a cast will be followed by an identifier, (, *, &, ++, --, or a number
            // we don't care about the rest of the parenthesized expr though
            prefixexp = "";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a cast, depth="depth);
            }
            if (depth > 0) {
               status = _c_parse_return_type(errorArgs, tag_files,
                                             "", "", p_buf_name,
                                             cast_type, isjava, 
                                             rt, visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: CAST match_class="rt.return_type" prefixexp="prefixexp" cast_type="cast_type" status="status);
               }
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
               previous_id="";
               return status;
            }
            // otherwise, just ignore the cast

         } else if (!pos("(",cast_type) && pos(",",cast_type)) {

            // this looks like an argument list, check for operator function call.
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a function call operator");
            }
            status = _c_get_return_type_of_symbol(errorArgs,
                                                  tag_files,
                                                  "()",
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ANY_PROCEDURE, 
                                                  context_flags:0,
                                                  maybe_class_name:false, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            if (status) {
               return status;
            }

         } else if (pos('^[ \t]*new[ \t]',cast_type,1,'re')) {

            // object creation expression
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a new expression");
            }
            parse cast_type with "new" cast_type;
            status = _c_parse_return_type(errorArgs, tag_files,
                                          "", "", p_buf_name,
                                          cast_type, isjava, 
                                          rt, visited, depth+1);
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: NEW: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type" status="status);
            }
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
            prefixexp="";
            if (status) {
               return status;
            }
         } else {
            // not a cast, must be an expression, go recursive
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's an expression, cast_type="cast_type);
            }
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:cast_type, 
                                               rt, visited, depth+1);
            if (status) {
               return status;
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: EXPR: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
            }
         }
      }
      break;

   case ")":
      // what do I do here?
      errorArgs[1] = full_prefixexp;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;

   case "$this":
   case "this":
      if (_LanguageInheritsFrom("phpscript") && ch=="$this") {
         ch="this";
      }
      status = _c_get_return_type_of_symbol(errorArgs, 
                                            tag_files, 
                                            ch, 
                                            search_class_name:"", 
                                            isjava,
                                            SE_TAG_FILTER_ANY_DATA, 
                                            context_flags:0,
                                            maybe_class_name:false, 
                                            substituteTemplateArguments:false, 
                                            actualFunctionArguments:null, 
                                            rt, 
                                            visited, 
                                            depth+1);
      if (status) {
         return status;
      }
      previous_id = "";
      if (!isjava && 
          !_LanguageInheritsFrom("js") &&
          !_LanguageInheritsFrom("as") &&
          !_LanguageInheritsFrom("e") &&
          !_LanguageInheritsFrom("vera") &&
          !_LanguageInheritsFrom("systemverilog")) {
         rt.pointer_count = 1;
      }
      if (_LanguageInheritsFrom("cs")) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
      }
      break;

   case "->*":   // pointer to member function
   case ".*":    // binds left-to-right, type of rhs is result
      previous_id = "";
      rt.return_type="";
      break;

   case "*":     // dereference pointer
   case "&":     // get reference to object
      if (!isjava) {
         // test if this is a unary operator
         if (prefixexp != "" && substr(full_prefixexp,2) == prefixexp) {
            status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, 0);
            if (!status) {
               if (ch :== "*" && rt.pointer_count > 0) {
                  rt.pointer_count--;
                  prefixexp = "";
                  break;
               } else if (ch :== "*") {
                  VS_TAG_RETURN_TYPE star_rt = rt;
                  status = _c_get_return_type_of_symbol(errorArgs, 
                                                        tag_files, 
                                                        ch,
                                                        rt.return_type, 
                                                        isjava, 
                                                        SE_TAG_FILTER_ANY_PROCEDURE,
                                                        context_flags:0, 
                                                        maybe_class_name:false, 
                                                        substituteTemplateArguments:true, 
                                                        actualFunctionArguments:null, 
                                                        star_rt, 
                                                        visited, 
                                                        depth+1);
                  if (!status) {
                     rt = star_rt;
                     prefixexp = "";
                     break;
                  } else {
                     errorArgs[1] = "*";
                     errorArgs[2] = prefixexp;
                     return (VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER);
                  }
               } else if (ch :== "&") {
                  rt.pointer_count++;
                  break;
               }
            }
         }
      }
      // drop through to operator overloading case

   case "<":
   case "!":
   case "!(":
      templateexp := "";
      if ((ch:=="!" && _LanguageInheritsFrom("d")) ||
          (ch:=="<" && match_generic(prefixexp, templateexp, num_args, "<>,") && previous_id :!= "") ||
          (ch:=="!(" && match_generic(prefixexp, templateexp, num_args, "(),") && previous_id :!= "")) {
         if (ch :== "!") {
            num_args = 1;
            paren_pos := pos('[^!]\(', prefixexp, 1, 'r');
            if (paren_pos > 0) {
               templateexp = substr(prefixexp, 1, paren_pos-1);
               prefixexp = substr(prefixexp, paren_pos);
            } else {
               templateexp = prefixexp;
               prefixexp = "";
            }
         }
         parameterizedProcOrVar := false;
         orig_globals_only := (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY);
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               previous_id, 
                                               rt.return_type,
                                               isjava, 
                                               SE_TAG_FILTER_ANY_STRUCT, 
                                               context_flags:0, 
                                               maybe_class_name:true, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files, 
                                                  previous_id, 
                                                  rt.return_type,
                                                  isjava, 
                                                  SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_DATA, 
                                                  context_flags:0, 
                                                  maybe_class_name:true, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            parameterizedProcOrVar = (status==0);
         } else if ( _first_char(strip(prefixexp)) == '(' ) {
            // constructor
            parameterizedProcOrVar = true;
         }
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part: <> match_class="rt.return_type" status="status" prefixexp="prefixexp" istemplate="rt.istemplate" parameterizedProcOrVar="parameterizedProcOrVar);
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         rt.return_flags |= orig_globals_only;

         // set up rt.template_args with the template arguments
         if (!status && rt.taginfo!="") {

            tag_get_info_from_return_type(rt, auto template_cm);
            template_args := template_cm.arguments;
            if (template_cm.template_args != "" && template_args == "") {
               template_args = template_cm.template_args;
            }
            if (template_cm.return_type != "" && rt.return_type=="") {
               rt.return_type = template_cm.return_type;
            }

            if ((template_cm.flags & SE_TAG_FLAG_TEMPLATE)) {
               // first parse out the argument values
               _str arg_vals[];
               val_pos := 0;
               arg_value := "";
               tag_get_next_argument(templateexp, val_pos, arg_value);
               while (arg_value !="") {
                  arg_vals :+= arg_value;
                  tag_get_next_argument(templateexp, val_pos, arg_value);
               }
               val_pos=0;
               // now parse out the argument names
               arg_pos := 0;
               arg_name := "";
               tag_get_next_argument(template_args, arg_pos, arg_name);
               while (arg_name !="") {
                  rt.istemplate=true;
                  arg_default := "";
                  parse arg_name with arg_name "=" arg_default;
                  arg_value=(val_pos < arg_vals._length())? arg_vals[val_pos]:"";
                  if (arg_value=="") {
                     if (arg_default!="") {
                        arg_value=arg_default;
                     } else if (_LanguageInheritsFrom("java")) {
                        arg_value="java.lang.Object";
                     }
                  }

                  arg_type := "";
                  arg_name = strip(arg_name);
                  if (pos(":v", arg_name, 1, 'r') == 1) {
                     arg_type = substr(arg_name, 1, pos(''));
                     arg_rest := strip(substr(arg_name, pos('')+1));
                     if (pos("...", arg_rest)) {
                        rt.isvariadic = true;
                        arg_type :+= "...";
                        arg_rest = substr(arg_rest, 4);
                     }
                     arg_name = arg_rest;
                  }

                  if (!_inarray(arg_name, rt.template_names)) {
                     rt.template_names :+= arg_name;
                  }
                  rt.template_args:[arg_name]=arg_value;
                  tag_get_next_argument(template_args, arg_pos, arg_name);
                  val_pos++;
               }
            }
            if (parameterizedProcOrVar && rt.return_type != null && rt.return_type != "") {
               // substitute template arguments
               for (ti := 0; ti < rt.template_names._length(); ++ti) {
                  ta := rt.template_names[ti];
                  tt := rt.return_type;
                  if (rt.template_types._indexin(ta)) {
                     tt = tag_return_type_string(rt.template_types:[ta],false);
                  } else if (rt.template_args._indexin(ta)) {
                     tt = rt.template_args:[ta];
                     struct VS_TAG_RETURN_TYPE template_rt;
                     tag_return_type_init(template_rt);
                     _c_parse_return_type(errorArgs, tag_files, 
                                          template_cm.member_name, "", p_buf_name,
                                          tt, isjava, template_rt, 
                                          visited, depth+1);
                     rt.template_types:[ta] = template_rt;
                     tt = tag_return_type_string(rt.template_types:[ta],false);
                  }
                  rt.return_type = stranslate(rt.return_type, tt, ta, "ew");
               }
            }
         }
         if (!status) {
            if (!parameterizedProcOrVar) {
               previous_id = "";
            }
            break;
         }
      }
      // drop through to operator overloading case

   case "=":     // binary operators within expression
   case "-":
   case "+":
   case "/":
   case "%":
   case "^":
   case "<<":
   case ">>":
   case "&&":
   case "|":
   case "||":
   case "<=":
   case ">=":
   case "==":
   case ">":   // "<" is needed for templates, above
      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: MAYBE BINARY OPERATOR="ch);
      }
      if (depth <= 0) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (previous_id != "") {
         extra_filters := SE_TAG_FILTER_NULL;
         if (ch == "/") {
            extra_filters |= SE_TAG_FILTER_ANY_STRUCT;
            extra_filters |= SE_TAG_FILTER_PACKAGE;
            extra_filters |= SE_TAG_FILTER_TYPEDEF;
         }
         tt := tag_get_tag_type_of_return_type(rt);
         rt.taginfo = "";
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files,
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA|extra_filters, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments: (ch != "/" || !tag_tree_type_is_package(tt)), 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         previous_id = "";
      }
      // check for operator overloading
      VS_TAG_RETURN_TYPE last_return_type = rt;
      if (rt.return_type != "") {
         skipOperatorLookup := false;
         if (isjava) {
            skipOperatorLookup = true;
         } else if (ch == "/") {
            // If the right hand side is a package or class name, 
            // then only look for members of this class, not operators
            lhs_type := tag_get_tag_type_of_return_type(rt);
            if (tag_tree_type_is_package(lhs_type) || tag_tree_type_is_class(lhs_type)) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: SKIP OPERATOR LOOKUP FOR /");
               }
               skipOperatorLookup = true;
            }
         }
         if (!skipOperatorLookup) {
            orig_match_class := rt.return_type;
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files, 
                                                  ch, 
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ANY_PROCEDURE, 
                                                  SE_TAG_CONTEXT_NO_GLOBALS, 
                                                  maybe_class_name:false, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: BINARY OPERATOR LOOKUP STATUS="status);
            }
            if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND) {
               rt.return_type=orig_match_class;
               return status;
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: BINARY OPERATOR rt.return_type="rt.return_type" last="last_return_type.return_type);
            }
         }
      }
      if (rt.return_type == "") {
      // For now just go back to the type of the lhs side of this expression if operator lookup fails.
         rt = last_return_type;
         //errorArgs[1] = full_prefixexp;
         //return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (ch == "/" && !(rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN)) {
         // This may be a slickedit class separator
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
      } else {
         prefixexp = "";  // breaks us out of loop
      }
      break;

   case "as":
      // check for C# style cast expressions
      if (_LanguageInheritsFrom("cs") && ch=="as") {
         cast_ch := ch;
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part: found C# style cast-as expression: "ch);
         }
         prefixexp = strip(prefixexp, "L");
         if (prefixexp != "") {
            ch = ")";
            previous_id = "";
            status = _c_parse_return_type(errorArgs,tag_files,
                                          "",search_class_name,p_buf_name,
                                          prefixexp,isjava,
                                          rt,visited,depth+1);
            prefixexp="";
            if (_chdebug) {
               isay(depth,"_c_get_type_of_part: prefixexp="prefixexp" ch="ch" status="status);
               tag_return_type_dump(rt, "_c_get_type_of_part(C# cast-as)", depth);
            }
            return status;
         }
      }
      // drop through, treat it as a an identifier

   case "checked":
   case "unchecked":
      // check for C# checked and unchecked expressions
      if (_LanguageInheritsFrom("cs") && (ch=="checked" || ch=="unchecked")) {
         cast_ch := ch;
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part: found C# checked/unchecked expression: "ch);
         }
         prefixexp = strip(prefixexp, "L");
         if (_first_char(prefixexp) == "(") {
            prefixexp = substr(prefixexp, 2);
            cast_expression := "";
            num_cast_args := 0;
            if (match_generic(prefixexp, cast_expression, num_cast_args, "(),")) {
               ch = ")";
               previous_id = "";
               status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                  "", "", "", 
                                                  VSCODEHELP_PREFIX_NULL, 
                                                  cast_expression, 
                                                  rt, visited, depth+1);
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_part: prefixexp="prefixexp" ch="ch" status="status);
                  tag_return_type_dump(rt, "_c_get_type_of_part(C# checked/unchecked)", depth);
               }
               return status;
            }
            prefixexp = orig_prefixexp;
         }
      }
      // drop through, treat it as a an identifier

   case "self":
      if (ch:=="self" && 
          (_LanguageInheritsFrom("py") ||
           _LanguageInheritsFrom("lua") ||
           _LanguageInheritsFrom("swift") ||
           _LanguageInheritsFrom("rs") ||
           _LanguageInheritsFrom("m"))
         ) {
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               symbol:"this", 
                                               search_class_name:"", 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         previous_id = "";
         if (_LanguageInheritsFrom("m")) {
            rt.pointer_count=1;
         } else {
            rt.pointer_count=0;
         }
         break;
      }
      // drop through, treat it as a an identifier

   case "base":
   case "super":
      if (((isjava ||
            _LanguageInheritsFrom("m") ||
            _LanguageInheritsFrom("vera") ||
            _LanguageInheritsFrom("swift") ||
            _LanguageInheritsFrom("rs") ||
            _LanguageInheritsFrom("systemverilog"))
           && ch:=="super") ||
          (_LanguageInheritsFrom("cs") && ch:=="base")) {
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               symbol:"this", 
                                               search_class_name:"", 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         tag_dbs := "";
         parent_types := "";
         parents := cb_get_normalized_inheritance(rt.return_type, 
                                                  tag_dbs, tag_files,
                                                  true, "", p_buf_name, 
                                                  parent_types, false, 
                                                  visited, depth+1);
         if ( _chdebug ) {
            isay(depth, "_c_get_type_of_part: SUPER OR BASE parents="parents" match_class="rt.return_type);
         }
         //parse parents with match_class ";" parents;
         // add each of them to the list also
         while (parents != "") {
            parse parents with auto p1 ";" parents;
            parse tag_dbs with auto t1 ";" tag_dbs;
            if (t1!="") {
               status = tag_read_db(t1);
               if (status < 0) {
                  continue;
               }
            }
            // add transitively inherited class members
            outer_class := "";
            parse p1 with p1 "<" .;
            parse p1 with p1 "!(" .;
            tag_split_class_name(p1, rt.return_type, outer_class);
            status = tag_find_context_iterator(rt.return_type,true,true,false,outer_class);
            if (status > 0) {
               rt.return_type = p1;
               break;
            }
            if (status < 0 && t1!="") {
               status = tag_find_tag(rt.return_type, "class", outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
               status = tag_find_tag(rt.return_type, "interface", outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
            }

            // try other tag files
            for (i:=0;;) {
               t1 = next_tag_filea(tag_files,i,false,true);
               tag_reset_find_tag();
               if (t1=="") {
                  break;
               }
               status = tag_find_tag(rt.return_type, "class", outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
               status = tag_find_tag(rt.return_type, "interface", outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
            }
            if (!status && t1 != "") {
               break;
            }
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         previous_id = "";
         break;
      }
      // drop through, treat as a plain identifier

   case "class":
      if (isjava && ch:=="class" && !_LanguageInheritsFrom("cs")) {
         rt.return_type = "java/lang/Class";
         rt.pointer_count=0;
         rt.istemplate=false;
         rt.isvariadic=false;
         rt.template_args._makeempty();
         rt.template_names._makeempty();
         rt.template_types._makeempty();
         rt.return_flags=0;
         rt.taginfo="Class(java/lang:class)";
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         previous_id = "";
         break;
      }
      // drop through, treat as a plain identifier

   case "outer":
      if ((isjava || _LanguageInheritsFrom("rs")) && ch:=="outer") {
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               symbol:"this", 
                                               search_class_name:"", 
                                               isjava,
                                               SE_TAG_FILTER_ANY_DATA, 
                                               context_flags:0,
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         junk := "";
         tag_split_class_name(rt.return_type, junk, rt.return_type);
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
         previous_id = junk;
         break;
      }
      // drop through and treat as a plain identifier

   case "operator":
      if (!isjava && ch :== "operator" && !_LanguageInheritsFrom("py")) {
         prefixexp = strip(prefixexp,'L');
         pp := pos("(",prefixexp,2);
         if (pp > 0) {
            ch = strip(substr(prefixexp,1,pp-1));
            prefixexp = substr(prefixexp,pp+1);
            //say("***prefixexp="prefixexp" ch="ch);
            dummy_args := "";
            if (!match_parens(prefixexp, dummy_args, num_args)) {
               // this is not good
               //say("return from (");
               errorArgs[1] = full_prefixexp;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files, 
                                                  ch,
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ANY_PROCEDURE, 
                                                  context_flags:0,
                                                  maybe_class_name:false, 
                                                  substituteTemplateArguments:true, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            if (status) {
               return status;
            }
            previous_id="";
         } else {
            ch = strip(prefixexp);
            prefixexp="";
         }
         break;
      }
      // drop through, treat it as an identifier

   case "new":   // new keyword
   case "gcnew": // managed C++
      if (ch :== "new" || ch :== "gcnew") {

         // special case for Rust  ClassName::new()
         if (_LanguageInheritsFrom("rs")) {
            // parse parameters
            if (substr(prefixexp, 1, 1):=="(") {
               prefixexp = substr(prefixexp, 2);
               _str parenexp;
               if (!match_parens(prefixexp, parenexp, num_args)) {
                  // this is not good
                  //say("return from new 2");
                  errorArgs[1] = "new "ch" "prefixexp;
                  return VSCODEHELPRC_PARENTHESIS_MISMATCH;
               }
            }
            previous_id = "";
            break;
         }

         // special case for Python
         if (_LanguageInheritsFrom("py")) {
            rt.return_type = ch;
            rt.taginfo = "new(package)";
            break;
         }
         // Just ignore 'new' if we don't know what to do with it
         if (depth<=1 && !pos('[(.-]',prefixexp,1,'r')) {         
            break;
         }
         if (previous_id=="") {
            if ( _chdebug ) {
               isay(depth, "_c_get_type_of_part: NEW, prefixexp="prefixexp);
            }
            status = _c_parse_return_type(errorArgs, tag_files,
                                          symbol, search_class_name,
                                          "", prefixexp, isjava,
                                          rt, visited, depth+1);
            if (!status) {
               prefixexp = "";
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY;
               if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) && !isjava && !_LanguageInheritsFrom("cs")) {
                  rt.pointer_count++;
               }
            }
            break;
         }
         if (isjava && previous_id=="") break;
         int p = pos('^(:b)*{:v|'_clex_identifier_re()'}(:b)*', prefixexp, 1, 'r');
         if (!p) {
            // this is not good news...
            //say("return from new");
            errorArgs[1] = "new " prefixexp;
            return VSCODEHELPRC_INVALID_NEW_EXPRESSION;
         }
         ch = substr(prefixexp, pos('S0'), pos('0'));
         prefixexp = substr(prefixexp, p+pos(""));
         rt.return_type = ch;
         if (substr(prefixexp, 1, 1):=="(") {
            prefixexp = substr(prefixexp, 2);
            _str parenexp;
            if (!match_parens(prefixexp, parenexp, num_args)) {
               // this is not good
               //say("return from new 2");
               errorArgs[1] = "new "ch" "prefixexp;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }
         }
         previous_id = "";
         if (!isjava && !_LanguageInheritsFrom("js") && !_LanguageInheritsFrom("e")) {
            rt.pointer_count=1;
         }
         break;
      }
      // drop through, treat it as an identifier

   case "const_cast":
   case "static_cast":
   case "dynamic_cast":
   case "reinterpret_cast":
   case "decltype":
   case "typeof":
   case "__typeof":
   case "__typeof__":
   case "_If":
   case "enable_if":
   case "enable_if_t":
   case "_Is_simple_alloc":
   case "is_same":
   case "noexcept":
      {
         special_status := _c_get_type_of_special_case_id(errorArgs, 
                                                          tag_files, isjava, 
                                                          ch, prefixexp, 0, 
                                                          symbol, search_class_name, 
                                                          rt, visited, depth+1);
         if (special_status == 0 || special_status == VSCODEHELPRC_BUILTIN_TYPE) {
            break;
         }
      }
      // drop through, treat it as an identifier

   default:

      // is this a literal constant
      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: identifier="ch);
      }
      if (rt.return_type=="" && _c_get_type_of_constant(ch, rt, depth+1) == 0) {
         if (_LanguageInheritsFrom("d") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom("jsl")) {
            box_type := _c_get_boxing_conversion(rt.return_type);
            if (box_type != "") {
               rt.return_type = box_type;
            }
         } else if (_LanguageInheritsFrom("e") && ch=="0") {
            box_type := _e_get_control_name_type("int",symbol);
            if (box_type != "") {
               rt.return_type = box_type;
            }
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part: CONSTANT ch="ch" type="rt.return_type);
         }
         return 0;
      }

      // C++11 user defined literal?
      if (rt.return_type=="" && pos(RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL, ch, 1, "UI") == 1 && _last_char(ch)!='"') {
         rt.pointer_count = 0;
         rt.taginfo = "";
         previous_id = ch;
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               SE_TAG_FILTER_PROCEDURE, 
                                               context_flags:0, 
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  C++ User-defined string operator: previous_id="ch" type="rt.return_type" pointer_count="rt.pointer_count);
         }
         previous_id = "";
         _maybe_strip(prefixexp, '.');
         return 0;
      }

      if (_LanguageInheritsFrom("m") &&
          (prefixexp :== "") &&
          (prefix_flags & VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE) &&
          (previous_id != "" || rt.return_type != "")) {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C: ["full_prefixexp"]");
         }
         if (previous_id != "") {
            status = _c_get_return_type_of_symbol(errorArgs, 
                                                  tag_files,
                                                  previous_id, 
                                                  rt.return_type, 
                                                  isjava,
                                                  SE_TAG_FILTER_ANY_DATA|SE_TAG_FILTER_ANY_STRUCT,
                                                  context_flags:0,
                                                  maybe_class_name:true, 
                                                  substituteTemplateArguments:false, 
                                                  actualFunctionArguments:null, 
                                                  rt, 
                                                  visited, 
                                                  depth+1);
            if (status) {
               return status;
            }
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C receiver: previous_id="previous_id" type="rt.return_type" pointer_count="rt.pointer_count);
         }
         if (rt.pointer_count == 0) {
            rt.return_flags = VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         } else if (rt.pointer_count != 1) {
            errorArgs[1] = current_id;
            return (VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
         }
         rt.pointer_count = 0;
         rt.taginfo = "";
         previous_id = ch;
         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               SE_TAG_FILTER_PROCEDURE, 
                                               context_flags:0, 
                                               maybe_class_name:false, 
                                               substituteTemplateArguments:false, 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
         if (status) {
            return status;
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C selector: previous_id="previous_id" type="rt.return_type);
         }
         previous_id = "";
         return 0;
      }

      // hack to handle C# and J# @keyword nonsense
      if (substr(ch,1,1)=="@" && (_LanguageInheritsFrom("cs") || _LanguageInheritsFrom("jsl"))) {
         ch=substr(ch,2);
      }

      // this must be an identifier (or drop-through case)
      previous_id = ch;
      if (rt.return_type=="" && (isjava || _LanguageInheritsFrom("pl") || _LanguageInheritsFrom("e"))) {
         // search ahead and try to match up package name
         package_name := previous_id;
         orig_prefix  := prefixexp;
         while (orig_prefix != "") {
            //say("package_name="package_name);
            int package_index = tag_check_for_package(previous_id, tag_files, true, true, null, visited, depth+1);
            if (package_index <= 0 && tag_check_for_package(package_name, tag_files, true, true, null, visited, depth+1)) {
               //isay(depth, "_c_get_type_of_part: package_name="package_name);
               rt.return_type = package_name;
               previous_id = "";
               prefixexp = orig_prefix;
            } else if (package_index > 0) {
               renamed_to := "";
               if (package_index==1) {
                  tag_get_detail(VS_TAGDETAIL_return, renamed_to);
               } else {
                  tag_get_detail2(VS_TAGDETAIL_context_return, package_index-1, renamed_to);
               }
               if (renamed_to=="") {
                  renamed_to=package_name;
               }
               //say("_c_get_type_of_part: package_index="package_index" renamed_to="renamed_to);
               if (renamed_to!="" && tag_check_for_package(renamed_to, tag_files, true, true, null, visited, depth+1)) {
                  package_name = renamed_to;
               }
               //isay(depth, "_c_get_type_of_part: package_name="package_name);
               rt.return_type = package_name;
               previous_id = "";
               //say("found package "package_name);
               prefixexp = orig_prefix;
            }
            ch = _c_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch != "." && ch != "::" &&
                (!_LanguageInheritsFrom("c") || !_LanguageInheritsFrom("pl") || ch != "->")) {
               break;
            }
            sepch := ch;
            ch = _c_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch == "" || !isid_valid(ch)) {
               break;
            }
            package_name :+= sepch :+ ch;
         }
         // DJB (12-08-2005)
         // If the package lookahead turns up a single-level package name,
         // such as "System" in J#, pretend it didn't happen, because it
         // could also match an imported class name
         if (_LanguageInheritsFrom("jsl") && rt.return_type!="" && !pos(".",rt.return_type)) {
            previous_id = rt.return_type;
            rt.return_type = "";
         }
      }
      break;
   }

   // successful so far, cool.
   //isay(depth, "_c_get_type_of_part: success");
   return 0;
}

/**
 * Utility function for parsing the next part of the prefix expression. 
 * This version is used specifically when the next item is a special keyword 
 * or identifier, for example "decltype" or "noexcept" or "nullptr". 
 *  
 * This is called repeatedly by _c_get_type_of_prefix (below) as it
 * parses the prefix expression from left to right, tracking the return
 * type as it goes along.
 * <P>
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_
 * @param tag_files           list of extension specific tag files
 * @param previous_id         the last identifier seen in the prefix expression
 * @param ch                  the last token removed from the prefix expression
 *                            (parsed out using _c_get_expr_token, above)
 * @param prefixexp           (reference) The remainder of the prefix expression
 * @param full_prefixexp      The entire prefix expression
 * @param rt                  (reference) set to return type result
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               depth of recursion (for handling typedefs)
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param symbol              name of symbol corresponding to current context 
 * @param search_class_name   class name of current context 
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _c_get_type_of_special_case_id( _str (&errorArgs)[], 
                                           typeless tag_files, bool isjava,
                                           _str ch, _str &prefixexp,
                                           CodeHelpExpressionPrefixFlags prefix_flags,
                                           _str symbol, _str search_class_name,
                                           struct VS_TAG_RETURN_TYPE &rt,
                                           struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth, "_c_get_type_of_special_case_id: IN ch="ch);
      tag_return_type_dump(rt, "_c_get_type_of_special_case_id: IN rt=", depth);
   }
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   status   := 0;
   num_args := 0;
   orig_prefixexp := prefixexp;
   switch (ch) {
   
   case "const_cast":
   case "static_cast":
   case "dynamic_cast":
   case "reinterpret_cast":
      // check for C++ style cast expressions
      if (_LanguageInheritsFrom("c") && _first_char(prefixexp) == '<') {
         cast_ch := ch;
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found C++ style cast expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         prefixexp = strip(prefixexp, "L");
         if (_first_char(prefixexp) == "<") {
            prefixexp = substr(prefixexp, 2);
            num_type_args := 0;
            if (match_generic(prefixexp, auto cast_type, num_type_args, "<>,")) {
               prefixexp = strip(prefixexp, "L");
               if (_first_char(prefixexp) == "(") {
                  prefixexp = substr(prefixexp, 2);
                  cast_expression := "";
                  num_cast_args := 0;
                  if (match_generic(prefixexp, cast_expression, num_cast_args, "(),")) {
                     ch = ")";
                     previous_id := "";
                     if (cast_type == "" && cast_ch=="const_cast" && cast_expression != "") {
                        // support type-inferred const_cast<> expression
                        status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                           "", "", "", 
                                                           VSCODEHELP_PREFIX_NULL, 
                                                           cast_expression, 
                                                           rt, visited, depth+1);
                        rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
                        rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
                     } else {
                        status = _c_parse_return_type(errorArgs, tag_files,
                                                      "", "", p_buf_name,
                                                      cast_type, isjava, 
                                                      rt, visited, depth+1);
                     }
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY;
                     if (_chdebug) {
                        isay(depth,"_c_get_type_of_special_case_id: prefixexp="prefixexp" ch="ch" status="status);
                        tag_return_type_dump(rt, "_c_get_type_of_special_case_id(C++ cast)", depth);
                     }
                     return status;
                  }
               }
            }
            prefixexp = orig_prefixexp;
         }
      }
      break;

   // D language typeof(x) type expressions
   // C++ language decltype(x) type expressions
   case "decltype":
   case "typeof":
   case "__typeof":
   case "__typeof__":
      if ((_LanguageInheritsFrom("d") && (ch:=="typeof") && _first_char(prefixexp)=="(") ||
          (_LanguageInheritsFrom("c") && (ch:=="decltype" || ch == "typeof" || ch:=="__typeof" || ch:=="__typeof__") && _first_char(prefixexp)=="(")) {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found DECLTYPE or TYPEOF expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         gnu_typeof_operator := (pos("typeof",ch) >= 0 && _LanguageInheritsFrom("c"));
         ch = "("; 
         prefixexp = substr(prefixexp,2);
         typeof_exp := "";
         if (!match_parens(prefixexp, typeof_exp, num_args)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         VS_TAG_RETURN_TYPE typeof_rt;
         tag_return_type_init(typeof_rt);
         typeof_rt = rt;
         status = _c_get_type_of_expression(errorArgs, tag_files, 
                                            "", "", "", 
                                            VSCODEHELP_PREFIX_NULL, 
                                            expr:typeof_exp, 
                                            typeof_rt, 
                                            visited, depth+1);
         if (gnu_typeof_operator) {
            typeof_rt.return_flags &= VSCODEHELP_RETURN_TYPE_REF;
         }
         if (status) return status;
         rt = typeof_rt;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_special_case_id: TYPEOF expr="typeof_exp" typeof_rt="typeof_rt.return_type);
         }
         return status;
      }
      if ((_LanguageInheritsFrom("cs") && (ch:=="typeof") && _first_char(prefixexp)=="(")) {
         ch = "("; 
         prefixexp = substr(prefixexp,2);
         typeof_exp := "";
         if (!match_parens(prefixexp, typeof_exp, num_args)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         VS_TAG_RETURN_TYPE typeof_rt;
         tag_return_type_init(typeof_rt);
         typeof_rt.return_type = "System/Type";
         typeof_rt.taginfo = "Type(System:class)";
         //typeof_rt.return_flags = VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         rt = typeof_rt;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_special_case_id: TYPEOF expr="typeof_exp" typeof_rt="typeof_rt.return_type);
         }
         return 0;
      }
      break;
         
   // C++ language noexcept(x) expression
   case "noexcept":
      if ((_LanguageInheritsFrom("c") && _first_char(prefixexp)=="(")) {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found NOEXCEPT expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         ch = "("; 
         prefixexp = substr(prefixexp,2);
         noexcept_exp := "";
         if (!match_parens(prefixexp, noexcept_exp, num_args)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }

         // evalute all of the actual function arguments
         no_exceptions_found := true;
         item_pos := 0;
         item_str := "";
         while (tag_get_next_argument(noexcept_exp, item_pos, item_str) >= 0) {
            //say("cb_next_arg returns "argument);
            tag_return_type_init(auto item_rt);
            arg_status := _c_get_type_of_expression(errorArgs, tag_files, symbol, search_class_name, p_buf_name, 0, item_str, item_rt, visited, depth+1);
            if (arg_status == 0 || arg_status == VSCODEHELPRC_BUILTIN_TYPE) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_special_case: NOEXCEPT: ARGUMENT, expr="item_str);
                  tag_return_type_dump(item_rt, "_c_get_type_of_special_case: NOEXCEPT: ARGUMENT TYPE", depth);
               }
               tag_decompose_tag_browse_info(item_rt.taginfo, auto item_cm);
               if (item_cm.exceptions != null && item_cm.exceptions != "") {
                  no_exceptions_found = false;
                  break;
               }
            }
         }
         rt.return_type = no_exceptions_found? "true" : "false";
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case: NOEXCEPT ch="ch" type="rt.return_type);
         }
         return 0;
      }
      break;

   case "_Is_simple_alloc":
      if (_LanguageInheritsFrom("c") && _first_char(prefixexp)=="<") {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found IS_SIMPLE_ALLOC expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         ch = "<"; 
         simple_template_prefixexp := substr(prefixexp,2);
         _str simple_template_parms[];
         if (!match_templates(simple_template_prefixexp, simple_template_parms)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH;
         }
         rt.return_type = "true";
         prefixexp = simple_template_prefixexp;
         if (substr(prefixexp,1,7) == "::value") {
            prefixexp = substr(prefixexp, 8);
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: IS_SIMPLE_ALLOC ch="ch" type="rt.return_type);
         }
         return 0;
      }
      break;

   case "is_same":
      if (_LanguageInheritsFrom("c") && _first_char(prefixexp)=="<") {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found IS_SAME expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         ch = "<"; 
         same_template_prefixexp := substr(prefixexp,2);
         _str same_template_parms[];
         if (!match_templates(same_template_prefixexp, same_template_parms)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH;
         }
         if (same_template_parms._length() == 2) {
            // evaluate the first parameter and see if it is 'false'
            prefixexp = same_template_prefixexp;
            if (substr(prefixexp,1,7) == "::value") {
               prefixexp = substr(prefixexp, 8);
            }
            VS_TAG_RETURN_TYPE left_rt;
            tag_return_type_init(left_rt);
            left_rt = rt;
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:same_template_parms[0], 
                                               left_rt, visited, depth+1);
            if (status) left_rt.return_type = same_template_parms[0];
            // Evaluate the type of the second parameter for 'false', the first otherwise
            VS_TAG_RETURN_TYPE right_rt;
            tag_return_type_init(right_rt);
            right_rt = rt;
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:same_template_parms[1], 
                                               right_rt, visited, depth+1);
            if (status) left_rt.return_type = same_template_parms[0];
            // And then compare the results
            rt.return_type = tag_return_type_equal(left_rt,right_rt)? "true" : "false";
            if (_chdebug) {
               isay(depth,"_c_get_type_of_special_case_id: IS_SAME ch="ch" type="rt.return_type);
            }
            return 0;
         }
      }
      break;

   case "_If":
   case "enable_if":
   case "enable_if_t":
      if (_LanguageInheritsFrom("c") && _first_char(prefixexp)=="<") {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_special_case_id: found IF / ENABLE_IF expression: "ch" prefixexp="prefixexp);
            isay(depth,"_c_get_type_of_special_case_id: search_class_name=: "search_class_name);
            tag_return_type_dump(rt, "_c_get_type_of_special_case_id", depth);
         }
         ch = "<"; 
         if_template_prefixexp := substr(prefixexp,2);
         _str if_template_parms[];
         if (!match_templates(if_template_prefixexp, if_template_parms)) {
            errorArgs[1] = orig_prefixexp;
            return VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH;
         }
         if (if_template_parms._length() == 3) {
            // evaluate the first parameter and see if it is 'false'
            prefixexp = if_template_prefixexp;
            if (substr(prefixexp,1,7) == "::value") {
               prefixexp = substr(prefixexp, 8);
            } else if (substr(prefixexp,1,7) == "::type") {
               prefixexp = substr(prefixexp, 7);
            }
            VS_TAG_RETURN_TYPE value_rt;
            tag_return_type_init(value_rt);
            value_rt = rt;
            if (_chdebug) {
               isay(depth,"_c_get_type_of_special_case_id: IF expr="if_template_parms[0]);
            }
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:if_template_parms[0], 
                                               value_rt, visited, depth+1);
            if (status) value_rt.return_type = if_template_parms[0];
            // Evaluate the type of the second parameter for 'false', the first otherwise
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            typeof_rt = rt;
            if_template_index := (if_template_parms[0]=="false" || value_rt.return_type=="false")? 2:1;
            if (_chdebug) {
               isay(depth,"_c_get_type_of_special_case_id: IF choice="if_template_parms[if_template_index]);
            }
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:if_template_parms[if_template_index], 
                                               typeof_rt, 
                                               visited, depth+1);
            // And then use the result
            if (status) return status;
            rt = typeof_rt;
            if (_chdebug) {
               isay(depth,"_c_get_type_of_special_case_id: IF ch="ch" type="rt.return_type);
            }
            return 0;
         }
      }
      break;

   default:
      // this case is not handled here
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   return 0;

}

/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param tag_files           List of tag files to use
 * @param symbol              name of symbol corresponding to current context 
 * @param search_class_name   class name of current context 
 * @param file_name           file name where symbol is located
 * @param expr                Prefix expression 
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param rt                  (reference) return type structure
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_expression(_str (&errorArgs)[], 
                              typeless tag_files,
                              _str symbol, 
                              _str search_class_name,
                              _str file_name,
                              CodeHelpExpressionPrefixFlags prefix_flags,
                              _str expr, 
                              struct VS_TAG_RETURN_TYPE &rt,
                              struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_get_type_of_expression: ===================================================");
      isay(depth,"_c_get_type_of_expression(expr="expr")");
      if (_isEditorCtl()) {
         isay(depth, "_c_get_type_of_expression: p_buf_name="p_buf_name);
         isay(depth, "_c_get_type_of_expression: p_RLine="p_RLine);
      }
   }
   orig_expr := expr;
   ref_count := 0;
   while (substr(expr,1,1) == "&" || substr(expr,1,1) == "*") {
      if (substr(expr,1,1) == "&") {
         ref_count++;
      } else {
         ref_count--;
      }
      expr = strip(substr(expr, 2));
   }
   if (_chdebug) {
      isay(depth,"_c_get_type_of_expression(stripped="expr", ref_count="ref_count")");
   }

   status := _c_get_type_of_prefix_recursive(errorArgs, tag_files,
                                             expr, rt, 
                                             visited, depth+1, prefix_flags,
                                             symbol, search_class_name);
   if (!status) {
      if (ref_count < 0) {
         // maybe they overloaded operator *
         while (ref_count < 0 && _LanguageInheritsFrom("c")) {
            // simple pointer dereference
            if (rt.pointer_count > 0) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_expression: DEREFERENCE POINTER");
               }
               rt.pointer_count--;
               ref_count++;
               continue;
            }
            // has to be operator *
            if (_LanguageInheritsFrom("c")) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_expression: TRYING TO FIND OPERATOR *");
               }
               status = _c_get_return_type_of_symbol(errorArgs,
                                                     tag_files,
                                                     "*", 
                                                     rt.return_type, 
                                                     isjava:false,
                                                     SE_TAG_FILTER_ANY_PROCEDURE, 
                                                     context_flags:0,
                                                     maybe_class_name:false, 
                                                     substituteTemplateArguments:true, 
                                                     actualFunctionArguments:null, 
                                                     rt, 
                                                     visited, 
                                                     depth+1);
               if (!status) {
                  ref_count++;
                  continue;
               }
            }
            // error
            if (_chdebug) {
               isay(depth,"_c_get_type_of_expression: DEREFERENCE BUT NOT A POINTER");
            }
            errorArgs[1] = "*";
            errorArgs[2] = orig_expr;
            status = VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER;
            break;
         }
      }
      if (!status && rt != null && rt.pointer_count+ref_count >= 0) {
         rt.pointer_count += ref_count;
      }
   }
   return status;
}

/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param tag_files           List of tag files to use
 * @param prefixexp           Prefix expression
 * @param rt                  (reference) return type structure
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               (optional) depth of recursion
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param symbol              name of symbol corresponding to current context 
 * @param search_class_name   class name of current context 
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_prefix_recursive(_str (&errorArgs)[], typeless tag_files,
                                    _str prefixexp, struct VS_TAG_RETURN_TYPE &rt,
                                    struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0,
                                    CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL,
                                    _str symbol="", _str search_class_name="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth,"_c_get_type_of_prefix: ===================================================");
      isay(depth,"_c_get_type_of_prefix("prefixexp", symbol="symbol", search_class_name="search_class_name")");
   }

   // Is this Java source code or something very similar?
   isjava := (_LanguageInheritsFrom("java") ||
              _LanguageInheritsFrom("cs") ||
              _LanguageInheritsFrom("groovy") ||
              _LanguageInheritsFrom("kotlin") ||
              _LanguageInheritsFrom("scala") ||
              _LanguageInheritsFrom("d") ||
              _LanguageInheritsFrom("cfscript"));

   // initiialize return values
   status := 0;
   rt.return_type   = "";
   rt.pointer_count = 0;
   rt.return_flags  = 0;

   // loop variables
   full_prefixexp := prefixexp;
   previous_id    := "";
   found_define   := false;

   // save the arguments, for retries later
   orig_rt          := rt;
   orig_prefixexp   := prefixexp;
   orig_previous_id := previous_id;

   // process the prefix expression, token by token, delegate
   // most of processing to recursive func _c_get_type_of_part
   while (prefixexp != "") {

      // get next token from expression
      ch := _c_get_expr_token(prefixexp);
      if (_chdebug) {
         isay(depth, "_c_get_type_of_prefix_recursive: parsed "ch", remaining:"prefixexp);
      }

      if (ch == "") {
         // special case for expression ending with brace initializer
         prefixexp = strip(prefixexp);
         if (_first_char(prefixexp) == '{' && _last_char(prefixexp) == '}') {
            break;
         }
         // don't recognize something we saw
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }

      // expand preprocessing macro if we see one.
      id_defined_to := "";
      id_arglist := "";
      if (_LanguageInheritsFrom("c") && isid_valid(ch) &&
          !_CheckTimeout() && depth < 10 &&
          tag_check_for_define(ch, p_line, tag_files, id_defined_to, id_arglist)) {
         if (id_defined_to != ch) {
            define_prefixexp := prefixexp;
            if (id_arglist != "" && _first_char(prefixexp) == "(" && pos(")",prefixexp) > 0) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_prefix_recursive: expanding #define "ch"("id_arglist") "id_defined_to);
               }
               define_parenexp  := "";
               define_arg_name  := "";
               define_arg_value := "";
               define_num_args  := 0;
               define_cur_arg   := 0;
               define_prefixexp = substr(prefixexp,2);
               match_parens(define_prefixexp,define_parenexp,define_num_args);
               argnames_pos := 0;
               arglist_pos := 0;
               id_defined_to = stranslate(id_defined_to, "\1\2", "##");
               for (define_cur_arg=0; define_cur_arg < define_num_args; define_cur_arg++) {
                  tag_get_next_argument(define_parenexp, arglist_pos, define_arg_value);
                  tag_get_next_argument(id_arglist, argnames_pos, define_arg_name);
                  define_arg_name = strip(define_arg_name);
                  define_arg_value = strip(define_arg_value);
                  id_defined_to = stranslate(id_defined_to, _dquote(define_arg_value), "#"define_arg_name, "ew");
                  id_defined_to = stranslate(id_defined_to, define_arg_value, define_arg_name, "ew");
               }
               id_defined_to = stranslate(id_defined_to, "", "\1\2");
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_prefix_recursive: expanded #define = "id_defined_to);
               }
            } else {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_prefix_recursive: expanding #define "ch" "id_defined_to);
               }
            }
            define_rt := rt;
            define_status := _c_get_type_of_prefix_recursive(errorArgs,tag_files,id_defined_to:+define_prefixexp,define_rt,visited,depth+1,prefix_flags,ch,"");
            if (define_status == 0 || define_status == VSCODEHELPRC_BUILTIN_TYPE) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_prefix_recursive: expanded #define "ch" "id_defined_to);
               }
               rt = define_rt;
               prefixexp = define_prefixexp;
               return 0;
            }
            if (_chdebug) {
               isay(depth,"_c_get_type_of_prefix_recursive: #define expansion failed");
            }
         }
      }

      // process this part of the prefix expression
      status = _c_get_type_of_part(errorArgs, tag_files, isjava,
                                   previous_id, ch, prefixexp, full_prefixexp,
                                   rt, visited, depth+1, prefix_flags,
                                   symbol, search_class_name);

      if (_chdebug) {
         isay(depth,"_c_get_type_of_prefix: prefixexp="prefixexp" ch="ch" status="status);
         tag_return_type_dump(rt, "_c_get_type_of_prefix", depth);
      }

      if (status && found_define) {
         //isay(depth,"_c_get_type_of_prefix: FAIL and retry with "orig_previous_id" instead of "previous_id);
         // try the original ID, not what the define said it was
         prefixexp        = orig_prefixexp;
         previous_id      = orig_previous_id;
         rt               = orig_rt;
         status = _c_get_type_of_part(errorArgs, tag_files, isjava,
                                      previous_id, ch, prefixexp, full_prefixexp,
                                      rt, visited, depth+1, prefix_flags);
         //isay(depth,"_c_get_type_of_prefix: status="status);
         //tag_return_type_dump(rt, "_c_get_type_of_prefix", depth);
      }
      // We do not want this function to return NO SYMBOLS FOUND becasue
      // that error code is used specifically by references to indicate that
      // we could not find a symbol at all.  In this case, the symbol we
      // could not find was part of a prefix expression, so this means we
      // were unable to compute the return type of the prefix expression.
      if (status == VSCODEHELPRC_NO_SYMBOLS_FOUND) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
      if (status) {
         return status;
      }

      // check if 'previous' ID was a define
      found_define = false;
      orig_previous_id = previous_id;
      if (!isjava && isid_valid(previous_id) && 
          tag_find_local_iterator(previous_id,true,true,false,"") < 0 &&
          tag_check_for_class(ch, rt.return_type, true, tag_files, visited, depth+1) <= 0 && 
          tag_check_for_define(previous_id, p_line, tag_files, previous_id)) {
         if (previous_id != orig_previous_id) {
            found_define=true;
         }
      }

      // save the arguments, for retries later
      orig_prefixexp       = prefixexp;
      orig_rt              = rt;
   }

   if (previous_id != "") {
      if (_chdebug) {
         isay(depth, "_c_get_type_of_prefix_recursive: before previous_id="previous_id" match_class="rt.return_type);
      }
      var_filters := SE_TAG_FILTER_ANY_DATA;
      if (!isjava) {
         var_filters |= SE_TAG_FILTER_ANY_PROCEDURE;
      }
      if (prefix_flags & VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE) {
         var_filters |= SE_TAG_FILTER_STRUCT;
      }
      if (rt.taginfo != "") {
         rt_tag_type := tag_get_tag_type_of_return_type(rt);
         if (tag_tree_type_is_package(rt_tag_type)) {
            var_filters |= SE_TAG_FILTER_PACKAGE;
            var_filters |= SE_TAG_FILTER_STRUCT;
         } else if (tag_tree_type_is_class(rt_tag_type)) {
            var_filters |= SE_TAG_FILTER_STRUCT;
            var_filters |= SE_TAG_FILTER_TYPEDEF;
         }
      } else if (tag_check_for_package(previous_id, tag_files, true, true, null, visited, depth+1)) {
         var_filters |= SE_TAG_FILTER_PACKAGE;
         var_filters |= SE_TAG_FILTER_STRUCT;
      } else if (tag_check_for_class(previous_id, "", true, tag_files, visited, depth+1)) {
         var_filters |= SE_TAG_FILTER_STRUCT;
         var_filters |= SE_TAG_FILTER_TYPEDEF;
      }

      status = _c_get_return_type_of_symbol(errorArgs, 
                                            tag_files, 
                                            previous_id, 
                                            rt.return_type, 
                                            isjava,
                                            var_filters, 
                                            context_flags:0, 
                                            maybe_class_name:true, 
                                            substituteTemplateArguments: (prefixexp!=""), 
                                            actualFunctionArguments:null, 
                                            rt, 
                                            visited, 
                                            depth+1);
      if (status && found_define) {
         // try the original ID, not what the define said it was
         prefixexp        = orig_prefixexp;
         rt               = orig_rt;
         previous_id      = orig_previous_id;

         status = _c_get_return_type_of_symbol(errorArgs, 
                                               tag_files, 
                                               previous_id, 
                                               rt.return_type, 
                                               isjava,
                                               var_filters, 
                                               context_flags:0, 
                                               maybe_class_name:true, 
                                               substituteTemplateArguments: (prefixexp!=""), 
                                               actualFunctionArguments:null, 
                                               rt, 
                                               visited, 
                                               depth+1);
      }
      // We do not want this function to return NO SYMBOLS FOUND becasue
      // that error code is used specifically by references to indicate that
      // we could not find a symbol at all.  In this case, the symbol we
      // could not find was part of a prefix expression, so this means we
      // were unable to compute the return type of the prefix expression.
      if (status == VSCODEHELPRC_NO_SYMBOLS_FOUND) {
         errorArgs[1] = previous_id;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
      if (status) {
         return status;
      }
      previous_id = "";
      //say("after previous_id="previous_id" match_class="rt.return_type" match_tag="rt.taginfo);
   }

   // is the current token a builtin?
   if (rt.pointer_count==0 && _c_is_builtin_type(rt.return_type)) {
      // is the current token a builtin?
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
      box_type := _c_get_boxing_conversion(rt.return_type);
      if (box_type != "") {
         rt.return_type = box_type;
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         return 0;
      }  
      if (_c_is_builtin_type(rt.return_type,true)) {
         return 0;
      }
      errorArgs[1]=previous_id;
      errorArgs[2]=rt.return_type;
      return VSCODEHELPRC_BUILTIN_TYPE;
   }

   if (_chdebug) {
      isay(depth,"_c_get_type_of_prefix: returns "rt.return_type);
   }
   return 0;
}


/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param prefixexp           Prefix expression
 * @param rt                  (reference) return type structure
 * @param depth               (optional) depth of recursion 
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param search_class_name   current package/class scope 
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                          struct VS_TAG_RETURN_TYPE &rt, 
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL, 
                          _str search_class_name="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   lang := _isEditorCtl()? p_LangId : "";
   tag_files := tags_filenamea(lang);
   tag_push_matches();
   status := _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth, prefix_flags, "", search_class_name);
   tag_pop_matches();
   return status;
}


