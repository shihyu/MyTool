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
#import "cjava.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "context.e"
#import "ccontext.e"
#import "cidexpr.e"
#import "csymbols.e"
#import "cutil.e"
#import "dlgman.e"
#import "emacs.e"
#import "erlang.e"
#import "listproc.e"
#import "main.e"
#import "objc.e"
#import "perl.e"
#import "pmatch.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "recmacro.e"
#import "rul.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#endregion


static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;


bool _c_skip_template_prefix_word()
{
   tk := c_sym_gtk();
   tkinfo := c_sym_gtkinfo();
   return(tk==TK_ID &&
           (tkinfo:=="const" ||
            tkinfo:=="constexpr" ||
            tkinfo:=="constinit" ||
            tkinfo:=="static" ||
            tkinfo:=="volatile" ||
            tkinfo:=="typedef" ||
            tkinfo:=="virtual" ||
            tkinfo:=="new" ||
            tkinfo:=="gcnew" ||
            tkinfo:=="inline" ||
            tkinfo:=="restrict" ||
            tkinfo:=="register" ||
            tkinfo:=="friend" ||
            tkinfo:=="export" ||
            tkinfo:=="extern" ||
            tkinfo:=="public" ||
            tkinfo:=="private" ||
            tkinfo:=="protected" ||
            tkinfo:=="mutable" ||
            tkinfo:=="explicit"
           )
          );

}

bool _c_probablyTemplateArgList(int &FunctionNameStartOffset)
{
   if (!_LanguageInheritsFrom("c")) {
      return(false);
   }
   /*
      Check if we are in a template argument list
      [::][id::]id<  dsf<
   */
   int begin_col=c_begin_stat_col(false /* No RestorePos */,
                                  false /* Don't skip first begin statement marker */,
                                  false /* Don't return first non-blank */);
   if (!begin_col) {
      return(false);
   }
   FunctionNameStartOffset=(int)point('s');
   tk := c_next_sym();
   for (;;) {
      if (!_c_skip_template_prefix_word()) {
         break;
      }
      _clex_skip_blanks();
      FunctionNameStartOffset=(int)point('s');
      tk = c_next_sym();
   }
   if (tk=="::") {
      tk = c_next_sym();
   }
   for (;;) {
      if (tk!=TK_ID) {
         return(false);
      }
      tk = c_next_sym();
      if (tk!="::") {
         break;
      }
      tk = c_next_sym();
   }
   if (tk!="<" && tk!="!(") {
      return(false);
   }
   /*
      Assume we are actually inside a template argument list.
      Let _c_get_expression_info and _c_fcthelp_get do the rest of the
      work.
   */
   return(true);
}

/**
 * Find the start of a function call.  This determines quickly whether
 * or not we are in the context of a function call.
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
 *     0    Successful<BR>
 *     VSCODEHELPRC_CONTEXT_NOT_VALID<BR>
 *     VSCODEHELPRC_NOT_IN_ARGUMENT_LIST<BR>
 *     VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 */
int _c_fcthelp_get_start(_str (&errorArgs)[],
                         bool OperatorTyped,
                         bool cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags,
                         int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_c_fcthelp_get_start: IN, OperatorTyped="OperatorTyped);
   }
   errorArgs._makeempty();
   iscpp := false;
   isdlang := false;
   isrust := false;
   has_bracket_expressions := (_LanguageInheritsFrom("cs") || _LanguageInheritsFrom("java"));
   _str not_function_words=C_NOT_FUNCTION_WORDS;
   case_options := p_EmbeddedCaseSensitive? "":"i";
   if (_LanguageInheritsFrom("d")) {
      not_function_words=D_NOT_FUNCTION_WORDS;
      isdlang=true;
   } else if (_LanguageInheritsFrom("c")) {
      iscpp=true;
   } else if (_LanguageInheritsFrom("rs")) {
      isrust=true;
   } else if (_LanguageInheritsFrom("cs")) {
      iscpp=true;
      not_function_words=CS_NOT_FUNCTION_WORDS;
   } else if (_LanguageInheritsFrom("java")) {
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
   } else if (_LanguageInheritsFrom("rul")) {
      not_function_words=RUL_NOT_FUNCTION_WORDS;
   }
   gInJavadoc_flag=0;
   exclude_colors := "xcs";
   flags=0;
   int cfg=_clex_find(0,"g");
   if (cfg==CFG_COMMENT) {
      if (_inJavadocSeeTag()) {
         flags|=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         gInJavadoc_flag=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         gInJavadoc_linenum=p_line;
         exclude_colors="xs";
      } else {
         //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   /*} else if(cfg==CFG_STRING) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);*/
   } else {
      gInJavadoc_linenum=(p_active_form.p_name=="_javadoc_form")?p_line:0;
   }
   //if (cursorInsideArgumentList || OperatorTyped)
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();
   typeless orig_seek=point('s');
   status := 0;
   first_less_than_seek := 0;
   have_d_template_signature := false;
   have_rust_macro_signature := false;
   ch := "";
   word := "";
   {
      if (OperatorTyped && last_event()=="<") {
         first_less_than_seek=orig_seek-1;
         flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
      } else {
         if ((iscpp || isdlang || _LanguageInheritsFrom("java")) &&
             !ginFunctionHelp && cursorInsideArgumentList) {
            status=search('[;}{()<>]','-rh@'exclude_colors);
            if (!status) {
               ch=get_text_safe();
               if ((!isdlang && ch=="<") || (isdlang && ch=="(" && get_text_left()=="!")) {
                  if (ch=="(") left();
                  first_less_than_seek=(int)point('s');
                  left();
                  if (get_text_safe()!="<") { // Have << or < at beginning of line
                     if (gInJavadoc_flag) {
                        status=search('[~ \t\r\n]','@rh-');
                     } else {
                        status=_clex_skip_blanks('-');
                     }
                     VS_TAG_IDEXP_INFO junk;
                     tag_idexp_info_init(junk);
                     status=_c_get_expression_info(false, junk);
                     if (!status) {
                        flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
                     }
                  }
               }
            }
            restore_pos(orig_pos);
         }

      }
      if (_chdebug) {
         isay(depth, "_c_get_fcthelp_start: IN TEMPLATE_ARGLIST:"(flags&VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST));
      }
#if 0
      ch=get_text_safe();
      if (ch==")" ||
          (OperatorTyped && (ch=="(" || ch==";" || ch=="{"))) {
         if(p_col==1){up();_end_line();} else {left();}
      }
#endif
      orig_col := p_col;
      orig_line := p_line;
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // Just look for beginning of statement
         if (_LanguageInheritsFrom("cs")) {
            // Special case for cast using 'as'
            status=search('[;}{]|:bas:b','-rh@'exclude_colors);
         } else {
            status=search('[;}{]','-rh@'exclude_colors);
         }
      } else {
         status=search('[;}{()]','-rh@'exclude_colors);
      }
      if (!status && p_line==orig_line && p_col==orig_col) {
         status=repeat_search();
      }
      ArgumentStartOffset= -1;
      for (;;) {
         if (status) {
            if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
               c_begin_stat_col(false,false,false);
            }
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get_start H"__LINE__": BREAK seek="_nrseek());
            }
            break;
         }
         ch=get_text_safe();
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get_start H"__LINE__": LOOPING ch="ch);
         }
         if (ch=="(") {
            save_pos(auto p);
            if( p_col==1 ){
               up();_end_line();
            } else {
               left();
               // check for D style !( template arguments
               if (isdlang && get_text_safe()=="!") left();
               if (isrust  && get_text_safe()=="!") left();
            }
            typeless p1,p2,p3,p4;
            save_search(p1,p2,p3,p4);
            if (gInJavadoc_flag) {
               search('[~ \t\r\n]','@rh-');
            } else {
               _clex_skip_blanks('-');
            }
            restore_search(p1,p2,p3,p4);
            ch=get_text_safe();

            // check for C++ overloaded operators
            if (!isrust) {
               _c_skip_operators_left();
            }

            ch=get_text_safe();
            word=cur_identifier(auto junk=0);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get_start H"__LINE__": BEFORE PAREN, ch="ch" word="word);
            }
            restore_pos(p);
            if (pos('['word_chars']',ch,1,'r')) {
               if (pos(" "word" ",not_function_words,1,case_options)) {
                  if (OperatorTyped && ArgumentStartOffset== -1) {
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get_start: NOT FUNCTION");
                     }
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get_start: BREAK NOT FUNCTION");
                  }
                  break;
               }
               ArgumentStartOffset=(int)point('s')+1;
            } else {
               /*
                  OperatorTyped==true
                      Avoid give help when have
                      myproc(....4+( <CursorHere>

               */
               if (OperatorTyped && ArgumentStartOffset== -1 &&
                   ch!=")" &&   // (*pfn)(a,b,c)  OR  f(x)(a,b,c)
                   ch!="]" &&   // calltab[a](a,b,c)
                   ch!=">"      // new STACK<stuff>(a,b,c)
                  ){
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get_start: NOT VALID ch="ch"=");
                  }
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               if (ch==")" || ch=="]" || (!isdlang && !isrust && ch==">")) {
                  ArgumentStartOffset=(int)point('s')+1;
               }
            }
         } else if (ch == "}" && has_bracket_expressions) { 
            // ie: new int[] {} or new Runnable() { public void run() {} }
            status = find_matching_paren(true);
            if (status) {
               restore_pos(orig_pos);
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get_start: H1 FIND MATCHING PAREN FAILED");
               }
               return(1);
            }
            status = repeat_search();
            continue;
         } else if (ch==")" || ch==">") {
            status=find_matching_paren(true);
            if (status) {
               restore_pos(orig_pos);
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get_start: H1 FIND MATCHING PAREN FAILED");
               }
               return(1);
            }
            save_pos(auto p);
            if(p_col==1){
               up();_end_line();
            } else {
               left();
               if (isdlang && get_text_safe()=="!") {
                  left();
                  have_d_template_signature=true;
               }
               if (isrust && get_text_safe()=="!") {
                  left();
                  have_rust_macro_signature=true;
               }
            }
            typeless p1,p2,p3,p4;
            save_search(p1,p2,p3,p4);
            if (gInJavadoc_flag) {
               status=search('[~ \t\r\n]','@rh-');
            } else {
               status=_clex_skip_blanks('-');
            }
            restore_search(p1,p2,p3,p4);
            word=cur_identifier(auto junk=0);
            if (pos(" "word" "," if elsif elseif while catch switch ")) {
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get_start: BREAK if else while catch");
               }
               break;
            }
            restore_pos(p);
         } else {
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get_start: NO MATCH FOR CHAR ch="ch);
            }
            break;
         }
         status=repeat_search();
      }
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get_start: ArgumentStartOffset="ArgumentStartOffset);
      }
      if (ArgumentStartOffset<0) {
         if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get_start: H1 NOT IN TEMPLATE ARGUMENT LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
      } else {
         goto_point(ArgumentStartOffset);
      }
   }
   if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
      if (isdlang) {
         status=search('!(','h@'exclude_colors);
      } else {
         status=search('<','h@'exclude_colors);
      }
      while (!status) {
         if (point('s')>=first_less_than_seek) {
            break;
         }
         typeless localp;
         save_pos(localp);
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         c_prev_sym2();
         restore_pos(localp);
         if(c_sym_gtk() != TK_ID || c_sym_gtkinfo() != "template") {
            break;
         }
         right();
         if (isdlang) {
            status=search('!(','h@'exclude_colors);
         } else {
            status=search('<','h@'exclude_colors);
         }
      }
      if (!status && get_text_safe()=="!") right();
      right();
   }
   ArgumentStartOffset=(int)point('s');
   left();
   if ((isdlang && get_text_safe()=="(" && get_text_left()=="!") ||
       (get_text_safe()=="<" && (iscpp || _LanguageInheritsFrom("java")))) {
      save_pos(auto p2);
      int junk;
      is_template_arglist := _c_probablyTemplateArgList(junk);
      restore_pos(p2);
      if (is_template_arglist) {
         flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
      } else {
         if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get_start: H2 NOT IN TEMPLATE ARGUMENT LIST");
            }
            return(1);
         }
      }
   } else {
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get_start: H3 NOT IN TEMPLATE ARGUMENT LIST");
         }
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
   }
   if ((isdlang || isrust) && get_text_safe()=="(" && get_text_left()=="!") left();
   left();
   lastid := "";
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   _clex_skip_blanks('-');
   restore_search(p1,p2,p3,p4);
   search('[~ \t]|^','-rh@');

   // check for C++ overloaded operators
   _c_skip_operators_left();

   // skip over D langauge template signature
   if (isdlang && get_text_safe()==')' && have_d_template_signature) {
      status=find_matching_paren(true);
      if (status) {
         restore_pos(orig_pos);
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get_start: DLANG FIND MATCHING PAREN FAILED");
         }
         return(1);
      }
      if (get_text_left()=="!") left();
      left();
   }

   // skip over Rust langauge template signature
   if (isrust && get_text_safe()==')' && have_rust_macro_signature) {
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get_start: RUST");
      }
      status=find_matching_paren(true);
      if (status) {
         restore_pos(orig_pos);
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get_start: RUST FIND MATCHING PAREN FAILED");
         }
         return(1);
      }
      if (get_text_left()=="!") left();
      left();
   }

   if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
      ch=get_text_safe();
      if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) &&
          (ch==")" || ch=="]" || (ch==">" && (iscpp || _LanguageInheritsFrom("java"))))) {
         FunctionNameOffset=ArgumentStartOffset-1;
         return(0);
      } else {
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get_start: NOT WORD CHAR ch="ch);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      int end_col=p_col+1;
      search('[~'word_chars']\c|^\c','-rh@');
      lastid=_expand_tabsc(p_col,end_col-p_col);
      FunctionNameOffset=(int)point('s');
   }
   /*if (cursorInsideArgumentList) {
      restore_pos(orig_pos);
   } */
   if (pos(" "lastid" ",not_function_words,1,case_options)) {
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get_start: NOT FUNCTION WORD");
      }
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   return(0);
}

/**
 * Bookkeeping for _c_fcthelp_get
 */
struct FnHelpCtx {
   int brace_nesting;
   int param_num;
   int lparen_offset;
   _str param_name;    // for named parameters (can override param_num)
   int param_name_num;
};

void initFnHelpCtx(FnHelpCtx& c, int offset = 0)
{
   c.brace_nesting = 0;
   c.param_num = 1;
   c.lparen_offset = offset;
   c.param_name = "";
   c.param_name_num = 1;
}

_str fnHelpCtxString(FnHelpCtx& c) {
   return nls("<FnHelpCtx: brace_nesting=%s, param_num=%s, lparen_offset=%s param_name=%s@%s>", c.brace_nesting, c.param_num, c.lparen_offset, c.param_name, c.param_name_num);
}


/**
 * Try parsing a python-style constructor expression for function help.
 */
static bool try_python_constructor(VS_TAG_RETURN_TYPE &rt,
                                      VS_TAG_IDEXP_INFO &idexp_info, 
                                      VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth, "try_python_constructor: IN");
   }
   VS_TAG_RETURN_TYPE rttemp;
   tag_return_type_init(rttemp);
   if (idexp_info.prefixexp != "") {
      /*
         Handle constructor call for class from module
           inst=moduleName.className(a1,a2)
           inst=outerClass.innerClass(a1,a2)
           inst=moduleName.outerClass.innerClass(a1,a2)
      */
      //say("******************************try "idexp_info.prefixexp:+idexp_info.lastid);
      status := _c_get_type_of_prefix(auto errorArgs, idexp_info.prefixexp:+idexp_info.lastid, rttemp, visited, depth+1);
      //status = _c_get_type_of_prefix(errorArgs, "nestedclass/outerC.innerC", rttemp);
      //say("status="status" rttemp.return_type="rttemp.return_type);
      if (rttemp.return_type==idexp_info.lastid || 
          idexp_info.prefixexp:+idexp_info.lastid==translate(rttemp.return_type,".",VS_TAGSEPARATOR_package)
         ) {
         tag_return_type_init(rt);
         idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid".";
         //say("idexp_info.prefixexp="idexp_info.prefixexp);
         //idexp_info.prefixexp="nestedclass/outerC::innerC";
         //idexp_info.prefixexp="innerC.";
         idexp_info.lastid="__init__";
         status = _c_get_type_of_prefix(errorArgs,idexp_info.prefixexp, rt, visited, depth+1);
         //status = _c_get_type_of_prefix(errorArgs,"nestedclass::outerC::innerC", rt);
         //say("h2 status="status" rt.return_type="rt.return_type);
         //rt.return_type="nestedclass/outerC::innerC";
         if (_chdebug) {
            isay(depth, "try_python_constructor: status="status);
         }
         return(!status);
      }
   } else {
      prefix_expression := idexp_info.lastid;
      status := _c_get_type_of_prefix(auto errorArgs, idexp_info.lastid, rttemp, visited, depth+1);

      if (status < 0) {
         tag_get_current_context(auto cur_tag_name, 
                                 auto cur_tag_flags, 
                                 auto cur_type_name, 
                                 auto cur_type_id, 
                                 auto cur_context, 
                                 auto cur_class, 
                                 auto cur_package,
                                 visited, depth+1);
         if (cur_context != "") {
            tag_return_type_init(rttemp);
            prefix_expression = cur_context"."idexp_info.lastid;
            status = _c_get_type_of_prefix(errorArgs, prefix_expression, rttemp, visited, depth+1);
         }
         if (status < 0 && cur_package != "") {
            tag_return_type_init(rttemp);
            prefix_expression = cur_package"."idexp_info.lastid;
            status = _c_get_type_of_prefix(errorArgs, prefix_expression, rttemp, visited, depth+1);
         }
      }

      if (rttemp.return_type==idexp_info.lastid ||
          endsWith(rttemp.return_type,VS_TAGSEPARATOR_package:+idexp_info.lastid)
          ) {
         tag_return_type_init(rt);
         idexp_info.prefixexp=idexp_info.lastid".";
         idexp_info.lastid="__init__";
         //say("special "dec2hex(idexp_info.info_flags));
         status = _c_get_type_of_prefix(errorArgs,prefix_expression, rt, visited, depth+1);
         //say("status="status);
         if (_chdebug) {
            isay(depth, "try_python_constructor: status="status);
         }
         return(!status);
      }
   }
   if (_chdebug) {
      isay(depth, "try_python_constructor: NOT CONSTRUCTOR");
   }
   return(false);
}

_str _e_parse_for_slickc_named_argument(bool search_for_start=false, int depth=0)
{
   if (_chdebug) {
      isay(depth, "parse_for_slickc_named_argument: IN");
   }
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   if (search_for_start) {
      status := search("[,(]", '-rh@Xcs');
      if (status < 0) restore_pos(p);
   }

   named_arg := "";
   do {
      // check that the next symbol is an identifier or "..."
      right();
      cfg := _clex_skip_blanks('q');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING || cfg==CFG_KEYWORD || cfg==CFG_NUMBER) {
         break;
      }
      start_col := p_col;
      if (get_text(3) == "...") {
         named_arg = "...";
      } else {
         named_arg = cur_identifier(start_col);
         if (named_arg == "") break;
      }

      // now check for ':" separator
      p_col = start_col+length(named_arg);
      _clex_skip_blanks('q');
      ch := get_text();
      if (ch != ":") {
         named_arg = "";
         break;
      }

      // and make sure it isn't another Slick-C operator that starts with ':'
      right();
      ch = get_text();
      if (pos(ch, "=:!<>[")) {
         named_arg = "";
         break;
      }

      // we have found our mojo
      if (_chdebug) {
         isay(depth, "parse_for_slickc_named_argument: found named argument = "named_arg);
      }
   } while (false);

   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   if (_chdebug) {
      isay(depth, "parse_for_slickc_named_argument: OUT");
   }
   return named_arg;
}

/**
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
int _c_fcthelp_get(_str (&errorArgs)[],
                   VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                   bool &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int /*AutoCodeInfoFlags*/ flags,
                   VS_TAG_BROWSE_INFO symbol_to_match=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug > 9) {
      isay(depth, "_c_fcthelp_get: fnoffset="FunctionNameStartOffset", flags=0x"_dec2hex(flags));
   }

   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;
   static _str prev_ParamName;
   if (FunctionNameStartOffset < 0 || flags == 0xffffffff) {
      prev_prefixexp  = "";
      prev_otherinfo  = "";
      prev_info_flags = 0;
      prev_ParamNum   = 0;
      prev_ParamName  = "";
      return(0);
   }
   
   errorArgs._makeempty();

   // check language mode
   common := C_COMMON_END_OF_STATEMENT_RE;
   case_sensitive := true;
   isjava := false;
   slickc := false;
   iscsharp := false;
   javascript := false;
   isrul := false;
   isphp := false;
   isdlang := false;
   isrlang := false;
   isrust := false;
   isother := false;
   isobjc := false;
   ispython := false;
   isperl := false;
   iserlang := false;

   FunctionHelp_list_changed=false;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }

   stack_top := 0;
   FnHelpCtx ctx_stack[];
   initFnHelpCtx(ctx_stack[0], 0);

   typeless cursor_offset=point('s');
   save_pos(auto p);
   orig_left_edge := p_left_edge;
   goto_point(FunctionNameStartOffset);
   word_chars := _clex_identifier_chars();

   if (_LanguageInheritsFrom("java")) {
      isjava=true;
      gInJavadoc_linenum = (p_active_form.p_name=="_javadoc_form")? p_line:0;
      if (gInJavadoc_linenum) {
         common='[,{};()]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      } else if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // for now, we don't try to handle parens in template argument lists
         common='[,#{};<>]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,#{};()]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      }
   } else if (_LanguageInheritsFrom("e")) {
      slickc=true;
      common='[,#{};()]|'common'|'SLICKC_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('js')) {
      javascript=true;
      common='[,{};()[]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("cfscript")) {
      javascript=true;
      case_sensitive=false;
      common='[,{};()[]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("rul")) {
      isrul=true;
      common='[,;()[]|'common'|'RUL_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("phpscript")) {
      isphp=true;
      common='[,;()[]|'common'|'PHP_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("sas")) {
      isother=true;
      case_sensitive=false;
      common='[,;()[]|'common'|'SAS_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("cs")) {
      iscsharp=true;
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         common='[<>,{};()]|'common'|'CS_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,{};()]|'common'|'CS_MORE_END_OF_STATEMENT_RE;
      }
   } else if (_LanguageInheritsFrom("d")) {
      isdlang=true;
      common='[,{};()]|'common'|'D_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom("rs")) {
      isrust=true;
      common='[,;()[]|'common;
   } else if (_LanguageInheritsFrom("m")) {
      isobjc=true;
      save_pos(auto op);
      // check for selector colon
      search('[~'word_chars' \t]|$','rh@');
      if (get_text_safe() == ":") {
         ++stack_top;
         initFnHelpCtx(ctx_stack[stack_top], (int)point('s'));
      }
      restore_pos(op);
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // for now, we don't try to handle parens in template argument lists
         common='[,#{};<>]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,#{};()]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      }

   } else if (_LanguageInheritsFrom("c")) {
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // for now, we don't try to handle parens in template argument lists
         common='[,#{};<>]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,#{};()]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      }

   } else {
      ispython = _LanguageInheritsFrom("py");
      isperl   = _LanguageInheritsFrom("pl");
      iserlang = _LanguageInheritsFrom("erlang");
      isrlang  = _LanguageInheritsFrom("r");
      case_sensitive=p_EmbeddedCaseSensitive;
      isother=true;
      common='[,;()[]|'common;
   }

   has_bracket_expressions := (iscsharp || isjava);
   in_d_template_arglist := false;
   had_d_template_arglist := false;
   in_rust_macro_arglist := false;
   had_rust_macro_arglist := false;
   exclude_colors := "xcs";
   if (flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      exclude_colors="xs";
   }
   case_options := "";
   if (!case_sensitive) {
      case_options="i";
   }

   // enum, struct class
   status := search(common,'rh@'case_options:+exclude_colors);
   // found_function_pointer := false;
   preprocessing_top := 0;
   int preprocessing_ParamNum_stack[];
   int preprocessing_offset_stack[];
   nesting := 0;

   for (;;) {
      if (status) {
         break;
      }
      ch := get_text_safe();
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get: nesting="stack_top" ch="ch" cursor_offset="cursor_offset" p="point('s')" "fnHelpCtxString(ctx_stack[stack_top]));
      }
      if (cursor_offset<=point('s')) {
         break;
      }
      if (ch == ",") {
         if (ctx_stack[stack_top].brace_nesting == 0) {
            ctx_stack[stack_top].param_num++;
            if (slickc || iscsharp) {
               maybe_named_argument := _e_parse_for_slickc_named_argument(false,depth+1);
               if (maybe_named_argument != "") {
                  ctx_stack[stack_top].param_name = maybe_named_argument;
                  ctx_stack[stack_top].param_name_num = ctx_stack[stack_top].param_num;
               }
               #if 0
               ext := _get_extension(p_buf_name, returnDot:true);
               #endif
            }
         }
         status=repeat_search();
         continue;
      }
      if (ch==")") {
         --stack_top;
         if (in_d_template_arglist && stack_top<=0) {
            in_d_template_arglist=false;
            had_d_template_arglist=true;
            status=repeat_search();
            continue;
         }
         if (in_rust_macro_arglist && stack_top<=0) {
            in_rust_macro_arglist=false;
            had_rust_macro_arglist=true;
            status=repeat_search();
            continue;
         }
         if (stack_top<=0 /*&& (!found_function_pointer && stack_top<0)*/) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: H1 NOT IN ARGUMENT LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         //found_function_pointer = false;
         status=repeat_search();
         continue;
      }
      if (ch==">") {
         --stack_top;
         if (stack_top<0 || (stack_top==0 && (int)point('s')+1 >= cursor_offset)) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: H2 NOT IN ARGUMENT LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         status=repeat_search();
         continue;
      }
      if (ch=="(") {
         // Determine if this is a new function
         if (isdlang && get_text_left()=="!") {
            in_d_template_arglist=true;
         } else if (isrust && get_text_left()=="!") {
            in_rust_macro_arglist=true;
         }
         ++stack_top;
         initFnHelpCtx(ctx_stack[stack_top], (int)point('s'));
         /*if (get_text(2)=="(*") {
            found_function_pointer = true;
         } */
         if (slickc || iscsharp) {
            maybe_named_argument := _e_parse_for_slickc_named_argument(false,depth+1);
            if (maybe_named_argument != "") {
               ctx_stack[stack_top].param_name = maybe_named_argument;
               ctx_stack[stack_top].param_name_num = ctx_stack[stack_top].param_num;
            }
         }
         status=repeat_search();
         continue;
      }
      if (ch=="[") {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(p);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: BRACKETS MISMATCH");
            }
            return(VSCODEHELPRC_BRACKETS_MISMATCH);
         }
         status=repeat_search();
         continue;
      }
      if (ch=="<") {
         // Determine if this is a new function
         ++stack_top;
         initFnHelpCtx(ctx_stack[stack_top], (int)point('s'));
         status=repeat_search();
         continue;
      }
      if (ch == "}") {
         if (ctx_stack[stack_top].brace_nesting > 0) {
            ctx_stack[stack_top].brace_nesting--;
            status = repeat_search();
            continue;
         }
         restore_pos(p);
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get: H3 NOT IN ARGUMENT LIST");
         }
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      if (ch==";") {
         // Semicolons can happen inside of anonymous classes.
         if (ctx_stack[stack_top].brace_nesting < 1) {
            restore_pos(p);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: H4 NOT IN ARGUMENT LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         status = repeat_search();
         continue;
      }
      if (ch=="#" || ch=="{" || (pos("[~"word_chars"]",get_text_safe(1,match_length('s')-1),1,"r") &&
                                 pos("[~"word_chars"]",get_text_safe(1,match_length('s')+match_length()),1,"r"))
          ) {
         // IF this could be enum, struct, or class
         _str word;
         junk := 0;
         if (stack_top>=1 && (ch=="e" || ch=="s" || ch=="c")) {
            word=cur_identifier(junk);
            if (word=="enum" || word=="struct" || word=="class") {
               status=repeat_search();
               continue;
            }
         }
         // IF we need to check for conditional preprocessing
         if (/*!isjava &&*/ !javascript && !isphp && ch=="#" && stack_top>0) {
            right();
            word=cur_identifier(junk);
            if (word=="if" || word=="ifdef" || word=="ifndef") {
               // IF we are in conditional preprocessing.
               ++preprocessing_top;
               preprocessing_ParamNum_stack[preprocessing_top]=ctx_stack[stack_top].param_num;
               preprocessing_offset_stack[preprocessing_top]=ctx_stack[stack_top].lparen_offset;
               status=repeat_search();
               continue;
            } else if (word=="elif" || word=="else") {
               if (preprocessing_top && stack_top>0 &&
                   preprocessing_offset_stack[preprocessing_top]==ctx_stack[stack_top].lparen_offset
                   ) {
                  ctx_stack[stack_top].param_num=preprocessing_ParamNum_stack[preprocessing_top];
                  status=repeat_search();
                  continue;
               }

            } else if (word=="endif") {
               if (preprocessing_top) {
                  --preprocessing_top;
               }
               status=repeat_search();
               continue;
            } else if (word!="define" && word!="undef" && word!="include" &&
                       word!="pragma" && word!="error") {
               status=repeat_search();
               continue;
            }
         }
         // Case for common java/cs construct to create an
         // from an initializer at runtime:  new int[] { 1, 2, 3 }; 
         // Or a java anonymous class:
         //  new Interface() { public void someMethod() { .... }}
         if (ch == "{" && has_bracket_expressions) {
            ctx_stack[stack_top].brace_nesting++;
            status=repeat_search();
            continue;
         }

         // If we're in an anonymous class def, we're going to 
         // hit a lot of tokens that would normally terminate 
         // function help.
         // Ignore these till we get out of the class, or until we overshoot the start pos.
         if (!(has_bracket_expressions && ctx_stack[stack_top].brace_nesting)) {
            restore_pos(p);
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: H5 NOT IN ARGUMENT LIST");
            }
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
      }
      status=repeat_search();
   }
   if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST) {
      restore_pos(p);
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get: IN TEMPLATE ARGUMENT LIST TEST");
      }
      return(0);
   }
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   if (_chdebug) {
      isay(depth, "_c_fcthelp_get: stack_top="stack_top);
      idump(depth+1, ctx_stack, "_c_fcthelp_get: ctx_stack");
   }

   typeless tag_files = tags_filenamea(p_LangId);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         if (_chdebug) {
            isay(depth, "_c_fcthelp_get: NO HELP FOR FUNCTION");
         }
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(ctx_stack[stack_top].lparen_offset+1);
      if (_chdebug) {
         isay(depth, "_c_fcthelp_get: stack_top="stack_top" goto offset="ctx_stack[stack_top].lparen_offset+1);
      }

      if (had_d_template_arglist || had_rust_macro_arglist) {
         goto_point(ctx_stack[stack_top].lparen_offset);
         if (get_text_safe()=="(") left();
         _clex_skip_blanks("-");
         if (get_text_safe() == ")") {
            find_matching_paren(true);
            right();
            //if (get_text_safe()=="(" && get_text_left()=="!") {
            //   left();
            //}
         }
      }
      if (isrust && get_text_left() == '(' && get_text(1, _nrseek()-2) == '!') {
         had_rust_macro_arglist = true;
      }
         
      typeless junk;
      if ((flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) || had_d_template_arglist) {
         // Don't allow any failures
         while (stack_top>1) {
            ctx_stack._deleteel(1);
            --stack_top;
         }
         left();left();
         if (isperl) {
            status=_pl_get_expression_info(false,idexp_info,visited,depth+1);
         } else if (iscsharp) {
            status=_cs_get_expression_info(false,idexp_info,visited,depth+1);
         } else {
            status=_c_get_expression_info(false,idexp_info,visited,depth+1);
         }
         idexp_info.info_flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
         errorArgs = idexp_info.errorArgs;
      } else if (had_rust_macro_arglist) {
         // Don't allow any failures
         while (stack_top>1) {
            ctx_stack._deleteel(1);
            --stack_top;
         }
         left();left();
         status=_c_get_expression_info(false,idexp_info,visited,depth+1);
         errorArgs = idexp_info.errorArgs;
      } else {
         if (isperl) {
            status=_pl_get_expression_info(true,idexp_info,visited,depth+1);
         } else if (iscsharp) {
            status=_cs_get_expression_info(true,idexp_info,visited,depth+1);
         } else if (iserlang) {
            status=_erlang_get_expression_info(true,idexp_info,visited,depth+1);
         } else {
            status=_c_get_expression_info(true,idexp_info,visited,depth+1);
         }
         errorArgs = idexp_info.errorArgs;
      }
      errorArgs[1] = idexp_info.lastid;


    if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_c_fcthelp_get",depth);
         isay(depth,"_c_fcthelp_get: idexp_info status="status);
    }
      if (!status) {
         // get parameter number and cursor position
         ParamNum     := ctx_stack[stack_top].param_num;
         ParamName    := ctx_stack[stack_top].param_name;
         ParamNameNum := ctx_stack[stack_top].param_name_num;
         ParamFoundAt := ParamNum;
         set_scroll_pos(orig_left_edge,p_col);

         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
             gLastContext_FunctionName :== idexp_info.lastid &&
             gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
             prev_otherinfo :== idexp_info.otherinfo &&
             prev_info_flags == idexp_info.info_flags &&
             prev_ParamNum   == ParamNum &&
             prev_ParamName  == ParamName 
            ) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }

         // find matching symbols
         //say("lastid="lastid" prefixexp="prefixexp" ParamNum="ParamNum" otherinfo="otherinfo);
         globals_only := false;
         found_define := 0;
         _str match_list[];
         match_symbol := idexp_info.lastid;
         match_class := "";
         match_flags := SE_TAG_FILTER_ANY_PROCEDURE;
         tag_return_type_init(auto rt);
         if (!isjava && !iscsharp && !javascript && !isrul && !isphp && !isdlang && !isother) {
            match_flags |= SE_TAG_FILTER_DEFINE;
            found_define = tag_check_for_define(idexp_info.lastid, p_line, tag_files, match_symbol);
            //say("tag_check_for_define, lastid="lastid" match_symbol="match_symbol"matches="found_define);
         }
         if (_LanguageInheritsFrom("sas")) {
            match_flags |= SE_TAG_FILTER_DEFINE;
         }
         if (!slickc && (idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) && !had_d_template_arglist) {
            match_flags = SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_INTERFACE;
         }
         if (had_rust_macro_arglist) {
            match_flags |= SE_TAG_FILTER_DEFINE;
         }

         // check for C++ overloaded operators
         if (pos("operator ", idexp_info.lastid, 1)) {
            parse idexp_info.lastid with . idexp_info.lastid;
         }

         // find symbols matching the given class
         num_matches := 0;
         tag_clear_matches();
         // this may be a variable MYCLASS a(
         if ((idexp_info.prefixexp==null || idexp_info.prefixexp=="") && 
             (idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL)) {
            idexp_info.otherinfo    = stranslate(idexp_info.otherinfo,":","::");
            parse idexp_info.otherinfo with idexp_info.otherinfo "<" . ;
            tag_split_class_name(idexp_info.otherinfo, match_symbol, match_class);
            cmatch_class := tag_join_class_name(match_symbol, match_class, tag_files, true, false, false, visited, depth+1);
            //say("111 match_symbol="match_symbol" match_class="cmatch_class);

            if (idexp_info.otherinfo != "") {
               // pull out the BIG guns to resolve the return type of the var
               VS_TAG_RETURN_TYPE var_rt;
               tag_return_type_init(var_rt);
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: OTHERINFO evaluating return type of "idexp_info.lastid);
               }
               if (!_c_get_return_type_of(errorArgs, tag_files, idexp_info.lastid, "", 0, isjava||iscsharp||isdlang, SE_TAG_FILTER_ANYTHING, true, false, var_rt, visited, depth+1)) {
                  cmatch_class = var_rt.return_type;
               } else if (!_c_parse_return_type(errorArgs, tag_files, 
                                                idexp_info.lastid, 
                                                "", p_buf_name, 
                                                idexp_info.otherinfo, 
                                                isjava||iscsharp||isdlang, var_rt, 
                                                visited, depth+1)) {
                  cmatch_class = var_rt.return_type;
               }
            }
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: cmatch_class="cmatch_class);
            }

            tag_clear_matches();
            _UpdateLocals(true);
            tag_list_in_class(match_symbol, cmatch_class, 
                              0, 0, tag_files,
                              num_matches, def_tag_max_function_help_protos,
                              SE_TAG_FILTER_ANY_PROCEDURE,
                              SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS,
                              true, case_sensitive,
                              null, null, visited, 1);
            if (num_matches <= 0) {
               match_symbol = idexp_info.lastid;
            }
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: match_symbol="match_symbol);
            }
         }

         // initializer list of constructor MYCLASS::MYCLASS() : BASECLASS(&lt;here&gt;
         if (idexp_info.info_flags & (VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) {
            idexp_info.otherinfo    = stranslate(idexp_info.otherinfo,":","::");
            tag_split_class_name(idexp_info.otherinfo,junk,match_class);
            if (match_class == "") {
               match_class = idexp_info.otherinfo;
            }
            match_symbol = idexp_info.lastid;
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: match_symbol="match_symbol" match_class="match_class);
            }
            tag_clear_matches();
            _UpdateLocals(true);
            tag_list_in_class(match_symbol, match_class, 
                              0, 0, tag_files,
                              num_matches, def_tag_max_function_help_protos,
                              SE_TAG_FILTER_ANY_PROCEDURE/*|SE_TAG_FILTER_ANY_STRUCT*/,
                              SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS,
                              true, true, null, null, visited, 1);
            if (num_matches==0) {
               tag_list_in_class(match_symbol, match_class, 
                                 0, 0, tag_files,
                                 num_matches, def_tag_max_function_help_protos,
                                 SE_TAG_FILTER_ANYTHING,
                                 SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_PRIVATE,
                                 //SE_TAG_FILTER_MEMBER_VARIABLE/*|SE_TAG_FILTER_ANY_STRUCT*/,
                                 //SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS,
                                 true, true, null, null, visited, 1);
               if (!isjava && !iscsharp && !isphp && !isrul && !javascript && !isdlang && !isother && num_matches>0) {
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: INITIALIZER LIST evaluating return type of "match_symbol" in "match_class);
                  }
                  status = _c_get_return_type_of(errorArgs,tag_files,
                                                 match_symbol,match_class,
                                                 0,false /*isjava||javascript||isrul*/,
                                                 SE_TAG_FILTER_ANY_DATA,
                                                 false,false,rt,visited,depth+1);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: INITIALIZER LIST status="status" match_class="match_class" match_symbol="match_symbol" match_type="rt.return_type);
                  }
                  if (!status && rt.return_type!="" && rt.pointer_count==0) {
                     tag_clear_matches();
                     num_matches=0;
                     match_symbol=rt.return_type;
                     sep_pos := lastpos("[:/]",match_symbol);
                     if (sep_pos) {
                        match_symbol=substr(match_symbol,sep_pos+1);
                     }
                     match_class=rt.return_type;
                     tag_list_in_class(match_symbol, rt.return_type, 
                                       0, 0, tag_files,
                                       num_matches, def_tag_max_function_help_protos,
                                       SE_TAG_FILTER_ANY_PROCEDURE/*|SE_TAG_FILTER_ANY_STRUCT*/,
                                       SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_INCLASS,
                                       true, true, null, null, visited, 1);
                  }
               }
            }
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: num_matches="num_matches" here 2");
            }
         }
         is_py_constructor_call := false;

         // analyse prefix epxression to determine effective class
         if (num_matches == 0) {
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: xxx prefixexp="idexp_info.prefixexp" match_symbol="match_symbol);
            }
            //if (prefixexp=="new") {
            //   say("_c_fcthelp_get: new");
            //   prefixexp="";
            //}
            // remove unwelcome new operator
            if ((isjava || iscsharp || isphp || isdlang) && pos("new ",idexp_info.prefixexp)==1 && pos(")",idexp_info.prefixexp)) {
               idexp_info.prefixexp=substr(idexp_info.prefixexp,5);
               idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid;
            }
            if ((isjava || iscsharp || isphp || isdlang) && pos("new ",idexp_info.prefixexp) == 1) {
               // 08/24/2000 --
               //   Disabled this case, let _c_get_type_of_prefix take
               //   care if this grunt work.  That will be more powerful
               //   in terms of resolving inheritance, and typedefs, and
               //   all those other nasty things.  It also will correctly
               //   handle more cases with template classes.
               //
               // handle 'new' expressions as a special case
               outer_class := substr(idexp_info.prefixexp, 5) :+ idexp_info.lastid;
               if (_chdebug > 9) {
                  isay(depth, "_c_fcthelp_get: stripped new, outer_class="outer_class);
               }
               
               _maybe_strip(outer_class, '::');
               _maybe_strip(outer_class, '.');
               outer_class = stranslate(outer_class, ":", "::");

               // qualify in the face of imports, etc...
               _c_parse_return_type(errorArgs, tag_files, 
                                    "", outer_class, 
                                    p_buf_name, outer_class, 
                                    isjava||iscsharp, rt, visited, depth+1);

               // We peel the constructor name off of the parsed return type, 
               // because it has already removed template arguments and
               // other decorations from the name.
               tag_split_class_name(rt.return_type, match_symbol, outer_class);
               idexp_info.lastid = match_symbol;
               if (_chdebug ) {
                  isay(depth, "_c_fcthelp_get: new case match_symbol="match_symbol", rt="rt.return_type);
               }
               
               rt.pointer_count = 1;
               status = 0;
            } else if (idexp_info.prefixexp != "") {
               if ((pos("new ",idexp_info.prefixexp)==1 || pos("gcnew ", idexp_info.prefixexp)==1)) {
                  status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, idexp_info.prefixexp:+idexp_info.lastid, rt, visited, depth+1, 0);
               } else {
                  status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, idexp_info.prefixexp, rt, visited, depth+1, 0);
               }
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: _c_get_type_of_prefix returns "rt.return_type" status="status" match_tag="rt.taginfo);
               }
               if (status && (slickc || javascript || isrlang)) {
                  // oh, well, we tried...
                  status = 0;
               }
               if (status && (status!=VSCODEHELPRC_BUILTIN_TYPE || idexp_info.lastid!="")) {
                  restore_pos(p);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: BUILTIN, lastid="idexp_info.lastid);
                  }
                  continue;
               }
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
                  globals_only = true;
               }
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: match_symbol="match_symbol" prefix="idexp_info.prefixexp"=");
               }
               if (pos("new ",idexp_info.prefixexp)==1 || pos("gcnew ", idexp_info.prefixexp)==1) {
                  if (rt.return_type!="") {
                     // Force the return type to be qualified, if possible.
                     idexp_info.lastid = rt.return_type; 
                     _c_parse_return_type(errorArgs, tag_files, 
                                          "", rt.return_type, 
                                          p_buf_name, rt.return_type, 
                                          isjava||iscsharp, rt, visited, depth+1);
                     colon_pos := lastpos("[:/]",rt.return_type,"",'r');
                     if (colon_pos) {
                        match_symbol=substr(rt.return_type,colon_pos+1);
                     } else {
                        match_symbol=rt.return_type;
                     }
                  } else {
                     //rt.return_type=match_symbol;
                     rt.return_type = tag_join_class_name(match_symbol, rt.return_type, tag_files, case_sensitive, false, false, visited, depth+1);
                  }
               }
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: XXX match_class="match_class" match_symbol="match_symbol);
               }
            }

            context_flags := globals_only? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS;
            if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
               context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
               context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
               context_flags |= SE_TAG_CONTEXT_ALLOW_PRIVATE;
            }

            // compute current context, package name, and class name to
            // determine unusual access restrictions for java
            tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                    auto cur_type_name,auto cur_type_id,
                                    auto cur_class_name,auto cur_class_only,
                                    auto cur_package_name,
                                    visited, depth+1);

            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: current_context pkg_name="cur_package_name", cur_class_name="cur_class_name", cur_type_name="cur_type_name);
            }
            if ((pos(cur_package_name"/",rt.return_type)==1) ||
                (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
                 !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
               context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
               context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
            }
            // is this a reference to the constructor of the parent class in Java?
            if (!iscsharp && (isjava || isdlang) && idexp_info.lastid=="super") {
               _java_find_super(idexp_info.lastid,cur_class_name,tag_files,false,visited,depth+1);
            } else if (iscsharp && idexp_info.lastid=="base") {
               _java_find_super(idexp_info.lastid,cur_class_name,tag_files,false,visited,depth+1);
            }

            tag_clear_matches();
            // try to find 'lastid' as a member of the 'match_class'
            // within the current context
            if (idexp_info.lastid!="" || match_symbol!="") {
               if (found_define && idexp_info.lastid!=match_symbol) {
                  orig_match_symbol := match_symbol;
                  match_symbol=idexp_info.lastid;
                  match_symbol=orig_match_symbol;
               }
               
               _UpdateContextAndTokens(true);
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: match_symbol="match_symbol" rt.return_type="rt.return_type" p_buf_name="p_buf_name);
                  tag_dump_filter_flags(match_flags, "_c_fcthelp_get: before list in context", depth);
                  tag_dump_context_flags(context_flags, "_c_fcthelp_get: before list in context", depth);
                  //tag_dump_context("_c_fcthelp_get:", depth+1);
               }

               tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                           0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, case_sensitive, 
                                           visited, depth+1, rt.template_args);
               
               num_matches = tag_get_num_of_matches();
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: got "num_matches" from list_symbols_in_context(match_sym="match_symbol", return_type="rt.return_type", match_flags=0x"_dec2hex(match_flags)", ctx_flags=0x"_dec2hex(context_flags)")");
                  isay(depth, "_c_fcthelp_get: num tag files "tag_files._length());
                  idump(depth+1, tag_files, "_c_fcthelp_get: tag_files");
               }
               if (num_matches == 0 && idexp_info.prefixexp=="" &&
                   (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("cs")) && 
                   !pos(VS_TAGSEPARATOR_package, rt.return_type)) {
                  // If the type is not qualified, use the current context
                  // to add qualification if available.  Without this, 
                  // tag_list_symbols_in_context can fail when rt.return_type
                  // is contained within a namespace when you're completing 
                  // an unqualified reference from the same namespace.
                  _str qn;
                  tag_qualify_symbol_name(qn, rt.return_type, cur_class_name, "", tag_files, true, visited, depth+1);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: qualified name to: "qn);
                  }
                  if (rt.return_type != qn) {
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: try qualifying type to "qn);
                     }
                     tag_list_symbols_in_context(match_symbol, qn, 
                                                 0, 0, tag_files, "",
                                                 num_matches, def_tag_max_function_help_protos,
                                                 match_flags, context_flags,
                                                 true, case_sensitive, 
                                                 visited, depth+1, rt.template_args);
                  }
               }

               if (num_matches==0 && ispython) {
                  is_py_constructor_call=try_python_constructor(rt,idexp_info,visited,depth+1);
                  //say("YXXnum_matches="num_matches" rt.return_type="rt.return_type);
                  //say("YYmatch_flags="dec2hex(match_flags));
                  if (is_py_constructor_call) {
                     tag_list_symbols_in_context("__init__", rt.return_type, 0, 0, tag_files, "",
                                                 num_matches, def_tag_max_function_help_protos,
                                                 match_flags, context_flags,
                                                 true, case_sensitive, 
                                                 visited, depth+1, rt.template_args);
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: python, look for constructors named '__init__' in class "rt.return_type);
                        isay(depth, "_c_fcthelp_get: python constructor call, num_matches="num_matches);
                     }
                  }
               }

               // PHPScript uses __construct instead of normal constructor names
               if (num_matches==0 && isphp && rt.return_type!="") {
                  tag_list_symbols_in_context("__construct", rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: phpscript, look for constructors named '__construct' in class "rt.return_type);
                     isay(depth, "_c_fcthelp_get: phpscript, num_matches="num_matches);
                  }
               }

               // D uses 'this' instead of normal constructor names
               if (num_matches==0 && isdlang && rt.return_type!="") {
                  tag_list_symbols_in_context("this", rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: D langauge, look for constructors named 'this' in class "rt.return_type);
                     isay(depth, "_c_fcthelp_get: D langauge, num_matches="num_matches);
                  }
               }

               // Rust uses 'new' instead of normal constructor names
               if (num_matches==0 && isrust && rt.return_type!="") {
                  tag_list_symbols_in_context("new", rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: D langauge, look for constructors named 'this' in class "rt.return_type);
                     isay(depth, "_c_fcthelp_get: D langauge, num_matches="num_matches);
                  }
               }

               if (num_matches==0 && _LanguageInheritsFrom("c") && rt.return_type!="" && !pos("operator ",match_symbol)) {
                  tag_split_class_name(rt.return_type, auto class_name_only, auto outer_name);
                  tag_list_symbols_in_context(class_name_only, rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: C langauge, look for constructors named "class_name_only" in class "rt.return_type);
                     isay(depth, "_c_fcthelp_get: C langauge, num_matches="num_matches);
                  }
               }

               // Could not find a match. Try assuming that it is in the current class
               // context and look there. This is to fix a bug where codehelp doesn't work
               // on a member of a class when inside that class when there is no prefix and that class
               // is in a namespace.
               if( ( idexp_info.prefixexp == "" ) && ( num_matches == 0 ) ) {
                  _UpdateContext(AlwaysUpdate:true);
                  tag_get_current_context(cur_tag_name,cur_tag_flags,
                                          cur_type_name,cur_type_id,
                                          cur_class_name,cur_class_only,
                                          cur_package_name,
                                          visited, depth+1);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: cur_class_name="cur_class_name);
                  }
                  _c_get_type_of_prefix_recursive(errorArgs, tag_files, cur_class_name, rt, visited, depth+1, 0);

                  // Look again with the new return type
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: trying again with current class (rt.return_type="rt.return_type", num_matches="num_matches);
                  }
               }

               if (num_matches==0 && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: tryng again with lastid="idexp_info.lastid" num_matches="num_matches);
                  }
               } else if (found_define && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              SE_TAG_FILTER_ANY_PROCEDURE, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: tryng again with #define lastid="idexp_info.lastid" num_matches="num_matches);
                  }
               }
            }
            // try variables, maybe there's a function pointer out there
            if (idexp_info.lastid != "" && !isother && !isjava && !javascript && !isphp && num_matches == 0) {
               //say("_c_fcthelp_get: 1, symbol="match_symbol" class="match_class);
               // try to find 'lastid' as a data member which may be a function
               // pointer in 'match_class', using shorthand call notation
               tag_clear_matches();
               tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                           0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           SE_TAG_FILTER_ANY_DATA, context_flags,
                                           true, true, 
                                           visited, depth+1, rt.template_args);
               if (num_matches == 0) {
                  tag_list_symbols_in_context(match_symbol, "",
                                              0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              SE_TAG_FILTER_ANY_DATA, context_flags,
                                              true, true, 
                                              visited, depth+1, rt.template_args);
               }
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: trying again looking for function pointer, num_matches="num_matches);
               }

               // see if we found a true function pointer
               tr := "";
               for (m:=1; m<=num_matches; m++) {
                  tag_get_detail2(VS_TAGDETAIL_match_return,m,tr);
                  if (pos("(",tr)) {
                     break;
                  }
               }

               if (m > num_matches) {
                  // no function pointers found
                  num_matches=0;
                  if (!isjava && !javascript && !isrul && !isphp && !isother && !(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                     // Maybe this is a call to operator (), function call,
                     // for some class instance?
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: maybe function call operator, type="rt.return_type" match_symbol="match_symbol);
                     }
                     tag_return_type_init(rt);
                     status = _c_get_return_type_of(errorArgs,tag_files,
                                                    match_symbol,rt.return_type,
                                                    0,false /*isjava||javascript||isrul*/,
                                                    SE_TAG_FILTER_ANY_DATA,
                                                    false, false, rt, visited, depth+1);
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: maybe function call status="status" rt.return_type="rt.return_type);
                     }
                     tag_clear_matches();
                     if (!status && rt.return_type!="") {
                        // OK, 'lastid' is a class instance, try to find operator ()
                        if (_chdebug) {
                           isay(depth, "_c_fcthelp_get: H5, match_type="rt.return_type);
                        }
                        num_matches=0;
                        if (!isjava && !iscsharp && !slickc) {
                           function_call_operator := "()";
                           if (isdlang) {
                              function_call_operator = "opCall";
                           }
                           tag_list_symbols_in_context(function_call_operator, rt.return_type, 0, 0, tag_files, "",
                                                       num_matches, def_tag_max_function_help_protos,
                                                       SE_TAG_FILTER_ANY_PROCEDURE, context_flags,
                                                       true, true, 
                                                       visited, depth+1, rt.template_args);
                        }
                        if (num_matches <= 0 && tr != "") {
                           // check for a typedef'd function pointer
                           if (_chdebug) {
                              isay(depth, "_c_fcthelp_get: LOOKING FOR TYPEDEF evaluating return type of "tr);
                           }
                           status = _c_get_return_type_of(errorArgs,tag_files,tr,
                                                          "",0,false,SE_TAG_FILTER_TYPEDEF,
                                                          false, false, rt, visited, depth+1);
                           if (_chdebug) {
                              isay(depth, "_c_fcthelp_get: LOOKING FOR TYPEDEF status="status "rt.return_type="rt.return_type);
                           }
                           if (!status) {
                              tag_get_info_from_return_type(rt, auto rt_cm);
                              parse rt_cm.return_type with rt_cm.return_type '(' .;
                              tag_clear_matches();
                              tag_insert_match_info(rt_cm);
                              num_matches++;
                           }
                        }
                     }
                  }
               }
            }

            num_matches = tag_get_num_of_matches();
            if (num_matches==0 && !(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
               // Maybe this is value constructor.   ClassName(<here>)
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: maybe constructor, prefix="idexp_info.prefixexp" lastid="idexp_info.lastid);
               }
               status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, 
                                                        idexp_info.prefixexp:+idexp_info.lastid, 
                                                        rt, visited, depth+1, 0);
               //status = _c_get_return_type_of(errorArgs,tag_files,
               //                               match_symbol, rt.return_type,
               //                               0,false /*isjava||javascript||isrul*/,
               //                               SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_TYPEDEF,
               //                               false, false, rt, visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: maybe constructor status="status" rt.return_type="rt.return_type);
               }
               tag_clear_matches();
               if (!status && rt.return_type!="") {
                  // OK, 'lastid' is a class instance, try to find operator ()
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: H5, match_type="rt.return_type);
                  }
                  num_matches=0;
                  constructor_name := "";
                  if (ispython) {
                     constructor_name = "__init__";
                  } else if (isphp) {
                     constructor_name = "__construct";
                  } else if (isdlang) {
                     constructor_name = "this";
                  } else if (isrust) {
                     constructor_name = "new";
                  } else {
                     tag_split_class_name(rt.return_type, constructor_name, auto outer_name);
                  }
                  tag_list_symbols_in_context(constructor_name, rt.return_type, 0, 0, tag_files, "",
                                              num_matches, def_tag_max_function_help_protos,
                                              SE_TAG_FILTER_ANY_PROCEDURE, context_flags,
                                              true, true, 
                                              visited, depth+1, rt.template_args);
               }
            }

            if (num_matches==0 && idexp_info.lastid == "" && rt.taginfo != "") {
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: idexp_info.lastid="idexp_info.lastid);
                  isay(depth, "_c_fcthelp_get: rt.taginfo="rt.taginfo);
               }
               tag_get_info_from_return_type(rt, auto rt_cm);
               tr := rt_cm.return_type;
               parse tr with tr "[" .;
               tag_clear_matches();
               tag_insert_match_info(rt_cm);
               num_matches = 1;
               //say("tn="tn" tc="tc" tt="tt" tf="tf" ts="ts);
               if (rt.return_type!="" && !pos("(",tr)) {
                  _str orig_return_type=rt.return_type;
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: FUNCTION CALL OPERATOR evaluating return type of "rt.return_type);
                  }
                  status = _c_get_return_type_of(errorArgs,tag_files,"()",rt.return_type,
                                                 0,false,SE_TAG_FILTER_ANY_PROCEDURE,
                                                 false, false, rt, visited, depth+1);
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: FUNCTION CALL status="status "rt.return_type="rt.return_type);
                  }
                  if (!status) {
                     tag_get_info_from_return_type(rt, rt_cm);
                     tag_clear_matches();
                     tag_insert_match_info(rt_cm);
                     num_matches++;
                  } else {
                     // this is a typedef'd function pointer
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: TYPEDEF FUNCTION POINTER evaluating return type of "tr);
                     }
                     status = _c_get_return_type_of(errorArgs,tag_files,tr,
                                                    "",0,false,SE_TAG_FILTER_TYPEDEF,
                                                    false, false, rt, visited, depth+1);
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: TYPEDEF FUNCTION POINTER status="status "rt.return_type="rt.return_type);
                     }
                     if (!status) {
                        tag_get_info_from_return_type(rt, rt_cm);
                        tag_clear_matches();
                        tag_insert_match_info(rt_cm);
                        num_matches++;
                     }
                  }
               }
            }
            if (slickc && num_matches == 0 && _e_match_procs(match_symbol)) {
               // probably don't need to do this anymore
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: Slick-C _e_match_procs()");
               }
               num_matches = 1;
            }
            if ((slickc || javascript || isphp || isrlang) && num_matches == 0) {
               // fallback case for slick-C, ignore prefix expression
               if (_chdebug) {
                  isay(depth, "_c_fcthelp_get: trying again, flags="match_flags);
               }
               tag_clear_matches();
               tag_list_symbols_in_context(match_symbol, "", 0, 0, tag_files, "",
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, case_sensitive, visited, depth+1);
            }
            if (slickc && match_symbol=="show") {
               /*
               save_pos(show_p);
               save_search(show_s1,show_s2,show_s3,show_s4,show_s5);
               c_next_sym();
               if (gtk==TK_STRING) {
                  if (pos(":v['\"]$",gtkinfo,1,"r")) {
                     form_name := substr(gtkinfo,pos('s'),pos('')-1);
                     say("_c_fcthelp_get: special show case, form="form_name);
                     tag_push_matches();
                     tag_match_symbol_in_context(form_name, "", 0, 0, tag_files,
                                                 num_matches, VSCODEHELP_MAXFUNCTIONHELPPROTOS,
                                                 SE_TAG_FILTER_GUI, context_flags,
                                                 true, case_sensitive, true, false, false);
                     for (x=1; x<=tag_get_num_of_matches(); ++x) {
                        tag_get_detail2(VS_TAGDETAIL_match_file,x,form_file);
                     }
                     tag_pop_matches();
                     say("_c_fcthelp_get: form_name="form_name);
                  }
                  say("_c_fcthelp_get: gtkinfo="gtkinfo);
               }

               restore_search(show_s1,show_s2,show_s3,show_s4,show_s5);
               restore_pos(show_p);
               */
            }
            if ((slickc || javascript || isphp || isrlang) && num_matches == 0) {
               // double-fallback for slick-C and Javascript, ignoring prefix
               // expression and class scoping completely
               tag_clear_matches();
               tag_list_any_symbols(0, 0, match_symbol, tag_files,
                                    SE_TAG_FILTER_ANY_PROCEDURE, SE_TAG_CONTEXT_ONLY_NON_STATIC,
                                    num_matches, def_tag_max_function_help_protos,
                                    true, case_sensitive,
                                    visited, depth+1);
            }
            //if (match_symbol == "") {
               // this could be a function pointer call, last_id is empty string
               //say("***** NOW WHAT!!! *****");
            //}
         } else {
            idexp_info.lastid = match_symbol;
         }

         if (_chdebug) {
            isay(depth, "_c_fcthelp_get: BEFORE num_matches="tag_get_num_of_matches());
            tag_dump_matches("_c_fcthelp_get: BEFORE REMOVE DUPLICATES", depth+1);
         }

         // remove duplicates from the list of matches
         int unique_indexes[]; unique_indexes._makeempty();
         _str duplicate_indexes[]; duplicate_indexes._makeempty();
         if (!isrul) {
            removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         } else {
            for (i:=0; i<tag_get_num_of_matches(); i++) {
               unique_indexes[i]=i+1;
               duplicate_indexes[i]="";
            }
         }

         if (_chdebug) {
            isay(depth, "_c_fcthelp_get: AFTER num_matches="tag_get_num_of_matches());
            tag_dump_matches("_c_fcthelp_get: AFTER REMOVE DUPLICATES", depth+1);
         }

         VS_TAG_BROWSE_INFO allMatches[];
         tag_get_all_matches( allMatches );
         cur_line_match := "";
         cur_line_index := -1;
         num_unique := unique_indexes._length();

         for (i:=0; i<num_unique; i++) {
            j := unique_indexes[i];
            tag_get_match_browse_info(j, auto cm);
            if (ispython && cm.type_name=="func" && 
                !(_file_eq(cm.file_name, p_buf_name) && cm.line_no == p_RLine) &&
                !(cm.flags & SE_TAG_FLAG_STATIC)) {
               parse cm.arguments with auto py_first_arg ',' .;
               if (py_first_arg == 'self' || is_py_constructor_call) {
                  //parse signature with ","signature;
                  ++ParamNum;
                  ++ParamNameNum;
                  ++ParamFoundAt;
               }
            }
            if ((cm.flags & SE_TAG_FLAG_TEMPLATE) && cm.arguments=="") {
               tag_get_detail2(VS_TAGDETAIL_match_template_args, j, cm.arguments);
            }
            if ((cm.flags & SE_TAG_FLAG_CONSTRUCTOR) && cm.arguments=="") {
               tag_get_detail2(VS_TAGDETAIL_arguments, j, cm.arguments);
            }
            // maybe kick out if already have match or more matches to check
            is_symbol_under_cursor := false;
            if (match_list._length()>0 || i+1<num_unique) {
               if (symbol_to_match == null && _file_eq(cm.file_name,p_buf_name) && cm.line_no:==p_line) {
                  //continue;
                  is_symbol_under_cursor = true;
               }
               if (tag_tree_type_is_class(cm.type_name)) {
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: SKIP CLASS TYPE");
                  }
                  continue;
               }
               if (cm.arguments=="" && (cm.flags & SE_TAG_FLAG_EXTERN)) {
                  if (_chdebug) {
                     isay(depth, "_c_fcthelp_get: EXTERN FUNCTION WITH EMPTY SIGNATURE");
                  }
                  continue;
               }
               if (cm.type_name :== "define") {
                  if (cm.arguments == "") {
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: #define with EMPTY SIGNATURE");
                     }
                     continue;
                  }
               }
            }
            // So, we are in a template argument list, then we are looking for template functions or classes
            if ( idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST ) {
               if ( !(cm.flags & SE_TAG_FLAG_TEMPLATE) ) {
                  if (_chdebug) isay(depth, "_c_fcthelp_get: TEMPLATE ARGLIST but not a TEMPLATE");
                  continue;
               }
               if ( tag_tree_type_is_data(cm.type_name) || cm.type_name == "define" ) {
                  if (_chdebug) isay(depth, "_c_fcthelp_get: TEMPLATE ARGLIST no variables allowed here");
                  continue;
               }
            }
            list_proc_name := cm.member_name;
            if (cm.flags & SE_TAG_FLAG_OPERATOR) {
               list_proc_name= "operator "list_proc_name;
            }
            if (cm.class_name != "") {
               if (javascript || isjava || iscsharp || isdlang || slickc || isphp) {
                  list_proc_name = cm.class_name "." list_proc_name;
               } else {
                  list_proc_name = cm.class_name "::" list_proc_name;
               }
            }
            if (tag_tree_type_is_data(cm.type_name) && (cm.flags & SE_TAG_FLAG_MAYBE_PROTO) && pos(VS_TAGSEPARATOR_equals,cm.return_type) && cm.arguments=="") {
               parse cm.return_type with cm.return_type "=" cm.arguments;
               cm.arguments = tag_tree_format_args(cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
            }
            if (tag_tree_type_is_func(cm.type_name)) {
               if (cm.arguments == "void" && !isjava && !iscsharp && !javascript && !isrul) {
                  cm.arguments = "";
               }
            } else if (cm.type_name :== "define") {
               cm.return_type = "#define";
            }
            if (!isrul) {
               cm.type_name="proc";
            }
            if(symbol_to_match != null) {
               match_list :+= symbol_to_match.member_name "\t" symbol_to_match.type_name "\t" symbol_to_match.arguments "\t" symbol_to_match.return_type "\t" j "\t" duplicate_indexes[i];
               break;
            } else {
               match_list :+= list_proc_name "\t" cm.type_name "\t" cm.arguments "\t" cm.return_type"\t"j"\t"duplicate_indexes[i];
               if (is_symbol_under_cursor) {
                  cur_line_index = match_list._length()-1;
                  cur_line_match = match_list[cur_line_index];
               }
            }
            if (_chdebug) {
               isay(depth, "_c_fcthelp_get: match_list["match_list._length()-1"] = "match_list[match_list._length()-1]);
            }
         }

         // get rid of any duplicate entries
         match_list._sort();
         if (isrul) {
            _rul_merge_and_remove_duplicates(match_list);
         }

         if (_chdebug) {
            idump(depth+1, match_list, "_c_fcthelp_get: match_list");
         }

         // if we are in the parameter list for a function declaration or
         // function definition, make it the preferred match (first in list)
         // unless there is another match of a different type (proc vs. proto)
         if (cur_line_match != "" && match_list._length() >= 2) {
            have_other_types := false;
            parse cur_line_match with auto cur_name "\t" auto cur_type "\t" . ;
            for (i=0; i<match_list._length(); i++) {
               if (match_list[i] == cur_line_match) {
                  cur_line_index = i;
                  continue;
               }
               parse match_list[i] with auto match_name "\t" auto match_type "\t" . ;
               if (match_name == cur_name && match_type != cur_type) {
                  have_other_types = true;
               }
            }
            if (!have_other_types && cur_line_index >= 0) {
               match_list[cur_line_index] = match_list[0];
               match_list[0] = cur_line_match;
               cur_line_match = "";
            }
         }

         // if the first match is the symbol under the cursor, then
         // move it to the end of the list
         if (cur_line_match!="" && match_list[0] == cur_line_match && match_list._length() >= 2) {
            match_list[0] = match_list[match_list._length()-1];
            match_list[match_list._length()-1] = cur_line_match;
         }

         // translate functions into struct needed by function help
         have_matching_params := false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            for (i=0; i<match_list._length(); i++) {
               k := FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               match_tag_name := "";
               match_type_name := "";
               imatch := "";
               duplist := "";
               signature := return_type := "";
               parse match_list[i] with match_tag_name "\t" match_type_name "\t" signature "\t" return_type"\t"imatch"\t"duplist;

               // substitute template arguments
               for (ti := 0; ti < rt.template_names._length(); ++ti) {
                  ta := rt.template_names[ti];
                  if (rt.template_types._indexin(ta)) {
                     tt := tag_return_type_string(rt.template_types:[ta],false);
                     return_type = stranslate(return_type, tt, ta, "ew");
                     signature   = stranslate(signature,   tt, ta, "ew");
                  }
               }

               // replace unnatural package/class separators with language specific info
               if (javascript || isjava || iscsharp || isdlang || slickc || isphp) {
                  match_tag_name = stranslate(match_tag_name, ".", VS_TAGSEPARATOR_class);
                  match_tag_name = stranslate(match_tag_name, ".", VS_TAGSEPARATOR_package);
               } else {
                  match_tag_name = stranslate(match_tag_name, "::", VS_TAGSEPARATOR_package);
               }

               //say("tag="match_tag_name" sig="signature" ret="return_type);
               tag_autocode_arg_info_init(FunctionHelp_list[k]);
               functionHelpArgK := FunctionHelp_list[k];
               if (substr(signature, 1, 1) == "<" && !slickc && !isjava && !javascript && !isphp) {
                  signature = substr(signature, 2);
                  functionHelpArgK.prototype = return_type" "match_tag_name"<"signature">";
               } else {
                  functionHelpArgK.prototype = return_type" "match_tag_name"("signature")";
               }
               base_length := length(return_type) + length(match_tag_name) + 2;
               functionHelpArgK.argstart[0]=length(return_type)+1;
               functionHelpArgK.arglength[0]=length(match_tag_name);
               functionHelpArgK.ParamNum=ParamNum;
               functionHelpArgK.ParamName=ParamName;

               tag_get_match_info((int)imatch, auto z_cm);
               if ((int)imatch >= 1 && (int)imatch <= allMatches._length()) {
                  z_cm = allMatches[(int)imatch-1];
               }
               tag_autocode_arg_info_add_browse_info_to_tag_list(functionHelpArgK, z_cm, rt);
               foreach (auto z in duplist) {
                  if (z == imatch) continue;
                  tag_get_match_info((int)z, z_cm);
                  if ((int)z >= 1 && (int)z <= allMatches._length()) {
                     z_cm = allMatches[(int)z-1];
                  }
                  tag_autocode_arg_info_add_browse_info_to_tag_list(functionHelpArgK, z_cm, rt);
               }

               //++base_length;

               // parse signature and map out argument ranges
               j:=0;
               foundNamedArg := false;
               argument  := "";
               arg_pos   := 0;
               arg_start := tag_get_next_argument(signature, arg_pos, argument);
               while (argument != "") {
                  // allow for variable length argument lists
                  if (!pos(",",substr(signature,arg_start))) {
                     if (argument=="..." ||
                         (isjava && pos("...",argument)) ||
                         (isdlang && pos("...",argument)) ||
                         (iscsharp && pos("[",argument)) ||
                         (iscsharp && substr(argument,1,7):=="params ")
                        ) {
                        while (j < ParamNum-1) {
                           j = functionHelpArgK.argstart._length();
                           functionHelpArgK.argstart[j]=base_length+arg_start;
                           functionHelpArgK.arglength[j]=0;
                        }
                     }
                  }
                  j = functionHelpArgK.argstart._length();
                  functionHelpArgK.argstart[j]=base_length+arg_start;
                  functionHelpArgK.arglength[j]=length(argument);
                  if (j == ParamFoundAt || (!foundNamedArg && j >= ParamNameNum && ParamName!="")) {
                     foundParamName := "";
                     if (pos("^["word_chars"]*([=]?*|)$",argument,1,'r')) {
                        parse argument with argument "=" auto init_to;
                        if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                           functionHelpArgK.ParamType=argument;
                        }
                        functionHelpArgK.ParamName=argument;
                        foundParamName = argument;
                     } else if ((flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) &&
                                pos("^(class|struct|interface):b["word_chars"]*([=]?*|)$",argument,1,'r')) {
                        parse argument with . argument "=" auto init_to;
                        functionHelpArgK.ParamName=argument;
                        functionHelpArgK.ParamType=argument;
                        foundParamName = argument;
                     } else {
                        // parse out the return type of the current parameter
                        pslang := p_LangId;
                        utf8 := p_UTF8;
                        psindex := _FindLanguageCallbackIndex("%s_proc_search",pslang);
                        temp_view_id := 0;
                        int orig_view_id=_create_temp_view(temp_view_id);
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
                           functionHelpArgK.ParamName=pvarInfo.member_name;
                           foundParamName = pvarInfo.member_name;
                           if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                              functionHelpArgK.ParamType=pvarInfo.return_type;
                              if (iscsharp) {
                                 foreach (auto w in pvarInfo.return_type) {
                                    if (w == "in" || w == "out" || w == "ref") {
                                       functionHelpArgK.ParamKeyword = w;
                                    }
                                 }
                              }
                           }
                        }
                        _delete_temp_view(temp_view_id);
                        p_window_id = orig_view_id;
                     }
                     if (ParamName != "" && ParamName == foundParamName) {
                        foundNamedArg=true;
                        ParamFoundAt = j + (ParamNum - ParamNameNum);
                        functionHelpArgK.ParamNum = ParamFoundAt;
                     }
                  }
                  arg_start = tag_get_next_argument(signature, arg_pos, argument);
               }
               FunctionHelp_list[k] = functionHelpArgK; 
               if (ParamFoundAt != 1 && j < ParamFoundAt) {
                  if (have_matching_params) {
                     FunctionHelp_list._deleteel(k);
                  }
               } else {
                  if (!have_matching_params) {
                     VSAUTOCODE_ARG_INFO func_arg_info = FunctionHelp_list[k];
                     FunctionHelp_list._makeempty();
                     FunctionHelp_list[0] = func_arg_info;
                  }
                  have_matching_params = true;
               }
            }
            // Found some matches?
            if (FunctionHelp_list._length() > 0) {
               if (prev_ParamNum!=ParamNum || prev_ParamName!=ParamName) {
                  FunctionHelp_list_changed=true;
               }
               prev_prefixexp  = idexp_info.prefixexp;
               prev_otherinfo  = idexp_info.otherinfo;
               prev_info_flags = idexp_info.info_flags;
               prev_ParamNum   = ParamNum;
               prev_ParamName  = ParamName;

               // This is a hack to avoid a stack when calling this function on a temp view.
               if(symbol_to_match == null && !p_IsTempEditor) {
                  FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
               }
               break;
            }
         }
      }
   }

   if (_chdebug) {
      idump(depth+1, FunctionHelp_list, "_c_fcthelp_get: FunctionHelp_list");
   }

   if (idexp_info.lastid!=gLastContext_FunctionName || gLastContext_FunctionOffset!=idexp_info.lastidstart_offset) {
      FunctionHelp_list_changed=true;
      gLastContext_FunctionName=idexp_info.lastid;
      gLastContext_FunctionOffset=idexp_info.lastidstart_offset;
   }
   restore_pos(p);
   return(0);
}

/**
 * Get the type of the specified symbol which was auto-declared
 * to match a reference type function parameter.  This function
 * assumes that the 'cm' is a local variable whose location is
 * within an argument list of a function call.  This is needed
 * for Slick-C&reg; Context Tagging&reg; since it has the capability to
 * declare a local variable within a function call, for example:
 * <pre>
 *    save_pos(auto p);
 *    get_line(auto line);
 * </pre>
 * 
 * @param errorArgs  For error messages if lookup fails
 * @param tag_files  tag files to search
 * @param cm         local variable's symbol information         
 * @param rt         return type for local variable
 * @param visited    hash table for previous results
 * @param depth      search depth
 * 
 * @return 0 on success, non-zero on error.
 */
int _c_get_type_of_parameter(typeless errorArgs,
                             typeless tag_files,
                             VS_TAG_BROWSE_INFO &cm, 
                             VS_TAG_RETURN_TYPE &rt,
                             VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( _chdebug ) {
      isay(depth, "_c_get_type_of_parameter: cm.seekpos="cm.seekpos" file="p_buf_name);
   }
   // jump to the location of the local variable
   if ( cm.seekpos <= 0 ) return VSCODEHELPRC_CONTEXT_NOT_VALID;
   save_pos(auto p);
   _GoToROffset(cm.seekpos);

   // get the basic function help information
   flags  := 0;
   status := _c_fcthelp_get_start(errorArgs,false,true,auto startOffset,auto argOffset,flags,depth+1);
   if ( status ) {
      restore_pos(p);
      return status;
   }

   // now get the details about the function help
   _GoToROffset(cm.seekpos);
   listChanged := true;
   status = _c_fcthelp_get(errorArgs,auto functionHelpList,
                           listChanged,auto cursor_x,auto helpWord,startOffset,0,
                           null, visited, depth+1);
   if ( status ) {
      restore_pos(p);
      return status;
   }

   // maybe we can see the return type with template arguments
   if (functionHelpList._length() <= 0) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }

   // now, while we are still in the argument list, get the return type information
   if (functionHelpList[0].tagList._length() > 0) {
      rt.template_args  = functionHelpList[0].tagList[0].class_type.template_args;
      rt.template_names = functionHelpList[0].tagList[0].class_type.template_names;
      rt.template_types = functionHelpList[0].tagList[0].class_type.template_types;
   }
   status = _c_parse_return_type(errorArgs, tag_files,
                                 cm.member_name, "",
                                 cm.file_name,
                                 functionHelpList[0].ParamType, false,
                                 rt, visited, depth+1);
   if ( _chdebug ) {
      isay(depth, "_c_get_type_of_parameter: param_name="functionHelpList[0].ParamName" status="status);
      tag_return_type_dump(rt, "_c_get_type_of_parameter:", depth);
   }

   // that's all folks
   restore_pos(p);
   return status;
}

/**
 * Check if we have just typed a space or open paren following
 * a "return" or "goto" statement.  If so, attempt to list function
 * argument help or list the labels for the goto statement.
 * 
 * @return bool
 */
bool c_maybe_list_args(bool OperatorTyped=false)
{
   // disable this feature for Standard edition
   if (!_haveContextTagging()) {
      return false;
   }

   // we don't do comments or strings
   if (_in_comment() || _in_string()) {
      return false;
   }

   // no auto-list params, then disable this feature
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_VALUES)) {
      return false;
   }

   // save the cursor position
   save_pos(auto p);

   // used later for argument matching
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);

   do {

      tk := c_prev_sym();
      if (tk==TK_ID) {

         // if we have a 'return' statement, list compatible variables
         tkinfo := c_sym_gtkinfo();
         if (tkinfo=="return" || tkinfo=="co_return" || tkinfo=="co_yield") {
            restore_pos(p);
            left();
            if (get_text_safe():!=" " && get_text_safe()!="(") {
               break;
            }
            left();
            if (get_text_safe():!="n") {
               break;
            }
            restore_pos(p);
            _do_list_members(OperatorTyped,
                             DisplayImmediate:false,
                             syntaxExpansionWords:null,
                             expected_type:null, rt);
            return true;
         }

         // if we have a 'case' statement, list compatible constants for the switch
         if (c_sym_gtkinfo()=="case") {
            restore_pos(p);
            left();
            if (get_text_safe():!=" ") {
               break;
            }
            left();
            if (get_text_safe():!="e") {
               break;
            }
            restore_pos(p);
            _do_list_members(OperatorTyped,
                             DisplayImmediate:false,
                             syntaxExpansionWords:null,
                             expected_type:null, rt, 
                             expected_name:null,
                             prefixMatch:false, 
                             selectMatchingItem:false, 
                             doListParameters:true);
            return true;
         }

         // if we have a goto statement, list labels
         if (c_sym_gtkinfo()=="goto") {
            restore_pos(p);
            left();
            if (get_text_safe():!=" ") {
               break;
            }
            left();
            if (get_text_safe():!="o") {
               break;
            }
            restore_pos(p);
            _do_list_members(OperatorTyped:false, DisplayImmediate:true);
            return true;
         }

      } else if (c_sym_gtk() == "=") {
         restore_pos(p);
         left();
         if (get_text_safe():!=" ") {
            break;
         }
         left();
         if (get_text_safe():!="=") {
            break;
         }
         restore_pos(p);
         _do_list_members(OperatorTyped,
                          DisplayImmediate:false,
                          syntaxExpansionWords:null,
                          expected_type:null, rt, 
                          expected_name:null,
                          prefixMatch:false, 
                          selectMatchingItem:false, 
                          doListParameters:true);
         return true;
      }

   } while ( false );

   // restore cursor position and return, doing nothing
   restore_pos(p);
   return false;
}

