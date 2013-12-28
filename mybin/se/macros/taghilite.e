////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46076 $
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
#include "markers.sh"
#include "color.sh"
#import "c.e"
#import "listproc.e"
#import "setupext.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagform.e"
#import "slickc.e"
#import "se/tags/TaggingGuard.e"
#endregion

static _str gwindow_filename;
static int  gwindow_seekpos;
static int  gwindow_scroll_pos;
static int  gwindow_height;
static int  gwindow_last_modified;

static _str gsymbol_name;
static _str gsymbol_file_name;
static int  gsymbol_line_no;
static int  gsymbol_marker;
static int  gSymbolScrollMarkerType;

static struct VS_TAG_RETURN_TYPE gsymbol_visited:[];

/**
 * Sets the maximum buffer size that will symbol highlight will 
 * search and highlight all matching occurrences.   If the 
 * buffer size is greater than the max size, then highlighting 
 * is restricted to only visible lines, and there will be a 
 * slight delay when scrolling to highlight matching symbols in 
 * view. 
 * 
 * @default  1048576
 * @category Configuration_Variables
 */
int def_highlight_symbols_max_bufsize = 1048576;


/**
 * Maximum number of matching occurrences to highlight for 
 * symbol highlighting. 
 * 
 * @default  100
 * @category Configuration_Variables
 */
int def_highlight_symbols_max_matches = 100;


/**
 * Symbol highlighting should stop searching after this amount of 
 * time.  This is done to prevent large typing delays. 
 *
 * @default 1000 milliseconds (1 second)
 * @categories Configuration_Variables
 */
int def_highlight_symbols_timeout_time = 1000;


static void _init_markers()
{
   if (gsymbol_marker <= 0) {
      gsymbol_marker = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(gsymbol_marker, VSMARKERTYPEFLAG_AUTO_REMOVE);
   }

   if (gSymbolScrollMarkerType <= 0) {
      gSymbolScrollMarkerType = _ScrollMarkupAllocType();
      _ScrollMarkupSetTypeColor(gSymbolScrollMarkerType, CFG_SYMBOL_HIGHLIGHT);
   }
}

static void _clear_markers()
{
   if (gsymbol_marker >= 0) {
      _StreamMarkerRemoveAllType(gsymbol_marker);
   }
   if (gSymbolScrollMarkerType >= 0) {
      _ScrollMarkupRemoveAllType(gSymbolScrollMarkerType);
   }
}

definit()
{
   gwindow_filename = '';
   gwindow_seekpos = 0;
   gwindow_scroll_pos = -1;
   gwindow_height = 0;
   gwindow_last_modified = 0;
   gsymbol_name = '';
   gsymbol_file_name = '';
   gsymbol_line_no = -1;
   gsymbol_marker = -1;
   gSymbolScrollMarkerType = -1;
   gsymbol_visited._makeempty();
}

void _update_current_symbol()
{
   gsymbol_name = '';
   gsymbol_file_name = '';
   gsymbol_line_no = -1;

   wordchars := _clex_identifier_chars();
   cfg := _clex_find(0, 'g');
   ch := get_text();
   if (cfg == CFG_STRING || cfg == CFG_COMMENT || cfg == CFG_NUMBER || cfg == CFG_KEYWORD || pos('[~'wordchars']', ch, 1, 'r')) {
      if (p_col > 1) {
         left(); cfg = _clex_find(0, 'g'); ch = get_text(); right();
         if (cfg == CFG_STRING || cfg == CFG_COMMENT || cfg == CFG_NUMBER || cfg == CFG_KEYWORD || pos('[~'wordchars']', ch, 1, 'r')) {
            return;
         }
      } else {
         return;
      }
   }

   struct VS_TAG_BROWSE_INFO cm;
   status := tag_get_browse_info("", cm, true, null, true, true);
   if (status == COMMAND_CANCELLED_RC || cm.member_name == "") {
      return;
   }
   gsymbol_name = cm.member_name;
   gsymbol_file_name = cm.file_name;
   gsymbol_line_no = cm.line_no;
}

void _render_highlights(boolean highlight_all = true)
{
   if (gsymbol_name :== '' || gsymbol_file_name :== '' || gsymbol_line_no < 0) {
      _clear_markers();
      refresh();
      return;
   }
   long start_seekpos, end_seekpos;
   if (highlight_all) {
      start_seekpos = end_seekpos = 0;
   } else {
      save_pos(auto p);
      if (p_scroll_left_edge >= 0) {
         _str line_pos, down_count, SoftWrapLineOffset;
         parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
         goto_point(line_pos);
         down((int)down_count);
         set_scroll_pos(p_scroll_left_edge, 0, (int)SoftWrapLineOffset);
         start_seekpos = (long)line_pos;
      } else {
         p_cursor_y = 0; _begin_line();
         start_seekpos =_QROffset();
      }
      p_cursor_y = p_client_height - 1; ++p_line; _end_line();
      end_seekpos = _QROffset();
      restore_pos(p);
   }

   _SetTimeout(def_highlight_symbols_timeout_time);
   int seekPositions[]; seekPositions._makeempty();
   _str errorArgs[]; errorArgs._makeempty();
   int maxMatches = def_highlight_symbols_max_matches;
   int numMatches = 0;
   int status = tag_match_occurrences_in_file_get_positions(
                  errorArgs, seekPositions,
                  gsymbol_name, p_EmbeddedCaseSensitive,
                  gsymbol_file_name, gsymbol_line_no,
                  VS_TAGFILTER_ANYTHING, (int)start_seekpos, (int)end_seekpos,
                  numMatches, maxMatches,
                  gsymbol_visited);
   _SetTimeout(0);

   int i;
   symbol_name_len := length(gsymbol_name);
   _clear_markers();
   for (i = 0; i < seekPositions._length(); ++i) {
      markerIndex := _StreamMarkerAdd(p_window_id, seekPositions[i], symbol_name_len, true, 0, gsymbol_marker, null);
      _StreamMarkerSetTextColor(markerIndex, CFG_SYMBOL_HIGHLIGHT);

      _ScrollMarkupAddOffset(p_window_id,seekPositions[i],gSymbolScrollMarkerType,symbol_name_len);
   }
   refresh();
}

void _UpdateContextHighlights(boolean AlwaysUpdate = false)
{
   if ((!AlwaysUpdate && _idle_time_elapsed() < def_update_tagging_idle) ||
       _no_child_windows()) {
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!AlwaysUpdate && 
       !(_mdi.p_child.p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) &&
       _idle_time_elapsed() < def_update_tagging_idle+def_update_tagging_extra_idle) {
      return;
   }

   // check if highlighting is enabled for this file
   doHighlights := (_mdi.p_child._GetCodehelpFlags() & VSCODEHELPFLAG_HIGHLIGHT_TAGS) && 
                   (_mdi.p_child._istagging_supported());
   
   // check if we can get a lock on the tag database immediately.
   se.tags.TaggingGuard sentry;
   if (doHighlights) {
      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      haveDBLock := tag_trylock_db(dbName);
      if (!AlwaysUpdate && !haveDBLock) {
         return;
      }
      // replace the trylock with a guard to handle all function return paths
      status := sentry.lockDatabase(dbName,def_highlight_symbols_timeout_time);
      if (haveDBLock) {
         tag_unlock_db(dbName);
      }
      if (status < 0) {
         return;
      }
   }

   // initialize markers and then return if highlighting isn't enabled.
   _init_markers();
   if (!doHighlights) {
      _clear_markers();
      return;
   }

   curr_seekpos := (int)_mdi.p_child._QROffset();
   show_all := (_mdi.p_child.p_buf_size < def_highlight_symbols_max_bufsize);
   if (gwindow_seekpos == curr_seekpos &&
       gwindow_filename :== _mdi.p_child.p_buf_name &&
       gwindow_last_modified == _mdi.p_child.p_LastModified) {
      if (show_all) {
         return;
      } else {
         if (gwindow_height == _mdi.p_child.p_height && _mdi.p_child.p_scroll_left_edge < 0) {
            return;
         }
         parse _mdi.p_child._scroll_page() with auto line_pos .;
         if (gwindow_height == _mdi.p_child.p_height && gwindow_scroll_pos == (int)line_pos) {
            return;
         }
         gwindow_scroll_pos = (int)line_pos;
         gwindow_height = _mdi.p_child.p_height;
      }
   } else {
      old_symbol_name := gsymbol_name;
      old_symbol_file_name := gsymbol_file_name;
      old_symbol_line_no := gsymbol_line_no;
      if (gwindow_filename :== _mdi.p_child.p_buf_name) {
         if (gwindow_last_modified != _mdi.p_child.p_LastModified) {
            gwindow_last_modified = _mdi.p_child.p_LastModified;
            gsymbol_visited._makeempty();
         }
      } else {
         gwindow_filename = _mdi.p_child.p_buf_name;
         gwindow_last_modified = _mdi.p_child.p_LastModified;
         old_symbol_name = '';
      }
      gwindow_seekpos = curr_seekpos;
      gwindow_scroll_pos = -1;

      _mdi.p_child._update_current_symbol();
      if (old_symbol_name :== gsymbol_name &&
          old_symbol_file_name :== gsymbol_file_name &&
          old_symbol_line_no == gsymbol_line_no) {
         return;
      }
   }
   _mdi.p_child._render_highlights(show_all);
}

