////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45237 $
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
#import "clipbd.e"
#import "dlgman.e"
#import "guifind.e"
#import "guiopen.e"
#import "markfilt.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "vc.e"
#require "se/search/SearchResults.e"
#endregion

using se.search.SearchResults;

/*
  _qryes.p_user=old_mark' 'wrap_mark' 'search_mark' 'options' 'search_flags' 'searched_in_wrap_mark' 'leave_selected
   _qrno.p_user=search_string
   _qrlast.p_user=replace_string
   _qrquit.p_user=0;               //Nofchanges
   _qrgo.p_user=form_parent

*/

/**
 * Searches for <i>search_string</i> and prompts you whether to replace it
 * with <i>replace_string.</i>  The <b>Prompt Replace dialog box</b> is
 * displayed to prompt you for an action when an occurrence is found.
 *
 * @param options is a string of one or more of the following:
 * <dl>
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
 * <dt><</dt><dd>If found, position cursor at beginning of word.</dd>
 *
 * <dt>></dt><dd>If found, position cursor at end of word.</dd>
 *
 * <dt>*</dt><dd>Make changes without prompting.</dd>
 *
 * <dt>R</dt><dd>Interprets <i>string1</i> to be a SlickEdit regular expression.  In
 * addition, the characters \ and # take on new meaning in the replace string.
 * See <b>SlickEdit Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interprets <i>string1</i> to be a UNIX regular expression.  In
 * addition, the character \ takes on new meaning in the replace string.  See
 * <b>UNIX Regular Expressions</b>.</dd>
 *
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See section <b>Brief
 * Regular Expressions</b>.</dd>
 *
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 *
 * <dt>N</dt><dd>Do not interpret search string as a regular search string.</dd>
 *
 * <dt>P</dt><dd>Wrap to beginning/end when string not found.</dd>
 *
 * <dt>W</dt><dd>Limits search to words.  Used to search and replace variable names.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt>
 * <dd>Specifies the valid characters in a word.  The default value is [A-Za-
 * z0-9_$].</dd>
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
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string NOT be
 * one of the color coding elements specified. For example, "XCS" requires that
 * the first character not be in a comment or string. <i>CCLetters</i> is a
 * string of one or more of the following color coding element letters:</dd>
 *
 *      <dl>
 *      <dt>O</dt><dd>Other</dd>
 *      <dt>K</dt><dd>Keyword</dd>
 *      <dt>N</dt><dd>Number</dd>
 *      <dt>S</dt><dd>String</dd>
 *      <dt>C</dt><dd>Comment</dd>
 *      <dt>P</dt><dd>Preprocessing</dd>
 *      <dt>L</dt><dd>Line number</dd>
 *      <dt>1</dt><dd>Symbol 1</dd>
 *      <dt>2</dt><dd>Symbol 2</dd>
 *      <dt>3</dt><dd>Symbol 3</dd>
 *      <dt>4</dt><dd>Symbol 4</dd>
 *      <dt>F</dt><dd>Function color</dd>
 *      <dt>V</dt><dd>No save line</dd>
 *      </dl>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to be
 * one of the color coding elements specified. See <i>CCLetters</i> above.</dd>
 * </dl>
 *
 *
 * @param quiet When true, no message is displayed on the message line when an error occurs.
 * @param multifile  When true, the "Next file" button of the Prompt Replace dialog is made visible.
 * @param logfile
 * @param tempFile Set to true when doing replace in temp file
 *                 to avoid read-only checks/prompts
 *
 * @return Returns 0 if successful.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories File_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 * @see find_next
 * @see gui_find
 * @see find
 * @see replace
 * @see gui_replace
 * @see find_prev
 */
int gui_replace2(_str search_string,_str replace_string,_str options, boolean quiet = false, boolean multifile = false, SearchResults* results = null, boolean tempFile = false)
{
   _Nofchanges=0;
   int edit_wid = p_window_id;
   _SearchInitSkipped(0);

   if (!tempFile && _QReadOnly()) {
      int status = _prompt_readonly_file(multifile);
      if (status == COMMAND_CANCELLED_RC) {
         return(status);
      } else if (status == -1) {
         return(0);
      } else if (status) {
         return(status);
      }
   }
   typeless mark=_duplicate_selection('');
   typeless old_mark=0;
   typeless search_mark=0;
   typeless wrap_mark=0;
   typeless searched_in_wrap_mark=0;
   typeless search_flags=0;
   typeless go=0;
   typeless leave_selected=0;
   typeless xv_options="xv,"options;
   typeless status=qreplace_init(search_string,replace_string,xv_options,
                                 old_mark,    // Handle to original marked area
                                 search_mark, // Handle to mark for original cursor pos
                                 wrap_mark,   // Handle to mark. Area to search in when reach end.
                                 searched_in_wrap_mark,
                                 search_flags, // flags equivalent of options
                                 go,
                                 leave_selected);
   if (status) {
      // If a critical message box was not display
      if (!quiet) { // arg(4)==1 means suppress STRING_NOT_FOUND_RC messages
         if (status == STRING_NOT_FOUND_RC) {
            message(get_message(status));
         }
      }
      return(status);
   }

   int Nofchanges=0;
   int add_Nofchanges=0;
   int searchrc=0;
   _str wrap_option="";
   old_go = go;
   if (go) {
      _show_selection(old_mark);
      Nofchanges = 1;
      search_replace(replace_string);
      if (results != null) results->insertCurrentReplace();
      searchrc = repeat_search('', _text_colc( match_length('P'),'I'), 1);
      if (!searchrc || (search_flags & WRAP_SEARCH)) {
         if ( !searchrc && !(search_flags & REVERSE_SEARCH) ) {
            goto_point(match_length('S'));
         }
         if ( !searchrc ) {
            wrap_option = (searched_in_wrap_mark == 1 ) ? 'm' : '';
            //searchrc = search(search_string,wrap_option'@':+options'*',replace_string,add_Nofchanges);
            searchrc = _qreplace_all(search_string, replace_string, wrap_option'@':+options, add_Nofchanges, results);
            Nofchanges += add_Nofchanges;
         }
         if (!searched_in_wrap_mark && _select_type(wrap_mark) != '' &&
             confirm_wrap(search_flags, search_string, 'm@'options, wrap_mark, old_mark, false, false)) {
            searched_in_wrap_mark = 1;
            if (search_flags & REVERSE_SEARCH) {
               _end_select(wrap_mark);
            } else {
               _begin_select(wrap_mark);
            }
            typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
            _show_selection(old_mark);
            //searchrc = search(search_string, 'm@'options'*', replace_string, add_Nofchanges);
            if (0 == search(search_string, 'm@'options)) {
               searchrc = _qreplace_all(search_string, replace_string, 'm@'options, add_Nofchanges, results);
               Nofchanges += add_Nofchanges;
            }
         }
      }
      if ( def_restore_cursor ) {
         _begin_select(search_mark);
      }
      return(qreplace_done2(searchrc,mark,old_mark,wrap_mark,search_mark,searched_in_wrap_mark,Nofchanges,edit_wid));
   }
   typeless old_show_cursor = _default_option('C');
   _default_option('C',0);

   int tbformwid = 0;
   int formwid = _tbIsActive("_tbproctree_form");
   if ( formwid > 0 && !formwid.p_enabled ) {
      tbformwid = formwid;
      tbformwid.p_enabled = true;
   }

   _str replace_args = old_mark' 'wrap_mark' 'search_mark' 'options' 'search_flags' 'searched_in_wrap_mark' 'leave_selected;
   typeless result = show('-reinit -modal -nocenter _qreplace_form', search_string, replace_string, p_window_id, multifile, replace_args, results, options );
   if (tbformwid > 0) {
      // The Defs tool window was disabled, so re-disable it
      tbformwid.p_enabled = false;
   }
   _killReplaceToolTip();
   _default_option('C', old_show_cursor);
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   old_go = result;
   return(0);
   }

static int _qreplace_all(_str search_string, _str replace_string, _str options, int& add_Nofchanges, SearchResults* results)
{
   int status = 0;
   add_Nofchanges = 0;
   while (!status) {
      ++add_Nofchanges;
      search_replace(replace_string);
      if (results != null) results->insertCurrentReplace();
      status = repeat_search('', _text_colc( match_length('P'),'I'), 1);
   }
   return status;
}

static _str gSaveSearch_search_string;
static int gSaveSearch_flags;
static int gSaveSearch_word_re;
static int gSaveSearch_ReservedMore;

defeventtab _qreplace_form;

void _qryes.on_create(_str search_string="",
                      _str replace_string="",
                      typeless wid=0,
                      typeless multifile=0,
                      _str mark_info="",
                      typeless results=null
                     )
{
   _qrno.p_user         = search_string;           // search string
   _qrlast.p_user       = replace_string;          // replace string
   _qrgo.p_user         = wid;                     // p_window_id
   _qryes.p_user        = mark_info;               // old_mark' 'wrap_mark' 'search_mark' 'options' 'search_flags' 'searched_in_wrap_mark' 'leave_selected
   _qrquit.p_user       = 0;                       // Nofchanges
   _qrnext.p_visible    = (multifile == 1);        // multifile
   _qrnext.p_user       = results;                 // SearchResults
   _qrfound.p_caption   = wid.get_match_text();
   _search_form_xy(p_active_form, wid);
   qreplace_liney(replace_string);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

void _qryes.on_destroy()
{
   typeless mark = _duplicate_selection('');
   typeless old_mark=0;
   typeless wrap_mark=0;
   typeless search_mark=0;
   typeless searched_in_wrap_mark=0;
   typeless leave_selected=0;
   parse _qryes.p_user with old_mark wrap_mark search_mark . . searched_in_wrap_mark leave_selected;
   if (searched_in_wrap_mark == 1) {
      typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
   }
   _show_selection(old_mark);
   _free_selection(wrap_mark);
   _free_selection(search_mark);
   _free_selection(mark);
   _Nofchanges = _qrquit.p_user;
}

static void qreplace_done(typeless mark, int &searchrc,var go)
{
   int Nofchanges = _qrquit.p_user;
   _Nofchanges = Nofchanges;
   _show_selection(mark);
   p_active_form._delete_window(go);
   Nofchanges -= _SearchQNofSkipped();
   _Nofchanges = Nofchanges;
   typeless skipped = _SearchQSkipped();
   if (skipped != '') {
      if (searchrc == STRING_NOT_FOUND_RC) {
         searchrc = 0;
         clear_message();
      }
      refresh();
      _message_box(get_message(VSRC_FF_FOLLOWING_LINES_SKIPPED)skipped);
   }
   if (searchrc == COMMAND_CANCELLED_RC || searchrc == STRING_NOT_FOUND_RC || searchrc == 0) {
      qreplace_Nofchanges(searchrc, Nofchanges);
   } else {
      _message_box(get_message(searchrc));
   }
}

static int qreplace_done2(int searchrc,
                          typeless mark,
                          typeless old_mark,
                          typeless wrap_mark,
                          typeless search_mark,
                          typeless searched_in_wrap_mark,
                          int Nofchanges,int edit_wid)
{
   if (searched_in_wrap_mark == 1) {
      typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
   }
   _show_selection(old_mark);
   _free_selection(wrap_mark);
   _free_selection(search_mark);
   _free_selection(mark);
   Nofchanges -= _SearchQNofSkipped();
   _Nofchanges = Nofchanges;
   typeless skipped = _SearchQSkipped();
   if (skipped != '') {
      if (searchrc == STRING_NOT_FOUND_RC) {
         searchrc = 0;
         clear_message();
      }
      refresh();
      _message_box(get_message(VSRC_FF_FOLLOWING_LINES_SKIPPED)skipped);
   }
   if (searchrc == COMMAND_CANCELLED_RC || searchrc == STRING_NOT_FOUND_RC || searchrc == 0) {
      qreplace_Nofchanges(searchrc, Nofchanges);
   } else {
      _message_box(get_message(searchrc));
   }
   return(0);
}

void _qrquit.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   typeless old_mark=0;
   typeless wrap_mark=0;
   typeless search_mark=0;
   typeless options=0;
   typeless search_flags=0;
   typeless searched_in_wrap_mark=0;
   typeless leave_selected=0;
   parse _qryes.p_user with old_mark wrap_mark search_mark options search_flags searched_in_wrap_mark leave_selected;
   typeless mark = _duplicate_selection('');
   if (leave_selected) {
      typeless orig_mark = _duplicate_selection();
      typeless prev_mark;
      if (searched_in_wrap_mark == 1) {
         prev_mark = wrap_mark;
         wrap_mark = orig_mark;
      } else {
         prev_mark = old_mark;
         old_mark = orig_mark;
      }
      _free_selection(prev_mark);
      _qryes.p_user=old_mark' 'wrap_mark' 'search_mark' 'options' 'search_flags' 'searched_in_wrap_mark' 'leave_selected;
   }
   qreplace_done(mark,COMMAND_CANCELLED_RC,'');
}

void _qryes.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   // Zap check variables. close if no child windows active, restore search
   typeless wid=0;
   _str search_string="";
   _str replace_string="";
   typeless options="";
   typeless search_flags="";
   typeless searched_in_wrap_mark=0;
   typeless search_mark=0;
   typeless old_mark=0;
   typeless mark=_duplicate_selection('');
   qreplace_resume(wid,search_string,replace_string,options,search_flags,searched_in_wrap_mark,search_mark,old_mark);
   SearchResults* results = (SearchResults*)_qrnext.p_user;
   ++_qrquit.p_user;
   _show_selection(old_mark);
   int orig_wid = p_window_id;
   p_window_id = wid;
   search_replace(replace_string);
   if (results != null) results->insertCurrentReplace();
   int searchrc = repeat_search('', _text_colc( match_length('P'),'I'), 1);
   if (searchrc == STRING_NOT_FOUND_RC) {
      searchrc = qreplace_wrap(orig_wid);
   }
   _show_selection(mark);
   if (!searchrc) {
      _MaybeUnhideLine();
      _select_match();
      orig_wid._qrfound.p_caption = get_match_text();
   }
   p_window_id = orig_wid;
   if (searchrc) {
      qreplace_done(mark,searchrc, 0);
      save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
      return;
   }
   qreplace_liney(replace_string);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

void _qrno.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   // Zap check variables. close if no child windows active, restore search
   typeless wid=0;
   _str search_string="";
   _str replace_string="";
   typeless options="";
   typeless search_flags="";
   typeless searched_in_wrap_mark=0;
   typeless search_mark=0;
   typeless old_mark=0;
   typeless mark=_duplicate_selection('');
   qreplace_resume(wid,search_string,replace_string,options,search_flags,searched_in_wrap_mark,search_mark,old_mark);
   // Check if the text at the cursor
   _show_selection(old_mark);
   int orig_wid = p_window_id;
   p_window_id = wid;
   int searchrc = repeat_search();
   if (searchrc == STRING_NOT_FOUND_RC) {
      searchrc = qreplace_wrap(orig_wid);
   }
   _show_selection(mark);
   if (!searchrc) {
      _MaybeUnhideLine();
      _select_match();
      orig_wid._qrfound.p_caption = get_match_text();
   }
   p_window_id = orig_wid;
   if (searchrc) {
      qreplace_done(mark,searchrc,0);
      save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
      return;
   }
   qreplace_liney(replace_string);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

void _qrlast.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   // Zap check variables. close if no child windows active, restore search
   typeless wid=0;
   _str search_string="";
   _str replace_string="";
   typeless options="";
   typeless search_flags="";
   typeless searched_in_wrap_mark=0;
   typeless search_mark=0;
   typeless old_mark=0;
   typeless mark=_duplicate_selection('');
   qreplace_resume(wid,search_string,replace_string,options,search_flags,searched_in_wrap_mark,search_mark,old_mark);
   SearchResults* results = (SearchResults*)_qrnext.p_user;
   // Check if the text at the cursor
   ++_qrquit.p_user;
   //_show_selection(old_mark);
   int orig_wid=p_window_id;
   p_window_id = wid;
   int searchrc=search_replace(replace_string);
   if (results != null) results->insertCurrentReplace();
   p_window_id = orig_wid;
   qreplace_done(mark,COMMAND_CANCELLED_RC,0);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

void _qrnext.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   // Zap check variables. close if no child windows active, restore search
   typeless mark=_duplicate_selection('');
   qreplace_done(mark,COMMAND_CANCELLED_RC,0);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

void _qrgo.lbutton_up()
{
   restore_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
   // Zap check variables. close if no child windows active, restore search
   typeless wid=0;
   _str search_string="";
   _str replace_string="";
   typeless options="";
   typeless search_flags="";
   typeless searched_in_wrap_mark=0;
   typeless search_mark=0;
   typeless old_mark=0;
   typeless mark=_duplicate_selection('');
   qreplace_resume(wid,search_string,replace_string,options,search_flags,searched_in_wrap_mark,search_mark,old_mark);
   SearchResults* results = (SearchResults*)_qrnext.p_user;

   // Check if the text at the cursor
   ++_qrquit.p_user;
   _show_selection(old_mark);
   int orig_wid = p_window_id;
   p_window_id = wid;
   int searchrc = search_replace(replace_string);
   if (results != null) results->insertCurrentReplace();
   searchrc = repeat_search('', _text_colc( match_length('P'),'I'), 1);
   if (searchrc) {
      if (0 == qreplace_wrap(orig_wid)) {
         parse orig_wid._qryes.p_user with . . . . . . searched_in_wrap_mark .;
      } else {
         p_window_id = orig_wid;
         if ( def_restore_cursor ) wid._begin_select(search_mark);
         qreplace_done(mark, searchrc, 1);
         save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
         return;
      }
   }
   if (! (search_flags & REVERSE_SEARCH) && !searchrc) {
      goto_point(match_length('S'));
   }
   _str wrap_option = (searched_in_wrap_mark == 1) ? 'm' : '';
   int add_Nofchanges1 = 0;
   int add_Nofchanges2 = 0;
   //searchrc=search(search_string,wrap_option'@':+options'*',replace_string,add_Nofchanges1);
   searchrc = _qreplace_all(search_string, replace_string, wrap_option'@':+options, add_Nofchanges1, results);
   if (0 == qreplace_wrap(orig_wid)) {
      //searchrc=search(search_string,'m@'options'*',replace_string,add_Nofchanges2);
      searchrc = _qreplace_all(search_string, replace_string, 'm@'options, add_Nofchanges2, results);
   }
   p_window_id = orig_wid;
   _qrquit.p_user += add_Nofchanges1 + add_Nofchanges2;
   if ( def_restore_cursor ) wid._begin_select(search_mark);
   qreplace_done(mark,searchrc,1);
   save_search(gSaveSearch_search_string,gSaveSearch_flags,gSaveSearch_word_re,gSaveSearch_ReservedMore);
}

static int qreplace_wrap(int orig_wid)
{
   typeless p; save_pos(p);
   _str search_string = orig_wid._qrno.p_user;
   typeless old_mark=0;
   typeless wrap_mark=0;
   typeless search_mark=0;
   typeless options=0;
   typeless search_flags=0;
   typeless searched_in_wrap_mark=0;
   typeless leave_selected=0;
   parse orig_wid._qryes.p_user with old_mark wrap_mark search_mark options search_flags searched_in_wrap_mark leave_selected;
   if (!searched_in_wrap_mark && _select_type(wrap_mark) != '' && (search_flags & WRAP_SEARCH)) {
      searched_in_wrap_mark = 1;
      if (search_flags & REVERSE_SEARCH) {
         _end_select(wrap_mark);
      } else {
         _begin_select(wrap_mark);
      }
      clear_message();
      typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
      _show_selection(old_mark);
      orig_wid._qryes.p_user = old_mark' 'wrap_mark' 'search_mark' 'options' 'search_flags' 'searched_in_wrap_mark' 'leave_selected;
      int searchrc = search(search_string,'m@'options);
      if (searchrc) {
         restore_pos(p);
      }
      return(searchrc);
   }
   restore_pos(p);
   return(STRING_NOT_FOUND_RC);
}

static void qreplace_resume(var wid,var search_string,var replace_string,var options,var search_flags,var searched_in_wrap_mark,var search_mark,var old_mark)
{
   parse _qryes.p_user with old_mark . search_mark options search_flags searched_in_wrap_mark .;
   search_string = _qrno.p_user;
   replace_string = _qrlast.p_user;
   wid = _qrgo.p_user;
}

static _str qreplace_init(_str &search_string,
                          _str &replace_string,
                          var options,
                          var old_mark,    // Handle to original marked area
                          var search_mark, // Handle to mark for original cursor pos
                          var wrap_mark,   // Handle to mark. Area to search in when reach end.
                          var searched_in_wrap_mark,
                          var flags,  // flags equivalent of options
                          var go,
                          var leave_selected)
{
   typeless mark = _duplicate_selection('');
   old_mark = _duplicate_selection();
   if (isinteger(options)) { /* Flags given? */
      go = options & GO_SEARCH;
      options = make_search_options(options, 1);
   } else {
      typeless a="";
      parse options with a 'w=','i';
      go = pos('*', a);
   }
   // Set the word characters
   restore_search(old_search_string,0,'['p_word_chars']');
   search('', options);
   // Translate flags to word_re
   typeless junk;
   typeless word_re;
   save_search(junk, flags, word_re);
   old_search_flags = flags;
   old_word_re = word_re;
   old_search_string = search_string;
   old_replace_string = replace_string;
   search_mark=_alloc_selection();
   if (search_mark < 0) {
      _message_box(get_message(search_mark));
      return(search_mark);
   }
   _select_char(search_mark);     /* Save cursor position */
   wrap_mark=_alloc_selection();
   if (wrap_mark < 0) {
      _message_box(get_message(wrap_mark));
      _free_selection(search_mark);
      return(wrap_mark);
   }

   if ((flags & MARK_SEARCH) && (_cursor_move_deselects() || _cursor_move_extendssel())) {
      if (_select_type(old_mark,'S') == 'C') select_it(_select_type(), old_mark);  /* lock the mark. */
      if (flags & REVERSE_SEARCH) {
         _end_select(); _end_line();
      } else {
         _begin_select(); _begin_line();
      }
      if (flags & WRAP_SEARCH) flags &= ~WRAP_SEARCH;
   }
   searched_in_wrap_mark = 0;
   if ((flags & (MARK_SEARCH|WRAP_SEARCH))==(MARK_SEARCH|WRAP_SEARCH) &&
       select_active() && _select_type()=='BLOCK') {
      // Can't handle wrap searching within block marks that well
      // Must start at begin or end of block
      if (flags & REVERSE_SEARCH) {
         _end_select();
      } else {
         _begin_select();
      }
      searched_in_wrap_mark = 2;
   }
   int searchrc=0;
   if (search_string:=='') {
      searchrc = STRING_NOT_FOUND_RC;
   } else {
      searchrc = search(search_string,options);
      if (searchrc == INVALID_REGULAR_EXPRESSION_RC) {
         _show_selection(mark);
         _free_selection(old_mark);
         _free_selection(wrap_mark);
         _free_selection(search_mark);
         return(searchrc);
      }
   }
   typeless p;
   typeless style='';
   if (search_string:!='' && (flags & WRAP_SEARCH) && !searched_in_wrap_mark) {
      save_pos(p);
      if ((flags & MARK_SEARCH) && select_active()) {
         style = 'CHAR';
         if (_select_type()=='BLOCK') {
            style = 'BLOCK';
         }
         // Is this an inclusive mark?
         if (flags & REVERSE_SEARCH) {
            if (searchrc) {
               _begin_select();
               if (_select_type()=='LINE') {
                  _begin_line();
               }
            } else {
               // Place cursor at first character string found
               int status2 = goto_point(match_length('s')+match_length(''));
               if (status2) {
                  // Must be binary file and found string at end of file.
                  // can't seek past end of file
                  clear_message();bottom();
               }
            }
            // Select text from after string to bottom of file
            select_it(style,wrap_mark);
            _end_select();
            if (_select_type()=='LINE') {
               _end_line(); p_col += 2;
            } else if (_select_type()=='CHAR' && _select_type('','i')) {
               // This is an inclusive character mark
               ++p_col;
            }
            select_it(style,wrap_mark);
         } else {
            if (searchrc) {
               _end_select();
               if (_select_type()=='LINE') {
                  _end_line(); p_col += 2;
               } else if (_select_type()=='CHAR' && _select_type('','i')) {
                  // This is an inclusive character mark
                  ++p_col;
               }
            } else {
               // Place cursor at start of string found
               goto_point(match_length('s'));
            }
            // Select text from start of string to top of file
            select_it(style,wrap_mark);
            _begin_select();
            if (_select_type()=='LINE') {
               _begin_line();
            }
            select_it(style,wrap_mark);
         }
      } else {
         if (flags & REVERSE_SEARCH) {
            if (searchrc) {
               top();
            } else {
               // Place cursor at first character string found
               int status2 = goto_point(match_length('s')+match_length(''));
               if (status2) {
                  // Must be binary file and found string at end of file.
                  // can't seek past end of file
                  clear_message(); bottom();
               }
            }
            // Select text from after string to bottom of file
            _select_char(wrap_mark); bottom(); _select_char(wrap_mark);
         } else {
            if (searchrc) {
               bottom();
            } else {
               // Place cursor at start of string found
               goto_point(match_length('s'));
            }
            // Select text from start of string to top of file
            _select_char(wrap_mark); top(); _select_char(wrap_mark);
         }
      }
      restore_pos(p);
   }
   _str wrap_option="";
   int wrap_flag=0;
   if ( searchrc<0 ) {
      if (!searched_in_wrap_mark && _select_type(wrap_mark)!='') {
         save_pos(p);
         searched_in_wrap_mark = 1;
         if (flags & REVERSE_SEARCH) {
            _end_select(wrap_mark);
         } else {
            _begin_select(wrap_mark);
         }
         clear_message();
         typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
         _show_selection(old_mark);
         wrap_option = 'm';
         wrap_flag = MARK_SEARCH;
         searchrc = search(search_string,'m'options);
         if (searchrc) {
            restore_pos(p);
         }
      }
   }
   if (searchrc) {
      if (searched_in_wrap_mark == 1) {
         typeless temp = wrap_mark; wrap_mark = old_mark; old_mark = temp;
      }
      _show_selection(mark);
      _free_selection(old_mark);
      _free_selection(wrap_mark);
      _free_selection(search_mark);
      return(searchrc);
   }
   int orig_mark_flag = (old_search_flags & MARK_SEARCH);
   leave_selected = !(orig_mark_flag && select_active()) && def_persistent_select=='D' && def_leave_selected;
   _show_selection(mark);
   if (!go) {
      _select_match();
      _MaybeUnhideLine();
   }
   if (flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE)) {
      // check for valid replace string
      get_replace_text(replace_string);
      if (rc) {
         return rc;
      }
   }
   return(searchrc);
}

static void qreplace_liney(_str replace_string)
{
   int form_x, form_y, form_width, form_height;
   int form_wid = p_active_form;
   int buf_wid = _qrgo.p_user;
   int line_height = buf_wid.p_font_height;
   int selection_mark;
   form_wid._get_window(form_x, form_y, form_width, form_height);
   _lxy2dxy(form_wid.p_xyscale_mode, form_x, form_y);
   _map_xy(0, buf_wid, form_x, form_y, SM_PIXEL);
   if (buf_wid.p_cursor_y + line_height * 2 > form_y) {
      buf_wid.set_scroll_pos(buf_wid.p_left_edge, line_height * 2);
   }
   buf_wid._showReplaceToolTip(replace_string);
}

defeventtab _prompt_readonly;

#define PROMPT_READONLY_SKIP           0x0001
#define PROMPT_READONLY_MAKE_WRITABLE  0x0002
#define PROMPT_READONLY_CHECKOUT       0x0004
#define PROMPT_READONLY_EDIT_IN_MEMORY 0x0008
#define PROMPT_READONLY_NOPROMPT       0x1000

static int prompt_readonly_flags = PROMPT_READONLY_SKIP;

void _prompt_readonly.on_create(typeless parent_id="", typeless showApplyAll="")
{
   _filename.p_caption = parent_id.p_buf_name;
   _applyall.p_visible = showApplyAll;
   ctlradio1.p_value = (prompt_readonly_flags & PROMPT_READONLY_MAKE_WRITABLE) ? 1 : 0;
   ctlradio2.p_value = (prompt_readonly_flags & PROMPT_READONLY_CHECKOUT) ? 1 : 0;
   ctlradio3.p_value = (prompt_readonly_flags & PROMPT_READONLY_SKIP) ? 1 : 0;
   ctlradio4.p_value = (prompt_readonly_flags & PROMPT_READONLY_EDIT_IN_MEMORY) ? 1 : 0;
}

void _ok.lbutton_up()
{
   prompt_readonly_flags = 0;
   prompt_readonly_flags |= (ctlradio1.p_value) ? PROMPT_READONLY_MAKE_WRITABLE : 0;
   prompt_readonly_flags |= (ctlradio2.p_value) ? PROMPT_READONLY_CHECKOUT : 0;
   prompt_readonly_flags |= (ctlradio3.p_value) ? PROMPT_READONLY_SKIP : 0;
   prompt_readonly_flags |= (ctlradio4.p_value) ? PROMPT_READONLY_EDIT_IN_MEMORY : 0;
   p_active_form._delete_window('flags');
}

void _saveas.lbutton_up()
{
   p_active_form._delete_window('saveas');
}

void _applyall.lbutton_up()
{
   prompt_readonly_flags = PROMPT_READONLY_NOPROMPT;
   prompt_readonly_flags |= (ctlradio1.p_value) ? PROMPT_READONLY_MAKE_WRITABLE : 0;
   prompt_readonly_flags |= (ctlradio2.p_value) ? PROMPT_READONLY_CHECKOUT : 0;
   prompt_readonly_flags |= (ctlradio3.p_value) ? PROMPT_READONLY_SKIP : 0;
   prompt_readonly_flags |= (ctlradio4.p_value) ? PROMPT_READONLY_EDIT_IN_MEMORY : 0;
   p_active_form._delete_window('flags');
}

int _prompt_readonly_file(boolean multifile = false)
{
   _str result = 'flags';
   int status = 0;
   if (!multifile) {
      prompt_readonly_flags &= ~PROMPT_READONLY_NOPROMPT;
   }
   if (isEclipsePlugin()) {
      if (_eclipse_validate_edit(p_buf_name) == 1) {
         // eclipse has already updated the rw attributes on disk
         // all we need to do is set the appropriate property
         p_readonly_mode=0;
         return(0);
      } 
      // if eclipse did not automatically change the file to writable, this could
      // have been for a number or reasons, so although it results in a double prompt
      // we need to let slickedit do it's thing here...
   }
   if (!(prompt_readonly_flags & PROMPT_READONLY_NOPROMPT)) {
      result = show('-reinit -modal -nocenter _prompt_readonly', p_window_id, multifile);
      if (result == '') {
         return COMMAND_CANCELLED_RC;
      }
   }
   if (result == 'flags') {
      if (prompt_readonly_flags & PROMPT_READONLY_MAKE_WRITABLE) {
         _set_read_only(false, false, true, false);
         status = 0;   // flip readonly file attrs, return ok status
      } else if (prompt_readonly_flags & PROMPT_READONLY_EDIT_IN_MEMORY) {
         status = 0;   // edit anyway, return ok status
      } else if (prompt_readonly_flags & PROMPT_READONLY_CHECKOUT) {
         status = vccheckout(p_buf_name, multifile, false);
      } else {
         status = -1;  // skip processing
      }
   } else if (result == 'saveas') {
      status = gui_save_as();
   }
   return status;
}

void _prompt_readonly_reset_prompt()
{
   prompt_readonly_flags &= ~PROMPT_READONLY_NOPROMPT;
}

int _StrFontSize2PointSizeX10(_str font_size)
{
   if (!isinteger(font_size)) {
      /* Could be 12 x 18 */
      typeless width, height;
      parse font_size with width ('X'),'i' height;
      font_size=0x80000000|(width<<16)|height;
      return(0x80000000|(width<<16)|height);
   }
   return((int)font_size*10);
}

void _showReplaceToolTip(_str replace_string)
{
   if (def_disable_replace_tooltip || replace_string :== '' || !match_length()) {
      return;
   }
   //refresh('W'); // this fixes some problem with p_cursor_y not up-to-date
   save_pos(auto p);
   goto_point(match_length('S'));
   int x = p_cursor_x;
   int y = p_cursor_y + p_font_height;
   _map_xy(p_window_id, 0, x, y);
   _str new_text = expand_tabs(get_replace_text(replace_string));
   _bbhelp('', p_window_id, x, y, new_text,
           p_font_name,_StrFontSize2PointSizeX10(p_font_size),0,
           _rgb(255,255,255), _rgb(255,0,0),0);
   restore_pos(p);
}

void _killReplaceToolTip()
{
   _bbhelp('C');
}

