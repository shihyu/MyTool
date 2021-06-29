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
 *  These constants (LESS, EQUAL, and GREATER) are provided for
 *  convenience only.  When calling the IEquals._compare()
 *  method directly, always check for &lt;0 or &gt;0.  Never
 *  check for a return result of LESS or GREATER.
 */
enum CompareResults {
   LESS=-1,    // this object is less than the rhs
   EQUAL=0,    // this object is equal to the rhs
   GREATER=1   // this object is greater than the rhs
};

/** 
 * By default, Slick-C objects can only be compared for 
 * equality.  By implementing this interface, you can 
 * enable a class to use all the relational operators and for an
 * array of class instances to be sorted using the builtin array 
 * _sort() method.  In effect, this is similar to overloading 
 * "operator &lt;", "operator &gt;", "operator &lt;=", "operator 
 * &gt;=", "operator ==" and "operator !="  in C++. 
 * <p> 
 * This has no effect on the ":==" and ":!=" operators. 
 */
interface IComparable {

   /** 
    * Compare this object with the given object of a compatible 
    * class.  The right hand side (rhs) object will always be a 
    * valid and initialized class instance. 
    * <p> 
    * Note that overriding this method effects both the equality 
    * == and inequality != operations 
    * 
    * @param rhs  object on the right hand side of comparison 
    *  
    * @return &lt;0 if 'this' is less than 'rhs', 0 if 'this'
    *         equals 'rhs', and &gt;0 if 'this' is greater than
    *         'rhs'.
    */
   int compare(IComparable &rhs);

};

