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
#region Imports
#include "slick.sh"
#require "sc/collections/MultiMap.e"
#require "sc/lang/IIterable.e"
#require "sc/lang/IHashIndexable.e"
#require "sc/collections/MapItemCompare.e"
#endregion Imports

namespace sc.collections;

using sc.collections.MultiMap;
using sc.collections.IMapIterator;

/** 
 * This class is used to store, retrieve, and iterate over 
 * items indexed by a unique key. Items are stored in sorted 
 * order. 
 *
 * <p><b>Motivation</b></p> 
 *
 * It is useful in some circumstances to maintain a sorted 
 * collection of items (a list), AND be able to index item by a
 * unique key (as you would a hash table). A Map gives you both.
 * One made-up application of a Map would be to maintain a list
 * of the countries-of-origin of the immortals (from the film 
 * "Highlander") indexed by name (e.g. Kurgan, MacLeod, Ramirez) 
 * See the example. 
 *
 * <p><b>Sorting</b></p>
 *
 * Items are inserted in sorted order and iterated over in
 * sorted order. By default, sort order is ascending
 * alphabetical by key, but you can change it by specifying a
 * new comparison function with <code>setCompareFunction</code>. 
 * Set the comparison function to <code>null</code> if you 
 * want no sort order (new items are always appended, assigning 
 * to existing items does not change order).  
 *
 * <p>
 *
 * Note that it is possible to change the compare function with 
 * existing items in the map. Doing so will cause the map items 
 * to be re-sorted automatically. 
 *
 * <p><b>Inserting</b></p>
 *
 * Use <code>insert</code> to insert an item into the map in
 * sorted order, indexed by key. If an item already exists in 
 * the map with the same key, then it is replaced. If you want 
 * to test for an item that maps to a specific key, then use 
 * <code>exists</code> or <code>findKey</code>. 
 *
 * <p><b>Deleting</b></p>
 *
 * Use <code>delete</code> to delete an item out of the map that
 * matches a specific key. 
 *
 * <p><b>Navigating</b></p>
 *
 * <li>Use <code>front</code> to get an iterator to the first 
 * item in the map. 
 * <li>Use <code>back</code> to get an iterator to the last item 
 * in the map. 
 * <li>Use <code>next</code> to get an iterator to the next item 
 * in the map relative to a specific iterator position. 
 * <li>Use <code>prev</code> to get an iterator to the previous 
 * item in the map relative to a specific iterator position. 
 *
 * <p><b>Searching</b></p>
 *
 * <li>Use <code>findKey</code> to search for an item matching a
 * specific key.
 * <li>Use <code>findValue</code> to search for items matching a
 * specific item-value.
 *
 * <p>
 *
 * Note: When using <code>findValue</code>, and item-values 
 * stored in the list are class objects, then object class for 
 * those values MUST implement one of the IEquals or IComparable
 * interfaces. 
 *
 * <p><b>Retrieving</b></p>
 *
 * Use the <code>:[]</code> operator to retrieve an item-value 
 * that maps to the given key. Null is returned if no item 
 * exists with that key. You can also use <code>get</code> or 
 * <code>getRef</code> to retrieve the value pointed to by an 
 * iterator returned by {@link foreach}, <code>findKey</code>, 
 * <code>findValue</code>, or any of the map navigation methods. 
 * You can not use the <code>:[]</code> operator to insert new 
 * items into the map. Use <code>insert</code> instead. 
 *
 * <p><b>Iterating</b></p>
 *
 * Use a {@link foreach} loop to iterate over all items in the
 * map. See the example.
 *
 * <p><b>Differences between Map and Slick-C hash 
 * table</b></p> 
 *
 * <li>Map items are stored and iterated over in sorted order
 * primarily on the key and, optionally, secondarily on the 
 * value. Use <code>setCompareFunction</code> to change the 
 * sorting algorithm. 
 *
 * <p><b>A note about performance</b></p>
 *
 * Map is implemented in Slick-C and, for this reason, will 
 * never be as efficient as a builtin hash table. Insertion, 
 * deletion, access, and iteration operations take longer than a 
 * builtin hash table. If you require a container that is more 
 * performant, you could write it in native C/C++ and export it 
 * to Slick-C. 
 *
 * @example Store sorted numbers.
 * <pre>
 * Map map;
 * map.insert('3',3);
 * map.insert('1',1);
 * map.insert('2',2);
 * foreach( auto key=>auto value in map ) { 
 *    say('key='key', value='value);
 * }
 * </pre>
 * Results in output:<br>
 * <pre>
 * key=1, value=1
 * key=2, value=2
 * key=3, value=3
 * </pre>
 *
 * @example Storing countries-of-origin of immortals (from the
 *          film "Highlander") indexed by name.
 * <pre> 
 * Map there_can_be_only_one;
 * there_can_be_only_one.insert('MacLeod','Scotland'); 
 * there_can_be_only_one.insert('Ramirez','Egypt'); 
 * there_can_be_only_one.insert('Kurgan','Russia'); 
 * foreach( auto name=>auto country in map ) {
 *    say(name' was born in 'country);
 * }
 * </pre>
 * Results in output:<br>
 * <pre>
 * Kurgan was born in Russia
 * MacLeod was born in Scotland
 * Ramirez was born in Egypt
 * </pre>
 */
class Map : sc.lang.IIterable, sc.lang.IHashIndexable {

   //
   // Public interfaces
   //

   public void set(_str key, typeless value);
   public _str delete(_str key);
   public bool exists(_str key);
   public _str findValue(typeless value);
   public typeless get(_str key);
   public typeless* getRef(_str key);
   public int count();
   public void clear();
   public _str front();
   public _str back();
   public _str next(_str key);
   public _str prev(_str key);
   public void setCompareFunction(MapItemCompareFunction pfn);

   //
   // Private data
   //

   // A Map is a degenerate MultiMap where only one value can map
   // to a key.
   sc.collections.MultiMap m_map;

   /**
    * Constructor.
    */
   Map() {
   }

   /**
    * Destructor.
    */
   ~Map() {
   }

   /**
    * Set the comparison function used to store item in sorted
    * order.
    *
    * <p>
    *
    * By default items are maintained sorted in ascending order by
    * key (secondary sort on value is arbitrary). You can define 
    * your own or use one of the pre-defined functions. 
    *
    * <p>
    *
    * Set to null for LIFO ordering. In LIFO ordering new items are
    * appended to the end in-order. The difference between 
    * <code>null</code> and {@link 
    * sc.collections.compare_map_item_lifo} is that setting to null
    * will not change the order when assigning to an existing 
    * item. 
    *
    * <p>
    *
    * Note that it is possible to change the compare function with 
    * existing items in the map. Doing so will cause the map items 
    * to be re-sorted automatically. 
    * 
    * @param pfn  Pointer to comparison function.
    */
   public void setCompareFunction(MapItemCompareFunction pfn) {
      m_map.setCompareFunction(pfn);
   }

   /**
    * Insert item into map in sorted order. It item already exist, 
    * it is replaced. Use {@link exists} to test for existence. 
    * 
    * @param key    Key of item to insert.
    * @param value  Value of item to insert.
    */
   public void set(_str key, typeless value) {

      // If item already exists that maps to key, then it is replaced
      IMapIterator iter = m_map.findKey(key);
      if( iter != null ) {
         m_map.assign(iter,value);
      } else {
         m_map.insert(key,value);
      }
   }

   /**
    * Delete item from map.
    *
    * @param key  Key of item to delete.
    *
    * @return Key of next remaining item or null if no more items.
    */
   public _str delete(_str key) {

      IMapIterator iter = m_map.findKey(key);
      if( iter == null ) {
         // Not found
         return null;
      }
      iter = m_map.delete(iter);
      if( iter != null ) {
         return iter.key();
      } else {
         // No more items
         return null;
      }
   }

   /**
    * Test for item indexed by specified key.
    * 
    * @param key  Key to test.
    * 
    * @return true if item exists that maps to key.
    */
   public bool exists(_str key) {
      return m_map.exists(key);
   }

   /**
    * Find the item with value matching specified value. 
    * 
    * @param value  Value to search for.
    * 
    * @return Key of item found. null if no item found. 
    */
   public _str findValue(typeless value) {

      IMapIterator iter = m_map.findValue(value);
      if( iter != null ) {
         return iter.key();
      } else {
         // Not found
         return null;
      }
   }

   /**
    * Get specific item-value in the map. A copy of the item is 
    * returned. Use {@link getRef} to get a reference pointer to an
    * item. Use {@link exists} to test if an item exists that maps 
    * to key. 
    * 
    * @param key  Key of item to get value for.
    * 
    * @return Item-value that maps to key. null if no item exists.
    */
   public typeless get(_str key) {

      IMapIterator iter = m_map.findKey(key);
      if( iter != null ) {
         return m_map.get(iter);
      } else {
         // Not found
         return null;
      }
   }

   /**
    * Get reference pointer to specific item-value in the map.
    * 
    * @param key  Key of item to get value for.
    * 
    * @return Reference pointer to item-value. null if no item 
    *         exists.
    */
   public typeless* getRef(_str key) {

      IMapIterator iter = m_map.findKey(key);
      if( iter != null ) {
         return m_map.getRef(iter);
      } else {
         // Not found
         return null;
      }
   }

   /**
    * Count the total number of items in the map.
    * 
    * @return Total number of items in the map.
    */
   public int count() {
      return m_map.count();
   }

   /**
    * Delete all items from the map.
    */
   public void clear() {
      m_map.clear();
   }

   /**
    * Return key of first item in map.
    * 
    * @return Key of first item in map. null is returned if there 
    *         are no items.
    */
   public _str front() {

      IMapIterator iter = m_map.front();
      if( iter != null ) {
         return iter.key();
      }
      // No items
      return null;
   }

   /**
    * Return key of last item in map.
    * 
    * @return Key of last item in map. null is returned if there 
    *         are no items.
    */
   public _str back() {

      IMapIterator iter = m_map.back();
      if( iter != null ) {
         return iter.key();
      }
      // No items
      return null;
   }

   /**
    * Return key of next item in map relative to starting key. 
    * 
    * @param key  Starting key.
    * 
    * @return Next key. null if no next item.
    */
   public _str next(_str key) {

      IMapIterator iter = m_map.next( m_map.findKey(key) );
      if( iter != null ) {
         return iter.key();
      }
      // No next item
      return null;
   }

   /**
    * Return key of previous item in map relative to starting
    * key. 
    * 
    * @param key  Starting key.
    * 
    * @return Previous key. null if no previous item.
    */
   public _str prev(_str key) {

      IMapIterator iter = m_map.prev( m_map.findKey(key) );
      if( iter != null ) {
         return iter.key();
      }
      // No previous item
      return null;
   }

   /**
    * Return next map item in-order.
    * 
    * @param iter  Starting item-key. Set to item-key of next item 
    *              on return or null if no next item.
    * 
    * @return Value of next item in map.
    */
   public typeless _nextel(typeless& iter) {

      if( iter == null ) {
         // First item
         IMapIterator map_iter = m_map.front();
         if( map_iter != null ) {
            iter = map_iter.key();
            return *(m_map.getRef(map_iter));
         }
         // No items
         return null;
      } else {
         // Next item
         IMapIterator map_iter = m_map.next( m_map.findKey(iter) );
         if( map_iter != null ) {
            iter = map_iter.key();
            return *(m_map.getRef(map_iter));
         } else {
            // No more items or invalid iterator
            iter = null;
            return null;
         }
         // No more items or invalid iterator
         return null;
      }
   }

   public typeless _hash_el(_str key) {

      IMapIterator map_iter = m_map.findKey(key);
      if( map_iter != null ) {
         return *(m_map.getRef(map_iter));
      }
      // Not found
      return null;
   }

};
