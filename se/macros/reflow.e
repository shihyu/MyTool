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
#import "stdcmds.e"
#endregion

static const MAX_CHECK_FOR_BLANK_LINE_LEN= 1000;


bool _BlockSelHasTextAfterEndCol(_str markid='',bool count_nosave_lines=false)
{
   int orig_wid;
   get_window_id(orig_wid);
   start_col := end_col := buf_id := 0;
   int status=_get_selinfo(start_col,end_col,buf_id,markid);
   if (status) {
      return(false);
   }
   int columnStartPixel,columnEndPixel;
   _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,markid);
   typeless orig_pos;
   save_pos(orig_pos);
   prev_select_type := "";
   if(_select_type(markid, 'S') == 'C') {
      prev_select_type = 'C';
      _select_type(markid, 'S', 'E');
   }
   activate_window(VSWID_HIDDEN);
   int orig_buf_id=p_buf_id;
   p_buf_id=buf_id;
   status=_begin_select(markid);
   if ( status ) return(false);
   count := 0;
   textAfterEndCol := false;
   for (;;) {
      if (count_nosave_lines || !(_lineflags()&NOSAVE_LF)) {
         ++count;
      }
      _BlockSelGetStartAndEndCol(start_col,end_col,columnStartPixel,columnEndPixel,markid);
      if (_expand_tabsc(end_col)!='') {
         textAfterEndCol=true;
         break;
      }
      status=down();
      if ( status || _end_select_compare(markid)>0 ) {
         break;
      }
   }
   p_buf_id=orig_buf_id;
   activate_window(orig_wid);
   restore_pos(orig_pos);
   if (prev_select_type != '') {
      _select_type(markid, 'S', prev_select_type);
   }
   return(textAfterEndCol);
}

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
_command reflow_selection(typeless new_right_margin="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_AB_SELECTION)
{
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   typeless p=0;
   first_line := last_line := 0;
   first_col := last_col := buf_id := 0;
   typeless junk="", utf8=0, encoding=0;
   _get_selinfo(first_col,last_col,buf_id,'',junk,utf8,encoding);
   int columnStartPixel,columnEndPixel;
   if (_select_type()=='BLOCK') {
      _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel);
      if (columnStartPixel>=0 && _BlockSelHasTextAfterEndCol()) {
         message("Proportional font reflow paragraph can't preserve text on right of Block selection");
         return -1;
      }
      _BlockSelGetStartAndEndCol(first_col,last_col,columnStartPixel,columnEndPixel);
      if (columnStartPixel>=0) {
         last_col=columnEndPixel intdiv p_font_width;
      }
      --last_col;  // Margins are inclusive and this is not so fix it
   }
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
   old_AutoLeftMargin := p_AutoLeftMargin;  // Might be turning this off for BLOCK selection
   _str old_margins=p_margins;
   if ( _select_type()=='BLOCK' ) {
      p_AutoLeftMargin=false;  // Want p_margins to be used by _reflow_selection()
      // Has a new right margin been chosen?
      if ( isinteger(new_right_margin) && new_right_margin>first_col ) {
        p_margins=first_col" "new_right_margin;
      } else {
        p_margins=first_col" "last_col;
      }
   }
   typeless left_margin="", right_margin="";
   parse p_margins with left_margin right_margin .;
   old_indent_with_tabs := p_indent_with_tabs;
   p_indent_with_tabs=false;

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
      p_AutoLeftMargin=old_AutoLeftMargin;
      return(mark);
   }
   _reflow_selection();
   typeless status=rc;
   if ( status ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      _free_selection(mark);
      p_indent_with_tabs=old_indent_with_tabs;
      p_AutoLeftMargin=old_AutoLeftMargin;
      return(status);
   }
   line := "";
   left_half := "";
   right_half := "";
   typeless mstyle="";
   save_select_style(mstyle);
   top();p_col=left_margin;
   select_it(_select_type(),mark);
   typeless old_mark=_duplicate_selection('');
   Noflines_in_paragraph := 0;
   Noflines_in_new_paragraph := 0;
   if ( _select_type()=='BLOCK' ) {
      bottom();p_col=right_margin;_select_block(mark);
      Noflines_in_new_paragraph=p_Noflines;
      Noflines_in_paragraph=count_lines_in_selection();
      _begin_select();p_margins=old_margins;
      if ( Noflines_in_new_paragraph>Noflines_in_paragraph ) {
         // Get the first line of the source
         get_line_raw(line);
         left_half=expand_tabs(line,1,first_col-1,'S');
         right_half=expand_tabs(line,last_col+1);
         // IF the text to the left and right of the first line is not the same
         //    OR we are dealing with proportional font where we can't rely on
         //       spaces
         if ( left_half!=right_half || columnStartPixel>=0) {
            // Insert blank lines
            line='';
         } else {
            // Add lines with borders
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
      _overlay_block_selection(mark,VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE,'');
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
   p_AutoLeftMargin=old_AutoLeftMargin;
   restore_select_style(mstyle);
   return(status);
}
int reflow_fundamental(bool curline_is_firstline_of_paragraph=false)
{
   /* find top of paragraph. */
   typeless paragraph_mark_handle= _alloc_selection();
   if ( paragraph_mark_handle<0 ) {
     message(get_message(paragraph_mark_handle));
     return(paragraph_mark_handle);
   }
   line := "";
   i := 0;
   AutoLeftMarginCol := 0;
   if (!curline_is_firstline_of_paragraph) {
      // Skip blank lines
      NofBlankLines := 0;
      for (;;) {
         if (_line_length()>MAX_CHECK_FOR_BLANK_LINE_LEN) {
            _begin_line();
            line=get_text(MAX_CHECK_FOR_BLANK_LINE_LEN);
         } else {
            get_line(line);
         }
         if ( _on_line0()) line='';
         if (line!='') break;
         if (down()) break;
         ++NofBlankLines;
      }

      for (;;) {
         if (_line_length()>MAX_CHECK_FOR_BLANK_LINE_LEN) {
            _begin_line();
            line=get_text(MAX_CHECK_FOR_BLANK_LINE_LEN);
         } else {
            get_line(line);
         }
        /* the '=' operator remove spaces from operands */
        /* before comparing them. */
        if ( _on_line0() ) line='';
        if ( line=='' ) break;
        if (p_AutoLeftMargin) {
           if (!AutoLeftMarginCol) {
              if (line!='') {
                 save_pos(auto p);
                 _first_non_blank();
                 AutoLeftMarginCol=p_col;
                 restore_pos(p);
              }
           } else {
              save_pos(auto p);
              _first_non_blank();
              new_col := p_col;
              restore_pos(p);
              if (AutoLeftMarginCol!=new_col) {
                 line='';
                 break;
              }
           }
        }
        int status=up();
        if ( status ) break;  /* reached top of file? */
        i++;
      }
      if ( i && line=='') {
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
      if ( _on_line0() ) line='';
      if ( line=='' ) break;
      if (p_AutoLeftMargin) {
         if (!AutoLeftMarginCol) {
            if (line!='') {
               save_pos(auto p);
               _first_non_blank();
               AutoLeftMarginCol=p_col;
               restore_pos(p);
            }
         } else {
            save_pos(auto p);
            _first_non_blank();
            new_col := p_col;
            restore_pos(p);
            if (AutoLeftMarginCol!=new_col) {
               line='';
               break;
            }
         }
      }
      int status=down();
      if ( status ) break;  /* reached bottom of file? */
      i++;
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
      paragraph_re := '([\t ]*$|'p_newline')';
      search('^'paragraph_re,'@rh');
      if ( ! rc ) {
         search('^~'paragraph_re,'@rh');
      }
      clear_message();
   } else {
      Noflines_down := col := 0;
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
_command void reflow_paragraph() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   if (_inJavadoc()) {
      javadoc_reflow();
   } else {
      reflow_fundamental();
   }
}
_command void reflow_hanging_indent() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   old_AutoLeftMargin := p_AutoLeftMargin;
   _str old_margins=p_margins;
   int old_word_wrap_style=p_word_wrap_style;

   int left_ma,right_ma;
   if(_getAutoMargins(left_ma,right_ma)) {
      message('bad margins settings');
      return;
   }
   if (p_col>=(int)right_ma-1) {
      message('cursor position at or after right margin');
      return;
   }
   save_pos(auto p);
   _first_non_blank();
   fnb_col := p_col;
   restore_pos(p);
   p_AutoLeftMargin=false;
   p_margins=p_col' 'right_ma' 'fnb_col;
   p_word_wrap_style|=WORD_WRAP_WWS;
   if (fnb_col<p_col) {
      /*
         Convert blanks between first non-blank and cursor to
         x's to preverse spaces and prevent cursor position
         from change.
      */
      orig_col := p_col;
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
   p_AutoLeftMargin=old_AutoLeftMargin;
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
defeventtab _margins_form;

void ctlok.lbutton_up() {
   _str cur_val;
   if (ctlAutomaticRadio.p_value) {
      if (ctlAutoFixedWidthRightMarginRadio.p_value) {
         if (!isinteger(ctlAutoFixedWidthRightMargin.p_text) || ctlAutoFixedWidthRightMargin.p_text<3 || ctlAutoFixedWidthRightMargin.p_text>MAX_LINE) {
            _message_box('Invalid fixed width right margin');
            ctlAutoFixedWidthRightMargin._set_focus();
            return;
         }
         cur_val=ctlAutoFixedWidthRightMargin.p_text:+'w';
      } else {
         cur_val=ctlAutoFixedRightColumn.p_text;
         if (!isinteger(ctlAutoFixedRightColumn.p_text) || ctlAutoFixedRightColumn.p_text<3 || ctlAutoFixedRightColumn.p_text>MAX_LINE) {
            _message_box('Invalid fixed right column');
            ctlAutoFixedRightColumn._set_focus();
            return;
         }
      }
   } else {
      if (!isinteger(ctlFixedLeftColumn.p_text) || ctlFixedLeftColumn.p_text<1 || ctlFixedLeftColumn.p_text>MAX_LINE) {
         _message_box('Invalid fixed left column');
         ctlFixedLeftColumn._set_focus();
         return;
      }
      if (!isinteger(ctlFixedRightColumn.p_text) || ctlFixedRightColumn.p_text<1 || ctlFixedRightColumn.p_text>MAX_LINE) {
         _message_box('Invalid fixed right column');
         ctlFixedRightColumn._set_focus();
         return;
      }
      if ( (int)ctlFixedLeftColumn.p_text+2>(int)ctlFixedRightColumn.p_text) {
         _message_box('Right margin must be greater than left margin');
         ctlFixedRightColumn._set_focus();
         return;
      }
      if (!isinteger(ctlNewParagraphLeftColumn.p_text) || ctlNewParagraphLeftColumn.p_text<1 || ctlNewParagraphLeftColumn.p_text>MAX_LINE) {
         _message_box('Invalid new paragraph left column');
         ctlNewParagraphLeftColumn._set_focus();
         return;
      }
      cur_val=ctlFixedLeftColumn.p_text' 'ctlFixedRightColumn.p_text' 'ctlNewParagraphLeftColumn.p_text;
   }
   if (ctlpartial.p_value) {
      cur_val='+p 'cur_val;
   } else {
      cur_val='-p 'cur_val;
   }
   p_active_form._delete_window(cur_val);
}
void ctlok.on_create(int editorctl_wid=0) {
   if (!editorctl_wid) {
      if (p_parent._isEditorCtl()) {
         editorctl_wid=p_parent;
      } else {
         editorctl_wid=_mdi.p_child;
         //editorctl_wid=_tbGetActiveChild();
      }
   }
   typeless left_ma="", right_ma="", new_para_ma="";
   parse editorctl_wid.p_margins with left_ma right_ma new_para_ma ;
   new_para_ma=strip(new_para_ma);
   ctlFixedLeftColumn.p_text=left_ma;
   ctlNewParagraphLeftColumn.p_text=new_para_ma;
   ctlFixedRightColumn.p_text=right_ma;

   ctlAutoFixedRightColumn.p_text=right_ma;
   ctlAutoFixedWidthRightMargin.p_text=right_ma;

   if (editorctl_wid.p_AutoLeftMargin) {
      ctlAutomaticRadio.p_value=1;
   } else {
      ctlFixedLeftColumnRadio.p_value=1;
   }
   if (editorctl_wid.p_FixedWidthRightMargin) {
      ctlAutoFixedRightColumnRadio.p_value=0;
      ctlAutoFixedWidthRightMarginRadio.p_value=1;
      ctlAutoFixedWidthRightMargin.p_text=editorctl_wid.p_FixedWidthRightMargin;
   } else {
      ctlAutoFixedRightColumnRadio.p_value=1;
      ctlAutoFixedWidthRightMarginRadio.p_value=0;
   }
   ctlpartial.p_value=(editorctl_wid.p_word_wrap_style & PARTIAL_WWS)?1:0;
}

void _margins_form_set_enabled() {
   automatic := ctlAutomaticRadio.p_value!=0;

   //ctlFixedLeftColumnRadio.p_enabled=!automatic;
   ctlFixedLeftColumn.p_enabled=!automatic;
   ctlNewParagraphLeftColumnLabel.p_enabled=!automatic;
   ctlNewParagraphLeftColumn.p_enabled=!automatic;
   ctlFixedRightColumnLabel.p_enabled=!automatic;
   ctlFixedRightColumn.p_enabled=!automatic;

   ctlAutoFixedRightColumnRadio.p_enabled=automatic;
   ctlAutoFixedWidthRightMarginRadio.p_enabled=automatic;
   ctlAutoFixedRightColumn.p_enabled=automatic && ctlAutoFixedRightColumnRadio.p_value;
   ctlAutoFixedWidthRightMargin.p_enabled=automatic && ctlAutoFixedWidthRightMarginRadio.p_value;

}
void ctlAutoFixedWidthRightMarginRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlAutoFixedRightColumnRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlAutomaticRadio.lbutton_up() {
   _margins_form_set_enabled();
}
void ctlFixedLeftColumnRadio.lbutton_up() {
   _margins_form_set_enabled();
}

/**
 * This command sets the left, right, and new paragraph margins for the 
 * current buffer.  For convenience, we decided to turn word wrap on when the 
 * margins are set.  Each buffer has one set of margins.  The <b>Margins dialog 
 * box</b> is displayed to prompt you for the new margins. 
 *  
 * To set up different initial margins for specific language modes, use the 
 * Options dialog ("Document", "[Language] Options...]", "Word Wrap".
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
   _str result= p_window_id.show('-modal _margins_form');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   margins(result);
   _macro('m',_macro('s'));
   _macro_call('margins',result);
}
/** 
 * Sets margin options 
 *  
 * @param cmdline is a string in one of the following formats:
 * <dl> 
 *    <dt><b>[+p|-p] left-margin right-margin new-paragraph-margin</b></dt>
 *    <dd>Sets left, right, and new paragraph margins to the value specified</dd>
 *    <dt><b>[+p|-p] right-margin</b></dt>
 *    <dd>Specifies auto left margin and fixed column right margin</dd>
 *    <dt><b>[+p|-p] 80w or w80</b></dt>
 *    <dd>Specifies auto left margin and fixed width right margin</dd>
 * </dl> 
 *  
 * When +p is specified. Partial word wrapping is turned on. When -p is 
 * specified partial word wrapping is turned off. When partial word wrap 
 * is on and typing characters, current line text is not appended with 
 * previous line and next line text is not appended to current line. 
 * This option provides word wrap similary to previous versions of 
 * SlickEdit. The partial word wrap option only effects word wrap when typing characters.
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
   typeless lm="", rm="", nm="";
   cur_val := "";
  cmdline=strip(cmdline,'L','=');
  if ( cmdline=='' ) {
    if ( command=='tabs' ) { 
       cur_val=p_tabs; 
    } else {
       if (p_AutoLeftMargin) {
          if (p_FixedWidthRightMargin) {
             cur_val=p_FixedWidthRightMargin'w';
          } else {
             parse p_margins with lm rm nm ;
             cur_val=rm;
          }
       } else {
          cur_val=p_margins; 
       }
       if (p_word_wrap_style & PARTIAL_WWS) {
          cur_val='+p 'cur_val;
       }
    }
    cmdline=prompt('',upcase(substr(command,1,1))substr(command,2),strip(cur_val),1);
  }
  rc=0;
  if ( command=='tabs' ) {
     p_tabs= cmdline;
  } else {
     /* 
         Syntax:
              [+p|-p] left-margin right-margin new-paragraph-margin
              [+p|-p] right-margin   <-- Specifies auto left margin and fixed column right margin
              [+p|-p] 80w or w80     <-- Specifies auto left margin and fixed width right margin
      
     */
     parse cmdline with auto first_word auto rest;
     if (first_word=='-p') {
        p_word_wrap_style&=~PARTIAL_WWS;
        cmdline=rest;
     } else if (first_word=='+p') {
        p_word_wrap_style|=PARTIAL_WWS;
        cmdline=rest;
     }
     // IF auto left margin and fixed column right margin specified
     if (isinteger(cmdline)) {
        p_AutoLeftMargin=true;
        if (!isinteger(cmdline) || cmdline<3) {
           message("Invalid right margin");
           return 1;
        }
        p_margins=1' 'cmdline;
        p_AutoLeftMargin=true;
        p_FixedWidthRightMargin=0;
        if (!(p_word_wrap_style&WORD_WRAP_WWS)) {
           message('Word wrap has been turned ON');
           p_word_wrap_style|=WORD_WRAP_WWS;
        }
     } else if (pos('w',cmdline,1,'i')) {
        typeless right_margin=stranslate(cmdline,'','w','i');
        if (!isinteger(right_margin) || right_margin<4) {
           message("Invalid fixed width right margin");
           return 1;
        }
        p_AutoLeftMargin=true;
        //p_margins=1' 'right_margin;
        p_FixedWidthRightMargin=right_margin;
        if (!(p_word_wrap_style&WORD_WRAP_WWS)) {
           message('Word wrap has been turned ON');
           p_word_wrap_style|=WORD_WRAP_WWS;
        }
     } else {
        p_margins=cmdline;
        if (!rc) {
           parse p_margins with lm rm nm ;
           wordwrap_turned_off := false;
           if (lm==1 && rm==254 && nm==1 && (p_word_wrap_style&WORD_WRAP_WWS)) {
              wordwrap_turned_off=true;
              message('Word wrap has been turned OFF');
              p_word_wrap_style&=~WORD_WRAP_WWS;
           } else if (!(p_word_wrap_style&WORD_WRAP_WWS)) {
              message('Word wrap has been turned ON');
              p_word_wrap_style|=WORD_WRAP_WWS;
           }
           if (!wordwrap_turned_off) {
              p_AutoLeftMargin=false; 
              //p_FixedWidthRightMargin=0; 
           }
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
