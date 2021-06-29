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
#require "sc/collections/IMultiMap.e"
#require "sc/lang/IIterable.e"
#require "sc/lang/IHashIndexable.e"
#require "sc/collections/List.e"
#require "sc/lang/IEquals.e"
#require "sc/lang/IToString.e"
#require "sc/collections/MapItemCompare.e"
#require "sc/lang/IComparable.e"
#require "sc/lang/IEquals.e"
#import "stdprocs.e"
#endregion Imports

namespace sc.collections;

using sc.collections.MapItemCompareFunction;
using sc.lang.IComparable;
using sc.lang.IEquals;


/**
 * Do not use this class directly. Use 
 * <code>MultiMap.byKeyIterator</code> instead. 
 *
 * <p>
 *
 * Used by MultiMap class to provide iteration over items that
 * map to a specific key with {@link foreach}. 
 */
class MapByKeyIterator : sc.lang.IIterable {

   private IMultiMap* m_map;
   private _str m_key;

   MapByKeyIterator(IMultiMap& map=null, _str key=null) {
      // Wrapper IMultiMap instance
      m_map = &map;
      m_key = key;
   }

   ~MapByKeyIterator() {
      m_map = null;
      m_key = null;
   }

   public int count() {
      return m_map->countByKey(m_key);
   }

   public typeless _nextel(typeless& iter) {
      if( iter != null ) {
         // Next item
         iter = m_map->findNextKey(iter);
         if( iter != null ) {
            return *(m_map->getRef(iter));
         }
         // No more items or invalid iterator
         return null;
      } else {
         // First item that maps to key
         iter = m_map->findKey(m_key);
         if( iter != null ) {
            return *(m_map->getRef(iter));
         }
         // No items that map to key
         return null;
      }
   }
};

/**
 * Internal use only. 
 *
 * <p>
 *
 * Used internally by MultiMap class to point to an item.
 */
struct InternalMapIterator {

   // Key used to index an item in the map
   _str key;

   // Sort-index iterator pointing to this item
   // in the sort-index.
   typeless siter;

   // Value iterator pointing to value
   typeless viter;

   // Key-index iterator for maintaining ordered list
   // of all values that map to the same key.
   typeless kiter;

};

/**
 * Iterator used to point to an item in the map.
 */
class MapIterator : IMapIterator {

   // The map this iterator belongs to
   private IMultiMap* m_map;

   // Iterator reference pointing to item in map
   private InternalMapIterator* m_imapi;

   public _str key() {
      return m_imapi->key;
   }

};

// Used to get/set with _getfield/_setfield.
static const MAPI_MAP_INDEX   = 0;
static const MAPI_IMAPI_INDEX = 1;

/**
 * Internal use only. 
 *
 * <p>
 *
 * Used internally by MultiMap class to provide sort-ability 
 * when user changes an item-key or item-value. 
 */
class PrivMapIteratorSortWrapper : IComparable {

   // Map instance we are sorting items for
   public IMultiMap* m_map;

   // Iterator pointing to item
   public IMapIterator m_mapi = null;

   // Pointer to comparison function used by map instance
   public MapItemCompareFunction m_pfnCompare;

   public int compare(IComparable& rhs) {
      PrivMapIteratorSortWrapper rhs_wmapi = (PrivMapIteratorSortWrapper)rhs;
      return (*m_pfnCompare)(m_mapi.key(),
                             rhs_wmapi.m_mapi.key(),
                             *(m_map->getRef(m_mapi)),
                             *(rhs_wmapi.m_map->getRef(rhs_wmapi.m_mapi)));
   }
};

/** 
 * This class is used to store, retrieve, and iterate over 
 * items indexed by a key. Items are stored in sorted order. 
 * Multiple items may be indexed by the same key. 
 *
 * <p><b>Motivation</b></p> 
 *
 * It is useful in some circumstances to maintain a sorted 
 * collection of items (a list), AND be able to index item by a
 * unique key (as you would a hash table). Add the ability to 
 * have more than one item that maps to the same key and you 
 * have a MultiMap. One made-up application of a MultiMap would 
 * be to maintain a list of animals (e.g. cat, dog, ibex) sorted
 * by name and indexed by class (e.g. bird, fish, mammal, etc.).
 * See the example. 
 *
 * <p><b>Sorting</b></p>
 *
 * Items are inserted in sorted order and iterated over in
 * sorted order. By default, sort order is ascending 
 * alphabetical by key, but you can change it by specifying a 
 * new comparison function with <code>setCompareFunction</code>. 
 * You can use one of the predefined functions 
 * <code>sc.collections.MapItemCompare.e</code> or define your 
 * own. Set the comparison function to <code>null</code> if you 
 * want no sort order (new items are always appended, assigning 
 * to existing items does not change order). 
 *
 * <p>
 *
 * Note that it is possible to change the compare function with 
 * existing items in the map. Doing so will cause the map items 
 * to be re-sorted (unless you are setting it to 
 * <code>null</code>). Existing iterators are not affected 
 * (iterators point to the same items before and after the 
 * sort). 
 *
 * <p><b>Inserting</b></p>
 *
 * Use <code>insert</code> to insert an item into the map in
 * sorted order. Multiple items-values can map to the same key. 
 * If you want to test for an item that maps to a specific key, 
 * then use <code>exists</code> or <code>findKey</code>. You can
 * not use the <code>:[]</code> operator to insert new items 
 * into the map. Use <code>insert</code> instead. 
 *
 * <p><b>Deleting</b></p>
 *
 * <li>Use <code>delete</code> to delete a specific item out of 
 * the map. 
 * <li>Use <code>deleteByKey</code> to delete all items out of 
 * the map that match a specific key. 
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
 * <li>Use <code>findKey</code> and <code>findNextKey</code> to 
 * search for items matching a specific key. 
 * <li>Use <code>findValue</code> and <code>findNextValue</code>
 * to search for items matching a specific item-value.
 *
 * <p>
 *
 * Note: When using <code>findValue/findNextValue</code>, and 
 * item-values stored in the list are class objects, then the 
 * object class for those values MUST implement one of the 
 * IEquals or IComparable interfaces. 
 *
 * <p><b>Retrieving</b></p>
 *
 * Use <code>get</code> or <code>getRef</code> to retrieve the 
 * value pointed to by an iterator returned by {@link foreach}, 
 * <code>findKey</code>, <code>findValue</code>, or any of the 
 * map navigation methods. 
 *
 * <p>
 *
 * Use <code>byKeyIterator</code> to iterate over items that map
 * to a specific key. See the comment for byKeyIterator for an 
 * example. 
 *
 * <p>
 *
 * A special note about the <code>:[]</code> operator.
 *
 * <p>
 * 
 * Use the <code>:[]</code> operator to retrieve an item-value 
 * that maps to the <b>first</b> in-order occurrence of a given 
 * key. Null is returned if no item exists with that key. Even 
 * though it might seem counter-intuitive, the <code>:[]</code> 
 * operator can be useful in situations where a function returns 
 * a MultiMap result, but you are only interested in the first 
 * unique occurrence of a given key. 
 *
 * <p><b>Iterating</b></p>
 *
 * Use a {@link foreach} loop to iterate over all items in the
 * map. See the example.
 *
 * <p><b>Differences between MultiMap and Slick-C hash 
 * table</b></p> 
 *
 * <li>Multiple values can be stored for the same key.
 *
 * <li>Map items are stored and iterated over in sorted order
 * primarily on the key and, optionally, secondarily on the 
 * item-value. Use <code>setCompareFunction</code> to change the
 * sorting algorithm. 
 *
 * <li>Using {@link foreach} to iterate over all items will
 * return a map iterator and a value. You can retrieve the 
 * item-key from the iterator. See the example. 
 *
 * <p><b>A note about performance</b></p>
 *
 * MultiMap is implemented in Slick-C and, for this reason, 
 * will never be as efficient as a builtin hash table. 
 * Insertion, deletion, access, and iteration operations take 
 * longer than a builtin hash table. If you require a container
 * that is more performant, you could write it in native C/C++
 * and export it to Slick-C. 
 *
 * @example Store sorted numbers.
 * <pre>
 * MultiMap map;
 * map.insert('1',1);
 * map.insert('2',2);
 * map.insert('3',3);
 * MapIterator iter; 
 * int value; 
 * foreach( iter=>value in map ) { 
 *    say('key='iter.key()', value='value);
 * }
 * </pre>
 * Results in output:<br>
 * <pre>
 * key=1, value=1
 * key=2, value=2
 * key=3, value=3
 * </pre>
 *
 * @example More interesting. Store animals indexed by class and 
 *          sorted by animal.
 * <pre>
 * int customCompare(_str key1, _str key2, typeless& value1, typeless& value2)
 * { 
 *    // Sort by animal/value NOT class/key
 *    return strcmp(value1,value2);
 * } 
 * ... 
 * MultiMap map;
 * map.setCompareFunction(customCompare); 
 * map.insert('mammal','ibex'); 
 * map.insert('mammal','dog'); 
 * map.insert('mammal','cat'); 
 * map.insert('bird','owl'); 
 * map.insert('bird','hawk'); 
 * map.insert('fish','koi'); 
 * map.insert('fish','tuna'); 
 *
 * MapIterator iter; 
 * _str value; 
 * foreach( iter=>value in map ) { 
 *    say(value);
 * }
 * </pre>
 * Results in output sorted by animal:<br>
 * <pre>
 * cat 
 * dog 
 * hawk 
 * ibex 
 * koi 
 * owl 
 * tuna 
 * </pre>
 *
 * <pre>
 * _str class_list[] = map.getKeys(); 
 * foreach( auto cls in class_list ) { 
 *    say(cls':');
 *    auto by_class = map.byKeyIterator(cls);
 *    foreach( iter=>value in by_class ) {
 *       say('=>'value);
 *    }
 * } 
 * </pre>
 * Results in output indexed by class, sorted by animal:<br>
 * <pre>
 * bird: 
 * =>hawk 
 * =>owl 
 * fish: 
 * =>koi 
 * =>tuna 
 * mammal: 
 * =>cat 
 * =>dog 
 * =>ibex 
 * </pre>
 */
class MultiMap : IMultiMap, sc.lang.IHashIndexable, sc.lang.IEquals {

   //
   // Public interfaces
   //

   public void setCompareFunction(MapItemCompareFunction pfn);
   public MapByKeyIterator byKeyIterator(_str key);
   public STRARRAY getKeys();

   //
   // Private interfaces
   //

   private MapIterator make_mapi(InternalMapIterator* pimapi);
   private typeless sort_iter(IMapIterator& mapi);
   private typeless value_iter(IMapIterator& mapi);
   private typeless key_iter(IMapIterator& mapi);
   private void sort();
   private void findSortedInsertPos(_str& key, typeless& value,
                                    typeless& siter, typeless& kiter);

   //
   // Private data
   //

   // Item-values
   private List m_value;

   // Hash table index on top of item storage to enable fast map
   // lookup of all items that map to the same key.
   private List m_key_index:[];

   // Sort-order index imposed on item-values to enable fast in-order
   // iteration over entire map with foreach.
   private List m_sort_index;

   // A reverse map of value-iter => sort-iter.
   // Needed for efficient findValue/findNextValue.
   private typeless m_value2sort_index:[];

   // Comparison function pointer for inserting items sorted
   private sc.collections.MapItemCompareFunction m_pfnCompare;

   /**
    * Constructor.
    */
   MultiMap() {
      // Default to case-sensitive, ascending sort order
      m_pfnCompare = sc.collections.compare_map_item_a;
   }

   /**
    * Destructor.
    */
   ~MultiMap() {
   }

   /**
    * Set the comparison function used to store item in sorted
    * order. 
    *
    * <p>
    *
    * By default items are maintained sorted in ascending order by
    * key (secondary sort on value is arbitrary). You can define 
    * your own or use one of the pre-defined functions in 
    * <code>sc.collections.MapItemCompare.e</code>. 
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
    * Note: A custom comparison function MUST handle the case of 
    * null values. 
    *
    * <p>
    *
    * Note that it is possible to change the compare function with 
    * existing items in the map. Doing so will cause the map items 
    * to be re-sorted. Existing iterators are not affected -- 
    * Iterators point to the same items before and after the sort. 
    * 
    * @param pfn  Pointer to comparison function.
    */
   public void setCompareFunction(MapItemCompareFunction pfn) {

      if( pfn == this.m_pfnCompare ) {
         // Nothing to do
         return;
      }

      if( pfn == null || _isfunptr(pfn) ) {
         m_pfnCompare = pfn;
      }

      // Must re-sort
      this.sort();
   }

   /**
    * Sort the sort-index. Used when the comparison function is
    * set and there are already items stored. 
    */
   private void sort() {

      if( !m_pfnCompare ) {
         // No sort order
         return;
      }

      if( m_sort_index.count() <= 1 ) {
         // Already sorted
         return;
      }

      PrivMapIteratorSortWrapper wrapped_mapi();
      wrapped_mapi.m_map = &this;
      wrapped_mapi.m_pfnCompare = this.m_pfnCompare;

      PrivMapIteratorSortWrapper a_wrapped_mapi[];
      InternalMapIterator imapi;
      foreach( imapi in m_sort_index ) {
         // Note: imapi is a copy, so we have to get the real pointer
         wrapped_mapi.m_mapi = make_mapi( m_sort_index.getRef(imapi.siter) );
         a_wrapped_mapi[ a_wrapped_mapi._length() ] = wrapped_mapi;
      }
      a_wrapped_mapi._sort();

      //
      // Fix up the sort-index and key-index with new sort ordering
      //

      _str key;
      foreach( key=>. in m_key_index ) {
         m_key_index:[key].clear();
      }

      InternalMapIterator* pimapi;
      typeless siter;
      int i, len=a_wrapped_mapi._length();
      for( i=0; i < len; ++i ) {
         pimapi = a_wrapped_mapi[i].m_mapi._getfield(MAPI_IMAPI_INDEX);
         // Move each iterator, from first to last in
         // the new sort-order, to the back of the
         // sort-index.
         m_sort_index.move( pimapi->siter , null );
         // Maintain sorted-order per-key
         m_key_index:[ pimapi->key ].append( pimapi->siter );
      }
   }

   /**
    * Find and set position in sort-index and key-index at which to 
    * insert item given by (key,value). 
    * 
    * @param key    (in) Key of item to insert.
    * @param value  (in) Value of item to insert.
    * @param siter  (out) Iterator pointing to position at which to
    *               insert into sort-index. Set to null if position
    *               is past the end (append).
    * @param kiter  (out) Iterator pointing to position at which to 
    *               insert into key-index. Set to null if position
    *               is past the end (append).
    */
   private void findSortedInsertPos(_str& key, typeless& value, typeless& siter,
                                    typeless& kiter) {

      // Default to inserting at end (append)
      siter = null;
      kiter = null;

      if( m_pfnCompare ) {

         if( m_key_index._indexin(key) ) {
            kiter = m_key_index:[key].front();
         }

         InternalMapIterator* pimapi;
         for( siter=m_sort_index.front(); siter != null; siter=m_sort_index.next(siter) ) {
            pimapi = m_sort_index.getRef(siter);
            if( (*m_pfnCompare)( key, pimapi->key, value, *(m_value.getRef(pimapi->viter)) ) < 0 ) {
               // Insert before this position
               break;
            }
            if( key == pimapi->key ) {
               // New item with duplicate key will be inserted AFTER this item
               // in the key-index.
               kiter = m_key_index:[key].next( pimapi->kiter );
            }
         }
      }
   }

   /**
    * Insert item into map in sorted order. 
    * 
    * @param key    Key of item to insert.
    * @param value  Value of item to insert.
    *
    * @return Iterator pointing to inserted item. null if insert 
    *         failed.
    */
   public IMapIterator insert(_str key, typeless value) {

      if( key == null || key == '' ) {
         // Invalid key
         return null;
      }

      // Append value to store
      typeless viter = m_value.append(value);

      // MapIterator
      InternalMapIterator imapi;
      imapi.key = key;
      imapi.viter = viter;
      // Note: .siter and .kiter will be set later

      // Find sorted insertion point into sort-index and key-index
      typeless siter;
      typeless kiter;
      findSortedInsertPos(key,value,siter,kiter);

      // Insert
      if( siter == null ) {
         // Append
         siter = m_sort_index.append(imapi);
      } else {
         // Insert before iter-position
         siter = m_sort_index.insert(siter,imapi);
      }
      if( siter == null ) {
         // Something went wrong, so back out
         m_value.delete(viter);
         return null;
      }

      // Enable fast value-iter => sort-iter lookup
      m_value2sort_index:[viter] = siter;

      // Map item to a key for fast lookup
      if( !m_key_index._indexin(key) ) {
         List tmpl_list;
         m_key_index:[key] = tmpl_list;
      }
      if( kiter == null ) {
         // Append
         kiter = m_key_index:[key].append(siter);
      } else {
         // Insert before iter-position
         kiter = m_key_index:[key].insert(kiter,siter);
      }
      if( kiter == null ) {
         // Something went wrong, so back out
         m_value.delete(viter);
         m_sort_index.delete(siter);
         m_value2sort_index._deleteel(viter);
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef(siter);
      pimapi->kiter = kiter;
      pimapi->siter = siter;

      // Return MapIterator
      return make_mapi(pimapi);
   }

   /**
    * Make a MapIterator for public consumption.
    * 
    * @param pimapi 
    * 
    * @return MapIterator 
    */
   private MapIterator make_mapi(InternalMapIterator* pimapi) {

      if( !pimapi ) {
         return null;
      }

      MapIterator mapi;
      mapi._setfield(MAPI_MAP_INDEX,&this);
      mapi._setfield(MAPI_IMAPI_INDEX,pimapi);
      return mapi;
   }

   /**
    * Extract sort-index iterator from MapIterator. Also used to 
    * ensure we are not passed a bogus MapIterator. 
    * 
    * @param mapi 
    * 
    * @return Sort-index iterator.
    */
   private typeless sort_iter(IMapIterator& mapi) {

      // Sanity please
      if( mapi == null ) {
         return null;
      }
      if( mapi._getfield(MAPI_MAP_INDEX) != &this ) {
         // Iterator does not belong to this map
         return null;
      }
      InternalMapIterator* pimapi = mapi._getfield(MAPI_IMAPI_INDEX);
      if( !pimapi ) {
         return null;
      }

      return pimapi->siter;
   }

   /**
    * Extract value iterator from MapIterator. Also used to ensure 
    * we are not passed a bogus MapIterator. 
    * 
    * @param mapi 
    * 
    * @return Value iterator.
    */
   private typeless value_iter(IMapIterator& mapi) {

      // Sanity please
      if( mapi == null ) {
         return null;
      }
      if( mapi._getfield(MAPI_MAP_INDEX) != &this ) {
         // Iterator does not belong to this map
         return null;
      }
      InternalMapIterator* pimapi = mapi._getfield(MAPI_IMAPI_INDEX);
      if( !pimapi ) {
         return null;
      }

      return pimapi->viter;
   }

   /**
    * Extract key-index iterator from MapIterator. Also used to 
    * ensure we are not passed a bogus MapIterator. 
    * 
    * @param mapi 
    * 
    * @return Key-index iterator.
    */
   private typeless key_iter(IMapIterator& mapi) {

      // Sanity please
      if( mapi == null ) {
         return null;
      }
      if( mapi._getfield(MAPI_MAP_INDEX) != &this ) {
         // Iterator does not belong to this map
         return null;
      }
      InternalMapIterator* pimapi = mapi._getfield(MAPI_IMAPI_INDEX);
      if( !pimapi ) {
         return null;
      }

      return pimapi->kiter;
   }

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
   public bool assign(IMapIterator where, typeless value) {

      typeless viter = value_iter(where);
      if( viter == null ) {
         // Not found
         return false;
      }

      // If there is no comparison function, then change in place (item 
      // is not resorted).
      if( m_pfnCompare ) {

         // Since items can be secondary-sorted on value, we have to
         // do a re-insert (without changing existing iterators).
         _str key = where.key();
         typeless siter;
         typeless kiter;
         findSortedInsertPos(key,value,siter,kiter);
         m_sort_index.move(sort_iter(where),siter);
         m_key_index:[key].move(key_iter(where),kiter);

      }

      // Success
      typeless* pvalue = m_value.getRef(viter);
      *pvalue = value;
      return true;
   }

   /**
    * Change the key that maps to existing item pointed to by 
    * where-iterator. Specified where-iterator remains valid after 
    * the key is changed. 
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
   public bool remap(IMapIterator where, _str key) {

      if( key == null || key == '' ) {
         // Invalid key
         return false;
      }

      typeless viter = value_iter(where);
      if( viter == null ) {
         // Not found
         return false;
      }

      if( where.key() :== key ) {
         // Nothing to do
         return true;
      }

      // Since items are sorted on key, we have to do a
      // re-insert (without changing existing iterators).
      typeless siter;
      typeless kiter;
      findSortedInsertPos(key,*(m_value.getRef(viter)),siter,kiter);

      // Update sort-index
      m_sort_index.move(sort_iter(where),siter);

      // Update key-index
      _str old_key = where.key();
      m_key_index:[old_key].delete( key_iter(where) );
      if( m_key_index:[old_key].count() == 0 ) {
         // No more items map to this key, so clean up
         m_key_index._deleteel(old_key);
      }
      if( !m_key_index._indexin(key) ) {
         List tmpl_list;
         m_key_index:[key] = tmpl_list;
      }
      if( kiter == null ) {
         // Append
         kiter = m_key_index:[key].append( sort_iter(where) );
      } else {
         // Insert before iter-position
         kiter = m_key_index:[key].insert(kiter, sort_iter(where) );
      }
      if( kiter == null ) {
         // Something went wrong, so back out
         m_value.delete(viter);
         m_sort_index.delete( sort_iter(where) );
         m_value2sort_index._deleteel(viter);
         return false;
      }

      // Update InternalMapIterator with new key and key-index iter
      InternalMapIterator* pimapi = m_sort_index.getRef( sort_iter(where) );
      pimapi->key = key;
      pimapi->kiter = kiter;

      // Success
      return true;
   }

   /**
    * Delete item from map.
    *
    * @param where  Iterator pointing to position of item to 
    *               delete.
    *
    * @return Iterator pointing to next remaining item or null if 
    *         no more items.
    */
   public IMapIterator delete(IMapIterator where) {

      InternalMapIterator* pimapi = m_sort_index.getRef( sort_iter(where) );
      if( !pimapi ) {
         // Not found
         return null;
      }

      // Delete from the key-index
      _str key = pimapi->key;
      m_key_index:[key].delete( pimapi->kiter );
      if( m_key_index:[key].count() == 0 ) {
         // No more items map to this key, so clean up
         m_key_index._deleteel(key);
      }

      // Delete value-iter => sort-iter mapping
      m_value2sort_index._deleteel( pimapi->viter );

      // Delete item from storage
      m_value.delete( pimapi->viter );

      // Delete from sort-index and return iterator to next sorted item
      pimapi = m_sort_index.getRef( m_sort_index.delete( pimapi->siter ) );
      return make_mapi(pimapi);
   }

   /**
    * Delete all items that map to a specific key.
    *
    * @param key  Key that maps to items to delete.
    */
   public void deleteByKey(_str key) {

      if( m_key_index._indexin(key) ) {
         // Delete all items that map to key
         InternalMapIterator* pimapi;
         foreach( auto kiter=>auto siter in m_key_index:[key] ) {
            pimapi = m_sort_index.getRef(siter);
            // Delete value
            m_value.delete( pimapi->viter );
            // Delete value-iter => sort-iter mapping
            m_value2sort_index._deleteel( pimapi->viter );
            // Delete from sort-index
            m_sort_index.delete(siter);
         }
         // Delete key-to-item mappings
         m_key_index._deleteel(key);
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
      return ( this.countByKey(key) > 0 );
   }

   /**
    * Find the first item that maps to specified key. Use {@link 
    * findNextKey} to find the next item. 
    * 
    * @param key  Key to search on.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   public IMapIterator findKey(_str key) {

      if( !m_key_index._indexin(key) || m_key_index:[key].count() == 0 ) {
         // No items map to key
         return null;
      }
      // First item
      InternalMapIterator* pimapi = m_sort_index.getRef( m_key_index:[key].get( m_key_index:[key].front() ) );
      return make_mapi(pimapi);
   }

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
   public IMapIterator findNextKey(IMapIterator where) {

      _str key = where.key();
      if( !key ) {
         // Not found
         return null;
      }
      // Next item matching key
      typeless next = m_key_index:[key].next( key_iter(where) );
      if( next == null ) {
         // No more items that map to this key
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef( m_key_index:[key].get(next) );
      return make_mapi(pimapi);
   }

   /**
    * Find the first item with value matching specified value. Use
    * {@link findNextValue} to find the next item. 
    * 
    * @param value  Value to search for.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   public IMapIterator findValue(typeless value) {

      typeless viter = m_value.find(value);
      if( viter == null || !m_value2sort_index._indexin(viter) ) {
         // Not found?
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef( m_value2sort_index:[viter] );
      return make_mapi(pimapi);
   }

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
   public IMapIterator findNextValue(IMapIterator where) {

      typeless viter = m_value.findNext( value_iter(where) );
      if( viter == null || !m_value2sort_index._indexin(viter) ) {
         // Not found?
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef( m_value2sort_index:[viter] );
      return make_mapi(pimapi);
   }

   /**
    * Get specific item-value in the map. A copy of the value is 
    * returned. Use {@link getRef} to get a reference pointer to an
    * item-value. 
    * 
    * @param where  Iterator that designates item to get value for.
    * 
    * @return Item-value pointed to by where-iterator.
    */
   public typeless get(IMapIterator where) {
      return m_value.get( value_iter(where) );
   }

   /**
    * Get reference pointer to specific item-value in the map.
    * 
    * @param where  Iterator that designates item to get value for.
    * 
    * @return Reference pointer to item-value.
    */
   public typeless* getRef(IMapIterator where) {
      return m_value.getRef( value_iter(where) );
   }

   /**
    * Get array of keys in case-sensitive, ascending sorted order.
    * 
    * @return Array of keys.
    */
   public STRARRAY getKeys() {

      _str keys[];
      foreach( auto key=>. in m_key_index ) {
         keys[ keys._length() ] = key;
      }
      keys._sort();
      return keys;
   }

   /**
    * Return an iterator used by {@link foreach} to iterate over 
    * items that map to a specific key. 
    * 
    * @return Key iterator.
    *
    * @example
    * <pre>
    * MultiMap map; 
    * map.insert('fruit','apple'); 
    * map.insert('fruit','banana'); 
    * map.insert('fruit','cherry'); 
    * map.insert('vegetable','asparagus'); 
    * map.insert('vegetable','broccoli'); 
    * map.insert('vegetable','carrot'); 
    * auto fruit_list = map.byKeyIterator('fruit'); 
    * foreach( auto fruit in fruit_list ) { 
    *    say(fruit);
    * }
    * </pre>
    * Results in output:<br>
    * <pre>
    * apple 
    * banana 
    * cherry 
    * </pre>
    */
   public MapByKeyIterator byKeyIterator(_str key) {
      MapByKeyIterator bykey_iter(this,key);
      return bykey_iter;
   }

   /**
    * Count the total number of items in the map.
    * 
    * @return Total number of items in the map.
    */
   public int count() {
      return m_value.count();
   }

   /**
    * Count the number of items for a particular key.
    * 
    * @return Number of items for key.
    */
   public int countByKey(_str key) {
      if( !m_key_index._indexin(key) ) {
         return 0;
      }
      return m_key_index:[key].count();
   }

   /**
    * Delete all items from the map.
    */
   public void clear() {
      m_value.clear();
      m_key_index._makeempty();
      m_sort_index.clear();
      m_value2sort_index._makeempty();
   }

   /**
    * Return iterator pointing to first item in map.
    * 
    * @return Iterator to first item in map. null is returned if 
    *         there are no items.
    */
   public IMapIterator front() {

      typeless siter = m_sort_index.front();
      if( siter == null ) {
         // No items
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef(siter);
      return make_mapi(pimapi);
   }

   /**
    * Return iterator pointing to last item in map.
    * 
    * @return Iterator to last item in map. null is returned if 
    *         there are no items.
    */
   public IMapIterator back() {

      typeless siter = m_sort_index.back();
      if( siter == null ) {
         // No items
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef(siter);
      return make_mapi(pimapi);
   }

   /**
    * Return iterator pointing to next item in map relative to 
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Next iterator. null if no next item.
    */
   public IMapIterator next(IMapIterator where) {

      typeless siter = sort_iter(where);
      if( siter == null ) {
         // Not found - invalid iterator
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef( m_sort_index.next(siter) );
      return make_mapi(pimapi);
   }

   /**
    * Return iterator pointing to previous item in map relative to
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Previous iterator. null if no previous item.
    */
   public IMapIterator prev(IMapIterator where) {

      typeless siter = sort_iter(where);
      if( siter == null ) {
         // Not found - invalid iterator
         return null;
      }
      InternalMapIterator* pimapi = m_sort_index.getRef( m_sort_index.prev(siter) );
      return make_mapi(pimapi);
   }

   /**
    * Return next map item in-order.
    * 
    * @param iter  Starting MapIterator pointing to map item. Set 
    *              to iterator of next item on return or null if no
    *              next item.
    * 
    * @return Value of next item in map.
    */
   public typeless _nextel(typeless& iter) {
      if( iter == null ) {
         // First item
         typeless siter = m_sort_index.front();
         if( siter != null ) {
            InternalMapIterator* pimapi = m_sort_index.getRef(siter);
            iter = make_mapi(pimapi);
            return *(m_value.getRef( pimapi->viter ) );
         }
         // No items
         return null;
      } else {
         // Next item
         typeless siter = m_sort_index.next( sort_iter(iter) );
         if( siter != null ) {
            InternalMapIterator* pimapi = m_sort_index.getRef(siter);
            iter = make_mapi(pimapi);
            return *(m_value.getRef( pimapi->viter ) );
         } else {
            // No more items or invalid iterator
            iter = null;
            return null;
         }
      }
   }

   /**
    * Return <b>first</b> occurrence of map item indexed by key.
    * 
    * @param key 
    * 
    * @return Map item or null if item does not exist.
    */
   public typeless _hash_el(_str key) {

      IMapIterator map_iter = this.findKey(key);
      if( map_iter != null ) {
         return *(this.getRef(map_iter));
      }
      // Not found
      return null;
   }

   public bool equals(IEquals& rhs) {

      if( !(rhs instanceof sc.collections.MultiMap) ) {
         return false;
      }

      if( this.count() != ((MultiMap)rhs).count() ) {
         return false;
      }
      // Order matters
      IMapIterator iter1 = this.front();
      IMapIterator iter2 = ((MultiMap)rhs).front();
      while( iter1 != null ) {
         if( iter1.key() != iter2.key() ) {
            return false;
         }
         typeless val1 = this.get(iter1);
         typeless val2 = ((MultiMap)rhs).get(iter2);
         if( val1 != val2 ) {
            return false;
         }
         iter1 = this.next(iter1);
         iter2 = ((MultiMap)rhs).next(iter2);
      }

      // Equal
      return true;
   }

};
