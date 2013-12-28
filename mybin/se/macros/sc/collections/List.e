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
#pragma option(pedantic,on)
#region Imports
#require "sc/collections/IList.e"
#require "sc/lang/IIterable.e"
#import "stdcmds.e"
#endregion Imports

namespace sc.collections;


/**
 * Do not use this class directly. Use 
 * <code>List.reverseIterator</code> instead. 
 *
 * <p>
 *
 * Used by List class to provide iteration over items in reverse
 * order with {@link foreach}. 
 */
class ReverseListIterator : sc.lang.IIterable {

   private IList* m_list;

   ReverseListIterator(IList& list=null) {
      // Wrapper IList instance
      m_list = &list;
   }

   ~ReverseListIterator() {
      m_list = null;
   }

   public typeless _nextel(typeless& iter) {
      if( iter != null ) {
         // Next item
         // 2 back + 1 forward = 1 back
         // Why do this? Because _nextel() is supposed to return a
         // reference to the item, and IList cannot return a reference.
         iter = m_list->prev(iter);
         if( iter != null ) {
            iter = m_list->prev(iter);
            return m_list->_nextel(iter);
         }
         // No more items or invalid iterator
         return null;
      } else {
         // First item
         // 2 back + 1 forward = 1 back
         // Why do this? Because _nextel() is supposed to return a
         // reference to the item, and IList cannot return a reference.
         iter = m_list->back();
         if( iter != null ) {
            iter = m_list->prev(iter);
            return m_list->_nextel(iter);
         }
         // No items
         return null;
      }
   }
};

/**
 * Internal use only.
 *
 * <p>
 *
 * Used internally by List to store ordered items. 
 */
struct PrivListNode {
   // Stored item
   typeless item;
   // Index to next in-order ListNode. -1 is None.
   int next;
   // Index to previous in-order ListNode. -1 is None.
   int prev;
   // Used to indicate that node is free
   boolean free;
};

// We need constants for accessing item
// by-index when calling _getfield because
// it is much faster than accessing by-name.
const LISTNODE_ITEM_INDEX = 0;

/** 
 * This class encapsulates the classic doubly-linked list. This 
 * class is used to efficiently insert, delete, and iterate over
 * items. Like all linked lists, random access is not as 
 * efficient as a simple array. 
 *
 * <p><b>Motivation</b></p> 
 *
 * This class uses iterators to point to an item in the list.
 * Insertion, deletion, and iteration all return iterators for
 * maintaining position within a List. Inserting, deleting, and 
 * assigning, or moving/swapping items from the List does not 
 * invalidate existing iterators. This makes it ideal for 
 * implementing other types of collections that require an 
 * ordered list. An ordered associative map is one example. A 
 * handle manager is another example. 
 *
 * <p><b>Inserting</b></p>
 *
 * Use <code>insert</code> to insert an item into the List at a 
 * specific position. Use <code>append</code> to append an item 
 * at end of List. Use <code>prepend</code> to prepend item at
 * beginning of List. Use <code>assign</code> to assign to an 
 * existing item in the List. 
 *
 * <p><b>Deleting</b></p>
 *
 * Use <code>delete</code> to delete item(s) out of the List.
 *
 * <p><b>Searching</b></p>
 *
 * Use <code>find</code> and <code>findNext</code> to find the 
 * first and next item respectively that match against a 
 * specified item. 
 *
 * <p>
 *
 * Note: If items stored in the list are class objects, then
 * they MUST implement one of the IEquals or IComparable
 * interfaces.
 * 
 * <p><b>Retrieving</b></p>
 *
 * Use <code>get</code> to retrieve the item at a specific 
 * iterator-position in the List. 
 *
 * <p><b>Iterating</b></p>
 *
 * Use a {@link foreach} loop to iterate over all items in the 
 * List. See the example. 
 *
 * <p><b>A note about performance</b></p>
 *
 * List is implemented in Slick-C and, for this reason, will 
 * sometimes not be as efficient as a builtin array. Insertion, 
 * deletion, access, and iteration operations may take longer 
 * than a builtin array. If you require a container that is more 
 * performant, you could write it in native C/C++ and export it 
 * to Slick-C. 
 *
 * @example
 * <pre>
 * List list; 
 * list.append(1); 
 * list.append(2); 
 * list.append(3); 
 * foreach( auto item in list ) { 
 *    say('item='item);
 * }
 * </pre>
 * Results in output:<br>
 * <pre>
 * item=1
 * item=2
 * item=3
 * </pre>
 */
class List : IList {

   //
   // Public interfaces
   //

   public typeless* getRef(typeless where);
   public typeless insert(typeless where, typeless item);
   public typeless append(typeless item);
   public typeless prepend(typeless item);
   public boolean move(typeless where_from, typeless where_to);
   public boolean swap(typeless where1, typeless where2);
   public boolean assign(typeless where, typeless item);
   public typeless delete(typeless where);
   public void clear();
   public ReverseListIterator reverseIterator();

   //
   // Private interfaces
   //

   private boolean isValidIterator(typeless iter);
   private int insertImpl(int index, typeless& item);
   private int alloc();
   private void free(int index);
   private void link(int index, int new_index);
   private typeless unlink(typeless where);

   //
   // Private data
   //

   // Storage to enable iteration over entire List with foreach
   private PrivListNode m_store[];
   // Index of first node in storage. m_front=-1 when there are
   // no nodes.
   private int m_front;
   // Index of last node in storage. m_back=-1 when there are
   // no nodes.
   private int m_back;
   // Index of last free node. Free nodes are threaded through storage by
   // using the .prev/.next member. m_free=-1 when there are no free nodes.
   private int m_free;
   // The count of items in the List
   private int m_count;

   /**
    * Constructor.
    */
   List() {
      m_front = -1;
      m_back = -1;
      m_free = -1;
      m_count = 0;
   }

   /**
    * Destructor.
    */
   ~List() {
   }

   /**
    * Return iterator pointing to first item in List.
    * 
    * @return Iterator to first item in List. null is returned if 
    *         there are no items.
    */
   public typeless front() {
      if( m_front < 0 ) {
         return null;
      } else {
         return m_front;
      }
   }

   /**
    * Return iterator pointing to last item in List.
    * 
    * @return Iterator to last item in List. null is returned if 
    *         there are no items.
    */
   public typeless back() {
      if( m_back < 0 ) {
         return null;
      } else {
         return m_back;
      }
   }

   private boolean isValidIterator(typeless iter) {
      if( iter == null ||
          !isinteger(iter) ||
          (int)iter < 0 || (int)iter >= m_store._length() ||
          m_store[(int)iter].free ) {

         // Invalid
         return false;
      } else {
         // Valid
         return true;
      }
   }

   /**
    * Get item in List. A copy of the item is returned. Use {@link 
    * getRef} to get a reference pointer to an item. 
    * 
    * @param where  Iterator that designates item to get.
    * 
    * @return Item pointed to by iterator.
    */
   public typeless get(typeless where) {
      typeless* pitem = this.getRef(where);
      if( !pitem ) {
         // Not found
         return null;
      }
      return *pitem;
   }

   /**
    * Get reference pointer to item in List.
    * 
    * @param where  Iterator that designates item to get.
    * 
    * @return Reference pointer to item.
    */
   public typeless* getRef(typeless where) {
      if( !isValidIterator(where) ) {
         return null;
      }
      return &(m_store[where].item);
   }

   /**
    * Allocate next available node from store.
    * 
    * @return Index in store of new node.
    */
   private int alloc() {

      // Allocate next available storage index
      int new_i;
      if( m_free < 0 ) {
         // No free items, so append to end of storage
         new_i = m_store._length();
      } else {
         // Pop the free index
         new_i = m_free;
         m_free = m_store[m_free].prev;
      }
      m_store[new_i].free = false;
      m_store[new_i].prev = -1;
      m_store[new_i].next = -1;
      return new_i;
   }

   /**
    * Free node from store.
    * 
    * @param index  Index in store of node to free.
    */
   private void free(int index) {

      // This item is now free
      m_store[index].free = true;
      // Thread onto free storage
      m_store[index].prev = m_store[index].next = m_free;
      m_free = index;
   }

   /**
    * Link new node given by new_index into List at index.
    * 
    * @param index      Index in storage to insert new node before. 
    *                   Specify -1 to insert last in order.
    * @param new_index  Index of new node to link in.
    */
   private void link(int index, int new_index) {

      if( index < 0 ) {
         // Insert at back
         if( m_back >= 0 ) {
            m_store[m_back].next = new_index;
         }
         m_store[new_index].prev = m_back;
         m_store[new_index].next = -1;
         m_back = new_index;
      } else {
         // Insert before index
         int prev = m_store[index].prev;
         if( prev >= 0 ) {
            m_store[prev].next = new_index;
         }
         m_store[index].prev = new_index;
         m_store[new_index].prev = prev;
         m_store[new_index].next = index;
         if( index == m_front ) {
            // Inserted at front
            m_front = new_index;
         }
      }
      if( m_front < 0 ) {
         // Inserted first item at back
         m_front = new_index;
      }
      if( m_back < 0 ) {
         // Inserted first item at front
         m_back = new_index;
      }
   }

   /**
    * Unlink node from list in preparation for delete or move 
    * operation. 
    * 
    * @param where  Iterator pointing to item to unlink.
    * 
    * @return Iterator pointing to next remaining item in List or 
    *         null if no more items.
    */
   private typeless unlink(typeless where) {

      // Cut this item out of storage and relink
      int next = m_store[where].next;
      int prev = m_store[where].prev;
      if( prev < 0 ) {
         // Unlinking from the front
         m_front = next;
      } else {
         m_store[prev].next = next;
      }
      if( next < 0 ) {
         // Unlinking from the back
         m_back = prev;
      } else {
         m_store[next].prev = prev;
      }

      // 'where' now points to a "zombie" node, so the caller
      // had better do something quickly.

      return next;
   }

   /**
    * Insert item at storage index. 
    * 
    * @param index  Index in storage to insert item before. Specify
    *               -1 to insert last in order.
    * @param item   Item to insert. 
    *
    * @return Index in m_store of insertion.
    */
   private int insertImpl(int index, typeless& item) {

      // Allocate next av2ailable storage index
      int new_i = this.alloc();

      // Store
      m_store[new_i].item = item;
      ++m_count;

      // Link into list
      link(index,new_i);

      return new_i;
   }

   /**
    * Insert item into List. 
    *
    * <p>
    *
    * Use {@link append} to append to end of List. Use {@link 
    * prepend} to prepend to beginning of List. 
    * 
    * @param where  Iterator position to insert item. Item is 
    *               inserted before this position.
    * @param item   Item to insert.
    *
    * @return Iterator pointing to inserted item. null if insert 
    *         failed (where-iterator was invalid).
    */
   public typeless insert(typeless where, typeless item) {
      if( !isValidIterator(where) ) {
         return null;
      }
      int new_i = this.insertImpl((int)where,item);
      return new_i;
   }

   /**
    * Append item to end of List. 
    *
    * <p>
    *
    * Use {@link insert} to insert into middle of List. Use {@link 
    * prepend} to prepend to beginning of List. 
    * 
    * @param item  Item to insert.
    *
    * @return Iterator pointing to appended item. null if append 
    *         failed.
    */
   public typeless append(typeless item) {
      int new_i = this.insertImpl(-1,item);
      return new_i;
   }

   /**
    * Prepend item to beginning of List. 
    *
    * <p>
    *
    * Use {@link insert} to insert into middle of List. Use {@link 
    * append} to append to end of List. 
    * 
    * @param item  Item to insert.
    *
    * @return Iterator pointing to prepended item. null if prepend 
    *         failed.
    */
   public typeless prepend(typeless item) {
      int new_i = this.insertImpl(m_front,item);
      return new_i;
   }

   /**
    * Move position of item in the List.
    *
    * <p>
    *
    * This differs from a simple delete/insert operation because 
    * the iterator that points to the item does not change. This 
    * operation will not invalidate any stored iterators. 
    * 
    * @param where_from  Iterator pointing to position of item to 
    *                    move.
    * @param where_to    Destination position. Item is moved to a 
    *                    position just previous to the destination
    *                    position. Set to null to move to the back.
    *
    * @return true on success. false is returned if either 
    *         where-from or where-to iterators are invalid.
    */
   public boolean move(typeless where_from, typeless where_to) {
      if( !isValidIterator(where_from) ||
          (where_to != null && !isValidIterator(where_to)) ) {

         return false;
      }
      if( where_from == where_to ) {
         // Nothing to do
         return true;
      }

      // Cut this item out of storage and relink at new position
      this.unlink(where_from);
      if( where_to == null ) {
         // Move to the back
         this.link(-1,where_from);
      } else {
         this.link(where_to,where_from);
      }

      // Success
      return true;
   }

   /**
    * Swap position of two items in the List.
    *
    * <p>
    *
    * This differs from a simple delete/delete/insert/insert 
    * operation because the iterators that point to the items do 
    * not change. This operation will not invalidate any stored 
    * iterators. 
    * 
    * @param where1  Iterator pointing to position of first item 
    *                swap.
    * @param where1  Iterator pointing to position of second item 
    *                swap.
    *
    * @return true on success. false is returned if either 
    *         iterators are invalid.
    */
   public boolean swap(typeless where1, typeless where2) {
      if( !isValidIterator(where1) || !isValidIterator(where2) ) {
         return false;
      }
      if( where1 == where2 ) {
         // Nothing to do
         return true;
      }

      typeless next1 = this.next(where1);
      typeless next2 = this.next(where2);
      if( next1 == where2 ) {
         // Special case: swap 1-with-2 = move 2-to-1
         return this.move(where2,where1);
      } else if( next2 == where1 ) {
         // Special case: swap 2-with-1 = move 1-to-2
         return this.move(where1,where2);
      }

      // Cut first item out of store
      this.unlink(where1);
      // Relink first item
      this.link(where2,where1);

      // Cut second item out of store
      this.unlink(where2);
      // Relink second item at previous position of first item
      this.link(next1,where2);

      // Success
      return true;
   }

   /**
    * Assign to existing item in List. Item pointed to by 
    * where-iterator must exist. 
    *
    * <p>
    *
    * Use {@link insert} to insert into middle of List. Use {@link 
    * append} to append to end of List. Use {@link prepend} to 
    * prepend to beginning of List. 
    * 
    * @param where  Iterator position of item to assign.
    * @param item   Item to assign.
    *
    * @return true on success. false is returned when item pointed 
    *         to by where-iterator is not valid.
    */
   public boolean assign(typeless where, typeless item) {

      if( !isValidIterator(where) ) {
         return false;
      }

      // Success
      m_store[where].item = item;
      return true;
   }

   /**
    * Delete item from List.
    *
    * @param where  Iterator pointing to position of item to
    *               delete.
    *
    * @return Iterator pointing to next remaining item in List or 
    *         null if no more items.
    */
   public typeless delete(typeless where) {

      int next = -1;
      if( isValidIterator(where) ) {

         // Cut this node out of storage and relink
         next = this.unlink(where);

         // Force destruct on stored item
         m_store[where].item = null;

         // Free this node
         this.free(where);

         // We now have one less item
         --m_count;
      }
      return (next < 0) ? null : next;
   }

   /**
    * Delete all items.
    */
   public void clear() {
      m_store._makeempty();
      m_front = m_back = -1;
      m_free = -1;
      m_count = 0;
   }

   /**
    * Return the number of items in the list.
    * 
    * @return Number of items.
    */
   public int count() {
      return m_count;
   }

   public typeless _nextel(typeless& iter) {
      if( iter != null ) {
         // Next item
         iter = m_store[iter].next;
         if( (int)iter >= 0 ) {
            // Lookup by-index is faster than by-name
            return m_store[iter]._getfield(LISTNODE_ITEM_INDEX);
         }
         // No more items
         iter = null;
         return null;
      } else {
         // First item
         if( m_front >= 0 ) {
            iter = m_front;
            // Lookup by-index is faster than by-name
            return m_store[iter]._getfield(LISTNODE_ITEM_INDEX);
         }
         // No items
         return null;
      }
   }

   /**
    * Find the first item that matches the specified item. Use 
    * {@link findNext} to find the next item. 
    * 
    * @param item  Item to find.
    * 
    * @return Iterator pointing to item found. null if no item 
    *         found.
    */
   public typeless find(typeless item) {
      typeless iter = this.front();
      for( ; iter != null; iter=this.next(iter) ) {
         if( m_store[iter].item == item ) {
            // Found it
            return iter;
         }
      }
      // Not found
      return null;
   }

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
   public typeless findNext(typeless where) {

      typeless iter = this.next(where);
      for( ; iter != null; iter=this.next(iter) ) {
         if( m_store[iter].item == m_store[where].item ) {
            // Found it
            return iter;
         }
      }
      // Not found
      return null;
   }

   /**
    * Return iterator pointing to next item in List relative to 
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Next iterator. null if no next item.
    */
   public typeless next(typeless where) {
      if( !isValidIterator(where) || m_store[where].next < 0 ) {
         return null;
      }
      return m_store[where].next;
   }

   /**
    * Return iterator pointing to previous item in List relative to
    * starting where-iterator. 
    * 
    * @param where  Starting iterator.
    * 
    * @return Previous iterator. null if no previous item.
    */
   public typeless prev(typeless where) {
      if( !isValidIterator(where) || m_store[where].prev < 0 ) {
         return null;
      }
      return m_store[where].prev;
   }

   /**
    * Return an iterator used by {@link foreach} to iterate over 
    * list items in reverse order. 
    * 
    * @return Reverse iterator.
    *
    * @example
    * <pre>
    * List list; 
    * list.append(1); 
    * list.append(2); 
    * list.append(3); 
    * auto rev_list = list.reverseIterator();
    * foreach( auto item in rev_list ) {
    *    say('item='item);
    * }
    * </pre>
    * Results in output:<br>
    * <pre>
    * item=3
    * item=2
    * item=1
    * </pre>
    */
   public ReverseListIterator reverseIterator() {
      ReverseListIterator rev_iter(this);
      return rev_iter;
   }

};
