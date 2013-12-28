////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#import "smartp.e"
#import "tags.e"
#import "c.e"
#import "caddmem.e"
#import "cbrowser.e"
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

defeventtab actionscript_keys;
def  ' '= c_space;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  ':'= c_colon;
def  '='= auto_codehelp_key;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  '*'= c_asterisk;
def  '/'= c_slash;
def  'ENTER'= c_enter;
def  'TAB'= smarttab;

defload()
{
   _str setup_info="MN=ActionScript,TABS=+4,MA=1 74 1,":+
                   "KEYTAB=actionscript-keys,WW=1,IWT=0,ST="DEFAULT_SPECIAL_CHARS",IN=2,WC=A-Za-z0-9_$,LN=ActionScript,CF=1,";
   _str compile_info="";
   _str syntax_info="4 1 1 0 4 1 1";
   _CreateLanguage('as', 'ActionScript', setup_info, compile_info, syntax_info);
   _CreateExtension('as', 'as');

   // refer jsfl to javascript
   // TODO: update tags with jsfl builtins?
   replace_def_data("def-lang-for-ext-jsfl", "js"); 

#if !__UNIX__
   // associate files so they can be loaded by default app  
   replace_def_data("def-association-fla", 1' '); 
   replace_def_data("def-association-swf", 1' ');
#endif
}

_command void actionscript_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage("as");
}

int as_smartpaste(boolean char_cbtype,int first_col,int Noflines,boolean allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _as_MaybeBuildTagFile(int &tfindex)
{
   _str ext = "as";
   _str tagfilename = '';
   if (ext_MaybeRecycleTagFile(tfindex, tagfilename, ext, ext)) {
      return(0);
   }

   int status = 0;
   int version = _flash_get_version_number();
   status = ext_BuildTagFile(tfindex, tagfilename, ext, "ActionScript Global Classpath",
                              true, _flash_get_global_classpath(version),
                              ext_builtins_path(ext,"actionscript"));
   return (status);
}


/**
 * @see _c_generate_function
 */
int _as_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                 _str (&header_list)[],_str function_body,
                                 int indent_col, int begin_col,
                                 boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}

/**
 * @see _c_get_expression_pos
 */
int _as_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
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
int _as_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
                          boolean find_parents,int max_matches,
                          boolean exact_match,boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_as_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   errorArgs[1] = lastid;
   num_matches := 0;
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
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
      _str package_name = substr(prefixexp,1,length(prefixexp)-1);
      if (pos("^[."word_chars"]@$", prefixexp, 1, 'r') &&
          (filter_flags & VS_TAGFILTER_PACKAGE) &&
          //_MatchSymbolAsPackage(prefixexp:+lastid, true, true)) {
          tag_check_for_package(package_name, tag_files, true, case_sensitive)) {
         rt.return_type='';
         //lastid = prefixexp:+lastid;
         tag_clear_matches();
         tag_list_context_packages(0,0,prefixexp:+lastid,tag_files,num_matches,max_matches,true,true);
         if (num_matches > 0) {
            return 0;
         }
      } else {
         int status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
         if (status) {
            return status;
         }
         // handle 'new' expressions as a special case
         if (pos('new ',prefixexp' ')==1 && (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
            _str outer_class = substr(prefixexp, 5);
            if (last_char(outer_class)==':') {
               outer_class = substr(outer_class, 1, length(outer_class)-2);
            }
            if (last_char(outer_class)=='.') {
               outer_class = substr(outer_class, 1, length(outer_class)-1);
            }
            outer_class = stranslate(outer_class, ':', '::');
            if (outer_class=='') {
               tag_qualify_symbol_name(constructor_class,lastid,'',p_buf_name,tag_files,true);
            } else {
               constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true);
            }
         }

         context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);
         tag_list_in_class(lastid, rt.return_type,
                           0, 0, tag_files,
                           num_matches, max_matches,
                           filter_flags, context_flags,
                           exact_match, case_sensitive, 
                           null, null, visited, depth);
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
                                  visited, depth);
         } else {
         tag_list_globals_of_type(0, 0, as_tag_files,
                                  VS_TAGTYPE_class, 0, 0,
                                  num_matches, max_matches);
      }     
   }

   // this instance is not a function, so mask it out of filter flags
   //int filter_flags=VS_TAGFILTER_ANYTHING;
   //if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
   //   filter_flags &= ~(VS_TAGFILTER_PROC|VS_TAGFILTER_PROTO|VS_TAGFILTER_SUBPROC);
   //}

   // get the current class and current package from the context
   cur_tag_name := cur_type_name := cur_class_name := "";
   cur_class_only := cur_package_name := "";
   cur_tag_flags := cur_type_id := 0;
   context_id := tag_get_current_context(cur_tag_name, cur_tag_flags,
                                         cur_type_name, cur_type_id,
                                         cur_class_name, cur_class_only,
                                         cur_package_name);

   // determine access levels allowed by this context
   if ((pos(cur_package_name'/',rt.return_type)==1) ||
       (pos(cur_package_name'/',constructor_class)==1) ||
       (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
        !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
      context_flags |= VS_TAGCONTEXT_ALLOW_package;
      context_flags |= VS_TAGCONTEXT_ALLOW_protected;
   }

   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==VS_TAGTYPE_function && cur_class_name!='' && prefixexp=='') {
      if (cur_tag_flags & VS_TAGFLAG_static) {
         context_flags |= VS_TAGCONTEXT_ONLY_static;
      }
   }

   // try to match the symbol in the current context
   tag_clear_matches();
   int context_list_flags = VS_TAGCONTEXT_FIND_all;
   if (find_parents) context_list_flags |= VS_TAGCONTEXT_FIND_parents;
   tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, '',
                               num_matches, max_matches,
                               filter_flags, context_flags | context_list_flags,
                               exact_match, case_sensitive, visited, depth);

   if (constructor_class!='') {
      tag_list_in_class(lastid, constructor_class, 0, 0,
                        tag_files, num_matches, max_matches,
                        filter_flags, context_flags|VS_TAGCONTEXT_ONLY_constructors|VS_TAGCONTEXT_ONLY_this_class,
                        exact_match, case_sensitive, null, null, visited, depth);
   }

   // Check if this is a prefix of a package name, return 0
   if (num_matches==0 && pos("^[."word_chars"]@$", prefixexp, 1, 'r') &&
       tag_check_for_package(prefixexp:+lastid, tag_files, false, case_sensitive)) {
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
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
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
 *
 * @return number of items inserted
 */
int _as_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix="", 
                                 boolean exact_match=false, boolean case_sensitive=true)
{
   return _java_insert_constants_of_type(rt_expected,
                                         tree_wid,tree_index,
                                         lastid_prefix,
                                         exact_match,case_sensitive);
}

/**
 * @see _c_match_return_type
 */
int _as_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}

/**
 * @see _c_fcthelp_get_start
 */
int _as_fcthelp_get_start(_str (&errorArgs)[],
                          boolean OperatorTyped,
                          boolean cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}

/**
 * @see _c_fcthelp_get
 */
int _as_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
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

_command void actionscript_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_space();
}

_command void actionscript_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_enter();
}

_command void actionscript_begin() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_begin();
}

_command void actionscript_endbrace() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   c_endbrace();
}

_command void actionscript_colon() name_info(',')
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
#if !__UNIX__
   if (machine() == "WINDOWS") {
      // # Windows:
      // Hard Disk\Documents and Settings\user\Local Settings\Application Data\Macromedia\Flash 8\language\Configuration\Classes
      // Hard Disk\Documents and Settings\user\Local Settings\Application Data\Macromedia\Flash MX 2004\language\Configuration\Classes
      if (version < 7 || version > 8) {
         return '';
      }
      _str path = '';
      _str classpaths = '';
      _str local_app_data = '';
      _str language = '';
      ntGetSpecialFolderPath(local_app_data, CSIDL_LOCAL_APPDATA);
      language = _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\Macromedia\Flash ' :+ version :+ '\Settings', '', 'Language');
      switch (version) {
      case 8:
         path = local_app_data :+  'Macromedia\Flash 8\' :+ language :+ '\Configuration\Classes';
         classpaths = maybe_quote_filename(path :+ FILESEP :+ "toplevel.as");
         classpaths = classpaths" "maybe_quote_filename(path :+ FILESEP :+ "mx" :+ FILESEP :+ "*.as");
         classpaths = classpaths" "maybe_quote_filename(path :+ FILESEP :+ "FP8" :+ FILESEP :+ "*.as");
         break;
      case 7:
         path = local_app_data :+  'Macromedia\Flash MX 2004\' :+ language :+ '\Configuration\Classes';
         classpaths = maybe_quote_filename(path :+ FILESEP :+ "*.as");
         break;
      }
      return classpaths;
   } else if (_isMac()) {
      // # Macintosh
      // Hard Disk/Users/user/Library/Application Support/Macromedia/Flash 8/language/Configuration/Classes
      // Hard Drive/Users/Library/Application Support/Macromedia/Flash MX 2004/language/Configuration/Classes
   }
#endif
   return '';
}


static int _flash_get_version_number()
{
#if !__UNIX__
   if (machine() == "WINDOWS") {
      //HKEY_LOCAL_MACHINE\SOFTWARE\Macromedia\Flash\8
      //HKEY_LOCAL_MACHINE\SOFTWARE\Macromedia\Flash\8\InstallPath
      //HKEY_CURRENT_USER\Software\Macromedia\Flash 8\exePath
      //HKEY_CURRENT_USER\Software\Macromedia\Flash 8\Settings\Language
      //C:\Program Files\Macromedia\Flash 8\Flash.exe
      _str version;
      int current_version = -1;

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
#endif
   return -1;
}

_str _flash_get_ide_path()
{
#if !__UNIX__
   if (machine() == "WINDOWS") {
      int version = _flash_get_version_number();
      if (version > 0) {      
         return _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\Macromedia\Flash ':+version, '', 'exePath');
      }
   }
#endif
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

static void _jsfl_generate_project_script(boolean is_publish_script, _str project_name)
{
   _str project_path = _strip_filename(project_name, 'N');
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
   int temp_view_id = 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   _str filename = 'publish.jsfl';
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
