////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_ARRAY_H
#define SLICKEDIT_ARRAY_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "vsmsgdefs_slicki.h"
#include "SEMemory.h"
#include "SEAllocator.h"
#include "SEIterator.h"
#include <stdlib.h>
#include <new>

// set this to 1 to enable array boundary checking
#if VSDEBUG
#define SLICKEDIT_ARRAY_BOUNDS_CHECKS 1
#else
#define SLICKEDIT_ARRAY_BOUNDS_CHECKS 0
#endif
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
#include <assert.h>
#endif

namespace slickedit {

/**
 * Manage an array of elements of type T.  The array can dynamically
 * grow if needed.  Elememts of the array can be indexed via the []
 * operator.
 * <P>
 * The array can also be sorted into ascending order by providing a
 * comparison function for the specific template class type.
 * <P>
 * Requirements:
 * <UL>
 * <LI>Type T must have a default constructor (ie. a constructor with no
 *     required arguments), a copy constructor, and an assignment operator.
 * <LI>For comparisons, the < and == operators are used.  If these operators
 *     are not available, a compare proc can also be registered.
 * </UL>
 *
 * @see SEStack
 * @see SEString
 * @see SEQueue
 * @see SEHashTable
 */
template <class T>
class SEArray : public SEMemory {
public:
   /**
    * Item comparison function for elements of the array.
    *
    * @see sortedAdd()
    * @see sortedSearch()
    * @see registerCompareProc()
    */
   typedef int (*CompareProc)( const T *item1, const T *item2 );
   typedef void (*ForEachProcConst)( const T & item1, int indent );
   typedef void (*ForEachProc)( T & item1,int indent );

   /**
    * Default constructor for SEArray, you may specify an
    * optional initial capacity for the array, and the array
    * will be initialized with that many elements.  If the
    * allocation of the initial array fails, _plist will be null.
    *
    * @param initialCapacity (optional) initial capacity of array
    */
   SEArray(size_t initialCapacity=0);
   /**
    * Copy constructor for SEArray class.  Performs a deep copy
    * of the array.  If allocation fails, _plist will be null.
    *
    * @param src        SEArray to copy.
    */
   SEArray(const SEArray<T> &src);
   /**
    * Destructor.  Individually destructs each item allocated
    * by the array, and then deletes the array itself.
    */
   ~SEArray();
   /**
    * Assignment operator for SEArray.  Performs a deep copy
    * of the array contents.  If the array has to grow, but
    * the allocation fails, you will know because this.length()
    * will not equal src.length().
    *
    * @param src        SEArray to copy
    *
    * @return *this
    */
   SEArray<T> & operator=(const SEArray<T> &src);

   /**
    * Comparison operator
    *
    * @param rhs        right hand side of == expression
    */
   bool operator==(const SEArray<T> &rhs) const;
   bool operator!=(const SEArray<T> &rhs) const;

   /**
    * Set length to 0.  No destructors are called.
    */
   void clear();
   /**
    * Make the SEArray empty, completely empty.
    * Calls destructors and deallocates _plist.
    */
   void makeEmpty();

   /**
    * Efficiently exchange the contents of the two array objects. 
    * This will safely swap the contents of the arrays
    * without doing any expensive copying or allocation.
    * 
    * @param lhs  [reference] array to swap contents with
    */
   void exchangeContentsWith(SEArray<T> &lhs);

   /**
    * Default comparison function to be used when their is on comparison 
    * function registered for this class.  Relies on 'T' supporting == and < 
    *  
    * @param item1   pointer to first item to compare 
    * @param item2   pointer to second item to compare 
    *  
    * @return <0 if item1 < item2, 0 if equal, and >0 if item1 > item2
    */
   static int defaultCompareFunc( const T *item1, const T *item2 );

   /**
    * Add a new item into its proper sorted position in the list.
    * The array is assumed to be sorted in ascending order.
    *
    * @param item   Item to be added
    *
    * @return 0 if successful, <0 on error.
    */
   int sortedAdd(const T & item);
   /**
    * Search for the specified item in the array, assuming the
    * array is sorted in ascending order.  This function uses
    * a binary search algorithm for effeciency.
    *
    * @param item   Item to be searched for
    *
    * @return Index of the item in the array, -1 for item not found.
    */
   int sortedSearch(const T & item) const;

   /**
    * Sort the array. Uses the c-runtime function qsort() to sort 
    * the array.
    *  
    * @param pfn_qsort_cmp    qsort compatible sort function.
    */
   void sort(int (*pfn_qsort_cmp)(const void *p1,const void *p2) = NULL);

   /**
    * Append new item to the end of the array.
    *
    * @param item         Item to be appended
    *
    * @return 0 if successful, <0 on error.
    */
   int add(const T & item);
   /**
    * Append all the items from the given array to the
    * end of this array.
    *
    * @param array        Array to append items from
    *
    * @return 0 if successful, <0 on error.
    */
   int add(const SEArray<T>& array);

   /**
    * Insert the item at the specified index.
    * The specified index must be within 0 and length().
    * 
    * @param item   Item to be inserted
    * @param index  Desired index to insert the item
    * @param count  Number of times to insert item.
    * 
    * @return 0 for OK, -1 index error, <0 on other error..
    */
   int insert(const T & item, size_t index, size_t count);
   /**
    * Insert the item() at the specified index. The specified index
    * must be within 0 and length(). 
    * 
    * @param parray  Pointer to items
    * @param count  Number of items pointed to by parray.
    * @param index  Desired index to insert the items
    * 
    * @return 0 for OK, -1 index error, <0 on other error..
    */
   int insertArray(const T *parray, size_t count, size_t index );
   /**
    * Insert the item at the specified index.
    * The specified index must be within 0 and length().
    *
    * @param item         Item to be inserted
    * @param index        Desired index to insert the item
    *
    * @return 0 for OK, -1 index error, <0 on other error..
    */
   int insert(const T & item, size_t index);
   /**
    * Delete the item at the specified index in the list.
    *
    * @param index        Index of item to remove
    *
    * @return 0 for OK, -1 for index out-of-range.
    */
   int remove(size_t index);
   /**
    * Delete up to 'count' items at the specified index in the list.
    *
    * @param index        Index of item to remove
    * @param count        Number of items to remove
    *
    * @return 0 for OK, -1 for index out-of-range.
    */
   int remove(size_t index, size_t count);

   /**
    * Search for the specified item in the array.
    * A linear search is used.
    *
    * @param item         Item to be searched for
    *
    * @return Index of the item in the array, -1 for item not found.
    *         Index 0 indicates the first item in the array.
    */
   int search(const T & item) const;
   /**
    * @return Return the number of items stored in the array.
    */
   size_t length() const;
   /**
    * @return Return 'true' if the given index is valid for this array.
    */
   bool isValidIndex(size_t i) const;
   bool isValidIndex(int i) const;

   /**
    * Register a function to be used to compare items stored
    * in the array.  This function will be used by the search
    * functions, and the sortedAdd functions.
    *
    * @param proc  Comparison function, taking two arguments of the T,
    *              and returning  an integer <0, 0, or >0.
    *
    * @return 0 on success, <0 on error
    */
   int registerCompareProc(CompareProc proc);
   /**
    * Return the pointer to the compare function used to compare
    * items stored in the array.
    *
    * @return function pointer, 0 if not defined.
    */
   CompareProc getCompareProc() const;

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
    * Return a copy of the array of items.
    * The caller should delete the returning array.
    *
    * @return Returns a deep copy of the list of items,
    *         or null pointer for out-of-memory.
    */
   T *copyItems() const;
   T *getItems() const;

   /**
    * Array access operator that may be used as part of
    * the LHS of an expression (an assignment, for example).
    *
    * @param index        array index
    *
    * @return reference to item at specified index
    */
   T & operator[]( int index );
   T & operator[]( size_t index );
   /**
    * Array access operator returning a constant reference to the item.
    *
    * @param index        array index
    *
    * @return 'const' reference to item at specified index
    */
   const T & operator[]( int index ) const;
   const T & operator[]( size_t index ) const;

   /**
    * @return Return a reference to the first element in the array.
    */
   T & first();
   const T & first() const;

   /**
    * @return Return a reference to the first element in the array.
    */
   T & last();
   const T & last() const;

   /**
    * Dereferencing operator is overloaded to return a
    * pointer to the list of items.
    *
    * @return Return a pointer to the list of items.
    */
   operator T *();

   /**
    * Make array large enough to hold the given number of
    * elements.  The length of the array is increased if
    * necessary.
    *
    * @param numItems   the number of items to expand array to hold.
    *
    * @return 0 if ok, INSUFFICIENT_MEMORY_RC if allocation failed
    *
    * @example To make an array with 32 elements
    * <PRE>
    *    SEArray<int> ia;
    *    ia.increaseLength(32);
    * </PRE>
    */
   int increaseLength(size_t numItems);
   /**
    * Set the length of the array to exactly 'numItems' items.
    * Note how this differs from increaseLength(), above, which
    * only grows the array if necessary, but will never decrease
    * the size of the array.
    *
    * @param numItems     New length of array
    *
    * @return 0 if ok, INSUFFICIENT_MEMORY_RC if allocation fails
    */
   int setLength(size_t numItems);
   /**
    * Set the length of the array and initialize new elements
    * with the given object.
    *
    * @param numItems     New length of array
    * @param defValue     Default value
    *
    * @return 0 if ok, INSUFFICIENT_MEMORY_RC if allocation fails
    */
   int setLength(size_t numItems, T defValue);

   /**
    * Return the number of items currently allocated to this array.
    */
   size_t getCapacity() const;

   /**
    * Make the array large enough to hold at least
    * the given number of items.
    * <p>
    * NOTE:  This has no effect if getCapacity() is already >= 'numItems'.
    * <p>
    * The array size is increased by allocating a new larger array,
    * copy the contents of the old array over, and delete the old array.
    *
    * @param numItems      New capacity for array
    *
    * @return 0 if ok, INSUFFICIENT_MEMORY_RC if allocation fails
    */
   int setCapacity(size_t numItems);
   /**
    * Increase the array enough to hold the given number more items 
    * than than it's current length. 
    * <p>
    * NOTE:  This has no effect if getCapacity() is already >= length() + numItems.
    * <p>
    * The array size is increased by allocating a new larger array,
    * copy the contents of the old array over, and delete the old array.
    *
    * @param numItems      New capacity for array
    *
    * @return 0 if ok, INSUFFICIENT_MEMORY_RC if allocation fails
    */
   int increaseCapacity(size_t numItems);

   /**
    * Call a function for each element of the array
    * @param pfnForEach function to call.  Must match typedef void (*ForEachProcConst)( const T & item1,int indent );
    * @param toCallback Value that is passed to the callback with each item
    */
   void forEach(ForEachProcConst pfnForEach,int toCallback=0) const;

   /**
    * Call a function for each element of the array
    * @param pfnForEach function to call.  Must match typedef void (*ForEachProc)( T & item1,int indent );
    * @param toCallback Value that is passed to the callback with each item
    */
   void forEach(ForEachProc pfnForEach,int toCallback=0);

   /**
    * Is this array empty?
    */
   bool isEmpty() const;
   /**
    * Is this array *not* empty?
    */
   bool isNotEmpty() const;


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
   const T* nextItem(SEIterator &iter, size_t &key) const;
   T* nextItem(SEIterator &iter, size_t &key);
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
   const T* prevItem(SEIterator &iter, size_t &key) const;
   T* prevItem(SEIterator &iter, size_t &key);
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
   const T* currentItem(const SEIterator &iter, size_t &key) const;
   T* currentItem(const SEIterator &iter, size_t &key);
   const T* currentItem(const SEIterator &iter) const;
   T* currentItem(const SEIterator &iter);

   /**
    * Get the current iterator key. 
    * If 'iter' is uninitialized, the result is undefined. 
    * 
    * @return Returns the current iterator key
    */
   const size_t currentKey(const SEIterator &iter) const;

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


private:

   // NOTE:  the member 'mList' should really be an array of T
   //
   //    T  mList[1];
   //
   // However if declared this way, the compiler will not
   // allow you to declare a self-recursive object that uses
   // SEArray as follows:
   //
   //    struct selfRecursiveTree {
   //       SEArray<selfRecursiveTree> children;
   //    };
   //
   // Because existing code uses SEArray in this manner, we
   // have to declare 'mList' opaquely and cast '&mList' to
   // a pointer to T.
   //
   //   T* p = &mArrayBuf->mList;
   //
   // IT IS CRITICAL TO REALIZE THAT 'mList' IS NOT A POINTER.
   // It just plays one on TV.
   //
   struct SEArrayBuf {
      CompareProc     pfnCompare;   // Compare proc
      unsigned int    mNumItems;    // Number of items in array
      void *          mList;        // Array Buffer.
   };

   // Array buffer
   SEArrayBuf *mArrayBuf;

   // utility functions
   const size_t headerSize() const;

   T* nextItemInternal(SEIterator &iter, size_t *key=NULL) const;
   T* prevItemInternal(SEIterator &iter, size_t *key=NULL) const;
   T* currentItemInternal(const SEIterator &iter, size_t *key=NULL) const;
};


///////////////////////////////////////////////////////////////////////////
// INLINE METHODS for SEArray
//

template<class T> inline
const size_t SEArray<T>::headerSize() const
{
   return (sizeof(SEArrayBuf)-sizeof(void*));
}

template<class T> inline
size_t SEArray<T>::getCapacity() const
{
   if (!mArrayBuf) return 0;
   return (SEAllocator::numBytesAllocated(mArrayBuf) - headerSize()) / sizeof(T);
}

template<class T> inline
SEArray<T>::SEArray(size_t initialCapacity):
   mArrayBuf(0)
{
   if (initialCapacity) {
      mArrayBuf = (SEArrayBuf*) SEAllocator::allocate(sizeof(T)*initialCapacity+headerSize());
      if (!mArrayBuf) {
         return;
      }
      memset(mArrayBuf,0,SEAllocator::numBytesAllocated(mArrayBuf));
      size_t numberAllocated = getCapacity();
      T* pItem = (T*) &mArrayBuf->mList;
      for (size_t j=0; j < numberAllocated; ++j,++pItem) {
         ::new((void *) pItem) T;
      }
   }
}

template<class T> inline
SEArray<T>::SEArray(const SEArray<T> &src):
   mArrayBuf(0)
{
   if (src.mArrayBuf) {
      size_t j,n=src.mArrayBuf->mNumItems;
      mArrayBuf = (SEArrayBuf*) SEAllocator::allocate(sizeof(T)*n+headerSize());
      if (!mArrayBuf) {
         return;
      }
      memset(mArrayBuf,0,SEAllocator::numBytesAllocated(mArrayBuf));
      T* pDst = (T*) &mArrayBuf->mList;
      T* pSrc = (T*) &src.mArrayBuf->mList;
      for (j=0; j<n; ++j) {
         ::new((void *) pDst) T;
         *pDst++ = *pSrc++;
      }
      size_t numberAllocated = getCapacity();
      for (j=n; j<numberAllocated; ++j,++pDst) {
         ::new((void *) pDst) T;
      }
      mArrayBuf->mNumItems  = (unsigned int)n;
      mArrayBuf->pfnCompare = src.mArrayBuf->pfnCompare;
   }
}

template<class T> inline
SEArray<T> & SEArray<T>::operator=(const SEArray<T> &src)
{
   if (this != &src) {
      if (src.mArrayBuf) {
         size_t j,n=src.mArrayBuf->mNumItems;
         setCapacity(n);
         if (mArrayBuf) {
            T* pDst = (T*) &mArrayBuf->mList;
            T* pSrc = (T*) &src.mArrayBuf->mList;
            for (j=0; j<n; ++j) {
               *pDst++ = *pSrc++;
            }
            mArrayBuf->mNumItems = (unsigned int)n;
            mArrayBuf->pfnCompare=src.mArrayBuf->pfnCompare;;
         }
      } else if (mArrayBuf) {
         mArrayBuf->mNumItems=0;
         mArrayBuf->pfnCompare=0;
      }
   }
   return(*this);
}

template<class T> inline
SEArray<T>::~SEArray()
{
   if (mArrayBuf) {
      size_t numberAllocated = getCapacity();
      T* pItem = (T*) &mArrayBuf->mList;
      for (size_t i=0; i<numberAllocated; ++i,++pItem) {
         pItem->~T();
      }
      SEAllocator::deallocate(mArrayBuf);
      mArrayBuf=0;
   }
}

template <class T>
inline bool SEArray<T>::operator ==(const SEArray<T>& rhs) const
{
   // same array buffer, then they match
   if (mArrayBuf == rhs.mArrayBuf) {
      return true;
   }
   // check array lengths
   size_t i,n=length();
   if (n != rhs.length()) {
      return false;
   }
   // compare each item
   T* pRHS = (T*) &mArrayBuf->mList;
   T* pLHS = (T*) &mArrayBuf->mList;
   for (i=0; i<n; ++i) {
      if (mArrayBuf->pfnCompare) {
         if (mArrayBuf->pfnCompare(pRHS++,pLHS++)!=0) {
            return false;
         }
      } else {
         if (*pRHS++ != *pLHS++) {
            return false;
         }
      }
   }
   return true;
}
template <class T>
inline bool SEArray<T>::operator !=(const SEArray<T>& rhs) const
{
   return ! operator==(rhs);
}

template<class T> inline
void SEArray<T>::makeEmpty()
{
   if (mArrayBuf) {
      size_t numberAllocated = getCapacity();
      T* pItem = (T*) &mArrayBuf->mList;
      for (size_t i=0; i<numberAllocated; ++i,++pItem) {
         pItem->~T();
      }
      SEAllocator::deallocate(mArrayBuf);
      mArrayBuf=0;
   }
}

template<class T> inline
void SEArray<T>::exchangeContentsWith(SEArray<T> &lhs)
{
   SEArrayBuf *tmpArrayBuf = lhs.mArrayBuf;
   lhs.mArrayBuf = this->mArrayBuf;
   this->mArrayBuf = tmpArrayBuf;
}

template<class T> inline
int SEArray<T>::registerCompareProc(typename SEArray<T>::CompareProc proc)
{
   if (!mArrayBuf) {
      setCapacity(1);
   }
   if (!mArrayBuf) {
      return INSUFFICIENT_MEMORY_RC;
   }
   mArrayBuf->pfnCompare = proc;
   return 0;
}
template<class T> inline
typename SEArray<T>::CompareProc SEArray<T>::getCompareProc() const
{
   if (!mArrayBuf) return 0;
   return mArrayBuf->pfnCompare;
}

template<class T> inline
T & SEArray<T>::operator[]( int index )
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index < (int)length());
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[index];
}
template<class T> inline
T & SEArray<T>::operator[]( size_t index )
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index < (size_t)length());
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[index];
}

template<class T> inline
const T & SEArray<T>::operator[]( int index ) const
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index < (int)length());
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[index];
}
template<class T> inline
const T & SEArray<T>::operator[]( size_t index ) const
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index < (size_t)length());
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[index];
}

template<class T> inline
SEArray<T>::operator T *()
{
   if (!mArrayBuf) return 0;
   return (T*) &mArrayBuf->mList;
}

template<class T> inline
T & SEArray<T>::first() 
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(length() > 0);
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[0];
}

template<class T> inline
const T & SEArray<T>::first() const 
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(length() > 0);
#endif
   const T* p = (T*) &mArrayBuf->mList;
   return p[0];
}

template<class T> inline
T & SEArray<T>::last() 
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(length() > 0);
#endif
   T* p = (T*) &mArrayBuf->mList;
   return p[mArrayBuf->mNumItems-1];
}

template<class T> inline
const T & SEArray<T>::last() const 
{
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(length() > 0);
#endif
   const T* p = (T*) &mArrayBuf->mList;
   return p[mArrayBuf->mNumItems-1];
}

template<class T> inline
size_t SEArray<T>::length() const
{
   if (!mArrayBuf) return 0;
   return mArrayBuf->mNumItems;
}

template<class T> inline
bool SEArray<T>::isValidIndex(size_t i) const
{
   if (!mArrayBuf) return false;
   return (i < mArrayBuf->mNumItems);
}

template<class T> inline
bool SEArray<T>::isValidIndex(int i) const
{
   if (!mArrayBuf) return false;
   return (i >= 0 && i < (int)mArrayBuf->mNumItems);
}

template<class T> inline
void SEArray<T>::clear()
{
   if (mArrayBuf) {
      mArrayBuf->mNumItems=0;
   }
}

template<class T> inline
int SEArray<T>::sortedAdd( const T & item )
{
   // Allocate a larger array if needed:
   size_t numItems = length();
   int status = setCapacity(numItems+1);
   if (status < 0) {
      return status;
   }

   // Special case for empty list:
   if (numItems==0) {
      T* p = (T*) &mArrayBuf->mList;
      *p = item;
      mArrayBuf->mNumItems = 1;
      return 0;
   }

   // Loop from the end of the array and move the items up as we search for
   // the correct location for the new item:
   // The loop is split into two sections for speed.
   T * p = (T*) &mArrayBuf->mList;
   T * curr = &p[ numItems-1 ];
   T * prev = &p[ numItems   ];
   CompareProc pfnCompare = mArrayBuf->pfnCompare;
   if ( pfnCompare ) {
      for ( size_t i = numItems; i > 0; i-- ) {
         if ( pfnCompare( &item, curr ) >= 0 ) {
            break;
         }
         *prev-- = *curr--;
      }
   } else {
      for ( size_t i = numItems; i > 0; i-- ) {
         if ( item < *curr ) {
            *prev-- = *curr--;
         } else {
            break;
         }
      }
   }

   // 'previous' is at the insertion point
   *prev = item;

   // finally, increment the item count
   mArrayBuf->mNumItems++;
   return 0;
}

template<class T> inline
int SEArray<T>::sortedSearch( const T & item ) const
{
   // no items at all?
   if (!mArrayBuf) return -1;

   // Search for the specified item in the array.
   // A binary search is used.
   // The code is split into two sections for speed.
   const T* pList = (T*) &mArrayBuf->mList;
   CompareProc pfnCompare = mArrayBuf->pfnCompare;
   size_t numItems = mArrayBuf->mNumItems;
   if (numItems <= 0) return -1;
   const T * middleItem;
   int first = 0, last = (int)numItems-1, middle, result;
   if ( pfnCompare ) {
      // use callback
      while ( first <= last ) {
         middle = ( first + last ) / 2;
         middleItem = &pList[middle];
         result = pfnCompare( &item, middleItem );
         if ( result == 0 ) return ( middle );
         else if ( result < 0 ) last = middle - 1;
         else first = middle + 1;
      }
   } else {
      // use operator == and operator <
      while ( first <= last ) {
         middle = ( first + last ) >> 1;
         middleItem = &pList[ middle ];
         if ( item == *middleItem ) return ( middle );
         else if ( item < *middleItem ) last = middle - 1;
         else first = middle + 1;
      }
   }
   // did not find the item
   return -1;
}

template<class T> inline
int SEArray<T>::defaultCompareFunc( const T *item1, const T *item2 )
{
   if (item1 == item2) return 0;
   if (item1 == 0) return -1;
   if (item2 == 0) return 1;
   if (*item1 == *item2) return 0;
   return (*item1 < *item2)? -1 : 1;
}

template<class T> inline
void SEArray<T>::sort(int (*pfn_qsort_cmp)(const void *p1,const void *p2))
{
   // no items at all?
   if (!mArrayBuf) return;

   if (!pfn_qsort_cmp) {
      pfn_qsort_cmp = (int (*)(const void *p1,const void *p2))  mArrayBuf->pfnCompare;
      if (!pfn_qsort_cmp) {
         pfn_qsort_cmp = (int (*)(const void *p1,const void *p2)) defaultCompareFunc;
      }
   }

   T* pList = (T*) &mArrayBuf->mList;
   size_t numItems = mArrayBuf->mNumItems;

   qsort(pList,(int)numItems,sizeof(T),pfn_qsort_cmp);
}

template<class T> inline
int SEArray<T>::add(const T & item)
{
   // Allocate a larger array if needed:
   size_t numItems = length();
   int status = setCapacity(numItems+1);
   if (status < 0) {
      return status;
   }

   // Append new item to the end of the array:
   T* p = (T*) &mArrayBuf->mList;
   p[numItems] = item;
   mArrayBuf->mNumItems++;
   return(0);
}

template<class T> inline
int SEArray<T>::add(const SEArray<T> & array)
{
   // Allocate a larger array if needed:
   size_t numItems = length();
   size_t newItems = array.length();
   int status = setCapacity(numItems+newItems);
   if (status < 0) {
      return status;
   }

   // Append new item to the end of the array:
   if (mArrayBuf) {
      T* p = (T*) &mArrayBuf->mList;
      T* q = (T*) &array.mArrayBuf->mList;
      for (size_t i=0; i<newItems; ++i) {
         p[numItems++] = q[i];
      }
      mArrayBuf->mNumItems = (unsigned int)numItems;
   }
   return(0);
}

template<class T> inline
int SEArray<T>::insert(const T & item, size_t index, size_t count)
{
   // Check to make sure that index is within the valid range:
   size_t numItems = length();
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index <= numItems);
#endif
   if ( index > numItems ) return -1;
   if ( !count ) return(0);

   // Allocate a larger array if needed:
   // Try twice the size of the previous array...
   int status = setCapacity(numItems+count);
   if (status < 0) {
      return status;
   }

   // Make space for the new item by moving the items starting from the
   // specified index up one step:
   T * p = (T*) &mArrayBuf->mList;
   if ( index < numItems ) {
      T * next = &p[ numItems+count-1   ];
      T * curr = &p[ numItems-1 ];
      for ( size_t i = numItems; i > index; i-- ) {
         *next-- = *curr--;
      }
   }
   // copy in the item
   mArrayBuf->mNumItems += (unsigned int)count;
   while (count--) {
      p[index++] = item;
   }
   return(0);
}
template<class T> inline
int SEArray<T>::insertArray(const T *parray, size_t count, size_t index )
{
   // Check to make sure that index is within the valid range:
   size_t numItems = length();
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index <= numItems);
#endif
   if ( index > numItems ) return -1;
   if ( !count ) return(0);

   // Allocate a larger array if needed:
   // Try twice the size of the previous array...
   int status = setCapacity(numItems+count);
   if (status < 0) {
      return status;
   }

   // Make space for the new items by moving the items starting from the
   // specified index up one step:
   T * p = (T*) &mArrayBuf->mList;
   if ( index < numItems ) {
      T * next = &p[ numItems+count-1   ];
      T * curr = &p[ numItems-1 ];
      for ( size_t i = numItems; i > index; i-- ) {
         *next-- = *curr--;
      }
   }
   // copy in the items
   mArrayBuf->mNumItems += (unsigned int)count;
   for (size_t i=0;i<count;++i) {
      p[index++] = parray[i];
   }
   return(0);
}
template<class T> inline
int SEArray<T>::insert(const T & item, size_t index)
{
   // Check to make sure that index is within the valid range:
   size_t numItems = length();
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index <= numItems);
#endif
   if ( index > numItems ) return -1;

   // Allocate a larger array if needed:
   // Try twice the size of the previous array...
   int status = setCapacity(numItems+1);
   if (status < 0) {
      return status;
   }

   // Make space for the new item by moving the items starting from the
   // specified index up one step:
   T * p = (T*) &mArrayBuf->mList;
   if ( index < numItems ) {
      T * next = &p[ numItems   ];
      T * curr = &p[ numItems-1 ];
      for ( size_t i = numItems; i > index; i-- ) {
         *next-- = *curr--;
      }
   }
   // copy in the item
   p[index] = item;
   mArrayBuf->mNumItems++;
   return(0);
}

template<class T> inline
int SEArray<T>::remove(size_t index)
{
   // empty array?
   if (!mArrayBuf) return -1;

   // check if beyond end of array
   size_t numItems = mArrayBuf->mNumItems;
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index < numItems);
#endif
   if ( index >= numItems ) return -1;

   // Delete entry by shifting all higher entries down:
   if ( index < numItems-1 ) {
      T * p = (T*) &mArrayBuf->mList;
      T * curr = &p[ index   ];
      T * next = &p[ index+1 ];
      for ( size_t j = index; j < numItems-1; j++ ) {
         *curr++ = *next++;
      }
   }

   // finally decrement the item count
   mArrayBuf->mNumItems--;
   return ( 0 );
}

template<class T> inline
int SEArray<T>::remove(size_t index, size_t count)
{
   // nothing to delete?
   if (count <= 0) return 0;

   // empty array?
   if (!mArrayBuf) return -1;

   // check if beyond end of array
   size_t numItems = mArrayBuf->mNumItems;
#if SLICKEDIT_ARRAY_BOUNDS_CHECKS
   assert(index >= 0);
   assert(index <= numItems);
#endif
   if ( index >= numItems ) return -1;
   if ( index+count > numItems ) {
      count = numItems-index;
   }

   // Delete entry by shifting all higher entries down:
   if ( index < numItems-1 ) {
      T * p = (T*) &mArrayBuf->mList;
      T * curr = &p[ index       ];
      T * next = &p[ index+count ];
      for ( size_t j = index; j < numItems-count; j++ ) {
         *curr++ = *next++;
      }
   }

   // finally decrement the item count
   mArrayBuf->mNumItems -= (unsigned int)count;
   return ( 0 );
}

template<class T> inline
int SEArray<T>::search(const T & item) const
{
   // no items at all?
   if (!mArrayBuf) return -1;

   // If a compare proc is defined, use it.  Otherwise, use the default ==
   // operator on the items.  We separate the code into two sections for speed.
   T* current = (T*) &mArrayBuf->mList;
   CompareProc pfnCompare = mArrayBuf->pfnCompare;
   size_t i,numItems = mArrayBuf->mNumItems;
   if ( pfnCompare ) {
      // use callback
      for (i=0; i<numItems; i++) {
         if ( pfnCompare( &item, current ) == 0 ) {
            return (int)( i );
         }
         current++;
      }
   } else {
      // use operator == and operator <
      for (i=0; i<numItems; i++) {
         if ( item == *current++ ) {
            return (int)( i );
         }
      }
   }

   // did not find the item
   return -1;
}

template<class T> inline
T ** SEArray<T>::copyItemPointers() const
{
   // get number of items
   size_t numItems = length();
   if (numItems==0) return 0;

   // allocate list object
   T** pArray = new T*[ length() ];
   if ( pArray == 0 ) return 0;

   // copy the list
   T* pSrc = (T*) &mArrayBuf->mList;
   T** pDst = pArray;
   for (size_t i=0; i<numItems; i++) {
      *pDst++ = &pSrc[i];
   }

   // return the new list
   return pArray;
}
template<class T> inline
T * SEArray<T>::copyItems() const
{
   // get number of items
   size_t numItems = length();
   if (numItems==0) return 0;

   // allocate list object
   T* pArray = new T[numItems];
   if ( pArray == 0 ) return 0;

   // copy the list
   T* pSrc = (T*) &mArrayBuf->mList;
   T* pDst = pArray;
   for (size_t i=0; i<numItems; i++) {
      *pDst++ = *pSrc++;
   }

   // return the new list
   return pArray;
}
template<class T> inline
T * SEArray<T>::getItems() const
{
   // get number of items
   size_t numItems = length();
   if (numItems==0) return 0;
   return((T *)&mArrayBuf->mList);
}

template<class T> inline
int SEArray<T>::increaseLength(size_t numItems)
{
   int status = setCapacity(numItems);
   if (status < 0) {
      return status;
   }
   if (mArrayBuf && numItems >= mArrayBuf->mNumItems) {
      mArrayBuf->mNumItems = (unsigned int)numItems;
   }
   return(0);
}
template<class T> inline
int SEArray<T>::setLength(size_t numItems)
{
   // special case for empty array
   if (numItems<=0) {
      if (mArrayBuf) mArrayBuf->mNumItems=0;
      return 0;
   }
   // check if array is big enough
   int status = setCapacity(numItems);
   if (status < 0) {
      return status;
   }
   // save the new length
   if (mArrayBuf) {
      mArrayBuf->mNumItems = (unsigned int)numItems;
   }
   return(0);
}

template<class T> inline
int SEArray<T>::setLength(size_t numItems, T defValue)
{
   // special case for empty array
   if (numItems<=0) {
      if (mArrayBuf) mArrayBuf->mNumItems=0;
      return 0;
   }
   // check if array is big enough
   int status = setCapacity(numItems);
   if (status < 0) {
      return status;
   }
   // initialize the new items
   if (mArrayBuf) {
      T* p = (T*) &mArrayBuf->mList;
      for (size_t i=mArrayBuf->mNumItems; i<numItems; ++i) {
         p[i] = defValue;
      }
      // save the new length
      mArrayBuf->mNumItems = (unsigned int)numItems;
   }
   return(0);
}

template<class T> inline
int SEArray<T>::increaseCapacity(size_t numItems)
{
   return setCapacity(length() + numItems);
}
template<class T> inline
int SEArray<T>::setCapacity(size_t numItems)
{
   // Allocate a larger array if needed:
   size_t numberAllocated = getCapacity();
   if (numItems > numberAllocated) {

      // Try twice the size of the previous array...
      size_t origLength = length();
      size_t newCapacity = origLength*2;
      if (newCapacity <= numItems) {
         newCapacity = numItems+1;
      }

      // allocate the new array
      SEArrayBuf* oldArray = mArrayBuf;
      SEArrayBuf* newArray = (SEArrayBuf*) SEAllocator::allocate(sizeof(T)*newCapacity+headerSize());
      if (!newArray) {
         return INSUFFICIENT_MEMORY_RC;
      }

      // save the new array pointer and it's actual capacity
      memset(newArray,0,SEAllocator::numBytesAllocated(newArray));
      mArrayBuf = newArray;
      newCapacity = getCapacity();

      T* pDst = (T*) &newArray->mList;
      if (oldArray) {
         // copy the items from the original array
         T* pSrc = (T*) &oldArray->mList;
         for (size_t i=0; i<origLength; ++i) {
            ::new((void *) pDst) T;
            *pDst++ = *pSrc++;
         }
         // save the number of items and the compare proc
         newArray->mNumItems  = oldArray->mNumItems;
         newArray->pfnCompare = oldArray->pfnCompare;
         // destruct the items in the old array
         pSrc = (T*) &oldArray->mList;
         for (size_t j=0; j<numberAllocated; ++j,++pSrc) {
            pSrc->~T();
         }
         // free Willy!
         SEAllocator::deallocate(oldArray);
      }

      // initialize the rest of the items in the array
      for (size_t k=origLength; k<newCapacity; ++k, ++pDst) {
         ::new((void *) pDst) T;
      }
   }

   // success!
   return (0);
}
template<class T> inline
void SEArray<T>::forEach(ForEachProcConst pfnForEach,int toCallback) const
{
   if (!pfnForEach || !mArrayBuf) {
      return;
   }
   const T* p = (const T*) &mArrayBuf->mList;

   size_t i,numItems = mArrayBuf->mNumItems;
   for (i=0;i<numItems;++i) {
      (*pfnForEach)(p[i],toCallback);
   }
}

template<class T> inline
void SEArray<T>::forEach(ForEachProc pfnForEach,int toCallback)
{
   if (!pfnForEach || !mArrayBuf) {
      return;
   }
   T* p = (T*) &mArrayBuf->mList;

   size_t i,numItems = mArrayBuf->mNumItems;
   for (i=0;i<numItems;++i) {
      (*pfnForEach)(p[i],toCallback);
   }
}

template<class T> inline
bool SEArray<T>::isEmpty() const
{
   return (!mArrayBuf || mArrayBuf->mNumItems == 0);
}

template<class T> inline
bool SEArray<T>::isNotEmpty() const
{
   return (mArrayBuf && mArrayBuf->mNumItems > 0);
}

template <class T> inline
T* SEArray<T>::nextItemInternal(SEIterator &iter, size_t *pKey) const
{
   if (mArrayBuf==NULL || mArrayBuf->mNumItems <= 0) {
      return NULL;
   }
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      iter.mIndex = 0;
      iter.mpNode = NULL;
   } else if (iter.mIndex+1 < mArrayBuf->mNumItems) {
      iter.mIndex++;
   } else {
      return NULL;
   }
   if (pKey) *pKey = iter.mIndex;
   return (T*) &((*this)[iter.mIndex]);
}
template <class T> inline
const T* SEArray<T>::nextItem(SEIterator &iter, size_t &key) const
{
   return nextItemInternal(iter, &key);
}
template <class T> inline
T* SEArray<T>::nextItem(SEIterator &iter, size_t &key)
{
   return nextItemInternal(iter, &key);
}
template <class T> inline
const T* SEArray<T>::nextItem(SEIterator &iter) const
{
   return nextItemInternal(iter);
}
template <class T> inline
T* SEArray<T>::nextItem(SEIterator &iter)
{
   return nextItemInternal(iter);
}

template <class T> inline
T* SEArray<T>::prevItemInternal(SEIterator &iter, size_t *pKey) const
{
   if (mArrayBuf == NULL || mArrayBuf->mNumItems <= 0) {
      return NULL;
   }
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      iter.mIndex = mArrayBuf->mNumItems-1;
      iter.mpNode = NULL;
   } else if (iter.mIndex > 0) {
      iter.mIndex--;
   } else {
      return NULL;
   }
   if (pKey != NULL ) *pKey = iter.mIndex;
   return (T*) &((*this)[iter.mIndex]);
}
template <class T> inline
const T* SEArray<T>::prevItem(SEIterator &iter, size_t &key) const
{
   return prevItemInternal(iter, &key);
}
template <class T> inline
T* SEArray<T>::prevItem(SEIterator &iter, size_t &key)
{
   return prevItemInternal(iter, &key);
}
template <class T> inline
const T* SEArray<T>::prevItem(SEIterator &iter) const
{
   return prevItemInternal(iter);
}
template <class T> inline
T* SEArray<T>::prevItem(SEIterator &iter)
{
   return prevItemInternal(iter);
}

template <class T> inline
T* SEArray<T>::currentItemInternal(const SEIterator &iter, size_t *pKey) const
{
   if (iter.mFindFirst) {
      return NULL;
   }
   if (mArrayBuf == NULL || iter.mIndex >= mArrayBuf->mNumItems) {
      return NULL;
   }
   if (pKey != NULL) *pKey = iter.mIndex;
   return (T*) &((*this)[iter.mIndex]);
}
template <class T> inline
const T* SEArray<T>::currentItem(const SEIterator &iter, size_t &key) const
{
   return currentItemInternal(iter, &key);
}
template <class T> inline
T* SEArray<T>::currentItem(const SEIterator &iter, size_t &key)
{
   return currentItemInternal(iter, &key);
}
template <class T> inline
const T* SEArray<T>::currentItem(const SEIterator &iter) const
{
   return currentItemInternal(iter);
}
template <class T> inline
T* SEArray<T>::currentItem(const SEIterator &iter)
{
   return currentItemInternal(iter);
}
template <class T> inline
const size_t SEArray<T>::currentKey(const SEIterator &iter) const
{
   return iter.mIndex;
}

template <class T> inline
int SEArray<T>::removeItem(SEIterator &iter)
{
   return remove(iter.mIndex);
}

}


#endif // SLICKEDIT_ARRAY_H
