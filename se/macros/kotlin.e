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
#import "se/lang/api/LanguageSettings.e"
#import "se/ui/AutoBracketMarker.e"
#import "cutil.e"
#import "c.e"
#import "stdcmds.e"
#import "groovy.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "cfcthelp.e"
#import "cjava.e"
#import "csymbols.e"
#import "diffprog.e"
#import "env.e"
#import "gradle.e"
#import "hotspots.e"
#import "java.e"
#import "javacompilergui.e"
#import "main.e"
#import "notifications.e"
#import "optionsxml.e"
#import "picture.e"
#import "pmatch.e"
#import "project.e"
#import "projconv.e"
#import "refactor.e"
#import "scala.e"
#import "slickc.e"
#import "smartp.e"
#import "sbt.e"
#import "stdprocs.e"
#import "tags.e"
#import "vc.e"
#import "wkspace.e"
#import "surround.e"
#endregion

using se.lang.api.LanguageSettings;
using se.ui.AutoBracketMarker;

#if 0
_str def_scala_home;

#endif
_str gCancelledCompiler;   // Used to cancel an auto-tagging of the kotlin compiler libraries.


// States the auto-tagging process can be in.
#define SAS_UNKNOWN 0
#define SAS_NOT_TAGGED 1
#define SAS_TAGGED 2
#define SAS_CANCELLED 3
int def_kotlin_autotag_state = SAS_UNKNOWN;
_str def_kotlin_compiler_exe;

definit()
{
   gCancelledCompiler='';
}

_command void kotlin_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('kotlin');
}

// Prefers a user setting, but if none is available, looks on path and in standard locations.
static _str get_kotlin_compiler()
{
   if (!file_exists(def_kotlin_compiler_exe)) {
      path := path_search('kotlinc'EXTENSION_EXE, 'PATH', 'P');
      if (path != '') {
         def_kotlin_compiler_exe = path;
      }
   }

   return def_kotlin_compiler_exe;
}

//TODO run arguments - what we did for the other languages. Debug run with arguments already works.
int _kotlin_set_environment(int projectHandle, _str cfg, _str target, 
                            bool quite, _str error_hint)
{
   rv := 0;
   if (_ProjectGet_AppType(projectHandle, cfg) == 'gradle') {
      rv = setup_gradle_environment();
   } else {
      if (def_kotlin_compiler_exe == '' || !file_exists(def_kotlin_compiler_exe)) {
         // Prompt the user.
         kc := show('_kotlin_compiler_location_form -modal');
         if (kc != '') {
            def_kotlin_compiler_exe = kc;
         }
      }
      if (!file_exists(def_kotlin_compiler_exe)) {
         rv = FILE_NOT_FOUND_RC;
         message('Can not find kotlinc executable');
      } else {
         kc := get_kotlin_compiler();
         set_env('SE_KOTLINC', kc);
         set('SE_KOTLINC='kc);

         kclib := find_kotlin_libs_dir(kc, auto ver);
         if (kclib != '') {
            cmplib := _maybe_quote_filename(kclib'kotlin-compiler.jar');
            set_env('SE_KOTLINC_LIB', cmplib);
            set('SE_KOTLINC_LIB='cmplib);
         }

         jroot := get_active_java_root();
         if (!file_exists(jroot)) {
            st := _message_box('Command failed, no java runtime configured.  Configure one now?', 'SlickEdit', MB_YESNO);
            if (st == IDYES) {
               config('_java_compiler_properties_form', 'D');
               // The dialog doesn't block, so we need to fail this operation.
               rv = FILE_NOT_FOUND_RC;
            }
         } else {
            _maybe_append_filesep(jroot);
            java := jroot'bin'FILESEP'java'EXTENSION_EXE;
            if (file_exists(java)) {
               set_env('SE_JAVA', java);
               set('SE_JAVA='java);
            } else {
               message('Could not find configured java install.');
               rv = FILE_NOT_FOUND_RC;
            }
         }
      }
   }

   return rv;
}

int _kotlins_set_environment(int projectHandle, _str cfg, _str target, 
                            bool quite, _str error_hint)
{
   return _kotlin_set_environment(projectHandle,cfg,target,quite,error_hint);
}

/*int _kotlin_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, kotlin_space_words, prefix, min_abbrev);
} */
bool _kotlin_find_surround_lines(int &first_line, int &last_line,
                               int &num_first_lines, int &num_last_lines,
                               bool &indent_change,
                               bool ignoreContinuedStatements=false) {
   return _c_find_surround_lines(first_line,last_line,num_first_lines,num_last_lines,indent_change,ignoreContinuedStatements);
}

bool _kotlins_find_surround_lines(int &first_line, int &last_line,
                               int &num_first_lines, int &num_last_lines,
                               bool &indent_change,
                               bool ignoreContinuedStatements=false) {
   return _c_find_surround_lines(first_line,last_line,num_first_lines,num_last_lines,indent_change,ignoreContinuedStatements);
}
#if 0
static bool _in_one_line_brace_pair()
{
   return should_expand_cuddling_braces(p_LangId);
}

void _scala_auto_bracket_key_mask(_str close_ch, int* keys)
{
   if (close_ch == '}' && _in_one_line_brace_pair()) {
      *keys = *keys & ~AUTO_BRACKET_KEY_ENTER;
   }
}
#endif

bool _kotlin_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _kotlin_supports_insert_begin_end_immediately() {
   return true;
}
int _kotlin_delete_char(_str force_wrap='') {
   return _c_delete_char(force_wrap);
}

int kotlin_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return groovy_smartpaste(char_cbtype,first_col,Noflines,allow_col_1);
}
bool _kotlin_is_continued_statement()
{
   return _c_is_continued_statement();
}

int _kotlin_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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


int _kotlin_parse_return_type(_str (&errorArgs)[], typeless tag_files,
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

int _kotlin_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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
int _kotlin_get_type_of_expression(_str (&errorArgs)[], 
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

int _kotlin_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
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

int _kotlin_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                             struct VS_TAG_RETURN_TYPE &rt_candidate,
                             _str tag_name,_str type_name,
                             SETagFlags tag_flags,
                             _str file_name, int line_no,
                             _str prefixexp,typeless tag_files,
                             int tree_wid, int tree_index)
{
   return 0;
}

int _kotlin_fcthelp_get_start(_str (&errorArgs)[],
                              bool OperatorTyped,
                              bool cursorInsideArgumentList,
                              int &FunctionNameOffset,
                              int &ArgumentStartOffset,
                              int &flags,
                              int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _kotlin_fcthelp_get(_str (&errorArgs)[],
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
 
bool _kotlins_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _kotlins_supports_insert_begin_end_immediately() {
   return true;
}
int _kotlins_delete_char(_str force_wrap='') {
   return _c_delete_char(force_wrap);
}

int kotlins_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return groovy_smartpaste(char_cbtype,first_col,Noflines,allow_col_1);
}
bool _kotlins_is_continued_statement()
{
   return _c_is_continued_statement();
}

int _kotlins_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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


int _kotlins_parse_return_type(_str (&errorArgs)[], typeless tag_files,
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

int _kotlins_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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
int _kotlins_get_type_of_expression(_str (&errorArgs)[], 
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

int _kotlins_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
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

int _kotlins_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                             struct VS_TAG_RETURN_TYPE &rt_candidate,
                             _str tag_name,_str type_name,
                             SETagFlags tag_flags,
                             _str file_name, int line_no,
                             _str prefixexp,typeless tag_files,
                             int tree_wid, int tree_index)
{
   return 0;
}

int _kotlins_fcthelp_get_start(_str (&errorArgs)[],
                              bool OperatorTyped,
                              bool cursorInsideArgumentList,
                              int &FunctionNameOffset,
                              int &ArgumentStartOffset,
                              int &flags,
                              int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _kotlins_fcthelp_get(_str (&errorArgs)[],
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
static _str find_kotlin_libs_dir(_str kc, _str& version)
{
   jf := 'kotlin-compiler.jar';
   bdir := _strip_filename(kc, 'N');
   ldir := '';
   tf := bdir'..'FILESEP'lib'FILESEP:+jf;
   if (file_exists(tf)) {
      ldir = _strip_filename(tf, 'N');
   } else {
      // For snap packages, a slightly different relative path from bin to lib.
      tf = bdir'..'FILESEP'kotlin'FILESEP'current'FILESEP'lib'FILESEP:+jf;
      if (file_exists(tf)) {
         ldir = _strip_filename(tf, 'N');
      }
   }

   if (ldir != '') {
      // Most kotlin installs have a build.txt that just contains the build number.
      status := _open_temp_view(ldir'..'FILESEP'build.txt', auto wid, auto origWid);
      if (status < 0) {
         version = 'installed';
      } else {
         top();
         get_line(version);
         activate_window(origWid);
         _delete_temp_view(wid);
         version = strip(version);
      }
   }

   return ldir;
}

// Extracts compiler version and library source fars for kotlin that was stashed 
// in the project file.
static void projGetKotlinCompilerInfo(_str& version, _str& libSrcJars)
{
   version = '';
   libSrcJars = '';
   handle := _ProjectHandle(_project_name, auto status);
   if (handle < 0) {
      return;
   }
   config := GetCurrentConfigName();

   root := _ProjectGet_ConfigNode(handle, config);
   if (root < 0) {
      return;
   }

   opt_node := _xmlcfg_find_simple(handle,"List[@Name='KotlinVersion']", root);
   if( opt_node >= 0 ) {
      node := _xmlcfg_find_simple(handle,"Item[@Name='Version']",opt_node);
      if( node >=0  ) {
         version = _xmlcfg_get_attribute(handle,node,"Value", '');
      }

      _str nodes[];
      if (_xmlcfg_find_simple_array(handle, "Item[@Name='SourceJar']", nodes, opt_node) == 0) {
         _str srcList = '';
         _str n;
         foreach (n in nodes) {
            f := _xmlcfg_get_attribute(handle,(int)n,"Value", '');
            if (f != '') {
               if (srcList != '') {
                  srcList :+= ' ';
               }
               srcList :+= _maybe_quote_filename(f);
            }
         }
         libSrcJars = srcList;
      }
   } else {
      // If there's no version information stored in the project file, then this is
      // not a compiler installed by gradle, but one on the system somewhere. See if 
      // we can locate the sources from the kotlin compiler path.
      kc := get_kotlin_compiler();
      if (kc != '') {
         ld := find_kotlin_libs_dir(kc, version);
         if (ld != '') {
            libSrcJars = '';
            tf := ld'kotlin-stdlib-jdk8-sources.jar';
            if (file_exists(tf)) libSrcJars :+= _maybe_quote_filename(tf)' ';
            tf = ld'kotlin-stdlib-sources.jar';
            if (file_exists(tf)) libSrcJars :+= _maybe_quote_filename(tf)' ';
         }
      }
      //say('version='version', libs='libSrcJars);
   }
}

static _str kotlinCompilerTagfile(_str ver)
{
   compName := 'kotlin_'ver;
   return _tagfiles_path():+compName:+TAG_FILE_EXT;
}

static void update_autotag_state(_str kotVer)
{
   _str tf;
   st := def_kotlin_autotag_state;
   checking := true;
   while (checking) {
      checking = false;

      switch (st) {
      case SAS_UNKNOWN:
         tf = kotlinCompilerTagfile(kotVer);
         if (file_exists(tf)) {
            st = SAS_TAGGED;
         } else {
            st = SAS_NOT_TAGGED;
         }
         break;

      case SAS_NOT_TAGGED:
         tf = kotlinCompilerTagfile(kotVer);
         if (file_exists(tf)) {
            st = SAS_TAGGED;
         }
         break;

      case SAS_TAGGED:
         tf = kotlinCompilerTagfile(kotVer);
         if (!file_exists(tf)) {
            st = SAS_NOT_TAGGED;
         }
         break;

      case SAS_CANCELLED:
         break;

      default:
         st = SAS_UNKNOWN;
         checking=true;
      }
   }

   def_kotlin_autotag_state=st;
}

int _kotlin_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   projGetKotlinCompilerInfo(auto kotVer, auto srcJars);
   if (kotVer == '' || srcJars == '') {
      return 0;
   }
   tagfile_name := kotlinCompilerTagfile(kotVer);

   if (tagfile_name != '' && tagfile_name != gCancelledCompiler) {
      update_autotag_state(kotVer);
      if (def_kotlin_autotag_state == SAS_NOT_TAGGED) {
         status := ext_BuildTagFile(tfindex, tagfile_name, 'kotlin', 'Kotlin Language', false, srcJars, '', withRefs, useThread);

         if (status) {
            message('Problem building Kotlin language tag file: 'status);
            gCancelledCompiler = tagfile_name;
         } else {
            gCancelledCompiler = '';
         }
      }
   }

   // If we're calling this from kotlinscript, and the kotlin tag file already 
   // exists (or vica versa), then we still need to communicate the tag file name 
   // back to the tagging system.
   if (LanguageSettings.getTagFileList(p_LangId) == '') {
      LanguageSettings.setTagFileList(p_LangId, tagfile_name);
   }

   return 0;
}

int _kotlins_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false)
{
   return _kotlin_MaybeBuildTagFile(tfindex,withRefs,useThread);
}

static _str kotlinc_from_dir(_str dir)
{
   exe := strip(dir);
   if (exe != '') {
      _maybe_append_filesep(exe);
      exe :+= 'kotlinc' :+ EXTENSION_BAT;
   }
   return exe;
}

static void update_paths_state(typeless dummy = null)
{
   exe := kotlinc_from_dir(_ctl_kotlin_exe.p_text);

   if (file_exists(exe)) {
      _ctl_home_error.p_visible = false;
   } else {
      _ctl_home_error.p_caption = "* '"exe"' is not a valid executable";
      _ctl_home_error.p_visible = true;
   }
}

defeventtab _kotlin_compiler_location_form;

void _ctl_kotlin_exe.on_change()
{
   update_paths_state(0);
}

void _ctl_kotlin_exe.on_create()
{
   kc := _strip_filename(get_kotlin_compiler(), 'N');
   _ctl_kotlin_exe.p_text = kc;
   update_paths_state(0);

   sizeBrowseButtonToTextBox(_ctl_kotlin_exe.p_window_id, 
                             _browsedir1.p_window_id, 0, 
                             p_active_form.p_width - _ctl_kotlin_exe.p_prev.p_x);
}

void _ctl_kotlin_exe.'ENTER'()
{
   p_active_form._delete_window(kotlinc_from_dir(_ctl_kotlin_exe.p_text));
}

void _ctl_ok.lbutton_up()
{
   p_active_form._delete_window(kotlinc_from_dir(_ctl_kotlin_exe.p_text));
}

// Support for same dialog embedded into the options tree.
void _kotlin_compiler_location_form_init_for_options(_str langid)
{
   _nocheck _control _ctl_kotlin_exe;
   _nocheck _control _ctl_ok;

   kc := get_kotlin_compiler();
   if (kc == '') {
      kc = def_kotlin_compiler_exe;
   }

   kc = _strip_filename(kc, 'N');
   _ctl_kotlin_exe.p_text = kc;
   update_paths_state(0);
   _ctl_ok.p_visible = false;
}

bool _kotlin_compiler_location_form_apply()
{
   _nocheck _control _ctl_kotlin_exe;

   def_kotlin_compiler_exe = kotlinc_from_dir(_ctl_kotlin_exe.p_text);
   return true;
}

bool _kotlin_compiler_location_form_is_modified()
{
   _nocheck _control _ctl_kotlin_exe;

   return kotlinc_from_dir(_ctl_kotlin_exe.p_text) != get_kotlin_compiler();
}
