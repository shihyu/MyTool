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
#include "autocomplete.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/ui/HotspotMarkers.e"
#import "adaptiveformatting.e"
#import "beautifier.e"
#import "c.e"
#import "caddmem.e"
#import "ccontext.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "pmatch.e"
#import "seek.e"
#import "stdprocs.e"
#import "tags.e"
#import "setupext.e"
#import "smartp.e"
#import "stdcmds.e"
#import "se/tags/TaggingGuard.e"
#endregion

using se.lang.api.LanguageSettings;
using se.ui.HotspotMarkers;

extern int _ObjectiveCReceiverInfo(_str expr, _str &result);
extern int _ObjectiveCSignatureInfo(_str expr, _str &signature, _str &receiver, int &arg_count, int &in_selectorid, int &func_offset, int &arg_offset);
extern int _ObjectiveCMethodDeclInfo(_str expr, _str &signature, int &arg_count, int &in_selectorid);

/* =========== Objective-c/c++ Tagging Support ================== */
/**
 * Activates Objective-C file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void objc_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage("m");
}

int _m_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex, tagfilename, "c", "ucpp") && !forceRebuild) {
      return(0);
   }

   // recycling didn't work, might have to build tag files
   tfindex=0;
   return(0);
}

// Starting from/inside @class/@interface/@implemenation/@protocol or method decl, find next method
int _objectivec_find_next_class_decl(typeless orig_point)
{
   nesting := 0;
   status := search('[-+{}]|\@(end|optional|required|dynamic|synthesize|property)','@rhxcs');
   for (;;) {
      if (status) {
         break;
      }
      offset := (int)point('s');
      if (offset > orig_point) {
         return(-1);
      }

      switch (get_match_text()) {
      case "-":
      case "+":
         if (!nesting) {
            return(0);
         }
         break;

      case "@optional":
      case "@required":
      case "@dynamic":
      case "@synthesize":
      case "@property":
         return(0);

      case "{":
         ++nesting;
         break;

      case "}":
         --nesting;
         if (nesting < 0) {
            return(-1);
         }
         break;

      case "@end":
         return(-1);
      }

      status = repeat_search();
   }
   return(-1);
}

/**
 * @see _c_get_type_of_expression
 */
int _m_get_type_of_expression(_str (&errorArgs)[], 
                               typeless tag_files,
                               _str symbol, 
                               _str search_class_name,
                               _str file_name,
                               CodeHelpExpressionPrefixFlags prefix_flags,
                               _str expr, 
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   _StackDump();
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 *
 *  If in specific Objective-C context, info will be set accordingly.
 *
 *  flags:       VSAUTOCODEINFO_OBJECTIVEC_CONTEXT
 *  otherinfo:   ""           in message expression, method name
 *               ":id:id:id"  in message expression, named parameter
 *               "@method"    in method declaration, method name
 *               "-id:id:id"  in method declaration, named parameter
 *               "@selector"  in @selector() expression
 *               "@protocol"  in @protocol() expression or interface declaration with protocol
 *
 */
int _m_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   save_pos(auto orig_pos);
   do {
      if (_chdebug) {
         isay(depth, "_m_get_expression_info: OFFSET="_QROffset()", LINE="p_line", COL="p_col);
      }
      cfg := _clex_find(0, 'g');
      if (cfg == CFG_COMMENT || cfg == CFG_STRING || cfg == CFG_NUMBER ||
          cfg == CFG_KEYWORD || cfg == CFG_PPKEYWORD) {
         break;
      }

      orig_point := (int)point('s');
      //possible operator is fudged for space key
      if (PossibleOperator) {
         left();
         if (get_text_safe() != " ") {
            break;
         }
         right();
      }

      lastid := "";
      lastid_col := p_col;
      lastid_offset := (int)point('s');
      word_chars := _clex_identifier_chars();
      bracket_count := 0;
      ch := get_text_safe();
      if (ch == ":") {
         // bail if scope operator "::"
         if (get_text_safe(2) == "::") {
            break;
         }
         left();
         if (get_text_safe() == ":") {
            break;
         }

      } else if (ch == ")" || ch == "}" || ch == ";") {
         left();

      } else if (ch == "]") {
         bracket_count++;
      }

      in_msg := _objectivec_message_statement(bracket_count, 
                                              auto indent_col, 
                                              auto bracket_col, 
                                              auto arg_col, 
                                              auto arg_count, 
                                              arg_align:false, 
                                              bracket_pos:true, 
                                              depth+1);
      if (in_msg) {
         if (_chdebug) {
            isay(depth, "_m_get_expression_info: Objective-C [message] OFFSET="_QROffset()", LINE="p_line", COL="p_col);
         }
         // only care about first selector id with space
         if (PossibleOperator && arg_count > 0) {
            break;
         }

         prefix_offset := (int)point('s');
         start_msg := _QROffset();

         restore_pos(orig_pos);
         if (PossibleOperator) {
            search('[~ \t]|$','r@');
         }
         ch = get_text_safe();
         if (pos('[~'word_chars']', ch, 1, 'r')) {
            left();
            ch = get_text_safe();
         }
         if (pos('['word_chars']', ch, 1, 'r')) {
            search('[~'word_chars']\c|^\c','-rh@');

            if (p_col <= lastid_col) {
               lastid_col = p_col;
               lastid_offset = (int)point('s');
               search('[~'word_chars']|$','rh@');
               lastid = _expand_tabsc(lastid_col, p_col - lastid_col);
            } else {
               search('[~'word_chars']|$','rh@');
            }

         } else if (ch == ":") {
            right();
            ch = get_text_safe();
            if (ch == " ") {
               left();
               ch = get_text_safe();
            }
         }

         end_msg := _QROffset();
         msg := get_text_safe((int)(end_msg - start_msg), (int)start_msg);
         if (_ObjectiveCSignatureInfo(msg, auto signature, auto receiver, arg_count, auto in_selector, auto func_offset, auto arg_offset)) {
            if (_chdebug) {
               isay(depth, "_m_get_expression_info H"__LINE__": FAILED TO GET Objective-C signature info");
            }
            restore_pos(orig_pos);
            return _c_get_expression_info(PossibleOperator, info, visited, depth+1);
         }
         if (_chdebug) {
            isay(depth, "_m_get_expression_info: Objective-C signature="signature" receiver="receiver" arg_count="arg_count);
         }
         if (receiver != "") {
            if (arg_count < 0) {
               if (PossibleOperator && signature != "") {
                  // only care here if signature is empty
                  break;
               }
               restore_pos(orig_pos);
               if (lastid == signature) {
                  info.lastid = signature;
                  info.lastidstart_col = lastid_col;
                  info.lastidstart_offset = lastid_offset;
                  info.prefixexp = receiver;
                  info.prefixexpstart_offset = prefix_offset;
                  info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
                  info.otherinfo = "";
                  return(0);
               }

            } else if (in_selector) {
               restore_pos(orig_pos);
               info.lastid = lastid;
               info.lastidstart_col = lastid_col;
               info.lastidstart_offset = lastid_offset;
               info.prefixexp = receiver;
               info.prefixexpstart_offset = prefix_offset;
               info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
               info.otherinfo = ":"signature;
               return(0);
            }
         }
         break;

      } else {
         // could be selector declaration
         if (indent_col > 0) {
            ch = get_text_safe();
            cfg = _clex_find(0, 'g');
            if (cfg == CFG_KEYWORD && ch == "@") {
               word := cur_word(auto junk);
               switch ("@"word) {
               case "@class":
               case "@interface":
               case "@implementation":
               case "@protocol":
                  if (!_objectivec_find_next_class_decl(orig_point)) {
                     ch = get_text_safe();
                  }
               }
            }

            if (ch == "-" || ch == "+") {
               prefix_offset := (int)point('s');
               start_msg := _QROffset();
               if (prefix_offset < orig_point) {
                  restore_pos(orig_pos);
                  ch = get_text_safe();
                  if (pos('[~'word_chars']', ch, 1, 'r')) {
                     left();
                     ch = get_text_safe();
                  }
                  if (pos('['word_chars']', ch, 1, 'r')) {
                     search('[~'word_chars']\c|^\c','-rh@');

                     lastid_col = p_col;
                     lastid_offset = (int)point('s');

                     search('[~'word_chars']|$','rh@');
                     lastid = _expand_tabsc(lastid_col, p_col - lastid_col);
                  } else if (ch == ")") {
                     right();
                     ch = get_text_safe();
                  }
                  end_msg := _QROffset();
                  msg := get_text_safe((int)(end_msg - start_msg), (int)start_msg);
                  if (_ObjectiveCMethodDeclInfo(msg, auto signature, arg_count, auto in_selector)) {
                     break;
                  }
                  if (_chdebug) {
                     isay(depth, "_m_get_expression_info: Objective-C method signature="signature" arg_count="arg_count" in_selector="in_selector);
                  }
                  if (arg_count < 0 || in_selector) {
                     restore_pos(orig_pos);

                     info.lastid = lastid;
                     info.lastidstart_col = lastid_col;
                     info.lastidstart_offset = lastid_offset;
                     info.prefixexp = "";
                     info.prefixexpstart_offset = prefix_offset;
                     info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
                     if (arg_count < 0) {
                        info.otherinfo = "@method";
                     } else {
                        info.otherinfo = "-"signature;
                     }
                     return(0);
                  }
                  break;
               }
            }
         }
      }

      restore_pos(orig_pos);
      search('^|[~ \t]','-rh@xc');
      ch = get_text_safe();
      if (ch == ")" || ch == ";") {
         left();
         ch = get_text_safe();
         if (pos('[~'word_chars']', ch, 1, 'r')) {
            break;
         }

      } else if (ch == ":") {
         left();
         ch = get_text_safe();
      }

      if (pos('['word_chars']', ch, 1, 'r')) {
         search('[~'word_chars']|$','rh@');
         end_col := p_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');

         lastid = _expand_tabsc(p_col,end_col-p_col);
         lastid_col = p_col;
         lastid_offset = (int)point('s');
         left();
         search('^|[~ \t]','-rh@xc');
         ch = get_text_safe();

         if (ch == "(") {
            left();
            tk := c_prev_sym2();
            cfg = _clex_find(0, 'g');
            if (cfg == CFG_KEYWORD && tk == TK_ID) {
               ch = get_text_safe();

               // @selector() or @protocol()?
               if (ch == "@") {
                  if (c_sym_gtkinfo() == "selector") {
                     restore_pos(orig_pos);
                     info.lastid = lastid;
                     info.lastidstart_col = lastid_col;
                     info.lastidstart_offset = lastid_offset;
                     info.prefixexp = "self";
                     info.prefixexpstart_offset = lastid_offset;
                     info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
                     info.otherinfo = "@selector";
                     return(0);

                  } else if (c_sym_gtkinfo() == "protocol") {
                     restore_pos(orig_pos);
                     info.lastid = lastid;
                     info.lastidstart_col = lastid_col;
                     info.lastidstart_offset = lastid_offset;
                     info.prefixexp = "";
                     info.prefixexpstart_offset = lastid_offset;
                     info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
                     info.otherinfo = "@protocol";
                     return(0);
                  }
               }
            }
         }

         // arg list?
         while (ch == ",") {
            left();
            c_prev_sym2();
            if (c_sym_gtk() == TK_ID) {
               ch = c_prev_sym2();
            }
         }

         // protocol decl
         if (ch == "<") {
            if (_chdebug) {
               isay(depth, "_m_get_expression_info: Objective-C @protocol: "lastid);
            }
            status := search('[;{}()\[\]]|\@(class|interface|implementation|protocol|end)','-@rhxcs');
            if (!status) {
               switch (get_match_text()) {
               case "@interface":
               case "@protocol":
                  restore_pos(orig_pos);
                  info.lastid = lastid;
                  info.lastidstart_col = lastid_col;
                  info.lastidstart_offset = lastid_offset;
                  info.prefixexp = "";
                  info.prefixexpstart_offset = lastid_offset;
                  info.info_flags = VSAUTOCODEINFO_OBJECTIVEC_CONTEXT;
                  info.otherinfo = "@protocol";
                  return(0);

               default:
                  // everything else
                  break;
               }
            }
         }
      }
      // fall through to default handling

   } while (false);

   restore_pos(orig_pos);
   return _c_get_expression_info(PossibleOperator, info, visited, depth+1);
}

int _m_find_context_tags(_str (&errorArgs)[], _str prefixexp,
                         _str lastid, int lastidstart_offset,
                         int info_flags, typeless otherinfo,
                         bool find_parents, int max_matches,
                         bool exact_match, bool case_sensitive,
                         SETagFilterFlags filter_flags = SE_TAG_FILTER_ANYTHING,
                         SETagContextFlags context_flags = SE_TAG_CONTEXT_ALLOW_LOCALS,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                         VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tag_return_type_init(prefix_rt);
   if (info_flags & VSAUTOCODEINFO_OBJECTIVEC_CONTEXT) {
      if (_chdebug) {
         isay(depth,"_m_find_context_tags: lastid="lastid" prefixexp="prefixexp" otherinfo="otherinfo);
      }

      errorArgs._makeempty();
      tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
      num_matches := 0;

      tag_clear_matches();

      _str template_args:[];
      class_name := "";

      if (otherinfo == "@protocol") {
         tag_list_symbols_in_context(lastid, class_name, 0, 0,
                                     tag_files, "",
                                     num_matches, def_tag_max_function_help_protos,
                                     SE_TAG_FILTER_INTERFACE, 0,
                                     exact_match, case_sensitive, visited, depth+1, template_args);

      } else {
         ch := _first_char(otherinfo);
         matchSelectorID := (ch == ":" || ch == "-");
         signature := "";
         selector_id := lastid;
         filter_flags = SE_TAG_FILTER_PROCEDURE;
         context_list_flags := SE_TAG_CONTEXT_NO_GLOBALS|SE_TAG_CONTEXT_ONLY_INCLASS;

         if (otherinfo == "@method" || ch == "-") {
            context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags,
                                                  auto cur_type_name, auto cur_type_id,
                                                  auto cur_context, auto cur_class,
                                                  auto cur_package,
                                                  visited, depth+1);

            if (cur_context != "" && (cur_type_id == SE_TAG_TYPE_SELECTOR || cur_type_id == SE_TAG_TYPE_STATIC_SELECTOR)) {
               class_name = cur_context;
            }

         } else {
            // maybe prefix expression is a package name or prefix of package name
            VS_TAG_RETURN_TYPE rt; tag_return_type_init(rt);
            status := 0;
            if (prefixexp != "") {
               // evaluate the prefix expression to set up the return type 'rt'
               status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE);
               if (status) {
                  tag_pop_matches();
                  return status;
               }

               if (_chdebug) {
                  tag_return_type_dump(rt, "_m_find_context_tags");
               }
               class_name = rt.return_type;
               template_args = rt.template_args;
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
                  context_list_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
               }
               if (rt.pointer_count > 0) {
                  context_list_flags |= SE_TAG_CONTEXT_ONLY_NON_STATIC;
               }
               if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
                  context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
               }
            }
            tag_pop_matches();
         }

         if (class_name == "") {
            errorArgs[1] = prefixexp;
            return(VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
         }

         if (matchSelectorID) {
            parse substr(otherinfo, 2) with selector_id ":" signature;
         }

         strict := (prefixexp != "");
         if (!strict) context_list_flags |= SE_TAG_CONTEXT_FIND_LENIENT;

         tag_list_in_class(selector_id, class_name, 0, 0,
                           tag_files, num_matches, max_matches,
                           filter_flags, context_list_flags,
                           exact_match, case_sensitive,
                           template_args,
                           null, visited, depth+1);
         if (_chdebug) {
            isay(depth,"_m_find_context_tags: num_matches="num_matches);
            int i,n = tag_get_num_of_matches();
            for (i=1; i<=n; ++i) {
               tag_get_match_info(i, auto cm);
               tag_browse_info_dump(cm, "_m_find_context_tags", 1);
            }
         }

         if (matchSelectorID) {
            VS_TAG_BROWSE_INFO matches[];
            tag_get_all_matches(matches);
            tag_clear_matches();
            tag_pop_matches();

            num_matches = 0;
            if (signature != "") {
               signature = ":"signature;
               split(signature, ":", auto selector_ids);
               current_id := selector_ids._length() - 1;
               if (current_id > 0) {
                  n := matches._length();
                  for (i := 0; i < n; ++i) {
                     args := stranslate(matches[i].arguments, ":", '\:\([~)]*\) :v{ |$}', "r");
                     if (pos(signature, args, 1) != 1) {
                        continue;
                     }
                     split(args, ":", auto arg_ids);
                     if (arg_ids != null && arg_ids._length() > current_id) {
                        tag_tree_insert_tag(0, 0, 0, -1, TREE_ADD_AS_CHILD, arg_ids[current_id], "param", "", 0, "", 0, "");
                        ++num_matches;
                     }
                  }
               }
            }
         }
      }

      // Return 0 indicating success if anything was found
      errorArgs[1] = (lastid=="") ? class_name:lastid;
      return(num_matches == 0) ? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   return _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                               info_flags,otherinfo,false,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,
                               visited,depth+1,prefix_rt);
}

int _m_fcthelp_get_start(_str (&errorArgs)[],
                         bool OperatorTyped,
                         bool cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags,
                         int depth=0)
{
   if (_chdebug) {
      isay(depth, "_m_fcthelp_get_start H"__LINE__": IN");
   }
   errorArgs._makeempty();
   FunctionNameOffset = -1;
   ArgumentStartOffset = -1;
   flags = 0;
   save_pos(auto orig_pos);
   save_pos(auto p);
   end_msg := _QROffset();
   bracket_count := 0;
   do {
      ch := get_text_safe();
      if (ch == ":") {
         // bail if scope operator "::"
         if (get_text_safe(2) == "::") {
            break;
         }
         left();
         if (get_text_safe() == ":") {
            break;
         }

      } else if (ch == ")" || ch == "}" || ch == ";") {
         left();

      } else if (ch == "]") {
         ++bracket_count;
      }

      int status, f_offset, a_offset;
      for (;;) {
         f_offset = -1; a_offset = -1;
         for (;;) {
            in_msg := _objectivec_message_statement(bracket_count, 
                                                    auto indent_col, 
                                                    auto bracket_col, 
                                                    auto arg_col, 
                                                    auto arg_count, 
                                                    arg_align:false, 
                                                    bracket_pos:true, 
                                                    depth+1);
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get_start H"__LINE__": AFTER PARSING MESSAGE STATEMENT: in_msg="in_msg" arg_count="arg_count);
            }
            if (!in_msg || arg_count < 0) {
               break;
            }
            start_msg := _QROffset();
            start_offset := (int)point('s');
            msg := get_text_safe((int)(end_msg - start_msg), (int)start_msg);
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get_start H"__LINE__": msg="msg);
            }
            if (_ObjectiveCSignatureInfo(msg, auto signature, auto receiver, arg_count, auto in_selector, auto func_offset, auto arg_offset)) {
               if (_chdebug) {
                  isay(depth, "_m_fcthelp_get_start H"__LINE__": GOT SIGNATURE INFO");
               }
               break;
            }
            f_offset = start_offset + func_offset;
            a_offset = start_offset + arg_offset;
            save_pos(p);
            left(); end_msg = _QROffset();
         }

         if (f_offset < 0 && FunctionNameOffset >= 0) {
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get_start H"__LINE__": f_offset="f_offset" FunctionNameOffset="FunctionNameOffset);
            }
            return(0);
         }

         FunctionNameOffset = f_offset;
         ArgumentStartOffset = a_offset;
         flags = 0;

         restore_pos(p);
         status = _c_fcthelp_get_start(errorArgs,
                                       OperatorTyped,
                                       cursorInsideArgumentList,
                                       f_offset,
                                       a_offset, flags, depth);

         if (!status) {
            save_pos(p);
            FunctionNameOffset = f_offset;
            ArgumentStartOffset = a_offset;
            flags = 0;
            end_msg = _QROffset();
            continue;
         }

         if (FunctionNameOffset < 0 || ArgumentStartOffset < 0) {
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get_start H"__LINE__": FunctionNameOffset="FunctionNameOffset" ArgumentStartOffset="ArgumentStartOffset);
            }
            break;
         }
         return(0);
      }

   } while (false);

   if (_chdebug) {
      isay(depth, "_m_fcthelp_get_start H"__LINE__": OUT, CONTEXT NOT VALID");
   }
   restore_pos(orig_pos);
   return(VSCODEHELPRC_CONTEXT_NOT_VALID);
}

int _m_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   bool &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   static _str prev_function_name;
   static _str prev_function_offset;
   static _str prev_receiver;
   static int  prev_param_num;

   errorArgs._makeempty();
   FunctionHelp_list_changed = false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed = true;
      prev_receiver = "";
      prev_function_name = "";
      prev_function_offset = -1;
      prev_param_num = -1;
   }

   if (_chdebug) {
      isay(depth, "_m_fcthelp_get: fnoffset="FunctionNameStartOffset", flags=0x"_dec2hex(flags));
   }

   save_pos(auto p);
   word_chars := _clex_identifier_chars();
   ch := get_text_safe();
   bracket_count := 0;
   if (pos('['word_chars']', ch, 1, 'r')) {
      search('[~'word_chars']|$','rh@');
      ch = get_text_safe();
   }
   if (ch == ")" || ch == "}" || ch == ";") {
      left(); ch = get_text_safe();
   }

   end_msg := _QROffset();
   start_offset := (int)point('s');
   start_col := p_col;
   signature := "";
   receiver := "";
   param_num := -1;
   function_offset := -1;
   in_msg := false;
   if (ch == "(" || ch == "[") {
      left(); end_msg++;
   } else if (ch == "]") {
      ++bracket_count;
   }

   for (;;) {
      in_msg = _objectivec_message_statement(bracket_count, 
                                             auto indent_col, 
                                             auto bracket_col, 
                                             auto arg_col, 
                                             auto arg_count, 
                                             arg_align:false, 
                                             bracket_pos:true, 
                                             depth+1);
      if (_chdebug) {
         isay(depth, "_m_fcthelp_get H"__LINE__": in_msg="in_msg);
      }
      if (in_msg) {
         start_offset = (int)point('s');
         start_col = p_col;
         start_msg := _QROffset();
         msg := get_text_safe((int)(end_msg - start_msg), (int)start_msg);
         if (_ObjectiveCSignatureInfo(msg, signature, receiver, arg_count, auto in_selector, auto func_offset, auto arg_offset)) {
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get H"__LINE__": FAILED GETTING SIGNATURE INFO, CONTEXT NOT VALID");
            }
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         if (arg_count < 0) {
            if (start_offset > FunctionNameStartOffset) {
               save_pos(p);
               left(); end_msg = _QROffset();
               bracket_count = 0;
               continue;
            }
            if (_chdebug) {
               isay(depth, "_m_fcthelp_get H"__LINE__": arg_count="arg_count" NO IN ARG LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }

         function_offset = start_offset + func_offset;
         param_num = arg_count*2 + 1;
         if (in_selector) {
            ++param_num;
         }
      }
      break;
   }

   if (_chdebug) {
      isay(depth, "_m_fcthelp_get H"__LINE__": in_msg="in_msg" receiver="receiver);
   }
   if (in_msg && receiver != "") {
      // reset _c_fcthelp_get statics
      _c_fcthelp_get(errorArgs,
                     FunctionHelp_list,
                     FunctionHelp_list_changed,
                     FunctionHelp_cursor_x,
                     FunctionHelp_HelpWord,
                     -1, 0xffffffff, null);

      parse signature with auto lastid ":" auto argid;

      // check if anything has changed
      if (prev_function_name :== lastid &&
          prev_function_offset :== function_offset &&
          prev_receiver :== receiver &&
          prev_param_num == param_num) {
         return(0);
      }

      lastid_col := p_col;

      _UpdateContextAndTokens(true);
      _UpdateLocals(true);
      tag_clear_matches();

      tag_files := tags_filenamea(p_LangId);
      filter_flags := SE_TAG_FILTER_PROCEDURE;
      context_flags := SE_TAG_CONTEXT_NO_GLOBALS|SE_TAG_CONTEXT_ONLY_INCLASS;
      _str template_args:[];
      class_name := "";

      VS_TAG_RETURN_TYPE rt; tag_return_type_init(rt);
      status := 0;
      if (receiver != "") {
         // evaluate the prefix expression to set up the return type 'rt'
         status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, receiver, rt, visited, depth+1, VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE);
         if (status) {
            tag_pop_matches();
            return(status);
         }

         if (_chdebug) {
            tag_return_type_dump(rt, "_m_fcthelp_get");
         }
         class_name = rt.return_type;
         template_args = rt.template_args;
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
            context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
         }
         if (rt.pointer_count > 0) {
            context_flags |= SE_TAG_CONTEXT_ONLY_NON_STATIC;
         }
      }
      tag_pop_matches();
      if (class_name == "") {
         return(VSCODEHELPRC_NO_SYMBOLS_FOUND);
      }

      num_matches := 0;
      tag_list_in_class(lastid, class_name, 0, 0,
                        tag_files, num_matches, def_tag_max_function_help_protos,
                        filter_flags, context_flags,
                        true, true,
                        template_args,
                        null, visited, depth+1);

      if (num_matches > 0) {
         FunctionHelp_list._makeempty();
         FunctionHelp_HelpWord = lastid;

         argid = ":"argid;
         n := tag_get_num_of_matches();
         for (i := 1; i <= n; ++i) {
            k := FunctionHelp_list._length();
            if (k >= def_tag_max_function_help_protos) break;

            tag_get_match_info(i, auto cm);
            args := stranslate(cm.arguments, ":", '\:\([~)]*\) :v( |$)', "r");
            if (pos(argid, args, 1) != 1) {
               continue;
            }

            prototype := cm.return_type" ":+lastid:+cm.arguments;
            tag_autocode_arg_info_from_browse_info(FunctionHelp_list[k], cm, prototype);
            base_length := length(cm.return_type) + 1;
            FunctionHelp_list[k].argstart[0] = base_length;
            FunctionHelp_list[k].arglength[0] = length(lastid);
            FunctionHelp_list[k].ParamNum = param_num;

            base_length += length(lastid);
            arg_start := pos(":", cm.arguments, 1) + 1;
            j := 1;
            while (arg_start) {
               // insert argument
               arg_start = pos('\([~)]*\) :v', cm.arguments, arg_start, 'r');
               if (!arg_start) break;

               arg_length := pos("");
               FunctionHelp_list[k].argstart[j] = base_length + arg_start;
               FunctionHelp_list[k].arglength[j] = arg_length;
               arg_start += arg_length;
               ++j;

               // insert selector id
               arg_start = pos(':v\:', cm.arguments, arg_start + 1, 'r');
               if (!arg_start) break;

               arg_length = pos("");
               FunctionHelp_list[k].argstart[j] = base_length + arg_start;
               FunctionHelp_list[k].arglength[j] = arg_length;
               arg_start += arg_length;
               ++j;
            }
         }
         if (prev_function_offset != function_offset ||
             prev_param_num != param_num) {
            FunctionHelp_list_changed = true;
         }
         prev_receiver = receiver;
         prev_function_name = lastid;
         prev_function_offset = function_offset;
         prev_param_num = param_num;
         if (!p_IsTempEditor) {
            FunctionHelp_cursor_x = (start_col-lastid_col)*p_font_width+p_cursor_x;
         }
      }
      return(0);

   } else {
      prev_receiver = "";
      prev_function_name = "";
      prev_function_offset = -1;
      prev_param_num = -1;
   }

   restore_pos(p);
   return _c_fcthelp_get(errorArgs,
                         FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth+1);
}

int _m_generate_function(VS_TAG_BROWSE_INFO &cm,
                         int &c_access_flags,
                         _str (&header_list)[],
                         _str function_body,
                         int indent_col, int begin_col,
                         bool make_proto=false,
                         bool in_class_scope=true,
                         _str className="",
                         _str class_signature="",
                         long insertion_seekpos=-1)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}

static void objc_get_selector_parameter_format(_str &openparen, _str &closeparen)
{
   ibeautifier := _beautifier_cache_get('m',p_buf_name);
   pad1 := pad2 := pad3 := "";
   
   if (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_OBJC_SP_METH_PARAM_BEFORE_LPAREN)) {
      pad1 = " ";
   }
   if (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_OBJC_SPPAD_METH_PARAM_PARENS)) {
      pad2 = " ";
   }
   if (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_OBJC_SP_METH_PARAM_AFTER_RPAREN)) {
      pad3 = " ";
   }
   openparen = pad1:+"(":+pad2;
   closeparen = pad2:+")":+pad3;
}

// return formatter string for colon, pad is spaces after colon
static _str objc_get_selector_colon_format(bool decl)
{
   option := (decl) ? VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_DECL_SELECTOR_COLON : VSCFGP_BEAUTIFIER_OBJC_SPSTYLE_CALL_SELECTOR_COLON;
   ibeautifier := _beautifier_cache_get('m', p_buf_name);
   switch (_beautifier_get_property(ibeautifier,option)) {
   case 0: return ":";     // no space
   case 1: return " :";    // before
   case 2: return ": ";    // after
   case 3: return " : ";   // before and after
      break;
   }
   return(": ");
}

static int _m_auto_insert_selector_signature(bool decl)
{
   save_pos(auto p);
   status := 1;
   do {
      // TODO: lang option to disable this?
      search('[~ \t]|$','r@');
      if (p_col > _text_colc(0,'E')) {
         status = 0;
         break;
      }

      ch := get_text_safe();
      if (decl) {
         if (ch == "{" || ch == ";") {
            status = 0;
            break;
         }

      } else {
         if (ch == "]" || ch == ";") {
            status = 0;
            break;
         }
      }

   } while(false);
   restore_pos(p);
   return(status);
}

void _m_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                   VS_TAG_IDEXP_INFO &idexp_info, 
                                   _str terminationKey="")
{
   _c_autocomplete_before_replace(word, idexp_info, terminationKey);
}

/**
 * Handles:
 *    Auto insert full selector signature
 *
 *
 */
bool _m_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                      VS_TAG_IDEXP_INFO &idexp_info,
                                      _str terminationKey="")
{
   if (idexp_info == null || word.symbol == null ||
       !(idexp_info.info_flags & VSAUTOCODEINFO_OBJECTIVEC_CONTEXT)) {
      return _c_autocomplete_after_replace(word, idexp_info, terminationKey);
   }
   if (terminationKey == ":") {
      return(false);
   }

   ch := _first_char(idexp_info.otherinfo);
   if ((ch == ":" || ch =="-") && (word.symbol.type_name == "param")) {
      _insert_text(objc_get_selector_colon_format(ch == "-"));

      if (ch == ":") {
         if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
            _do_function_help(OperatorTyped:true, 
                              DisplayImmediate:true,
                              cursorInsideArgumentList:true);
         }
      }
      return(true);
   }

   if ((word.symbol.type_name != "selector" && word.symbol.type_name != "staticselector") || idexp_info.otherinfo == "@selector") {
      return(false);
   }

   in_decl := (idexp_info.otherinfo == "@method");
   if (_m_auto_insert_selector_signature(in_decl)) {
      return(false);
   }

   signature := word.symbol.arguments;
   if (signature != "") {
      if (in_decl) {
         // tagged signature uses this format/spacing:
         // ":(type) argid id:(type) argid id:(type) argid ..."
         // need to match formatting options
         colon := objc_get_selector_colon_format(true);
         objc_get_selector_parameter_format(auto openparen, auto closeparen);

         signature = stranslate(signature, colon, ":");        // replace colon with formatter setting
         signature = stranslate(signature, openparen, "(");    // replace open paren with formatter setting
         signature = stranslate(signature, closeparen, ") ");  // replace close paren with formatter setting
         _insert_text(signature);
         return(true);
      }

      offset := _QROffset();
      long hotspots[];

      colon := objc_get_selector_colon_format(false);
      pad := (_last_char(colon) == " ") ? 1 : 0;
      signature = stranslate(signature, colon, ":");              // replace colon with formatter setting
      signature = stranslate(signature, "", '\([~)]*\) :v', "r"); // remove parameter (type) argid
      col := lastpos(",", signature);
      if (col > 1) {
         signature = substr(signature, 1, col - 1);               // remove variable arguments
      }

      // find offset for hotspots
      if (def_hotspot_navigation) {
         col = pos(":", signature);
         while (col > 0) {
            hotspots[hotspots._length()] = offset + col + pad;
            col = pos(":", signature, col + 1);
         }
      }

      col = p_col + length(colon);
      _insert_text(signature);
      p_col = col;
      if (hotspots._length() > 1) {
         HotspotMarkers.createMarker(hotspots);
      }

      if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
         _do_function_help(OperatorTyped:true, 
                           DisplayImmediate:true,
                           cursorInsideArgumentList:true);
      }
   }
   return(true);
}

int _m_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}

int _m_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, SETagFlags tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[],
                           int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}

int _m_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words);
}

/**
 * Block matching
 *
 * @param quiet   just return status, no messages
 * @return 0 on success, nonzero if no match
 */
int _m_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   int status;
   save_pos(auto p);
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_KEYWORD && p_col > 0) {
      left(); cfg = _clex_find(0, 'g');
   }
   if (cfg == CFG_KEYWORD) {
      start_col := -1;
      status = _clex_find(KEYWORD_CLEXFLAG, 'n-');
      if (!status) {
         status = _clex_find(KEYWORD_CLEXFLAG);
         start_col = p_col;
      }

      //@implementation @interface @protocol <--> @end
      word := cur_word(auto junk);
      if (start_col > 0 && get_text() == "@") {
         if (pos(" "word" "," class interface implementation protocol end ")) {
            dir := "";
            if (word == "end") {
               dir = "-";
               if (p_col == 1) {
                  up(); _end_line();
               } else {
                  left();
               }
            } else {
               right();
            }

            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = search('\@(class|interface|implementation|protocol|end)', dir:+'@rhxcs');
            for (;;) {
               if (status) break;
               word = get_match_text();
               cfg = _clex_find(0, 'g');
               if (cfg == CFG_KEYWORD) {
                  if (dir == "" && word == "@end") {
                     restore_search(s1, s2, s3, s4, s5);
                     return 0;
                  } else {

                  }
                  switch (word) {
                  case "@end":
                     if (dir == "") {
                        restore_search(s1, s2, s3, s4, s5);
                        return 0;
                     }
                     status = -1;
                     break;

                  //@class
                  //@interface
                  //@implementation
                  //@protocol
                  default:
                     if (dir == "-") {
                        restore_search(s1, s2, s3, s4, s5);
                        return 0;
                     }
                     status = -1;
                     break;
                  }
               }

               if (!status) {
                  status = repeat_search();
               }
            }
            restore_search(s1, s2, s3, s4, s5);
         }
      }
   }
   restore_pos(p);
   return _c_find_matching_word(quiet, pmatch_max_diff_ksize, pmatch_max_level);
}

int m_smartpaste(bool char_cbtype, int first_col, int Noflines, bool allow_col_1=false)
{
   // TODO: Check arg align option
   // allow multiple lines?
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   cfg := _clex_find(0,'g');
   if (Noflines == 1 && cfg != CFG_STRING && cfg != CFG_COMMENT) {
      get_line(auto line);
      id_re := _clex_identifier_re();
      line = strip(line, 'L');
      if (pos('^':+id_re:+'[ \t]*\:', line, 1, 'r')) { // line starts with ID:
         _objectivec_message_statement(0, auto indent_col, auto bracket_col, auto arg_col, auto arg_count, arg_align:true);
         if (arg_col > 1 && indent_col > 0 && arg_count > -1) {
            colon_col := pos(":", line);
            col := 1 + arg_col - colon_col;
            if (indent_col > 0 && (col < indent_col)) {
               col = indent_col;
            }
            _begin_select(); up();
            return(col);
         }
      }
   }
   return c_smartpaste(char_cbtype, first_col, Noflines, allow_col_1);
}

// find indent column if in objective-c message expression
int m_indent_col(int syntax_indent)
{
   save_pos(auto p);
   orig_col := p_col; left();
   _objectivec_message_statement(0, auto indent_col, auto bracket_col, auto arg_col, auto arg_count);
   restore_pos(p);
   if (arg_col > 1 && indent_col > 0 && arg_count > -1) {
      // TODO: check arg alignment option
      // If split selector arg: then
      // indent to align on colon
      id_re := _clex_identifier_re();;
      line := strip(_expand_tabsc(orig_col), 'L');
      if (pos('^':+id_re:+'[ \t]*\:', line, 1, 'r')) { // line starts with ID:
         colon_col := pos(":", expand_tabs(line));
         col := 1 + arg_col - colon_col;
         if (indent_col > 0 && (col < indent_col)) {
            col = indent_col;
         }
         indent_on_enter(0, col);
         replace_line_raw(indent_string(col-1):+line);
         return(0);
      }
   } else if (indent_col > 0) {
      // indent returned
      return(indent_col);
   }
   return(-1);
}

/**
 * @return return if the cursor pos is in an objective-c
 * category/protocol/interface/implementation.
 */
bool _objc_in_class()
{
   if (p_lexer_name=="") {
      return false;
   }

   // keep track of buffers that do not have Objective-C keywords
   // don't keep doing search if it isn't there to be found.
   STRARRAY* exclusionCacheP = _GetDialogInfoHtPtr("ObjectiveCExclusions", _mdi);
   if (exclusionCacheP != null &&
       p_buf_id < exclusionCacheP->_length() &&
       (*exclusionCacheP)[p_buf_id] != null &&
       (*exclusionCacheP)[p_buf_id] == p_LastModified:+"\t":+p_buf_name) {
      return false;
   }

   // Find objective-c category/protocol/interface/implementation beginning
   // search for begin brace,end brace, and switch not in comment or string
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   status := search('\@class|\@interface|\@implementation|\@protocol|\@end','@rh-xcs');

   // nothing found searching backwards, try searching forward
   // if this buffer has no Objective-C keywords then kick it out
   if (status) {
      status=search('\@class|\@interface|\@implementation|\@protocol|\@end','@rhxcs');
      if (status) {
         if (exclusionCacheP == null) {
            _str exclusionCache[];
            exclusionCache[p_buf_id] = p_LastModified:+"\t":+p_buf_name;
            _SetDialogInfoHt("ObjectiveCExclusions",exclusionCache,_mdi);
         } else {
            (*exclusionCacheP)[p_buf_id] = p_LastModified:+"\t":+p_buf_name;
         }
      }

   } else {

      loop {
         if (status) break;
         word := get_match_text();
         int color=_clex_find(0,'g');
         if (color==CFG_KEYWORD) {
            switch (word) {
            case "@end":
               status=STRING_NOT_FOUND_RC;
               continue;
            default:
               restore_search(s1, s2, s3, s4, s5);
               restore_pos(p);
               return true;
            }
         }
         status=repeat_search();
      }
   }

   // cleanup
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return false;
}

bool _objectivec_index_operator()
{
   status := false;
   // index operator or objective-c message expression
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   save_pos(auto p); left();
   tk := c_prev_sym2();
   switch (tk) {
   case TK_ID:  // index operator?
      if (c_sym_gtkinfo() == "return") {
         break;
      }
      status = true;
      break;

   case "]":
   case ")":   // probably index operator
      status = true;
      break;

   case "+":
   case "-": // unary, binary, or postfix op?
      tk = get_text_safe(2, _nrseek());
      if (tk == "++" || tk == "--") {
         status = true;
      }
      break;

   default: // other
      break;
   }
   restore_pos(p);
   restore_search(s1, s2, s3, s4, s5);
   return status;
}

int _objectivec_get_bracket_expression(_str& expr)
{
   right(); r_pos := _QROffset() + 1;
   status := find_matching_paren(true);
   if (status) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   l_pos := _QROffset();
   // index operator or message expression?
   if (_objectivec_index_operator()) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   msg := get_text_safe((int)(r_pos - l_pos), (int)l_pos);
   info := "";
   if (_ObjectiveCReceiverInfo(msg, expr)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   return(0);
}

static bool _objectivec_in_method_decl()
{
   save_pos(auto p);
   right(); _clex_skip_blanks();
   if (get_text() != "(") {
      restore_pos(p);
      return(false);
   }
   brace_count := 0;
   status := search('[{}]|\@(class|interface|implementation|protocol|end)','-@rhxcs');
   for (;;) {
      if (status) {
         break;
      }
      switch (get_match_text()) {
      case "{":
         ++brace_count;
         if (brace_count > 0) {
            restore_pos(p);
            return(false);
         }
         break;

      case "}":
         --brace_count;
         break;

      case "@end":
         restore_pos(p);
         return(false);

      case "@class":
      case "@interface":
      case "@implementation":
      case "@protocol":
         restore_pos(p);
         return(true);
      }
      status = repeat_search();
   }
   restore_pos(p);
   return(false);
}

/**
 * Search for beginning of Objective-c message expression.
 *
 * Assumes that expression is syntactically correct, mostly.
 *
 * @param bracket_count    Incoming brackets nest level
 * @param indent_col       Returns indent column for statement, or -1 for not found
 * @param bracket_col      Returns bracket column for statement, or -1 for not found
 * @param arg_col          Returns last argument colon column, or -1 for not found
 * @param arg_count        Returns argument count from start col, or -1 for not found
 * @param arg_align        On true, check exit condtions for aligning arguments on colon
 * @param bracket_pos      On true, leave position if open bracket found
 *
 * @return True for message statement found
 */
bool _objectivec_message_statement(int bracket_count, 
                                   int& indent_col, 
                                   int& bracket_col, 
                                   int& arg_col, 
                                   int& arg_count, 
                                   bool arg_align = false, 
                                   bool bracket_pos = false, 
                                   int depth=0)
{
   if (_chdebug) {
      isay(depth, "_objectivec_message_statement H"__LINE__": IN");
   }
   orig_line := p_line;
   orig_col := p_col;
   orig_point := (int)point('s');
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   paren_count := 0;
   indent_col = -1;
   arg_col = -1;
   arg_count = -1;
   last_arg_col := -1;
   last_arg_count := -1;
   last_arg_point := -1;
   bracket_col = -1;
   syntax_indent := p_SyntaxIndent;

   int status = search('[?:;{}()\[\]]|\b(class|struct|default|case|public|private|protected)|\@(class|interface|implementation|protocol|end|package|private|protected|public|optional|dynamic|selector|synthesize|required|property)','-@rhxcs');
   for (;;) {
      if (status) {
         arg_col = -1;
         arg_count = -1;
         bracket_col = -1;
         break;
      }
      ch := get_match_text();
      if (_chdebug) {
         isay(depth, "_objectivec_message_statement H"__LINE__": ch="ch);
      }
      switch (ch) {
      case ":":
         if (!bracket_count && !paren_count) {
            // check scope operator ::
            if (p_col > 1) {
               left();
               if (get_text_safe() == ":") {
                  break;
               }
               right();
            }

            last_arg_col = arg_col;
            last_arg_count = arg_count;
            last_arg_point = (int)point("s");

            ++arg_count;
            if (arg_align && (p_line == orig_line)) {
               status = -1; // already one on orig line, get out
            } else {
               arg_col = p_col;
            }
         }
         break;

      case "[":
         if (_chdebug) {
            isay(depth, "_objectivec_message_statement H"__LINE__": paren_count="paren_count);
         }
         if (paren_count) {
            break;
         }
         ++bracket_count;
         bracket_col = p_col;
         if (_chdebug) {
            isay(depth, "_objectivec_message_statement H"__LINE__": bracket_count="bracket_count" bracket_col="bracket_col);
         }
         break;

      case "]":
         if (paren_count) {
            break;
         }
         --bracket_count;
         break;

      case "(":
          ++paren_count;
          if (paren_count > 0) {
             status = -1;
          }
          break;

      case ")":
         --paren_count;
         break;

      case "@optional":
      case "@required":
         p_col += match_length(); // fall-through

      case "@class":
      case "@interface":
      case "@implementation":
      case "@protocol":
         if (!_objectivec_find_next_class_decl(orig_point)) {
            ch = get_text();
            if (ch == "+"|| ch == "-") {
               indent_col = p_col + beaut_continuation_indent();
               if (point('s') > last_arg_point) {
                  arg_col = last_arg_col;
                  arg_count = last_arg_count;
               }
               break;

            } else if (ch == "@" && (_clex_find(0, 'g') == CFG_KEYWORD)) {
               indent_col = p_col;
            } else {
               status = -1;
            }
         }
         arg_col = -1;
         arg_count = -1;
         break;

      case "@property":
      case "@synthesize":
      case "@dynamic":
         indent_col = p_col + beaut_continuation_indent();
         arg_col = -1;
         arg_count = -1;
         break;

      case "@package":
      case "@private":
      case "@protected":
      case "@public":
         if (beaut_indent_members_from_access_spec()) {
            indent_col = p_col + syntax_indent;
         } else {
            indent_col = p_col + syntax_indent - beaut_member_access_indent();
         }
         arg_col = -1;
         arg_count = -1;
         break;

      case "@selector":
         break;

      case "@end":
         indent_col = p_col;
         arg_col = -1;
         arg_count = -1;
         break;

      case "?":
         if (arg_align && (p_line == orig_line)) {
            status = -1;
            break;
         }
         if (bracket_count || paren_count || arg_count < 0) {
            break;
         }
         --arg_count;
         arg_col = -1;
         break;

      case "case":
      case "class":
      case "struct":
      case "default":
      case "private":
      case "protected":
      case "public":
         if (_clex_find(0, 'g') != CFG_KEYWORD) {
            break;
         }
         // fall-through
      case "{":
         // should not be here
         status = -1;
         break;

      case "}":
      case ";":
         // test for objective-c method declaration
         right(); _clex_skip_blanks();
         if (point('s') <= orig_point) {
            ch = get_text();
            if ((ch == "+"|| ch == "-") && _objectivec_in_method_decl()) {
               indent_col = p_col + beaut_continuation_indent();
               break;
            }
         }
         // Oh, right, badness.
         status = -1;
         break;

      default:
         // something else
         status = -1;
         break;
      }

      // not objective-c message expression
      if (status) {
         arg_col = -1;
         arg_count = -1;
         bracket_col = -1;
         break;
      }

      // hit different declaration type
      if (indent_col > 0) {
         break;
      }

      // open bracket found
      if (bracket_count > 0) {
         if (_chdebug) {
            isay(depth, "_objectivec_message_statement H"__LINE__": bracket count="bracket_count);
         }
         at_start := ((p_line == orig_line) && (p_col == orig_col));
         if (!_objectivec_index_operator() && !at_start) {
            if (_chdebug) {
               isay(depth, "_objectivec_message_statement H"__LINE__": not index op, not start");
            }
            if (arg_align && (p_line == orig_line)) {
               arg_col = -1;  // still on original line, nothing to align
            }
            if (arg_align && LanguageSettings.getUseContinuationIndentOnFunctionParameters(p_LangId)) {
               // continuation indent
               _first_non_blank();
               indent_col = p_col + syntax_indent;
            } else {
               // bracket indent
               indent_col = p_col + 1;
            }

         } else {
            if (_chdebug) {
               isay(depth, "_objectivec_message_statement H"__LINE__": reset bracket col");
            }
            arg_col = -1;
            arg_count = -1;
            bracket_col = -1;
         }

         if (_chdebug) {
            isay(depth, "_objectivec_message_statement H"__LINE__": BREAK LOOP");
         }
         break;
      }

      if (_chdebug) {
         isay(depth, "_objectivec_message_statement H"__LINE__": repeat search");
      }

      status = repeat_search();
   }

   if (_chdebug) {
      isay(depth, "_objectivec_message_statement H"__LINE__": status="status" bracket_count="bracket_count" bracket_col="bracket_col);
   }
   if (status || !bracket_pos) {
      restore_pos(p);
   }
   restore_search(s1, s2, s3, s4, s5);
   return (bracket_col > 0);
}

bool _objectivec_do_colon()
{
   // check for alignment
   orig_col := p_col;
   save_pos(auto p);  left(); left();
   _objectivec_message_statement(0, 
                                 auto indent_col, 
                                 auto bracket_col, 
                                 auto arg_col, 
                                 auto arg_count, 
                                 arg_align:true);
   restore_pos(p);
   status := true;
   if (arg_col > 1 && indent_col > 0 && arg_count > -1) {
      get_line_raw(auto line);
      orig_line_width := length(expand_tabs(line));
      new_line := strip(line, 'L');
      colon_col := pos(":", new_line);
      width := arg_col - colon_col;

      // maintain alignment current indent
      if (indent_col > 0 && (width < indent_col - 1)) {
         width = indent_col - 1;
      }

      // indent
      if (width > 0) {
         new_line = indent_string(width):+new_line;
      }
      replace_line_raw(new_line);
      p_col = orig_col + length(expand_tabs(new_line)) - orig_line_width;
      status = false;
   }

   // check for argument help
   if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_FUNCTION_HELP) {
      save_pos(p); left();
      in_msg := _objectivec_message_statement(0, indent_col, bracket_col, arg_col, arg_count);
      restore_pos(p);
      if (in_msg) {
         _do_function_help(OperatorTyped:true, 
                           DisplayImmediate:true,
                           cursorInsideArgumentList:true);
      }
   }
   return(status);
}

int objectivec_space_codehelp()
{
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      return(0);
   }

   // save the cursor position
   save_pos(auto p);
   orig_col := p_col;
   _first_non_blank();
   if (p_col >= orig_col) {
      // in leading whitespace
      restore_pos(p);
      return(0);
   }

   restore_pos(p);
   if (_clex_skip_blanks('-')) {
      restore_pos(p);
      return(0);
   }

   cfg := _clex_find(0, 'g');
   if (cfg == CFG_COMMENT || cfg == CFG_NUMBER || cfg == CFG_PPKEYWORD) {
      restore_pos(p);
      return(0);
   }

   if (cfg == CFG_KEYWORD) {
      word := cur_word(auto junk);
      if (word != "self") {
         restore_pos(p);
         return(0);
      }
   }

   restore_pos(p);
   ch := get_text_safe();
   if (ch == "]" || ch == ":" || ch == ";") {
      left();
   }

   // in [receiver selector] expression?
   in_msg :=  _objectivec_message_statement(0, auto indent_col, auto bracket_col, auto arg_col, auto arg_count);
   restore_pos(p);
   if (!in_msg || arg_count >= 0) {
      return(0);
   }
   _do_list_members(OperatorTyped:true, DisplayImmediate:true);
   return(1);
}

static bool _at_unary_position(bool in_brackets = false) {
   save_pos(auto p);
   if (in_brackets) {
      _clex_skip_blanks('-');
      left();
   }
   left();
   _clex_skip_blanks('-');
   switch (get_text()) {
   case "]":
      restore_pos(p);
      return false;

   case "{":
   case ";":
   case "(":
   case "[":
   case ")":
   case ",":
   case "@":
      restore_pos(p);
      return true;

   default:
      t := _clex_find(0, 'G');
      restore_pos(p);
      return (t == CFG_KEYWORD ||
              t == CFG_OPERATOR ||
              t == CFG_PUNCTUATION);
   }
}

void _m_auto_bracket_key_mask(_str close_ch, int* keys) {
   if (close_ch == "]" && _at_unary_position(true)) {
      // Disable ENTER as a completion key, so the user can
      // type multi-line method calls.
      *keys = *keys & ~AUTO_BRACKET_KEY_ENTER;
   }
}

// Slickedit RE that matches all of the keywords involved in class definition,
// minus the @end keyword.
const OBJECTIVEC_CLASS_KEYWORDS_RE = '\@(implementation|public|protected|private|package|class|interface|protocol|optional|dynamic|synthesize|required|property)';

bool objectivec_inside_dict_literal() {
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   nesting_seen := 0;
   status := search('[{}]|'OBJECTIVEC_CLASS_KEYWORDS_RE'|\@end',"@RH-");
   viable := 0;

   for (;viable == 0 && status == 0; status = repeat_search('@rh-')) {
      if (status != 0) {
         restore_pos(p);
         return false;
      }
//    say("objc_inside_dict_literal: "get_text());
      switch (get_text()) {
      case "@":
         viable = -1;
         break;

      case "}":
         nesting_seen++;
         break;

      case "{":
         if (nesting_seen == 0) {
            left();
            _clex_skip_blanks("-");
            if (get_text() == "@") {
               viable = 1;
            } else {
               viable = -1;
            }
         } else {
            nesting_seen--;
            if (nesting_seen < 0) {
               viable = -1;
            }
         }
         break;
      }
   }
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return (viable > 0);
}


bool _m_surroundable_statement_end() {
   return _c_surroundable_statement_end();
}

bool _m_auto_surround_char(_str key) {
   return _c_auto_surround_char(key);
}
