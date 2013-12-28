////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_ALLOCATOR_H
#define SLICKEDIT_ALLOCATOR_H

#include "vsdecl.h"
#include <ctype.h>
#include <new>

namespace slickedit {

/**
 * SlickEdit memory allocator class.
 * <p>
 * This class is used to efficiently allocate and de-allocate memory.
 * It allocates memory in large blocks and divides the blocks into
 * into segments which are cycled onto the free lists when deallocated.
 * Any allocation larger than the maximum allocation size is allocated
 * directly.  It will recycle deallocated memory as soon as all it's
 * constituent memory segments are deallocated.
 * <p>
 * This class is intended to be used as a singleton within a DLL,
 * but may also be used with care in other capacities.  Be aware that
 * all memory it allocates MUST be returned before this class is
 * deleted, otherwise, the memory will be leaked.
 * <p>
 * Memory allocated with this class must be deallocated and reallocated
 * with this class.  The default underlying allocation routines are
 * malloc() and free().
 */
class VSDLLEXPORT SEAllocator
{
public:

   /**
    * Default constructor.
    */
   SEAllocator();

   /**
    * Destructor
    */
   ~SEAllocator();


   /**
    * Allocate a segment of at least the given number of bytes.
    *
    * @param n    number of bytes to allocate
    *
    * @return 0 on failure, valid pointer otherwise.
    */
   static void *allocate(const size_t segment_size);

   /**
    * Reallocate the given pointer, allowing it to have the
    * same contents and more capacity.
    *
    * @param p    pointer to deallocate, from allocate(), above
    * @param n    number of bytes to allocate
    *
    * @return 0 on failure, valid pointer otherwise.
    */
   static void *reallocate(void *p, const size_t n);

   /**
    * Deallocate the given pointer, returning it to the free list.
    *
    * @param p    pointer to deallocate, from allocate(), above
    *
    * @return 0 on success, <0 on error.
    */
   static int deallocate(void *p);


   /**
    * @return Returns the number of bytes actually allocated to the given pointer.
    *         Returns 0 if 'p' is NULL.
    *
    * @param p    pointer to deallocate, from allocate(), above
    */
   static const size_t numBytesAllocated(const void *p);

   /**
    * Check if this memory is a valid allocation. 
    * Do not call this function unless debugging memory problems. 
    */
   static void checkMemory(const void *p);
   static void checkAllMemory();

   /**
    * Debugging function, writes to stdout.
    */
   static void printToScreen();

   /**
    * @return Return the total number of allocations made with this allocator.
    */
   static size_t getTotalNumberOfAllocations();

   /**
    * @return Return the total number of bytes allocated currently with this allocator.
    */
   static size_t getTotalNumberOfBytesAllocated();

   /**
    * @return Return the total number of blocks allocated currently.
    */
   static size_t getTotalNumberOfBlocksAllocated();

   /**
    * @return Return the number of bytes per block.
    */
   static size_t getNumberOfBytesPerBlock();


protected:

   // segment header
   struct SegmentInfo {

      // required part of header
      struct Header {
         // This flag is set if this is a small segment
         unsigned int mSmallSegmentFlag:1;
         // This flag is zero if the segment is free
         unsigned int mFreeSegmentFlag:1;
         // index 0..7 of allocator this segment belongs to
         unsigned int mAllocatorIndex:2;
         // Actual size is this value in bytes
         unsigned int mSegmentSize:28;
         union {
            // (Small Segment) Actual offset is this value * mGranularity
            unsigned short mSegmentOffset;
            // (Large Segment) High order bits of segment size
            unsigned short mSegmentSizeHigh;
         };
         // Actual offset is this value * mGranularity
         unsigned short mPrevSegmentOffset;
      } header;

      // used only when the segment is on the free list
      struct DataArea {
         SegmentInfo* mNextSegment;
         SegmentInfo* mPrevSegment;
      } dataArea;
   };

   // block header
   struct BlockInfo {
      BlockInfo* mNextBlock;
      BlockInfo* mPrevBlock;
   };

public:

   enum {
      // segment size granularity, and 8-byte alignment enforcement
      SEGMENT_SIZE_GRANULARITY = sizeof(SegmentInfo::Header),

      // maximum block size allowed (max signed short * granularity)
      BLOCK_SIZE = 32768,

      // number of blocks to keep reserved for future allocations
      // note that this is per allocator.
      MAX_RESERVED_BLOCKS = 512,

      // minimum segment size managed by allocator
      MIN_SEGMENT_SIZE = sizeof(SegmentInfo) - sizeof(SegmentInfo::Header),

      // maximum segment size managed by allocator
      MAX_SEGMENT_SIZE = 2048,

      // number of allocators to have to reduce thread contention
      MAX_ALLOCATORS = 4,

      // maximum segment size (+1) we can store in mSegmentSize (28 bits)
      MAXINT_SEGMENT_SIZE = 0x10000000
   };

protected:

   /**
    * Find the segment corresponding to the allocated pointer.
    *
    * @param p    pointer to look up
    *
    * @return Returns a pointer to the segment.
    *         Returns NULL if and only if 'p' is NULL.
    */
   static SegmentInfo* getSegmentPointer(void *p);

   /**
    * Convert a segment pointer to it's allocated pointer.
    *
    * @param segment    (!= NULL) segment to inspect
    *
    * @return Returns a pointer to the allocated memory.
    *         The returned pointer will never be NULL.
    */
   static void* getPointer(SegmentInfo* p);

   /**
    * Find the block that a segment belongs to.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to inspect
    *
    * @return Returns a pointer to the block the segment belongs to.
    *         The returned pointer will never be NULL.
    */
   static BlockInfo* getBlockPointer(SegmentInfo* segment);

   /**
    * @return Returns the first segment in the given block.
    *         The returned pointer will never be NULL.
    *
    * @param block      (!= NULL) block to inspect
    */
   static SegmentInfo* getFirstSegmentInBlock(const BlockInfo* block);
   /**
    * Return the next segment within the same block as the given segment.
    * <p>
    * The returned pointer will be NULL only if 'segment' is
    * the last segment in the block.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to inspect
    */
   static SegmentInfo* getNextSegmentInBlock(const SegmentInfo* segment);
   /**
    * Return the previous segment within the same block as the given segment.
    * <p>
    * The returned pointer will be NULL only if 'segment' is
    * the first segment in the block.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to inspect
    */
   static SegmentInfo* getPrevSegmentInBlock(const SegmentInfo* segment);

   /**
    * Check the free list for a segment of the given size
    *
    * @param n    size of segment to allocate ( <= mMaxSegmentSize )
    *
    * @return Returns a pointer to the free segment.
    *         Returns NULL if there is no such segment.
    */
   SegmentInfo* allocateSegmentFromFreeList(const size_t n);

   /**
    * Allocate a new block and slice a segment of size 'n'
    * off the front.  Place the remaining segment on the free list.
    *
    * @param n    size of segment to allocate ( <= mMaxSegmentSize ) 
    *  
    * @param allocatorIndex   index 0..MAX_ALLOCATORS of allocator 
    *                         instance being used by the current
    *                         thread.
    *
    * @return Returns a pointer to the allocated segment.
    *         Returns NULL only if we fail to allocate a new block.
    */
   SegmentInfo* allocateSegmentFromBlock(const size_t n, const size_t allocatorIndex);

   /**
    * Join a free segment with the previous adjacent free segment
    * in the same block and return the 'joined' segement pointer to
    * be added to the free list.
    * <p>
    * This method returns the same segment if it is not joined.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to join to adjacent segments
    *
    * @return Returns a pointer to the joined segment.
    *         The returned pointer will never be NULL.
    */
   SegmentInfo* joinWithPrevSegmentInBlock(SegmentInfo* segment);

   /**
    * Join a free segment with the next adjacent free segment
    * in the same block and return the 'joined' segement pointer to
    * be added to the free list.
    * <p>
    * This method returns the same segment if it is not joined.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to join to adjacent segments
    *
    * @return Returns a pointer to joined segment.
    *         The returned pointer will never be NULL.
    */
   SegmentInfo* joinWithNextSegmentInBlock(SegmentInfo* segment);

   /**
    * Split a free segment into two parts and place the remainder
    * of the segment on the free list.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to split
    * @param m          size to split the segment at (normalized)
    *
    * @return Returns a pointer to "remainder" segment.
    *         Return NULL if the segment is not split.
    */
   SegmentInfo* splitSegment(SegmentInfo* segment, const size_t m);

   /**
    * Add an allocated segment to the free list.
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to add to free list
    *
    * @return 0 on success, <0 on error.
    */
   int addSegmentToFreeList(SegmentInfo *segment);
   /**
    * Remove an allocated segment from the free list
    * <p>
    * The segment is assumed to be a non-null, "small" segment,
    * that is ( segment->header.mSmallSegmentFlag == 1 ).
    *
    * @param segment    (!= NULL) segment to add to free list
    *
    * @return 0 on success, <0 on error.
    */
   int removeSegmentFromFreeList(SegmentInfo* segment);

   /**
    * Normal the given segment size to match the allocation
    * granularity for that size.
    *
    * @param segment    segment to inspect
    */
   static const size_t normalizeSegmentSize(const size_t n);
   /**
    * Return the index to use for a segment of size 'n'
    * in the free lists.
    */
   static const size_t getSegmentIndex(const size_t n);

   /**
    * Allocate a new block.
    */
   BlockInfo* allocateBlock();
   /**
    * Release a block back to the memory pool.
    *
    * @param block      (!= NULL) block to release
    */
   void deallocateBlock(BlockInfo* block);

private:

   // The allocator uses the following data structures:
   //
   //    1) A doubly linked list of blocks [large allocations]
   //
   //    2) A table of double linked lists of free segments
   //       arranged by their allocation size.  This table
   //       has an entry for each allocation size between
   //       the minimum segment size and the maximum segment
   //       size, split up by increments of the granularity,
   //       which is sizeof(void*).
   //
   //    3) A "current" block and offset for the block that
   //       new segment allocations are to be allocated from.
   //
   // Blocks are split up into allocated segments.  When these
   // segments are free'd, then go back onto the free list
   // corresponding to their allocation size.  If all the segments
   // allocated within a block (not the current block) are free'd,
   // the block is removed from the block list, all it's segments
   // are removed from their free lists, and the block is
   // deallocated.
   //
   // Offsets and sizes in segment headers are stored right-shifted
   // by two (divided by four) because they will always be aligned
   // to four-byte boundaries within the segment anyway.  This allows
   // us to have block sizes up to 128K.
   //
   // For illustration:
   //
   //    BLOCK_1 <==> BLOCK_2 <==> ... <==> BLOCK_N
   //
   //    BLOCK
   //       |
   //       |------- BLOCK_HEADER
   //       |------- SEGEMNT_1
   //       |------- SEGEMNT_2
   //       |------- SEGEMNT_3
   //       |------- ...
   //       |------- SEGEMNT_M
   //
   //    BLOCK_HEADER
   //       |
   //       |------- NEXT
   //       |------- PREV
   //       |------- NUM_SEGMENTS
   //       |------- NUM_FREE_SEGMENTS
   //
   //    SEGMENT
   //       |
   //       |------- SEGMENT_HEADER
   //       |------- NEXT/PREV or BYTES (aligned to sizeof(void*)
   //
   //    SEGMENT_HEADER (8 bytes)
   //       |
   //       |------- SMALL SEGMENT / LARGE SEGMENT FLAG
   //       |------- FREE SEGMENT FLAG
   //       |------- OFFSET IN BLOCK
   //       |------- SIZE OF PREVIOUS SEGMENT
   //       |------- SIZE OF SEGMENT
   //
   //    FREE_LISTS
   //       |
   //       |------- size   8 ---> SEGMENT_8_1   <==> SEGMENT_8_2   <==> ...
   //       |------- size  16 ---> SEGMENT_16_1  <==> SEGMENT_16_2  <==> ...
   //       |------- size  24 ---> SEGMENT_32_1  <==> SEGMENT_32_2  <==> ...
   //       |------- size  32 ---> SEGMENT_64_1  <==> SEGMENT_64_2  <==> ...
   //       |------- size ...
   //       |------- size MAX ---> SEGMENT_MAX_1 <==> SEGMENT_MAX_2 <==> ...
   //

   // hide copy constructor
   SEAllocator( const SEAllocator& rhs );
   // hide assignment operator
   SEAllocator& operator=( const SEAllocator& rhs );


   // pointer to array of blocks currently allocated
   BlockInfo* mBlockList /*=NULL*/;

   // number of blocks allocated
   size_t mNumBlocks /*=0*/;

   // number of blocks with no segments allocated, 
   // but reserved for future allocations
   size_t mNumReserved /*=0*/;

   // number of allocations and total number of bytes allocated
   static size_t mNumAllocations /*=0*/;
   static size_t mNumBytesAllocated /*=0*/;

private:
   // pointer to array of free lists
   SegmentInfo* mSegmentFreeLists[MAX_SEGMENT_SIZE/SEGMENT_SIZE_GRANULARITY+1];

};

}

inline size_t slickedit::SEAllocator::getNumberOfBytesPerBlock()
{
   return BLOCK_SIZE;
}

#endif // SLICKEDIT_ALLOCATOR_H

