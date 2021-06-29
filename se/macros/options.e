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
#include "vsevents.sh"
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "commentformat.e"
#import "cutil.e"
#import "doscmds.e"
#import "eclipse.e"
#import "main.e"
#import "recmacro.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "cfg.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * Sets the cursor shape for insert mode, replace mode, virtual insert mode, 
 * and virtual replace mode.  Top and bottom refer to character vertical scan 
 * lines.  The cursor is said to be in virtual space if it is past the end 
 * of a line or in the middle of a tab character.  To make this function 
 * independent of hardware, this function maps the numbers 1 to 1000 to the 
 * actual number of vertical scan lines in a character.  
 * <p>
 * If no parameters are 
 * specified, the current settings are placed on the command line for editing.  
 * If the -v option is given, all options that follow are ignored and two 
 * vertical cursor shapes are selected.  A thin vertical cursor for insert 
 * mode and a fat vertical cursor for replace mode.
 * 
 * @example
 * <pre>
 * <i>cmdline</i> is a string in the format: 
 *          [-v] <i>ins_top ins_bot rep_top rep_bot vins_top vins_bot vrep_top vrep_bottom</i>
 * </pre>
 * @categories Miscellaneous_Functions
 */
_command void cursor_shape(_str options='')
{
   _str arg1=prompt(options,'',_cursor_shape());
   _cursor_shape(arg1);

}
#if 0
_command color_set(_str options='')
{
   arg1=prompt(options,'',_color_set())
   _color_set(arg1)
   if ( ! rc ) {
      one_window()   /* Reset the colors for the menu bar. */
   }

}
#endif
/**
 * Sets scroll style to center or smooth scrolling.  If no argument is given, 
 * the current value is placed on the command line for editing.  
 * <i>number</i> specifies how close the cursor may get to the top or 
 * bottom of the window before scrolling occurs, default is 0.
 * 
 * @param cmdline is a string in the format: [ C | V | H | S [<i>number</i>] ]
 * 
 * @example
 * <dl>
 * <dt>C</dt><dd>Specifies center scrolling when top or bottom of 
 * window is reached.</dd>
 * <dt>C 0</dt><dd>Specifies center scrolling when top or bottom of 
 * window is reached.</dd>
 * <dt>C 3</dt><dd>Specifies center scrolling when cursor is within 4 
 * lines of the top or bottom of the window.</dd>
 * <dt>S 2</dt><dd>Specifies smooth scrolling when cursor is within 3 
 * lines of the top or bottom of the window.</dd>
 * </dl>
 * 
 * @categories CursorMovement_Functions
 * 
 */ 
_command void scroll_style(_str cmdline='')
{
   _str arg1=prompt(cmdline,'',_scroll_style());
   arg1=upcase(strip(arg1));
   _scroll_style(arg1);
   parse arg1 with auto style auto when_vscroll;
   if (length(style)==1 && pos(style,"CSHV")) {
      _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_OPTIONS,VSCFGPROFILE_OPTIONS_VERSION,"scroll_style",style);
      if (isinteger(when_vscroll)) {
         _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_OPTIONS,VSCFGPROFILE_OPTIONS_VERSION,"when_vscroll",when_vscroll);
      }
   }
}

#if 0
_command select_style(_str cmdline="")
{
   parse cmdline with arg1 arg2 arg3 arg4 . ;
   param=upcase(prompt(arg1,'',def_select_style))
   if ( verify(param,'ECNI') ) {
      message nls('Invalid setting')
      return(1)
   } else {
      def_select_style=strip(param)
      if ( arg2!='' ) {
         def_persistent_select=arg2
         def_deselect_paste=arg3
         if ( arg4=='.' ) {
            def_advanced_select=''
         } else {
            def_advanced_select=arg4
         }
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return(0)
   }
}
#endif

/**
 * <p>When <b>auto_restore</b> is on, the safe_exit command (Alt+F4 or "File", "Exit") will save 
 * the window configuration, buffer positions, command retrieve buffer, clipboards, bookmarks, 
 * and other miscellaneous data in the directory specified by the environment variable VSLICKRESTORE 
 * before exiting the editor.  The next time the editor is invoked, SlickEdit will automatically 
 * resume your last edit session by restoring the window configuration, buffer positions, command 
 * retrieve buffer, clipboards, bookmarks, and other miscellaneous data.</p>
 * 
 * <p>If SlickEdit is invoked with a file specification, the window and buffer positions are not restored.</p>
 * 
 * <p>If the environment variable VSLICKRESTORE does not exist, the auto_restore data is saved in the
 * users configuration directory.  The user's configuration directory is pointed to by the 
 * SLICKEDITCONFIG environment variable.</p>
 *  
 * @categories Miscellaneous_Functions
 */
_command void auto_restore(_str onoff="")
{
   _str arg1=prompt(onoff,'',number2onoff(def_auto_restore));
   tmp := false;
   setonoff(tmp,arg1);
   def_auto_restore=(int)tmp;
   _config_modify_flags(CFGMODIFY_DEFVAR);

}
_str _prepare_word_chars(_str word_chars)
{
   return(word_chars);
}
int _check_word_chars(_str word_chars)
{
   if (_first_char(word_chars)=='~' || _first_char(word_chars)=='^') {
      _message_box("Word characters can not start with ('~') or ('^').  Use a backslash if necessary to escape the characters tilde ('~') or carot ('^')");
      return(1);
   }
   status := pos('['word_chars']','',1,'r');
   if (status<0) {
      _message_box("Word characters must be a valid character set specification for a regular expression.  Use a backslash if necessary to escape the characters dash ('-') or backslash ('\\')");
      return(1);
   }
   return(0);
}
/**
 * Allows you to specify the characters in a word for the current buffer.  
 * These characters affect word commands such as <b>next_word</b> or 
 * <b>prev_word</b> and the characters used for word searching.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void word_chars(_str wordChars="") name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str arg1=prompt(wordChars,'',_prepare_word_chars(p_word_chars));
   if(_check_word_chars(arg1)){
     return;
   }
   p_word_chars=arg1;
   update_format_line();
}

/**
 * If no parameters are specified the current cache size values are placed on the command line for editing.
 * <p>
 * The <i>buffer_ksize </i>parameter sets the maximum size of the text buffer cache.  If <i>buffer_ksize</i> is 
 * less than zero, the cache will grow until no memory is available.  In most cases, SlickEdit's cache is 
 * 3 times faster than operating system cache.  This means that you will want SlickEdit's buffer cache size 
 * small enough that the operating system cache is not used.  When the cache is full, text is written to a spill 
 * file "$slk.<i>nnn</i>" where <i>nnn</i> is a number.
 * <p>
 * The <i>state_ksize</i> parameter specifies the maximum amount of swappable state file data (parts of 
 * "vslick.sta" to be kept in memory. 
 * -1 specifies no limit.  The -ST invocation option may be used 
 * to specify the state cache size.  Modifying the state cache 
 * size may not take effect until the editor is reinvoked.  When 
 * you specify 0 as the argument to the -ST invocation , this 
 * specifies to preload the entire state file and close the file 
 * handle.  This function does NOT support the "-ST 0" feature. 
 * 
 * @param cmdline is a string in the format: <i>buffer_ksize</i> [<i>state_ksize</i> ]
 * @categories File_Functions
 */
_command void cache_size(_str param="", ...)
{
   if ( arg()>2 ) {
      if ( param=='' ) {
         message(nls('Invalid running cache size'));
         return;
      }
      param :+= " "arg(3) " "arg(4) " "arg(5) " "arg(6);
   } else if ( param=='' ) {
      param=prompt(param,'',_cache_size());
   }
   _cache_size(param);

}
/**
 * When <i>path</i> is given, the default spill file path is set to 
 * <i>path</i>.  If the spill file has already been created due to 
 * insufficient memory, this function has no effect on this session.  The 
 * current spill file path is displayed on the command line if no 
 * arguments are given.
 * 
 * @categories File_Functions
 * 
 */ 
_command spill_file_path(_str path="")
{
   _str arg1=prompt(path,'',_spill_file_path());
   _spill_file_path(arg1);
   return(0);

}

defeventtab _justify_form;
void _justifyu.lbutton_up()
{
   _justifyuspace.p_enabled = true;
}
void _justifyj.lbutton_up()
{
   _justifyuspace.p_enabled = false;
}
void _justifyn.lbutton_up()
{
   _justifyuspace.p_enabled = false;
}
/**
 * Displays <b>Justification dialog box</b>.  See <b>justify</b> function 
 * for information on <i>justify_option</i>.
 * 
 * @return Returns '' if user cancelled the dialog box.  Returns the justify 
 * option selected by the user.  You may use the <b>justify</b> function to set 
 * the justification based on this return value.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_justifyok.on_create(typeless word_wrap_style=0)
{
   _justifyuspace.p_value = (word_wrap_style&ONE_SPACE_WWS);

   if ( word_wrap_style&JUSTIFY_WWS ) {
      //ch='Y'
      _justifyj.p_value = 1;
   } else if ( word_wrap_style&STRIP_SPACES_WWS ) {
      //ch='U';
      _justifyu.p_value = 1;
   } else {
      //ch='N'
      _justifyn.p_value = 1;
   }

}

_justifyok.lbutton_up()
{
   result := "";
   if (_justifyu.p_value) {
      if (_justifyuspace.p_value) {
         result ='1';
      } else {
         result = 'U';
      }
   }
   if (_justifyj.p_value) {
      result = 'Y';
   }
   if (_justifyn.p_value) {
      result = 'N';
   }
   p_active_form._delete_window(result);
}

/**
 * <p>The <b>gui_justify</b> command affects the way the editor handles 
 * spaces between words when formatting paragraphs.  By default, the 
 * <b>reflow_paragraph</b> and <b>reflow_selection</b> commands place one space 
 * between words accept after the punctuation characters ".?!" which get two 
 * spaces.</p>
 * 
 * <p>SlickEdit provides three justification styles:</p> 
 * 
 * <dl>
 * <dt>Justified</dt><dd>Full justification.  Left and right edges of text will 
 * align exactly at margins.</dd>
 * <dt>Left and Respace</dt><dd>(Default) Left justification with space character 
 * reformatting.  One space is placed between words except after the punctuation 
 * characters ".?!" which get two spaces.</dd>
 * <dt>Left</dt><dd>Left justification with respect for space characters between 
 * words.  This setting requires the save options to be set such that trailing spaces are
 * not stripped when a buffer is saved.</dd>
 * </dl>
 * 
 * @see justify
 * 
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command void gui_justify() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   typeless result = show('-modal _justify_form',p_word_wrap_style);
   if (result != '') {
      justify(result);
      _macro('m',_macro('s'));
      _macro_call('justify', result);
   }
}
/**
 * The <b>justify</b> command affects the way the editor handles spaces 
 * between words when formatting paragraphs.  By default, the 
 * <b>reflow_paragraph</b> and <b>reflow_selection</b> commands place one space 
 * between words except after the punctuation characters, ".?!", which get two 
 * spaces.
 * 
 * <dl>
 * <dt>'Y'</dt><dd>Full justification.  Left and right edges of text will align 
 * exactly at margins.</dd>
 * <dt>'U'</dt><dd>(Default) Left justification with space character reformatting.  
 * One space is placed between words except after the punctuation characters 
 * ".?!" which get two spaces.</dd>
 * <dt>'N'</dt><dd>Left justification with respect for space characters between 
 * words.  This setting requires the save options to be set such
 * that trailing spaces are
 * not stripped when a buffer is saved.</dd>
 * </dl>
 * 
 * <p>The <b>justify</b> command only affects the current buffer.
 * 
 * <p>IMPORTANT: If <b>justify</b> is set to "N", the save options should be 
 * set to not strip spaces at the end of each line when a file is saved.</p>
 * 
 * @see word_wrap
 * @see gui_justify
 * 
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command justify(_str options="") name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   ch := upcase(options);
   if ( ch=='' ) {
      if ( p_word_wrap_style&JUSTIFY_WWS ) {
         ch='Y';
      } else if ( p_word_wrap_style&STRIP_SPACES_WWS ) {
         if (p_word_wrap_style&ONE_SPACE_WWS) {
            ch='1';
         }else{
            ch='U';
         }
      } else {
         ch='N';
      }
      ch=upcase(prompt('','',ch));
   }
   if ( ch=='Y' ) {
      p_word_wrap_style=(p_word_wrap_style&~(JUSTIFY_WWS|STRIP_SPACES_WWS)) | JUSTIFY_WWS;
   } else if ( ch=='U' ) {
      p_word_wrap_style= (p_word_wrap_style & ~(JUSTIFY_WWS|ONE_SPACE_WWS))|STRIP_SPACES_WWS;
   } else if ( ch=='1' ) {
      p_word_wrap_style= (p_word_wrap_style & ~(JUSTIFY_WWS))|ONE_SPACE_WWS|STRIP_SPACES_WWS;
   } else if ( ch=='N' ) {
      p_word_wrap_style=(p_word_wrap_style & ~(JUSTIFY_WWS|STRIP_SPACES_WWS));
   } else {
      message(nls('Invalid option'));
      return(1);
   }
   update_format_line();
   return(0);
}
int _OnUpdate_word_wrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (p_word_wrap_style & WORD_WRAP_WWS) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles word wrap on/off.  See <b>word_wrap</b> command for 
 * more information.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void word_wrap_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   param := "";
   if (p_word_wrap_style&WORD_WRAP_WWS) {
      param='n';
   } else {
      param='y';
   }
   _macro_call('word_wrap',param);
   word_wrap(param);
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_WORD_WRAP_TOGGLE);
   }
}
static void yesno_default_option(_str option,_str value)
{
   typeless number=0;
   _str arg1=prompt(value,'',number2yesno(_default_option(option)));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return;
   }
   _default_option(option,number);
}
/** 
 * Determines whether horizontal scroll bars are displayed on edit windows.
 * @categories Miscellaneous_Functions
 */
_command void display_hscroll(_str yesno="")
{
   yesno_default_option('H',yesno);
}

/** 
 * Determines whether vertical scroll bars are displayed on edit windows.
 * @categories Miscellaneous_Functions
 */
_command void display_vscroll(_str yesno="")
{
   yesno_default_option('V',yesno);
}

/** 
 * Determines whether a top of line indicator is displayed in edit windows.
 * @categories Miscellaneous_Functions
 */
_command void display_top(_str yesno="")
{
   yesno_default_option('T',yesno);
}
/** 
 * Determines whether the mouse is hidden when characters are typed into an 
 * edit window or editor control.  When no parameters are given, the current 
 * value is displayed on the command line.
 *
 * @categories Mouse_Functions
 * 
 */
_command void hide_mouse(_str yesno="")
{
   yesno_default_option('P',yesno);
}
/**
 * Determines whether pressing and releasing the Alt key activates the menu 
 * bar.  If no argument is specified, you are prompted for one.
 * @categories Menu_Functions
 */
_command void alt_menu(_str yesno="")
{
   yesno_default_option('A',yesno);
}
/**
 * Sets the default search case sensitivity used by all search commands to 
 * exact or ignore case.  If no argument is given, the current setting is 
 * displayed on the command line for editing.  'E' specifies case sensitive 
 * searching by default. 'I' specifies case insensitive searching by default.
 * 
 * @categories Search_Functions
 * 
 */ 
_command void search_case(_str option="")
{
   _str arg1=prompt(option,'',_search_case());
   _search_case(arg1);
}
/**
 * Sets the spaces between the left edge of the window and the text in 
 * twips.  This option has no effect when bitmaps are display in the left 
 * edge of the window.  All edit windows and editor controls are effected 
 * by this value.  If no argument is given, the current value is displayed 
 * on the command line.
 * 
 * @categories Edit_Window_Functions, Editor_Control_Functions, Window_Functions
 * 
 */ 
_command void wleft_margin(_str marginCol="")
{
   _str arg1=prompt(marginCol,'',_default_option('L'));
   if (!isinteger(arg1) ) {
      message('Invalid number');
      return;
   }
   _default_option('L',arg1);
}
/**
 * If yes, the editor attempts to keep the cursor within the margins when 
 * entering text, moving the cursor, and deleting characters.  The 
 * word_wrap command only affects the current buffer.  To set the 
 * default word wrap style for specific file extension, use the Extension 
 * Options dialog box ("Tools", "Configuration..", "File Extension 
 * Setup...", select the Word Wrap tab).
 * 
 * @see word_wrap_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command word_wrap(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless number=0;
   _str arg1=prompt(yesno,'',number2yesno(p_word_wrap_style&WORD_WRAP_WWS));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return(1);
   }
   p_word_wrap_style= (p_word_wrap_style& ~WORD_WRAP_WWS) | (number *2);
    update_format_line();
    return(0);
}
/**
 * Toggles the comment wrap option to preserve width on existing comments
 * on/off. See <b>comment_wrap_preserve_width</b> command for more information.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void comment_wrap_preserve_width_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   param := "";
   currentState := _GetCommentWrapFlags(CW_AUTO_OVERRIDE);
   if (currentState) {
      param='n';
   } else {
      param='y';
   }
   _macro_call('comment_wrap_preserve_width',param);
   comment_wrap_preserve_width(param);
}
/**
 * If yes, the editor uses the preserve width on existing
 * comments option when performing comment wrapping. To set
 * the comment wrap style for a specific language mode, use the Options
 * dialog ("Document", "[Language] Options...]", "Comments".
 * 
 * @see comment_wrap_preserve_width_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command comment_wrap_preserve_width(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   currentState := _GetCommentWrapFlags(CW_AUTO_OVERRIDE);
   typeless number=0;
   _str arg1=prompt(yesno,'',number2yesno(currentState ? 1 : 0));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return(1);
   }
   _SetCommentWrapFlags(CW_AUTO_OVERRIDE, (number == 1 ? true : false), p_LangId);
    update_format_line();
    return(0);
}
/**
 * Toggles comment wrap on/off.  See <b>comment wrap</b>
 * command for more information.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void comment_wrap_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   currentState := _GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP);
   param := "";
   if (currentState) {
      param='n';
   } else {
      param='y';
   }
   _macro_call('comment_wrap',param);
   comment_wrap(param);
}
/**
 * If yes, the editor attempts to automatically wrap 
 * block comments.  To set the the comment wrap style for a specific language mode, 
 * use the Options dialog ("Document", "[Language] Options...]", "Comments".
 * 
 * @see comment_wrap_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command comment_wrap(_str yesno="")  name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   currentState := _GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP);
   typeless number=0;
   _str arg1=prompt(yesno,'',number2yesno(currentState ? 1 : 0));
   if ( setyesno(number,arg1) ) {
      message('Invalid option');
      return(1);
   }
    _SetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP, (number == 1 ? true : false));

    update_format_line();
    return(0);
}
int _OnUpdate_comment_wrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   lang := p_LangId;
   if (!commentwrap_isSupportedLanguage(lang)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid._ConcurProcessName()!=null) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (_GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP)) {
      return(MF_CHECKED|MF_ENABLED);
   } else {
      return(MF_UNCHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_GRAYED);
}
int _OnUpdate_gui_reflow_comment(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || !target_wid._isEditorCtl() || target_wid.p_readonly_mode) {
      return(MF_GRAYED);
   }
   if (_in_comment(false)
       // reflow_comment doesn't support all languages
       && _reflow_comment_isSupportedLanguage(CW_saveCurrentLang())
        ) {

      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
int _OnUpdate_reflow_comment(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_gui_reflow_comment(cmdui,target_wid,command);
}

int _OnUpdate_indent_with_tabs_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (p_indent_with_tabs) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/** 
 * Toggles indenting with tabs on or off for the current buffer.
 * 
 * @see indent_with_tabs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void indent_with_tabs_toggle() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   _macro_call('indent_with_tabs', number2yesno(!p_indent_with_tabs));
   p_indent_with_tabs=!p_indent_with_tabs;
   if (!_QReadOnly()) {
      update_format_line();
   }
   if (p_indent_with_tabs) {
      message("Indent with tabs ON");
   } else {
      message("Indent with tabs OFF");
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_INDENT_TABS_TOGGLE);
   }
}
/**
 * If yes, the indent caused by invoking an ENTER key command or reformat 
 * paragraph command indents with tab characters.  The indent_with_tabs command 
 * only affects the current buffer.
 * 
 * @see indent_with_tabs_toggle
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command indent_with_tabs(_str yesno="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   bool indent_with_tabs;

   _str arg1=prompt(yesno,'',number2yesno(p_indent_with_tabs));
   if ( ! setyesno(indent_with_tabs,arg1) ) {
      p_indent_with_tabs= indent_with_tabs;
   }
   update_format_line();

}
/**
 * Displays the message "Execute write-state to save the configuration.".
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void write_state_message()
{
   message(nls('Execute write-state to save the configuration.'));

}

_command void adaptive_format_toggle() name_info(','VSARG2_REQUIRES_EDITORCTL)
{

   if (_isEditorCtl()) {
      lang := p_LangId;
      if (lang != '') {
         currentState := LanguageSettings.getUseAdaptiveFormatting(lang);
         _macro_call('adaptive_format_set_adaptive_on', !currentState);
         adaptive_format_set_adaptive_on(!currentState);
      }
   } 

}

int _OnUpdate_adaptive_format_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   lang := p_LangId;
   if (LanguageSettings.getUseAdaptiveFormatting(lang)) {
      return(MF_CHECKED|MF_ENABLED);
   } else {
      return(MF_UNCHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_GRAYED);
}

/**
 * Sets the maximum number of undoable steps for the current buffer.  A 
 * value of 0 for <i>Nofsteps</i> turns undo off.  The range of 
 * <i>Nofsteps</i> is 0..32767.  This command is a simple front end to 
 * the <b>p_undo_steps</b> property.
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command undo_steps(_str numSteps="")
{
   _str arg1=prompt(numSteps,'',p_undo_steps);
   typeless steps=0;
   parse arg1 with steps ;
   if ( ! isinteger(steps)) {
      message(nls('Invalid options'));
      return 1;
   }
   p_undo_steps=steps;
   return(0);
}
/** 
 * Sets the delay before a prefix key is displayed in 10ths of a second.  The 
 * prefix key is not displayed if the next key is pressed before the delay 
 * specified by <i>tenths_of_second</i>.  If no parameters are specified, the 
 * current key message delay is displayed.
 * 
 * @categories Keyboard_Functions
 * 
 */
_command void keymsg_delay(_str tenths_of_second="")
{
   _str arg1=prompt(tenths_of_second,'',get_event('D'));
   if ( ! isinteger(arg1) ) {
     message(nls("Specify number"));
     return;
   }
   get_event('D'arg1);

}

/** 
 * Determines the key bindings for all menu items on the SlickEdit 
 * menu bar.
 * 
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see mou_show_menu
 * @see show
 * 
 * @categories Menu_Functions
 * 
 */
_command void menu_mdi_bind_all() name_info(','VSARG2_REQUIRES_MDI)
{
   // Could not put menu_mdi_bind_all in "menu.e" because of order of loading
   // in "addons.e".  menu_mdi_bind_all must exist when "windefs.e" is run.
   if (_cur_mdi_menu=="") {
      return;
   }
   if(_no_mdi_bind_all) return;
   message('Setting menu bindings...');
   int menu_handle=_mdi.p_menu_handle;
   int menu_index=find_index(_cur_mdi_menu,oi2type(OI_MENU));
   //_menu_bind_all(menu_handle,menu_index,_default_keys,'');
   //_menu_bind_fileman();
   menu_modified:=_menu_bind_emulation();
   clear_message();
   if (menu_modified) {
      _set_object_modify(menu_index);
   }
   _DebugUpdateMenu();
}

void _set_object_modify(int index)
{
   if (!index) return;
   typeless ff=name_info(index);
   if (!isinteger(ff)) ff=0;
   ff|=FF_MODIFIED;
   if (ff & FF_SYSTEM) {
       _config_modify_flags(CFGMODIFY_SYSRESOURCE);
    } else {
       _config_modify_flags(CFGMODIFY_RESOURCE);
   }
   set_name_info(index,ff);
}

static bool default_keys_has_binding(_str k) {
   k = name2event(k);
   root := _default_keys;
   mode := _default_keys;
   count := 0;
   maxcount := 6;
   index := 0;

   for (;;) {
      index=eventtab_index(root,mode,event2index(k));
      if ( name_type(index)== EVENTTAB_TYPE && count!=maxcount ) {
         root=index;mode=index;
         count++;
      } else {
         break;
      }
   }
   return (index > 0);
}

void _eventtab_modify_mdi_menu_updater(typeless keytab, typeless event)
{
   menu_mdi_bind_all();
}
static _str maybe_rebind_menu_keys(_str orig_caption)
{
   caption := stranslate(orig_caption,"","&");
   dislikesHotkeys := _isLinux() && get_xdesktop_session_name() == 'unity';

   if (caption=="View") {
      if (!default_keys_has_binding('A-V')) {
         return "&View";
      } else if (!default_keys_has_binding('A-I')) {
         return "V&iew";
      }
   } else if (caption=="Tools") {
      if (!default_keys_has_binding('A-T')) {
         return "&Tools";
      } else if (!default_keys_has_binding('A-O')) {
         return "T&ools";
      }
   } else if (caption=="Document" && dislikesHotkeys) {
      // Since we may have removed the users hot key letter
      if (!default_keys_has_binding('A-C')) {
         return "Do&cument";
      }
   }
   if (!dislikesHotkeys) {
      return orig_caption;
   }
   _str ch;
   // Don't want to conflict with "Debug" caption
   if (caption!='Document') {
      // Check if the first letter has a binding
      ch=upcase(substr(caption,1,1));
      if (isalpha(ch)) {
         // First letter doesn't have a binding. We are done.
         if (!default_keys_has_binding('A-':+ch)) {
            return '&'caption;
         }
      }
   }
   // Try the letter the user has chosen
   j := pos("&",orig_caption);
   if (j) {
      ch=upcase(substr(orig_caption,j+1,1));
      if (!default_keys_has_binding('A-':+ch)) {
         // Users caption is fine.
         return orig_caption;
      }
   }
   if (dislikesHotkeys) {
      // Must strip hot key letter due to users key binding
      return caption;
   }
   // Leave Users caption alone
   return orig_caption;
}

static bool _menu_bind_emulation()
{
   int menu_handle=_mdi.p_menu_handle;
   int menu_index=find_index(_cur_mdi_menu,oi2type(OI_MENU));

   // Find View menu so we can be more selective about selection
   // character.
   flags := 0;
   caption := "";
   int i,j=0,Nofitems=_menu_info(menu_handle);
   menu_modified := false;
   for (i=0;i<Nofitems;++i) {
      _menu_get_state(menu_handle,i,flags,"P",caption);
      // IF the selection character is on the V or I
      newcaption := maybe_rebind_menu_keys(caption);

      if (newcaption !='' && newcaption:!= caption) {
         _menu_set_state(menu_handle,i,flags, "P", newcaption);
         menu_modified=true;
      }
   }

   // Force a redraw on this menu.
   first := 0;
   child := 0;
   _menu_info(menu_handle,'r');
   if (menu_index) {
      // Update the View menu resource caption
      for (first=child=menu_index.p_child;child;) {
         newcaption := maybe_rebind_menu_keys(child.p_caption);
         if (newcaption !='' && newcaption:!= child.p_caption) {
            child.p_caption = newcaption; 
            menu_modified=true;
         }
         child=child.p_next;
         if (child==first) break;
      }
   }
   return menu_modified;
}


static _str diffreport(_str r, _str propName, typeless actual, typeless configured)
{
   if (configured == "") {
      return r :+ '<li><b>'propName'</b>: 'actual;
   } else {
      return r :+ '<li><b>'propName'</b>: 'actual' (default setting is 'configured')</li>';
   }
}

static bool tabs_same(_str t1, _str t2)
{
   txt := "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tX";

   old_tabs := p_tabs;
   p_tabs = t1;
   t1r := expand_tabs(txt);
   p_tabs = t2;
   t2r := expand_tabs(txt);
   p_tabs = old_tabs;

   return t1r._length() == t2r._length();
}

static _str nicebool(bool b)
{
   return b ? "Yes" : "No";
}

static _str nicebes(int b)
{
   switch (b) {
   case BES_BEGIN_END_STYLE_2:
	  return "Next Line (2)";
   case BES_BEGIN_END_STYLE_3:
	  return "Next Line Indented (3)";
   default:
	  return "Same Line (1)";
   }
}

static _str nicecase(int c)
{
   switch (c) {
   case WORDCASE_CAPITALIZE:
	  return "Capitalize";
   case WORDCASE_LOWER:
	  return "Lower";
   case WORDCASE_UPPER:
	  return "Upper";
   default:
	  return "Preserve";
   }
}

/**
 * Makes a string report of the differences from defaults of 
 * some of the most important per-buffer, or the ones that 
 * adaptive formatting could have changed. 
 */
static _str diff_from_defaults()
{
   rv := "";
   lang := p_LangId;

   ltabs := LanguageSettings.getTabs(lang, p_tabs);
   if (!tabs_same(p_tabs,ltabs)) {
      rv = diffreport(rv, 'Tabs', '"'p_tabs'"', '"'ltabs'"');  
   }

   lsi := LanguageSettings.getSyntaxIndent(lang, p_SyntaxIndent);
   if (lsi != p_SyntaxIndent) {
      rv = diffreport(rv, 'Syntax Indent', p_SyntaxIndent, lsi);
   }

   iwt := LanguageSettings.getIndentWithTabs(lang, p_indent_with_tabs);
   if (iwt != p_indent_with_tabs) {
      rv = diffreport(rv, 'Indent With Tabs', nicebool(p_indent_with_tabs), 
					  "");
   }

   bes := LanguageSettings.getBeginEndStyle(lang, p_begin_end_style);
   if (bes != p_begin_end_style) {
	  rv = diffreport(rv, 'Begin/End Style', nicebes(p_begin_end_style),
					  nicebes(bes));
   }

   icfs := LanguageSettings.getIndentCaseFromSwitch(lang, p_indent_case_from_switch);
   if (icfs != p_indent_case_from_switch) {
	  rv = diffreport(rv, 'Indent Case From Switch', nicebool(p_indent_case_from_switch),
					  "");
   }

   pp := LanguageSettings.getPadParens(lang, p_pad_parens);
   if (pp != p_pad_parens) {
	  rv = diffreport(rv, 'Pad Parens', nicebool(p_pad_parens), "");
   }

   nsbp := LanguageSettings.getNoSpaceBeforeParen(lang, p_no_space_before_paren);
   if (nsbp != p_no_space_before_paren) {
	  rv = diffreport(rv, 'Space Before Control Statement Parens', nicebool(!p_no_space_before_paren), "");
   }

   kc := LanguageSettings.getKeywordCase(lang, p_keyword_casing);
   if (kc != p_keyword_casing) {
	  rv = diffreport(rv, 'Keyword Casing', nicecase(p_keyword_casing), nicecase(kc));
   }

   tc := LanguageSettings.getTagCase(lang, p_tag_casing);
   if (tc != p_tag_casing) {
	  rv = diffreport(rv, 'Tag Casing', nicecase(p_tag_casing), nicecase(tc));
   }

   ac := LanguageSettings.getAttributeCase(lang, p_attribute_casing);
   if (ac != p_attribute_casing) {
	  rv = diffreport(rv, 'Attribute Casing', nicecase(p_attribute_casing), nicecase(ac));
   }

   vc := LanguageSettings.getValueCase(lang, p_value_casing);
   if (vc != p_value_casing) {
	  rv = diffreport(rv, 'Value Casing', nicecase(p_value_casing), nicecase(vc));
   }

   hvc := LanguageSettings.getHexValueCase(lang, p_hex_value_casing);
   if (hvc != p_hex_value_casing) {
	  rv = diffreport(rv, 'Hex Value Casing', nicecase(p_hex_value_casing), nicecase(hvc));
   }

   return rv;
}

int _OnUpdate_report_changed_per_document_settings(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   } else if (diff_from_defaults() != "") {
      return MF_ENABLED|MF_UNCHECKED;
   }

   return MF_GRAYED|MF_UNCHECKED;
}

_command void report_changed_per_document_settings() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   rep := diff_from_defaults();

   if (rep == "") {
      message("No document settings differ from language settings.");
   } else {
		rep = "<ul>" :+ rep :+ "</ul>";
		rep = "<h3>Current file settings that differ from the "_LangId2Modename(p_LangId)" Defaults</h3>"rep;
      if (LanguageSettings.getUseAdaptiveFormatting(p_LangId)) {
         rep :+= "<br>Adaptive formatting is enabled.";
      }
      show("-modal _per_doc_settings_diffs_form", rep);
   }
}

defeventtab _per_doc_settings_diffs_form;

void _ctl_ok.on_create(_str text)
{
   ctlminihtml1.p_text = text;
   if (LanguageSettings.getUseAdaptiveFormatting(_mdi.p_child.p_LangId)) {
      _ctl_revert_settings.p_enabled = false;
   }
}

void _ctl_ok.lbutton_up()
{
   p_active_form._delete_window(IDOK);
}

void _per_doc_settings_diffs_form.ESC()
{
   p_active_form._delete_window(IDOK);
}

void _ctl_revert_settings.lbutton_up()
{
   bi := _mdi.p_child;
   lang := bi.p_LangId;

   bi.p_tabs = LanguageSettings.getTabs(lang);
   bi.p_SyntaxIndent = LanguageSettings.getSyntaxIndent(lang);
   bi.p_indent_with_tabs = LanguageSettings.getIndentWithTabs(lang);
   bi.p_begin_end_style = LanguageSettings.getBeginEndStyle(lang);
   bi.p_indent_case_from_switch = LanguageSettings.getIndentCaseFromSwitch(lang);
   bi.p_pad_parens = LanguageSettings.getPadParens(lang);
   bi.p_no_space_before_paren = LanguageSettings.getNoSpaceBeforeParen(lang);
   bi.p_keyword_casing = LanguageSettings.getKeywordCase(lang);
   bi.p_tag_casing = LanguageSettings.getTagCase(lang);
   bi.p_attribute_casing = LanguageSettings.getAttributeCase(lang);
   bi.p_value_casing = LanguageSettings.getValueCase(lang);
   bi.p_hex_value_casing = LanguageSettings.getHexValueCase(lang);

   p_active_form._delete_window(IDOK);
}

