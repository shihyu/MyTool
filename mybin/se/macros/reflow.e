////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "codehelp.e"
#import "javadoc.e"
#import "main.e"
#import "markfilt.e"
#import "recmacro.e"
#import "stdprocs.e"
#endregion

#define MAX_CHECK_FOR_BLANK_LINE_LEN 1000

/**
 * Reflows the text within the selection according to the margin settings.  
 * Character selection is not supported.
 * 
 * @return Returns 0 if successful.  Common return codes are 1 (buffer mark 
 * must be active), TOO_MANY_SELECTIONS_RC, 
 * TEXT_NOT_SELECTED_RC, and 
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC.  On error, 
 * message is displayed.
 * 
 * @see margins
 * @see gui_margins
 * @see reflow_paragraph
 * @see gui_justify
 * @see justify
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 * 
 */ 
_command reflow_selection(typeless new_right_margin="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION)
{
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   typeless p=0;
   int first_line=0, last_line=0;
   int first_col=0, last_col=0, buf_id=0;
   typeless junk="", utf8=0, encoding=0;
   _get_selinfo(first_col,last_col,buf_id,'',junk,utf8,encoding);
   if ( _select_type()=='CHAR' ) {
      // Convert it to a LINE selection
      if ( last_col==1 ) {
         // Discard the last line
         save_pos(p);
         _end_select();last_line=p_line;
         _begin_select();first_line=p_line;
         if ( last_line>first_line ) {
            _deselect();
            _select_line();
            down(last_line-first_line-1);
            _select_line();
         } else {
            // Do not know when we would hit this case
            _select_type('','T','LINE');
         }
         restore_pos(p);
      } else {
         _select_type('','T','LINE');
      }
   }
   if ( p_buf_id!=buf_id ) {
      message(nls('Buffer with selection must be active'));
      return(1);
   }
   _str old_margins=p_margins;
   if ( _select_type()=='BLOCK' ) {
      // Has a new right margin been chosen?
      if ( isinteger(new_right_margin) && new_right_margin>first_col ) {
        p_margins=first_col" "new_right_margin;
      } else {
        p_margins=first_col" "last_col;
      }
   }
   typeless left_margin="", right_margin="";
   parse p_margins with left_margin right_margin .;
   boolean old_indent_with_tabs=p_indent_with_tabs;
   p_indent_with_tabs=0;

   // This hocus pocus is to make sure the old buffer cursor position
   // information is saved.  The _create_temp_view() statement does not
   // save this information.  The _begin_select and _end_select calls
   // below need this.  Alternatively you could switch view before
   // calling _begin_select or _end_select
   _next_buffer('hr');_prev_buffer('hr');

   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_encoding=encoding;
   _delete_line();
   int temp_buf_id=p_buf_id;
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return(mark);
   }
   _reflow_selection();
   typeless status=rc;
   if ( status ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      _free_selection(mark);
      p_indent_with_tabs=old_indent_with_tabs;
      return(status);
   }
   _str line="";
   _str left_half="";
   _str right_half="";
   typeless mstyle="";
   save_select_style(mstyle);
   top();p_col=left_margin;
   select_it(_select_type(),mark);
   typeless old_mark=_duplicate_selection('');
   int Noflines_in_paragraph=0;
   int Noflines_in_new_paragraph=0;
   if ( _select_type()=='BLOCK' ) {
      bottom();p_col=right_margin;_select_block(mark);
      Noflines_in_new_paragraph=p_Noflines;
      Noflines_in_paragraph=count_lines_in_selection();
      _begin_select();p_margins=old_margins;
      if ( Noflines_in_new_paragraph>Noflines_in_paragraph ) {
         get_line_raw(line);
         left_half=expand_tabs(line,1,first_col-1,'S');
         right_half=expand_tabs(line,last_col+1);
         if ( left_half!=right_half ) {
            line='';
         } else {
            line=expand_tabs(left_half,1,last_col,'S'):+right_half;
         }
         _fill_selection(' ');
         int i;
         for (i=Noflines_in_paragraph; i<=Noflines_in_new_paragraph-1 ; ++i) {
            insert_line_raw(line);
         }
         _begin_select();
      } else {
         _fill_selection(' ');
      }
      _overlay_block_selection(mark);
      status=rc;
   } else {
     bottom();select_it(_select_type(),mark);
     _end_select();
     _copy_to_cursor(mark);
     status=rc;
     if ( !status ) {
       _delete_selection();
     }
   }
   load_files('+m +bi 'temp_buf_id);
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   _show_selection(mark);
   _free_selection(old_mark);
   p_indent_with_tabs=old_indent_with_tabs;
   restore_select_style(mstyle);
   return(status);
}
int reflow_fundamental(boolean curline_is_firstline_of_paragraph=false)
{
   /* find top of paragraph. */
   typeless leftmargin="", rightmargin="";
   parse p_margins with leftmargin rightmargin . ;
   typeless paragraph_mark_handle= _alloc_selection();
   if ( paragraph_mark_handle<0 ) {
     message(get_message(paragraph_mark_handle));
     return(paragraph_mark_handle);
   }
   _str line="";
   int i=0;
   if (!curline_is_firstline_of_paragraph) {
      for (;;) {
         if (_line_length()>MAX_CHECK_FOR_BLANK_LINE_LEN) {
            _begin_line();
            line=get_text(MAX_CHECK_FOR_BLANK_LINE_LEN);
         } else {
            get_line(line);
         }
        /* the '=' operator remove spaces from operands */
        /* before comparing them. */
        if ( _on_line0() ) { line=''; }
        if ( line=='' ) { break; }
        up();
        if ( rc ) { break; }  /* reached top of file? */
        i=i+1;
      }
      if ( i && line=='' ) {
        /* sitting on a blank line which was not the current line. */
        down();i=i-1;
      }
   }
   _select_line(paragraph_mark_handle);
   down(i); /* put the cursor back where it was. */
   /* find bottom of paragraph */
   i=0;
   for (;;) {
      if (_line_length()>MAX_CHECK_FOR_BLANK_LINE_LEN) {
         _begin_line();
         line=get_text(MAX_CHECK_FOR_BLANK_LINE_LEN);
      } else {
         get_line(line);
      }
      /* the '=' operator remove spaces from operands */
      /* before comparing them. */
      if ( _on_line0() ) { line=''; }
      if ( line=='' ) { break; }
      down();
      if ( rc ) { break; }  /* reached bottom of file? */
      i=i+1;
   }
   if ( i && line=='' ) {
     /* sitting on a blank line which was not the current line. */
     up();i=i-1;
   }
   _select_line(paragraph_mark_handle);
   up(i);
   _reflow_selection(paragraph_mark_handle);
   if ( rc ) {
     _free_selection(paragraph_mark_handle);
     message(get_message(rc));
     return(rc);
   }
   /* this begin mark helps to avoid unnecessary screen movement */
   /* by restoring cursory. Only useful if top of paragraph seen on screen */
   _begin_select(paragraph_mark_handle);
   _delete_selection(paragraph_mark_handle);
   _free_selection(paragraph_mark_handle);
   if ( def_reflow_next ) {
      /* Find the beginning of the next paragraph */
      _str paragraph_re='([\t ]*$|'p_newline')';
      search('^'paragraph_re,'@rh');
      if ( ! rc ) {
         search('^~'paragraph_re,'@rh');
      }
      clear_message();
   } else {
      int Noflines_down=0, col=0;
      _get_reflow_pos(Noflines_down,col);
      if ( Noflines_down>=0 ) {
        down (Noflines_down);
        p_col=col;
      }
   }
   return 0;
}
/**
 * Reflows the text of the current paragraph according to the margin 
 * settings.  Paragraphs are assumed to be separated by at least one blank 
 * line.  However, paragraphs in a Javadoc comment do not need to be 
 * terminated by a blank line.  By default, the cursor position within the 
 * paragraph is preserved.  If you want this command to place the cursor 
 * on the next paragraph after completing, invoke the command "<b>set-
 * var def-reflow-next 1</b>".
 * 
 * @return Returns 0 if successful.  Common return codes are 1 (buffer with mark 
 * must be active), and TOO_MANY_SELECTIONS_RC.  On error, 
 * message is displayed.
 * 
 * @see margins
 * @see gui_margins
 * @see reflow_selection
 * @see gui_justify
 * @see justify
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void reflow_paragraph() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (_inJavadoc()) {
      javadoc_reflow();
   } else {
      reflow_fundamental();
   }
}
_command void reflow_hanging_indent() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str old_margins=p_margins;
   int old_word_wrap_style=p_word_wrap_style;
   _str left_ma,right_ma,newpar_ma;
   
   parse p_margins with left_ma right_ma newpar_ma;
   if (p_col>=(int)right_ma-1) {
      message('cursor position at or after right margin');
      return;
   }
   save_pos(auto p);
   first_non_blank();
   int fnb_col=p_col;
   restore_pos(p);
   p_margins=p_col' 'right_ma' 'fnb_col;
   p_word_wrap_style|=WORD_WRAP_WWS;
   if (fnb_col<p_col) {
      /*
         Convert blanks between first non-blank and cursor to
         x's to preverse spaces and prevent cursor position
         from change.
      */
      int orig_col=p_col;
      _str orig_text=_expand_tabsc(fnb_col,p_col-fnb_col,'S');
      replace_line(_expand_tabsc(1,fnb_col-1,'S'):+
                   substr('',1,p_col-fnb_col,'x'):+
                   _expand_tabsc(p_col,-1,'S'));
      reflow_fundamental(true);
      replace_line(_expand_tabsc(1,fnb_col-1,'S'):+
                   orig_text:+
                   _expand_tabsc(orig_col,-1,'S'));

   } else {
      reflow_fundamental(true);
   }
   p_margins=old_margins;
   p_word_wrap_style=old_word_wrap_style;
   //_message_box('done');
}

/** 
 * Displays and optionally sets the tabs for the current buffer.  The 
 * <b>Tabs dialog box</b> prompts you for the tab stops.
 * 
 * @see tabs
 * 
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command gui_tabs() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   // Check if the tabs are in increments of a specific value
   typeless result=show('-modal _textbox_form',
        'Tabs',               // Caption
         0,                   // flags
         0,                   // Default text box width
         'tabs dialog box',   // help item
         '',                  // Buttons and captions
         'gui_tabs',          // retrieve name
         '-e _check_tabs:'p_window_id' Tabs:'p_tabs  /* First prompt */
         );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   p_tabs=_param1;
   _macro('m',_macro('s'));
   _macro_call('tabs',_param1);
   if (!_QReadOnly()) {
      update_format_line();
   }
}

/**
 * This command sets the left, right, and new paragraph margins for the 
 * current buffer.  For convenience, we decided to turn word wrap on when the 
 * margins are set.  Each buffer has one set of margins.  The <b>Margins dialog 
 * box</b> is displayed to prompt you for the new margins.  To set up different 
 * initial margins for specific file extensions, use the <b>Extension Options 
 * dialog box</b> ("Tools", Configuration...", "File Extension Setup...", select 
 * the Word Wrap tab).
 * 
 * @see margins
 * @see reflow_paragraph
 * @see reflow_selection
 * @see gui_justify
 * @see justify
 * 
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command gui_margins() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   typeless left_ma="", right_ma="", new_para_ma="";
   parse p_margins with left_ma right_ma new_para_ma ;
   new_para_ma=strip(new_para_ma);
   _macro_delete_line();
   typeless result = show('-modal _textbox_form',
                 'Margins',      // Form caption
                 0,              //flags
                 '',             //use default textbox width
                 'margins dialog box',  //Help item.
                 '',             //Buttons and captions
                 'gui_margins',  //Retieve Name
                 '-E1 _check_margins Left margin:'left_ma,
                 'Right margin:'right_ma,
                 'New paragraph margin:'new_para_ma);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str m=_param1' '_param2' '_param3;
   margins(m);
   _macro('m',_macro('s'));
   _macro_call('margins',m);
}
/**
 * @param cmdline is a string in the format <i>left </i>[<i>right
 * </i>[<i>new-paragraph</i>]]
 * 
 * <p>The <b>ma</b> or <b>margins</b> command sets the left, right, and new 
 * paragraph margins.  Each buffer has one set of margins.  To set up different 
 * initial margins for specific file extensions, use the <b>Extension Options 
 * dialog box</b> ("Tools", Configuration...", "File Extension Setup...", select 
 * the Word Wrap tab).</p>
 * 
 * @see gui_margins
 * @see reflow_paragraph
 * @see reflow_selection
 * @see gui_justify
 * @see justify
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void ma,margins(_str cmdline="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
  set_margins_or_tabs(cmdline,'margins');

}
/**
 * <p>Sets up to tab stops in increasing order.  The commands <b>ctab</b> 
 * and <b>cbacktab</b> may be used to move between tab stops.  The '+' 
 * symbol is used to set tabs according to an increment value.  Tab stops 
 * continue past the last tab stop by repeating the difference of the last 
 * two tab stop values.</p>
 * 
 * <p>Command line examples:</p>
 * 
 * <dl> 
 * <dt>tabs 1 7 13 16</dt><dd>Creates tab stops 1 7 13 16 19 21 
 * 24 ...</dd>
 * <dt>tabs +3</dt><dd>Creates tab stops 1 4 7 ...</dd>
 * <dt>tabs 1 4</dt><dd>Creates tab stops 1 4 7 ...</dd>
 * <dt>tabs 1 49 +3</dt><dd>Creates tab stops 1 4 7 ...</dd>
 * <dt>tabs 1 49 +3 53 250 +4</dt><dd>Creates tab stops 1 4 7 ... 49 53 57 
 * 61 65 69 ...</dd>
 * <dt>tabs 10 +3</dt><dd>Creates tab stops 10 13 16 ...</dd>
 * </dl>
 * 
 * @param cmdline is a string in the format: [+<i>t1</i>]: [+<i>t2</i>]: 
 * [+<i>t3</i>] ... 
 * 
 * @see ctab
 * @see cbacktab
 * @see move_text_tab
 * @see gui_tabs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void tabs(_str cmdline="") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
  set_margins_or_tabs(cmdline,'tabs');

}
static _str set_margins_or_tabs(_str cmdline,_str command)
{
   _str cur_val="";
  cmdline=strip(cmdline,'L','=');
  if ( cmdline=='' ) {
    if ( command=='tabs' ) { cur_val=p_tabs; } else { cur_val=p_margins; }
    cmdline=prompt('',upcase(substr(command,1,1))substr(command,2),strip(cur_val),1);
  }
  rc=0;
  if ( command=='tabs' ) {
     p_tabs= cmdline;
  } else {
     p_margins=cmdline;
     if (!rc) {
        typeless lm="", rm="", nm="";
        parse p_margins with lm rm nm ;
        if (lm==1 && rm==254 && nm==1 && (p_word_wrap_style&WORD_WRAP_WWS)) {
           message('Word wrap has been turned OFF');
           p_word_wrap_style&=~WORD_WRAP_WWS;
        } else if (!(p_word_wrap_style&WORD_WRAP_WWS)) {
           message('Word wrap has been turned ON');
           p_word_wrap_style|=WORD_WRAP_WWS;
        }
     }
  }
  if (rc) {
     message(get_message(rc));
  }
  if (!_QReadOnly()) {
     update_format_line();
  }
  return(0);
}
