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
 * Iterator used to point to an item in the map.
 */
interface IMapIterator {

   _str key();

};

/** 
 * Multi-map interface to provide key => value associative 
 * mappings in sorted order, and multiple values may map to the 
 * same key. 
 */
interface IMultiMap : sc.lang.IIterable {

   /**
    * Insert item into map in sorted order. 
    * 
    * @param key    Key of item to insert.
    * @param value  Value of item to insert.
    *
    * @return Iterator pointing to inserted item. null if insert 
    *         failed.
    */
   IMapIterator insert(_str key, typeless value);

   /**
    * Assign to existing item in map. Item pointed to by 
    * where-iterator must exist. 
    *
    * <p>
    *
    * Use {@link insert} to insert a new item. 
    * 
    * @param where  Iterator position of item to assign.
    * @param value  Value to assign to item.
    *
    * @return true on success. false is returned when item pointed 
    *         to by where-iterator is not valid.
    */
   bool assign(IMapIterator where, typeless value);

   /**
    * Change the key that maps to existing item pointed to by
    * where-iterator. 
    *
    * <p>
    *
    * Use {@link assign} to assign a new value to an existing item. 
    * Use {@link insert} to insert a new item. 
    * 
    * @param where  Iterator position of item to re-key.
    * @param key    New key.
    *
    * @return true on success. false is returned when item pointed 
    *         to by where-iterator is not valid.
    */
   bool remap(IMapIterator where, _str key);

   /**
    * Delete item from map.
    *
    * @param where  Iterator pointing to position of item to 
    *               delete.
    *
    * @return Iterator pointing to next remaining item or null if 
    *         no more items.
    */
   IMapIterator delete(IMapIterator where);

   /**
    * Delete all items that map to a specific key.
    *
    * @param key  Key that maps to items to delete.
    */
   void deleteByKey(_str key);

   /**
    * Test for item indexed by specified key.
    * 
    * @param key  Key to test.
    * 
    * @return true if item exists that maps to key.
    */
   bool exists(_str key);

   /**
    * Find the first item that maps to specified key. Use {@link 
    * findNextKey} to find the next item. 
    * 
    * @param key  Key to search on.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   IMapIterator findKey(_str key);

   /**
    * Find the next item, relative to current item given by 
    * where-iterator, that maps to the same key. Use {@link 
    * findKey} to find the first item. 
    * 
    * @param where  Iterator pointing to current item.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   IMapIterator findNextKey(IMapIterator where);

   /**
    * Find the first item with value matching specified value. Use
    * {@link findNextValue} to find the next item. 
    * 
    * @param value  Value to search on.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   IMapIterator findValue(typeless value);

   /**
    * Find the next item, relative to current item given by 
    * where-iterator, that matches item-value. Use {@link 
    * findValue} to find the first item. 
    * 
    * @param where  Iterator pointing to current item.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   IMapIterator findNextValue(IMapIterator where);

   /**
    * Get specific item-value in the map. A copy of the item is 
    * returned. Use {@link getRef to get a reference pointer to an 
    * item. 
    * 
    * @param where  Iterator that designates item to get value for.
    * 
    * @return Item-value pointed to by where-iterator.
    */
   typeless get(IMapIterator where);

   /**
    * Get reference pointer to specific item-value in the map.
    * 
    * @param where  Iterator that designates item to get value for.
    * 
    * @return Reference pointer to item-value.
    */
   typeless* getRef(IMapIterator where);

   /**
    * Count the total number of items in the map.
    * 
    * @return Total number of items in the map.
    */
   int count();

   /**
    * Count the number of items for a particular key.
    * 
    * @return Number of items for key.
    */
   int countByKey(_str key);

   /**
    * Delete all items from the map.
    */
   void clear();

   /**
    * Return iterator pointing to first item in map.
    * 
    * @return Iterator to first item in map. null is returned if 
    *         there are no items.
    */
   IMapIterator front();

   /**
    * Return iterator pointing to last item in map.
    * 
    * @return Iterator to last item in map. null is returned if 
    *         there are no items.
    */
   IMapIterator back();

   /**
    * Return iterator pointing to next item in map relative to 
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Next iterator. null if no next item.
    */
   IMapIterator next(IMapIterator where);

   /**
    * Return iterator pointing to previous item in map relative to
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Previous iterator. null if no previous item.
    */
   IMapIterator prev(IMapIterator where);

};
