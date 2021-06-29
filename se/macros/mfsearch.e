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
//#include "os390.sh"
#include "mfsearch.sh"
#include "mfundo.sh"
#include "diff.sh"
#import "bgsearch.e"
#import "bind.e"
#import "complete.e"
#import "files.e"
#import "guifind.e"
#import "guireplace.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "proctree.e"
#import "project.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "pushtag.e"
#import "saveload.e"
#import "search.e"
#import "seldisp.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "sellist.e"
#import "tagrefs.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "se/ui/toolwindow.e"
#import "util.e"
#import "se/datetime/DateTime.e"
#require "se/search/SearchResults.e"
#endregion

using namespace se.datetime;
using namespace se.search;

int _check_search(_str search_string,_str options)
{
   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_window_id = temp_view_id;
   status := search(search_string,options'@');
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);

   if (status == STRING_NOT_FOUND_RC || !status) {
      return(0);
   }
   return(status);
}
int _mffind2(_str search_string,_str options,_str files,_str wildcards=ALLFILES_RE,_str file_exclude='',int mfflags=0,int grep_id=0,int grep_before_lines=0,int grep_after_lines=0,_str file_stats='')
{
   return(_mffind(search_string,options,files,'',mfflags,false,false,wildcards,file_exclude,true,grep_id,grep_before_lines,grep_after_lines,file_stats));
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
 * <dt>L</dt><dd>Interpret string as a Perl regular expression. See section <b>Perl
 * Regular Expressions</b>.</dd>
 *
 * <dt>~</dt><dd>Interpret string as a Vim regular expression. See section <b>Vim
 * Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a Perl regular expression. See section <b>Perl
 * Regular Expressions</b>. Support for Unix syntax regular expressions has been dropped. </dd>
 *
 * <dt>B</dt><dd>Interpret string as a Perl regular expression. See section <b>Perl
 * Regular Expressions</b>. Support for Brief syntax regular expressions has been dropped.</dd>
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
 * contain wild cards.  '+t' and '-t' switches may be embedded between files
 * specifications to turn subdirectory (tree) searching on or off.
 * 
 * @param notused_atbuflist UNUSED PARAMETER
 * 
 * @param mfflags  One or more of the following flags:
 *
 * <dl>
 * <dt>MFFIND_CURBUFFERONLY</dt><dd>Search current buffer only.</dd>
 * <dt>MFFIND_FILESONLY</dt><dd>List files only and not matches.</dd> 
 * <dt>MFFIND_APPEND</dt><dd>Append to current output.</dd>
 * <dt>MFFIND_MDICHILD</dt><dd>Output to MDI child.</dd>
 * <dt>MFFIND_SINGLE</dt><dd>Stop after first occurrence.</dd>
 * <dt>MFFIND_GLOBAL</dt><dd>Find all without prompting.</dd>
 * <dt>MFFIND_THREADED</dt><dd>Run search in background.</dd> 
 * <dt>MFFIND_SINGLELINE<dd>List matching lines only once</dd> 
 * <dt>MFFIND_MATCHESONLY<dd>List matches only and not files</dd> 
 * </dl>
 * 
 * @param searchProjectFiles  Searches files in current project
 * 
 * @param searchWorkspaceFiles Searches files in workspace 
 * 
 * @param wildcards  File types to look in (ex: *.cpp;*.h)   
 * 
 * @param file_exclude  Paths, files, or file types to exclude
 *                      from a multi-file search.  Wildcard usage "*"
 *                      is currently limited to prefix and suffix
 *                      matching.
 * <dl>
 * <dt>*math*.cpp</dt><dd>Exclude any .cpp with "math" in the file name.</dd>
 * <dt>readme.txt</dt><dd>Exclude all files named readme.txt.</dd>
 * <dt>*.a;*.lib;*.png</dt><dd>Exclude any file with extension .a or .lib or .png.</dd>
 * <dt>.svn/</dt><dd>Exclude any path ".svn" while searching subdirectories</dd>
 * <dt>*demo*</dt><dd>Exclude any file or path with "demo" in the name.</dd>
 * </dl>
 * 
 * @param files_delimited_with_semicolon File list is
 *                                     using ';' to separate
 *                                     multiple paths
 * 
 * @param grep_id  Index of Search Result buffer to write 
 *                 results
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
int _mffind(_str search_string,_str options,_str files,_str notused_atbuflist,int mfflags=0,bool searchProjectFiles=false,bool searchWorkspaceFiles=false,_str wildcards='',_str file_exclude='',bool files_delimited_with_semicolon=false,int grep_id=0,int grep_before_lines=0,int grep_after_lines=0,_str file_stats='')
{
   _mdi.p_child.mark_already_open_destinations();
   save_last_search(search_string, options, -1, mfflags);

   fopts := "";
   _str fresult = strip_options(files, fopts, true);
   status := _check_search(search_string, options);
   if (status) {
      return(status);
   }

   if ((mfflags & MFFIND_THREADED) &&        // user asked for background search
        (((fresult != MFFIND_BUFFERS) && (fresult != MFFIND_BUFFER)) || searchProjectFiles || searchWorkspaceFiles) ) {   // not only searching buffers
      save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
      start_bgsearch(search_string,
                     options,
                     files,
                     mfflags,
                     searchProjectFiles,
                     searchWorkspaceFiles,
                     wildcards,
                     file_exclude,
                     files_delimited_with_semicolon,
                     grep_id,
                     grep_before_lines,
                     grep_after_lines,
                     file_stats);
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

   focus_wid := _get_focus();
   if (focus_wid==_cmdline) {
      VSWID_STATUS._set_focus();
   }
   status = _mffind2util(search_string, options, files, mfflags, searchProjectFiles, searchWorkspaceFiles, wildcards, file_exclude, files_delimited_with_semicolon, grep_id, grep_before_lines, grep_after_lines, file_stats);
   new_focus_wid := _get_focus();
   if (_iswindow_valid(focus_wid) && focus_wid._isEditorCtl() && focus_wid.p_mdi_child && 
       (new_focus_wid && new_focus_wid.p_object==OI_FORM && new_focus_wid.p_name == "_tbsearch_form")) {
      focus_wid._set_focus();
   }
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
                 int mfflags = 0, int grep_id = 0, bool show_diff = false)
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
 * <dt>L</dt><dd>Interpret string as a Perl regular expression.   See section <b>Perl
 * Regular Expressions</b>.</dd>
 *
 * <dt>~</dt><dd>Interpret string as a Vim regular expression.   See section <b>Vim
 * Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a Perl regular expression.   See section <b>Perl
 * Regular Expressions</b>. Support for Unix syntax regular expressions has been dropped.</dd>
 *
 * <dt>B</dt><dd>Interpret string as a Perl regular expression.   See section <b>Perl
 * Regular Expressions</b>. Support for Brief syntax regular expressions has been dropped.</dd>
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
                bool searchProjectFiles = false, bool searchWorkspaceFiles = false,
                _str wildcards = '', _str file_exclude = '', bool files_delimited_with_semicolon = false,
                int mfflags = 0, int grep_id = 0, bool show_diff = false, _str file_stats = '')
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
   options :+= '+';
   typeless status=_check_search(search_string, options);
   if(status) {
      return(status);
   }
   save_search(old_search_string, old_search_flags, old_word_re);
   set_find_next_msg("Find", search_string, options, VSSEARCHRANGE_CURRENT_BUFFER);
   save_last_search(search_string, options);
   save_last_replace(replace_string);
   focus_wid := _get_focus();
   if (focus_wid==_cmdline) {
      VSWID_STATUS._set_focus();
   }

   if (show_diff && !_haveDiff()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   if (show_diff) {
      if (replace_diff_begin()) {
         return (COMMAND_CANCELLED_RC);
      }
   }

   status = _mfreplace2util(search_string, replace_string, options,
                             files, searchProjectFiles, searchWorkspaceFiles,
                             wildcards, file_exclude, files_delimited_with_semicolon,
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

   treeWid := _tbGetActiveProjectsTreeWid();
   if ( treeWid ) {
      treeWid.projecttbRefresh();
   }
   return (status);
}

bool _mffind_IsToolbarVisible()
{
   return(_find_formobj("_tbsearch_form","n") != 0);
}

_str _mffind_vlx_check(_str search_options)
{
   _str options = search_options;
   if (p_lexer_name == '') {
      // strip out color options
      int status = verify(options, 'CX', 'M');
      if (status) {
         opt := substr(options, status, 1);
         options = stranslate(options, '', opt'[OKNSCPL1234FA]+', 'R');
         status = verify(options, 'CX', 'M');
         if (status) {
            opt = substr(options, status, 1);
            options = stranslate(options, '', opt'[OKNSCPL1234FA]+', 'R');
         }
      }
   }
   return options;
}


struct MFFIND_ARGS {
   int RestoreToNoMdiChildren;
   bool PromptInitDone;
   int SelectedMatch;
   bool return_status;
   int qmffind_wid;
   bool AskAboutMissingFiles;
   int list_view_id;
   int orig_view_id;
   _str search_string;
   _str options;
   bool leaveFileOpen;

   int NofFileMatches;
   int NofMatches;
   SearchResults results;
   int mfflags;
   bool cancel;

   int TotalFilesSearched;

   MFFIND_FILE_STATS file_stats;
};

static int _mffindProcessFile(MFFIND_ARGS &args,_str path,long offset=-1) {
   if (!_mffind_file_stats_test(path, args.file_stats)) {
      return 0;
   }

   status := 0;
   called_edit := false;
   file_already_loaded := false;
   typeless buf_view_id='';
   typeless result=0;
   status=_open_temp_view(path,buf_view_id,auto junk,'',file_already_loaded,false,true,0,false,false);
   if (status) {
      buf_view_id='';
   }
   if (status && status!=NEW_FILE_RC) {
      msg := "";
      if (status==FILE_NOT_FOUND_RC) {
         msg=nls("File '%s' not found",path);
      } else {
         msg=nls("Unable to edit '%s'.\n\n",path):+get_message(status);
      }
      msg :+= "\n\nContinue?";

      result=IDYES;
      if (args.AskAboutMissingFiles) {
         orig_wid := p_window_id;
         _str answer = show("-modal _yesToAll_form", msg, "Multi-file Search", false);
         if (answer== "YESTOALL") {
            args.AskAboutMissingFiles=false;
         } else if (answer != "YES") {
            result=IDNO;
         }
         p_window_id=orig_wid;
      }
      if (result!=IDYES) {
         if (args.qmffind_wid) {
            args.qmffind_wid._delete_window();
         }
         activate_window(args.orig_view_id);_set_focus();
         mou_hour_glass(false);
         clear_message();
         args.return_status=true;
         return(status);
      }
      status=0;
      return status;
   }
   if (status!=NEW_FILE_RC) {
      get_window_id(buf_view_id);
      restore_search(old_search_string,old_search_flags,'['p_word_chars']');
      top();
      int found_one_status=search(args.search_string,_mffind_vlx_check(args.options));
      done := 0;
      if (!found_one_status) {
         ++args.NofFileMatches;
         if (file_already_loaded) {
            if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
               _SetAllOldLineNumbers();
            }
         }
         /* When listing the current context, don't want to insert
            the filename line here. 
         */ 
         if (args.mfflags & MFFIND_FILESONLY) {
            args.results.insertFileLine(buf_view_id._build_buf_name());
         }
         if (args.mfflags & MFFIND_GLOBAL) {
            if (!(args.mfflags & MFFIND_FILESONLY)) {
               // Insert all occurrences
               status = 0;
               for (;;) {
                  if (status) break;
                  ++args.NofMatches;
                  args.results.insertCurrentMatch();
                  if (!def_search_result_list_nested_re_matches) {
                     match_len := match_length('');
                     if (match_len > 0) {
                        goto_point(match_length('s') + match_len - 1);
                     }
                  }
                  status=repeat_search();
               }
               args.results.endCurrentFile();
            }
         } else {
            // Insert all occurrences
            status=0; args.cancel=false;
            window_already_open := false;
            // we know the buffer exists in a temp view,
            // but is the buffer also being edited?
            if (!_no_child_windows()) {
               int i;
               for (i=1;i<=_last_window_id();++i) {
                  if (_iswindow_valid(i) &&
                      i._isEditorCtl(false) &&
                      i.p_mdi_child &&
                      i.p_buf_id==p_buf_id) {
                     window_already_open=true;
                     break;
                  }
               }
            }
            // open the buffer in an edit window
            save_search(auto p1,auto p2,auto p3,auto p4,auto p5);
            save_pos(auto found_pos);
            int phyical_col = _text_colc(p_col,'P');
            called_edit = true;
            int edit_buf_id = p_buf_id;
            p_window_id = _mdi.p_child;
            edit('+bi 'edit_buf_id, EDIT_NOWARNINGS);
            buf_wid := p_window_id;
            get_window_id(auto edit_view_id);
            save_pos(auto orig_pos);
            restore_pos(found_pos);
            if (!file_already_loaded) {
               _SetEditorLanguage();
               p_col=_text_colc(phyical_col,'I');
            }
            restore_search(p1,p2,p3,p4,p5);
            for (;;) {
               if (status) break;
               args.SelectedMatch=1;
               _deselect();_select_match();
               found := get_match_text();
               if (!(args.mfflags & MFFIND_FILESONLY)) {
                  ++args.NofMatches;
                  args.results.insertCurrentMatch();
               }
               if (!(args.mfflags & (MFFIND_GLOBAL))) {
                  if (args.mfflags & MFFIND_SINGLE) {
                     result="";
                  } else {
                     // ask user what to do with match
                     if (!args.PromptInitDone) {
                        args.PromptInitDone=true;
                        args.qmffind_wid=show('-mdi _qmffind_form');
                        _search_form_xy(args.qmffind_wid,buf_wid);
                     }
                     _nocheck _control ctlfound,ctlyes;
                     args.qmffind_wid.ctlfound.p_caption=found;
                     args.qmffind_wid.ctlyes._set_focus();
                     _SearchViewMatch(args.qmffind_wid,buf_wid);
                     save_search(p1,p2,p3,p4,p5);
                     result=_modal_wait(args.qmffind_wid);
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
                     args.mfflags |= MFFIND_GLOBAL;
                  }
               }
               activate_window(edit_view_id);
               if (!def_search_result_list_nested_re_matches) {
                  match_len := match_length('');
                  if (match_len > 0) {
                     goto_point(match_length('s') + match_len - 1);
                  }
               }
               status = repeat_search();
            }
            args.results.endCurrentFile();
            // clean up behind ourselves
            if (result=="") {  // Esc or NO
               args.RestoreToNoMdiChildren=0;
               args.qmffind_wid=0;
               done=1;
               if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
                  _SetAllOldLineNumbers();
               }
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
         // Done, break loop
         status=1;
         return status;
      }
   }
   // IF we created a temp view for this file
   if (buf_view_id != '') {
      // IF this buffer did not already exist
      if (!file_already_loaded) {
         if (called_edit) {
            typeless swold_pos=0;
            typeless swold_buf_id=0;
            _str old_buffer_name;
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
   return 0;
}


bool _mffind_is_binary_file() {
   switch (p_hex_mode==HM_HEX_ON?p_hex_mode_reload_encoding:p_encoding) {
   case VSENCODING_UTF32LE:
   case VSENCODING_UTF32BE:
   case VSENCODING_UTF32BE_WITH_SIGNATURE:
   case VSENCODING_UTF32LE_WITH_SIGNATURE:
   case VSENCODING_UTF16LE_WITH_SIGNATURE:
   case VSENCODING_UTF16BE_WITH_SIGNATURE:
   case VSENCODING_UTF16LE:
   case VSENCODING_UTF16BE:
   case VSENCODING_UTF8_WITH_SIGNATURE:
      return false;
   }
   test_size:=4000;
   if (p_buf_size<4000) {
      test_size=p_buf_size;
   }
   sample:=get_text(test_size);
   // Are there any binary characters?
   if (pos('[\0-\7\14-\31]',sample,1,'ry')) {
      return true;
   }
   return false;
}

bool _mffind_excludes_binary_files(_str file_exclude) {
   if (pos(';<Binary Files>;',';'file_exclude';',1,'i')) {
      return true;
   }else if (pos(';<Default Excludes>;',';'file_exclude';',1,'i')) {
      if (pos(';<Binary Files>;',';'_default_option(VSOPTIONZ_DEFAULT_EXCLUDES)';',1,'i')) {
         return true;
      }
   }
   return false;
}
static int _mffind2util(_str search_string,_str options,_str files,int mfflags,bool searchProjectFiles,bool searchWorkspaceFiles,_str wildcards='',_str file_exclude='',bool files_delimited_with_semicolon=false,int grep_id=0,int before_lines=0,int after_lines=0,_str file_stats='')
{
   get_window_id(auto orig_view_id);
   mou_hour_glass(true);
   message("Matching files...");
   list_view_id := 0;
   int status=_mfinit(list_view_id,files,wildcards,file_exclude,files_delimited_with_semicolon,searchProjectFiles,searchWorkspaceFiles,mfflags & MFFIND_LOOKINZIPFILES);
   if (status) {
      mou_hour_glass(false);
      clear_message();
      _message_box('No files found');
      return(status);
   }
   if (_mffind_excludes_binary_files(file_exclude)) {
      mfflags|= MFFIND_INTERNAL_EXCLUDE_BINARY_FILES;
   }

   SearchResults results;
   topline := se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude,'',orig_view_id._build_buf_name(),file_stats);
   if (!(mfflags & MFFIND_SINGLE)) {
      results.initialize(topline, search_string, mfflags, grep_id, before_lines, after_lines);
      results.showResults();
   }
   set_find_next_msg(topline);

   AskAboutMissingFiles := !(mfflags & MFFIND_QUIET);
   activate_window(list_view_id);
   mou_hour_glass(true);
   unused := 0;
   col := 0;
   status=0;
   path := "";


   MFFIND_ARGS args;
   args.RestoreToNoMdiChildren=_no_child_windows();
   args.PromptInitDone=false;
   args.SelectedMatch=0;
   args.return_status=false;
   args.AskAboutMissingFiles=AskAboutMissingFiles;
   args.qmffind_wid=0;
   args.list_view_id=list_view_id;
   args.orig_view_id=orig_view_id;
   args.search_string=search_string;
   args.options=options:+'@H+';

   args.NofFileMatches=0;
   args.NofMatches=0;
   args.results=results;
   args.mfflags=mfflags;
   args.cancel=false;
   args.TotalFilesSearched=0;
   _mffind_file_stats_init(file_stats, args.file_stats);


   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   VSWID_HIDDEN.search('',options);
   save_search(auto junk1,auto junk2, auto junk3, auto junk4, auto color_flags);
   restore_search(s1, s2, s3, s4, s5);

   if (!color_flags || true) {
      status=_grep_file_list(list_view_id,args.TotalFilesSearched,false,search_string,options,_mffindProcessFile,args,maybe_cancel_callback,mfflags);
   } else {
      if (!down()) {
         //int fileCount = 0;
         updateIncrement := 1;
         if (p_noflines > 10) updateIncrement = p_noflines intdiv 10;
         int ListLineNum;
         for (ListLineNum=1;ListLineNum<=p_Noflines;++ListLineNum) {
            process_events(args.cancel,'E');
            if (args.cancel) {
               status=COMMAND_CANCELLED_RC;
               break;
            }
            activate_window(list_view_id);
            // Need to use line numbers because switch buffers in
            // list_view_id does not always restore list line number in
            // one odd case (start with no child windows, not one file per window).
            p_line=ListLineNum;
            path=_lbget_text();
            path=strip(path,'b','"');
            if (_isUnix()) {
               if (!(args.TotalFilesSearched % updateIncrement)) {
                  message("File: "path);
               }
            } else {
               message("File: "path);
            }
            ++args.TotalFilesSearched;

            status=_mffindProcessFile(args,path,-1);
            if (status) {
               if (args.return_status) {
                  return status;
               }
               if (status==1) break;
            }
            activate_window(list_view_id);
         }
      }
   }
   activate_window(list_view_id);
   if (args.RestoreToNoMdiChildren && !_no_child_windows() && def_one_file=="") {
      _mdi.p_child._delete_window();
   }
   if (args.SelectedMatch &&
       !(def_persistent_select=='D' && def_leave_selected) &&
       !(def_keys=='brief-keys' && def_persistent_select != 'Y' && def_leave_selected)) {
      _deselect();
   }
   if (args.qmffind_wid) {
      args.qmffind_wid._delete_window();
   }
   results_text := "";
   activate_window(list_view_id);
   save_search(old_search_string,old_search_flags,old_word_re);
   mou_hour_glass(false);
   if (mfflags & MFFIND_SINGLE) {
      clear_message();
      // set the default wrap for the single match
      old_search_flags |= (_default_option('s') & (VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP));
   } else {
      if (mfflags & MFFIND_FILESONLY) {
         results_text='Matching files: 'args.NofFileMatches'     Total files searched: 'args.TotalFilesSearched;
      } else {
         results_text='Total found: 'args.NofMatches'     Matching files: 'args.NofFileMatches'     Total files searched: 'args.TotalFilesSearched;
      }
      bindings := "";
      if (def_mfflags & 1) {
         bindings=_mdi.p_child._where_is("find_next");
      } else {
         bindings=_mdi.p_child._where_is("next_error");
      }
      parse bindings with bindings ',';
      bindings_text := "";
      if (bindings!="") {
         bindings_text="  Press "bindings:+" for next occurrence.";
      }
      sticky_message(results_text:+bindings_text);
   }
   activate_window(orig_view_id);
   _delete_temp_view(list_view_id);
   args.results.done(results_text);
   args.results.showResults();
   if (status==COMMAND_CANCELLED_RC) {
      sticky_message(get_message(status));
      return(status);
   }
   return(0);
}
struct MFREPLACE_ARGS {
   bool AskAboutMissingFiles;
   int list_view_id;
   int orig_view_id;
   _str search_string;
   _str replace_string;
   _str options;
   bool doGrep;
   bool doDiff;
   bool doMFUndo;
   bool leaveFileOpen;

   bool MFUndoStarted;
   int edit_view_id;
   int NofFileMatches;
   bool go_save_all;
   bool prompt_save;
   SearchResults results;
   int Nofchanges;

   int TotalFilesSearched;

   MFFIND_FILE_STATS file_stats;
};

static int _mfreplaceProcessFile(MFREPLACE_ARGS &args,_str path,long offset=-1) {
   if (!_mffind_file_stats_test(path, args.file_stats)) {
      return 0;
   }
   ++args.TotalFilesSearched;
   args.edit_view_id=0;
   _str load_options = args.doDiff ? '+d' : '';
   // Create a view with this buffer or view
   int status;
   load_files_status := 0;
   int load_files_view_id;
   file_already_loaded := false;
   load_files_status = _open_temp_view(path, load_files_view_id, auto junk, load_options, file_already_loaded, false, true, 0, false, false);
   int load_files_buf_id = p_buf_id;
   needs_edit := !args.doDiff && (!old_go || (old_go && (args.leaveFileOpen || file_already_loaded)));
   edit_called := false;
   edit_status := 0;
   if (file_already_loaded) {
      if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
         _SetAllOldLineNumbers();
      }
   }
   if (!load_files_status) {
      restore_search(old_search_string, old_search_flags, '['p_word_chars']');
      if (offset<0) {
         top();
         status = search(args.search_string, args.options);
      } else {
         goto_point(offset); start_col:=p_col;start_linenum:=p_line;// Force calc of line number
         status = search(args.search_string, args.options);
         // This may be over kill
         if (p_line!=start_linenum || p_col!=start_col) {
            top();
            status = search(args.search_string, args.options);
         }
      }
      if (!status) {
         ++args.NofFileMatches;
         if (needs_edit) {
            linenum := p_line;
            col := p_col;
            activate_window(args.orig_view_id);
            // To allow us to find buffer with invalid file names like "Directory of ..." buffer
            // look for the buffer first.
            edit_called = true;
            edit_status = edit('+b 'path);
            get_window_id(args.edit_view_id);
            if (!edit_status) {
               goto_line(linenum);
               p_col=col;
            }
            activate_window(load_files_view_id);
            if (!file_already_loaded && edit_status) {
               _delete_buffer();
            }
            _delete_temp_view(load_files_view_id,false);
            activate_window(args.edit_view_id);
         }
      } else {
         if (!file_already_loaded) {
            _delete_buffer();
         }
         _delete_temp_view(load_files_view_id,false);
         activate_window(args.list_view_id);
         return 0;
      }
   }
   if (!edit_status) {
      edit_status = load_files_status;
   }
   if (edit_status) {
      msg := "";
      if (edit_status == FILE_NOT_FOUND_RC) {
         msg = nls("File '%s' not found",path);
      } else {
         msg = nls("Unable to edit '%s'.\n\n",path):+get_message(edit_status);
      }
      msg :+= "\n\nContinue?";
      //result=_message_box(nls("%s",msg),'',MB_YESNO);
      int result = IDYES;
      if (args.AskAboutMissingFiles) {
         orig_wid := p_window_id;
         _str answer = show("-modal _yesToAll_form", msg, "Multi-file Search", false);
         if (answer == "YESTOALL") {
            args.AskAboutMissingFiles=false;
         } else if (answer != "YES") {
            result = IDNO;
         }
         p_window_id = orig_wid;
      }
      if (result != IDYES) {
         status = COMMAND_CANCELLED_RC;
         rc = path;  // Name of file in which error occurred
         return status;
      }
      activate_window(args.list_view_id);
      status = 0;
      return 0;
   }
   if (p_modify && _need_to_save() && !args.leaveFileOpen) {
      must_save := args.go_save_all;
      if (args.prompt_save) {
         _str msg = nls("File '%s' is not saved.  File must be saved for multi-file undo operation to perform correctly. Save file now?", path);
         _str answer = show("-modal _yesToAll_form", msg, "Multi-file Replace", true);
         if (answer == "CANCEL") {
            status = COMMAND_CANCELLED_RC;
            rc = path;  // Name of file in which error occurred
            return status;
         } else if (answer == "YESTOALL") {
            args.prompt_save = false;
            args.go_save_all = true;
            must_save = true;
         } else if (answer == "NOTOALL")  {
            args.prompt_save = false;
            args.go_save_all = false;
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
   if (args.doMFUndo) {
      if (!args.MFUndoStarted) {
         temp_search_string := args.search_string;
         temp_replace_string := args.replace_string;
         if (length(temp_search_string) > 10) temp_search_string = substr(temp_search_string, 1, 10) :+ '...';
         if (length(temp_replace_string) > 10) temp_replace_string = substr(temp_replace_string, 1, 10) :+ '...';
         _str stepname = "Replace in Files "temp_search_string" => "temp_replace_string;
         _MFUndoBegin(stepname);
         args.MFUndoStarted = true;
      }
      _MFUndoBeginStep(path);
   }
   status = gui_replace2(args.search_string, args.replace_string, ((old_go)?'*':'')args.options, true, true, (args.doGrep) ? &args.results : null, args.doDiff);
   args.Nofchanges += _Nofchanges;
   if (edit_called) {
      activate_window(args.edit_view_id);
      if (status && status!=STRING_NOT_FOUND_RC) {
         // Command must have been cancelled
         message(get_message(status));
         if (args.doMFUndo) {
            _MFUndoCancelStep(path);
         }
         rc=path;  // Name of file in which error occurred
         return status;
      }
      if (p_modify && _need_to_save2() && !args.leaveFileOpen) {
         if (isEclipsePlugin()) {
            _eclipse_set_dirty(p_window_id, true);
         }
         status = save(_maybe_quote_filename(p_buf_name));
         if (status) {
            if (args.doMFUndo) {
               _MFUndoCancelStep(path);
            }
            rc=path;  // Name of file in which error occurred
            return status;
         }
      }
      if (!file_already_loaded && !args.leaveFileOpen) {
         status = quit();
         if (status) {
            if (args.doMFUndo) {
               _MFUndoCancelStep(path);
            }
            rc=path;  // Name of file in which error occurred
            return status;
         }
      }
   } else {
      if (args.doDiff && (_Nofchanges > 0)) {
         replace_diff_add_file(p_buf_name, p_encoding);
         replace_diff_set_modified_file(p_window_id);
      }
      if (!args.doDiff && (_Nofchanges > 0) && p_modify) {
         status=save(_maybe_quote_filename(p_buf_name), SV_NOADDFILEHIST);
         if (status) {
            if (args.doMFUndo) {
               _MFUndoCancelStep(path);
            }
            rc=path;  // Name of file in which error occurred
            return status;
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
         if (args.doMFUndo) {
            _MFUndoCancelStep(path);
         }
         return status;
      }
   }
   if (args.doMFUndo) {
      if (_Nofchanges <= 0) {
         _MFUndoCancelStep(path);
      } else {
         _MFUndoEndStep(path);
      }
   }
   return 0;
}

static int maybe_cancel_callback() {
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   int result1=_message_box('Would you like to cancel?','',MB_YESNO);
   def_actapp=orig_def_actapp;
   if (result1!=IDNO) {
      return COMMAND_CANCELLED_RC;
   }
   return 0;
}

static _str _mfreplace2util(_str search_string, _str replace_string, _str options, _str files,
                            bool searchProjectFiles, bool searchWorkspaceFiles,
                            _str wildcards = '', _str file_exclude = '', bool files_delimited_with_semicolon = false,
                            int mfflags = 0, int grep_id = 0, _str file_stats = '')
{
   doDiff := (mfflags & MFFIND_DIFF) != 0;
   leaveFileOpen := (mfflags & MFFIND_LEAVEOPEN) != 0;
   AskAboutMissingFiles := true;
   doMFUndo := !leaveFileOpen && !doDiff;
   //MFUndoStarted := false;
   doGrep := !doDiff;
   int orig_view_id, list_view_id, output_view_id;
   old_go = pos('*', options);
   get_window_id(orig_view_id);

   message("Matching files...");
   int status = _mfinit(list_view_id, files,wildcards,file_exclude,files_delimited_with_semicolon,searchProjectFiles,searchWorkspaceFiles,mfflags & MFFIND_LOOKINZIPFILES);
   if (status) {
      clear_message();
      rc='';  // Name of file in which error occurred
      _message_box('No files found');
      return(status);
   }
   if (_mffind_excludes_binary_files(file_exclude)) {
      mfflags|= MFFIND_INTERNAL_EXCLUDE_BINARY_FILES;
   }

   SearchResults results;

   if (doGrep) {
      _mffindNoMore(1);
      _mfrefNoMore(1);
      topline := se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude,replace_string,orig_view_id._build_buf_name(), file_stats);
      results.initialize(topline, search_string, mfflags, grep_id);
   }

   MFREPLACE_ARGS args;
   args.AskAboutMissingFiles=AskAboutMissingFiles;
   args.list_view_id=list_view_id;
   args.orig_view_id=orig_view_id;
   args.search_string=search_string;
   args.replace_string=replace_string;
   args.options=options:+'@H';
   args.doGrep=doGrep;
   args.doDiff=doDiff;
   args.doMFUndo=doMFUndo;
   args.leaveFileOpen=leaveFileOpen;

   args.MFUndoStarted=false;
   args.edit_view_id=0;
   args.NofFileMatches=0;
   args.go_save_all=false;
   args.prompt_save=true;
   args.results=results;
   args.Nofchanges=0;

   args.TotalFilesSearched=0;
   _mffind_file_stats_init(file_stats, args.file_stats);

   activate_window(list_view_id);
   mou_hour_glass(true);
   //int Nofchanges = 0;
   int RestoreToNoMdiChildren=_no_child_windows();

   // Disable the Defs tool window if active
   tbformwid := 0;
   formwid := tw_is_current_form("_tbproctree_form");
   if (formwid > 0) {
      tbformwid = GetProcTreeWID();
      tbformwid.p_enabled = false;
   }
   _project_disable_auto_build(true);

   _prompt_readonly_reset_prompt();
   path := "";
   status = 0;
   unused := 0;
   flush_keyboard();


   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   VSWID_HIDDEN.search('',options);
   save_search(auto junk1,auto junk2, auto junk3, auto junk4, auto color_flags);
   restore_search(s1, s2, s3, s4, s5);

   if (!color_flags || true) {
      status=_grep_file_list(list_view_id,unused,doDiff,search_string,options,_mfreplaceProcessFile,args,maybe_cancel_callback,mfflags);
   } else {
      for (;;) {
         if( _IsKeyPending(false)) {
            status=maybe_cancel_callback();
            if (status) {
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
         status=_mfreplaceProcessFile(args,path,-1);
         if (status) {
            break;
         }

         activate_window(list_view_id);
      }
   }
   if (doMFUndo) {
      _MFUndoEnd();
   }
   if (!status && RestoreToNoMdiChildren && !_no_child_windows() && def_one_file=="") {
      _mdi.p_child._delete_window();
   }
   mou_hour_glass(false);
   _str results_text = 'Total replaces: 'args.Nofchanges'     Matching files: 'args.NofFileMatches'     Total files searched: 'args.TotalFilesSearched;
   if (doMFUndo) {
      _str stepname = ( args.Nofchanges > 0 ) ? "     Multi-file undo available." : "";
      results_text :+= stepname;
   }
   sticky_message(results_text);
   if (doGrep) {
      args.results.done(results_text);
      args.results.showResults();
   }
   _delete_temp_view(list_view_id);
   activate_window(orig_view_id);
   if (tbformwid > 0) {
      tbformwid.p_enabled = true;
   }
   _project_disable_auto_build(false);
   if (status==COMMAND_CANCELLED_RC) {
      if (args.edit_view_id) {
         activate_window(args.edit_view_id);
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
int _mfinit(int &temp_view_id,_str files,_str wildcards='',_str file_exclude='',bool files_delimited_with_semicolon=true,
             bool searchProjectFiles=false,bool searchWorkspaceFiles=false,int look_in_zipfiles=0
            )
{
   orig_view_id := 0;
   get_window_id(orig_view_id);
   int status=bgm_gen_file_list(temp_view_id,files,wildcards,file_exclude,files_delimited_with_semicolon,searchProjectFiles,searchWorkspaceFiles,true,false,null,look_in_zipfiles);
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
      //_message_box('No files found');  //get_message(VSRC_FF_FILE_NOT_FOUND, filename));
      return(1);
   }
   if (def_search_result_sorted_filenames) {
      sort_buffer(_fpos_case);
      _remove_duplicates(_fpos_case);
   } else {
      // Faster not to sort a large list.
      _remove_duplicates(_fpos_case,0,-1,false);
   }
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
   form_x := form_y := form_width := form_height := 0;
   form_wid._get_window(form_x,form_y,form_width,form_height);
   _lxy2dxy(form_wid.p_xyscale_mode,form_x,form_y);
   _map_xy(0,buf_wid,form_x,form_y,SM_PIXEL);

   int line_height=buf_wid._text_height();
   if (buf_wid.p_cursor_y+line_height>form_y) {
      buf_wid.set_scroll_pos(buf_wid.p_left_edge,buf_wid._text_height()*2);
   }
}


// MFFIND_FILE_STATS
/* 
   MAX FILE SIZE | MODIFIED_TIME_OP, "LOCAL TIME 1", "LOCAL TIME 2"
*/

long _mffind_file_stats_get_file_size(_str file_stats) 
{
   parse file_stats with auto mffile_size '|' auto mffile_modified;
   if (mffile_size != '' ) {
      if (isinteger(mffile_size) && ((long)mffile_size > 0)) {
         return (long) mffile_size;
      }
   }
   return 0;
}

int _mffind_file_stats_get_file_modified(_str file_stats, _str& dt1, _str& dt2) 
{
   parse file_stats with auto mffile_size '|' auto mffile_modified;
   dt1 = dt2 = "";
   if (mffile_modified != '') {
      parse mffile_modified with auto op ',' '"' auto t1 '"' ',' '"' auto t2 '"';
      if (op != '' && isinteger(op)) {
         mod_op := (int)op;
         dt1 = t1;
         dt2 = t2;
         return mod_op;
      }
   }
   return 0;
}

void _mffind_file_stats_init(_str file_stats, MFFIND_FILE_STATS& info)
{
   info.max_file_size=0;
   info.modified_file_op=0;
   info.modified_file_time1=0;
   info.modified_file_time2=0;

   if (file_stats != '') {
      mffile_size := _mffind_file_stats_get_file_size(file_stats);
      if (mffile_size > 0) {
         info.max_file_size = mffile_size * 1024;
      }

      op := _mffind_file_stats_get_file_modified(file_stats, auto modtime1, auto modtime2);
      if (op != 0) {
         info.modified_file_op = op;
         if (modtime1 != '') {
            DateTime dt = DateTime.fromString(modtime1);
            info.modified_file_time1 = dt.toTimeF();
            if (op == MFFILE_STAT_TIME_DATE) {
               dt = dt.add(1, DT_DAY);
               info.modified_file_time2 = dt.toTimeF();
            } else if (modtime2 != '') {
               dt = DateTime.fromString(modtime2);
               info.modified_file_time2 = dt.toTimeF();
            }
         }
      }
   }
}

bool _mffind_file_stats_test(_str filename, MFFIND_FILE_STATS& info)
{
   if (info.max_file_size > 0) {
      file_size := _file_size(filename);
      if (file_size > info.max_file_size) {
         return false;
      }
   }

   if (info.modified_file_op > 0) {
      t := (long)(_file_date(filename, 'B'));

      status := true;
      switch(info.modified_file_op) {
      case MFFILE_STAT_TIME_DATE:
         status = ((t >= info.modified_file_time1) && (t < info.modified_file_time2));
         break;

      case MFFILE_STAT_TIME_BEFORE:
         status = (t < info.modified_file_time1);
         break;

      case MFFILE_STAT_TIME_AFTER:
         status = (t > info.modified_file_time1);
         break;

      case MFFILE_STAT_TIME_RANGE:
         status = ((t >= info.modified_file_time1) && (t <= info.modified_file_time2));
         break;

      case MFFILE_STAT_TIME_NOT_RANGE:
         status = !((t >= info.modified_file_time1) && (t <= info.modified_file_time2));
         break;

      default:
         break;
      }
      if (!status) {
          return status;
      }
   }
   return true;
}

