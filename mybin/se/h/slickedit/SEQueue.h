////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_QUEUE_H
#define SLICKEDIT_QUEUE_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "SEMemory.h"
#include "SEIterator.h"
#include "stddef.h"

namespace slickedit {

/**
 * Manage an queue (FIFO collection) of elements of type T.
 *
 * @param T    Type T must have a default constructor
 *             (ie. a constructor with no required arguments),
 *             a copy constructor, and an assignment operator.
 */
template <class T>
class SEQueue : public SEMemory
{
protected:

   /**
    * A queue node of type 'T'.  The queue nodes are doubly-linked lists.
    * <p>
    * NOTE:  This class is to be used only by SEQueue
    */
   class SEQueueNode : public SEMemory
   {
   public:
      // constructor, data item is required
      SEQueueNode( const T & item );
   
      // Points to next node in list
      SEQueueNode *next;
      // Points to prev node in list
      SEQueueNode *prev;
   
      // Node data
      T data;
   };

public:

   /**
    * Default constructor:  Build an empty SEQueue instance.
    */
   SEQueue();

   /**
    * Copy constructor:  Copy a SEQueue instance
    *
    * @param src     SEQueue to copy
    */
   SEQueue(const SEQueue<T> &src);

   /**
    * Destructor:  Clean up an instance of SEQueue.
    */
   ~SEQueue();

   /**
    * Assignment operator:  Copy a SEQueue instance.
    *
    * @param src     SEQueue to copy
    */
   const SEQueue<T>& operator =(const SEQueue<T> &src);


   /**
    * @return Return the number of items in the queue.
    */
   size_t length() const;

   /**
    * Remove everything from the queue.
    */
   int clear();

   /**
    * Add an item to the queue.
    *
    * @parma item    Item to add to queue
    *
    * @return 0 for OK, -1 for error.
    */
   int add(const T& item);

   /**
    * Transfer all items from one queue onto the end of this queue.
    * This operation removes the tokens from the source queue.
    *
    * @param src  queue to transfer tokens from
    */
   int transfer(SEQueue<T> &src);

   /**
    * Get an item from the head of the queue.
    * The item is removed from the queue.
    *
    * @param item    Returned item from queue
    *
    * @return 0 for OK, 1 for queue empty.
    */
   int get( T * item );

   /**
    * Get an item from the tail end of the queue. 
    * The item is removed from the queue. 
    * 
    * @param item    Returned item from queue
    *
    * @return 0 for OK, 1 for queue empty.
    */
   int getTail( T * item );

   /**
    * Peek at the item at the specified position in the queue.
    *
    * @param position   Position of desired item from the head of the queue.
    *                   peek(0) is equivelent to peekHead().
    *        item       Returned item from queue
    *
    * @return 0 for OK, 1 for queue empty, -1 for position out-of-range.
    */
   int peek( size_t position, T * item ) const;
   /**
    * Peek at the item at the specified position in the queue.
    *
    * @param position   Position of desired item from the head of the queue.
    *                   peek(0) is equivelent to peekHead().
    */
   const T* peek( size_t position ) const;
   T* peek( size_t position );

   /**
    * Peek at the item at the head of the queue
    *
    * @param item       Returned item, the head of the queue
    */
   int peekHead( T* item ) const;
   /**
    * Return a pointer to the first item in the queue.
    */
   const T* peekHead() const;
   T* peekHead();

   /**
    * Peek at the item at the tail of the queue
    *
    * @param item       Returned item, the tail of the queue
    */
   int peekTail( T* item ) const;
   /**
    * Return a pointer to the last item in the queue.
    */
   const T* peekTail() const;
   T* peekTail();

   /**
    * Delete the specified item from the queue.
    * 
    * @param item    Item to delete, must support operator == 
    */
   int deleteItem(T item);

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
   
private:

   SEQueueNode* head;   // Head of queue
   SEQueueNode* tail;   // Tail of queue
   size_t itemCount;    // Number of items in queue

};


///////////////////////////////////////////////////////////////////////////
// INLINE METHODS
//

template <class T>
inline SEQueue<T>::SEQueueNode::SEQueueNode(const T& item):
   data(item),
   next(0),
   prev(0)
{
}

template <class T>
inline SEQueue<T>::SEQueue():
   itemCount(0),
   head(0),
   tail(0)
{
}

template <class T>
inline SEQueue<T>::SEQueue(const SEQueue<T> &src):
   itemCount(0),
   head(0),
   tail(0)
{
   SEQueueNode * node = src.head;
   size_t i,n=src.itemCount;
   for (i=0; i<n; ++i) {
      add(node->data);
      node = node->next;
   }
}

  // Name:  SEQueue<T>::~SEQueue<T>
  // Para:
  // Retn:
  // Desc:  Clean up an instance of SEQueue.

template <class T>
inline SEQueue<T>::~SEQueue()
{
   // Delete the queue nodes:
   SEQueueNode * node;
   for ( size_t i = 0; i < itemCount; i++ ) {
     node = head;
     head = head->next;
     delete node;
   }
}

template <class T>
inline const SEQueue<T>& SEQueue<T>::operator =(const SEQueue<T> &src)
{
   if (this != &src) {
      // Copy the leading nodes from the queue
      const SEQueueNode* src_node = src.head;
      SEQueueNode*       dst_node = head;
      size_t i=0;
      while (i<itemCount && i<src.itemCount) {
         dst_node->data = src_node->data;
         dst_node = dst_node->next;
         src_node = src_node->next;
         i++;
      }
      // Delete the remaining nodes from the input
      while (i<itemCount) {
         SEQueueNode* this_node = dst_node;
         SEQueueNode* prev_node = dst_node->prev;
         SEQueueNode* next_node = dst_node->next;
         if (prev_node) prev_node->next=next_node;
         if (next_node) next_node->prev=prev_node;
         dst_node = next_node;
         delete this_node;
         i++;
      }
      // Move the remaining nodes from the src
      while (i<src.itemCount) {
         add(src_node->data);
         src_node = src_node->next;
         i++;
      }
      // update the number of nodes
      itemCount=src.itemCount;
   }
   return *this;
}

template <class T>
inline size_t SEQueue<T>::length() const
{
   return itemCount;
}

template <class T>
inline int SEQueue<T>::add(const T& item)
{
   // Create new queue node:
   SEQueueNode * node = new SEQueueNode(item);
   if (!node) {
      return INSUFFICIENT_MEMORY_RC;
   }

   // Link the node to the end of the queue:
   if ( itemCount == 0 ) {
      head = node;
   } else {
      tail->next = node;
      node->prev = tail;
   }
   tail = node;
   itemCount++;

   // that's all folks
   return( 0 );
}

template <class T>
inline int SEQueue<T>::get( T * item )
{
   // nothing in the queue?
   if ( itemCount == 0 ) {
      return( 1 );
   }
   // get the data from the first item in queue
   *item = head->data;
   // remove the head from the list
   SEQueueNode * oldHead = head;
   head = head->next;
   delete oldHead;
   itemCount--;
   if ( itemCount ) {
      head->prev = (SEQueueNode *)0;
   } else {
      head = tail = NULL;
   }
   // that's all folks
   return( 0 );
}

template <class T>
inline int SEQueue<T>::getTail( T * item )
{
   // nothing in the queue?
   if ( itemCount == 0 ) {
      return( 1 );
   }
   // get the data from the first item in queue
   *item = tail->data;
   // remove the head from the list
   SEQueueNode * oldTail = tail;
   tail = tail->prev;
   delete oldTail;
   itemCount--;
   if ( itemCount ) {
      tail->next = (SEQueueNode *)0;
   } else {
      head = tail = NULL;
   }
   // that's all folks
   return( 0 );
}

template <class T>
inline int SEQueue<T>::clear()
{
   // Delete the queue nodes:
   SEQueueNode * node;
   for ( size_t i = 0; i < itemCount; i++ ) {
     node = head;
     head = head->next;
     delete node;
   }

   // reset all head/tail pointers and item count
   head = tail = NULL;
   itemCount = 0;

   // that's all folks
   return( 0 );
}

template <class T>
inline int SEQueue<T>::peek( size_t position, T * item ) const
{
   // Queue may be empty:
   if ( itemCount == 0 ) {
      return( 1 );
   }
   // Look for a specified index:
   if ( position > itemCount ) {
      return( -1 );
   }
   // iterate over 'n' items
   SEQueueNode * node = head;
   for (size_t i=0; i<position; i++ ) {
      node = node->next;
   }
   *item = node->data;
   // that's all folks
   return( 0 );
}

template <class T>
inline const T* SEQueue<T>::peek( size_t position) const
{
   // Queue may be empty:
   if ( itemCount == 0 ) {
      return NULL;
   }
   // Look for a specified index:
   if ( position > itemCount ) {
      return NULL;
   }
   // iterate over 'n' items
   SEQueueNode * node = head;
   for (size_t i=0; i<position; i++ ) {
      node = node->next;
   }
   // that's all folks
   return &node->data;
}

template <class T>
inline T* SEQueue<T>::peek( size_t position)
{
   // Queue may be empty:
   if ( itemCount == 0 ) {
      return NULL;
   }
   // Look for a specified index:
   if ( position > itemCount ) {
      return NULL;
   }
   // iterate over 'n' items
   SEQueueNode * node = head;
   for (size_t i=0; i<position; i++ ) {
      node = node->next;
   }
   // that's all folks
   return &node->data;
}

template <class T>
inline T* SEQueue<T>::peekHead()
{
   if ( itemCount == 0 ) return NULL;
   if ( head == NULL ) return( NULL );
   return &head->data;
}
template <class T>
inline const T* SEQueue<T>::peekHead() const
{
   if ( itemCount == 0 ) return NULL;
   if ( head == NULL ) return( NULL );
   return &head->data;
}

template <class T>
inline T* SEQueue<T>::peekTail()
{
   if ( itemCount == 0 ) return NULL;
   if ( tail == NULL ) return( NULL );
   return &tail->data;
}
template <class T>
inline const T* SEQueue<T>::peekTail() const
{
   if ( itemCount == 0 ) return NULL;
   if ( tail == NULL ) return( NULL );
   return &tail->data;
}

template <class T>
inline int SEQueue<T>::peekHead( T * item ) const
{
   if ( itemCount == 0 || !head) return( 1 );
   *item = head->data;
   return( 0 );
}
template <class T>
inline int SEQueue<T>::peekTail( T * item ) const
{
   if ( itemCount == 0 || !tail ) return( 1 );
   *item = tail->data;
   return( 0 );
}

template<class T> inline
T ** SEQueue<T>::copyItemPointers() const
{
   // get number of items
   size_t numItems = itemCount;
   if (numItems==0) return 0;

   // allocate list object
   T** pArray = new T*[numItems];
   if ( pArray == 0 ) return 0;

   // copy the list
   SEQueueNode *curr = head;
   for (size_t i=0; i<numItems; i++) {
      pArray[i] = &curr->data;
      curr = curr->next;
   }

   // return the new list
   return pArray;
}

template<class T> inline
T * SEQueue<T>::copyItems() const
{
   // get number of items
   size_t numItems = itemCount;
   if (numItems==0) return 0;

   // allocate list object
   T* pArray = new T[numItems];
   if ( pArray == 0 ) return 0;

   // copy the list
   SEQueueNode *curr = head;
   for (size_t i=0; i<numItems; i++) {
      pArray[i] = curr->data;
      curr = curr->next;
   }

   // return the new list
   return pArray;
}

template <class T> inline
const T* SEQueue<T>::nextItem(SEIterator &iter) const
{
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      if (head != NULL) {
         iter.mpNode = head;
         return &head->data;
      }
   } else if (iter.mpNode != NULL) {
      SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
      if (curr->next != NULL && curr->next != head) {
         curr = curr->next;
         iter.mpNode = curr;
         return &curr->data;
      }
   }

   return NULL;
}
template <class T> inline
T* SEQueue<T>::nextItem(SEIterator &iter)
{
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      if (head != NULL) {
         iter.mpNode = head;
         return &head->data;
      }
   } else if (iter.mpNode != NULL) {
      SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
      if (curr->next != NULL && curr->next != head) {
         curr = curr->next;
         iter.mpNode = curr;
         return &curr->data;
      }
   }

   return NULL;
}

template <class T> inline
const T* SEQueue<T>::prevItem(SEIterator &iter) const
{
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      if (tail != NULL) {
         iter.mpNode = tail;
         return &tail->data;
      }
   } else if (iter.mpNode != NULL) {
      SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
      if (curr->prev != NULL && curr->prev != tail) {
         curr = curr->prev;
         iter.mpNode = curr;
         return &curr->data;
      }
   }

   return NULL;
}
template <class T> inline
T* SEQueue<T>::prevItem(SEIterator &iter)
{
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      if (tail != NULL) {
         iter.mpNode = tail;
         return &tail->data;
      }
   } else if (iter.mpNode != NULL) {
      SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
      if (curr->prev != NULL && curr->prev != tail) {
         curr = curr->prev;
         iter.mpNode = curr;
         return &curr->data;
      }
   }

   return NULL;
}

template <class T> inline
const T* SEQueue<T>::currentItem(const SEIterator &iter) const
{
   if (iter.mFindFirst) {
      return NULL;
   }
   if (iter.mpNode == NULL) {
      return NULL;
   }
   SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
   return &curr->data;
}
template <class T> inline
T* SEQueue<T>::currentItem(const SEIterator &iter)
{
   if (iter.mFindFirst) {
      return NULL;
   }
   if (iter.mpNode == NULL) {
      return NULL;
   }
   SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
   return &curr->data;
}

template <class T> inline
int SEQueue<T>::removeItem(SEIterator &iter)
{
   if ( itemCount == 0 ) return STRING_NOT_FOUND_RC;
   if (iter.mpNode == NULL) return STRING_NOT_FOUND_RC;
   SEQueueNode* curr = (SEQueueNode*) iter.mpNode;
   SEQueueNode* pPrev = curr->prev;
   SEQueueNode* pNext = curr->next;
   if (head==curr) head = pNext;
   if (tail==curr) tail = pPrev;
   delete curr;
   iter.mpNode = pNext;
   if (pPrev) {
      pPrev->next = pNext;
   }
   if (pNext) {
      pNext->prev = pPrev;
   }
   --itemCount;
   if (itemCount==0) {
      head = tail = NULL;
   }
   return 0;
}

template <class T>
inline int SEQueue<T>::deleteItem(T item)
{
   if ( itemCount == 0 ) return STRING_NOT_FOUND_RC;
   SEQueueNode *pCurr = head;
   for (size_t i=0; i<itemCount; i++) {
      if (pCurr->data == item) {
         SEQueueNode* pPrev = pCurr->prev;
         SEQueueNode* pNext = pCurr->next;
         delete pCurr;
         if (head==pCurr) head = pNext;
         if (tail==pCurr) tail = pPrev;
         if (pPrev) {
            pPrev->next = pNext;
         }
         if (pNext) {
            pNext->prev = pPrev;
         }
         --itemCount;
         if (itemCount==0) {
            head = tail = NULL;
         }
         return 0;
      }
      pCurr = pCurr->next;
   }
   return STRING_NOT_FOUND_RC;
}

template <class T>
inline int SEQueue<T>::transfer(SEQueue<T> &src)
{
   // nothing to transfer, that's easy
   if (src.itemCount==0) {
      return 0;
   }

   if (itemCount==0) {
      // usurp the source's head, tail pointers and all itermediate nodes, and item count
      head = src.head;
      tail = src.tail;
   } else {
      // chain the source's nodes into the queue
      tail->next = src.head;
      src.head->prev = tail;
      tail = src.tail;
   }

   // bump the item count
   itemCount += src.itemCount;

   // clear out the source object
   src.head = 0;
   src.tail = 0;
   src.itemCount = 0;

   // that's all folks
   return( 0 );
}

}

#endif // SLICKEDIT_QUEUE_H
