////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47594 $
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
#include "search.sh"
#include "os390.sh"
#include "mfundo.sh"
#include "diff.sh"
#import "bgsearch.e"
#import "bind.e"
#import "complete.e"
#import "files.e"
#import "guifind.e"
#import "guireplace.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "proctree.e"
#import "project.e"
#import "ptoolbar.e"
#import "pushtag.e"
#import "saveload.e"
#import "search.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "sellist.e"
#import "tagrefs.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "util.e"
#require "se/search/SearchResults.e"
#endregion

using namespace se.search;

typeless old_search_flags;
_str old_search_string,old_word_re,old_go;

int _check_search(_str search_string,_str options)
{
   int temp_view_id = 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_window_id = temp_view_id;
   int status = search(search_string,options);
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);

   if (status == STRING_NOT_FOUND_RC || !status) {
      return(0);
   }
   return(status);
}
int _mffind2(_str search_string,_str options,_str files,_str wildcards=ALLFILES_RE,_str file_exclude='',int mfflags=0,int grep_id=0)
{
   return(_mffind(search_string,options,files,'',mfflags,false,false,wildcards,file_exclude,true,grep_id));
}
/**
 * Searches for occurrences of the string, <i>search_string</i>, in the files
 * and buffers specified.  When an occurrence is chosen, the file is opened and
 * the cursor is placed on the occurrence.  Use the <b>find_next</b> (Ctrl+G)
 * and <b>find_prev</b> commands to find the next and previous occurrences
 * respectively.
 *
 * @param search_string String to search for.
 *
 * @param options A string of zero or more of the following search options:
 *
 * <dl>
 * <dt>E</dt><dd>Exact case.</dd>
 *
 * <dt>I</dt><dd>Ignore case.</dd>
 *
 * <dt>- </dt><dd>Reverse search.</dd>
 *
 * <dt>M</dt><dd> Limit search to marked area.</dd>
 *
 * <dt><</dt><dd> If found, place cursor at beginning of word.</dd>
 *
 * <dt>></dt><dd> If found, place cursor at end of word.</dd>
 *
 * <dt>R</dt><dd>Interpret string as a SlickEdit regular expression.  See section
 * <b>SlickEdit Regular Expressions</b> for syntax of regular expression.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See section <b>UNIX
 * Regular Expressions</b>.</dd>
 *
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See section <b>Brief
 * Regular Expressions</b>.</dd>
 *
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 *
 * <dt>N</dt><dd>Do not interpret search string as a regular-expression search string.</dd>
 *
 * <dt>P</dt><dd>Ignored.</dd>
 *
 * <dt>W</dt><dd>Limits search to words.  Used to search for variables.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>Specifies the valid characters
 * in a word.  The default value is [A-Za-* z0-9_$].</dd>
 *
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example, searching for "pre"
 * matches "pre" and "prefix" but not "supreme" or "supre".</dd>
 *
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example, searching for
 * "pre" matches "prefix" but not "pre", "supreme" or "supre".</dd>
 *
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example, searching for "fix"
 * matches "fix" and "sufix" but not "fixit".</dd>
 *
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example, searching for
 * "fix" matches "sufix" but not "fix" or "fixit".</dd>
 *
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the middle of a DBCS or
 * UTF-8 character.  This option is useful when editing binary files (in
 * SBCS/DBCS mode) which may contain characters which look like DBCS but are
 * not.  For example, if you search for the character 'a', it will not be found
 * as the second character of a DBCS sequence unless this option is specified.</dd>
 *
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 *
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified. For example, "XCS" requires that the first
 * character not be in a comment or string. <i>CCLetters</i> is a string of one
 * or more of the following color coding element letters:</dd>
 *
 * <dl>
 * <dt>O</dt><dd>Other</dd>
 * <dt>K</dt><dd>Keyword</dd>
 * <dt>N</dt><dd> Number</dd>
 * <dt>S</dt><dd>String</dd>
 * <dt>C</dt><dd>Comment</dd>
 * <dt>P</dt><dd> Preprocessing</dd>
 * <dt>L</dt><dd> Line number</dd>
 * <dt>1</dt><dd> Symbol 1</dd>
 * <dt>2</dt><dd> Symbol 2</dd>
 * <dt>3</dt><dd> Symbol 3</dd>
 * <dt>4</dt><dd> Symbol 4</dd>
 * <dt>F</dt><dd> Function color</dd>
 * <dt>V</dt><dd>No save line</dd>
 * </dl>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to be
 * one of the color coding elements specified. See <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * @param files   Zero or more space delimited file specifications which may
 * contain wild cards.  '+T' and '-T' switches may be embedded between files
 * specifications to turn subdirectory (tree) searching on or off.
 *
 * @param atbuflist Zero or more space delimited buffer names.  If a
 * buffer name starts with a '@' character, it is assumed to be a buffer which
 * contains a list of buffer names to search.
 *
 * @param mfflags  One or more of the following flags:
 *
 * <dl>
 * <dt>MFFIND_CURBUFFERONLY</dt><dd>Search current buffer only.</dd>
 * <dt>MFFIND_FILESONLY</dt><dd>List files only.</dd>
 * <dt> MFFIND_APPEND</dt><dd>Append to current output.</dd>
 * <dt>MFFIND_MDICHILD</dt><dd>Output to MDI child.</dd>
 * <dt> MFFIND_SINGLE</dt><dd>Stop after first occurrence.</dd>
 * <dt>MFFIND_GLOBAL</dt><dd>Find all without prompting.</dd>
 * </dl>
 *
 * @return Returns 0 if one or more occurrences are found.
 *
 * @example
 * <pre>
 * // Case sensitive word search for "main"  through all c and h files in or
 * below the current
 * // directory.
 * _mffind('main', 'ew', '+t *.c *.h','');
 * </pre>
 *
 * @see _mfreplace
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
int _mffind(_str search_string,_str options,_str files,_str notused_atbuflist,int mfflags=0,boolean searchProjectFiles=false,boolean searchWorkspaceFiles=false,_str wildcards='',_str file_exclude='',boolean files_delimited_with_pathsep=false,int grep_id=0)
{
   _mdi.p_child.mark_already_open_destinations();

   _str fopts='';
   _str fresult = strip_options(files, fopts, true);
   if ((mfflags & MFFIND_THREADED) &&        // user asked for background search
        (((fresult != MFFIND_BUFFERS) && (fresult != MFFIND_BUFFER)) || searchProjectFiles || searchWorkspaceFiles) ) {   // not only searching buffers
      start_bgsearch(search_string,
                     options,
                     files,
                     mfflags,
                     searchProjectFiles,
                     searchWorkspaceFiles,
                     wildcards,
                     file_exclude,
                     files_delimited_with_pathsep,
                     grep_id);
      old_search_string = search_string;
      return 0;
   }

   if (mfflags & MFFIND_THREADED){      // user asked for background search
      // we are silently switching to a foreground search for performance
      // however, to really do this silently, we have to set search to global
      mfflags&=~MFFIND_SINGLE;
      mfflags|=MFFIND_GLOBAL;
   }

   _mfrefNoMore(1);
   int window_list[];                             // List of Window ID's
   int i,count;

   int last=_last_window_id();                         // Record last window ID
   //messageNwait("last_window_id = "last);

   count = 0;

   for (i=1;i<=last ;++i) {                        // Loop through window ID's
      if ( _iswindow_valid(i) ) {                  // Check for valid Window ID
         if (i.p_mdi_child && i.p_window_state == 'I') {
                                                   // Check for Active window and if it is Iconized
            window_list[count] = i;                // Add ID to array
            ++count;                               //Increment
           // messageNwait("i= "i);
         }
      }
   }

   int status=_check_search(search_string,options);
   if(status) {
      return(status);
   }
   int focus_wid=_get_focus();
   if (focus_wid==_cmdline) {
      VSWID_STATUS._set_focus();
   }
   status = _mffind2util(search_string, options, files, mfflags,searchProjectFiles,searchWorkspaceFiles,wildcards,file_exclude,files_delimited_with_pathsep,grep_id);
   if (_get_focus()==VSWID_STATUS) {
      _cmdline._set_focus();
   }
   for (i = 0; i < count ; ++i) {                   //Loop through list of Windows
      if (_iswindow_valid(window_list[i]) && ( window_list[i] != _mdi.p_child)) { // Check and make sure that window is valid
         window_list[i].p_window_state= 'I';   //Set Window Back to Iconized
      }
   }
   return (status);
}

_str _mfreplace2(_str search_string, _str replace_string, _str options,
                _str files, _str wildcards=ALLFILES_RE, _str file_exclude = '',
                 int mfflags = 0, int grep_id = 0, boolean show_diff = false)
{
   return(_mfreplace(search_string, replace_string, options, files, '', false, false, wildcards, file_exclude, true, mfflags, grep_id, show_diff));
}
/**
 * Performs a search and replace on the files and buffers specified.
 *
 * @param search_string String to search for.
 * @param replace_string String to replace search string with.
 *
 * @param options A string of zero or more of the following search options:
 *
 * <dl>
 * <dt>*</dt><dd>Perform search and replace without prompting for replace or save.</dd>
 *
 * <dt>E</dt><dd>Exact case.</dd>
 *
 * <dt>I</dt><dd>Ignore case.</dd>
 *
 * <dt>-</dt><dd>Reverse search.</dd>
 *
 * <dt>M</dt><dd>Limit search to marked area.</dd>
 *
 * <dt>V</dt><dd>Preserve case. When specified, each occurrence found is checked for all
 * lower case, all upper case, first word capitalized or mixed case.  The
 * replace string is converted to the same case as the occurrence found excepted
 * when the occurrence found is mixed case (possibly mulltiple capitalized
 * words).  In this case, the replace string is used without modification.</dd>
 *
 * <dt><</dt><dd>If found, place cursor at beginning of word.</dd>
 *
 * <dt>></dt><dd>If found, place cursor at end of word.</dd>
 *
 * <dt>R</dt><dd>Interprets <i>search_string</i> to be a SlickEdit regular expression.
 * In addition, the characters \ and # take on new meaning in the replace
 * string.  See <b>SlickEdit Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See section <b>UNIX
 * Regular Expressions</b>.</dd>
 *
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See section <b>Brief
 * Regular Expressions</b>.</dd>
 *
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 *
 * <dt>N</dt><dd>Do not interpret search string as a regular-expression search string.</dd>
 *
 * <dt>P</dt><dd>Ignored.</dd>
 *
 * <dt>W</dt><dd>Limits search to words.  Used to search for variables.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>Specifies the valid characters
 * in a word.  The default value is [A-Za-z0-9_$].</dd>
 *
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example, searching for "pre"
 * matches "pre" and "prefix" but not "supreme" or "supre".</dd>
 *
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example, searching for
 * "pre" matches "prefix" but not "pre", "supreme" or "supre".</dd>
 *
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example, searching for "fix"
 * matches "fix" and "sufix" but not "fixit".</dd>
 *
 * <dt>W:SS</dt><dd> Limits search to strict word suffix.  For example, searching for
 * "fix" matches "sufix" but not "fix" or "fixit".</dd>
 *
 * <dt>Y</dt><dd> Binary search.  This allows start positions in the middle of a DBCS or
 * UTF-8 character.  This option is useful when editing binary files (in
 * SBCS/DBCS mode) which may contain characters which look like DBCS but are
 * not.  For example, if you search for the character 'a', it will not be found
 * as the second character of a DBCS sequence unless this option is specified.</dd>
 *
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 *
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string NOT
 * be one of the color coding elements specified. For example, "XCS" requires that the first
 * character not be in a comment or string. <i>CCLetters</i> is a string of one
 * or more of the following color coding element letters:</dd>
 *
 * <dl>
 * <dt>O</dt><dd>Other</dd>
 * <dt>K</dt><dd>Keyword</dd>
 * <dt>N</dt><dd>Number</dd>
 * <dt>S</dt><dd>String</dd>
 * <dt>C</dt><dd>Comment</dd>
 * <dt>P</dt><dd>Preprocessing</dd>
 * <dt>L</dt><dd>Line number</dd>
 * <dt>1</dt><dd>Symbol 1</dd>
 * <dt>2</dt><dd>Symbol 2</dd>
 * <dt>3</dt><dd>Symbol 3</dd>
 * <dt>4</dt><dd>Symbol 4</dd>
 * <dt>F</dt><dd>Function color</dd>
 * <dt>V</dt><dd>No save line</dd>
 * </dl>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to be one of the color
 * coding elements specified. See <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * @param files   Zero or more space delimited files which may contain wild
 * cards.  '+T' and '-T' switches may be embedded between files specifications
 * to turn subdirectory (tree) searching on or off.
 *
 * @param atbuflist  Zero or more space delimited buffer names.  If a
 * buffer name starts with a '@' character, it is assumed to be a buffer which
 * contains a list of buffer names to search.
 *
 * @return Returns 0 if a search and replace proceeds through all files and
 * no errors occur.
 *
 * @example
 * <pre>
 * // Case sensitive word search for "list"  through all c and h files in or
 * below the current
 * // directory.  Replace with better_name_list.
 * _mfreplace('list', 'better_name_list', 'ew', '+t *.c *.h','');
 * </pre>
 *
 * @see _mffind
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
_str _mfreplace(_str search_string, _str replace_string, _str options,
                _str files, _str notused_atbuflist,
                boolean searchProjectFiles = false, boolean searchWorkspaceFiles = false,
                _str wildcards = '', _str file_exclude = '', boolean files_delimited_with_pathsep = false,
                int mfflags = 0, int grep_id = 0, boolean show_diff = false)
{
   _macro('m', 0);
   int window_list[];                             // List of Window ID's
   int i,count;
   int last=_last_window_id();                         // Record last window ID
   //messageNwait("last_window_id = "last);
   count = 0;
   for (i=1;i<=last ;++i) {                        // Loop through window ID's
      if ( _iswindow_valid(i) ) {                  // Check for valid Window ID

         if (i.p_mdi_child && i.p_window_state == 'I') {
                                                   // Check for Active window and if it is Iconized
            window_list[count] = i;                // Add ID to array
            ++count;                               //Increment
           // messageNwait("i= "i);
         }
      }
   }
   options = options:+'+';
   typeless status=_check_search(search_string, options);
   if(status) {
      return(status);
   }
   save_search(old_search_string, old_search_flags, old_word_re);
   set_find_next_msg("Find", search_string, options, VSSEARCHRANGE_CURRENT_BUFFER);
   int focus_wid=_get_focus();
   if (focus_wid==_cmdline) {
      VSWID_STATUS._set_focus();
   }

   if (show_diff) {
      if (replace_diff_begin()) {
         return (COMMAND_CANCELLED_RC);
      }
   }

   status = _mfreplace2util(search_string, replace_string, options,
                             files, searchProjectFiles, searchWorkspaceFiles,
                             wildcards, file_exclude, files_delimited_with_pathsep,
                             mfflags, grep_id);
   if (_get_focus()==VSWID_STATUS) {
      _cmdline._set_focus();
   }
   for (i = 0; i < count ; ++i) {                   //Loop through list of Windows
      if (_iswindow_valid(window_list[i]) && ( window_list[i] != _mdi.p_child)) { // Check and make sure that window is valid
         window_list[i].p_window_state= 'I';   //Set Window Back to Iconized
      }
   }

   if (show_diff) {
      if (length(search_string) > 10) search_string = substr(search_string, 1, 10) :+ '...';
      if (length(replace_string) > 10) replace_string = substr(replace_string, 1, 10) :+ '...';
      replace_diff_end(false, "Replace in Files results", "Replace in Files "search_string" => "replace_string);
   }

   int treeWid = _find_object("_tbprojects_form._proj_tooltab_tree",'N');
   if ( treeWid ) {
      treeWid.projecttbRefresh();
   }
   return (status);
}

boolean _mffind_IsToolbarVisible()
{
   return(_find_object("_tbsearch_form","n") != 0);
}

static int _mffind2util(_str search_string,_str options,_str files,int mfflags,boolean searchProjectFiles,boolean searchWorkspaceFiles,_str wildcards='',_str file_exclude='',boolean files_delimited_with_pathsep=false,int grep_id=0)
{
   get_window_id(auto orig_view_id);
   mou_hour_glass(1);
   message("Matching files...");
   int list_view_id=0;
   int status=_mfinit(list_view_id,files,wildcards,file_exclude,files_delimited_with_pathsep,searchProjectFiles,searchWorkspaceFiles);
   if (status) {
      mou_hour_glass(0);
      clear_message();
      return(status);
   }

   SearchResults results;
   topline := se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude,'',orig_view_id._build_buf_name());
   if (!(mfflags & MFFIND_SINGLE)) {
      results.initialize(topline, search_string, mfflags, grep_id);
      results.showResults();
   }
   set_find_next_msg(topline);
   options = options:+'@H+';

   boolean AskAboutMissingFiles = !(mfflags & MFFIND_QUIET);
   activate_window(list_view_id);
   mou_hour_glass(1);
   int NofMatches=0;
   int NofFileMatches=0;
   int qmffind_wid=0;
   int SelectedMatch=0;
   int TotalFilesSearched=0;
   int RestoreToNoMdiChildren=_no_child_windows();
   int found_one_status=0;
   int phyical_col=0;
   int edit_buf_id=0;
   int edit_view_id=0;
   int buf_wid=0;
   int col=0;
   status=0;
   _str path='';
   _str found='';
   _str old_buffer_name='';
   boolean PromptInitDone=false;
   boolean file_already_loaded=false;
   typeless buf_view_id=0;
   typeless junk=0;
   typeless result=0;
   typeless p1,p2,p3,p4,p5;
   typeless found_pos=0;
   typeless orig_pos=0;
   boolean done=false;
   boolean cancel=false;
   if (!down()) {
      done=0;
      int fileCount = 0;
      int updateIncrement = 1;
      if (p_noflines > 10) updateIncrement = p_noflines / 10;
      _os390BeginOpenedPDS();
      int ListLineNum;
      for (ListLineNum=1;ListLineNum<=p_Noflines;++ListLineNum) {
         process_events(cancel,'E');
         if (cancel) {
            status=COMMAND_CANCELLED_RC;
            break;
         }
         activate_window(list_view_id);
         // Need to use line numbers because switch buffers in
         // list_view_id does not always restore list line number in
         // one odd case (start with no child windows, not one file per window).
         buf_view_id='';
         p_line=ListLineNum;
         path=_lbget_text();
         path=strip(path,'b','"');
         status=0;
         boolean called_edit=false;
         status=_open_temp_view(path,buf_view_id,junk,'',file_already_loaded,false,true,0,false,false);
         if (status) {
            buf_view_id='';
         }
         if (status && status!=NEW_FILE_RC) {
            _str msg='';
            if (status==FILE_NOT_FOUND_RC) {
               msg=nls("File '%s' not found",path);
            } else {
               msg=nls("Unable to edit '%s'.\n\n",path):+get_message(status);
            }
            msg=msg"\n\nContinue?";

            result=IDYES;
            if (AskAboutMissingFiles) {
               int orig_wid = p_window_id;
               _str answer = show("-modal _yesToAll_form", msg, "Multi-file Search", false);
               if (answer== "YESTOALL") {
                  AskAboutMissingFiles=false;
               } else if (answer != "YES") {
                  result=IDNO;
               }
               p_window_id=orig_wid;
            }
            if (result!=IDYES) {
               if (qmffind_wid) {
                  qmffind_wid._delete_window();
               }
               activate_window(orig_view_id);_set_focus();
               _delete_temp_view(list_view_id);
               mou_hour_glass(0);
               clear_message();
               return(status);
            }
            status=0;
            continue;
         }
         if (status!=NEW_FILE_RC) {
            ++TotalFilesSearched;
#if __UNIX__ || __TESTS390__
            if (!(fileCount % updateIncrement)) {
               message("File: "path);
            }
            fileCount++;
#else
            message("File: "path);
#endif
            get_window_id(buf_view_id);
            restore_search(old_search_string,old_search_flags,'['p_word_chars']');
            top();
            found_one_status=search(search_string,options);
            if (!found_one_status) {
               ++NofFileMatches;
               if (file_already_loaded) {
                  _SetAllOldLineNumbers();
               }
               results.insertFileLine(buf_view_id._build_buf_name());
               if (mfflags & MFFIND_GLOBAL) {
                  if (!(mfflags & MFFIND_FILESONLY)) {
                     // Insert all occurrences
                     status = 0;
                     for (;;) {
                        if (status) break;
                        ++NofMatches;
                        results.insertCurrentMatch();
                        status=repeat_search();
                     }
                  }
               } else {
                  // Insert all occurrences
                  status=0; cancel=0;
                  boolean window_already_open=0;
                  // we know the buffer exists in a temp view,
                  // but is the buffer also being edited?
                  if (!_no_child_windows()) {
                     int i;
                     for (i=1;i<=_last_window_id();++i) {
                        if (_iswindow_valid(i) &&
                            i._isEditorCtl(false) &&
                            i.p_mdi_child &&
                            i.p_buf_id==p_buf_id) {
                           window_already_open=1;
                           break;
                        }
                     }
                  }
                  // open the buffer in an edit window
                  save_search(p1,p2,p3,p4,p5);
                  save_pos(found_pos);
                  phyical_col = _text_colc(p_col,'P');
                  called_edit = true;
                  edit_buf_id = p_buf_id;
                  p_window_id = _mdi.p_child;
                  edit('+bi 'edit_buf_id, EDIT_NOWARNINGS);
                  buf_wid = p_window_id;
                  get_window_id(edit_view_id);
                  save_pos(orig_pos);
                  restore_pos(found_pos);
                  if (!file_already_loaded) {
                     _SetEditorLanguage();
                     p_col=_text_colc(phyical_col,'I');
                  }
                  restore_search(p1,p2,p3,p4,p5);
                  for (;;) {
                     if (status) break;
                     SelectedMatch=1;
                     _deselect();_select_match();
                     found = get_match_text();
                     if (!(mfflags & MFFIND_FILESONLY)) {
                        ++NofMatches;
                        results.insertCurrentMatch();
                     }
                     if (!(mfflags & (MFFIND_GLOBAL))) {
                        if (mfflags & MFFIND_SINGLE) {
                           result="";
                        } else {
                           // ask user what to do with match
                           if (!PromptInitDone) {
                              PromptInitDone=1;
                              qmffind_wid=show('-mdi _qmffind_form');
                              _search_form_xy(qmffind_wid,buf_wid);
                           }
                           _nocheck _control ctlfound,ctlyes;
                           qmffind_wid.ctlfound.p_caption=found;
                           qmffind_wid.ctlyes._set_focus();
                           _SearchViewMatch(qmffind_wid,buf_wid);
                           save_search(p1,p2,p3,p4,p5);
                           result=_modal_wait(qmffind_wid);
                           activate_window(edit_view_id);
                           restore_search(p1,p2,p3,p4,p5);
                        }
                        if (result=='') {
                           break;
                        }
                        if (result=='n') {  // Next file
                           break;
                        }
                        if (result=='g') {
                           mfflags |= MFFIND_GLOBAL;
                        }
                     }
                     activate_window(edit_view_id);
                     status = repeat_search();
                  }
                  // clean up behind ourselves
                  if (result=="") {  // Esc or NO
                     RestoreToNoMdiChildren=0;
                     qmffind_wid=0;
                     done=1;
                     _SetAllOldLineNumbers();
                  } else {
                     restore_pos(orig_pos);
                     if (!window_already_open && def_one_file!='') {
                        _delete_window();
                     }
                  }
               }
               activate_window(buf_view_id);
            }
            if (done) {
               _delete_temp_view(buf_view_id);
               break;
            }
         }
         // IF we created a temp view for this file
         if (buf_view_id != '') {
            // IF this buffer did not already exist
            if (!file_already_loaded) {
               if (called_edit) {
                  typeless swold_pos=0;
                  typeless swold_buf_id=0;
                  set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
                  quit_file();
                  switch_buffer(old_buffer_name,'Q',swold_pos,swold_buf_id);
               } else {
                  _delete_buffer();
               }
            }
            // Deleting buffer above improves performance by almost 10 percent
            _delete_temp_view(buf_view_id,false);
         }
         activate_window(list_view_id);
      }
      _os390EndOpenedPDS();
   }
   activate_window(list_view_id);
   if (RestoreToNoMdiChildren && !_no_child_windows() && def_one_file=="") {
      _mdi.p_child._delete_window();
   }
   if (SelectedMatch &&
       !(def_persistent_select=='D' && def_leave_selected) &&
       !(def_keys=='brief-keys' && def_persistent_select != 'Y' && def_leave_selected)) {
      _deselect();
   }
   if (qmffind_wid) {
      qmffind_wid._delete_window();
   }
   _str results_text='';
   activate_window(list_view_id);
   save_search(old_search_string,old_search_flags,old_word_re);
   mou_hour_glass(0);
   if (mfflags & MFFIND_SINGLE) {
      clear_message();
      // set the default wrap for the single match
      old_search_flags |= (_default_option('s') & (VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP));
   } else {
      if (mfflags & MFFIND_FILESONLY) {
         results_text='Matching files: 'NofFileMatches'     Total files searched: 'TotalFilesSearched;
      } else {
         results_text='Total found: 'NofMatches'     Matching files: 'NofFileMatches'     Total files searched: 'TotalFilesSearched;
      }
      _str bindings='';
      if (def_mfflags & 1) {
         bindings=_mdi.p_child.where_is("find_next",1);
      } else {
         bindings=_mdi.p_child.where_is("next_error",1);
      }
      parse bindings with 'is bound to 'bindings;
      parse bindings with bindings ',';
      _str bindings_text = "";
      if (bindings!="") {
         bindings_text="  Press "bindings:+" for next occurrence.";
      }
      sticky_message(results_text:+bindings_text);
   }
   activate_window(orig_view_id);
   _delete_temp_view(list_view_id);
   results.done(results_text);
   results.showResults();
   if (status==COMMAND_CANCELLED_RC) {
      sticky_message(get_message(status));
      return(status);
   }
   return(0);
}

static _str _mfreplace2util(_str search_string, _str replace_string, _str options, _str files,
                            boolean searchProjectFiles, boolean searchWorkspaceFiles,
                            _str wildcards = '', _str file_exclude = '', boolean files_delimited_with_pathsep = false,
                            int mfflags = 0, int grep_id = 0)
{
   boolean doDiff = (mfflags & MFFIND_DIFF) != 0;
   boolean leaveFileOpen = (mfflags & MFFIND_LEAVEOPEN) != 0;
   boolean AskAboutMissingFiles = true;
   boolean doMFUndo = !leaveFileOpen && !doDiff;
   boolean MFUndoStarted = false;
   boolean doGrep = !doDiff;
   int orig_view_id, list_view_id, output_view_id;
   get_window_id(orig_view_id);
   message("Matching files...");
   int status = _mfinit(list_view_id, files,wildcards,file_exclude,files_delimited_with_pathsep,searchProjectFiles,searchWorkspaceFiles);
   if (status) {
      clear_message();
      rc='';  // Name of file in which error occurred
      return(status);
   }
   SearchResults results;
   if (doGrep) {
      _mffindNoMore(1);
      _mfrefNoMore(1);
      topline := se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude,replace_string,orig_view_id._build_buf_name());
      results.initialize(topline, search_string, mfflags, grep_id);
   }
   activate_window(list_view_id);
   old_go = pos('*', options);
   mou_hour_glass(1);
   int Nofchanges = 0;
   int RestoreToNoMdiChildren=_no_child_windows();

   // Disable the Defs tool window if active
   int tbformwid = 0;
   int formwid = _tbIsActive("_tbproctree_form");
   if (formwid > 0) {
      tbformwid = GetProcTreeWID();
      tbformwid.p_enabled = false;
   }
   _project_disable_auto_build(true);
   options=options:+'@H';

   _prompt_readonly_reset_prompt();
   _str path='';
   _str event='';
   typeless junk='';
   boolean prompt_save = true;
   boolean go_save_all = false;
   boolean file_already_loaded=false;
   int edit_view_id = 0;
   status = 0;
   int NofFileMatches = 0;
   int TotalFilesSearched = 0;
   flush_keyboard();
   for (;;) {
      if( _IsKeyPending(false)) {
         int orig_def_actapp=def_actapp;
         def_actapp=0;
         int result1=_message_box('Would you like to cancel?','',MB_YESNOCANCEL);
         def_actapp=orig_def_actapp;
         if (result1!=IDNO) {
            status=COMMAND_CANCELLED_RC;
            path='';
            break;
         }
      }
      flush_keyboard();

      if ( down() ) {
         status=0;
         path='';  // Name of file in which error occurred
         break;
      }
      path=_lbget_text();
      path=strip(path,'b','"');
      message("File: "path);
      ++TotalFilesSearched;
      edit_view_id=0;
      _str load_options = doDiff ? '+d' : '';
      // Create a view with this buffer or view
      int load_files_status = 0;
      int load_files_view_id;
      load_files_status = _open_temp_view(path, load_files_view_id, junk, load_options, file_already_loaded, false, true, 0, false, false);
      int load_files_buf_id = p_buf_id;
      boolean needs_edit = !doDiff && (!old_go || (old_go && (leaveFileOpen || file_already_loaded)));
      boolean edit_called = false;
      int edit_status = 0;
      if (file_already_loaded) {
         _SetAllOldLineNumbers();
      }
      if (!load_files_status) {
         restore_search(old_search_string, old_search_flags, '['p_word_chars']');
         top();
         status = search(search_string, options);
         if (!status) {
            ++NofFileMatches;
            if (needs_edit) {
               int linenum = p_line;
               int col = p_col;
               activate_window(orig_view_id);
               // To allow us to find buffer with invalid file names like "Directory of ..." buffer
               // look for the buffer first.
               edit_called = true;
               edit_status = edit('+b 'path);
               get_window_id(edit_view_id);
               if (!edit_status) {
                  goto_line(linenum);
                  p_col=col;
               }
               activate_window(load_files_view_id);
               if (!file_already_loaded && edit_status) {
                  _delete_buffer();
               }
               _delete_temp_view(load_files_view_id,false);
               activate_window(edit_view_id);
            }
         } else {
             if (!file_already_loaded) {
                _delete_buffer();
             }
            _delete_temp_view(load_files_view_id,false);
            activate_window(list_view_id);
            continue;
         }
      }
      if (!edit_status) {
         edit_status = load_files_status;
      }
      if (edit_status) {
         _str msg = '';
         if (edit_status == FILE_NOT_FOUND_RC) {
            msg = nls("File '%s' not found",path);
         } else {
            msg = nls("Unable to edit '%s'.\n\n",path):+get_message(edit_status);
         }
         msg = msg"\n\nContinue?";
         //result=_message_box(nls("%s",msg),'',MB_YESNO);
         int result = IDYES;
         if (AskAboutMissingFiles) {
            int orig_wid = p_window_id;
            _str answer = show("-modal _yesToAll_form", msg, "Multi-file Search", false);
            if (answer == "YESTOALL") {
               AskAboutMissingFiles=false;
            } else if (answer != "YES") {
               result = IDNO;
            }
            p_window_id = orig_wid;
         }
         if (result != IDYES) {
            status = COMMAND_CANCELLED_RC;
            rc = path;  // Name of file in which error occurred
            break;
         }
         activate_window(list_view_id);
         status = 0;
         continue;
      }
      if (p_modify && _need_to_save() && !leaveFileOpen) {
         boolean must_save = go_save_all;
         if (prompt_save) {
            _str msg = nls("File '%s' is not saved.  File must be saved for multi-file undo operation to perform correctly. Save file now?", path);
            _str answer = show("-modal _yesToAll_form", msg, "Multi-file Replace", true);
            if (answer == "CANCEL") {
               break;
            } else if (answer == "YESTOALL") {
               prompt_save = false;
               go_save_all = true;
               must_save = true;
            } else if (answer == "NOTOALL")  {
               prompt_save = false;
               go_save_all = false;
               must_save = false;
            } else if (answer == "YES")  {
               must_save = true;
            } else if (answer == "NO") {
               must_save = false;
            }
         }
         if (must_save) {
            save();
         }
      }
      restore_search(old_search_string,old_search_flags,'['p_word_chars']');
      if (doMFUndo) {
         if (!MFUndoStarted) {
            temp_search_string := search_string;
            temp_replace_string := replace_string;
            if (length(temp_search_string) > 10) temp_search_string = substr(temp_search_string, 1, 10) :+ '...';
            if (length(temp_replace_string) > 10) temp_replace_string = substr(temp_replace_string, 1, 10) :+ '...';
            _str stepname = "Replace in Files "temp_search_string" => "temp_replace_string;
            _MFUndoBegin(stepname);
            MFUndoStarted = true;
         }
         _MFUndoBeginStep(path);
      }
      status = gui_replace2(search_string, replace_string, ((old_go)?'*':'')options, 1, 1, (doGrep) ? &results : null, doDiff);
      Nofchanges += _Nofchanges;
      if (edit_called) {
         activate_window(edit_view_id);
         if (status && status!=STRING_NOT_FOUND_RC) {
            // Command must have been cancelled
            message(get_message(status));
            rc=path;  // Name of file in which error occurred
            if (doMFUndo) {
               _MFUndoCancelStep(path);
            }
            break;
         }
         if (p_modify && _need_to_save2() && !leaveFileOpen) {
            if (isEclipsePlugin()) {
               _eclipse_set_dirty(p_window_id, true);
            }
            status = save(maybe_quote_filename(p_buf_name));
            if (status) {
               break;
            }
         }
         if (!file_already_loaded && !leaveFileOpen) {
            status = quit();
            if (status) {
               break;
            }
         }
      } else {
         if (doDiff && (_Nofchanges > 0)) {
            replace_diff_add_file(p_buf_name, p_encoding);
            replace_diff_set_modified_file(p_window_id);
         }
         if (!doDiff && (_Nofchanges > 0) && p_modify) {
            status=save(maybe_quote_filename(p_buf_name), SV_NOADDFILEHIST);
            if (status) {
               break;
            }
         }
         if (!file_already_loaded) {
            _delete_buffer();
         }
         // Deleting buffer above improves performance by almost 10 percent
         _delete_temp_view(load_files_view_id, false);
         if (status && status != STRING_NOT_FOUND_RC) {
            // Command must have been cancelled
            message(get_message(status));
            rc=path;  // Name of file in which error occurred
            if (doMFUndo) {
               _MFUndoCancelStep(path);
            }
            break;
         }
      }
      activate_window(list_view_id);
      if (doMFUndo) {
         if (_Nofchanges <= 0) {
            _MFUndoCancelStep(path);
         } else {
            _MFUndoEndStep(path);
         }
      }
   }
   if (doMFUndo) {
      _MFUndoEnd();
   }
   if (!status && RestoreToNoMdiChildren && !_no_child_windows() && def_one_file=="") {
      _mdi.p_child._delete_window();
   }
   mou_hour_glass(0);
   _str results_text = 'Total replaces: 'Nofchanges'     Matching files: 'NofFileMatches'     Total files searched: 'TotalFilesSearched;
   if (doMFUndo) {
      _str stepname = ( Nofchanges > 0 ) ? "     Multi-file undo available." : "";
      results_text = results_text:+stepname;
   }
   sticky_message(results_text);
   if (doGrep) {
      results.done(results_text);
      results.showResults();
   }
   _delete_temp_view(list_view_id);
   activate_window(orig_view_id);
   if (tbformwid > 0) {
      tbformwid.p_enabled = true;
   }
   _project_disable_auto_build(false);
   if (status==COMMAND_CANCELLED_RC) {
      if (edit_view_id) {
         activate_window(edit_view_id);
      }
      sticky_message(get_message(status));
      return(status);
   }
   rc=path;
   return(status);
}

/*
    When CreateTempView option is given orig_hidden_buf_id is
    set to current buffer id and NOT the current hidden window
    buffer id.
*/
int _mfinit(int &temp_view_id,_str files,_str wildcards='',_str file_exclude='',boolean files_delimited_with_pathsep=true,
             boolean searchProjectFiles=false,boolean searchWorkspaceFiles=false
            )
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   int status=bgm_gen_file_list(temp_view_id,files,wildcards,file_exclude,files_delimited_with_pathsep,searchProjectFiles,searchWorkspaceFiles,true);
   if (status) {
      if (status<0) {
         _message_box(get_message(status));
      }
      return(status);
   }
   activate_window(temp_view_id);
   bgm_filter_project_files(wildcards, file_exclude);
   if (!p_Noflines) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);_set_focus();
      _message_box('No files found');  //get_message(VSRC_FF_FILE_NOT_FOUND, filename));
      return(1);
   }
   sort_buffer(_fpos_case);
   _remove_duplicates(_fpos_case);
   top(); up();
   activate_window(orig_view_id);
   return(0);
}

defeventtab _qmffind_form;
void ctlyes.lbutton_up()
{
   p_active_form._end_modal_wait("y");
}
void ctlno.lbutton_up()
{
   p_active_form._delete_window("");
}
void ctlglobal.lbutton_up()
{
   p_active_form._end_modal_wait("g");
}
void ctlnextfile.lbutton_up()
{
   p_active_form._end_modal_wait("n");
}

void _SearchViewMatch(int form_wid,int buf_wid)
{
   int form_x=0, form_y=0, form_width=0, form_height=0;
   form_wid._get_window(form_x,form_y,form_width,form_height);
   _lxy2dxy(form_wid.p_xyscale_mode,form_x,form_y);
   _map_xy(0,buf_wid,form_x,form_y,SM_PIXEL);

   int line_height=buf_wid._text_height();
   if (buf_wid.p_cursor_y+line_height>form_y) {
      buf_wid.set_scroll_pos(buf_wid.p_left_edge,buf_wid._text_height()*2);
   }
}


