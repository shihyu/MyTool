////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_2WAY_HASHTABLE_H
#define SLICKEDIT_2WAY_HASHTABLE_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "vsmsgdefs_slicki.h"
#include "SEMemory.h"
#include "SEAllocator.h"
#include "SEIterator.h"
#include "SE2WayHashTable.h"
#include <new>
#include <vsdecl.h>

namespace slickedit {

//////////////////////////////////////////////////////////////////////////

/**
 * Manage a bi-directional hash table of elements of types K1 and K2.
 * They keys are mapped in both directions so that you can look up
 * a value of type K1 based on K2 and vice-versa.  The hash table can
 * dynamically grow if needed.  Elememts of the array can be indexed via the
 * [] operator, using keys of type K1.  Elements of the array can also be
 * indexed via the () operator, using keys of type K2. 
 * <P>
 * The hash table can also be searched linearly for a specific reverseKey
 * by providing a comparison function for the specific template
 * class type.
 * <P>
 * You must register hash functions which returns an unsigned integer
 * value for hashing items of types K1 and K2.  You may call the function
 * SEHashString(s) for an effecient, decent hash function for strings.
 * <P>
 * Types K2 and K1 must have default constructors (ie. constructor with no
 * required arguments), copy constructors, and an assignment operators.
 * <P>
 * For comparisons, the == operators is used.  If this operator
 * are not available, a compare proc can also be registered either for
 * keys or for values, or both.
 * <P>
 * The default behavior of the hash table is to specifically not allow
 * duplicates, however, you can force a duplicate key to be inserted
 * using the {@link addDuplicate} method. 
 *
 * @param K1  type of forward key to hash on
 * @param K2  type of reverse key to hash on
 */
template <class K1, class K2>
class SE2WayHashTable : public SEMemory {
private:
   // Key-Key pair, with chaining
   struct KeyPair : public SEMemory {
      // Construct a key to key pair instance
      KeyPair(const K1 &k1, const K2 &k2) {
         forwardKey=k1;
         reverseKey=k2;
         pNextItemForward=0;
         pNextItemReverse=0;
      }

      K1 forwardKey;         // hash key
      K2 reverseKey;         // hash value
      KeyPair *pNextItemForward;  // next in chain for forwardKey
      KeyPair *pNextItemReverse;  // next in chain for reverseKey
   };

public:
   // typedefs for registered hashing and comparison functions
   typedef unsigned int (*ForwardKeyHashProc)(K1 forwardKey);
   typedef unsigned int (*ReverseKeyHashProc)(K2 reverseKey);
   typedef int (*ForwardKeyCompareProc)(K1 k1, K1 k2);
   typedef int (*ReverseKeyCompareProc)(K2 k1, K2 k2);
   typedef void (*ForEachProc)(K1 k1, K2 k2);
   typedef void (*ForEachProcUD)(K1 k1, K2 k2, void *userData);

   /**
    * Construct a new hash table.
    * <P>
    * '89' was chosen as the initial capacity becuase the
    * default algorithm for growing the size of the hash table
    * is to double the size and add one: S(n+1) = 2*S(n)+1
    * Among numbers < 1000, using 89 as a seed produces the
    * most primes less than 100000 in its series (see below,
    * an asterisk indicates a prime number).
    * <P>
    * 89* 179* 359* 719* 1439* 2879* 5759 11519* 23039* 46079 92159
    *
    * @param initialCapacity   Initial number of hash buckets
    *                          89 is a good seed for the series
    */
   SE2WayHashTable(int initialCapacity=89);
   ~SE2WayHashTable();

   /**
    * Copy constructor
    */
   SE2WayHashTable(const SE2WayHashTable<K1,K2>& src);
   /**
    * Assignment operator
    */
   SE2WayHashTable<K1,K2> &operator = (const SE2WayHashTable<K1,K2>& src);

   /**
    * Comparison operators
    */
   bool operator == (const SE2WayHashTable<K1,K2>& lhs) const;
   bool operator != (const SE2WayHashTable<K1,K2>& lhs) const;

   /**
    * Remove and delete all the items from the hash table
    *
    * @param release_table   Also delete the hash table
    */
   void clear(int release_table=0);

   /**
    * Insert a new pair of keys into the hash table.
    * Return an error if either key already exists. 
    *
    * @param forwardKey   forward key value to hash on
    * @param reverseKey   reverse key value to hash on
    *
    * @return 0 if successful. Return <0 on error.
    */
   int add(const K1 &forwardKey, const K2 &reverseKey);

   /**
    * Insert a new pair of keys into the hash table.
    * If either key already exists, a duplicate key will be inserted.
    * 
    * @param forwardKey   forward key value to hash on
    * @param reverseKey   reverse key value to hash on
    * 
    * @return 0 if successful. Return <0 on error.
    */
   int addDuplicate(const K1 &forwardKey, const K2 &reverseKey);

   /**
    * Delete the given forward key pair from the hash table.
    *
    * @param forwardKey   forward key value to hash on
    *
    * @return 0 on success, <0 on error (not found)
    */
   int remove(const K1 &forwardKey);

   /**
    * Delete the given reverse key pair from the hash table.
    *
    * @param reverseKey   reverse key value to hash on
    *
    * @return 0 on success, <0 on error (not found)
    */
   int removeReverse(const K2 &reverseKey);

   /**
    * Delete the given key/value pair from the hash table.
    * <p> 
    * Both keys will be compared.
    * This function is only necessary to use when 
    * the hash set contains duplicate items. 
    *
    * @param forwardKey   forward key value to hash on
    * @param reverseKey   reverse key value to hash on
    *
    * @return 0 on success, <0 on error (not found)
    */
   int removeExact(const K1 &forwardKey, const K2 &reverseKey);

   /**
    * Search for the specified key in the array.
    * A linear search of the hash buckets is used.
    *
    * @param forwardKey   forward key value to hash on
    * @param reverseKey   (output) set to forward mapped key if found
    *
    * @return 0 on success, <0 on error.
    */
   int search(const K1 &forwardKey, K2 &reverseKey) const;

   /**
    * Search for the specified reverse mapping key in the array.
    * A linear search of the hash buckets is used.
    *
    * @param reverseKey   reverse key value to hash on
    * @param forwardKey   (output) set to reverse mapped key if found
    *
    * @return 0 on success, <0 on error.
    */
   int searchReverse(const K2 &reverseKey, K1 &forwardKey) const;

   /**
    * @return The number of pairs stored in the hash table
    */
   int length() const { return _NofItems; }

   /**
   * Set up custom hash function for forward key values
    */
   inline void registerForwardKeyHashProc(ForwardKeyHashProc proc) { _pfnForwardKeyHash=proc; }
   /**
   * Set up custom hash function for reverse key values
    */
   inline void registerReverseKeyHashProc(ReverseKeyHashProc proc) { _pfnReverseKeyHash=proc; }
   /**
    * Set up custom comparison function for comparing forward keys
    * (for types that don't have a working == operator).
    */
   inline void registerForwardKeyCompareProc(ForwardKeyCompareProc proc) { _pfnForwardKeyCompare=proc; }
   /**
    * Set up custom comparison function for comparing reverse keys
    * (for types that don't have a working == operator).
    */
   inline void registerReverseKeyCompareProc(ReverseKeyCompareProc proc) { _pfnReverseKeyCompare=proc; }

   /**
    * Return an array of pointers to the forward keys.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K1** copyKeyPointers() const;
   /**
    * Return an array of pointers to the reverse keys.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K2** copyReverseKeyPointers() const;

   /**
    * Return a copy of the forward keys in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K1* copyKeys() const;
   /**
    * Return a copy of the reverse keys in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K2* copyReverseKeys() const;

   /**
    * Return an array of pointers to the forward keys.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K2** copyItemPointers() const;
   /**
    * Return an array of pointers to the reverse keys.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K1** copyReverseItemPointers() const;

   /**
    * Return a copy of the forward keys in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K2* copyItems() const;
   /**
    * Return a copy of the reverse keys in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   K1* copyReverseItems() const;

   /**
    * Execute an operator for each key pair in the hash table.
    */
   void forEach(ForEachProcUD proc, void* userData) const;
   void forEach(ForEachProc proc) const;

   /**
    * Get the next key pair from this collection, iterating using forward keys.
    * If 'iter' is uninitialized, it will retrieve the first key pair
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to forward key retrieved
    * 
    * @return Returns a pointer to the reverse key, 
    *         NULL if there is no next pair.
    */
   const K2* nextItem(SEIterator &iter, K1 &forwardKey) const;
   K2* nextItem(SEIterator &iter, K1 &forwardKey);
   const K2* nextItem(SEIterator &iter) const;
   K2* nextItem(SEIterator &iter);

   /**
    * Get the next key pair from this collection, iterating using reverse keys.
    * If 'iter' is uninitialized, it will retrieve the first key pair
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to reverse key retrieved
    * 
    * @return Returns a pointer to the forward key, 
    *         NULL if there is no next pair.
    */
   const K1* nextItemReverse(SEIterator &iter, K2 &reverseKey) const;
   K1* nextItemReverse(SEIterator &iter, K2 &reverseKey);
   const K1* nextItemReverse(SEIterator &iter) const;
   K1* nextItemReverse(SEIterator &iter);

   /**
    * Get the previous key pair from this collection. 
    * If 'iter' is unitialized, it will retrieve the last key pair
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to forward key retrieved 
    * 
    * @return Returns a pointer to the reverse key, 
    *         NULL if there is no previous pair. 
    */
   const K2* prevItem(SEIterator &iter, K1 &forwardKey) const;
   K2* prevItem(SEIterator &iter, K1 &forwardKey);
   const K2* prevItem(SEIterator &iter) const;
   K2* prevItem(SEIterator &iter);

   /**
    * Get the previous key pair from this collection, iterating using reverse keys.
    * If 'iter' is unitialized, it will retrieve the last key pair
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to reverse key retrieved
    * 
    * @return Returns a pointer to the forward key, 
    *         NULL if there is no previous pair. 
    */
   const K1* prevItemReverse(SEIterator &iter, K2 &reverseKey) const;
   K1* prevItemReverse(SEIterator &iter, K2 &reverseKey);
   const K1* prevItemReverse(SEIterator &iter) const;
   K1* prevItemReverse(SEIterator &iter);

   /**
    * Get the current key pair pointed to by the given iterator. 
    * If 'iter' is unitialized, it will return NULL.
    * 
    * @param iter    black-box iterator object 
    * @param forwardKey    (output) set to foward retrieved 
    *  
    * @return Returns a pointer to the reverse key, 
    *         NULL if there is no current key pair.
    */
   const K2* currentItem(const SEIterator &iter, K1 &forwardKey) const;
   K2* currentItem(const SEIterator &iter, K1 &forwardKey);

   /**
    * Get the current iterator key. 
    * If 'iter' is uninitialized, the result is undefined. 
    * 
    * @return Returns the current iterator key
    */
   const K1* currentKey(const SEIterator &iter) const;
   K1* currentKey(const SEIterator &iter);
   /**
    * Get the current iterator reverse key. 
    * If 'iter' is uninitialized, the result is undefined. 
    * 
    * @return Returns the current iterator reverse key
    */
   const K2* currentReverseKey(const SEIterator &iter) const;
   K2* currentReverseKey(const SEIterator &iter);

   /**
    * Remove the current key pair pointed to by the given iterator 
    * from the collection.  The next key pair in the collection will 
    * become the new current key pair.
    * 
    * @param iter    black-box iterator object 
    * 
    * @return 0 on success, <0 on error or if 'iter' is unitialized. 
    */
   int removeItem(SEIterator &iter);

   /**
    * Return a pointer to the reverse key corresponding to the
    * given forward key.  This is the classic, fast hash table lookup.
    *
    * @param forwardKey    key value to look up
    *
    * @return pointer to reverse key corresponding to key.
    *         Returns 0 if there is no such key in table.
    */
   K2* operator[](const K1 &forwardKey);
   const K2* operator[](const K1 &forwardKey) const;

   /**
    * Return a pointer to the forward key corresponding to the
    * given reverse key.  This is the classic, fast hash table lookup.
    *
    * @param reverseKey    key value to look up
    *
    * @return pointer to forward key corresponding to key.
    *         Returns 0 if there is no such key in table.
    */
   K1* operator()(const K2 &reverseKey);
   const K1* operator()(const K2 &reverseKey) const;

   /**
    * Is the given forward key in the hash table?
    *
    * @param forwardKey    key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isKey(const K1 &forwardKey) const;

   /**
    * Is the given reverse key in the hash table?
    *
    * @param reverseKey    reverse key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isReverseKey(const K2 &reverseKey) const;

   /**
    * Is the given key pair in the hash table?
    *
    * @param forwardKey   forward key value to look up
    * @param reverseKey   reverse key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isKeyExact(const K1 &forwardKey, const K2 &reverseKey) const;

   /**
    * Rehash the hash table to the indicated number of buckets.
    * Note that the hash table already dynamically grows itself
    * in a fairly effecient manner.  Calling this explicitely
    * with a hash table size less than the number of items in the
    * hash table can result in a great deal of chained items.
    *
    * @param new_size    New number of buckets for hash table
    *                    If not specified, double the current
    *                    hash table size and add 1.
    *
    * @return 0 on success, <0 on error (out of memory)
    */
   int rehash(int new_size=0);

   /**
    * Is this set empty?
    */
   inline bool isEmpty() const {
      return (_NofItems == 0);
   }

   /**
    * Is this set *not* empty?
    */
   inline bool isNotEmpty() const {
      return (_NofItems > 0);
   }

private:

   KeyPair **_forwardKeyList;           // Forward key hash table buffer
   KeyPair **_reverseKeyList;           // Reverse key hash table buffer
                                        //
   int _NofItems;                       // Number of items in hash table
   int _NofChained;                     // Number of chained items
   int _NofAllocated;                   // Hash table capacity

   ForwardKeyCompareProc _pfnForwardKeyCompare;  // Compare proc for keys
   ReverseKeyCompareProc _pfnReverseKeyCompare;  // Compare proc for values
   ForwardKeyHashProc _pfnForwardKeyHash;        // Hash function
   ReverseKeyHashProc _pfnReverseKeyHash;        // Hash function

   // Hash the given forward key to an array index
   inline unsigned int hashForwardKey(const K1 &forwardKey) const
   {
      unsigned int h = _pfnForwardKeyHash(forwardKey);
      return(h % _NofAllocated);
   }
   inline unsigned int hashReverseKey(const K2 &reverseKey) const
   {
      unsigned int h = _pfnReverseKeyHash(reverseKey);
      return(h % _NofAllocated);
   }

   // Returns 1 if k1==k2, 0 otherwise.
   inline int isForwardKeyEqual(const K1 &k1, const K1 &k2) const
   {
      return (_pfnForwardKeyCompare? (_pfnForwardKeyCompare(k1,k2)==0) : (k1==k2));
   }
   // Returns 1 if v1==v2, 0 otherwise.
   inline int isReverseKeyEqual(const K2 &k1, const K2 &k2) const
   {
      return (_pfnReverseKeyCompare? (_pfnReverseKeyCompare(k1,k2)==0) : (k1==k2));
   }

   K2* nextItemInternal(SEIterator &iter, K1 *pKey=NULL) const;
   K2* prevItemInternal(SEIterator &iter, K1 *pKey=NULL) const;
   K2* currentItemInternal(const SEIterator &iter, K1 *pKey=NULL) const;

   K1* nextItemInternalReverse(SEIterator &iter, K2 *pKey=NULL) const;
   K1* prevItemInternalReverse(SEIterator &iter, K2 *pKey=NULL) const;
   K1* currentItemInternalReverse(const SEIterator &iter, K2 *pKey=NULL) const;
};

//////////////////////////////////////////////////////////////////////////

template <class K1, class K2> inline
SE2WayHashTable<K1,K2>::SE2WayHashTable(int initialCapacity) :
   // initial function pointers
   _pfnForwardKeyCompare(0),
   _pfnReverseKeyCompare(0),
   _pfnForwardKeyHash(0),
   _pfnReverseKeyHash(0),
   // initialize list of items
   _forwardKeyList(0),
   _reverseKeyList(0),
   _NofItems(0),
   _NofChained(0),
   _NofAllocated(0)
{
   // allocate list
   if (initialCapacity > 0) {
      _forwardKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (_forwardKeyList != NULL) {
         memset(_forwardKeyList,0,initialCapacity*sizeof(KeyPair*));
         _NofAllocated=initialCapacity;
      }
      _reverseKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (_reverseKeyList != NULL) {
         memset(_reverseKeyList,0,initialCapacity*sizeof(KeyPair*));
         _NofAllocated=initialCapacity;
      }
   }
}
template <class K1, class K2> inline
SE2WayHashTable<K1,K2>::SE2WayHashTable(const SE2WayHashTable<K1,K2>& src) :
   // initial function pointers
   _pfnForwardKeyCompare(src._pfnForwardKeyCompare),
   _pfnReverseKeyCompare(src._pfnReverseKeyCompare),
   _pfnForwardKeyHash(src._pfnForwardKeyHash),
   _pfnReverseKeyHash(src._pfnReverseKeyHash),
   // initialize list of items
   _forwardKeyList(0),
   _reverseKeyList(0),
   _NofItems(src._NofItems),
   _NofChained(src._NofChained),
   _NofAllocated(src._NofAllocated)
{
   // allocate sufficient space
   int initialCapacity = src._NofAllocated;
   if (initialCapacity > 0) {
      _forwardKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (_forwardKeyList != NULL) {
         memset(_forwardKeyList,0,initialCapacity*sizeof(KeyPair*));
         _NofAllocated=initialCapacity;
      }
      _reverseKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (_reverseKeyList != NULL) {
         memset(_reverseKeyList,0,initialCapacity*sizeof(KeyPair*));
         _NofAllocated=initialCapacity;
      }
      if (_forwardKeyList == NULL || _reverseKeyList == NULL) return;
   }

   // now copy in the forward key items
   for (int i=0; i<initialCapacity; ++i) {
      KeyPair *kv = src._forwardKeyList[i];
      KeyPair **ppkv = &_forwardKeyList[i];
      while (kv) {
         // allocate the key-value pair and it to the list
         KeyPair *pkv = new KeyPair(kv->forwardKey,kv->reverseKey);
         *ppkv = pkv;
         ppkv = &pkv->pNextItemForward;
         // get next item from source hash table
         kv=kv->pNextItemForward;
         // insert the item in the reverse hash table
         unsigned int h2 = hashReverseKey(pkv->reverseKey);
         pkv->pNextItemReverse = _reverseKeyList[h2];
         _reverseKeyList[h2] = pkv;
      }
   }
}
template <class K1, class K2> inline
SE2WayHashTable<K1,K2>& SE2WayHashTable<K1,K2>::operator=(const SE2WayHashTable<K1,K2>& src)
{
   if (this != &src) {
      // out with the old
      clear();
      this->_pfnForwardKeyHash = src._pfnForwardKeyHash;
      this->_pfnReverseKeyHash = src._pfnReverseKeyHash;
      this->_pfnForwardKeyCompare = src._pfnForwardKeyCompare;
      this->_pfnReverseKeyCompare = src._pfnReverseKeyCompare;
      this->_NofItems = src._NofItems;
      this->_NofChained = src._NofChained;

      // allocate sufficient space
      int initialCapacity = src._NofAllocated;
      if (initialCapacity > 0) {
         _forwardKeyList = (KeyPair**) SEAllocator::reallocate(_forwardKeyList, sizeof(KeyPair*)*initialCapacity);
         _reverseKeyList = (KeyPair**) SEAllocator::reallocate(_reverseKeyList, sizeof(KeyPair*)*initialCapacity);
         memset(_forwardKeyList,0,initialCapacity*sizeof(KeyPair*));
         memset(_reverseKeyList,0,initialCapacity*sizeof(KeyPair*));
         _NofAllocated=initialCapacity;
      }

      // in with the new
      for (int i=0; i<src._NofAllocated; ++i) {
         KeyPair *kv = src._forwardKeyList[i];
         KeyPair **ppkv = &_forwardKeyList[i];
         while (kv) {
            // allocate the key-value pair and it to the list
            KeyPair *pkv = new KeyPair(kv->forwardKey,kv->reverseKey);
            *ppkv = pkv;
            ppkv = &pkv->pNextItemForward;
            // get next reverseKey from source hash table
            kv=kv->pNextItemForward;
            // insert the item in the reverse hash table
            unsigned int h2 = hashReverseKey(pkv->reverseKey);
            pkv->pNextItemReverse = _reverseKeyList[h2];
            _reverseKeyList[h2] = pkv;
         }
      }
   }
   return *this;
}
template <class K1, class K2> inline
SE2WayHashTable<K1,K2>::~SE2WayHashTable()
{
   clear(1);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::copyKeys() const
{
   // allocate an array of items of type 'K2'
   if ( _NofItems==0 ) return NULL;
   K1 *list = new K1[_NofItems];
   if (!list) return NULL;
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->forwardKey;
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::copyReverseKeys() const
{
   // allocate an array of items of type 'K2'
   if ( _NofItems==0 ) return NULL;
   K2 *list = new K2[_NofItems];
   if (!list) return NULL;
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _reverseKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->reverseKey;
         pkv=pkv->pNextItemReverse;
         ++j;
      }
   }
   // that's all, return result
   return list;
}

template <class K1, class K2> inline
K1** SE2WayHashTable<K1,K2>::copyKeyPointers() const
{
   // allocate an array of items of type 'K2'
   if ( _NofItems==0 ) return NULL;
   K1 **list = new K1*[_NofItems];
   if (!list) return NULL;
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         list[j] = &pkv->forwardKey;
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
   // that's all, return result
   return list;
}

template <class K1, class K2> inline
K2** SE2WayHashTable<K1,K2>::copyReverseKeyPointers() const
{
   // allocate an array of items of type 'K2'
   if ( _NofItems==0 ) return NULL;
   K2 **list = new K2*[_NofItems];
   if (!list) return NULL;
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _reverseKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=&pkv->reverseKey;
         pkv=pkv->pNextItemReverse;
         ++j;
      }
   }
   // that's all, return result
   return list;
}

template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::copyItems() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return NULL;
   K2 *list = new K2[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->reverseKey;
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K1, class K2> inline
K2** SE2WayHashTable<K1,K2>::copyItemPointers() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return NULL;
   K2 **list = new K2*[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=&pkv->reverseKey;
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::copyReverseItems() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return NULL;
   K1 *list = new K1[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _reverseKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->forwardKey;
         pkv=pkv->pNextItemReverse;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K1, class K2> inline
K1** SE2WayHashTable<K1,K2>::copyReverseItemPointers() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return NULL;
   K1 **list = new K1*[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _reverseKeyList[i];
      while (pkv && j<_NofItems) {
         list[j]=&pkv->forwardKey;
         pkv=pkv->pNextItemReverse;
         ++j;
      }
   }
   // that's all, return result
   return list;
}

template <class K1, class K2> inline
void SE2WayHashTable<K1,K2>::forEach(ForEachProcUD proc, void* userData) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->forwardKey, pkv->reverseKey, userData);
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
}
template <class K1, class K2> inline
void SE2WayHashTable<K1,K2>::forEach(ForEachProc proc) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KeyPair *pkv = _forwardKeyList[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->forwardKey, pkv->reverseKey);
         pkv=pkv->pNextItemForward;
         ++j;
      }
   }
}

template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::nextItemInternal(SEIterator &iter, K1 *pKey) const
{
   // first check the linked lists
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      pkv = pkv->pNextItemForward;
      if (pkv != NULL) {
         iter.mpNode = pkv;
         if (pKey != NULL) {
            *pKey = pkv->forwardKey;
         }
         return &pkv->reverseKey;
      }
   }
   // go to the next (or first) slot
   if (iter.mFindFirst) {
      iter.mFindFirst=false;
      iter.mIndex = 0;
   } else if (iter.mIndex < (size_t)_NofAllocated) {
      iter.mIndex++;
   } else {
      iter.mpNode = NULL;
      return NULL;
   }
   // iterate until we find a slot with data in it
   if (_NofItems > 0) {
      while (iter.mIndex < (size_t)_NofAllocated) {
         pkv = _forwardKeyList[iter.mIndex];
         if (pkv != NULL) {
            iter.mpNode = pkv;
            if (pKey != NULL) {
               *pKey = pkv->forwardKey;
            }
            return &pkv->reverseKey;
         }
         iter.mIndex++;
      }
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}

template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::nextItemInternalReverse(SEIterator &iter, K2 *pKey) const
{
   // first check the linked lists
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      pkv = pkv->pNextItemReverse;
      if (pkv != NULL) {
         iter.mpNode = pkv;
         if (pKey != NULL) {
            *pKey = pkv->reverseKey;
         }
         return &pkv->forwardKey;
      }
   }
   // go to the next (or first) slot
   if (iter.mFindFirst) {
      iter.mFindFirst=false;
      iter.mIndex = 0;
   } else if (iter.mIndex < (size_t)_NofAllocated) {
      iter.mIndex++;
   } else {
      iter.mpNode = NULL;
      return NULL;
   }
   // iterate until we find a slot with data in it
   if (_NofItems > 0) {
      while (iter.mIndex < (size_t)_NofAllocated) {
         pkv = _reverseKeyList[iter.mIndex];
         if (pkv != NULL) {
            iter.mpNode = pkv;
            if (pKey != NULL) {
               *pKey = pkv->reverseKey;
            }
            return &pkv->forwardKey;
         }
         iter.mIndex++;
      }
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}

template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::nextItem(SEIterator &iter, K1 &forwardKey) const
{
   return nextItemInternal(iter,&forwardKey);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::nextItem(SEIterator &iter, K1 &forwardKey)
{
   return nextItemInternal(iter,&forwardKey);
}
template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::nextItem(SEIterator &iter) const
{
   return nextItemInternal(iter);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::nextItem(SEIterator &iter)
{
   return nextItemInternal(iter);
}

template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::nextItemReverse(SEIterator &iter, K2 &reverseKey) const
{
   return nextItemInternalReverse(iter,&reverseKey);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::nextItemReverse(SEIterator &iter, K2 &reverseKey)
{
   return nextItemInternalReverse(iter,&reverseKey);
}
template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::nextItemReverse(SEIterator &iter) const
{
   return nextItemInternalReverse(iter);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::nextItemReverse(SEIterator &iter)
{
   return nextItemInternalReverse(iter);
}

template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::prevItemInternal(SEIterator &iter, K1 *pKey) const
{
   // first check the linked lists
   if (!iter.mFindFirst && iter.mpNode != NULL) {
      KeyPair *pkv = _forwardKeyList[iter.mIndex];
      if (pkv != iter.mpNode) {
         while (pkv != NULL) {
            if (pkv->pNextItemForward == iter.mpNode) {
               iter.mpNode = pkv;
               if (pKey != NULL) {
                  *pKey = pkv->forwardKey;
               }
               return &pkv->reverseKey;
            }
            pkv = pkv->pNextItemForward;
         }
      }
      iter.mpNode = NULL;
   }
   // go to the next (or first) slot
   if (iter.mFindFirst) {
      iter.mFindFirst=false;
      iter.mIndex = _NofAllocated-1;
   } else if (iter.mIndex > 0) {
      iter.mIndex--;
   } else {
      iter.mpNode = NULL;
      return NULL;
   }
   // iterate until we find a slot with data in it
   if (_NofItems > 0) {
      for (;;) {
         KeyPair *pkv = _forwardKeyList[iter.mIndex];
         if (pkv != NULL) {
            while (pkv->pNextItemForward != NULL) {
               pkv = pkv->pNextItemForward;
            }
            iter.mpNode = pkv;
            if (pKey != NULL) {
               *pKey = pkv->forwardKey;
            }
            return &pkv->reverseKey;
         }
         if (iter.mIndex==0) break;
         iter.mIndex--;
      }
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}

template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::prevItemInternalReverse(SEIterator &iter, K2 *pKey) const
{
   // first check the linked lists
   if (!iter.mFindFirst && iter.mpNode != NULL) {
      KeyPair *pkv = _reverseKeyList[iter.mIndex];
      if (pkv != iter.mpNode) {
         while (pkv != NULL) {
            if (pkv->pNextItemReverse == iter.mpNode) {
               iter.mpNode = pkv;
               if (pKey != NULL) {
                  *pKey = pkv->reverseKey;
               }
               return &pkv->forwardKey;
            }
            pkv = pkv->pNextItemReverse;
         }
      }
      iter.mpNode = NULL;
   }
   // go to the next (or first) slot
   if (iter.mFindFirst) {
      iter.mFindFirst=false;
      iter.mIndex = _NofAllocated-1;
   } else if (iter.mIndex > 0) {
      iter.mIndex--;
   } else {
      iter.mpNode = NULL;
      return NULL;
   }
   // iterate until we find a slot with data in it
   if (_NofItems > 0) {
      for (;;) {
         KeyPair *pkv = _reverseKeyList[iter.mIndex];
         if (pkv != NULL) {
            while (pkv->pNextItemReverse != NULL) {
               pkv = pkv->pNextItemReverse;
            }
            iter.mpNode = pkv;
            if (pKey != NULL) {
               *pKey = pkv->reverseKey;
            }
            return &pkv->forwardKey;
         }
         if (iter.mIndex==0) break;
         iter.mIndex--;
      }
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}

template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::prevItem(SEIterator &iter, K1 &forwardKey) const
{
   return prevItemInternal(iter, &forwardKey);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::prevItem(SEIterator &iter, K1 &forwardKey)
{
   return prevItemInternal(iter, &forwardKey);
}
template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::prevItem(SEIterator &iter) const
{
   return prevItemInternal(iter);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::prevItem(SEIterator &iter)
{
   return prevItemInternal(iter);
}

template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::prevItemReverse(SEIterator &iter, K2 &reverseKey) const
{
   return prevItemInternalReverse(iter, &reverseKey);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::prevItemReverse(SEIterator &iter, K2 &reverseKey)
{
   return prevItemInternalReverse(iter, &reverseKey);
}
template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::prevItemReverse(SEIterator &iter) const
{
   return prevItemInternalReverse(iter);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::prevItemReverse(SEIterator &iter)
{
   return prevItemInternalReverse(iter);
}

template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::currentItemInternal(const SEIterator &iter, K1 *pKey) const
{
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      if (pKey != NULL) {
         *pKey = pkv->forwardKey;
      }
      return &pkv->reverseKey;
   }
   return NULL;
}
template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::currentItem(const SEIterator &iter, K1 &forwardKey) const
{
   return currentItemInternal(iter, &forwardKey);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::currentItem(const SEIterator &iter, K1 &forwardKey)
{
   return currentItemInternal(iter, &forwardKey);
}

template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::currentKey(const SEIterator &iter) const
{
   const KeyPair *pkv = (const KeyPair*)iter.mpNode;
   if (pkv != NULL) return &pkv->forwardKey;
   return NULL;
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::currentKey(const SEIterator &iter)
{
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (pkv != NULL) return &pkv->forwardKey;
   return NULL;
}

template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::currentReverseKey(const SEIterator &iter) const
{
   const KeyPair *pkv = (const KeyPair*)iter.mpNode;
   if (pkv != NULL) return &pkv->reverseKey;
   return NULL;
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::currentReverseKey(const SEIterator &iter)
{
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (pkv != NULL) return &pkv->reverseKey;
   return NULL;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::removeItem(SEIterator &iter)
{
   KeyPair *pkv = (KeyPair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      iter.mpNode = pkv->pNextItemForward;

      KeyPair *firstNode = _forwardKeyList[iter.mIndex];
      if (firstNode == pkv) {
         _forwardKeyList[iter.mIndex] = pkv->pNextItemForward;
         if (pkv->pNextItemForward != NULL) --_NofChained;
      } else if (firstNode != NULL) {
         while (firstNode->pNextItemForward != NULL) {
            if (firstNode->pNextItemForward == pkv) {
               firstNode->pNextItemForward = pkv->pNextItemForward;
               --_NofChained;
               break;
            }
            firstNode = firstNode->pNextItemForward;
         }
      }

      const unsigned int reverseIndex = hashReverseKey(pkv->reverseKey);
      firstNode = _reverseKeyList[reverseIndex];
      if (firstNode == pkv) {
         _reverseKeyList[reverseIndex] = pkv->pNextItemReverse;
         if (pkv->pNextItemReverse != NULL) --_NofChained;
      } else if (firstNode != NULL) {
         while (firstNode->pNextItemReverse != NULL) {
            if (firstNode->pNextItemReverse == pkv) {
               firstNode->pNextItemReverse = pkv->pNextItemReverse;
               --_NofChained;
               break;
            }
            firstNode = firstNode->pNextItemReverse;
         }
      }

      delete pkv;
      --_NofItems;

      if (iter.mpNode == NULL) {
         // go to the next slot
         if (iter.mIndex < (size_t)_NofAllocated) {
            iter.mIndex++;
         } else {
            return 0;
         }
   
         // iterate until we find a slot with data in it
         while (iter.mIndex < (size_t)_NofAllocated) {
            pkv = _forwardKeyList[iter.mIndex];
            if (pkv != NULL) {
               iter.mpNode = pkv;
               return 0;
            }
            iter.mIndex++;
         }

         // no more slots to test
         return 0;
      }
   }
   return 0;
}

template <class K1, class K2> inline
bool SE2WayHashTable<K1,K2>::isKey(const K1 &forwardKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return false;
   }
   unsigned int h=hashForwardKey(forwardKey);
   KeyPair *p=_forwardKeyList[h];
   while (p) {
      if (isForwardKeyEqual(p->forwardKey,forwardKey)) {
         return true;
      }
      p=p->pNextItemForward;
   }
   return(false);
}

template <class K1, class K2> inline
bool SE2WayHashTable<K1,K2>::isReverseKey(const K2 &reverseKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return false;
   }
   unsigned int h=hashReverseKey(reverseKey);
   KeyPair *p=_reverseKeyList[h];
   while (p) {
      if (isReverseKeyEqual(p->reverseKey,reverseKey)) {
         return true;
      }
      p=p->pNextItemReverse;
   }
   return(false);
}

template <class K1, class K2> inline
bool SE2WayHashTable<K1,K2>::isKeyExact(const K1 &forwardKey, const K2&reverseKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return false;
   }
   const unsigned int h=hashForwardKey(forwardKey);
   KeyPair *p = _forwardKeyList[h];
   while (p) {
      if (isForwardKeyEqual(p->forwardKey,forwardKey) && isReverseKeyEqual(p->reverseKey,reverseKey)) {
         return true;
      }
      p=p->pNextItemForward;
   }
   return false;
}

template <class K1, class K2> inline
const K2* SE2WayHashTable<K1,K2>::operator[](const K1 &forwardKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashForwardKey(forwardKey);
   KeyPair *p=_forwardKeyList[h];
   while (p) {
      if (isForwardKeyEqual(p->forwardKey,forwardKey)) {
         return &p->reverseKey;
      }
      p=p->pNextItemForward;
   }
   return(0);
}
template <class K1, class K2> inline
K2* SE2WayHashTable<K1,K2>::operator[](const K1 &forwardKey)
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashForwardKey(forwardKey);
   KeyPair *p=_forwardKeyList[h];
   while (p) {
      if (isForwardKeyEqual(p->forwardKey,forwardKey)) {
         return &p->reverseKey;
      }
      p=p->pNextItemForward;
   }
   return(0);
}


template <class K1, class K2> inline
const K1* SE2WayHashTable<K1,K2>::operator()(const K2 &reverseKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashReverseKey(reverseKey);
   KeyPair *p=_reverseKeyList[h];
   while (p) {
      if (isReverseKeyEqual(p->reverseKey,reverseKey)) {
         return &p->forwardKey;
      }
      p=p->pNextItemReverse;
   }
   return(0);
}
template <class K1, class K2> inline
K1* SE2WayHashTable<K1,K2>::operator()(const K2 &reverseKey)
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashReverseKey(reverseKey);
   KeyPair *p=_reverseKeyList[h];
   while (p) {
      if (isReverseKeyEqual(p->reverseKey,reverseKey)) {
         return &p->forwardKey;
      }
      p=p->pNextItemReverse;
   }
   return(0);
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::remove(const K1 &forwardKey)
{
   // if we have no items, no need to do anything
   if (_NofItems == 0) {
      return 0;
   }

   // compute hash bucket for the forward key
   const unsigned int h1=hashForwardKey(forwardKey);

   // check if this key is in the forward table
   KeyPair **ppkv = &_forwardKeyList[h1];
   KeyPair *p1 = _forwardKeyList[h1];
   int chaining = ((p1 && p1->pNextItemForward)? 1:0);
   while (p1) {
      if (isForwardKeyEqual(p1->forwardKey,forwardKey)) {
         *ppkv = p1->pNextItemForward;
         break;
      }
      ppkv=&p1->pNextItemForward;
      p1=p1->pNextItemForward;
   }

   // we did not find the key
   if (p1 == NULL) {
      return FILE_NOT_FOUND_RC;
   }

   // compute hash bucket for the reverse key
   const unsigned int h2=hashReverseKey(p1->reverseKey);

   // find the coresponding key in the reverse table
   ppkv = &_reverseKeyList[h2];
   KeyPair *p2 = _reverseKeyList[h2];
   chaining += ((p2 && p2->pNextItemReverse)? 1:0);
   while (p2) {
      if (p2 == p1) {
         *ppkv = p2->pNextItemReverse;
         break;
      }
      ppkv=&p2->pNextItemReverse;
      p2=p2->pNextItemReverse;
   }

   // Finally decrement the item count and delete the key pair.
   _NofChained-=chaining;
   _NofItems--;
   delete(p2);

   // Shrink the hash table if necessary
   if (_NofItems < 64 && _NofAllocated > 512) {
      rehash(89);
   } else if (_NofItems >= 64 && _NofItems < _NofAllocated / 8) {
      rehash(_NofItems*2+1);
   }

   // success
   return 0;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::removeReverse(const K2 &reverseKey)
{
   // if we have no items, no need to do anything
   if (_NofItems == 0) {
      return 0;
   }

   // compute hash bucket for the reverse key
   const unsigned int h2=hashReverseKey(reverseKey);

   // check if the key is in the reverse table
   KeyPair **ppkv = &_reverseKeyList[h2];
   KeyPair *p2 = _reverseKeyList[h2];
   int chaining = ((p2 && p2->pNextItemReverse)? 1:0);
   while (p2) {
      if (isReverseKeyEqual(p2->forwardKey,reverseKey)) {
         *ppkv = p2->pNextItemReverse;
         break;
      }
      ppkv=&p2->pNextItemReverse;
      p2=p2->pNextItemReverse;
   }

   // we did not find the key
   if (p2 == NULL) {
      return FILE_NOT_FOUND_RC;
   }

   // compute hash bucket for the forward key
   const unsigned int h1=hashForwardKey(p2->forwardKey);

   // check if this key is in the forward table
   ppkv = &_forwardKeyList[h1];
   KeyPair *p1 = _forwardKeyList[h1];
   chaining += ((p1 && p1->pNextItemForward)? 1:0);
   while (p1) {
      if (p2 == p1) {
         *ppkv = p1->pNextItemForward;
         break;
      }
      ppkv=&p1->pNextItemForward;
      p1=p1->pNextItemForward;
   }

   // Finally decrement the item count and delete the key pair.
   _NofChained-=chaining;
   _NofItems--;
   delete(p2);

   // Shrink the hash table if necessary
   if (_NofItems < 64 && _NofAllocated > 512) {
      rehash(89);
   } else if (_NofItems >= 64 && _NofItems < _NofAllocated / 8) {
      rehash(_NofItems*2+1);
   }

   // success
   return 0;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::removeExact(const K1 &forwardKey, const K2 &reverseKey)
{
   // if we have no items, no need to do anything
   if (_NofItems == 0) {
      return 0;
   }

   // compute hash bucket for new reverseKey
   unsigned int h1=hashForwardKey(forwardKey);

   // check if this key is already in the table
   KeyPair **ppkv = &_forwardKeyList[h1];
   KeyPair *p1 = _forwardKeyList[h1];
   int chaining = ((p1 && p1->pNextItemForward)? 1:0);
   while (p1) {
      if (isForwardKeyEqual(p1->forwardKey,forwardKey) && isReverseKeyEqual(p1->reverseKey, (K2&)reverseKey)) {
         *ppkv = p1->pNextItemForward;
         break;
      }
      ppkv=&p1->pNextItemForward;
      p1=p1->pNextItemForward;
   }

   // we did not find the key
   if (p1 == NULL) {
      return FILE_NOT_FOUND_RC;
   }

   // compute hash bucket for the reverse key
   const unsigned int h2=hashReverseKey(reverseKey);

   // find the corespponding key in the reverse table
   ppkv = &_reverseKeyList[h2];
   KeyPair *p2 = _reverseKeyList[h2];
   chaining += ((p2 && p2->pNextItemReverse)? 1:0);
   while (p2) {
      if (p2 == p1) {
         *ppkv = p2->pNextItemReverse;
         break;
      }
      ppkv=&p2->pNextItemReverse;
      p2=p2->pNextItemReverse;
   }

   // Finally decrement the item count and delete the key pair.
   _NofChained-=chaining;
   _NofItems--;
   delete(p1);

   // Shrink the hash table if necessary
   if (_NofItems < 64 && _NofAllocated > 512) {
      rehash(89);
   } else if (_NofItems >= 64 && _NofItems < _NofAllocated / 8) {
      rehash(_NofItems*2+1);
   }

   // success
   return 0;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::add(const K1 &forwardKey, const K2 &reverseKey)
{
   // allocate the forward hash table if we do not have one
   if (_forwardKeyList == NULL) {
      const int initialCapacity=89;
      _forwardKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (!_forwardKeyList) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_forwardKeyList,0,initialCapacity*sizeof(KeyPair*));
      _NofAllocated=initialCapacity;
   }

   // allocate the reverse hash table if we do not have one
   if (_reverseKeyList == NULL) {
      const int initialCapacity=89;
      _reverseKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (!_reverseKeyList) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_reverseKeyList,0,initialCapacity*sizeof(KeyPair*));
      _NofAllocated=initialCapacity;
   }

   // Allocate a larger array if needed:
   // If we have as many chained items as we have buckets,
   // then we know that our load factor is at least 2,
   // which means the hash table isn't working at peak
   // effeciency.
   if (_NofChained > _NofAllocated && _NofItems > _NofAllocated) {
      int status=rehash();
      if (status) {
         return(status);
      }
   }

   // compute hash bucket for new forward key
   const unsigned int h1=hashForwardKey(forwardKey);

   // check if this key is already in the forward table
   KeyPair *p1 = _forwardKeyList[h1];
   while (p1) {
      if (isForwardKeyEqual(p1->forwardKey,forwardKey)) {
         return INVALID_ARGUMENT_RC;
      }
      p1 = p1->pNextItemForward;
   }

   // compute hash bucket for new reverse key
   const unsigned int h2=hashReverseKey(reverseKey);

   // check if this key is already in the reverse table
   KeyPair *p2 = _reverseKeyList[h2];
   while (p2) {
      if (isReverseKeyEqual(p2->reverseKey,reverseKey)) {
         return INVALID_ARGUMENT_RC;
      }
      p2 = p2->pNextItemForward;
   }

   // allocate the key-value pair
   KeyPair *pkv = new KeyPair(forwardKey,reverseKey);
   if (!pkv) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // add new key pair to the forward key chain
   pkv->pNextItemForward = _forwardKeyList[h1];
   _forwardKeyList[h1] = pkv;
   if (pkv->pNextItemForward) _NofChained++;

   // add new reverseKey to the chain
   pkv->pNextItemReverse = _reverseKeyList[h2];
   _reverseKeyList[h2] = pkv;
   if (pkv->pNextItemReverse) _NofChained++;

   // Increment the number of items and we are done
   _NofItems++;
   return(0);
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::addDuplicate(const K1 &forwardKey, const K2 &reverseKey)
{
   // allocate the forward hash table if we do not have one
   if (_forwardKeyList == NULL) {
      const int initialCapacity=89;
      _forwardKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (!_forwardKeyList) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_forwardKeyList,0,initialCapacity*sizeof(KeyPair*));
      _NofAllocated=initialCapacity;
   }

   // allocate the reverse hash table if we do not have one
   if (_reverseKeyList == NULL) {
      const int initialCapacity=89;
      _reverseKeyList = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*initialCapacity);
      if (!_reverseKeyList) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_reverseKeyList,0,initialCapacity*sizeof(KeyPair*));
      _NofAllocated=initialCapacity;
   }

   // Allocate a larger array if needed:
   // If we have as many chained items as we have buckets,
   // then we know that our load factor is at least 2,
   // which means the hash table isn't working at peak
   // effeciency.
   if (_NofChained > _NofAllocated && _NofItems > _NofAllocated) {
      int status=rehash();
      if (status) {
         return(status);
      }
   }

   // allocate the key-value pair
   KeyPair *pkv = new KeyPair(forwardKey,reverseKey);
   if (!pkv) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // compute hash bucket for new forward key
   const unsigned int h1=hashForwardKey(forwardKey);

   // add new key pair to the forward key chain
   pkv->pNextItemForward = _forwardKeyList[h1];
   _forwardKeyList[h1] = pkv;
   if (pkv->pNextItemForward) _NofChained++;

   // compute hash bucket for new reverse key
   const unsigned int h2=hashReverseKey(reverseKey);

   // add new reverseKey to the chain
   pkv->pNextItemReverse = _reverseKeyList[h2];
   _reverseKeyList[h2] = pkv;
   if (pkv->pNextItemReverse) _NofChained++;

   // Increment the number of items and we are done
   _NofItems++;
   return(0);
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::search(const K1 &forwardKey, K2 &reverseKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) return STRING_NOT_FOUND_RC;
   const unsigned int h=hashForwardKey(forwardKey);
   const KeyPair *p = _forwardKeyList[h];
   while (p) {
      if (isForwardKeyEqual(p->forwardKey,forwardKey)) {
         reverseKey = p->reverseKey;
         return 0;
      }
      p=p->pNextItemForward;
   }
   return STRING_NOT_FOUND_RC;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::searchReverse(const K2 &reverseKey, K1 &forwardKey) const
{
   // if we have no items, no need to find the reverseKey
   if (_NofItems == 0) return STRING_NOT_FOUND_RC;
   const unsigned int h=hashReverseKey(reverseKey);
   const KeyPair *p = _reverseKeyList[h];
   while (p) {
      if (isReverseKeyEqual(p->reverseKey,reverseKey)) {
         forwardKey = p->forwardKey;
         return 0;
      }
      p=p->pNextItemReverse;
   }
   return STRING_NOT_FOUND_RC;
}

template <class K1, class K2> inline
int SE2WayHashTable<K1,K2>::rehash(int new_NofAllocated)
{
   // Try twice the size of the previous array...
   // + 1 to make it more likely to be prime, and non-zero
   if (new_NofAllocated <= 0) {
      new_NofAllocated=_NofAllocated*2+1;
   }
   KeyPair **new_forward_kvlist = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*new_NofAllocated);
   if (!new_forward_kvlist) {
      return INSUFFICIENT_MEMORY_RC;
   }
   memset(new_forward_kvlist,0,new_NofAllocated*sizeof(KeyPair*));

   KeyPair **new_reverse_kvlist = (KeyPair**) SEAllocator::allocate(sizeof(KeyPair*)*new_NofAllocated);
   if (!new_reverse_kvlist) {
      return INSUFFICIENT_MEMORY_RC;
   }
   memset(new_reverse_kvlist,0,new_NofAllocated*sizeof(KeyPair*));

   // Reset the chaining count
   _NofChained=0;

   // rehash the items in the forward hash table
   int i=0;
   for (i=0; i<_NofAllocated; ++i) {
      KeyPair *p=_forwardKeyList[i];
      while (p) {
         // save the next in chain
         KeyPair *pNextItemForward = p->pNextItemForward;
         // compute hash bucket for forward key
         unsigned int h1 = _pfnForwardKeyHash(p->forwardKey);
         h1 %= new_NofAllocated;
         // add new key to the chain
         p->pNextItemForward=new_forward_kvlist[h1];
         if (p->pNextItemForward) _NofChained++;
         new_forward_kvlist[h1]=p;

         // compute hash bucket for reverse key
         unsigned int h2 = _pfnReverseKeyHash(p->reverseKey);
         h2 %= new_NofAllocated;
         // add new key to the chain
         p->pNextItemReverse=new_reverse_kvlist[h2];
         if (p->pNextItemReverse) _NofChained++;
         new_reverse_kvlist[h2]=p;

         // next please
         p=pNextItemForward;
      }
   }

   // swap in the new lists
   SEAllocator::deallocate(_forwardKeyList);
   SEAllocator::deallocate(_reverseKeyList);
   _forwardKeyList=new_forward_kvlist;
   _reverseKeyList=new_reverse_kvlist;
   _NofAllocated=new_NofAllocated;
   return (0);
}

template <class K1, class K2> inline
void SE2WayHashTable<K1,K2>::clear(int release_table)
{
   for (int i=0; i<_NofAllocated; ++i) {
      KeyPair *p=_forwardKeyList[i];
      while (p) {
         KeyPair *pNextItemForward = p->pNextItemForward;
         delete p;
         p=pNextItemForward;
      }
      _forwardKeyList[i]=0;
      _reverseKeyList[i]=0;
   }

   _NofItems=0;
   _NofChained=0;
   if (release_table) {
      SEAllocator::deallocate(_forwardKeyList);
      _forwardKeyList=0;
      _reverseKeyList=0;
      _NofAllocated=0;
   }
}

template <class K1, class K2> inline
bool SE2WayHashTable<K1,K2>::operator==(const SE2WayHashTable<K1,K2>& lhs) const 
{
   if (this->_NofItems != lhs._NofItems) {
      return false;
   }
   if (this->_pfnForwardKeyHash != lhs._pfnForwardKeyHash ||
       this->_pfnReverseKeyHash != lhs._pfnReverseKeyHash ||
       this->_pfnForwardKeyCompare != lhs._pfnForwardKeyCompare ||
       this->_pfnReverseKeyCompare != lhs._pfnReverseKeyCompare) {
      return false;
   }
   slickedit::SEIterator iter;
   K1 forwardKey;
   for (;;) {
      K2* pItem = (K2*)this->nextItem(iter, forwardKey);
      if (pItem == NULL) break;
      K2* pLHS = (K2*)lhs[forwardKey];
      if (pLHS == NULL) return false;
      if (!isReverseKeyEqual(*pItem,*pLHS)) return false;
   }
   return true;
}

template <class K1, class K2> inline
bool SE2WayHashTable<K1,K2>::operator!=(const SE2WayHashTable<K1,K2>& lhs) const 
{
   return !this->operator ==(lhs);
}

}

#endif // SLICKEDIT_2WAY_HASHTABLE_H
