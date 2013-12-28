////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_STRINGTABLE_H
#define SLICKEDIT_STRINGTABLE_H

#include "vsdecl.h"
#include "vsmsgdefs_fio.h"
#include "vsutf8.h"
#include "SEMemory.h"
#include "SEString.h"
#include "SEAllocator.h"
#include "SEIterator.h"
#include "SECharType.h"
#include <new>

namespace slickedit {

//////////////////////////////////////////////////////////////////////////

/**
 * Manage a table of elements of type T, indexed using a string key.
 * Elememts of the array can be indexed via the [] operator, using
 * keys of any string type.
 * <P> 
 * The items are indexed using a string prefix tree.  This gives us
 * guaranteed order(m) insertion, deletion, and lookup time, where (m) is
 * the length of the string key being inserted. 
 * <P>
 * The table can also be searched linearly for a specific item
 * by providing a comparison function for the specific template
 * class type.
 * <P>
 * You can configure the string table to be case-sensitive or case-insensitive.
 * <P>
 * Type T must have a default constructor (ie. constructor with no
 * required arguments), copy constructor, and an assignment operator.
 * <P>
 * For comparisons, the == operators is used.  If this operator
 * are not available, an item compare proc can also be registered.
 *
 * @param T  type of item to store in the table
 */
template <class T>
class SEStringTable : public SEMemory {

public:
   // typedefs for registered hashing and comparison functions
   typedef int  (*CompareProc)(T v1, T v2);
   typedef void (*ForEachProc)(const slickedit::SEString &k, T &v);
   typedef void (*ForEachProcUD)(const slickedit::SEString &k, T &v, void *userData);

   /**
    * Construct a string table. 
    *  
    * @param caseSensitive    (default true) Treat string keys as case-sensitive? 
    * @param utf8encoding     (default false) Treat string keys as utf8? 
    */
   SEStringTable(bool caseSensitive=true, bool utf8encoding=false);

   /**
    * Destructor
    */
   ~SEStringTable();

   /**
    * Copy constructor, does a deep copy
    */
   SEStringTable(const SEStringTable<T>& src);
   /**
    * Assignment operator, does a deep copy
    */
   SEStringTable<T> &operator = (const SEStringTable<T>& src);

   /**
    * Comparison operators
    */
   bool operator == (const SEStringTable<T>& lhs) const;
   bool operator != (const SEStringTable<T>& lhs) const;

   /**
    * Remove and delete all the items from the table
    */
   void clear();

   /**
    * Insert a new item into the table.
    * If key already exists, the item will be replaced
    *
    * @param key    key value to hash on
    * @param item   item to store associated with key
    *
    * @return 0 if successful. Otherwise -1.
    */
   int add(const slickedit::SEString &key, const T &item);
   int add(const VSLSTR *key, const T &item);
   int add(const char *key, const T &item);
   int add(const char *key, size_t len, const T &item);

   /**
    * Delete the given key/value pair from the table.
    *
    * @param key    key value to hash on
    * @param item   item associated with key value
    *
    * @return 0 on success, <0 on error (not found)
    */
   int remove(const slickedit::SEString &key);
   int remove(const VSLSTR *key);
   int remove(const char *key);
   int remove(const char *key, size_t len);

   /**
    * Search for the specified item in the entire table.
    * A linear search of the table is used.
    *
    * @param item   value of item to search table for
    * @param key    (reference) set to key value for item
    *
    * @return 0 on success, <0 on error.
    */
   int search(T &item, slickedit::SEString &key) const;

   /**
    * @return The number of items stored in the table
    */
   size_t length() const;

   /**
    * Set up custom comparison function for comparing items/values
    * (for types that don't have a working == operator).
    */
   void registerValCompareProc(CompareProc proc);

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
   slickedit::SEString* copyKeys() const;

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
   const T* nextItem(SEIterator &iter, slickedit::SEString &key) const;
   T* nextItem(SEIterator &iter, slickedit::SEString &key);
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
   const T* prevItem(SEIterator &iter, slickedit::SEString &key) const;
   T* prevItem(SEIterator &iter, slickedit::SEString &key);
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
   const T* currentItem(const SEIterator &iter, slickedit::SEString &key) const;
   T* currentItem(const SEIterator &iter, slickedit::SEString &key);
   const T* currentItem(const SEIterator &iter) const;
   T* currentItem(const SEIterator &iter);

   /**
    * Get the current iterator key. 
    * If 'iter' is uninitialized, the result is undefined. 
    * 
    * @return Returns the current iterator key
    */
   const slickedit::SEString currentKey(const SEIterator &iter) const;

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
    * given key.
    *
    * @param key    key value to look up
    *
    * @return pointer to item corresponding to key.
    *         Returns 0 if there is no such item in table.
    */
   T* operator[](const slickedit::SEString &key);
   const T* operator[](const slickedit::SEString &key) const;
   T* operator[](const VSLSTR *key);
   const T* operator[](const VSLSTR *key) const;
   T* operator[](const char *key);
   const T* operator[](const char *key) const;

   /**
    * Is the given key in the hash table?
    *
    * @param key    key value to look up
    *
    * @return 1 if it is in the table, 0 otherwise.
    */
   bool isKey(const slickedit::SEString &key) const;
   bool isKey(const VSLSTR *key) const;
   bool isKey(const char *key) const;
   bool isKey(const char *key, size_t len) const;

   /**
    * Is this set empty?
    */
   bool isEmpty() const;

   /**
    * Is this set *not* empty?
    */
   bool isNotEmpty() const;


private:

   struct SEPrefixTree {
      unsigned char mPrefixChars[22];  // prefix characters
      unsigned char mPrefixLength;     // 0..sizeof(mPrefixChars)
      unsigned char mNumChildren;      // up to 256 items, sorted                                   
      T* mpData;                       // optional pointer to data

      // The follow two arrays are appeneded to the end of the struct.
      /*
      SEPrefixTree*  mChildren[mNumChildren];
      unsigned char* mPivotChars[mNumChildren];
      */

      // array of children (appended to end of struct)
      SEPrefixTree** getChildren() const {   
         return (SEPrefixTree**) (((char*)this) + sizeof(SEPrefixTree));
      }
      // array of children (appended to end of struct)
      SEPrefixTree* getChild(size_t i) const {
         SEPrefixTree **children = (SEPrefixTree**) (((char*)this) + sizeof(SEPrefixTree));     
         return children[i];
      }
      // array of pivot chars for each child, sorted
      unsigned char* getPivotChars() const { 
         return (unsigned char*) (((char*)this) + sizeof(SEPrefixTree) + sizeof(SEPrefixTree*)*mNumChildren);
      }
      // number of bytes to allocate for this tree with 'n' children
      static size_t getMinAllocSize(size_t n) {
         return sizeof(SEPrefixTree) + n*sizeof(SEPrefixTree*) + n*sizeof(unsigned char);
      }
   };

   SEPrefixTree *mPrefixRoot;          // prefix tree structure for fast string lookups 
   CompareProc pfnCompare;             // Compare proc for values
   int mNumItems;                      // Number of items in hash table
   bool mCaseSensitive;
   bool mUTF8Encoding;
   mutable SEString mUpcaseKey;

   // Returns 1 if v1==v2, 0 otherwise.
   int isEqual(T &v1, T &v2) const;

   // insert an item into the given subtree
   int insertItem(SEPrefixTree *t, const char *key, size_t len, const T &v);

   // remove an item from the given subtree
   int removeItem(SEPrefixTree *t, const char *key, size_t len);

   // search for an item matching the given key in the given subtree
   SEPrefixTree *searchItem(const SEPrefixTree *t, const char *key, size_t len) const;

   // search for a matching item in the given subtree
   SEPrefixTree *searchTree(const SEPrefixTree *t, T& item, slickedit::SEString &key) const;

   // copy all the keys under the given stubtree into the given array of strings
   slickedit::SEString* copyKeys(const SEPrefixTree *t, 
                                 slickedit::SEString prefix, 
                                 slickedit::SEString *list, size_t &len) const;

   // copy pointers all the items under the given subtree into the given array
   void copyItemPointers(const SEPrefixTree *t, T **list, size_t &len) const;

   // copy all the items under the given subtree into the given array
   void copyItems(const SEPrefixTree *t, T *list, size_t &len) const;

   // perform an operation for each item in the given subtree
   void forEach(SEPrefixTree *t, slickedit::SEString prefix, ForEachProcUD proc, void* userData) const;
   void forEach(SEPrefixTree *t, slickedit::SEString prefix, ForEachProc proc) const;

   // internal implmeentions of next/prev/current iterator functions
   T* nextItemInternal(SEIterator &iter) const;
   T* prevItemInternal(SEIterator &iter) const;
   T* currentItemInternal(const SEIterator &iter, slickedit::SEString &key) const;

   // find the child node corresponding to the given pivot character
   int findPrefixTree(const SEPrefixTree *t, unsigned char ch) const;

   // add a child node with the given pivot character to the tree
   SEPrefixTree **addPrefixTree(SEPrefixTree *&t, unsigned char ch, SEPrefixTree *subTree);

   // delete the given subtree, recursively
   static void deleteTree(SEPrefixTree *t);

   // copy the contents of the given subtree into the given destination
   static int copyTree(SEPrefixTree *dest, const SEPrefixTree *src);

   // compare two trees
   bool compareTrees(const SEPrefixTree *t1, const SEPrefixTree *t2) const;

};


//////////////////////////////////////////////////////////////////////////

template <class T>
inline size_t
SEStringTable<T>::length() const
{
   return mNumItems;
}

template <class T>
inline bool
SEStringTable<T>::isNotEmpty() const
{
   return mNumItems > 0;
}

template <class T>
inline bool
SEStringTable<T>::isEmpty() const
{
   return mNumItems == 0;
}

template <class T>
inline void
SEStringTable<T>::registerValCompareProc(CompareProc proc)
{
   pfnCompare = proc;
}

template <class T>
inline int
SEStringTable<T>::findPrefixTree(const SEPrefixTree *t, unsigned char ch) const
{
   // no items at all?
   int numItems = t->mNumChildren;
   if (numItems == 0) {
      return STRING_NOT_FOUND_RC;
   }

   // use a linear search for small arrays for the best speed
   if (numItems < 8) {
      const unsigned char *pivotChars = t->getPivotChars();
      int i=0;
      while (i < numItems) {
         if (*pivotChars == ch) {
            return i;
         }
         pivotChars++;
         i++;
      }

   } else {
      // Search for the specified item in the array.
      // A binary search is used.
      const unsigned char *pivotChars = t->getPivotChars();
      int first = 0, last = numItems-1;
      while ( first <= last ) {
         int middle = ( first + last ) >> 1;
         unsigned char midCh = pivotChars[middle];
         if ( midCh == ch ) {
            return middle;
         } else if ( midCh > ch ) {
            last = middle - 1;
         } else {
            first = middle + 1;
         }
      }
   }

   // did not find the item
   return STRING_NOT_FOUND_RC;
}

template <class T> 
inline typename SEStringTable<T>::SEPrefixTree **
SEStringTable<T>::addPrefixTree(SEPrefixTree *&t,
                                unsigned char ch, 
                                SEPrefixTree *subTree)
{
   // check if we already have enough space allocated for the new subtree
   int numItems = t->mNumChildren;
   size_t minAllocSize = SEPrefixTree::getMinAllocSize(numItems+1);
   if (SEAllocationSize(t) < minAllocSize) {
      if (numItems > 1) {
         // also make room for the next four
         minAllocSize += 3*(sizeof(SEPrefixTree*) + sizeof(unsigned char*));
      }
      t = (SEPrefixTree*) SEReallocate(t, minAllocSize);
   }

   // if there are no sub-trees, then just insert this one immediately
   if (numItems == 0) {
      t->mNumChildren = 1;
      SEPrefixTree **children = t->getChildren();
      children[0] = subTree;
      unsigned char *pivotChars = t->getPivotChars();
      pivotChars[0] = ch;
      return &children[0];
   }

   // slide over the first characters to make room for another pointer
   const unsigned char *origPivotChars = t->getPivotChars();
   t->mNumChildren++;
   unsigned char *pivotChars = t->getPivotChars();
   memmove(pivotChars, origPivotChars, numItems);

   // Search for the correct place to insert item and shift other items
   // get a pointer to the array of items for speed
   SEPrefixTree** children = t->getChildren();
   for (int i = numItems-1; i>=0; --i) {
      if (pivotChars[i] < ch) {
         children[i+1] = subTree;
         pivotChars[i+1] = ch;
         return &children[i+1];
      }
      children[i+1] = children[i];
      pivotChars[i+1] = pivotChars[i];
   }

   // did not find a slot, insert at start of array
   children[0] = subTree;
   pivotChars[0] = ch;
   return &children[0];
}

template <class T> 
inline int
SEStringTable<T>::insertItem(SEPrefixTree *t, const char *key, size_t len, const T &v)
{
   // make sure the key is not NULL
   if (key == NULL) {
      return INVALID_ARGUMENT_RC;
   }

   // convert the key to UTF8, upcase, if necessary
   size_t pos=0;
   if (mCaseSensitive) {
      // do nothing
   } else if (mUTF8Encoding) {
      mUpcaseKey.set(key, len);
      vsUTF8Upcase(mUpcaseKey.getMutableCString(), len);
      key = mUpcaseKey.getCString();
   } else {
      mUpcaseKey.set(key, len);
      mUpcaseKey.upcase();
      key = mUpcaseKey.getCString();
   }

   // starting with an empty tree?
   // then we should allocate a root node at least
   SEPrefixTree **parentTree = &mPrefixRoot;
   if (mPrefixRoot == NULL) {
      mNumItems = 0;
      size_t minAllocSize = SEPrefixTree::getMinAllocSize(8);
      mPrefixRoot = (SEPrefixTree*) SEAllocate(minAllocSize);
      if (mPrefixRoot == NULL) {
         return INSUFFICIENT_MEMORY_RC;
      }
      memset(mPrefixRoot, 0, sizeof(SEPrefixTree));
   }

   // if there are no items, we can copy the start of the key into the first node
   if (mNumItems == 0) {
      t = mPrefixRoot;
      size_t prefixLength = len-pos;
      if (prefixLength > sizeof(t->mPrefixChars)) prefixLength = sizeof(t->mPrefixChars);
      t->mPrefixLength = (unsigned char)prefixLength;
      if (prefixLength > 0) {
         memcpy(t->mPrefixChars, &key[pos], prefixLength);
      }
      if (len-pos == prefixLength) {
         t->mpData = new T(v);
         if (!t->mpData) return INSUFFICIENT_MEMORY_RC;
         return 1;
      }
   }

   for (;;) {

      // we are going to match characters up to the prefix length 
      // or the key len, whichever is shorter
      size_t i=0, n=t->mPrefixLength;
      if (len-pos < n) {
         n = len-pos;
      }

      // match the prefix string characters, if there are any
      if (n > 0) {
         const unsigned char *p = &t->mPrefixChars[0];
         while (i<n && p[i] == (unsigned char)key[pos+i]) {
            i++;
         }
      }

      // the prefix did not match completely, so we need to split the node
      if (i < t->mPrefixLength) {

         // did the prefix match the entire key?  Then we only split one way.
         if (i == len-pos) {

            // first, construct the new child node for the key we are inserting.
            size_t minAllocSize = SEPrefixTree::getMinAllocSize(1);
            SEPrefixTree *newParentNode = (SEPrefixTree*) SEAllocate(minAllocSize);
            if (!newParentNode) return INSUFFICIENT_MEMORY_RC;
            memset(newParentNode, 0, sizeof(SEPrefixTree));
            newParentNode->mpData = new T(v);
            if (!newParentNode->mpData) return INSUFFICIENT_MEMORY_RC;
            if (i > 0) {
               memcpy(newParentNode->mPrefixChars, t->mPrefixChars, i);
               newParentNode->mPrefixLength = (unsigned char)i;
            }

            // insert the old node under this node
            newParentNode->mNumChildren = 1;
            SEPrefixTree **children = newParentNode->getChildren();
            unsigned char *pivotChars = newParentNode->getPivotChars();
            children[0] = t;
            pivotChars[0] = t->mPrefixChars[i];
            if (parentTree) *parentTree = newParentNode;

            // now adjust the prefix characters in the original tree node
            t->mPrefixLength -= (unsigned char)(i+1);
            size_t prefixLength = t->mPrefixLength;
            if (prefixLength > 0) {
               memmove(t->mPrefixChars, &t->mPrefixChars[i+1], prefixLength);
            }
            t->mPrefixChars[prefixLength] = '\0';

            // we might be able to join the prefix characters from the child
            // node into the old node because we have free'd up some prefix chars
            // this is only possible if there is exactly one child
            if (t->mNumChildren == 1 && t->mpData==NULL) {
               SEPrefixTree *grandChild = t->getChildren()[0]; 
               if (t->mPrefixLength + grandChild->mPrefixLength+1 <= sizeof(t->mPrefixChars)) {
                  if (grandChild->mPrefixLength > 0) {
                     memmove(&grandChild->mPrefixChars[t->mPrefixLength+1], grandChild->mPrefixChars, grandChild->mPrefixLength);
                  }
                  unsigned char *pivotChars = t->getPivotChars();
                  grandChild->mPrefixChars[t->mPrefixLength] = pivotChars[0];
                  if (t->mPrefixLength > 0) {
                     memcpy(grandChild->mPrefixChars, &t->mPrefixChars, t->mPrefixLength);
                  }
                  grandChild->mPrefixLength = t->mPrefixLength + 1 + grandChild->mPrefixLength;
                  SEDeallocate(t);
                  t = children[0] = grandChild;
               }
            }
   
            // that's all, we have inserted the new pivot node
            return 1;
         } 
 
		 // get the prefix characters which will be inserted with the child nodes
         unsigned char oldChildPivotCh = t->mPrefixChars[i];
         unsigned char newChildPivotCh = (unsigned char)key[pos+i];
 
         // in this case, we have to split two ways
         // first, construct the new child node for the key we are inserting.
         bool isLeaf = (len-pos < sizeof(t->mPrefixChars));
         size_t minAllocSize = SEPrefixTree::getMinAllocSize(!isLeaf);
         SEPrefixTree *newChildNode = (SEPrefixTree*) SEAllocate(minAllocSize);
         //SEPrefixTree *newChildNode = SEAllocateType<SEPrefixTree>();
         if (!newChildNode) return INSUFFICIENT_MEMORY_RC;
         memset(newChildNode, 0, sizeof(SEPrefixTree));
         size_t prefixLength = len-pos-i-1;
         if (prefixLength > 0) {
            if (prefixLength > sizeof(newChildNode->mPrefixChars)) {
               prefixLength = sizeof(newChildNode->mPrefixChars);
            }
            newChildNode->mPrefixLength = (unsigned char)prefixLength;
            memcpy(newChildNode->mPrefixChars, &key[pos+i+1], prefixLength);
         }

         // second, construct the new parent node, which will replace
         // the node we are splitting and have two children
         minAllocSize = SEPrefixTree::getMinAllocSize(2);
         SEPrefixTree *newParentNode = (SEPrefixTree*) SEAllocate(minAllocSize);
         if (!newParentNode) return INSUFFICIENT_MEMORY_RC;
         memset(newParentNode, 0, sizeof(SEPrefixTree));
         newParentNode->mNumChildren = 2;
         if (i > 0) {
            newParentNode->mPrefixLength = (unsigned char)i;
            memcpy(newParentNode->mPrefixChars, t->mPrefixChars, i);
         }
         if (parentTree) *parentTree = newParentNode;

         // third, adjust the prefix characters in the original tree node
         SEPrefixTree *oldChildNode = t;
         size_t oldPrefixLength = oldChildNode->mPrefixLength-i-1;
         oldChildNode->mPrefixLength = (unsigned char)oldPrefixLength;
         if (oldPrefixLength > 0) {
            memmove(oldChildNode->mPrefixChars, &oldChildNode->mPrefixChars[i+1], oldPrefixLength);
            oldChildNode->mPrefixChars[oldPrefixLength] = '\0';
         }

         // we might be able to join the prefix characters from the child
         // node into the old node because we have free'd up some prefix chars
         // this is only possible if there is exactly one child
         if (oldChildNode->mNumChildren == 1 && oldChildNode->mpData==NULL) {
            SEPrefixTree *grandChild = oldChildNode->getChildren()[0];
            if (oldChildNode->mPrefixLength + grandChild->mPrefixLength+1 <= sizeof(oldChildNode->mPrefixChars)) {
               if (grandChild->mPrefixLength > 0) {
                  memmove(&grandChild->mPrefixChars[oldChildNode->mPrefixLength+1], grandChild->mPrefixChars, grandChild->mPrefixLength);
               }
               unsigned char *pivotChars = oldChildNode->getPivotChars();
               grandChild->mPrefixChars[oldChildNode->mPrefixLength] = pivotChars[0];
               if (oldChildNode->mPrefixLength > 0) {
                  memcpy(grandChild->mPrefixChars, &oldChildNode->mPrefixChars, oldChildNode->mPrefixLength);
               }
               grandChild->mPrefixLength = (unsigned char)oldChildNode->mPrefixLength + 1 + grandChild->mPrefixLength;
               SEDeallocate(oldChildNode);
               oldChildNode = grandChild;
            }
         }

         // insert the two children in order
         SEPrefixTree **children = newParentNode->getChildren();
         unsigned char *pivotChars = newParentNode->getPivotChars();
         if (oldChildPivotCh < newChildPivotCh) {
            children[0] = oldChildNode; pivotChars[0] = oldChildPivotCh;
            children[1] = newChildNode; pivotChars[1] = newChildPivotCh;
            parentTree = &children[1];
         } else {
            children[0] = newChildNode; pivotChars[0] = newChildPivotCh;
            children[1] = oldChildNode; pivotChars[1] = oldChildPivotCh;
            parentTree = &children[0];
         }

         // collapse the tail recursion by adjusting parameters and looping
         pos += i+prefixLength+1;
         t = newChildNode;

         // check if we have inserted the entire tree at this point
         if (len-pos == 0) {
            t->mpData = new T(v);
            if (!t->mpData) return INSUFFICIENT_MEMORY_RC;
            return 1;
         }

         // there is more to the key to chain together
         break;
      }

      // if we found the string, then insert it in this node
      if (i == len-pos && i == t->mPrefixLength) {
         if (t->mpData) {
            *t->mpData = v;
            return 0;
         }
         t->mpData = new T(v);
         if (!t->mpData) return INSUFFICIENT_MEMORY_RC;
         return 1;
      }

      // adjust the remaining amount of the key and len
      pos += i;
      
      // get the pivot character
      unsigned char uch = (unsigned char)key[pos];

      // get the next character and find the subtree to use
      int index = findPrefixTree(t, uch);
      if (index >= 0) {
         // collapse the tail recursion by adjusting parameters and looping
         pos++;
         SEPrefixTree **children = t->getChildren();
         parentTree = &children[index];
         t = children[index];
         continue;
      }
   
      // drop out of the tree search loop and create the new tree structure
      break;
   }

   // now loop creating other trees
   size_t prefixLength = sizeof(t->mPrefixChars);
   while (len-pos > prefixLength) {

      // now create a new sub-tree   
      size_t minAllocSize = SEPrefixTree::getMinAllocSize(1);
      SEPrefixTree *newTree = (SEPrefixTree*) SEAllocate(minAllocSize);
      if (!newTree) return INSUFFICIENT_MEMORY_RC;
      memset(newTree, 0, sizeof(SEPrefixTree));

      // get the pivot character
      unsigned char uch = (unsigned char)key[pos];

      // copy in as many characters as possible
      newTree->mPrefixLength = (unsigned char)prefixLength;
      memcpy(newTree->mPrefixChars, &key[pos+1], prefixLength);

      // add add it to the tree
      SEPrefixTree **newParentTree = addPrefixTree(t, uch, newTree);
      if (parentTree) *parentTree = t;
      parentTree = newParentTree;
      pos += (prefixLength+1);
      t = newTree;

      if (len-pos == 0) {
         newTree->mpData = new T(v);
         if (!newTree->mpData) return INSUFFICIENT_MEMORY_RC;
         return 1;
      }
   }

   // now create a new sub-tree   
   SEPrefixTree *newTree = SEAllocateType<SEPrefixTree>();
   if (!newTree) return INSUFFICIENT_MEMORY_RC;
   memset(newTree, 0, sizeof(SEPrefixTree));

   // get the pivot character
   unsigned char uch = (unsigned char)key[pos];

   // copy in as many characters as possible
   prefixLength = len-pos-1;
   if (prefixLength > 0) {
      newTree->mPrefixLength = (unsigned char)prefixLength;
      memcpy(newTree->mPrefixChars, &key[pos+1], prefixLength);
   }

   // add add it to the tree
   addPrefixTree(t, uch, newTree);
   if (parentTree) *parentTree = t;
   newTree->mpData = new T(v);
   if (!newTree->mpData) return INSUFFICIENT_MEMORY_RC;
   return 1;

}

template <class T> 
inline int
SEStringTable<T>::removeItem(SEPrefixTree *t, const char *key, size_t len)
{
   // test for null tree
   if (t == NULL) {
      return STRING_NOT_FOUND_RC;
   }

   // make sure the key is not NULL
   if (key == NULL) {
      return INVALID_ARGUMENT_RC;
   }

   // convert the key to UTF8, upcase, if necessary
   if (mCaseSensitive) {
      // do nothing
   } else if (mUTF8Encoding) {
      mUpcaseKey.set(key, len);
      vsUTF8Upcase(mUpcaseKey.getMutableCString(), len);
      key = mUpcaseKey.getCString();
   } else {
      mUpcaseKey.set(key, len);
      mUpcaseKey.upcase();
      key = mUpcaseKey.getCString();
   }

   // if the key is longer than the prefix string, it can't be a match
   size_t i=0, n=t->mPrefixLength;
   if (len < n) {
      return STRING_NOT_FOUND_RC;
   }

   // match the prefix string characters
   // return with error if anything mismatches
   if (n > 0) {
      const unsigned char *p = &t->mPrefixChars[0];
      if (mCaseSensitive || mUTF8Encoding) {
         while (i<n) {
            if (p[i] != (unsigned char)key[i]) {
               return STRING_NOT_FOUND_RC;
            }
            i++;
         }
      } else {
         while (i < n) {
            if (p[i] != SECharToUpper((unsigned char)key[i])) {
               return STRING_NOT_FOUND_RC;
            }
            i++;
         }
      }
   }

   // have we found the string?
   if (i == len) {
      if (t->mpData) {
         delete t->mpData;
         t->mpData = NULL;
         return 1;
      }
      return STRING_NOT_FOUND_RC; 
   }

   // get the pivot character
   unsigned char uch = key[i++];
   if (!mCaseSensitive && !mUTF8Encoding) {
      uch = SECharToUpper(uch);
   }

   // get the next character and find the subtree to use
   int index = findPrefixTree(t, uch);
   if (index < 0) {
      return STRING_NOT_FOUND_RC;
   }

   // recursively remove the key from the subtree
   SEPrefixTree *subTree = t->getChild(index);
   int removeStatus = removeItem(subTree, &key[i], len-i);
   if (removeStatus < 0) {
      return removeStatus;
   }

   // if the subtree still has child nodes or data, then we are done
   if (subTree->mNumChildren > 0 || subTree->mpData != NULL) {
      return removeStatus;
   }

   // sub tree has no children nor data, so remove it
   deleteTree(subTree);

   // now adjust the tree structure.
   // Remove all the leaf nodes if there are no more
   unsigned char *origPivotChars = t->getPivotChars();
   t->mNumChildren--;
   if (t->mNumChildren == 0) {
      return removeStatus;
   }

   // remove the pointer to the (now gone) sub tree
   SEPrefixTree **children = t->getChildren();
   while (index < (int)t->mNumChildren) {
      children[index] = children[index+1];
      origPivotChars[index] = origPivotChars[index+1];
      index++;
   }
   unsigned char *pivotChars = t->getPivotChars();
   memmove(pivotChars, origPivotChars, t->mNumChildren);

   // finally, return the status sent from the recursive remove
   return removeStatus;
}

template <class T> 
inline typename SEStringTable<T>::SEPrefixTree *
SEStringTable<T>::searchItem(const SEPrefixTree *t, const char *key, size_t len) const
{
   if (t == NULL || key==NULL) {
      return NULL;
   }

   // convert the key to UTF8, upcase, if necessary
   size_t pos=0;
   if (mCaseSensitive) {
      // do nothing
   } else if (mUTF8Encoding) {
      mUpcaseKey.set(key, len);
      vsUTF8Upcase(mUpcaseKey.getMutableCString(), len);
      key = mUpcaseKey.getCString();
   } else {
      mUpcaseKey.set(key, len);
      mUpcaseKey.upcase();
      key = mUpcaseKey.getCString();
   }

   for (;;) {

      // if the key is longer than the prefix string, it can't be a match
      size_t i=0, n=t->mPrefixLength;
      if (len < pos+n) {
         return NULL;
      }

      // match the prefix string characters, if there are any
      // return with error if anything mismatches
      const unsigned char *p = &t->mPrefixChars[0];
      while (i < n) {
         if (p[i] != (unsigned char)key[pos+i]) {
            return NULL;
         }
         i++;
      }

      // have we found the string, and does this node have leaf data?
      if (pos+i == len) {
         return (t->mpData != NULL)? (SEPrefixTree*) t : NULL;
      }

      // get the pivot character
      unsigned char uch = (unsigned char)key[pos+i];

      // get the next character and find the subtree to use
      int index = findPrefixTree(t, uch);
      if (index < 0) {
         return NULL;
      }
   
      // collapse the tail recursion by adjusting parameters and looping
      pos += (i+1);
      t = t->getChild(index);
      continue;
   }
}

template <class T> inline
SEStringTable<T>::SEStringTable(bool caseSensitive/*=true*/, bool utf8encoding/*=false*/) :
   // initial function pointers
   pfnCompare(0),
   mNumItems(0),
   mPrefixRoot(NULL),
   mCaseSensitive(caseSensitive),
   mUTF8Encoding(utf8encoding)
{
}
template <class T> inline
SEStringTable<T>::SEStringTable(const SEStringTable<T>& src) :
   // initial function pointers
   pfnCompare(src.pfnCompare),
   mNumItems(src.mNumItems),
   mPrefixRoot(NULL),
   mCaseSensitive(src.mCaseSensitive),
   mUTF8Encoding(src.mUTF8Encoding)
{
   if (src.mPrefixRoot != NULL) {
      size_t minAllocSize = SEPrefixTree::getMinAllocSize(src.mPrefixRoot->mNumChildren);
      SEPrefixTree *newTree = (SEPrefixTree*) SEAllocate(minAllocSize);
      if (newTree) {
         memset(newTree, 0, sizeof(SEPrefixTree));
         copyTree(newTree, src.mPrefixRoot);
         mPrefixRoot = newTree;
      }
   }
}

template <class T> inline
SEStringTable<T>& SEStringTable<T>::operator=(const SEStringTable<T>& src)
{
   if (this != &src) {
      pfnCompare = src.pfnCompare;
      mNumItems = src.mNumItems;
      mCaseSensitive = src.mCaseSensitive;
      mUTF8Encoding = src.mUTF8Encoding;

      // out with the old subtree
      if (mPrefixRoot) {
         deleteTree(mPrefixRoot);
         mPrefixRoot = NULL;
      }

      // copy in the new tree
      if (src.mPrefixRoot != NULL) {
         size_t minAllocSize = SEPrefixTree::getMinAllocSize(src.mPrefixRoot->mNumChildren);
         SEPrefixTree *newTree = (SEPrefixTree*) SEAllocate(minAllocSize);
         if (newTree) {
            memset(newTree, 0, sizeof(SEPrefixTree));
            copyTree(newTree, src.mPrefixRoot);
            mPrefixRoot = newTree;
         }
      }
   }
   return *this;
}

template <class T> void
SEStringTable<T>::deleteTree(SEPrefixTree *t)
{
   if (t->mpData != NULL) {
      delete t->mpData;
      t->mpData = NULL;
   }

   SEPrefixTree **children = t->getChildren();
   size_t i=0, n=t->mNumChildren;
   while (i<n) {
      deleteTree(children[i]);
      i++;
   }

   SEDeallocate(t);
}

template <class T> inline int
SEStringTable<T>::copyTree(SEPrefixTree *dest, const SEPrefixTree *src)
{
   if (src == dest) {
      return 0;
   }

   dest->mPrefixLength = src->mPrefixLength;
   memcpy(dest->mPrefixChars, src->mPrefixChars, sizeof(dest->mPrefixChars));

   if (dest->mpData != NULL) {
      if (src->mpData != NULL) {
         *dest->mpData = *src->mpData;
      } else {
         delete dest->mpData;
         dest->mpData = NULL;
      }
   } else if (src->mpData != NULL) {
      dest->mpData = new T(*src->mpData);
      if (dest->mpData == NULL) {
         return INSUFFICIENT_MEMORY_RC;
      }
   }

   SEPrefixTree **destChildren = dest->getChildren();
   size_t i=0, n=dest->mNumChildren;
   while (i<n) {
      deleteTree(destChildren[i]);
      destChildren[i] = NULL;
      i++;
   }

   n = src->mNumChildren;
   dest->mNumChildren = (unsigned char)n;
   if (n > 0) {
      unsigned char *destPivotChars = dest->getPivotChars();
      const unsigned char *srcPivotChars = src->getPivotChars();
      SEPrefixTree **srcChildren =  src->getChildren();
      for (i=0; i<n; i++) {
         destPivotChars[i] = srcPivotChars[i];
         size_t minAllocSize = SEPrefixTree::getMinAllocSize(srcChildren[i]->mNumChildren);
         destChildren[i] = (SEPrefixTree*) SEAllocate(minAllocSize);
         if (destChildren[i] == NULL) {
            return INSUFFICIENT_MEMORY_RC;
         }
         memset(destChildren[i], 0, sizeof(SEPrefixTree));
         if (copyTree(destChildren[i], srcChildren[i])) {
            return INSUFFICIENT_MEMORY_RC;
         }
      }
   }

   return 0;
}

template <class T> inline
SEStringTable<T>::~SEStringTable()
{
   // make sure the item count is reset to zero
   mNumItems = 0;

   // clean up the tree structure
   if ( mPrefixRoot != NULL) {
      deleteTree(mPrefixRoot);
      mPrefixRoot = NULL;
   }
}


template <class T> inline
slickedit::SEString* SEStringTable<T>::copyKeys(const SEPrefixTree *t, 
                                                              slickedit::SEString prefix, 
                                                              slickedit::SEString *list,
                                                              size_t &len) const
{
   // append this portion of the string prefix
   prefix.append((const char*)t->mPrefixChars, t->mPrefixLength);

   // if this is a leaf node, copy it in
   if (t->mpData != NULL) {
      list[len++] = prefix;
   }

   // now check all of our children nodes
   const unsigned char *pivotChars = t->getPivotChars();
   SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      prefix.append(pivotChars[i]);
      copyKeys(children[i], prefix, list, len);
      prefix.trim(1);
   }

   // that's all, return result
   return list;
}
template <class T> inline
slickedit::SEString* SEStringTable<T>::copyKeys() const
{
   // allocate an array of items of type 'T'
   if ( mNumItems==0 ) return NULL;
   slickedit::SEString *list = new slickedit::SEString[mNumItems];
   if (!list) return (0);

   // copy in the items from the list
   size_t len=0;
   slickedit::SEString prefix;
   if (mPrefixRoot) {
      copyKeys(mPrefixRoot, prefix, list, len);
   }

   // that's all, return result
   return list;
}

template <class T> inline
void SEStringTable<T>::copyItems(const SEPrefixTree *t, 
                                 T *list, size_t &len) const
{
   // if this is a leaf node, copy it in
   if (t->mpData != NULL) {
      list[len++] = *t->mpData;
   }

   // now check all of our children nodes
   SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      copyItems(children[i], list, len);
   }
}
template <class T> inline
T* SEStringTable<T>::copyItems() const
{
   // allocate an array of items of type 'T'
   if ( mNumItems==0 ) return NULL;
   T *list = new T[mNumItems];
   if (!list) return (0);

   // copy in the items from the list
   size_t len=0;
   if (mPrefixRoot) {
      copyItems(mPrefixRoot, list, len);
   }

   // that's all, return result
   return list;
}

template <class T> inline
void SEStringTable<T>::copyItemPointers(const SEPrefixTree *t, 
                                        T **list, size_t &len) const
{
   // if this is a leaf node, copy it in
   if (t->mpData != NULL) {
      list[len++] = t->mpData;
   }

   // now check all of our children nodes
   SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      copyItemPointers(children[i], list, len);
   }
}
template <class T> inline
T** SEStringTable<T>::copyItemPointers() const
{
   // allocate an array of items of type 'T'
   if ( mNumItems==0 ) return NULL;
   T **list = new T*[mNumItems];
   if (!list) return (0);

   // copy in the items from the list
   size_t len=0;
   if (mPrefixRoot) {
      copyItemPointers(mPrefixRoot, list, len);
   }

   // that's all, return result
   return list;
}


template <class T> inline
void SEStringTable<T>::forEach(SEPrefixTree *t, 
                                             slickedit::SEString prefix, 
                                             ForEachProcUD proc, void* userData) const
{
   prefix.append(t->mPrefixChars, t->mPrefixLength);
   if (t->mpData != NULL) {
      if (proc) {
         (*proc)(prefix, *t->mpData, userData);
      }
   }
   const SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      forEach(children[i], prefix, proc, userData);
   }
}

template <class T> inline
void SEStringTable<T>::forEach(ForEachProcUD proc, void* userData) const
{
   if (mPrefixRoot) {
      slickedit::SEString prefix;
      forEach(mPrefixRoot, prefix, proc, userData);
   }
}

template <class T> inline
void SEStringTable<T>::forEach(SEPrefixTree *t, 
                               slickedit::SEString prefix, 
                               ForEachProc proc) const
{
   prefix.append(t->mPrefixChars, t->mPrefixLength);
   if (t->mpData != NULL) {
      if (proc) {
         (*proc)(prefix, *t->mpData);
      }
   }
   const unsigned char *pivotChars = t->getPivotChars();
   const SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      prefix.append(pivotChars[i]);
      forEach(children[i], prefix, proc);
      prefix.trim(1);
   }
}

template <class T> inline
void SEStringTable<T>::forEach(ForEachProc proc) const
{
   if (mPrefixRoot) {
      slickedit::SEString prefix;
      forEach(mPrefixRoot, prefix, proc);
   }
}

template <class T> inline
T* SEStringTable<T>::currentItemInternal(const SEIterator &iter, slickedit::SEString &key) const
{
   // make sure that the iterator is initialized correctly
   // return a NULL key if the iterator is not initialized
   if (iter.mFindFirst || iter.mpNode == NULL) {
      key.makeNull();
      return NULL;
   }

   // now construct the key value
   // first, measure the length of the key string 
   size_t keyLength = 0;
   const SEPrefixTree *t = (const SEPrefixTree*) iter.mpNode;
   const SEIterator *next = &iter;
   while (t != NULL) {
      keyLength += t->mPrefixLength;
      next = next->mpNext;
      if (next == NULL) break;
      t = (const SEPrefixTree*) next->mpNode;
      keyLength++;
   }

   // now we set the length of the entire key
   key.setCapacity(keyLength+1);
   key.setLength(keyLength);

   // now work backwards filling in the key string
   t = (const SEPrefixTree*) iter.mpNode;
   next = &iter;
   while (t != NULL) {
      // first get the prefix charactors
      if (t->mPrefixLength > 0) {
         keyLength -= t->mPrefixLength;
         key.replace((unsigned int)keyLength, t->mPrefixLength, (const char*)t->mPrefixChars, t->mPrefixLength);
      }
      // then skip to the next item in the stack
      next = next->mpNext;
      if (next == NULL) break;
      t = (const SEPrefixTree*) next->mpNode;
      // then plug in the pivot character
      const unsigned char *pivotChars = t->getPivotChars();
      key[--keyLength] = pivotChars[next->mIndex];
   }

   // finally, return a pointer to the data item
   t = (const SEPrefixTree*) iter.mpNode;
   return t->mpData;
}

template <class T> inline
T* SEStringTable<T>::nextItemInternal(SEIterator &iter) const
{
   if (!mPrefixRoot) {
      return NULL;
   }
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      iter.mpNode = mPrefixRoot;
      iter.mIndex = 0;
      if (mPrefixRoot->mpData != NULL) {
         return mPrefixRoot->mpData;
      }
   }

   for (;;) {
      SEPrefixTree *t = (SEPrefixTree*) iter.mpNode;
      if (t == NULL) break;
      if (iter.mIndex < t->mNumChildren) {
         size_t origIndex = iter.mIndex;
         iter.pushStack();
         iter.mpNode = t = t->getChild(origIndex);
         iter.mIndex = 0;
         if (t->mpData != NULL) {
            return t->mpData;
         }
      } else {
         if (iter.popStack() < 0) break;
         iter.mIndex++;
      }
   }

   iter.mpNode = NULL;
   return NULL;
}
template <class T> inline
const T* SEStringTable<T>::nextItem(SEIterator &iter, slickedit::SEString &key) const
{
   const T* pItem = nextItemInternal(iter);
   if (pItem==NULL) return NULL;
   return currentItemInternal(iter, key);
}
template <class T> inline
T* SEStringTable<T>::nextItem(SEIterator &iter, slickedit::SEString &key)
{
   T* pItem = nextItemInternal(iter);
   if (pItem==NULL) return NULL;
   return currentItemInternal(iter, key);
}
template <class T> inline
const T* SEStringTable<T>::nextItem(SEIterator &iter) const
{
   return nextItemInternal(iter);
}
template <class T> inline
T* SEStringTable<T>::nextItem(SEIterator &iter)
{
   return nextItemInternal(iter);
}

template <class T> inline
T* SEStringTable<T>::prevItemInternal(SEIterator &iter) const
{
   if (!mPrefixRoot) {
      return NULL;
   }
   if (iter.mFindFirst) {
      iter.mFindFirst = false;
      iter.mIndex = 0;
      iter.mpNode = mPrefixRoot;
      SEPrefixTree *t = mPrefixRoot;
      while (t != NULL) {
         if (t->mNumChildren <= 0) break;
         iter.mIndex = t->mNumChildren-1;
         t = t->getChild(iter.mIndex);
         iter.pushStack();
         iter.mpNode = t;
         iter.mIndex = 0;
      }
      if (t != NULL && t->mpData != NULL) {
         return t->mpData;
      }
   }

   for (;;) {
      SEPrefixTree *t = (SEPrefixTree*) iter.mpNode;
      if (t == NULL) break;

      if (iter.popStack() < 0) break;
      if (iter.mIndex <= 0) {
         t = (SEPrefixTree*) iter.mpNode;
         if (t != NULL && t->mpData != NULL) {
            return t->mpData;
         }
      }
      while (iter.mIndex > 0) {
         iter.mIndex--;
         t = (SEPrefixTree*) iter.mpNode;
         if (t==NULL) break;
         t = t->getChild(iter.mIndex);
         iter.pushStack();
         iter.mpNode = t;
         while (t != NULL) {
            if (t->mNumChildren <= 0) break;
            iter.mIndex = t->mNumChildren-1;
            t = t->getChild(iter.mIndex);
            iter.pushStack();
            iter.mpNode = t;
         }
         if (t != NULL && t->mpData != NULL) {
            return t->mpData;
         }
         t = (SEPrefixTree*) iter.mpNode;
         if (t==NULL) break;
         iter.popStack();
         if (iter.mIndex <= 0) {
            t = (SEPrefixTree*) iter.mpNode;
            if (t != NULL && t->mpData != NULL) {
               return t->mpData;
            }
         }
      }
   }

   return NULL;
}
template <class T> inline
const T* SEStringTable<T>::prevItem(SEIterator &iter, slickedit::SEString &key) const
{
   const T* pItem = prevItemInternal(iter); 
   if (pItem==NULL) return NULL;
   return currentItemInternal(iter, key);
}
template <class T> inline
T* SEStringTable<T>::prevItem(SEIterator &iter, slickedit::SEString &key)
{
   T* pItem = prevItemInternal(iter); 
   if (pItem==NULL) return NULL;
   return currentItemInternal(iter, key);
}
template <class T> inline
const T* SEStringTable<T>::prevItem(SEIterator &iter) const
{
   return prevItemInternal(iter); 
}
template <class T> inline
T* SEStringTable<T>::prevItem(SEIterator &iter)
{
   return prevItemInternal(iter); 
}

template <class T> inline
const T* SEStringTable<T>::currentItem(const SEIterator &iter, slickedit::SEString &key) const
{
   return currentItemInternal(iter, key);
}
template <class T> inline
T* SEStringTable<T>::currentItem(const SEIterator &iter, slickedit::SEString &key)
{
   return currentItemInternal(iter, key);
}
template <class T> inline
const T* SEStringTable<T>::currentItem(const SEIterator &iter) const
{
   if (iter.mFindFirst || iter.mpNode == NULL) return NULL;
   const SEPrefixTree *t = (const SEPrefixTree*) iter.mpNode;
   return t->mpData;
}
template <class T> inline
T* SEStringTable<T>::currentItem(const SEIterator &iter)
{
   if (iter.mFindFirst || iter.mpNode == NULL) return NULL;
   const SEPrefixTree *t = (const SEPrefixTree*) iter.mpNode;
   return t->mpData;
}
template <class T> inline
const slickedit::SEString SEStringTable<T>::currentKey(const SEIterator &iter) const 
{
   slickedit::SEString key;
   currentItemInternal(iter, key);
   return key;
}

template <class T> inline
int SEStringTable<T>::removeItem(SEIterator &iter)
{
   SEPrefixTree *t = (SEPrefixTree*) iter.mpNode;
   if (t != NULL && t->mpData != NULL) {
      delete t->mpData;
      t->mpData = NULL;
      mNumItems--;

      for (;;) {
         // if the node has children or data, do not delete it
         if (t->mNumChildren >= 1) break;
         if (t->mpData != NULL) break;

         // get the parent tree and remove this item
         SEPrefixTree *childTree = t;

		 // try to pop up to the parent node, if that fails, we
		 // are probably at the root node and need to stop now.
		 if (iter.popStack() < 0) {
            if (childTree == mPrefixRoot) mPrefixRoot = NULL;
            SEDeallocate(childTree);
			childTree = NULL;
			break;
		 }

		 // successfully popped, now get our parent node
         t = (SEPrefixTree*) iter.mpNode;
         if (t == NULL) break;

         // now adjust the tree structure.
         // Remove all the leaf nodes if there are no more
         unsigned char *origPivotChars = t->getPivotChars();
         t->mNumChildren--;

         // remove the pointer to the (now gone) sub tree
         SEPrefixTree **children = t->getChildren();
         size_t index = iter.mIndex;
         while (index < t->mNumChildren) {
            children[index] = children[index+1];
            origPivotChars[index] = origPivotChars[index+1];
            index++;
         }
         unsigned char *pivotChars = t->getPivotChars();
         memmove(pivotChars, origPivotChars, t->mNumChildren);

         // now deallocate the child tree
         SEDeallocate(childTree);
         childTree = 0;
      }

      // position the iterator on the next item
      nextItem(iter);
   }

   return 0;
}

template <class T> inline
const T* SEStringTable<T>::operator[](const slickedit::SEString &key) const
{
   SEPrefixTree *t = searchItem(mPrefixRoot, key.getCString(), key.length());
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}
template <class T> inline
T* SEStringTable<T>::operator[](const slickedit::SEString &key)
{
   SEPrefixTree *t = searchItem(mPrefixRoot, key.getCString(), key.length());
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}

template <class T> inline
const T* SEStringTable<T>::operator[](const VSLSTR *key) const
{
   if (key == NULL) {
      return NULL;
   }
   SEPrefixTree *t = searchItem(mPrefixRoot, (const char*)key->str, key->len);
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}
template <class T> inline
T* SEStringTable<T>::operator[](const VSLSTR *key)
{
   if (key == NULL) {
      return NULL;
   }
   SEPrefixTree *t = searchItem(mPrefixRoot, (const char*)key->str, key->len);
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}

template <class T> inline
const T* SEStringTable<T>::operator[](const char *key) const
{
   if (key == NULL) {
      return NULL;
   }
   size_t len = strlen(key);
   SEPrefixTree *t = searchItem(mPrefixRoot, key, len);
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}
template <class T> inline
T* SEStringTable<T>::operator[](const char *key)
{
   if (key == NULL) {
      return NULL;
   }
   size_t len = strlen(key);
   SEPrefixTree *t = searchItem(mPrefixRoot, key, len);
   if (t == NULL) {
      return NULL;
   }
   return t->mpData;
}

template <class T> inline
bool SEStringTable<T>::isKey(const slickedit::SEString &key) const
{
   const SEPrefixTree *t = searchItem(mPrefixRoot, key.getCString(), key.length());
   return (t != NULL && t->mpData != NULL);
}

template <class T> inline
bool SEStringTable<T>::isKey(const VSLSTR *key) const
{
   const SEPrefixTree *t = searchItem(mPrefixRoot, (const char*)key->str, key->len);
   return (t != NULL && t->mpData != NULL);
}

template <class T> inline
bool SEStringTable<T>::isKey(const char *key) const
{
   if (key == NULL) return false;
   size_t len = strlen(key);
   const SEPrefixTree *t = searchItem(mPrefixRoot, key, len);
   return (t != NULL && t->mpData != NULL);
}
template <class T> inline
bool SEStringTable<T>::isKey(const char *key, size_t len) const
{
   const SEPrefixTree *t = searchItem(mPrefixRoot, key, len);
   return (t != NULL && t->mpData != NULL);
}

template <class T> inline
int SEStringTable<T>::remove(const slickedit::SEString &key)
{
   if (key.isNull()) {
      return STRING_NOT_FOUND_RC;
   }
   int status = removeItem(mPrefixRoot, key.getCString(), key.length());
   if (status <= 0) return status;
   --mNumItems;
   return 0;
}
template <class T> inline
int SEStringTable<T>::remove(const VSLSTR *key)
{
   if (key == NULL) {
      return STRING_NOT_FOUND_RC;
   }
   int status = removeItem(mPrefixRoot, (const char*)key->str, key->len);
   if (status <= 0) return status;
   --mNumItems;
   return 0;
}
template <class T> inline
int SEStringTable<T>::remove(const char *key, size_t len)
{
   if (key == NULL) {
      return STRING_NOT_FOUND_RC;
   }
   int status = removeItem(mPrefixRoot, key, len);
   if (status <= 0) return status;
   --mNumItems;
   return 0;
}
template <class T> inline
int SEStringTable<T>::remove(const char *key)
{
   if (key == NULL) {
      return STRING_NOT_FOUND_RC;
   }
   size_t len = strlen(key);
   int status = removeItem(mPrefixRoot, key, len);
   if (status <= 0) return status;
   --mNumItems;
   return 0;
}

template <class T> inline
int SEStringTable<T>::add(const slickedit::SEString &key, const T &item)
{
   int status = insertItem(mPrefixRoot, key.getCString(), key.length(), item);
   if (status <= 0) return status;
   mNumItems++;
   return 0;
}
template <class T> inline
int SEStringTable<T>::add(const VSLSTR *key, const T &item)
{
   if (key == NULL) return INVALID_ARGUMENT_RC;
   int status = insertItem(mPrefixRoot, (const char*)key->str, key->len, item); 
   if (status <= 0) return status;
   mNumItems++;
   return 0;
}
template <class T> inline
int SEStringTable<T>::add(const char *key, size_t len, const T &item)
{
   int status = insertItem(mPrefixRoot, key, len, item);
   if (status <= 0) return status;
   mNumItems++;
   return 0;
}

template <class T> inline
int SEStringTable<T>::add(const char *key, const T &item)
{
   if (key == NULL) return INVALID_ARGUMENT_RC;
   size_t len = strlen(key);
   int status = insertItem(mPrefixRoot, key, len, item);
   if (status <= 0) return status;
   mNumItems++;
   return 0;
}

template <class T>
inline typename SEStringTable<T>::SEPrefixTree *
SEStringTable<T>::searchTree(const SEPrefixTree *t, T& item, slickedit::SEString &key) const
{
   key.append(t->mPrefixChars, t->mPrefixLength);
   if (t->mpData) {
      if (isEqual(item, *t->mpData)) {
         return t;
      }
   }
   const unsigned char *pivotChars = t->getPivotChars();
   const SEPrefixTree **children = t->getChildren();
   size_t i,n=t->mNumChildren;
   for (i=0; i<n; i++) {
      key.append(pivotChars[i]);
      const SEPrefixTree *subTree = searchTree(children[i], item, key);
      if (subTree != NULL) return subTree;
      key.trim(1);
   }
   key.trim(t->mPrefixLength);
   return NULL;
}

template <class T> inline
int SEStringTable<T>::search(T &item, slickedit::SEString &key) const
{
   key.setLength(0);
   SEPrefixTree *t = searchTree(mPrefixRoot, item, key);
   if (t==NULL) return STRING_NOT_FOUND_RC;
   if (t->mpData) {
      item = *t->mpData;
      return 0;
   }
   return STRING_NOT_FOUND_RC;
}

template <class T> inline
void SEStringTable<T>::clear()
{
   if ( mPrefixRoot != NULL) {
      deleteTree(mPrefixRoot);
      mPrefixRoot = NULL;
   }
   mNumItems = 0;
   mUpcaseKey.makeNull();
}


template <class T> inline
int SEStringTable<T>::isEqual(T &v1, T &v2) const
{
   return (pfnCompare? (pfnCompare(v1,v2)==0) : (v1==v2));
}

template <class T> inline
bool SEStringTable<T>::compareTrees(const SEPrefixTree *t1, const SEPrefixTree *t2) const
{
   // both trees must have the same number of children
   if (t1->mNumChildren != t2->mNumChildren) {
      return false;
   }
   // if one tree has data, the other one must also have data
   if ((t1->mpData != NULL) != (t2->mpData != NULL)) {
      return false;
   }
   // the prefix characters must be the same length and match exactly
   if (t1->mPrefixLength != t2->mPrefixLength) {
      return false;
   }
   if (memcmp(t1->mPrefixChars, t2->mPrefixChars, t1->mPrefixLength) != 0) {
      return false;
   }
   // the pivot characters have to match exactly
   size_t numChildren = t1->mNumChildren;
   unsigned char *pivotChars1 = t1->getPivotChars();
   unsigned char *pivotChars2 = t2->getPivotChars();
   if (memcmp(pivotChars1, pivotChars2, numChildren) != 0) {
      return false;
   }
   // the data items have to match perfectly
   if (t1->mpData != NULL && t2->mpData != NULL) {
      if (!isEqual(*t1->mpData, *t2->mpData)) {
         return false;
      }
   }
   // each subtree has to match in the same way
   for (size_t i=0; i<numChildren; i++) {
      if (compareTrees(t1->getChild(i), t2->getChild(i)) == false) {
         return false;
      }
   }
   // in this case, the tree's match perfectly
   return true;
}

template <class T> inline
bool SEStringTable<T>::operator == (const SEStringTable &lhs) const
{
   if (mNumItems != lhs.mNumItems) {
      return false;
   }
   if (mCaseSensitive != lhs.mCaseSensitive || 
       mUTF8Encoding != lhs.mUTF8Encoding ||
       pfnCompare != lhs.pfnCompare) {
      return false;
   }
   if (mPrefixRoot != NULL || lhs.mPrefixRoot != NULL) {
      return compareTrees(mPrefixRoot, lhs.mPrefixRoot);
   }
   return true;
}

template <class T> inline
bool SEStringTable<T>::operator != (const SEStringTable &lhs) const
{
   return !this->operator ==(lhs);
}


}

#endif // SLICKEDIT_STRINGTABLE_H
