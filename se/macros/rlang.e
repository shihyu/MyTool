#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/AutoBracketMarker.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "tags.e"
#import "c.e"
#import "cutil.e"
#import "stdcmds.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cfcthelp.e"
#import "codehelputil.e"
#import "main.e"
#import "mprompt.e"
#import "stdprocs.e"
#import "env.e"
#endregion


/**
 * Set to the path to 'rscript' executable.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_rscript_exe_path;
/**
 * Activates R file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void r_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('r');
}
int _r_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "r";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"R") && !forceRebuild) {
      return(0);
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"R Libraries",
                           false, "",
                           ext_builtins_path(ext,"r"), withRefs, useThread);
}
int _r_delete_char(_str force_wrap='') {
   return _c_delete_char(force_wrap);
}
bool _r_find_surround_lines(int &first_line, int &last_line,
                               int &num_first_lines, int &num_last_lines,
                               bool &indent_change,
                               bool ignoreContinuedStatements=false) {
   return _c_find_surround_lines(first_line,last_line,num_first_lines,num_last_lines,indent_change,ignoreContinuedStatements);
}


int _r_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         bool find_parents,int max_matches,
                         bool exact_match, bool case_sensitive,
                         SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                         SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                         VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
      isay(depth, "_r_find_context_tags: ------------------------------------------------------");
      isay(depth, "_r_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case_sensitive="case_sensitive);
   }
   orig_num_matches := tag_get_num_of_matches();
   status := _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth+1,prefix_rt);

   // ignore namespace qualification if it wasn't valid
   if (endsWith(prefixexp, "::")) {
      if (status < 0 || tag_get_num_of_matches() <= orig_num_matches) {
         status = _c_find_context_tags(errorArgs,"",lastid,lastidstart_offset,
                                       info_flags,otherinfo,find_parents,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
      }
   }
   return status;
}


int _r_parse_return_type(_str (&errorArgs)[], typeless tag_files,
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

int _r_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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

/**
 * @see _c_get_type_of_expression
 */
int _r_get_type_of_expression(_str (&errorArgs)[], 
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

int _r_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                int tree_wid, int tree_index,
                                _str lastid_prefix="", 
                                bool exact_match=false, bool case_sensitive=true,
                                _str param_name="", _str param_default="",
                                struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_insert_constants_of_type(rt_expected,
                                      tree_wid,tree_index,
                                      lastid_prefix,
                                      exact_match,case_sensitive,
                                      param_name, param_default,
                                      visited, depth);
}

int _r_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                             struct VS_TAG_RETURN_TYPE &rt_candidate,
                             _str tag_name,_str type_name,
                             SETagFlags tag_flags,
                             _str file_name, int line_no,
                             _str prefixexp,typeless tag_files,
                             int tree_wid, int tree_index)
{
   return 0;
}

int _r_fcthelp_get_start(_str (&errorArgs)[],
                         bool OperatorTyped,
                         bool cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags,
                         int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _r_fcthelp_get(_str (&errorArgs)[],
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

_str _r_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   rv := '';

   switch (info.type_id) {
   case SE_TAG_TYPE_FUNCTION:
      rv :+= info.member_name'('info.arguments')';
      if (info.return_type != '' && info.return_type != 'Unit') {
         rv :+= ': 'info.return_type;
      }
      break;

   case SE_TAG_TYPE_GVAR:
   case SE_TAG_TYPE_LVAR:
   case SE_TAG_TYPE_VAR:
   case SE_TAG_TYPE_PARAMETER:
      if (info.return_type != '' && info.return_type != 'Unit') {
         rv = info.member_name': 'info.return_type;
      } else {
         rv = info.member_name;
      }
      break;

   case SE_TAG_TYPE_CLASS:
   case SE_TAG_TYPE_INTERFACE:
      if (info.type_id == SE_TAG_TYPE_CLASS) {
         if (info.flags & SE_TAG_FLAG_STATIC) {
            rv = 'object ';
         } else {
            rv = 'class ';
         }
      } else {
         rv = 'trait ';
      }
      if (info.qualified_name != '') {
         rv :+= translate(info.qualified_name, '.', '/')'.';
      }
      rv :+= info.member_name;
      break;

   default:
      rv = info.member_name:+': 'info.type_name;
   }
   return rv;
}
int _r_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   status:=_do_default_get_expression_info(PossibleOperator, info, visited, depth);
   return status;
}

static _str guessRScriptCompilerExePath()
{
/*
 HKEY_CLASSES_ROOT\RWorkspace\DefaultIcon
    <path>RGui.exe
 HKEY_CLASSES_ROOT\RWorkspace\shell\open\command

 HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RWorkspace\shell\open\command
    "<path>RGui.exe" "%1"
macros\vchack.e 1115 26:         frameworkVer = 


*/
   if( def_rscript_exe_path != "" ) {
      // No guessing necessary
      return def_rscript_exe_path;
   }
   _str command;
   _str filename;
   if (_isWindows()) {
      command=_ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Classes\\RWorkspace\\shell\\open\\command");
      filename=parse_file(command,false);
      if (filename!='') {
         return _strip_filename(filename,'N'):+'Rscript':+EXTENSION_EXE;
      }
      return '';
   }
   filename='/usr/bin/Rscript';
   if(file_exists(filename)) {
      return filename;
   }
   return '';
}
int _r_set_environment() {
   _str rscript_filename=_orig_path_search('Rscript');
   if (rscript_filename!="") {
       //if (!quiet) {
       //   _message_box('Rust is already setup.  rustc is already in your PATH.');
       //}
       _restore_origenv(true);
       return(0);
   }

   rscriptExePath := "";
   if( def_rscript_exe_path != "" ) {
      _restore_origenv(false);
      // Use def_rscript_exe_path
      rscriptExePath = def_rscript_exe_path;
   } else {
      _restore_origenv(true);

      for (;;) {
          // Prompt user for interpreter
          int status = _mdi.textBoxDialog("Rscript Executable",
                                          0,
                                          0,
                                          "",
                                          "OK,Cancel:_cancel\tSpecify the path and name to 'Rscript"EXTENSION_EXE"'",  // Button List
                                          "",
                                          "-bf Rscript Executable:":+guessRScriptCompilerExePath());
          if( status < 0 ) {
             // Probably COMMAND_CANCELLED_RC
             return status;
          }
          if (file_exists(_param1)) {
             break;
          }
          _message_box('Rscript executable not found. Please correct the path or cancel');
      }

      // Save the values entered and mark the configuration as modified
      def_rscript_exe_path = _param1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      rscriptExePath = def_rscript_exe_path;
   }

   // Make sure we got a path
   if( rscriptExePath == "" ) {
      return COMMAND_CANCELLED_RC;
   }

   // Set the environment
   //set_env('SLICKEDIT_rscript_EXE',rscriptExePath);
   rscriptDir := _strip_filename(rscriptExePath,'N');
   _maybe_strip_filesep(rscriptDir);
   // PATH
   _str path = _replace_envvars("%PATH%");
   _maybe_prepend(path,PATHSEP);
   path = rscriptDir:+path;
   set("PATH="path);

   // Success
   return 0;
}

/**
 * Prepares the environment for running python command-line 
 * interpreter. 
 *
 * @return 0 on success, <0 on error.
 */
_command int set_r_environment() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   int status = _r_set_environment();
   return status;
}
