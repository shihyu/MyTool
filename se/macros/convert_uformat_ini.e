#pragma option(pedantic,on)
#include "slick.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"

static void xlat_ada_property(int ibeautifier,_str name,_str value) {
   _str apply=null;
   origname:=name;
   switch (name) {
   case 'BLAdjacentAspectClause':
      name=VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FOR_USE;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAdjacentSubprogramBody':
      name=VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUNS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAdjacentSubprogramDecl':
      name=VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_FUN_PROTOTYPES;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAdjacentTypeDecl':
      name=VSCFGP_BEAUTIFIER_BL_BETWEEN_ADJACENT_TYPE_DECLS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterAspectClause':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_FOR_USE;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterBegin':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_BEGIN;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterIf':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_IF;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterLoop':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_LOOP;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterNestedParenListItem':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_NESTED_LIST_ITEM;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterReturn':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_RETURN;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterSubprogramBody':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_FUNS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterSubprogramDecl':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_FUN_PROTOTYPES;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterSubunitHeader':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_SUBUNIT_HEADER;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLAfterTypeDecl':
      name=VSCFGP_BEAUTIFIER_BL_AFTER_TYPE_DECLS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeAspectClause':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_FOR_USE;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeBegin':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_END;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeIf':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_END_IF;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeLoop':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_END_LOOP;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeNestedParenListItem':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_NESTED_LIST_ITEM;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeReturn':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_RETURN;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeSubprogramBody':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_FUNS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeSubprogramDecl':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_FUN_PROTOTYPES;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeSubunitHeader':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_SUBUNIT_HEADER;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;
   case 'BLBeforeTypeDecl':
      name=VSCFGP_BEAUTIFIER_BL_BEFORE_TYPE_DECLS;
      if (value<0) {
         apply=false;value=0;
      } else {
         apply=true;
      }
      break;

   case 'CommentAfterTypeDeclIndent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_COMMENT_AFTER_TYPE_DECL;
      break;
   case 'ContinuationIndent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION;
      break;
   case 'IfBreakOnLogicalOps':
      name=VSCFGP_BEAUTIFIER_REQUIRE_NEW_LINE_AFTER_LOGICAL_OPERATOR_IN_IF;
      break;
   case 'IfLogicalOpAddContinuationIndent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION;
      break;
   case 'IfLogicalOpLogicalOpAddContinuationIndent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_IF_EXPR_CONTINUATION_MULTIPLE_LOGICAL_OPS;
      break;
   case 'IndentPerLevel':
      name=VSCFGP_BEAUTIFIER_SYNTAX_INDENT;
      break;
   case 'IndentWithTabs':
      name=VSCFGP_BEAUTIFIER_INDENT_WITH_TABS;
      break;
   case 'MaxLineLength':
      name=VSCFGP_BEAUTIFIER_MAX_LINE_LEN;
      break;
   case 'NoTrailingTypeDeclComments':
      //name=VSCFGP_BEAUTIFIER_NL_BEFORE_TRAILING_TYPE_DECL_COMMENTS;
      //name=VSCFGP_BEAUTIFIER_ONELINE_TYPE_DECL_TRAILING_COMMENT;
      name=VSCFGP_BEAUTIFIER_LEAVE_TYPE_DECL_TRAILING_COMMENT;
      value=value?0:1;
      break;
   case 'OneDeclPerLine':
      name=VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_DECL;
      value=value?0:1;
      break;
   case 'OneEnumPerLine':
      name=VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_ENUM;
      value=value?0:1;
      break;
   case 'OneParameterPerLine':
      name=VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_FUN_DECL_PARAMS;
      value=value?0:1;
      break;
   case 'OneStatementPerLine':
      name=VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_STMT;
      value=value?0:1;
      break;
   case 'OperatorBias':
      name=VSCFGP_BEAUTIFIER_WRAP_OPERATORS_BEGIN_NEXT_LINE;
      break;
   case 'OrigTabSize':
      name=VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE;
      break;
   case 'PadAfterBinaryOps':
   case 'PadBeforeBinaryOps':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_OP_BINARY;
      break;
   case 'PadAfterComma':
   case 'PadBeforeComma':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_COMMA;
      break;
   case 'PadAfterLeftParen':
   case 'PadBeforeLeftParen':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_LPAREN;
      break;
   case 'PadAfterRightParen':
   case 'PadBeforeRightParen':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_RPAREN;
      break;
   case 'PadAfterSemicolon':
   case 'PadBeforeSemicolon':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_SEMICOLON;
      break;
   case 'ReservedWordCase':
      if (value<0) {
         value=WORDCASE_LOWER;
         apply=false;
      } else {
         apply=true;
      }
      name=VSCFGP_BEAUTIFIER_WC_KEYWORD;
      break;
   case 'TabSize':
      name=VSCFGP_BEAUTIFIER_TAB_SIZE;
      break;
   case 'TrailingComment':
      name=VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE3;
      break;
   case 'TrailingCommentCol':
      name=VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL;
      if (value<=0) {
         return;
      }
      break;
   case 'TrailingCommentIndent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_TRAILING_COMMENT;
      break;
   case 'VAlignAdjacentComments':
      name=VSCFGP_BEAUTIFIER_ALIGN_ADJACENT_COMMENTS;
      break;
   case 'VAlignAssignment':
      name=VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP;
      break;
   case 'VAlignParens':
   case 'VAlignSelector':
      // Code does nothing with these. Could add these later.
      name='';
      break;
   case 'VAlignDeclColon':
      name=VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_COLON;
      break;
   case 'VAlignDeclInOut':
      name=VSCFGP_BEAUTIFIER_ALIGN_FUN_PARAMS_ON_IN_OUT;
      break;
   }
   if (name=='') {
      return;
   }
   if (substr(origname,1,3)=='Pad') {
      typeless flags=0;
      flags=_beautifier_get_property(ibeautifier,name,flags);
      if (value<0) {
         value=0;apply=false;
      }  else {
         if (substr(name,1,8)=='PadAfter') {
            flags|=2;
         } else {   // PadBefore
            flags|=1;
         }
         value=flags;apply=true;
      }
   }
   if (isinteger(apply)) {
      _beautifier_set_property(ibeautifier,name,value,apply?true:false);
   } else {
      _beautifier_set_property(ibeautifier,name,value);
   }
}

static void xlat_c_property(int ibeautifier,_str name,_str value,_str langId) {
   _str apply=null;
   switch (name) {
   case 'align_on_equal':
      name=VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP;
      break;
   case 'align_on_parens':
      name=VSCFGP_BEAUTIFIER_LISTALIGN2_PARENS;
      value=value?0:1;
      break;
   case 'be_style':
      name=VSCFGP_BEAUTIFIER_BRACELOC_IF;
      /*tvalue:=_beautifier_get_property(ibeautifier,name,'',auto bapply);
      if (isinteger(tvalue)) {
         apply=bapply;
      } */
      if (value==1) {
         value=BES_BEGIN_END_STYLE_1;
      } else if (value==2) {
         value=BES_BEGIN_END_STYLE_2;
      } else if (value==3 || value==4) {
         value=BES_BEGIN_END_STYLE_3;
      } else {
         value=BES_BEGIN_END_STYLE_1;
      }
      break;
   case 'bestyle_on_functions':
      name=VSCFGP_BEAUTIFIER_APPLY_BRACELOC_TO_FUNCTIONS;
      break;
   case 'brace_indent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_BRACES;
      break;
   case 'continuation_indent':
      name=VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION;
      if (value==0) {
         if (langId=='e') {
            value=3;
         } else {
            value=4;
         }
      }
      break;
   case 'cuddle_else':
      name=VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE;
      value=value?0:1;
      break;
   case 'decl_comment_col':
      name=VSCFGP_BEAUTIFIER_DECL_COMMENT_COL;
      break;
   case 'disable_bestyle':
      // This option doesn't really work. Braces can still get slid left or right, just not on different lines.
      name='';
#if 0
      tvalue2:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF);
      if (!isinteger(tvalue2)) tvalue2=BES_BEGIN_END_STYLE_1;
      name=VSCFGP_BEAUTIFIER_BRACELOC_IF;
      apply=value?0:1;
      value=tvalue2;
#endif
      break;
   case 'eat_blank_lines':
      name=VSCFGP_BEAUTIFIER_RM_BLANK_LINES;
      break;
   case 'eat_pp_space':
      name=VSCFGP_BEAUTIFIER_PP_RM_SPACES_AFTER_POUND;
      break;
   case 'indent_access_specifier':
      name=VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS;
      break;
   case 'indent_case':
      name=VSCFGP_BEAUTIFIER_INDENT_CASE;
      break;
   case 'indent_col1_comments':
      name=VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS;
      break;
   case 'indent_comments':
      name=VSCFGP_BEAUTIFIER_INDENT_COMMENTS;
      break;
   case 'indent_fl':
      name=VSCFGP_BEAUTIFIER_INDENT_FIRST_LEVEL;
      break;
   case 'indent_idempotent_block':
      name=VSCFGP_BEAUTIFIER_PP_INDENT_IN_HEADER_GUARD;
      break;
   case 'indent_pp_inside_braces':
      name=VSCFGP_BEAUTIFIER_PP_INDENT_IN_CODE_BLOCK;
      break;
   case 'indent_pp':
      name=VSCFGP_BEAUTIFIER_PP_INDENT;
      break;
   case 'indent_with_tabs':
      name=VSCFGP_BEAUTIFIER_INDENT_WITH_TABS;
      break;
   case 'last_scheme':
      name='';
      break;
   case 'pad_condition':
   case 'nopad_condition':
      name='';
      break;
   case 'nospace_before_brace':
      name=VSCFGP_BEAUTIFIER_SP_BEFORE_LBRACE;
      value=value?0:1;
      break;
   case 'nospace_before_paren':
      name=VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN;
      value=value?0:1;
      break;
   case 'orig_tabsize':
      name=VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE;
      break;
   case 'pad_condition_state':
      name=VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS;
      if (value==0) {
         value=1;
         apply=1;
      } else if (value==1) {
         value=0;
         apply=1;
      } else if (value==2) {
         apply=0;
         value=0;
      } else {
         value=0;
         apply=1;
      }
      break;
   case 'pad_condition_state':
      name='';
      break;
   case 'parens_on_return':
      name=VSCFGP_BEAUTIFIER_REQUIRE_PARENS_ON_RETURN;
      //name='add_parens_on_return';
      break;
   case 'statement_comment_col':
      name=VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL;
      if (value<=0) {
         return;
      }
      break;
   case 'statement_comment_state':
      name=VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE;
//static enum TrailingComment { TC_ABS_COL = 0, TC_ORIG_ABS_COL, TC_ORIG_REL_INDENT};
      break;
   case 'syntax_indent':
      break;
   case 'tabsize':
      name=VSCFGP_BEAUTIFIER_TAB_SIZE;
      break;
   case 'use_relative_indent':
      name='';
      break;
   }
   if (name=='') {
      return;
   }
   if (isinteger(apply)) {
      _beautifier_set_property(ibeautifier,name,value,apply?true:false);
   } else {
      _beautifier_set_property(ibeautifier,name,value);
   }
}

static void convert_old_beautifier_uformat_ini(_str filename) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   top();up();
   status=search('^\[:v-scheme-','@r');
   while (!status) {
      get_line(auto line);
      parse line with '[' auto langId '-scheme-' auto profileName']';
      if (langId!='e' && langId!='as' /* actionscript */ && langId!='ada') {
         status=repeat_search();
         continue;
      }
      ibeautifier:=_beautifier_create(langId);
      for (;;) {
         if (down()) {
            status=repeat_search();
            break;
         }
         get_line(line);
         if (isalpha(substr(line,1,1))) {
            parse line with auto name '=' auto value;
            if (langId=='e' || langId=='as' /* actionscript */) {
               xlat_c_property(ibeautifier,name,value,langId);
            } else if (langId=='ada') {
               xlat_ada_property(ibeautifier,name,value);
            }
         }
         if (substr(line,1,1)=='[') {
            up();_end_line();
            status=repeat_search();
            break; 
         }
      }
      _beautifier_save_profile(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
      _beautifier_destroy(ibeautifier);
   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;


}

defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   convert_old_beautifier_uformat_ini(filename);

}
