////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_MEMORY_H
#define SLICKEDIT_MEMORY_H
#include "vsdecl.h"
#include <memory.h>

#define SLICKEDIT_MEMORY_DISABLE_NEW_DELETE 0

namespace slickedit {

// Allocation routines used within Slickedit
EXTERN_C VSDLLEXPORT void * SEAllocate(size_t size);
EXTERN_C VSDLLEXPORT void * SEReallocate(void *p, size_t size);
EXTERN_C VSDLLEXPORT void   SEDeallocate(void *p);
EXTERN_C VSDLLEXPORT size_t SEAllocationSize(void *p);
EXTERN_C VSDLLEXPORT void   SEAllocateCheckMemory(void *p);

/**
 * Template function for allocating sizeof(T) and casting result
 */
template <class T>
inline T* SEAllocateType() {
    return (T*) SEAllocate(sizeof(T));
}

/**
 * This class implements operators new and delete for all
 * classes in the slickedit library.  All base classes derive
 * from this class in order to pick up and use these allocators.
 */
class VSDLLEXPORT SEMemory {

public:

#if !SLICKEDIT_MEMORY_DISABLE_NEW_DELETE

   /**
    * operator new
    */

   void *operator new(size_t nbytes) throw();
   void *operator new[](size_t size) throw();

   /**
    * operator delete
    */
   void operator delete(void *p);
   void operator delete[](void * p);

#endif

};

}

#endif // SLICKEDIT_MEMORY_H
