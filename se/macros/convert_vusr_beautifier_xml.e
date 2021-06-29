#pragma option(pedantic,on)
#include "slick.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"

static void convert_tag_properties(int ibeautifier,bool isXml,int handle,int tag_node,_str tagname) {

   child:=_xmlcfg_get_first_child(handle,tag_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (child>=0) {
      _str name,value,apply;
      
      if (_xmlcfg_get_name(handle,child)=='P') {
         name=_xmlcfg_get_attribute(handle,child,'N');
         value=_xmlcfg_get_attribute(handle,child,'V');
         apply=_xmlcfg_get_attribute(handle,child,'E',null);
      } else if (_xmlcfg_get_name(handle,child)=='p') {
         name=_xmlcfg_get_attribute(handle,child,'n');
         value=_xmlcfg_get_attribute(handle,child,'v');
         apply=_xmlcfg_get_attribute(handle,child,'apply',null);
      } else {
         // Odd node here
         child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         continue;
      }
      orig_name:=name;
      switch (name) {
      case 'parent_tag':
         value=lowcase(value);
         if (value=='(unknown tag)') {
            value=BEAUT_DEFAULT_TAG_NAME;
         }
         break;
      case 'end_tag':
      case 'end_tag_required':
      case 'valid_child_tags':
      case 'content_style':
      case 'preserve_child_tags':
      case 'preserve_child_tags_indent':
      case 'preserve_text_indent':
      case 'wrap_remove_blank_lines':
      case 'wrap_never_join_lines':
      case 'wrap_respace':
         //typexlat=TYPEXLAT_NONE;
         break;
      case 'indent_style':
         name='indent_tags';
         if (strieq(value,'IndentToStartTagLT')) {
            value=0;
         } else {
            value=1;
         }
         break;
      case 'new_lines_before_start_tag':
         name='bl_before_start_tag';
         break;
      case 'new_lines_before_start_tag_is_min':
         name='ismin_before_start_tag';
         break;
      case 'new_lines_after_end_tag':
         name='bl_after_end_tag';
         break;
      case 'new_lines_after_end_tag_is_min':
         name='ismin_after_end_tag';
         break;
      case 'new_line_after_start_tag':
         name='bl_after_start_tag';
         break;
      case 'new_line_after_start_tag_is_min':
         name='ismin_after_start_tag';
         break;
      case 'new_line_before_end_tag':
         name='bl_before_end_tag';
         break;
      case 'new_line_before_end_tag_is_min':
         name='ismin_before_end_tag';
         break;
      case 'preserve_start_tag_trailing_indent':
      case 'preserve_start_tag_indent':
      case 'preserve_end_tag_trailing_indent':
      case 'preserve_end_tag_indent':
      case 'preserve_end_tag_indent_for_column1':
      case 'tag_attr_style':
      case 'close_attr_list_on_separate_line':
         break;
      case 'space_after_last_attr':
         name='sp_after_last_attr';
         break;
      case 'escape_new_lines_in_attr_value':
         break;
      case 'space_around_attr_equals':
         name='sppad_attr_eq';
         break;
      case 'tmp_preserve_body':
      case 'tmp_reformat_content':
      case 'tmp_literal_content':
         name='';
         break;
      default:
         name='';
      }
      if (name!=orig_name) {
         _beautifier_delete_tag_property(ibeautifier,tagname,orig_name);
      }
      if (name!='') {
         if (isinteger(apply)) {
            _beautifier_set_tag_property(ibeautifier,tagname,name,value,apply==0?false:true);
         } else {
            _beautifier_set_tag_property(ibeautifier,tagname,name,value);
         }
      }
      child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
}
static void convert_tags(int ibeautifier,_str langId,int handle,int tag_node) {

   isXml:=_LanguageInheritsFrom('xml',langId);
   tag_node=_xmlcfg_get_first_child(handle,tag_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (tag_node>=0) {
      tag_name:=_xmlcfg_get_attribute(handle,tag_node,'n');
      if (!isXml) {
         tag_name=lowcase(tag_name);
      }
      if (tag_name=='(unknown tag)') {
         tag_name=BEAUT_DEFAULT_TAG_NAME;
      }
      // Define the tag
      _beautifier_set_tag_property(ibeautifier,tag_name,'','');

      convert_tag_properties(ibeautifier,isXml,handle,tag_node,tag_name);
      tag_node=_xmlcfg_get_next_sibling(handle,tag_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
}
static _str beautifier_get_old_property(int handle,int profileNode,_str name,_str &apply,_str defaultValue=''){
   node:=_xmlcfg_find_simple(handle,"P[@N=" "'"name"']",profileNode);
   if (node>=0) {
      value:=_xmlcfg_get_attribute(handle,node,'V');
      apply=_xmlcfg_get_attribute(handle,node,'E');
      return value;
   }
   node=_xmlcfg_find_simple(handle,"p[@N=" "'"name"']",profileNode);
   if (node>=0) {
      value:=_xmlcfg_get_attribute(handle,node,'v');
      apply=_xmlcfg_get_attribute(handle,node,'apply');
      return value;
   }
   apply=null;
   return defaultValue;
}

static bool _beautifier_property_uses_apply_attribute(_str name) {
   temp_name:=name;
   if (substr(name,1,5)=='objc_') {
      temp_name=substr(name,6);
   }
   if (substr(temp_name,1,3)=='sp_' 
       || substr(temp_name,1,6)=='sppad_'
       || substr(temp_name,1,8)=='spstyle_'
       || substr(temp_name,1,8)=='oneline_'
       || substr(temp_name,1,8)=='justify_'
       || substr(temp_name,1,3)=='nl_'
       || substr(temp_name,1,6)=='nlpad_'
       || substr(temp_name,1,3)=='bl_'
       || substr(temp_name,1,3)=='ra_'
       || substr(temp_name,1,4)=='rai_'
       || substr(name,1,3)=='jd_'
       || substr(name,1,4)=='dox_'
       || substr(name,1,5)=='xdoc_'
       || temp_name=='original_tab_size'
       || temp_name=='indent_if_of_else_if'
       || temp_name=='max_line_len'
       ) {
      return true;
   }
   /*if (
       substr(name,1,9)=='pp_'
       || substr(name,1,9)=='braceloc_') {
      // This could change in the future.
      return false;
   } */
   return false;
}

static const TYPEXLAT_NOTSET=  -1;
static const TYPEXLAT_NONE=  0;
static const TYPEXLAT_YN=    1;
static const TYPEXLAT_SPSTYLE=  2;
static const TYPEXLAT_LISTALIGN= 3;
static const TYPEXLAT_BRACELOC= 4;
static const TYPEXLAT_TRAILING_COMMENT_STYLE= 5;
static const TYPEXLAT_BOOL= 6;
static const TYPEXLAT_RAI=  7;
static const TYPEXLAT_JUSTIFY=  8;
static const TYPEXLAT_WORDCASE= 9;
static const TYPEXLAT_QUOTESTYLE= 10;

static void xlat_property(_str langId,int handle,int profileNode,_str &name,_str &value,_str &apply) {

   orig_name:=name;
   _str value2,apply2;
   int typexlat=TYPEXLAT_NOTSET;
   switch (name) {
   case 'sp_ctlstmt_rparen':
   case 'sp_ctlstmt_padparen':
   case 'sp_switch_defcolon':
   case 'sp_switch_colon':
   case 'sp_ctlstmt_lparen':
   case 'sp_pp_eatspace':
   case 'parens_return':
   case 'parens_throw':
   case 'fundecl_void':
   case 'sp_ctlstmt_lbrace':
      name='';
      break;
   case 'respace_other':
      typexlat=TYPEXLAT_NONE;
      // Removed from these languages
      if (langId!='py' && langId!='vbs' && langId!='basic') {
         name='';
      }
      break;
   case 'pp_pin_hash':
   case 'indent_pp_col1':
   case 'pp_old_style_indent':
      name='pp_keep_pound_in_col1';
      break;
   case 'indent_preprocessing':
   case 'pp_indent':
      name='pp_indent';
      break;
   case 'pp_indent_block':
   case 'indent_in_block':
      name='pp_indent_in_code_block';
      break;
   case 'pp_indent_header_guard':
   case 'indent_guard':
      name='pp_indent_in_header_guard';
      break;
   case 'pp_code_indent':
   case 'pp_indent_with_code':
      name='pp_indent_with_code';
      break;

   case 'syntax_indent':
      name='syntax_indent';typexlat=TYPEXLAT_NONE;
      break;
   case 'tab_indent':
      name='tab_size';typexlat=TYPEXLAT_NONE;
      break;
   case 'indent_policy':
   case 'indent_with_tabs':
      name='indent_with_tabs';
      break;
   case 'indent_member_access':
      name='indent_member_access';
      break;
   case 'access_spec_indent':
      name='indent_width_member_access';
      break;
   case 'member_access_relative_indent':
      name='indent_member_access_relative';
      break;
   case 'indent_case':
      name='indent_case';
      break;
   case 'case_indent_width':
      name='indent_width_case';
      break;
   case 'continuation_width':
      name='indent_width_continuation';
      break;
   case 'funcall_param_align':
      name='listalign_fun_call_params';
      break;
   case 'st_nl_file':
      //name='nl_required_at_eof';
      name='require_new_line_at_eof';
      break;
   case 'original_tab':
      name='original_tab_size';typexlat=TYPEXLAT_NONE;
      apply=false;
      value2=beautifier_get_old_property(handle,profileNode,'indent_use_tab',apply2);
      if (value2!='' && value2==0) {
         apply=true;
      }
      break;
   case 'indent_use_tab':
      name='';
      break;
   case 'rm_trailing_ws':
      name='rm_trailing_spaces';
      break;
   case 'rm_dup_ws':
      name='rm_dup_spaces';
      break;
   case 'max_line_len':
      name='max_line_len';typexlat=TYPEXLAT_NONE;
      break;


   case 'st_nl_empty':
      name='nl_empty_block';
      break;
   case 'sp_catch_padparen':
      name='sppad_catch_parens';        // catch_pad_parens
      break;
   case 'sp_switch_lparen':
      name='sp_switch_before_lparen';  // switch_space_befroe_lparen
      break;
   case 'sp_arrayexpr_lbracket':
      name='sp_array_expr_before_lbracket';   // array_expr_space_before_lbracket
      break;
   case 'sp_arraydecl_lbracket':
      name='sp_array_decl_before_lbracket';   // array_decl_space_before_lbracket
      break;
   case 'st_fundecl_nameline':
      name='';
      break;
   case 'st_oneline_dowhile':
      name='oneline_dowhile';
      break;
   case 'sp_op_bitwise':
      name='spstyle_op_bitwise';
      break;
   case 'st_oneline_catch':
      name='oneline_catch';
      break;
   case 'sp_for_lparen':
      name='sp_for_before_lparen';
      break;
   case 'sp_funcall_voidparen':
      name='sp_fun_call_empty_parens';
      break;
   case 'sp_switch_padparen':
      name='sppad_switch_parens';
      break;
   case 'sp_fun_padparen':
      name='sppad_fun_parens';
      break;
   case 'sp_if_rparen':
      name='sp_if_after_rparen';
      break;
   case 'sp_op_bitand':
      name='';
      break;
   case 'sp_op_assignment':
      name='spstyle_op_assignment';
      break;
   case 'sp_for_comma':
      name='spstyle_for_comma';
      break;
   case 'sp_funcall_comma':
      name='spstyle_fun_call_comma';
      break;
   case 'sp_arrayexpr_rbracket':
      name='sp_array_expr_after_rbracket';
      break;
   case 'sp_op_mult':
      name='spstyle_op_mult';
      break;
   case 'sp_arraydecl_rbracket':
      name='sp_array_decl_after_rbracket';
      break;
   case 'sp_for_lbrace':
      name='spstyle_for_lbrace';
      break;
   case 'st_oneline_then':
      name='oneline_unblocked_then';
      break;
   case 'sp_catch_lparen':
      name='sp_catch_before_lparen';
      break;
   case 'sp_member_dot':
      name='spstyle_member_dot';
      break;
   case 'sp_for_rparen':
      name='sp_for_after_rparen';
      break;
   case 'sp_while_rparen':
      name='sp_while_after_rparen';
      break;
   case 'sp_ret_parexpr':
      name='sp_return_before_lparen';
      break;
   case 'sp_throw_parexpr':
      name='sp_throw_before_lparen';
      break;
   case 'st_oneline_statement':
      name='oneline_unblocked_statement';
      break;
   case 'st_oneline_elsif':
      name='oneline_elseif';
      break;
   case 'sp_op_unary':
      name='spstyle_op_unary';
      break;
   case 'sp_op_binary':
      name='spstyle_op_binary';
      break;
   case 'sp_op_comparison':
      name='spstyle_op_comparison';
      break;
   case 'sp_catch_rparen':
      name='sp_catch_after_rparen';
      break;
   case 'sp_fun_lparen':
      name='sp_fun_before_lparen';
      break;
   case 'sp_fun_voidparen':
      name='sp_fun_empty_parens';
      break;
   case 'sp_while_lbrace':
      name='spstyle_while_lbrace';
      break;
   case 'sp_switch_lbrace':
      name='spstyle_switch_lbrace';
      break;
   case 'sp_op_logical':
      name='spstyle_op_logical';
      break;
   case 'sp_for_semicolon':
      name='spstyle_for_semicolon';
      break;
   case 'st_nl_fn':
      name='nl_empty_fun_body';
      break;
   case 'sp_funcall_rparen':
      name='sp_fun_call_after_rparen';
      break;
   case 'sp_funcall_lparen':
      name='sp_fun_call_before_lparen';
      break;
   case 'sp_fun_comma':
      name='spstyle_fun_comma';
      break;
   case 'st_leave_declmult':
      name='leave_multiple_decl';
      break;
   case 'sp_catch_lbrace':
      name='spstyle_catch_lbrace';
      break;
   case 'sp_fun_lbrace':
      name='spstyle_fun_lbrace';
      break;
   case 'sp_if_lbrace':
      name='spstyle_if_lbrace';
      break;
   case 'sp_for_padparen':
      name='sppad_for_parens';
      break;
   case 'sp_switch_rparen':
      name='sp_switch_after_rparen';
      break;
   case 'sp_op_prefix':
      name='spstyle_op_prefix';
      break;
   case 'sp_funcall_padparen':
      name='sppad_fun_call_parens';
      break;
   case 'sp_while_padparen':
      name='sppad_while_parens';
      break;
   case 'sp_while_lparen':
      name='sp_while_before_lparen';
      break;
   case 'sp_fun_rparen':
      name='sp_fun_after_rparen';
      break;
   case 'st_leave_stmtmult':
      name='leave_multiple_stmt';
      break;
   case 'sp_arrayexpr_padbracket':
      name='sppad_array_expr_brackets';
      break;
   case 'sp_arraydecl_padbracket':
      name='sppad_array_decl_brackets';
      break;
   case 'st_oneline_else':
      name='oneline_unblocked_else';
      break;
   case 'st_nl_case':
      name='nl_after_case';
      break;
   case 'sp_op_postfix':
      name='spstyle_op_postfix';
      break;
   case 'sp_if_lparen':
      name='sp_if_before_lparen';
      break;
   case 'sp_if_padparen':
      name='sppad_if_parens';
      break;
   case 'indent_first_level':
      name='indent_first_level';
      break;
   case 'indent_goto':
      name='indent_label';
      break;
   case 'align_on_equals':
      name='align_on_assignment_op';
      break;
   case 'exp_paren_align':
      name='listalign2_expr_parens';
      break;
   case 'brace_loc_if':
      name='braceloc_if';
      break;
   case 'brace_loc_for':
      name='braceloc_for';
      break;
   case 'brace_loc_while':
      name='braceloc_while';
      break;
   case 'brace_loc_switch':
      name='braceloc_switch';
      break;
   case 'brace_loc_do':
      name='braceloc_do';
      break;
   case 'brace_loc_try':
      name='braceloc_try';
      break;
   case 'brace_loc_catch':
      name='braceloc_catch';
      break;
   case 'brace_loc_fun':
      name='braceloc_fun';
      break;
   case 'comment_indent':
      name='indent_comments';
      break;
   case 'comment_col1_indent':
      name='indent_col1_comments';
      break;
   case 'allow_one_line_block':
      name='leave_one_line_code_blocks';
      break;
   case 'st_newline_before_else':
      name='nl_before_else';
      break;
   case 'trailing_comment_align':
      name='trailing_comment_style';
      break;
   case 'trailing_comment_value':
      name='trailing_comment_col';typexlat=TYPEXLAT_NONE;
      break;
   case 'indent_from_brace':
      name='indent_from_brace';
      break;
   case 'label_indent':
      name='indent_width_label';
      break;
   case 'sp_return_padparen':
      name='sppad_return_parens';
      break;
   case 'sp_return_rparen':
      name='sp_return_after_rparen';
      break;
   case 'sp_throw_padparen':
      name='sppad_throw_parens';
      break;
   case 'sp_throw_rparen':
      name='sp_throw_after_rparen';
      break;
   case 'sp_expr_lparen':
      name='sp_expr_before_lparen';
      break;
   case 'sp_expr_padparen':
      name='sppad_expr_parens';
      break;
   case 'sp_expr_rparen':
      name='sp_expr_after_rparen';
      break;
   case 'sp_stmt_semicolon':
      name='sp_stmt_after_semicolon';
      break;
   case 'sp_try_lbrace':
      name='spstyle_try_lbrace';
      break;
   case 'brace_follows_case':
      name='align_lbrace_with_case';
      break;
   case 'nl_indent_lone_else':
      name='indent_if_of_else_if';
      break;
   case 'rw_force_throw_parens':
      name='ra_throw_parens';
      break;
   case 'rw_force_return_parens':
      name='rai_return_parens';
      break;
   case 'force_param_void':
      name='ra_fun_void_in_empty_param_list';
      break;
   case 'sp_cast_lparen':
      name='sp_cast_before_lparen';
      break;
   case 'sp_cast_padparen':
      name='sppad_cast_parens';
      break;
   case 'sp_cast_rparen':
      name='sp_cast_after_rparen';
      break;
   case 'blank_before_case':
      name='bl_before_case';
      break;
   case 'blank_before_first_case':
      name='bl_after_start_block_switch';
      break;
   case 'bl_start_block_if':
      name='bl_after_start_block_if';
      break;
   case 'bl_end_block_if':
      name='bl_after_end_block_if';
      break;
   case 'bl_start_block_for':
      name='bl_after_start_block_for';
      break;
   case 'bl_end_block_for':
      name='bl_after_end_block_for';
      break;
   case 'bl_start_block_while':
      name='bl_after_start_block_while';
      break;
   case 'bl_end_block_while':
      name='bl_after_end_block_while';
      break;
   case 'bl_start_block_do':
      name='bl_after_start_block_do';
      break;
   case 'bl_end_block_do':
      name='bl_after_end_block_do';
      break;
   case 'bl_end_block_switch':
      name='bl_after_end_block_switch';
      break;
   case 'bl_start_block_try':
      name='bl_after_start_block_try';
      break;
   case 'bl_start_block_catch':
      name='bl_after_start_block_catch';
      break;
   case 'bl_end_block_catch':
      name='bl_after_end_block_catch';
      break;
   case 'bl_start_block_method':
      name='bl_after_start_block_fun';
      break;
   case 'bl_before_locals':
      name='bl_before_locals';
      break;
   case 'bl_after_locals':
      name='bl_after_locals';
      break;
   case 'varalign_justification':
      name='justify_var_decls';
      break;
   case 'braceloc_multiline_cond':
      // Need to use apply here
      name='braceloc_multiline_cond';
      break;
   case 'sp_stmt_before_semi':
      name='sp_stmt_before_semicolon';
      break;
   case 'sp_enum_lbrace':
      name='spstyle_enum_lbrace';
      break;
   case 'sp_enum_comma':
      name='spstyle_enum_const_comma';
      break;
   case 'sp_fun_colon':
      name='spstyle_fun_colon';
      break;
   case 'st_nl_class':
      name='nl_empty_class_body';
      break;
   case 'allow_class_one_line_block':
      name='leave_class_one_line_block';
      break;
   case 'sp_class_lbrace':
      name='spstyle_class_lbrace';
      break;
   case 'sp_class_comma':
      name='spstyle_class_comma';
      break;
   case 'sp_class_colon':
      name='spstyle_class_colon';
      break;
   case 'brace_loc_class':
      name='braceloc_class';
      break;
   case 'indent_class_body':
      name='indent_class_body';
      break;
   case 'bl_before_first_decl':
      name='bl_before_first_decl';
      break;
   case 'bl_between_methods':
      name='bl_between_funs';
      break;
   case 'bl_between_fields':
      name='bl_between_member_var_decls';
      break;
   case 'bl_between_commented_fields':
      name='bl_between_commented_member_var_decls';
      break;
   case 'bl_between_member_classes':
      name='bl_between_member_classes';
      break;
   case 'bl_between_different_decls':
      name='bl_between_different_decls';
      break;
   case 'bl_between_classes':
      name='bl_between_classes';
      break;
   case 'bl_between_fn_prototypes':
      name='bl_between_fun_prototypes';
      break;
   case 'instvaralign_justification':
      name='justify_member_var_decls';
      break;
   case 'sp_tmpldecl_lt':
      name='sp_tmpl_decl_before_lt';
      break;
   case 'sp_tmpldecl_pad':
      name='sppad_tmpl_decl_angle_brackets';
      break;
   case 'sp_tmpldecl_comma':
      name='spstyle_tmpl_decl_comma';
      break;
   case 'sp_tmpldecl_equals':
      name='spstyle_tmpl_decl_eq';
      break;
   case 'sp_tmplparm_lt':
      name='sp_tmpl_parm_before_lt';
      break;
   case 'sp_tmplparm_pad':
      name='sppad_tmpl_parm_angle_brackets';
      break;
   case 'sp_tmplparm_comma':
      name='spstyle_tmplparm_comma';
      break;
   case 'jd_format_html':
      // ??? NO GUI WAY TO SET THIS??? Default is yes 
      name='jd_format_html';
      break;
   case 'jd_format_pre':
      name='jd_format_pre';
      break;
   case 'jd_indent_param_desc':
      name='jd_indent_param_desc';
      break;
   case 'jd_indent_past_param_name':
      name='jd_indent_past_param_name';
      break;
   case 'jd_force_delim_nl':
      // The code uses this as a count but the config and GUI seems to think it's a bool.
      // Default value in xml config is bad so convert to 0,1
      name='jd_nl_at_start_and_end';
      break;
   case 'jd_blank_lines_before_tags':
      name='jd_bl_before_tags';
      break;
   case 'jd_rm_blank_lines':
      name='jd_rm_blank_lines';
      break;
   case 'jd_between_diff_tags':
      name='jd_bl_between_different_tags';
      break;
   case 'jd_between_same_tags':
      name='jd_bl_between_same_tags';
      break;
   case 'dox_format_pre':
      name='dox_format_pre';
      break;
   case 'dox_indent_param_desc':
      name='dox_indent_param_desc';
      break;
   case 'dox_indent_past_param_name':
      name='dox_indent_past_param_name';
      break;
   case 'dox_force_delim_nl':
      // The code uses this as a count but the config and GUI seems to think it's a bool.
      // Default value in xml config is bad so convert to 0,1
      name='dox_nl_at_start_and_end';
      break;
   case 'dox_after_brief':
      name='dox_bl_after_brief';
      break;
   case 'dox_rm_blank_lines':
      name='dox_rm_blank_lines';
      break;
   case 'dox_between_diff_tags':
      name='dox_bl_between_different_tags';
      break;
   case 'dox_between_same_tags':
      name='dox_bl_between_same_tags';
      break;
   case 'xdoc_format_pre':
      name='xdoc_format_pre';
      break;
   case 'xdoc_between_diff_tags':
      name='xdoc_bl_between_different_tags';
      break;
   case 'xdoc_between_same_tags':
      name='xdoc_bl_between_same_tags';
      break;
   case 'xdoc_rm_blank_lines':
      name='xdoc_rm_blank_lines';
      break;
   case 'xdoc_nl_after_opentag':
      name='xdoc_nl_after_open_tag';
      break;
   case 'xdoc_nl_before_closetag':
      name='xdoc_nl_before_close_tag';
      break;


   // C++ **********************************************************
   case 'sp_init_comma':
      name='spstyle_init_comma';
      break;
   case 'sp_member_dotstar':
      name='spstyle_op_dotstar';
      break;
   case 'sp_mptr_ccs':
      name='sp_mptr_between_coloncolon_and_star';
      break;
   case 'sp_delete_padbracket':
      name='sppad_array_del_brackets';
      break;
   case 'sp_cppcast_pad':
      name='sppad_cppcast_angle_brackets';
      break;
   case 'sp_ref_arp':
      name='sp_ref_between_amp_and_rparen';
      break;
   case 'sp_member_arrowstar':
      name='spstyle_op_dashgtstar';
      break;
   case 'st_newline_after_extern':
      name='nl_after_extern';
      break;
   case 'sp_struct_comma':
      name='spstyle_struct_comma';
      break;
   case 'sp_ptr_is':
      name='sp_ptr_between_type_and_star';
      break;
   case 'sp_fun_equals':
      name='spstyle_fun_eq';
      break;
   case 'sp_delete_rbracket':
      name='sp_array_del_rbracket';
      break;
   case 'sp_ref_av':
      name='sp_ref_between_amp_and_id';
      break;
   case 'sp_new_lparen':
      name='sp_new_before_lparen';
      break;
   case 'sp_struct_colon':
      name='spstyle_struct_colon';
      break;
   case 'sp_ptr_srp':
      //NOT AVAILABLE IN GUI
      name='sp_ptr_between_star_and_rparen';
      break;
   case 'sp_funcall_operator':
      name='sp_fun_call_after_operator';
      break;
   case 'st_oneline_access':
      //name='nl_required_after_member_access';
      name='require_new_line_after_member_access';
      break;
   case 'sp_cppcast_gt':
      name='sp_cppcast_after_gt';
      break;
   case 'sp_fun_commainit':
      name='spstyle_constr_init_list_comma';
      break;
   case 'sp_init_lbrace':
      // Array/struct
      name='spstyle_init_list_comma';
      break;
   case 'sp_fun_operator':
      name='sp_fun_after_operator';
      break;
   case 'sp_ptr_ss':
      name='sp_ptr_between_star_and_star';
      break;
   case 'sp_tmplcall_pad':
      //???NOT USED ANYWHERE?? CPPB_SP_TMPLCALL_PAD
      name='';
      break;
   case 'sp_ptr_sv':
      name='sp_ptr_between_star_and_id';
      break;
   case 'sp_union_lbrace':
      name='spstyle_union_before_lbrace';
      break;
   case 'sp_new_rparen':
      name='sp_new_after_rparen';
      break;
   case 'sp_new_padparen':
      name='sppad_new_parens';
      break;
   case 'sp_enum_equals':
      name='spstyle_enum_const_eq';
      break;
   case 'sp_cppcast_lt':
      name='sp_cppcast_before_lt';
      break;
   case 'sp_enum_colon':
      name='spstyle_enum_colon';
      break;
   case 'sp_ptr_slp':
      name='sp_ptr_between_star_and_lparen';
      break;
   case 'sp_ptr_sa':
      name='sp_ptr_between_star_and_amp';
      break;
   case 'sp_ref_ia':
      name='sp_ref_between_type_and_amp';
      break;
   case 'sp_tmplcall_comma':
      /*??? not by beautifier but it's in xml config?? CPPB_SP_TMPLCALL_COMMA */
      name='';
      break;
   case 'sp_tmplcall_lt':
      /*??? not by beautifier but it's in xml config?? CPPB_SP_TMPLCALL_LT */
      name='';
      break;
   case 'sp_ptr_si':
      name='sp_ptr_between_star_and_qualifier';
      break;
   case 'sp_delete_lbracket':
      name='sp_array_del_before_lbracket';
      break;
   case 'sp_op_dereference':
      name='spstyle_op_dereference';
      break;
   case 'sp_struct_lbrace':
      name='spstyle_struct_lbrace';
      break;
   case 'sp_member_arrow':
      name='spstyle_op_dashgt';
      break;
   case 'sp_fptr_si':
      name='sp_fptr_between_star_and_id';
      break;
   case 'sp_ref_alp':
      name='sp_ref_between_amp_and_lparen';
      break;
   case 'sp_init_rbrace':
      name='spstyle_init_rbrace';
      break;
   case 'sp_op_addressof':
      name='spstyle_op_addressof';
      break;
   case 'indent_tab_custom':
      /* REMOVE??? not by beautifier but it's in xml config?? CPPB_INDENT_TAB_CUSTOM */
      name='';
      break;
   case 'indent_extern':
      name='indent_extern_body';
      break;
   case 'indent_namespace':
      name='indent_namespace_body';
      break;
   case 'indent_funcall_lambda':
      name='indent_funcall_lambda';
      break;
   case 'orig_indent':
      // remove??? CPPB_ORIG_INDENT not used any where
      name='';
      break;
   case 'brace_loc_asm':
      name='braceloc_asm';
      break;
   case 'brace_loc_namespace':
      name='braceloc_namespace';
      break;
   case 'brace_loc_enum':
      name='braceloc_enum';
      break;
   case 'fun_assoc_with_ret_type':
      name='sp_ptr_return_type_between_type_and_star';
      break;
   case 'cppb_sp_fptr_padparen':
      name='sppad_fptr_parens';
      break;
   case 'cppb_sp_fptr_lparen':
      name='sp_fptr_before_lparen';
      break;
   case 'cppb_sp_fptr_rparen':
      name='sp_fptr_after_rparen';
      break;
   case 'cont_indent_returntype':
      //  NOT IN GUI but in xml config and beautifier supports this.
      name='indent_on_return_type_continuation';
      break;
   case 'sp_ty_star_prototype':
      name='sp_ptr_cast_proto_between_type_and_star';
      break;
   case 'sp_ty_amp_prototype':
      name='sp_ref_cast_proto_between_type_and_amp';
      break;
   case 'sp_disassoc_ret_type_ref':
      name='sp_ref_return_type_between_type_and_amp';
      break;
   case 'sp_namespace_lbrace':
      name='spstyle_namespace_lbrace';
      break;
   case 'bl_before_access':
      name='bl_before_member_access';
      break;
   case 'bl_after_access':
      name='bl_after_member_access';
      break;
   case 'brace_loc_struct':
      name='braceloc_struct';
      break;
   case 'brace_loc_union':
      name='braceloc_union';
      break;
   case 'sp_pad_lambdabrace':
      name='sppad_lambda_braces';
      break;
   case 'sp_lambdacapture_lbracket':
      name='sp_lambda_before_lbracket';
      break;
   case 'sp_lambdacapture_rbracket':
      name='sp_lambda_after_rbracket';
      break;
   case 'sp_lambdacapture_pad':
      name='sppad_lambda_brackets';
      break;
   case 'rm_returntype_nls':
      name='rm_return_type_new_lines';
      break;


   // Object-C ************************************************************
   case 'meth_decl_align':
      name='objc_align_meth_decl_on_colon';
      break;
   case 'meth_call_align':
      name='objc_align_meth_call_on_colon';
      break;
   case 'category_padparen':
      name='objc_sppad_category_parens';
      break;
   case 'category_lparen':
      name='objc_sp_category_before_lparen';
      break;
   case 'category_rparen':
      name='objc_sp_category_before_rparen';
      break;
   case 'sp_decl_selector_colon':
      name='objc_spstyle_decl_selector_colon';
      break;
   case 'sp_call_selector_colon':
      name='objc_spstyle_call_selector_colon';
      break;
   case 'protocol_padparen':
      name='objc_sppad_protocol_parens';
      break;
   case 'protocol_lparen':
      name='objc_sp_protocol_before_lparen';
      break;
   case 'protocol_rparen':
      name='objc_sp_protocol_before_rparen';
      break;
   case 'protocol_comma':
      name='objc_spstyle_protocol_comma';
      break;
   case 'meth_call_bracket_align':
      name='objc_listalign2_meth_call_brackets';
      break;
   case 'meth_call_selalign_force':
      name='objc_align_meth_call_selectors_right';
      break;
   case 'prop_padparen':
      name='objc_sppad_property_parens';
      break;
   case 'prop_lparen':
      name='objc_sp_property_before_lparen';
      break;
   case 'prop_rparen':
      name='objc_sp_property_after_rparen';
      break;
   case 'prop_comma':
      name='objc_spstyle_property_comma';
      break;
   case 'synth_comma':
      name='objc_spstyle_synthesize_comma';
      break;
   case 'synth_eq':
      name='objc_spstyle_synthesize_eq';
      break;
   case 'dynamic_comma':
      name='objc_spstyle_dynamic_comma';
      break;
/*
    meth_return_padparen
    meth_return_rparen
    meth_return_padparen
    meth_return_rparen
*/
   case 'meth_return_lparen':
      name='objc_sp_meth_return_type_before_lparen';
      break;
   case 'meth_return_padparen':
      name='objc_sppad_meth_return_type_parens';
      break;
   case 'meth_return_rparen':
      name='objc_sp_meth_return_type_after_rparen';
      break;
   case 'meth_param_lparen':
      name='objc_sp_meth_param_before_lparen';
      break;
   case 'meth_param_padparen':
      name='objc_sppad_meth_param_parens';
      break;
   case 'meth_param_rparen':
      name='objc_sp_meth_param_after_rparen';
      break;
   case 'block_initial_indent':
      // ???Anonymous function or lambda
      name='objc_indent_width_lambda_body';
      break;
   case 'finally_lbrace':
      name='objc_spstyle_finally_lbrace';
      break;
   case 'synchronized_lparen':
      name='objc_sp_synchronized_before_lparen';
      break;
   case 'synchronized_padparen':
      name='objc_sppad_synchronized_parens';
      break;
   case 'synchronized_rparen':
      name='objc_sp_synchronized_after_rparen';
      break;
   case 'synchronized_lbrace':
      name='objc_spstyle_synchronized_lbrace';
      break;
   case 'prop_eq':
      name='objc_spstyle_property_eq';
      break;

   // java ************************************************************
   case 'sp_foreach_colon':
      name='spstyle_foreach_colon';
      break;
   case 'annot_newline':
      name='nl_after_type_annot';
      break;
   case 'sp_annot_lparen':
      name='sp_annot_before_lparen';
      break;
   case 'sp_annot_padparen':
      name='sp_pad_annot_parens';
      break;
   case 'sp_annot_rparen':
      name='sp_annot_after_rparen';
      break;
   case 'sp_annot_comma':
      name='spstyle_annot_comma';
      break;
   case 'annot_newline_package':
      name='nl_after_package_annot';
      break;
   case 'annot_newline_field':
      name='nl_after_var_annot';
      break;
   case 'annot_newline_method':
      name='nl_after_meth_annot';
      break;
   case 'annot_newline_parameter':
      name='nl_after_param_annot';
      break;
   case 'annot_newline_local':
      name='nl_after_local_var_decl_annot';
      break;
   case 'annot_type_brace_loc':
      name='braceloc_type_annot';
      break;
   case 'sp_annot_type_brace':
      name='spstyle_type_annot_lbrace';
      break;
   case 'sp_enum_constbody_lbrace':
      name='spstyle_enum_const_body_lbrace';
      break;
   case 'enum_braceloc':
      name='braceloc_enum';
      break;
   case 'enum_constbody_braceloc':
      name='braceloc_enum_const_body';
      break;
   case 'sp_enum_init_lparen':
      name='sp_enum_const_before_lparen';
      break;
   case 'sp_enum_init_rparen':
      name='sp_enum_const_after_rparen';
      break;
   case 'sp_enum_init_padding':
      name='sppad_enum_const_parens';
      break;
   case 'sp_enum_eq':
      // ???replace usage of sp_enum_eq with C++ spstyle_enum_eq
      name='spstyle_enum_const_eq';
      break;
   case 'anon_class_braceloc':
      name='braceloc_anon_class';
      break;
   case 'sp_anon_class_lbrace':
      // Not available in GUI
      name='spstyle_anon_class_lbrace';
      break;
   case 'ind_enum_body':
      name='indent_enum_body';
      break;
   case 'ind_enum_const_body':
      name='indent_enum_const_body';
      break;
   case 'ind_break_stmt':
      //??? REMOVE not used anywhere JAVA_IND_BREAK_STMT
      name='';
      break;
   case 'ind_annot_type_body':
      name='indent_annot_type_body';
      break;
   case 'sp_arr_init_comma':
      name='spstyle_array_init_comma';
      break;
   case 'sp_arr_init_pad':
      name='sppad_array_init_braces';
      break;
   case 'nl_array_init_inner_pad':
      name='nlpad_array_init_inner_braces';
      break;
   case 'nl_array_init_outer_pad':
      name='nlpad_array_init_outer_braces';
      break;
   case 'nl_array_init_before_outer_lbrace':
      name='nl_array_init_before_outer_lbrace';
      break;
   case 'nl_array_init_before_inner_lbrace':
      name='nl_array_init_before_inner_lbrace';
      break;
   case 'bl_before_package':
      name='bl_before_package';
      break;
   case 'bl_after_package':
      name='bl_after_package';
      break;
   case 'bl_leave_between_imports':
      name='bl_between_different_imports';
      break;
   case 'bl_after_imports':
      name='bl_after_imports';
      break;
   case 'sp_before_try_lparen':
      name='sp_try_before_lparen';
      break;
   case 'sp_after_try_rparen':
      name='sp_try_after_rparen';
      break;
   case 'sp_padparen_try':
      name='sppad_try_parens';
      break;
   case 'bl_before_sync':
      name='bl_after_start_block_synchronized';
      break;
   case 'bl_after_sync':
      name='bl_after_end_block_synchronized';
      break;
   case 'sp_sync_lparen':
      name='sp_synchronized_before_lparen';
      break;
   case 'sp_sync_pad':
      name='sppad_synchronized_parens';
      break;
   case 'sp_sync_rparen':
      name='sp_synchronized_after_rparen';
      break;
   case 'sp_exception_choice':
      name='spstyle_exception_vbar';
      break;
   case 'sp_exception_choice':
      name='spstyle_catch_vbar';
      break;



   // C# ************************************************************
   case 'nl_before_where':
      name='nl_before_where';
      break;
   case 'nl_after_comma':
      name='nl_after_where_comma';
      break;
   case 'sp_where_comma':
      name='spstyle_where_comma';
      break;
   case 'sp_where_colon':
      name='spstyle_where_colon';
      break;
   case 'braceloc_namespace':
      // ???Already have one of these for C++
      name='braceloc_namespace';
      break;
   case 'braceloc_using':
      name='braceloc_using';
      break;
   case 'sp_using_lparen':
      name='sp_using_before_lparen';
      break;
   case 'sp_using_padparen':
      name='sppad_using_parens';
      break;
   case 'sp_using_rparen':
      name='sp_using_after_rparen';
      break;
   case 'sp_using_comma':
      name='spstyle_using_comma';
      break;
   case 'braceloc_property':
      name='braceloc_property';
      break;
   case 'braceloc_outer_property':
      name='braceloc_outer_property';
      break;
   case 'sp_lock_lparen':
      name='sp_lock_before_lparen';
      break;
   case 'sp_lock_rparen':
      name='sp_lock_after_rparen';
      break;
   case 'sp_lock_padparen':
      name='sppad_lock_parens';
      break;
   case 'braceloc_lock':
      name='braceloc_lock';
      break;
   case 'bl_start_block_lock':
      name='bl_after_start_block_lock';
      break;
   case 'bl_end_block_lock':
      name='bl_after_end_block_lock';
      break;
   case 'bl_start_block_using':
      name='bl_after_start_block_using';
      break;
   case 'bl_end_block_using':
      name='bl_after_end_block_using';
      break;
   case 'braceloc_anonmeth':
      // ???Map to Java property
      name='braceloc_anon_class';
      break;
   case 'braceloc_enum':
      // ???Map to C++ property
      name='braceloc_enum';
      break;

   // Javascript ************************************************************
   case 'indent_fn_relative_to_keyword':
      name='indent_fun_relative_to_keyword';
      break;
   case 'sp_dict_colon':
      name='spstyle_dictionary_colon';
      break;

   // VBScript ************************************************************
   case 'keyword_case':
      /* REMOVE. Not used. VBScript and VB support a change_keywords_to_mixed_case, not this but change_keyword_case would be better */
      name='';
      break;

   // SystemVerilog ************************************************************
   case 'brace_style_fork':
      name='';
      break;
   case 'align_vars':
      name='';
      break;
   case 'varname_justification':
      // ?? var_decl_name 
      name='justify_var_decl_name';
      apply=false;
      value2=beautifier_get_old_property(handle,profileNode,'align_vars',apply2);
      if (value2!='' && value2) {
         apply=true;
      }
      break;
   case 'force_nl_after_var_commas':
      // ?? var_decl 
      //name='nl_required_after_var_decl_comma';
      name='require_new_line_after_var_decl_comma';
      break;
   case 'align_assignments':
   case 'align_module_instantiations':
   case 'align_module_parameters':
      break;

    // HTML/XML ************************************************************
   case 'indent':
      name='syntax_indent';typexlat=TYPEXLAT_NONE;
      break;
   case 'tab_size':
      name='tab_size';typexlat=TYPEXLAT_NONE;
      break;
   case 'original_tab_size':
      name='original_tab_size';typexlat=TYPEXLAT_NONE;
      break;
   case 'indent_with_tabs':
      name='indent_with_tabs';
      break;
   case 'indent_col1_comments':
      name='indent_col1_comments';
      break;
   case 'indent_standalone_comments':
      name='indent_comments';
      break;
   case 'indent_code_from_tag':
      //???
      name='indent_code_from_tag';typexlat=TYPEXLAT_BOOL;
      break;
   case 'mod_tag_indent':
      //???
      name='mod_tag_indent';typexlat=TYPEXLAT_BOOL;
      break;
   case 'ml_closing_tag':
      //???
      name='ml_closing_tag';typexlat=TYPEXLAT_BOOL;
      break;
   case 'ml_closing_block':
      //???
      name='ml_closing_block';typexlat=TYPEXLAT_BOOL;
      break;
   case 'default_embedded_lang':
      //???
      name='default_embedded_lang';typexlat=TYPEXLAT_NONE;
      break;
   case 'maximum_line_length':
      //???
      name='max_line_len';typexlat=TYPEXLAT_NONE;
      break;
   case 'tag_case_style':
      //???
      name='wc_tag_name';
      break;
   case 'attr_case_style':
      //???
      name='wc_attr_name';
      break;
   case 'attr_value_case_style':
      //???
      name='wc_attr_word_value';
      break;
   case 'attr_value_hex_case_style':
      //???
      name='wc_attr_hex_value';
      break;
   case 'quote_all_values':
      name='quote_all_values';typexlat=TYPEXLAT_BOOL;
      break;
   case 'wrap_remove_blank_lines':
      name='wrap_remove_blank_lines';typexlat=TYPEXLAT_BOOL;
      break;
   case 'wrap_never_join_lines':
      name='wrap_never_join_lines';typexlat=TYPEXLAT_BOOL;
      break;
   case 'wrap_respace':
      name='wrap_respace';typexlat=TYPEXLAT_BOOL;
      break;

   case 'tag_attr_style':
      name='tag_attr_style';typexlat=TYPEXLAT_NONE; // tagattrstyle
      break;
   case 'quote_word_value':
      name=VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE;
      break;
   case 'quote_number_value':
      name=VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE;
      break;
   case 'close_attr_list_on_separate_line':
      name='close_attr_list_on_separate_line';typexlat=TYPEXLAT_BOOL;
      break;
   case 'space_after_last_attr':
      name='sp_after_last_attr';
      break;
   case 'escape_new_lines_in_attr_value':
      name='escape_new_lines_in_attr_value';typexlat=TYPEXLAT_BOOL;
      break;
   case 'space_around_attr_equals':
      name='sppad_attr_eq';
      break;
   // VB/VBScript ************************************************************
   case 'indent':
      name=VSCFGP_BEAUTIFIER_SYNTAX_INDENT;typexlat=TYPEXLAT_NONE;
      break;
   case 'tab_size':
      name=VSCFGP_BEAUTIFIER_TAB_SIZE;
      break;
   case 'original_tab_size':
      name=VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE;
      break;
   case 'indent_with_tabs':
      name=VSCFGP_BEAUTIFIER_INDENT_WITH_TABS;
      break;
   case 'indent_case_from_select':
      name=VSCFGP_BEAUTIFIER_INDENT_CASE;
      break;
   case 'label_indent_style':
      name=VSCFGP_BEAUTIFIER_LABEL_INDENT_STYLE;typexlat=TYPEXLAT_NONE;
      break;
   case 'new_line_after_label':
      name='nl_after_label';
      break;
   case 'leave_statements_on_same_line':
      name=VSCFGP_BEAUTIFIER_LEAVE_MULTIPLE_STMT;
      break;
   case 'align_on_parens':
      name=VSCFGP_BEAUTIFIER_LISTALIGN2_PARENS;
      break;
   case 'align_on_equal':
      name=VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP;
      break;
   case 'ppindent':
      name=VSCFGP_BEAUTIFIER_PP_INDENT;
      break;
   case 'ppindent_inside_block':
      name=VSCFGP_BEAUTIFIER_PP_INDENT_IN_CODE_BLOCK;
      break;
   case 'ppremove_spaces_after_pound':
      name=VSCFGP_BEAUTIFIER_PP_RM_SPACES_AFTER_POUND;
      break;
   case 'change_keywords_to_mixed_case':
      apply=(value)?true:false;
      value=2;
      name=VSCFGP_BEAUTIFIER_WC_KEYWORD;typexlat=TYPEXLAT_NONE;
      break;
   case 'normalize_ends':
      name='normalize_ends';typexlat=TYPEXLAT_NONE;
      break;
   case 'remove_unnecessary_dim_keyword':
      name='rm_unnecessary_dim_keyword';
      break;
   case 'add_thens':
      name='add_thens';typexlat=TYPEXLAT_NONE;
      break;
   case 'convert_variant_to_object':
      name='convert_variant_to_object';typexlat=TYPEXLAT_NONE;
      break;
   case 'assignment_operator_spacing_style':
      name=VSCFGP_BEAUTIFIER_SPSTYLE_OP_ASSIGNMENT;
      break;
   case 'pad_binary_operators':
      name='sppad_op_binary';
      break;
   case 'space_before_initializer_open_brace':
      name='sp_initializer_before_lbrace';
      break;
   case 'space_after_word_followed_by_open_brace':
      name='sp_between_word_and_lbrace';
      break;
   case 'remove_spaces_before_comma':
      name='rm_spaces_before_comma';
      break;
   case 'space_after_comma':
      name='sp_after_comma';
      break;
   case 'strip_trailing_spaces':
      name='rm_trailing_spaces';
      break;
   case 'unary_operator_spacing_style':
      name='spstyle_op_unary';
      break;
   case 'space_before_lambda_open_paren':
      name='sp_lambda_before_lparen';
      break;
   case 'pad_parens':
      name='sppad_parens';
      break;
   case 'pad_empty_parens':
      name='sppad_empty_parens';
      break;
   case 'colon_spacing_style':
      name='spstyle_colon';
      break;
   case 'respace_other':
      typexlat=TYPEXLAT_NONE;
      break;
   case 'max_line_len':
      name='max_line_len';typexlat=TYPEXLAT_NONE;
      break;
   case 'indent_leading_comments':
      name='indent_comments';
      break;
   case 'indent_column1_comments':
      name='indent_col1_comments';
      break;
   case 'trailing_comment_style':
      name='trailing_comment_style';
      break;
   case 'trailing_comment_column':
      name='trailing_comment_col';typexlat=TYPEXLAT_NONE;
      break;
   // Python ************************************************************
   case 'indent':
      name='syntax_indent';typexlat=TYPEXLAT_NONE;
      break;
   case 'tab_size':
   case 'original_tab_size':
   case 'indent_with_tabs':
   case 'label_indent_style':
      typexlat=TYPEXLAT_NONE;
      break;
   case 'new_line_after_label':
      name='nl_after_label';
      break;
   case 'leave_statements_on_same_line':
      name='leave_multiple_stmt';
      break;
   case 'function_call_indent_style':
      name='listalign_fun_call_params';
      break;
   case 'paren_indent_style':
      name='listalign_parens';
      break;
   case 'brace_indent_style':
      name='listalign_braces';
      break;
   case 'bracket_indent_style':
      name='listalign_brackets';
      break;
   case 'align_on_equal':
   case 'align_on_assignment_operator':
      name='align_on_assignment_op';
      break;
   case 'assignment_operator_spacing_style':
      name='spstyle_op_assignment';
      break;
   case 'pad_binary_operators':
      name='sppad_op_binary';
      break;
   case 'space_after_literal_comma':
      name='sp_literal_after_comma';
      break;
   case 'space_after_function_comma':
      name='sp_fun_after_comma';
      break;
   case 'remove_spaces_before_comma':
      name='rm_spaces_before_comma';
      break;
   case 'remove_spaces_before_colon':
      name='rm_spaces_before_colon';
      break;
   case 'strip_trailing_spaces':
      name='rm_trailing_spaces';
      break;
   case 'unary_operator_spacing_style':
      name='spstyle_op_unary';
      break;
   case 'pad_parens':
      name='sppad_parens';
      break;
   case 'pad_empty_parens':
      name='sppad_empty_parens';
      break;
   case 'pad_braces':
      name='sppad_braces';
      break;
   case 'pad_empty_braces':
      name='sppad_empty_braces';
      break;
   case 'pad_brackets':
      name='sppad_brackets';
      break;
   case 'space_before_expression_open_paren':
      name='sp_expr_before_lparen';
      break;
   case 'space_before_expression_open_brace':
      name='sp_expr_before_lbrace';
      break;
   case 'space_before_expression_open_bracket':
      name='sp_expr_before_lbracket';
      break;
   case 'pad_empty_brackets':
      name='sppad_empty_brackets';
      break;
   case 'respace_other':
      name='respace_other';
      break;
   case 'semicolon_spacing_style':
      name='spstyle_semicolon';
      break;
   case 'max_line_len':
      name='max_line_len';typexlat=TYPEXLAT_NONE;
      break;
   case 'trailing_comment_style':
      break;
   case 'trailing_comment_column':
      name='trailing_comment_col';typexlat=TYPEXLAT_NONE;
      break;
   case 'space_before_fundecl_open_paren':
      name='sp_fun_decl_before_lparen';
      break;
   case 'space_before_funcall_open_paren':
      name='sp_fun_call_before_lparen';
      break;
   case 'blank_lines_func_func':
      name='bl_between_fun_and_fun';
      break;
   case 'blank_lines_class_func':
      name='bl_between_class_and_fun';
      break;
   case 'blank_lines_class_class':
      name='bl_between_class_and_class';
      break;
   }
   if (name=='') {
      return;
   }
   if (!_beautifier_property_uses_apply_attribute(name)) {
      apply=null;
   }
   if (typexlat==TYPEXLAT_NOTSET) {
      temp_name:=name;
      if (substr(name,1,5)=='objc_') {
         temp_name=substr(name,6);
      } else if (substr(name,1,3)=='jd_') {
         temp_name=substr(name,4);
      } else if (substr(name,1,4)=='dox_') {
         temp_name=substr(name,5);
      } else if (substr(name,1,5)=='xdoc_') {
         temp_name=substr(name,6);
      }
      if (temp_name=='trailing_comment_style') {
         typexlat=TYPEXLAT_TRAILING_COMMENT_STYLE;
      } else if (
          substr(temp_name,1,3)=='nl_'
          || substr(temp_name,1,8)=='require_'
          || substr(temp_name,1,6)=='nlpad_'
          || substr(temp_name,1,3)=='rm_'
          || substr(temp_name,1,3)=='sp_' 
          || substr(temp_name,1,6)=='sppad_'   // These are actuall 0,1 but this will work
          || substr(temp_name,1,3)=='pp_'   // These are actuall 0,1 but this will work
          || substr(temp_name,1,6)=='leave_'
          || substr(temp_name,1,6)=='align_'
          || substr(temp_name,1,8)=='oneline_'
          || substr(temp_name,1,7)=='format_'
          ) {
         typexlat=TYPEXLAT_YN;
      } else if (
          substr(temp_name,1,3)=='wc_'
          ) {
         typexlat=TYPEXLAT_WORDCASE;
      } else if (
          substr(temp_name,1,3)=='ra_'
          || substr(temp_name,1,4)=='rai_' 
          ) {
         typexlat=TYPEXLAT_RAI;
      } else if (
                 substr(temp_name,1,8)=='spstyle_'
                 ) {
         typexlat=TYPEXLAT_SPSTYLE;
      } else if (
                 substr(temp_name,1,9)=='braceloc_'
                 ) {
         typexlat=TYPEXLAT_BRACELOC;
      } else if (
                 substr(temp_name,1,8)=='justify_'
                 ) {
         typexlat=TYPEXLAT_JUSTIFY;
      } else if (        
                 substr(temp_name,1,13)=='indent_width_'
                 || substr(temp_name,1,3)=='bl_'
                  || substr(temp_name,1,4)=='max_'
                 ) {
         typexlat=TYPEXLAT_NONE;
      } else if (
                 substr(temp_name,1,7)=='indent_'
                 ) {
         typexlat=TYPEXLAT_YN;
      } else if (
                 substr(temp_name,1,11)=='listalign2_'
                 || substr(temp_name,1,10)=='listalign_'
                 ) {
         typexlat=TYPEXLAT_LISTALIGN;
      } else if (
                 substr(temp_name,1,6)=='quote_'
                 ) {
         typexlat=TYPEXLAT_QUOTESTYLE;
      }
   }
   if (typexlat==TYPEXLAT_NOTSET) {
      say('typexlat not set for 'name' typexlat='typexlat);
      return;
   }
   if (typexlat==TYPEXLAT_NONE) {
      return;
   }
   if (typexlat==TYPEXLAT_YN) {
//const COMBO_IN_TABS = 11;
//const COMBO_IN_SPACES = 12;
      value=(value==5 || value==0 || value==12)?0:1;
      return;
   }
   if (typexlat==TYPEXLAT_SPSTYLE) {
      /*
       No spaces = 0;
       Space Before = 1;
       Space After = 2;
       Space Before and After = 3;
      */
      if (strieq(value,'None')) {
         value=0;
         return;
      }
      if (strieq(value,'Before')) {
         value=1;
         return;
      }
      if (strieq(value,'After')) {
         value=2;
         return;
      }
      if (strieq(value,'BeforeAndAfter')) {
         value=3;
         return;
      }
      return;
   }
   if (typexlat==TYPEXLAT_LISTALIGN) {
      if (value==8 || strieq(value,'AlignOnParens')) {
         value=FPAS_ALIGN_ON_PARENS;
         return;
      }
      if (value==9 || strieq(value,'UseContinuationIndent')) {
         value=FPAS_CONTINUATION_INDENT;
         return;
      }
      if (value==10 || strieq(value,'ChooseFromSource')) {
         value= FPAS_AUTO;
         return;
      }
      value= FPAS_ALIGN_ON_PARENS;
      return;
   }
   if (typexlat==TYPEXLAT_BRACELOC) {
      if (value==15) {
         value=0;  // same line
         return;
      }
      if (value==13) {
         value= 1;  // next line
         return;
      }
      if (value==14) {
         value=2;  // next line indented
         return;
      }
      if (value==24 /* BL_MULTILINE_NO */ && name=='braceloc_multiline_cond') {
         value=10;
         return;
      }
      value=0;
      return;
   }
   if (typexlat==TYPEXLAT_TRAILING_COMMENT_STYLE) {
      /*
       "UseColumn" absolute column = 0;   use column   trailing_comment_col
       "Absolute" original absolute column = 1;
       "Relative" original relative indent = 2;
      */
      if (strieq(value,"UseColumn")) {
         value=0;
         return;
      }
      if (strieq(value,"Absolute")) {
         value=1;
         return;
      }
      if (strieq(value,"Relative")) {
         value=2;
         return;
      }
      return;
   }
   if (typexlat==TYPEXLAT_BOOL) {
      return;
   }
   if (typexlat==TYPEXLAT_RAI) {
      /*
const COMBO_FORCE_PARENS=21;
const COMBO_FORCE_PARENS_IF_COMPLEX=22;
const COMBO_REMOVE_PARENS=23;
      */
      if (value==23 || value==5 /* COMBO_N for force_param_void */) {
         value=0;
         return;
      }
      if (value==21 || value==4 /* COMBO_Y for force_param_void */) {
         value=1;
         return;
      }
      if (value==22) {
         value=2;
         return;
      }
      return;
   }
   if (typexlat==TYPEXLAT_JUSTIFY) {
      return;
   }
   if (typexlat==TYPEXLAT_WORDCASE) {
      if (strieq(value,'lower')) {
         value=WORDCASE_LOWER;apply=true;
         return;
      }
      if (strieq(value,'upper')) {
         value=WORDCASE_UPPER;apply=true;
         return;
      }
      if (strieq(value,'capitalize')) {
         value=WORDCASE_CAPITALIZE;apply=true;
         return;
      }
      if (strieq(value,'preserve')) {
         value=WORDCASE_LOWER;apply=false;
         return;
      }
      value=WORDCASE_LOWER;apply=false;
      return;
   }
   if (typexlat==TYPEXLAT_QUOTESTYLE) {
      if (strieq(value,'yes')) {
         value=1;apply=true;
         return;
      }
      if (strieq(value,'no')) {
         value=0;apply=true;
         return;
      }
      value=1;apply=false;
      return;
   }
}

static void _convert_lang_beautifier_profile_to_xmlcfg(int handle,int profileNode,_str match_langId,_str match_profileName) {
   langId:=_xmlcfg_get_attribute(handle,profileNode,"lang");
   if (langId=='') {
      // We are lost?
      return;
   }
   profileName:=_xmlcfg_get_attribute(handle,profileNode,"name");
   if (match_langId!='' && match_langId!=langId) {
      return;
   }
   if (match_profileName!='' && match_profileName!=profileName) {
      return;
   }
   ibeautifier:=_beautifier_create(langId);
   if (ibeautifier<0) {
      // We are lost?
      return;
   }
   status:=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),'Default');
   if (status) {
      // Unsupported language or system config is bad
      _beautifier_destroy(ibeautifier);
      return;
   }
   hit_braceloc_struct := false;
   hit_braceloc_union := false;
   child:=_xmlcfg_get_first_child(handle,profileNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (child>=0) {
      _str name,value,apply;
      
      if (_xmlcfg_get_name(handle,child)=='P') {
         name=_xmlcfg_get_attribute(handle,child,'N');
         value=_xmlcfg_get_attribute(handle,child,'V');
         apply=_xmlcfg_get_attribute(handle,child,'E');
      } else if (_xmlcfg_get_name(handle,child)=='p') {
         name=_xmlcfg_get_attribute(handle,child,'n');
         if (name=='tags') {
            /*
           <p n="tags">
               <tag n="OBJECT">
                   <p n="parent_tag" v="(INLINE)"/>
               </tag>
            */
            convert_tags(ibeautifier,langId,handle,child);
            child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
            continue;
         }
         value=_xmlcfg_get_attribute(handle,child,'v');
         apply=_xmlcfg_get_attribute(handle,child,'apply');
      } else {
         // Odd node here
         child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         continue;
      }
      orig_name:=name;
      xlat_property(langId,handle,profileNode,name,value,apply);
      // Since the defaults have been loaded into this beautifier
      // We can do this. 
      if (!_beautifier_has_property(ibeautifier,name)) {
         name='';
      }
      if (orig_name!=name) {
         _beautifier_delete_property(ibeautifier,orig_name,false);
      }
      if (name!='') {
         if (name=='braceloc_struct') hit_braceloc_struct=true;
         if (name=='braceloc_union') hit_braceloc_union=true;
         if (isinteger(apply)) {
            _beautifier_set_property(ibeautifier,name,value,apply?true:false);
         } else {
            _beautifier_set_property(ibeautifier,name,value);
         }
      }
      child=_xmlcfg_get_next_sibling(handle,child,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
   value:=_beautifier_get_property(ibeautifier,'braceloc_class');
   if (value!='') {
      if (!hit_braceloc_struct) {
         if(_beautifier_get_property(ibeautifier,'braceloc_struct')!='') {
            _beautifier_set_property(ibeautifier,'braceloc_struct',value);
         }
      }
      if (!hit_braceloc_union) {
         if(_beautifier_get_property(ibeautifier,'braceloc_union')!='') {
            _beautifier_set_property(ibeautifier,'braceloc_union',value);
         }
      }
   }
   _beautifier_save_profile(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(langId),profileName);
   _beautifier_destroy(ibeautifier);
}
static void _convert_lang_beautifier_profiles_to_xmlcfg(_str filename,_str langId,_str profileName) {
   handle:=_xmlcfg_open(arg(1),auto status);
   if (handle<0) {
      return;
   }
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/*/profile",array);
   for (i:=0;i<array._length();++i) {
      _convert_lang_beautifier_profile_to_xmlcfg(handle,array[i],langId,profileName);
   }
   _xmlcfg_close(handle);
}
   
defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   langId:=parse_file(args,false);
   profileName:=strip(args);
   if (filename=='') {
      filename=p_buf_name;
   }
   _convert_lang_beautifier_profiles_to_xmlcfg(filename,langId,profileName);
}
