////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47737 $
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
#include "search.sh"
#include "color.sh"
#import "c.e"
#import "clipbd.e"
#import "context.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "mfsearch.e"
#import "picture.e"
#import "recmacro.e"
#import "search.e"
#import "searchcb.e"
#import "selcode.e"
#import "stdprocs.e"
#import "surround.e"
#import "tbfind.e"
#import "se/tags/TaggingGuard.e"
#endregion

/**
 * If enabled, the {@link plusminus} command will try to find code
 * blocks to expand or collapse if the cursor is on a line that does
 * not have a +/- bitmap on it.
 * 
 * @default true
 * @categories Configuration_Variables, Tagging_Functions
 */
boolean def_plusminus_blocks=true;

/**
 * Toggles selective display on and off.  If selective display is
 * not on, this will hide lines in the current buffer which are 
 * not part of a function definition heading and collapse comment blocks.
 * If selective display is active, it will do a unhide everything.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_col1
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display
 */ 
_command toggle_all_outlining() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_NofSelDispBitmaps > 0) {
      show_all();
   } else {
      show_procs(SELDISP_COLLAPSEPROCCOMMENTS);
   }
}

/**
 * Hides lines in the current buffer which are not part of a 
 * function definition heading.  Also collapses comment blocks.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_col1
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @see toggle_all_outlining
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display
 */ 
_command collapse_to_definitions() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   show_procs(SELDISP_COLLAPSEPROCCOMMENTS);
}

static boolean plusminus_block()
{
   // get the number of lines in the current code block
   save_pos(auto p);
   isComment   := false;
   allowUnsurround := true;
   first_line := 0;
   last_line  := 0;
   num_first_lines := 0;
   num_last_lines  := 0;
   indent_change := true;
   if ( get_code_block_lines(first_line, num_first_lines, 
                             last_line,  num_last_lines,
                             indent_change, isComment, 
                             allowUnsurround, false, true) ) {
      // we have a code block, hide all but the first line of it
      if (p_line==first_line && first_line+1 <= last_line-num_last_lines) {
         _hide_lines(first_line+1, last_line-num_last_lines);
         restore_pos(p);
         return true;
      }
   }

   restore_pos(p);
   return false;
}

/**
 * Expands or collapses selective display blocks.
 * <ul>
 * <li>If the cursor is on a line that contains a "+" bitmap
 *        for selective display, expand the collapsed block.
 * <li>If the cursor is on a line that contains a "-" bitmap
 *     for selective display, collapse the block.
 * <li>otherwise, if the cursor is on a line that has no "+"
 *     or "-" bitmap, but the line is the first line of a block
 *     collapse the block, creating a new selective display region.
 *     The definition of the current block depends on the language.
 * </ul>
 * 
 * @see all
 * @see hide_selection
 * @see hide_all_comments
 * @see hide_code_block
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @see def_plusminus_blocks
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display
 */
_command int plusminus(_str CheckCurLineOnly='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   save_pos(auto p);
   int pm = _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF);
   if (pm==PLUSBITMAP_LF) {
      int start_level=_lineflags()&LEVEL_LF;
      int show_level=start_level+NEXTLEVEL_LF;
      get_event('B');
      _lineflags(MINUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF);
      for(;;) {
         if(down()) break;
         int level=_lineflags()&LEVEL_LF;
         // IF a strange condition occurred or we hit the start of a new expansion
         //    at the same level
         if (level<start_level ||
             (level==start_level && _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF))
             ) {
            break;
         }
         if (def_seldisp_flags &SELDISP_EXPANDSUBLEVELS) {
            if (_lineflags() & PLUSBITMAP_LF) {
               _lineflags(MINUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF);
            }
            // Turn off HIDDEN
            _lineflags(0,HIDDEN_LF);
         } else if (def_seldisp_flags &SELDISP_COLLAPSESUBLEVELS) {
            if (_lineflags() & MINUSBITMAP_LF) {
               _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF);
            }
         }
         if (level>=show_level) {
            if (level<=show_level) {
               if ( _lineflags()&MINUSBITMAP_LF) {
                  show_level=level+NEXTLEVEL_LF;
               }
               // Turn off HIDDEN
               _lineflags(0,HIDDEN_LF);
            }
         } else {
            if (level<show_level) {
               show_level=level;
               if (_lineflags()&MINUSBITMAP_LF) {
                  show_level=level+NEXTLEVEL_LF;
               }
               // Turn off HIDDEN
               _lineflags(0,HIDDEN_LF);
            /*} else if ( level==show_level ) {
               // Turn off HIDDEN
               _lineflags(0,HIDDEN_LF);
               if ( _lineflags()&PLUSBITMAP_LF) {
                  show_level=level-NEXTLEVEL_LF;
               }*/
            }
         }
      }
      restore_pos(p);
      return(0);
   } else if (pm==MINUSBITMAP_LF) {
      int start_level=_lineflags()&LEVEL_LF;
      get_event('B');
      _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF);
      for(;;) {
         if(down()) break;
         int level=_lineflags()&LEVEL_LF;
         // IF a strange condition occurred or we hit the start of a new expansion
         //    at the same level
         if (level<=start_level
             // ||(level==start_level && _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF))
             ) {
            break;
         }
         //Turn on HIDDEN
         _lineflags(HIDDEN_LF);
      }
      restore_pos(p);
      return(0);

   } else if (CheckCurLineOnly=='') {

      // first see if there is a block to expand or collapse under the cursor
      if (def_plusminus_blocks && plusminus_block()) {
         return 0;
      }

      restore_pos(p);
      int flags=_lineflags();
      int show_level=flags&LEVEL_LF;
      for (;;) {
         flags=_lineflags();
         int level = flags&LEVEL_LF;
         if (level<show_level) {
            if (flags&HIDDEN_LF) {
               break;
            }
            if (flags&MINUSBITMAP_LF) {
               return(plusminus());
            }
            break;
         }
         if ( up() ) break;
      }
      restore_pos(p);
      message("Nothing to expand or collapse");
   }
   return(1);
}
/*
    This function performs the following to the selection
    specified
       *  Character selection is converted to a line selection
          if it encompasses lines.

    For line selections or converted character selections
    the following actions are performed.
       *  If the last line of selection has a plus bitmap,
          hidden lines below the plus bitmap are selected.
          In addition, hidden lines at the end of new selection
          that are blank or just comments are removed from
          the selection.
       *  If the line before the first line of the selection
          contains a plus bitmap, the line selection is
          extended to contain the comments before the
          first line of the selection.
RETURN
    true if selection was modified
*/
boolean _extend_outline_selection(_str markid)
{
   if (_select_type(markid)!="LINE" || _select_type(markid)=="") return(false);

   _str persistant=(def_persistent_select=='Y')?'P':'';
   _str mstyle='N'persistant;
   int orig_buf_id=p_buf_id;
   int start_col,end_col,bufid;
   _get_selinfo(start_col,end_col,bufid,markid);
   p_buf_id=bufid;
   typeless p,begin,vend;
   save_pos(p);
   if (!_isnull_selection(markid) && _select_type(markid)=='CHAR') {
      if (start_col==1 && end_col==1 && !_select_type(markid,"I")) {
         _begin_select(markid);save_pos(begin);
         _end_select(markid);save_pos(vend);
         _deselect(markid);
         restore_pos(begin);_select_line(markid,mstyle);
         restore_pos(vend);up();_select_line(markid,mstyle);
      }

   }
   if (_select_type(markid)=="CHAR") {
      restore_pos(p);
      p_buf_id=orig_buf_id;
      return(false);
   }
   if (markid=="") markid=_duplicate_selection("");
   int new_markid=_duplicate_selection(markid);
   if (_select_type(markid,'S')=='C') {
      _select_type(markid,'S','E');
   }
   _end_select(new_markid);
   int pm = _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF);
   _free_selection(new_markid);
   // IF there is a plus bitmap displayed on this line.
   boolean result=false;
   if (pm==PLUSBITMAP_LF) {
#if 0
      if (p_lexer_name!="") {
         start_line=p_line;
      }
#endif
      for(;;) {
         if(down()) break;
         if (!(_lineflags()&HIDDEN_LF)) {
            up();
            break;
         }
      }
#if 0
      if (p_lexer_name!="") {
         // Don't include comments at the end of the selection
         _end_line();
         // Search backwards skipping blanks and comments
         _clex_skip_blanks("h-");
         if (p_line<start_line) {
            p_line=start_line;
         }
      }
#endif
      save_pos(vend);
      _begin_select(markid);save_pos(begin);

      _deselect(markid);
      restore_pos(begin);_select_line(markid,mstyle);
      restore_pos(vend);_select_line(markid,mstyle);
      result=true;
   }
   restore_pos(p);
   p_buf_id=orig_buf_id;
   return(result);
}
boolean _preprocessing_supported()
{
   lang := p_LangId;
   return(lang=='c' || lang=='cs' || lang=='pas' || ('.'lang==_macro_ext));
#if 0
   if ( def_keys=='vi-keys' ) {
      if ( upcase(vi_get_vi_mode())=='C' ) {
         etab_name=vi_name_on_key('','IK');
      } else {
         etab_name=name_name(p_mode_eventtab);
      }
   } else {
      etab_name=name_name(p_mode_eventtab);
   }
   //etab_name=name_name(p_mode_eventtab);
   return(etab_name=='c-keys' || etab_name=='slick-keys' || etab_name=='pas-keys' /*||
          etab_name=='awk-keys' || etab_name=='perl-keys' */);
#endif
}
/**
 * Hides all lines in current buffer which contain only comment text.
 * 
 * @see all
 * @see hide_selection
 * @see hide_code_block
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command void hide_all_comments() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   mou_hour_glass(1);
   save_pos(auto p);
   top();
   int status=_clex_find(COMMENT_CLEXFLAG);
   for (;;) {
      if (status) {
         break;
      }
      int orig_line=p_line;
      hide_comments();
      p_line=orig_line;
      _end_line();
      status=_clex_find(COMMENT_CLEXFLAG,'N');
      if (status) {
         break;
      }
      status=_clex_find(COMMENT_CLEXFLAG);
   }
   mou_hour_glass(0);
   restore_pos(p);
}
/*
Some case analysis

   [1]         [2]           [3]            [4]         [5]

    1           1+            1              1+          2
 -->1       --->2         --->1+         --->2+      --->1+
    ...         ...           ...            ...         ...
    1           2             2              3           2
-------------------------------------------------------------
   2 OK       NO              2 OK         NO           NO
          Could Use second
          Line of selection
          but it must be at
          same level
End of selection considerations
 * Make sure selection does not extend past end of this level
     2                  2
 --->2               -->2
     2                  2 <---shorten selection to here
 --->1+              -->1+

  Just stop

* Also make sure encompass all inner levels
   1
-->1
   1+
-->2
   2
   2 <--  Extend selection to here
   1
   1

*/
void _hide_lines(int first_line, int last_line)
{
   if (first_line>last_line) {
      p_line=last_line;
      return;
   }
   p_line=first_line;
   // IF we are on line#0 and we are not displaying tof line
   int status;
   if (_on_line0() && !_default_option('t')) {
      ++first_line;
      status=down();
      if (status || first_line>=last_line) {
         p_line=last_line;
         return;
      }
   }
   int cur_lineflags=_lineflags();
   up();
   int prev_lineflags=_lineflags();
   int new_level=0;
   // IF this is case 1 or 3
   if (!(prev_lineflags & (PLUSBITMAP_LF|MINUSBITMAP_LF)) &&
       (prev_lineflags & LEVEL_LF)==(cur_lineflags & LEVEL_LF)) {
      new_level=(prev_lineflags& LEVEL_LF) + NEXTLEVEL_LF;
      //messageNwait("hide_selection: case 1 or 3");
   // IF  this is case 2
   } else if ((prev_lineflags & (PLUSBITMAP_LF|MINUSBITMAP_LF)) &&
              !(cur_lineflags & (PLUSBITMAP_LF|MINUSBITMAP_LF))
              ) {
      p_line=last_line;
      return;
/*
      //messageNwait("hide_selection: case 2");
       down();
       // IF we are left with only one line
       if (p_line>=last_line) {
          p_line=last_line;
          return;
       }
       new_level=(cur_lineflags&LEVEL_LF) + NEXTLEVEL_LF;
*/
   // IF  this is case 4 or 5
   } else {
      p_line=last_line;
      return;
   }

   _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF);
   down();
   int start_level=new_level-NEXTLEVEL_LF;
   boolean doEndLastLevel=true;
   for (;;) {
      int level=(_lineflags() & LEVEL_LF);
      // IF a strange condition occurred or we hit the start of a new expansion
      //    at the same level
      if (level<start_level
          //||(level==start_level && _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF))
          ) {
         doEndLastLevel=false;
         break;
      }
      new_level= (_lineflags() & LEVEL_LF)+NEXTLEVEL_LF;
      _lineflags(HIDDEN_LF|new_level,HIDDEN_LF|LEVEL_LF);
      status=down();
      if (status) {
         doEndLastLevel=false;
         break;
      }
      if (p_line>last_line) {
         break;
      }
   }
   if (doEndLastLevel) {
      for (;;) {
         new_level= (_lineflags() & LEVEL_LF)+NEXTLEVEL_LF;
         if (new_level /*(_lineflags() & LEVEL_LF)*/<=start_level+NEXTLEVEL_LF) {
            break;
         }
         _lineflags(HIDDEN_LF|new_level,HIDDEN_LF|LEVEL_LF);
         status=down();
         if (status) break;
      }
   }
   p_line=last_line;
}
static void _show_lines(int first_line, int last_line)
{
   int new_level;
   p_line=first_line;
   up();
   if (p_line<=1) {
      p_line=0;
      new_level=0;
   } else {
      new_level=_lineflags()&LEVEL_LF;
      if(!up()) {
         new_level=_lineflags()&LEVEL_LF;
         down();
      }
   }
   for (;;) {
      if (p_line>last_line) break;
      int level=(_lineflags() & LEVEL_LF);
      _lineflags(new_level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
      int status=down();
      if (status) {
         break;
      }
      if (p_line>last_line) {
         break;
      }
   }
   p_line=last_line;
}

/**
 * Show all lines in current selection.
 * 
 * @param markid  is a handle to a selection or bookmark returned by one of
 *                the built-ins _alloc_selection or _duplicate_selection.
 *                A mark_id of '' or no mark_id parameter identifies the
 *                active selection.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see hide_selection
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command void show_selection(_str markid="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_AB_SELECTION)
{
   save_pos(auto p);
   hide_selection(markid,1);
   restore_pos(p);
}
/**
 * Hides lines in current selection.
 * 
 * @param markid  is a handle to a selection or bookmark returned by one of
 *                the built-ins _alloc_selection or _duplicate_selection.
 *                A mark_id of '' or no mark_id parameter identifies the
 *                active selection.
 * @param doShow  show selected lines or hide them?
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @see show_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command void hide_selection(_str markid="", _str doShow="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_AB_SELECTION)
{
   if (!select_active(markid)) {
      _message_box(get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   save_pos(auto p);
   _begin_select(markid);
   int first_line=p_line;
   _end_select(markid);
   int last_line=p_line;
   if (_select_type(markid)=='CHAR' && !_select_type(markid,'i')) {
      int start_col,end_col,buf_id;
      _get_selinfo(start_col,end_col,buf_id,markid);
      if (end_col==1) {
         --last_line;
      }
   }
   if (doShow != "") {
      _show_lines(first_line,last_line);
   } else {
      _hide_lines(first_line,last_line);
   }
   _deselect(markid);
   restore_pos(p);

}
/**
 * Displays <b>Selective Display dialog box</b> which lets you 
 * selectively display lines of the current buffer.
 * 
 * @param options    pass "-df" to disable show function headers
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see show_col1
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command void selective_display(_str options="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_MARK)
{
   show('_seldisp_form',options);
}
static void hide_comments(boolean doShow=false)
{
   //prev_level=0;
   // Search for beginning of comments
   int status=_clex_skip_blanks("h-");
   if (status) {
      top();
      _clex_find(COMMENT_CLEXFLAG,"O");
   } else {
      _end_line();  // Skip to end of line so we don't find comment after non-blank text.
      //prev_level=_lineflags()&LEVEL_LF;
      _clex_find(COMMENT_CLEXFLAG,"O");
   }

   // Changed this release to put plus + on first line of comment.
   // This allows the user to more easily collapse comments separately
   // from functions
#if 1
   int old_line=p_line;
   int start_line=p_line+1;
   // Find end of comment
   status=_clex_skip_blanks("h");
   // IF there is nothing to collapse
   if (p_line<=old_line) {
      return;
   }
   if (status) {
      bottom();
      _clex_find(COMMENT_CLEXFLAG,"-O");
      if (p_line<=old_line) {
         return;
      }
   } else {
      old_line=p_line;
      _clex_find(COMMENT_CLEXFLAG,"-O");
      // IF there is any non-comment or blank text on this line
      // This occurs when line starts with comment but after comment is some code.
      if (p_line==old_line) {
         up();
         // IF there is nothing to collapse
         if (p_line<=start_line) {
            return;
         }
      }
   }
   int last_line=p_line;
   if (doShow) {
      _show_lines(start_line,last_line);
   } else {
      _hide_lines(start_line,last_line);
   }
#else
   old_line=p_line;
   // IF there is nothing to collapse
   if (down()) {
      return;
   }
   _begin_line();search('[~ \t]|$','@rh');  // first_non_blank("h");
   // IF there is nothing to collapse
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return;
   }
   start_line=p_line;
   // Find end of comment
   status=_clex_skip_blanks("h");
   if (status) {
      bottom();
   } else {
      old_line=p_line;
      _clex_find(COMMENT_CLEXFLAG,"-O");
      // IF there is any non-comment or blank text on this line
      // This occurs when line starts with comment but after comment is some code.
      if (p_line==old_line) {
         up();
         // IF there is nothing to collapse
         if (p_line<=start_line) {
            return;
         }
      }
   }
   last_line=p_line;
   if (doShow) {
      _show_lines(start_line,last_line);
   } else {
      _hide_lines(start_line,last_line);
   }
#endif
}
int _OnUpdate_hide_code_block(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if(_isSelectCodeBlock_supported()) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}

/**
 * Hides lines in current code block.  The definition of the current block 
 * depends on the language.  Invoking this command from a key, menu, or button 
 * bar multiple times in succession hides larger code blocks.
 * 
 * @see all
 * @see hide_selection
 * @see hide_all_comments
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command void hide_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // Check to see if the very last command executed is the same command:
   int expandBlock = 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == "hide-code-block" ) expandBlock = 1;
   //say( '******* name='name );

   //Check if the first non-blank character of this line is a comment
   save_pos(auto p);
   first_non_blank();
   if (_clex_find(0,'g')==CFG_COMMENT) {
      hide_comments();
      return;
   }

   restore_pos(p);
   int status=cs_hide_code_block( expandBlock );
   if (!status && select_active()) {
      hide_selection();
      restore_pos(p);
   } else {
      _beep();
      sticky_message("Code block not found or language not supported");
   }

   // Make this command the last command executed:
   last_index( find_index( 'hide_code_block', COMMAND_TYPE ), 'C' );
}

/**
 * Unhides lines in current code block.  The definition of the current block 
 * depends on the language.  
 * 
 * @see all
 * @see hide_code_block
 * @see hide_selection
 * @see hide_all_comments
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display
 */
_command void show_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int expandBlock = 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == "show-code-block" ) expandBlock = 1;
   //Check if the first non-blank character of this line is a comment
   save_pos(auto p);
   _begin_line();search('[~ \t]|$','@rh');
   if (_clex_find(0,'g')==CFG_COMMENT) {
      hide_comments(1);
      return;
   }
   restore_pos(p);
   int status=cs_hide_code_block( expandBlock );
   if (!status && select_active()) {
      hide_selection("","1");
      restore_pos(p);
   } else {
      _beep();
      sticky_message("Code block not found or language not supported");
   }
   last_index( find_index( 'show-code-block', COMMAND_TYPE ), 'C' );
}
#if 0
_command void hide_all() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   top();
   // IF we are displaying the top of file line (line0)
   if (_default_option('t')) {
      // Put the plus sign there.
      up();
   } else {
      // IF there are not lines in this file.
      if (_on_line0()) {
         return;
      }
   }
   _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF);
   for (;;) {
      if ( down()) break;
      _lineflags(HIDDEN_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF);
   }
}
#endif
/**
 * Displays all lines in the current buffer.  Resets selective display.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command void show_all() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   save_pos(auto p);
   top();
   up();
   _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
   for (;;) {
      if ( down()) break;
      _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
   }
   restore_pos(p);
}

/**
 * Expand/collapse all collapsed/expanded branches.
 * 
 * @param option (optional). '' = expand all collapsed branches
 *                           'C' = collapse all expanded branches.
 *                           Default to ''.
 */
_command void expand_all(_str option='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int mask = upcase(option)=='C' ? MINUSBITMAP_LF : PLUSBITMAP_LF;
   save_pos(auto p);
   top();
   up();
   // Do line 0 first
   int plus_or_minus= _lineflags()&(mask);
   if( plus_or_minus ) {
      plusminus();
   }
   for (;;) {
      if ( down()) {
         break;
      }
      plus_or_minus= _lineflags()&(mask);
      if( plus_or_minus ) {
         plusminus();
      }
   }
   restore_pos(p);
}

/**
 * Collapse all expanded branches.
 */
_command void collapse_all() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   expand_all('C');
}



/**
 * Makes current line visible, expanding levels and preserving all selective display marks
 */
void expand_line_level()
{
   int flags = _lineflags();
   if (flags & HIDDEN_LF) {
      boolean skip_first = true;
      int level = _LevelIndex(flags);
      typeless p; save_pos(p);
      for (;;) {
         flags = _lineflags();
         if (_LevelIndex(flags) < level && (flags & PLUSBITMAP_LF) && !skip_first) {
            plusminus();
         }
         if (!(flags & HIDDEN_LF)) {
            break;
         }
         skip_first = false;
         if (up()) {
            break;
         }
      }
      restore_pos(p);
   }
}


static void _hide_lines2(int start_skip_linenum,int end_exp_linenum)
{
   //say("s="start_skip_linenum" e="end_exp_linenum);if(start_skip_linenum==1) trace();
   save_pos(auto p);
   p_line=start_skip_linenum;
   int new_level=(_lineflags() & LEVEL_LF)+NEXTLEVEL_LF;
   if (!up()) {
      if (!(_lineflags() & HIDDEN_LF)) {
         _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      }
      down();
   }
   for (;p_line<=end_exp_linenum;) {
      _lineflags(HIDDEN_LF|new_level,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      if (down()) break;
   }
   restore_pos(p);
}
static int find_directive(_str &directive,int find_first,boolean isdelphi)
{
   int status=0;
   if (isdelphi) {
      if (find_first) {
         status=search('(\(\*|\{)\${ifdef|ifndef|ifopt|else|endif|define|undef}',"hr@");
         //status=search('(\(\*|\{)\${[a-zA-Z](\+|)}',"hr@");
      } else {
         status=repeat_search();
      }
      for (;;) {
         if (status) {
            return(status);
         }

         // IF we are not in a nested comment AND we are in a comment
         if (!(_lineflags()&MLCOMMENTLEVEL_LF) && _clex_find(0,'g')==CFG_COMMENT) {
            // IF we are not sure this is the start of the multi-line comment
            if (p_col!=1) {
               left();
               // IF we are in a line comment
               if (_clex_find(0,'g')==CFG_COMMENT) {
                  status=repeat_search();
                  continue;
               }
            }
            directive=get_match_text(0);
#if 0
            if (pos(' 'directive' ',' ifdef ifndef ifopt else endif define undef ',1,'i')) {
               return(0);
            }
            ch=last_char(directive);
            // IF this is a compiler switch
            if (ch=='+' || ch=='-') {
               return(directive);
            }
#endif

            return(0);
         }
         status=repeat_search();
      }
   }
   if (find_first) {
      status=search('^[ \t]*\#([ \t]*)\c{ifdef|ifndef|if|elif|else|region|endregion|endif|define|undef}',"hr@");
      //status=search('^ *\#\c([ \t]*){if|elif|else|endif}','hr@');
   } else {
      status=repeat_search();
   }
   for (;;) {
      if (status) {
         return(status);
      }
      if (_clex_find(0,'g')==CFG_PPKEYWORD) {
         directive=get_match_text(0);
         return(0);
      }
      status=repeat_search();
   }
}
/*
   Call this function after calling find_directive to
   get directive parameters
*/
static void get_line_cont(_str &line,boolean isdelphi)
{
   _str ppkeyword='';
   if (isdelphi) {
      //p_col+=match_length('0');   // Skip over ppkeyword
      line=_expand_tabsc(p_col,-1,'E');
      parse line with '$' ppkeyword '[ \t]#','r' line '[~A-Za-z0-9_$+]','r';
      return;
   }
   //len=match_length('s')+match_length()+1;
   p_col+=match_length('0');   // Skip over ppkeyword
   line=_expand_tabsc(p_col,-1,'E');
   //line=get_text(_line_length()-match_length()-1,match_length('s')+match_length()+1);
   // Don't want to count trailing \ if comment on preprocessing line.
   int old_len=length(line);
   parse line with line '//';
   // If there was not a line comment
   if (old_len==length(line)) {
      _end_line();
      for (;;) {
         boolean RemoveLastChar=false;
         if (_clex_find(0,'g')!=CFG_COMMENT) {
            RemoveLastChar=(last_char(line)=='\');
            if (!RemoveLastChar) break;
         }
         p_col=1;
         down();
         get_line(auto line2);
         if (RemoveLastChar) {
            line=substr(line,1,length(line)-1);
         }
         old_len=length(line2);
         parse line2 with line2 '//';
         // If there was a line comment
         line=line:+line2;
         if (old_len!=length(line2)) break;
         _end_line();
      }
   }
   //messageNwait("get_line_cont: h2 line="line);
   /*
       Strip multiline comments
   */
   // Don't support Slick-C nested comments yet.
   // This does not support Slick-C strings with /* in them yet.
   // To do this we need to skip of strings.
   int i,j;
   for (i=1;;) {
      i=pos('/*',line,i);
      if (!i) break;
      j=pos('*/',line,i+2);
      if (!j) {
         line=substr(line,1,i-1);
         break;
      }
      line=substr(line,1,i-1):+substr(line,j+2);
   }
   //messageNwait('get_line_cont: OUT line='line);
}
static int isopt(_str &define_names,_str name)
{
   return(pos('(^| )'_escape_re_chars(name)'\+',define_names,1,'r'));
}
static int isdefined(_str &define_names,_str name)
{
   return(pos('(^| )'_escape_re_chars(name)'(=([~ ]@)|)( |$)',define_names,1,'r'));
}
static void remove_define(_str &define_names,_str name)
{
   int i=isdefined(define_names,name);
   if (i) {
      define_names=strip(substr(define_names,1,i-1):+" ":+
                         substr(define_names,i+pos('')));
      //messageNwait('remove_define: remove names='define_names);
   }
}
static void replace_defined_calls(_str &define_names,_str &exp)
{
   int i,j;
   word_chars := _clex_identifier_chars();
   for (i=1;;) {
      //j=pos('(^|[~a-zA-Z0-9_]){defined[ \t]*\([ \t]*[ \t]*)}',exp,i,'r');
      j=pos('(^|[~'word_chars']){defined[ \t]*\([ \t]*{['word_chars']*}[ \t]*\)}',exp,i,'r');
      //j=pos('(^|[~a-zA-Z0-9_]){defined\({V1}\)}',exp,i,'r');
      //messageNwait('replace_defined_calls: j='j);
      if (!j) {
         return;
      }
      _str name=substr(exp,pos('S1'),pos('1'));
      int start=pos('S0');
      int len=pos('0');
      int result=isdefined(define_names,name);
      _str leftstr=substr(exp,1,start-1):+result;
      i=length(leftstr)+1;
      exp=leftstr:+substr(exp,start+len);
      //messageNwait('exp='exp);
   }
}

static _str flatten_defines (_str define_names)
{
   //"flatten" out the provided defines.
   _str lval1 = '';
   _str lval2 = '';
   _str rval1 = '';
   _str rval2 = '';
   _str remainder = '';
   _str pairs:[];
   int equalSignPos = 0;
   int spacePos = 0;
   remainder = define_names;

   //process all the assignments
   do {
      equalSignPos = pos("=", remainder);
      if (equalSignPos) {
         lval1 = substr(remainder, 1, equalSignPos-1); //everything on the left
         rval1 = substr(remainder, equalSignPos+1); //everything on the right

         //isolate the variable to define
         lval1 = strip(lval1);
         spacePos = lastpos(" ", lval1);
         if (spacePos) {
            lval2 = substr(lval1, 1, spacePos-1);
            lval1 = substr(lval1, spacePos+1);
         } else {
            lval2 = "";
         }

         //isolate the value
         rval1 = strip(rval1);
         spacePos = pos(" ", rval1);
         if (spacePos) {
            rval2 = substr(rval1, spacePos+1);
            rval1 = substr(rval1, 1, spacePos-1);
         } else {
            rval2 = "";
         }

         remainder = lval2" "rval2;
         pairs:[lval1] = rval1; 
      }
   } while (equalSignPos);

   //process all the definitions without assignments
   do {
      parse remainder with lval1 remainder;
      pairs:[strip(lval1)] = ""; //gcc seems to assign 0 by default.
      remainder = strip(remainder);
   } while (remainder :!= "");

   //resolve assignments 
   boolean makingProgress = true;
   _str i;
   while (makingProgress) {
      makingProgress = false;
      for (i._makeempty();;) {
         pairs._nextel(i);
         if (i._isempty()) {
            break;
         }

         if (pairs._indexin(pairs:[i])) {
            pairs:[i] = pairs:[pairs:[i]];
            if (!pairs._indexin(pairs:[i])) {
               //This definition is not defined by another definition.
               makingProgress = true;
            }
         }
      }
   }

   _str result = "";
   for (i._makeempty();;) {
      pairs._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (pairs:[i] :!= "") {
         result = result:+i"="pairs:[i]" ";
      } else {
         result = result:+i" ";
      }
   }
   return result;
}

#define STATE0       0    /* No if has been processed. */
#define PROCESSCASE  1    /* last case was processed. */
#define SKIPCASE     2    /* last case was skipped. */
#define SKIPREST     4    /* Skip all cases that follow */
#define DIDELSE      16    /* Can have (SKIPREST|DIDELSE) or
                             (PROCESSCASE |DIDELSE)
                          */
/**
 * <p>Preprocesses current buffer based on <i>define_names</i> specified.  
 * Lines of code which have no effect based on the preprocessing are 
 * hidden.  Currently this command only supports C, C++, and Slick-C&reg;.</p>
 * 
 * <p>The syntax for <i>define_names</i> is:</p>
 * 
 * <pre>
 * [+w | -w]  <i>name1</i>[=<i>value1</i>]  
 * <i>name2</i>[=<i>value2</i>] ...
 * </pre>
 * 
 * <p>The -w option indicates that no warning should be given if a define 
 * name does not have a value in a preprocessor expression.  The +w 
 * option currently has no effect.</p>
 * 
 * @example
 * <pre>
 * preprocess  VSWINDOWS=1  WIN32S  UNIX=0
 * </pre>
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see show_all
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command void preprocess(_str define_names="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str warning="%s value not defined or not valid number.  Default value is 0";
   _str warnoption,rest;
   parse define_names with warnoption rest ;
   if (upcase(warnoption)=='+W') {
      define_names=rest;
   } else if (upcase(warnoption)=='-W') {
      define_names=rest;
      warning="";
   }
   if (!_preprocessing_supported()) {
      _message_box("Preprocessing is not supported for this file type");
      return;
   }

   define_names = flatten_defines(define_names);

   isdelphi := _LanguageInheritsFrom("pas");
   _str already_warned_list="";
   save_pos(auto p);
   mou_hour_glass(1);
   show_all();
   top();
   int state=STATE0;
   _str state_stack='';
   _str directive='';
   int status=find_directive(directive,1,isdelphi);
   int start_skip_linenum=0;
   int start_exp_linenum=0;
   int end_exp_linenum=0;
   typeless new_state=0;
   typeless result=0;
   _str exp,name,line;
   for (;;) {
      if (status) {
         break;
      }
      int state_change=1;
      switch (directive) {
      case 'if':     // Not Delphi
      case 'ifdef':
      case 'ifndef':
      case 'ifopt':  // Delphi only
      case 'region':
         state_stack=strip(state' 'state_stack);
         start_exp_linenum=p_line;
         if (directive=='region') start_exp_linenum++;
         //messageNwait('preprocess: start='p_line);
         get_line_cont(exp,isdelphi);
         end_exp_linenum=p_line;
         if (state&(SKIPCASE|SKIPREST)) {
            new_state=SKIPREST;
         } else {
            switch (directive) {
            case 'if':
               result=0;
               replace_defined_calls(define_names,exp);
               status=eval_exp(result,exp,10,define_names,0,warning,already_warned_list);
               break;
            case 'ifdef':
               parse exp with name . ;
               result=isdefined(define_names,name);
               break;
            case 'ifndef':
               parse exp with name . ;
               result=!isdefined(define_names,name);
               break;
            case 'ifopt':
               parse exp with name .;
               if(last_char(name)=='+') {
                  name=strip(name,"T","+");
                  result=isopt(define_names,name);
               } else {
                  name=strip(name,"T","-");
                  result=!isopt(define_names,name);
               }
               break;
            case 'region':
               result=0;
               break;
            }
            new_state=(result)?PROCESSCASE:SKIPCASE;
         }
         break;
      case 'elif':
         start_exp_linenum=p_line;
         get_line_cont(exp,isdelphi);
         end_exp_linenum=p_line;
         switch (state) {
         case SKIPCASE:
            result=0;
            replace_defined_calls(define_names,exp);
            status=eval_exp(result,exp,10,define_names,0,warning,already_warned_list);
            new_state=(result)?PROCESSCASE:SKIPCASE;
            break;
         case PROCESSCASE:
            new_state=SKIPREST;
            break;
         case SKIPREST:
            new_state=SKIPREST;
            break;
         default:
            //Error
            new_state=state;
         }
         break;
      case 'else':
         start_exp_linenum=end_exp_linenum=p_line;
         if (state & DIDELSE) {
            // ERROR
            new_state=state;
         } else {
            switch (state) {
            case SKIPCASE:
               new_state=PROCESSCASE|DIDELSE;
               break;
            case PROCESSCASE:
               new_state=SKIPREST|DIDELSE;
               break;
            case SKIPREST:
               new_state=SKIPREST;
               break;
            default:
               //Error
               new_state=state;
            }
         }
         break;
      case 'endif':
      case 'endregion':
         start_exp_linenum=end_exp_linenum=p_line;
         if (!state) {
            // Error
            new_state=state;
         } else {
            parse state_stack with new_state state_stack;
         }
         break;
      case 'define':
         state_change=0;
         if (!(state & (SKIPCASE|SKIPREST))) {
            get_line_cont(line,isdelphi);
            parse line with name exp;
            if (isinteger(exp) || hex2dec(exp)!="") {
               remove_define(define_names,name);
               define_names=define_names' 'name'='exp;
            } else {
               define_names=define_names' 'name;
            }
            //messageNwait('preprocess: define_names='define_names);
         }
         break;
      case 'undef':
         state_change=0;
         if (!(state & (SKIPCASE|SKIPREST))) {
            get_line_cont(line,isdelphi);
            parse line with name . ;
            remove_define(define_names,name);
            //messageNwait('preprocess: undef='define_names);
         }
         break;
      }
      //messageNwait('state='state' new='new_state' start='start_exp_linenum' end='end_exp_linenum);
      if (state_change) {
         if ((state&(SKIPCASE|SKIPREST)) ) {
            if ((new_state&PROCESSCASE) || new_state==STATE0) {
               _hide_lines2(start_skip_linenum,end_exp_linenum);
            }
         } else {
            // STATE0 or PROCESSCASE
            if (new_state & (SKIPCASE|SKIPREST)) {
               start_skip_linenum=start_exp_linenum;
            } else {
               _hide_lines2(start_exp_linenum,end_exp_linenum);
            }
         }
         state=new_state;
      }
      _end_line();
      status=find_directive(directive,0,isdelphi);
   }
   mou_hour_glass(0);
   restore_pos(p);
}
static _str _get_define_names()
{
   isdelphi := _LanguageInheritsFrom("pas");
   _str already_found_names=" ";
   _str already_found_opt_names=" ";
   save_pos(auto p);
   top();
   mou_hour_glass(1);
   _str define_names="";
   _str directive='';
   int status=find_directive(directive,1,isdelphi);
   int orig_view_id;
   get_window_id(orig_view_id);
   _str exp,name,line,rest;
   typeless result;
   int i,j;
   int last_was_defined=0;
outerloop:
   for (;;) {
      if (status) {
         break;
      }
      int state_change=1;
      save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
      switch (directive) {
      case "region":
         break;
      case "ifdef":
      case "ifndef":
         get_line_cont(exp,isdelphi);
         parse exp with name .;
         if (!pos(" "name" ",already_found_names)) {
            result=_message_box(nls("Define %s?",name),nls("Found #%s %s",directive,name),MB_YESNOCANCEL|MB_ICONQUESTION);
            already_found_names=" "name:+already_found_names;
            if (result==IDYES) {
               define_names=strip(define_names" "name);
            } else if (result==IDNO) {
            } else {
               break outerloop;
            }
         }
         break;
      case "ifopt":
         get_line_cont(exp,isdelphi);
         parse exp with name .;
         parse name with name '[+-]','r';
         if (!pos(" "name" ",already_found_opt_names)) {
            result=_message_box(nls("Is switch '%s' on?",name),nls("Found option #ifopt %s",name),MB_YESNOCANCEL|MB_ICONQUESTION);
            already_found_opt_names=" "name:+already_found_opt_names;
            if (result==IDYES) {
               define_names=strip(define_names" "name"+");
            } else if (result==IDNO) {
            } else {
               break outerloop;
            }
         }
         break;
      case "if":
      case "elif":
         get_line_cont(exp,isdelphi);
         last_was_defined=0;
         word_chars := _clex_identifier_chars();
         for (i=1;;) {
            j=pos("{["word_chars"]#}",exp,i,"r");
            //j=pos("{[A-Za-z_$][A-Za-z0-9_$]@}",exp,i,"r");
            if (!j) {
               break;
            }
            if (isdigit(substr(exp,j,1))) {
               i=j+pos('0');
               continue;
            }
            //messageNwait('exp='exp' name='name);
            name=substr(exp,pos('S0'),pos('0'));
            rest=strip(substr(exp,j+length(name)));
            // Skip defined( or macro(
            //messageNwait('_get_define_names: rest='rest);
            if (substr(rest,1,1)!='(') {
               if (!pos(" "name" ",already_found_names)) {
                  if (last_was_defined) {
                     result=_message_box(nls("Define %s?",name),nls("Found #%s ...defined(%s)...",directive,name),MB_YESNOCANCEL|MB_ICONQUESTION);
                     already_found_names=" "name:+already_found_names;
                     if (result==IDYES) {
                        define_names=strip(define_names" "name);
                     } else if (result==IDNO) {
                     } else {
                        break outerloop;
                     }
                  } else {
                     result = show('-modal _textbox_form',
                                   nls("Found %s in if/elif expression",name),  // Form caption
                                   0, //flags
                                   '',   //use default textbox width
                                   '',   //Help item.
                                   '',   //Buttons and captions
                                   '',   //Retrieve Name
                                   nls("Value for %s",name)":0"
                                  );
                     if (result=='') {
                        break outerloop;
                     }
                     if (!isnumber(_param1)) {
                        _param1=0;
                     }
                     define_names=strip(define_names" "name"="strip(_param1));
                     already_found_names=" "name:+already_found_names;
                  }
                  last_was_defined=0;
               }
            } else if (name=='defined') {
               last_was_defined=1;
            }
            i=j+length(name);
         }
         break;
      case "else":
      case "endif":
      case "endregion":
         break;
      case "define":
         get_line_cont(line,isdelphi);
         break;
      case "undef":
         break;
      }
      restore_search(ss1,ss2,ss3,ss4,ss5);
      _end_line();
      status=find_directive(directive,0,isdelphi);
   }
   activate_window(orig_view_id);
   mou_hour_glass(0);
   restore_pos(p);
   return(define_names);
}

typeless old_search_flags;
_str
   old_search_string
   ,old_word_re
   ,old_replace_string;

/**
 * <p>Searches entire buffer for lines containing the string specified.
 * Lines not containing the search string are hidden.  If a tilde (~)
 * is given in the command line syntax, then lines containing the search
 * string are hidden like the allnot command.  See find command for
 * information on options argument.</p>
 * 
 * <p>Alternate command line syntax:  <b>all [~]/string[/options]</b></p>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @see hide_all_comments
 * @see hide_selection
 * @see hide_code_block
 * @see show_all
 * @see preprocess
 * @see allnot
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @categories Search_Functions, Selective_Display
 */
_command void all(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   dolessnot := false;
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   old_search_flags = (old_search_flags &~(WRAP_SEARCH|POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH|NO_MESSAGE_SEARCH));
   _str new_search_options='';
   if ( arg()>1 ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      old_search_string=arg(1);
      new_search_options=arg(2);
      dolessnot=(arg(3)!='');
   } else if ( arg(1)=='' || arg(1)=='/' ) {
      old_search_string=prompt('',nls('All Search For'));
      new_search_options=prompt('',nls('All Options'));
   } else {
      boolean donot=0;
      _str arg1=arg(1);
      if (substr(arg1,1,1)=='~') {
         donot=1;
         arg1=substr(arg1,2);
      }
      _str delim;
      _str search_flags;
      parse arg1 with  1 delim +1 old_search_string (delim) new_search_options ;
      if (donot) {
         _macro('m',recording_macro);
         _macro_delete_line();
         _macro_call('allnot',old_search_string,new_search_options);
         allnot(old_search_string,new_search_options);
         return;
      }
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('all',old_search_string,new_search_options);

   _mffindNoMore(1);
   _mfrefNoMore(1);

   int status=0;
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;
   dohide_all:=true;

   // Fetch the search flags.
   search('','h@'new_search_options);
   save_search('',old_search_flags,old_word_re);
   _menu_add_searchhist(old_search_string,new_search_options);

   typeless junk;
   save_pos(auto p);

   top();
   save_pos(auto dohide_start_pos);
   if (!_default_option('t')) {
      // IF there are 0 or 1 lines in this file.
      if (_on_line0() || down()) {
         restore_pos(p);
         set_find_next_msg("Find", old_search_string, new_search_options);
         return;
      }
      top();
   }
   mou_hour_glass(1);
   if (dolessnot) {
      status=search(old_search_string,'@'new_search_options);
   } else {
      status=search(old_search_string,'h@'new_search_options);
   }
   if (status) {
      _beep();
      message(get_message(STRING_NOT_FOUND_RC));
   }
   for (;;) {
      if (status) bottom();
      if (dohide_all) {
         long stopOffset=_QROffset();
         save_pos(auto p2);
         restore_pos(dohide_start_pos);
         if (_default_option('t')) {
            up();
            _lineflags(NEXTLEVEL_LF,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
         }
         for (;;) {
            if ( down()) break;
            if (dolessnot && _QROffset() >= stopOffset) break;
            _lineflags(HIDDEN_LF|NEXTLEVEL_LF,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
         }
         restore_pos(p2);
         dohide_all=dolessnot;
      }
      if (status) break;
      up();
      if (!(_lineflags()&HIDDEN_LF)) {
         _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      }
      down();
      if (down()) {
         _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         break;
      }
      if (_lineflags() & HIDDEN_LF) {
         up();
         _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      } else {
         up();
      }
      save_pos(dohide_start_pos);
      status=repeat_search();
   }

   maybe_plus_first_line();
   mou_hour_glass(0);

   set_find_next_msg("Find", old_search_string, new_search_options);
   restore_pos(p);
   //return(status)
}
/*
   This command currently only perfectly supports selective display created
   by the all, allnot, less commands.
*/
_command void more(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   old_search_flags = (old_search_flags &~(WRAP_SEARCH|POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH|NO_MESSAGE_SEARCH));
   _str new_search_options='';
   if ( arg()>1 ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      old_search_string=arg(1);new_search_options=arg(2);
   } else if ( arg(1)=='' || arg(1)=='/' ) {
      old_search_string=prompt('',nls('All Search For'));
      new_search_options=prompt('',nls('All Options'));
   } else {
      _str arg1=arg(1);
      _str delim;
      _str search_flags;
      parse arg1 with  1 delim +1 old_search_string (delim) new_search_options;
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('more',old_search_string,new_search_options);

   int status=0;
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;


   search('','h@'new_search_options);
   save_search('',old_search_flags,old_word_re);
   _menu_add_searchhist(old_search_string,new_search_options);

   typeless junk;
   save_pos(auto p);

   top();
   if (!_default_option('t')) {
      // IF there are 0 or 1 lines in this file.
      if (_on_line0() || down()) {
         restore_pos(p);
         set_find_next_msg("Find", old_search_string, new_search_options);
         return;
      }
      _begin_line();
   }
   mou_hour_glass(1);
   status=search(old_search_string,'h@'new_search_options);
   for (;;) {
      if (status) break;
      int lf=_lineflags();
      if ((lf&HIDDEN_LF) &&
          !(lf & (PLUSBITMAP_LF|MINUSBITMAP_LF)) /*&& !(lf&LEVEL_LF)*/) {
         // Make sure the line below is at the same level
         if(down()) {
            _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
            break;
         }
         int lf2=_lineflags();
         if ((lf2 & (HIDDEN_LF|PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF))==
             (lf & (HIDDEN_LF|PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF))
            ) {
            up();
            int level=(lf &LEVEL_LF)-NEXTLEVEL_LF;
            if (level<0) level=0;
            _lineflags(PLUSBITMAP_LF|level,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         } else {
            up();
            _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         }
         up();
         if (_lineflags() & (PLUSBITMAP_LF|MINUSBITMAP_LF)) {
            _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         }
         down();
      }
      _end_line();
      status=repeat_search();
   }

   maybe_plus_first_line();
   mou_hour_glass(0);

   set_find_next_msg("Find", old_search_string, new_search_options);
   restore_pos(p);
   //return(status)
}
_command void lessnot(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   _str search_options='';
   _str new_search_options;
   _str new_search_string;
   if ( arg()>1 ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      new_search_string=arg(1);
      new_search_options=arg(2);
   } else if ( arg(1)=='' || arg(1)=='/' ) {
      new_search_string=prompt('',nls('All Search For'));
      new_search_options=prompt('',nls('All Options'));
   } else {
      _str delim;
      parse arg(1) with  1 delim +1 new_search_string (delim) new_search_options;
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('lessnot',new_search_string,new_search_options);
   _macro('m',0);
   all(new_search_string,new_search_options,1);
}
/*
   This command currently only perfectly supports selective display created
   by the all, allnot, less commands.
*/
_command void less(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   _str search_options='';
   boolean less=0;
   _str new_search_options;
   _str new_search_string;
   if ( arg()>1 ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      new_search_string=arg(1);
      new_search_options=arg(2);
      less=(arg(3)!="");
   } else if ( arg(1)=='' || arg(1)=='/' ) {
      new_search_string=prompt('',nls('All Search For'));
      new_search_options=prompt('',nls('All Options'));
   } else {
      _str delim;
      parse arg(1) with  1 delim +1 new_search_string (delim) new_search_options;
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('less',new_search_string,new_search_options);
   _macro('m',0);
   allnot(new_search_string,new_search_options,1);
}
/**
 * <p>Hides lines containing the search string specified.  The entire buffer is
 * processed.  See find command for information on options argument.</p>
 * 
 * <p>Alternate command line syntax:  <b>allnot /<i>string</i>[/<i>options</i>]</b></p>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @see hide_all_comments
 * @see hide_selection
 * @see hide_code_block
 * @see show_all
 * @see preprocess
 * @see all
 * @see show_procs
 * @see show_col1
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @categories Search_Functions, Selective_Display
 */
_command void allnot(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   //old_search_flags= (old_search_flags &~(WRAP_SEARCH|POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH|NO_MESSAGE_SEARCH));
   boolean doless=false;
   _str search_options='';
   if ( arg()>1 ) {
      // Default search options for case and re etc. not used when
      // this function is called with two arguments. This is so that
      // user defined keyboard macros work correctly when default
      // search options are changed.
      old_search_string=arg(1);
      search_options=arg(2);
      doless=(arg(3)!="");
   } else if ( arg(1)=='' || arg(1)=='/' ) {
      old_search_string=prompt('',nls('All Search For'));
      search_options=prompt('',nls('All Options'));
   } else {
      _str delim;
      parse arg(1) with  1 delim +1 old_search_string (delim) search_options;
      search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE)):+search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('allnot',old_search_string,search_options);

   _mffindNoMore(1);
   _mfrefNoMore(1);

   save_pos(auto p);

   top();
   mou_hour_glass(1);
   if (!doless) {
      show_all();
   }
   int status=search(old_search_string,'h@'search_options);
   int new_level=0;
   for (;;) {
      if (status) break;
      up();
      if (!(_lineflags()&HIDDEN_LF)) {
         new_level=(_lineflags() & LEVEL_LF)+NEXTLEVEL_LF;
         _lineflags(PLUSBITMAP_LF|(new_level-NEXTLEVEL_LF),PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         down();
      } else {
         new_level=(_lineflags() & LEVEL_LF);
         down();
      }
      _lineflags(HIDDEN_LF|new_level,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      _end_line();
      status=repeat_search();
   }

   //maybe_plus_first_line();
   mou_hour_glass(0);

   typeless junk;
   search('','@'search_options); // unset hidden flags
   save_search(junk,old_search_flags,old_word_re);
   _menu_add_searchhist(old_search_string,search_options);
   set_find_next_msg("Find", old_search_string, search_options);
   restore_pos(p);
   //return(status)
}

void e_find_lastprocparam()
{
   c_find_lastprocparam();
   return;
}
void c_find_lastprocparam()
{
   int orig_line=p_line;
   // Find open paren
   int status=search('(','h@');
   //reset_all();
   //stop();
   int cfg;
   for (;;) {
      if (status) {
         p_line=orig_line;
         return;
      }
      cfg=_clex_find(0,'g');
      if (cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
         break;
      }
      status=repeat_search();
   }
   // Search for close paren
   right();
   int nesting=1;
   status=search('[()]','rh@');
   for (;;) {
      if (status) {
         p_line=orig_line;
         return;
      }
      cfg=_clex_find(0,'g');
      if (cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
         switch (get_text()) {
         case ")":
            --nesting;
            if (!nesting) return;
            break;
         case "(":
            ++nesting;
         }
      }
      status=repeat_search();
   }
}

/**
 * Hides all procedures and comment blocks. 
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_col1
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */
_command hide_comments_and_code_blocks(_str seldisp_flags="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING)
{
   show_procs(seldisp_flags);
   hide_all_comments();
}

/**
 * Hides lines in the current buffer which are not part of a function 
 * definition heading.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_col1
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command show_procs(_str seldisp_flags="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING)
{
   if (seldisp_flags=="") {
      seldisp_flags=def_seldisp_flags;
   }
   if (! _istagging_supported()) {
      _message_box('Function scanning not supported for files of this extension.  Make sure support module is loaded.');
      return('');   //No support for this extension
   }
   find_lastprocparam_index := _FindLanguageCallbackIndex('%s_find_lastprocparam');
   if (!find_lastprocparam_index) find_lastprocparam_index=0;

   // get the line numbers from the context info
   mou_hour_glass(1);
   _UpdateContext(true);
   //say("show_procs");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   save_pos(auto p);
   top();up();
   int old_lastparam_linenum=p_line;
   if (!_default_option('t')) ++old_lastparam_linenum;
   boolean done_status=false;
   int num_context_tags = tag_get_num_of_context();
   _str tag_type='';
   int linenum=0;
   int done_hidden_linenum=0;
   int next_linenum=0;
   int end_comment_line=0;
   int start_comment_line=0;
   int i;
   for (i=1; !done_status; i++) {
      // only do this for functions
      tag_get_detail2(VS_TAGDETAIL_context_type, i, tag_type);
      if (i > num_context_tags) {
         linenum=p_Noflines;
         done_status=true;
         bottom(); down();
         done_hidden_linenum=p_Noflines;
      } else if (!tag_tree_type_is_func(tag_type)) {
         continue;
      } else {
         tag_get_detail2(VS_TAGDETAIL_context_line, i, linenum);
         p_RLine=linenum;p_col=1;

         //messageNwait("show_procs: h1");
         next_linenum=p_line;
         done_hidden_linenum=next_linenum-1;
         if (((int)seldisp_flags) & (SELDISP_COLLAPSEPROCCOMMENTS|SELDISP_SHOWPROCCOMMENTS)) {
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            int old_col=p_col;
            /*
               Process comments separately from function
            */
            up();
            end_comment_line=p_line;
            _end_line();
            // Look for a non-blank character
            int status=search("[^ \t]","@-rh");
            //messageNwait("show_procs: status="status" p_line="p_line);
            // If we found a non-blank character and
            //    it is comment text
            if (!status && _clex_find(0,'g')==CFG_COMMENT) {
               //messageNwait("show_procs: h2");
               // Skip blank lines and comments
               if (_clex_skip_blanks("h-")) {
                  // There is at least one line of comments
                  // We hit top of file.
                  top();up();
               }
               down();start_comment_line=p_line;
               // If we did skip any comments
               if (p_line<end_comment_line-1) {
                  //messageNwait("show_procs: h3");
                  _begin_line();
                  // Now skip over blank lines to find start of comments
                  status=search("^~([ \t]*$)","r@h");
                  if (!status && p_line<end_comment_line) {
                     start_comment_line=p_line;
                  }
               }
               if (start_comment_line<=end_comment_line) {
                  if (start_comment_line==end_comment_line) {
                     _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                  } else {
                     //messageNwait("show_procs: start="start_comment_line" end="end_comment_line);
                     p_line=start_comment_line;
                     if ((((int)seldisp_flags) & SELDISP_COLLAPSEPROCCOMMENTS)) {
                        _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                        down();
                        for (;p_line<=end_comment_line;) {
                           _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                           if (down()) break;
                        }
                     } else {
                        _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                        down();
                        for (;p_line<=end_comment_line;) {
                           _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                           if (down()) break;
                        }
                     }
                  }
               }
               done_hidden_linenum=start_comment_line-1;
            }
            p_col=old_col;
            restore_search(s1,s2,s3,s4,s5);
         }
      }
      if (old_lastparam_linenum<done_hidden_linenum) {
         //_hide_lines(old_lastparam_linenum,done_hidden_linenum);
         p_line=old_lastparam_linenum;
         _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
         down();
         for (;p_line<=done_hidden_linenum;) {
            _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
            if (down()) break;
         }
      }
      if (done_status) {
         break;
      }
      p_line=next_linenum;
      //messageNwait("show_procs: next_linenum="next_linenum);
      if (find_lastprocparam_index) {
         //message('p_line='p_line);  //delay(100);clear_message();
         save_search(auto a,auto b,auto c,auto d);
         call_index(find_lastprocparam_index);
         restore_search(a,b,c,d);
      }
      old_lastparam_linenum=p_line;
   }

   mou_hour_glass(0);
   //maybe_plus_first_line();
   clear_message();
   restore_pos(p);
}
static void maybe_plus_first_line()
{
   top();
   if (_default_option('t')) up();
   int status=down();
   if (status) return;
   if (_lineflags() & HIDDEN_LF) {
      up();
      _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
   }
}
/**
 * Hides lines in the current buffer which do not contain a non-blank 
 * (space or tab) character in column one.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command show_col1() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   all('^[~ \t]','r');
}

   _nocheck _control ctlLimit;

#define UserSelDispParent   ctlok.p_user
defeventtab _SelDispControls_form;

ctlscan.on_create()
{
   // align up the button with the textbox - it is auto-sized
   rightAlign := ctlremenu.p_parent.p_width - ctlsearchstring.p_x;
   sizeBrowseButtonToTextBox(ctlsearchstring.p_window_id, ctlremenu.p_window_id, 0, rightAlign);
}

ctlscan.lbutton_up()
{
   _nocheck _control ctlok;
   _macro('m',_macro('s'));
   _macro_append('define_names=_get_define_names();');
   ctldefines.p_text=UserSelDispParent._get_define_names();
   ctldefines._set_sel(1);
   ctldefines._set_focus();
}
void ctlCheckLimit.lbutton_up()
{
   ctlLimit.p_enabled=(p_value!=0);
   ctlLimit.p_next.p_enabled=(p_value!=0);
}
void ctlshowcomments.lbutton_up()
{
   if (p_window_id==ctlshowcomments) {
      if (ctlcollapsecomments.p_value) {
         ctlcollapsecomments.p_value=0;
      }
      return;
   }
   if (ctlshowcomments.p_value && ctlcollapsecomments.p_value) {
      ctlshowcomments.p_value=0;
   }
}
void ctlre.lbutton_up()
{
   ctlre_type.p_enabled = ctlremenu.p_enabled = ctlre.p_value ? true : false;
}

static void _FormGetMessage2(_str ControlName)
{
   _nocheck _control ctlhelplabel;
   _str string=_FormGetMessage('_SelDispControls_form',ControlName);
   ctlhelplabel.p_caption=ctlhelplabel.p_user:+"\r\r"string;
}
static _str _FormGetMessage(_str FormName,_str ControlName)
{
   int index=find_index(FormName,oi2type(OI_FORM));

   int child=index.p_child;
   int firstchild=child;
   if (child) {
      for (;;) {
         if (child.p_name==ControlName){
            return(child.p_message);
         }
         child=child.p_next;
         if (child==firstchild) break;
      }
   }
   return("");
}
_nocheck _control ctlre,ctlmatchcase,ctlwarning;
_nocheck _control ctlcollapsecomments,ctlshowcomments;
_nocheck _control ctldefines,ctlsearchstring,ctlmatchword;
_nocheck _control ctlShowAllMatchedLines,ctlHideAllMatchedLines;
_nocheck _control ctlShowMoreMatchedLines,ctlHideMoreMatchedLines;
_nocheck _control ctlHideMoreUnMatchedLines;
_nocheck _control ctlre_type, ctlremenu;
defeventtab _seldisp_form;
ctlok.on_create(_str options="")
{
   _str option;
   for (;;) {
      parse options with option options;
      if (option=='') {
         break;
      }
      if (lowcase(option)=='-df') {
         ctlshowprocs.p_enabled=false;
      }
   }
   _macro('m',_macro('s'));
   _macro_delete_line();
   UserSelDispParent=_form_parent();
   ctlhelplabel.p_user=ctlhelplabel.p_caption;
   // Load child pictures
   int index=find_index('_SelDispControls_form',oi2type(OI_FORM));
   int child=index.p_child;
   int firstchild=child;
   if (child) {
      for (;;) {
         if (child.p_object!=OI_IMAGE) {
            //form_wid=_load_template(index, _mdi, 'HA', 1);
            // Center the form to the MDI window while the form is invisible
            int form_wid=_load_template(child,_control ctlsettings,'H');
            form_wid._center_window();
            form_wid.p_y+=60;
         }
         child=child.p_next;
         if (child==firstchild) break;
      }
   }
   // This removes duplicates.  However, if we delete lines
   // below, there may be a duplicate because the lines are
   // not adjacent.
   ctldefines._retrieve_list();
   ctlsearchstring._retrieve_list();
   // Remove blank lines from ctldefines combo box list.
   p_window_id=ctldefines;
   int Nofhits=0;_lbtop();
   for (;;) {
      typeless status=_lbsearch("");
      if (status) {
         if (!Nofhits) {
            break;
         }
         _lbtop();Nofhits=0;
         break;
      } else {
         _lbdelete_item();
         ++Nofhits;
      }
   }

   p_window_id=ctlok;
   if (def_seldisp_flags&SELDISP_SHOWPROCCOMMENTS) {
      ctlshowcomments.p_value=1;
   } else if (def_seldisp_flags&SELDISP_COLLAPSEPROCCOMMENTS) {
      ctlcollapsecomments.p_value=1;
   }
   _retrieve_prev_form();
   if (ctlpreprocess.p_value) {
      if (!UserSelDispParent._preprocessing_supported()) {
         ctlsearch.p_value=1;
      }
   }

   ctlHideSelection.p_enabled=(UserSelDispParent.select_active2());
   if (!ctlHideSelection.p_enabled && ctlHideSelection.p_value) {
      ctlsearch.p_value=1;
   }
   if (!UserSelDispParent._preprocessing_supported()) {
      ctlpreprocess.p_enabled=0;
   }

   ctlre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   ctlre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   ctlre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   ctlre_type._lbadd_item(RE_TYPE_PERL_STRING);
   ctlre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
   if (ctlsearchstring.p_text:=='') {
      int flags=_default_option('s');
      ctlmatchcase.p_value= (int)!(flags & VSSEARCHFLAG_IGNORECASE);
      ctlmatchword.p_value=flags & VSSEARCHFLAG_WORD;
      ctlre.p_value = flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE);
      if (ctlre.p_value) {
         ctlre_type._init_re_type(flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE));
      } else {
         if (def_re_search == VSSEARCHFLAG_BRIEFRE) {
            ctlre_type.p_text = RE_TYPE_BRIEF_STRING;
         } else if (def_re_search == VSSEARCHFLAG_RE) {
            ctlre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
         } else if (def_re_search == VSSEARCHFLAG_WILDCARDRE) {
            ctlre_type.p_text = RE_TYPE_WILDCARD_STRING;
         } else if (def_re_search == VSSEARCHFLAG_PERLRE) {
            ctlre_type.p_text = RE_TYPE_PERL_STRING;
         } else {
            ctlre_type.p_text = RE_TYPE_UNIX_STRING;
         }
      }
   }
   ctlre_type.p_enabled = ctlremenu.p_enabled = ctlre.p_value ? true : false;
   if (ctlLimit.p_text=="") {
      ctlLimit.p_text=def_seldisp_maxlevel;
   }
   if (def_seldisp_flags & SELDISP_EXPANDSUBLEVELS) {
      ctlExpandSubLevels.p_value=1;
   } else if (def_seldisp_flags & SELDISP_COLLAPSESUBLEVELS) {
      ctlCollapseSubLevels.p_value=1;
   } else {
      ctlRememberSubLevels.p_value=1;
   }
}
_seldisp_form.on_load()
{
   ctlsearch.call_event(ctlsearch,LBUTTON_UP);
}
ctlok.lbutton_up()
{
   _macro('m',_macro('s'));
   if (ctlpreprocess.p_value && ctldefines.p_text!='') {
      _append_retrieve(ctldefines,ctldefines.p_text);
   }
   _str search_options='';
   if (ctlsearch.p_value) {
      if (ctlmatchcase.p_value) {
         search_options= '';
      } else {
         search_options='I';
      }
      if (ctlmatchword.p_value) {
         search_options=search_options'W';
      }
      if (ctlre.p_value) {
         switch (ctlre_type.p_text) {
         case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
         case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
         case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
         case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
         case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
         }
      }
      if (ctlsearchstring.p_text:!='') {
         if (ctlShowAllMatchedLines.p_value) {
            // resetting show/hide for entire document
            _macro_call('all',ctlsearchstring.p_text,search_options);
            UserSelDispParent.all(ctlsearchstring.p_text,search_options);
         } else if (ctlHideAllMatchedLines.p_value) {
            // resetting show/hide for entire document
            _macro_call('allnot',ctlsearchstring.p_text,search_options);
            UserSelDispParent.allnot(ctlsearchstring.p_text,search_options);
         } else if (ctlHideMoreMatchedLines.p_value) {
            // user is asking to hide additional lines
            _macro_call('less',ctlsearchstring.p_text,search_options);
            UserSelDispParent.less(ctlsearchstring.p_text,search_options);
         } else if (ctlHideMoreUnMatchedLines.p_value) {
            // user is asking to hide additional lines
            _macro_call('lessnot',ctlsearchstring.p_text,search_options);
            UserSelDispParent.lessnot(ctlsearchstring.p_text,search_options);
         } else if (ctlShowMoreMatchedLines.p_value) {
            // user is asking to show additional lines
            _macro_call('more',ctlsearchstring.p_text,search_options);
            UserSelDispParent.more(ctlsearchstring.p_text,search_options);
         }
         _append_retrieve(ctlsearchstring,ctlsearchstring.p_text);
      }
   /*} else if (ctlshowcol1.p_value) {
      _macro_call('show_col1');
      UserSelDispParent.show_col1();*/
   } else if (ctlshowprocs.p_value) {
      int flags=get_seldisp_flags();
      _macro_call('show_procs',flags);
      UserSelDispParent.show_procs(flags);
   } else if (ctlpreprocess.p_value) {
      _str warning="";
      if (!ctlwarning.p_value) {
         warning="-W ";
      }
      _macro_call('preprocess',warning:+ctldefines.p_text);
      UserSelDispParent.preprocess(warning:+ctldefines.p_text);
   } else if (ctlHideSelection.p_value) {
      _macro_call('hide_selection');
      UserSelDispParent.hide_selection();
   } else if (ctlMultiLevel.p_value) {
      _nocheck _control ctlbraces,ctlLimit;
      _str limitlevels="";
      if (ctlLimit.p_enabled) {
         limitlevels=ctlLimit.p_text;
      }
      if (ctlbraces.p_value) {
         if (limitlevels!="") {
            _macro_call('show_braces',limitlevels);
         } else {
            _macro_call('show_braces');
         }
         UserSelDispParent.show_braces(limitlevels);
      } else {
         if (limitlevels!="") {
            _macro_call('show_indent',limitlevels);
         } else {
            _macro_call('show_indent');
         }
         UserSelDispParent.show_indent(limitlevels);
      }
   } else if (ctlParagraphs.p_value) {
      _macro_call('show_paragraphs');
      UserSelDispParent.show_paragraphs();
   }
   _save_form_response();

   _str new_flag_str;
   int new_flag;
   int cur_flag=def_seldisp_flags & (SELDISP_EXPANDSUBLEVELS|SELDISP_COLLAPSESUBLEVELS);
   if (ctlExpandSubLevels.p_value) {
      new_flag_str="SELDISP_EXPANDSUBLEVELS";
      new_flag=SELDISP_EXPANDSUBLEVELS;
      ctlExpandSubLevels.p_value=1;
   } else if (ctlCollapseSubLevels.p_value) {
      new_flag_str="SELDISP_COLLAPSESUBLEVELS";
      new_flag=SELDISP_COLLAPSESUBLEVELS;
   } else {
      new_flag=0;
      ctlRememberSubLevels.p_value=1;
   }
   if (cur_flag!=new_flag) {
      _macro_append('def_seldisp_flags&=~(SELDISP_EXPANDSUBLEVELS|SELDISP_COLLAPSESUBLEVELS);');
      _macro_append('def_seldisp_flags|='new_flag_str';');
      def_seldisp_flags&=~(SELDISP_EXPANDSUBLEVELS|SELDISP_COLLAPSESUBLEVELS);
      def_seldisp_flags|=new_flag;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   p_active_form._delete_window(0);


}
ctlsearch.lbutton_up()
{
   _nocheck _control ctlMultiLevelPic,ctlPreprocessPic,ctlFunctionPic,ctlSearchPic;
   _nocheck _control ctlNoSettings;
   int hit_one=0;
   ctlSearchPic.p_visible=(ctlsearch.p_value!=0);
   if (ctlsearch.p_value) {
      _FormGetMessage2("ctlSearchMsg");
      ctlsearch._set_focus();
      hit_one=1;
   }
   ctlFunctionPic.p_visible=(ctlshowprocs.p_value!=0);
   if (ctlshowprocs.p_value) {
      ctlshowprocs._set_focus();
      _FormGetMessage2("ctlFunctionMsg");
      hit_one=2;
   }
   ctlPreprocessPic.p_visible=(ctlpreprocess.p_value!=0);
   if (ctlpreprocess.p_value) {
      _FormGetMessage2("ctlDefineMsg");
      ctlpreprocess._set_focus();
      hit_one=3;
   }
   ctlMultiLevelPic.p_visible=(ctlMultiLevel.p_value!=0);
   if (ctlMultiLevel.p_value) {
      ctlMultiLevel._set_focus();
      _FormGetMessage2("ctlMultiLevelMsg");
      hit_one=4;
   }
   ctlNoSettings.p_visible=hit_one==0;
   if (ctlParagraphs.p_value) {
      ctlParagraphs._set_focus();
      _FormGetMessage2("ctlParagraphsMsg");
   }
   if (ctlHideSelection.p_value) {
      ctlHideSelection._set_focus();
      _FormGetMessage2("ctlHideSelectionMsg");
   }
#if 0
   if (ctlsearch.p_value) {
      value=1;
   } else {
      value=0;
   }
   ctlResetSelDisp.p_enabled=ctlmatchcase.p_enabled=ctlmatchword.p_enabled=
                          ctlre.p_enabled=ctlsearchstring.p_enabled=value;
   if (ctlpreprocess.p_value) {
      ctlscan.p_enabled=ctldefines.p_prev.p_enabled=ctldefines.p_enabled=ctlwarning.p_enabled=1;
   } else {
      ctlscan.p_enabled=ctldefines.p_prev.p_enabled=ctldefines.p_enabled=ctlwarning.p_enabled=0;
   }
   ctlsavesettings.p_enabled=ctlshowcomments.p_enabled=ctlcollapsecomments.p_enabled=ctlshowprocs.p_value!=0;
#endif
}
#if 0
ctlsavesettings.lbutton_up()
{
   def_seldisp_flags=get_seldisp_flags();
   _config_modify_flags(CFGMODIFY_DEFVAR);
   save_config();
   _macro('m',_macro('s'));
   _macro_append("_config_modify_flags(CFGMODIFY_DEFVAR);");
   _macro_append("def_seldisp_flags="def_seldisp_flags";");
}
#endif
static int get_seldisp_flags()
{
   if (ctlshowcomments.p_value) {
      return(SELDISP_SHOWPROCCOMMENTS);
   } else if (ctlcollapsecomments.p_value) {
      return(SELDISP_COLLAPSEPROCCOMMENTS);
   }
   return(0);
}

struct LEVELINFO {
   int OpenBraceLineNum;
   int PrevLevel;
};
void _ShowLevels(int (*pfnFind)(int firstfirst,boolean &FoundStart),int maxlevel)
{
   save_pos(auto p);
   //mou_hour_glass(1);
   //show_all();
   _str options="";
   if (p_lexer_name!="") {
      options="xcs";  // Exclude comments and strings
   }
   top();
   int level=0;
   int LastLineSameLevel=0;
   LEVELINFO stack[];
   int findfirst=1;
   maxlevel=_Index2Level(maxlevel);
   boolean FoundStart=false;
   int CloseBraceLineNum=0;
   int OpenBraceLineNum=0;
   for (;;) {
      //status=search('\{|\}','h@r'options);
      int status=(*pfnFind)(findfirst,FoundStart);
      if (!status && FoundStart) {
         //messageNwait("show_braces: { stlen="stack._length());
         OpenBraceLineNum=p_line;
         p_line=LastLineSameLevel;
         int hidden_lf=0;
         if (stack._length()) {
            hidden_lf=HIDDEN_LF;
         }
         for (;p_line<=OpenBraceLineNum;) {
            _lineflags(hidden_lf|level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
            if(down())break;
         }
         p_line=OpenBraceLineNum;
         hidden_lf=HIDDEN_LF;
         LEVELINFO *plevelinfo;
         plevelinfo=&stack[stack._length()];
         plevelinfo->OpenBraceLineNum=OpenBraceLineNum;
         plevelinfo->PrevLevel=level;
         if (OpenBraceLineNum>=LastLineSameLevel && level<maxlevel) {
            level+=NEXTLEVEL_LF;
         }
         LastLineSameLevel=OpenBraceLineNum+1;

      } else {
         // IF there is a previous level
         if (stack._length()) {
            //messageNwait("show_braces: } l="p_line"status="status);
            if (status) {
               CloseBraceLineNum=p_Noflines+1;
               if (LastLineSameLevel>p_Noflines) {
                  CloseBraceLineNum=p_line;
               } else {
                  p_line=LastLineSameLevel;
               }
            } else {
               CloseBraceLineNum=p_line;
               p_line=LastLineSameLevel;
            }
            for (;p_line<CloseBraceLineNum;) {
               //messageNwait('level='level' l='p_line);
               _lineflags(HIDDEN_LF|level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               if(down()) break;
            }
            p_line=CloseBraceLineNum;
            // End the previous level
            while ((stack._length() && status) || !status) {
               int hidden_lf=HIDDEN_LF;
               if (stack._length()<=1) {
                  hidden_lf=0;
               }
               LEVELINFO levelinfo;
               levelinfo=stack[stack._length()-1];
               stack._deleteel(stack._length()-1);
               // IF level number changed for this brace pair AND
               //    there is at least one line inside these braces
               if (levelinfo.PrevLevel!=level &&
                   levelinfo.OpenBraceLineNum+1<CloseBraceLineNum) {
                  int orig_line=p_line;
                  p_line=levelinfo.OpenBraceLineNum;
                  //messageNwait('open level='levelinfo.PrevLevel' l='p_line);
                  _lineflags(PLUSBITMAP_LF|hidden_lf|levelinfo.PrevLevel,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
                  p_line=orig_line;
               }
               level=levelinfo.PrevLevel;
               if (CloseBraceLineNum>LastLineSameLevel) {
                  LastLineSameLevel=CloseBraceLineNum;
               }
               if (!status) {
                  break;
               }
            }
            if (status) {
               break;
            }
         }
         if (status) {
            p_line=LastLineSameLevel;
            for (;;) {
               //messageNwait('close level='level' l='p_line);
               _lineflags(level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               if(down()) break;
            }
            break;
         }
      }
      findfirst=0;
   }

   //mou_hour_glass(0);
   //maybe_plus_first_line();
   p_line=0;
   int pm= _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF);
   if (pm==PLUSBITMAP_LF) {
      plusminus();
      //if (!_default_option('t')) {
      //   _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF);
      //}
   }

   restore_pos(p);
}
static _str gFindOptions;
static int _FindBraces(int findfirst,boolean &FoundStart)
{
   if (findfirst) {
      gFindOptions="";
      if (p_lexer_name!="") {
         gFindOptions="xcs";  // Exclude comments and strings
      }
   } else {
      right();
   }
   int status=search('\{|\}','h@r'gFindOptions);
   FoundStart=get_text()=='{';
   return(status);
}
/**
 * Creates nested selective display based on the braces {}. 
 *
 * @param maxNestLevel  optionally specifies the limit on the nesting.
 *                      Must be at least one.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_col1
 * @see show_indent
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command show_braces(_str maxNestLevel="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   _ShowLevels(_FindBraces,(int) maxNestLevel);
}
static int gstate;
static int gNewIndent;
static int gStackIndent[];

static int GetNextIndent()
{
   int orig_line=p_line;
   if (p_line!=1 /*|| _default_option('t')*/) {
      if(down()) {
         return(0);
      }
   }
   // Skip blank lines
   _str line='';
   for (;;) {
      get_line(line);
      if (line!="") {
         break;
      }
      if(down()) return(0);
   }
   int i=verify(line," \t");
   // Remember first non-blank column
   int Indent=_text_colc(i,'I');
   p_line=orig_line;
   return(Indent);
}
static int _FindIndent(int findfirst,boolean &FoundStart)
{
   if (findfirst) {
      gStackIndent._makeempty();
      /*if (!_default_option('t')) {
         p_line=1;p_col=1;
      } else {*/
         p_line=0;p_col=1;
      //}
      gStackIndent[0]=GetNextIndent();
      FoundStart=true;
      gstate=0;
      return(0);
   }
   int TopIndent=0;
   if (gstate==1) {
      if (gStackIndent._length()<=0) {
         gStackIndent[0]=GetNextIndent();
         FoundStart=true;
      } else {
         TopIndent=gStackIndent[gStackIndent._length()-1];
         if (gNewIndent<TopIndent) {
            gStackIndent._deleteel(gStackIndent._length()-1);
            FoundStart=false;
            //messageNwait("_FindIndent: close l="p_line);
            return(0);
         }
         if (gNewIndent>TopIndent) {
            //messageNwait("st=1 _FindIndent: open l="p_line" g="gNewIndent" t="TopIndent);
            FoundStart=true;
            gstate=2;
            //messageNwait("_FindIndent: got here");
            gStackIndent[gStackIndent._length()]=gNewIndent;
            return(0);
         }
      }
   }
   if (!gstate && (1 /*p_line!=1 || _default_option('t')*/)) {
      if(down()) {
         return(1);
      }
   }
   // Skip blank lines
   _str line='';
   for (;;) {
      get_line(line);
      if (line!="") {
         break;
      }
      if(down()) return(1);
   }
   int i=verify(line," \t");
   // Remember first non-blank column
   gNewIndent=_text_colc(i,'I');

   TopIndent=gStackIndent[gStackIndent._length()-1];
   //messageNwait("_FindIndent: gNewIndent="gNewIndent" TopIndent="TopIndent);
   if (gNewIndent<TopIndent) {
      up();
      //messageNwait("_FindIndent: state=1");
      gstate=1;
      return(_FindIndent(0,FoundStart));
   }
   int NextIndent=0;
   for (;;) {
      // Skip lines with the same indent
      get_line(line);
      if (line=="") {
         if(down()) {
            return(1);
         }
         continue;
      }
      i=verify(line," \t");
      NextIndent=_text_colc(i,'I');
      if (gNewIndent!=NextIndent) {
         /*if (!gStackIndent._length()) {
            messageNwait('got here');
         } */
         if (NextIndent>gNewIndent /*|| !gStackIndent._length()*/) {
            up();
            FoundStart=true;
            gstate=0;
            gStackIndent[gStackIndent._length()]=NextIndent;
            //messageNwait("_FindIndent: open l="p_line" g="gNewIndent" t="TopIndent);
            return(0);
         }
         gNewIndent=NextIndent;
         gstate=1;
         return(_FindIndent(0,FoundStart));
      }
      if(down()) {
         return(1);
      }
   }
   return(0);
}
/**
 * Creates nested selective display based on leading spaces on lines.  
 * 
 * @param maxNestLevel  optionally specifies the limit on the nesting.
 *                      Must be at least one.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_col1
 * @see show_braces
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command void show_indent(_str maxNestLevel="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   _ShowLevels(_FindIndent,(int)maxNestLevel);
}
/**
 * Show first line of each paragraph.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_col1
 * @see show_braces
 * @see show_indent
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display
 * 
 */ 
_command void show_paragraphs(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   save_pos(auto p);
   mou_hour_glass(1);
   top();up();
   _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
   if (down()) {
      mou_hour_glass(0);
      restore_pos(p);
      return;
   }
   // Skip blank lines
   int status=0;
   _str line='';
   for (;;) {
      get_line(line);
      if (line!="") break;
      _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
      if (down()) {
         status=1;
         break;
      }
   }
   status=0;
   for (;;) {
      // Put plus on first line of paragraph
      _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
      // Hide lines that follow that are not blank
      for (;;) {
         if(down()) {
            status=1;
            break;
         }
         get_line(line);
         if (line=="") break;
         _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
      }
      if (status) {
         break;
      }
      // Skip blank lines
      for (;;) {
         get_line(line);
         if (line!="") break;
         _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
         if (down()) {
            status=1;
            break;
         }
      }
      if (status) {
         break;
      }
   }
   mou_hour_glass(0);
   restore_pos(p);
}

/**
 * Structure to describe regions of text to be hidden with selective display
 */
struct CODEREGION
{
   /**
    * Depth (or nesting) level of the code block. 0 indicates a
    * top-level region, and 1 indicates nested within a level 0 region.
    */
   int level;
   /**
    * The starting line of the code block.
    * This is first line that will be hidden by selective display.
    */
   int startLine;
   /**
    * The end line in the code block.
    * This is last line that will be hidden by selective display.
    */
   int endLine;
};

/**
 * Pushes a starting line number onto a pseudo-stack.
 * 
 * @param stack   And array of ints to act as a stack
 * @param lineNum The line number to push onto the stack
 * 
 * @example <pre>int myLines[];
 * pushLineNum(myLines, 45);
 * pushLineNum(myLines, 55);
 * int fiftyFive = popLineNum(myLines);
 * </pre>
 */
static void pushLineNum(typeless &stack, int lineNum)
{
   stack[++stack[0]] = lineNum;
}

/**
 * Returns the line number from the top of a pseudo-stack
 * 
 * @param stack  And array of ints to act as a stack
 * 
 * @return The line number on the top of the stack
 * @example <pre>int myLines[];
 * pushLineNum(myLines, 45);
 * pushLineNum(myLines, 55);
 * int fiftyFive = popLineNum(myLines);
 * </pre>
 */
static int popLineNum(typeless &stack)
{
   if (stack[0]<=0) return 0;
   int result = stack[stack[0]--];
   stack._deleteel(stack[0]+1); 
   return result;
}


/**
 * Determines the size of a pseudo-stack
 * 
 * @param stack  An array of ints to act as a pseudo-stack
 * 
 * @return The size of the stack
 */
static int stackSize(typeless &stack)
{
   return stack[0];
}


/**
 * Sorts an array of CODEREGION structures in descending order
 * with reference to the CODEREGION.level member
 * 
 * @param regionArray
 *                 The array of CODEREGION structures
 * @param maxLevel The highest depth level to sort on. Less than zero will force
 * the array to be scanned for the highest .level value.             
 */
static void sortCodeRegions(typeless &regionArray, int maxLevel = -1)
{
   // We have some nested #region areas to worry about, so
   // we'll need to do the most-nested ones first
   int idx = 0;
   int numElements = regionArray._length();

   if(maxLevel < 0)
   {
      // The caller has not defined the maximum nesting level, so
      // we'll need to walk the array to determine it.
      for(idx = 0; idx < numElements; ++idx)
      {
         CODEREGION rg = regionArray[idx];
         if(rg.level > maxLevel)
         {
            maxLevel = rg.level;
         }
      }
   }

   // So we'll walk the array and push the most nested ones
   // to the front
   CODEREGION arrTemp[];
   arrTemp = regionArray;
   regionArray._makeempty();
   int scanLevel = maxLevel;

   // TODO: This can probably be optimized to not walk the
   // array scanLevel + 1 times.
   for(; scanLevel >= 0; --scanLevel)
   {
      for(idx = 0; idx < numElements; ++idx)
      {
         CODEREGION rg = arrTemp[idx];
         if(rg.level == scanLevel)
         {
            regionArray[regionArray._length()] = rg;
         }
      }
   }
}

/**
 * Selective display command for #region / #endregion blocks
 * in C# or C++/CLI code
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_procs
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_col1
 * @see show_braces
 * @see show_indent
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display
 */
_command hide_dotnet_regions() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if(p_lexer_name == "cpp")
   {
      hide_cppcli_regions();
   }
   else if (p_lexer_name == "CSharp" || p_lexer_name == "Slick-C")
   {
      hide_csharp_regions();
   }
   else if (p_lexer_name == "Visual Basic")
   {
      hide_vb_regions();
   }
}

int _OnUpdate_hide_dotnet_regions(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if(target_wid._isMaybeDotNetCode()) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}

static boolean _isMaybeDotNetCode()
{
   if (p_lexer_name == "cpp" || 
       p_lexer_name == "CSharp" || 
       p_lexer_name == "Slick-C" || 
       p_lexer_name == "Visual Basic" ) {
      return true;
   }
   return false;
}

/**
 * Selective display function for #region / #endregion blocks
 * in C# or Slick-C&reg; code
 * 
 * @see hide_cppcli_regions
 * @see hide_vb_regions
 * @see hide_block_regions
 */
static void hide_csharp_regions()
{
   // Find the occurrence of "#region" or "#endregion", specifiying that it
   // should be pre-processor colored
   if (hide_block_regions("#region", "#endregion", "P") < 0) {
      message("No region blocks found");
   }
}

/**
 * Selective display function for #pragma region / #pragma endregion blocks
 * in C++/CLI code
 * 
 * @see hide_csharp_regions
 * @see hide_vb_regions
 * @see hide_block_regions
 */
static void hide_cppcli_regions()
{
   // Find the occurrence of "#pragma region" or "#pragma endregion", specifiying that it
   // should be pre-processor colored
   if (!hide_block_regions("#pragma region", "#pragma endregion", "P")) return;
   if (!hide_block_regions("#region", "#endregion", "P")) return;
   message("No region blocks found");
}

/**
 * Selective display function for #Region / #End Region blocks
 * in VB.net code
 * 
 * @see hide_csharp_regions
 * @see hide_cppcli_regions
 * @see hide_block_regions
 */
static void hide_vb_regions()
{
   // Find the occurrence of "#Region" or "#End Region", specifiying that it
   // should be pre-processor colored
   if (hide_block_regions("#Region", "#End Region", "P") < 0) {
      message("No region blocks found");
   }
}

/**
 * Selective display function for hiding blocks of code.
 * 
 * @param beginTag  The starting tag to search for (eg "#region")
 * @param endTag    The ending tag to look for (eg "#endregion")
 * @param colorOpts Color options used for searching. 
 *                  Default is "P" for searching for Preprocessor color
 * 
 * @see hide_cppcli_regions
 * @see hide_csharp_regions
 */
static int hide_block_regions(_str beginTag, _str endTag, _str colorOpts = "P")
{
   _str currentLine;
   int maxNestLevel = 0;
   int startingLines[];
   startingLines[0] = 0;
   CODEREGION arrRegions[];

   // Save the current position
   save_pos(auto p);

   // We want to begin our search from the start of the file
   top(); up();

   // Create the (begin|end) regular expression and search options strings,
   // which will be used as parameters to search()
   _str regexSearch = "(" :+ beginTag :+ ")|(" :+ endTag :+ ")";
   _str searchOpts = "@hUC" :+ colorOpts;

   int findStatus = search(regexSearch, searchOpts);
   while(findStatus == 0)
   {
      // Get the text of the found match
      _str word = get_text(match_length(),match_length('S'));

      // Which did we find? start or end?
      if(word == beginTag)
      {
         // If we found startTag, push the current line number onto the stack
         pushLineNum(startingLines, p_line);
      }
      else if (word == endTag)
      {
         // If we found endTag, take the current value for the starting line #
         // off the stack, and get the "nesting level" from the stackSize
         int beginLine = popLineNum(startingLines);
         if(beginLine > 0)
         {
            // We'll skip hiding blocks where the start and end
            // are found on adjacent lines.  We increment beginLine
            // so that the line containing the startTag is visible
            if(p_line > ++beginLine)
            {
               // How nested is this region block?
               int level = stackSize(startingLines);
               // Keep track of the maximum nesting level
               if(level > maxNestLevel)
               {
                  maxNestLevel = level;
               }

               // Then create a CODEREGION structure and put it into the array
               // of blocks to be hidden
               CODEREGION rg;
               rg.level = level;
               rg.startLine = beginLine;
               rg.endLine = p_line;
               arrRegions[arrRegions._length()] = rg;
            }
         }
      }

      // Repeat the search
      findStatus = repeat_search(searchOpts);
   }

   if(arrRegions._length() > 0)
   {
      // Invoke the "show-all" command to remove
      // existing selective displays
      execute("show-all");

      // Sort the region structures if we have nested blocks. We want
      // to hide the most-nested levels first so that the code collapsing
      // looks and works correctly
      if(maxNestLevel > 0)
      {
         sortCodeRegions(arrRegions, maxNestLevel);
      }

      // Walk the array of CODEREGION blocks and hide them
      int idx = 0;
      for(idx = 0; idx < arrRegions._length(); ++idx)
      {
         CODEREGION rg = arrRegions[idx];
        _hide_lines(rg.startLine, rg.endLine);
      }
   }

   // Restore the saved position
   restore_pos(p);

   // return error if there were no regions found
   return (arrRegions._length() <= 0)? STRING_NOT_FOUND_RC:0;
}


// Filter utility method for copy_selective_display
static _str filter_selective_display(_str s)
{
   // Return the text as-is if the line is not currently
   // hidden by selective display
   if (!(_lineflags() & HIDDEN_LF)) {
      // Turn off any "plus/minus" bitmap line flags
      _lineflags(0, PLUSBITMAP_LF|MINUSBITMAP_LF);
      return s;
   } 
   else {
      // Turn on the "no save" line flag to prevent copying this line.
      // filter_put_string checks for NOSAVE_LF 
      _lineflags(NOSAVE_LF, NOSAVE_LF);
   }
   return '';
}

/**
 * Copies currently visible lines only. Does not copy content of 
 * lines that are currently hidden by selective display. 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Clipboard_Functions, Selective_Display 
 */
_command void copy_selective_display() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_READ_ONLY)
{
   filter_selection_copy(filter_selective_display);
}
