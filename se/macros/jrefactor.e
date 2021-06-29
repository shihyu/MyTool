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
#include "cbrowser.sh"
#include "diff.sh"
#include "color.sh"
#import "cidexpr.e"
#import "context.e"
#import "csymbols.e"
#import "help.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "optionsxml.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "refactor.e"
#import "tagrefs.e"
#import "tags.e"
#import "taggui.e"
#import "util.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#endregion


////////////////////////////////////////////////////////////////////////////////
#region Java Organize Imports Options

/**
 * List of Java package prefixes to use to categorize and order imports when 
 * doing auto-import and organize imports.
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default "java;javax;org;com"
 * @categories Configuration_Variables
 */
_str def_jrefactor_prefix_list = "java;javax;org;com";

/**
 * If enabled, support auto import for Java.
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default true 
 * @categories Configuration_Variables
 */
bool def_jrefactor_auto_import = true;
/**
 * If enabled, support auto import for JSP pages (Java embedded
 * in HTML).
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_jrefactor_auto_import_jsp = false;
/**
 * This setting controls the maximum number of classes that will
 * be explicitely imported from a package before auto import or
 * organize imports will collapse the imports into a wildcard
 * import.
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default 10
 * @categories Configuration_Variables
 */
int def_jrefactor_imports_per_package = 10;
/**
 * If enabled, insert blank lines between groups of import
 * statements when doing organize imports in Java code.
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_jrefactor_add_blank_lines=true;
/**
 * If enabled, Java auto import and organize imports will
 * attempt to insert import statements even for classes that
 * start with lower case letters.  By default, this is disabled
 * as a performance and accuracy optimization because, by
 * convention, Java classes use initial caps.
 *
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a>
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_jrefactor_auto_import_lowcase_identifiers = false;

/** 
 * Determines the namespace nesting level at which to add space between using statements. 
 *  
 * <ul> 
 * <li>If set to 0, do not add extra whitespace lines at all.
 *    <pre>
 *       import com.blah.blah;
 *       import java.awt.blah;
 *       import java.awt.event.event1;
 *       import java.awt.event.event2;
 *       import java.util.blah;
 *       import javax.swing.blah1;
 *       import javax.swing.blah2;
 *    </pre>
 * </li>
 * <li>If set to 1, add space if they differ at the first level.
 *    <pre>
 *       import com.blah.blah;
 *       
 *       import java.awt.blah;
 *       import java.awt.event.event1;
 *       import java.awt.event.event2;
 *       import java.util.blah;
 *    
 *       import javax.swing.blah1;
 *       import javax.swing.blah2;
 *    </pre>
 * </li>
 * <li>If set to 2, add space if they differ at the second level.
 *    <pre>
 *       import com.blah.blah;
 *       
 *       import java.awt.blah;
 *       import java.awt.event.event1;
 *       import java.awt.event.event2;
 *       
 *       import java.util.blah;
 *    
 *       import javax.swing.blah1;
 *       import javax.swing.blah2;
 *    </pre>
 * </li>
 * <li>If set to 3, add space if they differ at the third level.
 *    <pre>
 *       import com.blah.blah;
 *       
 *       import java.awt.blah;
 *       
 *       import java.awt.event.event1;
 *       import java.awt.event.event2;
 *       
 *       import java.util.blah;
 *    
 *       import javax.swing.blah1;
 * 
 *       import javax.swing.blah2;   
 *    </pre>
 * </li>
 * </ul>
 *  
 * To modify this setting, go to
 * <a href="help:Java Organize Imports">Document &gt; Java Options... &gt; Organize Imports</a> 
 *  
 * @default 1
 * @categories Configuration_Variables
 */
int def_jrefactor_depth_to_add_space = 1;

#endregion


////////////////////////////////////////////////////////////////////////////////
#region C# Organize Imports Options

/**
 * List of C# namespace prefixes to use to categorize and order
 * imports when doing auto-import and organize imports.
 * 
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a> 
 * 
 * @default "System;Microsoft;Mono;Unity"
 * @categories Configuration_Variables
 */
_str def_csharp_refactor_prefix_list = "System;Microsoft;Mono;Unity";
/**
 * If enabled, support auto add using statements for C#.
 * 
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a> 
 * 
 * @default true 
 * @categories Configuration_Variables
 */
bool def_csharp_refactor_auto_import = true;
/**
 * If enabled, support auto import for ASP pages (C# embedded in HTML).
 *
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a>
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_csharp_refactor_auto_import_asp = false;
/**
 * This setting controls the maximum number of classes that will
 * be explicitely imported from a namespace before auto add using statements 
 * or organize using statements will collapse the statements into a using 
 * namespace statement.
 * 
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a> 
 * 
 * @default 10
 * @categories Configuration_Variables
 */
int def_csharp_refactor_imports_per_package = 10;
/**
 * If enabled, insert blank lines between groups of using
 * statements when doing organize using statements in C# code.
 * 
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a> 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_csharp_refactor_add_blank_lines=true;
/**
 * If enabled, C# auto add using and organize using statements will
 * attempt to insert using statements even for classes that
 * start with lower case letters.  By default, this is disabled
 * as a performance and accuracy optimization because, by convention, 
 * C# classes use initial caps.
 * 
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a> 
 *  
 * @default false
 * @categories Configuration_Variables
 */
bool def_csharp_refactor_auto_import_lowcase_identifiers = false;

/** 
 * Determines the namespace nesting level at which to add space between using statements. 
 *  
 * <ul> 
 * <li>If set to 0, do not add extra whitespace lines at all.
 *    <pre>
 *       using MyCompany.blah;
 *       using System.Collections.blah;
 *       using System.ComponentModel.blah;
 *       using System.Drawing.blah;
 *       using Microsoft.CSharp.blah1;
 *       using Microsoft.CSharp.blah2;
 *    </pre>
 * </li>
 * <li>If set to 1, add space if they differ at the first level.
 *    <pre>
 *       using MyCompany.blah;
 *
 *       using System.Collections.blah;
 *       using System.ComponentModel.blah;
 *       using System.Drawing.blah;
 *
 *       using Microsoft.CSharp.blah1;
 *       using Microsoft.CSharp.blah2;
 *    </pre>
 * </li>
 * <li>If set to 2, add space if they differ at the second level.
 *    <pre>
 *       using MyCompany.blah;
 *
 *       using System.Collections.blah;
 *
 *       using System.ComponentModel.blah;
 *
 *       using System.Drawing.blah;
 *
 *       using Microsoft.CSharp.blah1;
 *       using Microsoft.CSharp.blah2;
 *    </pre>
 * </li>
 * <li>If set to 3, add space if they differ at the third level.
 *    <pre>
 *       using MyCompany.blah;
 *
 *       using System.Collections.blah;
 *
 *       using System.ComponentModel.blah;
 *
 *       using System.Drawing.blah;
 *
 *       using Microsoft.CSharp.blah1;
 *
 *       using Microsoft.CSharp.blah2;
 *    </pre>
 * </li>
 * </ul>
 *  
 * To modify this setting, go to
 * <a href="help:C# Organize Imports">Document &gt; C# Options... &gt; Organize Imports</a>
 *  
 * @default 1
 * @categories Configuration_Variables
*/
int def_csharp_refactor_depth_to_add_space = 1;

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Organize Imports Implementation

static bool tagging_failure = false;

/**
 * Roll all the language-specific auto-import options into this struct.
 */
struct VS_JAVA_AUTO_IMPORT_OPTIONS {
   bool m_auto_import;
   bool m_auto_import_embedded;
   _str m_prefix_list;
   int m_imports_per_package;
   bool m_add_blank_lines;
   bool m_auto_import_lowcase_identifiers;
   bool m_delete_existing_imports;
   int m_depth_to_add_space;
   _str m_import_prefix;
   _str m_wildcard_suffix;
   _str m_project_include_path;
   _str m_system_include_path;
};

struct VS_JAVA_IMPORT_INFO {
   _str m_import_name;
   long m_start_seekpos;
   long m_end_seekpos;
   _str m_import_text;
   _str m_package;
   _str m_file_name;
   bool m_is_used;
   bool m_is_static;
   bool m_is_package;
   bool m_is_include;
   bool m_is_newly_added;
};

/**
 * Get the auto-import settings for the current language, all wrapped up 
 * nicely into a common struct.
 */
static struct VS_JAVA_AUTO_IMPORT_OPTIONS getAutoImportOptions(_str lang=null)
{
   if (lang == null && _isEditorCtl()) {
      lang = p_LangId;
   }
   if (lang == null) {
      return null;
   }

   // Java auto-import?
   VS_JAVA_AUTO_IMPORT_OPTIONS opts;
   if (_LanguageInheritsFrom("java", lang)) {
      opts.m_auto_import = def_jrefactor_auto_import;
      opts.m_auto_import_embedded = def_jrefactor_auto_import_jsp;
      opts.m_prefix_list = def_jrefactor_prefix_list;
      opts.m_imports_per_package = def_jrefactor_imports_per_package;
      opts.m_add_blank_lines = def_jrefactor_add_blank_lines;
      opts.m_auto_import_lowcase_identifiers = def_jrefactor_auto_import_lowcase_identifiers;
      opts.m_delete_existing_imports = true;
      opts.m_depth_to_add_space = def_jrefactor_depth_to_add_space;
      opts.m_import_prefix = "import ";
      opts.m_wildcard_suffix = ".*";
      opts.m_project_include_path = "";
      opts.m_system_include_path = "";
      return opts;
   }

   // C# auto-import?
   if (_LanguageInheritsFrom("cs", lang)) {
      opts.m_auto_import = def_csharp_refactor_auto_import;
      opts.m_auto_import_embedded = def_csharp_refactor_auto_import_asp;
      opts.m_prefix_list = def_csharp_refactor_prefix_list;
      opts.m_imports_per_package = def_csharp_refactor_imports_per_package;
      opts.m_add_blank_lines = def_csharp_refactor_add_blank_lines;
      opts.m_auto_import_lowcase_identifiers = def_csharp_refactor_auto_import_lowcase_identifiers;
      opts.m_delete_existing_imports = true;
      opts.m_depth_to_add_space = def_csharp_refactor_depth_to_add_space;
      opts.m_import_prefix = "using ";
      opts.m_wildcard_suffix = "";
      opts.m_project_include_path = "";
      opts.m_system_include_path = "";
      return opts;
   }

   // Slick-C or C/C++ options
   if (_LanguageInheritsFrom("e", lang) || _LangaugeIsLikeCPP(lang)) {
      opts.m_auto_import = false;
      opts.m_auto_import_embedded = false;
      opts.m_prefix_list = "";
      opts.m_imports_per_package = 1000;
      opts.m_add_blank_lines = false;
      opts.m_auto_import_lowcase_identifiers = true;
      opts.m_delete_existing_imports = false;
      opts.m_depth_to_add_space = 0;
      opts.m_import_prefix = "using ";
      opts.m_wildcard_suffix = "";
      if (_LanguageInheritsFrom("e", lang)) {
         opts.m_prefix_list = ";sc;se;com";
         opts.m_project_include_path = get_env("VSLICKMACROS");
         opts.m_system_include_path = "";
      } else {
         opts.m_prefix_list = ";std;tr1;boost;Qt";
         opts.m_project_include_path = get_cpp_project_include_path(1);
         opts.m_system_include_path  = get_cpp_system_include_path(1);
      }
      return opts;
   }

   // C# or Java embedded in HTML?
   if (_LanguageInheritsFrom("html", lang) || _LanguageInheritsFrom("xml", lang)) {
      if (_isEditorCtl()) {
         if (strieq(p_EmbeddedLexerName, "java") && def_jrefactor_auto_import_jsp) {
            return getAutoImportOptions("java");
         }
         if (strieq(p_EmbeddedLexerName, "csharp") && def_csharp_refactor_auto_import_asp) {
            return getAutoImportOptions("csharp");
         }
      }
   }

   // Not in a support language mode
   return null;
}

static bool _LangaugeIsLikeCPP(_str lang=null)
{
   if (_isEditorCtl() && lang == null) {
      lang = p_LangId;
   }
   switch (lang) {
   case "c":
   case "ansic":
   case "ch":
   case "m":
      return true;
   default:
      if (_isEditorCtl() && _LanguageInheritsFrom("c", lang)) {
         switch (lowcase(p_lexer_name)) {
         case "ansi c++":
         case "ansic":
         case "c":
         case "ch":
         case "cpp":
         case "objective-c":
         case "slick-c":
            return true;
         }
      }
      return false;
   }
}

static _str get_cpp_project_include_path(int depth=0)
{
   if (_chdebug) {
      isay(depth, "get_cpp_project_include_path H"__LINE__": IN");
   }
   all_includes := "";
   if (_isEditorCtl()) {
      all_includes = _strip_filename(p_buf_name, 'N');
   }
   if (_project_name == "") {
      return all_includes;
   }

   // get project include path for projects which include this file
   if (_isEditorCtl()) {
      allProjectFiles := _WorkspaceFindAllProjectsWithFile(p_buf_name, _workspace_filename, true);
      foreach (auto projectFileName in allProjectFiles) {
         info := _ProjectGet_IncludesList(_ProjectHandle(projectFileName), _project_get_section(gActiveConfigName));
         info = _absolute_includedirs(info, projectFileName);
         if (info != "") {
            _maybe_append(all_includes, PATHSEP);
            all_includes :+= info;
         }
      }
   }
   // get project include path
   project_includes := _ProjectGet_IncludesList(_ProjectHandle(_project_name));
   project_includes  = _absolute_includedirs(project_includes, _project_get_filename());
   if (project_includes != "") {
      _maybe_append(all_includes, PATHSEP);
      all_includes :+= project_includes;
   }

   // remove duplicates from the include paths
   split(all_includes, PATHSEP, auto array_of_includes);
   bool found_include:[];
   all_includes = "";
   foreach (auto include_dir in array_of_includes) {
      if (include_dir == "") continue;
      if (found_include._indexin(_file_case(include_dir))) {
         continue;
      }
      found_include:[_file_case(include_dir)] = true;
      _maybe_append(all_includes, PATHSEP);
      all_includes :+= include_dir;
      if (_chdebug) {
         isay(depth+1, "get_cpp_project_include_path H"__LINE__": dir="include_dir);
      }
   }

   return all_includes;
}

static _str get_cpp_system_include_path(int depth=0)
{
   if (_chdebug) {
      isay(depth, "get_cpp_system_include_path H"__LINE__": IN");
   }
   all_includes := "";
   if (_project_name != "") {
      // get system include path
      system_includes := _ProjectGet_SysIncludesList(_ProjectHandle(_project_name));
      system_includes  = _absolute_includedirs(system_includes, _project_get_filename());
      if (system_includes != "") {
         _maybe_append(all_includes, PATHSEP);
         all_includes :+= system_includes;
      }

      // get compiler configuration include path
      system_includes = _ProjectGet_SystemIncludes(_ProjectHandle(_project_name));
      system_includes = _absolute_includedirs(system_includes, _project_get_filename());
      if (system_includes != "") {
         _maybe_append(all_includes, PATHSEP);
         all_includes :+= system_includes;
      }
   } else if (_isUnix()) {
      // no project, unix, try /usr/include, obvious stuff
      _maybe_append(all_includes, PATHSEP);
      all_includes :+= "/usr/include";
      _maybe_append(all_includes, PATHSEP);
      all_includes :+= "/usr/include/X11";
   }

   // remove duplicates from the include paths
   split(all_includes, PATHSEP, auto array_of_includes);
   bool found_include:[];
   all_includes = "";
   foreach (auto include_dir in array_of_includes) {
      if (include_dir == "") continue;
      if (found_include._indexin(_file_case(include_dir))) {
         continue;
      }
      found_include:[_file_case(include_dir)] = true;
      _maybe_append(all_includes, PATHSEP);
      all_includes :+= include_dir;
      if (_chdebug) {
         isay(depth+1, "get_cpp_system_include_path H"__LINE__": dir="include_dir);
      }
   }

   return all_includes;
}

/**
 * @return 
 * Returns 'true' if the given symbol is a valid identifier for the 
 * current language. 
 * 
 * @param symbol    identifier name to check
 */
static bool is_valid_identifier(_str symbol) 
{
   ch := substr(symbol, 1, 1);
   if (isalpha(ch) || ch == '_') {
         return true;
   } 
   return false;
}

/**
 * @return 
 * Returns the current package or namespace name for the current buffer. 
 *  
 * @param start_of_package_pos   (output) set to the seek position of 
 *                               the start of the package found 
 * @param end_of_package_pos     (output) set to the seek position of 
 *                               the end of the package found 
 */
static _str get_package_name_for_current_buffer(long &start_of_package_pos, 
                                                long &end_of_package_pos,
                                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   current_seekpos := _QROffset();
   start_of_package_pos = 0L;
   end_of_package_pos = 0L;
   package_name := "";

   // Always try to put imports at the top of the file in C#
   if (_LanguageInheritsFrom("cs")) {
      return "";
   }
   if (_LanguageInheritsFrom("e") || _LangaugeIsLikeCPP()) {
      return "";
   }

   // Get the package name for this file.
   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;
   tag_push_matches();
   tag_list_in_file(0,0,
                    "", null,
                    _strip_filename(p_buf_name,'P'),
                    SE_TAG_FILTER_PACKAGE,SE_TAG_CONTEXT_ANYTHING,
                    num_matches,max_matches,
                    false,true,
                    visited, depth+1);

   // first iterate through looking for enclosing package name
   check_seekpos := true;
   loop {
      for (i:=1; i <= num_matches; i++) {
         tag_get_match_browse_info(i, auto cm);

         // check if we are in the right file and seek position range
         if (!file_eq(cm.file_name, p_buf_name)) {
            continue;
         }
         if (check_seekpos && cm.seekpos >= 0 && cm.end_seekpos >= 0) {
            if (cm.seekpos > current_seekpos || cm.end_seekpos < current_seekpos) {
               continue;
            }
         }

         // is this package more specified than the previous one we found?
         if (cm.class_name != "") {
            temp_pkg :=  cm.class_name :+ VS_TAGSEPARATOR_package :+ cm.member_name;
            if (length(temp_pkg) > length(package_name)) {
               package_name = temp_pkg;
            } else {
               continue;
            }
         } else {
            if (length(cm.member_name) > length(package_name)) {
               package_name = cm.member_name;
            } else {
               continue;
            }
         }

         // Go to first end of line character after package.
         start_of_package_pos = cm.seekpos;
         end_of_package_pos = cm.scope_seekpos;
         _save_pos2(auto orig_pos);
         _GoToROffset(end_of_package_pos);

         // Get seek position after the package name newline
         down();
         begin_line();
         end_of_package_pos = _QROffset();

         _restore_pos2(orig_pos);
      }

      // if we did not find it, try ignoring the seek position check
      if (!check_seekpos) break;
      check_seekpos=false;
   }

   tag_pop_matches();
   return package_name;
}

/**
 * @return 
 * Return the seek position of the start of the line below the line containing 
 * the given seek position.  This effectively adjust the incoming seek position 
 * to encompase any trailing line commment. 
 * 
 * @param seekpos     Seek position of import statement
 */
static long find_line_comment(long seekpos)
{
   // Support multiline line comments that are indented the same amount?
   _save_pos2(auto orig_pos);
   _GoToROffset(seekpos);

   down();
   begin_line();
   seekpos = _QROffset()-1;

   _restore_pos2(orig_pos);
   return seekpos;
}

/**
 * Extract the existing import statements from the current file and file away 
 * all the information about them.  This will both create a hash table of the 
 * import statements as well as an array of the import statements which can 
 * be used to keep track of import statement order. 
 * 
 * @param existingImports     (output) array of import statements found in current file
 * @param import_hash         (output) hash table of import statement information
 * @param min_seek_position   (output) where the import statements start
 * @param max_seek_position   (output) where the import statemetns end
 */
void java_get_existing_imports(_str (&existingImports)[], 
                               struct VS_JAVA_IMPORT_INFO (&import_hash):[], 
                               long &min_seek_position, 
                               long &max_seek_position,
                               _str (&tag_files)[], 
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // get the auto-import options
   auto_import_opts := getAutoImportOptions();
   if (auto_import_opts == null) {
      _message_box("Organize Imports: not supported in this context");
      return;
   }

   get_existing_imports(existingImports, import_hash, 
                        min_seek_position, max_seek_position, 
                        auto_import_opts, 
                        tag_files, visited, depth+1);
}

/**
 * Extract the existing import statements from the current file and file away 
 * all the information about them.  This will both create a hash table of the 
 * import statements as well as an array of the import statements which can 
 * be used to keep track of import statement order. 
 * 
 * @param existingImports     (output) array of import statements found in current file
 * @param import_hash         (output) hash table of import statement information
 * @param min_seek_position   (output) where the import statements start
 * @param max_seek_position   (output) where the import statemetns end
 */
static void get_existing_imports(_str (&existingImports)[], 
                                 struct VS_JAVA_IMPORT_INFO (&import_hash):[], 
                                 long &min_seek_position, 
                                 long &max_seek_position,
                                 struct VS_JAVA_AUTO_IMPORT_OPTIONS auto_import_opts,
                                 _str (&tag_files)[], 
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   min_seek_position = MAXINT;
   max_seek_position = 0;

   // Save current cursor position
   _save_pos2(auto cursorSeekPos);

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // Get all import statements.
   tag_push_matches();

   // Pass in null for tagfiles so the current context is checked. This is in the case where
   // some imports may have been removed, changed but have not been saved yet.
   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;
   tag_list_globals_of_type(0, 0, null, 
                            SE_TAG_TYPE_IMPORT, 
                            0, 0, 
                            num_matches, max_matches,
                            visited, depth+1);

   // get the #include and #import statements for C++ or Slick-C or Objective-C
   if (_LanguageInheritsFrom("e") || _LangaugeIsLikeCPP()) {
      tag_list_globals_of_type(0, 0, null, 
                               SE_TAG_TYPE_INCLUDE, 
                               0, 0, 
                               num_matches, max_matches,
                               visited, depth+1);
   }

   // Pick out all import statements that are in the current buffer.
   num_matches = tag_get_num_of_matches();
   if (_chdebug) {
      isay(depth, "get_existing_imports H"__LINE__": FOUND "num_matches" IMPORTs OR INCLUDEs");
   }
   for (i := 1; i <= num_matches; i++) {
      tag_get_match_browse_info(i, auto cm);
      if (!file_eq(cm.file_name, p_buf_name)) {
         continue;
      }
      if (_chdebug) {
         isay(depth, "get_existing_imports H"__LINE__": FOUND IMPORT OR INCLUDE name="cm.member_name" line="cm.line_no);
      }

      // we may need to refine the import name, especially for #includes
      import_name := cm.member_name;
      if (_first_char(import_name) == '"' || _first_char(import_name) == "'") {
         import_name = substr(import_name, 2, length(import_name)-2);
      } else if (_first_char(import_name) == '<') {
         parse import_name with '<' import_name '>';
      }

      // C++ tagging can be a bit strange here
      if (cm.type_name == "import" && cm.return_type != "" && pos("::", cm.return_type)) {
         import_name = cm.return_type;
         import_name = stranslate(import_name, ".", "::");
      }

      // Store information about each import statement.
      struct VS_JAVA_IMPORT_INFO import_info;
      import_info.m_import_name   = import_name;
      import_info.m_start_seekpos = cm.seekpos;
      import_info.m_end_seekpos   = cm.end_seekpos;
      import_info.m_package = null;
      import_info.m_file_name = "";
      import_info.m_is_used = false;
      import_info.m_is_static = false;
      import_info.m_is_package = false;
      import_info.m_is_newly_added = false;

      // Adjust end seek position to encompass any trailing line comment for this import
      import_info.m_end_seekpos = find_line_comment(import_info.m_end_seekpos);

      // Embedded Java (JSP). Want to grab the leading <% of the existing import that is not contained
      // by the tag start_seekpos so subtract two from the start seekpos. The adjustment of end seek position
      // for the trailing %> should be taken care of by find_line_comment
      if (strieq(p_EmbeddedLexerName, 'java')) {
         import_info.m_start_seekpos -=2;
      }

      // Grab import text
      import_info.m_import_text = get_text((int)(import_info.m_end_seekpos-import_info.m_start_seekpos+1), import_info.m_start_seekpos);

      // parse out the import name
      rest := "";
      if (_first_char(import_info.m_import_text) == '#') {
         parse import_info.m_import_text with "#" auto import_or_include_or_require rest;
         rest = strip(rest);
         if (_first_char(rest) == '<') {
            parse rest with '<' rest '>';
         } else if (_first_char(rest) == "'") {
            parse rest with "'" rest "'";
         } else {
            parse rest with '"' rest '"';
         }
         import_info.m_is_include = true;
      } else {
         if (beginsWith(strip(import_info.m_import_text), auto_import_opts.m_import_prefix)) {
            rest = strip(substr(strip(import_info.m_import_text), length(auto_import_opts.m_import_prefix)+1));
         }
      }

      // Check for static import
      temp := strip(rest);
      if (pos("static ", temp) == 1){
         // Leave static imports alone...for now
         import_info.m_is_static = true;
         import_info.m_is_used = true;
         parse rest with "static" rest;
      } else if (pos("namespace ", temp) == 1){
         import_name = stranslate(cm.member_name, ".", "::");
         import_info.m_is_static = false;
         import_info.m_is_package = true;
         parse rest with "namespace" rest;
      } else {
         import_info.m_is_static = false;
      }

      // check if this is a package or namespace import
      maybe_package := strip(rest, 'B', " \t\r\n");
      parse maybe_package with maybe_package ';';
      maybe_package = strip(maybe_package);
      maybe_package = stranslate(maybe_package, VS_TAGSEPARATOR_package, '::');
      maybe_package = stranslate(maybe_package, VS_TAGSEPARATOR_package, '.');
      _maybe_strip(maybe_package, ".*");
      aliased_to := "";
      if (_first_char(strip(import_info.m_import_text)) == '#') {
         import_info.m_is_include = true;
         import_info.m_file_name = _maybe_unquote_filename(rest);
         import_info.m_package   = "";
         if (_first_char(import_info.m_file_name) == '<') {
            parse import_info.m_file_name with '<' import_info.m_file_name '>';
         }
         last_sep := lastpos('/', import_info.m_file_name);
         if (last_sep > 0) {
            import_info.m_package = substr(import_info.m_file_name, 1, last_sep-1);
         }
      }
      if (!import_info.m_is_package && !import_info.m_is_include) {
         if (_chdebug) {
            isay(depth, "get_existing_imports H"__LINE__": maybe_package="maybe_package);
         }
         if (tag_check_for_package(maybe_package, tag_files, true, true, aliased_to, visited, depth+1) > 0) {
            if (_chdebug) {
               isay(depth, "get_existing_imports H"__LINE__": have package="maybe_package" aliased_to="aliased_to);
            }
            if (aliased_to == "") {
               import_info.m_is_package = true;
               import_info.m_package = maybe_package;
            }
         } else {
            last_sep := lastpos(VS_TAGSEPARATOR_package, maybe_package);
            if (last_sep > 0) {
               maybe_package = substr(maybe_package, 1, last_sep-1);
               if (tag_check_for_package(maybe_package, tag_files, true, true, aliased_to, visited, depth+1) > 0) {
                  if (_chdebug) {
                     isay(depth, "get_existing_imports H"__LINE__": have package="maybe_package" aliased_to="aliased_to);
                  }
                  if (aliased_to == "") {
                     import_info.m_is_package = false;
                     import_info.m_package = maybe_package;
                  }
               }
            }
         }
      }

      // Get bounds of import information.
      if (import_info.m_start_seekpos < min_seek_position) {
         min_seek_position = import_info.m_start_seekpos;
      }

      if (import_info.m_end_seekpos > max_seek_position) {
         max_seek_position = import_info.m_end_seekpos;
      }

      existingImports :+= import_info.m_import_name;
      import_hash:[import_info.m_import_name] = import_info;
   }

   if (_chdebug) {
      idump(depth+1, existingImports, "get_existing_imports H"__LINE__": existingImports");
      idump(depth+1, import_hash,     "get_existing_imports H"__LINE__": import_hash");
   }

   tag_pop_matches();
   _restore_pos2(cursorSeekPos);
}

/**
 * Does this import exist in the list of imports passed in? 
 *  
 * @param import_name      name of import to check for 
 * @param imports          list of imported symbols 
 * @param import_hash      hash table of import statements (hashed on import name)
 */
static bool import_exists(_str import_name, 
                          _str (&imports)[], 
                          struct VS_JAVA_IMPORT_INFO (&import_hash):[],
                          int depth)
{
   if (_chdebug) {
      isay(depth, "import_exists H"__LINE__": import_name="import_name);
   }
   if (import_hash._indexin(import_name) && import_hash:[import_name] != null) {
      import_hash:[import_name].m_is_used = true;
      if (_chdebug) {
         isay(depth, "import_exists H"__LINE__": IMPORT IS IN HASH TABLE");
      }
      return true;
   }
   // TBF:  This should not be necessary
   for (i := 0; i < imports._length(); i++) {
      if (import_name == imports[i]) {
         // This import is used by at least one reference in the file.
         import_hash:[import_name].m_is_used = true;
         if (_chdebug) {
            isay(depth, "import_exists H"__LINE__": IMPORT IS IN ARRAY");
         }
         return true;
      }
   }
   if (_chdebug) {
      isay(depth, "import_exists H"__LINE__": IMPORT WAS NOT FOUND");
   }
   return false;
}

/**
 * This function compares two packages and see on how many package levels that 
 * they match from left to right until a nonmatching level is found.
 * 
 * @param package1      first package name
 * @param package2      second package name
 * 
 * @return 
 * Returns the match level, that is how many parts of the prefix match. 
 * 0 indicates that they do not match at all.  1 indicates that only the 
 * top-level package name matches.  MAXINT indicates that package1 and 
 * package2 are identical. 
 */
static int levels_of_equality(_str package1, _str package2) 
{
   _str package1_array[];
   _str package2_array[];
   if (pos(VS_TAGSEPARATOR_package, package1)) {
      split(package1, VS_TAGSEPARATOR_package, package1_array);
   } else {
      split(package1, '.', package1_array);
   }
   if (pos(VS_TAGSEPARATOR_package, package2)) {
      split(package2, VS_TAGSEPARATOR_package, package2_array);
   } else {
      split(package2, '.', package2_array);
   }

   smallest := min(package1_array._length(), package2_array._length());
   for (level := 0; level < smallest; level++) {
      if (package1_array[level] != package2_array[level]) {
          break;
      }
   }

   if (level == smallest && package1 == package2) {
      level = MAXINT;
   }
   return level;
}

/**
 * Update the imports in the current file.
 * 
 * @param imports                     list of existing imports in the current file, in order
 * @param import_hash                 hash table of existing imports in the current file
 * @param min_seek_position           start seek position of imports section
 * @param max_seek_position           end seek position of imports section
 * @param end_of_package_name_pos     position of the end of package statement
 * @param doing_full_file             doing the whole file, or just current symbol?
 * @param unmatched_symbols           symbols which were not imported
 */
static void update_imports(_str (&imports)[],  
                           struct VS_JAVA_IMPORT_INFO (&import_hash):[],
                           struct VS_JAVA_AUTO_IMPORT_OPTIONS auto_import_opts,
                           long min_seek_position, 
                           long max_seek_position, 
                           long end_of_package_name_pos, 
                           bool doing_full_file,
                           _str unmatched_symbols[] = null,
                           int depth=0)
{
   if (_chdebug) {
      isay(depth, "update_imports H"__LINE__": IN");
      idump(depth+1, imports, "update_imports H"__LINE__": imports");
      foreach (auto key => . in import_hash) {
         isay(depth+1, "update_imports H"__LINE__": import_hash:["key"]");
      }
   }
   file_eol := p_newline;
   int num_imports_per_package:[];

   // Sort the list into alphabetical order
   imports._sort('i');

   // for Slick-C, we want to move using statements 
   // to the bottom of the list and move includes to the top of the list
   if (_LanguageInheritsFrom("e")) {
      _str all_includes[];
      _str all_imports[];
      _str all_using[];
      foreach (auto import_name in imports) {
         if (endsWith(import_name, ".sh")) {
            all_includes :+= import_name;
         } else if (endsWith(import_name, ".e")) {
            all_imports  :+= import_name;
         } else {
            all_using    :+= import_name;
         }
      }
      imports._makeempty();
      foreach (import_name in all_includes) {
         imports :+= import_name;
      }
      foreach (import_name in all_imports) {
         imports :+= import_name;
      }
      foreach (import_name in all_using) {
         imports :+= import_name;
      }
      if (_chdebug) {
         isay(depth, "update_imports H"__LINE__": AFTER SORTING SLICK-C IMPORTS");
         idump(depth+1, imports, "update_imports H"__LINE__": imports");
      }
   }

   // Count how many import statements per package.
   // Save package name in import info.
   if (_chdebug) {
      isay(depth, "update_imports H"__LINE__": COUNTING IMPORTS PER PACKAGE");
   }
   struct VS_JAVA_IMPORT_INFO import_info;   
   unused_import_and_tagging_failure := false;
   collapsing_wildcard_import := false;
   foreach (auto import_name in imports) {

      // If the whole file has been processed and the import
      // is not being used by any symbol then get rid of it.
      import_info = import_hash:[import_name];
      if (doing_full_file && import_hash._indexin(import_name) && import_info.m_is_used == false) {
         if (tagging_failure == false) {
            continue;
         } else {
            unused_import_and_tagging_failure = true;
         }
      }

      last_dot := lastpos('.', import_name);
      if (last_dot > 0) {
         package := substr(import_name, 1, last_dot-1);
         if (import_hash._indexin(import_name) && import_info.m_is_package && import_info.m_package != null) {
            package = import_info.m_package;
         }

         if (!num_imports_per_package._indexin(package)) {
            num_imports_per_package:[package] = 1;
         } else {
            num_imports_per_package:[package]++;
            if (num_imports_per_package:[package] > auto_import_opts.m_imports_per_package) {
               collapsing_wildcard_import = true;
            }
         }

         if (import_hash._indexin(import_name)) {
            import_hash:[import_name].m_package = package;
         }
         if (_chdebug) {
            isay(depth, "update_imports H"__LINE__": import_name="import_name" package="package);
         }
      } else if (import_hash._indexin(import_name) && 
                 (import_info.m_is_package || import_info.m_is_include)&& 
                  import_hash:[import_name].m_package != null) {
         package := import_hash:[import_name].m_package;
         if (_chdebug) {
            isay(depth, "update_imports H"__LINE__": import_name="import_name" package="package);
         }
         if (!num_imports_per_package._indexin(package)) {
            num_imports_per_package:[package] = 1;
         } else {
            num_imports_per_package:[package]++;
            if (num_imports_per_package:[package] > auto_import_opts.m_imports_per_package) {
               collapsing_wildcard_import = true;
            }
         }
      } else {
         if (_chdebug) {
            isay(depth, "update_imports H"__LINE__": import_name="import_name" NOT FOUND");
         }
      }
   }
   if (_chdebug) {
      idump(depth+1, num_imports_per_package, "update_imports H"__LINE__": num_imports_per_package");
   }

   keep_unused := false;
   if (unused_import_and_tagging_failure == true) {
      msg := "Organize Imports: Not deleting unused imports because it could not find some symbols:\n\n";
      foreach (auto x in unmatched_symbols) {
         msg :+= '   ' :+ x :+ "\n";
      }
      _message_box(msg);
      keep_unused = true;
   }

   // no unused imports and we are just adding an import, 
   // so just add the one import without reorganizing anything
   if (!doing_full_file && !collapsing_wildcard_import) {
      if (_chdebug) {
         isay(depth, "update_imports H"__LINE__": ADDING AN IMPORT AND NO NEW WILDCARDS, TRY TO PRESERVE EXISTING IMPORTS");
      }
      auto_import_opts.m_delete_existing_imports = false;
   }

   // Add temporary line between imports and rest of file to prevent
   // a problem with restoring the seek position when trying to add an 
   // import that is immediately below the deleted set of imports.
   // Delete this line after inserting organized set of imports.
   _GoToROffset(max_seek_position);

   // Only insert line if their is not one already.
   added_line := false;
   if (max_seek_position!= 0) {
      down();
      get_line(auto line);
      up();
      if (line!="") {
         insert_line("");
         added_line=true;
      }
   }

   // Delete old imports if any
   if (min_seek_position != MAXINT && auto_import_opts.m_delete_existing_imports) {
      _GoToROffset(min_seek_position);
      if (max_seek_position > min_seek_position) {
         _delete_text(max_seek_position-min_seek_position+1);
      }
      if (_chdebug) {
         isay(depth+1, "update_imports H"__LINE__": REMOVED IMPORTS AT: "min_seek_position" new position="_QROffset());
      }
   } else {
      _GoToROffset(end_of_package_name_pos);
      if (_chdebug) {
         isay(depth+1, "update_imports H"__LINE__": MOVING TO END OF PACKAGE SEEKPOS: "end_of_package_name_pos);
      }
   }

   // Build import prefix array from def var.
   split(auto_import_opts.m_prefix_list, ';', auto import_prefixes);
   if (import_prefixes._length() == 0) import_prefixes :+= "";
   if (_chdebug) {
      idump(depth+1, import_prefixes, "update_imports H"__LINE__": import_prefixes");
   }

   // Go through imports and see if they match any of the user
   // defined prefixes. If so then stick them in the matching prefix slot.
   _str prefixes[][];
   foreach (import_name in imports) {
      if (!import_hash._indexin(import_name)) {
         if (_chdebug) {
            isay(depth+1, "update_imports H"__LINE__": SKIPPING MISSING IMPORT INFO (SHOULD NEVER HAPPEN): "import_name);
         }
         continue;
      }
      import_info = import_hash:[import_name];
      if (_chdebug) {
         isay(depth+1, "update_imports H"__LINE__": COMPUTING PREFIXES, import_name="import_name);
         idump(depth+2, import_info, "update_imports H"__LINE__": import_info");
      }
      if (import_info == null) {
         if (_chdebug) {
            isay(depth+1, "update_imports H"__LINE__": SKIPPING NULL IMPORT (SHOULD NEVER HAPPEN): "import_name);
         }
         continue;
      }

      // If the whole file has
      // import_info.m_is_in = true; been processed and the import
      // is not being used by any symbol then get rid of it.
      if (doing_full_file &&
          import_hash._indexin(import_name) && 
          import_info.m_is_used == false && 
          unused_import_and_tagging_failure == false && 
          !keep_unused) {
          if (_chdebug) {
             isay(depth+1, "update_imports H"__LINE__": UNUSED IMPORT: "import_name);
          }
          continue;
      }

      // Don't add existing imports with *'s in them when doing organize imports. 
      // Keep them if just adding...  Unless it's unused and we have already 
      // determined we need to keep unused imports.
      if (doing_full_file && 
          (pos("*", import_info.m_import_text) != 0 /*|| import_info.m_is_package*/) && 
          import_info.m_is_static == false && 
          ((import_info.m_is_used == true) || (import_info.m_is_used == false && !keep_unused))) {
           if (_chdebug) {
              isay(depth+1, "update_imports H"__LINE__": SKIPPING WILDCARD IMPORT import_name="import_name);
           }
           continue;
      }

      // See what prefix this import matches and stick the import into this prefix list.
      index_of_empty_prefix := -1;
      for (j:=0; j < import_prefixes._length(); j++) {
         p := import_prefixes[j];
         if (length(p) <= 0) {
            index_of_empty_prefix = j;
            continue;
         }
         sub := substr(import_name, 1, length(p));
         nch := substr(import_name, length(p)+1, 1, '.');
         if (sub == p && pos(nch, ".:/")) {
            if (!import_info.m_is_include) {
               j = j+import_prefixes._length()+1;
            }
            prefixes[j] :+= import_name;
            index_of_empty_prefix = -1;
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": adding "import_name" to prefix "p" index="j);
            }
            break;
         }
      }

      // Does not match any prefix. Stick in last prefix slot, unless we
      // now have a prefix slot for empty prefixes
      if (j == import_prefixes._length()) {
         if (index_of_empty_prefix >= 0 && (import_info.m_is_include || !pos("[.:/]", import_name, 1, 'r'))) {
            prefixes[index_of_empty_prefix] :+= import_name;
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": adding "import_name" to empty prefix index="index_of_empty_prefix);
            }
         } else {
            if (!import_info.m_is_include) {
               j = j+import_prefixes._length()+1;
            }
            prefixes[j] :+= import_name;
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": adding "import_name" to new prefix group at "j);
            }
         }
      }
   }

   if (_chdebug) {
      idump(depth+1, prefixes, "update_imports H"__LINE__": prefixes");
   }

   num_bytes_added := 0;
   previous_package := "";
   for (i := 0; i < prefixes._length(); i++) {
      if (_chdebug && i < import_prefixes._length()) {
         isay(depth, "update_imports H"__LINE__": import_prefix="import_prefixes[i]);
      }

      // imports in same package
      foreach (auto p in prefixes[i]) {
         if (!import_hash._indexin(p)) continue;
         import_info = import_hash:[p];
         if (_chdebug) {
            idump(depth+1, import_info, "update_imports H"__LINE__": import_info");
         }
         if (import_info == null) {
            isay(depth+1, "update_imports H"__LINE__": NO IMPORT INFO FOR prefix "p);
            continue;
         }
         if (!import_info.m_is_include) {
            if (_chdebug && import_info.m_package != null) {
               isay(depth+1, "update_imports H"__LINE__": import_info.m_package="import_info.m_package);
            }
            if (import_info.m_package == null || import_info.m_package == "") {
               if (_chdebug) {
                  isay(depth+1, "update_imports H"__LINE__": IMPORT HAS NO PACKAGE NAME");
               }
               continue;
            }
         }

         // if we are not deleting all imports and re-organizing, then only add new imports
         if (!auto_import_opts.m_delete_existing_imports && !import_info.m_is_newly_added) {
            if (import_info.m_end_seekpos+num_bytes_added > _QROffset()) {
               _GoToROffset(import_info.m_end_seekpos+num_bytes_added);
               down();
               _begin_line();
            }
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": LEAVING OLD IMPORT next offset="_QROffset());
            }
            continue;
         }

         if (auto_import_opts.m_add_blank_lines && 
             previous_package != "" && 
             levels_of_equality(previous_package, import_info.m_package) < auto_import_opts.m_depth_to_add_space) {
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": ADDING BLANK LINE, package="import_info.m_package);
               isay(depth+1, "update_imports H"__LINE__": ADDING BLANK LINE, previous="previous_package);
               isay(depth+1, "update_imports H"__LINE__": ADDING BLANK LINE, level of equality="levels_of_equality(previous_package, import_info.m_package));
               isay(depth+1, "update_imports H"__LINE__": ADDING BLANK LINE, depth option="auto_import_opts.m_depth_to_add_space);
            }
            _insert_text(file_eol, false, p_newline);
            num_bytes_added += length(file_eol) + length(p_newline);
         }
         previous_package = import_info.m_package;
   
         // Insert wildcard import if exceeded import limit for this package.
         if (num_imports_per_package._indexin(import_info.m_package) && num_imports_per_package:[import_info.m_package] > auto_import_opts.m_imports_per_package) {
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": inserting wildcard package for"import_info.m_package);
            }
            // Insert wildcard import
            // 
            // Embedded Java(JSP?) If so then write out import in JSP format
            import_hash:[p].m_start_seekpos = _QROffset();
            if (strieq(p_EmbeddedLexerName,'java') || strieq(p_EmbeddedLexerName, "csharp")) {
               jsp_import_text := "<%@ page import=\"" :+ import_info.m_package :+ '.*' :+ "\"%>" :+ file_eol;
               _insert_text(jsp_import_text, false, p_newline);    
            } else {
               imp_prefix := auto_import_opts.m_import_prefix;
               imp_suffix := auto_import_opts.m_wildcard_suffix;
               if (import_info.m_is_static) {
                  imp_prefix :+= "static ";
                  imp_suffix = "";
               }
               import_statement_text := imp_prefix :+ import_info.m_package :+ imp_suffix :+ ";" :+ file_eol;
               _insert_text(import_statement_text, false, p_newline);
            }
            import_hash:[p].m_end_seekpos = _QROffset();
            num_bytes_added += (import_hash:[p].m_end_seekpos - import_hash:[p].m_start_seekpos);
 
            // Zero out num imports to indicate that the wildcard import has been inserted
            // and all subsequent explicit imports using this package should be ignored.
            num_imports_per_package:[import_info.m_package] = 0;
         } else if (num_imports_per_package._indexin(import_info.m_package) && num_imports_per_package:[import_info.m_package] != 0) {
            if (_chdebug) {
               isay(depth+1, "update_imports H"__LINE__": inserting regular import for "import_info.m_package" at seekpos "_QROffset());
            }
            import_hash:[p].m_start_seekpos = _QROffset();
            _insert_text(import_info.m_import_text,false, p_newline);
            import_hash:[p].m_end_seekpos = _QROffset();
            num_bytes_added += (import_hash:[p].m_end_seekpos - import_hash:[p].m_start_seekpos);
         }
      }
   }
   // Delete line created after original imports.
   if (added_line) {
      _delete_line();
   }
   if (_chdebug) {
      isay(depth, "update_imports H"__LINE__": OUT");
   }
}

/**
 * Find the import name for the symbol under the cursor. 
 * Get rid of any matches that we know cannot be valid. 
 * 
 * @param this_file_package_name    current package we are working on
 * @param symbol_type_name          (output) symbol type name found
 * @param found_matching_symbol     (output) did we find a matching symbol?
 * @param symbol_name               symbol name to look for
 * @param all_choices               all choices found
 * @param quiet                     if true, fail quietly, do not pop up a message box
 * @param final_find                final attempt?
 * @param import_hash               hash table of import statements in this file
 * @param cur_sym                   current symbol information
 * 
 * @return Returns the name of the matching import statement if found. 
 *         Otherwise returns an empty string.
 */
static _str find_import_name(_str this_file_package_name, 
                             _str &symbol_type_name, 
                             _str &symbol_file_name, 
                             bool &found_matching_symbol, 
                             _str symbol_name, 
                             struct VS_TAG_BROWSE_INFO (&all_choices)[], 
                             bool quiet, 
                             bool final_find, 
                             struct VS_JAVA_IMPORT_INFO (&import_hash):[],
                             VS_TAG_BROWSE_INFO &cur_sym,
                             _str (&tag_files)[], 
                             VS_TAG_RETURN_TYPE (&visited):[],
                             int depth)
{
   if (_chdebug) {
      isay(depth, "find_import_name H"__LINE__": IN symbol_name="symbol_name);
   }

   import_name := "";
   symbol_type_name = "";
   symbol_file_name = "";
   found_matching_symbol = false; // Found a symbol that exactly matches the symbol under the cursor?

   in_java_lang_package := false;
   in_same_package := false;
   not_visible := false;

   VS_TAG_BROWSE_INFO duplicate_hash:[]=null;
   VS_TAG_BROWSE_INFO refined_choices[]=null;

   // Throw out any choices that do not exactly match the symbol under the cursor, 
   // choices that are not classes, are of the same package as this file or are 
   // not members of the java.lang package
   //
   foreach (auto cm in all_choices) {

      // Make sure the language matches
      choice_language := cm.language;
      if (choice_language == "") {
         choice_language = _Filename2LangId(cm.file_name);
      }
      if (choice_language == "class") choice_language = "java";
      if (choice_language == "jar")   choice_language = "java";
      if (choice_language == "jmod")  choice_language = "java";
      if (choice_language == "obj")   choice_language = "cs";
      if (choice_language == "dll")   choice_language = "cs";
      if (choice_language != "" && choice_language != "dll" && choice_language != p_LangId) {
         if (_chdebug) {
            isay(depth, "find_import_name: SKIP, WRONG LANGUAGE: "choice_language);
         }
         continue;
      }

      if (symbol_name != cm.member_name) {
         if (_chdebug) {
            isay(depth, "find_import_name: SKIP, SYMBOL NAME DOES NOT MATCH: "cm.member_name);
         }
         continue;
      }

      found_matching_symbol = true;
      last_slash_pos := lastpos("/", cm.class_name);
      pack := "";
      if (last_slash_pos > 0 && !tag_tree_type_is_class(cm.type_name)) {
         pack = substr(cm.class_name, 1, last_slash_pos-1);
      } else {
         pack = cm.class_name;
         if (_chdebug) {
            say("find_import_name H"__LINE__": pack="pack);
         }
         tag_split_class_name(cm.class_name, auto inner_name, auto outer_name);
         if (_LanguageInheritsFrom("java", choice_language) &&
             tag_check_for_class(inner_name, outer_name, case_sensitive:true, tag_files, visited, depth+1)) {
            if (_chdebug) {
               say("find_import_name H"__LINE__": trying to import class in default package");
            }
            continue;
         }
      }

      // Don't include choices that are from the java.lang package since it is
      // always imported implicitly.
      if (_LanguageInheritsFrom("java") && (pack == 'java.lang' || pack == 'java/lang' || cm.class_name == 'java/lang' || cm.class_name == 'java.lang')) {

         // If we're in quiet mode (ie, trying to do an auto-import),
         // we always prefer java.lang imports over everything.
         // This avoids the situation where it automatically adds an import
         // for "org.gonzo.something.String" because the only two canidates
         // were that and java.lang.String.  For classes that have the same name
         // as java.lang classes, it's up to the user to add the import for the
         // different class.  (the alternative is allowing bogosities like 
         // "import java.lang.String", which doesn't hurt anything, but drives
         // me up the wall).
         if (quiet) {
            if (_chdebug) {
               isay(depth, "find_import_name H"__LINE__": java.lang case, return EMPTY");
            }
            return "";
         }

         in_java_lang_package = true;
         continue;
      }

      // Only look for header files in C/C++
      if (_LangaugeIsLikeCPP() && 
          _get_extension(cm.file_name) != "" &&
          lowcase(_first_char(_get_extension(cm.file_name))) != 'h') {
         if (_chdebug) {
            isay(depth, "find_import_name: SKIP, C/C++ NOT HEADER FILE");
         }
         continue;
      }

      if (tag_tree_type_is_class(cm.type_name)) {

         // Don't consider classes in the same package.
         if (this_file_package_name != "" && cm.class_name == this_file_package_name) {
            in_same_package = true;
            if (_chdebug) {
               isay(depth, "find_import_name: SKIP, SAME PACKAGE: "cm.class_name);
            }
            continue;
         }

         // Don't consider classes outside of our package that only have package visibility
         if ((cm.flags & SE_TAG_FLAG_ACCESS) == SE_TAG_FLAG_PACKAGE) {
            not_visible = true;
            if (_chdebug) {
               isay(depth, "find_import_name: SKIP, NOT VISIBLE OUTSIDE PACKAGE");
            }
            continue;
         } 
         
         // Is this class defined in this file?
         if (file_eq(cm.file_name, p_buf_name)) {
            if (_chdebug) {
               isay(depth, "find_import_name: SKIP, SAME FILE");
            }
            in_same_package = true;
            continue;
         }

         // Must be an inner class if it has slashes in it.
         slash_pos := pos("/", cm.class_name);
         if (slash_pos != 0) {
            // Grab everything before the first /. This should be the package name
            if (cm.class_name == this_file_package_name) {
               in_same_package = true;
               if (_chdebug) {
                  isay(depth, "find_import_name: SKIP, CLASS IS PACKAGE SCOPE");
               }
               continue;
            }

            // Make it a java compatible class name. 
            cm.class_name = stranslate(cm.class_name, ".", "/");
         }

         // Check to see if a fully qualified import already exists for this symbol.
         // If so then make it the only possible choice. This is so the user does not
         // keep having to make the choice over and over again
         hash_key :=  cm.class_name :+ '.' :+ cm.member_name;
         if (import_hash._indexin(import_name) && import_hash:[hash_key] != null) {
            if (quiet == false) {
               _message_box("Add Import: symbol '"hash_key"' already imported");
            }
            if ((cur_sym.type_name == "annotation" && cm.type_name == "annotype") || cur_sym.type_name != "annotation") {
               refined_choices._makeempty();
               refined_choices :+= cm;
               symbol_type_name=cm.type_name;
               symbol_file_name=cm.file_name;
            }
            break;
         }

         // If the name doesn't exist in our hash then add it to the refined list
         if ( duplicate_hash._isempty() || duplicate_hash._indexin(hash_key) == 0 ) {
            // DJB 11-17-2005
            // Skip this choice if there was already an implicitely included choice
            if (in_same_package && this_file_package_name!="") continue;
            // RGH 3-3-2008
            // Skip this choice if there is already a class in java.lang 
            if (in_java_lang_package) continue;
            // Add this choice to our list of choices. It passed all the tests.
            if ((cur_sym.type_name == "annotation" && cm.type_name == "annotype") || cur_sym.type_name != "annotation") {
               refined_choices :+= cm;
               duplicate_hash:[hash_key] = cm;
            }
         }
      }
      symbol_type_name=cm.type_name;
      symbol_file_name=cm.file_name;
   }

   // Could not find a choice. There could be
   // a couple reasons that this would happen   
   if (quiet == false && refined_choices._length() == 0) {
      if (in_java_lang_package == true) {
         _message_box("Add Import: '"symbol_name"' is in the java.lang package which is imported automatically. No import statement is needed.");
      } else if(in_same_package == true && this_file_package_name != "") {
         _message_box("Add Import: '"symbol_name"' is in the same package as this file. No import statement needed.");
      } else if(not_visible) {
         _message_box("Add Import: '"symbol_name"' has default access and is not visible. No import statement added.");
      } else if(final_find) {
         _message_box("Add Import: '"symbol_name"' is not a class.");
      }
      if (_chdebug) {
         isay(depth, "find_import_name H"__LINE__": could not find match, return EMPTY");
      }
      return "";
   }

   if (_chdebug) {
      isay(depth, "find_import_name H"__LINE__": num all_choices="all_choices._length());
      isay(depth, "find_import_name H"__LINE__": num refined_choices="refined_choices._length());
      idump(depth+1, refined_choices, "find_import_name H"__LINE__": refined_choices");
   }

   // If more than one refined_choice remains then ask the user to choose
   // the appropriate one.
   if (refined_choices._length() == 1) {
      import_name = refined_choices[0].class_name;
      _maybe_append(import_name, '.');
      import_name :+= refined_choices[0].member_name;
      symbol_type_name=refined_choices[0].type_name;
      symbol_file_name=refined_choices[0].file_name;
      cur_sym = refined_choices[0];
   } else if(refined_choices._length() > 1) {
      // Build list of package.class choices for user to pick from.
      _str choices[]=null;
      foreach (cm in refined_choices) {
         choices :+= cm.class_name :+ '.' :+ cm.member_name;
         symbol_type_name = cm.type_name;
         symbol_file_name = cm.file_name;
      }

      import_name = show('_sellist_form -modal ',
                  nls('Select a Tag Name'),
                  SL_SELECTCLINE,
                  choices,
                  '',
                  '',  // help item name
                  '',  // font
                  ''   // Call back function
                 );

      // find the symbol that this matched to
      foreach (cm in refined_choices) {
         key := cm.class_name :+ '.' :+ cm.member_name;
         if (import_name == key) {
            cur_sym = cm;
         }
      }
   }

   if (_chdebug) {
      isay(depth, "find_import_name H"__LINE__": DONE, return "import_name);
   }
   return import_name;
}

/** 
 * @return 
 * Calculate and return the relative path for a header file in the 
 * given include path. Try to find the shortest path. 
 * 
 * @param file_name      absolute path to header file
 * @param include_path   include path to search
 */
static _str make_include_relative_to(_str file_name, _str include_path, int depth=0)
{
   if (_chdebug) {
      isay(depth, "make_include_relative_to H"__LINE__": IN, file_name="file_name);
   }

   shortest_file_name := file_name;
   while (include_path != "") {
      parse include_path with auto include_dir PATHSEP include_path;
      if (include_dir != "") {
         if (_chdebug) {
            isay(depth+1, "make_include_relative_to H"__LINE__": include_dir="include_dir);
         }
         relative_file_name := relative(file_name, include_dir, false);
         if (length(relative_file_name) < length(shortest_file_name)) {
            shortest_file_name = relative_file_name;
         }
      }
   }
   if (_chdebug) {
      isay(depth, "make_include_relative_to H"__LINE__": OUT, shortest_file_name="shortest_file_name);
   }
   return shortest_file_name;
}

/** 
 * @return 
 * Check if this include file is usually included through a more common 
 * wrapper include file.  This just check for common cases. 
 * 
 * @param file_name      absolute path to header file
 */
static _str get_more_common_header_file_name(_str file_name, int depth)
{
   if (_chdebug) {
      isay(depth, "get_more_common_header_file_name H"__LINE__": IN, file_name="file_name);
   }

   // a bit of a hack for STL, because the goodies are under "bits", but
   // we don't want that, we want the "main" header include
   if (pos(FILESEP:+"bits":+FILESEP:+"stl_", file_name)) {
      nobits_file_name := stranslate(file_name, FILESEP, FILESEP:+"bits":+FILESEP:+"stl_");
      if (file_exists(_strip_filename(nobits_file_name, 'E'))) {
         file_name = _strip_filename(nobits_file_name, 'E');
         if (_chdebug) {
            isay(depth, "get_more_common_header_file_name H"__LINE__": FOUND, file_name="file_name);
         }
      } else if (file_exists(nobits_file_name)) {
         file_name = nobits_file_name;
         if (_chdebug) {
            isay(depth, "get_more_common_header_file_name H"__LINE__": FOUND, file_name="file_name);
         }
      }
   }

   return file_name;
}

/**
 * Attempt to add an import for the symbol under the cursor.
 * 
 * @param this_file_package_name    current package we are working on 
 * @param imports                   list of import statements in this file  
 * @param import_hash               hash table of import statements in this file 
 * @param cm                        (output) information for symbol under cursor 
 * @param choices                   (output) all choices found 
 * @param quiet                     if true, fail quietly, do not pop up a message box 
 * @param doing_full_file           is this part of an Organize Imports operation? 
 * @param max_seek_position_imports stop at this seek position 
 * @param visited                   (reference) hash table of prior tagging results 
 * @param depth                     keeps track of recursive depth for logging 
 * 
 * @return Returns 'true' on success, false otherwise.
 */
static bool add_import(_str this_file_package_name, 
                       _str (&imports)[], 
                       VS_JAVA_IMPORT_INFO (&import_hash):[], 
                       struct VS_JAVA_AUTO_IMPORT_OPTIONS auto_import_opts,
                       struct VS_TAG_BROWSE_INFO &cm, 
                       struct VS_TAG_BROWSE_INFO (&choices)[], 
                       bool quiet, bool doing_full_file, 
                       long max_seek_position_imports,
                       VS_TAG_RETURN_TYPE (&visited):[]=null,
                       int depth=0)
{
   if (_chdebug) {
      isay(depth, "add_import: IN");
      isay(depth, "add_import: this_file_package_name="this_file_package_name);
      isay(depth, "add_import: doing_full_file="doing_full_file);
      isay(depth, "add_import: max_seek_position="max_seek_position_imports);
      idump(depth+1, choices, "add_import H"__LINE__": choices");
   }
   if (!_haveRefactoring()) {
      return false;
   }

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   tag_files := tags_filenamea(cm.language);

   // Try to find the import name for the symbol under the cursor.
   type_name := "";
   import_file := "";
   found_matching_symbol := false;
   import_name := find_import_name(this_file_package_name, 
                                   type_name, import_file,
                                   found_matching_symbol, 
                                   cm.member_name, choices, 
                                   quiet, 
                                   final_find:false, 
                                   import_hash, cm,
                                   tag_files,
                                   visited, depth+1);
   if (_chdebug) {
      isay(depth, "add_import: import_name="import_name);
      isay(depth, "add_import: type_name="type_name);
      isay(depth, "add_import: found_matching_symbol="found_matching_symbol);
      tag_browse_info_dump(cm, "add_import H"__LINE__":", depth);
   }
   
   // If not doing full file then check to see if there is an already
   // existing wildcard import that this new import would fit into
   // and don't add the import in that case.
   if (doing_full_file==false && import_name != "") {
      foreach (auto import_i in imports) {
         wildcard := pos("*", import_i);
         lpos := lastpos('.', import_name);

         if (wildcard >= 3) {
            if (substr(import_i, 1, wildcard-2) == substr(import_name, 1, lpos-1)) {
               // Founding matching wildcard import. Bail out.
               if (quiet == false) {
                  _message_box("Add Import: symbol '"import_name"' already imported");
               }
               // This import is used by at least one reference in the file.
               import_hash:[import_i].m_is_used = true;
               if (_chdebug) {
                  isay(depth, "add_import: SOMETHING WITH WILDCARDS");
               }
               return false;
            }
         }
      }
   }

   // If the import name cannot be found for the symbol under the cursor
   // then jump to it's declaration and try again. This will find the import
   // name for cases such as:
   // TestClass aVar;  <-- when the cursor is on aVar and not TestClass
   // If doing full file do not do this step since somewhere in the file we will
   // find it's declaration and add the import for it.
   if (doing_full_file == false && found_matching_symbol==true && (type_name=='param' || type_name=='lvar' || type_name=='var')) {
      if (_chdebug) {
         isay(depth, "add_import: VAR case, type_name="type_name);
      }

      // Find the match information for this symbol. This is to get the
      // the type of this variable. TestClass aVar with the cursor on aVar
      // should get the name TestClass.
      tag_update_context();
      num_matches := 0;
      max_matches := def_tag_max_find_context_tags;
      tag_push_matches();
      tag_list_symbols_in_context(cm.member_name, "", 0, 0, tag_files, '',
                                  num_matches, max_matches, 
                                  SE_TAG_FILTER_ANYTHING, SE_TAG_CONTEXT_ANYTHING, 
                                  true, true, visited, depth+1);

      // Find the class name of this variable.
      match_name := "";
      var_class  := "";
      for (i := 0; i < num_matches; i++) {
         tag_get_detail2(VS_TAGDETAIL_match_name, i, match_name);
         tag_get_detail2(VS_TAGDETAIL_match_return, i, var_class);
         if (_chdebug) {
            isay(depth, "add_import: match_name["i"]="match_name" var_class="var_class);
         }
         if (match_name == cm.member_name) {
            break;
         }
      }
      tag_pop_matches();

      // If the class name is found then move the cursor to that definition
      // and redo get_browse_info and find_import_name steps.
      if (var_class != "") {
         save_pos(auto position);

         // Start search after any existing package specifier or imports.
         _GoToROffset(max_seek_position_imports);
         if (_chdebug) {
            isay(depth, "add_import: max_seek_position_imports="max_seek_position_imports);
            isay(depth, "add_import: var_name="var_class);
         }

         // Search for the class of the variable in the file.
         if (search(var_class,'@h') == 0) {
            result := tag_get_browse_info("", 
                                          cm, 
                                          quiet:true,
                                          choices, 
                                          return_choices:true,
                                          filterDuplicates:true,
                                          filterPrototypes:true,
                                          filterDefinitions:false,
                                          force_tag_search:false,
                                          filterFunctionSignatures:false,
                                          visited, depth+1, 
                                          def_tag_max_find_context_tags, 
                                          filterTagUses:true,
                                          filterAnnotations:true,
                                          filterImportsAndIncludes:true);
            if (_chdebug) {
               tag_browse_info_dump(cm, "add_import", depth);
            }
            import_name = find_import_name(this_file_package_name, 
                                           type_name, import_file,
                                           found_matching_symbol, 
                                           var_class, choices, 
                                           quiet, 
                                           final_find:true, 
                                           import_hash, cm,
                                           tag_files,
                                           visited, depth+1);
            if (_chdebug) {
               isay(depth, "add_import: H"__LINE__": import_name="import_name);
            }
         }
         restore_pos(position);
      }
   }

   // Get the package for this import name. If it
   // does not have a package then it cannot be an import.
   package := "";
   last_dot := lastpos('.', import_name);
   if (last_dot > 0) {
      package = substr(import_name, 1, last_dot-1);
   }

   // refine the file name for the import file (#include case)
   is_system_include := false;
   orig_import_len := length(import_file);
   if (_LanguageInheritsFrom("e") || _LangaugeIsLikeCPP()) {
      if (_LangaugeIsLikeCPP()) {
         common_import_file := get_more_common_header_file_name(import_file, depth+1);
         if (!file_eq(common_import_file, import_file)) {
            common_import_len := length(common_import_file);
            common_import_file = make_include_relative_to(common_import_file, auto_import_opts.m_project_include_path, depth+1);
            if (length(common_import_file) == common_import_len) {
               common_import_file = make_include_relative_to(common_import_file, auto_import_opts.m_system_include_path, depth+1);
               is_system_include = (length(common_import_file) < common_import_len);
            }
            if (length(common_import_file) < common_import_len) {
               import_file = common_import_file;
            }
         }
      }
      if (length(import_file) == orig_import_len) {
         import_file = make_include_relative_to(import_file, auto_import_opts.m_project_include_path, depth+1);
         if (length(import_file) == orig_import_len) {
            import_file = make_include_relative_to(import_file, auto_import_opts.m_system_include_path, depth+1);
            is_system_include = (length(import_file) < orig_import_len);
         }
      }
   }

   if (_chdebug) {
      isay(depth, "add_import: package="package);
      isay(depth, "add_import: type_name="type_name);
      isay(depth, "add_import: import_name="import_name);
      isay(depth, "add_import: import_file="import_file" system="is_system_include);
   }

   // Add new #include or #import if needed
   if (_LanguageInheritsFrom("e") || _LangaugeIsLikeCPP()) {
      if (//import_name == "" && 
          import_file != "" && 
          (tag_tree_type_is_class(type_name) || tag_tree_type_is_func(type_name) || tag_tree_type_is_constant(type_name) || tag_tree_type_is_data(type_name)) &&
          !_file_eq(_strip_filename(import_file, 'P'), "builtins.e") &&
          !_file_eq(_strip_filename(import_file, 'P'), _strip_filename(p_buf_name, 'P')) &&
          !import_exists(_strip_filename(import_file, 'P'), imports, import_hash, depth+1) &&
          !import_exists(import_file, imports, import_hash, depth+1)) {

         if (import_exists(_strip_filename(import_file, 'P'), imports, import_hash, depth+1)) {
            if (_chdebug) {
               isay(depth, "add_import: ALREADY HAVE #INCLUDE, NOT ADDING IMPORT");
            }
            if (quiet == false) {
               _message_box("Add Import: symbol '"import_name"' already included");
            }
            return false;
         }
         if (length(import_file) >= orig_import_len) {
            if (_chdebug) {
               isay(depth, "add_import: CAN NOT RESOLVE #include directory");
            }
            if (quiet == false) {
               _message_box("Add Import: Can not resolve relative #include directory for symbol '"import_name"'");
            }
            return false;
         }

         // Figure out the current newline
         file_eol := p_newline;

         // Add new import to list and hash table;
         struct VS_JAVA_IMPORT_INFO import_info;
         if (_LanguageInheritsFrom("e") && _get_extension(import_file) == 'e') {
            import_info.m_import_text = "#import \"" :+ import_file :+ "\"" :+ file_eol;
         } else if (is_system_include) {
            import_info.m_import_text = "#include <" :+ import_file :+ ">" :+ file_eol;
         } else {
            import_info.m_import_text = "#include \"" :+ import_file :+ "\"" :+ file_eol;
         }
         imports :+= import_file;
         import_name = import_file;
         import_info.m_import_name = import_name;
         import_info.m_start_seekpos = 0;
         import_info.m_end_seekpos = 0;
         import_info.m_package = package;
         import_info.m_file_name = import_file;
         import_info.m_is_used = true;
         import_info.m_is_include = true;
         import_info.m_is_newly_added = true;
         import_hash:[import_info.m_import_name] = import_info;
         if (_chdebug) {
            isay(depth, "add_import: ADDED #include, import_name="import_name);
            isay(depth, "add_import: ADDED #include, import_file="import_file);
            isay(depth, "add_import: ADDED #include, import_text="import_info.m_import_text);
            idump(depth+1, import_info, "add_import H"__LINE__": import_info");
         }

         // heh, maybe we can both add a #include and add a using statement
         // whoa, there, you are blowing my mind.  really?
         if (import_name == "" ||
             package == "" || 
             !tag_tree_type_is_class(type_name) ||
             import_exists(import_name, imports, import_hash, depth+1) ||
             import_exists(package, imports, import_hash, depth+1)) {
            return true;
         }
      }
   }

   // Add new import if needed
   if (import_name != "" && 
       package != "" && 
       tag_tree_type_is_class(type_name) &&
       !import_exists(import_name, imports, import_hash, depth+1)) {

      if (import_exists(package, imports, import_hash, depth+1)) {
         if (_chdebug) {
            isay(depth, "add_import: ALREADY HAVE PACKAGE, NOT ADDING IMPORT");
         }
         if (quiet == false) {
            _message_box("Add Import: symbol '"import_name"' already imported");
         }
         return false;
      }

      // Figure out the current newline
      file_eol := p_newline;

      // Add new import to list and hash table;
      struct VS_JAVA_IMPORT_INFO import_info;

      // Embedded Java (JSP?) If so then write out import in JSP format
      if (strieq(p_EmbeddedLexerName,'java') || strieq(p_EmbeddedLexerName,'cs')) {
         import_info.m_import_text = "<%@ page import=\"" :+ import_name :+ "\"%>" :+ file_eol;
         import_info.m_import_name = import_name;
      } else if (_LanguageInheritsFrom("cs")) {
         import_info.m_import_text = "using " :+ package :+ ';' :+ file_eol;
         import_info.m_import_name = package;
      } else if (_LanguageInheritsFrom("java")) {
         import_info.m_import_text = "import " :+ import_name :+ ';' :+ file_eol;
         import_info.m_import_name = import_name;
      } else if (_LanguageInheritsFrom("e")) {
         import_info.m_import_text = "using " :+ import_name :+ ';' :+ file_eol;
         import_info.m_import_name = package;
      } else if (_LangaugeIsLikeCPP()) {
         //import_info.m_import_text = "using namespace " :+ package :+ ';' :+ file_eol;
         //import_info.m_import_name = package;
         //import_info.m_is_package = true;
         c_import_name := stranslate(import_name, "::", ".");
         import_info.m_import_text = "using " :+ c_import_name :+ ';' :+ file_eol;
         import_info.m_import_name = import_name;
      } else if (_LanguageInheritsFrom("cs")) {
         import_info.m_import_text = "using " :+ package :+ ';' :+ file_eol;
         import_info.m_import_name = package;
         import_info.m_is_package = true;
      } else {
         import_info.m_import_text = "import " :+ import_name :+ ';' :+ file_eol;
         import_info.m_import_name = import_name;
      }
      import_info.m_start_seekpos = 0;
      import_info.m_end_seekpos = 0;
      import_info.m_package = package;
      import_info.m_file_name = import_file;
      import_info.m_is_used = true;
      import_info.m_is_newly_added = true;
      imports :+= import_info.m_import_name;
      import_hash:[import_info.m_import_name] = import_info;
      if (_chdebug) {
         isay(depth, "add_import: ADDED IMPORT, import_name="import_name);
         isay(depth, "add_import: ADDED IMPORT, import_file="import_file);
         isay(depth, "add_import: ADDED IMPORT, import_text="import_info.m_import_text);
         idump(depth+1, import_info, "add_import H"__LINE__": import_info");
      }
      return true;
   }

   if (quiet == false && found_matching_symbol && cm.member_name != "") {
      if (import_exists(import_name, imports, import_hash, depth+1)) {
         _message_box("Add Import: symbol '"cm.member_name"' is already imported");
      } else if (import_exists(_strip_filename(import_file, 'P'), imports, import_hash, depth+1) ||
                 import_exists(import_file, imports, import_hash, depth+1)) {
         _message_box("Add Import: symbol '"cm.member_name"' is already #included");
      } else {
         _message_box("Add Import: symbol '"cm.member_name"' does not require import");
      }
   }
   if (_chdebug) {
      isay(depth, "add_import: DONE, NOT ADDING IMPORT");
   }
   return false;
}

/**
 * Get the color coding information for the current symbol under the cursor. 
 * This is used to screen out keywords and builtin types. 
 * 
 * @return Color constant CFG_*
 */
static int get_curword_color()
{
   orig_col := p_col;
   start_col := p_col-1;
   p_col=start_col;

   color := _clex_find(0,'g');

   // Restore the position to the end of the word
   p_col = orig_col;
   return color;
}

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Organize Imports Commands

/**
 * Organize the imports for the the current buffer. 
 * This function is only supported in Java and C#.
 *  
 * @categories Refactoring_Functions
 */
_command int refactor_organize_imports() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   
   current_db := tag_current_db();
   _str symbols_processed:[];
   struct VS_JAVA_IMPORT_INFO import_hash:[];
   _str imports[];

   // Did tagging fail to find a symbol? If tagging failed for a symbol and their
   // are unused imports after finishing the file then inform the user of the problem
   // and don't delete unused imports. This is to fix a problem where users are using libraries
   // that are not tagged and organize imports was blowing away existing imports that were
   // actually used.
   tagging_failure = false;

   orig_wid := p_window_id;
   editorctl_wid := p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid = _mdi.p_child;
   }

   // get the auto-import options
   auto_import_opts := editorctl_wid.getAutoImportOptions();
   if (auto_import_opts == null) {
      _message_box("Organize Imports: not supported in this context");
      return -1;
   }

   // Check to see if occurrences need to be retaggged before
   // showing the cancel form. Bad interactions can happend
   // when the retag and cancel forms are up at the same time.
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   show_cancel_form("Organizing Imports", "", true, true);

   // Save current cursor position
   editorctl_wid._save_pos2(auto cursorSeekPos);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Get any imports that are already in the file.
   struct VS_TAG_RETURN_TYPE visited:[];
   editorctl_wid._UpdateContextAndTokens(true);
   tag_files := tags_filenamea(editorctl_wid.p_LangId);

   get_existing_imports(imports, import_hash, auto min_seek_position, auto max_seek_position, auto_import_opts, tag_files, visited, 1);
   if (_chdebug) {
      say("refactor_organize_imports H"__LINE__": min_seek_position="min_seek_position" max_seek_position="max_seek_position);
   }

   // Get the package name for this file.
   package_name := get_package_name_for_current_buffer(auto start_of_package_pos, auto end_of_package_pos, visited, 1);
   if (_chdebug) {
      say("refactor_organize_imports H"__LINE__": package_name="package_name);
      say("refactor_organize_imports H"__LINE__": start_of_package_pos="start_of_package_pos);
      say("refactor_organize_imports H"__LINE__": end_of_package_pos="end_of_package_pos);
   }

   prevword := "";

   // Start at end of imports and process all symbols in the file..
   _GoToROffset(max_seek_position);

   struct VS_TAG_BROWSE_INFO cm = null;

// say("===============================");
// say("Organize imports");
// say("===============================");

   curword := cur_word(auto start_col, "", false, true );
   _str unmatched_symbols[];
   while (curword!="") {
      cfg := get_curword_color();
      if (cfg == CFG_KEYWORD || cfg == CFG_COMMENT || cfg == CFG_STRING) {
         c_next_sym();
         prevword = curword;
         curword = c_get_syminfo();
         continue;
      }

      if (_chdebug) {
         say("refactor_organize_imports: curword="curword);
      }

      // Only process words that have not previously been processed and words
      // that look like valid identifiers. Don't try to find an import for any symbol
      // that is preceded by a . because that symbol already has a scope.
      if (symbols_processed:[curword]._isempty() && is_valid_identifier(curword) && prevword != '.') {
         symbols_processed:[curword] = 1;

         result := tag_get_browse_info_remove_duplicates("", 
                                                         cm, 
                                                         quiet:true, 
                                                         return_choices:true,
                                                         auto choices,
                                                         def_tag_max_find_context_tags, 
                                                         force_tag_search:false, 
                                                         ( VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS
                                                         | VS_TAG_REMOVE_DUPLICATE_PROTOTYPES
                                                         | VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES
                                                         | VS_TAG_REMOVE_DUPLICATE_TAG_USES
                                                         | VS_TAG_REMOVE_INVALID_LANG_REFERENCES
                                                         | VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES
                                                         | VS_TAG_REMOVE_DUPLICATE_IMPORTS
                                                         | VS_TAG_REMOVE_DUPLICATE_SYMBOLS ),
                                                         SE_TAG_FILTER_ANYTHING/* & ~(SE_TAG_FILTER_ANY_PROCEDURE)*/,
                                                         SE_TAG_CONTEXT_ANYTHING | SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                         visited, 1);
         
         // Did the match come from a Java file?
         if (cm.language=="" && cm.tag_database != "") {
            orig_tag_file := tag_current_db();
            if (tag_read_db(cm.tag_database) >= 0) {
               tag_get_language(cm.file_name, cm.language);
            }
            tag_read_db(orig_tag_file);
         }
         if (cm.language=="") cm.language=_Filename2LangId(cm.file_name);
         if (result == 0 && cm.language != "java" && cm.language != "cs" && cm.language != "dll") {
            // If not, force a tagfile search
            result = tag_get_browse_info_remove_duplicates( "", 
                                                            cm, 
                                                            quiet:true, 
                                                            return_choices:true,
                                                            choices,
                                                            def_tag_max_find_context_tags, 
                                                            force_tag_search:true,
                                                            ( VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS
                                                            | VS_TAG_REMOVE_DUPLICATE_PROTOTYPES
                                                            | VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES
                                                            | VS_TAG_REMOVE_DUPLICATE_TAG_USES
                                                            | VS_TAG_REMOVE_INVALID_LANG_REFERENCES
                                                            | VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES
                                                            | VS_TAG_REMOVE_DUPLICATE_IMPORTS
                                                            | VS_TAG_REMOVE_DUPLICATE_SYMBOLS ),
                                                            SE_TAG_FILTER_ANYTHING,
                                                            SE_TAG_CONTEXT_ANYTHING | SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                            visited, 1);

         }
         if (_chdebug) {
            isay(1, "refactor_organize_imports H"__LINE__": result="result);
            tag_browse_info_dump(cm, "refactor_organize_imports", 2);
            idump(2, choices, "refactor_organize_imports H"__LINE__": choices");
         }

         // Is this a valid symbol?
         if (result == 0 && cm.member_name !="" && choices != null) {
            found_class := false;
            curword = cm.member_name;
            foreach (auto choice_cm in choices) {
               // Process only symbols that exactly match the current word, 
               // and are interfaces or classes.
               if (curword == choice_cm.member_name && tag_tree_type_is_class(choice_cm.type_name)) {
                  if (_chdebug) {
                     isay(1, "refactor_organize_imports H"__LINE__": ADDING IMPORT FOR "choice_cm.member_name);
                  }
                  found_class = true;
                  add_import(package_name, 
                             imports, import_hash, 
                             auto_import_opts,
                             cm, choices, 
                             quiet:true, 
                             doing_full_file:true, 
                             max_seek_position, 
                             visited, 1);
                  break;
               }
            }
            // In this case, we have an existing import for a class we could not find
            if (!found_class && cm.type_name == "import" && _file_eq(cm.file_name, p_buf_name)) {
               if (_chdebug) {
                  isay(1, "refactor_organize_imports: EXISTING IMPORT FOR UNRECOGNIZED CLASS: "cm.member_name);
               }
               tagging_failure = true;
               unmatched_symbols :+= curword;
            }
         } else if(result != 0) {
            tagging_failure = true;
            unmatched_symbols :+= curword;
            if (_chdebug) {
               isay(1, "refactor_organize_imports H"__LINE__": NO MATCH FOR "curword);
            }
         }
      }

      // Manage progress bar and cancel button.
      static bool canceled;
      process_events( canceled );
      if (cancel_form_cancelled()) {
         // Move cursor back to original position
         close_cancel_form(cancel_form_wid());
         editorctl_wid._restore_pos2(cursorSeekPos);
         return COMMAND_CANCELLED_RC;
      }

      // Update form using seek position in file as progress amount.
      cancel_form_set_labels(cancel_form_wid(), "Finding Imports...");
      cancel_form_progress(cancel_form_wid(), (int)_QROffset(), p_RBufSize);

      c_next_sym();
      prevword = curword;
      curword = c_get_syminfo();
   }

   // Replace existing imports with new organized imports
   update_imports(imports, 
                  import_hash, 
                  auto_import_opts,
                  min_seek_position, max_seek_position, 
                  end_of_package_pos, 
                  true,
                  unmatched_symbols,
                  depth:1);

   // Move cursor back to original position
   _restore_pos2(cursorSeekPos);

   close_cancel_form(cancel_form_wid());

   // restore focus to the editor control when done
   if (editorctl_wid && _iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl(false)) {
      editorctl_wid._set_focus();
   }

   return 0;
}

/**
 * Organize the imports for the the current buffer. 
 * This function is only supported in Java and C#.
 *  
 * @categories Refactoring_Functions
 */
_command int jrefactor_organize_imports() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return refactor_organize_imports();
}
_command void codehelp_trace_organize_imports() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   say("codehelp_trace_organize_imports: ===========================");
   orig_chdebug := _chdebug;
   _chdebug = 1;
   refactor_organize_imports();
   _chdebug = orig_chdebug;
   say("============================================================");
}

int _OnUpdate_refactor_organize_imports(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   lang := target_wid.p_LangId;

   // Don't allow organize imports on JSP or ASP
   if (_LanguageInheritsFrom("java", lang)) {
      if (strieq(target_wid.p_EmbeddedLexerName,"java")) {
         return MF_GRAYED;
      }
   } else if (_LanguageInheritsFrom("cs", lang)) {
      if (strieq(target_wid.p_EmbeddedLexerName,"csharp")) {
         return MF_GRAYED;
      }
   } else {
      // language mode must be Java or C#
      return MF_GRAYED;
   }

   return MF_ENABLED;
}

int _OnUpdate_jrefactor_organize_imports(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_refactor_organize_imports(cmdui, target_wid, command);
}

/**
 * Command to add an import to a Java or C# file for the current symbol 
 * under the cursor.
 * 
 * @param quiet    If quiet then no message boxes will appear when there are problems
 *                 This is used when doing auto import so the user does not get message
 *                 boxes popping up when they are typing
 * @param cm       If this parameter is null then the symbol under the cursor is
 *                 the symbol that should have an import added for it. If cm
 *                 is nonnull then it should contain tag information for a java
 *                 class to add an import for.
 * @param filename when this is empty the current buffer is used. If the
 *                 filename is not empty then this is the file to place the import
 *                 statement into. A temp view will be opened for this filename
 * 
 * @return returns 0 on success. A nonzero error code on failure 
 *  
 * @categories Refactoring_Functions
 */
_command int refactor_add_import(bool quiet=false, struct VS_TAG_BROWSE_INFO cm=null, _str filename=null, bool jumpToImport=false) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (_chdebug) {
      say("refactor_add_import H"__LINE__": IN");
   }
   if (!_haveRefactoring()) {
      if (!quiet) {
          popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      }
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   editorctl_wid := p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid = _mdi.p_child;
   }

   // get the auto-import options
   auto_import_opts := editorctl_wid.getAutoImportOptions();
   if (auto_import_opts == null) {
      if (quiet == false) {
         _message_box("Add Import: not supported in this context");
      }
      return -1;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   editorctl_wid._UpdateContextAndTokens(true);
   context_id := editorctl_wid.tag_current_context();
   type_name := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   }
   if (type_name :== "import" || type_name :== "package" || tag_tree_type_is_annotation(type_name)) {
      if (_chdebug) {
         say("refactor_add_import H"__LINE__": in IMPORT or PACKAGE or ANNOTATION");
      }
      return 0 ;
   }

   // Get symbol to add import for from cursor
   // Set up cm and filename according to information from symbol under the cursor.
   typeless cursorSeekPos = null;
   need_temp_view := false;
   curword := "";
   struct VS_TAG_BROWSE_INFO choices[];

   if (cm == null) {
      if (_isdiffed(p_buf_id)) {
         if (quiet == false) {
            _message_box("Add Import: not allowed while the file is being diffed");
         }
         return -1;
      }

      // If in JSP but auto import is turned off then don't add the import
      if (strieq(p_EmbeddedLexerName,"java") && !def_jrefactor_auto_import_jsp) {
         if (_chdebug) {
            say("refactor_add_import H"__LINE__": JSP FAIL");
         }
         return -1;
      }
      // If in ASP but auto import is turned off then don't add the import
      if (strieq(p_EmbeddedLexerName,"csharp") && !def_csharp_refactor_auto_import_asp) {
         if (_chdebug) {
            say("refactor_add_import H"__LINE__": ASP FAIL");
         }
         return -1;
      }

      // Stop if we are in a comment or string
      cfg := _clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         if (quiet == false) {
            _message_box("Add Import: not allowed in a comment or string");
         }
         return -1;
      }

      // Stop if the current symbol does not look like a valid keyword.
      // If the character under the cursor is whitespace, slide left one char
      // before calling cur_word(), otherwise, it will find the next word
      // on the line.
      save_pos(auto p);
      if (get_text()=='') {
         left();
      }
      curword = cur_identifier(auto start_col);
      restore_pos(p);
      if (!is_valid_identifier(curword)) {
         if (quiet == false) {
            _message_box("Add Import: '"curword"' is not a valid identifier");
         }
         return -1;
      }

      // The current word might be at a different place then where the cursor is. This means
      // the above inside string check may not work because the cursor may not be in a string
      // but the current word is in a string so move the column to the start of the curword and
      // check there as well for whether we are in a string or not.
      curr_col := p_col;
      p_col = start_col;
      cfg=_clex_find(0,'g');
      p_col = curr_col;
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         if (quiet == false) {
            _message_box("Add Import: not allowed in a comment or string");
         }
         return -1;
      }
   
      // Stop if doing auto-import (quiet) and this identifier does
      // not start with a capital letter (like a class is expected to)
      if (quiet && upcase(substr(curword,1,1)) != substr(curword,1,1) &&
          !auto_import_opts.m_auto_import_lowcase_identifiers) {
         if (_chdebug) {
            say("refactor_add_import H"__LINE__": NOT CAP");
         }
         return -1;
      }
 
      VS_TAG_RETURN_TYPE visited:[];
      status := tag_get_browse_info_remove_duplicates("", 
                                                      cm, 
                                                      quiet:true, 
                                                      return_choices:true,
                                                      choices,
                                                      def_tag_max_find_context_tags, 
                                                      force_tag_search:false, 
                                                      ( VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS
                                                      | VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES
                                                      | VS_TAG_REMOVE_DUPLICATE_TAG_USES
                                                      | VS_TAG_REMOVE_INVALID_LANG_REFERENCES
                                                      | VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES
                                                      | VS_TAG_REMOVE_DUPLICATE_IMPORTS
                                                      | VS_TAG_REMOVE_DUPLICATE_SYMBOLS ),
                                                      SE_TAG_FILTER_ANYTHING/* & ~(SE_TAG_FILTER_ANY_PROCEDURE)*/,
                                                      SE_TAG_CONTEXT_ANYTHING | SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                      visited, 1);

      // Did the match come from a Java file?
      if (cm.language=="" && cm.tag_database != "") {
         orig_tag_file := tag_current_db();
         if (tag_read_db(cm.tag_database) >= 0) {
            tag_get_language(cm.file_name, cm.language);
         }
         tag_read_db(orig_tag_file);
      }
      if (cm.language=="") cm.language=_Filename2LangId(cm.file_name);
      if (status == 0 && cm.language != "java" && cm.language != "cs" && cm.language != "dll") {
         // If not, force a tagfile search
         status = tag_get_browse_info_remove_duplicates( "", 
                                                         cm, 
                                                         quiet:true, 
                                                         return_choices:true,
                                                         choices,
                                                         def_tag_max_find_context_tags, 
                                                         force_tag_search:true,
                                                         ( VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS
                                                         | VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES
                                                         | VS_TAG_REMOVE_DUPLICATE_TAG_USES
                                                         | VS_TAG_REMOVE_INVALID_LANG_REFERENCES
                                                         | VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES
                                                         | VS_TAG_REMOVE_DUPLICATE_IMPORTS
                                                         | VS_TAG_REMOVE_DUPLICATE_SYMBOLS ),
                                                         SE_TAG_FILTER_ANYTHING,
                                                         SE_TAG_CONTEXT_ANYTHING | SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                         visited, 1);
      }

      if (status < 0) {
         if (quiet == false && status != COMMAND_CANCELLED_RC) {
            _message_box("Add Import: not a valid symbol");
         }
         if (_chdebug) {
            say("refactor_add_import H"__LINE__": brouse info, status="status);
         }
         return status;
      }
   
      // Stop if the current symbol does not look like a valid keyword.
      curword = cm.member_name;
      if (!is_valid_identifier(curword)) {
         if (quiet == false) {
            _message_box("Add Import: '"curword"' is not a valid identifier");
         }
         return -1;
      }
      filename = cm.file_name;
   } else {
      // need to open a temp view for the file to place the import into since we are probably coming
      // from the proctree or symbol browser.
      need_temp_view = true;
      curword = cm.member_name;
      choices[0] = cm;
   }

   // open up a temp view for the file to add the import to
   temp_view_id := orig_view_id := 0;
   if (need_temp_view) {
      orig_view_id=p_window_id;
      status := _open_temp_view(filename, temp_view_id, orig_view_id);
      if (status) {
         p_window_id=orig_view_id;
         if (_chdebug) {
            say("refactor_add_import H"__LINE__": FAILED TO OPEN TEMP VIEW, file="filename);
         }
         return status;
      }
      p_window_id=temp_view_id;
   } else {
      // Save current cursor position
      _save_pos2(cursorSeekPos);
   }

   // Get any imports that are already in the file.
   _UpdateContextAndTokens(true);   
   tag_files := tags_filenamea(p_LangId);
   struct VS_TAG_RETURN_TYPE visited:[];
   get_existing_imports(auto imports, auto import_hash, auto min_seek_position, auto max_seek_position, auto_import_opts, tag_files, visited, 1);
   if (_chdebug) {
      say("refactor_add_import H"__LINE__": min_seek_position="min_seek_position" max_seek_position="max_seek_position);
   }

   // Get the package name for this file.
   package_name := get_package_name_for_current_buffer(auto start_of_package_pos, auto end_of_package_pos, visited, 1);
   if (_chdebug) {
      say("refactor_add_import H"__LINE__": package_name="package_name);
      say("refactor_add_import H"__LINE__": start_of_package_pos="start_of_package_pos);
      say("refactor_add_import H"__LINE__": end_of_package_pos="end_of_package_pos);
   }

   need_to_add_import := add_import(package_name, 
                                    imports, import_hash, 
                                    auto_import_opts,
                                    cm, choices, 
                                    quiet, 
                                    doing_full_file:false, 
                                    max_seek_position, 
                                    visited, 1);
   if (_chdebug) {
      say("refactor_add_import H"__LINE__": need_to_add_import="need_to_add_import);
   }

   // Replace existing imports with new organized imports
   if (jumpToImport && need_to_add_import) {
      response := _message_box("Add import statement for '"curword"'?", "SlickEdit", MB_OKCANCEL);
      if (response != IDOK) {
         need_to_add_import = false;
         jumpToImport = false;
      }
   }
   if (need_to_add_import) {
      if (jumpToImport && !need_temp_view && cursorSeekPos != null) {
         save_pos(auto beforePB);
         _restore_pos2(cursorSeekPos);
         push_bookmark();
         restore_pos(beforePB);
      }
      update_imports(imports, import_hash, 
                     auto_import_opts,
                     min_seek_position, max_seek_position, 
                     end_of_package_pos, false,
                     unmatched_symbols:null,
                     depth:1);
      sticky_message("Added import for '" curword"'");
   }
   if (jumpToImport) {
      // find the import statement that was used, if there was one
      found_one := false;
      foreach (auto import_info in import_hash) {
         if (import_info.m_is_used && import_info.m_start_seekpos > 0) {
            if (!need_to_add_import) push_bookmark();
            _GoToROffset(import_info.m_start_seekpos);
            _save_pos2(cursorSeekPos);
            found_one = true;
            break;
         }
      }
      if (!found_one) {
         _message_box("No import statement for '"curword"'.");
      }
   }

   if (need_temp_view) {
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   } else {
      // Move cursor back to original position
      _restore_pos2(cursorSeekPos);
   }

   if (_chdebug) {
      say("refactor_add_import H"__LINE__": OUT");
   }
   return 0;
}
/**
 * Command to add an import to a java file. 
 * 
 * @param quiet    If quiet then no message boxes will appear when there are problems
 *                 This is used when doing auto import so the user does not get message
 *                 boxes popping up when they are typing
 * @param cm       If this parameter is null then the symbol under the cursor is
 *                 the symbol that should have an import added for it. If cm
 *                 is nonnull then it should contain tag information for a java
 *                 class to add an import for.
 * @param filename when this is empty the current buffer is used. If the
 *                 filename is not empty then this is the file to place the import
 *                 statement into. A temp view will be opened for this filename
 * 
 * @return returns 0 on success. A nonzero error code on failure
 */
_command int jrefactor_add_import(bool quiet=false, struct VS_TAG_BROWSE_INFO cm=null, _str filename=null) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return refactor_add_import(quiet, cm, filename);
}
_command void codehelp_trace_add_import() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   say("codehelp_trace_add_import: =================================");
   orig_chdebug := _chdebug;
   _chdebug = 1;
   refactor_add_import();
   _chdebug = orig_chdebug;
   say("============================================================");
}
int _OnUpdate_jrefactor_add_import(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_refactor_add_import(cmdui, target_wid, command);
}
int _OnUpdate_refactor_add_import(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   // stop if this is not Java or we are diffing
   lang := target_wid.p_LangId;
   if (!_LanguageInheritsFrom("java",lang) && 
       !_LanguageInheritsFrom("cs", lang) &&
       !_LanguageInheritsFrom("e", lang) &&
       !_LangaugeIsLikeCPP(lang)) {
      return MF_GRAYED;
   }
   if (_isdiffed(target_wid.p_buf_id)) {
      return MF_GRAYED;
   }

   // Stop if we are in a comment or string
   int cfg=target_wid._clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return MF_GRAYED;
   }

   // Stop if the current symbol does not look like a valid keyword.
   curword := target_wid.cur_identifier(auto start_col);
   if (!is_valid_identifier(curword)) {
      return MF_GRAYED;
   }

   if (_LanguageInheritsFrom("cs", lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Add using statement for '"curword"'");
   } else if (_LanguageInheritsFrom("e", lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Add #import for '"curword"'");
   } else if (_LangaugeIsLikeCPP(lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Add #include for '"curword"'");
   } else {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Add import for '"curword"'");
   }
   return MF_ENABLED;
}

/**
 * Command to jump to the import or using statement for the current symbol 
 * under the cursor in a Java or C# file.
 * 
 * @param quiet    If quiet then no message boxes will appear when there are problems
 *                 This is used when doing auto import so the user does not get message
 *                 boxes popping up when they are typing
 * @param cm       If this parameter is null then the symbol under the cursor is
 *                 the symbol that should have an import added for it. If cm
 *                 is nonnull then it should contain tag information for a java
 *                 class to add an import for.
 * @param filename when this is empty the current buffer is used. If the
 *                 filename is not empty then this is the file to place the import
 *                 statement into. A temp view will be opened for this filename
 * 
 * @return returns 0 on success. A nonzero error code on failure 
 *  
 * @categories Refactoring_Functions
 */
_command int refactor_goto_import(bool quiet=false, struct VS_TAG_BROWSE_INFO cm=null, _str filename=null, bool jumpToImport=false) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return refactor_add_import(true, cm, filename, jumpToImport:true);
}
int _OnUpdate_refactor_goto_import(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   // stop if this is not Java or we are diffing
   lang := target_wid.p_LangId;
   if (!_LanguageInheritsFrom("java",lang) && 
       !_LanguageInheritsFrom("cs", lang) &&
       !_LanguageInheritsFrom("e", lang) &&
       !_LangaugeIsLikeCPP(lang)) {
      return MF_GRAYED;
   }
   if (_isdiffed(target_wid.p_buf_id)) {
      return MF_GRAYED;
   }

   // Stop if we are in a comment or string
   int cfg=target_wid._clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return MF_GRAYED;
   }

   // Stop if the current symbol does not look like a valid keyword.
   curword := target_wid.cur_identifier(auto start_col);
   if (!is_valid_identifier(curword)) {
      return MF_GRAYED;
   }

   if (_LanguageInheritsFrom("cs", lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Go to using statement for '"curword"'");
   } else if (_LanguageInheritsFrom("e", lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Go to #import for '"curword"'");
   } else if (_LangaugeIsLikeCPP(lang)) {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Go to #include for '"curword"'");
   } else {
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Go to import statement for '"curword"'");
   }
   return MF_ENABLED;
}
_command void codehelp_trace_goto_import() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   say("codehelp_trace_goto_import: ================================");
   orig_chdebug := _chdebug;
   _chdebug = 1;
   refactor_goto_import();
   _chdebug = orig_chdebug;
   say("============================================================");
}


/**
 * Open the organize imports options dialgo
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_organize_imports_options() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   
   orig_wid := p_window_id;
   result   := 0;

   if (_LanguageInheritsFrom("cs")) {
      result = config('_csharp_refactor_organize_imports_form', 'D');
   } else if (_LanguageInheritsFrom("java")) {
      result = config('_jrefactor_organize_imports_form', 'D');
   } else {
      _message_box("Organize Imports: not supported in this language");
   }

   p_window_id = orig_wid;
   return result;
}
int _OnUpdate_refactor_organize_imports_options(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_jrefactor_organize_imports(cmdui, target_wid, command);
}

/**
 * Open the organize imports options dialgo
 * 
 * @return 
 */
_command int jrefactor_organize_imports_options() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   return refactor_organize_imports_options();
}
int _OnUpdate_jrefactor_organize_imports_options(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_refactor_organize_imports(cmdui, target_wid, command);
}

#endregion


////////////////////////////////////////////////////////////////////////////////

#region Options Dialog Helper Functions
#region Java Organize Imports Form

defeventtab _jrefactor_organize_imports_form;

void _jrefactor_organize_imports_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
   ctl_help.p_visible = false;
}

bool _jrefactor_organize_imports_form_is_modified()
{
   if (def_jrefactor_imports_per_package != ctl_import_limit.p_text) return true;
   if (def_jrefactor_depth_to_add_space != ctl_add_lines.p_text) return true;
   if (def_jrefactor_auto_import != ctl_auto_import.p_value) return true;
   if (def_jrefactor_auto_import_jsp != ctl_auto_import_jsp.p_value) return true;

   // Recreate prefix list.
   newList := "";   
   prefix_index := ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (prefix_index != -1) {
      strappend(newList, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(newList, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }
   if (def_jrefactor_prefix_list != newList && def_jrefactor_prefix_list != substr(newList, 1, length(newList) - 1)) return true;

   if (def_jrefactor_add_blank_lines != (ctl_add_blank_lines.p_value != 0)) return true;

   return false;
}

bool _jrefactor_organize_imports_form_apply()
{
   int value;
   // Save out current settings. Don't bother to set the def vars if the input is garbage
   if (isinteger(ctl_import_limit.p_text)) {
      value = (int)ctl_import_limit.p_text;
      if (value >= 0) {
         def_jrefactor_imports_per_package = (int)ctl_import_limit.p_text;
      }
   }

   // Don't bother to set the def vars if the input is garbage
   if (isinteger(ctl_add_lines.p_text)) {
      value = (int)ctl_add_lines.p_text;
      if (value >= 0) {
         def_jrefactor_depth_to_add_space = (int)ctl_add_lines.p_text;
      }
   }
   def_jrefactor_auto_import = ctl_auto_import.p_value != 0;
   def_jrefactor_auto_import_jsp = ctl_auto_import_jsp.p_value != 0;

   // Recreate prefix list.
   def_jrefactor_prefix_list = "";   
   prefix_index := ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (prefix_index != -1) {
      strappend(def_jrefactor_prefix_list, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(def_jrefactor_prefix_list, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }

   if (ctl_add_blank_lines.p_value != 0) {
      def_jrefactor_add_blank_lines = true;
   } else {
      def_jrefactor_add_blank_lines = false;
   }

   // Make sure the def var changes stick.
   _config_modify_flags(CFGMODIFY_DEFVAR);

   return true;
}

#endregion Options Dialog Helper Functions

void _jrefactor_organize_imports_form.on_create()
{
   ctl_import_limit.p_text = def_jrefactor_imports_per_package;
   ctl_add_lines.p_text = def_jrefactor_depth_to_add_space;
   ctl_add_blank_lines.p_value = (int)(def_jrefactor_add_blank_lines);
   ctl_auto_import.p_value = (int)def_jrefactor_auto_import;
   ctl_auto_import_jsp.p_value = (int)def_jrefactor_auto_import_jsp;

   if (def_jrefactor_add_blank_lines == true) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }

   _str prefix, prefix_list = def_jrefactor_prefix_list;
   while (prefix_list != "") {
      parse prefix_list with prefix ';' prefix_list;
      ctl_package_sort_order._TreeAddItem(TREE_ROOT_INDEX, prefix, TREE_ADD_AS_CHILD, 0, 0, -1);
   }
}

void ctl_add_blank_lines.lbutton_up()
{
   if (ctl_add_blank_lines.p_value != 0) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }
}

void ctl_ok.lbutton_up()
{
   if (_jrefactor_organize_imports_form_apply()) {
      p_active_form._delete_window(1);
   }
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_up.lbutton_up()
{
   ctl_package_sort_order._TreeMoveUp(ctl_package_sort_order._TreeCurIndex());
}

void ctl_down.lbutton_up()
{
   ctl_package_sort_order._TreeMoveDown(ctl_package_sort_order._TreeCurIndex());
}

void ctl_delete.lbutton_up()
{
   current_selection := ctl_package_sort_order._TreeCurIndex();
   if (current_selection != TREE_ROOT_INDEX) {
      ctl_package_sort_order._TreeDelete(current_selection);
   }
}

void ctl_add.lbutton_up()
{
   _str promptResult = show("-modal _textbox_form", "Enter a prefix to add to the list",
                            0, "", "", "", "", "Prefix name:" "" );
   // Canceled
   if (promptResult == "") return;

   _str prefix_name = _param1;
   // Only add prefix_name if it is not already in the tree.
   if (ctl_package_sort_order._TreeSearch(TREE_ROOT_INDEX, prefix_name) != -1) {
        _message_box("Prefix already exists in list", "Organize Imports");
   } else {
      ctl_package_sort_order._TreeAddItem(TREE_ROOT_INDEX, prefix_name, TREE_ADD_AS_CHILD, 0, 0, -1);
   }
}

void _jrefactor_organize_imports_form.on_resize()
{
   // we don't need to worry about leaving space for buttons if 
   // we are embedded in the options dialog
   embeddedInOptions := !ctl_ok.p_visible;

   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_package_sort_order_frame.p_x;
   int vert_margin   = ctl_label_explicit_export_limit.p_y;

   // force size of dialog to remain reasonable
   if (!embeddedInOptions) {
      // if the minimum width has not been set, it will return 0
      if (!_minimum_width()) {
         _set_minimum_size(button_width*6, button_height*14);
      }
   }

   // determine how much we've resized in height by looking at the bottommost control
   deltaY := p_height - (ctl_package_sort_order_frame.p_y_extent + vert_margin);
   if (!embeddedInOptions) {
      deltaY = p_height - (ctl_ok.p_y_extent + vert_margin);
   }
   deltaX := p_width - (ctl_package_sort_order_frame.p_x_extent + 2 * horz_margin);

   ctl_package_sort_order_frame.p_height += deltaY;
   ctl_package_sort_order.p_height += deltaY;

   ctl_package_sort_order_frame.p_width += deltaX;

   alignUpDownListButtons(ctl_package_sort_order.p_window_id, 
                          ctl_package_sort_order_frame.p_width - ctl_package_sort_order.p_x, 
                          ctl_add.p_window_id,
                          ctl_up.p_window_id,
                          ctl_down.p_window_id,
                          ctl_delete.p_window_id);

   alignControlsHorizontal(ctl_ok.p_x, 
                           p_height - vert_margin - ctl_ok.p_height,
                           horz_margin,
                           ctl_ok.p_window_id, ctl_cancel.p_window_id, ctl_help.p_window_id);
}

#endregion


////////////////////////////////////////////////////////////////////////////////

#region Options Dialog Helper Functions
#region C# Organize Imports Form

defeventtab _csharp_refactor_organize_imports_form;

void _csharp_refactor_organize_imports_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
   ctl_help.p_visible = false;
}

bool _csharp_refactor_organize_imports_form_is_modified()
{
   if (def_csharp_refactor_imports_per_package != ctl_import_limit.p_text) return true;
   if (def_csharp_refactor_depth_to_add_space != ctl_add_lines.p_text) return true;
   if (def_csharp_refactor_auto_import != ctl_auto_import.p_value) return true;
   if (def_csharp_refactor_auto_import_asp != ctl_auto_import_jsp.p_value) return true;

   // Recreate prefix list.
   newList := "";   
   prefix_index := ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (prefix_index != -1) {
      strappend(newList, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(newList, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }
   if (def_csharp_refactor_prefix_list != newList && def_csharp_refactor_prefix_list != substr(newList, 1, length(newList) - 1)) return true;

   if (def_csharp_refactor_add_blank_lines != (ctl_add_blank_lines.p_value != 0)) return true;

   return false;
}

bool _csharp_refactor_organize_imports_form_apply()
{
   int value;
   // Save out current settings. Don't bother to set the def vars if the input is garbage
   if (isinteger(ctl_import_limit.p_text)) {
      value = (int)ctl_import_limit.p_text;
      if (value >= 0) {
         def_csharp_refactor_imports_per_package = (int)ctl_import_limit.p_text;
      }
   }

   // Don't bother to set the def vars if the input is garbage
   if (isinteger(ctl_add_lines.p_text)) {
      value = (int)ctl_add_lines.p_text;
      if (value >= 0) {
         def_csharp_refactor_depth_to_add_space = (int)ctl_add_lines.p_text;
      }
   }
   def_csharp_refactor_auto_import = ctl_auto_import.p_value != 0;
   def_csharp_refactor_auto_import_asp = ctl_auto_import_jsp.p_value != 0;

   // Recreate prefix list.
   def_csharp_refactor_prefix_list = "";   
   prefix_index := ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (prefix_index != -1) {
      strappend(def_csharp_refactor_prefix_list, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(def_csharp_refactor_prefix_list, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }

   if (ctl_add_blank_lines.p_value != 0) {
      def_csharp_refactor_add_blank_lines = true;
   } else {
      def_csharp_refactor_add_blank_lines = false;
   }

   // Make sure the def var changes stick.
   _config_modify_flags(CFGMODIFY_DEFVAR);

   return true;
}

#endregion Options Dialog Helper Functions

void _csharp_refactor_organize_imports_form.on_create()
{
   ctl_import_limit.p_text = def_csharp_refactor_imports_per_package;
   ctl_add_lines.p_text = def_csharp_refactor_depth_to_add_space;
   ctl_add_blank_lines.p_value = (int)(def_csharp_refactor_add_blank_lines);
   ctl_auto_import.p_value = (int)def_csharp_refactor_auto_import;
   ctl_auto_import_jsp.p_value = (int)def_csharp_refactor_auto_import_asp;

   if (def_csharp_refactor_add_blank_lines == true) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }

   _str prefix, prefix_list = def_csharp_refactor_prefix_list;
   while (prefix_list != "") {
      parse prefix_list with prefix ';' prefix_list;
      ctl_package_sort_order._TreeAddItem(TREE_ROOT_INDEX, prefix, TREE_ADD_AS_CHILD, 0, 0, -1);
   }
}

void ctl_add_blank_lines.lbutton_up()
{
   if (ctl_add_blank_lines.p_value != 0) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }
}

void ctl_ok.lbutton_up()
{
   if (_csharp_refactor_organize_imports_form_apply()) {
      p_active_form._delete_window(1);
   }
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_up.lbutton_up()
{
   ctl_package_sort_order._TreeMoveUp(ctl_package_sort_order._TreeCurIndex());
}

void ctl_down.lbutton_up()
{
   ctl_package_sort_order._TreeMoveDown(ctl_package_sort_order._TreeCurIndex());
}

void ctl_delete.lbutton_up()
{
   current_selection := ctl_package_sort_order._TreeCurIndex();
   if (current_selection != TREE_ROOT_INDEX) {
      ctl_package_sort_order._TreeDelete(current_selection);
   }
}

void ctl_add.lbutton_up()
{
   _str promptResult = show("-modal _textbox_form", "Enter a prefix to add to the list",
                            0, "", "", "", "", "Prefix name:" "" );
   // Canceled
   if (promptResult == "") return;

   _str prefix_name = _param1;
   // Only add prefix_name if it is not already in the tree.
   if (ctl_package_sort_order._TreeSearch(TREE_ROOT_INDEX, prefix_name) != -1) {
        _message_box("Prefix already exists in list", "Organize Imports");
   } else {
      ctl_package_sort_order._TreeAddItem(TREE_ROOT_INDEX, prefix_name, TREE_ADD_AS_CHILD, 0, 0, -1);
   }
}

void _csharp_refactor_organize_imports_form.on_resize()
{
   // we don't need to worry about leaving space for buttons if 
   // we are embedded in the options dialog
   embeddedInOptions := !ctl_ok.p_visible;

   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   int horz_margin   = ctl_package_sort_order_frame.p_x;
   int vert_margin   = ctl_label_explicit_export_limit.p_y;

   // force size of dialog to remain reasonable
   if (!embeddedInOptions) {
      // if the minimum width has not been set, it will return 0
      if (!_minimum_width()) {
         _set_minimum_size(button_width*6, button_height*14);
      }
   }

   // determine how much we've resized in height by looking at the bottommost control
   deltaY := p_height - (ctl_package_sort_order_frame.p_y_extent + vert_margin);
   if (!embeddedInOptions) {
      deltaY = p_height - (ctl_ok.p_y_extent + vert_margin);
   }
   deltaX := p_width - (ctl_package_sort_order_frame.p_x_extent + 2 * horz_margin);

   ctl_package_sort_order_frame.p_height += deltaY;
   ctl_package_sort_order.p_height += deltaY;

   ctl_package_sort_order_frame.p_width += deltaX;

   alignUpDownListButtons(ctl_package_sort_order.p_window_id, 
                          ctl_package_sort_order_frame.p_width - ctl_package_sort_order.p_x, 
                          ctl_add.p_window_id,
                          ctl_up.p_window_id,
                          ctl_down.p_window_id,
                          ctl_delete.p_window_id);

   alignControlsHorizontal(ctl_ok.p_x, 
                           p_height - vert_margin - ctl_ok.p_height,
                           horz_margin,
                           ctl_ok.p_window_id, ctl_cancel.p_window_id, ctl_help.p_window_id);
}

#endregion


////////////////////////////////////////////////////////////////////////////////
#region Imports Menu

/**
 * Add originize imports menu items to the specified menu
 *
 * @param menuHandle       Handle of parent menu
 * @param cmdPrefix        Prefix of command.  Empty for MDI menu or editor control right click menu
 * @param cm               Information about the tag that is currently selected
 * @param removeIfDisabled Remove the oi submenu if disabled and this is true 
 * @param currentBuffer    (optional) Name of current file 
 * @param currentLangId    (optional) current language mode 
 */
void addOrganizeImportsMenuItems(int menuHandle, _str cmdPrefix, 
                                 struct VS_TAG_BROWSE_INFO cm = null,
                                 bool removeIfDisabled = true, 
                                 _str currentBuffer="", _str currentLangId="")
{
   // find oi menu placeholder
   oiMenuIndex := _menu_find_loaded_menu_category(menuHandle, "organize_imports", auto oiMenuHandle);
   if (oiMenuIndex < 0) {
      return;
   }

   // load oi menu template
   index := find_index("_organize_imports_menu", oi2type(OI_MENU));
   if (!index) {
      return;
   }
   oiTemplateHandle := _menu_load(index, 'P');
   if (oiTemplateHandle < 0) {
      return;
   }

   // remove organize imports submenu if tag information isn't given
   if (removeIfDisabled && cm == null) {
      _menu_delete(menuHandle, oiMenuIndex);
      return;
   }


   // if this is not Java or C#, remove the organize imports submenu if requested
   lang := currentLangId;
   if (cm != null) lang = cm.language;
   if (length(lang) == 0) lang = _Filename2LangId(cm.file_name);
   if (removeIfDisabled && 
       (!_LanguageInheritsFrom('java', lang) && 
        !_LanguageInheritsFrom("cs", lang) && 
        !_LanguageInheritsFrom("e", lang) && 
        !_LangaugeIsLikeCPP(lang))) {
      // remove oi submenu
      _menu_delete(menuHandle, oiMenuIndex);
      return;
   }

   // determine if the organize imports menu items should be enabled
   // the extension check is to weed out cases where Java or C# is embedded.
   enableOrganizeImports := false;
   enableAddImport := false;
   if (cm != null) {
      if (_LanguageInheritsFrom('java', lang)) {
         if (_get_extension(currentBuffer, false) == 'java') {
            enableOrganizeImports = true;
         }
         if (tag_tree_type_is_class(cm.type_name) && _get_extension(currentBuffer, false) == 'java') {
            enableAddImport = true;
         }
      } 
      if (_LanguageInheritsFrom('cs', lang)) {
         if (_get_extension(currentBuffer, false) == 'cs') {
            enableOrganizeImports = true;
         }
         if (tag_tree_type_is_class(cm.type_name) && _get_extension(currentBuffer, false) == 'cs') {
            enableAddImport = true;
         }
      } 
      if (_LanguageInheritsFrom('e', lang) && _get_extension(currentBuffer, false) == 'e') {
         if (tag_tree_type_is_class(cm.type_name) ||
             tag_tree_type_is_func(cm.type_name)  ||
             tag_tree_type_is_constant(cm.type_name)) {
            enableAddImport = true;
         }
         if (tag_tree_type_is_data(cm.type_name) && cm.class_name == "") {
            enableAddImport = true;
         }
      } 
      if (_LangaugeIsLikeCPP(lang)) {
         if (tag_tree_type_is_class(cm.type_name) ||
             tag_tree_type_is_func(cm.type_name)  ||
             tag_tree_type_is_constant(cm.type_name)) {
            enableAddImport = true;
         }
      } 
   }

   // the format of the command depends on where the organize imports menu is being
   // shown from.  if cmdPrefix is empty, this is the main mdi menu or the
   // right click menu in an editor control.  for these, just use the normal
   // 'refactor_NAME' syntax.  if there is a command prefix, this is coming
   // from the proctree or symbol browser, so use the format 'PREFIX_refactor NAME'.
   //
   // each organize imports should use its category as its command suffix.
   // For example:
   //
   //   oi        category   command           prefixed-command
   //   ------------------------------------------------------------------------------
   //   rename    rename     refactor_rename   prefix_refactor rename
   //

   cmd := "_jrefactor ";
   if (_LanguageInheritsFrom('cs', lang)) {
      cmd = "_csharp_refactor ";
   }

   // add the specific items to the submenu
   if (!_LanguageInheritsFrom("e", lang) && !_LangaugeIsLikeCPP(lang)) {
      addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "organize_imports_options", cmdPrefix, cmd, 0, enableOrganizeImports);
      addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "bar", cmdPrefix, cmd, 0, true);
   }
   addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "add_import", cmdPrefix, cmd, 0, enableAddImport);
   addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "goto_import", cmdPrefix, cmd, 0, enableAddImport);
 
   // cleanup oi menu template
   _menu_destroy(oiTemplateHandle);
}

#endregion
