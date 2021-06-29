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
#include "minihtml.sh"
#import "briefutl.e"
#import "commentformat.e"
#import "cua.e"
#import "debug.e"
#import "guiopen.e"
#import "help.e"
#import "ispflc.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mouse.e"
#import "os2cmds.e"
#import "put.e"
#import "recmacro.e"
#import "seek.e"
#import "seldisp.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "xmlwrap.e"
#import "sellist2.e"
#import "tbterminal.e"
#endregion

static const MAX_CONDENSED_CLIPBOARD_LINE_LEN= 1000;

int _clipboards_view_id;     // View id of .clipboards buffer.
typeless _Nofclipboards;      // Number of clipboards in clipboard buffer.
                             // string type used so parse statement typecheck ok
int _Nofnulls;                // Number of unnamed clipboards
bool def_modal_paste=false;
bool _append_next_clipboard;
static bool _cb_modified;
static _str yesnosave_clipboards;
bool def_brief_word=false;
int def_paste_block_cursor_end=0;
bool def_append_clipboard_adds_newline=true;


   static bool _lastcbisauto=false;  // Set when _copy_to_clipboard called
                               // Could add option to _copy_to_clipboard
                               // function to indicate auto clipboard
                               // when _clipboard_format is called
definit() {
   _clipboard_clear_all();
}

/**
 * Returns the maximum name length of a named clipboard.
 *
 * We base the maximum name length on the number of allowed
 * clipboards.  Otherwise, we get cropped numbers, which appear
 * as duplicate names in the clipboards tool window.
 *
 * @return int
 */
static int max_clipboard_name_length()
{
   return max(2, length(def_clipboards));
}

/**
 * Deletes selection and copies it to the clipboard.  For an edit window or editor
 * control, if no text is selected, the current line is deleted and copied to the
 * clipboard.  All clipboards are stored in the ".clipboards" buffer.  The last
 * clipboard may be inserted by the <b>paste</b> command (Ctrl+V).  Previous
 * clipboards may be inserted with the <b>list_clipboards</b> command (Ctrl+Shift+V).
 * <p>
 * In ISPF emulation, this command is not called when invoked from the command line.
 * Instead <b>ispf_cut</b> is called.  Use ("Edit", "Cut") to explicitly invoke the
 * <b>cut </b>command.
 * <p>
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @param push
 * @param doCopy
 * @param name
 *
 * @return Returns 0 if successful.  Common return codes are 1 (no line at cursor)
 *         and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 * @see copy_to_clipboard
 * @see ispf_cut
 * @see <i>list_clipboards</i>
 * @see paste
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int cut(bool push=true,bool doCopy=false,_str name='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{   
   typeless status=0;
   int was_command_state=command_state();
   if (!was_command_state && commentwrap_Cut(push, doCopy, name)) {
      return 0;
   }
   if (!was_command_state && XW_Cut(push, doCopy, name)) {
      return 0;
   }
   if (was_command_state) {
      start_pos := 0;
      end_pos := 0;
      _get_sel(start_pos,end_pos);
      if (start_pos==end_pos) {
         status=push_clipboard_itype('CHAR','',1,true);
         if ( status ) return(status);
         append_clipboard_text(p_text,'');
         set_command("",1);
         return(0);
      }
      init_command_op();
      if (_select_type()=='') {
         retrieve_command_results();
         return(1);
      }
   }
   if (!was_command_state && use_copy_to_cursor_instead(true)) {
      return 0;
   }
   if (_MultiCursorAlreadyLooping() && !_MultiCursorFirstLoopIteration() &&
       push && !_append_next_clipboard && _Nofclipboards) {
      push=false;
      if (_select_type()=='CHAR') {
         append_clipboard_text("\n",name,false);
      }
   }
   status=cut2(push,doCopy,name);
   if (was_command_state) retrieve_command_results();
   return(status);
}
int cut2(bool push=true,bool doCopy=false,_str name='', bool quiet=false,int MarkFlags=-1)
{
   typeless old_mark=0;
   typeless mark=0;
   name=strip(name);
   if ( ! select_active() ) {
      // IF we are on linenum 0 or we don't want to copy when current line is selected
      if ( _on_line0() || !def_copy_noselection) {
         return(1);
      }
      if ( !doCopy) {
#if 0    /* This is not wanted for brief emulation and */
         /* Not very useful for SlickEdit emulation. */
         if ( name_name(prev_index()):=='cut' ) {
            prev_index(find_index('cut-line',COMMAND_TYPE))
         }
#endif
         return(cut_line(name));   /* HERE */
      }
      old_mark=_duplicate_selection('');
      mark=_alloc_selection();
      if ( mark<0 ) return(mark);
      _show_selection(mark);
      _select_line();
      if (!quiet) {
         message(nls('Line copied to clipboard'));
      }
   } else {
      if (!def_deselect_copy && doCopy) {
         old_mark=_duplicate_selection('');
         mark=_duplicate_selection();
         if ( mark<0 ) return(mark);
         _show_selection(mark);
         if (!quiet) {
            if ( upcase(strip(translate(def_keys,'-','_'))):=='VI-KEYS' ) {
               _str num_lines = count_lines_in_selection(mark);
               if (isinteger(num_lines)) {
                  if ((int)num_lines > 2) {
                     message(nls(num_lines' lines yanked'));
                  }
               } else {
                  message(nls('Selection copied to clipboard'));
               }
            } else {
               message(nls('Selection copied to clipboard'));
            }
         }
      } else {
         mark='';
      }
   }
   start_col := 0;
   end_col := 0;
   typeless junk;
   buf_name := "";
   typeless utf8='';
   _str lexername=p_lexer_name;
   int multiCursorCount=_MultiCursorCount();
   typeless status=0;
   view_id := 0;
   _extend_outline_selection(mark);
   if ( push ) {
      /* Deleting mark and user has cut/past style marking? */
      if ( !doCopy && pos('C',def_select_style,1,'i') ) {
         _begin_select(mark);
      }
      _get_selinfo(start_col,end_col,junk,mark,buf_name,utf8);
      status=push_clipboard_itype(_select_type(mark),name,start_col,utf8,lexername,multiCursorCount);
      if ( status ) {
         if( mark!='' ) {
            _show_selection(old_mark);
            _free_selection(mark);
         }
         return(status);
      }
   } else {
      get_window_id(view_id);
      activate_window(_clipboards_view_id);
      if ( name!='' ) {
         /* Make the current clipboard the named clipboard */
         status=goto_named_clipboard(name);
         if ( status ) {
            activate_window(view_id);
            if ( isinteger(name) && name>=1 && name<=_Nofnulls ) {
               if( mark!='' ) {
                  _show_selection(old_mark);
                  _free_selection(mark);
               }
               if (!quiet) {
                  message(nls("Unable to find named clipboard: "name));
               }
               return(status);
            } else {
               _get_selinfo(start_col,end_col,junk,mark,buf_name,utf8);
               status=push_clipboard_itype(_select_type(mark),name,start_col,utf8,lexername,multiCursorCount);
               if ( status ) {
                  if( mark!='' ) {
                     _show_selection(old_mark);
                     _free_selection(mark);
                  }
                  return(status);
               }
            }
         }
      } else if(_Nofclipboards) {
         goto_clipboard(_Nofclipboards);  /* Make sure we paste the most current clipboard */
      }
      activate_window(view_id);
   }
   status=append_cut2(mark,doCopy,name,MarkFlags);
   if ( mark!='' ) {
      _show_selection(old_mark);
      _free_selection(mark);
   }
   return(status);

}
int def_copy_to_clipboard_warn_ksize=100*1024;  // 100 megabytes
static bool use_copy_to_cursor_instead(bool doCut=false) {
   if ( select_active() && (_select_type()=='LINE' || _select_type()=='CHAR')) {
      save_pos(auto p);
      int dup_markid=_duplicate_selection();
      _begin_select(dup_markid);
      typeless start_seek=point('s');
      _end_select(dup_markid);
      typeless end_seek=point('s');
      restore_pos(p);
      diff:=end_seek-start_seek;
      if (diff>=def_copy_to_clipboard_warn_ksize*1024) {
         if (doCut) {
            result:=_message_box("It is recommended that you delete this text without copying it to the clipboard so you don't run out of memory\n\nDelete instead of cut?",'',MB_YESNO);
            if (result==IDCANCEL || result==IDYES) {
               delete_selection();
               return true;
            }
            return false;
         }
         result:=_message_box("This operation is very inefficient for copying text from one file to another and you may run out of memory.\n\nContinue?\n\nFor a much more efficient file to file copy, use the copy-to-cursor command (Edit>Other>Copy to Cursor) to copy the selection to the cursor even if the selection is in another file.",'',MB_YESNOCANCEL,IDNO);
         if (result==IDCANCEL || result==IDNO) {
            return true;
         }
      }
   }
   return false;
}
/**
 * Copies selection to the clipboard.  If no text is selected the current
 * line is copied to the clipboard.  The optional <i>cbname</i> string
 * specifies the name of the clipboard.  This name can be used with the
 * <b>paste</b> command to specify a specific clipboard.  Copies of all
 * clipboards are stored in the ".clipboards" buffer.  The clipboard may
 * be inserted by the <b>paste</b> command (Ctrl+V).  Previous clipboards
 * may be inserted with the <b>list_clipboards</b> command (Ctrl+Shift+V).
 * <p>
 * IMPORTANT: <i>cbname</i> needs to start with an alphabetic character (a-z).
 * numeric values for <i>cbname</i> are reserved for VI emulation.
 * <p>
 * NOTE: If there is no selection, the current line is copied.
 * <p>
 * NOTE: If the copy is done using Ctrl+C, the current window is the Build
 * window, and there is no selection, then execute stop-build.  This can be
 * disabled by setting the configuration variable {@link
 * def_stop_process_noselection} to false.
 * </p>
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no text
 * marked in current buffer) and TOO_MANY_SELECTIONS_RC.  On error, message
 * is displayed.
 *
 * @see cut
 * @see list_clipboards
 * @see paste
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_to_clipboard(_str name="",int MarkFlags=-1) name_info(','VSARG2_LASTKEY|VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (MarkFlags==-1 && !command_state() && _select_type()!='BLOCK') {
      if (p_hex_mode==HM_HEX_ON && p_hex_field && def_hex_view_copy) {
         // copy_as_hex_view doesn't support multiple cursors yet
         return copy_as_hex_view(name, MarkFlags);
      }
      if (p_hex_mode==HM_HEX_ON && def_hex_binary_copy) {
         MarkFlags=VSMARKFLAG_BINARY|VSMARKFLAG_KEEP_SRC_NLCHARS;
      }
   }
   
   // if we are in the process buffer and they hit Ctrl+C
   // without having a selection, then do stop_build
   if (def_stop_process_noselection && !command_state() &&
       _isEditorCtl() && beginsWith(p_buf_name,".process") &&
       last_event(null,true)==C_C && !select_active()) {
      if (debug_active()) {
         int status = debug_suspend();
         if (status==0) return status;
      }
      stop_build();
      return 0;
   }
   push := true;
   // now copy the selection (or current line) to the clipboard
   if (!command_state() && !(MarkFlags!=-1 && (MarkFlags & VSMARKFLAG_BINARY)) && use_copy_to_cursor_instead()) {
      return COMMAND_CANCELLED_RC;
   }
   init_command_op();
   if (_MultiCursorAlreadyLooping() && !_MultiCursorFirstLoopIteration() &&
        !_append_next_clipboard && _Nofclipboards /*&& (_select_type()=='CHAR' || _select_type()=='')*/) {
      push=false;
      if (select_active() && _select_type()=='CHAR') {
         append_clipboard_text("\n",name,false);
      }
   }

   // Check if the mouse-over tooltip has text selected
   if (_ECCommandCallback("copy")) return 0;

   int status=cut2(push,true,name,false,MarkFlags);
   retrieve_command_results();
   return(status);

}
/**
 * Copies selection to the clipboard as plain text and no other
 * additional formats like HTML. If no text is selected the
 * current line is copied to the clipboard.
 * 
 * <p>The optional <i>cbname</i> string specifies the name of
 * the clipboard. This name can be used with the
 * <b>paste</b> command to specify a specific clipboard.  Copies of all
 * clipboards are stored in the ".clipboards" buffer.  The clipboard may
 * be inserted by the <b>paste</b> command (Ctrl+V).  Previous clipboards
 * may be inserted with the <b>list_clipboards</b> command (Ctrl+Shift+V).
 * <p>
 * IMPORTANT: <i>cbname</i> needs to start with an alphabetic character (a-z).
 * numeric values for <i>cbname</i> are reserved for VI emulation.
 * <p>
 * NOTE: If there is no selection, the current line is copied.
 * <p>
 * NOTE: If the copy is done using Ctrl+C, the current window is the Build
 * window, and there is no selection, then execute stop-build.  This can be
 * disabled by setting the configuration variable {@link
 * def_stop_process_noselection} to false.
 * </p>
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no text
 * marked in current buffer) and TOO_MANY_SELECTIONS_RC.  On error, message
 * is displayed.
 *
 * @see copy_to_clipboard
 * @see cut
 * @see list_clipboards
 * @see paste 
 * @see copy_as_text
 * @see copy_as_binary
 * @see copy_as_hex_view 
 * @see copy_as_html
 * @see copy_as_plain_text
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_as_plain_text(_str name="",int MarkFlags=-1) name_info(','VSARG2_LASTKEY|VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL) {
   _str orig_def_clipboard_formats=def_clipboard_formats;
   def_clipboard_formats='';
   status:=copy_to_clipboard(name,MarkFlags);
   def_clipboard_formats=orig_def_clipboard_formats;
   return status;
}
/**
 * Copies selection to the clipboard and makes sure that an HTML
 * clipboard is created. The HTML clipboard is useful if you
 * want to paste color coding into another applicaiton. If no
 * text is selected the current line is copied to the clipboard.
 * 
 * <p>The optional
 * <i>cbname</i> string specifies the name of the clipboard.
 * This name can be used with the
 * <b>paste</b> command to specify a specific clipboard.  Copies of all
 * clipboards are stored in the ".clipboards" buffer.  The clipboard may
 * be inserted by the <b>paste</b> command (Ctrl+V).  Previous clipboards
 * may be inserted with the <b>list_clipboards</b> command (Ctrl+Shift+V).
 * <p>
 * IMPORTANT: <i>cbname</i> needs to start with an alphabetic character (a-z).
 * numeric values for <i>cbname</i> are reserved for VI emulation.
 * <p>
 * NOTE: If there is no selection, the current line is copied.
 * <p>
 * NOTE: If the copy is done using Ctrl+C, the current window is the Build
 * window, and there is no selection, then execute stop-build.  This can be
 * disabled by setting the configuration variable {@link
 * def_stop_process_noselection} to false.
 * </p>
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no text
 * marked in current buffer) and TOO_MANY_SELECTIONS_RC.  On error, message
 * is displayed.
 *
 * @see copy_to_clipboard
 * @see cut
 * @see list_clipboards
 * @see paste 
 * @see copy_as_text
 * @see copy_as_binary
 * @see copy_as_hex_view 
 * @see copy_as_html
 * @see copy_as_plain_text
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_as_html(_str name="",int MarkFlags=-1) name_info(','VSARG2_LASTKEY|VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL) {
   _str orig_def_clipboard_formats=def_clipboard_formats;
   def_clipboard_formats='H';
   status:=copy_to_clipboard(name,MarkFlags);
   def_clipboard_formats=orig_def_clipboard_formats;
   return status;
}

_command void push_clipboard(_str text="", _str name="", bool utf8=false) name_info(','VSARG2_READ_ONLY)
{
   typeless status = push_clipboard_itype('CHAR', name, 0, utf8);  
   if ( status ) return;
   append_clipboard_text(text,name);
}

static const NULL_CB_NAME=  '*';

/**
 * @return  Returns the clipboard type of the current internal clipboard
 * which may be "LINE", "BLOCK", or "CHAR".  If there are no internal clipboards,
 * '' is returned.  The optional <i>clipboard_view_id</i> parameter specifies
 * the view which contains the internal clipboards.
 *
 *
 * @categories Clipboard_Functions
 */
_str clipboard_itype(int temp_view_id)
{
   _str line=clipboard_info(temp_view_id);
   mark_name := "";
   typeless Noflines=0;
   parse line with ':' mark_name Noflines . ;
   return(mark_name);
}

/**
 * Returns the number of lines in the internal clipboard.  0 is returned
 * if there are no internal clipboards.  The optional <i>clipboard_view_id</i>
 * parameter specifies the view which contains the internal clipboards.
 *
 * @categories Clipboard_Functions
 */
int clipboard_iNoflines(int temp_view_id)
{
   _str line=clipboard_info(temp_view_id);
   mark_name := "";
   typeless Noflines=0;
   parse line with ':' mark_name Noflines .;
   if (Noflines=="") {
      return(0);
   }
   return(Noflines);
}
long clipboard_size(int temp_view_id)
{
   _str line=clipboard_info(temp_view_id);
   mark_name := "";
   typeless Noflines=0;
   parse line with ':' mark_name Noflines .;
   if (Noflines=="") {
      return(0);
   }
   orig_wid := p_window_id;
   activate_window(_clipboards_view_id);
   save_pos(auto p);
   down();_begin_line();
   startseek := _nrseek();
   down(Noflines-1);
   _end_line();
   endseek := _nrseek();
   restore_pos(p);
   activate_window(orig_wid);
   return(endseek-startseek);
}
/*
   When clipboard was created, we remember whether the
   column of the first character of the selected text
   that was copied.  This is so that SmartPaste(R) does not
   attempt to reindent.
*/
int clipboard_col(int temp_view_id)
{
   _str line=clipboard_info(temp_view_id);
   mark_name := "";
   typeless Noflines=0;
   typeless col=0;
   parse line with ':' mark_name Noflines . col .;
   if (col=="") {
      return(0);
   }
   return(col);
}

static void _change_clipboard_Noflines(int Noflines,int start_col=0)
{
   line := "";
   get_line(line);
   mark_type := "";
   name := "";
   typeless col=0;
   typeless rest='';
   parse line with mark_type . name col rest;
   if (start_col>0) {
      col=start_col;
   }
   replace_line(mark_type' 'Noflines' 'name' 'col' 'rest);
}

int _get_clipboard_header(_str &cbtype,int &Noflines=0,_str &name='',int &col=0,bool &utf8=false,_str &lexername='',int &multiCursorCount=0)
{
   line := "";
   get_line(line);
   _str sutf8;
   _str sNoflines;
   _str scol;
   _str smultiCursorCount;
   error_status := 0;
   if (substr(line,1,1)!=':') {
      error_status=1;
   }
   parse line with ':'cbtype sNoflines name scol sutf8 "[" lexername "]" smultiCursorCount .;
   if (cbtype!='CHAR' && cbtype!='LINE' && cbtype!='BLOCK') {
      error_status=1;
   }
   if (isinteger(scol)) {
      col=(int)scol;
   } else {
      col=0;
   }
   if(isinteger(sNoflines)) {
      Noflines=(int)sNoflines;
   } else {
      error_status=1;
      Noflines=0;
   }

   //With the addition of lexername to the clipboard header, sutf8 
   //now has a trailing space, so we need an explicit conversion to 
   //int before setting the proper boolean value.  We could also 
   //have used a strip() and the old logic, but this is clearer. 
   if (isinteger(sutf8)) {
      utf8 = (sutf8 != 0);
   } else {
      utf8 = false;
   }
   multiCursorCount=0;
   if (isinteger(smultiCursorCount) && smultiCursorCount>1) {
      multiCursorCount=(int)smultiCursorCount;
   }
   return error_status;
}

static void _add_clipboard_header(_str cbtype,int Noflines=0,_str name=NULL_CB_NAME,int col=0,bool utf8=false,_str lexername='',int multiCursorCount=0)
{
   insert_line(':'cbtype' 'Noflines' 'name' 'col' 'utf8' ['lexername'] 'multiCursorCount);
   _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
}

#if 0
static void _find_last_clipboard()
{
   top();
   for (i=0; i<_Nofclipboards-1; ++i) {
      _get_clipboard_header(type,count,name,col,utf8);
      down(count);
   }
}
/**
 * Removes (Pops) the last clipboard. This function is only used
 * to pop an "auto" clipboard that was temporarily added.
 *
 * @param lastcbisauto   When true, indicates that _lastcbisauto should be turned on.
 */
void pop_clipboard_itype(bool lastcbisauto)
{
   if (!_Nofclipboards) {
      return;
   }

   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_clipboards_view_id);

   int first_col;
   _str name;
   _get_clipboard_header(mark_name,Noflines,name,first_col,utf8);
   int markid=_alloc_selection();
   _select_line(markid);bottom();
   _select_line(markid);_delete_selection(markid);
   if (name==NULL_CB_NAME) {
      --_Nofnulls;
   }
   --_Nofclipboards;
   _find_last_clipboard();

   activate_window(orig_wid);
   if (lastcbisauto) {
      _lastcbisauto=lastcbisauto;
   }
}
#endif
/**
 * Starts a new clipboard entry of type <i>mark_kind</i>.
 * <i>mark_kind</i> may be 'LINE', 'BLOCK', or 'CHAR'.
 *
 * @return Returns 0 if successful.
 *
 * @categories Clipboard_Functions
 *
 */
_str push_clipboard_itype(_str mark_name,_str name="",int col=0,bool utf8=false,_str lexername='',int multiCursorCount=0)
{
   name=strip(name);
   if (!isinteger(col)) col=1;
   if ( length(name)>max_clipboard_name_length() ) {
      return(1);
   }
   view_id := 0;
   is_numbered_cb := (isinteger(name) && name>=1);
   _cb_modified=true;
   if ( _append_next_clipboard ) {
      // Make sure the clipboard file is not empty
      get_window_id(view_id);
      activate_window(_clipboards_view_id);
      if (p_Noflines) {
         activate_window(view_id);
         if (mark_name=='CHAR' && def_append_clipboard_adds_newline) {
            append_clipboard_text("",name);
         }
         return(0);
      }
      activate_window(view_id);
   }
   get_window_id(view_id);
   activate_window(_clipboards_view_id);
//  if replace_kill then   /* delete current killed text first?. */
//     status=delete_kill()
//     if status then
//        activate_window view_id
//        return(status)
//     endif
//     replace_kill=0
//  endif

   /* Look for possible named kill */
   typeless status=1;
   if ( name!='' ) {
      status=goto_named_clipboard(name);
      if ( status && is_numbered_cb ) {
         /* Tried to replace a numbered clipboard that is not within the range of valid clipboards */
         message('Clipboard is out of range');
         goto_clipboard(_Nofclipboards);
         activate_window(view_id);
         return(status);
      }
   }
   replace_cb := 0;   /* Replace the clipboard in place? */
   if ( ! status ) {
      /* Named kill found with name 'name' */
      delete_kill();
      /* We simply replace a named clipboard in place when that
         named clipboard is a number and already exists */
      if ( is_numbered_cb ) {
         replace_cb=1;
      }
   } else {
      if ( _Nofclipboards && _Nofclipboards>=def_clipboards ) {
         // Delete the oldest clipboard which is at the top of the buffer
         top();status=delete_kill();
         if ( status ) {
            goto_clipboard(_Nofclipboards);
            activate_window(view_id);
            return(status);
         }
      }
   }

   /* NULL_CB_NAME is a null place holder for the name of the kill */
   if ( name=='' || is_numbered_cb ) {
      name=NULL_CB_NAME;
   }

   if( replace_cb ) {
      if( p_line!=p_noflines ) {
         up();
      }
   } else {
      bottom();
   }
   _add_clipboard_header(mark_name,0,name,col,utf8,lexername,multiCursorCount);
   _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);
   _Nofclipboards++;
   if( name==NULL_CB_NAME ) {
      _Nofnulls++;
   }
   activate_window(view_id);
   return(0);
}
static _str clipboard_info(int temp_view_id)
{
   if (!temp_view_id) {
      temp_view_id=_clipboards_view_id;
   }
   if (!_Nofclipboards && temp_view_id==_clipboards_view_id) {
      return('');
   }
   view_id := 0;
   get_window_id(view_id);
   activate_window(temp_view_id);
   line := "";
   get_line(line);
   activate_window(view_id);
   return(line);
}

/**
 * Appends selected text to the clipboard and optionally deletes selected text.
 * Specify 'C' as the second argument if you do not want the selected text deleted.
 * mark_id is a handle to a selection returned by one of the built-ins _alloc_selection
 * or _duplicate_selection.  A mark_id of '' or no mark_id parameter identifies
 * the active selection.
 *
 * @param mark
 * @param doCopy
 * @param name
 *
 * @return Returns 0 if successful.  Common return codes are TEXT_NOT_SELECTED_RC,
 *         SOURCE_DEST_CONFLICT_RC, and INVALID_SELECTION_HANDLE_RC.  On error, message is displayed
 * @see append_clipboard_text
 * @see push_clipboard_itype
 * @categories Edit_Window_Methods, Selection_Functions
 */
_str append_cut2(_str mark='',bool doCopy=false,_str name='',int MarkFlags=-1)
{
   _cb_modified=true;
   if ( mark=='' ) {
      mark=_duplicate_selection('');  /* activate mark specified. */
   }
   start_col := 0;
   end_col := 0;
   buf_name := "";
   typeless junk;
   typeless utf8;
   _str lexername = p_lexer_name;
   int multiCursorCount=_MultiCursorCount();
   typeless status=0;
   if ( ! _Nofclipboards ) {  /* No clipboards yet. */
      old_append_next_kill := _append_next_clipboard;
      _append_next_clipboard=false;
      _get_selinfo(start_col,end_col,junk,mark,buf_name,utf8);
      status=push_clipboard_itype(_select_type(mark),name,0,utf8,lexername,multiCursorCount);
      _append_next_clipboard=old_append_next_kill;
      if ( status ) {
         return(status);
      }
      /* Make a clipboard. */
   }
   addClipboard := false;

   if (_append_next_clipboard == 0 && def_clipboard_formats != '') {
      addClipboard=true;
      // handle formatted clipboard
      _clipboard_open();
      _copy_color_coding_to_clipboard(mark, def_clipboard_formats);
   }
   
   view_id := 0;
   get_window_id(view_id);

   /* Check if the data copied is from a binary file. */
   isLastLoopIteration := _MultiCursorLastLoopIteration();

   activate_window(_clipboards_view_id);
   old_line := p_line;
   int first_col;
   mark_name := "";
   Noflines := 0;
   typeless junk1;
   _get_clipboard_header(mark_name,Noflines,junk1,first_col,utf8);
   _get_selinfo(start_col,end_col,auto mark_buf_id,mark);
   _begin_line();
   typeless heading_pos=point();
   down(Noflines);
   if ( _select_type(mark)=='CHAR' && Noflines ) {
      _end_line();
   } else if ( _select_type(mark)!='LINE' ) {
      insert_line('');
   }
   // Copy this data raw
   orig_utf8 := p_UTF8;
   p_UTF8=utf8;
   //say('copy utf8='utf8);
   _str orig_newline=p_newline;
   if (_select_type(mark)!='BLOCK' && MarkFlags!=-1 && (MarkFlags & VSMARKFLAG_KEEP_SRC_NLCHARS)) {
      p_newline=_BufGetNewline(mark_buf_id);
   }
   if ( doCopy ) {
      status=_copy_to_cursor(mark,MarkFlags);
   } else {
      status=_move_to_cursor(mark,MarkFlags);
   }
   if (MarkFlags!=-1 && (MarkFlags & VSMARKFLAG_KEEP_SRC_NLCHARS)) {
      p_newline=orig_newline;
   }
   p_UTF8=orig_utf8;
   if ( status) {
      p_line=old_line;
      activate_window(view_id);
      _deselect(mark);
      if (addClipboard) _clipboard_close(true);
      return(status);
   }
   if (_select_type(mark)=='') {
      insert_line('');
      Noflines=p_line-old_line;
   } else {
      _end_select(mark);
      int NewNoflines=p_line-old_line;
      if (_select_type(mark)!='BLOCK') {
         if (p_noflines - p_NofNoSave != p_RNoflines) {
            _lineflags(0,VSLF_EOL_MISSING);
            int count=NewNoflines-Noflines;
            while (count--) {
               up();
               if (_lineflags() & VSLF_EOL_MISSING) {
                  _join_line();
                  --NewNoflines;
               }
            }
            _lineflags(0,VSLF_EOL_MISSING);
         }
      }
      Noflines=NewNoflines;
   }
   /* up Noflines */
   p_line=old_line;
   if (first_col==0 && _select_type(mark)=='CHAR') {
      first_col=start_col;
   } else {
      first_col=0;
   }
   _change_clipboard_Noflines(Noflines,first_col);
   if (isLastLoopIteration) {
      p_UTF8=utf8;
      status=_append_to_system_cb(mark_name,Noflines,addClipboard,multiCursorCount,MarkFlags);
      p_UTF8=orig_utf8;
   }
#if 0
   /* Unfortunately _append_next_clipboard is not always set before this function is called */
   if ( ! _append_next_clipboard ) {
      status=_copy_to_clipboard(mark);
   } else {
      status=_append_to_system_cb(mark_name,Noflines);
   }
#endif
   activate_window(view_id);
   _deselect(mark);
   return(status);
}
static _str _append_to_system_cb(_str mark_name, int Noflines,bool addClipboard=false,int multiCursorCount=0,int MarkFlags=-1)
{
   int system_mark=_alloc_selection();
   if ( system_mark<0) {
      return(system_mark);
   }
   _begin_line();
   old_line := p_line;
   down();_begin_line();select_it(mark_name,system_mark);
   down(Noflines-1);_end_line();
   if ( mark_name:!='CHAR' ) {
      left();
   }
   if (mark_name=='BLOCK') {
      if (MarkFlags== -1) MarkFlags=0;
      MarkFlags|=VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE;
   }
   select_it(mark_name,system_mark);
   _lastcbisauto=false;
   int status=_copy_to_clipboard(system_mark,true,addClipboard,multiCursorCount,MarkFlags);
   if (addClipboard) _clipboard_close(true);
   p_line=old_line;
   _free_selection(system_mark);
   return(status);

}
/**
 * Appends <i>text</i> to clipboard in buffer.
 *
 * @param text   The text to append.
 *
 * @return Returns 0 to indicate successful.  No errors possible yet.
 *
 * @see append_cut2
 * @see push_clipboard_itype
 * @categories Clipboard_Functions, Selection_Functions
 */
int append_clipboard_text(_str text,_str name='',bool isLastLoopIteration=true)
{
   view_id := 0;
   get_window_id(view_id);
   activate_window(_clipboards_view_id);
   if (name!='') {
      int status=goto_named_clipboard(name);
      if ( status ) {
         activate_window(view_id);
         return status;
      }
   } else {
      if (!_Nofclipboards) {
         activate_window(view_id);
         return 1;
      }
      goto_clipboard(_Nofclipboards);  /* Make sure we paste the most current clipboard */
   }

   _cb_modified=true;
   old_line := p_line;
   mark_name := "";
   Noflines := 0;
   _get_clipboard_header(mark_name,Noflines);
   down(Noflines);
   if ( mark_name=='CHAR' ) {
      if ( Noflines ) {
         _end_line();
         if ( text:!='' ) {
            _insert_text(text);
         } else {
            insert_line("");
         }
      } else {
         //insert_line("");
         //_insert_text(text);
         insert_line("");
         _insert_text(text);
         if (text:=="") insert_line("");
      }
   } else {
     insert_line(text);
   }
   Noflines=p_line-old_line;
   up(Noflines);
   _change_clipboard_Noflines(Noflines);
   if (isLastLoopIteration) {
      typeless status=_append_to_system_cb(mark_name,Noflines);
   }
   activate_window(view_id);
   return(0);

}
static _str delete_kill()
{
   int mark=_alloc_selection();
   if ( mark<0 ) return(mark);
   typeless cbtype='';
   Noflines := 0;
   name := "";
   _get_clipboard_header(cbtype,Noflines,name);
   _select_line(mark);down(Noflines);_select_line(mark);
   _delete_selection(mark);
   typeless status=rc;
   _free_selection(mark);
   _Nofclipboards--;
   _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);
   if( strip(name)==NULL_CB_NAME ) {
      _Nofnulls--;
   }
   return(status);

}
/**
 * Places the cursor on the definition line of the Nth clipboard in the
 * ".clipboards" system buffer.  The first clipboard is the most recently
 * created or pasted internal clipboard.  The ".clipboards" buffer must be
 * active before calling this function (<b>activate_window
 * _clipboards_view_id</b>).
 *
 * @appliesTo Edit_Window
 *
 * @categories Clipboard_Functions
 *
 */
void goto_clipboard(int clipboard_index,bool skip_named_clipboards=false)
{
   if( !_Nofclipboards ) return;
   if ( clipboard_index>_Nofclipboards ) {
      clipboard_index=_Nofclipboards;
   }

   top();
   i := 1;
   Nofclipboards_count := 0;
   Nofnulls_count := 0;
   header_linenum_of_last_good_clipboard := 0;
   last_linenum_of_last_good_clipboard := 0;
   status := 0;
   for (;;) {
      typeless cbtype='';
      Noflines := 0;
      name := "";
      status=_get_clipboard_header(cbtype,Noflines,name);
      if (status) {
         break;
      }
      header_linenum:=p_line;
      if ( skip_named_clipboards ) {
         if ( name==NULL_CB_NAME ) {
            if ( i==clipboard_index ) {
               break;
            }
            i++;
         }
      } else {
         if ( i==clipboard_index ) {
            break;
         }
         i++;
      }
      status=down(Noflines);
      if (status) {
         break;
      }
      ++Nofclipboards_count;
      if (name==NULL_CB_NAME) {
         ++Nofnulls_count;
      }
      header_linenum_of_last_good_clipboard=header_linenum;
      last_linenum_of_last_good_clipboard=p_line;
      status=down();
      if (status) {
         break;
      }
   }
   if (status) {
      // we are in really bad shape;
      _Nofclipboards=Nofclipboards_count;
      _Nofnulls=Nofnulls_count;
      p_line=last_linenum_of_last_good_clipboard;
      if (!down()) {
         // Get rid of everything after the last line of the good clipboard;
         _begin_line();
         _delete_text(-2);
         _delete_line();
      }
      p_line=header_linenum_of_last_good_clipboard;
   }
}
/**
 * Invokes one of the built-ins <b>_select_char</b>,
 * <b>_select_block</b>, or <b>_select_line</b> corresponding to the
 * <i>mark_name</i> values 'CHAR', 'BLOCK', and 'LINE'.  The
 * <i>mark</i> parameter specifies the mark id.
 *
 * @categories Selection_Functions
 *
 */
void select_it(_str mark_name, _str mark, _str options='')
{
   _str a3=translate(options,'NI','01');
   if ( mark_name=='LINE' ) {
      _select_line(mark,a3);
   } else if ( mark_name=='BLOCK' ) {
      _select_block(mark,a3);
      if (!def_inclusive_block_sel) {
         _select_type(mark,'I',0);
      }
   } else if ( mark_name=='CHAR' ) {
      _select_char(mark,a3);
   }

}
static int paste_would_create_line_too_line(_str temp_line,int Noflines,int sel_lines) {
   if (p_TruncateLength > 0 && Noflines == 1 && sel_lines <= 1) {
      orig_col := p_col;
      is_blank := !_first_non_blank_col(0);
      if (!is_blank) {
         _save_pos2(auto p2);
         _begin_line();
         int begin_offset = (int)_QROffset();
         _TruncEndLine();
         if (p_col < orig_col) {
            p_col = orig_col;
         }
         int end_offset = (int)_QROffset();
         _restore_pos2(p2);
         temp_line :+= get_text(end_offset-begin_offset,begin_offset);
      } else {
         leading_space := substr('',1,p_col-1);
         temp_line = leading_space :+ temp_line;
      }
      new_bytes := length(temp_line);
      int new_trunc_length = _TruncateLengthC(temp_line,new_bytes);
      if (new_trunc_length != 0 && new_bytes > new_trunc_length) {
         if (sel_lines == 1) {
            undo();
         }
         message(get_message(VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG));
         return(VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG);
      }
   }
   return 0;
}
static int _paste_hex_view(bool from_sysclipboard, bool isClipboard,typeless &mark, int MarkFlags) {
   get_window_id(auto view_id);
   _create_temp_view(auto temp_view_id2);
   int status;
   typeless dup_mark;
   if (from_sysclipboard) {
      status=_copy_from_clipboard(isClipboard);
   } else {
      if (_select_type(mark)=='CHAR') {
         insert_line('');_delete_text(-2);
      }
      dup_mark=_duplicate_selection(mark);
      status=_copy_or_move(dup_mark,'C',false /* no SmartPaste(R) */ ,false /* no deselect */,( _select_type(dup_mark)=='BLOCK')?VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE:MarkFlags);
   }
   _str binary;
   if (status) {
      if (!from_sysclipboard) {
         _free_selection(mark);
         mark=dup_mark;
      }
      _delete_temp_view(temp_view_id2);
      activate_window(view_id);
      return(status);
   }
   top();
   if (_on_line0()) {
      status=1;
   } else {
      _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
      _default_option(VSOPTION_WARNING_STRING_LENGTH,0x7FFFFFFF);
      hex_view:=get_text(p_buf_size,0);
      status=_HexViewToBinary(hex_view,binary);
      //say('len='length(binary)' status='status);
      _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
   }
   if (!from_sysclipboard) {
      if (!status) {
         _free_selection(mark);
         mark=dup_mark;
      } else {
         _free_selection(dup_mark);
      }
   }
   _delete_temp_view(temp_view_id2);
   activate_window(view_id);
   if (!status) {
      orig_newline:=p_newline;
      p_newline=last_char(p_newline);
      _insert_text_raw(binary,true,p_newline);
      p_newline=orig_newline;
   }
   return status;
}
int paste2(_str persistent_select='',int temp_view_id=0,_str name='',bool isClipboard=true,int MarkFlags=-1)
{
   UseNamedClipboard := name!="";
   typeless cb_format='';
   typeless pid='';
   typeless cbtype='';
   typeless cbrest='';
   typeless p=0;
   typeless select_style='';
   typeless status=0;
   if (temp_view_id==0 || temp_view_id==_clipboards_view_id) {
      temp_view_id=_clipboards_view_id;
      cb_format=_clipboard_format(VSCF_VSTEXTINFO,isClipboard);
      // Note: _clipboard_empty does not really work. It only checks
      // if a couple clipboard formats are available.  That's
      // why the error message is ambiguous.
      if (!UseNamedClipboard && !cb_format && _clipboard_empty(isClipboard)) {
         message(nls('Clipboard empty or clipboard format not supported'));
         return(1);
      }
      //messageNwait('cb_format='cb_format);
      parse cb_format with 'pid='pid cbtype cbrest;
      // IF we are not pasted a named clipboard AND
      //    this clipboard we are pasting is from another
      //    SlickEdit process (or just a VSE clipboard)
      if (!UseNamedClipboard && pid!='' && getpid()!=pid) {
         temp_view_id=_cvtsysclipboard2(true,cbtype,cbrest,p_UTF8,isClipboard,p_lexer_name,MarkFlags);
         pid=getpid();
      }
   }
   if (!UseNamedClipboard &&
       temp_view_id==_clipboards_view_id &&
       (!cb_format || getpid()!=pid || !_Nofclipboards)) {
      sel_lines := 0;
      if (!_clipboard_format(VSCF_TEXT,isClipboard)) {
         _message_box(nls('This operation is not supported with this clipboard format'));
         return(1);
      }
      if ( ! (_select_type('','U')=='P' && _select_type('','S')=='E') &&
         persistent_select=='D' && select_active() && _within_char_selection()) {
         _begin_select();
         sel_lines=count_lines_in_selection();
         if (_select_type()=='LINE') p_col=1;
         p=point();
         _delete_selection();
         // IF deleted last line of buffer
         if (p!=point()) {
            insert_line('');
         }
      }
      /* If user wants inserted clipboard text marked. */
      if (!def_deselect_paste) {
         _deselect();
         select_style='';
#if 0
         if (pos('C',def_select_style)) {
            select_style='C';
         }
#endif
         _select_char('',select_style);
      }
      // Watch out for paste replace deleting all lines
      if (_on_line0()) {
         insert_line('');
      }
      int cbid=_cvtsysclipboard2(true,'CHAR','',p_UTF8,isClipboard,p_lexer_name);
      view_id := 0;
      get_window_id(view_id);
      activate_window(cbid);
      _get_clipboard_header(auto cbt,auto Noflines,auto junk1,auto junk2,auto utf8);
      down();_begin_line();
      _str temp_line;
      if (view_id.p_TruncateLength) {
         get_line(temp_line);
      }
      down(Noflines-1);_end_line();
      _delete_temp_view(cbid);

      activate_window(view_id);
      // wholesaled from below for internal cbs
      status=paste_would_create_line_too_line(temp_line,Noflines,sel_lines);
      if (status) {
         return status;
      }
      status=1;
      if (MarkFlags !=-1 && (MarkFlags & VSMARKFLAG_PASTE_HEX_VIEW)) {
         status=_paste_hex_view(true,isClipboard, '', MarkFlags);
      }
      if (status) {
         status=_copy_from_clipboard(isClipboard,(MarkFlags !=-1 && (MarkFlags & VSMARKFLAG_BINARY)));
         if (status) {
            message(get_message(status));
            return(status);
         }
      }
      if (!def_deselect_paste) {
         _select_char('',select_style);
         // _cua_select=1
      }
      //_updateTextChange();  don't think we need this
      return(0);
   }
   if ( ! _Nofclipboards && temp_view_id==_clipboards_view_id) {
      message(nls('Clipboard empty'));
      return(1);
   }
   do_free_mark := false;
   typeless mark='';
   if ( def_deselect_paste ) {
      mark=_duplicate_selection();
      do_free_mark=true;
      if ( mark<0 ) {
         mark=_duplicate_selection('');
      }
   } else {
      mark=_duplicate_selection('');
   }
   view_id := 0;
   get_window_id(view_id);
   typeless line2char=0;
   typeless savecol='';
   typeless insert_after='';
   typeless begin_p=0;
   sel_lines := 0;
   if ( ! (_select_type('','U')=='P' && _select_type('','S')=='E') &&
      persistent_select=='D' && select_active() && _within_char_selection() ) {
      /* _macro_append("_begin_select;if ( _select_type()=='LINE' ) p_col=1;_delete_selection") */
      _begin_select();
      sel_lines=count_lines_in_selection();
      begin_p=point();
      if ( _select_type()=='LINE' ) {
         savecol=p_col;
         p_col=1;
         insert_after='B';
      }
      line2char=1;
      _delete_selection();
      /* IF active mark is a LINE mark AND line number changed. */
      if ( savecol!='' && begin_p!=point() ) {
         insert_after='A';
      }
   }

   _deselect(mark);
   activate_window(temp_view_id);
   mark_name := "";
   Noflines := 0;
   typeless junk1,junk2;
   typeless utf8=0;
   _get_clipboard_header(mark_name,Noflines,junk1,junk2,utf8);
   orig_utf8 := p_UTF8;
   p_UTF8=utf8;
   if ( line2char && mark_name=='LINE' ) {
      if ( savecol!='' ) {
         line2char=0;
      } else {
         line2char=1;
         mark_name='CHAR';
      }
   } else {
      line2char=0;
      savecol='';
   }
   down();_begin_line();select_it(mark_name,mark);
   _str temp_line;
   if (view_id.p_TruncateLength) {
      get_line(temp_line);
   }
   down(Noflines-1);_end_line();
   if ( line2char ) {
      right();
   } else {
      if ( mark_name:!='CHAR' ) left();
   }
   typeless line_insert=def_line_insert;
   if (mark_name=='BLOCK' && !_select_type(mark,'I')) {
      right();
   }
   select_it(mark_name,mark);
   _begin_select(mark);up();         /* back to :mark_name nnnn */
   activate_window(view_id);
   if ( savecol!='' ) {  /* If active mark and clipboard are LINE marks? */
      line_insert=def_line_insert;
      def_line_insert=insert_after;
   } else if ( insert_after=='A' ) {
      insert_line('');
   }
   if (_select_type(mark)=='BLOCK' && _on_line0()) {
      insert_line('');
   }
   // Since we are insert at the cursor and don't want the cursor
   // moved. Save and restore the cursor.
   if ( _select_type(mark)=='BLOCK' && def_modal_paste && ! _insert_state() ) {
      status=_overlay_block_selection(mark,VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE);
   } else {
      if (_select_type(mark)=='CHAR') {
         status=paste_would_create_line_too_line(temp_line,Noflines,sel_lines);
         if (status) {
            return status;
         }
      }
      status=1;
      if (MarkFlags !=-1 && (MarkFlags & VSMARKFLAG_PASTE_HEX_VIEW)) {
         status=_paste_hex_view(false,false,mark,MarkFlags);
      }
      if (status) {
         status=_copy_or_move(mark,'C',false /* no SmartPaste(R) */ ,false /* no deselect */,( _select_type(mark)=='BLOCK')?VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE:MarkFlags);
      }
   }
   activate_window(temp_view_id);p_UTF8=orig_utf8;activate_window(view_id);
   if ( savecol!='' ) {
      def_line_insert=line_insert;
   }
   if ( ! status ) {
      if ( mark_name=='BLOCK' ) {
         switch (def_paste_block_cursor_end) {
         case 0:
            //_begin_select(mark,true,false);
            break;
         case 1:
         case 3:
            {
               col := p_col;
               int columnStartPixel,columnEndPixel;
               _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,mark);
               _end_select(mark,true,false);
               if (down()) {
                  if (def_paste_block_cursor_end==1) {
                     insert_line('');
                     _delete_text(2); // Delete NLChars
                  }
               }
               if (columnStartPixel>=0) {
                  int start_col,end_col;
                  _BlockSelGetStartAndEndCol(start_col,end_col, columnStartPixel,columnEndPixel,mark);
                  p_col=start_col;
                  //if(_select_type(mark,'I')) left();
               } else {
                  p_col=col;
               }
            }
            break;
         case 2:
            _end_select(mark,true,false);
            break;
         }
      } else {
         _end_select(mark,true,false);
      }
   }
   if ( savecol!='' ) {
      p_col=savecol;
   }
   if ( def_deselect_paste ) {
      if ( do_free_mark ) {
         _free_selection(mark);
      } else {
         _deselect();
      }
   }
   if (temp_view_id!=_clipboards_view_id) {
      _delete_temp_view(temp_view_id);
   }
   return(status);
}

/**
 * Replaces the current word (where cursor is) with the current clipboard.  No
 * selection is required.
 * 
 * @return Returns 0 if successful.  
 * 
 * @see paste
 * @categories Clipboard_Functions
 */
_command void paste_replace_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   init_command_op();
   start_pcol := 0;
   _str word=cur_word(start_pcol);
   if (word!='') {
      p_col=_text_colc(start_pcol,'I');
      delete_word();
   }
   paste();
   retrieve_command_results();
}

/*
 * Run results of command line/textbox paste through callback
 * processing.
 * <p>
 * A typical use for this callback mechanism is to define
 * a callback to condense a multiline paste into a single
 * line (this is what the Dialog Editor properties sheet uses
 * when pasting multiple lines of html into the text field of
 * a minihtml control). Any function of the following form will
 * automatically be called when pasting into a command line/textbox:
 * </p>
 * <pre>
 * bool _ProcessCommandPaste_[callback-suffix](int targetWid, int firstLineNumber, int lastLineNumber)
 *
 * targetWid       is the target window of the paste
 * firstLineNumber is the first line number of the pasted text in the current window
 * lastLineNumber  is the last line number of the pasted text in the current window
 *
 * The callback returns true if it processed the command results, and false if it did not.
 * </pre>
 *
 * <p>
 * When this function is called, the text has been pasted into the current window (a hidden window).
 * The callback should not assume that the current line is the first line, and must certainly not
 * process lines outside the range of the first-last lines of the pasted text.
 * </p>
 *
 * <p>
 * Note: As soon as a callback return true, processing stops and this function returns.
 * </p>
 *
 * <p>
 * Note: On return the cursor is guaranteed to be on last line of pasted text.
 * </p>
 */
static void process_command_paste(int targetWid, int firstLineNumber, int lastLineNumber)
{
   origNoflines := p_Noflines;
   bstatus := false;
   int index = name_match("_ProcessCommandPaste_",1,PROC_TYPE);
   while( index > 0 ) {
      if( index_callable(index) ) {
         bstatus=call_index(targetWid,firstLineNumber,lastLineNumber,index);
         if( bstatus ) {
            break;
         }
      }
      index=name_match("_ProcessCommandPaste_",0,PROC_TYPE);
   }
   // Ensure sanity in the retrieve buffer after callback is finished
   if( p_window_id != VSWID_RETRIEVE ) {
      p_window_id=VSWID_RETRIEVE;
   }
   if( origNoflines != p_Noflines ) {
      // Guarantee that we are on last line of destination pasted text on return
      int Noflines = lastLineNumber - firstLineNumber + 1;
      int diffNoflines = origNoflines - p_Noflines;
      p_line=firstLineNumber + (Noflines - diffNoflines) - 1;
   } else {
      p_line=lastLineNumber;
   }
}

int _paste_as_one_clipboard(_str name='',bool isClipboard=true,int temp_view_clipboard=0,int MarkFlags=-1)
{
   name=strip(name);
   begin_col := 0;
   sel_len := 0;
   line := "";
   mark_name := "";
   Noflines := 0;
   linenum := 0;
   isinternal := false;
   view_id := 0;
   typeless mark='';
   typeless status=0;
   if ( command_state() ) {
      begin_col=p_sel_start;
      sel_len=p_sel_length;
      if ( sel_len ) {
         // Delete selected text
         get_command(line);
         line=substr(line,1,begin_col-1):+substr(line,begin_col+sel_len);
         set_command(line,begin_col);
      }
      get_window_id(view_id);
      mark_name='CHAR';
      isinternal=_isclipboard_internal(false,isClipboard);
      if (isinternal) {
         // ??? might be internal
         activate_window(_clipboards_view_id);

         if ( name!='' ) {
            status=goto_named_clipboard(name);
            if ( status ) {
               goto_clipboard(_Nofclipboards);  /* Reset the current clipboard */
               activate_window(view_id);
               message(nls("Unable to find named clipboard: "name));
               return(1);
            }
         } else {
            goto_clipboard(_Nofclipboards);  /* Make sure we start at the most current clipboard */
         }

         _get_clipboard_header(mark_name,Noflines);
         activate_window(view_id);
      }
      if ( _select_type()!='' ) {
        mark=_duplicate_selection();
        if ( mark<0 ) clear_message();  /* If can't save mark no big deal. */
      } else {
        mark='';
      }
      init_command_op();
      linenum=p_line;
      _str old_def_line_insert=def_line_insert;
      def_line_insert='A';

      int temp_view_id=_cvtsysclipboard(name,isClipboard);
      if ( upcase(mark_name)=='LINE' ) {
         _delete_line();
         status=paste2('',temp_view_id,name,isClipboard);
         // In case we were on line 0??
         down();
      } else {
         status=paste2('',temp_view_id,name,isClipboard);
      }

      // Give command line/textbox callback processing a whack at it
      last_linenum := p_line;
      if( isinternal && mark_name == "BLOCK" ) {
         // Block selections are always put cursor at beginning (first line) of
         // the destination pasted text, so we have to calculate the last
         // line number.
         last_linenum=linenum + Noflines - 1;
      }
      process_command_paste(view_id,linenum,last_linenum);

      // Delete extra lines before retrieving result to the command line/textbox
      while (p_line>linenum) {
         _delete_line();
      }
      def_line_insert=old_def_line_insert;
      retrieve_command_results();

      if ( mark!='' ) {
        int cur_mark=_duplicate_selection('');
        _show_selection(mark);
        _free_selection(cur_mark);
      }
      return(status);
   }

   if (!_insertion_valid()) {
      return(VSRC_THIS_OPERATION_IS_NOT_ALLOWED_AFTER_TRUNCATION_LENGTH);
   }

   if (commentwrap_Paste(name, isClipboard,temp_view_clipboard)) {
      return 0;
   }
   if (XW_Paste(name, isClipboard,temp_view_clipboard)) {
      return 0;
   }
   /* HERE */
   mark_name=_clipboard_get_mark_type(isClipboard,name,temp_view_clipboard);
   if (mark_name=='') {
      if (name!='') {
         message(nls("Unable to find named clipboard: "name));
         return(1);
      }
      // Clipboard format is valid
      return(1);
   }

   //status=paste2("","",name);
   status=smart_paste("","",name,isClipboard,lowcase(mark_name),temp_view_clipboard,MarkFlags);
 #if 1
   // BRIEF paste already does this
   called_from_brief := ( name_name(last_index())=='brief-paste' );
   if ( !status && upcase(def_line_insert)=='B' && mark_name:=="LINE" && !called_from_brief ) {
      down();
   }
 #endif
   return(status);
}
_str _clipboard_get_last_clipboard_name() {
   if (!_Nofclipboards) {
      return '';
   }
   get_window_id(auto view_id);
   activate_window(_clipboards_view_id);
   goto_clipboard(_Nofclipboards);  /* Make sure we paste the most current clipboard */
   _get_clipboard_header(auto junk_mark_type,auto junk_Noflines, auto cb_name, auto junk_col, auto junk_utf8,auto junk_lexername,auto junk_multiCursorCount);
   activate_window(view_id);
   return cb_name;
}
_str _clipboard_get_mark_type(bool isClipboard=true,_str name='',int temp_view_clipboard=0,int &multiCursorCount=0) {

   _str mark_type;
   view_id := 0;
   get_window_id(view_id);
   multiCursorCount=0;
   if (temp_view_clipboard) {
      p_window_id=temp_view_clipboard;
      top();
      _get_clipboard_header(mark_type);
      activate_window(view_id);
      return mark_type;
   } 
   activate_window(_clipboards_view_id);
   if ( name!='' ) {
      int status=goto_named_clipboard(name);
      if ( status ) {
         goto_clipboard(_Nofclipboards);  /* Reset the current clipboard */
         activate_window(view_id);
         return '';
      }
   } else {
      if (!_clipboard_format(VSCF_TEXT,isClipboard)) {
         // System clipboard is not text format
         return(''); // error
      }
      goto_clipboard(_Nofclipboards);  /* Make sure we paste the most current clipboard */
   }
   UseNamedClipboard := name!='';
   if (UseNamedClipboard) {
      _get_clipboard_header(mark_type,auto junk_Noflines, auto junk_name, auto junk_col, auto junk_utf8,auto junk_lexername,multiCursorCount);
   } else {
      typeless cb_format=_clipboard_format(VSCF_VSTEXTINFO,isClipboard);
      typeless pid='';
      swidth := "";
      _str smultiCursorCount;
      parse cb_format with 'pid='pid mark_type swidth smultiCursorCount .;
      mark_type=upcase(mark_type);
      if (mark_type=='') {
         mark_type='CHAR';
      }
      multiCursorCount=0;
      if (isinteger(smultiCursorCount) && smultiCursorCount>1) {
         multiCursorCount=(int)smultiCursorCount;
      }
   }
   activate_window(view_id);
   return mark_type;
}
/*int _OnUpdate_paste(CMDUI &cmdui,int target,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if ( _HaveClipboard() ) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
*/


static int gmc_paste_view_id;
static int gmc_pasting_lines;
static int gmc_paste_markid;
static _str gmc_mark_type;
/**
 * <p>Inserts the clipboard at the cursor.  If <i>cbname</i> is given, then the
 * internal clipboard with name <i>cbname</i> is inserted.  LINE type
 * clipboards are inserted before or after the current line depending upon
 * the <b>Line insert style</b>.  By default, they are inserted after the
 * cursor.  By default, BLOCK type clipboards are inserted even when
 * the cursor is in replace mode.  If you want BLOCK type clipboards to
 * overwrite the destination text when your cursor is in replace mode,
 * invoke the command "set-var def-modal-paste 1".</p>
 *
 * <p>IMPORTANT:  <i>cbname</i> needs to start with an alphabetic
 * character (a-z).  numeric values for <i>cbname</i> are reserved for VI
 * emulation.</p>
 *
 * <p>In ISPF emulation, this command is not called when invoked from the
 * command line.  Instead ispf_paste is called.  Use ("Edit", "Paste") to
 * explicitly invoke the paste command.</p>
 * 
 * @param name   Optional name of an internal clipboard to paste
 * @param isClipboard  Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 * @param override_mark_type
 *     Optional override for the clipboard type. Can be "LINE",
 *     "BLOCK", or "CHAR". This is most useful for pasting a
 *     BLOCK/COLUMN clipboard as either a LINE or CHAR
 *     clipboard.
 * @param override_lines_per_cursor
 *     Optional override for the number of lines to paste per
 *     cursor. This argument is ignored unless there
 *     is more than one cursor.
 * @param override_strip_spaces_option
 *     Optionally specifies whether to strip leading, trailing,
 *     or leading and trailing spaces. Can be "L"-leading,
 *     "T"-trailing, or "B"-both. For example, when pasting a
 *     BLOCK clipboard as a LINE or CHAR type clipboard
 *     (override_mark_type='BLOCK'), it is very useful to strip
 *     trailing spaces on each line.
 *
 * @return Returns 0 if successful.  Common return code is 1 (clipboard empty,
 * or clipboard text too long for command line).  On error, message is
 * displayed.
 *
 * @see paste
 * @see paste_binary
 * @see paste_text
 * @see paste_special
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 *
 */
_command int paste(_str name="",bool isClipboard=true, _str override_mark_type='', int override_lines_per_cursor=0, _str override_strip_spaces_option='',int MarkFlags=-1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   if (MarkFlags==-1 && !command_state()) {
      if (p_hex_mode==HM_HEX_ON && p_hex_field && def_hex_view_copy) {
         MarkFlags=(VSMARKFLAG_BINARY|VSMARKFLAG_KEEP_SRC_NLCHARS|VSMARKFLAG_PASTE_HEX_VIEW);
      } else if (p_hex_mode==HM_HEX_ON && def_hex_binary_copy) {
         MarkFlags=(VSMARKFLAG_BINARY|VSMARKFLAG_KEEP_SRC_NLCHARS);
      }
   }

   cmdname:=name_name(last_index('','C'));
   //typeless executed_from_key=name_name(last_index()):==translate(cmdname,'-','_');
   executed_from_menu_or_cmdline := last_index('','w');

   /*
      Since _on_select() is NOT called when paste() is executed
      from the menu, toolbar, or command line.
      See if we need to do block mode key now.
   */
   if (executed_from_menu_or_cmdline) {
      _str keya=null;
      _str cbtype=_getClipboardMarkType();
      if (cbtype!='BLOCK' && cbtype!='') {
         // Returns
         keya=_getClipboardText(true,true,'',(p_object==OI_EDITOR)?p_UTF8:true);
      }
      if (name=='' && isClipboard && 
          keya!=null && (p_object==OI_EDITOR && !p_hex_mode) && !_MultiCursorAlreadyLooping() && doBlockModeKey('',keya,true)) {
         //_macro_call('doBlockModeKey','',keya,true));
         //last_index(find_index('doBlockModeKey',PROC_TYPE|COMMAND_TYPE),'C');
         return 0;
      }
   }


   temp_view_clipboard := 0;
#if 1
   if (!command_state()) {
      override_strip_spaces_option=upcase(override_strip_spaces_option);
      paste_flags:=0;
      if (_MultiCursorFirstLoopIteration()) {
         gmc_pasting_lines=0;
         int count=_MultiCursorCount();
         int multiCursorCount;
         // NOTE: If this is an NOT an internal clipboard or VS compatible clipboard, 
         //       multiCursorCount will be 0
         gmc_mark_type=_clipboard_get_mark_type(isClipboard,name,0,multiCursorCount);
         special_multi_cursor_block_paste:=false;
         if (special_multi_cursor_block_paste) {
            override_mark_type='CHAR';
            override_strip_spaces_option='T';
            override_lines_per_cursor=1;
         }
         if (gmc_mark_type!='' && override_mark_type!='') {
            gmc_mark_type=override_mark_type;
         }

         if (gmc_mark_type!='' && (multiCursorCount==count || override_lines_per_cursor>0)) {
            was_utf8 := p_UTF8;
            int orig_view_id=_create_temp_view(gmc_paste_view_id);
            p_UTF8=was_utf8;
            top();
            int orig_markid;
            save_selection(orig_markid);
            int status=_paste_as_one_clipboard(name,isClipboard,0,MarkFlags);
            restore_selection(orig_markid);
            if (status) {
               _delete_temp_view(gmc_paste_view_id);
               p_window_id=orig_view_id;
               return status;
            }
            if (override_lines_per_cursor>0 && p_Noflines<=override_lines_per_cursor) {
               // Assume user wants to repeat this one clipboard for each clipboard
               _delete_temp_view(gmc_paste_view_id);
            } else {
               if ((override_lines_per_cursor>0) && (p_Noflines>count*override_lines_per_cursor)) {
                  _delete_temp_view(gmc_paste_view_id);
                  _message_box(nls("There are %s1 lines but only %s2 cursors. Need more cursors or fewer lines in the clipboard.",p_Noflines,count));
                  p_window_id=orig_view_id;
                  _MultiCursorLoopDone();
                  return INVALID_ARGUMENT_RC;
               }
               if (override_lines_per_cursor>0) {
                  gmc_pasting_lines=override_lines_per_cursor;
                  //gmc_paste_markid=_alloc_selection();
                  top();up();
               } else if (p_Noflines && count && (p_Noflines%count)==0) {
                  gmc_pasting_lines=p_Noflines intdiv count;
                  //gmc_paste_markid=_alloc_selection();
                  top();up();
               } else {
                  _delete_temp_view(gmc_paste_view_id);
               }
               if (gmc_pasting_lines) {
                  if (override_strip_spaces_option=='T') {
                     // Strip trailing white spaces
                     search('[ \t]#$','@r','');
                     top();up();
                  } else if (override_strip_spaces_option=='L') {
                     // Strip leading white spaces
                     search('^[ \t]#','@r','');
                     top();up();
                  } else if (override_strip_spaces_option=='B') {
                     // Strip leading white spaces
                     search('^[ \t]#','@r','');
                     top();up();
                     // Strip trailing white spaces
                     search('[ \t]#$','@r','');
                     top();up();
                  }
               }
            }
            p_window_id=orig_view_id;
         }
      } 
      if (gmc_pasting_lines && _MultiCursorAlreadyLooping()) {
         orig_view_id := p_window_id;
         was_utf8 := p_UTF8;
         _str lexername=p_lexer_name;
         p_window_id=gmc_paste_view_id;
         int status=down();
         if (!status) {
            int markid=_alloc_selection();
            start_line := p_line;
            if (gmc_mark_type=='LINE') {
               _select_line(markid);
               down(gmc_pasting_lines-1);
               _select_line(markid);
            } else {
               _begin_line();_select_char(markid);
               down(gmc_pasting_lines-1);
               _end_line();_select_char(markid);
            }
            end_line := p_line;
            // Create a temporary internal clipboard.
            // It usually gets freed in _paste_as_one_clipboard() but not always.
            _create_temp_view(temp_view_clipboard);
            p_buf_name='.multicursor';
            p_UTF8=was_utf8;
            _add_clipboard_header(gmc_mark_type,end_line-start_line+1/*gmc_pasting_lines*/,NULL_CB_NAME,0,was_utf8,lexername);
            if (gmc_mark_type!='LINE') {
               insert_line('');_begin_line();
            }
            _copy_to_cursor(markid);
            _free_selection(markid);
         }
         p_window_id=orig_view_id;
         if (_MultiCursorLastLoopIteration()) {
            _delete_temp_view(gmc_paste_view_id);
            //_free_selection(gmc_paste_markid);
         }
         if (status) {
            p_window_id=orig_view_id;
            // No line to paste at this cursor
            return 0;
         }
         //return 0;
      }
      //say('override_mark_type='override_mark_type);
      //say('gmc_pasting_lines='gmc_pasting_lines);
      //say('override_strip_spaces_option='override_strip_spaces_option);
      if ((override_mark_type!='' || override_strip_spaces_option!='') && 
          (!_MultiCursorAlreadyLooping() || !gmc_pasting_lines)) {
         int multiCursorCount;
         _str type=_clipboard_get_mark_type(isClipboard,name,0,multiCursorCount);
         {
            was_utf8 := p_UTF8;
            _str lexername=p_lexer_name;
            int orig_view_id=_create_temp_view(temp_view_clipboard);
            p_UTF8=was_utf8;
            top();
            int orig_markid;
            save_selection(orig_markid);
            int status=_paste_as_one_clipboard(name,isClipboard,0,MarkFlags);
            paste_Noflines:=p_Noflines;
            restore_selection(orig_markid);
            if (status) {
               _delete_temp_view(gmc_pasting_lines);
               p_window_id=orig_view_id;
               return status;
            }
            if (override_mark_type!='') {
               type=override_mark_type;
            }
            top();up();
            if (override_strip_spaces_option=='T') {
               // Strip trailing white spaces
               search('[ \t]#$','@r','');
               top();up();
            } else if (override_strip_spaces_option=='L') {
               // Strip leading white spaces
               search('^[ \t]#','@r','');
               top();up();
            } else if (override_strip_spaces_option=='B') {
               // Strip leading white spaces
               search('^[ \t]#','@r','');
               top();up();
               // Strip trailing white spaces
               search('[ \t]#$','@r','');
               top();up();
            }
            _add_clipboard_header(type,paste_Noflines,NULL_CB_NAME,0,was_utf8,lexername);
            p_window_id=orig_view_id;
         }
      }
   }
#endif
   int status=_paste_as_one_clipboard(name,isClipboard,temp_view_clipboard,MarkFlags);

   if (temp_view_clipboard && buf_match('.multicursor',1,'HX')!='') {
      _delete_temp_view(temp_view_clipboard);
   }

   return status;
}

/**
 * <p>Same as {@link paste()} except newlines are not translated when pasted.
 *
 * <p>IMPORTANT: Intended to be used with {@link copy_binary()}. 
 * Only works for binary internal clipboards.
 *
 * @return Returns 0 if successful.
 * 
 * @see paste
 * @see paste_binary
 * @see paste_text
 * @see paste_special
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 *
 */
_command int paste_binary(_str name="",bool isClipboard=true, _str override_mark_type='', int override_lines_per_cursor=0, _str override_strip_spaces_option='',int MarkFlags=VSMARKFLAG_BINARY|VSMARKFLAG_KEEP_SRC_NLCHARS) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD) {
   return paste(name,isClipboard,override_mark_type,override_lines_per_cursor,override_strip_spaces_option,MarkFlags);
}
/**
 * <p>Same as {@link paste()} except newlines are always
 * translated when pasted.
 *
 * <p>IMPORTANT: Intended to be used with {@link copy_as_text()}. 
 * Only works for binary internal clipboards.
 *
 * @return Returns 0 if successful.
 * 
 * @see paste
 * @see paste_binary
 * @see paste_text
 * @see paste_special
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 *
 */
_command int paste_text(_str name="",bool isClipboard=true, _str override_mark_type='', int override_lines_per_cursor=0, _str override_strip_spaces_option='',int MarkFlags=0) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD) {
   return paste(name,isClipboard,override_mark_type,override_lines_per_cursor,override_strip_spaces_option,MarkFlags);
}
/**
 * <p>Inserts the clipboard at the cursor with some special
 * clipboard type translations. If <i>cbname</i> is given, then
 * the internal clipboard with name <i>cbname</i> is
 * inserted.</p>
 * 
 * <p>If this is a multicursor paste of a BLOCK clipboard, paste
 * as multiple BLOCK clipboards (1 per cursor) with trailing
 * whitespace stripped</p>
 * <p>If the clipboard is a BLOCK clipboard and there is only 1
 * cursor, paste as a CHAR clipboard with trailing whitespace
 * stripped.</p>
 * <p>If the clipboard is a CHAR clipboard and there is only 1 
 * cursor, paste as a LINE clipboard</p>
 * <p>If the clipboard is a LINE clipboard and there is only 1
 * cursor, paste as a CHAR clipboard</p>
 * 
 * <p>LINE type clipboards are inserted before or after the
 * current line depending upon
 * the <b>Line insert style</b>.  By default, they are inserted after the
 * cursor.  By default, BLOCK type clipboards are inserted even when
 * the cursor is in replace mode.  If you want BLOCK type clipboards to
 * overwrite the destination text when your cursor is in replace mode,
 * invoke the command "set-var def-modal-paste 1".</p>
 *
 * <p>IMPORTANT:  <i>cbname</i> needs to start with an alphabetic
 * character (a-z).  numeric values for <i>cbname</i> are reserved for VI
 * emulation.</p>
 *
 * @return Returns 0 if successful.  Common return code is 1 (clipboard empty,
 * or clipboard text too long for command line).  On error, message is
 * displayed.
 *
 * @see paste
 * @see paste_binary
 * @see paste_text
 * @see paste_special
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 *
 */
_command int paste_special(_str name="",bool isClipboard=true) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   override_mark_type := "";
   override_lines_per_cursor := 0;
   override_strip_spaces_option := "";
   if (!command_state()) {
      if (_MultiCursorAlreadyLooping()) {
         int multiCursorCount;
         // NOTE: If this is an NOT an internal clipboard or VS compatible clipboard, 
         //       multiCursorCount will be 0
         mark_type:=_clipboard_get_mark_type(isClipboard,name,0,multiCursorCount);
         if (mark_type=='BLOCK') {
            override_mark_type='CHAR';
            override_lines_per_cursor=1;
            override_strip_spaces_option='T';
         } else if (mark_type=='LINE') {
            override_mark_type='CHAR';
            override_lines_per_cursor=1;
            override_strip_spaces_option='';
         } else if (mark_type=='CHAR') {
            override_mark_type='LINE';
            override_lines_per_cursor=1;
            override_strip_spaces_option='';
         }
       } else {
          int multiCursorCount;
          // NOTE: If this is an NOT an internal clipboard or VS compatible clipboard, 
          //       multiCursorCount will be 0
           mark_type:=_clipboard_get_mark_type(isClipboard,name,0,multiCursorCount);
          if (mark_type=='BLOCK') {
             override_mark_type='LINE';
             //override_lines_per_cursor=1;
             override_strip_spaces_option='T';
          } else if (mark_type=='LINE') {
             override_mark_type='CHAR';
             //override_lines_per_cursor=1;
             override_strip_spaces_option='';
          } else if (mark_type=='CHAR') {
             override_mark_type='LINE';
             //override_lines_per_cursor=1;
             override_strip_spaces_option='';
          }
       }
   }
   return paste(name,isClipboard, override_mark_type,override_lines_per_cursor,override_strip_spaces_option);
}

/**
 * <p>Overlays the contents of the clipboard at the cursor.
 * If <i>cbname</i> is given, then the
 * internal clipboard with name <i>cbname</i> is inserted.
 * The behavior is similar to overlays in ISPF.
 * <p>
 * IMPORTANT:  <i>cbname</i> needs to start with an alphabetic
 * character (a-z).  numeric values for <i>cbname</i> are reserved for VI
 * emulation.</p>
 *
 * @return Returns 0 if successful.  Common return code is 1 (clipboard empty,
 * or clipboard text too long for command line).  On error, message is
 * displayed.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 *
 */
_command int overlay_clipboard(_str name='',bool isClipboard=true) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   // save position and other information
   save_pos(auto p);
   orig_col := p_col;
   orig_utf8 := p_UTF8;

   // create a temp view for the clipboard
   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   if (orig_view_id <= 0) {
      return orig_view_id;
   }

   // preserve utf8 mode
   p_UTF8 = orig_utf8;
   insert_line('');

   // paste the named clipboard into the temp view
   _str orig_line_insert = def_line_insert;
   def_line_insert = 'B';
   int status = paste(name, isClipboard);
   def_line_insert = orig_line_insert;
   if (status < 0) {
      return status;
   }

   // go to the start of the clipboard
   _GoToROffset(0);
   for (;;) {

      // start at the first column
      orig_view_id.p_col = orig_col;
      temp_view_id.p_col = 1;

      for (;;) {

         // past end of line?
         if (p_col > _line_length()) {
            break;
         }

         // get a character from the clipboard, skip if blank
         new_ch := temp_view_id.get_text();
         if (new_ch == '') {
            orig_view_id.p_col++;
            temp_view_id.p_col++;
            continue;
         }

         // past end of line in target buffer?
         old_ch := "";
         if (orig_view_id.p_col <= orig_view_id._line_length()) {

            // get the original character, skip of non-blank
            old_ch = orig_view_id.get_text();
            if (old_ch != '') {
               orig_view_id.p_col++;
               temp_view_id.p_col++;
               continue;
            }

            // check if we are on a tab character and compensate
            long old_pos = orig_view_id._QROffset();
            orig_view_id.p_col++;
            long new_pos = orig_view_id._QROffset();
            orig_view_id.p_col--;
            if (new_pos > old_pos) {
               orig_view_id._delete_text(1);
            }
         }

         // insert the new character
         orig_view_id._insert_text(new_ch);

         // next column
         temp_view_id.p_col++;
      }

      // next line please
      if (orig_view_id.down() < 0 || down() < 0) {
         break;
      }
   }

   // close temp view, restore window, done
   _delete_temp_view(temp_view_id);
   p_window_id = orig_view_id;
   restore_pos(p);
   return 0;
}

/**
 *  
 * WARNING:  For better error handling, caller should already 
 * know that the clipboard is a text clipboard. Can use 
 * _clipboard_format(VSCF_TEXT,isClipboard) or 
 * _getClipboardMarkType() to determine this.
 *  
 * @return Returns text of clipboard. null if error occurred on 
 *         paste.
 */
_str _getClipboardText(bool onlyFetchOneLine,bool isClipboard=true,_str name='',bool utf8=true) {
   get_window_id(auto window_id);
   _create_temp_view(auto temp_wid);
   p_UTF8=utf8;
   int status=paste(name,isClipboard);
   _str result=null;
   if (!status) {
      if (onlyFetchOneLine) {
         bottom();
         get_line(result);
         if (result=='' && p_line>1) {
            up();
            get_line(result);
         }
      } else {
         top();result=get_text(p_buf_size);
      }
   }
   // doBlockModeKey will stack if length(keya)==0
   if (result!=null && length(result)==0) {
      result=null;
   }
   _delete_temp_view(temp_wid);
   p_window_id=window_id;
   return(result);
}
/**
 * Return what type ("CHAR", "LINE", "BLOCK", or "") the paste 
 * command will paste. 
 *  
 * @param isClipboard   Unix Only: True if testing clipboard 
 *                      used by keyboard (not mouse).
 * 
 * @return Returns "CHAR", "LINE", "BLOCK", or ""
 */
_str _getClipboardMarkType(bool isClipboard=true,_str name='') {
   /*
       Need this to support "Mouse selection creates clipboard" (def_autoclipboard) 
       and support pasting character selection into a column selection. Keep in 
       mind that this only works when both clipboards are internal.
   */
   if (_isWindows() && name=='' && def_autoclipboard && _isclipboard_internal(false,isClipboard) ) {
      orig_wid:=p_window_id;
      activate_window(_clipboards_view_id);
      _get_clipboard_header(auto cbtype,auto Noflines,auto junk1,auto junk2,auto utf8);
      activate_window(orig_wid);
      return cbtype;
   }
   return _clipboard_get_mark_type(isClipboard,name);
}
bool _isclipboard_internal(bool allowClipboardFromDifferentVS=false,bool isClipboard=true)
{
   _str cb_format=_clipboard_format(VSCF_VSTEXTINFO,isClipboard);
   typeless pid='';
   parse cb_format with 'pid='pid . ;
   if (allowClipboardFromDifferentVS) {
      return(cb_format && pid!='');
   }
   return(cb_format && getpid()==pid && _Nofclipboards);
}
static _str killed_last_line;    /* Special case for deleting last line of file. */

static int nosave_delete_line()
{
   if (!(_lineflags() & NOSAVE_LF)) {
      return _delete_line();
   }
   int orig_modify_flags=p_ModifyFlags;
   if (def_keys=='ispf-keys') {
      count := ispf_is_excluded_line();
      if (count > 0) {
         orig_line := p_line;
         for (;count>0;--count) {
            p_line++;
            if (_lineflags() & HIDDEN_LF) {
               _lineflags(0,HIDDEN_LF);
            } else {
               break;
            }
         }
         p_line=orig_line;
      }
   }
   status := _delete_line();
   p_ModifyFlags=orig_modify_flags;
   return status;
}


/**
 * Deletes the current line and copies it to the clipboard.  Invoking this command
 * from the keyboard multiple times in succession creates one clipboard.  You may
 * retrieve the deleted line(s) with the command <b>paste</b>.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no line at cursor)
 * and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see     delete_line
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_line(_str cbname='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _str cmdname=name_name(last_index('','C'));
   executed_from_key := name_name(last_index()):==translate(cmdname,'-','_');
   typeless mark='';
   SelectionModified := false;
   line := "";
   key := "";
   typeless status=0;
   typeless old_killed_last_line='';
   cursor_y := 0;
   count := 0;
   dcount := 0;
   view_id := 0;
   need_to_remove_eol:=false;
   typeless mark_pos=0;
   if ( command_state() ) {
      get_command(line);
      set_command('',1,1);
      prev_index(0,'C');last_index(0,'C');
   } else {
      if ( _on_line0() ) {
         return(1);
      }
      if ( _process_within_submission() ) {
         fall_thru:=false;
         col:=1;
         if ( _process_info('c') ) {
            col=_process_info('c');
            if (_process_is_interactive_idname(_ConcurProcessName())) {
               if (p_col<_process_info('c')  || p_line==p_Noflines) {
                  p_col=_process_info('c');
               }
            } else {
               p_col=_process_info('c');
            }
         } else {
            if (_process_info('E',_ConcurProcessName())) {
               up();
               if (_process_info('c') && p_col<_process_info('c')) {
                  p_col=_process_info('c');
               }
               down();
               fall_thru=true;
            }
            if (!fall_thru && !_process_info('E',_ConcurProcessName())) {
               p_col=1;
            }
         }
         if (!fall_thru) {
            status=push_clipboard_itype('CHAR',cbname,1,p_UTF8,p_lexer_name,_MultiCursorCount());
            if ( status ) { return(status); }
            status=append_clipboard_text(_expand_tabsc(col,-1,'S'),cbname);
            replace_line(_expand_tabsc(1,col-1,'S'));
            // IF send on enter
            if (_process_info('E',_ConcurProcessName()) && _process_info('c') && p_line!=p_Noflines) {
               _join_line();
            }
            return(status);
         }
      }
      if ( name_name(prev_index('','C'))!='cut-line' ) {
         killed_last_line=0;
      }
      old_killed_last_line=killed_last_line;

      // See if we can invoke unsurround in this case, have to preserve
      // last_index and prev_index.  Also have to verify that cut-line
      // was not being repeated.
      save_last_index := last_index('','C');
      save_prev_index := prev_index('','C');
      if (!_MultiCursorAlreadyLooping() &&
          name_name(last_index('', 'C'))=='cut-line' &&
          name_name(prev_index('', 'C'))!='cut-line' &&
          maybe_unsurround_block(true, cbname,caller_fallthru_deletes_line:true)) {
         return(0);
      }
      last_index(save_last_index,'C');
      prev_index(save_prev_index,'C');

      cursor_y=p_cursor_y;
      if ( down() ) { /* Bottom of file? */
         killed_last_line=1;
      } else {
         up();
         killed_last_line=0;
      }
      set_scroll_pos(p_left_edge,cursor_y);

      // We used to attempt to accumulate repeats and perform the
      // cut in one fell swoop, but that does not work any more
      // because: 1) test_event is no longer used; 2) machines are
      // so fast that you would have to call delay(,'k') in order
      // to accumulate anything in the input queue. We will leave
      // count=1 here in case we want to pass in a count at some
      // point.
      count=1;

      //say('count='count' o='old_killed_last_line);
      mark=_alloc_selection();
      save_pos(mark_pos);
      if (p_ShowExtraLine) {
         need_to_remove_eol= _last_line_not_terminated_with_eol();
      }
      _select_line(mark);
      if (old_killed_last_line) {
         up(count-1);
         if (_on_line0()) down();
      } else {
         down(count-1);
         if ( down() ) { /* Bottom of file? */
            killed_last_line=1;
         } else {
            up();
            killed_last_line=0;
         }
      }
      _select_line(mark);
      if (mark!='') {
         SelectionModified=_extend_outline_selection(mark);
      }
      dcount=count_lines_in_selection(mark,true);
      _begin_select(mark);
   }
   linenum := 0;
   mark_name := "";
   Noflines := 0;
   push := true;
   if (_MultiCursorAlreadyLooping() && !_MultiCursorFirstLoopIteration() &&
       push && !_append_next_clipboard && _Nofclipboards) {
      push=false;
      //append_clipboard_text("\n");
   }
   int multiCursorCount=_MultiCursorCount();
   if ( push && name_name(prev_index('','C'))!='cut-line' ) {
     status=push_clipboard_itype('LINE',cbname,0,_isEditorCtl()?p_UTF8:false,_isEditorCtl()?p_lexer_name:"",multiCursorCount);
     if ( status ) {
        if(mark!='') _free_selection(mark);
        return(status);
     }
   } else {
      if ( old_killed_last_line ) {
         get_window_id(view_id);
         activate_window(_clipboards_view_id);
         linenum=p_line;
         if (mark=='') {
            insert_line(line);
         } else {
            _copy_to_cursor(mark);
            _free_selection(mark);
         }
         p_line=linenum;
         _get_clipboard_header(mark_name,Noflines);
         Noflines+=count;
         _change_clipboard_Noflines(Noflines);
         status=_append_to_system_cb(mark_name,Noflines,false,multiCursorCount);
         activate_window(view_id);
         if (mark!='') {
            for(;;) {
               _delete_line();
               if (!(--count)) break;
               _undo('s');
            }
         }
         if (need_to_remove_eol) {
            _save_pos2(auto p);
            _end_line();
            _delete_text(-2);
            _restore_pos2(p);
         }
         return(0);
      }
   }
   if (mark=='') {
      status=append_clipboard_text(line,cbname);
   } else {
      // Here we are trading off speed to make sure deleting selective display
      // can be undone in one stop.
      if (SelectionModified) {
         status=append_cut2(mark);
         _free_selection(mark);
      } else {
         status=append_cut2(mark,true);
         _free_selection(mark);
         if (mark!='') {
            for(;;) {
               nosave_delete_line();
               if (!(--count)) break;
               _undo('s');
            }
         }
      }
   }
   if (need_to_remove_eol) {
      _save_pos2(auto p);
      _end_line();
      _delete_text(-2);
      _restore_pos2(p);
   }
   return(status);

}
/**
 * Deletes the current line.
 * <p>
 * This function is hooked into auto-unsurround.
 * If you simply want to programmatically delete a single line,
 * call {@link _delete_line}.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no line at cursor)
 * and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see     cut_line
 * @see     _delete_line
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      line := "";
      get_command(line);
      set_command('',1,1);
   } else {
      // See if we can invoke unsurround in this case.
      // Verify that delete-line was not being repeated.
      if (!_MultiCursorAlreadyLooping() &&
          name_name(last_index('', 'C'))=='delete-line' &&
          name_name(prev_index('', 'C'))!='delete-line' &&
          maybe_unsurround_block(caller_fallthru_deletes_line:true)) {
         return;
      }
      bool need_to_remove_eol=false;
      if (p_ShowExtraLine) {
         need_to_remove_eol=_last_line_not_terminated_with_eol();
      }
      _delete_line();
      if (need_to_remove_eol) {
         _save_pos2(auto p);
         _end_line();
         _delete_text(-2);
         _restore_pos2(p);
      }
   }
}
/**
 * Attempts to identify the block of code starting at
 * the current line, and prompts to delete the entire block of code.
 * The deleted line(s) are copied to the clipboard.
 * You may retrieve the deleted line(s) with the command <b>paste</b>.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no block at cursor)
 * and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see     cut_line
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void cut_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!maybe_unsurround_block(true,'',0,true,true)) {
      message("Can not cut code block starting at this line");
   }
}
/**
 * Attempts to identify the block of code starting at
 * the current line, and prompts to delete the entire block of code.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no block at cursor)
 * and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see     delete_line
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!maybe_unsurround_block(false,'',0,true,true)) {
      message("Can not delete code block starting at this line");
   }
}

static void block_mode_delete_end_line(_str markid="", bool doCut=false)
{
   save_pos(auto p);
   _begin_select(markid);
   start_line_no := p_line;
   _end_select(markid);
   end_line_no := p_line;
   restore_pos(p);
   cur_line_no := p_line;
   cur_col_no := p_col;
   start_col := end_col := buf_id := 0;
   _get_selinfo(start_col,end_col,buf_id,markid);

   if (doCut) {
      push_clipboard_itype("LINE","",0,p_UTF8,p_lexer_name,_MultiCursorCount());
   }

   for (line_no := start_line_no; line_no <= end_line_no; ++line_no) {
      p_line = line_no;
      p_col  = end_col;
      if (end_col>start_col) p_col++;
      if (!at_end_of_line()) {
         if (doCut) {
            cur_offset := _QROffset();
            _end_line();
            end_offset := _QROffset();
            _GoToROffset(cur_offset);
            p_line = line_no;
            append_clipboard_text(get_text((int)(end_offset-cur_offset)));
         }
         _delete_text(-1);
      } else if (doCut) {
         append_clipboard_text("");
      }
   }
   p_col=end_col;
   p_line=cur_line_no;
   p_col=cur_col_no;
}

void erase_end_line()
{
   if ( p_col>_text_colc(0,'E')) {
      _join_line();
   } else {
      _delete_text(-1);
   }
}


/**
 * Deletes text from cursor to end of line and copies it to the clipboard.
 * For an edit window or editor control, if the cursor is past the last
 * character of the line, the next line is joined with the current line.
 * Invoking this command from the keyboard multiple times in succession
 * creates one clipboard.  You may retrieve the deleted text with the
 * command <b>paste</b>.
 *
 * @return  Returns 0 if successful.  Common return codes are BOTTOM_OF_FILE_RC
 * and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see     delete_end_line
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_end_line(bool push=true) name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   typeless mark_pos=0;
   typeless mark='';
   line := "";
   rest := "";
   key := "";
   col := 0;
   int i,count=1;
   typeless status=0;
   if ( command_state() ) {
      get_command(line,col);
      rest=substr(line,col);
      if ( rest:=='' ) return(0);
      line=substr(line,1,col-1);
      set_command(line);
      prev_index(0,'C');last_index(0,'C');
      col=0;
   } else {
      if (_on_line0()) {
         return(0);
      }

      // We used to attempt to accumulate repeats and perform the
      // cut in one fell swoop, but that does not work any more
      // because: 1) test_event is no longer used; 2) machines are
      // so fast that you would have to call delay(,'k') in order
      // to accumulate anything in the input queue. We will leave
      // count=1 here in case we want to pass in a count at some
      // point.
      count=1;

      // DJB 09-04-2008
      // add support for cut-end-line and delete-end-line for block insert mode
      if (allowBlockModeKey()) {
         block_mode_delete_end_line("", true);
         return(0);
      }

      mark=_alloc_selection();
      if (mark<0) {
         status=TOO_MANY_SELECTIONS_RC;
         message(get_message(status));
         return(status);
      }
      save_pos(mark_pos);
      _select_char(mark);col=p_col;
      for (i=1;i<=count;++i) {
         if ( p_col>_text_colc(0,'E')) {
            if(down()){
               count=i-1;
               break;
            }
            _begin_line();
         } else {
            _TruncEndLine();
         }
      }
      _select_char(mark);
      restore_pos(mark_pos);
      if (count<1) {
         _free_selection(mark);
         message(get_message(BOTTOM_OF_FILE_RC));
         return(BOTTOM_OF_FILE_RC);
      }
   }
   if (!command_state() && 
       _MultiCursorAlreadyLooping() && !_MultiCursorFirstLoopIteration() &&
       push && !_append_next_clipboard && _Nofclipboards && _select_type(mark)=='CHAR') {
      push=false;
      append_clipboard_text("\n");
   }

   // we use the 'D' parameter for Eclipse, but this messes up macro playback
   prevIndexParam := isEclipsePlugin() ? 'D' : 'C';
   if ( push && name_name(prev_index('',prevIndexParam))!='cut-end-line') {
      status=push_clipboard_itype('CHAR','',col,_isEditorCtl()?p_UTF8:_UTF8(),_isEditorCtl()?p_lexer_name:"",_MultiCursorCount());
      if ( status ) return(status);
   }

   if (mark=='') {
      return(append_clipboard_text(rest));
   }
   status=append_cut2(mark,true);
   _free_selection(mark);
   for(;;) {
      erase_end_line();
      if (!(--count)) break;
      _undo('s');
   }
   return(status);

}


/**
 * Deletes text from cursor to end of line.
 *
 * @see     cut_end_line
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_end_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // DJB 09-04-2008
   // add support for cut-end-line and delete-end-line for block insert mode
   if (allowBlockModeKey()) {
      block_mode_delete_end_line("", false);
   } else {
      _delete_text(-1);
   }

   retrieve_command_results();
}

/**
 * Helper function that deletes text from cursor to end of line. 
 *  
 */
void _delete_end_line()
{
   _delete_text(-1);
}

/**
 * Sets the maximum number of clipboards saved.  Clipboard text may be
 * retrieved by the command <b>paste</b> (Ctrl+V) or <b>list_clipboards</b>
 * (Ctrl+Shift+V).
 *
 * @categories Clipboard_Functions
 */
_command void clipboards(_str maxClipboards='')
{
   typeless arg1=prompt(maxClipboards,'',def_clipboards);
   if ( ! isinteger(arg1) || arg1<=0 ) {
      message(nls('Please specify number greater than 0'));
      return;
   }
   def_clipboards=arg1;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
/**
 * Deletes from the cursor to the end of the word at the cursor or the
 * next word and copies it to the clipboard.  Invoking this command from
 * the keyboard multiple times in succession creates one
 * clipboard. The deleted text may be retrieved by the command
 * <b>paste</b>.
 *
 * @return  Returns 0 if successful.  Common return codes are  TOO_MANY_SELECTIONS_RC, and STRING_NOT_FOUND_RC.  On error, message is displayed.
 *
 * @see     delete_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   push := name_name(prev_index('','c'))!='cut-word';

   typeless status=cut_word2(push);
   retrieve_command_results();
   return(status);
}

/**
 * Same as cut_word, except ignores the def_subword_nav setting and deletes 
 * from the cursor to the end of the full word at the cursor or the next 
 * word, and copies it to the clipboard.
 *
 * @return  Returns 0 if successful.
 *
 * @see cut_word
 * @see cut_subword
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int old_command_state=command_state();
   init_command_op();
   push := name_name(prev_index('','c'))!='cut-full-word';
   typeless status=cut_word2(push,false,-1);
   retrieve_command_results();
   return(status);
}
/**
 * Same as cut_word, except ignores the def_subword_nav setting and deletes 
 * from the cursor to the end of the subword at the cursor or the next 
 * word, and copies it to the clipboard.
 *
 * @return  Returns 0 if successful.
 *
 * @see cut_word
 * @see cut_full_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   _str push=name_name(prev_index('','c'))!='cut-subword';
   typeless status=cut_word2(push!=0,false,1);
   retrieve_command_results();
   return(status);
}

/**
 * Delete current word at cursor and copies it to the clipboard.
 * @return  Returns 0 if successful.  Common return codes are  TOO_MANY_SELECTIONS_RC, and STRING_NOT_FOUND_RC.  On error, message is displayed.
 *
 * @see     delete_word
 * @see     cut_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_whole_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   status := 0;
   int i = _text_colc(p_col,'p');
   LineLen := _line_length();
   if (i > LineLen && LineLen) {
      i = LineLen;
   }
   p_col = _text_colc(i,'I');
   status = search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-rh@');
   if (!status) {
      status = cut_word();
   }
   retrieve_command_results();
   return(status);
}

/**
 * Deletes from the cursor to the end of the current word.
 *
 * @see  cut_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command delete_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   typeless mark=_alloc_selection();
   typeless status=0;
   if ( mark<0) {
      message(get_message(mark));
      status=mark;
   } else {
      if (def_subword_nav) {
         status=pselect_subword(mark);
      } else {
         status=pselect_word(mark);
      }
      if ( ! status ) {
         _begin_select(mark);
         _delete_selection(mark);
      }
      _free_selection(mark);
   }
   retrieve_command_results();
   return(status);
}

/**
 * Same as delete_word, except ignores the def_subword_nav setting and 
 * deletes from the cursor to the end of the current full word.
 *
 * @see delete_word
 * @see delete_subword
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command delete_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   typeless mark=_alloc_selection();
   typeless status=0;
   if ( mark<0) {
      message(get_message(mark));
      status=mark;
   } else {
      status=pselect_word(mark);
      if ( ! status ) {
         _begin_select(mark);
         _delete_selection(mark);
      }
      _free_selection(mark);
   }
   retrieve_command_results();
   return(status);
}

/**
 * Same as delete_word, except ignores the def_subword_nav setting and 
 * deletes from the cursor to the end of the current subword.
 *
 * @see delete_word
 * @see delete_full_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command delete_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   typeless mark=_alloc_selection();
   typeless status=0;
   if ( mark<0) {
      message(get_message(mark));
      status=mark;
   } else {
      status=pselect_subword(mark);
      if ( ! status ) {
         _begin_select(mark);
         _delete_selection(mark);
      }
      _free_selection(mark);
   }
   retrieve_command_results();
   return(status);
}

/**
 * Delete current word at cursor.
 * @return  Returns 0 if successful.  Common return codes are  TOO_MANY_SELECTIONS_RC, and STRING_NOT_FOUND_RC.  On error, message is displayed.
 *
 * @see     delete_word
 * @see     cut_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command delete_whole_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   status := 0;
   int i = _text_colc(p_col,'p');
   LineLen := _line_length();
   if (i > LineLen && LineLen) {
      i = LineLen;
   }
   p_col = _text_colc(i, 'I');
   status = search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-rh@');
   if (!status) {
      status = delete_word();
   }
   retrieve_command_results();
   return (status);
}

/**
 * If <i>create_clipboard</i> is <b>true</b>, then a new clipboard is created
 * containing the text from the cursor to the end of the current word.
 * <p>
 * If <i>create_clipboard</i> is false, then the text from the cursor to
 * the end of the current word is appended to the current clipboard.
 * <p>
 * Regardless of the value of the <i>create_clipboard</i> parameter, if
 * the second argument is not 'C', the text that is copied is deleted from
 * the buffer.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @param push
 * @param doCopy
 * @param subwordOption 
 * @param skipTrailing 
 *
 * @return Returns 0 if successful.  Common return codes are 1 (no line at cursor),
 *
 *
 * TOO_MANY_SELECTIONS_RC, and STRING_NOT_FOUND_RC.
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int cut_word2(bool push, bool doCopy=false, int subwordOption=0, bool skipTrailing=true)
{
   if (_MultiCursorAlreadyLooping() && !_MultiCursorFirstLoopIteration() &&
       push && !_append_next_clipboard && _Nofclipboards) {
      push=false;
      append_clipboard_text("\n");
   }
   typeless mark=_alloc_selection();
   typeless status=0;
   if ( mark<0 ) {
      message(get_message(mark));
      status=mark;
   } else {
      if (subwordOption == 1) {
         status=pselect_subword(mark,skipTrailing);
      } else if (subwordOption == -1) {
         status=pselect_word(mark);
      } else if (def_subword_nav) {
         status=pselect_subword(mark,skipTrailing);
      } else {
         status=pselect_word(mark);
      }
      if ( ! status ) {
         typeless old_mark=_duplicate_selection('');
         _show_selection(mark);
         if ( !doCopy) {
            _begin_select(mark);
         } else {
            _end_select();
         }
         lindex := last_index('','C');
         status=cut2(push,doCopy);
         last_index(lindex,'C');
         _show_selection(old_mark);
      }
      _free_selection(mark);
   }
   return(status);

}
static const MARK_DATA_WIDTH=  12;

static _str _lcb_call_back(int reason,var result,_str key);

int _OnUpdate_old_list_clipboards(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || (!target_wid._isEditorCtl() && target_wid.p_object!=OI_TEXT_BOX)) {
      return(MF_GRAYED);
   }
   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      return(MF_GRAYED);
   }
   if (target_wid.p_object == OI_TEXT_BOX && target_wid._QReadOnly()) {
      return(MF_GRAYED);
   }
   // IF we don't have any internal clipboards
   if ( ! _Nofclipboards ) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows list-clipboards to report that
      // there are no clipboards.
      return(MF_GRAYED|MF_ENABLED);
   }
   return(MF_ENABLED);
}
static _str get_part_of_line(bool utf8)
{
   first_line := "";
   if (_line_length()>MAX_CONDENSED_CLIPBOARD_LINE_LEN) {
      first_line=get_text(MAX_CONDENSED_CLIPBOARD_LINE_LEN);
      //if (!_dbcsStartOfDBCS(first_line,length(first_line))) {
      //   first_line=substr(first_line,1,length(first_line)-1);
      //}
   } else {
      get_line(first_line);
   }
   if (!utf8) {
      first_line=_MultiByteToUTF8(first_line);
   }
   return(first_line);
}

/**
 * Sets named clipboard to active clipboard item 
 */
_str _set_current_clipboard(_str name)
{
   view_id := 0;
   _str status;
   get_window_id(view_id);
   activate_window(_clipboards_view_id);
   status = goto_named_clipboard(name);
   if (status) {
      activate_window(view_id);
      return (status);
   }
   mark_name := "";
   Noflines := 0;
   typeless junk1,junk2,utf8;
   int multiCursorCount;
   _get_clipboard_header(mark_name,Noflines,junk1,junk2,utf8,auto junk3,multiCursorCount);
   typeless mark = _alloc_selection();
   if (mark < 0 ) {
      activate_window(view_id);
      return (status);
   }
   _select_line(mark); down(Noflines); _select_line(mark);
   // IF this clipboard is NOT already at the bottom of the
   //    clipboard buffer.
   if (p_line != p_Noflines) {
      bottom();
      _move_to_cursor(mark);
      _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);
   }
   save_pos(auto p);
   _begin_select(mark);
   _deselect(mark);down();_begin_line();select_it(mark_name,mark);
   down(Noflines-1);_end_line();
   if ( mark_name:!='CHAR' ) left();
   select_it(mark_name,mark);
   _lastcbisauto=false;
   orig_utf8 := p_UTF8;p_UTF8=utf8;  // Change
   _copy_to_clipboard(mark,true,false,multiCursorCount);restore_pos(p);
   top();
   p_UTF8=orig_utf8;   // Change
   _free_selection(mark);
   activate_window(view_id);
   return (status);
}

void _get_clipboard_list(int temp_view_id)
{
   put_in_box(temp_view_id);
}

/**
 * Displays <b>List Clipboards dialog box</b>.  Allows you to select a
 * clipboard from a list of your most recently used (15 is the default maximum)
 * clipboards to insert at the cursor.  Subsequent calls to the <b>paste</b>
 * command will insert the same text as your last <b>list_clipboards</b>.  LINE
 * type clipboards are inserted before or after the current line depending upon
 * the <b>Line insert style</b>.  By default, they are inserted after the current line.
 *
 * @return Returns 0 if successful.  Common return codes are 1 (clipboard
 * empty, nothing selected, or clipboard text too long), TOO_MANY_SELECTIONS_RC,
 * TOO_MANY_WINDOWS_RC, and TOO_MANY_FILES_RC.  On error message is displayed.
 *
 * @see paste
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions
 *
 */
_command old_list_clipboards,list_clipboards_modal() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   cmdline_active := (_cmdline==p_window_id);
   in_text_box := p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX;
   _macro_delete_line();
   _clipboard_validate_all();
   if ( ! _Nofclipboards ) {
      message(nls('No clipboards'));
      return(1);
   }
   typeless result='';
   orig_view_id := 0;
   temp_view_id := 0;
   orig_wid := 0;
   wid := 0;
   orig_auto_select := false;
   if (arg(1)!='') {
      result=arg(1);
   } else {
      int start_pos,end_pos;
      if (in_text_box) {
         _get_sel(start_pos,end_pos);
      }
      orig_view_id=_create_temp_view(temp_view_id);
      if (orig_view_id=='') return('');

      put_in_box(temp_view_id);

      activate_window(orig_view_id);
      if (in_text_box) {
         orig_auto_select=p_auto_select;
         p_auto_select=false;
      }
      buttons := "OK, &View";
      orig_wid=p_window_id;
      wid=show('_sellist_form -new -reinit',
            nls('Select Text to Paste'),
            SL_VIEWID|SL_SELECTCLINE,
            temp_view_id,       //
            buttons,            // Buttons
            "list clipboards dialog box",  // Help item
            '',  // Font
            _lcb_call_back   // Call back function
            );
      if (cmdline_active) {
         _cmdline.p_visible=true;
      }
      result=_modal_wait(wid);
      // We will assume that the form is edited if '' is returned.
      // We want the edited form to be the active window so
      // we will not change the active window.
      if (result!='' && _iswindow_valid(orig_wid)) {
         p_window_id=orig_wid;
      }

      activate_window(orig_view_id);
      // Don't want to change focus if editing _sellist_form
      wid=_get_focus();
      if (wid && wid.p_name!='_sellist_form' && !wid.p_edit) {
         _set_focus();
      }
      if (in_text_box) {
         p_auto_select=orig_auto_select;
         _set_sel(start_pos,end_pos);
      }
      if ( result=='' ) {
         return(1);
      }
   }
   if (p_HasBuffer && _QReadOnly()) {
       popup_message(nls('Paste not allowed in %s mode.',p_mode_name));
       return(1);
   }

   _str name;
   parse result with name . ;
   get_window_id(orig_wid);
   typeless status = _set_current_clipboard(name);
   if (!status) {
      _PasteWithBlockModeSupport();
      _macro('m',_macro('s'));
      _macro_call('list_clipboards_modal',name);
      activate_window(orig_wid);
   }

   return(status);
}


void _font_string2props(_str font)
{
   old_redraw := p_redraw;
   p_redraw=false;
   font_name := "";
   typeless size='';
   typeless font_flags='';
   typeless charset='';
   parse font with font_name ',' size ',' font_flags ',' charset;

   if (font_name!='') {
      p_font_name=font_name;
   }
   if (size!='') {
      p_font_size=size;
   }
   if (isinteger(font_flags)) {
      _font_flags2props(font_flags);
   }
   if (isinteger(charset)) {
      p_font_charset=charset;
   }
   p_redraw=old_redraw;
}


/**
 * This function sets the font properties of the current object based on
 * the font flags.  <i>font_flags</i> is a combination of the following flag
 * constants defined in "slick.sh":
 * <UL>
 *       <DT>F_BOLD
 *       <DT>F_ITALIC
 *       <DT>F_STRIKE_THRU
 *       <DT>F_UNDERLINE
 *       <DT>F_PRINTER
 * </UL>
 * @see  _font_props2flags
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Hscroll_Bar_Methods, Label_Methods, List_Box_Methods, Radio_Button_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 */
void _font_flags2props(int font_flags)
{
   old_redraw := p_redraw;
   p_redraw=false;
   p_font_bold = (font_flags & F_BOLD)!=0;
   p_font_italic = (font_flags & F_ITALIC)!=0;
   p_font_underline = (font_flags & F_UNDERLINE)!=0;
   p_font_strike_thru = (font_flags & F_STRIKE_THRU)!=0;
   p_font_printer = (font_flags & F_PRINTER)!=0;
   p_redraw=old_redraw;
}

/**
 * @return  This returns font flags based on the current objects font
 * properties.  The font flags returned<i> are a combination of the following
 * flag constants defined in "slick.sh":
 *
 * <DL compact style="margin-left:20pt;">
 *       <DD>F_BOLD
 *       <DD>F_ITALIC
 *       <DD>F_STRIKE_THRU
 *       <DD>F_UNDERLINE
 *       <DD>F_PRINTER
 * </DL>
 *
 * @see  _font_flags2props
 *
 * @appliesTo  All_Window_Objects, Form, Image, Picture_Box, Gauge, Spin
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Frame_Methods, Hscroll_Bar_Methods, Label_Methods, List_Box_Methods, Radio_Button_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 */
_font_props2flags()
{
   flags := 0;

   flags |=(p_font_bold)?F_BOLD:0;
   flags |=(p_font_italic)?F_ITALIC:0;
   flags |=(p_font_underline)?F_UNDERLINE:0;
   flags |=(p_font_strike_thru)?F_STRIKE_THRU:0;
   flags |=(p_font_printer)?F_PRINTER:0;
   return(flags);
}
void _use_source_window_font(int cfg=CFG_SBCS_DBCS_SOURCE_WINDOW)
{
   font_name := "";
   typeless font_size='';
   typeless font_flags='';
   typeless charset='';
   parse _default_font(cfg) with font_name ',' font_size ',' font_flags ',' charset ',';
   p_redraw=false;
   p_font_name = font_name;
   p_font_size = font_size;
   if (charset=='') {
      charset=VSCHARSET_DEFAULT;
   }
   p_font_charset=charset;
   _font_flags2props(font_flags);
   p_redraw=true;
}
/**
 * Sets the font properties to be the default font used by MDI edit
 * windows.
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _use_edit_font()
{
   font_name := "";
   typeless font_size='';
   typeless font_flags='';
   typeless charset='';
   parse _default_font(CFG_SBCS_DBCS_SOURCE_WINDOW) with font_name ',' font_size ',' font_flags ',' charset ',';
   p_redraw=false;
   p_font_name = font_name;
   p_font_size = font_size;
   if (charset=='') {
      charset=VSCHARSET_DEFAULT;
   }
   p_font_charset=charset;
   _font_flags2props(font_flags);
   p_redraw=true;
}

_control list1;

static _str _lcb_call_back(int reason,var result,_str key)
{
   _nocheck _control _sellist;

   form_wid := p_active_form;

   user_button := reason == SL_ONUSERBUTTON;
   if (!user_button) {
      return('');
   }
   typeless mark='';
   line := "";
   view_id := 0;
   typeless kill_pos=0;
   mark_name := "";
   no_of_lines := 0;
   name := "";
   col := 0;
   typeless utf8=0;
   typeless wid=0;
   lexername := "";

   switch (key) {
   case 4://In this case, case key == 4 means the user pressed the copy button
      mark = _alloc_selection();
      if( mark<0){
         _message_box('Not enough memory to allocate selection');
         return('');
      }
      _cb_modified=false;
      line=_sellist._lbget_text();
      parse line with line .;
      get_window_id(view_id);
      activate_window(_clipboards_view_id);

      save_pos(kill_pos);
      goto_named_clipboard(line);

      _get_clipboard_header(mark_name,no_of_lines,name,col,utf8,lexername);
      orig_utf8 := p_UTF8;p_UTF8=utf8;  // Change
      down();                     //Move Down Past Header
      _select_line(mark);down(no_of_lines - 1);_select_line(mark);
      restore_pos(kill_pos);
      activate_window(view_id);
      wid = show('_cbview_form -Hidden -New');
      wid.list1.p_UTF8=utf8;
      wid.list1._use_source_window_font(utf8?CFG_UNICODE_SOURCE_WINDOW:CFG_SBCS_DBCS_SOURCE_WINDOW);
      //wid.list1.read_only_mode();//Makes the editor on the dialog box read only
      p_window_id = wid.list1;
      _copy_to_cursor(mark);
      p_lexer_name = lexername;
      p_color_flags = (lexername == '') ? 0 : LANGUAGE_COLOR_FLAG;
      _free_selection(mark);
      _delete_line();
      wid.p_visible = true;

      get_window_id(view_id);
      activate_window(_clipboards_view_id);
      p_UTF8=orig_utf8;   // Change
      result=_modal_wait(wid);
      if (_cb_modified) {     //If clipboards were modified
         form_wid._sellist._lbclear();

         p_window_id.put_in_box(form_wid._sellist);

         form_wid._sellist.p_line = 1;

         form_wid._sellist._lbselect_line();
      }
      // This IF is needed to check if form was edited
      if (_iswindow_valid(form_wid) && form_wid._find_control('_sellist')) {
         p_window_id = form_wid._sellist;
      }
      return('');
   }
   return('');
}


_control list1;



defeventtab _cbview_form;

_control _help;
_control _copy;
_control list1;

_copy.lbutton_up()
{
   if (list1.select_active()) {
      list1.copy_to_clipboard();
   } else {
      int selection = _alloc_selection();
      list1.top();
      list1._select_line(selection);
      list1.bottom();
      list1._select_line(selection);
      int old_selection = _duplicate_selection('');
      _show_selection(selection);
      list1.copy_to_clipboard();
      _show_selection(old_selection);
      _free_selection(selection);
   }
   p_active_form._delete_window();
}


   //_nocheck _control _sellist;

static void put_in_box(int temp_view_id)
{
   _str show_cb_name=def_show_cb_name;
   activate_window(_clipboards_view_id);
   width := 80;
   id_width := 0;
   if( show_cb_name ) {
      id_width=max(max_clipboard_name_length(),length(_Nofclipboards));
   } else {
      id_width=length(_Nofclipboards);
   }
   int max_data_size=width-id_width-1-(MARK_DATA_WIDTH);
   int half=(max_data_size-3) intdiv 2;
   top();
   typeless type='';
   typeless utf8=0;
   name := "";
   first_line := "";
   last_line := "";
   yank_data := "";
   startlen := 0;
   endhalf := 0;
   col := 0;
   p := 0;
   id := "";
   i := count := 0;
   for (i=_Nofclipboards; i>=1 ; --i) {
      _get_clipboard_header(type,count,name,col,utf8);
      down();
      first_line=get_part_of_line(utf8);
      down(count-1);
      last_line=get_part_of_line(utf8);
      if ( count==1 ) {
         if ( length(first_line)<=max_data_size ) {
            yank_data=first_line;
         } else {
            // We don't want to bisect a UTF-8 sequence
            startlen=_strBeginChar(first_line,half)-1;
            endhalf=_strBeginChar(last_line,length(first_line)-half+1);
            yank_data=substr(first_line,1,startlen)'...'substr(first_line,endhalf);
         }
      } else {
         if ( half>length(first_line) ) {
            yank_data=first_line;
         } else {
            // We don't want to bisect a UTF-8 sequence
            startlen=_strBeginChar(first_line,half)-1;
            yank_data=substr(first_line,1,startlen);
         }
         yank_data :+= '...';
         p=length(last_line)-(max_data_size-length(yank_data))+1;
         if ( p<=0 ) p=1;
         // We don't want to bisect a UTF-8 sequence
         endhalf=_strBeginChar(last_line,p);
         yank_data :+= substr(last_line,endhalf);
      }
      yank_data = expand_tabs(yank_data);
      activate_window(temp_view_id);
      up();
      if( show_cb_name ) {
         id=strip(name);
      } else {
         id=i;
      }
      insert_line(field(' 'id,id_width+3):+field(type " "count,MARK_DATA_WIDTH):+
                  yank_data);
      activate_window(_clipboards_view_id);
      if ( down() ) {
         up(count);  /*  put cursor back on last kill */
         break;
      }
   }
   activate_window(temp_view_id);

   typeless mark='';
   typeless old_mark='';
   l := 0;
   Noflines := 0;
   line := "";
   if ( show_cb_name ) {
      /* HERE - give numbers to the clipboards with NULL names and sort the clipboards in ascending order */
      Noflines=p_noflines;
      top();
      count=0;  /* Count of unnamed clipboards */
      for (i=1; i<=Noflines ; ++i) {
         get_line(line);
         parse line with name .;
         name=strip(name);
         if ( name==NULL_CB_NAME ) {
            count++;
            replace_line(' 'substr(count,1,max_clipboard_name_length()):+substr(line,id_width+1+1));
            down();
         } else {
            l=p_line;
            bottom();insert_line(line);
            p_line=l;
            _delete_line();
         }
      }
      
      if (Noflines > _Nofnulls)  {
         /* Sort the named clipboards */
         mark=_alloc_selection();
         if ( mark<0 ) {
            message(get_message(mark));
            return;
         }
         old_mark=_duplicate_selection('');
         top(); down(count);
         _select_block(mark);right();down(Noflines-_Nofnulls-1);_select_block(mark);
         _show_selection(mark);
         sort_on_selection('AE');
         _show_selection(old_mark);
         _free_selection(mark);
      }
   }
}
/*
   Returns true if current buffer has embedded 13 or 10 character
   that is not at the end of a line.  Cursor position is changed.
   If there is not an embedded 13 or 10 character,cursor is plated at top of
   buffer.
*/
int _embedded_crlf()
{
   save_pos(auto p);
   top();
   // This takes advantage of exactly how $ works for an editor buffer. This makes
   // no sense for use with the pos() function.
   int status=search('((#<!($|$\13))\10)|((#<!$)\13)','@r');
   restore_pos(p);
   if (status) {
      return 0;
   }
   return 1;
}

int def_max_cbsave= 100;   /* 100k worth of clipboards. */

_str _srg_clipboards(_str option='',_str info='')
{
   window_file_id := 0;
   get_window_id(window_file_id);/* should be $window.slk */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   typeless Noflines=0;
   typeless possible_extra_variable='';
   typeless line_number=0;
   typeless result=0;
   view_id := 0;
   if (option!='R' && option!='N' && (def_restore_flags & RF_CLIPBOARDS)) {
      _clipboard_validate_all();
   }
   if ( (option=='R' || option=='N') ) {
      /* HERE - added a parse for '_Nofnulls' (for named clipboards) from the auto-restore file */
      parse info with Noflines _Nofclipboards possible_extra_variable line_number;
      if( line_number=="" ) {
         // This must be an old style auto-restore file that does NOT have the '_Nofnulls' variable saved
         line_number=possible_extra_variable;
         _Nofnulls=_Nofclipboards;  // If we don't set this we'll really get messed up!
      } else {
         _Nofnulls=possible_extra_variable;
      }
      /* **** */
      down();_select_line(mark);
      down(Noflines-1);
      _select_line(mark);
      activate_window(_clipboards_view_id);
      _lbclear();
      _copy_to_cursor(mark);
      p_line=line_number;
   } else if ( (def_restore_flags & RF_CLIPBOARDS) && _Nofclipboards) {
      get_window_id(view_id);
      activate_window(_clipboards_view_id);
      Noflines=p_Noflines;
      // Check for embedded carriage return or line feed
      // Can't save clipboards if there is an embedded cr or lf
      if (!_embedded_crlf() && Noflines) {
         line_number=p_line;
         bottom();_end_line();
         result=IDYES;
         if (_nrseek()>def_max_cbsave*1000) {
            if (yesnosave_clipboards=="") {
               activate_window(view_id);_set_focus();
               yesnosave_clipboards=_message_box(nls("You have more than %sk of clipboards.\n\nSave and Restore Clipboards?",def_max_cbsave),'',MB_YESNO|MB_ICONQUESTION,IDNO);
            }
            result=yesnosave_clipboards;
         }
         if (result==IDYES) {
            activate_window(_clipboards_view_id);
            top();
            _select_line(mark);
            bottom();_select_line(mark);
            activate_window(window_file_id);
            /* HERE - added extra variable '_Nofnulls' (for named clipboards) to be inserted into auto-restore file */
            insert_line('CLIPBOARDS: 'Noflines " "_Nofclipboards " "_Nofnulls " "line_number);
            _copy_to_cursor(mark);
#if 0
            int totalNoflines=(int)Noflines;
            down();
            while (_begin_select_compare(mark)<0) {
               _str line,mark_name;
               typeless cbNoflines;
               get_line(line);
               parse line with ':' mark_name cbNoflines .;
               down(cbNoflines);
               // Now we are sitting on last line of clipboard
               _lineflags(0,VSLF_EOL_MISSING);
               int count=cbNoflines;
               while (--count>0) {
                  up();
                  if (_lineflags()&VSLF_EOL_MISSING) {
                     --cbNoflines;
                     --totalNoflines;
                     _join_line();
                  }
               }
               // Now we are sitting on the first line of the clipboard
               _lineflags(0,VSLF_EOL_MISSING);
               down(cbNoflines-1);
            }
            if (totalNoflines!=Noflines) {
               up(totalNoflines);
               replace_line('CLIPBOARDS: 'totalNoflines " "_Nofclipboards " "_Nofnulls " "line_number);
            }
#endif
            _end_select(mark);
         }
         activate_window(_clipboards_view_id);
         p_line=line_number;
      }
   }
   _free_selection(mark);
   activate_window(window_file_id);
   return(0);

}
/**
 * Appends the selected text to the clipboard.
 *
 * @param name   name of clipboard(if any)
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @see append_next_cut
 * @see append_cut
 * @see cut
 * @see paste
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 */
_command void append_to_clipboard(_str name='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_READ_ONLY)
{
   _append_next_clipboard=true;
   copy_to_clipboard(name);
   _append_next_clipboard=false;

}
/**
 * Appends selected text to clipboard and deletes selected text.
 *
 * Ctrl+Shift+X or "Edit", "Append Cut"
 *
 * @param name   rg(1) = name of clipboard(if any)
 *
 * @see append_next_cut
 * @see append_to_clipboard
 * @see cut
 * @see paste
 * @see copy_word
 * @see cut_word
 * @see cut_line
 * @see cut_end_line
 * @see cut_prev_word
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions, Text_Box_Methods
 */
_command void append_cut(_str name='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX)
{
   _append_next_clipboard=true;
   cut(true,false,name);
   _append_next_clipboard=false;

}
/**
 * Allows you to append the next clipboard command to the clipboard.
 * Used by EMACS emulation.
 *
 * @see append_cut
 * @see append_to_clipboard
 * @see cut
 * @see paste
 * @categories Clipboard_Functions, Selection_Functions
 */
_command void append_next_cut() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _append_next_clipboard=true;
   _str k=get_event();
   call_key(k);
   _append_next_clipboard=false;
}

int goto_named_clipboard(typeless name)
{
   top();
   if ( isinteger(name) && name>0 ) {
      if ( name>=1 && name<=_Nofnulls ) {
         goto_clipboard(_Nofnulls-name+1,true);
         return(0);
      }
      /* Cannot goto a numbered clipboard that is outside the */
      /* range of existing clipboards */
      return(1);
   }
   line := "";
   typeless cbtype='';
   Noflines := 0;
   n := "";
   int i;
   for (i=1; i<=_Nofclipboards ; ++i) {
     get_line(line);
     _get_clipboard_header(cbtype,Noflines,n);
     if ( strip(name):==strip(n) ) {
        break;
     }
     down(Noflines+1);
   }
   /*messageNwait('got here');*/
   if ( i>_Nofclipboards ) {
      return(1);
   } else {
      return(0);
   }
}

void free_clipboard(_str name='')
{
   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_clipboards_view_id);
   _str status = goto_named_clipboard(name);
   if (!status) {
      delete_kill();
   }
   goto_clipboard(_Nofclipboards);
   activate_window(orig_wid);
}

/**
 * Deletes from the cursor to the beginning of the previous word.
 *
 * @appliesTo     Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @see cut_prev_word
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_prev_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   cut_prev_word(true);
}

/**
 * Same as delete_prev_word, except ignores the def_subword_nav setting 
 * and deletes from the cursor to the beginning of the previous full 
 * word.
 *
 * @appliesTo     Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @see delete_prev_word 
 * @see delete_prev_subword
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_prev_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   cut_prev_word(true,-1);
}

/**
 * Same as delete_prev_word, except ignores the def_subword_nav setting 
 * and deletes from the cursor to the beginning of the previous subword.
 *
 * @appliesTo     Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @see delete_prev_word 
 * @see delete_prev_full_word
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_prev_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   cut_prev_word(true,1);
}

/**
 * Deletes from the cursor to the beginning of the previous word and copies it
 * to the clipboard.  Invoking this command from the keyboard multiple times
 * in succession creates one clipboard.  The
 * deleted text may be retrieved by the command <b>paste</b>.
 *
 * @see delete_prev_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cut_prev_word(bool doDelete=false, int subwordOption=0) name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int old_state=command_state();
   lindex := last_index('','C');
   typeless status=0;
   init_command_op();
   push := name_name(prev_index('','C'))!='cut-prev-word';
   int mark=_alloc_selection();
   if ( mark<0 ) {
      message(get_message(mark));
      status=mark;
   } else {
      if ( _on_line0() ) {
         retrieve_command_results();
         _free_selection(mark);
         return(0);
      }
      _select_char(mark);
      if (def_brief_word && subwordOption==0) {
         if ( p_col==1 ) {
            up();_end_line();
         } else {
           left();
         }
         //search '[~ \t]#([ \t]@)','re-<'
         search('([\od'p_word_chars']#|[~\od 'p_word_chars']#)([ \t]@)','@re-<');
         if ( rc ) {
            top();
         }
      } else {
         if (subwordOption == -1) {
            prev_full_word();
         } else if (subwordOption == 1) {
            prev_subword();
         } else {
            prev_word();
         }
      }
      if ( old_state && p_line!=p_Noflines ) {
         bottom();_begin_line();
      }
      _select_char(mark);
      if (doDelete) {
         _delete_selection(mark);
      } else {
         backward_cut(push,mark);
      }
      _free_selection(mark);
   }
   retrieve_command_results();
   last_index(lindex,'C');
   return(status);

}
/**
 * Appends selection specified by markid in front of the current clipboard.  If push is
 * true a new clipboard is created containing the selection specified.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @param push
 * @param mark
 * @categories Selection_Functions
 */
void backward_cut(bool push,_str mark='')
{
   typeless old_mark='';
   typeless status=0;
   if ( push ) {
      old_mark=_duplicate_selection('');
      _show_selection(mark);
      _begin_select(mark);
      status=cut(push,false);
      _show_selection(old_mark);
   } else {
      int multiCursorCount=_MultiCursorCount();
      view_id := 0;
      get_window_id(view_id);
      _begin_select(mark);
      activate_window(_clipboards_view_id);
      old_Noflines := p_Noflines;
      down();_begin_line();
      /* Check if the data copied is from a binary file. */
      status=_move_to_cursor(mark);
      new_Noflines := p_Noflines;
      up();
      mark_name := "";
      Noflines := 0;
      _get_clipboard_header(mark_name,Noflines);
      linenum := p_line;
      int lines_in_mark=new_Noflines-old_Noflines+1;
      p_line=linenum;
      Noflines=(Noflines+lines_in_mark-1);
      start_col := 0;
      end_col := 0;
      typeless junk;
      _get_selinfo(start_col,end_col,junk,mark);

      _change_clipboard_Noflines(Noflines,start_col);

      status=_append_to_system_cb(mark_name,Noflines,false,multiCursorCount);
      activate_window(view_id);
   }
}

/**
 * @return Returns <b>true</b> if there is no selection or the selection is
 * zero bytes in length.  Otherwise, <b>false</b> is returned.
 *
 * @see _select_type
 * @see select_active
 *
 * @categories Selection_Functions
 *
 */
bool _isnull_selection(_str markid='')
{
   if (!select_active(markid)) {
      return(true);
   }
   first_col := 0;
   last_col := 0;
   buf_id := 0;
   _get_selinfo(first_col,last_col,buf_id,markid);
   if ((_select_type(markid)=='CHAR' || _select_type(markid)=='BLOCK') && !_select_type(markid,'i') && first_col==last_col &&
      _begin_select_compare(markid)==0 && _end_select_compare(markid)==0) {
      return(true);
   }
   return(false);
}

/**
 * If the def_autoclipboard variable is true and the current buffer has a
 * selection, it is copied to the clipboard.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _autoclipboard()
{
   if (!select_active2()) {
      return;
   }
   if (def_autoclipboard) {
#if 0
      // This code can be slow.

      //If there is a external clipboard
      if (!_isclipboard_internal()) {
         // Make a copy of it internal
         _cvtsysclipboard();
      }
#endif
      int orig_markid;
      save_selection(orig_markid);
      _copy_to_clipboard('',!_isUnix());
      restore_selection(orig_markid);
      _lastcbisauto=true;
   }
}
int _cvtsysclipboard(_str name,bool isClipboard)
{
   if (_isUnix()) {
      // Need this for QT and if we correct our GTK support
      // we need it for GTK as well.
      if (name=='' && !isClipboard) {
         // Always use the system clipboard for a mouse paste
         _str cb_format=_clipboard_format(VSCF_VSTEXTINFO,isClipboard);
         typeless pid,cbtype,info;
         parse cb_format with 'pid='pid cbtype info;
         temp_view_id := 0;
         // Assume VSE version are compatible.  This could break in the future.
         if (getpid()==pid && cbtype!='' && info!='') {
            temp_view_id=_cvtsysclipboard2(true,cbtype,info,p_UTF8,isClipboard);
         } else {
            if (_clipboard_format(VSCF_TEXT,isClipboard)) {
               temp_view_id=_cvtsysclipboard2(true,'CHAR','',p_UTF8,isClipboard);
            } else {
               temp_view_id=_clipboards_view_id;
            }
         }
         return(temp_view_id);
      }
   }
   return(_clipboards_view_id);
}
static int _cvtsysclipboard2(bool make_temp_view,_str cbtype,_str cbrest,bool make_temp_utf8=true,bool isClipboard=true,_str lexername='',int MarkFlags=-1)
{
   // Convert the system clipboard in VSTEXT format to an internal
   // clipboard.
   int temp_view_id=_clipboards_view_id;
   view_id := 0;
   get_window_id(view_id);
   cbtype=upcase(cbtype);
   typeless width='';
   _str smultiCursorCount;
   parse cbrest with width smultiCursorCount .;
   if (make_temp_view) {
      _create_temp_view(temp_view_id);
      p_UTF8=make_temp_utf8;
      _add_clipboard_header(cbtype,0,NULL_CB_NAME,0,make_temp_utf8,lexername);
   } else {
      activate_window(_clipboards_view_id);
      push_clipboard_itype(cbtype,'',0,p_UTF8,p_lexer_name,_MultiCursorCount());
   }
   cbheader_linenum := p_line;
   insert_line('');
   _copy_from_clipboard(isClipboard,(MarkFlags!=-1 && (MarkFlags&VSMARKFLAG_BINARY)));
   if (!_line_length() && cbtype!='CHAR') {
      _delete_line();
   }
   int Noflines=p_line-cbheader_linenum;
   p_line=cbheader_linenum;
   _change_clipboard_Noflines(Noflines);
   activate_window(view_id);
   _lastcbisauto=false;
   return(temp_view_id);
}

#if 1 //!__UNIX__
void _cvtautoclipboard()
{
   if (_isUnix()) return;
   if (_lastcbisauto) {
      //say('_cvtautoclipboard:');
      _str cb_format=_clipboard_format(VSCF_VSTEXTINFO,true);
      _str pid,cbtype,cbrest;
      parse cb_format with 'pid='pid cbtype cbrest;
      if (getpid()==pid) {
         //say('_cvtautoclipboard: same pid');
         _cvtsysclipboard2(false,cbtype,cbrest,false,true);
      }
   }
}
#endif
#if 0
static AssertBufsize(_str msg)
{
   get_window_id(orig_view_id);
   activate_window(_clipboards_view_id);
   say(msg);
   a=1;b=1;_test1(a,b);
   activate_window(orig_view_id);
}
#endif
// DLL interface uses this function
bool _HaveClipboard()
{
   return(_Nofclipboards || _clipboard_format(VSCF_TEXT,true));
}

static void cycle_clipboard(int dir = 1)
{
   if (_Nofclipboards < 1) {
      return;
   }
   view_id := 0;
   typeless mark = _alloc_selection();
   if ( mark < 0 ) return;

   get_window_id(view_id);
   activate_window(_clipboards_view_id);
   if (dir > 0) {
      goto_clipboard(_Nofclipboards);
   } else {
      top();
   }
   mark_name := "";
   Noflines := 0;
   typeless junk1, junk2, utf8;
   int multiCursorCount;
   _get_clipboard_header(mark_name, Noflines, junk1, junk2, utf8,auto junk3,multiCursorCount);
   _select_line(mark); down(Noflines); _select_line(mark);
   if (dir > 0) {
      top(); up();
   } else {
      bottom();
   }
   _move_to_cursor(mark);
   _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);

   _deselect(mark);
   goto_clipboard(_Nofclipboards);
   _get_clipboard_header(mark_name, Noflines, junk1, junk2, utf8);
   orig_utf8 := p_UTF8; p_UTF8 = utf8;
   if (mark_name=='LINE') {
      down(); _select_line(mark); down(Noflines); _select_line(mark);
   } else if (mark_name=='CHAR') {
      down(); _begin_line();_select_char(mark); 
      down(Noflines); _end_line();_select_char(mark);
   } else if (mark_name=='BLOCK') {
      down(); _begin_line();_select_block(mark); 
      down(Noflines); _end_line();_select_block(mark);
      _select_type(mark,'I',0);
   }
   _copy_to_clipboard(mark,true,false,multiCursorCount);
   p_UTF8 = orig_utf8;
   _free_selection(mark);
   activate_window(view_id);
}

/**
 * Cycles clipboards and pastes next clipboard item to buffer.
 * Item remains selected and ignores deselect paste option, this
 * allows for quickly cycling through all clipboards.
 *
 * @see paste
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions
 */
_command void paste_prev_clipboard() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   paste_next_clipboard(-1);
}

/**
 * Cycles clipboards and pastes next clipboard item to buffer.
 * Item remains selected and ignores deselect paste option, this
 * allows for quickly cycling through all clipboards.
 *
 * @param nextOrPrev - option to use next (default [greater 
 *                     than 0]) or previous clipboard (less than
 *                     or equal to 0)
 *
 * @see paste
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions
 */
_command void paste_next_clipboard(int nextOrPrev = 1) name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   int was_command_state=command_state();
   if (was_command_state) {
      init_command_op();
   }

   index := last_index('', 'C');
   _str last_cmd = name_name(prev_index('','C'));
   if (prev_index('') == last_index('') || last_cmd == 'paste-next-clipboard' || last_cmd == 'paste-prev-clipboard') {
      // cycle on consecutive calls -- first time called starts on current clipboard
      cycle_clipboard(nextOrPrev);
   }
   old_def_deselect_paste := def_deselect_paste;
   typeless old_def_persistent_select = def_persistent_select;
   def_persistent_select = 'D';
   def_deselect_paste = false;
   paste();
   def_deselect_paste = old_def_deselect_paste;
   def_persistent_select = old_def_persistent_select;
   if (was_command_state) {
      retrieve_command_results();
   }
   last_index(index, 'C');
}

/**
 * Reset all internal clipboard data.
 *
 * @categories Clipboard_Functions
 */
_command void reset_clipboards() name_info(',')
{
   _Nofclipboards = 0;
   _Nofnulls = 0;
   _append_next_clipboard = false;

   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_clipboards_view_id);
   _lbclear();
   activate_window(orig_wid);

   _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);
}


/**
 * Write clipboard to file.
 *
 * @categories Clipboard_Functions
 */
_command void write_clipboard(_str name='') name_info(',')
{
   if (!_Nofclipboards) {
      message('No clipboards');
      return;
   }
   typeless result = _OpenDialog('-modal',
                               'Write Clipboard',
                               '',
                               def_file_types,
                               OFN_SAVEAS|OFN_SAVEAS_FORMAT|OFN_APPEND|OFN_PREFIXFLAGS,
                               '',
                               '',
                               '',
                               '',
                               ''
                              );
   if(result == '') {
      return;
   }

   typeless orig_mark = _duplicate_selection('');
   orig_view_id := p_window_id;
   activate_window(_clipboards_view_id);
   save_pos(auto p);
   goto_named_clipboard(name);
   _get_clipboard_header(auto type, auto Noflines, auto clip_name, auto col, auto utf8, auto lexername);
   markid := _alloc_selection();
   orig_utf8 := p_UTF8; p_UTF8 = utf8;
   down(); _begin_line();
   _select_line(markid); _select_type(markid, 'S', 'E');
   down(Noflines-1);
   _select_line(markid);
   _show_selection(markid);
   p_UTF8 = orig_utf8;

   temp_view_id := 0;
   orig_view_id = _create_temp_view(temp_view_id);
   orig_utf8 = p_UTF8; p_UTF8 = utf8;
   _copy_to_cursor(markid);
   _delete_line();

   status := 0;
   option := rest := "";
   parse result with option rest;
   if (lowcase(option) == '-a') {
      status = append(result);
      if (status) {
         clear_message();
         typeless junk1 = "";
         _message_box(nls('Unable to write clipboard to %s', strip_options(rest, junk1, true))'. 'get_message(status));
      }
   } else {
      status = put(result, SV_OVERWRITE);
      if (status) {
         clear_message();
         _message_box(nls('Unable to write clipboard to %s', result)'. 'get_message(status));
      }
   }
   p_UTF8 = orig_utf8;

   restore_pos(p);
   activate_window(orig_view_id);
   _show_selection(orig_mark);
   _delete_temp_view(temp_view_id);
   _free_selection(markid);
}
void _PasteWithBlockModeSupport(_str name='') {
   _str old = def_persistent_select;
   def_persistent_select = 'D';

   paste_done := false;

   // Only support current clipboard right now (_getClipboardMarkType??).
   if (p_HasBuffer && _select_type('')=='BLOCK') {
      _str cbtype=_getClipboardMarkType(true,name);
      if (cbtype!='BLOCK' && cbtype!='') {
         // Returns
         keya:=_getClipboardText(true,true,name,(p_object==OI_EDITOR)?p_UTF8:true);
         if (keya!=null) {
            just_call_key:=false;
            InsertingChar:=true;
            key:=C_V;
            if (!p_hex_mode && doBlockModeKey(key,keya,InsertingChar && !just_call_key)) {
               paste_done=true;
               //_macro_call('doBlockModeKey',key,keya,(InsertingChar && !just_call_key));
               //last_index(find_index('doBlockModeKey',PROC_TYPE|COMMAND_TYPE),'C');
            }
         }
      }
   }

   if (!paste_done) {
      if(def_keys == 'brief-keys') {
         last_index(find_index('brief-paste', COMMAND_TYPE));
         brief_paste(name);
      } else {
         paste(name);
      }
   }
   def_persistent_select = old;
}

void _copy_text_to_clipboard(_str text,bool doAppend=false) {
   orig_view_id := _create_temp_view(auto temp_view_id);

   orig_markid := _duplicate_selection('');
   mark_id := _alloc_selection();
   _insert_text(text);
   _begin_line(); _select_char(mark_id); _end_line(); _select_char(mark_id);
   _show_selection(mark_id);
   if (doAppend) {
      append_to_clipboard();
   } else {
      copy_to_clipboard();
   }
   activate_window(orig_view_id);
   _show_selection(orig_markid);
   _free_selection(mark_id);
   _delete_temp_view(temp_view_id);
}

void _clipboard_clear_all() { 
   yesnosave_clipboards="";
#if 1
   _append_next_clipboard=false;
   /* Start a temp buffer in hidden window called "killed" to */
   /* contain killed text. */
   /* No need to use more than one buffer to save multiple kills. */
   int window_group_view_id=_find_or_create_temp_view(_clipboards_view_id,'+futf8 +70 +t','.clipboards',false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   _Nofclipboards=0;
   _tbSetRefreshBy(VSTBREFRESHBY_INTERNAL_CLIPBOARDS);
   _Nofnulls=0;
//  replace_kill=0
   activate_window(window_group_view_id);
#endif
   rc=0;
}

void _clipboard_validate_all() {
   if (!_Nofclipboards) {
      if (_Nofnulls) {
         _clipboard_clear_all();
      }
      return;
   }
   orig_wid:=p_window_id;
   can_restore_orig_wid := orig_wid!=_clipboards_view_id;
   activate_window(_clipboards_view_id);
   save_pos(auto p);
   top();
   status := 0;
   Nofnulls_count := 0;
   for (i:=0; i<_Nofclipboards ; ++i) {
      status=_get_clipboard_header(auto type,auto count,auto name,auto col,auto utf8);
      if (status) {
         break;
      }
      if (name=='*') {
         ++Nofnulls_count;
      }
      orig_ln:=p_line;
      status=down(count);
      if (status) {
         break;
      }
      status=down();
      if (status) {
         if (i==_Nofclipboards-1) {
            status=0;
         }
         break;
      }

   }
   if (status || Nofnulls_count!=_Nofnulls) {
      _clipboard_clear_all();
   } else {
      restore_pos(p);
   }
   if (can_restore_orig_wid) {
      p_window_id=orig_wid;
   }

}
