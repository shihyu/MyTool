////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49180 $
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
#import "argument.e"
#import "bind.e"
#import "clipbd.e"
#import "dir.e"
#import "emacs.e"
#import "fileman.e"
#import "files.e"
#import "forall.e"
#import "fsort.e"
#import "get.e"
#import "help.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "moveedge.e"
#import "pmatch.e"
#import "prefix.e"
#import "pushtag.e"
#import "put.e"
#import "recmacro.e"
#import "savecfg.e"
#import "seek.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "window.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/*
 *  Fixed switch_other_buffer so that of the list-buffers command was
 *  canceled, it would set the p_buf_flags property back correctly.
 *
 *  It also now uses the BUFFER_ARG as opposed to FILE_ARG for competion
 *  purposes.
 *
 */

/*
 *  Fixed gnu_ctab so that it special cases the second "public" in the
 *  following:
 *
 *   public class stuff
 *   {
 *      public void junk()
 *      {
 *      }
 *   }
 *
 *  It would unindent the code.
 *
 */

/*
 * Gnu EMACS emulation macro
 *
 */


static int gnu_comment_column=33;
static int dabbrev_backward_only=0;
_str _no_resize;

/*
 *Function Name: gnu_save_some_buffers
 *
 *Parameters:
   none
 *
 *Description:
   cycles through buffer ring and prompts under the command line if you want
   to save the buffer (only stops on modified buffers)
 *
 *Returns:
   nothing
 *
 */
_command void gnu_save_some_buffers()
{
   int quit=0;
   int orig_buf_id=p_buf_id;
   do {
      if (p_modify && _need_to_save()) {
         _str letter=letter_prompt('Save file 'p_buf_name'? (y/n/q)','YNQ');

         switch (letter) {
         case 'Y':
            save();
            break;
         case 'N':
            break;
         case 'Q':
            quit=1;
            break;
         default:
            break;

         }
      }
      _next_buffer('R');
   } while ( p_buf_id!=orig_buf_id && quit!=1);     //get around compiler bug
   p_buf_id=orig_buf_id;   //set buffer back


}

/*
 *Function Name: gnu_command_on_key
 *
 *Parameters:
    key: key to check (gotten with get_event or pgetkey()
    index: nametable index of command bound to this key returned
 *
 *Description:
    returns index of command bound to key passed in
 *
 *Returns:
    returns the name of the command bound to key
 *
 */
static _str gnu_command_on_key(typeless key, var index)
{
   _str keyname="";
   typeless keytab_used="";
   typeless status=prompt_for_key('',keytab_used,key,keyname,'','1');
   index=eventtab_index(keytab_used,keytab_used,event2index(key));
   //return(name_name(eventtab_index(keytab_used,keytab_used,event2index(key))));
   return(name_name(index));
}

/*
 *Function Name:gnu_ctrl_argument
 *
 *Parameters:
   none
 *
 *Description:
   bound to c-0 through c-9.  Gets repeat count and calls argument with that
   # of times to repeat (c-2 c-2 whatever repeats whatever 22 times)
 *
 *Returns:
   nothing
 *
 */
_command void gnu_ctrl_argument() name_info(','VSARG2_LASTKEY)
{
   int count=0;
   int index=0;

   typeless number="";
   parse event2name(last_event()) with 'C-' number;
   count=(count*10)+number;

   //get key presses until something other than gnu_ctrl_arg is called
   _str k="";
   _str command="";
   for (;;) {
      message('Repeat count 'count);
      k=pgetkey();
      command=gnu_command_on_key(k,index);
      if (command=='gnu-ctrl-argument') {
         parse event2name(k) with 'C-' number;
         count=(count*10)+number;
      } else {
         /*name=event2name(k);
         if (name=='PAD-MINUS' || name=='-') {
            //count*=-1;  //gnu emacs doesn't do this
         } else {*/
         break;
         //}
      }
   }
   if (!iscancel(k)) {
      if (index) {
         argument(count,'','',index,k);
      } else {
         //messageNwait('inside else in gnu_ctrl_arg');
         int i;
         for (i=1; i<=count ; ++i) {
            call_key(k);
         }
      }
   } else {
      message('Repeat Aborted');
   }
   if (_cmdline.p_visible) {
      _cmdline.p_visible=0;
   }
}

/*
 *Function Name:gnu_alt_argument
 *
 *Parameters:
   none
 *
 *Description:
   bound to a-0 through a-9.  Gets repeat count and calls argument with that
   # of times to repeat (a-2 a-2 whatever repeats whatever 22 times)
 *
 *Returns:
   nothing
 *
 */
_command void gnu_alt_argument() name_info(','VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   int count=0;
   int index=0;

   typeless number="";
   parse event2name(last_event()) with 'A-' number;
   count=(count*10)+number;

   //get key presses until something other than ctrl_arg is called
   _str k="";
   _str command="";
   for (;;) {
      message('Repeat count 'count);
      k=pgetkey();
      command=gnu_command_on_key(k,index);
      if (command=='gnu-alt-argument') {
         parse event2name(k) with 'A-' number;
         count=(count*10)+number;
      } else {
         /*name=event2name(k);
         if (name=='PAD-MINUS' || name=='-') {
            //count*=-1;  //gnu emacs doesn't do this
         } else {*/
         break;
         //}
      }
   }
   if (!iscancel(k)) {
      if (index) {
         //_message_box('here');
         argument(count,'','',index,k);
         //_message_box('here2');
      } else {
         //messageNwait('inside else in ctrl_arg');
         int i;
         for (i=1; i<=count ; ++i) {
            call_key(k);
         }
      }
   } else {
      message('Repeat Aborted');
   }
   if (_cmdline.p_visible) {
      _cmdline.p_visible=0;
   }
}

/*
 *Function Name:gnu_help
 *
 *Parameters:
     none
 *
 *Description:
     tries to implement as much of the gnu emacs help system as is reasonable.
 *
 *Returns:
     nothing
 *
 */
_command void gnu_help() name_info(','VSARG2_CMDLINE|VSARG2_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY)
{
   if (command_state()) {
      command_toggle();
   }
   _str key="";
   _str name="";
   _str filename="";
   int qmark=0;
   message('c-h (Type ? for further options)');
   outerloop:
   for (;;) {
      //key=pgetkey();
      key=get_event();
      if (!iscancel(key)) {
         name=event2name(key);
         //messageNwait('key was:'event2name(key));
         switch (name) {
         case '?':
            ++qmark;
            if (qmark==1) {
               /*sticky_*/
               message('b c d k w.  Type ? again for more help:');
            } else if (qmark==2) {
               help('-contents');
               //print the help screen that has what the letters do
               clear_message();
            }
            break;
         case 'C-D':
         case 'F':
            help('Frequently Asked Questions');
            break outerloop;
         case 'i':
            execute('help -contents');
            break outerloop;
         case 'b':
         case 'BACKSPACE':
            list_keydefs();
            break outerloop;
         case 'c':
            key_sequence();
            break outerloop;
         case 'e':
            filename=COMPILE_ERROR_FILE;
            //filename=GetErrorFilename();
            edit(maybe_quote_filename(filename));
            break outerloop;
         case 'd':
         case 'f':
         case 'v':
         case 'C-C':
         case 'C-F':
            describe_command();
            break outerloop;
         case 'a':
         case 'A':
            execute('help -search');
            break outerloop;
         case 'k':
         case 'C-K':
            //prompt them for a command and get help on it
            //XEmacs C-K actually brings up the .info file, but we don't use them
            clear_message();
            what_is();
            break outerloop;
         case 's':
            //This will eventually list the mode specific keys
#if 1
            list_keydefs();
#else
            name=name_name(p_mode_eventtab);
            if (name=='default-keys' || name=='') {
               //Just list all of the key bindings
               list_keydefs();
               break outerloop;
            } else {
               int temp_view_id=0;
               int orig_view_id=_create_temp_view(temp_view_id);
               activate_window(orig_view_id);
               _delete_temp_view(temp_view_id);
            }
#endif
            break outerloop;
         case 't':
            help('Overview');
            break outerloop;
         case 'w':
            //get command name and print which keystroke(s) it is bound to
            clear_message();
            where_is();
            break outerloop;
         default:
            clear_message();
            break outerloop;
         }
      } else {
         clear_message();
         break;
      }
   }
}

//This is just a "quiet" version of what_is
static void key_sequence()
{
   _str k="";
   _str keyname="";
   typeless keytab_used="";
   typeless status=prompt_for_key(nls('Enter key sequence:')' ',keytab_used,k,keyname,'','','',1);
   if ( status || iscancel(k) ) {
      _beep();
      return;
   }
   int index=eventtab_index(keytab_used,keytab_used,event2index(k));
   if ( index && (name_type(index)&(COMMAND_TYPE|EVENTTAB_TYPE))) {
      int type=name_type(index) & ~(INFO_TYPE|DLLCALL_TYPE);
      _str type_name=eq_value2name(type& ~INFO_TYPE,HELP_TYPES);
      _str msg=nls('%s runs the %s',keyname,type_name " "name_name(index));
      message(msg);
      _macro_call('what_is', keyname);
      append_retrieve_command(name_name(index));
   } else {
      _str msg=nls('%s is not defined',keyname);
      message(msg);
   }
}

static void describe_command()
{
   clear_message();
   _str command="";
   get_string(command,'Enter item to get help on: ',COMMAND_ARG);
   if (strip(command)!='') {
      execute('help 'command);
      return;
   } else {
      message('No command entered');
      return;
   }
}

_command void copy_region_as_kill(_str name='') name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   copy_to_clipboard(name);
}

_command void minmdi() name_info(','VSARG2_CMDLINE|VSARG2_READ_ONLY)
//C-z
{
   _mdi.p_window_state='I';
}

_command void mou_gnu_track_insert()
{
   typeless p;
   _save_pos2(p);
   mou_click('','C');
   _restore_pos2(p);
   copy_to_cursor();
   deselect();
}

/*
 *Function Name: just_one_space
 *
 *Parameters: none
 *
 *Description: deletes all spaces (if any), and puts one in their place.
 *
 *Returns: nothing.
 *
 */

_command void just_one_space() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
//Bound to "Alt- " in emacs...  The editor maps this to "Ctrl- " on Unix
{
   if ( command_state() ) {
      call_root_key(' ');
      return;
   }
   //start_col=p_col;
   //messageNwait('p_col='p_col' _line...='_line_length());
   if (p_col > _line_length()) {
      keyin_space();
      gnu_delete_space();
   } else if (p_col < _first_non_blank_col()) {
      gnu_delete_space();
      p_col=1;
   } else {
      gnu_delete_space();
   }
   keyin_space();
   return;
}

/*
 *Function Name: gnu_delete_space
 *
 *Parameters: none
 *
 *Description: like the EMACS delete_space command, except the column isn't
 *             preserved, and it deletes all of the spaces, not just from
 *             the cursor to the next non-blank char.
 *
 *Returns: nothing
 *
 */
_command void gnu_delete_space() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
//A-\
{
   init_command_op();
   typeless p;
   _save_pos2(p);
   int col=p_col;
   search('[ \t]#|?|$|^','@rh-');
   if ( match_length() && get_text(1,match_length('s'))=='' ) {
      _nrseek(match_length('s'));
      _delete_text(match_length());
   }
   _restore_pos2(p);
   boolean last_pos=p_col>=_text_colc();

   // special case: when p_col is already in col 1 then the decrement will still
   //               leave it in col 1 and then it will be incremented in the else
   //               and left in column 2
   boolean notInCol1 = (p_col > 1);
   --p_col;
   if (get_text(1):==' ') {
      search('[ \t]#|?|$|^','@rh-');
      if ( match_length() && get_text(1,match_length('s'))=='' ) {
         _nrseek(match_length('s'));
         _delete_text(match_length());
      }
   } else {
      // only increment if werent already in col 1
      if(notInCol1) {
         p_col++;
      }
   }
   retrieve_command_results();
}

/*
 *Function Name: mark_beginning_of_buffer
 *
 *Parameters: none
 *
 *Description: marks from the current position to the beginning of the
               buffer (char)
 *
 *Returns: nothing
 *
 */
_command void mark_beginning_of_buffer() name_info(','VSARG2_MARK|VSARG2_READ_ONLY)
//C-S-,
{
   _select_char('','CP');
   top();
   exchange_point_and_mark();
}

/*
 *Function Name: mark_end_of_buffer
 *
 *Parameters: none
 *
 *Description: marks from the current position to the end of the buffer (char)
 *
 *Returns: nothing
 *
 */

_command void mark_end_of_buffer() name_info(','VSARG2_MARK|VSARG2_READ_ONLY)
//C-S-.
{
   _select_char('','CP');
   bottom();
   exchange_point_and_mark();
}

/*
 *Function Name: mark_whole_buffer
 *
 *Parameters: none
 *
 *Description: character selects the entire buffer, and leaves you at the top of it.
 *
 *Returns:
 *
 */
_command void mark_whole_buffer()
//C-x C-p, C-x h
{
   _deselect();
   bottom();
   _select_char('','CP');
   top();
}

/*
 *Function Name: gnu_kill_rectangle
 *
 *Parameters: none
 *
 *Description:
        This will cut the selected rectangle into a named clipboard.
 *
 *Returns:
 *
 */
_command void gnu_kill_rectangle() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
//C-x r k
{
   if (!select_active()) {
      message('There must be an active selection');
      return;
   }

   // figure out where our selection is so we can make an emacs selection out of it
   int startCol=0, endCol=0, buf_id=0;
   _get_selinfo(startCol, endCol, buf_id);
   typeless cursorP;
   save_pos(cursorP);

   _begin_select();
   typeless beginP;
   save_pos(beginP);
   _end_select();
   typeless endP;
   save_pos(endP);

   int width = endCol - startCol;

   if (startCol != endCol) {

      // go back to the beginning of the selection
      restore_pos(beginP);

      // we don't really include the last column in this selection
      if (startCol > endCol) {
         width = 0;
         --p_col;
      }

      // start an emacs selection at this position
      emacs_select_block();

      // now go to the end position
      restore_pos(endP);

      // we don't really include the last column in this selection
      if (endCol >= startCol) {
         // was our cursor at the beginning mark of the selection?
         if (cursorP == beginP) {
            width = 0;
         }
         --p_col;
      }

      // finally, do the cut thing
      cut(true, false, "gr");
   }

   // put the cursor back where it started
   restore_pos(cursorP);

   // move it over the width of the selection
   cursor_left(width);
}

/*
 *Function Name: gnu_yank_rectangle
 *
 *Parameters: none
 *
 *Description:
        This will paste the contents the killed rectangle.
 *
 *Returns:
 *
 */
_command void gnu_yank_rectangle() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
//C-x r y
{
      paste("gr");
}


/*
 *Function Name: gnu_indent_selection
 *
 *Parameters:
 *
 *Description:  Performs a modal tab on selected text.
 *
 *Returns:
 *
 */
_command void gnu_indent_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
//C-x r o
{
   if (!select_active()) {
      message('There must be an active selection');
      return;
   }
   if (def_modal_tab) {
      move_text_tab();
   } else {
      int amount=GetIndentWidth();
      shift_selection_right(amount);
   }
}
static int GetIndentWidth()
{
   int syntax_indent=p_SyntaxIndent;
   if (isinteger(syntax_indent) && syntax_indent) {
      return(syntax_indent);
   } else {
      typeless first="", last="";
      parse p_tabs with first last .;
      if (isinteger(first) && isinteger(last)) {
         return(last-first);
      } else {
         return(0);
      }
   }
}

/*
 *Function Name: c_indent_for_comment
 *
 *Parameters: none
 *
 *Description: indents the current pos to the gnu_comment_column column, or one past the
               last position on the current line
 *
 *Returns: nothing
 *
 */

_command void c_indent_for_comment()
//A-;  (c-mode)
{
   end_line();
   if (p_col>gnu_comment_column) {
      right();
   } else p_col=gnu_comment_column;
   keyin("/*  */");
   cursor_left(3);
}

/*
 *Function Name: set_comment_column
 *
 *Parameters: none
 *
 *Description: sets the comment column (used in c_indent_for_comment) to
               the current column.
 *
 *Returns: nothing
 *
 */

//This can't be bound to "C-x ;" in c-mode due to keytable problems.
_command void set_comment_column(typeless col="")
//C-x ; (c-mode)
{
   if (col:!='') {
      if (!isinteger(col) || col<0) {
         col=0;
      }
   } else {
      col=0;
   }
   if (col) {
      gnu_comment_column=col;
   } else {
      gnu_comment_column=p_col;
   }
   message(nls('Comment column set to column %s',gnu_comment_column));
}

/*
 *Function Name: move_past_close_and_reindent
 *
 *Parameters: none
 *
 *Description: moves the close brace to the end of the statement, and replaces
               it with the cursor
 *
 *Returns:
 *
 */
_command void move_past_close_and_reindent() name_info(','VSARG2_EDITORCTL)
//A-' (c-mode)
{
   //find('{','+NIXCS-');

   //Search backwards to find the open paren (not in a comment, or string)
   search('{','@I-,XSC,');
   _deselect();
   find_matching_paren(true);
   linewrap_delete_char();
   typeless p;
   _save_pos2(p);
   left();
   search('[~ ]','+NIr@');
   _deselect();
   right();
   keyin('}');
   _restore_pos2(p);
}

/*
 *Function Name: count_lines_region
 *
 *Parameters: none
 *
 *Description: counts the number of lines and chars in a selection
 *
 *Returns:
 *
 */

_command void count_lines_region() name_info(','VSARG2_MARK)
//A-=
{
   if (_select_type():!='') {
      //lock_selection();
      save_pos(auto p);
      message(nls('Selection has %s lines %s chars',count_lines2(),count_chars()));
      restore_pos(p);
   } else message('There needs to be an active selection');
}

static int count_lines2(...)
{
   message('Counting Lines');
   _end_select();
   end_line=p_line;
   _begin_select();
   begin_line=p_line;
   int result=abs(begin_line-end_line)+1;
   return(result);
}

static int count_chars(...)
{
   message('Counting Characters');
   save_pos(auto p);
   begin_select();
   typeless start = _QROffset();
   end_select();
   typeless end_val = _QROffset();
   int val = end_val - start;
   restore_pos(p);
   return(val);
}

/*
 *Function Name: what_cursor_position
 *
 *Parameters: none
 *
 *Description: returns the OCT, DEC, HEX and seek positions of the current text
 *
 *Returns: the above as a sticky message.
 *
 */

_command _str what_cursor_position() name_info(VSARG2_READ_ONLY)
//C-x =
{
   /* char: / (057, 47, 0x2f) point= _nrseek() of total_seek() (%) column p_col */
   save_pos(auto p);
   _str ch=get_text(1);
   int _dec=_UTF8Asc(ch);
   _str _hex=dec2hex(_dec);
   _str _oct=dec2hex(_dec,8);
   typeless result=_nrseek();
   bottom_of_buffer();
   typeless result2=_nrseek();
   typeless position="";
   if (result==result2) {
      position=100;
   } else {
      position=substr(result/result2*100,1,2);
   }
   restore_pos(p);
   _str msg=nls('char: %s (%s, %s, %s) point= %s of %s (%s%) column %s',
                ch, _oct, _dec, _hex, result, result2, position, p_col);
   sticky_message(msg);
   return(msg);
}


/*
 *Function Name:balance_windows
 *
 *Parameters: none
 *
 *Description: Makes all visible windows the same height (approximately)
 *
 *Returns: 0 if the windows were resized, otherwise 1.
 *
 */

_command int balance_windows() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI)
//C-x +
{
   if (_no_child_windows()) {
      //No child windows, so they can't be balanced.
      return(1);
   }
   //messageNwait('_mdi.p_child.p_window_state='_mdi.p_child.p_window_state);
   if (_mdi.p_child.p_window_state:=='M') {
      //The child window is maximized...  Therefore, only one visible window.
      return(1);
   }
   int count;
   int orig_wid;
   orig_wid=p_window_id;

   count=0;
   do {
      next_window();
      count++;
   } while ( p_window_id!=orig_wid );
   //p_window_id=orig_wid;
   //say(nls('_mdi.p_child.p_window_state=%s last=%s count=%s', _mdi.p_child.p_window_state, last, count));
   //messageNwait('count='count);
   if (count>1 && count <4) {
      _no_resize=1;
      tile_windows('h');
      _no_resize='';
      return(0);
   } else {
      if (count>=4) {
         _str letter=letter_prompt('More than three windows active.  Tile them? (y/n/q)','YNQ');
         if (upcase(letter)=='Y') {
            tile_windows('h');
            return(0);
         }
      }
   }
   return(1);
}

/*
 *Function Name: shrink_window_if_larger_than_buffer
 *
 *Parameters: none
 *
 *Description: shrinks the window's display


Shrink the WINDOW to be as small as possible to display its contents.
Do not shrink to less than `window-min-height' lines.
Do nothing if the buffer contains more lines than the present window height,
or if some of the window's contents are scrolled out of view,
or if the window is not the full width of the frame,
or if the window is the only window of its frame.


 *
 *Returns:
 *
 */

_command void shrink_window_if_larger_than_buffer() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI)
//C-x -
{
   if (_no_child_windows()) {
      //No child windows.
      return;
   }
   //messageNwait('_mdi.p_child.p_window_state='_mdi.p_child.p_window_state);
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return;
   }
   typeless op=_default_option('T');
   _str scroll=_scroll_style();
   if (pos('s',scroll,1,'i')) {
      typeless number="";
      parse scroll with . number ;
      op=+number+1;
   }
   int file_height=(p_Noflines+op)*_text_height();
   //hsplit_window();
   while (file_height<p_client_height) {
      //messageNwait('here');
      shrink_window();
   }
}

/*
 *Function Name: shrink_window_horizontally
 *
 *Parameters:
 *
 *Description: shrinks a v-split window.
 *
 *Returns:
 *
 */

_command void shrink_window_vertically() name_info(','VSARG2_REQUIRES_MDI)
//C-c {
{
   if (_no_child_windows()) {
      //No child windows.
      return;
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return;
   }
   //_mdi._tile_windows('H');
   typeless status=0;
   int view_id=0;
   if ( _tile_left(view_id,true)) {
      status=delete_tile('','','e',LEFT,RIGHT);
   } else if (_tile_right(view_id,true)) {
      status=delete_tile('','','e',RIGHT,LEFT);
   }
   if (status) {
      //delete_tile didn't find a window over there.
      message('The window must be tiled vertically.');
   }
}
/* Enlarges a v-split window */
_command void enlarge_window_vertically() name_info(','VSARG2_REQUIRES_MDI)
//C-c }
{
   if (_no_child_windows()) {
      //No child windows.
      return;
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return;
   }
   //_mdi._tile_windows('H');
   int view_id=0;
   typeless status=0;
   if ( _tile_left(view_id,true)) {
      status=delete_tile('','','e',LEFT,LEFT);
   } else if (_tile_right(view_id,true)) {
      status=delete_tile('','','e',RIGHT,RIGHT);
   }
   if (status) {
      //delete_tile didn't find a window over there.
      message('The window must be tiled vertically.');
   }
}

/*
 *Function Name: find_file_read_only
 *
 *Parameters: none
 *
 *Description:
 *
 *Returns: Status from edit()
 *
 */

_command int find_file_read_only(_str filename="") name_info(FILE_ARG'*,'VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE)
//C-x C-r
{
   typeless status=0;
   if (filename:=='') {
      status=edit();
   } else {
      status=edit(maybe_quote_filename(filename));
   }
   if (status) {
      //Edit failed
      return(status);
   }
   //Had to do it this way because of a bug in p_read_only_mode?
   p_readonly_mode=true;
   p_readonly_set_by_user=true;
   return(status);
}

/*
 *Function Name: last_command
 *
 *Parameters:
 *
 *Description: executes the last command that was run from the command line.
               Cannot be run from the command line.
 *
 *Returns:
 *
 */

_command int last_command() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_EDITORCTL)
//C-x C-A-[, C-x A-Esc
{
   _str line="";
   _cmdline.retrieve_skip();
   _cmdline.get_command(line);
   if (stranslate(line,'_','-'):=='last_command') {
      message('This command cannot be used on the command line');
      _cmdline.set_command('',1,1,'');
      return(1);
   }
   message('Executing command: 'line);
   //say(line);
   command_put(line);
   command_execute();
   message(nls('Command: %s completed', line));
   return(0);
}

_command gnu_goto_tag(_str proc_name="") name_info(TAG_ARG','VSARG2_READ_ONLY)
//C-x .
{
   if ( proc_name=='' ) {
      /* Try to find the procedure at the cursor. */
      if ( !_no_child_windows() ) {
         int start_col=0;
         proc_name=cur_word(start_col);
      }
   }
   _macro_delete_line();

   _str line="";
   typeless status=get_string(line,nls('Find tag: ')' ','-.goto_tag',proc_name);
   _cmdline.set_command('',1,1,'');
   if ( ! status && line!='') {
      status=push_tag(line);
      _macro_call('push_tag',line);
   }
   cursor_data();
   center_line();
   return(status);

}

/*
 *Function Name: find_other_tag
 *
 *Parameters: same as find-tag
 *
 *Description: does a find-tag if user has def_one_file set, it will
               tile all windows horizontally,
 *
 *Returns: 0 if successful
 *
 */

_command find_other_tag() name_info(TAG_ARG','VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY)
//C-x 4 .
{
   if (_no_child_windows()) {
      //No child windows.
      return(1);
   }
   //r=_nrseek();
   typeless tag_files=tags_filename();
   _str filename=next_tag_file(tag_files,1);
   if ( filename=='' && tag_files=='' ) {
      //Go ahead and perform the check now, so I don't mess up windowing.
      messageNwait(nls('No tag files found: %s',tags_filename()));
      return(1);
   }
   typeless status=0;
   _str new_buf_name="";
   _str buf_name=_mdi.p_child.p_buf_name;
   int orig_wid=_mdi.p_child.p_window_id;
   int junk=0;
   _str tag_name=cur_word(junk,'');
   next_window();
   if (_mdi.p_child.p_window_id==orig_wid) {
      //There was only one window active
      status=find_tag();
      if (status) {
         //find_tag failed.
         return(status);
      }
      if (buf_name:==p_buf_name) {
         //Help was brought up (Slick-C), or the tag is in the same file
         return(0);
      }
      //Need to create a window, and put the right files in them:
      new_buf_name=p_buf_name;
      if (_mdi.p_child.p_window_state=='M') {
         hsplit_window();
         prev_window();
         find_buffer(buf_name);
      } else {
         edit(' +w +b 'maybe_quote_filename(buf_name));
      }
      center_line();
      next_window();
      center_line();
   } else {
      //There was another window present.
      typeless seekpos=_nrseek();
      status=find_tag(tag_name);
      if (status) {
         //find_tag failed.
         prev_window();
         return(status);
      }
      if (buf_name:==p_buf_name && seekpos==_nrseek()) {
         //Help was brought up (Slick-C)
         prev_buffer();
         return(0);
      }
   }
   return(status);
}

/*
 *Function Name: switch_other_buffer
 *
 *Parameters: file's name
 *
 *Description: creates a new buffer in the "other" window.
               Does not pick the file up off disk!
 *
 *Returns:   0 if successful.
 *
 */

_command switch_other_buffer() name_info(BUFFER_ARG'*,'VSARG2_MARK|VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY)
//C-x 4 b
{
   _str message_string='Switch to buffer in other window: (default to buffer-list): ';

   _str buf_name="";
   typeless status=get_string(buf_name, message_string, BUFFER_ARG);
   if (status) {
      message(get_message(COMMAND_CANCELLED_RC));
      return(status);
   }
   //buf_name=prompt('','Switch to buffer in other window: (default to buffer-list)');
   if (_no_child_windows()) {
      //There aren't any windows opened, so it just opens a new buffer by that name.
      if (buf_name=='') {
         //User didn't specify a file either...
         return(1);
      }
      status=edit(' +b 'maybe_quote_filename(buf_name));
      return(status);
   }
   if (strip(buf_name)==''  && def_one_file!='') {
      return(list_buffers('',true));
   }
   _str name=p_buf_name;
   if (name=='') {
      name=p_DocumentName;
   }
   _str old_buf_name="";
   _str new_buf_name="";
   int old_wid=p_window_id;
   _next_window();
   int new_wid=p_window_id;
   _prev_window();
   if (strip(buf_name)=='') {
      //list-buffers will open the file for me.  However, I need it in a new window.
      old_buf_name=_mdi.p_child.p_buf_name;
      if (old_buf_name=='') {
         old_buf_name=_mdi.p_child.p_DocumentName;
      }
      if (old_wid==new_wid) {
         //Create new window...
         status=list_buffers('',true);
         if (status) {
            //old_wid.p_buf_flags=old_buf_flags;
            //prev_window();
            return(status);
         }
         if (old_wid==new_wid) {
            new_buf_name=_mdi.p_child.p_buf_name;
            if (new_buf_name=='') {
               new_buf_name=_mdi.p_child.p_DocumentName;
            }
            edit(' +b 'maybe_quote_filename(old_buf_name));
            hsplit_window();
            edit(' +b 'maybe_quote_filename(new_buf_name));
         }
         return(status);
      }
      //_next_window();
      status=list_buffers('',true);
      if (status) {
         //old_wid.p_buf_flags=old_buf_flags;
         //_prev_window();
         return(status);
      } else {
         new_buf_name=_mdi.p_child.p_buf_name;
         if (new_buf_name=='') {
            new_buf_name=_mdi.p_child.p_DocumentName;
         }
         edit(' +b 'maybe_quote_filename(old_buf_name));
         _prev_window();
         edit(' +b 'maybe_quote_filename(new_buf_name));
      }
      //Possibly redundant checking..
      if (old_wid==new_wid) {
         new_buf_name=_mdi.p_child.p_buf_name;
         if (new_buf_name=='') {
            new_buf_name=_mdi.p_child.p_DocumentName;
         }
         edit(' +b 'maybe_quote_filename(old_buf_name));
         hsplit_window();
         edit(' +b 'maybe_quote_filename(new_buf_name));
      }
      return(status);
   } else {
      if (new_wid==old_wid) {
         hsplit_window();
         tile_windows('h');
         _next_window();
      } else {
         _next_window();
         //tile_windows('h');
      }
      _str path="";
      parse buf_name with name '<'path'>';
      if (path != '') {
         buf_name = path:+name;
      }
      status=edit('+b 'maybe_quote_filename(absolute(buf_name)));
      if (status==FILE_NOT_FOUND_RC) {
         //The buffer wasn't found.  So I'll have to open a new one.
         clear_message();
         edit(' +t 'maybe_quote_filename(absolute(buf_name)));
      }
      return(status);
   }
}


/*
 *Function Name: prompt_other_dir
 *
 *Parameters:  A directory name.
 *
 *Description: Creates a fileman-dir in the "other" window if
               "One file per window" is on.  Otherwise, it just
               does a "dir".
 *
 *Returns:  nothing
 *
 */

_command int prompt_other_dir(_str directory="") name_info(FILE_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_NCW)
//C-x 4 d
{
   if (strip(directory):=='' || !isdirectory(strip(directory))) {
      directory=prompt('','Directory (other window)');
   }
   typeless status=0;
   if (_no_child_windows()) {
      //There were no child windows.
      status=dir(directory);
   } else {
      int orig_wid=_mdi.p_child.p_window_id;
      next_window();
      int new_wid=_mdi.p_child.p_window_id;
      if (orig_wid==new_wid) {
         //There was only one window
         if (_mdi.p_child.p_window_state=='M') {
            hsplit_window();
            status=dir(directory);
         } else {
            typeless old_one_file=def_one_file;
            def_one_file='+w';
            status=dir(directory);
            def_one_file=old_one_file;
         }
         if (status) {
            kill_window();
         }
      } else {
         //There was another window.
         status=dir(directory);
      }
   }
   if (status) {
      message(get_message(status));
   }
   return(status);
}

/*
 *Function Name: dir_other_window
 *
 *Parameters: none
 *
 *Description:  Does a "dir" on the current directory.
 *
 *Returns:
 *
 */

_command int dir_other_window() name_info(','VSARG2_REQUIRES_MDI)
//C-x 4 C-j, C-x 4 Enter
{
   typeless status=0;
   if (!_no_child_windows()) {
      int orig_wid=_mdi.p_child.p_window_id;
      next_window();
      int new_wid=_mdi.p_child.p_window_id;
      if (new_wid==orig_wid) {
         //There was one window.
         if (_mdi.p_child.p_window_state=='M') {
            hsplit_window();
            status=dir();
            if (status) {
               message(get_message(status));
            }
         } else {
            typeless old_one_file=def_one_file;
            def_one_file='+w';
            status=dir();
            def_one_file=old_one_file;
            if (status) {
               message(get_message(status));
            }
         }
      } else {
         status=dir();
         if (status) {
            message(get_message(status));
         }
      }
   } else {
      status=dir();
      if (status) {
         message(get_message(status));
      }
   }
   return(status);
}

/*
 *Function Name: edit_other_window
 *
 *Parameters:  same as edit
 *
 *Description: same as edit, but if def_one_file is set, it will tile the windows.
 *
 *Returns:  The edit() status.
 *
 */

_command int edit_other_window(_str filename="") name_info(FILE_ARG'*,'VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
//C-x 4 C-f, C-x 4 f
{
   if (filename:=='') {
      filename=prompt('','Edit (Other window)');
   }
   typeless status=0;
   filename=maybe_quote_filename(filename);
   if (_no_child_windows()) {
      status=edit(filename);
   } else {
      int orig_wid=p_window_id;
      next_window();
      if (p_window_id==orig_wid) {
         if (_mdi.p_child.p_window_state=='M') {
            hsplit_window();
            status=edit(filename);
         } else {
            status=edit(' +w 'filename);
         }
      }
      status=edit(filename);
      if (status) {
         message(get_message(status));
      }
   }
   return(status);
}

_command find_file_other_read_only(_str filename="") name_info(FILE_ARG'*,'VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE)
//C-x 4 r
{
   typeless status=0;
   if (filename:=='') {
      _str message_string='Edit read only (Other Window): ';
      status=get_string(filename, message_string, FILE_ARG);
      clear_message();
   }
   filename=maybe_quote_filename(filename);
   if (_no_child_windows()) {
      status=edit(filename);
   } else {
      int wid=p_window_id;
      next_window();
      if (p_window_id==wid) {
         if (_mdi.p_child.p_window_state=='M') {
            hsplit_window();
            status=edit(filename);
         } else {
            status=edit(' +w 'filename);
         }
      } else {
         status=edit(filename);
      }
      if (status) {
         message(get_message(status));
         return(status);
      }
   }
   //Had to do it this way because of a bug in p_read_only_mode?
   p_readonly_mode=true;
   p_readonly_set_by_user=true;
   return(status);
}


/*
 *Function Name: page_down_next_window
 *
 *Parameters:  none
 *
 *Description: This works only if there is a "next window"

               This does a page_down in the next_window()
 *
 *Returns:  0 if successful, otherwise 1.
 *
 */

_command int page_down_next_window() name_info(','VSARG2_EDITORCTL|VSARG2_MARK|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
//A-PgDn
{
   if (_no_child_windows()) {
      //No child windows
      return(1);
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return(1);
   }
   int wid=p_window_id;
   next_window();
   if (p_window_id!=wid) {
      page_down();
      prev_window();
   }
   return(0);
}

/*
 *Function Name: page_up_next_window
 *
 *Parameters:  none
 *
 *Description: This works only if there is a "next window"

               This does a page_up in the next_window()
 *
 *Returns:  0 if successful, otherwise 1.
 *
 */
_command int page_up_next_window() name_info(','VSARG2_EDITORCTL|VSARG2_MARK|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
//A-PgUp
{
   if (_no_child_windows()) {
      //No child windows
      return(1);
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return(1);
   }
   int wid=p_window_id;
   next_window();
   if (p_window_id!=wid) {
      page_up();
      prev_window();
   }
   return(0);
}

/*
 *Function Name: home_next_window
 *
 *Parameters:  none
 *
 *Description: This works only if there is a "next window"
               Goes to the top of the buffer in the next_window
 *
 *Returns:  0 if successful, otherwise 1.
 *
 */

_command int home_next_window() name_info(','VSARG2_EDITORCTL|VSARG2_MARK|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
//A-Home
{
   if (_no_child_windows()) {
      //No child windows
      return(1);
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return(1);
   }
   int wid=p_window_id;
   next_window();
   if (p_window_id!=wid) {
      top_of_buffer();
      prev_window();
   }
   return(0);
}
_command int end_next_window() name_info(','VSARG2_EDITORCTL|VSARG2_MARK|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
//A-End
{
   if (_no_child_windows()) {
      //No child windows
      return(1);
   }
   if (_mdi.p_child.p_window_state:=='M') {
      message('This operation is not supported if the window is maximized.');
      return(1);
   }
   int wid=p_window_id;
   next_window();
   if (p_window_id!=wid) {
      bottom_of_buffer();
      prev_window();
   }
   return(0);
}

/*
 *Function Name: center_paragraph
 *
 *Parameters: none
 *
 *Description:  This centers the current line (or selection) within the margins
 *
 *Returns:
 *
 */

_command void center_paragraph() name_info(','VSARG2_EDITORCTL|VSARG2_MARK)
//A-S-s
{
   if (!select_active()) {
      center_within_margins();
   } else {
      save_pos(auto p);
      end_select();
      int line=p_line;
      begin_select();
      while (p_line<=line) {
         center_within_margins();
         down();
      }
      restore_pos(p);
   }
}

//This is so that I don't have to write this for every shell command.
//It shells the command, edits the temporary file, and returns an int.
static int shell_it(_str cmd)
{
   /* Now make a temporary file to hold the output from the shell */
   //start=(int)substr(strip_filename(temp_in,'EP'),7)+1;
   //temp_out=mktemp(start);
   _str temp_out=mktemp();
   typeless status=buf_match(temp_out,1);
   if (status:!='') {
      edit('+b 'maybe_quote_filename(temp_out));
      p_modify=0;
      quit();
   }
   if ( temp_out=='' ) {
      message('Unable to make temp file');
      status=1;
      return(status);
   }
   temp_out=absolute(temp_out);    /* Do this in case the working directory changes */

   //messageNwait(nls('cmd=%s temp_in=%s temp_out=%s',cmd,temp_in,temp_out));
   shell(cmd' >'temp_out,'Q');
   if ( file_match(temp_out,1)!=temp_out ) {
      message('Error opening results of shell command');
      status=1;
      return(status);
   } else {
      /* Success */
      //messageNwait('def_one_file='def_one_file);
      if (!_no_child_windows()) {
         one_window();
         hsplit_window();
      }
      status=edit('-w 'maybe_quote_filename(temp_out));
      if (status) {
         message('Error opening output file for display.');
         return(status);
      }

      //old_line=p_line;
      ////cut('','','z');
      //old_line_insert=def_line_insert;
      //if ( p_line!=old_line ) {
      //   /* The end of the mark was at the bottom of the buffer, so insert AFTER */
      //   def_line_insert='A';
      //} else {
      //   def_line_insert='B';
      //}
      //get(temp_out, '', '', 0, 0, '+d');
      //if ( def_line_insert=='A' ) {
      //   down();      // Must move down so we are back where we started
      //}
      //def_line_insert=old_line_insert;     /* Quick, change it back */
      _ReloadCurFile(p_window_id,'',false,false,temp_out);
      p_modify=false;

      /* Now delete the temp files */
      status=delete_file(temp_out);
      if ( status ) {
         message('Error deleting temp file: 'temp_out);
         return(status);
      }
      window_above();
   }
   return(0);
}

_command int shell_command(_str command="")
//A-!
{
   if (command == "") {
      command=strip(prompt('','Enter command to shell'));
   }
   int status=shell_it(command);
   return(status);
}

/*
 *Function Name: move_window_line
 *
 *Parameters:  line number
 *
 *Description: centers the current line to the current window.
               If argument is a number, it will put the cursor on
               that relative line.
 *
 *Returns: nothing
 *
 */

_command void move_window_line()
//A-r
{
   if (arg(1):==''||!isinteger(arg(1))||arg(1)==0) {
      p_cursor_y=p_client_height intdiv 2;
   } else {
      if (arg(1)>0) {
         p_cursor_y=p_font_height*arg(1);
      } else {
         p_cursor_y=p_client_height-p_font_height*abs(arg(1));
      }
   }
}

/*
 *Function Name: gnu_select_argument
 *
 *Parameters:  Number of words to select.
 *
 *Description: selects (character) from the current point to the next word.
               if argument, it will select to that many words.
 *
 *Returns:
 *
 */

_command void gnu_select_argument()
{
   int i=0;
   if (arg(1):==''||!isinteger(arg(1))||arg(1)==0||arg(1)==1) {
      select_word();
   } else {
      _select_char('','CP');
      if (arg(1)>0) {
         for (i=1;i<arg(1);i++) {
            next_word();
         }
      } else {
         for (i=1;i<abs(arg(1));i++) {
            prev_word();
         }
      }
   }
}


/*
 *Function Name: zap_to_char
 *
 *Parameters:  none
 *
 *Description: prompts user to delete to certain character.
 *
 *Returns: nothing
 *
 */

_command void zap_to_char() name_info(','VSARG2_CMDLINE)
//A-z
{
   if (command_state()) {
      command_toggle();
   }
   _str ch='';
   _str text='Zap to char';
   _cmdline.set_command('',length(text),length(text),text': ');
   ch=get_event();
   _cmdline.set_command('',1,1,'');
//   if (ch:!=''||length(ch)>1) {
   if (length(ch)==1) {
      save_pos(auto p);
      int status=search(ch,'+IN@');
      if (!status) {
         right();
         _select_char('','CP');
         restore_pos(p);
         delete_selection();
      } else {
         restore_pos(p);
         message(nls('Character %s not found',ch));
      }
   } else {
      message('Invalid Character entered.');
   }
}

/*
 *Function Name: space_paren
 *
 *Parameters:  none
 *
 *Description: puts a space and an open paren into the file
 *
 *Returns: nothing
 *
 */

_command void space_paren() name_info(','VSARG2_READ_ONLY|VSARG2_EDITORCTL)
//A-(  (c-mode)
{
   if (get_text(1):==' ') {
      keyin('()');
   } else {
      keyin(' ()');
   }
   left();
}

/*Character selects the next word (continues a selection, if there is one and
"Extend selection as cursor moves" is on).*/
_command int select_next_word() name_info(','VSARG2_READ_ONLY|VSARG2_EDITORCTL|VSARG2_MARK)
//A-@
{
   typeless status=0;
   if (select_active() && upcase(_select_type()):=='CHAR' && pos('C',def_select_style)) {
      next_word();
   } else {
      if (select_active()) {
         //Don't want to select junk up until the next word.  Will select the
         //Preceding non-word character (if any).
         _deselect();
         _str search_string='([~'p_word_chars']|^)['p_word_chars']';
         typeless string, options, word_re, a4;
         save_search(string, options, word_re, a4);
         status=search(search_string,'@rh<');
         restore_search(string, options, word_re, a4);
         if (status) {
            return(status);
         }
      }
      select_word();
   }
   return(status);
}

/*
 *Function Name: enum_paste
 *
 *Parameters:  none.
 *
 *Description: cycles through the clipboard to paste into the current file
 *
 *Returns: nothing.
 *
 */

int _cbpaste=1;
int Nofnulls;

_command void enum_paste() name_info(','VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_MARK)
//A-y
{
   if (prev_index('')==last_index('')) {    //check if last command was enum_paste
      _cbpaste++;         //if so,increment which buffer to paste from
   } else {
      _cbpaste=1;
   }
   if (_cbpaste > Nofnulls) {     // wrap around
      _cbpaste=1;
   }
   typeless old_paste=def_deselect_paste;
   typeless old_select=def_persistent_select;
   def_persistent_select='D';
   def_deselect_paste=0;
   paste(_cbpaste);      //paste in the clipboard
   def_deselect_paste=old_paste;
   def_persistent_select=old_select;
   return;
}

static void gnu_replace_line_raw(_str line)
{
   if (p_indent_with_tabs) {
      typeless non_blank = verify( line," ");
      if ( non_blank ) {
         replace_line_raw( indent_string(text_col(line,non_blank,'I')-1) :+
                       substr(line,non_blank) );
      }
   } else {
      //p_indent_with_tabs is off.  Just replace the line normally.
      replace_line_raw(line);
   }
}


/*
 *Function Name: comint_run
 *
 *Parameters:
 *
 *Description: shells a command, and outputs stdout to a buffer.
 *
 *Returns:
 *
 */

_command comint_run()
{
   _str text='Run program: ';
   _str line="";
   get_string(line, text);
   typeless status=0;
   int index=find_index(line,COMMAND_TYPE);
   if (index) {
      //It's a SlickEdit command.
      status=call_index(index);
   } else {
      status=shell_it(line);
   }
   return(status);
}

/*
 *Function Name: gnu_filter
 *
 *Parameters:
 *
 *Description: This shells a command on the selected text.  If CHAR
               or BLOCK are the current selection, it changes them to
               LINE.

               Very much like the vi_filter command
 *
 *Returns:
 *
 */

_command int gnu_filter() name_info(','VSARG2_CMDLINE|VSARG2_EDITORCTL|VSARG2_LASTKEY|VSARG2_TEXT_BOX|VSARG2_MARK)
//A-|
{
   if (!select_active()) {
      message('There must be an active selection.');
      return(0);
   }
   if ( command_state() ) {
      cmdline_toggle();
   }
   _str orig=p_buf_name;
   _str cb_name='';
   typeless mark=_alloc_selection();
   typeless mark2=_duplicate_selection(mark);
   typeless old_mark=_duplicate_selection('');
   typeless status=0;
   if (mark<0) {
      message('Too many selections.');
      return(1);
   }
   if (lowcase(_select_type()):!='line') {
      _select_type('','T','LINE');
   }
   /* Use a loop here to give us an easy mechanism for breaking out */
   _str cmd="";
   for (;;) {
      _str lkey=last_event();
      //key=get_event();

      /* Now make a temporary file to hold the input to the shell and copy the marked lines into it */
      _str temp_in=mktemp();
      if ( temp_in=='' ) {
         _free_selection(mark);
         _free_selection(mark2);
         message('Unable to make temp file');
         status=1;
         break;
      }
      temp_in=absolute(temp_in);     /* Do this in case the working directory changes */
      //status=load_files('+t 'temp_in);
      status=put(temp_in);
      if ( status ) {
         _free_selection(mark);
         _free_selection(mark2);
         message(nls('Error writing to temporary file %s',temp_in));
         break;
      }

      /* Now prompt for the shell command to execute */
      //status=get_string(cmd,'! ');
      status=get_string(cmd,'command to shell');
      if ( status || cmd=='' ) {
         _free_selection(mark);
         break;
      }

      /* Now make a temporary file to hold the output from the shell */
      //start=(int)substr(strip_filename(temp_in,'EP'),7)+1;
      //temp_out=mktemp(start);
      _str temp_out=mktemp();
      status=buf_match(temp_out,1);
      if (status:!='') {
         edit('+b 'maybe_quote_filename(temp_out));
         p_modify=0;
         quit();
      }
      if ( temp_out=='' ) {
         _free_selection(mark);
         message('Unable to make temp file');
         status=1;
         break;
      }
      temp_out=absolute(temp_out);    /* Do this in case the working directory changes */

      //messageNwait(nls('cmd=%s temp_in=%s temp_out=%s',cmd,temp_in,temp_out));
      shell(cmd' <'temp_in' >'temp_out,'Q');
      if ( file_match(temp_out,1)!=temp_out ) {
         _free_selection(mark);
         message('Error opening results of shell command');
         status=1;
         break;
      } else {
         /* Success */
         //messageNwait('def_one_file='def_one_file);
         one_window();
         hsplit_window();
         status=edit('-w 'maybe_quote_filename(temp_out));
         if (status) {
            message('Error opening output file for display.');
            break;
         }
         _show_selection(mark);
         int old_line=p_line;
         //cut('','','z');
         _show_selection(old_mark);
         _free_selection(mark);
         typeless old_line_insert=def_line_insert;
         if ( p_line!=old_line ) {
            /* The end of the mark was at the bottom of the buffer, so insert AFTER */
            def_line_insert='A';
         } else {
            def_line_insert='B';
         }
         get(temp_out);
         if ( def_line_insert=='A' ) {
            down();      // Must move down so we are back where we started
         }
         def_line_insert=old_line_insert;     /* Quick, change it back */

         /* Now delete the temp files */
         status=delete_file(temp_in);
         if ( status ) {
            message('Error deleting temp file: 'temp_in);
            break;
         }
         status=delete_file(temp_out);
         if ( status ) {
            message('Error deleting temp file: 'temp_out);
            break;
         }
         window_above();
      }
      break;
   }
   _deselect();
   return(status);
}

/*
 *Function Name: gnu_c_rendent_selection
 *
 *Parameters:
 *
 *Description:
 *
 *Returns:
 *
 */

_command void gnu_c_rendent_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
//C-A-q  (c-mode)
{
   typeless p;
   _save_pos2(p);
   if (!select_active()) {
      gnu_ctab();
   } else {
      end_select(); end_line=p_line;
      begin_select();
      _deselect();
      for (;;) {
         _begin_line();
         gnu_ctab();
         down();
         if (p_line>=end_line) {
            break;
         }
      }
   }
   _restore_pos2(p);
}

_command void gnu_c_rendent_rigidly() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless p;
   _save_pos2(p);
   end_select(); 
   int end_line=p_line;
   begin_select(); 
   int start_line=p_line;
   _deselect();
   int start_col=_first_non_blank_col();
   gnu_ctab();
   int indention=_first_non_blank_col()-start_col;
   down();
   select_line(); p_line=end_line;
   if (indention<0) {
      shift_selection_left(abs(indention));
   } else {
      shift_selection_right(indention);
   }
   _deselect();
   _restore_pos2(p);
}

static boolean _no_code()
{
   int start_line=p_line;
   while (!up()) {
      _str line="";
      get_line(line);
      if (strip(line)=='') {
         continue;
      } else {
         p_line=start_line;
         return(0);
      }
   }
   p_line=start_line;
   return(1);
}

//This is the one that actually does the indention:
static void gnu_indent_on_ctab2(int syntax_indent, typeless column='')
{
   //syntax_indent=arg(1em);
   if ( _expand_tabsc(1,p_col-1)=='' ) {
      first_non_blank();
   }
   _str line="";
   get_line_raw(line);
   if (arg(2)==0) {
      gnu_replace_line_raw(strip(line,'L'));
      return;
   }
   typeless col1="";
   typeless col2="";
   if ( arg(2)!='' ) {
      col1=arg(2);
      col2=p_col;
      //messageNwait('here, col1='col1' col2='col2);
   } else {
      col2=p_col;
      col1=p_col+syntax_indent;
   }
   //_message_box(nls("col1=%s\ncol2=%s\nline=%s",col1,col2,line));
   typeless result=indent_string(col1-1):+_expand_tabsc_raw(col2,-1,'S');
   if ( result=='' && !LanguageSettings.getInsertRealIndent(p_LangId)) {
      result='';
   }
   //messageNwait('**'result'**');
   gnu_replace_line_raw(result);
   p_col=col1;
}

/*
 *Function Name: gnu_html_tab
 *
 *Parameters:  none
 *
 *Description: Indents from the cursor but not if prev line
   has no indentation.  Used as the indent-line-function
 *
 *Returns: 0 if it moved the text, otherwise 1.
 *
 */

_command int gnu_html_tab() name_info(','VSARG2_MARK)
//Tab  (html)
{
   if ( command_state() || _on_line0() || select_active() ) {
      call_root_key(TAB);
      return 0;
   }
   int start_col=p_col;
   int start_line=p_line;
   _str cur_line="";
   get_line_raw(cur_line);
   typeless status=up();
   if (status) {
      return(1);
   }
   _str line="";
   get_line_raw(line);
   while (strip(line):=='') {
      status=up();
      if (status) {
         p_line=start_line;
         return(1);
      }
      get_line_raw(line);
   }
   //Have a non-blank line.
   if (length(line) < start_col) {
      //It is past the EOL of the previous line, so I want to delete all the whitespace.
      p_line=start_line;
      gnu_delete_space();
   } else {
      if (get_text(1):==' ') {
         //I want to indent the line
         int i=pos('~[ \t]',line,start_col,'r');
         cur_line=substr(cur_line,1,start_col-1):+
                  substr('',1,i-start_col):+
                  substr(cur_line,start_col);
         p_line=start_line;
         p_col=i;
         gnu_replace_line_raw(cur_line);
      } else {
         //The line is non-empty, but the char isn't a space.
         p_line=start_line;
         return(1);
      }
   }
   return(0);
}

//refreshes a "List of" or "Directory of" listing
_command void gnu_fileman_refresh() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE)
//l (fileman-mode)
{
   if (command_state()) {
      _str key=last_event();
      if (isnormal_char(key)) {
         //A key was pressed on the command line
         keyin(key);
      }
      return;
   }
   if (p_LangId=='fileman') {
      typeless old_window_state=_mdi.p_child.p_window_state;
      _str buf_name=strip(p_buf_name,'B','"');
      if (buf_name == '') {
         buf_name=strip( p_DocumentName,'B','"');
      }
      _str word1="";
      _str rest="";
      parse buf_name with word1 . rest;
      word1=lowcase(word1);
      //_save_pos2(p);
      save_pos(auto p);
      p_modify=0;
      int old_x=0;
      int old_y=0;
      int old_height=0;
      if (old_window_state:=='N') {
         old_x=_mdi.p_child.p_x;
         old_y=_mdi.p_child.p_y;
         old_height=_mdi.p_child.p_height;
      }
      execute('quit');
      if (word1=='list') {
         execute('list 'maybe_quote_filename(rest));
      } else {
         execute('dir 'maybe_quote_filename(rest));
      }
      if (!_no_child_windows()) {
         _mdi.p_child.p_window_state=old_window_state;
         if (old_window_state:=='N') {
            _mdi.p_child.p_x=old_x;
            _mdi.p_child.p_y=old_y;
            _mdi.p_child.p_height=old_height;
         }
      }
      //_restore_pos2(p);
      restore_pos(p);
   }
}

_command gnu_fsort() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
//s (fileman mode)
{
   if (command_state()) {
      _str key=last_event();
      if (isnormal_char(key)) {
         //A key was pressed on the command line
         keyin(key);
      }
      return('');
   }
   return(fsort());
}
//  This command is not supported in a keyboard macro
_command void gnu_fileman_copy() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_CMDLINE)
//c (fileman mode)
{
   if (command_state()) {
      _str key=last_event();
      if (isnormal_char(key)) {
         //A key was pressed on the command line
         keyin(key);
      }
      return;
   }
   fileman_copy();
}

_command void gnu_unlist_select() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_CMDLINE)
//k (fileman mode)
{
   if (command_state()) {
      _str key=last_event();
      if (isnormal_char(key)) {
         //A key was pressed on the command line
         keyin(key);
      }
      return;
   }
   column_process_list(1,1,'^>','zap-line','r');
}

//This command will create two windows, and not do any of the "other window" stuff
_command void gnu_fileman_shell() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
//! (fileman mode)
{
   if (command_state()) {
      _str key=last_event();
      if (isnormal_char(key)) {
         //A key was pressed on the command line
         keyin(key);
      }
      return;
   }
   _str line="";
   get_line(line);
   if (strip(line)=='') {
      message('No file on this line');
      return;
   }
   _str filename=pcfilename(line);
   _str command=strip(prompt('','Enter command to shell on file 'filename));
   for (;;) {
      if (command=='') {
         command=strip(prompt('','Please enter a command to shell, or Ctrl-g to abort'));
      }
      if (command!='') {
         break;
      }
   }
   shell_it(command' 'filename);
   next_window();
   p_buf_name='Shelled output';
   prev_window();
}
_command sort_lines() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   typeless status=0;
   if (strip(arg(1))=='') {
      //Sort ascending:
      status=sort_buffer('A');
   } else {
      status=sort_buffer('D');
   }
   return(status);
}

_command sort_columns() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!select_active()) {
      message('There must be an active selection.');
      return(1);
   }
   if (strip(arg(1))=='') {
      return(sort_on_selection('A'));
   } else {
      return(sort_on_selection('D'));
   }
}
