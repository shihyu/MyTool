////////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
// File:        SEIterator.h
// Description: Declaration for the SEIterator class.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "SEMemory.h"
#include <stddef.h>
#include <vsmsgdefs_slicki.h>

namespace slickedit {

/**
 * SEIterator is a black-box class for storing data used to iterate 
 * through the items in a collection class.  It is used by all the 
 * slickedit collection classes to implement nextItem, prevItem, 
 * currentItem, and removeItem methods. 
 * <p>
 * The only things you can do with an SEIterator is construct it, 
 * copy it, reset it, and destroy it.  The state of SEIterator is 
 * always completely private. 
 * <p> 
 * The lifetime of an SEIterator class can not extend beyond 
 * the lifetime of the collection it is being used to iterator over, 
 * unless it is reset. 
 * <p> 
 * Inserting or removing items from a collection invalidates the 
 * state of an iterator, unless you use the removeItem() API that 
 * keeps the iterator in a consistent state. 
 * 
 * @author dbrueni (11/19/2010)
 */
class SEIterator {
public:
   SEIterator();
   SEIterator(const SEIterator &src);
   ~SEIterator();
   SEIterator &operator = (const SEIterator &src);

   void reset();

private:
   bool mFindFirst;              // starting from beginning (or end)
   size_t mIndex;                // index of current item in array 
   void *mpNode;                 // current node being inspected
   SEIterator *mpNext;           // next item in stack
                                 
   int pushStack();
   int popStack();
   int copyStack(const SEIterator &src);
   int clearStack();

   template <class T> friend class SEArray;
   template <class T> friend class SEHashSet;
   template <class T> friend class SEQueue;
   template <class T> friend class SEStack;
   template <class K, class T> friend class SEHashTable;
};


inline SEIterator::SEIterator():
   mFindFirst(true),
   mIndex(0),
   mpNode(nullptr),
   mpNext(nullptr)
{
}
inline SEIterator::SEIterator(const SEIterator &src): 
   mFindFirst(src.mFindFirst),
   mIndex(src.mIndex),
   mpNode(src.mpNode),
   mpNext(nullptr)
{
   copyStack(src);
}
inline SEIterator::~SEIterator() 
{
   clearStack();
   mpNode = nullptr;
   mpNext = nullptr;
}
inline void SEIterator::reset() 
{
   mFindFirst = true;
   mIndex = 0;
   mpNode = nullptr;
   clearStack();
}
inline SEIterator & SEIterator::operator =(const SEIterator &src) 
{
   if (this != &src) {
      mFindFirst = src.mFindFirst;
      mIndex = src.mIndex;
      mpNode = src.mpNode;
      clearStack();
      copyStack(src);
   }
   return *this;
}
inline int SEIterator::copyStack(const SEIterator &src)
{
   SEIterator **ppNext = &mpNext;
   const SEIterator *srcNext = src.mpNext;
   while (srcNext != nullptr) {
      SEIterator *dstNext = new SEIterator();
      if (dstNext == nullptr) return INSUFFICIENT_MEMORY_RC;
      dstNext->mFindFirst = srcNext->mFindFirst;
      dstNext->mIndex = srcNext->mIndex;
      dstNext->mpNode = srcNext->mpNode;
      dstNext->mpNext = nullptr;
      *ppNext = dstNext;
      ppNext = &dstNext->mpNext;
      srcNext = srcNext->mpNext;
   }
   return 0;
}
inline int SEIterator::clearStack()
{
   while (mpNext != nullptr) {
      SEIterator *next = mpNext->mpNext;
      mpNext->mpNext = nullptr;
      delete mpNext;
      mpNext = next;
   }
   mpNext = nullptr;
   return 0;
}
inline int SEIterator::pushStack()
{
   SEIterator *dstNext = new SEIterator();
   if (dstNext == nullptr) return INSUFFICIENT_MEMORY_RC;
   dstNext->mFindFirst = false;
   dstNext->mIndex = mIndex;
   dstNext->mpNode = mpNode;
   dstNext->mpNext = mpNext;
   mpNext = dstNext;
   mpNode = nullptr;
   mIndex = 0;
   return 0;
}
inline int SEIterator::popStack()
{
   if (mpNext == nullptr) return INVALID_ARGUMENT_RC;
   mFindFirst = false;
   mIndex = mpNext->mIndex;
   mpNode = mpNext->mpNode;
   SEIterator *next = mpNext->mpNext;
   mpNext->mpNext = nullptr;
   delete mpNext; 
   mpNext = next;
   return 0;
}

} // namespace slickedit

