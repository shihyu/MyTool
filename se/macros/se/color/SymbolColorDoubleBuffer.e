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
#include "tagsdb.sh"
#import "se/color/SymbolColorRule.e"
#import "se/tags/SymbolInfo.e"
#import "se/tags/SymbolTable.e"

using se.tags.SymbolInfo;

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information
 * within SlickEdit.
 */
namespace se.color;

// the stages of double-buffered symbol coloring
enum DoubleBufferStage {
   // uninitialized
   DBS_UNITIALIZED = -1,
   // go through and get symbols
   DBS_GET_SYMBOLS = 0,
   // match colors to symbols
   DBS_MATCH_COLORS,
   // color the symbols
   DBS_DO_COLOR,
   // create the symbol markerscolor the symbols
   DBS_DO_MARKERS,
};

struct DoubleBufferInfo {
   VS_TAG_IDEXP_INFO m_tagInfo;
   int m_scope;
   int m_offset;
   int m_length;
   int m_streamMarkerId;
   bool m_declaration;
   _str m_lastModified;
   SymbolColorRule m_rule;
   int m_colorId;
   _str m_description;
};

class SymbolColorDoubleBuffer {

   private DoubleBufferInfo m_symbolList[];
   private DoubleBufferStage m_stage = DBS_UNITIALIZED;
   private long m_state = -1;
   private int m_startLine = 0;
   private int m_endLine = 0;

   private int m_streamMarkerType = 0;

   public SymbolColorDoubleBuffer()
   {
      m_symbolList = null;

      m_stage = DBS_UNITIALIZED;
      m_state = -1;
      m_startLine = 0;
      m_endLine = 0;
      resetStreamMarkers();
   }

   public ~SymbolColorDoubleBuffer()
   {
      m_symbolList = null;

      m_stage = DBS_UNITIALIZED;
      m_state = -1;
      m_startLine = 0;
      m_endLine = 0;
      resetStreamMarkers();

      if (m_streamMarkerType > 0) {
         _MarkerTypeFree(m_streamMarkerType);
         m_streamMarkerType = 0;
      }
   }

   /**
    * Saves where we are in the course of symbol coloring
    *
    * @param stage            stage (one of DoubleBufferStage)
    * @param stateInfo        file position
    * @param startLine        start of line range we are currently working on 
    * @param endLine          end of line range we are currently working on 
    */
   public void saveState(DoubleBufferStage stage, long stateInfo, int startLine=0, int endLine=0)
   {
      m_stage = stage;
      m_state = stateInfo;
      if (startLine > 0 && endLine >= startLine) {
         m_startLine = startLine;
         m_endLine = endLine;
      }
   }

   /**
    * Retrieves where we are in the course of symbol coloring so
    * that we can start back in the same place.
    *  
    * @param stage            stage (one of DoubleBufferStage)
    * @param stateInfo        file position
    * @param startLine        start of line range we are currently working on 
    * @param endLine          end of line range we are currently working on 
    */
   public void getState(enum DoubleBufferStage &stage, long &stateInfo, int startLine, int endLine)
   {
      if (startLine > 0 && (startLine != m_startLine || endLine != m_endLine)) {
         stage = DBS_GET_SYMBOLS;
         stateInfo = -1;
         m_symbolList._makeempty();
      } else {
         stage = m_stage;
         stateInfo = m_state;
      }
   }

   /**
    * Sets our info.
    */
   public void reset()
   {
      m_symbolList = null;

      m_stage = DBS_UNITIALIZED;
      m_state = -1;
      m_startLine = 0;
      m_endLine = 0;

      resetStreamMarkers();
   }

   private void resetStreamMarkers()
   {
      if (m_streamMarkerType) {
         _StreamMarkerRemoveAllType(m_streamMarkerType);
      }
   }

   /**
    * Get the stream marker type.  Allocate one if we don't already
    * have one.
    */
   private int getStreamMarkerType()
   {
      if (m_streamMarkerType == 0) {
         m_streamMarkerType = _MarkerTypeAlloc();
         _MarkerTypeSetPriority(m_streamMarkerType, 200);
      }
      return m_streamMarkerType;
   }

   /**
    * Add a symbol to our storage.  We set a StreamMarker there to
    * hold the place in case the text changes (can't rely on just
    * the offset in this case).
    *
    * @param offset
    * @param symbol
    * @param symLength
    */
   public void addSymbol(int offset, VS_TAG_IDEXP_INFO &symbol, int symLength, int symScope)
   {
      DoubleBufferInfo dbi;
      dbi.m_offset = offset;
      dbi.m_streamMarkerId = _StreamMarkerAdd(0, offset, symLength, true, 0, getStreamMarkerType(), "");
      dbi.m_tagInfo = symbol;
      dbi.m_scope = symScope;
      dbi.m_length = symLength;
      dbi.m_declaration = false;
      dbi.m_rule = null;
      dbi.m_lastModified = p_LastModified;
      m_symbolList[m_symbolList._length()] = dbi;
   }

   /**
    * Returns how many symbols we have stored.
    *
    * @return int
    */
   public int getNumSymbols()
   {
      return m_symbolList._length();
   }

   /**
    * Gets the unique scope ID for this symbol.
    *
    * @param index
    *
    * @return int
    */
   public int getSymbolScope(int index)
   {
      if (index < m_symbolList._length()) {
         return m_symbolList[index].m_scope;
      }
      return 0;
   }

   /**
    * Get the offset for the symbol.
    *
    * @param index
    *
    * @return int
    */
   public int getOffset(int index)
   {
      if (index < m_symbolList._length()) {
         maybeUpdateSymbolInfo(index);
         return m_symbolList[index].m_offset;
      }

      return -1;
   }

   /**
    * Retrieve the tag info for the symbol.
    *
    * @param index
    *
    * @return VS_TAG_IDEXP_INFO*
    */
   public VS_TAG_IDEXP_INFO* getSymbol(int index)
   {
      if (index < m_symbolList._length()) {
         maybeUpdateSymbolInfo(index);
         return &m_symbolList[index].m_tagInfo;
      }

      return null;
   }

   /**
    * Get the length in characters for the symbol.
    *
    * @param index
    *
    * @return int
    */
   public int getSymbolLength(int index)
   {
      if (index < m_symbolList._length()) {
         maybeUpdateSymbolInfo(index);
         return m_symbolList[index].m_length;
      }

      return 0;
   }

   /**
    * Mark this symbol as processed and colored by symbol coloring.
    *  Remove the placeholder stream marker.
    *
    * @param index 
    * @param colorId 
    * @param description 
    */
   public void markSymbolColored(int index, int colorId, _str description)
   {
      if (index < m_symbolList._length()) {
         DoubleBufferInfo *psym = &m_symbolList[index];
         if (psym != null) {
            _StreamMarkerRemove(psym->m_streamMarkerId);
            psym->m_streamMarkerId = 0;
            psym->m_colorId = colorId;
            psym->m_description = description;
         }
      }
   }

   /**
    * Create the colored stream marker for this symbol.
    */
   public int createStreamMarker(int index, int markerType)
   {
      if (index < m_symbolList._length()) {
         DoubleBufferInfo *psym = &m_symbolList[index];
         if (psym != null) {
            streamMarkerId := _StreamMarkerAdd(0, 
                                               psym->m_offset,
                                               psym->m_length,
                                               true, 
                                               0, 
                                               markerType, 
                                               psym->m_description);
            if (streamMarkerId >= 0) {
               _StreamMarkerSetTextColor(streamMarkerId, psym->m_colorId);
               return streamMarkerId;
            }
         }
      }
      return INVALID_ARGUMENT_RC;
   }

   /**
    * Determines if the file has changed since we saved this
    * symbol.  If so, updates the offset and length info with
    * stream marker info.
    *
    * @param index
    */
   private void maybeUpdateSymbolInfo(int index)
   {
      if (index < m_symbolList._length()) {
         DoubleBufferInfo *psym = &m_symbolList[index];
         if (psym != null) {
            if (psym->m_lastModified != p_LastModified) {
               psym->m_lastModified = p_LastModified;
               status := _StreamMarkerGet(psym->m_streamMarkerId, auto info);
               if (!status) {
                  psym->m_tagInfo.lastidstart_offset = (int)info.StartOffset;
                  psym->m_offset = (int)info.StartOffset;
                  psym->m_length = (int)info.Length;
               } else {
                  psym->m_tagInfo = null;
                  psym->m_offset = -1;
                  psym->m_length = 0;
               }
            }
         }
      }
   }

   /**
    * Clears out our symbol list.
    */
   public void clearSymbols()
   {
      resetStreamMarkers();
      m_symbolList._makeempty();
   }

   /**
    * Sets whether this symbol is a declaration.
    *
    * @param index
    * @param decl
    */
   public void setSymbolDeclaration(int index, bool decl)
   {
      if (index < m_symbolList._length()) {
         m_symbolList[index].m_declaration = decl;
      }
   }

   /**
    * Returns whether this symbol is a declaration.
    *
    * @param index
    *
    * @return bool
    */
   public bool isSymbolDeclaration(int index)
   {
      if (index < m_symbolList._length()) {
         return m_symbolList[index].m_declaration;
      }

      return false;
   }

   /**
    * Retrieves the symbol color rule for this symbol.
    *
    * @param index
    *
    * @return SymbolColorRule*
    */
   public SymbolColorRule* getSymbolColorRule(int index)
   {
      if (index < m_symbolList._length() && m_symbolList[index].m_rule != null) {
         return &m_symbolList[index].m_rule;
      }

      return null;
   }

   /**
    * Sets the symbol color rule for this symbol.
    *
    * @param index
    * @param rule
    */
   public void setSymbolColorRule(int index, SymbolColorRule &rule)
   {
      if (rule != null && index < m_symbolList._length()) {
         m_symbolList[index].m_rule = rule;
      }
   }
};
