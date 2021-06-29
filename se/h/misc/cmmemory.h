#pragma once
#include "cmstd.h"
#include <string.h>

#define SLICKEDIT_MEMORY_DISABLE_NEW_DELETE 0

CMEXTERN_C CMDLLEXPORT char *cmAlloc(cmuint len);
CMEXTERN_C CMDLLEXPORT char *cmRealloc(void *p,cmuint len);
CMEXTERN_C CMDLLEXPORT void cmFree(void *p);
CMEXTERN_C CMDLLEXPORT cmuint cmAllocCapacity(void *p);
CMEXTERN_C CMDLLEXPORT void  cmAllocCheckMemory(void *p);

/**
 * Allocate one item of type T. 
 * @return cmAlloc(sizeof(T)) 
 */
template <class T>
inline T* cmAllocType() {
    return static_cast<T*>((void*)cmAlloc(sizeof(T)));
}
/**
 * Allocate an array of items of type T
 * @param numItems    Number of items to allocate 
 * @return cmAlloc(sizeof(T) * numItems)
 */
template <class T>
inline T* cmAllocType(cmuint numItems) {
    return static_cast<T*>((void*)cmAlloc(sizeof(T)*numItems));
}
/**
 * Allocate an array of items of type T, and an extra portion of bytes
 * @param numItems    Number of items to allocate 
 * @param extraBytes  Extra quantity of memory to allocate 
 * @return cmAlloc(sizeof(T) * numItems + extraBytes)
 */
template <class T>
inline T* cmAllocType(cmuint numItems, cmuint extraBytes) {
    return static_cast<T*>((void*)cmAlloc(sizeof(T)*numItems+extraBytes));
}

/**
 * Allocate one item of type T, and 0 out memory.
 * @return cmAlloc(sizeof(T)) 
 */
template <class T>
inline T* cmAllocTypeAndZero() {
    T *p = static_cast<T*>((void*)cmAlloc(sizeof(T)));
    if (p) memset(p, 0, sizeof(T));
    return p;
}
/**
 * Allocate an array of items of type T, and 0 out memory.
 * @param numItems    Number of items to allocate 
 * @return cmAlloc(sizeof(T) * numItems)
 */
template <class T>
inline T* cmAllocTypeAndZero(cmuint numItems) {
    T *p = static_cast<T*>((void*)cmAlloc(sizeof(T)*numItems));
    if (p) memset(p, 0, sizeof(T)*numItems);
    return p;
}
/**
 * Allocate an array of items of type T, and an extra portion of bytes, and 0 out memory.
 * @param numItems    Number of items to allocate 
 * @param extraBytes  Extra quantity of memory to allocate 
 * @return cmAlloc(sizeof(T) * numItems + extraBytes)
 */
template <class T>
inline T* cmAllocTypeAndZero(cmuint numItems, cmuint extraBytes) {
    T* p = static_cast<T*>((void*)cmAlloc(sizeof(T)*numItems+extraBytes));
    if (p) memset(p, 0, sizeof(T)*numItems+extraBytes);
    return p;
}

/**
 * Re-allocate an array of items of type T
 * @param p           Pointer to item to reallocate and copy (nullptr means allocate new array) 
 * @param numItems    Number of items to allocate 
 * @return cmRealloc(p, sizeof(T) * numItems)
 */
template <class T>
inline T* cmReallocType(T* p, cmuint numItems) {
    return static_cast<T*>((void*)cmRealloc(p, sizeof(T)*numItems));
}
/**
 * Re-allocate an array of items of type T, and an extra portion of bytes 
 * @param p           Pointer to item to reallocate and copy (nullptr means allocate new array) 
 * @param numItems    Number of items to allocate 
 * @param extraBytes  Extra quantity of memory to allocate 
 * @return cmRealloc(p, sizeof(T) * numItems + extraBytes)
 */
template <class T>
inline T* cmReallocType(T* p, cmuint numItems, cmuint extraBytes) {
    return static_cast<T*>((void*)cmRealloc(p, sizeof(T)*numItems + extraBytes));
}

/**
 * Re-allocate an array of items of type T, and zero out the *new* memory
 * @param p           Pointer to item to reallocate and copy (nullptr means allocate new array) 
 * @param numItems    Number of items to allocate 
 * @return cmRealloc(p, sizeof(T) * numItems)
 */
template <class T>
inline T* cmReallocTypeAndZero(T* p, cmuint numItems) {
    cmuint origSize = (p? cmAllocCapacityType(p) : 0);
    p = static_cast<T*>((void*)cmRealloc(p, sizeof(T)*numItems));
    if (p && numItems > origSize) memset(&p[origSize], 0, sizeof(T)*(numItems-origSize));
    return p;
}
/**
 * Re-allocate an array of items of type T, and an extra portion of bytes, and zero out the *new* memory
 * @param p           Pointer to item to reallocate and copy (nullptr means allocate new array) 
 * @param numItems    Number of items to allocate 
 * @param extraBytes  Extra quantity of memory to allocate 
 * @return cmRealloc(p, sizeof(T) * numItems + extraBytes)
 */
template <class T>
inline T* cmReallocTypeAndZero(T* p, cmuint numItems, cmuint extraBytes) {
    cmuint origSize = (p? cmAllocCapacity(p) : 0);
    p = static_cast<T*>((void*)cmRealloc(p, sizeof(T)*numItems+extraBytes));
    if (p && numItems*sizeof(T)+extraBytes > origSize) memset(((char*)p)+origSize, 0, sizeof(T)*numItems+extraBytes-origSize);
    return p;
}

/**
 * Return the number of items of type T allocated to this pointer
 * @param p           Pointer to array of items
 * @return cmAllocCapacity(p) / sizeof(T)
 */
template <class T>
inline cmuint cmAllocCapacityForType(T* p) {
    static_assert(sizeof(T) > 0, "Type can not be void");
    return cmAllocCapacity(p) / sizeof(T);
}

// All code must be reentrant for thread. 
// Implement small size allocator later
class CMDLLEXPORT cmMemory {
public:
#if !SLICKEDIT_MEMORY_DISABLE_NEW_DELETE
   void * operator new(size_t nbytes) noexcept;
   void * operator new[](size_t size) noexcept;
   void operator delete(void *p);
   void operator delete[](void * p);
#endif
};

// Just like cmMemory, but with a virtual destructor
class CMDLLEXPORT cmDeletableMemory : public cmMemory {
public:
    cmDeletableMemory();
    cmDeletableMemory(const cmDeletableMemory &);
    cmDeletableMemory(cmDeletableMemory &&);
    cmDeletableMemory &operator = (const cmDeletableMemory &);
    cmDeletableMemory &operator = (cmDeletableMemory &&);
    virtual ~cmDeletableMemory();
};

