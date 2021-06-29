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
#require "se/color/LineNumberRanges.e"
#require "se/color/SymbolColorRuleIndex.e"
#require "se/color/SymbolColorDoubleBuffer.e"
#require "se/tags/SymbolTable.e"
#require "se/tags/SymbolInfo.e"
#import "se/color/ColorInfo.e"
#import "se/color/ColorScheme.e"
#import "se/color/SymbolColorRule.e"
#import "se/color/SymbolColorRuleBase.e"
#import "se/color/SymbolColorConfig.e"
#import "se/color/IColorCollection.e"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "c.e"
#import "cfg.e"
#import "codehelp.e"
#import "context.e"
#import "files.e"
#import "help.e"
#import "listproc.e"
#import "main.e"
#import "pushtag.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#endregion

using namespace se.lang.api;
using se.color.SymbolColorRuleBase;
using se.color.SymbolColorRuleIndex;
using se.tags.SymbolTable;
using se.color.ColorScheme;

/**
 * Prefix for the msg member of Stream Markers
 */
static const SM_DESC_PREFIX=     "Symbol Color: ";

/**
 * Key to look up in buffer info hash table for Symbol Coloring analyzer object.
 */
static const SM_BUFFER_INFO_KEY= "SymbolColorAnalyzer";

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
   private bool m_isEnabled;

   /**
    * Indicates if highlighting of unidentified symbols is enabled or disabled 
    * for this file. 
    */
   private bool m_isErrorsEnabled;

   /**
    * Double-buffering information
    */
   private SymbolColorDoubleBuffer m_doubleBuffer;

   /**
    * Symbol table for caching symbol lookups
    */
   private SymbolTable m_symbolTable;

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
      m_symbolTable  = null;
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
      m_symbolTable  = null;
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
      
      //se.color.SymbolColorConfig scc;
      se.color.SymbolColorRuleBase rb;
      if (pRuleBase == null) {
         rb.loadProfile(def_symbol_color_profile);
         if (rb.getNumRules()>0) {
            pRuleBase=&rb;
         }
      }

      m_isEnabled = false;
      if (pRuleBase != null) {
         m_ruleIndex = SymbolColorRuleIndex.allocateRuleIndex(*pRuleBase);
         m_isEnabled = true;
      }

      m_doubleBuffer = null;
      m_symbolTable  = null;
      SymbolColorDoubleBuffer buff;
      m_doubleBuffer = buff;
      SymbolTable symtab;
      m_symbolTable = symtab;
   }

   /**
    * @return
    * Return 'true' if symbol coloring is enabled for this file.
    */
   bool isSymbolColoringEnabled() {
      return m_isEnabled;
   }

   /**
    * Turn symbol coloring on or off for the current file.
    */
   void enableSymbolColoring(bool onOff) {
      m_isEnabled = onOff;
   }

   /**
    * @return
    * Return 'true' if highlighting of unidentified symbols is enabled for this file.
    */
   bool isErrorColoringEnabled() {
      return m_isErrorsEnabled;
   }

   /**
    * Turn highlighting of unidentified symbols on or off for the current file.
    */
   void enableErrorColoring(bool onOff) {
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
         m_symbolTable.reset();
         _StreamMarkerRemoveAllType(m_streamMarkerType);
      }
   }

   /**
    * Reinitialize all the symbol color analyzers for different buffers 
    * if the current symbol coloring scheme changes. 
    */
   static void initAllSymbolAnalyzers(se.color.SymbolColorRuleBase *pRuleBase,
                                      bool resetViewOptions=false) {
      if (_no_child_windows()) {
         return;
      }

      orig_wid := p_window_id;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      orig_buf_id := p_buf_id;
      for (;;) {
         se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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
         se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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

         // maybe strip off the symbol color prefix
         if (beginsWith(markerInfo.msg, SM_DESC_PREFIX)) {
            msg := substr(markerInfo.msg, length(SM_DESC_PREFIX) + 1);
            rule := rb->getRuleByName(msg);
            if (rule != null) return rule;
         }
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
   static bool isPreprocessingLine() {
      
      // check if the starts with a preprocessing character
      save_pos(auto pp_pos);
      _first_non_blank();
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
         _first_non_blank();
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

   bool needsReset()
   {
      // if we are looking at a different buffer, or it's modify state
      // has changed, then reset the start & end lines.
      return (m_lastBufferId != p_buf_id || m_lastModified != p_LastModified);
   }

   /**
    * Determine the first and last visible lines in the current window 
    * (editor control). 
    * 
    * @param startLine  set to the first line (inclusive) to color 
    * @param endLine    set to the last line (inclusive) to color 
    * @param height     height of the current window (p_height)
    */
   static void determineFirstAndLastVisibleLines(int &startLine, int &endLine)
   {
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
      p_cursor_y=p_client_height-1;
      endLine = p_RLine+1;
      p_cursor_y = orig_cursor_y;
      restore_pos(p);
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
    * @param doMinimap   Set to true if the line range is off-screen, 
    *                    but visible in the minimap control.
    * @param doOffScreen Set to true if the line range is off-screen entirely. 
    * 
    * @return 'true' if we need to do symbol coloring, false if everything 
    *         is up to date. 
    */
   bool determineLineRangeToColor(int &startLine, 
                                  int &endLine, 
                                  bool &doRefresh,
                                  bool &doMinimap,
                                  bool &doOffScreen)
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
         m_symbolTable.reset();
         doRefresh = true;
      }

      // update the buffer id and last modified state
      m_lastBufferId = p_buf_id;
      m_lastModified = p_LastModified;

      // find the first and last visible lines on the screen
      determineFirstAndLastVisibleLines(startLine, endLine);

      // check if the range is within the minimal number of lines worth coloring
      if (endLine - startLine  < def_symbol_color_chunk_size) {
         endLine = startLine + def_symbol_color_chunk_size;
      }

      // Check if we have colored all the on-screen lines
      if (m_coloredLines != null && m_coloredLines.containsRange(startLine, endLine)) {
         doOffScreen = true;
      }

      // Check if we have a minimap
      minLine := startLine;
      maxLine :=   endLine;
      if (doOffScreen && p_minimap_wid && p_show_minimap) {
         if (_iswindow_valid(p_minimap_wid) && p_minimap_wid.p_visible) {
            p_minimap_wid.determineFirstAndLastVisibleLines(auto minimapStartLine, auto minimapEndLine);
            if (minimapStartLine < startLine) minLine = minimapStartLine;
            if (minimapEndLine   > endLine  ) maxLine = minimapEndLine;
            doMinimap = true;

            // color the lines shown above the current page in the minimap.
            // this is a big gulp, but we'll double-buffer as much as we can
            if (m_coloredLines != null && minLine < startLine-1 && !m_coloredLines.containsRange(minLine, startLine-1)) {
               endLine   = startLine-1;
               startLine = minLine;
               return true;
            }

            // color the lines shown below the current page in the minimap.
            // this is a big gulp, but we'll double-buffer as much as we can
            if (m_coloredLines != null && maxLine > endLine+1 && !m_coloredLines.containsRange(endLine+1, maxLine)) {
               startLine = endLine+1;
               endLine   = maxLine;
               return true;
            }
         }
      }

      // check if we have colored as much as we can color
      minLine = startLine - def_symbol_color_off_page_lines;
      maxLine = endLine + def_symbol_color_off_page_lines;
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
    * symbol declaration or definition in the current context.
    * <p> 
    * If it is, insert the symbol into the match set. 
    * <p> 
    * It is accurate to check the context first, before checking for matches 
    * among local variables, because we are looking at actual seek positions 
    * of the names in symbol declarations and definitions, so if we find a match 
    * in the current context, there is no chance of it being a local variable. 
    * <p> 
    * This also allows us to shortcut the local variable search. 
    * 
    * @return 'true' if there is a match, 'false' otherwise
    */
   bool findContextDeclaration(long curOffset, se.tags.SymbolInfo &sym) 
   {
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // current context?
      contextId := tag_current_context_name();
      if (contextId > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, contextId, auto typeName);
         switch (typeName) {
         case "friend":
         case "include":
         case "statement":
            break;
         case "import":
            tag_get_detail2(VS_TAGDETAIL_context_return, contextId, auto returnType);
            if (returnType == "") break;
            sym.getContextInfo(contextId);
            return true;
         default:
            sym.getContextInfo(contextId);
            return true;
         }
      }

      // no, this is not a declaration in the current context
      return false;
   }
   /**
    * Check if the cursor is positioned on the identifier part of a local
    * symbol declaration or definition.
    * <p> 
    * If it is, insert the symbol into the match set. 
    * 
    * @return 'true' if there is a match, 'false' otherwise
    */
   bool findLocalDeclaration(long curOffset, se.tags.SymbolInfo &sym) 
   {
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // is it a local variable?
      localId := tag_current_local_name();
      if (localId > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, localId, auto typeName);
         switch (typeName) {
         case "friend":
         case "include":
         case "statement":
            break;
         case "import":
            tag_get_detail2(VS_TAGDETAIL_local_return, localId, auto returnType);
            if (returnType == "") break;
            sym.getLocalInfo(localId);
            return true;
         default:
            sym.getLocalInfo(localId);
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
    *
    * @return 0 on success, &lt; 0 on error, TAGGING_TIMEOUT_RC on timeout.
    */
   int colorLines(int startLine=0, int endLine=0)
   {
      orig_idle_time := _idle_time_elapsed();
      status := 0;
      while (!status) {
         // find out if we were mid-process before
         m_doubleBuffer.getState(auto stage, auto stateInfo, startLine, endLine);
         switch (stage) {
         case DBS_GET_SYMBOLS:
         default:
            status = getSymbolsStep(startLine, endLine, stateInfo);
            if (!status) {
               m_doubleBuffer.saveState(DBS_MATCH_COLORS, -1, startLine, endLine);
            }
            break;
         case DBS_MATCH_COLORS:
            status = matchColorsStep((int)stateInfo);
            if (!status) {
               m_doubleBuffer.saveState(DBS_DO_COLOR, -1);
            }
            break;
         case DBS_DO_COLOR:
            status = colorLinesStep((int)stateInfo);
            if (!status) {
               m_doubleBuffer.saveState(DBS_DO_MARKERS, -1);
            }
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
               m_symbolTable.reset();

               // we completed everything successfully, so let's quit
               return 1;
            }
            break;
         }
         if (status == TAGGING_TIMEOUT_RC || _CheckTimeout()) {
            return TAGGING_TIMEOUT_RC;
         }
         new_idle_time := _idle_time_elapsed();
         if (new_idle_time >= orig_idle_time+def_symbol_color_timeout) {
            return TAGGING_TIMEOUT_RC;
         }
      }

      // that's just the way it is
      return status;
   }

   /**
    * First step in coloring lines - go through and get our
    * symbols.
    *
    * @param startLine
    * @param endLine
    * @param seekPos
    *
    * @return 0 on success, &lt; 0 on error, TAGGING_TIMEOUT_RC on timeout.
    */
   private int getSymbolsStep(int startLine=0, int endLine=0, long seekPos = -1)
   {
      // make sure we have a scheme set up and a rule index object
      if (m_ruleIndex == null) {
         return INVALID_POINTER_ARGUMENT_RC;
      }

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
         if (langExpressionInfoIndex <= 0 || !index_callable(langExpressionInfoIndex)) {
            return TAGGING_NOT_SUPPORTED_FOR_FILE_RC;
         }
      }

      // save the current editor position and search expression
      save_pos(auto p);
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

      // update the symbols in the current file
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);
      //_UpdateContextAndTokens(true);

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
      if (mark_id<0) {
         return INVALID_SELECTION_HANDLE_RC;
      }

      // create a selection of the first [default 4000] lines
      _select_line(mark_id);
      p_RLine = endLine;
      _select_line(mark_id);
      _show_selection(mark_id);
      _begin_select(mark_id);

      // symbol analysis result cache
      visited := null;

      // error symbol to be used as a proxy when we can not find a symbol
      _str errorArgs[];
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
      status := search(id_re:+"|\\{|\\}","@rmXknscp234lvax");
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
            m_symbolTable.pushScope();
            break;
         // closing the current scope, decrease the scope level
         case "}":
            m_symbolTable.popScope();
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
            analyzer := _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
            if (analyzer == null || _CheckTimeout()) {
               m_doubleBuffer.saveState(DBS_GET_SYMBOLS, _QROffset());
               endLine = p_RLine;
               timeout = true;
               break;
            }

            // get the current context ID
            contextId := tag_current_context();
            m_symbolTable.maybePushContextScope(contextId);

            // analyze the context this identifier was found in
            se.tags.SymbolInfo *psym = null;
            tag_idexp_info_init(idexp_info);

            if (_GetSymbolColoringOptions() & SYMBOL_COLOR_SIMPLISTIC_TAGGING) {
               idexp_info.lastid = cur_identifier(idexp_info.lastidstart_col);
               idexp_info.lastidstart_offset = (int)_QROffset();
               idexp_info.prefixexpstart_offset = idexp_info.lastidstart_offset;
               status = 0;
            } else if (fastExpressionInfoIndex != 0) {
               status = call_index(false, _QROffset(), idexp_info, errorArgs, fastExpressionInfoIndex);
            } else {
               status = call_index(false, idexp_info, visited, 0, langExpressionInfoIndex);
            }
            if (_chdebug) {
               say("SymbolColorAnalyzer.getSymbolsStep: status="status" lastid="idexp_info.lastid);
            }
            // did we find anything?
            if (status || idexp_info.lastid == null) {
               break;
            }

            m_doubleBuffer.addSymbol((int)_QROffset(), idexp_info, numChars, m_symbolTable.getScopeLevel());
         }

         // skip over the identifier
         p_col += numChars;

         analyzer := _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
         if (analyzer == null || _CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_GET_SYMBOLS, _QROffset());
            endLine = p_RLine;
            timeout = true;
            break;
         }

         // search for the next identifier
         status = search(id_re"|\\{|\\}","@mrXknscp234lvax");
      }

      // The selection can be freed because it is not the active selection.
      _show_selection(orig_mark_id);
      _free_selection(mark_id);

      // restore the editor position and search parameters
      restore_pos(p);
      restore_search(s1, s2, s3, s4, s5);

      if (timeout) {
         return TAGGING_TIMEOUT_RC;
      }
      return 0;
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
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);
      //_UpdateContextAndTokens(true);

      // If strict symbol matching is disabled for this language,
      // turn on the "lenient" flag.
      symbolColoringOptions := _GetSymbolColoringOptions();
      strictFlag := SE_TAG_CONTEXT_NULL;
      if (symbolColoringOptions & SYMBOL_COLOR_NO_STRICT_TAGGING) {
         strictFlag = SE_TAG_CONTEXT_FIND_LENIENT;
      }

      // symbol analysis result cache
      tag_files := tags_filenamea(p_LangId);

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
         offset := m_doubleBuffer.getOffset(j);
         _GoToROffset(offset);

         // determine if we need to change the scope
         scopeLevel := m_doubleBuffer.getSymbolScope(j);
         m_symbolTable.setScopeLevel(scopeLevel);

         if (_chdebug) {
            say("SymbolColorAnalyzer.matchColorsStep: lastid="idexp_info->lastid" line="p_RLine" col="p_col" scope="scopeLevel);
         }

         // check if the identifier under the cursor is part of a symbol
         // declaration or definition in the current context
         se.tags.SymbolInfo *psym = null;
         se.tags.SymbolInfo name_sym;
         if (findContextDeclaration(offset, name_sym)) {
            psym = &name_sym;
            m_symbolTable.addSymbol(idexp_info->prefixexp :+ idexp_info->lastid, name_sym);
            m_doubleBuffer.setSymbolDeclaration(j, true);
            if (_chdebug) {
               say("SymbolColorAnalyzer.matchColorsStep: found declaration, type="name_sym.m_tagType);
            }

            // try to propagate tag flags from this symbol to related symbols
            // that is, from declaration to definition, or vice-versa.
            tagFlags := name_sym.m_tagFlags;
            if (!(tagFlags & SE_TAG_FLAG_NO_PROPAGATE) && 
                name_sym.m_tagType != "lvar" && 
                name_sym.m_tagType != "param" &&
                name_sym.m_tagType != "package" &&
                name_sym.m_tagType != "program" &&
                name_sym.m_tagType != "library" &&
                name_sym.m_tagType != "import" &&
                name_sym.m_tagType != "include") {
               status := tag_list_associated_symbols(tag_files, 
                                                     name_sym.getBrowseInfo(), 
                                                     auto associated_symbols, 
                                                     auto this_one_found_at, 
                                                     auto num_assocated, def_tag_max_function_help_protos,
                                                     p_LangCaseSensitive,
                                                     *m_symbolTable.getVisitedCache(), 0);
               if (status >= 0) {
                  foreach (auto i => auto assoc_sym in associated_symbols) {
                     if (i == this_one_found_at) continue;
                     if (assoc_sym.flags & SE_TAG_FLAG_NO_PROPAGATE) continue;
                     if ((assoc_sym.flags & SE_TAG_FLAG_INCLASS) == (tagFlags & SE_TAG_FLAG_INCLASS)) continue;
                     if (assoc_sym.flags & SE_TAG_FLAG_INCLASS) {
                        if (!(tagFlags & SE_TAG_FLAG_INTERNAL_ACCESS)) {
                           tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_INTERNAL_ACCESS);
                        }
                        if (!(tagFlags & SE_TAG_FLAG_VIRTUAL)) {
                           tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_VIRTUAL);
                        }
                        if (!(tagFlags & SE_TAG_FLAG_FINAL)) {
                           tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_FINAL);
                        }
                     } else {
                        if (!(tagFlags & SE_TAG_FLAG_EXTERN)) {
                           tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_EXTERN);
                        }
                     }
                     if (!(tagFlags & SE_TAG_FLAG_STATIC)) {
                        tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_STATIC);
                     }
                     if (!(tagFlags & SE_TAG_FLAG_INLINE)) {
                        tagFlags |= (assoc_sym.flags & SE_TAG_FLAG_INLINE);
                     }
                     if (tagFlags != name_sym.m_tagFlags) {
                        name_sym.m_tagFlags = tagFlags;
                        break;
                     }
                  }
               }
            }

         } else {

            // symbol is not a declaration or definition in the current context
            // update local variables if we have moved to a new line
            _UpdateLocals(true,true);
            if (_CheckTimeout()) {
               m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
               timeout = true;
               break;
            }

            // check if the identifier under the cursor is part of a symbol
            // declaration or definition
            if (findLocalDeclaration(offset, name_sym)) {
               psym = &name_sym;
               m_symbolTable.addSymbol(idexp_info->prefixexp :+ idexp_info->lastid, name_sym);
               m_doubleBuffer.setSymbolDeclaration(j, true);
               if (_chdebug) {
                  say("SymbolColorAnalyzer.matchColorsStep: found local");
               }

            } else {

               // not a local variable either
               // try to look up the symbol in the symbol table [cache]
               if (!(idexp_info->info_flags & (VSAUTOCODEINFO_HAS_CLASS_SPECIFIER|VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER))) {
                  psym = m_symbolTable.lookup(idexp_info->prefixexp :+ idexp_info->lastid);
               }

            }
         }

         SymbolColorRule *ruleInfoP = null;
         if (psym != null) {
            // We found the symbol, now find a matching symbol coloring rule
            ruleInfoP = m_ruleIndex->m_scheme.matchRules(*psym, m_ruleIndex->m_rulesByType);
            if (_chdebug) {
               say("SymbolColorAnalyzer.matchColorsStep: found in symbol table");
            }

         } else {

            // update local variables if we have moved to a new line
            _UpdateLocals(true);
            analyzer := _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
            if (analyzer == null || _CheckTimeout()) {
               m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
               timeout = true;
               break;
            }

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
                  if (_chdebug) {
                     say("SymbolColorAnalyzer.matchColorsStep: doing simplicistic search: lastid="idexp_info->lastid);
                  }
                  status = tag_list_any_symbols(0, 0,
                                                idexp_info->lastid,
                                                tag_files,
                                                SE_TAG_FILTER_ANYTHING,
                                                SE_TAG_CONTEXT_ALLOW_LOCALS,
                                                num_matches, 10,
                                                true, p_LangCaseSensitive,
                                                *m_symbolTable.getVisitedCache(), 1);
                  if (num_matches <= 0 && tag_get_num_of_matches() <= 0) {
                     status = VSCODEHELPRC_NO_SYMBOLS_FOUND;
                  }
               } else {
                  if (_chdebug) {
                     say("SymbolColorAnalyzer.matchColorsStep: doing context tagging search: "idexp_info->prefixexp:+idexp_info->lastid);
                  }
                  status = call_index(errorArgs,
                                      idexp_info->prefixexp,
                                      idexp_info->lastid,
                                      idexp_info->lastidstart_offset,
                                      idexp_info->info_flags,
                                      idexp_info->otherinfo,
                                      false, 10,
                                      true, p_LangCaseSensitive,
                                      SE_TAG_FILTER_ANYTHING|(p_LangCaseSensitive? SE_TAG_FILTER_CASE_SENSITIVE:0),
                                      SE_TAG_CONTEXT_ALLOW_LOCALS|strictFlag,
                                      *m_symbolTable.getVisitedCache(), 1,
                                      langFindContextTagsIndex);
               }

               analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
               if (analyzer == null || _CheckTimeout() || status == VSCODEHELPRC_LIST_MEMBERS_TIMEOUT || status == TAGGING_TIMEOUT_RC ) {
                  m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
                  timeout = true;
                  tag_pop_matches();
                  if (_chdebug) {
                     say("SymbolColorAnalyzer.matchColorsStep: TIMEOUT, p_line="p_line" tag="idexp_info->lastid" status="status);
                  }
                  break;
               }

               // did not find the symbol, then use the surrogate error symbol
               if (_chdebug) {
                  say("SymbolColorAnalyzer.matchColorsStep: p_line="p_line" tag="idexp_info->lastid" status="status);
               }
               if (status < 0 && status!=VSCODEHELPRC_BUILTIN_TYPE) {
                  if (_chdebug) {
                     say("SymbolColorAnalyzer.matchColorsStep: NO MATCH");
                  }
                  tag_pop_matches();
                  if ( useSymbolNotFoundColoring ) {
                     psym = &errorSym;
                     errorSym.m_name = idexp_info->lastid;
                     m_symbolTable.addSymbol(idexp_info->prefixexp :+ idexp_info->lastid, errorSym);
                     ruleInfoP = m_ruleIndex->m_scheme.matchRules(*psym, m_ruleIndex->m_rulesByType);
                  }
               } else {

                  // analyze the symbol matches we found
                  num_matches = tag_get_num_of_matches();
                  if (_chdebug) {
                     say("SymbolColorAnalyzer.matchColorsStep: "num_matches" MATCHES");
                  }

                  // loop through the symbol matches, computing the color rule
                  // mappings and taking votes on which one was most popular.
                  int votes:[];
                  typeless rules:[];
                  typeless symbols:[];
                  for (i:=1; i<=num_matches; ++i) {
                     se.tags.SymbolInfo sym;
                     sym.getMatchInfo(i);
                     ruleInfoP = m_ruleIndex->m_scheme.matchRules(sym, m_ruleIndex->m_rulesByType);
                     if (ruleInfoP != null && ruleInfoP->m_colorInfo != null) {
                        if (votes._indexin(ruleInfoP->m_ruleName)) {
                           votes:[ruleInfoP->m_ruleName]++;
                        } else {
                           votes:[ruleInfoP->m_ruleName]=1;
                           rules:[ruleInfoP->m_ruleName] = ruleInfoP;
                           symbols:[ruleInfoP->m_ruleName] = sym;
                        }
                        if (sym.m_tagFlags & SE_TAG_FLAG_INCLASS) {
                           votes:[ruleInfoP->m_ruleName]+=2;
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
                     m_symbolTable.addSymbol(idexp_info->prefixexp :+ idexp_info->lastid, symbols:[mostVotedRule]);
                  }

                  // clean up match set
                  tag_pop_matches();
               }
            }
         }

         if (ruleInfoP != null) {
            m_doubleBuffer.setSymbolColorRule(j, *ruleInfoP);
         }

         analyzer := _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
         if (analyzer == null) {
            m_doubleBuffer.saveState(DBS_MATCH_COLORS, j++);
            break;
         }
         if (_CheckTimeout()) {
            m_doubleBuffer.saveState(DBS_MATCH_COLORS, j);
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
      codehelpFlags := _GetCodehelpFlags();

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
         numChars := m_doubleBuffer.getSymbolLength(j);
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
            description := "";
            if (codehelpFlags & VSCODEHELPFLAG_MOUSE_OVER_INFO) {
               description = SM_DESC_PREFIX :+ ruleInfoP->m_ruleName;
            }
            m_doubleBuffer.markSymbolColored(j, colorId, description);

         } else {
            // do not color symbols who do not match any symbol coloring rule
            //say("colorLines: no color rule matches");
         }

         analyzer := _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
         if (analyzer == null || _CheckTimeout()) {
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
   int createMarkersStep(bool reset=false)
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
 *  
 * @note
 * To correct for a bug in earlier versions of the Slick-C compiler, 
 * SYMBOL_COLOR_SHOW_NO_ERRORS overlaps with the unused symbol 
 * SYMBOL_COLOR_UNDERLINE_DEFINITIONS[_DEPRECATED].
 */
_metadata enum_flags SYMBOL_COLOR_OPTIONS {
   SYMBOL_COLOR_BOLD_DEFINITIONS = F_BOLD,
   SYMBOL_COLOR_UNDERLINE_DEFINITIONS_DEPRECATED = F_UNDERLINE,
   SYMBOL_COLOR_ITALIC_DEFINITIONS = F_ITALIC,
   SYMBOL_COLOR_SHOW_NO_ERRORS = 0x8,
   SYMBOL_COLOR_NO_STRICT_TAGGING,
   SYMBOL_COLOR_DISABLED,
   SYMBOL_COLOR_SIMPLISTIC_TAGGING,
   SYMBOL_COLOR_POSITIONAL_KEYWORDS,
   SYMBOL_COLOR_PARSER_ERRORS,
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

_metadata enum SYMBOL_COLOR_WINDOWS {
   SC_CURRENT_WINDOW,
   SC_VISIBLE_WINDOWS,
   SC_ALL_WINDOWS,
};

/**
 * Which windows to perform symbol coloring for.  Use the 
 * SYMBOL_COLOR_WINDOWS enum.  Possible values: 
 *    SC_CURRENT_WINDOW - color current window only 
 *    SC_VISIBLE_WINDOWS - color all visible windows
 *    SC_ALL_WINDOWS - color all windows
 */
int def_symbol_color_windows = SC_CURRENT_WINDOW;

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
bool _QSymbolColoringSupported(_str lang=null)
{
   // No language specified?
   if (lang == null && _isEditorCtl()) lang = p_LangId;
   if (lang == null) {
      return false;
   }

   // the current language has to support tagging
   if ( !_QTaggingSupported(p_window_id, lang) ) {
      return false;
   }

   // cache languages that are and are not supported.
   static bool isSupported:[];
   if (isSupported._indexin(lang)) {
      return isSupported:[lang];
   }

   // Do not support HTML, XML, XMLDoc, etc.
   if ( _LanguageInheritsFrom("html", lang) ||
        _LanguageInheritsFrom("xhtml", lang) ||
        _LanguageInheritsFrom("xml", lang) ||
        _LanguageInheritsFrom("tld", lang) ||
        _LanguageInheritsFrom("xsd", lang) ||
        _LanguageInheritsFrom("android", lang) ||
        _LanguageInheritsFrom("docbook", lang) ||
        _LanguageInheritsFrom("xmldoc", lang) ) {
      isSupported:[lang] = false;
      return false;
   }

   // Disable it for other non-SGML related markup languages
   if ( _LanguageInheritsFrom("bbc", lang) ||
        _LanguageInheritsFrom("markdown", lang) ||
        _LanguageInheritsFrom("tex", lang) ||
        _LanguageInheritsFrom("latex", lang) ||
        _LanguageInheritsFrom("bibtex", lang) ||
        _LanguageInheritsFrom("rtf", lang) ||
        _LanguageInheritsFrom("ps", lang) ||
        _LanguageInheritsFrom("pdf", lang) ) {
      isSupported:[lang] = false;
      return false;
   }

   // Also do not support certain configuration file formats
   if ( _LanguageInheritsFrom("ini", lang) ||
        _LanguageInheritsFrom("conf", lang) ||
        _LanguageInheritsFrom("vlx", lang) ||
        _LanguageInheritsFrom("diffpatch", lang) ||
        _LanguageInheritsFrom("rc", lang) ) {
      isSupported:[lang] = false;
      return false;
   }

   // Also do not support makefiles and Imakefiles and CMakeLists.txt
   if ( _LanguageInheritsFrom("mak", lang) ||
        _LanguageInheritsFrom("imakefile", lang) ||
        _LanguageInheritsFrom("ant", lang) ||
        _LanguageInheritsFrom("cmake", lang) ||
        _LanguageInheritsFrom("ninja", lang) ) {
      isSupported:[lang] = false;
      return false;
   }

   // Also, do not support compiler generator languages
   if ( _LanguageInheritsFrom("antlr", lang) ||
        _LanguageInheritsFrom("lex", lang) ||
        _LanguageInheritsFrom("yacc", lang) ) {
      isSupported:[lang] = false;
      return false;
   }

   // Let the others pass through
   isSupported:[lang] = true;
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
      se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer != null) analyzer->resetSymbolColoring();
      p_window_id = orig_wid;
      return;
   }

   // check if we already have an analyzer object for this buffer?
   se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(_QSymbolColoringErrors(true));
      _SetBufferInfoHt(SM_BUFFER_INFO_KEY, tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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

// this keeps track of our index in the tab list
static int other_tab_iter = 0;
static int visible_tab_iter = 0;
static bool tab_minimal_work = false;
static int gvisible_tabs[];
static int gother_tabs[];

int symbol_coloring_windows(int value = null)
{
   if (value != null) {
      // set the new value, reset our list
      def_symbol_color_windows = value;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      other_tab_iter = 0;
      visible_tab_iter = 0;
      tab_minimal_work = true;
      gvisible_tabs._makeempty();
      gother_tabs._makeempty();
   }

   return def_symbol_color_windows;
}

// reset our lists of visible windows (file tabs) and other windows to handle
static void _ResetVisibleTabs()
{
   other_tab_iter = 0;
   visible_tab_iter = 0;
   tab_minimal_work = true;
   gvisible_tabs._makeempty();
   gother_tabs._makeempty();
}

definit()
{
   _ResetVisibleTabs();
}

void _switchbuf_SymbolColoring(_str oldbuffname, _str flag)
{
   _ResetVisibleTabs();
}
void _cbquit_SymbolColoring(int buffid, _str name, _str docname= "", int flags = 0)
{
   _ResetVisibleTabs();
}
void _buffer_add_SymbolColoring(int newBuffID, _str name, int flags = 0)
{
   _ResetVisibleTabs();
}

static void _RemoveCachedFileTab(int wid, int tab_index)
{
   // remove from list of visible file tabs
   if (gvisible_tabs._length() > 1) {
      if (tab_index < gvisible_tabs._length() && gvisible_tabs[tab_index] == wid) {
         gvisible_tabs._deleteel(tab_index);
         if (tab_index < visible_tab_iter) {
            --visible_tab_iter;
         }
      } else if (visible_tab_iter < gvisible_tabs._length() && gvisible_tabs[visible_tab_iter] == wid) {
         gvisible_tabs._deleteel(visible_tab_iter);
      }
   }
   // remove from list of other file tabs
   if (tab_index < gother_tabs._length() && gother_tabs[tab_index] == wid) {
      gother_tabs._deleteel(other_tab_iter);
      if (tab_index < other_tab_iter) {
         --other_tab_iter;
      }
   } else if (other_tab_iter < gother_tabs._length() && gother_tabs[other_tab_iter] == wid) {
      gother_tabs._deleteel(other_tab_iter);
   }
}

static void _GetVisibleFileTabs(int (&visible_tabs)[], int (&other_tabs)[])
{
   // if we have the tabs cached, no need to get them again
   // but we should check if the window IDs are still valid
   if (gvisible_tabs._length() > 0) {
      have_invalid_editorctl_wid := false;
      foreach (auto editor_wid in gvisible_tabs) {
         if (!_iswindow_valid(editor_wid) || !editor_wid._isEditorCtl()) {
            have_invalid_editorctl_wid = true;
            break;
         }
      }
      if (!have_invalid_editorctl_wid) {
         visible_tabs = gvisible_tabs;
         other_tabs   = gother_tabs;
         return;
      }
   }

   orig_wid := p_window_id;
   current := 0;

   // start with the current one
   if (!_no_child_windows()) {
      p_window_id = _mdi.p_child;
      current=p_window_id;
   }
   bool tabs_found:[];
   if (current && current!=VSWID_HIDDEN && current.p_object==OI_EDITOR) {
      visible_tabs[0] = current;
      tabs_found:[current] = true;
   }

   // if we are only doing this one, then we are done
   if (def_symbol_color_windows == SC_CURRENT_WINDOW) {
      p_window_id = orig_wid;
      gvisible_tabs = visible_tabs;
      gother_tabs._makeempty();
      return;
   }

   // grab the list of windows
   int windows[];
   _MDIGetMDIWindowList(windows);

   // go through each one and pick up the visible document windows
   for (i := 0; i < windows._length(); i++) {
      first := _MDICurrentChild(windows[i]);
      if (first && first != current) {
         visible_tabs :+= first;
         tabs_found:[first] = true;
      }

      if (first) {
         next_wid := _MDINextDocumentWindow(first, 'G', false);
         while (next_wid && next_wid != first) {
            if (next_wid && !tabs_found._indexin(next_wid)) {
               visible_tabs :+= next_wid;
               tabs_found:[next_wid] = true;
            }
            next_wid = _MDINextDocumentWindow(next_wid, 'G', false);
         }
      }
   }

   // check the preview window
   preview_wid := _GetTagwinEditorWID(true);
   if (preview_wid > 0) {
      visible_tabs :+= preview_wid;
      tabs_found:[preview_wid] = true;
   } else {
      preview_wid = _GetTagwinEditorWID(false);
      if (preview_wid > 0) {
         other_tabs :+= preview_wid;
         tabs_found:[preview_wid] = true;
      }
   }

   // check the references window
   preview_wid = _GetReferencesEditorWID(true);
   if (preview_wid > 0) {
      visible_tabs :+= preview_wid;
      tabs_found:[preview_wid] = true;
   } else {
      preview_wid = _GetReferencesEditorWID(false);
      if (preview_wid > 0) {
         other_tabs :+= preview_wid;
         tabs_found:[preview_wid] = true;
      }
   }

   // if we are only doing visible windows, then we are done
   if (def_symbol_color_windows == SC_VISIBLE_WINDOWS) {
      p_window_id = orig_wid;
      gvisible_tabs = visible_tabs;
      gother_tabs = other_tabs;
      return;
   }

   // go through each one and pick up the rest of the document windows
   for (i = 0; i < windows._length(); i++) {
      first := _MDICurrentChild(windows[i]);
      if (first && !tabs_found._indexin(first)) {
         other_tabs :+= first;
         tabs_found:[first] = true;
      }

      if (first) {
         next_wid := _MDINextDocumentWindow(first, 'N', false);
         while (next_wid && next_wid != first) {
            if (next_wid && !tabs_found._indexin(next_wid)) {
               other_tabs :+= next_wid;
               tabs_found:[next_wid] = true;
            }
            next_wid = _MDINextDocumentWindow(next_wid, 'N', false);
         }
      }
   }

   p_window_id = orig_wid;
   gvisible_tabs = visible_tabs;
   gother_tabs = other_tabs;
   return;
}

void _UpdateSymbolColoring(bool force=false)
{
   _UpdateSymbolColoringForAll(force, doCurrentWindowOnly:false);
}

static void _UpdateSymbolColoringForAll(bool force=false, bool doCurrentWindowOnly=false)
{
   // No symbol coloring for SlickEdit Standard
   if (!_haveContextTagging()) {
      if (_chdebug) {
         say("_UpdateSymbolColoring: no context tagging");
      }
      return;
   }

   // update symbol coloring only when the editor has been idle for a while
   idle := _idle_time_elapsed();
   if (!force && idle < def_symbol_color_delay) {
      return;
   }

   // get the editor control window ID to update
   orig_wid := p_window_id;

   // get the list of tabs
   int visible_tabs[];
   int other_tabs[];
   if (doCurrentWindowOnly && !_no_child_windows() && _isEditorCtl()) {
      visible_tabs[0] = p_window_id;
   } else {
      _GetVisibleFileTabs(visible_tabs, other_tabs);
   }

   // set a one second timeout
   sc.lang.ScopedTimeoutGuard timeout(def_symbol_color_timeout);

   if (visible_tabs._varformat() == VF_ARRAY && visible_tabs._length() >= 1) {
      // always try to update the visible lines in the current window first
      p_window_id = visible_tabs[0];
      status := _UpdateSymbolColoringForWindow(force, doMinimalWork:true, okToRefresh:true);
      if (status || _CheckTimeout()) {
         // go back to our original window
         p_window_id = orig_wid;
         return;
      }

      // next try to update the off-screen lines in the current window
      status = _UpdateSymbolColoringForWindow(force, doMinimalWork:false, okToRefresh:false);
      if (status || _CheckTimeout()) {
         // go back to our original window
         p_window_id = orig_wid;
         return;
      }

      // next try to update the visible lines in the other visible tabs
      for (i:=1; i<visible_tabs._length(); i++) {
         // non-zero status means we broke out before completing this tab
         p_window_id = visible_tabs[i];
         status = _UpdateSymbolColoringForWindow(force, doMinimalWork:true, okToRefresh:true, i);
         if (status || _CheckTimeout()) {
            // go back to our original window
            p_window_id = orig_wid;
            return;
         }
      }

      // now try to update the lines outside the visible are of visible windows
      while (!doCurrentWindowOnly && visible_tab_iter < visible_tabs._length()) {
         // non-zero status means we broke out before completing this tab
         p_window_id = visible_tabs[visible_tab_iter];
         status = _UpdateSymbolColoringForWindow(force, doMinimalWork:false, okToRefresh:false, visible_tab_iter);
         if (status || _CheckTimeout()) {
            // go back to our original window
            p_window_id = orig_wid;
            return;
         }

         // next please
         visible_tab_iter++;
      }
   }

   // now try to update the non-visible windows
   if (!doCurrentWindowOnly && other_tabs._varformat() == VF_ARRAY && other_tabs._length() >= 1) {
      while (other_tab_iter < other_tabs._length()) {
         wid := other_tabs[other_tab_iter];
         if (!_iswindow_valid(wid) || !wid._isEditorCtl()) continue;
         p_window_id = wid;
         status := _UpdateSymbolColoringForWindow(force, tab_minimal_work, okToRefresh:false, other_tab_iter);
         if (!status) {
            // hey, we finished this tab!
            other_tab_iter++;
            if (other_tab_iter >= other_tabs._length() && tab_minimal_work) {
               tab_minimal_work = false;
               other_tab_iter = 0;
            }
         } else {
            // non-zero status means we broke out before completing this tab
            break;
         }

         // check to see if we need to bail on this step, try again when
         // we have more time
         if (_CheckTimeout()) break;
      }
   }

   // go back to our original window
   p_window_id = orig_wid;
}

/**
 * Update the symbol coloring for the current buffer. 
 *  
 * update current buffer first 
 *       other visible buffers
 *       other editor windows
 *  
 *       buffer information - name, wid, visibility status,
 *       whether it's been colored
 *  
 *  
 * @param force  -- force the symbol coloring to update now 
 *  
 * @return     0 the window has been completed, 1 if we timed 
 *             out or otherwise did not finish
 */
int _UpdateSymbolColoringForWindow(bool force=false, bool doMinimalWork=false, bool okToRefresh=false, int tab_index=0)
{
   // reset invalid regions after 1/4 second delay
   idle := _idle_time_elapsed();
   if (force || idle > 250 || idle > def_symbol_color_delay) {
      _MaybeResetSymbolColoring();
   }

   // update symbol coloring only when the editor has been idle for a while
   if (!force && idle < def_symbol_color_delay) {
      return 1;
   }

   // check if symbol coloring is disabled or not supported for this language
   if (!_QSymbolColoringSupported() || !_QSymbolColoringEnabled()) {
      if (_chdebug) {
         if (!_QSymbolColoringSupported()) {
            say("_UpdateSymbolColoringForWindow H"__LINE__": NOT SUPPORTED");
         }
         if (!_QSymbolColoringEnabled()) {
            say("_UpdateSymbolColoringForWindow H"__LINE__": NOT ENABLED");
         }
      }
      se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer != null) analyzer->resetSymbolColoring();
      _RemoveCachedFileTab(p_window_id, tab_index);
      return 0;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!force && !_ContextIsUpToDate(idle, MODIFYFLAG_CONTEXT_UPDATED|MODIFYFLAG_TOKENLIST_UPDATED)) {
      if (_chdebug) {
         say("_UpdateSymbolColoringForWindow: context not up-to-date");
      }
      return 1;
   }

   // if there are already background tagging jobs in process, then
   // return immediately so as not to interfere
   if (tag_get_num_async_tagging_jobs() > 0) {
      if (_chdebug) {
         say("SymbolColorAnalyzer: other tagging jobs in process");
      }
      return 1;
   }

   // Bail out for large files.
   if (!force && !_CheckUpdateContextSizeLimits(VS_UPDATEFLAG_tokens,true)) {
      if (_chdebug) {
         say("SymbolColorAnalyzer: file is too large");
      }
      _RemoveCachedFileTab(p_window_id, tab_index);
      return 1;
   }

   // check if we already have an analyzer object for this buffer?
   se.color.SymbolColorAnalyzer *analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(_QSymbolColoringErrors(true));
      _SetBufferInfoHt(SM_BUFFER_INFO_KEY, tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer == null) {
         if (_chdebug) {
            say("SymbolColorAnalyzer: could not get analyzer object");
         }
         return 1;
      }
      analyzer->initAnalyzer(null);
   }

   // make sure that this symbol analyzer actually does something
   analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer->getRuleBase() == null || analyzer->getRuleBase()->getNumRules() <= 0) {
      analyzer->resetSymbolColoring();
      if (_chdebug) {
         say("SymbolColorAnalyzer: no analyzer rules");
      }
      _RemoveCachedFileTab(p_window_id, tab_index);
      return 0;
   }
   
   // no symbol coloring allowed in DiffZilla
   if ( _isdiffed(p_buf_id) ) {
      if (_chdebug) {
         say("SymbolColorAnalyzer: file is being diffed");
      }
      analyzer->resetSymbolColoring();
      _RemoveCachedFileTab(p_window_id, tab_index);
      return 0;
   }

   // keep track of the last state buffer updated, it's modify state,
   // and what lines we updated.
   save_pos(auto p);
   startLine := endLine := 0;
   doRefresh := offScreen := doMinimap := false;
   analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null || !analyzer->determineLineRangeToColor(startLine, endLine, doRefresh, doMinimap, offScreen)) {
      // do nothing, no coloring information to update at this time
      restore_pos(p);
      _RemoveCachedFileTab(p_window_id, tab_index);
      return 0;
   }

   // if offscreen is true, then we have colored all the visible lines in the editor
   if (offScreen) {
      // this is the least that I can do for you
      if (doMinimalWork) {
         restore_pos(p);
         return 0;
      }
      // just double the delay if we are still working on the minimap
      if (doMinimap) {
         if (_idle_time_elapsed() < 2*def_symbol_color_delay) {
            restore_pos(p);
            return 0;
         }
      } else {
         // wait longer before doing off-screen lines, and do not do off-screen
         // lines if we are waiting on a keypress already
         if (_idle_time_elapsed() < 4*def_symbol_color_delay) {
            restore_pos(p);
            return 0;
         }
      }
   }

   // check if the tag database is busy and we can't get a lock.
   dbName := _GetWorkspaceTagsFilename();
   haveDBLock := tag_trylock_db(dbName);
   if (!force && !haveDBLock) {
      restore_pos(p);
      return 1;
   }

   // now color the lines
   //say("_UpdateSymbolColoring: start="startLine" end="endLine" minimap="doMinimap " offscreen="offScreen" refresh="doRefresh" iterations="analyzer->m_numIterations);
   if (!haveDBLock) {
      if (tag_lock_db(dbName,def_symbol_color_timeout) < 0) {
         restore_pos(p);
         return 1;
      }
   }
   timeout := false;
   analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer != null) {
      // lock and update the current context and tokens
      tag_lock_context();
      _UpdateContextAndTokens(true);
      // now color as many lines as we can
      status := analyzer->colorLines(startLine,endLine);
      timeout = (status == TAGGING_TIMEOUT_RC);
      // and unlock the current context
      tag_unlock_context();
   }
   tag_unlock_db(dbName);
   restore_pos(p);

   // did we run out of time?
   if (timeout) {
      return TAGGING_TIMEOUT_RC;
   }

   // do a refresh, if necessary
   if (doRefresh && okToRefresh) {
      refresh();
   }

   return 1;
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
   // no context tagging?
   if (!_haveContextTagging()) {
      return(MF_GRAYED|MF_REQUIRES_PRO);
   }

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
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer != null) {
      se.color.SymbolColorRuleBase *ruleBase = analyzer->getRuleBase();
      if (ruleBase != null && schemeName == ruleBase->m_name) {
         isActiveScheme = true;
      } else {
         checked = 0;
      }
   } else {
      if (def_symbol_color_profile == schemeName) {
         isActiveScheme = true;
      }
   }

   if (cmdui.menu_handle) {
      _menu_get_state(cmdui.menu_handle, cmdui.menu_pos, auto mf_flags, 'p', auto caption);
      _menu_set_state(cmdui.menu_handle,
                      cmdui.menu_pos,
                      MF_ENABLED|checked,'p',
                      caption);
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
int _OnUpdate_symbol_coloring_next_scheme(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_symbol_coloring_set_scheme(cmdui, target_wid, command);
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
int _OnUpdate_symbol_coloring_prev_scheme(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_symbol_coloring_set_scheme(cmdui, target_wid, command);
}

void _SetSymbolColorNextPrevScheme(bool doNext)
{
   schemeName := _GetSymbolColoringSchemeName();

   // look up all the available symbol coloring scheme names
   //_str schemeNames[];
   //_str compatibleWith[];
   //SymbolColorConfig.getSchemeNamesOnly(schemeNames, compatibleWith, def_color_scheme);
   _str schemeNames[];
   se.color.SymbolColorRuleBase scc;
   scc.listProfiles(schemeNames, ColorScheme.getDefaultProfile());

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
_command void _SetSymbolColoringSchemeName(_str name="", bool doUpdate=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
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
   if (name=="") name = CONFIG_AUTOMATIC;
   automaticSchemeName := name;
   if (name=="" || name == CONFIG_AUTOMATIC) {
      automaticSchemeName = SymbolColorRuleBase.getDefaultSymbolColorProfile();
      if (automaticSchemeName=="") return;
   }
   if (!_plugin_has_profile(VSCFGPACKAGE_SYMBOLCOLORING_PROFILES, automaticSchemeName)) {
      return;
   }
   se.color.SymbolColorRuleBase rb;
   rb.loadProfile(name) ;

   // get the analyzer for the current buffer, create one if we don't have one
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt(SM_BUFFER_INFO_KEY, tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer == null) {
         return;
      }
   }

   // update the symbol coloring
   analyzer->enableSymbolColoring(true);
   analyzer->initAnalyzer(&rb);
   if (doUpdate) {
      target_wid._UpdateSymbolColoringForAll(force:true, doCurrentWindowOnly:true);
   }
}
int _OnUpdate__SetSymbolColoringSchemeName(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_symbol_coloring_set_scheme(cmdui, target_wid, command);
}

/**
 * @return Return the name of the symbol coloring scheme active for the 
 *         current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
bool _QSymbolColoringEnabled(bool ignorePerFileOption=false)
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
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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
   // no context tagging?
   if (!_haveContextTagging()) {
      return(MF_GRAYED|MF_REQUIRES_PRO);
   }

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
 * Turn symbol coloring on or off for the current editor window.
 *  
 * @param onoff   Indicates if we are turning symbol coloring on or off 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
_command void symbol_coloring_toggle(_str onoff="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbol coloring");
      return;
   }
   if (onoff == "") {
      onoff = !_QSymbolColoringEnabled();
   }
   _SetSymbolColoringEnabled(onoff, doUpdate:true);
}

_command void codehelp_trace_symbol_coloring() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   say("codehelp_trace_symbol_coloring: ===============================");
   onoff := _QSymbolColoringEnabled();
   if (onoff) {
      symbol_coloring_toggle(0);
   }
   orig_chdebug := _chdebug;
   _chdebug = 1;
   orig_timeout := def_symbol_color_timeout;
   def_symbol_color_timeout = 10000;
   symbol_coloring_toggle(1);
   def_symbol_color_timeout = orig_timeout;
   _chdebug = orig_chdebug;
   if (!onoff) {
      symbol_coloring_toggle(0);
   }
   say("============================================================");
}

/**
 * Turn symbol coloring on or off for the current editor window.
 *  
 * @param onoff      Indicates if we are turning symbol coloring on or off 
 * @param doUpdate   Update symbol coloring for this window immediately?
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
void _SetSymbolColoringEnabled(_str onoff="", bool doUpdate=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) {
         if (_chdebug) {
            say("_SetSymbolColoringEnabled: no editor window");
         }
         return;
      }
      target_wid = p_mdi_child;
   }

   // never enable symbol coloring for unsupported languages
   if ( !target_wid._QSymbolColoringSupported()) {
      if (_chdebug) {
         say("_SetSymbolColoringEnabled: symbol coloring not supported");
      }
      return;
   }

   // get the analyzer for the current buffer, create one if we don't have one
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt(SM_BUFFER_INFO_KEY, tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer == null) {
         if (_chdebug) {
            say("_SetSymbolColoringEnabled: could not get analyzer object");
         }
         return;
      }
      analyzer->initAnalyzer();
   }

   // update the symbol coloring
   analyzer->enableSymbolColoring(onoff != "0");
   if (doUpdate) {
      target_wid._UpdateSymbolColoringForAll(force:true, doCurrentWindowOnly:true);
   }
}

/**
 * @return Return the name of the symbol coloring scheme active for the 
 *         current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
bool _QSymbolColoringErrors(bool ignorePerFileOption=false)
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
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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
   // no context tagging?
   if (!_haveContextTagging()) {
      return(MF_GRAYED|MF_REQUIRES_PRO);
   }

   // not an editor control, then disable
   if ( !target_wid || !target_wid._isEditorCtl() || _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }

   if ( !target_wid._QSymbolColoringSupported()) {
      return MF_GRAYED|MF_UNCHECKED;
   }
   if ( !target_wid._are_locals_supported()) {
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
_command void symbol_coloring_errors_toggle(_str onoff="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Symbol coloring");
      return;
   }
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
void _SetSymbolColoringErrors(_str onoff="", bool doUpdate=false)
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
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer == null) {
      se.color.SymbolColorAnalyzer tmpAnalyzer;
      tmpAnalyzer.enableErrorColoring(target_wid._QSymbolColoringErrors(true));
      target_wid._SetBufferInfoHt(SM_BUFFER_INFO_KEY, tmpAnalyzer);
      analyzer = _GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
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
      target_wid._UpdateSymbolColoringForAll(force:true, doCurrentWindowOnly:true);
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
   se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
   if (analyzer != null) {
      rb := analyzer->getRuleBase();
      if (rb) {
         automaticSchemeName := se.color.SymbolColorRuleBase.getDefaultSymbolColorProfile(CONFIG_AUTOMATIC);
         if (rb->m_name != automaticSchemeName) {
            return rb->m_name;
         }
         return CONFIG_AUTOMATIC;
      }
   }
   return def_symbol_color_profile;
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

   // No context tagging, so no symbol coloring
   if (!_haveContextTagging()) {
      return;
   }

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
   currentSchemeName := def_symbol_color_profile;
   target_wid := p_window_id;
   if ( !_isEditorCtl() && !no_child_windows) {
      target_wid = p_mdi_child;
   }
   if (target_wid._isEditorCtl()) {
      se.color.SymbolColorAnalyzer *analyzer = target_wid._GetBufferInfoHtPtr(SM_BUFFER_INFO_KEY);
      if (analyzer != null) {
         se.color.SymbolColorRuleBase *ruleBase = analyzer->getRuleBase();
         if (ruleBase != null) {
            currentSchemeName = ruleBase->m_name;
         }
      }
   }

   // look up all the available symbol coloring scheme names
   _str schemeNames[];
   SymbolColorRuleBase.listProfiles(schemeNames, ColorScheme.getDefaultProfile());

   // and insert the compatible ones into the submenu
   bool foundSchemeNames:[];
   name := "";
   foreach (name in schemeNames) {
      checked := MF_UNCHECKED;
      if (name == currentSchemeName) {
         checked = MF_CHECKED;
      }
      displayName := name;
      if (name == CONFIG_AUTOMATIC) {
         automaticSchemeName := se.color.SymbolColorRuleBase.getDefaultSymbolColorProfile(CONFIG_AUTOMATIC);
         displayName = name :+ " (" :+ automaticSchemeName :+ ")";
      }
      foundSchemeNames:[name] = true;
      if (_menu_find(subMenuHandle, name, itemMenuHandle, itemPosition, "C")) {
         status = _menu_insert(subMenuHandle, _menu_info(subMenuHandle), 
                               checked, stranslate(displayName, "&&", "&"),
                               "symbol_coloring_set_scheme ":+name, name);
      } else {
         _menu_set_state(itemMenuHandle, name, checked, 'C', displayName);
      }
   }

   // delete the out-of-date scheme names
   for (itemPosition = _menu_info(subMenuHandle)-1; itemPosition >= 4; itemPosition--) {
      _menu_get_state(subMenuHandle, itemPosition, mf_flags, "p", caption,
                      auto dummyHandle = 0, categories, helpCommand, helpMessage);
      if (!foundSchemeNames._indexin(categories)) {
         _menu_delete(subMenuHandle, itemPosition);
         continue;
      }
   }
}

/**
 * Update the symbol coloring for the current buffer. 
 *  
 * @param force  -- force the symbol coloring to update now 
 */
void _UpdatePositionalKeywordColoring(bool force=false)
{
   // This is not supported for SlickEdit Standard
   if (!_haveContextTagging()) {
      return;
   }

   // update symbol coloring only when the editor has been idle for a while
   idle := _idle_time_elapsed();
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

   // if positional keyword coloring is turned off for this language
   if (!_are_positional_keywords_supported()) {
      p_window_id = orig_wid;
      return;
   }
   if ((_GetSymbolColoringOptions() & SYMBOL_COLOR_POSITIONAL_KEYWORDS) == 0) {
      p_window_id = orig_wid;
      return;
   }

   // Check if we should watch for parser errors
   colorErrors := (_GetSymbolColoringOptions() & SYMBOL_COLOR_PARSER_ERRORS) != 0;

   // if the context is not yet up-to-date, then don't update yet
   if (!force && !_ContextIsUpToDate(idle, MODIFYFLAG_TOKENLIST_UPDATED)) {
      //say("_UpdatePositionalKeywordColoring: context not up-to-date");
      p_window_id = orig_wid;
      return;
   }

   // Bail out for large files.
   if (!force && !_CheckUpdateContextSizeLimits(VS_UPDATEFLAG_tokens, true)) {
      p_window_id = orig_wid;
      return;
   }

   // Check if the buffer has been modified since the last update
   pk := "POSITIONAL_KEYWORDS.";
   typeless last_modified = _GetBufferInfoHt(pk :+ "LAST_MODIFIED");
   if (last_modified != null && last_modified == p_LastModified) {
      p_window_id = orig_wid;
      return;
   }
   _SetBufferInfoHt(pk:+"LAST_MODIFIED", p_LastModified);

   // Look up the marker type for positional keywords, allocate it if needed
   typeless keyword_type = _GetBufferInfoHt(pk:+"TYPE");
   if (keyword_type == null) {
      keyword_type = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(keyword_type, VSMARKERTYPEFLAG_AUTO_REMOVE);
      //_MarkerTypeSetColorIndex(keyword_type, CFG_KEYWORD);
      _SetBufferInfoHt(pk:+"TYPE", keyword_type);
   }

   // lock the context
   tag_lock_context();
   _UpdateContextAndTokens(true);

   doRefresh := false;
   token_type := 0;
   token_status := 0;
   token_type_name := "";
   token_text := "";
   token_offset := 0;
   token_line := 0;
   marker_id := 0;

   // run through the token list and color the keywords
   _StreamMarkerRemoveAllType(keyword_type);
   token_id := tag_get_first_token();
   while (token_id > 0) {
      token_status = tag_get_token_status(token_id);
      switch (token_status) {
      // NO ERROR STATUS, BUT COULD BE POSITIONAL KEYWORD
      case 0:
         token_type = tag_get_token_type(token_id);
         if (token_type == _asc('K')) {
            tag_get_token_info(token_id,token_type,token_text,token_offset,token_line);
            marker_id = _StreamMarkerAdd(p_window_id, token_offset, length(token_text), true, 0, keyword_type, null);
            if (marker_id >= 0) _StreamMarkerSetTextColor(marker_id, CFG_KEYWORD);
            //say("_UpdatePositionalKeywordColoring: keyword, text="token_text" offset="token_offset);
            doRefresh = true;
         } else if (colorErrors && (token_type == _asc('E') || token_type == _asc('W') || token_type == 128/*garbage char*/)) {
            tag_get_token_info(token_id,token_type,token_text,token_offset,token_line);
            marker_id = _StreamMarkerAdd(p_window_id, token_offset, length(token_text), true, 0, keyword_type, null);
            if (marker_id >= 0) _StreamMarkerSetTextColor(marker_id, CFG_ERROR);
            //say("_UpdatePositionalKeywordColoring: error or warning, text="token_text" offset="token_offset);
            doRefresh = true;
         }
         break;

      // WARNING STATUS, ERROR STATUS or FATAL STATUS
      default:
         tag_get_token_info(token_id,token_type,token_text,token_offset,token_line);
         marker_id = _StreamMarkerAdd(p_window_id, token_offset, length(token_text), true, 0, keyword_type, null);
         if (marker_id >= 0) _StreamMarkerSetTextColor(marker_id, CFG_ERROR);
         //say("_UpdatePositionalKeywordColoring: error or warning, text="token_text" offset="token_offset);
         doRefresh = true;
         break;
      }

      // next please
      token_id = tag_get_next_token(token_id);
   }

   // finished
   tag_unlock_context();

   // do a refresh, if necessary
   if (doRefresh) {
      refresh();
   }

   // and finally, restore the window ID
   p_window_id = orig_wid;
}

