////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47844 $
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
#import "fileman.e"
#import "main.e"
#import "optionsxml.e"
#import "stdcmds.e"                 
#import "stdprocs.e"
#import "util.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  This module contains filtering procedures which support filtering of
  line, block, or character marks.


  status=filter_selection(proc_or_command_name)

         find index for proc or command filter.  If not found
         PROCEDURE_NOT_FOUND_RC is returned.  Otherwise 0 is returned.

  filter_init()                     initialize filter process

  status=filter_get_string(var string)

        returns -1 if no more strings left to be filtered. otherwise returns 0

  filter_put_string(string)

       replaces text returned by filter_get_string with string.

  At the end of this module there are small examples which use the
  filter functions.

*/

static int  firstcol,lastcol,not_first_time;
static int  grightcol;
static _str  mtype;
static int  filter_view_id;
static int glinelen;
int _leftcol,_width;
_str markfilt_position_mark;
static boolean gdoRaw;


definit()
{
   if ( arg(1):!='L' ) {
       markfilt_position_mark='';
   }

}

/**
 * Saves the cursor position and prepares for calls to functions 
 * <b>filter_get_string</b>, <b>filter_put_string</b>, and 
 * <b>filter_restore_pos</b>.
 * 
 * @see filter_get_string
 * @see filter_put_string
 * @see filter_restore_pos
 * @see filter_selection
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
void filter_init(boolean doRaw=false)
{
   gdoRaw=doRaw;
  /* mark the users current file and cursor position */
  if ( markfilt_position_mark=='' ) {
    markfilt_position_mark= _alloc_selection();
  } else {
    _deselect(markfilt_position_mark);
  }
  _select_char(markfilt_position_mark);
  int view_id;
  get_window_id(view_id);
  _begin_select();
  gmarkfilt_utf8=p_UTF8;
  get_window_id(filter_view_id);
  int fileid;
  _get_selinfo(firstcol,lastcol,fileid);
  mtype=_select_type();
  if (mtype=="BLOCK" && p_TruncateLength && lastcol>p_TruncateLength) {
     if (lastcol>p_TruncateLength) {
        lastcol=p_TruncateLength;
     }
     if (firstcol>p_TruncateLength) {
        firstcol=p_TruncateLength;
        lastcol=p_TruncateLength-1;
     }
  }
  not_first_time=0;     /* Indicate that down should be not be invoked. */
  activate_window(view_id);

}


/**
 * Restores the cursor position to the position saved by the 
 * <b>filter_init</b> procedure.
 * 
 * @see filter_get_string
 * @see filter_put_string
 * @see filter_init
 * @see filter_selection
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
void filter_restore_pos()
{
   _begin_select(markfilt_position_mark);   /* restore users original cursor pos. */
   _free_selection(markfilt_position_mark);markfilt_position_mark='';

}

/**
 * Sets variable <i>in_string</i> to next partial line of selection being 
 * filtered.  A non-zero value is returned if all text in the selection has been 
 * filtered.  The procedure <b>filter_init</b> must be called before this 
 * function.
 * 
 * @return  Returns 0 if successful.  A non-zero value is returned if all 
 * text in the selection has been filtered.
 * 
 * @see filter_init
 * @see filter_put_string
 * @see filter_restore_pos
 * @see filter_selection
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_str filter_get_string(_str &string)
{
   int view_id;
   get_window_id(view_id);
   activate_window(filter_view_id);
   /* position on next line. */
   if ( not_first_time ) {
      down();
      if ( ! rc ) {
         /* test if we are past the end of the mark. */
         if ( _end_select_compare()>0 ) {
            rc= BOTTOM_OF_FILE_RC;
         } else {
            rc=0;
         }
      }
      if ( rc ) { /* already process last line? */
         activate_window(view_id);
         return(-1);
      }
   } else {
      not_first_time=1;
   }
   glinelen=_line_length();
   if ( mtype == 'LINE' ) {
      _leftcol=1;grightcol=_text_colc(0,'E');
   } else {
      if ( mtype == 'BLOCK' ) {
         _leftcol=firstcol;grightcol=lastcol;
         _end_line();
      } else {
         if ( _begin_select_compare()==0 ) {
            _leftcol= firstcol;
            if ( _end_select_compare()==0 ) {
               grightcol= lastcol-(int)(!_select_type('','I'));
            } else {
               if ( _text_colc(0,'E')>=firstcol ) {
                  grightcol=_text_colc(0,'E');
               } else {
                  grightcol=firstcol-1+_select_type('','I');
               }
            }
         } else {
            if ( _end_select_compare()==0 ) {
               _leftcol=1;grightcol=lastcol-1+_select_type('','I');
            } else {
               _leftcol= 1;
               if ( _text_colc(0,'E') ) {
                  grightcol= _text_colc(0,'E');
               } else {
                  grightcol= 0;
               }
            }
         }
      }
      _end_line();
      if ( p_col<=grightcol ) {
         grightcol=p_col-1;
      }
   }
   if (p_TruncateLength && grightcol>p_TruncateLength) {
      grightcol=p_TruncateLength;
      if (_leftcol>p_TruncateLength) {
         _leftcol=p_TruncateLength;
         grightcol=p_TruncateLength-1;
      }
   }

   _width=grightcol-_leftcol+1;
   if (gdoRaw) {
      boolean orig_utf8=p_UTF8;
      p_UTF8=true;   // Get the raw data
      // DBCS adjusting for block and inclusive char selections done in _get_selinfo
      string=_expand_tabsc(_leftcol,_width,'S');
      p_UTF8=orig_utf8;
   } else {
      string=_expand_tabsc(_leftcol,_width,'S');
   }

   activate_window(view_id);
   return 0;

}

/** 
 * @return  Returns 0 and replaces current partial line of the selection 
 * being filtered with <i>out_string.
 * 
 * @see filter_init
 * @see filter_get_string
 * @see filter_restore_pos
 * @see filter_selection
 * 
 * @categories Selection_Functions
 * @appliesTo  Edit_Window, Editor_Control
 */
_str filter_put_string(_str string)
{
   if (gdoRaw && !gmarkfilt_utf8) {
      string=_MultiByteToUTF8(string);
   }
   int view_id;
   get_window_id(view_id);
   activate_window(filter_view_id);
   // The spell checking macro calls filter_get_string once
   // and calls filter_put_string multiple times on the same
   // line and modifies the text inbetween calls.
   int NewLineLen=_line_length();
   int rightcol=grightcol+(NewLineLen-glinelen);
   if (_lineflags() & NOSAVE_LF) {
      activate_window(view_id);
      return(0);
   }
   if ( mtype == 'LINE' ) {
      replace_line(string);
   } else {
      int lc=_leftcol;
      int rcol=rightcol;
      // DBCS adjusting for block and inclusive char selections done in _get_selinfo
      /*if (mtype!='BLOCK') {
         if (!_dbcsStartOfDBCSCol(lc)) {
            --lc;
         }
         if (!_dbcsStartOfDBCSCol(rcol+1)) {
            ++rcol;
         }
      } */

      int orig_col=p_col;
      p_col=lc;
      _delete_text(rcol-lc+1,'C');
      int orig_line=p_line;
      p_col=lc;_insert_text(string);
      p_col=orig_col;
      if (p_line>orig_line) {
         // This helps spell checking support of
         // p_TruncateLength
         p_line=orig_line;
      }
 #if 0
     replace_line _expand_tabsc(1,_leftcol-1,'S'):+string:+
                 _expand_tabsc(rightcol+1,-1,'S')
 #endif
   }
   activate_window(view_id);
   return(rc);
}
static _str upcase_filter(_str s)
{
   return(upcase(s));
}
static _str togglecase_filter(_str s) 
{
   return(togglecase(s));
}
static _str lowcase_filter(_str s)
{
   return(lowcase(s));
}
static _str reverse_filter(_str s)
{
   return(strrev(s));
}
static _str align_left_filter(_str s)
{
   int n=length(s);
   s=(strip(s,'L'));
   s=s:+substr('',1,n-length(s));
   return(s);
}
static _str align_right_filter(_str s)
{
   int n = lastcol - firstcol + 1;
   s = (strip(s,'B'));
   if (length(s) >= n) {
      return s;
   }
   s = substr('', 1, n - length(s)):+s;
   return(s);
}
static _str align_center_filter(_str s)
{
   int n = lastcol - firstcol + 1;
   s = (strip(s,'B'));
   if (length(s) >= n) {
      return s;
   }
   h := (n - length(s)) intdiv 2;
   s = substr('', 1, h) :+ s :+ substr('', 1, n-length(s)-h);
   return(s);
}
_str filter_selection_copy(typeless filter,_str optionL='',boolean doRaw=false)
{
   _str orig_markid=_duplicate_selection('');
   _str temp_markid=_duplicate_selection();
   _show_selection(temp_markid);
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   boolean was_line_selection=_select_type()=='LINE';
   if (!was_line_selection) {
      _insert_text('a');
      p_col=0;_delete_text(-2);
   }
   _copy_to_cursor();
   typeless status=filter_selection(filter,optionL,doRaw);
   if (!was_line_selection) {
      _deselect();top();_select_char();
      bottom();_select_char();
   } else {
      select_all();
   }
   copy_to_clipboard();
   _show_selection(orig_markid);
   _free_selection(temp_markid);
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(status);
}


/**
 * Filter selected text through an external command. The external command 
 * must be capable of redirecting stdin from a file and output to stdout.  Takes 
 * an optional argument that is the command to run. If "", then user * will be 
 * prompted for command to run.
 * 
 * @return  Returns 0 if successful.
 * @see filter_init
 * @see filter_get_string
 * @see filter_put_string
 * @see filter_restore_pos
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_str filter_selection(typeless filter,_str optionL='',boolean doRaw=false)
{
   typeless index;
   if (_isfunptr(filter)) {
      index=filter;
   } else {
      index=find_index(filter,PROC_TYPE|COMMAND_TYPE);
      if ( ! index_callable(index) ) {
         return(PROCEDURE_NOT_FOUND_RC);
      }
   }
   /* duplicate the current marked area to preserve mark type. */
   _str old_mark;
   _str mark_status=save_selection(old_mark);
   if ( mark_status ) {
      clear_message();   /* Not serious error */
   }
   filter_init(doRaw);
   if ( upcase(optionL)=='L' ) {
      _select_type("","L","LINE");
      mtype='LINE';
   }
   typeless status, string;
   if (_isfunptr(filter)) {
      for (;;) {
         status= filter_get_string(string);
         if ( status ) break;
         filter_put_string((*index)(string,index));
      }
   } else {
      for (;;) {
         status= filter_get_string(string);
         if ( status ) break;
         filter_put_string(call_index(string,index));
      }
   }
   filter_restore_pos();
   if ( ! mark_status ) {
      restore_selection(old_mark);
   }
   return(0);
}
_str select_active2()
{
   typeless status=select_active();
   if (status && !_isnull_selection()) {
      return(status);
   }
   return(0);
}
/**
 * @return Returns MARK_SEARCH (constant defined in 'slick.sh')  if the 
 * current buffer has a visible marked area.  Otherwise 0 is returned.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Selection_Functions
 * 
 */ 
int select_active(_str markid='')
{
   if ( _select_type(markid)!='' ) {
      int first_col,last_col,buf_id;
      _get_selinfo(first_col,last_col,buf_id,markid);
      if ( buf_id==p_buf_id ) {
         return(MARK_SEARCH);
      }
   }
   return(0);

}
_command void maybe_upcase_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! select_active2() ) {
      upcase_word();
      return;
   }
   upcase_selection();
}
/**
 * Translates characters within selection into upper case.
 * 
 * @see lowcase_selection
 * @see upcase
 * @see upcase_word
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 * 
 */ 
_command void upcase_selection(_str notused='',typeless filter_name='',boolean doRaw=false) name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) {
      init_command_op();
   }
   _str mark='';
   _str old_mark='';
   if ( ! select_active2() ) {
      // Select the current word.
      // Preserve the current selection
      mark=_alloc_selection();
      old_mark=_duplicate_selection("");
      _show_selection(mark);
      int start_col;
      _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
      if ( word=='' ) {
         if (!was_command_state) {
            message(nls('No word at cursor'));
         }
         if (was_command_state) retrieve_command_results();
         return;
      }
      p_col=_text_colc(start_col,'I');
      _select_char();
      p_col=p_col+_rawLength(word);_select_char();
   }
   if ( filter_name=="" ) {
      filter_name=upcase_filter;
   }
   filter_selection(filter_name,'',doRaw);
   if ( mark!='' ) {
      _show_selection(old_mark);
      _free_selection(mark);
   }
   if (was_command_state) retrieve_command_results();
}
_str _cap_word(_str s)
{
   int charLen;
   _strBeginChar(s,1,charLen,false);
   return(upcase(substr(s,1,charLen)):+lowcase(substr(s,1+charLen)));
}

/**
 * Capitalizes each letter following a space character in a string.
 * 
 * @param s             string
 * 
 * @return _str         string with each word capitalized
 */
_str _cap_string(_str s)
{
   // first capitalize the first part
   s = upcase(substr(s, 1, 1)) :+ substr(s, 2);

   // find all the spaces
   spacePos := pos(' ', s);
   count := 0;
   while ( spacePos > 0) {
      // capitalize the thing after the space
      s = substr(s, 1, spacePos) :+ upcase(substr(s, spacePos + 1, 1)) :+ substr(s, spacePos + 2);
      
      spacePos = pos(' ', s, spacePos + 1);
   }

   return s;
}

_str cap_word_filter(_str s)
{
   int i,charLen;
   word_chars := _extra_word_chars:+p_word_chars;
   for (i=1;;) {
      i=pos('['word_chars']',s,i,'r');
      if (!i) {
         return(s);
      }
      _strBeginChar(s,i,charLen,false);
      s=substr(s,1,i-1):+upcase(substr(s,i,charLen)):+lowcase(substr(s,i+charLen));
      i=pos('~['word_chars']',s,i,'r');
      if (!i) {
         return(s);
      }
   }

}

/**
 * Capitalizes the first character of the current selection and the first 
 * character of each word in the current selection and leaves the cursor at its
 * current location. If there is no current selection, then the command is 
 * identical to cap_word().
 *
 * @see cap_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cap_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   upcase_selection('',cap_word_filter);
}
_command void maybe_lowcase_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! select_active2() ) {
      lowcase_word();
      return;
   }
   lowcase_selection();
}
/**
 * Translates characters within a selection into lower case.  Text may be 
 * selected with one of the commands <b>select_char</b> (F8), <b>select_line</b> 
 * (Ctrl+L), or <b>select_block</b> (Ctrl+B).
 * 
 * <p>Displays message if text not marked.</p>
 * 
 * @see upcase_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 * 
 */
_command void lowcase_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   upcase_selection('',lowcase_filter);
}
/**
 * Aligns text within a selection to the left. 
 * Text may be selected with one of the commands 
 * <b>select_char</b> (F8), <b>select_line</b>  (Ctrl+L), or 
 * <b>select_block</b> (Ctrl+B).
 * 
 * <p>Displays message if text not marked.</p>
 * 
 * @see upcase_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command align_selection_left() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   upcase_selection('',align_left_filter,true);
}
/**
 * Aligns text within a selection to the right. 
 * Text must be selected with a <b>select_block</b> (Ctrl+B).
 * 
 * <p>Displays message if text not marked.</p>
 * 
 * @see upcase_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command align_selection_right() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_BLOCK_SELECTION)
{
   upcase_selection('',align_right_filter,true);
}
/**
 * Centers text within a selection. 
 * Text must be selected with a <b>select_block</b> (Ctrl+B).
 * 
 * <p>Displays message if text not marked.</p>
 * 
 * @see upcase_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command align_selection_center() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_BLOCK_SELECTION)
{
   upcase_selection('',align_center_filter,true);
}
 /**
 * Toggles the case of characters within a selection.
 * 
 * @see lowcase_selection
 * @see upcase_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 * 
 */
_command void togglecase_selection(_str notused='',typeless filter_name='',boolean doRaw=false) name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   upcase_selection('', togglecase_filter);
}
/**
 * Reverse characters in selection
 * 
 * <p>Displays message if text not marked.</p>
 * 
 * @see upcase_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command void reverse_selection() name_info(',')
{
    upcase_selection('',reverse_filter);
}
/**
 * Forces a reindent of the current line or selection by using 
 * smarttab. 
 *  
 * @see smarttab
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions 
 */
_command void force_reindent() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   int orig_smarttab = _lang_smart_tab(p_LangId);
   _lang_smart_tab(p_LangId,3);   
   if (!select_active()) {
      smarttab();
   } else {
      _save_pos2(auto p);
      int num_lines = count_lines_in_selection();
      begin_select();
      deselect();
      int i;
      for (i = 0; i < num_lines; i++) {
         smarttab();
         down();
      }
      _restore_pos2(p);
   }
   _lang_smart_tab(p_LangId,orig_smarttab);
}

static int gLeftBlockCol;
static _str indent_filter(_str s)
{
   if (s :== '' && !LanguageSettings.getInsertRealIndent(p_LangId)) {
      return s;
   }

   _str string;
   int _leftcol=1;
   if ( gLeftBlockCol ) {
      _leftcol=gLeftBlockCol;
   }
   p_col=_leftcol;ptab();
   if ( p_indent_with_tabs ) {
      int syntax_indent=p_col-_leftcol;
      if ( expand_tabs(s,1,_leftcol-1)!='' ) {
         string="\t";
      } else {
         _leftcol=1;
         s=reindent_line(s,syntax_indent);
         string='';
      }
   } else {
      string=substr('',1,p_col-_leftcol);
   }
   //messageNwait("_leftcol="_leftcol" l="expand_tabs(s,1,_leftcol-1,'s')"> r="expand_tabs(s,_leftcol,-1,'s')">");
   return(expand_tabs(s,1,_leftcol-1,'s')string:+expand_tabs(s,_leftcol,-1,'s'));
}
static _str unindent_filter(_str s)
{
   p_col=gLeftBlockCol;
   if ( p_indent_with_tabs && expand_tabs(s,1,p_col)!='' ) {
      tab();
   } else {
      ptab();
   }
   int syntax_indent=p_col-gLeftBlockCol;
   _str string=expand_tabs(s,gLeftBlockCol,syntax_indent);
   _str new_s=reindent_line(s,-syntax_indent);
   if ( expand_tabs(new_s,1,gLeftBlockCol-1)=='' ) {
      return(new_s);
   }
   return(expand_tabs(s,1,gLeftBlockCol-1,'S'):+strip(string,'L'):+
          expand_tabs(s,gLeftBlockCol+syntax_indent,-1,'S'));
}
/**
 * Indents the marked text.  For line and character marks, one indent 
 * level is added to each line.  For block marks, one indent level starting from 
 * the left edge of the mark is added.  Indenting will be with tab or space 
 * characters depending upon the indent style.  If this menu
 * item does not exist, the tab stops are used as the indent for
 * each level.
 * 
 * @see unindent_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */
_command indent_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   gLeftBlockCol=0;
   _str markt='';
   if ( _select_type()!='LINE' ) {
      markt='L';
   }
   if (_select_type()=='BLOCK') {
      typeless junk;
      _get_selinfo(gLeftBlockCol,junk,junk);
   }
   filter_selection(indent_filter,markt,true);
   return(0);
}
/**
 * @return Returns line with leading spaces and/or tabs reformatted to adhere 
 * precisely to the users <b>indent_with_tabs</b> style (See 
 * <b>indent_with_tabs</b> command).
 *  
 * If the line is completely blank (no tabs or spaces), uses the
 * forceIndentEmptyLine and LangaugeSettings.getInsertRealIndent 
 * value to figure out what to do. 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_str reindent_line(_str s,int syntax_indent, boolean forceIndentEmptyLine = false)
{
   // if the line is completely blank, then we do nothing
   if (s :== '' && 
       !LanguageSettings.getInsertRealIndent(p_LangId) && 
       !forceIndentEmptyLine) {
      return s;
   }

   int non_blank=pos('[~ \t]|$',s,1,'r');
   int indent_width=text_col(s,non_blank,'I')+syntax_indent-1;
   if ( indent_width<0 ) {
      indent_width=0;
   }
   return(indent_string(indent_width):+
         substr(s,non_blank));

}
void _reindent_linec(int syntax_indent)
{
   save_pos(auto p);
   _begin_line();
   //search('[~ \t]|$','r@');
   _TruncSearchLine('[~ \t]|$','r');
   int non_blank=p_col;
   int physical_non_blank=_text_colc(non_blank,'p');
   int indent_width=non_blank+syntax_indent-1;
   if ( indent_width<0 ) {
      indent_width=0;
   }
   _begin_line();
   _delete_text(physical_non_blank-1);
   _insert_text(indent_string(indent_width));
   restore_pos(p);
}
/**
 * Unindents selection.  For line and character selections, one indent 
 * level is removed from each line.  For block selections, one indent level 
 * starting from the left edge of the selection is removed.  Indenting will 
 * be with tab or space characters depending upon the Indent With Tabs 
 * setting.
 * 
 * @see indent_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Selection_Functions
 * 
 */ 
_command unindent_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   _str markt='L';
   if ( _select_type()=='BLOCK' ) {
      typeless junk;
      _get_selinfo(gLeftBlockCol,junk,junk);
   } else {
      gLeftBlockCol=1;
   }
   filter_selection(unindent_filter,markt,true);
}

/**
 * Unindents the current line one indent level.
 * Indenting will be with tab or space characters depending upon the
 * Indent With Tabs setting.
 * 
 * @see indent_line
 * @see unindent_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void unindent_line() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _str line="";
   get_line(line);
   line=reindent_line(line, -p_SyntaxIndent);
   replace_line(line);
   first_non_blank();
}

/**
 * Indents the current line one indent level.
 * Indenting will be with tab or space characters depending upon the
 * Indent With Tabs setting.
 * 
 * @see unindent_line
 * @see indent_selection
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void indent_line() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // since the user called this explicitly, we assume they want 
   // to indent a blank line
   _indent_line(true);
}

/**
 * Indents the current line one indent level. 
 *  
 * If the line is completely empty (no tabs or spaces), then we 
 * use the forceIndentEmptyLine parameter and the 
 * LangaugeSettings.getInsertRealIndent value to determine 
 * whether to indent it. 
 * 
 * @param forceIndentEmptyLine            if true, then empty 
 *                                        lines are indented.
 *                                        If false, then we use
 *                                        the InsertRealIndent
 *                                        value to determine
 *                                        what to do
 */
void _indent_line(boolean forceIndentEmptyLine)
{
   _str line="";
   get_line(line);
   line=reindent_line(line, p_SyntaxIndent, forceIndentEmptyLine);
   replace_line(line);
   first_non_blank();
}

/*
   Since some mark functions like begin_select change the mark
   style, this function can be called to restore the original mark
   style.  The pivot point and mark style(s) are restored.  The
   mark type (line,block, or char) is unchanged.
*/
void save_select_style(typeless &style)
{
   style=_select_type('','s'):+_select_type('','u'):+_select_type('','i')' '_select_type('','p');
}
int restore_select_style(typeless style)
{
   int start_col, end_col, buf_id;
   _get_selinfo(start_col,end_col,buf_id);
   _str new_mark=_alloc_selection();
   if ( new_mark<0 ) {
      return(1);
   }
   save_pos(auto p);
   _str cc;
   parse style with style cc;
   int type=_select_type();
   if ( substr(cc,1,1)=='B' ) { _begin_select(); } else { _end_select(); }
   /* if substr(cc,2,1)='B' then p_col=start_col else p_col=end_col endif */
   select_it(type,new_mark);
   if ( substr(cc,1,1)=='E' ) { _begin_select(); } else { _end_select(); }
   /* if substr(cc,2,1)='E' then p_col=start_col else p_col=end_col endif */
   select_it(type,new_mark,style);
   restore_pos(p);
   _str old_mark=_duplicate_selection('');
   _show_selection(new_mark);
   _free_selection(old_mark);
   return(0);
}

/* filter functions for converting tabs to spaces and back -- moved from emacs.e*/
_str _tabify_filter(_str s)
{
#if 0
   s=expand_tabs(substr('',1,_leftcol-1,'x'):+s);
   typeless i='';
   _str tab_line=substr('',1,length(s),"\t");
   for (;;) {
      i=lastpos(' #| #$',s,i,'r');
      if (!i) {
         break;
      }
      int width=lastpos('');
      s=substr(s,1,i-1):+expand_tabs(tab_line,i,width,'S'):+substr(s,i+width);
      i=i-1;
      if (!i) {
         break;
      }
   }
   return(substr(s,_leftcol));
#endif
#if 1
   /*
     This code is pretty slow (old code was slow too). 
     Handle case where already have all tabs. Old code might
     add spaces. Users don't want ANY new spaces.
    
     Note: expand_tabs with the 'S' needs to be changed to
     better handle bisecting a leading tab. Currently it always
     replaces it with spaces. It should only do that if it
     does not expand to one space.
   */
   s=substr('',1,_leftcol-1,'x'):+s;
   typeless i='';
   _str tab_line=substr('',1,length(s),"\t");
   for (;;) {
      i=lastpos('[\t ]#',s,i,'r');
      if (!i) {
         break;
      }
      int j=text_col(s,i,"I");
      int pwidth=lastpos('');
      int j2=text_col(s,i+pwidth,"I");
      int width=j2-j;
      _str found=substr(s,i,pwidth);
      // Special case for a tab character which expands to one space.
      if (pos(' ',found)) {
         s=substr(s,1,i-1):+expand_tabs(tab_line,j,width,'S'):+substr(s,i+pwidth);
      }
      i=i-1;
      if (!i) {
         break;
      }
   }
   return(substr(s,_leftcol));
#endif
}

_str _untabify_filter(_str s)
{
   _str prefix=substr('',1,_leftcol-1,'x');
   return(substr(expand_tabs(prefix:+s,1),_leftcol));
}

