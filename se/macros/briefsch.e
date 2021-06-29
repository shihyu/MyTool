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
#include "markers.sh"
#import "clipbd.e"
#import "cua.e"
#import "docsearch.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "options.e"
#import "recmacro.e"
#import "search.e"
#import "stdprocs.e"
#import "se/search/SearchResults.e"
#endregion

/* The command SEARCH-CASE sets the default search case sensitivity. */
/* The RE_SEARCH command sets the default regular expression value. */
static int s_brief_match_color;
static int s_brief_match_marker;
static int s_brief_match_timer;
static int s_brief_match_index;
static typeless s_brief_match_start_time;

static const RE_SEARCHFLAGS= (VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE);

definit()
{
   s_brief_match_color = _AllocColor();
   s_brief_match_marker = _MarkerTypeAlloc();
   s_brief_match_timer = -1;
   s_brief_match_index = -1;
}

/**
 * Sets the default search pattern sensitivity to regular or non-regular
 * expression for command line search commands.  Does not affect the
 * <b>i_search</b> or <b>reverse_i_search</b> commands.  If no
 * argument is given the current setting is displayed on the command line
 * for editing.  Used in BRIEF emulation.
 *
 * @see replace
 * @see find
 * @see i_search
 * @see reverse_i_search
 * @see search_case
 * @see re_toggle
 * @see case_toggle
 * @see search_forward
 * @see search_backward
 * @see translate_forward
 * @see translate_backward
 * @see translate_again
 * @see search_again.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 *
 */
_command re_search(_str commandName='') name_info(','VSARG2_EDITORCTL)
{
   _str arg1=prompt(commandName,'',number2onoff(_default_option('s')&RE_SEARCHFLAGS));
   typeless re_on='';
   setonoff(re_on,arg1);
   _default_option('s',_default_option('s')&~(RE_SEARCHFLAGS));
   if (re_on) {
      _default_option('s',_default_option('s')|def_re_search_flags);
   }
}

void _brief_select_match_callback(_str orig_last_event)
{
   if ((last_event(null,true) != orig_last_event) || ((typeless)_time('b') - s_brief_match_start_time) >= 4000) {
      _kill_timer(s_brief_match_timer);
      _StreamMarkerRemove(s_brief_match_index);
      s_brief_match_timer = -1;
      s_brief_match_index = -1;
      refresh();
      return;
   }
}

void brief_select_match(_str mark='')
{
   if (def_persistent_select=='D' && def_leave_selected) return;

   if (s_brief_match_timer > 0) {
      _kill_timer(s_brief_match_timer);
      _StreamMarkerRemove(s_brief_match_index);
      s_brief_match_timer = -1;
      s_brief_match_index = -1;
   }
   typeless fg_color, bg_color;
   parse _default_color(CFG_SELECTION) with fg_color bg_color .;
   _default_color(s_brief_match_color, fg_color, bg_color, F_INHERIT_STYLE);
   s_brief_match_index = _StreamMarkerAdd(p_window_id, match_length('S'), match_length(), true, 0, s_brief_match_marker, null);
   _StreamMarkerSetTextColor(s_brief_match_index, s_brief_match_color);
   s_brief_match_start_time = _time('b');
   s_brief_match_timer = _set_timer(100, _brief_select_match_callback, last_event(null, true));
}

/**
 * Used in BRIEF emulation.  Repeats the last search performed by any
 * search command.  The string found is highlighted for 4 seconds or
 * until a key is pressed.
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
 * @see search_again_backward 
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
_command search_again() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   status := 0;
   maybe_deselect();
   status=find_next();
   if (!status && !_mffindActive(1) && !_mfrefActive(1)) {
      brief_select_match();
   }
}
/**
 * Used in BRIEF emulation.  Repeats the last search performed by any
 * search command in the opposite direction. 
 * The string found is highlighted for 4 seconds or until a key is pressed.
 *
 * @see replace
 * @see find
 * @see i_search
 * @see reverse_i_search
 * @see search_case
 * @see case_toggle
 * @see re_search
 * @see re_toggle
 * @see search_again
 * @see search_forward
 * @see translate_forward
 * @see translate_backward
 * @see translate_again
 * @see search_backward
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
_command search_again_backward() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   status := 0;
   maybe_deselect();
   status=find_prev();
   if (!status && !_mffindActive(1) && !_mfrefActive(1)) {
      brief_select_match();
   }
}
/**
 * <p>For help on regular expressions see <b>Regular Expressions</b>.</p>
 *
 * <p>Used in BRIEF emulation.  Prompts for a string to search forward for.
 * The <b>case_toggle</b> and <b>re_toggle</b> commands may be
 * used to set the default case sensitivity and pattern sensitivity for the
 * next search.  You may toggle regular expression searching, the case
 * sensitivity, searching within mark, incremental searching, and the
 * searching direction while you are being   prompted for the search
 * argument.  The following keys change there meaning when you are
 * being prompted for the search string:</p>
 *
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search
 * string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search
 * string</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * The key bound to the command <b>re_toggle</b>
 * will also toggle regular expression pattern
 * matching.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.  </dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * command <b>case_toggle</b> will also toggle the
 * case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within selection.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
 *
 * @see replace
 * @see find
 * @see i_search
 * @see reverse_i_search
 * @see search_case
 * @see case_toggle
 * @see re_search
 * @see re_toggle
 * @see search_backward
 * @see translate_forward
 * @see translate_backward
 * @see translate_again
 * @see search_again
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 *
 */
_command search_forward(_str options='') name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro('s'));
   if ( ! qsearch(options:+_search_default_options()) ) {
      brief_select_match();
   }

}
/**
 * <p>For help on regular expressions see <b>Regular Expressions</b>.</p>
 *
 * <p>Used in BRIEF emulation.  Prompts for a string to search backward
 * for.  The <b>case_toggle</b> and <b>re_toggle</b> commands may
 * be used to set the default case sensitivity and pattern sensitivity for the
 * next search.  You may toggle regular expression searching, the case
 * sensitivity, searching within mark, incremental searching, and the
 * searching direction while you are being   prompted for the search
 * argument.  The following keys change there meaning when you are
 * being prompted for the search string:</p>
 *
 * <dl>
 * <dt>Ctrl+R</dt><dd>Searches in reverse for next occurrence of search
 * string</dd>
 * <dt>Ctrl+S</dt><dd>Searches forward for next occurrence of search
 * string</dd>
 * <dt>Ctrl+T</dt><dd>Toggles regular expression pattern matching on/off.
 * The key bound to the command <b>re_toggle</b>
 * will also toggle regular expression pattern
 * matching.</dd>
 * <dt>Ctrl+W</dt><dd>Toggles word searching on/off.</dd>
 * <dt>Ctrl+C</dt><dd>Toggles case sensitivity.  The key bound to the
 * command <b>case_toggle</b> will also toggle the
 * case sensitivity.</dd>
 * <dt>Ctrl+M</dt><dd>Toggles searching within selection.</dd>
 * <dt>Ctrl+Q</dt><dd>Quotes the next character typed.</dd>
 * <dt>Ctrl+O</dt><dd>Toggles incremental search mode.</dd>
 * </dl>
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
 * @see search_again
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 *
 */
_command search_backward() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro('s'));
   search_forward('-');
}
/**
 * Used in BRIEF emulation.  Performs a search and replace in the
 * forward direction.  This command is identical to the <b>replace</b>
 * command except that if the current buffer has a selection, the search is
 * limited to the selection by default.  Another difference is that the
 * <b>translate_forward</b> command does not accept any arguments.
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
 * @see search_again
 * @see translate_backward
 * @see translate_again
 * @see search_backward
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 *
 */
_command translate_forward(_str old_direction='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   search('',_search_default_options():+old_direction);
   typeless junk='';
   save_search(junk,old_search_flags,junk);
   if ( init_qreplace(init_search_flags(old_search_flags|select_active())) ) {
      return 1;
   }
   _macro('m',_macro('s'));
   int status=qreplace(old_search_string,old_replace_string,old_search_flags);
   if ( select_active() ) {
      select_it(_select_type(),'','C');
   }
   return(status);

}
/**
 * Used in BRIEF emulation.  Performs a search and replace in the
 * backward direction.  This command is identical to the
 * <b>translate_forward</b> command except the search and replace is
 * in the backward direction.
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
 * @see search_again
 * @see translate_again
 * @see search_backward
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Search_Functions
 *
 */
_command translate_backward() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro('s'));
   return(translate_forward('-'));

}
/**
 * Toggles regular expression searching on/off.  Effects command line
 * style BRIEF emulation search commands. Used in BRIEF emulation.
 *
 * @see case_toggle
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 *
 */
_command void re_toggle() name_info(','VSARG2_EDITORCTL)
{
   _macro_delete_line();
   msg := "";
   if ((old_search_flags & RE_SEARCHFLAGS) || arg(1)!='') {
      old_search_flags&= ~(RE_SEARCHFLAGS);
      msg=nls('Regular expressions OFF');
      _default_option('s',_default_option('s')&~(RE_SEARCHFLAGS));
      _macro_call('re_toggle',1);
   } else {
      old_search_flags|= def_re_search_flags;
      msg=nls('Regular expressions ON');
      _default_option('s',_default_option('s')|def_re_search_flags);
      _macro_call('re_toggle');
   }
   message(msg);
}
/**
 * Toggles case sensitive searching on/off.  Effects command line style BRIEF emulation search commands.  Used in BRIEF emulation.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @see re_toggle
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 */
_command void case_toggle() name_info(','VSARG2_EDITORCTL)
{
   _macro_delete_line();
   msg := "";
   if ((old_search_flags & IGNORECASE_SEARCH) || arg(1)!='') {
      old_search_flags&= ~IGNORECASE_SEARCH;
      _macro_call('case_toggle',1);
      search_case('E');
      msg=nls('Case sensitivity ON');
   } else {
      old_search_flags|=IGNORECASE_SEARCH;
      _macro_call('case_toggle');
      search_case('I');
      msg=nls('Case sensitivity OFF');
   }
   message(msg);

}
/**
 * Used in BRIEF emulation.  Same as <b>gui_find</b> command except that the
 * search direction is initially backward.
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods
 *
 */
_command gui_find_backward() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|MARK_ARG2)
{
   _macro('m',_macro('s'));
   return(gui_find('-'));
}
/**
 * Used in BRIEF emulation.  Same as <b>gui_replace</b> command except that
 * the search direction is initially backward.
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods
 */
_command gui_replace_backward() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro('s'));
   return(gui_replace('-'));
}

