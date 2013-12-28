////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50682 $
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
#include "color.sh"
#include "diff.sh"
#import "c.e"
#import "clipbd.e"
#import "context.e"
#import "html.e"
#import "listproc.e"
#import "pmatch.e"
#import "seek.e"
#import "seldisp.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/tags/TaggingGuard.e"
#endregion


#define CS_BODYONLY   0                // 1 = select code body only and
                                       //     exclude header
                                       // 0 = select everything

/**
 * Controls the initial amount of code selected by select_code_block
 * Set to 's' to select just one statement initially.
 * Set to 'b' to select entire code block.
 * 
 * @default 's' (statement)
 * @categories Configuration_Variables
 */
typeless def_initial_scope='s';        // 's'=statement, 'b'=block

// def_selcode_cursor_end only supports def_persistent_select=="Y"
// which is used in SlickEdit emulation.
boolean def_selcode_cursor_end=true;

// Used by C++,C, Java, Perl, JavaScript, PHP, and Slick-C
int def_cs_stepback_size_c    = 50000;
int def_cs_stepback_size_plsql = 5000;
static int cs_stepback_size=5000;
static typeless cs_recent_start_line, cs_recent_start_col;
static typeless cs_recent_end_line, cs_recent_end_col;
static typeless cs_recent_sbstart_line, cs_recent_sbstart_col;

static typeless cs_bm_list;
static typeless cs_bm_listcount;

static typeless cs_selected_level;
static typeless cs_selected_sl, cs_selected_sc, cs_selected_el, cs_selected_ec;
static typeless cs_last_target_l, cs_last_target_c;

static typeless cs_ori_position;

static typeless cs_nextBlockToken_ci;
static typeless cs_blockBoundary_ci;
static typeless cs_skipOverBlockStartToken_ci;
static typeless cs_skipOverBlockEndToken_ci;
static typeless cs_findProcBlock_ci;
static typeless cs_procBlockBoundary_ci;

static int cs_lastscope_sl;
static int cs_lastscope_sc;
static int cs_lastscope_el;
static int cs_lastscope_ec;

static _str cs_LangId;

static int cs_lastHiddenBlock_sl;
static int cs_lastHiddenBlock_el;


static typeless oc_nextBlock_ci;
static int gocFirstStructuredSpecial = 0;


/**
 * Selects lines in current code block.  The definition of the current block 
 * depends on the language.  Invoking this command from a key, menu, 
 * or button bar multiple times in succession selects larger code blocks.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 * @return 0 for OK, 1 for error.
 */ 
_command int select_code_block()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // More modern language-specific support.
   selCodeProc := _FindLanguageCallbackIndex('selectCodeBlock_%s');
   if (selCodeProc) {
      status := call_index(selCodeProc);
      return(status);
   }

   // If current selection not in same file, deselect it:
   int start_col=0, end_col=0, buf_id=0;
   if (!_get_selinfo(start_col,end_col,buf_id)) {
      if (buf_id!=p_buf_id) {
         _deselect();
      }
   }

   // Check to see if the same command was executed last time:
   boolean same_command = 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == 'select-code-block' || name == 'select-toggle' ) same_command = 1;
   //say( 'name='name' same_command='same_command );

   // Remember the position:
   save_pos( cs_ori_position );

   int old_def_pmatch_max_diff=def_pmatch_max_diff;
   def_pmatch_max_diff=1000000;

   // If the following conditions are satisfied, a selection currently exists.
   //    -- Selection exists
   //    -- Selection starting and ending corresponds to last known code
   //          block selection
   //    -- Caret position has not changed since last selection

   // If a selection currently exists and the same command was executed last
   // time, expand its scope.Otherwise, start a new code block selection.
   status := 0;
   if ( cs_selection_exists() && same_command ) {
      status = cs_expand_codeblock( CS_BODYONLY, def_initial_scope );
   } else {
      status = cs_select_newcodeblock( CS_BODYONLY, def_initial_scope, 1 );
   }
   if ( status ) restore_pos( cs_ori_position );

   // Restore old paren matching limits:
   def_pmatch_max_diff=old_def_pmatch_max_diff;

   // Move caret to the end of the selection:
   //restore_pos( old_position );
   if (!status) {
      _end_select();
      if (def_persistent_select=="Y") {
         // Lock the selection.
         int first_col=0, last_col=0;
         _get_selinfo(first_col,last_col,buf_id);
         if ( p_buf_id==buf_id ) {
            select_it(_select_type(),'',_select_type('','I'):+def_advanced_select);
         }
         if (def_selcode_cursor_end) {
            _begin_select();
         }
      }
   }
   // Make this the very last command:
   last_index( find_index( 'select-code-block', COMMAND_TYPE ), 'C' );
   return( status );
}

int _OnUpdate_select_code_block(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }

   // Determine which language:
   _str real_extension="";
   _str lang = cs_getExtension( real_extension );

   // Special case for HTML:
   if (lang == "html" || lang == "htm" || _LanguageInheritsFrom("xml", lang)) {
      return(MF_ENABLED);
   }

   // Init the call index for specific extension:
   if ( !_FindLanguageCallbackIndex( 'cs_%s_nextBlockToken',lang ) ) return( MF_GRAYED );
   if ( !_FindLanguageCallbackIndex( 'cs_%s_blockBoundary',lang ) ) return( MF_GRAYED );
   if ( !_FindLanguageCallbackIndex( 'cs_%s_skipOverBlockStartToken',lang ) ) return( MF_GRAYED );
   if ( !_FindLanguageCallbackIndex( 'cs_%s_skipOverBlockEndToken',lang ) ) return( MF_GRAYED );
   // Special cases here...
   if ( real_extension == 'java' || real_extension == 'jav' || real_extension == 'cs' ) {
      if ( !find_index( 'cs_java_findProcBlock', PROC_TYPE ) ) return( MF_GRAYED );
   } else {
      if ( !_FindLanguageCallbackIndex( 'cs_%s_findProcBlock',lang ) ) return( MF_GRAYED );
   }
   if ( !_FindLanguageCallbackIndex( 'cs_%s_procBlockBoundary',lang ) ) return( MF_GRAYED );

   return(MF_ENABLED);
}

// Desc:  Hide the body of the code block.
// Retn:  0 for OK, 1 for error.
int cs_hide_code_block( int expandBlock )
{
   // If current selection not in same file, deselect it:
   int start_col=0, end_col=0, buf_id=0;
   if (!_get_selinfo(start_col,end_col,buf_id)) {
      if (buf_id!=p_buf_id) {
         _deselect();
      }
   }

   // Remember the position:
   save_pos( cs_ori_position );

   int old_def_pmatch_max_diff=def_pmatch_max_diff;
   def_pmatch_max_diff=1000000;

   // Once a code block is hidden, the caret is placed on the first line
   // of the code block.  If the last command is the same, the last scope
   // will be expanded.  If the last command is not the same, a new scope
   // is selected.  It is possible that this new scope is already selected
   // and is hidden, and therefore, will be reselected and rehidden without
   // any visual cues to the user.  A second execution of the hide-code-block
   // command is needed to expand the current scope.  The side effect is that
   // the user has to click hide-code-block twice.

   // If a selection currently exists and the same command was executed last
   // time, expand its scope.  Otherwise, start a new code block selection.
   typeless status=0;
   if ( cs_selection_exists2() && expandBlock ) {
      //messageNwait("Moving outside last scope" );
      _str lang = p_LangId;
      if (_LanguageInheritsFrom("plsql",lang)) {
         /*
         int oldline, oldseekpos;
         oldseekpos = _nrseek();
         oldline = p_line; p_col = 1;
         status = search("begin","r@iHCK");
         if (!status && p_line == oldline && p_col == 1) { // Already at the first column... Try the
                                                           // outer block from previous select_code_block()
            //_nrseek(oldseekpos);
            //messageNwait("expand existing");
            status = cs_expand_codeblock(1, "b");
         } else {
            // Starting from column 1 of current line will hide the block containing the line.
            _nrseek(oldseekpos);
            p_col = 1;
            //messageNwait("new larger scope");
            status = cs_select_newcodeblock( 1, 'b', 0 );
            //messageNwait("new larger scope status="status);
         }
         */

         // Loop to find the next code block whose body includes the
         // previous code block. For PL/SQL, a newly expanded code block's
         // body may be the same as that of the previous block.
         int found;
         found = 0;
         status = 0;
         while (!found && !status) {
            status = cs_expand_codeblock(1, "b");
            //messageNwait("cs_hide_code_block expanding status="status);
            if (status) break;
            if (!cs_isSameAsLastHiddenBlock()) {
               // Scan thru selection and show all hidden lines:
               cs_saveLastHiddenBlock();
               cs_showHiddenLinesInSelection();
               found = 1;
            }
         }
      } else {
         p_line = cs_lastscope_sl - 1;
         status = cs_select_newcodeblock( 1, 'b', 0 );

         // Scan thru selection and show all hidden lines:
         if (!status) {
            cs_saveLastHiddenBlock();
            cs_showHiddenLinesInSelection();
         }
      }
   } else {
      //say( "New scope" );
      //messageNwait("cs_hide_code_block New scope h1");
      status = cs_select_newcodeblock( 1, 'b', 0 );
      //messageNwait("cs_hide_code_block h2");

      // Scan thru selection and show all hidden lines:
      if (!status) {
         cs_saveLastHiddenBlock();
         cs_showHiddenLinesInSelection();
      }
   }
   if ( status ) restore_pos( cs_ori_position );
   //messageNwait("cs_hide_code_block h1 status="status);

   // Restore old paren matching limits:
   def_pmatch_max_diff=old_def_pmatch_max_diff;

   // Move caret to the end of the selection:
   //restore_pos( old_position );
   if (!status) _end_select();
   //messageNwait("cs_hide_code_block h2 status="status);
   return( status );
}

// Desc: Save the last hidden block start and end lines.
static void cs_saveLastHiddenBlock()
{
   typeless ori_position;
   save_pos(ori_position);
   _begin_select();
   cs_lastHiddenBlock_sl = p_line;
   _end_select();
   cs_lastHiddenBlock_el = p_line;
   restore_pos(ori_position);
}

// Desc: Check the current selection against the previous hidden block.
//       If both have the same start and end lines, the blocks are the same.
//       This situation can occurs for language lile PL/SQL when expanding a
//       block may not expand the block body.
//       Ex:  if HELLOTHEREISTRUE then  <--+   <--+
//               doThis;                   |      |
//               doThis;                <--+      |
//            end if;                          <--+
// Retn: 1 for same block, 0 not
static int cs_isSameAsLastHiddenBlock()
{
   int count;
   count = 0;
   typeless ori_position;
   save_pos(ori_position);
   _begin_select();
   if (cs_lastHiddenBlock_sl == p_line) {
      count++;
   }
   _end_select();
   if (cs_lastHiddenBlock_el == p_line) {
      count++;
   }
   restore_pos(ori_position);
   if (count == 2) {
      return(1);
   }
   return(0);
}

// Desc: Scan through the selection and show all the hidden lines.
//       There is a limitation in hide_selection() and it can not combine
//       new lines into a hidden code block located right above the new line.
//
//       If the selection block contains hidden lines and the hidden lines
//       shares the same + bitmap with the selection (to be hidden), show the
//       hidden lines and clear the hidden line bitmap.
static void cs_showHiddenLinesInSelection()
{
   typeless ori_position;
   save_pos(ori_position);

   // Check to see if selection block contains hidden lines and that those
   // line share the same bitmap with the selection.
   int blockHasBitmap;
   blockHasBitmap = 0;
   _begin_select();
   if (up()) {
      restore_pos(ori_position);
      return;
   }
   if (_lineflags() & PLUSBITMAP_LF) {
      blockHasBitmap = 1;
   }
   if (!blockHasBitmap) {  // No shared bitmap... Do nothing.
      restore_pos(ori_position);
      return;
   }

   // Find the start and line lines of the selection:
   int start_line, end_line;
   _begin_select();
   start_line = p_line;
   _end_select();
   end_line = p_line;

   // Scan thru the list of selected lines and make hidden lines
   // visible.
   int flags, level;
   p_line = start_line;
   while (1) {
      flags = _lineflags();
      level = flags & LEVEL_LF;
      //messageNwait("Found hidden lines p_line="p_line" level="level);
      if (flags & HIDDEN_LF) {
         _lineflags(0, HIDDEN_LF);
         _lineflags(0, LEVEL_LF);
      }
      if (p_line == end_line) break;
      p_line = p_line + 1;
   }

   // Turn off block bitmap:
   _begin_select();
   up();
   if (_lineflags() & PLUSBITMAP_LF) {
      _lineflags(0,PLUSBITMAP_LF);
   }
   restore_pos(ori_position);
}


#if 0
// Desc:  Hide the body of the code block.
// Retn:  0 for OK, 1 for error.
int cs_hide_code_block()
{
   // Re-init stuff:
   cs_init();

   // Remember the position:
   save_pos( cs_ori_position );

   // Save current paren matching limit:
   old_def_pmatch_max_diff=def_pmatch_max_diff;
   def_pmatch_max_diff='1000000';

   // Select code block:
   status = cs_select_newcodeblock( 1, 'b', 0 );

   // Restore old paren matching limits:
   def_pmatch_max_diff=old_def_pmatch_max_diff;

   // Restore original position:
   restore_pos( cs_ori_position );
   return( status );
}
#endif


// Desc:  Select a new code block.
// Retn:  0 for OK, 1 for error.
static int cs_select_newcodeblock( boolean bodyonly, _str mode, boolean always_select )
{
   // Re-init stuff:
   int level = 0;
   boolean found = 0;
   typeless status=cs_init();
   if (status) return(status);

   // Special case for HTML:
   // HTML is drastically different from other structured languages that
   // we can't use the normal code path for selecting and hiding code
   // blocks.
   if (_LanguageInheritsFrom("html", cs_LangId) || _LanguageInheritsFrom("xml", cs_LangId)) {
      int startLine, startCol, endLine, endCol;
      if (htool_selecttag2(startLine, startCol, endLine, endCol) < 0) {
         message( "Unable to determine code block." );
         return(1);
      }
      cs_select_codetext( bodyonly, '-', startLine, startCol, endLine, endCol,
               startLine, startCol, 0, startLine, startCol );
      return(0);
   }

   // Set up the caret target position:
   int target_line = p_line; 
   int target_col = p_col;

   // Determine the start of the proc block:
   typeless sl=0, sc=0, el=0, ec=0;
   status = cs_findProcBlock( sl, sc, el, ec );
   if ( status ) {
      // Select current line:
      restore_pos( cs_ori_position );
      if ( always_select ) {
         cs_select_text( 'l', p_line, p_col, p_line, p_col );
      }
      return( 1 );
   }

   // Fix the target column. The target column may be
   // before the proc start column in the case where the block keyword
   // is preceeded by other complementary words. Adjust the target column
   // to be within the block start column (if on the same line).
   if (target_line == sl && target_col < sc) {
      target_col = sc;
   }

   // List all code blocks:
   p_line = sl; p_col = sc;
   //messageNwait("cs_select_newcodeblock start="sl' 'sc' end='el' 'ec);
   cs_list_all_codeblocks( level, mode, bodyonly, sl, sc, el, ec,
            target_line, target_col, found );
   return( 0 );
}


// Desc:  A code selection has already been made.  Expand the scope of the
//     selection to the higher level.  If the code block is already at the
//     top level (ie. the proc itself), select the entire file.
// Retn:  0 for OK, 1 for error.
static int cs_expand_codeblock( boolean bodyonly, _str mode )
{
   int level = cs_selected_level - 1;

   // Special case for HTML:
   if (_LanguageInheritsFrom("html", cs_LangId) || _LanguageInheritsFrom("xml", cs_LangId)) {
      int startLine, startCol, endLine, endCol;
      if (htool_expandsel(startLine, startCol, endLine, endCol) < 0) {
         message( "Unable to further expand code block." );
         return(1);
      }
      cs_select_codetext( bodyonly, '-', startLine, startCol, endLine, endCol,
               startLine, startCol, 0, startLine, startCol );
      return(0);
   }

   // If selection is at top level (level 0), select the entire file:
   //say( 'cs_expand_codeblock' );
   typeless target_line = cs_last_target_l; 
   typeless target_col = cs_last_target_c;
   if ( cs_selected_level == 0 ) {
      bottom();
      cs_select_codetext( 0, '-', 1, 1, p_line, p_col, 0, 0, 0,
               target_line, target_col );

      // Reset selection level so that next selection restart from fresh:
      cs_selected_level = -1;
      return( 0 );
   }

   // Get the next higher level code block:
   typeless cbs_line=0, cbs_col=0;
   typeless cbe_line=0, cbe_col=0;
   typeless sbs_line=0, sbs_col=0;
   if ( cs_get_bm( level, cbs_line, cbs_col, cbe_line, cbe_col,
            sbs_line, sbs_col ) ) {
      message( "Can't find code block selection marker." );
      return( 1 );
   }
   //say( 'level='level' 'cbs_line',' cbs_col',' cbe_line',' cbe_col',' sbs_line',' sbs_col );

   // Select code inside new scope:
   cs_save_recent_selection_info( cbs_line, cbs_col, cbe_line, cbe_col,
              sbs_line, sbs_col );
   //messageNwait(cbs_line" "cbs_col" "cbe_line" "cbe_col);
   cs_select_codetext( bodyonly, '-', cbs_line, cbs_col, cbe_line, cbe_col,
            sbs_line, sbs_col, level, target_line, target_col );
   return( 0 );
}


// Desc:  Recurse and list all code blocks.
// Para:  mode               Selection mode:
//                              's' -- Statement only
//                              'b' -- Entire block
//        bodyonly           Flag: 1 = block body only
// Retn:  0 for OK, 1 for error.
static int cs_list_all_codeblocks( int level, _str mode, boolean bodyonly, 
                                   int bbsl, int bbsc, int bbel, int bbec,
                                   int target_line, int target_col, boolean &found )
{
   // If target position is not inside scope, do nothing:
   if ( found || target_line < bbsl || target_line > bbel ) return( 0 );

   // Find next code block:
   //messageNwait("cs_list_all_codeblocks hh1");
   typeless status=0;
   for(;;) {
      // If at end or outside current scope, stop:
      if ( !cs_is_withinbounds( p_line, p_col, bbsl, bbsc, bbel, bbec ) ) break;
      status = cs_nextBlockToken( bbel, bbec );
      //messageNwait("cs_nextBlockToken status="status);
      if ( status == '' ) {
         if (!level) {
            return(1);
         }
         //messageNwait(cs_recent_start_line","cs_recent_start_col","cs_recent_end_line","cs_recent_end_col);
         cs_select_codetext( bodyonly, '-', cs_recent_start_line, cs_recent_start_col,
                  cs_recent_end_line, cs_recent_end_col,
                  cs_recent_sbstart_line, cs_recent_sbstart_col,
                  level-1, target_line, target_col );
         found = 1;
         break;
      }
      if ( !cs_is_withinbounds( p_line, p_col, bbsl, bbsc, bbel, bbec ) ) break;

      // If target is somewhere in between code block, select the recent block
      // and done:
      if ( cs_is_withinbounds( target_line, target_col,
               bbsl, bbsc, p_line, p_col - 1 ) ) {
         cs_select_codetext( bodyonly, '-', cs_recent_start_line, cs_recent_start_col,
                  cs_recent_end_line, cs_recent_end_col,
                  cs_recent_sbstart_line, cs_recent_sbstart_col,
                  level-1, target_line, target_col );
         found = 1;
         break;
      }

      // Determine block boundary:
      // Special case for level 0 (ie. proc block).
      //messageNwait( 'level='level );
      typeless sbtype=0;
      typeless cbstart_line=0, cbstart_col=0;
      typeless cbend_line=0, cbend_col=0;
      typeless sbstart_line=0, sbstart_col=0;
      if ( level == 0 ) {
         //messageNwait( 'proc... h1' );
         sbtype = cs_procBlockBoundary( cbstart_line, cbstart_col, cbend_line,
                  cbend_col, sbstart_line, sbstart_col );
         //messageNwait( 'proc... h2' );
      } else {
         //messageNwait( 'block... h3' );
         sbtype = cs_blockBoundary( cbstart_line, cbstart_col, cbend_line,
                  cbend_col, sbstart_line, sbstart_col );
         //messageNwait( 'block... h4' );
      }
      //messageNwait("sbtype="sbtype" sbstart_*="sbstart_line" "sbstart_col);
      //messageNwait( 'h2 sbtype='sbtype );
      //say( 'level 'level': cb start='cbstart_line' 'cbstart_col', end='cbend_line' 'cbend_col', sb start='sbstart_line' 'sbstart_col );
      if ( !cs_is_withinbounds( p_line, p_col, bbsl, bbsc, bbel, bbec ) ) {
         //say( "sub-block not within bounds" );
         break;
      }
      if ( sbtype == '' ) break;

      // Check to see if target is inside block:
      boolean inside_subblock = 0;
      if ( cs_is_withinbounds( target_line, target_col,
               cbstart_line, cbstart_col, cbend_line, cbend_col ) ) {
         inside_subblock = 1;
      }
      //messageNwait("inside_subblock="inside_subblock" sbtype="sbtype);

      // Goto next subblock:
      if ( sbstart_line ) {
         // Block with { }
         if ( inside_subblock ) {
            // Save this code block:
            //messageNwait(cbstart_line", "cbstart_col", "cbend_line", "cbend_col", "sbstart_line", "sbstart_col);
            cs_save_recent_selection_info( cbstart_line, cbstart_col,
                      cbend_line, cbend_col, sbstart_line, sbstart_col );

            // Add block marker into a list:
            cs_add_bm( level, cs_recent_start_line, cs_recent_start_col,
                     cs_recent_end_line, cs_recent_end_col,
                     cs_recent_sbstart_line, cs_recent_sbstart_col );

            // If target between keyword and block body, select block:
            if (sbtype == "proto" || cs_is_withinbounds( target_line, target_col,
                     cbstart_line, cbstart_col, sbstart_line, sbstart_col ) ) {
               //messageNwait("b1 "cs_recent_start_line" "cs_recent_start_col" "cs_recent_end_line" "cs_recent_end_col", "cs_recent_sbstart_line" "cs_recent_sbstart_col", "level" "target_line" "target_col);
               cs_select_codetext( bodyonly, '-', cs_recent_start_line, cs_recent_start_col,
                        cs_recent_end_line, cs_recent_end_col,
                        cs_recent_sbstart_line, cs_recent_sbstart_col,
                        level, target_line, target_col );
               found = 1;
               break;
            }

            // Traverse this block:
            //messageNwait("before cs_skipOverBlockStartToken");
            cs_skipOverBlockStartToken( sbstart_line, sbstart_col, sbtype );
            //messageNwait("after skip");
            //messageNwait("before recurse");
            cs_list_all_codeblocks( level + 1, mode, bodyonly,
                     sbstart_line, sbstart_col,
                     cbend_line, cbend_col, target_line, target_col, found );
            p_line = cbend_line; p_col = cbend_col;
            //messageNwait("after recurse found="found);
            cs_skipOverBlockEndToken( sbstart_line, sbstart_col, sbtype );
            if ( found ) break;
         } else {
            // Subblock exists but not containing caret...
            // Skip over block:
            p_line = cbend_line; p_col = cbend_col;
            cs_skipOverBlockEndToken( sbstart_line, sbstart_col, sbtype );
         }
      } else {
         // Block terminated with ;
         // If target is inside subblock, found block:
         if ( inside_subblock ) {
            if ( mode == 'b' || mode == 'B' ) {
               //messageNwait("a1 "cs_recent_start_line" "cs_recent_start_col" "cs_recent_end_line" "cs_recent_end_col", "cs_recent_sbstart_line" "cs_recent_sbstart_col", "level-1" "target_line" "target_col);
               cs_select_codetext( bodyonly, '-', cs_recent_start_line, cs_recent_start_col,
                        cs_recent_end_line, cs_recent_end_col,
                        cs_recent_sbstart_line, cs_recent_sbstart_col,
                        level-1, target_line, target_col );
            } else {
               cs_select_codetext( bodyonly, '-', cbstart_line, cbstart_col,
                        cbend_line, cbend_col, 0, 0,
                        level, target_line, target_col );
            }
            found = 1;
            break;
         }

         // Skip over the terminating ;.
         typeless seek_pos = _nrseek();
         _nrseek( seek_pos + 1 );
      }
   }
   return( 0 );
}


// Desc:  Determine the boundary of the code block.  The caret must be at the
//     start of a keyword.
// Retn:  0 for OK, 1 for error.
static int cs_blockBoundary( int &start_line, int &start_col,
                             int &end_line,   int &end_col, 
                             int &sbstart_line, int &sbstart_col )
{
   rc = call_index( start_line, start_col, end_line, end_col,
            sbstart_line, sbstart_col, cs_blockBoundary_ci );
   return( rc );
#if 0
   // Determine which language:
   lang = cs_getExtension( real_extension );

   // Get the apropriate proc:
   //index = find_index( 'cs_'ext'_blockBoundary', PROC_TYPE );
   if ( cs_getCallIndex( "cs_blockBoundary", lang, index ) ) return( 1 );
   if ( index_callable( index ) ) {
      rc = call_index( start_line, start_col, end_line, end_col,
               sbstart_line, sbstart_col, index );
      return( rc );
   }
   return( 1 );
#endif
}


// Desc:  C.  Determine the boundary of the code block.  The caret must be at the
//     start of a keyword.
// Retn:  block type for OK, '' for error.
int cs_c_blockBoundary( int &start_line, int &start_col,
                        int &end_line,   int &end_col, 
                        int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;

   // Skip over keyword:
   // If no keyword, do nothing.
   start_line = p_line; start_col = p_col;
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();

   // Locate ; or {
   typeless ch = cs_c_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc:  Pascal.  Determine the boundary of the code block.  The caret
//     must be at the start of a keyword.
// Retn:  block type for OK, '' for error.
int cs_pas_blockBoundary( int &start_line, int &start_col,
                          int &end_line,   int &end_col, 
                          int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;

   // Skip over keyword:
   // If no keyword, do nothing.
   typeless ch="";
   start_line = p_line; start_col = p_col;
   int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
   if ( type == CFG_KEYWORD ) {
      // Special case for 'repeat'...   'repeat' is paired with 'until'.  Treat
      // 'repeat' as a block start marker and don't skip over it.
      ch = get_text( 3 ); ch = lowcase( ch );
      if ( ch != 'rep' && ch != 'cas' ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
      }
   }

   // Locate ;, begin, class, record, repeat
   ch = cs_pas_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc: PL/SQL.  Determine the boundary of the code block.  The caret
//       must be at the start of a keyword.
// Retn:  block type for OK, '' for error.
_str cs_plsql_blockBoundary( int &start_line, int &start_col,
                             int &end_line,   int &end_col, 
                             int &sbstart_line, int &sbstart_col )
{
   // Init:
   _str ch, ch4;
   sbstart_line = 0; sbstart_col = 0;

   // Skip over keyword:
   // If no keyword, do nothing.
   typeless status=0;
   start_line = p_line; start_col = p_col;
   int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
   word_chars := _clex_identifier_chars();
   if ( type == CFG_KEYWORD ) {
      // Special case for "if"... "if" is paired with "end if".
      // Treat "if" as a block marker and don't skip over it.
      ch = get_text(2); ch = lowcase(ch);
      ch4 = get_text(4); ch4 = lowcase(ch4);
      if (ch != "if" && ch4 != "loop" && ch4 != "begi" && ch4 != "pack" &&
          ch4 != "decl" && ch4 != "exce" && ch4 != "else") {
         cs_skipKeyword();
      }

      // Special case for "declare", "function", "procedure", "exception",
      // "when".
      // Can't have "package" here because "package" can't be nested.
      if (ch4 == "decl") {
         // Skip over the "declare" keyword:
         status = search("[~"word_chars"]|$","r@iHXCS");
         if (status) return("");
         sbstart_line = p_line; sbstart_col = p_col;

         // "declare" block starts right after the "declare" keyword.
         // Locate the "begin":
         status = cs_plsql_next_begin("", 1);
         if (status) return("");

         // Locate the matching "end":
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return("");
         cs_nextSemicolon();
         end_line = p_line; end_col = p_col;
         return("decl");
      } else if (ch4 == "proc" || ch4 == "func") {
         // If proto, skip over it:
         sbstart_line = p_line; sbstart_col = p_col;
         if (cs_plsql_is_proto()) {
            //messageNwait("PROTO");
            end_line = p_line; end_col = p_col;
            return("proto");
         }

         // For procedure/function, the block starts right after the
         // "is" or "as":
         status = search("is|as","rw@iHCK");
         if (status) return("");
         sbstart_line = p_line; sbstart_col = p_col;

         // Locate the "begin":
         status = cs_plsql_next_begin("", 1);
         if (status) return("");

         // Locate the matching "end":
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return("");
         cs_nextSemicolon();
         end_line = p_line; end_col = p_col;
         return("proc");
      } else if (ch4 == "exce") { // "exception"
         /*
            declare
              ...
            begin
              ...
            exception
              ...
            end;
         */
         // Skip over the "exception" keyword:
         status = search("[~"word_chars"]|$","r@iHXCS");
         if (status) return("");
         sbstart_line = p_line; sbstart_col = p_col;

         // Locate the end of the exception block:
         status = cs_plsql_exceptionBlockBoundary();
         if (status) return("");
         end_line = p_line; end_col = p_col;
         return("exce");
      } else if (ch4 == "when") {  // "when" of "exception"
         /*
            exception
               when NODATA1
                  statements;
               when NODATA2
                  statements;
               when others
                  statements;
            end;
         */
         // "when" block starts right after the "then" keyword:
         status = search("then","rw@iHCK");
         if (status) return("");
         status = search("[~"word_chars"]|$","r@iHXCS");
         if (status) return("");
         sbstart_line = p_line; sbstart_col = p_col;

         // Locate the end of the "when" block:
         status = cs_plsql_whenBlockBoundary();
         if (status) return("");
         end_line = p_line; end_col = p_col;
         return("when");
      }
   }

   // Locate ;, begin, loop, if
   ch = cs_plsql_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );
   return( ch );
}

// Desc: Determine the end of the "exception" block.
// Retn: 0 OK, !0 error
static int cs_plsql_exceptionBlockBoundary()
{
   int oldLine, oldCol;
   oldLine = p_line; oldCol = p_col;

   // Find matching "end"
   int status;
   status = cs_plsql_next_end();
   if (status) return(1);

   // Trace back to the previous ";"
   int newline;
   newline = p_line;
   status = search(";","-r@iHXCS");
   if (status) return(1);

   // Some bad PL/SQL code... block without any statement.
   if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
      p_line = newline - 1;
   }
   return(0);
}

// Desc: Find the matching "end" for the block.
// Retn: 0 OK, !0 not found
static int cs_plsql_next_end()
{
   while (1) {
      int status;
      status = search("end|else|elsif|if|loop|begin", "rw@iHCK");
      if (status) return(1);
      _str ch;
      ch = lowcase(get_text(2));
      if (ch == "en" || ch == "el") {
         return(0);
      } else {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }
   }
   return(0);
}

// Desc: Determine the end of the "when" block.
//       Then "when" block ends with:
//          1. the start of another "when" block
//          2. "end" of the "exception" block
// Retn: 0 OK, !0 error
static int cs_plsql_whenBlockBoundary()
{
   int oldLine, oldCol;
   oldLine = p_line; oldCol = p_col;

   while (1) {
      int status;
      status = search("end|when|if|loop|begin", "rw@iHCK");
      if (status) return(1);
      _str ch;
      ch = lowcase(get_text(2));
      if (ch == "en" || ch == "wh") {
         // We are a little over... Back up to the previous semicolon.
         int newline;
         newline = p_line;
         status = search(";","-r@iHXCS");
         if (status) return(1);
         // Some bad PL/SQL code... block without any statement.
         if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
            p_line = newline - 1;
         }
         return(0);
      } else {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }
   }
   return(0);
}

// Desc:  Awk.  Determine the boundary of the code block.
// Retn:  block type for OK, '' for error.
int cs_awk_blockBoundary( int &start_line, int &start_col,
                          int &end_line,   int &end_col, 
                          int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;
   start_line = p_line; start_col = p_col;

   // Locate ;, begin, record, repeat, if, while, for, case
   typeless ch = cs_awk_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc:  Locate the next ';', { and its matching }.  If statement is not
//     bounded by {} and is not semicolon-terminated, it is assumed to be
//     terminated by a newline.
//
// Retn:  ';', 'n' for newline, '{', or '' if neither is found.
static typeless cs_awk_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   boolean found = 0;
   while ( !found ) {
      if ( ch == '(' ) {
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( '' );
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      } else if ( ch == '{' ) {
         sbstart_line = p_line; sbstart_col = p_col;
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( '' );
         return( '{' );
      } else if ( ch == ';' ) {
         return( ';' );
      }

      // Check and jump over keywords:
      //    keywords= if while for do break continue next exit return print
      //    keywords= delete else function
      //    keywords= BEGIN END
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 2 ); ch = lowcase( ch );
         // 'if', 'for', and 'while' may have one statement following without
         // the need to enclose code in { }.  The statement follwing these
         // commands must be terminated by ';' or '\n'.
         //
         if ( ch == 'if' || ch == 'fo' || ch == 'wh' ) {
            // Skip over the paren and goto the start of the sub-statement:
            if ( cs_awk_next_openParen( 1 ) ) return( '' );
            if ( _find_matching_paren(def_pmatch_max_diff) ) return( '' );
            seek_pos = _nrseek() + 1;
            if ( _nrseek( seek_pos ) == '' ) return( '' );
            if ( cs_skipSpaces() == -1 ) return( '' );

            // Find the end of the statement:
            rc = cs_awk_nextEOLN( 1 );
            if ( rc == '' ) return( '' );
            else if ( rc == ';' ) return( ';' );
            else if ( rc == 'n' ) return( 'n' );
            else continue;
         }
      }

      // Skip over comment and string:
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         int status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         rc = cs_awk_nextEOLN( 1 );
         if ( rc == '{' ) continue;
         return( rc );
      }

      // Skip over alphanumeric characters to EOLN:
      if ( isalnum( ch ) || ( ch >= '!' && ch <= '@' ) ) {
         rc = cs_awk_nextEOLN( 1 );
         if ( rc == '{' ) continue;    // Continue and try to match with '}'
         if ( rc == '}' ) {
            // Bad place to get an '}' ...  Must be that of the immediately
            // outer scope.  Use this '}' as the termination character for
            // current statement.
            //messageNwait( 'got }' );
            p_col = p_col - 1;
            return( 'n' );
         }
         return( rc );
      }

      // No comment or string, advance to next character:
      seek_pos=seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Locate the next ; or { or }
// Retn:  ';', '{', '}', or '' if neither is found.
static typeless cs_c_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   if ( cs_skipSpaces() == -1 ) return( '' );
#if 0
   seek_pos = _nrseek();
   ch = get_text();
   found = 0;
   while ( !found ) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         sbstart_line = p_line; sbstart_col = p_col;
         status = _find_matching_paren(def_pmatch_max_diff);
         if ( cs_isCurlyCodeBlock( sbstart_line, sbstart_col,
                  p_line, p_col ) ) return( '{' );
      }
      if ( ch == ';' ) {
         return( ';' );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
#else
   typeless status=search("[({};]","ri@H");
   for (;;) {
      if (status) return('');
      // Skip over comment and string:
      int type=_clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status=repeat_search();
         continue;
      }
      _str ch=get_text();
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         status=repeat_search();
         continue;
      }
      if ( ch == '{' ) {
         sbstart_line = p_line; sbstart_col = p_col;
         status = _find_matching_paren(def_pmatch_max_diff);
         if ( cs_isCurlyCodeBlock( sbstart_line, sbstart_col,
                  p_line, p_col ) ) return( '{' );
      }
      if ( ch == '}' ) return( '}' );
      if ( ch == ';' ) return( ';' );
      status=repeat_search();
   }
   return( '' );
#endif
}


// Desc:  Locate the next ;, or begin, class, record, repeat, case and their
//     matching block markers.
//
//     ;
//     begin <==> end
//     class <==> end
//     record <==> end
//     repeat <==> until
//     case <==> end
// Retn:  ';', begin, class, record, repeat, or '' if neither is found.
static typeless cs_pas_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless seek_pos = _nrseek();
   typeless status = 0;
   int type=0;
   _str ch = get_text(); ch = lowcase( ch );
   boolean found = 0;
   while ( !found ) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'b' ) {               // begin
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = _find_matching_paren(def_pmatch_max_diff);
            if ( status ) return( '' );
            return( 'begin' );
         }
      } else if ( ch == 'c' ) {        // class, case
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'cl' ) {           // class
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               // 'class' begin block marker must not be semicolon terminated:
               if ( !cs_is_semicolonTerminated() ) {
                  status = cs_pas_findNextEnd();
                  if ( status ) return( '' );
                  return( 'class' );
               }
            }
         } else if ( ch == 'ca' ) {    // case
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'case' );
            }
         }
      } else if ( ch == 'r' ) {        // record or repeat
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 're' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               // 'record' and 'repeat' begin block marker must not be
               // semicolon terminated:
               if ( !cs_is_semicolonTerminated() ) {
                  ch = get_text( 3 ); ch = lowcase( ch );
                  if ( ch == 'rec' ) {
                     status = cs_pas_findNextEnd();
                     if ( status ) return( '' );
                     return( 'record' );
                  } else {
                     status = cs_pas_findMatchingUntil();
                     if ( status ) return( '' );
                     return( 'repeat' );
                  }
               }
            }
         }
      }
      if ( ch == ';' ) {
         return( ';' );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc: Locate the next ;, or begin, loop, if and their
//       matching block markers.
//          ;
//          begin <==> end XXXX
//          loop <==> end loop
//          if <==> end if
//          then <==> elsif or else or end if
//          else <==> end if
// Retn:  ';', begin, loop, if, or '' if none is found.
static typeless cs_plsql_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   // Special case for "else". "else" block starts right after the keyword.
   int status=0;
   typeless type=0;
   _str ch='';
   if (lowcase(get_text(4)) == "else") {
      word_chars := _clex_identifier_chars();
      status = search("[~"word_chars"]|$","r@iHXCS");
      if (status) return("");
      sbstart_line = p_line; sbstart_col = p_col;
      status = cs_plsql_match_else_endif();
      if (!status) return("");
      return('else');
   }

   while (1) {
      // We can't match for word here because we also need to
      // look for ";" and "(". The side effect is that the search
      // can also find words that contain embedded "begin", "if",...
      //messageNwait("hh1");
      status = search("begin|loop|if|then|;|[(]","r@iHXCS");
      if (status) return("");
      //messageNwait("hh2");

      // Process non-word first:
      if (get_text() == ";") {
         return( ';' );
      } else if (get_text() == "(") {
         _find_matching_paren(def_pmatch_max_diff);
         typeless seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Make sure this is a key word:
      status = _clex_find(KEYWORD_CLEXFLAG, "G");
      if (status != CFG_KEYWORD) {
         _nrseek(_nrseek() + 1);
         continue;
      }
      if (lowcase(get_text(5)) == "begin") {
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = _find_matching_paren(def_pmatch_max_diff);
            if ( status ) return( '' );
            cs_nextSemicolon();
            return( 'begin' );
         }
      } else if (lowcase(get_text(4)) == "loop") {
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = _find_matching_paren(def_pmatch_max_diff);
            if ( status ) return( '' );
            cs_nextSemicolon();
            return( 'loop' );
         }
      } else if (lowcase(get_text(4)) == "then") {
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_plsql_match_then_elseifend();
            if (!status) return('');
            return( 'then' );
         }
      } else if (lowcase(get_text(2)) == "if") {
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = _find_matching_paren(def_pmatch_max_diff);
            if ( status ) return( '' );
            cs_nextSemicolon();
            return( 'if' );
         }
      }
   }
   return("");

   /*
   _str ch, ch4;
   if ( cs_skipSpaces() == -1 ) return( '' );
   seek_pos = _nrseek();
   ch = get_text(); ch = lowcase( ch );
   found = 0;
   while ( !found ) {
      //messageNwait("cs_plsql_locateStartEnd ch="ch);
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'b' ) {               // begin
         ch4 = get_text(5); ch4 = lowcase(ch4);
         if (ch4 == "begin") {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               cs_nextSemicolon();
               return( 'begin' );
            }
         }
      } else if (ch == "l") {        // loop
         ch4 = get_text(4); ch4 = lowcase(ch4);
         if (ch4 == "loop") {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               cs_nextSemicolon();
               return( 'loop' );
            }
         }
      } else if (ch == "i") {        // if
         ch4 = get_text(2); ch4 = lowcase(ch4);
         if (ch4 == "if") {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               cs_nextSemicolon();
               return( 'if' );
            }
         }
      } else if (ch == "t") {        // then
         ch4 = get_text(4); ch4 = lowcase(ch4);
         if (ch4 == "then") {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = cs_plsql_match_then_elseifend();
               if (!status) return('');
               /*
               if (status == 3) {
                  // If "then" matches "end if", there is only one
                  // clause in "if". Even though this does not hurt us,
                  // We don't want to count the if-endif and the
                  // then-endif range. We fake this out by returning a
                  // fake range that encloses just the "then"
                  p_line = sbstart_line; p_col = sbstart_col;
                  status = _clex_find(KEYWORD_CLEXFLAG, 'N');
                  return("fake then");
               }
               */
               return( 'then' );
            }
         }
      } else if (ch == "e") {        // else
         if (lowcase(get_text(4)) == "else") {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = cs_plsql_match_else_endif();
               if (!status) return('');
               return( 'then' );
            }
         }
      /*
      } else if ( ch == 'c' ) {        // class, case
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'cl' ) {           // class
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               // 'class' begin block marker must not be semicolon terminated:
               if ( !cs_is_semicolonTerminated() ) {
                  status = cs_plsql_findNextEnd();
                  if ( status ) return( '' );
                  return( 'class' );
               }
            }
         } else if ( ch == 'ca' ) {    // case
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'case' );
            }
         }
      } else if ( ch == 'r' ) {        // record or repeat
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 're' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               // 'record' and 'repeat' begin block marker must not be
               // semicolon terminated:
               if ( !cs_is_semicolonTerminated() ) {
                  ch = get_text( 3 ); ch = lowcase( ch );
                  if ( ch == 'rec' ) {
                     status = cs_plsql_findNextEnd();
                     if ( status ) return( '' );
                     return( 'record' );
                  } else {
                     status = cs_plsql_findMatchingUntil();
                     if ( status ) return( '' );
                     return( 'repeat' );
                  }
               }
            }
         }
      */
      }
      if ( ch == ';' ) {
         return( ';' );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
   */
}

// Desc: Match "then" with "elsif" or "else" or "end if".
// Retn: 1 matched "else", 2 matched "elsif", 3 matched "end if", 0 not matched
static int cs_plsql_match_then_elseifend()
{
   int oldLine, oldCol;
   oldLine = p_line; oldCol = p_col;

   // Skip over keyword ("then" or "else"):
   word_chars := _clex_identifier_chars();
   status := search("[~"word_chars"]|$","r@iHXCS");
   if (status) return(0);

   while (1) {
      // Search for matching "elsif", "else", "end if".
      // Note that inside the "then" clause, there can be other blocks and
      // even nested "if".
      status = search("elsif|else|end if|begin|loop|if|declare","rw@iHCK");
      if (status) return(0);
      _str ch, ch4;
      ch = lowcase(get_text(2));
      ch4 = lowcase(get_text(4));
      if (ch4 == "elsi") {
         int newline;
         newline = p_line;
         // Too far forward... Back up to the last semicolon.
         search(";","-r@iHXCS");
         // Some bad PL/SQL code... block without any statement.
         if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
            p_line = newline - 1;
         }
         return(2);
      } else if (ch4 == "else") {
         int newline;
         newline = p_line;
         // Too far forward... Back up to the last semicolon.
         search(";","-r@iHXCS");
         // Some bad PL/SQL code... block without any statement.
         if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
            p_line = newline - 1;
         }
         return(1);
      } else if (ch == "en") {
         int newline;
         newline = p_line;
         // Too far forward... Back up to the last semicolon.
         search(";","-r@iHXCS");
         // Some bad PL/SQL code... block without any statement.
         if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
            p_line = newline - 1;
         }
         return(3);
      }

      // For nested blocks, jump over the blocks:
      if (ch4 == "begi" || ch4 == "loop" || ch == "if") {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }

      // For the "declare" block, need to jump to its "begin" with
      // special care to jump over any nested blocks in its declaration
      // section (ie. stuff between "declare" and "begin".
      if (ch4 == "decl") {
         status = cs_plsql_next_begin("", 1);
         if (status) return(1);
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }
   }
   return(0);

   /*
   // Skip over current keyword:
   int status;
   status = _clex_find(KEYWORD_CLEXFLAG, 'N');
   if (status == STRING_NOT_FOUND_RC) return(0);

   int lastTokenSeekPos;
   lastTokenSeekPos = 0;

   while (1) {
      // Skip to the next keyword:
      status = _clex_find(KEYWORD_CLEXFLAG, 'O');
      if (status == STRING_NOT_FOUND_RC) return(0);

      ch = lowcase(get_text(2));
      //messageNwait("cs_match_then_elseif ch="ch);
      if (ch == "if" || ch == "pa" || ch == "be" || ch == "lo") {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(0);
         cs_nextSemicolon();
         lastTokenSeekPos = _nrseek();
         continue;
      } else if (ch == "el") {
         ch = lowcase(get_text(4));
         // Go back to the last keyword and skip over it:
         if (lastTokenSeekPos) _nrseek(lastTokenSeekPos);
         //messageNwait("cs_match_then_elseif h1");
         //cs_nextSemicolon();
         _clex_find(KEYWORD_CLEXFLAG, 'N');
         //messageNwait("cs_match_then_elseif h2");
         if (ch == "else") return(1);
         return(2);
      } else if (lowcase(get_text(3)) == "end") {
         // Go back to the last keyword and skip over it:
         if (lastTokenSeekPos) _nrseek(lastTokenSeekPos);
         //messageNwait("cs_match_then_elseif h1");
         //cs_nextSemicolon();
         _clex_find(KEYWORD_CLEXFLAG, 'N');
         //messageNwait("cs_match_then_elseif h2");
         return(3);
      } else {
         lastTokenSeekPos = _nrseek();
         status = _clex_find(KEYWORD_CLEXFLAG, 'N');
         if (status == STRING_NOT_FOUND_RC) return(0);
         continue;
      }
   }
   return(0);
   */
}

// Desc: Match "else" with "end if".
// Retn: 1 matched OK, 0 not matched
static int cs_plsql_match_else_endif()
{
   typeless status=0;
   int oldLine, oldCol;
   oldLine = p_line; oldCol = p_col;
   while (1) {
      // Search for matching "elsif", "else", "end if".
      // Note that inside the "then" clause, there can be other blocks and
      // even nested "if".
      status = search("end if|begin|loop|if|declare","rw@iHCK");
      if (status) return(0);
      _str ch, ch4;
      ch = lowcase(get_text(2));
      ch4 = lowcase(get_text(4));
      if (ch == "en") {
         int newline;
         newline = p_line;
         search(";","-r@iHXCS");
         // Some bad PL/SQL code... block without any statement.
         if (p_line < oldLine || (p_line == oldLine && p_col < oldCol)) {
            p_line = newline - 1;
         }
         return(1);
      }

      // For nested blocks, jump over the blocks:
      if (ch4 == "begi" || ch4 == "loop" || ch == "if") {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }

      // For the "declare" block, need to jump to its "begin" with
      // special care to jump over any nested blocks in its declaration
      // section (ie. stuff between "declare" and "begin".
      if (ch4 == "decl") {
         status = cs_plsql_next_begin("", 1);
         if (status) return(1);
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         cs_nextSemicolon();
         continue;
      }
   }
   return(0);
}


// Desc:  Skip over spaces.
// Retn:  # of white spaces skipped.
static int cs_skipSpaces()
{
   int hit = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   while ( pos( ch, " \t\n\f\r\v" ) ) {
      hit = hit + 1;
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( -1 );
      ch = get_text();
   }
   return( hit );
}


// Desc:  Skip over leading spaces in current line
//        starting from the current column position.
// Retn:  # of white spaces skipped.
static int cs_skipLeadingSpacesInLine()
{
   int hit = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   while (pos(ch, " \t")) {  // skip over spaces and tabs
      hit = hit + 1;
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( -1 );
      ch = get_text();
   }
   return(hit);
}


// Desc:  Skip over spaces until reaching end-of-line.
// Retn:  # of white spaces skipped.
static int cs_skipSpacesUntilEOLN()
{
   int hit = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   while ( pos( ch, " \t\f\v" ) ) {
      hit = hit + 1;
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( -1 );
      ch = get_text();
   }
   return( hit );
}


// Desc:  Determine the start and end of the proc block.
// Retn:  0 for OK, 1 for error.
static int cs_findProcBlock( int &start_line, int &start_col,
                             int &end_line,   int &end_col )
{
   rc = call_index( start_line, start_col, end_line, end_col, cs_findProcBlock_ci );
   if ( !rc ) return( 0 );

   // Try again with an alternative algorithm for the real extension:
   // If one does not exists, do nothing and return the previous error code.
   //say( "Using alt proc" );
   restore_pos( cs_ori_position );
   _str real_extension="";
   _str ext = cs_getExtension( real_extension );
   index := _FindLanguageCallbackIndex('cs_%s_findProcBlockAlt',ext);
   if ( !index ) return( rc );
   rc = call_index( start_line, start_col, end_line, end_col, index );
   return( rc );
#if 0
   // Determine which language:
   ext = cs_getExtension( real_extension );

   // Differentiate between C and Java:
   if ( real_extension == 'java' || real_extension == 'cs' ) {
      status = cs_java_findProcBlock( start_line, start_col,
               end_line, end_col );
      return( status );
   }

   // Get the apropriate proc:
   //index = find_index( 'cs_'ext'_findProcBlock', PROC_TYPE );
   if ( cs_getCallIndex( "cs_findProcBlock", ext, index ) ) return( 1 );
   if ( index_callable( index ) ) {
      rc = call_index( start_line, start_col, end_line, end_col, index );
      if ( !rc ) return( 0 );

      // Try again with an alternative algorithm for the real extension:
      // If one does not exists, do nothing and return the previous error code.
      //say( "Using alt proc" );
      restore_pos( cs_ori_position );
      index = _FindLanguageCallbackIndex('cs_%s_findProcBlockAlt',ext);
      if ( !index ) return( rc );
      rc = call_index( start_line, start_col, end_line, end_col, index );
      return( rc );
   }
   return( 1 );
#endif
}


// Desc:  Determine the start and end of the proc block.
// Retn:  0 for OK, 1 for error.
int cs_c_findProcBlock( int &start_line, int &start_col,
                        int &end_line,   int &end_col )
{
   // Find the start of the proc.  This may be the function itself or the
   // function before this one.  Can't be sure at this time.
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      _message_box('Tagging not supported for files of this extension.  Make sure support module is loaded.');
      return(1);
   }

   int ori_line = p_line; 
   int ori_column = p_col;
   if ( prev_proc(1) ) {
      // Try starting from next line and find prev proc:
      // This takes care of the case when the proc is the first proc and the
      // caret is right on the proc's first line:
      p_line = p_line + 1;
      if ( prev_proc(1) ) return( 1 );
   }
   int proc_start_line = p_line;

   // Get the starting context id
   _UpdateContext(true,false);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int start_ctxId = tag_current_context();

   // Find the starting and ending code block symbol:
   //    C         -- { and }
   start_line = p_line; start_col = p_col;
   int block_start_line=0, block_end_line=0;
   if ( cs_c_find_block( block_start_line, block_end_line ) ) {
      return( 1 );
   }
   end_line = p_line; end_col = p_col;

   // Get the ending context id
   _UpdateContext(true,false);
   int end_ctxId = tag_current_context();

   // If the original line is inside the proc start and the ending block lines,
   // and the start and context ids are the same then current proc is the right proc:
   if ( proc_start_line <= ori_line && ori_line <= block_end_line && start_ctxId == end_ctxId ) {
      //say( 'select_code_block FOUND start='proc_start_line' end='block_end_line );
      return( 0 );
   }

   // Find the next proc:
   if ( next_proc(1) ) {
      //message( "Not inside any valid code block." );
      return( 1 );
   }
   proc_start_line = p_line;

   // If the original line is before the proc start, no proc found:
   if ( ori_line < proc_start_line ) {
      //message( "Not inside any valid code block." );
      return( 1 );
   }

   // Found proc:
   // Find the starting and ending code block symbol:
   start_line = p_line; start_col = p_col;
   if ( cs_c_find_block( block_start_line, block_end_line ) ) {
      return( 1 );
   }
   end_line = p_line; end_col = p_col;
   //say( 'select_code_block FOUND start='proc_start_line' end='block_end_line );
   return( 0 );
}


// Desc:  Check to see if current caret position is within the specified bounds.
// Retn:  1 for within bounds, 0 for not.
static int cs_is_withinbounds( int line, int col, 
                               int sl, int sc, int el, int ec )
{
   if ( line < sl || line > el ) return( 0 );
   if ( line != el ) return( 1 );
   if ( sl < el ) {
      if ( col > ec ) return( 0 );
   } else {
      if ( col < sc || col > ec ) return( 0 );
   }
   return( 1 );
}


// Desc:  Goto next keyword, block terminator, or block open.
//     Spaces, strings and comments are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  See language specifics.
//        ..., '' for not found.
static typeless cs_nextBlockToken( int bbel, int bbec )
{
   rc = call_index( bbel, bbec, cs_nextBlockToken_ci );
   return( rc );
#if 0
   // Determine which language:
   lang = cs_getExtension( real_extension );

   // Get the apropriate proc:
   index = _FindLanguageCallbackIndex('cs_%s_nextBlockToken',lang);
   if ( index ) {
      rc = call_index( bbel, bbec, index );
      return( rc );
   }
   return( '' );
#endif
}


// Desc:  C.  Goto next keyword, block terminator (;), or block open ({).
//     Spaces, strings and comments are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword, 'a' for ASCII, ';', '{', or '' for not found.
typeless cs_c_nextBlockToken( int bbel, int bbec )
{
   typeless status=0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      _str ch = get_text();
      if ( ch == ';' ) return( ';' );
      if ( ch == '{' ) return( '{' );

      // Stop for alphanumeric characters:
      if ( isalnum( ch ) || ( ch >= '!' && ch <= '@' ) ) return( 'a' );

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc:  Pascal.  Goto next keyword, block terminator (;), or block open (begin).
//     Spaces, strings and comments, 'end' are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword other than 'begin', 'a' for ASCII, ';',
//     'begin', or '' for not found.
typeless cs_pas_nextBlockToken( int bbel, int bbec )
{
   _str ch="";
   typeless status = 0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 2 );
         ch = lowcase( ch );
         if ( ch == 'be' ) return( 'begin' );
         if ( ch == 'en' ) {
            // Skip over 'end':
            // 'end' in Pascal is treated like '}' in C.
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            seek_pos = _nrseek();
            continue;
         }
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      ch = get_text();
      if ( ch == ';' ) return( ';' );

      // Stop for alphanumeric characters:
      if ( isalnum( ch ) ) return( 'a' );

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc: PL/SQL.  Goto next keyword, block terminator (;),
//       or block open (begin, if).
//       Spaces, strings and comments, 'end' are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword other than 'begin', 'a' for ASCII, ';',
//     'begin', or '' for not found.
typeless cs_plsql_nextBlockToken( int bbel, int bbec )
{
   _str ch="";
   typeless status = 0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Make sure that caret is still within bound:
      if (p_line > bbel) return("");
      if (p_line == bbel && p_col > bbec) return("");

      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 3 );
         ch = lowcase( ch );
         if ( ch == 'beg' ) return( 'begin' );
         //if ( lowcase(get_text(2)) == 'if' ) return( 'if' );
         if ( ch == 'end' ) {
            // Skip over 'end':
            // Skip until semicolon because "end" may have
            // an optional label.
            //cs_skipKeyword();
            cs_nextSemicolon();
            cs_skipSemiColonAtCursor();
            seek_pos = _nrseek();
            continue;
         }
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      ch = get_text();
      if ( ch == ';' ) return( ';' );

      // Stop for alphanumeric characters:
      if (isalnum(ch) || ch == "_") return( 'a' );

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc:  MODULA-2.  Goto next keyword, block terminator (;), or block open (begin).
//     Spaces, strings and comments, 'end' are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword other than 'begin', 'a' for ASCII, ';',
//     'begin', or '' for not found.
typeless cs_mod_nextBlockToken( int bbel, int bbec )
{
   _str ch="";
   typeless status = 0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 2 );
         ch = lowcase( ch );
         if ( ch == 'be' ) return( 'begin' );
         if ( ch == 'en' ) {
            // Skip over 'end':
            // 'end' in Pascal is treated like '}' in C.
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            seek_pos = _nrseek();
            continue;
         }
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      ch = get_text();
      if ( ch == ';' ) return( ';' );

      // Stop for alphanumeric characters:
      if ( isalnum( ch ) ) return( 'a' );

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc:  Ada.  Goto next keyword, block terminator (;).
//     Spaces, strings and comments, 'end' are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword, 'a' for ASCII, ';',
//     or '' for not found.
typeless cs_ada_nextBlockToken( int bbel, int bbec )
{
   _str ch="";
   typeless status = 0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'end' ) {
            // Skip over 'end':
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            seek_pos = _nrseek();
            continue;
         }
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      ch = get_text();
      if ( ch == ';' ) return( ';' );

      // Stop for alphanumeric characters:
      if ( isalnum( ch ) ) return( 'a' );

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc:  Awk.  Goto next keyword, block terminator (;).
//     Spaces, strings and comments are skipped.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword, 'a' for ASCII, ';',
//     or '' for not found.
typeless cs_awk_nextBlockToken( int bbel, int bbec )
{
   _str ch="";
   typeless status = 0;
   typeless seek_pos = _nrseek();
   for(;;) {
      // Determine what's under the caret:
      // Skip over comments and strings.
      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         return( 'k' );
      } else if ( type == CFG_STRING ) {
         status = _clex_find( STRING_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      } else if ( type == CFG_COMMENT ) {
         status = _clex_find( COMMENT_CLEXFLAG, 'N' );
         seek_pos = _nrseek();
         continue;
      }

      // Check for ; or {
      ch = get_text();
      if ( ch == ';' ) return( ';' );
      else if ( ch == '{' ) return( '{' );

      // Stop for alphanumeric characters:
      if ( isalnum( ch ) ) {
         //say( 'ascii' );
         return( 'a' );
      }

      // Stop for other non-white space characters:
      if ( ch >= '!' && ch <= '@' ) {
         //say( 'non-white ch='asc(ch) );
         return( 'a' );
      }

      // Prevent the scan to go beyond specified scope:
      if ( p_line == bbel && p_col == bbec ) break;

      // Skip over this one and try the next:
      seek_pos = seek_pos + 1;
      status = _nrseek( seek_pos );
      if ( status == '' ) break;
   }
   return( '' );
}


// Desc:  Cobol.  Goto the next block token.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword, 'a' for ASCII, ';',
//     or '' for not found.
typeless cs_cob_nextBlockToken( int bbel, int bbec )
{
   // Skip to the next non-white-space:
   if ( cs_skipSpaces() == -1 ) return( '' );

   // If line is a continuation or comment, skip it:
   while (p_col == 7) {
      int oldLine;
      oldLine = p_line;
      p_line = p_line + 1;
      if (p_line == oldLine) return('');
      p_col = 1;
      if (cs_skipSpaces() == -1) return('');
   }
   return( 'a' );
}


// Desc:  Fortran.  Goto the next block token.
// Para:  bbel, bbec          Bounding ending line and column
// Retn:  'k' for keyword, 'a' for ASCII, ';',
//     or '' for not found.
typeless cs_for_nextBlockToken( int bbel, int bbec )
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   return( 'a' );
}


// Desc:  Select the text between the specified positions.
// Para:  mode               Mode: 'c' - Character selection
//                                 'l' - Line selection
//                                 '-' - Normal
static void cs_select_text( _str mode, int sl, int sc, int el, int ec )
{
   // Clear old selection:
   int temp_line = p_line; 
   int temp_col = p_col;
   deselect();
   _str persistent=(def_persistent_select=='Y')?'P':'';
   _str mstyle='EN'persistent;

   // Restore the original position before starting selection:
   // This prevents the 'jumping' of the view.
   restore_pos( cs_ori_position );

   // Select:
   if ( mode == 'c' || ( mode != 'l' && sl == el ) ) {
      // Selected text spans a single line, do character selection:
      p_line = sl; p_col = sc;
      _select_char('',mstyle);
      p_line = el; p_col = ec;
      _select_char('',mstyle);
   } else {
      // Selected text spans multiple lines, do line selection:
      p_line = sl; p_col = sc;
      _select_line('',mstyle);
      p_line = el; p_col = ec;
      _select_line('',mstyle);
   }
   p_line = temp_line; p_col = temp_col;
}


// Desc:  Select the code block text with specified modes.
// Para:  bodyonly           Flag: 1 = select body only
//        mode               Selection mode.  See cs_list_all_codeblocks()
//        level              Code block nesting level
static void cs_select_codetext( boolean bodyonly, _str mode, 
                                int sl, int sc, int el, int ec, 
                                int bl, int bc, int level, 
                                int target_line, int target_col )
{
   // Select text:
   int s_line, s_col, e_line, e_col;
   _str real_extension="";
   _str ext = cs_getExtension( real_extension );
   s_line = sl; s_col = sc;
   e_line = el; e_col = ec;
   if ( bodyonly ) {
      //messageNwait("h1 s_line="s_line" e_line="e_line);
      if ( !bl || !bc ) {
         s_line = sl; s_col = sc;
         mode = '-';
      } else {
         // For PL/SQL, be a little smarter about selecting the "real" body
         // of the code block. The body should exclude block start/end keywords!
         if (real_extension == "plsql") {
            if (e_line > s_line) {
               int oldseekpos, status;
               oldseekpos = _nrseek();
               p_line = s_line; p_col = 1;
               int foundbeginonstartline;
               int beginCol;
               foundbeginonstartline = 0;
               status = search("begin","rw@iHCK");
               if (!status && p_line == sl) {
                  foundbeginonstartline = 1;
               }
               s_line++;

               // Find the starting column of the first line of the selection.
               p_line = sl;
               p_col = 1;
               word_chars := _clex_identifier_chars();
               search("["word_chars"]","rh@XCS");
               beginCol = p_col;
               //messageNwait("beginCol="beginCol);

               // Exclude last line of the selection when it begins with "end"
               // and starts at the same column as the first line of the
               // selection.
               int foundendonlastline;
               foundendonlastline = 0;
               p_line = e_line; p_col = 1;
               status = search("end","rw@iHCK");
               //messageNwait("p_col="p_col);
               if (!status && p_line == el && p_col == beginCol) {
                  e_line--;
                  foundendonlastline = 1;
               }
               _nrseek(oldseekpos);

               // If block only has two lines and "begin" is the first and
               // "end" is on the second, don't modify the selection and let
               // the selection includes both lines.
               if (foundbeginonstartline && foundendonlastline && (el == sl + 1)) {
                  s_line = sl; s_col = sc;
                  e_line = el; e_col = ec;
               }
            }
            //messageNwait("s_line="s_line" e_line="e_line);
         } else {
            s_line = bl; s_col = bc;
            if (e_line - s_line) {
               s_line++;
               if (!( real_extension == 'cob')) {
                  e_line--;
               }
            }
         }
         mode = 'l';
         if (s_line > e_line) return;
      }
   }
   //messageNwait('ec='ec);
   e_col++;
   cs_select_text( mode, s_line, s_col, e_line, e_col );

   // Remember what is selected:
   // This information is saved for possible selection expansion when
   // select_code_block() is called repeatedly.
   cs_selected_level = level;
   cs_last_target_l = target_line;
   cs_last_target_c = target_col;
   cs_selected_sl = s_line;
   cs_selected_sc = s_col;
   cs_selected_el = e_line;
   cs_selected_ec = e_col;

   // Remember the last scope:
   cs_lastscope_sl = sl;
   cs_lastscope_sc = sc;
   cs_lastscope_el = el;
   cs_lastscope_ec = ec;
}


// Desc:  Add block markers on a stack.
// Para:  level              Code block nesting level
//        cbs_line,cbs_col   Start of code block (including header)
//        cbe_line,cbe_col   End of code block
//        sbs_line,sbs_col   Start of body of code block (excluding header)
static void cs_add_bm( int level, 
                       int cbs_line, int cbs_col, 
                       int cbe_line, int cbe_col, 
                       int sbs_l,    int sbs_c )
{
   // List has the following format:
   //    level=v1a,v1b,v2a,v2b,v3a,v3b [level=v1a,v1b,v2a,v2b,v3a,v3b]...
   //
   // New entries are added to the front of the list.
   // The total length of the list is limited to 1K.  Assuming that each
   // block marker uses 64 characters, this list can hold up to 16 entries.
   cs_bm_listcount = cs_bm_listcount + 1;
   cs_bm_list = level'='cbs_line','cbs_col','cbe_line','cbe_col','sbs_l','sbs_c' 'cs_bm_list;
   //say( 'cs_bm_list='cs_bm_list );
}


// Desc:  Get the block marker at the specified level from the list.
// Para:  level              Block nesting level
//        cbs_line,cbs_col   Start of code block (including header)
//        cbe_line,cbe_col   End of code block
//        sbs_line,sbs_col   Start of body of code block (excluding header)
// Retn:  0 for OK, 1 for blocker marker not found
static int cs_get_bm( int level, 
                      typeless &cbs_line, typeless &cbs_col, 
                      typeless &cbe_line, typeless &cbe_col,
                      typeless &sbs_l,    typeless &sbs_c )
{
   if ( !cs_bm_listcount ) return( 1 );
   _str entry = eq_name2value( level, cs_bm_list );
   parse entry with cbs_line',' cbs_col',' cbe_line',' cbe_col',' sbs_l',' sbs_c;
   //say( cbs_line',' cbs_col',' cbe_line',' cbe_col',' sbs_l',' sbs_c );
   return( 0 );
}


// Desc:  Clear the block mark list.
static void cs_clear_list()
{
   cs_bm_list = '';
   cs_bm_listcount = 0;
}


// Desc:  Check to see if a there is a selection in the current buffer.
// Retn:  1 for selection exists and valid, 0 for not.
static int cs_selection_exists()
{
   // If the following conditions are satisfied, a selection currently exists.
   //    -- Selection exists
   //    -- Selection starting and ending corresponds to last known code
   //          block selection
   //    -- Caret position has not changed since last selection

   // No last known code block selection:
   //say( 'cs_selected_level='cs_selected_level );
   if ( cs_selected_level == -1 || 
        ( !cs_bm_listcount && 
          !_LanguageInheritsFrom("html",cs_LangId) && 
          !_LanguageInheritsFrom("xml",cs_LangId) )
      ) {
      return( 0 );
   }

#if 0
   // Make sure that the target caret position has not moved:
   //say( 'p_line='p_line' p_col='p_col' cs_last_target_l='cs_last_target_l' cs_last_target_c='cs_last_target_c );
   if ( p_line != cs_last_target_l || p_col != cs_last_target_c ) return( 0 );
#endif

   // No active selection in the current buffer:
   typeless stype = _select_type( '', 'T' );
   if ( stype == '' ) return( 0 );
   if ( stype == 'BLOCK' ) return( 0 );

   // Make sure the starting and ending markers of the current selection is
   // the same as that of the last known code block selection:
   _begin_select();
   if ( stype == 'LINE' ) {
      if ( p_line != cs_selected_sl ) return( 0 );
   } else {
      if ( p_line != cs_selected_sl || p_col != cs_selected_sc ) return( 0 );
   }
   _end_select();
   if ( stype == 'LINE' ) {
      if ( p_line != cs_selected_el ) return( 0 );
   } else {
      if ( p_line != cs_selected_el || p_col != cs_selected_ec ) return( 0 );
   }

   return( 1 );
}


// Desc:  Check to see if cursor is within the last selected code block.
// Retn:  1 for within last code block, 0 for not.
static int cs_selection_exists2()
{
   // No last known code block selection:
   //say( 'cs_selected_level='cs_selected_level );
   //if ( cs_selected_level == -1 || !cs_bm_listcount ) return( 0 );

   // Check to see if the current caret position is within the last
   // known scope:
   if ( p_line < cs_lastscope_sl ) {
      return( 0 );
   }
   if ( p_line > cs_lastscope_el ) {
      return( 0 );
   }
   if ( p_line == cs_lastscope_sl && p_col < cs_lastscope_sc ) {
      return( 0 );
   }
   if ( p_line == cs_lastscope_el && p_col > cs_lastscope_ec ) {
      return( 0 );
   }
   return( 1 );
}


// Desc:  Save current selection block:
static void cs_save_recent_selection_info( int cbstart_line, int cbstart_col,
                                           int cbend_line,   int cbend_col, 
                                           int sbstart_line, int sbstart_col )
{
   // Save this code block:
   cs_recent_start_line = cbstart_line; cs_recent_start_col = cbstart_col;
   cs_recent_end_line = cbend_line; cs_recent_end_col = cbend_col;
   cs_recent_sbstart_line = sbstart_line; cs_recent_sbstart_col = sbstart_col;
}


// Desc:  Pascal.  Find the next procedure, function, constructor, destructor.
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'proc', 'func', 'prog', 'con', 'des'
// Retn:  0 for OK, 1 for not found.
static int cs_pas_next_proc( boolean no_skip, typeless &type )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for PROCEDURE and PROGRAM (PR*), and FUNCTION (FU*):
      typeless seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'pr' || ch == 'fu' ) {
         // Found one...
         // If already at a proc, skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            ch = get_text( 4 );
            ch = lowcase( ch );
            if ( ch == 'prog' ) {
               type = 'prog';
               return( 0 );
            } else {
               // Make sure this is not a declaration/prototype in a class:
               if ( ch == 'proc' ) type = 'proc';
               else type = 'func';
               if ( cs_pas_is_beginBeforeEnd() ) {
                  return( 0 );
               }
            }
         }
      } else if ( ch == 'de' ) {       // 'destructor'
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            type = 'des';
            return( 0 );
         }
      } else if ( ch == 'co' ) {       // 'constructor'
         ch = get_text( 6 );
         ch = lowcase( ch );
         if ( ch == 'constr' ) {
            type = 'con';
            return( 0 );
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  PL/SQL.  Find the next procedure, function, package
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'proc', 'func', 'pack', 'decl'
// Retn:  0 for OK, 1 for not found.
static int cs_plsql_next_proc( boolean no_skip, typeless &type, int includeIfBegin )
{
   int temp_l, temp_c;
   temp_l = p_line; temp_c = p_col;
   while (1) {
      int status;
      //messageNwait("h1");
      if (includeIfBegin) {
         status = search("procedure|function|package|declare|table|trigger|if|begin", "rw@iHCK");
      } else {
         status = search("procedure|function|package|declare|table|trigger", "rw@iHCK");
      }
      //messageNwait("h2 status="status);
      if (status) return(1);

      _str ch;
      ch = lowcase(get_text(7));
      if (ch == "procedu" || ch == "functio" || ch == "trigger") {
         // Skip over prototypes:
         type = 'proc';
         if (cs_plsql_is_proto()) continue;
         if (no_skip || p_line != temp_l || p_col != temp_c) return(0);
         cs_skipKeyword();
         return(0);
      } else if (ch == "declare") {
         type = 'decl';
         if (no_skip || p_line != temp_l || p_col != temp_c) return(0);
         cs_skipKeyword();
         return(0);
      } else if (lowcase(get_text(5)) == "table") {
         // Skip over prototypes:
         type = 'tabl';
         if (cs_plsql_is_tableproto()) continue;
         if (no_skip || p_line != temp_l || p_col != temp_c) return(0);
         cs_skipKeyword();
         return(0);
      } else if (lowcase(get_text(2)) == "if") {
         return(0);
      } else if (lowcase(get_text(5)) == "begin") {
         return(0);
      }

      type = 'pack';
      if (no_skip || p_line != temp_l || p_col != temp_c) return(0);
      cs_skipKeyword();
      return(0);
   }
   return(0);

   /*
   temp_l = p_line; temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for PROCEDURE (PR*), PACKAGE (PAC*), and FUNCTION (FU*):
      seek_pos = _nrseek();
      ch = lowcase(get_text(7));
      //messageNwait("cs_plsql_next_proc ch="ch);
      if (ch == 'procedu' || ch == 'functio' || ch == "package") {
         // Found one...
         // If already at a proc, skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            if (ch == 'procedu') type = 'proc';
            else if (ch == "functio") type = 'func';
            else type = "pack";

            // Make sure this is not a declaration/prototype in a class:
            if (cs_plsql_is_proto()) {
               return( 0 );
            }
            return(0);
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
   */
}


// Desc:  Find the next 'begin' keyword.
// Para:  no_skip            Flag: 1=if already on key, do nothing (don't skip)
// Retn:  0 for OK, 1 for not found.
static int cs_pas_next_begin( boolean no_skip )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for BEGIN (b*):
      typeless seek_pos = _nrseek();
      _str ch = get_text( 1 ); ch = lowcase( ch );
      if ( ch == 'b' ) {
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'beg' ) {
            // Found one...
            // If already at a 'begin', skip over this one to find the next:
            if ( no_skip || p_line != temp_l || p_col != temp_c ) return( 0 );
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc: Find the next 'begin' keyword.
//       This function recurses!
// Para: type               Outer-block type: "proc", "func", "pack"
//       no_skip            Flag: 1=if already on key, do nothing (don't skip)
// Retn:  0 for OK, 1 for not found.
static int cs_plsql_next_begin(_str type, int skip)
{
   // If this is a package (or "if" or "begin"), the block starts
   // at the keyword.
   if (lowcase(get_text(7)) == "package" || lowcase(get_text(2)) == "if"
       || lowcase(get_text(5)) == "begin") {
      return(0);
   }

   // If this is a "table", block starts at the "("
   if (lowcase(get_text(5)) == "table") {
      int status;
      status = search("[(]","r@iHXCS");
      if (status) return(1);
      return(0);
   }


   // Skip over keyword:
   int status;
   if (skip) {
      word_chars := _clex_identifier_chars();
      status = search("[~"word_chars"]|$","r@iHXCS");
      if (status) return(1);
   }

   // Search for next block begin... Blocks can be nested!
   // Can not have nested packages!!!
   while (1) {
      status = search("begin|declare|procedure|function|trigger", "rw@iHCK");
      if (status) return(1);
      _str ch = lowcase(get_text(5));
      if (ch == "begin") {
         return(0);
      } else if (lowcase(get_text(2)) == "if") {
         return(0);
      } else if (ch == "decla") {
         status = cs_plsql_skipOverDeclare();
         if (status) return(1);
      } else if (ch == "funct" || ch == "proce" || ch == "trigg") {
         status = cs_plsql_skipOverFunction();
         if (status) return(1);
      }
   }
   return(0);
}

// Desc: Skip over the declare/begin/end block.
// Retn: 0 OK, !0 error
static int cs_plsql_skipOverDeclare()
{
   // Skip over keyword:
   word_chars := _clex_identifier_chars();
   status := search("[~"word_chars"]|$","r@iHXCS");
   if (status) return(1);

   // Locate "begin" of "declare" block:
   status = cs_plsql_next_begin("", 1);
   if (status) return(1);
   status = _find_matching_paren(def_pmatch_max_diff);
   if (status) return(1);
   cs_nextSemicolon();
   return(0);
}

// Desc: Skip over the function/begin/end block.
// Retn: 0 OK, !0 error
static int cs_plsql_skipOverFunction()
{
   // If function is a proto, skip over the proto:
   if (cs_plsql_is_proto()) return(0);

   // Skip over keyword:
   word_chars := _clex_identifier_chars();
   status := search("[~"word_chars"]|$","r@iHXCS");
   if (status) return(1);

   // Locate "begin" of "function":
   status = cs_plsql_next_begin("", 1);
   if (status) return(1);
   status = _find_matching_paren(def_pmatch_max_diff);
   if (status) return(1);
   cs_nextSemicolon();
   return(0);
}


// Desc:  Find the next 'end.' keyword.  The caret position may be before the
//     keyword.  It may also be right on the keyword.
// Retn:  0 for OK, 1 for not found.
static int cs_pas_next_enddot()
{
   // Check to make sure that caret is not directly over a keyword:
   // If it is, back up to the beginning of that keyword.
   typeless seek_pos=0;
   int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
   if ( type == CFG_KEYWORD ) {
      // Find the beginning of this keyword:
      while ( type == CFG_KEYWORD ) {
         seek_pos = _nrseek() - 1;
         _nrseek( seek_pos );
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      }
      _nrseek( seek_pos + 1 );
   }

   // Search for 'end.'
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for END (b*):
      seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'en' ) {
         // Make sure this one has the dot after:
         // If not, do nothing.
         ch = get_text( 4 );
         ch = lowcase( ch );
         if ( ch == 'end.' ) return( 0 );
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'end.' keyword.  The caret position may be before the
//     keyword.  It may also be right on the keyword.
// Retn:  0 for OK, 1 for not found.
static int cs_plsql_next_enddot()
{
   // Check to make sure that caret is not directly over a keyword:
   // If it is, back up to the beginning of that keyword.
   typeless seek_pos=0;
   int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
   if ( type == CFG_KEYWORD ) {
      // Find the beginning of this keyword:
      while ( type == CFG_KEYWORD ) {
         seek_pos = _nrseek() - 1;
         _nrseek( seek_pos );
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      }
      _nrseek( seek_pos + 1 );
   }

   // Search for 'end.'
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for END (b*):
      seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'en' ) {
         // Make sure this one has the dot after:
         // If not, do nothing.
         ch = get_text( 4 );
         ch = lowcase( ch );
         if ( ch == 'end.' ) return( 0 );
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Check to see if the caret is inside main code block.
// Retn:  1 for in main, 0 for not.
static int cs_pas_is_inmain( int &start_line, int &start_col,
                             int &end_line, int &end_col )
{
   // Search for 'end.' keyword:
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless status = cs_pas_next_enddot();
   if ( status ) return( 0 );

   // Skip over the keyword and mark the position:
   typeless seek_pos = _nrseek();
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   if ( ori_line > p_line ) return( 0 );
   end_line = p_line; end_col = p_col;

   // Find matching 'begin':
   _nrseek( seek_pos );
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 0 );

   // Inside main:
   if ( cs_is_withinbounds( ori_line, ori_col, p_line, p_col,
            end_line, end_col ) ) {
      start_line = p_line; start_col = p_col;
      return( 1 );
   }
   return( 0 );
}


// Desc: Check to see if the caret is inside some large outer block.
//       The outer block could be that of a package, for example.
// Retn: 1 for in main, 0 for not.
static int cs_plsql_is_inmain( int &start_line, int &start_col,
                               int &end_line, int &end_col )
{
   int oriseekpos;
   oriseekpos = _nrseek();
   int ori_line, ori_col;
   int status;
   status = search("begin", "rw@iHCK");
   if (status) {
      _nrseek(oriseekpos);
      return(0);
   }
   ori_line = p_line; ori_col = p_col;
   if (_find_matching_paren(def_pmatch_max_diff)) return(0);
   cs_nextSemicolon();
   end_line = p_line; end_col = p_col;
   _nrseek(oriseekpos);

   // Inside begin/end of some outer block (maybe package block):
   if (cs_is_withinbounds(ori_line, ori_col, p_line, p_col,
            end_line, end_col)) {
      start_line = p_line; start_col = p_col;
      return(1);
   }
   return( 0 );
}


// Desc:  Pascal.  Determine the start and end of the proc block.
//     If inside proc or func, found.  If outside any proc/func and inside
//     program and corresponding 'end.', take program block.
// Retn:  0 for OK, 1 for not found.
int cs_pas_findProcBlock( int &start_line, int &start_col,
                          int &end_line, int &end_col )
{
   // Try to find the proc starting from cs_stepback_size characters backup:
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless type=0;
   typeless status = cs_pas_next_proc( 1, type );
   if ( status ) {
      // Maybe inside 'main' code block:
      p_line = ori_line; p_col = ori_col;
      if ( cs_pas_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main0 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }
      return( 1 );
   }

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         //messageNwait( 'h1' );
         status = cs_pas_next_begin( 0 );
         //messageNwait( 'h2' );
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            // Skip over the 'end' keyword:
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            end_line = p_line; end_col = p_col;
            //say( 'Found proc1 start='start_line' 'start_col' end='end_line' 'end_col );
            return( 0 );
         }

         // Find next proc:
         status = cs_pas_next_proc( 0, type );
      }

      // Maybe inside 'main' code block:
      p_line = ori_line; p_col = ori_col;
      if ( cs_pas_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main1 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }
      return( 1 );
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   status = cs_pas_next_proc( 1, type );

   // Special case if the first proc is 'program':
   if ( type == 'prog' ) {
      // Find the 'end.' and take the whole thing:
      status = cs_pas_next_enddot();
      if ( status ) return( 1 );
      start_line = 1; start_col = 1;
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      end_line = p_line; end_col = p_col;
      //say( 'Found main2 start='start_line' 'start_col' end='end_line' 'end_col );
      return( 0 );
   }

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_pas_next_begin( 0 );
      if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         // Skip over the 'end' keyword:
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         end_line = p_line; end_col = p_col;
         //say( 'Found proc2 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }

      // Find next proc:
      status = cs_pas_next_proc( 0, type );
   }
   return( 1 );
}


// Desc:  PL/SQL.  Determine the start and end of the proc block.
//     If inside proc or func, found.  If outside any proc/func and inside
//     program and corresponding 'end.', take program block.
// Retn:  0 for OK, 1 for not found.
int cs_plsql_findProcBlock( int &start_line, int &start_col,
                            int &end_line, int &end_col )
{
   // Estimating a good starting position from the current line.
   // For an initial start, exclude subblock keywords such as "if" and "begin".
   int oldseekpos;
   oldseekpos = _nrseek();
   int oldline;
   oldline = p_line;
   int possibleStart;
   int status;
   status = search("procedure|function|package|declare|table|trigger", "-rw@iHCK");
   if (status) {
      _nrseek(oldseekpos);
      status = search("procedure|function|package|declare|table|trigger", "rw@iHCK");
      if (status) return(1);
      if (p_line != oldline) return(1);
      possibleStart = _nrseek();
   } else {
      possibleStart = _nrseek();
      _nrseek(oldseekpos);
   }

   // Try to find the proc starting from cs_stepback_size characters backup:
   //messageNwait("h0");
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   /*
   int stepBackLine;
   stepBackLine = p_line - 100;
   if (stepBackLine < 1) {
      seek_pos = _nrseek();
   }
   */
   if (possibleStart < seek_pos) {  // Pick the farther position, the back step or
                                    // the first found proc block.
      seek_pos = possibleStart;
   }
   _nrseek( seek_pos );
   //messageNwait("h1");
   // Trying to establish some reference so exclude "if" and "begin".
   typeless type=0;
   status = cs_plsql_next_proc( 1, type, 0 );
   //messageNwait("h2 status="status);
   if ( status ) {
      // Try from the beginning of the file. Worst case!
      //messageNwait("From beginning");
      _nrseek(0);
      // Trying to establish some reference so exclude "if" and "begin".
      status = cs_plsql_next_proc( 1, type, 0 );
      if (status) {
         return(1);
      }
      /*
      // Maybe inside 'main' code block:
      p_line = ori_line; p_col = ori_col;
      if ( cs_plsql_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main0 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }
      */
   }

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   int triedFromBeginning;
   triedFromBeginning = 0;
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         //messageNwait( 'hh1' );
         status = cs_plsql_next_begin(type, 1);
         //messageNwait( 'hh2' );
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
         //messageNwait( 'hh3' );

         // Matched backwards... Restore start and search forward.
         // This can happen if we hit "if" in "end if" which matches
         // backward to the starting "if".
         if (p_line < start_line) {
            p_line = start_line; p_col = start_col;
            cs_nextSemicolon();
            status = cs_plsql_next_proc( 0, type, 0 );
            continue;
         }

         cs_nextSemicolon();
         //messageNwait( 'hh4' );

         // If original line is before the start of the proc block,
         // the line must not in any proc block.
         if (ori_line < start_line) {
            //messageNwait("before proc h1");
            _nrseek(oldseekpos);
            p_col = 1;

            // If line does not have any words on it, give up:
            // If it does, block starts at the column 1 of line and ends
            // at first semicolon.
            int saveline;
            saveline = p_line;
            word_chars := _clex_identifier_chars();
            status = search("["word_chars"]","r@iHCK");
            if (status) return(1);
            if (p_line > saveline) return(1);
            //messageNwait("before proc h2");
            start_line = p_line; start_col = 1;
            cs_nextSemicolon();
            //messageNwait("before proc h3");
            end_line = p_line; end_col = p_col;
            return( 0 );
         }

         // Found proc:
         if ( ori_line <= p_line ) {
            // Skip over the 'end' keyword:
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            //cs_skipKeyword();
            cs_nextSemicolon();
            end_line = p_line; end_col = p_col;
            //say( 'Found proc1 start='start_line' 'start_col' end='end_line' 'end_col );
            return( 0 );
         }

         // Find next proc.
         // Once we have established some reference point, we can include
         // subblock keywords like "if" and "begin" in the search for a proc
         // block. A PL/SQL file can be quite large and is not practical to
         // scan through the entire file.
         status = cs_plsql_next_proc( 0, type, 1 );

         // Start of next proc is beyond the original line...
         // This can be very expensive!!!  Should avoid doing this.
         if (p_line > ori_line && !triedFromBeginning) {
            _nrseek(0);
            triedFromBeginning = 1;
            // Trying to establish some reference so exclude "if" and "begin".
            status = cs_plsql_next_proc( 0, type, 0 );
         }
      }

      // Maybe inside 'main' code block:
      //messageNwait("hh4");
      if ( cs_plsql_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main1 start='start_line' 'start_col' end='end_line' 'end_col );
         //messageNwait("hh5");
         return( 0 );
      }
      //messageNwait("hh6");

      // If line does not have any words on it, give up:
      // If it does, block starts at the column 1 of line and ends
      // at first semicolon.
      _nrseek(oldseekpos);
      p_col = 1;
      int saveline;
      saveline = p_line;
      word_chars := _clex_identifier_chars();
      status = search("["word_chars"]","r@iHCK");
      if (status) return(1);
      if (p_line > saveline) return(1);
      start_line = p_line; start_col = 1;
      cs_nextSemicolon();
      end_line = p_line; end_col = p_col;
      return( 0 );
      //return( 1 );
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   // Trying to establish some reference so exclude "if" and "begin".
   top();
   status = cs_plsql_next_proc( 1, type, 0 );

   /*
   // Special case if the first proc is 'program':
   if ( type == 'prog' ) {
      // Find the 'end.' and take the whole thing:
      status = cs_plsql_next_enddot();
      if ( status ) return( 1 );
      start_line = 1; start_col = 1;
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      end_line = p_line; end_col = p_col;
      //say( 'Found main2 start='start_line' 'start_col' end='end_line' 'end_col );
      return( 0 );
   }
   */

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_plsql_next_begin(type, 1);
      if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         // Skip over the 'end' keyword:
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         //cs_skipKeyword();
         cs_nextSemicolon();
         end_line = p_line; end_col = p_col;
         //say( 'Found proc2 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }

      // Find next proc:
      // Once we have established some reference point, we can include
      // subblock keywords like "if" and "begin" in the search for a proc
      // block. A PL/SQL file can be quite large and is not practical to
      // scan through the entire file.
      status = cs_plsql_next_proc( 0, type, 1 );
   }
   return( 1 );
}


// Desc:  Skip over the block start token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
static void cs_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   call_index( start_line, start_col, type, cs_skipOverBlockStartToken_ci );
#if 0
   // Determine which language:
   lang = cs_getExtension( real_extension );

   // Get the apropriate proc:
   //index = find_index( 'cs_'ext'_skipOverBlockStartToken', PROC_TYPE );
   if ( cs_getCallIndex( "cs_skipOverBlockStartToken", lang, index ) ) return;
   if ( index_callable( index ) ) {
      call_index( start_line, start_col, type, index );
   }
#endif
}


// Desc:  C.  Skip over the block start token {.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_c_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   p_line = start_line; p_col = start_col + 1;
}


// Desc:  Pascal.  Skip over the block start token 'begin'.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_pas_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   //say( 'type='type );
   p_line = start_line; p_col = start_col;
   if ( type == 'case' ) {
      // Skip everything until 'of' keyword and then skip over the 'of':
      cs_pas_findNextOf();
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      return;
   }
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
}


// Desc:  PL/SQL.  Skip over the block start token 'begin'.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_plsql_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   //say( 'type='type );
   p_line = start_line; p_col = start_col;
   if ( type == 'case' ) {
      // Skip everything until 'of' keyword and then skip over the 'of':
      cs_plsql_findNextOf();
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      return;
   }
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
}


// Desc:  MODULA-2.  Skip over the block start token 'begin'.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_mod_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   //say( 'type='type );
   p_line = start_line; p_col = start_col;
   //messageNwait( 'type='type );
   if ( type == 'if' ) {
      // Skip everything until 'then' keyword and then skip over the 'then':
      cs_mod_findNextThen();
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      return;
   } else if ( type == 'while' || type == 'for' || type == 'with' ) {
      // Skip everything until 'do' keyword and then skip over the 'do':
      cs_mod_findNextDo();
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      return;
   } else if ( type == 'case' ) {
      // Skip everything until 'of' keyword and then skip over the 'of':
      cs_pas_findNextOf();
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      return;
   }

   // Just skip over the token:
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
}


// Desc:  Ada.  Skip over the block start token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_ada_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   //say( 'type='type );
   p_line = start_line; p_col = start_col;

   // Just skip over the token:
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
}


// Desc:  Awk.  Skip over the block start token {.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_awk_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   cs_c_skipOverBlockStartToken( start_line, start_col, type );
}


// Desc:  Cobol.  Skip over the block start token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_cob_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   p_line = start_line; p_col = start_col;
}


// Desc:  Fortran.  Skip over the block start token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_for_skipOverBlockStartToken( int start_line, int start_col, int type )
{
   //say( 'type='type );
   p_line = start_line; p_col = start_col;

   // Just skip over the token:
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
}


// Desc:  Skip over the block end token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
static void cs_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   call_index( start_line, start_col, type, cs_skipOverBlockEndToken_ci );
#if 0
   // Determine which language:
   lang = cs_getExtension( real_extension );

   // Get the apropriate proc:
   //index = find_index( 'cs_'ext'_skipOverBlockEndToken', PROC_TYPE );
   if ( cs_getCallIndex( "cs_skipOverBlockEndToken", lang, index ) ) return;
   if ( index_callable( index ) ) {
      call_index( start_line, start_col, type, index );
   }
#endif
}


// Desc:  C.  Skip over the block end token }.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_c_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   // Just skip over the ;
   p_col = p_col + 1;
}


// Desc:  Pascal.  Skip over the block end token.
//     The block end tokens can be 'end' or 'until' depending on the block type.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_pas_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   if ( type == ';' ) {
      // Skip over semicolon:
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   if ( type == 'begin' || type == 'class' || type == 'record' ) {
      // Skip over 'end' and semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   if ( type == 'repeat' ) {
      // Skip over 'until' and everything up to semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
}


// Desc:  PL/SQL.  Skip over the block end token.
//     The block end tokens can be 'end' or 'until' depending on the block type.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_plsql_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   if (type == ';' || type == "proto") {
      // Skip over semicolon:
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   if (type == 'begin' || type == "loop" || type == "if" /*|| type == 'class' || type == 'record'*/) {
      // Skip over 'end' and semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   /*
   if ( type == 'repeat' ) {
      // Skip over 'until' and everything up to semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   */
}


// Desc:  MODULA-2.  Skip over the block end token.
//     The block end tokens can be 'end' or 'until' depending on the block type.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_mod_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   //messageNWait( 'type='type );
   if ( type == ';' ) {
      // Skip over semicolon:
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   // Skip over 'end' and semicolon:
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   cs_nextSemicolon();
   p_col = p_col + 1;
   return;

#if 0
   if ( type == 'begin' || type == 'if' || type == 'while' ||
            type == 'for' || type == 'case' || typetype == 'record' ) {
      // Skip over 'end' and semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   if ( type == 'repeat' ) {
      // Skip over 'until' and everything up to semicolon:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
#endif
}


// Desc:  Ada.  Skip over the block end token.
//     The block end tokens can be 'end' or 'until' depending on the block type.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_ada_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   //messageNWait( 'type='type );
   if ( type == ';' ) {
      // Skip over semicolon:
      cs_nextSemicolon();
      p_col = p_col + 1;
      return;
   }
   // Skip over 'end' and semicolon:
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   //messageNwait( 'b4 semicolon' );
   cs_nextSemicolon();
   p_col = p_col + 1;
   return;
}


// Desc:  Awk.  Skip over the block end token }.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_awk_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   cs_c_skipOverBlockEndToken( start_line, start_col, type );
}


// Desc:  Cobol.  Skip over the block end token.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_cob_skipOverBlockEndToken( int start_line, int start_col, int type )
{
   //messageNwait( 'cs_cob_skipOverBlockEndToken' );
   //say( 'start='start_line' 'start_col' 'type );
   //p_line = start_line + 1; p_col = 1;
   //cs_skipSpaces();
}


// Desc:  Fortran.  Skip over the block end token.
//     The block end tokens can be 'end' or 'until' depending on the block type.
// Para:  start_line         Start position of token
//        start_col
//        type               Block type
void cs_for_skipOverBlockEndToken( int start_line, int start_col, int type )
{
}


// Desc:  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
static typeless cs_procBlockBoundary( int &start_line, int &start_col,
                                      int &end_line, int &end_col, 
                                      int &sbstart_line, int &sbstart_col )
{
   rc = call_index( start_line, start_col, end_line, end_col,
            sbstart_line, sbstart_col, cs_procBlockBoundary_ci );
   return( rc );
#if 0
   // Determine which language:
   lang = cs_getExtension( real_extension );

   // Get the apropriate proc:
   //index = find_index( 'cs_'ext'_procBlockBoundary', PROC_TYPE );
   if ( cs_getCallIndex( "cs_procBlockBoundary", lang, index ) ) return( '' );
   if ( index_callable( index ) ) {
      rc = call_index( start_line, start_col, end_line, end_col,
               sbstart_line, sbstart_col, index );
      return( rc );
   }
   return( '' );
#endif
}


// Desc:  C.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_c_procBlockBoundary( int &start_line, int &start_col,
                                 int &end_line,   int &end_col, 
                                 int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;

   // Search for the next '{':
   if ( cs_c_next_openCurly( 1 ) ) return( '' );
   sbstart_line = p_line; sbstart_col = p_col;

   // Find the matching '}':
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( '' );
   end_line = p_line; end_col = p_col;
   return( '{' );
}


// Desc:  Pascal.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_pas_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;

   // Special case for 'program':
   // If proc is 'program', limit the scope of this block to the first
   // occurrence of proc/func.
   _str ch = get_text( 4 );
   ch = lowcase( ch );
   if ( ch == 'prog' ) {
      sbstart_line = start_line + 1; sbstart_col = 1;
      typeless type=0;
      if ( cs_pas_next_proc( 0, type ) ) return( '' );
      end_line = p_line - 1; end_col = p_col;
      return( 'prog' );
   }

   // Search for the next 'begin':
   if ( cs_pas_next_begin( 1 ) ) return( '' );
   sbstart_line = p_line; sbstart_col = p_col;

   // Find the matching 'end':
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   end_line = p_line; end_col = p_col;
   return( 'begin' );
}


// Desc:  PL/SQL.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_plsql_procBlockBoundary( int &start_line, int &start_col,
                                     int &end_line,   int &end_col,
                                     int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;

   // Determine which keyword to look for.
   //    procedure --> begin
   //    function --> begin
   //    package --> as,begin
   //    declare --> begin
   //    trigger --> begin
   //
   //    if --> <right after the "if">
   //    begin --> <right after the "begin">
   typeless status=0;
   word_chars := _clex_identifier_chars();
   _str ch4, type;
   ch4 = lowcase(get_text(4));
   if (ch4 == "pack") {
      // Search for the next 'begin':
      type = "pack";
      if ( cs_plsql_next_begin(type, 1) ) return( '' );
      sbstart_line = p_line; sbstart_col = p_col;
   } else if (ch4 == "decl") {
      // For "declare" block, block starts right after the keyword.
      status = search("[~"word_chars"]|$","r@HXCS");
      if (status) return("");
      sbstart_line = p_line; sbstart_col = p_col;

      // Search for the next 'begin':
      if ( cs_plsql_next_begin("begin", 1) ) return( '' );
   } else if (ch4 == "func" || ch4 == "proc") {
      // For "procedure" and "function", the block starts right
      // after the "is" or "as":
      sbstart_line = p_line; sbstart_col = p_col;
      if (cs_plsql_is_proto()) {
         end_line = p_line; end_col = p_col;
         return("proto");
      }

      // Look for "is" or "as":
      status = search("is|as","rw@iHCK");
      if (status) return("");

      // Skip over is/as keyword:
      search("[~"word_chars"]|$","r@iHXCS");
      sbstart_line = p_line; sbstart_col = p_col;

      // Search for the next 'begin':
      type = "proc";
      if ( cs_plsql_next_begin(type, 0) ) return( '' );
   } else if (ch4 == "trig") {
      // For "procedure" and "function", the block starts right
      // after the "is" or "as":
      sbstart_line = p_line; sbstart_col = p_col;
      if (cs_plsql_is_proto()) {
         end_line = p_line; end_col = p_col;
         return("proto");
      }

      // Skip over is/as keyword:
      search("[~"word_chars"]|$","r@iHXCS");
      sbstart_line = p_line; sbstart_col = p_col;

      // Search for the next 'begin':
      type = "trig";
      if ( cs_plsql_next_begin(type, 0) ) return( '' );
   } else if (ch4 == "begi") {
      type = "begi";
      // Skip over "begin" keyword:
      int seek1;
      seek1 = _nrseek();
      search("[~"word_chars"]|$","r@iHXCS");
      sbstart_line = p_line; sbstart_col = p_col;
      _nrseek(seek1);  // go back so we can do the begin/end matching
   } else if (lowcase(get_text(2)) == "if") {
      type = "if";
      // Skip over "if" keyword:
      int seek1;
      seek1 = _nrseek();
      search("[~"word_chars"]|$","r@iHXCS");
      sbstart_line = p_line; sbstart_col = p_col;
      _nrseek(seek1);  // go back so we can do the if/endif matching
   } else {
      sbstart_line = p_line; sbstart_col = p_col;
      cs_nextSemicolon();
      end_line = p_line; end_col = p_col;
      return("other");
   }

   // Find the matching 'end':
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   //cs_skipKeyword();
   cs_nextSemicolon();
   end_line = p_line; end_col = p_col;
   return( 'begin' );
}


// Desc:  MODULA-2.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_mod_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Special case for 'module':
   // If proc is 'module', limit the scope of this block to the first
   // occurrence of proc/func.
   _str ch = get_text( 4 );
   ch = lowcase( ch );
   if ( ch == 'modu' ) {
      sbstart_line = start_line + 1; sbstart_col = 1;
      typeless type=0;
      if ( cs_mod_next_proc( 0, type ) ) return( '' );
      end_line = p_line - 1; end_col = p_col;
      return( 'modu' );
   }

   // Search for the next 'begin':
   if ( cs_pas_next_begin( 1 ) ) return( '' );
   sbstart_line = p_line; sbstart_col = p_col;

   // Find the matching 'end':
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   if ( cs_nextSemicolonOrDot() ) return( '' );
   end_line = p_line; end_col = p_col;
   return( 'begin' );
}


// Desc:  Ada.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_ada_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Find the matching block end:
   sbstart_line = p_line; sbstart_col = p_col;
   typeless type=0;
   if ( cs_ada_findBlockEnd( 0, type, 0, sbstart_line, sbstart_col ) ) {
      return( '' );
   }
   end_line = p_line; end_col = p_col;
   return( type );
}


// Desc:  Awk.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_awk_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Find the block start token '{'
   if ( cs_c_next_openCurly( 1 ) ) return( '' );

   // Find the matching block end:
   sbstart_line = p_line; sbstart_col = p_col;
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( '' );
   end_line = p_line; end_col = p_col;
   return( '{' );
}


// Desc:  Cobol.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_cob_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Find the matching block end:
   sbstart_line = p_line; sbstart_col = p_col;
   typeless type=0;
   if ( cs_cob_findBlockEnd( type, sbstart_line, sbstart_col ) ) {
      return( '' );
   }
   end_line = p_line; end_col = p_col;
   type = 'proc';
   return( type );
}


// Desc:  Fortran.  Determine the boundary of the proc block.
// Retn:  block type for OK, '' for error.
typeless cs_for_procBlockBoundary( int &start_line, int &start_col,
                                   int &end_line,   int &end_col, 
                                   int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Find the matching block end:
   sbstart_line = p_line; sbstart_col = p_col;
   _str stopLabel="";
   typeless type=0;
   if ( cs_for_findBlockEnd( 0, type, 0, sbstart_line, sbstart_col, stopLabel ) ) {
      return( '' );
   }
   end_line = p_line; end_col = p_col;
   return( type );
}


// Desc:  Initialize internal data structure.
static int cs_init()
{
   cs_bm_list = '';
   cs_bm_listcount = 0;
   cs_selected_level = -1;
   cs_last_target_l = cs_last_target_c = 0;
   cs_LangId = "";
   if ( cs_buildCallIndexProcList() ) {
      message("Select code block does not support files of this type." );
      return(1);
   }
   return(0);
}


// Desc:  Already at the start of a function.  Find the code block of this
//     function.
// Retn:  0 for OK, 1 for error.
static int cs_c_find_block( int &start_line, int &end_line )
{
   // Search for the next '{':
   if ( cs_c_next_openCurly( 1 ) ) return( 1 );
   start_line = p_line;

   // Find the matching '}':
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
   end_line = p_line;
   return( 0 );
}


// Desc:  Find the next '{'.
// Para:  no_skip            Flag: 1=if already on char, do nothing (don't skip)
// Retn:  0 for OK, 1 for not found.
static int cs_c_next_openCurly( boolean no_skip )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   boolean found = 0;
#if 0
   while ( !found ) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         // Found one...
         // If already at a '{', skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) return( 0 );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 1 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 0 );
#else
   //messageNwait("cs_c_next_openCurly: h1");
   typeless type=0;
   typeless status=search("[(|{]","ri@H");
   for(;;){
      if (status) {
         //messageNwait("cs_c_next_openCurly: done");
         return(1);
      }
      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status=repeat_search();
         continue;
      }
      ch=get_text();
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         status=repeat_search();
         continue;
      }
      if ( ch == '{' ) {
         // Found one...
         // If already at a '{', skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) return( 0 );
      }
      status=repeat_search();
   }
   return( 0 );
#endif
}


// Desc:  Get the extension of the current buffer.
// Para:  real_extension     Real extension
// Retn:  Extension.
static _str cs_getExtension( _str &real_extension )
{
   // We need to use the mode name in order to
   // handle embedded languages.
   _str lang = p_LangId;

   // Slick-C, java are treated the same as C:
   switch (lang) {
   case 'e':
   case 'java':
   case 'pl':
   case 'js':
   case 'phpscript':
   case 'idl':
   case 'rul':
   case 'cs':
   case 'as':
      lang = 'c';
      break;
   }

   return( lang );
}


// Desc:  Check to make sure that keyword 'begin' comes before 'end'.
//     This is used to verify that the proc/func keyword is the real proc header
//     and not a prototype/declaration.
//
//     TDate = class
//        Year: Integer;
//        Month: 1..12;
//        Day: 1..31;
//        procedure SetDate(D, M, Y: integer);      ==> declaration
//        function ShowDate: String;                ==> declaration
//     end;
//
//     procedure p1( var sum : integer );           ==> definition
//     var
//        a : integer;
//     begin  { processjunk }
//        sum := 0;
//        while 1 do
//           sum := sum + 100;
//     end; { begin }
//
// Retn:  1 for 'begin' before 'end', 0 for not.
static int cs_pas_is_beginBeforeEnd()
{
   int temp_line = p_line; 
   int temp_col = p_col;
   for(;;) {
      // Find the next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) {
         p_line = temp_line; p_col = temp_col;
         return( 0 );
      }

      // Not good if found 'end' first.  OK if found 'begin' first:
      // Skip over all other keywords.
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'en' ) {
         p_line = temp_line; p_col = temp_col;
         return( 0 );
      } else if ( ch == 'be' ) {
         p_line = temp_line; p_col = temp_col;
         return( 1 );
      }
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 0 );
}

// Desc: Check to see if "begin" is before "end" or ";".
//       This is used to determine if the proc/func is a proto.
//       If this is a prototype, the caret is moved to the end of the
//       proto.
// Retn: 1 proc/func is a proto, 0 not
static int cs_plsql_is_proto()
{
   int oldseekpos;
   oldseekpos = _nrseek();
   while (1) {
      int status;
      status = search("as|is|begin|end|;","r@iHXCS");
      if (status) {
         _nrseek(oldseekpos);
         return(0);
      }
      if (get_text() == ";") {
         return(1);
      }
      status = _clex_find(KEYWORD_CLEXFLAG, "G");
      if (status != CFG_KEYWORD) {
         _nrseek(_nrseek() + 1);
         continue;
      }

      // Not a proto... Restore original position.
      _nrseek(oldseekpos);
      return(0);
   }
   return(0);

   /*
   int oldseekpos;
   oldseekpos = _nrseek();
   for(;;) {
      // Find the next keyword:
      status = _clex_find(KEYWORD_CLEXFLAG, "G");

      if (status == CFG_KEYWORD) {
         if (lowcase(get_text(3)) == "end") {
            _nrseek(oldseekpos);
            return(0);
         } else if (lowcase(get_text(5)) == "begin") {
            _nrseek(oldseekpos);
            return(0);
         }
         cs_skipKeyword();
         continue;
      } else if (status == CFG_STRING) {
         // Skip over string:
         status = _clex_find(STRING_CLEXFLAG, "N");
         if (status) {
            _nrseek(oldseekpos);
            return(0);
         }
         continue;
      } else if (status == CFG_COMMENT) {
         // Skip over comment:
         status = _clex_find(COMMENT_CLEXFLAG, "N");
         if (status) {
            _nrseek(oldseekpos);
            return(0);
         }
         continue;
      } else {
         ch = get_text();
         if (ch == ";") {
            _nrseek(oldseekpos);
            return(1);
         } else if (ch == "(") {
            if (_find_matching_paren(def_pmatch_max_diff)) {
               _nrseek(oldseekpos);
               return(0);
            }
         }
         _nrseek(_nrseek() + 1);
      }
   }
   return( 0 );
   */
}

// Desc: Check to see if this is a "table" or a "table" proto.
// Retn: 1 table is a proto, 0 not
static int cs_plsql_is_tableproto()
{
   int oldseekpos;
   oldseekpos = _nrseek();
   while (1) {
      int status;
      status = search("[(;]","r@iHXCS");
      if (status) {
         _nrseek(oldseekpos);
         return(0);
      }
      if (get_text() == ";") {
         return(1);
      }

      // Not a proto... Restore original position.
      _nrseek(oldseekpos);
      return(0);
   }
   return(0);
}


// Desc:  Check to see if the keyword under the caret is semicolon terminated.
// Retn:  1 for semicolon terminated, 0 for not.
static int cs_is_semicolonTerminated()
{
   // Skip over keyword:
   int temp_line = p_line; 
   int temp_col = p_col;
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();

   // Find the next non-white space character:
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   while ( pos( ch, " \t\n\f\r\v" ) ){
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) {
         p_line = temp_line; p_col = temp_col;
         return( 0 );
      }
      ch = get_text();
   }
   p_line = temp_line; p_col = temp_col;
   if ( ch == ';' ) return( 1 );
   return( 0 );
}


// Desc:  Find the next 'end' keyword.
// Retn:  0 for found, 1 for not.
static int cs_pas_findNextEnd()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'en' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'end' keyword.
// Retn:  0 for found, 1 for not.
static int cs_plsql_findNextEnd()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'en' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'of' keyword.
// Retn:  0 for found, 1 for not.
static int cs_pas_findNextOf()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'of' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'of' keyword.
// Retn:  0 for found, 1 for not.
static int cs_plsql_findNextOf()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'of' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'until' keyword.
// Retn:  0 for found, 1 for not.
static int cs_pas_findMatchingUntil()
{
   for(;;) {
      //messageNwait( 'here' );
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 3 ); ch = lowcase( ch );
      if ( ch == 'unt' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Find the next 'until' keyword.
// Retn:  0 for found, 1 for not.
static int cs_plsql_findMatchingUntil()
{
   for(;;) {
      //messageNwait( 'here' );
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 3 ); ch = lowcase( ch );
      if ( ch == 'unt' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}

/*
// Desc:  Go to next semicolon.
// Retn:  0 for OK, 1 for error.
static typeless cs_nextSemicolon()
{
   if ( cs_skipSpaces() == -1 ) return( 1 );
   seek_pos = _nrseek();
   ch = get_text();
   for(;;) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         status = _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == ';' ) {
         return( 0 );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 1 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 1 );
}
*/

// Desc:  Go to next semicolon.
// Retn:  0 for OK, 1 for error.
static typeless cs_nextSemicolon()
{
   while (1) {
      int status;
      status = search("[({;]","r@HXCS");
      if (status) return(1);
      _str ch;
      ch = get_text();
      if (ch == "(" || ch == "{") {
         _find_matching_paren(def_pmatch_max_diff);
         continue;
      } else {
         return(0);
      }
   }
   return(0);
}


// Desc:  Go to next semicolon or dot.
// Retn:  0 for OK, 1 for error.
static typeless cs_nextSemicolonOrDot()
{
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   for(;;) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         status = _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == ';' || ch == '.' ) {
         return( 0 );
      }

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 1 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 1 );
}


// Desc:  Java.  Determine the start and end of the proc block.
//     In Java, the 'proc' block is actually the class block.  The individual
//     methods are just sub code blocks inside the class block.
// Retn:  0 for OK, 1 for not found.
int cs_java_findProcBlock( int &start_line, int &start_col,
                           int &end_line,   int &end_col )
{
   // Try to find the proc starting from cs_stepback_size characters backup:
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless type=0;
   typeless status = cs_java_next_proc( 1, type );
   if ( status ) return( 1 );

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         status = cs_c_next_openCurly( 0 );
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            end_line = p_line; end_col = p_col;
            //say( 'Found proc1 start='start_line' 'start_col' end='end_line' 'end_col );
            return( 0 );
         }

         // Find next proc:
         status = cs_java_next_proc( 0, type );
      }
      return( 1 );
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   status = cs_java_next_proc( 1, type );

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_c_next_openCurly( 0 );
      if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         end_line = p_line; end_col = p_col;
         //say( 'Found proc2 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }

      // Find next proc:
      status = cs_java_next_proc( 0, type );
   }
   return( 1 );
}


// Desc:  Java.  Find the next class.
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'class'
// Retn:  0 for OK, 1 for not found.
static int cs_java_next_proc( boolean no_skip, typeless &type )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for 'class'
      typeless seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'cl' ) {
         // Found one...
         // If already at a proc, skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            type = 'class';
            return( 0 );
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  MODULA-2.  Determine the start and end of the proc block.
//     If inside proc or func, found.  If outside any proc/func and inside
//     'module' and corresponding 'end.', take module block.
// Retn:  0 for OK, 1 for not found.
int cs_mod_findProcBlock( int &start_line, int &start_col,
                          int &end_line,   int &end_col )
{
   // Try to find the proc starting from cs_stepback_size characters backup:
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless type=0;
   typeless status = cs_mod_next_proc( 1, type );
   if ( status ) {
      // Maybe inside 'main' code block:
      p_line = ori_line; p_col = ori_col;
      if ( cs_mod_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main0 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }
      return( 1 );
   }

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         status = cs_pas_next_begin( 0 );
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            // Skip over the 'end' keyword:
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            if ( cs_nextSemicolon() ) return( 1 );
            end_line = p_line; end_col = p_col;
            //say( 'Found proc1 start='start_line' 'start_col' end='end_line' 'end_col );
            return( 0 );
         }

         // Find next proc:
         status = cs_mod_next_proc( 0, type );
      }

      // Maybe inside 'main' code block:
      p_line = ori_line; p_col = ori_col;
      if ( cs_mod_is_inmain( start_line, start_col, end_line, end_col ) ) {
         //say( 'Found main1 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }
      return( 1 );
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   status = cs_mod_next_proc( 1, type );

   // Special case if the first proc is 'module':
   if ( type == 'modu' ) {
      // Find the 'end.' and take the whole thing:
      status = cs_mod_next_enddot( 1 );
      if ( status ) return( 1 );
      start_line = 1; start_col = 1;
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
      cs_mod_nextDot();
      end_line = p_line; end_col = p_col;
      //say( 'Found main2 start='start_line' 'start_col' end='end_line' 'end_col );
      return( 0 );
   }

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_pas_next_begin( 0 );
      if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         // Skip over the 'end' keyword:
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_nextSemicolon() ) return( 1 );
         end_line = p_line; end_col = p_col;
         //say( 'Found proc2 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }

      // Find next proc:
      status = cs_mod_next_proc( 0, type );
   }
   return( 1 );
}


// Desc:  MODULA-2.  Find the next procedure.
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'proc', 'modu'
// Retn:  0 for OK, 1 for not found.
static int cs_mod_next_proc( boolean no_skip, typeless &type )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for PROCEDURE:
      typeless seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'pr' ) {
         // Found one...
         // If already at a proc, skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            type = 'proc';
            return( 0 );
         }
      } else if ( ch == 'mo' ) {       // 'module'
         ch = get_text( 4 );
         ch = lowcase( ch );
         if ( ch == 'modu' ) {
            // Found one...
            // If already at a proc, skip over this one to find the next:
            if ( no_skip || p_line != temp_l || p_col != temp_c ) {
               type = 'modu';
               return( 0 );
            }
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  MODULA-2.  Check to see if the caret is inside main code block.
// Retn:  1 for in main, 0 for not.
static int cs_mod_is_inmain( int &start_line, int &start_col,
                             int &end_line, int &end_col )
{
   // Search for 'end <id>.' keyword:
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless status = cs_mod_next_enddot( 1 );
   if ( status ) return( 0 );

   // Skip over the keyword and mark the position:
   typeless seek_pos = _nrseek();
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   if ( ori_line > p_line ) return( 0 );

   // Skip to the '.'
   if ( cs_mod_nextDot() ) return( 0 );
   end_line = p_line; end_col = p_col;

   // Find matching 'begin':
   _nrseek( seek_pos );
   if ( _find_matching_paren(def_pmatch_max_diff) ) return( 0 );

   // Inside main:
   if ( cs_is_withinbounds( ori_line, ori_col, p_line, p_col,
            end_line, end_col ) ) {
      start_line = p_line; start_col = p_col;
      return( 1 );
   }
   return( 0 );
}


// Desc:  MODULA-2.  Find the next 'end.' keyword.  The caret position may be before the
//     keyword.  It may also be right on the keyword.
// Retn:  0 for OK, 1 for not found.
static int cs_mod_next_enddot(...)
{
   // Check to make sure that caret is not directly over a keyword:
   // If it is, back up to the beginning of that keyword.
   int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
   if ( type == CFG_KEYWORD ) {
      // Find the beginning of this keyword:
      typeless seek_pos=0;
      while ( type == CFG_KEYWORD ) {
         seek_pos = _nrseek() - 1;
         _nrseek( seek_pos );
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      }
      _nrseek( seek_pos + 1 );
   }

   // Search for 'end.'
   int temp_l = p_line; 
   int temp_c = p_col;
   for(;;) {
      // Look for next keyword:
      typeless status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );

      // Look for END (b*):
      typeless seek_pos = _nrseek();
      _str ch = get_text( 2 );
      ch = lowcase( ch );
      if ( ch == 'en' ) {
         // Make sure this one has the dot somewhere after on the same line:
         // If not, do nothing.
         int temp_line = p_line; 
         int temp_col = p_col;
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( !cs_mod_nextDot() ) {
            p_line = temp_line; p_col = temp_col;
            return( 0 );
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  MODULA-2.  Go to next dot.  Dot must be on the same line.
// Retn:  0 for OK, 1 for error.
static typeless cs_mod_nextDot()
{
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   for(;;) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         typeless status = _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == "\n" || ch == "\r" ) return( 1 );
      if ( ch == ';' ) return( 1 );
      if ( ch == '.' ) return( 0 );

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         typeless status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 1 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 1 );
}


// Desc:  MODULA-2.  Determine the boundary of the code block.  The caret
//     must be at the start of a keyword.
// Retn:  block type for OK, '' for error.
int cs_mod_blockBoundary( int &start_line, int &start_col,
                          int &end_line,   int &end_col, 
                          int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;
   start_line = p_line; start_col = p_col;

   // Locate ;, begin, record, repeat, if, while, for, case
   typeless ch = cs_mod_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc:  Locate the next ;, or begin, record, repeat, case, if, while, for,
//     and their matching block markers.
//
//     ;
//     begin <==> end
//     record <==> end
//     repeat <==> until
//     case <==> end
//     if <==> end
//     while <==> end
//     for <==> end
// Retn:  ';', begin, record, repeat, case, if, while, for, or ''
//     if neither is found.
static typeless cs_mod_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless type=0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   boolean found = 0;
   while ( !found ) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'b' ) {               // begin
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'be' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'begin' );
            }
         }
      } else if ( ch == 'c' ) {        // case
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'ca' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'case' );
            }
         }
      } else if ( ch == 'i' ) {        // if
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'if' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'if' );
            }
         }
      } else if ( ch == 'w' ) {        // while or with
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            ch = get_text( 2 ); ch = lowcase( ch );
            if ( ch == 'wh' ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'while' );
            } else if ( ch == 'wi' ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'with' );
            }
         }
      } else if ( ch == 'f' ) {        // for
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'fo' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) {
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'for' );
            }
         }
      } else if ( ch == 'r' ) {        // record or repeat
         type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
         if ( type == CFG_KEYWORD ) {
            ch = get_text( 3 ); ch = lowcase( ch );
            if ( ch == 'rec' ) {                 // record
               sbstart_line = p_line; sbstart_col = p_col;
               status = cs_pas_findNextEnd();
               if ( status ) return( '' );
               return( 'record' );
            } else if ( ch == 'rep' ) {          // repeat
               sbstart_line = p_line; sbstart_col = p_col;
               status = _find_matching_paren(def_pmatch_max_diff);
               if ( status ) return( '' );
               return( 'repeat' );
            }
         }
      }
      if ( ch == ';' ) {
         return( ';' );
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  MODULA-2.  Find the next 'then' keyword.
// Retn:  0 for found, 1 for not.
static int cs_mod_findNextThen()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'th' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  MODULA-2.  Find the next 'do' keyword.
// Retn:  0 for found, 1 for not.
static int cs_mod_findNextDo()
{
   for(;;) {
      int status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'do' ) return( 0 );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Ada.  From the block start keyword, find the matching block
//     ending keyword.
//
//     if ... then          ==> end if ;
//     begin                ==> end ____ ;
//     case ... is          ==> end case ;
//     loop                 ==> end loop ;
//     accept ... do        ==> end ____ ;
//     select               ==> end select ;
//     record               ==> end record ;
//
//     procedure ... is     ==> begin ==> end ____ ;
//     function ... is      ==> begin ==> end ____ ;
//     package ... is       ==> end ____ ;
//     package body ... is  ==> begin ==> end ____ ;
//     task ... is          ==> end ____ ;
//     task body ... is     ==> begin ==> end ____ ;
//
// Para:  type               Returned block type
// Retn:  0 for found, 1 for not, 3 for stopped at begin.
static int cs_ada_findBlockEnd( int level, typeless &type, int stopAtBegin,
                                int &sbstart_line, int &sbstart_col )
{
   for(;;) {
      // Get next keyword:
      //messageNwait( 'b4 next key' );
      int status = _clex_find( KEYWORD_CLEXFLAG );
      //messageNwait( 'after next key' );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );

      // Check for block end keyword, 'end'
      if ( ch == 'en' ) {
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'end' ) {
            if ( !level ) return( 1 );      // Find 'end' before 1st block
            return( 0 );
         }
      }

      // Skip over the block associated with this keyword:
      typeless rtype=0;
      int tl=0, tc=0;
      if ( ch == 'if' ) {                     // if
         tl = p_line; tc = p_col;
         rc = cs_ada_nextThen();
         if ( rc == '' || rc == ';' ) return( 1 );
         sbstart_line = p_line; sbstart_col = p_col;
         p_line = tl; p_col = tc;
         status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'if';
         return( 0 );
      } else if ( ch == 'be' ) {              // begin
         sbstart_line = p_line; sbstart_col = p_col;
         if ( stopAtBegin ) {
            //messageNwait( 'stop at begin' );
            return( 3 );
         }
         status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'begin';
         return( 0 );
      } else if ( ch == 'ca' ) {              // case
         tl = p_line; tc = p_col;
         rc = cs_ada_nextIs();
         if ( rc == '' || rc == ';' || rc == 'body' ) return( 1 );
         sbstart_line = p_line; sbstart_col = p_col;
         p_line = tl; p_col = tc;
         status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'case';
         return( 0 );
      } else if ( ch == 'lo' ) {              // loop
         sbstart_line = p_line; sbstart_col = p_col;
         status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'loop';
         return( 0 );
      } else if ( ch == 'se' ) {              // select
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'sel' ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'select';
            return( 0 );
         }
      } else if ( ch == 'ac' ) {              // accept
         ch = get_text( 5 ); ch = lowcase( ch );
         if ( ch == 'accep' ) {
            tl = p_line; tc = p_col;
            rc = cs_ada_nextDo();
            if ( rc == '' || rc == ';' ) return( 1 );
            sbstart_line = p_line; sbstart_col = p_col;
            p_line = tl; p_col = tc;
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'accept';
            return( 0 );
         }
      } else if ( ch == 're' ) {              // record
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'rec' ) {
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'record';
            return( 0 );
         }
      } else if ( ch == 'pa' ) {              // package
         rc = cs_ada_nextIs();
         if ( rc == '' || rc == ';' ) return( 1 );
         if ( rc == 'is' ) {           // is
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'packageis';
            return( 0 );
         } else {                      // body
            // Skip over 'body' and go to 'is'
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            rc = cs_ada_nextIs();
            if ( rc != 'is' ) return( 1 );
            sbstart_line = p_line; sbstart_col = p_col;

            // Find the 'begin' or ';'
            status = cs_ada_nextBlockEnd( level, rtype, 1, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;

            // Find matching 'end'
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'packagebodyis';
            return( 0 );
         }
      } else if ( ch == 'ta' ) {              // task
         rc = cs_ada_nextIs();
         if ( rc == '' || rc == ';' ) return( 1 );
         if ( rc == 'is' ) {           // is
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'taskis';
            return( 0 );
         } else {                      // body
            // Skip over 'body' and go to 'is'
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            rc = cs_ada_nextIs();
            if ( rc != 'is' ) return( 1 );
            sbstart_line = p_line; sbstart_col = p_col;

            // Find the 'begin' or ';'
            status = cs_ada_nextBlockEnd( level, rtype, 1, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;

            // Find matching 'end'
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'taskbodyis';
            return( 0 );
         }
      } else if ( ch == 'fu' ) {              // function
         rc = cs_ada_nextIs();
         if ( rc == '' ) return( 1 );
         if ( rc == ';' ) continue;
         sbstart_line = p_line; sbstart_col = p_col;

         // Find the 'begin' or ';'
         //messageNwait( 'function h1' );
         status = cs_ada_nextBlockEnd( level, rtype, 1, sbstart_line, sbstart_col );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;

         // Find matching 'end'
         //messageNwait( 'function h2' );
         status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
         //messageNwait( 'function h3 status='status' level='level );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'function';
         return( 0 );
      } else if ( ch == 'pr' ) {              // procedure
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'pro' ) {
            //messageNwait( 'h1' );
            rc = cs_ada_nextIs();
            //messageNwait( 'h2' );
            if ( rc == '' ) return( 1 );
            if ( rc == ';' ) continue;
            sbstart_line = p_line; sbstart_col = p_col;

            // Find the 'begin' or ';'
            //messageNwait( 'h3' );
            status = cs_ada_nextBlockEnd( level, rtype, 1, sbstart_line, sbstart_col );
            //messageNwait( 'h4' );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;

            // Find matching 'end'
            //messageNwait( 'function h2' );
            status = cs_ada_nextBlockEnd( level, rtype, 0, sbstart_line, sbstart_col );
            //messageNwait( 'function h3 status='status' level='level );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'procedure';
            return( 0 );
         }
      }

      // Skip over this keyword:
      //messageNwait( 'skip over unused keyword' );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
}


// Desc:  Ada.  Recurse and find end of new block.
// Retn:  0 for found but stop, 1 for error, 2 for found and continue
static int cs_ada_nextBlockEnd( int level, typeless &type, int stopAtBegin,
                                int sbstart_line, int sbstart_col )
{
   //messageNwait( 'hh1' );
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   cs_skipKeyword();
   //messageNwait( 'hh2' );
   typeless rtype=0;
   rc = cs_ada_findBlockEnd( level + 1, rtype, stopAtBegin, sbstart_line,
            sbstart_col );
   if ( rc == 1 ) return( 1 );
   if ( rc == 3 ) return( 0 );
   if ( level ) {
      cs_nextSemicolon();
      return( 2 );
   }
   return( 0 );
}


// Desc:  Ada.  Find the next 'is', 'body', or semicolon.
// Retn:  'is', ';', or '' for error.
static typeless cs_ada_nextIs()
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless type=0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'i' ) {               // is
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'is' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 'is' );
         }
      } else if ( ch == 'b' ) {        // body
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'bo' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 'body' );
         }
      }
      if ( ch == ';' ) return( ';' );

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Ada.  Find the next 'begin'.
// Retn:  0 for OK, 1 for error.
static typeless cs_ada_nextBegin()
{
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless type = 0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'b' ) {               // begin
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'be' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 0 );
         }
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         cs_skipSpaces();
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 0 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 0 );
}


// Desc:  Ada.  Find the next 'then'.
// Retn:  'then', or '' for error.
static typeless cs_ada_nextThen()
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless type = 0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         cs_skipSpaces();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 't' ) {               // then
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'th' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 'then' );
         }
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         cs_skipSpaces();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Ada.  Find the next 'do'.
// Retn:  0 for OK, 1 for error.
static typeless cs_ada_nextDo()
{
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless type = 0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 'd' ) {               // do
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'do' ) {
            type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 'then' );
         }
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Skip over the current keyword.
//     As of 4/1/1996, there is a bug with skipping over keyword using
//     _clex_find( KEYWORD_CLEXFLAG, 'N' ) when two or more consecutive
//     keywords are on separate lines.  _clex_find() skips over multiple
//     keywords.
static void cs_skipKeyword()
{
   typeless seek_pos = _nrseek();
   int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
   while ( type == CFG_KEYWORD ) {
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return;
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
   }
}


// Desc:  Skip over the current string and/or comment.
static void cs_skipStringComment()
{
   typeless seek_pos = _nrseek();
   int type = _clex_find( STRING_CLEXFLAG, 'G' );
   while ( type == CFG_STRING || type == CFG_COMMENT ) {
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return;
      type = _clex_find( STRING_CLEXFLAG, 'G' );
   }
}


// Desc:  Skip over the semicolon at the cursor.
static void cs_skipSemiColonAtCursor()
{
   _str ch;
   ch = get_text();
   if (ch != ";") return;
   _nrseek(_nrseek() + 1);
}


// Desc:  Ada.  Find the next procedure, function, task, package.
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'proc', 'func', 'task', 'pack'
// Retn:  0 for OK, 1 for not found.
static int cs_ada_next_proc( boolean no_skip, typeless &type )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   int temp_line = 0;
   int temp_col  = 0;
   typeless status = 0;
   for(;;) {
      // Look for next keyword:
      status = _clex_find( KEYWORD_CLEXFLAG );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );
      if ( ch == 'fu' ) {                   // function
         // Must begin with 'is'...  Everything else means a prototype.
         temp_line = p_line; temp_col = p_col;
         rc = cs_ada_nextIs();
         if ( rc == '' ) return( 1 );
         if ( rc == ';' ) continue;
         type = 'func';
         p_line = temp_line; p_col = temp_col;
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            return( 0 );
         }
      } else if ( ch == 'pr' ) {            // procedure
         // Must begin with 'is'...  Everything else means a prototype.
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'pro' ) {
            temp_line = p_line; temp_col = p_col;
            rc = cs_ada_nextIs();
            if ( rc == '' ) return( 1 );
            if ( rc == ';' ) continue;
            type = 'proc';
            p_line = temp_line; p_col = temp_col;
            if ( no_skip || p_line != temp_l || p_col != temp_c ) {
               return( 0 );
            }
         }
      } else if ( ch == 'ta' ) {                   // task
         // Must begin with 'is'...  Everything else means a prototype.
         temp_line = p_line; temp_col = p_col;
         rc = cs_ada_nextIs();
         if ( rc == '' ) return( 1 );
         if ( rc == ';' ) continue;
         type = 'task';
         p_line = temp_line; p_col = temp_col;
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            return( 0 );
         }
      } else if ( ch == 'pa' ) {                   // package
         // Must begin with 'is'...  Everything else means a prototype.
         temp_line = p_line; temp_col = p_col;
         rc = cs_ada_nextIs();
         if ( rc == '' ) return( 1 );
         if ( rc == ';' ) continue;
         type = 'pack';
         p_line = temp_line; p_col = temp_col;
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            return( 0 );
         }
      }

      // Skip over this keyword:
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
   return( 1 );
}


// Desc:  Ada.  Determine the start and end of the proc block.
//     Since Ada does not have an outer most code block (like 'class' block in
//     java), this function can only estimate the highest scope code block
//     that contains the caret.  Ada can have proc nested inside proc and,
//     therefore, the outermost proc can not be easily determined.
// Retn:  0 for OK, 1 for not found.
int cs_ada_findProcBlock( int &start_line, int &start_col,
                          int &end_line,   int &end_col )
{
   // Try to find the proc starting from cs_stepback_size characters backup:
   //
   // If the start of the true outer most proc is actually more than cs_stepback_size
   // characters up, this function will pick the wrong proc.  Too bad!
   // In any case, the function will pick the closest, highest scoped proc
   // that contains the caret.
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless type = 0;
   typeless status = cs_ada_next_proc( 1, type );
   if ( status ) return( 1 );

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   typeless sbstart_line=0;
   typeless sbstart_col=0;
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         status = cs_ada_findBlockEnd( 0, type, 0, sbstart_line, sbstart_col );
         if ( status ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            // Skip over the 'end' keyword:
            //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
            cs_skipKeyword();
            if ( cs_nextSemicolon() ) return( 1 );
            end_line = p_line; end_col = p_col;
            //say( 'Found proc1 start='start_line' 'start_col' end='end_line' 'end_col );
            return( 0 );
         }

         // Find next proc:
         status = cs_ada_next_proc( 0, type );
      }

      // Fall thru...  Try the entire file:
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   status = cs_ada_next_proc( 1, type );

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_ada_findBlockEnd( 0, type, 0, sbstart_line, sbstart_col );
      if ( status ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         // Skip over the 'end' keyword:
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_nextSemicolon() ) return( 1 );
         end_line = p_line; end_col = p_col;
         //say( 'Found proc2 start='start_line' 'start_col' end='end_line' 'end_col );
         return( 0 );
      }

      // Find next proc:
      status = cs_ada_next_proc( 0, type );
   }
   return( 1 );
}


// Desc:  Ada.  Determine the boundary of the code block.  The caret
//     must be at the start of a keyword.
// Retn:  block type for OK, '' for error.
int cs_ada_blockBoundary( int &start_line, int &start_col,
                          int &end_line,   int &end_col, 
                          int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;
   start_line = p_line; start_col = p_col;

   // Locate ;, begin, record, repeat, if, while, for, case
   typeless ch = cs_ada_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc:  Fortran.  Determine the boundary of the code block.  The caret
//     must be at the start of a keyword.
// Retn:  block type for OK, '' for error.
int cs_for_blockBoundary( int &start_line, int &start_col,
                          int &end_line,   int &end_col, 
                          int &sbstart_line, int &sbstart_col )
{
   // Init:
   sbstart_line = 0; sbstart_col = 0;
   start_line = p_line; start_col = p_col;

   // Locate ;, begin, record, repeat, if, while, for, case
   typeless ch = cs_for_locateStartEnd( sbstart_line, sbstart_col );
   end_line = p_line; end_col = p_col;
   //say( 'ch='ch' start='start_line' 'start_col', end='end_line' 'end_col );

   return( ch );
}


// Desc:  Locate the next ; or if, begin, case, loop, procedure, function,
//     package, accept, select, and task and their matching block markers.
//
//     ;
//     if ... then          ==> end if ;
//     begin                ==> end ____ ;
//     case ... is          ==> end case ;
//     loop                 ==> end loop ;
//     accept ... do        ==> end ____ ;
//     select               ==> end select ;
//     record               ==> end record ;
//
//     procedure ... is     ==> begin ==> end ____ ;
//     function ... is      ==> begin ==> end ____ ;
//     package ... is       ==> end ____ ;
//     package body ... is  ==> begin ==> end ____ ;
//     task ... is          ==> end ____ ;
//     task body ... is     ==> begin ==> end ____ ;
//
// Retn:  ';', keyword, or '' if neither is found.
static typeless cs_ada_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   cs_skipSpaces();
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless status = 0;
   typeless rtype = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   boolean found = 0;
   while ( !found ) {
      //say( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'if' || ch == 'be' || ch == 'ca' || ch == 'lo' ||
               ch == 'pa' || ch == 'ta' ) {
            status = cs_ada_findBlockEnd( 0, rtype, 0, sbstart_line,
                     sbstart_col );
            if ( status ) return( '' );
            return( rtype );
         } else if ( ch == 'se' || ch == 're' ) {
            ch = get_text( 3 ); ch = lowcase( ch );
            if ( ch == 'sel' || ch == 'rec' ) {
               status = cs_ada_findBlockEnd( 0, rtype, 0, sbstart_line,
                        sbstart_col );
               if ( status ) return( '' );
               return( rtype );
            }
         } else if ( ch == 'ac' ) {
            ch = get_text( 5 ); ch = lowcase( ch );
            if ( ch == 'accep' ) {
               status = cs_ada_findBlockEnd( 0, rtype, 0, sbstart_line,
                        sbstart_col );
               if ( status ) return( '' );
               return( rtype );
            }
         } else if ( ch == 'fu' || ch == 'pr' ) {
            ch = get_text( 3 ); ch = lowcase( ch );
            if ( ch == 'fun' || ch == 'pro' ) {
               int tl = p_line; 
               int tc = p_col;
               rc = cs_ada_nextIs();
               //messageNwait( 'rc='rc );
               if ( rc == '' ) return( 1 );
               if ( rc == ';' ) return( ';' );
               p_line = tl; p_col = tc;
               status = cs_ada_findBlockEnd( 0, rtype, 0, sbstart_line,
                        sbstart_col );
               if ( status ) return( '' );
               return( rtype );
            }
         }
      }
      if ( ch == ';' ) return( ';' );

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Fortran.  Locate the next "\n", "\r" or if, do, subroutine, function,
//     and program and their matching block markers.
//
//     "\n", "\r"
//     if ... then          ==> endif
//     do                   ==> end do
//     do <label>           ==> <label> continue
//
//     subroutine           ==> end
//     function             ==> end
//     program              ==> end
//
// Retn:  ';', keyword, or '' if neither is found.
static typeless cs_for_locateStartEnd( int &sbstart_line, int &sbstart_col )
{
   if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
   typeless rtype = 0;
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   _str stopLabel="";
   boolean found = 0;
   while ( !found ) {
      //messageNwait( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
      if ( type == CFG_KEYWORD ) {
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'if' ) {
            stopLabel="";
            status = cs_for_findBlockEnd( 0, rtype, 1, sbstart_line,
                     sbstart_col, stopLabel );
            if ( status ) return( '' );
            return( rtype );
         } else if ( ch == 'do' ) {
            ch = get_text( 3 ); ch = lowcase( ch );
            if ( ch != 'dou' ) {
               status = cs_for_findBlockEnd( 0, rtype, 0, sbstart_line,
                        sbstart_col, stopLabel );
               if ( status ) return( '' );
               return( rtype );
            }
         }
      }
      if ( ch == "\n" || ch == "\r" ) return( ';' );

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Awk.  Determine the start and end of the proc block.
// Retn:  0 for OK, 1 for not found.
int cs_awk_findProcBlock( int &start_line, int &start_col,
                          int &end_line,   int &end_col )
{
   // Try to find the proc starting from N characters backup:
   int ori_line = p_line; 
   int ori_col = p_col;

#if 1
   // Since AWK proc block rules are so lenient, the step-back size is
   // increased to improve the pobability of hitting the real code block.
   // (Anything enclosed by {} is a proc block.)
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   int last_line = p_line; 
   int last_col = p_col;
   typeless type = 0;
   typeless status = cs_awk_next_proc( 1, type );
   if ( status ) return( 1 );

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            // Keep the ending:
            end_line = p_line; end_col = p_col;
            // Start from end of last proc block, find start of current block:
            p_line = last_line; p_col = last_col;
            if ( cs_skipSpaces() == -1 ) return( 1 );
            start_line = p_line; start_col = p_col;
            return( 0 );
         }
         last_line = p_line; last_col = p_col + 1;

         // Find next proc:
         status = cs_awk_next_proc( 0, type );
         if ( !status && p_line > ori_line ) {
            // Even though we may have gone passed the original point,
            // the caret may still be inside the pattern-action pair.
            // Need to back track and check for this condition:
            int tl = p_line; 
            int tc = p_col;
            p_line = last_line; p_col = last_col;
            if ( cs_skipSpaces() == -1 ) return(1);
            if ( p_line > ori_line ) return( 1 );
            p_line = tl; p_col = tc;
         }
      }

      // Fall thru and try the entire file:
      // ...
   }
#endif

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   last_line = p_line; last_col = p_col;
   status = cs_awk_next_proc( 1, type );

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         // Keep the ending:
         end_line = p_line; end_col = p_col;
         // Start from end of last proc block, find start of current block:
         p_line = last_line; p_col = last_col;
         if ( cs_skipSpaces() == -1 ) return(1);
         start_line = p_line; start_col = p_col;
         return( 0 );
      }
      last_line = p_line; last_col = p_col + 1;

      // Find next proc:
      status = cs_awk_next_proc( 0, type );
      if ( !status && p_line > ori_line ) {
         // Even though we may have gone passed the original point,
         // the caret may still be inside the pattern-action pair.
         // Need to back track and check for this condition:
         int tl = p_line; 
         int tc = p_col;
         p_line = last_line; p_col = last_col;
         if ( cs_skipSpaces() == -1 ) return(1);
         if ( p_line > ori_line ) return( 1 );
         p_line = tl; p_col = tc;
      }
   }
   return( 1 );
}


// Desc:  Awk.  Find the next proc block.
//
//     -- xxxxxx   { ... }
//     -- xxxxxx
//        {
//          ...
//        }
//     -- {
//          ...
//        }
//
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
//        type               Returned type: 'proc', 'func', 'task', 'pack'
// Retn:  0 for OK, 1 for not found.
static int cs_awk_next_proc( boolean no_skip, typeless &type )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   for(;;) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( 1 );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         if ( no_skip || p_line != temp_l || p_col != temp_c ) {
            return( 0 );
         }
      }

      // Skip over comment and string:
      type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         int status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return(1);
      ch = get_text(); ch = lowcase( ch );
   }
   return( 1 );
}


// Desc:  Find the next ';', 'n', '{', or '}'
// Para:  no_skip            Flag: 1=if already on char, do nothing (don't skip)
// Retn:  '{', '}', ';', 'n', or '' for not found.
static typeless cs_awk_nextEOLN( boolean no_skip )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   int last_line = p_line; 
   int last_col = p_col;
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      // Detect EOLN:
      if ( p_line > last_line ) {
         p_line = last_line; p_col = last_col;
         return( 'n' );
      }
      //messageNwait( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         last_line = p_line; last_col = p_col;
         //cs_skipSpaces();
         ch = get_text();
         continue;
      } else if ( ch == ';' || ch == '{' || ch == '}' ) {
         // Found one...
         // If already at a '\n', skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) return( ch );
      }

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         cs_skipStringComment();
         last_line = p_line; last_col = p_col;
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         cs_skipKeyword();
         last_line = p_line; last_col = p_col;
         //cs_skipSpaces();
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      last_line = p_line; last_col = p_col;
      if ( cs_skipSpaces() ) {
         seek_pos = _nrseek();
      } else {
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
      }
      ch = get_text(); ch = lowcase( ch );
   }
}


// Desc:  Find the next '('.
// Para:  no_skip            Flag: 1=if already on char, do nothing (don't skip)
// Retn:  0 for OK, 1 for not found.
static int cs_awk_next_openParen( boolean no_skip )
{
   int temp_l = p_line; 
   int temp_c = p_col;
   if ( cs_skipSpaces() == -1 ) return( 1 );
   typeless status = 0;
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   boolean found = 0;
   while ( !found ) {
      if ( ch == '(' ) {
         // Found one...
         // If already at a '(', skip over this one to find the next:
         if ( no_skip || p_line != temp_l || p_col != temp_c ) return( 0 );
      }

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( 1 );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( 1 );
      ch = get_text(); ch = lowcase( ch );
   }
   return( 0 );
}

static void end_line2()
{
   // We want to use the original _end_line() and not end_line()
   // with code to search backward for first non-blank.
   _end_line();
}

// Desc:  Cobol.  Determine the start and end of the proc block.
// Retn:  0 for OK, 1 for not found.
int cs_cob_findProcBlock( int &start_line,  int &start_col,
                          int &ending_line, int &ending_col )
{
   // Check to see if current line is the start of a code block:
   int ori_line = p_line; 
   int ori_col = p_col;
   p_col = 1;
   if ( cs_skipSpaces() == -1 ) return( 1 );
   start_line = p_line; start_col = p_col;

   // If in comment or continuation line or in a sub block,
   // scan upward to determine the start of the code block.
   if (p_col == 7 || p_col > 8) {
      for(;;) {
         if ( p_line > 1 ) {
            p_line = p_line - 1; p_col = 1;
         } else {
            start_line = p_line; start_col = p_col;
            break;
         }
         if ( cs_skipLeadingSpacesInLine() == -1 ) return( 1 );

         // Handle continuation:
         if ( p_col == 7 ) continue;

         // Found the block start:
         if ( p_col == 8 ) {
            start_line = p_line; start_col = p_col;
            break;
         }
      }
   }

   // Scan downward to determine the end of the code block:
   bottom();
   int bottom_line = p_line; 
   int bottom_col = p_col;
   p_line = ori_line; p_col = ori_col;
   for(;;) {
      int last_line = p_line; 
      int last_col = p_col;
      if ( p_line < bottom_line ) {
         p_line = p_line + 1; p_col = 1;
      } else {
         p_line = last_line;
         end_line2();
         ending_line = last_line; ending_col = p_col;
         return( 0 );
      }
      if ( cs_skipSpaces() == -1 ) return( 1 );
      if ( p_col == 7 ) continue;
      if ( p_col == 8 ) {
         p_line = last_line;
         end_line2();
         ending_line = last_line; ending_col = p_col;
         //say("start start_line="start_line" start_col="start_col);
         //say("end ending_line="ending_line" ending_col="ending_col);
         return( 0 );
      }
   }
   return( 1 );
}


// Desc:  Cobol.  From the start of some code block, determine the end of that
//     code block.
// Retn:  0 for OK, 1 for not found.
int cs_cob_findBlockEnd( typeless &type, int &sbstart_line, int &sbstart_col )
{
   // Check to see if current line is the start of a code block:
   type = 'b';
   int ori_line = p_line; 
   int ori_col = p_col;

   // Determine the bottom of the file:
   bottom();
   int bottom_line = p_line; 
   p_line = ori_line;

   // Scan downward to determine the end of the code block:
   // The code block ends when the start of the new line is at the same
   // indentation level as the first line of the block.
   int start_found = 0;
   for(;;) {
      int last_line = p_line; 
      int last_col = p_col;
      if ( p_line < bottom_line ) {
         p_line = p_line + 1; p_col = 1;
      } else {
         // Code block ends as the last line in the file:
         end_line2();
         return( 0 );
      }
      if ( cs_skipSpaces() == -1 ) return( 1 );

      // Found the end of the code block:
      if ( p_col != 7 && p_col < ori_col ) {
         // Line's starting column is less than the block's, must have gone
         // beyond code block.
         p_line = last_line; p_col = last_col;
         end_line2();
         return( 0 );
      } else if ( p_col == ori_col ) {
         // If the keyword begins with 'END-', include this line in the block:
         //messageNwait( 'h1' );
         _str ch = get_text( 4 ); ch = lowcase( ch );
         if ( ch != 'end-' ) {
            p_line = last_line; p_col = last_col;
         }
         end_line2();
         return( 0 );
      }

      // Still inside subcode block:
      if ( !start_found ) {
         int temp_l = p_line; 
         int temp_c = p_col;
         p_line = last_line; end_line2();
         sbstart_line = p_line; sbstart_col = p_col + 1;
         p_line = temp_l; p_col = temp_c;
         start_found = 1;
      }
   }
   return( 1 );
}


// Desc:  Awk.  Determine the boundary of the code block.
// Retn:  block type for OK, '' for error.
typeless cs_cob_blockBoundary( int &start_line, int &start_col,
                               int &end_line,   int &end_col, 
                               int &sbstart_line, int &sbstart_col )
{
   // Init:
   start_line = p_line; start_col = p_col;
   //messageNwait( 'h1' );

   // Find the matching block end:
   sbstart_line = 0; sbstart_col = 0;
   typeless type = 0;
   if ( cs_cob_findBlockEnd( type, sbstart_line, sbstart_col ) ) {
      return( '' );
   }
   end_line = p_line; end_col = p_col;
   return( type );
}


// Desc:  Perl.  Use an alternate algorithm to determine the start and end
//     of the proc block.
// Retn:  0 for OK, 1 for error.
int cs_c_findProcBlockAlt( int &start_line, int &start_col,
                           int &end_line,   int &end_col )
{
   // Take a step back and look for the next '{'
   int ori_line = p_line; 
   int ori_column = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless status = cs_c_next_openCurly( 1 );

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( !status && p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         //messageNwait( 'h1' );
         if ( _find_matching_paren(def_pmatch_max_diff) ) return( 1 );
         //messageNwait( 'h2' );

         // Found proc:
         if ( ori_line <= p_line ) {
            if ( cs_isCurlyCodeBlock( start_line, start_col, p_line, p_col ) ) {
               //messageNwait( 'h3' );
               end_line = p_line; end_col = p_col;
               return( 0 );
            }
         }

         // Find next proc:
         status = cs_c_next_openCurly( 0 );
         //messageNwait( 'h4' );
         if ( ori_line < p_line ) return( 1 );
      }
      return( 1 );
   }
   return( 1 );
}


// Desc:  Given the positions of { and }, make a best guess at whether this
//     is a code block or just a special use like $var{$var} ...
// Retn:  1 for yes, 0 for not.
static int cs_isCurlyCodeBlock( int start_line, int start_col, 
                                int end_line,   int end_col )
{
   // If { and } are on different lines, probably not code block:
   if ( start_line != end_line ) return( 1 );

   // Scan from { to } for semicolon:
   // The presence of a semicolon indicates code ...
   int temp_l = p_line; 
   int temp_c = p_col;
   p_line = start_line; p_col = start_col + 1;
   //messageNwait( 'b1' );
   rc = cs_nextSemicolonOrCloseCurly();
   //messageNwait( 'b2 rc='rc );
   p_line = temp_l; p_col = temp_c;
   if ( rc == ';' ) return( 1 );
   return( 0 );
}


// Desc:  Go to next semicolon or }, whichever come first.
// Retn:  ';', '}', or '' for error.
static typeless cs_nextSemicolonOrCloseCurly()
{
   if ( cs_skipSpaces() == -1 ) return( '' );
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   for(;;) {
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text();
         continue;
      }
      if ( ch == '{' ) {
         typeless status = _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         ch = get_text();
         continue;
      }
      if ( ch == '}' ) return( '}' );
      else if ( ch == ';' ) return( ';' );

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         int status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpaces() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Fortran.  Determine the start and end of the proc block.
// Retn:  0 for OK, 1 for error.
int cs_for_findProcBlock( int &start_line, int &start_col,
                          int &end_line,   int &end_col )
{
   // Try to find the proc starting from cs_stepback_size characters backup:
   //
   // If the start of the true outer most proc is actually more than cs_stepback_size
   // characters up, this function will pick the wrong proc.  Too bad!
   // In any case, the function will pick the closest, highest scoped proc
   // that contains the caret.
   int ori_line = p_line; 
   int ori_col = p_col;
   typeless ori_seek_pos = _nrseek();
   typeless seek_pos = ori_seek_pos - cs_stepback_size;
   if ( seek_pos < 1 ) seek_pos = 0;
   _nrseek( seek_pos );
   typeless status = cs_for_next_proc( 1 );
   typeless type = 0;
   _str stopLabel = "";
   if ( status ) return( 1 );
   typeless sbstart_line=0, sbstart_col=0;

   // The proc is within cs_stepback_size characters from original caret position:
   // It also may not be in any proc...
   if ( p_line <= ori_line ) {
      while ( !status ) {
         start_line = p_line; start_col = p_col;
         stopLabel="";
         status = cs_for_findBlockEnd( 0, type, 0, sbstart_line,
                  sbstart_col, stopLabel );
         if ( status ) return( 1 );

         // Found proc:
         if ( ori_line <= p_line ) {
            cs_skipKeyword();
            end_line = p_line; end_col = p_col;
            return( 0 );
         }

         // Find next proc:
         status = cs_for_next_proc( 0 );
      }

      // Fall thru...  Try the entire file:
   }

   // The proc beginning is more than cs_stepback_size characters backup...
   // Go back all the way to the beginning of the file:
   top();
   status = cs_for_next_proc( 1 );

   // Normal processing to find the next proc that contains the caret:
   if ( p_line > ori_line ) return( 1 );
   while ( !status ) {
      start_line = p_line; start_col = p_col;
      status = cs_for_findBlockEnd( 0, type, 0, sbstart_line,
               sbstart_col, stopLabel );
      if ( status ) return( 1 );

      // Found proc:
      if ( ori_line <= p_line ) {
         cs_skipKeyword();
         end_line = p_line; end_col = p_col;
         return( 0 );
      }

      // Find next proc:
      status = cs_for_next_proc( 0 );
   }
   return( 1 );
}


// Desc:  Fortran.  From the block start keyword, find the matching block
//     ending keyword.
//
//     if ... then          ==> endif
//     do                   ==> end do
//     do <label>           ==> <label> continue
//
//     subroutine           ==> end
//     function             ==> end
//     program              ==> end
//
// Para:  type               Returned block type
//        stopAt             Mode:  1=ELSE, 2=label
//        stopLabel          Stop label
//
// Retn:  0 for found, 1 for not, 3 for stopped at ---.
static int cs_for_findBlockEnd( int level, typeless &type, int stopAt,
                                int &sbstart_line, int &sbstart_col, 
                                _str stopLabel )
{
   for(;;) {
      // Get next keyword:
      //messageNwait( 'b4 next key level='level );
      int status = _clex_find( KEYWORD_CLEXFLAG );
      //messageNwait( 'after next key' );
      if ( status ) return( 1 );
      _str ch = get_text( 2 ); ch = lowcase( ch );

      // Check for block end keyword, 'end'
      if ( ch == 'en' ) {
         //messageNwait( 'END level='level );
         if ( stopAt ) return( 3 );
         return( 0 );
      }

      // Skip over the block associated with this keyword:
      typeless rtype = 0;
      if ( ch == 'if' ) {                     // if
         int tl = p_line; 
         int tc = p_col;
         //messageNwait( 'IF level='level );
         rc = cs_for_nextThen();
         //messageNwait( 'after looking for THEN level='level' rc='rc );
         if ( rc == '' ) return( 1 );
         if ( rc == 'n' ) {
            if ( stopAt ) return( 0 );
            continue;
         }
         sbstart_line = p_line; sbstart_col = p_col;
         status = cs_for_nextBlockEnd( level, rtype, 0, sbstart_line,
                  sbstart_col, stopLabel );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'if';
         return( 0 );
      } else if ( ch == 'el' ) {                     // else
         //messageNwait( 'ELSE level='level' stopAt='stopAt );
         if ( stopAt ) return( 3 );
         int tl = p_line; 
         int tc = p_col;
         sbstart_line = p_line; sbstart_col = p_col;
         cs_skipToEOLN();         // Skip over the IF ...THEN part
         status = cs_for_nextBlockEnd( level, rtype, 1, sbstart_line,
                  sbstart_col, stopLabel );
         //messageNwait( 'back from ELSE block' );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'else';
         return( 0 );
      } else if ( ch == 'do' ) {                 // do
         cs_skipKeyword();
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( 1 );
         ch = get_text(); ch = lowcase( ch );
         if ( ch == 'w' || ch == "\n" || ch == "\r") { // do while  ==> end do
            cs_skipToEOLN();
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_for_nextBlockEnd( level, rtype, 0, sbstart_line,
                     sbstart_col, stopLabel );
            //messageNwait( 'back from DO block level='level );
         } else if ( ch >= '0' && ch <= '9' ) {        // do <label>
            _str label = cs_for_getLabel();
            //say( 'label='label );
            cs_skipToEOLN();
            sbstart_line = p_line; sbstart_col = p_col;
            status = cs_for_nextBlockEnd( level, rtype, 2,
                     sbstart_line, sbstart_col, label );
            //messageNwait( 'back from DO label block level='level );
         }
         type = 'do';
         if ( !level ) return( 0 );
         cs_skipToEOLN();
         continue;
      } else if ( ch == 'su' ) {              // subroutine
         // Skip to the beginning of the next line (which I assume is the
         // start of the sub block).
         cs_skipToEOLN();
         cs_for_skipOverContinuation();
         sbstart_line = p_line; sbstart_col = p_col;

         // Find matching 'end'
         //messageNwait( 'function h2' );
         status = cs_for_nextBlockEnd( level, rtype, 0, sbstart_line,
                  sbstart_col, stopLabel );
         //messageNwait( 'back from SUBROUTINE status='status' level='level );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'subroutine';
         return( 0 );
      } else if ( ch == 'fu' ) {              // function
         cs_skipToEOLN();
         cs_for_skipOverContinuation();
         sbstart_line = p_line; sbstart_col = p_col;

         // Find matching 'end'
         //messageNwait( 'function h2' );
         status = cs_for_nextBlockEnd( level, rtype, 0, sbstart_line,
                  sbstart_col, stopLabel );
         //messageNwait( 'function h3 status='status' level='level );
         if ( status == 1 ) return( 1 );
         if ( status == 2 ) continue;
         type = 'function';
         return( 0 );
      } else if ( ch == 'pr' ) {              // program
         ch = get_text( 4 ); ch = lowcase( ch );
         if ( ch == 'prog' ) {
            cs_skipToEOLN();
            cs_for_skipOverContinuation();
            sbstart_line = p_line; sbstart_col = p_col;

            // Find matching 'end'
            //messageNwait( 'function h2' );
            status = cs_for_nextBlockEnd( level, rtype, 0, sbstart_line,
                     sbstart_col, stopLabel );
            //messageNwait( 'function h3 status='status' level='level );
            if ( status == 1 ) return( 1 );
            if ( status == 2 ) continue;
            type = 'program';
            return( 0 );
         }
      } else if ( ch == 'co' ) {              // continue
         ch = get_text( 3 ); ch = lowcase( ch );
         if ( ch == 'con' ) {
            //messageNwait( 'hit CONTINUE' );
            int temp_line = p_line; 
            int temp_col = p_col;
            p_col = 1;
            _str label = cs_for_getLabel();
            p_line = temp_line; p_col = temp_col;
            if ( label == stopLabel ) {
               //messageNwait( 'CONTINUE LABEL level='level );
               type = 'continue';
               return( 3 );
            }
         }
      }

      // Skip over this keyword:
      //messageNwait( 'skip over unused keyword' );
      //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
      cs_skipKeyword();
   }
}


// Desc:  Fortran.  Recurse and find end of new block.
// Retn:  0 for found but stop, 1 for error, 2 for found and continue
static int cs_for_nextBlockEnd( int level, typeless &type, int stopAt,
                                int sbstart_line, int sbstart_col, 
                                _str stopLabel )
{
   //messageNwait( 'hh1' );
   //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
   //cs_skipKeyword();
   //messageNwait( 'hh2' );
   typeless rtype = 0;
   rc = cs_for_findBlockEnd( level + 1, rtype, stopAt, sbstart_line,
            sbstart_col, stopLabel );
   //messageNwait( 'hh3 rc='rc );
   if ( rc == 1 ) return( 1 );
   if ( rc == 3 ) return( 2 );
   if ( level ) {
      // Skip to the end-of-line:
      cs_skipToEOLN();
      return( 2 );
   }
   return( 0 );
}


// Desc:  Fortran.  Find the next 'then' or EOLN.
// Retn:  'then', 'n', or '' for error.
static typeless cs_for_nextThen()
{
   int ori_line = p_line; 
   int ori_col = p_col;
   if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
   typeless seek_pos = _nrseek();
   _str ch = get_text(); ch = lowcase( ch );
   for(;;) {
      //messageNwait( 'ch='ch );
      if ( ch == '(' ) {
         _find_matching_paren(def_pmatch_max_diff);
         seek_pos = _nrseek() + 1;
         if ( _nrseek( seek_pos ) == '' ) return( '' );
         cs_skipSpacesUntilEOLN();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }
      if ( ch == 't' ) {               // then
         ch = get_text( 2 ); ch = lowcase( ch );
         if ( ch == 'th' ) {
            int type = _clex_find( KEYWORD_CLEXFLAG, 'G' );
            if ( type == CFG_KEYWORD ) return( 'then' );
         }
      }
      if ( ch == "\n" || ch == "\r" ) {
         return( 'n' );
      }

      // Skip over comment and string:
      int type = _clex_find( COMMENT_CLEXFLAG, 'G' );
      if ( type == CFG_COMMENT || type == CFG_STRING ) {
         int status = _clex_find( COMMENT_CLEXFLAG | STRING_CLEXFLAG, 'N' );
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // Skip over unwanted keywords:
      if ( type == CFG_KEYWORD ) {
         //status = _clex_find( KEYWORD_CLEXFLAG, 'N' );
         cs_skipKeyword();
         if ( cs_skipSpacesUntilEOLN() == -1 ) return( '' );
         seek_pos = _nrseek();
         ch = get_text(); ch = lowcase( ch );
         continue;
      }

      // No comment or string, advance to next character:
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return( '' );
      ch = get_text(); ch = lowcase( ch );
   }
   return( '' );
}


// Desc:  Skip until the end-of-line.
static void cs_skipToEOLN()
{
   typeless seek_pos = _nrseek();
   _str ch = get_text();
   while ( ch != "\n" && ch != "\r" ) {
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) return;
      ch = get_text();
   }
}


// Desc:  Fortran.  Get the next string as a statement label.
static typeless cs_for_getLabel()
{
   typeless seek_pos = _nrseek();
   typeless ori_seekpos = seek_pos;
   _str ch = get_text(); ch = lowcase( ch );
   while ( ch >= '0' && ch <= '9' ) {
      seek_pos = seek_pos + 1;
      if ( _nrseek( seek_pos ) == '' ) break;
      ch = get_text();
   }
   int len = seek_pos - ori_seekpos;
   ch = get_text( len, ori_seekpos ); ch = lowcase( ch );
   return( ch );
}


// Desc:  Fortran.  Skip over continuation lines.
static void cs_for_skipOverContinuation()
{
   // Check the next line to see if it continues current line:
   int temp_l = p_line; 
   int temp_c = p_col;
   bottom(); 
   int bottom_line = p_line;
   p_line = temp_l; p_col = temp_c;
   if ( temp_l == bottom_line ) return;
   p_line = temp_l + 1; p_col = 1;
   if ( cs_skipSpacesUntilEOLN() == -1 ) return;
   if ( p_col != 6 ) {
      // Restore original position:
      p_line = temp_l; p_col = temp_c;
      return;
   }

   // Skip over the continuation lines:
   while ( p_col == 6 ) {
      temp_l = p_line;
      if ( temp_l == bottom_line ) return;
      p_line = temp_l + 1; p_col = 1;
      if ( cs_skipSpacesUntilEOLN() == -1 ) return;
   }
}


// Desc:  Fortran.  Go to the next proc.
// Para:  no_skip            Flag: 1=if already on proc, do nothing (don't skip)
// Retn:  0 for OK, 1 for error.
static int cs_for_next_proc( boolean no_skip )
{
   if ( !no_skip ) return( next_proc(1) );
   int ori_l = p_line; 
   int ori_c = p_col;
   if ( next_proc(1) ) return( 1 );
   if ( prev_proc(1) ) return( 1 );
   if ( p_line == ori_l ) return( 0 );
   return( next_proc(1) );
}


// Desc:  Build call index proc list
// Retn:  0 for OK, 1 for error.
static int cs_buildCallIndexProcList()
{
   // Determine which language:
   _str real_extension="";
   _str lang = cs_getExtension( real_extension );

   // Special case for HTML:
   if (lang == "html" || lang == "htm") {
      cs_LangId = "html";
      return(0);
   }

   // and for xml
   if (_LanguageInheritsFrom("xml", lang)) {
      cs_LangId = "xml";
      return(0);
   }

   cs_LangId = lang;

   // Init the call index for specific extension:
   cs_nextBlockToken_ci = _FindLanguageCallbackIndex( 'cs_%s_nextBlockToken',lang );
   if ( !cs_nextBlockToken_ci ) return( 1 );

   cs_blockBoundary_ci = _FindLanguageCallbackIndex( 'cs_%s_blockBoundary',lang );
   if ( !cs_blockBoundary_ci ) return( 1 );

   cs_skipOverBlockStartToken_ci = _FindLanguageCallbackIndex( 'cs_%s_skipOverBlockStartToken',lang );
   if ( !cs_skipOverBlockStartToken_ci ) return( 1 );

   cs_skipOverBlockEndToken_ci = _FindLanguageCallbackIndex( 'cs_%s_skipOverBlockEndToken',lang );
   if ( !cs_skipOverBlockEndToken_ci ) return( 1 );

   // Special cases here...
   if ( real_extension == 'java' || real_extension == 'jav' || real_extension == 'cs' ) {
      cs_findProcBlock_ci = find_index( 'cs_java_findProcBlock', PROC_TYPE );
   } else {
      cs_findProcBlock_ci = _FindLanguageCallbackIndex( 'cs_%s_findProcBlock',lang );
   }
   if ( !cs_findProcBlock_ci ) return( 1 );
   if ( !index_callable( cs_findProcBlock_ci ) ) return( 1 );

   cs_procBlockBoundary_ci = _FindLanguageCallbackIndex( 'cs_%s_procBlockBoundary',lang );
   if ( !cs_procBlockBoundary_ci ) return( 1 );

   int index=find_index("def_cs_stepback_size_"lang,VAR_TYPE);
   if (index) {
      cs_stepback_size= _get_var(index);
   } else {
      cs_stepback_size = 5000;
   }
   return( 0 );
}

// Desc: Check to see if select code block is supported for current buffer.
//       Extensions supported: c, e, java, javascript, pl,
//                             cob, ada, for, pas, awk,
//                             mod, html, plsql, php
boolean _isSelectCodeBlock_supported()
{
   if (cs_buildCallIndexProcList()) {
      return(false);
   }
   return(true);
}


//------------------------------------------------------------------------
// Outline Code.

// Desc:  Get the extension of the current buffer.
// Para:  real_extension     Real extension
// Retn:  Extension.
static _str oc_getExtension(_str &real_extension)
{
   // We need to use the mode name in order to
   // handle embedded languages.
   _str lang = p_LangId;
   real_extension = lang;

   // Slick-C, java are treated the same as C:
   if (lang == 'e') {
      lang = 'c';
   } else if (lang == 'java' || lang == 'jav' || lang == 'cs' ) {
      lang = 'java';
   }
   return(lang);
}

// Desc: Set the call indexes required for outline code.
// Retn: 0 OK, 1 extension not supported
int ocBuildCallIndex()
{
   // Determine which language:
   _str ext, real_extension;
   ext = oc_getExtension(real_extension);

   // A supported languange must have a few required function indexes.
   oc_nextBlock_ci = _FindLanguageCallbackIndex('oc_%s_nextBlock',ext );
   if (!oc_nextBlock_ci) return(1);

   return(0);
}

// Desc: Check to see if outline code is supported for the buffer extension.
// Retn: true supported, false no
boolean isOutlineCode_supported()
{
   if (ocBuildCallIndex()) {
      return(false);
   }
   return(true);
}

int _OnUpdate_outline_code(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid.isOutlineCode_supported() && !target_wid._istagging_supported()) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);

}
// Desc: Go through the buffer and create an outline by collapsing the body
//       of top-level code blocks.
// Retn: 0 OK, 1 error.
_command int outline_code(_str seldisp_flags="", typeless appendTrailingBlankLines="")  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Check to see if outline code is supported for this extension.
   if (!isOutlineCode_supported()) {
      if (_istagging_supported()) {
         return(show_procs(seldisp_flags));
      }
      message("Outline code does not support files of this type." );
      return(1);
   }

   // Get the arguments:
   int collapseComment = 0;

#if 0
   if (seldisp_flags=="") {
      seldisp_flags=def_seldisp_flags;
   }
   if( seldisp_flags& SELDISP_COLLAPSEPROCCOMMENTS) {
      collapseComment=1;
   }
   //SELDISP_COLLAPSEPROCCOMMENTS|SELDISP_SHOWPROCCOMMENTS
#endif

   if (seldisp_flags != "") {
      collapseComment = (int)seldisp_flags;
   }
   if (appendTrailingBlankLines == "") {
      appendTrailingBlankLines = 1;
   }

   // Remember the position:
   typeless origPosition;
   save_pos(origPosition);
   int old_def_pmatch_max_diff=def_pmatch_max_diff;
   def_pmatch_max_diff=1000000;

   // Start from the beginning of the file.
   int status;
   _nrseek(0);
   search("[!-~]", "r@iH");

   // This is a final resort (ie. a hack) to collapse the first
   // junk block followed by a structured block.
   gocFirstStructuredSpecial = 1;

   // Go thru the entire file.
   while (1) {
      // Locate next code block. Get the start and end of code block.
      // Also get the start of code body.
      int sl, sc, el, ec;
      int bodysl, bodysc;
      _str blockType;
      blockType = "";
      //messageNwait("outline_code h1");
      status = ocNextBlock(sl, sc, el, ec, bodysl, bodysc, blockType
                           ,collapseComment           // collapse comment
                           ,appendTrailingBlankLines  // append trailing blank lines
                           );
      if (status && status != 2) break;
      //messageNwait("outline_code h2 status="status);
      //messageNwait("outline_code "sl" "sc" "el" "ec"  "bodysl" "bodysc" "blockType);
      //message("outline_code "sl" "sc" "el" "ec"  "bodysl" "bodysc" "blockType);

      // Hide the code block.
      ocHideBlock(sl, sc, el, ec, bodysl, bodysc, blockType);
      if (status == 2) break;

      // Once a block has been established, disable this special case.
      gocFirstStructuredSpecial = 0;
   }

   // Restore original position.
   def_pmatch_max_diff=old_def_pmatch_max_diff;
   restore_pos(origPosition);
   return(0);
}

// Desc: Hide the body of the specified code block.
static void ocHideBlock(int sl, int sc, int el, int ec, int bodysl, int bodysc
                        ,_str blockType)
{
   // Block must span more than one line.
   if (sl == el) return;

   // Remember the position.
   int seekPos;
   seekPos = _nrseek();

   // Select the block body.
   deselect();
   _str persistent = (def_persistent_select=='Y')?'P':'';
   _str mstyle = 'EN'persistent;

   // Select the block:
   if (substr(blockType,1,1) == "s") {
      // If the block body start line is the same as the block start line,
      // select the line right after the start line.
      if (sl == bodysl) {
         p_line = bodysl + 1; p_col = 1;
      } else {
         p_line = bodysl; p_col = 1;
      }
   } else if (blockType == "c" || blockType == "n") {
      p_line = bodysl + 1; p_col = 1;
   } else {
      p_line = bodysl; p_col = 1;
   }
   _select_line('',mstyle);
   p_line = el; p_col = ec;
   _select_line('',mstyle);

   // Hide the selection.
   hide_selection();

   // Restore orig position.
   _nrseek(seekPos);
}

// Desc: Locate the next code block.
// Retn: 0 OK, 1 error, 2 EOF
static int ocNextBlock(int & sl, int & sc, int & el, int & ec
                       ,int & bodysl, int & bodysc
                       ,_str & blockType
                       ,int collapseComment
                       ,int appendTrailingBlankLines
                       )
{
   int status;
   status = call_index(sl, sc, el, ec, bodysl, bodysc, blockType
                       ,collapseComment
                       ,appendTrailingBlankLines
                       ,oc_nextBlock_ci);
   return(status);
}

// Desc: If the current line is a blank line, skip over all consecutive
//       blank lines.
// Retn: 0 OK, 1 error, 2 EOF
static int oc_c_skipBlankLines()
{
   int status;
   int seekpos;
   int cLine;
   _str line;

   p_col = 1;
   while (1) {
      get_line(line);
      if (!pos("^[ \t]*$", line, 1, "r")) {
         if (p_line == p_Noflines) {
            return(2);
         }
         return(0);
      }
      p_line = p_line + 1;
   }
   return(0);
}

// Desc: Append any trailing blank lines to the current code block.
//       The text caret must be on a blank line.
static void oc_c_appendTrailingBlankLines(int & el, int & ec)
{
   // If there are blank line immediately following the block, skip over the
   // blank lines.
   int cLine;
   cLine = p_line;
   oc_c_skipBlankLines();
   if (p_line != cLine) {
      p_line = p_line - 1;
      p_col = 1;
      el = p_line;
      ec = 1;
   }
}

// Desc: Backward scan for #if with optional blank lines between
//       the #if and the current line.
// Retn: 0 found #if, 1 not
static int oc_c_backScanForPoundIf()
{
   int seek1;
   seek1 = _nrseek();

   _str line;
   while (1) {
      if (p_line == 1) {
         _nrseek(seek1);
         return(1);
      }
      p_line = p_line - 1;
      get_line(line);
      if (!pos("^[ \t]*$", line, 1, "r")) { // not blank
         if (substr(line,1,3) == "#if") {
            return(0);
         }
         _nrseek(seek1);
         return(1);
      }

      // Found blank line... Skip over it and check
      // the line before it.
   }
   return(1);
}

// Desc: Backward scan for specified word.
// Retn: 1 found, 0 not found
static int oc_c_backScanForWord(_str word, int lineCount)
{
   int seek1;
   _str line;
   seek1 = _nrseek();
   while (lineCount) {
      get_line(line);
      if (pos(word,line,1,"r")) {
         _nrseek(seek1);
         return(1);
      }
      if (p_line == 1) {
         _nrseek(seek1);
         return(0);
      }
      p_line = p_line - 1;
      lineCount--;
   }
   _nrseek(seek1);
   return(0);
}

// Desc: Go backward and estimate the end of the junk block.
//       Use the current structured block as the starting point.
// Retn: 1 found end, 0 no end
static int oc_c_estimateStartJunkBlock(int lineCount)
{
   _str line;
   _str rc1,rc2,rc3,rce;
   rc1 = '(^[ \t]*\#)';
   rc2 = '(^[ \t]*$)';
   rc3 = '(^?*;[ \t]*$)';
   rce = rc1'|'rc2'|'rc3;
   while (lineCount) {
      get_line(line);
      if (pos(rce,line,1,"r")) {
         return(1);
      }
      if (p_line == 1) {
         return(0);
      }
      p_line = p_line - 1;
      lineCount--;
   }
   return(0);
}

// Desc: Find the next code block.
// Retn: 0 OK, 1 error, 2 EOF (ie. block not found)
int oc_c_nextBlock(int & sl           // block start line and column
                   ,int & startCol
                   ,int & el          // block end line and column
                   ,int & ec
                   ,int & bodysl      // block body start line and column
                   ,int & bodysc
                   ,_str & blockType  // block type: c=comment,s=structured,n=normal
                   ,int collapseComment
                   ,int appendTrailingBlankLines
                   )
{
   _str line;
   int seek1;

   // Internals:
   _str oparen = '\(';

   // Skip over the blank lines.
   // Only do this if the current line is a blank line.
   int status;
   //messageNwait("oc_c_nextBlock hh0");
   oc_c_skipBlankLines();

   // Mark the real start of the block.
   int realStartLine;
   int realStartCol;
   realStartLine = p_line;
   realStartCol = p_col;

   // Determine the start of the block. If the start is a comment block
   // and we don't collapse comment block, the block is skipped over.
   int hasBlock = 0;
   int continueBlock = 0;
   _str ch;
   while (1) {
      // Default the start or continue the last block.
      if (!continueBlock) {
         blockType = "s";
         sl = p_line;
         startCol = p_col;
         bodysl = p_line;
         bodysc = p_col;
      }
      continueBlock = 0;

      // Search for { ( or ; or line begins with comment:
      _str re1,re2,re3,re4,re5,re6,ree;
      //messageNwait("oc_c_nextBlock search h1");
      /*
      re1 = '(^\c[ \t]*(//|/\*))'; // comment lines
      re2 = '(^?*\c(class|struct|enum)(?|\n)*\{)'; // class,struct,enum header
      re3 = '\c;';
      re4 = '\c\{';
      re5 = '(^?*'oparen'([^;]|\n)*\c\{)'; // function header
      ree = re1'|'re2'|'re3'|'re4'|'re5;
      */
      ree = "(^[ \t]*(//|/\\*))|(;|\\{|\\()";
      status = search(ree, "r@iHXS");
      //messageNwait("oc_c_nextBlock search h2");
      if (status) {
         // Hit EOF. Consider here to the end of the file a code block.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      ch = get_text(1);

      // Found a "(". Match paren to skip over it.
      // This helps the jump over the multi-line function header,
      // especially when it has embedded comment on lines by
      // themselves.
      while (ch == "(") {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         get_line(line);
         if (pos(";",line,p_col)) {
            //status = search('(^[ \t]*(//|/\*))|(;|\{|\()',"r@iHXS");
            status = search(ree, "r@iHXS");
         } else {
            status = search(";|\\{|\\(", "r@iHXCS");
         }
         if (status) {
            // Hit EOF. Consider here to the end of the file a code block.
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         ch = get_text(1);
      }

      // Found class/struct/enum header.
      if (ch == "c" || ch == "s" || ch == "e") {
         // If this structured block has been preceeded by a junk block,
         // this indicates the end of the junk block.
         if (p_line > (realStartLine + 1)) {
            el = p_line - 1;
            ec = p_col;
            p_col = 1;
            return(0);
         }

         // Move the start of body block... and falls thru.
         search('\{', "r@iHXCS");
         ch = "{";
      }

      // Found a structured block. A structured block is one enclosed by {}.
      _str rc1,rc2,rc3,rce;
      if (ch == "{") {
         // If structured block is preceeded by extern "C" {,
         // preserve the extern "C".
         seek1 = _nrseek();
         if (oc_c_backScanForWord('extern[ \t]*"C"[ \t]*\{', 2)) {
            // Found the extern "C" {.  Skip over it!
            blockType = "n";
            _nrseek(seek1 + 1);
            continueBlock = 1;
            continue;
         }

         /*
         // If structured block is preceeded by a junk block and junk block is
         // separated from structured block by blank lines, end the
         // junk block.
         seek1 = _nrseek();
         if (p_line > (sl + 1)) {
            p_line = p_line - 1;
            get_line(line);
            rc1 = '(^[ \t]*\#)';
            rc2 = '(^[ \t]*$)';
            rc3 = '(^?*;[ \t]*$)';
            rce = rc1'|'rc2;
            if (pos(rce, line, 1, "r")) { // blank line separation
               blockType = "n";
               el = p_line;
               ec = p_col;
               _nrseek(seek1);
               p_col = 1;
               return(0);
            }
            _nrseek(seek1);
         }
         */
         // Estimate the end of the junk block. Use the start of the
         // structured block as the starting point.
         if (gocFirstStructuredSpecial && p_line > (sl + 1)) {
            gocFirstStructuredSpecial = 0;
            if (oc_c_estimateStartJunkBlock(20)) {
               blockType = "n";
               el = p_line;
               ec = p_col;
               p_line = p_line + 1;
               p_col = 1;
               return(0);
            }
            _nrseek(seek1);
         }
         break;
      }

      // Found a the start of a block but the start is
      // not the same as the line we started out with. Must have
      // skipped over a chunk of non-structed code.
      // If so, select that block as a valid code block.
      if (ch != ";" && p_line > (realStartLine + 1) && !collapseComment) {
         //messageNwait("oc_c_nextBlock junkBLock");
         blockType = "n";
         el = p_line - 1;
         ec = p_col;
         return(0);
      }

      // If found the start of a comment block and we don't need to collapse
      // comment, skip over the comment block.
      if (ch != ";" && !collapseComment) {
         //messageNwait("oc_c_nextBlock skip over comment h1 ch=<"ch">");
         if (ch == " ") search("[^ \t]", "r@iHXS");  // skip over leading spaces
         status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+", "r@iHXC");
         //messageNwait("oc_c_nextBlock skip over comment h2 status="status);
         if (status) return(2);
         continue;
      }

      // If we have already jumped over a block of junk code
      // and reached the start of a comment block and we do
      // need to collapse the comment, merge this comment block
      // to the preceeding block.
      if (ch != ";" && p_line > (realStartLine + 1) && collapseComment) {
         status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+","r@iHXCS");
         if (status) {
            // Hit EOF. Consider here to the end of the file a code block.
            bottom();
            blockType = "n";
            el = p_line;
            ec = p_col;
            return(2);
         }
         blockType = "n";
         continueBlock = 1;
         hasBlock = 1;
         continue;
      }

      // Found the start of a block...
      //messageNwait("oc_c_nextBlock foundstartblock ch="ch);
      break;
   }

   // Found a structured block. A structured block is one enclosed by {}.
   _str matchCh;
   if (ch == "{") {
      // If a block is already established, this { indicates
      // the begin of a structured block which is the end of the
      // established block.
      if (hasBlock) {
         // Search backward for the the start of this structured
         // code block. This could be a function header, class, struct,
         // enum.
         status = search("([A-Za-z0-9_]+[ \t]*\\()|((struct|class|enum)?+\\{)", "-r@iHXCS");
         el = p_line - 1;
         ec = 1;
         p_col = 1;
         return(0);
      }

      // Check to see if the header of this structured block is
      // on the same line as the {. If on the same line, start the
      // block body on the next line.
      blockType = "s";
      get_line(line);
      if (pos("([A-Za-z_0-9 ]+[ \t]*\\()|(struct)|(enum)", line, 1, "r")) {
         bodysl = p_line + 1;
         bodysc = 1;
      } else {
         bodysl = p_line;
         bodysc = 1;
      }

      // Match the brace to determine the end of the structured block.
      //messageNwait("oc_c_nextBlock structured block h1");
      status = _find_matching_paren(def_pmatch_max_diff);
      //messageNwait("oc_c_nextBlock structured block h2");
      if (status) return(1);
      el = p_line;
      ec = p_col;
      if (el < sl) sl = el;

      // Skip to next line.
      _nrseek(_nrseek() + 1);
      status = search("^", "r@iH");

      // If there are blank line immediately following the block, skip over the
      // blank lines.
      if (appendTrailingBlankLines) {
         oc_c_appendTrailingBlankLines(el, ec);
      }
      return(0);
   }

   // Found the start of a comment block or a normal code block.
   matchCh = ch;
   if (matchCh == ";") {
      blockType = "n"; // normal block
   } else {
      blockType = "c"; // comment block
   }
   el = p_line;
   ec = p_col;

   // Process this comment block. By this time, we already detected that
   // we need to collapse comment. We need to determine the end of the
   // comment block, and possibly, the following normal code block.
   if (blockType == "c") {
      sl = p_line;
      startCol = p_col;
      bodysl = p_line;
      bodysc = p_col;
      //messageNwait("oc_c_nextBlock commentblock h0");
      if (matchCh == " ") search("[^ \t]", "r@iHXS");  // skip over leading spaces
      //messageNwait("oc_c_nextBlock commentblock h1");
      status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+", "r@iHXC");
      //messageNwait("oc_c_nextBlock commentblock h2");
      if (status) {
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      if (collapseComment) {
         el = p_line - 1;
         ec = p_col;
         if (appendTrailingBlankLines) {
            oc_c_appendTrailingBlankLines(el, ec);
         }
         return(0);
      }

      /*
      el = p_line - 1;
      ec = p_col;
      if (appendTrailingBlankLines) {
         oc_c_appendTrailingBlankLines(el, ec);
      }
      return(0);
      */

      // Fall thru to merge the following normal block to
      // this comment block.
   }

   // Process normal block.
   _str gp1, gp2, gp3, gp4;
   seek1 = _nrseek();
   _nrseek(seek1 + 1);
   while (1) {
      // Search for the following items:
      //    ;                     ==> statement termination
      //    = {                   ==> static array initializer
      //    struct/class/enum {   ==> struct definition
      //    func()                ==> function
      oparen='\(';
      //messageNwait("oc_c_nextBlock normalblock h2");
      //status = search('\c;|(^?*\c=?*\{)|(^?*(struct|class|enum)?+\c\{)|(^[ \t]*(([A-Za-z0-9_ ]+[ \t]*\c'oparen')|//|/\*))',"r@iHXS");
      gp1 = '(^?*\c=?*\{)';
      gp2 = '\c;';
      gp3 = '(^?*(struct|class|enum)?+\c\{)';
      gp4 = '(^[ \t]*(([A-Za-z0-9_:.* ]+[ \t]*\c'oparen')|//|/\*))';
      status = search(gp1'|'gp2'|'gp3'|'gp4,"r@iHXS");
      //messageNwait("oc_c_nextBlock normalblock h3 status="status);
      if (status) {
         // Reached EOF. Current block extends to EOF.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      ch = get_text(1);
      if (ch == "{") { // already inside another block...
         // Search backward for the the start of this structured
         // code block. This could be a function header, class, struct,
         // enum.
         status = search("([A-Za-z0-9_]+[ \t]*\\()|((struct|class|enum)?+\\{)", "-r@iHXCS");
         el = p_line - 1;
         ec = 1;
         p_col = 1;

         // Scan backward for #if (with optional blank lines between
         // #if and the block header). If found, end the normal block
         // right before the #if.
         if (!oc_c_backScanForPoundIf()) {
            if (bodysl < p_line) {
               el = p_line - 1;
               ec = 1;
            }
            return(0);
         }
         break;
      } else if (ch == "=") {
         el = p_line - 1;
         ec = 1;
         p_col = 1;
         return(0);
      }

      // If still in the same block type, expand the block and search again.
      if (ch == matchCh) {
         el = p_line;
         ec = p_col;
         seek1 = _nrseek();
         _nrseek(seek1 + 1);
         continue;
      }

      // Found possible function header.
      if (ch == "(") {
         seek1 = _nrseek();
         //messageNwait("oc_c_nextBlock found functinoheader");
         status = search(";|\\{", "r@iHXCS");
         if (status) {
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         ch = get_text(1);
         if (ch == ";") {
            el = p_line;
            ec = p_col;
            seek1 = _nrseek();
            _nrseek(seek1 + 1);
            continue;
         }
         _nrseek(seek1);
         p_col = 1;
         el = p_line - 1;
         ec = 1;

         // Scan backward for #if (with optional blank lines between
         // #if and the block header). If found, end the normal block
         // right before the #if.
         if (!oc_c_backScanForPoundIf()) {
            if (bodysl < p_line) {
               el = p_line - 1;
               ec = 1;
            }
            return(0);
         }
         break;
      }

      // Found start of a comment block.
      // Comment block follows normal block but we don't need to
      // collapse comment. Mark end normal block.
      if (!collapseComment) {
         p_col = 1;
         el = p_line - 1;
         ec = 1;
         return(0);
      }

      // If we need to collapse comment block, merge the comment
      // block to the existing normal block.
      // Skip over comment block.
      status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+","r@iHXCS");
      if (status) {
         // Hit EOF. Consider here to the end of the file a code block.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
   }

   // If there are blank line immediately following the block, skip over the
   // blank lines.
   if (appendTrailingBlankLines) {
      oc_c_appendTrailingBlankLines(el, ec);
   }
   return(0);
}

// Desc: Find the next code block.
// Retn: 0 OK, 1 error, 2 EOF (ie. block not found)
int oc_java_nextBlock(int & sl           // block start line and column
                      ,int & startCol
                      ,int & el          // block end line and column
                      ,int & ec
                      ,int & bodysl      // block body start line and column
                      ,int & bodysc
                      ,_str & blockType  // block type: c=comment,s=structured,n=normal
                      ,int collapseComment
                      ,int appendTrailingBlankLines
                      )
{
   _str line;
   int seek1;
   _str oparen, cparen;

   // Internals:
   oparen = '\(';
   cparen = '\)';

   // Skip over the blank lines.
   // Only do this if the current line is a blank line.
   int status;
   //messageNwait("oc_c_nextBlock hh0");
   oc_c_skipBlankLines();

   // Mark the real start of the block.
   int realStartLine;
   int realStartCol;
   realStartLine = p_line;
   realStartCol = p_col;

   // Determine the start of the block. If the start is a comment block
   // and we don't collapse comment block, the block is skipped over.
   int hasBlock = 0;
   int continueBlock = 0;
   _str ch;
   while (1) {
      // Default the start or continue the last block.
      if (!continueBlock) {
         blockType = "s";
         sl = p_line;
         startCol = p_col;
         bodysl = p_line;
         bodysc = p_col;
      }
      continueBlock = 0;

      // Search for { ( or ; or line begins with comment:
      _str re1,re2,re3,re4,re5,re6,ree;
      //messageNwait("oc_c_nextBlock search h1");
      re1 = '(^\c[ \t]*(//|/\*))'; // comment lines
      re2 = '(^?*\cclass(?|\n)*\{)'; // class header
      re3 = '\c;';
      re4 = '\c\{';
      re5 = '(^?*'oparen'([^;]|\n)*\c\{)'; // function header
      ree = re1'|'re2'|'re3'|'re4'|'re5;
      status = search(ree, "r@iHXS");
      //messageNwait("oc_c_nextBlock search h2");
      if (status) {
         // Hit EOF. Consider here to the end of the file a code block.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      ch = get_text(1);

      // Found a "(". Match paren to skip over it.
      // This helps the jump over the multi-line function header,
      // especially when it has embedded comment on lines by
      // themselves.
      while (ch == "(") {
         status = _find_matching_paren(def_pmatch_max_diff);
         if (status) return(1);
         get_line(line);
         if (pos(";",line,p_col)) {
            status = search('(^[ \t]*(//|/\*))|(;|\{|\()',"r@iHXS");
         } else {
            status = search(";|\\{|\\(", "r@iHXCS");
         }
         if (status) {
            // Hit EOF. Consider here to the end of the file a code block.
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         ch = get_text(1);
      }

      // Found a class header.
      // Locate and skip over the { and go to the next line.
      if (ch == "c") {
         status = search('\{', "r@iHXCS");
         if (status) {
            // Hit EOF. Consider here to the end of the file a code block.
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         _nrseek(_nrseek() + 1);
         continue;
      }

      // Found a structured block. A structured block is one enclosed by {}.
      if (ch == "{") {
         break;
      }

      // Found a the start of a block but the start is
      // not the same as the line we started out with. Must have
      // skipped over a chunk of non-structed code.
      // If so, select that block as a valid code block.
      if (ch != ";" && p_line > (realStartLine + 1) && !collapseComment) {
         //messageNwait("oc_c_nextBlock junkBLock");
         el = p_line - 1;
         ec = p_col;
         return(0);
      }

      // If found the start of a comment block and we don't need to collapse
      // comment, skip over the comment block.
      if (ch != ";" && !collapseComment) {
         //messageNwait("oc_c_nextBlock skip over comment h1 ch=<"ch">");
         if (ch == " ") search("[^ \t]", "r@iHXS");  // skip over leading spaces
         status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+", "r@iHXC");
         //messageNwait("oc_c_nextBlock skip over comment h2 status="status);
         if (status) return(2);
         continue;
      }

      // If we have already jumped over a block of junk code
      // and reached the start of a comment block and we do
      // need to collapse the comment, merge this comment block
      // to the preceeding block.
      if (ch != ";" && p_line > (realStartLine + 1) && collapseComment) {
         status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+","r@iHXCS");
         if (status) {
            // Hit EOF. Consider here to the end of the file a code block.
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         continueBlock = 1;
         hasBlock = 1;
         continue;
      }

      // Found the start of a block...
      //messageNwait("oc_c_nextBlock foundstartblock ch="ch);
      break;
   }

   // Found a structured block. A structured block is one enclosed by {}.
   _str matchCh;
   if (ch == "{") {
      // If a block is already established, this { indicates
      // the begin of a structured block which is the end of the
      // established block.
      if (hasBlock) {
         // Search backward for the the start of this structured
         // code block. This could be a function header, class, struct,
         // enum.
         status = search("([A-Za-z0-9_]+[ \t]*\\()|((struct|class|enum)?+\\{)", "-r@iHXCS");
         el = p_line - 1;
         ec = 1;
         p_col = 1;
         return(0);
      }

      // Block body starts at the {
      bodysl = p_line + 1;
      bodysc = 1;

      // Match the brace to determine the end of the structured block.
      //messageNwait("oc_c_nextBlock structured block h1");
      status = _find_matching_paren(def_pmatch_max_diff);
      //messageNwait("oc_c_nextBlock structured block h2");
      if (status) return(1);
      el = p_line;
      ec = p_col;
      if (el < sl) sl = el;

      // Skip to next line.
      _nrseek(_nrseek() + 1);
      status = search("^", "r@iH");

      // If there are blank line immediately following the block, skip over the
      // blank lines.
      if (appendTrailingBlankLines) {
         oc_c_appendTrailingBlankLines(el, ec);
      }
      return(0);
   }

   // Found the start of a comment block or a normal code block.
   matchCh = ch;
   if (matchCh == ";") {
      blockType = "n"; // normal block
   } else {
      blockType = "c"; // comment block
   }
   el = p_line;
   ec = p_col;

   // Process this comment block. By this time, we already detected that
   // we need to collapse comment. We need to determine the end of the
   // comment block, and possibly, the following normal code block.
   if (blockType == "c") {
      sl = p_line;
      startCol = p_col;
      bodysl = p_line;
      bodysc = p_col;
      //messageNwait("oc_c_nextBlock commentblock h0");
      if (matchCh == " ") search("[^ \t]", "r@iHXS");  // skip over leading spaces
      //messageNwait("oc_c_nextBlock commentblock h1");
      status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+", "r@iHXC");
      //messageNwait("oc_c_nextBlock commentblock h2");
      if (status) {
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      if (collapseComment) {
         el = p_line - 1;
         ec = p_col;
         if (appendTrailingBlankLines) {
            oc_c_appendTrailingBlankLines(el, ec);
         }
         return(0);
      }

      // Fall thru to merge the following normal block to
      // this comment block.
   }

   // Process normal block.
   _str gp1, gp2, gp3, gp4, gp5, ree2;
   seek1 = _nrseek();
   _nrseek(seek1 + 1);
   while (1) {
      // Search for the following items:
      //    ;                     ==> statement termination
      //    = {                   ==> static array initializer
      //    struct/class/enum {   ==> struct definition
      //    func()                ==> function
      //messageNwait("oc_c_nextBlock normalblock h2");
      gp1 = '(^?*\c=?*\{)';
      gp2 = '\c;';
      gp3 = '(^?*\cclass(?|\n)*\{)'; // class header
      gp4 = '(^?*(struct|enum)?+\c\{)';
      gp5 = '(^[ \t]*(([A-Za-z0-9_ ]+[ \t]*\c'oparen')|//|/\*))';
      ree2 = gp1'|'gp2'|'gp3'|'gp4'|'gp5;
      status = search(ree2, "r@iHXS");
      //messageNwait("oc_c_nextBlock normalblock h3 status="status);
      if (status) {
         // Reached EOF. Current block extends to EOF.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
      ch = get_text(1);
      if (ch == "{") { // already inside another block...
         // Search backward for the the start of this structured
         // code block. This could be a function header, class, struct,
         // enum.
         status = search("([A-Za-z0-9_]+[ \t]*\\()|((struct|class|enum)?+\\{)", "-r@iHXCS");
         el = p_line - 1;
         ec = 1;
         p_col = 1;

         // Scan backward for #if (with optional blank lines between
         // #if and the block header). If found, end the normal block
         // right before the #if.
         if (!oc_c_backScanForPoundIf()) {
            if (bodysl < p_line) {
               el = p_line - 1;
               ec = 1;
            }
            return(0);
         }
         break;
      }

      if (ch == "=") {
         el = p_line - 1;
         ec = 1;
         p_col = 1;
         return(0);
      }

      // Hit class header. The class header indicates the end of
      // the current normal block.
      if (ch == "c") {
         el = p_line - 1;
         ec = 1;
         p_col = 1;
         return(0);
      }

      // If still in the same block type, expand the block and search again.
      if (ch == matchCh) {
         el = p_line;
         ec = p_col;
         seek1 = _nrseek();
         _nrseek(seek1 + 1);
         continue;
      }

      // Found possible function header.
      if (ch == "(") {
         seek1 = _nrseek();
         //messageNwait("oc_c_nextBlock found functinoheader");
         status = search(";|\\{", "r@iHXCS");
         if (status) {
            bottom();
            el = p_line;
            ec = p_col;
            return(2);
         }
         ch = get_text(1);
         if (ch == ";") {
            el = p_line;
            ec = p_col;
            seek1 = _nrseek();
            _nrseek(seek1 + 1);
            continue;
         }
         _nrseek(seek1);
         p_col = 1;
         el = p_line - 1;
         ec = 1;

         // Scan backward for #if (with optional blank lines between
         // #if and the block header). If found, end the normal block
         // right before the #if.
         if (!oc_c_backScanForPoundIf()) {
            if (bodysl < p_line) {
               el = p_line - 1;
               ec = 1;
            }
            return(0);
         }
         break;
      }

      // Found start of a comment block.
      // Comment block follows normal block but we don't need to
      // collapse comment. Mark end normal block.
      if (!collapseComment) {
         p_col = 1;
         el = p_line - 1;
         ec = 1;
         return(0);
      }

      // If we need to collapse comment block, merge the comment
      // block to the existing normal block.
      // Skip over comment block.
      status = search("^[ \t]*[A-Za-z0-9~!@#$%^&*()_+`\\-=:'\",.<>\\?]+","r@iHXCS");
      if (status) {
         // Hit EOF. Consider here to the end of the file a code block.
         bottom();
         el = p_line;
         ec = p_col;
         return(2);
      }
   }

   // If there are blank line immediately following the block, skip over the
   // blank lines.
   if (appendTrailingBlankLines) {
      oc_c_appendTrailingBlankLines(el, ec);
   }
   return(0);
}
