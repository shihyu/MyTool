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
#import "context.e"
#import "listproc.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagform.e"
#import "se/tags/TaggingGuard.e"
#endregion

static _str gwindow_filename;
static long gwindow_seekpos;
static int  gwindow_scroll_pos;
static int  gwindow_height;
static int  gwindow_last_modified;
static long gwindow_id_seekpos;
static long gwindow_lo_seekpos;
static long gwindow_hi_seekpos;

static VS_TAG_BROWSE_INFO gsymbol_info;
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
 * @default 250 milliseconds (1/4 second)
 * @categories Configuration_Variables
 */
int def_highlight_symbols_timeout_time = 250;


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
   gwindow_filename = "";
   gwindow_seekpos = 0;
   gwindow_id_seekpos = 0;
   gwindow_lo_seekpos = 0;
   gwindow_hi_seekpos = 0;
   gwindow_scroll_pos = -1;
   gwindow_height = 0;
   gwindow_last_modified = 0;
   gsymbol_info = null;
   gsymbol_marker = -1;
   gSymbolScrollMarkerType = -1;
   gsymbol_visited._makeempty();
}

void _update_current_symbol()
{
   save_pos(auto p);

   // save the start position of the symbol
   _begin_identifier();
   gwindow_id_seekpos = _QROffset();
   restore_pos(p);

   // now look up the symbol under the cursor
   tag_init_tag_browse_info(gsymbol_info);
   wordchars := _clex_identifier_chars();
   cfg := _clex_find(0, 'g');
   ch := get_text();
   if (cfg == CFG_STRING || cfg == CFG_COMMENT || cfg == CFG_NUMBER || cfg == CFG_KEYWORD || pos("[~"wordchars"]", ch, 1, 'r')) {
      if (p_col > 1) {
         left(); cfg = _clex_find(0, 'g'); ch = get_text(); right();
         if (cfg == CFG_STRING || cfg == CFG_COMMENT || cfg == CFG_NUMBER || cfg == CFG_KEYWORD || pos("[~"wordchars"]", ch, 1, 'r')) {
            restore_pos(p);
            return;
         }
      } else {
         restore_pos(p);
         return;
      }
   }

   status := tag_get_browse_info("", 
                                 auto cm, 
                                 quiet:true, 
                                 null, 
                                 return_choices:false, 
                                 filterDuplicates:true);
   if (status == COMMAND_CANCELLED_RC || cm.member_name == "") {
      restore_pos(p);
      return;
   }
   gsymbol_info = cm;
   restore_pos(p);
}

void _render_highlights(bool highlight_all = true, bool ForceUpdate = false)
{
   if (gsymbol_info == null || 
       gsymbol_info.member_name :== "" || 
       gsymbol_info.file_name == "" || 
       gsymbol_info.line_no < 0) {
      _clear_markers();
      refresh();
      return;
   }

   // set up for doing symbol highlighting search
   start_time := (long)_time('B');
   haveNewMatches := false;
   symbol_name_len := length(gsymbol_info.member_name);
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   case_opt    := p_LangCaseSensitive? 'e' : 'i';
   id_chars    := _clex_identifier_chars();
   search_opts := case_opt:+'rh@<Xcnkaplsw=[':+id_chars:+']#';

   // first time here, make sure to highlight the "current" identifier
   if (gwindow_lo_seekpos == gwindow_hi_seekpos && 
       gwindow_lo_seekpos >= gwindow_id_seekpos && 
       gwindow_hi_seekpos <= gwindow_id_seekpos+symbol_name_len) {
      _clear_markers();
      markerIndex := _StreamMarkerAdd(p_window_id, gwindow_id_seekpos, symbol_name_len, true, 0, gsymbol_marker, null);
      _StreamMarkerSetTextColor(markerIndex, CFG_SYMBOL_HIGHLIGHT);
      _ScrollMarkupAddOffset(p_window_id, gwindow_id_seekpos, gSymbolScrollMarkerType, symbol_name_len);
      haveNewMatches = true;
      restore_pos(p);
      gwindow_lo_seekpos = gwindow_id_seekpos;
      gwindow_hi_seekpos = gwindow_id_seekpos+symbol_name_len;
   }

   // we have searched the entire buffer
   if (gwindow_lo_seekpos == 0 && gwindow_hi_seekpos >= p_buf_size) {
      return;
   }


   // loop until we run out of time or space
   // we are trying to search from the middle (cursor location) out to the
   // further points within the file.
   loop {

      // first try searching backwards for symbol match nearest cursor
      search_status := STRING_NOT_FOUND_RC;
      if (gwindow_lo_seekpos > 0 && (gwindow_seekpos - gwindow_lo_seekpos) < (gwindow_hi_seekpos - gwindow_seekpos)) {
         _GoToROffset(gwindow_lo_seekpos-1);
         search_status = search(_escape_re_chars(gsymbol_info.member_name), '-':+search_opts);
         if (search_status < 0) {
            gwindow_lo_seekpos = 0;
         } else {
            gwindow_lo_seekpos = _QROffset();
         }
      }

      // no match before cursor, so check if there are more to find after cursor
      if (search_status < 0 && gwindow_hi_seekpos < p_buf_size) {
         _GoToROffset(gwindow_hi_seekpos+1);
         search_status = search(_escape_re_chars(gsymbol_info.member_name), search_opts);
         if (search_status < 0) {
            gwindow_hi_seekpos = p_buf_size;
         } else {
            gwindow_hi_seekpos = _QROffset()+symbol_name_len;
         }
      }

      // no match after the cursor, but we have not searched everything before
      if (search_status < 0 && gwindow_lo_seekpos > 0) {
         _GoToROffset(gwindow_lo_seekpos-1);
         search_status = search(_escape_re_chars(gsymbol_info.member_name), '-':+search_opts);
         if (search_status < 0) {
            gwindow_lo_seekpos = 0;
         } else {
            gwindow_lo_seekpos = _QROffset();
         }
      }

      // now determine if the word under the cursor matches
      if (search_status < 0) break;
      curr_seekpos := _QROffset();

      //int seekPositions[];
      _str errorArgs[];
      status := tag_match_single_symbol_occurrence_in_file(errorArgs, 
                                                           gsymbol_info, p_EmbeddedCaseSensitive,
                                                           SE_TAG_FILTER_ANYTHING, 
                                                           SE_TAG_CONTEXT_ANYTHING, 
                                                           def_highlight_symbols_max_matches, 
                                                           gsymbol_visited, depth:1);
      if (!status) {
         markerIndex := _StreamMarkerAdd(p_window_id, curr_seekpos, symbol_name_len, true, 0, gsymbol_marker, null);
         _StreamMarkerSetTextColor(markerIndex, CFG_SYMBOL_HIGHLIGHT);
         _ScrollMarkupAddOffset(p_window_id, curr_seekpos, gSymbolScrollMarkerType, symbol_name_len);
         haveNewMatches = true;
      }

      // have we used up our time slice ?
      if (!ForceUpdate) {
         now := (long)_time('B');
         if (now - start_time >= def_highlight_symbols_timeout_time) {
            break;
         }
      }
   }

   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   if (haveNewMatches) {
      refresh();
   }
}

void _MaybeUpdateContextHighlights(bool AlwaysUpdate = false)
{
   _UpdateContextHighlights(AlwaysUpdate);
}

void _UpdateContextHighlights(bool AlwaysUpdate = false, bool ForceUpdate = false)
{
   if (!_haveContextTagging()) {
      return;
   }

   elapsed := _idle_time_elapsed();
   if ((!AlwaysUpdate && elapsed < def_update_tagging_idle) || _no_child_windows()) {
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!AlwaysUpdate && !_mdi.p_child._ContextIsUpToDate(elapsed, MODIFYFLAG_CONTEXT_UPDATED|MODIFYFLAG_TOKENLIST_UPDATED)) {
      return;
   }

   // Bail out for large files.
   if (!_mdi.p_child._CheckUpdateContextSizeLimits(0, true)) {
      return;
   }

   // check if highlighting is enabled for this file
   doHighlights := (_mdi.p_child._GetCodehelpFlags() & VSCODEHELPFLAG_HIGHLIGHT_TAGS) && 
                   (_mdi.p_child._istagging_supported());
   
   // check if we can get a lock on the tag database immediately.
   se.tags.TaggingGuard sentry;
   if (doHighlights || ForceUpdate) {
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
   if (!doHighlights && !ForceUpdate) {
      _clear_markers();
      return;
   }

   curr_seekpos := _mdi.p_child._QROffset();
   show_all := (_mdi.p_child.p_buf_size < def_highlight_symbols_max_bufsize);
   if (gsymbol_info != null && 
       gsymbol_info.member_name != null && 
       length(gsymbol_info.member_name) > 0 &&
       curr_seekpos >= gwindow_id_seekpos && 
       curr_seekpos <= gwindow_id_seekpos+length(gsymbol_info.member_name) &&
       gwindow_filename :== _mdi.p_child.p_buf_name &&
       gwindow_last_modified == _mdi.p_child.p_LastModified) {

      if (show_all) {
         if (gwindow_lo_seekpos <= 0 && gwindow_hi_seekpos >= _mdi.p_child.p_buf_size) {
            return;
         }
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

      old_symbol_info := gsymbol_info;
      if (gwindow_filename :== _mdi.p_child.p_buf_name) {
         if (gwindow_last_modified != _mdi.p_child.p_LastModified) {
            gwindow_last_modified = _mdi.p_child.p_LastModified;
            gsymbol_visited._makeempty();
         }
      } else {
         gwindow_filename = _mdi.p_child.p_buf_name;
         gwindow_last_modified = _mdi.p_child.p_LastModified;
         tag_init_tag_browse_info(old_symbol_info);
      }

      gwindow_seekpos = curr_seekpos;
      gwindow_id_seekpos = curr_seekpos;
      gwindow_lo_seekpos = curr_seekpos;
      gwindow_hi_seekpos = curr_seekpos;
      gwindow_scroll_pos = -1;

      // now get the symbol information from the tag database
      _mdi.p_child._update_current_symbol();
      if (tag_browse_info_equal(old_symbol_info, gsymbol_info)) {
         if (gwindow_lo_seekpos <= 0 && gwindow_hi_seekpos >= _mdi.p_child.p_buf_size) {
            return;
         }
      }
   }

   // find matching symbols and highlight them.
   _mdi.p_child._render_highlights(show_all, ForceUpdate);
}

_command void tag_highlight_current_symbol() name_info(',')
{
   if (_no_child_windows()) return;
   wid := _isEditorCtl()? p_window_id : _mdi.p_child;
   wid._UpdateContextHighlights(AlwaysUpdate:true, ForceUpdate:true);
}

_command void tag_clear_symbol_highlights() name_info(',')
{
   if (_no_child_windows()) return;
   wid := _isEditorCtl()? p_window_id : _mdi.p_child;
   wid._clear_markers();
}

