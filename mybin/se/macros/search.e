////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50498 $
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
#import "clipbd.e"
#import "context.e"
#import "cua.e"
#import "files.e"
#import "get.e"
#import "guireplace.e"
#import "help.e"
#import "htmltool.e"
#import "ispflc.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "mouse.e"
#import "recmacro.e"
#import "pip.e"
#import "prefix.e"
#import "proctree.e"
#import "searchcb.e"
#import "seek.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tbfind.e"
#import "util.e"
#import "vi.e"
#import "se/search/SearchResults.e"
#endregion

enum VSSearchFlags {
   VSSEARCHFLAG_IGNORECASE          = 0x1,
   VSSEARCHFLAG_MARK                = 0x2,
   VSSEARCHFLAG_POSITIONONLASTCHAR  = 0x4,
   VSSEARCHFLAG_REVERSE             = 0x8,
   VSSEARCHFLAG_RE                  = 0x10,
   VSSEARCHFLAG_WORD                = 0x20,
   VSSEARCHFLAG_UNIXRE              = 0x40,
   VSSEARCHFLAG_NO_MESSAGE          = 0x80,
   VSSEARCHFLAG_GO                  = 0x100,
   VSSEARCHFLAG_INCREMENTAL         = 0x200,
   VSSEARCHFLAG_WRAP                = 0x400,
   VSSEARCHFLAG_HIDDEN_TEXT         = 0x800,
   VSSEARCHFLAG_SCROLL_STYLE        = 0x1000,
   VSSEARCHFLAG_BINARYDBCS          = 0x2000,
   VSSEARCHFLAG_BRIEFRE             = 0x4000,
   VSSEARCHFLAG_PRESERVE_CASE       = 0x8000,
   VSSEARCHFLAG_WORDPREFIX          = 0x10000,
   VSSEARCHFLAG_WORDSUFFIX          = 0x20000,
   VSSEARCHFLAG_WORDSTRICT          = 0x40000,
   VSSEARCHFLAG_HIDDEN_TEXT_ONLY    = 0x80000,
   VSSEARCHFLAG_NOSAVE_TEXT         = 0x100000,
   VSSEARCHFLAG_NOSAVE_TEXT_ONLY    = 0x200000,
   VSSEARCHFLAG_PROMPT_WRAP         = 0x400000,
   VSSEARCHFLAG_FINDHILIGHT         = 0x800000,
   VSSEARCHFLAG_REPLACEHILIGHT      = 0x1000000,
   VSSEARCHFLAG_WILDCARDRE          = 0x2000000,
   VSSEARCHFLAG_PERLRE              = 0x4000000
};

typeless old_search_reserved;
int old_search_flags;
int old_search_flags2;
int old_go=0;
int gisearch_pos2=0;

_str old_search_string='';
_str old_word_re='';
_str old_replace_string='';
boolean old_search_within_selection=false;
_str old_search_mark='';
_str old_search_message='';
int old_search_range=VSSEARCHRANGE_CURRENT_BUFFER;

_str _key;
static int _search_flags;
static boolean _allow_searching;
static boolean _first_change_dir;
static int gIncSearchMarker;

int def_search_incremental_highlight = 0;

#define DEFAULT_SEARCH_OPTIONS_MASK (VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE|VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_WORD|VSSEARCHFLAG_REVERSE|VSSEARCHFLAG_HIDDEN_TEXT|VSSEARCHFLAG_POSITIONONLASTCHAR)

definit()
{
   old_search_reserved = null;
   old_search_string = '';
   old_replace_string = '';
   old_word_re='[A-Za-z0-9_$]';
   old_search_flags = _default_option('s') & (DEFAULT_SEARCH_OPTIONS_MASK|VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP);
   old_search_mark = '';
   old_search_message = '';
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
   gIncSearchMarker = -1;
}

_str _search_default_options()
{
   int flags = _default_option('s');
   _str options = '';
   if (flags & VSSEARCHFLAG_RE) {
      options = options:+'r';
   }
   if (flags & VSSEARCHFLAG_UNIXRE) {
      options = options:+'u';
   }
   if (flags & VSSEARCHFLAG_BRIEFRE) {
      options = options:+'b';
   }
   if (flags & VSSEARCHFLAG_PERLRE) {
      options = options:+'l';
   }
   if (flags & VSSEARCHFLAG_WILDCARDRE) {
      options = options:+'&';
   }
   if (flags & VSSEARCHFLAG_IGNORECASE) {
      options = options:+'i';
   }
   if (flags & VSSEARCHFLAG_WORD) {
      options = options:+'w';
   }
   if (flags & VSSEARCHFLAG_WRAP) {
      if (flags & VSSEARCHFLAG_PROMPT_WRAP) {
         options = options:+'p?';
      } else {
         options = options:+'p';
      }
   }
   if (flags & VSSEARCHFLAG_REVERSE) {
      options = options:+'-';
   }
   if (flags & VSSEARCHFLAG_POSITIONONLASTCHAR) {
      options = options:+'>';
   }
   if (flags & VSSEARCHFLAG_HIDDEN_TEXT) {
      options = options:+'h';
   }
   return(options);
}

_str make_search_options(int search_flags,boolean ignoreDirection=false)
{
   _str search_options;
   if ( search_flags & VSSEARCHFLAG_REVERSE ) {
      search_options='-';
   } else {
      search_options='+';
   }
   if ( ignoreDirection ) {
      search_options=substr(search_options,2);
   }
   if ( search_flags & VSSEARCHFLAG_POSITIONONLASTCHAR ) {
      search_options=search_options'>';
   }
   if ( search_flags & VSSEARCHFLAG_RE ) {
      search_options=search_options'R';
   } else if( search_flags & VSSEARCHFLAG_UNIXRE ) {
      search_options=search_options'U';
   } else if( search_flags & VSSEARCHFLAG_BRIEFRE ) {
      search_options=search_options'B';
   } else if( search_flags & VSSEARCHFLAG_PERLRE ) {
      search_options=search_options'L';
   } else if ( search_flags & VSSEARCHFLAG_WILDCARDRE) {
      search_options=search_options'&';
   } else {
      search_options=search_options'N';
   }
   if ( search_flags & VSSEARCHFLAG_IGNORECASE ) {
      search_options=search_options'I';
   } else {
      search_options=search_options'E';
   }
   if ( search_flags & VSSEARCHFLAG_MARK ) {
      search_options=search_options'M';
   }
   if ( search_flags & VSSEARCHFLAG_WORD ) {
      search_options=search_options'W';
   }
   if ( search_flags & VSSEARCHFLAG_WRAP ) {
      if (search_flags & VSSEARCHFLAG_PROMPT_WRAP) {
         search_options=search_options'p?';
      } else {
         search_options=search_options'P';
      }
   }
   if (search_flags & VSSEARCHFLAG_HIDDEN_TEXT) {
      search_options = search_options'H';
   }
   if (search_flags & VSSEARCHFLAG_FINDHILIGHT) {
      search_options = search_options'#';
      if (search_flags & VSSEARCHFLAG_GO) {
         search_options = search_options'*';
      }
   }
   return(search_options);
}

typeless make_search_prompt(typeless search_flags,_str orig_prompt)
{
   if (def_keys=='brief-keys') {
      return(brief_make_search_prompt(search_flags,orig_prompt));
   }
   if ( search_flags=='' ) {
      return(orig_prompt);
   }
   _str prompt='';
   if ( search_flags & VSSEARCHFLAG_REVERSE ) {
      prompt=prompt:+nls('Rev')' ';
   }
   if ( ! (search_flags & VSSEARCHFLAG_IGNORECASE) ) {
      prompt=prompt:+nls('Exact')' ';
   }
   if ( search_flags & VSSEARCHFLAG_WORD ) {
      prompt=prompt:+nls('Word')' ';
   }
   if ( search_flags & VSSEARCHFLAG_MARK ) {  // Search with selection
      prompt=prompt:+nls('Selection')' ';
   }
   if ( search_flags & VSSEARCHFLAG_HIDDEN_TEXT ) {  // Search with selection
      prompt=prompt:+nls('Hidden')' ';
   }
   if ( search_flags & VSSEARCHFLAG_FINDHILIGHT ) {  // Search with selection
      prompt=prompt:+nls('Highlight')' ';
      if (search_flags & VSSEARCHFLAG_GO ) {
         prompt=prompt:+nls('All')' ';
      }
   }
   if ( search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE) ) {
      prompt=prompt:+nls('R-E')' ';
   }
   _str suffix='';
   if ( search_flags & VSSEARCHFLAG_INCREMENTAL ) {
      suffix='I-';
   }
   return(prompt:+suffix:+orig_prompt);

}

static _str brief_make_search_prompt(int search_flags,_str orig_prompt)
{
   if ( search_flags=='' ) {
      return(nls('Replacement:')' ');
   }
   _str prompt='';
   if ( ! (search_flags & VSSEARCHFLAG_IGNORECASE) ) {
      prompt=prompt:+nls('Exact')' ';
   }
   if ( search_flags & VSSEARCHFLAG_WORD ) {
      prompt=prompt:+nls('Word')' ';
   }
   if ( search_flags & VSSEARCHFLAG_MARK ) {
      prompt=prompt:+nls('Mark')' ';
   }
   _str search_msg=nls('Search:');
   _str suffix='';
   if ( search_flags & VSSEARCHFLAG_INCREMENTAL ) {
      suffix='I-';
   }
   _str direction='';
   if ( search_flags & VSSEARCHFLAG_REVERSE ) {
      direction=nls('Rev')' ';
   }
   _str p, p2;
   if ( ! (search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE)) ) {
      if ( orig_prompt==search_msg ) {
         p=nls('Search (RE off) for:')' ';
      } else {
         p=nls('Pattern (RE off) for:')' ';
      }
      p2=' 'nls('(RE off)');
   } else {
      if ( orig_prompt==search_msg ) {
         p=nls('Search for:')' ';
      } else {
         p=nls('Pattern for:')' ';
      }
      p2='';
   }
   if ( orig_prompt==nls('Replace string:') || orig_prompt==search_msg ) {
      return(strip(prompt:+direction' ':+suffix:+p,'L'));
   }
   return(strip(prompt:+direction:+p2' 'orig_prompt,'L'));

}

/**
 * Toggle current search flags on or off
 * @param on_flags flags to enable, 0 for no change
 * @param off_flags flags to disable, 0 for no change
 *
 */
void toggle_search_flags(int on_flags, int off_flags)
{
   typeless s1, s2, s3, s4;
   int search_flags;
   save_search(s1, search_flags, s2, s3, s4);
   search_flags |= on_flags;
   search_flags &= ~off_flags;
   restore_search(s1, search_flags, s2, s3, s4);

   old_search_flags |= on_flags;
   old_search_flags &= ~off_flags;
}

/**
 * Confirm that the given search flags permit us to wrap the
 * @param search_flags
 * @param wrap_mark
 * @param search_str
 * @param search_options
 *
 * @return boolean
 */
boolean confirm_wrap(int search_flags,
                     _str search_str=null, _str search_options=null,
                     _str wrap_mark=null, _str old_mark=null,
                     boolean doPrevious=false, boolean refresh_buffer=true)
{
   boolean reverse_search = (((search_flags & VSSEARCHFLAG_REVERSE) != 0) != doPrevious);
   boolean mark_search = (search_flags & VSSEARCHFLAG_MARK) != 0;
   _str mark_id = '';
   if (mark_search) {
      if (wrap_mark == null && !_isnull_selection(old_search_mark)) {
         mark_id = old_search_mark;
      } else if (!_isnull_selection(wrap_mark)) {
         mark_id = wrap_mark;
      }
      if (mark_id == '' || _isnull_selection(mark_id)) {
         mark_search = false;
      }
   }
   _str range_name = (mark_search) ? "selection" : "file";
   // wrap search turned off?
   if (!(search_flags & VSSEARCHFLAG_WRAP)) {
      if (reverse_search) {
         message(nls("Beginning of ":+range_name:+" reached"));
      } else {
         message(nls("End of ":+range_name:+" reached"));
      }
      return false;
   }

   // get top/bottom message

   // wrap search is on, but prompt is off
   if (!(search_flags & VSSEARCHFLAG_PROMPT_WRAP)) {
      if (reverse_search) {
         message(nls("Past the beginning of ":+range_name));
      } else {
         message(nls("Past the end of ":+range_name));
      }
      return true;
   }

   // before prompting them to wrap, check if there are matches
   typeless p; save_pos(p);
   long orig_offset=_QROffset();
   if (wrap_mark!=null) { // wrap within selection
      if (reverse_search) {
         _end_select(wrap_mark);
      } else {
         _begin_select(wrap_mark);
      }
      _str temp = wrap_mark;
      wrap_mark = old_mark; old_mark = temp;
      _show_selection(old_mark);
   } else {               // wrap within buffer
      if (reverse_search) {
         bottom();
      } else {
         top();
      }
   }

   // now search
   int status;
   if (search_str!=null) {
      status=search(search_str,search_options);
   } else {
      status=repeat_search();
   }
   // If we went back to right where we were, then don't prompt to wrap
   if (!status && _QROffset()==orig_offset) {
      status=STRING_NOT_FOUND_RC;
   }
   restore_pos(p);
   if (status) {
      return false;
   }
   // prompt, return true if they say 'yes'
   _str msg;
   if (reverse_search) {
      msg=nls("Beginning of ":+range_name:+" reached.  Continue searching at the end?");
   } else {
      msg=nls("End of ":+range_name:+" reached.  Continue searching at the beginning?");
   }
   clear_message();
   if ( refresh_buffer ) {
      refresh();
   }
   status = _message_box(msg,'',MB_YESNOCANCEL);
   p_window_id._set_focus();
   if (status == IDYES) {
      return true;
   }
   // they said 'no' or cancelled, don't wrap
   return false;
}

/**
 * Starts a reverse incremental search.  Searching takes place as
 * characters are typed.  Press Ctrl+Break to terminate a long search.  The
 * following keys take on a different definition during an incremental
 * search:
 *
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for the next occurrence of the
 * search string.</dd>
 *
 * <dt>Ctrl+S</dt><dd>Searches forward for the next occurrence of the
 * search string.</dd>
 *
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * See section <b>Regular Expressions</b> for
 * information on regular expressions.  The key bound
 * to the BRIEF emulation command
 * <b>re_toggle</b> will also toggle regular
 * expression pattern matching.</dd>
 *
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.  The default word
 * characters are "A-Za-z0-9_$".</dd>
 *
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * BRIEF emulation command <b>case_toggle</b>
 * will also toggle the case sensitivity.</dd>
 *
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 *
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * </dl>
 * @see i_search
 * @see gui_find
 * @see find
 * @see replace
 * @see gui_replace
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command void reverse_i_search() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   qsearch('-'_search_default_options(),'1');
}

/**
 * Starts an incremental search.  Searching takes place as characters are typed.  A long
 * search may be stopped by pressing Ctrl+Break.  The following keys take on a different
 * definition during an incremental search:
 *
 * <DL compact style="margin-left:10pt">
 * <DT>Ctrl+R</DT><DD>Searches in reverse for the next occurrence of the search string</DD>
 * <DT>Ctrl+S</DT><DD>Searches forward for the next occurrence of the search string.</DD>
 * <DT>Ctrl+T</DT><DD>Toggles regular expression pattern matching on/off.  See section Regular Expressions for information on regular expressions.  The key bound to the BRIEF emulation command re_toggle will also toggle regular expression pattern matching.</DD>
 * <DT>Ctrl+W</DT><DD>Toggles word searching on/off.  </DD>
 * <DT>Ctrl+C</DT><DD>Toggles case sensitivity.  The key bound to the BRIEF emulation command case_toggle will also toggle the case sensitivity.</DD>
 * <DT>Ctrl+M</DT><DD>Toggles searching within mark.</DD>
 * <DT>Ctrl+O</DT><DD>Toggles incremental search mode.</DD>
 * <DT>Ctrl+Q</DT><DD>Quotes the next character typed.</DD>
 *
 * </DL>
 *
 * @see reverse_i_search
 * @see gui_find
 * @see find
 * @see replace
 * @see gui_replace
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 */
_command void i_search() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   qsearch('>'_search_default_options(),'1');
   _menu_add_searchhist(old_search_string,old_search_flags,1);
}

/**
 * Prompts for a string to search for.  The <i>options</i> are the same as
 * those supported by the find command and are displayed in a more
 * English-like form in the message prompt.  Unlike the find command,
 * this function does not use any default options not specified by the
 * <i>options </i>parameter and always prompts for the search string
 * argument so that no delimiters are required.  The <i>options
 * </i>argument is a string of one or more of the following:
 *
 * <dl>
 * <dt>E</dt><dd>Exact case.</dd>
 * <dt>I</dt><dd>Ignore case.</dd>
 * <dt>-</dt><dd>Reverse search.</dd>
 * <dt>M</dt><dd>Limit search to marked area.</dd>
 * <dt><</dt><dd>If found, place cursor at beginning of word.</dd>
 * <dt>></dt><dd>If found, place cursor at end of word.</dd>
 * <dt>R</dt><dd>Interpret string as a SlickEdit regular expression.
 * See section SlickEdit Regular Expressions for
 * syntax of regular expression.</dd>
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 * section UNIX Regular Expressions.</dd>
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 * section Brief Regular Expressions.</dd>
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 * <dt>N</dt><dd>Do not interpret search string as a regular search
 * string.</dd>
 * <dt>P</dt><dd>Wrap to beginning/end when string not found.</dd>
 * <dt>W</dt><dd>Limits search to words.  Used to search for
 * variables.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 *    Specifies the valid characters in a word.  The
 * default value is [A-Za-z0-9_$].</dd>
 *
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 * searching for "pre" matches "pre" and "prefix" but
 * not "supreme" or "supre".</dd>
 *
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 * searching for "pre" matches "prefix" but not "pre",
 * "supreme" or "supre".</dd>
 *
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 * searching for "fix" matches "fix" and "sufix" but
 * not "fixit".</dd>
 *
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 * searching for "fix" matches "sufix" but not "fix" or
 * "fixit".</dd>
 *
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 *
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 *
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified.
 * For example, "XCS" requires that the first character
 * not be in a comment or string. <i>CCLetters</i> is
 * a string of one or more of the following color
 * coding element letters:</dd>
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
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to
 * be one of the color coding elements specified. See
 * <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * <p>While you enter the <i>string</i> parameter the following keys take
 * on a new meaning:</p>
 *
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for the next occurrence of the
 * search string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for the next occurrence of the
 * search string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * See section Regular Expressions for information
 * on regular expressions.  The key bound to the
 * BRIEF emulation command <b>re_toggle</b> will
 * also toggle regular expression pattern matching.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * BRIEF emulation command <b>case_toggle</b>
 * will also toggle the case sensitivity.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * </dl>
 *
 * <p>A non-null value for <i>incremental</i> argument may be specified if
 * you want searching to take place as the search string is entered.</p>
 *
 * @return Returns 0 if the search string specified is found.  Common return
 * codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC, and
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 * displayed.
 *
 * @see qreplace
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
_str qsearch(_str options, _str incremental="")
{
   // IF this editor control is not and MDI child AND
   //    we don't have a command line
   if ((!p_mdi_child || incremental=="") && !_default_option(VSOPTION_HAVECMDLINE)) {
      int status = gui_find(options);
      return(status);
   }
   _mffindNoMore(1);
   _mfrefNoMore(1);
   // Set the word characters
   restore_search(old_search_string,0,'['p_word_chars']',null);
   search('','xv,'options);
   old_search_bounds=null;
   old_search_within_selection=false;
   p_LCHasCursor=0;
   _str junk;
   int flags;
   // translate the flags to word_re
   save_search(junk,flags,old_word_re);
   if ( incremental!="" ) {
      flags=flags|VSSEARCHFLAG_INCREMENTAL;
   }
   if ( ! init_search(init_search_flags(flags)) && old_search_string:!='' ) {
      /* User turned off incremental searching and entered search string */
      _macro('m',_macro('s'));
      return(l(old_search_string,make_search_options(old_search_flags)));
   }
   return(1);
}

static _str last_i_search(_str search_string,int search_flags)
{
   int status;
   if ( search_flags & VSSEARCHFLAG_REVERSE ) {
      restore_search(search_string,search_flags,'['p_word_chars']');
      status = repeat_search();
   } else {
      status = search(search_string,'xv,'make_search_options(search_flags));
   }
   if ( status == STRING_NOT_FOUND_RC ) {
      if ( search_flags & WRAP_SEARCH ) {
         typeless p; save_pos(p);
         if ( search_flags & VSSEARCHFLAG_REVERSE ) {
            bottom();
         } else {
            top();up();
         }
         status = repeat_search();
         if (status) {
            restore_pos(p);
         }
      }
   }
   if (!status) {
      set_find_next_msg("Find", search_string, make_search_options(search_flags), old_search_range);
   }
   if (search_flags & VSSEARCHFLAG_INCREMENTAL) {
      _isearch_highlight_window(search_string, make_search_options(search_flags), !status);
   }
   return(status);
}

static void init_isearch(_str search_string, _str search_options, int search_flags, var notfound,
                         var invalid_re, var start_point, var wrap_search)
{
   if ( length(search_string)==0 ) {
      _isearch_clear_markers();
      invalid_re=0;notfound=0;
      return;
   }
   _str prev_select_type = '';
   if (select_active() && pos('M', upcase(search_options)) && (_cursor_move_deselects() || _cursor_move_extendssel()) && (_select_type('', 'S') == 'C')) {
      prev_select_type = 'C';
      _select_type('', 'S', 'E');
   }
   _str old_point=point();
   int old_col=p_col;
   wrap_search='';
   if ( start_point!='' ) {
      int left_edge = p_left_edge;
      int cursor_y = p_cursor_y;
      goto_point(start_point);
      if ( old_point==point() && p_col>=left_edge+1 ) {
         set_scroll_pos(left_edge,cursor_y);
      }
   }
   if (!_default_option(VSOPTION_HAVECMDLINE)) {
      search_options='@'search_options;
   }
   int status=search(search_string,'xv,'search_options);
   if ( status==INVALID_REGULAR_EXPRESSION_RC ) {
      invalid_re=1;
      notfound=0;
   } else {
      invalid_re=0;
      if ( status ) {
         if (search_flags & VSSEARCHFLAG_WRAP) {
            if (search_flags & VSSEARCHFLAG_REVERSE) {
               if (search_flags & VSSEARCHFLAG_MARK) {
                  _end_select(); _end_line();
               } else {
                  bottom();
               }
            } else {
               if (search_flags & VSSEARCHFLAG_MARK) {
                  _begin_select(); _begin_line();
               } else {
                  top();
               }
            }
            status = search(search_string,'xv,'search_options);
            if (!status) {
               wrap_search = 1;
            }
         }
      }
      if (search_flags & VSSEARCHFLAG_WORD) {
         notfound=0;
      } else {
         notfound=status;
      }
   }
   if ( status ) {
      goto_point(old_point);
      p_col = old_col;
      _beep();
   } else {
      if (_default_option(VSOPTION_HAVECMDLINE)) {
         clear_message();
      }
      start_point = match_length('s');
      _MaybeUnhideLine();
      set_find_next_msg("Find", search_string, search_options, old_search_range);
   }
   if (prev_select_type != '') {
      _select_type('', 'S', prev_select_type);
   }
   _isearch_highlight_window(search_string, search_options, !status);
   return;
}

static void _end_incremental_search()
{
   _isearch_clear_markers();
}

/**
 * <blockquote><b>Ctrl+Shift+G</b> or <b>"Search", "Previous Occurrence"</b></blockquote>
 *
 * <p>Repeats a search initiated by a search command in the opposite direction.
 *
 * @return Returns 0 if successful.  Otherwise STRING_NOT_FOUND_RC is returned.  On error, message is displayed.
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_prev
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int find_prev() name_info(','VSARG2_EDITORCTL)
{
   return(find_next(true));
}

/*
    This OnUpdate code only supports MDI menu bar, pop-up editor
    control menus, and MDI Toolbars.
*/
int _OnUpdate_find_next(CMDUI &cmdui,int target_wid,_str command)
{
   // IF there are no MDI children OR
   //    MDI child is not an editor control (future possibility)
   if (_mffindActive(1)) {
      int state=MF_ENABLED;
      return(state);
   }
   if (_mfrefActive(1)) {
      int state=MF_ENABLED;
      return(state);
   }
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   return(length(old_search_string)?MF_ENABLED:MF_GRAYED);
}

int _OnUpdate_find_prev(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_find_next(cmdui,target_wid,command));
}

/**
 * <blockquote><b>Ctrl+G</b> or <b>"Search", "Next Occurrence"</b></blockquote>
 *
 * <p>Repeats a search initiated by a search command in same direction and with the same search options.
 *
 * @param doPrevious  If true, repeats search in the opposite direction.
 *
 * @return Returns 0 if successful.  Otherwise STRING_NOT_FOUND_RC is returned.  On error, message is displayed.
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_prev
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int find_next(boolean doPrevious=false) name_info(','VSARG2_EDITORCTL)
{
   int status;
   if (!p_active_form.p_modal) {
      if(_mffindActive(1)) {
         if (doPrevious) {
            status=_mffindPrev();
         } else {
            status=_mffindNext();
         }
         if (status==NO_MORE_FILES_RC) {
            message("No more occurrences");
            _beep();
         } else if(status){
            _beep();
         } else {
             message(old_search_message);
         }
         return(status);
      }
      if (_mfrefActive(1)) {
         if (doPrevious) {
            status=prev_ref(false,true);
         } else {
            status=next_ref(false,true);
         }
         if (status==NO_MORE_FILES_RC) {
            message("No more occurrences");
            _beep();
         } else if(status){
            _beep();
         } else {
            message(old_search_message);
         }
         return(status);
      }
   }
   if (_no_child_windows() && p_object!=OI_EDITOR) {
      _beep();
      return(0);
   }
   _str markid='';
   _str orig_markid='';
   boolean doAll;
   if (old_search_bounds!=null) {
      if(_InitSearchBounds(old_search_bounds,
                           markid,
                           orig_markid,
                           doAll
                           )) {
         return(1);
      }
   }
   _ExitScroll();

   if (doPrevious) {
      restore_search(old_search_string,
                     (old_search_flags^VSSEARCHFLAG_REVERSE) & ~(VSSEARCHFLAG_NO_MESSAGE),
                     old_word_re,old_search_reserved,old_search_flags2);
   } else {
      restore_search(old_search_string,old_search_flags & ~(VSSEARCHFLAG_NO_MESSAGE),old_word_re,old_search_reserved,old_search_flags2);
   }

   _update_old_search_mark();
   maybe_deselect();

   int prev_mark = _duplicate_selection('');
   boolean show_mark = ((old_search_bounds == null) && (!old_search_within_selection) && (old_search_flags & VSSEARCHFLAG_MARK));
   if (show_mark) {
      if (_update_find_next_mark(old_search_mark)) {
         _show_selection(old_search_mark);
      } else {
         show_mark = false;
      }
   }

   if (old_search_message :== '') { // restore old search message
      set_find_next_msg("Find", old_search_string, old_search_flags, old_search_range);
   }

   typeless p = point();
   int col = p_col;
   status=repeat_search();
   // Note: The condition below can only be true for regular expressions
   // when searching in reverse.
   //  For example:  "m\ce" when the cursor is on the 'e' of the word message.
   if ( ! status && p==point() && col==p_col ) { /* In same place? */
      status=repeat_search();
   }
   if (markid!='') {
      _show_selection(orig_markid);
      _free_selection(markid);
   }
   if (status && status != INVALID_REGULAR_EXPRESSION_RC && confirm_wrap(old_search_flags,null,null,null,null,doPrevious,true)) {
      //clear_message();
      if (doPrevious) {
         restore_search(old_search_string,
                        (old_search_flags^VSSEARCHFLAG_REVERSE) & ~(VSSEARCHFLAG_NO_MESSAGE),
                        old_word_re,old_search_reserved,old_search_flags2);
      } else {
         restore_search(old_search_string,old_search_flags & ~(VSSEARCHFLAG_NO_MESSAGE),old_word_re,old_search_reserved,old_search_flags2);
      }
      save_pos(p);
      boolean reverse_search = ((old_search_flags & VSSEARCHFLAG_REVERSE) != 0);
      if (reverse_search != doPrevious) {
         bottom();
      } else {
         top();up();
      }
      status = repeat_search();
      if (status) {
         // There are no occurrences of this string in this file
         restore_pos(p);
      }
   }
   if (show_mark) {
      _show_selection(prev_mark);
   }
   if (!status){
      _str selection_markid=_alloc_selection();
      _MaybeUnhideLine(selection_markid);
      p_LCHasCursor=0;
      if ((!select_active() || !(old_search_within_selection) ) /*&& def_persistent_select=='D'*/ && def_leave_selected){
        _str amarkid = _duplicate_selection('');
        _show_selection(selection_markid);
        _free_selection(amarkid);

        //_deselect();
       //_select_match();
      /*} else if (def_keys=='brief-keys' && !select_active() && def_persistent_select!='Y' &&
         !def_leave_selected) {
         _deselect();
         brief_select_match(selection_markid);*/
      } else {
         _free_selection(selection_markid);
      }
      typeless junk;
      save_search(junk, junk, junk, old_search_reserved, junk); // save last pos and offset info
      message(old_search_message);
   }
   return(status);

}

/**
 * <p>Repositions the cursor on the item currently selected in the
 * search or references tool window.  If neither window is active, it
 * will do a find-prev, followed by a find-next to attempt to reposition
 * on the current match.
 *
 * @param doPrevious  If true, repeats search in the oposite direction.
 *
 * @return Returns 0 if successful.
 *         Otherwise STRING_NOT_FOUND_RC is returned.
 *         On error, message is displayed.
 *
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_prev
 * @see find_next
 * @see next_ref
 * @see prev_ref
 *
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int find_current() name_info(','VSARG2_EDITORCTL)
{
   int status;
   if (!p_active_form.p_modal) {
      if(_mffindActive(1)) {
         return _mffindCurrent();
      }
      if (_mfrefActive(1)) {
         return current_ref(false,true);
      }
   }
   if (_no_child_windows() && p_object!=OI_EDITOR) {
      _beep();
      return(0);
   }

   // disable wrapping
   int orig_wrap = old_search_flags & WRAP_SEARCH;
   old_search_flags &= ~WRAP_SEARCH;
   status = find_prev();
   if (!status) {
      old_search_flags |= orig_wrap;
      return status;
   }
   status = find_next();
   old_search_flags |= orig_wrap;
   return status;
}

/**
 * @return  Returns <b>true</b> if moving the cursor will extent the active
 * selection.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
boolean _cursor_move_extendssel()
{
   return(select_active() &&  _select_type('','S')=='C');
}

/**
 * @return  Returns <b>true</b> if moving the cursor will remove
 * the active selection.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
boolean _cursor_move_deselects()
{
   return(select_active() && def_persistent_select!='Y' && _select_type('','U')=='');

#if 0
   if (select_active()=='' || def_persistent_select=='Y' ||
      ( _select_type('','U')=='P' && _select_type('','S')=='E') ) {
      return(0);
   }
   return( _select_type('','u')=='' );
    //_select_type('','S')=='C'
#endif

}
void _LCGetBounds(int &start_col,int &end_col)
{
   if (p_BoundsStart<=0) {
      start_col=0;end_col=0;
      return;
   }
   start_col=p_BoundsStart;
   end_col=p_BoundsEnd;
}
/**
 * Searchs for line command label
 *
 * @param label  Label name with leading dot.
 * @return If successful, line number of label is returned.  -1 is returned if the
 *         label is not found.  -2 is returned if the label is defined more than once.
 */
int _LCFindLabel(_str label,boolean displayError=true,boolean duplicatesAllowed=false)
{
   int i;
   label=upcase(label);
   switch (label) {
   case '.ZL':
   case '.ZLAST':
      return(p_Noflines);
   case '.ZF':
   case '.ZFIRST':
      return(0);
   case '.ZC':
   case '.ZCSR':
      return(p_line);
   }
   int LineNumber=-1;
   for (i=0;;++i) {
      if (i>=_LCQNofLineCommands()) {
         if (displayError && LineNumber<0) {
            clear_message();
            _message_box(nls('Label %s not found',label));
         }
         return(LineNumber);
      }
      _str data=upcase(_LCQDataAtIndex(i));
      if (data==label) {
         if (LineNumber>=0) {
            if (displayError) {
               clear_message();
               _message_box(nls('Label %s defined more than once',label));
            }
            return(-2);
         }
         LineNumber=_LCQLineNumberAtIndex(i);
         if (duplicatesAllowed) {
            return(LineNumber);
         }
      }
   }
}
int _InitSearchBounds(VSSEARCH_BOUNDS vssearch_bounds,_str &markid,_str &orig_markid,boolean &doAll)
{
   orig_markid=_duplicate_selection('');
   markid='';
   doAll=false;
   // Error check first
   int start_linenum= -1,end_linenum= -1;
   int startCol= -1; int endCol=-1;
   if(vssearch_bounds.startLabel!='') {
      start_linenum=_LCFindLabel(vssearch_bounds.startLabel);
      if (start_linenum<0) {
         return(1);
      }
      if (start_linenum==0) start_linenum=1;
      if(vssearch_bounds.endLabel!='') {
         end_linenum=_LCFindLabel(vssearch_bounds.endLabel);
         if (end_linenum<0) {
            return(1);
         }
         if (end_linenum==0) end_linenum=1;

         if (start_linenum>end_linenum){
            int temp=end_linenum;
            end_linenum=start_linenum;
            start_linenum=temp;
         }
      } else {
         end_linenum=start_linenum;
      }
      doAll=true;
   }
   if (vssearch_bounds.startCol>0) {
      startCol=vssearch_bounds.startCol;
      if (vssearch_bounds.endCol>0) {
         endCol=vssearch_bounds.endCol;
      } else {
         endCol=startCol;
      }
      if (start_linenum<0) {
         start_linenum=1;
         end_linenum=p_Noflines;
      }
   } else {
      _LCGetBounds(startCol,endCol);
      if (startCol>0) {
         start_linenum=1;
         end_linenum=p_Noflines;
      }
   }
   if (start_linenum>=0) {

      markid=_alloc_selection();
      typeless p; save_pos(p);

      p_line=start_linenum;
      if (p_line!=start_linenum) {
         _free_selection(markid);
         markid='';
      } else {
         if (startCol>0) {
            p_col=startCol;
            _select_block(markid);
         } else {
            _select_line(markid);
         }
         p_line=end_linenum;
         if (endCol>0) {
            p_col=endCol;
            _select_block(markid,'PE');
         } else {
            _select_line(markid,'PE');
         }
         _show_selection(markid);
      }
      restore_pos(p);
   }
   if (vssearch_bounds.startCmd=='ALL' ||
       vssearch_bounds.startCmd=='ALLLAST') {
      doAll=true;
   }
   return(0);
}
void _initSearchBounds2(VSSEARCH_BOUNDS vssearch_bounds,
                        boolean doAll,_str markid,_str &fail_pos)
{
   fail_pos=null;
   if (doAll) {
      // Range of labels given
      if (markid!='') {
         if (vssearch_bounds.startCmd=='LAST') {
            save_pos(fail_pos);
            _end_select(markid);_end_line();
            return;
         }
         save_pos(fail_pos);
         _begin_select(markid);p_col=1;
         return;
      }
      if (vssearch_bounds.startCmd=='ALL') {
         save_pos(fail_pos);
         top();
         return;
      }
      // ALLLAST case
      save_pos(fail_pos);
      bottom();
      return;
   }
   if (vssearch_bounds.startCmd=='FIRST') {
      save_pos(fail_pos);
      top();
      return;
   }
   if (vssearch_bounds.startCmd=='LAST') {
      save_pos(fail_pos);
      bottom();
      return;
   }
}

void _MaybeUnhideLine(_str selection_markid='')
{
   if (selection_markid!='') {
      _select_match(selection_markid);
   }
   typeless p;
   int status;
   if (_lineflags()& HIDDEN_LF) {
      // Search up until we hit a nosave line (probably because we are in
      // ISPF emulation or the level changes in which case we should be on
      // a bitmap line.
      int orig_level = _LevelIndex(_lineflags());
      int Noflines = 0;
      _save_pos2(p);
      for (;;) {
         status=up();
         if (_on_line0()) {
            _restore_pos2(p);
            //_lineflags(0,HIDDEN_LF);
            break;
         }
         int flags = _lineflags();
         if (flags & NOSAVE_LF) {
            int previous_Noflines=ispf_is_excluded_line();
            if (previous_Noflines) {
               int ModifyFlags=p_ModifyFlags;
               if (Noflines==0) {
                  _delete_line();
               } else {
                  ispf_insert_exclude(Noflines,true);
               }
               _begin_select(p);
               _lineflags(0,HIDDEN_LF);
               int new_Noflines=previous_Noflines-Noflines-1;
               if (new_Noflines>0) {
                  ispf_insert_exclude(new_Noflines);
                  _lineflags(NOSAVE_LF,NOSAVE_LF);
               }
               _restore_pos2(p);
               p_ModifyFlags=ModifyFlags;
            } else {
               _restore_pos2(p);
               _lineflags(0,HIDDEN_LF);
            }
            break;
         }
         if (_LevelIndex(flags)<orig_level ) {
            _restore_pos2(p);
            break;
         }
         ++Noflines;
      }
   }

   // handle multiline selections - expand level for all lines in selection
   save_pos(p);
   markid := _alloc_selection();
   goto_point(match_length('s')); _select_line(markid);
   goto_point(match_length('s') + match_length('')); _select_line(markid);
   for (;;) {
      if (_on_line0()) {
         _lineflags(0, HIDDEN_LF);
         break;
      }
      if (_lineflags() & HIDDEN_LF) {
         expand_line_level();
      }
      status = up();
      if (status || _begin_select_compare(markid) < 0) break;
   }
   restore_pos(p);
   _free_selection(markid);
}

_command void set_find()  name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _str string='';
   int junk=0;
   if (select_active()) {
      filter_init();
      filter_get_string(string);
      filter_restore_pos();
   } else {
      string=cur_word(junk);
   }
   if (string=='') {
      message('No text to search for');
      return;
   }
   _mffindNoMore(1);
   _mfrefNoMore(1);
   old_search_string=string;

   _str new_search_options=make_search_options(_default_option('s') & DEFAULT_SEARCH_OPTIONS_MASK);
   search('',new_search_options);
   save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
}
static int gFindRecurse;
/**
 * Syntax: <B>/<I>string</I> </B>[ <B>/<I>options</I></B> ] or <B>L /<I>string</I> </B>[ <B>/<I>options</I></B> ] or <B>find /<I>string</I> </B>[ <B>/<I>options</I></B> ]
 * <p>The /, L, or find command searches for the string specified.  Press and hold Ctrl+Alt+Shift to terminate a long search.  Any search or search and replace command may be terminated by pressing and holding Ctrl+Alt+Shift.  If you use the L or find command, the first non blank character is used as the delimiter.
 * <p>In ISPF emulation, this command is not called when invoked from the command line.  Instead ispf_find is called.  Use ("Edit", "Find...") to explicitly invoke the find command.
 * <p>When no parameters are specified, you are prompted for the string parameter.  While you enter the string parameter the following keys take on a new meaning:
 * <DL compact style="margin-left:20pt;">
 *  <DT>Ctrl+R</DT><DD>Searches in reverse for the next occurrence of the search string</DD>
 *  <DT>Ctrl+S</DT><DD>Searches forward for the next occurrence of the search string.</DD>
 *  <DT>Ctrl+T</DT><DD>Toggles regular expression pattern matching on/off.  See section <a href="help:Regular Expressions">Regular Expressions</a> for information on regular expressions.  The key bound to the BRIEF emulation command {@link re_toggle} will also toggle regular expression pattern matching.</DD>
 *  <DT>Ctrl+W</DT><DD>Toggles word searching on/off.  Word searching is useful for search and replacing variables.</DD>
 *  <DT>Ctrl+C</DT><DD>Toggles case sensitivity.  The key bound to the BRIEF emulation command {@link case_toggle} will also toggle the case sensitivity.</DD>
 *  <DT>Ctrl+M</DT><DD>Toggles searching within selection.</DD>
 *  <DT>Ctrl+O</DT><DD>Toggles incremental search mode.</DD>
 *  <DT>Ctrl+Q</DT><DD>Quotes the next character typed.</DD>
 * </DL>
 *
 * @appliesTo Edit_Window, Editor_Control
 * @param string  Input string to search for.
 * @param options
 *                The options argument is a string of one or more of the following:
 *
 *                <DL compact>
 *                <DT>E</DT><DD>Exact case.</DD>
 *                <DT>I</DT><DD>Ignore case.</DD>
 *                <DT>-</DT><DD>Reverse search.</DD>
 *                <DT>M</DT><DD>Limit search to marked area.</DD>
 *                <DT><</DT><DD>If found, place cursor at beginning of word.</DD>
 *                <DT>></DT><DD>If found, place cursor at end of word.</DD>
 *                <DT>R</DT><DD>Interpret string as a regular expression.  See section <a href="help:SlickEdit regular expressions">SlickEdit Regular Expressions</a> for syntax of regular expression.</DD>
 *                <DT>U</DT><DD>Interpret string as a UNIX regular expression.   See section <a href="help:UNIX regular expressions">UNIX Regular Expressions</a>.</DD>
 *                <DT>B</DT><DD>Interpret string as a Brief regular expression.   See section <a href="help:Brief regular expressions">Brief Regular Expressions</a>.</DD>
 *                <DT>L</DT><DD>Interpret string as a Perl regular expression.</DD>
 *                <DT>&</DT><DD>Interpret string as a Wildcard regular expression.</DD>
 *
 *                <DT>H</DT><DD>Search through hidden lines.</DD>
 *                <DT>#</DT><DD>Highlight matched occurrences with highlight color.</DD>
 *                <DT>N</DT><DD>Do not interpret search string as a regular expression.</DD>
 *                <DT>P</DT><DD>Wrap to beginning/end when string not found.</DD>
 *                <DT>W</DT><DD>Limits search to words.  Used to
 *                search for variables. </DD>
 *                <DT>W</DT><DD>SlickEdit-regular-expression Specifies the valid characters in a word.  The default value is [A-Za-z0-9_$].</DD>
 *
 *                <DT>W:P</DT><DD> search to word prefix.  For example, searching for "pre" matches "pre" and "prefix" but not "supreme" or "supre".</DD>
 *                <DT>W:PS</DT><DD>Limits search to strict word prefix.  For example, searching for "pre" matches "prefix" but not "pre", "supreme" or "supre".</DD>
 *                <DT>W:S</DT><DD>Limits search to word suffix.  For example, searching for "fix" matches "fix" and "sufix" but not "fixit".</DD>
 *                <DT>W:SS</DT><DD>Limits search to strict word suffix.  For example, searching for "fix" matches "sufix" but not "fix" or "fixit".</DD>
 *
 *                <DT>Y</DT><DD>Binary search.  This allows start positions in the middle of a DBCS or UTF-8 character.  This option is useful when editing binary files (in SBCS/DBCS mode) which may contain characters which look like DBCS but are not.  For example, if you search for the character 'a', it will not be found as the second character of a DBCS sequence unless this option is specified.</DD>
 *                <DT>,</DT><DD>Delimiter to separate ambiguous options.</DD>
 *                <DT>X<I>CLetters</I>'</DT><DD>Requires the first character of search string NOT be one of the color coding elements specified. For example, "XCS" requires that the first character not be in a comment or string. <i>CCLetters</i> is a string of one or more of the following color coding element letters:</DD>
 *                <DL compact style="margin-left:20pt;">
 *                <DT>O</DT><DD>Other</DD>
 *                <DT>K</DT><DD>Keyword</DD>
 *                <DT>N</DT><DD>Number</DD>
 *                <DT>S</DT><DD>String</DD>
 *                <DT>C</DT><DD>Comment</DD>
 *                <DT>P</DT><DD>Preprocessing</DD>
 *                <DT>L</DT><DD>Line number</DD>
 *                <DT>1</DT><DD>Symbol 1</DD>
 *                <DT>2</DT><DD> Symbol 2</DD>
 *                <DT>3</DT><DD> Symbol 3</DD>
 *                <DT>4</DT><DD> Symbol 4</DD>
 *                <DT>F</DT><DD>Function color</DD>
 *                <DT>V</DT><DD>No save line</DD>
 *                </DL>
 *                <DT>C<i>CCLetters</i><DD>Requires the first character of search string to be one of the color coding elements specified. See <i>CCLetters</i> above.</DD>
 *                </DL>
 *                Default search options may be set by the
 *                {@link help:Search Options} ("Tools > Options
 *                > Editing > Search").
 * @param vssearch_bounds
 *                Specifies ISPF search bounds parameters
 *
 * @return Returns 0 if the search string specified is found.  Common return codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC and INVALID_REGULAR_EXPRESSION_RC.  On error, message is displayed
 * @example Command Line Examples
 * <DL style="margin-left:20pt;">
 * <DT><b>/xyz/-</b></DT><dd>Search for string "xyz" using default search case in reverse.</DD>
 * <DT><b>L /xyz/-</b></DT><DD>Search for string "xyz" using default search case in reverse.  Notice that prefixing the string "/xyz/-" with L has no effect on this command.</DD>
 * <DT><b>L $xyz$-</b></DT><DD>Search for string "xyz" using default search case in reverse.  The L command can change the string delimiter which in this case is not necessary.</DD>
 * <DT><b>L $/$</b></DT><DD>Search forward for the character slash.  The L command has been used so that the string delimiter could be changed to $ which allows searching for the / character.</DD>
 * <DT><b>L $/$-</b></DT><DD>Search backward for the character slash.</DD>
 * <DT><b>/i/w</b></DT><DD>Search for the variable i.</DD>
 * <DT><b>/xyz/e</b></DT><DD>Search for "xyz" in exact case.</DD>
 * </DL>
 *
 * @see i_search
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int find,l,'/'(_str string='',_str options=null,VSSEARCH_BOUNDS vssearch_bounds=null) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (vssearch_bounds!=null && options==null) {
      options='';
   }
   if (!gFindRecurse && !_default_option(VSOPTION_HAVECMDLINE) &&
       options==null && (string=='' || string=='/') ) {
      gFindRecurse=1;
      int status=gui_find();
      gFindRecurse=0;
      return(status);
   }
   gFindRecurse=0;
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']',old_search_reserved,old_search_flags2);
   old_search_flags = (old_search_flags &~(VSSEARCHFLAG_POSITIONONLASTCHAR|VSSEARCHFLAG_INCREMENTAL|VSSEARCHFLAG_NO_MESSAGE));
   _str markid="";
   boolean doAll=false;
   _str fail_pos=null;
   old_search_bounds=null;
   old_search_within_selection=false;
   _str new_search_options;
   _str orig_markid='';
   if ( options!=null ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      new_search_options=options;
      if (vssearch_bounds!=null && !pos('m',new_search_options,1,'i')) {
         //VSSEARCH_BOUNDS vssearch_bounds;
         //vssearch_bounds=arg(3);
         if(_InitSearchBounds(vssearch_bounds,
                              markid,
                              orig_markid,
                              doAll
                              )) {
            return(1);
         }
         if (markid!='') {
            new_search_options=new_search_options:+'m';
         }
         if (vssearch_bounds.startCmd=='PREV' ||
             vssearch_bounds.startCmd=='ALLLAST' ||
             vssearch_bounds.startCmd=='LAST'
             ) {
            new_search_options=new_search_options:+'-';
         }
         _initSearchBounds2(vssearch_bounds,doAll,markid,fail_pos);

         old_search_bounds=vssearch_bounds;
         old_search_bounds.result_doAll=doAll;
         if (markid!='' && _select_type(markid)!='LINE') {
            int junk;
            _get_selinfo(old_search_bounds.result_startCol,
                         old_search_bounds.result_endCol,
                         junk,
                         markid);
         } else {
            old_search_bounds.result_startCol= -1;
            old_search_bounds.result_endCol= -1;
         }
      } else {
         if (old_search_bounds!=null) {
            old_search_bounds.orig_searchString=string;
         }
      }
      old_search_string=string;
   } else if ( string=='' || string=='/' ) {
      if ( ! def_prompt ) {
         command_put('l /');
         return(1);
      }
      if ( init_search(init_search_flags(old_search_flags)) ) {
         return(1);
      }
      new_search_options=make_search_options(old_search_flags);
      old_search_within_selection=pos('M',upcase(new_search_options))!=0;
      old_search_range = old_search_within_selection ? VSSEARCHRANGE_CURRENT_SELECTION : VSSEARCHRANGE_CURRENT_BUFFER;
      if (old_search_bounds!=null) {
         old_search_bounds.orig_searchString=old_search_string;
      }
      if ( pos('#',new_search_options)) {
         clear_highlights();
      }

      pip_log_regex_search(new_search_options);
   } else {
      _str delim;
      _str temp_options;
      parse string with  1 delim +1 old_search_string (delim) temp_options;
      new_search_options=make_search_options(_default_option('s') & (DEFAULT_SEARCH_OPTIONS_MASK | VSSEARCHFLAG_WRAP | VSSEARCHFLAG_PROMPT_WRAP)):+temp_options;
      old_search_within_selection=pos('M',upcase(new_search_options))!=0;
      if (old_search_bounds!=null) {
         old_search_bounds.orig_searchString=old_search_string;
         old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
      } else {
         old_search_range = old_search_within_selection ? VSSEARCHRANGE_CURRENT_SELECTION : VSSEARCHRANGE_CURRENT_BUFFER;
      }
      if ( pos('#',new_search_options)) {
         clear_highlights();
      }

      pip_log_regex_search(new_search_options);
   }
   if (old_search_mark != '') {
      _free_selection(old_search_mark);
      old_search_mark = '';
   }
   _str prev_pos = '';
   _str prev_select_type = '';
   if ( select_active() && pos('M',upcase(new_search_options)) && (_cursor_move_deselects() || _cursor_move_extendssel())) {
      // Lock the selection
      // Lock the selection allows the user to do a find next within the selection.
      // Locking the selection may be annoying to some users.
      // We should ask users what they expect to happen when they search
      // within a selection.

      //select_it(_select_type(),'',_select_type('','I'):+def_advanced_select);
      if( _select_type('','S')=='C' ) {
         prev_select_type = 'C';
         _select_type('','S','E');
         //_select_type('','U','P');
      }
      save_pos(prev_pos);
      if ( pos('-',new_search_options) ) {
         _end_select();_end_line();
      } else {
         _begin_select();_begin_line();
      }
   }
   if (recording_macro) {
      _macro('m',recording_macro);
      _macro_delete_line();
      _macro_call('find',old_search_string,new_search_options);
   }
   mou_hour_glass(1);
   _mffindNoMore(1);
   _mfrefNoMore(1);
   //say('new_search_options='new_search_options);
   //say('old_search_string='old_search_string);
   //messageNwait('got here');
   _Nofchanges=0;
   _str selection_markid=_alloc_selection();
   int status=search(old_search_string,'xv,@'new_search_options);
   if (!status) {
      _MaybeUnhideLine(selection_markid);
      if (doAll) {
         //save_search(a1,a2,a3,a4);
         typeless first_pos;
         save_pos(first_pos);
         ++_Nofchanges;
         for (;;) {
            if (repeat_search()) break;
            _MaybeUnhideLine();
            ++_Nofchanges;
         }
         restore_pos(first_pos);
      }
   }
   //search_flags_str=old_search_flags;//Dan Added here
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;
   if (markid!='') {
      _show_selection(orig_markid);
      _free_selection(markid);
   }
   _str junk;
   int new_flags;
   save_search(junk,new_flags,junk);
   if (status && status != INVALID_REGULAR_EXPRESSION_RC && confirm_wrap(new_flags)) {
      save_pos(auto p);
      if (new_flags & VSSEARCHFLAG_REVERSE) {
         if (new_flags & VSSEARCHFLAG_MARK) {
            _end_select();
         } else {
            bottom();
         }
      } else {
          if (new_flags & VSSEARCHFLAG_MARK) {
            _begin_select();
         } else {
            top();
         }
      }
      status=search(old_search_string,'xv,@'new_search_options);
      if (status) {
         // There are no occurrences of this string in this file
         restore_pos(p);
      } else {
         _MaybeUnhideLine(selection_markid);
      }
   }

   if (!status && pos('*',new_search_options)) {            // mark all
      typeless orig_pos; save_pos(orig_pos);
      top(); up();
      for (;;) {
         if (repeat_search()) break;
         _MaybeUnhideLine();
         ++_Nofchanges;
      }
      restore_pos(orig_pos);
   }

   mou_hour_glass(0);
   if (!status && (pos('M',upcase(new_search_options)))) {
      old_search_mark = _duplicate_selection();
   }
   if (status) {
      set_find_next_msg('');
      _free_selection(selection_markid);
      if (prev_pos != '') {
         restore_pos(prev_pos);
         if (prev_select_type != '') {
            _select_type('','S',prev_select_type);
         }
      }
      if (!pos('@',new_search_options)) {
         message(get_message(status));
      }
   } else {
      set_find_next_msg("Find", old_search_string, new_search_options, old_search_range);
      if (( (!select_active() || !old_search_within_selection) ||
                !pos('M',upcase(new_search_options))) &&
              /*def_persistent_select=='D' && */def_leave_selected) {
      //if (doAll) restore_search(a1,a2,a3,a4);
      int amarkid=_duplicate_selection('');
      _show_selection(selection_markid);
      _free_selection(amarkid);
      //_deselect();
      //_select_match();
   /*} else if (def_keys=='brief-keys' &&
              ( !select_active() || !pos('M',upcase(new_search_options))) &&
              def_persistent_select!='Y' && !def_leave_selected) {
      brief_select_match(selection_markid); */
      } else if (select_active() && !pos('M',upcase(new_search_options)) && _cursor_move_deselects()) {
         _free_selection(selection_markid);
         _deselect();
      } else {
         _free_selection(selection_markid);
      }
   }
   old_search_string=old_search_string;
   save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
   _menu_add_searchhist(old_search_string,new_search_options);
   if (!status) p_LCHasCursor=0;
   if (fail_pos!=null && status) {
      restore_pos(fail_pos);
   }
   return(status);
}
/**
 * Used in BRIEF emulation.  Repeats the last search and replace
 * performed by the <b>translate_forward</b> or
 * <b>translate_backward</b> command.
 *
 * @see replace
 * @see find
 * @see i_search
 * @see reverse_i_search
 * @see search_case
 * @see case_toggle
 * @see re_search
 * @see re_toggle
 * @see search_forward
 * @see translate_forward
 * @see translate_backward
 * @see translate_again
 * @see search_backward
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 *
 */
_command translate_again() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _str mark_option='';
   if ( select_active() ) {
      mark_option='m';
   }
   int status = c(old_search_string,old_replace_string,
            mark_option:+make_search_options(old_search_flags & ~VSSEARCHFLAG_MARK));
   if ( select_active() ) {
      select_it(_select_type(),'','C');
   }
   return(status);
}
/**
 * <p>In ISPF emulation, the <b>replace</b> or <b>c </b>command is not
 * called when invoked from the command line.  Instead
 * <b>ispf_replace</b> or <b>ispf_c</b> (short for
 * <b>ispf_change</b>) command is invoked, respectively.  Use ("Edit",
 * "Replace...") to explicitly invoke the<b> replace</b> or <b>c
 * </b>command.</p>
 *
 * <p>The <b>replace</b> or <b>c</b> command changes occurrences of
 * <i>string1</i> with <i>string2</i>.  If no parameters are specified,
 * you are prompted for the <i>string1</i> and <i>string2</i>
 * parameters.  From a macro, the <i>string1</i>, <i>string2</i>, and
 * <i>options</i> parameters may be passed as separate arguments which
 * do not require any delimiters.  While you enter the <i>string1</i>
 * parameter the following keys take on a new meaning:</p>
 *
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for the next occurrence of the
 * search string.</dd>
 *
 * <dt>Ctrl+S</dt><dd>Searches forward for the next occurrence of the
 * search string.</dd>
 *
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * See section <b>Regular Expressions</b> for
 * information on regular expressions.  The key bound
 * to the BRIEF emulation command
 * <b>re_toggle</b> will also toggle regular
 * expression pattern matching.</dd>
 *
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 *
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * BRIEF emulation command <b>case_toggle</b>
 * will also toggle the case sensitivity.</dd>
 *
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * </dl>
 *
 * <p>The First non blank character is used as the delimiter.  The
 * <i>options</i> argument is a string of one or more of the following:</p>
 *
 * <dl>
 * <dt>E</dt><dd>Exact case.</dd>
 * <dt>I</dt><dd>Ignore case.</dd>
 * <dt>-</dt><dd>Reverse search.</dd>
 * <dt>M</dt><dd>Limit search to marked area.</dd>
 *
 * <dt>V</dt><dd>Preserve case. When specified, each occurrence
 * found is checked for all lower case, all upper case,
 * first word capitalized or mixed case.  The replace
 * string is converted to the same case as the
 * occurrence found excepted when the occurrence
 * found is mixed case (possibly mulltiple capitalized
 * words).  In this case, the replace string is used
 * without modification.</dd>
 *
 * <dt>$</dt><dd>Replaced occurrences are highlighted with modified color.</dd>
 *
 * <dt><</dt><dd>If found, position cursor at beginning of word.</dd>
 * <dt>></dt><dd>If found, position cursor at end of word.</dd>
 * <dt>*</dt><dd>Make changes without prompting.</dd>
 *
 * <dt>R</dt><dd>Interprets <i>string1</i> to be a SlickEdit regular
 * expression.  In addition, the characters \ and # take
 * on new meaning in the replace string.  See
 * <b>SlickEdit Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 * section <b>UNIX Regular Expressions</b>.</dd>
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 * section <b>Brief Regular Expressions</b>.</dd>
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 * <dt>N</dt><dd>Do not interpret search string as a regular search
 * string.</dd>
 * <dt>P</dt><dd>Wrap to beginning/end when string not found.</dd>
 * <dt>W</dt><dd>Limits search to words.  Used to search and replace
 * variable names.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 *    Specifies the valid characters in a word.  The
 * default value is [A-Za-z0-9_$]</dd>
 *
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 * searching for "pre" matches "pre" and "prefix" but
 * not "supreme" or "supre".</dd>
 *
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 * searching for "pre" matches "prefix" but not "pre",
 * "supreme" or "supre".</dd>
 *
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 * searching for "fix" matches "fix" and "sufix" but
 * not "fixit".</dd>
 *
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 * searching for "fix" matches "sufix" but not "fix" or
 * "fixit".</dd>
 *
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 *
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 *
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified.
 * For example, "XCS" requires that the first character
 * not be in a comment or string. <i>CCLetters</i> is
 * a string of one or more of the following color
 * coding element letters:</dd>
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
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to
 * be one of the color coding elements specified. See
 * <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * <p>If the '*' option is not specified, you will be prompted with the
 * message "Yes/No/Last/Go/Quit?" for each occurrence of
 * <i>string1</i>.   Press one of the following keys to take an action:</p>
 *
 * <dl>
 * <dt>'Y' or SPACE</dt><dd>Make change and continue searching.</dd>
 *
 * <dt>'N' or BACKSPACE</dt><dd>
 *    No change and continue searching.</dd>
 *
 * <dt>'L' or .</dt><dd>Make change and stop searching.</dd>
 *
 * <dt>'G' or !</dt><dd>Make change and change the rest without
 * prompting.</dd>
 *
 * <dt>'Q' or ESC</dt><dd>Exits command.  By default, the cursor is NOT
 * restored to its original position.  If you want the
 * cursor restored to its original position, invoke the
 * command "<b>set-var def-restore-cursor 1</b>"
 * and save the configuration.</dd>
 *
 * <dt>Ctrl+G</dt><dd>Exits command and restores cursor to its original
 * position.</dd>
 *
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search
 * string.</dd>
 *
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search
 * string.</dd>
 *
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * The key bound to the BRIEF emulation command
 * <b>re_toggle</b> will also toggle regular
 * expression pattern matching.  See section
 * <b>Regular Expressions</b> for more information.</dd>
 *
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 *
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * BRIEF emulation command <b>case_toggle</b>
 * will also toggle the case sensitivity.</dd>
 *
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 *
 * <dt>F1 or '?'</dt><dd>Displays help on <b>replace</b> command.</dd>
 * </dl>
 *
 * <p>No space character is needed between the 'C' and the '/' delimiter
 * UNLESS you use a delimiter other than '/'.  You may use any character
 * except space as the delimiter.  For example, "c $/$\$" replaces
 * occurrences of forward slashes to back slashes.</p>
 *
 * <p>Command line examples:</p>
 *
 * <dl>
 * <dt><b>c/x/y/m</b></dt><dd>Replace occurrences of x in the marked area
 * with y using default search case sensitivity.</dd>
 *
 * <dt><b>c $x$y$m</b></dt><dd>Replace occurrences of x in the marked area
 * with y using default search case sensitivity.
 * The string delimiter $ has been used requiring
 * a space character after the C.</dd>
 *
 * <dt><b>c/x/y/e*</b></dt><dd>Replace lower case occurrences of x with y
 * without prompting.</dd>
 *
 * <dt><b>c/i/something_more_meaningful/w</b></dt><dd>
 *    Replace occurrences of the variable i with
 * something_more_meaningful</dd>
 *
 * <dt><b>c/i/j/w=[A-Za-z]</b></dt><dd>Replace occurrences of the word i
 * with j and specify valid characters in a word
 * to be alphabetic.</dd>
 *
 * <dt><b>c/{if|while}/x\0y\1/r </b></dt><dd>Replaces occurrences of if and while with
 * xify and xwhiley.  Unmatched groups are
 * null.  Note the \1 is replaced with null.</dd>
 *
 * <dt><b>c $/$\\$r</b></dt><dd>Replace forward slash with backslash.  Two
 * backslashes represent single backslash for
 * regular expression search and replace.</dd>
 * </dl>
 *
 * @return Returns 0 if search string and replace not cancelled.   Common return
 * codes are COMMAND_CANCELLED_RC,
 * STRING_NOT_FOUND_RC, TOO_MANY_SELECTIONS_RC,
 * INVALID_REGULAR_EXPRESSION_RC, and
 * INVALID_OPTION_RC.  On error, message is displayed.  The
 * universal scope variable "_Nofchanges" is set to the number of
 * occurrences changed.
 *
 * @example
 * c/<i>string1</i>/<i>string2</i>[/<i>options</i>] or replace
 * /<i>string1</i>/<i>string2</i>[/<i>options</i>]
 *
 * @see i_search
 * @see reverse_i_search
 * @see gui_replace
 * @see gui_find
 * @see find
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
_command int replace,c(_str string1='',_str string2=null, _str options=null) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!gFindRecurse && !_default_option(VSOPTION_HAVECMDLINE) &&
       string2==null && (string1=='') ) {
      gFindRecurse=1;
      int status = gui_replace();
      gFindRecurse=0;
      return(status);
   }
   if (!p_mdi_child && _executed_from_key_or_cmdline('c')) {
      return(gui_replace());
   }
   _str new_search_options;
   if ( string2!=null) {
      if (options==null) options='';
      old_search_string=string1;old_replace_string=string2;new_search_options=options;
      pip_log_regex_search(new_search_options);
   } else {
      if ( string1=='' ) {
        if ( ! def_prompt ) {
           command_put('c /');
           return(1);
        }
        old_search_flags = (old_search_flags &~(VSSEARCHFLAG_POSITIONONLASTCHAR|VSSEARCHFLAG_INCREMENTAL|VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_FINDHILIGHT));
        if ( init_qreplace(init_search_flags(old_search_flags)) ) {
           return(1);
        }
        new_search_options=old_search_flags;
      } else {
         _str delim, temp_search_flags;
         parse string1 with  1 delim +1 old_search_string (delim) old_replace_string (delim) temp_search_flags;
         new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE)):+temp_search_flags;
      }
   }
   if ( pos('$',new_search_options)) {
      clear_highlights();
   }
   int status=qreplace(old_search_string,old_replace_string,new_search_options);
   return(status);

}
void qreplace_Nofchanges(int status,int Nofchanges)
{
   if ( status<=0 && Nofchanges ) {
      _str prefix_msg='';
      if (status  && status!=STRING_NOT_FOUND_RC) {
         prefix_msg=get_message(status)'.  ';
      }
      _str plural=nls('Replaced %s occurrences',Nofchanges);
      if ( Nofchanges==1 ) {
         plural=nls('Replaced 1 occurrence');
      }
      message(strip(prefix_msg:+' 'plural,'L'));
   }

}

static int _search_ft_toggle_keys(_str key, int _search_flags, int& flag)
{
   flag = 0;
   if (name_on_key(key)=='re-toggle') {
      flag = def_re_search;

   } else if (name_on_key(key)=='case-toggle') {
      flag = VSSEARCHFLAG_IGNORECASE;

   } else {
      if (key == name2event('C_W') && def_keys != 'gnuemacs-keys') {
         flag = VSSEARCHFLAG_WORD;

      } else if (key == name2event('C_S_W') && def_keys == 'gnuemacs-keys') {
         flag = VSSEARCHFLAG_WORD;
         
      } else {
         switch (key) {
         case C_C:
            flag = VSSEARCHFLAG_IGNORECASE;
            break;
         case C_T:
            flag = def_re_search;
            break;
         case C_M:
            flag = VSSEARCHFLAG_MARK;
            break;
         default:
            break;
         }
      }
   }
   return flag;
}

static boolean _search_ft_complete_word(_str key)
{
   if (def_keys=='gnuemacs-keys') {
      if (key == name2event('C_W')) {
         return true;
      }
      return false;
   }
   if (key == name2event('C_S_W')) {
      return true;
   }
   return false;
}

_str _search_ft(_str key,var prompt,_str orig_prompt,var leave_cursor,
                typeless doSearchPrompt='',int editorctl_wid=0 )
{
   static _str notfound;
   static _str invalid_re;
   static _str start_point;
   static _str search_options;
   _str cmd_text, search_string, tmp_prompt;
   _str wrap_search = '';
   if ( !_allow_searching ) {
      prompt=orig_prompt;
      if ( key:==C_S || key:==C_R ) {
         _cmdline.get_command(cmd_text);
         if ( cmd_text:=='' ) {
            cmd_text=old_replace_string;
         }
         command_put(cmd_text);
         return('');
      } else if ( key:=='' ) {
         prompt=make_search_prompt('',orig_prompt);
         return('');
      }
      return 0;
   }
   int flag=0;
   boolean replace_ft = (orig_prompt == nls('Replace string:'));
   int re_search = _search_flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE);
   leave_cursor=_search_flags & VSSEARCHFLAG_INCREMENTAL;
   if ( key:==BACKSPACE ) {  /* Incremental search must be on. */
      if (!_default_option(VSOPTION_HAVECMDLINE)) {
         parse get_message() with tmp_prompt ': 'search_string;
         if ( !length(search_string)) return '';
         search_string=substr(search_string,1,length(search_string)-1);
         message(tmp_prompt': 'search_string);
      }  else {
         _cmdline.get_command(search_string);
         if ( length(search_string)==0 ) { return ''; }
         _cmdline._rubout();
         _cmdline.get_command(search_string);
      }
      if (!invalid_re) {
         _begin_select(gisearch_pos2);
      }
      start_point='';
      init_isearch(search_string, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
   } else if (isnormal_char(key) && key:!='') {  /* Incremental search must be on. */
      if ( doSearchPrompt!='' ) {
         prompt=make_search_prompt(_search_flags,orig_prompt);
         return(1);
      }
      if ( length(key)>1 ) {
         key=key2ascii(key);
      }
      if (!notfound || re_search) {
         if (!_default_option(VSOPTION_HAVECMDLINE) ) {
            parse get_message() with tmp_prompt ': 'cmd_text;
            //say('len='length(cmd_text)' t='cmd_text);
            cmd_text=cmd_text:+key;
            message(tmp_prompt': 'cmd_text);
         }  else {
            _cmdline.get_command(cmd_text);
            cmd_text=cmd_text:+key;
            _cmdline.set_command(cmd_text,length(cmd_text)+1);
         }
         if (re_search) {
            _begin_select(gisearch_pos2);
            start_point='';
         }
        init_isearch(cmd_text, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
      }
   } else if ( ((key:==C_R || (key:==A_F5 && def_keys=='brief-keys')) || (key:==C_S || (key:==F5  && def_keys=='brief-keys'))) ) {
      int old_flags=_search_flags;
      boolean change_dir;
      if ( key:==C_S || key:==F5) {
         change_dir= (_search_flags & VSSEARCHFLAG_REVERSE) != 0;
         _search_flags= (_search_flags & ~VSSEARCHFLAG_REVERSE)|VSSEARCHFLAG_POSITIONONLASTCHAR;
      } else {
         change_dir= ! (_search_flags & VSSEARCHFLAG_REVERSE);
         _search_flags= (_search_flags & ~VSSEARCHFLAG_POSITIONONLASTCHAR)|VSSEARCHFLAG_REVERSE;
      }
      prompt=make_search_prompt(_search_flags,orig_prompt);
      if ( change_dir ) {
         search_options=make_search_options(_search_flags);
      }
      if ( _first_change_dir && change_dir && ! (_search_flags & VSSEARCHFLAG_INCREMENTAL) ) {
         _first_change_dir=0;
         return('');
      }
      _first_change_dir=0;
      if (!_default_option(VSOPTION_HAVECMDLINE)) {
         parse get_message() with tmp_prompt ': 'cmd_text;
      }  else {
         _cmdline.get_command(cmd_text);
      }
      if ( cmd_text:=='' ) {
         restore_search(old_search_string,_search_flags,'['p_word_chars']',old_search_reserved,old_search_flags2);
         if ( old_search_string:!='' ) {
            cmd_text=old_search_string;

            if (!_default_option(VSOPTION_HAVECMDLINE)) {
               message(prompt:+cmd_text);
            } else {
               _cmdline.set_command(cmd_text,length(cmd_text)+1);
            }

            _search_flags = (_search_flags & ~(VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WORD|VSSEARCHFLAG_IGNORECASE))|
               (old_search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WORD|VSSEARCHFLAG_IGNORECASE));
            prompt = make_search_prompt(_search_flags,orig_prompt);
         } else {
            return('');
         }
      }
      p_window_id=editorctl_wid;_set_focus();
      restore_search(cmd_text,_search_flags,'['p_word_chars']');
      old_search_string=cmd_text;

      // Exit any scroll that we are in. Had to do this for mouse scroll wheel
      // where the user can start scrolling with the wheel, and the cursor/caret
      // goes out of view.
      _ExitScroll();
      _str junk;

      if (change_dir) {
         // going backwards
         if (_search_flags & VSSEARCHFLAG_REVERSE) {
            // go to the beginning of the match, so we don't match the same thing again
            goto_point(match_length('s'));
         } else {
            // go to the end of the match, so we don't match the same thing again
            goto_point(match_length('s') + match_length(''));
         }
      }

      _str status = last_i_search(cmd_text,_search_flags);
      save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
      if (!_default_option(VSOPTION_HAVECMDLINE)) {
         message(prompt:+cmd_text);
      } else {
         command_put(cmd_text);
         p_window_id = editorctl_wid;_set_focus();
         _cmdline.p_visible = 1;
      }
      leave_cursor=1;
      if ( status==INVALID_REGULAR_EXPRESSION_RC ) {
         invalid_re = 1;
         notfound = 0;
      } else {
         invalid_re = 0;
         notfound=status;
      }
      if ( ! status ) {
         if (_default_option(VSOPTION_HAVECMDLINE)) {
           clear_message();
         }
         start_point = match_length('s');
      } else {
         _beep();
      }
   } else if (_search_ft_toggle_keys(key, _search_flags, flag)) {
      if (replace_ft && (flag & (VSSEARCHFLAG_FINDHILIGHT|VSSEARCHFLAG_GO))) {
         flag = 0;
      }
      if ( _search_flags & flag ) {
         _search_flags =_search_flags & ~flag;
      } else {
         _search_flags =_search_flags | flag;
      }
      prompt = make_search_prompt(_search_flags,orig_prompt);
      if ( _search_flags & VSSEARCHFLAG_INCREMENTAL ) {
         if (!_default_option(VSOPTION_HAVECMDLINE)) {
            parse get_message() with ': 'search_string;
         }  else {
           _cmdline.get_command(search_string);
         }
         search_options = make_search_options(_search_flags);
         init_isearch(search_string, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
      }
   } else if ( name_on_key(key):=='quote-key' && ! notfound &&
             (_search_flags & VSSEARCHFLAG_INCREMENTAL) ) {
      if (!_default_option(VSOPTION_HAVECMDLINE)) {
         _str param;
         parse get_message() with tmp_prompt ': 'cmd_text;
         key=get_event();
         key=key2ascii(key);
         if ( length(key)>1 ) {
            param=last_event();
         } else {
            param=key2ascii(key);
         }
         cmd_text=cmd_text:+param;
         message(tmp_prompt': 'cmd_text);
         return('');
      }
      int orig_view_id;
      get_window_id(orig_view_id);
      p_window_id=_cmdline;_set_focus();
      quote_key();
      activate_window(orig_view_id);_set_focus();
      _cmdline.p_visible=1;
      //p_window_id=editorctl_wid;
      _cmdline.get_command(search_string);
      init_isearch(search_string, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
   } else if ( key:=='' || key:==C_O ) {  /* Init prompt or Toggle incremental search? */
      if (key:==C_O && !_default_option(VSOPTION_HAVECMDLINE)) {
         return('');
      }
      notfound=0;
      if ( key:=='' ) {
         start_point='';
      }
      invalid_re=0;
      if ( key:==C_O ) {
         if ( _search_flags & VSSEARCHFLAG_INCREMENTAL ) {
            _search_flags= _search_flags & ~(VSSEARCHFLAG_INCREMENTAL /* |VSSEARCHFLAG_POSITIONONLASTCHAR */);
            _end_incremental_search();
         } else {
            _search_flags= _search_flags | VSSEARCHFLAG_INCREMENTAL;
            if ( ! (_search_flags & VSSEARCHFLAG_REVERSE) ) {
               _search_flags= _search_flags | VSSEARCHFLAG_POSITIONONLASTCHAR;
            }
         }
      }
      if ( _search_flags & VSSEARCHFLAG_INCREMENTAL ) {
         if (!_default_option(VSOPTION_HAVECMDLINE)) {
            p_window_id=editorctl_wid;
         } else {
            _cmdline.get_command(cmd_text);
            command_put(cmd_text);
            p_window_id=editorctl_wid;_set_focus();
            _cmdline.p_visible=1;
         }
         _get_string2='1'; /* Don't allow get_string() editing */
         leave_cursor=1;
      } else {
         cursor_command();
         _get_string2='';
      }
      prompt=make_search_prompt(_search_flags,orig_prompt);
      search_options=make_search_options(_search_flags);
      if ( key:==C_O && (_search_flags & VSSEARCHFLAG_INCREMENTAL) ) {
         if (!_default_option(VSOPTION_HAVECMDLINE)) {
            parse get_message() with prompt ': 'search_string;
         } else {
            _cmdline.get_command(search_string);
         }
         search_options=make_search_options(_search_flags);
         init_isearch(search_string, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
      }
   } else if (_search_ft_complete_word(key)) {
      // get the previous word list
      _str prevSearchString = "";
      _cmdline.get_command(prevSearchString);

      // grab the next word, not going beyond the end of the line.  do not grab preceding
      // whitespace if this is the first word.  the cursor will be left sitting at the end
      // of the next word
      _str searchResult = getNextWord();

      searchResult = prevSearchString :+ searchResult;
      command_put(searchResult);

      p_window_id=editorctl_wid;_set_focus();
      _cmdline.p_visible=1;
      if (_search_flags & VSSEARCHFLAG_INCREMENTAL) {
         if (!_default_option(VSOPTION_HAVECMDLINE)) {
            parse get_message() with prompt ': 'search_string;
         } else {
            _cmdline.get_command(search_string);
         }
         search_options=make_search_options(_search_flags);
         init_isearch(search_string, search_options, _search_flags, notfound, invalid_re, start_point, wrap_search);
      }
   } else if ( orig_prompt==nls('Replace string:') && _get_string2!='' && ! iscancel(key) && key:!=ENTER ) {
      return(1);
   } else {
      if (_search_flags & VSSEARCHFLAG_INCREMENTAL) {
         _end_incremental_search();
      }
      return(0);
   }
   return('');

}

/**
 * Get the next word in the same manner that copy_word() does, but
 * return the word in a string instead of putting it on the clipboard
 *
 * @return The next word at the cursor
 */
static _str getNextWord()
{
   _str match = "";

   int i = _text_colc(p_col, "P");
   int lineLen = _line_length();
   if(i > lineLen) {
      return "";
   }
   p_col = _text_colc(i, "I");
   int status = 0;

   // this search serves only the purpose of backing the cursor up to the beginning
   // of the current word so that the entire word will be selected.  copy_word()
   // does the exact same thing before calling pselect_word().  this is different
   // from the behavior of gnu emacs which just takes the rest of the word from the
   // cursor.  simply commenting out this search will restore the gnu emacs behavior
   //
   // search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-r@');

   // pselect_word() is the same function that copy_word() calls and will handle the search
   // for us.  it leaves the cursor at the end of the word that this function returns
   int origOffset = (int)_QROffset();
   int mark = _alloc_selection();
   pselect_word(mark);
   _free_selection(mark);

   int newOffset = (int)_QROffset();
   if(newOffset > origOffset) {
      int matchOffset = origOffset;
      int matchLength = newOffset - origOffset;
      //say("offset=" matchOffset " length=" matchLength);
      match = get_text(matchLength, matchOffset);
      //say("match: \"" match "\"");
   }

   return match;
}

int init_search_flags(int flags)
{
   _get_string=find_index('-search-ft',PROC_TYPE);
   _search_flags=flags;
   return(_search_flags);

}
int init_qreplace( typeless flags='', _str prompt='' )
{
   if ( flags=='' ) {
      flags=0;
   }
   if ( prompt=='' ) {
      prompt=nls('Replace string:')' ';
   }
   old_search_bounds=null;
   old_search_within_selection=false;
   p_LCHasCursor=0;
   if ( init_search(flags,prompt,'1') ) {
      return(1);
   }
   _get_string=find_index('_search_ft',PROC_TYPE);
   _allow_searching=0; /* Don't allow _search_ft searching */
   _str cmd_name=name_name(last_index('','C'));
   _str replace_string;
   int status = (int) get_string(replace_string,'With: ','-.'cmd_name,old_replace_string);
   _get_string='';
   if ( status ) {
      return(status);
   }
   old_replace_string=replace_string;
   return(0);

}
/**
 * Searches from cursor position for <i>search_string</i> and replaces
 * matches with <i>replace_string</i>.  This procedure supports the
 * same options as the <b>replace</b> command.  Unlike the
 * <b>replace</b> command, this procedure does not use any default
 * options not specified by the <i>options </i>parameter and requires the
 * <i>search_string</i>, <i>replace_string</i>, and <i>options</i>
 * parameters to be given.  The <i>options</i> argument is a string of
 * one or more of the following:
 *
 * <dl>
 * <dt>E</dt><dd>Exact case.</dd>
 *
 * <dt>I</dt><dd>Ignore case.</dd>
 *
 * <dt>-</dt><dd>Reverse search.</dd>
 *
 * <dt>M</dt><dd>Limit search to marked area.</dd>
 *
 * <dt>V</dt><dd>Preserve case. When specified, each occurrence
 * found is checked for all lower case, all upper case,
 * first word capitalized or mixed case.  The replace
 * string is converted to the same case as the
 * occurrence found excepted when the occurrence
 * found is mixed case (possibly mulltiple capitalized
 * words).  In this case, the replace string is used
 * without modification.</dd>
 *
 * <dt><</dt><dd>If found, position cursor at beginning of word.</dd>
 *
 * <dt>></dt><dd>If found, position cursor at end of word.</dd>
 *
 * <dt>*</dt><dd>Make changes without prompting.</dd>
 *
 * <dt>R</dt><dd>Interprets <i>string1</i> to be a SlickEdit regular
 * expression.  <i>String2</i> may specify tagged
 * expressions with a pound followed by a group
 * number 0-9.  Count the left braces '{' to determine a
 * group number.  The first tagged expression is "#0".
 * See <b>SlickEdit Regular Expressions</b>.</dd>
 *
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 * section <b>UNIX Regular Expressions</b>.
 * <i>String2</i> may specify tagged expressions
 * with a backslash followed by a group number 0-9.
 * Count the left parenthesis '(' to determine a group
 * number.  The first tagged expression is "\1" and the
 * last tagged expression is "\9".  See <b>UNIX
 * Regular Expressions</b>.</dd>
 *
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 * section <b>Brief Regular Expressions</b>.
 * <i>String2</i> may specify tagged expressions
 * with a backslash followed by a group number 0-9.
 * Count the left braces '{' to determine a group
 * number.  The first tagged expression is "\0".  See
 * <b>Brief Regular Expressions</b>.</dd>
 *
 * <dt>H</dt><dd>Search through hidden lines.</dd>
 *
 * <dt>N</dt><dd>Do not interpret search string as a regular search
 * string.</dd>
 *
 * <dt>P</dt><dd>Wrap to beginning/end when string not found.</dd>
 *
 * <dt>W</dt><dd>Limits search to words.  Used to search and replace
 * variable names.</dd>
 *
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 *    Specifies the valid characters in a word.  The
 * default value is [A-Za-z0-9_$]</dd>
 *
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 * searching for "pre" matches "pre" and "prefix" but
 * not "supreme" or "supre".</dd>
 *
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 * searching for "pre" matches "prefix" but not "pre",
 * "supreme" or "supre".</dd>
 *
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 * searching for "fix" matches "fix" and "sufix" but
 * not "fixit".</dd>
 *
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 * searching for "fix" matches "sufix" but not "fix" or
 * "fixit".</dd>
 *
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 *
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 *
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified.
 * For example, "XCS" requires that the first character
 * not be in a comment or string. <i>CCLetters</i> is
 * a string of one or more of the following color
 * coding element letters:</dd>
 *
 * <dl>
 * <dt>O</dt><dd>Other</dd>
 * <dt>K</dt><dd>Keyword</dd>
 * <dt>N</dt><dd>Number</dd>
 * <dt>S</dt><dd>String</dd>
 * <dt>C</dt><dd>Comment</dd>
 * <dt>P</dt><dd> Preprocessing</dd>
 * <dt>L</dt><dd>Line number</dd>
 * <dt>1</dt><dd>Symbol 1</dd>
 * <dt>2</dt><dd>Symbol 2</dd>
 * <dt>3</dt><dd>Symbol 3</dd>
 * <dt>4</dt><dd>Symbol 4</dd>
 * <dt>F</dt><dd>Function color</dd>
 * <dt>V</dt><dd>No save line</dd>
 * </dl>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to
 * be one of the color coding elements specified. See
 * <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * <p>If the '*' option is not specified, you will be prompted with the
 * message "Yes/No/Last/Go/Quit?" for each occurrence of
 * <i>string1</i>.   Press one of the following keys to take an action:</p>
 *
 * <dl>
 * <dt>'Y' or SPACE</dt><dd>Make change and continue searching.</dd>
 * <dt>'N' or BACKSPACE</dt><dd>No change and continue searching.</dd>
 * <dt>'L' or .</dt><dd>Make change and stop searching.</dd>
 * <dt>'G' or !</dt><dd>Make change and change the rest without
 * prompting.</dd>
 * <dt>'Q' or ESC</dt><dd>Exits command.  By default, the cursor is
 * NOT restored to its original position.  If you
 * want the cursor restored to its original
 * position, invoke the command "<b>set-var
 * def-restore-cursor 1</b>" and save the
 * configuration.  Quit searching.</dd>
 * <dt>Ctrl+G</dt><dd>Exits command and restores cursor to its
 * original position.</dd>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of
 * search string.</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of
 * search string.</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching
 * on/off.  The key bound to the BRIEF
 * emulation command <b>re_toggle</b> will
 * also toggle regular expression pattern
 * matching.  See section <b>Regular
 * Expressions</b> for more information.
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to
 * the BRIEF emulation command
 * CASE_TOGGLE will also toggle the case
 * sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within mark.</dd>
 * <dt>F1 or '?'</dt><dd>Displays help on C command.</dd>
 * </dl>
 *
 * <p>The optional <i>orig_cursor_pos_mark</i> argument is a selection
 * handle which specifies the text position where the cursor position
 * should be restored if Ctrl+G is pressed to terminate the search.</p>
 *
 * @return Returns 0 if search string found and search & replace not cancelled.
 * Common return codes are COMMAND_CANCELLED_RC,
 * STRING_NOT_FOUND_RC, TOO_MANY_SELECTIONS_RC,
 * INVALID_REGULAR_EXPRESSION_RC, and
 * INVALID_OPTION_RC.  On error, message displayed.  The global
 * variable "_Nofchanges" is set to the number of occurrences changed.
 *
 * @see qsearch
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see find_next
 * @see find_prev
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
int qreplace(_str search_string,_str replace_string,typeless options,typeless search_mark="")
{
   typeless old_mark=_duplicate_selection('');
   typeless mark=_duplicate_selection();
   if ( mark<0 ) {
      _message_box(get_message(mark));
      if ( search_mark!='' ) {
         _free_selection(search_mark);
      }
      return(mark);
   }
   int go=0;
   if ( isinteger(options) ) { /* Flags given? */
      go=options&VSSEARCHFLAG_GO;
      // Removed ,1 so that BRIEF translate_backward did not go
      // forward.
      options=make_search_options(options/*,1*/);
   } else {
      _str a="";
      parse options with a 'w=','i';
      go=pos('*',a);
   }
   old_go=go;
   int Nofchanges=0;
   _SearchInitSkipped(0);
   // Set the word characters
   restore_search(old_search_string,0,'['p_word_chars']');
   search('',options);
   // Translate flags into word re
   typeless junk,flags,word_re;
   save_search(junk,flags,word_re);
   old_search_flags=flags;
   old_word_re=word_re;
   old_search_string=search_string;
   old_replace_string=replace_string;
   old_search_bounds=null;
   old_search_within_selection=false;
   p_LCHasCursor=0;
   _macro_delete_line();
   _macro_call('replace',old_search_string,old_replace_string,options);
   options='xv,'options;
   _str nls_chars="";
   _str prompt=nls_strip_chars(nls_chars,'Replace ~Yes/~No/~Last/~Go/~Quit?');
   if ( search_mark=='' ) {
      search_mark=_alloc_selection();
      if ( search_mark<0 ) {
         _message_box(get_message(search_mark));
         _free_selection(mark);
         return(search_mark);
      }
      _select_char(search_mark);     /* Save cursor position */
   }
   typeless wrap_mark=_alloc_selection();
   if (wrap_mark<0) {
      _message_box(get_message(wrap_mark));
      _free_selection(mark);
      _free_selection(search_mark);
      return(wrap_mark);
   }
   if ( (flags & VSSEARCHFLAG_MARK) &&
         select_active() && (_cursor_move_deselects() || _cursor_move_extendssel())
      ) {
      if( _select_type('','S')=='C' ) {
         _select_type('','S','E');       /* lock the selection. */
         //select_it(_select_type(),'');  /* lock the selection. */
      }
      if ( flags&VSSEARCHFLAG_REVERSE ) {
         _end_select();_end_line();
      } else {
         _begin_select();_begin_line();
      }
      if (flags & VSSEARCHFLAG_WRAP) flags&=~ (VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP);
   }
   int searched_in_wrap_mark=0;
   _str wrap_option='';
   int wrap_flag=0;
   if ((flags & (VSSEARCHFLAG_MARK|VSSEARCHFLAG_WRAP))==(VSSEARCHFLAG_MARK|VSSEARCHFLAG_WRAP) &&
       select_active() && _select_type()=='BLOCK') {
      // Can't handle wrap searching within block marks that well
      // Must start at begin or end of block
      if (flags & VSSEARCHFLAG_REVERSE) {
         _end_select();
      } else {
         _begin_select();
      }
      searched_in_wrap_mark=2;
   }
   int searchrc=0;
   if ( search_string:=='' ) {
      searchrc=STRING_NOT_FOUND_RC;
      message(get_message(STRING_NOT_FOUND_RC));
   } else {
      searchrc=search(search_string,options);
      if ( ! searchrc && !go) {
         message(make_search_prompt(flags,prompt));
      }
      if (searchrc == INVALID_REGULAR_EXPRESSION_RC) {
         _show_selection(old_mark);
         _free_selection(wrap_mark);
         _free_selection(search_mark);
         _free_selection(mark);
         return(searchrc);
      }
   }
   typeless status2=0;
   typeless p=0;
   _str style='';
   if (search_string:!='' && (flags & VSSEARCHFLAG_WRAP) && !searched_in_wrap_mark) {
      save_pos(p);
      if ((flags & VSSEARCHFLAG_MARK) && select_active()) {
         style='CHAR';
         if (_select_type()=='BLOCK') {
            style='BLOCK';
         }
         // Is this an inclusive mark?
         if (flags & VSSEARCHFLAG_REVERSE) {
            if (searchrc) {
               _begin_select();if (_select_type()=='LINE') _begin_line();
            } else {
               // Place cursor at first character string found
               status2=goto_point(match_length('s')+match_length(''));
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
               _end_line();p_col+=2;
            } else if (_select_type()=='CHAR' && _select_type('i')) {
               // This is an inclusive character mark
               ++p_col;
            }
            select_it(style,wrap_mark);
         } else {
            if (searchrc) {
               _end_select();
               if (_select_type()=='LINE') {
                  _end_line();p_col+=2;
               } else if (_select_type()=='CHAR' && _select_type('i')) {
                  // This is an inclusive character mark
                  ++p_col;
               }
            } else {
               // Place cursor at start of string found
               goto_point(match_length('s'));
            }
            // Select text from start of string to top of file
            select_it(style,wrap_mark);
            _begin_select();if (_select_type()=='LINE') _begin_line();
            select_it(style,wrap_mark);
         }
      } else {
         if (flags & VSSEARCHFLAG_REVERSE) {
            if (searchrc) {
               top();
            } else {
               // Place cursor at first character string found
               status2=goto_point(match_length('s')+match_length(''));
               if (status2) {
                  // Must be binary file and found string at end of file.
                  // can't seek past end of file
                  clear_message();bottom();
               }
            }
            // Select text from after string to bottom of file
            _select_char(wrap_mark);bottom();_select_char(wrap_mark);
         } else {
            if (searchrc) {
               bottom();
            } else {
               // Place cursor at start of string found
               goto_point(match_length('s'));
            }
            // Select text from start of string to top of file
            _select_char(wrap_mark);top();_select_char(wrap_mark);
         }
      }
      restore_pos(p);
   }
   typeless temp="";
   typeless status=0;
   int orig_mark_flag=(old_search_flags & VSSEARCHFLAG_MARK);
   boolean leave_selected=!(orig_mark_flag && select_active()) && def_persistent_select=='D' && def_leave_selected;
   cursor_data();
   boolean restore_cursor=def_restore_cursor;
   boolean call_last_key=0;
   typeless failing='';
   boolean found_one=0;
   _str key='';
   _suspend();
   if ( rc ) {
      if ( rc==1 ) {
         rc=0;
      }
      status=rc;
      if (status==VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) {
         clear_message();
         refresh();
         _beep();
         _message_box(get_message(VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO));
      } else {
         if ( status ) {
            message(get_message(status));
         } else {
            clear_message();
         }
      }
      if ( restore_cursor ) _begin_select(search_mark);
      if (searched_in_wrap_mark==1) {
         temp=wrap_mark;wrap_mark=old_mark;old_mark=temp;
      }
      _free_selection(wrap_mark);
      _free_selection(search_mark);
      _show_selection(old_mark);
      _free_selection(mark);
      old_go=go;
      old_search_string=search_string;
      old_replace_string=replace_string;
      save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
      old_search_flags &= ~VSSEARCHFLAG_MARK;old_search_flags |=orig_mark_flag;
      if ( call_last_key ) {
         _undo('s');
         call_key(key);
      }
      Nofchanges-=_SearchQNofSkipped();
      _Nofchanges=Nofchanges;
      _str skipped=_SearchQSkipped();
      if (skipped!='') {
         refresh();
         _message_box("The following lines were skipped to prevent line truncation:\n\n"skipped);
      }
      qreplace_Nofchanges(status,Nofchanges);
      return(status);
   }
   if (!searchrc && flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE)) {
      // check for valid replace string
      get_replace_text(replace_string);
      if (rc) {
         return(rc);
      }
   }
   typeless old_searchrc=searchrc;
   for (;;) {
      _killReplaceToolTip();
      if ( searchrc<0 ) {
         if (searchrc!=COMMAND_CANCELLED_RC && !searched_in_wrap_mark &&
             _select_type(wrap_mark)!='' &&
             confirm_wrap(flags,search_string,'@m'options,wrap_mark,old_mark,false,false)) {
            save_pos(p);
            old_searchrc=searchrc;
            searched_in_wrap_mark=1;
            if (flags & VSSEARCHFLAG_REVERSE) {
               _end_select(wrap_mark);
            } else {
               _begin_select(wrap_mark);
            }
            clear_message();
            temp=wrap_mark;wrap_mark=old_mark;old_mark=temp;
            _show_selection(old_mark);
            wrap_option='m';
            wrap_flag=VSSEARCHFLAG_MARK;
            searchrc=search(search_string,'m'options);
            /* messageNwait('searchrc='searchrc' go='go' options='options) */
            if ( ! searchrc && !go) {
               message(make_search_prompt(flags,prompt));
            }
            if (searchrc) {
               if (old_searchrc == STRING_NOT_FOUND_RC) {
                  restore_pos(p);
               }
               if(go) {
                  clear_message();
               }
               break;
            }
            if (flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE)) {
               // check for valid replace string
               get_replace_text(replace_string);
               searchrc = rc;
               if (searchrc) {
                  break;
               }
            }
         } else {
            break;
         }
      } else if ( searchrc==0 && failing!='' ) {
         failing='';
         message(failing:+make_search_prompt(flags,prompt));
      }
      int nls_index=0;
      if (go) {
         nls_index=4;
      } else {
         found_one=1;
         _showReplaceToolTip(replace_string);
         _show_selection(mark);
         if ( failing=='' ) {
            _select_match(mark);
         } else {
            _show_selection(mark);
         }
         //_UpdateContext(true);
         _UpdateCurrentTag(true);
         _UpdateContextWindow(true);
         key=pgetkey();
         _show_selection(old_mark);
         nls_index=pos(upcase(key),nls_chars);
      }
      if ( nls_index==1 || key:==' ' ) {   // Yes
         ++Nofchanges;
         searchrc=search_replace(replace_string,'R');
         if (searchrc==VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) --Nofchanges;
      } else if ( nls_index==2 || key:==BACKSPACE ) { // No
         searchrc=repeat_search();
      } else if ( nls_index==3 || key:=='.' ) {  // Last
         ++Nofchanges;
         searchrc=search_replace(replace_string);
         if (searchrc==VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) --Nofchanges;
         break;
      } else if ( nls_index==4 || key:=='!' ) { // Go

         found_one=1;
         ++Nofchanges;
         searchrc=search_replace(replace_string,'r');
         if (searchrc==VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) --Nofchanges;
         go=1;
         int add_Nofchanges=0;
         if ( searchrc ) {
            clear_message();
            if (searchrc!=VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) {
               searchrc=0;
            }
            add_Nofchanges=0;
         } else {
            typeless tflags;
            save_search(junk,tflags,junk);
            if ( ! (tflags & VSSEARCHFLAG_REVERSE) ) {
               if (_nrseek()!=match_length('S')) {
                  goto_point(match_length('S'));
               }
            }
            searchrc=search(search_string,wrap_option:+options'*',replace_string,add_Nofchanges);
         }
         Nofchanges+=add_Nofchanges;
         if (searched_in_wrap_mark) {
            break;
         } else {
            if (searchrc!=VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO) {
               searchrc=STRING_NOT_FOUND_RC;
            }
         }
      } else if ( key:==C_G ) {  // EMACS alternate cancel
         if (leave_selected) {
            temp=old_mark;old_mark=mark;mark=temp;
         }
         restore_cursor=1;
         searchrc=COMMAND_CANCELLED_RC;
         break;
      } else if ( nls_index==5 || iscancel(key) ) {  // Cancel
         if (leave_selected) {
            temp=old_mark;old_mark=mark;mark=temp;
         }
         restore_cursor=0;
         searchrc=0;
         if ( iscancel(key) ) {
            searchrc=COMMAND_CANCELLED_RC;
         }
         break;
      } else if ( key:==F1 || key:=='?' ) {
         help('replace');
#if 0
         _str name=name_name(last_index('','C'));
         if ( name=='c' ) {
            help('replace');
         } else {
            help(translate(name,'_','-'));
         }
#endif
      } else if ( key:==C_R || key:==C_S || key:=='^' ) {
         //Forget wrapping logic
         if (!searched_in_wrap_mark) searched_in_wrap_mark=2;
         _deselect(wrap_mark);wrap_option='';wrap_flag=0;
         p=point();
         int col=p_col;
         if ( key:==C_S ) {
             searchrc=repeat_search('+');
         } else {
             searchrc=repeat_search('-');
         }
         if ( ! searchrc && p==point() && col==p_col ) { /* In same place? */
            searchrc=repeat_search();
         }
         if ( searchrc ) {
            searchrc=1;
            failing=get_message(STRING_NOT_FOUND_RC)'  ';
         }
         message(failing:+make_search_prompt(flags,prompt));
         restore_search(search_string,flags,old_word_re);
      } else {
         _search_flags=flags;
         _allow_searching=1;
         typeless new_prompt="";
         if ( _search_ft(key,new_prompt,prompt,junk,'1',p_window_id) ) {
            searchrc=rc;
            flags=_search_flags;
            options=make_search_options(flags,1);
            restore_search(search_string,flags|wrap_flag,word_re);
            message(failing:+new_prompt);
         } else {
            call_last_key=1;
            restore_cursor=0;
            searchrc=0;
            break;
         }
      }
      _undo('s');

   }
   _undo('s');
   if (searchrc==STRING_NOT_FOUND_RC && found_one) {
      searchrc=0;
   }
   rc=searchrc;
   if ( ! rc ) {
      rc=1;  // Indicate that there were no errors
   }
   _killReplaceToolTip();
   _resume();
   // We will never hit this return statement
   return(1);
}
int init_search( typeless flags='', _str prompt='',  typeless call_key_on_complete='')
{
   int orig_wid=p_window_id;
   typeless search_mark=_alloc_selection('B');
   if ( search_mark<0 ) {
      message(get_message(search_mark));
      return(search_mark);
   }
   _select_char(search_mark);     /* Save cursor position */
   if ( flags=='' ) {
      flags=0;
   }
   if ( prompt=='' ) {
      prompt=nls('Search:')' ';
   }
   _search_flags=flags;
   _first_change_dir=1; /* Don't search on first change of direction. */
   _allow_searching=1;  /* Allow _search_ft searching */
   _str cmd_name=name_name(last_index('','C'));
   /* make a copy of the current view so that position in file is saved */
   _save_pos2(gisearch_pos2);
   _str old_scroll_style=_scroll_style();
   _scroll_style('c'substr(old_scroll_style,2));  /* always center scroll for searching. */
   init_search_flags(_search_flags);
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   _str search_string='';
   _str key='';
   typeless status=0;
   typeless junk="";
   _suspend();
   if ( rc ) {
      _get_string='';_get_string2='';
      status=rc;
      _free_selection(gisearch_pos2);
      _cmdline.set_command('',1,1,'');
      _scroll_style(old_scroll_style);
      if ( search_string:!='' ) {
         old_search_string=search_string;
         old_search_flags=_search_flags;
         save_search(junk,junk,old_word_re);
      }
      if ( status==1 ) {
         if ( _search_flags & VSSEARCHFLAG_INCREMENTAL ) {
            p_window_id=orig_wid;
         }
         if ( ! iscancel(key) ) {
            clear_message();
            if ( (_search_flags & VSSEARCHFLAG_INCREMENTAL) && call_key_on_complete=='' ) {
               _macro('m',_macro());
               _macro_delete_line();
               _macro_call('find',old_search_string,make_search_options(old_search_flags));
               _free_selection(search_mark);
               if (key:==LBUTTON_DOWN && !mou_in_window()) {
               } else {
                  // GNU Emacs 19.29 ENTER terminates incremental search.
                  if (key:!=ENTER || (def_keys!='gnuemacs-keys' && def_keys!='emacs-keys')) {
                     if (!p_mdi_child) {
                        //command=name_on_key(key);
                        call_event(p_window_id,key);
                     } else {
                        call_key(key);
                     }
                  }
               }
               return 1;  /* Indicate searching complete */
            }
            _free_selection(search_mark);
            return(0);
         }
         if ( key:==C_G ) {
            _begin_select(search_mark);
         }
         _free_selection(search_mark);
         cancel();
         return 1;
      }
      _free_selection(search_mark);
      message(get_message(status));
      return(status);
   }
   _str string=old_search_string;
   if ( _search_flags & VSSEARCHFLAG_INCREMENTAL ) {
      string='';
   }
   // IF we don't have a command line.
   if (!_default_option(VSOPTION_HAVECMDLINE)) {
      status=get_string2(search_string,prompt,'-.'cmd_name,string);
   } else {
      status=get_string(search_string,prompt,'-.'cmd_name,string);
   }
   _get_string='';_get_string2='';
   key=_key;
   if ( ! status ) {
      status=1;
   }
   rc=status;_resume();
   // We will never hit this return statement
   return(1);
}

int _srg_search(_str option='',_str info='')
{
   if ( option=='R' || option=='N' ) {
      typeless temp_search_flags="";
      parse info with . temp_search_flags' .'old_search_string;
      old_search_flags=temp_search_flags;
      down();
      get_line(old_replace_string);
   } else {
#if __EBCDIC__
      cond := (!pos('[\13\21]',old_search_string,1,'r') && !pos('[\13\21]',old_replace_string,1,'r'));
#else
      cond := (!pos('[\13\10]',old_search_string,1,'r') && !pos('[\13\10]',old_replace_string,1,'r'));
#endif
      if (cond) {
         insert_line('SEARCH: 1 'old_search_flags' .'old_search_string);
         insert_line(old_replace_string);
      }
   }
   return(0);
}
/* Used by start-recording command to set ESC to abort-kbd-macro.  */
/* You may changed this key to any valid key constant. See help KEY-NAMES. */

/**
 * Returns event index for canceling macro recording.  Defaults to event2index (ESC).
 *
 * @return the event index
 *
 * @see iscancel
 * @see islist_cancel
 *
 *
 * @categories Keyboard_Functions, Macro_Programming_Functions
 */
int cancel_key_index()
{
   if (def_keys=='emacs-keys' ) {
      return(0);
   }
   return(event2index(ESC));
}

/* if there is no mark searches for the word at the cursor.
   if there is a mark, searches for the selected text if it is on a single line.
   Otherwise, searches for the word at the cursor within the mark
*/
static _str get_quick_search_word(int &start_col)
{
   word := "";
   if (select_active2()) {
      if (!_begin_select_compare()&&!_end_select_compare()) {
         /* get text out of selection */
         last_col := 0;
         buf_id   := 0;
         _get_selinfo(start_col,last_col,buf_id);
         if (_select_type('','I')) ++last_col;
         if (_select_type()=='LINE') {
            get_line(auto line);
            word=line;
            start_col=0;
         } else {
            word=_expand_tabsc(start_col,last_col-start_col);
         }
         _deselect();
      }else{
         deselect();
         word=cur_word(start_col,'',1);
      }
   }else{
      word=cur_word(start_col,'',1);
   }
   return word;
}
/**
 * Search for word at cursor or selection.
 *
 * @param cursorPos String indicating position to leave the
 *                  cursor at after a search.  Default is '>'
 *                  (after word).
 *
 * @return Returns 0 if the search string is found.  Otherwise,
 * STRING_NOT_FOUND_RC is returned..  On error, message is
 * displayed.
 *
 * @see qreplace
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int quick_search(_str cursorPos='>') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   start_col := 0;
   word := get_quick_search_word(start_col);
   if ( word=='' ) {
      _beep();
      message(nls('No word at cursor'));
      return(STRING_NOT_FOUND_RC);
   }
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
   // Note: removed 'p' option so we respect the default search option for wrapping
   _str default_search_options = make_search_options(_default_option('s'));
   if (def_keys == 'vi-keys') {
      if (def_vi_always_highlight_all) {
         default_search_options = default_search_options :+ '*#';
         clear_highlights();
      }
      default_search_options = default_search_options :+ 'w';
      append_retrieve_command('@2/ 'word);
   }
   status := find(word,default_search_options'n+'cursorPos);
   return(status);
}

int _OnUpdate_quick_search(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_ENABLED;
   }

   // see if we have a selection
   if (target_wid.select_active()) {
      // is it multi-line?  then don't do this, because it's sorta nonsensical anyway
      target_wid._get_selinfo(auto startCol, auto endCol, auto bufId, '', '', 0, 0, auto nOfLines);
      if (nOfLines != 1) {
         return MF_GRAYED;
      }
   }

   return MF_ENABLED;
}

/**
 * Search backwards for word at cursor or selection.
 *
 * @return Returns 0 if the search string is found.  Otherwise,
 * STRING_NOT_FOUND_RC is returned..  On error, message is
 * displayed.
 *
 * @see qreplace
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int quick_reverse_search() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   start_col := 0;
   word := get_quick_search_word(start_col);
   if ( word=='' ) {
      _beep();
      message(nls('No word at cursor'));
      return(STRING_NOT_FOUND_RC);
   }
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
   if (!select_active2()) {
      begin_word();
      prev_full_word();
   } else {
      begin_select();
      left();
   }
   _str default_search_options = make_search_options(_default_option('s'));
   if (def_keys == 'vi-keys') {
      if (def_vi_always_highlight_all) {
         default_search_options = default_search_options :+ '*#';
         clear_highlights();
      }
      default_search_options = default_search_options :+ 'w';
      append_retrieve_command('@1? 'word);
   }
   status :=find(word,default_search_options'n-<');
   return(status);
}

/**
 * Replace the word at cursor or selection.
 *
 * @return Returns 0 if the search string is found.  Otherwise,
 * STRING_NOT_FOUND_RC is returned..  On error, message is
 * displayed.
 *
 * @see qreplace
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 * @see quick_search
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
_command int qr,quick_replace(_str new_word="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   start_col := 0;
   word := get_quick_search_word(start_col);
   if ( word=='' ) {
      _beep();
      message(nls('No word at cursor'));
      return(STRING_NOT_FOUND_RC);
   }
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
   new_word = prompt(new_word, "Replace \""word"\" with", word);
   // make sure we find *this* word first
   p_col = start_col;
   // Note: removed 'p' option so we respect the default search option for wrapping
   status := replace(word,new_word,make_search_options(_default_option('s'))'n+<');
   return(status);
}

int _OnUpdate_quick_replace(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_ENABLED;
   }

   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      return(MF_GRAYED);
   }

   // see if we have a selection
   if (target_wid.select_active()) {
      // is it multi-line?  then don't do this, because it's sorta nonsensical anyway
      target_wid._get_selinfo(auto startCol, auto endCol, auto bufId, '', '', 0, 0, auto nOfLines);
      if (nOfLines != 1) {
         return MF_GRAYED;
      }
   }

   return MF_ENABLED;
}

/**
 * Highlight all occurrences of the word at cursor or selection.
 * Use clear_highlights command to clear all highlights or you
 * can also use Undo to remove the highlights.
 *
 * @return Returns 0 if the search string is found.  Otherwise,
 * STRING_NOT_FOUND_RC is returned..  On error, message is
 * displayed.
 *
 * @see find
 * @see gui_find
 * @see quick_search
 * @see clear_highlights
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
_command int quick_highlight() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   int start_col = 0;
   _str search_string = get_quick_search_word(start_col);
   if (search_string == '') {
      message(nls('No word at cursor'));
      return(STRING_NOT_FOUND_RC);
   }
   old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;

   _str search_options = make_search_options(_default_option('s'));
   typeless p; save_pos(p);
   top(); up();
   int matches = 0;
   int status = search(search_string, '@'search_options'#');
   if (!status) {
      for (;;) {
         ++matches;
         if (repeat_search()) break;
      }
   }
   typeless junk;
   old_search_string = search_string;
   save_search(junk, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   old_search_flags &= (~VSSEARCHFLAG_FINDHILIGHT); // don't carrying highlight to find-next
   set_find_next_msg("Find", search_string, search_options, old_search_range);
   restore_pos(p);
   if (matches == 0) {
      message(get_message(status));
   } else {
      message("Highlighted ":+matches:+" occurrence":+((matches>1)?"s":""));
   }
   return (status);
}

// Set the message to be displayed for find_next/find_prev commands
void set_find_next_msg(_str label = '', _str search_string = '', _str options = '', int range=VSSEARCHRANGE_CURRENT_BUFFER)
{
   old_search_message = label;
   if (search_string :!= '') {
      old_search_message = old_search_message:+' "':+search_string'"';
   }
   if (options:!= '') {
      old_search_message = old_search_message:+', ':+_get_search_options_label(options);
   }
   if (range != VSSEARCHRANGE_CURRENT_BUFFER) {
      old_search_message = old_search_message:+', ':+_get_search_range_label(range);
   }
}

/**
 * Show selection used for wrapping search in selection.
 *
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command void show_old_search_mark()
{
   if ( old_search_mark != '' ) {
      _str markid = _duplicate_selection('');
      _show_selection(_duplicate_selection(old_search_mark));
      _free_selection(markid);
   }
}

/**
 * Search buffer for all occurrences of search string.
 *
 * @param search_string Search string.
 * @param search_options Search options.
 * @param index_list Array of callbacks for each occurrence found.
 *
 * @return Returns number of matching occurrences in this buffer.
 *
 * @see search
 * @see repeat_search
 * @see find_index
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
int search_all(_str search_string, _str search_options, int index_list[])
{
   typeless p; save_pos(p);
   boolean search_backwards = ( pos( '-', search_options ) != 0 );
   boolean search_in_mark = ( pos( 'm', search_options, 1, 'I' ) != 0 );
   if ( search_backwards ) {
      if ( search_in_mark ) {
         _end_select(); _end_line();
      } else {
         bottom();
      }
   } else {
      if ( search_in_mark ) {
         _begin_select(); _begin_line();
      } else {
         top(); up();
      }
   }
   int i;
   int NofMatches = 0;
   int status = search( search_string, '@'search_options );
   if ( !status ) {
      for ( i = 0; i < index_list._length(); ++i ) {
         int index = index_list[i];
         if ( ( index != 0 ) && index_callable( index ) ) {
            if ( call_index( search_string, index ) ) {
               index_list[i] = 0;
            }
         }
      }
      ++NofMatches;
      status = repeat_search();
   }
   restore_pos(p);
   return NofMatches;
}

static void _init_markers()
{
   if (gIncSearchMarker > 0) {
      return;
   }
   gIncSearchMarker = _MarkerTypeAlloc();
   _MarkerTypeSetFlags(gIncSearchMarker, VSMARKERTYPEFLAG_AUTO_REMOVE);
}

static void _isearch_clear_markers()
{
   if ( gIncSearchMarker >= 0 ){
      _StreamMarkerRemoveAllType(gIncSearchMarker);
   }
}

// search viewable range
static void _isearch_highlight_window(_str search_string, _str search_options, boolean show_current)
{
   if (def_search_incremental_highlight == false) {
      return;
   }
   boolean search_selection = ((pos('M',upcase(search_options)) != 0) && select_active(''));
   int match_offset = show_current ? match_length('S') : -1;
   int match_len = show_current ? match_length() : -1;
   _init_markers();
   _isearch_clear_markers();

   int markerIndex;
   if (show_current) {
      // highlight current incremental match
      markerIndex = _StreamMarkerAdd(p_window_id, match_offset, match_len, true, 0, gIncSearchMarker, null);
      _StreamMarkerSetTextColor(markerIndex, CFG_INC_SEARCH_CURRENT);
   }

   typeless p; save_pos(p);
   int orig_mark = _duplicate_selection('');
   int view_mark = _alloc_selection();
   long d_offset_size;

   // create selection around lines in view
   _show_selection(view_mark);
   p_cursor_y = 0; 
   if (_on_line0()) {
      down();
   }
   _select_line(view_mark);
   p_cursor_y = p_client_height - 1; down(); _select_line(view_mark); _end_line();  d_offset_size = _QROffset();
   _begin_select(view_mark); _begin_line(); d_offset_size = d_offset_size - _QROffset();
   if ( d_offset_size < 0x04000 ) { // if (end - start) < threshold size then search region
      // highlight all visible matches
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
      int status = search( search_string, 'xv,'search_options:+'m+' );
      if (!status) {
         lastOffset := -1;
         for (;;) {
            int offset = match_length('S');

            // This tweak probably need to be put in repeat_search()
            if ( offset==lastOffset ) break;
            if (offset != match_offset) {
               markerIndex = _StreamMarkerAdd(p_window_id, offset, match_length(), true, 0, gIncSearchMarker, null);
               _StreamMarkerSetTextColor(markerIndex, CFG_INC_SEARCH_MATCH);
            }
            lastOffset = offset;
            if (repeat_search()) break;
         }
      }
      restore_search(s1, s2, s3, s4, s5);
   }
   restore_pos(p);
   _show_selection(orig_mark);
   _free_selection(view_mark);
}

