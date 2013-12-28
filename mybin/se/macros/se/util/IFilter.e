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

namespace se.util

/**
 * Evaluate a given Slick-C object, not necessarily of the same
 * type as the current object. By implementing this interface,
 * given objects can be checked for membership in a set.
 */
interface IFilter {

   /**
    * Evaluate the given object with a test specific to the current 
    * object. In contrast to IComparable, it is unlikely the two 
    * objects are of the same type, so the implementation should 
    * probably immediately check that the given object is an 
    * instanceof the expected type. 
    * 
    * @param rhs 
    * 
    * @return true if the given object passes the evaluation, false
    *         if it does not.
    */
   boolean filter(typeless &rhs);

};
