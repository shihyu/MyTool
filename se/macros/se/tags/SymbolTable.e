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
#require "se/tags/SymbolInfo.e"
#endregion

/**
 * The "se.tags" namespace contains interfaces and classes that are
 * necessary for working with SlickEdit's tag databases and symbol 
 * analysis. 
 */
namespace se.color;

using se.tags.SymbolInfo;

/**
 * This class is used to keep track of symbol information for symbols 
 * analyzed by symbol coloring.  It is used to avoid doing lookup's of
 * the same symbol in the same scope twice. 
 */
class SymbolTable {
   
   /**
    * This is a stack of hash tables mapping symbol names to 
    * SymbolInfo objects.  We use the stack to keep track of
    * the scope in which symbols are found. 
    */
   private SymbolInfo m_symbolTable[]:[];
   private typeless   m_visitedTable[];
   private int        m_previousScope[];
   private int        m_previousContextId[];
   private int        m_currentScope;
   private int        m_currentContextId;
   
   /**
    * Symbol table constructor, initialize table
    */
   SymbolTable() {
      m_symbolTable  = null;
      m_visitedTable = null;
      m_previousScope = null;
      m_previousContextId = null;
      m_previousScope[0] = 0;
      m_currentScope = 0;
      m_currentContextId = 0;
   }

   void reset() {
      m_symbolTable  = null;
      m_visitedTable = null;
      m_previousScope = null;
      m_previousContextId = null;
      m_previousScope[0] = 0;
      m_currentScope = 0;
      m_currentContextId = 0;
   }

   /**
    * Increment the symbol scope level. 
    *  
    * @return 
    * Return 'false' if the scope depth is too deep. 
    */
   bool pushScope(int contextId=0) {
      new_scope := m_previousScope._length();
      if (new_scope > 1000) return false;
      m_previousScope[new_scope] = m_currentScope;
      m_currentScope = new_scope;
      m_previousContextId[new_scope] = m_currentContextId;
      m_currentContextId = contextId;
      return true;
   }

   /**
    * Adjust the scope level if the current context changes.
    * @param contextId   new current context ID 
    *  
    * @return 
    * Return 'false' if the scope depth is too deep. 
    */
   bool maybePushContextScope(int contextId) {
      // do nothing if current context is same
      if (m_currentContextId == contextId) return false;
      // pop if we moved out of our current scope
      if (contextId == 0) {
         if (m_currentContextId != 0) {
            popScope();
         }
         return false;
      }
      // push if we moved into a new scope
      if (m_currentContextId == 0) {
         return pushScope(contextId);
      }
      // switch scopes or push scope if we move into nested scope
      if (m_currentContextId != 0) {
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, m_currentContextId, auto currentStartSeekPos);
         tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, m_currentContextId, auto currentEndSeekPos);
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, contextId, auto newStartSeekPos);
         tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, contextId, auto newEndSeekPos);
         if (newStartSeekPos >= currentStartSeekPos && newEndSeekPos <= currentEndSeekPos) {
            return pushScope(contextId);
         } else {
            popScope();
            return pushScope(contextId);
         }
      }

      // no scope pushed
      return false;
   }

   /**
    * Decrement the symbol scope level.  All symbols at the top-most
    * scope will be removed from the symbol stack.
    */
   void popScope() {
      n := m_currentScope;
      if (n < m_symbolTable._length()) {
         m_symbolTable[n] = null;
      }
      if (n < m_visitedTable._length()) {
         m_visitedTable[n] = null;
      }
      if (n < m_previousScope._length()) {
         m_currentScope = m_previousScope[n];
      }
      if (n < m_previousContextId._length()) {
         m_currentContextId = m_previousContextId[n];
      }
   }

   /**
    * Return the current symbol scope level.
    */
   int getScopeLevel() {
      return m_currentScope;
   }

   /**
    * Select the given scope level
    */
   void setScopeLevel(int level) {
      if (level < 0) level = 0;
      if (level >= m_previousScope._length()) {
         m_previousScope[level] = m_currentScope;
      }
      if (level >= m_previousScope._length()) {
         m_previousContextId[level] = m_currentContextId;
      }
      m_currentScope = level;
   }

   /**
    * Return a pointer to the symbol lookup cache table.
    */
   typeless *getVisitedCache() {
      n := m_currentScope;
      if (n >= m_visitedTable._length()) {
         m_visitedTable[n] = null;
      }
      return &m_visitedTable[n];
   }

   /**
    * Add a symbol to the symbol table at the current scope. 
    * If there is already a symbol with that name, then replace 
    * that symbol with the new definition.
    *  
    * @param sym  Symbol information 
    */
   void addSymbol(_str name, SymbolInfo &sym) {
      n := m_currentScope;
      if (n >= m_symbolTable._length()) {
         m_symbolTable[n]  = null;
      }
      m_symbolTable[n]:[name] = sym;
   }

   /**
    * Look up a symbol in the symbol table and return a pointer to 
    * it's symbol information.  This will only look in the topmost 
    * scope, otherwise, it might locate a symbol from an outer scope 
    * which is overridden in the current scope. 
    *  
    * @param name    name of symbol to look up 
    * 
    * @return Return a pointer to the corresponding symbol information 
    *         or null if no such symbol was found. 
    */
   SymbolInfo *lookup(_str name) {
      n := m_currentScope;
      if (n < m_symbolTable._length() && m_symbolTable[n]._indexin(name)) {
         return &m_symbolTable[n]:[name];
      }
      return null;
   }

};

