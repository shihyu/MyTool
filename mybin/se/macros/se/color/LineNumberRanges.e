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
#include "slick.sh"

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/** 
 * This class is used to represent an set of ranges of line numbers. 
 * compactly and effeciently as possible without creating a bitset, 
 * since the numbers could be arbitrary in size.  This is used for 
 * keeping track of which lines have already been colored by the 
 * symbol coloring engine. 
 */
class LineNumberRanges {

   private int m_startNums[];
   private int m_endNums[];

   /** 
    * Construct an initially empty set.
    */
   LineNumberRanges() {
      m_startNums = null;
      m_endNums = null;
   }

   /** 
    * Find the segment of contiguous numbers surrounding 
    * the given integer.   
    * 
    * @param n          integer to look for
    * @param spanIndex  (output) set to index of span containing <code>n</code>. 
    *                   if no span contains <code>n</code>, return the index of
    *                   the span that will need to be created to contain <code>n</code>.
    * 
    * @return <code>true</code> if <code>n</code> is in the set, 
    *         <code>false</code> otherwise.
    */
   private boolean findSpanContaining(int n, int *spanIndex=null) {

      // we won't find anything in an empty list, we know that
      if (m_startNums == null) {
         if (spanIndex) *spanIndex = 0;
         return false;
      }

      // Search for the specified item in the array.
      // A binary search is used.
      firstIndex := 0;
      lastIndex  := m_startNums._length()-1;
      while ( firstIndex <= lastIndex ) {
         middleIndex := ( firstIndex + lastIndex ) >> 1;
         middleStart := m_startNums[ middleIndex ];
         middleEnd   := m_endNums[ middleIndex ];
         if ( n >= middleStart && n <= middleEnd ) {
            if (spanIndex) {
               *spanIndex = middleIndex;
            }
            return true;
         }
         if ( n < middleStart ) {
            lastIndex = middleIndex - 1;
         } else {
            firstIndex = middleIndex + 1;
         }
      }

      // did not find a matching range, make sure we are aligned
      // correctly and set the span index where we expect
      if (firstIndex > 0) firstIndex--;
      while (firstIndex < m_startNums._length() && m_startNums[firstIndex] < n) {
         firstIndex++;
      }
      if (spanIndex) {
         *spanIndex = firstIndex;
      }
      return false;
   }

   private void maybeJoinSegment(int index) {
      // try to join the segment after this one
      if (index+1 < m_startNums._length() && m_endNums[index] >= m_startNums[index+1]) {
         if (m_endNums[index] < m_endNums[index+1]) {
            m_endNums[index] = m_endNums[index+1];
         }
         if (m_startNums[index] > m_startNums[index+1]) {
            m_startNums[index] = m_startNums[index+1];
         }
         m_startNums._deleteel(index+1);
         m_endNums._deleteel(index+1);
      }
      // try to join the segment before this one
      if (index > 0 && m_endNums[index-1] >= m_startNums[index]) {
         if (m_endNums[index-1] < m_endNums[index]) {
            m_endNums[index-1] = m_endNums[index];
         }
         if (m_startNums[index-1] > m_startNums[index]) {
            m_startNums[index-1] = m_startNums[index];
         }
         m_startNums._deleteel(index);
         m_endNums._deleteel(index);
      }
   }

   /**
    * Add a single integer to the set.
    * 
    * @param n    Integer to add to the set. 
    */
   void addNumber(int n) {
      spanIndex := 0;
      if (findSpanContaining(n, &spanIndex)) {
         return;
      }
      nearIndex := 0;
      if (findSpanContaining(n-1, &nearIndex)) {
         if (m_endNums[nearIndex] < n) {
            m_endNums[nearIndex] = n;
         }
         maybeJoinSegment(nearIndex);
         return;
      }
      if (findSpanContaining(n+1, &nearIndex)) {
         if (m_startNums[nearIndex] > n) {
            m_startNums[nearIndex] = n;
         }
         maybeJoinSegment(nearIndex);
         return;
      }
      m_startNums._insertel(n, spanIndex);
      m_endNums._insertel(n, spanIndex);
   }

   void addRange(int startNum, int endNum) {
      startSpanIndex := endSpanIndex := 0;
      if (endNum < startNum) {
         tempNum := startNum;
         startNum = endNum;
         endNum = tempNum;
      }
      if (findSpanContaining(startNum, &startSpanIndex) &&
          findSpanContaining(endNum,  &endSpanIndex)) {
         if (startSpanIndex == endSpanIndex) return;
         if (m_endNums[endSpanIndex] > m_endNums[startSpanIndex]) {
            m_endNums[startSpanIndex] = m_endNums[endSpanIndex];
         }
         m_startNums._deleteel(startSpanIndex+1, endSpanIndex-startSpanIndex);
         m_endNums._deleteel(startSpanIndex+1, endSpanIndex-startSpanIndex);
      } else {
         addNumber(startNum);
         addNumber(endNum);
         addRange(startNum, endNum);
      }
   }

   void clearSet() {
      m_startNums = null;
      m_endNums = null;
   }

   boolean isEmpty() {
      return m_startNums._isempty();
   }

   boolean containsNumber(int startNum) {
      return findSpanContaining(startNum);
   }

   boolean containsRange(int startNum, int endNum) {
      if (endNum < startNum) {
         tempNum := startNum;
         startNum = endNum;
         endNum = tempNum;
      }
      spanIndex := 0;
      if (!findSpanContaining(startNum, &spanIndex)) {
         return false;
      }
      if (endNum > m_endNums[spanIndex]) {
         return false;
      }
      return true;
   }

   boolean getRangeSurrounding(int n, int &startNum, int &endNum) {
      spanIndex := 0;
      if (findSpanContaining(n, &spanIndex)) {
         startNum = m_startNums[spanIndex];
         endNum   = m_endNums[spanIndex];
         return true;
      }
      startNum = endNum = 0;
      return false;
   }

   boolean findNearestHole(int n, int minLine, int maxLine,
                        int &startNum, int &endNum, int maxSize) {

      if (m_startNums._length() == 0) {
         startNum = n-(maxSize intdiv 2);
         endNum   = startNum+maxSize;
         if (startNum < minLine) startNum=minLine;
         if (startNum > maxLine) startNum=maxLine;
         if (endNum > maxLine) endNum=maxLine;
         if (endNum < minLine) endNum=minLine;
         return true;
      }

      spanIndex := 0;
      if (findSpanContaining(n, &spanIndex)) {
         startNum = m_startNums[spanIndex];
         endNum   = m_endNums[spanIndex];
         if (n - startNum < endNum - n && startNum > minLine) {
            endNum = startNum-1;
            startNum = startNum - maxSize;
            if (spanIndex > 0 && m_endNums[spanIndex-1]+1 > startNum) {
               startNum = m_endNums[spanIndex-1]+1;
            }
            if (startNum < minLine) startNum=minLine;
            if (startNum > maxLine) startNum=maxLine;
            if (endNum > maxLine) endNum=maxLine;
            if (endNum < minLine) endNum=minLine;
            return true;
         } else if (endNum < maxLine) {
            startNum = endNum+1;
            endNum   = startNum+maxSize;
            if (spanIndex+1 < m_startNums._length() && m_startNums[spanIndex+1]-1 < endNum) {
               endNum = m_startNums[spanIndex+1]-1;
            }
            if (startNum < minLine) startNum=minLine;
            if (startNum > maxLine) startNum=maxLine;
            if (endNum > maxLine) endNum=maxLine;
            if (endNum < minLine) endNum=minLine;
            return true;
         } else {
            return false;
         }
      }

      if (spanIndex >= m_startNums._length()) {
         spanIndex--;
      }
      if (spanIndex > 0 && m_endNums[spanIndex] > maxLine) {
         spanIndex--;
      }
      startNum = m_endNums[spanIndex]+1;
      endNum   = startNum+maxSize;
      if (spanIndex+1 < m_startNums._length() && m_startNums[spanIndex+1]-1 < endNum) {
         endNum = m_startNums[spanIndex+1]-1;
      }
      if (startNum < minLine) startNum=minLine;
      if (startNum > maxLine) startNum=maxLine;
      if (endNum > maxLine) endNum=maxLine;
      if (endNum < minLine) endNum=minLine;
      return true;
   }

   /** 
    * @return 
    * Return the smallest line number in this set. 
    */
   int getMinimum() {
      if (m_startNums == null) return 0;
      return m_startNums[0];
   }
   /** 
    * @return 
    * Return the largest line number in this set.
    */
   int getMaximum() {
      if (m_endNums == null) return 0;
      return m_endNums[m_endNums._length()-1];
   }

};


