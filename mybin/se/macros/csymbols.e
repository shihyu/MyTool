////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50649 $
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
#import "cutil.e"
#import "dlgman.e"
#import "emacs.e"
#import "listproc.e"
#import "main.e"
#import "math.e"
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


static _str gtkinfo;
static _str gtk;

static int gInJavadoc_linenum;
static int gInJavadoc_flag;

const C_COMMON_END_OF_STATEMENT_RE = 'if|while|switch|for|case|default|public|private|signals|protected|static|class|break|continue|do|else|goto|try|catch|return';

const JAVA_MORE_END_OF_STATEMENT_RE = 'abstract|final|native|synchronized|throw|volatile|enum';
const C_MORE_END_OF_STATEMENT_RE = 'auto|enum|extern|register|struct|typedef|delete|finally|friend|inline|restrict|overload|virtual|using|template|asm|throw|namespace';
const SLICKC_MORE_END_OF_STATEMENT_RE = 'enum|extern|register|struct|typedef|delete|finally|using|template|throw|namespace';
const CS_MORE_END_OF_STATEMENT_RE = 'auto|enum|extern|register|struct|typedef|delete|finally|friend|inline|operator|overload|virtual|using|throw|namespace|lock|fixed|readonly|override|unsafe|var';
const RUL_MORE_END_OF_STATEMENT_RE = 'abort|begin|downto|elseif|end|endfor|endif|endprogram|endswitch|endwhile|exit|function|program|prototype|repeat|step|then|to|typedef|until';
const PHP_MORE_END_OF_STATEMENT_RE = 'exit|endif|endwhile|elseif|global|define|include|require|virtual';
const SAS_MORE_END_OF_STATEMENT_RE = 'abort|array|attrib|by|call|char|class|create|decending|delete|delimiter|do|else|end|endsas|go|gt|if|in|le|macro|macrogen|ne|not|or|otherwise|proc|quit|return|run|to|until|var|when|where|while';
const D_MORE_END_OF_STATEMENT_RE = 'abstract|alias|asm|auto|break|type|case|catch|class|continue|default|do|else|enum|export|extern|final|finally|for|foreach|foreach_reverse|function|goto|if|import|interface|lazy|macro|mixin|module|new|nothrow|null|out|override|pacakge|pragma|private|protected|public|pure|return|scope|static|struct|switch|synchronized|template|throw|try|typedef|union|unittest|void|volatile|while|with';

const JAVA_NOT_FUNCTION_WORDS = ' catch do for if return synchronized switch throw while ';
const C_NOT_FUNCTION_WORDS = ' int long double float bool short signed unsigned char asm __asm __declspec __except catch do for if return sizeof typeid switch throw typedef using while with template volatile '; // const_cast static_cast dynamic_cast reinterpret_cast 
const CS_NOT_FUNCTION_WORDS = ' int long double float bool short char decimal byte ubyte string var in is checked unchecked ushort ulong uint catch do for foreach if return sizeof typeid switch using throw while lock with fixed ';
const D_NOT_FUNCTION_WORDS = ' abstract alias align asm auto body bool break byte case cast catch cdouble cent cfloat char class const continue creal dchar default delegate delete deprecated do double else enum export extern final finally float for foreach foreach_reverse function goto idouble if ifloat import in inout int interface invariant ireal is lazy long macro mixin module new nothrow out override package pragma private protected public pure real ref return scope short static struct switch synchronized template throw try typedef typeid typeof ubyte ucent uint ulong union unittest ushort void volatile wchar while with ';
const RUL_NOT_FUNCTION_WORDS = ' abort case downto elseif exit for goto if return step switch to until while ';

/*
#define C_BUILTIN_TYPES ':bool:char:double:float:int:long:short:signed:unsigned:unsigned char:unsigned short:unsigned int:unsigned long:signed char:signed short:signed int:signed long:void:long long:long double:short int:long int:unsigned short int:unsigned long int:'
#define CS_BUILTIN_TYPES ':int:long:double:float:bool:short:char:decimal:byte:ubyte:string:'
#define JAVA_BUILTIN_TYPES ':boolean:byte:char:double:float:int:long:short:void:'
#define RUL_BUILTIN_TYPES ':BOOL:BYREF:CHAR:HWND:INT:LIST:LONG:LPSTR:NUMBER:POINTER:SHORT:STRING:'
#define SLICKC_BUILTIN_TYPES ':double:float:int:long:short:unsigned:void:typeless:bigint:_str:bigstring:bigfloat:var:boolean:'
*/

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
   int i=0;
   if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('e')) {
      i=lastpos('.',class_name);
      if (i) {
         class_name=substr(class_name,1,i-1):+VS_TAGSEPARATOR_package:+substr(class_name,i+1);
      }
   } else {
      i=lastpos('::',class_name);
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
   while (gtk=='.') {
      class_name=class_name:+gtkinfo;
      c_next_sym();
      if (gtk==TK_ID) {
         class_name=class_name:+gtkinfo;
         c_next_sym();
      } else {
         break;
      }
   }
   return(xlat_class_name(class_name));
}

static void skip_template_args()
{
   isdlang := _LanguageInheritsFrom('d');
   int nesting=0;
   c_next_sym();
   for (;;) {
      if (c_sym_gtk() == '<' || (isdlang && c_sym_gtk() == '!(')) {
         ++nesting;
      } else if (c_sym_gtk() == '>' || (isdlang && c_sym_gtk() == ')')) {
         --nesting;
         if (nesting <= 0) {
            return;
         }
      } else if (c_sym_gtk()=='') {
         return;
      }
      c_next_sym();
   }
}


int c_parse_class_definition(_str &class_name, _str &class_type_name, _str &implement_list,int &vsImplementFlags,typeless &AfterKeyinPos=null)
{
   class_type_name='';
   if (_LanguageInheritsFrom("c")) {
      vsImplementFlags=VSIMPLEMENT_ABSTRACT;
   } else {
      vsImplementFlags=0;
   }
   class_name="";
   implement_list="";
   _str line='', word='';
   int col=0, indent_col=0;
   left();
   typeless brace_nrseek=_nrseek();
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }

   inherit_class_name := '';
   in_template := false;
   in_c := _LanguageInheritsFrom('c');
   in_slickc := _LanguageInheritsFrom('e');
   in_java := _LanguageInheritsFrom('java');
   isdlang := _LanguageInheritsFrom('d');

   if (in_java) {
      if (_clex_skip_blanks('-')) return(0);
      if (get_text_safe()==')') {
         // Here we match round parens. ()
         int status=_find_matching_paren(def_pmatch_max_diff);
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

         if (gtk==TK_ID && pos(' 'gtkinfo' ',' for if switch while new ')) {
            return(0);
         }
         implement_list="";
         //typeless p4;
         while (gtk==TK_ID || gtk=='.') {
            if (gtkinfo=='new') {
               break;
            }
            implement_list=gtkinfo:+implement_list;
            c_prev_sym2();
            //save_pos(p4);
         }
         if (gtkinfo!='new') {
            return(0);
         }
         implement_list=xlat_class_name(implement_list);
         search("new",'@h');
         col=p_col;
         first_non_blank();
         if (col!=p_col) {
            if (AfterKeyinPos!=null) {
               typeless t1;
               save_pos(t1);
               restore_pos(AfterKeyinPos);
               down();
               get_line(line);
               if (line=='}') {
                  first_non_blank();
                  col=p_col+p_SyntaxIndent-1;
                  replace_line(indent_string(col)'}');
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
         if (word=='class' || word=='struct' || word=='union' || word=='enum' || word=='interface') {
            class_type_name=word;
            break;
         }
         if (word=='enum_flags' && in_slickc) {
            class_type_name=word;
            break;
         }
         if (word=='abstract') {
            vsImplementFlags=VSIMPLEMENT_ABSTRACT;
         }
         if (word =='template' && in_c) {
            in_template = true;
            skip_template_args();
         }
         c_next_sym();
      }
      c_next_sym();
      if (gtk!=TK_ID) {
         if (class_type_name == 'enum' || class_type_name == 'union') {  // anonymous enums & unions
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
         while (gtkinfo=='implements' || gtkinfo=='extends') {
            for (;;) {
               c_next_sym();
               if (gtk!=TK_ID) {
                  break;
               }
               inherit_class_name=parse_java_class_name();
               if (inherit_class_name=="") {
                  return(1);
               }
               if (implement_list=="") {
                  implement_list=inherit_class_name;
               } else {
                  implement_list=implement_list';'inherit_class_name;
               }
               if (gtk!=',') {
                  break;
               }
            }
         }
      } else {
         if (in_c && in_template && (gtk == '<' || (isdlang && gtk == '!('))) { // template specialization
            skip_template_args();
            c_next_sym();
         }
         if ( gtk=='{' ) {
            if (in_c || in_slickc) {
               return indent_col;
            }
         }
         if (gtk!=':') {
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
            if (gtk!=TK_ID && gtk!='::') {
               return(0);
            }
            inherit_class_name='';
            while (gtk==TK_ID || gtk=='::') {
               inherit_class_name=inherit_class_name:+gtkinfo;
               c_next_sym();
            }
            inherit_class_name=xlat_class_name(inherit_class_name);
            if (gtk=='<' || (gtk=='!(' && isdlang)) {
               int nesting=0;
               for (;;) {
                  inherit_class_name=inherit_class_name:+gtkinfo;
                  if (gtk=='<' || (gtk=='!(' && isdlang)) {
                     ++nesting;
                  } else if (gtk=='>' || (gtk==')' && isdlang)) {
                     --nesting;
                     if (nesting<=0) {
                        c_next_sym();
                        break;
                     }
                  } else if (gtk=='{') {
                     return(0);
                  }
                  c_next_sym();
               }
            }
            if (implement_list=="") {
               implement_list=inherit_class_name;
            } else {
               implement_list=implement_list';'inherit_class_name;
            }
            if (gtk!=',') {
               break;
            }
         }
      }
      if (gtkinfo!='{' || _nrseek()-1!=brace_nrseek) {
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
 *
 * @return 0 on success, non-zero otherwise
 */
int _c_get_expression_pos(int &lhs_start_offset,
                          _str &expression_op,
                          int &pointer_count)
{
   // first check for a compatible operator
   typeless p, s1,s2,s3,s4,s5;
   save_pos(p);
   if (get_text_safe()!='') {
      left();
   }
   gtk=c_prev_sym();

   // allow one open parenthesis, no more (this is a fudge-factor)
   if (gtk=='(') {
      gtk=c_prev_sym();
   }

   // handle return statements
   if (gtkinfo=='return') {
      expression_op=gtkinfo;
      _UpdateContext(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int context_id=tag_current_context();
      if (context_id > 0) {
         _str type_name='';
         _str proc_name='';
         int start_seekpos=0;
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
   if (gtkinfo=='case') {
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
   _str allowed=" = == += -= != %= ^= *= &= |= /= >= <= > < + - * / % ^ & | ";
   if (_LanguageInheritsFrom('e')) {
      allowed=allowed:+':== :!= .= ';
   }
   if (!pos(' 'gtkinfo' ',allowed)) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   expression_op=gtkinfo;

   // ok, now what is on the other side of the expresson?
   gtk=c_prev_sym();

   // watch for array arguments
   while (gtk==']') {
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
   if (gtk==')') {
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

static boolean _c_skip_operators_left()
{
   // check for C++ overloaded operators
   if (!pos(get_text_safe(), "~=+-!%^&*[]<>/|) ")) {
      return false;
   }

   // check for function call operator and other operators
   typeless op_pos;
   save_pos(op_pos);
   if (get_text_safe()==')' && get_text_safe(1, _nrseek()-1)=='(') {
      left();
      left();
   } else if (get_text_safe():==' ') {
      while (p_col > 1 && get_text_safe() :== ' ') {
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
   int end_col = p_col;
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

static _str gOperatorNameMap:[]:[] = {
   "e" => {
      "="   => "copy",
      "<"   => "compare",
      "<="  => "compare",
      ">"   => "compare",
      ">="  => "compare",
      "=="  => "equals",
      "!="  => "equals",
      ":[]" => "_hash_el",
      "[]"  => "_array_el",
   },
   "d" => {
      "++"  => "opPostInc",
      "--"  => "opPostDec",
      "+"   => "opAdd",
      "-"   => "opSub",
      "*"   => "opMul",
      "/"   => "opDiv",
      "%"   => "opMod",
      "&"   => "opAnd",
      "|"   => "opOr",
      "^"   => "opXor",
      "<<"  => "opShl",
      ">>"  => "opShr",
      ">>>" => "opUShr",
      "~"   => "opCat",
      "=="  => "opEquals",
      "!="  => "opEquals",
      "< "  => "opCmp",
      "<="  => "opCmp",
      "> "  => "opCmp",
      ">="  => "opCmp",
      "= "  => "opAssign",
      "+="  => "opAddAssign",
      "-="  => "opSubAssign",
      "*="  => "opMulAssign",
      "/="  => "opDivAssign",
      "%="  => "opModAssign",
      "&="  => "opAndAssign",
      "|="  => "opOrAssign",
      "^="  => "opXorAssign",
      "<<=" => "opShlAssign",
      ">>=" => "opShrAssign",
      ">>>="=> "opUShrAssign",
      "~="  => "opCatAssign",
      "in"  => "opIn",
      "()"  => "opCall",
      "[]"  => "opIndex",
   }
};

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
 * innerclass ic=j.new innerclass().&lt;Here&gt;       /* java */
 *    prefixexp="j.new innerclass()."
 *    lastid=""
 *    lastidstart_col=column after last dot
 *    infoflags=VSAUTOCODEINFO_DO_LIST_MEMBERS
 *
 * innerclass ic=j.new innerclass(&lt;Here&gt;        /* java */
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
int _c_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info, 
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (0 && _chdebug) {
      isay(depth, "_c_get_expression_info: possible_op="PossibleOperator" @"_QROffset()" ["p_line","p_col"]");
   }
   int status=0;
   idexp_info.errorArgs._makeempty();
   _str not_function_words=C_NOT_FUNCTION_WORDS;
   boolean isjava=false;
   boolean slickc=false;
   boolean iscpp=false;
   boolean javascript=false;
   boolean isperl=false;
   boolean isrul=false;
   boolean isidl=false;
   boolean isphp=false;
   boolean isobjc=false;
   switch (lowcase(p_LangId)) {
   case 'cs':
      isjava=true;
      not_function_words=CS_NOT_FUNCTION_WORDS;
      break;
   case 'java':
      isjava=true;
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
      break;
   case 'd':
      isjava=true;
      not_function_words=D_NOT_FUNCTION_WORDS;
      break;
   case 'e':
      slickc=true;
      break;
   case 'idl':
      isidl=true;
      break;
   case 'phpscript':
      isphp=true;
      break;
   case 'ansic':
   case 'c':
      iscpp=true;
      break;
   case 'cfscript':
   case 'js':
      javascript=true;
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
      break;
   case 'pl':
      isperl=true;
      break;
   case 'rul':
      isrul=true;
      not_function_words=RUL_NOT_FUNCTION_WORDS;
      break;
   case 'm':
      iscpp=true;
      isobjc=true;
      break;
   }
   idexp_info.otherinfo="";
   gInJavadoc_flag=0;
   
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   int cfg=0;
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
   int index=0;
   if (cfg==CFG_COMMENT) {
      _str tag='';
      if (!_inJavadocSeeTag(tag)) {
         if (_inDocComment()) {
            restore_pos(orig_pos);
            return _doc_comment_get_expression_info(PossibleOperator, idexp_info, visited, depth+1);
         }
         index=find_index('_javadoc_'tag'_find_context_tags',PROC_TYPE);
         if (!index) {
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
      _str ch=get_text_safe();
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
            int start_col=p_col;
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
            idexp_info.prefixexp='';
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
            idexp_info.prefixexp='';
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
         int before_col=p_col;
         clex_status=_clex_find(STRING_CLEXFLAG,'o');
         if (clex_status) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         int start_col=p_col;
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
         idexp_info.prefixexp='';
         idexp_info.lastidstart_col=start_col;
         idexp_info.lastidstart_offset=start_offset;
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         idexp_info.lastid=_expand_tabsc(start_col,p_col-start_col+1);
         //say("_c_get_expression_info: lastidstart_col="idexp_info.lastidstart_col" lastid="idexp_info.lastid);

         p_col=before_col;
         gtk=c_prev_sym_same_line();
         include_info := gtkinfo;
         if (gtk!=TK_ID || (gtkinfo!='include' && gtkinfo!='import' && gtkinfo!='require')) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         gtk=c_prev_sym_same_line();
         if (gtk!='#') {
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
      gInJavadoc_linenum=(p_active_form.p_name=='_javadoc_form')?p_line:0;
   }

   // Only want auto-list members on _ for Slick-C when type
   // property "p_"
   // DOB
   if ( PossibleOperator &&  slickc &&
        get_text_safe(1,(int)point('s')-1)=='_' &&
        (
           get_text_safe(1,(int)point('s')-2)!='p' ||
            pos('['word_chars']',get_text_safe(1,(int)point('s')-3),1,'r')
        )
      ) {
      restore_pos(orig_pos);
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   _str ch='';
   _str line='';
   int orig_col=p_col;
   int orig_line=p_RLine;
   int start_col=0;
   int end_col=0;
   typeless start_offset=0;
   typeless end_offset=0;

   // DOB - Problem if this is past end of line
   //past_end_of_line(true);
   if (PossibleOperator && !(slickc && get_text_safe(1,(int)point('s')-1)=='_')) {
      if (p_col == 1) {
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      left();
      ch=get_text_safe();
      if (ch=='#' && gInJavadoc_linenum) {
         ch='.';
      }
      if (_chdebug > 9) {
         isay(depth, "_c_get_expression_info: chleft="ch);
      }
      
      switch (ch) {
      case '#':
         orig_col=p_col;
         p_col=1;
         _clex_skip_blanks('');
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
            idexp_info.prefixexp='#';
            restore_pos(orig_pos);
            return(0);
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '@':
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
            idexp_info.prefixexp='@';
            restore_pos(orig_pos);
            idexp_info.prefixexpstart_offset=(int)point('s')-1;
            if (_in_comment()) {
               idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
            } else {
               idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
            }
            return(0);
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case ':':
         if (!(iscpp || isperl || isidl)|| get_text_safe(1,(int)point('s')-1)!=':') {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         // foo::bar, foo is not a constructor or destructor, even if name matches
         //idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
         // found a ::, drop through to other dot case
      case '>':
      case '.':
         //say("here");
         orig_col=p_col;
         if (ch=='.') {
            if (isphp) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            // foo.bar, foo is not a constructor or destructor, even if name matches
            //idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
            // Watch out for parse <exp> with a . b .
            if (slickc && get_text_safe(1,(int)point('s')-1)=='') {
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
         } else if (ch==':') {
            right();
         } else {
            if (isjava || javascript) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (get_text_safe(1,(int)point('s')-1)!='-') {
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
      case '/':
      case '\':
         save_pos(auto before_slash);
         right();
         if (get_text()=='>') {
            restore_pos(before_slash);
            start_col=p_col;
            start_offset=point('s');
            idexp_info.lastidstart_col=start_col;
            idexp_info.lastidstart_offset=start_offset;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            idexp_info.lastid='';
            idexp_info.prefixexp='';
            idexp_info.info_flags=0;
            c_before_id(false, not_function_words, idexp_info);
            restore_pos(orig_pos);
            return 0;
         }
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         break;
      case '<':
      case '(':
         if (ch=='(') {
            idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
            idexp_info.lastidstart_col=p_col;  // need this for function pointer case
            idexp_info.lastidstart_offset=(int)point('s');  // need this for function pointer case
         } else {

            // check for #include <>
            save_pos(auto before_lt);
            left();
            gtk=c_prev_sym_same_line();
            if (gtk==TK_ID && (gtkinfo=='include' || gtkinfo=='import' || gtkinfo=='require')) {
               include_info := gtkinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!='#') {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               restore_pos(before_lt);
               start_col=p_col;
               start_offset=point('s');
               idexp_info.lastidstart_col=start_col+1;
               idexp_info.lastidstart_offset=start_offset+1;
               idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
               idexp_info.lastid='';
               idexp_info.prefixexp="#"include_info;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
               restore_pos(orig_pos);
               return 0;
            }
            restore_pos(before_lt);

            if (javascript || slickc || isrul || isphp || get_text_safe(1,(int)point('s')-1)=='<') {
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
         if (ch=='(' && (get_text_safe()==')' || get_text_safe()==']' || ((iscpp || isjava) && get_text_safe()=='>')) && !javascript && !isphp) {
            // If we really have a cast like (char *)(p+1) don't worry about it
            //typeless p2;
            //save_pos(p2);
            end_offset=point('s');
            for (;;) {
               if (get_text_safe()=='>') {
                  // match template argument start
                  typeless gts1, gts2, gts3, gts4, gts5;
                  save_search(gts1,gts2,gts3,gts4,gts5);
                  int nesting=0;
                  int gtstatus=search("(^|<|>)",'-rh@Xs');
                  while (!gtstatus) {
                     if (get_text_safe()=='>') {
                        nesting++;
                     } else if (get_text_safe()=='<') {
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
                  if (gtstatus || get_text_safe()!='<') {
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
               if (ch!=')' && ch!=']') {
                  if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
                     idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST;
                     idexp_info.prefixexp=get_text_safe(end_offset-start_offset+1,start_offset);
                     idexp_info.prefixexpstart_offset=start_offset;
                     //say('prefixexp='idexp_info.prefixexp);
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

                  //say('status='status' p='point('s'));
                  if (status) {
                     restore_pos(orig_pos);
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
                  idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST;
                  if (idexp_info.lastid=='operator') {
                     idexp_info.lastid=get_text_safe(end_offset-start_offset+1,start_offset);
                  } else if (idexp_info.lastid=='return' || idexp_info.lastid=='throw') {
                     idexp_info.prefixexp=get_text_safe(end_offset-start_offset+1,start_offset);
                     idexp_info.lastid="";
                     idexp_info.prefixexpstart_offset=start_offset;
                  } else {
                     // Special handling for new expressions - prefixexp is
                     // already "new Something" in this case.
                     if (pos("^{new|gcnew} ", idexp_info.prefixexp,1, "r")) {                        
                        _str al = substr(idexp_info.prefixexp, 1, lastpos("0"));
                        idexp_info.prefixexp = al:+' ':+idexp_info.lastid:+get_text_safe(end_offset-start_offset+1,start_offset);
                     } else {
                        idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid:+get_text_safe(end_offset-start_offset+1,start_offset);
                        idexp_info.lastid="";
                     }
                  }
                  //say('prefixexp='idexp_info.prefixexp);
                  restore_pos(orig_pos);
                  return(0);
               }
            }
         }

         // check for C++ overloaded operators
         end_col=p_col+1;
         boolean hasOperator = _c_skip_operators_left();

         // character under cursor should be an identifier character
         if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }

         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         
         if (hasOperator && pos("operator", idexp_info.lastid, 1)==1) {
            _str op = strip(substr(idexp_info.lastid,9));
            idexp_info.lastid = 'operator 'op;
         }
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
         if (pos(' 'idexp_info.lastid' ',not_function_words)) {
            restore_pos(orig_pos);
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         if(p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         break;
      case '[':
         idexp_info.info_flags=gInJavadoc_flag|VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         ch=get_text_safe();
         if (ch == ':' && _LanguageInheritsFrom("e")) {
            left();
            ch=get_text_safe();
         }
         search('[~ \t]|^','-rh@');
         end_offset=point('s');
         for (;;) {
            ch=get_text_safe();
            if (ch!=')' && ch!=']') {
               break;
            }
            isBracket := ch == ']';
            if (find_matching_paren(true)) {
               restore_pos(orig_pos);
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            start_offset=point('s');
            // required ][ or ]( to be on same line
            left();
            search('[~ \t]|^','-rh@');
            ch=get_text_safe();
            if (isBracket && ch == ':' && _LanguageInheritsFrom("e")) {
               left();
               ch=get_text_safe();
            }
            if (ch!=')' && ch!=']') {
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
         if (pos(' 'idexp_info.lastid' ',not_function_words)) {
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
      if (ch=='.' || (!isjava && !javascript && ch=='>' && get_text_safe(1,(int)point('s')-1)=='-' ) ) {
         right();
         ch=get_text_safe();
         //lastid='';
         //lastidstart_col=p_col+1;
      } else if (!isjava && !javascript && ch=='-' && get_text_safe(1,(int)point('s')+1)=='>') {
         right();right();
         ch=get_text_safe();
      }
#endif
      boolean done=false;

      if (_chdebug > 9) {
         isay(depth, "_c_get_expression_info: ch1="ch);
      }
      
      if (pos('[~'word_chars']',ch,1,'r')) {

         left();
         ch=get_text_safe();
         if ((ch=='.' && !isphp) ||
             (!isjava && !javascript && ch=='>' && get_text_safe(1,(int)point('s')-1)=='-' ) ||
             ((iscpp || isperl || isidl) && ch==':' && get_text_safe(1,(int)point('s')-1)==':') ||
             (isperl && ch=="'")
            ) {
            idexp_info.lastid='';
            idexp_info.lastidstart_col=p_col+1;
            idexp_info.lastidstart_offset=(int)point('s')+1;
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
            done=true;
         }
         if (ch == '<') {
            // check for #include <>
            save_pos(auto before_lt);
            left();
            gtk=c_prev_sym_same_line();
            if (gtk==TK_ID && (gtkinfo=='include' || gtkinfo=='import' || gtkinfo=='require')) {
               include_info := gtkinfo;
               gtk=c_prev_sym_same_line();
               if (gtk!='#') {
                  restore_pos(orig_pos);
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               restore_pos(before_lt);
               start_col=p_col;
               start_offset=point('s');
               idexp_info.lastidstart_col=start_col+1;
               idexp_info.lastidstart_offset=start_offset+1;
               idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
               idexp_info.lastid='';
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
            if (get_text_safe() == '>') {
               first_non_blank();
               if (get_text_safe() == '#') {
                  restore_pos(before_gt);
                  gtk=c_prev_sym_same_line();
                  if (gtk == "/") {
                     start_col=p_col;
                     start_offset=point('s');
                     idexp_info.lastidstart_col=start_col+2;
                     idexp_info.lastidstart_offset=start_offset+2;
                     idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
                     idexp_info.lastid='';
                     idexp_info.prefixexp='';
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
         boolean foundOperator = _c_skip_operators_left();
         if (!foundOperator && 
             _LanguageInheritsFrom('c') && 
             _clex_find(0,'g') != CFG_COMMENT &&
             pos(get_text_safe(), "~=+-!%^&*[]<>/| ")) { 

            // check for function call operator and other operators
            typeless op_pos;
            save_pos(op_pos);

            // check for the cursor just before the operator with whitespace
            if (get_text_safe()=='' && 
                get_text_safe(2,_nrseek()+1) != "/*" &&
                get_text_safe(2,_nrseek()+1) != "//" &&
                pos(get_text_safe(1,_nrseek()+1), "~=+-!%^&*[]<>/|") 
                /*&& !at_end_of_line()*/) { 
               right();
            }

            // skip forward to grab the rest of the operator
            int operator_end_col=p_col;
            boolean hasArrayOperator=false;
            if (get_text_safe()==']') {
               operator_end_col = p_col;
               find_matching_paren(true);
               left();
               hasArrayOperator=true;
            } else {
               while (pos(get_text_safe(), "=+-!%^&*<>/|") /*&& !at_end_of_line()*/) {
                  if (get_text_safe(2) == '**' ||
                      get_text_safe(2) == '*&' ||
                      get_text_safe(2) == '>&' ||
                      get_text_safe(2) == '*>' ||
                      get_text_safe(2) == '>*') {
                     right();
                     break;
                  }
                  right();
               }
               left();
               operator_end_col = p_col;
               while (p_col > 1 && pos(get_text_safe(), "=+-!%^&*<>/|")) {
                  if (get_text_safe(2,_nrseek()-1) == '**') break;
                  if (get_text_safe(2,_nrseek()-1) == '*&') break;
                  if (get_text_safe(2,_nrseek()-1) == '>&') break;
                  if (get_text_safe(2,_nrseek()-1) == '>*') break;
                  if (get_text_safe(2,_nrseek()-1) == '*>') break;
                  left();
               }
            }

            // get the contents of the operator
            int operator_start_col = p_col+1;
            int operator_start_offset = _nrseek()+1;
            _str c_operator = "";
            if (operator_end_col+1 >= orig_col) {
               c_operator = _expand_tabsc(p_col+1,operator_end_col-p_col);
            }
            if (hasArrayOperator) c_operator = '[]';

            // back up over spaces
            search('^|[~ \t]','@rh-');

            // check for a postfix operator ++ or --
            _str postfix_operator="";
            if (get_text_safe(2,_nrseek()-1) == '++' || get_text_safe(2,_nrseek()-1) == '--') {
               left();
               postfix_operator = get_text_safe(2);
               left();
            }

            // check for an identifier
            int before_status = -1;
            if (c_operator != "" && pos('['word_chars']',get_text_safe(),1,'r') && _clex_find(0,'g') != CFG_PPKEYWORD) {
               // get the expression on the LHS of the operator
               before_status = _c_get_expression_info(false, idexp_info, visited, depth+1);
            } else if (c_operator != "" && pos(get_text_safe(), ")]>")) {
               gtk = c_prev_sym();
               before_status = c_before_dot(isjava, idexp_info);
               if (before_status==2) before_status=0;
            }

            // check for a prefix operator, *, ~, !, or &
            _str prefix_operator = "";
            if (before_status==0 && idexp_info.prefixexpstart_offset>=2) {
               _GoToROffset(idexp_info.prefixexpstart_offset-1);
               while (p_col > 1 && get_text_safe() == " ") left();
               if (pos(get_text_safe(), "*~!&") &&
                   get_text_safe(2,_nrseek()-1) != '>&' &&
                   get_text_safe(2,_nrseek()-1) != '>*' &&
                   get_text_safe(2,_nrseek()-1) != '&&') {
                  prefix_operator = get_text_safe();
                  idexp_info.prefixexpstart_offset=(int)point('s');
               } else if (get_text_safe(2,_nrseek()-1) == '++' || 
                          get_text_safe(2,_nrseek()-1) == '--') {
                  left();
                  prefix_operator = get_text_safe(2);
                  idexp_info.prefixexpstart_offset=(int)point('s');
               }
            }

            // if we found something, then put it all together
            if (before_status==0 && operator_start_col+length(c_operator) > orig_col) {
               idexp_info.prefixexp = '(' prefix_operator :+ idexp_info.prefixexp :+ idexp_info.lastid :+ postfix_operator ').';
               idexp_info.lastid = 'operator 'c_operator;
               if ( gOperatorNameMap._indexin(p_LangId) && gOperatorNameMap:[p_LangId]._indexin(c_operator) ) {
                  idexp_info.lastid = gOperatorNameMap:[p_LangId]:[c_operator];
               }
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
            idexp_info.prefixexp='';
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col;
            idexp_info.lastidstart_offset=(int)point('s');
            idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;

            gtk=c_prev_sym2();
            if (gtk==TK_ID && !isperl && !javascript && !isphp) {
               switch (gtkinfo) {
               case 'goto':
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_GOTO_STATEMENT;
                  break;
               case 'throw':
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_THROW_STATEMENT;
                  break;
               case 'using':
                  if (iscpp || slickc || _LanguageInheritsFrom('cs')) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
                  }
                  break;
               case 'import':
                  if (isjava && !_LanguageInheritsFrom('cs')) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
                  }
                  if (slickc) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
                     gtk=c_prev_sym_same_line();
                     if (gtk=='#') {
                        idexp_info.prefixexp="#import";
                        restore_pos(orig_pos);
                        return 0;
                     } else {
                        gtk=TK_ID;
                        gtkinfo="import";
                     }
                  }
                  break;
               case 'include':
                  if (iscpp || slickc) {
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
                     idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
                     gtk=c_prev_sym_same_line();
                     if (gtk=='#') {
                        idexp_info.prefixexp="#include";
                        restore_pos(orig_pos);
                        return 0;
                     } else {
                        gtk=TK_ID;
                        gtkinfo="include";
                     }
                  }
                  break;
               case 'class':
               case 'struct':
               case 'interface':
               case 'namespace':
               case 'union':
                  idexp_info.info_flags += VSAUTOCODEINFO_HAS_CLASS_SPECIFIER;
                  break;
               default:
                  idexp_info.prefixexp='';
                  break;
               }
            } else if (iscpp && (gtk==':' || gtk==',')) {
               status=parse_constructor_or_initializer(idexp_info.prefixexp,idexp_info.prefixexpstart_offset,
                                                       idexp_info.lastid,idexp_info.lastidstart_offset,
                                                       idexp_info.info_flags,idexp_info.otherinfo,visited,depth+1);
            }
            if (gtk=='#') {
               _clex_skip_blanks('h');
               idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               idexp_info.prefixexp='#';
               idexp_info.prefixexpstart_offset=(int)point('s');
            } else if (gtk=='@' && p_col <= orig_col && p_RLine == orig_line) {
               search("@", "@h");
               idexp_info.prefixexp='@';
               if (_in_comment()) {
                  idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
               } else {
                  idexp_info.info_flags|=VSAUTOCODEINFO_IN_PREPROCESSING;
               }
               idexp_info.prefixexpstart_offset=(int)point('s');
            } else if (gtk=='&' || gtk=='*' || gtk=='^' || gtk=='%') {
               if (get_text_safe(2,_nrseek()+1) != '&&') {
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
            return(0);
         }

         //search('[~'p_word_chars']|$','rh@');
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col=p_col;

         // check if the word under the cursor is "operator"
         int orig_end_col=end_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         start_col=p_col;
         boolean hasOperator = false;
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
         if (get_text_safe()=='(') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         } else if (get_text_safe()=='[') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
            long open_bracket_pos=_QROffset();
            if (!find_matching_paren(true)) {
               long close_bracket_pos=_QROffset();
               idexp_info.otherinfo=get_text_safe((int)(close_bracket_pos-open_bracket_pos-1),(int)(open_bracket_pos+1));
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','\/\/?*[\n\r]','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','^[ \t\n\r]#','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','[ \t\n\r]#$','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,' ','[ \t\n\r][ \t\n\r]#','r');
               idexp_info.otherinfo=stranslate(idexp_info.otherinfo,'','\/\*?*\*\/','r');
            }
            if (idexp_info.otherinfo=='') {
               idexp_info.info_flags&=~VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET;
            }
            _GoToROffset(open_bracket_pos);
         }
         // check if this is NOT a function call
         if (pos(get_text_safe(),'~*&.:{[]}') || // p_col>_text_colc(0,'E') ||
             ((iscpp || isperl || isidl) && get_text_safe(2)=='::') ||
             ((iscpp || slickc || isperl) && get_text_safe(2)=='->')) {
            idexp_info.info_flags|=VSAUTOCODEINFO_NOT_A_FUNCTION_CALL;
         }
         p_col=orig_end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');

         // check if we are on a reference to a destructor, include tilde
         if (get_text_safe(1,_nrseek()-1)=='~') {
            if (pos(get_text_safe(1,_nrseek()-2), ".>:")) {
               // symbol is qualified
               left();
            } else {
               // unqualified, can only be destructor found in class definition
               _UpdateContext(true);

               // make sure that the context doesn't get modified by a background thread.
               se.tags.TaggingGuard sentry;
               sentry.lockContext(false);

               int context_id = tag_current_context();
               if (context_id > 0) {
                  int start_seekpos=0;
                  int context_flags=0;
                  tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, context_flags);
                  if (start_seekpos == _QROffset()-1 && (context_flags & VS_TAGFLAG_destructor)) {
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
            _str op = strip(substr(idexp_info.lastid,9));
            idexp_info.lastid = 'operator 'op;
         }
      }
      //if (slickc && (PossibleOperator && lastid!='p_')
      if (slickc && (PossibleOperator && last_char(idexp_info.lastid)!='_')
          /*||substr(lastid,1,2)!='p_' */
          ) {
         restore_pos(orig_pos);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
   //say("cur_word1 = '"get_text(5)"'");
   idexp_info.prefixexpstart_offset=idexp_info.lastidstart_offset;
   idexp_info.prefixexp='';
   gtk=c_prev_sym2();
   if (_chdebug > 9) {
      isay(depth, "_c_get_expression_info: prevsym="gtk", inf="gtkinfo);
   }
   
   boolean hit_colon_colon=false;
   if (gtk=='::' && iscpp) {
      for (;;) {
         hit_colon_colon=1;
         idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset=(int)point('s')+1;
         gtk=c_prev_sym_same_line();
         if (gtk!=TK_ID || pos(' 'gtkinfo' ',C_NOT_FUNCTION_WORDS,1,'e')) {
            if (gtk=='>') {
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
         if (gtk!='::') {
            break;
         }
      }
   }
   //say("cur_word2 = '"get_text(5)"'");
   if (idexp_info.info_flags& VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
      if (gtk==',' || gtk=='{' || gtk==';' || gtk=='' || gtk=='}' ||
          _skip_template_prefix_word()) {
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
      if (get_text_safe() == '#') {
         restore_pos(orig_pos);
         return 0;
      }
      restore_pos(orig_pos);
   }

   // Skip over preprocessing
   if (gtk == TK_ID && endsWith(gtkinfo, "EXPORT|IMPORT|API", true, "r")) {
      defined_to := "";
      tag_files := tags_filenamea();
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
   _str before_keywords = ' gcnew new goto throw return using import class struct union interface namespace template typename enum ';
   if (slickc) before_keywords :+= "enum_flags _command const ";
   if ((iscpp || slickc) && 
       (gtk==',' || 
        (gtk==TK_ID && !pos(' 'gtkinfo' ',before_keywords)) || 
        (gtk=='&' && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) ||
        (gtk=='*' && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) ||
        (gtk=='&' && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) ||
        (gtk=='*' && (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) ||
        gtk==':' || 
        gtk=='>' )
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
      //messageNwait('p_buf_name='p_buf_name);
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
   isdlang := _LanguageInheritsFrom('d');
   int nesting=0;
   for (;;) {
      prefixexp=gtkinfo:+prefixexp;
      if (gtk=='>' || gtk==')' || gtk==']') {
         ++nesting;
      } else if (gtk=='<' || (isdlang && gtk=='!(')) {
         --nesting;
         if (nesting<=0) {
            prefixexpstart_offset=(int)point('s')+1;
            c_prev_sym2();
            return 0;
         }
      } else if (gtk=='(' || gtk=='[' || gtk==':[') {
         --nesting;
         if (nesting<=0) {
            prefixexp = orig_prefixexp;
            restore_pos(p);
            return 0;
         }
      } else if (gtk==';' || gtk=='{' || gtk=='}' || gtk=='') {
         prefixexp = orig_prefixexp;
         restore_pos(p);
         return 0;
      }  else if (p_RLine+10 < orig_line) {
         prefixexp = orig_prefixexp;
         restore_pos(p);
         return VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT;
      } else if ( gtk=='') {
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
   int status=0;
   boolean check_for_var_decl_or_colon=false;
   prefixexpstart_offset=lastidstart_offset;
outer_loop:
   for (;;) {
      if (gtk=='>') {
         int FunctionNameStartOffset;
         if (!_probablyTemplateArgList(FunctionNameStartOffset)) {
            return(0);
         }
         _str errorArgs[];
         typeless FunctionHelp_list;
         boolean FunctionHelp_list_changed=false;
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
         gtk='>';
         break;
      }
      // IF maybe inializer list case
      if (gtk==':') {
         if (!_LanguageInheritsFrom("c")) {
            return 0;
         }
         typeless colon_paren_pos;
         save_pos(colon_paren_pos);
         c_prev_sym2();
         if (gtk!=')') {
            // We are not in an initializer list
            if (check_for_var_decl_or_colon) {
               restore_pos(colon_paren_pos);gtk=':';
               break outer_loop;
            }
            return(0);
         }
         goto_point((int)point('s')+1);
         status=find_matching_paren(true);
         if (status) {
            // We are not in an initializer list
            if (check_for_var_decl_or_colon) {
               restore_pos(colon_paren_pos);gtk=':';
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
               restore_pos(colon_paren_pos);gtk=':';
               break outer_loop;
            }
            return(0);
         }
         otherinfo=gtkinfo;
         c_prev_sym2();
         if (gtk=='::') {
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
               if (gtk!='::') {
                  break;
               }
            }
            info_flags|=VSAUTOCODEINFO_IN_INITIALIZER_LIST;
            return(0);
         }
         info_flags|=VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST;
         return(0);
      }
      int orig_line=p_RLine;
      for (;;) {
         if (gtk==')') {
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
               if (pos(' 'gtkinfo' ',' catch for if switch throw while ')) {
                  //End of statement
                  restore_pos(close_paren_pos);gtk=')';
                  //refresh();_message_box('c');
                  break outer_loop;
               }
               c_prev_sym2();
            }
         }
         // for (MYCLASS x;...)  OR we are not in a variable declaration.
         if (gtk=='(') {
            typeless open_paren_pos;
            save_pos(open_paren_pos);
            c_prev_sym_same_line();
            if (gtk!=TK_ID || gtkinfo!='for') {
               //restore_pos(open_paren_pos);gtk='(';
               //break outer_loop;
               // This is not a variable declaration.
               return(0);
            }
            restore_pos(open_paren_pos);gtk='(';
            break outer_loop;
         }
         // case ...:  OR default:  OR (exp)? ...: OR    class a:
         if (gtk==':') {
            check_for_var_decl_or_colon=1;
            break;
         }
         // IF we definitely hit end of statement
         if (gtk==';' || gtk=='{' || gtk=='}') {
            c_next_sym();
            break outer_loop;
         }
         if (gtk=='') {
            break outer_loop;
         }
         // IF we are in a #define
         if (_in_c_preprocessing()) {
            down(); _begin_line();
            break outer_loop;
         }
         //if (gtk=='#') {
         //   // We are lost
         //   return(0);
         //}
         // don't back up more than 250 lines
         if (p_RLine < orig_line-250) {
            return(0);
         }
         c_prev_sym2();
      }
   }
   if (gtk!='>') {
      if (gtk!='') {
         if (p_col>_text_colc()) {
            down();_begin_line();
            _clex_skip_blanks('h');
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
   _str classlist=stranslate(strip(prefixexp,'T',':'),':','::');
   _str varname;
   if (classlist=='') {
      varname=lastid'(gvar)';
   } else {
      varname=lastid'('classlist':gvar)';
   }
   boolean utf8=p_UTF8;
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=utf8;
   //xx::yy::y
   //varname=id'('
   _insert_text(text);
   top();
   //_message_box(varname' text='text);
   _str coloncolon='';
   _SetEditorLanguage("c", false);
   status=_VirtualProcSearch(varname);
   if (!status) {
      if (get_text_safe(1,(int)point('s')-1)==':' &&
          get_text_safe(1,(int)point('s')-2)==':'
          ) {
         coloncolon='::';
      }
   }
   _delete_temp_view(temp_view_id);
   if (!status) {
      /*
         A  B(
      */
      //_message_box('Need new tag_decompose_tag code to get return type into otherinfo');
      _str proc_name='';
      _str type_name='';
      _str class_name='';
      _str signature='';
      _str return_type='';
      int tag_flags=0;

      tag_tree_decompose_tag(varname, proc_name, class_name, type_name, tag_flags, signature, return_type);
      info_flags|=VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL;
      if (return_type == "_command") return_type = "";
      if (substr(return_type,1,9) == "_command ") {
         return_type = substr(return_type,10);
      }
      otherinfo=coloncolon:+return_type;
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
 * @return next token or ''
 */
_str c_next_sym()
{
   int status=0;
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   _str ch=get_text_safe();
   if (ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(c_next_sym());
   }
   int start_col=0;
   int start_line=0;
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
   if (ch=='-' && get_text_safe()=='>') {
      right();
      gtk=gtkinfo='->';
      return(gtk);
   }
   if (_LanguageInheritsFrom('d') && ch=='!' && get_text_safe()=='(') {
      right();
      gtk=gtkinfo='!(';
      return(gtk);
   }
   if (_LanguageInheritsFrom('e') && ch==':' && get_text_safe() == '[') {
      gtk=gtkinfo=':[';
      left();
      return(gtk);
   }
   if (ch==':' && get_text_safe()==':') {
      right();
      gtk=gtkinfo='::';
      return(gtk);
   }
   if (ch=='&' && get_text_safe()=='&') {
      right();
      gtk=gtkinfo='&&';
      return(gtk);
   }
   if (ch=='|' && get_text_safe()=='|') {
      right();
      gtk=gtkinfo='||';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
/*
/**
 * Useful utility function for getting the previous token on the
 * same linenext token, symbol, or '' if the previous token is
 * on a different line.
 * <P>
 * This function only always works gInJavadoc_linenum!=0.  Otherwise,
 * this function is somewhat unreliable.
 *
 * @return
 *    previous token or '' if no previous token on current line
 */
*/
static _str c_prev_sym_same_line()
{
   //messageNwait('h0 gtk='gtk);
   if (!gInJavadoc_linenum) {
      if (gtk!='(' && gtk!='::' && gtk!='#') {
         return(c_prev_sym());
      }
      // Only force same line for Slick-C and C++ and InstallScript
      if (!_LanguageInheritsFrom("c") && !_LanguageInheritsFrom('e') && !_LanguageInheritsFrom('rul')) {
         return(c_prev_sym());
      }
   }
   int orig_linenum=(gInJavadoc_linenum) ?gInJavadoc_linenum:p_line;
   _str result=c_prev_sym();
   //messageNwait('h1 gtkinfo='gtkinfo);
   if (p_line == orig_linenum) {
      return result;
   }
   if (p_line == orig_linenum-1 && p_col > _text_colc()) {
      return result;
   }

   //messageNwait('h2');
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
 * @return previous token or ''
 */
_str c_prev_sym()
{
   int status=0;
   _str ch=get_text_safe();
   if (ch=='#' && gInJavadoc_linenum) {
      ch='.';
   }
   if (ch=="\n" || ch=="\r" || ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      if (gInJavadoc_flag) {
         status=search('[~ \t\r\n]','@hr-');
         while (get_text_safe() == '/' && _clex_find(0,'g')==CFG_COMMENT) {
            if(p_col == 1) { 
               up();
               end_line();
            } else {
               left();
            }
            status=search('[~ \t\r\n]','@hr-');
         }
      } else {
         status=_clex_skip_blanks('-h');
      }
      if (status) {
         gtk=gtkinfo='';
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
   if (ch=='#' && p_col==1 && p_line==1 && _LanguageInheritsFrom('c')) {
      up();_end_line();
      gtk=gtkinfo=ch;
      return(gtk);
   }
   if (ch=='@') {
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
         gtk=gtkinfo='::';
      }
      return(gtk);
   }
   left();
   if (ch=='>' && get_text_safe()=='-') {
      left();
      gtk=gtkinfo='->';
      return(gtk);
   }
   if (_LanguageInheritsFrom('d') && ch=='(' && get_text_safe()=='!') {
      left();
      gtk=gtkinfo='!(';
      return(gtk);
   }
   if (_LanguageInheritsFrom('e') && ch==':' && get_text_safe() == '[') {
      gtk=gtkinfo=':[';
      left();
      return(gtk);
   }
   if (_LanguageInheritsFrom('e') && point('s') > 2 && ch=='=' &&
       get_text_safe(1,(int)point('s')-1)==':' &&
       (get_text_safe()=='!' || get_text_safe()=='=')) {
      gtk=gtkinfo=':'get_text_safe()'=';
      left();
      left();
      return(gtk);
   }
   if (ch=='=' && pos(get_text_safe(),'=+!%^*&|/><')) {
      gtk=gtkinfo=get_text_safe()'=';
      left();
      return(gtk);
   }
   if (ch=='&' && get_text_safe() == '&') {
      gtk=gtkinfo='&&';
      left();
      return(gtk);
   }
   if (ch=='|' && get_text_safe() == '|') {
      gtk=gtkinfo='||';
      left();
      return(gtk);
   }
   if (ch=='<' && get_text_safe() == '<') {
      gtk=gtkinfo='<<';
      left();
      return(gtk);
   }
   if (ch=='>' && get_text_safe() == '>') {
      gtk=gtkinfo='>>';
      left();
      return(gtk);
   }
   if (ch=='=' && pos(get_text_safe(),'=+!%^*&|/><')) {
      gtk=gtkinfo=get_text_safe()'=';
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
      gtk=gtkinfo='::';
      return(gtk);
   }
   if (ch==':' && get_text_safe()==':') {
      left();
      gtk=gtkinfo='::';
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
   if (get_text() != '=') {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }

   // skip over the assignment operator
   prev_char();
   if (get_text() == ':') left(); 
   _clex_skip_blanks('-h');

   // now check for array type declarator
   gtk=c_prev_sym2();
   while (gtk==']' && get_text()=='[') {
      left();
      if (_LanguageInheritsFrom('e') && get_text()==':') left();
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
 * Call with the buffer position on the ']' of 
 * an array index operator.  (ie, somarr[x+1]) 
 * 
 * @param status 0 on success, otherwise returns a 
 *               VSCODEHELPRC_* error.
 * 
 * @return _str Returns the expression inside of the [], minus 
 *         any comments.
 */
_str _c_get_index_expression(int& status) 
{
   long right_idx = _QROffset();

   right();

   int rc = find_matching_paren(true);

   if (rc) {
      status = VSCODEHELPRC_CONTEXT_NOT_VALID;
      return '';
   }

   long left_idx = _QROffset();

   _str rv = get_text_safe((int)(right_idx - left_idx), (int)left_idx+1);

   rv=stranslate(rv,'','\/\/?*[\n\r]','r');
   rv=stranslate(rv,'','[ \t\n\r]#','r');
   rv=stranslate(rv,'','\/\*?*\*\/','r');

   if (rv == '') {
      status = VSCODEHELPRC_CONTEXT_NOT_VALID;
      return rv;
   }

   status = 0;
   return rv;
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
static int c_before_dot(boolean isjava, VS_TAG_IDEXP_INFO &idexp_info)
{
   int status=0;
   _str i_expr;

outer_loop:
   for (;;) {
      idexp_info.prefixexpstart_offset = (int)point('s')+1;
      switch (gtk) {
      case ']':
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
         if (_LanguageInheritsFrom('e') && gtk==':') {
            idexp_info.prefixexp = ':':+idexp_info.prefixexp;
            gtk=c_prev_sym2();
         }
         if (_LanguageInheritsFrom('e') && gtk=='->') {
            idexp_info.prefixexp = '->':+idexp_info.prefixexp;
            gtk=c_prev_sym2();
         }
         if (gtk!=']') {
            if (gtk!=TK_ID) {
               if (gtk==')') {
                  continue;
               }
               if (gtk==',' || gtk=='{') {
                  continue;
               }
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
            if (isjava && gtkinfo=='new') {
               idexp_info.prefixexp = 'new ':+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               gtk=c_prev_sym2();
            }
            return(2);  // continue
         }
         break;
      case ')':
         int nest_level=0;
         int count;
         for (count=0;;++count) {
            if (count>200) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk:=='') {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk==']') {
               i_expr = '';
               if (_LanguageInheritsFrom('m')) {
                  status = _objectivec_get_bracket_expression(i_expr);
                  if (!status) {
                     idexp_info.prefixexp = i_expr:+idexp_info.prefixexp;
                     gtk=c_prev_sym_same_line();
                  }
               } 

               if (i_expr == '') {
                  idexp_info.prefixexp = '[]':+idexp_info.prefixexp;
                  right();
                  status=find_matching_paren(true);
                  if (status) {
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
                  }
                  left();
               }

            } else {
               if (gtk==TK_ID) {
                  idexp_info.prefixexp = gtkinfo' ':+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               }
            }
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            if (gtk=='(' || gtk=='!(') {
               --nest_level;
               if (nest_level<=0) {
                  gtk=c_prev_sym_same_line();
                  if (gtk!=TK_ID) {

                     if (gtk==']') {
                        continue outer_loop;
                     }
                     if (gtk==')') {
                        continue;
                     }
                     if (gtk=='>') {
                        continue outer_loop;
                     }
                     if (gtk=='') {
                        return(0);
                     }
                     return(0);
                  }
                  if (pos(' 'gtkinfo' ',' if elsif elseif while catch switch ')) {
                     return 0;
                  }
                  idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
                  idexp_info.prefixexpstart_offset = (int)point('s')+1;
                  gtk=c_prev_sym_same_line();
                  if (isjava && gtkinfo=='new') {
                     idexp_info.prefixexp = 'new ':+idexp_info.prefixexp;
                     idexp_info.prefixexpstart_offset = (int)point('s')+1;
                     gtk=c_prev_sym2();
                  }
                  return(2);// Tell call to continue processing
               }
            } else if (gtk==')') {
               ++nest_level;
            }
            gtk=c_prev_sym2();
         }
         break;
      case '>':
         if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs')) {
            if (add_template_args(idexp_info.prefixexp,idexp_info.prefixexpstart_offset) != 0 || gtk!=TK_ID) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
            right();
            _clex_skip_blanks('h');
            idexp_info.prefixexpstart_offset = (int)point('s');
            _clex_skip_blanks('h-');
            gtk=c_prev_sym2();
            if (isjava && gtkinfo=='new') {
               idexp_info.prefixexp = 'new ':+idexp_info.prefixexp;
               _clex_skip_blanks('h');
               idexp_info.prefixexpstart_offset = (int)point('s');
               _clex_skip_blanks('h-');
               gtk=c_prev_sym2();
            }
            return(2);  // continue
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case ',':
         // this may be a C99 style designated struct initializer
         // first, move to the corresponding open brace
         if (idexp_info.prefixexp != "" && first_char(idexp_info.prefixexp) != ".") {
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
         if (get_text() == '{') {
            return c_before_struct_initializer(idexp_info.prefixexp);
         }
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      case '{':
         // this may be a C99 style designated struct initializer
         if (idexp_info.prefixexp != "" && first_char(idexp_info.prefixexp) != ".") {
            right();right();
            _clex_skip_blanks('h');
            idexp_info.prefixexpstart_offset = (int)point('s');
            return 0;
         }
         return c_before_struct_initializer(idexp_info.prefixexp);
      default:
         if (_LanguageInheritsFrom('d')) {
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
static int c_before_id(boolean isjava, _str &not_function_words,
                       VS_TAG_IDEXP_INFO &idexp_info, int depth=0)
{
   if (_chdebug > 9) {
      isay(depth, "c_before_id: isjava="isjava" lastid="idexp_info.lastid);
   }
   
   int status=0;
   for (;;) {
      if (_chdebug > 9) {
         isay(depth, "c_before_id: gtk="gtk", info="gtkinfo);
      }
      switch (gtk) {
      case '*':
      case '&':
      case '^':
         idexp_info.info_flags |= VSAUTOCODEINFO_HAS_REF_OPERATOR;
         idexp_info.otherinfo = gtk;
         return(0);
      case '#':
         _clex_skip_blanks('h');
         int pound_offset=(int)point('s');
         if (idexp_info.prefixexp=='') {
            idexp_info.prefixexp='#';
            idexp_info.prefixexpstart_offset = pound_offset;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
         }
         return(0);
      case '@':
         search("@","@h");
         int at_offset=(int)point('s');
         idexp_info.prefixexp = '@':+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset = at_offset;
         if (_in_comment()) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         } else {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
         }
         return(0);
      case '->':
         if (isjava) {
            return(0);
         }
         // Fall thru intentional
      case '.':
         // "." is used for string concatentation in Perl and PHP, not member access
         if (gtk == '.' && (_LanguageInheritsFrom("pl") || _LanguageInheritsFrom("phpscript"))) {
            return(0);
         }
         idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset = (int)point('s')+1;
         gtk=c_prev_sym2();
         if (gtk!=TK_ID) {
            if (gtk=='' && gInJavadoc_linenum) {
               //prefixexp=orig_prefixexp;
               if (_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('d')) {
                  idexp_info.prefixexp = '(*this)':+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp = 'this':+idexp_info.prefixexp;
               }
               return(0);
            }
            status=c_before_dot(isjava,idexp_info);
            if (status < 0) {
               return(status);
            }
         } else {
            boolean isBuiltinType = false;
            if (_LanguageInheritsFrom('d') && _c_is_builtin_type(gtkinfo)) {
               isBuiltinType = true;
            }
            if (!isBuiltinType && pos(' 'gtkinfo' ',not_function_words,1,'e')) {
               return(0);
            }
            if (gInJavadoc_linenum && gtkinfo=='see' &&
                get_text_safe()=='@') {
               //prefixexp=orig_prefixexp;
               if (_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('d')) {
                  idexp_info.prefixexp='(*this)':+idexp_info.prefixexp;
               } else {
                  idexp_info.prefixexp='this':+idexp_info.prefixexp;
               }
               return(0);
            }
            idexp_info.prefixexp=gtkinfo:+idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
         }
         break;
      case '::':
         if (!isjava) {
            for (;;) {
               idexp_info.prefixexp = gtkinfo:+idexp_info.prefixexp;
               idexp_info.prefixexpstart_offset = (int)point('s')+1;
               gtk=c_prev_sym_same_line();
               if (gtk!=TK_ID || pos(' 'gtkinfo' ',not_function_words,1,'e')) {
                  if (gtk=='<') {
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
               if (gtk!='::') {
                  return(0);
               }
            }
         }
         return(0);
      case '<':
         // check for #include <>
         save_pos(auto before_lt);
         left();
         gtk=c_prev_sym_same_line();
         if (gtk==TK_ID && (gtkinfo=='include' || gtkinfo=='import' || gtkinfo=='require')) {
            include_info := gtkinfo;
            gtk=c_prev_sym_same_line();
            if (gtk!='#') {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            restore_pos(before_lt);
            typeless start_col=p_col;
            typeless start_offset=point('s');
            if (idexp_info.prefixexp != '') {
               idexp_info.lastid = idexp_info.prefixexp:+idexp_info.lastid;
               idexp_info.lastidstart_offset = idexp_info.prefixexpstart_offset;
               idexp_info.lastidstart_col -= length(idexp_info.prefixexp);
            }
            idexp_info.prefixexpstart_offset = start_offset+1;
            idexp_info.prefixexp="#"include_info;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING;
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_PREPROCESSING_ARGS;
            return 0;
         }
         restore_pos(before_lt);
         return(0);
      case '/':
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
            if (gtk!='/') break;
         }
         // go handle include case
         if (gtk=='<') {
            continue;
         }
         idexp_info.prefixexp = orig_prefixexp;
         idexp_info.prefixexpstart_offset = orig_prefixexpstart_offset;
         restore_pos(before_slash);
         return(0);

      case TK_ID:
         if (gtkinfo=='new' || gtkinfo=='gcnew') {
            idexp_info.prefixexp = gtkinfo' 'idexp_info.prefixexp;
            idexp_info.prefixexpstart_offset = (int)point('s')+1;
            gtk=c_prev_sym2();
            if (_chdebug > 9) {
               isay(depth, "c_before_id: new prefixexp: '"idexp_info.prefixexp"', left_of_new "gtk", "gtkinfo);
            }
            if (!isjava || gtk!='.') {
               return(0);
            }
            continue;
         } else if (gtkinfo=='goto') {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
         } else if (gtkinfo=='throw') {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_THROW_STATEMENT;
         } else if (gtkinfo=='import' && isjava && !_LanguageInheritsFrom('cs')) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
         } else if (gtkinfo=='using' && (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs'))) {
            idexp_info.info_flags |= VSAUTOCODEINFO_IN_IMPORT_STATEMENT;
         } else if (gtkinfo=='class' || gtkinfo=='struct' ||
                    gtkinfo=='union' || gtkinfo=='interface' ||
                    (gtkinfo=='namespace' && _LanguageInheritsFrom('c'))) {
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
      parse return_type with s1 '?' +0 s2;
      if (s2=='') {
         return;
      }
      return_type='System.Nullable<'s1'>':+substr(s2,2);
   }
}

/**
 * Substitute actual template parameters for the template parameters
 * found in the template class's template signature.
 * 
 * @param search_class_name     class we are searching from matches within
 * @param file_name             file containing matches
 * @param isjava                is this Java or Java-like source?
 * @param template_parms        List of actual template arguments (may be empty)
 * @param template_sig          Template signature from template class
 * @param template_args         [output] hash table of template arguments
 * @param template_names        [output] ordered array of template argument names 
 * @param template_class_name   [input] name of template class 
 * @param template_file         [input] name of file template class comes from
 * @param tag_files             array of tag files
 * @param visited               [reference] problems already solved
 * @param depth                 depth of recursive search
 */
static void _c_substitute_template_args( _str search_class_name, _str file_name, boolean isjava,
                                         _str (&template_parms)[], _str template_sig,
                                         _str (&template_args):[], _str (&template_names)[],
                                         VS_TAG_RETURN_TYPE (&template_types):[],
                                         _str template_class_name, _str template_file,
                                         typeless tag_files, VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth,"_c_substutite_template_args: ===================================================");
      isay(depth,"_c_substitute_template_args: class="search_class_name" sig="template_sig" num_param="template_parms._length());

      VS_TAG_RETURN_TYPE tmp_rt;
      tag_return_type_init(tmp_rt);
      tmp_rt.istemplate = true;
      tmp_rt.template_args  = template_args;
      tmp_rt.template_names = template_names;
      tmp_rt.template_types = template_types;
      tag_return_type_dump(tmp_rt, "_c_substitute_template_args", depth);
   }

   // save the original template arguments (from the context of the template ID)
   int num_template_parms = template_parms._length();
   _str orig_template_args:[];
   _str orig_template_names[];
   VS_TAG_RETURN_TYPE orig_template_types:[];
   orig_template_args  = template_args;
   orig_template_names = template_names;
   orig_template_types = template_types;

   // initialize the "output" template argument lists we are building
   template_args._makeempty();
   template_names._makeempty();
   template_types._makeempty();

   _str id='';
   int i=0, arg_pos = 0;
   _str argument = '';
   tag_get_next_argument(template_sig, arg_pos, argument);
   while (argument != '') {
      // just keep the last word of the argument string (kludge)
      if (_chdebug) {
         isay(depth,"_c_substitute_template_args: cb_next_arg returns "argument" arg_pos="arg_pos" sig="template_sig);
      }

      for (;;) {
         int p = pos('^ @{:v|'_clex_identifier_re()'|?}', argument, 1, 'r');
         int n = pos('0');
         if (argument=='' || !p) {
            if (i >= template_parms._length()) {
               template_parms[i]=id;
            }
            break;
         }
         p = pos('S0');
         id = substr(argument, p, n);
         argument = substr(argument, p+n);
         //isay(depth, "_c_substitute_template_args: ID="id" ARG="argument);
         if (pos(' *=',argument,1,'r')==1) {
            //isay(depth, "_c_substitute_template_args: argument="substr(argument, pos('')+1)" len="template_parms._length()" i="i);
            if (i >= template_parms._length()) {
               template_parms[i] = substr(argument, pos('')+1);
            }
            argument='';
         } else if (pos(' *extends ',argument,1,'r')==1) {
            //isay(depth, "_c_substitute_template_args: argument=" substr(argument, pos('')+1)" len="template_parms._length()" i="i);
            if (i >= template_parms._length()) {
               template_parms[i] = substr(argument, pos('')+1);
            }
            argument='';
         } else if (i >= template_parms._length() && _LanguageInheritsFrom('java')) {
            template_parms[i]="java.lang.Object";
         }
      }
      //isay(depth,"_c_substitute_template_args: argument="argument);
      if (i < template_parms._length()) {
         //isay(depth, "_c_substitute_template_args["i"]: TEMPLATE ARG: "id"-->"template_parms[i]);
         template_search_class_name := "";
         template_file_name := "";
         VS_TAG_RETURN_TYPE rt_arg;tag_return_type_init(rt_arg);
         if (i < num_template_parms) {
            rt_arg.template_args=orig_template_args;
            rt_arg.template_names=orig_template_names;
            rt_arg.template_types=orig_template_types;
            template_search_class_name=search_class_name;
            template_file_name=file_name;
         } else {
            rt_arg.template_args=template_args;
            rt_arg.template_names=template_names;
            rt_arg.template_types=template_types;
            template_search_class_name = template_class_name;
            template_file_name = template_file;
         }
         rt_arg.istemplate=true;

         int status=0;
         _str errorArgs[];

         //isay(depth, "_c_substitute_template_args: search_class="search_class_name" file="file_name);
         if (_LanguageInheritsFrom('java')) {
            template_parms[i] = strip(template_parms[i]);
            if (template_parms[i]=='?') {
               template_parms[i]='java.lang.Object';
            }
            if (substr(template_parms[i],1,1)=='?') {
               _str extends_kw='';
               _str rest='';
               parse template_parms[i] with "?" extends_kw rest;
               if (extends_kw=='extends') {
                  template_parms[i] = strip(rest);
               }
            }
         }

         if (template_parms[i] != '') {

            tag_push_matches();
            status = _c_parse_return_type(errorArgs, tag_files,
                                          '', template_search_class_name,
                                          template_file_name, template_parms[i],
                                          isjava, rt_arg,
                                          visited, depth+1);

            _str rt_arg_string = rt_arg.return_type;
            if (rt_arg.istemplate) {
               strappend(rt_arg_string,"<");
               int j=0;
               for (j=0; j<rt_arg.template_names._length(); ++j) {
                  _str el = rt_arg.template_names[j];
                  if (j > 0) strappend(rt_arg_string,",");
                  if (template_args._indexin(el)) {
                     strappend(rt_arg_string,template_args:[el]);
                  } else {
                     strappend(rt_arg_string,rt_arg.template_args:[el]);
                  }
               }
               strappend(rt_arg_string,">");
            }

            if (_chdebug) {
               isay(depth,"_c_substitute_template_args: rt_string="rt_arg_string);
               tag_return_type_dump(rt_arg,"_c_substitute_template_args(AFTER)",depth);
            }

            tag_pop_matches();
         }

         if (!template_args._indexin(id)) {
            template_names[template_names._length()] = id;
         }
         if (status==VSCODEHELPRC_BUILTIN_TYPE) status=0;
         if (!status && rt_arg.return_type!='') {
            _str arg_return_type = tag_return_type_string(rt_arg, false);
            if (isjava) {
               arg_return_type = stranslate(arg_return_type,'.',':');
               arg_return_type = stranslate(arg_return_type,'.','/');
            } else {
               arg_return_type = stranslate(arg_return_type,'::',':') :+ substr('',1,rt_arg.pointer_count,'*');
            }
            template_args:[id] = arg_return_type;
            template_types:[id] = rt_arg;

         } else {
            //isay(depth,"_c_substitute_template_args: status="status" return_type="rt_arg.return_type);
            template_args:[id] = template_parms[i];
         }
      }
      tag_get_next_argument(template_sig, arg_pos, argument);
      ++i;
   }
}

/**
 * Look for inherited template arguments.  See example.
 * <pre>
 *    class A {
 *       int x,y,z;
 *    };
 *    template&lt;typename T&gt; class B {
 *    public:
 *       T* create();
 *    };
 *    class C: public B&lt;A&gt; {
 *    };
 *    void foobar(C* x) {
 *       x->create()->z;
 *    }
 * </pre>
 * 
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param tag_class_name     class that the the tag was found in
 * @param search_class_name  derived class
 * @param file_name          where is the tag's class defined
 * @param rt                 return_type to add template argumetns to
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 * 
 * @return 0
 */
static int _c_get_inherited_template_args(_str (&errorArgs)[], 
                                          typeless tag_files,
                                          _str tag_class_name, 
                                          _str search_class_name, 
                                          _str file_name,
                                          struct VS_TAG_RETURN_TYPE &rt,
                                          VS_TAG_RETURN_TYPE (&visited):[], 
                                          int depth=0)
{
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: tag_class="tag_class_name" search_class="search_class_name);
      tag_return_type_dump(rt, "_c_get_inherited_template_args", depth);
   }

   // stop if this has gone too far
   if (depth > VSCODEHELP_MAXRECURSIVETYPESEARCH) {
      return 1;
   }

   // make sure that there is a derivation relationship
   if (tag_class_name == '' || search_class_name=='') {
      return 1;
   }
   if (!tag_is_parent_class(tag_class_name, search_class_name,
                            tag_files, true, true, 
                            file_name, visited, depth)) {
      return 1;
   }

   // get this classes's parents
   _str in_tag_files = '';
   _str parents = cb_get_normalized_inheritance(search_class_name, in_tag_files, tag_files, true, "", "", "", true);
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: parents="parents);
   }

   // for each parent
   while (parents != '') {

      // get the parent class, this may include template arguments
      _str parent_class = '';
      parse parents with parent_class VS_TAGSEPARATOR_parents parents;

      // strip off the template arguments
      _str parent_no_templates = parent_class;
      if (_LanguageInheritsFrom('d')) {
         parse parent_no_templates with parent_no_templates '!(';
      } else {
         parse parent_no_templates with parent_no_templates '<';
      }

      // split the class name
      _str template_inner='', template_outer='';
      tag_split_class_name(parent_no_templates, template_inner, template_outer);

      // parse the parent class as a return type to evaluate everything
      VS_TAG_RETURN_TYPE parent_rt;
      tag_return_type_init(parent_rt);
      parent_rt.template_args  = rt.template_args;
      parent_rt.template_names = rt.template_names;
      parent_rt.template_types = rt.template_types;
      int status = _c_parse_return_type(errorArgs, tag_files, 
                                        template_inner, search_class_name,
                                        file_name, parent_class, 
                                        false, parent_rt, 
                                        visited, depth+1);
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: status="status);
         tag_return_type_dump(parent_rt, "_c_get_inherited_template_args", depth);
      }

      // if successful, transfer the template arguments and quit
      if (!status && parent_rt.return_type == tag_class_name) {
         if (parent_rt.istemplate) {
            rt.template_args  = parent_rt.template_args;
            rt.template_names = parent_rt.template_names;
            rt.template_types = parent_rt.template_types;
            rt.istemplate = true;
         }
         return 0;
      }

      // recursively attempt to get the parents of this parent
      status = _c_get_inherited_template_args(errorArgs, tag_files,
                                              tag_class_name, parent_no_templates, file_name,
                                              parent_rt, visited, depth+1);
      if (!status) {
         rt = parent_rt;
         return 0;
      }
   }

   // no luck
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: NO TEMPLATE ARGS FOUND");
   }
   return 1;
}

// check if this return type uses "auto" for type inference
// 
//    a := 4;     // Java, Slick-C
//    auto b = 3; // C++, Slick-C
//    var c = 2;  // C#
// 
static boolean isTypeInferred(_str return_type, boolean &add_const=1)
{
   // language independent initializer based type inference 
   if (substr(return_type, 1, 1) == '=') {
      return true;
   }

   // type inference only supported for C++, Slick-C, and C#
   if (!_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('e') && !_LanguageInheritsFrom('cs')) {
      return false;
   }

   // Slick-C auto type inferred declarations
   // Get the type from the RHS of the expression.
   boolean found_auto=false;
   while (return_type != '') {

      // strip leading spaces
      if (substr(return_type, 1, 1) :== ' ') {
         return_type = strip(return_type);
         continue;
      }

      // strip leading 'const' keyword
      if (length(return_type)>=6 && 
          substr(return_type, 1, 5)=='const' && 
          !isid_valid(substr(return_type, 6, 1))) {
         add_const=true;
         return_type = substr(return_type, 6);
         continue;
      }

      // strip * or & (pointer or reference)
      first_ch := substr(return_type,1,1);
      if (first_ch=='*' || first_ch=='&' || first_ch=='^' || first_ch=='%') {
         return_type = substr(return_type, 2);
         continue;
      }

      // strip [] (array args)
      if (substr(return_type, 1, 1)=='[') {
         int num_args=0;
         if (!match_brackets(return_type, num_args)) return false;
         continue;
      }

      // check for auto keyword
      if (length(return_type)>=5 && 
          substr(return_type, 1, 4)=='auto' && 
          !isid_valid(substr(return_type, 5, 1))) {
         found_auto=true;
         return_type = substr(return_type, 5);
         continue;
      }

      // check for C# var keyword
      if (_LanguageInheritsFrom('cs') &&
          length(return_type)>=4 && 
          substr(return_type, 1, 3)=='var' && 
          !isid_valid(substr(return_type, 4, 1))) {
         found_auto=true;
         return_type = substr(return_type, 4);
         continue;
      }

      // check for initializer expression
      if (substr(return_type, 1, 1)=='=' || substr(return_type,1,2)==':=') {
         return found_auto;
      }

      // if we see anything else, we are out of here
      return false;
   }

   // May have found "auto", but did not find initializer
   return false;
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
                         _str file_name, _str return_type, boolean isjava,
                         struct VS_TAG_RETURN_TYPE &rt,
                         VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth,"_c_parse_return_type: ==============================================================");
      isay(depth,"_c_parse_return_type(symbol="symbol", search_class="search_class_name", return_type="return_type","file_name","depth")");
   }

   // filter out mutual recursion
   _str input_args='parse;'symbol';'search_class_name';'file_name';'return_type';'p_buf_name';'tag_return_type_string(rt);
   int status = _CodeHelpCheckVisited(input_args, "_c_parse_return_type", rt, visited, depth);
   if (!status) {
      if (_chdebug) {
         tag_return_type_dump(rt,"_c_parse_return_type: SHORTCUT SUCCESS",depth);
      }
      return 0;
   }
   if (status < 0) {
      errorArgs[1]=symbol != ""? symbol : return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // locals
   int num_args=0;
   boolean found_seperator = false;
   _str orig_return_type = return_type;
   _str orig_search_class = search_class_name;
   _str template_sig='';
   VS_TAG_RETURN_TYPE orig_rt = rt;
   tag_return_type_init(rt);
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

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
   if (_LanguageInheritsFrom('cs') && pos('?',return_type)) {
      _xlat_csharp_shorthand_nullable(return_type);
   }

   // Slick-C type inferred declarations
   //    b := 3;
   //    auto b = 3;
   // Get the type of the RHS of the expression.
   //
   if (isTypeInferred(return_type, auto add_const=false)) {
      parse return_type with . '=' return_type;
      boolean doInferredLookup=true;
      if (_LanguageInheritsFrom('py')) {
         _str ch1=substr(return_type,1,1);
         if (ch1=='[') {
            return_type='PyList';
            doInferredLookup=false;
         } else if (ch1=='{') {
            // This will get confused if a string contains a colon or a comma
            int i=pos('[:,]',return_type,1,'r');
            boolean hit_colon=false;
            if (i && substr(return_type,i,1)==':') {
               hit_colon=true;
            }
            if (return_type=='{}' || return_type=='{ }' || hit_colon) {
               return_type='PyDictionary';
            } else {
               return_type='PySet';
            }
            doInferredLookup=false;
         } else if (ch1=='(') {
            return_type='PyTuple';
            doInferredLookup=false;
         } else if (ch1=='"' || ch1=="'" || 
                    ( (strieq(ch1,'r') || strieq(ch1,'u')) && 
                      (substr(return_type,2,1)=='"' || substr(return_type,2,1)=="'")
                    ) ||
                    ( strieq(substr(return_type,1,2),'ur') &&
                      (substr(return_type,3,1)=='"' || substr(return_type,3,1)=="'")
                    )
                    ) {
            strip(return_type,'L','u');
            return_type='PyString';
            doInferredLookup=false;
         } else if (ch1=='"' || ch1=="'" || 
                    ( (strieq(ch1,'b')) && 
                      (substr(return_type,2,1)=='"' || substr(return_type,2,1)=="'")
                    ) 
                   ) {
            strip(return_type,'L','u');
            return_type='PyBytes';
            doInferredLookup=false;
         /*} else if (isdigit(ch1)) {
            return_type='PyObject';
            doInferredLookup=false;*/
         }
      }
      if (doInferredLookup) {
         status = _c_get_type_of_expression(errorArgs, tag_files,
                                            return_type, rt, 
                                            visited, depth+1);
         if (add_const) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (_chdebug) {
            tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
         }
         if (_LanguageInheritsFrom('py') && (status || rt.return_type=='')) {
            return_type='PyObject';
            status = _c_get_type_of_expression(errorArgs, tag_files,
                                               return_type, rt, 
                                               visited, depth+1);
            if (add_const) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (_chdebug) {
               tag_return_type_dump(rt,"_c_parse_return_type: INFERRED",depth);
            }
         }
         return status;
      }
   }

   int loopCount = 0;
   _str ch='', prev_ch = '', next_ch=''; 
   _str notparen=_LanguageInheritsFrom('d')? '|\!\(':'';
   _str ch_re = '^ @{\:\:|\:|\/|\.\.\.|\:\[|\[|\]'notparen'|[.<>*&()\^]|:v|'_clex_identifier_re()'|\@:i:v|\@:i}';

   while (return_type != '') {

      // evaluating a prefix should not take more than 20 iterations
      loopCount++;
      if (loopCount > 20) {
         //isay(depth, "_c_parse_return_type: BREAKING ENDLESS LOOP return_type="return_type);
         break;
      }

      // if the return type is simply a builtin, then stop here
      if (_c_is_builtin_type(strip(return_type)) && 
          rt.return_type=='' && rt.pointer_count==0 && 
          !_LanguageInheritsFrom('cs') && 
          !_LanguageInheritsFrom('d')) {
         //isay(depth, "_c_parse_return_type: BUILTIN");
         rt.return_type = strip(return_type);
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         if (_c_is_builtin_type(rt.return_type,true)) {
            visited:[input_args]=rt;
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: BUILTIN TYPE");
            }
            return 0;
         }
         errorArgs[1] = rt.return_type;
         errorArgs[2] = orig_return_type;
         return VSCODEHELPRC_BUILTIN_TYPE;
      }

      // parse the next token off of the return type
      if (pos(ch_re, return_type, 1, 'r') <= 0) {
         break;
      }
      prev_ch = ch;
      ch = substr(return_type, pos('S0'), pos('0'));
      return_type = substr(return_type, pos('S0')+pos('0'));

      // get the next, next token from the return type
      if (pos(ch_re, return_type, 1, 'r') <= 0) {
         next_ch = '';
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
      case '::':
      case '/':
         search_class_name = rt.return_type;
         found_seperator = true;
         if (rt.return_type == '') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         }
         break;

      // member access or tag database class separator
      case '.':
      case ':':
         search_class_name = rt.return_type;
         found_seperator = true;
         if (ch=='.' && _LanguageInheritsFrom('d') && rt.return_type == '') {
            tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                    auto cur_type_name, auto cur_type_id, 
                                    auto cur_context, auto cur_class, auto cur_package);
            rt.return_type = cur_package;
            search_class_name = cur_package; 
         }
         break;

      // increment the number of pointers
      case '*':
      case '^':
         if (rt.return_type != '') {
            rt.pointer_count++;
         }
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: PARSE("ch") pointer_count="rt.pointer_count);
         }
         break;

      // as far as our analysis cares, references are just like values
      case '&':
      case '%':
         if (rt.return_type != '') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
         }
         break;

      // Slick-C hash table
      case ':[':
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
      case '[':
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         if (_LanguageInheritsFrom('rul') && rt.return_type=='STRING' && rt.pointer_count==0) {
            // the array just indicates the array size
         } else {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
            rt.pointer_count++;
         }
         if (_chdebug) {
            isay(depth, "_c_parse_return_type: PARSE[], pointer_count="rt.pointer_count);
         }
         break;

      // closing bracket, ignore it
      case ']':
         break;

      // Java 5 variable length argument lists, final argument is really array
      case '...':
         if (_LanguageInheritsFrom('java')) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
            rt.pointer_count++;
         }
         break;

      // function call, #define, or cast
      case '(':
         _str parenexp='';
         if (!match_parens(return_type, parenexp, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         // verify that array arguments within parens all match
         while (pos('[', parenexp)) {
            parenexp = substr(parenexp, pos('S')+1);
            if (!match_brackets(parenexp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            rt.pointer_count++;
         }
         // this is a pointer to array
         if (next_ch == '[' || next_ch == ':[') {
            while (pos('*', parenexp)) {
               parenexp = substr(parenexp, pos('S')+1);
               rt.pointer_count++;
            }
         }
         break;

      // closing parenthesis, ignore it
      case ')':
         break;

      // template arguments
      case '<':
      case '!(':
         // first try to match leading < with > for template arguments
         _str template_parms[];
         template_parms._makeempty();
         if (!match_templates(return_type, template_parms)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH;
         }
         // look up specialized template
         _str template_class_name = rt.return_type;
         _str template_args=join(template_parms,',');
         _str template_inner='', template_outer='';
         tag_split_class_name(rt.return_type, template_inner, template_outer);
         specialized := tag_check_for_template(template_inner:+"<"template_args">", template_outer, true, tag_files, template_sig);
         if (specialized) {
            template_rt := rt;
            status = _c_get_return_type_of(errorArgs, tag_files, 
                                           template_inner"<"template_args">",
                                           template_outer, 0, isjava,
                                           VS_TAGFILTER_ANYTHING, 
                                           true, false, template_rt, 
                                           visited, depth+1);
            if (status == 0) {
               rt = template_rt;
            } else {
               specialized=0;
            }
         }
         // now look up just the class, is it a template?
         if (!specialized && !tag_check_for_template(template_inner, template_outer, true, tag_files, template_sig)) {
            errorArgs[1] = rt.return_type;
            return VSCODEHELPRC_NOT_A_TEMPLATE_CLASS;
         }
         if (_chdebug) {
            isay(depth,"_c_parse_return_type: CLASS="rt.return_type" TEMPLATE_SIG="template_sig);
            isay(depth,"_c_parse_return_type: CLASS="rt.return_type" TEMPLATE_ARGS="template_args);
            tag_return_type_dump(rt, "_c_parse_return_type: TEMPLATE rt", depth);
            tag_return_type_dump(orig_rt, "_c_parse_return_type: TEMPLATE orig_rt", depth);
         }
         // now create hash table of formal params to actual
         rt.istemplate = true;
         if (rt.return_type :!= search_class_name) {

            // transfer template arguments
            rt.template_args  = orig_rt.template_args;
            rt.template_names = orig_rt.template_names;
            rt.template_types = orig_rt.template_types;

            _c_substitute_template_args(orig_search_class, file_name, isjava, 
                                        template_parms, template_sig,
                                        rt.template_args, rt.template_names, rt.template_types,
                                        template_class_name, "",
                                        tag_files, visited, depth+1);
            if (_chdebug) {
               tag_return_type_dump(rt, "_c_parse_return_type: TEMPLATE ARGS", depth);
            }
         }
         break;

      // closing template arguments, ignore it
      case '>':
         break;

      // all keywords need to drop through to the identifier case if
      // they do not apply to the current language
      case 'const':
      case 'volatile':
      case 'restrict':
      case 'extern':
      case 'struct':
      case 'class':
      case 'interface':
      case 'union':
      case 'typename':
         if (!_LanguageInheritsFrom('rul') && !_LanguageInheritsFrom('cs')) {
            if (ch:=='volatile') {
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
               }
            } else if (ch:=='const') {
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
            } else if (ch:=='interface' && return_type=='' && rt.return_type=='') {
               rt.return_type=ch;
            }
            break;
         }

      // handle special C# builtins, mapped to System classes
      case 'object':   if (ch:=='object'   && _LanguageInheritsFrom('cs')) {rt.return_type="System/Object";break;}
                       if (ch:=='object'   && _LanguageInheritsFrom('jsl')){rt.return_type="System/Object";break;}
      case 'string':   if (ch:=='string'   && _LanguageInheritsFrom('cs')) {rt.return_type="System/String";break;}
                       if (ch:=='string'   && _LanguageInheritsFrom('jsl')){rt.return_type="System/String";break;}
      case 'delegate': if (ch:=='delegate' && _LanguageInheritsFrom('cs')) {rt.return_type="System/Delegate";break;}
                       if (ch:=='delegate' && _LanguageInheritsFrom('jsl')){rt.return_type="System/Delegate";break;}
      case 'void':     if (ch:=='void'     && _LanguageInheritsFrom('d'))  {rt.return_type="__ANY_TYPE";break;}
      
      // InstallScript pointers
      case 'POINTER':
         if (_LanguageInheritsFrom('rul') && ch:=='POINTER' && rt.return_type!='') {
            rt.pointer_count++;
            break;
         }

      // InstallScript reference types
      case 'BYREF':
         if (_LanguageInheritsFrom('rul') && ch:=='BYREF') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }

      // Slick-C typeless reference variables
      case 'var':
         if (_LanguageInheritsFrom('e') && ch:=='var') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            rt.return_type="typeless";
            visited:[input_args]=rt;
            return(0);
         }

      // C# parameter tyupes, by reference
      case 'in':
      case 'ref':
      case 'out':
         if (_LanguageInheritsFrom('cs') && ch:=='out') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_OUT;
            break;
         }
         if (_LanguageInheritsFrom('cs') && ch:=='ref') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_REF;
            break;
         }
         if (_LanguageInheritsFrom('cs') && ch:=='in') {
            break;
         }

      // C# readonly parameters, treat this like 'const'
      case 'readonly':
         if (_LanguageInheritsFrom('cs') && (ch:=='readonly')) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            break;
         }

      // C/C++ signed and unsigned builtin types
      case 'signed':
      case 'unsigned':
         if (_LanguageInheritsFrom('c') && (ch:=='signed' || ch:=='unsigned' || ch:=='long')) {
            if (_c_is_builtin_type(return_type) && rt.return_type=='') {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               rt.return_type=ch' 'return_type;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return VSCODEHELPRC_BUILTIN_TYPE;
            }
         }
         
      // C/C++ long integers, long long, and long double
      case 'long':
         if (_LanguageInheritsFrom('c') && ch:=='long') {
            if (_c_is_builtin_type(return_type) && rt.return_type=='') {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
               rt.return_type=ch' 'return_type;
               errorArgs[1] = symbol;
               errorArgs[2] = orig_return_type;
               return VSCODEHELPRC_BUILTIN_TYPE;
            }
         }

      // D language typeof(x) type expressions
      case 'typeof':
         if (_LanguageInheritsFrom('d') && ch:=='typeof' && first_char(return_type)=='(') {
            ch = '('; 
            return_type = substr(return_type,2);
            _str typeof_exp='';
            if (!match_parens(return_type, typeof_exp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }
            VS_TAG_RETURN_TYPE typeof_rt;
            tag_return_type_init(typeof_rt);
            status = _c_get_type_of_expression(errorArgs, tag_files, typeof_exp, typeof_rt, visited, depth+1);
            if (status) return status;
            rt = typeof_rt;
            continue;
         }

      case 'input':
      case 'output':
      case 'inout':
      case 'ref':
         if (_LanguageInheritsFrom('sv') && 
             (ch:=='input' || ch:=='output' || ch:=='inout' || ch:=='ref')) {
            rt.return_type=ch;
            break;
         }

      // Any other type of identifier
      default:

         // is the current token a builtin?
         if (_c_is_builtin_type(ch) && rt.return_type=='') {
            rt.return_type = ch;
            continue;
         }

         // try simple macro substitution
         orig_ch := ch;
         if (!isjava && ch!='interface' &&
             tag_check_for_class(ch, rt.return_type, true, tag_files) <= 0 && 
             tag_check_for_define(ch, 0, tag_files, ch)) {
            switch (ch) {
            case '':
            case 'extern':
            case 'struct':
            case 'class':
            case 'interface':
            case 'union':
               continue;
            case 'volatile':
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
               }
               continue;
            case 'const':
               if (rt.pointer_count <= 0) {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               }
               continue;
            }
         }

         // try template argument substitution
         if (!found_seperator && orig_rt.template_types._indexin(ch)) {
            if (_chdebug) {
               isay(depth,"_c_parse_return_type: USIG TEMPLATE ARGUMENT: "ch);
            }
            rt = orig_rt.template_types:[ch];
            continue;
         }

         // check for an unqualfied package name
         // if we find a namespace alias, let it be handled below
         _str aliased_to = "";
         if (rt.return_type == '' && !found_seperator && return_type != '' &&
             tag_check_for_package(ch, tag_files, true, true, aliased_to) && aliased_to=="") {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: package_name="ch);
            }
            rt.return_type = ch;
            continue;
         }

         // check for a qualified package name
         switch (prev_ch) {
         case '::':
         case '/':
         case ':':
         case '.':
            if (rt.return_type!='' && tag_check_for_package(rt.return_type:+prev_ch:+ch, tag_files, false, true)) {
               rt.return_type = rt.return_type:+prev_ch:+ch;
               continue;
            }
            if (rt.return_type!='' && tag_check_for_package(rt.return_type:+'/':+ch, tag_files, true, true)) {
               rt.return_type = rt.return_type:+'/':+ch;
               continue;
            }
            break;
         }

         // check for specific qualified package name
         _str alt_ch1 = '';
         _str alt_ch2 = '';
         switch (prev_ch) {
         case '::':  alt_ch1 = '/';  break;
         case '/':   alt_ch1 = '::'; break;
         case ':':   alt_ch1 = '.'; alt_ch2 = '::'; break;
         case '.':   alt_ch1 = ':'; alt_ch2 = '::'; break;
         }
         if (rt.return_type!='') {
            if (alt_ch1 != '') {
               if (tag_check_for_package(rt.return_type:+alt_ch1:+ch, tag_files, true, true) ||
                   tag_check_for_package(rt.return_type:+alt_ch1:+ch:+alt_ch1, tag_files, false, true)) {
                  rt.return_type = rt.return_type:+alt_ch1:+ch;
                  continue;
               }
            }
            if (alt_ch2 != '') {
               if (tag_check_for_package(rt.return_type:+alt_ch2:+ch, tag_files, false, true) &&
                   tag_check_for_package(rt.return_type:+alt_ch2:+ch:+alt_ch2, tag_files, false, true)) {
                  rt.return_type = rt.return_type:+alt_ch2:+ch;
                  continue;
               }
            }
         }
         if (!found_seperator && rt.return_type=='' && (next_ch == '.' || next_ch == '::')) {
            if (tag_check_for_package(ch:+next_ch, tag_files, false, true)) {
               rt.return_type = ch;
               continue;
            }
         }

         // check for compound builtin type names
         if (_c_is_builtin_type(rt.return_type) && _c_is_builtin_type(ch)) {
            rt.return_type = rt.return_type ' ' ch;
         } else if (rt.return_type=='' && _c_is_builtin_type(ch)) {
            rt.return_type=ch;
         }

         // look up 'ch' using Context Tagging&reg; to it's fullest power
         VS_TAG_RETURN_TYPE ch_rt;
         tag_return_type_init(ch_rt);
         if (found_seperator) {
            ch_rt.template_args  = rt.template_args;
            ch_rt.template_names = rt.template_names;
            ch_rt.template_types = rt.template_types;
            if (rt.return_type != '') {
               search_class_name = rt.return_type;
               if (!tag_check_for_package(rt.return_type, tag_files, true, true)) {
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
            if (ch_rt.filename=='') {
               ch_rt.filename=file_name;
            }
         }

         int pushtag_flags = VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ENUM;
         if (next_ch != '<') {
            pushtag_flags |= VS_TAGFILTER_TYPEDEF;
            if (next_ch != '') {
               pushtag_flags |= VS_TAGFILTER_PACKAGE;
            }
         } else {
            ch_rt.istemplate = true;
         }

         status = _c_get_return_type_of(errorArgs, tag_files, ch,
                                        search_class_name, 0, isjava,
                                        pushtag_flags, true, false, 
                                        ch_rt, visited, depth+1);
         if (_chdebug) {
            isay(depth,"_c_parse_return_type(CH): status="status);
            tag_return_type_dump(ch_rt, "_c_parse_return_type(CH)", depth);
         }
         if (!status) {
            if (next_ch != '<') {
               if (ch_rt.return_type :== search_class_name) {
                  ch_rt.template_args  = orig_rt.template_args;
                  ch_rt.template_names = orig_rt.template_names;
                  ch_rt.template_types = orig_rt.template_types;
               } else if (prev_ch == '::') {
                  tag_return_type_merge_templates(ch_rt, rt);
               }
            }
            orig_const_only := (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
            rt = ch_rt;
            rt.return_flags |= orig_const_only;
            continue;
         }
         // check for an unqualfied package name
         if (rt.return_type == '' && !found_seperator &&
             tag_check_for_package(ch, tag_files, false, true) &&
             (tag_check_for_package(ch'.', tag_files, false, true) ||
              tag_check_for_package(ch'/', tag_files, false, true) ||
              tag_check_for_package(ch':', tag_files, false, true))) {
            if (_chdebug) {
               isay(depth, "_c_parse_return_type: package_name="ch);
            }
            rt.return_type = ch;
            continue;
         }
         if (rt.return_type=="" && return_type=="" && status < 0) {
            return status;
         }
      }
   }

   if (rt.return_type == '') {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   if (_chdebug) {
      tag_return_type_dump(rt, "_c_parse_return_type returns", depth);
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
 * @param errorArgs                  instruction_case; * @param tag_files
 *                                   refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files                  list of extension specific tag files
 * @param symbol                     name of symbol having given return type
 * @param search_class_name          class context to evaluate return type relative to
 * @param min_args                   minimum number of arguments for function, used
 *                                   to resolve overloading.
 * @param isjava                     Is this Java, JavaScript, C# or similar?
 * @param pushtag_mask               bitset of VS_TAGFILTER_*, allows us to search only
 *                                   certain items in the database (e.g. functions only)
 * @param maybe_class_name           Could the symbol be a class name, for example
 *                                   C++ syntax of BaseObject::method, BaseObject might
 *                                   be a class name.
 * @param rt                         (reference) set to return type information
 * @param visited                    (reference) have we evalued this return type before?
 * @param depth                      depth of recursion (for handling typedefs)
 * @param match_type
 * @param pointer_count
 * @param toy_return_flags
 * @param match_tag
 * @param depth
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _c_get_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                 _str symbol, _str search_class_name,
                                 int min_args, boolean isjava,
                                 int pushtag_mask, boolean maybe_class_name,
                                 boolean filterFunctionSignatures,
                                 struct VS_TAG_RETURN_TYPE &rt,
                                 VS_TAG_RETURN_TYPE (&visited):[], int depth=0, int context_flags=0)
{
   if (_chdebug) {
      isay(depth,"_c_get_return_type_of: =======================================");
      isay(depth,"_c_get_return_type_of: symbol="symbol" class="search_class_name);
      tag_return_type_dump(rt, "_c_get_return_type_of", depth);
   }

   if (depth > 100) {
      errorArgs[1] = symbol;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
   }

   // filter out mutual recursion
   _str input_args='get;'symbol';'search_class_name';'min_args';'isjava';'pushtag_mask';'maybe_class_name';'p_buf_name';'tag_return_type_string(rt);
   int status = _CodeHelpCheckVisited(input_args, "_c_get_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // open the expected file in a temp view
   _str search_file = rt.filename;
   if (search_file == '' && rt.return_type == '') {
      search_file = p_buf_name;
   }
   int temp_view_id=0;
   int orig_view_id=0;
   boolean inmem=false;
   int temp_view_status = -1;
   if (rt.filename != '') {
      lang := _Filename2LangId(rt.filename);
      if (lang!='xml' && !_QBinaryLoadTagsSupported(rt.filename)) {
         temp_view_status = _open_temp_view(rt.filename,temp_view_id,orig_view_id,'',inmem,false,true);
         if (!temp_view_status) {
            if (rt.line_number > 0) {
               p_RLine = rt.line_number;
               first_non_blank();
            }
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_push_context();
            _UpdateContext(true);
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

   // initialize c_return_flags
   rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                        VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                        VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                        VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                        VSCODEHELP_RETURN_TYPE_ARRAY|
                        VSCODEHELP_RETURN_TYPE_HASHTABLE|
                        VSCODEHELP_RETURN_TYPE_HASHTABLE2
                       );
   if (search_class_name == '::') {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
      search_class_name = '';
   }

   // get the current class from the context
   _str cur_tag_name, cur_type_name, cur_class_name, cur_class_only, cur_package_name;
   int cur_tag_flags=0, cur_type_id=0;
   int context_id = tag_get_current_context(cur_tag_name,cur_tag_flags,
                                            cur_type_name,cur_type_id,
                                            cur_class_name,cur_class_only,
                                            cur_package_name);

   // evaluate the scope of this context so that cur_class_name is qualified.
   if (cur_class_name != '' && !maybe_class_name && 
       !_LanguageInheritsFrom('java') &&
       !(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
       !(rt.return_flags & VSCODEHELP_RETURN_TYPE_INCLASS_ONLY)) {
      VS_TAG_RETURN_TYPE scope_rt;
      tag_return_type_init(scope_rt);
      if (!_c_parse_return_type(errorArgs, tag_files,
                                cur_tag_name, search_class_name,
                                p_buf_name, cur_class_name,
                                isjava, scope_rt, visited, depth+1)) {
         cur_class_name = scope_rt.return_type;
      }
   }

   // attempt to resolve the class name to a package
   // need this for C++ namespaces
   _str inner_name, outer_name, qualified_name='';
   tag_split_class_name(cur_class_name,inner_name,outer_name);
   if (!tag_qualify_symbol_name(qualified_name,
                                inner_name, outer_name,
                                p_buf_name, tag_files,
                                true, visited, depth)) {
      cur_class_name=qualified_name;
   }

   // special case keyword 'this'
   if (symbol :== 'this' && !(cur_tag_flags & VS_TAGFLAG_static) && cur_class_name!='') {
      if (search_class_name :== '' && context_id > 0) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         if (cur_tag_flags & VS_TAGFLAG_const) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (cur_tag_flags & VS_TAGFLAG_volatile) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         // revert to cur_class_name if we could not qualify class name
         if (qualified_name=='' || qualified_name==inner_name) {
            rt.return_type = cur_class_name;
         } else {
            rt.return_type = qualified_name;
         }
         boolean this_is_reference = (_LanguageInheritsFrom('js') || 
                                      _LanguageInheritsFrom('as') || 
                                      _LanguageInheritsFrom('e') || 
                                      _LanguageInheritsFrom('d') ||
                                      _LanguageInheritsFrom('lua') ||
                                      _LanguageInheritsFrom('vera') ||
                                      _LanguageInheritsFrom('systemverilog')); 
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
            if (rt.return_type == cur_class_name) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            }
         }

         visited:[input_args]=rt;

         // close the temp view
         if (temp_view_status == 0) {
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_pop_context();
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContext(true);
            _UpdateLocals(true);
         }
         return 0;
      } else if (isjava && search_class_name != '') {
         rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_CONST_ONLY|
                              VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                              VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY|
                              VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                              VSCODEHELP_RETURN_TYPE_ARRAY|
                              VSCODEHELP_RETURN_TYPE_HASHTABLE|
                              VSCODEHELP_RETURN_TYPE_HASHTABLE2
                             );
         rt.return_type = search_class_name;
         rt.pointer_count = 0;
         visited:[input_args]=rt;

         // close the temp view
         if (temp_view_status == 0) {
            //DJB 01-03-2007 -- push/pop context is obsolete
            //tag_pop_context();
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
            _UpdateContext(true);
            _UpdateLocals(true);
         }
         return 0;
      }
   }

   //tag_return_type_dump(rt, "_c_get_return_type_of (BEFORE)", depth);
   status = _c_find_return_type_of(errorArgs, tag_files,
                                    symbol, search_class_name, search_file,
                                    cur_class_name, min_args,
                                    isjava, maybe_class_name,
                                    filterFunctionSignatures,
                                    pushtag_mask, rt, visited, depth+1, context_flags);
   if (_chdebug) {
      tag_return_type_dump(rt,"_c_get_return_type_of returns", depth);
   }

   // close the temp view
   if (temp_view_status == 0) {
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      _UpdateContext(true);
      _UpdateLocals(true);
   }

   // check for error condition
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   }
   return status;
}
/**
 * Utility function for searching the current context and tag files
 * for symbols matching the given symbol and search class, filtering
 * based on the pushtag_mask and toy_return_flags.  The number of
 * matches is returned and can be obtained using TAGSDB function
 * tag_get_match(...).
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param pushtag_mask        bitset of VS_TAGFILTER_*, allows us to search only
 *                            certain items in the database (e.g. functions only)
 * @param rt                  return type information
 *
 * @return 0 on success,
 *         < 0 on other error (normal slickedit RC)
 */
static int _c_find_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                  _str symbol, _str search_class_name,
                                  _str search_file, _str cur_class_name,
                                  int min_args, boolean isjava, 
                                  boolean maybe_class_name,
                                  boolean filterFunctionSignatures,
                                  int pushtag_mask, struct VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0, 
                                  int context_filter_flags=0)
{
   if (_chdebug) {
      isay(depth,"_c_find_return_type_of(symbol="symbol", search_class="search_class_name", cur_class="cur_class_name")");
      tag_return_type_dump(rt, "_c_find_return_type_of", depth);
   }

   // filter out mutual recursion
   _str input_args='match;'symbol';'search_class_name';'search_file';'cur_class_name';'min_args';'isjava';'maybe_class_name';'pushtag_mask';'tag_return_type_string(rt);
   int status = _CodeHelpCheckVisited(input_args, "_c_find_return_type_of", rt, visited, depth);
   if (!status) return 0;
   if (status < 0) {
      errorArgs[1]=symbol;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // Attempt to qualify symbols to their appropriate package for Java
   if (/*isjava &&*/ search_class_name=='') {
      _str junk='';
      tag_qualify_symbol_name(search_class_name,
                              symbol, search_class_name,
                              search_file, tag_files,
                              true, visited, depth);
      tag_split_class_name(search_class_name, junk, search_class_name);
   }
   //say("2 before previous_id="symbol" match_class="search_class_name);

   // try to find match for 'symbol' within context, watch for
   // C++ global designator (leading ::)
   int i, num_matches = 0;
   tag_clear_matches();
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      if (_chdebug) {
         isay(depth,"_c_find_return_type_of: matching globals");
      }
      tag_list_context_globals(0, 0, symbol, true, tag_files, pushtag_mask,
                               VS_TAGCONTEXT_ONLY_non_static,
                               num_matches, def_tag_max_function_help_protos, true, true);
   } else {
      if (_chdebug) {
         isay(depth,"_c_find_return_type_of: matching class symbols, search_class="search_class_name" symbol="symbol" pushtag_mask="dec2hex(pushtag_mask));
      }
      int context_flags = VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ALLOW_protected|VS_TAGCONTEXT_ALLOW_anonymous;
      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags,context_flags);
      boolean strict = (rt.return_flags & VSCODEHELP_RETURN_TYPE_INCLASS_ONLY)? true:false;
      if (strict) context_flags |= VS_TAGCONTEXT_ONLY_inclass;
      if (pos(search_class_name, cur_class_name)==1 &&
          substr(cur_class_name, length(search_class_name)+1, 1) == ':') {
         context_flags |= VS_TAGCONTEXT_ALLOW_private;
      }
      if (rt.istemplate && !(pushtag_mask & ~VS_TAGFILTER_ANYSTRUCT)) {
         context_flags |= VS_TAGCONTEXT_ONLY_templates;
      }
      int context_list_flags = (strict)? 0 : VS_TAGCONTEXT_FIND_lenient;
      if (_chdebug) {
         isay(depth, "_c_find_return_type_of: calling tag_list_symbols_in_context, return_type="rt.return_type" search_class="search_class_name", istemplate="rt.istemplate);
      }
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, 
                                  tag_files, ''/*search_file*/, 
                                  num_matches, def_tag_max_function_help_protos, 
                                  pushtag_mask, context_flags | context_filter_flags | context_list_flags, 
                                  true, true, visited, depth, rt.template_args);
      // if we didn't have a search class, try again using cur_class_name
      if (num_matches == 0 && search_class_name=='' &&
          cur_class_name!='' && !(context_flags & VS_TAGCONTEXT_ONLY_inclass)) {
         if (_chdebug) {
            isay(depth, "_c_find_return_type_of: trying from cur_class");
         }
         context_list_flags &= ~VS_TAGCONTEXT_FIND_lenient;
         context_flags &= ~VS_TAGCONTEXT_ONLY_templates;
         tag_list_symbols_in_context(symbol, cur_class_name, 0, 0, 
                                     tag_files, ''/*search_file*/, 
                                     num_matches, def_tag_max_function_help_protos, 
                                     pushtag_mask, context_flags | context_filter_flags | context_list_flags, 
                                     true, true, visited, depth);
      }
   }

   // check for error condition
   if (_chdebug) {
      isay(depth,"_c_find_return_type_of: num_matches="num_matches);
   }
   if (num_matches < 0) {
      return num_matches;
   }

   // resolve the type of the matches
   rt.taginfo = '';
   rt.filename = '';
   rt.line_number = 0;
   status = _c_get_type_of_matches(errorArgs, tag_files, symbol,
                                   search_class_name, cur_class_name,
                                   min_args, isjava, maybe_class_name,
                                   filterFunctionSignatures,
                                   rt, visited, depth+1);

   if (_chdebug) {
      tag_return_type_dump(rt,"_c_find_return_type_of(AFTER)",depth);
   }
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
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
static int _c_get_type_of_matches(_str (&errorArgs)[], typeless tag_files,
                                  _str symbol, _str search_class_name,
                                  _str cur_class_name, int min_args,
                                  boolean isjava, boolean maybe_class_name,
                                  boolean filterFunctionSignatures,
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth,"_c_get_type_of_matches: ===================================================");
      isay(depth,"_c_get_type_of_matches(symbol="symbol", search_class="search_class_name", cur_class="cur_class_name")");
      tag_return_type_dump(rt, "_c_get_type_of_matches", depth);
   }

   // used for going through match list
   VS_TAG_BROWSE_INFO cm;
   int i=0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // remove duplicate matches
   tag_remove_duplicate_symbol_matches(false,false,true,true,true,false,
                                       '',filterFunctionSignatures,
                                       visited,depth+1,false);

   // filter out matches based on number of arguments
   _str matchlist[];
   matchlist._makeempty();
   boolean check_args=true;
   int num_matches = tag_get_num_of_matches();
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
             !(cm.flags & VS_TAGFLAG_operator) && !(cm.flags & VS_TAGFLAG_maybe_var)) {
            int num_args = 0;
            int def_args = 0;
            int arg_pos  = 0;
            for (;;) {
               _str parm = '';
               tag_get_next_argument(cm.arguments, arg_pos, parm);
               if (parm == '') {
                  break;
               }
               if (pos('=', parm)) {
                  def_args++;
               }
               if (parm :== '...') {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom('java') && pos('...',parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom('d') && pos('...',parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom('lua') && pos('...',parm)) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom('cs') && pos('[',parm) && !pos(',',substr(cm.arguments,arg_pos))) {
                  num_args = min_args;
                  break;
               }
               if (_LanguageInheritsFrom('cs') && substr(parm,1,7):=='params ') {
                  num_args = min_args;
                  break;
               }
               num_args++;
            }
            // this prototype doesn't take enough arguments?
            //say("_c_get_type_of_matches: num="num_args" min="min_args);
            if (num_args < min_args) {
               continue;
            }
            // this prototype requires too many arguments?
            if (num_args - def_args > min_args) {
               continue;
            }
         } else if (cm.type_name=='typedef') {
            // skip over recursive typedefs
            _str p1='', p2='';
            parse cm.return_type with p1 ' ' p2;
            if (symbol==cm.return_type || symbol==p2) {
               continue;
            }
         }
         // As it turns out, in C++, you can inherit operators
         //if ((tag_flags & VS_TAGFLAG_operator) && class_name :!= search_class_name) {
         //   continue;
         //}
         //say("WHERE proc_name="proc_name" class="class_name" return_type="return_type);
         if (rt.taginfo == '') {
            rt.taginfo = tag_tree_compose_tag_info(cm);
            rt.filename = cm.file_name;
            rt.line_number = cm.line_no;
            //say("MATCH TAG="match_tag);
         }
         if (cm.type_name == 'friend' || (cm.flags & VS_TAGFLAG_forward)) {
            continue;
         }
         if (tag_tree_type_is_func(cm.type_name) && (cm.flags & VS_TAGFLAG_constructor) && pos(cm.member_name, cm.class_name)) {
            cm.return_type = cm.class_name;
         }
         if (tag_tree_type_is_class(cm.type_name) || cm.type_name=='enum') {
            cm.return_type = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true);
            if (cm.return_type=='') cm.return_type = cm.member_name;
         }
         if (tag_tree_type_is_package(cm.type_name) && 
             ((cm.class_name==rt.return_type) || (rt.return_type==""))) {
            cm.return_type = cm.member_name;
            if (cm.class_name != '') {
               cm.return_type = cm.class_name:+VS_TAGSEPARATOR_package:+cm.member_name;
            }
         }
         if (_LanguageInheritsFrom('cs') && cm.type_name=='enum') {
            cm.return_type = cm.member_name;
         } else if (_LanguageInheritsFrom('java') && cm.type_name=='enum') {
            cm.return_type = cm.member_name;
         }
         if (cm.return_type != '') {
            matchlist[matchlist._length()] = cm.member_name "\t" cm.class_name "\t;" cm.file_name ";\t" cm.line_no "\t" cm.return_type "\t" cm.type_name "\t" cm.flags;
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
   // for each match in list, (have to do it this way because
   // _c_parse_return_type()) uses the context match set.
   VS_TAG_RETURN_TYPE found_rt;tag_return_type_init(found_rt);
   VS_TAG_RETURN_TYPE match_rt;tag_return_type_init(match_rt);
   rt.return_type = '';
   int status=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   int found_status=1;
   int num_repeats=0;
   for (i=0; i<matchlist._length(); i++) {

      _str match_flags='';
      _str match_line='';

      parse matchlist[i] with cm.member_name "\t" cm.class_name "\t;" cm.file_name ";\t" match_line "\t" cm.return_type "\t" cm.type_name "\t" match_flags;
      cm.flags = isnumber(match_flags)? (int) match_flags : 0;
      cm.line_no   = isnumber(match_line)?  (int) match_line  : 0;

      tag_return_type_init(found_rt);
      found_rt.template_args  = rt.template_args;
      found_rt.template_names = rt.template_names;
      found_rt.template_types = rt.template_types;
      found_rt.istemplate     = rt.istemplate;
      found_rt.filename       = cm.file_name;
      found_rt.line_number    = cm.line_no;
      if (_chdebug) {
         tag_browse_info_dump(cm,"_c_get_type_of_matches (BEFORE)", depth);
         tag_return_type_dump(found_rt,"_c_get_type_of_matches (BEFORE)", depth);
      }
      if (tag_tree_type_is_package(cm.type_name) && 
          cm.return_type != '' && cm.return_type != cm.member_name && 
          cm.return_type != cm.class_name:+VS_TAGSEPARATOR_package:+cm.member_name) {
         // namespace alias
         status = _c_parse_return_type(errorArgs, tag_files, 
                                       cm.member_name, cur_class_name,
                                       cm.file_name, cm.return_type, 
                                       isjava, found_rt, 
                                       visited, depth+1);
         if (_chdebug) {
            isay(depth, "_c_get_type_of_matches: MAY BE PACKAGE NAME, return_type="cm.return_type" class="cm.class_name" member="cm.member_name);
         }

      } else if (tag_tree_type_is_class(cm.type_name) || tag_tree_type_is_package(cm.type_name) || cm.type_name=='enum') {
         found_rt.return_type = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true, true);
         found_rt.taginfo = tag_tree_compose_tag(cm.member_name, cm.class_name, cm.type_name, cm.flags);
         found_rt.filename = cm.file_name;
         found_rt.line_number = cm.line_no;
         if (cm.flags & VS_TAGFLAG_template) {
            found_rt.istemplate = true;
         }
         if ((tag_tree_type_is_class(cm.type_name) || cm.type_name=='enum') && !_LanguageInheritsFrom('lua')) {
            boolean isParentClass = tag_is_parent_class(found_rt.return_type, cur_class_name,
                                                        tag_files, true, false, found_rt.filename, 
                                                        visited, depth);
            if (_chdebug) {
               isay(depth, "_c_get_type_of_matches: CHECK FOR STATIC ONLY, isParentClass="isParentClass);
            }
            if (_LanguageInheritsFrom('py')) {
               /*
                  For Python, when evern the class name is specified, the function

                    baseclass.__init__(

               */
               found_rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: CHECK FOR STATIC ONLY, PYTHON");
               }
            } else if (_in_function_scope() && !isParentClass && 
                       cm.type_name != "union" && cm.type_name != "group") {
               found_rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: CHECK FOR STATIC ONLY, OUTSIDE OF CLASS");
               }
            } else {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_matches: CHECK FOR STATIC ONLY, NOT PARENT CLASS");
               }
            }
         }
         status = 0;
      } else {
         if ( _LanguageInheritsFrom('e') && cm.type_name=='lvar' && 
              (cm.return_type=='auto' || isTypeInferred(cm.return_type))) {
            // Slick-C colon-declared local variable with type of reference parameter
            status = _c_get_type_of_parameter(errorArgs,tag_files,cm,found_rt,visited,depth+1);
            if (status) {
               status = _c_parse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cur_class_name,
                                             cm.file_name, cm.return_type, 
                                             isjava, found_rt, 
                                             visited, depth+1);
            }
         } else if (cm.class_name=='') {
            status = _c_parse_return_type(errorArgs, tag_files, 
                                          cm.member_name, cur_class_name,
                                          cm.file_name, cm.return_type, 
                                          isjava, found_rt,
                                          visited, depth+1);
         } else {
            _c_get_inherited_template_args(errorArgs, tag_files, cm.class_name,
                                           search_class_name, cm.file_name, 
                                           found_rt, visited, depth+1);
            status = _c_parse_return_type(errorArgs, tag_files, 
                                          cm.member_name, cm.class_name,
                                          cm.file_name, cm.return_type, 
                                          isjava, found_rt,
                                          visited, depth+1);
         }

         // is the return type a builtin that has a boxing conversion?
         if (_c_is_builtin_type(rt.return_type)) {
            box_type := _c_get_boxing_conversion(rt.return_type);
            if (box_type != '') {
               rt.return_type = box_type;
            }
         }
         if (cm.flags & VS_TAGFLAG_template) {
            found_rt.istemplate = true;
         }
         found_rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
      }
      if (_chdebug) {
         isay(depth, "_c_get_type_of_matches: matchlist["i"] status="status);
         tag_return_type_dump(found_rt, "_c_get_type_of_matches matchlist["i"]", depth);
      }
      // skip over overloaded return types we can't handle
      if (status<0 && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         if (found_status > 0) found_status = status;
         found_rt=match_rt;
         continue;
      }
      // previous overload failed, but now we have a good one
      found_status = 0;
      if (found_rt.return_type != '') {

         if (rt.return_type=='') {
            match_rt=found_rt;
            rt.return_type = found_rt.return_type;
            //_message_box("new match type="rt.return_type);
            rt.return_flags = found_rt.return_flags;
            rt.pointer_count += found_rt.pointer_count;
            //say("RETURN, pointer_count="rt.pointer_count" found_pointer_count="found_rt.pointer_count" found_type="found_rt.return_type);
            match_rt.pointer_count = found_rt.pointer_count;
         } else {
            // different opinions on static_only or const_only, chose more general
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
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
                  isay(depth, "_c_get_type_of_matches: DIFFERENT MATCH_TYPE="rt.return_type" FOUND_TYPE="found_rt.return_type" pointer="match_rt.pointer_count" found_pointer="found_rt.pointer_count);
               }
               errorArgs[1] = symbol;
               return VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
            }
            //say("_c_get_type_of_matches: here");
         }
         // if we have over five matching return types, then call it good
         num_repeats++;
         if (num_repeats>=4) {
            //say("_c_get_type_of_matches: GOT FOUR IDENTICAL TYPES");
            break;
         }
      }
   }

   if (found_status < 0 && found_status != VSCODEHELPRC_BUILTIN_TYPE) {
      //say("_c_get_type_of_matches: error="status);
      if (status < 0 && errorArgs._length() > 0) return status;
      if (errorArgs._length() == 0) errorArgs[1]=symbol;
      return found_status;
   }

   // transfer template arguments from outer to inner class
   rt.istemplate = (found_rt.istemplate || rt.istemplate);
   rt.template_args  = found_rt.template_args;
   rt.template_names = found_rt.template_names;
   rt.template_types = found_rt.template_types;

   //say("maybe class name, num_matches="num_matches);
   // Java syntax like Class.blah... or C++ style iostream::blah
   if (maybe_class_name && num_matches==0) {
      //say("111 searching for class name, symbol="symbol" class="search_class_name);
      int class_context_flags=0;
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals);
      class_context_flags |= ((rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS)? 0:VS_TAGCONTEXT_ALLOW_protected);
      tag_list_symbols_in_context(symbol, search_class_name, 0, 0, 
                                  tag_files, '', num_matches, def_tag_max_function_help_protos, 
                                  VS_TAGFILTER_PACKAGE|VS_TAGFILTER_STRUCT|VS_TAGFILTER_INTERFACE|VS_TAGFILTER_UNION,
                                  class_context_flags,
                                  true, true, visited, depth);


      //say("found "num_matches" matches");
      if (num_matches > 0) {
         VS_TAG_BROWSE_INFO x_cm;
         tag_get_match_info(1,x_cm);
         //say("X tag="x_tag_name" class="x_class_name" type="x_type_name);
         //isay(depth, "_c_get_type_of_matches: symbol="symbol);
         rt.return_type = symbol;
         if (search_class_name == '' || search_class_name == cur_class_name) {
            _str outer_class_name = cur_class_name;
            int local_matches=0;
            if (x_cm.flags & VS_TAGFLAG_template) {
               rt.istemplate=true;
            }
            //while (outer_class_name != '') {
            for (;;) {
               tag_list_symbols_in_context(rt.return_type, cur_class_name, 0, 0, 
                                           tag_files, '', 
                                           num_matches, def_tag_max_function_help_protos,
                                           VS_TAGFILTER_PACKAGE|VS_TAGFILTER_STRUCT|VS_TAGFILTER_INTERFACE|VS_TAGFILTER_UNION,
                                           class_context_flags,
                                           true, true, visited, depth);

               //say("222 match_type="rt.return_type" cur_class_name="cur_class_name" num_matches="local_matches);
               if (local_matches > 0) {
                  VS_TAG_BROWSE_INFO rel_cm;
                  tag_get_match_info(1,rel_cm);
                  rt.return_type = tag_join_class_name(rt.return_type, rel_cm.class_name, tag_files, true, true);
                  //isay(depth, "_c_get_type_of_matches(222): return_type="rt.return_type);
                  //say("type_name="rel_type_name" MATCH_TYPE="match_type);
                  if (isjava) {
                     rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                  }
                  break;
               }
               _str junk;
               tag_split_class_name(outer_class_name, junk, outer_class_name);
               if (outer_class_name=='') {
                  break;
               }
            }
         } else if (search_class_name != '') {
            rt.return_type = tag_join_class_name(rt.return_type, search_class_name, tag_files, true, true);
            //isay(depth, "_c_get_type_of_matches: rt.return_type="rt.return_type);
            if (isjava) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
         }
      }
   }

   // see if 'symbol' is a control for Slick-C
   if ((num_matches==0 || rt.return_type=='') && _LanguageInheritsFrom('e')) {
      //say("_c_get_type_of_matches: Slick-C");
      // maybe should just search source here...
      _str eventtab_name = '';
      save_pos(auto p);
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      if (!search('^ *defeventtab +{:v}','@-hr')) {
         eventtab_name = get_match_text(0);
         eventtab_name=stranslate(eventtab_name,'-','_');
      }
      restore_search(p1,p2,p3,p4);
      restore_pos(p);

      //say("_c_get_type_of_matches: tab="eventtab_name);
      _str name_symbol = stranslate(symbol,'-','_');
      int wid=_find_formobj(eventtab_name,'E');
      if (!wid) {
         wid = find_index(eventtab_name,oi2type(OI_FORM));
      }
      if (wid && _iswindow_valid(wid)) {
         wid = (int)_for_each_control(wid,'_compare_control_name','H',name_symbol);
      }
      //say("_c_get_type_of_matches: wid="wid);
      if (wid && _iswindow_valid(wid)) {
         rt.return_type = '';
         int t = wid.p_object;
         if (t == OI_MDI_FORM)             rt.return_type = '_mdi_form';
         else if (t == OI_FORM)            rt.return_type = '_form';
         else if (t == OI_TEXT_BOX)        rt.return_type = '_text_box';
         else if (t == OI_CHECK_BOX)       rt.return_type = '_check_box';
         else if (t == OI_COMMAND_BUTTON)  rt.return_type = '_command_button';
         else if (t == OI_RADIO_BUTTON)    rt.return_type = '_radio_button';
         else if (t == OI_FRAME)           rt.return_type = '_frame';
         else if (t == OI_LABEL)           rt.return_type = '_label';
         else if (t == OI_LIST_BOX)        rt.return_type = '_list_box';
         else if (t == OI_HSCROLL_BAR)     rt.return_type = '_hscroll_bar';
         else if (t == OI_VSCROLL_BAR)     rt.return_type = '_vscroll_bar';
         else if (t == OI_COMBO_BOX)       rt.return_type = '_combo_box';
         else if (t == OI_HTHELP)          rt.return_type = '_hthelp';
         else if (t == OI_PICTURE_BOX)     rt.return_type = '_picture_box';
         else if (t == OI_IMAGE)           rt.return_type = '_image';
         else if (t == OI_GAUGE)           rt.return_type = '_gauge';
         else if (t == OI_SPIN)            rt.return_type = '_spin';
         else if (t == OI_MENU)            rt.return_type = '_menu';
         else if (t == OI_MENU_ITEM)       rt.return_type = '_window';
         else if (t == OI_TREE_VIEW)       rt.return_type = '_tree_view';
         else if (t == OI_SSTAB)           rt.return_type = '_sstab';
         else if (t == OI_DESKTOP)         rt.return_type = '_window';
         else if (t == OI_SSTAB_CONTAINER) rt.return_type = '_sstab_container';
         else if (t == OI_EDITOR)          rt.return_type = '_editor';
         //say("t="t" match_type="rt.return_type);
         if (rt.return_type != '') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
            return 0;
         }
      }
   }

   // no matches?
   if (num_matches == 0) {
      //say("_c_get_type_of_matches: no symbols found");
      errorArgs[1] = symbol;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // check if we should list private class members
   //isay(depth, "_c_get_type_of_matches: match_type="rt.return_type" cur_class="cur_class_name);
   int cur_context_id = tag_current_context();
   if (cur_context_id == 0) {
      // if the current context is global, then include private members
      // because they may be trying to put together a function definition
      // for a private method.
      if (!_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('cs')) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
      }
   } else {
      // current method is from same class, then we have private access
      int class_pos = lastpos(cur_class_name,rt.return_type);
      if (class_pos>0 && class_pos+length(cur_class_name)==length(rt.return_type)+1) {
         if (class_pos==1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         } else if (substr(rt.return_type,class_pos-1,1)==VS_TAGSEPARATOR_package) {
            // maybe class comes from imported namespace
            _str import_type = '';
            _str import_name = substr(rt.return_type,1,class_pos-2);
            int import_id = tag_find_local_iterator(import_name,true,true,false,'');
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_local_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_local_iterator(import_name,import_id,true,true,false,'');
            }
            import_id = tag_find_context_iterator(import_name,true,true,false,'');
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_context_iterator(import_name,import_id,true,true,false,'');
            }
         }
      } else {
         // if the current context is a namespace, then include private members
         // because they may be trying to put together a function definition
         // for a private method.
         if (!_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('cs')) {
            _str cur_context_type = '';
            tag_get_detail2(VS_TAGDETAIL_context_type, cur_context_id, cur_context_type);
            if (tag_tree_type_is_package(cur_context_type)) {
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
            }
         }
      }
   }

   if (_chdebug) {
      tag_return_type_dump(rt, "_c_get_type_of_matches: returns", depth);
   }
   return 0;
}

// returns true if match was found, false otherwise
static _str _c_get_expr_token(_str &prefixexp)
{
   int p;
   p = pos("^ @{[0-9]#UL|[0-9]#[LU]|[0-9]#LU|0x[0-9A-F]#[ul]@|:n[fd]@|[L|S]@\"[~\"]@\"|'\\[ux][0-9A-F]#'|'\\[0-9]#'}", prefixexp, 1, 'ri');
   if(!p) {
      // get next token from expression
      _str notparen=_LanguageInheritsFrom('d')? '|\!\(':'';
      p = pos('^ @{->(\*|)|\.\*|\:\:|<<'notparen'|>>|\&\&|\|\||[<>=\|\&\*\+-/~\^\%](=|)|[@]:v|:v|'_clex_identifier_re()'|:q|[()\.]|\:\[|\[|\]}', prefixexp, 1, 'ri');
      if (!p) {
         return '';
      }
   }
   p = pos('S0');
   int n = pos('0');
   _str ch = substr(prefixexp, p, n);
   prefixexp = substr(prefixexp, p+n);
   return ch;
}

// Unix regular expression matching java unicode literal. This is 
// a single quoted \u followed by a hexadecimal number.
// For example '\uABCD'
#define RE_MATCH_UNICODE_LITERAL                      "(?:'[^']\\[ux][0-9A-F]+'|[L]'\\[0-9A-F]+')"

// Unix regular expression matching a double quoted string
// For example  "howdy"
#define RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL       "(?:\"[^\"]*\")"

// Unix regular expression matching a single quoted string
// For example  '\0' or '\233'
#define RE_MATCH_C_SINGLE_QUOTED_CHAR_LITERAL         "(?:'[^']*')"

// Unix regular expression matching a hexadecimal literal appened with L or l to cast
// it to a long. Example 0xBADF00DL
#define RE_MATCH_C_HEXADECIMAL_LONG_LITERAL           "(?:0x[0-9A-F]+L)"

// Unix regular expression matching a hexadecimal unsigned literal appened with u or U andL or l to cast
// it to an unsigned long. Example 0xBADF00DL
#define RE_MATCH_C_HEXADECIMAL_UNSIGNED_LONG_LITERAL  "(?:0x[0-9A-F]+(UL|LU))"

// Unix regular expression matching a hexadecimal literal
// it to a long. Example 0xCAFEF00D. Note match Long literal before this.
#define RE_MATCH_C_HEXADECIMAL_INT_LITERAL            "(?:0x[0-9A-F]+)"

// Unix regular expression matching a hexadecimal literal
// it to a long. Example 0xCAFEF00D. Note match Long literal before this.
#define RE_MATCH_C_HEXADECIMAL_UNSIGNED_INT_LITERAL   "(?:0x[0-9A-F]+U)"

// Unix regular expression matching a decimal literal appended with L or l to cast
// it to a long. Example 550L
#define RE_MATCH_C_LONG_LITERAL                       "(?:[0-9]+L)"

// Unix regular expression matching an unsigned decimal literal appended with L or l to cast
// it to a long. Example 550ul
#define RE_MATCH_C_UNSIGNED_LONG_LITERAL              "(?:[0-9]+(UL|LU))"

// Unix regular expression matching a decimal literal Example 550
#define RE_MATCH_C_INT_LITERAL                        "(?:[0-9]+)"

// Unix regular expression matching a decimal literal appended with U or Lto cast
// it to an unsigned Example 55U
#define RE_MATCH_C_UNSIGNED_INT_LITERAL               "(?:[0-9]+U)"

// Unix regular expression matching a floating point literal appended with f or F to
// make it floating point precision.
#define RE_MATCH_C_FLOATING_POINT_LITERAL             "(?:(?:[0-9]+(?:\\.[0-9]+|)|\\.[0-9]+)(?:[E](?:\\+|-|)[0-9]+|)[F])"

// Unix regular expression matching a floating point literal that is double precision. (no trailing f or F)
#define RE_MATCH_C_DOUBLE_PRECISION_LITERAL           "(?:(?:[0-9]+(?:\\.[0-9]+|)|\\.[0-9]+)(?:[E](?:\\+|-|)[0-9]+|))"

// Unix regular expression matching a wide character string literal.
// For instance L"A string". This maps to a wchar_t *
#define RE_MATCH_C_WIDE_CHARACTER_LITERAL             "(?:L\"[^\"]*\")"

// Unix regular expression matching a windows managed string literal
// For instance L"A string". This maps to a wchar_t *
#define RE_MATCH_C_MANAGED_STRING_LITERAL             "(?:S\"[^\"]*\")"

/**
 * Get the return type information for a string suspected of being a constant or literal
 * 
 * @param ch      String containing constant or literal to get type information about
 * @param rt      (out)Filled with the type information for the string passed in.
 * 
 * @return int returns 0 if the string type is successfully interpreted.
 * VSCODEHELPRC_RETURN_TYPE_NOT_FOUND otherwise
 */
static int _c_get_type_of_constant(_str ch, struct VS_TAG_RETURN_TYPE &rt)
{
   // Note: order matters in these checks.
   // Want to check the most specific to most general check.
   // For instance check for 57L (long integer) before you
   // check for integer because the integer check will pick 
   // out 57 as an integer.
   // Check for 5.1f (floating point check for trailing f) 
   // before checking for double. etc.
   VS_TAG_RETURN_TYPE orig_rt = rt;
   rt.filename = p_buf_name;
   rt.line_number = p_line;
   rt.template_args._makeempty();
   rt.template_names._makeempty();
   rt.template_types._makeempty();
   rt.return_flags = VSCODEHELP_RETURN_TYPE_CONST_ONLY; // ? 
   rt.pointer_count = 0;
   rt.istemplate = false;
   rt.taginfo = ""; // Not sure what to put in here

   // Check to see if this literal is a string or character constant
   if(_LanguageInheritsFrom('e')) {
      // In Slick-C there are only string literals and then can have either single or double quotes
      if(pos(":q", ch, 1, "r") == 1) {
         rt.return_type = "_str";
         return 0;
      }   
   } else {
      // wide character string literal L"Blah"
      if(pos(RE_MATCH_C_WIDE_CHARACTER_LITERAL, ch, 1, "U") == 1) {
         rt.return_type = "const wchar_t*";
         rt.pointer_count = 1;
         return 0;
      }

      // .NET managed string literal S"Blah"
      if(pos(RE_MATCH_C_MANAGED_STRING_LITERAL, ch, 1, "U") == 1) {
         rt.return_type = "System/String";
         return 0;
      }

      // Is this a string literal? "Blah"
      if(pos(RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL, ch, 1, "UI") == 1) {
         if(_LanguageInheritsFrom('d')) {
            rt.return_type = "char";
            rt.pointer_count = 1;
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         } else if(_LanguageInheritsFrom('c')) {
            rt.return_type = "const char*";
            rt.pointer_count = 1;
         } else if(_LanguageInheritsFrom('cs')) {
            rt.return_type = "System/String";
         } else if(_LanguageInheritsFrom('java')) {
            rt.return_type = "String";
         }
         return 0;
      }

      // Unix regular expression matching java unicode literal. This is 
      // a single quoted \u followed by a hexadecimal number.
      // For example '\uABCD'
      if(pos(RE_MATCH_UNICODE_LITERAL, ch, 1, "UI") == 1) {
         if (_LanguageInheritsFrom('d')) {
            rt.return_type = "wchar";
         } else if(_LanguageInheritsFrom('c')) {
            rt.return_type = "wchar_t";
         } else {
            rt.return_type = "char";
         }
         return 0;
      }

      // Is this a character literal?
      // Match any number of characters in the single quoted string to
      // catch '\0' and typos. 
      if(pos(RE_MATCH_C_SINGLE_QUOTED_CHAR_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "char";
         return 0;
      }
   }

   // Floating point literal check 5.1f. Make sure there is a dot somewhere before deciding it is float.
   if(pos(RE_MATCH_C_FLOATING_POINT_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
      rt.return_type = "float";
      return 0;
   }

   // Double 5.1. Make sure there is a dot somewhere before deciding it is float.
   if(pos(RE_MATCH_C_DOUBLE_PRECISION_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
      rt.return_type = "double";
      return 0;
   }

   // Hexadecimal unsigned long 0xBADF00DLU or decimal unsigned long 550ul
   if(pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1 ||
      pos(RE_MATCH_C_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1) {
      rt.return_type = "unsigned long";
      return 0;
   }

   // Hexadecimal long 0xBADF00DL or decimal long 550l
   if(pos(RE_MATCH_C_HEXADECIMAL_LONG_LITERAL, ch, 1, "UI") == 1 ||
      pos(RE_MATCH_C_LONG_LITERAL, ch, 1, "UI") == 1) {
      rt.return_type = "long";
      return 0;
   }

   // Hexadecimal unsigned int 0xBadF00dU or decimal unsigned int 550U
   if(pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1 ||
      pos(RE_MATCH_C_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1) {
      rt.return_type = "unsigned int";
      return 0;
   }

   // Hexadecimal int 0xBadF00d or decimal int 550
   if(pos(RE_MATCH_C_HEXADECIMAL_INT_LITERAL, ch, 1, "UI") == 1 ||
      pos(RE_MATCH_C_INT_LITERAL, ch, 1, "UI") == 1) {
      rt.return_type = "int";
      return 0;
   }

   // Boolean constant
   if(ch:=='true' || ch:=='false') {
      if(_LanguageInheritsFrom('e')) {
         rt.return_type = "boolean";
      } else {
         rt.return_type = "bool";
      }
      return 0;
   }

   // Boolean constant
   if(ch:=='null' || ch:=='NULL') {
      rt.return_type = "void";
      rt.pointer_count = 1;
      return 0;
   }

   rt = orig_rt;
   return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
}

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
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _c_get_type_of_part(_str (&errorArgs)[], typeless tag_files, boolean isjava,
                               _str &previous_id, _str ch,
                               _str &prefixexp, _str &full_prefixexp,
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0,
                               int prefix_flags=0)
{
   if (_chdebug) {
      isay(depth,"_c_get_type_of_part: ===================================================");
      isay(depth,"_c_get_type_of_part(prev_id="previous_id", ch="ch", prefixexp="prefixexp",full_prefixexp="full_prefixexp", depth="depth")");
   }

   // was the previous identifier a builtin type?
   _str current_id = previous_id;
   boolean previous_builtin = false;
   if (_c_is_builtin_type(previous_id)) {
      previous_builtin=true;
   }

   // number of arguments in paren or brackets group
   int status = 0;
   int num_args = 0;
   _str cast_type = '';

   // is the current token a builtin?
   if (_c_is_builtin_type(ch)) {
      if (rt.return_type=='' && _LanguageInheritsFrom('d')) {
         rt.return_type = _c_get_boxing_conversion(ch);
         if (rt.return_type != '') {
            return 0;
         }
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
   case '->':     // pointer to member
      if (previous_id != '') {
         status = _c_get_return_type_of(errorArgs, tag_files,
                                        previous_id, rt.return_type, 0,
                                        isjava, VS_TAGFILTER_ANYDATA,
                                        false, false, rt, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_c_get_type_of_part: ID -> FOUND, match_class="rt.return_type" pointer_count="rt.pointer_count" status="status);
         }
         if (status) {
            return status;
         }
         previous_id = '';
      }
      if (_chdebug) {
         isay(depth, "_c_get_type_of_part: -> FOUND, pointer_count="rt.pointer_count);
      }
      if (rt.pointer_count != 1) {
         if (rt.pointer_count < 1) {
            if (!(isjava && !_LanguageInheritsFrom('cs')) && !_LanguageInheritsFrom('pl') && !_LanguageInheritsFrom('phpscript') && !_LanguageInheritsFrom('e')) {
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: TRYING TO FIND OPERATOR ->");
               }
               _str unusedErrorArgs[];
               status = _c_get_return_type_of(unusedErrorArgs,tag_files,
                                              '->', rt.return_type, 0,
                                              false, VS_TAGFILTER_ANYPROC,
                                              false, false, rt, visited, depth+1);
               if (_chdebug ) {
                  isay(depth, "_c_get_type_of_part: OPERATOR ->, match_class="rt.return_type);
               }
               if (status) {
                  rt.return_type='';
               }
               previous_id = '';
            }
            if (_LanguageInheritsFrom('pl')) {
               rt.pointer_count=0;
            } else if (rt.return_type == '') {
               errorArgs[1] = '->';
               errorArgs[2] = current_id;
               return (VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER);
            } else if (rt.pointer_count > 0) {
               rt.pointer_count--;
            }
            break;
         } else {
            if (_LanguageInheritsFrom('e') && substr(prefixexp,1,1)=='[') {
               --rt.pointer_count;
               break;
            }
            errorArgs[1] = '->';
            errorArgs[2] = current_id;
            return (VSCODEHELPRC_DASHGREATER_FOR_PTR_TO_POINTER);
         }
      }
      rt.pointer_count = 0;
      break;

   case '.':     // member access operator
      //isay(depth, "_c_get_type_of_part: DOT");
      if (_LanguageInheritsFrom('d') && previous_id == '' && rt.return_type=='') {
         tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                 auto cur_type_name, auto cur_type_id, 
                                 auto cur_context, auto cur_class, auto cur_package);
         rt.return_type = cur_package; 
      }
      if (previous_id != '') {
         //isay(depth, "_c_get_type_of_part(DOT): before previous_id="previous_id" match_class="rt.return_type);
         VS_TAG_RETURN_TYPE orig_rt = rt;
         status = _c_get_return_type_of(errorArgs, tag_files,
                                        previous_id, rt.return_type, 0, isjava,
                                        VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ENUM|VS_TAGFILTER_TYPEDEF|VS_TAGFILTER_PACKAGE,
                                        true, false, rt, visited, depth+1);
         // special case for array, hash tables in slick-C, javascript
         //say("status="status" p_mode_name="p_mode_name" c-return_flags="c_return_flags);
         // unknown variable used in slick-c 'DOT' expression, then just skip it
         if (_LanguageInheritsFrom('e') &&
             depth < VSCODEHELP_MAXRECURSIVETYPESEARCH &&
             (status == VSCODEHELPRC_BUILTIN_TYPE ||
              status == VSCODEHELPRC_NO_SYMBOLS_FOUND)) {
            return _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, 0);
         } 

         if (status == 0 && _LanguageInheritsFrom('c')) {
            // Special case for C++/CLI "enum class/struct" - 
            // for these types of enums, 'EnumNAme.ValueName'
            // is not valid syntax for referring to the values.
            // (EnumName::ValueName is the correct way).
            int tg_flags;
            _str a, b, c;

            tag_tree_decompose_tag(rt.taginfo, a, b, c, tg_flags);
            if (tg_flags & VS_TAGFLAG_opaque) {
               // Not perfect, but retrying while excluding enums should
               // work in most cases.
               rt = orig_rt;
               status = _c_get_return_type_of(errorArgs, tag_files,
                                              previous_id, rt.return_type, 0, isjava,
                                              VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ANYDATA|VS_TAGFILTER_TYPEDEF|VS_TAGFILTER_PACKAGE,
                                              true, false, rt, visited, depth+1);
            }
            
         }

         if (status) {
            return status;
         }
         previous_id = '';
         //isay(depth, "_c_get_type_of_part(DOT): after previous_id="previous_id" match_class="rt.return_type" pointer_count="rt.pointer_count);
      }
      //isay(depth, "_c_get_type_of_part: xxx");
      if (rt.pointer_count > 0) {
         //say("checking pointer count > 0");
         if (_LanguageInheritsFrom('js') || _LanguageInheritsFrom('cfscript')) {
            rt.return_type = "Array";
            rt.pointer_count = 0;
         } else if (_LanguageInheritsFrom('java')) {
            rt.return_type = "java/lang/Object";
            rt.pointer_count = 0;
         } else if (_LanguageInheritsFrom('cs')) {
            rt.return_type = "System/Array";
            rt.pointer_count = 0;
         } else if (_LanguageInheritsFrom('d') && (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
            rt.return_type = "__ARRAY_TYPE";
            rt.pointer_count = 0;
         } else if (_LanguageInheritsFrom('d') && rt.pointer_count==1) {
            // can use '.' even for pointer types in D language
            rt.pointer_count = 0;
         } else if (_LanguageInheritsFrom('e')) {
            //say("_c_get_type_of_part(): flags="c_return_flags" pointer="pointer_count);
            if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) {
               if (rt.pointer_count==1 && (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
                  rt.return_type = '_hashtable';
                  rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE;
               } else if (rt.pointer_count==2 && (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
                  rt.return_type = '_hashtable';
                  if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE2) {
                     rt.return_flags |= VSCODEHELP_RETURN_TYPE_HASHTABLE;
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_HASHTABLE2;
                  }
               } else {
                  rt.return_type = '_array';
               }
               if (rt.pointer_count==1) {
                  rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY;
               }
               rt.pointer_count = 0;
            } else {
               errorArgs[1] = '.';
               errorArgs[2] = current_id;
               return(VSCODEHELPRC_DOT_FOR_POINTER);
            }
         } else if (_LanguageInheritsFrom('systemverilog') && (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
            rt.return_type = "__ARRAY_TYPE";
            rt.pointer_count = 0;

         } else if (_LanguageInheritsFrom('m') && rt.pointer_count==1) {
            // TODO: handle '.' syntax for matching selectors (getter/setter type)
            errorArgs[1] = '.';
            errorArgs[2] = current_id;
            return(VSCODEHELPRC_DOT_FOR_POINTER);

         } else {
            errorArgs[1] = '.';
            errorArgs[2] = current_id;
            return(VSCODEHELPRC_DOT_FOR_POINTER);
         }
      } else if (rt.pointer_count < 0) {
         // maybe they overloaded operator *
         if (rt.pointer_count==-1 && _LanguageInheritsFrom('c')) {
            //isay(depth,"_c_get_type_of_part: TRYING TO FIND OPERATOR *");
            status = _c_get_return_type_of(errorArgs,tag_files,
                                           '*', rt.return_type, 0,
                                           false, VS_TAGFILTER_ANYPROC,
                                           false, false, rt, visited, depth+1);
            if (status) {
               errorArgs[1] = full_prefixexp;
               return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
            }
            previous_id = '';
         } else {
            errorArgs[1] = full_prefixexp;
            return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
         }
      }
      break;

   case '::':    // static member or global scope indicator
      //say(":: previous_id="previous_id" match_class="match_class);
      if (previous_id == '' && rt.return_type=='') {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         rt.return_type = '::';
         //say("XX match_class=::");
      } else if (previous_id != '') {
         typeless orig_rt = rt;
         status = _c_get_return_type_of(errorArgs, tag_files,
                                        previous_id, rt.return_type, 0,
                                        isjava, VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_PACKAGE,
                                        true, false, rt, visited, depth+1);
         //say(":: match_class="rt.return_type" status="status);
         if (status) {
            rt = orig_rt;
         }

         if (status && _LanguageInheritsFrom('c')) {
            // Check for C++/CLI "enum class" or "enum stuct" case
            // where we want to access enum members via ::
            status = _c_get_return_type_of(errorArgs, tag_files,
                                           previous_id, rt.return_type, 0,
                                           isjava, VS_TAGFILTER_ENUM,
                                           true, false, rt, visited, depth+1);

            if (!status) {
               _str tg_name, cl_name, ty_name;
               int tg_flags = 0;

               tag_tree_decompose_tag(rt.taginfo, tg_name, cl_name, ty_name, tg_flags);
               if (!(tg_flags & VS_TAGFLAG_opaque)) {
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
         if (status && tag_check_for_typedef(previous_id, tag_files, true, rt.return_type)) {
            //say(previous_id" is a typedef");
            int orig_const_only    = (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
            int orig_volatile_only = (rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY);
            int orig_is_array      = (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES);
            status = _c_get_return_type_of(errorArgs, tag_files,
                                           previous_id, rt.return_type, 0,
                                           isjava, VS_TAGFILTER_TYPEDEF,
                                           true, false, rt, visited, depth+1);
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
            rt.return_type='';
            return status;
         }
         previous_id = '';
      } else {
         //say(":: already processed previous ID");
      }
      break;

   case 'new':   // new keyword
   case 'gcnew': // managed C++
      // special case for Python
      if (_LanguageInheritsFrom('py')) {
         rt.return_type = ch;
         rt.taginfo = 'new(package)';
         break;
      }
      // Just ignore 'new' if we don't know what to do with it
      if (depth<=1 && !pos('[(.-]',prefixexp,1,'r')) {         
         break;
      }
      if (isjava && previous_id=='') break;
      int p = pos('^(:b)*{:v|'_clex_identifier_re()'}(:b)*', prefixexp, 1, 'r');
      if (!p) {
         // this is not good news...
         //say("return from new");
         errorArgs[1] = 'new ' prefixexp;
         return VSCODEHELPRC_INVALID_NEW_EXPRESSION;
      }
      ch = substr(prefixexp, pos('S0'), pos('0'));
      prefixexp = substr(prefixexp, p+pos(''));
      rt.return_type = ch;
      if (substr(prefixexp, 1, 1):=='(') {
         prefixexp = substr(prefixexp, 2);
         _str parenexp;
         if (!match_parens(prefixexp, parenexp, num_args)) {
            // this is not good
            //say("return from new 2");
            errorArgs[1] = 'new 'ch' 'prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
      }
      previous_id = '';
      if (!isjava && !_LanguageInheritsFrom('js') && !_LanguageInheritsFrom('e')) {
         rt.pointer_count=1;
      }
      break;

   case ':[':
   case '[':
      if (_LanguageInheritsFrom('m') && previous_id == '' && rt.return_type == '') {
         match_generic(prefixexp, auto bracketexp, num_args, '[],');
         status = _c_get_type_of_expression(errorArgs, tag_files, bracketexp, rt, visited, depth+1, VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE);
         if (status) {
            return status;
         }
         previous_id = '';
         break;
      }

      // handle slick-c hash tables
      boolean slickc_hash_table=false;
      if (_LanguageInheritsFrom('e') && ch==':[') {
         slickc_hash_table=true;
         //prefixexp=substr(prefixexp,2);
      }

      if (!match_brackets(prefixexp, num_args)) {
         // this is not good
         //say("return from [");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (previous_id != '') {
         current_id = previous_id;
         status = _c_get_return_type_of(errorArgs, tag_files,
                                        previous_id, rt.return_type, 0,
                                        isjava, VS_TAGFILTER_ANYDATA,
                                        false, false, rt, visited, depth+1);
         if (status) {
            return status;
         }
         previous_id = '';
      }
      if (rt.pointer_count <= 0) {
         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_ARRAY_TYPES;
            break;
         }
         if (!isjava || 
             _LanguageInheritsFrom('cs') || 
             _LanguageInheritsFrom('d')  ||
             _LanguageInheritsFrom('e')) {
            //say("TRYING TO FIND OPERATOR []");
            _str array_operator_name = "[]";
            if (_LanguageInheritsFrom('d')) {
               array_operator_name = "opIndex";
            } else if (_LanguageInheritsFrom('e')) {
               if (slickc_hash_table) {
                  array_operator_name = "_hash_el";
               } else {
                  array_operator_name = "_array_el";
               }
            }
            status = _c_get_return_type_of(errorArgs,tag_files,
                                           array_operator_name, rt.return_type, 0,
                                           false, VS_TAGFILTER_ANYPROC,
                                           false, false, rt, visited, depth+1);
            if (status) {
               return status;
            }
            previous_id = '';
         }
         if (rt.return_type == '') {
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

   case ']':     // array subscript close
      // what do I do here?
      break;

   case '(':     // function call, cast, or expression grouping
      if (!match_parens(prefixexp, cast_type, num_args)) {
         // this is not good
         //say("return from (");
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_PARENTHESIS_MISMATCH;
      }
      if (_chdebug) {
         isay(depth,"_c_get_type_of_part: PAREN cast_type="cast_type" previous_id="previous_id);
      }
      if (previous_id != '') {
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
            }
            orig_rt := rt;
            boolean filterFunctionSignatures = (prefixexp != '' && (_GetCodehelpFlags() & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS) != 0);
            status = _c_get_return_type_of(errorArgs,tag_files,previous_id,
                                           rt.return_type, num_args, isjava,
                                           VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYDATA,
                                           false, filterFunctionSignatures,
                                           rt, visited, depth+1);
            if (!filterFunctionSignatures && 
                prefixexp != "" && 
                status == VSCODEHELPRC_OVERLOADED_RETURN_TYPE) {
               rt = orig_rt;
               filterFunctionSignatures = true;
               status = _c_get_return_type_of(errorArgs,tag_files,previous_id,
                                              rt.return_type, num_args, isjava,
                                              VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYDATA,
                                              false, filterFunctionSignatures,
                                              rt, visited, depth+1);
            }
            boolean is_py_constructor=false;
            if (_LanguageInheritsFrom('py') && rt.return_type=='' && orig_rt.return_type!='') {
               /*
                   Handle the following case:

                   x=mypackage.myclass() --> translate to mypackage/myclass
               */
               is_py_constructor=true;
               rt.return_type=orig_rt.return_type:+VS_TAGSEPARATOR_package:+previous_id;
            }
            _str new_match_class=rt.return_type;
            rt.return_type=orig_rt.return_type;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: PAREN AFTER ID status="status" pointer_count="rt.pointer_count" match_tag="rt.taginfo);
            }
            if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND &&
                status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
               return status;
            }
            // did we find a variable of a function or function pointer?
            boolean is_function=false;
            if (rt.taginfo != '') {
               _str ts='',tr='',tn='',cn='',tt='';
               int tf=0;
               tag_tree_decompose_tag(rt.taginfo, tn,cn,tt,tf,ts,tr);
               if (tag_tree_type_is_func(tt) || pos('(',tr)) {
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
            if (/*!isjava &&*/ new_match_class == '') {
               int num_matches = 0;
               tag_list_symbols_in_context(previous_id, rt.return_type, 0, 0, 
                                           tag_files, '', 
                                           num_matches, def_tag_max_find_context_tags, 
                                           VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_TYPEDEF,
                                           VS_TAGCONTEXT_ALLOW_locals | VS_TAGCONTEXT_FIND_all,
                                           true, true, visited, depth, rt.template_args);

               if (num_matches > 0) {
                  if (_chdebug) {
                     isay(depth, "_c_get_type_of_part: PAREN AFTER ID "previous_id" is a struct or typedef");
                  }
                  status = _c_parse_return_type(errorArgs, tag_files,
                                                '', '', p_buf_name,
                                                previous_id, isjava, rt, 
                                                visited, depth+1);
                  if (!status) {
                     is_function = true;
                  }
               } else if (rt.return_type != '') {
                  rt.pointer_count = 0;
               }
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID match_class="rt.return_type" status="status" pointer_count="rt.pointer_count);
               }
            } else {
               rt.return_type = new_match_class;
               previous_id='';
            }
            // maybe they have function call operator
            if (!is_py_constructor && !isjava && rt.return_type!='' && status && !is_function) {
               status = _c_get_return_type_of(errorArgs,tag_files,'()',
                                              rt.return_type, num_args,
                                              isjava, VS_TAGFILTER_ANYPROC,
                                              false, false, rt, visited, depth+1);
               if (status && 
                   status != VSCODEHELPRC_BUILTIN_TYPE &&
                   status != VSCODEHELPRC_NO_SYMBOLS_FOUND) {
                  return status;
               }
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: PAREN AFTER ID match_class="rt.return_type" status="status" pointer="rt.pointer_count);
               }
            }
            previous_id = '';
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

         } else if (pos("([-][>]|[.])[*]", cast_type, 1, 'r') && pos('(',prefixexp)==1) {

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
                                             '', '', p_buf_name,
                                             cast_type, isjava, 
                                             rt, visited, depth+1);
               if (_chdebug) {
                  isay(depth, "_c_get_type_of_part: CAST match_class="rt.return_type" prefixexp="prefixexp" cast_type="cast_type" status="status);
               }
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
               previous_id='';
               return status;
            }
            // otherwise, just ignore the cast

         } else if (!pos('(',cast_type) && pos(',',cast_type)) {

            // this looks like an argument list, check for operator function call.
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a function call operator");
            }
            status = _c_get_return_type_of(errorArgs,tag_files,'()',
                                           rt.return_type, num_args,
                                           isjava, VS_TAGFILTER_ANYPROC,
                                           false, false, rt, visited, depth+1);
            if (status) {
               return status;
            }

         } else if (pos('^[ \t]*new[ \t]',cast_type,1,'re')) {

            // object creation expression
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's a new expression");
            }
            parse cast_type with 'new' cast_type;
            status = _c_parse_return_type(errorArgs, tag_files,
                                          '', '', p_buf_name,
                                          cast_type, isjava, 
                                          rt, visited, depth+1);
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: NEW: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type" status="status);
            }
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            prefixexp='';
            if (status) {
               return status;
            }
         } else {
            // not a cast, must be an expression, go recursive
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: CAST PAREN think it's an expression, cast_type="cast_type);
            }
            status = _c_get_type_of_expression(errorArgs, tag_files, cast_type, rt, visited, depth+1, 0);
            if (status) {
               return status;
            }
            if (_chdebug) {
               isay(depth, "_c_get_type_of_part: EXPR: match_class="rt.return_type"prefixexp="prefixexp" cast_type="cast_type);
            }
         }
      }
      break;

   case ')':
      // what do I do here?
      errorArgs[1] = full_prefixexp;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;

   case '$this':
   case 'this':
      if (_LanguageInheritsFrom('phpscript') && ch=='$this') {
         ch='this';
      }
      status = _c_get_return_type_of(errorArgs, tag_files, ch, '', 0,
                                     isjava, VS_TAGFILTER_ANYDATA,
                                     false, false, rt, visited, depth+1);
      if (status) {
         return status;
      }
      previous_id = '';
      if (!isjava && 
          !_LanguageInheritsFrom('js') &&
          !_LanguageInheritsFrom('as') &&
          !_LanguageInheritsFrom('e') &&
          !_LanguageInheritsFrom('vera') &&
          !_LanguageInheritsFrom('systemverilog')) {
         rt.pointer_count = 1;
      }
      break;

   case '->*':   // pointer to member function
   case '.*':    // binds left-to-right, type of rhs is result
      previous_id = '';
      rt.return_type='';
      break;

   case '*':     // dereference pointer
   case '&':     // get reference to object
      if (!isjava) {
         // test if this is a unary operator
         if (prefixexp != '' && substr(full_prefixexp,2) == prefixexp) {
            status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth+1, 0);
            if (!status) {
               if (ch :== '*' && rt.pointer_count > 0) {
                  rt.pointer_count--;
                  prefixexp = '';
                  break;
               } else if (ch :== '*') {
                  VS_TAG_RETURN_TYPE star_rt = rt;
                  status = _c_get_return_type_of(errorArgs, tag_files, ch,
                                                 rt.return_type, 0, isjava,
                                                 VS_TAGFILTER_ANYPROC, false, false,
                                                 star_rt, visited, depth+1);
                  if (!status) {
                     rt = star_rt;
                     prefixexp = '';
                     break;
                  } else {
                     errorArgs[1] = '*';
                     errorArgs[2] = prefixexp;
                     return (VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER);
                  }
               } else if (ch :== '&') {
                  rt.pointer_count++;
                  break;
               }
            }
         }
      }
      // drop through to operator overloading case

   case '<':
   case '!(':
      _str templateexp='';
      if ((ch:=='<' && match_generic(prefixexp, templateexp, num_args, '<>,') && previous_id :!= '') ||
          (ch:=='!(' && match_generic(prefixexp, templateexp, num_args, '(),') && previous_id :!= '')) {
         parameterizedProcOrVar := false;
         int orig_globals_only = (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY);
         status = _c_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type,
                                        0, isjava, VS_TAGFILTER_ANYSTRUCT, true, false, 
                                        rt, visited, depth+1);
         if (status) {
            status = _c_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type,
                                           0, isjava, VS_TAGFILTER_ANYPROC|VS_TAGFILTER_ANYDATA, 
                                           true, false, rt, visited, depth+1);
            parameterizedProcOrVar = (status==0);
         }
         //say("<> match_class="rt.return_type" status="status" prefixexp="prefixexp" istemplate="rt.istemplate);
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         rt.return_flags |= orig_globals_only;

         // set up rt.template_args with the template arguments
         if (!status && rt.taginfo!='') {
            _str template_name='';
            _str template_class='';
            _str template_args='';
            _str template_type='';
            _str template_return='';
            _str template_sig='';
            int template_flags=0;
            tag_tree_decompose_tag(rt.taginfo,template_name,template_class,template_type,template_flags,template_args,template_return,template_sig);
            if (template_sig != '' && template_args == '') {
               template_args = template_sig;
            }
            if (template_return != "" && rt.return_type=='') {
               rt.return_type = template_return;
            }

            if ((template_flags & VS_TAGFLAG_template)) {
               // first parse out the argument values
               _str arg_vals[];arg_vals._makeempty();
               int val_pos=0;
               _str arg_value = '';
               tag_get_next_argument(templateexp, val_pos, arg_value);
               while (arg_value !='') {
                  arg_vals[arg_vals._length()]=arg_value;
                  tag_get_next_argument(templateexp, val_pos, arg_value);
               }
               val_pos=0;
               // now parse out the argument names
               int arg_pos=0;
               _str arg_name = '';
               tag_get_next_argument(template_args, arg_pos, arg_name);
               while (arg_name !='') {
                  rt.istemplate=true;
                  _str arg_default='';
                  parse arg_name with arg_name '=' arg_default;
                  arg_value=(val_pos < arg_vals._length())? arg_vals[val_pos]:'';
                  if (arg_value=='') {
                     if (arg_default!='') {
                        arg_value=arg_default;
                     } else if (_LanguageInheritsFrom('java')) {
                        arg_value='java.lang.Object';
                     }
                  }
                  //isay(depth,"_c_get_type_of_part: %%%%%%%%%%%%%%%%%%%%%%");
                  //isay(depth,"_c_get_type_of_part: "arg_name" --> "arg_value);
                  if (pos("class ", arg_name)==1) arg_name = substr(arg_name,7);
                  rt.template_names[rt.template_names._length()]=arg_name;
                  rt.template_args:[arg_name]=arg_value;
                  tag_get_next_argument(template_args, arg_pos, arg_name);
                  val_pos++;
               }
            }
            if (parameterizedProcOrVar && rt.return_type != null && rt.return_type != '') {
               // substitute template arguments
               for (ti := 0; ti < rt.template_names._length(); ++ti) {
                  ta := rt.template_names[ti];
                  tt := rt.template_args:[ta];
                  if (rt.template_types._indexin(ta)) {
                     tt = tag_return_type_string(rt.template_types:[ta],false);
                  } else {
                     struct VS_TAG_RETURN_TYPE template_rt;
                     tag_return_type_init(template_rt);
                     _c_parse_return_type(errorArgs, tag_files, 
                                          template_name, '', p_buf_name,
                                          tt, isjava, template_rt, 
                                          visited, depth+1);
                     rt.template_types:[ta] = template_rt;
                     tt = tag_return_type_string(rt.template_types:[ta],false);
                  }
                  rt.return_type = stranslate(rt.return_type, tt, ta, 'ew');
               }
            }
         }
         if (!status) {
            if (!parameterizedProcOrVar) {
               previous_id = '';
            }
            break;
         }
      }
      // drop through to operator overloading case

   case '=':     // binary operators within expression
   case '-':
   case '+':
   case '/':
   case '%':
   case '^':
   case '<<':
   case '>>':
   case '&&':
   case '|':
   case '||':
   case '<=':
   case '>=':
   case '==':
   case '>':   // '<' is needed for templates, above
      if (depth <= 0) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (!isjava) {
         if (previous_id != '') {
            rt.taginfo = '';
            status = _c_get_return_type_of(errorArgs, tag_files,
                                           previous_id, rt.return_type, 0,
                                           isjava, VS_TAGFILTER_ANYDATA,
                                           false, false, rt, visited, depth+1);
            if (status) {
               return status;
            }
            previous_id = '';
         }
         // check for operator overloading
         VS_TAG_RETURN_TYPE last_return_type = rt;
         if (rt.return_type != '') {
            _str orig_match_class=rt.return_type;
            status = _c_get_return_type_of(errorArgs, tag_files, ch, rt.return_type, 0,
                                           isjava, VS_TAGFILTER_ANYPROC, false, false, 
                                           rt, visited, depth+1, VS_TAGCONTEXT_NO_globals);
            if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND) {
               rt.return_type=orig_match_class;
               return status;
            }
         }
         if (rt.return_type == '') {
            // For now just go back to the type of the lhs side of this expression if operator lookup fails.
            rt = last_return_type;
            //errorArgs[1] = full_prefixexp;
            //return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
         }
         prefixexp = '';  // breaks us out of loop
      }
      break;

   case "const_cast":
   case "static_cast":
   case "dynamic_cast":
   case "reinterpret_cast":
      // check for C++ style cast expressions
      if (_LanguageInheritsFrom("c") && (ch=="static_cast" || ch=="dynamic_cast" || ch=="reinterpret_cast" || ch=="const_cast")) {
         cast_ch := ch;
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part: found C++ style cast expression: "ch);
         }
         orig_prefixexp := prefixexp;
         prefixexp = strip(prefixexp, "L");
         if (first_char(prefixexp) == '<') {
            prefixexp = substr(prefixexp, 2);
            num_type_args := 0;
            if (match_generic(prefixexp, cast_type, num_type_args, "<>,")) {
               prefixexp = strip(prefixexp, "L");
               if (first_char(prefixexp) == '(') {
                  prefixexp = substr(prefixexp, 2);
                  cast_expression := "";
                  num_cast_args := 0;
                  if (match_generic(prefixexp, cast_expression, num_cast_args, "(),")) {
                     ch = ')';
                     previous_id = "";
                     if (cast_type == "" && cast_ch=="const_cast" && cast_expression != "") {
                        // support type-inferred const_cast<> expression
                        status = _c_get_type_of_expression(errorArgs, tag_files, 
                                                           cast_expression, 
                                                           rt, visited, depth+1, 0);
                        rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
                        rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
                     } else {
                        status = _c_parse_return_type(errorArgs, tag_files,
                                                      '', '', p_buf_name,
                                                      cast_type, isjava, 
                                                      rt, visited, depth+1);
                     }
                     rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
                     if (_chdebug) {
                        isay(depth,"_c_get_type_of_part: prefixexp="prefixexp" ch="ch" status="status);
                        tag_return_type_dump(rt, "_c_get_type_of_part(C++ cast)", depth);
                     }
                     return status;
                  }
               }
            }
            prefixexp = orig_prefixexp;
         }
      }
      // drop through, treat it as a an identifier

   case 'self':
      if (ch:=='self' && 
          (_LanguageInheritsFrom('py') ||
           _LanguageInheritsFrom('lua') ||
           _LanguageInheritsFrom('m'))
         ) {
         status = _c_get_return_type_of(errorArgs, tag_files, 'this', '', 0,
                                        isjava, VS_TAGFILTER_ANYDATA,
                                        false, false, rt, visited, depth+1);
         if (status) {
            return status;
         }
         previous_id = '';
         if (_LanguageInheritsFrom('m')) {
            rt.pointer_count=1;
         } else {
            rt.pointer_count=0;
         }
         break;
      }
      // drop through, treat it as a an identifier

   case 'base':
   case 'super':
      if (((isjava ||
            _LanguageInheritsFrom('m') ||
            _LanguageInheritsFrom('vera') ||
            _LanguageInheritsFrom('systemverilog'))
           && ch:=='super') ||
          (_LanguageInheritsFrom('cs') && ch:=='base')) {
         status = _c_get_return_type_of(errorArgs, tag_files, 'this', '', 0,
                                        isjava, VS_TAGFILTER_ANYDATA,
                                        false, false, rt, visited, depth+1);
         if (status) {
            return status;
         }
         _str tag_dbs='';
         _str parents = cb_get_normalized_inheritance(rt.return_type, tag_dbs, tag_files, true, '', p_buf_name);
         //say("_c_get_type_of_part: parents="parents" match_class="rt.return_type);
         //parse parents with match_class ';' parents;
         // add each of them to the list also
         while (parents != '') {
            _str p1, t1;
            parse parents with p1 ';' parents;
            parse tag_dbs with t1 ';' tag_dbs;
            if (t1!='') {
               status = tag_read_db(t1);
               if (status < 0) {
                  continue;
               }
            }
            // add transitively inherited class members
            _str outer_class='';
            parse p1 with p1 '<' .;
            parse p1 with p1 '!(' .;
            tag_split_class_name(p1, rt.return_type, outer_class);
            if (t1!='') {
               status = tag_find_tag(rt.return_type, 'class', outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
               status = tag_find_tag(rt.return_type, 'interface', outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
            } else {
               status = tag_find_context_iterator(rt.return_type,true,true,false,outer_class);
               if (status > 0) {
                  rt.return_type = p1;
                  break;
               }
            }

            // try other tag files
            int i;
            for (i=0;;) {
               t1 = next_tag_filea(tag_files,i,false,true);
               tag_reset_find_tag();
               if (t1=='') {
                  break;
               }
               status = tag_find_tag(rt.return_type, 'class', outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
               status = tag_find_tag(rt.return_type, 'interface', outer_class);
               tag_reset_find_tag();
               if (!status) {
                  rt.return_type = p1;
                  break;
               }
            }
            if (!status && t1 != '') {
               break;
            }
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         previous_id = '';
         break;
      }
      // drop through, treat as a plain identifier

   case 'class':
      if (isjava && ch:=='class' && !_LanguageInheritsFrom('cs')) {
         rt.return_type = "java/lang/Class";
         rt.pointer_count=0;
         rt.istemplate=false;
         rt.template_args._makeempty();
         rt.template_names._makeempty();
         rt.template_types._makeempty();
         rt.return_flags=0;
         rt.taginfo="Class(java/lang/class)";
         previous_id = '';
         break;
      }
      // drop through, treat as a plain identifier

   case 'outer':
      if (isjava && ch:=='outer') {
         status = _c_get_return_type_of(errorArgs, tag_files, 'this', '', 0,
                                        isjava, VS_TAGFILTER_ANYDATA,
                                        false, false, rt, visited, depth+1);
         if (status) {
            return status;
         }
         _str junk='';
         tag_split_class_name(rt.return_type, junk, rt.return_type);
         previous_id = junk;
         break;
      }
      // drop through and treat as a plain identifier

   case 'operator':
      if (!isjava && ch :== 'operator' && !_LanguageInheritsFrom('py')) {
         prefixexp = strip(prefixexp,'L');
         int pp = pos('(',prefixexp,2);
         if (pp > 0) {
            ch = strip(substr(prefixexp,1,pp-1));
            prefixexp = substr(prefixexp,pp+1);
            //say("***prefixexp="prefixexp" ch="ch);
            _str dummy_args='';
            if (!match_parens(prefixexp, dummy_args, num_args)) {
               // this is not good
               //say("return from (");
               errorArgs[1] = full_prefixexp;
               return VSCODEHELPRC_PARENTHESIS_MISMATCH;
            }
            status = _c_get_return_type_of(errorArgs, tag_files, ch,
                                           rt.return_type, num_args,
                                           isjava, VS_TAGFILTER_ANYPROC,
                                           false, false, rt, visited, depth+1);
            if (status) {
               return status;
            }
            previous_id='';
         } else {
            ch = strip(prefixexp);
            prefixexp='';
         }
         break;
      }
      // drop through, treat it as an identifier

   default:

      // is this a literal constant
      if (rt.return_type=='' && _c_get_type_of_constant(ch, rt) == 0) {
         if (_LanguageInheritsFrom('d') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('jsl')) {
            box_type := _c_get_boxing_conversion(rt.return_type);
            if (box_type != "") {
               rt.return_type = box_type;
            }
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part: CONSTANT ch="ch" type="rt.return_type);
         }
         return 0;
      }

      if (_LanguageInheritsFrom('m') &&
          (prefixexp :== '') &&
          (prefix_flags & VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE) &&
          (previous_id != '' || rt.return_type != '')) {
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C: ["full_prefixexp"]");
         }
         if (previous_id != '') {
            status = _c_get_return_type_of(errorArgs, tag_files,
                                           previous_id, rt.return_type, 0,
                                           isjava, VS_TAGFILTER_ANYDATA,
                                           true, false, rt, visited, depth+1);
            if (status) {
               return status;
            }
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C receiver: previous_id="previous_id" type="rt.return_type" pointer_count="rt.pointer_count);
         }
         if (rt.pointer_count != 1) {
            errorArgs[1] = current_id;
            return (VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT);
         }
         rt.pointer_count = 0;
         rt.taginfo = '';
         previous_id = ch;
         status = _c_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                        isjava, VS_TAGFILTER_PROC, false, false, rt, visited, depth+1);
         if (status) {
            return status;
         }
         if (_chdebug) {
            isay(depth,"_c_get_type_of_part:  Objective-C selector: previous_id="previous_id" type="rt.return_type);
         }
         previous_id = '';
         return 0;
      }

      // hack to handle C# and J# @keyword nonsense
      if (substr(ch,1,1)=='@' && (_LanguageInheritsFrom('cs') || _LanguageInheritsFrom('jsl'))) {
         ch=substr(ch,2);
      }
      // this must be an identifier (or drop-through case)
      rt.taginfo = '';
      previous_id = ch;
      int var_filters = VS_TAGFILTER_VAR|VS_TAGFILTER_PROPERTY;
      if (rt.return_type == '') {
         var_filters |= VS_TAGFILTER_LVAR|VS_TAGFILTER_GVAR;
      }
      if (rt.return_type=='' && (isjava || _LanguageInheritsFrom('pl') || _LanguageInheritsFrom('e'))) {
         // search ahead and try to match up package name
         _str package_name = previous_id;
         _str orig_prefix  = prefixexp;
         while (orig_prefix != '') {
            //say("package_name="package_name);
            int package_index = tag_check_for_package(previous_id, tag_files, true, true);
            if (package_index <= 0 && tag_check_for_package(package_name, tag_files, true, true)) {
               //isay(depth, "_c_get_type_of_part: package_name="package_name);
               rt.return_type = package_name;
               previous_id = '';
               prefixexp = orig_prefix;
            } else if (package_index > 0) {
               _str renamed_to='';
               if (package_index==1) {
                  tag_get_detail(VS_TAGDETAIL_return, renamed_to);
               } else {
                  tag_get_detail2(VS_TAGDETAIL_context_return, package_index-1, renamed_to);
               }
               if (renamed_to=='') {
                  renamed_to=package_name;
               }
               //say("_c_get_type_of_part: package_index="package_index" renamed_to="renamed_to);
               if (renamed_to!='' && tag_check_for_package(renamed_to, tag_files, true, true)) {
                  package_name = renamed_to;
               }
               //isay(depth, "_c_get_type_of_part: package_name="package_name);
               rt.return_type = package_name;
               previous_id = '';
               //say("found package "package_name);
               prefixexp = orig_prefix;
            }
            ch = _c_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch != '.' && ch != '::' &&
                (!_LanguageInheritsFrom('c') || !_LanguageInheritsFrom('pl') || ch != '->')) {
               break;
            }
            _str sepch=ch;
            ch = _c_get_expr_token(orig_prefix);
            //say("prefixexp = "orig_prefix" ch="ch);
            if (ch == '' || !isid_valid(ch)) {
               break;
            }
            package_name = package_name :+ sepch :+ ch;
         }
         // DJB (12-08-2005)
         // If the package lookahead turns up a single-level package name,
         // such as "System" in J#, pretend it didn't happen, because it
         // could also match an imported class name
         if (_LanguageInheritsFrom('jsl') && rt.return_type!='' && !pos('.',rt.return_type)) {
            previous_id = rt.return_type;
            rt.return_type = '';
         }
      }
      break;
   }

   // successful so far, cool.
   //isay(depth, "_c_get_type_of_part: success");
   return 0;
}

/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param tag_files      List of tag files to use
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param visited        (reference) prevent recursion, cache results
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_expression(_str (&errorArgs)[], typeless tag_files,
                              _str expr, struct VS_TAG_RETURN_TYPE &rt,
                              struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0,
                              int prefix_flags=0)
{
   int ref_count = 0;
   while (substr(expr,1,1) == '&' || substr(expr,1,1) == '*') {
      if (substr(expr,1,1) == '&') {
         ref_count++;
      } else {
         ref_count--;
      }
      expr = strip(substr(expr, 2));
   }
   int status = _c_get_type_of_prefix_recursive(errorArgs, tag_files,
                                                expr, rt, 
                                                visited, depth+1, prefix_flags);
   if (!status) rt.pointer_count += ref_count;
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
 * @param errorArgs      List of argument for codehelp error messages
 * @param tag_files      List of tag files to use
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param visited        (reference) prevent recursion, cache results
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_prefix_recursive(_str (&errorArgs)[], typeless tag_files,
                                    _str prefixexp, struct VS_TAG_RETURN_TYPE &rt,
                                    struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0,
                                    int prefix_flags=0)
{
   if (_chdebug) {
      isay(depth,"_c_get_type_of_prefix: ===================================================");
      isay(depth,"_c_get_type_of_prefix("prefixexp")");
   }

   // Is this Java source code or something very similar?
   boolean isjava=(_LanguageInheritsFrom('java') ||
                   _LanguageInheritsFrom('cs') ||
                   _LanguageInheritsFrom('d') ||
                   _LanguageInheritsFrom('cfscript'));

   // initiialize return values
   int status = 0;
   rt.return_type   = '';
   rt.pointer_count = 0;
   rt.return_flags  = 0;

   // loop variables
   _str     full_prefixexp  = prefixexp;
   _str     previous_id     = '';
   boolean  found_define    = false;

   // save the arguments, for retries later
   VS_TAG_RETURN_TYPE orig_rt = rt;
   _str     orig_prefixexp       = prefixexp;
   _str     orig_previous_id     = previous_id;

   // process the prefix expression, token by token, delegate
   // most of processing to recursive func _c_get_type_of_part
   while (prefixexp != '') {

      // get next token from expression
      _str ch = _c_get_expr_token(prefixexp);
      if (_chdebug) isay(depth, "parsed "ch", remaining:"prefixexp);

      if (ch == '') {
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
            if (id_arglist != "" && first_char(prefixexp) == "(" && pos(")",prefixexp) > 0) {
               if (_chdebug) {
                  isay(depth,"_c_get_type_of_prefix_recursive: expanding #define "ch"("id_arglist") "id_defined_to);
               }
               define_parenexp := "";
               define_arg_name  := "";
               define_arg_value := "";
               define_num_args := 0;
               define_cur_arg  := 0;
               argnames_pos := 0;
               arglist_pos := 0;
               prefixexp = substr(prefixexp,2);
               match_parens(prefixexp,define_parenexp,define_num_args);
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
            define_status := _c_get_type_of_prefix_recursive(errorArgs,tag_files,id_defined_to:+prefixexp,define_rt,visited,depth+1,prefix_flags);
            if (!define_status) {
               rt = define_rt;
               return 0;
            }
         }
      }

      // process this part of the prefix expression
      status = _c_get_type_of_part(errorArgs, tag_files, isjava,
                                   previous_id, ch, prefixexp, full_prefixexp,
                                   rt, visited, depth+1, prefix_flags);

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
      if (status) {
         return status;
      }

      // check if 'previous' ID was a define
      found_define = false;
      orig_previous_id = previous_id;
      if (!isjava && isid_valid(previous_id) && 
          tag_find_local_iterator(previous_id,true,true,false,'') < 0) {
          tag_check_for_class(ch, rt.return_type, true, tag_files) <= 0 && 
          tag_check_for_define(previous_id, p_line, tag_files, previous_id);
         if (previous_id != orig_previous_id) {
            found_define=true;
         }
      }

      // save the arguments, for retries later
      orig_prefixexp       = prefixexp;
      orig_rt              = rt;
   }

   if (previous_id != '') {
      //say("before previous_id="previous_id" match_class="rt.return_type);
      int var_filters = VS_TAGFILTER_ANYDATA;
      if (!isjava) {
         var_filters |= VS_TAGFILTER_ANYPROC;
      }
      if (prefix_flags & VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE) {
         var_filters |= VS_TAGFILTER_STRUCT;
      }

      status = _c_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                     isjava, var_filters, true, false, rt, visited, depth+1);
      if (status && found_define) {
         // try the original ID, not what the define said it was
         prefixexp        = orig_prefixexp;
         rt               = orig_rt;
         previous_id      = orig_previous_id;

         status = _c_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                        isjava, var_filters, true, false, rt, visited, depth+1);
      }
      if (status) {
         return status;
      }
      previous_id = '';
      //say("after previous_id="previous_id" match_class="rt.return_type" match_tag="rt.taginfo);
   }

   // is the current token a builtin?
   if (rt.pointer_count==0 && _c_is_builtin_type(rt.return_type)) {
      // is the current token a builtin?
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
      box_type := _c_get_boxing_conversion(rt.return_type);
      if (box_type != '') {
         rt.return_type = box_type;
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


#define VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE   0x0001


/**
 * Evaluate the type of a C++, Java, Perl, JavaScript, C#,
 * InstallScript, or PHP prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
int _c_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                          struct VS_TAG_RETURN_TYPE &rt, 
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          int prefix_flags=0)
{
   typeless tag_files = tags_filenamea(p_LangId);
   tag_push_matches();
   status := _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth, prefix_flags);
   tag_pop_matches();
   return status;
}


// Insert files with the given extension in the same directory as
// the current buffer into the tree
int insert_files_of_extension(int tree_wid, int tree_root,
                              _str buf_name,_str extension_list,
                              boolean referExtension=false,
                              _str directoryPrefix="",
                              boolean includeDirs=false,
                              _str lastid="", 
                              boolean exact_match=false)
{
   //say("insert_files_of_extension: includePath="buf_name" directoryPrefix="directoryPrefix);
   // get the path of the current buffer
   _str dir_name = _strip_filename(buf_name,'N');
   if (dir_name=='') {
      return(0);
   }
   if (last_char(dir_name)!=FILESEP) {
      dir_name=dir_name:+FILESEP;
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
      filename := file_match(maybe_quote_filename(dir_name:+lastid:+wildcards):+prefixOpt' -X',1); // find first.
      for (;;) {
         if (_CheckTimeout()) return num_files;
         if (filename=='=' || filename=='')  break;
         if (last_char(filename)==FILESEP) {
            includeFile := substr(filename, 1, length(filename)-1);
            includeFile = _strip_filename(includeFile,'P');
            if (first_char(includeFile) != "." || (includeFile == ".." && directoryPrefix=="") ) {
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
   _str searchExt = "";
   _str allExtensions[];
   split(substr(extension_list,2,length(extension_list)-2), ";", allExtensions);

   // if there are more than 10 extensions to search for, then
   // just do a simple wildcard search for all files and filter later
   if (!exact_match && allExtensions._length() > 10) {
      allExtensions._makeempty();
      allExtensions[0] = ALLFILES_RE;
   } else if (!exact_match && pos(".", lastid) > 0) {
      allExtensions[allExtensions._length()] = "";
   }

   // next search through the extensions
   foreach (searchExt in allExtensions) {
      if (searchExt != ALLFILES_RE && searchExt != "") {
         searchExt = wildcards:+".":+searchExt;
      }
      filename := file_match(maybe_quote_filename(dir_name:+lastid:+searchExt):+prefixOpt' -D',1); // find first.
      for (;;) {
         if (_CheckTimeout()) return num_files;
         if (filename=='=' || filename=='')  break;
         _str ext=_get_extension(filename);
         if (referExtension) ext=_Ext2LangId(ext);
         if (pos(';'ext';',extension_list)) {
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

static boolean _skip_template_prefix_word()
{
   return(gtk==TK_ID &&
           (gtkinfo:=='const' ||
            gtkinfo:=='static' ||
            gtkinfo:=='volatile' ||
            gtkinfo:=='typedef' ||
            gtkinfo:=='virtual' ||
            gtkinfo:=='new' ||
            gtkinfo:=='gcnew' ||
            gtkinfo:=='inline' ||
            gtkinfo:=='restrict' ||
            gtkinfo:=='register' ||
            gtkinfo:=='friend' ||
            gtkinfo:=='extern' ||
            gtkinfo:=='public' ||
            gtkinfo:=='private' ||
            gtkinfo:=='protected' ||
            gtkinfo:=='mutable' ||
            gtkinfo:=='explicit'
           )
          );

}
static boolean _probablyTemplateArgList(int &FunctionNameStartOffset)
{
   if (!_LanguageInheritsFrom('c')) {
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
      return(0);
   }
   FunctionNameStartOffset=(int)point('s');
   c_next_sym();
   for (;;) {
      if (!_skip_template_prefix_word()) {
         break;
      }
      _clex_skip_blanks();
      FunctionNameStartOffset=(int)point('s');
      c_next_sym();
   }
   if (gtk=='::') {
      gtk=c_next_sym();
   }
   for (;;) {
      if (gtk!=TK_ID) {
         return(0);
      }
      gtk=c_next_sym();
      if (gtk!='::') {
         break;
      }
      gtk=c_next_sym();
   }
   if (gtk!='<' && gtk!='!(') {
      return(0);
   }
   /*
      Assume we are actually inside a template argument list.
      Let _c_get_expression_info and _c_fcthelp_get do the rest of the
      work.
   */
   return(1);
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
                         boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   errorArgs._makeempty();
   boolean iscpp=false;
   boolean isdlang=false;
   boolean has_bracket_expressions = (_LanguageInheritsFrom('cs') || _LanguageInheritsFrom('java'));
   _str not_function_words=C_NOT_FUNCTION_WORDS;
   _str case_options=p_EmbeddedCaseSensitive? '':'i';
   if (_LanguageInheritsFrom('d')) {
      not_function_words=D_NOT_FUNCTION_WORDS;
      isdlang=true;
   } else if (_LanguageInheritsFrom('c')) {
      iscpp=true;
   } else if (_LanguageInheritsFrom('cs')) {
      iscpp=true;
      not_function_words=CS_NOT_FUNCTION_WORDS;
   } else if (_LanguageInheritsFrom('java')) {
      not_function_words=JAVA_NOT_FUNCTION_WORDS;
   } else if (_LanguageInheritsFrom('rul')) {
      not_function_words=RUL_NOT_FUNCTION_WORDS;
   }
   gInJavadoc_flag=0;
   //say("_c_fcthelp_get_start");
   _str exclude_colors='xcs';
   flags=0;
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT) {
      if (_inJavadocSeeTag()) {
         flags|=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         gInJavadoc_flag=VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
         gInJavadoc_linenum=p_line;
         exclude_colors='xs';
      } else {
         //return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   /*} else if(cfg==CFG_STRING) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);*/
   } else {
      gInJavadoc_linenum=(p_active_form.p_name=='_javadoc_form')?p_line:0;
   }
   //if (cursorInsideArgumentList || OperatorTyped)
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();
   typeless orig_seek=point('s');
   int status=0;
   int first_less_than_seek=0;
   boolean have_d_template_signature=false;
   _str ch='';
   _str word='';
   {
      if (OperatorTyped && last_event()=='<') {
         first_less_than_seek=orig_seek-1;
         flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
      } else {
         if ((iscpp || isdlang || _LanguageInheritsFrom('java')) &&
             !ginFunctionHelp && cursorInsideArgumentList) {
            status=search('[;}{()<>]','-rh@'exclude_colors);
            if (!status) {
               ch=get_text_safe();
               if ((!isdlang && ch=='<') || (isdlang && ch=='(' && get_text_left()=='!')) {
                  if (ch=='(') left();
                  first_less_than_seek=(int)point('s');
                  left();
                  if (get_text_safe()!='<') { // Have << or < at beginning of line
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
         say("_c_get_fcthelp_start: IN TEMPLATE_ARGLIST:"(flags&VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST));
      }
#if 0
      ch=get_text_safe();
      if (ch==')' ||
          (OperatorTyped && (ch=='(' || ch==';' || ch=='{'))) {
         if(p_col==1){up();_end_line();} else {left();}
      }
#endif
      int orig_col=p_col;
      int orig_line=p_line;
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // Just look for beginning of statement
         if (_LanguageInheritsFrom('cs')) {
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
               c_begin_stat_col(false,0,false);
            }
            //say('break '_nrseek());
            break;
         }
         ch=get_text_safe();
         //say("CCH="ch);
         if (ch=='(') {
            save_pos(auto p);
            if( p_col==1 ){
               up();_end_line();
            } else {
               left();
               // check for D style !( template arguments
               if (isdlang && get_text_safe()=='!') left();
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
            _c_skip_operators_left();

            ch=get_text_safe();
            word=cur_identifier(auto junk=0);
            restore_pos(p);
            if (pos('['word_chars']',ch,1,'r')) {
               if (pos(' 'word' ',not_function_words,1,case_options)) {
                  if (OperatorTyped && ArgumentStartOffset== -1) {
                     return(VSCODEHELPRC_CONTEXT_NOT_VALID);
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
                   ch!=')' &&   // (*pfn)(a,b,c)  OR  f(x)(a,b,c)
                   ch!=']' &&   // calltab[a](a,b,c)
                   ch!='>'      // new STACK<stuff>(a,b,c)
                  ){
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               if (ch==')' || ch==']' || ch=='>') {
                  ArgumentStartOffset=(int)point('s')+1;
               }
            }
         } else if (ch == '}' && has_bracket_expressions) { 
            // ie: new int[] {} or new Runnable() { public void run() {} }
            status = find_matching_paren(true);
            if (status) {
               restore_pos(orig_pos);
               return(1);
            }
            status = repeat_search();
            continue;
         } else if (ch==')' || ch=='>') {
            status=find_matching_paren(true);
            if (status) {
               restore_pos(orig_pos);
               return(1);
            }
            save_pos(auto p);
            if(p_col==1){
               up();_end_line();
            } else {
               left();
               if (isdlang && get_text_safe()=='!') {
                  left();
                  have_d_template_signature=true;
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
            if (pos(' 'word' ',' if elsif elseif while catch switch ')) {
               break;
            }
            restore_pos(p);
         } else {
            break;
         }
         status=repeat_search();
      }
      if (ArgumentStartOffset<0) {
         if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
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
         if(gtk!=TK_ID || gtkinfo!='template') {
            break;
         }
         right();
         if (isdlang) {
            status=search('!(','h@'exclude_colors);
         } else {
            status=search('<','h@'exclude_colors);
         }
      }
      if (!status && get_text_safe()=='!') right();
      right();
   }
   ArgumentStartOffset=(int)point('s');
   left();
   if ((isdlang && get_text_safe()=='(' && get_text_left()=='!') ||
       (get_text_safe()=='<' && (iscpp || _LanguageInheritsFrom('java')))) {
      save_pos(auto p2);
      int junk;
      boolean is_template_arglist = _probablyTemplateArgList(junk);
      restore_pos(p2);
      if (is_template_arglist) {
         flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
      } else {
         if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
            return(1);
         }
      }
   } else {
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
   }
   if (isdlang && get_text_safe()=='(' && get_text_left()=='!') left();
   left();
   _str lastid='';
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
         return(1);
      }
      if (get_text_left()=='!') left();
      left();
   }

   if (pos('[~'word_chars']',get_text_safe(),1,'r')) {
      ch=get_text_safe();
      if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) &&
          (ch==')' || ch==']' || (ch=='>' && (iscpp || _LanguageInheritsFrom('java'))))) {
         FunctionNameOffset=ArgumentStartOffset-1;
         return(0);
      } else {
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
   if (pos(' 'lastid' ',not_function_words,1,case_options)) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   return(0);
}
static boolean try_python_constructor(VS_TAG_RETURN_TYPE &rt,VS_TAG_IDEXP_INFO &idexp_info, 
                                      VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{

   int status;
   _str  errorArgs[];
   VS_TAG_RETURN_TYPE rttemp;tag_return_type_init(rttemp);
   if (idexp_info.prefixexp!='') {
      /*
         Handle constructor call for class from module
           inst=moduleName.className(a1,a2)
           inst=outerClass.innerClass(a1,a2)
           inst=moduleName.outerClass.innerClass(a1,a2)
      */
      //say('******************************try 'idexp_info.prefixexp:+idexp_info.lastid);
      status = _c_get_type_of_prefix(errorArgs, idexp_info.prefixexp:+idexp_info.lastid, rttemp, visited, depth+1);
      //status = _c_get_type_of_prefix(errorArgs, "nestedclass/outerC.innerC", rttemp);
      //say('status='status' rttemp.return_type='rttemp.return_type);
      if (rttemp.return_type==idexp_info.lastid || 
          idexp_info.prefixexp:+idexp_info.lastid==translate(rttemp.return_type,'.',VS_TAGSEPARATOR_package)
         ) {
         tag_return_type_init(rt);
         idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid'.';
         //say('idexp_info.prefixexp='idexp_info.prefixexp);
         //idexp_info.prefixexp='nestedclass/outerC::innerC';
         //idexp_info.prefixexp='innerC.';
         idexp_info.lastid='__init__';
         status = _c_get_type_of_prefix(errorArgs,idexp_info.prefixexp, rt, visited, depth+1);
         //status = _c_get_type_of_prefix(errorArgs,"nestedclass::outerC::innerC", rt);
         //say('h2 status='status' rt.return_type='rt.return_type);
         //rt.return_type='nestedclass/outerC::innerC';
         return(!status);
      }
   } else {
      status=_c_get_type_of_prefix(errorArgs, idexp_info.lastid, rttemp, visited, depth+1);
      if (rttemp.return_type==idexp_info.lastid ||
          endsWith(rttemp.return_type,VS_TAGSEPARATOR_package:+idexp_info.lastid)
          ) {
         tag_return_type_init(rt);
         idexp_info.prefixexp=idexp_info.lastid'.';
         idexp_info.lastid='__init__';
         //say('special 'dec2hex(idexp_info.info_flags));
         status = _c_get_type_of_prefix(errorArgs,idexp_info.prefixexp, rt, visited, depth+1);
         //say('status='status);
         return(!status);
      }
   }
   return(false);
}

static _str gLastContext_FunctionName;
static int gLastContext_FunctionOffset;

/**
 * Bookkeeping for _c_fcthelp_get
 */
struct FnHelpCtx {
   int brace_nesting;
   int param_num;
   int lparen_offset;
};

void initFnHelpCtx(FnHelpCtx& c, int offset = 0)
{
   c.brace_nesting = 0;
   c.param_num = 1;
   c.lparen_offset = offset;
}

_str fnHelpCtxString(FnHelpCtx& c) {
   return nls("<FnHelpCtx: brace_nesting=%s, param_num=%s, lparen_offset=%s>", c.brace_nesting, c.param_num, c.lparen_offset);
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
                   boolean &FunctionHelp_list_changed,
                   int &FunctionHelp_cursor_x,
                   _str &FunctionHelp_HelpWord,
                   int FunctionNameStartOffset,
                   int flags,
                   VS_TAG_BROWSE_INFO symbol_to_match=null,
                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug > 9) {
      isay(depth, "_c_fcthelp_get: fnoffset="FunctionNameStartOffset", flags="dec2hex(flags));
   }

   // avoid recalculating the expression when we don't have to
   static _str prev_prefixexp;
   static _str prev_otherinfo;
   static int  prev_info_flags;
   static int  prev_ParamNum;
   if (FunctionNameStartOffset < 0 || flags == 0xffffffff) {
      prev_prefixexp  = "";
      prev_otherinfo  = "";
      prev_info_flags = 0;
      prev_ParamNum   = 0;
      return(0);
   }
   
   errorArgs._makeempty();

   // check language mode
   _str common=C_COMMON_END_OF_STATEMENT_RE;
   boolean case_sensitive=true;
   boolean isjava=false;
   boolean slickc=false;
   boolean javascript=false;
   boolean isrul=false;
   boolean isphp=false;
   boolean isdlang=false;
   boolean isother=false;
   boolean isobjc=false;
   boolean has_bracket_expressions = (_LanguageInheritsFrom('cs') || _LanguageInheritsFrom('java'));

   FunctionHelp_list_changed=0;
   if(FunctionHelp_list._isempty()) {
      FunctionHelp_list_changed=1;
      gLastContext_FunctionName="";
      gLastContext_FunctionOffset=-1;
   }

   int stack_top=0;
   FnHelpCtx ctx_stack[];
   initFnHelpCtx(ctx_stack[0], 0);

   typeless cursor_offset=point('s');
   save_pos(auto p);
   int orig_left_edge=p_left_edge;
   goto_point(FunctionNameStartOffset);
   word_chars := _clex_identifier_chars();

   if (_LanguageInheritsFrom('java')) {
      isjava=true;
      gInJavadoc_linenum = (p_active_form.p_name=='_javadoc_form')? p_line:0;
      if (gInJavadoc_linenum) {
         common='[,{};()]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      } else if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // for now, we don't try to handle parens in template argument lists
         common='[,#{};<>]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,#{};()]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
      }
   } else if (_LanguageInheritsFrom('e')) {
      slickc=true;
      common='[,#{};()]|'common'|'SLICKC_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('js')) {
      javascript=true;
      common='[,{};()[]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('cfscript')) {
      javascript=true;
      case_sensitive=false;
      common='[,{};()[]|'common'|'JAVA_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('rul')) {
      isrul=true;
      common='[,;()[]|'common'|'RUL_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('phpscript')) {
      isphp=true;
      common='[,;()[]|'common'|'PHP_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('sas')) {
      isother=true;
      case_sensitive=false;
      common='[,;()[]|'common'|'SAS_MORE_END_OF_STATEMENT_RE;
   } else if (_LanguageInheritsFrom('cs')) {
      isjava=true;
      
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         common='[<>,{};()]|'common'|'CS_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,{};()]|'common'|'CS_MORE_END_OF_STATEMENT_RE;
      }
   } else if (_LanguageInheritsFrom('d')) {
      isdlang=true;
      common='[,{};()]|'common'|'D_MORE_END_OF_STATEMENT_RE;

   } else if (_LanguageInheritsFrom('m')) {
      isobjc=true;
      save_pos(auto op);
      // check for selector colon
      search('[~'word_chars' \t]|$','rh@');
      if (get_text_safe() == ':') {
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

   } else if (_LanguageInheritsFrom('c')) {
      if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
         // for now, we don't try to handle parens in template argument lists
         common='[,#{};<>]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      } else {
         common='[,#{};()]|'common'|'C_MORE_END_OF_STATEMENT_RE;
      }

   } else {
      case_sensitive=p_EmbeddedCaseSensitive;
      isother=true;
      common='[,;()[]|'common;
   }
   boolean in_d_template_arglist=false;
   boolean had_d_template_arglist=false;
   _str exclude_colors='xcs';
   if (flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      exclude_colors='xs';
   }
   _str case_options='';
   if (!case_sensitive) {
      case_options='i';
   }

   // enum, struct class
   int status=search(common,'rh@'case_options:+exclude_colors);
   //boolean found_function_pointer=false;
   int preprocessing_top=0;
   int preprocessing_ParamNum_stack[];
   int preprocessing_offset_stack[];
   int nesting=0;

   for (;;) {
      if (status) {
         break;
      }
      _str ch=get_text_safe();
      //say('_c_fcthelp_get: nesting='stack_top' ch='ch' cursor_offset='cursor_offset' p='point('s')' 'fnHelpCtxString(ctx_stack[stack_top]));
      if (cursor_offset<=point('s')) {
         break;
      }
      if (ch == ',') {
         if (ctx_stack[stack_top].brace_nesting == 0) {
            ctx_stack[stack_top].param_num++;
         }
         status=repeat_search();
         continue;
      }
      if (ch==')') {
         --stack_top;
         if (in_d_template_arglist && stack_top<=0) {
            in_d_template_arglist=false;
            had_d_template_arglist=true;
            status=repeat_search();
            continue;
         }
         if (stack_top<=0 /*&& (!found_function_pointer && stack_top<0)*/) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         //found_function_pointer = false;
         status=repeat_search();
         continue;
      }
      if (ch=='>') {
         --stack_top;
         if (stack_top<0 || (stack_top==0 && (int)point('s')+1 >= cursor_offset)) {
            // The close paren has been entered for the outer most function
            // We are done.
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         status=repeat_search();
         continue;
      }
      if (ch=='(') {
         // Determine if this is a new function
         if (isdlang && get_text_left()=='!') {
            in_d_template_arglist=true;
         }
         ++stack_top;
         initFnHelpCtx(ctx_stack[stack_top], (int)point('s'));
         /*if (get_text(2)=='(*') {
            found_function_pointer = true;
         } */
         status=repeat_search();
         continue;
      }
      if (ch=='[') {
         status=find_matching_paren(true);
         if (status) {
            restore_pos(p);
            return(VSCODEHELPRC_BRACKETS_MISMATCH);
         }
         status=repeat_search();
         continue;
      }
      if (ch=='<') {
         // Determine if this is a new function
         ++stack_top;
         initFnHelpCtx(ctx_stack[stack_top], (int)point('s'));
         status=repeat_search();
         continue;
      }
      if (ch == '}') {
         if (ctx_stack[stack_top].brace_nesting > 0) {
            ctx_stack[stack_top].brace_nesting--;
            status = repeat_search();
            continue;
         }
         restore_pos(p);
         return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
      }
      if (ch==';') {
         // Semicolons can happen inside of anonymous classes.
         if (ctx_stack[stack_top].brace_nesting < 1) {
            restore_pos(p);
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
         status = repeat_search();
         continue;
      }
      if (ch=='#' || ch=='{' || (pos('[~'word_chars']',get_text_safe(1,match_length('s')-1),1,'r') &&
                                 pos('[~'word_chars']',get_text_safe(1,match_length('s')+match_length()),1,'r'))
          ) {
         // IF this could be enum, struct, or class
         _str word;
         int junk=0;
         if (stack_top>=1 && (ch=='e' || ch=='s' || ch=='c')) {
            word=cur_identifier(junk);
            if (word=='enum' || word=='struct' || word=='class') {
               status=repeat_search();
               continue;
            }
         }
         // IF we need to check for conditional preprocessing
         if (/*!isjava &&*/ !javascript && !isphp && ch=='#' && stack_top>0) {
            right();
            word=cur_identifier(junk);
            if (word=='if' || word=='ifdef' || word=='ifndef') {
               // IF we are in conditional preprocessing.
               ++preprocessing_top;
               preprocessing_ParamNum_stack[preprocessing_top]=ctx_stack[stack_top].param_num;
               preprocessing_offset_stack[preprocessing_top]=ctx_stack[stack_top].lparen_offset;
               status=repeat_search();
               continue;
            } else if (word=='elif' || word=='else') {
               if (preprocessing_top && stack_top>0 &&
                   preprocessing_offset_stack[preprocessing_top]==ctx_stack[stack_top].lparen_offset
                   ) {
                  ctx_stack[stack_top].param_num=preprocessing_ParamNum_stack[preprocessing_top];
                  status=repeat_search();
                  continue;
               }

            } else if (word=='endif') {
               if (preprocessing_top) {
                  --preprocessing_top;
               }
               status=repeat_search();
               continue;
            } else if (word!='define' && word!='undef' && word!='include' &&
                       word!='pragma' && word!='error') {
               status=repeat_search();
               continue;
            }
         }
         // Case for common java/cs construct to create an
         // from an initializer at runtime:  new int[] { 1, 2, 3 }; 
         // Or a java anonymous class:
         //  new Interface() { public void someMethod() { .... }}
         if (ch == '{' && has_bracket_expressions) {
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
            return(VSCODEHELPRC_NOT_IN_ARGUMENT_LIST);
         }
      }
      status=repeat_search();
   }
   if (flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST) {
      restore_pos(p);
      return(0);
   }
   _UpdateContext(true);
   _UpdateLocals(true);

   typeless tag_files = tags_filenamea(p_LangId);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   for (;;--stack_top) {
      if (stack_top<=0) {
         restore_pos(p);
         return(VSCODEHELPRC_NO_HELP_FOR_FUNCTION);
      }
      goto_point(ctx_stack[stack_top].lparen_offset+1);

      if (had_d_template_arglist) {
         goto_point(ctx_stack[stack_top].lparen_offset);
         if (get_text_safe()=='(') left();
         _clex_skip_blanks('-');
         if (get_text_safe() == ')') {
            find_matching_paren(true);
            right();
            //if (get_text_safe()=='(' && get_text_left()=='!') {
            //   left();
            //}
         }
      }
         
      typeless junk;
      if ((flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) || had_d_template_arglist) {
         // Don't allow any failures
         while (stack_top>1) {
            ctx_stack._deleteel(1);
            --stack_top;
         }
         left();left();
         if (_LanguageInheritsFrom("pl")) {
            status=_pl_get_expression_info(false,idexp_info,visited,depth);
         } else if (_LanguageInheritsFrom('cs')) {
            status=_cs_get_expression_info(false,idexp_info,visited,depth);
         } else {
            status=_c_get_expression_info(false,idexp_info,visited,depth);
         }
         idexp_info.info_flags|=VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST;
         errorArgs = idexp_info.errorArgs;
      } else {
         if (_LanguageInheritsFrom("pl")) {
            status=_pl_get_expression_info(true,idexp_info,visited,depth);
         } else if (_LanguageInheritsFrom('cs')) {
            status=_cs_get_expression_info(true,idexp_info,visited,depth);
         } else {
            status=_c_get_expression_info(true,idexp_info,visited,depth);
         }
         errorArgs = idexp_info.errorArgs;
      }
      errorArgs[1] = idexp_info.lastid;


    if (_chdebug) {
         tag_idexp_info_dump(idexp_info,"_c_fcthelp_get");
         isay(depth,'_c_fcthelp_get: idexp_info status='status);
    }
      if (!status) {
         // get parameter number and cursor position
         int ParamNum=ctx_stack[stack_top].param_num;
         set_scroll_pos(orig_left_edge,p_col);

         // check if anything has changed
         if (prev_prefixexp :== idexp_info.prefixexp &&
            gLastContext_FunctionName :== idexp_info.lastid &&
            gLastContext_FunctionOffset :== idexp_info.lastidstart_col &&
            prev_otherinfo :== idexp_info.otherinfo &&
            prev_info_flags == idexp_info.info_flags &&
            prev_ParamNum   == ParamNum) {
            if (!p_IsTempEditor) {
               FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
            }
            break;
         }

         // find matching symbols
         //say('lastid='lastid' prefixexp='prefixexp' ParamNum='ParamNum' otherinfo='otherinfo);
         int tag_flags=0;
         boolean globals_only=false;
         int found_define=0;
         _str signature='';
         _str return_type='';
         _str match_list[];
         _str match_symbol = idexp_info.lastid;
         _str match_class='';
         int  match_flags = VS_TAGFILTER_ANYPROC;
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         if (!isjava && !javascript && !isrul && !isphp && !isdlang && !isother) {
            match_flags |= VS_TAGFILTER_DEFINE;
            found_define = tag_check_for_define(idexp_info.lastid, p_line, tag_files, match_symbol);
            //say("tag_check_for_define, lastid="lastid" match_symbol="match_symbol"matches="found_define);
         }
         if (_LanguageInheritsFrom('sas')) {
            match_flags |= VS_TAGFILTER_DEFINE;
         }
         if (!slickc && (idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) && !had_d_template_arglist) {
            match_flags = VS_TAGFILTER_STRUCT|VS_TAGFILTER_INTERFACE;
         }

         // check for C++ overloaded operators
         if (pos('operator ', idexp_info.lastid, 1)) {
            parse idexp_info.lastid with . idexp_info.lastid;
         }

         // find symbols matching the given class
         int num_matches = 0;
         tag_clear_matches();
         // this may be a variable MYCLASS a(
         if (idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL) {
            idexp_info.otherinfo    = stranslate(idexp_info.otherinfo,':','::');
            parse idexp_info.otherinfo with idexp_info.otherinfo '<' . ;
            tag_split_class_name(idexp_info.otherinfo, match_symbol, match_class);
            _str cmatch_class = tag_join_class_name(match_symbol, match_class, tag_files, true);
            //say("111 match_symbol="match_symbol" match_class="cmatch_class);

            if (idexp_info.otherinfo != '') {
               // pull out the BIG guns to resolve the return type of the var
               VS_TAG_RETURN_TYPE var_rt;
               tag_return_type_init(var_rt);
               if (!_c_get_return_type_of(errorArgs, tag_files, idexp_info.lastid, '', 0, isjava||isdlang, VS_TAGFILTER_ANYTHING, true, false, var_rt, visited, depth+1)) {
                  cmatch_class = var_rt.return_type;
               } else if (!_c_parse_return_type(errorArgs, tag_files, 
                                                idexp_info.lastid, 
                                                '', p_buf_name, 
                                                idexp_info.otherinfo, 
                                                isjava||isdlang, var_rt, 
                                                visited, depth+1)) {
                  cmatch_class = var_rt.return_type;
               }
            }

            tag_clear_matches();
            _UpdateLocals();
            tag_list_in_class(match_symbol, cmatch_class, 
                              0, 0, tag_files,
                              num_matches, def_tag_max_function_help_protos,
                              VS_TAGFILTER_ANYPROC,
                              VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_inclass,
                              true, case_sensitive,
                              null, null, visited);
            if (num_matches <= 0) {
               match_symbol = idexp_info.lastid;
            }
         }

         // initializer list of constructor MYCLASS::MYCLASS() : BASECLASS(&lt;here&gt;
         if (idexp_info.info_flags & (VSAUTOCODEINFO_IN_INITIALIZER_LIST|VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) {
            idexp_info.otherinfo    = stranslate(idexp_info.otherinfo,':','::');
            tag_split_class_name(idexp_info.otherinfo,junk,match_class);
            if (match_class == '') {
               match_class = idexp_info.otherinfo;
            }
            match_symbol = idexp_info.lastid;
            //say("match_symbol="match_symbol" match_class="match_class);
            tag_clear_matches();
            _UpdateLocals();
            tag_list_in_class(match_symbol, match_class, 
                              0, 0, tag_files,
                              num_matches, def_tag_max_function_help_protos,
                              VS_TAGFILTER_ANYPROC/*|VS_TAGFILTER_ANYSTRUCT*/,
                              VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_inclass,
                              true, true, null, null, visited);
            if (num_matches==0) {
               tag_list_in_class(match_symbol, match_class, 
                                 0, 0, tag_files,
                                 num_matches, def_tag_max_function_help_protos,
                                 VS_TAGFILTER_ANYTHING,
                                 VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_private,
                                 //VS_TAGFILTER_VAR/*|VS_TAGFILTER_ANYSTRUCT*/,
                                 //VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_inclass,
                                 true, true, null, null, visited);
               if (!isjava && !isphp && !isrul && !javascript && !isdlang && !isother && num_matches>0) {
                  status = _c_get_return_type_of(errorArgs,tag_files,
                                                 match_symbol,match_class,
                                                 0,false /*isjava||javascript||isrul*/,
                                                 VS_TAGFILTER_ANYDATA,
                                                 false,false,rt,visited,depth+1);
                  //say("_c_fcthelp_get: status="status" match_class="match_class" match_tag="match_tag" match_type="rt.return_type);
                  if (!status && rt.return_type!='' && rt.pointer_count==0) {
                     tag_clear_matches();
                     num_matches=0;
                     match_symbol=rt.return_type;
                     int sep_pos=lastpos('[:/]',match_symbol);
                     if (sep_pos) {
                        match_symbol=substr(match_symbol,sep_pos+1);
                     }
                     match_class=rt.return_type;
                     tag_list_in_class(match_symbol, rt.return_type, 
                                       0, 0, tag_files,
                                       num_matches, def_tag_max_function_help_protos,
                                       VS_TAGFILTER_ANYPROC/*|VS_TAGFILTER_ANYSTRUCT*/,
                                       VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ONLY_inclass,
                                       true, true, null, null, visited);
                  }
               }
            }
            //say("num_matches="num_matches" here 2");
         }
         boolean is_py_constructor_call=false;

         // analyse prefix epxression to determine effective class
         if (num_matches == 0) {
            //say("xxx prefixexp="prefixexp" match_symbol="match_symbol);
            //if (prefixexp=='new') {
            //   say("_c_fcthelp_get: new");
            //   prefixexp='';
            //}
            // remove unwelcome new operator
            if ((_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom('phpscript') || _LanguageInheritsFrom('d')) && pos("new ",idexp_info.prefixexp)==1 && pos(')',idexp_info.prefixexp)) {
               idexp_info.prefixexp=substr(idexp_info.prefixexp,5);
               idexp_info.prefixexp=idexp_info.prefixexp:+idexp_info.lastid;
            }
            if ((_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom('phpscript') || _LanguageInheritsFrom('d')) && pos('new ',idexp_info.prefixexp) == 1) {
               // 08/24/2000 --
               //   Disabled this case, let _c_get_type_of_prefix take
               //   care if this grunt work.  That will be more powerful
               //   in terms of resolving inheritance, and typedefs, and
               //   all those other nasty things.  It also will correctly
               //   handle more cases with template classes.
               //
               // handle 'new' expressions as a special case
               _str outer_class = substr(idexp_info.prefixexp, 5) :+ idexp_info.lastid;
               if (_chdebug > 9) {
                  isay(depth, "_c_fcthelp_get: stripped new, outer_class="outer_class);
               }
               
               if (last_char(outer_class)==':') {
                  outer_class = substr(outer_class, 1, length(outer_class)-2);
               }
               if (last_char(outer_class)=='.') {
                  outer_class = substr(outer_class, 1, length(outer_class)-1);
               }
               outer_class = stranslate(outer_class, ':', '::');

               // qualify in the face of imports, etc...
               _c_parse_return_type(errorArgs, tag_files, 
                                    '', outer_class, 
                                    p_buf_name, outer_class, 
                                    isjava, rt, visited, depth+1);

               // We peel the constructor name off of the parsed return type, 
               // because it has already removed template arguments and
               // other decorations from the name.
               int lastpsep = lastpos(VS_TAGSEPARATOR_package, rt.return_type);

               if (lastpsep == 0) {
                  idexp_info.lastid = rt.return_type;
               } else {
                  idexp_info.lastid = substr(rt.return_type, lastpsep+1);
               }
               match_symbol = idexp_info.lastid;

               if (_chdebug > 9) {
                  isay(depth, "_c_fcthelp_get: new case match_symbol="match_symbol", rt="rt.return_type);
               }
               
               rt.pointer_count = 1;
               status = 0;
            } else if (idexp_info.prefixexp != '') {
               if ((pos('new ',idexp_info.prefixexp)==1 || pos('gcnew ', idexp_info.prefixexp)==1)) {
                  status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, idexp_info.prefixexp:+idexp_info.lastid, rt, visited, depth+1, 0);
               } else {
                  status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, idexp_info.prefixexp, rt, visited, depth+1, 0);
               }
               //say("_c_get_type_of_prefix returns "rt.return_type" status="status" match_tag="rt.taginfo);
               if (status && (slickc || javascript)) {
                  // oh, well, we tried...
                  status = 0;
               }
               if (status && (status!=VSCODEHELPRC_BUILTIN_TYPE || idexp_info.lastid!='')) {
                  restore_pos(p);
                  continue;
               }
               if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
                  globals_only = true;
               }
               //say("_c_fcthelp_get: match_symbol="match_symbol" prefix="prefixexp"=");
               if (pos('new ',idexp_info.prefixexp)==1 || pos('gcnew ', idexp_info.prefixexp)==1) {
                  if (rt.return_type!='') {
                     // Force the return type to be qualified, if possible.
                     idexp_info.lastid = rt.return_type; 
                     _c_parse_return_type(errorArgs, tag_files, 
                                          '', rt.return_type, 
                                          p_buf_name, rt.return_type, 
                                          isjava, rt, visited, depth+1);
                     int colon_pos=lastpos('[:/]',rt.return_type,"",'r');
                     if (colon_pos) {
                        match_symbol=substr(rt.return_type,colon_pos+1);
                     } else {
                        match_symbol=rt.return_type;
                     }
                  } else {
                     //rt.return_type=match_symbol;
                     rt.return_type = tag_join_class_name(match_symbol, rt.return_type, tag_files, case_sensitive);
                  }
               }
               //say("_c_fcthelp_get: XXX match_class="match_class" match_symbol="match_symbol);
            }

            _str cur_tag_name = '';
            _str cur_type_name = '';
            _str cur_class_name = '';
            _str cur_class_only = '';
            _str cur_package_name = '';
            int cur_tag_flags = 0;
            int cur_type_id = 0;

            int context_flags=globals_only? 0:VS_TAGCONTEXT_ALLOW_locals;
            if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
               context_flags |= VS_TAGCONTEXT_ALLOW_package;
               context_flags |= VS_TAGCONTEXT_ALLOW_protected;
               context_flags |= VS_TAGCONTEXT_ALLOW_private;
            }

            // compute current context, package name, and class name to
            // determine unusual access restrictions for java
            tag_get_current_context(cur_tag_name,cur_tag_flags,
                                                     cur_type_name,cur_type_id,
                                                     cur_class_name,cur_class_only,
                                                     cur_package_name);

            if (_chdebug) isay(depth, "_c_fcthelp_get: current_context pkg_name="cur_package_name", cur_class_name="cur_class_name", cur_type_name="cur_type_name);
            if ((pos(cur_package_name'/',rt.return_type)==1) ||
                (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
                 !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
               context_flags |= VS_TAGCONTEXT_ALLOW_package;
               context_flags |= VS_TAGCONTEXT_ALLOW_protected;
            }
            // is this a reference to the constructor of the parent class in Java?
            if ((isjava || isdlang) && idexp_info.lastid=="super") {
               _java_find_super(idexp_info.lastid,cur_class_name,tag_files);
            }

            tag_clear_matches();
            // try to find 'lastid' as a member of the 'match_class'
            // within the current context
            if (idexp_info.lastid!='' || match_symbol!='') {
               if (found_define && idexp_info.lastid!=match_symbol) {
                  _str orig_match_symbol=match_symbol;
                  match_symbol=idexp_info.lastid;
                  match_symbol=orig_match_symbol;
               }
               
               _UpdateContext(true);
               tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                           0, 0, tag_files, '',
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, case_sensitive, 
                                           visited, depth+1, rt.template_args);
               
               if (_chdebug > 9) {
                  isay(depth, "_c_fcthelp_get: got "num_matches" from list_symbols_in_context(match_sym="match_symbol", return_type="rt.return_type", match_flags="dec2hex(match_flags)", ctx_flags="dec2hex(context_flags)")");
                  isay(depth, "_c_fcthelp_get: num tag files "tag_files._length());
                  _dump_var(tag_files);
               }
               if (num_matches == 0 && idexp_info.prefixexp=="" &&
                   (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs')) && 
                   !pos(VS_TAGSEPARATOR_package, rt.return_type)) {
                  // If the type is not qualified, use the current context
                  // to add qualification if available.  Without this, 
                  // tag_list_symbols_in_context can fail when rt.return_type
                  // is contained within a namespace when you're completing 
                  // an unqualified reference from the same namespace.
                  _str qn;
                  tag_qualify_symbol_name(qn, rt.return_type, cur_class_name, '', tag_files, true);
                  if (rt.return_type != qn) {
                     if (_chdebug) {
                        isay(depth, "_c_fcthelp_get: try qualifying type to "qn);
                     }
                     tag_list_symbols_in_context(match_symbol, qn, 
                                                 0, 0, tag_files, '',
                                                 num_matches, def_tag_max_function_help_protos,
                                                 match_flags, context_flags,
                                                 true, case_sensitive, 
                                                 visited, depth+1, rt.template_args);
                  }
               }

               if (num_matches==0 && _LanguageInheritsFrom("py")) {
                  is_py_constructor_call=try_python_constructor(rt,idexp_info,visited,depth);
                  //say('YXXnum_matches='num_matches' rt.return_type='rt.return_type);
                  //say('YYmatch_flags='dec2hex(match_flags));
                  if (is_py_constructor_call) {
                     tag_list_symbols_in_context("__init__", rt.return_type, 0, 0, tag_files, '',
                                                 num_matches, def_tag_max_function_help_protos,
                                                 match_flags, context_flags,
                                                 true, case_sensitive, 
                                                 visited, depth+1, rt.template_args);
                     //say('num_matches='num_matches);
                  }
               }
               // PHPScript uses __construct instead of normal constructor names
               if (num_matches==0 && _LanguageInheritsFrom("phpscript") && rt.return_type!="") {
                  tag_list_symbols_in_context("__construct", rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  //say('num_matches='num_matches);
               }
               // D uses 'this' instead of normal constructor names
               if (num_matches==0 && _LanguageInheritsFrom("d") && rt.return_type!="") {
                  tag_list_symbols_in_context("this", rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
                  //say('num_matches='num_matches);
               }
               // Could not find a match. Try assuming that it is in the current class
               // context and look there. This is to fix a bug where codehelp doesn't work
               // on a member of a class when inside that class when there is no prefix and that class
               // is in a namespace.
               if( ( idexp_info.prefixexp == '' ) && ( num_matches == 0 ) ) {
                  tag_get_current_context(cur_tag_name,cur_tag_flags,
                                         cur_type_name,cur_type_id,
                                         cur_class_name,cur_class_only,
                                         cur_package_name);
                  _c_get_type_of_prefix_recursive(errorArgs, tag_files, cur_class_name, rt, visited, depth+1, 0);

                  // Look again with the new return type
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
               }

               if (num_matches==0 && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              match_flags, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
               } else if (found_define && idexp_info.lastid!=match_symbol) {
                  match_symbol=idexp_info.lastid;
                  tag_list_symbols_in_context(match_symbol, rt.return_type, 0, 0, tag_files, '',
                                              num_matches, def_tag_max_function_help_protos,
                                              VS_TAGFILTER_ANYPROC, context_flags,
                                              true, case_sensitive, 
                                              visited, depth+1, rt.template_args);
               }
            }
            // try variables, maybe there's a function pointer out there
            if (idexp_info.lastid != '' && !isother && !isjava && !javascript && !isphp && num_matches == 0) {
               //say("_c_fcthelp_get: 1, symbol="match_symbol" class="match_class);
               // try to find 'lastid' as a data member which may be a function
               // pointer in 'match_class', using shorthand call notation
               tag_clear_matches();
               tag_list_symbols_in_context(match_symbol, rt.return_type, 
                                           0, 0, tag_files, '',
                                           num_matches, def_tag_max_function_help_protos,
                                           VS_TAGFILTER_ANYDATA, context_flags,
                                           true, true, 
                                           visited, depth+1, rt.template_args);

               int m;
               _str tr='';
               for (m=1; m<=num_matches; m++) {
                  tag_get_detail2(VS_TAGDETAIL_match_return,m,tr);
                  if (pos('(',tr)) {
                     break;
                  }
               }
               if (m > num_matches) {
                  // no function pointers found
                  num_matches=0;
                  if (!isjava && !slickc && !javascript && !isrul && !isphp && !isother) {
                     // Maybe this is a call to operator (), function call,
                     // for some class instance?
                     //say("_c_fcthelp_get: maybe function call operator, type="rt.return_type);
                     status = _c_get_return_type_of(errorArgs,tag_files,
                                                    match_symbol,rt.return_type,
                                                    0,false /*isjava||javascript||isrul*/,
                                                    VS_TAGFILTER_ANYDATA,
                                                    false, false, rt, visited, depth+1);
                     tag_clear_matches();
                     if (!status && rt.return_type!='') {
                        // OK, 'lastid' is a class instance, try to find operator ()
                        //say("_c_fcthelp_get: 5, match_type="rt.return_type);
                        num_matches=0;
                        _str function_call_operator = "()";
                        if (_LanguageInheritsFrom('d')) {
                           function_call_operator = "opCall";
                        }
                        tag_list_symbols_in_context(function_call_operator, rt.return_type, 0, 0, tag_files, '',
                                                    num_matches, def_tag_max_function_help_protos,
                                                    VS_TAGFILTER_ANYPROC, context_flags,
                                                    true, true, 
                                                    visited, depth+1, rt.template_args);
                        if (num_matches <= 0) {
                           // check for a typedef'd function pointer
                           status = _c_get_return_type_of(errorArgs,tag_files,tr,
                                                          '',0,0,VS_TAGFILTER_TYPEDEF,
                                                          false, false, rt, visited, depth+1);
                           if (!status) {
                              _str tn='', tc='', tt='', ts='';
                              int tf=0;
                              tag_tree_decompose_tag(rt.taginfo, tn,tc,tt,tf,ts,tr);
                              tag_clear_matches();
                              tag_insert_match('',tn,tt,'',0,tc,tf,tr:+VS_TAGSEPARATOR_args:+ts);
                              num_matches++;
                           }
                        }
                     }
                  }
               }
            }
            if (idexp_info.lastid == '' && rt.taginfo != '') {
               _str tr='', tn='', tc='', tt='', ts='';
               int tf=0;
               tag_tree_decompose_tag(rt.taginfo, tn,tc,tt,tf,ts,tr);
               parse tr with tr '[' .;
               tag_clear_matches();
               tag_insert_match('',tn,tt,'',0,tc,tf,tr:+VS_TAGSEPARATOR_args:+ts);
               num_matches = 1;
               //say("tn="tn" tc="tc" tt="tt" tf="tf" ts="ts);
               if (rt.return_type!='' && !pos('(',tr)) {
                  _str orig_return_type=rt.return_type;
                  status = _c_get_return_type_of(errorArgs,tag_files,'()',rt.return_type,
                                                 0,false,VS_TAGFILTER_ANYPROC,
                                                 false, false, rt, visited, depth+1);
                  if (!status) {
                     tag_tree_decompose_tag(rt.taginfo, tn,tc,tt,tf,ts,tr);
                     tag_clear_matches();
                     tag_insert_match('',tn,tt,'',0,tc,tf,tr:+VS_TAGSEPARATOR_args:+ts);
                     num_matches++;
                  } else {
                     // this is a typedef'd function pointer
                     status = _c_get_return_type_of(errorArgs,tag_files,tr,
                                                    '',0,0,VS_TAGFILTER_TYPEDEF,
                                                    0, false, rt, visited, depth+1);
                     if (!status) {
                        tag_tree_decompose_tag(rt.taginfo, tn,tc,tt,tf,ts,tr);
                        tag_clear_matches();
                        tag_insert_match('',tn,tt,'',0,tc,tf,tr:+VS_TAGSEPARATOR_args:+ts);
                        num_matches++;
                     }
                  }
               }
            }
            if (slickc && num_matches == 0 && _e_match_procs(match_symbol)) {
               // probably don't need to do this anymore
               //say("_c_fcthelp_get: 2");
               num_matches = 1;
            }
            if ((slickc || javascript || isphp) && num_matches == 0) {
               // fallback case for slick-C, ignore prefix expression
               //say("trying again, flags="match_flags);
               tag_clear_matches();
               tag_list_symbols_in_context(match_symbol, '', 0, 0, tag_files, '',
                                           num_matches, def_tag_max_function_help_protos,
                                           match_flags, context_flags,
                                           true, case_sensitive, visited, depth+1);
            }
            if (slickc && match_symbol=='show') {
               /*
               save_pos(show_p);
               save_search(show_s1,show_s2,show_s3,show_s4,show_s5);
               c_next_sym();
               if (gtk==TK_STRING) {
                  if (pos(":v['\"]$",gtkinfo,1,'r')) {
                     _str form_name = substr(gtkinfo,pos('s'),pos('')-1);
                     say("_c_fcthelp_get: special show case, form="form_name);
                     tag_push_matches();
                     tag_match_symbol_in_context(form_name, '', 0, 0, tag_files,
                                                 num_matches, VSCODEHELP_MAXFUNCTIONHELPPROTOS,
                                                 VS_TAGFILTER_GUI, context_flags,
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
            if ((slickc || javascript || isphp) && num_matches == 0) {
               // double-fallback for slick-C and Javascript, ignoring prefix
               // expression and class scoping completely
               tag_clear_matches();
               tag_list_any_symbols(0, 0, match_symbol, tag_files,
                                    VS_TAGFILTER_ANYPROC, VS_TAGCONTEXT_ONLY_non_static,
                                    num_matches, def_tag_max_function_help_protos,
                                    true, case_sensitive);
            }
            //if (match_symbol == '') {
               // this could be a function pointer call, last_id is empty string
               //say("***** NOW WHAT!!! *****");
            //}
         } else {
            idexp_info.lastid = match_symbol;
         }

         //say("_c_fcthelp_get: num_matches="tag_get_num_of_matches());

         // check if the symbol was on the kill list for this extension
         if (_check_killfcts(match_symbol, rt.return_type, flags)) {
            continue;
         }

         // remove duplicates from the list of matches
         int i,j;
         int unique_indexes[]; unique_indexes._makeempty();
         _str duplicate_indexes[]; duplicate_indexes._makeempty();
         if (!isrul) {
            removeDuplicateFunctions(unique_indexes,duplicate_indexes);
         } else {
            for (i=0; i<tag_get_num_of_matches(); i++) {
               unique_indexes[i]=i+1;
               duplicate_indexes[i]="";
            }
         }

         VS_TAG_BROWSE_INFO allMatches[];
         tag_get_all_matches( allMatches );
         _str cur_line_match = '';
         int cur_line_index = -1;
         int num_unique = unique_indexes._length();

         for (i=0; i<num_unique; i++) {
            j = unique_indexes[i];

            _str tag_file = '';
            _str proc_name = '';
            _str type_name = '';
            _str file_name = '';
            _str class_name = '';
            int line_no = 0;

            tag_get_match(j,tag_file,proc_name,type_name,
                          file_name,line_no,class_name,tag_flags,
                          signature,return_type);
            if (_LanguageInheritsFrom('py') && type_name=='func' &&
                pos(VS_TAGSEPARATOR_package,class_name) &&
                !(tag_flags & VS_TAGFLAG_static) &&
                (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) || is_py_constructor_call)
                ) {
               //parse signature with ','signature;
               ++ParamNum;
            }
            if ((tag_flags & VS_TAGFLAG_template) && signature=='') {
               tag_get_detail2(VS_TAGDETAIL_match_template_args, j, signature);
            }
            // maybe kick out if already have match or more matches to check
            boolean is_symbol_under_cursor = false;
            if (match_list._length()>0 || i+1<num_unique) {
               if (symbol_to_match == null && file_eq(file_name,p_buf_name) && line_no:==p_line) {
                  //continue;
                  is_symbol_under_cursor = true;
               }
               if (tag_tree_type_is_class(type_name)) {
                  continue;
               }
               if (signature=='' && (tag_flags & VS_TAGFLAG_extern)) {
                  continue;
               }
               if (type_name :== 'define') {
                  if (signature == '') {
                     continue;
                  }
               }
            }
            _str list_proc_name=proc_name;
            if (tag_flags & VS_TAGFLAG_operator) {
               list_proc_name= "operator "list_proc_name;
            }
            if (class_name != '') {
               if (javascript || isjava || isdlang || slickc || isphp) {
                  list_proc_name = class_name '.' list_proc_name;
               } else {
                  list_proc_name = class_name '::' list_proc_name;
               }
            }
            if (tag_tree_type_is_func(type_name)) {
               if (signature == 'void' && !isjava && !javascript && !isrul) {
                  signature = '';
               }
            } else if (type_name :== 'define') {
               return_type = '#define';
            }
            if (!isrul) {
               type_name='proc';
            }
            if(symbol_to_match != null) {
               match_list[match_list._length()] = symbol_to_match.member_name "\t" symbol_to_match.type_name "\t" symbol_to_match.arguments "\t" symbol_to_match.return_type "\t" j "\t" duplicate_indexes[i];
               break;
            } else {
               match_list[match_list._length()] = list_proc_name "\t" type_name "\t" signature "\t" return_type"\t"j"\t"duplicate_indexes[i];
               if (is_symbol_under_cursor) {
                  cur_line_index = match_list._length()-1;
                  cur_line_match = match_list[cur_line_index];
               }
            }
            //say("match_list[i] = "match_list[match_list._length()-1]);
         }

         // get rid of any duplicate entries
         match_list._sort();
         if (isrul) {
            _rul_merge_and_remove_duplicates(match_list);
         }

         // if we are in the parameter list for a function declaration or
         // function definition, make it the preferred match (first in list)
         // unless there is another match of a different type (proc vs. proto)
         if (cur_line_match != '' && match_list._length() >= 2) {
            boolean have_other_types = false;
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
               cur_line_match = '';
            }
         }

         // if the first match is the symbol under the cursor, then
         // move it to the end of the list
         if (cur_line_match!='' && match_list[0] == cur_line_match && match_list._length() >= 2) {
            match_list[0] = match_list[match_list._length()-1];
            match_list[match_list._length()-1] = cur_line_match;
         }

         // translate functions into struct needed by function help
         boolean have_matching_params = false;
         if (match_list._length()>0) {
            FunctionHelp_list._makeempty();
            FunctionHelp_HelpWord = match_symbol;

            //say("FunctionHelp_cursor_x="FunctionHelp_cursor_x" lastid="lastid);
            for (i=0; i<match_list._length(); i++) {
               int k = FunctionHelp_list._length();
               if (k >= def_tag_max_function_help_protos) break;
               _str match_tag_name = '';
               _str match_type_name = '';
               _str imatch = '';
               _str duplist = '';
               parse match_list[i] with match_tag_name "\t" match_type_name "\t" signature "\t" return_type"\t"imatch"\t"duplist;

               // substitute template arguments
               int ti;
               for (ti = 0; ti < rt.template_names._length(); ++ti) {
                  _str ta = rt.template_names[ti];
                  if (rt.template_types._indexin(ta)) {
                     _str tt = tag_return_type_string(rt.template_types:[ta],false);
                     return_type = stranslate(return_type, tt, ta, 'ew');
                     signature   = stranslate(signature,   tt, ta, 'ew');
                  }
               }

               // replace unnatural package/class separators with language specific info
               if (javascript || isjava || isdlang || slickc || isphp) {
                  match_tag_name = stranslate(match_tag_name, '.', VS_TAGSEPARATOR_class);
                  match_tag_name = stranslate(match_tag_name, '.', VS_TAGSEPARATOR_package);
               } else {
                  match_tag_name = stranslate(match_tag_name, '::', VS_TAGSEPARATOR_package);
               }

               //say("tag="match_tag_name" sig="signature" ret="return_type);
               if (substr(signature, 1, 1) == '<' && !slickc && !isjava && !javascript && !isphp) {
                  signature = substr(signature, 2);
                  FunctionHelp_list[k].prototype = return_type' 'match_tag_name'<'signature'>';
               } else {
                  FunctionHelp_list[k].prototype = return_type' 'match_tag_name'('signature')';
               }
               int base_length = length(return_type) + length(match_tag_name) + 2;
               FunctionHelp_list[k].argstart[0]=length(return_type)+1;
               FunctionHelp_list[k].arglength[0]=length(match_tag_name);
               FunctionHelp_list[k].ParamNum=ParamNum;
               FunctionHelp_list[k].ParamName='';
               FunctionHelp_list[k].ParamType='';

               VS_TAG_BROWSE_INFO z_cm;
               tag_get_match_info((int)imatch, z_cm);
               if ((int)imatch >= 1 && (int)imatch <= allMatches._length()) {
                  z_cm = allMatches[(int)imatch-1];
               }
               FunctionHelp_list[k].tagList[0].comment_flags=0;
               FunctionHelp_list[k].tagList[0].comments=null;
               FunctionHelp_list[k].tagList[0].filename=z_cm.file_name;
               FunctionHelp_list[k].tagList[0].linenum=z_cm.line_no;
               FunctionHelp_list[k].tagList[0].taginfo=tag_tree_compose_tag_info(z_cm);
               int z1;
               for (z1=1;;) {
                  _str z='';
                  parse duplist with z duplist;
                  if (z=="") break;
                  if (z!=imatch) {
                     tag_get_match_info((int)z, z_cm);
                     if ((int)imatch >= 1 && (int)imatch <= allMatches._length()) {
                        z_cm = allMatches[(int)imatch-1];
                     }
                     FunctionHelp_list[k].tagList[z1].filename=z_cm.file_name;
                     FunctionHelp_list[k].tagList[z1].linenum=z_cm.line_no;
                     FunctionHelp_list[k].tagList[z1].comment_flags=0;
                     FunctionHelp_list[k].tagList[z1].comments=null;
                     FunctionHelp_list[k].tagList[z1].taginfo=tag_tree_compose_tag_info(z_cm);
                     ++z1;
                  }

               }


               //++base_length;

               // parse signature and map out argument ranges
               j=0;
               int arg_pos=0;
               _str param_name='';
               _str param_type='';
               _str argument = '';
               int arg_start = tag_get_next_argument(signature, arg_pos, argument);
               while (argument != '') {
                  // allow for variable length argument lists
                  if (!pos(',',substr(signature,arg_start))) {
                     if (argument=='...' ||
                         (_LanguageInheritsFrom('java') && pos('...',argument)) ||
                         (_LanguageInheritsFrom('d') && pos('...',argument)) ||
                         (_LanguageInheritsFrom('cs') && pos('[',argument)) ||
                         (_LanguageInheritsFrom('cs') && substr(argument,1,7):=='params ')
                        ) {
                        while (j < ParamNum-1) {
                           j = FunctionHelp_list[k].argstart._length();
                           FunctionHelp_list[k].argstart[j]=base_length+arg_start;
                           FunctionHelp_list[k].arglength[j]=0;
                        }
                     }
                  }
                  j = FunctionHelp_list[k].argstart._length();
                  FunctionHelp_list[k].argstart[j]=base_length+arg_start;
                  FunctionHelp_list[k].arglength[j]=length(argument);
                  if (j == ParamNum) {
                     if (pos("^["word_chars"]*([=]?*|)$",argument,1,'r')) {
                        parse argument with argument '=';
                        param_name=argument;
                        param_type=argument;
                        if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                           FunctionHelp_list[k].ParamType=argument;
                        }
                        FunctionHelp_list[k].ParamName=argument;
                     } else if ((flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) &&
                                pos("^(class|struct|interface):b["word_chars"]*([=]?*|)$",argument,1,'r')) {
                        parse argument with . argument '=';
                        param_name=argument;
                        param_type=argument;
                        FunctionHelp_list[k].ParamName=argument;
                     } else {
                        // parse out the return type of the current parameter
                        _str pslang = p_LangId;
                        boolean utf8=p_UTF8;
                        psindex := _FindLanguageCallbackIndex('%s_proc_search',pslang);
                        int temp_view_id=0;
                        int orig_view_id=_create_temp_view(temp_view_id);
                        p_UTF8=utf8;
                        _insert_text(argument';');
                        top();
                        _str pvarname='';
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
                           _insert_text(argument' a;');
                           top();
                           if (index_callable(psindex)) {
                              status=call_index(pvarname,1,pslang,psindex);
                           } else {
                              status=_VirtualProcSearch(pvarname, false);
                           }
                           if (substr(pvarname,1,2)!='a(') {
                              status=STRING_NOT_FOUND_RC;
                           }
                        }
                        if (!status) {
                           _str ds='', dc='', dy='';
                           int tf=0;
                           param_type='';
                           tag_tree_decompose_tag(pvarname,param_name,dc,dy,tf,ds,param_type);
                           if (!(flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST)) {
                              FunctionHelp_list[k].ParamType=param_type;
                           }
                           FunctionHelp_list[k].ParamName=param_name;
                        }
                        _delete_temp_view(temp_view_id);
                        p_window_id = orig_view_id;
                     }
                  }
                  arg_start = tag_get_next_argument(signature, arg_pos, argument);
               }
               if (ParamNum != 1 && j < ParamNum) {
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
               if (prev_ParamNum!=ParamNum) {
                  FunctionHelp_list_changed=1;
               }
               prev_prefixexp  = idexp_info.prefixexp;
               prev_otherinfo  = idexp_info.otherinfo;
               prev_info_flags = idexp_info.info_flags;
               prev_ParamNum   = ParamNum;

               // This is a hack to avoid a stack when calling this function on a temp view.
               if(symbol_to_match == null && !p_IsTempEditor) {
                  FunctionHelp_cursor_x=(idexp_info.lastidstart_col-p_col)*p_font_width+p_cursor_x;
               }
               break;
            }
         }
      }
   }
   if (idexp_info.lastid!=gLastContext_FunctionName || gLastContext_FunctionOffset!=idexp_info.lastidstart_offset) {
      FunctionHelp_list_changed=1;
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
static int _c_get_type_of_parameter(typeless errorArgs,
                                    typeless tag_files,
                                    VS_TAG_BROWSE_INFO &cm, 
                                    VS_TAG_RETURN_TYPE &rt,
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // jump to the location of the local variable
   if ( cm.seekpos <= 0 ) return VSCODEHELPRC_CONTEXT_NOT_VALID;
   save_pos(auto p);
   _GoToROffset(cm.seekpos);

   // get the basic function help information
   flags  := 0;
   status := _c_fcthelp_get_start(errorArgs,false,true,auto startOffset,auto argOffset,flags);
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

   // now, while we are still in the argument list, get the return type information
   status = _c_parse_return_type(errorArgs, tag_files,
                                 cm.member_name, '',
                                 cm.file_name,
                                 functionHelpList[0].ParamType, false,
                                 rt, visited, depth+1);

   // that's all folks
   restore_pos(p);
   return status;
}

/**
 * Check if we have just typed a space or open paren following
 * a "return" or "goto" statement.  If so, attempt to list function
 * argument help or list the labels for the goto statement.
 * 
 * @return boolean
 */
boolean c_maybe_list_args(boolean OperatorTyped=false)
{
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

      gtk = c_prev_sym();
      if (gtk==TK_ID) {

         // if we have a 'return' statement, list compatible variables
         if (gtkinfo=='return') {
            restore_pos(p);
            left();
            if (get_text_safe():!=' ' && get_text_safe()!='(') {
               break;
            }
            left();
            if (get_text_safe():!='n') {
               break;
            }
            restore_pos(p);
            _do_list_members(OperatorTyped,false,null,null,rt);
            return true;
         }

         // if we have a 'case' statement, list compatible constants for the switch
         if (gtkinfo=='case') {
            restore_pos(p);
            left();
            if (get_text_safe():!=' ') {
               break;
            }
            left();
            if (get_text_safe():!='e') {
               break;
            }
            restore_pos(p);
            _do_list_members(OperatorTyped,false,null,null,rt,null,false,false,true);
            return true;
         }

         // if we have a goto statement, list labels
         if (gtkinfo=='goto') {
            restore_pos(p);
            left();
            if (get_text_safe():!=' ') {
               break;
            }
            left();
            if (get_text_safe():!='o') {
               break;
            }
            restore_pos(p);
            _do_list_members(false,true);
            return true;
         }

      } else if (gtk == '=') {
         restore_pos(p);
         left();
         if (get_text_safe():!=' ') {
            break;
         }
         left();
         if (get_text_safe():!='=') {
            break;
         }
         restore_pos(p);
         _do_list_members(OperatorTyped,false,null,null,rt,null,false,false,true);
         return true;
      }

   } while ( false );

   // restore cursor position and return, doing nothing
   restore_pos(p);
   return false;
}

boolean c_maybe_list_javadoc(boolean OperatorTyped=false)
{
   // check if we are in a docummentation comment
   if (last_event()==" " && 
       (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) &&
       _clex_find(0, "g") == CFG_COMMENT && _inDocComment()) {
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      visited := null;
      status := _doc_comment_get_expression_info(false, idexp_info, visited);
      if (status < 0) {
         return false;
      }
      if (!(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT)) {
         return false;
      }
      if (idexp_info.prefixexp == "@param" || 
          idexp_info.prefixexp == "@see" ||
          idexp_info.prefixexp == "@throw" ||
          idexp_info.prefixexp == "\\param" ||
          idexp_info.prefixexp == "\\see" ||
          idexp_info.prefixexp == "\\throw") {
          _do_list_members(false, true);
          return true;
      }
      // maybe listing attributes of an HTML tag
      if (first_char(idexp_info.prefixexp) == "<" && length(idexp_info.prefixexp) > 1) {
         _do_list_members(false, true);
         return true;
      }
   }

   // not what we were looking for
   return false;
}
