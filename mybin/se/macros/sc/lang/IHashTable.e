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

#require "sc/lang/IHashIndexable.e"

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * Implementing this interface allows an object to be indexed 
 * using the hash table indexing operator :[]. 
 */
interface IHashTable : IHashIndexable {

   /** 
    * @return 
    * Returns a pointer to an element in a collection, addressing the 
    * element by the given key.  If there is no such key, it returns 
    * a pointer to a null item added to the collection at the given key. 
    * 
    * @param key  key to look up item corresponding to 
    * @param obj  the object that the key was derived from 
    */
   typeless *_hash_el_pointer(typeless key);

   /**
    * Delete the item with the given key, if it is found in the hash table
    *
    * @param key  key to look up item corresponding to
    */
   void _delete_el(typeless key);

   /**
    * @return 
    * Returns the number of items in this collection.
    */
   int _hash_length();

};

