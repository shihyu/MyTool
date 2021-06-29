////////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include <memory.h>

namespace slickedit {

// Allocation routines used within Slickedit
EXTERN_C VSDLLEXPORT void* SEAllocate(size_t size);
EXTERN_C VSDLLEXPORT void* SEReallocate(void *p, size_t size);
EXTERN_C VSDLLEXPORT void SEDeallocate(void *p);
EXTERN_C VSDLLEXPORT size_t SEAllocationSize(void *p);
EXTERN_C VSDLLEXPORT void SEAllocateCheckMemory(void *p);

/**
 * Template function for allocating sizeof(T) and casting result
 */
template <class T>
inline T* SEAllocateType() {
    return (T*) SEAllocate(sizeof(T));
}

}

