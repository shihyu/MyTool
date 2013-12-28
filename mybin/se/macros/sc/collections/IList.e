////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#pragma option(pedantic, on)
#region Imports
#require "sc/lang/IIterable.e"
#endregion

namespace sc.collections;

/** 
 * Linked list interface.
 */
interface IList : sc.lang.IIterable {

   /**
    * Return iterator pointing to first item in list.
    * 
    * @return Iterator to first item in list. null is returned if 
    *         there are no items.
    */
   typeless front();

   /**
    * Return iterator pointing to last item in list.
    * 
    * @return Iterator to last item in list. null is returned if 
    *         there are no items.
    */
   typeless back();

   /**
    * Get item in list. A copy of the item is returned. 
    * 
    * @param where  Iterator that designates item to get.
    * 
    * @return Item pointed to by iterator.
    */
   typeless get(typeless where);

   /**
    * Return the number of items in the list.
    * 
    * @return Number of items.
    */
   int count();

   /**
    * Find the first item that matches the specified item. Use 
    * {@link findNext} to find the next item. 
    * 
    * @param item  Item to find.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   typeless find(typeless item);

   /**
    * Find the next item, relative to current item given by 
    * where-iterator, that matches current item. Use {@link find} 
    * to find the first item. 
    * 
    * @param where  Iterator pointing to current item.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   typeless findNext(typeless where);

   /**
    * Return iterator pointing to next item in list relative to 
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Next iterator. null if no next item.
    */
   typeless next(typeless where);

   /**
    * Return iterator pointing to previous item in list relative to
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Previous iterator. null if no previous item.
    */
   typeless prev(typeless where);

};
