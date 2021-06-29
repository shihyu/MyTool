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
#import "se/lang/api/ExtensionSettings.e"
#import "autobracket.e"
#import "smartp.e"
#import "tags.e"
#import "c.e"
#import "caddmem.e"
#import "cbrowser.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "cjava.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

using se.lang.api.ExtensionSettings;

defeventtab actionscript_keys;
def  ' '= actionscript_space;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  ':'= c_colon;
def  '='= auto_codehelp_key;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  '*'= c_asterisk;
def  '/'= c_slash;
def  'ENTER'= actionscript_enter;
def  'TAB'= smarttab;


_command void actionscript_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage("as");
}

int as_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _as_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (ext_MaybeRecycleTagFile(tfindex, auto tagfilename, "as", "actionscript") && !forceRebuild) {
      return(0);
   }
   version := _flash_get_version_number();
   return ext_MaybeBuildTagFile(tfindex, "as", "actionscript", 
                                "ActionScript Global Classpath",
                                _flash_get_global_classpath(version), true,
                                withRefs, useThread, forceRebuild);
}


/**
 * @see _c_generate_function
 */
int _as_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                 _str (&header_list)[],_str function_body,
                                 int indent_col, int begin_col,
                                 bool make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}

/**
 * @see _c_get_expression_pos
 */
int _as_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
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
int _as_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * @see _java_find_context_tags
 */
int _as_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          bool find_parents,int max_matches,
                          bool exact_match,bool case_sensitive,
                          SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                          SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_as_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   tag_return_type_init(prefix_rt);
   errorArgs._makeempty();
   errorArgs[1] = lastid;
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // watch out for unwelcome 'new' as prefix expression
   if (strip(prefixexp)=='new') {
      prefixexp='';
   }

   constructor_class := "";
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   word_chars := _clex_identifier_chars();
   if (prefixexp != '') {
      package_name := substr(prefixexp,1,length(prefixexp)-1);
      if (pos("^[."word_chars"]@$", prefixexp, 1, 'r') &&
          (filter_flags & SE_TAG_FILTER_PACKAGE) &&
          //_MatchSymbolAsPackage(prefixexp:+lastid, true, true)) {
          tag_check_for_package(package_name, tag_files, true, case_sensitive, null, visited, depth+1)) {
         rt.return_type='';
         //lastid = prefixexp:+lastid;
         tag_clear_matches();
         tag_list_context_packages(0,0,prefixexp:+lastid,tag_files,num_matches,max_matches,true,true,visited,depth+1);
         if (num_matches > 0) {
            return 0;
         }
      } else {
         int status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1);
         if (status) {
            return status;
         }
         // handle 'new' expressions as a special case
         if (pos('new ',prefixexp' ')==1 && (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
            outer_class := substr(prefixexp, 5);
            _maybe_strip(outer_class, '::');
            _maybe_strip(outer_class, '.');
            outer_class = stranslate(outer_class, ':', '::');
            if (outer_class=='') {
               tag_qualify_symbol_name(constructor_class,lastid,'',p_buf_name,tag_files,true, visited, depth+1);
            } else {
               constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true, false, false, visited, depth+1);
            }
         }

         context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
         tag_list_in_class(lastid, rt.return_type,
                           0, 0, tag_files,
                           num_matches, max_matches,
                           filter_flags, context_flags,
                           exact_match, case_sensitive, 
                           null, null, visited, depth+1);
      }

   } else {
      // get list of actionscript only tag files
      file_name := "";
      _str as_tag_files[];
      for (i:=0; i<tag_files._length(); i++) {
         status := tag_read_db(tag_files[i]);
         if (status >= 0) {
            dummy_lang := '';
            if (tag_find_language(dummy_lang, 'as') < 0 && 
                tag_find_language(dummy_lang, 'tagdoc') < 0) {
               tag_reset_find_language();
               continue;
            }
            tag_reset_find_language();
            as_tag_files[as_tag_files._length()] = tag_files[i];
         }
      }
      if (lastid != "") {
         tag_list_context_globals(0, 0, lastid,
                                  true, as_tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
         } else {
         tag_list_globals_of_type(0, 0, as_tag_files,
                                  SE_TAG_TYPE_CLASS, 0, 0,
                                  num_matches, max_matches,
                                  visited, depth+1);
      }     
   }

   // this instance is not a function, so mask it out of filter flags
   //SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING;
   //if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
   //   filter_flags &= ~(SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE|SE_TAG_FILTER_SUBPROCEDURE);
   //}

   // get the current class and current package from the context
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_class_name, auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);

   // determine access levels allowed by this context
   if ((pos(cur_package_name'/',rt.return_type)==1) ||
       (pos(cur_package_name'/',constructor_class)==1) ||
       (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
        !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
      context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
      context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
   }

   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==SE_TAG_TYPE_FUNCTION && cur_class_name!='' && prefixexp=='') {
      if (cur_tag_flags & SE_TAG_FLAG_STATIC) {
         context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
      }
   }

   // try to match the symbol in the current context
   tag_clear_matches();
   context_list_flags := SE_TAG_CONTEXT_FIND_ALL;
   if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
      context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
   }
   tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, '',
                               num_matches, max_matches,
                               filter_flags, context_flags | context_list_flags,
                               exact_match, case_sensitive, visited, depth+1);

   if (constructor_class!='') {
      tag_list_in_class(lastid, constructor_class, 0, 0,
                        tag_files, num_matches, max_matches,
                        filter_flags, context_flags|SE_TAG_CONTEXT_ONLY_CONSTRUCTORS|SE_TAG_CONTEXT_ONLY_THIS_CLASS,
                        exact_match, case_sensitive, null, null, visited, depth+1);
   }

   // Check if this is a prefix of a package name, return 0
   if (num_matches==0 && pos("^[."word_chars"]@$", prefixexp, 1, 'r') &&
       tag_check_for_package(prefixexp:+lastid, tag_files, false, case_sensitive, null, visited, depth+1)) {
      return 0;
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   //say("_as_find_context_tags: num_matches="num_matches);
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * @see _c_analyze_return_type
 */
int _as_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tag_files      array of tag files
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at 
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 * @param param_name     (unused)named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _as_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
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

/**
 * @see _c_match_return_type
 */
int _as_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
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

/**
 * @see _c_fcthelp_get_start
 */
int _as_fcthelp_get_start(_str (&errorArgs)[],
                          bool OperatorTyped,
                          bool cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags,
                          int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

/**
 * @see _c_fcthelp_get
 */
int _as_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

/**
 * @see _c_get_decl
 */
_str _as_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}

int _as_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words);
}

_command void actionscript_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_space();
}

_command void actionscript_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}
bool _as_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _as_supports_insert_begin_end_immediately() {
   return true;
}

_command void actionscript_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_begin();
}

_command void actionscript_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_endbrace();
}

_command void actionscript_colon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   c_colon();
}

/*
#Breakpoints xml file
Hard Disk\Documents and Settings\user\Local Settings\Application Data\Macromedia\Flash 8\language\Configuration\Debugger\
Macintosh HD/Users/User/Library/Application Support/Macromedia Flash 8/Configuration/Debugger/

AsBreakpoints.xml------------------------------------------
<?xml version="1.0"?>
<flash_breakpoints version="1.0">
    <file name="c:\project\file1.as">
        <breakpoint line="4"></breakpoint>
        <breakpoint line="8"></breakpoint>
    </file>
    <file name="c:\project\file2.as">
        <breakpoint line="12"></breakpoint>
    </file>
</flash_breakpoints>
*/

static _str _flash_get_global_classpath(int version)
{
   if (_isUnix()) {
      return '';
   }
   if (_isWindows()) {
      // # Windows:
      // Hard Disk\Documents and Settings\user\Local Settings\Application Data\Macromedia\Flash 8\language\Configuration\Classes
      // Hard Disk\Documents and Settings\user\Local Settings\Application Data\Macromedia\Flash MX 2004\language\Configuration\Classes
      if (version < 7 || version > 8) {
         return '';
      }
      path := "";
      classpaths := "";
      local_app_data := "";
      language := "";
      ntGetSpecialFolderPath(local_app_data, CSIDL_LOCAL_APPDATA);
      language = _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\Macromedia\Flash ' :+ version :+ '\Settings', '', 'Language');
      switch (version) {
      case 8:
         path = local_app_data :+  'Macromedia\Flash 8\' :+ language :+ '\Configuration\Classes';
         classpaths = _maybe_quote_filename(path :+ FILESEP :+ "toplevel.as");
         classpaths :+= " "_maybe_quote_filename(path :+ FILESEP :+ "mx" :+ FILESEP :+ "*.as");
         classpaths :+= " "_maybe_quote_filename(path :+ FILESEP :+ "FP8" :+ FILESEP :+ "*.as");
         break;
      case 7:
         path = local_app_data :+  'Macromedia\Flash MX 2004\' :+ language :+ '\Configuration\Classes';
         classpaths = _maybe_quote_filename(path :+ FILESEP :+ "*.as");
         break;
      }
      return classpaths;
   } else if (_isMac()) {
      // # Macintosh
      // Hard Disk/Users/user/Library/Application Support/Macromedia/Flash 8/language/Configuration/Classes
      // Hard Drive/Users/Library/Application Support/Macromedia/Flash MX 2004/language/Configuration/Classes
   }
   return '';
}


static int _flash_get_version_number()
{
   if (_isUnix()) {
      return -1;
   }
   if (_isWindows()) {
      //HKEY_LOCAL_MACHINE\SOFTWARE\Macromedia\Flash\8
      //HKEY_LOCAL_MACHINE\SOFTWARE\Macromedia\Flash\8\InstallPath
      //HKEY_CURRENT_USER\Software\Macromedia\Flash 8\exePath
      //HKEY_CURRENT_USER\Software\Macromedia\Flash 8\Settings\Language
      //C:\Program Files\Macromedia\Flash 8\Flash.exe
      _str version;
      current_version := -1;

      int status = _ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,
                                  'SOFTWARE\Macromedia\Flash', version, 1);
      while (!status && isnumber(version)) {
         if ((int)version > current_version) {
            current_version = (int)version;
         }
         status = _ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,
                                 'SOFTWARE\Macromedia\Flash', version, 0);
      }
      return current_version;
   }
   return -1;
}

_str _flash_get_ide_path()
{
   if (_isUnix()) {
      return '';
   }
   if (_isWindows()) {
      int version = _flash_get_version_number();
      if (version > 0) {      
         return _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\Macromedia\Flash ':+version, '', 'exePath');
      }
   }
   return '';
}

static _str path_to_uri(_str path)
{
   path = stranslate(path,'/', '\');
   path = stranslate(path,'|', ':');
   path = stranslate(path,'%20', ' ');
   path = 'file:///' :+ path;
   return path;
}

static void _jsfl_generate_project_script(bool is_publish_script, _str project_name)
{
   project_path := _strip_filename(project_name, 'N');
   _str project_command = is_publish_script ? 'publishProject' : 'testProject';
   _lbclear();
   insert_line('/* autogenerated script */');
   insert_line('');
   insert_line('var project_name = "'path_to_uri(project_name)'";');
   insert_line('var log_file = "'path_to_uri(project_path :+ 'log_file.txt')'";');
   insert_line('');
   insert_line('fl.outputPanel.clear();');
   insert_line('fl.trace("'project_command'(" + project_name + ")");');
   insert_line('fl.openProject(project_name);');
   insert_line('var bSucceess = fl.getProject().'project_command'();');
   insert_line('fl.trace(bSucceess)');
   insert_line('fl.outputPanel.save(log_file);');
}

int _flash_create_default_build_scripts(_str project_name)
{
   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   filename := "publish.jsfl";
   if (!file_exists(filename)) {
      p_buf_name = filename;
      _jsfl_generate_project_script(true, project_name);
      _save_file('+o');
   }
   filename = 'test.jsfl';
   if (!file_exists(filename)) {
      p_buf_name = filename;
      _jsfl_generate_project_script(false, project_name);
      _save_file('+o');
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

bool _as_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}
