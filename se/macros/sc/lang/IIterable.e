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
 * Implementing this interface allows an object to be
 * the target of the "foreach" statement. 
 * <p> 
 * When implementing this interface, it is recommended 
 * to replace the standard "typeless" return type for _nextel() 
 * with the precise type of the element being returned because 
 * the "foreach" statement can infer the type of the iterator 
 * variable using this return type.  If the 'iter' utilizes a 
 * utility class or struct, it is also recommended to use the 
 * precise type for 'iter' rather than "typeless". 
 */
interface IIterable {

   /** 
    * @return 
    * Returns the next element in a class that represents a set of
    * items that can be iterated through using "foreach". 
    * 
    * @param iter
    * If 'iter' is null, the first element is returned. 
    * If there are no more elements, 'iter' is set to null.
    */
   typeless _nextel(typeless &iter);

};

