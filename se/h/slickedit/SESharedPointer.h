#pragma once
#include "vsdecl.h"
#include <assert.h>

namespace slickedit {

/**
 * Template class for a reference-counted dynamic pointer class. 
 * The information pointed to is automatically allocated using new, 
 * and deleted using delete when all the references are collected. 
 * The reference counting is done using atomic counters. 
 *  
 * This class is similar to std::shared_ptr<>, but a little simpler. 
 *  
 * @param T             Type of variable to instantiate 
 */
template <class T>
struct VSDLLEXPORT SESharedPointer {
public:

    /**
     * Default constructor leaves behind null pointer.
     */
    SESharedPointer();
    /**
     * Construct with a non-null default-constructed pointer.
     */
    explicit SESharedPointer(const bool doAllocate/*=true*/);
    /**
     * Default constructor from an already instantiated pointer.
     * The data pointed to will be copied and the pointer WILL NOT BE DELETED. 
     * 
     * @param ptr   Pointer to use.
     */
    explicit SESharedPointer(const T * ptr);
    /**
     * Construct from another instance of the data type.
     * This will allocate data and make a copy of the object.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer(const T & src);
    /**
     * Construct from an rvalue instance of the data type.
     * This will allocate data and make a copy of the object.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer(T && src);
    /**
     * Copy constructor from another instance of the template class. 
     * This will make a shallow reference counted copy of the object.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer(const SESharedPointer & src);
    /**
     * Copy constructor from an rvalue instance of the template class. 
     * This will make a shallow reference counted copy of the object, 
     * and then null out the source pointer. 
     * 
     * @param src   instance to copy 
     */
    SESharedPointer(SESharedPointer && src);
    /**
     * Destructor.  Will delete pointer if allocated and the reference count 
     * drops to zero.
     */
    ~SESharedPointer();

    /**
     * Assignment operator from an instance of the data type.
     * This will make a copy of the object, allocating if necessary.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer & operator = (const T & src);
    /**
     * Move assignment operator from an instance of the data type.
     * This will make a copy of the object, allocating if necessary.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer & operator = (T && src);
    /** 
     * Assignment operator from an already instantiated pointer.
     * The data pointed to will be copied and the pointer WILL NOT BE DELETED. 
     * 
     * @param ptr   Pointer to use.
     */
    SESharedPointer & operator = (const T * ptr);
    /**
     * Assignment operator from another instance of the template class. 
     * This will make a reference counted shallow copy of the object.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer & operator = (const SESharedPointer & src);
    /**
     * Move assignment operator from another instance of the template class. 
     * This will make a shallow copy of the object and then zero out the src pointer.
     * 
     * @param src   instance to copy 
     */
    SESharedPointer & operator = (SESharedPointer && src);

    /** 
     * @return Return 'true' if pointer to data is not allocated.
     */
    bool operator !() const;

    /**
     * @return Returns 'true' if the pointer is null.
     */
    operator bool() const;

    /** 
     * @return 
     * Compares this object to another instance of the same data type. 
     * This will do a comparison of the object for equality.
     * 
     * @param src   instance to compare to 
     */
    bool operator == (const T & src) const;
    /** 
     * @return 
     * Compares this object to another instance of the same data type. 
     * This will do a comparison of the object for equality.
     * 
     * @param src   instance to compare to 
     */
    bool operator != (const T & src) const;

    /**
     * @return 
     * Compares this object o another instance of the same data type. 
     * This does a shallow pointer comparison only. 
     * 
     * @param p     pointer to compare against
     */
    bool operator == (const T * p) const;
    /**
     * @return 
     * Compares this object o another instance of the same data type. 
     * This does a shallow pointer comparison only. 
     * 
     * @param p     pointer to compare against
     */
    bool operator != (const T * p) const;

    /** 
     * @return  
     * Compares this object to another instance of template class.  This will do 
     * a comparison (comparing both the pointer and the object for equality). 
     * 
     * @param src   instance to compare to 
     */
    bool operator == (const SESharedPointer & src) const;
    /** 
     * @return 
     * Compares this object to another instance of template class.  This will do 
     * a comparison (comparing both the pointer and the object for equality). 
     * 
     * @param src   instance to compare to 
     */
    bool operator != (const SESharedPointer & src) const;

    /**
     * @return Returns pointer to allocated data.  The non-const version of 
     * this operator Will allocate data if the pointer is not already allocated. 
     * The const version will return 0 if the pointer is null.
     */
    const T * operator->() const;
    T * operator->();

    /**
     * @return Returns reference to allocated data.  The non-const version of 
     * this operator Will allocate data if the pointer is not already allocated. 
     * The const version will assert if the pointer is null.
     */
    const T & operator *() const;
    T & operator *();

    /** 
     * @return Return pointer to data, do not allocate (returns 0 if null). 
     */
    const T * get() const;
    T * get();

    /**
     * Set pointer to copy of data from an already instantiated pointer.
     * The data pointed to will be copied and the given pointer WILL NOT BE DELETED. 
     * 
     * @param ptr   Pointer to use.
     */
    void set(const T * ptr);

    /** 
     * @return
     * Return the pointer allocated by this template class instance into the wild, 
     * where it will need to fend for itself (and be deleted eventually, or returned to captivity).
     * After this function is called, the pointer stored in this class will be null. 
     *  
     * @see returnToCaptivity() 
     */
    T * releaseIntoWild();
    /**
     * Return a pointer previously taken from this class using {@link releaseIntoWild} 
     * back to this instance of the pointer template.  It will then be deleted 
     * when this class instance is deleted.  Note that this will cause any 
     * existing pointer managed by this class to be deleted and replaced by 'ptr'. 
     * 
     * @param ptr   Pointer to return to controlled state. 
     *  
     * @see releaseIntoWild() 
     */
    void returnToCaptivity(T * ptr);

    /** 
     * @return Return pointer to data, allocate if it is not already allocated.
     */
    T * getNonNull();

    /**
     * Make the pointer null (delete's allocated data).
     */
    void setNull();
    /**
     * Make sure the pointer is allocated to default
     */
    void setNotNull();
    /**
     * @return Returns 'true' if the pointer is null.
     */
    const bool isNull() const;
    /**
     * @return Returns 'true' if the instance is unique (not a shared pointer).
     */
    const bool isUnique() const;

    /** 
     * Make sure the current instance is allocated and unique.
     */
    void setUnique();

    /**
     * Return a read-only reference to the object pointed to.
     */
    const T & getConstReference() const;
    /**
     * Return a writable reference to the object pointed to. 
     */
    T & getWriteReference();

private:

    /**
     * reference counted pointer to object
     */
    T * m_ptr;

};

////////////////////////////////////////////////////////////////////////////////
/// INLINE METHODS
///

//==============================================================================
template <class T>
inline SESharedPointer<T>::SESharedPointer():
   m_ptr(nullptr)
{
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator !() const 
{
    return (m_ptr == nullptr);
}

//==============================================================================
template <class T>
inline SESharedPointer<T>::operator bool() const 
{
    return (m_ptr != nullptr);
}

//==============================================================================
template <class T>
inline const T * SESharedPointer<T>::get() const 
{
    return m_ptr;
}

//==============================================================================
template <class T>
inline T * SESharedPointer<T>::get() 
{
    return m_ptr;
}

//==============================================================================
template <class T>
inline T * SESharedPointer<T>::getNonNull() 
{
    setUnique();
    VSASSERT(m_ptr != nullptr);
    return m_ptr; 
}

//==============================================================================
template <class T>
inline const bool SESharedPointer<T>::isNull() const {
    return (m_ptr == nullptr);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator == (const T & src) const 
{
    if (!m_ptr) return false;
    return (*m_ptr == src);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator != (const T & src) const 
{
    if (!m_ptr) return true;
    return (*m_ptr != src);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator == (const T * p) const 
{
    if (!m_ptr) return (p == nullptr);
    return (m_ptr == p);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator != (const T * p) const 
{
    if (!m_ptr) return (p != nullptr);
    return (m_ptr != p);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator == (const SESharedPointer & src) const 
{
    if (m_ptr == src.m_ptr) return true;
    if (!m_ptr || !src.m_ptr) return false;
    return (*m_ptr == *src.m_ptr);
}

//==============================================================================
template <class T>
inline bool SESharedPointer<T>::operator != (const SESharedPointer & src) const 
{
    if (m_ptr == src.m_ptr) return false;
    if (!m_ptr || !src.m_ptr) return true;
    return (*m_ptr != *src.m_ptr);
}

//==============================================================================
template <class T>
inline const T * SESharedPointer<T>::operator->() const 
{
    VSASSERT(m_ptr != nullptr);
    return m_ptr; 
}

//==============================================================================
template <class T>
inline T * SESharedPointer<T>::operator->() 
{
    setUnique();
    VSASSERT(m_ptr != nullptr);
    return m_ptr; 
}

//==============================================================================
template <class T>
inline const T & SESharedPointer<T>::operator *() const 
{
    VSASSERT(m_ptr != nullptr);
    return *m_ptr;
}

//==============================================================================
template <class T>
inline T & SESharedPointer<T>::operator *() 
{
    setUnique();
    VSASSERT(m_ptr != nullptr);
    return *m_ptr; 
}

////////////////////////////////////////////////////////////////////////////////
/// POINTER COMPARISON OPERATORS
///

//==============================================================================
template <class T>
inline bool operator == (const T * p, const SESharedPointer<T> & pt) 
{
    return (p == pt.get());
}

//==============================================================================
template <class T>
inline bool operator != (const T * p, const SESharedPointer<T> & pt) 
{
    return (p != pt.get());
}

}

