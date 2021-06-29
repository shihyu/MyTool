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
#import "adaptiveformatting.e"
#import "backtag.e"
#import "c.e"
#import "cbrowser.e"
#import "cidexpr.e"
#import "clipbd.e"
#import "codehelp.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "files.e"
#import "guiopen.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "saveload.e"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

void _c_add_member(VS_TAG_BROWSE_INFO &cm,bool doVariable)
{
   _str result=show("-mdi -modal _c_add_member_form",cm,doVariable);
   if (result=="") {
      return;
   }
}
static bool DO_VARIABLE(...){
   if (arg()) ctltext1.p_user=arg(1);
   return ctltext1.p_user;
}
static VS_TAG_BROWSE_INFO BROWSE_INFO(...){
   if (arg()) ctlok.p_user=arg(1);
   return  ctlok.p_user;
}
defeventtab _c_add_member_form;

static int skip_on_change;
void ctltext1.on_change()
{
   if (skip_on_change) {
      return;
   }
   skip_on_change=1;
   text := p_text;
   ctlok.p_enabled=(text!="");
   if (pos("^virtual ",text,1,"r")) {
      ctlvirtual.p_value=1;
      ctlstatic.p_value=0;
      ctlstatic.p_enabled=false;
   } else if (pos("^static ",text,1,"r")) {
      ctlstatic.p_value=1;
      ctlvirtual.p_value=0;
      ctlvirtual.p_enabled=false;
      ctlvirtual.p_value=0;
   } else {
      ctlstatic.p_value=0;
      ctlstatic.p_enabled=true;
      ctlvirtual.p_value=0;
      ctlvirtual.p_enabled=true;
   }
   skip_on_change=0;
}
void ctlvirtual.lbutton_up()
{
   if (p_value) {
      text := ctltext1.p_text;
      _str firstword, rest;
      parse text with firstword rest;
      if (firstword=="static" || firstword=="virtual") {
         text=rest;
      }
      ctlstatic.p_value=0;
      ctlstatic.p_enabled=false;
      ctltext1.p_text="virtual "text;
   } else {
      ctlstatic.p_enabled=true;
   }
}
void ctlstatic.lbutton_up()
{
   if (p_value) {
      text := ctltext1.p_text;
      _str firstword, rest;
      parse text with firstword rest;
      if (firstword=="static" || firstword=="virtual") {
         text=rest;
      }
      ctlvirtual.p_value=0;
      ctlvirtual.p_enabled=false;
      ctltext1.p_text="static "text;
   } else {
      ctlvirtual.p_enabled=true;
   }
}
static bool _member_decl_valid_for_c(_str &decl,_str className,bool doVariable,
                                        _str &memberName,_str &memberDef)
{
   linecomment := "";
   parse decl with decl "//" +0 linecomment;
   if (linecomment!="") {
      _message_box("Line comment not supported");
      return(false);
   }
   // Remove the /* */ comments
   _str temp=decl;
   for (;;) {
      rest := "";
      parse temp with temp "/*" +0 rest;
      if (rest=="") break;
      parse rest with "*/" +0 rest;
      if (rest=="") {
         _message_box("Comment not terminated");
         return(false);
      }
      temp :+= " ":+substr(rest,3);
   }
   decl=strip(decl);
   _maybe_strip(decl, ";");
   b := false;
   error_col := 0;
   if (doVariable) {
      b=_isvariable_decl_valid_for_c(decl,memberName,error_col);
      memberDef="";
   } else {
      b=_isfunction_decl_valid_for_c(decl,className,memberName,memberDef,error_col);
   }
   strappend(decl,";");
   if (linecomment!="") {
      strappend(decl," // "linecomment);
   }
   //_message_box("functionName="memberName">\nfunctionDef="memberDef">");
   return(b);
}
void ctlok.on_create(VS_TAG_BROWSE_INFO cm=null,bool doVariable=true)
{
   if (doVariable) {
      ctlvirtual.p_visible=false;
      p_active_form.p_caption="Add Member Variable";
      ctlexample.p_caption=ctlexample.p_caption:+"  int x";
   } else {
      ctlexample.p_caption=ctlexample.p_caption:+"  void foo(int a)";
   }
   if (cm==null) {
      cm.member_name="testclass";
      cm.file_name="";
   }
   BROWSE_INFO(cm);
   DO_VARIABLE(doVariable);
}
void ctlok.lbutton_up()
{
   decl := ctltext1.p_text;
   decl=strip(decl);
   _str inClassDecl=decl;   // function prototype or variable definition that go inside class

   memberName := "";
   memberDef := "";
   VS_TAG_BROWSE_INFO cm;
   cm=BROWSE_INFO();
   if(!_member_decl_valid_for_c(inClassDecl,cm.member_name,DO_VARIABLE(),memberName,memberDef)) {
      return;
   }
   if (cm.file_name=="") {
      p_active_form._delete_window(1);
      return;
   }
   access := "";
   if (ctlpublic.p_value) {
      access="public";
   } else if (ctlprotected.p_value) {
      access="protected";
   } else if (ctlprivate.p_value) {
      access="private";
   }
   // Check if we already have a member by this name
   _add_member(cm,inClassDecl,memberName,memberDef,access);
}

static bool gquiet;
static void parse_decl_error(_str msg)
{
   if (!gquiet) {
      //_on_slickc_error(1,"");
      _message_box(msg);
   }
}

static _str gtkinfo;
static _str gtk;

static _str c_next_sym2()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   status := 0;
   ch := get_text();
   if (ch=="" || (ch=="/" && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(c_next_sym2());
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
      int cfg=_clex_find(0,'g');
      if(cfg==CFG_NUMBER) {
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
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=(cfg==CFG_KEYWORD)?TK_KEYWORD:TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=="-" && get_text()==">") {
      right();
      gtk=gtkinfo="->";
      return(gtk);

   }
   if (ch==":" && get_text()==":") {
      right();
      gtk=gtkinfo="::";
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
static const COMMON_KEYWORD_TYPES= " void int unsigned short long char double float bool byte ";
static int parse_decl_arg(_str termination_char,_str termination_char2,bool name_required,bool name_allowed,_str &lastid,bool allow_function_args=false,bool have_return_type=false,bool parsing_template_args=false)
{
   lastid="";
   returntype := "";
   _str returnid=(have_return_type)?"x":"";
   lastid="";
   // Parse until there is an open parenthesis
   for (;;) {
      if (returntype!="") {
         strappend(returntype," ");
      }
      strappend(returntype,gtkinfo);
      switch (gtk) {
      case TK_ID:
         if (lastid!="") {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         lastid=gtkinfo;
         c_next_sym2();
         while (gtk=="::") {
            lastid :+= gtkinfo;
            strappend(returntype,gtkinfo);
            c_next_sym2();
            if (gtk!=TK_ID) {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            lastid :+= gtkinfo;
            strappend(returntype,gtkinfo);
            c_next_sym2();
         }
         if (returnid=="") {
            returnid=lastid;
            lastid="";
         } else if (!name_allowed) {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         break;
      case TK_KEYWORD:
         if(!parsing_template_args && pos(" "gtkinfo" "," const struct class ")) {
         } else if (pos(" "gtkinfo" ",COMMON_KEYWORD_TYPES)) {
            returnid=gtkinfo;
         } else {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         c_next_sym2();
         break;
      case "(":
         if (lastid!="") {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         c_next_sym2();
         // This must be unary expression case
         if (parse_decl_arg(")",")",name_required,name_allowed,lastid,false,true)) {
            return(1);
         }
         c_next_sym2();
         // Function pointer declaration?
         if (gtk=="(" && allow_function_args) {
            if(parse_decl_arglist(")",true)) {
               return(1);
            }
            if (gtk!=termination_char && gtk!=termination_char2) {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            return(0);
         }
         if (gtk!="[") {
            if (gtk!=termination_char && gtk!=termination_char2) {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            return(0);
         }
      case "[":
         if (returnid=="" || (lastid=="" && name_required)) {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         while (gtk=="[") {
            c_next_sym2();
            if (gtk!="]") {
               parse_decl_error("Expecting closing bracket");
               return(1);
            }
            c_next_sym2();
         }
         if (gtk!=termination_char && gtk!=termination_char2) {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         return(0);
      case "<":
         {
            if (returnid=="" || lastid!="") {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            if(parse_decl_arglist(">",false)) {
               return(1);
            }
         }
         break;
      case "*":
      case "&":
         if (returnid=="" || lastid!="") {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         c_next_sym2();
         break;
      case "=":
         {
            int start_col=p_col-1;
            c_next_sym2();
            if (returnid=="" || lastid=="" || termination_char!=")") {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            if(skip_default_param_expression(termination_char,termination_char2,parsing_template_args)) {
               return(1);
            }
            end_col := p_col;
            p_col=start_col;
            _delete_text(end_col-start_col-1);
            //get_line(line);_message_box(line);
            ++p_col;
            return(0);
         }
         break;
      default:
         if (gtk==termination_char || gtk==termination_char2) {
            if (returnid=="" || (lastid=="" && name_required)) {
               parse_decl_error("Invalid declaration");
               return(1);
            }
            return(0);
         }
         //say(gtk" "gtkinfo);
         parse_decl_error("Invalid declaration");
         return(1);
      }
   }
}
static int parse_decl_arglist(_str termination_char=")",bool name_allowed=true)
{
   c_next_sym2();
   if (gtk==termination_char) {
      c_next_sym2();
      return(0);
   }
   for (;;) {
      lastid := "";
      if(parse_decl_arg(termination_char,",",false,name_allowed,lastid,true)) {
         return(1);
      }
      if (gtk!=",") {
         if (gtk!=termination_char) {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         c_next_sym2();
         return(0);
      }
      c_next_sym2();
   }
}
static int skip_default_param_expression(_str termination_char,_str termination_char2,bool parsing_template_args)
{
   if (gtk==termination_char || gtk==termination_char2) {
      parse_decl_error("Invalid declaration");
      return(1);
   }
   nesting := 0;
   _str ch1="(",ch2=")";
   if (parsing_template_args) {
      ch1="<";ch2=">";
   }
   for (;;) {
      //say("tk="gtkinfo" t1="termination_char" t2="termination_char2);
      if (gtk==ch1) {
         ++nesting;
      } else if (gtk==ch2 && nesting) {
         --nesting;
      } else if (!nesting && (gtk==termination_char || gtk==termination_char2)) {
         return(0);
      } else if (gtk=="" || gtk=='\' || gtk==";" || gtk=="{" || gtk=="}") {
         parse_decl_error("Invalid declaration");
         return(1);
      }
      c_next_sym2();
   }
}
static int skip_paren_expression()
{
   nesting := 0;
   for (;;) {
      if (gtk=="(") {
         ++nesting;
      } else if (gtk==")") {
         --nesting;
         if (nesting<=0) {
            return(0);
         }
      } else if (gtk=="" || gtk=='\' || gtk==";" || gtk=="{" || gtk=="}") {
         parse_decl_error("Invalid declaration");
         return(1);
      }
      c_next_sym2();
   }
}
static bool _isfunction_decl_valid_for_c2(_str decl,_str className,_str &functionName,_str &functionDef)
{
   functionDef="";
   c_next_sym2();
   returntype := "";
   returnid := "";
   lastid := "";
   lastid_col := 0;
   destructor_col := 0;
   isConstructor := 0;
   isDestructor := 0;

   // Parse until there is an open parenthesis
outer_loop:
   for (;;) {
      switch (gtk) {
      case TK_ID:
         if (returntype!="") strappend(returntype," ");
         strappend(returntype,gtkinfo);
         if (lastid!="") {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         lastid=gtkinfo;
         lastid_col=p_col-length(lastid);
         c_next_sym2();
         while (gtk=="::") {
            lastid :+= gtkinfo;
            strappend(returntype,gtkinfo);
            c_next_sym2();
            if (gtk!=TK_ID) {
               parse_decl_error("Invalid declaration");
               return(false);
            }
            lastid :+= gtkinfo;
            strappend(returntype,gtkinfo);
            c_next_sym2();
         }
         if (returnid=="") {
            returnid=lastid;
            lastid="";
         }
         break;
      case TK_KEYWORD:
         if (returntype!="") strappend(returntype," ");
         strappend(returntype,gtkinfo);
         if (pos(" "gtkinfo" "," const constexpr constinit consteval mutable volatile static virtual struct class inline restrict export ")) {
         } else if (pos(" "gtkinfo" ",COMMON_KEYWORD_TYPES)) {
            returnid=gtkinfo;
         } else if (gtkinfo=="operator") {
            //int operator ==(const BOOKMARKLIST &item2) const {
            parse_decl_error("operator declarations not supported");
            return(false);
         } else {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         c_next_sym2();
         break;
      case "<":
         if (returntype!="") strappend(returntype," ");
         strappend(returntype,gtkinfo);
         {
            if (returnid=="" || lastid!="") {
               parse_decl_error("Invalid declaration");
               return(false);
            }
            if(parse_decl_arglist(">",false)) {
               return(false);
            }
         }
         break;
      case "(":
         if (returnid=="") {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         if (className==returntype) {
            isConstructor=1;
         } else if ("~ "className==returntype ) {
            isDestructor=1;
         } else if ("virtual ~ "className==returntype) {
            isDestructor=1;
         }
         if (lastid=="" && !(isConstructor+isDestructor)) {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         if (isDestructor) {
            c_next_sym2();
            if (gtk!=")") {
               if (gtk==TK_KEYWORD && gtkinfo=="void") {
                  c_next_sym2();
                  if (gtk!=")") {
                     parse_decl_error("Destructor cannot have arguments");
                     return(false);
                  }
               } else {
                  parse_decl_error("Destructor cannot have arguments");
                  return(false);
               }
            }
            c_next_sym2();
         } else {
            if(parse_decl_arglist(")",true)) {
               return(false);
            }
         }
         break outer_loop;
      case "*":
      case "&":
         if (returntype!="") strappend(returntype," ");
         strappend(returntype,gtkinfo);
         if (returnid=="" || lastid!="") {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         c_next_sym2();
         break;
      case "~":  // Declaring destructor
         destructor_col=p_col-1;
         if (returntype!="" && returntype!="virtual") {
            parse_decl_error("Invalid declaration");
            return(false);
         }
         if (returntype!="") strappend(returntype," ");
         strappend(returntype,gtkinfo);
         c_next_sym2();
         break;
      default:
         parse_decl_error("Invalid declaration");
         return(false);
      }
   }
   if ((lastid=="" && !(isConstructor + isDestructor)) || pos("::",lastid)) {
      parse_decl_error("Invalid declaration");
      return(false);
   }
   if (gtk==TK_KEYWORD && gtkinfo=="const") {
      c_next_sym2();
   }
   nofunctiondef := false;
   if (gtk=="=") {
      nofunctiondef=true;
      c_next_sym2();
      if (gtk!=TK_NUMBER || gtkinfo!="0") {
         parse_decl_error("Invalid declaration");
         return(false);
      }
      c_next_sym2();
   }
   if (isConstructor+isDestructor) {
      lastid=className;
   }
   initializer_col := 0;
   if (className!="" && returntype==className) {
      if (gtk==":") {
         initializer_col=p_col;
         c_next_sym2();
         for (;;) {
            if (gtk!=TK_ID) {
               parse_decl_error("Invalid declaration");
               return(false);
            }
            c_next_sym2();
            while (gtk=="::") {
               c_next_sym2();
               if (gtk!=TK_ID) {
                  parse_decl_error("Invalid declaration");
                  return(false);
               }
               c_next_sym2();
            }
            if (gtk!="(") {
               parse_decl_error("Invalid declaration");
               return(false);

            }
            skip_paren_expression();
            c_next_sym2();
            if (gtk!=",") {
               break;
            }
            c_next_sym2();
         }
      }
   }
   if (gtk!=";") {
      parse_decl_error("Invalid declaration");
      return(false);
   }
   if (isDestructor) {
      functionName="~"lastid;
   } else {
      functionName=lastid;
   }
   if (nofunctiondef) {
      functionDef="";
   } else {
      get_line(functionDef);
      if (initializer_col) {
         functionDef=substr(functionDef,1,initializer_col-2);
      } else {
         functionDef=substr(functionDef,1,length(functionDef)-1);
      }
      functionDef=strip(functionDef);
      if (destructor_col) {
         lastid_col=destructor_col;
      }
      functionDef=substr(functionDef,1,lastid_col-1):+
         _chr(1)"::":+
         substr(functionDef,lastid_col);
   }
   if (isConstructor + isDestructor) {
      insert_line("};");
      top();up();
      insert_line("class "className"{");
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   //say("num="tag_get_num_of_context());
   if(tag_get_num_of_context()!=1+isConstructor+isDestructor) {
      parse_decl_error("Invalid declaration");
      return(false);
   }
   tag_name := "";
   tag_get_detail2(VS_TAGDETAIL_context_name, 1, tag_name);
   if (tag_name != lastid) {
      parse_decl_error("Invalid declaration");
      return(false);
   }
   if (pos("^virtual ",functionDef,1,"r") || pos("^static ",functionDef,1,"r")) {
      parse functionDef with . functionDef;
   }
   return(true);
}
static bool _isvariable_decl_valid_for_c(_str decl,_str &variableName,int &error_col)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _SetEditorLanguage("c");
   insert_line(decl";");
   begin_line();
   c_next_sym2();
   if (gtk==TK_KEYWORD && gtkinfo=="static") {
      c_next_sym2();
   }
   int status=parse_decl_arg(";",";",true,true,variableName,true,false);
   if (!status) {
      c_next_sym2();
      if (gtk!="") {
         parse_decl_error("Invalid declaration");
         status=1;
      }
   }
   error_col=p_col;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return((status)?false:true);
}

static bool _isfunction_decl_valid_for_c(_str decl,_str className,_str &functionName,_str &functionDef,int &error_col)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _SetEditorLanguage("c");
   insert_line(decl";");
   begin_line();
   b := _isfunction_decl_valid_for_c2(decl,className,functionName,functionDef);
   error_col=p_col;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(b);
}
/**
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
static int _add_InClassDecl(int context_id,VS_TAG_BROWSE_INFO cm,_str inClassDecl,_str memberName,_str &filenameDef)
{
/*
   tag_push_context();
int VSAPI vsc_list_tags(int output_view_id,char *filename_p,char *extension_p)
   vsc_list_tags(0,"",inClassDecl,VSLTF_SET_TAG_CONTEXT|VSLTF_READ_FROM_STRING,
                 0, // tree_wid
                 length(inClassDecl),  // length of string

                 );
   tag_pop_context();
*/
   if (context_id<=0) {
      _message_box("Unable to parse new definition");
      return(1);
   }
   filenameDef="";
   case_sensitive := p_EmbeddedCaseSensitive;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   name := "";
   tag_get_detail2(VS_TAGDETAIL_context_name, context_id, name);
   rline := p_RLine;
   if (case_sensitive) {
      if (name!=memberName) {
         _message_box("Unable to parse new definition");
         return(1);
      }
   } else {
      if (!strieq(name,memberName)) {
         _message_box("Unable to parse new definition");
         return(1);
      }
   }
   new_signature := "";
   type_name := "";
   tag_flags := SE_TAG_FLAG_NULL;
   tag_get_detail2(VS_TAGDETAIL_context_args, context_id, new_signature);
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
   isinline := (SE_TAG_FLAG_INLINE & tag_flags);
   isfunc   := tag_tree_type_is_func(type_name);
   //say(new_signature);

   _UpdateContext(true);
   tag_files := tags_filenamea(p_LangId);
   num_matches := 0;
   tag_clear_matches();
   //say("***************");
   //say("x="cm.qualified_name);
   //tag_list_in_class();
   VS_TAG_RETURN_TYPE visited:[];
   tag_list_in_class("",cm.qualified_name, 0, 0, tag_files,
                     num_matches,def_tag_max_find_context_tags,
                     SE_TAG_FILTER_ANYTHING,
                     SE_TAG_CONTEXT_ACCESS_PRIVATE|SE_TAG_CONTEXT_ONLY_THIS_CLASS,
                     false, case_sensitive, null, null, visited, 1);
   //say("num_matches="num_matches);
   for (match_id:=1; match_id<=num_matches; ++match_id) {
      tag_get_match_browse_info(match_id, auto match_cm);
      if (match_cm.line_no==rline) {
         continue;
      }
      //say("tag_name="tag_name);
      if (filenameDef=="" && !(match_cm.flags & SE_TAG_FLAG_INCLASS) &&
          tag_tree_type_is_func(match_cm.type_name) &&
          (isinline == (match_cm.flags & SE_TAG_FLAG_INLINE))
          ) {
         filenameDef=match_cm.file_name;
      }
      // say("signature="signature" "new_signature);
      // say("i="match_id" "context_id" "tag_name" c="class_name" s="signature);
      // say("type="type_name);
      // say("inclass="(tag_flags & SE_TAG_FLAG_INCLASS));
      // say("isfunc "isfunc" "tag_tree_type_is_func(type_name));
      if(!isfunc || !tag_tree_type_is_func(match_cm.type_name) ||
          !tag_tree_compare_args(VS_TAGSEPARATOR_args:+match_cm.arguments,new_signature,false)
         ) {
         match := false;
         if (case_sensitive) {
            if (match_cm.member_name==memberName) {
               match=true;
            }
         } else {
            if (!strieq(match_cm.member_name,memberName)) {
               match=true;
            }
         }
         if (match) {
            _message_box(nls("%s is already defined in this class",memberName));
            return(1);
         }
      }
   }
   return(0);
}
static int _get_template_args(_str signature,_str &template_args)
{
   termination_char := ")"; // Allow default arguments = xxx
   template_args="";
   c_next_sym2();
   if (gtk==termination_char) {
      parse_decl_error("Invalid declaration");
      return(1);
   }
   for (;;) {
      lastid := "";
      if(parse_decl_arg(termination_char,",",true,true,lastid,true,false,true)) {
         return(1);
      }
      if (template_args=="") {
         template_args=lastid;
      } else {
         strappend(template_args,","lastid);
      }
      if (gtk!=",") {
         if (gtk!=termination_char) {
            parse_decl_error("Invalid declaration");
            return(1);
         }
         c_next_sym2();
         return(0);
      }
      c_next_sym2();
   }
}
int _c_get_template_classdef_info(_str signature,_str &template_line,_str &className,bool quiet=false)
{
   template_line="";
   _str template_args;
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   insert_line(signature")");
   _begin_line();
   orig_quiet := gquiet;
   gquiet=quiet;
   int status=_get_template_args(signature,template_args);
   gquiet=orig_quiet;
   c_next_sym2();
   if (status || gtk!="") {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      if (!quiet) {
         _message_box("Unable to parse template arguments");
      }
      return(1);
   }
   get_line(auto line);
   template_line="template <"substr(line,1,length(line)-1)">";
   className :+= "<"template_args">";
   _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   return(0);
}
static int _add_member(VS_TAG_BROWSE_INFO cm,_str inClassDecl,_str memberName,_str memberDef,_str access)
{
   //status=_BufEdit(cm.arguments.
   int buf_id=_BufEdit(cm.file_name,"",false,"",true);
   if (buf_id<0) {
      if (buf_id==FILE_NOT_FOUND_RC) {
         _message_box(nls("File '%s' not found",cm.file_name));
      } else {
         _message_box(nls("Unable to open '%s'",cm.file_name)".  "get_message(buf_id));
      }
      return(1);
   }
   int temp_view_id,orig_view_id;
   _open_temp_view("",temp_view_id,orig_view_id,"+bi "buf_id);
   if (_QReadOnly()) {
      _message_box(nls("File '%s' is read only",p_buf_name));
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return(ACCESS_DENIED_RC);
   }

   int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,false);
   if (status) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return(1);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   int context_id = tag_current_context();
   if (context_id<0) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      _message_box("Unable to find this class");
      return(1);
   }
   type := "";
   outer_class := "";
   signature := "";
   tag_flags := 0;
   scope_seekpos := 0;
   end_seekpos := 0;
   seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_class, context_id, outer_class);
   tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,tag_flags);
   tag_get_detail2(VS_TAGDETAIL_context_args,context_id,signature);
   _str className=cm.qualified_name;
   className=stranslate(className,"::",VS_TAGSEPARATOR_class);
   className=stranslate(className,"::",VS_TAGSEPARATOR_package);
   template_line := "";
   if ((tag_flags & SE_TAG_FLAG_TEMPLATE) && memberDef!="") {
      status=_c_get_template_classdef_info(signature,template_line,className);
      if (status) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         _message_box("Unable to parse template arguments");
         return(1);
      }
   }
   memberDef=stranslate(memberDef,className,_chr(1));
   bool inserted_line;
   old_modify := p_modify;
   int old_TruncateLength=p_TruncateLength;
   p_TruncateLength=0;
   int indent_col=c_indent_col(0,false)-1;
   _c_prepare_access(access,seekpos,scope_seekpos,end_seekpos,type,outer_class,inserted_line,indent_col);
   _end_line();

   insert_line(indent_string(indent_col):+inClassDecl);
   linenum := p_line;p_col=indent_col+1;
   _UpdateContext(true);

   filename := "";
   context_id=tag_current_context();
   status=_add_InClassDecl(context_id,cm,inClassDecl,memberName,filename);

   need_filename := !status && memberDef!="" && filename=="";

   line1 := line2 := "";
   p_line=linenum;
   if (inserted_line) {
      up();
      get_line(line2);
      _delete_line();
   }
   get_line(line1);
   _delete_line();
   p_modify=old_modify;

   if (need_filename) {
      // Determine the file which is to contain the definition of the function
      wildcards := "";
      parse def_file_types with '(^|,)C/C\+\+ Files \(','ri' wildcards')';
      filename=_OpenDialog("-new -mdi -modal","Open File for Definitions",wildcards,"",OFN_NODATASETS,"",cm.file_name);
      if (filename=="") {
         status=1;
      } else {
         filename=strip(filename,'B','"');
      }
   }
   activate_window(temp_view_id);
   /*
      Here we special case the same_file so that undo works better.
      Since edit does a set focus this seems to start an undo step.
      That's why we always deleting what was inserted an then reinsert
      below.
   */
   same_file := !status && memberDef!="" && _file_eq(p_buf_name,filename);
   buf_id= -1;
   int temp_view_id2,orig_view_id2;
   if (same_file) {
      activate_window(orig_view_id);
      p_active_form._delete_window(0);
      status = edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      if (status) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return(status);
      }
      get_window_id(orig_view_id);
   } else if (!status && memberDef!="") {
      // Check if this file or buffer is read-only
      buf_id=_BufEdit(filename,"",false,"",true);
      if (buf_id>=0) {
         _open_temp_view("",temp_view_id2,orig_view_id2,"+bi "buf_id);
         if (_QReadOnly()) {
            _delete_temp_view(temp_view_id2);
            _message_box(nls("File '%s' is read only",filename));
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            return(ACCESS_DENIED_RC);
         }
         activate_window(orig_view_id2);
      } else {
         if (buf_id==FILE_NOT_FOUND_RC) {
            _message_box(nls("File '%s' not found",filename));
         } else {
            _message_box(nls("Unable to open file '%s'",filename));
         }
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return(buf_id);
      }
   }

   // Syntax expansion options so we can correctly format braces
// typeless be_style, indent_fl;
// parse name_info(_edit_window().p_index) with . . . . be_style indent_fl . ;
// if( !isinteger(be_style) ) {
//    // Default to Style 1 (K&R braces), insert braces
//    be_style=4;
// }

   if (!status) {
      p_line=linenum-1;
      if (inserted_line) {
         up();
         insert_line(line2);
      }
      insert_line(line1);
   }
   p_TruncateLength=old_TruncateLength;

   if (!status) {
      _TagDelayCallList();
      if (!same_file) {
         //file_date=p_file_date;
         status=_save_file(build_save_options(p_buf_name));
         if ( status ) {
            p_line=linenum;
            if (inserted_line) {
               up();
               _delete_line();
            }
            _delete_line();
            p_modify=old_modify;

            _message_box(nls('Unable to save file "%s"',p_buf_name)".  "get_message(status));
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            _TagProcessCallList();
            if (memberDef!="") {
               _delete_temp_view(temp_view_id2);
            }
            return(status);
         }
         TagFileOnSave();
         if (memberDef!="") {
            _delete_temp_view(temp_view_id2,false);
         }
      }
      _delete_temp_view(temp_view_id,!same_file);activate_window(orig_view_id);
      if (!same_file) {
         p_active_form._delete_window(0);
      }
      if (memberDef!="") {
         if (!same_file) {
            status = edit("+bi "buf_id,EDIT_DEFAULT_FLAGS|EDIT_NOWARNINGS);
            if (status && status!=NEW_FILE_RC) {
               _TagProcessCallList();
               return(status);
            }
         }
         bottom();
         line := "";
         get_line(line);
         if (line!="") {
            insert_line("");
         }
         if (template_line!="") {
            insert_line(template_line);
         }
         if( p_begin_end_style == 0 ) {
            // Style 1 braces (K&R)
            insert_line(memberDef" {");
         } else {
            // Style 2 or 3, so brace goes on next line
            insert_line(memberDef);
            indent := "";
            if( (p_begin_end_style == VS_C_OPTIONS_STYLE2_FLAG) && def_style3_indent_all_braces ) {
               indent=indent_string(p_SyntaxIndent);
            }
            insert_line(indent:+"{");
         }
         indent := "";
         if( (p_begin_end_style == VS_C_OPTIONS_STYLE2_FLAG) && def_style3_indent_all_braces ) {
            indent=indent_string(p_SyntaxIndent);
         }
         //insert_line(indent:+"{");
         insert_line(indent:+"}");
         up();
         insert_line(indent_string(p_SyntaxIndent));
         _BGReTag2(true);
      }
      _TagProcessCallList();
   } else {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
   }
   return(status);
}
/**
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
int _c_delete_tag(int context_id,bool comment_out=true,bool selectForEdit=true)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   did_select := false;
   type_name := "";
   start_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
   start_col := 1;
   do_char_selection := false;
   if (_expand_tabsc(1,p_col-1)!="") {
      start_col=p_col;
   }
   _GoToROffset(start_seekpos);
   first_line := p_line;
   last_line  := p_line;
   start_line := p_line;
   if (start_col>1 || _do_default_get_tag_header_comments(first_line, last_line, start_line)) {
      first_line= start_line;
   }
   if (start_col==1) {
      p_line=first_line;
      for (;;) {
         up();
         get_line(auto line);
         if (p_line==0 || line!="") {
            down();
            break;
         }
      }
      first_line= p_line;
   }
   status := 0;
   if (type_name=="proc" || type_name=="func" || type_name=="constr" || type_name=="destr") {
      end_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
      _GoToROffset(end_seekpos);
   } else {
      status=search(";","@hxcs");
      if (status) {
         _message_box("Unable to find end of variable defition");
         return(1);
      }
      ++p_col;
   }
   delete_all_of_last_line := true;
   int last_col;
   last_line=p_line;
   save_pos(auto p);
   _clex_skip_blanks();
   if (p_line==last_line && p_col<=_text_colc()) {
      restore_pos(p);last_col=p_col;
      delete_all_of_last_line=false;
   } else {
      restore_pos(p);_end_line();
      last_col=p_col+1;
   }
   _str markid;
   markid=_alloc_selection();
   if (comment_out) {
      if (!delete_all_of_last_line) {
         _message_box("Unable to safely comment last line of this definition or prototype");
         return(1);
      }
      // Prefix each line with //DEL
      _str prefix=C_DEL_TAG_PREFIX;
      p_line=first_line;
      for (;p_line<=last_line;) {
         if (p_line==first_line) {
            p_col=start_col;
         } else {
            _begin_line();
         }
         _insert_text(prefix);
         if(down()) break;
      }
      last_col+=length(prefix);
      if (!selectForEdit) {
         _BGReTag2(true);
         return(0);
      }
   }
   _deselect(markid);
   p_col=start_col;
   p_line=first_line;
   _select_char(markid,'E');
   p_line=last_line;p_col=last_col;
   select_it("CHAR",markid,"E");
   if (selectForEdit) {
      _cua_select=1;
      did_select=true;
      line := p_RLine;
      col := p_col;
      //say("edit "p_buf_name);
      status=edit("+bi "p_buf_id,EDIT_DEFAULT_FLAGS);
      if (!status) {
         goto_line(line);
         goto_col(col);
      }
      _str orig_mark=_duplicate_selection("");
      _show_selection(markid);
      _free_selection(orig_mark);
      _BGReTag2(true);
      return(status);
   }
   _delete_selection(markid);
   _free_selection(markid);

   _BGReTag2(true);
   return(0);


}

void _c_prepare_access(_str access, long start_seekpos,
                       long scope_seekpos,long end_seekpos,
                       _str type, _str outer_class,
                       bool &inserted_line=false,
                       int begin_col=1
                      )
{
   _GoToROffset(start_seekpos);

   class_name := "";
   implement_list := "";
   vsImplementFlags := 0;
   class_type := "";

   c_parse_class_definition(class_name,class_type,implement_list,vsImplementFlags);

   default_access := "";
   if(class_type == "class") {
      default_access = "private";
   } else if(class_type == "struct") {
      default_access = "public";
   }

   tag_lock_context();
   inserted_line=false;
   int markid=_alloc_selection();
   cur_seekpos := _QROffset();
   _GoToROffset(end_seekpos);_select_char(markid);
   _GoToROffset(scope_seekpos);_select_char(markid);
   status := search(access":","m@hck");
   for (;;) {
      if (status) {
         break;
      }
      get_line(auto line);
      parse line with line "//";
      if (line==access":") {         
         // Make sure we are not in a nested classes
         int context_id = tag_current_context();
         if (context_id>=0) {
            _str this_type;
            int this_scope_seekpos,this_end_seekpos,this_outer_class;
            tag_get_detail2(VS_TAGDETAIL_context_type, context_id, this_type);
            tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, this_scope_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, this_end_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_class, context_id, this_outer_class);
            if (this_type==type && this_scope_seekpos==scope_seekpos &&
                this_end_seekpos==end_seekpos && this_outer_class==outer_class) {
               break;
            }
         }
      }
      status=repeat_search();
   }
   tag_unlock_context();
   _free_selection(markid);
   if (status && default_access != access) {
      _GoToROffset(end_seekpos);
      up();
   }
   // This is a work around save/undo bug.  Undo back to before the save we want to
   // make sure the modify flag is on!
   if (!p_modify) {
      p_modify=true;
      _undo('S');
   }
   if (status && default_access != access) {
      inserted_line=true;
      insert_line(indent_string(begin_col):+access);
      last_event(":");
      c_colon();
      status=0;
   }
}
/**
 * Generate the signature for a function prototype inserted
 * when we do c_begin for a class.
 *
 * @param match_id             match ID from tagsdb match set
 * @param c_access_flags       bitset of SE_TAG_FLAG_* (SE_TAG_FLAG_access)
 * @param header_list          list of lines to insert as header comment
 * @param indent_col           indentation column
 * @param begin_col            start column (for class)
 * @param make_proto           make a prototype or definition?
 * @param in_class_scope       are we in the class scope or outside?
 * @param className            class name (if we are outside class scope)
 * @param class_signature      class signature (for templates)
 *
 * @return Returns the necessary cursor position
 */
/*
int _c_generate_match_signature(int match_id, int &c_access_flags,
                                _str (&header_list)[],
                                int indent_col, int begin_col,
                                bool make_proto=false,
                                bool in_class_scope=true,
                                _str className="",
                                _str class_signature="")
{
   // get the information about this match
   _str tag_file,tag_name,type_name,file_name,class_name;
   _str signature,return_type,exceptions;
   int tag_flags,line_no;
   tag_get_match(match_id,tag_file,tag_name,type_name,file_name,
                 line_no,class_name,tag_flags,signature,return_type);
   tag_get_detail2(VS_TAGDETAIL_match_throws,match_id,exceptions);
   // generate access specifier keywords
   is_java := false;
   show_access := 0;
   if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('cs')) {
      show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
   } else if (_LanguageInheritsFrom('c') && in_class_scope) {
      access := "";
      switch (c_access_flags) {
      case SE_TAG_FLAG_public:
      case SE_TAG_FLAG_package:
         access="public";
         break;
      case SE_TAG_FLAG_protected:
         access="protected";
         break;
      case SE_TAG_FLAG_private:
         access="private";
         break;
      }
      if (make_proto) {
         // This is slow, but it works
         _UpdateContext(true);
         int context_id = tag_current_context();
         if (context_id<0) {
            if ((tag_flags & SE_TAG_FLAG_access) != c_access_flags) {
               c_access_flags = (tag_flags & SE_TAG_FLAG_access);
               show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
            }
         }  else {
            //
            _str type;
            int scope_seekpos,end_seekpos,outer_class;
            tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type);
            tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_class, context_id, outer_class);
            _c_prepare_access(access,scope_seekpos,end_seekpos,type,outer_class);
         }
      } else {
         if ((tag_flags & SE_TAG_FLAG_access) != c_access_flags) {
            c_access_flags = (tag_flags & SE_TAG_FLAG_access);
            show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
         }
      }
   }

   // generate comment block
   int i;
   for (i=0;i<header_list._length();++i) {
      insert_line(header_list[i]);
   }

   show_inline := 0;
   if (!in_class_scope &&
       file_eq(file_name,p_buf_name) &&
       pos('h',get_extension(p_buf_name))) {
      show_inline=VSCODEHELPDCLFLAG_SHOW_INLINE;
   }
   show_class := 0;
   if (!in_class_scope && class_name!="" && _LanguageInheritsFrom('c')) {
      show_class=VSCODEHELPDCLFLAG_SHOW_CLASS;
   }
   int in_class_def=(in_class_scope)?VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF:0;
   VS_TAG_BROWSE_INFO info;
   tag_browse_info_init(info);
   info.class_name=class_name;
   template_line := "";
   if (className!="" && !make_proto) {
      if (class_signature!="") {
         _c_get_template_classdef_info(class_signature,template_line,className);
      }
      info.class_name=className;
   }
   info.member_name=tag_name;
   info.type_name=type_name;
   if (make_proto) {
      info.flags=tag_flags;
   } else {
      info.flags=tag_flags & ~SE_TAG_FLAG_native;
   }

   // remove initializers from argument list
   if (_LanguageInheritsFrom('c') && !make_proto) {
      signature = stranslate(signature,',','=[^=,]*,','r');
      signature = stranslate(signature,"",'=[^=,]*$','r');
   }

   // get the brace style flags
   typeless expand,be_style,indent_fl;
   parse name_info(_edit_window().p_index) with . expand . . be_style indent_fl .;
   if (!isnumber(be_style)) {
      be_style=VS_C_OPTIONS_STYLE1_FLAG;
   }

   // change pointer and reference type formatting
   space_before_pointer := ' ';
   space_after_pointer := "";
   if (be_style & VS_C_OPTIONS_SPACE_AFTER_POINTER) {
      space_before_pointer="";
      space_after_pointer=' ';
   } else if (be_style & VS_C_OPTIONS_SPACE_SURROUNDS_POINTER) {
      space_before_pointer=' ';
      space_after_pointer=' ';
   }
   signature = stranslate(signature,space_before_pointer'*'space_after_pointer,' *\* *','r');
   signature = stranslate(signature,space_before_pointer'&'space_after_pointer,' *\& *','r');
   return_type = stranslate(return_type,space_before_pointer'*'space_after_pointer,' *\* *','r');
   return_type = stranslate(return_type,space_before_pointer'&'space_after_pointer,' *\& *','r');

   // set up info for generating declaration
   info.return_type=return_type;
   info.arguments=signature;
   info.exceptions=exceptions;
   info.language=p_LangId;

   int result=_c_get_decl(p_LangId,info,
                          VSCODEHELPDCLFLAG_VERBOSE|show_access|show_inline|show_class|in_class_def,
                          indent_string(indent_col),
                          indent_string(begin_col));

   // insert template arguments if needed
   _end_line();
   if (template_line!="") {
      _insert_text("\n"template_line);
   }

   AfterKeyinPos := 0;
   if (make_proto) {
      // just a prototype, so all we need is the semicolon
      _insert_text("\n"result';');
      save_pos(AfterKeyinPos);

   } else {
      _insert_text("\n"result);
      if (be_style & (VS_C_OPTIONS_STYLE1_FLAG|VS_C_OPTIONS_STYLE2_FLAG|VS_C_OPTIONS_BRACE_INSERT_FUNCTION_FLAG)) {
         // style's 2 or 3, new line and indent
         if (be_style & VS_C_OPTIONS_STYLE2_FLAG) {
            indent_col+=p_SyntaxIndent;
         }
         _insert_text("\n"indent_string(indent_col)"{");
      } else {
         _insert_text(" {");
      }
      // save position, then insert close brace
      if (be_style & VS_C_OPTIONS_BRACE_INSERT_LINE_FLAG) {
         insert_line(indent_string(indent_col+p_SyntaxIndent));
      }
      save_pos(AfterKeyinPos);
      if (!make_proto) {
         insert_line(indent_string(indent_col):+'}');
      }
   }

   return (AfterKeyinPos);
}
*/

static const HEADER_FILE_EXTENSIONS= "h hpp hp hh hxx h++ resx xaml inl m";
bool _c_is_header_file(_str filename) {
   _str fext = _get_extension(filename);
   foreach (auto ext in HEADER_FILE_EXTENSIONS) {
      if (ext == fext) {
         return true;
      }
   }
   return false;
}

/**
 * <B>Hook function</B> -- _ext_generate_function
 * <P>
 * Generate the signature for the given browse info
 *
 * @param cm                   browse info describing function to create
 * @param c_access_flags       bitset of SE_TAG_FLAG_* (SE_TAG_FLAG_access)
 * @param header_list          list of lines to insert as header comment
 * @param function_body        code to insert into body of function or null if none.
 * @param indent_col           indentation column
 * @param begin_col            start column (for class)
 * @param make_proto           make a prototype or definition?
 * @param in_class_scope       are we in the class scope or outside?
 * @param className            class name (if we are outside class scope)
 * @param class_signature      class signature (for templates)
 * @param insertion_seekpos    position in file to insert function after. -1 for placing the function in
 *                             the appropriate access area
 *
 * @return Returns the necessary cursor position
 */
int _c_generate_function(VS_TAG_BROWSE_INFO &cm,
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
   // get the information about this match
   // generate access specifier keywords
   is_java := false;
   show_access := 0;

   if(insertion_seekpos > 0) {
      _GoToROffset(insertion_seekpos);
   }

   if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs")) {
      show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
   } else if (_LanguageInheritsFrom("c") && in_class_scope) {
      access := "";
      switch (c_access_flags) {
      case SE_TAG_FLAG_PUBLIC:
      case SE_TAG_FLAG_PACKAGE:
         access="public";
         break;
      case SE_TAG_FLAG_PROTECTED:
         access="protected";
         break;
      case SE_TAG_FLAG_PRIVATE:
         access="private";
         break;
      }
      if (make_proto) {
         // This is slow, but it works
         _UpdateContext(true);
         tag_lock_context();
         int context_id = tag_current_context();
         if (context_id<0) {
            if ((cm.flags & SE_TAG_FLAG_ACCESS) != c_access_flags) {
               c_access_flags = (int)(cm.flags & SE_TAG_FLAG_ACCESS);
               show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
            }
         }  else if(insertion_seekpos < 0){
            _str type;
            int scope_seekpos,end_seekpos,seekpos,outer_class;
            tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_class, context_id, outer_class);
            _c_prepare_access(access,seekpos,scope_seekpos,end_seekpos,type,outer_class,auto inserted_line,begin_col);
         }
         tag_unlock_context();
      } else {
         if ((cm.flags & SE_TAG_FLAG_ACCESS) != c_access_flags) {
            c_access_flags = (int)(cm.flags & SE_TAG_FLAG_ACCESS);
            show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
         }
      }
   }
   
   buf_basename := _strip_filename(p_buf_name, "E");
   tfile_basename := _strip_filename(p_buf_name, "E");

   show_inline := 0;
   if (!in_class_scope &&
       _file_eq(tfile_basename,buf_basename) &&
       _c_is_header_file(p_buf_name)) {
      show_inline=VSCODEHELPDCLFLAG_SHOW_INLINE;
   }

   show_class := 0;
   if (!in_class_scope && cm.class_name!="" && _LanguageInheritsFrom("c")) {
      show_class=VSCODEHELPDCLFLAG_SHOW_CLASS;
   }
   int in_class_def=(in_class_scope)?VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF:0;
   tag_init_tag_browse_info(auto info);
   info.class_name=cm.class_name;
   template_line := "";
   if (className!="" && !make_proto) {
      if (class_signature!="") {
         _c_get_template_classdef_info(class_signature,template_line,className);
      }
      info.class_name=className;
   }
   info.member_name=cm.member_name;
   info.type_name=cm.type_name;
   if (make_proto) {
      info.flags=cm.flags;
   } else {
      info.flags=cm.flags & ~SE_TAG_FLAG_NATIVE;
   }

   // remove initializers from argument list
   if (_LanguageInheritsFrom("c") && !make_proto) {
      cm.arguments = stranslate(cm.arguments,",","=[^=,]*,","r");
      cm.arguments = stranslate(cm.arguments,"","=[^=,]*$","r");
   }

   // change pointer and reference type formatting
   space_before_pointer := " ";
   space_after_pointer := "";
   if (p_pointer_style == VS_C_OPTIONS_SPACE_AFTER_POINTER) {
      space_before_pointer="";
      space_after_pointer=" ";
   } else if (p_pointer_style == VS_C_OPTIONS_SPACE_SURROUNDS_POINTER) {
      space_before_pointer=" ";
      space_after_pointer=" ";
   }


   cm.arguments = stranslate(cm.arguments,space_before_pointer"*"space_after_pointer,' *\* *',"r");
   cm.arguments = stranslate(cm.arguments,space_before_pointer"&"space_after_pointer,' *\& *',"r");
   cm.return_type = stranslate(cm.return_type,space_before_pointer"*"space_after_pointer,' *\* *','r');
   cm.return_type = stranslate(cm.return_type,space_before_pointer"&"space_after_pointer,' *\& *',"r");

   // set up info for generating declaration
   info.return_type=cm.return_type;
   info.arguments=cm.arguments;
   info.exceptions=cm.exceptions;
   info.language=p_LangId;

   // Slick-C cannot have an explicit array return type so 
   // change it to typeless.
   if(_LanguageInheritsFrom("e") && pos("[",info.return_type) != 0) {
      info.return_type="typeless";
   }
   
   //To avoid the comment being put above the access modifier, only insert
   //comment block here when not showing the access modifier.  Otherwaise pass 
   //the comment on _c_get_decl() below to insert after the modifier. 
   if (!((p_LangId == "c") && (show_access))) {
      // generate comment block
      int i;
      for (i=0;i<header_list._length();++i) {
         if (length(strip(header_list[i])) != 0) {
            insert_line(header_list[i]);
         }
      }
      header_list._makeempty();
   }
   
   result := _c_get_decl(p_LangId, info,
                         VSCODEHELPDCLFLAG_VERBOSE|show_access|show_inline|show_class|in_class_def,
                         indent_string(indent_col),
                         indent_string(begin_col), header_list, 
                         (def_use_override_keyword && p_LangId == "c") ? "override-kw" : "" );

   // insert template arguments if needed
   _end_line();

   if (template_line!="") {
      _insert_text("\n"template_line);
   }

   AfterKeyinPos := 0;
   if (make_proto) {
      // just a prototype, so all we need is the semicolon
      _insert_text("\n"result";");
      save_pos(AfterKeyinPos);

   } else {
      updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
      _insert_text("\n"result);
      if (p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3 ||
          p_function_brace_on_new_line) {
         // style's 2 or 3, new line and indent
         if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            indent_col+=p_SyntaxIndent;
         }
         _insert_text("\n"indent_string(indent_col)"{");
      } else {
         _insert_text(" {");
      }
      // save position, then insert close brace
      if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) {
         insert_line(indent_string(indent_col+p_SyntaxIndent));
      }
      save_pos(AfterKeyinPos);
      if (!make_proto) {
         if(function_body != null) {
            _insert_text("\n"function_body);
         }
         insert_line(indent_string(indent_col):+"}");
      }
   }

   return (AfterKeyinPos);
}
