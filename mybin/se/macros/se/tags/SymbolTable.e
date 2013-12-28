////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45579 $
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
   
   /**
    * Symbol table constructor, initialize table
    */
   SymbolTable() {
      m_symbolTable = null;
   }

   void reset() {
      m_symbolTable = null;
   }

   /**
    * Increment the symbol scope level.
    */
   void pushScope() {
      m_symbolTable[m_symbolTable._length()] = null;
   }

   /**
    * Decrement the symbol scope level.  All symbols at the top-most
    * scope will be removed from the symbol stack.
    */
   void popScope() {
      n := m_symbolTable._length();
      if (n > 0) {
         m_symbolTable._deleteel(n-1);
      }
   }

   /**
    * Add a symbol to the symbol table at the current scope. 
    * If there is already a symbol with that name, then replace 
    * that symbol with the new definition.
    *  
    * @param sym  Symbol information 
    */
   void addSymbol(_str name, SymbolInfo &sym) {
      n := m_symbolTable._length();
      if (n == 0) {
         m_symbolTable[0] = null;
         n++;
      }
      m_symbolTable[n-1]:[name] = sym;
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
      n := m_symbolTable._length();
      if (n > 0) {
         if (m_symbolTable[n-1]._indexin(name)) {
            return &m_symbolTable[n-1]:[name];
         }
      }
      return null;
   }

};

