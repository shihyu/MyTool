////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_HANDLE_MANAGER_H
#define SLICKEDIT_HANDLE_MANAGER_H

#include "SEMemory.h"

/**
 * Template class to manage handles of pointers to type T. 
 * Typical usage would be: 
 *  
 * T *tp = new T(); 
 * int iHandle = handlehandleMgr->add(tp); 
 * ...
 * T *tp = handlehandleMgr->release( iHandle ); 
 * delete tp; 
 *  
 * Algorithm: 
 * Keep a table of PTRITEM items.  PTRITEM is: 
 *  
 *     union PTRITEM { 
 *        T *pt;
 *        PTRITEM *pNextFree;
 *     };
 * 
 * Private member m_pNextFreeItem is a poitner to the first free item in the 
 * list, and union will be set to the next item.
 */

namespace slickedit {
template <class T>
class SEHandleManager {
public:
   /** 
    * @param iInitialSize the number of items the table will initally hold.
    * Defaults to 10. 
    *  
    * @param callDelete if true, call delete when handles are released. 
    * Defaults to false
    */
   SEHandleManager(int iInitialSize=10,bool callDelete=false);

   ~SEHandleManager();

   /** 
    * Add <B>t</B> to the table and return a handle to it
    * 
    * @return int handle to newly added item <B>t</B>
    */
   int add(T *pt);

   /**
    * @return bool true if <B>iHandle</B> is valid
    */
   bool isHandleValid(int iHandle) const;

   /**
    * @return int The number of handles in use.
    */
   int length() const;

   /**
    * @return int The highest handle number available. 
    *             All may not be valid!
    */
   int getMaxHandle() const;

   /**
    * @return T* item associated with <B>iHandle</B>
    */
   T *get(int iHandle) const;

   /**
    * Free Handle <B>iHandle</B>.  If SEHandleManager was constructed with 
    * <B>callDelete</B> set to true, it will delete the object as well.
    *  
    * @return T* if <B>callDelete</B> is false returns pointer object associated 
    * with <B>iHandle</B>. Otherwise returns NULL.
    */
   T *releaseHandle(int iHandle); 

   /**
    * Free all handles.
    */
   void clear();

   /**
    * Turn off to not reuse handles
    * 
    * @param onOff  value to turn on and off
    * 
    * @return Returns previous setting
    */
   bool recycleObjects(bool onOff);

private:

   /** 
    * Struct to build table out of. Includes an entry for valid and 
    * next free index 
    */
   union PTRITEM {
      T *pt;
      PTRITEM *pNextFree;
   };

   /**
    * reallocate <B>m_pTable</B> to be sure it is big enough
    */
   void maybeReallocateTable();

   int m_iNumHandlesAllocated;
   int m_iNumHandlesActive;
   int m_iNumHandlesUsed;
   int m_iInitialSize;
   bool m_recycleObjects;
   bool m_callDelete;
   PTRITEM *m_pTable;
   PTRITEM *m_pNextFreeItem;
};

template <class T>
inline SEHandleManager<T>::SEHandleManager(int iInitialSize/*=10*/,bool callDelete/*=false*/) :
      m_iNumHandlesAllocated(0),
      m_iNumHandlesActive(0),
      m_iNumHandlesUsed(0),
      m_iInitialSize(iInitialSize),
      m_pTable(NULL),
      m_pNextFreeItem(NULL),
      m_recycleObjects(true),
      m_callDelete(callDelete)
{
}

template <class T>
inline void SEHandleManager<T>::clear()
{
   if ( m_pTable ) {

      // If m_callDelete is on, we have to call delete for any valid handles left
      if ( m_callDelete ) {
         for ( int i=0;i<m_iNumHandlesUsed;++i ) {
            if ( isHandleValid(i) ) {
               delete m_pTable[i].pt;
               m_pTable[i].pNextFree = NULL;
            }
         }
      }
      slickedit::SEDeallocate(m_pTable);
      m_iNumHandlesAllocated = 0;
      m_iNumHandlesActive = 0;
      m_iNumHandlesUsed = 0;
      m_pNextFreeItem = NULL;
      m_pTable = NULL;
   }
}

template <class T>
inline SEHandleManager<T>::~SEHandleManager()
{
   clear();
}

template <class T>
int SEHandleManager<T>::add(T *pt)
{
   size_t iCurHandle;
   
   if ( m_recycleObjects && m_pNextFreeItem!=NULL ) {
      
      // Have to do this first.  Since the items are a union, when we set
      // pt below, it will change the value of m_pNextFreeItem
      iCurHandle = m_pNextFreeItem - m_pTable;
      PTRITEM *pNextFree = m_pNextFreeItem->pNextFree;
      
      m_pNextFreeItem->pt = pt;

      m_pNextFreeItem = pNextFree;

      ++m_iNumHandlesActive;
      return (int)iCurHandle;
   }

   maybeReallocateTable();
   iCurHandle = m_iNumHandlesUsed;
   ++m_iNumHandlesUsed;
   m_pTable[iCurHandle].pt = pt;

   ++m_iNumHandlesActive;
   return (int)iCurHandle;
}

template <class T>
bool SEHandleManager<T>::isHandleValid(int iHandle) const
{
   if ( iHandle>=0 && iHandle<m_iNumHandlesUsed ) {
      PTRITEM *p = m_pTable[iHandle].pNextFree;
      if ( !p ) return false;

      return p<m_pTable || p>=m_pTable+m_iNumHandlesAllocated;
   }
   return false;
}

template<class T>
int SEHandleManager<T>::length() const
{
   return m_iNumHandlesActive;
}

template<class T>
int SEHandleManager<T>::getMaxHandle() const
{
   return m_iNumHandlesUsed;
}

template <class T>
T *SEHandleManager<T>::get(int iHandle) const 
{
   if ( isHandleValid(iHandle) ) return m_pTable[iHandle].pt;
   return (T *) NULL;
}

template <class T>
T *SEHandleManager<T>::releaseHandle(int iHandle) 
{
   if ( !isHandleValid(iHandle) ) return NULL;

   // We have to save this pointer so we can return it.  Since our items are
   // a union, when we set pNextFree below, we will lose this pointer.
   T* pt = m_pTable[iHandle].pt;

   PTRITEM *pCurNextFreeItem = m_pNextFreeItem;
   m_pNextFreeItem = &m_pTable[iHandle];

   //int calculatedHandle = m_pNextFreeItem - m_pTable;

   m_pNextFreeItem->pNextFree = pCurNextFreeItem;

   if ( m_callDelete ) {
      delete pt;
      pt = (T *) NULL;
   }

   if (m_iNumHandlesActive > 0) {
      --m_iNumHandlesActive;
   }
   return pt;
}

template <class T>
bool SEHandleManager<T>::recycleObjects(bool onOff)
{
   bool old=m_recycleObjects;
   m_recycleObjects = onOff;
   return old;
}

template <class T>
void SEHandleManager<T>::maybeReallocateTable() {
   if ( m_iNumHandlesUsed>=m_iNumHandlesAllocated ) {
      int iOldSize = m_iNumHandlesAllocated;
      int iNewSize = m_iNumHandlesAllocated + (m_iNumHandlesAllocated/4);
      if ( iNewSize<10 ) iNewSize = 10;

      PTRITEM *pOrigTable = m_pTable;
      PTRITEM *pOrigEndTable = m_pTable+m_iNumHandlesUsed;

      m_pTable = (PTRITEM*) slickedit::SEReallocate(m_pTable,sizeof(PTRITEM)*iNewSize);
      // Reallocate the table, and then memset the new part of it
      memset(m_pTable+m_iNumHandlesAllocated,0,sizeof(PTRITEM)*(iNewSize-iOldSize));

      if ( pOrigTable ) {
         // If we reallocated the table, we must look through for entries that
         // were part of the free list and adjust them.
         if ( m_pNextFreeItem ) {
            ptrdiff_t adjust;
            adjust=((char *)m_pTable-(char *)pOrigTable);
            m_pNextFreeItem = (PTRITEM *)((char *)m_pNextFreeItem+adjust);

            for ( int i=0;i<m_iNumHandlesUsed;++i ) {
               if ( m_pTable[i].pNextFree>=pOrigTable && m_pTable[i].pNextFree<pOrigEndTable ) {
                  m_pTable[i].pNextFree=(PTRITEM *)((char *)m_pTable[i].pNextFree+adjust);
               }
            }
         }
      }

      m_iNumHandlesAllocated = iNewSize;
   }

}

#if 0 //2:17pm 5/6/2011
/** 
 * Manage pool of handles to data objects. 
 * <p>
 * Requirements:
 * <ul>
 * <li>Type DATA must have a default constructor (i.e. a 
 *     constructor with no required arguments), a copy
 *     constructor, and an assignment operator.
 * <li>Type HANDLE must be derived from SEHandle and defaults 
 *     to SESimpleHandle if not provided.
 * </ul> 
 *  
 * @see SESimpleHandle 
 * @see SEMagicHandle 
 */
template <typename DATA, class HANDLE=SESimpleHandle>
class SEHandleManager : public SEMemory {

private:
   struct HandleObject : public SEMemory {

      enum {
         HOBJ_NULL = -1
      };

      bool m_valid;
      DATA m_data;
      HANDLE m_handle;
      // Next/prev used/free HandleObject allows quick iteration over all
      // items.
      int m_next;
      int m_prev;

      HandleObject() :
         m_valid(false)
         ,m_next(HOBJ_NULL)
         ,m_prev(HOBJ_NULL) {
      }

      HandleObject(const HandleObject& hobj) :
         m_valid(hobj.m_valid)
         ,m_data(hobj.m_data)
         ,m_handle(hobj.m_handle)
         ,m_next(hobj.m_next)
         ,m_prev(hobj.m_prev) {

      }

      HandleObject(const HANDLE& handle, const DATA& data) :
         m_valid(false)
         ,m_handle(handle)
         ,m_data(data)
         ,m_next(HOBJ_NULL)
         ,m_prev(HOBJ_NULL) {
      }

      HandleObject& operator= (const HandleObject& hobj) {
         if( this != &hobj ) {
            m_valid = hobj.m_valid;
            m_data = hobj.m_data;
            m_handle = hobj.m_handle;
            m_next = hobj.m_next;
            m_prev = hobj.m_prev;
         }
         return *this;
      }
   };
   // Pool of handle/data
   SEArray<HandleObject> m_hobj;
   // Free/available stack
   SEStack<unsigned int> m_free;
   // Index of first item allocated/used to iterate over all
   // allocated/used items.
   int m_head;

public:

   typedef void (*ForEachProc)(HANDLE handle, DATA& data, void* userData);

   SEHandleManager();
   ~SEHandleManager();

   /** 
    * Check if a handle is valid.
    * 
    * @param handle
    * 
    * @return true if handle is valid.
    */
   bool isHandleValid(const HANDLE& handle) const;

   /** 
    * Allocate a handle for DATA.
    * 
    * @param handle (out). Allocated handle.
    * 
    * @return Pointer to DATA associated with allocated handle.
    */
   DATA* allocate(HANDLE& handle);

   /** 
    * Allocate a handle and store data.
    * 
    * @param handle (out). Allocated handle.
    * @param data   (in). Data to associate with handle.
    * 
    * @return true on success.
    */
   bool allocate(HANDLE& handle, DATA data);

   /** 
    * Release handle back to free pool of handles.
    * 
    * @param handle
    * 
    * @return true if successful, false if handle not valid.
    */
   bool release(HANDLE handle);

   /** 
    * Get pointer to DATA associated with handle.
    * 
    * @param handle
    * 
    * @return Pointer to DATA.
    */
   DATA* get(HANDLE handle);
   const DATA* get(HANDLE handle) const;

   /** 
    * Release all handles.
    */
   void clear();

   /** 
    * Get number of handles allocated.
    * 
    * @return Number of handles allocated.
    */
   int length() const;

   /**
    * Execute an operator for each handle/data object in use.
    * <p>
    * Note: this function is only as const as the forEach proc. 
    *  
    * @param proc     ForEachProc callback. 
    * @param userData Pointer to optional userdata that is passed 
    *                 to the callback. Defaults to 0.
    */
   void forEach(ForEachProc proc, void* userData=0) const;
   void forEach(ForEachProc proc, void* userData=0);

   /**
    * Array access operators.
    * Note that that given handle must be valid. 
    *
    * @return reference to item at specified index
    */
   DATA & operator[]( HANDLE handle );
   const DATA & operator[]( HANDLE handle ) const;

   /**
    * Debug.
    */
   void print() const;

};

template <typename DATA, class HANDLE>
inline SEHandleManager<DATA,HANDLE>::SEHandleManager() :
   m_head(HandleObject::HOBJ_NULL)
{
}

template <typename DATA, class HANDLE>
inline SEHandleManager<DATA,HANDLE>::~SEHandleManager()
{
}

template <typename DATA, class HANDLE>
inline bool SEHandleManager<DATA,HANDLE>::isHandleValid(const HANDLE& handle) const
{
   size_t index = handle.getIndex();
   if( index >= (size_t)m_hobj.length() ) {
      // Index out-of-range
      return false;
   }
   if( !m_hobj[index].m_valid ) {
      // Handle already marked free
      return false;
   }
   if( handle.valid() && handle != m_hobj[index].m_handle ) {
      // Invalid handle
      return false;
   }

   // Valid handle
   return true;
}

template <typename DATA, class HANDLE>
inline DATA* SEHandleManager<DATA,HANDLE>::allocate(HANDLE& handle)
{
   int index;
   if( m_free.length() == 0 ) {
      // No more free slots, so make more
      index = (int)m_hobj.length();
      handle.init(index);
      if( 0 != m_hobj.add( HandleObject(handle,DATA()) ) ) {
         // Error
         return 0;
      }
   } else {
      index = m_free.pop();
      handle.init(index);
      m_hobj[index] = HandleObject(handle,DATA());
   }

   // Update linked list of used items
   m_hobj[index].m_next = HandleObject::HOBJ_NULL;
   m_hobj[index].m_prev = HandleObject::HOBJ_NULL;
   if( m_head == HandleObject::HOBJ_NULL ) {
      // First item
      m_head = index;
      m_hobj[ m_head ].m_next = m_head;
      m_hobj[ m_head ].m_prev = m_head;
   } else {
      // Append allocated item onto tail
      int tail = m_hobj[ m_head ].m_prev;
      m_hobj[ tail ].m_next = index;
      m_hobj[ index ].m_prev = tail;
      m_hobj[ m_head ].m_prev = index;
      m_hobj[ index ].m_next = m_head;
   }

   // Success
   m_hobj[index].m_valid = true;
   return ( &(m_hobj[index].m_data) );
}

template <typename DATA, class HANDLE>
inline bool SEHandleManager<DATA,HANDLE>::allocate(HANDLE& handle, DATA data)
{
   DATA* pdata = allocate(handle);
   if( !pdata ) {
      return false;
   }
   *pdata = data;

   // Success
   return true;
}

template <typename DATA, class HANDLE>
inline bool SEHandleManager<DATA,HANDLE>::release(HANDLE handle)
{
   if( !isHandleValid(handle) ) {
      return false;
   }

   // Invalidate/release the entry
   size_t index = handle.getIndex();
   m_hobj[index].m_valid = false;
   m_hobj[index].m_handle.reset();
   m_free.push((unsigned int)index);

   // Update linked list of used items
   int next = m_hobj[index].m_next;
   int prev = m_hobj[index].m_prev;
   if( next == index ) {
      // Releasing last item
      m_head = HandleObject::HOBJ_NULL;
   } else {
      m_hobj[ prev ].m_next = next;
      m_hobj[ next ].m_prev = prev;
      if( m_head == index ) {
         // Just released the first item, so adjust
         // m_head to point to next item.
         m_head = next;
      }
   }
   m_hobj[index].m_next = HandleObject::HOBJ_NULL;
   m_hobj[index].m_prev = HandleObject::HOBJ_NULL;

   // Success
   return true;
}

template <typename DATA, class HANDLE>
inline DATA* SEHandleManager<DATA,HANDLE>::get(HANDLE handle)
{
   if( !isHandleValid(handle) ) {
      return 0;
   }
   int index = handle.getIndex();
   return ( &(m_hobj[index].m_data) );
}

template <typename DATA, class HANDLE>
inline const DATA* SEHandleManager<DATA,HANDLE>::get(HANDLE handle) const
{
   // const_cast is okay since non-const version does not modify instance.
   typedef SEHandleManager<DATA,HANDLE> ThisType;
   return ( const_cast<ThisType*>(this)->get(handle) );
}

template <typename DATA, class HANDLE>
inline void SEHandleManager<DATA,HANDLE>::clear()
{
   m_hobj.clear();
   m_free.clear();
   m_head = HandleObject::HOBJ_NULL;
}

template <typename DATA, class HANDLE>
inline int SEHandleManager<DATA,HANDLE>::length() const
{
   return (int)( m_hobj.length() - m_free.length() );
}

template <typename DATA, class HANDLE>
inline void SEHandleManager<DATA,HANDLE>::forEach(ForEachProc proc, void* userData)
{
   if( m_head == HandleObject::HOBJ_NULL ) {
      // Nothing to do
      return;
   }

   int i = m_head;
   do {

      (*proc)(m_hobj[i].m_handle,m_hobj[i].m_data,userData);
      i = m_hobj[i].m_next;

   } while( i != m_head );
}

template <typename DATA, class HANDLE>
inline void SEHandleManager<DATA,HANDLE>::forEach(ForEachProc proc, void* userData) const
{
   // const_cast is okay since non-const version does not modify instance.
   // The callback might modify the DATA&, but that is another story.
   typedef SEHandleManager<DATA,HANDLE> ThisType;
   const_cast<ThisType*>(this)->forEach(proc,userData);
}

template <typename DATA, class HANDLE>
inline DATA & SEHandleManager<DATA,HANDLE>::operator [](HANDLE handle) 
{
   unsigned int index = handle.getIndex();
   return ( m_hobj[index].m_data );
}
template <typename DATA, class HANDLE>
inline const DATA & SEHandleManager<DATA,HANDLE>::operator [](HANDLE handle) const 
{
   unsigned int index = handle.getIndex();
   return ( m_hobj[index].m_data );
}

template <typename DATA, class HANDLE>
inline void SEHandleManager<DATA,HANDLE>::print() const
{
   // Raw array print out
   int i, n = m_hobj.length();
   xprintf("SEHandleManager: raw array (%d items):",n);
   for( i=0; i < n; ++i ) {
      xprintf("  [%d] : m_valid=%d, m_prev=%d, m_next=%d",i,m_hobj[i].m_valid,m_hobj[i].m_prev,m_hobj[i].m_next);
   }

   // Valid entry print out
   xprintf("SEHandleManager: valid entries:");
   if( m_head != HandleObject::HOBJ_NULL ) {
      int i = m_head;
      do {
         xprintf("  [%d] : m_valid=%d, m_prev=%d, m_next=%d",i,m_hobj[i].m_valid,m_hobj[i].m_prev,m_hobj[i].m_next);
         i = m_hobj[i].m_next;
      } while( i != m_head );
   } else {
      xprintf("  (none)");
   }

   // Free stack
   xprintf("SEHandleManager: free stack (top-down):");
   n = m_free.length();
   for( i=n-1; i >=0; --i ) {
      xprintf("  [%d] : index=%d",i,m_free.peek(i));
   }
}
#endif

}

#endif // SLICKEDIT_HANDLE_MANAGER_H
