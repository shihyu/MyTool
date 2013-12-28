////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_STRINGPOOL_H
#define SLICKEDIT_STRINGPOOL_H

#include "vsdecl.h"
#include "SEString.h"
#include "SEHashSet.h"

namespace slickedit {

//////////////////////////////////////////////////////////////////////////

/**
 * Manage a pool of reference counted strings.
 * <p>
 * This class provides a mechanism to select an instance of a string
 * string from the pool and use that version in order to take advantage
 * of the reference counting inherint to SEString's.
 */
class VSDLLEXPORT SEStringPool : public SEMemory {
public:
   // constructors
   SEStringPool(int initialCapacity=89);
   SEStringPool(const SEStringPool& rhs);
   // destructor
   ~SEStringPool();

   // assignment operator
   SEStringPool& operator=( const SEStringPool& rhs );

   /**
    * Internalize the given string, returning a 'const' reference
    * to a string <code>'r'</code> found in the pool, such that 
    * <code>(s == r)</code>.
    * <p>
    * This function will add 's' to the pool if it is not already
    * in the pool.
    * 
    * @param s       input string
    * @return  normalize string
    */
   const SEString &get(const SEString &s);
   const SEString &get(const char *s);
   void internalize(SEString &s);

   /**
    * Remove the give string from the pool.
    */
   int remove(const SEString &s);
   /**
    * Remove everything from the pool.
    */
   void clear();

   /**
    * @return Return the number of items in the pool.
    */
   unsigned int length() const;
   /**
    * @return Return an array of all the strings in the pool.
    */
   SEString *getStrings() const;

private:
   // the actual string pool is simply a hash set
   SEHashSet<SEString>* mPool;
};

}

#endif // SLICKEDIT_STRINGPOOL_H
