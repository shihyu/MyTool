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
#import "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "cfcthelp.e"
#import "context.e"
#import "ccontext.e"
#import "cidexpr.e"
#import "csymbols.e"
#import "cutil.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * Support for lexer and parser generators, ANTLR, Lex, and Yacc.
 * The support is essentially limited to color coding.
 * <P>
 * INSTALLATION:
 * <UL>
 * <LI>Load this macro module with LOAD command (MENU, "Macro", "Load").
 * <LI>Save the configuration. (CONFIG,Save configuration...)
 * </UL>
 */

static const WORD_CHARS= "a-zA-Z0-9_$%";

static const ANTLR_LANGUAGE_ID=  "antlr";

static const LEX_LANGUAGE_ID=    "lex";

static const YACC_LANGUAGE_ID=   "yacc";


/**
 * Switch into ANTLR mode.
 */
_command antlr_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(ANTLR_LANGUAGE_ID);
}

/**
 * Switch into Lex mode.
 */
_command lex_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(LEX_LANGUAGE_ID);
}

/**
 * Switch into Yacc mode.
 */
_command yacc_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(YACC_LANGUAGE_ID);
}

/**
 * Search for the next tag in an ANTLR grammer.
 *
 * @param proc_name     (reference) set to tag name, in the format:
 *                      <code>TAGNAME([CLASS:]TYPE)</code>
 *                      See tag_tree_compose_tag() for more details.
 * @param find_first    find first match or next match?
 *
 * @return 0 on success, non-zero on error, STRING_NOT_FOUND_RC
 *         if there are no more tags found.
 */
int antlr_proc_search(_str &proc_name, bool find_first)
{
   static _str cur_class;
   status := 0;
   if ( find_first ) {
      cur_class="";
      if ( proc_name:=="" ) {
         proc_name = _clex_identifier_re();
      }
      skip_line := '[ \t\r\n\f]*';
      _str skip_stuff=skip_line'([!]'skip_line'|)':+
                               '(\[{?*}\]'skip_line'|)':+
                               '(\{{?*}\}'skip_line'|)':+
                               '(options'skip_line'[{]?*[}]'skip_line'|)':+
                               '(returns'skip_line'\[{?*}\]'skip_line'|)':+
                               '([{]?*[}]'skip_line'|)';
      word_chars := _clex_identifier_chars();
      class_def := "class:b{"proc_name"}:bextends:b{[."word_chars"]*}";
      status=search('^({protected:b|}{'proc_name'}\om'skip_stuff'\ol[:]|'class_def')','@rihXcs');
   } else {
      status=repeat_search();
   }
   if (status < 0) {
      return status;
   }
   proc_name=get_match_text(1);
   if (proc_name=="options" || proc_name=="header") {
      if (down()) return 1;
      _begin_line();
      return antlr_proc_search(proc_name,false);
   } else if (proc_name!="") {
      tag_init_tag_browse_info(auto cm, proc_name, "", SE_TAG_TYPE_FUNCTION);
      cm.flags = (get_match_text(0)=="protected")? SE_TAG_FLAG_PROTECTED : 0;
      cm.arguments = get_match_text(2);
      cm.arguments = stranslate(cm.arguments,"",'ANTLR_USE_NAMESPACE\([ \ta-zA-Z0-9_\:]*\) *','r');
      cm.return_type = get_match_text(3);
      parse cm.return_type with cm.return_type .;
      proc_name = tag_compose_tag_browse_info(cm);
   } else {
      proc_name=get_match_text(5);
      extends := get_match_text(6);
      cur_class=proc_name;
      tag_init_tag_browse_info(auto cm, proc_name, "", SE_TAG_TYPE_CLASS);
      proc_name=tag_compose_tag_browse_info(cm);
   }
   return(0);
}
/**
 * Search for the next tag in an Yacc grammer.
 *
 * @param proc_name     (reference) set to tag name, in the format:
 *                      <code>TAGNAME([CLASS:]TYPE)</code>
 *                      See tag_tree_compose_tag() for more details.
 * @param find_first    find first match or next match?
 *
 * @return 0 on success, non-zero on error, STRING_NOT_FOUND_RC
 *         if there are no more tags found.
 */
int yacc_proc_search(_str &proc_name, bool find_first)
{
   if (find_first) {
      search('^[%][%]','@rh');
      down();
   }

   return _generic_regex_proc_search('^([ \t]*<<<NAME>>>\om[ \t\r\n\f]*[:]\ol|[%][%])', proc_name, find_first, "label");
}
/**
 * Search for the next tag in an Lex lexer.
 *
 * @param proc_name     (reference) set to tag name, in the format:
 *                      <code>TAGNAME([CLASS:]TYPE)</code>
 *                      See tag_tree_compose_tag() for more details.
 * @param find_first    find first match or next match?
 *
 * @return 0 on success, non-zero on error, STRING_NOT_FOUND_RC
 *         if there are no more tags found.
 */
int lex_proc_search(_str &proc_name, bool find_first)
{
   // no real declaration lex, silly to tag rules (they are regular expressions).
   proc_name="";
   return(STRING_NOT_FOUND_RC);
}

#if 0
/**
 * Return the actual extension to handle things as for antlr.
 */
_str _antlr_extension()
{
   // lex and yacc are always 'c'
   if (p_LangId!='antlr') {
      return 'c';
   }

   int p;
   typeless s1,s2,s3,s4,s5;
   save_pos(p);
   save_search(s1,s2,s3,s4,s5);
   top();_begin_line();

   new_ext := 'c';
   status := search('language[ \t]*=[ \t]*\"{[a-zA-Z0-9]*}\"','@reh');
   if (!status) {
      switch (lowcase(get_match_text(0))) {
      case "java":
         new_ext='java';
         break;
      case "c":
      case "cpp":
         new_ext='c';
         break;
      case "csharp":
      case "c#":
         new_ext='cs';
         break;
      case "sather":
         new_ext='sather';
         break;
      }
   }

   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return new_ext;
}
#endif

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
 * @since 11.0
 */
int _antlr_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
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
 * @since 11.0
 */

int _lex_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
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
 * @since 11.0
 */
int _yacc_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _[ext]_find_context_tags
 * <P>
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link _antlr_get_expression_info()}.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _antlr_get_expression_info}
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
int _antlr_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                             _str lastid,int lastidstart_offset,
                             int info_flags,typeless otherinfo,
                             bool find_parents,int max_matches,
                             bool exact_match,bool case_sensitive,
                             SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                             SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                             VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,
                               lastidstart_offset,
                               info_flags,
                               otherinfo,
                               find_parents,
                               max_matches,
                               exact_match,
                               case_sensitive,
                               filter_flags,
                               context_flags,
                               visited, depth,
                               prefix_rt);
}
int _lex_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,
                               lastidstart_offset,
                               info_flags,
                               otherinfo,
                               find_parents,
                               max_matches,
                               exact_match,
                               case_sensitive,
                               filter_flags,
                               context_flags,
                               visited, depth,
                               prefix_rt);
}
int _yacc_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                            VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,
                               lastidstart_offset,
                               info_flags,
                               otherinfo,
                               find_parents,
                               max_matches,
                               exact_match,
                               case_sensitive,
                               filter_flags,
                               context_flags,
                               visited, depth,
                               prefix_rt);
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get_start
 * <P>
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.  This determines
 * quickly whether or not we are in the context of a function call.
 *
 * @param errorArgs                List of argument for codehelp error messages
 * @param OperatorTyped            When true, user has just typed last
 *                                 character of operator.
 *                                 <PRE>
 *                                    p->myfunc( &lt;Cursor Here&gt;
 *                                 </PRE>
 *                                 This should be false if
 *                                 cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList When true, user requested function help when
 *                                 the cursor was inside an argument list.
 *                                 <PRE>
 *                                    MessageBox(...,&lt;Cursor Here&gt;...)
 *                                 </PRE>
 *                                 Here we give help on MessageBox
 * @param FunctionNameOffset       (reference) Offset to start of first argument
 * @param ArgumentStartOffset      (reference) set to seek position of argument
 * @param flags                    (reference) bitset of VSAUTOCODEINFO_*
 *
 * @return
 *    0    Successful<BR>
 *    VSCODEHELPRC_CONTEXT_NOT_VALID<BR>
 *    VSCODEHELPRC_NOT_IN_ARGUMENT_LIST<BR>
 *    VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 */
int _antlr_fcthelp_get_start(_str (&errorArgs)[],
                             bool OperatorTyped,
                             bool cursorInsideArgumentList,
                             int &FunctionNameOffset,
                             int &ArgumentStartOffset,
                             int &flags,
                             int depth=0)
{
   return _c_fcthelp_get_start(errorArgs,
                               OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,
                               flags,
                               depth);
}
int _lex_fcthelp_get_start(_str (&errorArgs)[],
                           bool OperatorTyped,
                           bool cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags,
                           int depth=0)
{
   return _c_fcthelp_get_start(errorArgs,
                               OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,
                               flags,
                               depth);
}
int _yacc_fcthelp_get_start(_str (&errorArgs)[],
                            bool OperatorTyped,
                            bool cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags,
                            int depth=0)
{
   return _c_fcthelp_get_start(errorArgs,
                               OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,
                               flags,
                               depth);
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get
 * <P>
 * Context Tagging&reg; hook function for retrieving the information
 * about each function possibly matching the current function call
 * that function help has been requested on.
 * <P>
 * If there is no help for the first function, a non-zero value
 * is returned and message is usually displayed.
 * <P>
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 * <P>
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <PRE>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type='';
 * </PRE>
 *
 * @param errorArgs                    (reference) error message arguments
 *                                     refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list            (reference) Structure is initially empty.
 *                                     FunctionHelp_list._isempty()==true
 *                                     You may set argument lengths to 0.
 *                                     See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed    (reference) Indicates whether the data in
 *                                     FunctionHelp_list has been changed.
 *                                     Also indicates whether current
 *                                     parameter being edited has changed.
 * @param FunctionHelp_cursor_x        Indicates the cursor x position
 *                                     in pixels relative to the edit window
 *                                     where to display the argument help.
 * @param FunctionHelp_HelpWord        (reference) set to name of function
 * @param FunctionNameStartOffset      Offset to start of function name.
 * @param flags                        bitset of VSAUTOCODEINFO_*
 *
 * @return
 *    Returns 0 if we want to continue with function argument
 *    help.  Otherwise a non-zero value is returned and a
 *    message is usually displayed.
 *    <PRE>
 *    1    Not a valid context
 *    (not implemented yet)
 *    10   Context expression too complex
 *    11   No help found for current function
 *    12   Unable to evaluate context expression
 *    </PRE>
 */
int _antlr_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   bool &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,
                         FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info, 
                         visited, depth);
}
int _lex_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   bool &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,
                         FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info, 
                         visited, depth);
}

int _yacc_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   bool &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_info=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,
                         FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info, 
                         visited, depth);
}
