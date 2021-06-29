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
#import "cfcthelp.e"
#import "codehelp.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "emacs.e"
#import "objc.e"
#import "pmatch.e"
#import "projutil.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/tags/TaggingGuard.e"
#endregion


static _str gtkinfo;
static _str gtk;

int gInJavadoc_linenum;
int gInJavadoc_flag;

const C_COMMON_END_OF_STATEMENT_RE = "if|while|switch|for|case|default|public|private|signals|protected|static|class|break|continue|do|else|goto|try|catch|return";

const JAVA_MORE_END_OF_STATEMENT_RE = "abstract|native|synchronized|throw|volatile|enum";
const C_MORE_END_OF_STATEMENT_RE = "auto|enum|extern|register|struct|typedef|delete|finally|friend|inline|restrict|overload|virtual|using|template|asm|throw|namespace|co_await|co_return|co_yield";
const SLICKC_MORE_END_OF_STATEMENT_RE = "enum|extern|register|struct|typedef|delete|finally|using|template|throw|namespace";
const CS_MORE_END_OF_STATEMENT_RE = "auto|enum|extern|register|struct|typedef|delete|finally|friend|inline|operator|overload|virtual|using|throw|namespace|lock|fixed|readonly|override|unsafe|yield";
const RUL_MORE_END_OF_STATEMENT_RE = "abort|begin|downto|elseif|end|endfor|endif|endprogram|endswitch|endwhile|exit|function|program|prototype|repeat|step|then|to|typedef|until";
const PHP_MORE_END_OF_STATEMENT_RE = "exit|endif|endwhile|elseif|global|define|include|finally|try|catch|require|virtual";
const SAS_MORE_END_OF_STATEMENT_RE = "abort|array|attrib|by|call|char|class|create|decending|delete|delimiter|do|else|end|endsas|go|gt|if|in|le|macro|macrogen|ne|not|or|otherwise|proc|quit|return|run|to|until|var|when|where|while";
const D_MORE_END_OF_STATEMENT_RE = "abstract|alias|asm|auto|break|type|case|catch|class|continue|default|do|else|enum|export|extern|final|finally|for|foreach|foreach_reverse|function|goto|if|import|interface|lazy|macro|mixin|module|new|nothrow|null|out|override|pacakge|pragma|private|protected|public|pure|return|scope|static|struct|switch|synchronized|template|throw|try|typedef|union|unittest|void|volatile|while|with";

const JAVA_NOT_FUNCTION_WORDS = " catch do for if return synchronized switch throw while var yield ";
const C_NOT_FUNCTION_WORDS = " const contexpr int long double float bool byte short signed unsigned char asm __asm __declspec __except catch do for if return sizeof typeid switch throw typedef using while with template volatile co_await co_return co_yield "; // const_cast static_cast dynamic_cast reinterpret_cast 
const CS_NOT_FUNCTION_WORDS = " int long double float bool short char decimal byte ubyte string var in is checked unchecked ushort ulong uint catch do for foreach if return sizeof typeid switch using throw while lock with fixed yield ";
const D_NOT_FUNCTION_WORDS = " abstract alias align asm auto body bool break byte case cast catch cdouble cent cfloat char class const continue creal dchar default delegate delete deprecated do double else enum export extern final finally float for foreach foreach_reverse function goto idouble if ifloat import in inout int interface invariant ireal is lazy long macro mixin module new nothrow out override package pragma private protected public pure real ref return scope short static struct switch synchronized template throw try typedef typeid typeof ubyte ucent uint ulong union unittest ushort void volatile wchar while with ";
const RUL_NOT_FUNCTION_WORDS = " abort case downto elseif exit for goto if return step switch to until while ";

definit()
{
   gInJavadoc_linenum=0;
   gInJavadoc_flag=0;
}

_str c_sym_gtk()
{
   return gtk;
}
_str c_sym_gtkinfo()
{
   return gtkinfo;
}


static _str xlat_class_name(_str class_name)
{
   i := 0;
   if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom("e")) {
      i=lastpos(".",class_name);
      if (i) {
         class_name=substr(class_name,1,i-1):+VS_TAGSEPARATOR_package:+substr(class_name,i+1);
      }
   } else {
      i=lastpos("::",class_name);
      if (i) {
         class_name=substr(class_name,1,i-1):+VS_TAGSEPARATOR_package:+substr(class_name,i+2);
      }
   }
   return(class_name);
}
static _str parse_java_class_name()
{
   if (gtk!=TK_ID) {
      return "";
   }
   _str class_name=gtkinfo;
   c_next_sym();
   while (gtk==".") {
      class_name :+= gtkinfo;
      c_next_sym();
      if (gtk==TK_ID) {
         class_name :+= gtkinfo;
         c_next_sym();
      } else {
         break;
      }
   }
   return(xlat_class_name(class_name));
}

static void skip_template_args()
{
   isdlang := _LanguageInheritsFrom("d");
   nesting := 0;
   c_next_sym();
   for (;;) {
      if (c_sym_gtk() == "<" || (isdlang && c_sym_gtk() == "!(")) {
         ++nesting;
      } else if (c_sym_gtk() == ">" || (isdlang && c_sym_gtk() == ")")) {
         --nesting;
         if (nesting <= 0) {
            return;
         }
      } else if (c_sym_gtk()=="") {
         return;
      }
      c_next_sym();
   }
}


int c_parse_class_definition(_str &class_name, _str &class_type_name, _str &implement_list,int &vsImplementFlags,typeless &AfterKeyinPos=null)
{
   status := 0;
   _str errorArgs[];
   lang := _isEditorCtl()? p_LangId : "";
   tag_files := tags_filenamea(lang);
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   struct VS_TAG_RETURN_TYPE visited:[];

   if (_chdebug) {
      say("c_parse_class_definition H"__LINE__": file="p_buf_name" line="p_line);
   }
   class_type_name="";
   if (_LanguageInheritsFrom("c")) {
      vsImplementFlags=VSIMPLEMENT_ABSTRACT;
   } else {
      vsImplementFlags=0;
   }
   class_name="";
   implement_list="";
   line := word := "";
   col := indent_col := 0;
   left();
   typeless brace_nrseek=_nrseek();
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   inherit_class_name := "";
   in_template := false;
   in_c := _LanguageInheritsFrom("c");
   in_slickc := _LanguageInheritsFrom("e");
   in_java := _LanguageInheritsFrom("java");
   isdlang := _LanguageInheritsFrom("d");

   if (in_java) {
      if (_clex_skip_blanks('-')) return(0);
      if (get_text_safe()==")") {
         // Here we match round parens. ()
         status = _find_matching_paren(def_pmatch_max_diff_ksize);
         if (status) {
            return(0);
         }
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         c_prev_sym2();
         // This could be java new anonymous class
         //if (_clex_skip_blanks('-')) return(0);

         if (gtk==TK_ID && pos(" "gtkinfo" "," for if switch while new ")) {
            return(0);
         }
         implement_list="";
         //typeless p4;
         while (gtk==TK_ID || gtk==".") {
            if (gtkinfo=="new") {
               break;
            }
            implement_list=gtkinfo:+implement_list;
            c_prev_sym2();
            //save_pos(p4);
         }
         if (gtkinfo!="new") {
            return(0);
         }

         if (_chdebug) {
            say("c_parse_class_definition H"__LINE__": implement_list="implement_list);
         }
         tag_return_type_init(rt);
         status = _c_get_type_of_expression(errorArgs, tag_files, 
                                            "", "", "", 
                                            VSCODEHELP_PREFIX_NULL, 
                                            expr:implement_list, 
                                            rt, visited);
         if (status == 0 && rt.return_type != "") {
            implement_list = rt.return_type;
         }
         if (_chdebug) {
            say("c_parse_class_definition H"__LINE__" AFTER: implement_list="implement_list);
         }

         implement_list=xlat_class_name(implement_list);
         search("new","@h");
         col=p_col;
         _first_non_blank();
         if (col!=p_col) {
            if (AfterKeyinPos!=null) {
               typeless t1;
               save_pos(t1);
               restore_pos(AfterKeyinPos);
               down();
               get_line(line);
               if (line=="}") {
                  _first_non_blank();
                  col=p_col+p_SyntaxIndent-1;
                  replace_line(indent_string(col)"}");
               }
               restore_pos(t1);
            }
            p_col+=p_SyntaxIndent;
         }
         indent_col=p_col+p_SyntaxIndent-1;
      }
   }
   if (!indent_col) {
      indent_col=c_begin_stat_col(false,false,false);
      if (!indent_col) {
         return(0);
      }
      indent_col+=p_SyntaxIndent-1;
      // parse words before "class" keyword
      c_next_sym();
      for (;;) {
         if (gtk!=TK_ID) {
            return(0);
         }
         word=gtkinfo;
         if (word=="class" || word=="struct" || word=="union" || word=="enum" || word=="interface" || word=="typename") {
            class_type_name=word;
            break;
         }
         if (word=="enum_flags" && in_slickc) {
            class_type_name=word;
            break;
         }
         if (word=="abstract") {
            vsImplementFlags=VSIMPLEMENT_ABSTRACT;
         }
         if (word =="template" && in_c) {
            in_template = true;
            skip_template_args();
         }
         c_next_sym();
      }
      c_next_sym();
      if (gtk!=TK_ID) {
         if (class_type_name == "enum" || class_type_name == "union") {  // anonymous enums & unions
            return (indent_col);
         }
         return(0);
      }
      class_name=gtkinfo;
      //goto_point(_nrseek()+length(word);
      //if (_clex_skip_blanks()) return(0);
      c_next_sym();
      if (in_java) {
         if (gtk!=TK_ID) {
            return(0);
         }
         while (gtkinfo=="implements" || gtkinfo=="extends") {
            for (;;) {
               c_next_sym();
               if (gtk!=TK_ID) {
                  break;
               }
               inherit_class_name=parse_java_class_name();
               if (inherit_class_name=="") {
                  return(1);
               }

               if (_chdebug) {
                  say("c_parse_class_definition H"__LINE__" BEFORE: inherit_class_name="inherit_class_name);
               }
               tag_return_type_init(rt);
               status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                  "", "", "", 
                                                  VSCODEHELP_PREFIX_NULL, 
                                                  expr:inherit_class_name, 
                                                  rt, visited, 1);
               if (status == 0 && rt.return_type != "") {
                  inherit_class_name = tag_return_type_string(rt);
               }
               if (_chdebug) {
                  say("c_parse_class_definition H"__LINE__" AFTER: inherit_class_name="inherit_class_name);
               }

               if (implement_list=="") {
                  implement_list=inherit_class_name;
               } else {
                  implement_list :+= ";"inherit_class_name;
               }
               if (gtk!=",") {
                  break;
               }
            }
         }
      } else {
         if (in_c && in_template && (gtk == "<" || (isdlang && gtk == "!("))) { // template specialization
            skip_template_args();
            c_next_sym();
         }
         if ( gtk=="{" ) {
            if (in_c || in_slickc) {
               return indent_col;
            }
         }
         if (gtk!=":") {
            return (0);
         }
         for (;;) {
            c_next_sym();
            // skip keywords like public
            while (gtk==TK_ID) {
               left();
               if (_clex_find(0,'g')!=CFG_KEYWORD) {
                  right();
                  break;
               }
               right();
               c_next_sym();
            }
            if (gtk!=TK_ID && gtk!="::") {
               return(0);
            }
            inherit_class_name="";
            while (gtk==TK_ID || gtk=="::") {
               inherit_class_name :+= gtkinfo;
               c_next_sym();
            }
            inherit_class_name=xlat_class_name(inherit_class_name);
            if (gtk=="<" || (gtk=="!(" && isdlang)) {
               nesting := 0;
               for (;;) {
                  inherit_class_name :+= gtkinfo;
                  if (gtk=="<" || (gtk=="!(" && isdlang)) {
                     ++nesting;
                  } else if (gtk==">" || (gtk==")" && isdlang)) {
                     --nesting;
                     if (nesting<=0) {
                        c_next_sym();
                        break;
                     }
                  } else if (gtk=="{") {
                     return(0);
                  }
                  c_next_sym();
               }
            }

            if (_chdebug) {
               say("c_parse_class_definition H"__LINE__" BEFORE: inherit_class_name="inherit_class_name);
            }
            tag_return_type_init(rt);
            status = _c_get_type_of_expression(errorArgs, tag_files, 
                                               "", "", "", 
                                               VSCODEHELP_PREFIX_NULL, 
                                               expr:inherit_class_name, 
                                               rt, visited, 1);
            if (status == 0 && rt.return_type != "") {
               inherit_class_name = tag_return_type_string(rt);
            }
            if (_chdebug) {
               say("c_parse_class_definition H"__LINE__" AFTER: inherit_class_name="inherit_class_name);
            }

            if (implement_list=="") {
               implement_list=inherit_class_name;
            } else {
               implement_list :+= ";"inherit_class_name;
            }
            if (gtk!=",") {
               break;
            }
         }
      }
      if (gtkinfo!="{" || _nrseek()-1!=brace_nrseek) {
         return(0);
      }
   }
   return(indent_col);
}


/**
 * get the position of a comparible identifier in the
 * current expression that we can use to determine the expected
 * return type
 *
 * @param lhs_start_offset   (reference) seek position of matching identifier
 * @param expression_op      (reference) expression operator
 * @param pointer_count      (reference) set to number of times lhs is dereferenced
 *                           either through an array operator or * (future fix)
 * @param depth              (optional) recursive call depth for debugging 
 *
 * @return 0 on success, non-zero otherwise
 */
int _c_get_expression_pos(int &lhs_start_offset,
                          _str &expression_op,
                          int &pointer_count,
                          int depth=0)
{
   // first check for a compatible operator
   typeless p, s1,s2,s3,s4,s5;
   save_pos(p);
   if (get_text_safe()!="") {
      left();
   }
   gtk=c_prev_sym();

   // allow one open parenthesis, no more (this is a fudge-factor)
   if (gtk=="(") {
      gtk=c_prev_sym();
   }

   // handle return statements
   if (gtkinfo=="return"      || gtkinfo == "yield"    ||
       gtkinfo == "co_return" || gtkinfo == "co_yield" ) {
      expression_op=gtkinfo;

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      int context_id=tag_current_context();
      if (context_id > 0) {
         type_name := "";
         proc_name := "";
         start_seekpos := 0;
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
         if (tag_tree_type_is_func(type_name)) {
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_name,context_id,proc_name);
            _GoToROffset(start_seekpos);
            save_search(s1,s2,s3,s4,s5);
            int search_status=search(_escape_re_chars(proc_name)'[ \t]*[(]','@rh');
            if (!search_status) {
               lhs_start_offset=(int)_QROffset();
               restore_search(s1,s2,s3,s4,s5);
               restore_pos(p);
               return(0);
            }
            restore_search(s1,s2,s3,s4,s5);
         }
      }
      // must have failed here
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }

   // handle case statements, does not handle nested switch statements
   if (gtkinfo=="case") {
      expression_op=gtkinfo;
      save_search(s1,s2,s3,s4,s5);
      if (!search("switch[ \t]*\\c[(]","@-erhCk") && !find_matching_paren(true)) {
         left();
         gtk=c_prev_sym();
         if (gtk==TK_ID) {
            right();
            lhs_start_offset=(int)_QROffset();
            restore_search(s1,s2,s3,s4,s5);
            restore_pos(p);
            return(0);
         }
      }
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }

   // check list of other allowed expression operators
   allowed := " = == += -= != %= ^= *= &= |= /= >= <= > < + - * / % ^ & | ";
   if (_LanguageInheritsFrom("e")) {
      allowed :+= ":== :!= .= ";
   }
   if (!pos(" "gtkinfo" ",allowed)) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   expression_op=gtkinfo;

   // ok, now what is on the other side of the expresson?
   gtk=c_prev_sym();

   // watch for array arguments
   while (gtk=="]") {
      right();
      int status=find_matching_paren(true);
      if (status) {
         restore_pos(p);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      pointer_count++;
      left();
      gtk=c_prev_sym();
   }

   // watch for function call
   if (gtk==")") {
      right();
      int status=find_matching_paren(true);
      if (status) {
         restore_pos(p);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      left();
      gtk=c_prev_sym();
   }

   // didn't found an ID after all that work...
   if (gtk!=TK_ID) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   right();
   lhs_start_offset=(int)point('s');
   restore_pos(p);
   return(0);
}

bool _c_skip_operators_left()
{
   // check for C++ overloaded operators
   if (!pos(get_text_safe(), "~=+-!%^&*[]<>/|) ")) {
      return false;
   }

   // check for function call operator and other operators
   typeless op_pos;
   save_pos(op_pos);
   if (get_text_safe()==")" && get_text_safe(1, _nrseek()-1)=="(") {
      left();
      left();
   } else if (get_text_safe():==" ") {
      while (p_col > 1 && get_text_safe() :== " ") {
         left();
      }
   } else {
      while (p_col > 1 && pos(get_text_safe(), "~=+-!%^&*[]<>/|")) {
         left();
      }
   }

   // back up over spaces
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   search('^|[~ \t]','@rh-');
   word_chars := _clex_identifier_chars();
   if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
      restore_pos(op_pos);
      restore_search(s1,s2,s3,s4,s5);
      return false;
   }

   // check for the operator keyword
   end_col := p_col;
   search('[~'word_chars']\c|^\c','-rh@');
   _str word = _expand_tabsc(p_col,end_col-p_col+1);
   if (word != "operator") {
      restore_pos(op_pos);
      restore_search(s1,s2,s3,s4,s5);
      return false;
   }

   // success, we have an operator expression
   restore_search(s1,s2,s3,s4,s5);
   p_col = end_col;
   return true;
}

/**
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * This version is designed for "C" and other "C"-like languages.
 * It has special case code for Java, InstallScript, JavaScript,
 * C#, Perl, and PHP.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 * <P>
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param id_expinfo             (reference) VS_TAG_IDEXP_INFO which contains all the information set by this function
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @example
 * <PRE>
 * <B>PossibleOperator==true</B>
 * </PRE>
 * <P>
 * If this function is called when possibly operator typed like -> or ( or .
 * <UL>
 * <LI>return 1 if not valid operator
 * <LI>return 1 if expression too complex or invalid context
 * </UL>
 * <PRE>
 * a[1].b.c.&lt;Here&gt;
 *
 *    prefixexp="a[].b.c."
 *    lastid=""
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * x=A::B::MYCLASS(Noflines);   // C++ ambiguity only. Most common case
 *    prefixexp="A::B::"
 *    lastid="MYCLASS"
 *    lastidstart_col=column is M of MYCLASS
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *
 *    This could be a function or a converter
 *
 * x=A::B::
 *    prefixexp="A::B::"
 *    lastid=""
 *    lastidstart_col=column after last :
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 *    This could be a function or a converter
 *
 * f(x,y).a[1].b.c.method(&lt;Here&gt;
 *    return 1 --> expression too complex
 *
 *    prefixexp="f(x,y).a[1].b.c."
 *    lastid="method"
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *
 *
 * MYCLASS *p=new MYCLASS(&lt;Here&gt;
 *    prefixexp="new"
 *    lastid="MYCLASS"
 *    lastidstart_col=column is M of MYCLASS
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *
 * innerclass ic=j.new innerclass().&lt;Here&gt;       // java
 *    prefixexp="j.new innerclass()."
 *    lastid=""
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * innerclass ic=j.new innerclass(&lt;Here&gt;        // java
 *    prefixexp="j.new"
 *    lastid="innerclass"
 *    lastidstart_col=column is 'i' of innerclass
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *
 * MYCLASS::MYCLASS(int x,int y):a(x),b(&lt;Here&gt;
 *    prefixexp=""
 *    lastid="b"
 *    lastidstart_col=column is at b
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *    otherinfo="MYCLASS"
 *
 *    Only list members of MYCLASS and base classes
 *
 * MYCLASS():a(&lt;Here&gt;
 *    prefixexp=""
 *    lastid="a"
 *    lastidstart_col=column is at a
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *    otherinfo="MYCLASS"
 *
 *    We are in an initializer list only if the class
 *    name in otherinfo matches the context class.
 *
 *    Only list members of MYCLASS and base classes if
 *    we are in an initializer list, otherwise treat
 *    this case like the typical VSAUTOCODEINFO_DO_FUNCTION_HELP
 *    case.
 *
 * MYCLASS method(&lt;Here&gt;
 *
 *    prefixexp=""
 *    lastid="method"
 *    lastidstart_col=column of 'm' character of method
 *    infoflags=VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN
 *    otherinfo="MYCLASS"
 *
 *    This is either a variable definition or a prototype
 *
 *    Hopefully, it is sufficient to display function help
 *    for the MYCLASS constructors. It not, the caller could do
 *    nothing unless  we are in the context of function code.
 * </PRE>
 *
 * <PRE>
 * <B>PossibleOperator==false</B>
 * </PRE>
 * <P>
 * Identifier just typed (curr char not id) or on identifier
 * <PRE>
 * a[1].b.c.id&lt;Here&gt;
 *
 *    prefixexp="a[].b.c."
 *    lastid="id"
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * a[1].b.c.&lt;here&gt;id
 *
 *    prefixexp="a[].b.c."
 *    lastid="id"
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * &lt;here&gt;
 *
 *    prefixexp=""
 *    lastid=""
 *    lastidstart_col=column same as cursor
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * a[1].b.c&lt;here&gt;.id
 *
 *    prefixexp="a[].b."
 *    lastid="c"
 *    lastidstart_col=column at c
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * f(&lt;here&gt;+id
 *
 *    prefixexp=""
 *    lastid=""
 *    lastidstart_col=column after (
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 * </PRE>
 * @since 11.0
 */
int _c_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info, 
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_idexp_info_init(idexp_info);
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (0 && _chdebug) {
      isay(depth, "_c_get_expression_info: possible_op="PossibleOperator" @"_QROffset()" ["p_line","p_col"]");
   }
   status := 0;
   idexp_info.errorArgs._makeempty();
   not_function_words := C_NOT_FUNCTION_WORDS;
   isjava := false;
   slickc := false;
   iscpp := false;
   javascript := false;
   isperl := false;
   isrul := false;
   isidl := false;
   isphp := false;
   isobjc := false;
   switch (lowcase(p_LangId)) {
   case "cs":
      isjava=true;
      not_function_words=CS_NOT_FUNCTION_WORDS;
      break;
   case "java":
      isjava=true;
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
      break;
   case "d":
      isjava=true;
      not_function_words=D_NOT_FUNCTION_WORDS;
      break;
   case "e":
      slickc=true;
      break;
   case "idl":
      isidl=true;
      break;
   case "phpscript":
      isphp=true;
      break;
   case "ansic":
   case "c":
   case "rs":
      iscpp=true;
      break;
   case "cfscript":
   case "js":
      javascript=true;
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
      break;
   case "pl":
      isperl=true;
      break;
   case "rul":
      isrul=true;
      not_function_words=RUL_NOT_FUNCTION_WORDS;
      break;
   case "m":
      iscpp=true;
      isobjc=true;
      break;
   }
   idexp_info.otherinfo="";
   gInJavadoc_flag=0;
   gInJavadoc_linenum=0;
   
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   cfg := 0;
   if (PossibleOperator && p_col > 1) {
      left();cfg=_clex_find(0,'g');right();
   } else {
      cfg=_clex_find(0,'g');
   }
   typeless orig_pos;
   save_pos(orig_pos);

   // Handle the case where we have an identifier immediately
   // abutted with a comment and we are at the end of the identifier
   // For example:   /*comment*/i/*comment*/
   if (p_col>1 && cfg==CFG_COMMENT) {
      left();cfg=_clex_find(0,'g');right();
   }

   if (_chdebug > 9) {
      isay(depth, "_c_get_expression_info: lexed="cfg);
   }

   word_chars := _clex_identifier_chars();
   index := 0;
   if (cfg==CFG_COMMENT) {
      tag := "";
      if (!_inJavadocSeeTag(tag)) {
         if (_inDocComment()) {
            restore_pos(orig_pos);
            return _doc_comment_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
         }
         index=find_index("_javadoc_"tag"_find_context_tags",PROC_TYPE);
         if (!index) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
      }
      //idexp_info.info_flags|=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      gInJavadoc_flag=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      gInJavadoc_linenum=p_line;
   } else if(cfg==CFG_STRING || cfg==CFG_NUMBER) {
      int orig_cfg=cfg;
      left();
      cfg=_clex_find(0,'g');
      ch := get_text_safe();
      right();

      if (orig_cfg==CFG_NUMBER && !PossibleOperator) {
         if (cfg==CFG_STRING || cfg==CFG_NUMBER ||
             !pos('['word_chars'.>:]',ch,1,'r')) {
            // "Rock" back-then-forward until we are parked at the beginning
            // of the string or number.
            int clex_flag=(orig_cfg==CFG_STRING)? STRING_CLEXFLAG:NUMBER_CLEXFLAG;
            int clex_status=_clex_find(clex_flag,'n-');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            clex_status=_clex_find(clex_flag,'o');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            start_col := p_col;
            int start_offset=(int)point('s');
            // Sanity check? Not sure when this would ever fail.
            clex_status=_clex_find(clex_flag,'n');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            clex_status=_clex_find(clex_flag,'o-');
            if (clex_status) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp="";
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col+1);
            //say("_c_get_expression_info: lastidstart_col="idexp_info.lastidstart_col" lastid="idexp_info.lastid);
            restore_pos(orig_pos);
            return(0);
         }
      } else if (cfg==CFG_STRING) {

         if (p_LangId == ANT_LANG_ID) {
            _str cw = cur_word(auto sc);
            idexp_info.prefixexp="";
            idexp_info.lastid=cw;
            idexp_info.lastidstart_col=sc;
            restore_pos(orig_pos);
            return 0;
         }

         int clex_status=_clex_find(STRING_CLEXFLAG,'n-');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         before_col := p_col;
         clex_status=_clex_find(STRING_CLEXFLAG,'o');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         start_col := p_col;
         int start_offset=(int)point('s');
         clex_status=_clex_find(STRING_CLEXFLAG,'n');
         if (clex_status) {
            bottom();
            _end_line();
            clex_status=0;
         } else {
            clex_status=_clex_find(STRING_CLEXFLAG,'o-');
         }
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         idexp_info.prefixexp="";
         idexp_info.lastidstart_col=start_col;
         idexp_info.lastidstart_offset=start_offset;
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col+1);
         //say("_c_get_expression_info: lastidstart_col="idexp_info.lastidstart_col" lastid="idexp_info.lastid);

         p_col=before_col;
         gtk=c_prev_sym_same_line();
         include_info := gtkinfo;
         if (gtk!=TK_ID || (gtkinfo!="include" && gtkinfo!="import" && gtkinfo!="require")) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         gtk=c_prev_sym_same_line();
         if (gtk!="#") {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         idexp_info.prefixexp="#"include_info;
         idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
         idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
         idexp_info.lastidstart_col++;
         idexp_info.lastid = strip(idexp_info.lastid);
         idexp_info.lastid = strip(idexp_info.lastid, "B", "\"' ");
         restore_pos(orig_pos);
         return 0;

      } else if (cfg==orig_cfg || cfg==CFG_COMMENT) {
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      gInJavadoc_linenum=(p_active_form.p_name=="_javadoc_form")?p_line:0;
   }

   // Only want auto-list members on _ for Slick-C when type
   // property "p_"
   // DOB
   if ( PossibleOperator &&  slickc &&
        get_text_safe(1,(int)point('s')-1)=="_" &&
        (
           get_text_safe(1,(int)point('s')-2)!='p' ||
            pos('['word_chars']',get_text_safe(1,(int)point('s')-3),1,'r')
        )
      ) {
      restore_pos(orig_pos);
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   ch := "";
   line := "";
   orig_col := p_col;
   orig_line := p_RLine;
   start_col := 0;
   end_col := 0;
   typeless start_offset=0;
   typeless end_offset=0;

   // DOB - Problem if this is past end of line
   //past_end_of_line(true);
   if (PossibleOperator && !(slickc && get_text_safe(1,(int)point('s')-1)=="_")) {
      if (p_col == 1) {
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      left();
      ch=get_text_safe();
      if (ch=="#" && gInJavadoc_linenum) {
         ch=".";
      }
      if (_chdebug > 9) {
         isay(depth, "_c_get_expression_info: chleft="ch);
      }
      
      switch (ch) {
      case "#":
         orig_col=p_col;
         p_col=1;
         _clex_skip_blanks("");
         if (orig_col==p_col && !isperl && !javascript && !isphp) {
            idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
            idexp_info.prefixexpstart_offset=(int)point('s');
            // get the id after the dot
            // IF we are on a id character
            right();
            if (pos('['word_chars']',get_text_safe(),1,'r')) {
               start_col=p_col;start_offset=point('s');
               //search('[~'p_word_chars']|$','r@');
               _TruncSearchLine('[~'word_chars']|$','r');
               idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
               idexp_info.lastidstart_col=start_col;
               idexp_info.lastidstart_offset=start_offset;
            } else {
               idexp_info.lastid="";
               idexp_info.lastidstart_col=p_col;
               idexp_info.lastidstart_offset=(int)point('s');
            }
            idexp_info.prefixexp="#";
            restore_pos(orig_pos);
            return(0);
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "@":
         orig_col=p_col;
         //p_col=1;
         //_clex_skip_blanks('');
         if (orig_col==p_col) {
            // get the id after the dot
            // IF we are on a id character
            right();
            if (pos('['word_chars']',get_text_safe(),1,'r')) {
               start_col=p_col;start_offset=point('s');
               //search('[~'p_word_chars']|$','r@');
               _TruncSearchLine('[~'word_chars']|$','r');
               idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
               idexp_info.lastidstart_col=start_col;
               idexp_info.lastidstart_offset=start_offset;
            } else {
               idexp_info.lastid="";
               idexp_info.lastidstart_col=p_col;
               idexp_info.lastidstart_offset=(int)point('s');
            }
            idexp_info.prefixexp="@";
            restore_pos(orig_pos);
            idexp_info.prefixexpstart_offset=(int)point('s')-1;
            if (_in_comment()) {
               idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
            } else {
               idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
            }
            restore_pos(orig_pos);
            return(0);
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case ":":
         if (!(iscpp || isperl || isidl)|| get_text_safe(1,(int)point('s')-1)!=":") {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         // foo::bar, foo is not a constructor or destructor, even if name matches
         //idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
         // found a ::, drop through to other dot case
      case ">":
      case ".":
         //say("here");
         orig_col=p_col;
         if (ch==".") {
            if (isphp) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            // foo.bar, foo is not a constructor or destructor, even if name matches
            //idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
            // Watch out for parse <exp> with a . b .
            if (slickc && get_text_safe(1,(int)point('s')-1)=="") {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            // Screen out floating point.  1.0
            if (isdigit(get_text_safe(1,(int)point('s')-1))) {
               // Check if identifier before . is a number
               save_pos(auto p2);
               left();
               search('[~'word_chars']\c|^\c','-rh@');
               if (isdigit(get_text_safe())) {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               restore_pos(p2);

            }
            get_line(line);
            if (pos('^[ \t]*\#[ \t]*include',line,1,'r')) {
               // Screen out -->  #include <iostream.h>
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            right();
         } else if (ch==":") {
            right();
         } else {
            if (isjava || javascript) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (get_text_safe(1,(int)point('s')-1)!="-") {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            right();
         }
         // get the id after the dot
         // IF we are on a id character
         if (pos('['word_chars']',get_text_safe(),1,'r')) {
            start_col=p_col;start_offset=point('s');
            //search('[~'p_word_chars']|$','r@');
            _TruncSearchLine('[~'word_chars']|$','r');
            idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col);
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
         } else {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
         }
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         p_col=orig_col;
         break;
      case "/":
      case '\':
         save_pos(auto before_slash);
         right();
         if (get_text()==">") {
            restore_pos(before_slash);
            start_col=p_col;
            start_offset=point('s');
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid="";
            idexp_info.prefixexp="";
            idexp_info.info_flags=0;
            c_before_id(false, not_function_words, idexp_info);
            restore_pos(orig_pos);
            return 0;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         break;
      case "<":
      case "(":
         if (ch=="(") {
            idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            idexp_info.lastidstart_col=p_col;  // need this for function pointer case
            idexp_info.lastidstart_offset=(int)point('s');  // need this for function pointer case
         } else {

            // check for #include <>
            save_pos(auto before_lt);
            left();
            gtk=c_prev_sym_same_line();
            if (gtk==TK_ID && (gtkinfo=="include" || gtkinfo=="import" || gtkinfo=="require")) {
               include_info := gtkinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!="#") {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               restore_pos(before_lt);
               start_col=p_col;
               start_offset=point('s');
               idexp_info.lastidstart_col=start_col+1;
               idexp_info.lastidstart_offset=start_offset+1;
               idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
               idexp_info.lastid="";
               idexp_info.prefixexp="#"include_info;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
               restore_pos(orig_pos);
               return 0;
            }
            restore_pos(before_lt);

            if (javascript || slickc || isrul || isphp || get_text_safe(1,(int)point('s')-1)=="<") {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST|VSAUTOCODEINFO_DO_FUNCTION_HELP;
         }
         left();
         // IF languages has preprocessing
         if (iscpp || slickc || isrul || /*isjava ||*/ isidl) {
            search('[~ \t]|^','-rh@');
         } else {
            _clex_skip_blanks('-h');
         }
         // maybe there was a function pointer expression or template parameters.
         if (ch=="(" && (get_text_safe()==")" || get_text_safe()=="]" || ((iscpp || isjava) && get_text_safe()==">")) && !javascript && !isphp) {
            // If we really have a cast like (char *)(p+1) don't worry about it
            //typeless p2;
            //save_pos(p2);
            end_offset=point('s');
            for (;;) {
               if (get_text_safe()==">") {
                  // match template argument start
                  typeless gts1, gts2, gts3, gts4, gts5;
                  save_search(gts1,gts2,gts3,gts4,gts5);
                  nesting := 0;
                  int gtstatus=search("(^|<|>)",'-rh@Xs');
                  while (!gtstatus) {
                     if (get_text_safe()==">") {
                        nesting++;
                     } else if (get_text_safe()=="<") {
                        nesting--;
                        if (!nesting) {
                           break;
                        }
                     } else {
                        break;
                     }
                     repeat_search();
                  }
                  restore_search(gts1,gts2,gts3,gts4,gts5);
                  if (gtstatus || get_text_safe()!="<") {
                     restore_pos(orig_pos);
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
               } else {
                  if (find_matching_paren(true)) {
                     restore_pos(orig_pos);
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
               }
               start_offset=point('s');
               // IF languages has preprocessing
               if (iscpp || slickc || isrul || isjava || isidl) {
                  // required ]( or )( to be on same line
                  left();
                  search('[~ \t]|^','-rh@');
               } else {
                  if (p_col==1) {
                     up();_end_line();
                  } else {
                     left();
                  }
                  _clex_skip_blanks('-h');
               }
               ch=get_text_safe();
               if (ch!=")" && ch!="]") {
                  if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
                     idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST;
                     idexp_info.prefixexp=get_text_safe(end_offset-start_offset+1,start_offset);
                     idexp_info.prefixexpstart_offset=start_offset;
                     //say("prefixexp="idexp_info.prefixexp);
                     idexp_info.lastid="";
                     restore_pos(orig_pos);
                     return(0);
                  }
                  // look for operator here!!!
                  // Preserve lastidstart_col
                  int previous_lastidstart_col = idexp_info.lastidstart_col;
                  int previous_lastidstart_offset = idexp_info.lastidstart_offset;
                  status=_c_get_expression_info(false, idexp_info, visited, depth+1);
                  idexp_info.lastidstart_col = previous_lastidstart_col;
                  idexp_info.lastidstart_offset = previous_lastidstart_offset;

                  //say("status="status" p="point('s'));
                  if (status) {
                     restore_pos(orig_pos);
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
                  idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST;
                  if (idexp_info.lastid=="operator") {
                     idexp_info.lastid=get_text_safe(end_offset-start_offset+1,start_offset);
                  } else if (idexp_info.lastid=="return"   || 
                             idexp_info.lastid=="throw"    ||
                             idexp_info.lastid=="yield"    ||
                             idexp_info.lastid=="co_await" ||
                             idexp_info.lastid=="co_return"||
                             idexp_info.lastid=="co_yield" ) {
                     idexp_info.prefixexp=get_text_safe(end_offset-start_offset+1,start_offset);
                     idexp_info.lastid="";
                     idexp_info.prefixexpstart_offset=start_offset;
                  } else {
                     // Special handling for new expressions - prefixexp is
                     // already "new Something" in this case.
                     if (pos("^{new|gcnew} ", idexp_info.prefixexp,1, "r")) {                        
                        al := substr(idexp_info.prefixexp, 1, lastpos("0"));
                        idexp_info.prefixexp = al:+" ":+idexp_info.lastid:+get_text_safe(end_offset-start_offset+1,start_offset);
                     } else {
                        idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid:+get_text_safe(end_offset-start_offset+1,start_offset);
                        idexp_info.lastid="";
                     }
                  }
                  //say("prefixexp="idexp_info.prefixexp);
                  restore_pos(orig_pos);
                  return(0);
               }
            }
         }

         // check for C++ overloaded operators
         end_col=p_col+1;
         hasOperator := _c_skip_operators_left();

         // character under cursor should be an identifier character
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         
         if (hasOperator && pos("operator", idexp_info.lastid, 1)==1) {
            op := strip(substr(idexp_info.lastid,9));
            idexp_info.lastid = "operator "op;
         }
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if (pos(" "idexp_info.lastid" ",not_function_words)) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      case "[":
         idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         ch=get_text_safe();
         if (ch == ":" && _LanguageInheritsFrom("e")) {
            left();
            ch=get_text_safe();
         }
         search('[~ \t]|^','-rh@');
         end_offset=point('s');
         for (;;) {
            ch=get_text_safe();
            if (ch!=")" && ch!="]") {
               break;
            }
            isBracket := ch == "]";
            if (find_matching_paren(true)) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            start_offset=point('s');
            // required ][ or ]( to be on same line
            left();
            search('[~ \t]|^','-rh@');
            ch=get_text_safe();
            if (isBracket && ch == ":" && _LanguageInheritsFrom("e")) {
               left();
               ch=get_text_safe();
            }
            if (ch!=")" && ch!="]") {
               break;
            }
         }
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if (pos(" "idexp_info.lastid" ",not_function_words)) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      default:
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   } else {
      // IF we are not on an id character.
      ch=get_text_safe();
#if 0
      if (ch=="." || (!isjava && !javascript && ch==">" && get_text_safe(1,(int)point('s')-1)=="-" ) ) {
         right();
         ch=get_text_safe();
         //lastid="";
         //lastidstart_col=p_col+1;
      } else if (!isjava && !javascript && ch=="-" && get_text_safe(1,(int)point('s')+1)==">") {
         right();right();
         ch=get_text_safe();
      }
#endif
      done := false;

      if (_chdebug > 9) {
         isay(depth, "_c_get_expression_info: ch1="ch);
      }
      
      if (pos('[~'word_chars']',ch,1,'r')) {

         left();
         ch=get_text_safe();
         if ((ch=="." && !isphp) ||
             (!isjava && !javascript && ch==">" && get_text_safe(1,(int)point('s')-1)=="-" ) ||
             ((iscpp || isperl || isidl) && ch==":" && get_text_safe(1,(int)point('s')-1)==":") ||
             (isperl && ch=="'")
            ) {
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            done=true;
         }
         if (ch == "<") {
            // check for #include <>
            save_pos(auto before_lt);
            left();
            gtk=c_prev_sym_same_line();
            if (gtk==TK_ID && (gtkinfo=="include" || gtkinfo=="import" || gtkinfo=="require")) {
               include_info := gtkinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!="#") {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               restore_pos(before_lt);
               start_col=p_col;
               start_offset=point('s');
               idexp_info.lastidstart_col=start_col+1;
               idexp_info.lastidstart_offset=start_offset+1;
               idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
               idexp_info.lastid="";
               idexp_info.prefixexp="#"include_info;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
               restore_pos(orig_pos);
               return 0;
            }
            restore_pos(before_lt);
         } else if (ch == "/" || ch == "\\") {
            save_pos(auto before_gt);
            right();
            if (get_text_safe() == ">") {
               _first_non_blank();
               if (get_text_safe() == "#") {
                  restore_pos(before_gt);
                  gtk=c_prev_sym_same_line();
                  if (gtk == "/") {
                     start_col=p_col;
                     start_offset=point('s');
                     idexp_info.lastidstart_col=start_col+2;
                     idexp_info.lastidstart_offset=start_offset+2;
                     idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
                     idexp_info.lastid="";
                     idexp_info.prefixexp="";
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
                     c_before_id(false, not_function_words, idexp_info); 
                     restore_pos(orig_pos);
                     return 0;
                  }
               }
            }
            restore_pos(before_gt);
         }
      }
      if (!done) {

         // check for C++ overloaded operators
         foundOperator := _c_skip_operators_left();
         if (!foundOperator && 
             _LanguageInheritsFrom("c") && 
             _clex_find(0,'g') != CFG_COMMENT &&
             pos(get_text_safe(), "~=+-!%^&*[]<>/| ")) { 

            // check for function call operator and other operators
            typeless op_pos;
            save_pos(op_pos);

            // check for the cursor just before the operator with whitespace
            if (get_text_safe()=="" && 
                get_text_safe(2,_nrseek()+1) != "/*" &&
                get_text_safe(2,_nrseek()+1) != "//" &&
                pos(get_text_safe(1,_nrseek()+1), "~=+-!%^&*[]<>/|") 
                /*&& !at_end_of_line()*/) { 
               right();
            }

            // skip forward to grab the rest of the operator
            operator_end_col := p_col;
            hasArrayOperator := false;
            if (get_text_safe()=="]") {
               operator_end_col = p_col;
               find_matching_paren(true);
               left();
               hasArrayOperator=true;
            } else {
               while (pos(get_text_safe(), "=+-!%^&*<>/|") /*&& !at_end_of_line()*/) {
                  if (get_text_safe(2) == "**" ||
                      get_text_safe(2) == "*&" ||
                      get_text_safe(2) == ">&" ||
                      get_text_safe(2) == "*>" ||
                      get_text_safe(2) == ">*") {
                     right();
                     break;
                  }
                  right();
               }
               left();
               operator_end_col = p_col;
               while (p_col > 1 && pos(get_text_safe(), "=+-!%^&*<>/|")) {
                  if (get_text_safe(2,_nrseek()-1) == "**") break;
                  if (get_text_safe(2,_nrseek()-1) == "*&") break;
                  if (get_text_safe(2,_nrseek()-1) == ">&") break;
                  if (get_text_safe(2,_nrseek()-1) == ">*") break;
                  if (get_text_safe(2,_nrseek()-1) == "*>") break;
                  left();
               }
            }

            // get the contents of the operator
            int operator_start_col = p_col+1;
            int operator_start_offset = _nrseek()+1;
            c_operator := "";
            if (operator_end_col+1 >= orig_col) {
               c_operator = _expand_tabsc(p_col+1,operator_end_col-p_col);
            }
            if (hasArrayOperator) c_operator = "[]";

            // back up over spaces
            search('^|[~ \t]','@rh-');

            // check for a postfix operator ++ or --
            postfix_operator := "";
            if (get_text_safe(2,_nrseek()-1) == "++" || get_text_safe(2,_nrseek()-1) == "--") {
               left();
               postfix_operator = get_text_safe(2);
               left();
            }

            // check for an identifier
            before_status := -1;
            if (c_operator != "" && pos('['word_chars']',get_text_safe(),1,'r') && _clex_find(0,'g') != CFG_PPKEYWORD) {
               // get the expression on the LHS of the operator
               before_status = _c_get_expression_info(false, idexp_info, visited, depth+1);
            } else if (c_operator != "" && pos(get_text_safe(), ")]>")) {
               gtk = c_prev_sym();
               before_status = c_before_dot(isjava, idexp_info);
               if (before_status==2) before_status=0;
            }

            // check for a prefix operator, *, ~, !, or &
            prefix_operator := "";
            if (before_status==0 && idexp_info.prefixexpstart_offset>=2) {
               _GoToROffset(idexp_info.prefixexpstart_offset-1);
               while (p_col > 1 && get_text_safe() == " ") left();
               if (pos(get_text_safe(), "*~!&") &&
                   get_text_safe(2,_nrseek()-1) != ">&" &&
                   get_text_safe(2,_nrseek()-1) != ">*" &&
                   get_text_safe(2,_nrseek()-1) != "&&") {
                  prefix_operator = get_text_safe();
                  idexp_info.prefixexpstart_offset=(int)point('s');
               } else if (get_text_safe(2,_nrseek()-1) == "++" || 
                          get_text_safe(2,_nrseek()-1) == "--") {
                  left();
                  prefix_operator = get_text_safe(2);
                  idexp_info.prefixexpstart_offset=(int)point('s');
               }
            }

            // if we found something, then put it all together
            if (before_status==0 && operator_start_col+length(c_operator) > orig_col) {
               idexp_info.prefixexp = "(" prefix_operator :+ idexp_info.prefixexp :+ idexp_info.lastid :+ postfix_operator ").";
               idexp_info.lastid = _c_get_operator_name(c_operator);
               idexp_info.lastidstart_col = operator_start_col;
               idexp_info.lastidstart_offset = operator_start_offset;
               idexp_info.info_flags = VSAUTOCODEINFO_CPP_OPERATOR;
               restore_pos(orig_pos);
               return(0);
            }

            // didn't find an operator, too bad
            restore_pos(op_pos);
         }

         // IF we are not on an id character.
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            idexp_info.prefixexp="";
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;

            gtk=c_prev_sym2();
            if (gtk==TK_ID && !isperl && !javascript && !isphp) {
               switch (gtkinfo) {
               case "goto":
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_GOTO_STATEMENT;
                  break;
               case "throw":
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_THROW_STATEMENT;
                  break;
               case "raise":
                  if (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("ttcn3")) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_THROW_STATEMENT;
                  }
                  break;
               case "using":
                  if (iscpp || slickc || _LanguageInheritsFrom("cs")) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
                  }
                  break;
               case "import":
                  if (isjava && !_LanguageInheritsFrom("cs")) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
                  }
                  if (slickc) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
                     gtk=c_prev_sym_same_line();
                     if (gtk=="#") {
                        idexp_info.prefixexp="#import";
                        restore_pos(orig_pos);
                        return 0;
                     } else {
                        gtk=TK_ID;
                        gtkinfo="import";
                     }
                  }
                  break;
               case "include":
               case "require":
                  if (iscpp || slickc) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
                     gtk=c_prev_sym_same_line();
                     if (gtk=="#") {
                        idexp_info.prefixexp="#include";
                        restore_pos(orig_pos);
                        return 0;
                     } else {
                        gtk=TK_ID;
                        gtkinfo="include";
                     }
                  }
                  break;
               case "enum":
               case "enum_flags":
               case "class":
               case "struct":
               case "interface":
               case "namespace":
               case "union":
               case "typename":
                  idexp_info.info_flags += VSAUTOCODEINFO_HAS_CLASS_SPECIFIER;
                  break;
               default:
                  idexp_info.prefixexp="";
                  break;
               }
            } else if (gtk==TK_ID &&
                       ((isperl && gtkinfo == "sub") ||
                        (lowcase(gtkinfo) == "function" && (isidl || javascript || isphp || _LanguageInheritsFrom("lua"))) ||
                        (gtkinfo == "def" && (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("ruby"))) ||
                        (gtkinfo == "task" && (_LanguageInheritsFrom("verilog") || _LanguageInheritsFrom("systemverilog"))) ||
                        (isrul && gtkinfo == "prototype"))) {
               idexp_info.info_flags += VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER;
            } else if (iscpp && (gtk==":" || gtk==",")) {
               status=parse_constructor_or_initializer(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,
                                                       idexp_info.lastid,idexp_info.lastidstart_offset,
                                                       idexp_info.info_flags,idexp_info.otherinfo,visited,depth+1);
            }
            if (gtk=="#") {
               _clex_skip_blanks('h');
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               idexp_info.prefixexp="#";
               idexp_info.prefixexpstart_offset=(int)point('s');
            } else if (gtk=="@" && p_col <= orig_col && p_RLine == orig_line) {
               search("@", "@h");
               idexp_info.prefixexp="@";
               if (_in_comment()) {
                  idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
               } else {
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               }
               idexp_info.prefixexpstart_offset=(int)point('s');
            } else if (gtk=="&" || gtk=="*" || gtk=="^" || gtk=="%") {
               if (get_text_safe(2,_nrseek()+1) != "&&") {
                  idexp_info.otherinfo=gtk;
                  idexp_info.info_flags|=VSAUTOCODEINFO_HAS_REF_OPERATOR;
                  idexp_info.prefixexpstart_offset=(int)point('s');
               }
            }
            restore_pos(orig_pos);
            // safeguard for really messed up cases
            if (idexp_info.prefixexpstart_offset >= (int)point('s')) {
               idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
               idexp_info.prefixexp="";
               if (!(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)) {
                  idexp_info.info_flags &= ~VSAUTOCODEINFO_IN_PREPROCESSING;
               }
            }
            restore_pos(orig_pos);
            return(0);
         }

         //search('[~'p_word_chars']|$','rh@');
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col=p_col;

         // check if the word under the cursor is "operator"
         orig_end_col := end_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         start_col=p_col;
         hasOperator := false;
         _str maybe_operator=_expand_tabsc(p_col,end_col-p_col);
         p_col = end_col;
         if (_LanguageInheritsFrom('c') && maybe_operator=="operator") {
            hasOperator=true;
            _TruncSearchLine('[~ \t]|$','r');
            if (get_text_safe(2)=='()') {
               p_col+=2;
               end_col=p_col;
            } else {
               while (pos(get_text_safe(), "~=+-!%^&*[]<>/|") /*&& !at_end_of_line()*/) {
                  right();
                  end_col=p_col;
               }
            }
         }

         // Check if this is a function call
         //search('[~ \t]|$','rh@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text_safe()=="(") {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         } else if (get_text_safe()=="[") {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
            open_bracket_pos := _QROffset();
            if (!find_matching_paren(true)) {
               close_bracket_pos := _QROffset();
               idexp_info.otherinfo=get_text_safe((int)(close_bracket_pos-open_bracket_pos-1),(int)(open_bracket_pos+1));
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','\/\/?*[\n\r]','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','^[ \t\n\r]#','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','[ \t\n\r]#$','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,' ','[ \t\n\r][ \t\n\r]#','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','\/\*?*\*\/','r');
            }
            if (idexp_info.otherinfo=="") {
               idexp_info.info_flags&=~VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
            }
            _GoToROffset(open_bracket_pos);
         } else if (get_text_safe(2)=="{}") {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACES;
         }
         // check if this is NOT a function call
         if (pos(get_text_safe(),'~*&.:{[]}') || // p_col>_text_colc(0,'E') ||
             ((iscpp || isperl || isidl) && get_text_safe(2)=='::') ||
             ((iscpp || slickc || isperl) && get_text_safe(2)=="->")) {
            idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
         }
         p_col=orig_end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');

         // check if we are on a reference to a destructor, include tilde
         if (get_text_safe(1,_nrseek()-1)=="~") {
            if (pos(get_text_safe(1,_nrseek()-2), ".>:")) {
               // symbol is qualified
               left();
            } else {
               // unqualified, can only be destructor found in class definition

               // make sure that the context doesn't get modified by a background thread.
               se.tags.TaggingGuard sentry;
               sentry.lockContext(false);
               _UpdateContext(true);

               context_id := tag_current_context();
               if (context_id > 0) {
                  start_seekpos := 0;
                  context_flags := 0;
                  tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, context_flags);
                  if (start_seekpos == _QROffset()-1 && (context_flags & SE_TAG_FLAG_DESTRUCTOR)) {
                     left();
                  }
               }
            }
         }

         // ok, now we get the identifier under the cursor
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }

         // check for C++ overloaded operators
         if (hasOperator) {
            op := strip(substr(idexp_info.lastid,9));
            idexp_info.lastid = "operator "op;
         }
      }
      //if (slickc && (PossibleOperator && lastid!="p_")
      if (slickc && (PossibleOperator && _last_char(idexp_info.lastid)!="_")
          /*||substr(lastid,1,2)!="p_" */
          ) {
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
   //say("cur_word1 = '"get_text(5)"'");
   idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
   idexp_info.prefixexp="";
   gtk=c_prev_sym2();
   if (_chdebug > 9) {
      isay(depth, "_c_get_expression_info: prevsym="gtk", inf="gtkinfo);
   }
   
   hit_colon_colon := false;
   if (gtk=="::" && iscpp) {
      for (;;) {
         hit_colon_colon=true;
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset=(int)point('s')+1;
         gtk=c_prev_sym_same_line();
         if (gtk!=TK_ID || pos(" "gtkinfo" ",C_NOT_FUNCTION_WORDS,1,'e')) {
            if (gtk==">") {
               if (add_template_args(idexp_info.prefixexp,idexp_info.prefixexpstart_offset) != 0 || gtk != TK_ID) {
                  // have     NO-ID-HERE <a,b,c>::
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
            } else {
               break;
            }
         }
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset=(int)point('s')+1;
         gtk=c_prev_sym_same_line();
         if (gtk!="::") {
            break;
         }
      }
   }
   //say("cur_word2 = '"get_text(5)"'");
   if (idexp_info.info_flags& VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
      if (gtk=="," || gtk=="{" || gtk==";" || gtk=="" || gtk=="}" ||
          _c_skip_template_prefix_word()) {
         _clex_skip_blanks('h');
         restore_pos(orig_pos);
         return(0);
      }
      restore_pos(orig_pos);
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   // check that the previous symbol was not a preprocessing statement
   if (_clex_find(0,'g') == CFG_PPKEYWORD) {
      save_pos(auto before_id);
      _clex_skip_blanks('h');
      if (get_text_safe() == "#") {
         restore_pos(orig_pos);
         return 0;
      }
      restore_pos(orig_pos);
   }

   // Skip over preprocessing
   if (gtk == TK_ID && endsWith(gtkinfo, "EXPORT|IMPORT|API", true, "r")) {
      defined_to := "";
      lang := _isEditorCtl()? p_LangId : "";
      tag_files := tags_filenamea(lang);
      if (tag_check_for_define(gtkinfo, 0, tag_files, defined_to) > 0) {
         orig_gtk := gtk;
         orig_gtkinfo := gtkinfo;
         save_pos(auto before_pp);
         gtk=c_prev_sym2();
         if (gtk != TK_ID) {
            gtk = orig_gtk;
            gtkinfo = orig_gtkinfo;
            restore_pos(before_pp);
         }
      }
   }

   // IF we could be in a declaration list
   before_keywords := " gcnew new goto throw return using import class struct union interface namespace template typename enum ";
   if (slickc) before_keywords :+= "enum_flags _command const ";
   if ((iscpp || slickc) && 
       (gtk=="," || 
        (gtk==TK_ID && !pos(" "gtkinfo" ",before_keywords)) || 
        (gtk=="&" && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) ||
        (gtk=="*" && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) ||
        (gtk=="&" && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) ||
        (gtk=="*" && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) ||
        gtk==":" || 
        gtk==">" )
       ) {
      /*
         Check for the following cases:
            int a,b,c(&lt;Here&gt;
            [myclass::]myclass(...): a(1),b(1),c(&lt;Here&gt;
            TEMPLATECLASS<...>  a,b,c(&lt;Here&gt;
            MYTYPE id&lt;Here&gt;
      */
      status=parse_constructor_or_initializer(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,
                                              idexp_info.lastid,idexp_info.lastidstart_offset,
                                              idexp_info.info_flags,idexp_info.otherinfo,visited,depth+1);
      //messageNwait("p_buf_name="p_buf_name);
      restore_pos(orig_pos);
      return(status);
   }

   status=c_before_id(isjava||javascript,not_function_words, idexp_info, depth);
   restore_pos(orig_pos);
   return(status);
}

/*
  Current token must be >
*/
static int add_template_args(_str &prefixexp,int &prefixexpstart_offset)
{
   save_pos(auto p);
   orig_prefixexp := prefixexp;
   orig_line := p_RLine;
   isdlang := _LanguageInheritsFrom("d");
   nesting := 0;
   for (;;) {
      prefixexp=gtkinfo:+prefixexp;
      if (gtk==">" || gtk==")" || gtk=="]") {
         ++nesting;
      } else if (gtk=="<" || (isdlang && gtk=="!(")) {
         --nesting;
         if (nesting<=0) {
            prefixexpstart_offset=(int)point("s")+1;
            c_prev_sym2();
            return 0;
         }
      } else if (gtk=="(" || gtk=="[" || gtk==":[" || gtk=="?[") {
         --nesting;
         if (nesting<=0) {
            prefixexp = orig_prefixexp;
            restore_pos(p);
            return 0;
         }
      } else if (gtk==";" || gtk=="{" || gtk=="}" || gtk=="") {
         prefixexp = orig_prefixexp;
         restore_pos(p);
         return 0;
      }  else if (p_RLine+10 < orig_line) {
         prefixexp = orig_prefixexp;
         restore_pos(p);
         return VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT;
      } else if ( gtk=="") {
         return 0;
      }
      c_prev_sym2();
   }
}
/*
   Check for the following cases:
      int a,b,c(&lt;Here&gt;
      [myclass::]myclass(...): a(1),b(1),c(&lt;Here&gt;
*/
static int parse_constructor_or_initializer(_str prefixexp,int &prefixexpstart_offset,
                                            _str lastid,int lastidstart_offset,
                                            int &info_flags,typeless &otherinfo,
                                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := 0;
   check_for_var_decl_or_colon := false;
   prefixexpstart_offset=lastidstart_offset;
outer_loop:
   for (;;) {
      if (gtk==">") {
         int FunctionNameStartOffset;
         if (!_c_probablyTemplateArgList(FunctionNameStartOffset)) {
            return(0);
         }
         _str errorArgs[];
         typeless FunctionHelp_list;
         FunctionHelp_list_changed := false;
         int FunctionHelp_cursor_x;
         _str FunctionHelp_HelpWord;
         status=_c_fcthelp_get(errorArgs,
                               FunctionHelp_list,
                               FunctionHelp_list_changed,
                               FunctionHelp_cursor_x,
                               FunctionHelp_HelpWord,
                               FunctionNameStartOffset,
                               VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST,
                               null, visited, depth+1);
         if (status) {
            //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            return 0;
         }
         goto_point(FunctionNameStartOffset);
         gtk=">";
         break;
      }
      // IF maybe inializer list case
      if (gtk==":") {
         if (!_LanguageInheritsFrom("c")) {
            return 0;
         }
         typeless colon_paren_pos;
         save_pos(colon_paren_pos);
         c_prev_sym2();
         if (gtk!=")") {
            // We are not in an initializer list
            if (check_for_var_decl_or_colon) {
               restore_pos(colon_paren_pos);gtk=":";
               break outer_loop;
            }
            return(0);
         }
         goto_point((int)point('s')+1);
         status=find_matching_paren(true);
         if (status) {
            // We are not in an initializer list
            if (check_for_var_decl_or_colon) {
               restore_pos(colon_paren_pos);gtk=":";
               break outer_loop;
            }
            return(0);
         }
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         c_prev_sym2();
         if (gtk!=TK_ID) {
            // We are not in an initializer list
            if (check_for_var_decl_or_colon) {
               restore_pos(colon_paren_pos);gtk=":";
               break outer_loop;
            }
            return(0);
         }
         otherinfo=gtkinfo;
         c_prev_sym2();
         if (gtk=="::") {
            // We are definitely in an initializer list
            for (;;) {
               otherinfo=gtkinfo:+otherinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!=TK_ID) {
                  // This should not happen.
                  break;
               }
               otherinfo=gtkinfo:+otherinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!="::") {
                  break;
               }
            }
            info_flags|=VSAUTOCODEINFO_IN_INITIALIZER_LIST;
            return(0);
         }
         info_flags|=VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST;
         return(0);
      }
      orig_line   := p_RLine;
      orig_offset := _QROffset();
      for (;;) {
         if (gtk==")") {
            typeless close_paren_pos;
            save_pos(close_paren_pos);
            goto_point((int)point('s')+1);
            status=find_matching_paren(true);
            if (status) {
               // We are lost
               return(0);
            }
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            c_prev_sym2();
            if (gtk==TK_ID) {
               if (pos(" "gtkinfo" "," catch for if switch throw while ")) {
                  //End of statement
                  restore_pos(close_paren_pos);gtk=")";
                  //refresh();_message_box("c");
                  break outer_loop;
               }
               c_prev_sym2();
            }
         }
         // for (MYCLASS x;...)  OR we are not in a variable declaration.
         if (gtk=="(") {
            typeless open_paren_pos;
            save_pos(open_paren_pos);
            c_prev_sym_same_line();
            if (gtk!=TK_ID || gtkinfo!="for") {
               //restore_pos(open_paren_pos);gtk="(";
               //break outer_loop;
               // This is not a variable declaration.
               return(0);
            }
            restore_pos(open_paren_pos);gtk="(";
            break outer_loop;
         }
         // case ...:  OR default:  OR (exp)? ...: OR    class a:
         if (gtk==":") {
            check_for_var_decl_or_colon=true;
            break;
         }
         // IF we definitely hit end of statement
         if (gtk==";" || gtk=="{" || gtk=="}") {
            c_next_sym();
            break outer_loop;
         }
         if (gtk=="") {
            break outer_loop;
         }
         // IF we are in a #define
         if (_in_c_preprocessing()) {
            down(); _begin_line();
            break outer_loop;
         }
         //if (gtk=="#") {
         //   // We are lost
         //   return(0);
         //}
         // don't back up more than 250 lines or 10000 characters
         if (p_RLine < orig_line-250) {
            return(0);
         }
         if (_QROffset() < orig_offset-10000) {
            return 0;
         }
         // also watch out for timeout
         if (_CheckTimeout()) {
            return 0;
         }
         c_prev_sym2();
      }
   }
   if (gtk!=">") {
      if (gtk!="") {
         if (p_col>_text_colc()) {
            down();_begin_line();
            _clex_skip_blanks("h");
         } else {
            goto_point((int)point('s')+2);
         }
      }
   }

   // make sure we have cursor at start of identifier
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',get_text_safe(),1,'r')) {
      search('[~'word_chars']\c|^\c','@hr-');
   }

   int count=lastidstart_offset-(int)point('s');
   if (count < 0) {
      return(0);
   }
   _str text=get_text_safe(count):+lastid'(1);';
   classlist := stranslate(strip(prefixexp,'T',':'),':','::');
   _str varname;
   if (classlist=="") {
      varname=lastid"(gvar)";
   } else {
      varname=lastid"("classlist":gvar)";
   }
   utf8 := p_UTF8;
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=utf8;
   //xx::yy::y
   //varname=id"("
   _insert_text(text);
   top();
   //_message_box(varname" text="text);
   coloncolon := "";
   _SetEditorLanguage("c", false);
   status=_VirtualProcSearch(varname);
   if (!status) {
      if (get_text_safe(1,(int)point('s')-1)==":" &&
          get_text_safe(1,(int)point('s')-2)==":"
          ) {
         coloncolon="::";
      }
   }
   _delete_temp_view(temp_view_id);
   if (!status) {
      /*
         A  B(
      */
      //_message_box("Need new tag_decompose_tag code to get return type into otherinfo");
      tag_decompose_tag_browse_info(varname, auto cm);
      info_flags|=VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL;
      if (cm.return_type == "_command") cm.return_type = "";
      if (substr(cm.return_type,1,9) == "_command ") {
         cm.return_type = substr(cm.return_type,10);
      }
      otherinfo=coloncolon:+cm.return_type;
   }
   activate_window(orig_view_id);
   return(0);
}
/**
 * Useful utility function for getting the next token, symbol, or
 * identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string)
 *
 * @return next token or ""
 */
_str c_next_sym()
{
   status := 0;
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   ch := get_text_safe();
   if (ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(c_next_sym());
   }
   start_col := 0;
   start_line := 0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@hr');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=="-" && get_text_safe()==">") {
      right();
      gtk=gtkinfo="->";
      return(gtk);
   }
   if (_LanguageInheritsFrom("d") && ch=="!" && get_text_safe()=="(") {
      right();
      gtk=gtkinfo="!(";
      return(gtk);
   }
   if (_LanguageInheritsFrom("e") && ch==":" && get_text_safe() == "[") {
      gtk=gtkinfo=":[";
      left();
      return(gtk);
   }
   if (_LanguageInheritsFrom("cs") && ch=="?" && get_text_safe() == "[") {
      gtk=gtkinfo="?[";
      left();
      return(gtk);
   }
   if (ch==":" && get_text_safe()==":") {
      right();
      gtk=gtkinfo="::";
      return(gtk);
   }
   if (ch=="&" && get_text_safe()=="&") {
      right();
      gtk=gtkinfo="&&";
      return(gtk);
   }
   if (ch=="|" && get_text_safe()=="|") {
      right();
      gtk=gtkinfo="||";
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
/*
/**
 * Useful utility function for getting the previous token on the
 * same linenext token, symbol, or "" if the previous token is
 * on a different line.
 * <P>
 * This function only always works gInJavadoc_linenum!=0.  Otherwise,
 * this function is somewhat unreliable.
 *
 * @return
 *    previous token or "" if no previous token on current line
 */
*/
static _str c_prev_sym_same_line()
{
   //messageNwait("h0 gtk="gtk);
   if (!gInJavadoc_linenum) {
      if (gtk!="(" && gtk!="::" && gtk!="#") {
         return(c_prev_sym());
      }
      // Only force same line for Slick-C and C++ and InstallScript
      if (!_LanguageInheritsFrom("c") && !_LanguageInheritsFrom("e") && !_LanguageInheritsFrom("rul")) {
         return(c_prev_sym());
      }
   }
   int orig_linenum=(gInJavadoc_linenum) ?gInJavadoc_linenum:p_line;
   _str result=c_prev_sym();
   //messageNwait("h1 gtkinfo="gtkinfo);
   if (p_line == orig_linenum) {
      return result;
   }
   if (p_line == orig_linenum-1 && p_col > _text_colc()) {
      return result;
   }

   //messageNwait("h2");
   gtk=gtkinfo="";
   return(gtk);
}
_str c_prev_sym2()
{
   if (gInJavadoc_linenum) {
      return(c_prev_sym_same_line());
   }
   return(c_prev_sym());
}
/**
 * Useful utility function for getting the previous token, symbol,
 * or identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string).
 *
 * @return previous token or ""
 */
_str c_prev_sym()
{
   status := 0;
   ch := get_text_safe();
   if (ch=="#" && gInJavadoc_linenum) {
      ch=".";
   }
   if (ch=="\n" || ch=="\r" || ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      if (gInJavadoc_flag) {
         status=search('[~ \t\r\n]','@hr-');
         while (get_text_safe() == "/" && _clex_find(0,'g')==CFG_COMMENT) {
            if(p_col == 1) { 
               up();
               _end_line();
            } else {
               left();
            }
            status=search('[~ \t\r\n]','@hr-');
         }
      } else {
         status=_clex_skip_blanks('-h');
      }
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(c_prev_sym());
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      int end_col=p_col+1;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col==1) break;
            left();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               right();
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      } else {
         search('[~'word_chars']\c|^\c','@hr-');
         gtk=TK_ID;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if (ch=="#" && p_col==1 && p_line==1 && _LanguageInheritsFrom("c")) {
      up();_end_line();
      gtk=gtkinfo=ch;
      return(gtk);
   }
   if (ch=="@") {
      up();_end_line();
      gtk=gtkinfo=ch;
      return(gtk);
   }
   if (p_col==1) {
      up();_end_line();
      if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      if (_LanguageInheritsFrom("pl") && ch=="'") {
         gtk=gtkinfo="::";
      }
      return(gtk);
   }
   left();
   if (ch==">" && get_text_safe()=="-") {
      left();
      gtk=gtkinfo="->";
      return(gtk);
   }
   if (_LanguageInheritsFrom("d") && ch=="(" && get_text_safe()=="!") {
      left();
      gtk=gtkinfo="!(";
      return(gtk);
   }
   if (_LanguageInheritsFrom("e") && ch==":" && get_text_safe() == "[") {
      gtk=gtkinfo=":[";
      left();
      return(gtk);
   }
   if (_LanguageInheritsFrom("cs") && ch=="?" && get_text_safe() == "[") {
      gtk=gtkinfo="?[";
      left();
      return(gtk);
   }
   if (_LanguageInheritsFrom("e") && point('s') > 2 && ch=="=" &&
       get_text_safe(1,(int)point('s')-1)==":" &&
       (get_text_safe()=="!" || get_text_safe()=="=")) {
      gtk=gtkinfo=":"get_text_safe()"=";
      left();
      left();
      return(gtk);
   }
   if (ch=="=" && pos(get_text_safe(),"=+!%^*&|/><")) {
      gtk=gtkinfo=get_text_safe()"=";
      left();
      return(gtk);
   }
   if (ch=="&" && get_text_safe() == "&") {
      gtk=gtkinfo="&&";
      left();
      return(gtk);
   }
   if (ch=="|" && get_text_safe() == "|") {
      gtk=gtkinfo="||";
      left();
      return(gtk);
   }
   if (ch=="<" && get_text_safe() == "<") {
      gtk=gtkinfo="<<";
      left();
      return(gtk);
   }
   if (ch==">" && get_text_safe() == ">") {
      gtk=gtkinfo=">>";
      left();
      return(gtk);
   }
   if (ch=="=" && pos(get_text_safe(),"=+!%^*&|/><")) {
      gtk=gtkinfo=get_text_safe()"=";
      left();
      return(gtk);
   }
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col :=p_col+1;
      start_line:=p_line;
      status=_clex_find_start();
      if (!status && p_line==start_line) {
         gtk=TK_STRING;
         gtkinfo=_expand_tabsc(p_col,start_col-p_col+1);
         left();
      }
      return(gtk);
   }
   if (_LanguageInheritsFrom("pl") && ch=="'") {
      gtk=gtkinfo="::";
      return(gtk);
   }
   if (ch==":" && get_text_safe()==":") {
      left();
      gtk=gtkinfo="::";
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}

/**
 * Return gtkinfo which was set by c_next_sym() and c_prev_sym()
 */
_str c_get_syminfo()
{
   return gtkinfo;
}

/**
 * Parse past the open brace of a C99 style struct initializer 
 * in order to find the variable or expression on the left-hand 
 * side of the assignment or declaration in order to complete 
 * the prefix expression for context tagging. 
 */
static int c_before_struct_initializer(_str &prefixexp)
{
   // current character is an open brace, skip past it.
   prev_char();
   _clex_skip_blanks('-h');

   // check for an assignment statement
   if (get_text() != "=") {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   // skip over the assignment operator
   prev_char();
   if (get_text() == ":") left(); 
   _clex_skip_blanks('-h');

   // now check for array type declarator
   gtk=c_prev_sym2();
   while (gtk=="]" && get_text()=="[") {
      left();
      if (_LanguageInheritsFrom("e") && get_text()==":") left();
      gtk=c_prev_sym2();
   }

   // we are expecting an identifier now
   if (gtk!=TK_ID) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   // add the identifier to the prefix expression 
   prefixexp=gtkinfo:+prefixexp;
   gtk=c_prev_sym2();
   return(2);  // continue
}

/**
 * Utility function for parsing part of prefix expression before a
 * dot (member access operator), called starting from _c_get_expression_info 
 * or c_before_id, etc.  Basic plan is to parse code backwards from the 
 * cursor location until you reach a stopping point. 
 *
 * @param isjava                 is this Java, JavaScript or C# code?
 * @param idexp_info             (reference) context expression information.
 *
 * @return
 * <LI>0  -- finished successfully
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int c_before_dot(bool isjava, VS_TAG_IDEXP_INFO &idexp_info)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := 0;
   i_expr := "";

outer_loop:
   for (;;) {
      idexp_info.prefixexpstart_offset = (int)point('s')+1;
      switch (gtk) {
      case "]":
         if (idexp_info.prefixexp=="" && _LanguageInheritsFrom('m')) {
            status = _objectivec_get_bracket_expression(i_expr);
            if (!status) {
               idexp_info.prefixexp = i_expr:+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               left();
               return(2);
            }
         } 

         i_expr = _c_get_index_expression(status);
         if (status != 0) {
            return status;
         }

         idexp_info.prefixexp = '['i_expr']'idexp_info.prefixexp;
         left();

         gtk=c_prev_sym2();
         if (_LanguageInheritsFrom("e") && gtk==":") {
            idexp_info.prefixexp = ":":+idexp_info.prefixexp;
            gtk=c_prev_sym2();
         }
         if (_LanguageInheritsFrom("e") && gtk=="->") {
            idexp_info.prefixexp = "->":+idexp_info.prefixexp;
            gtk=c_prev_sym2();
         }
         if (gtk!="]") {
            if (gtk!=TK_ID) {
               if (gtk==")") {
                  continue;
               }
               if (gtk=="," || gtk=="{") {
                  continue;
               }
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
            if (isjava && gtkinfo=="new") {
               idexp_info.prefixexp = "new ":+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               gtk=c_prev_sym2();
            }
            return(2);  // continue
         }
         break;
      case ")":
         nest_level := 0;
         int count;
         for (count=0;;++count) {
            if (count>200) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk:=="") {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk=="]") {
               i_expr = "";
               if (_LanguageInheritsFrom('m')) {
                  status = _objectivec_get_bracket_expression(i_expr);
                  if (!status) {
                     idexp_info.prefixexp = i_expr:+idexp_info.prefixexp;
                     gtk=c_prev_sym_same_line();
                  }
               } 

               if (i_expr == "") {
                  idexp_info.prefixexp = "[]":+idexp_info.prefixexp;
                  right();
                  status=find_matching_paren(true);
                  if (status) {
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
                  left();
               }

            } else {
               if (gtk==TK_ID) {
                  idexp_info.prefixexp = gtkinfo" ":+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               }
            }
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            if (gtk=="(" || gtk=="!(") {
               --nest_level;
               if (nest_level<=0) {
                  gtk=c_prev_sym_same_line();
                  if (gtk!=TK_ID) {

                     if (gtk=="]") {
                        continue outer_loop;
                     }
                     if (gtk==")") {
                        continue;
                     }
                     if (gtk==">") {
                        continue outer_loop;
                     }
                     if (gtk=="") {
                        return(0);
                     }
                     return(0);
                  }
                  if (pos(" "gtkinfo" "," if elsif elseif while catch switch ")) {
                     return 0;
                  }
                  idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
                  idexp_info.prefixexpstart_offset = (int)point('s')+1;
                  gtk=c_prev_sym_same_line();
                  if (isjava && gtkinfo=="new") {
                     idexp_info.prefixexp = "new ":+idexp_info.prefixexp;
                     idexp_info.prefixexpstart_offset = (int)point('s')+1;
                     gtk=c_prev_sym2();
                  }
                  return(2);// Tell call to continue processing
               }
            } else if (gtk==")") {
               ++nest_level;
            }
            gtk=c_prev_sym2();
         }
         break;
      case ">":
         if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("c") || _LanguageInheritsFrom("cs")) {
            if (add_template_args(idexp_info.prefixexp,idexp_info.prefixexpstart_offset) != 0 || gtk!=TK_ID) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            //right();
            _clex_skip_blanks("h");
            idexp_info.prefixexpstart_offset = (int)point('s');
            _clex_skip_blanks("h-");
            gtk=c_prev_sym2();
            if (isjava && gtkinfo=="new") {
               idexp_info.prefixexp = "new ":+idexp_info.prefixexp;
               _clex_skip_blanks('h');
               idexp_info.prefixexpstart_offset = (int)point('s');
               _clex_skip_blanks('h-');
               gtk=c_prev_sym2();
            }
            return(2);  // continue
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case ",":
         // this may be a C99 style designated struct initializer
         // first, move to the corresponding open brace
         if (idexp_info.prefixexp != "" && _first_char(idexp_info.prefixexp) != ".") {
            right();right();
            _clex_skip_blanks('h');
            idexp_info.prefixexpstart_offset = (int)point('s');
            return 0;
         }
         right();right();
         status = backward_up_sexp();
         if (status < 0) {
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         // we should be on the open brace
         if (get_text() == "{") {
            return c_before_struct_initializer(idexp_info.prefixexp);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case "{":
         // this may be a C99 style designated struct initializer
         if (idexp_info.prefixexp != "" && _first_char(idexp_info.prefixexp) != ".") {
            right();right();
            _clex_skip_blanks('h');
            idexp_info.prefixexpstart_offset = (int)point('s');
            return 0;
         }
         return c_before_struct_initializer(idexp_info.prefixexp);
      default:
         if (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("d") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom("rs")) {
            if (gtk==TK_NUMBER || gtk==TK_STRING) {
               idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               return 0;
            }
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
   return(VSCODEHELPRC_CONTEXT_NOT_VALID);
}
/**
 * Utility function for parsing part of prefix expression before
 * an identifier, called starting from _c_get_expression_info or
 * c_before_dot, etc.  Basic plan is to parse code backwards 
 * from the cursor location until you reach a stopping point.
 *
 * @param isjava                 Is this Java, JavaScript, or similar? 
 * @param not_function_words     words not to consider as function names.
 * @param idexp_info             (reference) context expression information.
 *
 * @return
 * <LI>0  -- finished successfully
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int c_before_id(bool isjava, _str &not_function_words,
                       VS_TAG_IDEXP_INFO &idexp_info, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug > 9) {
      isay(depth, "c_before_id: isjava="isjava" lastid="idexp_info.lastid);
   }
   
   status := 0;
   for (;;) {
      if (_chdebug > 9) {
         isay(depth, "c_before_id: gtk="gtk", info="gtkinfo);
      }
      switch (gtk) {
      case "*":
      case "&":
      case "^":
         idexp_info.info_flags |= VSAUTOCODEINFO_HAS_REF_OPERATOR;
         idexp_info.otherinfo = gtk;
         return(0);
      case "#":
         _clex_skip_blanks('h');
         int pound_offset=(int)point('s');
         if (idexp_info.prefixexp=="") {
            idexp_info.prefixexp="#";
            idexp_info.prefixexpstart_offset = pound_offset;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
         }
         return(0);
      case "@":
         search("@","@h");
         int at_offset=(int)point('s');
         idexp_info.prefixexp = "@":+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset = at_offset;
         if (_in_comment()) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         } else {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
         }
         return(0);
      case "->":
         if (isjava) {
            return(0);
         }
         // Fall thru intentional
      case ".":
         // "." is used for string concatentation in Perl and PHP, not member access
         if (gtk == "." && (_LanguageInheritsFrom("pl") || _LanguageInheritsFrom("phpscript"))) {
            return(0);
         }
         idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset = (int)point('s')+1;
         gtk=c_prev_sym2();
         if (gtk!=TK_ID) {
            if (gtk=="" && gInJavadoc_linenum) {
               //prefixexp=orig_prefixexp;
               if (_LanguageInheritsFrom("c") && !_LanguageInheritsFrom("d")) {
                  idexp_info.prefixexp = "(*this)":+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp = "this":+idexp_info.prefixexp;
               }
               return(0);
            }
            status=c_before_dot(isjava,idexp_info);
            if (status < 0) {
               return(status);
            }
         } else {
            isBuiltinType := false;
            if (_c_has_boxing_conversion(p_LangId)) {
               isBuiltinType = _c_is_builtin_type(gtkinfo);
            }
            if (!isBuiltinType && pos(" "gtkinfo" ",not_function_words,1,"e")) {
               return(0);
            }
            if (gInJavadoc_linenum && gtkinfo=="see" &&
                get_text_safe()=="@") {
               //prefixexp=orig_prefixexp;
               if (_LanguageInheritsFrom("c") && !_LanguageInheritsFrom("d")) {
                  idexp_info.prefixexp="(*this)":+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp="this":+idexp_info.prefixexp;
               }
               return(0);
            }
            idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
         }
         break;
      case "::":
         if (!isjava) {
            for (;;) {
               idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               gtk=c_prev_sym_same_line();
               if (gtk!=TK_ID || pos(" "gtkinfo" ",not_function_words,1,"e")) {
                  if (gtk=="<") {
                     if (add_template_args(idexp_info.prefixexp,idexp_info.prefixexpstart_offset) != 0 && gtk!=TK_ID) {
                        return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                     }
                  } else {
                     idexp_info.prefixexpstart_offset = (int)point('s')+1;
                     return(0);
                  }
               }
               idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               gtk=c_prev_sym_same_line();
               if (gtk!="::") {
                  return(0);
               }
            }
         }
         return(0);
      case "<":
         // check for #include <>
         save_pos(auto before_lt);
         left();
         gtk=c_prev_sym_same_line();
         if (gtk==TK_ID && (gtkinfo=="include" || gtkinfo=="import" || gtkinfo=="require")) {
            include_info := gtkinfo;
            gtk=c_prev_sym_same_line();
            if (gtk!="#") {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            // scan ahead for the rest of the filename (extension)
            restore_pos(before_lt);
            after_lastid := "";
            gtk = c_next_sym();
            if (gtk == "<") {
               gtk = c_next_sym();
               if (gtk == TK_ID && gtkinfo==idexp_info.lastid) {
                  gtk = c_next_sym();
                  while (gtk=="." || gtk==TK_ID) {
                     after_lastid :+= gtkinfo;
                     gtk = c_next_sym();
                  }
                  if (gtk != ">") {
                     after_lastid = "";
                  }
               }
            }
            // set up idexp_info to return
            restore_pos(before_lt);
            typeless start_col=p_col;
            typeless start_offset=point('s');
            if (idexp_info.prefixexp != "") {
               idexp_info.lastid = idexp_info.prefixexp:+idexp_info.lastid;
               idexp_info.lastidstart_offset = idexp_info.prefixexpstart_offset;
               idexp_info.lastidstart_col -= length(idexp_info.prefixexp);
            }
            idexp_info.lastid :+= after_lastid;
            idexp_info.prefixexpstart_offset = start_offset+1;
            idexp_info.prefixexp="#"include_info;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
            return 0;
         }
         restore_pos(before_lt);
         return(0);
      case "/":
         // check for #include <>
         save_pos(auto before_slash);
         orig_prefixexp := idexp_info.prefixexp;
         orig_prefixexpstart_offset := idexp_info.prefixexpstart_offset;
         for (;;) {
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym_same_line();
            if (gtk!=TK_ID) {
               break;
            }
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym_same_line();
            if (gtk!="/") break;
         }
         // go handle include case
         if (gtk=="<") {
            continue;
         }
         idexp_info.prefixexp = orig_prefixexp;
         idexp_info.prefixexpstart_offset = orig_prefixexpstart_offset;
         restore_pos(before_slash);
         return(0);

      case TK_ID:
         if (gtkinfo=="new" || gtkinfo=="gcnew") {
            idexp_info.prefixexp = gtkinfo" "idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
            if (_chdebug > 9) {
               isay(depth, "c_before_id: new prefixexp: '"idexp_info.prefixexp"', left_of_new "gtk", "gtkinfo);
            }
            if (!isjava || gtk!=".") {
               return(0);
            }
            continue;
         } else if (gtkinfo=="goto") {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
         } else if (gtkinfo=="throw") {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_THROW_STATEMENT;
         } else if (gtkinfo=="raise" && (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("ttcn3"))) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_THROW_STATEMENT;
         } else if (gtkinfo=="import" && isjava && !_LanguageInheritsFrom("cs")) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
         } else if (gtkinfo=="using" && (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("cs"))) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
         } else if ((gtkinfo == "sub" && _LanguageInheritsFrom("pl")) ||
                    (lowcase(gtkinfo) == "function" && (_LanguageInheritsFrom("idl") || _LanguageInheritsFrom("js") || _LanguageInheritsFrom("cfscript") || _LanguageInheritsFrom("phpscript") || _LanguageInheritsFrom("lua"))) ||
                    (gtkinfo == "def" && (_LanguageInheritsFrom("py") || _LanguageInheritsFrom("ruby"))) ||
                    (gtkinfo == "task" && (_LanguageInheritsFrom("verilog") || _LanguageInheritsFrom("systemverilog"))) ||
                    (gtkinfo == "prototype" && _LanguageInheritsFrom("rul"))) {
            idexp_info.info_flags |= VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER;
         } else if (gtkinfo=="class" || gtkinfo=="struct"    ||
                    gtkinfo=="union" || gtkinfo=="interface" ||
                    gtkinfo=="enum"  || gtkinfo=="typename"  ||
                    (gtkinfo=="enum_flags" && _LanguageInheritsFrom("e")) ||
                    (gtkinfo=="namespace" && _LanguageInheritsFrom("c"))) {
            idexp_info.info_flags |= VSAUTOCODEINFO_HAS_CLASS_SPECIFIER;
         } 
         return(0);

      default:
         return(0);

      }
   }
}
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

