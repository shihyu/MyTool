////////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 SlickEdit Inc. 
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
#include "slick.sh"
#import "ccontext.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "compile.e"
#import "complete.e"
#import "csymbols.e"
#import "cutil.e"
#import "diff.e"
#import "dir.e"
#import "env.e"
#import "help.e"
#import "main.e"
#import "mprompt.e"
#import "projutil.e"
#import "projconv.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "wkspace.e"

_command void rust_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('rs');
}
bool _rs_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _rs_supports_insert_begin_end_immediately() {
   return true;
}
/**
 * Set to the path to 'cargo' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_cargo_exe_path;
_str def_rust_cargo_package="Rust - Cargo GNU";
int _new_rust_proj(bool inDialog,_str packageName,_str Filename,_str Path, bool add_to_workspace, bool ExecutableName,_str Dependency,bool ShowProperties=false,bool runInitMacros=true)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str filename=path_search('cargo',"PATH",'P');
   // IF cargo isn't installed and in the PATH
   if (filename=='') {
      _message_box("'cargo' executable not found. Please install rust and make sure cargo is in your path");
      return(1);
   }
   if (_DebugMaybeTerminate()) {
      return(1);
   }
   msg := "";
   if (Filename=='') {
      msg="You must specify a project name";
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (_isWindows()) {
         // pretty much all the characters are allowed on UNIX
      if (iswildcard(Filename)) {
         msg="Invalid filename";
         if (inDialog) {
            _new_prjname._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return(1);
      }
   }
   if (Path=='') {
      msg="You must specify a project directory";
      if (inDialog) {
         ctlProjectNewDir._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (_strip_filename(Filename,'n')!='') {
      msg='Project name must not contain a path';
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (pos('[a-zA-Z_$][a-zA-Z_$0-9]@',Filename,1,'r')!=1 || pos('')!=length(Filename)) {
       msg='Project name must be valid identifier';
       if (inDialog) {
          _new_prjname._text_box_error(msg);
       } else {
          _message_box(msg);
       }
       return(1);
   }

   Path=strip(Path,'B','"');
   _maybe_append_filesep(Path);

   // handle special unix paths like "~/"
   if (def_unix_expansion) {
      Path = _unix_expansion(Path);
   }

   Path=absolute(Path);    // VC++ uses current directory

   ProjectPath := Path:+Filename;
   if (isdirectory(ProjectPath)) {
       _message_box(nls("Directory %s already exists.", Path), "", MB_OK);
       return 1;

   }


   createdDirectory := false;
   // Only show project properties if directory does not exist.
   // Moving thing code fixes bug when adding project to workspace.
   status := 0;
   if (!isdirectory(Path)) {
      createdDirectory=true;
      status=_mkdir_chdir(Path);
      if (status) {
         return(status);
      }
   } else {
      cd(Path);
      ShowProperties=true;
   }
   // run cargo to create the cargo project files
   status=shell('cargo new 'Filename' --bin','q');
   if (!isdirectory(ProjectPath)) {
       _message_box(nls("Failed to create directory %s.", ProjectPath), "", MB_OK);
       return 1;
   }
   cargo_toml:=ProjectPath:+FILESEP:+'Cargo.toml';
   if (!file_exists(cargo_toml)) {
       _message_box(nls("File '%s' not found", cargo_toml), "", MB_OK);
       return 1;
   }
   if (inDialog) {
      p_active_form._delete_window(0);
   }
   if (def_rust_cargo_package!=packageName) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_rust_cargo_package=packageName;
   }
   result:=workspace_open(cargo_toml);

   return result;
   //return setup_rust_proj(configName);
}

static _str guessCargoCompilerExePath()
{
   if( def_cargo_exe_path != "" ) {
      // No guessing necessary
      return def_cargo_exe_path;
   }
   filename := _HomePath()'/.cargo/bin/cargo'EXTENSION_EXE;
   if (file_exists(filename)) {
       return absolute(filename);
   }
   if (_isUnix()) {
      filename = "/usr/local/bin/cargo"EXTENSION_EXE;
      if (file_exists(filename)) {
          return absolute(filename);
      }
   }
   return '';
}
int _cargo_set_environment2() {
    _str cargo_filename=_orig_path_search('cargo');
    if (cargo_filename!="") {
        //if (!quiet) {
        //   _message_box('Rust is already setup.  rustc is already in your PATH.');
        //}
        _restore_origenv(true);
        return(0);
    }

    cargoExePath := "";
    if( def_cargo_exe_path != "" ) {
       _restore_origenv(false);
       // Use def_cargo_exe_path
       cargoExePath = def_cargo_exe_path;
    } else {
       _restore_origenv(true);

       for (;;) {
           // Prompt user for interpreter
           int status = _mdi.textBoxDialog("Cargo Executable",
                                           0,
                                           0,
                                           "",
                                           "OK,Cancel:_cancel\tSpecify the path and name to 'cargo"EXTENSION_EXE"'",  // Button List
                                           "",
                                           "-bf Cargo Executable:":+guessCargoCompilerExePath());
           if( status < 0 ) {
              // Probably COMMAND_CANCELLED_RC
              return status;
           }
           if (file_exists(_param1)) {
              break;
           }
           _message_box('cargo executable not found. Please correct the path or cancel');
       }

       // Save the values entered and mark the configuration as modified
       def_cargo_exe_path = _param1;
       _config_modify_flags(CFGMODIFY_DEFVAR);
       cargoExePath = def_cargo_exe_path;
    }

    // Make sure we got a path
    if( cargoExePath == "" ) {
       return COMMAND_CANCELLED_RC;
    }

    // Set the environment
    //set_env('SLICKEDIT_CARGO_EXE',cargoExePath);
    cargoDir := _strip_filename(cargoExePath,'N');
    _maybe_strip_filesep(cargoDir);
    // PATH
    _str path = _replace_envvars("%PATH%");
    _maybe_prepend(path,PATHSEP);
    path = cargoDir:+path;
    set("PATH="path);

    // Success
    return 0;
}
int _cargo_set_environment(int projectHandle=-1, _str config="", _str target="",
                            bool quiet=false, _str& error_hint=null)
{
    return _cargo_set_environment2();
}


int _rs_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          bool find_parents,int max_matches,
                          bool exact_match,bool case_sensitive,
                          SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                          SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
     isay(depth, '_rs_find_context_tags(prefixexp='prefixexp' lastid='lastid' lastidstart_offset='lastidstart_offset' info_flags='info_flags' otherinfo='otherinfo' find_parents='find_parents' max_matches='max_matches' exact_match='exact_match' case_sensitive='case_sensitive' filter_flags='filter_flags' context_flags='context_flags')');
   }
   return _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                               info_flags,otherinfo,find_parents,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,
                               visited,depth+1,prefix_rt);
}

int _rs_fcthelp_get_start(_str (&errorArgs)[],
                          bool OperatorTyped,
                          bool cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags,
                          int depth=0)
{
   return _c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags,
                               depth);
}

int _rs_fcthelp_get(_str (&errorArgs)[],
                    VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                    bool &FunctionHelp_list_changed,
                    int &FunctionHelp_cursor_x,
                    _str &FunctionHelp_HelpWord,
                    int FunctionNameStartOffset,
                    int flags,
                    VS_TAG_BROWSE_INFO symbol_info=null,
                    VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,FunctionHelp_list,
                         FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth);
}

int _rs_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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
                                 rt,visited,depth+1);
}

int _rs_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   status := _c_get_expression_info(PossibleOperator, info, visited, depth);
   return status;
}

int _rs_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}

int _rs_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix="", 
                                 bool exact_match=false, bool case_sensitive=true,
                                 _str param_name="", _str param_default="",
                                 struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (0);
   }

   // Insert boolean
   match_count := 0;
   if (rt_expected.return_type=="bool") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k := tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k := tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
   }

   // that's all folks
   return(match_count);
}

/**
 * @see _c_get_type_of_expression
 */
int _rs_get_type_of_expression(_str (&errorArgs)[], 
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

/**
 * @see ext_MaybeBuildTagFIle
 */
int _rs_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (ext_MaybeRecycleTagFile(tfindex, auto tagfilename, "rs", "rust") && !forceRebuild) {
      return(0);
   }
   return ext_MaybeBuildTagFile(tfindex, "rs", "rust", 
                                "Rust Libraries",
                                "-E *.toml", true,
                                withRefs, useThread, forceRebuild);
}

/**
  On entry, cursor is on line,column of tag symbol.
  Finds the starting line and ending line for the tag's comments.

  @param first_line   (output) set to first line of comment
  @param last_line    (output) set to last line of comment

  @return 0 if header comment found and first_line,last_line
          set.  Otherwise, 1 is returned.
*/
int _rs_get_tag_header_comments(int &first_line,int &last_line)
{
   // first try to get comments above the function or macro
   save_pos(auto orig_pos);
   status := _do_default_get_tag_header_comments_above(first_line,last_line);
   if (!status) return status;
   restore_pos(orig_pos);
   return _do_default_get_tag_header_comments_below(first_line,last_line);
}

_str _rs_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   tag_flags  := info.flags;
   tag_name   := info.member_name;
   class_name := info.class_name;
   type_name  := info.type_name;
   in_class_def := (flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   verbose      := (flags&VSCODEHELPDCLFLAG_VERBOSE);
   show_class   := (flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   show_access  := (flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   arguments := (info.arguments!="")? "("info.arguments")":"";
   result := "";
   proto := "";
   kw := "";

   if (!in_class_def && show_class && class_name!="") {
      class_name = stranslate(class_name,"::",":");
      class_name = stranslate(class_name,"::","/");
      tag_name   = class_name"::"tag_name;
   }

   //say("_pas_get_decl: type_name="type_name);
   switch (type_name) {
   case "proc":         // procedure or command
   case "proto":        // function prototype
   case "constr":       // class constructor
   case "destr":        // class destructor
   case "func":         // function
   case "procproto":    // Prototype for procedure
   case "subfunc":      // Nested function or cobol paragraph
   case "subproc":      // Nested procedure or cobol paragraph
   case "closure":      // closure

      before_tag := decl_indent_string;
      if (tag_flags & SE_TAG_FLAG_EXTERN) {
         before_tag :+= "extern ";
      }

      if (show_access && in_class_def) {
         c_access_flags := (tag_flags & SE_TAG_FLAG_ACCESS);
         switch (c_access_flags) {
         case SE_TAG_FLAG_PUBLIC:
            before_tag :+= "pub ";
            break;
         case SE_TAG_FLAG_PACKAGE:
            break;
         case SE_TAG_FLAG_PROTECTED:
            before_tag :+= "prot ";
            break;
         case SE_TAG_FLAG_PRIVATE:
            before_tag :+= "priv ";
            break;
         }
      }

      if (verbose) {
         if (tag_flags & SE_TAG_FLAG_VIRTUAL) {
            before_tag :+= "virt ";
         }
         if (tag_flags & SE_TAG_FLAG_ABSTRACT) {
            before_tag :+= "abstract ";
         }
      }

      if (verbose && in_class_def && (tag_flags & SE_TAG_FLAG_STATIC)) {
         before_tag :+= "static ";
      }
      if (verbose) {
         before_tag :+= "fn ";
      }

      // prepend qualified class name for C++
      if ((tag_flags & SE_TAG_FLAG_OPERATOR) && verbose) {
         tag_name = "op ":+tag_name;
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,"::",":");
         class_name = stranslate(class_name,"::","/");
         tag_name   = class_name"::"tag_name;
      }

      return_type := info.return_type;
      after_sig := "";
      if (return_type!="" && verbose) {
         after_sig = " -> ":+return_type;
      }

      // finally, insert the line
      result=before_tag:+tag_name:+"("info.arguments")":+after_sig;
      return(result);

   case "define":       // preprocessor macro definition
      if (verbose) {
         return(decl_indent_string"macro_rules! ":+tag_name:+arguments);
      }
      return(decl_indent_string:+tag_name:+"!":+arguments);

   case "typedef":      // type definition
      if (verbose) {
         return(decl_indent_string:+"type ":+tag_name" = "info.return_type:+arguments);
      }
      return(decl_indent_string:+tag_name);

   case "gvar":         // global variable declaration
   case "var":          // member of a class / struct / package
   case "lvar":         // local variable declaration
   case "prop":         // property
   case "param":        // function or procedure parameter
   case "group":        // Container variable
   case "const":        // Constant
      if (type_name == "lvar")  kw = "let";
      if (type_name == "const") kw = "const";
      if (verbose) {
         return(decl_indent_string:+kw:+" ":+tag_name:+": ":+info.return_type);
      }
      return(decl_indent_string:+tag_name);

   case "struct":       // structure definition
   case "enum":         // enumerated type
   case "class":        // class definition
   case "union":        // structure / union definition
   case "interface":    // interface, eg, for Java
   case "package":      // package / module / namespace
   case "prog":         // pascal program
   case "lib":          // pascal library
      before_tag = decl_indent_string;
      if (tag_flags & SE_TAG_FLAG_EXTERN) {
         before_tag :+= "extern ";
      }
      if (show_access && in_class_def) {
         c_access_flags := (tag_flags & SE_TAG_FLAG_ACCESS);
         switch (c_access_flags) {
         case SE_TAG_FLAG_PUBLIC:
            before_tag :+= "pub ";
            break;
         case SE_TAG_FLAG_PACKAGE:
            break;
         case SE_TAG_FLAG_PROTECTED:
            before_tag :+= "prot ";
            break;
         case SE_TAG_FLAG_PRIVATE:
            before_tag :+= "priv ";
            break;
         }
      }
      arguments = (info.template_args!="")? "<"info.template_args">" : "";
      switch (type_name) {
      case "struct":       kw="struct";  break;
      case "enum":         kw="enum";    break;
      case "class":        kw="impl";    break;
      case "union":        kw="union";   break;
      case "interface":    kw="trait";   break;
      case "package":      kw="mod";     break;
      case "prog":         kw="crate";   break;
      case "lib":          kw="crate";   break;
      case "task":         kw="impl";    break;
      }
      if (verbose) {
         return(decl_indent_string:+before_tag:+kw" "tag_name:+arguments);
      }
      return(decl_indent_string:+tag_name:+arguments);

   case "label":        // label
      if (verbose) {
         return(decl_indent_string:+tag_name":");
      }
      return(decl_indent_string:+tag_name);

   case "import":       // package import or using
      if (verbose) {
         return(decl_indent_string:+"use ":+tag_name);
      }
      return(decl_indent_string:+tag_name);

   case "friend":       // C++ friend relationship
      if (verbose) {
         return(decl_indent_string:+"friend "tag_name:+arguments);
      }
      return(decl_indent_string:+tag_name:+arguments);
   case "include":      // C++ include or Ada with (dependency)
      if (verbose) {
         return(decl_indent_string:+"#include "tag_name);
      }
      return(decl_indent_string:+tag_name);

   case "enumc":        // enumeration value
      proto=decl_indent_string:+tag_name;
      strappend(proto,info.member_name);
      if (info.return_type!="" && verbose) {
         strappend(proto," = "info.return_type);
      }
      return(proto);

   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "file":         // COBOL file descriptor
   case "cursor":       // Database result set cursor
      if (verbose) {
         return(decl_indent_string:+type_name" "tag_name);
      }
      return(decl_indent_string:+tag_name);

   default:
      proto=decl_indent_string:+info.member_name;
      if (info.return_type!="" && verbose) {
         strappend(proto,": "info.return_type" ");
      }
      return(proto);
   }
}

bool _rs_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                    VS_TAG_IDEXP_INFO &idexp_info, 
                                    _str terminationKey="")
{
   if (get_text() != "!" && 
       word != null && word.symbol != null && word.symbol.type_name == "define" && 
       cur_identifier(auto start_col) == word.symbol.member_name) {
      _insert_text("!");
   }
   return true;
}
