////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_STACK_H
#define SLICKEDIT_STACK_H

#include "SEArray.h"
#include <new>

namespace slickedit {

/**
 * Manage an stack of elements of type T.  The stack can dynamically
 * grow if needed.  The stack has only three operations, push(),
 * pop(), and clear().
 * <p>
 * Requirements:
 * <ul>
 * <li>Type T must have a default constructor (ie. a constructor with no
 *     required arguments), a copy constructor, and an assignment operator.
 * </ul>
 *
 * @see SEArray
 * @see SEQueue
 */
template <class T>
class SEStack : public SEMemory {
public:

   /**
    * Default constructor for SEStack, you may specify an
    * optional initial capacity for the stack, and the stack
    * will be initialized with that many elements.  If the
    * allocation of the initial stack fails, _plist will be null.
    *
    * @param initialCapacity (optional) initial capacity of stack
    */
   SEStack(int initialCapacity=0);
   /**
    * Copy constructor for SEStack class.  Performs a deep copy
    * of the stack.  If allocation fails, _plist will be null.
    *
    * @param src        SEStack to copy.
    */
   SEStack(const SEStack<T> &src);
   /**
    * Destructor.  Individually destructs each item allocated
    * by the stack, and then deletes the stack itself.
    */
   ~SEStack();
   /**
    * Assignment operator for SEStack.  Performs a deep copy
    * of the stack contents.  If the stack has to grow, but
    * the allocation fails, you will know because this.length()
    * will not equal src.length().
    *
    * @param src        SEStack to copy
    *
    * @return *this
    */
   SEStack<T> & operator=(const SEStack<T> &src);

   /**
    * Comparison operator
    *
    * @param rhs        right hand side of == expression
    */
   bool operator==(const SEStack<T> &rhs) const;
   bool operator!=(const SEStack<T> &rhs) const;

   /**
    * Set statck depth to 0.  No destructors are called.
    */
   void clear();
   /**
    * Make the SEStack empty, completely empty.
    * Calls destructors and deallocates _plist.
    */
   void makeEmpty();

   /**
    * Add a new item to the top of the stack.
    *
    * @param item         Item to be added
    *
    * @return 0 if successful. Otherwise -1.
    */
   int push(const T & item);

   /**
    * Remove an item from the stack and return it.
    *
    * @return pointer to item on success, 0 on failure.
    */
   T pop();
   /**
    * Remove an item from the stack if one is available.
    *
    * @param item (reference) set to value of the item
    *
    * @return 0 on success, <0 on error.
    */
   int pop(T& item);

   /**
    * @return Return the item on top of the stack
    */
   const T &top() const;
   T &top();
   /**
    * @return Return the item on the bottom of the stack
    */
   const T &bottom() const;
   T &bottom();
   /**
    * Get the top item from the stack if one is available.
    *
    * @param item (reference) set to value of the item
    *
    * @return 0 on success, <0 on error.
    */
   int top(T& item) const;

   /**
    * @return Return the n'th item on under the top of the stack
    *         peek(0) is equivelent to top()
    *
    * @param n number of items to look under
    */
   const T &peek(size_t n) const;
   T &peek(size_t n);
   /**
    * Get the n'th item under the top of the stack.
    * peek(0) is equivelent to top()
    *
    * @param n    number of items to look under
    * @param item (reference) set to value of the item
    *
    * @return 0 on success, <0 on error.
    */
   int peek(size_t n, T& item) const;

   /**
    * @return Return the peek index of the given item if it is 
    * found somewhere on the stack.  For example, if the item is 
    * on the top of the stack, this will return 0;
    */
   int search(const T& item) const;

   /**
    * Remove the item at the given index from the top of the stack.
    */
   int remove(size_t n);

   /**
    * @return Return the number of items stored in the stack.
    */
   size_t length() const;

private:

   // the stack is implemented as a SEArray
   SEArray<T> mStack;

};


template<class T> inline
SEStack<T>::SEStack(int initialCapacity):
   mStack(initialCapacity)
{
}
template<class T> inline
SEStack<T>::SEStack(const SEStack<T> &src):
   mStack(src.mStack)
{
}
template<class T> inline
SEStack<T> & SEStack<T>::operator=(const SEStack<T> &src)
{
   if (this != &src) {
      mStack = src.mStack;
   }
   return(*this);
}
template<class T> inline
bool SEStack<T>::operator==(const SEStack<T> &src) const
{
   return (mStack == src.mStack);
}
template<class T> inline
bool SEStack<T>::operator!=(const SEStack<T> &src) const
{
   return (mStack != src.mStack);
}
template<class T> inline
SEStack<T>::~SEStack()
{
}

template<class T> inline
void SEStack<T>::clear()
{
   mStack.clear();
}

template<class T> inline
void SEStack<T>::makeEmpty()
{
   mStack.makeEmpty();
}

template<class T> inline
int SEStack<T>::push(const T & item)
{
   return mStack.add(item);
}

template<class T> inline
T SEStack<T>::pop()
{
   size_t top=mStack.length();
   T item = mStack[top-1];
   mStack.remove(top-1);
   return item;
}
template<class T> inline
int SEStack<T>::pop(T& item)
{
   size_t top=mStack.length();
   if (top == 0) {
      return -1;
   }
   item = mStack[top-1];
   return mStack.remove(top-1);
}

template<class T> inline
const T & SEStack<T>::top() const
{
   size_t top=mStack.length();
   return mStack[top-1];
}
template<class T> inline
int SEStack<T>::top(T& item) const
{
   size_t top=mStack.length();
   if (top == 0) {
      return -1;
   }
   item = mStack[top-1];
   return 0;
}

template<class T> inline
T & SEStack<T>::top()
{
   size_t top=mStack.length();
   return mStack[top-1];
}

template<class T> inline
const T & SEStack<T>::bottom() const
{
   return mStack[0];
}
template<class T> inline
T & SEStack<T>::bottom()
{
   return mStack[0];
}

template<class T> inline
const T & SEStack<T>::peek(size_t n) const
{
   size_t top=mStack.length();
   return mStack[top-1-n];
}
template<class T> inline
T & SEStack<T>::peek(size_t n)
{
   size_t top=mStack.length();
   return mStack[top-1-n];
}
template<class T> inline
int SEStack<T>::peek(size_t n, T& item) const
{
   size_t top=mStack.length();
   if (n >= top) {
      return -1;
   }
   item = mStack[top-1-n];
   return 0;
}

template<class T> inline
int SEStack<T>::search(const T& item) const
{
   int pos = mStack.search(item);
   if (pos < 0) return pos;
   return static_cast<int>(mStack.length())-1-pos;
}

template<class T> inline
int SEStack<T>::remove(size_t n)
{
   size_t top=mStack.length();
   if (n >= top) return INVALID_ARGUMENT_RC;
   return mStack.remove(top-1-n);
}

template<class T> inline
size_t SEStack<T>::length() const
{
   return mStack.length();
}

}

#endif // SLICKEDIT_STACK_H
