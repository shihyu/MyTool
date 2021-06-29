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
#require "sc/lang/IIterable.e"

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * This class is used to represent an iterable numeric range. 
 * Used in conjunction with the {@link range} function, it 
 * makes it possible to effeciently iterate over a sequence 
 * of integers. 
 *  
 * @example 
 * <pre> 
 *    foreach(auto i in range(32,64) {
 *       say("i="i);
 *    }
 * </pre> 
 */
class Range : IIterable {

   private int m_start;
   private int m_end;
   private int m_step;

   /** 
    * Construct a Range object, specifying the start, end, 
    * and increment.
    * 
    * @param start_val  inclusive start value
    * @param end_val    inclusive end value
    * @param step_by    step amount (may be negative)
    */
   Range(int start_val=0, int end_val=0, int step_by=1) {
      m_start = start_val;
      m_end   = end_val;
      m_step  = step_by;
   }

   /** 
    * @return  
    * Return the start point (inclusive) for this range object.
    */
   int getStartNumber() {
      return m_start;
   }
   /**
    * @return 
    * Return the end point for this range object.
    */
   int getEndNumber() {
      return m_end;
   }
   /**
    * @return 
    * Return the amount to increment by for this range. 
    */
   int getIncrement() {
      return m_step;
   }

   /**
    * @return
    * Returns the next element in the range. 
    *
    * @param iter
    * If 'iter' is null, the first element is returned.
    * If there are no more elements, 'iter' is set to null.
    */
   typeless _nextel(typeless &iter) {
      if (iter==null) {
         iter=m_start;
         return m_start;
      }
      if ((m_step > 0 && iter+m_step > m_end) || (m_step < 0 && iter+m_step < m_end)) {
         iter=null;
         return null;
      }
      iter += m_step;
      return iter;
   }

};

