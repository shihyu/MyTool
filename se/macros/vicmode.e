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
#include "ex.sh"
#import "bind.e"
#import "bookmark.e"
#import "cformat.e"
#import "clipbd.e"
#import "complete.e"
#import "ex.e"
#import "files.e"
#import "get.e"
#import "hex.e"
#import "main.e"
#import "markfilt.e"
#import "moveedge.e"
#import "options.e"
#import "pmatch.e"
#import "pushtag.e"
#import "put.e"
#import "recmacro.e"
#import "search.e"
#import "seek.e"
#import "seldisp.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "vi.e"
#import "vivmode.e"
#import "window.e"
#endregion

int  def_vi_always_preview_change;
_str _vi_insertion_pos;
_str def_vi_chars;
_str def_vi_chars2;

bool def_vim_esc_codehelp=false;
bool def_vim_stay_in_ex_prmpt=true;
bool def_vim_start_in_cmd_mode=false;

_str def_next_word_style;

static int gupdown_col=1;
static int  gupdown_cursor_x=0;
static int gupdown_left_edge=0;

// Used by vi-change to do a call-key after the text
// to be changed has been cut.
_str _vi_ckey='';

// Cursor definitions for Vim
_str VI_INSERT_CURSOR='-v 750 1000 750 1000 750 1000 750 1000';
_str VI_COMMAND_CURSOR='750 1000 750 1000 750 1000 750 1000';

static const INTRALINE_CMDS= ' vi-cursor-right vi-cursor-left vi-begin-next-line':+
                       ' vi-next-line vi-prev-line vi-begin-prev-line vi-begin-line':+
                       ' vi-begin-text vi-end-line vi-goto-line vi-goto-col vi-next-word':+
                       ' vi-next-word2 vi-prev-word vi-prev-word2 vi-end-word':+
                       ' vi-end-word2 vi-prev-sentence vi-next-sentence vi-visual-select-up':+
                       ' vi-maybe-text-motion vi-goto-percent vi-open-bracket-cmd vi-closed-bracket-cmd ';

static const INTRALINE_CMDS2= ' vi-prev-paragraph vi-next-paragraph vi-prev-section':+
                        ' vi-next-section vi-find-matching-paren vi-top-of-window':+
                        ' vi-middle-of-window vi-bottom-of-window vi-prev-line-context':+
                        ' vi-prev-context vi-to-mark-col vi-to-mark-line vi-visual-select-left' :+
                        ' vi-visual-select-right vi-visual-select-down vi-visual-begin-select vi-visual-next-word':+
                        ' vi-visual-prev-word vi-visual-prev-word2 vi-visual-next-word2 vi-visual-end-word':+
                        ' vi-visual-end-word2 ';

static const INTRALINE_CMDS3= ' vi-visual-next-paragraph vi-visual-prev-paragraph vi-visual-next-sentence':+
                        ' vi-visual-prev-sentence vi-visual-a-cmd vi-visual-i-cmd vi-visual-maybe-text-motion ';

/* The line command constants are used primarily by VI-SHIFT-TEXT-LEFT and
 * VI-SHIFT-TEXT-RIGHT to determine which commands are valid to use in
 * delimiting the lines to shift.
 */
static const LINE_CMDS= ' vi-begin-next-line vi-next-line vi-prev-line vi-begin-prev-line':+
                  ' vi-goto-line vi-next-word vi-next-word2 vi-prev-word vi-prev-word2':+
                  ' vi-end-word vi-end-word2 vi-prev-sentence vi-next-sentence';

static const LINE_CMDS2= ' vi-prev-paragraph vi-next-paragraph vi-prev-section vi-next-section':+
                   ' vi-find-matching-paren vi-top-of-window vi-middle-of-window':+
                   ' vi-bottom-of-window vi-to-mark-line ';

static const MODIFICATION_CMDS= ' vi-change-line-or-to-cursor vi-change-to-end vi-join-line':+
                          ' vi-replace-char vi-replace-line vi-substitute-char':+
                          ' vi-substitute-line vi-shift-text-left vi-shift-text-right':+
                          ' vi-toggle-case-char vi-filter vi-visual-replace vi-visual-change':+
                          ' vi-visual-upcase vi-visual-downcase vi-visual-toggle-case vi-visual-join':+
                          ' vi-visual-maybe-join-nospaces vi-visual-shift-left vi-visual-shift-right vi-format':+
                          ' vi-increment vi-decrement ';

static const DELETE_CMDS= ' vi-forward-delete-char vi-backward-delete-char vi-visual-delete ';

static const CB_CMDS= ' vi-put-after-cursor vi-put-before-cursor vi-yank-to-cursor vi-yank-line vi-visual-yank':+
                ' vi-visual-put ';

static const SEARCH_CMDS= ' vi-char-search-forward vi-char-search-backward vi-char-search-forward2':+
                    ' vi-char-search-backward2 vi-repeat-char-search vi-reverse-repeat-char-search':+
                    ' vi-to-mark-line vi-to-mark-col ex-search-mode ex-reverse-search-mode vi-visual-search':+
                    ' vi-visual-reverse-search vi_quick_search vi_quick_reverse_search ';

static const DOUBLE_CMDS= ' vi-delete vi-change-line-or-to-cursor vi-shift-text-left vi-shift-text-right':+
                    ' vi-yank-to-cursor vi-filter ';

static const SCROLL_CMDS= ' vi-scroll-window-down vi-scroll-window-up ';

/**
 * Callback used in Vim emulation for changing the cursor shape. 
 * Uses underscore-cursor if in command mode, depending on def
 * var.
 * 
 * @return int
 */
int _vi_switchmode_cursor_shape(){
   if( def_keys=='vi-keys' ) {
      if (def_vim_change_cursor) {
         typeless mode=vi_get_vi_mode();
         if( mode=='C' || mode=='V') {
            _cursor_shape(VI_COMMAND_CURSOR,false);
         } else {
            _cursor_shape(VI_INSERT_CURSOR,false);
         }
      }
   }
   return(0);
}

/**
 * This function returns [by reference] the start and end 
 * columns of the current 'WORD' (according to Vim 
 * documentation) at the cursor. 
 *  
 * A 'word' is described as a sequence of non-blank characters, 
 * seperated with white space (spaces, tabs, EOL). 
 *  
 * @param startCol 
 * @param endCol 
 * @param leading_spaces 
 * @param trailing_spaces 
 *  
 * @see http://vimdoc.sourceforge.net/htmldoc/motion.html#word 
 * 
 */
void vi_cur_word_boundaries2(int &startCol, int &endCol, int spaces = 0, _str dir = "+")
{
   cur_char := get_text();
   // If on a blank char, find the whole sequence
   if (cur_char == " " || cur_char == "\t") {
      save_pos(auto p);
      search('[ \t]#','@rh-');
      startCol = p_col;
      search('[ \t]#','@rh+>');
      left();
      endCol = p_col;
      if (spaces) {
         // in this case we only look for trailing
         search('['def_vi_chars'|'def_vi_chars2']#|$','@rh+>');
         left();
         endCol = p_col;
      }
      restore_pos(p);
   } else {
      // Otherwise, find the whole WORD
      save_pos(auto p);
      status := search('['def_vi_chars'|'def_vi_chars2']#','@reh-<');
      startCol = p_col;
      status = search('['def_vi_chars'|'def_vi_chars2']#','@reh+>');
      left();
      endCol = p_col;
      if (spaces) {
         // have to leave cursor after result in case of a string of spaces
         search('[ \t]#|$','@rh+>');
         left();
         cur_char = get_text();
         if (cur_char != ' ' && cur_char != '\t') {
            // didnt find trailing spaces...so find leading spaces
            left();
            search('[ \t]#|$|^','@rh-<');
            startCol = p_col;
         } else {
            endCol = p_col;
         }
      }
      restore_pos(p);
   }
   if (dir == "-") {
      temp := startCol;
      startCol = endCol;
      endCol = temp;
   }
}

/**
 * This function returns [by reference] the start and end 
 * columns of the current 'word' (according to Vim 
 * documentation) at the cursor. 
 *  
 * A 'word' is described as a sequence of letters digits and 
 * underscores, or a sequence of other non-blank characters, 
 * seperated with white space (spaces, tabs, EOL). 
 *  
 * @param startCol 
 * @param endCol 
 * @param leading_spaces 
 * @param trailing_spaces 
 *  
 * @see http://vimdoc.sourceforge.net/htmldoc/motion.html#word 
 * 
 */
void vi_cur_word_boundaries(int &startCol, int &endCol, int spaces = 0, _str dir = "+")
{
   // Are we on a def_vi_chars character? (letter, digit, underscore)
   cur_char := get_text();
   at_normal_word_char := (isalnum(cur_char)||cur_char == "_");
   // If we are, then cur_word should grab the appropriate word
   if (at_normal_word_char) {
      save_pos(auto p);
      search('['def_vi_chars']#','@reh-<');
      startCol = p_col;
      search('['def_vi_chars']#','@reh+>');
      left();
      endCol = p_col;
      if (spaces) {
         // have to leave cursor after result in case of a string of spaces
         search('[ \t]#|['def_vi_chars2']|$','@rh+>');
         left();
         cur_char = get_text();
         if (cur_char != ' ' && cur_char != '\t') {
            // didnt find trailing spaces...so find leading spaces
            left();
            search('[ \t]#|['def_vi_chars2']|$|^','@rh-<');
            cur_char = get_text();
            if (cur_char != ' ' && cur_char != '\t') {
               right();
            }
            startCol = p_col;
         } else {
            endCol = p_col;
         }
      }
      restore_pos(p);
   } else if (cur_char != " " && cur_char != "\t") {
      // We are on some other non-blank character...find the start/end of the sequence
      save_pos(auto p);
      status := search('['def_vi_chars2']#','@reh-<');
      startCol = p_col;
      status = search('['def_vi_chars2']#','@reh+>');
      left();
      endCol = p_col;
      if (spaces) {
         // have to leave cursor after result in case of a string of spaces
         search('[ \t]#|['def_vi_chars']|$','@rh+>');
         left();
         cur_char = get_text();
         if (cur_char != ' ' && cur_char != '\t') {
            // didnt find trailing spaces...so find leading spaces
            left();
            search('[ \t]#|['def_vi_chars']|$|^','@rh-<');
            cur_char = get_text();
            if (cur_char != ' ' && cur_char != '\t') {
               right();
            }
            startCol = p_col;
         } else {
            endCol = p_col;
         }
      }
      restore_pos(p);
   } else {
      // Must be a blank...find the start/end of the sequence of blanks
      save_pos(auto p);
      search('[ \t]#','@rh-');
      startCol = p_col;
      search('[ \t]#','@rh+>');
      left();
      endCol = p_col;
      if (spaces) {
         // in this case we only look for trailing
         search('['def_vi_chars']#|['def_vi_chars2']#|$','@rh+>');
         left();
         endCol = p_col;
      }
      restore_pos(p);
   }
   if (dir == "-") {
      temp := startCol;
      startCol = endCol;
      endCol = temp;
   }
}

/**
 * By default this command handles '1'-'9' pressed.
 * <P>
 * The '0' key in vi serves two purposes in command mode:
 * <OL>
 *   <LI>If user is not in the process of specifying a
 *       repeat count, then this key will put cursor at
 *       column 1
 *   <LI>Otherwise, the repeat count is extended
 * </OL>
 */
_command int vi_count(_str arg1="", _str clipboard_info="", 
                      typeless multiplier="", 
                      _str snapToEndLine="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{     
   static _str key;
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   _macro('m',_macro());
   _macro_delete_line();

   arg1=strip(arg1);
   option := last_name := "";
   parse arg1 with option ':' last_name;
   option=upcase(strip(option));
   last_name=vi_name_eq_translate(last_name);
   in_delete := (option=='D');
   in_modification := (option=='M');
   in_cb := (option=='C');
   in_cb_name := (option=='N');
   cb_info := "";
   if( in_delete || in_cb || in_cb_name || in_modification ) {
      cb_info=clipboard_info;
   }
   // Should we snap the cursor to the end of the line if an operation
   // leaves the cursor in virtual space?
   snap_to_end_line := true;
   if( snapToEndLine!='' && snapToEndLine ) {
      snap_to_end_line=false;
   }
   static _str lkey;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      lkey=last_event();
      if( length(lkey)!=1 || ! isinteger(lkey) || lkey<1 ) {
         _MultiCursorLoopDone();
         vi_message('The key "'key'" should not be bound to vi-count');
         return(1);
      }
   }
   // This is a multiplier for the repeat count
   if( !isinteger(multiplier) || multiplier<1 ) {
      multiplier=1;
   }
   static typeless repeat_count;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      repeat_count='';
      key=lkey;
   }
   // See declaration above
   _vi_ckey='';
   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      for(;;) {
         repeat_count :+= key;
         key=vi_get_event();
         if (!isinteger(key) || length(key)!=1 || key<0) {
            break;
         }
      }
   }

   typeless status=0;
   typeless info="";
   typeless mark="";

   _str name=vi_name_eq_translate(vi_name_on_key(key));
   is_intraline_cmd := ( vi_name_in_list(name,INTRALINE_CMDS) || vi_name_in_list(name,INTRALINE_CMDS2) || vi_name_in_list(name,INTRALINE_CMDS3));
   is_modification_cmd := ( vi_name_in_list(name,MODIFICATION_CMDS) && !vi_name_in_list(name,'vi-replace-line') );
   is_delete_cmd := ( vi_name_in_list(name,DELETE_CMDS) );
   is_cb_cmd := ( vi_name_in_list(name,CB_CMDS) );
   is_cb_name_cmd := ( vi_name_in_list(name,'vi-cb-name') );
   is_search_cmd := ( vi_name_in_list(name,SEARCH_CMDS) );
   is_posted_cmd := ( vi_name_in_list(name,VI_CMDS_POSTED_INSERT) );
   is_scroll_cmd := ( vi_name_in_list(name,SCROLL_CMDS) );

   // 'is_double_cmd' handles cases like 'd3d' or 'c3c' or '>3>' or 'y3y'
   is_double_cmd := (name==last_name && vi_name_in_list(name,DOUBLE_CMDS) && vi_name_in_list(last_name,DOUBLE_CMDS));

   index := find_index(name,COMMAND_TYPE);
   if( index==0 || ! index_callable(index) ) {
      _MultiCursorLoopDone();
      vi_message('Command "'name'" not found');
      status=1;
      return status;
   }
   typeless p=0;
   typeless arg2info="";
   parse name_info(index) with ',' arg2info;
   if( p_readonly_mode && !(arg2info&VSARG2_READ_ONLY) ) {
      _MultiCursorLoopDone();
      ex_msg_ro();
      status=1;
      return status;
   }
   // We must add the test:  !isinteger(key) for the case of
   // vi_begin_line() which is normally bound to '0'.
   if( !isinteger(key) && (is_intraline_cmd || is_modification_cmd || is_delete_cmd || is_cb_cmd || is_cb_name_cmd || is_search_cmd || is_double_cmd) ) {
      if( !is_double_cmd && (((is_modification_cmd || is_delete_cmd || is_cb_cmd || is_cb_name_cmd) && (in_modification || in_cb))
         || ((is_modification_cmd || is_delete_cmd || is_cb_cmd) && in_delete)) ) {
         _MultiCursorLoopDone();
         vi_message('Invalid key sequence');
         status=1;
         return status;
      }

      inclusive_mark_override := false;
      if( in_modification && last_name=='vi-change-line-or-to-cursor' ) {
         if( vi_name_in_list(name,'vi-next-word vi-next-word2 vi-end-word vi-end-word2') ) {
            inclusive_mark_override=true;
            switch( name ) {
               case 'vi-next-word':
                  name='vi-end-word';
                  break;
               case 'vi-next-word2':
                  name='vi-end-word2';
                  break;
            }
            // We need the new index if the name changed
            index=find_index(name,COMMAND_TYPE);
         }
      } else if( in_delete ) {
         if( vi_name_in_list(name,'vi-end-word vi-end-word2') ) {
            inclusive_mark_override=true;
         }
      }

      // Begin the mark
      //
      // Will need this later when checking for vi-change-line-or-to-cursor
      beginline := p_line;
      if( (in_delete || in_cb || in_modification) && cb_info!='' ) {
         mark=_alloc_selection();
         if( mark<0 ) {
            _MultiCursorLoopDone();
            vi_message(get_message(mark));
            status=mark;
            return status;
         }
         if( is_double_cmd ) {
            // A double command is always a line mark marking 'repeat_count'
            // lines including the current line. The only commands that will
            // not be included here are:  vi-shift-text-left and
            // vi-shift-text-right.
            _select_line(mark,'P');
         } else {
            // This starts the appropriate mark-type depending on which
            // command is specified by 'name'.
            intraline_mark(name,mark,'',1);
         }
      }

      p=_nrseek();
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_event(key);
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_index(index);
      info='';
      if( is_cb_cmd || in_cb_name ) {
         info=cb_info;
      }
      if( is_double_cmd ) {
         // A double command requires that we simply mark 'repeat_count'
         // lines including the current line.
         typeless q;
         save_pos(q);
         status=down(multiplier*repeat_count-1);
         if( status ) {
            restore_pos(q);
         }
      } else {
         // Check special case of vi_change_line_or_to_cursor()
         // used with vi_end_word() or vi_end_word2().
         include_cur_col := false;
         if( last_name=='vi-change-line-or-to-cursor' && vi_name_in_list(name,'vi-end-word vi-end-word2') ) {
            _str line=_expand_tabsc();
            _str ch1=_SubstrChars(line,p_col,1);
            _str ch2=_SubstrChars(line,p_col+1,1);
            if( name=='vi-end-word' ) {
               include_cur_col= ( (pos('[\od\p{L}\p{N}'def_vi_chars']',ch1,'','r') && !pos('[\od\p{L}\p{N}'def_vi_chars']',ch2,'','r')) ||
                                  (pos('['def_vi_chars2']',ch1,'','r') && !pos('['def_vi_chars2']',ch2,'','r')) ||
                                  pos('[ \t]',ch1,'','r')
                                );
            } else {
               include_cur_col= ( (pos('[~ \t]',ch1,'','r') && !pos('[~ \t]',ch2,'','r')) ||
                                  pos('[ \t]',ch1,'','r')
                                );
            }
            if( (multiplier*repeat_count)>1 || !include_cur_col ) {
               if( include_cur_col ) {
                  // Subtract 1 so we select the correct number of words
                  _macro_call(stranslate(name_name(index),'_','-'),multiplier*repeat_count-1,info);
                  // 'info' is an optional argument used mainly by the
                  // clipboard commands.
                  status=call_index(multiplier*repeat_count-1,info,index);
               } else {
                  _macro_call(stranslate(name_name(index),'_','-'),multiplier*repeat_count,info);
                  // 'info' is an optional argument used mainly by the
                  // clipboard commands.
                  status=call_index(multiplier*repeat_count,info,index);
               }
            }
         } else {
            //Special case here for #%
            if(event2name(key) == '%'){
               vi_goto_percent(multiplier*repeat_count);
            }
            else {
               _macro_call(stranslate(name_name(index),'_','-'),multiplier*repeat_count,info);
               // 'info' is an optional argument used mainly by the
               // clipboard commands.
               status=call_index(multiplier*repeat_count,info,index);
            }
         }
      }
      if( status ) {
         if( p==_nrseek() && name!='vi-cursor-right' ) {
            // A possible error occurred in the command called
            if ( (in_delete || in_cb || in_modification) && cb_info!='' ) {
               _free_selection(mark);
            }
            //error=true;
            return status;
         } else {
            // Clear the message if not a serious error.
            // A non_serious error would be CALLing vi_cursor_down()
            // more times than is valid, where the result is to
            // simply put the cursor at the bottom of the file.
            clear_message();
         }
      }

      // End the mark and move to the clipboard
      //
      // Will need this when checking for vi_change_line_or_to_cursor()
      endline := p_line;
      if( (in_delete || in_cb || in_modification) && cb_info!='' ) {
         if( is_double_cmd ) {
            // A double command is always a line mark marking 'repeat_count'
            // lines including the current line. The only commands that will
            // not be included here are:  vi_shift_text_left() and
            // vi_shift_text_right().
            _select_line(mark,'P');
         } else {
            status=(status || inclusive_mark_override);
            // This ends the appropriate mark-type depending on which
            // command is specified by 'name'.
            intraline_mark(name,mark,status,0);
         }

         // There were no serious errors so far
         status=0;
         // Get the mark showing
         typeless old_mark=_duplicate_selection('');
         _show_selection(mark);
         typeless at_bottom=down();
         if( !at_bottom ) up();
         copy_option := "";
         cb_name := "";
         parse cb_info with copy_option cb_name;
         stack_push := "";
         if( in_delete ) {
            // Push onto clipboard stack too
            stack_push=1;
         }
         typeless stype=_select_type(mark);
         if( !is_double_cmd && last_name=='vi-change-line-or-to-cursor' && ((stype!='LINE' && beginline==endline) || def_vi_always_preview_change) ) {
            // Special case:  leave the highlighted block until a key
            // is pressed to show what the user is changing.
            _begin_select(mark);
            // Don't attempt showing the highlighted block if we are in
            // a multi-cursor loop.
            if (!_MultiCursorAlreadyLooping()) {
               _vi_ckey=vi_get_event();
            }
         }

         if( !is_double_cmd && last_name=='vi-change-line-or-to-cursor' ) {

            // Check to see if only an empty line was selected
            save_pos(p);
            _begin_select(mark);
            beginline=p_line;
            _end_select(mark);
            endline=p_line;
            restore_pos(p);
            int noflines=endline-beginline+1;
            single_empty_line := (noflines==1 && !_line_length() );
            if( stype=='LINE' || !single_empty_line ) {
               if( vi_cut(false,cb_name) ) {
                  status=1;
               }
            }
         } else {
            if ( vi_cut(copy_option!=0,cb_name,stack_push) ) {
               // Something happened when trying to move the mark
               // to the clipboard.
               status=1;
            }
         }

         if( !status ) {
            // Check special cases
            if( (is_double_cmd && name=='vi-change-line-or-to-cursor') ||
                (last_name=='vi-change-line-or-to-cursor' && stype=='LINE')
            ) {
               // Now check to see if we are at bottom of file
               //
               // Are we at the bottom of the file?
               if( !at_bottom ) {
                  up();
               }
               // Open a new line for inserting
               _str lkey2=last_event();
               // Must do this so nosplit_insert_line() works correctly
               last_event(ENTER);
               nosplit_insert_line();
               // Set the last event back
               last_event(lkey2);
            }
         }
         _show_selection(old_mark);
         _free_selection(mark);
         // Now make sure the cursor is on a real character
         if( snap_to_end_line && p_col>_text_colc() ) {
            p_col=_text_colc();
         }
      }
      return status;
   } else if( (name=='vi-delete' || name=='vi-delete-to-end') && ! in_delete && !in_cb && !in_modification ) {
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_event(key);
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_index(index);
      _macro_call(stranslate(name_name(index),'_','-'),cb_info,info);
      status=call_index(multiplier*repeat_count,cb_info,index);
      return status;
   } else if( name=='vi-execute-kbdmacro' && !in_delete && !in_cb && !in_modification ) {
      status=vi_execute_kbdmacro(repeat_count/*,cb_info*/);
      return status;
   } else if( name=='vi-repeat-last-insert-or-delete' && !in_delete && !in_cb && !in_modification ) {
      status=vi_repeat_last_insert_or_delete(repeat_count,cb_info);
      return status;
   } else if( is_posted_cmd ) {
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_event(key);
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_index(index);
      _macro_call(stranslate(name_name(index),'_','-'),repeat_count);
      status=call_index(repeat_count,index);
      return status;
   } else if( is_scroll_cmd || key == '*' || key == '#') {
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_event(key);
      // Set this so that vi_repeat_last_insert_or_delete() works correctly
      last_index(index);
      _macro_call(stranslate(name_name(index),'_','-'),repeat_count);
      status=call_index(repeat_count,index);
      return status;
   }
   _MultiCursorLoopDone();
   vi_message('Invalid key sequence');
   status=1;
   return status;
}

/**
 * By default this command handles 'l',SPACE,RIGHT pressed.
 * <P>
 * This command will NOT allow the cursor to go past the end of the line.
 * <P>
 * <B>Please note:</B>
 * <BR>
 * You might observe that the delete option used in conjunction
 * with this command behaves differently when used with the
 * vi-cursor-left command.  This is how the true vi behaves, and
 * not our choice.
 *
 * @return
 */
_command int vi_cursor_right(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      } else {
         right();
      }
      return(0);
   }
   if (p_hex_mode==HM_HEX_ON) {
      cursor_right();
      return 0;
   }
   if ( !isinteger(count) || count<1 ) {
      count=1;
   }

   typeless status=0;
   if ( !_line_length() ) {
      vi_message('Line is empty');
      return(1);
   }
   int add_one= (vi_get_vi_mode()=='V')?1:0;
   int i;
   for( i=0;i<count;++i ) {
      right();
      if( p_col>_text_colc()+add_one ) {
         status=1;   // This is not serious
         break;
      }
   }
   if( status ) {
      left();
      vi_message('Can''t go past end of line');
      _macro('KA');  // Abort playback
      return(1);
   }

   _undo('S');
   return(status);
}


/**
 * By default this command handles 'h',LEFT pressed.
 * <P>
 * This command will NOT allow the cursor to go past beginning of line.
 * <P>
 * <B>Please note:</B>
 * <BR>
 * You might observe that the delete option used in conjunction
 * with this command behaves differently when used with the
 * vi-cursor-right command.  This is how the true vi behaves, and
 * not our choice.
 *
 * @return
 */
_command int vi_cursor_left(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      } else if ( key:==BACKSPACE ) {
         rubout();
      } else {
         left();
      }
      return(0);
   }
   if (p_hex_mode==HM_HEX_ON) {
      cursor_left();
      return 0;
   }
   if ( count=='' || count<1 ) {
      count=1;
   }

   typeless status=0;
   if( p_col==1 ) {
      vi_message('Can''t go past beginning of line');
      return(1);
   }
   //_undo('S');
   int i;
   for( i=0;i<count;++i ) {
      if( p_col==1 ) {
         status=1;   // This is not serious
         break;
      }
      left();
   }

   _undo('S');
   return(status);
}

/**
 * By default this command handles 'BACKSPACE' or 'S-BACKSPACE' pressed.
 * 
 * @return 
 */
_command int vi_cmd_backspace(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   typeless key="";
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      } else if ( key:==BACKSPACE ) {
         rubout();
      } else {
         left();
      }
      return(0);
   }
   if ( count=='' || count<1 ) {
      count=1;
   }

   typeless status=0;
   if( p_col==1 ) {
      up();
      _TruncEndLine();
      return(1);
   }
   //_undo('S');
   int i;
   for( i=0;i<count;++i ) {
      if( p_col==1 ) {
         up();
         _TruncEndLine();
      } else{
         left();
      }
   }

   _undo('S');
   return(status);
}

/**
 * By default this command handles '+',ENTER.
 * <P>
 * This command moves cursor down 1 line to the first non-blank character.
 */
_command int vi_begin_next_line(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==ENTER && p_window_id==_cmdline ) {
         command_execute();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if ( count=='' || count<1 ) {
      count=1;
   }
   // Save in case of fail
   save_pos(auto p);

   if ( down(count) ) {
      restore_pos(p);
      vi_message('Can''t move past end of file');
      return(1);
   }

   // Make sure cursor is on first non-blank character
   _first_non_blank();

   return(0);
}

/**
 * By default this command handles 'j','C-N',DOWN pressed.
 * <P>
 * This command moves cursor down/up 1 line without changing the column.
 * <P>
 * <B>Note:</B> If direction='-' then go up to PREVious line.
 */
_command int vi_next_line(typeless count=1, _str direction="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
  key := "";
  if( command_state() ) {
     key=last_event();
     if( key==UP && p_window_id==_cmdline ) {
        retrieve_prev();
     } else if( key==DOWN && p_window_id==_cmdline ) {
        retrieve_next();
     } else if( isnormal_char(key) ) {
        keyin(key);
     }
  } else {
     if( !isinteger(count) || count<1 ) {
        count=1;
     }
     read_behind();
     _str prev_cmd=name_name(prev_index());
     if( gupdown_col && prev_cmd!='vi-next-line' && prev_cmd!='vi-prev-line' && prev_cmd!='vi-visual-select-down' && prev_cmd!='vi-visual-select-up') {
        gupdown_col=p_col;
        gupdown_cursor_x=p_cursor_x;
        gupdown_left_edge=p_left_edge;
     }
     status := 0;
     //_undo('S');
     int i;
     for( i=1;i<=count;++i ) {
        if( p_hex_mode ) {
           if( direction=='-' ) {
              _hex_up(def_updown_screen_lines);
           } else {
              _hex_down(def_updown_screen_lines);
           }
        } else {
           if( direction=='-' ) {
              status=up(1,def_updown_screen_lines);
           } else {
              status=down(1,def_updown_screen_lines);
           }
           if( status ) break;
           if( _lineflags()&HIDDEN_LF ) {
              --i;
           }
        }
     }
     if( !p_hex_mode ) {
        stay_on_text((typeless)gupdown_col,(typeless)gupdown_cursor_x,gupdown_left_edge,direction);
     }
     read_behind();
     _undo('S');
     if (status) {
        if( direction=='-' ) {
           vi_message('Can''t move past beginning of file');
        } else {
           vi_message('Can''t move past end of file');
        }
        _macro('KA');  // Abort playback
        return 1;
     }
  }

  return(0);
}

// Wholesaled from stdcmds.e
static void stay_on_text(int updown_col,int updown_cursor_x,int left_edge,_str direction,bool recurse=false)
{
   blockSelectionActive := (select_active() && _select_type():=='BLOCK');
   if ( updown_col) {
      if (!p_fixed_font || (p_hex_mode==HM_HEX_ON/* && p_UTF8*/)|| (p_SoftWrap && p_hex_mode!=HM_HEX_ON)) {
         //say('h2 x='updown_cursor_x);
         save_pos(auto p);
         set_scroll_pos(left_edge,p_cursor_y);
         int orig_cursor_y=p_cursor_y;
         p_cursor_x=updown_cursor_x;
         //say('col='p_col);
         if (!blockSelectionActive && p_hex_mode!=HM_HEX_ON/* && !p_SoftWrap*/) {
            if ( _text_colc(0,'E')<p_col ) {
               int add_one= (vi_get_vi_mode()=='V')?1:0;
               p_col=_text_colc(0,'E')+add_one;
            } else if( _text_colc(p_col,'T')<0 ) {
               p_col=_text_colc(1-_text_colc(p_col,'T'),'i');
            }
         }
         _refresh_scroll();
         if (!recurse && p_SoftWrap && orig_cursor_y!=p_cursor_y) {
            restore_pos(p);
            int count=1;
            for( i:=1;i<=count;++i ) {
               if( p_hex_mode ) {
                  if( direction=='-' ) {
                     _hex_up(def_updown_screen_lines);
                  } else {
                     _hex_down(def_updown_screen_lines);
                  }
               } else {
                  int status;
                  if( direction=='-' ) {
                     status=up(1,def_updown_screen_lines);
                  } else {
                     status=down(1,def_updown_screen_lines);
                  }
                  if( status ) break;
                  if( _lineflags()&HIDDEN_LF ) {
                     --i;
                  }
               }
            }
            if( !p_hex_mode ) {
               stay_on_text(updown_col,updown_cursor_x,left_edge,direction,true);
            }
         }
      } else if( !blockSelectionActive ) {
         if( _text_colc(0,'E')<updown_col ) {
            int add_one= (vi_get_vi_mode()=='V')?1:0;
            p_col=_text_colc(0,'E')+add_one;
         } else if( _text_colc(updown_col,'T')<0 ) {
            p_col=_text_colc(1-_text_colc(updown_col,'T'),'i');
         } else {
            p_col=updown_col;
         }
      }
   }
}

/**
 * By default this command handles 'k','C-P',UP pressed.
 * <P>
 * This command moves the cursor up 1 line without changing the column.
 */
_command int vi_prev_line(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   return(vi_next_line(count,'-'));
}

/**
 * By default this command handles '-' pressed.
 * <P>
 * This command moves cursor up 1 line to the first non-blank character.
 */
_command int vi_begin_prev_line(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   save_pos(auto p);   // Save the current position in case of fail

   typeless status=up(count);   // Go up 'count' lines

   if( status || _on_line0() ) {
      restore_pos(p);
      vi_message('Can''t move past beginning of file');
      return(1);
   }

   // Make sure cursor is on the first non-blank character
   vi_begin_text();

   return(0);
}

/**
 * By default this command handles '0' pressed.
 * <P>
 * This command puts the cursor in the first column.
 */
_command int vi_begin_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else if( p_window_id==_cmdline ) {
         line := "";
         col := 0;
         get_command(line,col);
         set_command(line,1);
      }
      return(0);
   }
   _begin_line();

   return(0);
}

/**
 * By default this command handles '^' pressed.
 * <P>
 * This command puts the cursor on the first non-blank character.
 */
_command int vi_begin_text() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else {
         line := "";
         col := 0;
         get_command(line,col);
         set_command(line,1);
      }
      return(0);
   }
   orig_col := p_col;
   _first_non_blank();
   if( p_col==orig_col ) {
      _begin_line();
   }
   if (_MultiCursorActiveLoopIteration()) {
      set_scroll_pos(0,p_cursor_y);
   }

   return(0);
}

/**
 * By default this command handles '$' pressed.
 * <P>
 * This command, unlike SlickEdit emulation, will put
 * the cursor on the last character of the line,
 * not after it.
 */
_command int vi_end_line(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else {
         _str line;
         get_command(line);
         set_command(line,length(line)+1);
      }
      return(0);
   }
   if ( count=='' || count<1 ) {
      count=1;
   }
   // Save the buffer location in case of fail
   save_pos(auto p);

   // Move the cursor
   typeless status=down(count-1);

   if ( status ) {
      // Restore the starting position
      restore_pos(p);
      vi_message('Can''t move past end of file');
      return(status);
   }
   _TruncEndLine();
   //_end_line();
   // Put cursor on last character of line
   left();

   return(0);
}

/**
 * By default this command handles 'G' pressed.
 * 
 * Changed behavior to go to end of file rather than throw error if 
 * linenum > Noflines. - RH
 * 
 */
_command int vi_goto_line(typeless linenum="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_MARK)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   Noflines := p_noflines;
   //if( linenum=='' || linenum<1 ) {
   if( linenum=='' || linenum<1 || linenum > Noflines) {
      linenum=Noflines;
   }
   /*if( linenum>Noflines ) {
      vi_message('No such line number');
      return(1);
   } else {*/
   vi_set_prev_context();   // Set the previous context
   goto_line(linenum);
   _first_non_blank();
   vi_visual_select();
   //}

   return(0);
}

/**
 * By default this command handles '|' pressed.
 */
_command int vi_goto_col(typeless col="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   // This is an imaginary length
   int len=_text_colc();
   if( col=='' || col<1 ) {
      // If no 'col' is given then move to column 1 of current line
      col=1;
   }
   if( col>len ) {
      vi_message('Can''t move past end of line');
      return(1);
   } else {
      // Set the column and then make sure we are not bisecting a DBCS
      // or UTF-8 character.
      p_col=col;right();left();
      if( p_fixed_font ) {
         if( p_col>p_char_width ) {
            // Scroll column into the middle of the window
            set_scroll_pos(p_col-(p_char_width intdiv 2),p_cursor_y);
         }
      } else {
         if( (p_cursor_x+p_left_edge)>p_client_width ) {
            // Scroll column into the middle of the window
            set_scroll_pos((p_client_width intdiv 2),p_cursor_y);
         }
      }
   }

   return(0);
}

/**
 * By default this command handles 'w' pressed.
 */
_command int vi_next_word(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
        keyin(key);
      }
      return(0);
   }
   
   if( count=='' || count<1 ) {
      count=1;
   }

   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      status=vi_skip_word('','','B');
      if ( status )  break;
   }
   if( status ) {
      bottom();_TruncEndLine();left();
      if( count==1 ) {
         vi_message('Can''t go past end of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles 'W' pressed.
 */
_command int vi_next_word2(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if ( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   int i;
   for( i=1; i<=count ; ++i ) {
      status=vi_skip_word('','1','B');
      if( status ) break;
   }
   if( status ) {
      bottom();_TruncEndLine();left();
      if( count==1 ) {
         vi_message('Can''t go past end of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles 'b' pressed.
 */
_command int vi_prev_word(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      status=vi_skip_word('-','','B');
      if( status ) break;
   }
   if( status ) {
      top();
      if( count==1 ) {
         vi_message('Can''t go past beginning of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles 'B' pressed.
 */
_command int vi_prev_word2(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      status=vi_skip_word('-','1','B');
      if( status ) break;
   }
   if( status ) {
      top();
      if( count==1 ) {
         vi_message('Can''t go past beginning of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles 'e' pressed.
 */
_command int vi_end_word(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      status=vi_skip_word('','','E');
      if( status ) break;
   }
   if( status ) {
      bottom();left();
      if( count==1 ) {
         vi_message('Can''t go past end of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles 'E' pressed.
 */
_command int vi_end_word2(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      status=vi_skip_word('','1','E');
      if( status ) break;
   }
   if( status ) {
      bottom();left();
      if( count==1 ) {
         vi_message('Can''t go past end of file');
         return(status);
      }
   }

   return(0);
}

// direction_option:  '-' = skip to previous word
//                    otherwise, skip to next word
//     chars_option:  ''  = use 'def_vi_chars'||'def_vi_chars2'
//                    otherwise, use '[~ \t]'
//  next_word_style:  'B' = moves cursor to beginning of next word
//                    'E' = moves cursor to end of next word
static int vi_skip_word(_str direction_option, _str chars_option, _str next_word_style)
{
   next_word_style=upcase(next_word_style);

   typeless p=0;
   typeless col=0;
   typeless status=0;
   line := "";
   word_re := "";
   word_re2 := "";
   charLen := 0;

   if( direction_option=='-' ) {
      p=point();col=p_col;
      if ( p_col==1 ) {
         up();_TruncEndLine();
      } else if(next_word_style != 'E'){
         left();
      } else {
         // This is the case where we are going backward to the end of a ward
         // So first we need to get out of the current word...this is done by
         // going to the beginning of the current word and moving left one space
         vi_skip_word('-',chars_option,'B');
         if ( p_col==1 ) {
            up();_TruncEndLine();
         }
         left();
      }
      if ( chars_option=='' ) {
         word_re='([\od\p{L}\p{N}':+def_vi_chars']#)|(['def_vi_chars2']#)|(^[ \t]@$)';
      } else {
         word_re='([~ \t]#)|(^[ \t]@$)';
      }
      if(next_word_style == 'B'){
         status=search(word_re,'@reh-<');
      } else {
         status=search(word_re,'@reh->');
      }
      // The only way you get stuck going backward to the end of a word is if you are
      // at a word which starts at the beginning of a line...so just move up in this case
      if( !status && (p==point() && col==p_col) ) {
         up();
         _end_line();
      }
      else if ( status ) {
         up();_begin_line();
      }
   } else {
      word_re='';
      word_re2='';
      if ( chars_option=='' ) {
         if ( next_word_style=='E' ) {
            word_re='(((^|)[\od\p{L}\p{N}':+def_vi_chars']#\c)|((^|)['def_vi_chars2']#\c))';
            line=_expand_tabsc(1,-2);
            _strBeginChar(line,p_col,charLen,true);
            bool at_last_char=(pos('[\od\p{L}\p{N}':+def_vi_chars']',_SubstrChars(line,p_col,1),'','r') && !pos('[\od\p{L}\p{N}':+def_vi_chars']',_SubstrChars(line,p_col+charLen,1),'','r')) ||
                         (pos('['def_vi_chars2']',_SubstrChars(line,p_col,1),'','r') && !pos('['def_vi_chars2']',substr(line,p_col+charLen,1),'','r'));
            if ( (p_col==1 && line=='') || at_last_char ) {
               // Don't want to get stuck on an empty line or at the end
               // of a word.
               right();
            }
         } else {
            //word_re='((([~\od'def_vi_chars']|^)\c[\od'def_vi_chars']#)|(([~'def_vi_chars2']|^)\c['def_vi_chars2']#))|(^[ \t]@$)'
            word_re='((^\c[~ \t])|(([~\od\p{L}\p{N}':+def_vi_chars'])\c[\od\p{L}\p{N}':+def_vi_chars']#)|(([~'def_vi_chars2'])\c['def_vi_chars2']#))|(^[ \t]@$)';
            //word_re2='((([~\od'def_vi_chars'])\c[\od'def_vi_chars']#)|(([~'def_vi_chars2'])\c['def_vi_chars2']#))|(^[ \t]@$)'
            word_re2='((([~\od\p{L}\p{N}':+def_vi_chars'])\c[\od\p{L}\p{N}':+def_vi_chars']#)|(([~'def_vi_chars2'])\c['def_vi_chars2']#))';
         }
      } else {
         if ( next_word_style=='E' ) {
            word_re='((^|)[~ \t]#\c)';
            line=_expand_tabsc(1,-2);
            _strBeginChar(line,p_col,charLen,true);
            at_last_char := (pos('[~ \t]',_SubstrChars(line,p_col,1),'','r') && ! pos('[~ \t]',_SubstrChars(line,p_col+charLen,1),'','r'));
            if ( (p_col==1 && line=='') || at_last_char ) {
               right();
            }
         } else {
            word_re='((([ \t]|^)\c[~ \t]#)|(^[ \t]@$))';
         }
      }
      p=point();col=p_col;
      status=search(word_re,'@reh');
      // Did we move?
      if( !status && (p==point() && col==p_col) ) {
         if( word_re2!='' ) {
            // Is the line blank (all whitespace)?
            if( _first_non_blank_col('-1')=='-1' ) {
               status=repeat_search();
            } else {
               status=repeat_search();
               if( status ) {
                  status=search(word_re2,'@reh');
                  // Did we move?
                  if( !status && (p==point() && col==p_col) ) {
                     status=repeat_search();
                  }
               }
            }
         } else {
            status=repeat_search();
         }
      }
      if ( next_word_style=='E' ) {
         left();
      }
   }

   if ( status ) {
      clear_message();
   }

   return(status);
}

/**
 * By default this command handles '(' pressed.
 */
_command int vi_prev_sentence(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if ( count=='' || count<1 ) {
      count=1;
   }
   typeless paragraph_chars=def_vi_or_ex_paragraphs;
   if ( paragraph_chars=='' ) {
      // This is from 'ex.sh'
      paragraph_chars=VI_DEFAULT_PARAGRAPHS;
   }
   typeless paragraph_re='(^['paragraph_chars']*$)';
   typeless skip_paragraphs_re='^~(['paragraph_chars']*$)';

   typeless p=0;
   typeless col=0;
   typeless status=0;
   int i;
   for (i=1; i<=count ; ++i) {
      if ( status ) break;
      if ( _first_non_blank_col('-1')=='-1' ) {
         // On a paragraph separator
         search('[~'paragraph_chars']','@rh-');
      }
      p=point();col=p_col;
      status=search(paragraph_re'|(^[ \t]*\c[~ \t'END_SENTENCE_CHARS'])|('END_OF_SENTENCE_RE'\c)','@rh-');
      if ( (!status && p==point() && p_col>=col) ) {   // In same place?
         status=repeat_search();
      }
      if( p_col>1 && p_col>=_text_colc()) {
         left();
         ch := get_text(-2);
         right();
         if( pos('['END_SENTENCE_CHARS']',ch,'','r') ) {
            status=repeat_search();
         }
      }
      for(;;) {
         if( status ) {
            top();
            break;
         }
         if( pos(get_text(1,match_length('S')),END_SENTENCE_CHARS) ) break;
         up();
         if( status ) break;
         get_line(auto line);
         down();
         if( pos(paragraph_re,line,'','R') ||
              pos(_last_char(strip(line)),END_SENTENCE_CHARS) ) {
            break;
         }
         status=repeat_search();
      }
   }
   // Clear possible "String not found" message
   clear_message();
   if( status && count==1 ) {
      if( p==point() && col==p_col ) {
         vi_message('Can''t move past beginning of file');
      }
      return(status);
   }

   return(0);
}

/**
 * By default this command handles ')' pressed.
 */
_command int vi_next_sentence(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless paragraph_chars=def_vi_or_ex_paragraphs;
   if( paragraph_chars=='' ) {
      // This is from 'ex.sh'
      paragraph_chars=VI_DEFAULT_PARAGRAPHS;
   }
   paragraph_re := '(^['paragraph_chars']*$)';
   skip_paragraphs_re := '^~(['paragraph_chars']*$)';

   typeless p=0;
   typeless col=0;
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      if( _first_non_blank_col('-1')=='-1' ) {
         // On a paragraph separator
         search(skip_paragraphs_re,'@rh');
         // Put cursor on first VALID character of the sentence
         search('[\od\p{L}\p{N}':+def_vi_chars:+def_vi_chars2']','@rh');
         continue;
      }
      p=point();col=p_col;
      status=search(paragraph_re'|'END_OF_SENTENCE_RE,'@rh');
      if( status ) {
         bottom();left();
         break;
      }
      _str line=_expand_tabsc();
      if( (p!=point() || p_col>col) ) {
         if( substr(line,p_col)=='' ) {
            if ( !down() ) _begin_line();
         } else {
            // Put cursor on first VALID character of the sentence
            status=search('[\od\p{L}\p{N}':+def_vi_chars:+def_vi_chars2']','@rh');
         }
      }
      if( status ) {
         bottom();left();
         break;
      }
   }
   // Clear possible "String not found" message
   clear_message();
   if( status && count==1 ) {
      if( p==point() && col==p_col ) {
         vi_message('Can''t move past end of file');
      }
      return(status);
   }

   return(0);
}

/**
 * By default this command handles '{' pressed.
 */
_command int vi_prev_paragraph(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless paragraph_chars=def_vi_or_ex_paragraphs;
   if( paragraph_chars=='' ) {
      // This is from 'ex.sh'
      paragraph_chars=VI_DEFAULT_PARAGRAPHS;
   }
   paragraph_re := '(^['paragraph_chars']*$)';
   skip_paragraphs_re := '^~(['paragraph_chars']*$)';
   // Save the current seek position so we can tell if we have
   // moved at all.
   typeless spos=_nrseek();

   typeless col=0;
   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      col=p_col;
      _first_non_blank();
      if( col<=p_col ) {
         up();
      }
      _begin_line();
      // Skip paragraph separator lines
      search(skip_paragraphs_re,'@rh-');
      // Search for paragraph separator line
      status=search(paragraph_re,'@rh-');
      if( status ) {
         top();
         // Have we moved at all?
         if( spos!=_nrseek() ) {
            status=0;
         }
         break;
      } else {
         _begin_line();
      }
   }
   clear_message();
   if( status && count==1 ) {
      vi_message('Can''t move past beginning of file');
      return(status);
   }

   return(0);
}

/**
 * By default this command handles '}' pressed.
 */
_command int vi_next_paragraph(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless paragraph_chars=def_vi_or_ex_paragraphs;
   if( paragraph_chars=='' ) {
      // This is from 'ex.sh'
      paragraph_chars=VI_DEFAULT_PARAGRAPHS;
   }
   paragraph_re := '(^['paragraph_chars']*$)';
   skip_paragraphs_re := '^~(['paragraph_chars']*$)';
   // Save the current seek position so we can tell if we have
   // moved at all.
   typeless spos=_nrseek();

   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      _begin_line();
      // Skip paragraph separator lines
      search(skip_paragraphs_re,'@rh');
      // Search for paragraph separator line
      status=search(paragraph_re,'@rh');
      if( status ) {
         bottom();left();
         // Have we moved at all?
         if( spos!=_nrseek() ) {
            status=0;
         }
         break;
      }
   }
   clear_message();
   if( status && count==1 ) {
      vi_message('Can''t move past end of file');
      return(status);
   }

   return(0);
}

/**
 * By default this command handles the '[' pressed.
 * 
 * @return 
 */
_command int vi_open_bracket_cmd(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_MARK)
{
   static _str key;
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key=vi_get_event();
   }


   // Are we in visual mode with a selection?
   vis := false;
   if (vi_get_vi_mode() :== 'V' && select_active()) {
      vis = true;
   }

   status := 1;
   switch (event2name(key)){
   case '[':
      status = vi_prev_section(count);
      break;
   case 'p':
      if (!vis) {
         status = vi_put_before_adjust_indent();
      }
      break;
   case '{':
      status = vi_find_enclosing_bracket('{', '-', count);
      break;
   case '(':
      status = vi_find_enclosing_bracket('(', '-', count);
      break;
   }

   if (status == 0 && vis) {
      vi_visual_select(/*1*/);
   }

   return(0);
}

/**
 * Find enclosing '{', '(', '[', ']', '}' or ')'.
 */
int vi_find_enclosing_bracket(_str c, _str dir, int count){
   int i;
   cur_line := p_line;
   cur_col := p_col;
   typeless p1;
   save_pos(p1);
   success := false;
   bool color_option_set=false;
   _str color_options='';
   for (i = 0; i < count; i++) {
      done := false;
      success = false;
      while (!done) {
         orig_line := p_line; 
         orig_col := p_col;
         int status;
         if (color_option_set) {
            status = search(c, dir'@');
            if (!status) {
               cfg:=_clex_find(0,'g');
               color_option_set=true;
               if (cfg==CFG_STRING) {
               } else if (cfg==CFG_COMMENT) {
               } else {
                  // This if matches the code in find_matching_paren().
                  // Not sure why PL/I has special case code in find_matching_paren()
                  // but this code needs to match it.
                  if (p_lexer_name != 'PL/I') {
                     color_options='xcs';
                  }
               }
            }
         } else {
            status = search(c, dir'@X'color_options);
         }
         if (status != 0) {
            done = true;
            success = false;
            restore_pos(p1);
            break;
         }
         if (p_line != orig_line || p_col != orig_col) {
            save_pos(auto p);
            status = find_matching_paren();
            if (status != 0 || (dir :== '-' && (p_line > cur_line || ( p_line == cur_line && p_col > cur_col))) || 
                (dir :== '+' && (p_line < cur_line || (p_line == cur_line && p_col < cur_col)))) {
               done = true;
               success=true;
               restore_pos(p);
            } else {
               restore_pos(p);
               vi_maybe_move_cursor(dir);
            }
         } else {
            vi_maybe_move_cursor(dir);
         }
      }
      if (!success) {
         break;
      } else {
         if (i + 1 < count) {
            vi_maybe_move_cursor(dir);
         }
      }
   }
   return(0);      
}
/**
 * Find quoted string inside cursor
 */
int vi_visual_select_quoted_string(_str c, int count,bool include_quotes){
   int status;
   save_pos(auto p);
   // Does this language have color coding?
   bool use_color_coding=false;
   if (p_lexer_name!='') {
      // If we are in a string
      if (_clex_find(0,'g')==CFG_STRING) {
         use_color_coding=true;
         // Find the beginning of the string
         status=_clex_find(STRING_CLEXFLAG,'-N');
         if (status || p_line==0) {
            top();
         } else {
            if (p_col<_text_colc(0,'L')) {
               right();
            } else {
               down();_begin_line();
            }
         }
         ch:=get_text();
         if (ch:==c || ch=="'" || ch=='"' || ch=='`') {
            c=ch;
         } else {
            // This is a less common string.
            // For now, just guess and leave 1 byte on each side.
            //include_quotes=true;
         }
      }
   }
   if (!use_color_coding) {
      status=search(c'|^','@r-');
      if (status || match_length()==0) {
         // We didn't find the start quote
         // Try forward direction.
         status=search(c'|$','@r');
         if (status || match_length()==0) {
            restore_pos(p);
            return 1;
         }
      }
   }
   typeless p1;
   save_pos(p1);
   start_col:=p_col;
   start_line:=p_line;
   right();
   if (!include_quotes) {
      save_pos(p1);
      start_col=p_col;
      start_line=p_line;
   }
   if (use_color_coding) {
      // find the end quoted using color coding
      status=_clex_find(STRING_CLEXFLAG,'N');
      if (status) {
         bottom();
      }
      if (_clex_find(0,'g')==CFG_STRING) {
         // This is an unterminated string
         include_quotes=true;
      } else {
         while (_clex_find(0,'g')!=CFG_STRING && p_line!=0) {
            if (p_col==1) {
               up();_end_line();
               // IF the new line character is string color
               if (_clex_find(0,'g')==CFG_STRING) {
                  // This is an unterminated string
                  include_quotes=true;
               }
               left();
            } else {
               left();
            }
         }
      }
   } else {
      // find the end quoted
      status=search(c'|$','@r');
      if (status || match_length()==0) {
         restore_pos(p);
         return 1;
      }
   }
   if (include_quotes) {
      right();
   } else {
      if (p_col==start_col && p_line==start_line) {
         return 1;
      }
   }
   save_pos(auto p2);
   restore_pos(p1);
   type:=_select_type();
   deselect();
   vi_visual_select(type);
   restore_pos(p2);
   left();
   // found start quote
   return(0);      
}

/**
 * Used for moving the cursor when using vi_open_bracket_cmd and 
 * vi_closed_bracket_cmd. 
 *  
 * @param dir 
 */
static void vi_maybe_move_cursor(_str dir){
   if (dir :== '-') {
      if (p_col == 1) {
         up();
         end_line();
      } else {
         left();
      }
   } else if (dir :== '+') {
      if (at_end_of_line()) {
         down();
         begin_line();
      } else {
         right();
      }
   }
}
/**                
 * This command performs exactly as vi_put_after_cursor, 
 * only it will adjust the indent of the paste to the indent 
 * of the current line.
 * 
 * @return 
 */
_command int vi_put_after_adjust_indent() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   vi_put_after_cursor();
   if (_on_line0()) {
      return(0);
   }
   int cur_non_blank_col = _first_non_blank_col();
   up();
   int prev_non_blank_col = _first_non_blank_col();
   save_pos(auto p);
   vi_begin_line();
   _str prev_indent = get_text(_text_colc(prev_non_blank_col,'p')-1);
   restore_pos(p);
   down();
   vi_begin_line();
   _delete_text(cur_non_blank_col-1,'C');
   _insert_text(prev_indent);
   return(0);
}

/**
 * By default this command handles the ']' pressed.
 * 
 * @return 
 */
_command int vi_closed_bracket_cmd(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_MARK)
{
   static _str key;
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key=vi_get_event();
   }

   // Are we in visual mode with a selection?
   vis := false;
   if (vi_get_vi_mode() :== 'V' && select_active()) {
      vis = true;
   }

   status := 1;
   switch(event2name(key)){
   case ']':
      status = vi_next_section(count);
      break;
   case 'p':
      if (!vis) {
         status = vi_put_after_adjust_indent();
      }
      break;
   case '}':
      status = vi_find_enclosing_bracket('}', '+', count);
      break;
   case ')':
      status = vi_find_enclosing_bracket(')', '+', count);
      break;
   }
   
   if (status == 0 && vis) {
      vi_visual_select(/*1*/);
   }

   return(0);
}

/**                
 * This command performs exactly as vi_put_before_cursor, 
 * only it will adjust the indent of the paste to the indent 
 * of the current line.
 * 
 * @return 
 */
_command int vi_put_before_adjust_indent() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   vi_put_before_cursor();
   up();
   int cur_non_blank_col = _first_non_blank_col();
   down();
   int prev_non_blank_col = _first_non_blank_col();
   save_pos(auto p);
   vi_begin_line();
   _str prev_indent = get_text(_text_colc(prev_non_blank_col,'p')-1);
   restore_pos(p);
   up();
   vi_begin_line();
   _delete_text(cur_non_blank_col-1,'C');
   _insert_text(prev_indent);

   return(0);
}

/**
 * This command handles '[[' pressed.
 * <P>
 * Note: If you rebind this command to another key,
 * then you must hit that key twice for the desired
 * effect.
 */
_command int vi_prev_section(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   /*key1=last_event();
   key2=vi_get_event();
   if( vi_name_on_key(key1)!=vi_name_on_key(key2) ) {
      return(1);
   }*/

   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   typeless p=point();
   typeless col=p_col;
   status=search('^['def_vi_or_ex_sections']','@rh-');
   if( !status && p==point() && col==p_col ) {
      status=repeat_search();
   }
   int i;
   for( i=1;i<=(count-1);++i ) {
      if( status ) break;
      status=repeat_search();
   }
   clear_message();
   if( status ) {
      top();
      if( count==1 && (p==point() && col==p_col) ) {
         vi_message('Can''t move past beginning of file');
         return(status);
      }
   }

   return(0);
}

/**
 * This command handles ']]' pressed.
 * <P>
 * Note: If you rebind this command to another key,
 * then you must hit that key twice for the desired
 * effect.
 */
_command int vi_next_section(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');
   /*key1=last_event();
   key2=vi_get_event();*/
   /*if( vi_name_on_key(key1)!=vi_name_on_key(key2) ) {
      return(1);
   }*/
   if( count=='' || count<1 ) {
      count=1;
   }
   typeless status=0;
   typeless p=point();
   typeless col=p_col;
   status=search('^['def_vi_or_ex_sections']','@rh');
   if( !status && p==point() && col==p_col ) {
      status=repeat_search();
   }
   int i;
   for( i=1;i<=(count-1);++i ) {
      if( status ) break
      status=repeat_search();
   }
   clear_message();
   if( status ) {
      bottom();left();
      if( count==1 && (p==point() && col==p_col) ) {
         vi_message('Can''t move past end of file');
         return(status);
      }
   }

   return(0);
}

/**
 * By default this command handles '%' pressed.
 */
_command int vi_find_matching_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|
   VSARG2_MARK)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   typeless status=_find_matching_paren(0x7fffffff);
   if( status ) {
      // Must find the first paren/bracket/brace on the current line
      _str line=_expand_tabsc();
      int p=pos('\(|\)|\[|\]|\{|\}',line,p_col,'r');
      if( p ) {
         /* Put cursor on the paren/bracket/brace */
         p_col=p;
         _find_matching_paren(def_pmatch_max_diff_ksize);
      } else {
         vi_message('Not on paren/bracket/brace pair');
         return(1);
      }
   }
   clear_message();
   vi_visual_select();

   return(0);
}

/**
 * By default this command handles 'H' pressed.
 */
_command int vi_top_of_window(typeless offset=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   
   if( offset=='' || offset<1 ) {
      offset=1;
   }
   int pixel_offset=offset*p_font_height;

   typeless status=0;
   // Starting line number
   start_lineno := p_line;
   // Save the old scroll position
   old_cursor_y := p_cursor_y;

   // Save the old previous context
   typeless old_prev_context=vi_get_prev_context();
   // Set the previous context
   vi_set_prev_context();

   line_cursor_y := 0;
   if( offset>p_char_height ) {
      line_cursor_y=p_cursor_y intdiv p_font_height;
      status=down(offset-line_cursor_y-1);
   } else {
      p_cursor_y=pixel_offset-p_font_height;
   }
   if( status ) {
      // 'offset' was too large
      p_line=start_lineno;
      set_scroll_pos(p_left_edge,old_cursor_y);
      // Set it back to original state
      vi_set_prev_context(old_prev_context);
      vi_message('Can''t move past end of file');
      return(1);
   }
   // Call _first_non_blank_col() instead of first_non_blank() in case
   // the scrolling is set to something other than 0.
   p_col=_first_non_blank_col();

   return(0);
}

/**
 * By default this command handles 'M' pressed.
 */
_command vi_middle_of_window() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // DO NOT CARE ABOUT THE OFFSET FOR THIS COMMAND

   // Starting line number
   start_lineno := p_line;
   // Save the old scroll position
   old_cursor_y := p_cursor_y;

   // Set the previous context
   vi_set_prev_context();

   p_cursor_y=(p_client_height intdiv 2)-1;
   // Call _first_non_blank_col() instead of first_non_blank() in case
   // the scrolling is set to something other than 0.
   p_col=_first_non_blank_col();

   return(0);
}

/**
 * By default this command handles 'L' pressed.
 */
_command int vi_bottom_of_window(typeless offset=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   
   if( offset=='' || offset<1 ) {
      offset=1;
   }
   int pixel_offset=offset*p_font_height;

   // Starting line number
   start_lineno := p_line;
   // Save the old scroll position
   old_cursor_y := p_cursor_y;

   // Save the old previous context
   typeless old_prev_context=vi_get_prev_context();
   // Set up the previous context
   vi_set_prev_context();

   line_cursor_y := 0;
   if( offset>p_char_height ) {
      line_cursor_y=p_cursor_y intdiv p_font_height;
      up(offset-(p_char_height-(line_cursor_y+1)+1));
   } else {
      p_cursor_y=(p_client_height-pixel_offset+1)-1;
   }
   if( p_line==0 ) {
      // 'offset' was too large
      p_line=start_lineno;
      set_scroll_pos(p_left_edge,old_cursor_y);
      vi_set_prev_context(old_prev_context);
      vi_message('Can''t move past beginning of file');
      return(1);
   }
   // Call _first_non_blank_col() instead of first_non_blank() in case
   // the scrolling is set to something other than 0.
   p_col=_first_non_blank_col();

   return(0);
}

/**
 * This procedure handles "'",'`' pressed in command mode.
 * <P>
 * Note: arg2!='' specifies the cursor be put on the first non-blank of
 * the line containing the mark.
 */
int vi_goto_mark(_str name, _str arg2="")
{
   int orig_buf_id=p_buf_id;   // 11/24/1997 - Need this so can restore in the case of an editor control

   typeless status=0;
   if( name=='' ) {
      status=vi_goto_prev_context();
   } else {
      if (isEclipsePlugin()) {
         if (substr(name,1,length("Bookmark:"))!="Bookmark:")  {
            // Eclipse requires this specific format for a bookmark name
            name = "Bookmark: '"upcase(name)"'";
         }
         status=goto_bookmark(name);
      } else {
         status=goto_bookmark(name);
      }
   }

   if( !p_mdi_child && p_buf_id!=orig_buf_id ) {
      p_buf_id=orig_buf_id;
      vi_message('Not allowed to switch buffers in an editor control');
      return(0);
   }

   if( status>=0 && strip(arg2)!='' ) {
      // Go to the beginning of the line of the previous context
      _first_non_blank();
   }
   
   // goto_bookmark now returns >=0 as success
   if (status >= 0){ 
      return 0;
   } else {
      return(status);
   }
}

/**
 * By default this command handles '\'' pressed.
 * <P>
 * Case "''":
 * <BR>
 * A little more explanation: This command puts the cursor on the line
 * where the last "non-relative" cursor motion occurred.  "Non-relative"
 * means the last cursor motion that was not relative to any previous
 * cursor motion.  Examples of "non-relative" cursor motion is use of
 * the following commands:  'G', 'H', 'M', 'L'.  An example of a "relative"
 * cursor motion is 'C-F', it pages forward relative to the current line.
 * <P>
 * Case "'letter":
 * <BR>
 * A little more explanation:  If "'" is followed by "letter", then "letter"
 * represents a mark id to goto.
 */
_command int vi_to_mark_line(typeless count=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   _str key1=last_event();
   _str key2=vi_get_event();
   if( isinteger(count) && count!=1 ) {
      // Count not allowed
      vi_message('No count allowed');
      return(1);
   }
   if( vi_name_on_key(key1)==vi_name_on_key(key2) ) {
      // Go to the beginning of the line of the previous context
      return(vi_goto_mark('','1'));
   } else if( length(key2):==1 && isalpha(key2) ) {
      if (isEclipsePlugin()) {
         key2 = "Bookmark: '"upcase(key2)"'";
         return(vi_goto_mark(key2,'1'));
      }
      return(vi_goto_mark(key2,'1'));
   } else if (key2 :== '.') {
      return(undo_cursor());
   } else {
      vi_message('Invalid key sequence');
      return(1);
   }
}

/**
 * By default this command handles '`' pressed.
 * <P>
 * Case "``":
 * <BR>
 * A little more explanation:  This command puts the cursor on the line
 * and column where the last "non-relative" cursor motion occurred.
 * "Non-relative" means the last cursor motion that was not relative to
 * any previous cursor motion.  Examples of "non-relative" cursor motion
 * is use of the following commands:  'G', 'H', 'M', 'L'.  An example of
 * a "relative" cursor motion is 'C-D', it pages forward relative to the
 * current line.
 * <P>
 * Case "`letter":
 * <BR>
 * A little more explanation:  If "`" is followed by "letter", then "letter"
 * represents a mark id to goto.
 */
_command int vi_to_mark_col(typeless count=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');
   _str key1=last_event();
   _str key2=vi_get_event();
   if( isinteger(count) && count!=1 ) {
      // Count not allowed
      vi_message('No count allowed');
      return(1);
   }
   if( vi_name_on_key(key1)==vi_name_on_key(key2) ) {
      // Go to the previous context
      return(vi_goto_mark(''));
   } else if( length(key2):==1 && isalpha(key2) ) {
      if (isEclipsePlugin()) {
         key2 = "Bookmark: '"upcase(key2)"'";
         return(vi_goto_mark(key2));
      }
      return(vi_goto_mark(key2));
   } else {
      vi_message('Invalid key sequence');
      return(1);
   }
}

/**
 * By default this command handles the '*' pressed. 
 *  
 * @param count
 * 
 * @return int
 */
_command int vi_quick_search(typeless count = 1) name_info(','VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK) {
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==ENTER && p_window_id==_cmdline ) {
         command_execute();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if (!isinteger(count)) {
      vi_message('Invalid key sequence');
      return(1);
   }
   _vi_visual_auto_deselect();
   int num_search = (int)count;
   i := 0;

   mark := -1;
   if (vi_get_vi_mode() == 'V') {
      save_selection(mark);
   }

   while (i < count) {
      orig_col := p_col;
      orig_line := p_line;
      vi_set_prev_context();
      int status = quick_search('<');
      if (orig_col == p_col && orig_line == p_line && !status) {
         vi_end_word();
         quick_search('<');
      }
      i++;
   }

   if (mark != -1) {
      restore_selection(mark);
      vi_visual_select();
   }

   return(0);
}

/**
 * By default this command handles the '#' pressed. 
 *  
 * @param count
 * 
 * @return int
 */
_command int vi_quick_reverse_search(typeless count = 1) name_info(','VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK) {
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==ENTER && p_window_id==_cmdline ) {
         command_execute();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if (!isinteger(count)) {
      vi_message('Invalid key sequence');
      return(1);
   }
   _vi_visual_auto_deselect();
   int num_search = (int)count;

   mark := -1;
   if (vi_get_vi_mode() == 'V') {
      save_selection(mark);
      deselect();
   }

   i := 0;
   while (i < count) {
      vi_set_prev_context();
      quick_reverse_search();
      i++;
   }

   if (mark != -1) {
      restore_selection(mark);
      vi_visual_select();
   }

   return(0);
}

// This procedure handles 'C-U' and 'C-D' in command mode.
static int vi_scroll(_str direction_option, typeless scroll_amount="")
{
   if( isinteger(scroll_amount) && scroll_amount>0 ) {
      // This is an amount to save for future scrolling
      def_vi_or_ex_scroll=scroll_amount;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if( isinteger(def_vi_or_ex_scroll) && def_vi_or_ex_scroll>0 ) {
      scroll_amount=def_vi_or_ex_scroll;
   } else {
      scroll_amount=ex_client_height() intdiv 2;
   }
   typeless status=0;
   save_cursor_y := p_cursor_y;
   if( direction_option=='-' ) {
      status=down(scroll_amount);
   } else {
      status=up(scroll_amount);
   }
   if( status || p_line==0 ) {
      // Probably near top/bottom of file or jumped up to line 0
      if( direction_option=='-' ) {
         bottom();
      } else {
         p_line=1;
      }
   }
   // Put cursor at beginning of line, not column 1
   _first_non_blank();
   set_scroll_pos(p_left_edge,save_cursor_y);
   refresh();

   return(0);
}

/**
 * By default this command handles 'C-U' pressed.
 */
_command int vi_scroll_up(typeless scroll_amount="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_scroll('',scroll_amount);

   return(0);
}

/**
 * By default this command handles 'C-D' pressed.
 */
_command int vi_scroll_down(typeless scroll_amount="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_scroll('-',scroll_amount);

   return(0);
}

// This procedure handles 'C-F' and 'C-B' in command mode.
static int vi_page_up_down(_str direction_option, typeless count=1)
{
   if( count=='' || count<1 ) {
      count=1;
   }

   save_pos(auto p);
   typeless s=_nrseek();

   typeless status=0;
   int i;
   for( i=1;i<=count;++i ) {
      if( direction_option=='-' ) {
         status=_page_down();
      } else {
         status=_page_up();
      }
      if( status ) break;
   }
   if( status && i<=count && s:==_nrseek() ) {
      restore_pos(p);
      return(status);
   }
   vi_visual_select();

   return(0);
}

/**
 * By default this command handles 'C-F' pressed.
 */
_command int vi_page_down(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   typeless status=vi_page_up_down('-',count);
   if( status ) {
      // We did not move
      vi_message('Can''t move past end of file');
   }

   return(status);
}

/**
 * By default this command handles 'C-B' pressed.
 */
_command int vi_page_up(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   typeless status=vi_page_up_down('',count);
   if( status ) {
      vi_message('Can''t move past beginning of file');
   }

   return(status);
}

/**
 * This procedure handles 'C-E' and 'C-Y' in command mode.
 * <P>
 * Scrolls the current line up/down in the client window by count lines.
 */
static int vi_scroll_window(_str direction_option, typeless count=1)
{
   if( !isinteger(count) || count<1 ) {
      count=1;
   }
   cursor_y := p_cursor_y;
   // If trying to scroll window beyond client area.
   // Allow ridiculous counts for this, otherwise would
   // have to check the number of lines in the file AND
   // because down() and up() gracefully handle counts
   // that are larger than the number of lines in file.
   updown_count := 0;

   int save_cursor_y=cursor_y;
   if( direction_option=='-' ) {
      // 'C-E'
      cursor_y-=count*p_font_height;

      // Special case of scrolling the line up AND the current line is
      // already butted up against the top of the window.
      if( cursor_y<0 ) {
         updown_count=(-cursor_y) intdiv p_font_height;
         cursor_y=0;
      }
   } else {
      // 'C-Y'
      int lines_to_top= (cursor_y intdiv p_font_height) + 1;
      if( lines_to_top>=p_line ) {
         return(0);
      }
      cursor_y+=count*p_font_height;

      int line_height=p_char_height*p_font_height;
      // Subtract out the "Top of File" line only if it is scrolled into view
      if( p_line<=p_char_height && _default_option('T') ) line_height-=p_font_height;

      // Special case of scrolling the line down AND the current line is
      // already butted up against the bottom of the window.
      if( cursor_y>=line_height ) {
         updown_count= ((cursor_y-line_height) intdiv p_font_height) + 1;
         cursor_y=p_client_height;
      }
   }

   // The line is already butted up against the top/bottom of the client
   // window, so adjust the current line down/up.
   if( updown_count ) {
      if( direction_option=='-' ) {
         down(updown_count);
      } else {
         up(updown_count);
      }
   }

   set_scroll_pos(p_left_edge,cursor_y);

   // Check to be sure we are *not* somewhere in virtual space
   if( p_col>_text_colc() ) {
      p_col=_text_colc();
   }

   refresh();

   return(0);
}

/**
 * By default this command handles 'C-E' pressed.
 */
_command int vi_scroll_window_up(typeless count=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_MARK)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_scroll_window('-',count));
}

/**
 * By default this command handles 'C-Y' pressed.
 */
_command int vi_scroll_window_down(typeless count=1) name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_MARK)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_scroll_window('',count));
}

/**
 * By default this command handles 'C-G' pressed.
 */
_command int vi_status() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   percent := 0;
   if( p_line==0 ) {
      percent=0;
   } else {
      percent=(p_line*100)  intdiv  p_noflines;
   }
   vi_message('"'p_buf_name'" line 'p_line' of 'p_noflines' --'percent'%--');

   return(0);
}

/**
 * By default this command handles 'z' pressed.
 */
_command int vi_zero_line(typeless lineno="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( lineno=='' || lineno<1 ) {
      lineno=p_line;
   }
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   p_line=lineno;
   key=vi_get_event();
   key=event2name(key);
   new_y := 0;
   if( key=='ENTER' || key=='t') {
      new_y=0;
   } else if( key=='.' || key=='z') {
      new_y=(p_client_height intdiv 2)-1;
   } else if( key=='-' || key=='b') {
      new_y=p_client_height;
   } else {
      vi_message('Invalid key pressed');
      return(1);
   }
   set_scroll_pos(p_left_edge,new_y);

   return(0);
}

/**
 * By default this command handles 'C-L' pressed.
 */
_command int vi_redraw() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( p_mdi_child ) clear_message();

   return(0);
}

/**
 * By default this command handles 'i' pressed.
 */
_command int vi_insert_mode(_str cb_name="", typeless insertAtBeginLine="", typeless insertAtFirstCol="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   insert_at_begin_line := (insertAtBeginLine!='' && insertAtBeginLine!=0);
   insert_at_first_col := (insertAtFirstCol!='' && insertAtFirstCol!=0);

   if (insert_at_begin_line && insert_at_first_col) {
      vi_message('Invalid options passed to vi_insert_mode.');
      return 1;
   }

   callback_idx := find_index('vi_escape',COMMAND_TYPE);
   lstidx := last_index();
   // This is kind of a hack, but it is the best way to do this.  The 'gI' command starts an 
   // insertion and thus should be supported by the '.' command for repeating insertions and
   // deletions.  But we can't add 'vi-maybe-text-motion' to PLAYBACK_CMDS because that will 
   // reset the last insertion/deletion everytime you do a 'g' command, even if it's not 'gI'.
   // 
   // This fakes the last command so that everything works properly. 
   if (insert_at_first_col) {
      lstidx = find_index('vi-first-col-insert-mode', COMMAND_TYPE);
   }
   // insertAtBeginLine is '' because we do not want to save the last keystroke
   // into the keyboard macro.
   vi_repeat_info(lstidx,'',cb_name,'',callback_idx);

   if (!_MultiCursorAlreadyLooping() || vi_get_vi_mode()!='I') {
      // Reset the mode keytable pointer
      typeless status=vi_switch_mode('I');
      if( status ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         return(status);
      }
   }

   if (insert_at_begin_line) {
      // Insert at beginning of line at first nonblank character
      _first_non_blank();
   } else if (insert_at_first_col) {
      // Insert at column 1 
      _begin_line();
   }
   // Save the beginning line and column of the insertion
   _vi_insertion_pos= p_line' 'p_col;

   return(0);
}

/**
 * By default this command handles 'I' pressed.
 */
_command int vi_begin_line_insert_mode(_str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return(vi_insert_mode(cb_name,'1'));
}

_command int vi_first_col_insert_mode(_str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return(vi_insert_mode(cb_name,'','1'));
}

/**
 * By default this command handles 'a' pressed.
 */
_command int vi_append_mode(_str cb_name="", _str appendAtEndLine="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   callback_idx := find_index('vi_escape',COMMAND_TYPE);
   // appendAtEndLine is '' because we do not want to save the last keystroke
   // into the keyboard macro.
   vi_repeat_info(last_index(),'',cb_name,'',callback_idx);

   if (_MultiCursorLastLoopIteration()) {
      // Reset the mode keytable pointer
      typeless status=vi_switch_mode('I');
      if( status ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         return(status);
      }
   }

   append_at_end_line := (appendAtEndLine!='' && appendAtEndLine!=0);
   if( !append_at_end_line ) {
      // Append after cursor
      right();
   } else {
      // Append at end of current line
      vi_end_line();
      if( _line_length() ) right();
   }
   // Save the beginning line and column of the insertion
   _vi_insertion_pos= p_line' 'p_col;

   return(0);
}

/**
 * By default this command handles 'A' pressed.
 */
_command int vi_end_line_append_mode(_str cb_name='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return(vi_append_mode(cb_name,'1'));
}

/**
 * By default this command handles 'o' pressed.
 */
_command int vi_newline_mode(_str cb_name="", typeless newlineAbove="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   callback_idx := find_index('vi_escape',COMMAND_TYPE);
   // newlineAbove is '' because we do not want to save the last keystroke
   // into the keyboard macro.
   vi_repeat_info(last_index(),'',cb_name,'',callback_idx);

   if (_MultiCursorLastLoopIteration()) {
      // Reset the mode keytable pointer
      typeless status=vi_switch_mode('I');
      if( status ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         return(status);
      }
   }

   newline_above := (newlineAbove!=0 && newlineAbove!='');
   if( newline_above ) {
      // Start a newline above the current line
      _first_non_blank();
      up();
   }

   _TruncEndLine();
   _str old_lkey=last_event();


   last_event(ENTER);
   nosplit_insert_line();
   last_event(old_lkey);
   defCol := p_col;

   // This is useful when in the middle of a for( ;; ) statement
   rc := get_smart_tab_column();

   if (rc <= 0) {
      p_col = defCol;
   } else {
      p_col = rc;
   }

   if (_MultiCursorActiveLoopIteration()) {
      // Save the beginning line and column of the insertion
      _vi_insertion_pos= p_line' 'p_col;
   }

   return(0);
}

/**
 * By default this command handles 'O' pressed.
 */
_command int vi_above_newline_mode(_str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return(vi_newline_mode(cb_name,'1'));
}

/**
 * By default this command handles 'x' pressed.
 */
_command int vi_forward_delete_char(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else if( key:==DEL ) {
         _cmdline._delete_char();
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   if( count=='' || count<1 ) {
      count=1;
   }

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   if( !_line_length() ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Empty line');
      return(1);
   }
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_repeat_info('A');
      vi_message(get_message(mark));
      return(1);
   }
   //_undo('S');
   _select_char(mark,'P');
   int i;
   for( i=0;i<(count-1);++i ) {
      right();
      if( p_col>_text_colc() ) {
         _TruncEndLine();left();
         break;
      }
   }
   // One more right() because we are doing a non-inclusive character
   // selection
   right();
   _select_char(mark,'P');
   _begin_select(mark);
   _show_selection(mark);
   if (count==1) {
      // _delete_char does a better job of scrolling when softwrap with
      // breaking on word is on.
      vi_cut(true,cb_name,'');
      delete_char();
   } else {
      vi_cut(false,cb_name);
   }
   _show_selection(old_mark);
   _free_selection(mark);

   // Now make sure that the cursor is on a real character
   if( p_col>_text_colc() ) {
      vi_end_line();
   }

   this_idx := find_index('vi-forward-delete-char',COMMAND_TYPE);
   // Get the index which started the recording
   int repeat_idx=vi_repeat_info('X');
   if( repeat_idx && repeat_idx==this_idx ) {
      if( vi_repeat_info('I') ) {
         // End and save the currently recording keyboard macro
         vi_repeat_info('E');
      }
   }

   _undo('S');
   return(0);
}

/**
 * By default this command handles 'X' pressed.
 */
_command int vi_backward_delete_char(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   if( count=='' || count<1 ) {
      count=1;
   }
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   if( !_line_length() ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Empty line');
      return(1);
   }
   // This is physical column
   int col=_text_colc(p_col,'P');
   int len=col-1;
   if( len==0 ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Can''t go past beginning of line');
      return(1);
   }
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_repeat_info('A');
      vi_message(get_message(mark));
      return(1);
   }
   //_undo('S');
   save_pos(auto p);
   int i;
   for( i=0;i<count;++i ) {
      if( p_col==1 ) break;
      left();
   }
   _select_char(mark,'P');
   restore_pos(p);
   _select_char(mark,'P');
   _begin_select(mark);
   _show_selection(mark);
   vi_cut(false,cb_name);
   _show_selection(old_mark);
   _free_selection(mark);

   // Now make sure that the cursor is on a real character
   if( p_col>_text_colc() ) {
      vi_end_line();
   }

   this_idx := find_index('vi-backward-delete-char',COMMAND_TYPE);
   // Get the index which started the recording
   int repeat_idx=vi_repeat_info('X');
   if( repeat_idx && repeat_idx==this_idx ) {
      if( vi_repeat_info('I') ) {
         // End and save the currently recording keyboard macro
         vi_repeat_info('E');
      }
   }

   _undo('S');
   return(0);                 
}


/**
 * This command handles the &lt;NUMBER&gt;% command, which 
 * navigates to &lt;NUMBER&gt;% down the buffer.
 * 
 * @return 
 */
_command int vi_goto_percent(typeless percent="") name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   int line;
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if(!isinteger(percent)){
      vi_message("Malformed command.");
      return(1);
   }

   line = (p_noflines * percent) intdiv 100;
   vi_goto_line(line);
   return(0);
}

/**
 * By default this command handles Ctrl+W pressed, which may be followed
 * by a number of split window commands.
 * 
 * @return 
 */
_command int vi_maybe_split_cmd() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|
VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   key = vi_get_event();
   _str name = event2name(key);
   switch(name){
   case 's':
      hsplit_window();
      break;
   case 'v':
      vsplit_window();
      break;
   case ']':
      vi_split_to_tag();
      break;
   case 'f':
      vi_split_to_file();
      break;
   case 'n':
      vi_split_to_new();
      break;
   case 'o':
      maximize_window();
      break;
   case 'j':
      window_below();
      break;
   case 'k':
      window_above();
      break;
   case 'l':
      window_right();
      break;
   case 'h':
      window_left();
      break;
   case 't':     
      vi_split_to_top();
      break;
   case 'b':
      vi_split_to_bottom();
      break;
   case 'q':
      close_buffer();
      kill_window();
      break;
   case 'W':
      vi_split_above_wrap();
      break;
   case 'w':
      next_window();
      break;
   case 'C-W':
      vi_split_below_wrap();
      break;
   }

   return(0);
}

/**
 * This command moves focus to the window below the current window (wrap). 
 */
_command void vi_split_below_wrap() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY
|VSARG2_READ_ONLY)
{
   prev_id := p_window_id;
   window_below();
   cur_id := p_window_id;
   if(cur_id == prev_id){
      vi_split_to_top();
   }
}

/**
 * This command moves focus to the window above the current window (wrap).
 */
_command void vi_split_above_wrap() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY
|VSARG2_READ_ONLY)
{
   prev_id := p_window_id;
   window_above();
   cur_id := p_window_id;
   if(cur_id == prev_id){
      vi_split_to_bottom();
   }
}

/**
 *  This command moves focus to the bottom-most window.
 */
_command void vi_split_to_bottom() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY
|VSARG2_READ_ONLY)
{
   prev_id := p_window_id;
   window_below();
   cur_id := p_window_id;
   while(prev_id != cur_id){
      window_below();
      prev_id = cur_id;
      cur_id = p_window_id;
   }
}

/**
 * This command moves focus to the top-most window.
 */
_command void vi_split_to_top() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|
VSARG2_READ_ONLY)
{
   prev_id := p_window_id;
   window_above();
   cur_id := p_window_id;
   while(prev_id != cur_id){
      window_above();
      prev_id = cur_id;
      cur_id = p_window_id;
   }
}

/**
 * This command splits the current buffer with a new buffer.
 */
_command void vi_split_to_new() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY
|VSARG2_READ_ONLY)
{
   hsplit_window();
   edit('+t');
}

/**
 * This command splits the window and opens the file under the cursor in 
 * one of the windows.
 */
_command void vi_split_to_file() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY
|VSARG2_READ_ONLY)
{
   int x;
   _str old_word_chars = p_word_chars;
   word_chars(p_word_chars:+'./\\:');
   __ex_split(cur_word(x));
   word_chars(old_word_chars);
}

/**
 * This command splits the window and jumps to the tag of the symbol under the cursor
 * in one of the windows.
 */
_command void vi_split_to_tag() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|
VSARG2_READ_ONLY)
{
   hsplit_window();
   push_tag();
}


/**
 * By default this command handles the 'g' pressed.
 * 
 * @return 
 */
_command int vi_maybe_text_motion(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   typeless status=0;
   i := 0;
   static _str key;
   static _str lkey;
   _str name;

   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      lkey=last_event();
   }
   vi_repeat_info(last_index(),lkey,count,cb_name);

   int repeat_count=vi_repeat_info('C',count);

   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key = vi_get_event();
   }
   name = event2name(key);

   /*name=vi_name_eq_translate(vi_name_on_key(key));

   index=find_index(name,COMMAND_TYPE);
   if( index==0 || ! index_callable(index) ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Command "'name'" not found');
      return(1);
   }*/
   switch (name) {
   case 'g':
      vi_goto_line(repeat_count);
      vi_visual_select();
      break;
   case 'm':
      int old_y;
      old_y = p_cursor_y;
      _end_line();
      left();
      // If the end of the line is past the middle of the screen,
      // or if the line has wrapped and we are now on the line below,
      // we have to move to the middle.
      if((p_cursor_x > (p_client_width intdiv 2)-1 ) || (p_cursor_y > old_y)){
         p_cursor_x = (p_client_width intdiv 2)-1;
      }
      vi_visual_select();
      break;
   case 'P':
      old_col := p_col;
      vi_put_before_cursor();
      // 'gP' acts exactly like our 'P' unless you are copying a full line
      if(old_col == p_col){
         undo();
         vi_begin_line();
         vi_put_before_cursor();
      }
      break;
   case 'p':
      old_line := p_line;
      old_c := p_col;
      vi_put_after_cursor();
      // 'gp' acts exactly like our 'p' unless you are copying a full line
      if(old_c == p_col && old_line != p_line){
         vi_end_line();
      }
      break;
   case 'j':
      def_updown_screen_lines = true;
      vi_next_line(repeat_count);
      def_updown_screen_lines = false;
      vi_visual_select();
      break;
   case 'k':
      def_updown_screen_lines = true;
      vi_next_line(repeat_count, '-');
      def_updown_screen_lines = false;
      vi_visual_select();
      break;
   case 'e':
      for(i = 0; i < repeat_count; i++ ) {
         status=vi_skip_word('-','','E');
         if( status ) break;
      }
      if( status ) {
         top();
         if( repeat_count == 1 ) {
            vi_message('Can''t go past beginning of file');
            return(status);
         }
      }
      vi_visual_select();
      break;
   case 'E':
      for(i = 0; i < repeat_count; i++ ) {
         status=vi_skip_word('-','1','E');
         if( status ) break;
      }
      if( status ) {
         top();
         if( repeat_count == 1 ) {
            vi_message('Can''t go past beginning of file');
            return(status);
         }
      }
      vi_visual_select();
      break;
   case 'J':
      if (vi_get_vi_mode() == 'V') {
         _str num_lines = count_lines_in_selection();
         begin_select();
         for (i = 0; i < num_lines; i++) {
            join_line(false);
         }
         vi_visual_toggle_off();
      }
      break;
   case 'I':
      if (vi_get_vi_mode() == 'V') {
         vi_visual_begin_line();
      } else {
         vi_first_col_insert_mode(cb_name);
      }
      break;
   case '~':
   case 'u':
   case 'U':
      if (vi_get_vi_mode() == 'V') {
         if (name == 'u') {
            vi_visual_downcase();
         } else if (name == 'U') {
            vi_visual_upcase();
         } else {
            vi_visual_toggle_case();
         }
      } else {
         static _str key2;
         if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
            key2=vi_get_event();
         }
         _str name2=vi_name_eq_translate(vi_name_on_key(key2));

         index := find_index(name2,COMMAND_TYPE);
         if( index==0 || ! index_callable(index) ) {
            // Abort any keyboard macro currently recording
            vi_repeat_info('A');
            vi_message('Command "'name2'" not found');
            return(1);
         }

         // Special check for vi-goto-line - do not default the repeat-count to 1
         if( name2=='vi-goto-line' && (!isinteger(count) || count<1) ) {
            repeat_count=count;
         }
         is_intraline_cmd := ( vi_name_in_list(name2,INTRALINE_CMDS) || vi_name_in_list(name2,INTRALINE_CMDS2) || vi_name_in_list(name2,INTRALINE_CMDS3));
         is_search_cmd := ( vi_name_in_list(name2,SEARCH_CMDS) );
         if( is_intraline_cmd || is_search_cmd ) {

            // Check the special case of deleting to end of current word or next word
            inclusive_mark_override := false;
            if( vi_name_in_list(name2,'vi-end-word vi-end-word2') ) {
               inclusive_mark_override=true;
            }

            typeless mark=_alloc_selection();
            if( mark<0 ) {
               // Abort any keyboard macro currently recording
               vi_repeat_info('A');
               vi_message(get_message(mark));
               return(mark);
            }
            // This starts the appropriate mark-type depending on which command is
            // specified by 'name2'.
            intraline_mark(name2,mark,'',1);
            typeless p=_nrseek();

            // Save this in case a search command takes us to a mark in another buffer
            int buf_id=p_buf_id;

            /*
            * If we are recording a macro, delete the 'vi-get-event' line that was inserted before
            * we call the search command.  This is so that the search command can record the search string.
            */
            _str prev_line = _macro_get_line();
            if (_macro('s')) {
               _macro_delete_line();
            }

            status=call_index(repeat_count,index);

            // Now reinsert the 'vi-get-event', now that the search command should be all set.
            if (_macro('s')) {
               _macro_append(prev_line);
            }

            // Did a search command (i.e. vi-to-mark-col) take us to another buffer?
            if( is_search_cmd && buf_id!=p_buf_id ) {
               // Abort any keyboard macro currently recording
               vi_repeat_info('A');
               load_files('+bi 'buf_id);
               vi_message('Can''t toggle case across different buffers');
               _free_selection(mark);
               return(1);
            }

            if( status ) {
               if( p==_nrseek() && name2!='vi-cursor-right' ) {
                  // A possible error occurred in the command called
                  //
                  // Abort any keyboard macro currently recording
                  vi_repeat_info('A');
                  _free_selection(mark);
                  return(1);
               } else {
                  // Clear the message line if not serious error.
                  // A non-serious error would be calling vi-cursor-down
                  // more times than is valid, where the result is to
                  // simply put the cursor at the bottom of the file.
                  clear_message();
               }
            }

            status=(status || inclusive_mark_override);
            // This ends the appropriate mark-type depending on which command is
            // specified by 'name2'.
            intraline_mark(name2,mark,status,0);

            // There were no serious errors so far
            status=0;
            typeless old_mark=_duplicate_selection('');
            _show_selection(mark);
            if (name == 'u') {
               lowcase_selection();
            } else if (name == 'U') {
               upcase_selection();
            } else {
               togglecase_selection();
            }
            _show_selection(old_mark);
            _free_selection(mark);

         } else if ( name2=='vi-insert-mode' || name2=='vi-append-mode') {
            status=vi_mark_text_object(count==""?1:count,0,"",true,name2=='vi-append-mode'?1:0);
            begin_select();
            if (!status) {
               if (name == 'u') {
                  lowcase_selection();
               } else if (name == 'u') {
                  upcase_selection();
               } else {
                  togglecase_selection();
               }
               deselect();
               _vi_mode = 'C';
            }
         } /*else if( name2=='vi-count' ) {
            //TODO: Support this case
         } */else {
            vi_message('Invalid toggle case sequence');
            status=1;
         }
      }
      break;
   }
   
   return(0);
}
int vi_mark_text_object(int count=1, typeless &rp=0, typeless &mark="", bool leave_selected=false, int spaces=0)
{
   status := 0;
   done := true;
   typeless p = 0;
   typeless p1 = 0;
   static _str switchkey;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      switchkey=vi_get_event();
   }
   switch (switchkey) {
   case '{':
   case '}':
   case 'B':
      vi_find_enclosing_bracket('{', '-', count);
      done=false;
      break;
   case '(':
   case ')':
   case 'b':
      vi_find_enclosing_bracket('(', '-', count);
      done=false;
      break;
   case '[':
   case ']':
      vi_find_enclosing_bracket('[', '-', count);
      done=false;
      break;
   case '<':
   case '>':
      orig_def_pmatch_chars:=def_pmatch_chars;
      def_pmatch_chars='<>';
      vi_find_enclosing_bracket('<', '-', count);
      def_pmatch_chars=orig_def_pmatch_chars;
      done=false;
      break;
   case 'w':
      vi_toggle_char_visual(0);
      vi_visual_select_inner_word(0,spaces,count,'+');
      mark=_duplicate_selection();
      _select_type(mark,'P','EE');
      begin_select();
      save_pos(rp);
      if (!leave_selected) {
         vi_toggle_char_visual(0);
      }
      break;
   case 'W':
      vi_toggle_char_visual(0);
      vi_visual_select_inner_word(1,spaces,count,'+');
      mark=_duplicate_selection();
      _select_type(mark,'P','EE');
      begin_select();
      save_pos(rp);
      if (!leave_selected) {
         vi_toggle_char_visual(0);
      }
      break;
   case 's':
      if (spaces==1) {
         return 1;
      }
      vi_toggle_line_visual(0);
      vi_visual_select_inner_sentence(0,count,'+');
      mark=_duplicate_selection();
      _select_type(mark,'P','EE');
      begin_select();
      save_pos(rp);
      if (!leave_selected) {
         vi_toggle_line_visual(0);
      }
      break;
   case 'p':
      if (spaces==1) {
         return 1;
      }
      vi_toggle_line_visual(0);
      vi_visual_select_inner_paragraph(0,0,count,'+');
      mark=_duplicate_selection();
      _select_type(mark,'P','EE');
      begin_select();
      save_pos(rp);
      if (!leave_selected) {
         vi_toggle_line_visual(0);
      }
      break;
   case '"':
   case '''':
   case '`':
      vi_toggle_char_visual(0);
      status=vi_visual_select_quoted_string(switchkey,count,spaces!=0);
      if (status) {
         deselect();
         break;
      }
      mark=_duplicate_selection();
      _select_type(mark,'P','EE');
      begin_select();
      save_pos(rp);
      if (!leave_selected) {
         vi_toggle_char_visual(0);
      }
      break;
   default:
      status=1;
      break;
   }
   if (!done) {
      if (switchkey=='<' || switchkey=='>') {
         orig_def_pmatch_chars:=def_pmatch_chars;
         def_pmatch_chars='<>';
         vi_visual_finish_i_cmd(p,p1,spaces==1);
         def_pmatch_chars=orig_def_pmatch_chars;
      } else {
         vi_visual_finish_i_cmd(p,p1,spaces==1);
      }
      if (p && p1) {
         select_lines := false;
         // Move back to the original paren
         restore_pos(p);
         // Move off the paren
         if (!spaces) {
            right();
         }
         // If we are at the end of the line, the selection should start on the next
         // line down because the paren shouldn't be included in the selection
         start_line := -1;
         if (at_end_of_line() && !spaces) {
            down();
            begin_line();
            // track start_line here...we might need to use _select_line
            start_line=p_line;
         }
         save_pos(rp);
         if (start_line > -1) {
            restore_pos(p1);
            // at the other end of the selection, if we on a different line and 
            // at the end of the line, we want to use _select_line
            if (p_line > start_line && at_end_of_line()) {
               select_lines=true;
            }
            restore_pos(rp);
         }
         if (select_lines) {
            _select_line(mark,'CP');
         } else {
            _select_char(mark,'CIP');
         }
         restore_pos(p1);
         if (select_lines) {
            _select_line(mark,'CP');
         } else {
            _select_char(mark,'CIP');
            if (!spaces) {
               vi_cursor_left();
            }
         }
      }
   }
   return status;
}
/**
 * By default this command handles 'd' pressed.
 * <P> cb_name is not '' when called by vi-count.
 */
_command int vi_delete(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   int repeat_count=vi_repeat_info('C',count);

   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   static _str key1;
   static _str key2;

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key1=last_event();
      key2=vi_get_event();
   }

   _str name=vi_name_eq_translate(vi_name_on_key(key2));

   index := find_index(name,COMMAND_TYPE);
   if( index==0 || ! index_callable(index) ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Command "'name'" not found');
      return(1);
   }

   // Special check for vi-goto-line - do not default the repeat-count to 1
   if( name=='vi-goto-line' && (!isinteger(count) || count<1) ) {
      repeat_count=count;
   }
   typeless status=0;
   is_intraline_cmd := ( vi_name_in_list(name,INTRALINE_CMDS) || vi_name_in_list(name,INTRALINE_CMDS2) || vi_name_in_list(name,INTRALINE_CMDS3));
   is_search_cmd := ( vi_name_in_list(name,SEARCH_CMDS) );
   if( vi_name_eq_translate(vi_name_on_key(key1)):==name ) {
      // This is the equivalent of a 'dd' pressed in vi
      typeless mark=_alloc_selection();
      if( mark<0 ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         vi_message(get_message(mark));
         return(mark);
      }
      _select_line(mark,'P');
      save_pos(auto p);
      status=down(repeat_count-1);
      if( status ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         restore_pos(p);
         vi_message('Invalid count');
         return(status);
      }
      _select_line(mark,'P');
      // Now move the marked area to the clipboard
      typeless old_mark=_duplicate_selection('');
      _show_selection(mark);
      if( vi_cut(false,cb_name,1) ) {
         // Something happened when trying to move the mark to the clipboard
         status=1;
      }
      _show_selection(old_mark);
      _free_selection(mark);

      // Now make sure the cursor is on a real character
      if( p_col>_text_colc() ) {
         p_col=_text_colc();
      }
   } else if( is_intraline_cmd || is_search_cmd ) {

      // Check the special case of deleting to end of current word or next word
      inclusive_mark_override := false;
      if( vi_name_in_list(name,'vi-end-word vi-end-word2') ) {
         inclusive_mark_override=true;
      }

      typeless mark=_alloc_selection();
      if( mark<0 ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         vi_message(get_message(mark));
         return(mark);
      }
      // This starts the appropriate mark-type depending on which command is
      // specified by 'name'.
      intraline_mark(name,mark,'',1);
      typeless p=_nrseek();

      // Save this in case a search command takes us to a mark in another buffer
      int buf_id=p_buf_id;

      /*
      * If we are recording a macro, delete the 'vi-get-event' line that was inserted before
      * we call the search command.  This is so that the search command can record the search string.
      */
      _str prev_line = _macro_get_line();
      if (_macro('s')) {
         _macro_delete_line();
      }

      status=call_index(repeat_count,index);

      // Now reinsert the 'vi-get-event', now that the search command should be all set.
      if (_macro('s')) {
         _macro_append(prev_line);
      }

      // Did a search command (i.e. vi-to-mark-col) take us to another buffer?
      if( is_search_cmd && buf_id!=p_buf_id ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         load_files('+bi 'buf_id);
         vi_message('Can''t delete across different buffers');
         _free_selection(mark);
         return(1);
      }

      if( status ) {
         if( p==_nrseek() && name!='vi-cursor-right' ) {
            // A possible error occurred in the command called
            //
            // Abort any keyboard macro currently recording
            vi_repeat_info('A');
            _free_selection(mark);
            return(1);
         } else {
            // Clear the message line if not serious error.
            // A non-serious error would be calling vi-cursor-down
            // more times than is valid, where the result is to
            // simply put the cursor at the bottom of the file.
            clear_message();
         }
      }

      status=(status || inclusive_mark_override);
      // This ends the appropriate mark-type depending on which command is
      // specified by 'name'.
      intraline_mark(name,mark,status,0);

      // There were no serious errors so far
      status=0;
      typeless old_mark=_duplicate_selection('');
      _show_selection(mark);
      if( vi_cut(false,cb_name,'1') ) {
         // Something happened when trying to move the mark to the clipboard
         status=1;
      }
      _show_selection(old_mark);
      _free_selection(mark);

      // Now make sure the cursor is on a real character
      if( p_col>_text_colc() ) {
         vi_end_line();
      }
   } else if( name=='vi-count' ) {
      flag := "D:vi-delete";
      // '0 ' is a place holder and, because it is not equal to 'C ',
      // will cause the subsequent mark to be deleted to the clipboard.
      cb_info := '0 'cb_name;
      status=vi_count(flag,cb_info,repeat_count);
   } else if ( name=='vi-insert-mode' || name=='vi-append-mode') {
      status=vi_mark_text_object(count==""?1:count,0,"",true,name=='vi-append-mode'?1:0);
      if (!status) {
         vi_cut(false,cb_name);
         // Now make sure that the cursor is on a real character
         if(p_col>_text_colc()) {
            vi_end_line();
         }
         if (vi_get_vi_mode()=='V') {
            vi_toggle_char_visual();
         }
      }
   } else {
      vi_message('Invalid delete sequence');
      status=1;
   }

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-delete',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}


_str vi_old_search_string,vi_old_word_re;
int  vi_old_search_flags;

static int intraline_mark(_str cmd_name, typeless mark, 
                          typeless inclusiveMarkOverride="",
                          typeless startMark="")
{
   // 'inclusive_mark_override' is non-zero when a command (like vi-cursor-right)
   // is called more times than is valid and there is a deletion sequence in
   // progress.  In the case of vi-cursor-right the cursor would be put at the
   // end of the current line and the mark would be inclusive so that the last
   // character on the line gets deleted along with the rest of the mark.
   inclusive_mark_override := (isinteger(inclusiveMarkOverride) && inclusiveMarkOverride!=0);
   noninclusive_mark_override := (upcase(inclusiveMarkOverride)=='N');
   start_mark := (isinteger(startMark) && startMark!=0);
   if( inclusive_mark_override ) {
      _select_char(mark,'IP');
   } else if( noninclusive_mark_override ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-cursor-left' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-cursor-right' || cmd_name=='vi-to-mark-col' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-begin-line' || cmd_name=='vi-begin-text' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-goto-col' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-next-word' || cmd_name=='vi-next-word2' || cmd_name=='vi-prev-word' || cmd_name=='vi-prev-word2' ) {
      if( start_mark && (cmd_name=='vi-prev-word' || cmd_name=='vi-prev-word2') ) {
         if( p_col==1 ) {
            // Start the deletion on the line above
            up();_TruncEndLine();
         }
      } else if( !start_mark && (cmd_name=='vi-next-word' || cmd_name=='vi-next-word2') ) {
         save_pos(auto p);
         old_line := p_line;
         _begin_select(mark);
         int diff=old_line-p_line;
         restore_pos(p);
         if( diff>0 ) {
            _str line=_expand_tabsc();
            if( substr(line,1,p_col-1)=='' ) {
               // End deletion on the line above
               up();_TruncEndLine();
            }
         }
      }
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-end-word' || cmd_name=='vi-end-word2' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-prev-sentence' || cmd_name=='vi-next-sentence'
              || cmd_name=='vi-prev-paragraph' || cmd_name=='vi-next-paragraph'
              || cmd_name=='vi-prev-section' || cmd_name=='vi-next-section' ) {
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-char-search-forward' || cmd_name=='vi-char-search-backward'
          || cmd_name=='vi-char-search-forward2' || cmd_name=='vi-char-search-backward2'
          || cmd_name=='vi-repeat-char-search' || cmd_name=='vi-reverse-repeat-char-search' )
          {
      if( start_mark ) {
         if( cmd_name=='vi-char-search-backward' || cmd_name=='vi-char-search-backward2' ) {
            col := p_col;
            left();
            _select_char(mark,'IP');
            if( p_col!=col ) {
               // Put us back where we started so the user does not see
               right();
            }
         } else if( cmd_name=='vi-repeat-char-search' || cmd_name=='vi-reverse-repeat-char-search' ) {
            if( (cmd_name=='vi-repeat-char-search' && vi_old_search_flags&REVERSE_SEARCH)
                || (cmd_name=='vi-reverse-repeat-char-search' && !(vi_old_search_flags&REVERSE_SEARCH))
                ) {
               col := p_col;
               left();
               _select_char(mark,'IP');
               if( p_col!=col ) {
                  // Put us back where we started so the user does not see
                  right();
               }
            } else {
               _select_char(mark,'IP');
            }
         } else {
            _select_char(mark,'P');
         }
      } else {
         if( cmd_name=='vi-char-search-forward' || cmd_name=='vi-char-search-forward2' || cmd_name=='vi-repeat-char-search' ) {
            if( p_col>_text_colc() ) {
               _TruncEndLine();
               left();
            }
         }
         // We want the character at the cursor, so must do right() because
         // of non-inclusive character selection.
         right();
         _select_char(mark,'P');
      }
   } else if( cmd_name=='ex-search-mode' || cmd_name=='ex-reverse-search-mode' ) {
      if( start_mark ) {
         if( cmd_name=='ex-reverse-search-mode' && p_col==1 ) {
            // Do not include the character at the cursor
            up();_TruncEndLine();
         }
      }
      _select_char(mark,'NP');
   } else if( cmd_name=='vi-find-matching-paren' ) {
      _select_char(mark,'IP');
   } else if( cmd_name=='vi-to-mark-line' ) {
      _select_line(mark,'P');
   } else if( vi_name_in_list(cmd_name,LINE_CMDS) || vi_name_in_list(cmd_name,LINE_CMDS2) ) {
      _select_line(mark,'P');
   } else {
      _select_char(mark,'IP');
   }

   return(0);
}

/**
 * By default this command handles 'D' pressed.
 */
_command int vi_delete_to_end(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   // This is not used
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   typeless status=0;
   // Is the line empty?
   if( !_line_length() ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Nothing to delete');
      return(1);
   }
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_repeat_info('A');
      vi_message(get_message(mark));
      return(mark);
   }
   save_pos(auto p);
   _TruncEndLine();
   if (count != "" && isinteger(count)) {
      down(count - 1);
      _TruncEndLine();
   }
   _select_char(mark,'P');
   restore_pos(p);
   _select_char(mark,'P');
   // Now move the marked area onto the clipboard
   typeless old_mark=_duplicate_selection('');
   _show_selection(mark);
   if( vi_cut(false,cb_name) ) {
      // Something happened when trying to move the mark to the clipboard
      status=1;
   }
   _show_selection(old_mark);
   _free_selection(mark);

   // Now make sure the cursor is on a real character
   if( p_col>_text_colc() ) {
      vi_end_line();
   }

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-delete-to-end',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(0);
}

/**
 * By default this command handles 'Ctrl+R'.
 */
_command int vi_redo() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_MARK|VSARG2_READ_ONLY/*|VSARG2_NOEXIT_SCROLL*/)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   idx := find_index('redo',COMMAND_TYPE);
   if( !idx ) {
      vi_message('Can''t find command: undo');
      return(1);
   }
   // Set the last index for past save
   last_index(idx);

   // note: this should be deselecting the selection and going back to command mode
   //   but it's not deselecting...
   //vi_visual_toggle();

   old_lines := p_Noflines;
   status := call_index(idx);
   if (status & LINE_DELETES_UNDONE) {
      vi_message(p_Noflines - old_lines' more lines');
   } else if (status & LINE_INSERTS_UNDONE) {
      vi_message(old_lines - p_Noflines' fewer lines');
   }
   return(status);
}
/**
 * By default this command handles 'u' pressed.
 */
_command int vi_undo() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_MARK|VSARG2_READ_ONLY/*|VSARG2_NOEXIT_SCROLL*/)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   idx := find_index('undo',COMMAND_TYPE);
   if( !idx ) {
      vi_message('Can''t find command: undo');
      return(1);
   }
   // Set the last index for past save
   last_index(idx);

   // note: this should be deselecting the selection and going back to command mode
   //   but it's not deselecting...
   //vi_visual_toggle();

   old_lines := p_Noflines;
   status := call_index(idx);
   if (status & LINE_DELETES_UNDONE) {
      vi_message(p_Noflines - old_lines' more lines');
   } else if (status & LINE_INSERTS_UNDONE) {
      vi_message(old_lines - p_Noflines' fewer lines');
   }
   return(status);
}

/**
 * By default this command handles 'U' pressed.
 */
_command int vi_undo_cursor() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   idx := find_index('undo-cursor',COMMAND_TYPE);
   if( !idx ) {
      vi_message('Can''t find command: undo-cursor');
      return(1);
   }
   // Set the last index for past save
   last_index(idx);

   return(call_index(idx));
}

/**
 * By default this command handles '.' pressed.
 */

_command int vi_repeat_last_insert_or_delete(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // MUST pass this unmodified because vi-repeat-info makes decisions
   // based on the original value.
   // Clipboard name which (if not '') will override any existing
   // clipboard name associated with playback.
   int idx=vi_repeat_info('X');
   _str cmdname=vi_name_eq_translate(name_name(idx));
   is_posted_cmd := vi_name_in_list(cmdname,VI_CMDS_POSTED_INSERT);
   if( is_posted_cmd ) {
      call_index(idx);
   }
   orig_last:=last_index();
   // '' as 'count' means execute the last command
   typeless status=vi_repeat_info('',count,cb_name);
   last_index(orig_last);
   _undo('S');
   return(status);
}

// This procedure handles 'c','C' pressed in command mode.
static int vi_change(_str option, typeless count=1, _str cb_name="")
{
   // 'C' = delimit changed text between the cursor and an intraline cursor command
   // 'E' = delimit from cursor to end of line
   // 'L' = delimit entire line
   // 'I' = delimit inner text object 
   // 'A' = delimit outer text object 
   option=upcase(strip(option));
   typeless orig_count=count;
   if( ! isinteger(count) || count<1 ) {
      count=1;
   }
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(cb_name);

   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   // We call this key for the example:  '4cl' so that we can mark the
   // affected text and cut it when the user starts typing, so that the
   // user may see what they are affecting.
   _vi_ckey='';

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   typeless status=0;
   if( option:=='C' ) {
      _str key=last_event();
      _str name=vi_name_eq_translate(vi_name_on_key(key));
      is_intraline_cmd := ( vi_name_in_list(name,INTRALINE_CMDS) || vi_name_in_list(name,INTRALINE_CMDS2) || vi_name_in_list(name,INTRALINE_CMDS3));
      is_search_cmd := ( vi_name_in_list(name,SEARCH_CMDS) );
      is_line_cmd := ( vi_name_in_list(name,LINE_CMDS) || vi_name_in_list(name,LINE_CMDS2) );

      // Special check for vi-goto-line() - do not default the repeat-count to 1
      if( name=='vi-goto-line' && (!isinteger(orig_count) || orig_count<1) ) {
         count=orig_count;
      }
      if( is_intraline_cmd || is_search_cmd || name:=='vi-count' ) {

         // Check the special case of changing to end of current word or next word
         inclusive_mark_override := false;
         if( vi_name_in_list(name,'vi-next-word vi-next-word2 vi-end-word vi-end-word2') ) {
            ch1 := get_text(-1);
            is_whitespace := (ch1:==' ' || ch1:=="\t");
            switch( name ) {
            case 'vi-next-word':
               // Starting in whitespace is a special case. If we
               // are starting in whitespace, then getting to the next
               // word requires a change in position, so we do not have
               // to compensate for that by changing the command issued.
               if( !is_whitespace ) {
                  inclusive_mark_override=true;
                  name='vi-end-word';
               }
               break;
            case 'vi-next-word2':
               // Starting in whitespace is a special case. If we
               // are starting in whitespace, then getting to the next
               // word requires a change in position, so we do not have
               // to compensate for that by changing the command issued.
               if( !is_whitespace ) {
                  inclusive_mark_override=true;
                  name='vi-end-word2';
               }
               break;
            default:
               // vi-end-word, vi-end-word2
               inclusive_mark_override=true;
            }
         }

         index := find_index(name,COMMAND_TYPE);
         if( !index || !index_callable(index) ) {
            vi_message('Command "'name'" not found');
            return(1);
         }
         // Save the starting position
         save_pos(auto p);
         typeless s=_nrseek();
         if( name=='vi-count' ) {
            flag := "M:vi-change-line-or-to-cursor";
            // '0 ' is just a place holder
            cb_info := '0 'cb_name;
            // In a modification sequence
            status=call_index(flag,cb_info,count,'1',index);
         } else {
            // Start the mark
            intraline_mark(name,mark,'',1);
            include_cur_col := false;
            end_word := vi_name_in_list(name,'vi-end-word vi-end-word2');
            line := ch1 := ch2 := "";
            if( end_word ) {
               line=_expand_tabsc();
               ch1=_SubstrChars(line,p_col,1);
               ch2=_SubstrChars(line,p_col+length(ch1),1);
               if( name=='vi-end-word' ) {
                  include_cur_col= ( (pos('[\od\p{L}\p{N}'def_vi_chars']',ch1,'','r') && !pos('[\od\p{L}\p{N}'def_vi_chars']',ch2,'','r')) ||
                                     (pos('['def_vi_chars2']',ch1,'','r') && !pos('['def_vi_chars2']',ch2,'','r')) ||
                                     pos('[ \t]',ch1,'','r')
                                   );
               } else {
                  include_cur_col= ( (pos('[~ \t]',ch1,'','r') && !pos('[~ \t]',ch2,'','r')) ||
                                     pos('[ \t]',ch1,'','r')
                                   );
               }
            }
            if( include_cur_col ) {
               --count;
            }
            if( count>0 || !include_cur_col ) {
               status=call_index(count,index);
            } else if( ch1:=="\t" || _text_colc(p_col,'T')<0 ) {   // Handles the case of a TAB
               // End the selection at the EXACT end of the tab
               right();
               --p_col;
            } else {
               // What are we doing here?
            }
         }
         if( status && s:==_nrseek() && name!='vi-cursor-right' ) {
            // An error occurred executing the intraline command
            _free_selection(mark);
            return(status);
         } else {
            // Clear the message line if not serious error. A non-serious
            // error would be CALLing vi-cursor-down more times than is
            // valid, where the result is to simply put the cursor at the
            // bottom of the file.
            clear_message();
         }
         if( name!='vi-count' ) {
            status=(status || inclusive_mark_override);
            // End the mark
            intraline_mark(name,mark,status,0);
            _begin_select(mark);
            _show_selection(mark);

            // Check to see if we should go ahead and delete the text
            // before the user presses a key.
            save_pos(p);
            endline := p_line;
            _end_select(mark);
            int at_bottom=down();
            if( !at_bottom ) up();
            beginline := p_line;
            restore_pos(p);
            typeless stype=_select_type(mark);
            if( (stype!='LINE' && beginline==endline) || def_vi_always_preview_change ) {
               if (!_MultiCursorAlreadyLooping()) {
                  _vi_ckey=vi_get_event();
               }
            }

            // Check to see if only an empty line was selected
            save_pos(p);
            _begin_select(mark);
            beginline=p_line;
            _end_select(mark);
            endline=p_line;
            restore_pos(p);
            int noflines=endline-beginline+1;
            single_empty_line := (noflines==1 && !_line_length());

            if( stype=='LINE' || !single_empty_line ) {
               vi_cut(false,cb_name);
            }

            if( stype=='LINE' ) {

               // Check to see if we are at the bottom of the file
               if( !at_bottom ) {
                  // Open a new line for inserting
                  up();
               }
               _str lkey=last_event();
               // Must do this so nosplit_insert_line() works correctly
               last_event(ENTER);
               nosplit_insert_line();
               last_event(lkey);
            }
         }
      } else {
         _free_selection(mark);
         vi_message('Invalid key sequence');
         return(1);
      }
   } else if( option:=='E' || option:=='L' ) {
      if( _line_length() || count!=1 ) {
         if( option:=='L' ) {
            p_col=1;
         }
         _select_char(mark,'IP');

         // Check to be sure we can substitute 'count' lines
         //
         // Save the starting position
         save_pos(auto p);
         if( count>1 ) {
            if( down(count-1) ) {
               restore_pos(p);
               _free_selection(mark);
               vi_message('Invalid count');
               return(1);
            }
         }
         vi_end_line();
         _select_char(mark,'IP');
         // Start changing at beginning
         restore_pos(p);
         _show_selection(mark);
         vi_cut(false,cb_name);
      }
   } else if ( option:=='I' || option:=='A') {
      status=vi_mark_text_object(count==""?1:count,0,"",true,option:=='A'?1:0);
      if (!status) {
         vi_cut(false,cb_name);
         // manually turn off visual mode and turn on command mode because the 
         // normal functions for this will not accomodate us here
         if (_MultiCursorLastLoopIteration()) {
            _vi_mode = 'C';
         }
         // Now make sure that the cursor is on a real character
         if(p_col>_text_colc()) {
            vi_end_line();
         }
      }
   }

   _show_selection(old_mark);
   _free_selection(mark);
   if (_MultiCursorLastLoopIteration()) {
      status=vi_switch_mode('I');
      if( !status && _vi_ckey:!='' ) {
         call_key(_vi_ckey);
      }
   }

   return(status);
}

/**
 * By default this command handles 'c' pressed.
 */
_command int vi_change_line_or_to_cursor(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   static _str key1;
   static _str key2;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key1=last_event();
      key2=vi_get_event();
   }
   typeless status=0;
   if( vi_name_on_key(key1):==vi_name_on_key(key2) ) {
      // This is the equivalent of a 'cc' in vi
      status=vi_change('L',count,cb_name);
   } else if (vi_name_on_key(key2):=='vi-insert-mode'){
      status=vi_change('I',count,cb_name);
      // This is the equivalent of a 'ci' in vi
   } else if (vi_name_on_key(key2):=='vi-append-mode'){
      status=vi_change('A',count,cb_name);
      // This is the equivalent of a 'ci' in vi
   } else {
      status=vi_change('C',count,cb_name);
   }

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   }

   return(status);
}

/**
 * By default this command handles 'C' pressed.
 */
_command vi_change_to_end(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   typeless status=vi_change('E',count,cb_name);

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   }

   return(status);
}

// This procedure handles 'r','R' pressed in command mode.
static typeless vi_replace(_str option, typeless count=1)
{
   // 'C' = only change the character at the cursor
   // 'R' = go into vi replace mode (overstrike mode)
   option=upcase(strip(option));

   // This is a repeat count
   if( ! isinteger(count) || count<1 ) {
      count=1;
   }
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   typeless mark=0;
   i := 0;

   if( option:=='C' ) {
      int len=_text_colc(0,'E');
      len=_text_colc(len,'P');
      // Physical column
      int col=_text_colc(p_col,'P');
      // Note: There is no way to know if we are trying to replace more
      // characters than are on the line for the case of UTF-8 or DBCS
      // because we would have to count all the characters on the line
      // first.
      if( count>len ) {
         vi_message('Replacement text is longer than existing line');
         return(1);
      }
      static _str key1;
      _str key;
      if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
         key1=vi_get_event();
      }
      key=key1;
      typeless orig_point=point();
      if( (isnormal_char(key)) || key==TAB || key==ENTER ) {
         if( key==TAB ) {
            key=_chr(9);
         } else if( key==ENTER ) {   // To support 'r' followed by ENTER to split a line
            mark=_alloc_selection();
            if( mark<0 ) {
               vi_message(get_message(mark));
               return(1);
            }
            _select_char(mark,'IP');
            for( i=0;i<(count-1);++i ) {
               if( p_col>_text_colc(0,'E') ) {
                  left();
                  break;
               }
               right();
            }
            _select_char(mark,'IP');
            _begin_select(mark);
            _delete_selection(mark);
            _free_selection(mark);
            split_insert_line();

            return(0);
         }
         // Replacement string
         rstr := "";
         for( i=1;i<=count;++i ) {
            rstr :+= key;
         }
         mark=_alloc_selection();
         if( mark<0 ) {
            vi_message(get_message(mark));
            return(1);
         }
         _select_char(mark,'IP');
         for( i=0;i<(count-1);++i ) {
            if( p_col>_text_colc(0,'E') ) {
               left();
               break;
            }
            right();
         }
         _select_char(mark,'IP');
         _begin_select(mark);
         _delete_selection(mark);
         _free_selection(mark);
         _insert_text(rstr);
      } else if( lowcase(strip(translate(vi_name_on_key(key),'-','_'))):=='quote-key' ) {
         message(nls('Type a key'));
         static _str key2;
         if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
            key2=vi_get_event();
         }
         key=key2;
         clear_message();
         key=key2ascii(key);
         str := "";
         if( length(key)>1 ) {
            str=key;
         } else {
            str=key;
         }
         // Replacement string
         rstr := "";
         for (i=1; i<=count ; ++i) {
            rstr :+= str;
         }
         mark=_alloc_selection();
         if( mark<0 ) {
            vi_message(get_message(mark));
            return(1);
         }
         _select_char(mark,'IP');
         for( i=0;i<(count-1);++i ) {
            if( p_col>_text_colc(0,'E') ) {
               left();
               break;
            }
            right();
         }
         _select_char(mark,'IP');
         _begin_select(mark);
         _delete_selection(mark);
         _free_selection(mark);
         _insert_text(rstr);
      } else {
         vi_message('Invalid key');
         return(1);
      }
      // if _insert_text wrapped to next line
      if(orig_point!=point()) {
         vi_end_line();
      } else {
         // Move cursor to end of replacement
         p_col=_text_colc(col+(count*length(key))-length(key),'I');
      }
   } else {
      // option=='R'
      //
      // This is essentially a way to put the editor into overstrike mode
      if( _insert_state() ) {
         _insert_toggle();
      }
      return(vi_switch_mode('I'));
   }

   return(0);
}

/**
 * By default this command handles 'r' pressed.
 */
_command int vi_replace_char(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   typeless status=vi_replace('C',count);

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-replace-char',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * By default this command handles 'R' pressed.
 * <P>
 * Note: Unlike standard vi, this command only puts the editor into
 * overstrike mode and does not take a repeat count
 */
_command int vi_replace_line(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   callback_idx := find_index('vi_escape',COMMAND_TYPE);
   // cb_name is '' because we do not want to save the last keystroke into the
   // keyboard macro.
   vi_repeat_info(last_index(),'',count,cb_name,callback_idx);

   typeless status=vi_replace('R');

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   }

   return(status);
}

/**
 * This procedure handles 's','S' pressed in command mode.
 */
static int vi_substitute(_str option, typeless count=1, _str cb_name="")
{
   // 'C' = replace single character with some text
   // 'L' = replace entire line with some text
   option=upcase(strip(option));

   if( ! isinteger(count) || count<1 ) {
      count=1;
   }

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(cb_name);

   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_message(get_message(mark));
      return(1);
   }
   if( option:=='C' ) {
      int col=_text_colc(p_col,'P');
      len := _line_length();
      if( count>(len-col+1) ) {
         count=len-col;
      } else {
         // Do this instead of a non-inclusive mark
         count--;
      }
      _select_char(mark,'IP');
      int i;
      for( i=0;i<count;++i ) {
         if( p_col>_text_colc(0,'E') ) {
            left();
            break;
         }
         right();
      }
      _select_char(mark,'IP');
      _begin_select(mark);
      _show_selection(mark);
      vi_cut(false,cb_name);
   } else {
      // Start substituting at the start of the new line
      p_col=1;
      if( _line_length() ) {
         _select_char(mark,'IP');

         // Check to be sure we can substitute 'count' lines
         //
         // Save the starting position
         save_pos(auto p);
         if( count>1 ) {
            if( down(count-1) ) {
               restore_pos(p);
               _free_selection(mark);
               vi_message('Invalid count');
               return(1);
            }
         }
         vi_end_line();
         _select_char(mark,'IP');
         // Start substituting at beginning
         restore_pos(p);
         _show_selection(mark);
         vi_cut(false,cb_name);
      }
   }
   _show_selection(old_mark);
   _free_selection(mark);
   typeless status=0;
   if (_MultiCursorLastLoopIteration()) {
      status=vi_switch_mode('I');
   }

   return(status);
}

/**
 * By default this command handles 's' pressed.
 */
_command int vi_substitute_char(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   typeless status=vi_substitute('C',count,cb_name);

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   }

   return(status);
}

/**
 * By default this command handles 'S' pressed.
 */
_command int vi_substitute_line(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   typeless status=vi_substitute('L',count,cb_name);

   if( status ) {
      vi_repeat_info('A');
   }

   return(status);
}

/**
 * By default this command handles '!' pressed.
 */
_command int vi_filter(typeless count="", _str cb_name="", _str arg_cmd="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (_MultiCursorAlreadyLooping()) {
      _MultiCursorLoopDone();
   }
   _str key;
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   _macro_delete_line();
   int Noflines;  // Can be positive or negative
   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   // If cmd!="" then it will be used instead of prompting the user for
   // the command to execute for the filter. This is most useful when
   // recording a macro for playback.
   typeless status=0;

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   _str initial_value;
   // Use a loop here to give us an easy mechanism for breaking out
   for(;;) {
       _str lkey;
       start_addr := p_line;
       lkey=last_event();
       key=vi_get_event();
       save_pos(auto p);
       if( lkey==key ) {
          // This is the equivalent of a '!!'
          //
          start_addr=p_line;
          if( isinteger(count) && count>1 ) {
             Noflines= count;
          } else {
             Noflines=1;
          }
       } else {
          _str name=vi_name_eq_translate(vi_name_on_key(key));
          index := find_index(name,COMMAND_TYPE);
          if( index==0 || ! index_callable(index) ) {
             vi_message('Command "'name'" not found');
             status=1;
             break;
          }

          // Now mark the lines which will be used as input to the filter
          // AND replaced with the output from the filter.
          is_line_cmd := ( vi_name_in_list(name,LINE_CMDS) || vi_name_in_list(name,LINE_CMDS2) );
          is_search_cmd := ( vi_name_in_list(name,'ex-search-mode ex-reverse-search-mode') );
          if( is_line_cmd || is_search_cmd || name=='vi-count' ) {
             if( name=='vi-count' ) {
                // Have to force a line mark, so don't pass any cb info to vi-count
                status=call_index('M:vi-filter','',count,index);
             } else {
                status=call_index(count,index);
             }
             if( status ) {
                break;
             }
             if (p_line<start_addr) {
                Noflines= start_addr-p_line+1;
                start_addr=p_line;
             } else {
                Noflines=p_line-start_addr+1;
                restore_pos(p);
             }
          } else {
             vi_message('Invalid key sequence');
             status=1;
             break;
          }
       }
       if (start_addr+Noflines-1>=p_Noflines) {
          if (start_addr==1) {
             initial_value='1,$!';
          } else {
             initial_value='.,$!';
          }
       } else if (Noflines==1) {
          initial_value='.!';
       } else {
          initial_value='.,.+'(Noflines-1)'!';
       }
       ex_mode('',initial_value);
       break;
   }

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-filter',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * By default this command handles 'J' pressed.
 * <P>
 * This code has been wholesaled from join-line.
 * A check has been added to check if the newly joined line
 * exceeds the line length limit and a FOR loop has been
 * added to support a repeat count.
 */
_command int vi_join_line(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   status := 0;
   count=vi_repeat_info('C',count);
   if( ! isinteger(count) || count<1 ) {
      count=1;
   } else {
      if( count>(p_noflines-p_line) ) {
         count=p_noflines-p_line;
      }
   }

   // Might want an option/parameter for this later.
   // Note: vim emulation has a different command for not stripping spaces.
   strip_spaces := true;

   // Join next line to current line at cursor position.
   // If cursor position is less than length of line then
   // join next line to end of current line. Leading spaces
   // and tabs of next line are stripped before join.
   int i;
   for( i=1;i<=count;++i ) {
      _TruncEndLine();
      _save_pos2(auto spacePos);
      status=down();
      if( status ) {
        vi_message(get_message(status));
        break;
      }
      up();
      --p_col;
      // No SPACE or TAB at end of line?
      need_space := false;
      if( _line_length() && !pos('[ \t]',get_text(),'','r') ) {
         // Force us to pad the end of the line with a space
         p_col+=2;
         need_space = true;
      }
      if(p_TruncateLength && p_col>=_TruncateLengthC()) {
         _beep();
         vi_message(get_message(VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG));
         status=VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG;
         break;
      }
      if( strip_spaces ) {
         down();
         deletedText := "";
         strip_leading_spaces(deletedText);
         up();
         status2 := _join_line();
         if(status2 && _TruncateLengthC()) {
            save_pos(auto p);
            down();
            int truncLength = _TruncateLengthC();
            if(length(deletedText)>truncLength) {
               deletedText=substr(deletedText,1,truncLength);
            }
            _begin_line();
            _insert_text(deletedText);
            restore_pos(p);
         }
      } else {
         _join_line();
      }
      _restore_pos2(spacePos);
      if (need_space) {
         _insert_text(' ');
      }
   }
   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-join-line',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * This procedure handles '<','>' pressed in command mode.
 */
static int vi_shift_text(_str option, typeless count=1, _str cb_name="")
{
   option=upcase(strip(option));
   typeless orig_count=count;
   if( ! isinteger(count) || count<1 ) {
      count=1;
   }

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(cb_name);

   int shiftwidth=p_SyntaxIndent;
   if( !isinteger(shiftwidth) || shiftwidth<1 ) {
      typeless t1="", t2="";
      parse p_tabs with t1 t2 .;
      if( isinteger(t2) && isinteger(t1) && t2>t1 ) {
         shiftwidth=t2-t1;
      }
      if( !isinteger(shiftwidth) || shiftwidth<1 ) {
         shiftwidth=def_vi_or_ex_shiftwidth;
      }
   }
   if( !isinteger(shiftwidth) || shiftwidth<1 ) {
      // This is the real vi default value
      shiftwidth=VI_DEFAULT_SHIFTWIDTH;
   }

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   static _str key1;
   static _str key2;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key1=last_event();
      key2=vi_get_event();
   }
   // vim does not write to a register when type >> or <<
#if 0
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_message(get_message(mark));
      return(1);
   }
#endif
   if( vi_name_on_key(key1)==vi_name_on_key(key2) ) {
      save_pos(auto p);
      if( down(count-1) ) {
         restore_pos(p);
         // Can free this because it was never shown
         vi_message('Invalid count');
         return(1);
      }
      up(count-1);
#if 0
      // vim does not write to a register when type >> or <<
      save_pos(auto p);
      _select_line(mark,'P');
      if( down(count-1) ) {
         restore_pos(p);
         // Can free this because it was never shown
         _free_selection(mark);
         vi_message('Invalid count');
         return(1);
      }
      _select_line(mark,'P');
      _show_selection(mark);
      vi_cut(true,cb_name);
      _show_selection(old_mark);
      _free_selection(mark);
      up(count-1);
#endif
   } else {
      _str name=vi_name_eq_translate(vi_name_on_key(key2));
      is_line_cmd := ( vi_name_in_list(name,LINE_CMDS) || vi_name_in_list(name,LINE_CMDS2) );
      is_search_cmd := ( vi_name_in_list(name,'vi-to-mark-line vi-to-mark-col ex-search-mode ex-reverse-search-mode') );

      // Special check for vi-goto-line : don't default the repeat-count to 1
      if( name=='vi-goto-line' && (!isinteger(orig_count) || orig_count<1) ) {
         count=orig_count;
      }
      if(is_line_cmd||is_search_cmd||name:=='vi-count'||name:=='vi-insert-mode'||name:=='vi-append-mode') {
         index := find_index(name,COMMAND_TYPE);
         if( index==0 || ! index_callable(index) ) {
            vi_message('Command "'name'" not found');
            return(1);
         }
         begin_linenum := p_line;
         typeless status=0;
         save_pos(auto p);
         if( name:=='vi-count' ) {
            // We have to force a line mark, so call vi-count without any clipboard info
            flag := "";
            if( option=='-' ) {
               flag='M:vi-shift-text-left';
            } else {
               flag='M:vi-shift-text-right';
            }
            // 'M' = in a modification sequence
            status=call_index(flag,'',count,index);
         } else if ( name:=='vi-insert-mode' || name:=='vi-append-mode' ) {
            status=vi_mark_text_object(count,0,"",true,name:=='vi-append-mode'?1:0);
            if (!status) {
               begin_select();
               begin_linenum=p_line;
               end_select();
               deselect();
               if (vi_get_vi_mode() == 'V') {
                  vi_switch_mode('V',0);
               } 
            }
         } else {
            status=call_index(count,index);
         }
         if( status ) {
            restore_pos(p);
            // Can free this because it was never shown
            //_free_selection(mark);
            return(status);
         }
         end_linenum := p_line;
         if( begin_linenum>end_linenum ) {
            int temp=begin_linenum;
            begin_linenum=end_linenum;
            end_linenum=temp;
         } else {
            p_line=begin_linenum;
         }
         count=(end_linenum-begin_linenum+1);

         save_pos(p);
         if( down(count-1) ) {
            restore_pos(p);
            // Can free this because it was never shown
            vi_message('Invalid count');
            return(BOTTOM_OF_FILE_RC);
         }
         up(count-1);
#if 0
         // vim does not write to a register when type >> or <<
         save_pos(p);
         _select_line(mark,'P');
         if( down(count-1) ) {
            restore_pos(p);
            // Can free this because it was never shown
            _free_selection(mark);
            vi_message('Invalid count');
            return(BOTTOM_OF_FILE_RC);
         }
         _select_line(mark,'P');
         _show_selection(mark);
         // vim does not write to a register when type >> or <<
         //vi_cut(true,cb_name);
         _show_selection(old_mark);
         _free_selection(mark);
         up(count-1);
#endif
      } else {
         // Can free this because it was never shown
         // _free_selection(mark);
         vi_message('Invalid modification sequence');
         return(1);
      }
   }

   // Now shift the text
   //
   // Start on the line above so the FOR loop works correctly
   up();
   int i;
   for( i=1;i<=count;++i ) {
      down();
      if( !_line_length() ) continue;
      _first_non_blank();
      if( option:=='-' ) {
         // Shifting left
         int shift_amount=shiftwidth;
         if( shiftwidth>(p_col-1) ) {
            shift_amount=p_col-1;
         }
         if( p_col>1 ) {
            _str lead_indent=_expand_tabsc(1,p_col-shift_amount-1,'S');
            int dcount=p_col-1;
            _begin_line();
            // Strip leading spaces
            _delete_text(dcount,'C');
            _insert_text(lead_indent);
         }
      } else {
         // Shifting right
         if( (_text_colc()+shiftwidth) > MAX_LINE ) {
            vi_message('This line cannot be shifted because it would exceed the line length limit!');
            return(1);
         }
         _first_non_blank();
         // The new indent
         _str lead_indent=indent_string(shiftwidth+p_col-1);
         int dcount=p_col-1;
         _begin_line();
         // Strip leading spaces
         _delete_text(dcount,'C');
         _insert_text(lead_indent);
      }
   }
   up(count-1);
   _first_non_blank();

   return(0);
}

/**
 * By default this command handles '<' pressed.
 */
_command int vi_shift_text_left(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   // Get the proper repeat count for playback
   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   typeless status=vi_shift_text('-',count,cb_name);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-shift-text-left',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * By default this command handles '>' pressed.
 */
_command vi_shift_text_right(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),count,cb_name);

   // Get the proper repeat count for playback
   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);
   typeless status=vi_shift_text('',count,cb_name);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-shift-text-right',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}


/**
 * By default this command handles '"' pressed.
 */
_command int vi_cb_name(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|
                                                    VSARG2_MARK)
{
   static _str key;
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   typeless status=0;
   static _str cb_name;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      cb_name=vi_get_event();
      if( !vi_is_valid_clipboard(cb_name) ) {
         _MultiCursorLoopDone();
         vi_message('Invalid clipboard name: "'cb_name'"');
         return(1);
      }
      key=vi_get_event();
   }
   _str name=vi_name_eq_translate(vi_name_on_key(key));
   is_cb_cmd := ( vi_name_in_list(name,CB_CMDS) );
   is_modification_cmd := ( vi_name_in_list(name,MODIFICATION_CMDS) && !vi_name_in_list(name,'vi-replace-char vi-replace-line vi-join-line vi-increment vi-decreement') );
   is_delete_cmd := ( vi_name_in_list(name,DELETE_CMDS) );
   if( is_cb_cmd || is_modification_cmd || is_delete_cmd || name=='vi-count' || name=='vi-delete' || name=='vi-delete-to-end' ) {
      index := find_index(name,COMMAND_TYPE);
      if( index==0 || ! index_callable(index) ) {
         _MultiCursorLoopDone();
         vi_message('Command "'name'" not found');
         return(1);
      }
      if( name!='vi-count' && name!='vi-delete' ) {
         // Set this so that vi-repeat-last-insert-or-delete works correctly
         last_event(key);
         // Set this so that vi-repeat-last-insert-or-delete works correctly
         last_index(index);
         if (name == 'vi-yank-to-cursor' && count == 1) {
            count = '';
         }
         status=call_index(count,cb_name,index);
      } else {
         _str cb_info=cb_name;
         if( name=='vi-count' ) {
            flag := "N:vi-cb-name";
            status=call_index(flag,cb_info,count,index);
         } else {
            // Call vi-delete
            //
            // Set this so that vi-repeat-last-insert-or-delete works correctly
            last_event(key);
            // Set this so that vi-repeat-last-insert-or-delete works correctly
            last_index(index);
            status=call_index(count,cb_info,index);
         }
      }
      return(status);
   } else if( name=='vi-repeat-last-insert-or-delete' ) {
      return(vi_repeat_last_insert_or_delete(count,cb_name));
   }

   _MultiCursorLoopDone();
   // If we got here then we have an error
   vi_message('Invalid key sequence');
   return(1);
}

/**
 * This procedure handles 'p','P' pressed in command mode.
 * This pastes text from the clipboard into the editing buffer.
 */
static int vi_put(_str option, _str cb_name="", typeless count=1,bool insert_as_lines_after=false,_str text_to_paste=null)
{
   // 'B' = insert lines before current line
   // 'A' = insert lines after current line
   option=upcase(strip(option));

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(cb_name);
   if( cb_name=='') {
      // Paste last clipboard. Could be "1 or "0 or the system clipboard
      cb_name='';
#if 0
      // Paste last clipboard. could be "1 or "0
      cb_name=_clipboard_get_last_clipboard_name();
      if (substr(cb_name,1,1)=='"' && length(cb_name)==2 && isalnum(substr(cb_name,2,1))) {
         cb_name=substr(cb_name,2,1);
      } else {
         cb_name='';
      }
#endif
   } else if( !vi_is_valid_clipboard(cb_name) ) {
      vi_message('Invalid clipboard name: "'cb_name'"');
      return(1);
   }
   typeless old_line_insert=def_line_insert;
   if (insert_as_lines_after) {
      def_line_insert='A';
   } else if( option:=='B' || option:=='A' ) {
      def_line_insert=option;
   }

   do_left := false;
   if( def_line_insert=='A' ) {
      if( _line_length() ) {
         if( p_col>=_text_colc() ) {
            // Start the paste after the last char
            vi_end_line();
         }
         right();
         // Correct for the right() we just did
         do_left=true;
      }
   }
   if (cb_name=='+') cb_name='';
   if (cb_name!='') cb_name='"'lowcase(cb_name);
   int temp_view_id=_cvtsysclipboard(cb_name,true);
   lines := -1;
   if (cb_name!='') {
      lines = clipboard_iNoflines(temp_view_id);
   }
   int status;
   orig_wid := -1;
   temp_wid := -1;
   if (insert_as_lines_after) {
      orig_wid=_create_temp_view(temp_wid);
      if (text_to_paste!=null) {
         insert_line(text_to_paste);
      } else {
         status=paste(cb_name);
      }
      lines=p_Noflines;
   }
   orig_line := -1;
   if (lines<0 && (point('L')>=0 || (_nrseek()<= def_use_fundamental_mode_ksize*1024))) {
      orig_line= p_line;
   }
   if (!isinteger(count)) count=1;
   int i;
   for (i=0;i<count;++i) {
      if (insert_as_lines_after) {
         bottom();
         _begin_line();_first_non_blank();
         mark:=_alloc_selection();
         top();_select_line(mark);
         bottom();_select_line(mark);
         activate_window(orig_wid);
         _copy_or_move(mark,'C');
         down(lines);
         _begin_line();_first_non_blank();
         _free_selection(mark);
         activate_window(temp_wid);
      } else {
         if (text_to_paste!=null) {
            insert_line(text_to_paste);
         } else {
            status=paste(cb_name);
         }
      }
   }
   def_line_insert=old_line_insert;
   if (!insert_as_lines_after) {
      if( do_left ) left();
   }

   if (lines<0 && orig_line>=0) {
      lines=p_line-orig_line;
   }
   if (insert_as_lines_after) {
      activate_window(orig_wid);
      _delete_temp_view(temp_wid);
   }
   // if cb_name='', won't get message if buffer is large and don't have line number.
   // Note that vim never shows a message for "block" paste but this does if cb_name!=''.
   if (lines > 2) {
      vi_message(lines ' more lines');
   }
   
   return(status);
}

/**
 * By default this command handles 'p' pressed.
 */
_command int vi_put_after_cursor(typeless count="", _str cb_name="",bool insert_as_lines_after=false,_str text_to_paste=null) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   typeless status=vi_put('A',cb_name,count,insert_as_lines_after,text_to_paste);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-put-after-cursor',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * By default this command handles 'P' pressed.
 */
_command int vi_put_before_cursor(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   typeless status=vi_put('B',cb_name,count);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-put-before-cursor',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

// This procedure handles 'y','Y' pressed in command mode.
// This copies text from the editing buffer into the clipboard.
static typeless vi_yank(_str option, _str cb_name="", typeless count=1)
{
   // 'C' = copy text between current position to the cursor
   // 'L' = copy current line
   option=upcase(strip(option));

   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(cb_name);

   typeless orig_count=count;
   if( ! isinteger(count) || count<1 ) {
      count=1;
   }
   // Start/initialize the list of events used when playing back recorded macros
   typeless status=0;
   vi_get_event('S');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_message(get_message(mark));
      return(mark);
   }
   typeless rp = 0;
   if( option:=='C' ) {
      static _str key1;
      static _str key2;
      if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
         key1=last_event();
         key2=vi_get_event();
      }
      _str name=vi_name_eq_translate(vi_name_on_key(key2));
      is_intraline_cmd := ( vi_name_in_list(name,INTRALINE_CMDS) || vi_name_in_list(name,INTRALINE_CMDS2) || vi_name_in_list(name,INTRALINE_CMDS3));
      is_search_cmd := ( vi_name_in_list(name,SEARCH_CMDS) );

      // Special check for vi-goto-line : don't default the repeat-count to 1
      if( name=='vi-goto-line' && (!isinteger(orig_count) || orig_count<1) ) {
         count=orig_count;
      }
      if( vi_name_on_key(key1)==vi_name_on_key(key2) ) {
         // This is the equivalent of a 'yy' pressed in the real vi
         //
         // First see if the count is valid
         l := p_line;
         if( down(count-1) ) {
            p_line=l;
            _free_selection(mark);
            vi_message('Invalid count');
            return(BOTTOM_OF_FILE_RC);
         }
         // Now mark it
         _select_line(mark,'P');
         up(count-1);
         _select_line(mark,'P');
      } else if( is_intraline_cmd || is_search_cmd || name:=='vi-count' ) {
         // We may have a repeat count
         index := find_index(name,COMMAND_TYPE);
         if( !index || ! index_callable(index) ) {
            vi_message('Command "'name'" not found');
            return(1);
         }
         save_pos(auto p);
         if( !(is_intraline_cmd || is_search_cmd) ) {
            // Call vi-count
            flag := "C:vi-yank-to-cursor";
            cb_info := 'C 'cb_name;
            status=call_index(flag,cb_info,count,index);   // 'C' = in a clipboard operation
            restore_pos(p);
            _free_selection(mark);
            return(status);
         }

         inclusive_mark_override := false;
         if( name=='vi-end-word' || name=='vi-end-word2' ) {
            inclusive_mark_override=true;
         }
         typeless s=_nrseek();
         // Start of mark
         intraline_mark(name,mark,inclusive_mark_override,1);
         status=call_index(count,index);
         if( status && s:==_nrseek() && name!='vi-cursor-right' ) {
            // An error occurred executing the intraline command
            restore_pos(p);
            _free_selection(mark);
            return(status);
         } else {
            // Clear the message if not a serious error.
            // A non-serious error would be CALLing vi-cursor-down
            // more times than is valid, where the result is to
            // simply put the cursor at the bottom of the file.
            clear_message();
         }
         // End of mark
         intraline_mark(name,mark,status||inclusive_mark_override,0);
         restore_pos(p);
      } else if (name :== 'vi-insert-mode') {
         vi_mark_text_object(count, rp, mark, false, 0);
      } else if (name :== 'vi-append-mode') {
         vi_mark_text_object(count, rp, mark, false, 1);
      } else {
         _free_selection(mark);
         vi_message('Invalid key sequence');
         return(1);
      }
   } else if( option:=='L' ) {
      // First see if the count is valid
      l := p_line;
      if( down(count-1) ) {
         p_line=l;
         _free_selection(mark);
         vi_message('Invalid count');
         return(BOTTOM_OF_FILE_RC);
      }
      // Now mark it
      _select_line(mark,'P');
      up(count-1);
      _select_line(mark,'P');
   }
   typeless old_mark=_duplicate_selection('');
   _show_selection(mark);

   status=vi_cut(true,cb_name,'0');
   _show_selection(old_mark);
   _free_selection(mark);

   if (rp) {
      restore_pos(rp);
   }

   return(status);
}

/**
 * By default this command handles 'y' pressed.
 */
_command int vi_yank_to_cursor(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   static _str lkey;

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      lkey=last_event();
   }


   vi_repeat_info(last_index(),lkey,count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   typeless status=vi_yank('C',cb_name,count);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-yank-to-cursor',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}

/**
 * By default this command handles 'Y' pressed.
 */
_command int vi_yank_line(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=strip(vi_repeat_info('N',cb_name));
   typeless status=vi_yank('L',cb_name,count);

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-yank-line',COMMAND_TYPE);
      int repeat_idx=vi_repeat_info('X');   // Get the index which started the recording
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            vi_repeat_info('E');   // End and save the currently recording keyboard macro
         }
      }
   }

   return(status);
}

// This procedure handles 'f','F','t','T' pressed in command mode.
static int vi_char_search(_str option1,_str option2,typeless count=1)
{
   // option1 - ''  = put cursor ON next character typed
   //           '<' = put cursor BEFORE next character typed
   //           '>' = put cursor AFTER next character typed
   //           'R' = repeat last search
   //
   // option2 - ''  = forward search
   //           '-' = reverse search
   if( _on_line0() ) {
      return(1);
   }
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      vi_message(get_message(mark));
      return(1);
   }
   typeless old_mark=_duplicate_selection('');
   option1=upcase(option1);
   if( ! isinteger(count) || count<1 ) {
      count=1;
   }
   save_pos(auto p);
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   typeless status=0;
   search_flags := "";
   // We will be searching within a line mark
   soptions := "@hm";
   // Reversing the search?
   if( option2=='-' ) {
      if( option1=='R' ) {
         if( vi_old_search_flags&REVERSE_SEARCH ) {
            soptions :+= '+';
         } else {
            soptions :+= '-';
         }
      } else {
         soptions :+= '-';
      }
   }
   if( option1=='R' ) {
      // Mark the line and show it
      _show_selection(mark);_select_line(mark,'P');_select_line(mark,'P');
      restore_search(vi_old_search_string,vi_old_search_flags,vi_old_word_re);
      /*if( search_flags!='' ) {
         execute(vi_old_search_flags);
      } */
      int i;
      for( i=1;i<=count;++i ) {
         typeless q=point();
         col := p_col;
         status=repeat_search(soptions);
         // In same place?
         if( !status && q==point() && col==p_col ) {
            status=repeat_search(soptions);
         }
         if( status ) break;
      }
   } else {
      static _str key1;
      _str key;
      if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
         key1=vi_get_event();
      }
      key=key1;
      if( lowcase(strip(translate(vi_name_on_key(key),'-','_'))):=='quote-key' ) {
         message(nls('Type a key'));
         static _str key2;
         if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
            key2=vi_get_event();
         }
         key=key2;
         clear_message();
         key=key2ascii(key);
      } else if( length(key)!=1 ) {
         if( !_dbcsIsLeadByte(substr(key,1,1)) && !p_UTF8 && !isnormal_char(key) ) {
            vi_message('Invalid character');
            status=1;
         }
      }
      if( option1=='<' ) {
         key=_escape_re_chars(key);
         // The '?' forces us to put cursor before the character pressed
         key='?':+key;
         soptions :+= 'r';
      } else if( option1=='>' ) {
         soptions :+= '>';
      }
      // We show the mark after we get the character so the user does not see the mark
      //
      // Mark the line and show it
      _show_selection(mark);_select_line(mark,'P');_select_line(mark,'P');
      typeless s=_nrseek();
      status=search(key,soptions);
      //#if 0   /* 0 = rev post 5.0b */
      // Did we move?
      if( s==_nrseek() ) {
         status=repeat_search();
      }
      //#endif
      int i;
      for( i=1;i<=(count-1);++i ) {
         if( status ) break;
         status=repeat_search();
      }
      if( !status ) {
         save_search(vi_old_search_string,vi_old_search_flags,vi_old_word_re);
      }
   }
   _show_selection(old_mark);
   _free_selection(mark);
   if( status ) {
      restore_pos(p);
      vi_message(get_message(status));
      return(status);
   }

   return(0);
}


/**
 * By default this command handles 'f' pressed.
 */
_command int vi_char_search_forward(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('','',count));
}

/**
 * By default this command handles 'F' pressed.
 */
_command int vi_char_search_backward(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('','-',count));
}

/**
 * By default this command handles 't' pressed.
 * <P>
 * This command puts the cursor before the character searched for.
 */
_command int vi_char_search_forward2(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('<','',count));
}

/**
 * By default this command handles 'T' pressed.
 * <P>
 * This command puts the cursor before the character searched for.
 */
_command int vi_char_search_backward2(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('>','-',count));
}

/**
 * By default this command handles ';' pressed.
 */
_command int vi_repeat_char_search(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('R','',count));
}


/**
 * By default this command handles ',' pressed.
 */
_command int vi_reverse_repeat_char_search(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   return(vi_char_search('R','-',count));
}

/**
 * By default this command handles 'm' pressed.
 */
_command int vi_set_mark() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   key=vi_get_event();
   if( isalpha(key) ) {
      typeless status=set_bookmark('-r 'key);
      if( status ) {
         vi_message('Error setting bookmark');
      }
      return(status);
   } else {
      vi_message('Invalid key sequence');
      return(1);
   }
}

/**
 * By default this command handles ')','}' pressed.
 */
_command int vi_maybe_keyin_match_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( def_vi_or_ex_showmatch!='' && def_vi_or_ex_showmatch ) {
      return(keyin_match_paren());
   } else {
      keyin(last_event());
   }

   return(0);
}

/**
 * By default this command handles '~' pressed.
 */
_command int vi_toggle_case_char(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),count,cb_name);

   typeless status=0;
   count=vi_repeat_info('C',count);
   if( !isinteger(count) || count<1 ) {
      count=1;
   }
   len := _line_length();
   typeless old_mark=_duplicate_selection('');
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      // Abort the keyboard macro recording
      vi_repeat_info('A');
      vi_message(get_message(mark));
      return(1);
   }

   //_undo('S');
   _select_char(mark,'IP');
   int i;
   for( i=0;i<(count-1);++i ) {
      if( p_col>_text_colc(0,'E') ) {
         left();
         break;
      }
      right();
   }
   _select_char(mark,'IP');
   _show_selection(mark);
   togglecase_selection();
   _end_select();
   _show_selection(old_mark);
   _free_selection(mark);
   // Position cursor just after toggled text
   if( p_col<_text_colc() ) right();

   // Clear the "Can't go past end of line" message
   // possibly generated by vi-cursor-right.
   clear_message();

   if( status ) {
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-toggle-case-char',COMMAND_TYPE);
         // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   _undo('S');
   return(status);
}

/**
 * By default this command handles 'BACKSPACE' or 'S-BACKSPACE' pressed.
 * 
 * Changed behavior to vim default - RH
 */
_command void vi_backspace(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   linewrap_rubout();
}

/*
 * By default this command handles TAB pressed.
 */
_command int vi_tab() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else {
         ctab();
         return(0);
      }
      return(0);
   }

   vi_message('Invalid key sequence');

   return(1);
}

/**
 * By default this command handles Shift+TAB pressed.
 */
_command int vi_backtab() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      } else {
         cbacktab();
         return(0);
      }
      return(0);
   }

   vi_message('Invalid key sequence');

   return(1);
}
/**
 * This function is called by other functions like next_buffer(), prev_buffer().
 * <P>
 * This will display the current mode if the SHOWMODE option is turned ON
 */
int _switchbuf_vi(_str old_buffer_name, _str options="")
{
   keys := upcase(strip(translate(def_keys,'-','_')));
   if ( keys=="VI-KEYS" ) {
      _str orig_mode=vi_get_vi_mode();
      if (def_vim_start_in_cmd_mode && _select_type()=='') {
         vi_switch_mode("c",0);
      } else {
         vi_correct_visual_mode(0);
      }
      _str mode=vi_get_vi_mode();
      if ((mode=='C' && p_mode_eventtab!=find_index('vi-command-keys',EVENTTAB_TYPE)) ||
          (mode!='C' && p_mode_eventtab==find_index('vi-command-keys',EVENTTAB_TYPE))
         ) {
         //messageNwait('_switchbuf_vi');
         vi_switch_mode(vi_get_vi_mode(),0);
      }
      mode=vi_get_vi_mode();
      read_only := "Read only";
      showmode := __ex_set_showmode();
      showmode=(isnumber(showmode) && showmode>0);
      if ( showmode && (upcase(options)!='W' || orig_mode!=mode) ) {
         if ( p_readonly_mode) {
            if (mode=='V') {
               sticky_message(VI_VISUAL_MODE_MSG);
            } else {
               sticky_message(def_vi_command_mode_msg);
            }
         } else {
            if ( mode=='C' ) {
               sticky_message(def_vi_command_mode_msg);
            } else if (mode=='V') {
               sticky_message(VI_VISUAL_MODE_MSG);
            } else {
               sticky_message(VI_INSERT_MODE_MSG);
            }
         }
      }
   }

   return(0);
}
static typeless _last_idle_time;

static void generate_keys_recreating_selection() {
   typeless count=count_lines_in_selection();
   if (count>1) {
      // Generate key strokes for cursor down
      --count;
      int i;
      for (i=1;i<=length(count);++i) {
          _macro('KK',substr(count,i,1));
      }
      _macro('KK',name2event('DOWN'));
   }
   if (_select_type()!='LINE') {
      _get_selinfo(auto start_col,auto end_col,auto junk_buf_id);
      // Vim selections always inclusive
      count=length(_expand_tabsc(start_col,end_col-start_col,'S'));
      int i;
      for (i=1;i<=length(count);++i) {
          _macro('KK',substr(count,i,1));
      }
      _macro('KK',name2event('RIGHT'));
   }
}

void vi_correct_visual_mode_timer(bool AlwaysUpdate=false) {
   if (def_keys!='vi-keys') {
      return;
   }
   if ((AlwaysUpdate || _idle_time()!=_last_idle_time) && !_no_child_windows()) {
      _mdi.p_child.vi_correct_visual_mode();
      _last_idle_time=_idle_time();
   }
}
static void maybe_adjust_for_non_inclusive_selection() {
   if (_select_type()=='CHAR' && !_select_type('','I') && p_col>1) {
      lc:=_select_type('','P');
      if (substr(lc,2,1)=='B') {
         --p_col;
      } else {
         save_pos(auto p);
         dupmark:=_duplicate_selection();
         _end_select(dupmark);
         if (p_col>1) {
            --p_col;
            dupmark2:=_duplicate_selection();
            _free_selection(dupmark);
            _deselect();
            _select_char();
            _begin_select(dupmark2);
            _select_char();
            _free_selection(dupmark2);
         } else {
            _free_selection(dupmark);
         }
         restore_pos(p);
      }
   }
}

void vi_correct_visual_mode(_str showmsg=null) {
   if (!_vi_enable_correct_visual_mode) {
      return;
   }
   //say('vi_correct_visual_mode');
   if (select_active()) {
      _str mode=vi_get_vi_mode();
      if (mode == 'C') {
         //say('Switch to V');
         if (showmsg==null) showmsg=__ex_set_showmode();
         bool auto_deselect=_cua_select!=0;
         switch (_select_type()) {
         case 'CHAR':
            maybe_adjust_for_non_inclusive_selection();
            // Generate keys for selections
            last_index(find_index('vi_toggle_char_visual',COMMAND_TYPE),'C');
            vi_toggle_visual(1,_select_type(),auto_deselect);
            _vi_dot_kbdmacro_start_recording();
            _macro('KK','v');  // Assume this command is bound to this key
            generate_keys_recreating_selection();
            return;
         case 'BLOCK':
            last_index(find_index('vi_toggle_block_visual',COMMAND_TYPE),'C');
            vi_toggle_visual(1,_select_type(),auto_deselect);
            _vi_dot_kbdmacro_start_recording();
            _macro('KK',name2event('c-v'));  // Assume this command is bound to this key
            generate_keys_recreating_selection();
            return;
         case 'LINE':
            last_index(find_index('vi_toggle_line_visual',COMMAND_TYPE),'C');
            vi_toggle_visual(1,_select_type(),auto_deselect);
            _vi_dot_kbdmacro_start_recording();
            _macro('KK',name2event('V'));  // Assume this command is bound to this key
            generate_keys_recreating_selection();
            return;
         }
      } else if (mode=='V') {
         maybe_adjust_for_non_inclusive_selection();
         // Reselect with the selection attributes we want.
         // 'v' Shift+End.  The shift+End selects to end of line with the wrong attributes
         _vi_visual_select();
      }
   } else if (vi_get_vi_mode()=='V') {
      //say('Switch to C');
      // Switch to command mode.
      // The 'V' option toggles the V option
      if (showmsg==null) showmsg=__ex_set_showmode();
      vi_switch_mode('V',showmsg);
   }
}
void vi_toggle_visual(int showmsg,_str type,bool auto_deselect_vmode=false) {
   if (command_state()) {
      vi_visual_maybe_command();
      return;
   }
   if (vi_get_vi_mode() == 'V' && _select_type()!=type && _select_type()!='') {
      _vi_auto_deselect_vmode=auto_deselect_vmode;
      _select_type('','T',type);
      return;
   }
   if (_MultiCursorLastLoopIteration()) {
      if (vi_get_vi_mode() == 'V') {
         // Switch out of visual mode and turn off recording
         deselect(); 
         _macro('KD',0);
         vi_switch_mode('V',showmsg);
         return;
      }
      // Switch into visual mode
      count := 0;
      cb_name := "";
      vi_repeat_info(last_index('','C'),last_event(),count,cb_name);

      int repeat_count=vi_repeat_info('C',count);

      if( ! isinteger(repeat_count) || repeat_count<1 ) {
         repeat_count=1;
      }

      // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
      cb_name=strip(vi_repeat_info('N',cb_name));
      // Start/initialize the list of events used when playing back recorded macros
      vi_get_event('S');
      vi_switch_mode('V',showmsg,'',auto_deselect_vmode);
   }
   // If there is not a selection in this buffer
   if (!select_active()) {
      deselect();
   }
   vi_visual_select(type);

}
/**
 * Toggles character visual mode on/off (which also toggles visual mode on/off)
 */
_command void vi_toggle_char_visual(int showmsg=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_MARK|
                                                               VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   vi_toggle_visual(showmsg,'CHAR');
}

/**
 * Toggles line visual mode on/off (which also toggles visual mode on/off)
 */
_command void vi_toggle_line_visual(int showmsg=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_MARK|
                                                VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   vi_toggle_visual(showmsg,'LINE');
}

/**
 * Toggles block visual mode on/off (which also toggles visual mode on/off)
 */
_command void vi_toggle_block_visual(int showmsg=1) name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_MARK|
                                                 VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   vi_toggle_visual(showmsg,'BLOCK');
}

/**
* This command handles the = pressed. 
*/
_command int vi_format(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if( command_state() ) {
      key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   vi_repeat_info(last_index(),last_event(),count,cb_name);

   // Get the proper repeat count for playback
   int repeat_count=vi_repeat_info('C',count);
   // IMPORTANT - DO NOT UPCASE THE CLIPBOARD NAME
   cb_name=vi_repeat_info('N',cb_name);

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');

   static _str key1;
   static _str key2;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key1=last_event();
      key2=vi_get_event();
   }
   _str name=vi_name_eq_translate(vi_name_on_key(key2));

   index := find_index(name,COMMAND_TYPE);
   if( index==0 || ! index_callable(index) ) {
      _MultiCursorLoopDone();
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
      vi_message('Command "'name'" not found');
      return(1);
   }

   // Special check for vi-goto-line - do not default the repeat-count to 1
   if( name=='vi-goto-line' && (!isinteger(count) || count<1) ) {
      repeat_count=count;
   }
   typeless status=0;
   is_intraline_cmd := ( vi_name_in_list(name,INTRALINE_CMDS) || vi_name_in_list(name,INTRALINE_CMDS2) || vi_name_in_list(name,INTRALINE_CMDS3));
   is_search_cmd := ( vi_name_in_list(name,SEARCH_CMDS) );
   if( vi_name_eq_translate(vi_name_on_key(key1)):==name ) {
      // This is the equivalent of a '==' pressed in vi
      typeless mark=_alloc_selection();
      if( mark<0 ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         vi_message(get_message(mark));
         return(mark);
      }
      if (!isinteger(repeat_count)) {
         repeat_count=1;
      }
      _select_line(mark,'P');
      save_pos(auto p);
      status=down(repeat_count-1);
      if( status ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         restore_pos(p);
         vi_message('Invalid count');
         return(status);
      }
      _select_line(mark,'P');
      // Now move the marked area to the clipboard
      typeless old_mark=_duplicate_selection('');
      _show_selection(mark);
   } else if( is_intraline_cmd || is_search_cmd ) {

      // Check the special case of deleting to end of current word or next word
      inclusive_mark_override := false;
      if( vi_name_in_list(name,'vi-end-word vi-end-word2') ) {
         inclusive_mark_override=true;
      }

      typeless mark=_alloc_selection();
      if( mark<0 ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         vi_message(get_message(mark));
         return(mark);
      }
      // This starts the appropriate mark-type depending on which command is
      // specified by 'name'.
      intraline_mark(name,mark,'',1);
      typeless p=_nrseek();

      // Save this in case a search command takes us to a mark in another buffer
      int buf_id=p_buf_id;

      /*
      * If we are recording a macro, delete the 'vi-get-event' line that was inserted before
      * we call the search command.  This is so that the search command can record the search string.
      */
      _str prev_line = _macro_get_line();
      if (_macro('s')) {
         _macro_delete_line();
      }

      status=call_index(repeat_count,index);

      // Now reinsert the 'vi-get-event', now that the search command should be all set.
      if (_macro('s')) {
         _macro_append(prev_line);
      }

      // Did a search command (i.e. vi-to-mark-col) take us to another buffer?
      if( is_search_cmd && buf_id!=p_buf_id ) {
         // Abort any keyboard macro currently recording
         vi_repeat_info('A');
         load_files('+bi 'buf_id);
         vi_message('Can''t filter across different buffers');
         _free_selection(mark);
         return(1);
      }

      if( status ) {
         if( p==_nrseek() && name!='vi-cursor-right' ) {
            // A possible error occurred in the command called
            //
            // Abort any keyboard macro currently recording
            vi_repeat_info('A');
            _free_selection(mark);
            return(1);
         } else {
            // Clear the message line if not serious error.
            // A non-serious error would be calling vi-cursor-down
            // more times than is valid, where the result is to
            // simply put the cursor at the bottom of the file.
            clear_message();
         }
      }

      status=(status || inclusive_mark_override);
      // This ends the appropriate mark-type depending on which command is
      // specified by 'name'.
      intraline_mark(name,mark,status,0);

      // There were no serious errors so far
      status=0;
      typeless old_mark=_duplicate_selection('');
      _show_selection(mark);
   } else if( name=='vi-count' ) {
      flag := "M:vi-format";
      _str cb_info=cb_name;
      status=vi_count(flag,cb_info,repeat_count);
   } else if ( name=='vi-insert-mode' || name=='vi-append-mode') {
      status=vi_mark_text_object(count==""?1:count,0,'',true,name=='vi-append-mode'?1:0);
   } else {
      vi_message('Invalid filter sequence');
      status=1;
   }

   // this might not leave the cursor exactly where vim would
   status = beautify_selection();
   if (vi_get_vi_mode()=='V') {
      vi_toggle_char_visual();
   }

   if( status ) {
      // Abort any keyboard macro currently recording
      vi_repeat_info('A');
   } else {
      this_idx := find_index('vi-format',COMMAND_TYPE);
      // Get the index which started the recording
      int repeat_idx=vi_repeat_info('X');
      if( repeat_idx && repeat_idx==this_idx ) {
         if( vi_repeat_info('I') ) {
            // End and save the currently recording keyboard macro
            vi_repeat_info('E');
         }
      }
   }

   return(status);
}
static bool gdo_increment=false;
static typeless gincrement_count=0;
static _str _vi_increment_filter(_str s)
{
   i:=pos('(-|)[0-9]#',s,1,'r');
   if (i<=0) {
      return s;
   }
   len:=pos('');
   typeless n;
   n=substr(s,i,len);
   if (gdo_increment) {
      n+=gincrement_count;
   } else {
      n-=gincrement_count;
   }
   s=substr(s,1,i-1):+n:+substr(s,i+len);
   return s;
}

static int vi_increment_or_decrement(typeless count,_str cb_name,bool do_increment) {
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      } else {
         right();
      }
      return(0);
   }
   if ( !isinteger(count) || count<1 ) {
      count=1;
   }
   cmd_index:=last_index();
   vi_repeat_info(last_index(),last_event(),count,cb_name);
   count=vi_repeat_info('C',count);

   gincrement_count=count;
   gdo_increment=do_increment;
   if (_select_type()!='') {
      upcase_selection('',_vi_increment_filter);
      begin_select();
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
      return(0);
   }
   int status;
   ch:=get_text();
   save_pos(auto p);
   if (isdigit(ch)|| ch:=='-') {
      status=search('(-|)[0-9]#','r@h-');
   } else {
      status=search('(-|)[0-9]#|$','r@h');
   }
   if (status || match_length()==0) {
      restore_pos(p);
      return 1;
   }
   i:=(typeless)get_match_text('');
   if (do_increment) {
      i+=count;
   } else {
      i-=count;
   }
   _nrseek(match_length('S'));
   len:=match_length();
   _delete_text(len);
   _insert_text(i);--p_col;


   // Get the index which started the recording
   int repeat_idx=vi_repeat_info('X');
   if( repeat_idx && repeat_idx==cmd_index ) {
      if( vi_repeat_info('I') ) {
         // End and save the currently recording keyboard macro
         vi_repeat_info('E');
      }
   }

   _undo('S');
   return(status);
}

_command int vi_increment(typeless count=1,_str cb_name='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return vi_increment_or_decrement(count,cb_name,true);
}
_command int vi_decrement(typeless count=1,_str cb_name='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return vi_increment_or_decrement(count,cb_name,false);
}
