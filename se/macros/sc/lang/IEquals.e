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
 * By default, Slick-C objects can be compared using a deep 
 * memberwise comparison.  Implementing this interface allows an
 * object to have custom equality and inequality semantics.
 * In effect, this is similar to overriding "operator ==" and 
 * "operator !="  in C++. 
 * <p> 
 * This has no effect on the ":==" and ":!=" operators. 
 */
interface IEquals {

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
    * @return 'true' if this equals 'rhs', false otherwise 
    */
   bool equals(IEquals &rhs);

};

