////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#endregion Imports

namespace sc.collections;

/** 
 * This class is used to represent a stack or Last-in-first-out 
 * collection. 
 */
class Stack {

   // Data
   private typeless m_array[];
   private int m_count = 0;

   /** 
    * Construct a stack, initializing to empty.
    */
   Stack() {
      m_array._makeempty();
   }

   /** 
    * Empties the stack of all items.
    */
   public void clear() {
      m_array._makeempty();
      m_count = 0;
   }

   /** 
    * Returns whether the stack is currently empty of any items.
    * 
    * @return true if no items on stack.
    */
   public boolean isEmpty() {
      return ( m_count == 0 );
   }

   /** 
    * Pushes an item onto top of the stack. This item will be the 
    * first to be popped off. 
    * 
    * @param item  Item to be pushed.
    */
   public void push(typeless item) {
      m_array[m_count++] = item;
   }

   /** 
    * Pops an item off of the stack.  This item will be the last 
    * one that was pushed on the stack. 
    * 
    * @return Item that was popped.
    */
   public typeless pop() {
      if( m_count > 0 ) {
         return m_array[--m_count];
      }
      // Nothing to pop
      return null;
   }

   /** 
    * Returns the n'th item under the top of the stack without 
    * popping it off. n=0 corresponds to the top of stack.
    * 
    * @param n  Index of n'th item under top of stack.
    * 
    * @return n'th item under top of stack.
    */
   public typeless peek(int n=0) {
      if( n < 0 || (m_count - n - 1) < 0 ) {
         return null;
      }
      return ( m_array[m_count - n - 1] );
   }

   /**
    * Return the number of items on the stack.
    * 
    * @return Number of items on the stack.
    */
   public int count() {
      return m_count;
   }

};
