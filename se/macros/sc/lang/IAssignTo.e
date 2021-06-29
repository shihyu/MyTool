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

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * By default, Slick-C objects are deep-copied.  Implementing 
 * this interface allows an object to have custom copy 
 * semantics. 
 *  
 * In effect, this is similar to overriding "operator =" in C++, 
 * but the method binds to the source object, not the 
 * destination object.  In that respect, it is more similar to 
 * overidding the "clone()" method in Java. 
 */
interface IAssignTo {

   /** 
    * Copy this object to the given destination.  The destination 
    * class will always be a valid and initialized class instance. 
    * 
    * @param dest   Destination object, expected to be 
    *               the same type as this class.
    */
   void copy(IAssignTo &dest);

};

