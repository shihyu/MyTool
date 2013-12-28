////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50466 $
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
#include "alias.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/alias/AliasFile.e"
#import "se/tags/TaggingGuard.e"
#import "aliasedt.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "c.e"
#import "clipbd.e"
#import "codehelp.e"
#require "codehelputil.e"
#import "codetemplate.e"
#import "compile.e"
#import "commentformat.e"
#import "context.e"
#import "cua.e"
#import "cutil.e"
#import "dir.e"
#import "files.e"
#import "get.e"
#import "hotspots.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "recmacro.e"
#import "savecfg.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;
using se.alias.AliasFile;

/*   See help on ALIAS command */

/*
You alias file needs to have the aliases below defined in it.

functioncomment( fname "Function Name:"
                 )
                /*
                 *Function Name:%(fname)
                 *
                 *Parameters:%\c
                 *
                 *Description:
                 *
                 *Returns:
                 *
                 */

filecomment /*******************************************************************
  *
  *    DESCRIPTION:%\c
  *
  *    AUTHOR:
  *
  *    HISTORY:
  *
  *    DATE:%\d
  *
  *******************************************************************/

 /** include files **/

 /** local definitions **/

 /* default settings */

 /** external functions **/

 /** external data **/

 /** internal functions **/

 /** public data **/

 /** private data **/

 /** public functions **/

 /** private functions **/

*/


//  set this variable to 'e' if you want case sensitive alias matching.

#define ALIAS_ARG ('alias:'TERMINATE_MATCH)   /* Underscores must be dashes */

/**
 * Applies To: Editor Control or any object.  When applied to Editor
 *             Control extension specific alias filename is returned
 *             in addition to other alias files.
 * 
 * @param includeExtAliasFilename   Specify true if you want the extension specific file.
 * @param includeGlobalAliasFile    Specify true if you want the global alias file.
 * 
 * @return 
 * Returns  alias filename(s) separated with PATHSEP character.
 *          Only files which are found are returned.
 */
_str alias_filename(boolean includeExtAliasFile=true, boolean includeGlobalAliasFile=true)
{
   boolean do_ext_aliasfile= includeExtAliasFile;
   _str filename='';
   if (includeGlobalAliasFile) {
      filename = seGetSlickEditAliasFile();
   }
   int buf_wid=_edit_window();
   if (buf_wid.p_HasBuffer && do_ext_aliasfile ) {
      lang := buf_wid.p_LangId;
      if (buf_wid._inJavadoc()) lang='html';

      aliasFile := LanguageSettings.getAliasFilename(lang);
      if (aliasFile != '') {
         filename = aliasFile :+ PATHSEP :+ filename;
      }

      // Also add the embedded language alias file, if applicable
      _str embeddedLang = buf_wid._GetEmbeddedLangId();
      if(embeddedLang != '' && embeddedLang != lang)
      {
         aliasFile = LanguageSettings.getAliasFilename(embeddedLang);
         if (aliasFile != '') {
            filename = aliasFile :+ PATHSEP :+ filename;
         }
      }
   }
   _str filenames=filename;
   _str pfilenames='';
   for (;;) {
      parse filenames with filename (PATHSEP) filenames;
      if (filenames=='' && filename=='') break;
      if (!pathlen(filename)) {
         filename=usercfg_path_search(filename);
      }
      if (filename=='') continue;
      if (pfilenames=='') {
         pfilenames=filename;
      } else {
         pfilenames=pfilenames:+PATHSEP:+filename;
      }
   }
   return(pfilenames);
}

_str alias_profile(_str filename)
{
   name := _strip_filename(filename, 'p');
   if (file_eq(name, VSCFGFILE_ALIASES)) {
      return '';
   }

   int buf_wid = _edit_window();
   if (buf_wid.p_HasBuffer) {
      lang := buf_wid.p_LangId;
      return getAliasLangProfileName(lang);
   }
   return '';
}

/**
 * Changes the current directory to the <i>alias</i> or <i>directory</i>
 * given.  If an <i>alias</i> is given, it must evaluate to a directory.
 * If no parameter is given, you will be prompted for a parameter.  T he
 * current directory in the build window is set as well if the build
 * window is started.
 * 
 * @return 0 if successful
 * @see alias
 * @see expand_alias
 * @see gui_cd
 * @see cd
 * @see cdd
 * @categories File_Functions, Miscellaneous_Functions
 */
//_command alias_cd() name_info(ALIAS_ARG','VSARG2_CMDLINE|VSARG2_EDITORCTL)
_command int alias_cd(_str msg='') name_info(DIR_ARG','VSARG2_CMDLINE|VSARG2_EDITORCTL)
{
   p_window_id=_edit_window();
   _str dir_name=prompt(msg,'Directory');
   if (msg=='') {
      if ( ! def_stay_on_cmdline) {
         if (_no_child_windows()) {
            VSWID_STATUS._set_focus();
         } else {
            cursor_data();
         }
      }
   }
   typeless multi_line_info='';
   _str path = get_alias(dir_name,multi_line_info);
   typeless multi_line_flag='';
   typeless old_view_id=0;
   typeless alias_view_id=0;
   parse multi_line_info with multi_line_flag old_view_id alias_view_id .;
   if ( multi_line_flag ) {
      message('Multi-line alias not allowed.');
      return(1);
   }

   if ( path=='' ) {
      if ( dir_name=='' ) {
         return(1);
      }
      /* Actual directory may have been specified. */
      if ( ! isdirectory(dir_name) ) {
         message(nls('Alias "%s" not found',dir_name));
         return(1);
      }
      path=dir_name;
   }
   /* back_dir=getcwd() */
   /* All that work, just for this */
   typeless status=cd(path);
   return(status);
}


/**
 * Inserts or overwrites the MDI edit window buffer name path depending on 
 * the insert state.
 * 
 * @appliesTo Edit_Window, Editor_Control Text_Box, Combo_Box
 * 
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 * 
 */
_command void keyin_dir_name()  name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX)
{
   maybe_delete_selection();
   _str buf_name= _mdi._edit_window().p_buf_name;
   keyin(substr(buf_name,1,pathlen(buf_name)));
}

_str get_alias(_str name,
               var multi_line_info,
               typeless replace_envvars='',
               _str aliasfilename='',
               boolean quiet=false)
{
   int old_view_id=0;
   int alias_view_id=0;
   typeless multi_line_flag='';
   int alias_linenum=0;
   AliasParam params[];
   int status=find_alias2(name,params,old_view_id,alias_view_id,
                          multi_line_flag,aliasfilename,alias_linenum,false,quiet);
   multi_line_info=multi_line_flag " "old_view_id" ":+
                   alias_view_id" "alias_linenum" "aliasfilename;
   if ( status ) {
      return('');
   }
   if (multi_line_flag || params._length()) {
      _delete_temp_view(alias_view_id);
      p_window_id=old_view_id;
      return('');
   }
   _str alias='';
   get_line(alias);
   if ( replace_envvars ) {
      alias=_replace_envvars(alias);
   }
   _delete_temp_view(alias_view_id);
   p_window_id=old_view_id;
   return(alias);

}

_command typeless expand_space_alias()  name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   typeless no_expansion=0;
   if (command_state()) {
      _str key=' ';
      int index=eventtab_index(_default_keys,
                              _default_keys,event2index(key));
      if (index!=last_index()) {
         last_event(key);
         return(call_root_key(key));
      }
      keyin(' ');
      return('');
   }
   _str line='';
   get_line_raw(line);
   line=strip(line,'T');
   _str orig_word=strip(line);
   if (p_col!=text_col(line)+1 || pos('[~\od'_extra_word_chars:+p_word_chars']',orig_word,1,'r')) {
      keyin(' ');
      return('');
   }
   expand_alias('',1);
   return('');
}
/*
*/


/**
 * Ctrl+Space bar
 * 
 * Expands the alias name before the cursor by deleting the alias name and 
 * replacing it with its value.
 * 
 * @param alias_name          Option name of alias
 * @param insert_space_arg    If not '', space character is inserted if alias is not found.
 * @param aliasfilename       Single alias file to look in. 
 * @param isDocCommentExpansion True if this is a special case of a doc comment 
 *                              expansion.  False for a regular alias.
 * @param isAutoExpansion     true if we are trying to auto-expand an alias 
 *                            through syntax expansion after a user hit space
 * 
 * @return  Returns 0 if successful.  Otherwise a non-zero number is returned.
 * 
 * @see alias
 * @see alias_cd
 * 
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int expand_alias(_str alias_name='',
                          _str insert_space_arg='',
                          _str aliasfilename='',
                          boolean isDocCommentExpansion = false,
                          boolean isAutoExpansion = false
                          )  name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{

   updateAliasFiles();
   update_lang_surround_definitions();
   boolean insert_space_if_not_found = (insert_space_arg!='');
   int old_col=0;
   if (command_state()) {
      old_col=_get_sel();
   } else {
      old_col=p_col;
   }
   int status=0;
   int start_col=0;
   int old_command_state=command_state();
   if (alias_name=='') {
      init_command_op();
      if (p_col==1) {
         alias_name=cur_word(start_col,0);
         if (alias_name=="") {
            retrieve_command_results();
            return(1);  // No word at cursor
         }
         start_col=_text_colc(start_col,"I");
      } else {
         left();
         status=search('([~\od'_extra_word_chars:+p_word_chars"]|^)\\c","@ir-");
         start_col=p_col;
         alias_name=_expand_tabsc(start_col,old_col-start_col);
         p_col=old_col;
      }
   } else {
      start_col=p_col;
   }
      
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   if (alias_name=="") {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   //get_line line
   //start_col=text_col(line,start_col,'i')
   int old_view_id=0;
   int alias_view_id=0;
   typeless multi_line_flag='';
   int alias_linenum=0;
   AliasParam params[];
   status=find_alias2(alias_name,params,old_view_id,alias_view_id,
                      multi_line_flag,aliasfilename,alias_linenum,
                      insert_space_if_not_found, false, 
                      VSBUFFLAG_THROW_AWAY_CHANGES);
   if (status) {
      if (status==STRING_NOT_FOUND_RC && insert_space_arg!='') {
         p_col=old_col;
         keyin(" ");
      }
      retrieve_command_results();
      return(status);
   }
   if ( multi_line_flag && old_command_state) {
      _delete_temp_view(alias_view_id);
      p_window_id=old_view_id;
      retrieve_command_results();
      message('Multi-line alias not allowed on command line.');
      return(1);
   }
   status=0;
   get_line(auto line);
   status=expand_alias2(alias_name,params,line,start_col,old_view_id,alias_view_id, 
                        isDocCommentExpansion, old_command_state!=0, isAutoExpansion);
   if (status==COMMAND_CANCELLED_RC && insert_space_arg!='') {
      p_col=old_col;
      keyin(" ");
   }
   p_window_id=old_view_id;
   retrieve_command_results();
   return(status);
}

void getLocalParams(_str (&local_param_names)[]) 
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   
   boolean mergeExistingComment = false;
   _UpdateContext(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   // get the multi-line comment start string
   _str prefix, endPrefix;
   _str mlcomment_start;
   _str mlcomment_end;

   save_pos(auto p);
   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   if (context_id <= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      return;
   }

   // get the information about the current function
   _str tag_name = '';
   _str type_name = '';
   _str file_name = '';
   _str class_name = '';
   _str signature = '';
   _str return_type = '';
   int start_line_no = 0;
   int start_seekpos = 0;
   int scope_line_no = 0;
   int scope_seekpos = 0;
   int end_line_no = 0;
   int end_seekpos = 0;
   int tag_flags = 0;
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);

   // get the start column of the tag, align new comment here
   int i=0;
   local_param_names._makeempty();
   if (tag_tree_type_is_func(type_name)) {
      _GoToROffset((scope_seekpos<end_seekpos)? scope_seekpos:start_seekpos);
      _UpdateLocals(true);

      for (i=1; i<=tag_get_num_of_locals(); i++) {
         _str param_name='';
         _str param_type='';
         int local_seekpos=0;
         tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
         tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
         if (param_type=='param' && local_seekpos>=start_seekpos) {
            tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
            local_param_names[local_param_names._length()] = param_name;
         }
      }
   }
   restore_pos(p);
   return;
}

/**
 * Try to get an author tag from the code template settings.  If not 
 * defined, return the username. 
 * 
 * @param _str key Template tag to look up
 * 
 * @return _str 
 */
_str getAuthor(_str key = "author")
{
   _str filename = _ctOptionsGetOptionsFilename();
   ctOptions_t options;
   int status = _ctOptionsGetOptions(filename,options);
   if( status == 0 ) {
      if (options.Parameters._indexin(key))
         return options.Parameters:[key].Value;
   }

   _str returnVal = '';
#if __UNIX__
   returnVal=get_env("USER");
   if( returnVal=="" ) {
      returnVal=get_env("LOGNAME");
   }
#else
   returnVal = get_env("USERNAME");
#endif
   return returnVal;
}

/** 
 * 
 * 
 * @param name
 * @param first_line
 * @param start_col
 * @param destination_view_id
 * @param alias_view_id
 * @param isDocCommentExpansion True if this is a special case of a doc comment 
 *                              expansion.  False for a regular alias.
 * 
 * @return int
 */
static int expand_alias2(_str name, AliasParam (&params)[],
                         _str first_line,
                         int start_col,
                         int destination_view_id,
                         int alias_view_id,
                         boolean isDocCommentExpansion = false,
                         boolean isCommandState = false,
                         boolean isAutoExpansion = false)
{
   activate_window(destination_view_id);
   boolean alias_in_comment = _clex_find(0, 'G') == CFG_COMMENT;
   boolean dest_utf8=p_UTF8;
   typeless prompt_view_id='';
   p_window_id=alias_view_id;
   _str line;
   typeless var_view_id=prompt_view_id='';
   if (params._length()) {
      build_prompts(params, prompt_view_id,var_view_id);
      p_window_id=destination_view_id;
      typeless result=show('-modal _textbox_form',
        'Parameter Entry',
        TB_VIEWID_INPUT|TB_VIEWID_OUTPUT|TB_QUERY_COMPAT,   // flags
        '',                 // width ('' or 0 uses default)
        '',                 // Optional help item
        '',                 // Buttons and captions
        '',                 // Retrieve name
        prompt_view_id
        );
      if (result=='') {
         /* user pressed ESC or an error occurred */
         activate_window(var_view_id);
         _delete_temp_view(var_view_id);
         p_window_id=destination_view_id;
         return(COMMAND_CANCELLED_RC);
      }
      prompt_view_id=result;
      p_window_id=alias_view_id;
   }

   _str alias_line;
   typeless alias_col='';
   get_line_raw(alias_line);
   p_window_id=destination_view_id;
   clear_hotspots();
   typeless start_pos;
   save_pos(start_pos);

   p_col = 1;
   expand_start_offset := _QROffset();
   restore_pos(start_pos);

   get_line_raw(line);
   if(!dest_utf8) name=_UTF8ToMultiByte(name);
   if (upcase(expand_tabs(line,start_col,length(name)),dest_utf8)==upcase(name,dest_utf8)) {
      replace_line_raw(expand_tabs(line,1,start_col-1,'s'):+expand_tabs(line,start_col+length(name),-1,'s'));
   }

   //Check for local function information
   MI_localFunctionParams_t local_param_names;
   if (_is_line_before_decl()) {
      save_pos(auto start_pos2);
      getLocalFunctionParams(local_param_names);
      restore_pos(start_pos2);
   }

   int start_line=p_line;
   set_surround_mode_start_line();
   _str stop_info[];
   stop_info._makeempty();

   boolean hasParamExpansion = false;
   expand_alias_line(name,alias_line,1,start_col,alias_col,stop_info,prompt_view_id,var_view_id, alias_view_id, local_param_names, isDocCommentExpansion, isCommandState);
   _str lineRemainder = CW_getLineFromColumn();
   save_pos(auto orig_pos);
   for (;;) {
      p_window_id = alias_view_id;
      if (down()) {
         /* at bottom of alias */
         break;
      }
     get_line_raw(alias_line);
      p_window_id=destination_view_id;
      expand_alias_line('',alias_line,0,start_col,alias_col,stop_info,prompt_view_id,var_view_id, alias_view_id, local_param_names, isDocCommentExpansion, isCommandState);
   }
   p_window_id=destination_view_id;
   // move trailing text
   if (start_line != p_line) {
      _save_pos2(auto p2);    // Save stream position here, we want it to track_any movement caused by the delete_end_line
      restore_pos(orig_pos);
      delete_end_line();
      _restore_pos2(p2);
      save_pos(p2);   // Now use a normal save position, so we don't track the movement caused by the insert_text_raw.
      _insert_text_raw(lineRemainder);
      restore_pos(p2);
   }

   _delete_temp_view(alias_view_id);

   /* now clean up if we were expanding a parameterized alias */
   if ( prompt_view_id!='' ) {
      _delete_temp_view(prompt_view_id);
      _delete_temp_view(var_view_id);
   }

   surround_save_end_pos();
   expand_end_offset := _QROffset();

   // cursor position(s) was set by alias
   typeless stop_point='';
   typeless stop_line='';
   typeless stop_col='';
   int i,n = stop_info._length();
   if (n > 1) {
      for (i=0; i<n; ++i) {
         parse stop_info[i] with stop_point stop_line stop_col;
         goto_point(stop_point,stop_line);p_col=stop_col;
         add_hotspot();
      }
      show_hotspots();
   }

   // go to the first cursor position
   if (n > 0) {
      parse stop_info[0] with stop_point stop_line stop_col;
      goto_point(stop_point,stop_line);p_col=stop_col;
   }

   // try to do dynamic surround (cursor needs to be on first line)
   if (isAutoExpansion) {
      // the dynamic surround might notify for both it and the alias expansion
      if (!do_surround_mode_keys(false, NF_ALIAS_EXPANSION)) {
         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_ALIAS_EXPANSION);
      }
   } else {
      do_surround_mode_keys();
   }

   // Beautify it, if we are so configured...
   if (beautify_alias_expansion(p_LangId)
       && !alias_in_comment) {
      long markers[];

      new_beautify_range(expand_start_offset, expand_end_offset, markers, true, false, false, BEAUT_FLAG_ALIAS);
   }

   // finished!
   return(0);
}

/**
 * Format current time according to the <code>format</code> 
 * specification and return result. 
 *
 * <p>
 *
 * Uses the same conversion-specifiers as the operating system 
 * implementation of <code>strftime</code>. The '#' is used as a 
 * conversion specifier instead of '%', otherwise all 
 * conversion-specifiers are the same. Not all specifiers will 
 * be valid on all platforms. See the note for a specifier 
 * before using it. 
 *
 * <pre>
 *
 * #a
 *      The abbreviated weekday name according to the current locale. 
 *
 * #A
 *      The full weekday name according to the current locale.  In the
 *      default "C" locale, one of Sunday, Monday, Tuesday,
 *      Wednesday, Thursday, Friday, Saturday. 
 *
 * #b
 *      The abbreviated month name according to the current locale. 
 *
 * #B
 *      The full month name according to the current locale.  In the
 *      default "C" locale, one of January, February, March,
 *      April, May, June, July, August, September,
 *      October, November, December. 
 *
 * #c
 *      The preferred date and time representation for the current locale. 
 *
 * #C
 *      The century, that is, the year divided by 100 then truncated.  For
 *      4-digit years, the result is zero-padded and exactly two
 *      characters; but for other years, there may a negative sign or more
 *      digits.  In this way, #C#y is equivalent to #Y. 
 *      NOT CROSS-PLATFORM
 *
 * #d
 *      The day of the month, formatted with two digits (from 01 to
 *      31). 
 *
 * #D
 *      A string representing the date, in the form "#m/#d/#y". 
 *      NOT CROSS-PLATFORM
 *
 * #e
 *      The day of the month, formatted with leading space if single digit
 *      (from 1 to 31). 
 *      NOT CROSS-PLATFORM
 *
 * #Ex
 *      In some locales, the E modifier selects alternative
 *      representations of certain modifiers x. Otherwise, it is
 *      ignored, and treated as #x.
 *      NOT CROSS-PLATFORM
 *
 * #F
 *      A string representing the ISO 8601:2000 date format, in the form
 *      "#Y-#m-#d". 
 *      NOT CROSS-PLATFORM
 *
 * #g
 *      The last two digits of the week-based year, see specifier #G (from
 *      00 to 99). 
 *      NOT CROSS-PLATFORM
 *
 * #G
 *      The week-based year. In the ISO 8601:2000 calendar, week 1 of the
 *      year includes January 4th, and begin on Mondays. Therefore, if
 *      January 1st, 2nd, or 3rd falls on a Sunday, that day and earlier
 *      belong to the last week of the previous year; and if December
 *      29th, 30th, or 31st falls on Monday, that day and later belong to
 *      week 1 of the next year.  For consistency with #Y, it always has
 *      at least four characters.  Example: "#G" for Saturday 2nd January
 *      1999 gives "1998", and for Tuesday 30th December 1997 gives
 *      "1998". 
 *      NOT CROSS-PLATFORM
 *
 * #h
 *      Synonym for "#b". 
 *      NOT CROSS-PLATFORM
 *
 * #H
 *      The hour (on a 24-hour clock), formatted with two digits (from
 *      00 to 23). 
 *
 * #I
 *      The hour (on a 12-hour clock), formatted with two digits (from
 *      01 to 12). 
 *
 * #j
 *      The count of days in the year, formatted with three digits (from
 *      001 to 366). 
 *
 * #k
 *      The hour (on a 24-hour clock), formatted with leading space if
 *      single digit (from 0 to 23). Non-POSIX extension (c.p.
 *      #I). 
 *      NOT CROSS-PLATFORM
 *
 * #l
 *      The hour (on a 12-hour clock), formatted with leading space if
 *      single digit (from 1 to 12). Non-POSIX extension (c.p.
 *      #H). 
 *      NOT CROSS-PLATFORM
 *
 * #m
 *      The month number, formatted with two digits (from 01 to
 *      12). 
 *
 * #M
 *      The minute, formatted with two digits (from 00 to 59). 
 *
 * #Ox
 *      In some locales, the O modifier selects alternative digit
 *      characters for certain modifiers x.  Otherwise, it is ignored,
 *      and treated as #x.
 *      NOT CROSS-PLATFORM
 *
 * #p
 *      Either AM or PM as appropriate, or the corresponding
 *      strings for the current locale. 
 *
 * #P
 *      Same as #p, but in lowercase.  This is a GNU extension. 
 *      NOT CROSS-PLATFORM
 *
 * #r
 *      Replaced by the time in a.m. and p.m. notation.  In the "C" locale
 *      this is equivalent to "#I:#M:#S #p".  In locales which don't
 *      define a.m./p.m.  notations, the result is an empty string. 
 *      NOT CROSS-PLATFORM
 *
 * #R
 *      The 24-hour time, to the minute.  Equivalent to "#H:#M". 
 *      NOT CROSS-PLATFORM
 *
 * #S
 *      The second, formatted with two digits  (from  00  to  60).
 *      The value 60 accounts for the occasional leap second. 
 *
 * #T
 *      The 24-hour time, to the second.  Equivalent to "#H:#M:#S". 
 *      NOT CROSS-PLATFORM
 *
 * #u
 *      The weekday as a number, 1-based from Monday (from 1 to
 *      7). 
 *      NOT CROSS-PLATFORM
 *
 * #U
 *      The week number, where weeks start on Sunday, week 1 contains the
 *      first Sunday in a year, and earlier days are in week 0.  Formatted
 *      with two digits (from 00 to 53).  See also #W. 
 *
 * #V
 *      The week number, where weeks start on Monday, week 1 contains
 *      January 4th, and earlier days are in the previous year.  Formatted
 *      with two digits (from 01 to 53).  See also #G. 
 *      NOT CROSS-PLATFORM
 *
 * #w
 *      The  weekday  as  a  number,  0-based  from  Sunday (from 0 to 6).
 *
 * #W
 *      The week number, where weeks start on Monday, week 1 contains the
 *      first Monday in a year, and earlier days are in week 0.  Formatted
 *      with two digits (from 00 to 53). 
 *
 * #x
 *      Replaced by the preferred date representation in the current
 *      locale.  In the "C" locale this is equivalent to "#m/#d/#y". 
 *
 * #X
 *      Replaced by the preferred time representation in the current
 *      locale.  In the "C" locale this is equivalent to "#H:#M:#S". 
 *
 * #y
 *      The last two digits of the year (from 00 to 99). 
 *      (Implementation interpretation:  always positive, even for
 *      negative years.)
 *
 * #Y
 *      The full year, equivalent to #C#y.  It will always have at least
 *      four characters, but may have more. 
 *
 * #z
 *      The offset from UTC.  The format consists of a sign (negative is
 *      west of Greewich), two characters for hour, then two characters
 *      for minutes (-hhmm or +hhmm). 
 *      NOT CROSS-PLATFORM
 *
 * #Z
 *      The time zone name. 
 *
 * ##
 *      A literal # character.
 * 
 * </pre>
 * 
 * @param format  Format specification.
 * 
 * @return String result. "" on failure.
 *
 * @example 
 * <pre>
 * April 20, 2011 === "#B #e, #Y" 
 * 2011-4-20 === "#Y-#m-#d" 
 * 11:31 pm === #I:#M #p 
 * </pre>
 */
_str printtime(_str format)
{
   format = stranslate(format,'%','#');
   return strftime(format);
}

void makeCommentPrefix(_str reg, _str alias_line, int start_col, _str& comment_prefix, int& comment_prefix_col)
   { get_line_raw( auto line);
   line = substr(expand_tabs(line), 1, start_col - 1);
   if (pos(reg, line, 1, 'R')) {
      _str prefix = substr(line, pos('S'), pos(''));
      if (substr(strip(alias_line), 1, length(prefix)) :!= prefix) {
         //if (!pos('* /', strip(alias_line))) {
            comment_prefix = prefix;
            comment_prefix_col = (int)_first_non_blank_col(start_col);
         //}
      }
   }
}

/**
 * 
 * Used to exit out of expand_alias_line().  Example use is when alias 
 * line contains a %\p escape sequence, but there are no local function 
 * parameters. 
 * 
 * @param expand_first 
 * @param start_col 
 * @param originalLine 
 * 
 * @return void 
 */
static void cancel_expand_alias_line(typeless expand_first, int start_col, _str originalLine, _str (&stop_info)[]) {
   // remove hotspots on line
   typeless stop_line, cur_line = point('L');
   int i,n = stop_info._length() - 1;
   for (i = n; i >= 0; --i) {
      parse stop_info[i] with . stop_line . ;
      if (stop_line == cur_line) {
         stop_info._deleteel(i);
      }
   }
   if (!expand_first) {
      delete_line();
      up();
   } else {
      replace_line_raw(originalLine);
      p_col = start_col;
   }
}

/**
 * 
 * 
 * 
 * @param duplicateNumber 
 * @param alias_line 
 * @param alias_view_id 
 * 
 * @return void 
 */
static void duplicate_this_alias_line(int duplicateNumber, _str alias_line, int alias_view_id) {
   int i, view_id = 0;
   get_window_id(view_id);
   if (alias_view_id != '') {
      activate_window(alias_view_id);
      save_pos(auto StartPos);
      for (i = 1; i < duplicateNumber; i++) {
         insert_line_raw(alias_line);
      }
      restore_pos(StartPos);
   }
   activate_window(view_id);
}

/**
 * 
 * 
 * @param after 
 * 
 */
static void jumpToRelOrSpecCol(_str &after) {
   _str ch, number = '';
   int afterCol = 1;

   //Read the number after the %\x escape sequence.
   //If sequence not followed by valid jump number, then return
   if (!pos('^[\-\+]:0,1:i', after, 1, 'R')) return;

   //Store number found as string
   number = substr(after, 1, pos(''));

   //Remove the number from front of after string
   after = substr(after, length(number) + 1);

   //Adjust the column based on whether a specific column or a
   //positive relative or negative jump is given
   if (substr(number, 1, 1) == '+') {
      p_col += (int)substr(number, 2);
   } else if (substr(number, 1, 1) == '-') {
      p_col -= (int)substr(number, 2);
   } else {
      p_col = (int)number;
   }
   return;
}

/**
 * 
 * 
 * @param after 
 * 
 */
static void InsertMacroCall(_str &after) {
   //Read the macro after the %\m escape sequence. If escape sequence not 
   //followed by valid macro, then return 
   if (!pos('^[ \t]*[A-Za-z0-9_]?*%', after, 1, 'R')) {say('Invalid macro');
      return;
   }
   //Store macro command found as string
   _str macCommand = substr(after, 1, pos('') - 1);

   //Remove the macro command from front of after string
   after = substr(after, length(macCommand) + 2);

   _str params = '';
   parse macCommand with macCommand params;
   int index = find_index(macCommand, COMMAND_TYPE|PROC_TYPE);
   _str val = '';
   boolean point_changed = false;
   if (index && index_callable(index)) {
      // Save the point to check for change (inserted text) later
      typeless p = point();
      if (params == '') {
         val = call_index(index);
      } else {
         val = call_index(params,index);
      }
      // A simple change in position will cause this to be true,
      // but that is okay since we assume the user knows what
      // they are doing.
      point_changed= (p != point());
   }
   if ( !point_changed ) {
      // Text was not inserted, so use the returned string instead
      after = val :+ after;
   }
}

static int paramExpansionCounter = 0;
/**
 * Takes an alias line and processes all of the escape sequences and 
 * environment variables and inserts the result. 
 * 
 * @param name
 * @param alias_line            Alias value line.
 * @param expand_first 
 * @param start_col             Column of alias being replaced
 * @param alias_col             Spaces adjustment or ''
 * @param stop_info 
 * @param prompt_view_id        view containing prompt strings
 * @param var_view_id           view containing parameter names
 * @param alias_view_id  
 * @param local_param_names     local function information
 * @param isDocCommentExpansion True if this is a special case of a doc comment 
 *                              expansion.  False for a regular alias.
 * 
 * @return int 
 */
static int expand_alias_line(_str name,
                             _str alias_line, 
                             typeless expand_first,
                             int start_col, 
                             var alias_col, 
                             _str (&stop_info)[],
                             int prompt_view_id, 
                             int var_view_id,    
                             int alias_view_id,    
                             MI_localFunctionParams_t& local_param_names, 
                             boolean isDocCommentExpansion = false,
                             boolean isCommandState = false)
{
   if (paramExpansionCounter > 0) paramExpansionCounter--;
   get_line_raw(auto originalLine);
   int originalStartCol = start_col;

   _str line='';
   _str comment_prefix = "";
   int comment_prefix_col = 1;


   //Check if expanding within document comment or within a block comment 
   //with borders 
   if (_inJavadoc() && start_col>1) {
      makeCommentPrefix('\*#', alias_line, start_col, comment_prefix, comment_prefix_col);
   } else if (commentwrap_inXMLDoc(auto startpos, auto endpos)) {
      makeCommentPrefix('///', alias_line, start_col, comment_prefix, comment_prefix_col);
   }

   if ( ! expand_first ) {
      insert_line('');
   }
   typeless p='';
   int i=0, k=0, l=0;
   _str code='';
   _str before='';
   _str after='';
   _str utf8_before='';
   _str spaces='';
   _str cur_line='';
   int syntax_indent=0;
   int non_blank_col=0;
   _str proc_name='';
   boolean dest_utf8=p_UTF8;
   int adjust_spaces=1;
   for (;;) {
      get_line_raw(line);            /* User text line. */
      if ( ! expand_first && adjust_spaces ) {
         if ( comment_prefix!="" ) {
            _str comment_prefix_str = indent_string(comment_prefix_col-1):+comment_prefix;
            line=comment_prefix_str:+substr('',1,start_col-1-length(comment_prefix)-comment_prefix_col-1);
         } else {
            line=indent_string(start_col-1);
         }
      }
      p = next_multi_line_code(alias_line,'ALL');
      if ( p ) {
         /* HERE - check for a parameter */
         int q=pos('{%\([0-9a-zA-Z_]@\)}',substr(alias_line,p),1,'r');
         if ( q==1 ) {
            code=substr(alias_line,p,pos('0'));
         } else {
            code=substr(alias_line,p,3);   /* grab the code */
            code=upcase(code);
         }

         after=substr(alias_line,p+length(code));
         before=substr(alias_line,1,p-1);
         utf8_before=before;
      } else {
         utf8_before=alias_line;
         code='';
      }
      if (!dest_utf8) {
         utf8_before=_MultiByteToUTF8(utf8_before);
         before=_replace_envvars(utf8_before);
         before=_UTF8ToMultiByte(before);
      } else {
         before=_replace_envvars(utf8_before);
      }
      if ( adjust_spaces ) {
         if ( alias_col=='' ) {
            alias_col=verify(before,' ');
            if ( ! alias_col ) {
               alias_col='';
            } else {
               alias_col=alias_col-1;
            }
            before=strip(before,'L');
         } else {
            spaces=substr(before,1,alias_col);
            if ( spaces!='' ) {
               before=strip(before,'L');
            } else {
               before=substr(before,alias_col+1);
            }
         }
      }
      replace_line_raw(expand_tabs(line,1,start_col-1,'s'):+
                       before:+expand_tabs(line,start_col,-1,'s'));
      p_col=start_col+length(before);

      if ( code=='' ) {
         return(0);
      }
      /*
          NOTE:  There still be some Multi-byte to UTF-8 problems below
      */
      switch (code) {
         
         case '%\B':
            // Back indent
            get_line_raw(cur_line);
            /* IF unindent from the beginning of a line. */
            syntax_indent = p_SyntaxIndent;
            if (syntax_indent > 0 && expand_tabs(cur_line,1,p_col-1) == '' && 
                p_col > syntax_indent ) {
               non_blank_col = verify(cur_line, ' '\t);
               if ( ! non_blank_col ) {
                  non_blank_col = length(cur_line) + 1;
               }
               replace_line_raw(indent_string(text_col(cur_line, non_blank_col, 'i') - syntax_indent - 1) :+
                                substr(cur_line,non_blank_col));
               p_col = p_col - syntax_indent;
            } else {
               cbacktab();
            }
            break;

         case '%\C':
            // Place cursor here after expansion complete
            stop_info[stop_info._length()] = point() " "point('L') " "p_col;
            break;

         case '%\I':
            // Indent
            get_line_raw(cur_line);
            /* IF unindent from the beginning of a line. */
            syntax_indent=p_SyntaxIndent;
            if ( syntax_indent>0 && expand_tabs(cur_line,1,p_col-1)=='' ) {
               non_blank_col=verify(cur_line,' '\t);
               if ( ! non_blank_col ) {
                  non_blank_col=length(cur_line)+1;
               }
               replace_line_raw(indent_string(text_col(cur_line,non_blank_col,'i')+syntax_indent-1):+
                                substr(cur_line,non_blank_col));
               p_col=p_col+syntax_indent;
            } else {
               ctab();
            }
            break;

         case '%\L':
            // Empty placeholder
            after = after;
            break;

         case '%\S':
            // Empty placeholder
            after = after;
            break;

         case '%\N':
            // Current function/procedure (just the name)
            /*
               We still need more work here.  Checking for local_param_names.m_procName
               not empty works for function but not other identifier types.
            */
            if (local_param_names.m_procName != "") {
               proc_name = local_param_names.m_procName;
            } else {
               if (isCommandState && !_no_child_windows()) {
                  proc_name = _mdi.p_child.current_proc(false);
               } else {
                  proc_name = current_proc(false);
               }
               i = pos('(', proc_name);
               if (i) {
                  //current_proc() now sometimes returns more information than
                  //the procname, and users want it stripped off.  Created a %\o
                  //expansion that will return current_proc's value.
                  proc_name = substr(proc_name, 1, i-1);
               }
            }
            after = proc_name :+ after;
            break;

         case '%\O':
            // Current function/procedure
            _str signature = '';
            /*
               We still need more work here.  Checking for local_param_names.m_procName
               not empty works for function but not other identifier types.
            */
            if (local_param_names.m_procName != "") {
               signature = local_param_names.m_signature;
            } else {
               if (isCommandState && !_no_child_windows()) {
                  signature = _mdi.p_child.current_func_signature(false);
               } else {
                  signature = current_func_signature(false);
               }
            }
            after = signature :+ after;
            break;

         case '%\P':
            if (!paramExpansionCounter) {
               paramExpansionCounter = local_param_names.paramNum();
               if (!paramExpansionCounter) {
                  cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
                  return 0;
               }
               duplicate_this_alias_line(paramExpansionCounter, alias_line, alias_view_id);
            }
            // Local function param names
            after = local_param_names.m_param[local_param_names.paramNum() - paramExpansionCounter] :+ after;
            break;

         case '%\Q':
            if (!paramExpansionCounter) {
               paramExpansionCounter = local_param_names.paramNum();
               if (!paramExpansionCounter) {
                  cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
                  return 0;
               }
               duplicate_this_alias_line(paramExpansionCounter, alias_line, alias_view_id);
            }
            // Local function param types
            after = local_param_names.m_ptype[local_param_names.paramNum() - paramExpansionCounter] :+ after; 
            break;

         case '%\R':
            if (!local_param_names.returnNum()) {
               break;
               //cancel_expand_alias_line(expand_first, originalStartCol, originalLine);
               //return 0;
            }
            // Local function return type
            after = local_param_names.m_rtype :+ after;
            break;

         case '%\U':
            // If this was an inverse conditional check...
            if ( upcase(substr(after, 1, 1)) == 'N' ) {
               //Remove the ! from front of after string
               after = substr(after, 2);
   
               // Remove line if no local function parameters.
               if (local_param_names.paramNum()) {
                  cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
                  return 0;
               }
               
            } else if (!local_param_names.paramNum()) { // Remove line if no local function parameters.
               cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
               return 0;
            }
            break;
   
         case '%\V':
            // If this was an inverse conditional check...
            if ( upcase(substr(after, 1, 1)) == 'N' ) {
               //Remove the ! from front of after string
               after = substr(after, 2);
   
               // Remove line if no local function return type.
               if (local_param_names.returnNum()) {
                  cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
                  return 0;
               }
            } else if (!local_param_names.returnNum()) { // Remove line if no local function return type.
               cancel_expand_alias_line(expand_first, originalStartCol, originalLine, stop_info);
               return 0;
            }
            break;
   
   
         case '%\K':
            // Do nothing. Was handled in preprocessing.
            after = after;
            break;

         case '%\A':
            // Look up author.
            after = getAuthor() :+ after;
            break;

         case '%\F':
            // Current file name (no path)
            if (isCommandState && !_no_child_windows()) {
               after = _strip_filename(_mdi.p_child.p_buf_name, 'p') :+ after;
            } else {
               after = _strip_filename(p_buf_name, 'p') :+ after;
            }
            break;

         case '%\T':
            // Time
            after = _time('L') :+ after;
            break;

         case '%\E':
            // Date in MMDDYY format
            after = strftime('%m%d%y') :+ after;
            break;

         case '%\D':
            // Local date
            after = _date('L') :+ after;
            break;

         case '%\X':
            // Jump to relative or specific column
            jumpToRelOrSpecCol(after);
            break;

         case '%\M':
            // Result of (M)acro
            InsertMacroCall(after);
            break;

         case '%\G':
            // File separator
            after = FILESEP :+ after;
            break;

         case '%\W':
            // line number, please
            if (isCommandState && !_no_child_windows()) {
               after = _mdi.p_child.p_line :+ after;
            } else {
               after = p_line :+ after;
            }
            break;

         case '%\J':
            className := '';
            if (local_param_names.m_className != "") {
               className = local_param_names.m_className;
            } else {
               className = current_class(false); 
            }
            pkgName := current_package(false);

            if (_LanguageInheritsFrom('java', _mdi.p_child.p_LangId) && 
                (className == '' || className :== pkgName)) {
               if (isCommandState && !_no_child_windows()) {
                  className = _strip_filename(_mdi.p_child.p_buf_name, 'pe');
               } else {
                  className = _strip_filename(p_buf_name, 'pe');
               }
            }

            // find out if we want the fully qualified name
            qualified := false;
            if (substr(after, 1, 1) == '+' ) {
               qualified = true;
               //Remove the + from front of after string
               after = substr(after, 2);
            }

            // do some magic
            sepPos := lastpos(VS_TAGSEPARATOR_package, className);
            if (sepPos) {
               // strip off the last part, it's all we want
               first := substr(className, 1, sepPos - 1);
               last := substr(className, sepPos + 1);

               // do we want the whole thing or just the end?
               if (qualified) {

                  // whole thing, but make sure we have a separator that we like
                  lang := _mdi.p_child.p_LangId;
                  if (_LanguageInheritsFrom('c', lang) || _LanguageInheritsFrom('sas', lang) || _LanguageInheritsFrom('rul', lang)) {
                     className = stranslate(className, '::', VS_TAGSEPARATOR_package);
                  } else {
                     className = stranslate(className, '.', VS_TAGSEPARATOR_class);
                     className = stranslate(className, '.', VS_TAGSEPARATOR_package);
                  }

               } else {
                  // just the end part please
                  className = last;
               }
            }

            after = className :+ after;
            break;

         default:
            // Insert a alias Parameter
            int view_id=0;
            get_window_id(view_id);
            _str varble='';
            parse code with '%(' varble ')';
            if (var_view_id=='') {
               PreserveFocusMessageBox(nls('"%s" not found in parameter list.',varble));
            } else if (varble=='') {
            } else {
               activate_window(var_view_id);
               top();
               search('^'varble'$',def_alias_case'@r');
               if ( ! rc ) {
                  int index=p_line;
                  activate_window(prompt_view_id);
                  top();
                  down(p_noflines intdiv 2 + (index-1));
                  get_line(auto val);
                  // DWH 2:59:20 PM 1/30/2008
                  // We want to escape '%' chars in the value, but not if 
                  // it is another parameter ( %(param) )
                  after=stranslate(val, '%%', '\%~[\(]','r'):+after;
               } else {
                  message(nls('"%s" not found in parameter list.',varble));
               }
            }
            activate_window(view_id);
      } //switch

      start_col=p_col;
      alias_line=after;
      name='';  /* this is here for the first line of alias,  *
                 * if there is a code in the first line, then *
                 * line remaining after code requires name='' */

      adjust_spaces=0;
   }

   /* END expand_alias_line */


}

static int build_prompts(AliasParam (&params)[], int &prompt_view_id, int &var_view_id)
{
   int view_id=0;
   get_window_id(view_id);
   _create_temp_view(prompt_view_id);
   _create_temp_view(var_view_id);

   _str varble='';
   _str prompt_string='';
   _str init_value='';
   foreach (auto p in params) {
      varble = p.name;
      init_value = p.initial;
      prompt_string = p.prompt;
      if (last_char(prompt_string) != ':') {
         /* must have a colon at end of prompt string for QUERY */
         prompt_string = prompt_string:+':';
      }
      activate_window(var_view_id);
      insert_line(strip(varble));
      activate_window(prompt_view_id);
      insert_line(prompt_string:+init_value);
   }
   activate_window(view_id);
   return(0);
}

/**
 * 
 * 
 * 
 * @param _str alias 
 * @param _str use_bcdftilsmneox 
 * 
 * @return int 
 */
int next_multi_line_code(_str alias, _str use_bcdftilsmneox='')
{
   int start_col=1;
   _str valid_chars='';
   if ( use_bcdftilsmneox != '') {
      //valid_chars='[BbCcDdFfgGTtIiLlSsMmNnEeOoXxPpQqRrKkAaUuVvHh]';
      valid_chars='[BbCcDdFfgGJjWwTtIiLlSsMmNnEeOoXxPpQqRrKkAaUuVv]';
   } else {
      valid_chars='[]';
   }

   int end_col=0;
   int end_length=0;
   int level=0;
   _str temp='';
   int start_envvar=0;
   for (;;) {
      if ( pos('{%(\\'valid_chars'|\([0-9a-zA-Z_]@\))}',alias,start_col,'r') ) {   /* HERE */
         end_col=pos('S0')-1;
         if ( end_col<start_col ) {
            return(start_col);
         }
         //end_length=1 + length(substr(alias,start_col)) - length(substr(alias,end_col))
         end_length=1 + end_col-start_col;
         level=0;
         temp=substr(alias,start_col,end_length);

         for (;;) {
            start_envvar= pos('%',temp,1);
            if (start_envvar) {
               int p=pos('%',temp,start_envvar+1);
               if ( p ) {
                  temp=substr(temp,p+1);
                  continue;
               } else {
                  // Unfortunately, when envvars are processed, won't see this code
                  level=1;
                  break;
               }
            } else {
               break;
            }
         }
         // Unfortunately, when envvars are processed, won't see this code
         if ( level ) {
            start_col=end_col+2;   /* skip '%' */
            continue;
         } else {
            return(end_col+1);     /* it is a multi-line alias! */
         }
      } else {
         return(0);
      }
   }   /* outer loop */
   /* END next_multi_line_code */
}

static int _delete_alias(_str name)
{
   _str filename = next_alias_file(alias_filename(), 1);
   int status = 0;
   for (;;) {
      AliasFile aliasFile;
      status = aliasFile.open(filename);
      if (!status) {
         if (aliasFile.hasAlias(name)) {
            aliasFile.deleteAlias(name);
            break;
         }
         aliasFile.close();
      }
      filename = next_alias_file('', 0);
      if (filename == '') {
         break;
      }
   }
   return(0);
}

static _str _get_lang_alias()
{
   _str lang=p_LangId;
   if (_inJavadoc()) lang='html';
   return lang;
}

static _str _get_lang_alias_filename()
{
   return getAliasFileNameForLang(_get_lang_alias());
}

/**
 * Set the alias file for a given language.  Should just give the name of the 
 * alias file, not the full path, and should have the .als extension. 
 * 
 * @param cmdline Space separated combination of language name followed by name 
 *                of alias file.
 */
_command void set_lang_alias_filename(_str cmdline='') name_info(VAR_ARG','VSARG2_EDITORCTL)
{
   _str lang, filename;
   parse cmdline with lang ' ' filename;
   lang = prompt(lang, "Language");
   filename = prompt(filename, "Alias file");
   if (filename == '') {
      filename = lang".als.xml";
   }

   LanguageSettings.setAliasFilename(lang, filename);
}
/**
 * <p>
 * The <b>alias</b> command displays, creates, or modifies aliases.  To expand an alias, execute the
 * <b>expand_alias</b> command (Ctrl+Space bar).
 * </p>
 * 
 * <p>
 * If no arguments are given or cmdline is "", you will prompted to pick an alias file and the
 * Alias Editor dialog box will be displayed.  We recommend you use the alias editor for creating,
 * deleting, viewing, or modifying aliases because it is easier to use than this command. </p>
 * 
 * <p>Use the "-e" argument to edit aliases for the current file.  Use the 
 * "-surround" option to edit surround with aliases for the current file.
 * </p>
 * 
 * <p>Aliases are stored by default in a file called 
 * "alias.als.xml". Use the VSLICKALIAS environment variable
 * to define one or more alias files.  Separate each alias 
 * filename with a ';' (UNIX: ':'). 
 * New aliases created with the <b>alias</b> command are placed in the first file defined by
 * the VSLICKALIAS environment variable.</p>
 * 
 * <p>The value of the alias may have any of the following escape sequences  embedded in it.
 * </p>
 * 
 * <pre>
 * %&lt;EnvVar&gt;%  Insert the value of the environment variable specified
 * %\d   Insert the date
 * %\t   Insert the time
 * %\i   Indent
 * %\b   Unindent
 * %\c   Place cursor
 * %\n   Current function name
 * %(ParamName)   Argument replacement.
 * </pre>
 * 
 * Prefix the name of the alias with "-d" to delete an alias.
 * 
 * See <b>alias_cd</b> command for information on using an alias to change directory.
 * 
 * @return 
 * @categories Miscellaneous_Functions
 */
_command int alias(_str params='') name_info(ALIAS_ARG',')
{
   update_lang_surround_definitions();
   typeless temp;
   temp._makeempty();
   _str filename='';
   _str aliasfilename='';
   int index=0;
   typeless p='', result='';
   _str option="", aliasname="";
   parse params with option aliasname;
   if (first_char(option)!='-' && aliasname=="") {
      aliasname=option;
      option="";
   }
   boolean delete_option=upcase(option)=="-D";
   if (delete_option) {
      return(_delete_alias(aliasname));
   }
   boolean extension_alias_file_only=upcase(option)=="-E";
   boolean editSurround=lowcase(option)=='-surround';
   if (option=="" || extension_alias_file_only || editSurround) {
      if ((extension_alias_file_only || editSurround) && p_HasBuffer) {
         filename=_get_lang_alias_filename();
         temp:[filename]=filename;
      } else {
         aliasfilename = seGetSlickEditAliasFile();
         for (;;) {
            parse aliasfilename with filename (PATHSEP) aliasfilename;
            if (filename=='') break;
            if (filename!="") {
               filename=_file_case(filename);
               temp:[filename]=filename;
            }
         }
         index=name_match("def-alias-",1,MISC_TYPE);
         for (;;) {
            if (!index) break;
            filename=name_info(index);
            index=name_match("def-alias-",0,MISC_TYPE);
            if (filename!="") {
               filename=_file_case(filename);
               temp:[filename]=filename;
            }
         }
      }

      // Count number of elements in hash table.
      int count=0;
      typeless i;
      for (count=0,i._makeempty();;++count) {
         p=&temp._nextel(i);
         if (i._isempty()) break;
         aliasfilename= *p;
      }
      if (count==0) {
         aliasfilename=VSCFGFILE_ALIASES;
      } else if (count==1) { // We already have the filename
      }else{
         result=show('-modal _sellist_form',
                     nls('Select Alias File'),
                     SL_SELECTCLINE,
                     temp,
                     '',                           // buttons
                     'Select Alias File dialog',   // help item name
                     ''                            // font
                     );
         if (result=='') {
            return(1);
         }
         aliasfilename=result;
      }
      showAliasEditorForFilename(aliasfilename, editSurround' 'aliasname);
      return(0);
   }
   return(0);
}

//   ignore_not_found=arg(9)
static int find_alias2(_str name, AliasParam (&param)[],
                        int &orig_view_id,int &alias_view_id,
                        _str &multi_line_flag,
                        _str &alias_fn,int &alias_linenum,
                        boolean ignore_not_found,
                        boolean quiet=false,
                        int more_buf_flags = 0 //Set to non-zero when expanding alias
                       )
{
   alias_view_id=0;alias_linenum=0;
   multi_line_flag=0;
   orig_view_id = p_window_id;
   _str filename='';
   if (alias_fn == '') {
      filename = next_alias_file(alias_filename(), 1);
   }else{
      filename = alias_fn;
   }

   _str temp_install_alias_file='';
   if (filename == '') {
      if (alias_fn=="" && find_builtin_directory_alias(name,orig_view_id,alias_view_id,multi_line_flag,alias_fn,alias_linenum,more_buf_flags)==0) {
         return 0;
      }
      if (!ignore_not_found) {
         temp_install_alias_file=get_env('VSROOT'):+'$alias.als.xml';
         if (!quiet && file_match2(temp_install_alias_file,1,'-p')=='') {
            PreserveFocusMessageBox(nls('Warning: No alias files found: %s',alias_filename()));
         }
      }
      p_window_id=orig_view_id;
      return(FILE_NOT_FOUND_RC);
   }

   int status = 0;
   for (;;) {
      AliasFile aliasFile;
      status = aliasFile.open(filename);
      if (!status) {
         value := aliasFile.getAlias(name, &param);
         if (value != '') {
            _find_or_create_temp_view(alias_view_id, '', '.alias');
            _lbclear();
            p_UTF8 = orig_view_id.p_UTF8;
            p_encoding = orig_view_id.p_encoding;
            p_newline = orig_view_id.p_newline;
            p_indent_with_tabs = orig_view_id.p_indent_with_tabs;

            if (!p_UTF8) value = _UTF8ToMultiByte(value);
            alias_fn = filename; alias_linenum = 1;
            multi_line_flag = pos("\n", value, 1, 'r');
            _insert_text_raw(value); top();
            return(0);
         }
         aliasFile.close();
      }

      filename = next_alias_file('', 0);
      if (filename == '') {
         break;
      }
   }

   if (find_builtin_directory_alias(name,orig_view_id,alias_view_id,multi_line_flag,alias_fn,alias_linenum,more_buf_flags)==0) {
      return 0;
   }
   p_window_id = orig_view_id;
   return(STRING_NOT_FOUND_RC);
}

static int find_builtin_directory_alias(_str name,
                                        int &orig_view_id,int &alias_view_id,
                                        _str &multi_line_flag,
                                        _str &alias_fn,int &alias_linenum,
                                        int more_buf_flags = 0 //Set to non-zero when expanding alias
                                        )
{
   // special case process buffer to include these directory aliases
   // do not include directory aliases in other language modes
   if (_isEditorCtl()) {
      boolean includeGlobalAliasFile = false;
      switch (p_LangId) {
      case '':
      case FUNDAMENTAL_LANG_ID:
      case 'process':
      case 'fileman':
         break;
      default:
         return(STRING_NOT_FOUND_RC);
      }
   }

   // Check if the alias name matches the names of any of the active 
   // projects, and, if so, expand the alias to the path of that project
   // also try to match against the names of directories and containing
   // directories the projects are found in.
   line := "";
   if ( _workspace_filename != "" ) {
      // get the list of project files in this workspace
      _str projectFileList[] = null;
      _WorkspaceGet_ProjectFiles(gWorkspaceHandle, projectFileList);
      // first priority, try each project name.
      foreach (auto i => auto projectName in projectFileList) {
         if (_strip_filename(projectName,'PE') == name) {
            projectName = absolute(projectName, _strip_filename(_workspace_filename,'N'));
            line = _strip_filename(projectName,'N');
            break;
         }
      }
      // try up to four levels up the directory name list
      for (stripCount := 0; stripCount < 4 && line==""; stripCount++) {
         // check the directory path of each project
         foreach (i => projectName in projectFileList) {
            projectName = absolute(projectName, _strip_filename(_workspace_filename,'N'));
            strippedDirectoryName := _strip_filename(projectName,'N');
            // strip off j parts of the path
            for (j := 0; j < stripCount && length(strippedDirectoryName) > 3; j++) {
               strippedDirectoryName = _strip_filename(strippedDirectoryName,'N');
               if (last_char(strippedDirectoryName) == FILESEP) {
                  strippedDirectoryName = substr(strippedDirectoryName,1,length(strippedDirectoryName)-1);
               }
            }
            // check if that directory name matches the path
            if (_strip_filename(strippedDirectoryName,'P') == name) {
               line = strippedDirectoryName:+FILESEP;
               break;
            }
         }
      }
   }

   // next we check for aliases that we should always be able to expand
   // such as jumping to the configuration directory, or macros, build dir,
   // or the temp directory.
   if ( line == "" ) {
      switch (name) {
      case "slickedit":
         line = get_env('VSROOT');
         break;
      case "macros":
         line = get_env('VSROOT'):+"macros":+FILESEP;
         break;
      case "config":
         line = _ConfigPath();
         break;
      case "project":
         line = _strip_filename(_project_name, "N");
         break;
      case "workspace":
         line = _strip_filename(_workspace_filename, "N");
         break;
      case "build":
         line = getActiveProjectConfigObjDir();
         line = _parse_project_command(line, "", _project_name, name);
         break;
      case "temp":
         line = _temp_path();
         break;
      default:
         break;
      }
   }

   // if we didn't find anything then give up
   if ( line == "" ) {
      return STRING_NOT_FOUND_RC;
   }

   // construct a fake temp view of the expanded macro text and return success
   alias_fn = _ConfigPath():+"builtins.als";
   orig_view_id = _find_or_create_temp_view(alias_view_id, "", alias_fn, false, more_buf_flags, true);
   multi_line_flag = 0;
   alias_linenum = 1;
   line = maybe_quote_filename(line);
   if (last_char(line) == "\"") {
      line = substr(line,1,length(line)-1);
   }
   insert_line(line);
   return 0;
}

void _autocomplete_expand_alias(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,boolean onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   p_col -= length(prefix);
   _delete_text(length(prefix));
   _insert_text(insertWord);
   if (onlyInsertWord) {
      return;
   }
   AutoCompleteTerminate();
   expand_alias();
}

int find_alias_completions(var words, boolean forceUpdate=false)
{
   _str aliasFileList='';
   int start_col=0;
   int status=0;

   _str alias_name = '';
   if (p_col==1) {
      alias_name=cur_word(start_col,0);
      if (alias_name=="" && !forceUpdate) {
         return STRING_NOT_FOUND_RC;
      }
      start_col=_text_colc(start_col,"I");
   } else {
      int old_col=p_col;
      save_pos(auto p);
      left();
      status=search('([~\od'_extra_word_chars:+p_word_chars"]|^)\\c","@irh-");
      if (status < 0 && !forceUpdate) return status;
      start_col=p_col;
      if (old_col > start_col) {
         alias_name=_expand_tabsc(start_col,old_col-start_col);
      }
      restore_pos(p);
   }

   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   if (alias_name=="" && !forceUpdate) {
      return STRING_NOT_FOUND_RC;
   }

   // special case process buffer to include the global alias file
   boolean includeGlobalAliasFile = false;
   for (;;) {
      aliasFileList=alias_filename(true,includeGlobalAliasFile);
      if (aliasFileList!='') {
         break;
      }
      if (includeGlobalAliasFile) {
         return(STRING_NOT_FOUND_RC);
      }
      switch (p_LangId) {
      case '':
      case FUNDAMENTAL_LANG_ID:
      case 'process':
      case 'fileman':
         includeGlobalAliasFile=true;
         break;
      default:
         return(STRING_NOT_FOUND_RC);
      }
   }

   // Right now, next_alias_file does not support filenames that contain semicolons.
   _str filename = next_alias_file(aliasFileList,1);
   while (filename != '') {
      AliasFile aliasFile;
      status = aliasFile.open(filename);
      if (status) {
          filename = next_alias_file(aliasFileList,0);
          continue;
      }

      _str aliases:[];
      aliasFile.getAliases(aliases, alias_name);
      foreach (auto match_name => auto alias_text in aliases) {
         _str comments = "<pre>" :+ alias_text :+ "</pre>";
         parse alias_text with auto expanded_alias '\n','r' auto rest;
         if (rest != '') {
            expanded_alias = expanded_alias :+ " ...";
         }

         // get picture indexes for _alias.ico
         if (!_pic_alias) {
            _pic_alias = load_picture(-1,'_alias.ico');
            if (_pic_alias >= 0) {
               set_name_info(_pic_alias, 'Alias or code template');
            }
         }

         // add the result to the list
         if (substr(match_name,1,9) != "=surround") {
            AutoCompleteAddResult(words, 
                                  AUTO_COMPLETE_ALIAS_PRIORITY,
                                  match_name': 'expanded_alias,
                                  _autocomplete_expand_alias, 
                                  comments,
                                  null, 
                                  true, 
                                  _pic_alias, 
                                  match_name);
         }
      }
      aliasFile.close();
      filename = next_alias_file(aliasFileList, 0);
   }
   // that's all folks
   return 0;
}

/**
 * Returns the name of the alias matching the prefix name_prefix.  If a match is not found,
 * '' is returned.  Specify <i>find_first</i> == 1, to start from the first alias and 0 to find
 * the next match.  You must call this function with <i>find_first</i>==2, to terminate matching
 * after no match is found.
 * 
 * @return The name of the alias matching the prefix specified by <i>name</i>.
 * @see alias
 * @see expand_alias
 * @categories Completion_Functions
 */
_str alias_match(_str name,int find_first)
{
   // deprecacted
#if 0
   _str filename='';
   static int orig_view_id;
   static int temp_view_id;
   if ( find_first ) {
      if ( find_first:==2 ) {
         alias_match2('','',2,temp_view_id,orig_view_id);
         return('');
      }
      filename=next_alias_file(alias_filename(),1);
      if ( filename=='' ) {
         orig_view_id=_create_temp_view(temp_view_id,'',filename);
         activate_window(orig_view_id);
         messageNwait(nls('No alias files found: %s',alias_filename()));
         return('');
      }
   }
   _str found_name='';
   for (;;) {
      /* filename does not have to be initialized unless find_first=1 */
      found_name=alias_match2(filename,name,find_first,temp_view_id,orig_view_id);
      if ( found_name!='' ) {
         /* messageNwait('filename='filename' found_name='found_name' findfirst='find_first) */
         return(found_name);
      }
      filename=next_alias_file(alias_filename(),0);
      if ( filename=='' ) {
         return('');
      }
      /* Remove the previous file. */
      alias_match2('','',2,temp_view_id,orig_view_id);
      find_first=1;
   }
#endif
   // deprecated
   return '';
}
void alias_match_names(_str name, _str (&list)[])
{
   _str filename = next_alias_file(alias_filename(), 1);
   int status = 0;
   for (;;) {
      AliasFile aliasFile;
      status = aliasFile.open(filename);
      if (!status) {
         aliasFile.getNames(list, name);
         aliasFile.close();
      }
      filename = next_alias_file('', 0);
      if (filename == '') {
         break;
      }
   }
}

boolean alias_find(_str name)
{
   _str filename = next_alias_file(alias_filename(), 1);
   int status;
   for (;;) {
      AliasFile aliasFile;
      status = aliasFile.open(filename);
      if (!status) {
         if (aliasFile.hasAlias(name)) {
            return true;
         }
         aliasFile.close();
      }
      filename = next_alias_file('', 0);
      if (filename == '') {
         break;
      }
   }
   return false;
}


static void PreserveFocusMessageBox(_str text, _str title='', typeless flags='')
{
   int focus_wid=_get_focus();
   if (flags=='') {
      _message_box(text,title);
   } else {
      _message_box(text,title,flags);
   }
   if (focus_wid) {
      focus_wid._set_focus();
   }
}


_str _check_alias_name(_str name, typeless obj)
{
   if (!isid_valid(name)) {
      _message_box('Invalid alias name.');
      return INVALID_ARGUMENT_RC;
   }

   if (obj) {
      AliasFile* aliasFile = (AliasFile*)obj;
      if (aliasFile->hasAlias(name)) {
         int status = _message_box("An alias already exists named \""name"\".  Overwrite?", "SlickEdit", MB_YESNO);
         if (status == IDNO) return COMMAND_CANCELLED_RC;
         aliasFile->deleteAlias(name);
      }
   }
   return 0;
}

/**
 * Create a new extension specific alias containing the currently
 * selected text.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command int new_alias(_str name="", boolean showInAliasEditor=true) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   // this command requires a selection
   if (!select_active()) {
      _message_box("Selection required");
      return NOTHING_SELECTED_RC;
   }

   // get the name for the extension specific alias file for this extension
   _str alias_filename = _get_lang_alias_filename();
   if (alias_filename == "") {
      _message_box("No language specific alias file!");
      return FILE_NOT_FOUND_RC;
   }
   alias_filename = absolute(alias_filename, _ConfigPath());
   alias_lang := _get_lang_alias();
   int status = 0;
   AliasFile aliasFile;
   status = aliasFile.open(alias_filename, getAliasLangProfileName(alias_lang));
   if (status) {
      aliasFile.create(_get_lang_alias());
   }

   // make sure we have a valid alias name
   if (name == "") {
      status = textBoxDialog("Enter New Alias Name", 0, 0, "Enter New Alias Name dialog", "", "", 
                           "-e _check_alias_name:"(typeless)&aliasFile" Alias name:");
      if (status < 0) {
         return status;
      }
      name = _param1;
   }

   if (_check_alias_name(name, &aliasFile) != 0) {
      return INVALID_ARGUMENT_RC;
   }

   // open the alias file name in a temporary window
   int alias_view_id=0;
   int orig_view_id=0;
   orig_view_id=_create_temp_view(alias_view_id,'','.als');
   if (orig_view_id < 0) {
      _message_box("Could not open temp view!");
      return FILE_NOT_FOUND_RC;
   }
   p_window_id=alias_view_id;

   // duplicate the current selection
   typeless mark= _duplicate_selection();
   if ( mark<0 ) {
      _message_box("Could not duplicate selection!");
      _delete_temp_view(alias_view_id);
      p_window_id=orig_view_id;
      return(mark);
   }

   p_window_id=alias_view_id;
   bottom();
   if (_select_type()!='LINE') {
      insert_line("");
   }
   int start_line = p_line;
   if (_select_type()=='LINE') {
      start_line++;
   }

   // Make a copy of the current selection so we dont loose it.
   p_col=1;
   status=_copy_to_cursor(mark);
   _free_selection(mark);

   // now determine the amount to shift selection over
   int min_col = MAXINT;
   p_line = start_line;
   do {
      int col = _first_non_blank_col(min_col);
      if (col < min_col) min_col = col;
   } while ( !down() );

   // now shift over the rest of the selection for alignment
   _str line="";
   _str value="";
   p_line = start_line;
   do {
      get_line(line);
      line = stranslate(line, "%%", "%");
      line = substr(line, _text_colc(min_col,'p'));
      strappend(value, line"\n");
   } while ( !down() );

   if (!p_UTF8) value = _MultiByteToUTF8(value);
   // save the modified alias file
   aliasFile.insertAlias(name, value);
   aliasFile.save(alias_filename);
   aliasFile.close();

   // clean up and return final status
   _delete_temp_view(alias_view_id);
   p_window_id=orig_view_id;

   // now bring up the alias editor and focus on the selected alias
   if (!showInAliasEditor) {
      return 0;
   }
   return alias("-e "name);
// showAliasEditorForFilename(alias_filename, name);
// return 0;
}

/**
 * Determines whether we can expand an alias after a user has pressed space, 
 * triggering syntax expansion. 
 * 
 * @param origWord                  original word as user typed it
 * @param word                      abbreviated word as determined by 
 *                                  min_abbrev2
 * @param aliasFilename             filename where we should check for an alias 
 * @param expandResult              0 if the expansion was not attempted or 
 *                                  successful, a non-zero value otherwise
 * 
 * @return int                      0 if we handled the space press, 1 if we 
 *                                  did not (not to be confused with whether the
 *                                  expand operation was successful)
 */
int maybe_auto_expand_alias(_str origWord, _str word, _str aliasFilename, int &expandResult)
{
   // initialize this to 0 in case we don't try to expand
   expandResult = 0;

   // we can't do anything with this
   if (aliasFilename == null) return 0;

   // do we have anything worth looking at?
   if (word != '' && aliasFilename != '') {

      // if the alias has already been all entered, just add a space
      if (origWord :== word && origWord == get_alias(word, auto mult_line_info, 1, aliasFilename)) {
         _insert_text(' ');
         return(0);
      }

      // figure out how many spaces we need
      col := p_col - _rawLength(origWord);
      linePrefix := '';
      if (col != 1) {
         linePrefix = indent_string(col - 1);
      }

      // throw in our spaces, put the cursor in the right spot
      replace_line(linePrefix);
      p_col = col;

      // just expand the alias and call it a day
      expandResult = expand_alias(word, '', aliasFilename, false, true);

      // we return a 0 because we did handle the space event, even if the 
      // expand operation was not successful
      return 0;
   }

   // we didn't do anything
   return 1;
}

