////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_HASHSET_H
#define SLICKEDIT_HASHSET_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "vsmsgdefs_slicki.h"
#include "SEMemory.h"
#include "SEString.h"
#include "SEIterator.h"
#include <new>

namespace slickedit {

//////////////////////////////////////////////////////////////////////////

/**
 * Manage a hash set of elements of type T.
 * The hash table can dynamically grow if needed.
 * Elememts of the array can be indexed via the [] operator.
 * <P>
 * The hash set can also be searched linearly for a specific item
 * by providing a comparison function for the specific template
 * class type.
 * <P>
 * The hashed type T is required to have a member function
 * named "hash" that returns an unsigned integer value.
 * If you wish to override the 'hash' method, you may register
 * a hash function which returns an unsigned integer value for
 * hashing items of type T.
 * <P>
 * T must have default constructors (ie. constructor with no
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
 * @param T  type of item to store in hash table
 */
template <class T>
class SEHashSet : public SEMemory {
private:
   // Key-Value pair, with chaining
   struct KVpair : public SEMemory {
      // Construct a key value pair instance
      KVpair(const T &v) {
         val=v;
         pnext=0;
      }

      T val;          // hash value
      KVpair *pnext;  // next in chain

   };

public:
   // typedefs for registered hashing and comparison functions
   typedef unsigned int (*HashProc)(const T &item);
   typedef int (*KeyCompareProc)(const T &k1, const T &k2);
   typedef int (*ValCompareProc)(const T &v1, const T &v2);
   typedef void (*ForEachProc)(T &v);
   typedef void (*ForEachProcUD)(T &v, void *userData);

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
   SEHashSet(int initialCapacity=89);
   ~SEHashSet();

   /**
    * Copy constructor
    */
   SEHashSet(const SEHashSet<T>& src);
   /**
    * Assignment operator
    */
   SEHashSet<T> &operator = (const SEHashSet<T>& src);

   /**
    * Comparison operators
    */
   bool operator == (const SEHashSet<T>& lhs) const; 
   bool operator != (const SEHashSet<T>& lhs) const; 

   /**
    * Remove and delete all the items from the hash table
    *
    * @param release_table   Also delete the hash table
    */
   void clear(bool release_table=false);

   /**
    * Insert a new item into the hash table.
    * If key already exists, the item will be replaced
    * 
    * @param item      item to store associated with key
    * @param dupStatus Set this to 1 to avoid two hash lookups in 
    *                  the case where you only want to add an item
    *                  if it is not already there.
    * 
    * @return 0 if successful. Otherwise -1.
    */
   int add(const T &item,int dupStatus=0);

   /**
    * Insert a new item into the hash table.
    * If the key already exists, a duplicate item will be inserted.
    * 
    * @param item      item to store associated with key
    * 
    * @return 0 if successful. Otherwise -1.
    */
   int addDuplicate(const T &item);

   /**
    * Delete the given key/value pair from the hash table.
    *
    * @param key    key value to hash on
    * @param item   item associated with key value
    *
    * @return 0 on success, <0 on error (not found)
    */
   int remove(const T &item);

   /**
    * Delete the given key/value pair from the hash table.
    * <p> 
    * The key will be compared using _isValEqual(), 
    * in order to check for exact equality. 
    * This function is only necessary to use when 
    * the hash set contains duplicate items. 
    *
    * @param key    key value to hash on
    * @param item   item associated with key value
    *
    * @return 0 on success, <0 on error (not found)
    */
   int removeExact(const T &item);

   /**
    * Search for the specified item in the array.
    * A linear search of the hash buckets is used.
    *
    * @param item   value of item to search hash table for
    * @param key    (reference) set to key value for item
    *
    * @return 0 on success, <0 on error.
    */
   int search(T &item, const T &key) const;

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
    * Return a copy of the keys in a simple array.
    * The caller should delete the returning array.
    *
    * @return Returns a list of items, or 0 for out-of-memory.
    */
   T* copyItems() const;

   /**
    * Execute an operator for each item in the hash table.
    * <p>
    * NOTE:  This function is only as const as the for Each proc.
    */
   void forEach(ForEachProcUD proc, void* userData) const;
   void forEach(ForEachProc proc) const;

   /**
    * Get the next item from this collection. 
    * If 'iter' is unitialized, it will retrieve the first item 
    * in the collection. 
    *  
    * @param iter    black-box iterator object 
    * 
    * @return Returns a pointer to item, NULL if there is no next item 
    */
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
   const T* currentItem(const SEIterator &iter) const;
   T* currentItem(const SEIterator &iter);

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
   T* operator[](const T& key);
   const T* operator[](const T& key) const;

   /**
    * Is the given key in the hash table?
    *
    * @param key    key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isInHashSet(const T& key) const;

   /**
    * Is the given item in the hash set (exactly). 
    * This function is only necessary when the set contains duplicates. 
    */
   bool isInHashSetExact(const T& key) const;

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
   inline unsigned int hashKey(const T &item) const
   {
      unsigned int h = _pfnHash? _pfnHash(item) : item.hash();
      return(h % _NofAllocated);
   }
   // Returns 1 if k1==k2, 0 otherwise.
   inline int isKeyEqual(const T &k1, const T &k2) const
   {
      return (_pfnKeyCompare? (_pfnKeyCompare(k1,k2)==0) : (k1==k2));
   }
   // Returns 1 if v1==v2, 0 otherwise.
   inline int isValEqual(const T &v1, const T &v2) const
   {
      return (_pfnValCompare? (_pfnValCompare(v1,v2)==0) : (v1==v2));
   }

   T* nextItemInternal(SEIterator &iter) const;
   T* prevItemInternal(SEIterator &iter) const;
};

/**
 * This typedef is used to store a set of SEStrings.
 */
typedef SEHashSet<slickedit::SEString> SEStringSet;

//////////////////////////////////////////////////////////////////////////

template <class T> inline
SEHashSet<T>::SEHashSet(int initialCapacity)
{
   // initial function pointers
   _pfnKeyCompare=0;
   _pfnValCompare=0;
   _pfnHash=0;
   // initialize list of items
   _kvlist=0;
   _NofItems=0;
   _NofChained=0;
   _NofAllocated=0;
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
template <class T> inline
SEHashSet<T>::SEHashSet(const SEHashSet<T>& src) :
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
         KVpair *pkv = new KVpair(kv->val);
         *ppkv = pkv;
         ppkv = &pkv->pnext;
         // get next item from source hash table
         kv=kv->pnext;
      }
   }
}
template <class T> inline
SEHashSet<T>& SEHashSet<T>::operator=(const SEHashSet<T>& src)
{
   if (this != &src) {
      // out with the old
      clear();

      // allocate sufficient space
      int initialCapacity = src._NofAllocated;
      if (initialCapacity > 0) {
         _kvlist = (KVpair**) SEAllocator::reallocate(_kvlist, sizeof(KVpair*)*initialCapacity);
         if (!_kvlist) {
            return *this;
         }
         memset(_kvlist,0,initialCapacity*sizeof(KVpair*));
         _NofAllocated=initialCapacity;
      }

      // copy the callback functions
      this->_pfnKeyCompare = src._pfnKeyCompare;
      this->_pfnValCompare = src._pfnValCompare;
      this->_pfnHash = src._pfnHash;
      this->_NofItems = src._NofItems;
      this->_NofChained = src._NofChained;

      // in with the new
      for (int i=0; i<src._NofAllocated; ++i) {
         KVpair *kv = src._kvlist[i];
         KVpair **ppkv = &_kvlist[i];
         while (kv) {
            // allocate the key-value pair and it to the list
            KVpair *pkv = new KVpair(kv->val);
            *ppkv = pkv;
            ppkv = &pkv->pnext;
            // get next item from source hash table
            kv=kv->pnext;
         }
      }
   }
   return *this;
}
template <class T> inline
SEHashSet<T>::~SEHashSet()
{
   clear(true);
}

template <class T> inline
T** SEHashSet<T>::copyItemPointers() const
{
   // get number of items
   int numItems = length();
   if (numItems==0) return 0;

   // allocate list object
   T** list = new T*[numItems];
   if ( list == 0 ) return 0;

   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated; ++i) {
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
template <class T> inline
T* SEHashSet<T>::copyItems() const
{
   // get number of items
   int numItems = length();
   if (numItems==0) return 0;

   // allocate list object
   T* list = new T[numItems];
   if ( list == 0 ) return 0;

   // copy in the items from the list
   int i=0,j=0;
   for (; i<_NofAllocated; ++i) {
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

template <class T> inline
bool SEHashSet<T>::isInHashSet(const T& item) const
{
   if (_NofItems==0) return false;
   unsigned int h=hashKey(item);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item)) {
         return true;
      }
      p=p->pnext;
   }
   return(false);
}

template <class T> inline
bool SEHashSet<T>::isInHashSetExact(const T& item) const
{
   if (_NofItems==0) return false;
   unsigned int h=hashKey(item);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item) && isValEqual(p->val,item)) {
         return true;
      }
      p=p->pnext;
   }
   return(false);
}

template <class T> inline
void SEHashSet<T>::forEach(ForEachProcUD proc, void* userData) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->val, userData);
         pkv=pkv->pnext;
         ++j;
      }
   }
}
template <class T> inline
void SEHashSet<T>::forEach(ForEachProc proc) const
{
   int i=0,j=0;
   for (; i<_NofAllocated && j<_NofItems; ++i) {
      KVpair *pkv = _kvlist[i];
      while (pkv && j<_NofItems) {
         (*proc)(pkv->val);
         pkv=pkv->pnext;
         ++j;
      }
   }
}

template <class T> inline
T* SEHashSet<T>::nextItemInternal(SEIterator &iter) const
{
   // first check the linked lists
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      pkv = pkv->pnext;
      if (pkv != NULL) {
         iter.mpNode = pkv;
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
   size_t i = iter.mIndex;
   size_t n = (size_t)_NofAllocated;
   while (i < n) {
      pkv = _kvlist[i];
      if (pkv != NULL) {
         iter.mIndex = i;
         iter.mpNode = pkv;
         return &pkv->val;
      }
      i++;
   }
   // no more slots to test
   iter.mIndex = i;
   iter.mpNode = NULL;
   return NULL;
}
template <class T> inline
const T* SEHashSet<T>::nextItem(SEIterator &iter) const
{
   return nextItemInternal(iter);
}
template <class T> inline
T* SEHashSet<T>::nextItem(SEIterator &iter)
{
   return nextItemInternal(iter);
}

template <class T> inline
T* SEHashSet<T>::prevItemInternal(SEIterator &iter) const
{
   // first check the linked lists
   if (!iter.mFindFirst && iter.mpNode != NULL) {
      KVpair *pkv = _kvlist[iter.mIndex];
      if (pkv != iter.mpNode) {
         while (pkv != NULL) {
            if (pkv->pnext == iter.mpNode) {
               iter.mpNode = pkv;
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
   size_t i = iter.mIndex;
   for (;;) {
      KVpair *pkv = _kvlist[i];
      if (pkv != NULL) {
         while (pkv->pnext != NULL) {
            pkv = pkv->pnext;
         }
		 iter.mIndex = i;
         iter.mpNode = pkv;
         return &pkv->val;
      }
      if (i==0) break;
      i--;
   }
   // no more slots to test
   iter.mIndex = i;
   iter.mpNode = NULL;
   return NULL;
}
template <class T> inline
const T* SEHashSet<T>::prevItem(SEIterator &iter) const
{
   return prevItemInternal(iter);
}
template <class T> inline
T* SEHashSet<T>::prevItem(SEIterator &iter)
{
   return prevItemInternal(iter);
}
template <class T> inline
const T* SEHashSet<T>::currentItem(const SEIterator &iter) const
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      return &pkv->val;
   }
   return NULL;
}
template <class T> inline
T* SEHashSet<T>::currentItem(const SEIterator &iter)
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      return &pkv->val;
   }
   return NULL;
}
template <class T> inline
int SEHashSet<T>::removeItem(SEIterator &iter)
{
   KVpair *pkv = (KVpair*)iter.mpNode;
   if (!iter.mFindFirst && pkv != NULL) {
      iter.mpNode = pkv->pnext;

      KVpair *firstNode = _kvlist[iter.mIndex];
      if (firstNode == pkv) {
         _kvlist[iter.mIndex] = pkv->pnext;
         if (pkv->pnext != NULL) _NofChained--;
         _NofItems--;
         delete pkv;
      } else if (firstNode != NULL) {
         while (firstNode->pnext != NULL) {
            if (firstNode->pnext == pkv) {
               firstNode->pnext = pkv->pnext;
               delete pkv;
               _NofItems--;
               _NofChained--;
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

template <class T> inline
const T* SEHashSet<T>::operator[](const T& item) const
{
   if (_NofItems==0) return(0);
   unsigned int h=hashKey(item);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item)) {
         return &p->val;
      }
      p=p->pnext;
   }
   return(0);
}
template <class T> inline
T* SEHashSet<T>::operator[](const T& item)
{
   if (_NofItems==0) return(0);
   unsigned int h=hashKey(item);
   KVpair *p=_kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item)) {
         return &p->val;
      }
      p=p->pnext;
   }
   return(0);
}
template <class T> inline
int SEHashSet<T>::remove(const T& item)
{
   // compute hash bucket for new item
   if (_NofItems==0) return(0);
   unsigned int h=hashKey(item);

   // check if this key is already in the table
   KVpair **ppkv = &_kvlist[h];
   KVpair *p = _kvlist[h];
   int chaining = (p && p->pnext)? 1:0;
   while (p) {
      if (isKeyEqual(p->val,item)) {
         _NofItems--;
         _NofChained -= chaining;
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
template <class T> inline
int SEHashSet<T>::removeExact(const T& item)
{
   // compute hash bucket for new item
   if (_NofItems==0) return(0);
   const unsigned int h=hashKey(item);

   // check if this key is already in the table
   // do a quick pointer check first
   KVpair **ppkv = &_kvlist[h];
   KVpair *p = _kvlist[h];
   const int chaining = (p && p->pnext)? 1:0;
   while (p) {
      if (&p->val == &item) {
         _NofItems--;
         _NofChained -= chaining;
         *ppkv = p->pnext;
         delete(p);
         return(0);
      }
      ppkv=&p->pnext;
      p=p->pnext;
   }

   // check if this key is already in the table
   ppkv = &_kvlist[h];
   p = _kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item) && isValEqual(p->val,item)) {
         _NofItems--;
         _NofChained -= chaining;
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
template <class T> inline
int SEHashSet<T>::add(const T &item,int dupStatus)
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
   unsigned int h=hashKey(item);

   // check if this key is already in the table
   KVpair *p = _kvlist[h];
   while (p) {
      if (isKeyEqual(p->val,item)) {
         p->val=item;
         return(dupStatus);
      }
      p=p->pnext;
   }

   // allocate the key-value pair
   KVpair *pkv = new KVpair(item);
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
template <class T> inline
int SEHashSet<T>::addDuplicate(const T &item)
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
   KVpair *pkv = new KVpair(item);
   if (!pkv) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // compute hash bucket for new item
   unsigned int h=hashKey(item);

   // add new item to the chain
   pkv->pnext=_kvlist[h];
   _kvlist[h]=pkv;
   _NofItems++;
   _NofChained+=(pkv->pnext)? 1:0;
   return(0);
}
template <class T> inline
int SEHashSet<T>::search(T &item, const T &key) const
{
   for (int i=0; i<_NofAllocated; ++i) {
      KVpair *pkv=_kvlist[i];
      while (pkv) {
         if (isKeyEqual(key, pkv->val)) {
            item=pkv->val;
            return(0);
         }
         pkv=pkv->pnext;
      }
   }
   return FILE_NOT_FOUND_RC;
}

template <class T> inline
int SEHashSet<T>::rehash(int new_NofAllocated)
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
         unsigned int h = _pfnHash? _pfnHash(p->val) : p->val.hash();
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

template <class T> inline
void SEHashSet<T>::clear(bool release_table)
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

template <class T> inline
bool SEHashSet<T>::operator==(const SEHashSet<T>& lhs) const 
{
   if (this->_NofItems != lhs._NofItems) {
      return false;
   }
   if (this->_pfnKeyCompare != lhs._pfnKeyCompare ||
       this->_pfnValCompare != lhs._pfnValCompare) {
      return false;
   }
   slickedit::SEIterator iter;
   for (;;) {
      T* pItem = (T*)this->nextItem(iter);
      if (pItem == NULL) break;
      T* pLHS = (T*)lhs[*pItem];
      if (pLHS == NULL) return false;
      if (!isValEqual(*pItem,*pLHS)) return false;
   }
   return true;
}
template <class T> inline
bool SEHashSet<T>::operator!=(const SEHashSet<T>& lhs) const 
{
   return !this->operator ==(lhs);
}

}

#endif // SLICKEDIT_HASHSET_H
