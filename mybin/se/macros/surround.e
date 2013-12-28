////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49748 $
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
#include "vsevents.sh"
#include "color.sh"
#include "markers.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/alias/AliasFile.e"
#require "notifications.e"
#import "se/tags/TaggingGuard.e"
#import "alias.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "bind.e"
#import "bookmark.e"
#import "c.e"
#import "cformat.e"
#import "clipbd.e"
#import "codehelp.e"
#import "color.e"
#import "context.e"
#import "debug.e"
#import "keybindings.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "put.e"
#import "recmacro.e"
#import "saveload.e"
#import "seek.e"
#import "selcode.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagfind.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;
using se.alias.AliasFile;

/**
 * surround with templates can be separated from all other aliases
 * by checking if the name of the alias begins with this prefix
 */
static _str gprefix = '=surround_with_';

/**
 * Surround with templates will be copied from files in the sysconfig
 * directory based on the version number.  SURROUND_VERSION is the last
 * version to be added to the sysconfig directory
 */
#define SURROUND_VERSION 9

// these must be static because they are used by sur_text which is not called directly

/**
 * set to true while expanding the alias.  sur_text checks this value
 * first and will exit with an error if it is false
 */
static boolean in_surround_mode=false;
/**
 * set to true while expanding a code template.  sur_text checks this
 * value and will not paste any code when it is set
 */
static boolean in_code_template_mode=false;
/**
 * the number of times that sur_text is called from within a template
 */
static int gsur_block_count;
/**
 * set to non-zero if there is an error expanding the template<br>
 * <br>
 * There used to be one possible error involving the insert_code_template
 * command, but that possibility has been removed.  This variable is
 * being left in so that any future error detection can set it easily
 * and have the condition handled.
 */
static int gexpansion_error;
/**
 * when set to true, handle_surround_selection will attempt to
 * re-create the user's orginal selection after expanding the alias
 */
static boolean greselect;
/**
 * The position stored by _save_pos2 at the beginning of the last call
 * to sur_text.  Only used if greselect is true.
 */
static typeless gstart_new_text;
/**
 * The position stored by _save_pos2 at the end of the last call to
 * sur_text.  Only used if greselect is true.
 */
static typeless gend_new_text;
/**
 * The view id that contains a temporary buffer with the selected text
 */
static int gtemp_view_id=0;
/**
 * The position stored by save_pos at the end of the alias expansion
 * before the cursor is repositioned to any %\c marks that may have
 * been in the alias
 */
static int gend_alias_expansion;
/**
 * If set to true, handle_surround_selection will not attempt to
 * beautify the results of the template expansion.
 */
static boolean gno_beautify;

/**
 * Structure used to hold information about the current template
 * expansion and simplify parameter passing
 */
static struct sur_selection_parameters {
   int      id;               // the markid created when extracting the selected text
   _str     orig_id;          // the markid passed into surround-with
   _str     type;             // the type of the original selection 'CHAR', 'LINE' or 'BLOCK'
   int      leading_spaces;   // the number of selected spaces before the first non-whitespace character
   int      trailing_lines;   // the number of selected lines after the last non-whitespace character
   int      trailing_col;     // the number of selected spaces on the last line
   boolean  add_macro_call;   // set to true during macro recording and a function call needs to be inserted
   _str     macro_function;   // the function call to insert, either 'surround-with' or 'insert-code-template'
};

static void update_existing_aliases(_str alias_file, _str new_aliases_file, _str lang)
{
   int status;

   _str filename = usercfg_path_search(alias_file);
   if (filename == '') {
      filename = _ConfigPath():+alias_file;
   }

   alias_profile := getAliasLangProfileName(lang);

   AliasFile newAliasFile;
   status = newAliasFile.open(new_aliases_file, alias_profile);
   if (status) {
      return;
   }
   AliasFile aliasFile;
   status = aliasFile.open(filename, alias_profile);
   if (status) {
      aliasFile.create(alias_profile);
   }

   _str new_aliases:[];
   newAliasFile.getAliases(new_aliases);
   foreach (auto name => auto value in new_aliases) {
      aliasFile.insertAlias(name, value);
   }

   // always save the file in the user's configuration directory
   filename = _ConfigPath():+_strip_filename(alias_file,'P');
   aliasFile.save(filename);
   aliasFile.close();
   newAliasFile.close();
}

/**
 * Add any new surround-with templates for the specified extension to the
 * user's alias file
 *
 * @param surround_version the version of the templates to look for
 * @param lang    Language ID (see {@link p_LangId} 
 */
static void sur_update_language(int surround_version,_str lang)
{
   new_aliases := get_env('VSROOT'):+'sysconfig'FILESEP'aliases'FILESEP'$'surround_version:+lang'.als.xml';
   if (!file_exists(new_aliases)) {
      // no new aliases for this extension in this version
      return;
   }

   // is there a filename for this extension stored in a def-var
   filename := LanguageSettings.getAliasFilename(lang, '');
   if (filename != '') {
      parse filename with filename (PATHSEP) .;
   } else {
      filename = lang'.als.xml';
      LanguageSettings.setAliasFilename(lang, filename);
   }

   update_existing_aliases(filename, new_aliases, lang);
}

/**
 * Check if any of the automatic surround with template 
 * definitions for this language are out of date and update them
 * as necessary 
 */
void update_lang_surround_definitions(_str langId = '')
{
   // no language?  pull it from the editor window
   if (langId == '') {
      bufWid := _edit_window();
      if (bufWid.p_HasBuffer ) {
         langId = bufWid.p_LangId;
         if (bufWid._inJavadoc()) langId = 'html';
      }
   }

   if (langId == '') return;

   // get the current surround version for this language
   curVersion := LanguageSettings.getSurroundWithVersion(langId);

   // maybe no update is needed?
   if (curVersion >= SURROUND_VERSION) return;

   // walk through all versions
   while (curVersion < SURROUND_VERSION) {
      // update!
      ++curVersion;
      sur_update_language(curVersion, langId);
   }

   // save the new version
   LanguageSettings.setSurroundWithVersion(langId, curVersion);
}

/**
 * helper function for parsing the options to sur_text
 *
 * allow the user to have hypens in the prefix or suffix text
 * by only terminating the text option with the end of the
 * of the macro parameters or the next valid option
 */
static void get_text_option(_str& current_option, _str& options)
{
   boolean found_next_parm=false;
   int end_opt=1;
   _str next_opt;

   do {
      end_opt=pos(' -', options,end_opt);
      if (end_opt==0) {
         end_opt=length(options);
         found_next_parm=true;
      } else {
         parse substr(options, end_opt) with next_opt .;
         switch (upcase(next_opt)) {
         case '-BEAUTIFY':
         case '-BEGIN':
         case '-DESELECT':
         case '-END':
         case '-IGNORE':
         case '-INDENT':
         case '-LOWCASE':
         case '-NOBEAUTIFY':
         case '-NOTEXT':
         case '-SELECT':
         case '-STRIPBEGIN':
         case '-STRIPEND':
         case '-UPCASE':
            found_next_parm=true;
            --end_opt; // don't take the space separating the options
            break;
         default:
            ++end_opt; // skip past hypen
         }
      }
   } while ( !found_next_parm );
   current_option=substr(options, 1, end_opt);
   options=substr(options, end_opt);
}

/**
 * <tt>sur_text</tt> is a Slick-C&reg; function that can only be used 
 * inside of a {@link surround_with surround-with} template.  
 * <tt>sur_text</tt> is used to indicate where the selected text
 * should be placed and can be used multiple times within a single
 * surround-with template.  sur_text can take several parameters, 
 * which can appear in any order.  The available parameters are:
 * <ul>
 *    <li><b>-beautify</b>    -- (Default for C, Java, and others) 
 *                               Beautify the results of the template expansion.
 *    <li><b>-nobeautify</b>  -- (Default for HTML, XML and others) 
 *                               Do not attempt to beautify the results of the
 *                               template expansion.
 *    <li><b>-deselect</b>    -- (Default) Do not leave the text selected/
 *    <li><b>-begin &lt;text&gt;</b>-- Prefix each line of the selection with <i>text</i></dd>.
 *    <li><b>-end &lt;text&gt;</b>  -- Suffix each line of the selection with <i>text</i>.
 *    <li><b>-ignore</b>      -- The -begin, -indent, -lowcase, -stripbegin and
 *                               -upcase options will ignore any <i>chars</i>. 
 *                               when finding the beginning of the selected line.
 *    <li><b>-lowcase</b>     -- Convert each line of the selection to upper case
 *    <li><b>-upcase</b>      -- Convert each line of the selection to lower case
 *    <li><b>-indent</b>      -- Indent each line of selection.
 *    <li><b>-notext</b>      -- Do not paste any text.
 *    <li><b>-select</b>      -- Leave the text selected
 *    <li><b>-stripbegin &lt;text&gt;</b> -- If any line begins with <i>text</i>, 
 *                                     <i>text</i> will be removed from the line.
 *                                     This option is applied before -begin.
 *    <li><b>-stripend &lt;text&gt;</b>   -- If any line ends with <i>text</i>,
 *                                     <i>text</i> will be removedm the line.  
 *                                     This option is applied before -end.
 * </ul>
 * <p>
 * This function can also be used during alias expansion to indicate
 * where the surrounding text should be inserted in order to invoke
 * dynamic surround immediately after expanding an alias.
 * 
 * @see surround_with
 * @see expand_alias
 * @categories Editor_Control_Methods
 */
void sur_text(_str options='')
{
   if (!in_surround_mode) {
      if (in_dynamic_surround_mode()) {
         set_surround_mode_end_line(p_line+1);
      } else {
         message("sur-text should only be used to expand surround-with templates");
      }
      return;
   }

   ++gsur_block_count;

   boolean use_indent=false;
   greselect=false;
   _str ml_begin='';
   _str ml_end='';
   _str ml_ignore='';

   _str strip_end='';
   _str strip_begin='';

   boolean force_upcase=false;
   boolean force_lowcase=false;

   _str opt;
   boolean no_text=false;

   // set to true if some operation must be
   // applied to every inserted line
   boolean adjust_lines=false;

   while (options!='') {
      parse options with opt options;

      opt = upcase(opt);

      switch (opt) {
      case '-BEAUTIFY':
         gno_beautify=false;
         break;
      case '-BEGIN':
         get_text_option(ml_begin,options);
         adjust_lines=true;
         break;
      case '-DESELECT':
         greselect=false;
         break;
      case '-END':
         get_text_option(ml_end,options);
         adjust_lines=true;
         break;
      case '-IGNORE':
         parse options with ml_ignore options;
         break;
      case '-INDENT':
         use_indent=true;
         adjust_lines=true;
         break;
      case '-LOWCASE':
         force_lowcase=true;
         adjust_lines=true;
         break;
      case '-NOBEAUTIFY':
         gno_beautify=true;
         break;
      case '-NOTEXT':
         no_text=true;
         break;
      case '-SELECT':
         greselect=true;
         break;
      case '-STRIPBEGIN':
         get_text_option(strip_begin,options);
         adjust_lines=true;
         break;
      case '-STRIPEND':
         get_text_option(strip_end,options);
         adjust_lines=true;
         break;
      case '-UPCASE':
         force_upcase=true;
         adjust_lines=true;
      }
   }

   if (in_code_template_mode || no_text) {
      greselect=false;
      return;
   }

   // when inserting extra text (-begin or -indent), skip any text
   // that may be before the insertion point and on the same line
   int first_line_offset=_text_colc(p_col,'T');
   // when inserting extra text (-end), skip any text that may be
   // after the insertion point and on the same line
   int first_line_extra=0;

   if (first_line_offset<0) {
      // something has gone wrong, but try to finish anyway
      first_line_offset=-first_line_offset;
   } else {
      get_line(auto first_line_text);

      first_line_extra=length(first_line_text)-first_line_offset+1;
      if (first_line_extra<0) {
         // this could happen with virtual space
         first_line_extra=0;
      }
   }

   // paste the text and figure out how many lines are being used
   int first_line=p_line;
   _save_pos2(gstart_new_text);
   {
      int orig_view_id;
      get_window_id(orig_view_id);
      activate_window(gtemp_view_id);
      int markid=_alloc_selection();
      if (markid>=0) {
         top();_select_char(markid);
         bottom();
         _select_char(markid);
         activate_window(orig_view_id);
         _copy_to_cursor(markid);_end_select(markid);
         _free_selection(markid);
      } else {
         activate_window(orig_view_id);
         _insert_text('ERROR - failed to insert text');
      }
   }
   int last_line=p_line;

   deselect(); // always deselect for consistency (user options can change behavior of paste)

   if (adjust_lines) {
      int edit_line;
      _str text;
      int pcol;   // physical column
      int lcol;   // logical column
      for (edit_line=first_line;edit_line<=last_line;++edit_line) {
         p_line=edit_line;
         get_line(text);

         if (text!='') {
            // skip beginning of template on first line of selected text
            if (edit_line!=first_line) {
               first_line_offset=1;
               first_line_extra=0;
            }

            // collect information about the insertion point
            pcol=pos('~[ \t'ml_ignore']', text, first_line_offset, 'r');
            lcol=text_col(text,pcol,'I');

            // separate the text into three parts.
            // the leading and trailing parts together make the orginal line
            // before the "paste" (copy_to_cursor) and the remaining
            // text is subject to any additional operations
            _str leading_text=substr(text,1,pcol-1);
            _str trailing_text=substr(text,length(text)-first_line_extra+1);
            text=substr(text,pcol,length(text)-pcol-first_line_extra+1);

            // check for the leading pattern
            if ((strip_begin!='')&&(strip_begin==substr(text,1,length(strip_begin)))) {
               text=substr(text,length(strip_begin)+1);
            }

            // and the trailing pattern
            if ((strip_end!='')&&(strip_end==substr(text,length(text)-length(strip_end)+1))) {
               text=substr(text,1,length(text)-length(strip_end));
            }

            if (force_upcase) {
               text=upcase(text);
            } else if (force_lowcase) {
               text=lowcase(text);
            }

            replace_line(leading_text:+text:+trailing_text);

            p_col=lcol;
            if (use_indent) {
               move_text_tab();
               if (edit_line==first_line) {
                  // save the new point to start the re-selection of the moved code
                  _save_pos2(gstart_new_text);
               }
            }

            _insert_text(ml_begin);
            end_line();
            _insert_text(ml_end);
         }
      }
   }

   _save_pos2(gend_new_text);
}

/**
 * Callback (of sorts) from the alias expansion to capture the final
 * expansion position.
 */
void surround_save_end_pos()
{
   gend_alias_expansion = _nrseek();
   set_surround_mode_num_lines();
}

/**
 * Determine if files of the specificed extension should have
 * surround-with templates beautified or not if neither the
 * -nobeautify or -beautify options are given to sur_text
 */
static boolean default_beautify(_str lang)
{
   //html=html cfml=html xml=html xsd=html vpj=xml
   return (!_LanguageInheritsFrom('html',lang) &&
           !_LanguageInheritsFrom('cfml',lang) &&
           !_LanguageInheritsFrom('xml',lang) &&
           !_LanguageInheritsFrom('xsd',lang) &&
           !_LanguageInheritsFrom('vpj',lang) &&
           !_LanguageInheritsFrom('vpw',lang));
}

/**
 * This function does runs expand_macro and handles any reselection, beautification, and
 * macro recording work that needs to be done.
 *
 * @param sur_params most of the data that is needed to do the expansion
 * @param full_alias the full name of the alias to be expanded.  includes the =surround_with_ prefix
 */
static void handle_surround_selection(sur_selection_parameters& sur_params,_str full_alias)
{
   // if the user is recording a macro, add a call to surround-with with the
   // selected alias
   if (sur_params.add_macro_call) {
      // macro recording may have been turned off
      // turn it back on
      _macro('M',1);
      _macro_call(sur_params.macro_function,substr(full_alias,length(gprefix)+1));;
   }
   boolean show_error=false;
   int orig_view_id=p_window_id;
   _create_temp_view(gtemp_view_id);
   insert_line(''); // _move_to_cursor fails unless a dummy line is inserted
   _move_to_cursor(sur_params.id);
   activate_window(orig_view_id);

   int first_col_of_template=p_col;
   _free_selection(sur_params.id);
   sur_params.id=-1;

   typeless start_expand_pos;
   _save_pos2(start_expand_pos);
   save_pos(auto pp1);
   p_col= 1;
   start_expand_offset := _QROffset();
   restore_pos(pp1);

   gsur_block_count=0;
   gno_beautify=!default_beautify(p_LangId);

   if (sur_params.orig_id=='') {
      deselect();
   }
   in_surround_mode=true;
   gexpansion_error=0;
   expand_alias(full_alias);
   // can not set in_surround_mode to false here.  sur_text
   // might be called later to restore the orginal text if
   // the alias does not include a call to sur_text

   expand_beautified := beautify_alias_expansion(p_LangId);
   _str lang = p_LangId;
   if (gsur_block_count==0 || gexpansion_error) {
      // do away with anything generated by the alias
      _nrseek(gend_alias_expansion);
      select_char();
      _restore_pos2(start_expand_pos);
      select_char();
      delete_selection();

      if (gsur_block_count==0) {
         // expand_alias never called sur_text
         show_error=true;

         // and now restore the old text
         sur_text();

         // try to restore the orginal selection
         greselect=true;
      }
   } else if( (!gno_beautify) && (!BeautifyCheckSupport(lang)) && !expand_beautified ) {
      // sur_text was called, try to beautify the generated code

      // figure out if the alias has a %\c mark in it
      boolean mark_cursor=(_nrseek()!=gend_alias_expansion);

      // try to preserve the cursor position through the beautify
      // neither save/restore_pos nor _save/_restore_pos2 work if
      // the cursor should change lines during a beautify

      // drop a funny character, so we can look for it later
      if (mark_cursor) {
         _insert_text(_chr(3));
      }

      // start the selection
      _GoToROffset(start_expand_offset);
      select_char();

      _nrseek(gend_alias_expansion+1);
      // end the selection
      select_char();

      beautify_selection();
      deselect();

      if (mark_cursor) {
         _str ss_search_string;
         int ss_flags;
         _str ss_word_re;
         _str ss_ReservedMore;
         int ss_flags2;
         save_search(ss_search_string,ss_flags,ss_word_re,ss_ReservedMore,ss_flags2);
         down();end_line(); // just to be sure we search the end of the expanded alias
         search(_chr(3),'@h-<');   // search backwards and leave the cursor at the start of the match
         linewrap_delete_char();
         restore_search(ss_search_string,ss_flags,ss_word_re,ss_ReservedMore,ss_flags2);
      }
   }
   _delete_temp_view(gtemp_view_id);
   in_surround_mode=false;

   if (greselect) {
      typeless final_cursor_pos;
      _save_pos2(final_cursor_pos);

      _restore_pos2(gend_new_text);
      // re-select the moved (and possibly modified) text
      if ((sur_params.trailing_lines>0)&&(sur_params.type!='BLOCK')) {
         down(sur_params.trailing_lines);
         p_col=sur_params.trailing_col;
      }

      switch (sur_params.type) {
      case 'LINE':
         _select_line();
         break;
      case 'BLOCK':
         _select_block();
         break;
      case 'CHAR':
         _select_char();
         break;
      default:
         _message_box('unrecognized select type "'sur_params.type'"');
         break;
      }
      _restore_pos2(gstart_new_text);
      if (sur_params.leading_spaces<0) {
         begin_line();
      } else {
         int space_count;
         for (space_count=0;space_count<sur_params.leading_spaces;++space_count) {
            left();
         }
      }
      switch (sur_params.type) {
      case 'LINE':
         _select_line();
         break;
      case 'BLOCK':
         _select_block();
         break;
      case 'CHAR':
         _select_char();
         break;
      }
      _restore_pos2(final_cursor_pos);
   }
   if (show_error) {
      _message_box('surround-with aliases must contain %\m sur_text (options)%');
   }
}

/**
 * generates the full alias name and calls handle_surround_selection
 *
 * @param sur_params most of the data that is needed to do the expansion
 * @param caption abbreviated name of the alias
 */
static void handle_surround_caption(sur_selection_parameters& sur_params,_str caption)
{
   _str full_alias = gprefix;
   strappend(full_alias, caption);
   //full_alias = translate(full_alias, '_', '-');

   handle_surround_selection(sur_params,full_alias);
}

/**
 * Try to match the abbreviated alias name against any of the defined
 * surround with templates
 *
 * @param sur_params most of the data that is needed to do the expansion
 * @param caption abbreviated name (or prefix) of the alias
 *
 * @return non-zero if a match was found and handle_surround_selection
 *         was called
 */
static int maybe_use_arg(sur_selection_parameters& sur_params,_str caption)
{
   int ret_value=0;
   _str full_alias = gprefix;
   strappend(full_alias, caption);
   if (alias_find(full_alias)) {
      handle_surround_selection(sur_params,full_alias);
      ret_value=1;
   }
   return(ret_value);
}

/**
 * Move the cursor to the beginning of the specified selection
 *
 * @param markid the selection to use
 */
static void sur_begin_select(_str markid)
{
   // go to the first line of the selection
   begin_select(markid);

   // begin_select does not move the cursor to the beginning of the line
   // in a line selection
   if (_select_type()=='LINE') {
      begin_line();
   }
}

/**
 * Move the cursor to the end of the specified selection
 *
 * @param markid the selection to use
 */
static void sur_end_select(_str markid)
{
   // go to the last line of the selection
   end_select(markid);

   // end_select does not move the cursor to the end of the line
   // in a line selection
   if (_select_type(markid)=='LINE') {
      end_line();
   } else if (_select_type(markid)=='BLOCK') {
      right();
   } else if (_select_type(markid, 'I')==1) {
      right();
   }
}

/**
 * Deteremine if the cursor is at or past the end of the current
 * line
 *
 * @return true if the cursor is at or past the end of the current
 *         line
 */
boolean at_end_of_line()
{
   int column=p_col;
   _end_line();
   boolean at_end=(column>=p_col);
   p_col=column;
   return(at_end);
}

/**
 * this function esentally calls strip() on the selection.  sur_params.id
 * is adjusted to the stripped version of the specified selection.
 *
 * @param sur_params most of the data that is needed to do the expansion
 * @param markid the selection to adjust
 */
static void select_text(sur_selection_parameters& sur_params, _str markid)
{
   sur_params.type=_select_type(markid);

   // find the start of the text leaving any initial whitespace
   sur_begin_select(markid);

   int first_column=p_col;
   first_non_blank();

   // if the selection does not start at the beginning of a line
   if (p_col < first_column) {
      // use the start of the selection
      begin_select(markid);
      sur_params.leading_spaces=0;
      // otherwise leave the cursor at the first character
      // and record the number of leading spaces that are being strip
   } else if ((first_column==1)&&(p_col!=1)) {
      // if the selection starts that the beginning of the line
      // and that is not the start of the text, special case this
      // so that always go to the beginning of the line even if
      // the indent option is used and the number of leading spaces
      // on the selection has to grow
      sur_params.leading_spaces=-1;
   } else {
      // either the text starts at column one or the user
      // has some number of leading spaces selected
      sur_params.leading_spaces=p_col-first_column;
   }

   typeless start_of_text;
   save_pos(start_of_text);
   int start_of_text_col=p_col;

   // find the end position
   end_select(markid);

   first_non_blank();
   first_column = p_col;
   sur_end_select(markid);
   sur_params.trailing_lines=0;
   sur_params.trailing_col=p_col;

   while (first_column >= p_col) {
      // there is nothing selected on this line but whitespace
      //   keep looking for end of selected text
      if (up()) break;
      first_non_blank();
      first_column = p_col;
      end_line();
      ++sur_params.trailing_lines;
   }

   // do not allow the selection to go past the end of the last line (problem in block selection mode)
   int cur_col=p_col;
   end_line();
   if (cur_col<p_col) {
      p_col=cur_col;
   }

   int compare_result=_begin_select_compare(markid);
   if ( (compare_result<0) || ((compare_result==0) && (p_col<=start_of_text_col)) ) {
      _free_selection(sur_params.id);
      sur_params.id=_duplicate_selection(markid);
      sur_begin_select(sur_params.id);
   } else {
      _select_char(sur_params.id);
      restore_pos(start_of_text);
      _select_char(sur_params.id); // lock the selection
   }
}

/**
 * Determine if mac_call is a call to function
 */
static boolean is_call_to(_str mac_call,_str function)
{
   if (1==pos('^'function'\(',mac_call,1,'R')) {
      return true;
   }
   if (1==pos("^execute\\('"function"[' ]",mac_call,1,'R')) {
      return true;
   }
   return false;
}

typeless get_surround_with_templates(_str search_string='') 
{
   // find all aliases that match the prefix
   int prefix_length = length(gprefix);
   _str names[];
   alias_match_names(search_string, names);
   for (i := 0; i < names._length(); ++i) {
      names[i] = translate(substr(names[i], prefix_length+1),' ', '_');
   }
   names._sort('ID');
   return names;
}

static _str _surround_with_callback(int reason,var result,_str key)
{
   if (key==4 && !_no_child_windows()) {
      _mdi.p_child.alias("-surround");
      _str temps[] = get_surround_with_templates();
      _sellist._lbclear();
      int num_temps = temps._length();
      while (num_temps > 0) {
         --num_temps;
         _sellist._lbadd_item(temps[num_temps]);
      }
   }
   return '';
}

/**
 * Surrounds the selected block of text with a control structure or tag.
 * <br>
 * <p>
 * <b>sur_text</b> is a Slick-C&reg; function that can only be used inside 
 * of a surround-with template.  <b>sur_text</b> is used to indicate where
 * the selected text should be placed and can be used multiple times within
 * a single surround-with template.  <b>sur_text</b> can take several options.
 * Please see {@link sur_text} for more information.
 *
 * @param prefix Specifies the name of the surround-with template to use.  
 *               If no argument is given or if multiple possible templates 
 *               are found, the user is prompted to select the template
 *               they wish to use.
 * @param markid Specifies the selection block to use.
 * @param prompt if false and multiple matches are found, 
 *               it is handled as if no matches were found
 * 
 * @return zero if a surround with template was expanded
 * 
 * @see sur_text
 * @see "Alias Facility"
 * @categories Editor_Control_Methods
 */
_command int surround_with(_str prefix='',_str markid='',boolean prompt=true) name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK)
{
   // if the user is recording a macro, bringing up a dialog and having them
   // make a selection really screws up the macro.  So if a macro is being
   // recorded, the call is first removed, then if a surround-with alias is
   // actually run (the user doesn't cancel out from the selection dialog)
   // a macro call is added with the selected alias as a parameter so that
   // the dialog is not displayed during playback.
   _str mac_call=strip(_macro_get_line());
   boolean add_macro_call=false;
   boolean is_call_to_sur_with = is_call_to(mac_call,'surround-with');
   
   if (is_call_to_sur_with || is_call_to(mac_call,'insert-code-template')) {
      _macro_delete_line();
      add_macro_call=true;
      // the call to surround-with may have come from the context menu
      // which also does not need to be played back
      mac_call=strip(_macro_get_line());
      if (mac_call=='context_menu();') {
         _macro_delete_line();
      }
   }

   // check for a usable selection
   if (markid=='') {
      if (!select_active()) {
         select_code_block();
      }
      if (!select_active()) {
         message('Error: surround-with could not find a selection.');
         return (1);
      }
      lock_selection();
   }

   update_lang_surround_definitions();

   // save the initial cursor position in case the user cancels the
   // operation after they are prompted with the list, or if no
   // possible aliases were found
   typeless initial_pos;
   save_pos(initial_pos);

   sur_selection_parameters sur_params;

   sur_params.id=_alloc_selection();
   sur_params.orig_id=markid;

   if (sur_params.id<0) {
      message('Error: surround-with could not allocate a new selection block');
      return (1);
   }

   select_text(sur_params, markid);
   sur_params.add_macro_call=add_macro_call;
   if (is_call_to_sur_with) {
      sur_params.macro_function='surround_with';
   } else {
      sur_params.macro_function='insert_code_template';
   }

   _str search_string;

   if (prefix != '') {
      if (maybe_use_arg(sur_params,prefix)) {
         // sur_params.id freed by handle_surround_selection
         return gexpansion_error;
      }
      // there was more than one possible alias
      search_string = gprefix :+ prefix;
   } else {
      search_string = gprefix;
   }

   typeless temps = get_surround_with_templates(search_string);

   int num_temps = temps._length();
   if (num_temps == 0) {
      _free_selection(sur_params.id);
      if (prefix=='') {
         message('no surround-with templates found for this language');
      } else {
         message('no surround-with templates found starting with "'prefix'"');
      }
      restore_pos(initial_pos);
      return (1);
   } else if (!prompt) {
      _free_selection(sur_params.id);
      return (1);
   }

   int temp_view_id;
   typeless orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return (1);

   // The buffer and view allocated by _create_temp_view are active
   while (num_temps) {
      --num_temps;
      _lbadd_item(temps[num_temps]);
   }

   //  The original view must be activated before showing the _sellist_form
   typeless result=show('_sellist_form -xy -mdi -modal',
                        "Surround With...",
                        SL_VIEWID|SL_SELECTCLINE|SL_SIZABLE|SL_COMBO|SL_SELECTPREFIXMATCH, // Indicate the next argument is a view_id
                        temp_view_id,
                        "OK,Customize...",
                        "Surround With dialog",  // Help item
                        '',  // Use default font
                        _surround_with_callback,   // Call back function
                        '',
                        'choose_surround_with'                         // retrieve name
                        );
   activate_window(orig_view_id);
   if (result == "") {
      _free_selection(sur_params.id);
      restore_pos(initial_pos);
      return (1);
   }

   handle_surround_caption(sur_params,translate(result,'_', ' '));
   // sur_params.id freed by handle_surround_selection

   return gexpansion_error;
}

/**
 * The most common usage of the {@link surround-with} to surround a block of code with an if statement
 *
 * @see surround-with
 */
_command void surround_with_if() name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK | VSARG2_REQUIRES_AB_SELECTION)
{
   surround_with('if');
}

/**
 * Inserts a code template.  The code templates are defined as surround-with templates.
 * This only uses surround-with as its base instead of working with aliases directly
 * so that the template prompting, recorded macro handling and beautification of surround-with
 * can be leveraged.  Also it will keep the code templates separate from the regular aliases.
 * 
 * @param prefix Specifies the name of the surround-with template to use.  If no argument
 *               is given or if multiple possible templates are found, the user is prompted
 *               to select the template they wish to use.
 *
 * @param prompt if false and multiple matches are found, it is handled as if no matches were found
 *
 * @return zero if a code template was expanded
 * @see "Alias Facility"
 * @categories Editor_Control_Methods
 */
_command int insert_code_template(_str prefix='',boolean prompt=true) name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK)
{
   typeless cursor_pos;
   _save_pos2(cursor_pos);

   in_code_template_mode=true;
   int ret_value=expand_surround_with(' ',true,prefix,prompt);
   in_code_template_mode=false;

   if (ret_value) {
      _restore_pos2(cursor_pos);
   }

   return ret_value;
}

/**
 * Inserts the specified text, selects it, and then runs {@link surround_with}
 *
 * @param text The text to insert and surround
 *
 * @param delete_on_error If true and there is an error expanding the template, delete
 *                        the inserted text
 *
 * @param prefix Specifies the name of the surround-with template to use.  If no argument
 *               is given or if multiple possible templates are found, the user may be
 *               prompted to select the template they wish to use.
 *
 * @param prompt if false and multiple matches are found, it is handled as if no matches were found
 * 
 * @return zero if a code template was expanded
 * @see "Alias Facility"
 * @categories Editor_Control_Methods
 */
_command int expand_surround_with(_str text=' ',boolean delete_on_error=false,_str prefix='',boolean prompt=true) name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK)
{
   int mark_id=_alloc_selection();
   if (mark_id<0) {
      return mark_id;
   }
   if (p_line==0) {
      down();
      if (p_line==0) {
         call_root_key(ENTER);
      }
      p_col=1;
   }
   _select_char(mark_id);
   _insert_text(text);
   _select_char(mark_id);

   int status=surround_with(prefix,mark_id,prompt);

   if (status && delete_on_error) {
      _delete_selection(mark_id);
   }

   _free_selection(mark_id);

   return status;
}


/////////////////////////////////////////////////////////////////////////////
// Surround after syntax expansion or alias expansion
// 

static int gSurroundBlockMarkerType=-1;   // block marker type for surround
static int gSurroundBlockMarkerId=-1;     // block marker ID for surround
static int gSurroundEndLineMarkerType=-1; // end Line marker type for surround
static int gSurroundEndLineMarkerId=-1;   // end Line marker ID for surround
static int gSurroundMarkerStartLine=0;    // Start line for surround block
static int gSurroundMarkerNumStartLines=0;// Number of lines to protect at start of block
static int gSurroundMarkerEndLine=0;      // End line for surround block
static int gSurroundMarkerNumEndLines=1;  // Number of lines to move at end of block
static int gSurroundEditStartMarker=-1;   // stream marker ID for editable area
static int gSurroundEditEndMarker=-1;     // stream marker ID for editable area
static boolean gSurroundDoIndent=true;       // indent amount to change as lines are surrounded/unsurrounded

// Bitmap for dynamic surround
int _pic_surround = 0;

definit()
{
   gSurroundBlockMarkerType=-1;
   gSurroundBlockMarkerId=-1;
   gSurroundEndLineMarkerType=-1;
   gSurroundEndLineMarkerId=-1;
   gSurroundMarkerStartLine=0;
   gSurroundMarkerNumStartLines=0;
   gSurroundMarkerEndLine=0;
   gSurroundMarkerNumEndLines=1;
   gSurroundEditStartMarker=-1;
   gSurroundEditEndMarker=-1;
   gSurroundDoIndent=true;
}

/**
 * Clear all line markers used by surround mode.
 */
void clear_surround_mode_line()
{
   gSurroundBlockMarkerId=-1;
   gSurroundEndLineMarkerId=-1;
   gSurroundMarkerEndLine=0;
   gSurroundMarkerNumEndLines=1;
   if (gSurroundBlockMarkerType >= 0) {
      _LineMarkerRemoveAllType(gSurroundBlockMarkerType);
   }
   if (gSurroundEndLineMarkerType >= 0) {
      _StreamMarkerRemoveAllType(gSurroundEndLineMarkerType);
   }
}

/**
 * Return the marker type ID for surround mode's line marker.
 */
static int get_surround_mode_block_marker_type()
{
   if (gSurroundBlockMarkerType < 0) {
      gSurroundBlockMarkerType = _MarkerTypeAlloc();
   }
   if (def_surround_mode_options & VS_SURROUND_MODE_DRAW_BOX) {
      _MarkerTypeSetFlags(gSurroundBlockMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE|VSMARKERTYPEFLAG_DRAW_BOX);
   } else {
      _MarkerTypeSetFlags(gSurroundBlockMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE);
   }
   return gSurroundBlockMarkerType;
}

/**
 * Return the marker type ID for surround mode's line marker.
 */
static int get_surround_mode_end_marker_type()
{
   if (gSurroundEndLineMarkerType < 0) {
      gSurroundEndLineMarkerType = _MarkerTypeAlloc();
   }
   _MarkerTypeSetFlags(gSurroundEndLineMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE);
   return gSurroundEndLineMarkerType;
}

/**
 * Set the first line to be included in the surround mode box.
 * Note that this number never changes as long as we are in
 * surround mode.
 * 
 * @param start_line    start line of alias / syntax expansion
 * @param num_lines  (default=0) number of lines for statement start
 */
void set_surround_mode_start_line(int start_line=0, int num_lines=0)
{
   clear_surround_mode_line();
   if (!start_line) {
      start_line = p_line;
   }
   gSurroundMarkerStartLine = start_line;
   gSurroundMarkerNumStartLines = num_lines;
}

/**
 * Set the last line to be included in the surround mode box.
 * Note that this number changes as they cursor up and down.
 * This is the single line that will be moved as they
 * cursor up/down.
 * 
 * @param end_line   end line for alias / syntax expansion
 * @param num_lines  (default=1) number of lines to move
 * @param force      (default=false) force surround mode even if disabled
 */
void set_surround_mode_end_line(int end_line=0, int num_lines=1, boolean force=false)
{
   if (!force && !(_GetSurroundModeFlags() & VS_SURROUND_MODE_ENABLED)) {
      return;
   }

   // make sure we had a start line set
   if (gSurroundMarkerStartLine <= 0) {
      return;
   }

   // clear the previous settings / marker
   clear_surround_mode_line();
   if (!end_line) {
      end_line = p_line;
   }

   // get the start line for the marker
   int start_line = end_line;
   if (gSurroundMarkerStartLine > 0 && end_line >= gSurroundMarkerStartLine) {
      start_line = gSurroundMarkerStartLine;
   }

   int total_lines = end_line - start_line + num_lines;
   int block_id = _LineMarkerAdd(p_window_id, 
                                 start_line, false, total_lines,
                                 0, get_surround_mode_block_marker_type(),
                                 get_message(VSRC_DYNAMIC_SURROUND_MESSAGE)
                                 );

   // get picture indexes for _surround.ico
   if (!_pic_surround) {
      _pic_surround = load_picture(-1,'_surround.ico');
   }

   // add picture to show last line movement
   save_pos(auto p);
   p_line=end_line;
   p_col=1;
   int line_id = 0;
   if ((def_surround_mode_options & VS_SURROUND_MODE_DRAW_ARROW) && num_lines > 0) {
      line_id = _StreamMarkerAdd(p_window_id, _QROffset(), 1, 1, 
                                 _pic_surround, get_surround_mode_end_marker_type(),
                                 get_message(VSRC_DYNAMIC_SURROUND_MESSAGE)
                                );
   }
   restore_pos(p);

   // use the block matching color to display the dynamic
   // surround block
   typeless fg=0,bg=0;
   parse _default_color(CFG_BLOCK_MATCHING) with fg bg . ;
   _LineMarkerSetStyleColor(block_id,fg);

   gSurroundBlockMarkerId = block_id;
   gSurroundEndLineMarkerId = line_id;
   gSurroundMarkerStartLine = start_line;
   gSurroundMarkerEndLine = end_line;
   gSurroundMarkerNumEndLines = num_lines;
}

boolean surround_get_extent(long& start_off, long& end_off) {
   if (gSurroundBlockMarkerId < 0) {
      return false;
   }
   save_pos(auto po);
   p_line = gSurroundMarkerStartLine;
   p_col = 1;
   start_off = _QROffset();

   p_line = gSurroundMarkerEndLine + gSurroundMarkerNumEndLines;
   _end_line();
   end_off = _QROffset();
   restore_pos(po);
   return true;
}

int save_surround_state_to(long (&markers)[]) {
   int surround_index = -1;
   if (gSurroundBlockMarkerId < 0) {
      return surround_index;
   }

   if (def_beautifier_debug > 1) 
      say('Save surround: start_line='gSurroundMarkerStartLine', num_start_lines='gSurroundMarkerNumStartLines', end_line='gSurroundMarkerEndLine', num_end_lines='gSurroundMarkerNumEndLines", marker_idx="markers._length());

   _save_pos2(auto p);
   surround_index = markers._length();
   p_line = gSurroundMarkerStartLine;
   p_col = 1;
   markers[markers._length()] = _QROffset();

   p_line = p_line + gSurroundMarkerNumStartLines;
   p_col = 1;
   markers[markers._length()] = _QROffset();

   p_line = gSurroundMarkerEndLine;
   p_col = 1;
   markers[markers._length()] = _QROffset();

   p_line += gSurroundMarkerNumEndLines;
   p_col = 1;
   markers[markers._length()] = _QROffset();
   _restore_pos2(p);

   clear_surround_mode_line();
   return surround_index;
}

void restore_surround_state_from(int surround_index, long (&markers)[]) {
   if (surround_index < 0 || surround_index >= markers._length()) {
      return;
   }

   _GoToROffset(markers[surround_index]);
   start := p_line;
   
   _GoToROffset(markers[surround_index+1]);
   nsl := p_line - start - 1;
   if (nsl < 0) {
      nsl = 0;
   }
   _GoToROffset(markers[surround_index+2]);
   endl := p_line;

   _GoToROffset(markers[surround_index+3]);
   endl_end := p_line;

   num_end := endl_end - endl;
   if (num_end <= 0) {
      num_end = 1;
   }
   set_surround_mode_start_line(start, nsl);
   set_surround_mode_end_line(endl, num_end);
   if (def_beautifier_debug > 1) 
      say('Restore surround: start_line='gSurroundMarkerStartLine', num_start_lines='gSurroundMarkerNumStartLines', end_line='gSurroundMarkerEndLine', num_end_lines='gSurroundMarkerNumEndLines);
}


/** 
 * Set the last line of the block to be surrounded.
 * This function assumes you have already called
 * {@link set_surround_mode_end_line} to indicate
 * where the end line for the surround block is.
 * <p>
 * The purpose of this function is to simplify
 * situations like alias expansion where you
 * might see the surround marker but there is still
 * an undetermined number of additional lines to float.
 * 
 * @param last_line
 * @param force      (default=false) force surround mode even if disabled
 */
void set_surround_mode_num_lines(int last_line=0, boolean force=false)
{
   if (gSurroundMarkerEndLine <= 0) {
      return;
   }
   if (!last_line) {
      last_line = p_line;
   }
   int num_lines = last_line - gSurroundMarkerEndLine + 1;
   set_surround_mode_end_line(gSurroundMarkerEndLine, num_lines, force);
}

/**
 * Return the line number of the first line currently visible in the
 * editor window in the current scrolling configuration.
 */
static int get_first_visible_line()
{
   save_pos(auto p);
   p_cursor_y=0;
   int line = p_line;
   restore_pos(p);
   return line;
}

/**
 * Function to indent or unindent the current line 
 * when it is was moved into (or out of) a surround block.
 * 
 * @param direction  '+' to indent, '-' to unindent
 */
static void indent_surround(_str direction, _str (&origLines):[])
{
   // save original lines (to restore later)
   if (!origLines._indexin(direction:+p_line)) {
      get_line(auto line);
      origLines:[direction:+p_line] = line;
   }

   // check if we can just restore the previous contents of the line
   end_lines := gSurroundMarkerNumEndLines;
   if (direction=='+' && origLines._indexin("-":+(p_line+end_lines))) {
      replace_line(origLines:["-":+(p_line+end_lines)]);
      return;
   } else if (direction=='-' && origLines._indexin("+":+(p_line-end_lines))) {
      replace_line(origLines:["+":+(p_line-end_lines)]);
      return;
   }

   // check for a language-specific indent callback
   index := _FindLanguageCallbackIndex('_%s_indent_surround');
   if (index) {
      call_index(direction, index);
      return;
   }

   // use the generic indent/unindent code
   if (direction=='+') {
      _indent_line(false);
   } else {
      unindent_line();
   }
}

/**
 * If there are hidden lines, unhide them before surrounding
 * or unsurrounding them
 */
static maybe_unhide_surround_lines()
{
   int orig_line=p_line;
   // expand hidden blocks before unsurrounding
   if (_lineflags() & PLUSBITMAP_LF) {
      plusminus(true);
   }
   if (_lineflags() & HIDDEN_LF) {
      expand_line_level();
   }
   p_line=orig_line;
}

/**
 * Un-surround a group of lines by un-indenting them in by the
 * syntax indent amount and moving the end of the surround
 * block up.
 * 
 * @param lower_limit   lower limit, can't surround above this line
 * @param upper_limit   upper limit, can't surround below this line
 * @param num_lines     number of lines to cough up
 * @param p             cursor position to restore to when done
 */
static void unsurround_lines(int lower_limit, int upper_limit,
                             int num_lines, typeless p,
                             _str (&origLines):[])
{
   int i;
   for (i=0; i<num_lines; ++i) {
      int end_lines = gSurroundMarkerNumEndLines;
      if (gSurroundMarkerEndLine==lower_limit) {
         message(get_message(VSRC_DYNAMIC_SURROUND_NO_MORE_UP));
         _beep();
         return;
      }
      _str line="";
      p_line = gSurroundMarkerEndLine;
      up();
      maybe_unhide_surround_lines();
      int line_flags = _lineflags();

      // save bookmark, breakpoint, and annotation information
      _SaveBookmarksInFile(auto bmSaves,p_RLine,p_RLine,false);
      _SaveBreakpointsInFile(auto bpSaves,p_RLine,p_RLine,false);
      _SaveAnnotationsInFile(auto annoSaves,p_RLine,p_RLine,false);

      boolean doIndent = (line_flags & NOSAVE_LF)==0 && gSurroundDoIndent;
      get_line(line);
      if (end_lines > 0) {
         _delete_line();
         down(end_lines-1);
         insert_line(line);
      }
      _lineflags(line_flags);
      if (doIndent) {
         indent_surround('-', origLines);
      }
      if (end_lines > 0) {
         up(end_lines);
      }
      set_surround_mode_end_line(p_line, end_lines, true);
      int last_line = get_first_visible_line();
      restore_pos(p);
      _scroll_page('l', last_line);

      // restore bookmarks, breakpoints, and annotation locations
      _RestoreBookmarksInFile(bmSaves, end_lines);
      _RestoreBreakpointsInFile(bpSaves, end_lines);
      _RestoreAnnotationsInFile(annoSaves, end_lines);
   }
   message(get_message(VSRC_DYNAMIC_SURROUND_MESSAGE));
}

/**
 * Surround a group of lines by indenting them in by the
 * syntax indent amount and moving the end of the surround
 * block down.
 * 
 * @param lower_limit   lower limit, can't surround above this line
 * @param upper_limit   upper limit, can't surround below this line
 * @param num_lines     number of lines to swallow
 * @param p             cursor position to restore to when done
 */
static void surround_lines(int lower_limit, int upper_limit,
                           int num_lines, typeless p,
                           _str (&origLines):[])
{
   int i;
   for (i=0; i<num_lines; ++i) {
      int end_lines = gSurroundMarkerNumEndLines;
      if (upper_limit > lower_limit && gSurroundMarkerEndLine+end_lines >= upper_limit) {
         message(get_message(VSRC_DYNAMIC_SURROUND_NO_MORE_DOWN));
         _beep();
         return;
      }
      _str line="";
      p_line = gSurroundMarkerEndLine;
      down(end_lines);
      maybe_unhide_surround_lines();
      int line_flags = _lineflags();

      // save bookmark, breakpoint, and annotation information
      _SaveBookmarksInFile(auto bmSaves,p_RLine,p_RLine,false);
      _SaveBreakpointsInFile(auto bpSaves,p_RLine,p_RLine,false);
      _SaveAnnotationsInFile(auto annoSaves,p_RLine,p_RLine,false);

      boolean doIndent = (line_flags & NOSAVE_LF)==0 && gSurroundDoIndent;
      get_line(line);
      int extra_line = (p_line == p_Noflines)? 0:1;
      _delete_line();
      up(end_lines+extra_line);
      insert_line(line);
      _lineflags(line_flags);
      if (doIndent) {
         indent_surround('+', origLines);
      }
      down();
      set_surround_mode_end_line(p_line, end_lines, true);
      int last_line = get_first_visible_line();
      restore_pos(p);
      _scroll_page('l', last_line);

      // restore bookmarks, breakpoints, and annotation locations
      _RestoreBookmarksInFile(bmSaves, -end_lines);
      _RestoreBreakpointsInFile(bpSaves, -end_lines);
      _RestoreAnnotationsInFile(annoSaves, -end_lines);
   }
   message(get_message(VSRC_DYNAMIC_SURROUND_MESSAGE));
}

/**
 * Compute the number of lines to grab for the next block
 * of surround.  This will use statement tagging if available
 * or an extension specific "_[ext]_next_statement" callback.
 * It will also call "_[ext]_is_continued_statement" in order
 * to handle chained else-if and try-catch statements.
 * 
 * @param direction  '+1' for forward (surround),
 *                   '-1' for reverse (unsurround)
 * @param startLine  (optional) line to start searching from
 * 
 * @return number of lines to surround/unsurround
 */
static int get_num_surround_lines(int direction, int startLine=0)
{
   if (!(def_surround_mode_options & VS_SURROUND_MODE_JUMP_FAST) && !startLine) {
      return 1;
   }

   int status=0;
   save_pos(auto p);
   if ( !startLine ) {
      startLine = gSurroundMarkerEndLine + direction*gSurroundMarkerNumEndLines;
   }
   p_line = startLine;
   
   first_non_blank();

   // skip blank lines one at a time
   _str line="";
   get_line(line);
   if (line == "") {
      return 1;
   }

   // work through JavaDoc or XMLDoc comments one line at a time
   if (_inJavadoc()) {
      return 1;
   }

   if (_clex_find(0, 'g')==CFG_COMMENT) {

      // skip over groups of comments
      if (direction > 0) {
         while (_clex_find(0, 'g')==CFG_COMMENT) {
            origPos := _QROffset();
            _clex_find(COMMENT_CLEXFLAG, 'n');
            if (p_col > 1) break;
            first_non_blank();
            if (_QROffset() == origPos) {
               restore_pos(p);
               return 0;
            }
         }
         _clex_find(COMMENT_CLEXFLAG, '-o');
         down();
      } else {
         while (_clex_find(0, 'g')==CFG_COMMENT) {
            origPos := _QROffset();
            _clex_find(COMMENT_CLEXFLAG, '-n');
            if (search("\\c(^|[^ \t])", "-@r") < 0) break;
            if (p_col > 1) break;
            up();_end_line();
            if (_QROffset() == origPos) {
               restore_pos(p);
               return 0;
            }
         }
         _clex_find(COMMENT_CLEXFLAG, 'o');
         up();
      }

   } else {

      // look for extension specific next/prev statement callbacks
      status = STRING_NOT_FOUND_RC;
      int index = 0;
      if (direction > 0) {
         index = _FindLanguageCallbackIndex("_%s_next_statement");
      } else {
         index = _FindLanguageCallbackIndex("_%s_prev_statement");
      }
      if (index) {
         status = call_index(index);
      }

      // check if we are in a function and that we
      // have statement tagging available
      _UpdateContext(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      if (line!="" && !index && 
          tag_current_context() > 0 &&
         _are_statements_supported()) {

         // first, align to the begin/end of the current statement
         boolean realignStatement=false;
         if (direction > 0) {
            status = end_statement(1);
            // make sure that the end seek position is tight
            save_pos(auto pend);
            _GoToROffset(_QROffset()-1);
            if (!search('[^ \t\n\r]', '-@rh') && p_RLine >= startLine) {
               _GoToROffset(_QROffset()+1);
            } else {
               restore_pos(pend);
            }
            
         } else {
            status = begin_statement(1);
         }

         // check if there is a "continued statement" callback
         // for this extension (to handle "else" and "catch")
         cont_index := _FindLanguageCallbackIndex("_%s_is_continued_statement");
         if (status==0 && cont_index) {
            for (;;) {
               // check if the current statement is a continuation
               if (!call_index(cont_index)) {
                  if (realignStatement && direction > 0) {
                     realignStatement=false;
                     up(); _end_line();
                     _clex_skip_blanks('-');
                  }
                  break;
               }
               // yes, it was continued, so we will need
               // to realign again when we are done
               realignStatement=true;
               // skip to the next sibling statement
               int orig_line=p_line;
               if (direction > 0) {
                  _clex_skip_blanks('');
                  status = next_sibling(1);
               } else {
                  status = prev_sibling(1);
               }
               // no next sibling?
               if (status || p_line==orig_line) {
                  break;
               }
            }
         }

         // now align to the begin-end of the last sibling that
         // was continued (if there was a continuation)
         if (realignStatement) {
            if (direction > 0) {
               status = end_statement(1);
            } else {
               status = begin_statement(1);
            }
         }

         // now move up/down a line
         if (direction > 0) {
            down();
         } else {
            up();
         }
         _begin_line();
      }
   }

   // now compute the number of lines that we jumped over
   int num_lines = 1;
   if (status == 0) {
      if (direction > 0) {
         num_lines = p_line - startLine;
      } else {
         num_lines = gSurroundMarkerEndLine - p_line - gSurroundMarkerNumEndLines;
      }
      if (num_lines <= 0) {
         num_lines = 1;
      }
   }

   // restore cursor position and return the number of lines
   restore_pos(p);
   return num_lines;
}

/**
 * Most syntax expansion modes support inserting a blank line
 * automatically.  If using dynamic surround, we want to remove
 * this blank line before surrounding any code.
 * 
 * @param first_time  
 * @param start_line
 * @param end_line
 */
static void maybe_delete_blank_line(boolean &first_time, int &start_line, int &end_line)
{
   if (!first_time) return;
   first_time=false;
   if (gSurroundMarkerEndLine <= 1) return;
   save_pos(auto p);
   p_line = gSurroundMarkerEndLine-1;
   get_line(auto line);
   if (line=="") {
      _delete_line();
      gSurroundMarkerEndLine--;
      start_line--;
      end_line--;
   }
   restore_pos(p);
}

/**
 * Save information needed for tracking dynamic surround
 * mode editing.
 */
static void StartDynamicSurroundEditing(boolean doNag = true, NotificationFeature callingFeature = -1)
{
   save_pos(auto p);
   search('[~ \t\r\n]','@-rh');
   left();
   gSurroundEditStartMarker = _StreamMarkerAdd(p_window_id,_QROffset(),1,1,0,get_surround_mode_end_marker_type(),null);
   restore_pos(p);
   search('[~ \t\r\n]','@rh');
   right();
   gSurroundEditEndMarker = _StreamMarkerAdd(p_window_id,_QROffset(),1,1,0,get_surround_mode_end_marker_type(),null);
   restore_pos(p);

   // notify the user what's going on
   if (doNag) {
      if (callingFeature > 0) {
         notifyUserOfFeatureUse(callingFeature, p_buf_name, p_line, NF_DYNAMIC_SURROUND);
      } else {
         notifyUserOfFeatureUse(NF_DYNAMIC_SURROUND, p_buf_name, p_line);
      }
   }
}
/**
 * Clean up information used for tracking dynamic surround
 * mode editing.
 */
static void TerminateDynamicSurroundEditing()
{
   if ( gSurroundEditStartMarker >= 0 ) {
      _StreamMarkerRemove(gSurroundEditStartMarker);
      gSurroundEditStartMarker=-1;
   }
   if ( gSurroundEditEndMarker >= 0) {
      _StreamMarkerRemove(gSurroundEditEndMarker);
      gSurroundEditEndMarker=-1;
   }
}
/**
 * Check if cursor is still in the range we need
 * it to be in.
 */
static boolean CheckDynamicSurroundEditPos()
{
   // get start of editable area
   if ( gSurroundEditStartMarker < 0 ||
        _StreamMarkerGet(gSurroundEditStartMarker,auto info)) {
      return false;
   }
   // is cursor to left of editable area
   if ( _QROffset() < info.StartOffset ) {
      return false;
   }
   // get end of editable area
   if ( gSurroundEditEndMarker < 0 ||
        _StreamMarkerGet(gSurroundEditEndMarker,info)) {
      return false;
   }
   // is cursor to right of editable area?
   if ( _QROffset() > info.StartOffset ) {
      return false;
   }
   // we are still in business
   return true;
}

/**
 * Process keys handled by surround mode.  Immediately exit from
 * surround mode if any unrecognized key or mouse event happens.
 * <p>
 * While in surround mode, cursor-down will move the line after the last
 * line of the block down one line and indent it within the block.
 * Likewise, cursor-up will move the last line in the block outside and
 * unindent it to it's original state.
 * 
 * @param force      (default=false) force surround mode even if disabled
 * 
 * @categories Editor_Control_Methods
 */
boolean do_surround_mode_keys(boolean force=false, NotificationFeature callingFeature = -1)
{
   // get out if dynamic surround is disabled, unless manually invoked
   if (!force && !(_GetSurroundModeFlags() & VS_SURROUND_MODE_ENABLED)) {
      clear_surround_mode_line();
      return false;
   }

   // do not allow dynamic surround during macro recording or playback
   if (_macro('S') || _macro('R')) {
      clear_surround_mode_line();
      return false;
   }

   // Check to be sure we are not in diff mode.  Disable dynamic surround in diff
   if (_isdiffed(p_buf_id)) {
      clear_surround_mode_line();
      return false;
   }

   // no dynamic surround start/end information set up, then we are done
   if (gSurroundBlockMarkerId < 0) {
      clear_surround_mode_line();
      return false;
   }

// say("do_surround_mode_keys: gSurroundMarkerEndLine="gSurroundMarkerEndLine" p_line="p_line);
   if (p_line >= gSurroundMarkerEndLine) {
      clear_surround_mode_line();
      return false;
   }

   int last_line = 0;
   int start_line = 0;
   if ( gSurroundMarkerNumStartLines > 0 ) {
      start_line = gSurroundMarkerStartLine+gSurroundMarkerNumStartLines;
   } else {
      start_line = gSurroundMarkerEndLine;
   }
   _str line="";
   typeless event='';
   save_pos(auto p);

   int end_line = 0;
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto ctx_type_name);
      if (ctx_type_name == 'block') { // ignore statement blocks
         context_id = 0;
      } else {
         tag_get_detail2(VS_TAGDETAIL_context_end_linenum, context_id, end_line);
      }
   }
   // go to the end of the statement but make sure we did not go
   // past the end of the current function.
   p_line = gSurroundMarkerEndLine+gSurroundMarkerNumEndLines-1;
   _end_line();
   p_col++;
   if (context_id > 0 && _are_statements_supported() && !end_statement(1)) {
      _UpdateContext(true);
      if (tag_current_context()==context_id) {
         end_line = p_line;

         // Two common types of end statement - some sort of close brace, which
         // we don't want to pull in with surround, and an ending keyword like
         // 'break', which we can pull into the surround.  This language
         // hook allows us to differentiate.  Hook can assume the cursor is 
         // at the end of the statement in question.
         inclusive := find_index('_'p_LangId'_surroundable_statement_end', PROC_TYPE);
         if (inclusive > 0) {
            if (call_index(inclusive)) {
               end_line += 1;
            }
         }
      }
   }
   if (!end_line) {
      end_line = p_Noflines+1;
   }
   restore_pos(p);

// say("do_surround_mode_keys: gSurroundMarkerEndLine="gSurroundMarkerEndLine);
// say("do_surround_mode_keys: gSurroundMarkerNumEndLines="gSurroundMarkerNumEndLines);
// say("do_surround_mode_keys: end_line="end_line);
   if (gSurroundMarkerEndLine+gSurroundMarkerNumEndLines >= end_line && !XW_isSupportedLanguage2(p_LangId)) {
      clear_surround_mode_line();
      return false;
   }

   // save the original message line, and tell them what to do
   _str orig_message=get_message();
   message(get_message(VSRC_DYNAMIC_SURROUND_MESSAGE));

   // start dynamic surround mode
   _str origLines:[];
   StartDynamicSurroundEditing(!force, callingFeature);

   // event loop for handling dynamic surround mode
   int count=0;
   boolean first_time=true;
event_loop:
   for (;;) {

      // get the next event from the keyboard
      event=get_event();
      //say("do_surround_mode_keys: HERE, event="event2name(event));

      // if they hit escape to cancel list-members or parameter help, let it through 
      if ( ParameterHelpActive() && event:==ESC ) {
         call_key(event);
         continue;
      }

      // any other escape is grounds for termination
      if ( !AutoCompleteActive() ) {
         if (event:==ESC || name_on_key(event):=="cmdline-toggle") {
            event='';
            break;
         }
      }

      // any mouse event is also grounds for termination
      if (vsIsMouseEvent(event2index(event))) {
         event='';
         break;
      }

      if ( !AutoCompleteActive() ) {

         // any sort of ENTER is grounds for termination
         if (event:==ENTER || 
             event:==name2event("c-s-enter") || 
             event:==name2event("a-enter") || 
             event:==name2event("c-enter") || 
             event:==name2event("s-enter")) {
            break;
         }

         // handle special keys for dynamic surround
         int num_lines=1;
         switch (name_on_key(event)) {
         case 'cursor-up':
            if (first_time && gSurroundMarkerNumStartLines==0) break event_loop;
            num_lines = get_num_surround_lines(-1);
            unsurround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'cursor-down':
            maybe_delete_blank_line(first_time, start_line, end_line);
            num_lines = get_num_surround_lines(1);
            surround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'page-up':
            if (first_time) break event_loop;
            p_line = gSurroundMarkerEndLine;
            page_up();
            num_lines = gSurroundMarkerEndLine - p_line - gSurroundMarkerNumEndLines;
            restore_pos(p);
            unsurround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'page-down':
            maybe_delete_blank_line(first_time, start_line, end_line);
            p_line = gSurroundMarkerEndLine;
            page_down();
            num_lines = p_line - gSurroundMarkerEndLine - gSurroundMarkerNumEndLines;
            restore_pos(p);
            surround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'top-of-buffer':
            if (first_time) break event_loop;
            num_lines = gSurroundMarkerEndLine - gSurroundMarkerNumEndLines;
            unsurround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'bottom-of-buffer':
            maybe_delete_blank_line(first_time, start_line, end_line);
            num_lines = p_Noflines - gSurroundMarkerEndLine - gSurroundMarkerNumEndLines;
            surround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'top-of-window':
            if (first_time) break event_loop;
            p_line = gSurroundMarkerEndLine;
            top_of_window();
            num_lines = gSurroundMarkerEndLine - p_line - gSurroundMarkerNumEndLines;
            restore_pos(p);
            unsurround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         case 'bottom-of-window':
            p_line = gSurroundMarkerEndLine;
            bottom_of_window();
            num_lines = p_line - gSurroundMarkerEndLine - gSurroundMarkerNumEndLines;
            restore_pos(p);
            surround_lines(start_line, end_line, num_lines, p, origLines);
            continue;
         default:
            break;
         }
      }

      // let the event through and make it an undo step
      wasInAutoComplete := AutoCompleteActive();
      call_key(event);
      _undo('S');

      // Auto-Complete completed something, reset 
      if (wasInAutoComplete && !AutoCompleteActive() && !CheckDynamicSurroundEditPos()) {
         TerminateDynamicSurroundEditing();
         StartDynamicSurroundEditing();
      }

      // make sure cursor didn't move outside of safe area
      if ( !CheckDynamicSurroundEditPos() ) {
         event='';
         break;
      }

      // update code help dialogs
      if ( ParameterHelpActive() ) {
         orig_idle := def_codehelp_idle;
         orig_key  := def_codehelp_key_idle;
         def_codehelp_idle=0;
         def_codehelp_key_idle=0;
         _CodeHelp();
         def_codehelp_idle = orig_idle;
         def_codehelp_key_idle = orig_key;
      }

      // update auto-complete dialogs
      if ( AutoCompleteActive() ) {
         orig_idle := def_auto_complete_update_idle_time;
         def_auto_complete_update_idle_time = 0;
         AutoCompleteUpdateInfo();
         def_auto_complete_update_idle_time = orig_idle;
      }

      // save the cursor position
      save_pos(p);
   }

   // shut down dynamic surround mode
   TerminateDynamicSurroundEditing();
   clear_surround_mode_line();
   //restore_pos(p);

   // restore message line
   if (orig_message) {
      message(orig_message);
   } else {
      clear_message();
   }

   // send along the last event
   if (event:!='') {
      call_key(event);
   }

   return true;
}

///////////////////////////////////////////////////////////////////////////////

/**
 * Get the extension specific surround options.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>def_surround_mode_options</code> as the default.
 * 
 * @param lang    language ID (p_LangId)
 * 
 * @return bitset of VS_SURROUND_MODE_* options.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @deprecated Use {@link _GetSurroundModeFlags()}
 */
int _ext_surround_flags(_str lang='')
{
   return _GetSurroundModeFlags(lang);
}
/**
 * Get the language-specific surround options.
 * <p>
 * The options are stored per language.  If the options
 * are not yet defined for a language, then use
 * <code>def_surround_mode_options</code> as the default.
 * 
 * @param lang    language ID (p_LangId)
 * 
 * @return bitset of VS_SURROUND_MODE_* options.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Tagging_Functions
 */
int _GetSurroundModeFlags(_str lang='')
{
   if (lang=='' && _isEditorCtl()) {
      lang = p_LangId;
   }
   return LanguageSettings.getSurroundOptions(lang);
}

/**
 * Are we trying to set up dynamic surround mode?
 */
boolean in_dynamic_surround_mode()
{
   return (gSurroundMarkerStartLine > 0);
}

///////////////////////////////////////////////////////////////////////////////

/**
 * When on, if you delete the first line of a simple block statement,
 * you will be prompted if you want to delete the entire block,
 * or just delete the outer statement (un-surround).
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_auto_unsurround_block=true;
/**
 * Prompt user for confirmation before deleting code blocks using
 * {@link cut_code_block} or {@link delete_code_block}.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_prompt_for_delete_code_block=true;
/**
 * Prompt user for confirmation before unsurrounding
 * code blocks using {@link unsurround}.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_prompt_for_unsurround_block=true;
/**
 * Amount of time in milliseconds to delay in order to 
 * animate unsurround and delete code block when the 
 * the confirmation prompts are turned off.
 * 
 * @default 500 milliseconds
 * @categories Configuration_Variables
 */
int def_code_block_view_delay=500;

/**
 * Locate the enclosing block statement for the line the cursor is
 * currently located on and attempt to un-surround that statement.
 * 
 * @categories Editor_Control_Methods
 */
_command void unsurround() name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK)
{
   // save the auto-unsurround options
   orig_auto_unsurround := def_auto_unsurround_block;
   def_auto_unsurround_block=true;

   // keep track of the original cursor position
   orig_line := p_RLine;
   save_pos(auto p);

   // find the top of the current procedure for a stopping point
   status := prev_proc();
   first_line := p_RLine;

   // no current proc, then just go up at most 100 lines
   if (status && first_line==orig_line) {
      first_line=(orig_line>100)? orig_line-100 : 0;
   }

   // go back to where we started
   restore_pos(p);

   // move up line by line until we find a surround block
   // matching the line the cursor was originally on
   while (p_RLine > first_line) {

      // if we unsurround'ed something, there will be fewer lines
      int orig_Noflines=p_Noflines;
      if (maybe_unsurround_block(false,'',orig_line,false,true)) {

         // restore original option value
         def_auto_unsurround_block=orig_auto_unsurround;

         // restore cursor if they cancelled
         if (orig_Noflines==p_Noflines) {
            restore_pos(p);
         }

         // that's all
         return;
      }

      // next please
      up();
   }

   // did not find a surrounding statement, so give up
   restore_pos(p);
   message("No block statement to unsurround");
   def_auto_unsurround_block=orig_auto_unsurround;
}
int _OnUpdate_unsurround(CMDUI &cmdui,int target_wid,_str command)
{
   // must be an editor control
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return MF_GRAYED;
   }

   // and it must support unsurround
   index := target_wid._FindLanguageCallbackIndex("_%s_find_surround_lines",target_wid._GetEmbeddedLangId());
   return (index > 0)? MF_ENABLED : MF_GRAYED;
}

/**
 * Check if the current line starts a multi-line comment
 * 
 * @param first_line       set to first line of comment
 * @param last_line        set to last line of comment
 * @param num_first_lines  number of start lines (for unsurround)
 * @param num_last_lines   number of end lines (for unsurround)
 * @param force            force a match even if not on first line
 * 
 * @return true if it it a multi-line comment
 */
static boolean check_for_block_comment(int &first_line, int &last_line, 
                                       int &num_first_lines, int &num_last_lines,
                                       boolean force=false)
{
   save_pos(auto p);
   first_non_blank();
   orig_line := p_line;

   do {
      // we must be in a comment
      if ( _clex_find(0,'g') != CFG_COMMENT ) break;

      // check if we can get outside of the comment going backwards
      status := _clex_skip_blanks('-h');
      if (status) top();
      status = _clex_find(COMMENT_CLEXFLAG,'o');
      if (status) break;

      // verify that we are still on the first line
      if ( !force && p_line < orig_line ) break;

      // ok, we have the first line
      first_line = p_line;

      // check if the first line has anything interesting on it
      _str line="";
      get_line(line);
      num_first_lines = (pos('['p_word_chars']',line,1,'r')==0)? 1:0;

      // now find the end of the comment
      restore_pos(p);
      status = _clex_skip_blanks('h');
      if (status) bottom();
      status = _clex_find(COMMENT_CLEXFLAG,'-o');
      if (status) break;

      // verify that the last line of comment > the first line?
      if ( p_line <= first_line ) break;

      // ok, we have the last line
      last_line = p_line;

      // check if the last line has anything interesting on it
      get_line(line);
      num_last_lines = (pos('['p_word_chars']',line,1,'r')==0)? 1:0;

      // we got ourselves a multi-line comment
      restore_pos(p);
      return true;

   } while (false);

   restore_pos(p);
   return false;
}

/**
 * Check if the current line starts a multi-line symbol
 * 
 * @param first_line       set to first line of symbol
 * @param last_line        set to last line of symbol
 * @param num_first_lines  number of start lines (for unsurround)
 * @param num_last_lines   number of end lines (for unsurround)
 * @param force            force a match even if not on first line
 * 
 * @return true if it it a multi-line comment
 */
static boolean check_for_multiline_symbol(int &first_line, 
                                          int &last_line, 
                                          int &num_first_lines, 
                                          int &num_last_lines,
                                          boolean force=false)
{
   // check for tagging support
   if ( !_istagging_supported() ) {
      return false;
   }

   // Update the symbols in the current context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get the current item under the cursor
   context_id := tag_current_context();
   if ( context_id <= 0 ) {
      return false;
   }
   /*
     This is a bit ugly but it was the simplest changed and is
     gaurenteed to work. If we wants something language independent,
     we could add a callback here to screen out some tags,
     or add a tag flag or do some sort of special check with
     seek positions.
   */
   if (_LanguageInheritsFrom('py') && context_id==1) {
      return(false);
   }
   // This is a cheat

   // get the first line of the symbol
   int start_linenum=0;
   int scope_linenum=0;
   int end_linenum=0;
   int start_seekpos=0;
   int scope_seekpos=0;
   int end_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_linenum, context_id, scope_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_linenum, context_id, end_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);

   // check if this is a multi-line symbol
   if ( end_linenum <= start_linenum ) {
      return false;
   }

   // check if this line is the first line of the symbol
   if ( !force && p_RLine != start_linenum ) {
      return false;
   }

   // we have a multi-line symbol
   num_first_lines = 0;
   num_last_lines  = 0;
   first_line = start_linenum;
   last_line  = end_linenum;
   return true;
}

/**
 * Check if the current line starts a multi-line statement,
 * as located by statement tagging.
 * 
 * @param first_line       set to first line of symbol
 * @param last_line        set to last line of symbol
 * @param num_first_lines  number of start lines (for unsurround)
 * @param num_last_lines   number of end lines (for unsurround)
 * @param force            force a match even if not on first line
 * 
 * @return true if it it a multi-line comment
 */
static boolean check_for_multiline_statement(int &first_line, 
                                             int &last_line, 
                                             int &num_first_lines, 
                                             int &num_last_lines,
                                             boolean force=false)
{
   // check for tagging support
   if ( !_are_statements_supported() ) {
      return false;
   }

   // Update the statements in the current scope
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get the current item under the cursor
   context_id := tag_current_statement();
   if ( context_id <= 0 ) {
      return false;
   }
   /*
     This is a bit ugly but it was the simplest changed and is
     gaurenteed to work. If we wants something language independent,
     we could add a callback here to screen out some tags,
     or add a tag flag or do some sort of special check with
     seek positions.
   */
   if (_LanguageInheritsFrom('py') && context_id==1) {
      return(false);
   }

   // get the first line of the symbol
   int start_linenum=0;
   int scope_linenum=0;
   int end_linenum=0;
   int start_seekpos=0;
   int scope_seekpos=0;
   int end_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
   //tag_get_detail2(VS_TAGDETAIL_context_scope_linenum, context_id, scope_linenum);
   //tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_linenum, context_id, end_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);

   // move cursor to first line of statement
   save_pos(auto p);

   int orig_end_linenum=end_linenum;
   p_RLine = start_linenum;
   first_line = p_line;

   // check if there is a "continued statement" callback
   // in order to see if this statement is continued
   continuedStatement := false;
   cont_index := _FindLanguageCallbackIndex("_%s_is_continued_statement");
   if ( cont_index ) {
      continuedStatement = call_index(cont_index);
   }
   if ( continuedStatement ) {
      // kind of a hack, just guess that there is one end line
      // to protect at the end of the continued statement
      if ( !_LanguageInheritsFrom('py') ) {
         --end_linenum;
      }
   } else {
      // check for a statement continuation
      int num_lines = get_num_surround_lines(1,p_line);
      if ( num_lines>1 && start_linenum+num_lines-1 > end_linenum ) {
         end_linenum = start_linenum+num_lines-1;
      }
   }
   /*
      Handle following case:

         if () {
            int x
      
         }
      Note that this code only works if the end_seekpos is at or before
      the end brace

   */
   //say('end='end_linenum' orig_end_linenum='orig_end_linenum);
   if (end_linenum==orig_end_linenum) {
      //say('new code end_seekpos='end_seekpos);
      _GoToROffset(end_seekpos);
      if (p_col==1) {
         up();_end_line();
      } else {
         --p_col;
      }
      _clex_skip_blanks('h-');
      if (p_RLine!=end_linenum) {
         if (p_RLine<start_linenum) {
            end_linenum=start_linenum;
         } else {
            end_linenum=p_RLine;
            end_seekpos=(int)_QROffset()+1;
         }
      }
      restore_pos(p);
   }

   // ok, first line check is done, restore cursor position now
   restore_pos(p);

   // check if this is a multi-line symbol
   if ( !force && end_linenum <= start_linenum ) {
      return false;
   }

   // check if this line is the first line of the symbol
   if ( !force && p_RLine != start_linenum ) {
      return false;
   }

   // we have a multi-line symbol
   num_first_lines = 0;
   num_last_lines  = 0;
   first_line = start_linenum;
   last_line  = end_linenum;
   return true;
}

/**
 * Find the first line, last line, and number of start and end lines for
 * the code block starting on the current line under the cursor.
 * 
 * @param first_line       set to first line of comment
 * @param last_line        set to last line of comment
 * @param num_first_lines  number of start lines (for unsurround)
 * @param num_last_lines   number of end lines (for unsurround)
 * @param isComment        is this a block comment?
 * @param allowUnsurround  should we allow unsurround to happen here?
 * @param force            force a match even if not on first line
 * 
 * @return true on success, false if no block found
 */
boolean get_code_block_lines( int &first_line, int &num_first_lines, 
                              int &last_line,  int &num_last_lines,
                              boolean &indent_change,
                              boolean &isComment=false, 
                              boolean &allowUnsurround=false,
                              boolean force=false,
                              boolean ignoreContinuedStatements=false) 
{
   // initialize first line, last line, etc.
   save_pos(auto p);
   found_block := false;
   first_line = 0;
   last_line  = 0;
   num_first_lines = 0;
   num_last_lines  = 0;
   indent_change = true;
   allowUnsurround = true;

   // Check if we have the language specific callback
   lang := _GetEmbeddedLangId();
   if (lang == 'fundamental') {
      return false;
   }
   index := _FindLanguageCallbackIndex("_%s_find_surround_lines",lang);
   if (index > 0) {
      // now call the callback and immediately restore the cursor position
      found_block = call_index(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements, index);
      restore_pos(p);
   }

   // Check if we are on a multi-line comment
   if ( !found_block ) {
      found_block = check_for_block_comment(first_line, last_line, num_first_lines, num_last_lines, force);
      isComment = found_block;
   }

   // Check for statement (as found by statement tagging)
   if ( !found_block ) {
      found_block = check_for_multiline_statement(first_line, last_line, num_first_lines, num_last_lines, force);
      allowUnsurround = false;
   }

   // Check current context for multi-line symbol
   if ( !found_block ) {
      found_block = check_for_multiline_symbol(first_line, last_line, num_first_lines, num_last_lines, force);
      allowUnsurround = false;
   }

   // didn't find it, then get out of here
   if (!found_block) {
      return false;
   }

   // no code in the block to unsurround, then get out of here
   if (first_line+1/*num_first_lines*/ > last_line-num_last_lines+1) {
      return false;
   }

   // success!
   return true;
}

/**
 * Workhorse function for un-surround.  This calls the language-specific
 * callback and verifies that we are on the start of a statement, then it
 * either deletes the entire block or unsurrounds, depending on what the
 * user specified.
 * 
 * @param createClipboard    Put deleted lines onto clipboard?
 * @param cbname             clipboard name to use (from cut-line)
 * @param unsurround_line    line that must be part of unsurround block
 * 
 * @return 'true' if it did something, 'false' if this was not
 *         a block statement, or if they selected "delete line".
 */
boolean maybe_unsurround_block(boolean createClipboard=false,
                               _str cbname='', 
                               int unsurround_line=0,
                               boolean force=false,
                               boolean hideDeleteLine=false)
{
   // Is this option even enabled?
   if (!def_auto_unsurround_block && !force) {
      return false;
   }

   // if they passed in a clipboard name, then this
   // was definately not a simple cut-line or delete-line
   if (cbname != '') {
      return false;
   }

   // Avoid being called recursively
   static boolean in_unsurround;
   if (in_unsurround) {
      return false;
   }

   // save original line, column, cursor position
   save_pos(auto p);
   orig_point := point();
   orig_col   := p_col;

   // get the number of lines in the current code block
   found_block := get_code_block_lines(auto first_line, auto num_first_lines, 
                                       auto last_line, auto num_last_lines, auto indent_change, 
                                       auto isComment, auto allowUnsurround, force);
   if (!found_block) {
      return false;
   }

   // no code in the block to unsurround, then get out of here
   if (first_line+num_first_lines > last_line-num_last_lines+1) {
      return false;
   }

   // check if there are no lines to unsurround
   if (first_line+num_first_lines == last_line-num_last_lines+1) {
      allowUnsurround = false;
   }

   // unsurround line not within the block
   if (unsurround_line > 0 && (unsurround_line < first_line || unsurround_line > last_line)) {
      return false;
   }

   // no leading or trailing lines, then do not allow unsurround
   if ( num_first_lines <= 0 && num_last_lines <= 0 ) {
      allowUnsurround = false;
   }

   // create a selection in order to show what block is being modified
   typeless orig_mark, orig_style;
   save_select_style(orig_style);
   save_selection(orig_mark);
   _deselect();
   p_RLine=last_line;
   select_line();
   p_RLine=first_line;
   /* So that pressing undo after cut code block works and
      so that the correct selection is displayed when
      "Extend selection as cursor moves" is unchecked.
      Note that the built-in _select_line is used below selections
      which the user never sees.  To bad there isn't a way to temporarily suspend
      starting a new undo step for this buffer until the dialog is gone.
   */
   if (!pos('C',def_select_style)) {
      select_line();
   }
   // force a redraw so that we can see the selection
   refresh('aw');
   answer := 'U';
   _use_timers=0;
   if (unsurround_line > 0) {
      // coming from the "unsurround" command, so just prompt to confirm
      if (def_prompt_for_unsurround_block) {
         if (_message_box("Un-surround the selected block?","SlickEdit",MB_OKCANCEL)!=IDOK) {
            answer=ESC;
         }
      } else {
         delay(def_code_block_view_delay/10);
      }
   } else if ( force && first_line == last_line ) {
      answer = 'D';
   } else if ( !allowUnsurround && first_line == last_line ) {
      answer = 'D';
   } else {
      // use the auto-unsurround form
      if (!hideDeleteLine || def_prompt_for_delete_code_block) {
         int orig_color_flags = p_color_flags;
         p_color_flags |= CLINE_COLOR_FLAG;
         answer = show("-modal _auto_unsurround_form", 
                       createClipboard, allowUnsurround, 
                       hideDeleteLine, force);
         p_color_flags=orig_color_flags;
      } else {
         delay(def_code_block_view_delay/10);
         answer = 'B'; 
      }
   }

   // get rid of the view selection and restore their old selection
   _use_timers=1;
   _deselect();
   restore_select_style(orig_style);
   restore_selection(orig_mark);
   restore_pos(p);

   // gonna need these later
   i := 0;
   line := "";
   in_unsurround=true;

   // what did they select? 
   switch (answer) {
   case 'D':
      // delete the current line, drop through
      // NOTE: never get here for unsurround() command case
      in_unsurround=false;
      if ( force ) _delete_line();
      return false;

   case 'B':
      // delete block, first make a selection of the whole block
      _deselect();
      p_RLine=last_line;
      _select_line();
      p_RLine=first_line;
      _select_line();

      // now either cut it or outright delete it
      if (createClipboard) {
         cut2();
      } else {
         _delete_selection();
      }
      break;

   case 'U':
      // unsurround block, first unindent the "surrounded" lines
      for (i = first_line+num_first_lines; i<=last_line-num_last_lines; ++i) {
         p_RLine = i;
         first_non_blank();
         //Change to unindent all lines, including comments (10/19/2007)
         //if _clex_find(0, 'g') != CFG_COMMENT) {
         if (indent_change) {
            unindent_line();
         }
         //}
      }

      // delete the leading part of the block statement
      if (num_first_lines > 0) {
         _deselect();
         p_RLine=first_line;
         _select_line();
         p_RLine=first_line+num_first_lines-1;
         _select_line();
         if (createClipboard) {
            cut2(true,false,cbname);
         } else {
            _delete_selection();
         }
      }

      // then delete the trailing part of the statement
      if (num_last_lines > 0) {
         _deselect();
         p_RLine=last_line-num_last_lines-num_first_lines+1;
         _select_line();
         p_RLine=last_line-num_first_lines;
         _select_line();
         if (createClipboard) {
            append_to_clipboard(cbname);
         }

         _deselect();
         p_RLine=last_line-num_last_lines-num_first_lines+1;
         _select_line();
         p_RLine=last_line-num_first_lines;
         _select_line();
         _delete_selection();
      }
      break;

   default:
      // they hit cancel, so do nothing, but pretend we did something
      in_unsurround=false;
      return true;
   }

   // kill any residual selection and attempt to restore cursor position.
   _deselect();
   goto_point(orig_point);
   first_non_blank();
   in_unsurround=false;

   // we have either deleted the block or unsurrouned it
   return true;
}

/**
 * Locate the enclosing block statement for the line the cursor is
 * currently located on and attempt to jump into dynamic surround to
 * adjust the scope of that block statement.
 * 
 * @categories Editor_Control_Methods
 */
_command int dynamic_surround(_str quiet='', _str onlyIfEmpty='') name_info(',' VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK)
{
   // save original line, column, cursor position
   save_pos(auto p);

   // these items will be calculated by the callback.
   first_line := 0;
   last_line  := 0;
   num_first_lines := 0;
   num_last_lines  := 0;
   indent_change := true;

   // Check if we have the language specific callback
   lang := _GetEmbeddedLangId();
   if (lang == 'fundamental') {
      return 0;
   }
   index := _FindLanguageCallbackIndex("_%s_find_surround_lines",lang);
   if (index <= 0) {
      if ( quiet=='' ) {
         _message_box("Dynamic surround not supported");
      }
      return -1;
   }

   // now call the callback and immediately restore the cursor position
   found_block := call_index(first_line, last_line, num_first_lines, num_last_lines, indent_change, index);
   if ( !found_block ) {
      if ( quiet=='' ) {
         _message_box("Statement not recognized");
      }
      return -1;
   }

   // check if there are any statements in the block
   if ( onlyIfEmpty != '' ) {
      if ( onlyIfEmpty != last_line ||
           first_line+num_first_lines < last_line ) {
         return -1;
      }
      //Insert an undo step here, so user can undo just the paste
      _undo('S');
   }

   // now set up and slip into dynamic surround mode
   p_line = first_line;
   first_non_blank();
   set_surround_mode_start_line(first_line, num_first_lines);
   set_surround_mode_end_line(last_line, num_last_lines, true);
   gSurroundDoIndent = indent_change;
   do_surround_mode_keys(true);

   // ok, now move cursor back where we started
   restore_pos(p);
   return 0;
}

///////////////////////////////////////////////////////////////////////////////
defeventtab _auto_unsurround_form;
void ctl_delete_line.on_create(boolean createClipboard=false,
                               boolean allowUnsurround=false,
                               boolean hideDeleteLine=false,
                               boolean hideCheckBox=false)
{
   ctl_always_delete_line.p_value = (int) !def_auto_unsurround_block;
   ctl_always_delete_block.p_value =(int) !def_prompt_for_delete_code_block;
   ctl_unsurround.p_enabled = allowUnsurround;
   ctl_cut_label.p_visible = createClipboard;
   ctl_always_delete_line.p_visible = !hideCheckBox;
   ctl_always_delete_line.p_enabled = !hideCheckBox;

   if (hideDeleteLine) {
      ctl_delete_line.p_visible=false;
      ctl_always_delete_line.p_visible=false;
      ctl_always_delete_line.p_enabled=false;

      int delta_y = ctl_unsurround.p_y-ctl_delete_block.p_y;
      ctl_delete_block.p_y   -= delta_y;
      ctl_always_delete_block.p_y -= delta_y;
      ctl_unsurround.p_y     -= delta_y;
      ctl_cut_label.p_y      -= delta_y;
      ctl_cancel.p_y         -= delta_y;
      p_active_form.p_height -= delta_y;
   } else {
      ctl_always_delete_block.p_visible = false;
      ctl_always_delete_block.p_enabled = false;
   }

   int keys[];
   if (createClipboard) {
      copy_key_bindings_to_form("cut-line", ctl_delete_line.p_window_id, LBUTTON_UP, keys);
   } else {
      copy_key_bindings_to_form("delete-line", ctl_delete_line.p_window_id, LBUTTON_UP, keys);
   }
  
}
void _auto_unsurround_form.on_load()
{
   if ( !ctl_always_delete_line.p_visible ) {
      ctl_delete_line.p_default = false;
      ctl_delete_block.p_default = true;
      ctl_delete_block._set_focus();
   }
}
void ctl_always_delete_line.lbutton_up()
{
   ctl_unsurround.p_enabled=(p_value==0);
   ctl_delete_block.p_enabled=(p_value==0);

   if ( ctl_always_delete_line.p_value != 0 ) {
      ccb_cmd := "cut_code_block";
      ccb_key := _mdi.p_child.where_is(ccb_cmd,true);
      parse ccb_key with . "is bound to " ccb_key;
      if (ccb_key=='') {
         ccb_key = _mdi.p_child.where_is("delete_code_block",true);
         parse ccb_key with . "is bound to " ccb_key;
         if (ccb_key != "") ccb_cmd = "delete_code_block";
      }
      if (ccb_key!='') {
         _message_box("To delete entire code blocks on demand:\ninvoke the "ccb_cmd" command directly by pressing: "ccb_key".");
      } else {
         reply := _message_box("To delete entire code blocks on demand:\ncreate a key binding for the 'cut_code_block' command.\n\nWould you like to create a key binding now?", "SlickEdit", MB_YESNO);
         if (reply == IDYES) {
            gui_bind_command("cut_code_block");
         }
      }
   }
}
void ctl_always_delete_block.lbutton_up()
{
   ctl_unsurround.p_enabled=(p_value==0);
   ctl_delete_line.p_enabled=(p_value==0);

   if ( ctl_always_delete_block.p_value != 0 ) {
      ccb_cmd := "unsurround";
      ccb_key := _mdi.p_child.where_is(ccb_cmd,true);
      parse ccb_key with . "is bound to " ccb_key;
      if (ccb_key!='') {
         _message_box("To unsurround code blocks on demand:\ninvoke the "ccb_cmd" command directly by pressing: "ccb_key".");
      } else {
         reply := _message_box("To unsurround code blocks on demand:\ncreate a key binding for the 'unsurround' command.\n\nWould you like to create a key binding now?", "SlickEdit", MB_YESNO);
         if (reply == IDYES) {
            gui_bind_command("unsurround");
         }
      }
   }
}
void ctl_delete_line.lbutton_up()
{
   if (ctl_always_delete_line.p_enabled && 
       ctl_always_delete_line.p_value == def_auto_unsurround_block) {
      def_auto_unsurround_block = (ctl_always_delete_line.p_value == 0);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   p_active_form._delete_window('D');
}
void ctl_unsurround.lbutton_up()
{
   p_active_form._delete_window('U');
}
void ctl_delete_block.lbutton_up()
{
   if (ctl_always_delete_block.p_enabled && 
       ctl_always_delete_block.p_value == def_prompt_for_delete_code_block) {
      def_prompt_for_delete_code_block = (ctl_always_delete_block.p_value == 0);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   p_active_form._delete_window('B');
}

