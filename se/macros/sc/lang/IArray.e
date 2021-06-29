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
#require "sc/lang/IIndexable.e"

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * Implementing this interface allows an object to be indexed 
 * using the array indexing operator []. 
 */
interface IArray : IIndexable {

   /** 
    * @return
    * Returns a pointer to an element in an array, addressing
    * the element by the given integer index.
    * 
    * @param i  index of item to look up
    */
   typeless *_array_el_pointer(int i);

   /** 
    * Inserts an element into an array class.
    * It also allows you to specify a number of items, 
    * so you can use this method to effeciently initialize an array. 
    * Nofitems defaults to 1.
    *  
    * @param value      value to insert into the array 
    * @param index      index / key corresponding to item to insert
    * @param Nofitems   number of items to insert (arrays only)
    *
    * @example
    * <pre>
    * t[0]=1;
    * t[1]=2;
    * t[2]=3;
    * t._insertel(4,1,2);  // t = {1,4,4,2,3} 
    * </pre>
    */
   void _insert_el(typeless value,int index,int Nofitems=1);

   /**
    * Deletes element from an array class. 
    * Nofitems specifies the number of elements to delete.
    * Nofitems defaults to 1.
    *
    * @param index      index / key corresponding to item to delete
    * @param Nofitems   number of items to delete
    *
    * @example
    * <pre>
    * t[0]=1;
    * t[1]=2;
    * t[2]=3;
    * t._deleteel(1);   // Delete t[1].  t[1] will now contain 3 
    * </pre>
    */
   void _delete_el(int index,int Nofitems=1);

   /**
    * @return 
    * Returns the number of items in this collection.
    */
   int _array_length();

};

