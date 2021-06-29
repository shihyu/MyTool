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
#import "se/lang/api/LanguageSettings.e"
#import "c.e"
#import "clipbd.e"
#import "context.e"
#import "help.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "mfsearch.e"
#import "mouse.e"
#import "picture.e"
#import "recmacro.e"
#import "search.e"
#import "searchcb.e"
#import "selcode.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tbfind.e"
#import "se/tags/TaggingGuard.e"
#import "fileman.e"
#endregion

using se.lang.api.LanguageSettings;

_metadata enum_flags LanguageSelectiveDisplayFlags {
   SELDISP_SYMBOL_OUTLINE_ON_OPEN,
   SELDISP_STATEMENT_OUTLINE_ON_OPEN,
   SELDISP_HIDE_DOC_COMMENTS_ON_OPEN,
   SELDISP_HIDE_OTHER_COMMENTS_ON_OPEN,
};

/**
 * Selective display options flags. 
 *  
 * @see show_procs 
 * @see hide_all_comments 
 */
enum_flags SelectiveDisplayFlags {
   /** 
    * In {@link show_procs}, specifies that the comments preceeding a 
    * function definition or declaration should be collapsed as a separate 
    * selective-display region.
    */
   SELDISP_COLLAPSEPROCCOMMENTS        = 0x0001,
   /**
    * In {@link show_procs}, specifies that the comments preceeding a function 
    * definition or declaration should remain visible. 
    * If neither this flag nor {@link SELDISP_COLLAPSEPROCCOMMENTS} are set, 
    * the comments will be hidden entirely.
    */
   SELDISP_SHOWPROCCOMMENTS            = 0x0002,

   /**
    * In {@link plusminus}, specifies that when expanding a selective display 
    * region with nested regions, that the nested regions should also be expanded.
    */
   SELDISP_EXPANDSUBLEVELS             = 0x0004,
   /**
    * In {@link plusminus}, specifies that when expanding a selective display 
    * region with nested regions, that the nested regions should be collapsed. 
    */
   SELDISP_COLLAPSESUBLEVELS           = 0x0008,

   /**
    * In {@link show_procs}, specifies that other symbols should be collapsed 
    * in the same way functions are handled.  If this is not specified, 
    * non-function symbols will be hidden entirely. 
    */
   SELDISP_SHOW_OTHER_SYMBOLS          = 0x0010,
   /**
    * In {@link show_procs}, specifies that the bodies of function definitions 
    * should be collapsed as a separate selective-display region. 
    */
   SELDISP_COLLAPSE_PROC_BODIES        = 0x0020,
   /**
    * In {@link show_procs}, specifies that the bodies of function definitions 
    * should remain visible.
    */
   SELDISP_SHOW_PROC_BODIES            = 0x0040,
   /**
    * In {@link show_procs}, specifies that blank lines separating 
    * functions and other symbols should remain visible.
    */
   SELDISP_SHOW_BLANK_LINES            = 0x0080,

   /**
    * In {@link hide_all_comments} specifies that any documentation
    * comment should be collapsed. 
    *  
    * In {@link show_procs}, specifies that the action specified for function 
    * comments (Show, Collapse, or Hide), should be specifically applied to 
    * documentation comments. 
    */
   SELDISP_COLLAPSE_DOC_COMMENTS       = 0x0100,
   /**
    * In {@link hide_all_comments} specifies that any non-documentation
    * comment should be collapsed. 
    *  
    * In {@link show_procs}, specifies that the action specified for function 
    * comments (Show, Collapse, or Hide), should be specifically applied to 
    * non-documentation comments. 
    */
   SELDISP_COLLAPSE_OTHER_COMMENTS     = 0x0200,
};


/**
 * If enabled, the {@link plusminus} command will try to find code
 * blocks to expand or collapse if the cursor is on a line that does
 * not have a +/- bitmap on it.
 * 
 * @default true
 * @categories Configuration_Variables, Tagging_Functions
 */
bool def_plusminus_blocks=true;

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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */ 
_command collapse_to_definitions() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   show_procs(SELDISP_COLLAPSEPROCCOMMENTS);
}

static bool plusminus_block(bool force=false)
{
   // get the number of lines in the current code block
   save_pos(auto p);
   isComment  := false;
   allowUnsurround := true;
   first_line := 0;
   last_line  := 0;
   num_first_lines := 0;
   num_last_lines  := 0;
   indent_change := true;
   if ( get_code_block_lines(first_line, num_first_lines, 
                             last_line,  num_last_lines,
                             indent_change, isComment, 
                             allowUnsurround, force, true) ) {
      // we have a comment block, hide all but the first line of it
      if (isComment && p_line==first_line && num_last_lines<=1 && first_line+1 <= last_line) {
         _hide_lines(first_line+1, last_line);
         restore_pos(p);
         return true;
      }
      // we have a code block, hide all but the first (and possible last) line(s) of it
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
 * Query the range of a selective display block. 
 * The cursor should be on the line containing a [+] or [-] bitmap. 
 * 
 * @param first_line   (reference) set to real line number of first line of block
 * @param last_line    (reference) set to real line number of last line of block
 * 
 * @return 0 on success, STRING_NOT_FOUND_RC if selective display block is not found.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */
int get_plusminus_range(int &first_line, int &last_line)
{
   save_pos(auto p);
   first_line = p_RLine;
   last_line  = first_line;
   start_level := (_lineflags() & LEVEL_LF);
   pm := (_lineflags() & (PLUSBITMAP_LF|MINUSBITMAP_LF));

   if (pm==PLUSBITMAP_LF) {
      loop {
         // check for end of file
         if(down()) break;
         // this line is not hidden
         if (!(_lineflags() & HIDDEN_LF)) break;
         // if we hit the start of a new expansion at the same level
         level := (_lineflags() & LEVEL_LF);
         if (level<start_level || (level==start_level && _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF))) break;
         // keep track of last line of expansion
         last_line = p_RLine;
      }
      restore_pos(p);
      return(0);
   }

   if (pm==MINUSBITMAP_LF) {
      loop {
         // check for end of file
         if(down()) break;
         // if we hit the start of a new expansion at the same level
         level := (_lineflags() & LEVEL_LF);
         if (level<=start_level) break;
         // keep track of last line of expansion
         last_line = p_RLine;
      }
      restore_pos(p);
      return(0);
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * Expands or collapses selective display blocks.
 * <ul>
 * <li>If the cursor is on a line that contains a "+" bitmap
 *        for selective display, expand the collapsed block.
 * <li>If the cursor is on a line that contains a "-" bitmap
 *     for selective display, collapse the block.
 * <li>Otherwise, if the cursor is in a selection, hide the selection.
 * <li>Finally, if the cursor is on a line that has no "+"
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
 * @see show_symbols 
 * @see show_statements 
 * @see def_plusminus_blocks
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */
_command int plusminus(_str CheckCurLineOnly='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
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
      if (def_plusminus_blocks && plusminus_block(true)) {
         return 0;
      }

      // hide selection if we are in one
      if (select_active() && _in_selection()) {
         hide_selection();
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

int count_num_seldisp_lines()
{
   save_pos(auto p);
   count := 0;
   pm := _lineflags() & (PLUSBITMAP_LF|MINUSBITMAP_LF);
   start_level := _lineflags()&LEVEL_LF;
   if (pm==PLUSBITMAP_LF) {
      for(;;) {
         count++;
         if(down()) break;
         level := _lineflags()&LEVEL_LF;
         if (level<start_level || (level==start_level && _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF))) {
            break;
         }
      }
   } else if (pm==MINUSBITMAP_LF) {
      for(;;) {
         count++;
         if(down()) break;
         level := _lineflags()&LEVEL_LF;
         if (level<=start_level) {
            break;
         }
      }
   } else if (def_plusminus_blocks) {
      if ( get_code_block_lines(auto first_line, auto num_first_lines, 
                                auto last_line,  auto num_last_lines,
                                auto indent_change, auto isComment, 
                                auto allowUnsurround, false, true) ) {
         if (isComment && p_RLine==first_line && num_last_lines<=1 && first_line+1 <= last_line) {
            // we have a comment block, hide all but the first line of it
            count = last_line-first_line;
         } else if (p_RLine==first_line && first_line+1 <= last_line-num_last_lines) {
            // we have a code block, hide all but the first (and possible last) line(s) of it
            count = last_line-first_line-num_last_lines;
         }
      }
   }
   restore_pos(p);
   return count;
}

/** 
 * Create selective display outline for this buffer based on language-specific
 * selective display options.
 * 
 * This only runs once and then returns without doing anything afterwards.
 * In order to not conflict with auto-restore, this will not create selective
 * display regions if there were auto-restored selective display regions. 
 *
 * @param force   force update independent of amount of idle time elapsed.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */
void _UpdateSelectiveDisplay(bool force=false) 
{
   // Check idle time
   idle_time := _idle_time_elapsed();
   if (!force && idle_time < def_update_tagging_idle) {
      //say("_UpdateSelectiveDisplay: WAIT");
      return;
   }

   // get the editor control window ID to update
   orig_wid := p_window_id;
   if (!_no_child_windows()) {
      p_window_id = _mdi.p_child;
   } else if (!_isEditorCtl()) {
      //say("_UpdateSelectiveDisplay: NOT EDITOR");
      return;
   }

   // is the file begin diffed?
   if (_isdiffed(p_buf_id)) {
      //say("_UpdateSelectiveDisplay: IN DIFF");
      p_window_id = orig_wid;
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   flags := LanguageSettings.getSelectiveDisplayFlags(p_LangId);
   if (!force && !_ContextIsUpToDate(idle_time, MODIFYFLAG_CONTEXT_UPDATED|((flags & SELDISP_STATEMENT_OUTLINE_ON_OPEN)? MODIFYFLAG_STATEMENTS_UPDATED:0))) {
      //say("_UpdateSelectiveDisplay H"__LINE__": context not up to date");
      return;
   }

   // check the last selective display options, clear the previous options
   // if we already have selective display going on
   options_key := "selective_display_file_options";
   lastOptions := _GetBufferInfoHt(options_key);
   if (lastOptions == null || lastOptions!=flags) {
      //say("_UpdateSelectiveDisplay H"__LINE__": OPTIONS CHANGED");
      if (lastOptions != null && lastOptions != 0 && p_NofSelDispBitmaps > 0) {
         //say("_UpdateSelectiveDisplay H"__LINE__": CLEAR SELDISP");
         show_all();
      }
      _SetBufferInfoHt(options_key, flags);
   }

   // do nothing else if no flags are turned on
   if (flags == 0) {
      //say("_UpdateSelectiveDisplay: OPTIONS OFF, lang="p_LangId);
      p_window_id = orig_wid;
      return;
   }

   // check the last time we updated this buffer, and then mark it as up-to-date
   hash_key := "selective_display_file_time";
   lastModified := _GetBufferInfoHt(hash_key);
   if (lastModified != null && lastModified==p_LastModified) {
      //say("_UpdateSelectiveDisplay: ALREADY DONE");
      p_window_id = orig_wid;
      return;
   }
   _SetBufferInfoHt(hash_key, p_LastModified);

   // was selective display already auto-restored for this buffer?
   //say("_UpdateSelectiveDisplay H"__LINE__": HERE, file="p_buf_name);
   if (p_NofSelDispBitmaps > 0) {
      //say("_UpdateSelectiveDisplay: ALREADY HAVE SELDISP");
      p_window_id = orig_wid;
      return;
   }

   // maybe create an outline
   save_pos(auto p);
   levels := def_seldisp_maxlevel:+" ":+(def_seldisp_minlevel>0? def_seldisp_minlevel:63);
   if (_istagging_supported()) {
      if (flags & SELDISP_STATEMENT_OUTLINE_ON_OPEN) {
         if (_are_statements_supported()) {
            show_statements(levels,false);
         } else {
            show_symbols(levels,false);
         }
      } else if (flags & SELDISP_SYMBOL_OUTLINE_ON_OPEN) {
         show_symbols(levels,false);
      }
   }

   // now maybe hide comments
   hideCommentsFlags := 0;
   if (flags & SELDISP_HIDE_DOC_COMMENTS_ON_OPEN) {
      hideCommentsFlags |= SELDISP_COLLAPSE_DOC_COMMENTS;
   }
   if (flags & SELDISP_HIDE_OTHER_COMMENTS_ON_OPEN) {
      hideCommentsFlags |= SELDISP_COLLAPSE_OTHER_COMMENTS;
   }
   if (hideCommentsFlags) {
      hide_all_comments(hideCommentsFlags);
   }

   // restore original cursor position
   restore_pos(p);
   expand_line_level();
   p_window_id = orig_wid;
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
bool _extend_outline_selection(_str markid)
{
   if (_select_type(markid)!="LINE" || _select_type(markid)=="") return(false);

   _str persistant=(def_persistent_select=='Y')?'P':'';
   mstyle := 'N'persistant;
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
   result := false;
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
bool _preprocessing_supported()
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
 * @param seldisp_flags    Specifies which kinds of comments to hide. 
 *                         By default, this function collapses all types of comments.
 *                         <ul>
 *                         <li>SELDISP_COLLAPSE_DOC_COMMENTS (256) -- collapse documentation comments
 *                         <li>SELDISP_COLLAPSE_OTHER_COMMENTS (512) -- collapse non-documentation comments
 *                         </ul>
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 */
_command void hide_all_comments(_str seldisp_flags="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (seldisp_flags=="") {
      seldisp_flags=def_seldisp_flags;
   }

   mou_hour_glass(true);
   save_pos(auto p);
   top();
   int status=_clex_find(COMMENT_CLEXFLAG);
   for (;;) {
      if (status) {
         break;
      }

      doHideComment := true;
      if ((int)seldisp_flags & (SELDISP_COLLAPSE_DOC_COMMENTS|SELDISP_COLLAPSE_OTHER_COMMENTS)) {
         if (!((int)seldisp_flags & SELDISP_COLLAPSE_DOC_COMMENTS)) {
            // check if this is a documentation comment.
            if (_clex_find(0, 'D') == CFG_DOCUMENTATION) {
               doHideComment = false;
            }
         }
         if (!((int)seldisp_flags & SELDISP_COLLAPSE_OTHER_COMMENTS)) {
            // check if this is a non-documentation comment.
            if (_clex_find(0, 'D') != CFG_DOCUMENTATION) {
               doHideComment = false;
            }
         }
      }

      // hide the comment if we need to
      if (doHideComment) {
         orig_line := p_line;
         hide_comments();
         p_line=orig_line;
      }

      _end_line();
      status=_clex_find(COMMENT_CLEXFLAG,'N');
      if (status) {
         break;
      }
      status=_clex_find(COMMENT_CLEXFLAG);
   }
   mou_hour_glass(false);
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
   new_level := 0;
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
   doEndLastLevel := true;
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
 * @param leaveSelected  Leave the selection active. 
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */
_command void show_selection(_str markid="", _str leaveSelected="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_AB_SELECTION)
{
   save_pos(auto p);
   hide_selection(markid,1,leaveSelected);
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
 * @param leaveSelected  Leave the selection active. 
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */
_command void hide_selection(_str markid="", _str doShow="", _str leaveSelected="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_AB_SELECTION)
{
   if (!select_active(markid)) {
      _message_box(get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   save_pos(auto p);
   _begin_select(markid);
   first_line := p_line;
   _end_select(markid);
   last_line := p_line;
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
   if (leaveSelected == "") {
      _deselect(markid);
   }
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command void selective_display(_str options="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_MARK)
{
   show('_seldisp_form',options);
}
static void hide_comments(bool doShow=false)
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
   old_line := p_line;
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
   last_line := p_line;
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */
_command void hide_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // Check to see if the very last command executed is the same command:
   expandBlock := 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == "hide-code-block" ) expandBlock = 1;
   //say( '******* name='name );

   //Check if the first non-blank character of this line is a comment
   save_pos(auto p);
   _first_non_blank();
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */
_command void show_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   expandBlock := 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == "show-code-block" ) expandBlock = 1;
   //Check if the first non-blank character of this line is a comment
   save_pos(auto p);
   _begin_line();search('[~ \t]|$','@rh');
   if (_clex_find(0,'g')==CFG_COMMENT) {
      hide_comments(true);
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
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
 * @param option (optional).     '' = expand all collapsed branches
 *                               'C' = collapse all expanded branches.
 *                               Default to ''.
 * @param skip_lines_from_top    Number of lines to skip at top of file 
 *                               Default is 0 
 */
_command void expand_all(_str option='', int skip_lines_from_top=0) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   mask := upcase(option)=='C' ? MINUSBITMAP_LF : PLUSBITMAP_LF;
   save_pos(auto p);
   top();
   if (skip_lines_from_top > 0) {
      down(skip_lines_from_top);
   } else {
      up();
   }
   // Do line 0 first
   plus_or_minus :=  _lineflags()&(mask);
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
 *  
 * @param option (optional).     '' = expand all collapsed branches
 *                               'C' = collapse all expanded branches.
 *                               Default to ''.
 * @param skip_lines_from_top    Number of lines to skip at top of file 
 *                               Default is 0 
 */
_command void collapse_all(_str option='C', int skip_lines_from_top=0) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   expand_all('C', skip_lines_from_top);
}



/**
 * Makes current line visible, expanding levels and preserving all selective display marks
 */
void expand_line_level()
{
   int flags = _lineflags();
   if (flags & HIDDEN_LF) {
      skip_first := true;
      level := _LevelIndex(flags);
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
static int find_directive(_str &directive,int find_first,bool isdelphi)
{
   status := 0;
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
static void get_line_cont(_str &line,bool isdelphi)
{
   ppkeyword := "";
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
   old_len := length(line);
   parse line with line '//';
   // If there was not a line comment
   if (old_len==length(line)) {
      _end_line();
      for (;;) {
         RemoveLastChar := false;
         if (_clex_find(0,'g')!=CFG_COMMENT) {
            RemoveLastChar=(_last_char(line)=='\');
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
         line :+= line2;
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
      name := substr(exp,pos('S1'),pos('1'));
      start := pos('S0');
      len := pos('0');
      int result=isdefined(define_names,name);
      leftstr := substr(exp,1,start-1):+result;
      i=length(leftstr)+1;
      exp=leftstr:+substr(exp,start+len);
      //messageNwait('exp='exp);
   }
}

static _str flatten_defines (_str define_names)
{
   //"flatten" out the provided defines.
   lval1 := "";
   lval2 := "";
   rval1 := "";
   rval2 := "";
   remainder := "";
   _str pairs:[];
   equalSignPos := 0;
   spacePos := 0;
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
   makingProgress := true;
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

   result := "";
   for (i._makeempty();;) {
      pairs._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (pairs:[i] :!= "") {
         result :+= i"="pairs:[i]" ";
      } else {
         result :+= i" ";
      }
   }
   return result;
}

static const STATE0=       0;    /* No if has been processed. */
static const PROCESSCASE=  1;    /* last case was processed. */
static const SKIPCASE=     2;    /* last case was skipped. */
static const SKIPREST=     4;    /* Skip all cases that follow */
static const DIDELSE=      16;    /* Can have (SKIPREST|DIDELSE) or
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */
_command void preprocess(_str define_names="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   warning := "%s value not defined or not valid number.  Default value is 0";
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
   already_warned_list := "";
   save_pos(auto p);
   mou_hour_glass(true);
   show_all();
   top();
   int state=STATE0;
   state_stack := "";
   directive := "";
   int status=find_directive(directive,1,isdelphi);
   start_skip_linenum := 0;
   start_exp_linenum := 0;
   end_exp_linenum := 0;
   typeless new_state=0;
   typeless result=0;
   _str exp,name,line;
   for (;;) {
      if (status) {
         break;
      }
      state_change := 1;
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
               if(_last_char(name)=='+') {
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
               define_names :+= ' 'name'='exp;
            } else {
               define_names :+= ' 'name;
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
   mou_hour_glass(false);
   restore_pos(p);
}
static _str _get_define_names()
{
   isdelphi := _LanguageInheritsFrom("pas");
   already_found_names := " ";
   already_found_opt_names := " ";
   save_pos(auto p);
   top();
   mou_hour_glass(true);
   define_names := "";
   directive := "";
   int status=find_directive(directive,1,isdelphi);
   int orig_view_id;
   get_window_id(orig_view_id);
   _str exp,name,line,rest;
   typeless result;
   int i,j;
   last_was_defined := 0;
outerloop:
   for (;;) {
      if (status) {
         break;
      }
      state_change := 1;
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
   mou_hour_glass(false);
   restore_pos(p);
   return(define_names);
}

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
 * @see show_symbols 
 * @see show_statements 
 *  
 * @categories Search_Functions, Selective_Display_Category
 */
_command void all(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   dolessnot := false;
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   old_search_flags = (old_search_flags &~(WRAP_SEARCH|POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH|NO_MESSAGE_SEARCH));
   new_search_options := "";
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
      donot:=false;
      _str arg1=arg(1);
      if (substr(arg1,1,1)=='~') {
         donot=true;
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
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('all',old_search_string,new_search_options);

   _mffindNoMore(1);
   _mfrefNoMore(1);

   status := 0;
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;
   dohide_all:=true;

   // Fetch the search flags.
   search('','h@'new_search_options);
   save_search('',old_search_flags,old_word_re);
   save_last_search(old_search_string, new_search_options);

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
   mou_hour_glass(true);
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
         stopOffset := _QROffset();
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
   mou_hour_glass(false);

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
   new_search_options := "";
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
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('more',old_search_string,new_search_options);

   status := 0;
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;


   search('','h@'new_search_options);
   save_search('',old_search_flags,old_word_re);
   save_last_search(old_search_string, new_search_options);

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
   mou_hour_glass(true);
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
   mou_hour_glass(false);

   set_find_next_msg("Find", old_search_string, new_search_options);
   restore_pos(p);
   //return(status)
}
_command void lessnot(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   search_options := "";
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
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
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
   search_options := "";
   less:=false;
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
      new_search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE)):+new_search_options;
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
 * @see show_symbols 
 * @see show_statements 
 *  
 * @categories Search_Functions, Selective_Display_Category
 */
_command void allnot(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int recording_macro=_macro();
   /* Restore word_re */
   restore_search(old_search_string,old_search_flags,'['p_word_chars']');
   //old_search_flags= (old_search_flags &~(WRAP_SEARCH|POSITIONONLASTCHAR_SEARCH|INCREMENTAL_SEARCH|NO_MESSAGE_SEARCH));
   doless := false;
   search_options := "";
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
      search_options=make_search_options(_default_option('s')&(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_IGNORECASE|VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE)):+search_options;
   }
   _macro('m',recording_macro);
   _macro_delete_line();
   _macro_call('allnot',old_search_string,search_options);

   _mffindNoMore(1);
   _mfrefNoMore(1);

   save_pos(auto p);

   top();
   mou_hour_glass(true);
   if (!doless) {
      show_all();
   }
   status := search(old_search_string,'h@'search_options);
   new_level := 0;
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
   mou_hour_glass(false);

   typeless junk;
   search('','@'search_options); // unset hidden flags
   save_search(junk,old_search_flags,old_word_re);
   save_last_search(old_search_string, search_options);
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
   orig_line := p_line;
   // Find open paren
   status := search('(','h@');
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
   nesting := 1;
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
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
   mou_hour_glass(true);
   //say("show_procs");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   save_pos(auto p);
   top();up();
   old_lastparam_linenum := p_line;
   if (!_default_option('t')) ++old_lastparam_linenum;
   done_status := false;
   int num_context_tags = tag_get_num_of_context();
   tag_type := "";
   linenum := 0;
   done_hidden_linenum := 0;
   next_linenum := 0;
   symbol_scope_linenum := 0;
   symbol_scope_seekpos := 0;
   symbol_end_linenum := 0;
   symbol_end_seekpos := 0;
   end_comment_line := 0;
   start_comment_line := 0;
   int i;
   for (i=1; !done_status; i++) {
      // only do this for functions
      tag_get_detail2(VS_TAGDETAIL_context_type, i, tag_type);
      if (i > num_context_tags) {
         linenum=p_Noflines;
         done_status=true;
         bottom(); down();
         done_hidden_linenum=p_Noflines;
      } else {
         tag_get_detail2(VS_TAGDETAIL_context_line, i, linenum);
         tag_get_detail2(VS_TAGDETAIL_context_scope_linenum, i, symbol_scope_linenum);
         tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, i, symbol_scope_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_end_linenum, i, symbol_end_linenum);
         tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, i, symbol_end_seekpos);
         if (symbol_scope_linenum < linenum) symbol_scope_linenum = 0;
         if (symbol_scope_linenum > symbol_end_linenum) symbol_scope_linenum = symbol_end_linenum;
         if (symbol_scope_seekpos > symbol_end_seekpos) symbol_scope_seekpos = symbol_end_seekpos;
         if (tag_type == "proto" || tag_type == "procproto") {
            find_lastprocparam_index = 0;
            if (symbol_scope_linenum <= linenum && symbol_end_linenum > linenum) {
               symbol_scope_linenum = symbol_end_linenum;
               symbol_scope_seekpos = symbol_end_seekpos;
            }
         }
         symbol_end_linenum=0;

         if (!tag_tree_type_is_func(tag_type)) {
            find_lastprocparam_index = 0;
            if (!((int)seldisp_flags & SELDISP_SHOW_OTHER_SYMBOLS)) {
               continue;
            }
         } else {
            if ((int)seldisp_flags & (SELDISP_SHOW_PROC_BODIES|SELDISP_COLLAPSE_PROC_BODIES)) {
               tag_get_detail2(VS_TAGDETAIL_context_end_linenum, i, symbol_end_linenum);
            }
         }

         p_RLine=linenum;p_col=1;

         //messageNwait("show_procs: h1");
         next_linenum=p_line;
         done_hidden_linenum=next_linenum-1;

         if (((int)seldisp_flags) & (SELDISP_COLLAPSEPROCCOMMENTS|SELDISP_SHOWPROCCOMMENTS|SELDISP_COLLAPSE_DOC_COMMENTS|SELDISP_COLLAPSE_OTHER_COMMENTS)) {
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            old_col := p_col;
            /*
               Process comments separately from function
            */
            up();
            end_comment_line=p_line;
            _end_line();
            // Look for a non-blank character
            status := search("[^ \t]","@-rh");
            //messageNwait("show_procs: status="status" p_line="p_line);
            // If we found a non-blank character and
            //    it is comment text

            // check what specific kind of comments we should hide
            doComment := true;
            if ((int)seldisp_flags & (SELDISP_COLLAPSE_DOC_COMMENTS|SELDISP_COLLAPSE_OTHER_COMMENTS)) {
               if (!((int)seldisp_flags & SELDISP_COLLAPSE_DOC_COMMENTS)) {
                  // check if this is a documentation comment.
                  if (_clex_find(0, 'D') == CFG_DOCUMENTATION) {
                     doComment = false;
                  }
               }
               if (!((int)seldisp_flags & SELDISP_COLLAPSE_OTHER_COMMENTS)) {
                  // check if this is a non-documentation comment.
                  if (_clex_find(0, 'D') != CFG_DOCUMENTATION) {
                     doComment = false;
                  }
               }
               if (!(((int)seldisp_flags) & (SELDISP_COLLAPSEPROCCOMMENTS|SELDISP_SHOWPROCCOMMENTS))) {
                  doComment = !doComment;
               }
            } else if (!(((int)seldisp_flags) & (SELDISP_COLLAPSEPROCCOMMENTS|SELDISP_SHOWPROCCOMMENTS))) {
               doComment = false;
            }

            if (doComment && !status && _clex_find(0,'g')==CFG_COMMENT) {
               //messageNwait("show_procs: h2");
               // Skip blank lines and comments
               if (_clex_skip_blanks("h-")) {
                  // There is at least one line of comments
                  // We hit top of file.
                  top();up();
               }
               down();
               start_comment_line=p_line;
               if (_clex_find(0,'g')!=CFG_COMMENT) {
                  _clex_find(COMMENT_CLEXFLAG, 'O');
                  start_comment_line=p_line;
               }
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
                        _lineflags(MINUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                        down();
                        for (;p_line<=end_comment_line;) {
                           _lineflags(NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
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
         if (symbol_end_linenum > 0 && symbol_scope_linenum > 0 && symbol_end_linenum > symbol_scope_linenum+1) {
            if ((int)seldisp_flags & SELDISP_COLLAPSE_PROC_BODIES) {
               p_RLine = symbol_scope_linenum;
               _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
               down();
               for (;p_RLine<symbol_end_linenum;) {
                  _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                  if (down()) break;
               }
               next_linenum = symbol_end_linenum;
            } else if ((int)seldisp_flags & SELDISP_SHOW_PROC_BODIES) {
               p_RLine = symbol_scope_linenum;
               _lineflags(MINUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
               down();
               for (;p_RLine<symbol_end_linenum;) {
                  _lineflags(NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
                  if (down()) break;
               }
               next_linenum = symbol_end_linenum;
            }
         }
      }
      if (old_lastparam_linenum<done_hidden_linenum) {
         //_hide_lines(old_lastparam_linenum,done_hidden_linenum);
         if ((int)seldisp_flags & SELDISP_SHOW_BLANK_LINES) {
            p_line=old_lastparam_linenum;
            down();
            get_line(auto line);
            while (line == "" && p_line <= done_hidden_linenum) {
               old_lastparam_linenum = p_line;
               if (down()) break;
               get_line(line);
            }
         }
         if (old_lastparam_linenum<done_hidden_linenum) {
            p_line=old_lastparam_linenum;
            _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
            down();
            for (;p_line<=done_hidden_linenum;) {
               _lineflags(HIDDEN_LF|NEXTLEVEL_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
               if (down()) break;
            }
         }
      }
      if (done_status) {
         break;
      }
      p_line=next_linenum;
      //messageNwait("show_procs: next_linenum="next_linenum);
      if (symbol_end_linenum > 0) {
         p_RLine = symbol_end_linenum;
      } else if (symbol_scope_linenum > 0) {
         // go to the seek position of the starting scope for this function
         _GoToROffset(symbol_scope_seekpos);
         get_line(auto scope_line);
         left();
         if (p_col==1) {
            up();
            _end_line();
         }
         _clex_skip_blanks('-');
      } else if (find_lastprocparam_index) {
         //message('p_line='p_line);  //delay(100);clear_message();
         save_search(auto a,auto b,auto c,auto d);
         call_index(find_lastprocparam_index);
         restore_search(a,b,c,d);
      }
      old_lastparam_linenum=p_line;
   }

   mou_hour_glass(false);
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
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command show_col1() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   all('^[~ \t]','r');
}


defeventtab _seldisp_form;
static int UserSelDispParent(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}

ctlscan.on_create()
{
   // align up the button with the textbox - it is auto-sized
   rightAlign := ctlremenu.p_parent.p_width - ctlsearchstring.p_x;
   sizeBrowseButtonToTextBox(ctlsearchstring.p_window_id, ctlremenu.p_window_id, 0, rightAlign);
}

ctlscan.lbutton_up()
{
   _macro('m',_macro('s'));
   _macro_append('define_names=_get_define_names();');
   ctldefines.p_text=UserSelDispParent()._get_define_names();
   ctldefines._set_sel(1);
   ctldefines._set_focus();
}

void ctlCheckLimit.lbutton_up()
{
   ctlLimit.p_enabled=(p_value!=0);
   ctlLimit.p_next.p_enabled=(p_value!=0);
}
void ctlCollapseLimit.lbutton_up()
{
   ctlLowerLimit.p_enabled=(p_value!=0);
   ctlLowerLimit.p_next.p_enabled=(p_value!=0);
}

void ctlre.lbutton_up()
{
   ctlre_type.p_enabled = ctlremenu.p_enabled = ctlre.p_value ? true : false;
}

void ctlshowdoccomments.lbutton_up()
{
   if (ctlshowothercomments.p_value == 0 && ctlshowdoccomments.p_value == 0) {
      p_value = 1;
   }
}
void ctl_doc_comments_checkbox.lbutton_up()
{
   if (ctl_doc_comments_checkbox.p_value == 0 && ctl_other_comments_checkbox.p_value == 0) {
      p_value = 1;
   }
}

ctlok.on_create(_str options="")
{
   // force the form height (since the form contains hidden controls) 
   p_active_form.p_height = ctlok.p_y_extent + ctlsearch.p_y;

   // parse command line options
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
   UserSelDispParent(_form_parent());
   ctlhelplabel.p_user=ctlhelplabel.p_caption;

   // This removes duplicates.  However, if we delete lines
   // below, there may be a duplicate because the lines are
   // not adjacent.
   ctldefines._retrieve_list();
   ctlsearchstring._retrieve_list();

   // Remove blank lines from ctldefines combo box list.
   p_window_id=ctldefines;
   Nofhits := 0;_lbtop();
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

   // set options for show procs
   p_window_id=ctlok;
   if (def_seldisp_flags&SELDISP_SHOWPROCCOMMENTS) {
      ctlshowcomments.p_value=1;
   } else if (def_seldisp_flags&SELDISP_COLLAPSEPROCCOMMENTS) {
      ctlcollapsecomments.p_value=1;
   } else {
      ctlhidecomments.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_SHOW_PROC_BODIES) {
      ctlshowbodies.p_value=1;
   } else if (def_seldisp_flags&SELDISP_COLLAPSE_PROC_BODIES) {
      ctlcollapsebodies.p_value=1;
   } else {
      ctlhidebodies.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_SHOW_BLANK_LINES) {
      ctlshowblanklines.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_COLLAPSE_DOC_COMMENTS) {
      ctlshowdoccomments.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_COLLAPSE_OTHER_COMMENTS) {
      ctlshowothercomments.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_SHOW_OTHER_SYMBOLS) {
      ctl_show_all_symbols.p_value=1;
   }

   // set options for show comments
   if (def_seldisp_flags&SELDISP_COLLAPSE_DOC_COMMENTS) {
      ctl_doc_comments_checkbox.p_value=1;
   }
   if (def_seldisp_flags&SELDISP_COLLAPSE_OTHER_COMMENTS) {
      ctl_other_comments_checkbox.p_value=1;
   }
   if (!(def_seldisp_flags&(SELDISP_COLLAPSE_DOC_COMMENTS|SELDISP_COLLAPSE_OTHER_COMMENTS))) {
      ctl_doc_comments_checkbox.p_value=1;
      ctl_other_comments_checkbox.p_value=1;
   }

   // set up regular expression options
   //ctlre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   //ctlre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   ctlre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   ctlre_type._lbadd_item(RE_TYPE_PERL_STRING);
   ctlre_type._lbadd_item(RE_TYPE_VIM_STRING);
   ctlre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
   //if (def_re_search_flags & VSSEARCHFLAG_BRIEFRE) {
   //   ctlre_type.p_text = RE_TYPE_BRIEF_STRING;
   //} else 
   if (def_re_search_flags & VSSEARCHFLAG_RE) {
      ctlre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
   } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
      ctlre_type.p_text = RE_TYPE_WILDCARD_STRING;
   } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
      ctlre_type.p_text = RE_TYPE_VIM_STRING;
   } else /*if (def_re_search_flags & VSSEARCHFLAG_PERLRE) */{
      ctlre_type.p_text = RE_TYPE_PERL_STRING;
   //} else {
    //  ctlre_type.p_text = RE_TYPE_UNIX_STRING;
   }

   // retrieve the previous form options
   _retrieve_prev_form();

   // disable reset if the buffer has no hidden lines
   if (!UserSelDispParent().p_Nofhidden) {
      ctlshowall.p_enabled=false;
   }

   // check that preprocesing is supported for this language
   if (!UserSelDispParent()._preprocessing_supported()) {
      ctlpreprocess.p_enabled=false;
      if (ctlpreprocess.p_value) {
         ctlsearch.p_value=1;
      }
   }

   // check that tagging is supported for this language
   if (!UserSelDispParent()._istagging_supported()) {
      ctlsymbols.p_enabled=false;
      ctlstatements.p_enabled=false;
      ctlshowprocs.p_enabled=false;
      if (ctlshowprocs.p_value) {
         ctlsearch.p_value=1;
      }
      if (ctlsymbols.p_value) {
         ctlbraces.p_value=1;
      }
   }

   // check that statement tagging is supported for this language
   if (!UserSelDispParent()._are_statements_supported() || !_haveContextTagging()) {
      ctlstatements.p_enabled=false;
      if (ctlstatements.p_value) {
         ctlsymbols.p_value=1;
      }
   }

   // check that we have a selection
   ctlHideSelection.p_enabled=(UserSelDispParent().select_active2()!=0);
   if (!ctlHideSelection.p_enabled && ctlHideSelection.p_value) {
      ctlsearch.p_value=1;
   }
   ctlOnlySelection.p_enabled=(UserSelDispParent().select_active2()!=0);

   // set up search options
   if (ctlsearchstring.p_text:=='') {
      int flags=_default_option('s');
      ctlmatchcase.p_value= (int)!(flags & VSSEARCHFLAG_IGNORECASE);
      ctlmatchword.p_value=flags & VSSEARCHFLAG_WORD;
      ctlre.p_value = flags & (VSSEARCHFLAG_RE/*|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE*/|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE);
   }
#if 0
   if (ctlre.p_value) {
      int flags=_default_option('s') & (VSSEARCHFLAG_RE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE);
      //ctlre_type._init_re_type(flags);
      if (flags) {
         if (flags == VSSEARCHFLAG_RE) {
            ctlre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
         } else if (flags == VSSEARCHFLAG_WILDCARDRE) {
            ctlre_type.p_text = RE_TYPE_WILDCARD_STRING;
         } else if (flags == VSSEARCHFLAG_VIMRE) {
            ctlre_type.p_text = RE_TYPE_VIM_STRING;
         } else if (flags == VSSEARCHFLAG_PERLRE) {
            ctlre_type.p_text = RE_TYPE_PERL_STRING;
         }
      }
   } 
#endif
   ctlre_type.p_enabled = ctlremenu.p_enabled = ctlre.p_value ? true : false;

   // set up multi-level outlining options
   if (ctlLimit.p_text=="") {
      ctlLimit.p_text=def_seldisp_maxlevel;
   }
   if (ctlLowerLimit.p_text=="") {
      ctlLowerLimit.p_text=def_seldisp_minlevel;
   }

   // set up options for expanding or collapsing sublevels
   if (def_seldisp_flags & SELDISP_EXPANDSUBLEVELS) {
      ctlExpandSubLevels.p_value=1;
   } else if (def_seldisp_flags & SELDISP_COLLAPSESUBLEVELS) {
      ctlCollapseSubLevels.p_value=1;
   } else {
      ctlRememberSubLevels.p_value=1;
   }

   // make sure the right controls are selected
   if (ctlsearch.p_value) {
      ctlsearch.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctlshowprocs.p_value) {
      ctlshowprocs.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctlpreprocess.p_value) {
      ctlpreprocess.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctloutline.p_value) {
      ctloutline.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctlcomments.p_value) {
      ctlcomments.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctlParagraphs.p_value) {
      ctlParagraphs.call_event(ctlsearch,LBUTTON_UP);
   } else if (ctlHideSelection.p_value) {
      ctlHideSelection.call_event(ctlsearch,LBUTTON_UP);
   } else if ( ctlOnlySelection.p_value ) {
      ctlOnlySelection.call_event(ctlsearch,LBUTTON_UP);
   }

}

ctlok.lbutton_up()
{
   _macro('m',_macro('s'));
   if (ctlpreprocess.p_value && ctldefines.p_text!='') {
      _append_retrieve(ctldefines,ctldefines.p_text);
   }

   // check if they wanted to reset selective display first
   if (ctlshowall.p_enabled && ctlshowall.p_value) {
      _macro_call('show_all');
      UserSelDispParent().show_all();
   }

   search_options := "";
   if (ctlsearch.p_value) {
      if (ctlmatchcase.p_value) {
         search_options= '';
      } else {
         search_options='I';
      }
      if (ctlmatchword.p_value) {
         search_options :+= 'W';
      }
      if (ctlre.p_value) {
         switch (ctlre_type.p_text) {
         //case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
         //case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
         case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
         case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
         case RE_TYPE_VIM_STRING:       search_options = search_options'~'; break;
         case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
         }
      }
      if (ctlsearchstring.p_text:!='') {
         if (ctlShowAllMatchedLines.p_value) {
            // resetting show/hide for entire document
            _macro_call('all',ctlsearchstring.p_text,search_options);
            UserSelDispParent().all(ctlsearchstring.p_text,search_options);
         } else if (ctlHideAllMatchedLines.p_value) {
            // resetting show/hide for entire document
            _macro_call('allnot',ctlsearchstring.p_text,search_options);
            UserSelDispParent().allnot(ctlsearchstring.p_text,search_options);
         } else if (ctlHideMoreMatchedLines.p_value) {
            // user is asking to hide additional lines
            _macro_call('less',ctlsearchstring.p_text,search_options);
            UserSelDispParent().less(ctlsearchstring.p_text,search_options);
         } else if (ctlHideMoreUnMatchedLines.p_value) {
            // user is asking to hide additional lines
            _macro_call('lessnot',ctlsearchstring.p_text,search_options);
            UserSelDispParent().lessnot(ctlsearchstring.p_text,search_options);
         } else if (ctlShowMoreMatchedLines.p_value) {
            // user is asking to show additional lines
            _macro_call('more',ctlsearchstring.p_text,search_options);
            UserSelDispParent().more(ctlsearchstring.p_text,search_options);
         }
         _append_retrieve(ctlsearchstring,ctlsearchstring.p_text);
      }
   } else if (ctlshowprocs.p_value) {
      int flags=get_seldisp_flags();
      _macro_call('show_procs',flags);
      UserSelDispParent().show_procs(flags);
   } else if (ctlpreprocess.p_value) {
      warning := "";
      if (!ctlwarning.p_value) {
         warning="-W ";
      }
      _macro_call('preprocess',warning:+ctldefines.p_text);
      UserSelDispParent().preprocess(warning:+ctldefines.p_text);
   } else if (ctlcomments.p_value) {
      _macro_call('hide_all_comments');
      flags := 0;
      if (ctl_doc_comments_checkbox.p_value) {
         flags |= SELDISP_COLLAPSE_DOC_COMMENTS;
      }
      if (ctl_other_comments_checkbox.p_value) {
         flags |= SELDISP_COLLAPSE_OTHER_COMMENTS;
      }
      _macro_call('hide_all_comments',flags);
      UserSelDispParent().hide_all_comments(flags);
   } else if (ctlHideSelection.p_value) {
      _macro_call('hide_selection');
      UserSelDispParent().hide_selection();
   } else if (ctloutline.p_value) {
      limitlevels := "6";
      if (ctlLimit.p_enabled) {
         limitlevels=ctlLimit.p_text;
      }
      if (ctlLowerLimit.p_enabled) {
         limitlevels :+= " "ctlLowerLimit.p_text;
      } else { // use maximum for collapse level
         limitlevels :+= " 63";
      }
      if (ctlbraces.p_value) {
         _macro_call('show_braces',limitlevels);
         UserSelDispParent().show_braces(limitlevels);
      } else if (ctlindent.p_value) {
         _macro_call('show_indent',limitlevels);
         UserSelDispParent().show_indent(limitlevels);
      } else if (ctlsymbols.p_value) {
         _macro_call('show_symbols',limitlevels);
         UserSelDispParent().show_symbols(limitlevels);
      } else if (ctlstatements.p_value) {
         _macro_call('show_statements',limitlevels);
         UserSelDispParent().show_statements(limitlevels);
      }
      if (ctl_outline_doc_comments.p_value || ctl_outline_other_comments.p_value) {
         flags := 0;
         if (ctl_outline_doc_comments.p_value) {
            flags |= SELDISP_COLLAPSE_DOC_COMMENTS;
         }
         if (ctl_outline_other_comments.p_value) {
            flags |= SELDISP_COLLAPSE_OTHER_COMMENTS;
         }
         _macro_call('hide_all_comments',flags);
         UserSelDispParent().hide_all_comments(flags);
      }
   } else if (ctlParagraphs.p_value) {
      _macro_call('show_paragraphs');
      UserSelDispParent().show_paragraphs();
   } else if ( ctlOnlySelection.p_value ) {
      _macro_call('show_only_selection_instances');
      UserSelDispParent().show_only_selection_instances();
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

_command void show_only_selection_instances() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_AB_SELECTION)
{
   filter_init();
   searchStr := "";
   save_pos(auto p);
   numLinesInSearchStr := 0;
   for (;;) {
      status := filter_get_string(auto str);
      if ( status ) break;
      searchStr :+= p_newline:+str;
      ++numLinesInSearchStr;
   }
   deselect();
   top();
   save_pos(auto dohide_start_pos);
   status := search(searchStr,'@h');
   if (status) {
      _beep();
      message(get_message(STRING_NOT_FOUND_RC));
   }
   dohide_all := true;
   for (;;) {
      if (status) bottom();
      if (dohide_all) {
         stopOffset := _QROffset();
         save_pos(auto p2);
         restore_pos(dohide_start_pos);
         if (_default_option('t')) {
            up();
            _lineflags(NEXTLEVEL_LF,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
         }
         for (;;) {
            if ( down()) break;
            _lineflags(HIDDEN_LF|NEXTLEVEL_LF,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
         }
         restore_pos(p2);
      }
      if (status) break;
      up();
      if (!(_lineflags()&HIDDEN_LF)) {
         _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      }
      down();
      for (i:=1;i<=numLinesInSearchStr;++i) {
         if (down()) {
            break;
         }
         _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      }
      _lineflags(PLUSBITMAP_LF,PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF|LEVEL_LF);
      save_pos(dohide_start_pos);
      status=repeat_search();
   }

   maybe_plus_first_line();
}

ctlsearch.lbutton_up()
{
   // find the image control with the corresponding help message
   help_wid := p_active_form._find_control(p_name:+"_help");
   if (help_wid != 0) {
      ctlhelplabel.p_caption = help_wid.p_message :+ "\n\n" :+ ctlhelplabel.p_user;
   } else {
      ctlhelplabel.p_caption = ctlhelplabel.p_user;
   }

   // find the frame that corresponds to the button that was selected 
   ctlsettings.p_visible = true;
   wid := ctlsettings.p_next;
   while (wid != 0 && wid != p_window_id) {
      // watch out for the "When expanding" settings frame
      if (wid.p_name == "ctlexpanding") break;
      // look for the matching frame control
      if (wid.p_name == p_name:+"_frame") {
         ctlsettings.p_visible = false;
         wid.p_y = ctlsettings.p_y;
         wid.p_visible = true;
      } else {
         wid.p_visible = false;
      }
      // next please
      wid = wid.p_next;
   }
}

static int get_seldisp_flags()
{
   seldisp_flags := 0;
   if (ctlshowcomments.p_value) {
      seldisp_flags |= SELDISP_SHOWPROCCOMMENTS;
   } else if (ctlcollapsecomments.p_value) {
      seldisp_flags |= SELDISP_COLLAPSEPROCCOMMENTS;
   }
   if (ctlshowdoccomments.p_value) {
      seldisp_flags |= SELDISP_COLLAPSE_DOC_COMMENTS;
   }
   if (ctlshowothercomments.p_value) {
      seldisp_flags |= SELDISP_COLLAPSE_OTHER_COMMENTS;
   }
   if (ctlshowbodies.p_value) {
      seldisp_flags |= SELDISP_SHOW_PROC_BODIES;
   } else if (ctlcollapsebodies.p_value) {
      seldisp_flags |= SELDISP_COLLAPSE_PROC_BODIES;
   }
   if (ctl_show_all_symbols.p_value) {
      seldisp_flags |= SELDISP_SHOW_OTHER_SYMBOLS;
   }
   if (ctlshowblanklines.p_value) {
      seldisp_flags |= SELDISP_SHOW_BLANK_LINES;
   }
   return(seldisp_flags);
}

struct LEVELINFO {
   int OpenBraceLineNum;
   int PrevLevel;
   int OrigLineFlags;
};
void _ShowLevels(int (*pfnFind)(bool firstfirst,bool &FoundStart),int maxlevel,int minlevel=1)
{
   save_pos(auto p);
   //mou_hour_glass(true);
   //show_all();
   options := "";
   if (p_lexer_name!="") {
      options="xcs";  // Exclude comments and strings
   }
   top();
   if (minlevel <= 0) minlevel=1;
   level := 0;
   LastLineSameLevel := 0;
   LEVELINFO stack[];
   findfirst := true;
   maxlevel=_Index2Level(maxlevel);
   FoundStart := false;
   CloseBraceLineNum := 0;
   OpenBraceLineNum := 0;
   for (;;) {
      //status=search('\{|\}','h@r'options);
      int status=(*pfnFind)(findfirst,FoundStart);
      if (!status && FoundStart) {
         //messageNwait("show_braces: { stlen="stack._length());
         origLineFlags := (_lineflags() & (PLUSBITMAP_LF|MINUSBITMAP_LF|HIDDEN_LF));
         OpenBraceLineNum=p_line;
         p_line=LastLineSameLevel;
         hidden_lf := (origLineFlags & HIDDEN_LF);
         if (stack._length() >= minlevel && !(stack[stack._length()-1].OrigLineFlags & MINUSBITMAP_LF)) {
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
         plevelinfo->OrigLineFlags = origLineFlags;
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
            origLineFlags := stack[stack._length()-1].OrigLineFlags;
            for (;p_line<CloseBraceLineNum;) {
               //messageNwait('level='level' l='p_line);
               if (origLineFlags & (PLUSBITMAP_LF|HIDDEN_LF)) {
                  _lineflags(HIDDEN_LF|level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               } else if (origLineFlags & MINUSBITMAP_LF) {
                  _lineflags(level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               } else if (stack._length() >= minlevel) {
                  _lineflags(HIDDEN_LF|level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               } else {
                  _lineflags(level,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
               }
               if(down()) break;
            }
            p_line=CloseBraceLineNum;
            // End the previous level
            while ((stack._length() && status) || !status) {
               LEVELINFO levelinfo;
               levelinfo=stack[stack._length()-1];
               stack._deleteel(stack._length()-1);
               hidden_lf := (levelinfo.OrigLineFlags & HIDDEN_LF);
               if (stack._length() > minlevel && !(levelinfo.OrigLineFlags & MINUSBITMAP_LF)) {
                  hidden_lf=HIDDEN_LF;
               }

               // IF level number changed for this brace pair AND
               //    there is at least one line inside these braces
               if (levelinfo.PrevLevel!=level &&
                   levelinfo.OpenBraceLineNum+1<CloseBraceLineNum) {
                  orig_line := p_line;
                  p_line=levelinfo.OpenBraceLineNum;
                  //messageNwait('open level='levelinfo.PrevLevel' l='p_line);
                  if (levelinfo.OrigLineFlags & MINUSBITMAP_LF) {
                     _lineflags(MINUSBITMAP_LF|hidden_lf|levelinfo.PrevLevel,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
                  } else if (levelinfo.OrigLineFlags & PLUSBITMAP_LF) {
                     _lineflags(PLUSBITMAP_LF|hidden_lf|levelinfo.PrevLevel,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
                  } else if (minlevel>0 && levelinfo.PrevLevel < _Index2Level(minlevel-1)) {
                     _lineflags(MINUSBITMAP_LF|hidden_lf|levelinfo.PrevLevel,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
                  } else {
                     _lineflags(PLUSBITMAP_LF|hidden_lf|levelinfo.PrevLevel,HIDDEN_LF|LEVEL_LF|PLUSBITMAP_LF|MINUSBITMAP_LF);
                  }
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
      findfirst=false;
   }

   //mou_hour_glass(false);
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
static int _FindBraces(bool findfirst,bool &FoundStart)
{
   if (findfirst) {
      gFindOptions="";
      if (p_lexer_name!="") {
         gFindOptions="xcs";  // Exclude comments and strings
      }
   } else {
      right();
   }
   status := search('\{|\}','h@r'gFindOptions);
   FoundStart=get_text()=='{';
   return(status);
}
static int _FindContext(bool findfirst,bool &FoundStart,bool doStatements=true)
{
   static long statement_stack[];
   static int statement_id;
   static bool returned_start;

   if (findfirst) {
      _UpdateContext(true, false, VS_UPDATEFLAG_context|(doStatements? VS_UPDATEFLAG_statement:0));
      statement_id = 1;
      statement_stack._makeempty();
      returned_start = false;
   }

   // loop until we run out of statements in the current context
   while (statement_id <= tag_get_num_of_context()) {

      statement_start := 0;
      statement_end   := 0;
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, statement_id, statement_start);
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   statement_id, statement_end);

      // do we need to back out a level?
      n := statement_stack._length();
      if (n > 0) {
         last_end := statement_stack[n-1];
         if (last_end < statement_end) {
            _GoToROffset(last_end);
            statement_stack._deleteel(n-1);
            FoundStart = false;
            return 0;
         }
      }

      // starting a new symbol?
      if (!returned_start && statement_start >= _QROffset()) {
         statement_stack[statement_stack._length()] = statement_end;
         _GoToROffset(statement_start);
         FoundStart = true;
         returned_start = true;
         return 0;
      }

      // done with this symbol, next please
      statement_id++;
      returned_start = false;
   }

   // no more symbols, clean up stack and return
   n := statement_stack._length();
   if (n > 0) {
      _GoToROffset(statement_stack[n-1]);
      statement_stack._deleteel(n-1);
      FoundStart = false;
      return 0;
   }
   return STRING_NOT_FOUND_RC;
}
static int _FindStatements(bool findfirst,bool &FoundStart)
{
   return _FindContext(findfirst,FoundStart,true);
}
static int _FindSymbols(bool findfirst,bool &FoundStart)
{
   return _FindContext(findfirst,FoundStart,false);
}

/**
 * Creates nested selective display based on statement tagging.
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
 * @see show_braces 
 * @see show_symbols
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */ 
_command show_statements(_str maxNestLevel="", bool force=true) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   //if (!_haveContextTagging()) {
   //   popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Statement tagging");
   //   return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   //}
   if (!_are_statements_supported()) {
      _message_box(nls("No statement tagging support function for '%s'",p_mode_name));
      return(1);
   }

   // force context tagging to update statements
   if ( force ) {
      _UpdateStatements(true,true);
   }

   parse maxNestLevel with maxNestLevel auto minNestLevel;
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   if (!isinteger(minNestLevel)) minNestLevel=def_seldisp_minlevel;
   _ShowLevels(_FindStatements,(int) maxNestLevel,(int)minNestLevel);
}

/**
 * Creates nested selective display based on context tagging.
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
 * @see show_braces 
 * @see show_statements 
 * @see show_paragraphs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
 */ 
_command show_symbols(_str maxNestLevel="", bool force=true) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_istagging_supported()) {
      _message_box(nls("No tagging support function for '%s'",p_mode_name));
      return(1);
   }

   // force context tagging to update statements
   if ( force ) {
      _UpdateContext(true,true);
   }

   parse maxNestLevel with maxNestLevel auto minNestLevel;
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   if (!isinteger(minNestLevel)) minNestLevel=def_seldisp_minlevel;
   _ShowLevels(_FindSymbols,(int) maxNestLevel,(int)minNestLevel);
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command show_braces(_str maxNestLevel="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   parse maxNestLevel with maxNestLevel auto minNestLevel;
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   if (!isinteger(minNestLevel)) minNestLevel=def_seldisp_minlevel;
   _ShowLevels(_FindBraces,(int) maxNestLevel,(int)minNestLevel);
}
static int gstate;
static int gNewIndent;
static int gStackIndent[];

static int GetNextIndent()
{
   orig_line := p_line;
   if (p_line!=1 /*|| _default_option('t')*/) {
      if(down()) {
         return(0);
      }
   }
   // Skip blank lines
   line := "";
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
static int _FindIndent(bool findfirst,bool &FoundStart)
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
   TopIndent := 0;
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
   line := "";
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
      return(_FindIndent(false,FoundStart));
   }
   NextIndent := 0;
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
         return(_FindIndent(false,FoundStart));
      }
      if (down()) {
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command void show_indent(_str maxNestLevel="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   parse maxNestLevel with maxNestLevel auto minNestLevel;
   if (!isinteger(maxNestLevel)) maxNestLevel=def_seldisp_maxlevel;
   if (!isinteger(minNestLevel)) minNestLevel=def_seldisp_minlevel;
   _ShowLevels(_FindIndent,(int)maxNestLevel,(int)minNestLevel);
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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command void show_paragraphs(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   save_pos(auto p);
   mou_hour_glass(true);
   top();up();
   _lineflags(0,PLUSBITMAP_LF|MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
   if (down()) {
      mou_hour_glass(false);
      restore_pos(p);
      return;
   }
   // Skip blank lines
   status := 0;
   line := "";
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
   mou_hour_glass(false);
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
   idx := 0;
   numElements := regionArray._length();

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
 * @see show_symbols 
 * @see show_statements 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions, Selective_Display_Category
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
   } else {
      // Check for an OEM callback
      // There is a single OEM callback, _oem_hide_regions(), which can then
      // look at p_lexer_name and call subsequent callbacks
      oemCallbackIndex := find_index("_oem_hide_regions",PROC_TYPE);
      if ( oemCallbackIndex ) {
         call_index(p_lexer_name,oemCallbackIndex);
      }
   }
}

int _OnUpdate_hide_dotnet_regions(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (target_wid._isMaybeDotNetCode()) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}

static bool _isMaybeDotNetCode()
{
   if (p_lexer_name == "cpp" || 
       p_lexer_name == "CSharp" || 
       p_lexer_name == "Slick-C" || 
       p_lexer_name == "Visual Basic" ) {
      return true;
   }
   // If we did not hit these cases, check for an OEM callback
   oemCallbackIndex := find_index("_oem_isMaybeDotNetCode",PROC_TYPE);
   if ( oemCallbackIndex ) {
      rv := call_index(p_lexer_name,oemCallbackIndex);
      return rv;
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
   have_pragma_region := hide_block_regions("#pragma region", "#pragma endregion", "P");
   have_dotnet_region := hide_block_regions("#region", "#endregion", "P", false);
   if (have_pragma_region < 0 && have_dotnet_region < 0) {
      message("No region blocks found");
   }
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
 * If the search tags start with a '#', assume it is a preprocessor directive 
 * and allow for spaces after the #. 
 *  
 * An the search tags contain a space, assume that multiple spaces would also 
 * be allowed, so replace the space with an exprssion to match multiple spaces.
 * 
 * @param beginTag      The starting tag to search for (eg "#region")
 * @param endTag        The ending tag to look for (eg "#endregion")
 * @param colorOpts     Color options used for searching. 
 *                      Default is "P" for searching for Preprocessor color
 * @param showAllFirst  Expand all existing selective display first before doing this
 * 
 * @see hide_cppcli_regions
 * @see hide_csharp_regions
 * @see hide_vb_regions
 */
static int hide_block_regions(_str beginTag, _str endTag, _str colorOpts = "P", bool showAllFirst=true)
{
   maxNestLevel := 0;
   int startingLines[];
   startingLines[0] = 0;
   CODEREGION arrRegions[];

   // Save the current position
   save_pos(auto p);

   // We want to begin our search from the start of the file
   top(); up();

   // If the begin tag and/or end tag contains spaces, allow for multiples
   beginTag = stranslate(beginTag, '(:b)', ' ');
   endTag   = stranslate(endTag, '(:b)', ' ');

   // If the begin tag and/or end tag starts with a #, allow for spaces
   if (_first_char(beginTag) == '#') {
      beginTag = "\\# *" :+ substr(beginTag,2);
   }
   if (_first_char(endTag) == '#') {
      endTag = "\\# *" :+ substr(endTag,2);
   }

   // Create the (begin|end) regular expression and search options strings,
   // which will be used as parameters to search()
   regexSearch := "(" :+ beginTag :+ ")|(" :+ endTag :+ ")";
   searchOpts :=  "@hrC" :+ colorOpts;

   findStatus := search(regexSearch, searchOpts);
   while (findStatus == 0) {
      // Get the text of the found match
      word := get_text(match_length(),match_length('S'));

      // Which did we find? start or end?
      if (pos("^":+beginTag:+"$", word, 1, 'r') == 1) {
         // If we found startTag, push the current line number onto the stack
         pushLineNum(startingLines, p_line);
      } else if (pos("^":+endTag:+"$", word, 1, 'r') == 1) {
         // If we found endTag, take the current value for the starting line #
         // off the stack, and get the "nesting level" from the stackSize
         beginLine := popLineNum(startingLines);
         if (beginLine > 0) {
            // We'll skip hiding blocks where the start and end
            // are found on adjacent lines.  We increment beginLine
            // so that the line containing the startTag is visible
            if(p_line > ++beginLine) {
               // How nested is this region block?
               level := stackSize(startingLines);
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

   if (arrRegions._length() > 0) {
      // Invoke the "show-all" command to remove
      // existing selective displays
      if (showAllFirst) {
         show_all();
      }

      // Sort the region structures if we have nested blocks. We want
      // to hide the most-nested levels first so that the code collapsing
      // looks and works correctly
      if (maxNestLevel > 0) {
         sortCodeRegions(arrRegions, maxNestLevel);
      }

      // Walk the array of CODEREGION blocks and hide them
      for (idx := 0; idx < arrRegions._length(); ++idx) {
         CODEREGION rg = arrRegions[idx];
        _hide_lines(rg.startLine, rg.endLine);
      }
   }

   // Restore the saved position
   restore_pos(p);

   // return error if there were no regions found
   return (arrRegions._length() <= 0)? STRING_NOT_FOUND_RC:0;
}


static _str _copy_visible_lines()
{
   int orig_markid=_duplicate_selection('');
   int temp_markid=_duplicate_selection();
   _show_selection(temp_markid);
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   was_line_selection := _select_type()=='LINE';
   was_block_selection := _select_type()=='BLOCK';
   _get_selinfo(auto start_col,auto end_col,auto sel_buf_id,orig_markid);
   temp_buf_id:=p_buf_id;
   p_buf_id=sel_buf_id;
   utf8:=p_UTF8;
   color_flags:=p_color_flags;
   lexer_name:=p_lexer_name;
   p_buf_id=temp_buf_id;
   p_UTF8=utf8;
   p_color_flags=color_flags;
   p_lexer_name=lexer_name;
   if (!was_line_selection) {
      _insert_text('a');
      p_col=0;_delete_text(-2);
   }

   _copy_to_cursor('',VSMARKFLAG_BLOCK_OPERATE_ON_VISIBLE_LINES);
   if (!was_block_selection) {
      top();up();
      while (!down()) {
         if (_lineflags() & HIDDEN_LF) {
            if(!_delete_line()) {
               up();
            }
         } else {
            _lineflags(0, PLUSBITMAP_LF|MINUSBITMAP_LF);
         }
      }
   }
   markflags := -1;
   if (was_block_selection) {
      /*
          This only works on a proportional font block selection if the 
          start and end line are visible.
      */
      _deselect();top();p_col=1;_select_block();
      bottom();p_col=1;_select_block();
      markflags=VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE;
   } else if (!was_line_selection) {
      _deselect();top();_select_char();
      bottom();_select_char();
   } else {
      select_all_line();
   }
   copy_to_clipboard('',markflags);
   _show_selection(orig_markid);
   _free_selection(temp_markid);
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(0);
}


/**
 * Copies currently visible lines only. Does not copy content of 
 * lines that are currently hidden by selective display. 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Clipboard_Functions, Selective_Display_Category 
 */
_command void copy_selective_display() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_READ_ONLY)
{
   _copy_visible_lines();
}
