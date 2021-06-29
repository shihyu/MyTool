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
#include "slick.sh"
#include "markers.sh"
#include "mfsearch.sh"
#include "tagsdb.sh"
#import "se/datetime/DateTime.e"
#import "se/tags/TaggingGuard.e"
#import "context.e"
#import "files.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "pushtag.e"
#import "search.e"
#import "sellist.e"
#import "seltree.e"
#import "seldisp.e"
#import "stdprocs.e"
#import "tbsearch.e"
#import "util.e"

int def_search_result_max_line_size = 500;
int def_search_result_truncate_cols = 0;
int def_search_result_multiline_matches = 1;
int def_search_result_list_nested_re_matches = 0;
int def_search_result_min_prefix_width = 6;
_str def_search_result_separator_char = '-';
int def_search_result_sorted_filenames = 0;

using namespace se.datetime;

namespace se.search;

static const SEARCH_RESULT_TRUNCATE_LEADING_FLAG = 0x1;
static const SEARCH_RESULT_TRUNCATE_TRAILING_FLAG = 0x2;

enum {
   SEARCH_RESULT_PREFIX = -1,
   SEARCH_RESULT_LINE_MATCH = 0,
   SEARCH_RESULT_LINE_CONTINUATION = 1,
   SEARCH_RESULT_LINE_PRE_MATCH = 2,
   SEARCH_RESULT_LINE_POST_MATCH = 3,
   SEARCH_RESULT_LINE_SEPARATOR = 4,
};

class SearchResults {
   private _str   m_last_file = '';
   private int    m_match_line = -1;
   private int    m_match_col = -1;
   private int    m_prefix_width = -1;
   private int    m_last_line = -1;
   private int    m_last_col = -1;
   private int    m_top_line = 1;
   private int    m_mfflags = 0;
   private int    m_wid = 0;
   private int    m_grepid = 0;
   private int    m_context_id = -1;
   private int    m_context_level = -1;
   private int    m_last_buf_id = -1;
   private int    m_before_match_lines = 0;
   private int    m_after_match_lines = 0;
   private bool   m_context_enabled = false;
   private _str   m_after_lines[];

   private int    m_context_stack[];

   static void resetFindMark(int grep_id) {
      get_window_id(auto orig_view_id);
      results_id := _get_grep_buffer_view(grep_id);
      activate_window(results_id);
      _mffindSetMark();
      activate_window(orig_view_id);
   }

   void initialize(_str topline, _str search_text, int mfflags, int grep_id, int before_lines = 0, int after_lines = 0) {
      get_window_id(auto orig_view_id);
      set_grep_buffer(grep_id, search_text);
      results_id := _get_grep_buffer_view(grep_id);
      activate_window(results_id);
      grep_buf_id := p_buf_id;
      m_last_file = '';
      m_last_line = -1;
      m_last_col = -1;
      m_prefix_width = -1;
      m_top_line = p_Noflines + 1;
      m_mfflags = mfflags;
      m_grepid = grep_id;
      m_context_id = -1;
      m_context_level = -1;
      m_last_buf_id = -1;
      m_before_match_lines = before_lines;
      m_after_match_lines = after_lines;
      m_after_lines._makeempty();
      m_context_enabled = false;
      m_context_stack._makeempty();

      get_window_id(m_wid);
      if (!(m_mfflags & MFFIND_APPEND)) {
         _lbclear(); p_col = 1;
         m_top_line = 1;
      }
      bottom();
      insert_line(topline);
      _lineflags(MINUSBITMAP_LF|0,MINUSBITMAP_LF|LEVEL_LF|HIDDEN_LF);
      _begin_line(); _mffindSetMark();
      p_undo_steps = 0;
      toolSearchScroll();
      activate_window(orig_view_id);
   }

   void done(_str results_text) {
      if (!m_wid) {
         return;
      }
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom(); insert_line(results_text); _lineflags(0, LEVEL_LF|CURLINEBITMAP_LF|HIDDEN_LF);
      p_line = m_top_line; p_col = 1;
      p_undo_steps = _DefaultUndoSteps();
      activate_window(orig_view_id);
   }

   static _str getLineExpanded(_str& line, int &col, int &match_len) {
      if (match_len > length(line)) {
         match_len = length(line);
      }
      orig_col := col; orig_len := match_len;
      expanded_line := "";
      if (col > 1) {
         expanded_line = expand_tabs(substr(line, 1, orig_col - 1));
         col = length(expanded_line) + 1;
      }
      expanded_line = expand_tabs(expanded_line:+substr(line, orig_col, orig_len));
      match_len = length(expanded_line) - col + 1;
      expanded_line = expand_tabs(expanded_line:+substr(line, orig_col + orig_len));
      return expanded_line;
   }

   public static _str convertToUTF8(_str origline, int& pcol, int& plen) {
      line := _MultiByteToUTF8(origline);
      leading := _MultiByteToUTF8(substr(origline, 1, pcol));
      matchword := _MultiByteToUTF8(substr(origline, pcol, plen));
      pcol = _strBeginChar(leading, length(leading));
      plen = length(matchword);
      return line;
   }

   // truncate result for long lines
   static int getSearchResultLine(_str& line, int &col, int &match_len) {
      if (!_isEditorCtl()) {
         return 0;
      }
      utf8 := p_UTF8;
      status := 0;
      pcol := _text_colc(col, 'P');
      if (pcol + match_len - 1 > _line_length()) {
         match_len = (_line_length() - _text_colc(pcol, 'P')) + 1;
      }

      if (def_search_result_truncate_cols > 0) {
         if (_line_length() + 1 > p_col + match_len + def_search_result_truncate_cols) {
            status |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
         }
         if (p_col - 1 > def_search_result_truncate_cols) {
            status |= SEARCH_RESULT_TRUNCATE_LEADING_FLAG;
         }
         if (status) {
            save_pos(auto p);
            linelen := _line_length();
            if (status & SEARCH_RESULT_TRUNCATE_TRAILING_FLAG) {
               orig_col := p_col;
               p_col += match_len + def_search_result_truncate_cols;
               if (p_UTF8 || _dbcs() || _text_colc(p_col, 'T') < 0) {
                  right(); left();
               }
               linelen = _text_colc(p_col, 'P') - 1;
               p_col = orig_col;

            } else {
               linelen = _line_length();
            }

            // check leading length
            if (status & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
               p_col -= def_search_result_truncate_cols;
               if (p_UTF8 || _dbcs() || _text_colc(p_col, 'T') < 0) {
                  left(); right();
               }
               width := _text_colc(p_col, 'P') - 1;
               linelen -= width;
               col = col - width;
            } else {
               _begin_line();
            }

            line = get_text_raw(linelen);
            if (!utf8) {
               line = convertToUTF8(line, col, match_len);
            }
            restore_pos(p);
            return status;
         }
      }

      if (def_search_result_max_line_size > 0) {
         if (_line_length() > def_search_result_max_line_size) {
            if (pcol + match_len - 1 > def_search_result_max_line_size) {
               match_len = -1;
            }
            save_pos(auto p);
            p_col = def_search_result_max_line_size + 1;
            if (p_UTF8 || _dbcs() || _text_colc(p_col, 'T') < 0) {
               right(); left();
            }
            linelen := _text_colc(p_col, 'P') - 1;
            status |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
            _begin_line();
            line = get_text_raw(linelen);
            if (!utf8) {
               line = convertToUTF8(line, col, match_len);
            }
            restore_pos(p);
            return status;
         }
      }

      get_line_raw(line);
      if (!utf8) {
         line = convertToUTF8(line, col, match_len);
      }
      line = getLineExpanded(line, col, match_len);
      return 0;
   }

   void setMatchLinenum(int linenum, int col) {
      m_match_line = linenum; m_match_col = col;
      if (m_mfflags & MFFIND_SINGLELINE) {
         if (linenum != m_last_line) {
            m_prefix_width = length('  'linenum' 'col':'); // default width
         }

      } else {
         m_prefix_width = length('  'linenum' 'col':'); // default width
      }
      if (m_prefix_width < def_search_result_min_prefix_width) {
         m_prefix_width = def_search_result_min_prefix_width;
      }
   }

   private void insertAfterLines(int match_linenum) {
      if (!m_after_lines._isempty()) {
         foreach(auto l in m_after_lines) {
            parse l with auto lnum ":" auto truncated ":" auto line;
            int linenum = (int)lnum;
            if ((match_linenum > 0) && (linenum >= match_linenum)) break;
            insertLine(linenum, -1, -1, line, SEARCH_RESULT_LINE_POST_MATCH, (int)truncated);
         }
         m_after_lines._makeempty();
      }
   }

   void setContext(int context_id, int context_level) {
      m_context_id = context_id;
      if (context_level > LEVEL_LF) {
         context_level = LEVEL_LF;
      }
      m_context_level = context_level;
   }

   void insertFileLine(_str filename, bool checkFileContext = true) {
      if (!m_wid) {
         return;
      }
      insertAfterLines(-1);
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom();
      insert_line('File 'filename);  
      _lineflags((m_mfflags & MFFIND_FILESONLY) ? NEXTLEVEL_LF : NEXTLEVEL_LF | MINUSBITMAP_LF,
                 (m_mfflags & MFFIND_FILESONLY) ? LEVEL_LF | CURLINEBITMAP_LF | HIDDEN_LF : LEVEL_LF | MINUSBITMAP_LF | CURLINEBITMAP_LF | HIDDEN_LF);   
      p_col = 1; _SetTextColor(CFG_FILENAME, _line_length(), false);
      activate_window(orig_view_id);

      m_last_file = filename;
      m_last_line = -1;
      m_last_col = -1;
      m_context_id = -1;
      m_context_level = -1;
      m_prefix_width = -1;

      // disable for proc-search languages
      if (checkFileContext) {
         m_context_enabled = (_istagging_supported(p_LangId) && (!_FindLanguageCallbackIndex("%s_proc_search")));
      } else {
         m_context_enabled = false;
      }
   }

   void insertLine(int linenum, int pcol, int match_len, _str line, int type, int truncated, bool check_output = true) {
      if (!m_wid) {
         return;
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      get_window_id(auto orig_view_id);
      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      if (m_context_id >= 0) {
         next_level = m_context_level;
      }

      prefix := '';
      suffix := '';
      // build prefix
      switch (type) {
      case SEARCH_RESULT_LINE_MATCH:
         prefix = m_match_line' 'm_match_col':';
         break;

      case SEARCH_RESULT_LINE_CONTINUATION:
         prefix = ':';
         break;

      case SEARCH_RESULT_LINE_PRE_MATCH:
         prefix = '-:';
         break;

      case SEARCH_RESULT_LINE_POST_MATCH:
         prefix = '+:';
         break;

      case SEARCH_RESULT_LINE_SEPARATOR:
         if (def_search_result_separator_char :!= '') {
            prefix = substr('', 1, m_prefix_width - 1, def_search_result_separator_char):+':';
         }
         break;
      }
      pad := m_prefix_width - length(prefix);
      if (pad > 0) {
         prefix = substr('', 1, pad, " "):+prefix;
      }

      if (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
         prefix :+= '...';
      }
      if (truncated & SEARCH_RESULT_TRUNCATE_TRAILING_FLAG) {
         suffix = '... ';
      }
      if (truncated) {
         suffix :+= ' [line truncated]';
      }

      activate_window(m_wid);
      bottom();
      bool inserted_line=true;
      if (/*!truncated && */(type == SEARCH_RESULT_LINE_MATCH) && (m_mfflags & MFFIND_SINGLELINE)) {
         if (m_last_line !=linenum) {
            insert_line(prefix:+line:+suffix);
            _lineflags(next_level, LEVEL_LF);
            pcol += length(prefix);
         } else {
            inserted_line=false;
            if (truncated && ((truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) || pcol+match_len>_text_colc(length(prefix:+line) + 1, 'I'))) {
               match_len=0;
            }
            pcol += m_prefix_width;
         }

      } else {
         insert_line(prefix:+line:+suffix);
         _lineflags(next_level, LEVEL_LF);
         pcol += length(prefix);
      }
      m_last_line = linenum;

      if (match_len > 0) {
         p_col = _text_colc(pcol, 'I');
         _SetTextColor(CFG_HILIGHT, match_len, false);
      }
      if (inserted_line && (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG)) {
         // highlight '...'
         p_col = _text_colc(length(prefix) - 2, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, 3, false);
      }
      if (inserted_line && truncated && suffix != '') {
         // highlight suffix '...  [line truncated]'
         p_col = _text_colc(length(prefix:+line) + 1, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, length(suffix), false);
      } 
      if (check_output) checkOutput();
      activate_window(orig_view_id);
   }

   void insertContextLine(int context_id, _str context_name = '', int context_type = 0, int context_linenum = -1, int context_level = 0) {
      if (!m_wid) {
         return;
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }

      insertAfterLines(-1);
      if (context_id < 0) {
         m_context_id = -1;
         return;
      }

      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom();

      line := ' ':+_grep_get_context_word(context_type):+' ':+context_name:+' : ':+context_linenum;
      insert_line(line);
      new_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      if (context_level > 0) {
         new_level += (NEXTLEVEL_LF * context_level);
      }
      flags := 0;
      if (new_level > LEVEL_LF) {
         new_level = LEVEL_LF;
      } else {
         flags |= MINUSBITMAP_LF;
      }
      flags |= new_level;
      _lineflags(flags, LEVEL_LF | MINUSBITMAP_LF | CURLINEBITMAP_LF);   
      p_col = 1; _SetTextColor(CFG_FUNCTION, _line_length(), false);
      activate_window(orig_view_id);
   }

   void pushContextScope(int context_id) {
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }

      buf_id := p_buf_id;

      int scope_ids[];
      if (context_id >= 0) {
         tag_search_result_context_get_contexts(buf_id, context_id, scope_ids);
      }

      i := 0;
      index := -1;
      // match current tag stack to new context stack
      for (i = 0; (i < m_context_stack._length()) && (i < scope_ids._length()); ++i, ++index) {
         if (m_context_stack[i] != scope_ids[i]) {
            break;
         }
      }

      // remove old elements
      for (i = index + 1; i < m_context_stack._length(); ++i) {
         m_context_stack._deleteel(i);
      }

      if (context_id < 0) {
         if (m_context_id >= 0) {
            insertLine(-1, -1, -1, "", SEARCH_RESULT_LINE_SEPARATOR, 0);
         }
         m_context_level = NEXTLEVEL_LF + NEXTLEVEL_LF;
         m_context_id = context_id;
         return;
      }

      // add new elements
      for (i = index + 1; i < scope_ids._length(); ++i) {
         parent_id := scope_ids[i];

         status := tag_search_result_context_get_info(buf_id, parent_id, auto context_type, auto context_linenum, auto context_name);
         if (!status) {
            insertContextLine(parent_id, context_name, context_type, context_linenum, i);
         }
         m_context_stack[i] = parent_id;
      }

      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF + (m_context_stack._length() * NEXTLEVEL_LF);
      if (next_level > LEVEL_LF) {
         next_level = LEVEL_LF;
      }
      m_context_level = next_level;
      m_context_id = context_id;
   }

   private void updateCurrentContext() {
      if (!m_context_enabled) {
         return;
      }

      buf_id := p_buf_id;
      linenum := p_line;
      match_offset := match_length('S');
      context_id := tag_search_result_context_find(buf_id, linenum, match_offset);

      if (m_context_id != context_id) {
         pushContextScope(context_id);
      }
   }

   private void buildContextTable() {
      if (!m_context_enabled) {
         return;
      }
      if (m_last_buf_id >= 0) {
         tag_search_result_context_end(m_last_buf_id);
         m_last_buf_id = -1;
      }

      buf_id := p_buf_id;
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true, true);
      tag_search_result_context_start(buf_id);
      m_last_buf_id = buf_id;
   }
   
   void insertMatchOnly() {
      match_linenum := p_RLine;
      match_col := _text_colc(p_col, 'P');
      match_offset := match_length('S');
      match_len := match_length();

      setMatchLinenum(match_linenum, match_col);

      utf8 := p_UTF8;
      end_offset := (match_len > 0) ? (match_offset + match_len - 1) : match_offset;
      goto_point(match_offset);
      offset := (int)point('S');
      line_type := SEARCH_RESULT_LINE_MATCH;
      mlen := match_len;
      linenum := match_linenum; 
      do {
         last_offset := offset;
         pcol := _text_colc(p_col, 'P'); len := mlen;
         truncated := 0;
         line_len := (_line_length() - pcol) + 1;
         if (line_len > len) {
            line_len = len;
         }
         if ((def_search_result_max_line_size > 0) && (line_len > def_search_result_max_line_size)) {
            line_len = def_search_result_max_line_size;
            truncated |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
         }
         line := get_text_raw(line_len); pcol = 1;
         if (!utf8) {
            line = convertToUTF8(line, pcol, line_len);
         }
         if (len < 0) len = 0;
         insertLine(linenum, pcol, line_len, line, line_type, truncated);
         if (!def_search_result_multiline_matches) break;
         if (down()) break;
         _begin_line(); offset = (int)point('S');
         mlen -= (offset - last_offset);
         line_type = SEARCH_RESULT_LINE_CONTINUATION;
         ++linenum;
      } while ((offset < end_offset) && (mlen > 0));
   }

   void insertCurrentMatch() {
      if (!m_wid) {
         return;
      }
      buf_name := _build_buf_name();
      insert_ab_sep := false;
      if (m_last_file != buf_name) {
         insertFileLine(buf_name);
         if ((m_mfflags & MFFIND_LIST_CURRENT_CONTEXT) && !(m_mfflags & MFFIND_FILESONLY)) {
            buildContextTable();
         }
      }

      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }

      if (m_mfflags & MFFIND_LIST_CURRENT_CONTEXT) {
         updateCurrentContext();
      }

      if (m_mfflags & MFFIND_MATCHONLY) {
         insertMatchOnly();
         return;
      }

      match_linenum := p_RLine;
      match_col := _text_colc(p_col, 'P');
      // Handle case where very long line is force wrapped into multiple lines
      if (p_line!=match_linenum) {
         orig_linenum:=p_line;
         for (;;) {
            up();
            if (p_RLine!=match_linenum) {
               break;
            }
            match_col+=_line_length();
         }
         p_line=orig_linenum;
      }
      match_offset := match_length('S');
      match_len := match_length();

      save_pos(auto p);
      pre_match_lines := m_before_match_lines;
      post_match_lines := m_after_match_lines;
      if (pre_match_lines > 0 || post_match_lines > 0) {
         if (post_match_lines > 0) {
            insertAfterLines(match_linenum);
         }
         if (m_last_line > 0) {
            insert_ab_sep = true;
         }
         if (pre_match_lines > 0) {
            // check prematch lines
            if (match_linenum < pre_match_lines + 1) {
               pre_match_lines = match_linenum - 1;
            }

            if (m_last_line > 0) {
               if (match_linenum <= (m_last_line + pre_match_lines)) {
                  pre_match_lines = match_linenum - (m_last_line + 1);
                  insert_ab_sep = false;

               } else if ((match_linenum - pre_match_lines) <= (m_last_line + 1)) {
                  insert_ab_sep = false;
               }
            }

         } else {
            if (m_last_line > 0) {
               // don't add seperator for consecutive lines
               if (match_linenum <= (m_last_line + 1)) {
                  insert_ab_sep = false;
               }
            }
         }

         if (insert_ab_sep) {
            insertLine(-1, -1, -1, "", SEARCH_RESULT_LINE_SEPARATOR, 0);
         }
      }

      setMatchLinenum(match_linenum, match_col);

      // insert pre-lines
      if (pre_match_lines > 0) {
         up(pre_match_lines);
         linenum := match_linenum - pre_match_lines; 
         for (i := 0; i < pre_match_lines; ++i, ++linenum) {
            _begin_line(); len := _line_length();
            truncated := getSearchResultLine(auto line, 1, len);
            insertLine(linenum, 1, -1, line, SEARCH_RESULT_LINE_PRE_MATCH, truncated);
            if (down()) break;
         }
         restore_pos(p);
      }

      // insert current lines
      end_offset := (match_len > 0) ? (match_offset + match_len) : match_offset;
      goto_point(match_offset);
      linenum := match_linenum;
      offset := (int)point('S');
      line_type := SEARCH_RESULT_LINE_MATCH;
      mlen := match_len;
      do {
         last_offset := offset;
         pcol := _text_colc(p_col, 'P'); len := mlen;
         truncated := getSearchResultLine(auto line, pcol, len);
         insertLine(linenum, pcol, len, line, line_type, truncated);
         if (!def_search_result_multiline_matches) break;
         if (down()) break;
         _begin_line(); offset = (int)point('S');
         mlen -= (offset - last_offset);
         line_type = SEARCH_RESULT_LINE_CONTINUATION;
         linenum=p_RLine;
      } while ((offset < end_offset) && (mlen > 0));

      // insert post-lines
      if (post_match_lines > 0) {
         goto_point(match_offset+match_len);
         linenum = p_RLine;
         for (i := 0; i < post_match_lines; ++i) {
            if (down()) break;
            _begin_line(); len := _line_length(); ++linenum;
            truncated := getSearchResultLine(auto line, 1, len);

            // store lines
            m_after_lines[m_after_lines._length()] = linenum':'truncated':'line;
         }
      }
      restore_pos(p);
   }

   void insertCurrentReplace() {
      if (!m_wid) {
         return;
      }
      get_window_id(auto buf_view_id);
      buf_name := _build_buf_name();
      if (m_last_file != buf_name) {
         insertFileLine(buf_name);
         if (m_mfflags & MFFIND_LIST_CURRENT_CONTEXT) {
            buildContextTable();
         }
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      if (m_mfflags & MFFIND_LIST_CURRENT_CONTEXT) {
         updateCurrentContext();
      }
      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      if (m_context_id >= 0) {
         next_level += NEXTLEVEL_LF;
      }

      match_linenum := p_RLine;
      match_col := _text_colc(p_col, 'P');
      // Handle case where very long line is force wrapped into multiple lines
      if (p_line!=match_linenum) {
         orig_linenum:=p_line;
         for (;;) {
            up();
            if (p_RLine!=match_linenum) {
               break;
            }
            match_col+=_line_length();
         }
         p_line=orig_linenum;
      }
      setMatchLinenum(match_linenum, match_col);

      linenum := p_RLine; pcol:=_text_colc(p_col, 'P');
      utf8 := p_UTF8;
      replace_width :=  match_length('R');
      truncated := getSearchResultLine(auto line, pcol, replace_width);
      activate_window(m_wid);
      bottom();
      prefix := '  'match_linenum' 'match_col':';
      suffix := '';
      if (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
         prefix :+= '...';
      }
      if (truncated & SEARCH_RESULT_TRUNCATE_TRAILING_FLAG) {
         suffix = '... ';
      }
      if (truncated) {
         suffix :+= ' [line truncated]';
      }
      prefix_width := length(prefix);
      bool inserted_line=true;
      if (/*!truncated && */(m_mfflags & MFFIND_SINGLELINE)) {
         if (m_last_line != linenum) {
            insert_line(prefix:+line:+suffix); 
            _lineflags(next_level, LEVEL_LF);
         } else {
            inserted_line=false;
            p_col = _text_colc(pcol + m_prefix_width, 'I');
            if (truncated && ((truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) || p_col+replace_width>_text_colc(length(prefix:+line) + 1, 'I'))) {
               replace_width=0;
            }
            rest_of_line_len:=length(line)-pcol+1;
            if (rest_of_line_len>0) {
               _delete_text(rest_of_line_len);
               _insert_text(substr(line, pcol));
            }
            prefix_width = m_prefix_width;
         }
      } else {
         insert_line(prefix:+line:+suffix); 
         _lineflags(next_level, LEVEL_LF);
      }
      m_last_line = linenum;
      m_last_col = -1;
      m_prefix_width = prefix_width;
      pcol += prefix_width;
      if (replace_width > 0) {
         p_col = _text_colc(pcol, 'I');
         _SetTextColor(CFG_MODIFIED_LINE, replace_width, false);
      }
      if (inserted_line && (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG)) {
         // highlight '...'
         p_col = _text_colc(prefix_width - 2, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, 3, false);
      }
      if (inserted_line && truncated && suffix != '') {
         // highlight suffix '...  [line truncated]'
         p_col = _text_colc(length(prefix:+line) + 1, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, length(suffix), false);
      } 
      checkOutput();
      activate_window(buf_view_id);
   }

   void insertMessage(_str line) {
      if (!m_wid) {
         return;
      }
      insertAfterLines(-1);
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom(); insert_line(line);
      _lineflags(NEXTLEVEL_LF, LEVEL_LF | CURLINEBITMAP_LF | HIDDEN_LF);
      activate_window(orig_view_id);
   }

   void insertResult(int linenum, int col, _str line) {
      if (!m_wid) {
         return;
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      get_window_id(auto orig_view_id);
      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      if (m_context_id >= 0) {
         next_level = m_context_level;
      }

      prefix := linenum' 'col':';
      activate_window(m_wid);
      bottom();
      insert_line(prefix:+line);
      _lineflags(next_level, LEVEL_LF);
      activate_window(orig_view_id);
   }

   void endCurrentFile() {
      if (!m_wid) {
         return;
      }
      insertAfterLines(-1);
      m_prefix_width = -1;
      m_last_file = '';
      m_last_line = -1;
      m_last_col = -1;
      m_context_id = -1;
      m_context_level = -1;
      if (m_last_buf_id >= 0) {
         tag_search_result_context_end(m_last_buf_id);
         m_last_buf_id = -1;
      }
      m_context_stack._makeempty();
   }

   void showResults() {
      if (!m_wid) {
         return;
      }
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      int bufid = p_buf_id;
      if (m_mfflags & MFFIND_MDICHILD) {
         edit('+bi 'bufid, EDIT_NOADDHIST);
         grep_mode();
      } else {
         toolShowSearch(m_grepid);
      }
      activate_window(orig_view_id);
   }

   int getBufferSize() {
      if (!m_wid) {
         return 0;
      }
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      int bufsize = p_buf_size;
      activate_window(orig_view_id);
      return bufsize;
   }

   void setMFFlags(int on, int off) {
      m_mfflags = (m_mfflags & ~off) | on;
   }   

   int getMFFlags() {
      return m_mfflags;
   }

   private void checkOutput() {
      if (p_buf_size > def_max_mffind_output_ksize*1024) {
         if (def_max_mffind_output_ksize >= (2 * 1024)) {
            insert_line('Output larger than '(def_max_mffind_output_ksize intdiv 1024):+'MB. Switching to files only mode.');
         } else {
            insert_line('Output larger than '(def_max_mffind_output_ksize):+'KB. Switching to files only mode.');
         }
         _lineflags(0, LEVEL_LF|CURLINEBITMAP_LF|HIDDEN_LF);
         m_mfflags |= MFFIND_FILESONLY;
      }
   }
  
};

int _get_grep_buffer_view(int grep_id,bool check_if_active_window_is_search_results=false)
{
   if (grep_id < 0) {
      if (check_if_active_window_is_search_results) {
         if (check_if_active_window_is_search_results) {
            if (p_HasBuffer &&  substr(p_buf_name,1,7)=='.search') {
               return p_window_id;
            }
         }
         grep_id=0;
      } else {
         return 0;
      }
   }
   _str grep_buffer_name;
   grep_buffer_name = '.search'grep_id;
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '+futf8 +t', grep_buffer_name, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   p_UTF8 = true;
   activate_window(orig_wid);
   return temp_grep_view;
}

void generate_mffile_file_stats_summary(_str& summary, _str file_stats)
{
   mffile_size := _mffind_file_stats_get_file_size(file_stats);
   if (mffile_size > 0) {
      strappend(summary,', Max File Size: 'mffile_size' KB');
   }
   mffile_mod := _mffind_file_stats_get_file_modified(file_stats, auto modtime1, auto modtime2);
   if (mffile_mod > 0) {
      DateTime dt = DateTime.fromString(modtime1);
      local1 := dt.toStringParts(DT_LOCALTIME, DT_DATE);
      if (mffile_mod != MFFILE_STAT_TIME_DATE) {
         local1 = local1:+" ":+substr(dt.toStringParts(DT_LOCALTIME, DT_TIME), 1, 8);
      }
      local2 := "";
      if (mffile_mod == MFFILE_STAT_TIME_RANGE || mffile_mod == MFFILE_STAT_TIME_NOT_RANGE) {
         dt = DateTime.fromString(modtime2);
         local2 = dt.toStringParts(DT_LOCALTIME, DT_DATE):+" ":+substr(dt.toStringParts(DT_LOCALTIME, DT_TIME), 1, 8);
      }
      
      switch (mffile_mod) {
      case MFFILE_STAT_TIME_DATE:
         strappend(summary,', File Modified Date: [':+local1:+']');
         break;

      case MFFILE_STAT_TIME_BEFORE:
         strappend(summary,', File Modified Date Before: [':+local1:+']');
         break;

      case MFFILE_STAT_TIME_AFTER:
         strappend(summary,', File Modified Date After: [':+local1:+']');
         break;

      case MFFILE_STAT_TIME_RANGE:
         strappend(summary,', File Modified Date Range: [':+local1' - ':+local2:+']');
         break;

      case MFFILE_STAT_TIME_NOT_RANGE:
         strappend(summary,', File Modified Date Not In Range: [':+local1' - ':+local2:+']');
         break;

      default:
         break;
      }
   }
}

_str generate_search_summary(_str search_string, _str options, 
                             _str files, int mfflags,
                             _str wildcards, _str file_exclude='',
                             _str replace_string='', _str cur_file='', _str file_stats='')
{
   _str ss_search_string;
   int ss_flags;
   _str ss_word_re;
   _str ss_reserved_more;
   int ss_flags2;

   save_search(ss_search_string, ss_flags, ss_word_re, ss_reserved_more, ss_flags2);

   _str ts_search_string;
   int ts_flags;
   _str ts_word_re;
   _str ts_reserved_more;
   int ts_flags2;

   VSWID_HIDDEN.search('', options);
   save_search(ts_search_string, ts_flags, ts_word_re, ts_reserved_more, ts_flags2);
   restore_search(ss_search_string, ss_flags, ss_word_re, ss_reserved_more, ss_flags2);
   _str subdir_options;
   _str disp_files = strip_options(files,subdir_options,true);
   up_options := upcase(options);
   summary := "";
   if (replace_string != '') {
      summary = 'Replace all "'search_string'", "'replace_string'", ';
   } else {
      if (mfflags & MFFIND_SINGLE) {
         summary = 'Find "'search_string'", ';
      } else {
         summary = 'Find all "'search_string'", ';
      }
   }

   if (!(ts_flags & VSSEARCHFLAG_IGNORECASE)) {
      strappend(summary, 'Match case, ');
   }

   if ((ts_flags & VSSEARCHFLAG_WORDPREFIX) && (ts_flags & VSSEARCHFLAG_WORDSTRICT)) {
      strappend(summary, 'Match strict prefix, ');
   } else if (ts_flags & VSSEARCHFLAG_WORDPREFIX) {
      strappend(summary, 'Match prefix, ');
   } else if ((ts_flags & VSSEARCHFLAG_WORDSUFFIX) && (ts_flags & VSSEARCHFLAG_WORDSTRICT)) {
      strappend(summary, 'Match strict suffix, ');
   } else if (ts_flags & VSSEARCHFLAG_WORDSUFFIX) {
      strappend(summary, 'Match suffix, ');
   } else if (ts_flags & VSSEARCHFLAG_WORD) {
      strappend(summary, 'Whole word, ');
   }

   if (ts_flags & VSSEARCHFLAG_RE) {
      strappend(summary, 'Regular expression (SlickEdit), ');
   //} else if (ts_flags & VSSEARCHFLAG_UNIXRE) {
   //   strappend(summary, 'Regular expression (UNIX), ');
   //} else if (ts_flags & VSSEARCHFLAG_BRIEFRE) {
   //   strappend(summary, 'Regular expression (Brief), ');
   } else if (ts_flags & VSSEARCHFLAG_PERLRE) {
      strappend(summary, 'Regular expression (Perl), ');
   } else if (ts_flags & VSSEARCHFLAG_VIMRE) {
      strappend(summary, 'Regular expression (Vim), ');
   } else if (ts_flags & VSSEARCHFLAG_WILDCARDRE) {
      strappend(summary, 'Wildcard (*,?), ');
   }

   if (ts_flags2 != 0) {
      _str colortab[];
      colortab[0]="Other, ";
      colortab[1]=""; // E??
      colortab[2]="Keyword, ";
      colortab[3]="Number, ";
      colortab[4]="String, ";
      colortab[5]="Comment, ";
      colortab[6]="Preprocessing, ";
      colortab[7]="Line Number, ";
      colortab[8]="Symbol 1, ";
      colortab[9]="Symbol 2, ";
      colortab[10]="Symbol 3, ";
      colortab[11]="Symbol 4, ";
      colortab[12]="Function, ";
      colortab[13]=""; // no save line
      colortab[14]="Attribute, ";

      colors := "";
      not_colors := "";
      index := 0;
      int flags2 = ts_flags2;

      while (index < 15) {
         if (flags2 & 1) {
            strappend(colors, colortab[index]);
         } else if (colortab[index] != '') { // ignore the unused options
            strappend(not_colors, get_message(VSRC_FF_NOT)' 'colortab[index]);
         }
         flags2 = flags2 >> 1;
         ++index;
      }
      if (length(colors) < length(not_colors)) {
         strappend(summary, colors);
      } else {
         strappend(summary, not_colors);
      }
   }

   if (pos('+t', subdir_options)) {
      strappend(summary,'Subfolders, ');
   }
   if (mfflags & MFFIND_LOOKINZIPFILES) {
      strappend(summary,'Zip files, ');
   }
   if (mfflags & MFFIND_FILESONLY) {
      strappend(summary,'List filenames only, ');
   }

   if (disp_files :!= '') {
      strappend(summary,'"'disp_files'"');
      if (wildcards :!= '') {
         strappend(summary, ', "'wildcards'"');
         if (file_exclude :!= '') {
            strappend(summary,', Exclude: "'file_exclude'"');
         }
      }
      if (file_stats != '') {
         generate_mffile_file_stats_summary(summary, file_stats);
      }

   } else if (cur_file != '') {
      strappend(summary,'"'cur_file'"');
   } else {
      summary = strip(summary, 'T');
      summary = strip(summary, 'T', ",");
   }
   return summary;
}

static _str _grep_get_context_word(int context_type)
{
   switch (context_type) {
   case SE_TAG_TYPE_PROC:
   case SE_TAG_TYPE_FUNCTION:
   case SE_TAG_TYPE_CONSTRUCTOR:
   case SE_TAG_TYPE_DESTRUCTOR:
   case SE_TAG_TYPE_SELECTOR:
   case SE_TAG_TYPE_STATIC_SELECTOR:
   case SE_TAG_TYPE_SUBFUNC:
   case SE_TAG_TYPE_SUBPROC:
   case SE_TAG_TYPE_TASK:
   case SE_TAG_TYPE_TRIGGER:
   case SE_TAG_TYPE_OPERATOR:       return 'Function';

   case SE_TAG_TYPE_CLASS:          return 'Class';
   case SE_TAG_TYPE_INTERFACE:      return 'Interface';
   case SE_TAG_TYPE_STRUCT:         return 'Struct';
   case SE_TAG_TYPE_TASK:           return 'Class';
   case SE_TAG_TYPE_UNION:          return 'Union';
   case SE_TAG_TYPE_ENUM:           return 'Enum';
   case SE_TAG_TYPE_PACKAGE:        return 'Package/Namespace';
   case SE_TAG_TYPE_PROGRAM:        return 'Program';
   case SE_TAG_TYPE_LIBRARY:        return 'Library';

   default:                         return 'Context';
   }
}

bool _grep_is_context_word(_str word)
{
   switch (word) {
   case 'function':
   case 'class':
   case 'interface':
   case 'struct':
   case 'class':
   case 'union':
   case 'enum':
   case 'package/namespace':
   case 'program':
   case 'library':
   case 'context':
      return true;
   default:
      return false;
   }
   return false;
}

int parse_line(_str &filename, int &linenum, int &col)
{
   _str line, rest, colstr;
   save_pos(auto p);
   // handle prefix/suffix/continuation lines
   prefix_re := "(([ ]#(|[+-]))|":+def_search_result_separator_char:+"#)\\:";
   last_dir := 0;
   do {
      get_line(line);
      if (line :== "") return (STRING_NOT_FOUND_RC);
      if (!beginsWith(line, prefix_re, false, 'R')) {
         break;
      }

      prefix := strip(substr(line, 1, pos('')));
      dir := ((prefix :== '-:') ? 1 : -1);
      if ((dir > 0) && (last_dir >= 0)) {  // pre match line
         if (down()) {
            break;
         }

      } else if ((dir < 0) && (last_dir <= 0)) {  // post match line | continuation | separator line
         if (up()) {
            break;
         }

      } else {
         restore_pos(p);
         return (1); // error, results buffer may be inconsistent
      }
      last_dir = dir;

   } while (true);

   parse line with line rest;

   // File c:\22.0.0\slickedit\macros\se\search\SearchResults.e
   if (lowcase(line) == 'file') {
      filename = rest;
      linenum = -1;
      restore_pos(p);
      return (0);
   }

   // Context: se/search::parse_line(_str &filename, int &linenum, int &col) : 660
   if (_grep_is_context_word(lowcase(line))) {
      n := pos('\: :n$', rest, 1, 'r'); 
      if (!n) {
         restore_pos(p);
         return (1);
      }
      parse substr(rest, n) with ':' line;
      if (!isinteger(line)) {
         restore_pos(p);
         return (1);
      }
      linenum = (int)line;
      col = 1;
      status := search('^ *file', '-@rih');
      get_line(filename);
      parse filename with . filename;
      restore_pos(p);
      return (0);
   }


   parse rest with colstr ':';
   if (!isinteger(line) || !isinteger(colstr)) {
      restore_pos(p);
      return (1);
   }
   linenum = (int)line;
   col = (int)colstr;
   status := search('^ *file', '-@rih');
   get_line(filename);
   parse filename with . filename;
   restore_pos(p);
   return (status);
}

namespace default;

_metadata enum_flags MFSearchInitFlags {
   MFSEARCH_INIT_HISTORY   = 0x1,
   MFSEARCH_INIT_CURWORD   = 0x2,
   MFSEARCH_INIT_SELECTION = 0x4,
   MFSEARCH_INIT_AUTO_ESCAPE_REGEX = 0x8
};

static _str _mffind_markid;
definit() 
{
   _mffind_markid = "";
}

static void _mffindUpdateLine() {
   wid := p_window_id;
   bufname := p_buf_name; linenum := p_line;
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_EDITOR && !i.p_IsMinimap && i.p_buf_name == bufname) {
         i.p_line = linenum;
         i._scroll_page('E');
      }
   }
}

static void _mffindSetMark(bool updateLine = true)
{
   _SetNextErrorMark(_mffind_markid);
   if (updateLine) {
      _mffindUpdateLine();
   }
}

void _SetNextErrorMark(_str &markid,bool reset=false)
{
   if (markid==null) markid='';
   // markid could be $errors.tmp, .process, or search tab output buffer
   if (markid=="") {
      markid=_alloc_selection('b');
      _select_type(markid,'A',0 /* don't adjust column for backward compatibility*/ );
   } else {
      if (_select_type(markid)!="") {
         save_pos(auto p);
         int orig_buf_id=p_buf_id;
         int status=_begin_select(markid);
         if (status) {
            clear_message();
         } else {
            _lineflags(0,CURLINEBITMAP_LF);
            p_buf_id=orig_buf_id;
            restore_pos(p);
         }
      }
   }
   _select_char(markid);
   _select_type(markid,'A',0 /* don't adjust column for backward compatibility*/ );
   _lineflags(CURLINEBITMAP_LF,CURLINEBITMAP_LF);
   linenum := p_line;
   col:=p_col;
   if (_isGrepBuffer(p_buf_name)) {
      parse p_buf_name with '.search' auto grep_id;
      if (grep_id != '' && isnumber(grep_id)) {
         int wid = se.search._get_grep_buffer_view((int)grep_id);
         if (wid) {
            wid.p_scroll_left_edge=-1;
         }
      }
   } else if (beginsWith(p_buf_name,'.process') || _process_info('b')) {
      if (p_buf_name=='.process') {
         int wid=_find_object('_tbshell_form._shellEditor');
         if (wid) {
            if (!reset || !wid._process_info('c')) {
               if (wid._process_info('c')) {
                  wid.p_col=wid._process_info('c');
               } else {
                  wid.p_col=1;
               }
               wid.p_line=linenum;
            }
            wid.p_scroll_left_edge=-1;
         }
      }
   }
}

bool _mfrefActive(int srcbit /*1-search 2-compile */)
{
   if (!_haveContextTagging()) {
      return false;
   }
   if (!(def_mfflags & srcbit)) {
      return(false);
   }
   return(_mfrefIsActive);
}

void _mfrefNoMore(int srcbit /*1-search 2-compile */)
{
   if (_mfrefIsActive) {
      set_find_next_msg('');
   }
   _mfrefIsActive=false;
}



/*
    Forces _mffindActive to return false.
*/
void _mffindNoMore(int srcbit /*1-search 2-compile */)
{
   _mfXMLOutputIsActive = false;
   if (!(def_mfflags & srcbit)) {
      return;
   }
   if (_mffind_markid=="") return;
   if (_select_type(_mffind_markid)!="") {
      orig_view_id := 0;
      get_window_id(orig_view_id);
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();

      start_col := 0;
      end_col := 0;
      grep_buf_id := 0;
      _get_selinfo(start_col,end_col,grep_buf_id,_mffind_markid);
      p_buf_id=grep_buf_id;
      _begin_select(_mffind_markid);
      _lineflags(0,CURLINEBITMAP_LF);
      _deselect(_mffind_markid);
      activate_window(orig_view_id);
      _safe_hidden_window();
      set_find_next_msg('');
   }
}
/*
    Returns true if _mffindNext/Prev function can traverse
    the multi-file find messages.
*/
bool _mffindActive(int srcbit /*1-search 2-compile */)
{
   if (!(def_mfflags & srcbit)) {
      return(false);
   }
   if (_mffind_markid=="") return(false);
   if (_select_type(_mffind_markid)=="") {
      return(false);
   }
   return(true);
}

int _mffindPrev()
{
   return(_mffindNext(-1));
}

int _mffindNext(int doPrev=0, bool checkFileLine=false)
{
   if (_mffind_markid=="" || _select_type(_mffind_markid)=="") {
      return(STRING_NOT_FOUND_RC);
   }

   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   _begin_select(_mffind_markid);

   // force one line of context to be visible above and below the selected
   // line in the search results tool window.  This helps force the last file
   // with the summary of search results to be visible when you reach the
   // end of the search results, and forces the first file name back into view 
   // when going backwards. 
   old_scroll_style := _scroll_style();
   scroll_when := doPrev? 2:1;
   if (old_scroll_style != "") {
      _scroll_style(_first_char(old_scroll_style):+" ":+scroll_when);
   } else {
      _scroll_style("v ":+scroll_when);
   }

   // if there are two consecutive lines beginning with 'file'
   // then the output has been truncated, and the file should
   // be opened
   line := "";
   rest := "";
   typeless status=0;
   get_line(line);
   parse line with line rest;
   lineIsFile := doPrev ? (lowcase(line)=='file') : checkFileLine;
   lineIsNumber := false;
   lastFileLine := -1;
   do {
      if (lineIsFile) {
         lastFileLine = p_line;
      }
      if (doPrev) {
         status = up();
      } else {
         status = down();
      }
      if (status) break;
      get_line(line);
      parse line with line rest;
      lineIsFile = (lowcase(line)=='file');
      lineIsNumber = (!lineIsFile && isnumber(line));
      if (lineIsNumber) {
         break; // found line number
      }
      if (lineIsFile && (lastFileLine > 0)) {
         break; // have found two consecutive files
      }
   } while (true);

   if (!doPrev && (lineIsFile || status) && (lastFileLine > 0)) {
      p_line = lastFileLine;

   } else if (status) {
      _scroll_style(old_scroll_style);
      _safe_hidden_window();
      return(NO_MORE_FILES_RC);
   }

   filename := "";
   linenum := 0;
   col := 0;
   status=_mffindGetDest(filename,linenum,col);
   _scroll_style(old_scroll_style);
   _safe_hidden_window();
   if (status) return(status);
   return(_mffindGoTo(filename,linenum,col,false));
}

int _mffindCurrent()
{
   if (_mffind_markid=="" || _select_type(_mffind_markid)=="") {
      return(STRING_NOT_FOUND_RC);
   }
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   _begin_select(_mffind_markid);

   filename := "";
   linenum := 0;
   col := 0;
   int status=_mffindGetDest(filename,linenum,col);
   _safe_hidden_window();
   if (status) return(status);
   return(_mffindGoTo(filename,linenum,col));
}

int _mffindNextFile(int doPrev=0)
{
   if (_mffind_markid=="" || _select_type(_mffind_markid)=="") {
      return(STRING_NOT_FOUND_RC);
   }
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   _begin_select(_mffind_markid);

   get_line(auto line);
   parse line with line .;
   lineIsFile := lowcase(line) == 'file';
   if (!lineIsFile) {
      options := "@rih";
      if (doPrev) {
         strappend(options, "-");
         up(); _begin_line();
      } else {
         _end_line();
      }
      status := search("^ *file", options);
      if (!status) {
         _mffindSetMark(false);
      } else {
         _begin_select(_mffind_markid);
         _safe_hidden_window();
      }
      if (status) return(status);
   }
   return(_mffindNext(doPrev, !lineIsFile && !doPrev));
}

int _mffindGetDest(_str &filename,int &linenum,int &col,bool checkErrorFormatOnly=false)
{
   int status = se.search.parse_line(filename,linenum,col);
   if (!status) {
      if (!checkErrorFormatOnly) {
         _mffindSetMark();
      }
   }
   return status;
}

/*
     Use must call _mffindGetDest before calling this function.
*/
int _mffindGoTo(_str filename,int linenum,int pcol,bool maybePushBM=false, bool openNewWindow=false)
{
   if (filename=='') {
      return(FILE_NOT_FOUND_RC);
   }
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE;
   start_col := 0;
   end_col := 0;
   grep_buf_id := 0;
   int i;
   _get_selinfo(start_col,end_col,grep_buf_id,_mffind_markid);
   _begin_select(_mffind_markid);

   // 6.2.09 - sg
   // Push a bookmark here so that we can pop back.
   if (maybePushBM && !_no_child_windows() && def_search_result_push_bookmark && !openNewWindow) {
      _mdi.p_child.push_bookmark();
   }

   orig_buf_id := 0;
   orig_window_id := 0;
   if (!_no_child_windows()  && !openNewWindow && _mdi.p_child.pop_destination()) {
      orig_window_id = _mdi.p_child;
      orig_buf_id = _mdi.p_child.p_buf_id;
   }
   typeless buf_id=0;
   typeless status=0;
   typeless modify=0;
   typeless buf_flags=0;
   typeless buf_name='';
   if (_isno_name(filename)) {
      parse filename with '<' buf_id'>';
      get_window_id(auto wid);
      // Current editor control could be in a dialog. Try to choose it
      // if it's the current wid. This code can be removed if it causes
      // problems. It's not all the helpful.
      if (_isEditorCtl(false) && p_buf_id==buf_id && !p_IsTempEditor) {
         status=0;
      } else {
         // check if untitled buffer id exists and still untitled
         activate_window(VSWID_HIDDEN);
         _safe_hidden_window();
         status = load_files('+q +bi 'buf_id);
         if (!status) buf_name = p_buf_name;
         activate_window(wid);
         if (status || buf_name != '') {
            status = FILE_NOT_FOUND_RC;
         } else {
            bopts := openNewWindow ? '+i +bi ' : '+bi ';
            status = edit(bopts:+buf_id);
         }
      }
   } else {
      // To allow us to find buffer with invalid file names
      // look for the buffer first.
      parse buf_match(filename,1,'hvx') with buf_id modify buf_flags buf_name;
      if (buf_id != '') {
         get_window_id(auto wid);
         activate_window(VSWID_HIDDEN);
         _safe_hidden_window();
         status = load_files('+q +bi 'buf_id);
         activate_window(wid);
         if (!status) {
            bopts := openNewWindow ? '+i +bi ' : '+bi ';
            status = edit(bopts:+buf_id);
         }
      } else {
         typeless file_already_loaded = buf_match(filename,1,'hx')!='';
         isa_fso := (file_already_loaded || file_exists(filename));
         isa_dir := (!file_already_loaded && isa_fso && isdirectory(filename));
         if (!isa_fso || isa_dir) {
           status = FILE_NOT_FOUND_RC;
         } else {
            status = edit(_maybe_quote_filename(filename), EDIT_DEFAULT_FLAGS);
            if (!file_already_loaded && !status) {
               if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
                  _SetAllOldLineNumbers();
               }
            }
         }
      }
   }
   if (status) {
      message(get_message(status));
      return(status);
   }
   _str old_scroll_style=_scroll_style();
   _scroll_style('c');
   if (linenum>=0) {
      _GoToOldLineNumber(linenum);
      //p_line=linenum;
      _goto_physical_col(pcol);
      //p_col=_text_colc(pcol, 'I');
      if (select_active() && def_leave_selected) {
         _free_selection('');
      }
      if (_lineflags()& HIDDEN_LF) {
         expand_line_level();
      }
   }
   if (!openNewWindow) {
      _mdi.p_child.push_destination(orig_window_id, orig_buf_id);
   } else {
      _mdi.p_child.mark_open_destination();
   }
   _scroll_style(old_scroll_style);
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
   return(0);
}

/* 
   Duplicate Search Result buffer into current window id
*/
int _duplicate_grep_buffer()
{
   orig_wid := p_window_id;
   undo_steps := p_undo_steps;
   encoding := p_encoding;
   utf8 := p_UTF8;
   parse p_buf_name with '.search' auto grep_id;
   if (grep_id == '' || !isnumber(grep_id)) {
      return(1);
   }

   // copy stream markers???
   int type = _GetTextColorMarkerType();
   int list[];
   _StreamMarkerFindList(list, orig_wid, 0, p_buf_size, VSNULLSEEK, type);

   typeless mark = _alloc_selection();
   if (mark < 0) {
      return(1);
   }
   save_pos(auto p);
   top(); _select_line(mark);
   bottom(); _select_line(mark);
   restore_pos(p);

   orig_view_id := _create_temp_view(auto temp_view_id);
   if (orig_view_id == '') {
      _free_selection(mark);
      return(1);
   }
   _delete_line();
   buf_id := p_buf_id;
   grep_mode();
   p_encoding = encoding;
   p_UTF8 = utf8;
   status := _copy_to_cursor(mark);
   _free_selection(mark);

   _delete_window();  // delete temp window, not buffer
   activate_window(orig_wid);
   p_buf_id = buf_id;      // set orig window buffer to temp buffer
   p_DocumentName = '';
   p_buf_flags &= ~(VSBUFFLAG_HIDDEN|VSBUFFLAG_THROW_AWAY_CHANGES); // reset temp flags
   p_undo_steps = undo_steps; // reset undo

   save_pos(p);
   int i;
   VSSTREAMMARKERINFO info;
   for (i = 0; i < list._length(); ++i) {
      _StreamMarkerGet(list[i], info);
      _GoToROffset(info.StartOffset);
      _SetTextColor(info.ColorIndex, (int)info.Length, false);
   }
   restore_pos(p);
   return(0);
}

int promptSearchResultsId()
{
   last_grep_id := _get_last_grep_buffer();

   _str grep_ids[];
   int i;
   for (i = 0; i <= last_grep_id; ++i) {
      grep_ids[grep_ids._length()] = 'Search<'i'>';
   }
   grep_ids[grep_ids._length()] = '<New>';
   grep_ids[grep_ids._length()] = '<Auto Increment>';

   result := select_tree(grep_ids, null, null, null, null, null, null, "Select Search Result window");
   if (result == COMMAND_CANCELLED_RC || result == '') {
      return -1;
   }

   typeless grep_id;
   if (pos('new', result, 1, 'I')) {
      grep_id = add_new_grep_buffer();
   } else if (pos('auto increment', result, 1, 'I')) {
      grep_id = auto_increment_grep_buffer();
   } else {
      parse result with 'Search<' grep_id '>';
   }
   return (int)grep_id;
}
