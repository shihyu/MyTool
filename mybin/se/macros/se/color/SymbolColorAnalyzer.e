////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49613 $
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
#require "sc/lang/IAssignTo.e"
#require "se/tags/SymbolInfo.e"
#require "se/color/ColorInfo.e"
#require "se/color/SymbolColorRule.e"
#require "se/color/SymbolColorRuleBase.e"
#require "se/color/SymbolColorRuleIndex.e"
#require "se/color/SymbolColorConfig.e"
#require "se/color/SymbolColorDoubleBuffer.e"
#require "se/color/IColorCollection.e"
#require "se/color/LineNumberRanges.e"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/SymbolTable.e"
#import "se/tags/TaggingGuard.e"
#import "c.e"
#import "codehelp.e"
#import "context.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#endregion

using namespace se.lang.api;
using se.color.SymbolColorConfig;

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * The SymbolColorAnalyzer class is used to apply the symbol coloring 
 * rules from one color scheme to a single buffer.  It is designed to 
 * be a transient class instance, not something to ever be saved to the 
 * state file.  It's class instance should be saved in {@link p_buf_user} 
 * using {@link _SetBufferInfoHt()}. 
 */
class SymbolColorAnalyzer : sc.lang.IAssignTo {

   /**
    * This is the last state of p_modify for the last buffer colored.
    * If this does not match the current value for p_modify, we need
    * to recolor the symbols.
    */
   private typeless m_lastModified;
   /**
    * This is the last buffer (open file) which had symbol coloring.
    * If this does not match the current buffer, we need to recolor.
    */
   private int m_lastBufferId;
   /**
    * This class is used to keep track which lines are colored in the 
    * buffer and which ones are not already colored. 
    */
   private LineNumberRanges m_coloredLines;

   /**
    * Stream marker type allocated for this class instance 
    */
   private int m_streamMarkerType;

   /**
    * This is the number of segments we have colored so far. 
    * We need to wait the idle time duration for each segment, 
    * otherwise, the timer can pull down the machine too much. 
    */
   int m_numIterations;

   /**
    * This contains a pointer to the rule base index for this color 
    * analyzer.  The rule base index are allocated by that factory 
    * and reference counted. 
    */
   private SymbolColorRuleIndex *m_ruleIndex;

   /**
    * Indicates if symbol coloring is enabled or disabled for this file. 
    */
   private boolean m_isEnabled;

   /**
    * Indicates if highlighting of unidentified symbols is enabled or disabled 
    * for this file. 
    */
   private boolean m_isErrorsEnabled;

   /**
    * Double-buffering information
    */
   private SymbolColorDoubleBuffer m_doubleBuffer;

   /**
    * Construct a symbol color rule base.
    */
   SymbolColorAnalyzer(SymbolColorRuleBase ruleBase=null) {
      m_lastModified = null;
      m_lastBufferId = 0;
      m_coloredLines = null;
      m_streamMarkerType = 0;
      m_numIterations = 0;
      m_ruleIndex = null;
      m_isEnabled = true;
      m_isErrorsEnabled = false;
      m_doubleBuffer = null;
      if (ruleBase != null) {
         m_ruleIndex = SymbolColorRuleIndex.allocateRuleIndex(ruleBase);
      }
   }

   /**
    * Clean up resources used by this class instance.
    */
   ~SymbolColorAnalyzer() {
      if (m_streamMarkerType != 0) {
         _StreamMarkerRemoveAllType(m_streamMarkerType);
         _MarkerTypeFree(m_streamMarkerType);
      }
      m_lastModified = null;
      m_lastBufferId = 0;
      m_coloredLines = null;
      m_numIterations = 0;
      m_doubleBuffer = null;
      if (m_ruleIndex != null) {
         SymbolColorRuleIndex.freeRuleIndex(m_ruleIndex);
         m_ruleIndex = null;
      }
   }

   /**
    * Reinitialized the rule indexes which we built for faster rule matching.
    */
   void initAnalyzer(SymbolColorRuleBase *pRuleBase=null) {

      if (m_streamMarkerType != 0) {
         _StreamMarkerRemoveAllType(m_streamMarkerType);
      }

      m_lastModified = null;
      m_lastBufferId = 0;
      m_coloredLines = null;
      m_numIterations = 0;

      if (m_ruleIndex != null) {
         SymbolColorRuleIndex.freeRuleIndex(m_ruleIndex);
         m_ruleIndex = null;
      }

      if (pRuleBase==null) {
         pRuleBase = getRuleBase();
      }
      if (pRuleBase == null && 
          (def_symbol_color_scheme != null) &&
          (def_symbol_color_scheme instanceof se.color.SymbolColorRuleBase) &&
          (def_symbol_color_scheme.getNumRules() > 0)) {
         pRuleBase = &def_symbol_color_scheme;
      }

      m_isEnabled = false;
      if (pRuleBase != null) {
         m_ruleIndex = SymbolColorRuleIndex.allocateRuleIndex(*pRuleBase);
         m_isEnabled = true;
      }

      m_doubleBuffer = null;
      SymbolColorDoubleBuffer buff;
      m_doubleBuffer = buff;
   }

   /**
    * @return
    * Return 'true' if symbol coloring is enabled for this file.
    */
   boolean isSymbolColoringEnabled() {
      return m_isEnabled;
   }

   /**
    * Turn symbol coloring on or off for the current file.
    */
   void enableSymbolColoring(boolean onOff) {
      m_isEnabled = onOff;
   }

   /**
    * @return
    * Return 'true' if highlighting of unidentified symbols is enabled for this file.
    */
   boolean isErrorColoringEnabled() {
      return m_isErrorsEnabled;
   }

   /**
    * Turn highlighting of unidentified symbols on or off for the current file.
    */
   void enableErrorColoring(boolean onOff) {
      m_isErrorsEnabled = onOff;
   }

   /** 
    * @return 
    * Return a pointer to the rule base in use for this symbol color analyzer. 
    */
   se.color.SymbolColorRuleBase *getRuleBase() {
      if (m_ruleIndex == null) return null;
      if (m_ruleIndex->m_scheme == null) return null;
      return &(m_ruleIndex->m_scheme);
   }

   /**
    * Reset the symbol coloring that was calcuated for this buffer, 
    * forcing it to be re-calculated. 
    */
   void resetSymbolColoring() {
      if (m_streamMarkerType > 0) {
         m_coloredLines = null;
         m_numIterations=0;
         m_doubleBuffer.reset();
         _StreamMarkerRemoveAllType(m_streamMarkerType);
      }
   }

   /**
    * Reinitialize all the symbol color analyzers for different buffers 
    * if the current symbol coloring scheme changes. 
    */
   static void initAllSymbolAnalyzers(se.color.SymbolColorRuleBase *pRuleBase,
                                      boolean resetViewOptions=false) {
      if (_no_child_windows()) {
         return;
      }

      orig_wid := p_window_id;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      int orig_buf_id = p_buf_id;
      for (;;) {
         se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
         if (analyzer != null) {
            analyzer->resetSymbolColoring();
         }
         if (analyzer != null && pRuleBase != null) {
            analyzer->initAnalyzer(pRuleBase);
            if (resetViewOptions) {
               analyzer->enableErrorColoring(_QSymbolColoringErrors(true));
               analyzer->enableSymbolColoring(_QSymbolColoringEnabled(true));
            }
         }
         _next_buffer('hr');
         if (p_buf_id == orig_buf_id) {
            break;
         }
      }

      // that's all folks
      activate_window(orig_wid);
   }

   /**
    * Resets the last modified value, so that a reset is triggered.
    */
   void forceReset() {
      if (m_lastBufferId == p_buf_id) {
         m_lastModified = null;
      }
   }

   /**
    * Reset all the symbol color analyzers for different buffers
    * if the current tag file changes.
    */
   static void resetAllSymbolAnalyzers() {
      if (_no_child_windows()) {
         return;
      }

      orig_wid := p_window_id;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      int orig_buf_id = p_buf_id;
      for (;;) {
         se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
         if (analyzer != null) {
            analyzer->forceReset();
         }
         _next_buffer('hr');
         if (p_buf_id == orig_buf_id) {
            break;
         }
      }

      // that's all folks
      activate_window(orig_wid);
   }

   /**
    * Get the stream marker type.  Allocate one if we don't already 
    * have one.  
    */
   int getStreamMarkerType() {
      if (m_streamMarkerType == 0) {
         m_streamMarkerType = _MarkerTypeAlloc();
         _MarkerTypeSetPriority(m_streamMarkerType, 200);
      }
      return m_streamMarkerType;
   }

   /**
    * @return Return a pointer to the symbol coloring rule corresponding 
    * to the symbol currently under the cursor.  The current object must 
    * be an editor control. 
    */
   SymbolColorRule *getSymbolColorUnderCursor() 
   {
      //  make sure we have an active rules base
      rb := getRuleBase();
      if (rb == null) {
         return null;
      }
      // check for stream markers under the cursor
      // return the rule corresponding to any symbol coloring markers set
      _StreamMarkerFindList(auto markerIdList,p_window_id,_QROffset(),1,VSNULLSEEK,getStreamMarkerType());
      foreach (auto markerId in markerIdList) {
         _StreamMarkerGet(markerId, auto markerInfo);
         rule := rb->getRuleByName(markerInfo.msg);
         if (rule != null) return rule;
      }
      // no matches
      return null;
   }

   /** 
    * @return 
    * Return <code>true</code> if this line contains preprocessing, 
    *        or is a continuation of a preprocessing line, assuming
    *        the use of the C style continuation character (backslash).
    */
   static boolean isPreprocessingLine() {
      
      // check if the starts with a preprocessing character
      save_pos(auto pp_pos);
      first_non_blank();
      pp_cfg := _clex_find(0, 'g');
      if (pp_cfg == CFG_PPKEYWORD) {
         restore_pos(pp_pos);
         return true;
      }

      // move up one line and check for a continuation 
      while ( !up() ) {
      
         // continuation character has to be at the very end of line
         _end_line();left();
         if ( get_text() != "\\" ) {
            break;
         }
      
         // and it can not be in a string or comment, must be plain text
         pp_cfg = _clex_find(0, 'g');
         if (pp_cfg != CFG_WINDOW_TEXT) {
            break;
         }

         // now, check if the line starts with a preprocessing character
         first_non_blank();
         pp_cfg = _clex_find(0, 'g');
         if (pp_cfg == CFG_PPKEYWORD) {
            restore_pos(pp_pos);
            return true;
         }
      }

      // this is not a preprocesing line
      restore_pos(pp_pos);
      return false;
   }

   boolean needsReset()
   {
      // if we are looking at a different buffer, or it's modify state
      // has changed, then reset the start & end lines.
      return (m_lastBufferId != p_buf_id || m_lastModified != p_LastModified);
   }

   /**
    * Calculate what range of lines in the current file needs to be colored. 
    * Generally, the lines colored are only the visible lines on the screen, 
    * however, if a user pages up, we can potentially extend the symbol 
    * coloring region instead of starting over from scratch every time. 
    * <p> 
    * The current object must be an editor control. 
    *  
    * @param startLine  set to the first line (inclusive) to color 
    * @param endLine    set to the last line (inclusive) to color
    * @param doRefresh  set to true if we expect to need to do a 
    *                   screen refresh after recalculating the symbol
    *                   coloring information.
    * @param doOffScreen Set to true if the line range to is off-screen 
    * 
    * @return 'true' if we need to do symbol coloring, false if everything 
    *         is up to date. 
    */
   boolean determineLineRangeToColor(int &startLine, int &endLine, 
                                     boolean &doRefresh,
                                     boolean &doOffScreen)
   {
      // optimistic, hopefully we don't have to reset or refresh anything
      doRefresh = false;
      doOffScreen = false;

      // if we are looking at a different buffer, or it's modify state
      // has changed, then reset the start & end lines.
      if (needsReset()) {
         m_coloredLines = null;
         m_numIterations=0;
         m_doubleBuffer.reset();
         doRefresh = true;
      }

      // update the buffer id and last modified state
      m_lastBufferId = p_buf_id;
      m_lastModified = p_LastModified;

      // find the first and last visible lines on the screen
      save_pos(auto p);
      orig_cursor_y := p_cursor_y;
      // adjust screen position if we are scrolled
      if (p_scroll_left_edge >= 0) {
         _str line_pos,down_count,SoftWrapLineOffset;
         parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
         goto_point(line_pos);
         down((int)down_count);
         set_scroll_pos(p_scroll_left_edge,0,(int)SoftWrapLineOffset);
      }
      p_cursor_y=0;
      startLine = p_RLine;
      if (startLine > 1) --startLine;
      p_cursor_y=_ly2dy(p_xyscale_mode, p_height);
      endLine = p_RLine+1;
      p_cursor_y = orig_cursor_y;
      restore_pos(p);

      // check if we have colored as much as we can color 
      minLine := startLine - def_symbol_color_off_page_lines;
      maxLine :=   endLine + def_symbol_color_off_page_lines;
      if (minLine <= 0) minLine=1;
      if (m_coloredLines != null && m_coloredLines.containsRange(minLine, maxLine)) {
         return false;
      }

      // find the origin line (pivot point)
      origLine := p_RLine;
      if (origLine < minLine) origLine = minLine;
      if (origLine > maxLine) origLine = maxLine;

      // calculate what lines to color
      //("determineLineRangeToColor: startLine="startLine" endLine="endLine);
      if (m_coloredLines != null && m_coloredLines.containsRange(startLine, endLine)) {

         if (m_coloredLines.findNearestHole(origLine, minLine, maxLine, 
                                            auto nearestHoleStart=0, auto nearestHoleEnd=0,
                                            def_symbol_color_chunk_size)) {
            startLine = nearestHoleStart;
            endLine   = nearestHoleEnd;
            return true;
         }

         return false;

      } else {
         // just color the visible lines on the screen
         doRefresh=true;
      }

      // start and end are set, and we need to do some symbol coloring
      return true;
   }

   /**
    * Check if the cursor is positioned on the identifier part of a 
    * symbol declaration or definition in the current context or a local. 
    * <p> 
    * If it is, insert the symbol into the match set. 
    * 
    * @return 'true' if there is a match, 'false' otherwise
    */
   boolean findLocalOrContextDeclaration(int curOffset, se.tags.SymbolInfo &sym) 
   {
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // is it a local variable?
      localId := tag_current_local_name();
      if (localId > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, localId, auto typeName);
         switch (typeName) {
         case "import":
         case "friend":
         case "include":
         case "statement":
            break;
         default:
            sym.getMinimalLocalInfo(localId);
            return true;
         }
      }
      // current context?
      contextId := tag_current_context_name();
      if (contextId > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, contextId, auto typeName);
         switch (typeName) {
         case "import":
         case "friend":
         case "include":
         case "statement":
            break;
         default:
            sym.getMinimalContextInfo(contextId);
            return true;
         }
      }
      // no, this is not a declaration
      return false;
   }

   /**
    * Looks for commented or string regions and removes all symbol
    * coloring from them.
    */
   void resetInvalidRegions()
   {
      // save the current editor position and search expression
      save_pos(auto p);

      top();
      _begin_line();

      // check for comments, etc
      _StreamMarkerFindList(auto list, p_window_id, _QROffset(), MAXINT, VSNULLSEEK, getStreamMarkerType());
      foreach (auto markerId in list) {
         // get this marker
         _StreamMarkerGet(markerId, auto markerInfo);

         // go to the offset
         _GoToROffset(markerInfo.StartOffset);

         // see what we have here
         cfg := _clex_find(0, 'g');
         switch (cfg) {
         case CFG_STRING:
         case CFG_COMMENT:
         case CFG_SINGLEQUOTED_STRING:
         case CFG_BACKQUOTED_STRING:
         case CFG_UNTERMINATED_STRING:
         case CFG_INACTIVE_CODE:
         case CFG_INACTIVE_KEYWORD:
         case CFG_INACTIVE_COMMENT:
            _StreamMarkerRemove(markerId);
            break;
         }
      }

      restore_pos(p);
      refresh();
   }

   /**
    * Color the lines between the given start and end lines.
    * Assumes that the current control is an editor control.
    *
    * @param startLine  starting line number
    * @param endLine    ending line number
    */
   void colorLines(int startLine=0, int endLine=0)
   {
      status := 0;
      while (!status) {
         // find out if we were mid-process before
         m_doubleBuffer.getState(auto stage, auto stateInfo);
         switch (stage) {
         case DBS_GET_SYMBOLS:
         default:
            status = getSymbolsStep(startLine, endLine, stateInfo);
            if (!status) m_doubleBuffer.saveState(DBS_MATCH_COLORS, -1);
            break;
         case DBS_MATCH_COLORS:
            status = matchColorsStep((int)stateInfo);
            if (!status) m_doubleBuffer.saveState(DBS_DO_COLOR, -1);
            break;
         case DBS_DO_COLOR:
            status = colorLinesStep((int)stateInfo);
            if (!status) m_doubleBuffer.saveState(DBS_DO_MARKERS, -1);
            break;
         case DBS_DO_MARKERS:
            status = createMarkersStep(m_numIterations==0);
            if (!status) {
               // update the start and end line range which we have covered
               m_numIterations++;
               if (m_coloredLines == null) {
                  LineNumberRanges emptySet;
                  m_coloredLines = emptySet;
               }
               m_coloredLines.addRange(startLine, endLine);

               m_doubleBuffer.reset();

               // we completed everything successfully, so let's quit
               status = 1;
            }
            break;
         }
      }


   }

   /**
    * First step in coloring lines - go through and get our
    * symbols.
    *
    * @param startLine
    * @param endLine
    * @param seekPos
    *
    * @return int
    */
   private int getSymbolsStep(int startLine=0, int endLine=0, long seekPos = -1)
   {
      // make sure we have a scheme set up and a rule index object
      if (m_ruleIndex == null) return 0;

      // Check if we have a fast c-language expression info callback
      fastExpressionInfoIndex := _FindLanguageCallbackIndex("vs%s_get_expression_info");
      if (!index_callable(fastExpressionInfoIndex)) {
         fastExpressionInfoIndex = 0;
      }

      // verify that we have the callbacks we will be needing
      langExpressionInfoIndex := 0;
      if (fastExpressionInfoIndex == 0) {
         langExpressionInfoIndex = _FindLanguageCallbackIndex("_%s_get_expression_info");
         if (langExpressionInfoIndex <= 0) {
            langExpressionInfoIndex = find_index("_do_default_get_expression_info", PROC_TYPE);
         }
         if (langExpressionInfoIndex <= 0 || !index_callable(langExpressionInfoIndex)) return 0;
      }

      // save the current editor position and search expression
      save_pos(auto p);
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

      // update the symbols in the current file
      _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);

      // jump to the first line to start coloring
      if (seekPos > 0) {
         _GoToROffset(seekPos);
      } else if (startLine > 0) {
         p_RLine = startLine;
         _begin_line();
      } else {
         top();
         _begin_line();
      }

      // Allocate a selection for searching top of file
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      if (mark_id<0) return 0;

      // create a selection of the first [default 4000] lines
      _select_line(mark_id);
      p_RLine = endLine;
      _select_line(mark_id);
      _show_selection(mark_id);
      _begin_select(mark_id);

      // symbol analysis result cache
      typeless visited = null;

      // error symbol to be used as a proxy when we can not find a symbol
      VS_TAG_IDEXP_INFO idexp_info;
      se.tags.SymbolInfo errorSym;
      errorSym.m_tagType = "UNKNOWN";

      // Search for identifiers and open and close braces
      // TBF:  searching for open and close braces is very C specific
      // we need a language specific symbol and block scope search
      // callback
      id_re := _clex_identifier_re();
      if (id_re==null || id_re=="") id_re=":v";

      scope := 0;
      status := search(id_re:+"|\\{|\\}","@rmXknscplvax");
      timeout := false;
      while (!status) {
         // past the designated end line?
         if (endLine > 0 && p_RLine > endLine) {
            break;
         }

         // keep track of how many characters were in the identifier.
         numChars := match_length();

         // handle symbols depending on their purpose
         switch (get_text()) {
         // starting a new block, so increase the symbol table scope level
         case "{":
            m_doubleBuffer.pushScope();
            break;
         // closing the current scope, decrease the scope level
         case "}":
            m_doubleBuffer.popScope();
            break;

         default:
            // check if we landed in embedded code, if so, skip it
            // we don't want to do this expensive work in embedded code
            if (p_EmbeddedLexerName != '') {
               break;
            }

            // check if this symbol is on a line containing preprocessing
            // note that this does not handle line continuations
            if (isPreprocessingLine()) {
               _end_line();
               p_col -= numChars;
               break;
            }

            // check if we had already colored this line
            if (m_coloredLines!=null && m_coloredLines.containsNumber(p_RLine)) {
               _end_line();
               p_col -= numChars;
               break;
            }

            // update local variables if we have moved to a new line
            _UpdateLocals(true);

            // check to see if we need to bail on this step, try again when
            // we have more time
            if (_CheckTimeout()) {
               m_doubleBuffer.saveState(DBS_GET_SYMBOLS, _QROffset());
               endLine = p_RLine;
               timeout = true;
               break;
            }

            // analyze the context this identifier was found in
            se.tags.SymbolInfo *psym = null;
            tag_idexp_info_init(idexp_info);

            if (_GetSymbolColoringOptions() & SYMBOL_COLOR_SIMPLISTIC_TAGGING) {
               idexp_info.lastid = cur_identifier(idexp_info.lastidstart_col);
               idexp_info.lastidstart_offset = (int)_QROffset();
               idexp_info.prefixexpstart_offset = idexp_info.lastidstart_offset;
               status = 0;
            } else if (fastExpressionInfoIndex != 0) {
               status = call_index(false, _QROffset(), idexp_info, fastExpressionInfoIndex);
            } else {
               status = call_index(false, idexp_info, visited, 0, langExpressionInfoIndex);
            }
            // did we find anything?
            if (status || idexp_info.lastid == null) {
               break;
            }

            m_doubleBuffer.addSymbol((int)_QROffset(), idexp_info, numChars);
         }

         // skip over the identifier
         p_col += numChars;

         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_GET_SYMBOLS, _QROffset());
            endLine = p_RLine;
            timeout = true;
            break;
         }

         // search for the next identifier
         status = search(id_re"|\\{|\\}","@mrXknscplvax");
      }

      // The selection can be freed because it is not the active selection.
      _show_selection(orig_mark_id);
      _free_selection(mark_id);

      // restore the editor position and search parameters
      restore_pos(p);
      restore_search(s1, s2, s3, s4, s5);

      return timeout ? 1 : 0;
   }

   /**
    * Second step of coloring lines.  Match colors to symbols.
    *
    * @param arrayIndex
    *
    * @return int
    */
   int matchColorsStep(int arrayIndex = -1)
   {
      // make sure we have a scheme set up and a rule index object
      if (m_ruleIndex == null) return 0;

      // we will also needs a find context tags callback
      langFindContextTagsIndex := _FindLanguageCallbackIndex("_%s_find_context_tags");
      if (langFindContextTagsIndex <= 0) {
         langFindContextTagsIndex = find_index("_do_default_find_context_tags", PROC_TYPE);
      }
      if (langFindContextTagsIndex <= 0 || !index_callable(langFindContextTagsIndex)) return 0;

      // If the langauge has no list-locals callback, then disable symbol
      // not found coloring, otherwise the whole screen turns to mush
      useSymbolNotFoundColoring := false;
      langListLocalsIndex := _FindLanguageCallbackIndex("%s_list_locals");
      if (langListLocalsIndex > 0) {
         useSymbolNotFoundColoring = _QSymbolColoringErrors();
      }

      // save the current editor position and search expression
      save_pos(auto p);

      // update the symbols in the current file
      _UpdateContext(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);

      // If strict symbol matching is disabled for this language,
      // turn on the "lenient" flag.
      symbolColoringOptions := _GetSymbolColoringOptions();
      strictFlag := 0;
      if (symbolColoringOptions & SYMBOL_COLOR_NO_STRICT_TAGGING) {
         strictFlag = VS_TAGCONTEXT_FIND_lenient;
      }

      // symbol analysis result cache
      tag_files := tags_filenamea();
      typeless visited = null;
      SymbolTable st;

      // error symbol to be used as a proxy when we can not find a symbol
      se.tags.SymbolInfo errorSym;
      errorSym.m_tagType = "UNKNOWN";

      timeout := false;
      numSymbols := m_doubleBuffer.getNumSymbols();
      VS_TAG_IDEXP_INFO * idexp_info;

      if (arrayIndex < 0) arrayIndex = 0;
      for (j := arrayIndex; j < numSymbols; j++) {

         // get the next symbol
         idexp_info = m_doubleBuffer.getSymbol(j);

         // go to the symbol's location
         _GoToROffset(m_doubleBuffer.getOffset(j));

         // determine if we need to change the scope
         scopeChange := m_doubleBuffer.getScopeChange(j);
         if (scopeChange < 0) {
            st.popScope();
         } else if (scopeChange > 0) {
            st.pushScope();
         }

         // update local variables if we have moved to a new line
         _UpdateLocals(true);
         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
            timeout = true;
            break;
         }

         // check if the identifier under the cursor is part of a symbol
         // declaration or definition
         se.tags.SymbolInfo *psym = null;
         se.tags.SymbolInfo name_sym;
         if (findLocalOrContextDeclaration((int)_QROffset(), name_sym)) {
            psym = &name_sym;
            st.addSymbol(idexp_info -> prefixexp :+ idexp_info -> lastid, name_sym);
            m_doubleBuffer.setSymbolDeclaration(j, true);
         }

         // try to look up the symbol in the symbol table [cache]
         if (psym == null) {
            psym = st.lookup(idexp_info -> prefixexp :+ idexp_info -> lastid);
         }

         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
            timeout = true;
            break;
         }

         SymbolColorRule *ruleInfoP = null;
         if (psym != null) {
            ruleInfoP = m_ruleIndex->m_scheme.matchRules(*psym, m_ruleIndex->m_rulesByType);
         } else {

            // do not do expensive lookups on symbols already colored
            // by syntax color coding
            cfg := _clex_find(0, 'g');
            if (cfg!=CFG_KEYWORD && cfg!=CFG_PUNCTUATION && cfg!=CFG_LIBRARY_SYMBOL &&
                cfg!=CFG_OPERATOR && cfg!=CFG_USER_DEFINED) {

               // otherwie, we need to do a tagging search to find the symbol
               tag_push_matches();

               _str errorArgs[];
               num_matches := 0;
               status := 0;
               if (symbolColoringOptions & SYMBOL_COLOR_SIMPLISTIC_TAGGING) {
                  status = tag_list_any_symbols(0, 0,
                                                idexp_info->lastid,
                                                tag_files,
                                                VS_TAGFILTER_ANYTHING,
                                                VS_TAGCONTEXT_ALLOW_locals,
                                                num_matches, 10,
                                                true, p_LangCaseSensitive);
               } else {
                  status = call_index(errorArgs,
                                      idexp_info->prefixexp,
                                      idexp_info->lastid,
                                      idexp_info->lastidstart_offset,
                                      idexp_info->info_flags,
                                      idexp_info->otherinfo,
                                      false, 10,
                                      true, p_LangCaseSensitive,
                                      VS_TAGFILTER_ANYTHING,
                                      VS_TAGCONTEXT_ALLOW_locals|strictFlag,
                                      visited, 0,
                                      langFindContextTagsIndex);
               }

               if (_CheckTimeout()) {
                  m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
                  timeout = true;
                  break;
               }

               // did not find the symbol, then use the surrogate error symbol
               if (status < 0 && status!=VSCODEHELPRC_BUILTIN_TYPE) {

                  tag_pop_matches();
                  //say("colorLines: no match, p_line="p_line" tag="idexp_info.lastid" status="status);
                  if ( useSymbolNotFoundColoring && !_CheckTimeout() ) {
                     psym = &errorSym;
                     errorSym.m_name = idexp_info -> lastid;
                     st.addSymbol(idexp_info -> prefixexp :+ idexp_info -> lastid, errorSym);
                     ruleInfoP = m_ruleIndex->m_scheme.matchRules(*psym, m_ruleIndex->m_rulesByType);
                  }
               } else {

                  // analyze the symbol matches we found
                  num_matches = tag_get_num_of_matches();

                  // loop through the symbol matches, computing the color rule
                  // mappings and taking votes on which one was most popular.
                  int votes:[];
                  typeless rules:[];
                  typeless symbols:[];
                  for (i:=1; i<=num_matches; ++i) {
                     se.tags.SymbolInfo sym;
                     sym.getMinimalMatchInfo(i);
                     ruleInfoP = m_ruleIndex->m_scheme.matchRules(sym, m_ruleIndex->m_rulesByType);
                     if (ruleInfoP != null && ruleInfoP->m_colorInfo != null) {
                        if (votes._indexin(ruleInfoP->m_ruleName)) {
                           votes:[ruleInfoP->m_ruleName]++;
                        } else {
                           votes:[ruleInfoP->m_ruleName]=1;
                           rules:[ruleInfoP->m_ruleName] = ruleInfoP;
                           symbols:[ruleInfoP->m_ruleName] = sym;
                        }
                     }
                  }

                  // select the most popular symbol coloring rule
                  mostVotedRule := "";
                  mostVotes := 0;
                  foreach (auto ruleName => auto tally in votes) {
                     if (tally > mostVotes) {
                        mostVotedRule = ruleName;
                        mostVotes = tally;
                     }
                  }

                  // possibly add this symbol to the symbol table, or replace
                  // the previous definition of this symbol.
                  if (mostVotedRule != "") {
                     ruleInfoP = rules:[mostVotedRule];
                     st.addSymbol(idexp_info -> prefixexp :+ idexp_info -> lastid, symbols:[mostVotedRule]);
                  }

                  // clean up match set
                  tag_pop_matches();
               }
            }
         }

         if (ruleInfoP != null) {
            m_doubleBuffer.setSymbolColorRule(j, *ruleInfoP);
         }

         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_MATCH_COLORS, j++);
            timeout = true;
            break;
         }
      }

      // restore the editor position and search parameters
      restore_pos(p);

      return timeout ? 1 : 0;
   }

   /**
    * Third step of coloring lines - color the lines!
    *
    * @param arrayIndex
    * @param reset
    *
    * @return int
    */
   int colorLinesStep(int arrayIndex = -1)
   {
      // make sure we have a scheme set up and a rule index object
      if (m_ruleIndex == null) return 0;

      // save the current editor position and search expression
      save_pos(auto p);

      // calculate additional font flags for symbol definitions
      definitionFontFlags := 0;
      symbolColoringOptions := _GetSymbolColoringOptions();
      if (symbolColoringOptions & SYMBOL_COLOR_BOLD_DEFINITIONS) {
         definitionFontFlags = F_BOLD;
      // DJB 01-27-2012 -- these options are not supported
      //} else if (symbolColoringOptions & SYMBOL_COLOR_UNDERLINE_DEFINITIONS) {
      //   definitionFontFlags = F_UNDERLINE;
      //} else if (symbolColoringOptions & SYMBOL_COLOR_ITALIC_DEFINITIONS) {
      //   definitionFontFlags = F_ITALIC;
      }

      // get the font flags for CFG_FUNCTION
      ColorInfo cfgFunction;
      cfgFunction.getColor(CFG_FUNCTION);
      functionFontFlags := cfgFunction.getFontFlags();

      timeout := false;
      numSymbols := m_doubleBuffer.getNumSymbols();
      VS_TAG_IDEXP_INFO * idexp_info;

      if (arrayIndex < 0) arrayIndex = 0;
      for (j := arrayIndex; j < numSymbols; j++) {

         // get the next symbol
         idexp_info = m_doubleBuffer.getSymbol(j);

         // go to the symbol's location
         _GoToROffset(m_doubleBuffer.getOffset(j));

         // get the info for this one
         int numChars = m_doubleBuffer.getSymbolLength(j);
         SymbolColorRule * ruleInfoP = m_doubleBuffer.getSymbolColorRule(j);

         // color the symbol with the color that matched from the rule base
         if (ruleInfoP != null/* && psym != null*/) {

            // determine the color ID for this rule
            colorId := m_ruleIndex->getColorId(*ruleInfoP);
            if ( definitionFontFlags && m_doubleBuffer.isSymbolDeclaration(j)) {
               colorId = m_ruleIndex->getStyledColorId(*ruleInfoP, definitionFontFlags);
            } else if ( ( _clex_find(0, 'g') == CFG_FUNCTION) && (functionFontFlags & (F_BOLD|F_ITALIC|F_UNDERLINE)) ) {
               colorId = m_ruleIndex->getStyledColorId(*ruleInfoP, functionFontFlags);
            }

            // mark the symbol as colored
            description := "Symbol Color: ":+ruleInfoP->m_ruleName;
            m_doubleBuffer.markSymbolColored(j, colorId, description);

         } else {
            // do not color symbols who do not match any symbol coloring rule
            //say("colorLines: no color rule matches");
         }

         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_DO_COLOR, j++);
            timeout = true;
            break;
         }
      }

      // restore the editor position and search parameters
      restore_pos(p);

      return timeout ? 1 : 0;
   }

   /**
    * Fourth step of coloring lines - create symbol markers 
    * This step does not have the luxury of timing out. 
    *
    * @param arrayIndex
    * @param reset
    *
    * @return int
    */
   int createMarkersStep(boolean reset=false)
   {
      // reset the stream markers?
      markerType := getStreamMarkerType();
      if (reset) {
         _StreamMarkerRemoveAllType(markerType);
      }

      // add the new markers
      numSymbols := m_doubleBuffer.getNumSymbols();
      for (j := 0; j <= numSymbols; j++) {
         m_doubleBuffer.createStreamMarker(j, markerType);
      }

      // that's all folks
      return 0;
   }


   ////////////////////////////////////////////////////////////////////////
   // interface IAssignTo
   ////////////////////////////////////////////////////////////////////////

   /** 
    * Copy this object to the given destination.  The destination 
    * class will always be a valid and initialized class instance. 
    * 
    * @param dest   Destination object, expected to be 
    *               the same type as this class.
    */
   void copy(sc.lang.IAssignTo &dest) {
      if (dest instanceof se.color.SymbolColorAnalyzer) {
         SymbolColorAnalyzer *pdest = (typeless*) &dest;
         pdest->m_lastBufferId = this.m_lastBufferId;
         pdest->m_lastModified = this.m_lastModified;
         pdest->m_streamMarkerType = 0;
         pdest->m_numIterations = this.m_numIterations;
         pdest->m_isEnabled = this.m_isEnabled;
         pdest->m_isErrorsEnabled = this.m_isErrorsEnabled;
         if (pdest->m_ruleIndex != m_ruleIndex) {
            if (pdest->m_ruleIndex != null) {
               SymbolColorRuleIndex.freeRuleIndex(pdest->m_ruleIndex);
               pdest->m_ruleIndex = null;
            }
            if (m_ruleIndex != null && m_ruleIndex->m_scheme != null) {
               pdest->m_ruleIndex = SymbolColorRuleIndex.allocateRuleIndex(m_ruleIndex->m_scheme);
            }
         }
      } else {
         dest = null;
      }
   }

};


////////////////////////////////////////////////////////////////////////
// Global utility functions for updating symbol coloring
////////////////////////////////////////////////////////////////////////

namespace default;

/**
 * Symbol coloring options flags.  This is a bitset, however, under 
 * the current implementation, BOLD, UNDERLINE, STRIKE_THRU, and 
 * ITALIC are mutually exclusive. 
 */
enum_flags SYMBOL_COLOR_OPTIONS {
   SYMBOL_COLOR_BOLD_DEFINITIONS = F_BOLD,
   SYMBOL_COLOR_UNDERLINE_DEFINITIONS = F_UNDERLINE,
   SYMBOL_COLOR_ITALIC_DEFINITIONS = F_ITALIC,
   SYMBOL_COLOR_SHOW_NO_ERRORS,
   SYMBOL_COLOR_NO_STRICT_TAGGING,
   SYMBOL_COLOR_DISABLED,
   SYMBOL_COLOR_SIMPLISTIC_TAGGING,
};

/** 
 * Number of milliseconds of idle time to wait before updating 
 * the symbol coloring for the current file.
 * 
 * @default 500 ms (1/2 second)
 * @categories Configuration_Variables
 */
int def_symbol_color_delay = 500;

/** 
 * Number of milliseconds of time to allow symbol coloring to spend 
 * during each pass.  If this isn't enough time, the screen may 
 * be only partially painted. 
 * 
 * @default 1000 ms (1 second)
 * @categories Configuration_Variables
 */
int def_symbol_color_timeout = 1000;

/** 
 * Number of lines to color above and below the current page when 
 * calculating symbol coloring.  The lines on the current page are 
 * calculated first, then the off-page lines are calculated on 
 * subsequent passes.  This makes it possible for symbol coloring 
 * to already be up-to-date and available immediately when you page 
 * up if there has been a sufficient amount of time for it to be 
 * pre-calculated. 
 *
 * @default 100 lines
 * @categories Configuration_Variables
 */
int def_symbol_color_off_page_lines = 100;

/** 
 * Number of lines to color per pass when calculating symbol coloring 
 * for off-page lines.  By breaking the symbol coloring work into passes, 
 * each one doing a small chunk of lines, we are able to guard against 
 * symbol coloring monopolizing the CPU and provide more consistent smooth 
 * performance. 
 *
 * @default 20 lines
 * @categories Configuration_Variables
 */
int def_symbol_color_chunk_size = 20;

/**
 * Gets/sets the symbol coloring options which are a bitset of
 * <code>SYMBOL_COLOR_*</code>.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use 
 * SYMBOL_COLOR_BOLD_DEFINITIONS as the default.
 *
 * @param lang    language ID -- see {@link p_LangId} 
 * @param value   the value you wish to set the symbol coloring options.  Use 
 *                null to retrieve the current options.
 *
 * @return bitset of SYMBOL_COLOR_* options.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 * 
 * @return 
 */
int _lang_symbol_coloring_options(_str langID, int value = null)
{
   if (value == null) {
      value = _GetSymbolColoringOptions(langID);
   } else {
      _SetSymbolColoringOptions(langID, value);
   }

   return value;
}

/**
 * @return  Return 'true' if symbol coloring is supported for 
 *          the given language.   
 * 
 * @param lang    current language ID 
 *                (default={@link p_LangId})
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 * @since 14.0
 */
boolean _QSymbolColoringSupported(_str lang=null)
{
   // the current language has to support tagging
   if ( !_QTaggingSupported(p_window_id, lang) ) {
      return false;
   }

   // Do not support HTML, XML, TagDoc
   if ( _LanguageInheritsFrom("html", lang) ||
        _LanguageInheritsFrom("xml", lang) ||
        _LanguageInheritsFrom("tagdoc", lang) ||
        _LanguageInheritsFrom("xmldoc", lang) ) {
      return false;
   }

   return true;
}

/**
 * Get the symbol coloring options which are a bitset of
 * <code>SYMBOL_COLOR_*</code>.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use 
 * SYMBOL_COLOR_BOLD_DEFINITIONS as the default.
 *
 * @param lang    language ID -- see {@link p_LangId}
 *
 * @return bitset of SYMBOL_COLOR_* options.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
int _GetSymbolColoringOptions(_str lang='')
{
   if (lang == '') lang = p_LangId;
   return LanguageSettings.getSymbolColoringOptions(lang);
}
/**
 * Set the symbol coloring options which are a 
 * bitset of <code>SYMBOL_COLOR_*</code>.
 * <p>
 * The options are stored per extension type using
 * <code>def_symbolcoloring_[ext]</code>.
 *
 * @param lang    language ID -- see {@link p_LangId}
 * @param flags   bitset of SYMBOL_COLOR_* options
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
void _SetSymbolColoringOptions(_str lang, int flags)
{
   LanguageSettings.setSymbolColoringOptions(lang, flags);
}

void _MaybeResetSymbolColoring()
{
   // get the editor control window ID to update
   orig_wid := p_window_id;
   if (!_no_child_windows()) {
      p_window_id = _mdi.p_child;
   } else if (!_isEditorCtl()) {
      return;
   }

   if (p_ModifyFlags & MODIFYFLAG_SYMBOL_COLORING_RESET) {
      p_window_id = orig_wid;
      return;
   }
   p_ModifyFlags |= MODIFYFLAG_SYMBOL_COLORING_RESET;

   // check if symbol coloring is disabled or not supported for this language
   if (!_QSymbolColoringSupported() || !_QSymbolColoringEnabled()) {
      se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer != null) analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   // check if we already have an analyzer object for this buffer?
   se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(_QSymbolColoringErrors(true));
      _SetBufferInfoHt("SymbolColorAnalyzer", tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer == null) {
         p_window_id = orig_wid;
         return;
      }
      analyzer->initAnalyzer(null);
   }

   // make sure that this symbol analyzer actually does something
   if (analyzer->getRuleBase() == null || analyzer->getRuleBase()->getNumRules() <= 0) {
      analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   // no symbol coloring allowed in DiffZilla
   if ( _isdiffed(p_buf_id) ) {
      analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   if (analyzer->needsReset()) {
      analyzer->resetInvalidRegions();
   }
}

/**
 * Update the symbol coloring for the current buffer. 
 *  
 * @param force  -- force the symbol coloring to update now 
 */
void _UpdateSymbolColoring(boolean force=false)
{
   // reset invalid regions after 1/4 second delay
   idle := _idle_time_elapsed();
   if (force || idle > 250 || idle > def_symbol_color_delay) {
      _MaybeResetSymbolColoring();
   }

   // update symbol coloring only when the editor has been idle for a while
   if (!force && idle < def_symbol_color_delay) {
      return;
   }

   // get the editor control window ID to update
   orig_wid := p_window_id;
   if (!_no_child_windows()) {
      p_window_id = _mdi.p_child;
   } else if (!_isEditorCtl()) {
      return;
   }

   // check if symbol coloring is disabled or not supported for this language
   if (!_QSymbolColoringSupported() || !_QSymbolColoringEnabled()) {
      se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer != null) analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!force && !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) &&
       _idle_time_elapsed() < def_symbol_color_delay+def_update_tagging_extra_idle) {
      p_window_id = orig_wid;
      return;
   }

   // if there are already background tagging jobs in process, then
   // return immedately so as not to interfere
   if (tag_get_num_async_tagging_jobs() > 0) {
//    say("SymbolColorAnalyzer: other tagging jobs in process");
      return;
   }

   // check if we already have an analyzer object for this buffer?
   se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(_QSymbolColoringErrors(true));
      _SetBufferInfoHt("SymbolColorAnalyzer", tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer == null) {
         p_window_id = orig_wid;
         return;
      }
      analyzer->initAnalyzer(null);
   }

   // make sure that this symbol analyzer actually does something
   if (analyzer->getRuleBase() == null || analyzer->getRuleBase()->getNumRules() <= 0) {
      analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }
   
   // no symbol coloring allowed in DiffZilla
   if ( _isdiffed(p_buf_id) ) {
      analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   // set a one second timeout
   _SetTimeout(def_symbol_color_timeout);

   // keep track of the last state buffer updated, it's modify state,
   // and what lines we updated.
   save_pos(auto p);
   startLine := endLine := 0;
   doRefresh := offScreen := false;
   if (!analyzer->determineLineRangeToColor(startLine, endLine, doRefresh, offScreen)) {
      // do nothing, no coloring information to update at this time
      restore_pos(p);
      _SetTimeout(0);
      p_window_id = orig_wid;
      return;
   }

   // wait longer before doing off-screen lines, and do not do off-screen
   // lines if we are waiting on a keypress already
   if (offScreen && _idle_time_elapsed() < (def_symbol_color_delay*analyzer->m_numIterations)) {
      restore_pos(p);
      _SetTimeout(0);
      p_window_id = orig_wid;
      return;
   }

   // check if the tag database is busy and we can't get a lock.
   dbName := _GetWorkspaceTagsFilename();
   haveDBLock := tag_trylock_db(dbName);
   if (!force && !haveDBLock) {
      restore_pos(p);
      _SetTimeout(0);
      p_window_id = orig_wid;
      return;
   }

   // now color the lines
   //say("_UpdateSymbolColoring: start="startLine" end="endLine" reset="doReset" iterations="analyzer->m_numIterations);
   if (!haveDBLock) {
      if (tag_lock_db(dbName,def_symbol_color_timeout) < 0) {
         restore_pos(p);
         _SetTimeout(0);
         p_window_id = orig_wid;
         return;
      }
   }
   analyzer->colorLines(startLine,endLine);
   tag_unlock_db(dbName);
   restore_pos(p);

   // do a refresh, if necessary
   if (doRefresh) {
      refresh();
   }

   // and finally, restore the window ID
   _SetTimeout(0);
   p_window_id = orig_wid;
}

/**
 * Enable or disable the symbol coloring command for selecting a different 
 * symbol coloring scheme for the current document. 
 * 
 * @param cmdui 
 * @param target_wid 
 * @param command 
 * 
 * @return int 
 */
int _OnUpdate_symbol_coloring_set_scheme(CMDUI &cmdui,int target_wid,_str command)
{
   // not an editor control, then disable
   if ( !target_wid || !target_wid._isEditorCtl() || _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   // the current language has to support tagging
   if ( !target_wid._QSymbolColoringSupported() ) {
      return MF_GRAYED|MF_UNCHECKED;
   }

   // check if the main option is disabled
   checked := target_wid._QSymbolColoringEnabled()? MF_CHECKED:0;

   // check if the scheme name matches the current one in use
   // if so, add the check mark.
   isActiveScheme := false;
   parse command with . auto schemeName;
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer != null) {
      se.color.SymbolColorRuleBase *ruleBase = analyzer->getRuleBase();
      if (ruleBase != null && schemeName == ruleBase->m_name) {
         isActiveScheme = true;
      } else {
         checked = 0;
      }
   } else {
      if (def_symbol_color_scheme != null && 
          def_symbol_color_scheme.m_name != null &&
          def_symbol_color_scheme.m_name == schemeName) {
         isActiveScheme = true;
      }
   }

   if (cmdui.menu_handle) {
      _menu_get_state(cmdui.menu_handle, cmdui.menu_pos, auto mf_flags, 'p', auto caption);
      if (substr(caption, 1, 2) == "> ") {
         caption = substr(caption, 3);
      }
      active := (isActiveScheme && !target_wid._QSymbolColoringEnabled())? "> ":"";
      _menu_set_state(cmdui.menu_handle,
                      cmdui.menu_pos,
                      MF_ENABLED|checked,'p',
                      active :+ caption);
   }

   // it is running 
   return MF_ENABLED|checked;
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_set_scheme(_str name="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _SetSymbolColoringSchemeName(name,true);
}

/**
 * Cycle to the next symbol coloring scheme to be used with the current file. 
 *  
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_next_scheme() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _SetSymbolColorNextPrevScheme(true);
}
/**
 * Cycle to the previous symbol coloring scheme to be used with the current file. 
 *  
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_prev_scheme() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _SetSymbolColorNextPrevScheme(false);
}

void _SetSymbolColorNextPrevScheme(boolean doNext)
{
   schemeName := _GetSymbolColoringSchemeName();

   // look up all the available symbol coloring scheme names
   _str schemeNames[];
   _str compatibleWith[];
   SymbolColorConfig.getSchemeNamesOnly(schemeNames, compatibleWith, def_color_scheme);

   i:=0;
   for (i=0; i<schemeNames._length(); ++i) {
      if (schemeNames[i] == schemeName) {
         break;
      }
   }

   i = i + (doNext? 1:-1);
   if (i >= schemeNames._length()) i=0;
   if (i < 0) i = schemeNames._length()-1;

   if (schemeNames[i] == schemeName) {
      message("There is only one compatible scheme.");
      return;
   }
   message("Switching to '"schemeNames[i]"' symbol coloring scheme");
   _SetSymbolColoringSchemeName(schemeNames[i], true);
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void _SetSymbolColoringSchemeName(_str name="", boolean doUpdate=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return;
      target_wid = p_mdi_child;
   }

   // never enable symbol coloring for unsupported languages
   if ( !target_wid._QSymbolColoringSupported()) {
      return;
   }

   // if they don't specify a name, then use the default scheme
   se.color.SymbolColorRuleBase *rb = null;
   if (name == "") {
      if (def_symbol_color_scheme == null) return;
      name = def_symbol_color_scheme.m_name;
      rb = &(def_symbol_color_scheme);
   }

   // otherwise, look up the rule base
   se.color.SymbolColorConfig scc;
   if (rb == null) {
      scc.loadEmptyScheme();
      scc.loadSystemSchemes();
      scc.loadUserSchemes();
      scc.loadCurrentScheme();
      rb = scc.getScheme(name);
      if (rb == null) {
         // did not find scheme with that name
         return;
      }
   }

   // get the analyzer for the current buffer, create one if we don't have one
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt("SymbolColorAnalyzer", tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer == null) {
         return;
      }
   }

   // update the symbol coloring
   analyzer->enableSymbolColoring(true);
   analyzer->initAnalyzer(rb);
   if (doUpdate) {
      target_wid._UpdateSymbolColoring(true);
   }
}

/**
 * @return Return the name of the symbol coloring scheme active for the 
 *         current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
boolean _QSymbolColoringEnabled(boolean ignorePerFileOption=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return false;
      target_wid = p_mdi_child;
   }

   // always disabled if symbol coloring is not supported
   if (!target_wid._QSymbolColoringSupported()) {
      return false;
   }

   // get the analyzer for the current buffer
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer != null && !ignorePerFileOption) {
      return analyzer->isSymbolColoringEnabled();
   }

   // no rule base set for this file 
   return (target_wid._GetSymbolColoringOptions() & SYMBOL_COLOR_DISABLED) == 0;
}

/**
 * Enable or disable the symbol coloring command for selecting a different 
 * symbol coloring scheme for the current document. 
 * 
 * @param cmdui 
 * @param target_wid 
 * @param command 
 * 
 * @return int 
 */
int _OnUpdate_symbol_coloring_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   // not an editor control, then disable
   if ( !target_wid || !target_wid._isEditorCtl() || _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   if ( !target_wid._QSymbolColoringSupported()) {
      return MF_GRAYED|MF_UNCHECKED;
   }

   if (target_wid._QSymbolColoringEnabled()) {
      return(MF_ENABLED|MF_CHECKED);
   }

   return MF_ENABLED|MF_UNCHECKED;
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_toggle(_str onoff="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (onoff == "") {
      onoff = !_QSymbolColoringEnabled();
   }
   _SetSymbolColoringEnabled(onoff,true);
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
void _SetSymbolColoringEnabled(_str onoff="", boolean doUpdate=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return;
      target_wid = p_mdi_child;
   }

   // never enable symbol coloring for unsupported languages
   if ( !target_wid._QSymbolColoringSupported()) {
      return;
   }

   // get the analyzer for the current buffer, create one if we don't have one
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt("SymbolColorAnalyzer", tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer == null) {
         return;
      }
      analyzer->initAnalyzer();
   }

   // update the symbol coloring
   analyzer->enableSymbolColoring(onoff != "0");
   if (doUpdate) {
      target_wid._UpdateSymbolColoring(true);
   }
}

/**
 * @return Return the name of the symbol coloring scheme active for the 
 *         current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
boolean _QSymbolColoringErrors(boolean ignorePerFileOption=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return false;
      target_wid = p_mdi_child;
   }

   // always disabled if symbol coloring is not supported
   if (!target_wid._QSymbolColoringSupported()) {
      return false;
   }

   // get the analyzer for the current buffer
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer != null && !ignorePerFileOption) {
      return analyzer->isErrorColoringEnabled();
   }

   // no rule base set for this file 
   return (target_wid._GetSymbolColoringOptions() & SYMBOL_COLOR_SHOW_NO_ERRORS) == 0;
}

/**
 * Enable or disable the symbol coloring command for selecting a different 
 * symbol coloring scheme for the current document. 
 * 
 * @param cmdui 
 * @param target_wid 
 * @param command 
 * 
 * @return int 
 */
int _OnUpdate_symbol_coloring_errors_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   // not an editor control, then disable
   if ( !target_wid || !target_wid._isEditorCtl() || _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   if ( !target_wid._QSymbolColoringSupported()) {
      return MF_GRAYED|MF_UNCHECKED;
   }

   grayed  := target_wid._QSymbolColoringEnabled()? MF_ENABLED:MF_GRAYED;
   checked := target_wid._QSymbolColoringErrors()?  MF_CHECKED:MF_UNCHECKED;
   return MF_ENABLED|grayed|checked;
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_errors_toggle(_str onoff="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (onoff == "") {
      onoff = !_QSymbolColoringErrors();
   }
   _SetSymbolColoringErrors(onoff,true);
}

/**
 * Modify the symbol coloring scheme to be used with the current file. 
 *  
 * @param name    Symbol coloring scheme to switch to 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
void _SetSymbolColoringErrors(_str onoff="", boolean doUpdate=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return;
      target_wid = p_mdi_child;
   }

   // never enable symbol coloring for unsupported languages
   if ( !target_wid._QSymbolColoringSupported()) {
      return;
   }

   // get the analyzer for the current buffer, create one if we don't have one
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt("SymbolColorAnalyzer", tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer == null) {
         return;
      }
      analyzer->initAnalyzer();
   }

   // update the symbol coloring
   analyzer->enableErrorColoring(onoff != 0);
   if (onoff != 0) {
      analyzer->enableSymbolColoring(true);
   }
   if (doUpdate) {
      analyzer->resetSymbolColoring();
      target_wid._UpdateSymbolColoring(true);
   }
}

/**
 * @return Return the name of the symbol coloring scheme active for the 
 *         current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_str _GetSymbolColoringSchemeName()
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return "";
      target_wid = p_mdi_child;
   }

   // get the analyzer for the current buffer
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
   if (analyzer != null) {
      rb := analyzer->getRuleBase();
      return rb? rb->m_name : "";
   } else if (def_symbol_color_scheme != null) {
      return def_symbol_color_scheme.m_name;
   }

   // no rule base set for this file 
   return "";
}

/**
 * Initialize the symbol coloring submenu on the View menu.
 */
void _init_menu_symbol_coloring(int menu_handle, int no_child_windows)
{
   status := 0;
   viewMenuHandle := 0;
   symbolColoringMenuHandle := 0;
   itemPosition := 0;
   itemMenuHandle := 0;

   // make sure the submenu is there, insert it after softwrap if not
   if (_menu_find(menu_handle, "SymbolColorAnalyzer", symbolColoringMenuHandle, itemPosition, "C")) {
      if (_menu_find(menu_handle, "softwrap-toggle", viewMenuHandle, itemPosition, "M")) {
         return;
      }
      if (_menu_insert(viewMenuHandle,
                       itemPosition+1,
                       MF_SUBMENU,                       // flags
                       "Symbol Coloring",                // tool name
                       "",                               // command
                       "SymbolColorAnalyzer",            // category
                       "",                               // help command
                       "Select symbol coloring options"  // help message
                       ) < 0 ) {
         return;
      }
      if (_menu_find(menu_handle, "SymbolColorAnalyzer", symbolColoringMenuHandle, itemPosition, "C")) {
         return;
      }
   }

   // get the submenu handle for symbol coloring
   if (_menu_get_state(symbolColoringMenuHandle, itemPosition, 
                       auto mf_flags=0, "p", auto caption="",
                       auto subMenuHandle = 0, auto categories = "",
                       auto helpCommand = "", auto helpMessage = "")) {
      return;
   }

   // add the link to the Symbol Coloring options dialog
   if (_menu_find(subMenuHandle, "config Symbol Coloring", itemMenuHandle, itemPosition, "M")) {
      status = _menu_insert(subMenuHandle, 0, MF_ENABLED, "Customize...", 
                            "config Symbol Coloring", "", 
                            "help Symbol Coloring dialog", 
                            "Configure symbol coloring rules");
   }

   // add the link to turn on/off Symbol Coloring for the current file
   if (_menu_find(subMenuHandle, "symbol_coloring_toggle", itemMenuHandle, itemPosition, "M")) {
      status = _menu_insert(subMenuHandle, 1, MF_ENABLED, 
                            "Enable Symbol Coloring", 
                            "symbol_coloring_toggle", "", 
                            "help Symbol Coloring dialog", 
                            "Enable/disable symbol coloring for the current file");
   }

   // add the link to turn on/off Symbol Coloring for the current file
   if (_menu_find(subMenuHandle, "symbol_coloring_errors_toggle", itemMenuHandle, itemPosition, "M")) {
      status = _menu_insert(subMenuHandle, 2, MF_ENABLED, 
                            "Highlight Unidentified Symbols", 
                            "symbol_coloring_errors_toggle", "", 
                            "help Symbol Coloring dialog", 
                            "Enable/disable highlighting for symbols which are not found by Context Tagging"VSREGISTEREDTM);
   }

   if (_menu_find(subMenuHandle, "-", itemMenuHandle, itemPosition, "C")) {
      status = _menu_insert(subMenuHandle, 3, MF_ENABLED, "-", "", "-"); 
   }

   // get the current symbol coloring scheme name
   currentSchemeName := "";
   if (def_symbol_color_scheme != null) {
      currentSchemeName = def_symbol_color_scheme.m_name;
   }
   target_wid := p_window_id;
   if ( !_isEditorCtl() && !no_child_windows) {
      target_wid = p_mdi_child;
   }
   if (target_wid._isEditorCtl()) {
      se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer != null) {
         se.color.SymbolColorRuleBase *ruleBase = analyzer->getRuleBase();
         if (ruleBase != null) {
            currentSchemeName = ruleBase->m_name;
         }
      }
   }

   // look up all the available symbol coloring scheme names
   boolean foundSchemeNames:[];
   _str schemeNames[];
   _str compatibleWith[];
   SymbolColorConfig.getSchemeNamesOnly(schemeNames, compatibleWith, def_color_scheme);

   // and insert the compatible ones into the submenu
   i := 0; name := "";
   foreach (i => name in schemeNames) {
      checked := MF_UNCHECKED;
      if (name == currentSchemeName) {
         checked = MF_CHECKED;
      }
      foundSchemeNames:[name] = true;
      if (_menu_find(subMenuHandle, name, itemMenuHandle, itemPosition, "C")) {
         status = _menu_insert(subMenuHandle, _menu_info(subMenuHandle), 
                               checked, stranslate(name, "&&", "&"),
                               "symbol_coloring_set_scheme ":+name, name);
      } else {
         _menu_set_state(itemMenuHandle, name, checked, 'C');
      }
   }

   // delete the out-of-date scheme names
   for (itemPosition = _menu_info(subMenuHandle)-1; itemPosition >= 4; itemPosition--) {
      _menu_get_state(subMenuHandle, itemPosition, mf_flags, "p", caption,
                      auto dummyHandle = 0, categories, helpCommand, helpMessage);
      caption = stranslate(caption, "&",  "&&");
      if (substr(caption, 1, 2) == "> ") {
         caption = substr(caption, 3);
      }
      if (!foundSchemeNames._indexin(caption)) {
         _menu_delete(subMenuHandle, itemPosition);
         continue;
      }
   }
}
