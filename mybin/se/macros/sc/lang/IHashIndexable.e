////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47096 $
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
 * Implementing this interface allows an object to be indexed 
 * using the hash table indexing operator :[]. 
 */
interface IHashIndexable {

   /** 
    * @return
    * Returns an element in a collection, addressing the element by 
    * the given key.  Returns null if there is no such key. 
    * 
    * @param key  key to look up item corresponding to
    */
   typeless _hash_el(_str key);

};

