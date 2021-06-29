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
#include "project.sh"
#import "adaptiveformatting.e"
#import "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "c.e"
#import "cfcthelp.e"
#import "cjava.e"
#import "csymbols.e"
#import "cutil.e"
#import "diffprog.e"
#import "env.e"
#import "groovy.e"
#import "hotspots.e"
#import "java.e"
#import "javacompilergui.e"
#import "main.e"
#import "notifications.e"
#import "optionsxml.e"
#import "picture.e"
#import "pmatch.e"
#import "projconv.e"
#import "refactor.e"
#import "slickc.e"
#import "smartp.e"
#import "sbt.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "vc.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;

static const PROTOCOLBUF_LANG_ID=    'protocolbuf';

_command void protocolbuf_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PROTOCOLBUF_LANG_ID);
}
bool _protocolbuf_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _protocolbuf_supports_insert_begin_end_immediately() {
   return true;
}
static SYNTAX_EXPANSION_INFO protocolbuf_space_words:[] = {
   'double'    => { "double" },
   'float'     => { "float" },
   'int32'     => { "int32" },
   'int64'     => { "int64" },
   'uint32'    => { "uint32" },
   'uint64'    => { "uint64" },
   'sint32'    => { "sint32" },
   'sint64'    => { "sint64" },
   'fixed32'   => { "fixed32" },
   'fixed64'   => { "fixed64" },
   'sfixed32'  => { "sfixed32" },
   'sfixed64'  => { "sfixed64" },
   'bool'      => { "bool" },
   'string'    => { "string" },
   'bytes'     => { "bytes" },
   'enum'      => { "enum" },
   'extend'    => { "extend" },
   'extensions'=> { "extensions" },
   'import'    => { "import" },
   'message'   => { "message" },
   'oneof'    => { "oneof" },
   'option'    => { "option" },
   'optional'  => { "optional" },
   'package'   => { "package" },
   'repeated'  => { "repeated" },
   'rpc'  => { "rpc" },
   //'singular'  => { "singular" },
   'syntax'    => { "syntax" },
};
static _str _protocolbuf_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);
   typeless status = 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line, 'T');
   orig_word := strip(line);
   if (p_col != text_col(_rawText(line)) + 1) {
      return(1);
   }

   width := -1;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word, protocolbuf_space_words, '', aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return(expandResult != 0);
   }
   if (word == '') {
      /*if (orig_word == 'case') {
         // Auto-indent line to the correct indent for our settings.
         enc := enclosing_stmt_start_col();
         if (enc > 0) {
            indent := enc + beaut_case_indent() - 1;
            replace_line(indent_string(indent):+'case');
         }
         end_line();
      } */
      return(1);
   }
   typeless block_info = "";
   line = substr(line, 1, length(line) - length(orig_word)):+word;
   if (width < 0) {
      width = text_col(_rawText(line), _rawLength(line) - _rawLength(word) + 1, 'i') - 1;
   }
   orig_word = word;
   word = lowcase(word);
   doNotify := true;
   clear_hotspots();
   /*if (word == 'if' || word == 'while' || word == 'for') {
      replace_line(line:+' ()');
      _end_line(); add_hotspot();
      p_col = p_col - 1; add_hotspot();
   } else */if (word) {
      replace_line(line:+' '); _end_line(); 
      doNotify = false;


   } else {
      status = 1;
      doNotify = false;
   }
   show_hotspots();
   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }
   return(status);
}
_command void protocolbuf_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _protocolbuf_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}


int _protocolbuf_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                   _str lastid,int lastidstart_offset,
                                   int info_flags,typeless otherinfo,
                                   bool find_parents,int max_matches,
                                   bool exact_match, bool case_sensitive,
                                   SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                   SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                   VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}
int _protocolbuf_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                            _str symbol, _str search_class_name,
                            _str file_name, _str return_type, bool isjava,
                            struct VS_TAG_RETURN_TYPE &rt,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_parse_return_type(errorArgs,tag_files,
                               symbol,search_class_name,
                               file_name,return_type,
                               true,rt,visited,depth);
}
int _protocolbuf_get_type_of_expression(_str (&errorArgs)[], 
                                        typeless tag_files,
                                        _str symbol, 
                                        _str search_class_name,
                                        _str file_name,
                                        CodeHelpExpressionPrefixFlags prefix_flags,
                                        _str expr, 
                                        struct VS_TAG_RETURN_TYPE &rt,
                                        struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}

int _protocolbuf_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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

int _protocolbuf_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                          int tree_wid, int tree_index,
                                          _str lastid_prefix="", 
                                          bool exact_match=false, bool case_sensitive=true,
                                          _str param_name="", _str param_default="",
                                          struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_insert_constants_of_type(rt_expected,
                                         tree_wid,tree_index,
                                         lastid_prefix,
                                         exact_match,case_sensitive,
                                         param_name, param_default,
                                         visited, depth);
}

int _protocolbuf_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                   struct VS_TAG_RETURN_TYPE &rt_candidate,
                                   _str tag_name,_str type_name,
                                   SETagFlags tag_flags,
                                   _str file_name, int line_no,
                                   _str prefixexp,typeless tag_files,
                                   int tree_wid, int tree_index,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);
}

int _protocolbuf_fcthelp_get_start(_str (&errorArgs)[],
                                   bool OperatorTyped,
                                   bool cursorInsideArgumentList,
                                   int &FunctionNameOffset,
                                   int &ArgumentStartOffset,
                                   int &flags,
                                   int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _protocolbuf_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_fcthelp_get(errorArgs,
                             FunctionHelp_list,FunctionHelp_list_changed,
                             FunctionHelp_cursor_x,
                             FunctionHelp_HelpWord,
                             FunctionNameStartOffset,
                             flags, symbol_info,
                             visited, depth);
   return(status);
}

_str _protocolbuf_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
int _protocolbuf_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
/**
 * Build a tag file for Python.  Looks in the
 * registry on Windows to find the installation
 * path for the CygWin distribution of the Python
 * interpreter.  Failing that does a path search
 * for the python interpreter executable (python.exe),
 * and tags any .py files under the "lib" directory,
 * excluding the "test" directory.
 *
 * @param tfindex Set to the index of the extension specific
 *                tag file for Python.
 * @return 0 on success, nonzero on error
 */
int _protocolbuf_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "protocolbuf";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"protocol_buffers") && !forceRebuild) {
      return(0);
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"Protocol Buffers Libraries",
                           false, "",
                           ext_builtins_path(ext,"protocol_buffers"), withRefs, useThread);
}
