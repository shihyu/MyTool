////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_HASHTABLE_H
#define SLICKEDIT_HASHTABLE_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "vsmsgdefs_slicki.h"
#include "SEMemory.h"
#include "SEAllocator.h"
#include "SEIterator.h"
#include <new>
#include <vsdecl.h>

namespace slickedit {

//////////////////////////////////////////////////////////////////////////

/**
 * Compute a hash value for the given string.  This particular
 * hashing algorithm is designed to be particularly effective for
 * hashing "C" style identifiers.
 *
 * @param p    string to compute hash value for
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashString(const char *p);
VSDLLEXPORT unsigned int SEHashWideString(const wchar_t *p);
VSDLLEXPORT unsigned int SEHashBString(const char *p, size_t len);
VSDLLEXPORT unsigned int SEHashBStringI(const char *p, size_t len);
VSDLLEXPORT unsigned int SEHashBStringUTF8(const char *p, size_t len);

/**
 * Compute a hash value for the given string.
 *
 * @param plstr    string to compute hash value for
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashPLstr(const VSLSTR *plstr);

/**
 * Hash the 'len' raw bytes starting at 'p'
 * using a sipmle additive algorithm.
 *
 * @param p    pointer to binary data
 * @param len  length of binary data
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashBinary(const void *p, unsigned int len);

/**
 * Hash a raw pointer to an unsigned int.
 * Simply do this by casting and shifting the
 * insignificant parts of the address away.
 *
 * @param p    pointer
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashPointer(const void *p);

/**
 * Hash an unsigned integer.
 *
 * @param i integer
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashUInteger(const unsigned int i);
VSDLLEXPORT unsigned int SEHashUInteger64(const VSUINT64 i);

/**
 * Hash a signed integer.
 *
 * @param i integer
 *
 * @return hash value
 */
VSDLLEXPORT unsigned int SEHashInteger(const int i);
VSDLLEXPORT unsigned int SEHashInteger64(const VSINT64 i);


/**
 * Manage a hash table of elements of type T, hashed using a key
 * of type K.  The hash table can dynamically grow if needed.
 * Elememts of the array can be indexed via the [] operator, using
 * keys of type K.
 * <P>
 * The hash table can also be searched linearly for a specific item
 * by providing a comparison function for the specific template
 * class type.
 * <P>
 * You must register a hash function which returns an unsigned
 * integer value for hashing items of type K.  You may call the
 * function SEhashString(s) for an effecient, decent hash
 * function for strings.  
 * <P>
 * Types T and K must have default constructors (ie. constructor with no
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
 * @param K  type of key to hash on
 * @param T  type of item to store in hash table
 */
template <class K, class T>
class SEHashTable : public SEMemory {
private:
   // Key-Value pair, with chaining
   struct KVpair : public SEMemory {
      // Construct a key value pair instance
      KVpair(const K &k, const T &v) {
         key=k;
         val=v;
         pnext=0;
      }

      K key;          // hash key
      T val;          // hash value
      KVpair *pnext;  // next in chain
   };

public:
   // typedefs for registered hashing and comparison functions
   typedef unsigned int (*HashProc)(K item);
   typedef int (*KeyCompareProc)(K k1, K k2);
   typedef int (*ValCompareProc)(T &v1, T &v2);
   typedef void (*ForEachProc)(K k, T &v);
   typedef void (*ForEachProcUD)(K k, T &v, void *userData);

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
   SEHashTable(int initialCapacity=89);
   ~SEHashTable();

   /**
    * Copy constructor
    */
   SEHashTable(const SEHashTable<K,T>& src);
   /**
    * Assignment operator
    */
   SEHashTable<K,T> &operator = (const SEHashTable<K,T>& src);

   /**
    * Comparison operators
    */
   bool operator == (const SEHashTable<K,T>& lhs) const;
   bool operator != (const SEHashTable<K,T>& lhs) const;

   /**
    * Remove and delete all the items from the hash table
    *
    * @param release_table   Also delete the hash table
    */
   void clear(int release_table=0);

   /**
    * Insert a new item into the hash table.
    * If key already exists, the item will be replaced
    *
    * @param key    key value to hash on
    * @param item   item to store associated with key
    *
    * @return 0 if successful. Return <0 on error.
    */
   int add(const K &key, const T &item);

   /**
    * Insert a new item into the hash table.
    * If the key already exists, a duplicate item will be inserted.
    * 
    * @param item      item to store associated with key
    * 
    * @return 0 if successful. Return <0 on error.
    */
   int addDuplicate(const K &key, const T &item);

   /**
    * Delete the given key/value pair from the hash table.
    *
    * @param key    key value to hash on
    * @param item   item associated with key value
    *
    * @return 0 on success, <0 on error (not found)
    */
   int remove(const K &key);

   /**
    * Delete the given key/value pair from the hash table.
    * <p> 
    * Both the key and the item will be compared. 
    * This function is only necessary to use when 
    * the hash set contains duplicate items. 
    *
    * @param key    key value to hash on
    * @param item   item associated with key value
    *
    * @return 0 on success, <0 on error (not found)
    */
   int removeExact(const K &key, const T &item);

   /**
    * Search for the specified item in the array.
    * A linear search of the hash buckets is used.
    * <p> 
    * Both the key and the item will be compared. 
    * This function is only necessary to use when 
    * the hash set contains duplicate items. 
    *
    * @param item   value of item to search hash table for
    * @param key    (reference) set to key value for item
    *
    * @return 0 on success, <0 on error.
    */
   int search(T &item, K &key) const;

   /**
    * @return The number of key/value pairs stored in the hash table
    */
   int length() const { return _NofItems; }

   /**
   * Set up custom hash function for key values
    */
   inline void registerHashProc(HashProc proc) { _pfnHash=proc; }
   /**
    * Set up custom comparison function for comparing keys
    * (for types that don't have a working == operator).
    */
   inline void registerKeyCompareProc(KeyCompareProc proc) { _pfnKeyCompare=proc; }
   /**
    * Set up custom comparison function for comparing items/values
    * (for types that don't have a working == operator).
    */
   inline void registerValCompareProc(ValCompareProc proc) { _pfnValCompare=proc; }

   /**
    * Return an array of pointers to the items.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   T** copyItemPointers() const;
   /**
    * Return a copy of the items in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   T* copyItems() const;
   /**
    * Return a copy of the keys in a simple array.
    *
    * IMPORTANT: The caller must delete the returning array
    *            using scalar delete.  (delete [] array)
    *
    * @return Returns a list of keys, or 0 for out-of-memory.
    */
   K* copyKeys() const;

   /**
    * Execute an operator for each item in the hash table.
    * <p>
    * NOTE: this function is only as const as the forEach proc.
    */
   void forEach(ForEachProcUD proc, void* userData) const;
   void forEach(ForEachProc proc) const;

   /**
    * Get the next item from this collection. 
    * If 'iter' is unitialized, it will retrieve the first item 
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to key for item retrieved 
    * 
    * @return Returns a pointer to item, NULL if there is no next item 
    */
   const T* nextItem(SEIterator &iter, K &key) const;
   T* nextItem(SEIterator &iter, K &key);
   const T* nextItem(SEIterator &iter) const;
   T* nextItem(SEIterator &iter);

   /**
    * Get the previous item from this collection. 
    * If 'iter' is unitialized, it will retrieve the last item 
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * @param key     (output) set to key for item retrieved 
    * 
    * @return Returns a pointer to item, NULL if there is no previous item 
    */
   const T* prevItem(SEIterator &iter, K &key) const;
   T* prevItem(SEIterator &iter, K &key);
   const T* prevItem(SEIterator &iter) const;
   T* prevItem(SEIterator &iter);

   /**
    * Get the current item pointed to by the given iterator. 
    * If 'iter' is unitialized, it will return NULL.
    * 
    * @param iter    black-box iterator object 
    * @param key     (output) set to key for item retrieved 
    *  
    * @return Returns a pointer to item, NULL if there is no current item 
    */
   const T* currentItem(const SEIterator &iter, K &key) const;
   T* currentItem(const SEIterator &iter, K &key);
   const T* currentItem(const SEIterator &iter) const;
   T* currentItem(const SEIterator &iter);

   /**
    * Get the current iterator key. 
    * If 'iter' is uninitialized, the result is undefined. 
    * 
    * @return Returns the current iterator key
    */
   const K currentKey(const SEIterator &iter) const;

   /**
    * Remove the current item pointed to by the given iterator 
    * from the collection.  The next item in the collection will 
    * become the new current item.
    * 
    * @param iter    black-box iterator object 
    * 
    * @return 0 on success, <0 on error or if 'iter' is unitialized. 
    */
   int removeItem(SEIterator &iter);

   /**
    * Return a reference to the item corresponding to the
    * given key.  This is the classic, fast hash table lookup.
    *
    * @param key    key value to look up
    *
    * @return pointer to item corresponding to key.
    *         Returns 0 if there is no such item in table.
    */
   T* operator[](const K &key);
   const T* operator[](const K &key) const;

   /**
    * Is the given key in the hash table?
    *
    * @param key    key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isKey(const K &key) const;

   /**
    * Is the given key and value in the hash table?
    *
    * @param key    key value to look up
    * @param item   test if this item is what is mapped to key
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isKeyWithValue(const K &key, const T& item) const;

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
   KVpair **_kvlist;                    // Hash table buffer
   int _NofItems;                       // Number of items in hash table
   int _NofChained;                     // Number of chained items
   int _NofAllocated;                   // Hash table capacity

   KeyCompareProc _pfnKeyCompare;       // Compare proc for keys
   ValCompareProc _pfnValCompare;       // Compare proc for values
   HashProc _pfnHash;                   // Hash function

   // Hash the given key to an array index
   inline unsigned int hashKey(const K &key) const
   {
      unsigned int h = _pfnHash(key);
      return(h % _NofAllocated);
   }
   // Returns 1 if k1==k2, 0 otherwise.
   inline int isKeyEqual(K k1, K k2) const
   {
      return (_pfnKeyCompare? (_pfnKeyCompare(k1,k2)==0) : (k1==k2));
   }
   // Returns 1 if v1==v2, 0 otherwise.
   inline int isValEqual(T &v1, T &v2) const
   {
      return (_pfnValCompare? (_pfnValCompare(v1,v2)==0) : (v1==v2));
   }

   T* nextItemInternal(SEIterator &iter, K *pKey=NULL) const;
   T* prevItemInternal(SEIterator &iter, K *pKey=NULL) const;
   T* currentItemInternal(const SEIterator &iter, K *pKey=NULL) const;
};

//////////////////////////////////////////////////////////////////////////

template <class K, class T> inline
SEHashTable<K,T>::SEHashTable(int initialCapacity) :
   // initial function pointers
   _pfnKeyCompare(0),
   _pfnValCompare(0),
   _pfnHash(0),
   // initialize list of items
   _kvlist(0),
   _NofItems(0),
   _NofChained(0),
   _NofAllocated(0)
{
   // allocate list
   if (initialCapacity > 0) {
      _kvlist = (KVpair**) SEAllocator::allocate(sizeof(KVpair*)*initialCapacity);
      if (!_kvlist) {
         return;
      }
      memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
      _NofAllocated=initialCapacity;
   }
}
template <class K, class T> inline
SEHashTable<K,T>::SEHashTable(const SEHashTable<K,T>& src) :
   // initial function pointers
   _pfnKeyCompare(src._pfnKeyCompare),
   _pfnValCompare(src._pfnValCompare),
   _pfnHash(src._pfnHash),
   // initialize list of items
   _kvlist(0),
   _NofItems(src._NofItems),
   _NofChained(src._NofChained),
   _NofAllocated(src._NofAllocated)
{
   // allocate sufficient space
   int initialCapacity = src._NofAllocated;
   if (initialCapacity > 0) {
      _kvlist = (KVpair**) SEAllocator::allocate(sizeof(KVpair*)*initialCapacity);
      if (!_kvlist) {
         return;
      }
      memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
      _NofAllocated=initialCapacity;
   }

   // now copy in the items
   for (int i=0; i<initialCapacity; ++i) {
      KVpair *kv = src._kvlist[i];
      KVpair **ppkv = &_kvlist[i];
      while (kv) {
         // allocate the key-value pair and it to the list
         KVpair *pkv = new KVpair(kv->key,kv->val);
         *ppkv = pkv;
         ppkv = &pkv->pnext;
         // get next item from source hash table
         kv=kv->pnext;
      }
   }
}
template <class K, class T> inline
SEHashTable<K,T>& SEHashTable<K,T>::operator=(const SEHashTable<K,T>& src)
{
   if (this != &src) {
      // out with the old
      clear();
      this->_pfnHash = src._pfnHash;
      this->_pfnKeyCompare = src._pfnKeyCompare;
      this->_pfnValCompare = src._pfnValCompare;
      this->_NofItems = src._NofItems;
      this->_NofChained = src._NofChained;

      // allocate sufficient space
      int initialCapacity = src._NofAllocated;
      if (initialCapacity > 0) {
         _kvlist = (KVpair**) SEAllocator::reallocate(_kvlist, sizeof(KVpair*)*initialCapacity);
         memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
         _NofAllocated=initialCapacity;
      }

      // in with the new
      for (int i=0; i<src._NofAllocated; ++i) {
         KVpair *kv = src._kvlist[i];
         KVpair **ppkv = &_kvlist[i];
         while (kv) {
            // allocate the key-value pair and it to the list
            KVpair *pkv = new KVpair(kv->key,kv->val);
            *ppkv = pkv;
            ppkv = &pkv->pnext;
            // get next item from source hash table
            kv=kv->pnext;
         }
      }
   }
   return *this;
}
template <class K, class T> inline
SEHashTable<K,T>::~SEHashTable()
{
   clear(1);
}
template <class K, class T> inline
K* SEHashTable<K,T>::copyKeys() const
{
   // allocate an array of items of type 'T'

   if ( _NofItems==0 ) return ( (K *)0 );
   K *list = new K[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->key;
         pkv=pkv->pnext;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K, class T> inline
T* SEHashTable<K,T>::copyItems() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return ( (T *)0 );
   T *list = new T[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         list[j]=pkv->val;
         pkv=pkv->pnext;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K, class T> inline
T** SEHashTable<K,T>::copyItemPointers() const
{
   // allocate an array of items of type 'T'
   if ( _NofItems==0 ) return ( (T **)0 );
   T **list = new T*[_NofItems];
   if (!list) return (0);
   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         list[j]=&pkv->val;
         pkv=pkv->pnext;
         ++j;
      }
   }
   // that's all, return result
   return list;
}
template <class K, class T> inline
void SEHashTable<K,T>::forEach(ForEachProcUD proc, void* userData) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->key, pkv->val, userData);
         pkv=pkv->pnext;
         ++j;
      }
   }
}
template <class K, class T> inline
void SEHashTable<K,T>::forEach(ForEachProc proc) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->key, pkv->val);
         pkv=pkv->pnext;
         ++j;
      }
   }
}


template <class K, class T> inline
T* SEHashTable<K,T>::nextItemInternal(SEIterator &iter, K *pKey) const
{
   // first check the linked lists
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      pkv = pkv->pnext;
      if (pkv != NULL) {
         iter.mpNode = pkv;
         if (pKey != NULL) {
            *pKey = pkv->key;
         }
         return &pkv->val;
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
   while (iter.mIndex < (size_t)_NofAllocated) {
      pkv = _kvlist[iter.mIndex];
      if (pkv != NULL) {
         iter.mpNode = pkv;
         if (pKey != NULL) {
            *pKey = pkv->key;
         }
         return &pkv->val;
      }
      iter.mIndex++;
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}

template <class K, class T> inline
const T* SEHashTable<K,T>::nextItem(SEIterator &iter, K &key) const
{
   return nextItemInternal(iter,&key);
}
template <class K, class T> inline
T* SEHashTable<K,T>::nextItem(SEIterator &iter, K &key)
{
   return nextItemInternal(iter,&key);
}
template <class K, class T> inline
const T* SEHashTable<K,T>::nextItem(SEIterator &iter) const
{
   return nextItemInternal(iter);
}
template <class K, class T> inline
T* SEHashTable<K,T>::nextItem(SEIterator &iter)
{
   return nextItemInternal(iter);
}

template <class K, class T> inline
T* SEHashTable<K,T>::prevItemInternal(SEIterator &iter, K *pKey) const
{
   // first check the linked lists
   if (!iter.mFindFirst && iter.mpNode != NULL) {
      KVpair *pkv = _kvlist[iter.mIndex];
      if (pkv != iter.mpNode) {
         while (pkv != NULL) {
            if (pkv->pnext == iter.mpNode) {
               iter.mpNode = pkv;
               if (pKey != NULL) {
                  *pKey = pkv->key;
               }
               return &pkv->val;
            }
            pkv = pkv->pnext;
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
   for (;;) {
      KVpair *pkv = _kvlist[iter.mIndex];
      if (pkv != NULL) {
         while (pkv->pnext != NULL) {
            pkv = pkv->pnext;
         }
         iter.mpNode = pkv;
         if (pKey != NULL) {
            *pKey = pkv->key;
         }
         return &pkv->val;
      }
      if (iter.mIndex==0) break;
      iter.mIndex--;
   }
   // no more slots to test
   iter.mpNode = NULL;
   return NULL;
}
template <class K, class T> inline
const T* SEHashTable<K,T>::prevItem(SEIterator &iter, K &key) const
{
   return prevItemInternal(iter, &key);
}
template <class K, class T> inline
T* SEHashTable<K,T>::prevItem(SEIterator &iter, K &key)
{
   return prevItemInternal(iter, &key);
}
template <class K, class T> inline
const T* SEHashTable<K,T>::prevItem(SEIterator &iter) const
{
   return prevItemInternal(iter);
}
template <class K, class T> inline
T* SEHashTable<K,T>::prevItem(SEIterator &iter)
{
   return prevItemInternal(iter);
}

template <class K, class T> inline
T* SEHashTable<K,T>::currentItemInternal(const SEIterator &iter, K *pKey) const
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      if (pKey != NULL) {
         *pKey = pkv->key;
      }
      return &pkv->val;
   }
   return NULL;
}
template <class K, class T> inline
const T* SEHashTable<K,T>::currentItem(const SEIterator &iter, K &key) const
{
   return currentItemInternal(iter, &key);
}
template <class K, class T> inline
T* SEHashTable<K,T>::currentItem(const SEIterator &iter, K &key)
{
   return currentItemInternal(iter, &key);
}
template <class K, class T> inline
const T* SEHashTable<K,T>::currentItem(const SEIterator &iter) const
{
   return currentItemInternal(iter);
}
template <class K, class T> inline
T* SEHashTable<K,T>::currentItem(const SEIterator &iter)
{
   return currentItemInternal(iter);
}

template <class K, class T> inline
const K SEHashTable<K,T>::currentKey(const SEIterator &iter) const
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (pkv != NULL) {
      return pkv->key;
   }
   K *pKey = new K();
   K key = *pKey;
   delete pKey;
   return key;
}

template <class K, class T> inline
int SEHashTable<K,T>::removeItem(SEIterator &iter)
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      iter.mpNode = pkv->pnext;

      KVpair *firstNode = _kvlist[iter.mIndex];
      if (firstNode == pkv) {
         _kvlist[iter.mIndex] = pkv->pnext;
         if (pkv->pnext != NULL) --_NofChained;
         --_NofItems;
         delete pkv;
      } else if (firstNode != NULL) {
         while (firstNode->pnext != NULL) {
            if (firstNode->pnext == pkv) {
               firstNode->pnext = pkv->pnext;
               delete pkv;
               --_NofItems;
               --_NofChained;
               break;
            }
            firstNode = firstNode->pnext;
         }
      }

      if (iter.mpNode == NULL) {
         // go to the next slot
         if (iter.mIndex < (size_t)_NofAllocated) {
            iter.mIndex++;
         } else {
            return 0;
         }
   
         // iterate until we find a slot with data in it
         while (iter.mIndex < (size_t)_NofAllocated) {
            pkv = _kvlist[iter.mIndex];
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

template <class K, class T> inline
bool SEHashTable<K,T>::isKey(const K &key) const
{
   // if we have no items, no need to find the item
   if (_NofItems == 0) {
      return false;
   }
   unsigned int h=hashKey(key);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->key,key)) {
         return true;
      }
      p=p->pnext;
   }
   return(false);
}

template <class K, class T> inline
bool SEHashTable<K,T>::isKeyWithValue(const K &key, const T&item) const
{
   // if we have no items, no need to find the item
   if (_NofItems == 0) {
      return false;
   }
   unsigned int h=hashKey(key);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->key,key) && isValEqual(p->val, (T&)item)) {
         return true;
      }
      p=p->pnext;
   }
   return(false);
}

template <class K, class T> inline
const T* SEHashTable<K,T>::operator[](const K &key) const
{
   // if we have no items, no need to find the item
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashKey(key);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->key,key)) {
         return &p->val;
      }
      p=p->pnext;
   }
   return(0);
}
template <class K, class T> inline
T* SEHashTable<K,T>::operator[](const K &key)
{
   // if we have no items, no need to find the item
   if (_NofItems == 0) {
      return NULL;
   }
   unsigned int h=hashKey(key);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->key,key)) {
         return &p->val;
      }
      p=p->pnext;
   }
   return(0);
}
template <class K, class T> inline
int SEHashTable<K,T>::remove(const K &key)
{
   // if we have no items, no need to do anything
   if (_NofItems == 0) {
      return 0;
   }

   // compute hash bucket for new item
   unsigned int h=hashKey(key);

   // check if this key is already in the table
   KVpair **ppkv = &_kvlist[h];
   KVpair *p = _kvlist[h];
   int chaining = (p && p->pnext)? 1:0;
   while (p) {
      if (isKeyEqual(p->key,key)) {
         _NofItems--;
         _NofChained-=chaining;
         *ppkv = p->pnext;
         delete(p);
         break;
      }
      ppkv=&p->pnext;
      p=p->pnext;
   }

   // Did not find item
   if (p == NULL) {
      return FILE_NOT_FOUND_RC;
   }

   // Shrink the hash table if necessary
   if (_NofItems < 64 && _NofAllocated > 512) {
      rehash(89);
   } else if (_NofItems >= 64 && _NofItems < _NofAllocated / 8) {
      rehash(_NofItems*2+1);
   }

   // success
   return 0;
}
template <class K, class T> inline
int SEHashTable<K,T>::removeExact(const K &key, const T &item)
{
   // if we have no items, no need to do anything
   if (_NofItems == 0) {
      return 0;
   }

   // compute hash bucket for new item
   unsigned int h=hashKey(key);

   // check if this key is already in the table
   KVpair **ppkv = &_kvlist[h];
   KVpair *p = _kvlist[h];
   int chaining = (p && p->pnext)? 1:0;
   while (p) {
      if (isKeyEqual(p->key,key) && isValEqual(p->val, (T&)item)) {
         _NofItems--;
         _NofChained-=chaining;
         *ppkv = p->pnext;
         delete(p);
         return(0);
      }
      ppkv=&p->pnext;
      p=p->pnext;
   }

   // add new item to the chain
   return FILE_NOT_FOUND_RC;
}
template <class K, class T> inline
int SEHashTable<K,T>::add(const K &key, const T &item)
{
   // allocate the hash table if we do not have one
   if (_kvlist == NULL) {
      const int initialCapacity=89;
      _kvlist = (KVpair**) SEAllocator::allocate(sizeof(KVpair*)*initialCapacity);
      if (!_kvlist) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
      _NofAllocated=initialCapacity;
   }
   // Allocate a larger array if needed:
   // If we have as many chained items as we have buckets,
   // then we know that our load factor is at least 2,
   // which means the hash table isn't working at peak
   // effeciency.
   if (_NofChained > _NofAllocated/2 && _NofItems > _NofAllocated) {
      int status=rehash();
      if (status) {
         return(status);
      }
   }

   // compute hash bucket for new item
   unsigned int h=hashKey(key);

   // check if this key is already in the table
   KVpair *p = _kvlist[h];
   while (p) {
      if (isKeyEqual(p->key,key)) {
         p->key=key;
         p->val=item;
         return(0);
      }
      p=p->pnext;
   }

   // allocate the key-value pair
   KVpair *pkv = new KVpair(key,item);
   if (!pkv) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // add new item to the chain
   pkv->pnext=_kvlist[h];
   _kvlist[h]=pkv;
   _NofItems++;
   _NofChained+=(pkv->pnext)? 1:0;
   return(0);
}
template <class K, class T> inline
int SEHashTable<K,T>::addDuplicate(const K &key, const T &item)
{
   // allocate the hash table if we do not have one
   if (_kvlist == NULL) {
      const int initialCapacity=89;
      _kvlist = (KVpair**) SEAllocator::allocate(sizeof(KVpair*)*initialCapacity);
      if (!_kvlist) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
      _NofAllocated=initialCapacity;
   }
   // Allocate a larger array if needed:
   // If we have as many chained items as we have buckets,
   // then we know that our load factor is at least 2,
   // which means the hash table isn't working at peak
   // effeciency.
   if (_NofChained > _NofAllocated/2 && _NofItems > _NofAllocated) {
      int status=rehash();
      if (status) {
         return(status);
      }
   }

   // allocate the key-value pair
   KVpair *pkv = new KVpair(key,item);
   if (!pkv) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // compute hash bucket for new item
   unsigned int h=hashKey(key);

   // add new item to the chain
   pkv->pnext=_kvlist[h];
   _kvlist[h]=pkv;
   _NofItems++;
   _NofChained+=(pkv->pnext)? 1:0;
   return(0);
}
template <class K, class T> inline
int SEHashTable<K,T>::search(T &item, K &key) const
{
   for (int i=0; i<_NofAllocated; ++i) {
      KVpair *pkv=_kvlist[i];
      while (pkv) {
         if (isValEqual(item, pkv->val)) {
            key=pkv->key;
            return(0);
         }
         pkv=pkv->pnext;
      }
   }
   return FILE_NOT_FOUND_RC;
}

template <class K, class T> inline
int SEHashTable<K,T>::rehash(int new_NofAllocated)
{
   // Try twice the size of the previous array...
   // + 1 to make it more likely to be prime, and non-zero
   if (new_NofAllocated <= 0) {
      new_NofAllocated=_NofAllocated*2+1;
   }
   KVpair **new_kvlist = (KVpair**) SEAllocator::allocate(sizeof(KVpair*)*new_NofAllocated);
   if (!new_kvlist) {
      return INSUFFICIENT_MEMORY_RC;
   }
   memset(new_kvlist,0,new_NofAllocated*sizeof(KVpair*));

   // Reset the chaining count
   _NofChained=0;

   // rehash the items in the hash table
   for (int i=0; i<_NofAllocated; ++i) {
      KVpair *p=_kvlist[i];
      while (p) {
         // save the next in chain
         KVpair *pnext = p->pnext;
         // compute hash bucket for new item
         unsigned int h = _pfnHash(p->key);
         h %= new_NofAllocated;
         // add new item to the chain
         p->pnext=new_kvlist[h];
         _NofChained+=(p->pnext)? 1:0;
         new_kvlist[h]=p;
         // next please
         p=pnext;
      }
   }

   // swap in the new list
   SEAllocator::deallocate(_kvlist);
   _kvlist=new_kvlist;
   _NofAllocated=new_NofAllocated;
   return (0);
}

template <class K, class T> inline
void SEHashTable<K,T>::clear(int release_table)
{
   for (int i=0; i<_NofAllocated; ++i) {
      KVpair *p=_kvlist[i];
      while (p) {
         KVpair *pnext = p->pnext;
         delete p;
         p=pnext;
      }
      _kvlist[i]=0;
   }
   _NofItems=0;
   _NofChained=0;
   if (release_table) {
      SEAllocator::deallocate(_kvlist);
      _kvlist=0;
      _NofAllocated=0;
   }
}

template <class K, class T> inline
bool SEHashTable<K,T>::operator==(const SEHashTable<K,T>& lhs) const 
{
   if (this->_NofItems != lhs._NofItems) {
      return false;
   }
   if (this->_pfnHash != lhs._pfnHash ||
       this->_pfnKeyCompare != lhs._pfnKeyCompare ||
       this->_pfnValCompare != lhs._pfnValCompare) {
      return false;
   }
   slickedit::SEIterator iter;
   K key;
   for (;;) {
      T* pItem = (T*)this->nextItem(iter, key);
      if (pItem == NULL) break;
      T* pLHS = (T*)lhs[key];
      if (pLHS == NULL) return false;
      if (!isValEqual(*pItem,*pLHS)) return false;
   }
   return true;
}
template <class K, class T> inline
bool SEHashTable<K,T>::operator!=(const SEHashTable<K,T>& lhs) const 
{
   return !this->operator ==(lhs);
}

}

#endif // SLICKEDIT_HASHTABLE_H
