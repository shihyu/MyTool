////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47802 $
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
#import "context.e"
#import "csymbols.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "optionsxml.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "refactor.e"
#import "tagrefs.e"
#import "tags.e"
#import "util.e"
#import "se/tags/TaggingGuard.e"
#endregion

/**
 * This module implements our support for java specific tag based oi.
 *
 * @since  10.0
 */

/**
 * List of Java package prefixes to use to categorize and order
 * imports when doing auto-import and organize imports.
 * <p>
 * To modify this setting, go to "Tools" > "Imports" >
 * "Options..."
 * 
 * @default "java;javax;org;com"
 * @categories Configuration_Variables
 */
_str def_jrefactor_prefix_list = "java;javax;org;com";
/**
 * If enabled, support auto import for Java.
 * <p>
 * To modify this setting, go to "Tools" > "Imports" >
 * "Options..."
 * 
 * @default true 
 * @categories Configuration_Variables
 */
int def_jrefactor_auto_import = 1;
/**
 * If enabled, support auto import for JSP pages (Java embedded
 * in HTML).
 * <p>
 * To modify this setting, go to "Tools" > "Imports" >
 * "Options..."
 * 
 * @default false
 * @categories Configuration_Variables
 */
int def_jrefactor_auto_import_jsp = 0;
/**
 * This setting controls the maximum number of classes that will
 * be explicitely imported from a package before auto import or
 * organize imports will collapse the imports into a wildcard
 * import.
 * <p>
 * To modify this setting, go to "Tools" > "Imports" >
 * "Options..."
 * 
 * @default 10
 * @categories Configuration_Variables
 */
int def_jrefactor_imports_per_package = 10;
/**
 * If enabled, insert blank lines between groups of import
 * statements when doing organize imports in Java code.
 * <p>
 * To modify this setting, go to "Tools" > "Imports" >
 * "Options..."
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_jrefactor_add_blank_lines=true;
/**
 * If enabled, Java auto import and organize imports will
 * attempt to insert import statements even for classes that
 * start with lower case letters.  By default, this is disabled
 * as a performance and accuracy optimization because, by
 * convention, Java classes use initial caps.
 * 
 * @default false
 * @categories Configuration_Variables
 */
boolean def_jrefactor_auto_import_lowcase_identifiers = false;

static boolean tagging_failure = false;

/*  
   if they differ at all then don't do anything if gmin_depth_to_add_space is zero

   import com.blah.blah;
   import java.awt.blah;
   import java.awt.event.event1;
   import java.awt.event.event2;
   import java.util.blah;
   import javax.swing.blah1;
   import javax.swing.blah2;

   if they differ at the first level then add a space when gmin_depth_to_add_space is = 1 then

      import com.blah.blah;
      
      import java.awt.blah;
      import java.awt.event.event1;
      import java.awt.event.event2;
      import java.util.blah;
   
      import javax.swing.blah1;
      import javax.swing.blah2;
   
   if they differ at the second level then add a space when gmin_depth_to_add_space is = 2

      import com.blah.blah;
      
      import java.awt.blah;
      import java.awt.event.event1;
      import java.awt.event.event2;
      
      import java.util.blah;
   
      import javax.swing.blah1;
      import javax.swing.blah2;
      
   if they differ at the third level then add a space when gmin_depth_to_add_space is = 3

      import com.blah.blah;
      
      import java.awt.blah;
      
      import java.awt.event.event1;
      import java.awt.event.event2;
      
      import java.util.blah;
   
      import javax.swing.blah1;

      import javax.swing.blah2;   
*/
int def_jrefactor_depth_to_add_space = 1;

struct VS_JAVA_IMPORT_INFO {
   _str  name;
   int   start_seekpos;
   int   end_seekpos;
   _str  text;
   _str  package;
   boolean used;
   boolean is_static;
};

int _OnUpdate_jrefactor_organize_imports_options(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   return MF_ENABLED;
}

int _OnUpdate_jrefactor_organize_imports(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   _str lang=target_wid.p_LangId;
   // Don't allow organize imports on JSP
   if (!_LanguageInheritsFrom('java',lang) || strieq(p_EmbeddedLexerName,"java")) {
      return MF_GRAYED;
   }

   return MF_ENABLED;
}

int _OnUpdate_jrefactor_add_import(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   // stop if this is not Java or we are diffing
   _str lang=target_wid.p_LangId;
   if (!_LanguageInheritsFrom('java',lang)) {
      return MF_GRAYED;
   }
   if(_isdiffed(target_wid.p_buf_id)) {
      return MF_GRAYED;
   }

   // Stop if we are in a comment or string
   int cfg=target_wid._clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return MF_GRAYED;
   }

   // Stop if the current symbol does not look like a valid keyword.
   curword := target_wid.cur_identifier(auto start_col);
   if(!is_valid_identifier(curword)) {
      return MF_GRAYED;
   }

   _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P',"Add import for '"curword"'");
   return MF_ENABLED;
}

static boolean is_valid_identifier(_str symbol) 
{
   _str ch = substr(symbol, 1, 1);
   if(isalpha(ch) || ch == '_') {
//    int cfg=_clex_find(0,'g');
//    if (cfg==CFG_SYMBOL3 || cfg==CFG_SYMBOL1 || cfg==CFG_SYMBOL2 || cfg==CFG_SYMBOL4) {
         return true;
//    }
   } 

   return false;
}

// ==============================
static _str get_package_name_for_current_buffer(int &end_of_package_name_pos) 
{
   int i, num_matches=0, max_matches=def_tag_max_find_context_tags;
   _str previous_import="",tag_files[] = tags_filenamea(p_LangId);

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // Get the package name for this file.
   _str package_name="", file_name="";
   _str prefix="", suffix="";
   tag_push_matches();
   tag_list_in_file(0,0,"",null,_strip_filename(p_buf_name,'P'),VS_TAGFILTER_PACKAGE,VS_TAGCONTEXT_ANYTHING,
                    num_matches,max_matches,false,true);
   for(i = 1; i <= num_matches; i++) {
      tag_get_detail2(VS_TAGDETAIL_match_file, i, file_name);
  
      if(file_name == p_buf_name) {
         tag_get_detail2(VS_TAGDETAIL_match_name, i, suffix);
         tag_get_detail2(VS_TAGDETAIL_match_class, i, prefix);
         if (prefix != "") {
            _str temp_pkg = prefix :+ VS_TAGSEPARATOR_package :+ suffix;
            if (length(temp_pkg) > length(package_name)) {
               package_name = temp_pkg;
            }
         } else {
            if (length(suffix) > length(package_name)) {
               package_name = suffix;
            }
         }
         tag_get_detail2(VS_TAGDETAIL_match_scope_seekpos,  i, end_of_package_name_pos);

         // Go to first end of line character after package.
         typeless orig_pos;
         _save_pos2(orig_pos);
         _GoToROffset(end_of_package_name_pos);

         // Get seek position after the package name newline
         down();
         begin_line();
         end_of_package_name_pos = (int)_QROffset();

         _restore_pos2(orig_pos);
      }
   }

   tag_pop_matches();
   return package_name;
}

// ==============================
static int find_line_comment(int seekpos)
{
   // Support multiline line comments that are indented the same amount?
   typeless orig_pos;
   _save_pos2(orig_pos);
   _GoToROffset(seekpos);

   down();
   begin_line();
   seekpos = (int)_QROffset()-1;

   _restore_pos2(orig_pos);
   return seekpos;
}

void java_get_existing_imports(_str (&existingImports)[], struct VS_JAVA_IMPORT_INFO (&import_hash):[], int &min_seek_position, int &max_seek_position)
{
   get_existing_imports(existingImports,import_hash,min_seek_position,max_seek_position);
}

static void get_existing_imports(_str (&existingImports)[], struct VS_JAVA_IMPORT_INFO (&import_hash):[], int &min_seek_position, int &max_seek_position)
{
   struct VS_JAVA_IMPORT_INFO import_info;
   _str file_name;
   typeless i, cursorSeekPos;

   min_seek_position = MAXINT;
   max_seek_position = 0;

   // Save current cursor position
   _save_pos2(cursorSeekPos);

   int num_matches=0,max_matches=def_tag_max_find_context_tags;
   _str previous_import="";

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // Get all import statements.
   tag_push_matches();
   // Pass in null for tagfiles so the current context is checked. This is in the case where
   // some imports may have been removed, changed but have not been saved yet.
   tag_list_globals_of_type(0, 0, null, VS_TAGTYPE_import, 0, 0, num_matches, max_matches);

   // Pick out all import statements that are in the current buffer.
   for(i = 1; i <= num_matches; i++) {
      tag_get_detail2(VS_TAGDETAIL_match_file, i, file_name);
      if(file_name == p_buf_name) {
          // Store information about each import statement.
         tag_get_detail2(VS_TAGDETAIL_match_name,  i, import_info.name);
         tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, import_info.start_seekpos);
         tag_get_detail2(VS_TAGDETAIL_match_end_seekpos, i, import_info.end_seekpos);

         // Adjust end seek position to encompass any trailing line comment for this import
         import_info.end_seekpos = find_line_comment(import_info.end_seekpos);

         // Embedded Java (JSP). Want to grab the leading <% of the existing import that is not contained
         // by the tag start_seekpos so subtract two from the start seekpos. The adjustment of end seek position
         // for the trailing %> should be taken care of by find_line_comment
         if(strieq(p_EmbeddedLexerName, 'java')) {
            import_info.start_seekpos -=2;
         }

         // Adjust begin seek position to one after the end of the last import statement comment.
         if(previous_import != "") {
//            import_info.start_seekpos = import_hash:[previous_import].end_seekpos+1;
         } else {
            // Figure out what if any comments above should be included in the first import.
//            say("first");
         }

         // Grab import text
         import_info.text = get_text(import_info.end_seekpos-import_info.start_seekpos+1, import_info.start_seekpos);
         import_info.used = false;

         // Check for static import
         _str rest;
         parse import_info.text with "import" rest;
         _str temp = strip(rest);
         if (pos("static", temp) == 1){
            // Leave static imports alone...for now
            import_info.is_static = true;
            import_info.used = true;
         } else {
            import_info.is_static = false;
         }

         existingImports[existingImports._length()] = import_info.name;
 
         // Get bounds of import information.
         if(import_info.start_seekpos < min_seek_position) {
            min_seek_position = import_info.start_seekpos;
         }

         if(import_info.end_seekpos > max_seek_position) {
            max_seek_position = import_info.end_seekpos;
         }

         import_hash:[import_info.name] = import_info;

         previous_import = import_info.name;
      }
   }
   tag_pop_matches();
   _restore_pos2(cursorSeekPos);
}

/*
 * Does this import exist in the list of imports passed in?
 */
static boolean import_exists(_str import_name, _str (&imports)[], struct VS_JAVA_IMPORT_INFO (&import_hash):[])
{
   int i;
   for(i = 0; i < imports._length(); i++) {
      if(import_name == imports[i]) {
         // This import is used by at least one reference in the file.
         import_hash:[import_name].used = true;
         return true;
      }
   }
   return false;
}

// This function compares to packages and see on how many package
// levels that they match from left to right until a nonmatching level
// is found.
static int levels_of_equality(_str package1, _str package2) 
{
   int level, smallest=0;
   _str package1_array[], package2_array[];

   split(package1, '.', package1_array);
   split(package2, '.', package2_array);

   if(package1_array._length() < package2_array._length()) {
      smallest = package1_array._length();
   } else {
      smallest = package1_array._length();
   }

   for(level = 0; level < smallest; level++) {
      if(package1_array[level] != package2_array[level]) {
          break;
      }
   }

   if(level == smallest && package1 == package2) {
      level = MAXINT;
   }
   return level;
}

static void update_imports(_str (&imports)[],  struct VS_JAVA_IMPORT_INFO (&import_hash):[], 
                           int min_seek_position, int max_seek_position, int end_of_package_name_pos, 
                           boolean doing_full_file, _str unmatched_symbols[] = null)
{
   int i,j;
   _str file_eol = p_newline, num_imports_per_package:[] = null;

   // Sort the list into alphabetical order
   imports._sort();

   // Count how many import statements per package.
   // Save package name in import info.
   boolean unused_import_and_tagging_failure = false;
   for(i=0; i < imports._length(); i++) { 
      // If the whole file has been processed and the import
      // is not being used by any symbol then get rid of it.
      if(doing_full_file && import_hash:[imports[i]].used == false) {
         if(tagging_failure == false) {
            continue;
         } else {
            unused_import_and_tagging_failure = true;
         }
      }

      int last_dot = lastpos('.', imports[i]);
      if(last_dot > 0) {
         _str package = substr(imports[i], 1, last_dot-1);

         if(num_imports_per_package:[package]._isempty()) {
            num_imports_per_package:[package] = 1;
         } else {
            num_imports_per_package:[package]++;
         }

         import_hash:[imports[i]].package = package;
      }
   }

   boolean keep_unused = false;
   if(unused_import_and_tagging_failure == true) {
      _str msg = "Organize Imports: Not deleting unused imports because it could not find some symbols:\n\n";
      int x;
      for (x = 0; x < unmatched_symbols._length(); x++) {
         msg = msg :+ '   ' :+ unmatched_symbols[x] :+ "\n";
      }
      _message_box(msg);
      keep_unused = true;
   }

   // Add temporary line between imports and rest of file to prevent
   // a problem with restoring the seek position when trying to add an 
   // import that is immediately below the deleted set of imports.
   // Delete this line after inserting organized set of imports.
   _GoToROffset(max_seek_position);

   // Only insert line if their is not one already.
   boolean added_line=false;
   if(max_seek_position!= 0) {
      _str line;
      down();
      get_line(line);
      up();
      if(line!="") {
         insert_line("");
         added_line=true;
      }
   }

   // Delete old imports if any
   if(min_seek_position != MAXINT) {
      _GoToROffset(min_seek_position);
      if (max_seek_position > min_seek_position) {
         _delete_text(max_seek_position-min_seek_position+1);
      }
   } else {
      if(end_of_package_name_pos==0) {
         _GoToROffset(0);
      } else {
         _GoToROffset(end_of_package_name_pos);
      }
   }

   // Build import prefix array from def var.
   _str import_prefixes[], prefix, prefix_list = def_jrefactor_prefix_list;
   while(prefix_list != "") {
      parse prefix_list with prefix ';' prefix_list;
      import_prefixes[import_prefixes._length()] = prefix;
   }


   // Go through imports and see if they match any of the user
   // defined prefixes. If so then stick them in the matching prefix
   // slot.
   struct VS_JAVA_IMPORT_INFO import_info;   
   _str prefixes[][];
   for(i=0; i < imports._length(); i++) {
      import_info = import_hash:[imports[i]];

      // If the whole file has been processed and the import
      // is not being used by any symbol then get rid of it.
      if(doing_full_file && import_hash:[imports[i]].used == false && unused_import_and_tagging_failure == false
         && !keep_unused) continue;

      // Don't add existing imports with *'s in them when doing organize imports. Keep
      // them if just adding...
      // Unless it's unused and we have already determined we need to
      // keep unused imports.
      if(doing_full_file && pos("*",  import_info.text) != 0 && import_info.is_static == false && (import_hash:[imports[i]].used == true || 
               (import_hash:[imports[i]].used == false && !keep_unused))) continue;

      // See what prefix this import matches and stick the import into this prefix list.
      for(j=0; j < import_prefixes._length(); j++) {
         _str sub = substr(imports[i], 1, length(import_prefixes[j]));
         if( sub == import_prefixes[j]) {
            prefixes[j][prefixes[j]._length()] = imports[i];
            break;
         }
      }

      // Does not match any prefix. Stick in last prefix slot.
      if(j == import_prefixes._length()) {
         prefixes[j][prefixes[j]._length()] = imports[i];
      }
   }

   _str previous_package = "";
   for(i = 0; i < import_prefixes._length()+1; i++) {

      // imports in same package
      for(j = 0; j < prefixes[i]._length(); j++) {
         import_info = import_hash:[prefixes[i][j]];
         if(import_info.package == null) {
            continue;
         }

         if(def_jrefactor_add_blank_lines != 0 && previous_package != "" && levels_of_equality(previous_package, import_info.package) < def_jrefactor_depth_to_add_space) {
            _insert_text(file_eol,false,  p_newline);
         }
         previous_package = import_info.package;
   
         // Insert wildcard import if exceeded import limit for this package.
         if(num_imports_per_package:[import_info.package] > def_jrefactor_imports_per_package) {
            // Insert wildcard import
            // 
            // Embedded Java(JSP?) If so then write out import in JSP format
            if(strieq(p_EmbeddedLexerName,'java')) {
               _insert_text( "<%@ page import=\"" :+ import_info.package :+ '.*' :+ "\"%>" :+ file_eol, false, p_newline);    
            } else {
               _str imp_prefix = "import "; 
               if (import_info.is_static) {
                  imp_prefix = imp_prefix :+ "static "; 
               }
               _insert_text(imp_prefix :+ import_info.package :+ '.*;' :+ file_eol, false, p_newline);
            }
 
            // Zero out num imports to indicate that the wildcard import has been inserted
            // and all subsequent explicit imports using this package should be ignored.
            num_imports_per_package:[import_info.package] = 0;
         } else if(num_imports_per_package:[import_info.package] != 0) {
            _insert_text(import_info.text,false, p_newline);      
         }
      }
   }
   // Delete line created after original imports.
   if(added_line) {
      _delete_line();
   }
}

// Find the import name for the symbol under the cursor.
// Get rid of any matches that we know cannot be valid.
static _str find_import_name(_str this_file_package_name, _str &symbol_type_name, boolean &found_matching_symbol, 
                             _str symbol_name, struct VS_TAG_BROWSE_INFO (&all_choices)[], 
                             boolean quiet, boolean final_find, struct VS_JAVA_IMPORT_INFO (&import_hash):[],
                              VS_TAG_BROWSE_INFO cur_sym)
{
   int i;
   _str import_name="";
   symbol_type_name = "";
   found_matching_symbol = false; // Found a symbol that exactly matches the symbol under the cursor?

   boolean in_java_lang_package = false;
   boolean in_same_package = false;
   boolean not_visible= false;

   VS_TAG_BROWSE_INFO duplicate_hash:[]=null;

   // Throw out any choices that do not exactly match the symbol under the cursor, choices that
   // are not classes, are of the same package as this file or are not members of the java.lang package
   struct VS_TAG_BROWSE_INFO refined_choices[]=null;
   for(i=0; i < all_choices._length(); i++) {

      if(symbol_name == all_choices[i].member_name) {
         found_matching_symbol = true;

         int last_slash_pos = lastpos("/", all_choices[i].class_name);
         _str pack = '';
         if (last_slash_pos > 0 && all_choices[i].type_name != 'class') {
            pack = substr(all_choices[i].class_name, 1, last_slash_pos-1);
         } else {
            pack = all_choices[i].class_name;
         }

         // Don't include choices that are from the java.lang package since it is
         // always imported implicitly.
         if(pack == 'java.lang' || pack == 'java/lang' || all_choices[i].class_name == 'java/lang' || 
            all_choices[i].class_name == 'java.lang') {

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
               return '';
            }

            in_java_lang_package = true;
            continue;
         }

         if((all_choices[i].type_name == 'class' || all_choices[i].type_name == 'interface' || 
             all_choices[i].type_name == 'annotype' || all_choices[i].type_name == 'enum' )) {

            // Don't consider classes in the same package.
            if(all_choices[i].class_name == this_file_package_name) {
               in_same_package = true;
               continue;
            }

            // Don't consider classes outside of our package that only have package visibility
            if((all_choices[i].flags & VS_TAGFLAG_access) == VS_TAGFLAG_package) {
               not_visible = true;
               continue;
            } 
            
            // Is this class defined in this file?
            if(all_choices[i].file_name == p_buf_name) {
               in_same_package = true;
               continue;
            }
   
            // Must be an inner class if it has slashes in it.
            int slash_pos = pos("/", all_choices[i].class_name);
            if(slash_pos != 0) {
               // Grab everything before the first /. This should be the package name
               if(all_choices[i].class_name == this_file_package_name) {
                  in_same_package = true;
                  continue;
               }

               // Make it a java compatible class name. 
               all_choices[i].class_name = stranslate(all_choices[i].class_name, ".", "/");
            }

            // Check to see if a fully qualified import already exists for this symbol.
            // If so then make it the only possible choice. This is so the user does not
            // keep having to make the choice over and over again
            _str hash_key = all_choices[i].class_name :+ '.' :+ all_choices[i].member_name;
            if(import_hash:[hash_key]._isempty() == false) {
               if(quiet == false) {
                  _message_box("Add Import: symbol '"import_name"' already imported");
               }
               if (cur_sym.type_name == "annotation" && all_choices[i].type_name == "annotype" || 
                     cur_sym.type_name != "annotation") {
                  refined_choices._makeempty();
                  refined_choices[refined_choices._length()] = all_choices[i];
                  symbol_type_name=all_choices[i].type_name;
               }
               break;
            }

            // If the name doesn't exist in our hash then add it to the refined list
            if( duplicate_hash._isempty() || duplicate_hash._indexin(hash_key) == 0 ) {
               // DJB 11-17-2005
               // Skip this choice if there was already an implicitely included choice
               if (in_same_package) continue;
               // RGH 3-3-2008
               // Skip this choice if there is already a class in java.lang 
               if (in_java_lang_package) continue;
               // Add this choice to our list of choices. It passed all the tests.
               if (cur_sym.type_name == "annotation" && all_choices[i].type_name == "annotype" || 
                     cur_sym.type_name != "annotation") {
                  refined_choices[refined_choices._length()] = all_choices[i];
                  duplicate_hash:[hash_key] = all_choices[i];
               }
            }
         }
         symbol_type_name=all_choices[i].type_name;
      }
   }

   // Could not find a choice. There could be
   // a couple reasons that this would happen   
   if(quiet == false && refined_choices._length() == 0) {
      if(in_java_lang_package == true) {
         _message_box("Add Import: '"symbol_name"' is in the java.lang package which is imported automatically. No import statement is needed.");
      } else if(in_same_package == true) {
         _message_box("Add Import: '"symbol_name"' is in the same package as this file. No import statement needed.");
      } else if(not_visible) {
         _message_box("Add Import: '"symbol_name"' has default access and is not visible. No import statement added.");
      } else if(final_find) {
         _message_box("Add Import: '"symbol_name"' is not a class.");
      }
      return "";
   }

   // If more than one refined_choice remains then ask the user to choose
   // the appropriate one.
   if(refined_choices._length() == 1) {
      import_name = refined_choices[0].class_name :+ '.' :+ refined_choices[0].member_name;
      symbol_type_name=refined_choices[0].type_name;
   } else if(refined_choices._length() > 1) {
      // Build list of package.class choices for user to pick from.
      _str choices[]=null;
      for(i=0; i < refined_choices._length(); i++) {
         choices[i] = refined_choices[i].class_name :+ '.' :+ refined_choices[i].member_name;
         symbol_type_name=refined_choices[i].type_name;
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

   }


   return import_name;
}

static boolean add_import(_str this_file_package_name, 
                          _str (&imports)[], 
                          VS_JAVA_IMPORT_INFO (&import_hash):[], 
                          struct VS_TAG_BROWSE_INFO &cm, 
                          struct VS_TAG_BROWSE_INFO (&choices)[], 
                          boolean quiet, boolean doing_full_file, 
                          int max_seek_position_imports,
                          VS_TAG_RETURN_TYPE (&visited):[]=null
                          )
{
   int i, result;
   struct VS_JAVA_IMPORT_INFO import_info;
   _str import_name="";

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // Try to find the import name for the symbol under the cursor.
   _str type_name;
   boolean found_matching_symbol=false;
   import_name = find_import_name(this_file_package_name, type_name, found_matching_symbol, cm.member_name, choices, quiet, false, import_hash, cm);

   
   
   // If not doing full file then check to see if there is an already
   // existing wildcard import that this new import would fit into
   // and don't add the import in that case.
   if(doing_full_file==false) {
      for(i = 0 ; i < imports._length(); i++) {
         int wildcard = pos("*", imports[i]);
         int lpos = lastpos('.', import_name);

         if(wildcard >= 3) {
            if(substr(imports[i], 1, wildcard-2) == substr(import_name, 1, lpos-1)) {
               // Founding matchng wildcard import. Bail out.
               if(quiet == false) {
                  _message_box("Add Import: symbol '"import_name"' already imported");
               }
               // This import is used by at least one reference in the file.
               import_hash:[imports[i]].used = true;
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
   if(doing_full_file == false && found_matching_symbol==true && (type_name=='param' || type_name=='lvar' || type_name=='var')) {

      // Find the match information for this symbol. This is to get the
      // the type of this variable. TestClass aVar with the cursor on aVar
      // should get the name TestClass.
      tag_update_context();
      num_matches := 0;
      max_matches := def_tag_max_find_context_tags;
      _str tag_files[] = tags_filenamea();
      tag_push_matches();
      tag_list_symbols_in_context(cm.member_name, "", 0, 0, tag_files, '',
                                  num_matches, max_matches, 
                                  VS_TAGFILTER_ANYTHING, VS_TAGCONTEXT_ANYTHING, 
                                  true, true, visited, 0);

      // Find the class name of this variable.
      _str match_name,var_class = "";
      for(i = 0; i < num_matches; i++) {
         tag_get_detail2(VS_TAGDETAIL_match_name, i, match_name);
         tag_get_detail2(VS_TAGDETAIL_match_return, i, var_class);
         if(match_name == cm.member_name) {
            break;
         }
      }
      tag_pop_matches();

      // If the class name is found then move the cursor to that definition
      // and redo get_browse_info and find_import_name steps.
      if(var_class != "") {
         typeless position;
         save_pos(position);

         // Start search after any existing package specifier or imports.
         _GoToROffset(max_seek_position_imports);

         // Search for the class of the variable in the file.
         if(search(var_class,'@h') == 0) {
            result = tag_get_browse_info("", cm, true, choices, true, true, true, false, false, false, visited);
            import_name = find_import_name(this_file_package_name, type_name, found_matching_symbol, var_class, 
                                           choices, quiet, true, import_hash, cm);
         }
         restore_pos(position);
      }
   }

   // Get the package for this import name. If it
   // does not have a package then it cannot be an import.
   _str package = "";
   int last_dot = lastpos('.', import_name);
   if(last_dot > 0) {
      package = substr(import_name, 1, last_dot-1);
   }

   // Add new import if needed
   if(import_name != "" && package != "" && (type_name=='class' || type_name=='interface' || type_name =='annotype'
                                             || type_name == 'enum') && !import_exists(import_name, imports, import_hash)) {
      // Figure out the current newline
      _str file_eol = p_newline;

      // Add new import to list and hash table;
      imports[imports._length()] = import_name;
      import_info.name = import_name;

      // Embedded Java (JSP?) If so then write out import in JSP format
      if(strieq(p_EmbeddedLexerName,'java')) {
         import_info.text = "<%@ page import=\"" :+ import_name :+ "\"%>" :+ file_eol;    
      } else {
         import_info.text = "import " :+ import_name :+ ';' :+ file_eol;
      }
      import_info.start_seekpos = 0;
      import_info.end_seekpos = 0;
      import_info.package = package;
      import_info.used = true;
      import_hash:[import_info.name] = import_info;
      return true;
   }

   return false;
}


int get_curword_color()
{
   int start_col=0, orig_col = p_col;

// cur_word(start_col,'',true,false);
   start_col = p_col-1;

   p_col=start_col;

   int color = _clex_find(0,'g');

   // Restore the position to the end of the word
   p_col = orig_col;
   return color;
}

/**
 * Organize the imports for the the current buffer
 * 
 * @return 
 */
_command int jrefactor_organize_imports() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str current_db = tag_current_db();
   _str symbols_processed:[];
   struct VS_JAVA_IMPORT_INFO import_hash:[];
   _str imports[], file_name;
   typeless cursorSeekPos;
   int i, min_seek_position, max_seek_position;

   // Did tagging fail to find a symbol? If tagging failed for a symbol and their
   // are unused imports after finishing the file then inform the user of the problem
   // and don't delete unused imports. This is to fix a problem where users are using libraries
   // that are not tagged and organize imports was blowing away existing imports that were
   // actually used.
   tagging_failure = false;

   int wid = p_window_id;

   // Check to see if occurrences need to be retaggged before
   // showing the cancel form. Bad interactions can happend
   // when the retag and cancel forms are up at the same time.
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   show_cancel_form("Organizing Imports", "", true, true);

   // Save current cursor position
   _save_pos2(cursorSeekPos);

   // Get any imports that are already in the file.
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   get_existing_imports(imports, import_hash, min_seek_position, max_seek_position);

   // Get the package name for this file.
   int end_of_package_name_pos=0;   
   _str package_name = get_package_name_for_current_buffer(end_of_package_name_pos);
   _str prevword="";
   // Start at end of imports and process all symbols in the file..
   _GoToROffset(max_seek_position);

   _str tag_files[] = tags_filenamea();
   struct VS_TAG_RETURN_TYPE visited:[];

// say("===============================");
// say("Organize imports");
// say("===============================");

   int start_col;
   _str curword = cur_word(start_col, "", false, true );
   _str unmatched_symbols[];
   while(curword!="") {
      int cur_flags=0, cur_type_id=0;
      _str cur_tag_name='', cur_type_name='', cur_context='', cur_class='', cur_package='';

      int cfg = get_curword_color();
      if(cfg == CFG_KEYWORD || cfg == CFG_COMMENT || cfg == CFG_STRING) {
         c_next_sym();
         prevword = curword;
         curword = c_get_syminfo();
         continue;
      }

      // Only process words that have not previously been processed and words
      // that look like valid identifiers. Don't try to find an import for any symbol
      // that is preceded by a . because that symbol already has a scope.
      if(symbols_processed:[curword]._isempty() && is_valid_identifier(curword) && prevword != '.') {
         symbols_processed:[curword] = 1;

//       say("curword = "curword);

         struct VS_TAG_BROWSE_INFO cm, choices[]=null;
         int result = tag_get_browse_info("", cm, true, choices, true, true, true, false, false, false, visited);
         
         // Did the match come from a Java file?
         if (cm.language=="" && cm.tag_database != "") {
            orig_tag_file := tag_current_db();
            if (tag_read_db(cm.tag_database) >= 0) {
               tag_get_language(cm.file_name, cm.language);
            }
            tag_read_db(orig_tag_file);
         }
         if (cm.language=="") cm.language=_Filename2LangId(cm.file_name);
         if (result == 0 && cm.language != "java") {
            // If not, force a tagfile search
            result = tag_get_browse_info("", cm, true, choices, true, true, true, false, true, false, visited);
         }

         // Is this a valid symbol?
         if(result == 0 && cm.member_name !="" && choices != null) {
            curword = cm.member_name;
            for(i = 0; i < choices._length(); i++) {
               // Process only symbols that exactly match the current word, and are interfaces or
               // classes.
               if(curword == choices[i].member_name && (choices[i].type_name == 'interface' || choices[i].type_name == 'class'
                                                        || choices[i].type_name == 'enum')) {
                  add_import(package_name, imports, import_hash, cm, choices, true, true, max_seek_position, visited);
                  break;
               }
            }
         } else if(result != 0) {
            tagging_failure = true;
            unmatched_symbols[unmatched_symbols._length()] = curword;
         }
      }

      // Manage progress bar and cancel button.
      static boolean canceled;
      process_events( canceled );
      if(cancel_form_cancelled()) {
         // Move cursor back to original position
         close_cancel_form(cancel_form_wid());
         wid._restore_pos2(cursorSeekPos);
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
   update_imports(imports, import_hash, min_seek_position, max_seek_position, end_of_package_name_pos, true,
                     unmatched_symbols);

   // Move cursor back to original position
   _restore_pos2(cursorSeekPos);

   close_cancel_form(cancel_form_wid());

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
_command int jrefactor_add_import(boolean quiet=false, struct VS_TAG_BROWSE_INFO cm=null, _str filename=null) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   boolean need_temp_view=false;
   struct VS_TAG_BROWSE_INFO choices[];
   struct VS_JAVA_IMPORT_INFO import_hash:[], import_info;
   _str curword, imports[], import_name="";
   int i, min_seek_position, max_seek_position, cursorSeekPos;

   int editorctl_wid = p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid = _mdi.p_child;
   }
   editorctl_wid._UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = editorctl_wid.tag_current_context();
   _str type_name;
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   if (type_name :== "import") {
      return(0);
   }

   // Get symbol to add import for from cursor
   // Set up cm and filename according to information from symbol under
   // the cursor.
   if(cm == null) {
      if(_isdiffed(p_buf_id)) {
         if(quiet == false) {
            _message_box("Add Import: not allowed while the file is being diffed");
         }
         return -1;
      }

      // If in JSP but auto import is turned off then don't add the import
      if(strieq(p_EmbeddedLexerName,"java") && def_jrefactor_auto_import_jsp==0) {
         return -1;
      }

      // Stop if we are in a comment or string
      int cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         if(quiet == false) {
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
      int start_col=0;
      curword = cur_identifier(start_col);
      restore_pos(p);
      if(!is_valid_identifier(curword)) {
         if(quiet == false) {
            _message_box("Add Import: '"curword"' is not a valid identifier");
         }
         return -1;
      }

      // The current word might be at a different place then where the cursor is. This means
      // the above inside string check may not work because the cursor may not be in a string
      // but the current word is in a string so move the column to the start of the curword and
      // check there as well for whether we are in a string or not.
      int curr_col=p_col;
      p_col = start_col;
      cfg=_clex_find(0,'g');
      p_col = curr_col;
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         if(quiet == false) {
            _message_box("Add Import: not allowed in a comment or string");
         }
         return -1;
      }
   
      // Stop if doing auto-import (quiet) and this identifier does
      // not start with a capital letter (like a class is expected to)
      if (quiet && upcase(substr(curword,1,1)) != substr(curword,1,1) &&
          !def_jrefactor_auto_import_lowcase_identifiers) {
         return -1;
      }
 
      VS_TAG_RETURN_TYPE visited:[];
      int status = tag_get_browse_info("", cm, quiet, choices, true, true, true, false, false, false, visited);

      // Did the match come from a Java file?
      if (cm.language=="" && cm.tag_database != "") {
         orig_tag_file := tag_current_db();
         if (tag_read_db(cm.tag_database) >= 0) {
            tag_get_language(cm.file_name, cm.language);
         }
         tag_read_db(orig_tag_file);
      }
      if (cm.language=="") cm.language=_Filename2LangId(cm.file_name);
      if (status == 0 && cm.language != "java") {
         // If not, force a tagfile search
         status = tag_get_browse_info("", cm, true, choices, true, true, true, false, true, false, visited);
      }

      if(status < 0) {
         if(quiet == false && status != COMMAND_CANCELLED_RC) {
            _message_box("Add Import: not a valid symbol");
         }
         return status;
      }
   
      // Stop if the current symbol does not look like a valid keyword.
      curword = cm.member_name;
      if(!is_valid_identifier(curword)) {
         if(quiet == false) {
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
   int temp_view_id=0, orig_view_id=0;
   if(need_temp_view) {
      orig_view_id=p_window_id;
      int status=_open_temp_view(filename, temp_view_id, orig_view_id);
      if (status) {
         p_window_id=orig_view_id;
         mou_hour_glass(0);
         return status;
      }
      p_window_id=temp_view_id;
   } else {
      // Save current cursor position
      _save_pos2(cursorSeekPos);
   }

   // Get any imports that are already in the file.
   _UpdateContext(true);   
   get_existing_imports(imports, import_hash, min_seek_position, max_seek_position);

   // Get the package name for this file.
   int end_of_package_name_pos=0;   
   _str package_name = get_package_name_for_current_buffer(end_of_package_name_pos);

   struct VS_TAG_RETURN_TYPE visited:[];
   boolean need_to_add_import = add_import(package_name, imports, import_hash, cm, choices, quiet, false, max_seek_position, visited);

   // Replace existing imports with new organized imports
   if(need_to_add_import) {
      update_imports(imports, import_hash, min_seek_position, max_seek_position, end_of_package_name_pos, false);
      sticky_message("Added import for '" curword"'");
   }

   if(need_temp_view) {
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   } else {
      // Move cursor back to original position
      _restore_pos2(cursorSeekPos);
   }

   return 0;
}

/**
 * Open the organize imports options dialgo
 * 
 * @return 
 */
_command int jrefactor_organize_imports_options()
{
   int orig_wid = p_window_id;

   result := config('_jrefactor_organize_imports_form', 'D');
   p_window_id = orig_wid;
   return result;
}

defeventtab _jrefactor_organize_imports_form;


#region Options Dialog Helper Functions

void _jrefactor_organize_imports_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
   ctl_help.p_visible = false;
}

boolean _jrefactor_organize_imports_form_is_modified()
{
   if(def_jrefactor_imports_per_package != ctl_import_limit.p_text) return true;
   if(def_jrefactor_depth_to_add_space != ctl_add_lines.p_text) return true;
   if(def_jrefactor_auto_import != ctl_auto_import.p_value) return true;
   if(def_jrefactor_auto_import_jsp != ctl_auto_import_jsp.p_value) return true;

   // Recreate prefix list.
   newList := "";   
   prefix_index := ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while(prefix_index != -1) {
      strappend(newList, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(newList, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }
   if(def_jrefactor_prefix_list != newList && def_jrefactor_prefix_list != substr(newList, 1, length(newList) - 1)) return true;

   if(def_jrefactor_add_blank_lines != (ctl_add_blank_lines.p_value != 0)) return true;

   return false;
}

boolean _jrefactor_organize_imports_form_apply()
{
   int value;
   // Save out current settings. Don't bother to set the def vars if the input is garbage
   if(isinteger(ctl_import_limit.p_text)) {
      value = (int)ctl_import_limit.p_text;
      if(value >= 0) {
         def_jrefactor_imports_per_package = (int)ctl_import_limit.p_text;
      }
   }

   // Don't bother to set the def vars if the input is garbage
   if(isinteger(ctl_add_lines.p_text)) {
      value = (int)ctl_add_lines.p_text;
      if(value >= 0) {
         def_jrefactor_depth_to_add_space = (int)ctl_add_lines.p_text;
      }
   }
   def_jrefactor_auto_import = ctl_auto_import.p_value;
   def_jrefactor_auto_import_jsp = ctl_auto_import_jsp.p_value;

   // Recreate prefix list.
   def_jrefactor_prefix_list = "";   
   int prefix_index = ctl_package_sort_order._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while(prefix_index != -1) {
      strappend(def_jrefactor_prefix_list, ctl_package_sort_order._TreeGetCaption(prefix_index));
      strappend(def_jrefactor_prefix_list, ";");
      prefix_index = ctl_package_sort_order._TreeGetNextSiblingIndex(prefix_index);
   }

   if(ctl_add_blank_lines.p_value != 0) {
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
   ctl_auto_import.p_value = def_jrefactor_auto_import;
   ctl_auto_import_jsp.p_value = def_jrefactor_auto_import_jsp;

   if(def_jrefactor_add_blank_lines == true) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }

   _str prefix, prefix_list = def_jrefactor_prefix_list;
   while(prefix_list != "") {
      parse prefix_list with prefix ';' prefix_list;
      ctl_package_sort_order._TreeAddItem(TREE_ROOT_INDEX, prefix, TREE_ADD_AS_CHILD, 0, 0, -1);
   }
}

void ctl_add_blank_lines.lbutton_up()
{
   if(ctl_add_blank_lines.p_value != 0) {
      ctl_add_lines.p_enabled = true;
   } else {
      ctl_add_lines.p_enabled = false;
   }
}

void ctl_ok.lbutton_up()
{
   if(_jrefactor_organize_imports_form_apply()) {
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
   int current_selection = ctl_package_sort_order._TreeCurIndex();
   if(current_selection != TREE_ROOT_INDEX) {
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
   if(ctl_package_sort_order._TreeSearch(TREE_ROOT_INDEX, prefix_name) != -1) {
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
   if(!embeddedInOptions) {
      // if the minimum width has not been set, it will return 0
      if (!_minimum_width()) {
         _set_minimum_size(button_width*6, button_height*14);
      }
   }

   // determine how much we've resized in height by looking at the bottommost control
   deltaY := p_height - (ctl_package_sort_order_frame.p_y + ctl_package_sort_order_frame.p_height + vert_margin);
   if(!embeddedInOptions) {
      deltaY = p_height - (ctl_ok.p_y + ctl_ok.p_height + vert_margin);
      ctl_ok.p_y     += deltaY;
      ctl_cancel.p_y += deltaY;
      ctl_help.p_y   += deltaY;
   }
   deltaX := p_width - (ctl_package_sort_order_frame.p_x + ctl_package_sort_order_frame.p_width + 2 * horz_margin);

   ctl_package_sort_order_frame.p_height += deltaY;
   ctl_package_sort_order.p_height += deltaY;

   ctl_package_sort_order_frame.p_width += deltaX;
   ctl_add.p_x = ctl_up.p_x = ctl_down.p_x = ctl_delete.p_x += deltaX;

   ctl_package_sort_order.p_width += deltaX;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _jrefactor_organize_imports_form_initial_alignment()
{
   rightAlign := ctl_package_sort_order_frame.p_width - ctl_package_sort_order.p_x;
   alignUpDownListButtons(ctl_package_sort_order, rightAlign, ctl_add, ctl_up, ctl_down, ctl_delete);
}

/**
 * Add oi menu items to the specified menu
 *
 * @param menuHandle Handle of parent menu
 * @param cmdPrefix  Prefix of command.  Empty for MDI menu or editor control right click menu
 * @param cm         Information about the tag that is currently selected
 * @param removeIfDisabled
 *                   Remove the oi submenu if disabled and this is true
 */
void addOrganizeImportsMenuItems(int menuHandle, _str cmdPrefix, struct VS_TAG_BROWSE_INFO cm = null,
                             boolean removeIfDisabled = true, _str currentBuffer="")
{
   // find oi menu placeholder
   int oiMenuHandle;
   int oiMenuIndex = _menu_find_loaded_menu_category(menuHandle, "organize_imports", oiMenuHandle);
   if(oiMenuIndex < 0) {
      return;
   }

   // load oi menu template
   int index = find_index("_organize_imports_menu", oi2type(OI_MENU));
   if(index <= 0) {
      return;
   }
   int oiTemplateHandle = _menu_load(index, 'P');
   if(oiTemplateHandle < 0) {
      return;
   }
   // if cm is null or this is not a 'c' extension, remove the oi
   // if requested
   if(removeIfDisabled && (cm == null || !_LanguageInheritsFrom('java', _Filename2LangId(cm.file_name)))) {
//      boolean hasSeparatorBefore = false;
//      boolean hasSeparatorAfter = false;

//      _str sepCaption;
//      int mfflags;

      // check for separator before
//      if(oiMenuIndex > 0) {
//         if(!_menu_get_state(menuHandle, oiMenuIndex - 1, mfflags, 'P', sepCaption)) {
//            if(sepCaption == '-') {
//               hasSeparatorBefore = true;
//            }
//         }
//      }

      // check for separator after
//      if(!_menu_get_state(menuHandle, oiMenuIndex + 1, mfflags, 'P', sepCaption)) {
//         if(sepCaption == '-') {
//            hasSeparatorAfter = true;
//         }
//      }

      // remove oi submenu
      _menu_delete(menuHandle, oiMenuIndex);

      // remove trailing separator if there is also one before
//      if(hasSeparatorAfter) {
//         if(oiMenuIndex == 0 || hasSeparatorBefore) {
//            _menu_delete(menuHandle, oiMenuIndex);
//         }
//      }

      return;
   }

   boolean enableOrganizeImports=false;
   if(cm != null) {
      _str lang = _Filename2LangId(cm.file_name);
      if (_LanguageInheritsFrom('java', lang)) {

         if(tag_tree_type_is_class(cm.type_name) == 1 && _get_extension(currentBuffer, false) == 'java') {
            enableOrganizeImports = true;
         }
      } 
   }

   // the format of the command depends on where the oi menu is being
   // shown from.  if cmdPrefix is empty, this is the main mdi menu or the
   // right click menu in an editor control.  for these, just use the normal
   // 'refactor_NAME' syntax.  if there is a command prefix, this is coming
   // from the proctree or symbol browser, so use the format 'PREFIX_refactor NAME'.
   //
   // each oi should use its category as its command suffix.  for
   // example:
   //
   //   oi   category   command           prefixed-command
   //   ------------------------------------------------------------------------------
   //   rename        rename     refactor_rename   prefix_refactor rename
   //

   _str cmd = "_jrefactor ";

   // bar
   addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "organize_imports_options", cmdPrefix, cmd, 0, enableOrganizeImports);
   addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "bar", cmdPrefix, cmd, 0, true);
   addSpecificRefactoringMenuItem(oiMenuHandle, oiTemplateHandle, "add_import", cmdPrefix, cmd, 0, enableOrganizeImports);
 
   // cleanup oi menu template
   _menu_destroy(oiTemplateHandle);
}
