////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49815 $
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
#include "quickrefactor.sh"
#include "refactor.sh"
#include "tagsdb.sh"
#include "cbrowser.sh"
#include "diff.sh"
#include "scc.sh"
#include "color.sh"
#import "alias.e"
#import "beautifier.e"
#import "c.e"
#import "caddmem.e"
#import "cformat.e"
#import "codehelp.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "refactor.e"
#import "setupext.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tags.e"
#import "util.e"
#import "vc.e"
#import "xmldoc.e"
#import "se/tags/TaggingGuard.e"
#endregion

/**
 * This module implements our support for quick (tagging based)
 * refactoring.
 *
 * @since  11.0
 */

//////////////////////////////////////////////////////////
// Utility functions used by multiple refactorings
///////////////////////////////////////////////////////// 

/**
 * Rename a symbol and adjust all references.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_quick_rename(_str precise='') name_info(FILE_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   // get browse information for the tag under the symbol
   VS_TAG_RETURN_TYPE visited:[];
   struct VS_TAG_BROWSE_INFO cm;
   int status = tag_get_browse_info("", cm, false, null, false, true, true, false, false, false, visited);
   if (status == COMMAND_CANCELLED_RC) return status;
   if (status < 0) {
      //_message_box("Rename failed: ":+get_message(status), "Rename Refactoring");
      return status;
   }
   
   // use precise refactor_rename?
   if (!def_disable_cpp_refactoring && precise=="precise" && 
       _LanguageInheritsFrom('c', cm.language)) {

      // init refactoring operations
      if (!refactor_init()) return COMMAND_CANCELLED_RC;

      // tag_get_browse_info() returns information about where the
      // symbol is defined, not necessarily the location where the cursor
      // is now.  therefore, the current file and seek position should
      // also be passed to refactor_rename_symbol()
      _str symbolName = "";
      int i,seekPosition = 0;
      getSymbolInfoAtCursor(symbolName, seekPosition);

      // call common rename function
      return refactor_rename_symbol(cm, "", p_buf_name, seekPosition, 0, visited);
   }

   // call quick rename function
   return refactor_quick_rename_symbol(cm, visited, p_identifier_chars);
}


/**
 * 
 * @param cm
 * @param fileList
 * @param tag_files
 * @param i
 * @param n
 * 
 * @return int
 */
int refactor_get_quick_file_list(_str (&fileList)[], _str (&tag_files)[], _str symbol_name)
{
   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   // iterate though all these files
   int count=0;
   int i, n = tag_files._length();
   for (i=0; i<n; ++i) {

      // open the tagfile
      int status = tag_read_db(tag_files[i]);
      if (status < 0) continue;

      // build list of files to check
      status = tag_find_occurrence(symbol_name, true, true);
      while (!status) {

         // find the files containing references
         _str occurName, occurFilename;
         tag_get_occurrence(occurName, occurFilename);
         if (fileList._length()==0 || !file_eq(fileList[0], occurFilename)) {
            fileList[fileList._length()] = occurFilename;
         }

         // next please
         status = tag_next_occurrence(symbol_name, true, true);
      }
      tag_reset_find_occurrence();
   }

   // success!
   return 0;
}

/**
 * Calculate the start end search seek positions for finding 
 * references to the given symbol. 
 * 
 * @param cm                  symbol information
 * @param func_start_seekpos  [output] start seek position of 
 *                            enclosing function
 * @param func_end_seekpos    [output] end seek position of 
 *                            enclosing function.
 * 
 * @return 0 on success, <0 on error.
 */
int refactor_get_symbol_scope(struct VS_TAG_BROWSE_INFO cm,
                              int &func_start_seekpos, int &func_end_seekpos)
{
   // initialize start and end seekpositions to defaults
   func_start_seekpos = func_end_seekpos = 0;

   // do we not have the seek position for this symbol?
   if (cm.seekpos <= 0) {
      return 0;
   }

   // the symbol must be a local variable, parameter, or label
   if (cm.type_name != "lvar" && cm.type_name!="param" && cm.type_name!="label") {
      return 0;
   }

   // the symbol has to come from somewhere
   if (cm.file_name == null || cm.file_name == "" ) {
      return FILE_NOT_FOUND_RC;
   }

   // and it can not be from a DLL or ZIP file
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return 0;
   }

   // open the file in a temp view
   alreadyExists := false;
   tempViewID := origViewID := 0;
   status := _open_temp_view(cm.file_name, tempViewID, origViewID, "", alreadyExists, false, true);
   if (status < 0) {
      return status;
   }

   // for local variables and function parameters, restrict scope of search to current function
   _UpdateContext(true);
   save_pos(auto p);
   func_start_seekpos = cm.seekpos;
   for (;;) {
      _GoToROffset(func_start_seekpos);
      context_id := tag_current_context();
      if (context_id <= 0) {
         func_end_seekpos = 0;
         if (cm.type_name == "label") func_start_seekpos = 0;
         break;
      }
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, func_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, func_end_seekpos);
      if (func_start_seekpos <= cm.seekpos && func_end_seekpos >= cm.end_seekpos) {
         break;
      }
      func_start_seekpos--;
   }
   restore_pos(p);

   // cleanup
   _delete_temp_view(tempViewID);
   p_window_id = origViewID;
   return 0;
}

int refactor_quick_rename_symbol(struct VS_TAG_BROWSE_INFO cm,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, _str id_chars="")
{
   // init refactoring operations
   if (!refactor_init(true, false)) {
      return COMMAND_CANCELLED_RC;
   }

   // Canceled rename
   _str newName = show('-modal _refactor_quick_rename_form', cm.member_name, id_chars);
   if ( newName == '' ) {
      return 0;
   }

   // begin the refactoring transaction
   int handle = refactor_begin_transaction();
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   // rename the symbol
   show_cancel_form("Refactoring", "", true, true);

   // always add the file that contains the tag
   _str fileList[]; fileList._makeempty();
   fileList[fileList._length()] = cm.file_name;

   // get all the tag files for our extension
   // do not do this for locals and private class members in Java
   status := 0;
   func_start_seekpos := func_end_seekpos := 0;
   if (cm.type_name != "lvar" && cm.type_name != "param" &&
       !((cm.flags & VS_TAGFLAG_access) == VS_TAGFLAG_private && _get_extension(cm.file_name)=="java")) {

      _str tag_files[] = tags_filenamea(cm.language);
      status = refactor_get_quick_file_list(fileList, tag_files, cm.member_name);
      if (status < 0) {
         close_cancel_form(cancel_form_wid());
         refactor_cancel_transaction(handle);
         return status;
      }
   } else {
      refactor_get_symbol_scope(cm, func_start_seekpos, func_end_seekpos);
   }

   // close this cancel form
   close_cancel_form(cancel_form_wid());

   // if the file count is high enough, show progress dialog
   int progressFormID = show_cancel_form("Finding files that reference '" cm.member_name "'", null, true, true);

   // iterate over the file list, making sure they really refer to the object
   int i,n = fileList._length();
   for (i=0; i<n; i++) {
      // open a temp view for this file
      int tempViewID = 0;
      int origViewID = 0;
      boolean alreadyExists = false;
      status = _open_temp_view(fileList[i], tempViewID, origViewID, "+d", alreadyExists, false, true);
      if(status < 0) continue;

      // show this file going through
      _SccDisplayOutput("Parsing:  \""fileList[i]"\"", false);

      // find all the references to this tag
      int seekPositions[]; seekPositions._makeempty();
      _str errorArgs[]; errorArgs._makeempty();
      int maxReferences = def_cb_max_references;
      int numReferences = 0;
      tag_match_occurrences_in_file_get_positions(errorArgs, seekPositions,
                                                  cm.member_name, p_EmbeddedCaseSensitive,
                                                  cm.file_name, cm.line_no,
                                                  VS_TAGFILTER_ANYTHING, 
                                                  func_start_seekpos, func_end_seekpos,
                                                  numReferences, maxReferences, visited);
      // go through the file backwards
      int j,m = seekPositions._length();
      for (j=m-1; j>=0; --j) {

         // go to the seek position
         status = _GoToROffset(seekPositions[j]);
         if (status < 0) continue;

         _delete_text(length(cm.member_name));
         _insert_text(newName);
      }

      // if the symbol is a param, try to update the corresponding javadoc comment
      if (cm.type_name == 'param' && n == 1) {
         refactor_quick_rename_update_javadoc(cm, newName);
      }

      // Did we make any changes?
      if (seekPositions._length() > 0) {

         // add the file to the transaction
         refactor_add_file(handle, fileList[i], '', '', '', '');
         refactor_set_file_encoding(handle, fileList[i], _EncodingToOption(p_encoding));

         // save the file contents
         refactor_set_modified_file_contents(p_window_id, handle, fileList[i]);
      }
      
      // cleanup
      _delete_temp_view(tempViewID);
      p_window_id = origViewID;

      // if there is a progress form, update it
      cancel_form_progress(progressFormID, i, fileList._length());
      if (cancel_form_cancelled()) {
         // empty file list
         status = COMMAND_CANCELLED_RC;
         break;
      }
   }

   // kill progress form
   if(progressFormID) {
      close_cancel_form(progressFormID);
   }

   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      return status;
   } else if (status < 0) {
      _message_box("Failed renaming symbol '" :+ cm.member_name :+ "':  ":+get_message(status), "Rename Refactoring");
   }

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, 
                                          "Failed to rename symbol.", 
                                          "Quick rename "cm.member_name" => "newName, 
                                          cm.file_name);
   return 0;
}

void refactor_quick_rename_update_javadoc(VS_TAG_BROWSE_INFO cm, _str newName)
{
   _save_pos2(auto p);
   // find the comment
   _do_default_get_tag_header_comments(auto first_line, auto last_line);
   if (first_line <= 0 || last_line <= 0) {
      _restore_pos2(p);
      return;
   }
   // get the comment flags
   int status =_GetCurrentCommentInfo(auto comment_flags,auto orig_comment, auto return_type, 
      auto slcomment_start, auto blanks, auto doxygen_comment_start);
   if (orig_comment == '' || status) {
      _restore_pos2(p);
      return;
   }
   _str tagPrefix = '@';
   if (comment_flags & VSCODEHELP_COMMENTFLAG_DOXYGEN) {
      tagPrefix = '\';
   } 
   // select the entire comment
   p_line=first_line;
   select_line();
   p_line=last_line;
   select_line();
   p_line=first_line;
   // search and replace on the param element in the selected comment
   search(tagPrefix'param ':+cm.member_name,'M',tagPrefix'param ':+newName);
   // deselect, return to the original position in the view, and done
   _deselect();
   _restore_pos2(p);
}

int _OnUpdate_refactor_quick_rename(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');
   if (clex_color!=CFG_WINDOW_TEXT && clex_color!=CFG_LIBRARY_SYMBOL && clex_color!=CFG_USER_DEFINED && clex_color!=CFG_FUNCTION) {
     return(MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command, false, true);
}

// deprecated, for backwards compability with 10.0 beta 1
_command int refactor_fast_rename(_str precise='') name_info(FILE_ARG',')
{
   return refactor_quick_rename(precise);
}

// deprecated, for backwards compability with 10.0 beta 1
int _OnUpdate_refactor_fast_rename(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_refactor_quick_rename(cmdui, target_wid, command);
}

/* TODO Extract Method quick refactoring

   -see if extracted code starts or ends in the middle of a statement. If so disallow the extraction.
   -check for returns and warn the user about them.
   -for the LHS code check to see if the local is passed to a function as a reference parameter for marking it as LHS.
   -Handle arrays.
   -Handle array reference parameters. Special syntax for each language( _str (&blah)[] for Slick-C.
   -Make language specific function call and function definition builders.
       * Java (Can't complete if more then one reference parameter(that has to be converted to a return value)
       * C++
       * Slick-C
   -Visual Basic support??
   -Detect the extraction of expression blocks?!?! and figure out the return type. Hard.
   -need to have extract dialog show the correct language specific function prototype.
   -detect break, continue statements
   -Need to pass nonprimitive types by const reference instead of by value for C
*/

#define BEFORE_EXTRACTED_CODE    1
#define INSIDE_EXTRACTED_CODE    2
#define AFTER_EXTRACTED_CODE     4

static void debug_regex(_str string_to_search, _str regex) 
{
   int p = pos(regex, string_to_search, 1, "U");
}

static boolean c_only_allowable_characters_between_local_and_operator(_str diff)
{
   // The characters between the operator and the local must only be in this set.
   return pos("[^*( )&\t\n\r\\]\\[]", diff, 1, "U") == 0;
}

// Pass in a string with equals and the character before and the character after. 
static boolean c_equals_is_assignment_operator(_str operator_string)
{
   // Could be left hand side of an assignment operator
   boolean assignment_operator=true;
   _str pre_operator = substr(operator_string, 1, 1);

   // Could this be a logical operator?
   switch(pre_operator) {
      case '<' : assignment_operator = false; break;
      case '>' : assignment_operator = false; break;
      case '!' : assignment_operator = false; break;
      // This can happen when iterating through all the = in the statement
      case '=' : assignment_operator = false; break;    
   }

   // == is not an assignment operator
   _str post_operator = substr(operator_string, 3, 1);
   switch(post_operator) {
      case '=' : assignment_operator = false; break;
   }

   return assignment_operator;
}

static _str get_line_leading_whitespace(_str text='', boolean including_newlines=false)
{
   if(text == '') {
      get_line(text);
   }
   // Grab leading whitespace
   _str leading_indention = ""; 
   int p;
   if(including_newlines) {
      p = pos("[^ \t\n\r]", text, 1, "U");
   } else {
      p = pos("[^ \t]", text, 1, "U");
   }
   if(p > 1) {
      leading_indention = substr(text, 1, p-1);
   }
   return leading_indention;
}

// Poor man's statement grab 
static _str c_get_statement(int &start_statement, _str &leading_comment_and_ws, _str &trailing_comment_and_ws)
{
   leading_comment_and_ws="";
   trailing_comment_and_ws="";

   int comment_flags;
   _str comments;

   // Grab any comments above statement or any line comments after end of statement.
   search(";","@h+<Xcs");
   int end_statement = (int)_QROffset();

   // Find the end of line after the semicolon
   search("$","@hrXcs");
   int end_of_line = (int)_QROffset();

   // Grab text after semicolon and before the end of line.
   _GoToROffset(end_statement+1);
   _str text = get_text(end_of_line-1-end_statement);

   // Move to before the semicolon that ends this statement.
   _GoToROffset(end_statement-1);

   trailing_comment_and_ws = text;

   // Search backwards for beginning of statement
   search("$","@hu-<Xcs");
   search("[^ \t]","@hu+<Xcs");
   start_statement = (int)_QROffset();

   int first_line, last_line;
   if(_do_default_get_tag_header_comments(first_line, last_line) == 0) {
      p_line = first_line;
      _begin_line();
      leading_comment_and_ws = get_text(start_statement-(int)_QROffset());
   } else {
      _begin_line();
      leading_comment_and_ws = get_text(start_statement-(int)_QROffset());
   }

   _GoToROffset(start_statement);
   _str statement_string = get_text(end_statement-start_statement+1);

//   say("    leading comment='"leading_comment_and_ws"'");
//   say("    trailing comment='"trailing_comment_and_ws"'");
//   say("    statement_string='"statement_string"'");

   return statement_string;
}

struct VS_TAG_REFERENCE_INFO 
{
   _str ref_name;          // Name of reference we care about in this expression/statement
   _str qualified_name;    // Name of reference we care about including prefix
   _str statement;         // String containing entire statement
   _str filename;          // File that contains this statement
   int  statement_start;   // Seek position of start of statement in the file.
   _str lhs;               // LHS side of expression involving this reference   
   _str rhs;               // RHS side of expression invloving this reference if any
   boolean modified;       // If this reference modified in this statement
   typeless array_index;   // Array index for this reference in this statement
   int start_id_seek;      // Seek position of start of full identifier 
   int end_id_seek;        // Seek position of end of full identifier including array part if an array.
};

void tag_reference_info_init(VS_TAG_REFERENCE_INFO &ref_info) 
{
   ref_info.ref_name='';
   ref_info.qualified_name='';
   ref_info.statement='';
   ref_info.filename='';
   ref_info.statement_start=0;
   ref_info.lhs='';
   ref_info.rhs='';
   ref_info.modified=false;
   ref_info.array_index='';
   ref_info.start_id_seek=0;
   ref_info.end_id_seek=0;
}

void tag_reference_info_dump(VS_TAG_REFERENCE_INFO ref_info, _str description="")
{
   int i;
   if(description != "") {
      say(description);
   }
   say("-------------------");
   say(ref_info.ref_name);
   say("-------------------");
   say("    qualified_name="ref_info.qualified_name);
   say("    statement="ref_info.statement);
   say("    filename="ref_info.filename);
   say("    statement_start="ref_info.statement_start);
   say("    lhs="ref_info.lhs);
   say("    rhs="ref_info.rhs);
   say("    modified="ref_info.modified);
   if(ref_info.array_index != null) {
      say("    array_index="ref_info.array_index);
   } else {
      say("    array_index= null");
   }
   say("    start_id_seek="ref_info.start_id_seek);
   say("    end_id_seek="ref_info.end_id_seek);
}

static boolean c_reference_is_modified(_str local_name, VS_TAG_REFERENCE_INFO &ref_info, 
                                       VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   tag_reference_info_init(ref_info);

   int offset = (int)_QROffset();
   
   _str leading_comment_and_ws, trailing_comment_and_ws;
   ref_info.statement = c_get_statement(ref_info.statement_start, leading_comment_and_ws, trailing_comment_and_ws);
   _GoToROffset(offset);

   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   status := _Embeddedget_expression_info(false, lang, idexp_info, visited, depth);
   if (status < 0) return false;

   ref_info.qualified_name = idexp_info.prefixexp :+ local_name;
   ref_info.start_id_seek = idexp_info.lastidstart_offset;
   ref_info.end_id_seek = idexp_info.lastidstart_offset + length(local_name); 
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET) {
      ref_info.array_index = idexp_info.otherinfo;

      // Find end of array following identifier
      if(search("]","@hXcs") == 0) {
         ref_info.end_id_seek = (int)_QROffset()+1;
      }
      _GoToROffset(offset);
   }

   int rhs_start = -1, start_pos = 1;
   boolean assigned=false;

   // Look for any assignment operator after the local_name
   int pos_equals = pos("=", ref_info.statement);
   int pos_local = pos(local_name, ref_info.statement);

   // Could be left hand side of an assignment operator
   while(pos_equals > 0) {
      _str equals_string = substr(ref_info.statement, pos_equals-1, 3);
      if(pos_equals > pos_local) {
         assigned = c_equals_is_assignment_operator(equals_string);
         rhs_start = pos_equals+1;
      }

      // Get next = operator
      start_pos = pos_equals+1;
      if(start_pos >= length(ref_info.statement)) break;
      pos_equals = pos("=", ref_info.statement, start_pos);
   }

   // Look for the pre/post increment operator before or after the local_name
   start_pos = 1;
   int pos_plusplus = pos("++", ref_info.statement, start_pos);
   while(pos_plusplus > 0) {
      _str diff = "";
      if(pos_plusplus < pos_local) {
         diff = substr(ref_info.statement, pos_plusplus+2, pos_local-pos_plusplus-2);
      } else if(pos_plusplus > pos_local) {
         diff = substr(ref_info.statement, pos_local+length(local_name), pos_plusplus-pos_local-length(local_name));
      }

      if(diff == "" || c_only_allowable_characters_between_local_and_operator(diff)) {
         assigned = true;
         rhs_start = pos_plusplus+1;
         ref_info.rhs = ref_info.qualified_name :+ " + 1";
      }

      // Get next ++
      start_pos = pos_plusplus+1;
      if(start_pos >= length(ref_info.statement)) break;
      pos_plusplus = pos("++", ref_info.statement, start_pos);
   }

   // Look for the pre/post decrement operator before or after the local_name
   start_pos = 1;
   int pos_minusminus = pos("--", ref_info.statement, start_pos);
   while(pos_minusminus > 0) {
      _str diff = "";
      if(pos_minusminus < pos_local) {
         diff = substr(ref_info.statement, pos_minusminus+2, pos_local-pos_minusminus-2);
      } else if(pos_plusplus > pos_local) {
         diff = substr(ref_info.statement, pos_local+length(local_name), pos_minusminus-pos_local-length(local_name));
      }

      if(diff == "" || c_only_allowable_characters_between_local_and_operator(diff)) {
         assigned = true;
         rhs_start = pos_minusminus+1;
         ref_info.rhs = ref_info.qualified_name :+ " - 1";
      }

      // Get next --
      start_pos = pos_minusminus+1;
      if(start_pos >= length(ref_info.statement)) break;
      pos_minusminus = pos("--", ref_info.statement, start_pos);
   }

   if(ref_info.rhs == "" && rhs_start > 0) {
      ref_info.rhs = substr(ref_info.statement, rhs_start);
      // Strip off leading an trailing whitespace characters
      ref_info.rhs = strip(ref_info.rhs);
   }

   // Strip semicolon off of right hand side
   ref_info.rhs = strip(ref_info.rhs,"T",';');

   // TODO
   // Need to see if this is a function and see if the local is being cast as a parameter
   // and whether that parameter is passed as a reference that could be modified_in the function.
   _GoToROffset(offset);

   ref_info.ref_name = local_name;
   ref_info.modified = assigned;
   ref_info.filename = p_buf_name;

   return assigned;
}

// Generate a nice debugging string for the extract flags.
static _str get_extract_flags_string(int flags)
{
   _str s = "";
   if(flags & BEFORE_EXTRACTED_CODE) {
      strappend(s, "BEFORE_EXTRACTED_CODE");
   }
   if(flags & INSIDE_EXTRACTED_CODE) {
      if(s != "") strappend(s, " | ");
      strappend(s, "INSIDE_EXTRACTED_CODE");
   }
   if(flags & AFTER_EXTRACTED_CODE) {
      if(s != "") strappend(s, " | ");
      strappend(s, "AFTER_EXTRACTED_CODE");
   }
   return s;
}

// Print out local information for debugging
static void print_local_info(VS_TAG_LOCAL_INFO &local_info) 
{
   say("-------------------");
   say(local_info.cm.member_name);
   say("-------------------");
   say("      new name = "local_info.new_name);
   say("      is_param           = "local_info.is_param);
   say("      is_ref_param       = "local_info.is_ref_param);
   say("      is_return_param    = "local_info.is_return_param);

   say("      declaration_flags = "get_extract_flags_string(local_info.declaration_flags));
   say("      used_flags        = "get_extract_flags_string(local_info.used_flags));
   say("      modified_flags    = "get_extract_flags_string(local_info.modified_flags));
   tag_browse_info_dump(local_info.cm,"cm", 6);
}

// Rename locals that are params in the range given.
static void rename_locals(VS_TAG_LOCAL_INFO (&params)[], int begin_seekpos, int &end_seekpos)
{
   int i, current_offset = (int)_QROffset();

   // Go to beginning of context and start searching for references
   VS_TAG_RETURN_TYPE visited:[];
   for(i=0; i < params._length(); i++) {

      // find all the references to this tag
      int seekPositions[]; seekPositions._makeempty();
      _str errorArgs[]; errorArgs._makeempty();
      int maxReferences = def_cb_max_references;
      int numReferences = 0;
      tag_match_occurrences_in_file_get_positions(errorArgs, seekPositions,
                                                  params[i].cm.member_name, p_EmbeddedCaseSensitive,
                                                  params[i].cm.file_name, params[i].cm.line_no,
                                                  VS_TAGFILTER_ANYTHING, 0, 0,
                                                  numReferences, maxReferences, visited);

      // go through the file backwards
      int j,m = seekPositions._length();
      for (j=m-1; j>=0; --j) {

         // Skip any references that are after the extracted block
         if(seekPositions[j] > end_seekpos) {
            continue;
         }

         // If we end up before the extracted block then stop.
         if(seekPositions[j] < begin_seekpos) {
            break;
         }
         // go to the seek position
         int status = _GoToROffset(seekPositions[j]);
         if (status < 0) continue;

         _delete_text(length(params[i].cm.member_name));
         _insert_text(params[i].new_name);
         end_seekpos += (length(params[i].new_name) - length(params[i].cm.member_name));
      }
   }
   _GoToROffset(current_offset);

}

/**
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
static void set_local_modified_flags(int context_id, 
                                     int extract_block_startseek, 
                                     int extract_block_endseek, 
                                     VS_TAG_LOCAL_INFO &local,
                                     VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_scope_seekpos, context_end_seekpos;

   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, context_scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, context_end_seekpos);

   int current_offset = (int)_QROffset();

   // Go to beginning of context and start searching for references
   _GoToROffset(context_scope_seekpos);

   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;

   boolean found = search(local.cm.member_name, "@h>EWXcs") == 0;
   while(found && _QROffset() <= context_end_seekpos) {

      // What color is this reference word.
      int lex_type=_clex_find(0,'g');
      // Why does get_expression_info not work in this context?!?!?
      // 
      // Ignore references in comments and string.
      if (lex_type!=CFG_COMMENT && lex_type!=CFG_STRING) {

         // Get the context information about the symbol under the cursor
         tag_idexp_info_init(idexp_info);
         _Embeddedget_expression_info(false, lang, idexp_info, visited, depth);

         // If this has a prefixexp then it is probably a class member_name
         // rather then a local. Ignore it.
         VS_TAG_REFERENCE_INFO ref_info;
         if(idexp_info.prefixexp == '') {
            // Don't use declarations to mark a var as used unless it is also a left hand side?
            if(_QROffset() < extract_block_startseek) {
               local.used_flags |= BEFORE_EXTRACTED_CODE;
               if(c_reference_is_modified(local.cm.member_name, ref_info, visited, depth)) {
                  local.modified_flags |= BEFORE_EXTRACTED_CODE;
               }
            } else if (_QROffset() < extract_block_endseek) {
               local.used_flags |= INSIDE_EXTRACTED_CODE;
               if(c_reference_is_modified(local.cm.member_name, ref_info, visited, depth)) {
                  local.modified_flags |= INSIDE_EXTRACTED_CODE;
               }
            } else {
               local.used_flags |= AFTER_EXTRACTED_CODE;
               if(c_reference_is_modified(local.cm.member_name, ref_info, visited, depth)) {
                  local.modified_flags |= AFTER_EXTRACTED_CODE;
               }
            }
         }
      }
      found = (search(local.cm.member_name, "@h>EWXcs") == 0);
   }

   _GoToROffset(current_offset);
}


/**
 * fill array with all the locals in the current context
 * 
 * @param context_id context to get locals for
 * @param all_locals (out)array to fill with locals
 */
static void get_locals(int context_id, VS_TAG_LOCAL_INFO (&all_locals)[])
{
   VS_TAG_BROWSE_INFO function_cm;
   _str p1, p3, p4;
   int p2, p5;

   save_search(p1,p2,p3,p4,p5);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int method_start_line, method_end_line, method_end_pos;
   // find the current context - more specifically
   // find the start of the currnet context so it
   // can be used as the insertion point for the
   // new method
   if (context_id>0) {
      tag_get_context_info(context_id, function_cm);
   } else {
      _message_box('Could not find current context.');
      return;
   }
   int current_seekpos = (int)_QROffset();

   // Move cursor to end of find because tag_find_local, tag_next_local
   // will look from the start of the context until the cursor.
   _GoToROffset(function_cm.end_seekpos);

   all_locals._makeempty();
   int local_tag_id=tag_find_local_iterator('',false,true,true);
   
   // find all the local variables
   while (local_tag_id>=0) {
      VS_TAG_BROWSE_INFO cm;
      tag_get_local_info(local_tag_id, cm);

      VS_TAG_LOCAL_INFO local_info;
      local_info.cm = cm;

      local_info.new_name = cm.member_name;

      local_info.declaration_flags = 0;
      local_info.used_flags = 0;
      local_info.modified_flags = 0;

      local_info.is_param = false;
      local_info.is_ref_param = false;
      local_info.is_return_param = false;

      // Type could have an =<initializer> in it. 
      // Take it out if it exists.
      int equals = pos("=", local_info.cm.return_type);
      if(equals) {
         local_info.cm.return_type = substr(local_info.cm.return_type, 1, equals-1);
      }

      all_locals[all_locals._length()] = local_info;
      local_tag_id=tag_next_local_iterator('',local_tag_id,false,true,true);

   }

   _GoToROffset(current_seekpos);
}

static int get_class_context(int seek_position, VS_TAG_BROWSE_INFO &class_cm)
{
   int old_seek_position = (int)_QROffset();

   _GoToROffset(seek_position);

   // get browse information for the tag under the symbol
   _UpdateContext(true, false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   tag_browse_info_init(class_cm);
   int context_id = tag_current_context();
   while (context_id > 0) {
      // get information about this context item, is it the proc?
      tag_get_context_info(context_id, class_cm);

      if (class_cm.type_name=='class' || class_cm.type_name=='struct') {
         break;
      }
      // go up one level
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }

   // Couldn't find a class context.
   if(class_cm.type_name != 'class' && class_cm.type_name != 'struct') {
      return -1;
   }

   _GoToROffset(old_seek_position);
   return 0;
}


static int get_function_context(int seek_position, _str &context_type, _str &context_name, int &context_id)
{
   int old_seek_position = (int)_QROffset();

   _GoToROffset(seek_position);

   // get browse information for the tag under the symbol
   _UpdateContext(true, false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   context_name = '';
   context_type = 0;
   context_id = tag_current_context();
   while (context_id > 0) {
      // get information about this context item, is it the proc?
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, context_type);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, context_name);
      if (tag_tree_type_is_func(context_type) && context_type!='proto' && context_type!='procproto') {
         break;
      }
      // go up one level
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }

   _GoToROffset(old_seek_position);
   return 0;
}

static _str get_class_name(_str tag_class_name)
{
   _str class_name = tag_class_name;
   if(lastpos("/", tag_class_name) > 0) {
      class_name = substr(tag_class_name, lastpos("/", tag_class_name)+1);
   }
   return class_name;
}

/**
 * create's function call string and inserts it where the extracted code was.
 * 
 * @param return_value
 *               return value info for the function call
 * @param params parameters to the function call
 *
 * @param extracted_function_name
 *               name of function to call
 * @param leading_indention
 *               whitespace to place before function call
 */
static void c_create_extracted_function_call(VS_TAG_LOCAL_INFO &return_value, VS_TAG_LOCAL_INFO (&params)[],_str extracted_function_name, _str leading_indention)
{
   int i;
   _str function_call = leading_indention;

   if(return_value != null) {
      // Slick-C cannot have an explicit array return type so 
      // change it to typeless.
      if(_LanguageInheritsFrom('e') && pos("[",return_value.cm.return_type) != 0) {
         return_value.cm.return_type="typeless";
      }

      if(return_value.declaration_flags & INSIDE_EXTRACTED_CODE) {
         // make a local variable and assign the return value of this function to it.
         // Name it the same as the return value variable in the original extracted code.
         strappend(function_call, return_value.cm.return_type :+ " " :+ return_value.cm.member_name :+ " = ");
      } else {
         // Assign the return value of this function to the local variable that was passsed in.
         strappend(function_call, return_value.cm.member_name :+ " = ");
      }
   }

   strappend(function_call, extracted_function_name"(");

   boolean first_param=true;
   for(i=0; i < params._length(); i++) {
      if (!first_param) {
         strappend(function_call,", ");
      } else {
         first_param=false;
      }
      if(_LanguageInheritsFrom('cs') && params[i].is_ref_param) {
         strappend(function_call, " ref ");
      }
      strappend(function_call, params[i].cm.member_name);
   }

   strappend(function_call, ");");

   _insert_text(function_call);
}


/**
 * fix selection to make sure it encompasses complete statements. Make sure it 
 * starts at the beginning of the first line and ends at the end of the last line.
 * 
 * @param selection_markid
 *               selection to expand
 * @param start_seekpos
 *               (ref)start seek position of expanded selection
 * @param end_seekpos
 *               (ref)end seek position of expanded selection.
 * 
 * @return new expanded selection
 */
static int expand_selection(int selection_markid, int &start_seekpos, int &end_seekpos)
{
   // Modifying/Validating selection rules:
   // 1. If start of selection is not on column 1 and there is only whitespace 
   //    between the start of selection and column 1 then make start of selection column 1.
   // 2. expand end of selection to end of the line that the end of selection is on.
   // 3. If start of selection or end of selection is contained within a statement then the
   //    selection is invalid.
   // 
   // If a selection contains any return, continue, break, or goto statments then warn the user
   // that the extraction could break their behavior. 
   // a break or continue inside a loop construct or a break inside a switch statement are ok however
   // and do not need a warning.

   begin_select();
   start_seekpos = (int)_QROffset();

   if(p_col > 1) {
      get_line(auto line);

      // Get the text on the line before where the selection starts
      _str leading_text = substr(line, 1, p_col-1);

      // If the leading text is only whitespace then modify the start of the selection block
      // to be the start of the line.
      if(pos("[^ \t]", leading_text, 1, "U") == 0) {
         start_seekpos = (int)(_QROffset() - length(leading_text));
      }
   }

   end_select();
   end_line();
   end_seekpos = (int)_QROffset();

   // replace mark with new expanded selection.
   selection_markid = select_range(start_seekpos, end_seekpos);
   return selection_markid;
}

// Stick all the information into a string that the extract dialog will read.
// name\ttype\t[&]\t[1]\t[array]\n
static _str add_to_param_string(_str param_info, VS_TAG_LOCAL_INFO &local_info)
{
   strappend(param_info, local_info.cm.member_name);
   strappend(param_info, "\t");
   strappend(param_info, local_info.cm.return_type);
   strappend(param_info, "\t");
   if(local_info.is_ref_param) {
      strappend(param_info, "&");
   }
   strappend(param_info, "\t");
   strappend(param_info, "1"); // Is this parameter required?
   strappend(param_info, "\t");
   strappend(param_info, ""); // Array indicator I.E. []
   strappend(param_info, "\n");
   return param_info;
}

// Do all the cleanup before returning out of quick extract method
static void cleanup_quick_refactor(int handle, int temp_view_id, int orig_view_id) 
{
   refactor_cancel_transaction(handle);
   _delete_temp_view(temp_view_id);
   p_window_id = orig_view_id;
}

// Position the character where we want to insert the new function
static void find_new_method_insertion_point(int start_line)
{ 
   // position on the start line
   p_line=start_line;

   // go up and to the beginning of the previous line_number
   _begin_line();

   // skip backwards over whitespace and comments
   _clex_skip_blanks('-');

   // this line contains non-blank characters, remember iterate
   int non_blank_line = p_line;

   // go back to the start line
   p_line=start_line;

   // check the first line above
   up();
   begin_line();

   // loop until we find a blank line outside of a comment
   while (p_line > non_blank_line) {
      if (_in_comment()) {
         up();
         continue;
      }
      _str line='';
      get_line(line);
      if (line=='') {
         break;
      }
      // HS2: go up if it's still a non-blank line
      up();
   }

   // ok, now jump to the end of the line and insert a new line
   _end_line();
   nosplit_insert_line();
}

/**
 * get browse information for the prototype of the function defined 
 * by the browse info passed in.
 * 
 * @param function_cm
 *               function to get proto of
 * 
 * @return prototype browse info
 */
VS_TAG_BROWSE_INFO find_proto(VS_TAG_BROWSE_INFO function_cm)
{
   int current_offset = (int)_QROffset();
   _GoToROffset(function_cm.seekpos);

   // Put cursor at beginning of function name
   search(function_cm.member_name, "@h<WXcs");

   // Find all definitions/declarations for function
   _str errorArgs[]; errorArgs._makeempty();
   tag_clear_matches();
   int i, num_matches=context_match_tags(errorArgs, function_cm.member_name,true,
                                         def_tag_max_find_context_tags,
                                         true,p_EmbeddedCaseSensitive);   
   for (i=1; i<=num_matches; i++) {
      VS_TAG_BROWSE_INFO match;
      tag_get_match_info(i, match);
      if(match.type_name == 'proto') {
         _GoToROffset(current_offset);
         return match;
      }
   }

   _GoToROffset(current_offset);
   return null;
}


/**
 * Adds a function prototype above where the function that the extracted code came from is declared.
 * 
 * @param handle           refactoring transaction handle
 * @param new_function     browse info for function that is being created.
 * @param proto_cm         browse info for the prototype that the new function's prototype should be placed before
 *                         and whose access flags should be mimiced.
 * @param create_javadoc   create a javadoc comment for the new function.
 */
static void add_prototype_for_new_function(int handle, VS_TAG_BROWSE_INFO new_function, VS_TAG_BROWSE_INFO proto_cm, _str create_comment)
{
   int proto_temp_view_id = 0, orig_view_id = 0;
   boolean alreadyExists;
   int status=0;
   if(proto_cm.file_name != new_function.file_name) {
      status = _open_temp_view(proto_cm.file_name, proto_temp_view_id, orig_view_id, "+d", alreadyExists, false, true);
   }
   // Jump to function prototype so that new function prototype will be inserted before it.
   p_line = proto_cm.line_no;
   
   // Create function prototype
   gen_index := _FindLanguageCallbackIndex('_%s_generate_function');
   if(gen_index != 0) {
      new_function.flags = proto_cm.flags;
      int c_access_flags=(new_function.flags&VS_TAGFLAG_access);
      boolean in_class_scope = false;
   
      // If we are inside a class then say we are in class scope and add the indention. Needs work
      // to handle nested classes.
      _str function_indention = 0;
      if(proto_cm.class_name != "") {
         in_class_scope = true;
         function_indention = p_SyntaxIndent;
      }
      int end_prototype_pos=call_index(new_function, c_access_flags, null, "", function_indention, p_SyntaxIndent,
                        true, in_class_scope, '', '', gen_index);
   
      if(create_comment == "1" || create_comment == "2") {
         // Move cursor to end of prototype that was just inserted.
         restore_pos(end_prototype_pos);
         // Search backwards to find the function name. Position cursor at beginning of function name.
         search(new_function.member_name, "@h-<WXcs");
         // Make the javadoc comment for the function that the cursor is sitting on.
         if(create_comment == "1") {
            javadoc_comment();
            commentwrap_SetNewJavadocState();
         } else {
            xmldoc_comment();
         }
      }
   }
   
   // Save the prototype file contents
   if(proto_cm.file_name != new_function.file_name) { 
      refactor_set_modified_file_contents(proto_temp_view_id, handle, proto_cm.file_name);
      _delete_temp_view(proto_temp_view_id);
   }
}


static boolean pass_local_by_reference(VS_TAG_LOCAL_INFO &parameter, _str lang, boolean &const_ref)
{
   const_ref = false;

   // No ref params for java
   if(_LanguageInheritsFrom('java', lang)) {
      return false;
   }

   if(parameter.is_ref_param == true) {
      return true;
   }

   // Now how about nonref parameters that really should be passed by reference.
   code_is_c := _LanguageInheritsFrom('c', lang);
   param_is_builtin := do_default_is_builtin_type(parameter.cm.return_type);
   modified_inside_extracted_code := (parameter.modified_flags & INSIDE_EXTRACTED_CODE) != 0;

   // Don't pass builtins by reference
   if(code_is_c && !param_is_builtin) {
      if(!modified_inside_extracted_code) {
         const_ref == true;
      }
      return true;
   }
   return false;
}

static int ask_about_word_in_extracted_code(_str word)
{
   _GoToROffset(0);
   // Search for whole words and keyword color.
   int res = search(word, "@hWCKXcs");
   if(search(word, "@hWCKXcs") == 0) {
      int answer = _message_box("There is a "word" in the code to extract. This may cause the extracted code in the new function not to work. Do you wish to continue?", 
                     "Quick Extract Method", MB_YESNO);
      return answer;
   }
   return IDYES;
}


/**
 * search through extracted code for keywords that could cause the code, 
 * once extracted not to work. Warn the user about the keywords 
 * and ask them if they want to continue.
 * 
 * @param extracted_code   string to search for keywords.
 * 
 * @return 
 */
static boolean check_for_problematic_keywords(_str extracted_code)
{
   boolean proceed=true;

   _str lang = p_LangId;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=='' ) {
      return false;
   }

   // Make sure we are in the proper language so that keyword searchs will work.
   _SetEditorLanguage(lang);
   _insert_text(extracted_code);

   if(ask_about_word_in_extracted_code("return") == IDNO) {
      proceed = false;
   } else if(ask_about_word_in_extracted_code("goto") == IDNO) {
      proceed = false;
   } else if(ask_about_word_in_extracted_code("break") == IDNO) {
      proceed = false;
   } else if(ask_about_word_in_extracted_code("continue") == IDNO) {
      proceed = false;
   }

   _delete_temp_view(temp_view_id);
   p_window_id = orig_view_id;
   return proceed;
}

/**
 * Create a string of the parameters to the function being generated
 * 
 * @param final_param_list    parameters to make string out of.
 * @param lang                language ID to create parameters for 
 *                            see {@link p_LangId} 
 * 
 * @return _str   string that is what should be inserted within the parens of the extracted function.
 */
_str create_arguments_string(VS_TAG_LOCAL_INFO final_param_list[], _str lang)
{
   get_decl_index := _FindLanguageCallbackIndex('_%s_get_decl',lang);
   _str args="";
   int i;
   boolean first_param=true;
   for(i = 0 ; i < final_param_list._length(); i++) {
      if (!first_param) {
         strappend(args,", ");
      } else {
         first_param=false;
      }

//      // Extract array brackets out of type so that they can be placed after the variable name. 
//      _str type = final_param_list[i].cm.return_type;
//      _str array_value="";
//      int array_start = pos("[",type);
//      int array_end = lastpos("]",type);
//    
//      if(array_start > 0 && array_end > array_start) {
//         array_value = substr(type, array_start, array_end - array_start+1);
//         type= substr(type, 1, array_start-1);
//      }
    
      boolean const_ref=false;
      boolean pass_by_ref = pass_local_by_reference(final_param_list[i], lang, const_ref);

      if(get_decl_index) {
         VS_TAG_BROWSE_INFO info = final_param_list[i].cm;
         info.member_name = final_param_list[i].new_name;

         // add ref if it is not already there
         if(pass_by_ref && pos("&",info.return_type) == 0) {
            strappend(info.return_type,"&");
         }

         // adjust const flags
         if(const_ref || info.type_name == 'const' || pos('const', info.return_type) != 0) {
            info.flags |= VS_TAGFLAG_const;
         }

         // Now it is a parameter.
         info.type_name = 'param';

         _str param = call_index(p_LangId, info, 0, "", "", get_decl_index);

         strappend(args, param);
      }
   }

   return args;
}

/**
 * Set the usage, declaration, and modified flags for this array of locals
 * 
 * @param extract_start_pos   start of code to examine
 * @param extract_end_pos     end of code to examine
 * @param context_id          context id of function that code is contained in.      
 * @param all_locals          (ref)array of locals to set the flags for.
 * 
 * @return int  number of ref params in this list of locals.
 */
static int set_locals_usage_flags(int extract_start_pos, int extract_end_pos, int context_id, VS_TAG_LOCAL_INFO (& all_locals)[], boolean &was_canceled)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   static boolean canceled;

   was_canceled=false;
   int j,num_ref_params=0;
   boolean have_return_value=false;
   for(j = 0 ; j < all_locals._length(); j++) {

      if(all_locals[j].cm.seekpos < extract_start_pos) {
         all_locals[j].declaration_flags = BEFORE_EXTRACTED_CODE;
      } else if (all_locals[j].cm.seekpos < extract_end_pos) {
         all_locals[j].declaration_flags = INSIDE_EXTRACTED_CODE;
      } else {
         all_locals[j].declaration_flags = AFTER_EXTRACTED_CODE;
      }

      set_local_modified_flags(context_id, extract_start_pos, extract_end_pos, all_locals[j]);

      process_events(canceled);
      if (cancel_form_cancelled()) {
         was_canceled = true;
         break;
      }

      cancel_form_progress(cancel_form_wid(), j, all_locals._length()-1);
 
      // If this local is declared before the extracted block and it is used inside the extracted block
      // then it should be a parameter.
      if((all_locals[j].declaration_flags == BEFORE_EXTRACTED_CODE) && (all_locals[j].used_flags & INSIDE_EXTRACTED_CODE)) {
         all_locals[j].is_param = true;
         if((all_locals[j].modified_flags & INSIDE_EXTRACTED_CODE) && (all_locals[j].used_flags & AFTER_EXTRACTED_CODE)) {
            all_locals[j].is_ref_param = true;
            num_ref_params++;
         } else {
            all_locals[j].is_ref_param = false;
         }
      } else if((all_locals[j].declaration_flags == INSIDE_EXTRACTED_CODE) && (all_locals[j].used_flags & AFTER_EXTRACTED_CODE)) {
         // This should be a return type. However if there are multiple ones that fall into this category then
         // these would have to be moved to var parameters. If
         if(have_return_value == false) {
            all_locals[j].is_return_param = true;
            have_return_value = true;
         } else {
            // If multiple locals could be the return type make the extra ones ref parameters instead.
            all_locals[j].is_param = true;
            all_locals[j].is_ref_param = true;
            num_ref_params++;
         }
      }
   }

   return num_ref_params;
}

/**
 * Create browse info for new function based on the browse info for the function that the code is being extracted from.
 * 
 * @param function_cm               function code is being extracted from
 * @param return_value              return value to be used in new function
 * @param extracted_function_name   new function name
 * @param args                      string containing arguments to new function
 * 
 * @return VS_TAG_BROWSE_INFO       browse info that defines the new function
 */
VS_TAG_BROWSE_INFO create_browse_info_for_new_function(VS_TAG_BROWSE_INFO function_cm, VS_TAG_LOCAL_INFO return_value, _str extracted_function_name, _str args)
{
   VS_TAG_BROWSE_INFO new_function;
   tag_browse_info_init(new_function);
   new_function.class_name = function_cm.class_name;
   new_function.member_name = extracted_function_name;
   new_function.type_name = 'func';
   new_function.file_name = function_cm.file_name;
   new_function.language = function_cm.language;

   // New function won't be a constructor or destructor so take out those flags
   new_function.flags = function_cm.flags & ~VS_TAGFLAG_const_destr;

   if(return_value != null) {
      new_function.return_type = return_value.cm.return_type;
   } else {
      new_function.return_type = "void";
   }
   new_function.arguments = args;
   new_function.exceptions = function_cm.exceptions;
   new_function.class_parents = function_cm.class_parents;
   new_function.template_args = function_cm.template_args;

   return new_function;
}


_str build_prototype_string(_str name, VS_TAG_BROWSE_INFO function_cm, VS_TAG_LOCAL_INFO params[], VS_TAG_LOCAL_INFO return_value)
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=='' ) {
      return "";
   }

   // Make sure we are in the proper language so that keyword searchs will work.
   _SetEditorLanguage(function_cm.language);

   // Create arguments string
   _str args = create_arguments_string(params, function_cm.language);

   // Build the browse info for the function that we are going to create.
   VS_TAG_BROWSE_INFO new_function = create_browse_info_for_new_function(function_cm, return_value, name, args);

   // create the new function using the language specific generate function
   // This will create the function in the current buffer.
   typeless inside_function_pos=0;
   gen_index := _FindLanguageCallbackIndex('_%s_generate_function');
   if(gen_index != 0) {
      inside_function_pos=call_index(new_function, 0 , null, '', 0, 0,
                        true, false, '', '', gen_index);
   }

   // Grab contents of temp buffer.
   _GoToROffset(0);
   _str proto = get_text(p_buf_size);

   // Clean up.
   _delete_temp_view(temp_view_id);
   p_window_id = orig_view_id;

   return proto;
}

static boolean update_extract_progress(int handle, int tempViewID, int origViewID, int percent)
{
   static boolean canceled;
   process_events(canceled);
   if (cancel_form_cancelled()) {
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return true;
   }
   cancel_form_progress(cancel_form_wid(), percent, 100);
   return false;
}

/**
 * Extract method.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_quick_extract_method(_str precise='') name_info(FILE_ARG',')
{
   // init refactoring operations
   if (!refactor_init(true, false)) {
      return COMMAND_CANCELLED_RC;
   }

   // begin the refactoring transaction
   int status = 0, handle = refactor_begin_transaction();
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   // add the current file to the refactoring transaction
   refactor_add_file(handle, p_buf_name, '', '', '', '');
   refactor_set_file_encoding(handle, p_buf_name, _EncodingToOption(p_encoding));

   // This method requires a selection, but not a block selection
   if ( ! select_active() ) {
      refactor_cancel_transaction(handle);
      _message_box("Quick Extract Method requires a selection.", "Quick Extract Method");
      return -1;
   }

   // TODO determine type of selection if we think it is an expression.
   // Surround it with parens and pass it to _c_get_type_of_prefix.

   // Get current selection bounds in current buffer so that it can be transferred to the temporary view.
   long orig_pos = _QROffset();
   begin_select();

   // go to the beginning of this line - begin_select only goes to the top line of the 
   // selection without changing the column for line selections
   if (_select_type() == 'LINE') p_col = 1;
      
   int start_seekpos = (int)_QROffset();
   end_select();
   int end_seekpos = (int)_QROffset();

   _GoToROffset(orig_pos);

   // Do all the work in a temp view so that undo/cancel works correctly. 
   int tempViewID = 0, origViewID = 0;
   boolean alreadyExists = false;
   status = _open_temp_view(p_buf_name, tempViewID, origViewID, "+d", alreadyExists, false, true);
   if (status < 0) {
      // TBF: gracefully handle error
      refactor_cancel_transaction(handle);
      _message_box("Quick Extract Method:  Could not open file: "p_buf_name);
      return status;
   }

   // Select the same range in the new buffer as was selected in the original buffer.
   int selection_temp_view_mark = select_range(start_seekpos, end_seekpos);

   // Expand the selection so that the beginning and end of the selection select the whole line.
   // Replace the current selection with this new expanded one.
   int extract_start_pos, extract_end_pos;
   selection_temp_view_mark = expand_selection(selection_temp_view_mark, extract_start_pos, extract_end_pos);

   // Grab leading whitespace
   _str extracted_code = get_text(extract_end_pos-extract_start_pos, extract_start_pos);
   _str leading_indention = get_line_leading_whitespace(extracted_code);

   // Search for problematic keyword and ask the user if they want to continue.
   if(check_for_problematic_keywords(extracted_code) == false) {
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return COMMAND_CANCELLED_RC;
   }

   // get browse information for the tag under the symbol
   _UpdateContext(true, false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   _UpdateLocals(true);
   _str start_context_name, end_context_name, start_context_type, end_context_type;
   int start_context_id, end_context_id;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Get context of start of selection.
   get_function_context(extract_start_pos, start_context_type, start_context_name, start_context_id);

   // Get context of end of selection.
   get_function_context(extract_end_pos, end_context_type, end_context_name, end_context_id);

   // Begin and end of block must be in the same context
   if(start_context_id != end_context_id) {
      _message_box('Selection begin and end points must be in the same context.', "Quick Extract Method");
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return -1;
   }

   // The selection must be inside a function body
   if (start_context_name == '') {
      _message_box("Selection must be within a function body.", "Quick Extract Method");
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return -1;
   }

   show_cancel_form("Quick Extract method", "Analyzing locals", true, true);

   VS_TAG_BROWSE_INFO function_cm;
   tag_get_context_info(start_context_id, function_cm);

   VS_TAG_LOCAL_INFO all_locals[], return_value=null;
   get_locals(start_context_id, all_locals);

   boolean was_canceled=false;

   // Set the declaration, used, and modified flags for all locals and fill in a return value 
   // This takes the majority of the processing time before the dialog is shown so do the progress bar in this function.
   int num_ref_params = set_locals_usage_flags(extract_start_pos, extract_end_pos, start_context_id, all_locals, was_canceled);

   if(was_canceled) {
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return COMMAND_CANCELLED_RC;
   }

   // Find return value local
   int i=0, j=0;
   for(i=0; i < all_locals._length(); i++) {
      if(all_locals[i].is_return_param) {
         return_value = all_locals[i];
         break;
      }
   }

   // Find prototype for function
   VS_TAG_BROWSE_INFO proto_cm = null;
   if(_LanguageInheritsFrom('c')) {
      proto_cm = find_proto(function_cm);
      if(proto_cm != null) {
         // add the current file to the refactoring transaction
         refactor_add_file(handle, proto_cm.file_name, '', '', '', '');
         refactor_set_file_encoding(handle, proto_cm.file_name, _EncodingToOption(p_encoding));
      }
   }

   // Java does not allow reference parameters. Instead 
   // if there is one ref param and no return parameters then add
   // the ref param is the return value.
   if(_LanguageInheritsFrom('java')) {
      if((num_ref_params > 1) || (return_value != null && num_ref_params > 0)) {
         _message_box('There are to many locals that are modified in the extracted code and used afterwards. Canceling extraction.', "Quick Extract Method");
         cleanup_quick_refactor(handle, tempViewID, origViewID);
         return COMMAND_CANCELLED_RC;
      }

      // Make ref parameter nonref and also make it the return value. Poors man's ref parameter.
      if(num_ref_params == 1) {
         for(i=0; i < all_locals._length(); i++) {
            if(all_locals[i].is_ref_param == true) {
               all_locals[i].is_ref_param = false;
               return_value = all_locals[i];
               break;
            }
         }
      }
   }
   _str param_info="";
   VS_TAG_LOCAL_INFO final_param_list[];
   for(i=0; i < all_locals._length(); i++) {
      if(all_locals[i].is_param) {
         final_param_list[final_param_list._length()] = all_locals[i];
         param_info = add_to_param_string(param_info, all_locals[i]);
      }
   }

   // Get the return value type if any and pass this to the dialog.
   _str return_value_type = "";
   if(return_value != null) {
      return_value_type = return_value.cm.return_type;
   }

   _str lang = p_LangId;
   boolean beautify_enabled = BeautifyCheckSupport(lang) == 0;
   boolean javadoc_enabled = is_javadoc_supported();
   boolean xmldoc_enabled = _is_xmldoc_supported(lang);

   build_prototype_string(function_cm.member_name"_extracted", function_cm, final_param_list,return_value);

   close_cancel_form(cancel_form_wid());

   struct EXTRACT_METHOD_INFO method_info;
   method_info.params = final_param_list;
   method_info.function_cm = function_cm;
   method_info.return_type = return_value;

   _str paramInfo = show("-modal -xy _refactor_extract_method_form", function_cm.member_name"_extracted", 
         return_value_type, param_info, 1, beautify_enabled, javadoc_enabled, xmldoc_enabled, 
         p_LangId, method_info);

   method_info = gMethodInfo;

   if (paramInfo == '') {
      cleanup_quick_refactor(handle, tempViewID, origViewID);
      return COMMAND_CANCELLED_RC;
   }

   show_cancel_form("Quick Extract method", "Creating extracted method", true, true);

   typeless createMethodCall;
   // Need to rename locals that are parameters into the extracted method.
   _str extracted_function_name = function_cm.member_name"_extracted"; 
   _str beautify_new_function="0", create_comment="0";
   parse paramInfo with extracted_function_name "\n" createMethodCall "\n" beautify_new_function "\n" create_comment "\n" paramInfo;

   // Rename all locals in extracted code that correspond to parameters that have
   // been renamed by the user.
   if(update_extract_progress(handle, tempViewID, origViewID, 20) == true) return COMMAND_CANCELLED_RC;

   rename_locals(method_info.params, extract_start_pos, extract_end_pos); 

   // Reselect renamed extracted code(Is potentially a different range in the file due to change in name lengths)
   typeless renamed_selection_mark;
   renamed_selection_mark = select_range(extract_start_pos, extract_end_pos);
//   _delete_selection(selection_temp_view_mark);

   // Reget renamed extracted_code
   extracted_code = get_text(extract_end_pos-extract_start_pos, extract_start_pos);

//   say("==================================");
//   say("ALL_LOCALS count = "all_locals._length());
//   say("==================================");
//   for(i=0; i < all_locals._length(); i++) {
//      print_local_info(all_locals[i]);
//   }

//   say("==================================");
//   say("FINAL_PARAM_LIST count = "final_param_list._length());
//   say("==================================");
//   for(i=0; i < final_param_list._length(); i++) {
//      print_local_info(final_param_list[i]);
//   }

   _GoToROffset(extract_start_pos);

   // Delete original extracted code
   if(createMethodCall == true) {
      _delete_selection();
      _delete_selection(renamed_selection_mark);
   }

   // Create arguments string
   _str args = create_arguments_string(method_info.params, function_cm.language);

   if(update_extract_progress(handle, tempViewID, origViewID, 40) == true) return COMMAND_CANCELLED_RC;

   // Build the browse info for the function that we are going to create.
   VS_TAG_BROWSE_INFO new_function = create_browse_info_for_new_function(function_cm, return_value, extracted_function_name, args);
   // is defined inside or outside of the class.
   int function_indention = 0;
   if(new_function.class_name != '' && _LanguageInheritsFrom('c') ) {
      function_indention = p_SyntaxIndent;
   }

   // Create language specific function call
   if(createMethodCall == true) {
      // Handle C like language function call creation(Java, C, Slick-C)
      c_create_extracted_function_call(return_value, method_info.params, extracted_function_name, leading_indention);
   }

   if(update_extract_progress(handle, tempViewID, origViewID, 60) == true) return COMMAND_CANCELLED_RC;

   // Position the character where we want to insert the new function
   find_new_method_insertion_point(function_cm.line_no);

   // Add a return to the end of the function
   if(return_value != null) {
      strappend(extracted_code, p_newline :+ leading_indention :+ "return ");
      strappend(extracted_code, return_value.new_name :+ ";");
   }

   auto start_off = _QROffset();

   // create the new function using the language specific generate function
   typeless inside_function_pos=0;
   gen_index := _FindLanguageCallbackIndex('_%s_generate_function');
   if(gen_index != 0) {
      inside_function_pos=call_index(new_function, 0 , null, extracted_code, function_indention, p_SyntaxIndent,
                        false, false, '', '', gen_index);
   }
   _save_pos2(auto after_fn);
   if(update_extract_progress(handle, tempViewID, origViewID, 80) == true) return COMMAND_CANCELLED_RC;

   if(create_comment == "1") {
      restore_pos(inside_function_pos);
      // Try to user their language's default javadoc format.
      first_non_blank();
      scol := p_col;
      _begin_line();
      _insert_text(p_newline);
      up();
      _insert_text(indent_string(scol-1));
      if (expand_alias('/**', '', getCWaliasFile(p_LangId), true)) {
         javadoc_comment();
      }
      commentwrap_SetNewJavadocState();
   } else if (create_comment == "2") {
      restore_pos(inside_function_pos);
      xmldoc_comment();
   }

   if(beautify_new_function == "1") {
      // If a comment is generated, our current position
      // is right after the comment, we want the position
      // right after the generated function.
      save_pos(auto bp);
      _GoToROffset(start_off);
      _select_char();

      _restore_pos2(after_fn);
      _select_char();
      restore_pos(bp);
      beautify_selection();
   }

   // save the file contents
   refactor_set_modified_file_contents(p_window_id, handle, p_buf_name);

   // Add the prototype for the created method
   if(proto_cm != null) {
      add_prototype_for_new_function(handle, new_function, proto_cm, create_comment);
   }

   if(update_extract_progress(handle, tempViewID, origViewID, 90) == true) return COMMAND_CANCELLED_RC;

   // If the proto and new function are the same then capture the results of the add prototype as well.
   if(new_function.file_name == proto_cm.file_name) {
      refactor_set_modified_file_contents(p_window_id, handle, p_buf_name);
   }

   if(update_extract_progress(handle, tempViewID, origViewID, 90) == true) return COMMAND_CANCELLED_RC;

   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status,
                                          "Failed to extract method.",
                                          "Quick extract method ",'');

   // Do any cleanup that needs to be done before leaving.
   cleanup_quick_refactor(handle, tempViewID, origViewID);

   return 0;
}

int _OnUpdate_refactor_quick_extract_method(CMDUI &cmdui,int target_wid,_str command)
{               
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if ( ! select_active() || _select_type()=='BLOCK' ) {
      return MF_GRAYED;
   }

   // Only support languages that have a generate function function.
   if(!_FindLanguageCallbackIndex('_%s_generate_function')) {
      return MF_GRAYED;
   }

   // Only support languages that have statement parsing.
//   if(_are_statements_supported() == false) {
//      return MF_GRAYED;
//   }

   return MF_ENABLED;
}

static _str _taglist_callback(int reason,var result,typeless key)
{
   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist.p_line-1;
      return(1);
   }
   return("");
}

static long get_class_insertion_point(VS_TAG_BROWSE_INFO class_cm, VS_TAG_BROWSE_INFO method_list[], _str method_sig)
{
   // Need to support overloaded methods?

   _UpdateContext(true,true);
   long curr_offset = _QROffset(), insertion_offset = -1;;
   // No public methods to insert around.
   int i;
      
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // pick the first 
   if(method_sig == "As first public method") {
      // Assumes that method_list was built from start to end of class.
      if(method_list._length() > 0) {
         find_new_method_insertion_point(method_list[0].line_no);
         insertion_offset = (int)_QROffset();
      }
   } else {
      // Find method to insert after
      for(i = 0; i < method_list._length(); i++) {
         _str sig = method_list[i].member_name :+ "(" :+  method_list[i].arguments :+ ")";

         if(sig == method_sig) {
            _GoToROffset(method_list[i].end_seekpos);
            end_line();
            down();
            insertion_offset = _QROffset();
            break;
         }
      }
   }

   // Restore position from before this function was called
   _GoToROffset(curr_offset);

   return insertion_offset;
}

/**
 * Makes a field private. In C this will move the field to a private access block or create a private
 * access block to move the field into.
 * 
 * @param member_pos    The position of the member variable declaration saves using _save_pos2().
 * @param class_cm      The browse info describing the class that this field is a member of.
 * @param member_cm     The browse info describing this member variable.
 * 
 * @return boolean Returns true if making the field private was successful, false otherwise. Will return true
 * and do nothing if the field is already private.
 */
static boolean make_field_private(typeless member_pos, VS_TAG_BROWSE_INFO class_cm, VS_TAG_BROWSE_INFO member_cm)
{
   _restore_pos2(member_pos);
   _save_pos2(member_pos);

   // Already private
   if((member_cm.flags & VS_TAGFLAG_access) == VS_TAGFLAG_private) {
      return true;
   }

   // Grab any stuff after member name like an initialization. Don't just grab from an equals because then
   // we miss any potential whitespace before the equals. Instead get from right after the member name
   // to the end of the statement.
   int start_statement;
   _str leading_comment_and_ws, trailing_comment_and_ws;
   _str statement = c_get_statement(start_statement, leading_comment_and_ws, trailing_comment_and_ws);

   // Grab any initializer statement that this field may have.
   // TODO. Need to grab any whitespace before =
   _str initializer="";
   if(pos("=",statement) > 0) {
      initializer = substr(statement, pos("=",statement));
   }

   // If we can't find get_decl then done't even try.
   get_decl_index := _FindLanguageCallbackIndex('_%s_get_decl');
   if(!get_decl_index) {
      return false;
   }

   // Change flags from public to private
   member_cm.flags &= ~VS_TAGFLAG_access;
   member_cm.flags |= VS_TAGFLAG_private;

   // Make new declaration
   _str decl = call_index(p_LangId, member_cm, 0, "", "", get_decl_index);

   if(_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('java') || _LanguageInheritsFrom('e')) { 
      if(initializer != "") {
         strappend(decl, initializer);
      } else {
         strappend(decl, ";");
      }
   }

   boolean inserted_line=false;
   _c_prepare_access("private",class_cm.seekpos, class_cm.scope_seekpos,class_cm.end_seekpos,'class',class_cm.member_name,inserted_line);

   // Find first private member to stick in front of
   // TODO allow the user to specify where to put the private field
   end_line();
   insert_line(leading_comment_and_ws :+ decl :+ trailing_comment_and_ws);
   _restore_pos2(member_pos);

   // Grab the statemnt again just to get it's new start after the insertion.
   int statement_start=0;
   _str field = c_get_statement(statement_start, leading_comment_and_ws, trailing_comment_and_ws);
   _GoToROffset(_QROffset() - length(leading_comment_and_ws)+1);
   _delete_text(length(field)+length(leading_comment_and_ws)+length(trailing_comment_and_ws)+1);

   return true;
}

/**
 * Create the getter and setter functions for a field that is to be encapsulated.
 * 
 * @param handle              Handle to the refactoring transaction.
 * @param member_cm           Browse info describing field to encapsulate.
 * @param class_cm            Browse info describing class that field belongs to.
 * @param getter_name         Name to give the getter function.
 * @param setter_name         Name to give the setter function.
 * @param make_protos         Should prototypes be made or the full declaration and body(C++)
 * @param in_class            Should these functions be inserted inside the class or outside.
 * @param insertion_seekpos   The location that these functions should be inserted.
 */
static void create_getter_and_setter_functions(int handle, VS_TAG_BROWSE_INFO member_cm, VS_TAG_BROWSE_INFO class_cm, 
               _str getter_name, _str setter_name, boolean make_protos, boolean in_class, long insertion_seekpos)
{
   //tag_browse_info_dump(member_cm,"create_getter_and_setter_functions");
   int i;
   VS_TAG_BROWSE_INFO getter, setter;
   tag_browse_info_init(getter);
   tag_browse_info_init(setter);

   long curr_offset = _QROffset();
   if(make_protos) {
      _GoToROffset(class_cm.scope_seekpos);
   }

   gen_index := _FindLanguageCallbackIndex('_%s_generate_function');
   if(gen_index != 0) {
      // Make the parameter name different from the member_name. 
      // Does not currently do any collision checks.
      _str param_name = "_" :+ member_cm.member_name;

      _str body_indention = indent_string(p_SyntaxIndent);
      if(in_class) {
         body_indention = indent_string(p_SyntaxIndent*2);
      }

      // Is this an array type. If so where does the array start?
      int array_pos = pos("[",member_cm.return_type);

      // Make the default function body appropriate for C, CS, Java
      _str getter_function_body, setter_function_body;
      if(array_pos != 0) {
         getter_function_body = body_indention :+ "return " :+ member_cm.member_name :+ "[_index];";
         setter_function_body = body_indention :+ member_cm.member_name :+ "[_index] = " :+ param_name :+ ";";
      } else {
         getter_function_body = body_indention :+ "return " :+ member_cm.member_name :+ ";";
         setter_function_body = body_indention :+ member_cm.member_name :+ " = " :+ param_name :+ ";";
      }
      
      getter.member_name = getter_name;
      getter.class_name = class_cm.member_name;
      getter.flags = VS_TAGFLAG_public | VS_TAGFLAG_const;
      getter.type_name = 'func';

      setter.member_name = setter_name;
      setter.class_name = class_cm.member_name;
      setter.flags = VS_TAGFLAG_public;
      setter.type_name = 'func';
      setter.return_type = "void";

      // Array. Pass in an array index and strip array of type. (single dimension arrays) C Style.
      if(array_pos != 0) {
         getter.return_type = substr(member_cm.return_type, 1, array_pos-1);
         getter.arguments = "int _index";

         setter.arguments =  "int _index, " :+ getter.return_type :+ " " :+ param_name;
      } else {
         getter.return_type = member_cm.return_type;
         getter.arguments = "";

         setter.arguments =  member_cm.return_type :+ " " :+ param_name;
      }

      int initial_indent = 0;
      if(in_class) {
         getter.flags |= VS_TAGFLAG_inclass;
         setter.flags |= VS_TAGFLAG_inclass;
         initial_indent = p_SyntaxIndent;
      }

      int end_prototype_pos=call_index(getter, VS_TAGFLAG_public, null, getter_function_body, initial_indent, p_SyntaxIndent,
                        make_protos, in_class, class_cm.member_name, "", insertion_seekpos, gen_index);

      call_index(setter, VS_TAGFLAG_public, null, setter_function_body, initial_indent, p_SyntaxIndent,
                        make_protos, in_class, class_cm.member_name, "", _QROffset(),  gen_index);
   }

   _GoToROffset(curr_offset);
}


static typeless get_class_members(VS_TAG_BROWSE_INFO class_cm, 
                                  int filter_flags, int context_flags, 
                                  VS_TAG_BROWSE_INFO (&member_list)[],
                                  VS_TAG_RETURN_TYPE (&visited):[])
{
   _str class_members[];

   _UpdateContext(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   tag_clear_matches();
   _str tag_files[] = tags_filenamea(class_cm.language);

   _str class_name = tag_join_class_name(class_cm.member_name,class_cm.class_name,tag_files,true,false);
   tag_list_in_class("",class_name,0,0,tag_files,
                     auto num_matches=0,def_tag_max_list_members_symbols,
                     filter_flags,context_flags,
                     false, true, null, null, visited);

   tag_remove_duplicate_symbol_matches();
   member_list._makeempty();
   _str def_files_hash:[];
   _str def_files[];
   for(i:=1; i <= tag_get_num_of_matches(); i++) {
      VS_TAG_BROWSE_INFO match_cm;
      tag_get_match_info(i,match_cm);
      member_list[member_list._length()] = match_cm;

      // Make sure that the match is actually inside the class definition because list_in_class
      // picks up externally defined methods(C++)
      if(match_cm.file_name == class_cm.file_name && match_cm.seekpos >= class_cm.seekpos && match_cm.seekpos < class_cm.end_seekpos) {
         class_members[class_members._length()] = match_cm.member_name;
      }
   }

   return class_members;
}
/**
 * 
 * Rename this bad name
 * 
 * @param cm
 * @param class_cm
 * @param method_list
 * 
 * @return typeless
 */
static typeless ask_for_file_to_insert_methods(VS_TAG_BROWSE_INFO class_cm, 
                                               int context_flags, _str &maybe_class_def_file,
                                               VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   // Default to same file as definition. This should be the only choice for most languages
   // except for C++
   maybe_class_def_file = class_cm.file_name;

   _str class_methods[];

   tag_clear_matches();
   _str tag_files[] = tags_filenamea(class_cm.language);

   int i, num_matches=0;
   tag_list_in_class("",class_cm.member_name,0,0,tag_files,
                     num_matches,def_tag_max_list_members_symbols,
                     VS_TAGFILTER_ANYPROC,context_flags,
                     false, true, null, null, visited);

   //method_list._makeempty();
   _str def_files_hash:[];
   _str def_files[];
   for(i=1; i <= tag_get_num_of_matches(); i++) {
      VS_TAG_BROWSE_INFO match_cm;
      tag_get_match_info(i,match_cm);
      //method_list[method_list._length()] = match_cm;

      // Make sure that the match is actually inside the class definition because list_in_class
      // picks up externally defined methods(C++)
      if(match_cm.file_name == class_cm.file_name && match_cm.seekpos >= class_cm.seekpos && match_cm.seekpos < class_cm.end_seekpos) {
         class_methods[class_methods._length()] = match_cm.member_name;
      } else if(!(class_cm.flags & VS_TAGFLAG_inclass)) {
         // This might be where the function definitions for this class are put. Remember it.
         if(!def_files_hash._indexin(match_cm.file_name)) {
            def_files[def_files._length()] = match_cm.file_name;
            def_files_hash:[match_cm.file_name]=true;
         }
      }
   }

   i=0;
   if(def_files._length() > 1) {
      _str old_scroll_style=_scroll_style();
      _scroll_style('c');
      i=show("_sellist_form -mdi -modal -reinit",
                     nls("Which file should the getter and setter function definitions be placed?"),
                     SL_DEFAULTCALLBACK|SL_SELECTCLINE,
                     def_files,
                     "",
                     "",  // help item name
                     "",  // font
                     _taglist_callback  // Call back function
                    );
   }

   // Default to class declaration file
   if(def_files._length() == 0 || i == "") {
      maybe_class_def_file=class_cm.file_name;
   } else {
      maybe_class_def_file=def_files[i];
   }

   return class_methods;
}

static void change_references_to_function_calls(int handle, 
                                                VS_TAG_BROWSE_INFO &cm, 
                                                _str getter_name, _str setter_name,
                                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // find all the references to this tag
   int seekPositions[]; seekPositions._makeempty();
   _str errorArgs[]; errorArgs._makeempty();
   int numReferences = 0, maxReferences = def_cb_max_references;
   tag_match_occurrences_in_file_get_positions(errorArgs, seekPositions, 
                                               cm.member_name, p_EmbeddedCaseSensitive,
                                               cm.file_name, cm.line_no, 
                                               VS_TAGFILTER_ANYTHING, 0, 0,
                                               numReferences, maxReferences, 
                                               visited, depth);

   // go through the file backwards
   int status, j,m = seekPositions._length();
   for (j=m-1; j>=0; --j) {

      //say("seekPositions["j"]="seekPositions[j]);

      // Don't change declaration reference. If this reference is within the scope of the symbol 
      // declaration then skip it.
      if(p_buf_name == cm.file_name && (seekPositions[j] >= cm.seekpos && seekPositions[j] <= cm.end_seekpos)) {
         continue;
      }
      // go to the seek position
      status = _GoToROffset(seekPositions[j]);
      if (status < 0) continue;

      VS_TAG_BROWSE_INFO match_cm;
      tag_get_browse_info("", match_cm, true, null, false, true, true, false, false, false, visited, depth+1);
      if(match_cm.type_name != 'var') {
         continue;
      }

      VS_TAG_REFERENCE_INFO ref_info;
      boolean use_setter = c_reference_is_modified(cm.member_name, ref_info, visited, depth);

      if(use_setter) {
         _GoToROffset(ref_info.statement_start);
         _delete_text(length(ref_info.statement));
         _str leading_whitespace = get_line_leading_whitespace(ref_info.statement, true);
         if(ref_info.array_index != null && ref_info.array_index != '') {
            _insert_text(leading_whitespace :+ setter_name :+ "(" :+ ref_info.array_index:+ ", " :+ ref_info.rhs :+");");
         } else {
            _insert_text(leading_whitespace :+ setter_name :+ "(" :+ ref_info.rhs :+ ");");
         }
      } else {
         _delete_text(ref_info.end_id_seek - ref_info.start_id_seek);
         if(ref_info.array_index != null && ref_info.array_index != '') {
            _insert_text(getter_name :+ "(" :+ ref_info.array_index :+ ")");
         } else {
            _insert_text(getter_name :+ "()");
         }
      }
   }
}

static int update_browse_infos(typeless &symbol_pos, typeless &class_pos, 
                               struct VS_TAG_BROWSE_INFO &cm, 
                               struct VS_TAG_BROWSE_INFO &class_cm,
                               VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   long current_offset = _QROffset();
   _restore_pos2(symbol_pos);
   _save_pos2(symbol_pos);
   _UpdateContext(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int status = tag_get_browse_info("", cm, true, null, false, true, true, false, false, false, visited, depth+1);
   if(status != 0) {
      return -1;
   }

   _restore_pos2(class_pos);
   _save_pos2(class_pos);
   status =  get_class_context(cm.seekpos,class_cm);
   _GoToROffset(current_offset);
   return status;
}

/**
 * Manage a hash table mapping filenames to temp views.
 * If a temp view has not been created for a particular file
 * then create the temp view.
 * 
 * @param file_view_hash
 * @param filename
 * 
 * @return int temp_view opened to this file
 */
static int file_get_view(int (&file_view_hash):[], _str filename) 
{
   // is this file already in the hash table?
   if (file_view_hash._indexin(filename)) {
      return file_view_hash:[filename];
   }

   // nope, then open it
   boolean alreadyExists=false;
   int hash_temp_view_id=0, hash_orig_view_id=0;
   int status = _open_temp_view(filename, hash_temp_view_id, hash_orig_view_id, "+d", alreadyExists, false, true);
   if (status < 0) return status;
   file_view_hash:[filename] = hash_temp_view_id;
   return hash_temp_view_id;
}

/**
 * Close all temp views found in the given hash table
 * @param file_view_hash   hash table of files => view ids
 * @see file_get_view
 */
static void file_hash_delete_temp_views(int (&file_view_hash):[])
{
   typeless i;
   for (i._makeempty();;) {
      file_view_hash._nextel(i);
      if (i._isempty()) break;

      _delete_temp_view(file_view_hash:[i]);
   }
}

/**
 * For each modified file in the list of files modified by this
 * refactoring, add it to the transaction's list of modified files.
 * 
 * @param handle           refactoring transaction handle
 * @param file_view_hash   hash tables (file names => view ids)
 * 
 * @return number of modified files added
 */
int file_hash_set_modified_file_contents(int handle, int (&file_view_hash):[])
{
   int count=0;
   typeless element;
   for (element._makeempty();;) {
      file_view_hash._nextel(element);
      if (element._isempty()) break;
      int view_id = file_view_hash:[element];
      activate_window(view_id);
      if (view_id.p_modify) {
         refactor_set_modified_file_contents(view_id, handle, element);
         count++;
      }
   }
   return count;
}

int refactor_start_quick_encapsulate(struct VS_TAG_BROWSE_INFO cm)
{
   //say("refactor_start_quick_encapsulate");
   //say("********************************");

   long offset = _QROffset();

   // Start the transaction and get the handle for the transaction
   _str fileList[];
   int orig_view_id = p_window_id;

   int handle = refactor_start_refactoring_transaction(cm, fileList);
   if(handle < 0 && handle!=COMMAND_CANCELLED_RC) {
      _message_box("Quick Encapsulate field failed:  ":+get_message(handle));
      return handle;
   }

   if(handle == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   // Validate choice.
   if(cm.class_name == "" || cm.type_name != 'var') {
      refactor_cancel_transaction(handle);
      _message_box("Quick Encapsulate field failed:  The symbol "cm.member_name" must be a class field");
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   // Create view file mapping for all files that could potentially change
   int i, temp_view, file_view_hash:[];

   show_cancel_form("Refactoring", "", true, true);

   // Open up a temp view for the definition file and place the cursor where the definition is.
   boolean alreadyExists = false;

   temp_view = file_get_view(file_view_hash, cm.file_name);
   if (temp_view < 0) {
      // TBF: handle error
   }
   activate_window(temp_view);

   _SetEditorLanguage();

   // Put cursor on the symbol definition.
   _GoToROffset(offset);

   // Bookmark position of member. It's seek position could change as a result of insertions and deletions.
   typeless member_pos;
   _save_pos2(member_pos);

   VS_TAG_BROWSE_INFO class_cm;
   int status = get_class_context(cm.seekpos,class_cm);
   if(status < 0) {
      refactor_cancel_transaction(handle);
      close_cancel_form(cancel_form_wid());
      _message_box("Quick Encapsulate field failed:  The symbol "cm.member_name" must be a class field");
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   // Bookmark position of class. It's seek position could change as a result of insertions and deletions.
   typeless class_pos;
   _save_pos2(class_pos);

   VS_TAG_RETURN_TYPE visited:[];
   update_browse_infos(member_pos, class_pos, cm, class_cm, visited);

   // get list of public class methods in the class declaration
   VS_TAG_BROWSE_INFO method_list[];
   _str maybe_class_def_file="";
   _str class_methods[] = get_class_members(class_cm, VS_TAGFILTER_ANYPROC, VS_TAGCONTEXT_ACCESS_public, method_list, visited);

   for(i=0; i < class_methods._length(); i++) {
      strappend(class_methods[i], "(" :+  method_list[i].arguments :+ ")");
   }

   update_browse_infos(member_pos, class_pos, cm, class_cm, visited);

   // close this cancel form
   close_cancel_form(cancel_form_wid());

   _str result = show('-modal _refactor_encapsulate_field_form', handle, cm.member_name, class_methods);

   if(result == "") {
      return COMMAND_CANCELLED_RC;
   }
   // Grab the getter and setter names and the name of the method to insert the getter and setter after
   _str getter_name, setter_name, method_to_insert_after;
   parse result with getter_name PATHSEP setter_name PATHSEP method_to_insert_after;

   class_methods = ask_for_file_to_insert_methods(class_cm, VS_TAGCONTEXT_ACCESS_public, maybe_class_def_file);

   // Change references in all files
   int curr_view = p_window_id;
   long curr_offset = _QROffset();
   for(i=0; i < fileList._length(); i++) {
      temp_view = file_get_view(file_view_hash, fileList[i]);
      if (temp_view < 0) {
         // TBF: handle error
      } else {
         activate_window(temp_view);
         change_references_to_function_calls(handle, cm, getter_name, setter_name);
      }
   }
   activate_window(curr_view);
   _GoToROffset(curr_offset);

   // Move cursor to place to insert getter and setter
   long insertion_seekpos = get_class_insertion_point(class_cm, method_list, method_to_insert_after);

   // Create getter and setter function inside the class
   if(_LanguageInheritsFrom('c', cm.language)) {
      boolean make_protos = true;
      boolean in_class = true;

      _GoToROffset(insertion_seekpos);

      create_getter_and_setter_functions(handle, cm, class_cm,  getter_name, setter_name, make_protos, in_class, insertion_seekpos);

      temp_view = file_get_view(file_view_hash, maybe_class_def_file);
      if(temp_view < 0) {
         // TBF: handle error
      } else {
         activate_window(temp_view);
      }

      // Create functions at the end of the file
      _GoToROffset(p_buf_size);
      make_protos = false;
      in_class = false;
      create_getter_and_setter_functions(handle, cm, class_cm,  getter_name, setter_name, make_protos, in_class, -1);

      temp_view = file_get_view(file_view_hash, class_cm.file_name); 
      if(temp_view < 0) {
         // TBF: handle error
      } else {
         activate_window(temp_view);
      }
   } else {
      boolean make_protos = false;
      boolean in_class = true;
      create_getter_and_setter_functions(handle, cm, class_cm,  getter_name, setter_name, make_protos, in_class, insertion_seekpos);
   }

   make_field_private(member_pos, class_cm, cm);

   // save the files modified by this transaction
   file_hash_set_modified_file_contents(handle,file_view_hash);

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, 0, 
                                          "Failed to encapsulate field.",
                                          "Quick encapsulate field", '');
   return 0;
}

_command int refactor_quick_encapsulate_field() name_info(FILE_ARG',')
{
   // init refactoring operations
   if (!refactor_init(true, false)) {
      return COMMAND_CANCELLED_RC;
   }

   VS_TAG_RETURN_TYPE visited:[];
   struct VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);

   int status = tag_get_browse_info("", cm, true, null, false, true, true, false, false, false, visited);
   if(status != 0) {
      return status;
   }

   return refactor_start_quick_encapsulate(cm);
}

int _OnUpdate_refactor_quick_encapsulate_field(CMDUI &cmdui,int target_wid,_str command)
{
   // TBF: disable this feature for the 11.0 beta
   return MF_GRAYED;

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');
   if (clex_color!=CFG_WINDOW_TEXT && clex_color!=CFG_LIBRARY_SYMBOL && clex_color!=CFG_USER_DEFINED) {
      return(MF_GRAYED);
   }

   // Only support java and C++ for now. Slick-C doesn't make sense right now but would work if it had classes.
   if(!_LanguageInheritsFrom('java', target_wid.p_LangId) && !_LanguageInheritsFrom('c', target_wid.p_LangId)) {
      return (MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command, false, true);
}


struct VS_TAG_FUNCTION_INFO
{
   // Browse info describing the function definition
   VS_TAG_BROWSE_INFO function_cm;

   // Information about each argument
   VSAUTOCODE_ARG_INFO arguments[];
   VS_TAG_RETURN_TYPE return_types[];
   _str default_values[];

   // Mapping of parameter indexes to original parameter
   // indexes.  >0 is the index of one of the original
   // parameters, <0 is the index of a new parameter
   int param_mapping[];

   // prototype and default values for function after editing
   _str param_protos[];
   _str param_defaults[];
};

void tag_function_info_init(VS_TAG_FUNCTION_INFO &function_info)
{
   tag_browse_info_init(function_info.function_cm);
   function_info.arguments._makeempty();
   function_info.return_types._makeempty();
   function_info.default_values._makeempty();
   function_info.param_mapping._makeempty();
   function_info.param_defaults._makeempty();
   function_info.param_protos._makeempty();
}

void tag_function_info_dump(VS_TAG_FUNCTION_INFO function_info, _str where="", int level=0)
{
   isay(level,"//=================================================================");
   isay(level,"// VS_TAG_FUNCTION_INFO from " where);
   isay(level,"//=================================================================");

   int i;
   tag_browse_info_dump(function_info.function_cm);
   for(i=0; i < function_info.arguments._length(); i++) {
      tag_autocode_arg_info_dump(function_info.arguments[i], "argument " :+i);
      tag_return_type_dump(function_info.return_types[i], "type ":+i);
      if (function_info.default_values[i] != '') {
         say("tag_function_info_dump: default value="function_info.default_values[i]);
      }
   }
}

struct VS_TAG_FUNCTION_CALL_ARGUMENT
{
   VS_TAG_RETURN_TYPE type;
   boolean unrecognizable_type;
   _str text;
   int start_seekpos;
   int end_seekpos;
};

static int get_function_call_info(VS_TAG_FUNCTION_CALL_ARGUMENT (&args)[])
{
   // Simple dumb search for beginning of parameters when cursor is on function name.
   args._makeempty();
   int result = search("(","@h>Xcs");
   if (result < 0) {
      return result;
   }

   int first_arg_start = (int)_QROffset();
   int parens=0;
   while(result == 0) {
      _str current_char = get_text(1, (int)_QROffset()-1);
      if(current_char == "(") {
         parens++;
      }

      if(current_char == ")") {
         parens--;
      }

      if ((parens==0 && current_char==")") || (parens==1 && current_char==",")) {

         long end_offset = _QROffset();
         _GoToROffset(first_arg_start);
         if (pos(get_text(), " \t\r\n")) {
            _clex_skip_blanks('h');
            first_arg_start = (int)_QROffset();
         }
         _GoToROffset(end_offset);

         VS_TAG_FUNCTION_CALL_ARGUMENT argument;
         tag_return_type_init(argument.type);
         argument.text = get_text((int)_QROffset()-first_arg_start-1, first_arg_start);
         argument.start_seekpos = first_arg_start;
         argument.end_seekpos = (int)_QROffset()-1;
         argument.unrecognizable_type=false;

         first_arg_start = (int)_QROffset();
         if (parens == 0 && current_char == ')' && argument.text=='') {
            break;
         }

         _str errorArgs[];
         struct VS_TAG_RETURN_TYPE visited:[];
         int status = _c_get_type_of_prefix(errorArgs, argument.text, argument.type, visited);
         if(status != 0) {
            argument.unrecognizable_type=true;
            if(argument.text == "NULL" && _LanguageInheritsFrom('c')) {
               tag_return_type_init(argument.type);
               argument.type.return_type = "void*";
               argument.type.pointer_count = 1;
            }
         }

         args[args._length()] = argument; 
      }

      if(parens <= 0 || current_char == ";") {
         break;
      }

      result = search("[(,);]","@rh>Xcs");
   }

   //int i;
   //for(i=0; i < args._length(); i++) {
   //   say("args["i"]="args[i].text" return_type="args[i].type.return_type" start_seekpos="args[i].start_seekpos" end_seekpos="args[i].end_seekpos);
   //}

   return 0;
}

static int get_function_taginfo_index(VSAUTOCODE_ARG_INFO (&functionHelpList)[], 
                                      VS_TAG_BROWSE_INFO &cm)
{
   int i,n = functionHelpList._length();
   if (n==1) return 0;
   for (i=0; i<n; ++i) {
      VSAUTOCODE_ARG_INFO arg_info = functionHelpList[i];
      int j,m = arg_info.tagList._length();
      for (j=0; j<m; ++j) {
         if (file_eq(arg_info.tagList[j].filename, cm.file_name) &&
             arg_info.tagList[j].linenum == cm.line_no) {
            return i;
         }
      }
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * Get the function information including parameter information about a function definition
 * 
 * @param function_info       (output) Function information
 * @param cm                  Browse info for function definition
 * @param function_seekpos    Seek position to move cursor to to get info. -1 indicates use current cursor position.
 * 
 * @return 0 on success, non zero on error
 */
static int get_function_info(struct VS_TAG_FUNCTION_INFO &function_info,
                             struct VS_TAG_BROWSE_INFO &cm, int function_seekpos=-1,
                             typeless (&visited):[]=null, int depth=0)
{
   int current_offset = (int)_QROffset();
   if(function_seekpos != -1) {
      _GoToROffset(function_seekpos);
   }

   // Simple dumb search for beginning of parameters when cursor is on function name.
   int result = search("(","@h>Xcs");
   long offset = _QROffset();

   _str errorArgs[];
   VSAUTOCODE_ARG_INFO FunctionHelp_list[];
   boolean FunctionHelp_list_changed=false;
   int FunctionHelp_cursor_x=0;
   _str FunctionHelp_HelpWord="";
   int FunctionNameStartOffset=(int)offset-length(cm.member_name);
   int flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;

   tag_function_info_init(function_info);
   function_info.function_cm = cm;

   _str parameter_array[];
   split(cm.arguments, ',', parameter_array);

   int i, n = parameter_array._length();
   for(i=0; i < parameter_array._length(); i++) {

      _str arg_default = "";
      VSAUTOCODE_ARG_INFO arg_info;
      tag_autocode_arg_info_init(arg_info);

      save_pos(auto p);
      index := _FindLanguageCallbackIndex('_%s_fcthelp_get');
      if (!index) {
         return STRING_NOT_FOUND_RC;
      }

      int status=call_index(errorArgs, FunctionHelp_list, FunctionHelp_list_changed,
                            FunctionHelp_cursor_x, FunctionHelp_HelpWord,
                            FunctionNameStartOffset, flags, cm, visited, depth+1,
                            index);
      if (status < 0) {
         return STRING_NOT_FOUND_RC;
      }

      int j = get_function_taginfo_index(FunctionHelp_list,cm);
      if (j < 0) {
         return j;
      }

      // TBF:  get default argument value
      arg_info = FunctionHelp_list[j];
      _str arg_declaration = "";
      if (arg_info.ParamNum < arg_info.argstart._length() && arg_info.ParamNum < arg_info.arglength._length()) {
         arg_declaration = substr(arg_info.prototype,arg_info.argstart[arg_info.ParamNum],arg_info.arglength[arg_info.ParamNum]);
      }
      parse arg_declaration with . "=" arg_default;

      // Build return type for function parameter
      VS_TAG_RETURN_TYPE rt;
      tag_return_type_init(rt);
      rt.filename = p_buf_name;
      rt.line_number = p_line;
      rt.istemplate = 0;

      // Count *'s
      int count=0,position=pos("*",arg_info.ParamType);
      while(position != 0) {
         position=pos("*", arg_info.ParamType, position+1);
         count++;
      }

      rt.pointer_count = count;
      rt.return_type = arg_info.ParamType;
      rt.return_flags = 0;
      rt.taginfo = tag_tree_compose_tag(arg_info.ParamName, "", 'param', 0, '', arg_info.ParamType);

      // analyze the expected return type
      ar_index := _FindLanguageCallbackIndex('_%s_analyze_return_type');
      if(status == 0 && ar_index) {
         typeless tag_files = tags_filenamea(cm.language);
         status = call_index(errorArgs,tag_files,
                             arg_info.ParamName, '', 'param',
                             cm.flags, cm.file_name, arg_info.ParamType,
                             rt,visited,ar_index);
      }

      function_info.arguments[function_info.arguments._length()] = arg_info;
      function_info.return_types[function_info.return_types._length()] = rt;
      function_info.default_values[function_info.default_values._length()] = arg_default;

      // Must be another parameter jump to next comma
      if(i < parameter_array._length()-1) {
         restore_pos(p);
         search(",", "@h>Xcs");
      }
   }

   //tag_function_info_dump(function_info);
   if(function_seekpos != -1) {
      _GoToROffset(current_offset);
   }

   return 0;
}

/**
 * Check if the function call under the cursor matches the given
 * symbol information, comparing the argument lists for assignment
 * compatibility.  The current object must be an editor control
 * positioned on the name of a function being called.
 * 
 * @param cm  symbol information to test instance against
 * 
 * @return 1 if they successfully match, 0 if not, <0 on error
 */
int tag_check_function_parameter_list(VS_TAG_BROWSE_INFO cm,
                                      VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // check if this is Slick-C, which does not have overloading
   if (_LanguageInheritsFrom('e')) {
      return 1;
   }

   // get more details about 'cm'
   save_pos(auto p);
   tag_push_matches();
   int status = tag_refine_symbol_match(cm, true);
   if (status < 0) {
      tag_pop_matches();
      restore_pos(p);
      return status;
   }

   // open the file in a temp view
   boolean alreadyExists=false;
   int temp_view_id=0, orig_view_id=0;
   status = _open_temp_view(cm.file_name, temp_view_id, orig_view_id, "", alreadyExists, false, true);
   if (status < 0) { 
      tag_pop_matches();
      restore_pos(p);
      return status;
   }

   // go to it's exact location
   _GoToROffset(cm.seekpos);

   // get the information about this function
   VS_TAG_FUNCTION_INFO function_info;
   status = get_function_info(function_info, cm, -1, visited, depth);
   if (status < 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      tag_pop_matches();
      restore_pos(p);
      return status;
   }

   // clean up
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   
   // now we know about the function that was passed in
   // now get the information about the argument list under
   // the cursor
   // save current cursor position
   boolean inFunctionHeader=false;
   boolean inFunctionProto=false;
   VS_TAG_FUNCTION_CALL_ARGUMENT args[]; args._makeempty();
   status = refactor_check_function_parameter_list(function_info, args, 
                                                   inFunctionHeader, 
                                                   inFunctionProto,
                                                   visited, depth);
   if (status < 0) {
      restore_pos(p);
      tag_pop_matches();
      return 0;
   }

   // no errors, we have a match
   restore_pos(p);
   tag_pop_matches();
   return 1;
}

static int refactor_check_function_parameter_list(VS_TAG_FUNCTION_INFO &function_info,
                                                  VS_TAG_FUNCTION_CALL_ARGUMENT (&args)[],
                                                  boolean &inFunctionHeader,
                                                  boolean &inFunctionProto,
                                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // If the item is part of a function definition or prototype 
   // for this function.  Test this by checking if the current item
   // under the cursor is a function and our seekpos falls between
   // it's start and scope.  If so it is the function definition and
   // we can ignore it.
   // 
   long orig_seekpos = _QROffset();
   boolean inSpecifiedFunction=false;
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   VS_TAG_BROWSE_INFO proto_cm;
   tag_browse_info_init(proto_cm);

   int context_id = tag_current_context();
   if (context_id > 0) {
      _str context_type = '';
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, context_type);
      if (tag_tree_type_is_func(context_type)) {
         tag_get_context_info(context_id, proto_cm);
         if (proto_cm.seekpos <= orig_seekpos && orig_seekpos < proto_cm.scope_seekpos) {
            inFunctionHeader=true;
            inFunctionProto=(context_type=='proto' || context_type=='procproto');
            if (proto_cm.seekpos==function_info.function_cm.seekpos &&
                file_eq(p_buf_name, function_info.function_cm.file_name)) {
               inSpecifiedFunction=true;
               inFunctionProto=true;
            }
            if (_LanguageInheritsFrom('java')) {
               inFunctionProto=false;
            }
         }
      }
   }

   // get the arguments for this function call instance
   static typeless last_bufid;
   static typeless last_offset;
   static typeless last_modified;
   static typeless last_args;
   if (p_buf_id == last_bufid && orig_seekpos == last_offset && p_LastModified == last_modified) {
      args = last_args;
   } else {
      get_function_call_info(args);
      last_bufid= p_buf_id;
      last_offset = orig_seekpos;
      last_modified = p_LastModified;
      last_args = args;
   }

   // too many arguments, this is NOT a reference to the function
   int i,n = args._length();
   int m = function_info.arguments._length(); 
   if (n > m) {
      return -1;
   }

   // check if unspecified arguments have default values
   for (i=n; i<m; ++i) {
      if (inFunctionHeader || function_info.default_values[i]=="") {
         if (m==1 && function_info.return_types[i].return_type=="void") continue;
         if (pos('proto', function_info.function_cm.type_name)) {
            return -1;
         }
      }
   }

   // if this is a function header, replace the arg
   // return types with more accurate function header information
   if (inFunctionHeader) {
      VS_TAG_FUNCTION_INFO proto_info;
      tag_function_info_init(proto_info);
      get_function_info(proto_info, proto_cm, -1, visited, depth+1);
      for (i=0; i<n; ++i) {
         if (i < proto_info.arguments._length()) {
            args[i].type=proto_info.return_types[i];
         }
      }
   }

   // check that we have a return type matching function, or use default
   rt_index := _FindLanguageCallbackIndex('_%s_match_return_type');
   if (!rt_index) {
      rt_index = find_index('_do_default_match_return_type',PROC_TYPE);
   }

   // check the rest of the arguments for assignment compatibilty
   typeless tag_files = tags_filenamea();
   for (i=0; i<n; ++i) {
      _str call_type = args[i].type.return_type;
      _str def_type = function_info.arguments[i].ParamType;

      // exact match, short cut the comparison
      if (call_type == def_type) {
         continue;
      }

      // is this the function we are operating on?
      if (inSpecifiedFunction) {
         break;
      }

      // expression too complex to handle accurately, punt
      if (args[i].unrecognizable_type) {
         continue;
      }

      // slick-c does not have overloading
      if (_LanguageInheritsFrom('e')) break;

      // compare the actual argument to the formal argument
      _str arg_tag_name='anonymous';
      _str arg_tag_class='';
      _str arg_tag_type='lvar';
      int arg_tag_flags=0;
      if (args[i].type.taginfo!='') {
         tag_tree_decompose_tag(args[i].type.taginfo, 
                                arg_tag_name, arg_tag_class, arg_tag_type, arg_tag_flags);
      }

      // create a new match set, match_return_type will insert into the set
      tag_push_matches();
      call_index(function_info.return_types[i],
                 args[i].type, arg_tag_name, arg_tag_type, arg_tag_flags,
                 p_buf_name, p_line, '', tag_files,  0, 0,
                 rt_index);

      // check if there is a natural match in the match set
      boolean match = false;
      int k;
      for (k=1; k<=tag_get_num_of_matches(); ++k) {
         _str match_name='';
         tag_get_detail2(VS_TAGDETAIL_match_name, k, match_name);
         if (match_name == arg_tag_name) {
            match = true;
         }
      }

      // clear out the match set, bail out if there are not matches
      tag_pop_matches();
      if (!match) {
         return -1;
      }
   }

   return 0;
}

static int quick_modify_parameters_maybe_change_reference(VS_TAG_FUNCTION_INFO& function_info,
                                                          VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // check if this instance matches the given function
   boolean inFunctionHeader=false;
   boolean inFunctionProto=false;
   VS_TAG_FUNCTION_CALL_ARGUMENT args[];
   int status = refactor_check_function_parameter_list(function_info, args, 
                                                       inFunctionHeader, 
                                                       inFunctionProto,
                                                       visited, depth);
   if (status < 0) {
      return status;
   }

   // trim off trailing arguments that were previously defaulted
   int i,m = function_info.param_mapping._length();
   if (!inFunctionHeader) {
      while (m > 0) {
         i = function_info.param_mapping[m-1];
         if (i <= args._length()) break;
         --m;
      }
   }

   // remove any left-over parameters
   long orig_seekpos = _QROffset();
   if (args._length() > m) {
      VS_TAG_FUNCTION_CALL_ARGUMENT first_arg = args[m];
      VS_TAG_FUNCTION_CALL_ARGUMENT  last_arg = args[args._length()-1];
      _GoToROffset(first_arg.start_seekpos);
      while (p_col > 1) {
         left();
         if (get_text()!=' ') break;
      }
      if (get_text()!='(' && get_text()!=',') {
         _clex_skip_blanks('-h');
      }
      if (get_text()==',' || get_text()=='(') {
         if (get_text()=='(') right();
         first_arg.start_seekpos = (int) _QROffset();
      }
      _delete_text(last_arg.end_seekpos-first_arg.start_seekpos);
   }

   // now we move the parameters around
   boolean in_default_args = !_LanguageInheritsFrom('java');
   for (i=m-1; i>=0; --i) {

      // get the default value for this argument
      _str def_value = function_info.param_defaults[i];
      if (def_value=='') in_default_args=false;

      // now figure out the argument text to plug in here
      _str arg_text = "";
      int arg_index = function_info.param_mapping[i];
      if (inFunctionHeader) {
         // get the new function prototype
         arg_text = function_info.param_protos[i];
         if (def_value != '') {
            if (inFunctionProto) {
               arg_text = arg_text:+"=":+def_value;
            } else {
               arg_text = arg_text:+" /*=":+def_value:+"*/";
            }
         }
      } else if (arg_index < 0) {
         // use new [default] argument
         if (in_default_args) continue;
         _str arg_proto = function_info.param_protos[i];
         if (def_value != '') arg_proto = arg_proto:+"="def_value;
         arg_text = "<<":+"<":+arg_proto:+">>":+">";
      } else if (arg_index-1 < args._length()) {
         // use the original argument
         arg_text = args[arg_index-1].text;
      } else {
         // check if this argument has a default arg
         if (in_default_args) continue;
         arg_text = function_info.default_values[arg_index-1];
         if (arg_text == '') {
            arg_text = "<<":+"<":+def_value:+">>":+">";
         }
      }

      // go to the position of the argument
      if (i < args._length()) {
         VS_TAG_FUNCTION_CALL_ARGUMENT this_arg = args[i];
         _GoToROffset(this_arg.start_seekpos);
      } else if (args._length() > 0) {
         VS_TAG_FUNCTION_CALL_ARGUMENT last_arg = args[args._length()-1];
         _GoToROffset(last_arg.end_seekpos);
      } else {
         _GoToROffset(orig_seekpos);
         search('(','@h>Xcs');
      }

      // now insert the argument, two cases, replacement and appending new arg
      if (i < args._length()) {
         // replacing existing argument
         VS_TAG_FUNCTION_CALL_ARGUMENT this_arg = args[i];
         _str orig_text = get_text(this_arg.end_seekpos-this_arg.start_seekpos);
         if (arg_text != orig_text) {
            _delete_text(this_arg.end_seekpos-this_arg.start_seekpos);
            _insert_text(arg_text);
         }
      } else {
         // appending new argument
         if (i > 0) {
            _insert_text(",");
            if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA)) {
               _insert_text(" ");
            }
         } else {
            if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
               _insert_text(" ");
            }
         }
         _insert_text(arg_text);
      }
   }

   // that's all folks
   return 0;
}

static int quick_modify_parameters_change_references_in_file(int progressFormID,
                                                             int (&file_view_hash):[],
                                                             _str file_name,
                                                             VS_TAG_FUNCTION_INFO &function_info,
                                                             VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // Open file in temp view
   int temp_view = file_get_view(file_view_hash, file_name);
   if (temp_view < 0) {
      // TBF: handle error
      return temp_view;
   }
   activate_window(temp_view);

   // find all the references to this tag
   struct VS_TAG_BROWSE_INFO cm = function_info.function_cm;
   int seekPositions[]; seekPositions._makeempty();
   _str errorArgs[]; errorArgs._makeempty();
   int maxReferences = def_cb_max_references;
   int numReferences = 0;
   tag_match_occurrences_in_file_get_positions(errorArgs, seekPositions,
                                               cm.member_name, p_EmbeddedCaseSensitive,
                                               cm.file_name, cm.line_no,
                                               VS_TAGFILTER_ANYTHING, 0, 0,
                                               numReferences, maxReferences, 
                                               visited, depth);

   // go through the file backwards
   boolean comment_defaults=false;
   int j,m = seekPositions._length();
   for (j=m-1; j>=0; --j) {

      // check if they hit cancel
      if (cancel_form_cancelled()) {
         return COMMAND_CANCELLED_RC;
      }

      // go to the seek position
      int status = _GoToROffset(seekPositions[j]);
      if (status < 0) continue;

      // now attempt to modify the reference to this function
      quick_modify_parameters_maybe_change_reference(function_info, visited, depth+1);
   }

   // that's all folks
   return 0;
}

static int quick_modify_parameters_change_references(int (&file_view_hash):[],
                                                     VS_TAG_FUNCTION_INFO &function_info,
                                                     _str fileList[],
                                                     VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // if the file count is high enough, show progress dialog
   struct VS_TAG_BROWSE_INFO cm = function_info.function_cm;
   int progressFormID = show_cancel_form("Finding files that reference '" cm.member_name "'", null, true, true);
   if (cancel_form_cancelled(0)) {
      return COMMAND_CANCELLED_RC;
   }

   // iterate over the file list, making sure they really refer to the object
   boolean comment_defaults=false;
   int i, n = fileList._length();
   for (i=0; i<n; i++) {

      if (cancel_form_cancelled(0)) {
         return COMMAND_CANCELLED_RC;
      }

      // show this file going through
      _str file_name = fileList[i];
      _SccDisplayOutput("Parsing:  \""file_name"\"", false);
      int max_label2_width=cancel_form_max_label2_width(progressFormID);
      _str sfilename=progressFormID._ShrinkFilename(file_name,max_label2_width);
      cancel_form_set_labels(progressFormID,"Parsing:",sfilename);
      cancel_form_progress(progressFormID,i+1,n);

      // and then change the references in the file
      int status = quick_modify_parameters_change_references_in_file(progressFormID,
                                                                     file_view_hash, file_name,
                                                                     function_info, visited, depth+1);
      if (status == COMMAND_CANCELLED_RC) {
         return status;
      }
   }

   // kill progress form
   if(progressFormID) {
      close_cancel_form(progressFormID);
   }

   return 0;
}

/**
 * 
 * @param cm
 * 
 * @return int
 */
int refactor_start_quick_modify_params(struct VS_TAG_BROWSE_INFO cm,
                                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // Start the transaction and get the handle for the transaction
   int handle = refactor_begin_transaction();
   if (handle < 0 && handle!=COMMAND_CANCELLED_RC) {
      _message_box("Quick Modify parameters failed:  ":+get_message(handle));
      return handle;
   }
   if (handle == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   // Validate choice.
   if (!tag_tree_type_is_func(cm.type_name)) {
      refactor_cancel_transaction(handle);
      _message_box("Quick Modify parameters failed:  The symbol "cm.member_name" must be a function");
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }
   if (cm.flags & VS_TAGFLAG_operator) {
      refactor_cancel_transaction(handle);
      _message_box("Quick Modify parameters failed:  Can not modifiy parameters to overloaded operator");
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }
   if (cm.flags & VS_TAGFLAG_const_destr) {
      refactor_cancel_transaction(handle);
      _message_box("Quick Modify parameters failed:  Can not modifiy parameters to constructor");
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   // Create view file mapping for all files that could potentially change
   int file_view_hash:[];
   file_view_hash._makeempty();

   //show_cancel_form("Refactoring", "", true, true);
   int i=0;
   int temp_view = file_get_view(file_view_hash, cm.file_name);
   if (temp_view < 0) {
      refactor_cancel_transaction(handle);
      _message_box("Quick Modify parameters failed:  Could not open file: "cm.file_name);
      return COMMAND_CANCELLED_RC;
   }
   activate_window(temp_view);
   _SetEditorLanguage();
   tag_refine_symbol_match(cm);
   _GoToROffset(cm.seekpos);

   // get the information about this function call
   VS_TAG_FUNCTION_INFO function_info;
   int status = get_function_info(function_info, cm);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      file_hash_delete_temp_views(file_view_hash);
      _message_box("Quick Modify parameters: failed to get function parameter information");
      return COMMAND_CANCELLED_RC;
   }

   // Format of parameters info
   // <Number of parameters>@return_type$
   // <Original Parameter Position>@<Argument Type String>@<Argument Name>@<Default Value>@[no_refs|has_refs]@[old|new]$
   // ...
   _str param_info="";
   strappend(param_info, function_info.arguments._length());
   strappend(param_info, "@");
   strappend(param_info, cm.return_type);
   strappend(param_info, "$");
   for(i=0; i < function_info.arguments._length(); i++) {
      strappend(param_info, i :+ "@");
      strappend(param_info, function_info.arguments[i].ParamType :+ "@");
      strappend(param_info, function_info.arguments[i].ParamName :+ "@");
      strappend(param_info, function_info.default_values[i] :+ "@"); // Default value
      strappend(param_info, "no_refs" :+ "@");
      strappend(param_info, "old" :+ "$");
   }

   // Bring up modify parameter dialog
   _str newParamInfo = show("-modal -xy _refactor_modify_params_form", cm.member_name, param_info, true);
   if(newParamInfo == "") {
      refactor_cancel_transaction(handle);
      file_hash_delete_temp_views(file_view_hash);
      return COMMAND_CANCELLED_RC;   
   }

   // Parse out results
   _str num_params, return_type;
   parse newParamInfo with num_params '@' return_type '$' newParamInfo;

   // Build new arugment string
   _str new_arguments = "";
   _str new_arg_names[];
   new_arg_names._makeempty();
   for(i=0; i < (int)num_params; i++) {
      _str index, param_type, param_name, default_value, refs, old_or_new;
      parse newParamInfo with index '@' param_type '@' param_name '@' default_value '@' refs '@' old_or_new '$' newParamInfo;

      // except for Java, clip off the array parameters so we can
      // put them back in the right place.
      _str param_array_info = "";
      int param_array_pos = pos('(\[|\:\[)',param_type,1,'r');
      if (param_array_pos > 0 && !pos('(',param_type) && !_LanguageInheritsFrom("java")) {
         param_array_info = substr(param_type,param_array_pos);
         param_type = substr(param_type,1,param_array_pos-1);
      }

      _str this_arg="";
      strappend(this_arg,param_type);
      if (!pos("[(] *[*&] *":+_escape_re_chars(param_name):+" *[)][\\:\\[\\]]*$", param_type, 1, 'r')) {
         strappend(this_arg," ");
         strappend(this_arg,param_name);
      }
      strappend(this_arg,param_array_info);

      new_arg_names[new_arg_names._length()] = param_name;
      function_info.param_defaults[function_info.param_defaults._length()] = default_value;
      function_info.param_protos[function_info.param_protos._length()] = this_arg;

      if(default_value != "" && !_LanguageInheritsFrom('java')) {
         strappend(this_arg," = ");
         strappend(this_arg,default_value);
      }
      strappend(new_arguments,this_arg);
      if(i < (int)num_params-1) {
         strappend(new_arguments,", ");
      }
   }

   // Build the argument mapping
   int n = new_arg_names._length();
   for (i=0; i<n; ++i) {
      function_info.param_mapping[i] = -i-1;
      int j,m = function_info.arguments._length();
      for (j=0; j<m; ++j) {
         if (function_info.arguments[j].ParamName == new_arg_names[i]) {
            function_info.param_mapping[i] = j+1;
            break;
         }
      }
   }

   // get the list of files which may have references to this function
   _str tag_files[] = tags_filenamea(cm.language);
   _str fileList[]; fileList._makeempty();
   status = refactor_get_quick_file_list(fileList, tag_files, cm.member_name);
   if (status < 0) {
      file_hash_delete_temp_views(file_view_hash);
      refactor_cancel_transaction(handle);
      return status;
   }

   // now change the references to the function
   status = quick_modify_parameters_change_references(file_view_hash, function_info, fileList, visited);
   if (status == COMMAND_CANCELLED_RC) {
      file_hash_delete_temp_views(file_view_hash);
      refactor_cancel_transaction(handle);
      return status;
   }

   // save the files modified by this transaction
   file_hash_set_modified_file_contents(handle,file_view_hash);
   file_hash_delete_temp_views(file_view_hash);

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, 0,
                                          "Failed to modify parameters.",
                                          "Quick modify parameters", '');
   return 0;
}

/**
 * 
 * 
 * @return int
 */
_command int refactor_quick_modify_params() name_info(FILE_ARG',')
{
   // init refactoring operations
   if (!refactor_init(true, false)) {
      return COMMAND_CANCELLED_RC;
   }

   // get the symbol information about the word under the cursor
   _UpdateContext(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   VS_TAG_RETURN_TYPE visited:[];
   struct VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   int status = tag_get_browse_info("", cm, false, null, false, true, false, true, false, true, visited);
   if (status == COMMAND_CANCELLED_RC) return status;
   if (status < 0) {
      //_message_box("Quick modify parameters failed: ":+get_message(status), "Quick Modify Parameters Refactoring");
      return status;
   }

   return refactor_start_quick_modify_params(cm, visited);
}

/**
 * 
 * @param cmdui
 * @param target_wid
 * @param command
 * 
 * @return int
 */
int _OnUpdate_refactor_quick_modify_params(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');
   if (clex_color!=CFG_FUNCTION) {
      return(MF_GRAYED);
   }

   // Only support java and C++ for now. Slick-C doesn't make sense right now but would work if it had classes.
   if(!_LanguageInheritsFrom('java', target_wid.p_LangId) && !_LanguageInheritsFrom('c', target_wid.p_LangId) && !_LanguageInheritsFrom('e', target_wid.p_LangId)) {
      return (MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command, false, true);
}

/**
 * Builds the string that will declared this constant
 * 
 * @param literal       literal to replace with a constant
 * @param constantName  name of constant to replace literal with
 * @param flags         The type of constant to create. I.E. VSREFACTOR_DEFTYPE_CONSTANT
 * @param literalType   The type information for the literal. (int, float, String, char etc)
 * 
 * @return _str declaration of constant
 */
_str make_constant_string(_str literal, _str constantName, int flags, _str literalType)
{
   // If we can't find get_decl then done't even try.
   get_decl_index := _FindLanguageCallbackIndex('_%s_get_decl');
   if(!get_decl_index) {
      return false;
   }

   // Build a browse info for get_decl() to use to create the declaration.
   VS_TAG_BROWSE_INFO constant_cm;
   tag_browse_info_init(constant_cm);

   // Fill in literal string and constantName
   constant_cm.member_name = constantName;

   // Setup the flags for the type of constant we are making.
   if(flags == VSREFACTOR_DEFTYPE_DEFINE) {
      constant_cm.type_name = 'define';
      constant_cm.return_type = literal;
   } else if(flags == VSREFACTOR_DEFTYPE_CONSTANT || flags == VSREFACTOR_DEFTYPE_STATIC) {
      constant_cm.type_name = 'var';
      constant_cm.return_type = literalType :+ "=" :+ literal;
   }

   if(flags == VSREFACTOR_DEFTYPE_STATIC) {
      constant_cm.flags |= VS_TAGFLAG_static; 
   }

   // Language specific flags.
   if(_LanguageInheritsFrom('java')) {
      constant_cm.flags |= VS_TAGFLAG_final;
   } else {
      constant_cm.flags |= VS_TAGFLAG_const;
   }

   // Make new declaration
   _str decl = call_index(p_LangId, constant_cm, 0, "", "", get_decl_index);

   if(flags != VSREFACTOR_DEFTYPE_DEFINE) {
      strappend(decl, ";");
   }

   return decl;
}

/**
 * Preform the replace literal refactoring
 * 
 * @param filename         file to replace literal in
 * @param literal_offset   position of cursor in this file that is on the literal we want to replace.
 * @param literal          literal to replace I.E. "Blah" 58 '\n'
 * @param constantName     Name of constant that will replace literal
 * @param flags            type of constant to create I.E. VSREFACTOR_DEFTYPE_STATIC
 * @param literal_type     type of literal. String, char *, const wchar_t, int, unsigned long etc.
 * 
 * @return int             returns 0 on success
 */
int refactor_start_quick_replace_literal(_str filename, long literal_offset, _str literal, _str constantName, int flags, _str literal_type)
{
   // begin the refactoring transaction
   int handle = refactor_begin_transaction(/*"Encapsulate Field"*/);
   if (handle < 0) {
      return handle;
   }

   // We don't care about any includes or defines
   int status = refactor_add_file(handle, filename, "", "", "", "");
   refactor_set_file_encoding(handle, filename, _EncodingToOption(p_encoding));
   if (status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // Create view file mapping for all files that could potentially change
   int i, temp_view, file_view_hash:[];

   // Open a temp view of current buffer and set it up. 
   boolean alreadyExists=false;
   int temp_view_id=0;
   int orig_view_id=0;
   status = _open_temp_view(filename, temp_view_id, orig_view_id, "+d", alreadyExists, false, true);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // Build the constant declaration
   _GoToROffset(literal_offset);
   _str constant_string = make_constant_string(literal, constantName, flags, literal_type);

   // Find a place to insert the declaration
   int insertion_line = 0;
   _str leading_ws="",t;
   if(_LanguageInheritsFrom('java')) {
      VS_TAG_BROWSE_INFO class_cm;
      get_class_context((int)_QROffset(), class_cm);
      insertion_line = class_cm.scope_line_no;

      // Grab a nearby statement and use it's leading whitespace
      int start_statement;
      p_line = insertion_line;
      _str statement = c_get_statement(start_statement, leading_ws, t);
   } else if(_LanguageInheritsFrom('c') || _LanguageInheritsFrom('e')){
      _GoToROffset(0);
      p_line=1;
      _UpdateContext(true, true);
      int color = _clex_find(0,'g');
      while((color == CFG_COMMENT || color == CFG_PPKEYWORD) && p_line < p_Noflines) {
         p_line++;
         color = _clex_find(0,'g');
      }
      insertion_line = p_line;
   }

   // save the original search options
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   // start at the bottom of the file and work backwards
   bottom();
   _end_line();

   status = search(literal, "@h-Xc");
   while (status == 0) {
      if (p_line <= insertion_line) {
         break;
      }

      // save the match length and cursor position
      int len = match_length();
      typeless p;save_pos(p);

      // Check that our match was not just a substring
      // of the constant we are replacing.
      long startSeekPos=0, endSeekPos=0;
      _str thisLiteral = findLiteralAtCursor(startSeekPos, endSeekPos);
      if (thisLiteral == literal) {

         // they match, now replace the text
         _delete_text(len);
         _insert_text(constantName);
      }

      // go back to original search position
      restore_pos(p);
      status = repeat_search();
   }

   // insert_line inserts to the line after so go backwards one line
   p_line = insertion_line;

   // insert declaration
   insert_line(leading_ws :+ constant_string);

   // restore search options
   restore_search(s1,s2,s3,s4,s5);

   // Save the modified contents of our temp view
   refactor_set_modified_file_contents(temp_view_id, handle, filename);

   // delete the temp view and restore our original view
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, 0, 
                                          "Failed to replace literal.", 
                                          "Quick replace literal (":+literal") with "constantName,
                                          '');
   return 0;
}

/**
 * Peform the quick replace literal command on the symbol under the cursor in 
 * current buffer.
 * 
 * @return int 0 on success nonzero on errorArgs.
 */
_command int refactor_quick_replace_literal() name_info(FILE_ARG',')
{
   // init refactoring operations
   if (!refactor_init(true, false)) {
      return COMMAND_CANCELLED_RC;
   }

   long startSeekPos,endSeekPos;
   _str literal = findLiteralAtCursor(startSeekPos, endSeekPos);
   if (literal == "") {
      _message_box("Replace Literal requires a string or number literal.");
      return COMMAND_CANCELLED_RC;
   }

   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   _str errorArgs[]; errorArgs._makeempty();

   _c_get_type_of_prefix(errorArgs, literal, rt);
   _str result = show('-modal _refactor_replace_literal_form', p_buf_name, literal, p_LangId, true);
   if (result == '') {
      return 0;
   }

   _str newName, sFlags;
   parse result with newName PATHSEP sFlags;

   return refactor_start_quick_replace_literal(p_buf_name, _QROffset(), literal , newName, (int)sFlags, rt.return_type);
}

/**
 * 
 * @param cmdui
 * @param target_wid
 * @param command
 * 
 * @return int
 */
int _OnUpdate_refactor_quick_replace_literal(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int startSeek,endSeek;
   _str literal = findLiteralAtCursor(startSeek,endSeek);

   if(_clex_find(0,'g')!=CFG_NUMBER && _clex_find(0,'g')!=CFG_STRING) {
      return MF_GRAYED;
   }
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   _str lang = target_wid.p_LangId;
   if (!_LanguageInheritsFrom('c',lang) && !_LanguageInheritsFrom('java',lang) && !_LanguageInheritsFrom('e',lang)) {
      return MF_GRAYED;
   }
   if (!target_wid._istagging_supported(lang)) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

/**
 * get the sequence used to print out a variable of the given type. For instance
 * %d for int %s for char *
 * 
 * @param var_type   variable type. I.E. int, char *, float
 * 
 * @return _str   returns string containing sequence of characters needed 
 * to print variable of the passed in type.
 */
static _str get_printf_type(_str var_type)
{
   _str type_string = "";

   // Special case char *. This check will need some more work to make it more accurate
   if( pos("char",var_type) != 0 && 
       pos("*",var_type) != 0) {
      type_string = "%s";
   } // TODO: Also need special case for VSPLSTR type
   else if(pos("VSPSZ",var_type) != 0){
      type_string = "%s";
   }
   else if(_c_is_builtin_type(var_type, false) == false) {
      type_string = "0x%x";
   } else {
      if(_c_builtin_assignment_compatible("int", var_type, false)) {
         type_string = "%d";
      } else if(_c_builtin_assignment_compatible("char", var_type, false)) { 
         type_string = "%c";
      } else if(_c_builtin_assignment_compatible("float", var_type, false)) { 
         type_string = "%f";
      } else if(_c_builtin_assignment_compatible("double", var_type, false)) { 
         type_string = "%lf";
      } else if(_c_builtin_assignment_compatible("long", var_type, false)) { 
         type_string = "%l";
      } else if(_c_builtin_assignment_compatible("unsigned int", var_type, false)) { 
         type_string = "%u";
      } else if(_c_builtin_assignment_compatible("unsigned long", var_type, false)) { 
         type_string = "%ul";
      }
   }
   return type_string;
}

/**
 * Is a variable with name and whose type is type_name declared in the current local context
 * @param name       Name of variable to look for in the current local context
 * @param type_name  Type of variable to look for in the current local context. I.E. int, float, etc.   
 * 
 * @return boolean returns true if the variable is declared in the current local context false if not or there
 * is an error.
 */
static boolean is_declared_in_current_context(_str name, _str type_name)
{
   _UpdateContext(true,true);
   _UpdateLocals(true, true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Find current context
   int ctx_id = tag_current_context();
   if(ctx_id <= 0) {
      return false;
   }

   // Find list locals function for this extension
   list_locals_index := _FindLanguageCallbackIndex('%s-list-locals');
   if (!list_locals_index) {
      return false;
   }

   // Get bounds of current context
   int context_start_seekpos, context_end_seekpos;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, ctx_id, context_start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, ctx_id, context_end_seekpos);

   int i, n=tag_get_num_of_locals();
   for (i=1; i<=n; i++) {
      VS_TAG_BROWSE_INFO cm;
      tag_get_local_info(i, cm);
      if(cm.member_name == name && cm.return_type == type_name) {
         return true;
      }
   }
   return false;
}

/**
 * Get the definition browse info for a variable browse info. For example if we have the browse
 * info for a symbol b where the declaration of b is of class Foobar, this function will get the browse
 * info for class Foobar. If the type is a builtin then there is not def info and this function will return
 * nonzero.
 * 
 * @param cm         Browse info to get the definition of.
 * @param var_def    (out)The definition of the variable.
 * 
 * @return int       Returns nonzero if the cm passed in is not a var or is a builtin type. 0 
 *                   if cm is not a builtin and is a var type.
 */
static int get_var_def(VS_TAG_BROWSE_INFO cm, VS_TAG_BROWSE_INFO &var_def)
{
   /* TODO Support having a def defined in a different file */

   tag_browse_info_init(var_def);

   // For our consideration we don't want to see arrays or pointers in the type string.
   _str builtin_only=cm.return_type;
   if(pos("*",builtin_only) != 0) {
      builtin_only = substr(builtin_only, 1, pos("*",builtin_only)-1);
   }
   if(pos("[",builtin_only) != 0) {
      builtin_only = substr(builtin_only, 1, pos("[",builtin_only)-1);
   }

   // If a builtin type then it does not have a definition to jump to so
   // just return -1;
   if(_c_is_builtin_type(builtin_only, false) == true) {
      return -1;
   }

   // Jump to definition and see if this a struct
   save_pos(auto p);
   _GoToROffset(cm.seekpos);
   tag_get_browse_info("", var_def, true);
   restore_pos(p);
   return 0;
}

/**
 * Callback to generate debug statements for Slick-C&reg; code.
 * 
 * @param cm      Symbol information
 * @param prefix  Symbol prefix expression
 * 
 * @return 0 on success, <0 on error
 */
int _e_generate_debug(VS_TAG_BROWSE_INFO cm, _str prefix)
{
   VS_TAG_BROWSE_INFO var_def;
   tag_browse_info_init(var_def);
   _str indent             = get_line_leading_whitespace();
   _str indent_one_level   = indent :+ indent_string(p_SyntaxIndent);
   _str current_indent = indent;

   // Print out function and function arguments
   if(cm.type_name == 'proc' || cm.type_name == 'func') {
      VS_TAG_FUNCTION_INFO function_info;
      get_function_info(function_info, cm);

      // Go to start of function body.
      _GoToROffset(cm.scope_seekpos);

      line := indent_string(p_SyntaxIndent) :+ "say('" :+ cm.member_name :+ "(";
      if(function_info.arguments._length() != 0) {
         skippedParams := 0;
         for(i:=0; i < function_info.arguments._length(); i++) {
            if (function_info.arguments[i].ParamNum != i + 1 - skippedParams) {
               skippedParams++;
               continue;
            } 

            strappend(line, function_info.arguments[i].ParamName"='");
            if(_c_is_builtin_type(function_info.arguments[i].ParamType, false) == false) {
               strappend(line, "("function_info.arguments[i].ParamName :+ "!=null?'nonnull':'null')");
            } else {
               strappend(line, function_info.arguments[i].ParamName);
            }
            strappend(line,"' ");
         }
      }
      strappend(line,")'"  :+ ");");
      insert_line(line);
      return 0;

   } else if (tag_tree_type_is_data(cm.type_name) || (cm.type_name=="proto" && (cm.flags & VS_TAGFLAG_maybe_var))) {

      _str var_access = prefix :+ cm.member_name;   // String used to access the var in the outputted code
      _str var_string = prefix :+ cm.member_name;   // String used to print the value of the var in the outputted code

      // Find end of statement. This handles multiple-line statements.
      search(";","@hXcs");

      // Make hash table iteration loop
      if(pos(":[]", cm.return_type)) {
         if(is_declared_in_current_context("element", "typeless") == false) {
            insert_line(indent :+ "typeless element;");
         }
         insert_line(indent :+ "for (element._makeempty();;) {");
         insert_line(indent_one_level :+ cm.member_name :+ "._nextel(element);");
         insert_line(indent_one_level :+ "if(element._isempty()) break;");
         var_access = "element";
         var_string = "element";
         current_indent = indent_one_level;
      // Make an array iteration loop
      } else if(pos("[]", cm.return_type)) {
         if(is_declared_in_current_context("_print_array_index", "int") == false) {
            insert_line(indent :+ "int _print_array_index;");
         }
         
         insert_line(indent :+ "for(_print_array_index=0; _print_array_index < "cm.member_name"._length(); _print_array_index++) {");
         var_access = cm.member_name :+ "[" :+ "_print_array_index" :+ "]";
         var_string = cm.member_name :+ "[" :+ "'_print_array_index'" :+ "]";
         current_indent = indent_one_level;
      } 

      // Special case functions for types that have a known print function.
      if(pos("VS_TAG_BROWSE_INFO",cm.return_type) != 0) {
         insert_line(current_indent :+ "tag_browse_info_dump("var_access",'"var_string"');");
      } else if(pos("VS_TAG_IDEXP_INFO",cm.return_type) != 0) {
         insert_line(current_indent :+ "tag_idexp_info_dump("var_access",'"var_string"');");
      } else if(pos("VS_TAG_RETURN_TYPE",cm.return_type) != 0) {
         insert_line(current_indent :+ "tag_return_type_dump("var_access",'"var_string"');");
      } else if(pos("VS_TAG_FUNCTION_INFO",cm.return_type) != 0) {
         insert_line(current_indent :+ "tag_function_info_dump("var_access",'"var_string"');");
      } else {
         // If a struct then print out all the members
         if(get_var_def(cm, var_def) == 0 && tag_tree_type_is_class(var_def.type_name)) {
            VS_TAG_BROWSE_INFO member_list[];
            struct VS_TAG_RETURN_TYPE visited:[];
            get_class_members(var_def, VS_TAGFILTER_VAR, VS_TAGCONTEXT_ACCESS_public, member_list, visited); 
            for(i := 0; i < member_list._length(); i++) {
               _str member_access = var_access :+ '.' :+ member_list[i].member_name;
               _str member_string_access = var_string :+ '.' :+ member_list[i].member_name;
               insert_line(current_indent :+ "say('" :+ member_string_access :+ "='" :+ member_access :+ ");");
            }
         } else {
            insert_line(current_indent :+ "say('" :+ var_string :+ "='" :+ var_access :+ ");");
         }
      }

      // Complete block if array or hash table.
      if(pos("[]",cm.return_type) != 0) {
         insert_line(indent :+ "}");
      }

      // done
      return 0;
   }

   // nothing generated
   return STRING_NOT_FOUND_RC;
}

/**
 * Callback to generate debug statements for Java code.
 * 
 * @param cm      Symbol information
 * @param prefix  Symbol prefix expression
 * 
 * @return 0 on success, <0 on error
 */
int _java_generate_debug(VS_TAG_BROWSE_INFO cm, _str prefix)
{
   VS_TAG_BROWSE_INFO var_def;
   tag_browse_info_init(var_def);
   _str indent             = get_line_leading_whitespace();
   _str indent_one_level   = indent :+ indent_string(p_SyntaxIndent);
   _str current_indent = indent;

   if(cm.type_name == 'proc' || cm.type_name == 'func') {
      VS_TAG_FUNCTION_INFO function_info;
      get_function_info(function_info, cm);

      // Go to start of function body.
      _GoToROffset(cm.scope_seekpos);

      line := indent_one_level :+ 'System.out.println("' :+ cm.member_name :+ '(';
      if(function_info.arguments._length() != 0) {
         for(i:=0; i < function_info.arguments._length(); i++) {
            strappend(line, function_info.arguments[i].ParamName'="+' :+ function_info.arguments[i].ParamName :+ '+"');
         }
      }
      strappend(line,')"' :+ ');');
      insert_line(line);
      return 0;

   } else if(cm.type_name == 'param' || cm.type_name == 'var' || cm.type_name == 'gvar' || cm.type_name == 'lvar') {

      indent = get_line_leading_whitespace();
      _str var_access = prefix :+ cm.member_name;   // String used to access the var in the outputted code
      _str var_string = prefix :+ cm.member_name;   // String used to print the value of the var in the outputted code

      // Find end of statement. This handles multiple-line statements.
      search(";","@hXcs");

      // Make an array iteration loop
      if(pos("[]", cm.return_type)) {
         if(is_declared_in_current_context("_print_array_index", "int") == false) {
            insert_line(indent :+ "for(int _print_array_index=0; _print_array_index < "cm.member_name".length; ++_print_array_index) {");
         } else {
            insert_line(indent :+ "for(_print_array_index=0; _print_array_index < "cm.member_name".length; ++_print_array_index) {");
         }

         var_access = cm.member_name :+ "[" :+ "_print_array_index" :+ "]";
         var_string = cm.member_name :+ "[" :+ "_print_array_index" :+ "]";
         current_indent = indent_one_level;
      }

      // TODO: collection and generics iteration

      // If a struct then print out all the members
      _str line='';
      if(get_var_def(cm, var_def) == 0 && var_def.type_name == 'class') {
         VS_TAG_BROWSE_INFO member_list[];
         struct VS_TAG_RETURN_TYPE visited:[];
         get_class_members(var_def, VS_TAGFILTER_VAR, VS_TAGCONTEXT_ACCESS_package, member_list, visited); 
         for(i := 0; i < member_list._length(); i++) {
            _str member_access = cm.member_name :+ '.' :+ member_list[i].member_name;
            insert_line(current_indent :+ 'System.out.println("' :+ member_access :+ '="' :+ '+' :+ member_access :+ ');');
         }
      } else {
         line = current_indent :+ 'System.out.println("' :+ var_string :+ '="' :+ '+' :+ var_access :+ ");";
      }

      // Reset indent after loop indention
      insert_line(line);

      // Complete block if array or hash table.
      if(pos("[]",cm.return_type) != 0) {
         insert_line(indent :+ "}");
      }

      // done
      return 0;
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * Callback to generate debug statements for C/C++ code.
 * 
 * @param cm      Symbol information
 * @param prefix  Symbol prefix expression
 * 
 * @return 0 on success, <0 on error
 */
int _c_generate_debug(VS_TAG_BROWSE_INFO &cm, _str prefix) 
{
   VS_TAG_BROWSE_INFO var_def;
   tag_browse_info_init(var_def);
   _str indent             = get_line_leading_whitespace();
   _str indent_one_level   = indent :+ indent_string(p_SyntaxIndent);
   _str current_indent = indent;

   if(cm.type_name == 'proc' || cm.type_name == 'func') {

      VS_TAG_FUNCTION_INFO function_info;
      get_function_info(function_info, cm);

      indent = get_line_leading_whitespace() :+ indent_string(p_SyntaxIndent);

      // Go to start of function body.
      _GoToROffset(cm.scope_seekpos);

      line := indent :+ 'printf("' :+ cm.member_name :+ '(';
      if(function_info.arguments._length() != 0) {
         for(i:=0; i < function_info.arguments._length(); i++) {
            strappend(line, function_info.arguments[i].ParamName'=');
            strappend(line, get_printf_type(function_info.arguments[i].ParamType));
            if(i < function_info.arguments._length()-1) {
               strappend(line, ", ");
            }
         }
      }
      strappend(line,')\n"');
      for(i:=0; i < function_info.arguments._length(); i++) {
         //RH - added to handle parameters passed by references
         if(pos('&', function_info.arguments[i].ParamType) > 0){
            strappend(line, ', ' :+ '&' :+ function_info.arguments[i].ParamName);
         }
         else {
            strappend(line, ', ' :+ function_info.arguments[i].ParamName);
         }
      }
      strappend(line, ");");
      insert_line(line);
      return 0;

   } else if(cm.type_name == 'param' || cm.type_name == 'var' || cm.type_name == 'gvar' || cm.type_name == 'lvar') {
      indent = get_line_leading_whitespace();

      _str var_access = prefix :+ cm.member_name;   // String used to access the var in the outputted code

      // Find end of statement. This handles multiple-line statements.
      search(";","@hXcs");

      // If a struct then print out all the members
      if(get_var_def(cm, var_def) == 0 && (var_def.type_name == 'struct' || var_def.type_name == 'class')) {
         VS_TAG_BROWSE_INFO member_list[];
         struct VS_TAG_RETURN_TYPE visited:[];
         get_class_members(var_def, VS_TAGFILTER_VAR, VS_TAGCONTEXT_ACCESS_public, member_list, visited); 
         for(i:=0; i < member_list._length(); i++) {
            _str member_access = var_access :+ '.' :+ member_list[i].member_name;

            // Is this a pointer? If so then use -> as the accessor instead.
            if(pos("*", cm.return_type) != 0) {
               member_access = var_access :+ '->' :+ member_list[i].member_name;
            }

            line := indent :+ 'printf("' :+ member_access :+ '=';
            strappend(line, get_printf_type(member_list[i].return_type) :+ '\n", ' :+ member_access :+ ');');
            insert_line(line);
         }
      } else {
         line := indent :+ 'printf("' :+ var_access :+ '=';
         strappend(line, get_printf_type(cm.return_type) :+ '\n", ' :+ var_access :+ ");");
         insert_line(line);
      }
      return 0;
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * Callback to generate debug statements for C# code.
 * 
 * @param cm      Symbol information
 * @param prefix  Symbol prefix expression
 * 
 * @return 0 on success, <0 on error
 */
int _cs_generate_debug(VS_TAG_BROWSE_INFO cm, _str prefix)
{
   VS_TAG_BROWSE_INFO var_def;
   tag_browse_info_init(var_def);
   _str indent             = get_line_leading_whitespace();
   _str indent_one_level   = indent :+ indent_string(p_SyntaxIndent);
   _str current_indent = indent;

   if(cm.type_name == 'proc' || cm.type_name == 'func') {
      VS_TAG_FUNCTION_INFO function_info;
      get_function_info(function_info, cm);

      // Go to start of function body.
      _GoToROffset(cm.scope_seekpos);

      line := indent_one_level :+ 'System.Diagnostics.Trace.WriteLine(';
      if(function_info.arguments._length() != 0) {
         // Emit method name plus the parameters
         // Create format string of paramName={index} for inside the quotes
         // And ,paramName for the parameter listing
         _str formatterLeading = '';
         _str paramFormatters = '';
         _str paramListing = '';
         for(i:=0; i < function_info.arguments._length(); i++) {
            if(i == 1) {
               formatterLeading = ', ';
            }
            strappend(paramFormatters, formatterLeading :+ function_info.arguments[i].ParamName :+ '={' :+ i :+ '}');
            strappend(paramListing, ', ' :+ function_info.arguments[i].ParamName);
         }
         // Create the multi-argument formatted output using:
         //  string.Format("methodName(paramOne={0}, parameTwo={1},etc...", paramOne, paramTwo)
         strappend(line, 'string.Format("' :+ cm.member_name :+ '(' :+ paramFormatters :+ ')"' :+ paramListing :+ ')');
      }
      else
      {
         // Just emit method name, enclosed in quotes
         strappend(line, '"' :+ cm.member_name :+ '()"');
      }
      // Close the WriteLine(...); call
      strappend(line, ');');
      insert_line(line);
      return 0;

   } else if(cm.type_name == 'param' || cm.type_name == 'var' || cm.type_name == 'gvar' || cm.type_name == 'lvar') {

      indent = get_line_leading_whitespace();
      _str var_access = prefix :+ cm.member_name;   // String used to access the var in the outputted code
      _str var_string = prefix :+ cm.member_name;   // String used to print the value of the var in the outputted code

      // Find end of statement. This handles multiple-line statements.
      search(";","@hXcs");

      // Make an array iteration loop
      boolean isArrayIter = false;
      if(pos("[]", cm.return_type)) {
         isArrayIter = true;
         if(is_declared_in_current_context("_print_array_index", "int") == false) {
            insert_line(indent :+ "for(int _print_array_index=0; _print_array_index < "cm.member_name".Length; ++_print_array_index) {");
         } else {
            insert_line(indent :+ "for(_print_array_index=0; _print_array_index < "cm.member_name".length; ++_print_array_index) {");
         }

         var_access = cm.member_name :+ "[" :+ "_print_array_index" :+ "]";
         var_string = cm.member_name :+ "[" :+ "_print_array_index" :+ "]";
         current_indent = indent_one_level;
      }

      // TODO: collection and generics iteration

      // If a struct then print out all the members
      _str line='';
      if( (get_var_def(cm, var_def) == 0) && (var_def.type_name == 'class' || var_def.type_name == 'struct') ) {
        
         // Following lines print out public and internal fields/properties of the struct or class
         VS_TAG_BROWSE_INFO member_list[];
         struct VS_TAG_RETURN_TYPE visited:[];
         get_class_members(var_def, VS_TAGFILTER_VAR, VS_TAGCONTEXT_ACCESS_package, member_list, visited);

         if (isArrayIter) {

            // Print out array access
            // Print out the default object.ToString() for this class/struct
            _str stringDotFormat_Class = 'string.Format("' :+ cm.member_name :+ '[{0}]={1}", _print_array_index, ' :+ var_access :+ ')';
            line = current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat_Class ');';
            insert_line(line);
            for (i := 0; i < member_list._length(); i++) {
               _str member_access_fmt = cm.member_name :+ '[{0}].' :+ member_list[i].member_name;
               _str member_access = cm.member_name :+ '[_print_array_index].' :+ member_list[i].member_name;
               _str stringDotFormat_Member = 'string.Format("' :+ member_access_fmt :+ '={1}", _print_array_index, ' :+ member_access :+ ')';
               insert_line(current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat_Member ');');
            }

         } else {

            // Just one instance (not an array)
            // Print out the default object.ToString() for this class/struct
            _str stringDotFormat_Class = 'string.Format("' :+ var_string :+ '={0}", ' :+ var_access :+ ')';
            line = current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat_Class ');';
            insert_line(line);
            for (i := 0; i < member_list._length(); i++) {
               _str member_access = cm.member_name :+ '.' :+ member_list[i].member_name;
               _str stringDotFormat_Member = 'string.Format("' :+ member_access :+ '={0}", ' :+ member_access :+ ')';
               insert_line(current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat_Member ');');
            }

         }
         line = '';


      } else {
         if(isArrayIter) {
            _str stringDotFormat = 'string.Format("' :+ cm.member_name :+ '[{0}]={1}", _print_array_index, ' :+ var_access :+ ')';
            line = current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat ');';
         }
         else
         {
            _str stringDotFormat = 'string.Format("' :+ var_string :+ '={0}", ' :+ var_access :+ ')';
            line = current_indent :+ 'System.Diagnostics.Trace.WriteLine(' :+ stringDotFormat ');';
         }
      }

      // Reset indent after loop indention
      if(length(line) > 0) {
         insert_line(line);
      }

      // Complete block if array or hash table.
      if(pos("[]",cm.return_type) != 0) {
         insert_line(indent :+ "}");
      }

      // done
      return 0;
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * This command will generated print code for the symbol under the cursor.
 * If the symbol is a function then a print will be generated that will
 * show the function name and list all of the parameters and their values.
 * If the symbol is a variable then the code to display the name and
 * contents of the variable will be generated.  The languages currently
 * supported are C/C++, Java, and Slick-C&reg;.  If the symbol is a struct
 * or class then all public members of the class/struct will have prints
 * generated for them.  Java array symbols will have loop code generated
 * to iterate through all the members.  For Slick-C&reg; the code to
 * iterate through both hash tables and arrays will be generated.
 */
_command void generate_debug() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   typeless p;
   _save_pos2(p);

   // find the extension specific callback
   generate_index := _FindLanguageCallbackIndex("_%s_generate_debug");
   if (!generate_index) {
      _message_box("Generate Debug is not supported for this language");
      return;
   }

   // Is the cursor on a function definition?
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   status := tag_get_browse_info("", cm);
   if (status != 0) {
      return;
   }

   // Get the prefix of this expression if there is any.
   prefix := "";
   lang := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   struct VS_TAG_RETURN_TYPE visited:[];
   _Embeddedget_expression_info(false, lang, idexp_info, visited);
   prefix = idexp_info.prefixexp;

   // call the extension specific generate debug callback
   status = call_index(cm, prefix, generate_index);
   if (status < 0) {
      message("Can not generate debug for this symbol");
   }
   _restore_pos2(p);
}

int _OnUpdate_generate_debug(CMDUI &cmdui,int target_wid,_str command)
{
   // see if it's supported for this language
   generate_index := _FindLanguageCallbackIndex("_%s_generate_debug");
   if (!generate_index) {
      return MF_GRAYED;
   }

   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
