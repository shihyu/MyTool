////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_HANDLE_H
#define SLICKEDIT_HANDLE_H

#include "vsdecl.h"
#include "SEMemory.h"
#include <limits>
#undef max /* Win32 #define collides with STL definition */

namespace slickedit {

/** 
 * Abstract Handle class used to abstract a resource/data object
 * into a handle. 
 * 
 * @see SESimpleHandle 
 * @see SEMagicHandle 
 */
class VSDLLEXPORT SEHandle : public SEMemory {

public:

   /** 
    * Virtual default constructor.
    */
   virtual SEHandle* create() const = 0;

   /** 
    * Virtual copy-constructor.
    */
   virtual SEHandle* clone() const = 0;

   /** 
    * Initialize handle with resource index. 
    *  
    * @param index Resource index. 
    * 
    * @return true on success. false if index is invalid or handle 
    *         is already assigned.
    */
   virtual bool init(unsigned int index) = 0;

   /** 
    * Reset handle to undefined/invalid state.
    */
   virtual void reset() = 0;

   /** 
    * Test for a valid handle.
    * 
    * @return true if valid.
    */
   virtual bool valid() const = 0;

   /** 
    * Index to object referenced by handle.
    * 
    * @return Unsigned integer index.
    */
   virtual unsigned int getIndex() const = 0;

   /** 
    * Unsigned integer representation of handle.
    * 
    * @return Unsigned integer handle.
    */
   virtual unsigned int getHandle() const = 0;
};


//////////////////////////////////////////////////////////////////////////////
// SESimpleHandle
//////////////////////////////////////////////////////////////////////////////

/** 
 * Simple handle. Used to abstract access to a data object.
 */
class VSDLLEXPORT SESimpleHandle : public SEHandle {

private:
   unsigned int m_index;

public:

   enum { 
      // Invalid handle
      // A SESimpleHandle has no flag that indicates it is invalid,
      // so we use MAXUNSIGNED (unsigned=0xffffffff, signed=-1) to invalidate.
      INVALID_HANDLE = VSMAXUNSIGNED
   };

   SESimpleHandle(unsigned int handle=INVALID_HANDLE);
   SESimpleHandle(const SESimpleHandle& handle);
   virtual ~SESimpleHandle();

   SESimpleHandle& operator= (const SESimpleHandle& handle);

   virtual SESimpleHandle* create() const;
   virtual SESimpleHandle* clone() const;

   virtual bool init(unsigned int index);
   virtual void reset();
   virtual bool valid() const;

   virtual unsigned int getIndex() const;
   virtual unsigned int getHandle() const;

};

inline bool operator== (SESimpleHandle l, SESimpleHandle r) {
   return ( l.getHandle() == r.getHandle() );
}

inline bool operator!= (SESimpleHandle l, SESimpleHandle r) {
   return ( l.getHandle() != r.getHandle() );
}

//////////////////////////////////////////////////////////////////////////////
// SEMagicHandle
//////////////////////////////////////////////////////////////////////////////

/**
 * Magic handle. Used to abstract access to a data object. 
 * Ensures validity of handle with an internal "magic number". 
 */
class VSDLLEXPORT SEMagicHandle : public SEHandle {

private:
   // A handle takes up 32 bits
   union {
      struct {
         // Resource index
         unsigned short m_index;
         // Magic number for handle validity check
         unsigned short m_magic;
      } m_resource;
      // Unique handle
      unsigned int m_handle;
   };

public:

   enum {
      // Invalid handle
      INVALID_HANDLE = 0
   };

   SEMagicHandle(unsigned int handle=INVALID_HANDLE);
   SEMagicHandle(const SEMagicHandle& handle);
   virtual ~SEMagicHandle();

   SEMagicHandle& operator= (const SEMagicHandle& handle);

   virtual SEMagicHandle* create() const;
   virtual SEMagicHandle* clone() const;

   virtual bool isNull() const;

   virtual bool init(unsigned int index);

   virtual void reset();
   virtual bool valid() const;

   virtual unsigned int getIndex() const;
   virtual unsigned int getHandle() const;

};

inline bool operator== (SEMagicHandle l, SEMagicHandle r) {
   return ( l.getHandle() == r.getHandle() );
}

inline bool operator!= (SEMagicHandle l, SEMagicHandle r) {
   return ( l.getHandle() != r.getHandle() );
}

}

#endif // SLICKEDIT_HANDLE_H
