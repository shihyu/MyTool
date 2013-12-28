////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49714 $
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
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "pushtag.e"
#import "search.e"
#import "sellist.e"
#import "seldisp.e"
#import "stdprocs.e"
#import "tbsearch.e"

int def_search_result_max_line_size = 500;
int def_search_result_truncate_cols = 30;

namespace se.search;

#define SEARCH_RESULT_TRUNCATE_LEADING_FLAG     0x1
#define SEARCH_RESULT_TRUNCATE_TRAILING_FLAG    0x2

class SearchResults {
   private _str m_last_file = '';
   private int m_last_line = -1;
   private int m_last_prefix_width = -1;
   private int m_top_line = 1;
   private int m_mfflags = 0;
   private int m_wid = 0;
   private int m_grepid = 0;

   void initialize(_str topline, _str search_text, int mfflags, int grep_id) {
      get_window_id(auto orig_view_id);
      set_grep_buffer(grep_id, search_text);
      results_id := _get_grep_buffer_view(grep_id);
      activate_window(results_id);
      grep_buf_id := p_buf_id;
      m_last_file = '';
      m_last_line = -1;
      m_last_prefix_width = -1;
      m_top_line = p_Noflines + 1;
      m_mfflags = mfflags;
      m_grepid = grep_id;
      get_window_id(m_wid);
      if (!(m_mfflags & MFFIND_APPEND)) {
         _lbclear(); p_col = 1;
         m_top_line = 1;
      }
      bottom();
      insert_line(topline);
      _lineflags(MINUSBITMAP_LF|0,MINUSBITMAP_LF|LEVEL_LF);
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
      bottom(); insert_line(results_text); _lineflags(0, LEVEL_LF|CURLINEBITMAP_LF);
      p_line = m_top_line; p_col = 1;
      p_undo_steps = _DefaultUndoSteps();
      activate_window(orig_view_id);
   }

   // truncate result for long lines
   static int getSearchResultLine(_str& line, int &col, int &match_len, int mfflags) {
      if (!_isEditorCtl()) {
         return 0;
      }
      status := 0;
      col = _text_colc(p_col, 'P');
      if (mfflags & MFFIND_MATCHONLY) {
         if ((def_search_result_max_line_size > 0) && (match_len > def_search_result_max_line_size)) {
            match_len = def_search_result_max_line_size;
            status |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
         }
         col = 1;
         line = get_text_raw(match_len);
         return status;
      }

      if ((def_search_result_max_line_size > 0) && (_line_length() > def_search_result_max_line_size)) {
         // truncated long match length
         if (match_len > def_search_result_max_line_size) {
            match_len = def_search_result_max_line_size;
            status |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
         }

         save_pos(auto p);
         linelen := match_len;
         if (!status && def_search_result_truncate_cols > 0) {
            // check trailing length
            if (_line_length() > p_col + match_len + def_search_result_truncate_cols) {
               orig_col := p_col;
               p_col += match_len + def_search_result_truncate_cols;
               if (p_UTF8 || _dbcs() || _text_colc(p_col, 'T') < 0) {
                  right(); left();
               }
               linelen = _text_colc(p_col, 'P') - col;
               status |= SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
               p_col = orig_col;

            } else {
               linelen = (_line_length() - col) + 1;
            }

            // check leading length
            if (p_col > def_search_result_truncate_cols) {
               p_col -= def_search_result_truncate_cols;
               if (p_UTF8 || _dbcs() || _text_colc(p_col, 'T') < 0) {
                  left(); right();
               }
               dl := col - _text_colc(p_col, 'P');
               col = dl + 1;
               linelen += dl;
               status |= SEARCH_RESULT_TRUNCATE_LEADING_FLAG;

            } else {
               linelen += _text_colc(p_col, 'P');
               _begin_line();
            }
         } else {
            col = 1;
         }

         line = get_text_raw(linelen);
         restore_pos(p);
         return status;
      }
      get_line_raw(line);
      return status;
   }
   
   void insertFileLine(_str filename) {
      if (!m_wid) {
         return;
      }
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom();
      insert_line('File 'filename);  
      _lineflags((m_mfflags & MFFIND_FILESONLY) ? NEXTLEVEL_LF : NEXTLEVEL_LF | MINUSBITMAP_LF,
                 (m_mfflags & MFFIND_FILESONLY) ? LEVEL_LF | CURLINEBITMAP_LF : LEVEL_LF | MINUSBITMAP_LF | CURLINEBITMAP_LF);   
      p_col = 1; _SetTextColor(CFG_FILENAME, _line_length(), false);
      m_last_file = filename;
      m_last_line = -1;
      activate_window(orig_view_id);
   }

   void insertLine(int pcol, int match_len, int linenum, int col, _str line, int truncated = 0) {
      if (!m_wid) {
         return;
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      get_window_id(auto orig_view_id);
      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      prefix := '  'linenum' 'col':';
      suffix := '';
      activate_window(m_wid);
      bottom();
      if (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
         prefix :+= '...';
      }
      if (truncated & SEARCH_RESULT_TRUNCATE_TRAILING_FLAG) {
         suffix = '... ';
      }
      if (truncated) {
         suffix :+= ' [line truncated]';
      }

      if (!truncated && (m_mfflags & MFFIND_SINGLELINE)) {
         if (m_last_line != linenum) {
            insert_line(prefix:+line:+suffix);
            _lineflags(next_level, LEVEL_LF);
            m_last_line = linenum;
            m_last_prefix_width = length(prefix);

         }
         pcol += m_last_prefix_width;

      } else {
         insert_line(prefix:+line:+suffix);
         _lineflags(next_level, LEVEL_LF);
         pcol += length(prefix);
      }

      if (match_len > 0) {
         p_col = _text_colc(pcol, 'I');
         _SetTextColor(CFG_HILIGHT, match_len, false);
      }
      if (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
         // highlight '...'
         p_col = _text_colc(length(prefix) - 2, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, 3, false);
      }
      if (truncated && suffix != '') {
         // highlight suffix '...  [line truncated]'
         p_col = _text_colc(length(prefix:+line) + 1, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, length(suffix), false);
      } 
      checkOutput();
      activate_window(orig_view_id);
   }

   void insertCurrentMatch() {
      if (!m_wid) {
         return;
      }
      buf_name := _build_buf_name();
      if (m_last_file != buf_name) {
         insertFileLine(buf_name);
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      linenum := p_RLine; col := p_col;
      utf8 := p_UTF8;
      match_len := match_length();
      truncated := getSearchResultLine(auto line, auto pcol, match_len, m_mfflags);
      if (!utf8) {
         line = convertToUTF8(line, pcol, match_len);
      }
      if (match_len < 0) match_len = 0;
      insertLine(pcol, match_len, linenum, col, line, truncated);
   }

   void insertCurrentReplace() {
      if (!m_wid) {
         return;
      }
      get_window_id(auto buf_view_id);
      buf_name := _build_buf_name();
      if (m_last_file != buf_name) {
         insertFileLine(buf_name);
      }
      if (m_mfflags & MFFIND_FILESONLY) {
         return;
      }
      next_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
      linenum := p_RLine; col := p_col;
      utf8 := p_UTF8;
      replace_width :=  match_length('R');
      truncated := getSearchResultLine(auto line, auto pcol, replace_width, m_mfflags);
      if (!utf8) {
         line = convertToUTF8(line, pcol, replace_width);
      }
      activate_window(m_wid);
      bottom();
      prefix := '  'linenum' 'col':';
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
      if (!truncated && (m_mfflags & MFFIND_SINGLELINE)) {
         if (m_last_line != linenum) {
            m_last_line = linenum;
            m_last_prefix_width = prefix_width;
            insert_line(prefix:+line:+suffix); 
            _lineflags(next_level, LEVEL_LF);
         } else {
            p_col = _text_colc(pcol + m_last_prefix_width, 'I');
            _delete_text(-1);
            _insert_text(substr(line, pcol));
            prefix_width = m_last_prefix_width;
            truncated = 0;
         }
      } else {
         insert_line(prefix:+line:+suffix); 
         _lineflags(next_level, LEVEL_LF);
      }
      pcol += prefix_width;
      if (replace_width > 0) {
         p_col = _text_colc(pcol, 'I');
         _SetTextColor(CFG_MODIFIED_LINE, replace_width, false);
      }
      if (truncated & SEARCH_RESULT_TRUNCATE_LEADING_FLAG) {
         // highlight '...'
         p_col = _text_colc(prefix_width - 2, 'I');
         _SetTextColor(CFG_SEARCH_RESULT_TRUNCATED, 3, false);
      }
      if (truncated && suffix != '') {
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
      get_window_id(auto orig_view_id);
      activate_window(m_wid);
      bottom(); insert_line(line);
      _lineflags(0, LEVEL_LF | CURLINEBITMAP_LF);
      activate_window(orig_view_id);
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
      if (p_buf_size > def_max_mffind_output) {
         if (def_max_mffind_output >= (2 * 1024 * 1024)) {
            insert_line('Output larger than '(int)(def_max_mffind_output/(1024*1024)):+'MB. Switching to files only mode.');
         } else {
            insert_line('Output larger than '(int)(def_max_mffind_output/1024):+'KB. Switching to files only mode.');
         }
         _lineflags(0, LEVEL_LF|CURLINEBITMAP_LF);
         m_mfflags |= MFFIND_FILESONLY;
      }
   }
   
   private _str convertToUTF8(_str origline, int& pcol, int& plen) {
      line := _MultiByteToUTF8(origline);
      leading := _MultiByteToUTF8(substr(origline, 1, pcol));
      matchword := _MultiByteToUTF8(substr(origline, pcol, plen));
      pcol = _strBeginChar(leading, length(leading));
      plen = length(matchword);
      return line;
   }
};

int _get_grep_buffer_view(int grep_id)
{
   if (grep_id < 0) {
      return 0;
   }
   _str grep_buffer_name;
   grep_buffer_name = '.search'grep_id;
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '', grep_buffer_name, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   p_UTF8 = true;
   activate_window(orig_wid);
   return temp_grep_view;
}

_str generate_search_summary(_str search_string, _str options, 
                             _str files, int mfflags,
                             _str wildcards, _str file_exclude,
                             _str replace_string='', _str cur_file='')
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

   search('', options);
   save_search(ts_search_string, ts_flags, ts_word_re, ts_reserved_more, ts_flags2);
   restore_search(ss_search_string, ss_flags, ss_word_re, ss_reserved_more, ss_flags2);
   _str subdir_options;
   _str disp_files = strip_options(files,subdir_options,true);
   _str up_options = upcase(options);
   _str summary = '';
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
   } else if (ts_flags & VSSEARCHFLAG_UNIXRE) {
      strappend(summary, 'Regular expression (UNIX), ');
   } else if (ts_flags & VSSEARCHFLAG_BRIEFRE) {
      strappend(summary, 'Regular expression (Brief), ');
   } else if (ts_flags & VSSEARCHFLAG_PERLRE) {
      strappend(summary, 'Regular expression (Perl), ');
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

      _str colors = '';
      _str not_colors = '';
      int index = 0;
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

   if (mfflags & MFFIND_FILESONLY) {
      strappend(summary,'List filenames only, ');
   }

   if (disp_files :!= '') {
      strappend(summary,'"'disp_files'", ');

      if (wildcards == '') {
         strappend(summary, '"*"');
      } else {
         strappend(summary, '"'wildcards'"');
      }
      if (file_exclude != '') {
         strappend(summary,', Exclude: "'file_exclude'"');
      }
   } else if (cur_file != '') {
      strappend(summary,'"'cur_file'"');
   } else {
      summary = strip(summary, 'T');
      summary = strip(summary, 'T', ",");
   }
   return summary;
}

int parse_line(_str &filename, int &linenum, int &col)
{
   _str line, rest, colstr;
   get_line(line);
   parse line with line rest;
   if (lowcase(line) == 'file') {
      filename = rest;
      linenum = -1;
      return (0);
   }
   parse rest with colstr ':';
   if (!isinteger(line) || !isinteger(colstr)) {
      return (1);
   }
   linenum = (int)line;
   col = (int)colstr;
   typeless p; save_pos(p);
   int status = search('^ *file', '-@rih');
   get_line(filename);
   parse filename with . filename;
   restore_pos(p);
   return (status);
}

namespace default;

static _str _mffind_markid;
definit() 
{
   _mffind_markid = "";
}

static void _mffindSetMark()
{
   _SetNextErrorMark(_mffind_markid);
}

void _SetNextErrorMark(_str &markid)
{
   // markid could be $errors.tmp, .process, or search tab output buffer
   if (markid=="") {
      markid=_alloc_selection('b');
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
   _lineflags(CURLINEBITMAP_LF,CURLINEBITMAP_LF);
   int linenum=p_line;
   if (_isGrepBuffer(p_buf_name)) {
      parse p_buf_name with '.search' auto grep_id;
      if (grep_id != '' && isnumber(grep_id)) {
         int wid = se.search._get_grep_buffer_view((int)grep_id);
         if (wid) {
            wid.p_scroll_left_edge=-1;
         }
      }
   } else if (p_buf_name=='.process' || _process_info('b')) {
      int wid=_find_object('_tbshell_form._shellEditor');
      if (wid) {
         wid.p_col=1;
         wid.p_line=linenum;
         wid.p_scroll_left_edge=-1;
      }
   }
}

boolean _mfrefActive(int srcbit /*1-search 2-compile */)
{
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
      int orig_view_id=0;
      get_window_id(orig_view_id);
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();

      int start_col=0;
      int end_col=0;
      int grep_buf_id=0;
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
boolean _mffindActive(int srcbit /*1-search 2-compile */)
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

int _mffindNext(int doPrev=0)
{
   if (_mffind_markid=="" || _select_type(_mffind_markid)=="") {
      return(STRING_NOT_FOUND_RC);
   }
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   _begin_select(_mffind_markid);
   // if there are two consecutive lines beginning with 'file'
   // then the output has been truncated, and the file should
   // be opened
   _str line='';
   _str rest='';
   typeless status=0;
   int lastFileLine=-1;
   boolean lineIsFile=false;
   do {
      if (lineIsFile) {
         lastFileLine=p_line;
      }
      if (doPrev) {
         status=up();
      } else {
         status=down();
      }
      get_line(line);
      parse line with line rest;
      lineIsFile=(lowcase(line)=='file');

   } while ((!status)&&                            // not the end of the file
            (!isnumber(line))&&                    // have not found a result
            ((!lineIsFile)||(lastFileLine<0)) );   // have not found two consecutive files

   if ((lastFileLine>0)&&           // found a file line
       (!isnumber(line))&&          // did not find a real result
       ((!doPrev)||(!status)) ) {   // but don't go up to the first file in the list
      p_line=lastFileLine;
   } else if (status) {
      _safe_hidden_window();
      return(NO_MORE_FILES_RC);
   }
   _str filename='';
   int linenum=0;
   int col=0;
   status=_mffindGetDest(filename,linenum,col);
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

   _str filename='';
   int linenum=0;
   int col=0;
   int status=_mffindGetDest(filename,linenum,col);
   _safe_hidden_window();
   if (status) return(status);
   return(_mffindGoTo(filename,linenum,col));
}

int _mffindGetDest(_str &filename,int &linenum,int &col,boolean checkErrorFormatOnly=false)
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
int _mffindGoTo(_str filename,int linenum,int col,boolean maybePushBM=false)
{
   if (filename=='') {
      return(FILE_NOT_FOUND_RC);
   }
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE;
   int start_col=0;
   int end_col=0;
   int grep_buf_id=0;
   int i;
   _get_selinfo(start_col,end_col,grep_buf_id,_mffind_markid);
   for (i=1;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && i.p_HasBuffer && i.p_buf_id==grep_buf_id) {
         i._begin_select(_mffind_markid);
      }
   }

   // 6.2.09 - sg
   // Push a bookmark here so that we can pop back.
   if (maybePushBM && !_no_child_windows() && def_search_result_push_bookmark) {
      _mdi.p_child.push_bookmark();
   }

   int orig_buf_id=0;
   int orig_window_id=0;
   if (!_no_child_windows() && _mdi.p_child.pop_destination()) {
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
      status=edit('+bi 'buf_id);
   } else {
      // To allow us to find buffer with invalid file names
      // look for the buffer first.
      parse buf_match(filename,1,'hvx') with buf_id modify buf_flags buf_name;
      if (buf_id!='') {
         status=edit('+bi 'buf_id);
      } else {
         typeless file_already_loaded=buf_match(filename,1,'hx')!='';
         status=edit(maybe_quote_filename(filename), EDIT_DEFAULT_FLAGS);
         if (!file_already_loaded && !status) {
            if (p_buf_size<VSMAX_SETOLDLINENUMS_BUF_SIZE) {
               _SetAllOldLineNumbers();
            }
         }
      }
   }
   if (status) return(status);
   _str old_scroll_style=_scroll_style();
   _scroll_style('c');
   if (linenum>=0) {
      _GoToOldLineNumber(linenum);
      //p_line=linenum;
      p_col=col;
      if (select_active() && def_leave_selected) {
         _free_selection('');
      }
      if (_lineflags()& HIDDEN_LF) {
         expand_line_level();
      }
   }
   _mdi.p_child.push_destination(orig_window_id, orig_buf_id);
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

